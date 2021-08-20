#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2662007672"
MD5="98357ed45f0ddf9c83b8b07b54182183"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23640"
keep="y"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt" | more
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.4.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 592 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." > /dev/tty; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=copy
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Fri Aug 20 00:39:54 -03 2021
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--xz\" \\
    \"--copy\" \\
    \"--target\" \\
    \"$HOME/lamw_manager\" \\
    \"/tmp/lamw_manager_build\" \\
    \"lamw_manager_setup.sh\" \\
    \"LAMW Manager Setup\" \\
    \"./.start_lamw_manager\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"$HOME/lamw_manager\"
	echo KEEP=y
	echo NOOVERWRITE=n
	echo COMPRESS=xz
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=168
	echo OLDSKIP=593
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 592 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 592 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 592 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
	
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = xy; then
	    echo
	fi
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf "$tmpdir"; eval $finish; exit 15' 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd "$TMPROOT"
    /bin/rm -rf "$tmpdir"
fi
eval $finish; exit $res
�7zXZ  �ִF !   �X����\] �}��1Dd]����P�t�D�aq���u8NZ��F��}�3Y��$�{�l2�t]K��-����x��C�/������O��}u���弢6R�b/S���f�Ș�]�`�dB�U�kG�ɗ�!ƛ�<�9�lS��<|�:�`ɰ��Q	���
:�{���19=��4c��@�I�K���A����>�����֒3?���eXz�R��q������V*P.c=��3�=��$VA^LMޱ���+�n��)3�C�S}U��ڴR/l����7�y�B���a��ا	���(�q��N
e��/W��r�'�8�j�LN<��갊�[���>v�� nП��s�����;6�"���C��49t�Q�j	r�}j`U%8t��V��	�n�m�-�e+){a����s���i�g�|8C@HC�Z#��dGY�g0K|S�עO�R	�[E׼�is�(��Ø�����ւCZ�j�(Љh��N,�ev���.�цz�-���B>Ǣm3��'W�����7 o#�H���1�y΂D���h��Ƹ�~�����0˂�E�;��,���ЛK�I"�k-5 �¦���H�'�W�(��W�-�xg�7�T�U��!l��F����,|Ɋ1��h/+zj�7bQ'������4�[M§%r^D�B ��y�n����h��?��_�T����ԏ���B�2�nC�����	��]�����\��ѯ�Im�%uݶ=�e����?F�hl�u	sz.�4f������S]37����&�2W�\�
Tc	�Ҁ=n��b�G������J_�b2E���h~
�����^��(*�Ն��$tX�U�C/:�三b�atY\�̻��*�_�<<��u��w��.$��uo�>�v��}�!�TP�j�@}E*��p���kǗ1!%:%.�5<��6�NU��'[��L�N�K�]�<>C��C, ��ӇUutK?g$���G���9p}߼q|F�\,�q��ٚo=묛��@���I�m����:�nM��j /��5`�i-�=��%���~�(]h�-+��O��~�n*F�:��}�_�l_1KE�]�&Z�
�o}�u�*���� �Q���)�U?����Ң9	Cb�_kR�Ηu�>�p��_!����(n@�����V����R��!wW�����.��}�{���6���f�g��+��܀�W	��M��VS�u`�l~%�Da�V
ǿݴ�yWqyV������Ok� �PI!��
O�5+Vs��S�\��u�䬃Y7.��M��&4F4[�~�8���R��R$�+2U�yR�g���K���H}�H�����]Z$�
�~�||��2���S\hʾ�Y 5m�Ƌ���5@��`��*�p|R	�e��	�M�H0�Ȇ�v[�&gs-�O>*Hzͼ�=f#��O��y,E?�@H�0�0W�������~R�r��D7a��
ڮC�:W��q:�og��npM���h<#�TԿ�L���	���ݚ�3F竟�X=m�x��3h�B�R�]��)��:�p���,6g#"7go���3�F�D��Aekv����ͬ��y�3�M��6E�t�E�hY`�x�C��d!�B��T_�YDXE-/��_����� `[Ky�W.vU/$�\f�?�D]�֕�U� � �٤��CfCUg��M�\�- 6x��@~;5à��>s��3ҐI����{�ܔ+�5�$;����S��N����:��8�Ob�k���;��u���-2���
�S|�t�}��Qյu,#n�M�1�r�"(�}��Sv>�c�9�UK��C�܏Z�$�R�k̉<�n#"���K����+�N���`���
�\�(�#��7<��k�����&mh[h�P8�����br촏�1�d�o�t{�5G�9�6�y�	=�#�� �#���g`��#]�.0�m$:�2��@�n��9�_��=I:����Y�4����-{j��SD�KfݶWl����u�ɵ<�\g$�2�>[�Y��i+�[�5m}[�@��)a�Y�ŀ����P�5^��	�Ji���B�vwZ���������ls�(��/�T&��m=���4��d[`5�W��?iANNNcÉGNVp�`�-�F��WH��1"g:ME��V�F�M�4�#W��6'�1�}��z8����q���x��t�JRKSZ/f+����{,ʥ�y�ŧЁ-���L1�.h� pbΈI��3��T70�j$���1�7վ�b��0���a���I?���;�[�Ю!Z�k�����1D"{zԀls�;%����PjUB�b:Vr����T?@�@�n�����J{Ċe�K9��qy[⒘�ă.>�#�y*꧙�0�((����R(A0��Si�=\I�;��Y����/ ��_|ë}6��Ng�v܆,�^�x�����̵�	w+�˟n4�<� ܜyW8ǉ#F�h�CSTF�9��yl���(�+�QW�k��*�Nщo�XP83}�4Ì�3w\�2��]��a�^�}GэB�3�֣l��'�t:�="s!�_�qME�6�y թ�v�t蓃��{I8G�O�Y<��~�$�����%&�ذ@a4�V�6�7�]��T�o�ԅ�}��]�=TW�����J�9�H���o�*��w�GE�|:j��&�~�/w�_��������N ��a�]>v�Q6���m����=Q	n�b,@}�cߋP	r]N��i����X1���������B#�x{�B����	�k�-��hb�feĉ@��o=N��M�p'�9�j�Z�5[�f�8�om}덷��#�m��a��C�)i��]��?�P`~-4௬��}�g�g�� �{���d$[��T��#��ܱ��9���-�
;�;��z�nq�j�+����Sq�����G�a�j�`���x��kQBl�����0:�߾�#�����2�:�����m� 2��?�̶wk�.��$���P�4��Mk�[��*�ܘa~Q~���@"F9.�H� �� �S�����ۑ9��}��d�ĕ+ m�Aا�h��]�yD+N��ǋ��	{�K�����%M�
�o@%{�ƕ\�1����;2L���;��u��A�	Ll�9�h�;�d
#��`���(��Jo����-Gh�����]�<��h�4^��^���(l�=G�����=}���>j�"����	a�Qg�g4����%���;�T�x9M]^��N��t-�����|tP� �a��T��{}/�6���Q�1�4�r��;��5pV���V�1�40���F�C?0i,n-�¦�3�}��jNB��&T���`B~�>�P��vL�}j�K4��>�m5m[�����1��;���Z�S���M~ث�6�`27��`m^�M�J�q��9	b�%{�g'IaI<h��=O��Ύ�vs��2��,�Rr A������	D�h�؊��D1��k��C���W��4 M��F"\��9�T�����*)�	���8�́���I5a��z�ˣ��f�OM�������Q�'�k����O�M��M}%��J�	t0LI7=5�L�Pcw��c��4id�NX/�Q{��!L>�H�??��05�Ih�B�4E��w���W���sj�:���5�qmDv�n��h�%XN%X��R��m���5e��,���I��r����.�1������E�h���.�?�(�4��"��mM*���#G�p��MX/%@]~hي2�ǝ���V}�Z�v��g�I�eV�����.�������3���:a��Q�]�+lf�4r:
�������xQ���#���ߘ0T��<�c��͓+59&m?""��w'��v*#t��ۿ)9�"]�.�|���V��q�ۿ��:D>|�to�px��ɿ��>�u��+��h�?A ZZ��� �mԞ!'!* 9pmn.o���SY�~�b3�M�g�����2�ĈV���d�J'����u��Z1�6v7uP��|���3&_F���D��3 "�`>�PJ�I�u�h�pY0y���Պ�W�/~�Fΐw*�k}ue��V�[�nAj��	�M�O��b~5L�|C�,�
���q��̽j
�X�"��aBG���1�fs4N�T���f���-�Iw�XN}���atz��.�����2�N�֑�n�n�	�* �mY�*VVR.E}���+Gu���R`K�_|�D��~� ������E� ;�����r��s���H�̨�^"�ʋ�}�������G��l���I?��8��c=���:�0���3	!؇��3(�h�S'�W��V��@�q� �dփ~o"��:}�nC��R&�=r\
,`�Qe�k�S������;hf��wne����)_�������S�77o��a�ܓx����<%��J9b���#�2ϰ�hR��L�/���{L[k 
,��T����u��:�M�̉���Ow�Ȉ����@�§�־�_�h-�W�%���Q׏7D��3w��>�%dz"^���q��q��&Ç78�;){�*ߙ3�=���έ�?T6��N�_��|b�m����9M˞��n*����zkB�D�m����_uoI;�C��6�Y܈^��}���A��-�o���e���p���Q9���X�Β�~_D�o2!{�'(����ˆ��Qh��+.`��\j���15呖�����:n���1��KN
�3���ÃV�Ij�ݥ�N���2xp0��+i��� �y�i����+"j�X����f�scZ��׭�!����+�Y�_s�L� �n{�A�>�q���Ek3_<�2��$���lu�bN���a�E�>�,�5��O�R��m�l".C}y���>හ��Ft��]W�݅�,NP�kѺ�ۗǕ�{b>Kw�����G�>iN��͊���M|\� ����� ��D��,x��/�$�/	�KE
�o�xcO�	��{۸�U1"?�p������!��>�U��Ъ��{���OWĐ�V��u��)�`���;�|�6���NLP*�#v�4��4��?�'����E�� �c?��-U=_JC��:X2�:6�NMڣ���tg�NHC�?��h�����r��F�J����`���q�nϵ^����KV��0�@�sH:L�3x��(nW�`�D)*1��7��rrsQ���W85g-�i�_>�+U�V�xHq9��8��������Tq$n"���<��'����/����#�w�{x�"���y�2�7f���g=��
@Ap���2�P%�RV����-�Bɛ�f�&W���Vx���؂z>�c�QYV�]<�Cd��l�����V�re4�&��v7��0x��ڹ�{V홽ܢw�b>�C%�b_�I@K�CΝ��A�#�����s�Ҭ+�+�rĥ�R��@P1�f˭n�]!w�!�x��?6ێ^�_N��M
��,H��l�oV"]Y\���mra����Yb���d���L�M꽫\0��1\����j��[W��n,���^C����Щk#��H�4������d�m� 6��2v��ȕs�)��yr�ӫ��Y�׆�����B�x��JQ��6��,L���/@��g�N��v�t(m8p�w�B��9��#n%���v�=��[տ�aޯ�f}A=����S��L3]K�֤&H�2�U{��X2~�l�ٟ���K᭴W��Ȫ��h�_����N�<�����'�UKzR�k�J����o���N99�7����=��	��W$5���֤����WL�
j��^2dpF��
=�q�!�1�c��0�C��{1bQ� c�.��YxV�Mŷ_a�Ζ�!ncYX:�0f��9k��[��kc�{tI� �tJ:{��t�`&��"2#��:�~���P!����Z�0���hYN#!���zEo�U��/4����9u�RU�C�����m�-��4�q�e��a�bB&���-�,�,�,��L�1-��������K&�$�9�����ؿ�
�4�ݥq��a_*e.\��ϏJ��Um��J�����Z�� �b��	�A��#���Wd�1,kZ'��J>���$vR����8����ST�mȟ�������y�FY]]��`�������l4��e'�L�M�e>�0��R�$xM�J�a7#P��ء�ZH G�[��l�`-���je{	qe!�)�}���k�]�l�M��C{�AYg����He��-��q�lK�o8�9�E�m����uֆ��dwт��C��Fi���P��{+JP=d,)�O��B�] �Tl�Mb�j� �r*��W��S����� ���s_Ӱ�R$����J4ApZ��Bp��Vщ�
��E���Stv�Z�D��T����җr}[���fi@"�5$��6D�����@�/�2���=_�W���1���#�ɞ�)�ė\�M�)Z�CH��'�á��
xe>��hm
Ī��J^R�b*�0�ǨK|QW��/��P[{c��f��(s��r,�wahJO�.�-/���b�r�����&�!�Z֥�]j�y���썉m�qL�h��^�&�����A�����t�������p���*����=��ߋ�V(B�C���`@��m���&��w����<1�� ��1Z���^VxAo�,?�>�e9I��/=g���2B	@T)1Ԓ/6O"�ɤZ���e�J�H�E���SC���<�����ʓ�ٮJ�{�UJ�Tgͷ#����f[��Y�pB�P&u�9��u+�Va8X. {qx��E],��t6�e\�:�6�i�^����n?2��p�"�U� O����@Y�Xz�k����?��7_r7��
c�-l˖}��8lhK�q��ˀ/��7`5>�'�n�-���g-�Lwj9�d� �Ԝ �J_��Q�����U�� ��v���R��}G]6d��Ĺ�K�6�g](�	��3ܴT�I�"�:eM��W_z2���=V����>R�+�? +�ve��ΉW�]����{x	mrx� ��'���naos��w��vhp�!/&��¶^d5���_>s����l�(����"8�;EI�������]���H2[�� �h�Rb��OB~W9��~�C�Dc��?�%��� �9�m��rڌB��IU+�s��bc�k���D�aV�X�b��Q��N%J� |���A�9�J�E�3j�0�*��L��i�8tD<�a9ؕJ����PsR
�T�*H�����'�N�/�k*t0��wN�^���$�w�_����]=��&܍�)��{�z�+Y:��'q���5�zժ/���}����$��{O�;�l'���Z�s��%Ơ-R�u"�`U�P=���m�(�sқސ��(���6��x\̘h=���b>T�h
0�b����0�P�o[(Vh(�7a[r|f�?���1-n+����}�\)@��X��Z��4mښ�E�%qT�O�0w�����{=D���I�J��e=^�EE#vd�������[�dc�Z�~���;�A��~�Y�d��:#B/.�J f����2<�;�?���#K�د�	�ٟ`�[a���D�c�D"O�P7u̮K�qm>�x�[jĐ���x�	��~���4�;��$X'.�OM����xM�R��t�-�K!�Y띀ل`��D�w�d�	=�=u����c8 �����ʥOPr�]BXJN�����J�T��u����k(V�`}D�J���z vТ1�z+��U�H� �^ԺלB��`	�8q����ƸE����-;d�_څc`��\Cv%�k�q�esB�j)��ɛR�I��.C�X��Z0B��ډ�J���y����Ҹ�0Re�l����lew��ޓ�iU���P�3��v5�1w�V�_4��w������<������ڣ�L��:�~M�B�.I<J��1�}m.�A[_H���2[����3UJŮ�C��@e��,�e@Kha�Dz'���-�����7��aX�_Z��9���k:�xff��O�C�h��詩y��SK�'=�ݪ����2n�A%��@�pT2y'��^�]>��0cZ�d��K���#&~�����O�?Kt��4�1r)Jq՘#
�Ϊ@��|��x�Vl�la�� �S�|s����b **�
��1؝qj\bN���9�x��0Vw>x<�I�&��i��r*�&�n%����%��$@Q�<-}����6�缪����Z4O�_<gi�	%4;�c��A�{����͠��F��;�%
`c��ɝ'ed��Cd��K����Vd��v�]��$�#3yR��}Q$ż�)���ʃZN���}/k�D�z���.|ju	��yUA��}�����{uJ�9�f	�Ɏ�ٹ�*�4��W�G}�NP.(�!D�v�T/ԪW+����j��H�F n�H�lc�w�d���m~Һ2Tk�1b�~�z��'(��z�Od�\}��W"f�������p��F�z
�L:�����Z&����^[�:��U�q��G��_H����L� ���/��[v�q�L��->��D��3��8�9/�g�]f6_��mOP����� �bw����&���bRCo뉥�%=��{6���L
UIA���o���Ġ��v�}N�_�v߅�
�EV�%��B�a���%�tT���G���'9�_
۟a��:J b���H9��ŗ���g��Z��0Zp�ݶ�a
�
VN��i�+V k6Uv'�8S=�hs�� �cV���C֩O�iswL�� T�������?����E,nU��c��<
�VW������!�oW��ټ���ʼ�5�TK}��*ɘY�յ���97�͓֊Q����o1Z0x��O�N>��lV%�I�L�zR�;�A+�]�HE�K�"��,u�S�h#�e��/Gp�����#��=$⊿��ӽ�st��<2ul>����,�:��Q2o.�*�\:(}�P��]w�G����
��W����1Т���>_P�~��V�!J�|����Mt�Е��+~_�i �����'A��h������i~��{X�����r�^���:�������'��2��	�P�)*�i�X�h�������f�>~������%���j��V=�ƞ�@��΋�x�Hi6��99w���-�����^��H������6���*wu
YΥFΙ���c�?ز�\�RB��s���r�S'Bj��M/W�U�٨��t�|_�H�.-b�fCYC8v9F�fיC��"�Jg~����;k�Ɓ���Vi��`�
�yzG��ᖦ���h�8�G��:�O?��p�g��M�� .N��AZ������;��'_�<Ó��Ҿa�]A�0��m��Y*�I���:�A��y3N�(�5�^m]�rJ�:P���:�Ra{l��9�1�fgkx^x���A�sM��ϸ�q�dt���l�Z4����^�Q� �����&�!#��	v4>��j3Z���)����uCfiZ����'�zS~�0��Q��d��z3c.F:c������A�tg��t.�o7��<|����@�	F�'�:��F�oDKȌK�d��@4-=}h�l#be��Ė�T[�� ��-��v?az#J�gzi��%���K*�#��x����������@�\�r��
��KT0�I$nO���X�Fk��:|4�q�Z�<�������,�=b;��V�v���mUU&Y#���`U�c���4�S��{�s��G�lH�峞>gk�1#F_��lĽ�r�nml�R��#�ϬF��"�a��b(y��e�w�l����c���x��Q�a��]����J�ik ���T�/R�����%u��:���	�gJ�ɰ���ȟ���}��󏸠s�稂
<2�s��� q 0D�
��w-0�Q��]��kV�I������F^]��]Dg�Ǽ�<�[��M�]`�OS��Mu� ��E��M���TŞ����+2�T�Bv' �Lb�B}O���wM�AЍ8�/�)����_��b�<@5����q���H1��������J�6����2�h���3�X��k�Wz���nB��[N�%��< �{��|vA�`�{ͪc�+���Sn5�/�`�u�����䒇��=EV-�v"AZO�����؞�ت�Y�~Z�5A]Q-�;]"j��NZ���(��)��j\�-�e�$?�f[��f8�.b���4�G��W��~U�!e�v�/�)�$�&%����&"v��=W*A��@eC
	������t����ʨW��P���o��bNL������ɀ�i70]b����-%ʵ�h�K �t�
����d�D��tRg�Q��	���2��/�0i���ᠠn��2c�Z����ϘZ��br�)B� ��-]���u��Byz��T�ha�TF��E�V�>�3�.�Ѱ��`���`L
�c��.@�N���K���>\˹�w��Å�d�|_��<z�ϥ�l�F^}9�$���C����wp'��5���"3�m�������Ѡr�G��A��W�U��5,��!�)��m�_�`��("m�I^��d*��Nk��,�{���7Hɥ�]I~��y<n?i������5x%�#���}�x��now�} ����������F����x��B�4uќ�3c��v��jK�ڦ�Q�U7Ҹ�n���Hn_�^|p�F8�f9��:8���5�l�!`Q�X�,��b�����I��9������X
��)*,C������T�x�܏LO>��Grn�w�cʌ8�]�U�Wn�.�P������^^��YMG��!�/��L�Z	i��X���[�f��c��{�?�P�yλ�U�%�9���UmQ��3�d����d�_c�)�!�J\$�D�`�%A���P�A�L3���s����3U���	�ܞ�,1��&����G�%�`��D��1.b���?�.�w���`Y���]�*�]�8�@��u��*zq5�N)����a��c��"�ԑ�'�܆��7�c�	T�Xʐ�i�7���*��&ẑ��I�2Y��-�4��E�G>w,^��]��~[����qd�7�#c}d쩳��%p0�I:��oZ�i�� ���ɘf�VȤ�"����s��83���^�h
��ީ�=�kŰ��_Q��S�Z�>-#]��n��S���G��2�|��o��(5�mu����׭� 5F���:�A�;�I��A�R'%�~-��uye)E���q��Z��b_Ɵ��pqƤ;{�*w�ʿq�R�54x�V��u����+����c��,��cD!���'�|XA��X��aVtz"> K�BZ|@ka���˔\e���ZH)������E[>�I3dQ} i˪�F^�6>�����CM	o�[k��\Y������l�E�hT�b殮:�?32cߐ��Yh,$
͏��D;��>����|gw�ʒC�,�O ����r{�������>{-��O8�%����\P��"5�!E�~��'^.5�ڷ�cJs����;�M��5���d��߆��ni�0��x�O+�J�Q�����MQk��c�5bW��9W\V,���l0����c��u�F�?H�{��U*Z�@=a'{G�|$�l�~����/V���D��<�n�J�_2� ��-�L���tf%7Ƹ�HCXQ@�Y)y��^?P�V.����M��N�Ly��E��6�Q;m!sw��$z_�5�������;�� ��"t�����"a���&��+#���#�pI�[{}�$<�ۏ���(ԧ���l���}�( K��3�f���UW�#�u׀V&�hj$�Mǂ���e>����s���)@1=�L�D�d?z}�a&�!I��&;��P$D0���4 �9Ukx�rLs�7�Ή��e�#��LYļ~y�~�e/)$Q8���oUT�7fW? 7��y��<
q�WA�+�%_�x��]�q`��U\��4c���ۦ'�B-�Y�㚁��m���tN�[u;3��4�hˀ�
B�}��T8s�+8��[t ���J��M�M[�8��w��8���6��]��V��_�Ð��@��<��ɠ������g�@ܡt�1|�ZF��.�����=�3ǚ�N���U+<[џYfNp��awsk� ����R9�1���-ﲕ�����X"b�#8j>NH�f�%Ĳm�d8�f�jhu����/X%�]�&^�y�!��BƜ�m���qk#�q��;ק�Qʘ,g�/��t�X�n�.L�x�J�m�`��2H�( \� D��Ay,:�mC���8|R�	axK�k�L�i�\o�w�)�^���Pǖ:�=����5Ԗu�I�ew���bӍ7^�
�;��h9j�~' \�n�Io%s9�!�DlL�����ƚ�{�hP�F]����qٝ���ծ�:��|(a�$��3SR���d��s��
��H�^��-<��5�y?^���lxN~������{���ώ��}vl��Rom1_8�W5�Fy6� ��W�R�V�a�%Bh	aⷫ/7��d�6]�Iｩ��=�����Z��ӬdQX�4�R�,�&��/�݂*z-�)U�)*�z!�3��W^�i|:�ŗ*�����'`M�T����Vh��*�B�r������I���%��]V���	��A,-Q���)�$)C�gy�D�d���d�~eѦ����#�*該���~����sU�I����{h<*�̴c�S&`TN :.c��lf�p~����<BJi%��XK�I��*�%*1�����n�Y���D[�����L�g����n�ܟG㸌*���$�#����K���|�{��/:,I��] _Ws׹E�z�n|���p$3�Ô<[C�r������Gݙ���D{ule͆�Ū���u��MТM;j�cc$�',%��5�WN���/�߼���.�˩z#/�ƹ��>��^��[�#�{ʿ��3S�`��[3vڤ���#'���励��{�r��f�*��6~������^���f7�Z�u����v�n����6�W�K�-�,��A��^Y�u	��)h�TS��THo�:�g��h7A6em�,�wP�M奸�[#F��y����\8�X=�R��������̰0&�>��t9���������߻����ٶ�A�Q�C�.|	{�ǋ#�A�1떜S;*�'�-����:-�'nPi�y������1bV��h��e���\5�7�g8xzI�)���c�<�
�$�Y�����x���q_9����h*�E�H���_�(Fvn��ah;��ۦ�)c�}����}�TBhd�F<�
#B1��}�6U��f����~�md�E��B�U�C&�ṋ��������R��=@�:���`o͊G���%B_��t{�Pm�w��#���H~S�i;x!Yg�\/�VT�D�D�{��~׽(�ɶ�޲H�c�����m���e�Է'�ȱ�bEN��:�#'�)׏ ��F�3�i�z�(����p��vC�~ LK�?n��4g��m�oK)�X��@]::?��}k�:)w,L��aS �gl�(I<�ݘ	u��P������ݮҾ}W7+�Ɠ�6ӑ�����-��Q�8o��u��%r�z�F�A�w�gFg�Y����[��a�
�����(�m�/��f��2 {p�&��AaA���<� >��>0��o�W�{��gI\~��GK!�h7�N���V�:(D(ۥI�y�Zc�s�Bu�J��������jΣ�u��e���xtB����\+vJ�/�Wp��E�W�������ll�%ŉ��`�4�K�y�('5X�
��)B�d1#�9%2=\5:���QK6F$��(G��H���c�b�;��vp�$�
�D�Yh����0q���w�Ȅ6�8T~|j�<Ef$�z�����@�F�_���������4);3��Ro�ѵ
��o~����m2���o�5�/?�,��
Z����"�k��>���"੦��L�1�X㡜hqW
�f����<�*��3Xԯ��z�1�����nu��w�ô�:�N�z8�!g�������& ���WҊ�K�:,�a
dm�l�W#��d�6�U���HM���	�oAۯ�~�t�"YT��uMy�AzH�4�|�9dמ7d ����FZN��4L�}��tZ�Y0C]��*�������_�}wL���v)EС����'Jo�!���GXL�8Р%�28Y�W��2-������3�ٌB}�\���$�c'����!#m|v^�Q
�˦��}��&�df%���i2cv���DR#��� �0.wp���!F��\�ġR}����s�<��X?S��P��tp2��jP�߳ 9�b(�;�J�n��?��?��Z��2;m��*��$.ԛ��NjΔgW4�W(����4�	��ڟ�5�O�6�kI
>Xd�\��@�U����s2���+J��P�O�
�ƻ�z�)���:=�&����B��8`�@�x�aT��,nX��=v���}\�p�eV�t�&&��Gq�=R�fin���-��%�ڏ�:�Y�߿e���T�+�E�U-�~p5��TͲ��,|�B]f��"��N7ޡ�6t��J�3hI@��Q/�ނ�X-�{�z;�bm��+q�v!�A� �#�a�8���+*��|�os/8kl�Y��!���I`22�J4�'s�*�X� �%~#Q�����Y��3�}�± D)TI�A��y�J���G��6���A�/n66��� 7pzς�wk�<��'� �%,Z>����s镽R�����z���+���5�Q"���?���SC&��nK�W�c>3`��0
�l{���``n�-�(S�tr�
!�l�?�^��!o<Q��5��!�X���D��0-3nT��={�R�?�>�G-�P/
���_�&��A�\~���C�=��4���U�V����������MR|�ȿXV:�,IK'��hq�w��Xen&�	�J�0��'��a���`%\'3�tt~>^r�!�
*/������*0n`�|�
���7���#�R����� 1��7�Ã���*��!_����a/V�~�,b�c����W:�R-�D���5�z���	���%K�T#�2��u��ߌ�I����`t(ՇQ�BFk���"q*�vl#���%�Vq�w�o��;����G�£�n�%4^�_ {6�#,,!i1~������X|*f�A�k�ౕ�ah�h�@��.�.i�s�IY/'q�0�t +�t�i��>;��)�kS�7�;~2g�H}ΚQs�M�]R\_������W������C�r"F��r��?Eſu��ڱ�f�ዕ�Nǝ 	k�N�"[�m�߹=@�V>��Y������8|Q�8MA�l�]�]SӲx��٤���ԝaaZ�%�]j���t��VF��1P7x��4u�^?JC�L��+�e7��j��>$S�I<�Vq@=
v��]
� i��T���a��XɋY����X��;��ߝs<�\_�1�a��v�����L�����Z<,�	��Tm|��� k6���r���1�,�q��5Jp9+C��u���&w�֜���KG�`��huf��`Z��-�d��P	U�*,��Д��x�&.Pj��H�zޔ��h�j��M�ۏ�;|j =��'���`�L�I7��X�P�T��3��l>���O���_�[z���J�N��;��xDm�Pwe�#���_<E���m�fի�o�W�8"������cؚc�I0`�%ړr��,���"۵���ж�Yx'.���)2Ƴ-�^@n���b>������%�0�&��%M,�0D1T��4y��� <9֕x[�16�uPG��R�~r��_<9�-� ;��Dz*c;"Qԯ�ʻ��Z�~��yO.�Y��iw�F�����P��3z�K�Q�%���߄AU����~G$Z��%ρ��<k��=�h?�O��?��?7x/\�~RO��_�h��Ƿ7���x`��2ZS��2Y�	O+>�c?N4����( �j��O? r>�@�
J�Q�$o��DApa`�R���/��-nLbv�:ww<Nʍ�#:C��W �rH�(�	aQ�Cx���JU�SH"2�:�wY���KJ<��}Y�b����S[����q�#<������*İ����]�3�;�P�T�.���5�`���j��X����3v������ W��b�-L�{ƦK�pAn��~lcFY)_L�ha����m63U����>f��k�&~��DC\�Q�^�:K����=�O���m��r���'�6���äC�$Ή�^gSgN[j�m�f����U��7��Зl�iJg)!�;~�m�6�`V
���M+��˄Ȱ��*�g ma1ߑ�ٓ��j���R��8�
�x;�NAX"4d�__Z;�-�Ty4	THMԮs�C�I�璖q��Y��lo��f(�<e�_d��4f��-�5�OǲtH}+���,��	͋�<n(|�G�);C��}�J����jW9�I���-�X	m��	i���#m�W����E�
+)De)I�T�%A�'M�E�*��,�%^��\^"Z��{B�"x���dh<Y��
�iPr���`au]�\��.���pה��dLGVl�T'�v��@(��`��2LH��YE�Df2����(m����{Y��`H)l	y��Z����׊�~ZL[��4̈�� ���w�45�!yi�C|��)����)AL9z��R��A�!����ӉV�y�`\�P�UO%�=�M���3��H:�>�9C��{@�>�� ��s�K�1ʁĨ�p!���1�*�S2Y ��h�xb׳J��������9�0f^����܊]}>?~G���q|�eH��B��ҿP
[�`�嗜�*�k�`�wi;nK��40I������*�c��j���2�aY���UW!~����[����[YKM��JR֔Z_0��������y%9��KRϖ,a���ZGsi��N���̵�;�>H`o�1ta����w��V:}$��l���C[�6s��_z��w}���C,L��YQд���/�E���{�R���}}B��$�E�_��;{N��a(,�gz�������oE���wۆДhy��¸X 2�A�f�eD����f�?�;![�~DaU�7�0�%m��j�u@g$������ 7"���>�t�W=��_ ~4��=�hS�܏~��.`"k�F����C�a��7�J����#N�@�9�����n�&���-é~U��T��h򨎫.�b�@�̱ҮEtҚG�{�
�)ɎZ�2�Zx�٢��!��\0E ��A6h�u����1���F�E4��gA���7�?K{t�~y���v�l
�I#	��eS��K�KȻ�+�V��0a�Q@��J./TC�8DNT�H���13�x3��M���^�BhFd����[��cۦ�\�&�-8<_^m�(	Ȋ���1��
`��`ܹt3Y������+T���5���9t���~�;Ň��l�2�J��4��l�h|�/b�_.��#���p/�M�c����\]�\�?�b�v%�d�W�o�[�p��I?�k�W�w�b ���-���Xf&��*�^���p�t|%�d�sW�q���6��U��b���]�@B�EMV����]�_,���D���D��G V�̭ؖn1?����x��73N����|TK-�*�e�����?�Rh��>�}&*�``�#��U-}I[�w4�z{^7W*1��z���f�r�q���ZB��T����2����ϘP��4p�l�_-_�33�չ�ߠ�)��V�c^}1+u�������j�٫W��-��[�_�I�W�(��;O�\��K�ry/Z+�g��{��Ö
�#6��U�sej�����J�/@;�rCa���ƙ����iC��oW�щ��n�ſԂ�+�#�@xfK"�O�r�����fVq��9��߿�G��߬�>/��?w��O�oO��9���(���ڒΈF�Ny�D��҅�����6qot�A�GH���B5n������s�s����Oĳ ﮟ��3�3�sEKKQ�:�JX�Zx���k(b�$'��Ϟ��;���N���3.u��L��c�Ed���1�ނ�v<��(-��{��b�d�l��8��;CU��1����������у�g�B?�#����Nt-9�|�I��_�vtdV�s4W:���\cG]�1З-4���;����]��?���C�@
H~a^#��E�)iI�}��C�j�9K����O�3;��L���L.E1�Z�H��zǋ�Q���@��i�!�I��z�3Ɯ�)�X���%_�$c�T5�(����vx@aA���`�D�,�|��Bޢ�b��=�o�a�e#c�a�M���"/����-V4��hٶ 	�0�2&I�o��"|ڂ��+O#�Pf��xf�
�, ީ9�!|�2���V��Y�!�������-tFW��D��`
��ѳ!
��U��.B���ׅ�5�\��M���\�����dO���q�j)���)m�x�/��~���ػ8)S�i2�I.��K�f�R.��A:�	���@�Q�u�kd��]�q��Q��wX���0p�X3hw��y|��P��/�M��ȳz���~�Q����"v`�J� s`���@�yp���7K\!^�]wM�~���cI�)-�����bZ:�"���R�}�b�(�(5������T�6�[��7a(�Y9ļ����m�F��@�3���Ҙ��y"�x�.h���1�G��̭�T��:�P�a�M?���l$%�e%e�5��� �'�h��V�
�}o�+�ΠԗxG�,�ni�	)��'��RA�}��V�_(����f5_9PQ�T�01�1���I�O=�n`���3'��.d��\%�� �b���<�ʬ��90�D�$��h0C�l�]�4#Fxg��$������u~�t?�.��TR�!�ک̼f���\M��Vk�e���}؈?�{���m������	g��E�Q/���-[�T��	��$\r9���'�F:�Tv�U���5�E{�4J=9"��v�h�i�}�8�`N�aN�2��j�Ҁ9@�s���>�c�^2�~��~GPof5�o����Wo����δ����<4�Ē���n��y�3���c�'��.�l���a�D��hI&��NQ�S�L.-�A�Y�߬���fL�Oi�3|����5�^^ԫ��P<CD�%���Ϋb�#�����`���J6�1�b��\%���H ��d�`���[�Z�Լ���CUt��ݶ='G��P��m.�e���ۯSCѸf���P�@+�R@���k���m��I@kL
jCчKs"�2g��C�e�i�Oυ?�G�)���:�2�w�j�K�1���d������*$�&rv�v��DM/��<����'�5t�:e(
�[z��l%�Ts�gII�`v[0;��m���!�����M���=s֓>�����,"D���Tp1���x��!� ���m��>D!�(
%m2��D�V�|YӬ4{��g�\6��տ��D3nG�еv�����T����oF�d�X�l,DJy�D`�9[�=;5��{1��iv�97T7�/�s�żg����HAB*�V�[h,���bF�+x�~C
*]��a�Ho�D�@Ec} �;�m=�z��zT�ה�hK ��u@�+T�q2�w��蒠�N�O�C)�t����9���}�,(Q�\�Rd�H~��n�4�����D_�t�׳N�,?ޑ��������D�N�h��7����m�k5�����͌�)�1�2��i$.�*�s�|�i:�O��Y����[��R��`f��v��p���s�m�a ����c�PC��f1��ys��M-,��DX�JE���u�F1�#v��C�O	��j�Wl���7�S8��*�1/Ƴw&ztY�&k�������|U���0�)/kqu��>�zL&E�!��=�܅կ�[�)k���"%ډ}5 Y�6����;�o�#W;W�7�O>8�b�}�	�D\Y\A�O�.)��Q;���"ے_��?N�3������zY�F��n0-�P�a���\�e�d����� �������ʥS�&r��a}���#'�dKxj���FH!vP٩�E)�V�X��Z�B[P箚l<vɚ��k)iί���x:4%\Ӯ��i}<�]a�pU��\G8�m�ʥD$��j�W��e�)�P�Ik��D��YM��
}���*�K��Ô���L� ,*�z�d8�K1@�R��q��>ũ�p�2�'KDJ�u��Jt��̟>�v�6_ׯ�%����8+2]��i��h�ԍ�ܷݶ�h|7Vr��:ұ�q-1ag�'>���w/8�%�p�'��w���HSx>��bq���w���$wsA�z'�����,�����Z֌�؃@[�<�
������T���HXq������>n�����È44d�,�%u�B���Z\��i-�RPc+�1��U���� 8��v!�R��NY�URL����i�W�"N�������2�ƻ��,�Lt�6�.�嵵N��Ϸ6���Lc�@�)��g���� {�4�����-���u M�t"��D��n�L�DȺ�/[/���*9w�����$��2���M<J�T�b�H>J�ޮ�����.�wpĊ�L�aɠu)�VӶ��B��[��2cg��'e�s=1��A�r����*�b��� �9�h�V������s�e�ӹ��;y�D{�d*(T>Gǹ�� ��m�R��xY����"b��L�mA~C䉥>S�:^��*�	�/�A6��OV��c-f���<���g�:SB���������q�>Pu�&4/����ۂ4�<�-[���p�%1X�S�"!��i��3孹�"T0�K��a�������N�&4Q�08�X�~b�ӡy�r�Q�(�ײ�\���m�5'e@��s�� M�(#�1�&��t��HJ>���Q��9ZI(����#��ظޔ��qRu;�IG�*�W�@��f��(��5��p�9��b����y?0U�:���Ǫ�ٿ8 Ʋ	/-)J�F����g��&L$0�*�|��5�@Ǟ98��3L����wA3�w�ur��\b���^�c�c�����O�mܦf�_`�dJ@i���V�E�G[h�򡺧���k3��~�<p���t�S ������{�7�o�byH*���/'aMrgpxP���1M1+%G^� ��f�@~Vw�w'{�w�"�Ͷ�G�r�gsJ�K�U[��Z0ُ2<i�t��fFA�qaP���2�1`v��OAH�+"J\���迤�x��Ԡ���<Xe�<ςn4��� � (�n���	�ɤ���%j������p��h��:D�t.�*iz�6��}�B�ܞ�Y�!�xo���;��* ��U�ߎ��8F�ҧF�"�#�I�?-5����Ep�ʉ�I�����|�vqE�?1ظR� ��I��5� �3~�Y��Re�8�,.ጙ��=(Zm�ki�!<c��%Zx�y�������KƟ.S�>�����qz5\�ތf� ���$�RRb�i�M�GjԢw�9���e,�I�A�n�!���[����0��)���e^(�Φ�e���l�(q���/�R�?R�dv��;sL����4�tS�y��G�u:�T��*pr�Z��A꟢y)������;�|�����u��W	6��R"VI��6h�ȹ����m�7�Y�5?��v��*I:,�H�`j�3�ݬ��d��l����\�"�B�YS{�3�j`��ׄYy)�w��|@����)��5�˫[�2�D+��J��E�όZ~uT�[�����Uϓ��E�MV�nB^�2����*"z�a��TK:��a?�ML����rת<���j�K)� w���gah���ā������O�M5����Q-$�n�I�s#0�1���UH�Jr~W  `\azj'-K_@񥩪]������jSd���5`Ҧc&��/�����+"͠����/�@�����
}������܀t�;m��T߄�'[�Վ�IH����E,7h��?��s�<A��o�l#c����7�
a��(i���Y�z�|�+e��F������x��duQ�w�O�!n�T��<8Z��i���D�5���-���=�[D��:'��"��@���H�n����^��8�6Ay�ښF%9�J� kؼ��-�c��R�<t�o�q_7!Fo<���f�+�<n�]J����b�T��F�f���wt�n�"�	���,��y��,|���vu�u�c{����X{�{��Q�eH�b��%.�t8K!�$��L<ױW��'ls����c�jT9֚�ħ��H���G�Y�YPS�chY$q4R���b�
i��Em�$S��6P?��ٻ�q��`���ws[��c�s4S}��(�0#���$5
�i�J��c�eG:�}�,'�+�#��]<���V��M�Nh�a�ͣ^ޚt6���ʯ�Ŧ߳�;�N9��ф�	I0mv#�8x.{H
B�,^*�o�},S�/�]�:`��:�����l�v�}  �c�y���7NLz
A�%6[	���˅�~&4a�Bs�֏���2����������5�}C��׉����Q��;�D
�G���Hy�����l�Z����-'B�|���ܸ8���W�明��J��CnOk02wQM�^J2��ռ9���#@�]e���Fl�-ȉ��U�2=4����̼/N'a��oә����d�0b	����:(&�q�F����Q��P��g��(��K�e\/��!P�\�*����Ǉ]w� x!���8�E�7{�Tc,�x�w��q9�4n�_�hv�>"����;ϳJ�1�1ʶ�h��_]��I-�7zf+<�;���"T�I9���CY7�1�A�{�}*h��6�a�`f>[`"��_E�z�`ET���_32��a��%}z��ٔ�'S�sx"7r��R��{��芈��M�����x�<����6�d!W9o�pػx�0p���B0��@Ҫ7Q7���ĤBٱ�CU�}����綩�T    ��j5�� ����~����g�    YZ