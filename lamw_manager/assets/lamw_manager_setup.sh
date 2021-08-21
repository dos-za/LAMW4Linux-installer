#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3608122813"
MD5="6653955ad65a38756b951956ade99d4a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23632"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Sat Aug 21 16:19:09 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X����\] �}��1Dd]����P�t�D�E��I�}�q~2��i���I�xV\��A��:�ܝ!�0ܐ�.`�/�Z�e��~`��\�`�["8��
3+S��3�m�M���Q����-�,�P"ܨ�����9n�NLV���2�W['�9K��,��Ɣ�
��<�4\LK�"7�4�TWd
H �H=��Řc�]g��Z�3���k����aX�� ����x�x�V[�n��*IC/�t.&�&���^L4*���κ^c��J`�$��j��~��ܫ�(���{}��80x�,*JiMbT��\�/x� �ڕfݕ�mh���E��D:΂Xe�z�=�3�@L+���~��n��tP�V�r�Rls�:uvA:y�쭢�b��4Ej���� Y@�BB�6�\-[l>��[g����Yʮʵ�n4?o�HStp;���&��z4���uʝ$ƖM�-�P-9o��<�x�3�4x��!��<B�B�J�s2K�0A2YO<���NddT#�h0M�+�丵xx�/>����5M�(��f\f�E�����Ո*���X�W.���!�i-,�,]��
(�����,��Af֡^h���G����{8u�i�c��k�І�3����V��l�b���"8�e�U:�r�|�OlE���x��̬L�����	�.�
1�@;�BP1ú$�ǧ0��i�Z ��������L�UF��l���d����TT[����<�t��/�h�C��V(u7�*Gp�:vrGK<:�k�i��v?b�^k>�N��T��$}zyfJym��z�a=��Dt����G#+I)��ЫW���Z�;�f���la_�F8��_9y�7�X|���|��*I��I��Yp�3��>ٕ�:����F�%(����`1�O�����u|=�<i�&���ߍ5��z�R��ّ"�|��ȡ���' ����wswQ!� %\���:����Y�@��V�����4Wl\�'�Σ��o^�y��;���k�'�����Ҷ�Y��>��K��2��7�QX�.��ٵq�4w�
���u"���g���[u����Q�2��ϙ�=�������Ы0������E}��X�l����n�Ѿ�N��(��1u�sހ�g�S��sM+�Y��v?�LgbK
���G�)��O$��<w�ё?�B�߄�	��/FP���k@gVZRtv�j�[I�N(�=����1�!�RY����.�J�R��78X�HB���uU���ȅҤ!乽4�eSA뜌5ڇaC>u��X�l�E�b�6׶�؏����t`{��4��'��L˪&'4�ݦ���T����J�>Ju�ZtLh^�34�DE�2�rɨXlڔ�A�+lzT*a��
c��"\-�:��m�h-Z�a!h����\���/���5��I��n��NC/{�M;�=��"<Y�1��}�����jz� a�����"��&�N�_���%:1��  ��^c¶P�Ϣt4��3n+@�f�D�7�a�/�Ou�s�+ :p��V����������uB<����T-�K>.����`X�p�_��Ū�Ԓj�ja��s��.!iOc�����:uV\�6�+�n��!FPW+VKP��c��`3;w�1�G�WH�;�_3p�p������c+���A���E�zRt��\/M�.��?X��q>l�M9�t��8�&�K��;���aa�"�B#�����ߗ��~���N�3�>����ڏ�e�)ê��|�������hfЖ+C�Ⱦ ���	X��&75�M7e�i�.�s;�������MX;��E,��R%1�G\Q�Y�1�Z�9 (7V�7�owv�W��e�~(���:�8��n���hP�'��\�\�^�I~$��@�9>}�㖜�~��cNR��TE�''��Gn.�CX�Z4������N����8�+
�.��؀��n��|�x*�x踱ҳ��T`Ī�2���iM��'�;
f���l�aͤt�$6�M�s{^���{]���y��\@�bZD���ћ�wZ� ��C4��J �|L�8�Gk�xVގ�|v7	�I/2/
J�bU�Ω*�e<h>����:`;D���O�B~���rH��S�f�*#����:4�ޠ�_��ԉ�
�hp����]�9>aE;3��L��W��߱���N9Wr^�V���@:!��#��p�/W(f��@�ι�JR��'�6�d��In��q������ �Ͼ*�=ǭ<������}�j&��؞2_K��5�2�7�g�1�u[�n[����ܼ��Jf?��XŭWХ�~��[(���7tR���6��[�䒓M����N���w����)�,���ݑ�5�F_�~:)S�
j~��Խ�	qV��E��\ܸ�-��7cлF�V3}�a,��d��]<�%���x��:`���Y���[G��b��?�F/����<�:Z@\�6���.5���y�x�U�J�p�+Z��$�&l�{>���^��d�ڣ�5m(�õ3Ϙ3�D����`C����"�]MF�N�2CV�%��!A��� �����<�֠�C�v���BynZ=w�6R�K��:'�Y���0�
Jd��$v��#�֒��^,�L���غ[˕��}���~�x#�ˠ5�y^� �3
`M>IQT3}�r������������|�~�2J�ۨa�
?���s@6Q[�!W�����@cɤ)��;�aq��WԘ-'%�L�n�9�`��XJ!��7~_a�6A*>��бѠ�jŘpU=Ts�=#��f��� �W�	_5n���Z�6�4��NvEUC�x|��7�H;��k��Ƥ��O�,��������_F��ΒUH&]&�sʬԤ��@���SSx���(���ҹ���C�	�Du��S�;zp��<����.���DCT�맙"��9�|uc����~ۨ�%���ҶC":������R��M���IG�KH r��%u�'IfN��&H��C�d^l3�"�2�7I-սYa�oı���X6iJ��28;H�����y��)�٩��P�`�9p?[�$\���������/ �,�܂��xO�9�֎���^��U 㘡���fVz��<���������:�_쾆"��5zS�K_\W0�s(!ƑsD�ɬR�<��r�tC�~����
/?`yui� WQ�k�U���OZ�s{�N���<�0!���4�wl��Dt�qj��r���O#���,f��,�ޱ�,��b���qԣI�J�P��q�uP�{�S�튣��#�����R�R�e����U�?����~��tl�.+�:��ф�&B哻�I�ĭ���%�k���d�׶��ԝ#i�!9_䴃�@�-�:���K��dy3�y$��He6��F#U�>��j4����l�v-�D�FQ����8٩	W#<H���������LDڇ���Xz��B?��R��yC�:RF{�*����5�-�*��@�I�җ�J4�(�+��G��i�k)(D�x��OQ�|<���g3J'����^r�F�4^�b)�-5JS}\%ƹ=j��X��Jʞ�<�UJ���>�_�ME��)R���.(��m��l+�FAo������J"�����G&Q���9P��DǤL�Ƙ�!b�K�Ц����院q}2�O�ik��X�A�%@��,(M�
�����Ls@qB��޳yi�,�1�u��~�'v���Wm�g��n����78���y�~�c��B�-�$���T�lP�,����I�7��BbˏW
�rF� F��� Z �;`1p�&mؗ�͸K4�<H��*T-��n~;[WfҞd�`�!�L��®� �	70�� U�%��&���T�LM�����c�f�4ZF!n*����-JH&�V��-�u��&���q��@P���
!V=�{��F~3�t�g|*5�}�-�t��M��9%��}�wsX`&�lHxIï��?�8�0µ��f@U��iG�GlP���m��i�8~๘��?7	��G��t�Ą���~�[�%���L�M;�&q�u�Iɘh�RH ?\���neM�l=��C	��k]��kS�NAJ���'����'
41L���׍�2��ǔ�P�?A�gA�a6h����̾��}�7�����o�k�z��;A�0N�M��,��哧�~;����ϭ���0���|��oW��sA\#��B0oŬ�~)�̸YR�X���Z�>�g�Ks�=@,9O�"����9�u4ʦ0wC���л�F		G]Z_ۯh���63�
4���+Z�NI��Wo�[*Gx�Bj���5˹�=63

���"q��Lr��E��g�[A����E;�E�a"��.zl� ?��!`"- � <S��A�HP�:m�5�-ϩ�sk�yˤf3O܌��4��?��w5��Q��*/����ݩ��wV$�L.��X#�� ٖc��pV�1P�y���'�]
y��]�A�m�3ZB��-z��c�.��}�BQ��Һjm�FO!~[tmp�|��v_�9��+u��\+�i&9.��W��J���l�7���&~(;�k�/y������W���FD��|��ѡ�>�GH���UO��<tû���ct��X�iɫ0-�r�p��t~�L��d����1Ņ��6r�T�;�4��Hӧp�9{��v��_ ٛ�}�+���H��l)
a�Y��̞q֝N�8�����=�b��F)�e�[�Y(�x�6T��1�X(���6S����w�� D�yf�+^C�}H׊ȕ�3b��N��������얽Z���Ci��@���D�X��x3d1���R�9�r;����2�o����7�6��ƕ�9g��v��\�oֳrХ���d�5����WA
_e�
F��E�� g�~��Ѽ�=��Q��>Y�0~;�����b��(�4Y���"	���Wi2���� ���F�����Z��ӕ;~(rL���EG�@�m�w����6�	����5z�+�X@*���<�t�(���@�v���x�N��\0��e�=�:���ǆ3=�6e�>/��r�R���cG,������ti�n�)T���������5�|9v����$P�Wo�h�J��ܗ�����/�/�\�B �~'��mX(+>,��z\��^��nE�,��nNP�Mn���+j6�}M��8�� $���m:Bo�$�3�z�up�o^���F\���w�*d����h�"�3�I���T*e���C�W���ͧ��z E���q��*��vRd� f���'�s��w�X�P��M��V��7��k�����:<I�`v,�	��Æ�d�3e�ARa�-���tb�����\�W �\n��Y���)l��)�#e�'�hI�p<���F�6f
�w�;{,���v���,	hj���p1�u#��4��7Ռ�MN+�#C��!JTh50�:�S��P���#VM`x둥�5&R9���4�H�*������{�)��U�����}$_�������[���rrZ#��yD��b����-��.0�Q��wUl�3 �(˘h?�1��4u��>���)����1֚r3��j�G��&[� `w�5����%�eT��$�F�������7�"$�;�%O�	Қ�D�-�ӂ�j9G$IvD^��o�
 ��U&�Ĭ����䦴����MHC�W�6EC���yj�8x��pi��p4M4r�J����v��:��ƶ���뱞�~���p� ����;�R����S����R�4������o�G��� &�f/��}�X�Һ>�C$�*׋����-�����_R����b�s�_�Ru+�J��xus�O�8�����W+�q'���W��b����8Qݜ0;�2%5Tv
�vܕ9�
���D�!���P�UM`��HW
ꕩ�w��mM�D��yA����3y����'JT���k�W<Y��e��Ʌ���Q]'i�ƞ�4��˟�.�Kl�t��>�j!�`�k��.ؼ����]��h��G�>?]�f��ZlMߣ�]�Z9�b��}�ޖ����ٌ���i��0��\/����E�ӮX�������-t)�g�3��	��_��:�5���1�B���$��6c��Il����R�rrv�x�#^�e�WMJ�(�u
=g����iЭ`j���#�֠�x���{ңN�.*�H���NGD�q,;�q�o'�.�����Uh��U���F~���_鏂����^��N B�t4���	:<�9,�f��K�lu�����S�snr}�3l�-=���c���|�`������IEraWT���������i�|N�ӌ(�� zo���&�/�Y�9��<�˞0Ih�'�|K���s��63��L����9Њ�����vr����ʜ�F�ذc�e>6�K�,�k��hcРLyt�9�{#Cw����c�4�s�e��t���޵����DVza"3Y���t�RP�۵��ذ�m�F�9:~"`���_p
�j�̉�
8˷���K C�&�	S� ���yۧ�yMY�4H?S+{�9S�����*���4�}���0xnH�o�5���\��
Z;TUs��5�C%aۨ���p<�5AGp2��{ϸ�kl�����8�{
h�z�-��ɭb��F�o�k�I{�6g��jt�a��!�"J9��h��Nq,͕+�%�������<ŕ`=�C��J$g��P���,`�z��?؅zt��b�Bmg���T%"�p�߃e?�����L����nlS�ђ#o������Q���i��S$�]> ��5�,�A�L�Am�aU\JC��(�,/��v�AÒȐd��Z���B�&��m��g'�M^�Z%��I~r�AD'�k*�qӥe��W���\Ikoz]\�-Q՗�m$]�4Z4l����PD�bZ��2x��R��GX;����V��ej�"���r�+�C7uQ^jhψ�Р��~�kǰzya@#w�]?�f���(f<U�������*{����b��I�j��

�TXw��+�Ar��h�p6���$�\�3�*-S�3���pp�.y�]��na�也�������L�SHr�ds�Ӯ�LIݚ�t!�z���� rU�����f���{.\��f�ke��$�)�ԶV��K7��<q�U�]p$��k��NgU�M��A���cW�?U�ܟR�0�*��Ł3�����u���Y��p�]]l�x3h:���� ��o3���� @�O�
��}�v�u>w���<Y��̜�d�Af�	�'h�
j
~ys�3�u�SmƓm�:��0�$�����jŜ*�=���4�Մ�W��Yk�Ot
�Ŷ�2�,��v��:=g���kຢѕ�����>4���W��wlkJܸ���~��6�eq���I�%���Bp����*��ኝ;d	�#OaǼ��>&p2a/q�`e�)�y�,��L�v/o:-F�2{}c��_#��^% x�^����8�g
r�A~9��������"?s�K��7�1jf]k�F`K�M�>=E�	�W(j8��-tk�8�-~�ޞ�E���b�2e��j�G�mY�<�J�]~!4+Y�n��k�D �[I�Jf�Ȫ�C��z�+*�!J%�>�; '��p��Ck��e�'��5R,_C��	A�dV�Xt6}+]fQ�sd6�Fka���g���� �2�%n��0�����,��ws��'H��
7�&��FR|=�"A��Mjr�*9 ���r����NV�ޛ2�C��_�ų��bwH�ǎ�[�̷� |q;;
լB��)��*(�0�_~Do�R�j��oQX��B1�D��8%��򢅍v�)��!�+EK�ĵ)���M��[I)�BtO1�n�T���<�����̧��더r�тXS�2m�)�|�R�A�.x����E�J�]Qg�}tE�Y�(�"O���J�i�2k�d�8[�-"�9iN�~cdÃE���1�V
:��� 5�����d|��Sa�������)�:GTm�瞖,4v^��gH�w�Nv���ש���t��x�ӥ B-C�*���I�q�þx��4���V�,�f7���nw�q@�	�i2�M�ݑX�)���p�^V(e�
�|�K��}��2��T��>%UW����+N�Q� ȣN����o��S�=�Z_
��;B�T`�7|hZ��H��Ɋz4���8���r.c�?j΢�^�|�%�B�I�r��Fa5= !a}?'�����)�,�(��1g�5.�\	Z�S�Ƒ6ۚ� Z�/&��s����F����en�fo�!yd=��2x,<�4�j��
���.L&�^�ww�~��F��g�I�Bc`\�a��/%���]L�R�6?��hPr8HIz��:�X�~�*z}���˝�	�8f��0��Di�q���9�b�4(kc�{�v� Q�iv�"�Ζ�R6&D��N�ie�(w�NZ��{F��3Z��ʟ��;ӗ�ɯUW]AI�?d&���&��X�������mg��sc��4��	�q�R��g`�W�Ԅ8��ᤨ;/���}�E���(,�N{&�/�G^�wb��w�%�P]Y��/_x�.�L�.���b�⵴zv��@,�Y�7;�{�r8l���$!5=��14��oa+�v#�ܽ)֡�w
W��>  ����Qg���P� 4�ȳL|1�w	�Z> C�3�O"C��zy��d���TV�GS�O�̏�@Y��	��	D�j����g�R��f�j��N���%�{kT��K���|�@�F�	��}���)E�\����t��1���3w�A)�n5
/��s#�sĵ��U3诜ǡ��y1WID>��z��D�4���� �[*�}��.�&	�#�N��)2�7�	��B�~�rM�hU{z_��'�K�͊ �����MIbzT�U��sn�S;`_I�"P���$�ac�?�X?�2�>stm�"�Wk]58�]����P��[VS��4���������Ù�:�<eLr���E��z���3q<b"a�%�����%ש口n�S�=)�b�hJ�cL��s�U9�jj�l��P\.m��w>��pGn�K<�N��;݄�&e��^�-��rS����ާM@ ��eI��Uw��oW�a��}\�`h�M��)\ �Q1�J�N����S$qW�j������0)C̵��^ �����@+I���?��$�䙴>#�E�R�p4��@i�*6�U,��!'/-!a�zk\C��cPA����E�|g�d.R�f�I{��I²Ǫ��C�!"gGMo��*)��ٽ�9v$ڌ�T�����.J������E�>B�5�,�����Mf7��^9֢Asא6����h�F��#[��v; �M;����|��fYb�Ta���^Wr{�{K"��uoH�GԻH�^x�%-Ϋ�JL��f��Bd�wj<}{	�#2��.5&�ZoG{Bv|�ϕ�1�M?�i� =��V�u��fl���3��9E����l<�p��MN�M��'��w�
�H#�-��� ���1D=g��~���Ϳ��������⭒�{����t@�	��R��i?��v���9��m�!������,O�����E-���+���E�������bC�؎;m1PY�,x�Ҏ��D�\-�p���� K�S����3����W�P��B��F3��k� u���S��;4D�=�������Qm��	��ۖ*�g,����?l)���|7����3�<+���iW{6�/���S�UK��c�$j�o�0}f_NAC���gl�ދ�h��8RC�~JT�?��J��Nb��80$�>P�G�W��J�j����o�C(�t|�"���]Q%�r��J��+��h�7\�Ìb��0M�'�����h;�)�zm���]=�G�a�#`��xa�D�l� ogLᗱNA��NIft���J.K(L�F�V!�eNF)�{Gq�'e�X��<�����  \���dY��N�gc��ם�g�`����c�m�g�F���L�g(IU( $�qm��:JǆƶX�9��Lt2a����*��ܧ�s�����V�6W�E�����y�A���-��/������ꝎQ��$�bt��s�Hb��BJ~Y��o57��$%�N��iؑ$5Lc6d�t`y�v�,.����(Gqܫ6a�D�4)w���r�v�Ԡ��Ám`��;���Ï.(�!)k����@ϴT�yR��M�T�ͭ��|Z�x���[�./U
q�s�
�2y&��)������HSۯq����l�8D�aM�yZ����0f���H�i�͛�P���<ە*k<v�!c�i��,\��Ó7����޹���yB[¬6��nE��%��Xzm��c��l8!�B7
0��]��% gI0�V�
��?��h�}�\_ߧ�&�3�]\�zl�t�M'38����Y��/���G@1��}�.������������Z
۪08>@u�.(&��]�:�~I.%�@��E�I�WA*��L�|����v�t�UjX��p߯�dz|e`�[�ʝ����Zl߄���]�$]z���ځΔv�&E����7��[vm�|b�;;������I�VC��9�@]�����{ө5@��Γ�:Ğ�О�J�5)�y2�pQT~���7t;5��i�m,�j?���H9�
<t�*��tWD�W�X_�����.7���T��ŘM �Ætsoy>Ό��f�3lM�
�0nߙb'�b�G-��H���`���P����}�
/���7}��s�l��*���%J4wQꯩ���:�11l�muGPi;�
�����#�;7M��T�buߪ]8�<b���p�0�ś(���C_�(�l��?���+S ��#8�����T����lS;]�֙��1yk���I�)��[id�%���Bn�C��
��X�9;�� S�d5	`b��Q��������y�t�h(ǧ|F����"�ڤ�\�x�I���/�{��#ɰY���8=E���INU>���VvYE���[�ȮL�S��o-̯l���N��O�s��t���	C\4H��`��P���]ٿ���!�&wk�.t���3���8�`ED1����e/+9F��G�9�oK�E>�ҦTZA�'��F���=�	Ҟb(w�z���c� %+����%��U�b!���S�~!?�v#W�0E ���`yC93暌˸�|{E~V���9c1F�S�K���d���ZFy.PC�N�5Ԅ��{�0]a9�{eK��3FeYM��L�dI���>���LF�������u-G��$������(�m��E��/��R����h�݅j��l��ÞR��}ػ��b�b�@� ��Xs�S|T��������ms }�1���V��Dǘ�/Tܓp���I,\�SK���_F�G���

P�˷�h`������ �81M4��L���l�7$����-_�`���o�m����\���={C��S��MD�<���d�*%6��5B�z�H�p� ���8����$לa+����.�V�k�� LV�%[��=�{:ɰG��A�Anpaڧ�ʎ�`�"`�.\�� E>Ž����D��^�
 ��Y2�e	�:��A�S��;��'OzN���I�@M"�t��[��阰�Ü�ig�}0h �t�O�֫x��?C�9�x�(�ſz��֭�z�S��*��s+v�s��GMҭ�����4��{>@�;��}�A�V����W�7��e���>��]��<O�,���c������)b3��a�gڮ���w���7Z�WH��<Έ��bh�VO�S�����-�~�d�F�=S56[x��|��y�7�{�v���T<�*[��Wǂ���z>`[��d%�{sEb*]YG���O����u�^��ֱ�Iͯ��Z ���?F�l�b��`߈���`��eB�_�\���Z�<1k�v�i���g����.|@&��F��}���w_�:aǐt*d��1���9#�0�b��T��2��� (�B�&�KҼBX�lP=օ�̢�loj� �"�g�'�I��!$���S$�jF ���U9��/�S���(em�S 1|�?�K�r�Qe�J>��r��������^��H�?Lr��"�Y�k�0����i��T����A�~OJD�N�J���wjf�O�g$v�E�3-t�c3{�j����2��TA��\�r;NB��6�L�������|}:����݄&��(����!�hY2�[fX�$�$�eB�HPB��3Z;��I����a�\�$B�Bs�W�ҙ�fw��+�-���= #�l�2�+':3�� ��e��2 �0�4v驐?&�l�|��r؝qf*f�>9�67g��?6ۦa6uxO���t-�K+B�0W�HTo`X���9�n�p�K��L�&R"m����d����R���SCǹ�ǒr^����\w(�C
W���VZ�t��g��z��^1�Sv"�6�IZB���0uM�iF�{�>�$\����T�õέ�x4��Ԓ@�����.�9��&<��e�޵�H��B���U^��K_�GD�G�sdJ0T9kiTy�D�iq��k������	';t�|��s���	;g�~���풇ք��h�|���Ǟ)0z�p]�o�<z��bi��O"j׊�4�k�MF���;>,�;J�ą��B
��ȭ5�E0E8���ܒº�9=H�Os�TkfS����2��~�]M�Y�+`J�N��^M�w��K�	� s���S���zI+� ga�8xн�q�F��E��q�LH��'��y�	�a�7�Ғ��/�u��V2�m��y6�Y�.�'^^R�r�B\	=Ffz�$��[�"�����������\��B�����<��_�-[�Q�O����to�N1��}�0T��?�,�i
-}���K���I��2�W�]��:RX^B�r|#/k��q56�"]��Xu5�&�����w>-	i<��]��SQ.wʩ�mZ��)@�ܵ�J՗��iN1��Kf�*���)�sk(X^��<�~���[�����"�2-0H��I����l�z�v)�1i�oV��.G�c�
��% :���Y��ǫ�?��Ws�Q���2}��J&{�p�|�B�qL�u�wY�n$�zh.��2]U�r�ފg�yz��
���� �#<ՓI�#Mm}�]��$����Ѓ����P�X��d9� o����m:����Oq��&ll��� ��]�V�>d@��1g��B-^���6n�oY7��\ �ɍWzn_�e�%+�Q�X�X����/us�l�ܣ#D��Aa��
<�h���>��;��0MY�m1�����\���,d����M�Z&u1��V��(�\�*8��̗P�D���f�F����(�~� �ð�ViTg��ݰ>���w�Vsm���J:�
��{��p�}ZD2��F-����5���w�\�q�W9�����*�^���av		������t��/t5�?Cs�о�ŉ�Co�y%w�ӣ�De�U5"w���8T�Z<�MH�`#	�+�f֐�Az���y�ȑ\.��[-�@ȯ�WM�����x��T:� b���V��W�6K�'��ё+^x���.a:�gEu0��b��~򯖝��=f��4Ϻ���J?3X���;��̊4<˼"3�<닌���W��me\Y�36g��8�����V�9W��MуW�p��Ӆf=��A�Vʙ��!�;*�
�9̂w��M5ׄ�)��ho���Ce��,� Eʈ�|΍��p���0����Q��dܦm��.��M�b�\Qy�C^�g�+��ף�$���,�+��7�ksK��W,�5��A�����vkHMq��Kw�97c`A��瘭{z��K>��GYch��@.g�H�u=$Z�����DWk��ѭ���Uj)V������&���j��EO��N�z�k��[��x�9Χ뢐%�&�����8?�4\_�]}�,X�#}v
��@`���=q��K��� �+.h��-wP���/I�ih�yRZR%Ӛ	n�O�baM�����Z>=Y���K���C
3/WvrP�T��x���l��tf�03��3���y�^9.χ�g�hF�Qj��x�D*N8�ޝ}3M����nx!�q��Wۉ��k���W�}g��<3���"eB�H�	��6��xҗ��bYq!���E��	=U'HgɒTg�dh�h�W.�$=D_���P�B���~�fU�.(Ntc���j����K�� �ʲ�\ӟ�����^��l������� ̓�v$&m�f�R�2q��8XFƨ�z�ٚ4������Cn��T�Ʃ!�`��LB�<�����N߻�(�߳��?��7�O���P��wn��C}~MR������z�7�c�X��9�U���|غ�-�:pY|�H���]�,(���mJs�%�������j��f��Á<Ӭ
 -�^�c�#xSTTޣ����}��v���� ��J">�^��u)M���8�+B@U+s|4�'�=�l�iJf����%�z�Y��9Evq���U������>���q�ˁ��O�xOi�љ��j�/�/�#N��(�c;{ʿA�e��Īz%y�����	���;=�=�E�|�R��P|�D��G��R�jL{A�wBr���;��ML�o\g��m��4A�ˇ�=Q
�'�Aז~"I@x���� ���v;���r2���_��+�����ג�F3�_�j�h��	��Q��
��������VI"���"[�jGW�wK�[cu�T�Θ�R'9;�����k�t�x�i:y���]�w}��9��k�J����q���V_ۣ����ϓ�Q��9!�H*���_vNod�׏g���[��fQ*�+���;D��qk+` ��&mڹ��Lh��r� \! �P��I����]p��@����&5����?����%���t�����lo9�I��G���Az�z�#�G��?�F�S�4;�a*��k,�:a�����p�q�#;/A�tV�0��w�~>s�-ӎ�F۹������-�ؽڴ�1���N�{k����c��h�jr���~�f-��j��X!���I�\a7��M^�E�GUpwtG�x熦����L�
���L�Ϋ*�Ia ���)ܹM�fE���{�.�|�u��LLo�
b��rV(������WGI-�o3�h'����%�k���A�>�~V�ƙ�+R��eP�j(�s�⊄���lb_F�@,�����B�W<�k��}*���O�X�`1c�C��}-X���<�b��Ee[���@���2�C u0�q���E0lrk�I�Km�J����X*o�2~F����b���Ms��M����+�-,*2,�<&���_D&�����fQ��ف�CD }��^�\�Q��o čy���Ţ"��ejS[��s��������*x��_���Vz`��@,�-ɤ@�p��<ТV".�J����)��#&���R~x���,M��u��5\�8;i�A�� ��ڪ���T����X<
�|��u�B4�� )�I+�������Bc1���X���:�G���<�l�}��]�&��"�3h�<�\�2�R^2u`i��z�1pdDԻ�dC�+�}�e�m�_�O�N^iu	!�*�A�;�U��:6���"�q��|Ğ����s�����C������η��4���*/��Z�KtƩ}��I�%���SYP{�����!��t���bX��Ry ;О���c��إ�$�0݉�[�7L�mS��<#�/|�lPYo١Z��^c�3-�wQ?2^�J�����/�g^�-��ǖ�n1��I.Y �W��}�h����u�p����Dے��i�Sm��cQ<�ՙ�p�H��n�!��f�&�G����)���R��}b��N���&V����}x=��X�s�<�h� tW�
�΋����,	�������|&H�\cM>��v��M�H���@�@� ��Z2�e{|#��-�?4d,s�\oO��r���Z�W�8�+���ӖX��*3��F���'��Ap�NB��X�e�"$��]�J�G5�����J��CzJg�썛�$i�S�	W�'(�X|߉E����?Yy�/XOh��6U];"��5~��L���J�n���$���B�k�3��D�Nw��zg���6�ɞţd]`K�O+�ё6䈇E8:||4~jJ�g����$�s�Ѕ���~�����d1�
���2oE������8=η�#��*�!��M�$�r`�jFV�������-[Z���d�pM�nC��z�7�`��|����r�va����}���=X�?��vm�̓�m�l� ��c9xˎP}]'�I5��mÑy��L^�� )�mo���&1v_�>[Q�f�S���m��?�1�c4u��`�;m���^�� �+���?���>���&w(n�/<�[	z�6�
��]�bּR6�Y������a5��E h��g?$oq����KaxsV�Zl���bv'j^���f��&��c����z�+��W�1H��3�/M��8^�e.�c 0.-'+x�!�ʋYDT����ב|';Y��~��&�����{>2�sj���?[t�hxS����m�N��#��qtb����C{�<D�$���|s�[8�^w�fJ�p�Â�'ř@�չ��Q�К0m	���e���&S�.�!�{|��y@.���0��oS�
�+:�}Y��t�c8���`N&�Rq�������}M�[M�(#�_�-R��63bL��n��;њTh�Ԃ��Αz��Hd�_�.������37~��)�sxs֍� ��L�_�����z^p)z�`���}H�m�m����5����]�Prb��CG�2`s�!P6Em��r� ��N9eUb�m}���1�GǾ���Q�����5��}�Q����˵{�U�3����`���F���o������O���e'��q�7еf��@I�SP`!�@Z"�a���w\���+,]�<|X�zQ��~����)5Ջ��)��^�o��0�ѩ��(O��gh��(M��<2u���*Jc�+�l',�+���ij��Fؚ�I�]��2e��D�5������R�w��i��YC��f�XG}�T ��Ro���g!�lD�'Df����g�`�ȓݭ�D�Y yx��Z��P���y=$J��P�DN�#Ғq�$���l ���zS��7q2�NmJ�`�ƾ�����u��>%���q�bL+�g�Ph6�~�]w:��s��;�ۗ�=���D��<?��&3���a& �S9�f�#l8���K�$�h��d�+�ԕ��椁aQ�����Q<<�U�1v�x!G9�$;XѲ`Zl+i��؀� k�N��1��'�AoK*�^�~i,��8����A0�a����d�9���[q4�$&VrY�W#�m��V��	m�4��K��;o>���*�u@�����k���"�.|mYk��&"�����sIܺԜ=g�������*���%6҂=����e������V�1t�����Ӕ0S�~�m��]��D�����%
{2՞#-cJ��l��j�~b;�<��|C��s��<�Iz:[֒#��5F(� Y�Nj��8[P<��'>r!+5��L���?u�����A/��0�F;��!]�!���h�"��B0/�����t��h
[k�I#���"��(���@u?�l��_�Y�-".)Y'f��R�F���b���<Q�s�d��!���^`���� T�t����%��H��n��tM���W�J��1� �5��`�����A�c���]%H0���-�-�G��D$�Rv ����V�5-�+HI`�T�z)�g"�ԍ%�~�h8�"�X,S�Q���Ե�Y��r��TcԶ�N�ң�}L�)�k��4�
Ԗ�c���a*��!���="*_.��k{`�Ĳ4���x�o���CB_m&�`�Ϭ,��GsV?��*u��lϒ��"�-�T�T*� 4��]���%Iŵ�����g�M���
IAe��PVOu��gB������&�
8�nT�P�A��1Ho�+�f�%�í���U�)}0�7;�8'�t� 
�mk��j"����d����D�����ϧ�}Ikm��f�{�ջ�{w�8��Za|ve�Q�`_K��HQ4jO�G���lbp"�Á�4����Yl����G��xX��%f��Wd���tP��oX?NGV:˃�����M�������������?�Y����f�%�W�*/�-����5mC�i�.שYS�6 ����W�^�(��C�k�+w�"pZsƱ�g�bƇ��#>4d���m�;�q�)�� BӉpпn��c�^���.D4G��+c�����M~��2;��B�U��;?�k�b�B�٧�>Q��ХS�n��e0F?a9��eujW	�MJِ;��zn6���4]�+K�-D�bY2�&5�
eI������J'?��8q�5*z�����-�%��MT��<qA^W5!�]��_
LKA?�1�X������k�8�I�� �q���(8h�eY�?�7�FH��AR�X��G�j�'c~����Q[��y�� i��bM�ej<d.-PLu#	�n�7^H���5��9��e���4w�a�p�0eo�j8�?�(w�r�P����rG3%"u�X�Xݎ���4Na^r����'3��W�`��.���uF{Q��	�-ԅY�������~�<j0�BL���7�z`��I�vf�L܆g�}G4���D���(�h+�l�s2�_�&�#��4|�=d�x�z�M�����_=L�n�j�8B���Y=}1Y5祂��C���6����3�8wȼ��!�>JhQ�X��u.�&�mIU���i�k�B|������˔�w�z���������^�y�P�$(f�&�8��[�u>�M\
�fO$��ƶ	9%�/Zb;��a*��t_�;�l%��h׉.qA�L��,Z/m�
���qQ֙M��l�����ߞ\�ZΤ7���#b�:�BD��P��و�����P���Dd�7��o�. ieSb<�d���7?�~��ۆ�&Q�4D���|�i�;H�s"�3�=��e/���ۇ3Ջo;"*zhl�0�o����U�4^�a)��H,e�N:$��ֻ	�b�+�+�j�l�ܧ�\�1�D�E[�{X����/��v ��Xt�+v#<J�����V ��@��-{�������V��d_��:�*_������"�U�����pv^�$ʅFi�����n�Z����M2�z�� ��<BcP]Lu%d����.ݢ�N��C��)A��ni��5�	d�a	'��Q��������:�w��pR�#�s�2�<�k��.��P=��~2q��$��Y���}%���4�j�!c�Q�/Qqޚ��<K�m����O]�@�*0�p���*1
���[��P�0�!��3�"��>BhvK�zY�F{�y� 䱉����N�M��L1�[b���Ga\��5Y1�����l$�"�}CG�G�a2d	�̎����SU��\���
���������`k���H�vd��3#����m'�b 1 B�k֘�!]�?��r'�	2�)L	�2Mk桦�#zd�1=ݞ1��}9�+�p��L��1R;��!km&d�S�I�%ZV��wv���� a����Փ����i��cR���B�r���Y�	�|c79i�ywF�s3*�@#y�x�I��'�x#����)og+ˎ����J�U����`'Z���>�*�2@j-<@�����+��l��ɘܵN?�W��d)��e����y"2&C�c���a#�����$;��8.�I.����>%� �n�v�:��Ц���C��$nL�h>��,Jj���W��^$FR�ux,���#)���q�]��1����_t'L�ĭ��"��%�k?j��T�])
5��� 'hUo,VQ��$;V�5�۷��0�on����I���=%�!�l2�Nk���%�+=%��H��w8�����,������wǈ�H�δ`_��W��͌{�z�r?��>tNn�ֱtA9�x���s�0��a�N���#�����A.�5\S.3Si����;�EW%}����!�v:c��K�ӡ��uɨ��<�/$1C��g�q-��p?��]�K�� �V����|m����~�����U��f�Er���2�IB95FGAJ����/s���	D�n��%kj3E��A���~��������\����q�d�XH2��Z�2��\��Y�i{f��R��;_H�E�Y��l���a�Ti�VU����5>�;WLf����{B+8*1+�?� �kH �l�b*'�ś�e|"�gK�ט�t<�5�+��,bZ6S�h����!�������I������XU\j;�j�����rN�e�sg��j�9�J���7���=o�}P!	#題�.5U�Ój�AU}4�T��MOR��nZ@��� Ì $,�IC?=&�dc�'�#g�T���<k�ц�QFoҞa�/G�TNLCod��n���F��n��K��7>�T��P���� ���%h���B�g��*�2Aa��(��_�i/a�_�M�>U)�@e`[]�oc���k�Ǘ��ohx�� ��sT���#�X���5��w�]��<�$�Q3M����gv:��g��,x80��m��٥l����1��4����^�J�!)�љ����y��[B����^ͱҳ2�~��3���kr�e/�a�E��@�?&�CK��@וd@����)�T:�v��i�P��_H���(tKyh�I(��3Qn�r���5�<n1�E<�E�����J,�H�2����J4ݮ^<�OB�Q\G��kòg�7�Y���<2�)�K�pb����~�>ic�GD��8q9�.K����������}u�ʅ�W�5N0!���K(I+4�<y��U�d\�!�3ܱ���$��߮�=4{M�P�INb����ܶ��$�ܲ�)C�O��>�pc��\�Nqƍ�`%���nV9�>uW������(G��Jj��8�7�����c�%;I�u���!�5�[N��t7r�CA�z�9S���S[�u9fi������0�\;\W9I��%A�v©��3��s�Rl�[Ȕ���+��^�mH
�A_ �!%R� 5{��7-�	���K�a"-R�+��lZ�1�Tv7�Q�of]��`4C�v�g�ۍ��(ګ�R�KeGtPȪ�� Xp9�DEq��'5��R�i��/^,��b  tʊ# �Ó�_g@��F�)E��?���S��;��cJU)@N�:�7�Ml)�ĝ����A��v1��L�'�x���t��6��`�R���+�c�q��(q�3|`$2�ޏ�X�b�t�f�lO!ݐ���A����Vr���AV���Uf�w��΢��W��TB8&|��Ţ�${Z��WA�~�M׷��ǵ�>� HΌ2�8�W��������OV8^G)��GuF�_�xhJϫ�/5�u�l�����nR�Vՙ�Ш�e� �+�U�Nl�3��Ƶ,�*	N�ꗐ�;���7O-�@��2���+�A�o��&����	��]����
Zư��7�deר%Y��(0�S�;��ͼ����zu�X1��Z#?��@�Q~����*<�������VH��T���")������M:"�zD�_�����E��6��?��}�s�!}��m#o[�k~�{���Q����0�~lk�Ē��k�����N���b�e��FZ�o��H�����[즲2?A���IFj��c �{��Zj�a������%��J$%�(R����hdz�����ڢ��lN=�<�\,U�2�=����f���c;Y�<w6/�1@_q� �={����̵"3��8��y���O=<Z���
i������Ù9�v;�P�\\�bu��\s,�� @tl']ƊG3�>�\A�~����C�<u����b�T���G��~�Cwo��]��Nw,��W�K+"J�ǁ[9�Q|��دl�|�(̲���A�j�^��u��^uc(8w/H�_ꀷ��-��4g�'�,���s�V-|i�����C>�lQO�5�,��(�(���]�.�q��s�Chw��<��z��b��.��P�b�t�+z،n$��Y���Rp���l�މ���H����>�M,˄z��(���֞l���OV̴�pE"8ߢL�ƢN�����â���Q��R�K���S�7�1J�ǹ(�[&�u�4�'hG��hi��ڧ;�)�'�~%�`��� �k��J<�8(}�2��sAP �u�r/]>���Yd�U�����T��:i��8�m�RZ�E�d I_�ev�Wj�@�,+(*��e{�'�V������j@|	"�Hv&�']g�FcA!yZc���#�&��L;���dU�&�ϝ��b<�Z��>]Wn�i�f�5�w5W��#׷5�ө�Q�j�N}5�`�0�r9vsB�-����Ř>�I+z՜N�L<�1���� �>�C>�ğ6C%�����#�d��0�;�g���,��slJ���zl,��Q�eK^�s�0��jӷ�e�i6���T�GL�&D:��>����Eמ�/�Y>�1��Q$�@T�INMT�*{�dzYk8	+wB�E�����D/������u��S��axSΠ}}�M�{�X� ��9ɔ������F�&���V�������Ra
g#G��of�dLE�g�-�S*y��YAe%�N���S �3��
��Rc��#��%[�C�Z�BZM��X��y'�-a��Ļ���!�@~���R>{�BJ8�+N��@�
�-9�<e��"3�{�g���E8�2�)ķ�����T���N[AI�����3�����|(���p���똴%d��z����鯵M=z;+<��Jгڽ��y�.ϥ�2
�@iЏ��DWg�◮k�A�Ⱦu�q�c����[�`���F�#���O<�p��7{*��
     �nzX��� ����&��ѱ�g�    YZ