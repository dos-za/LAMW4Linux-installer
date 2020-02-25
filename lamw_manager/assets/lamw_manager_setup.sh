#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1606845145"
MD5="3084ba8eb7e3027326e51c0df8220f90"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20436"
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
	echo Date of packaging: Tue Feb 25 01:25:25 -03 2020
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
�7zXZ  �ִF !   �X���O�] �}��JF���.���_j��`-\,��zj�܅�/��|�s�#�1�7��;�s��B��M��������ٞ�!����c��^"��+{ٶ���[���0_������'��H�>�ا�j�ff����8T^�L��������^���9�\��"�+OZv�2e����+ƈ\�2q��e�{z�/ڲ;�O��q�"�2�C D���:��?�)���Jl�F�S�+EAn�47>�֓�.�n��^N >Rn��`C-�Xwk�67�a\lu�1Kgs�A�S&b8��d`H�z�8*�VnH7Q��W{�*�m\'f @�Ǵ.tՀ�!B7��W��jƕ'ǆ�wē�+���fQ��祟�9vm�Xx+jN�� ��O�LK ��Wӓ)ҁ��Qz6��.�}G�T��DD�� *R�b�s� z�@{a�~���j�f�5>?�9+-��V���ŧS,pH��Q�+����r-�T��EB&�Sa%�����=�؇\Zqjq���oj���)�{�*�'�N9E���o���.@h6�����B�F�ya�?���0�y�u������ٕ�����m���]��+W�2#E(W35��:�cov0kMY'있�RL��?����*��R{�9�
q���I�/1 �%:��RFz#�$mpMHU�����c���|Tu��
��7�7��-#Rd{����M@?������4�U��?�㳝V"M�=�f�L��4Z(_��9����.�>�Vb�Q!l�c=�߸��iE{��l5�9��š���X�V
��\*��!R��%Џ���_�� ����.9dw$Zq��!���É#�~�'Q]�D�
Y��z�oFU����)D�����n(���h�<�ڴ�3�<��6���A�ј?9t~�O�1�b$hO{T�� ڐ��������>�2�˃}8�k�i�q�x!���.�e�=����`�P�[��m���p�p�j.�!s��z��g��$X2� ��P�\����m�>���
���"�ߵ(�2�����w�X�mY2��ܧ�l�ѡ���Ӿ6MI�'4kb����}�>��Q�@�a�At�'����X8Gt�m~�D�O��k����uL��+�A�_�.�兽`2q.�e��pB�a�zA��8��$��OFr����63��S~�ǤS��x�`UO����UT�?��0����xs�:O~��V,�h�'M���$j
U�1b��c���g"�p�����:�J�%#�5T���������؈������h�ġ��E˽%�8�-� �����ͅ�i�>�P ����S��w�I��о��2[������ݘd�ŬY�n@r��od���׿N��.Q���v^����x:$K@V>\�!�T8�:t#�ޗ�~���>�P���ӵ6�M�ݑ�w��/=��+�5ge���Z��Cb�#	i�.��dP��+�3���k^�1ë\ �zptd�%�!�VH�`pu2�_;ā�6�߾d����#�Ӥ�*lP�,onbby�:Ń<q�c����t�yt���6��xy]�#dw��ݭ���xz4�12�_w�k�Zs�>��^� �S�4�h�DW_�蘋���F,��Cy#7<����d�$�q���a)K[[�
ۀ�(�\D�g��$&f�^�D&��[��x:�������ݵJ? N�v?�%H��ŞE����|�K�8P�d���Z-�3�� ��/7��
.���sk9;`�#��W��
'7x~�eA��=�� N��o[�.k]�f�]�%e2q�&e��W�E������
�Ӊ&���o$��Џ��'XH�.���+Y���f��%��@fs!\�K�1�G��[���&H~	���C�x�0?O��"��VR]��j5IR��Y6�k���ȟ�Y^X��&HkG�D��*�^zw��)����¯���(1��+[bY<�De?���8$�5���V��9�]V
�dJP�.�nz�H���l�j%SVI�ݼ<I�ő�����n�5�Z9���1��RjGu�ͬ�]{A��J7^^�ݣ�S_���c ���)yO�i(��#η���g?��D�����������A�A��!��K*k��ac7�����n�62�o�� ����N+���d���I����Uȏ�b�,�٪X��)��Жd$&�w[��&q�ذ�`ey1sI�xtk�h�j����}��#���T��|~\�0������~r���I1X��
ke���uя�=5�d���m��n�5�Q�)�5�e\����7QJ5���*�L��:1�X��u+�����k"cVu��Il)P��FQ�>�D�ВS>7�I�(i@`�x4����ie"ޑ��:��-8�w��bE@�8�����GV����lf���������ϱ)<�Y�z��=�Z\����EO�D�fi�u�M�����`V,�y���ڲ"���;��dvq���|�m��&`P��kVq���7��^=[���؏���,r�]����Q8�|�Br@f���X�7�M�� �婩��^<(+)J��Gu%�p)x�C�!΢�<�+�Ѝw����|��VO+������dt1�E�(܎�lA�M���:�ܼ\����M�K%�z��GId@��m,���79z�X~��b�'Ҁ�e�y�J��e���%��@J�l6&��E�׵fS]��S�S�p��27�˯���N ���#!�@{2e���J	ڹT���Q)V�7�3�]�ҏT��<X��� ����g��3�Do?%=���"ZL@.�c���j$W5>	�vd��̸��\�x�I�[� >P�zz}Ď�뺉�py;4-=�U��l�����;k��W��e͌��4�WvAE�>�G�빁�����$C��ȹ@��5��ڳ��lS�����Ԗ	�z� A��w/:!	�hbN���V�[�پ��yV�٧�%��FR^ �k:����
�y0]�����H�V�f�栍�o<� \�Kz�*�ұ�
x��?[ϰH�M�Yg�2ߩ�w䡬~���j4r��/|4<��G�H:��`�t����$��5��5�Quߦ�0�b�+���JD����94��.Fƥ�D��?���ϩ��k(XN*�h
=�?
�gFNF1��UR�k�Ͼ]�"��Л��^��H�#c�B�Ab��9/6%^W����f� �7x.�I�������N��)�d���l�#_r���͹~�P8��$�����"]�k�|Iϴh���|�f��m�NV�s���"R>8�$�ˀ��`r�]I�6�	�o�q�_��2RV)���u߈�<�B��x�	��u���(��??T��S��g'���ῼ�H�A���Rt�"�l�c�{K�X���l�&u�j�k���S<b�"um�$��0_PU?`��/>F�]ue�o������i[]�`����NX�_��G��f)7��4�WY[�� �0D�?�y�9�	Ff^x���=���\}��${��r�eI�k�����-����ٳe	Z1u�t<��-L�z���~���'|���2��d���G��նz������r�F�\W�=�Ė��~�<;�I��X���6�s�S�܂�=ɸ�����rE2!��
 �V�� ��[-�"9����r<G�䄇p9W'Ո�l�$~�M�V>��sU#�?pJ#�k�a1��ߋEo�)�r-�I��LE��,z�5�5^��Wɜa�uu�!���s+����x=�� \*9�j2���P�ȳ�)bC�c�_�%�幞q�Q)�8V��ޥ�Δյ��*z� 
��	�rww�y��/���\�Ov�U�0����Y:��_4�y�3gԼ��]�J������T��g�zwU>{�;_�!T��M��w:�ц�)t��'$<d׮An%shl��V�hN��/w�t���D̴͐s���	'��u"rܶ�!N+�������&�A��O���G|��L�C�b�06Zo���}�_���łQ"zg��9���93��*��F���:,�l?�'��%*�LOR��s��$%!d��8F���2��{Lΰ�6@��w � ��v��Ivke���2�O\mhW�0$f�
7����?��cgH_�rhe�1��xE�4�luF�-�4ɔ|�T�H�<h�?@�'�̮yFp&�~����wy]�~53��u{Kw�-��$�ƚﮦ��}l�O�=0Z�z��F�O�|/g��L�-؊�"k�׼���r ��o�[�����C�����7
8*��0
r5����)�cM�v��F-��l���+u���.i����*� q�Ne*[+݉�ݲQ~͏aPg'u���-6q{�h *_��S�da��~F��r�T�w+�xIU�\N}S`~�lZL�o#�˭�����O��֗��u���X��!x~e�4�;h��o�Y'Ƈ�����c�(B',H�`狍EN��\���gp��ws^}���TO.� N�(X����B䝦�fOX�h�ȱ�Gv~�_Vv���I�)�%�;ֺ):\Iz���6��£�J���붅����#�Z�D����y����V��\���k�3U���ƪ:|�X�cOi�|�}�e�:P?�Q���c���Isp���w��w�[�'᧽%�S6��ܔ�(OW7�)	l�.�����z�D~�㟢�"'	���s�R 9���Nd���<�e��f<���3r�0?�gǔ`��c��S�j
wDC=�ٍUK/��].���9��ub�O�!:D~�
S
�6�QK���2N�b��ж����`I���=z̽�}���a�CA�̵5�����y��t5��S�Z%�;��[�b��$����Ȝ� D����^�UBYj���0H�u[db�������3�H8dO�D��{w���+��O�Ʀ�A�w)aEZg�G�n�?�2�o��+�(N�ߤ, u�jg	�=�N�6g��d���L��a�F�Ǌ㱟&/9���Df����J�U=Í���5l����7���Z^�s��E��(./�jٓ~���u�Kz���@K�EY�Dsz�@����E��	u1=�C�s�%��B��e�c:T�&��t!3�Z�M;VUo�����rtA��|Z!��	�-��d�<��,�����/�g���}���ܬ���x�F+�X��Y������g��=.4���X�-�#p�+R�t����XzmV@�];GZJ��i*�В�����1�f��s~q|��X*��AҬjSL�&��������eK�RLᲜ�[n�����Y��!挟�cۍ;����$l�#�d���P��ʂ1��q�;��g�W	Br�[8���>2y.m�ə������������m�t[ğ$�F�_s�~[B���F�9l}�aF��I�ط4>$}ʢ7���w��K��������C;��Og-����T�`���3�b�9`~ţ�������u$�G
�!w��-����X���$7�L�� (<�?� ^Z*�xlj��8ӝ!�b��2̦��l0E��w�~҅���a��Q�!�p�~���)>�ʃP�ӝ�m�L���%z�4�S|$�y��R�������t��O/=e���`���{���%-@�Iw��k�A�Q��fJ�b{Q�r;| �1�x�؃~�t85%�u���^&�0g�q��9�+LO�?�|V�B�h���ߌ��aޡ�j�h�C�+z��F-���˽��V�Ju��	�A�p�mc�=�&X5�̖��Yr��TZ`����=�j�=@�K�lQX��D��
�F&�	U(�0P�:�m�%c��aMS����@j�9G�PpY����̖DO=�(�I H�.4�m��q��l�W�҄z�_�Y6��.��F
�?���_��؀\�@��e�=�{[Y��$����`j�,+��� �n��2�٨�dS�*U��J>�c���"�",a������!P}֘m�>#/����M���������s�V��b<�kyJ��d
��\���23��`X���[�؊��̊05��k�T�ߕ�ZjS�=.[��y&ǯ/���k��S=Ŵ�����d�b�����̻��gM��T��T����u�kV��q��D`�d����&Lu#F7�O���S*.�U���m�-|��`�Z�0jhPe?m�b���D��n��� �H�o��+9����n��K�O�n�8G���越�����Q�+H��A���%s�[I��1ք� �ǿ�7�}6�T�ꮖg�)�l$�>�/˻�q<����6\Ib�q]��HOB�$�_��������W��&�4>Ϗ����X�_�K��M���Hn�� �b��"3vU�3�ݦdg���=����;b�hާ�u�F�O>2 �BΆZ*���ܗ��{��s�f�.�K���8�le�-e�#��?n��~�^<$L��̳ {�_���]�~��	�;'� sQ�ߖ[Ǜ���y���?3��Ѻ(<]�f7�"���
�6�0^�=2����&=�K�]����S���h�
U���C';���y�&��kwH�����:>X��c	>�2�.V9�M
TR�
�T�\*Kp'� ��d�������j��-n��?e��R�@{{WN���N}X�a���&���j�/�l-�c��4e
@�ҷSmk�j����s�٢�r��Q���{�Z���)o�?�0K��Q*�v Xg�
椌|ף�(�P�د�)X��ӭ �$�}'Dt�b�X,��k�͋1�`Vf��9�a����\Ck�-^�t�:�>d�&�w_��]L�
̰)�u�W��{=��y�D�� ��U�S�Y����[�bL!�^�ʈxM��|h��)�a{5s�C��_�9���f`��{�@�t/H�=sM7����n���8)O�eS��&!�g����"Z~O��G�A�7���r�~2|'
E.j3��?�c����l�����l	�����YH�5X�C�嵬A%�7�^Y[;�{��Y!�b&y���s+�M܏��EO�J�%ii��"!ȭ�b�nf���W��zMI3��\r���T�{��6+����ޤ�y��B4���3�b��;*م_�3C�h��@��ZGb�/��^ǵ@��!Kc<�wdF���i��	6A	�	eh<T9����/0��.�9v#���X�5w�\WqB
;�[�	v�*�UHM��D��0�q�|�����o}���<׳���~�)J�!�ր��iF��J�������o�(��>e�J�a[���`(F1���3T�3�F����a���dJ�X]�{�l��A����L0_�-�f�6��5��lK���]�%���y$:��~t!ߌ:�|X��@\��l]j�=:��RvJ}D!f*�!�
�@��z�y+�m�u�_"W���0j0Էs�P\	�Q�����9��s��-V{�%se`3�!�<���}��G����*���?f�K{������G~�����N�x:�3��PͰ�߰%�R�Q���完��q���p|�@γ�W��ǥ�vǰy~=m��Op�t�f�b����s~�}bk��#��|q�=�_�4��Ws�\�YE2+'+��r[./K�x��5K��[0������qJ�A��/��z:-}��e�P{�*u����4~�_��h�9&��OӃ!g��M�5 ��
�|C�҅s�'�~ԋB�%���Ӯt8�]D��b�^��_��TL��i��p\����h�1c�\��l�',֚pp��:B}���^��p���e��3��Jܛ7�>	���k�$��Ո��>�(�T��_=k�ףtڴ��V�Ćq�E�aT �Em���\�総���r�'���4~ÁSnD�/��X�K�8A�"��b�Eo2�巍fU%}I�^�����ZaV5 �k��"�Af�{��H�\��Q}3�P�{e��7���ϑ�E�����"�wɥo�e��5�x�\�h��8ɉڟ_�d�t8%����|�<�ٯ�˵q?�Gf�� XPl1&N�|�5{]c����+M���d+W����ևPq������䖭��gKv�|�ɩ
���@2��;�o�㷠F�Y=��oG?H�x���=E�QA��J�A�yҠ$�P�!�M��:�0N��FޓXS���/���ڪ�X�랖�8^��d�TY�vY[ ��������vB�J�`��sG�e�Y�`�y6�l'���g!��{�(g,}�R�C�m8�-y��b�?6`Fd�̬<$^bg
��FE���nܶ�p��ʖ^�Of&T84ZX�-v�$�Ϳ0����z0J Tk�*��h��pl�aD�g}��T��h��)F�o=�,�l7+@�	�� �0@M�����X؀)�����p��ֲ�����<C�y�
��;�#P���v�57��?��Δ�Ԣ؆�&�s��q���MV�)����j�W8jTb)�A;�d�l�	X��fq#r)d�E��9M�kҐl[y��;��-��1��ʹ�d��^#���Z[F.8�f0 "��B�ܞjO����H��d�$��e��*RC�'�rJ�htr�~u.���=��f?�4�f��/���"S�:c|�f^A��ṯ�A="�w��x���V���`!�F��+�UzL������
G���b��j����!�oU.$��ʑ %���/�6:in�Ȅ�<�^�#��޸%j�=F�K�[|+
�6�ŧ6Z[�������n����{�9f��|^hS����*�W� ���� ���ꉞ�P����� �7��9y�ن��A�f;����k:���Mm��"x��ĽXo���w�2Ϙ���2@��չD~ū�"�a%�a^�m�v��6�P���B�U>ݳ%����r����w�9����X9$s��|R���Å?(q1'�>�)�z竛���2�3��)�_�Xf�������29I�[`���W��^dk39�/x��M\J�җ����x32}cx�!ۙ��R]�fp�U���姷��[�Ħ���U\�]'svL�TH��7�"kGN�=�F&`�A�?��֕��,��W�r���ی�X��-�]!δ�l��J�R�Y>����ºhȭ�C�x�/�M�d�޲���孟=\�|�#p N`����ڭ�\�NA_�g�e�7�	�r�F!�ߓs7�֙�(�/CtѨ=B��x8H�w�0_�,7F��B�����6�Ě�6��P�I�5=��o���>Pp G$��B�im��<��	���v��N���"0��iI܈Á�ݷ܇A�����=b�8J�K�x���ٕzf�`h��ų�#q"es�R�AS�ɹ-�xDѼJ��l~�C��@�-��r����Zi� ;(w�)BF�oYϥGږ婶5��K5��,�j�F�D�#���;	d��!X<���'FZy��%����� Y?X�ģ_�ms�Cf�&n<��OЁ�>�� (��Lc_o #�Gp1Tf�j�S���zk�S�e~�@�vMT�uj���<�	�V���%�3<Q�h�As���OAŃƴ���WPn]�6/���OMݮ��^����e'N��g�6�W\N����̍:��b+��E�iN��b�S�����-G{�_����b[�,^w��{ ��Ej^/����	�t��-���	��'���9�c)�K��^�*�>�:�b�K�5队n�ϰ�Y�� �[TY?ŕ!��@vܪM�&Pǐ�zp�l���h���T�}e4C5Kv��#%�6ٴ�����஝�߯pXA��tE�4�E �2�xN|0�M[
]���mAF��������ET ۢ�H!!�ؕ��>�H�7�K�ׂg��ۺd��{���%-؏:h�f�iɁt���"��ú���j����-ktJ��5ˆDT*�^�d�X�t�mL}S���W�`�{�١p.�jI�>���x���$@��<B�[�@Ĵ�W�?�A��tp#H���O�cDX��Y�z�hvc9�˺�� �����F� �p{��4	����9�i�oq�W�9�C�I���uLȫ��ln�q�:����A��?�0Q���&���f�����'@��,\3��;Тu%Xb���qd�}zA_+~�e����	����]��9A�쭶�4�(C����cj��y�&-_cV�QC�3x�5�����Yb��	KF���Cn�i�	��[%�S�/[;���gm�K�JU��bc���AAF4n�0g(���G8�	S]N�q���՝��B�����q�]Y���m&o�ܱ�\����ک���A������
N4����*4k;;`܋ j��X�6Ш�+�E/ќ�ӏ _�v�2/��P"1= �{�"r��F��G��@�����f��_S�˾ROex���p1����Mj�#�-1���v_-���6hy3�1���v��I���ǀ	���hRS��%R�'V͟�l�V����߭��5��ʇQ��#4���� )��ޟ�f��p�Yh���-�%���q��:��@�쪟��x��V%;��~AR���9��kS��J/�H���� �n��;�\Gx?��#�Xy��@���qEX�>F�fV��Qb +�Y��4�;ϕz6IIګ��	�E�0�>��Ɔ���ꕰH�����R�+l�β`�m�+�5�.����M���w����u@k�H*\[�i��Ӡ��d�3�a\��/vV[e�LO��~Y��B9=6�m�2m�J�
�Э��@A���P�Q�9 �;�I�_�{���ͣ�	f?e�Zv�����I��VV��Sf(�ٜ.��|9�b�����j詷���H�bf�5g�{}i�_G��i�u0"��{@�a�1���㎉��W�
� �Z4�Ϥ�c�Dxj�S!��ꏲc�3	렭CYf�7[F_��܉֎�����R����ͮu���v Oڐ�|.?4"B��=��e��|c� ��y.','�YW>�8F;�vNM�C!e�Z�I�05����=�A�����:m崺�-��>B�5p��R��rgf������;�zd����1"���k,�Bo�lt'=���"�����rY�C����8��Z��N�*�^�=���Ǌ�\�Q,�q>�c^�m?�$0s1j(ο�U��_���|�"+s��T΋������%5������'t�?Ӥ
������G���B�7���8�"�J����6���W���C���ci�X]���5E��cG?Q�JR�C��`���E���\V��FX�=�f��P��M֞���t�:����Kۀ}�u�6%jٶ��`iZ[����@����h�]��[��Kˍ��9_��$��4�l���� א$;��j�b:�)`;עLe�4��;��/S�#'���@�\� @�O�m�μ4{ƌ]�i��i�~nn���zTRϥ�G��E}�kY˒�I�uDø�SL��0��@��'J�p��J� �+��q�@iu~-zo�������W���â���'bn)��g�р�C�R�[��
�h�bעO�-�_�
�H؍2����9�ߝ�
*-��s�*ny�Q fKF�����[ �~���H.�n�F��:�.����C���Z "p�ʣ�t*�+z+M'�������~}2��X�O������p�����-�b+��&n*<L�z�٭�-��2V�?����G*K����#�[��黼z�4�<�������5��uy���vl��m������|ʛ]�(�*���ͨ5;�3 @��J��~<�Z��I�rȌU���_����*�Q�m9V���^�) ֲ�6�+}�� \tL���(��L�'��a�u��5��#����C�?!���}�8��r���pf��z��>� \�����%�zC� I�ey!Bŕ<}%�>�XNe�������)��0O���2(�XTV����e�˖��{.��e�v���p�_�<G����m]�ayl��
Bm��m�"G��:9�661��SRi�/�6. �d�n/�T�^.� T�wX	Q1��*^��1���r��=ԛϽf�sHQL��k��x�n���WL ��]��Unx.h��$3WF2�jjV��IT�I��`$�>�U���|;A��z�#w����%q<�A%*�z�-N9�2<{�����hjg��`��{�RM�y�AX�܆�>��?_���*N�/���������B=�&(��m3nP�(�[�Cf���2�H�,�e�[��M�
�֡�'��ܷ'x�3��.���xm��'���*�Z�� v�u�4*R4SY,v׹>�Lo�eߺ0T¢9s:�����h��M�!'|oB*:=��I�/%�W�y��y?�fڦ�6j!Ƚ+&��[*�SW�������gU����R��qˎ�υi~�WW�-�u�oD1��L��?i4��2���c�����:"j�r�[&5��VQ� BI�@<{剞F��q>x�l�$�	�}��d ��$�Mp�� 8�R�B��n,G�K�)�;7j�m�ߞ�A7ؒF�˭0�f��/YS��R���"Z�+�� ���TWQP�7����ƥn�B�#L��,��1�%s�	rOX�+e�yH�u�
�kJ󈠚�)���c&X����k�ڗ�0���V���0�tŴB�w���6�E���mI��	���d��7r�uM_�������z��=��⇕�M>�1u��S��c�"o�#�J9���ʷ��������0��j1qDk7��}'��%��\F%���0�\�9ݦ�$������.W�JY뭔
*Z�ESpn��� Uj�q���S���/��D�|UTE]����"�zG���ϖp(6r�,��5b�^�:��0�YY�i�7!^�&�_��N�����q��x��M�S�zw�Z3!,5�|ɹޟXh�Z&�?e�2����gC����PYr<L$��(g���3g�j��]�,� �����B�)JR{"A(�(�H��n�Fa2p!����|E�d�����4��j�������&d��V��z�hk �[N�����E�BCۇZR5�|`Z$=�7���yYK�'�t��"s�ZΚ�P��K!*�>:��|4�ͻ�0��O/B;)��� �/\��J�z�U�Y���"���(PX�E1�	y��ٷ�j�܂��Y��K��1��'�r����|�lT���	�o^��wׂ�����zzhV��]���Z
fC�nM�p��Q�b�`8oH��q��_���t5{��Վ�ZA��9�S�M[]�֭��`~Cӛ5_
/Q)�����"�g���3���%����tx�nB�B�0g�n���Js���f�*3:��@BXpeƽ�C��v��<�g��ܚ�$� �&�uLIrm�*�P��Ĩ������ǥy.��U�������JK������ӵ�����:�-E�~��t��釺���8��|�+�^�<�z��~��^V�ooT�t�e�A�Z��_�)!�k�x�"�k��X,8|Hd�)�|&����f!#�'.��2���س��e効ڼ�!?���|nH�!��Q�ęf�������]l� @(�`5DZb|��"�K?���YzS��΋�����������4T���~���慞���G�%4IU��jBv8Rl���s^�y�W�C����fQ'A��NՄG&yV���8�Ɣ�gX4~?��*Ϭoޒ5��%KV��lf���0l.���O��-����DD�up?�bߍ�̟�ʊ��<��?l?Sd�EQ�~Ǡ���+��I����!��}_�L��JO�&�_�p�jX@`���G�gh��^q<o��<��>�z%��Xƌ�:���2��a��ŏ:�#�
윯�Ŵ�U#���T"7��5"'����~�8ܽ�i��f*�/f�j��9{�<͹^s�zi���s����Ը?ٛt�M��N�ጹ6��1!ۺYvXn�>��}&c���X�0��*(�����>��qLд����ͦ�EAJ�-����n�y"i�vYN���R��`~����<�8�z%�z�>�뷉
y^�~
9�<QC���
N^ڵ\��	���9��h�����a��ш�����؝�9˳{���tn���Th��g9��b?�����c��x��9�v�<-3{���B4�<��`�2�j)������m���Қ#R4�l���77����.�f7P�k�_:os/l+y�C��<���Ov�� &��+�WG
Ϊ�Ǧ��Ce.�^V�o��t� M=S�
����&�w]��}{��rm�~�)��}��L	�H�I*f���r+1{�2@�)�"��7Zi)ҧ�CЫ��TQ��J��^(1����n�3�����F�=%6���������p��L����Vg	��x�#^��g%#��R6�3�������I����v��M����S͒����o��ZN�7�?�L_��6'N�[�z�&�I�8�� L�n�!�sX�y�!.��6~��{�DS^}�7Y�ձ�q\� ���;ؘ��)�F��Y2]h��#��	1�Y�L�l����,}03�o�bi[��h
����=�=��A�2J���C1�Հ�i�����y�d��5���t�f!g9k�vӜ .��|��7��ҹ�~*��`�{�����c'p��l��6j*8C};�yy�b�ȉFbԁ(���{P���9*�R�N�N��\���VJ�	��;?�x��[����[������r��������"����htE�SK�/�0C���cq���Y��E1���)�����9D�!R�]�i�H���Z�)��?��5�+�ܮ�8Dm9�֟n��q+E�5M�'����%�G���WU�̟f�\����'�+ �{~�4$D�<א��@���jS�)�~���J�٦Ɩ{׏���n:|7vx��2}N���4�ds���j�[����*^@�ݮaZHpHϢ`s%󚁽/���y{7��?��/HM��kf1�������Ê�A�6�f8��-�=��W��W�=sۄ:*�˷�A���;�z�~��@S�;'����1��ekR�ˈ����AI�W5{	���qޛ6���1^�f�|�vk���72<�b�K��bO9ƥ��'4]��)ŏ&t��HM���K�/&�����9*���)�m����On?��� �,�Nn�+���]����>
���}"8�����ImK��k��q�|>i�U{��*�G*�b���\�f��lJ��,A҇~���x�Kf��'�ij�\�y� /q��pO	�گ�ᐨkL*>��E�����b��7�i�<�� ����5���V^�3B��V;T�+
/�;�t�F6�Fs�'�X�{�gV8/��0�#)8V����oX�!��gz� �i瘺ު���n�3�JRO�tT�f�aE�3��;�P���Ӿ�y��+Y�3��1(Ԋ#3�[n�%��h�>�NWb 뻸<ک�45���r� h���w��Xq'hR B�5|�ʍ�9őː�iQ����>���\B92e��"�#�@!��|��ޡ�N(�D�adfz��oXF��g��F�݅l���U.2�{�J�}x)��Tx�VNi��.<	2���v����	��H�@�u�wRߠŎ62�z �	RJ���/x�iʻAZ��ڢ���RW��e�O�����P���i5?��냜��<ʑ}X㝔�R��M'0WK�r �>ד��N`�������Z�W �H_�� 4);��,}/�8CxѮ��Λ3N���O��<��_)������`y�O=�]� �ZO�9���ż�$H������y�)<T�=�M#_�z��b�Dw0'Wfm8=Ԭ=�s��t�0D�V�� 	",����cT�OE�Τ�T����L�׆�;^�t���$�ۜb`�߷N�F�O?�~�Cϥ�0�rX��[�Ԛ�U'm$�b{�"\���]!������8�$s+����`?�']�O+<-E� �x^Cs��{��a�聉�_NW����B
�Z�^_W#�p�iJ�����lB����@cOn���;�b[)���|��r�ː{9�GuJj���M_U?�R��#��NN�i�>,�ϚW< 7~�O�4� p�ЫP��M���#;�k�U���Ϗ)g&_X���5H��x#:��/7�� ��g#�;;�Ǘ�-zh#��u/Q0���2��0
U�Vw������T�s��>W��x<��$��2��M��ь����ox+f���	8�ϝ�yO6'����I�߫�;ϱ��u��h֨��� V������m��ך�W�M)6TTX�.��br�}ر��0+!n(P�Kg4�K&��|>^-m��(��߃��F�`}rC+Q�Q	�c��;�:�.��ޚ�95�M+�*�ݭe���9�3�s>�'��'?H�'��	��-���d^H?kHv��և��(�Pho0�z_����x�J{���Ӎ�a2\�V�h}�Wگx1h�'�$%[�+οi�-=b��O�����6_��{��mͦ�.G�R̪�C"�ȗ�<�GGYy7�0|8���qI��1�"��#ǥW#�����F\X�X	:��Àq��J���2%���hA N<�X'��)��к.	 X0�멋�R�@��f�����=����9������1 0yK�#:ӿ*Z��v���J�+��2��c� M*&f;�7���)=�U<����*��b�"�݂�܅�M�k�H�U��#�F���PcmJ�8��Q�]�H�6�q����c���H����J�rC���~�g��{\���To��JA�+����<�Y�F�H�0���N������w�	.�+��n��j�+�_�d#.�q\�[�f�ݮǻ���D:�����[g9����p�R�Ty�E��U���h~7�N�D�g�24��e��c8sȼL�9ܗ7�^jٙr߮����5�T����M��U�|q9�j��n{�:�r�;�d�:�6�� ߍNx�9�͹o�ց.������_.D�껂M�T!��J�"���BK�_~(u��'��E�������?oA����c�׵	�`L�Ѝy�z�-���e'飰�j&T�9׮�������M6�{����ף-Bѯ�Օ� hp ޿���E�僨a&�l�E$�Eӥ���+��;��U����hw�t�'�K�#�V"�p����������H�;Ś�]��C�	d(��2-v�n(]N��h/R-��F��Q5�p��������жMRj��a�!N3c!�VX*��QL��whxni� &�s~�N[C��'vH���:=GӜ7��������@���dr�6*o�{8����m}�����;���zo8in�	�S*�������K�C���v����k� ��}��Nc_�0�'�/��;����*�:˨"^��)%+�p�\�	z���٥ɾh�9��'��H6���_���A9\��B��G�c:�}�iN��i����tW7p�,���:�$�Z�	1|C��� ��Z(oSs� {��%�1X��
�|yה��j͌���í��H�(�
1�#s2�@��e�olC��ѥT㠜�D��&�E��yH���
*5t��RB�Π;<Fy�G�~]\�A���<�5�}����5�_�t bGLZ�RA���`�*�U���u�\�,7�(!�+-o'
�����<nZ�Nu_��bw���k��(�c��'����g�տ�� �Z\�`�SI���Xޮ=P���(�vU	�1��1'YV�ԯ��X@6�w��D2��Q�A�%��1A\�k@��C�ce�;��9�n5�#��)�%8�P��膅�?"v�EU<�&7�1����`%�68�q~Q�i}��0���w%��j�����~��m�ۻ�(�z��c�%l ���v��;�r����z{0�B����?�n#�:v�M`p���i�e�'X�銥�0��N�NO�W����YU1���}B�\�QЫ{4�j�����2>��w��j�s4����c�ƿ;�-6PE�3���c��=����XM����_@P�8!���/yz�5pM)��tW2D�1��M|�i����m̼��=*e�]��y)��t`�,/�T��u�k4@O���;V��B�g3���ñ����%&aL�UA_�C(.�Y���1���D���|����?�]N1C�]�o6�[N��8����l�J��[��~Ek��UzC 15W��f,�ސ�!w^��jB�U�*��(��"���g�N$Ġi��kW.�W�޻ǓBB^o,8f�����U(2
��F�nb�M���~y�+	J�a^�XL����8�wR�� �����5����~G�+�+��S*�e�AIX�/��,��Y�Zk�yǛ��~����o�}�<-3�?[ (H��VI��j퍍-[�n�{�a_�a������q� ����OU_�|��HC�@G���./��k�¶X�,#ly�VZRS)I=JBPO���?��.���px����a��a��k#�� Z ̈���2�[�P{q�XpMr���&�`z=>���/ƙy��`�W�'����65���0�xP�Y����B�q��ٻ>G��,ps���c;�u���-֖�����1j�e��`Aӳ��L�[��j�"+� 	��\L;4�liE�q��T��,w	y��	�B�.��ߤ9�[�=r�:�d�98(���r��	���L.�Yna@v�W=��I����K#���Kt����$��ꪪ�م�J�D�,M�XT!�vUsV)��WeZ2�ꍑ��v|��?��"d9:ˮ|��u�������޸ VФo�+-}�.	9�>�w-Y+d�����a��e����\�� �[�S�N��ߟV�4]�Ưڬ|�3=�D��aNKH����w�71j�e�rw�'���چ(��ҔmI�U�"��+�ҧe`��.Ɩ5�G��ve-u-ul��؆Q�C��)�����z��Y�9?�}v���Wd�x?B=
�I����R4��:����!�ga�_��k.$$`1�g�O2�Y��6�D<Rc� .�Tv,����:NB�Q�( �]�Ӿ�t����V�t�gL{/N�K��0����|L�	6i���L��BK�P�ց!�����i��`�"�CR\��̠��,�x�F�-:�tHT��˲�yfԞ�gY��F���nM珇R�����D*d��XI����8��4��B,���q�_�([�Ұ�8dwE����R�MԶ�����i$'���8��RC�k�x�e�LG��Y���I��:��[c���]~]:щ1}�L��X��By1�?�?/OH@#����l�ฤ�@�Dm����ԃ���ǩP}��i�������	��<�N��⛙K� ��M�������)�/���)��|�e$��IZ�3m�6�ax稐.ObF5���H����@c׋�
!�k�̑�L�Կ6u�����G��؇h�0p1���CZ")��O��-���17�Otu������}||���d�=p���_��#�br�W�}�X��>�W����G��O�)/��������%�9.�r�� 8�O� �`B�*\���Ԯn�ř7*A6k��K�M��5��rz�a4lM{-�y���X�;D�����@�a�qX`�>���0�y�a��آÒ��j���/}K���%D;�������W��(�`�|�<6�d>���e3ui��.BT�h1����>��zN�W�����B��#�+>0���,w�]Av��BEĤ�|#�3�p2h}�|������
"��R�3���ӡ�|gX�K���s�H���6���u�uo�ZD�T������?�8YU|�{���sŢf�Y2��_~�c�
�j}�턴͞i�h7�:~�L��L=�xR���V'��+��e��<p�n]�b�SzG����T�AKܜ��{� �/X��p�� �r#^���3ayP��q���qL�3RoR4S��'^D�o[�q���Ա!P���ߙx�xw�����H�F�7�?�'�C�  ܼ$�Y,�� ������f��g�    YZ