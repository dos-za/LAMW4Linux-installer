#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="746206753"
MD5="a9422bfd1212313dd620bbb5c0a61a73"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23792"
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
	echo Date of packaging: Sat Sep 18 19:55:39 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D��ܨt�I]�=�5 ̞<i;�#wr�	���/����c�����Lqi�p%��%N��Ek����Is�@��Yq�$����xv����#�r��Iv�����j)>%�]������W�	��e�Z1�qȁ�CO\��"�������ud��R��g�h�z�ƑP�3~N����A�3��%��y�&ِV��T�c�,
Q�+bܖ���"�]���r��h�����22{��̐�kU'sw�@�1����N5q;፛�d|;�����L�-?����di �|����^��%'�x/&5����1�E��Z�,��|}���_d��ԍ�B�֚��B�h�㽠G���_���ؾ��jr��Κ�A�3�}�]�}��C���C@)�� �UR$w�_LSg�uUԕ|
:���W�Б����b�$1�¹}�V���zĳ%]��������Ig�K��S۟�*��9v�?��������ﰳ�ձww��?d�����A��N�s�(0=K���{](�(�>����	 �K�m8ٔ��+/:�~\cZt.�YT+����@��p羥"�u۬�M�,Z�#ΌL����p���M-�7���k�	�ҲHA�1��x˺�0������5j:
�Мk`�&�Kowi�3�n��S,�e�����w�Ǯ�u=��5��ԅZOXǵ�C5��A�>��7s�Ni���H��ȋ��إRt�q2�'���]��b�\������Q�f^d_��n(�N1�D.4��[�.%y����df��T�������˖�u�AU�CaD `��*t��:(b������v���U�Q����ɠ\�hR��z��2|B����& �/�h�F��� ����s<~��h�,��Q�d�aݓv|�vK;�F�~!>ηʉ�+��,[��@�)�1�8$�Q��b�BY3pZ@�@%�'S���-�wZy�CMD�&�\c�I5�FD�>{a.�w��m��a)7s�`�Ȉ�~I�K$욶XdfZzv����UCo�3J�osQvfu����鼌(�IŘ,��<�ÒkN�<�X� /��ô<i�4����Б���|2��I��$h8��Hm��*c����ӈrc ��fd�0�iʗ�x��D����_��N��@[��}�{�B'N�E~R�����J�CI �{������t�0�_�]�熕w�(�M/h��n�0��(n����B��ٯx���E����?/̩�C?�_4�?��3��ś\�W?��+�d�Q֘7�J*���,�q��KtG�إ}��.���d�׬��/HU賸 \���CU�2oV3kYl��0r�����a�^��F�e�v����L�.�UX���b�՘G����x2�D�gn�E�����c�q��
*���r!V�L���!��qa/R�/J�}U��&����;�wp!�K9���!?�1��f+��0���f?�ìL��k胈�t�k�$�3<_� �M�r�lN��~��ӫ���`�_��Z���z(b�đ|��S+�Q*l���J�Z�_�1�*�Tq�K� �ގZk0�Ɲ��1�n�nln
���v�^����!|�!���w��)̠B^�����L�3�YE�����#t���1�L��'�O���s.���hA�F�6�
���5ZT�[ۃ>�����ǹ&1=vJ0��Ő��:|���u"iv��	6���Fe���?v��`&(���O�r h�/>��7�*���'w�$y�e���?��v��Ҭ7��Ĩ�l%�*��͐o�:8�}�3��Mo_��U�=�}>oҾM��� ��,�A~0��d��7ר�3�%q[�!I3F��e�^�<x�(� W��Гz��ua��3�a��5{��gI_�[�j��1�IR1�L�\���u~�'(������C�a�E�1&�G̥ۯ�$�|͆�ۦ=�	E�������X���e�		'��xd���?�Z��&C�C��[�]t��g�A�=��)C�;Z���l��tnhi�\�+�^�f�-Ɏ�9d��T���lyVM��� �wZ	5���.��,k��sAxƧp��ڨ��ӿݝ*Q��Q����\��PYo)��l]� m)��v��*%"j����������&��9w�@M��{ӿȋ��a��u��H5� :a�$���R�@k�����*"D�]@�ŖA��}�pZ�1��r��}��D�n�y�UwPz4J�5�śm"����M�v�H���?�
O�N�)�S��X�P���P5?D�č3Z�3s�6.�.�"�Y� �g��k�~۷��udl�ɐ��(6�]Q��&� �5���s�́ۢK���?#��7�i}���0��&j��L�v�7�hh
�e��}2��ժ��wQ������G��)F��z�U	b�Dמ�~*
�*e��{��MR��(����5�wW<�-?g��
%�6s�D8��i��H_u1��� �:��	���F͙a2�d��C��TL�F���Ĵ((`xmxy,"-�}��W�xr�nC�������=m��?Ot3�������V��sh�3��X���N������d�=A�'�BW˃ᇹ�wo!��"A�R]a��с�Ha�j��H�\�Y�dudO6j�_�w!��$F|�b;ǥj=�T�q��F�%1UD�;�o���ʯ B��,�п�04�V?�$��tY@����H;�;V�����-[RhZ�dB_%�#`ц[uXm��ʚ���^��H��
���Y��Z�r15�Wv�3)=@��n�p�7�_K=!�ٱ��OQC�� ҁ�����S��O�? ��}�&a/���C����Jjk�[��Im�'NK@K��]	��d�� �gvF:�������k��|ƻa����"+WI�r���#��s��`���������#�Y���-�d��/7���Z�x5�T�'x�րY�e�,�i����^E�>�]G���"�H�9t��)��t�̌iXY#�2�?�ع-��o?��J1�z5��ؙ��r����X�SDOJ}�eyE�V;��2�Uz%�,JR-*����F��ൺ<�A���Տ|eK��!dk�f
2bt��VE�[���K�4NUՕ�|?L2�r^J�Tx�nެs6Kz=��3ej#ҙ�i�^�Ý?1���x^�!Xu�����\tf��hϒ:<���\�C�Ҕ���2��B��j�$��
QIap�0�y< �@;ʕ?�y�%�s'���leB�v��A�Q����������3w0MH�Ǻcq�<�#|)iS
 � ҤD�ZQ��Q6�P3���0��A\]PU�����ׁ(���PHf3������@2�CԚx�(�VO��tn(/�b �B�6�i��7֓WJ`K;�l��Ue�Jo�6Kq�ECcT����M�L��q��������ӥ���N{Gf���=���NVP��i���>� �kT�4��͌m�J��3q����<��zSsE+ݢ��m���sJyJ��NGO�;L�z���@�m=�A%5��;C䱑�oTE�r���Ã�zw�r�0ga��<�r�lk�xr 9����z����`@o�!�P�.;0ޏ�N��qf�k�,L:��(����ͳV��佖�]r;�O>���͹{�4n�_�!�ଉ���Tz����@���JX��<yrl��H��].����nL���d�Q�75nC�.�>�p����u�i�m�o����V��P3����|�?�q재�&���Q~K�d��-�k��Jx�	�E�^�H(҉���
��7e�0JO$c3���B�{���E�r�<w{�������E���d�B@���WR����`-9[Ex�۾f���&�p��&��N5;}Zֻm�K�M�չ�=Knb)9��ZE�:ݳ�	���"d W�O{�ԝ[ך�7V��_��Q�?���y}ύ����_�{u�
ä����Z�\\xu�B���Z�}q��N�C]%�2��j4��b�)���&�y��Ȇ�(���e[�<�X����S�XVk;��6|�� �C�3�P�T�9����NE3�i�GZ�?��4R�k�c#�-�k�5��O*`;���4g Uzt�4'oy�����&��wn�Oq+��:�.�{ˌ�J�?�Pys��K$#�c���.9@hF��?��_�u.�T�s"��}�6�ʻ���K¯���D�VO��[�9�VL߭t���7�O��џ�H���^�;�1�a2�����H�!)]A�qi�(4>�\�m�j�r��c�9V�k���7Z�b��ѕ\�.�8�E�!KU�`�ѳ"� ��2+^�Gw�A'���l������Q挡��9̚�鱪��-�J��5Ƽ�~Z���S��N��VjFu�@}?�-N���kF!7���������'#��G��cj_�n�V`u1,��Ѿ¿ݗ��G2})LJ�B�o��Dr(�Vg%�����qnH6�\<M�)*,d*��扺���EYK�Z�)10�_�φ?]l�&��`�3/�٘.�_��^���LV��m�c`_Z�J�^iU����6ͧ���'p�
���KSl��b��c���6�3�wJf��qw!�d宴��Ѹ���gm�G ��t��vc���yiw@�y�W>
��Aʑ�C嚵֏^��9
+�����9��lH�?��B&�����<�<�7�.���y�f����O*C�ꆞr�!ٙ�-� 8':Yj���me�v���Mf��H���GB�˭��ȡ�*}�V������.�:8D��L"Щo"kp4�ȖN�\O�_�	9����A����ыI0�!�RQ��$<�1���\�c���o�����I�^�k�MZ�cGTK��'�����O�1���sp��%�ĸ�N�^��e$Y�
?o,�
��z�����~��ɼʪ�J�}�}E魬�������W��� ͮ�4н�S�9&��`���D����l�nzh��~/�3:�#�2��{��\��2ϯ6u�(ʲu�j��Ri�M(����e��0u_�3(nѧ��?�Cä n4xE������L7�
����I�F�Bl۴�ɡES�� F�ڨ�m��5�����v��NS�Tcnӧ:�F����Vh�`�s����rgOL�%҇� ��U;��w�����MV	˪���y�ɷ�F�l�I~_F���I��s�nO�ʡ�����[7��[
�����etgMF�L�s��ˡ� 钷l&�}�W��� ݹ�L[W�7E0hm9�5�U�� �cӸo�������-��f
}�ɉ�|�
*���p
��Η��s��1z֬�}�y�h ��< �����Tf��^�]��߈�F6���G���H���j�l�!��!���[����)�P�ַ���un��?F�g��[��^�����S ���]�~)�"�Ĭs��`l&]LH)�P��񂈀�S>��P.�E=k0S�RJl�z�^�`�x/��S��
}�^�T��rL���9B��i��?"��_f>�C���7i�TK��/{��"�zI�6E�������w1�;KS���t�<(�q�3���}�������Ur��U3
�j9�eBZ��:�A�<��ya�W� ��ק�cX?p�m��I���Ch��\:6���bמXd�8���a�Nd+�H�d��H	\�H��g^����3�o��!�	GZ%��Ҋrֽ][ A!ehPu� Ӟ�K�w����`�I��1�L��}�2���`�<I�+�ˇ��DV3g��cVc��Q��
�����L�e�_�j��M�`�����#��Ã��ϩ:*�XǼO6p�T��
���X"T"qj����VҜ��S�r��͓yP-h��琎@{P\��:�B���ã)͘X?���lf���^��4:&�����F�Jv^��(��rZ��)R��ކhNF~� ��S�����.��[����~�!2�HL�1	�g}O�sloHߠ�Yz���������@��°L~p7��W���K�A����]#��ŋ�5�!�8:b㐻��H�� �SnH��sQ�e_�DWZ�Y�
,l�ϸ^=m���W��Wq|��¥�����I��_/�����������W8�Dg��:�7nGE��I}ȇV��sP'r����S�ӦCkݭ�g$�?(�?����̀��I8GQ��zHꧨ�Ë�����8��	.�1!s ����DBy�da��b�C���>�#��K�Y��*ศ�EZK�nrI���c��(g�W���
���*��_����V����W�8s~�@�J���� ��%�>aօ<og�����C�]L���I�~ۘ)��oy�X�o�!	$(*
��ۯ=!��*�G��ST�$�����l�~j��3c�23V>%46�/��Qёs�?�Npӛ��?-�6�m���6�v�X����3�Hf:��.3�/H��C(x�\[�J�'�i;�������w�2�`��ێ|K
��M�$��vD����\�T\��r�:�S���!4�t�mq�l��W�pF��Tna�`���8�t��h�??�e5��MŽ]��������.d(p�Q�Z�Caٳ�������6RRS��i�P�Y�	FRp*�(��Vcy�q�ɓ }\ V��"U Y�f�a�[��A�b���*D�^��'��"��v o ��q2ڡ��KC|k�sˮ����n�B^~���	���X�Vi���q�QQ�~���zs�EƯ������:?�I"�5??tYe�#-a\��#��I9����N�h.0����JKr�(8Ɨ1�����ݳ�x�j)|c�❟��i���2��l<�/?��_��( C�K�<>�"//����@���P(X� �ej5��x��>�B�air'�!���d���
2�4\�X2�I1(b�Hԍ3������nWj+Mи��cS�؅/�O����s�A���j<F���	�N�t>��z�e7>���0�>��{����|�(�������6���&�_y �j�T���1&�@��e�N_��+�Fۥ���1�ؼ�@;<��O�|���7�)̎��&3w[.�����{��@�� ��l�W�ާ~9@�9��c����h�hC\T�����
Fe2d�oz��5�.<���`�@ �ei����LN��#_���^Z��Tkl�W���8gÆ�n��'�%J1�~��E��b��iJwVk�>2;�
����E�D��S��Ib��s���?��c������L�J[�Mn+S��ɟ�92��{Ъ���YTWv��Z���-,�[Bw�"�D������"ݧ�9�8�ڐEP��ۿn��I-�IБ���3RI��^�y�	cfw�G{�t��|HG���te1�Ѳ�(��K�.�f�M�ukw��y���F��t'�V	]frc���\[t��O���D`T�;�/9 r�����c<s�t�&�:�{7U$�H*D^��L���` �2��T��ƃ�)�%:����~�������*jN$,�4~f��5o��v���O�V}J��;i|��5�Ӑ[�P� ��]��9�oa^6��M��24�/�q����~����%[��"PDϯ[���3Y\H|3�V��U�ɿ�5�M��T���s}=���cu���`�c!ۛ�8+	��<��jHK>�#4���!x��0��v�|$G8U�/��[m,�D�����2hۨj;��W��BR�wK�����[x�q�L����y0G����+��	� Ʊ@���/Ms�����o�L��D٨6�3��Dp��8 'c֏À�y��J�0k�)���ۦ��A�Q�d��0fyN֫1�^@�)�x�������q��y�)^�V�Dp��M�T�� ������ʜX:R���>����~�a3� �ވ#T�@,:�r���u�Զ�F*�E�S������x��L��fD�z�<$�fסY2��v��|�� ⑭�b�~\3@+�`��HX�{���|WLČ�����{`��99"-$m�l�w��5�/T��M�Pr�����+!aړ���W���!w�@,�e뇓ݝ���'�~`F�+p?�j�0l�~�e�0�q�����^�1T�E�B�'��ѷ�M+j}��\IV�̧�{����25>Ec�߹2�m��Lֱ����O���i�ڇTk
��@>���� k�>��/�0x�Ү硫C��>����.g[9L�����z�aȝ3�]��u�[��=0/A^���p .�2�h����[�}+t���,F&�GU�G<f�z� ��P~��E�NF�_}r�Rs�BW�a=πOR����k(�m6��J��Q��l�`tB#�'����u���"����m�Oç���c����bn�GčP����[6���rK��FT1NP\�r|۞K`|��h}?���	p���)��bQ��4~N�:�WK5}%�r�i�rUdz��w�윓�Hu�n�e���AB��
�K,Mp��)R!���//�]Q��u.��#^Ab���=o�]iś��hO�����Z
͜������S�<�{r��������P�j_71�y C���7�#zMK��i�;�S9���5�=4uX�nK��m}��뵑.����D�ϐAqn������^�<��|��~��;�LnM�V���w��x+g����ڕwH�ȵ���Z��=�#�{YS�.��S�W�L?3s�����Yb.y<	=f��M9{C��] w|h�F/5��u�/��� ��o�3�󊾳�O	a ��zR[�C)A9>�-�Xx��o�NI���T\�L]�x��6��3��n�+��W	1�-�D��m7]�������!J40�6�Gt��Rߛ�ܢ��J��شr�<�m�rfj�x��
7�bc��*��l���I��%cgص)�����	��	P�X_���^u"
�[\A̦b\F]d�*��l��DD�,q��o���-}w�D]oo��o5��.�M�����y����}[�]"Q�m�yDd���9���i �B4��4Q++V�q�RFt��] ���hYɧ�~;0偏�K	���m�[a�D��m����[Pjǀ��Y���Q}���%��)�݄/�8�8�`����ּ���,2�i�p��'E_K��!�xڜQp�A�W�y��Xu�Z���.�y7`�M���$��	dJ���8��Q@nL�Ψuݍm	:�rL&s￝�iuh%��O���f���I�=_��G>5���g3��2��f���Ka���|O)�O.X��Īyx����W���N4r��Bk�������$�LQ���RD��>�)�Q�chQ�d1(c�t_P�\�d=�^$3^kg�f��/ˤ�<ă�WZ��_Ьᗪ��pYP�|oȡ��|x���2���.���c�n=��t� ����O^<��Bf������{H�27�NOfL�̗`r�vQ�<<<�i�==q��ZWR���JX����'��OD���\�J6��vu�19�J��U��G	RZ Ⱦ�e����~�0�(@��^�]"�����m6��7��h6邸��Lɡc��"z����N�;�Dv֘k�����T\������؛~�Z�����쎶�Ƀ�W$2嗜@l��H�׫3�u�X՜��N�9��O�� l;*�@<�.¨fQ����#� �1��撓C3���{8e��"h� ��!��\t
��}!Z��T���9�Z�;+�h�!�����;E##�#��Ux�uܮ�9���A�I"<�k��	�}��NJj	cl�4ّ������W��-_���<�q�����dO�t�����8�CP������b��iT� �u�S�Z��s\э����Jڜ�&���J�� ������)(;��u`����z+͗�(�
��Q��X�jXq���)��}]��·��Y�y���1����HD��pD1SLn��CGnk���ݯ�##��oة6i�l��;���5w����O�K�[ʪqy�1lO:Yd�s轍�a�7��XX���w�X� ~:�C��:�B��Ww�oQR=������Hi��V�%ľ[��tYAn��&��",t��n?�-T�O�Dt2DFY�%�Q1� �xd_\�$�߱�R8���x�>�q���r���dc(l��X� c�#FZ���ց���D���[uW�� ީ2m��W�c��7�2�1��n3k�^��LyS4���V���(��'�:X��k� �8�>�8�.�s��D�2i���
��e���q����m�����M��с�J��z������X�i܋i�qx9KE%�-���r�@�1��Ek��j�؎�i�]��R���\��|� r�U�m�<AR�79��E��M�qQ�c�~p%3���<���M���r�l�E�U���Y�LC�i���D+��k�$B��O�E)jO@�n���GMGد��?��]�����f�W����&�KG����'�J5����ی	��dc��'��V����~�)-99bF�v�Z��af��m
J��R���ϊ�o���ǉ'�7�����XF�����r���W��+�m��+����bX����~�l��ғ� �R�9iS�'���`A�+�K+���xZ��w��j6�nq��QxlC�s�!���� ����݈ݣ�~�u�֗�<pe�43q�Bd�X���9:�nߛ����R�`�WI�oTc�N %���G�w8 a_��*��1N���S�3�^�n��=(��lQg���S��E@�`B�\n ��JJ��WMF��ȴ�X=��uݝ�������o\.�4Ia@�J:Uz='M��_�?KEM��1�s�U"�by*Ov##<N�N��$����~B� |�E[�Ud񧘱����}�����[M0�J�1�NU��Y���!�1L�`��V���9����2���LGo��6
�x��1�;���
��iJ7|�m1�����,1+����C�t�SЅ��OC����W��[{c�cEI���	�uCg��M`A�L�QeK�àdA\�_j�c��h	�gs�:;�B����"��[�ƞ,/&����U���to�XO���S�Y|���� �A�b#]�������ۥ<нz�P�B(�W��W���*_��"�M�B�__��;v֔�N( �g���"����b�q�\�ڸ�"�&w�\������n�`r0P��-���42G#]%b��OۙS�;ů01.�����}&����[�N�r�o�H��;�v��߸�Mt�S�fˊ�ģ/��Ǐ����m���+�'nQ�&[����A���0sMG��Ti'T�3�e�Ҵ��2����(,W�zڍ�m5���'�}���O�:�Hd�\O*��>�J�'�	�	�J=��Ծ���)� �h�o��V�I��iQ]�J�т����YSO��X����e4��%�:���s:�h�ڹƹ���Ҩ�x����K�����rϧ�����o�<��vF�/^3,�AdwHMӴtx� NAf�z7'f2�B������� ��4Ta��|y�e�(f}&�
��/O�mmg��������(Ey+�d�軬��AEC�Zw: Ԑ����<����&��`ey��s*�?��Qqi�6a���)L���AC|�w2<��A�|��ӱ�/�=(&� ���P��	�\��d��|0 �799�{�W��������P� ���|P	R�LD'�TsǤ)�n�=�
�M7zy6M4n�ө�Z.; �2�3��~1�q�/��)w�j� �ߋJ����TV�~��Է��*1����6f��s<y��)/��?>Ag2�Lf#����3���o?�6W��H\%{�;�&�׮�/���	��~Rav�ҧ�I�j8��χɋ��.�RP�����H2~���][����d̓���t(����=V�����ߞ<?Ti�ͽ�_��d��f	(�޺�5��D;��tP�E ����+0]̤9���ܚdo������r-x�G��AW՗��0e�6���mW^� ��T�2�
�ST^��7佼�\���ܧ�x��f@Us�A��}��aWC�,fQf���� +�s��\$A0��=��½�к1U4�z��:A��=jn?v"��p�wP.s7k�[� K!v&Q��,�^!J�u~"g��mZU��4��<K����m�,���������z�8��_8�,%��$/�_�82��L�~6ɹe꫈�O�[��ӕ�o��b�^\����u��n�=kG3�2A;Cm0,o��t�H���Y�<?���+�n}�9"�	�́]�k7��N�R-6��%�O5��׏���~����[��$Z����1���$to�>�%$!#����$�,:��]v5���>�荾����/�|��P�%�N�]��7	��I9����K�M#�����(�t��X`N�`UJ�I��t	̀�<}WL1��c�.*Z�oR*�MM0���Gcd��H��w>�]܆<��܊���Z���V7$�����5�*RfS.[	KG��6����R�B��ˏ܃�NZ��!X28�>C��s:P�T�|���'��+��U��P##�\��kz�7��ӵ�m�y�cܴB��r�R����a���p;I/I@��ZeP��]��<��l��ۈ1:,Kf
��ah|�r��_g���e�
����e<��l0�	�w�m�U`���nn#������;��ؐ�wl5�Q���Ǜ&�)�0����4�z�i�ݔ�f���;!b|��u��������
��6���Y��;�����ɏ�e{����ޙ��H�\P�w.��?��I�eV9�砾����q�fH	��9�C�9ϫvs�/�hm'�?�[�=A�8c��_��Tޱ��$]٭]q��93�]RY���.��}�p�s��K���;:V��k\ouG��Ԅf#����E�+��F+��b�ps��/t�ʒ2N�O��*������,�f45��ᗨ���ܥ�"�4���>`UaݥP-��<;ꨂ��\�W��k��xs� 17t��y�#x������Hb]��ò/}Pq�aB�w��.��Ic�n=�*�Y�9KaY�x�����4ٔ=�E�ͺT�8�~�,�p1�V&K����>������y��
��8"�]T��p�>�(��?���Ֆ>��zi璙+`վBҿ,F
�V���T!m��<������Lfb������Lr������o���F �	��l��|��>��ې50L��tR,a�p�mJ]�i9%|���׉�-�����v4��҈��ڍ�'��3al�R^���ף��y*�k���jQ�~|s�p ��p��%F=��҇�RB:`���f_/@Q3^�l�RU�iQ��C��K#S�;��4����̮��\w�Z�a�7&�lA�QW�)�Jrq�7:Db+ާ����Ԥ(����شe�Q����A�T��^pk��7�{��mh���Ҍi*���
�
+�ăX�-2��٘0ZB�=i[s�	W��v�@7���߭�ƿf0���_�D̻��g&O�
�3�ǙIw�Ok�tE�q�?�0݃E��8E!1��֫�3�Q���o�<kc��u''b� �"a���߅���5p� u�ZU��:�4W��d��0�� �'��>[/x�Y�����K���{;�7�c���7:P�\-��,�����%L=�7%�T�Z���y��8x/�Js%�.6��mQ@��;�����!M�\�ňVz�������.���&��N"3;�
�чN1@�FN�&t+�6n	U��Z ��	ٴ����N?�7A`�ď6r����V����i��|G��۬E(kY�P����üj	��ɥ���\�#_G@{s��3>��ڎu_�|���s�x@Ex���CUg{�yӫ�auڅ,��u��*�-ɰ��=d�����=E;�v-��`���Tn���+������\�+nr���ϰ5Wkq~�L�Ч@4���VtF��*u���*�m�/�� W���>K����"P?�-����m�@��Ɍ��(�1���7��|���;XĦ��U�ԍb2�{�Y�������i����a��T/z?�9'-��q�a��Eix)^׶P2�ϵ�G��}W8���4���7K �_fu#��,A#>vZ�#��W?t!�xCS0H0���as�����,�1��t�-�=�D.fL���m$M�����a�i�����J�e1�����do�՝�#Xq�f�J���G���\Z�Y��?�����q?����L���Xj.��̚��1G͠Œ{GRhn���I)�O<������xL����;����X���^��jo�5P}�AˆaX�rߤR��s��ȉ �G��>����B?���!��(?����CO"��r��S��$iE�\� 
:�	,�WWs�W�x"ɋ9�zX�٠1Ɣ��F���Ae��k�w2Y����Ixi��L����/��A��O����sz�Ԡp�7�Y������D�KŎI��D�U�/��1��� &���}�F	���TGs���N+O�!�t�8�4z��"�O�P񥘯��~oYOۏ�Y�]]���_`�����N��ɍ����^R�һ�p�,��1 ~��xC�])
��]�>o�h��p�da�.&��x��e�b�nH7��pGf���R"���OE+K�w���P P�$kd���J���>�������"��a*�!�KA__�R���	�d�M�o%w0#������Z=s��P$�:'~�[GW[aКU���mW��- 򫁘��d��[r�t�T�c[����CX�]Ŝ�
�i
��3�2�#�-njتa"Qd�w����� �pG�Y���G�l�ũv��㥷#�Ф �}!\1)��r��g�v��Zֵ#=�K�5 �x�*�D��Á��'����W�T�~'� �����Qz��m�!�^n)<���o�E��u�T�x�2�CU�^����=��@�
�@z!yJ��-2h���4��"�PS�=�=S�����I�ke'	��4��Q�ݍ���F�jȕs�na���)I�0?h_ ��t��s�A���V6�fR���]hq��!HH
���	屯U��+V�0�v-"B@���ˀ���=Z+�,#�Lu���D����vv/��P�`�9ucI��O��Z�Q����*����hUFb��/��g��ŝ�k�>:q���1�<�sT�&.�8X���^:3���y)�?
��HU�;�V)N�~*��,� X5�a�, J@
���tU���W�h�K}[A�##bÊ�P=j��@�ȸ0j"��u�G1�^�M�(�AS��&�E:�(�\Ǭ�j����Y��` .�7���!][u���q�"ӻ����7��.�{��r�,aY�f�F%�<�~���#��� G���Vͬ|D��$�F�����B��X�~�/g���I��ܨ!���� �V�=��8�͂Y�<��RC�В���,�(����:����6���s�)���~�N�M�b�&��%_����7d�To{���"�g!DVe��F�����N�*Gt�A���O�Vt�Z
�M�Y[�Q�ސ�$S���w�{��op��a�5 ���D>�K|y+|��mx�a2S��_�F��/z���ۯ����s@1����'��FE���u�2�UA-I��R~u�d,�(OfW=wɴ�/���0�m�]�'m�#����~�
�9��b�jt�uɩ��mA����L��&����٘���uF����\g�ocp�O~^q�o.�uokn�̬'H��Y$d�L��X���2cF)��茀F�� C6%�����fY2��q��H�[0��8f��C���6��-*;t#D2]��U�?���Ŭ�庉��hH��of�^�����i�j�iph^^�i��N���#';(��x�D��mR �Af��6B����/��S����򤿴�i��MR.m�	_�&W���-S�2�͋c��Hea�N4�x4��%�B&پ%�J$��N�Q�Vґ@̙�-��Xj��-׬�~XӒ�\MksQ��C3f��추K�u���#~���ئ$Yr��wn
��w��<�AJP�'=0�DF)ko� �*\�)��t���%����
���#��_͜r�P�F.6�DtV���� N3m�iP#��>x��3oH8�Asf�����C��P�@��4�ǍL)���M���&�S_�U����0wO$!_'BQ��ע�>��I7�͠l�Qw7V?ܥ�� �ޘG�Ȼ�+��������8v#���]��əLq-pe�9��qa�o�yW[�ᰉ�(Y�X��)슡R�;D}��_f�g�F�Lx���bQ��	��IP��<�=4̎���T��{����F����pj�vW���	�x�Wʂ�Y����|*���:&�!����@�+��.x�A%V����Φ2v�Y��穱,�G�m���
��u˷�04R���:��z��ƅ�;*~�2>�/�'p|�D׆kZ��=��$��,�tiJ��f���@�-S*���ў�����#�3��TA��ut�BШn֗'�ҏ}f{����-�1��F�D��Ү�8�w�1�PQ��u���v��u�-B�e����V��B� �h�#LT��
�RȆ���e�W�.3�R��H�A�Е�;ǹ�/���W���.��ف�!��`�=���J��,�prvg��a�͉�bQȏ��]�I��H��Fy��I����@�Z�Ҟ��|��I}��=��������J6�+�d�G�~z3>���/�e�`H�0�T��j�������֓�\���m*���Q��Y��H"Z�`'�� ���rQ-���5���B���^8�Nĭ�����?G�Ɓe��hУ\+����{�J��ݦ�{�Wpv��Rr�?���Յ���(��г�G����I)ɑ���۶F/'�^"�������g��J�wz��S|�}좵#e ���'����Q$0���qʵ�XJvfmo=���B`[��8�0V"�����l��͋�QC����yH�ic���O�B���^;d���\��5��i�z��z��J$��י���؇���$�j"q���	H�M&���;��ca�S ��7X��C}#��T�M�[@e���S��׊ct9b��H*���y	�Z�t��y�F�%�2�j�o��ȟ���m(�-��C����R��(*?z�1o�t�n�pH�;8��Ќx��:�����o��J�@+�]�O�g�[�~g�Ų1M�aWB}��W��F���Ƹ��c�F�~1!�"�E�,Et�L���V����c��-p�s�0����n��=�6ZɩoI�r;w��sOn�7w���9��֥ww|Ҁ��Qث�ݔFé�%t����� Ґ`�{'g�[�r|���u��5Y��`�\�K��~���U�J�V�ؤ��
qr-��o��oW�Ԛ�t`�.�<�0
i����(���������]��02�N,��LT�v�,�ڨ��A%�
��r(-΀�O[ԡ!c��6t=��J���?&O�ޞ�a��5�g���꺔��p�6�A	DF�.^�JD�|��-�9�V!�c��y�Ap�KՙB�D8����<yTΙ�Ή������w)���N)1��X�֖�6�,v�@�����r�(�W�3����LF���a��6Aȍ�ϩ�ۢ��`��y���Eoa9;.��n���moj���7m��o��/��@0<N�y�;H)mx�M��E�9�� �J^/{c�\�-17�6J�;ǔ[>�����(�~��h�x��1�D̘6��i�>"����`��k �	)�ʖ��q��{��Ys�l���G}p�EQgg2&�: ��w�Z�B�k_:�T�1V� 5���y���.R>K���6����?�"��R�7�1��>*F'Sn�� ��#�?"ɜ��-'���~-ʈy�����9j6C6��߆����H00���A��o�>�̮�>#U�g%��Xmg0AaA�[2��p)�k�˻F@I�+8!�ד.�M5�8�ȯ�
`�� V���Xsէ*���^ޭ	�u1C4��k�
C� �2r���&��<?�����hҬR`n����>�M�tg7Wʘk����e~;>,���E�z��p|��q�n�qFPmmЉ�|8r��d+,�b��@		zFT
�:S�O��y�T�!
IZx�O!�<�1���5^�ʳ?�B��|�����r�!c-���b�٘������� �W\6"�� (3[��j�7��~�T�k8kV���9�{�����K�^�ň��A+�;h�l��I���0)��0'��D�r~���Ga˟v}>{�pp�灔�W[��4psf�,�N<���D����rf�� /��)�ƷJC$$����͏Kl�>�������[l�Y\X15Ɍf�f��K�����V�8G1�d|?|�G:�=��\r=�vV�@@y0��`f�N��f	�b��]w=�,w4.g ���8���U��Ҡ���Z���a�$皥����v#vm<
�>߷J2*Sa��A��rr4�a0J�|�N��ߡ�g��|����W�G�i�c�� �r�]$M�(nB�*[,�2��]�h��� ��o��a�f �Ah8�BG�A� ��?O!t���(��u,`�e�ܘ��j=�B��|����;�� [�/��9�[5=~vVQv��x�E�Fi��`z�U@�+6{23�SA�b9Q:{x�4��N�}�~s:s�PgT8�Wh�D�T5����͍��<���1((á2bם��[;�L�_Э�Lh�|��˯��ݰY?�k�~}�Op���)|�`�:�肷���n���'��S��6�l�d+M[Q�Nn9ھ�� I4qPP�D�L�D;� �(o򣴘�v���jO� &�5�����5�p��w����1^N�ߤN��7A�ջw_'���gGV����Q'���ø%&�;b[�:/^*�4@yzA�\g�ڒ��7�7����D�`����:4�P Hh�3k�!�U�k�iW_�+%(��0��+^b�h#M��m��,$�d�qQ��Z�[2��� ��"�-�҉������e�}��@C��=J}҃D���
 �W����� ��P�j�q&j���M=H����!\l�8���,�ȋ9��L��:���_wl
WEC�����Iƴ�0�?������z�L=�{�l�}[y���x�.�Qث�����3�������E	:I@I�'���L��f������,̤s��:Z�ؚ.��{�G���L��T�x��	�5��&��<����怙+�3j|�sec�9�����|@��' /0�������Y
'V�냭�-���c����;7}~.�X�$���ñV����4 ��l���( ���ZX���v�)I�s�4Ա@�n�]o����K?�_�J���<�ş�Un�&��b�غ��Jv}Jo����:��Q�F��F�����|�������%:<�/�"��<���<��0q0�(�3fO��}��%�������C�{cn��J_m&�C �U;���1v�V�܀�?�=��$f���Fy�_,m���D�/M�QuˍXv�`���P�q5�L�B,����0���m�0��I����Zd��t�1R��8�o֝@�/l���(���U]d8,�@���c����'m����Aw���o V�Á1���Z��{x��la��Sf_�bYZ<�f[bL�f�2jI�AX����V�ٞ����j�V�Te�<h��L��]�5������w�9�Rs
)̼���P�l��^v�Ϧr	ȗ�7�k}��*�!�T�}d��!dԪF�/�;���
�8�� `fN��	r�z#X��3�V�e�7��[�>�.�%uV���$�%ڼ��2�+
wV���e�l'E�o�6���{��1�LJ,�b �A��J��|L+hZ� X�8��=�$x�#.eFIQXf�7�Q./{:�Q�>��6���ɑD-�! m<}���ݾ:>�S�X90_^~C��h4�'�R��7�����Ӷ��c�&[Qo~�%�q�	BI5��������:�X*�{�UQ�t�d2kj��j�����j���u��)=�5_B�E�Q�7��o�a�S��u��K��U��A@�>��(R�"��R�Ն[��Gv���`��d��E��Z�EB�N�9w�[���n�|�p�BREd�y��z��L\y�g�Z(�!-Qh�<~6��v4����?�p�/h:Lz�"�DR�O'��LX),"T 报c <�ր9���I.��&�@X!̧��6���2Gl��e�S-:�3eo���Z�>�1�JDI��%7�i�DJ5�L��;�����@E��N�Uw󳵨�o�c�TQ�����vK�H��X�it�b�lAޟ5A@d~:��6�^c�+7d���i��N�q�u��e[��� �g�%FȌ�a�
����M�X�"�ty��w���Z����%������]O�͕��ޭ��'��z�َ�ц�����6O�>>�Hz��P��r��}ot01b����ca�������֊���[�����`Ti@�Z.����1F|�qZ�Gz�Ѽ
�L�I���Ūf oR�Y��G����Ûj��)�����7��e�]Z�J�]M�̠
����u/�Hᚷ0GYi�)f��T(i� /"�=W��5��g��A�����XR<`<)��+�:|u5DrLG*����N�[���R���;Y/[�[
�~YMx���o�!_V�(�����F�oB�} qY�d6e��;�'�gc�ƴ�h���~ә|�?��8Y��Z�eh��w�p��1�^egؐJ���������[�[�OМ��x�e�N�V�������N���-zo���l���8hE��I*���}�I2xQ=ޅ�
�ШR�#�;�X�"H�6rRw���@��-@R�H�8�[���dOв�I�qz�&[M��R�jQ9OR.�ٯI��~�b��=�)6�yl�T��J�:!L����:"���T���q�q�~�u�[�4y.�]�=�8�tzp�(���, �鏝���{v�|�xLղ��Qlr�� ���j��J(Jf��tVW�d�#a	N�|аy���*�,<((�e��U�3w1,S � ��2�>s���?�eD�.�v�@m���H���a$��@�
X�s�٩^il�}�!�u�N�|Z/��J�]�;l$&��\̓���>^ʟ>��^�]����I�v���E�s�w�/��<q�W�dE]M���g9�j6���VL��zk�en�7���!R�����h��1}0�<�����U8R���7� y���܅]i�t�e�@&K���Y�j!:2V_Փ�@��Z�V�.��zuQ-��<x@j�;��4p��R���Z����t�N���0F/��}��LnXa˼TNs�Ps����$���7��3� �ITD��֫�=�U���9_�2d9ƌ������V�"!�o��T���	��t�R�Z����s�)h��EE�5��&gl�%�]����BX=v����c�7p�ig���~h����;Փ����Ϣw{	���W3����/����O21���� b��."Nb��?>+�g�X ��{�GXz&���0����.��z��#�0�r5�<�8/��~|)�sQlH���R�_��p�V!x�1��پ���Ln�!l0��il����/4����ao�f��,�BY8�
��υ��JS�T��X`�v��;s�6��BK�\����;#��_K-"����#j�\��n(���wJ��EqE��q���� #M䯢t��噭늻�{|8�W;���-9�)Rnq�($)V�Q1�᷄��1zuQ�}B��l.�s�|bV���X����إ�YҸ��L9y���S�v�6���Gq�|�ϙ�<��
=�Ӈ��q��j���+V���_9H�z�z���|��t�"��w_�
�x+����B?��ǵ��n������GP��B@�CHf����<&��G��~�8��@
I��r޾�O��f4	�i�r��F�'}�d�@a�"
歮SJ#=4�����y�I��+n87�e*��ֹMg�.�s�����e���6�o�4J�m(	�!O�~�	����[�Ha��$����J�L4[Ҿ���@�t1�q��;�t�4\�ף�q�3���T���J����z��TBԁ��}����C�����#(���l~FN%�oX��*HɌ�����sd^P=1Ǧr�N�'�[9>�BZ[�����+�PlF��}Ň.�l�!�)���(l� ,)�l�s�o�;�{{߰�U�f�#+W�׊r�*S���}-x�-�~��(&�3Ta6f��1<[�T�lG��B�_w1�=���*���2;�+q�[J�.��8A6�"��J��/v��JbK/O����TB !��9&T�k�*�hr~����	b"s�y厃��=�}�F�=�����j�i���AM��Ba�V�<I�f�ڿ�)V�nA��1�EϏ��{�؜q' ��d�B��dg�"��Q3���2|h��B�_�}�S�P� �J�( �Rjk�#�P���'�յLy����e��I�F�����u�oI�}9]V��D�:��t{:V)Z<�N�_U�d���]���D�d�M�˞Oe�4� ���uX^��:�;f[g78k?�8��|��4KU���ײ�(0p%{@X�1z��l�x� �1�y��!}nݦŁ�t��e�ٚ�����?S;�gY>���,��?�[�C�^�v �zD�`w10�K�����G��A��vf��|0��\wO��~�-�qd���Wz��&�W����U��f#�f��Ԇ����W�"�8��7�*�z�I��0!� �c\�֚i���t�������KI�_��ƌ+⥽�t� ��5��;��0�O�M	Z�8yo�͂?Ӳ��au���瘑
%,Lb�՗��oDEޭK���M�u������_�F}��G9����@+��	���-2a�}����c��R/lA�Ι��O���hP=��b��A��{1A����e\v�\�ɕ5�0�Z�T0=�@��Dq6�&ލ��t�Omɹ��⑼q3��w8P��̖TT��+N=��q{ٿ�R�D�SEѮ�rcu��k�Gh��w�=_l�Fi���~�tp��K�`�
��˃R�� ����CzԨ���V}�1��q",    #.�@S^~ ʹ��b��b��g�    YZ