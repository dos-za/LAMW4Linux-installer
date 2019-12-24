#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1632426362"
MD5="6e44396fdb9962851f753711cf7541ca"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20364"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec 24 15:18:26 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���OI] �}��JF���.���_j� {���D�їrF~<�JoS�����G�8N|�(~U���i�#K;�=�1��{?k��zX3������{>�a�,��͉� �1�
{�o%�d��͋ʗ����������B��I���Bh,WA,e(�1��s<��a`<��Q����b����=��PD�V��O��De?:�/�Qhj��)+����d�� H��?w.�x}uq�ʐN8Au^��I��끓Z�P~=\��8~<�L�1�EQ�wD-5���:��������\�Q�2?6Hh�f��#^[��<��7<	�xv5�;F��_��ў������Đsf��
�r�Z��i�ɠȮ;�Aʜ�Z�m��+����կ���F�K�ڿ�#�-W�@�8��X��H��$�����H�)PC1�\�y��X�@b#�k������G2�38�zl���&��x��y�E��bH`N�h����q�����^֟�~�v�8�)���6��TF�ץ]A'�"�W�ʁ7A�죠Z�-ƍI_MN��p�=4�����0�I����v	��gڭ�f";m�͖�=+`з�d�J:�b�	���v�I��^��P�˃��år��c�Da��]K��I�?d�$�-f� d3`V�n8H�%_�3����h��-��c�X��k�R���'; ɼ*WאD>�/����d;b<�N����C4"��8C��Yb`mͯ��k��K �%bp�h���Ջ��\}! �����euH��#�%��i��ԛ��D�l'�P4/᳦pN0��S0��&�9/��+s��ҵڋM*�GԪ`V�� �+��_Y���۞Mݼ!�B����S(��_`A���"�z\�I�}W�����&p�5Ge�s��^*88T���:9�F��q��𧕐����sc$?H�̉B�$`����{��.y*(���1P�2�ս���B� �	Z��K�X�UG5%5���Q��;��Щ;?h6�'��o/�_@��!���Fwx�L�#c�R�z������jy�*dD;:���|]J���`^�`��O�t_5��9@��;e�Q�k�`m���V��k*��%��Ë����خ���uY��o�:�p��V�����Q{IY ��at]D�]������F����|�_�s�0��|����$�=���T����$y46j�ۧ��:�����x�"��em5��� ����W"1Ⱦ�g���V�����NP�y`�`;��;A�;��t]�7���t���I�K#^�o�2YL�mh✥�+��,T/J*��G_>�2T��ǥIV\r0�b�׬��~�O�����KF�����Z��T��R��b���HD:���ٲ�٧����)�K�̀��<4���iRi��
���ҚV<�3�𘓰�
�;(k�1�0�%���|�a8W�!,�A��)�i8q.���"#_1�1�M�k�>���V�H�.�M�^��W��$�=�`dJ�"�LD(���x>���M*r�$��6� 
1B���z�w�%9�+�;B����C��.�����^~b�@�"	������h���?$�D��
����Qc|~2`ս�7UO�?�o�bTY�]��*�%�[+�b���{$�>�$����^:���6}qb�8hK�w�8�V�%Q�`��B+��5v���Մ@O�n<��[�ѶHJc�v����V�0,Ӱ���@3L�jv���C ��ſpW?�]v��?m�{���5f��6�so��G��ٲf��)��P���p�<�0�B���汣A7���F^��r�$�$�K3���l�~���_����P�ڀ�X����ʢTx g�+���Rs9�ÿo�2��W�{�h%�4��f�Xb���=�j^�[�w��.�i���jSf�c�ۗ��gƩ������d�p� G��G�����u���<c�Ї��Όŀjߐ�$2�o	��%�$�������v4��4𹊣�7C���v�d�'�[���*��-v��>^t&�l£O�B����˖����eݜ��|J,\�Z
;���N����I��<�_e�D1z�K�!<�Ey�a�#���|^e~�/E�){�s��dV(N��|�D8��ϣ��+����|<3��C�����yOi}�`7��� ��zf}R�]���j�%L�O�Q�>�s*FP��2"g���Pa?U��}�jK&L�&7����g�<�*[�.Ks�CS�y�7��ĆM��M[}��ǧ;�>�FTB/>����+X���f�Uٯ�6;�Z5]e��p�?"�@
���eOk�t^�Y])�b�5�bP�풟#U��N�aL;�����y�Qt��^����PE{ (�\x�O&�f�����U�/5l$Hx�1W<�������ڤ�URSa e����O^q����c�ږu�.��=��߼�麱�Dڔ/	�=1��5m� �H�)Fy��b����'��F}���S�Z����M�qp��tޱ��{�o�����Q���:���v�Ճ?X5ѫ6���h@��-���:TG0���XcQL�h���5L7���{G��
�mM�DW�]Q~���m���},w��Sek I�r!;\�F�Q�����5���ߟ�tD.%�1kᦞ����q}�������~d˥
2,Eї�CN��܀~?��w҃�P�\O�<���m��E8/��!�ȾH>wm������z����1?���l�=��=? �����>Ĩ��I^��/��c��T��6��r� �Q��N��VsV��3��;��G*V�1qW�KkŊ��V�l	M��˹զy�XCM�6K��W5��w}ӑ�LbV�D"P�fe�m��h�"<R���I$T<{\��! 
P�� ]�r�adO�ţ���`�'���?[_����A���b:
�˝1#�~W���ﱄ����]�Z���{/zPnb���-�Y<mk�� iʮ\���N�V�4�Ox�e.'w��z��V�+B�_�UH<gq��	��^x�%�XfPR �$\��q�2��,�ރ�Ȝ���p1̶����)gB5R-�phD�Wu���Xu�����Y�7f]�)��Q��L�&#á5[&X8Y��Tш ��]��F`��`{ln�!YNϢ
�xZJP�����V�C_�F�Xִ�erNi[B&J��?v@�޾���,bg�隇G#~����j.!n��C[7ɨ��BP�,�DY��+ ��I?J�R�fأ}��;H}�����v3A��w��<�
@A�5���;����x�O��@aLz^k�k�
+g�.2A�q�S:W��>�a�B���!�r1��V�^�u�g�a��A򙹮��eA6nN�~>"�M���Q-W�a���>k����~�#}�I��KZ�H��?c�Ǚk���T�%NCn��(�c�6�$Mo+�bR�ގ�ԟj��9&$��4��Kd�����pCطܾ
�i�'A�m�م�(m�����[��lg�^�1��=��B��&��3�đk�!��C0�{A!�D6[�j:�i�-7�>����V���v����1:�HCZU�a�<���u��������ը9�ğl�q�׃2��h�`�����ǆ�x2��m����D�''^���b��u�*z���ߪU9o��6���M}��*�#!>�GO�3�ß�
wn���+�.1��@*�����0]���^����?�������ĳ�<"��@>W04��	�R��MB[�~o|��+��	Do��4�ӿuY����Ka��P>�>{k��-����������	���ʀo�z�g�/�bJ;ݓI�}�'/��hHG�T��h���!��q��s��9$?x��2juvdt��@A�4-�����4�A�g��E�<�~з���1鯗�_�}�Ku�����w�N�'���A�Zr��|�s�]"z�]�7
H���U��9@�J/4���AͰ4��޽cw�%1uUd�y\�Yb`�F�=h����Bcћ�6䰖�o_Ȁm^Q�_��n��|��������!WX`,������-LpeKS8�4�O�M8�YiP-�n��$�e����d}�<�`_k�)�a����-`��@�3��3�����s� ߛVLwm�Jk���.�#Zj����ܐ�r�\���݂�ܪ�+�c��ӓ���	�y�:������)֝}�a6�����/L5w�[j��ore��gs����\��	waR��c�����Of+�w3���Y�;�U��L7��"<8�Nkc��Q��ʧ&#y0�MA<��p���CTk�6S	��x^�#U�8�F�����w�򯟱��85ȓ��Pq/|�S#���ø�s�CHT9i��a���&�u�R��6^�l��-�_�c�����Fmd`$��w��n�>jAx�� ����1H����("�����V���/� ��uR=����%�i�ngEQ'fߍY+�mҽ��P!"I����`�/?�^�ֲ�^��RFT8l�1�Īg��8,��'lz�)�<D�g�,W�(�89�� B�x�[,��SbtV��Q�1"�s��#⏅�ɳ��Ⱦ	1�6|M���g�n�YT|o����u�a��v�hkc���q�hy8��$i�82��cD��_�C�>3�������g�
�8ia$�"R�W� �s��K�eD�O�B`B�<*W�:Q��M�op����c�Vi�����x�y9��v����5��i�f�x��y7�O�@xn4[*?[���>�?�}y��=���v?�ģu����"�G9���YX���>��^� �ݲ��D�=u�&��*mN�$�.7��"�'���b�>p��J�����K	NOd�|�� �$����ö�_�qS0��B.�c�I�l���k!{"t�2��[vѨ��=F�1'��)p�w^�K����e�L��:eh�b*�+%Ws�EO;���T/�RGr���1��c�w������I�c����o��8�z�k`�Q1
��@AI�8B+��c\�\��[ؓ�ϡ�G+���w����7rak�X�ss<�3�<qj�S�5-r��f3��F�-��]��E'��+�N��, A����|KK<���f�C���&|�p�N���&=q8�<^�!wh�}
{6<��D@hz����D��͂]�����Um�H�R�Z�S�(L_m��^��ۇ�~�R�'X��#�e#'� 0�N�����&:��#�U4��Tg��Z8Ռȭ��Oc��Uq���R/�nOE�ʴ�-'�A�Ѳ0�)�Ԇ�6Ht��4�]|B����Qܳ���s�8֟�^���L�}��0��Ze/m��¼�� �������U�m�Ӹ��P������/��°TP���ϰx�s��M�|(_�X���Nj����+���mU��~RSs�_s����d]��>`�F� G1GyF|6�r<p� ���s	[�U!z��n�+�����=� ��E�1�Pt\��24=|�¶�!^XEc��S���F��6�t'�(5|·�v�� NcE902q�*��U~��?�w�'DNs8���L�p������(.��wƐi|P̨��.@I�����	�����m�FZ�=�ڴViP-��,�B,�������P+=?�qA�-(�F^tlz}�I/0������ u��Ȱ`���I��<6���\�T`B@Mr$I8�������X���Ql�Q�v /*�l��D �J���H+������D���[�������.��׶k =�8Q�9x�m�A���3��Kw$�zĠYD���/��O����I]���I�TƞN+��ٸ�����em�o�g�^~#Q3˖�BB�%�.P��:�8�Ge
����k�.Ѷ��2��b��+���f0�jr��Sr(p�?j{��wE��m����,OQ�����9!Uu���WݷW����?�žj��Z��Ű�x�s�k}�����Zw_ʪe~ &R[��}#�KD&`���H�|A$�P�5jD�/�_�Uh߈��1�V���g���8�pnDn� vQ�g��T��3�q����_$;w��u3\��"���zuU�Nz�Օ\w㮿���``k�5�D��U�[k���{lk�6@�������ˉ���[�D�ra2�R�)��Ɩ���<g������}�ï��+cz�&���vdqL�R�%�For�Q�@���G���)K1�T��yl�q���ad�dסE�.���W�g�n�)��*C-t`�z�WFT��p2��j����P�1k)hT�x�px$���Nv�Ʈ?3���ݿ��"�NVm}�c�N�������/��7(Nt�G�FW�s��h$�PH�9��K� >�=x�rJ��e
|��n@ҧ�h���M(M^�l�@�f�e�����ζ>��vؘ޸�+�'�`�X%b(�k�!*3��1Ҝ�7ɓS��Z�*��L=��l��ku}�yf�����dMq�:�L��ٜ* �S�}�h�,��@!9o���� 	P��3x�t!Ǻ�q&�P:%*��i�ȁ#�|D+م��Ɏd��h��j3�2�<��vƹ���i�O�O���0 8X_�7��-T��k�ۨ�ފb���QM���Ľ��at�|�֑ngT@�ͥ)[.'�+���
�͍�fuDbI#�)_�26�9�a���)$�7
��i��Ƥn�X>���W'1(st��O�6��Z��N��U��.�~�[TT���`o[e;e���ٹ��2�MG@��[�������4:�rI|�"m�6�"���:g��\?_��ȫ����:��:kXH�L ڎ$�����V��Z2t�Qx���C\Y���\�Q/IQ�A͡�s�	8�Ɯ�6 ^0�]��*�6��흙�s!Ra�:EzCL���^@S���qP ��&M>�-xh�s������ى�&L�ŌI.5��ؚĒmj�3 t>�$5p�~�kX��uOL�L�þ��ܣ��c�L�<�H�:j����ܣf��n�6�W�3���n���9��*a�E�4!|v��ªXVz��^~Z7���������� _�!��c���úb�'��%6Vg�b�P�lbO�c&.G���0PY)��%�><�������Z����;���1�6�1�K�~������f�f,�S��J'�&@��0�*S�۪�&�AefdB�������]W���*k�]��V��������C~�����o�Zpܖ�3��fN�!����:Ic|֫�P!=ju��w}P(z]>���]g1�G�x�{������ �����!�9Pjr�=U�]a�3F�¡�����lp.�fp����+�_?�`%.M)��Q�[�&<B^�S�G&7т�����!�u�k�+��T���=�z X�F+��vF�q����D�r���5wEUB-q��g��%�n����8*@�^�.0�&ѐ¥���b��˝B3!�.{��V�=/A�@ׄ���]א)1��"^�56O��s�ڞ>[�NSy�X�a����Ci�,����\�Y�	��+����W�Z�%�%�{}�Xn�en+��P�ֲ�5b��y�t`�%Ydf�N�0��M!X���@�}k9S��i��9$�q�ti$M��b����3��f��D��/r�qSgkH�;�#^��{���9CmG��]N���c9t��r4��a��w��㾤�~�s�>1[�D�s$����s�1M3_X�����e�mB�h ��dŤk�9�2�3/��Vدj����1���#�W�`{U�M5��r����*��x�j`#�^��TX`����%�<y�,�Y|Ac/�_��bÙ�4s��a`۟_eS�(]���yP���y��j��Xp1�x;�U��n���זj�9h�t\g?�ǯvF���VV���)T�j?7|�T��ܕ~C��5�O��!n��~}*v�c�5���9���}UG9��5�����p%ey�^͍d��������P/sT^��2�M���A�����l�z��N#A��
N��'�~Π����h*�$v6�#�?�3��S��B�ո?c� �T�D�%�A~
�"�4�tNd�Q�k�<ׅ�]5yt {O@����8�yi�� �('87oyd?؏U�,�U����yb�X[�dT&��_	���P�]�b��4v�_�<\!ˠ��Ϭi�j'/0�+�����^Tշ��vh"�)f�*EG96��c9�|���b3�	:�Fi��S�@mt�0��C�X#��6�0��Yo�>,	��rz`_.���J��������귙'��4�!f��7<�.�*i\A��*��/�\A���6�~2�ᔵ8�� 6�~��1��/�D�+�W�|�le�/$�k�6N�tQ����89��s�r�4s^�@�&}y���ƺ��!]�3��j6	I�w�����A�S�ͳ%a��׬rn�z�^6d>I�2��QlT�{�N�Wt��)�_��k��[��v�p=(�`����޾X��ޑ'�5��O67��:�$�����aa�.�%by;�X����a�M��t�c�.��l�](�;��5�uN���UI����j'�陖�%w��X�
�K �b+:8%3��1ʉ��^������ ��NE����8��ρ�3�Mz0Ҙ8�ǋT�K���0F&�3�M{ʭ+'8�d��F����������K%�ޤ.S<�M�|j2�k�r�X~:`a��lSj�!�$i|�۹,�s�ԗnv1K�|�=Xi��l����J���Saب����a}��3 ��קf¹��l��J����a�� .~�U6��_��C��ֿ�b�xy���ᬠ+�}��{���m�����8��k��� ��z�ܴ�t*��]����� Q����[E?�k��EA͞r�1�Mv6�Ԓ�ڈ�Vr�4.ӆ�M7�ݗEeg�DK��&y�)E����R�%�֏S@��~\��az�W}�};=x���[@�ZK�d�KP8Ɔ0y���c�Z�v���p��G#��31���cU� i�`:�C�.=�)4�(�*h14��m$Ya�[����c t��|��\o�C5�1²�)L6�u�'�J�L	��4�a��8)���E�!x_��Sue�t)ضd4 i`uP��C�6�aZ)tP�������k�n`�p��Mnu8u���c�j@�ԧ�k��M�W�}�t�JlO�0N�M^W�.�MK6P��{��I[n��#�/%?�qG|j���)h����&Erynx�6s�HXV�����ЕX� ���PT��G��/k��QJla�0Xpu=��Q�D�Ý噾�~������]��Ԑ@�H��µ���wA`��������#�}�O8]�v�7���Kb0�q��&V��(��Y����w���|���Ч�����C�|�c�c�i�Y��j]�?�����������|ƨ���[=e��8q\0�<��V�q�c�M����+:[�s+fS��[r_M
c�B��u}T�E�=��k� ��~3u�bw|�Ʉ �ҧ�>�.:@12�&�Kv��l}	1	� �ȕ�����~GŅ����D�j"�����B`k���^Z�M�e��Z=������[���[1+��������u /�N2������m ���D�#�xk[�+����Ҵ�O�p�~Y�;2g�Y����*O>:�Zc�P R�JK���V��D�/�C�^�����$�xt�:��uw3����8�H;��K���}���'Bm�����,r�{�Ll�R�>��Ds��#�"���@gT����5�,�|�����R�T���nv��p�F>Ǣq�s����ve�Y��7d�<`:��
��>�����}J�,4c�engT]�p�ɦ���6�����Dx��1�jx��!@��!� ��8�[��l�,r�y�� O~��Z�q�3�Χp<Liq���h���gzA�`�D�9_>YaX�F'��]n�J�^�����F�z3E#�՞,�&�0I�߼���"R�T�D�q��)ץp���xA_���#�V�r�����pE�n��I��Ti�E>���*�D�Bp;?}9}�6�� �V�>��v�(Zع]sV�s�m����OI���b@�nF�P%w��/'�|���VAY�����׎�:�l���$��S�@^ߘ�uv���5A�g��lc�m�����)��N�DF���3
�9�����|L��]4Y��V�7M蟶;E.���YnZ��sH�(K�('�h�Xx?z֞�\~�P]>�p�H�Xјó���ӆ&��kd-��]t�\+���E�9�Q��>�8,|��(<�����ȴ�"V_���ƏtfhV�F�16��@�E�)��Е���7��oo�HK���?�%��D��M�c����1��-��3���� +s���:�����k��&zţ~E"��Y���H�\E�blK �X�	?�����L�:^K����D[4�e��� ��=�Nm�|�gI�>[9�Bc��^S=*6���t�W4�o�T�QQ�SI�˅��y4��l�����To�7Ę$��#�[�ˤі�O2/Xj#�f�ة �ƚ�n�����Zë��1UoS]=n���>HS�)�]6Rx��Ș��@��$���x'ʇ��@ �O�pu}����8L4�t���5�gj3U#_�WG����I5�a��'��m���G��ܹ3�f�_��/��O��+$7�)J��:)m�h�����_���>��4��ݩy���,Ǫ8ֽ���V+=�����}��#�Y�e�� ;)�Y�M.L��E&�,�fHa�d��ǯ��>�eBX��'��_��p�r���2Eҫn�^�3��>�7f�S\�i�z:��9�_^m>��u{�v� �y#�������B���"�b:�Z�J�`/�}v��ˤ}8���xC_�PrQ�7�-l��o�]�S���Z7���Cb�杩Nn@�{=���A�k�T�?^���<�c��f�W�%đ�:E���+�1��5,_"��Cru8�uК�����2ҕ� BFg3j��!��5�ؗK5��v�zY�Ľⷹ��
�E��o[]t��^��gf�	 ��|̧�I� �}�xX�9��Q�����-B��M�������JV�e�����ٸ���
�E�0W�xO	�vF�H��t^��9P��uc.@���cH��18�0,�ʅ����E��f+���닮���>;^��5��Vg�*
?_�z[@J����q]a�UE�6���(#�n_��}x����6�)!��P��ڃVKuNK$X�io���{^a�4�u5�3�r~��@t,�	(g�"������ܫMWѠ(�ᙺ{!�H���*��??�� �`'��Z<���['��B):���?�=~߰�;��K�qePKk�~\��BZe3<�[���s83;KH�? hk;zL�_č9��kh.�ri�����3�����é�( �<� �u� ��G�୆T��ܜN����Ɛ��{¡R�KN����T����UO��I0밷�Ǌ)s���f�fj	;�Rⷸ�^>�y����2�>��'��|0l�����ܑ|N��y^���^�&:�ÛUT���F�Ѓ��<���A����2L��i��39��9��Sx:)���ԃ��U��b����[,�Cr��IǱ���B����f�̩��le~�Pᙩ���^+�3��_r9���^w�� ��4�}���'���4夏B�	Q�8;�d���Oѫ�趗�;b��y�f�7��K($�G�1�M��ĳT��jbI��(�!\2���M#��FG)y�t�^^9������p���J,�]�*�a͡��4���·?m6�Ď��sy���a������/�f0���mA_Iη��(��AaP�Pb� ��ϧ�Dp�A�Rk�No'a)e]���K՟x��0A�O�i�������zM&Bu��T?4Bt���-��;!�w��u��0{��L����Xv��.]���A�4j��Nו�����\�r$Kj����/��	�����r!
R���g�V�����:�]�Ԩ�#썝���Ax���x�9|��n�̇?!��@��Ċ�F���To��xa��.`d�r;!���<�U�k�.��;�0�/��唧e���
��T\P����\]��⊸	�{�E��7�����c7] �Izw+f�>��u��~�m����]�2s+)�r�Y���|�6�9g����?>�!���S���x}���Ĩ>uQ|����:d��y�t��̩��r� , "��-D{,/Di���y�>�I�0��+�cI}��r�x6b� H�f�'���bg������aKϤ����CS�*�7!SW8�iL��ބ6�dl��X���K�⽩�z�RiB��_f�ӿ��f�W+��Z�;�����z�c���n?�Q^��<ݓfn�;}I>����m\D,��b��ch�����������.�����#��gx}kz�DGY���3w��p%�P&2�����[���:�V/::o��#1�D=���˿������������l�i@�ߣ�����a���}��ґ[�i��5����i^�1��W�H���^��6�\!��\2ڇ�]�9�޺�]Un�H�i2�va�u�������b	t��Zfc�P����h����޲������/�7�\U	3��I;�����u��<B|�$^Q��&� �y��;�\��X�'�~i�|G`#�o���w`�d%�-�=�s��=E�J��=C����]%�%j������}z~Y5��b���$�S0��l��0�q'm�;���F}Ȗ���~'���_���qŁ�u��x�!��о�R�5HE��܋�v:����[��*i2Y������D�G݆FqОȽ�SC5���=js��g+s�.11��\�!�9�:���,baU�Uqp�L�%���IL�!�)r�=��үY���t����M�y3 f�
�I�������z�p3<��u��X\��R9�%���\*( @�>JRsc��>�#oԜ��0���D!oW�����/�}� �\��ZZc�ۚEڐ�_��T-�������}��m��8E�)H2�h����DpU(���5M��)�6�����M\-=ɖ$�� :�P j�F0tn�Ђ?� ��Gb��z���Q����͂��4�"3s��W�}�ɿ\�%����%uV�W�������gYsi�Y��G{���fNٕJ]O���� ��8�5N����g��I	��5k����2��f�T�'�2��>�(T^��~̶��ƈ���l������	��_��P��a��k�� ��=�	�\�9UÛ�@��q�kFΗ{��F&v�96v��D4a��@u�����C�`K���vҙ��q�t�c�g�O ��5�ɴ��kZ)�<���&	�p����p+�aK_vZ��,�j�юI��\(�wo�9��YrG�8�b�}E�f�`��`e��]mZ�(.K���)���ί�� 0�5��MF�p�Vf�s~J��f� ��!v*�FM��:]h�I��-��a=�1�5/��4��ӣ�R��)�g����cv|���a��	��� 67�6�|�����Z�ɧ{-�s��������K�FH�	��B���;����X78s2<����NX8eȔ���s��s��Vuɦ��D�:b��U�+�d�f�j� ̤m�H�)ާ.���͜k��s��L�宻�,�.��R.u���."��F�o�l*:�H���Կ*#�E"�{�W
����D�ە�ND�f��q�E��;�ʒ�1mR�	8�����=ˌ#�Њc�7ƭ��HL�h_�������]�Aw�}�^�{���i��|X����\����\`�4�! ߐ�nvN��B3�/�������X���p��я_?C������#�3{T�4RT��4�W���80s����%��Z��|M��bR!�G�[�9XG��ź����_Fm�F���d��ŵ,o�)��,e˔�gw6��>e��p�o�8 ��e?=�
����4豝�b_,#xP���h<���:�>M~p���������� ���	e�Rz��g~�e��#o6LY��k�J@R�6�h����/��()X����=Y/�ˑ��v%:]qv� ��@�� 3I�g�D=�t^~P�-Q\�)���JeS�Y�#��d,�HPȀg��j� 1vۂ�}l'm����#r�&�M�R�wp�o�M��_�آ�T�!�ɠΧ�ƝyЕ(e�#޿z*b�!�u%J�wfޓ�}�|pDa�U��|������(v5��j�"����$h��X�ؤi��k���l��qwе�L�[��Ȑg���ג]̎�g%���;��7@ۦ�����2\�ӈx�~�y��y�Cղ�I\�����KY z���?�?�?��}�))I�f�o���v�n�["���i�k:�G��iq���S�M��\�7|����tOp��qV���bs0cNm)�1�I ���K\���m��&:K�`���|����l<�� �Z��խX���U���$��<V�b�m�&S��$*K�O�����ZV�m�%u�'=a?0�/�Mn�j���1�23�ؐos���~���Yl�fR�Vz��0kV�S˫��Q`$6c@>����K�!{~(��l#�!���d�
���CY�8��b(�d�6����dBc���f��a҄�(S@�[Q[�
�i��ϵ����}�߀��lA>�̿��$3U�/O�0}Ά^��}Ms��h<K���G!H��,�=�mš���1�p���0����c")JϷ�0ƛq�<Cn���{p� �f���/}l� &��ԥ�9�ԝ�,��2V�#�vBE��ys�P�
�5�s�tʐ�aY����,W�n	H)J#͖�p�R>U,�ک��I��-G����oQ�v'��)f�0����	� �)�[Z���pZ��u^�YC����a�\�,]�Z)�n+��s0���r��j�������A��jbi��|�j_m�V����h�˱�*�(��.��̌cj�\�	�.��
�>7��=�pz/�l�o�3���a{H��/f��FД��W��;\����	6���	R��Wi�.Q�XM
!�R@�WMg���d�H��h�h�cs�D��5��]�����=ݲ�|�?|������gN�!�c�l�i�`�#��D�eJݦ#"8~���l�AM0�� *�N|W���U����cb9�܃Gr�"I�R�u>��{%�D�v�P�<~�y}��Fm�X`G�Շe��E&Ɵ
���w۰�AS��v�dm2QQ\�Y�\J9��v��
Y��]x�Ǧq�AWߵ�g*����M��F��D�͘�6� ��!���{��9�0���13�4� {Q1Ϻp�4�[� -�6^2W�9Y`�")�W���y=Wo�T̯�S�����&�[�S�jS�R�L��'L_)8U�x|媠��J�i����Dw����U#S��MR�U�85/,���-6��v�Ǡ�ȯ`eYGcgc3�Oi�\�2(�k����?����b��㥏S�X�UpEbE#4�����2���jy"�ڟ,-����j���gk�	�p�0�ڸ쓹P
HK3Q:T��3e..ȼP�(X���W�3I|�9�����ۿՠ�}�3��j�$�5���� 8����ځN8��肎1�̀ �ER���y��>��� lZ���qT\�g��01��m��Y��nd�|(���ed0�\�(�1Q�1�U��Q	��0jN�3�aҠ��`i���s��wg����d��U�9E���_ܶ�L@��!�2���~HI���?���㐣U�*%7�����
J<��x+"��gJ�E��K�Ao��>���dEa�4�ʇ���ou�	䤨7acض@.�oas6�gY�߇�ı7���?�KP	�&�>^���g����Y��B[lEa�'Q�����J�^��j}"�id��"T�͖4�S.	(�э�M�K����l�Ep�gs�:�(ʿ�^�Qݝ�6�� ��W������\�+�EE�6���>H�]��y�F5��m=ߦ�(�)��7.d���WT������S������LU6��w@ ��Ţ1K�1c�8�h^a� -��ɧ�c�Ѐ�p����/?n�b�^�y�X���]i򗲖�.!E�����K�-�,�*#�r=,1��[cYw��l�噝�W3�T�f�n�0d�uG�L6��R�V�5�c�S!�C�Ò�o�6<Wc�L�X�18�m�MOh�53�d�4_�	������|K���2t,�սUMT�Ւ$C�5��֠�<b�1�s�����F2�72��T���ez�4�����bh�onb�E��=�����a����ΧR����,��*�e��E���Փ�>���F�-
�ՋOF~I�(:Nܤ!YE~�ӘNc`5��qI߀��w��-��}�f�-G��/K��L�Oa�?1�H�vc�+.�ڢ�����&d?��xL�pj�L*�lC@h3%�w%+Ē{<����`��b#r�-2�8�ψQx�0�΅�Bf�Hbneh�������9g�؅^�z�H��u�/N �S>�	t&Tp��c����="�P0Q��0�F���W��;M�M����p"�7ݑ�:�)t��z�[>#p7����Y�>�_�,Ldg�C���:��������2�c>U�塑�4�+��QF��L2H}�QN�.�چ8�lr�Љ���zu�$�Gc��h�8�%�vR����gc8�K%���L�Ų�	�/�������+� kb���ui"ǒ�ρ�b6&�Ef�Z(6�ܙ�
��T�$	PHY��IįkY�X �p�2��,E�c�C�F-�*��Y������X�<�ь-Be��&\��UdG�����X5���]�� P-��ة ����,�|ռZA��cR͏����K��}�𐰨ӽW���J���]�e2��IF��
�3���p��t��j��9���N���E�Ʊ�=���+D�D,H.���\�5IR�2��ߌSӇ��R���{��.n��'�c�ێ��9�pq,�]�z��}��A�ݶ0��uIh7h�r�7�ƙ1H~�5����6_:�I��nW��>xqZQ�@  ����E�'���$l��	t4F���q� \�K�6�xp�.��f�]�Ka�K'�>�o1�:���jPR�p}��~����F_��w%��A1RG�T�?�7P;V�ٜ
\KINǲ�O�,!�s��gXa�擴��ĐlUCBvFZ�8��-o�MnB��V����i��D0|�.?X�V�V�Υ�E���$�Sp&���Y��sR�y�~?�2(��=s&��,��h��6�g��+MtPY̭\2�XE�Byj�&��3#{��z��͹To��P�>F0*��_]�;EM[{C��%�����T��~x? {.����XO��.�K������'�S�re\����{���-��a7�%0	*T��b��>!�OI����=W>Z�z�CM��>ҎQ`���(�nZnT�D�=���p��̵�%�x���	Jt�r\;J$X�!���Z�� cs~��k�ҍmk�[rЂ���*��b{%�AB�ˍp�SqeJm��:��%�7��u�ey�n8|:K6F.HL���me)�]Є����E0%>�JM!6j��~�
\����Nh�_�٦ڣ�.(p�c�uG9���G���j��ͦ�FHPMe,؞7�?�P����U5vY��Q��)��C����:�G����ǰ�6��:��S�FI�#8�ϫp�r�9g�7�~I�[��qgF������f
���BsFQMJ��E������^�����xeE'�v����r"�E9ϗ�q1�N�X��g�j������n�LiO���ƿ!n��Tm�;]��r4%�;je��&�ݮY�z�7����
�2|�:O<���b|{ ���Y�U�I%�T�n�E�ןO.�D��� Υ\�"�#)g(ں�汼0���������	�\�s�Y۵*��|ڛ�Vݺ� :��Q������:��pg����+�h��C0?�h���G�
�S��}"���ՙ�^b���n�����(<���I��Q�e3a�O]�B=���*|���eW���C����	����8A�t,r�1W�X�[��ԜiB"�{I�m2�YX���������^��" ���C׺��-���u���]���-{��$S�gA	����XI����T�M�p��/�0+��#A�(�bFi���bC�A���o/!@�I�[YȝK���H�M�/��=��X�R�)�mp�Z>C胤��8����YPanfm�$j���>�|"0XDF���H�w�d��XF@�����!T�������n�Ċ/:���Z��^>r
XXd�c�������>�Ʊǽ���4ú����f��Z�)�釻���߮1�`�(zԁb%��,���tnAx��i�1�}��Gl�
$N��#ȍt����@Â3�QL��l�C�Y;��"Mݓ�z��?.�Vm`������m�����3���ڛwx�9Ra;���������Wdbp�x�׎����օ�l��b��9r_�W:�U�s�vf���|�DɞSP�X�~򖨊�m�]�JCm��x�a#�E`W��������/���'2>P��ߓF3,<غ9=/'��G��[ź���~��P@���&6�5QÊ����\+��UtaDD�*4Af�,,�V�s<dµ�ϡ�r)���uo��@$d]�X��ަ���;�7�cϟ�������tۻ�dd��ƃd�� ol��N�LW�&�����?�[��<
o��f?7o�<�53]����k�6l�?�����\�A�4�P�R����k㜓Zn{��2c��)I.8��;Ԃ�5<�O��T�����o1��R�A �ϵ.*��tY�=	%��&R Ș�,ǌY���/6vnF:�����ȥL
8�
K��_���`(�򙃾Й;9N߁�-�7��R��3|as��������9ky��"9�*9=��
�'�\�F_���t=#�<0�}�xo�T�O����������%�u�|��^��n���Oy����N9���yȅ�fa,Ł �3���4lA�!����� �v5��;^����ݙ��h�=�A(��-{ji�ܫ�r�����Vv���욾X��:����ۨ�V��x�Ν�ԠV^�/�wE����D@�z�-Ĳ'"@/JS��dc
u�,��j�,�#�@)H!�V
C̤֑�zx���g0����IM���T�`n7fW�I͡�s� toJв�j��O`E<]����r؇�mm��u��9���eO��_��1Z��.�W�|~]�>5�	%{ٛ>ZO��~s�;N�G�+���HK �Fq�?bh.TtBةu�-6j�6���6�UJ������R
ƏM�/���A�}��>3��C)d=����7�������bk��WL�����1oْ��]����$0� �5��SGԾ�C-�c�_���(�@1ч� e�/�3�;
V��%�B߭�����w彸�_�z��=��E'�M����z���i�L&1�;{��.���Qk��5,�#yQ����eV�����(�[UjWu�1�sergGJ8?� 7Ҹ���ֿI(83j�Z/{�ϲ5���?�'��z��p����,.wYEհZ�p)���r���!��R�R�u�rr���T7�HV�rv�cO�Z[/j9tZ(�\��v���_�uy74�_C�
ƺ{K�7S��͸!L�
L�x�p�q�q`v.�^M��^���d����T�������D �/��G-�Sj1�-SE�'E4|��J�4�c7�'&���N�ⷲL�~���9�E^��v�rOӰ�N��y�]}� ��6D8���{ebf=���U��ɦ�%�UP� �.���x��IFEE -�]_O_�    ���q�  ��������g�    YZ