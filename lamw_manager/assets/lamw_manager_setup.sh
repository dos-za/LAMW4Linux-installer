#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1931539455"
MD5="c9fd9d360a715b32f00621b7ea25c8b2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23480"
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
	echo Date of packaging: Sat Jul 31 15:08:53 -03 2021
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
�7zXZ  �ִF !   �X����[x] �}��1Dd]����P�t�D�`�*8/,��7�s�ɞ���Vi�n؂���;W�}����q�g|?�+cD:�j�/� 6�5oY��vʏ����� ���;����΁����D��'�112xjBQTڊ�w5.!�Q�*s�K����f8��lA����p�q��t2�*T#�d���l�!���:Da���j*��u�*��SX�F��ݟ��Χ`�R�[�-7r鬂��Jν|�-T��d	y�?Y�Ms��i���=����䚩X�ɒ���YR�?�J�?	]��$�9y;:p�g��L�|�.�W�.�8���S�"z�֫�U�;X}BC�A�B�(1�Z|&ؾh+B?��q8���M$Db���r��`�-6O����JScnG	��+�E#+"��:O���jfy]�BxHr&�/iB�|��T?�T�?t<���K��
�Iм	~��-����Խ��I ���Ճ��|�`)R��.�4���G����M��x���@�pJ�(!��[Fea�O���*_�|�c����,��i����a��hj���`le��U�?�#�e*�H��A���h( k&��n;����楝��<���Hu�[�J��X�ޚ5�#Dr��H���xv�|�x�r��p�N}�s��kB�	4�*2�P*���	��_%��1a����ًP�r�P[�Ūr.�4�t�7!���!F�t��W�k6�4ڢ�)6>I���a��l���"/= �N�e����ҦaP�H��$ݪAX� �d(�Z���p�\n
p�-��#��;�ɋHW_���F**�x���������[�J:�NHc���j#�rx���[���~�!MQ1r�\���כ����'�+��;Yއ�A��-k��TB���w$!�y�e���z��䤎�Sm@��*�<.X6��H�`ކ���밬��\
���(D�Z8�V���6`�(��<�� ��L�z�)j±IY�}j�9��%ۺ_�������x��<����2r|�<,��'���M��^��Y��d�Q���+�\�9���G����կ�C��w�R51�^�-�m�eW�8���.Ҋ��P���̈;S���}��r-�ǔ�碑��82N@&��&���U�$zS����*m{*�,2kM9��{�(��h+��e`�M���i�*2�?y7ya�H%�{�NeL�cBT�I�����P��y������Ri�m�QD%�?�
Az�~ P�о�G,�R��{�V6�?�a���
������~i�!�<��v���α�n��V���Ö��]��SH;Ah�[�@�{��H
� ��;�e�b<�e��z�Z�k��¦�^*麿�;2�I�w�����}JY�_���7����~��ٮG)+�')����>e�u|�i�l�[� 2UVy�߅����
���:��X�Ҝ�������Fǌ�Q��\�����vU��F�WI^L��i	A��(N�D0�daY�\�H_Ř}l:���)�3tL� |�@��U���)�?Z֢�Oky�ZHt_��?
W�}��9T����i����|<!���JzZ�7�� �X6�x�6-]._�&[��)���7�¨��j��c}�fBt��!?O�#��i�*&���Gb*�]�#-�����W鵔1ŧO*S��W$�5Y�B�Ƽ)��,��%���4����7�R�b�z.��|7��$��w�
�������%����GAGV����qQ�w���l�å�*�1�f�+̼��KC��_/\�`�<!`'��Y�_6]m�MFw��cbLS��
�w�5�l�Ua�Y����z]!}M�L�	`0ù�%<�2_�b<rp�����|�R7��ҟ����n���G����3/�%��il�L!ɪe)Y;�ZM�^|�A��e86S�7�P)8hc¯d<i�Y$�Y��݀�<��nV���v�ʦVI�$���j��S����=�/c3ߏ	Q�eyF�<���m?�y�����6X4�+����T��hb����Qڀ]zT=��D.�s>�[n�cz����֬�!�m�����!����[�!��1�����XC�P��5�.�0 /�n@���o�|�_�]+������@pp�o������4�$g:f��
�d�7�����u��@��.��JJ�9e/��m�N�U���A�?&��F�q�Qq.LPz2�7�S�����8rV7��w�l�r�8�NY�ࣄ����7��ޤ.�����⍭n8�O&�;�;�s��l�bf˂7��}�>ھʁҵ4+ΰ�`L�F�`+����������M�r^d&ò���d*_��L��;mH,nd}���ou���g�"��;�����^Q�����%�
^�ޓ�b���CQ�xP�L~V��v��oԖ|����%���*_b/���W�s���R�ҵQ��g ~�����v!�oI�Jl ��SY�,;03
�Vy��v�"���E����t�D��-jζ�[����8h�)�m~BY�B �DK��&�m���w�T���pBu
���~���h	�S(�59�B`'�B2�b�\���t���5�(��;vFm���z�%�h��L����Q�d�ڥxg$x��2�O6��fs�����s�y�����*9Ħ�Z��nQ�r��YQ�uo$M~T���<��[1��<�y(�ș����i5��%�A,��UV�����c�,���u�s4SG}�e�w��
�0h+��I1��'*B�]��2[U�;�J��[A��US�Ҍ1L��V�$�����8q��M*F�$Lá��K��,���)��]-s�9�J0Y�9�>��c��4�����^����l�76*z�腚:	�&n�������p`�}���2�|x�2gz��0B���BU �N����M��,��z�\G[}k��V%#4(�(�����$)ժE����\���'�����`kO���̖���`#<��у�gTΝ�12�Ӛ�D1&����l������*)Rb@d�LڨJ,V��ID.���z�������z���h�/�7��� �N�� SP����5a�j�%K>��p��Vc�J��z�%@�	+N=f��P>�U*���aJ�ʇ$�5�p�v호�-�����x|,LAٓ����<q�e[�IM����H�S�
�F�cJ�����~l�	^���� ��])��d$ɖ'�oENÿw.�Uqnyb�`�y�L�J|���%����w B�@VZ����.�0=wY�t�}��@�N��X��Lj箚	�Mi'~�x���s6�K5e'�69�+�'��\m��r�&�8�f��b�4G�ᢤ��ܠ�3om�W<c
ɬ���9�?�;���S�%�k5x���<>'÷Gx	�_�{	�����@��[����vb�?-��a�b�s�~�K�w����@�!�`EE��Ħ[i��M�2|��;��p�!�|j����kn��e�C��|��0ԭ�%ĴЏ���F��GӼ�e�W_T����5=��������0U}����?v�\���3�_*�
�t���H6��=
wr!��=����A����F)�*L���W��|	�k�mc^a�����W�u� hƦT�����!�Kv(��mt�)��s��8���I��x~��u�;�6�	�bjZ����;�{7 ���|?o�؎:�n5�Pj�x�1|��7ѭ��>�!FjB����N =�)��ratj	��u�u�������V{?�$g�k������P����]Bf %������'�W|�l�m^�� �s츨7d�~��1�ԉ	�d ��ëlfZRˬ��qN�V��+�^[%��WJ&&~M+�@1A#���
�h��>��A���;��"�T��@?�81B�7��N�-@?|���5���`qY���/^�$��٣M�"�U��ƙ4S�e��R�|�OF��kAp�̀yzAa�,C�9v:�7�A-�X6���]�~�&����� ��5�=�)�Ŏ`6D(LAb���t���S^�ؖ"+�54��I� ���-�6��%+���Y�D�uR-���#1��x^f�Q�m9A��t㧞n\������%
�ݺ�'���
�RF�R�XS���v��
���1]�Wj#�  �D�S��	k��{ @��-�:i��˺v�W�~��ru+��U��	�|Sf��TV��h��'3�A{c-`Wr3~(Y,P$�F}F��"|�y��	<��x[a|������j�u)�ɡ��!���������1c�Rl�u6�F���X�,2���Z�NAKԳ���[�;O��f�h��)I���+��)���X]D5�i�k���z�+3k���5�t���I(O����͑8�$v��At�����_�ShAAWq�>�8�݆y�9��H<jR6��n��� r���S����A��ޜ4D�!|i�;w�f�Pry������˛s��H�J�Խ�ĕoy���ʩ�*�\��������0Ǌ�B�C�V�?�p��7Pւ4}2*>�h�D'>�|��~���Gu~-�;�7��I��U��1Z��GC7�ʃ�b44�)��<�nb���?&���S3k"�VEv�g��\cJ�^�a��F6�B�yl�s��u7V��Y�m�h����z/B
w�(��Oˁ�k���CΎ�t��� ʒ���X%��7sw�_���1��I��`�X��A��O�	'�� Jmd�u���f�y��9 ɣ锕�ꡁ�D��<kJ��W���� VE| &Aǖ����n�e�N���V!b�����6땜}1p�6j){��"��"p�2���&��5&&H�^��E�6��2����{���SŎw�6�
F,~�������A�<gk)uL���Ƈڮ�G�3���ݔ=��� 0W���/±�;}�+-L#��s1d��V ��e��Ɖ������!�=b@%	Q�l��pZC��	��_�zW'
^ub�CCFęJ�UZ��y���D'cܒ�cL�5u͸�2�e��^�I�ߏ�X[԰�*�IQ:�󳃍| ���M��q��v��s��򉸾���{��9�%r}gV����ҹ�oХ	��=랏����H7V���\$.5�y#ЖMfqT�+j�D�Գ��U!��;�/F�������z�|v4�u{l=3<����pc�|�>Z��|/��^h���噗#()*S�ɮ�l���4�������?����J�=�Χ��������6
?�2!�l�Pc��W��p���������L.kZ��W$�  g8�lp�U�S�h�Fv2gP������ۀ�~_������#b�FM����}\ ����V���fr��<)�d�a�}*[Up<��P��W#�������\1��C� ��'b�X��/q��p%���	�������_�,�J���/�ew),���-�i��[*��_�W@�9��ajݞ" ��2NKH�]C����j`]�!XkZ���2�Ϋs'�;.�[���J�%ߵ1?�lr��rc�l�$�)���:�n/��\s���(�z!x����s@���V�U��C3���;G��,���3M����hv%�靝x���h4	��"�&%��t7��
������Uj>y?�n?L��PEj�n���?H_}�%U�/�`I�Ʀܐ0) h�I�{H*�ikU�fC������p�kQ���+��8�@���'�BK�x��W�'���72{Ezn�0�ѩ�����SWw[��F�M���F����Kզ�u����8(��9$N���E�B��5���+���,���W��g�y��߻�K$�g�B�|ʟ�-3�1�I^@�2<lM����0u�ݧ��q���m��Lz\<8�Qm�JOK�s�y89��∔�!��9l����Y�.�Es뾣T��v�aȷ �	wkl�,柟��1�5&�`��;���3x�7�����,��e��M#��)Um���lN'��8��D��J&��LST��Ӕz�	T��#4���E�ȝ��p��"�`�[��������Ū�"�ʔ�e���n��{��_��R�� V��ǦFW�i��!лd��Ѵ_Qԛ�Q �	���E�|�P2 ���k$+�`��H�|{�FbЁx� �f��8U�@�[4��x���T�����l��惦�[Y�b��:���*T�5�C�pXH��}5��vb�:|�X1{��5gh����u�U�o�v�q ��>s�/^�C7�u��W���.�c����bTQ\۰��\ޥ<�EL����D�n)�S�KN$t
�{e+q��|�]¥Q�ȇ	~�7����/ �c\��rzs� ���K����{s����&��B�C���nI`��ֲ���\�DD��w
�&T����ѻ0 T�[F�p&�g���BjS?ZR����w���T�ғ�5�]�hO�ޤ�W���\�h��=����!�>�̬�ƒGۿ[8 B'4�3|� P2�""�SeTZͧ~K>��2�z5� �t�=(dէ� ���/����M]0ԑ4���"���
ӝ���z��au-^UGs���`O䪄S�'7}�g����!#� xT�p�tnr�un�z��>��xN�`�S����#���p��?��]�bL}�}�����̉x˖��&~�f{�8�C ��������A:L<tX�(Ո>�a���L =vָ�a�� `�9�d~r��4��C+n:��D���}q��,���g�T�N�@Z�����z��'^;�+��p��K8�$X g�P>g���;��d��z���:�c5o�@��D��R�Z#x��:�M��0��0�m�����P`hPI*R 6��-�U��5w\g��a�DgF���:\���M ^]:���ca
�QWƅx��(�����Y��*?�_X\%P���ř?<o*�^��v��t����!S�Wmܧ�ϯ�+?�#&���V.$[W����d ?�1T�L)��ˍ��aŃ�o �I��%м)P�?Yg�Do� �Ө�.�Q�����gInL���_9�;m�~�w��Q"����n3U����O#	�®4��g&?|^z�)���trb�����B�~��a����Is�÷8�����sv17~�Y�y������$y��p\ 58�׼%��I%���.��o���~.Y�=���~�֣)�:��Xew���2����e�V�r��ߜ��l�q�_���
1��2ֿ��E��ǭ}�)ґ�����h;RW�B�� ���"�|���+��5|�y0MryKCb򺚖�:Kp]��E�����qs;����Sc�#|��K��K���b�|�6��)�̀�{�*z
L�
h�%Es��w|�{�!�n�1�����pV4��q���v�#�,�V��UDM���jZyď�Q!���z�!9cps����=ǉ�S�P3��>��5nd�tH�?ʏm
�+���\-C�-�-{�����7�D!��r.c��#�ˊ�?�/���X��y����1k'l���r�	�Va���U�1aU�|���bh��"��-�&v��e�_�S����d�Z�L�_Z.Y+�����l��-�Z�$������(�<c�$ۙf9(Lc����g�,,@���}��]�^�gC�{)9�
ɩ*�+[���v���E�qQp�"��LW��Ŧ �q������� �DE�B_��@.������v�1�+-�ݝ8��,=Ǆ��b�}�|.�k����b�.�[1+8Ecmք�#9x�*E�lb<��K]�m��L���W1�n�ѫ���@���rNgrѮ�cRh	�(��r�9,L�|�.��R�y���ǜ~�9*��HYV����H'~����䏵��'�� ����G	��{a�W	cp��o0��@�%�����w#��,�P��.`��4��u0���j�>4��	r�2�o[`��
��7.���5S�ԧE�+o����Zq�I@�C��wD�%���4�p�H��
�(]{�����bINz���=)=J� �q��2�V��>a#�I���zP1��g���H$=վ�} S�8�{-�� �:�
t���?��̌Ӗ�I	}�K���LJ�k�����La���P��d����?>#��94�����m��V"��.�4�����=�Hr������Hˌ_�j����	Y��A7��2���Ո�+
1jyן/�`Q��U1}	��j�ex����<��1�ywT�����TJ��ԙ��n��e4��Vx�D���0���ĝ�T8h����|B��0��R����3�ݐ=ǡS�3�/ۢ �~�0 Jks�l�G�)�����ս&��_y�Qʹ�0�V:��|����s��j2���,�⭮��!�"ljy��L��'��аR��.���0fǵ�@��%	R��i�m��e0�?K&5���a:�(;��ʵj�F["����uxc���h�m;:f���X�k��,@��.�S�F'Ŭv�u�Ď�Ht��#U5�������6W7�*���0�ε��G�D�A�A�m������}Y�d~n"k�[�BE�J�@ړ�ld�*\έ�hf���%��q(��!�Zςs�a�������U��m�#����/iس��ɫc��Mvi���,����}��{C��׿��Svp
���VPję$�f/� [���yl,�;v/�`qU_b�~�-T3{����
r�w��魫%�*Wq*�<��̮�q���w���l؞��������p��q��{� Ћ!FJb�Ў���X���'�N���#�����\9��#H��]�����@
nX)Of����IL|�Sq9�F�a�)��'���,d��ӏ��ՂKK!���)"&܏M'��(�ʲ{w�S}>҃i]�K�4{^�������7���Or}^5������4L��y(ͤ<E+�/���v��(U���L��B���O��E_8}H��14{�[U��ħ���"� �r��[�$�}
Ş�����*|�Ah�1�I�0�y�b��}��Uw�}i�R�2F���;��Iuz��7�}�w H�(���7��U$+�L��$�1f:�_�ᳶx���r�Im%��֎�p�@MU��-X�2�:���p_�S���}vO�r�o�PD�-J^��[��SHAm©ѿ��Lzv�� �T�2���a��	)�.E�4(0���C���]���\s���s��l�����
+���9�5ew�K�J]_�w��W�/g�c'eId�I���i�|�;ޟ��[�~X��(��H�"k��+�� ǳG40{H�u�h4�ɕ�Vw:�Ѫ���,`p�G����4"9%1����6����[�NZB��h2���1Ƞ��Ɓ������O��4\���X��T���W6Ԛ24,�I��`|~ %3�\���]0��se
�l�AR��_֌ΤdV'�Ν��b��ڜ��g�uE�i�=9��5�a�����o����t�,����8�dx�G�BiU0rEV`g���َ���a[e�$O�Ur��ox���2B�5{��w��G�l�M;�Zy��b��ඒ��$@���������6��G��o��W�W.I�rd�r)������Ƨ���j|��oE;)��E�W�H���
�S�̶_O���/�?!�PT_Ï`�b�!�vFA�8����6Xo�>*�������g-��1���t�疧�:��ʊ��#c�fӶ��
�ٓ���G�LC��SB�L�_�;���n�Ia���R���o��$�ᨓh�_��@Z�;X�D��(���?�'#����yʯ�e�Z7�1k�ҝZ6��A����̹�����}S��Ź�i�1%_�_Y�$W���韵N
6GQ '`����O���+���a�����f�K�����C���.1M�_���9c��M���G>T���H��@Б @�A��wV5Ց=�Wg�����������������mre�9�(}m?m�T����e�a���d�r��5q�
E�z,����U9 �濯��܁�Wζԗ+�d%�Fۉ�m�h�Uel�mI�J�]�tu|)M|,G�Ƈ��S帣�y.(�?0�F��^. .I(hZ�i�	�wP
ʦ�l׻��-o��GbX�û�J�|Y-\�D�Wj��1b��}���xa$1p��B�xu'Jh��3�
��n��W?c���ܺ�4ʥ_˫�p�1�����{ϙ�X���U-x����F6M0�?����r�M��h`�u��Gߎ��k��ąr��v6�����6 ���c�E&3���h�~��jX��M�L��C(W��;1ū�����V������w-*��5�Ԫ�Xb���h�*���tz�i�ô�H,�n�ݟ��L�=��ʼB�>Vf�&%�G:%�k�9iJ����Mlf]�g���:�2�17H[+h���������0���3��(@�˂]8�m��p��Q
�ybS�b�Eb���x}�B�S*���VIbf,N��4e6i4r��Ϭ�~���NÄ�rv^�\�X�7RYk�'b,��o_��fW�,�ҁOd�Fg��xN���s��R�N���<�%f�����UK�aL��bXD�CO��U��[�/2���;�r�P����������[X2���GP�f���Ċ��g{E#&��?�,��#�����'�M��s��;mzD?�˄�0�9��Y2�G��̃~r�U�s�Ȧf�T�PVZV�%��� ��r�!iѷҐ���}�^�3�A�^�����ˡ�L �zæm������y.+/�?4�^t��:��kC侼���4�wB'c��\z҆r�������[eb��W8;�;�=(�Ά�	Z�V��	k�T���>��ֻ�j�i��%mW�����۫n��V�|�kL�'@���v|P��zs=\e�_=O_�)b����5��yjՕD{f���Ɵa��[m�DO��r� uJ�^�	5ˎx�=Ў�m
_^T	��1�c)��Z�F=J4:�O��?�� Ù����n�U���Y!�MV4��#�;��t��So(�
)3��kBhS,��9� ��$�: �.xC�ӫ�<`�_���b(��_�.�C2���a��2�҄'��h��
.�}�z��LG���+T�q둹�Y�!�A��8s��.�u�~M0t�b���I4xK���6��B׊7��&�b�,�)�z�N��'ukc�nVn�3ӝ�u� �C�<!�`�2���%K��m��ыT��L�YVm
�Q�Z��������195�Z|]Ȱ	Y`���V*��HW��聾_�}M]�l]�T��{��nP'5b����ɕX��<؟����*F�>P�KĦ�l;�V�I��Rv8�[�a�����ݹM����F~�'/����L�z�V
0djS������E���a?oў�E
6-����t/�΄���4�d�UH���{S�^�W9�ݫ̲� M^T�Lbh"N��)N�;k��������O6ҿ�F"Ez�&Be��]l�g��n���E!�_äH\k#�ڶ��+#�/�r��0���9W@N�>�7{��}%u�e�	�z��qI��E�L�!`E�eD�7^Y�޾Z��!n*|�"�CH2���1$��p�X�1�2Iv#�A�p��(���;)��%��(�`���n�i��ǟ�.�?����*P�qBT��h�4�/K~�w��%��#
�G��?1��:���=����!�yh=�#2W��_��Cl~v+ 1K�rv�&��Z�|E���A9�������/�B�bx!���@�FAp�*4�#ZDn6��׊�:E�_]��5�(�lյյI`�B��C�����[����s��)8��yM���K��{�( ��p�Es�M�[c��۝�2��Ć���s壈��S7�2q)���h�B��;�J��0\>���=<(�0T�4�&���[�i�D>���]�}�m���/�+����)n�K���ZRO���<��^L.��>�I��)'�à����0��'K��c���ݗa�n��]^Q~���3W[rOqE;w?m�YZH=�/Ϙ�|�6�訞�'�Ģߒ�����E"n�&�9�pm�v�1NG�<4���76����*��	�
~�˳�eN�-�@�;3}]��f����vYŬԑ�Ly���hg�&�)�r֋�3��u-2X3�:a����@�VQ�]G�`��7���f��Ռ޶���0�f�������M?�X�"�V�m���Ϗ�<M��)+W��ad�$���Н����j���gO,�0�����<���JN%U����z��ߑ,K���Ȧ��@o�=t Q�ͭ��9 ~2|�OV&/O�(������f��v�Mܗ��S ���lH�O���BN��g&�����⥍>��>r����I1t~��q��^ud.�����kXwh��/��=Թ��aa��d��(t����e��V{9��u���T։L5'��+�Q���rۇ�R�|J=!3�.�s,��(�su�$V����I��zܨ#9��twvXcnZ�E1�!���~P�cI���-.��A38�������E=��o�K'�9��d��]����Y�$Ov��)��u�,X�x��������Լ�$�'q<���Oݯ��:��P\e����%��b_�/O�_UL�U0���%A�8�w1��$t��������������ڸ96�H�,c�6C�D�y����%~<�+WZ��rO���!�*c�ٺ�9o*�_:@`�|f��*�c�ki˂Sx�QpC'(�Y�tP\@�|����)��"P�~�4�LWX��&@jǫ�{
c�;�{��t��~յ���ddZM�j�\��o��u�މ���GQ~�]�5�����F!�8\+����J�Ő�G}��Y:���X�.����;Gn6{�m^D�c�P2���w��PE W>{���댒E\uL;?5 �[hVߒ��m��F��zd�N㔦�W�(���S�C��xn�J�*k����\;o a����I�N� �Í4�������c/a�:��cuf�O��Jog��"�x%�m@<]��7y����C�oɂ�u��ƺKN
k.��K]�C!C��(a��mN������k�R��N>�\IoW+-�l������ԩX��"�T��_8�m͆]^�R��`�U/jԧJ�7�ޠ�$��/2\'�b��u�j�LJ�MB�Z&��Ae���C��,"i��<��7egv�w��LR<��X�ifE��9+��&���)�b[�K3�91h" -蓪��b��hD	�[S���ȋ�f�$Xc��(X�a�)3�������˟�p�,G��f��?�:��Ҁ�wa���9���z�8��ν"n@0�W9)zׁk)����=�ݟ�����=ʗ�(����;�#h���+����J�E+֫����K{�,�}�+�FFT�������E�s$ף�zB����(�k�h1z%���T�Hw��V�0D��|K�	t�6�R��tX���ڞ��t'���-�i�Ӱ�T�!W=�S���������[��tX��e9w�0�}�'%���?�|+VJ[l��k6.�=Đ*�" x��� Ȣ�����n��8C1"�*}h�
:�GW��2�TV`���<�
JQ���B�(�3���r�UI���֓�@q	�P*k,RO��~�}^]�����Q�7~���m�!x��������	�NZ���}k3 H�
��6��I���N���dW3][h}�3���n*�\��6�R;+j���p���}��.������	Et ��AQ�Ն]�u�3�y�m�x���E�D��M��Gwc��ډ���ɩ_-?�3��A8r� !Q���E��3���n��Y��ނ����*�
E�]��=	�v��[Cʏ*��*v��)�V+NՌh������,�Ež���YJ� ���
�I���Y�ҝBB��3+A�ƾ�T��(^���ЦmiW�m4�W���ӈڕ��Tk��z	6�M*���;���001 �F��xb,S4��޾��NNם�_��}�=MHa@�+�4x���,�_�1�������~��Ř#ǱE��
3����+�{~{Z{��U�؂��n��*��N��U��z��J���"g˰�Ƨl�9}%F'ߏ��[Ox
ze�M�\+�3W+��6ϛ�D�gŎ-iJ��%��A�m���T�w��H��-m�Z���#�$3�wfw�"��_�D���,(h/\1��2r.�5��m��z�������LD�>g{pE��Q�7�S�tqD	��]gz-��XE��X9�F����v�s�l	���Ӫ���E��V�)l�1�F�㿯jX����|g����{Ʉ����* J��BQ�ؤ�5��*��4����V�gO����3�V5����v>�ۻf{܆1~�Ix;�UC��XHp��X�H$��=��jC���fQ;�C�N���W��%�މu[[2w��� zuf�����u5]�?��,`�����ڽ��<�X[���nE��o��Tl8$�w�i-�MŴa%���K����b��k��Aܴ���	kyl���aW�.W[ymc��q�i"!���)�2��qz��w-��{���@�#T����7�lO�?k9��B���b��s)�����5���ɫ�r�W��m>āD�5�r�b��!mP'O���|��᧹c���1<�� 
!p[����F�;����W�.};-7ѥ��]�u��v�
������~h�d�@���\�����}r?���{~��K1�ڡ#b7[hĤ�8~r&W�t���u ��;<11A������Kw�� �VC�}"d�"Q �;�G�Ӝ���J�k<�M�{�$&]���}���E�>�j��D*c�.����TEƗ(P zhn��#���K�����E�PH���ldj�6�&T�ň䲡ҕ��������V&#������JL�K��u�/�X�O���B��*6�>�U���熐�AfG��	eӿ�8���ؗ,�K4k]-j�U4�ī��¡B��k���a��N�cKJ�M��&�K'�\d��D����w1�M�\B|sX��|�s�w��B��A�F��S����lpL��'�I�R����?OU��FC��mJ�����/�Sh�����I�����z��wQi<׈���~��x\���ـ�ܮbǐQ73 ��Ӎkؑ^�JԺ��1��^?�5���U� x�b���fqNGbf��������� �����/�}�)fEB$G�Y�@G�cpd�1�hzI�a�)�����6�p�d(f��\�٢���2�P#8��3]n�x�%�A�lA�Ԃ�,-NU�����oi/���Q^O̲5f���Gwy��;r$�͕�Z���NЕ0��t�w�sr;V�3G�&"Y�#��A2��!c�g�Y_�4�VݒJ��%��]���#�=q���@q rmݍ���K�o��K8_�m��a�
���%l�x�l�΅�꺿��u��
�y��g�V��/ )�n�n;.ͽ�3*f�Ίf3?��W8e�AC��jh!�B����ȭ���~C�b_JX�L�r�#ǠΈl����'�:Ǖ�
�^�a��r+�J�F��)N9�E�ɣ;q��S��5p"�x��sۭ`�W�n��C*�X�L�)�.媬���@�X��aH�S�Q��>�c�톩k�C���}��c��v��wtHx-�<PڭS���?�6d��Z��$�̦2�:�g�)��'��#�(w�b3�'�}��
7�M(�����;�.=/�)`?k����<�M�R��!-�`�������x��2=��1�c��Ot���'����q�II�7��2�����1�d*�a�rEp�I֯�.�@FGۛLϞj�+E�.�U�_?K����JZt�u.�������e���COJO̜����䛟E:-gÖ���yRSh5�8hg� *��u�B���vaJ�(�Q���]Q�� �*���8c, ����q��vM�B������e�� ���Y>s
��z=O�IU��ŰA���C�{��vW Xy^D�Cʲ�Ԕ�v�A4̍l$�~gf-���px|�7��~�v������i�)6$�ǽEֽ-\�1�� f��۪�.�3��@k����P��ܡs/Q���~jҸ#3��S]�MJ5�Э�.�r��ssU7 �jg8pQ�RS���-A5�!!咳���т�IȱI���,� �9�'X5y)_X ڰ8-����5N.Y����Aۉ�z�VC+����R�Q���~�>��K�G��[����k�ڒ�\A�	T��4��"�YoDa���"Rޖi��7<�t�F��-=Ȅ̚g���'�g,w��t�7��{�b?��H�/�sH�>�j�A�jz^>���Y"/ӑ���SH��K��O*��h[�"Fr�{�GZ|�;�c�z?��׻��b� �z�/�!N�����r��?�%R�ہ&Z����X,+a�IB
,Ɋ�@ʢ���=r��B�(�CF��� �z��I,��:�.�0�F��A`M>�����x�l��oQ��X贼�S�m����-��Q��� \�(�+�S�Oj�<�q7�����@���(Tί��K�>e�߭Gf�i�B��(�[p;y��6�&�r_������"�K8D,&�����8�Ѝpg�KF���T��T�Y�A��g�T��Z��R������mq4?{{�F�m�O�Ϩ;J��W��9��^:���#ֆ�?���U�"��G���	.�X��f�`�F?N��o�@Oh�z!�Zr���z�ɍG��1צ�#]��PQd��-��y\V�~98�|�^���T��Ó���&��4�d�t��͔�t���c�V��[ت¢�"]Ɗ.Sů?w�^�l�N�mF9�c1_ň�AV��]a�fb�3�BX�<uJNJ_�J8���� ���q�-}7���V�ݕh��i?�\cN2t�nfTt�O��O�I��Z�ʒJ,��.E.�K#+�*˛�M��u�$�J�'!�J����y��tv�
��ݸ�F^����9�?$�����-�Џ��7a��#=��E�B?��q�%
'ٲ�t�Aڢ�)��賗�����ߺR$���!Ĕ� ��G>���]~��K~��SU�D��lJ�u�U�,�@��T�
O�V�㕅��KӻM�6�0��5����1�-�b^�j�Yp�u2���B�����T���
����,GK���!.�\j)Vq!�u�\�{�V}�q�ЦR�^A	����u�W�[���ѿ�zs�-t&�����>uw�aʅ�ҵ��}LJ�Ry��o���2�J�	��}	����d�=�����G;$���C�z�SƏ�#�AQs8��ߜ���Xz�2��<ٽ�6m�J�i(�^�ו���>2~�#���N��"�h<�\�h�v��
b"��pʃ�:�Q;+D\�c-`SY}�ªO�����G�q�tj�7��3��a#Mʭ��n�������y��'�D7K[�T�t��l6I'��zj"s  ����颱_�]Xo��HK��p�����캣���/��s�W���71s7a.c3\�Oi.j��9�y�ƫx �0j���ZBRi=�D!zf��V��}^���ڸ"��`!q��(6q��6B���U�Z��*�@~!����Q^m͸"�l ߁l���2*�ܺ~FMވ�_}�k���7�${8�}��l;��8ؒ3S������1����a���i��eͣv�^�����1��Ӷ:v�g_Y���`����"�W3������gL�(q�G����A��W�����+=Dm��%�����N	���Q��G����)~��H8��1U(�6�W5�#�.&B�*GE�n�S��B��Pyɵ(��ɣ�_:������u<>oji�n���w��V�r��������9�^���'��O����ODUٚ�G۪Y�am�������^�T	5�����&�C�8����xk�!d�J�F\7%�d�e��o��J�bI)���Pz
_�\��ay]����ҎbK���0����D~��'ͨA��=����	ĭ�0��/��i���[�t�u?�	`a����:�����ӽ�9b�Q~�#]�����Rj.���:���Ay�ߌ�V�~���$� ��ܷ*�m���K��7d��i�1�5�qY3~��hG��w���{y����(̝?�_Ȉ���T U��z�ҴIqD�c/��b���`J����cL)�WkJ���F8\��7��۵M%
7m���}<$�Z�I��p$Tg�~B�ޱS؆�#��Ɩ�5�����������*��0�@H��
�I=+"�����Nw��1S);�[��b�����gZ3�9c���6��P�rA+1��{�>���ӽ�~������1μ+B;ҽ�I����G'� ���!R9�u�
�m����l��9��?�ar)0�@r<�>����_FԞ�lwaKV�Z��ӛ���֯����$3&�p?{?D���*��w�S���Y����)/��s4��(WR���L����ə���9J`����(�i${��̈�a��TNr�ig�+����[ �:b���Қ����~���/����æ$^BM����X�$'H� K Y��B�r�j?Z��-Q'� ZP\kY�}�ˬf6?��<�}�i�I�*� ��9u�8[�g��iLC��Td&��^L�4K��.����󸰛
�BD�ȶ�ȟ�,��m�������~ٵ?EC��+:�(:&Dȉ?[u	��%���%�Gjڡ���\+ۇ�y������H�T c\�u�O�%���rȺ�㬁�겣E�wV�������.�h�O���31�Q�b��cE*$tv-	Ur TB�X��ح��K���f��4���q�X�͂R�x����5��yė��5WCݚ�����u�L��3��'�����oQ�N��7@�h�f'd�`,/�ͬM ���b�į����b��s����S(y���T���K�U�7��}i����k1�b��͊��5�޷b�(��r�Yz���8jPp�>��_�݀v����g[�V��~��J���!F�&V'��H<s�G[ܡx��bӿ�#��
�����Z�w��_�LĔK��
2�������,<:��w�/m٭&z��D�8ܓ"5hHC���޶��F���̯e�8��#�!�A{��;���^��%����ɦ�)*:L8�� �n�J�|�$wG>l�(P�'�;g�|e7�s�s\�dNg�����������~m��=-�y.���:�GgH�da��.�[�/�)O8�� �!OW�>8fu�s1��0�C������t	N%���n4Hǳy��Cd?��q��уbBq�i�����������QB�.�:S�6�h&���'�?�m�R��#h�<o��esE�"�P/G�>�e���5oS`҂6���p�˱}���Em΢�� 8�s���Gv��>V��饏�{�0��ۺIS�q�H�� �@����9��4������Sߙ�����LW%B�}l[L�}���QVN�?�m�Ǿ
R�q^���԰=~�!���1�̚��"t��h�{ ���bE��6���`�"����I&�2��em���wq��p���)�L�7��Q�F�S;Ϻ'	��>ୣA-�[�i'J=mW/W3�~>�ǶX2��Q��Tp�/$P>7����r+$e�/��d��N�E��3��`8GX�������-Q�I�$ �wD���N��
f;��E�T:��D������bw��~4n�7�G�����.�ƉoG�S-Q�L]&^Ok�������n�׏������rδH�-Z�ޢ�5���A
���p��@W���4���99�F�}/�Ő���1Wna��vr�|�h����ɑ�h9B� O�.#�%n�:�9nh���.��#_�Є�t�����
v���� ��}ԇ�zmʫ�&��a�2��&�[�+%`j���%5�`TMl�F��T.�܈�]T/����{^V��u��Oƛ�"�@�~ܰ�9|�X����nl�,�t�ބ�T_9b�����wY���3���2&��� =_�r���6{�Vk?T���su���������Unk��$$���>b6�x��.�?ԙ�I��gF\)�k�O՗	�so�uchو^�kIm��0�Q{�,�_&�6k��<K����׏K] �Y�D��OaP����1Oo\��0D��s���&�V��b^��*n"���{��a�4�����G��U�"�n��M�?S�Ef�ѽ��&�GxX�ۇ� @�7ζ�֘��MN�x&%�=����C�����.��+\��=4ڳr�o���[/%��{������<:���W49%KNK�K��u`t;���\Ѳ�Yi,�B>1m�z{S�*4i3�]9:��];X%~�>���W���j�����Ԣ��QX�Pr$R$�����iKދ�f�:�+ ̰aZ?4Bk��1���#y��	[o��
mr�i�g�ԐR���[\��a(J �~6k� o���f&�]=ҥL��v���c׏P׵0�F�Ϩ�¬r&k��^�a���@f2�(���c�";��"@��7"���Kʉ<�دi�$j8���G��
�7�~y���1�x������MD���B�~(O��h���E���m�	��L:>��]�Jc�u	��\^�F0*��ʢB�b�Ϸ�9w>�^5���C@g5]��=�9��b`"ʒ��cnY-����r��~��;��Jj�Gci��_U ����bi���Xr1b�w�XX�X�jҲ?��y����Y.)� t�{k�2����w�"
�}�z���Z�+���5�8�m`\��ȵL)��X���Nbi��W�M^'�.U%_9�_���͉">���(��58EF=���3�DM:z]�?N0˵�`�)O0��L�B-����*I1��	�?�i�1�t�J�� ���n�.*���E��矊͝�9UU�@�"���|s@J.�	�@�t�����G�/��=���L��Q�.��o��UZ�G�<��TG�*�M�>� -�\�Q�'i��h��@ж���K���O����[,��iQ�O��&�N-��铩3tI�_x�w���\`���1���J�X>���GcT��&3���z<^�\�PY Sќ�j$s~X�T`QS�y��G	�k���9�+&U��jY��+���%���SOZd#�����km2y�$�G�׾Bt!ȉ-�"�s�"��*I��%�����C�.����Z�
\N�F��Y"�R6��uˀt��ҵN���m��z>r-�4�W����=PW�O���ߣq�9Sc.�̖�@��.iP9�ØL���s-
�f�b�m�)p�蹗\�)f�[��:T���.Ȫ�d���
�;W��	5���l�E�z��6;�d�v�?蘸��U����Xn��y5�4z$IU�'�4Y)����xq��Mp�ç�Ks9��}'l���N�r��<NCy���(暷䈍�X;��t�H�����ej��ß�Fс�֕�	�*ӵ�Ҁ�m[��x��d]%�����ř�dE���Ee[�F��?lL����[��$� 	�io�]�p?�� Kt-.`���-Z�t,~������GQ��;��xԵ��%�oa:�4�Ǘ��o�S�oX� ��=K�X��T�Y�3s׳�ɍ;��o�l|o(o ��AT,���"e�1�H{�_�~��Y����O�]9�����*!>�(.4n^�u�<�ۍ��?+-�^ȁ�bb\I�����t�
@�Vs���3�]�8N?l<����I6ŹѢO1f�Z��/Re<�7ܳt�S�>C
L��Q0e����AD --2�Ċ��Јekv���0H�n�Oe�}ƙ�2�VU�
�sp��'4��՘ J]u��Y,{*�DW��%Pw�8s�c�d1ȇ��PY���}+φ�f���!2cK�`������?/�n�����u�aɍh �jo"����p�/*��q졡-\�ëRi�>S�2�=�����פ��U ��!$�j����"�)� �yw`� B%%V�Н�aކ��f ��$c��h�]"�B�Y��eV]"��=4�q"�b�=4aͱ�M�a��8��G8��>+0l��	���D�F�����([*���=���Q��⶜�H�� ��&�yw?Qu���~K{���B�z	.�O���@@ U��iKU}g�"�ģ��n:��9�t��Ȍ�?JY��*K���$�^v=0���5Og�kF��UŽ�k�}�e��)9�RM�T���Z�5נ��Ã���^H��E�\)a�~v�}M�q��y�N�F�8dߦ�x�G\V��3*x{$g�6
����w��Fy�5�>��{�*c`Mf(��!.?h�����PMu�Q���E��U��*�"qa�d,��?N��.�fX�t����T�5db`\�hb����'����ש�׈e�4�o ��qM��E���hs���o��2(\�h���Fh�yÓ�B�`��Fό���2�	�E�v��5�cc�ǅ,B ��q�P���n��P����.�Be��#$��w�z8��)>w��#��X�Gw�Sd�!�&[��as�lc�W2yL�ś#0N�>�60���e�0�ᎃ�:
B�C$�Ss��N�{GG�̭�р�'gDHXӡ��z��H��De�'�?�<�^��,L�*j��r�sz��-{���T�� T�GX���Q��;.�D�D�����[YƐ0~_�o:�h��}��C��h��d\P���t�}���b.!�@s�6�"�([���m:�S�4*c�^G�rN��zr3���0^����s}h�VVP�pqR�H������  �����O�� �����jR��g�    YZ