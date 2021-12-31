#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="469620061"
MD5="27986b61acff0a5b9cb2d77b8d0480c1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25800"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 00:47:44 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���d�] �}��1Dd]����P�t�D�#��΄Dnx��\�s���)=^���$~J'�p��u3E�(�ӣ�4��a>J�) �����b�,P���c%�C[�4���_�� ]��V��A4��F�Q�M�h�/�+2����2����[z�,?�S�/.�Vۄ�vDiE��uݬ:&*�7zX��m�/zُ����"n��2���B3A-T��*�H�5j1�=�{��E�b���W֧���g�D�{o�@��"r��X���d��Q���=[��|�*(n��G�ֱVX$vH��N�:^A�A�A�m�>x�I(��Z�CCG8�na���3�z�[���R�^�zF!h�Q���>k����i�Dv���]�2��G�g܄=�/�OK���i5N��H���X3�uu4F���XɺP���jG	1J�6�/�����H��z���h̯^g>�G5���:��$�T��$-�c?�qD�rݸ0��3�����Lv���3M���(�UZ�"��r]5�Y��W�w��-VuA�����\ݪ8��;�-�J�+|޲���H#�p�CӇ������[X�1:�{��CΜ���
7���O0�E�_*�Ô��j����u*ՠC�XH��;G8o֨g�;(z��¶H���x �Z7���*��H�<p4����k��n�&6mj�(U���F�s2�M�+*�0��,:,����Dt�k}S�fXMV��N;�ڟ�vV�*H�C�:V�x���g���-g�=����uNY�K� C�m�`
�'/��05�����GʜTwKD�����O��/�ё�����@���v��G��^����TJ���9%���J.9D
�eG�!�y�E��NбX�|7��_D�Q�l��Uht|CȇY�����²��������]ʻ͵�=2��>�)�1��9���N9[�t�
6�Z������S��|�m*Y����}��U��J��L����A,��u,�	ɘs�Tm,�p�X;(xP��9�wWb;��mK�H��MI��P��03���6�=���>���J�����/'߂�9���o
px$]�ܽ�$�ښF�W,�"�yQ����r9D�p��و���
�Q����YM5�6���֮�^����Kwf:�6w+�1�[�aN��.�U�1
t
�ɽ�X��
2���;��M~�@��|�[��^���+b.�\���8k�����f���P�o�O�\��2,!�Z�Lrn����2�3̰+0�V����f
mC��4��A���v��W	}���q�R����t\�{�kt`�}F|OT�O<ɶ��B��.o�t�2��$`JS c���j��s���m	��}��Y�`=�	%qR�����I��� {ʄ�t��մ�S�wT)qhr{���Y��L%� �l\,Rȳ����+P�k� ��ٻ�кQ�E92�	$D��>�N�/�հCe�"z�����BY���7�R�D�wA<�u��岰
~]w�VW!}k{�=ѩ��$�/asLr�k�}2;�Y�4�t�z��I�q��`��y�:�F�>d�����B�W��c���m��MUO|;lO�z����+��'����_)�o�W�ͷ��!�%�`�q�e�*�������#DtO�������_B�_�W9��]a�hk�
��G���1w�����Ӭ�B�)�#���dn�:����rci��&P?_�ݽp���M�r�Q�����j��i11K6f~>��,$	�?���!ړ��fzb�;J�{�\ �\Ӂܿa~���	��K��ӂ�8�K�f���{Z���8�s��~�(E���������58$��!z�#9�^��&����T����a2ބ"F{'�d0]}D��|W�"l�����'��h�R%��k��\g�b��-(gk9(��K]��F9aS�l�ŝ��^����ٌ۵d�B{T���+_�Z��k�\g�5+g��$g �1��V5nu��PD�c�ǁ�.�p�x;���I�t��rm��
�Td*tl)��?�M��]h�d�v/���
N�.��Kԍ87������*�7��!@2v�X��z�xC��WT�7�r%�kX	h��i8���a���]i<2Q� �f���d��c�E�g��F龑�?�W��g��z��A����}	����"HJ��?4�竄������&�[���\�����Ϟ��}���	�a�!+#��i>@��e�Wf&��"xB�E����{v���J�C o���>OE��KU��(	����[��ؑ^��;�t�"$���\�'����Id���(vn[a���t���b��Unuݤ��kx��	F^��`�-�3�Y_��!R(-2��m�%��M+�܅����e�}��=
�ê2+�i���ԡ�x��R��\�9P_�x���	JM6�k$΀C�Yy�����u���"��6���E �k��hW=�(��n���1�K��.Z}a���<"P���v�,�#���./��H+�G;�S�q��X0 ��^��߅)lt�Ѷ2�.xtnv��e��fJ<�~��3���e�gݷ����^�U'@�;��F>�-�u%je�1H�M��'�CY p�]�3y�Ry >��w>�����P����렜�.=�k��������io�|1��AA�2� S�Ĵ��3��#�7W�t�i��K.>@/�ll�uh:�dMBO��s��Oѣ[fğ6/��A��a��C�s�	������3���H�Z,�P�VBk(mq��� �*�p��?:��R���aHuO4�7��%�C9�?�q��s]�������²�a�6B�~��A���Q���^/\s8 ]�#?8��h!���ﾉ�:�o^v �v(��i\���P9�UZY����PEx�0\r������`�p��^5�s�d�f�T�:���/PO�c���S�P�����2e���\��K��3XA�-:M�_��5q,!/04p����F���2�-�R9��k@����e}��9�r��cs������#q��z��M�U��q����X�G�􇺼�c��}]�nylO?-��� ؽ�,����V|P�1�wJ��4�bhwL��ŧ: 9��<(&���E���)�C8#'p��l̂�A+� ��+ S�0�N�^�hB�Q�~ǉ���Oծ2��T�(i��,�T)쒭ټ��4���)ʨ�0Vo7O����K�+�� $��\�_Ql��f³�O�xA���̺6Z�m/9tZ��?�|ې�),��r��R6SrV���?Ƨ������-��V������=�����!^�]/�b�@I�I���Or�T�#:V�U���Lx/c���YL����ǼT��T̰�ֆ"򿑨�X,�Ȕt[#8�Y�{H���4��1���0�Э�<y�!���'�d��;F{\ZF���?/�c#���:�P�۪Z��¸����L���Eq�$m���O_]9=x�]|���C5�#�W(_�ŭiYKFfS�C����*�����X(��)�6(��y�~����6�����V�ϭ}
�LҴ�09���I��d��V��&H�����?��/�$�+JS���xjE0�j%浶��מ�-��k	l p�P���/��֟_�o�,�>����� %�X!]��*HA�	΍�u_��>��)��q^��mI��e}����@����{���`�,�H~���e��>#�Um�tN�v��
�߱��Nt��OQ`P�PTD�|�Ux��R�9D�1���r#�29#�øT�"�F�+���H��7�C�m��.^�k�/�WH��o:,t����\_��+�P9U#|9U��qw+�o�ߤ�D�� ���O�R�ss���6rZ� \Kv_{T>PT�v��9Y�^@���ɕ�م9Aym�B^�-���/d��<�L~��g+�6�(��"��V�|��w���{YϖmS�ۄzg+���P��6��(��
�X};�vS��l0���>4��Н�5��wFԦS�v[f�!��-� �=Ϋhf���{*�L3{���_H�}�nb�9�+n����'>���o,���u@UM��[/EW��SfjU�~��,���W亰LOr/
%�@qk�x����\$f{�2��e��燕t[�ej�����ʕ����#HI�-��g��"	��BXȑ��
���(�͗K3-$8]�b��2Y��Η�7��tue�J�gjŔ�I�(�c�-�2��7H'ѣ�FkG_�r�T={�I��ۃ��ˠ]����"��	���:���E���Ō�]Ig): �zS n.�����?ц��u��Z���K0��X���_gܡ���w�̒:��҂	�̾Ó��p��kA��D@mi �ČM�1��s�P.͟��z>z�8�A�n,���g�+\U.��P��@n��͢����-�S�swٴy('Cb��@��\�:D�:\�Ip#U�dg��Guf�g�E�c»JC�[�Y��BP�~�y�9t�P�������;Ov�c��vɹ;�|\�hf�|��/�3&��%ۧ3Y�M�����r����p$�#P1{���)�I��8����P�+qV�R^���p�W鏳����z A�;�E��v�k~q�E0aG���?�����	�18�8�&y��"&������8{g�}��ը8�[��|nTE����5�-��d9�+��?�Vg]��vm����愉���Ƀ݈ޮ��߯l��l�p�d��I�ߺH� /��툫W�hy-X�,�Oσ�v��`�>��.��xW=wE�e��G�8�B��@eg�K^��ߗ�>h���[�Ww��p���w���;x���. �A��P�
��.� ���򥲵-�wP.��uB�v3���������)��Be����ą�f�/A*����ʙ�[d��$�b�9��U�fER��=�DS�r��'[eKK�?����0��lO��`����!�5ק��gy��о�Jkq�=0� �����[¥W��*�HH�A��fDщ�#���g.ڞ�EC�ڐxë�y � ��;���
P얫��^C-�>j��Gu��"� �����p�+m�9�I$b �y��;lC@���~�l��bfUʙ�7��%�	_ �[��"ߙ�:fe�|T�֐4�S(�`��z������hgn��g�%H��ܡ[�"�Ѓ���f�04��j��1B��L���OJ��g��%uw��b��a�KtTX<߻{i�B��B��5W���5�w��s��q=Qx{'w}M~G�2��:��I��$%��9!��)�jz����M4s�H�������RG9֢�pF��X.EJ�D96(�� ��/F���`Fw��'�q�6̇РDUV�������LG~~�h p����L�"0�����:��j]#�Pl�x�S9��U@xް��є����^Iͩ�ލ5zc�/���{�۶v��ks�MD!��6K�_Wc�'�S�-C�!�Ǣ�ht}ɸZu�=;����ݬ*F��	̺��)�	���S�(�2�#���W�q#�"������|nB}��&1J�ܧa�̾��:� \��+Y��#�
F�'�3�K��H��eF�VK���fws0�$�s�å� �����2j���˼+W�����v�,#�D���f�+��7rr�h���$��r�e0]����P�e�f�a��;��פ/����&.7����VD����0���BD�Y}5��El��$����P�E�1�v�c�	�Uu� `���<?3 @�@Va�c�N��Q�3�p!�.����זō��0� �[Q/b��v+.SX�:c�8�2��������Q�2՝9D��@+�9�̶�Q��%H_��Ud?m���CQ�@S�J��1o��&~~��u.����ٺ�b	��Z�D�������F+��5����-�D�l6z�HMZ.��o�N�u��¹e ���'�}�+�E�Zv�c���������	�eiOo��(ɴ��T��U�GO�c�<�ܥvx`�L"x��\�������nqاi�Y Q�FJS���斮 Aò�ou<���:�aHOؕT��	�*l6lC�d�<���/hI�p��oЊIȎt������?���W�k���8�'�U�)��PZ��$;�F:���-G �`�k(#K����Ҧ��89�]�����V�~�[v�Z�CYw�$����n�ֵzN�xj����m��T"��Q ^Xt����*ۢ<�+�FVm+-�"Uۅ�v���G�2RI¶z J��qi�9�T� R���c@�K� ܆�C��8��`�9+櫫�����o���ڑq��6a�wSI��.�(�n5.�U&�ܝ�LSth�g�p6g��KS�(؅��}sd�C(jjO�w�T�){�B�<G���$��p�4qn�FG��RV�U$>�l���gp�l��҇���w���ɤ�m�et��H�}��$}2 }�m������R��p�f�;"b��y��B�S�%"̣6X#^Yw�!�d�!V@����s���iuF��;fy`�B��q�Em�L���(x�$xSw'����ذ��&�u�d�pl2FU�u���MdGe(�٥<xGtw�<�`Fh���\Q�!�mء�݊�w`��SW>���}����vZ�/���d��W�\l����Z�ג�ADlY�f��L{z�إ�]�a����[��ݺ�s�e.T���I���$�\��Q�.��usR��ek�Ö��f�g��7����GFo�ޓ9:���q*~��C���L �p� ��^Tm�/��B<GIk�� ��+\%�/x��	B����
r�8uF`��4�C�֡��D�yP`7����N#������$�B_eG/������]?�+�1X��C�=�����E���y�Z�2�OxؚS�+��ׇ��;���K=� E^y���7\�Rc���K�ز�O-��4Ku>c��O�4��K��/��}�����;���R�k���� ^�(�.:��wb�2��6h�η�_\��!����V����}� �*�����L5�������F���؄�.Iِ���)�/^o�7E�O�<�WӁ�)�-wCċ��C[�nff�C�yiqz�����䞩DN��B*J#�N�,|�:��W��(Rp��), �11q~F&�y:�uz�n�L~1o ��ҭ�o:}ռ���?^�"A�ݹ���j��!'e��l��@HSs�P�%ʙ*���耳�Z;%}�$%fн�qA�cB_x��8��d^����y�]� �y7�Ȏ.st%�4�`@'�)�H��(���x���n�/�C�i�����|�4g�3
��Sw��8l��ǣ2��*,�ú���C��Ѷ����|��� �f�{�B��B�6�Na�#q`�3�1Rq����@AI��|f�uB樨yjY-Ԇ��<��ns�����g~�.��^}We]H���_��SCMֱ�'���vD�L�H|�lXR	'�.^���H��k��}��X�0^��q�[Q��Z[-8��L�J���9ɂa;�Z|P��j��Za:M�r���5Km���[�;�h[�s{�-�ݥ���� �Q��y09խ���N��n���߶����U��,�o��W�x�+i��$����5��BQ���0
~�:h����j�O�n��H�Lk�t�@l��Zq��� �|�}K�"����L~]um��+'(ڙ@��ѥ��oT���.6J	ďOi���={BZ��:J��)k(�T\������
��"��-1I��N�(�%��pS���s�c����7�������<#չu��>��d���2��RP�5#�s�"�^҃�ݦר��棜��EI!(n�[�M:7 �O$�	�.X�<*�b\�ܿ�ߢ7]��ʳ�;�ʔ��h�鮉��lHh�x��{�E�����il4�%,�6�Ѥ���3���t-���N�H� 	�Jg�ʄv� M�ڽ�	?1�)�4۝LF��D{>����j�����Y#�no��^��~�kK5�=���k�=�z9y�+�����sQ�ԥVUJפ' mG�(�b��4�1�>�W  ��q�*�w7�}3������MsR���
�)$�A�
|A��DL��Hхjq���b+C3�t����u�*���z���Z �pyA79'6���dP�Y�b���X��i�|�(b�}�s����0���}��G��rz�A`ϯ�%�WO����_��̵��X;�f>\T�'�h�N&K��>�5JSyc�C�I%>�S���7Pÿu��`���	++��*~[���½)�ۇ1���D4�e�εÎl|���l��Ie+�{`�N-?�
=	�➋��uJf��>��S���:�Р����<ªP�g=�U��i|�B��H �gh�vU����8�Q �*�}��7���h�Cēy���+�PCpW�(C��h�8��#�d�5�5�ޜ��K��Hx-|����,M����������T`��5ƠM�u}FÕ顰Ah T0HǾ�>~��ˆdA	HIߤ�? �*W�{��{y�s�V�k�h
��yE��p�ġ�������s��CD{e���=���^�F]�g�/�eh��SS��H��o]#�#c*ũ��!�-�����5� ���(l�S�Y���/����yΫq$Q�?�~��4�9�ԛ��CL��Z:��:��A�h�R2�KwF�k,�x�����4<��EꂾeX�Sr�<k�
9���Ba�R
���D��CP�l
�0/�ǽKC�, *^`��c�E��-}�K�l^�P���W��&px��{5?)��\ğKV��"���Ç��%8R���3�U2U"#�u��B¯����\���!��~I=��]<FG�����os�Xs٣��do���u�	\"c��$%GH�k�|��?�\F7�$������� ʎ�5����q�����$ZjY4�1+p[d���L�(���	�aE����������D���H`���`�*M��G��A��=Q&��fML�"�Aɇi�`_ŏc���
ѝ�(�ߜy
7O�
���\L@KJ&��o��j�/�/��Eǋbn�C������O{�h���9�]~�%{1�Ϲy���D�{��fvN*�n�e��`b�^8�].�uG���_�;�e��� ƴ(A_A�^5.�K5:{b�ѧ ��Q?FJ������Z;�E�4W�:�s�^+[z��J��������\K����s,�䐪��� x$��ٜg ��vP]S9C��=H�^ҩ���2,�UN~Cް|�{W�E�0�?�&��w$�ldqjO�^ ˄2��"�����=k�ǆ��������ߝ
�����*�i@ФӞ�{9���e{�>�#[~��AK����鉎R�j�zHN��܇���2|c�{��T��[ܳ&%.��=������	�J��$\�������8�������u�}�lۺf3�w�RW��A�M�'��44%��kk��0*���8<����M���� Z?V���Ix���M�WAa��lP� w)��7�[�A���ӯ�+D�}Z�T�M�\��r�έ��ϝ�{)heW#��h��G֝)���7TN����B���I|O�SJ�yE1�>�R�e��C�fi�4Ԩؒ�%B E�aٌ���
�ͅ���y���0�-���z>:�����6�r$�vUX ��-�u�0�F��!n�5�ܬxӞ��ԗdq6`_��`ׯ&w�Egv�h����dU��Qӷ-�{�ܰ3 %�K�6�fy�N7�/T���J��/K�Lh^��'��HD�Z�q��}�ֳ�^�+�@��{\��Wk��x��{��J���>��1)�[���&��W[|��j"q�
6jÝĉ�Ub&4��k�SvȌe�2��;_����aH�`^q��DDEi�WI��,��;C-���a��p�n����&����j&��ߴ�/�C�\Ϫ_���^� �OF�~�,:�s!�C'��tF�#rJ�<�z�l�ư'�m�l{�~���e~��qjѦ�����Np���w��\\l��o�	�d]�no��D�wV�:J�����Hi	;��Re�N�<{�X "l���Np{�cp��M�{G5{H!w͢}�pq�5
��@2yu��λ��`���(6��z,d�P�%	�ۮ�f���4	{ty�}&x2����ɘE����r=Ɔ*4�z��
�U.��Y�m~/湀zuc��A2y4��q�1G�*���/햴�;�� ݽBW7I
)���֝n#=2��`�G��/z����uJ;39�}�̜t�E?��� E��	�lK4_[��!�F��=
'�r�T#�����$�����L�Nv1b{��ږf�A�b �v]��~�f+�y��nT��[�c�̷�;���&����DF��?�ە�"�k�H��~�i��:��'�_���JXe�0^U�?G� �X��p���ݗ_�X@�{�7Hӏ�OzH��2@}?a'�J�{�R{�e�4�z[�]ƿχ�I�Q�~���ٜ y�KF�u��E}W(R��!2�9���Ta��Y����+��M!D���@ax1[�a��.	w8)���˓���?�YO���=��y0Hz	'x��Y��H��{}�~-��e�=��qV.����ģ-9piԮ��7����tgإ\�'��|�@���u��S�av�� (t�#h09�G^����7A5�P�'�B���{�9m��+XZ,iEu=�R+bS���PxC��Œo<��A��T���*�����wY�_¯�W��� �|�0{sa�����s_�M��#���:�#�w+I�҅y!�$�|ɰ�C��t���,��>%�����S��I��+wUqpl�qi�tO�9%v���jj�E3� ����\8x�c�0To^��I���Q7�T���9����C�
~�#+&��v����������e2��p?�����Ze��!��,bύח�t����}�0�Dot=��������_9�'L��W�lo1e����d���]���L�J�td�q*&�~�7����6�M������G<�RtI۔�f@	��I睽�Εl���!���JQ W��]��(��t<ʂJm��!�e������YD�a��%z=��og9(���ޭ����1z����˺R����^�Eh������ч�* �/�O�q�$Ⱥ��4��2g���B/$,}_�����/�{�����l���O��|�^�d:/o�;˕��cBN5�e+8�b����7w��髿>>M��taHw�u����΂�-"t�Q�F��֍S"���g�2[�d���E�L��Ї���!�܀��u�^����նo}���.�Y�Q"��c��T"ϯX� �fk�p�M�w��q%��?����d��b����pp|?Se������S�R��mF�s]d��;�,Bf�WBh�nkuG��T�Q��p�3�>�`ء�#�,��m��˂;�)�3c�[�|:i��7.�%��I����p񯅩F�)��q:��z�ݻFZړ�륉�ِ�3f�֤�;NE�7�,���4!��q�������Tp���Yۅ���u�"2��%&iM��-�WͱD"����v,�^�`Y��1�H�7'�o�/�h�Z�D���:�bb���D���_b���XP�~�گ=E��G������h�=���m�Ъ97q�,�`�	�z5I�;���$ւ\b��� 1��۟�Ȏ��5ﳧ𹘐s�"��2ϐ*��Q���6�Q�ىۢq�qz�����ԧT��f�[���E��-��֠T�����/���4�ަ�h:ʻ�R}�H	����_���g��S�IBu�_�^x'�T�A�h����}>�Xe��w.��,�Ww"3��T�`z��?�A[1�K�4�(ua�Py?���d8�j��y���S~�@���3��/�҃x'S�;y��H�u�i�����V侵�$�U"����Qz����yfS�7GTgKK�݄ "PJ�����_���5aW�������]������=T���������c�D澵\�+����vb�s���ui��?�6.9�e�-�����J@<��|����A%����jؔ��m��A'�S��R�G�,����EU�,����8��"a�-D�
���YD���tŜ��l�aL�d��p���1��qS�X?�j�N��$ޅ����Hi@�1��� ��
�3��B@��^0ѯk,�:��?��hrg�h8jt��9���9��
/Vi�@����l���ؘ��������S�`n�
�)�*��@m3�R��Jr�ޛ��l��� u�jyu.N����-$�/�6�I��.���n�w�( ��������Gl�:�h8�7+�4*&,w�95�b�]�� 58v;E���^�`�����F�p��&���@��\�����L�rϪ��Z�L��G3|��.>�Ab����CctG�R���>R��)���G�z+����H\#=���@�DT󢐿������V��9��~�B��h��ؽ3ň�\���b���ɖZWͶ�EU�,\�����s�}z#�w~��/u��TlB8DJ�l�|WT� 6ao�k���HCmD��;�"D�B�\*T�9Sz���8Z�n�zG��B3�9�c��=?�`�B�����$��Z|Y-^�CK��P�VwK�2�I�f�,�1UO��D˝@w��E�����b*�t6q��B��$j?rG`^�����}�Z�vd��_��`j}%�},���W.�~�O�G��KљƗ��ΰ��C,�g4I�Ԍ1N�v�yeP����'�!�R����cñTl���ǰCN�ڮ ��cW	wǠs'_�i��ƃ׹�kh޽˺��#�Z�k"�U��������&)o*o��O�!9Y ����������R����`a��P��V�+9ۜ��{�͘��������d��`O��-pڡ�� LL�w������[Z��Ӎ����2�ߣ���%A�vM��9�63	���"�~o$�긤C4��Y�;o{#R�ӻj����LVFcb��,��j���'�N�㩾�Z��,l����;��0��'�̽�T�]�)ް&�N�w�H{Xt���V�R���@���6 ���7�ޫG���]�ۃs�(p�(���B��[��r?�.M�2ۯ���S�;���Iy4Hϖt�����%D�0�7yB�Y֯�Q�`Ol�Q�C�����0J��"�X�K�n~o�N�.~��I��nY4���ԃJ��H���T:��6���B��p$�0=�*�����ۉ#���A�����Jle����d,�̦2go�T��V�\����0��^�P�FYJ������+O8�E8�թ̝�;}�f���<.�e�d+Ǯ�&�!�-���=x/�[����RGjd���=jƇm�D߼����RS�X ̡�/�&�{4�q��ES��VhQmm������D��@������b������l����
KlXBTG�B����1L��'4GFƈ�lTܻ�"W ��v�W�u`�����r̦�.��Ebq�W�tM�&D������U�����_���֣[y�5e�>�;}�؇�>�|�Y,���Ѵ��B����d�q��q^\˅�Em���I�5z�m��7ǘ�c1�h�>y�H�n�����%C@-��w�_f��	�[���ez�`қ�
�Y&��_� @��,�!��.���.����$�����-T0�_e���/J�s�"oB��%i��@��-�j=0�E�>IYh=hJ=��@�=|Z;V�����G�.��k1���^��ڕ�=F�L�*����
vB��;�C0��6,IIO���7-�"���z���ȯ�J�6���Ty.����K��N�U��P3�}6��C�J����V었{��є�0q�S�@�J�c�7S-V���BӰ�K��Y��9��	��)�KMLhX|�+�7={BϹm"\\~�7�)6z6��2v�%oD�轘�����ǘI��$�ѷ��8V\3�?Z+��B�¥/�<���|n�[8����@zp���4IQ A��ߩ�t_��Γ���ܩ��\b���Ε{�g�L%� ��*6i�Ǧ8!�g��`>�Ik�3-�Y"�?��L�4߫�
�4K"�\�C������Ba<4�g�Z��p�g�L��N��E�ϸX��y6��tv��V~�)S�ى)qҤ6�~̞!��~�A��R�ǖ�I��~� �Ce�F�����Fo��^�a��*��Xa?�wm<U-,v:��-�ę�eo�P���!b��M_;sH.��]؋Xw��{0��K���mEn�$-��{�H��3�{
���3���5V��-���,��h��ԄN�K�H˕�CN3nn�tfсm�>�L&8��Gckw��Y��P�u�/,J@��Gu�cә!���V�?�m!'�Y����Q�4�m�+�x�+l'Prr��$+�	9�e �:A�Z=�,�A��pSƷ>$�9?����ч�1k�zE�<�Gy>|5dȜWJO2�kG�lM~z�z6�.g�\�]�DWԆx�j��!����'ؐjt`r�N>{@�p��J~�4��,��x �ɶy3��&�B򩗡�1-f�Jk1�ՙe}��a�+`:@a�[$�&�n�T�-$�ʿ�������^�V:�+}��fv-B��<R#��"���xw-w��.�\�3%Sq�4�z���i)���X;�|�O��(ЉB��#�Gi2[}[��2�[���r�-���[߷��\ʒ��shL��S��Yc�(,Gn�i5��8�;M%j{l��:���G�b�32s�;��F\t��W��ߵF7=�K���ǩ���u-�d���6ߌu���Λ�&�	23��]�R��51�Sp�����nyjG�X��r|cz�#����{d����!�h�`�:��b� ��J�����S@?Y<g}��%2EB��ٍ�{v1��>��&�}�_Vj�������*D�����(\�
��< ��-����@��_��8��4'��]�'�"�F�|�I���1�=�l�O���Z��_T���d���ТIs,%�B���Q�����T�6�5����doN����Q{>���|� �U,c[�ti��g,���5�����W]#+���G6N��K�M��Y���ot7GʢLh�)h]t�*�,3*�@z]u����_�tm�4x��T����Hb@dvn\����}R'���~.��V��q]��m�����G06��
$���:�8>$y<��`��0��^��+�tPMP{���6��z�
Ő����bE|5�K0���=I\R~��L����0��COwD�E;S�v�<j.�}2�Gz�hUL�l8�p�#>d_`M
�9�N��/< �tc���,?t��&@~�d-����I1 7���;�1� >�D��9_*$3^�������=�P=c�	�����.���U==O�5&���M���in$���ъ�h��9��m�s�ߨ����(ꈡ�K&P�oW�\��������Qӣ>�Bc6��&���Wa�΃1q2<��#:|S?t;���q<,#��qD���~&��u��� �v�X!D��U��۶T$��m;JR�g-3�)�R�3u��al��j����UF�a&�@�5*���,xR���sb
eh�r�fG�v÷=���C��r�{�>-�G�`������6�C�L(�/�]��wV�r�ipx24u��-�J������!F7|�yC^��چ�7�Ѷ"��i�	���&�HJ��U|��"i'���"Ɗe�r�2��:����,�ERy� k�Fk�5�ߐ
��G_S��_3�q��Ⱦ�#�&�����86准�	�,l{ �f�O9�m5D*e�ˤ�u�e���d		LU��=X ��:U9آ��v�Y�H�"f.g����R�����x�>`_�S�v�-��z��v44h�q��+t�n[8�jD��々K;/��e��n�jigT-š�ȗV�vK�Wc3��� �7*5�B���$N
A;hu-2��`�|�-���}�r�a�oW0��sC�1dG��E+@g��V>ώ���:E���}�ЖE�j�T�i���]�O�ޥf_h�M$�u�U���a.�!�3�[� w��N�4&��r�O��I}��7��&��R��X'�I��N+�gFK%���o�d&0��rY��'v�2�Ƣ<���E���<,yC�[z'�����m�(P�^S��� ?�ϼ�7�?NS��M�J	Pvy7�Z�-�z�Ա��;3.^�iǑ�?')Q.ker}�3�.��e&Ζ� �	#��e�ž:<�\�k��j�?U�6?4�!�Nuu���|�v:q���Dk@�ѫ�� |�Ծ�N��(��$�U�Ő��;ȓڿ}������9"mk�[	�7�!z���fދ�'o�Bz�5\"�3P�w��2B'��x��:T��D����'|��o�IE]n��O��)���"��➘PF����&C�
�opZ\=�(�P��XH�zۓ�mn�ܖ�ڟcV�K�c�?8�U���Ţ"��G�	��bsʩ*	�����NH���s��v׿��{�ӷ���J����n7�
����g��SJfu�_:�Z�BB�@w���ŵ��6�0TN�2s�"�����x�p��[���$K|��L�waRJ߆2���?�Y�P$�x�E�,��|�[�3袣���뼦<�L �y Q�Dv�'8��#�G��q�����p�/�O�Y|jf���ށv8��x0��S��7��ӟ �q�Am[�R�/�o��sw��9�v#��xP��P~V(8�ے>T�r��mö"L���9+2�����"m�ϵx΁+f�=��ٔ��I�bv,�:>���c�����/| ��e�"����$��jߥ�6�oZp��ۄq��%Q��%�솖�h�'�*Fk?йf9�+�>7)O�!�J���ے�h�	m\�4��p�u������_��];�8%��d�&�iˎ�ͱ7K!)쪎��/oc$~g$�?���J������`�.��C�Ϯ*Ӏ��˯f�<��)�,W��5=�	�Ɨ7�tR��j]:�'�;��ғ�R�� ��%���!y8�W��@����G���(�%�V�߰�&W�
%�:\��6�G{�b��3�b;q���7�p��SԺ��l;r���A��X&����Ui\��4�<
f>ep�hx��Ǒ�h�?������M���!�jO:�n����%�~��z"ug�[��q4�?�h��`���Z���p�����Zʼn��N�Zo�9��v$	\�RP�A4E�����F&Ȁ���U�Q;��ZK�zq�oII%�D�RWgg���3kƹю����r��������<=U
?��?cܭvhf���:�wI{��&�n`.��EOM��=Dޑ�n�P��g�\���Y=�i�^dk�gA��@r�$���
_��˘v�3�J~3�6���F�2�ҎK�D�
�!��8��TveDb
(�uR択&U�Ԃ�����!O�kAN�҃涙��Η�U8�QP�����[k�
�XjYM��\t\M����/�Jy�I-��)J�j����rA0������}R�N�8l.S�L2c�lZ��@�|��M!��;T(,e��M��J+<����u9�;I��t��@�F�b~ �H(92
��x��s�����12ӟć{���gYh��u�����v��a[�@����� �>���	[P0R�Ou2�H�i�uB�����ٙޯ	</�s��QsŇW�[[�f�|kX�G�J ���g&u�acCX^K�H�bs`!Ӊ�[�JS��,V�/m�-�9<j{)��D]jl!��u�E��vX*̌���J��,��}�!?�5�	t-a�6��?��BR)���\n��ׄ)��4�p��ED���cR	�'0nH)"�1l_ ������`4�r��d񏹂�S$����<�ncu$��!2c2xy�9�9W�g�K~����p%�9�xR׿���y;L�+|O#(�p�x��p�2�X��|�$���q����T� �	dIL��7o�e����y��-�H2�EO=R��S#���ᮖprɬ_%�`Vt�t��ҧS�u��o�eɞN5�{����#*��>�����a��oYk(l���B%�Q�p��P�U�¢��i8�+��D�p���Ԙ��:�&:s_���`�J�w��U�#Y
-5��z�r��f��
($�(s��م�q��O����f�h+}�f��X�C��'���$�iA�a���g|��	��p�I^S_���ڿ�U�z+A�Y�jG�c<��k�\P�#P�����8��b�m,���|	�s�h6�{U�Εh��l{�[<߻�SF�)��Mu�`?lE6JUgeF�M��	�J��BE�L��\L��&��jp�)� $��.P�5M<�U��x{>H`b���M�ǽ�xĄE7���M1�Z�~�:��F��YN�=�x&�<�lH�������IwB}�>K���ק.b\c��%�0S�����s��k��`6���Ly��h8�S�-�Z�5���ZaY��^������}RE0X)ɡ)��" 9F�(��������C9�+:��1�-2�` ��[6�vH���!�M=8 翕���Q��a�n�Q����ɍ�v�v����^r��P�	�w��5][���Y�"������4�,S�1�X�J d]:�������k.�+�>odS47��R~u��dƛj1����VV�F���g��%��jmPf�\�i>�1э���#[��J.~Τ`��=�g���M]��I!/����(�g����F�������#3EmS
�'T�v�ŝ������H��(�E(R"R~J��Ao)|�$a�����c����Wp�w��`/�4��U���� ��B���.�
�� זM?�����nu�iS�y?:xF��3Q�Yz�^!�L���M���6�l֒E2�������pJ�O��܇��혗�;߆��Ą�	VSf֦�OAu
�;��έ&��9��&�~���O�12��Ŧ��o\��.���a�d�Iy����ȅ�Lj>x�d�h�w���x��P���5@������$[$	�Ƴ��S￹t�`	�/��FJ�ch�֙�%��,����#x	n�m�(�tj�1�ə_%��Ԭ��B�u5s{^�g��=#@��U�de츼�:���
?����viK
�H"j���%FG�l�mw���{�Qg��}N_q�Cl�#�
�4D�ȧֺ��/N��8ז�	;���?9��zV��(�r	ߤ��t)ek�h�� ���F�^�F`mD�̈�B��T��%PE~�
��� z1<�9�@/���9c���}5������H4/��p��
��ISp�R�س|<��;�
�z �=i����7w�ʱ��:{�/i�"���R��b��.Ze��fs�t����=�A���~�Eo�)%���� U��K��6���4����h;)��py�{���V���qtP���z�ҫ�~��Tvk��pr�T�V�.	s�`3�Y���3��}�;�J�L���>��F0b(#���h�
b@h�~4|�'�^�3����ti5 ⛄&(��'Ď�P�gQ�����>��s���>m�B��ӈ}�/^�m�d���o�� �bBr��_��.�8��Ϟk��t�=�׵%���,U}�h���pQ�*|~��W8�1�u�>�����}�a(ػJ�5q��a���K��*�@|�%���{�{�\�H\+��;ߞ�֟~q*��)|R ���g��U����W�gi���]���*����~#��_�Ds7�{�j�y���aI����|�׮K<�A*B����0΢��f5!��p�ƹ�=1�U{��p�N���R#E��D%�"6�qS�� s�S30�2���W�}p�Α��nzQ@�ʼOe�}�$�z��C~��������{�׮* zs��aN=m,�T@�t��Be�;����c��ջ2�����o�Տ�E�E!Mv����!�,� +�N|`��h�E +Q�K>ᴣ�C�FY�+[��Y�W&���^���hl��F��r�&d�X��%L��]�{�
�����z��劮�����<m/��r��ia�}�*T(�.ٙ[|��R���a����:���t�0�Me�ԫǋ�Xa	����_��g|�D8����VC�	C�п8-�1�����|�+q�~�x&Hp��D¿�5U�T��V��A���a7j���~��1߯�s3#=H�j|n]��j/�~����+5��}P.��ˡ~q/-�S
ҽ�Tk�f��s�D�1�,�{�+�u��a�)9��xf0ߦ��-|����R]�p`
:��+D�EïY�%��IP��<)��AM��X�E�aq�t�״��u��f�(n6`;�z3�Sm{-���
�zY- ����2q���O1aTo3!�:���s<��ퟦ͗��
ނ�hn��D`��@A	�����ǥ�����0��
.�,�� .�_�I���`7�h�"����S���t4����fه�-����B"^�n�5`vaz�K�#����6��ؙ��U�|����P�^�w���	ܮ�^�6�'�t�S1K�Me�3j�:��c:�_պd�q���Yh.JC�.�b����׀U�ig�{���㯓Q��S����Q����� ��O���)1_�o�f�%즤{2�(�Z* E��(
��|��8� �!m[V�mj	"�G>�;KV�:~9������>��~f�Z.�Bu��]C*Gm2����Cx~/��ڴ���r*0C�v/!�7o���7�b �3=�F�a��H*Eԭ3 tvo���-�_=b�����XÍ�F
���Y]���c����&�)K'��+���A���c���Db2Q�!xF=]��j�B�>�E��ڝ�{�@���$�@O��[1�=9�Eڙ[ٷp���hV��%�	��F����N��e����9*}����я폓妯±�R� us�[ƽt�,t������1D��R�����P�:�Aq�ڭ�ý=���4�9��c����rM�i	*d�r�@�֛��������� 3��?�hUK�-�-�Ǡ����OW�1��/�O�9�n�N�k��9�� t��M�������7j�/�rq���/�G�s5�4� �R��wZX�6�����{*����%?�.m�?ݠV�z,�y#���#D�*3����@ṴV���ih4 a-K'���|���t]�PD7É~�ӝ��@Z�HeH0񎦷�:����/�:�$�@PI50-�Ϧ�n,S�~�����?H�×�t0>Am�!A7�˟�6�8۷��\�PE�L��������ItU� ��Lf�G&�=H-K_�u���$l�B�6�٦���ra�(�6 ��44�XQh_�G�鹌��e����i!��ρsW���`;G"��D}�Vj7=�p����R�� l�qY�"�yb'�~$;:O�$X4#
�ָ��=ف�'I���@w%���	�0\���@�K��$���7��u���'�zdx��MJP�L)�?�;7��+Il� ��i����!�gF����u ��Z�AÆse�څ���ז�-#����R����͟@�+0ZzP��БG ��?j�9���%��h_$�*򵂁p���_�VSQo��z���-#�2��4�o_�k�c.>*9�����B*��Ғ��3���-�	@U�q�v�-z�9�y�l�}�s���3Vh*�:�5�؆�F�0"��og���iȩ?����tzH
ܠ��.����,QPǞbJ�$���5����Y�Ӡ��~�8�8� �w���O'�l������w���kıA�d䪓ġ(%k˕)���K �^r�Ǚt����S�^�Q��د��m�Ɣ_���lS1fy��J�(��]4�3�J���� �6=��(�6; ��9`k[���d�6���'s۫����L�CoA��y�Z�?4M�X�V�s�C ���&ά�JCŋ��<8�/�A-0�k�Cr6^�(�LyɅ�wG�����+���(c�1��(b����I5m��5���UT�<8��=a�#�2��>�A������?0�Q����:(3�v��9��9�;]�	pq$o�{t$�K���AP�~�l��.	�eHI/����lq��!UxXe �a���Նc�@�3;l�|�f2������ܙ!x�<�!AQ�LV�s���wi��FJc��	�pu0���l8��}S��zp��m�,Ua!�J^Ҷv�-�R�&���y�I�u^g�g� �`DP	�S[>����[<���m�$O�Yk�;:�8*)��c����6&�<t�h @|I�;c�v)f����ۉhX��>J˳�V�5�f�������3b�ݍP�A�J�L�?�RDmw�E�
J���0k��j�&��u�§�rZ1��~<�;'���E�p���T"-�ۣuT�9���F���0Jঠ��Xn0��f��~J�d�F�:j�����F10�O�c�3�a�/V��{��I|��3���;�K�#�A��t��K�]W5vE���ע�kF<��<N�=�G�^�t�	Łe_�Λ���dg����<�j�A0�MǼ.�[1c�v����5?�$�[XN�k����o��� /JL�k�*P����J�������^�M� }�����2���8��>ksQ�,�g5=��P[b@���UZ"�U͹���i���|�_db�E<Ύ6qVB�;������l�k��ӕk��� �Y� ��4��~J�6
��	Xr~X������h�ҙ�=�uχO�lc�e""���۠
���� ���\�@���4T��P$�6�S�b�ӯ��Z�
�K`��i�Q�R��b����#�XX=K	�a�����K�:���b�7aq�Pi>��� �:�0 y����(`�G�I(`2��!5V�q��������*ع3.I1v#��7����N�E��(�&��c��&�m����4�u~��K��:岙S�Ĝ����0NZ�À�,���F��1N��B|O���K�l:��!\]`D(0-ۡ^�u�)��U[2]\��cu-b�.$d�v���̧c���׶`�R����2�Qg���-��a��@x%h�q��1�r}�N�O�c��4�ЬD�5�n������~���a��/�E̡-Rؒ�K����E��6*o�PJ�tF��{E��H�p������p���s/��3�G��q�$jk�Df���9��)T�l�F��~o��U��rD��~ �{�M��,Ay�(��ݠ5�J�;n�5i)�W�5�2@j|��2D�����jn︆��c���#��+Xl�J�aB���f�s̻�&ɐ�Y�d����*'!JW19}�f��7^���W�厈Ƞ�@��%&I��Q��m'��͝>�d�Q[�@M� e�F��v�&Aݜ�)'���ސ�e.�o��`�K;��hͻ�v�!2�v-�#�V����M`LY�d���|�7��YS|�MQ5"Rq���W���le>�J�N��+W���.G�D�m��X�Y�_Ku�H���
�V�
$��~�N�����l󗫪��˾����?6A6���V�Wޣ�)y��RhY����M��i���P@�;Yp4���	�]�r�I0�'��-3�p1�$��g�Mn�C��}�{p�����`��᜕R���kgn�u�ne�~:��a,��p�yM6�Oޱ;����J�Ջ����_�1����o�=�U����J��K��>����$=�])X!&d�P��|1���,��ϊ�${P����Fǌ�Y�E�����k��P\�j
��)��V'�.��z�
̢QM�����d:]w��5����?��Q{�N������VE����E�!]�̬�YrP�X/y�6 z���� �Pݣ�w����iz���N�ʦ��L���dl��Kb���@��.�(S_����f��Z}���퀹�����ƒ���BӍU�`k�o����i�e5��q�����L�I�Tt�����ܾ#q4��%�B��%#��8� RG
Q͢�nB��f~z�x.��d����_��Ç�!�t:�-��#�����A�'���>��h��U	͜�p��?�e�>Q�Dz��W>����Cݬw�u�~�\�����!I&C�����+����΂�����[�R�;��X�V� �.�d�C���|�ƪ���|��)֝���4D�p���%6�S�?�ݹ���F$�s�.qY�T9���_�Ȥ ���/Z�HK�eLJ��![�إ=N
&��p+Z�Wy��1e
�/AHދ�V���O��S�Td��Q� �H��z3x��"�IH�Ҋ����m\W�A4	�b[a`���a�$]G����\۪�V��7b���1�+X�(v3O�\$����Q.ف�4H��Һxe�*XT����0��\��O\ăK����Ttyܤ�����R�7�Ye�l��d�8t����u�)+GM�Gŗ~)Q�2�I4N >��$^�SP��/h�I�ICN�<1e�kn_�ӛ��`��iB���S�疣P�s���xʗ�z�6M\_+S�1G��~�92�E�r�:b健�T詘�tZ��{B-��u
kG�"%�vX
L�8;82]{�������i���஻�~<U�C0��	g�8�R�K�b����D�?�#���Y�q�Ƈ���1	ɓ�C!Y��ͦ�����󄌀�M�S���³w&Ks�?[�H!���%޼���Zb�B���S�˰��S�*n��-���sO}�9
C'W�y��[5�Ղ`�1�d�ψbD�����i:�)Dd�����xxF������)|�:��&f���G����VY�G�##e������ީ��Y#a1��9��SYg#ڴ��dw�K�X;���.\*�����~�V��Q>�R'����.X!FlU���$3���M��J��lV�n��r��O�%0�[��׸r\I�uU C�F9����{W���蠶�P��7�&�0�ն����$����`�������-��(/%����9*���܌��Cx��Aض�'������B��IBs��sa��?	�]�e7)�pݴK�E��O�����<0`l   I.5Ƒ�
 ����_��U��g�    YZ