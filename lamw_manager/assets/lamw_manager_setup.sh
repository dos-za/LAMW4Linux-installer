#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="760574501"
MD5="4e8058fe8d2893c675117aab670863b0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23916"
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
	echo Date of packaging: Thu Sep 23 13:39:18 -03 2021
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
�7zXZ  �ִF !   �X����])] �}��1Dd]����P�t�D�rŊ�5��&�y�{�[קp�2Ӟ�������=kС��D'z%�;GlH)��@�|�ҋZ
@�\������Ao���0�2�[Oz�ώ�Q.|kbmW՚����@+��	;�_���ˡ��is�8 ��;����1x��Cu���vл����>k��e�.�!֧����y,3"a�D�q���mu8[������nr���9�0�K�vP���?8���u�R{m`{#�d{ER	��h�#'R`�ʬjn���ړ@�o�!��\�Q����bY�9����bʉ�Uw\�g��~�Ӭ��qj�<����+2��=�w�ݰ�r<kZ7@���4�<F�b謾dUF ź�[�>+�>#��8m0a66���|nj�����0��f�壺܆9�Ѩ!ib�*�O	rt�\��U@�M�0ip����z�<��k��/}�Х
jy2�Q��]aA�{Wru�%�d���dMY ��@<kqBlD�eK���Y9�/���u��Υw�����>��ȡ���1@g��ɷ�G����_�U�����k(O�?{����B��i�UOuur�#���ЪL��ʂ��&�����_j�r��}^��1*�T�d���뱟A�'q�:�����'���)��8e��X������`~ ���Ѡ`l���pzs�����3~C���KDdG!6 ��.�f4���Z癝�O�l-Grc�Ϳo��o�����[���� ���y������3���I|�C��[P�4n���^>�^�A��*şJ�ϑ�V}%�yb�V�n���o5C��oҾ�����ςM��Oݰ3����������G۟���c�ؚ�-�HA|��#{�l�{X��~vJ���]�:��_|�m��@�W�VlK�tw�˿W(�  ��T��F�L0��7�t2>O���#�`�[PX�j��8ꏕì^&� X���>��r���Q��rÃL]/S~�rY��	(O��݇���?�:2F�a�e
���ǹ�3t����/0���Qs<�*Gq�y�1Ô�Ut���x����q���*�*V�؏�@�4�D���I�A�<���"`"���Z���G�;���a�c4"�
vs���X�N��U��?��+�ۜT7�`���+@�A��-��J�J`�fn��&]6�E����Ԁi��a-zZw~6�}rWq���fk��m��9/�|T�=�˄=���n>�V� 2���C&�vv�>��K��3��^;K@�ZS�"�C�:�˫U��;�����7N�_Tbff�u)G��v�6Q���3|H��ʗ�gF�8(�!9����[r�{D*1 �ue���2��̜������i
���m�`D���8?���@�N0e�H*X�t�V!E7�{�}�,�H�X�	��ұ���_��Q[�b�Ǒ��U3�6��	��S*���~��^�I�8���0Xp
����Ѓ��dW(޿��Y�+=L~Y�E��QqRh����$Ήr?O�V�����սO�;��#03�E����)Y��[���Ce[���A�2T/����Bz�/�J%GC�W��r��le� ;���W�R�]�_�����x��!���l?�0��b�W�|m����Yw�}T#��4��.{,�u2QɨnS�Xl�0b*3ُ��CZ��2gള�V�T�s�z$�;b-�D�tK�}�����{�{c���f4���JN�]f㗙2a|�E��>�/����3j��q�ⰹ�h������2��zvyybS%#���:zl8Ul8���	�\�ܓ�g�N&�B8���Wl�U��%�Yt��6�܅�6���.d��^r2�W��;���R�J��IC�E���g�b�؏�/9Q�e~%�����o��	w��+[\���%:fu�D;#�.��	�$���{nM���U=�^��^�6f�����]��%? ��pb��>m�5�}��+qa���7Kz@_|�����ڻ u��x����*��tڴ�;��CA�2Ĕ���:���~������z��E�@�a�P���g�f�L��ai&>����n��x�������H|J� �Ш��9�k�?���B$�A�v�ܕ���ע2*F���;��SD凁]��$�٢ r��l�Q�sɥ��e����4"��6+�����i3�ɓ��J^n;�D,���ko���0�֧��
��W"���T��'�H���Yf���ϓ��Mwγ:�]jA8�^�$a۩���A�>DZ��u�]l7q�8˼��3�:P'B"ȷ�4�A!�,�SŊ?�#�_����c#��ߌ�M�m�f��F$��:!C�B��LҊc�ׯ��!W�b#��m cq�U"�,�̝a��f�8���?���t�]� ��rMov9[���q#&���t�������s�I��p´�p����<��uʜ�|�x[=;�*ߞ�(k&1�F��pwèr���0m7�5ywdmʰ�����Sl�=�]��8oh���U�IE:�>Y�^���<j%�����Un_|��S�~��A�@*S��`6޷S�hgHF���3s5p%�9�!��<�ܨ^%՘3���fi��PN�����F�1��7��ϗ>N���]�bNn .-��?�CXݺ��֚)�v�i=Qs�� W�����2�\;��5�#����H6��'�:����ְ˧�	Sl�\Ea�S��DY2i�UV�C>�2ִ�{DQO�X@���؋�S��� ˏ�b�����'�L"��ņ�pR�(�C뤊�)���9E�e�dVOi������"a�����1��\�i�xU`�n���t8���qq8d�@�2b��H�k��F�erw�{71�Z�۞�R ?y���5�2����2����I�?�ε�r�=�U[aΝ���i����[�ϣ!̠J��R��Q���;��f����-	l<�=>G�E&1n���I���R�:�l���~[�q�!5���c�K�6�m�d�׾���8�)Gܧ�i�)�T%\�f!�b���<g����Nߪ�C�8 �����aX-tVl�],]���Z����k��Z�޹��aW��fY�g0ϗMր� �*� Z ;n0�j"7�V�p��v�e��-���9����9��ȯ���Dp�ȋ���H���%��5,I΂K`��_Y�]���\]�T�}M��,�J�Z��t�V!�|9fC�L�����8J�
?~5\�GA�o]��u�Fd����G=��I���R�������	�E�g	��"�����@j�3r� ��N
�6�U���8
βT~v�������F1n6�dP�2Ro�������w�Iky�s��\��j������t%��}xm�x���M���$���7.�W������1�w�z�~<Z=�l�"�ao�*,��6E�s-���u�\�xn��gZ�zy�[�D4Q���hF㷤�OrE3�>���TS��	���
&Xs/�j
*��O1!UV����w�H�1d��r_(Ic�.�V<,M�d�>0�B p��;@'	>
��]��Z3�{_!I�\5�Up1��J�3!L`P���ǚ����K��J��\�ͬ,�|�f�,3���)��`�)M�(2!ͺ����/&WU��*)��L��ª�,�K��/���-�U'�@�>�V��6�m��z�`����W���'��'��so�"n����@�R�<x��.q��]I([��ue	�;V��ʻ�q]�OE��*�.|��R��p
��6��v����/��X�zF�"&�n��/�N:����@d!�`�	���a;S�OW595�]Wk�4+��˓���y�Jdzw��������J"O�>��@h2H��Y:��مWG�DL�i���������0�8���6[^!�]68񊧮��&�&��pIs��k.9�� |,�?� ��_�G|�Mwl�a�gΥf��G-~�P�	���{��]�;�z*�B�09ظ�݀s��n`5��ytF��A�����hោL�^�'�{b��w��i�0�s�������fV��=PeG0\ۡ�F{Y 5�I��sn��~�z�8��A�`�=G'G�\A�q�h�e[��߯��G �������Z�>\���!lc�o�5��e��Z5${n�__�A�\�n��J�Utd���|��\�i�/�3���8^ч�˔�![�1��m`RE�'��oV?<��]R�84}�eUM�a����X/�;f9�c�$��>�e��R�@�?�R�I
AerQ�R2�H��0A����d�ߋ=P�!�g�I�k�Fh���6_��	ݾ;RVAf*�e�)��̔֛��\�Z�rM�����;~i�X���Z��=���D �j�-\�8ԑ{��&�����%�Og�V�>������s�|����~8h���9�ASja��=/-��\���o���9��q�{�]A��M�X�����������At2UT�e�u����v+���4��ʎY~����n,�ǨO�(����Ȋ����.����v�������o˟�^�&\p��-j��PY�|�k[[3,'����b=��I�͛�>5���@�����d+��INeQ��=q
�j��%KB�2���]��8�{oqJ}.Py�u�X@K	�O�mW��_,Ѷв�!���a{�Q`~S�}]j�4,u� ��R�.�fPg��i��M��g�p����6�ɌK��9b���1��3�dS�tB���L���t˗�� �Ǧ320%_z*�8� �J�V���q�����%��"u={�<F�R��ͯ���Q�Ǣ����#�!�� wS��^��п�|��(T2�׊3�V����@[�B5� p`�Ke˕�ԚF���6X��xM,U�����:Oo��b��AN��ʷ����̩Ps�JgA骚��S�P��]^���G[��1A;n<�q׽� G���b.��*_�~� @-�z0y�9��D"�^V�N��2,���G�w=I�|�>�`9����<>=u��
�O��"�)��)Gmپ1<GhK�H@��Z�D�:؝���>Y��B�h4<M�&]����XF�܏�gU��3{�y����nk��2��`��-�'�@��:̙�`QA�EG��ǉ=�,ʹB���]��U�L������P���fQ���?��gk���,��e<�a� 5��EWff(�30�g�(`c�>K�c� ~n�/x���Ŧ!�_�Gt4+W��*�g��ťn�f ˮ6�T���O"��勥���%ٳ,/����F�|��ϲ;z�E#���V������6E嗨�ٝ���~��pM�'���^%ЮT� =�^Uz&�ބ�)G*�~k>b~I�*�a]�Ä���* g�B(���k��ư\_63��^8�P���E�T}����M�NiS���P�źu`c%v+�Q�!A��o2�Mv�r�xћ_�?Rj�_v��6m�J[�7���a��A-���:=?��>���M��6��x��mf+0no�����-��[Y ��A[��f�0t�&N�gQ�©�RK�(��J��5h �n �wC���LeXe?/�v��i�u�%~��9Vc�
�t5�*����g��E�>Z�}ƽv���5� 3b����@���ٗ�C�r���i��_y�ϧ&k6�,�Ɂ��mS��ږ߃g*JS�׻�iU���LQ����f���	~���8��m��e�Q	�>���j�#�����B+t���a�������ߟ��o�{)���'��.׋d�U`��U&a!�E�Q����?j"e7)i�c��:lo���d����]����I�ԳS�;��~3�t�WhH����=l�ph�]k���jD�a��g�W"�T����#�7}z���ǹ�*EE͇��zo��*5;��j�m�Q}o��fo�ū)����V��f0,blB��C>���#SZھ<g�d	�1�Y�~�5}�1b��3AA��f�
����W
4$xq	Ǐ.a�cx�t��A �ֈy!�s��&���r���9�i���	h�v5��|�в�@9Il�I��ض�k}�)ǽ�����U★!���P�\l�fu��a�h�%��E��wʓ�rF�8<���j�%���,E��A5I���.����yx��A�잿� �=Կ妗�(�oLq�vg��6��������B�C����I��\�?	�ã����a~(�oz�:�r}+{�a�hõ�D��颕��_�����U_�����W��8���*t��ǑO����^�~�qA(��U-7d�� t|����o��i�*�&��t�M	%�HʶD.}'(\�p�C@����X
�ΒC�jz���d �jA5|^W8ь�S�B��U[��S2�E��n�U'��dv3�ڂC�o"���=G@�d��أ$~�=.2��U�P���� ����J�>��k��7�x��i�6l[� m#��=2l���\D(p.��s<w��vD6TY�����̗I`@��A���a����.d�xb�6�c���8e��F����9�QkI�T���TE9�3ٙZfl%A��kؚq9���`ѕ�H�{Y�а��i'a��s���p�1~�6�9#Iz2��������:�u{��E�?�
E_t�Ҟ�t7�|���I��m/"�j���`/۝����.�̮�����<Go���Q��c���,�}�L�>'��߫�5� L��q:�_�Igvo�� ���&�8��N���twd~�:í*.�O��ֹO���������1mGG����!��=~,��&8[��s����D@���O��Yd�v�<$�&�2��
��i^�R�.9�-��Ľ+8�Y��fe.羁�3A�6�m7X9qm�x�t�qU��K��1��_'��cL2H�%A�f�?�L�<lؠ���͂��pC�P��u��V��%�v��s���R̭��FR@x�/����j�����6���iplnl��?G��+6���G�/������m((͟Wj�׌�#�&΁��V~�MA�����#?B�ڠ4�#�\�9��AF���i>�d��yC>��	���Mb��S�3 ү��_��v1�R_<cEǯ�5�(����g�v0l_��B �^<�%t5�J��bk�x���!��M�	!�N#��pR.�������E����lZN�ߖo��(��cE+ܻ��j��qPJ:)i���q��0����� 0��s����`Vmx�X��.���Y����@zq�d�\��ܡ=��e;���07��~sb�T6N�%n�AnD\��V���9�W�39Zؕ&E�T1�n�*;�K=����JQ�U����"��[Xlwa�A���Н	۩	������������'��E�h}��KО�O:&�fs�o�'e�џ�29(}�OBf��2є@�y��S�Z���vP���ֵh�������74���ɭ�W�e���q/�.ۻ%��w��o����E|E?,#i�H.H��"W�*�k1y�*9�)?�	�cM���tU�Tń�9i��c~�?���$M]7r{�������'Y���T�WvE�5񓍿���-��vch���zu�&�3�|^	f�I�1�� ����N�VZZ��Ds�Ns��Q��3��H50��g������F�Z©����բ1���o�����jEb�5��h���D�}�F�q���s��5~B�y��xp�����}��ѕ>�H�����_�;ׁ	B/�!U��2Č�F�,�C �z��M�h�P>���iDb	�.نH��+cbĐ�ٲ�J[����IA �kZ|@x�x<�lҶ9�K����x��yLg�P�&(럾CA�XƑ��ҧ��'+ي���y���f�����ͣ/ix[{7�`aFM���#�'+bęf'�1z‎c���^߃�ͪ�����Z���i�%f�^_���&��A�Z�U�e���]g��8����x
m֧�k�x����������fU&�PwN~��I�����K������QI{|�S4 �<7�]�S��ƌ��(7:���ǿ������_J��#j��f}(9-9�cV���|�!)OLlnQ���_P�Ii�������|��79��Tr-�$k�V����^4I�s{���Dgm��mS6�m��W�W�<�����j�����ˑ|9	`����̑W��4/��m�|J���	��%Q8�I�#����'���f��y�W��1�y&Lo`��XV��5�g�`@��YN�\��e���p����Z>�%`���1�ȹv;���������toڕ��Y@����g�֦Ӆ19�hƖ����@���,�u��ODE�H�sR�}�:�2�m����{��PkɄw�ETS�IIP�YZ#iT�T�v��F�����H� �N|n�v�e׾@����W���׮�9��W��������^T:�`D&j�&r}<��������h�VV�"�-�W��r�@�V��
+������k!Ũ�&3��k�Hˀ>��~�M�gS��[�g��lu]}����A��;��	!KcW�R)<��ɮ�*"Pb��.־��Sss:�Q|W,�9Y���9AGCo:��2ƃ�׊I�{�"ymGr&�
�.�l��]���t����U�) ��=�cY�"mx]��=���--Ys�EJz���J�q�dɽ�=M��(��1N�Fsix�����_1&*�3:9(���v�t$/_�m������D��N�@d}���\$6��5�]D�uwʽ����M3�v?;�� �nJ1ѵ�x�Q�@˒\��������p+w���"p*����h#���cN��0��^[u��r�����ع��?���C N�@�Q���C;4%������':��$$C����lU�+I�A�+8���ٸr�}��� L�P��$d�Rk%s�Oy2d�ʿbz�nT�mO�W��H��jRL⊹�����"i�O�:�8�̥+�=�uXజą{s���B�k^�퓱o:+�8��Bh>`�,�Z��Y������/�r����N�b����̠�!O�2Xӏw�c>�)�y���͸z��l�i�e"����[�Hߟ�
� �!,�
r`�o�?����EYzܗK,�Y(01jZ���x�j�TL�x�t���Y�K;62��3�9E�Ą%�VKSl�bk@U�fA�U�>`x�Z˳�Ow��I'�?Y�"�<si��E��>Q��y<K��F+�*�X�lnp��߆���jz1<.6,#�3�p���M2�������^����ʯ3n9_ǜ&���fP:	Cօ�;�0<kj�pt�Ċ�'dlJ�/�x�&>u</��ab7e�h��5܉���k|z�a.ߙf�"������!�ts������C��y��~��o����M�/n|b�(�oM��"�a����ɗșjЂ�]������{){s��6xN6�D.ݘ}"�ѩA=�(.���#	~%�(fҲ�&��nEƟG� ��~l���:<���e���g��� �CXodvN_x;�)�|^C���/C @7�ׅ��A<�lj�#H���8	a��|(����ެ�����6AQ��$��u�ɇ�$����.z���� J�ҫ 9�MENZ�vH�O5v`��n@4w��&���(je�OL�z��T7��1���q��Fr%�Z���<V��	�~���Gh�.c��
���q-���V��4�N��?����쉩��1�'�S8B�bM!�&����?v�y��'v�r��9��eU�v�ð�����a~�o4��}��d3&ߤ�=�Ϳ���0_:e{|�`LE.�T���Z��E��U�y��o{��_��s�z������[;X��r�x���36�μ��]{��X�0����o��rA�?=�����D�yorRe's�E
���+����?B�U{�#Hv�2���qP��Va�&p<�@Ke�
�������NE)v��
����)����0�1"��V|9�r8�u�Y��`�7իYJ*hTeB��bg�CT���#q�{��	'jє��#s����(:����Yzx�C��<6��/�ِ?7�Vo^U�W�!���P�TNK��[yQ��w�'�[P�H��.�"�!�m45��16�/��OyJ�+��;q~��/�_�pk�)6�	�فR��)R;Qv����ձ� �<7/6�R� $_<�Q�$zV��U�y��_y�BޖB���!�v�+Ư)��ߊ�#E��Οw���3��僀��R� &>��'b�x�7m��~�n?%�t�5�ƃ����mwgM���M���h��*���q���Qf���+��k��t�`����t5��?s4�޹\戜�M8Ev>�nG]�)>!/�>���mY\�_�p��\�����si졪tE0H�i�"�_n�`�U�.�2�7�?�tb�Es@����[}��ÇW R=���_�3z�u��wbDs@*{���� g�N	����ԟ�q|���pt�h	�ĸ

��ڟ��0�P�I�y�o�7���)j�^	���+��ݹ��;x!�x������x�S@`)��*RFE��k�x�����8�Y�?�<�A��da��,��D[K����Bu[~	��n�4=zN]�mv� � B̉:t��J��OһU�Fc�R���?�y��! 3��4v�R��
{��g�k]�2�ꭔ���~=��1O��9*���¶�]([:2�b�`���[��#�a�҆y���V��iI8�E%_^9�y?W�sv���gѳ�B���sr��HK΍@Z���g*�o"�ɁM�����	���?�|��'ݟ�"��fA������!U�0o�k�t�$&���D^ה�����Ӣ���!l0����M�M	���h�]ԟS�Op�,yWlp����)%+������3&�8�C�J>�N	N9���DY�uCpV��I���ϫ�픀����S>|x��)��\{89�􌸲��
C�k�ؾ�㰭�Z �O�1F0�c���P�Yo��{�G��^��W��1l�L&���1����`-��V�w�SMm���z4NL���o%���4���ɷ��{�1k�y�c/
�V[�:�A=�	�M���|т�NlX^`��K=0-zn�Vay�z~�j_x��Z�h���#��"\B/t�4"j����͡�A�c��{��Ρ�F/R�د|�^ۧu�7�3�Ny5�>�N��2�"L %��I��:]����5Up0J|e�X�(�5eƞ�U7�֮>���I��N��qF�l<ߝӘ뾤��� �A�$wV�V���������(bMT�N����CpS�z�f���]v]�*�ə�vdݛ�R$w�N���*��k-)p������Ù0E$c���}}��`'q_�ue�Zۋ+��V�څ!�8��$.����e�q�+��9�0�z�BW�D"��ͦ�ֺO>�|ؘ
���z�`�u(|���\����/�~���c��E4?��.��Å[�D��cSe_-�]�)�)_�1y\T�β���8<�́qk���Vp7�N`Q���'֙�A������>���7��F��2mn�d1i/e�&..��C,�*�<pj�x���lQ�lA��^��߯PB%#VW6n�nB����
%��]�5�|�{�?�ǻŕ�Q-��Z�����;]�25����9��ꕯNG��1�9�ͅ�\o�W5�0�8���arcu�����v��
ɋ�ۧ�+�dC0��n�m+2#�3�H��uH{�qǴ�g�it.l;ELA�U�=��GG'�`�N4H��c��/��8-�S�p�,�wRx:�w_�x��	4_t�D���7�&5S�x���(��*uL��!��3S=�P��D� �!PAa��vy��[�����N�bU�SrX(��ލ���c�8��M`n0��"X�W��P6�ri��Fn��.�T@�C�/�v
�5"�~$�V����c���s�F�)�����"���p�Ng�a��wCOeZ���/B����0y�DJ��� �ֽ�� ��Tr�S����7J	l���w�<x�F�qMI������3��	?Z��C=@��]�h7A�E
0�6��~�`��_��[�������a��O�|�w_��
�u<Pk"U�"Y��,�Y!��Y��bk2������6�Nq�¯�N�N�C��2��'�N�:��-�am&aa�bߡ�i�?�D�)��Lm>J	Ҹ�����=�%౔!j{6�m5T�R�ኼ���Q�~��j3=��\���4|2Y�\0��Q/bT��D��$�;�b��f�[b�&j�`�ʵO՚�15q�����}.<i�4h���_9�H�k�{�b-rO�RfB�ڌJxR���VM��;��Ba6d;�N�nN����6�{�~�;�2� �G}å��n����6�%��r��P��`�8���F�D�=(���~��;�4�H'yjm��EQ[ ��=e�����y��\�Ű]t��$��P��&�Z���̧F'�e�y`=�^6��S�<�gM��Y`��+�Q���!�uf��x�����*�~�`G�l�:�
���$�O�8��?�Ӷ���Z4$x����z��裈�o.:h�UM��2w�!%�6��mT��{����V<Հ!��ڃ-y���G��ժ��ȝQ�1[lKD��h����Y��k���Ƕ�>�v�ȍ���1V&XL���f�&��@��.�K��[��ul�T�	טzGj�&��6̬�~�=/�T0n�T���617j
���Uc�2=��o<��J��	��	A��d�=_lǬ;�L�������M�%�˖���~��A�γ ��$|L���|�ᾈ���D��,�nȠ2�lk��}5��\ǈ��#ph�����$��!#� w��f@�v���#�l4)�ZƏԣZ�h,�Ȫ�e&�׊&9�����5�_/�X��$���P�Y���
wY�._B�|��h�&_M]� p���r�~�f�Vo�h�I��6h�mQ��"ɀ�
�K�$Ѯҗqt�}���̲����x��6q���8e���`��?� �ۉD�!���DrJ�W�6>����$N��&_,��,�!��Asp�O�0��߿�7"��$���%�Nk�o�&!8>޹%~�~Ş�>4ZB��H{�:�ݾ$��=Zi�RS����?��5���e�q�q���L��r�3�Ohy��1��1{�C}�2V�92ުHb+�!�o�U�p�4�5��L���=������A'�p��)�n�k�2fwuR�/��n  -1p�� �3e[aF��վ�ڬO�g��G=�:x�^��ʩ��
�x�_�'rl5�O���?}X����x��elI��I�5��{k�hR{D�ף#z2����N7�ւ�&ov���S�F�*��]i$���U�J���2@7���'��ȣ'T�4f�)9}��~��6���3"���O�5ۡ���G���	�'��HQ}�ke��>N���;a�n�ۈ��(�?$�):�?_�U*�5[7#<0P���s���_���n*K�,�A��&����q��2���2Cߎ�ĉ?e9ګFRe��F)�Bu��4=j�{{D�ǒ�6�U��hd3���˖!�����^&1A�p�SQr��D㘬O~K-e��
d�:��l".�v�|����^R��i��x�DL�JE�`r�ǂ�AB����uV�iXz��ߧx���ȩ&U~'E'D�e�:���{�Q�}��O}�Dp()|�{���):DU 1�;%9�3c7r��Њ�F1`��bd�������������!��+���Q�ޞ����d	Wp���j��������<��!�+��M��>��C'$�7P(��1�$����!0�z�"37�<|��~?�)z�W�M�D�h�LiNM#
D�k
.yrsaĉ_`?������LK��=J��du�g���:w�S}bc��➵O_�6����a�ǋV#�l����<@��'t%N�n{O"�-��ŀ#�WGG±�מ�$8�����J�ڣ�
Xb\�����S���$�{�e��[�w{8I��"��:�����MdOgs���7p�wPd>�م��^�]�˴�����Aڏ�(`�;����[�4��D'�P|q���$��Ī���o79��t���5��L0[��|yPߺ�ͷ��2�,�?i��Ux��̦|nh�S�N�Y�v��������!g
��O�����g��3HNj�/I8Ʃxw&d �.1������vZ��HT������UѸGv�4�-�A4��1���c�%b.�E�M ��sP�v��H��5���"ql��ƨ䈨aa7�K��!1�12� �$�v�����"º�ި� oIw}��%��
ۍN��|(�90J�������z1z��L�^��Gc���]��j�T�q6y��@��D���9d��5�����'��a�M稌����ݹC�q�k�QĻBj�#!�~y�6��W�¿��i��K}�O���y�KgtW�!K7Iczq�,��a*ګ�N�~Ш��	��km3x�o�����'�B��j-�� �E�}S͟�ă���dyVP ����I⣡�k�����_@��-���e�ٝ�L��4c��V�1 (SiF|�b��Y�qՈ��o�\�--����%�z��xt:����81��񪶍�d�BB.�oj��=���Q�>�5�RSt�d�Y��^u����J9�w>=��j���(�g��?H�b?�S�9��KV{���*m�ӫ�����Q��$I���z�Q	(�S��aV����'�C"�sa1#s-����Y_��ԁ2QnF�9;<p..��|b�+7�=�M��6�Kh�|�_��{�䛁��'U�դ�Y�m�A�S��yi�+�_V埉��:Q���pJ���Ѡ�5�%<�v�Aw�`�;��+a��17[1�+k�� ��gs칢P aMr�� п2K�#�h]�7��M� U�{�M��u��J-K`�F@������r\ �!:�d9n�N�c>ؠWx�0�P��#;	V~�e��M���m�Hw�v�Nx?���8��� ܟ�����{ }�r?v�6�3g~�Y�-(����_e�����&�q���?��oRV�g
I}��drc�Wr�C��緂��H����+������i�x�#[���i^g;(�����$�G��&k>�0����Zs��wlc�{��ܢ����d�
z��|ƚ�o�~B��i�}|A:�7 ����A�EI�M<f;���ki{�K:v��p++Y�/$lO ��wl%�0QLķ�HEF:��b�־g�\�r�_Rv�"Ȕ4�|ϝ}�Ov�nJ���*��*B��=w%/�J"r�>|���z@F�|wbuVa�h����H�T��d��~_�{iФ�T������Ys���f������0��(��i!!�D*X-*��NdQ�/v��X��j�(o<\��:�Ĉ��_����T�mNd �k�l?Xt�oKd4��.sl[ǐ���D5�a�p��8�h����u�T�����p��Q�7��L�`�x ��;_#��,V��'��O-�"p��~u��t���sDE�R��<��Q�]�gA5X�TZ����x��6B	f�7zֈb@[k%�R�Bq�F������16P۪�7�s>�nׂ���ږ��l�|�i:8sjl���N��_�6�	�p���\�Z`��(@��Ts�e���^�ƪ�ǰо��g����r=�1�s+ �z-��P�$6.�C	�٪�� ��mQ�"�JOki��,85�W�)�VoL�(3��p�;�����qGoS%^"ivk��1O�@^��J�a���Y��ں���sQq�c��jj�%~��Y0$�O���!�O�KAMܣ5��thb�KMRńx��n¼�)��%~!�_i^eTL���Yo��H����ڠLO����Q�2��- �qO��}���J�<��6ٚ9�x�C��s]��l��Xt�ǐ�k��-ⱝ�Mv�H�+�ܳVd�'>|V��%��bhh�@�&vE��`ɬ�]M���F�%>S)E�[[Y��r���b�·��ኛ�K���T(����m�,3�(ڸ���-�$4tx	¾�D ��~��ǜyC�k���N��#%s��*AGF���ږ�C������ې��$k�� +U����g|�J"�?e�d$
�ND�������"b��������A"�L {�^��^��U��c�����t�P�W��H�@�������霆S�M���P�V��2aS�)�VXw6P�G$�L����MXǢr|�P��͐�cy�Ċ��H�J�Woz���A��|�����	Ki�m�Op��\O6~W^'��@��#��+`l�6�VRZF�&�zG8Zm]�Vo�o�F�TR��I}1��/q���ʭ��?Bc�]�z>�ߝ��}8���a6n`�����e�+ ���z�Aṗ5�R�01���0��(�v�:N�3��;G�J���do<{I ���gb(�G�|�3`.Ro\���j��C	gǥR�-+�	�g5���@U]�w�؍=H_�Oṱ9�]��iݞ�!m�t �T��T�e����4c����ȿ6m��J��~�,/�LKi��)أ���pT�f��:3@�H�"G�m\��?5����uY5Q�x=�o�e�k@�](��<d���f�F�ͦ� �'��w�(���~�o֧�3����&��8j�΢&.O��8��B�_�e`����ԥ�M�]�۱�qߠ���Yڬe�ݞ{��1�Xԩ�	%%���
#��������i����4*D�n{̭�)����Ih�����1�z��y$V���#�
_��#	L=��VwF#S��R�- >ɗ)�Ƒ���  ��{7�K�l�vT���&�EXU".�Q�:�lJ��	O!U^��R���wJ'�����X�	�3\�;���i[;���;c���Ҝ����@���e�N� N�e)�n�wwy�%>R[�6+��O��eh`R(uD���*ج��������+���)p$w��J�Y�7�)��=E�Ń�d0T�������'r�,NA�Gm���R�s�Αp�a�(]_�E���EKD�tJ���7g��- ��	7ȇBa��q�����ʇ�K�ZE�(��N�xma>��7�|�C�c�M��iRgx3�W�5��R����R`�N�;H`2�c�(.�*�L�*ښ���eq���i�`�T�Z�����%m3f��� �ļ<ՙ���#������6����l���%��s��������E��LTp�=�y��Y5µVU�\���o����~��@�Z�OT�O¨�|z�x&��V��Ϝm�HJ�{x:k�pt�<�W�m��J;k!*�� �,��v@=�;o�g�.��A�Y�l �Eյ�M��C�[�`]{q�1�J��F�!�M�B���Y�����w�蕅!�qdu�f�]~ގw��2Λ��mi;��̭��#��-������a�������;))Ӓ���v&�� !��g:���~*5l�+?�Z�#Y`H��	����rIl���azA������t�I;7}8)��x���I�ȃ�x�`�>���5雩F�3#�p�&_mX�<�*L.��`2��}��om��HVv��Q�:g <����'��pZ�dM�t�'�9��������r���8�l��L�Z��X�󧥪*��I�-���%&��_�K�l�_�*�ϓ�<O�&G�����x�I�&��UԼ����Y=mn���㬊�� �/?������h��:�S��O��[�kq��xC>E����/aݣ�&s��.qy^�& �|���d�7���e�}�rVÿF���u�{���l��؀��Icۓ��#&��U7 ����QBAO瀡�!�
1�S��<��q�!�GCt�������$I)L�ɣ˝��\���-^��P���ֽ�)V��|�����"z��]��{��Z����hy~m�/�np�!1:v��y�2����H���WZ?+��&��=�5@];+u^��*��,CU������I�sZ:�.���52Հ��d�6?�:��8gץ�MOe��G?bwfܷ_h�g3���e�FL�3m��S$*D�9/�b����a�@J�wy-EyM�܄�(�Ѳ�w:"�Uo �i�ky�1��mw.�e���sa7�F"�*��8�A�$�������I�ү��n�pby ���!;1h���K��2��pwGL����I�^��xfV��#-y��'��~�;��t&i(�q?����#���N���Z4���I#!�]Pt>���� �����'�$�b�y��Gq)�r���-�c�Q%�|sz�� _ ��P]n���~ �v�T(�ݔշզB�������ۥ>&
vBȿsJd�7]�9��ң��%1�=��;�In]��ˁ��͋��"��M��J��#kjz��䥡o}u��&��Π-�,@ML�-zJ�qL[�xEWG_�uE�|#S=�����4�g��c��x�,��jWʇ1���V_8m��0�۝9�	���*R�T#;���v��Q�
E˅M�vdH_U�|�|��jҁmX�W}.��
K�+��wIn���	H]�q?�qR%�%[c�2Fv��z�x�5�s:�`Ȓ���B���P[,���d$�-��#�B2p��ǜ�b�a�x�E2�3`���0�Ofq����x����*@��`�U�*R�����o�g�ya�U���o���Q0wN�2V���>�C��틴j6��=�P��VQ��"Qk��y�qG�Q ���%M&[��e�Mu9�����3n�>��*1<�}�R�(��Yy~��.��p� �m�]6�����u���C-�Z���C�l�p��'2�%c5' ���c��b9��K%����g]�CZN�M)r�� �I;�)*R�������g[���-u�օ`�=����G�ZL`F�fa�x��y����ڋFö��9�'�Eg���aL>=�@q�"����� O�f�Χ<�]�}�#��f��م�5)
�{L=z]��n#�tDN��Q���0�Ӳ9D�:�.Lq�il%�D�6��;��?N��(��j���({�AP������k�.�8�sE�w<�LcbӀ�y��M����b�nȸ�H���ǥ�>�;�b2R�*I>{<T�����V��^q�y�}$B�@	^��oԅ���_�.�� 3l���<dt�(��Z�Ac^k�#\�B�����!��7�S��M�Ò��Ęz;Ƅopߌl��(I�\9�0��GR�k�I�e4�p�۟�&��,-agX��b���|q��E��n�ŧ,~=#n&m�"e�M�ż�Q"�H<�j�!�`]��?������-��m��P?���Z�����3�H�@�J	7��@����� ��Ȩ��BP��S�,!���<�i��A��劰�@*��Ŋ��кoz6k:��99�߂H�0��<'��I�#�Eei�L@��;��*�����D�2��$����K��4s���j��8
���ZX�.ւ`OGIZ�G���\�,�k���D!?f��e��<��viT��g�,��P�3��+T3qv��e��K��UC\��2 �q�Aptkgoj�{i���VL^@�QE�"H�8ҵy��Ҝݷ�����l3�-���*X@h�#!�n���ھx4��N�=�7��vD�OO���ϩ����y�)�G���u&<�ܳ^��6؞�ky�*}@z����=,â�D�"/� �x��0\l=4C��$��DSA�����Ő7���v�����[1�*�@����t\;s�0({)C�C4̧��4�c8�%�S���##_��*�Ұ��\v����1P�ǹ�}���.N�g?g*z��m�E�8�kԉ�a,eʙ�!�ڼ��<|,�.~6��rȤ��7j!�H��?-����"���ͼ.�jGW�o����M4��m^M"S�B���o������*�+O ���|Ġ�l�>���$R���wp "�%R5�Y޹1��7��=�+ӳ�(�!��Ń�^?��,),���.���V�c;
Ѥy����� "�=?��  �9?����\,΅t�MJ�{e��Q��]5����e^�*5���X	�is����m�N���k�qN	X��{�ETb��c�Kթx9�Y��'�������&��u�Mn����4S1쿕�I����s�?W���������̮��_��D�USm�2Ge���R:,�P���1��{Qf�S��=*X�������N:���Va0Ѥ��:����I��������\K�w�o��wV���� �`G�PC։�Kn��d���U[A$�%ׄv1���0�}ۃb݌���K��
�'zU��I�(���i�P�>�t3%����?�R5kO�f_:�RI`���̇�X���E-�U�bzw*�-2_^^���t)Q!�=�CTS���`&�%��2Mǿ"���5�\J�tc��rCl3���0�c̳�d ���>�|y�#	��M�lR]�M^1؈��Z[)pT�����$�/92¡�GƷ;�#�#ҙ�
���[�~E[�{~p��m+��-N�\
A�����#NV5�;��jZM*�}:��/[7��C����e/�.��/��\����do�E���e� �qR�����e�Xq��l��,�mw2�޷�4�A�t�R��b���T�v��!*�d#m���S�eW�zf.z��Ǫ~��F@�ڀ���!w@�K3��E_�M%��ô�1�~�����j�5*����B+n�_uA�j��>��k�2�aCv�
��d��b��R3wIC���g{�I������zXG�{f���E@2)$��c�?�.�,����H)���Կ?Μ�X�=�����_�:�,�v �t:ԈQ���f*���2pIͅ�����|���F��� 0��1~�]��]|��������c�]ڄ�9Z��?���M����}V�a+�^��Q�:I&y���=I��9��c�|����o�_?�r\Rx~^��2��)�$���ꊻkHݫ?�$�l�~��A�������fN{Ͳ>Dʄ+~;
!L�!��p���[��y5<�D�q:oʭFxf0J�W!�o��kZsv���` ��]_�������
�S45��dZ�i�' H�uu+��[U;9*��8���`V�&��V��(�d��+՞���<�RX1�($Ŵ���SI�b�\����/WZpg~1�_���G)j�W#���Hv� �d�g�p��c�B�+؉���ٻ:�>��d���1@��w�A?���U[�p����-����ڃj�)\S?9F�B�1�(�9�m����4[�|+CIF��;G�p�{n�P��Kt�F�����i�%�W�^��cX��{~3_�
�;TSH���0q��4���2�T�ۄ]Z?0�c:��a�@�By��[�羦�`#�ӡIտՐ�3����2���㶤�+�5`%��8$&"�����5#3^��,�h�q���C=���1_꽲,v�i��:Qg���L�@r�{��zf :¥ ���R�����,n�+�](҉�&K\stEC�G�S T�q���ŧ��i�o�'���A�����^�Hq�$��.�$psJ��rGu�5�dܶ�#���E7n�s���;�6>��.z[����jʲ�|D0�U�h<<ii���s35]V��+���i�P d]؃Ҏ���2���+Ã�eZ�\^���[���T�Oj���n�O=��9��jc���1���:-|��0������U_4�L��:��"��3�ܭ���=?��"�$:���T-��v�q�Gd՛��o�hÍ�]n=��o}��5�p�L��ɠ�O4;6	��c��s�Y�#=�op���Iu�'��N��/(h��0}��_�U5��o`ˑ�cJ��'"�C[��'��l3���b�;n��jI3���;���`�JY�[R�a��<���hyPχ ��Uma��'d�H�2m�o��z�Ȼ�!֬E��Ȭ����5yw;&Q����J�5�&'�������,�J�N-P$��$�*g����R��d�y:��p�0� �S�^�P�ǬL����0ʮH�'-�>)�~1�=}�� G)��V��T'����x�o:~��o���E�k�ѕ���9����)��9�P���(���y���[�2�V��gcT!̧���Z�%�!�#s-���E�b򟄌��#������o�0Ψ��b�/"��!BpJw��b��m�EZ��A*��@.��C�2(�^]8#j?ȦQg�{냣�w�b���>y�P� Y������짣e�\�.�ƆtГ�هcr�EZ�����Ӝ�J�t��@1��"��.�����O�nS�<����q7��(�8J�@�弲�F���3�:4����?t_ VH�P�D������ā���$678?�j�tL�V�-:��0t�\),��_�\[�#eb���1��&xXG�S�7�+�<u�1�D�';���3m�����J ��iR���ޖ��{V�K;����	�����B�)�s}r��;��-�vT-D�&x4��BŊW��1�x:�LdB�B�P�2��4˼|QG[�{�bПZ��@[ޅ������,��X�!�!7��ũ9��@kY� |G�Ӟ<�=n
���/��a�<�Ko͢��*I�������
Sqp��3�@��n���{[�����[��H���ٖ�9L���|z�WɃ�3l
X2��Mg��;B�O��p�.�Ɠ��p��6u�����b����b{�8aL>�����U��W���`��b�nݝ�YS�&h�l'~R:��!֮�k�)��{/f0oN��G��m����>p��+l�-Q�$?l�H����f�샑��ȩ���;�s�<WA�}H[�KO �k%{N؜��ᷪ������������H�ڤmś-	F�9
<X]���?cV��",2ګy�K0_?�d�e{���E�Vy� �R�1ĝ:q�3����0������H�Ky����Z����m�?~�M!��`ȋ�N];��c2�a{CTq�p2�B`�Tc$�/9>M����h?RY��{��Ǟ[ݍ"���CT��%�f�p�/}��mD�_�_�_�1����z�H�x����o��)�4mv�.>�酗��@��߂n%�R�ٞ�؏���+�&��������S�ڙ���Upgv�F�p���e��S�7����?p7�
�v�d��iD̏z��l��4	r�3*����V�c�S#��*h,��c�5-����     FNT��>? ź��guԱ�g�    YZ