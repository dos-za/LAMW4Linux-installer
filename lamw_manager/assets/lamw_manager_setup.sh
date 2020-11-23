#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1882690050"
MD5="3461cf7ecb631eee67fdc080beec4b96"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20856"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov 23 03:28:16 -03 2020
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X���Q8] �}��1Dd]����P�t�AՇ8[M6�OK�MLJ5w�����G��Ԟ- �B���x]Q-�����i\\���̩�
L��v>it\Fv��;��j�����I��{�:Y�!y�
n*�ZhP�����=�d�9(�!K7�|��o�<,�� ��t[&�%��H1!��M��Ck1<&������MJG��/�b�rD@�<��z�oU�`f�������F�r�[��b?�`�����ǸE�>�	�O��'ǳ�� DF�٪����	J� A�o�&��__X
� hMlį��8�q�!e�̋���ދ�s����.ܠ���m��p�hf��;�{�T�ɥ��H�Ղ��]V�L-�R����nV��3���/�H�;B��_⏕r�a��Z�_>��O5;�2�1������+Z=j?�M�?�����3���������|�y;4:
���T[�h~�E�û��!��Pk�&���"���6��Á�p�(�g4L�6��Q�6�2'ˏk��pzN����CxzQ���A��3�yu={R��L�5�����4����2��.�x�!�l�2���X͓!X���w�>	�(-qu�aW��jH�+���ŝH��Аl1�7f�$@�Ͻ!Ak#��*㦵�3[&@a��/r�*�8F�	"��m��6��zÎ�@��.j0¬�d��"�Ͷ���-_莰'	���6����nޤ�챙���vs��W�0f
��d*���:�-��K�qTy�^�	�7����͑��>�b���b� x�R���r�P@5�g�A����M��f��0.ץqdT0���JN�꼪��/�%I�6H��wB�6�
��F";�*z@ɭ�}&��`��I�"�8묧��[��>�rs�h
��ά�|�(z�/G��eF��W%*��=�� ~�>��6S�aS�'!��+���Gi�wz�4"�"r��C�)�P�N�'nŕe������v>���>��gu��`�3+�s=�gN�fK�]����,���S��I쓍9�q�'g��!b��`XҴ��0���MA'��M}E?�y��3{SZ�[� M��P��D撠yi;�y�gs��?T/�Ɔ��آ��e;�U��?�m�Q=��P±��n�[�z�˕�[j���qÚSW�gz���N<�>& ��o�>�e��Ih*W�{	ҿ���@�rS��ݪ���.�ܿ��_),���-`���[u�l �2�s#�d<F	���a�\T*��Yv�F=�IM���9�yl�r�	0���S�����1n(v:AK���1@�8	>��b%=�D���BjOUay�M"SeT0�����6cvnHv��ў�[����μ�!�U��L�D��2�20!�vSQ眧ǒQΦ�k�v|��s����ہ��F	KT��y�q�}U�v�׎׼��*��j��/�)�G�-]B����j��c��@/P͢����By�&�R�7u�`����qm���e?��Bq�W�e8��6R_�54����	�V�x�G4�ޮURݨC���b�y�>m h��9r���,X�J��E����.�Mڿ���v�����	r�A�v��EU ���H��,���&t��l1G��u��~�)���E��4y��k����a���&|����+f-�����3�Ùs6	���0g�#�}u?��(��/�_^0?$�y�B񖗶ϖ\T�1Q�	(�h�m�P�4��ʗ��)7��$� ��DZ��<�%���<߃�d�ʸcw�5.n�к&B�[�.�-�w��R�a�'��PJ{+-13.�-�����V�?�G*�͈�*�掸�����H8)4�y�"�\��~o��4+�U{:�V��~��Y�/q@~��R����J鯌�����O���'T�$D4�o�Qm32��=*�\I$d"�-!�V@���#�3�Q|�ˁ��r�$*�>ʵ`Y�F��.��P9L�؅�c]�z�և�h�D%A�:L�<�8��&�a$�yG�!�<S�����$��B*Ua�X��G���qOou
�f@󸢟3>�$�<�>��́��Q��O��TKE��6�3�J�(Z�������93�i��|{�s���|���r>S�a��R�ϟ?�y��ϔ�>�_]E�m�!��40�QK�s�6ڃ���8s��&D���6|5M�t9�T���M63#���c�xN����贼c������@���>M�M�z�x"A&p�O�)��uVh�ͺ]�7O=?8qm%d$q�V�Ʋ��ow�V,~�����_3�
�4���v&�9��&ޱ��m���S�lV"���a�S붕��%���O]�.��Hh�2pw1��h�����Z�#j\��$A�tU#�^��P�Vt^�w+��v��K�D�A'�ѱ�p�n.v���@�k� �,��8�>=`5�����BqT�#1�e,a��6�h����	��KQ2���h�`#�����>
$�r���|��@�⡠�/q�ǂfS�uD�LV�О�o�����z���8AQL�)]�N.�`�������%��9�!S��>'>���;_H�2W��]��"����@�L�`,;a	�P�֗�R��|�ԥ�щ$Eg�L�cx2�	CE�A%X���0��i�޺/��X���coC��r�[6�n��WS��d����9&��Qe�V^�밡ÝH#�Noy���ܲ�f�mA�5D$>�WF7���ΝI
i�mV ��Yc��N��*�Y$�-�n�C?������s:��燢x���T���E+S��K��B�e���5N ��S�4l�e�`���[�����Q��ƞ�D�nW�GP]_�-���;Ol2�����b���4��K��0�[L�S�vX�H:��n��3��*8��X��Is'�a\��>��I��`��X��]M�ĵ����oo������&�p�C�}(�r����}�f'�?�N�@6�+�܃a_@rݍ���@�9���� j*#��e�~`dd�j��'��"��+ܼY�K�-�y�9_@��2�1�fU]�$~C�2~X�`WWM�@��|�`��=���W�M��y��8B88�T^ף�<oߑ��{�Ҿ�u���4Ɓ~�r��B�z�*��*�v懄���id�Ws,p+V�}E���b8�-��zc�Irb�s`���Et�Se��	�J�w�����7���ۙ�B��R8����}��ՠ_��u����_Z�m�	�3uS3�À�������O���GB"8�Ƙ��tn��SW{5��`�t���KoK�Ø�%.���%�/�K�TB�Or�߭Ƭ��1��f�X<
,��r�^}�@��@�����#5�ӫr}���Ba�s=6�ĩ��?@:��M��O��Y�rDs|�p���%�\���Ƃ��=����Y�E���:�6��c!����%�8^m����XGo;\�a	8%�]�-���) n����/����#1��a<��-'+I�D*��bW���߫�llNA��3�m��G�q�7�>����~��e1�)�!�z�/�L՞:އ�!���%��W+7�P4$��#�ʘ��?[�<�ON��_=��fG�'y=���������MUX�ߝ��+�}�C(���6�-$����zCjΟ�ɮ�O��hU���G�y���2{��䌞�q��1�{��ʉ�Y�� ��Cwx ��_����/�N}���90�����i��!dW�+�Hy4���;c/�p��?I�$�B#A 6���y,*��0CWeo��؞��G,K��;K��A��0���~�mmd��}4[G���i%�ЊK�f$ ��7�M�.�Bj�8̶��@J7���:@i 1���K����.<����7��ԟK� �Eˀ��(��8��j�`�ݭ�����hk۟����"cz�7���B/�#���Ka�4sG[�s��Ϗ0���H�ڻ#�[�q���|��~� Ptx�ywj���<����h��1�>�BS��a��\�s�F Tr�7w'��_!�E�gh~�s�]?4%�	�#���k��eL-ٸ�B����쯺�老 ��R##��X�>� *\I��M�Ĳ���$jkOKq�V�@Z9��k9[%2�
����:Uy������"��h�ޯ�2S��Y(��:�E����$��sC ��`�ȼ�M'�n��W@D��k������ �B�&�8�k8��ƞɉ\���Z�.vAFa /
��t`������������x�;�}�c��?���E��G2�B�@���Ӵt*#�`,Q��c�>�t��.<C�}Pl��Q8��r�dA��\Y�F_]t<ɺ��q�}���8�M�P6vC���^�����.5�2�����B.��b�S����Ɛ��ܧ���?()�6"�_7w4����޻㐣���m����`�3��t�f���lW��<�M"e]"=�2#�zKKl��xZ$g����C@�Q[�a��5���<��ꃘ�������R�e�#]���$�3��6,��X�b�4^��2!;�.��$<��*�GT�.���eX����)�䤪�1�UX�����x!�]��r�1�kY���􌞌��b@H�q�5Y�,n}H�J~���;�DÙ�g�|��EfY��n�}A� 
�>����K��g�q;20[!�U/s��0���'aD����Q�� ��P�bd��X�l%+P&˂���B���G�q�p��&�5�jTǹ���@N�l��:4D���~Jp��#�i�����NH�`���n�0��>b➞�x1K�O��Nx� α��A˵�;#Η9Ʉ��
*�ƿ��P�I:�hr�3�cl�˷��?u�z�hǕ����5b�)�������j��u��f���b� �bGK�����5��gHD�^�� ��t.���T��ac1�����/V//@Ԛ�5hT�0N�jD�6��9f<U�aƆH�|8q��;O���lů�P�:���P��+�oT4�ңI�.0�]G�Uem
3`YF��kb-�蚊�L�>+�`t�~����`��&:{�@��ZNb?�a���Q��f��pݤO�k��E�6*؉���c%_�>��LДCw��	v�3��ż5���g���q�xT��F�,\�u�s��Ӭ�a�)�W�����D`�g�xQ?��'��	+�F�Yu��#��[9=Y��5��pӔ|��K��#۠�*���\nG�`v��[Uy?4�ꇮ,��	U��)��4S��c��S.��z�޽�ɳc�"�B����i�9G[e���s�S��u�j[�D,���&L��������{�n����,�C���2�!����7�⛅�-�@�5kn5� �ӱH��BM��R%K�w3�훩I~%C_� �G� �$l�H�Mz�7��WOA�O��G���5�j~�z�.=)ɇ�N���%rz�{G\�� �$9G0ޔ�}�� w_sl��X��s]���=f�@�SI	.��mr�����A�g�����g�W#:��� J%��"�r���9!kr�����k�+*f���u^�}`��Q�p���FN=m1,r�^�����[�?��Wf�o��.��.�09�j�@D���ke,�2��r0y�H��1t������y�<s��6�42닇<�0�5�����=X�u��G�(�p�=�-��Zg���l���ߕ�hD������7���<�AN�F�O0�w�ԑ*��\7�P��uKLEc��w�E��B��0Dժ��~R�q����o�0��~qb�]��a}Ђ؉��68��T�`MO1R,	�9����4:Q�1'�����~���(ʄ���_�+���q�R��Z��>2�n����H�<�8��9:I�R�VRÈl�6iZF�"r	�k�l>�$����}`�9��y��\n	�)AÕ�9�G ���������M�mZ�4����"h��u�0PfӪ��U�>"���/V�2�SH)�$1����FZ�2��T�'/�k.].�rguo<Uu]�T��7s}�Sz�=�ܩ����MHe��ҷ��>��b)�y_TB��B���GwIKwE��5+R���P����R
�m6�WP]�^�3��]�����R/&Q�S���"B�G&��T��S�*�������L�w^H�w�5Q��7#�E�����]�݅Ɏ�0���|�qL�T[MGЗe�l��+�4'��r�����ڹd��w�_���ԏ��Û�����t/��.$�כ�3�&lo`���1��b>��v�̄���8��Ź���%��<S��!b��ch	�R�C���ЊQ�9��i@�C߆�:3O`�r�;R���\��g��}�a�Lu'��i��Q����>��~];m|�	����_�h T��iE��řܣ,{���E{�rV�����6��oI4��&��o�Qf�$�JIL��\)�h�T妵w����it���%���{��=�S8�P�h���G�F�y3R�'�
7XR{�:�FW�4��s��Ka��baں��]� J,1�!EG�k�Y�w���}���ۨX��h`�d鬡���*j���E6��o���Pۡmfy7��h1C�@Z�����;��t��줞�>�z�_�1^�����e��ƐYJ�2X7���0��GEx��DS?�m��Ue���P�B,�L����y�Yv�-�b^k��E�*��v�� ��H�%S��{�hb�tK��Bҁ�f��[�b�m::����<S쾜h�߇=y}_��@����q��k���y��o���\w�7`�����md��=� �Z�UcE�M�{�
y=E��ѱ�m�,�*�[d8�X�$F-�h�8���z�!Xm�`R��	��+\�R�ۑ?��oU�+�o��|w�4r�+Hj����Ώ�4f��hF��11����&8`�<t���k��%�wU��&/rH�V��P��u�@�$��_+9o{�ǞQ�	�1P�k�a`�h�,&;�v������l�\�g����
R՞f��T��H?��j��:u�q��5­}e�E�]�/��f� �_�)	�Х En'�}��Y,��ȼ���T����n����b�)� &�����>R����Oߔ#�W;�Z8��!"6s� (��ٽ��]!�s^oa��.�0�т|��]�&Ʃ|	�U�y-�#�K]Iy��	����ʃQP]��,~MF9���� ����i �A�7�D�������{z�`�C��Mez��qV�[�MgfWϣq��VEP'�L�J��4,�`0
��h�a���#Z��.!� �Y�����j�C�Z7���~~U������x��W��S߃�V�
΅�ST�T��̴�,/:�C�����4�����|��d��4���۳V�\�E�cF�0�o�9X�!'��D�F'��)}�E	/�����%[v�1<�P,&�˽�ll���4�f<h��zߙ�5/��x$�,�_��+ le�A���0��5o���R��K��N�.���֟�B�/�����H���x�a��d!�u��l�9s��h�c��e��M�� =SdO?s�E8�T�Å(ˎ�"��>5���e�"YQɏ�5a��v�.���S�a[���O,O��8]%�9�jbrs���+-�v5P&��k1vӇz>���lS�jm[i�A{rH�G���@0���ۆ�&���;�ǌ(��'+���wK��K���h�5�tv!����a���YHAno� �{�1�%���;nޱ���x!WȜ	��%�
'�'���u��P��cA"����/ֻڱ�%��������;X;t�2?C�P�C^풚Aϻ���n���5���jZ�F��y��~므N�F�n�Y�Hy��W�%H�jY����H���9�uH�2�����y��2��ȕ��J� ֹ�h��QN���zC��`��2h�B�@R�|��[ɗ)8n��v�WK�Œ�Dn�B~�{1R>��3��������������9��r�5�>� u~::��ԋ[k悦��N�m�b���3�DS
:0�I�tk�0���7=ǹ\k��o�p�(q��"�&�`!Ѕ�����>>���~�l:if�>_��]>�:�.�����$��L,�C�}cn��7�R��'��ʜF�ʰ���?����n��`���:hUꭠ$�m{>K�=%�zT�`d���͋��u���~��9�	(쭗$��-�t���!M9w�z�����x�0��q���������]�|����J���
N	�>Ǖ6:�-���*dQ���A�r����n��,ӟUg]{&��_0?(9��!�P����.H�̋�Z{�
�����=ɓ�VՊX����d��/�1�f@&��8��c��m�2�D� ��8�-�'������JJL�־�0��6�m�.Y�W������CsҌםQ��� �6�M��˫��?�@�nQ�e���H��S0a��9"��t��5e��C� E�ѭ��m8?��b-KD�w0ёݣWR��wk)#w�z
o�ev(J����{;2��I��G�^��(\�ؖ���"o�Z��n�J%+0.��(���v����'��H����n>����	�o���7�bJ6�h�=X{Է_Q���;�_o�~�����$��ta���h,�w�x�3�u��w�3u3�<�nvu�+�Ħ�F3�W���0wy�r�d#1�7���ݗ ���Om�)�>�E�y��+o������q��OilJ�g��vO��v��Y��џS��%��R
{����ޥN��h���sfu\�C	2��j�k��	�S#�w�T>�G�Ĺ��G�}��n�I���x�h��ª�][�Oi�-R5�_ԡ\+�DI���ҕ܄D�������c,!z���Z�*�'YLd_��#�J#C���cm0y��8����[�JN���3[lP%Ӫ�q�Ҕ�BF\�����g���ø$vz�%�<y2]?sr4�fAN3�_�y`+��{Y�֜0B-���R?7�
Nk u:��,C��I:S�/�P�.�d	�(O�X>�8{%�����9��IK���m�靄���Ѷ���|�@pih�e�G�̪��>�o&B�,��y��#�VG猯��G���-��ͻ���ՙ.Bwq��m����p�o[��c=��]B��0��_ht�{Y ���IR�X�9|��;_���3���
�E.]�+s��!��$�r[ ��o#ϊ�6)��z;[H��W>��u�5?ό��B�-	(d9I�JZG�ZC�Lf��v}Y��2W]�
�݌�H5,G��t�����˅�¼�<8L�_n'K�����|���s�]���Z7������.F��Ɗ�&J�t��Ru�[��T��M�%��⟐0�9 ����5C1��ucj/��%v^�B�, ��w��{�t�E��-)�46�nú��]�^k�	�s�x�2a�5QqMZ�h�&����H������R�x�c�qr�^��>�W�>�v3[�~���5uqTp���wv�Lx��<]]��C��"L��r�s�g���#�/�3Q}�Pșq��ٳ��!�B�w?�iȲ�6�)��]��E���R3��h�ݭ{h�`�ݚ�. ��74�x�,>��Du�y̿D�sIׇBh��I��L��,X�3�H���6���nV�|�#z�(s�"��k� Z<��)�Gk� ��h���̅�dd
Wo˾��^��"�7���0��3�q{�qW���7@`J0ҍW洷��v��� ��m�z�&��K�L�R�
� �6W����B���poe���_�0��V�я�p���
�	AX^s���H������o���қ�V�Oףl=8m�f���Ct� ������ʜ.w���D�R�w^���͝z�9Q�7bA�e�/`��+"N5�"�\��zٿ��N�-a���|̀C1o��><�����i.���:	�hª�[s���%�)�7�
E\��j��E43�=!�RI˫|,��f���6�V�p��ۢ�<UJKW-����C�8�\�h�ʍ�����)�R���&���񏀽�P��O>�R5�����l���xV�*m� �1����A��EyN�� �1��v`c�o����w�ŴE�&�e�k�q1�^��[�!1ȝ*
ejk��'kd�e�(�*� ����;7���|4%P� S�Ƥ��Lg0:�,�JQK�[_ X|¹5Q����qe<�59��k���Mr�r�5<V��)��0���yD�#��S5���;��,ʔ�����\0���y$������|���V���
�f�/�$�-��/r���L\��k��� ��2����v�1T�m�~;-�s|���wZ�U� �ʵb���5����:e�hlH�d&���696ڗ>	�ᏺ��h���^����_�QC����yb7��И�Dv^c �w�{tZD9�R��;a�p����!��;x�-����E->�4h��Ì��Bq�ZTj�hKo�s֮�Y'xl�����@/�z����<�I	0[8���rC ������
:.'t�4AcȖ*��B��E(�@e�%m�U�3��$V�_�kC�m�����QZJK���^��v�QR��]�Q^|kl�V���w�N�ɜ$wLP��zt~���	������5 �bs��eI��~�Ϟ�:�Z.-A?����؆����C�J�I�R�˥[ND��,�b��H��yL�ۃ�� �%QV���5�rf�U2S}�bRrNu��^1�Elb^9��_5��B��8d���*�$Ư����ź�X��嵽3�1Y@
V-��&X��ċ�ĴzY�6R�Vi\��,��YI�,�A�?�<sN� ��T$�D�@�+��7`�k�3Z�+�����*��^>R�-b�Q�;;�������p�1P�tB_��.s�T���o���\��=�e;$�3gT	؝���<U}m�[P"K��� ��E0�Wt�B�\�a����l�� *�"X��ɀ�|DA��(�q��a��?���^�I;�H}�.����eB�����R�K�@�x~I�fJA<(���Q�%����M�vӜ�.�i�4źp�� ���Y	��(]�_�r��u�8���v�j�M�yȓ{�L#�n�=v�x7�Ps�b
��_B{��gs
#��\��4ո��e�|��l�9�V'��'���2�]G�F�C��ov�0��l�`h�_"nߖNi�%�'�8���1g��������M4�톦�RMF��hQ�����ԁk�E�9ضe�;p��i+���A����jM�XR�Z�9�=����ogU�.�`�p���ɛɂ^�r����ҧI����Gش�ݗ�s���	1�.Y�#�D,)*]���H�xK�Ն[>��X����t�o3��b�W��q�hA$hIֱ,`�`դ����'� �{��(�o)2"�i��$��#�&�����0+�������W˅hV��C��1HXgz��v�i���8&}��z���8�Ô�#,�SV���N*Rz)��T���v&��2�_�{�i���j-X����]i�i�aF	-Rd"d܋<�{9�O�^Ж:��"�Q�鹫�����>\�W�ﯚ�ȥ��y���C��&Nx$��K�#cC�	�f@e��v}��2I�Z�dS
T�sh6�Ym^�}	bx�M�CÃg��zh��4{��p�_���,yM1񺇼���y�����*,?w�7����[��&��,��F8/��.|3mi��V���f|6���F�H�+������C���WX��?=�^��M�~?2�a��>-<t\<�����v�'�iu7}PU�� G��O",�����[���'Wc��`�#[���H�qp	;0�3��OG6k��j�	8m�I�~����{����kr��*�T���]��.�5�"G�dO���]\�\@k�K��c�:z�+���$�U&U�0�]��=���cO�Zϐ��f��ʟ4�F�^�K,���%���z>���E���3L9�Hp������� پ�w��/�r�D��5��_�4]|YZ��9KH�A��D��\@�4U<~�/����@�)�R�
�I�9���@�)T�m\<�-^~����V*cE�۟<�z->�*�B�Lj�e�ªso��D��l�胪2Ӡ"!��J��Ԭ|�i��/Ho���Yc�$�W���_�����A��Ӝ1�����gq�w��uZۦ�ڶ����6�p3������=t��k��ڐ��S��X.�pz�5�ɴ�c�����$s��|�-S�F�� �&K��h�5����V��HKx� Aw_g����Ej݈@ؽ�,�_���ٜ�%U�>D�(r��-�	z��<l����	?�E�E/�-g|�fa7
��Uf�n���D6�^\�.e�!S��>ܰx��m�Q����>͘�'�"c��a�|�L&0��쓧� ��=\<��i�5��a���fT ^+��
MƂ��`�����	q#/ؗ ^_���i��чZ�d"�U���ƛ�)Z��B��P����dE���ջ���n,1z.`��٩n�#j�����[�����S��$�DM:,�z�I�����b�uh�� �X�w����<�xH/���r�d�6)źc�3p�!��>n�n'�~�(��6�S9YPE��ދB��cK��g�!3���ݪ쑬#\���֍?Jl�E�m��y���d>\���=�G ����{�ď���ۢ=�z/�!y~䗛��i��6��WTW������<�C�����K��xF��'z��|��x���|�7�}��=�PE�/���h{&�R��,��J�b�Q�T��U2�:gĪ5ξ�z��Q�&�:���;`p;C�(&��H����'S���9������']EȜ�7��&y�cL�N���>m�$q0Kl�E���S���!�����L���}��I���DgتFT�IM'�um�s�i�fڥ��vwy3I`E�١9�p��	�"(���`W��à~��ŊW�Z�2L!���n+���IּB�8�-�rE1\-H�S���V`��O��X 9*�7-<u}E�24��f��m^'��e�%�$eEt��	���I�4�1�^��C��tP����`ߖ��JFmא��� K�1ND}���Y�Ԧ��@���y�tv�x7�n���U@����%t���%�-~*�@�����C��������Ҫ�UEMz�DTH+��ȼeMi��ǜjC��#�J0�/1f�(�W����K�AoU7��N%��� K=pq�JeaY[P�1<�@��^|�5s1}Ru�m`�Di�p����厉ĎF���x��`[���gКnޛasG��{������,��;�U��.ާ}�&_$���4�BP��BR,��划���B�̒�'�1oz�K��7��b|�>m�>o�,a���-U�f���zD��+3��?X�� E�И�}���6����1L!;�b�� <�bA%���Ѩ��5if�����H˱�YeE�P���*����n��m�h�aӒ��0���A�ehwd#�����ŮW�y�w䐾/[���2�q�͓�f	T�7�h��y.{��	�y w #!���wObZ=B���>�"���tNq82�T�����!}b�Aj�|h6:�D� B���u���2�[j�������k�*�W*:Ρk^�a˫�^�H��~�w�z�����El��ZyT-���԰Q$�����W�smOv�L�j�a���5�r�Kn,�W��/C;KgW��}q����,�Uͷ{������}��3:g�P��lˈ�'�=?%c�C��v��F�´�J*4�?�<'`��§�m��B��Z��A�vDZbwQ��NF���gc�k]Fsm��m�=��Ư�?��=,AJ�Ԙ�&Ef����l�e�j1�s�9�_E G��Փ��y��r`�)���yӃ�{���f�,K���9ϧ�?�A��I�-�q"MV�����f�����1�����ob���k��&���9��=�3*(8l`�[y�՘�q"��w��q)r��{x����p�cD��yé+�U��#���$�H�4�;�Iԧ�́+�3���qK1�aGm�J�Ƭ\>1R~��f"RQ/��]^��,�
��2�tmy��A�W�����}�͸��n���~+?���Ըѿ�v��@`<���#�Q�&���RK��S�#g,�;�-BaW�@v	`0�,��g�tĹ�6F��md/�P�Z��&N�\���Ar-G��� "��d/0�N|ڵ>��{_D|�Ps��b+Ɨ����n�����I�#��� ��{�af�e���Ҟ�;5�IOE�4^�'NwyN���9��r��uǮ�)���>3��ܽn��R��e&_"������J�N��%���l�R���8bɄ
3�#?W�䳊���ֽ)����n}�������
�k^x����dҁ�%�R������}	O�OG`�?�,�su~D|�w�F��a|�V����x�@'� V�2u�_��3G~m� ��tG��d�'u�Fu��X�Q�3Uf�Μ�Z��%�)n�T���X�R�I��V������l�i�%�\�V$f������_Q[*��J_Iޞ��� ����X� ��L��Xmp\�rp.ԥ��H�G)�F#� ��A�6��r#�6��2���Ϭw����D�Uu���aZ]̪�5������ڠ�PDзuo��L�W���yض��)#��v�L�~/�"&\ �����\� �@�Cx1(��k��	����F���I�� ]o��3!�"�K~��o���͆� oD��dr�ea޿�����Obf�rq�Sx�6�L�]�g�[�*�S��V��+v�Z襹+��(���D
I�$��W�F�!��T�{~Ĭ}���CR)7ሜ)���2.=7R��:7��R�Ur�W�J�)���.��h5Ӌ���N���aV:?���t���B$4S�u{ ML��g�1mܭ�^y�b���W���$�����}��&����8IED�P:��y�&al&�jzg0�1��}.-(��n����X������lN'Xgc�wy�2�:��/Yf7,C��!�����s��ͽ:θ��?���y��	9��nX��y�\�Y��F�%u
����������M>"���jR��J� �&���r�0��5,@�gġ%fa�&u��y��|�7�7�8��2������R�$;�T|;��f=8_��X����(�ijKW�|Rj���D6�"�t��
�lJm�!3�O%�T}��$0zEo\j[����p�|�[�p�M�ב�Y��h~�,�A:�ӎ�����=30z�����f�N�Y`��Y����V�����6�@ֵ�!�R �8y�����(jR0�{�@�����8����-\�ioXj`�G�ñ�#v&�.�0�͵����N�7ɺi����/�JGW��Ǹ��/4��#���,�U�D���J:3L���r�T�D�|��b<*n�Xtڱ�
�4�,YQ<%7J��
���Er}6��O\�r<7D�2�Ϋ�1n�un+��W�|W6��y�i� ')J���ڌk$s�!ٍ�x�g����ԕ���k"��ou��%3��
�c>�NO%/�J#�NéݼL��,���l�͞��/FH���#�|�q���\Q8ů�Χ%�&�$H۩���T��h(k��r��/����_�{���(��>��~���
/፹�łR�}<y���5ƒV�\���P��w��Y&kő`)5LX+e_�(���p���� �L�b
�f�=�����I�xO�#������������S���k�z�5ત���F�&����+�,Ȃb�4��D�F�T��n�Z�1��xS�#P�t�[� $70a�*.���ТN�\�������u��ԩ��9�7L��� s�>Uvp�'��I��l&#���x �J��3iJ�E�,qCo�� �hF�=5������t~�P�Y��8�C���)��4�Į;y��6��+�����_g��+��4/�0�>*�W6�}��T�r�ݺ��G�N���n5(��UJ��92�ηN��ND#� �0G�Ok�pw��F���}Rt[��i�)&V�s�s���ez��f�.�Ҥ�i����g�q�tD�%�E��D�5q26�W<H��.+̌�f)�q,L	op�m\h�A�I��a�8�ᬙ�P������m,����x���Nx�w�@:g���Y�c��4�PV�b+)��$�8� ��ٴ�>ԗM�Նt�8���#�u��6�B���|��/,�H��x�͕0m ��������������ǫ��a2��~�
�
�]��	���-e��-�s�y��ӿ	�\�ltМ����>��T(����U�e+Q�S�����G���t���W��Tp�m+=��£%B�.,��2d�����`IH�esO��f�.Pe"��?A��`�;x �Xmdi�=��!
� ���E�yC^�q���J��VW�%$�*y��m��FG�;��JvdO�����o	��l%�=�5wlƗ"���t������>h3A���8�S�|`U릎Z<����-F�n<�C/D�����/a���J3eԚ�K���	7-}+��}�v*�Ok�q�7�-_��eT��<��?��M�?.�8Z?���	�u8P=�{$��d
�p�.���3�C�T���~~�]���+}ȅ^/
󜕔��~0�x�O��-l�eF�y�D�iqc�qI��t�r7��v�̡��2Ǐ��Vm>����/�����	)��#�di�V��gh� ��y�nt vtTۘՀ_-?7��~V�7�4WX!�U/�yY����(^�}=�U4��5�0��N0."�H��Ԟ:�D�7ړy�7� �i֨�� ���D�x}v�s�o,�%2�v����1Q����?WV�wN��䑮ቕ�̵�����hd�S�[a�b�0�W���:�]k��
��!u�G��^~,��Ï�OK����$�Fy��0��%Uw�K' =lOq���z�WŤ]ƛ�x`�R��ӌ��+�&r�w	u!�𖟎�-V=m��JE������G�:�]SI��>�ܧJ��x0V5((Gk���"�|�Tn�A!�*�rPpR�3��a��c��q�.lU�kGR��!��*`uk|����>]yZ�-����0=E�l���Ʋ%�t[�A��-m�O���~���}��6�+J�U���<�����U9�CBj<��}%�ۀ+TXZa4��tr=���������y(��M��Ϝ��7�L���n��zL��2|渼�0m��Ӷ��}�F�������U5ՇZ��)�=����s���V�뭹,Qi\~�Iȍg�ڟ�Nvs�+�У�q����%w�т!�-Nl�z�T��߻��(�����啡��^Emi[��lKʠl�<6;i�y�z��g^�C��1���]j��,F-���� ��1V����C�4�S	~�4�]3��i%xng��P���X�B���GR�k�(��R�E$���&�S��#�BUL؀^��x ���Z����_x��W��<�b���N��,�йѤmf��,hh��ᴆ�*pv3u{�\}�sŗ��cfXy�5����lD����/���Gv�*,,u�bۆ�� hr<�e�X�)� ��W���|ڴ����zj�N��O>7  |sf�oRY�A��%��kL��uۺ-�˕&����"��^H���4d�\HfԎ����Q��3���eggt	�)��^`wŶ�g��f��&Qf�h��17`5m���Ŕ�QЬ̭�j��#+�֔�͊J<8��_�f�$AM�2�)�N��N�D����d6�K\���?:>��r��|\��NF���pZ6i��gהI^J�]��m�*t��J���� ?�~�2�;П���N�ęH���/�1��]�p,���,���r6�y��D�`2�Е.�����ʼ��aߖ�I�ړ;"�Czs����|�ɈS���튰�N����!UR��9M�"�'|��
�i�!��ep�{��R��0�֮FV]PMX$^<��$��M"Z�wr���W����I�q�N4;w���^z�o[��e�ʈ�;Ɲ� NzZ�X�2J�Kb��Q��*��%41�����>o��?L{������ޛ�Σ�?~hd�ϟ��	��dOӯ��֧��4*�)~��|�^�ʂn���	�,+��h-�^R��Ή��|��>u�cS35��k�
��i!����Q��}�̩�>nyze�4����u>�l p�%�\�)�$���ngfܜ����a�F���TQ����u].Qܕ��n��yRu���%��oI��xI�zqGC��E��y~͛�T�T�F�_1O`t��m76�eT/�*�I0�>���B���,j)*\C�XǨ8*��㛺|*���܂�����?S�=k�#��ۭ�>�U&�����U��m�!$��\U߼����+#�i��5�g1��`˪�ώ�0���q՘�x����P����Z��}�8�'H'�6�Q{�`��GY�h���|����*u�� "y��������`a_���,C��X%���F ��h��|�cSfn{ł:_�-P�@�w��cԯT�9 �*L���u�\��4Yk����/ω�J�B��N����COC*�&��
~����<��"�ɘ�ҟ�*��������)����;E�Ȳ2qt9X��S�1�
�!�*�A�Tk_Oݏl��Ge���$]�r�{Ʀ�Kz�a�A��	{gs�2:a%�_c��c��c��K@9��=<ZaV����:��]8�x��v�cM��eB����4W����K��y!����Q��\:���0؅.��7+�ް˽ħ�Jk��6+��t�>��I,��ĵ�"��ʔ�	���! �[R�ѕ�.�կ]\K�� IKؚ�e�\���hd.�q�U!��uԕ���y@�}i�]7���
��e�+��������NB�uU�^Ol�/[U�T��	풱jD��ď��'�2?(���x��d�C}��諈��%^�ō�5�������Q�����zA�t��sX���8���1���tg<�JaW�@�m���B��l�b\*���[o���	f��<��Y�b�W�����2*gS��Ӫ�*�]�� s�m�T��x�|'A�Q��H�KYG�]&��{�,A8�k�⥨�� ��k�*�Z�Y6�c�I `3�EQ���|rd��Rx���i(w�P8.�|�S<3��7�K�p�Fag��S1��@JhV[�W�!��k!z��R-�DZ'H�v���~��YZK]7. x���;��x�[H�h �� �>��-�|���AUZ.��	A�;#�~�Ί����GF��j�ʲ�4�g&�	s��GY<��'oљ>�#^������e �2��X�Ag���\Я�J�� rf�*Q;d��[�(��&�r:M1Qj{�seAG]A.13o��&L��ueI�� ]�+A���h�������,�!Ix�?�Bl�}#cv���p3�A6aS"u���b�*/�z���%)lDqa5΄�ڙ����sQ�`�á�y����i?'�6c���sw/0Ԥ̭X���}M��BCh���Q5lyz��Gn�G8��n��+�J�l�'���_IN�����,�!��˺J�ء�'.u3�Y�Hv���
�ݢ��:ÿ8
���&9�	���^m�}�?q���ʮE�=,���W��������b2���N�T"!%,�e�M��γ��~�E)���_��瑍�	��fl���K3�(	RB'���#�/;uÌkfx��>�18�t��ߗq��d�׆b�BY��>��ځ͙ 6��_�J�R�-)b����uI�~,_�掻��N��guվ��P��&�.�3��<=�WMo�e7��� ��F�qr]ieĵ� ��3ֻѨ_�x^t�i�D���ң�)�ݕϝ�=�1Q�]���*��#7}P|Z�+�J�`2�Bo�p+I��d����_l�
���]PH�\�jQ���Kn�HD�E����
�+Ǭ�w�l(����J#+�@�7��o\�)��S�8鵽���Ȓ�5�V������a��
����t��nZb��x]4S����Z~��߫�iI�"�no�����8���4�MS�m�}{�s�c�/�u�	X��w���O� NzA���w	B��5���������M��>�$0��_�7N�g8�cI�j�b M*m�uy4VG>:�jݜ�X�4?��j���4���b�瓇ź^��v�t0����I�o�� Ͳ!�b!�E�l[�J�l^�sOy���6:�!Ł�! �P�=U�	 Ԣ��~K��g�    YZ