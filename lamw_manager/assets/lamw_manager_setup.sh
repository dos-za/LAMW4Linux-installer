#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1783368359"
MD5="1ee2341b480aa38ad557b13adcac16f1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21392"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Wed Nov 27 20:45:06 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� �
�]�<�v�6��+>J��qZ��gZ��^E�5��+�I�I�%B2c���l��}�=��>�>B^�� � )�v�&�wo����`0�o���>����;;���t�!'�G[;�Ow;���G������#���|"�!�,�u����觮;��r47]sF���oom��swc�i|�����~��mW��\�j��SU�g����-ӢdJ-���'f董�c�#������+Ֆ���Ħ�7�#�R�/���F}���T`��h�;�fc�Gh�l�~�P�sJTY�Ub3�AH�)	�w�7O^���N�� &�� �\��ӀL���8��f� JN���_��
��=�������h$�����PkOԤ3:9�:��a���X"Y�\ou�mCM���Q�E�u����>���aw�~�f�-�e��9xn�(W)
�ó +�#
����^p]�;ls@{J����{u�׊kQɻ}�9W�����`~���ƪ����9;��(S[Y��Znp	�
�a. �x��j��QP��7��	l�2��t��e��o�RIx��s_�C�'�;^!�H0_����	[�trA c��/ĞE�G�t>��Q8��A��(P*3$:'�,�"�����a�o��g�[t�����T��D�1H#�MXLeY�6�����}�3Ƨu�e/H@��)4�7T ����k�M��ɹ2���&���D-����t�����\��t=E�ߒ*�ρ�$�,xȈ;���7X=����2������4E����S��/[�)���iBeYk�o�]��l����ŷ�E�f��
�4�杚M$|j�R֞�J%�|�O+g�y����Ō�|a�|N��^�	��t���F-�A^7φϻ��ڲ����\%��e+���Pƀ*pD���^�!����~@M+���UD���׏+�+��u���
%U*�$$b��I�X��b��V�m�1�s�vSJ|�du�y���T*�&����Se�C�����&�3
RN�"+��8���5icɣ����?x��vgd qpH�zx~��w{{e������o=�y�5�����%ڤ�ќM�S*����ڌGh��+Je�8~�C��cӵ`|%�Z��oA��N�R诊�����
�>#����767����x�U��3��j��w�s�&�Q[��9�`��+iuO;Gg��_�$�Edn^s����Ga���dϦ�$�>�{�=�!'�`��qcJ���|Y`9��̀��NV��_"W��C��h�mQǞ�2
�L�\��eԙ3�EH<#����@�tbd�c:�#�a�=]O��mO�2E%��Y�[��+G�_���xD{n&L`��2��3�D<ӡ��:y����{��uM�[�8��j�����%�������������	^�qd;��������K�s����Z�����������_��䂄��&�>�#�hķȿ2�.x�AQl�"4�'��D'�f��|w[#M�
<��B�]�Z4��Єw���x���ԟ�i�i���H�E��hbYn���m.lʋ��|lc�K��a��u�Rq�	����8`���`����]�cy�a!?������l�aD6~��O 0�`b�s���Q�FN�x�u�;��芜@E6~|�H�̉������Uo�y<g��,�P���-��4��A�Խ`�M:pQ���P@<�5FU�XFǝg�^s��P���c�q ��J`�ãy '�>�Ί(���vs�6�;'~��:�S#^���k�H5�:�������%m߹$����$Y���#�4E���Һ���HAi�ʋ�a��S�?��@���K�������?�4
3��.x��hN�������?{��+On� 7��Lm�E�h���/�x9Hj�%�^�^��O�*^�+鮄���K�u���=9Gn�/@U4�z\)Wk�A*1��.���c.rT[5���z�2�_�*�x���ɸ�B�K+$���BY��$<B'���g�/Hjȇ8
��9�r Y�6�m�AM�F�p����o�jOns�㣘�ϝ^|d�}�9={=z�=is�`�&D��<�tH�/O�ͣ[nKf���{U}��~SKV�
b���\�,/��m�r]�B- �*zJX�Ԕ'9s�� ������p/���\�@^�X� ń�+�3lja������tg4;�_Z��-R)Yw���2��W<�4XN�?��2i��F�f��=4L�����P5q��c�ti���H��`���O�DkM_�^n�$�^�}�ym��T�|�1�R(�%U�Jv'A��Y���4�ȁC�ZQ���IB>�f�	K�^O�J���?���>��<��q�x�L{޽=4i��C@ˤ��d��ݜv�'��[��eC�[��%�����J�_�������b����/c�2�|f_yY�3��C�V�A�� QI�.�B3���n���CY�vK�� =0��%��׎�K�^F�]��~��hR��G�9�	���nʽ���6�c�T���C���:\D��d�͋���F��6�;�dQAVnaf���煃00}�l�:@��Y ����6���q�ht�E��<=�w;�X�
wd�'!kn�D�%jP�g�P����)��<</��җ�$��*_I����˲q�2�(&=sraΨ�������Qj[/���v-z�/�$a �� ��M�������ʄ�_�����_~͈�� L����+�]���]����<�z���q�w��_�t��X�%�p->o,��փ������Cym�#ă���F]<&^'.+�u�z��p��X���ۡ�g�aMB�ƕ,�ߵ��x>?h�F�!�nw8���	~��x-q	��rp1� �D�s �'���p~?/=�����C�W�V��ޚ\����(���$�Sr����<D%?���t��5Al��B�̢�MB��v�)Y�=�:�OC��X��4����m�����������A��3��tچ���݅��~��g��� ���]#��Q*���q"?K���bJ�	i`4X�5\$/c�@��U��P,m��_"{��b��r��1�RPrWTR��O���o��F4����������G��\N*B��"��C��g@������l�4�x�4���!�����m� @H-��%y�����J~@�7���nRslkq��SK�Vw��w��՜�1�V�L��6i�1aO��~[N�y�!n<(�=ρ\��������P4B�.�E�!.�U*k�a����F^��1�b9���G�П| t��.��u���uE���Q$�-$U�,�!F$9��Ra\7�m��.^d.���L�7�w<�J�O��nԙ��&�`ַ�Q��	.Vh.(.l���Ƃ���f�ǖ8xhB��ZH���Ք�>��u*!i�>�V7-�:�B�x���	�EK|lX���E^l2 ���"�*�g�%5P^�ſ{��~��-��ȭ�:.ؼb��D��c���;)���G�a /
 ey�՚�UzN���RX:�mi�s���R��Ubo�t5�	��τ�܇<����Z��e�#�EK��'b,���h��/A�3rM���	yu�^�G`&�a��/y���t��ϱ'e�B0`�(��k|�.3 �=~���T�X��f���l����kZx/"�K����1�̬+��ٽti�t�4�G���\�׷5ĐH_�P����l̥;>Q�����������e�=K�73���Xm� f0<���?�Kώ��'���T�S�8s�L��T��zS=/�ײ��)*��<*��������	y	F���$Q=����� 
�Ǐm��o�T��J�y������w��@n����f���,�(	�^��h��q�ĞbY�2�C��;���K��v�t��:�Qr�obgmȑ�G����ޔ�"�I�� �i ��K>B/�Ӆ� ������w��ឪ�\�q�^�t���K/�`�9�1s_u�/�3��K����YbƤ�4���{^ޡ9��qv�FR�f�
b��a�b�w����3��s��2��&xz ��J�S�R�65桰���F#�(������������䲩�Iܫ=Ưu�����p��L��|��k+5~�.�05��p�v �7�)\!(B�{��!_�3.�G��뭻Z������=ڻ���3�߳���W�S���޺��[��<6��d��lrN݈`Ԍ͡���;��b��W�����=�Q`u�d���#�a`� J9������Qd,,d�R�C'N���9�}Q`�u�����E�E��<�����L����;�����ٖ����'�.�GT�Wt�;z-�������Z���r�'�PeQ���2�����]V&���6t1Eytuh��4�ۮ�S4L4]��hf����2㱃!��a��ei8��G_��u�����/�>�)�_����"�O`;9Y!�
�+M�!��O���{�aM���>��J� +������""Uڈ卋|�ĳ(L��b�/�5�������@�Ə��w��Lzٲ�����k��A[;��,h�*����w���� Đ�7�4��u`|�������j�&m$:q�o+��j�5:i���:��I��������H�8��K;`�9\�G���a����A
H�7�MQ��4}/�:~}�zs�ȵήYH��f�mQԞ�#,��`�"��ZI|�<�;u44)m�:	��n.b�_͝��Dq��g�_&�	y �th��l�G��dv��{^��TT���s��RvO�}#QI FYX��!�4 ��(���<�{)J�k�w��z�KV�<F�P��,*P�k��j���,J��r���Y&1u`%���7f�2�qv-��b�c�V���ڧ�@��o50�{�B3�Ĥ���[?�����Rդ-4�$�9����U�}��1%���9/�/(X:��7�P���AZ�d�7��ou��0'i*����_?��R�O��:��c��?<Q� ���J@��s	l�&O}!��V]� cВ�}9q�[��:'��2���<E�"�Sz��Js,��W�Ƭ���/@0�����Q���(~d��V�s��p��y_�!�3��O�?/��0� >_TK�@�!����������:0�3:�kk�y[��5�%"?�'f3���-�p@Cc3N������g���Iv/>@1�~e�|?��q4K�UcGZ� Y���߹S�U'
]qqZ[���G2T]*c��P?S�]������q����R�'�3t&o�]�YwZ��:�!X˜J�����8��%�Q%�C�F��$��V�H�w<jr�|�0ɼ�B�_�Jd�Y����bT�Ս�~]]����95�ϖ����FAn�M��o{_��F�칯�_�.�6�$$�ǀ��`7�8�g���)�W[R�$0���/��g���ه������GfVfU�$h��+�c#U�wFFFFF�"���K8�����N��,����'*uw�U���JՏQ�2�o��7zB����ym�ö(�~E���v%� ��eK������(�{2��k��-��t�<�D� ��V�K4�)���!��������u�T\�����cXtǇE�����$���g�����㓹�_Fc%4V*���xZ�T��W6��x_��"����N6���v�ioW_��'�¯�3պ~a�\9�Qٞ��ՍJe2@�kTf���n�x*s�ʵQBwK󝷤��\;{�U��X�.��ʉq�Ԗ��v�P��b3���P6c��6���cPΨ�,�G}� 
m5�A������j�Y�d�2�W׫u�O�n܃�I�A�D*F�i&3�H�eP]�YrcZ��<d�h1��?v���P����O��a���������^wĈ%��g�I_%��:�^��ntq����w<^6�A���[�n��.t�O�U�A�����O�P�F-NN�����(���u���.m��4�.�V26��$ݘ�~�F�2Np9�������M9�Qp޾�$}U��c��!�E������Sd
�a����������FD#_Q��_�o���WP�)�� ���~"!�������"��Bܠ������m���wҝ��7���0,�����8�?�؛��]��(�RF	����L:#C�[;�/ғ�UfI�:<��=Drc��E㹥���M?�`�$&�I�}�R���f����=�#+�A|Y��>���]����d�&�uV���È3u68���E�.Jg5U�;�;�wIG��F�~F� 5~��ȋ�/�zY��m*�{�jZ�L+�s֤W�OŽ��&�R'=f�t�Nut�r�`�a�ܞ��@� 9l���y�����v�@��g$8�[R��6��m����H��.i������T�Ƹ�zr*�F"����^Hj�b�f%����M�JE�Q�<*��ܝ�L�o����u������Bf��_��`��'Gj�p,��wż�����p�4}����;ִ��2�)]ʃ���D���p�@E��?���0�$l��@w��@hhB�H<~/Z��>>6��}��l�9�X!a��S������3>�F%K�~�4�B��v<�.���ҍ�nr>t����ꆑYL���g���!���/��l��c�]��8';i���[�ˋ,L���o\s�����j΍�؏�ɓ��gs��2
K�)2�S�1��-`��!7��@
OP��8<9\�&�"���A�N+f�7	�FGS���k힜��i������]�������Oq�qp�3�gZ�TNjcWvo)�j���r���E�t�'��Z9S�]����K�Y��%�����VnGn�#��Q���v9�<����t��q7�z��<����/���[N��c^�+�}!�(�v��@�&՜)��w��e�\M봳=�;��� <�C,��j����U�n�b�{���A�ֆf�zS��7풪Y�W��2���N�"��|9PJ�S��u��t�~LW����(�n���N�������1+Љ)>��_��*b&9j�>oG}�䅑(�ϐр�0F��J$�1][�9V�/'aCӜڋ��B���&X+c 2�٪�����̻�����%���{�}s

�R���Sy6I%j�����:!]��>?�>�[Z�ں6��[��DQ�z]}��l�K �+凫˙�ȗ PT̲��@r�ܨ�y��!��b;���|����2��t`�o�)�ucα��q?�ẗdp�DY�_U��\c�)t��S���TET�Y�ɑv�F�Tvdҗ�*B}��?/;m�
V��ƬUf�<gDf�6F@�׬����*k�ppe��������GͯW�|8t�.0��z�������s^��c����*�4�?$�����|�kK���b�̯���a�`nj�8M�ͯ���/˒*D�A�uYE<+����h#�z^�}1-ݲc$Y���+L��`V=�a\<�m�M40��֑�|nb���*�M2�Aq]�P-�(��^�%�O�3�}��]%�_`:k�3Y��g�����Ѫ��*���R}z����j�|��|��:|�X/.�`Ӡ&�lܶ�X+=f�aN� �9�*l�r!џa;�v�i}ـ�̠q���V��>ā�<,�9oPb4�p�������y�]l���;��٭`��=�D�_j���_�"#��l�r�k����76�����E����,����m�Z����oV���h���n�������Q ��B]���r/ރ��ei�j�ƛWz��r{_|�}��N�-��U܋G��T�{���,/����[����v�xw��_�����]��%l��n�����`���މ�RO�+ Y]��]�*��mX	��~���H�3Ҭl&<�>:i�������_�
�r�;�p�[^��O�!��qb����!��#�f�Ϫ�\���g���U/yҥ@{���m��L�GG�n.w�Nd0Q��S��%�Ā�9U��G2�690v�����(�p�y���]�G �h@�oPx���G���ئ�M��p<��cf���݀m�~�n&�?�_|���v�����+�9xx1|$�*T<D�A�\�n�*�d�A�ǁ�Yi5QY"o�4����KG��x2�x$��O/��܍�Q�|px���3{��r#���#��v��)$��JsB�r�ۑ0t qu�5b]�=�ڠ�d_I_K������8�`t�JW��F�"����1����ܴ�R^i���s'������Wl!�nC@-T(}�'({4WV]��7�A4���,�=�Z�خ���*L�Kh]i�|���j5�yՄ��)�O��Y��5K%���XJ����ە��U���㪍���0-��e�Q�!��I�x6��J;�ZW�>BT�H'�m̝ph�w&Yl��M�h��dw��}|��7,U�e��J''���n(Y]lKr�JZ'i�r��Ч��9<�Mg&�6Mҕ��F���D���*����)��3:e�M9���HK2�f�H�^e�2�Z�Ă��]�'�T��I����I�A�L��=�C��	�Ңh�Cצsk=�=���u5��-�[�`XQ�Sޘp�7�������\�`-.��q������X��x	lY)c�<L2̐�D�z�6��}d��=N#���o*1q��I?ɂ��y��}��>pH�N��K���A ||�pp����j �a�L�j����0��5��ƴ.����G"����˹/�
@�����-�c7M˔�e[��К�?J��w�+��(�'�Y`\H騐��E]J����0�$#���0����2���}3�홄k�gΜ��nGk��fEQ��%�Z���u�}���ƻ��-��w���V'SL�x���?��-��vε�X%�0X�q<V���c �8�G�$-��9�=�HD�a;
k�J�@țx:���o�bF�4��ddy��F�O���Rh��d@�ٜ�>G�L�e��v��Z�"	���Å�ә��PW�;b
fB;w2�X��9�e86VG=�HS�~v]8vy6�_e\CRe���
L\����b%�[Q�i�B�(T�+ia��!F�AӸA8&���?�@x�y NF7Q2F|ǹ�����M��"�G&(k2F�A��t b��y8�;a���#A�hAܒ�2�y e���q��GhE��!����\��$����D�I�Lǖer�'A����ح�[�Q��'t�~��s��H �S``��'Ͽ��R8��	*�b{XP��X(�ɐF��=���#�H��� S��r�=���U�-*Qt�@��5�gt`g�{�E ����Ճ1�ĹR����ue2&آ1�"���l�6,�P��>V��r��6\�V;>�(L�D%مcL*���Ik�p
�%xX���.�o��Q~�3&�Y${�33�5sE��m�Ğs�KNq�~�n9��?aVb~�y<����4q�������i#�g�q����g���������&���畊�n�r��?]#X�a~�"�����a�@7���$���ȭ��	6�Ƞ�Eݰ�fBM7�q귚�{�QǑ��R|ϳN��컊��#΀8�u�4kJ� �WY�х��ɜ�44��2<�Ca߬�x�:W��(N��e;��c_}0�pL��R~��3��P�ud�k���.K�[ZU��֬�����͕�	��@�Ay@4Kh���ȃ_&��,@f�,�9r(��t9�M�%$����������V(tM����4{v����H�űI�l2�lzsW�}p2�^L3�R�"�sQD��8O���{8el��o�TY!���'�-����dR4C���:8l�9��/�(���:iZ��+P|U�<%F���c0�?�<���������U���#T�������aȥ�IU<I��"�+x�-*p���U����������$�@��i�2�
tD� hՔ�L�e�O�H���B�U(0R�5mE%d��7�[i㖬h�0V,E\˼��oj3@2ꊖ��zv>�Zꃭ��.�湚�%l����{|�}�����������e���s�F�ـk��*-�7���h_�14C��dS�p��)�X�J._F1ɍ����5�-��Wתk�`��q����>=B;S���>���<
��k��a8���wBvVp���g�Li�Pp��*�:���n�o���Uw)=�����M#t�j�3eݔp��#1Ih������h�fC7����IK�{��������I�jhH�X�I�m���OL!/���/� L��&�~�"0cf��E9�r���}�jS���(qtB�T�Wc�p��8�p�&u��j�q������wx5
5�O�j?T�'���/���s�w��{:���_�:	��@6�����RĪ��G��ɐ�l�8L
���D�f_C�ޝ}�7N�p�r�pF��p2����S�!l*bv�z�!�>rA'��/ǻ���/�Io��#�gA��O��H�@u��}g	�����,b�j-$�1���|XIQ�a�ԥ*��Ȗ j�lpi�2KUҬ�:B{2��R_�hi�:"� ѓ%�����~�,G��l���!�i�����)�
��V0�t����6�t��4��] Af(���%0��Ԧ&�u)�MՖ!5&5Z��$�n8L<�c'ĻCT3$��S�j�6�k�?.k<��f�J��\�����)Sf�9�`��5C�P�C�I��,Se�Y�@O�Չ�9�p+E
G$}a���˲?t%ɜ�g���Qc
y[�n�x�HS��<�f��ΒQ�[�y
uA�lU������B�2�j�h˨��c��~/C�`�5#hiN�^2l4�;{蜭/$�,���$��%�r�;����:��{/[�|D��o��8��1	����K5��N؍���GqB^uG����ںu}m��U0�G��u�|ɐN[�mfM�mi@*�q�~�b%�AU6���~S76��Wq�L�g�4f��DuP�03��ذ��j���ۂ�;�~��7�*�^�		q�Aܦ8*�����_�G;� �_尡�0����>�~�{�~�vǨ����6�2���4������Jv�d{S�nH�Z�ĺ��l�Z���m%pT\Z6�n9�e�t�O�ޛ)���:q�g��M86����nH��r<1�4%�.(��;��@��l�*8?��������vk�V%xz4������]A��AA9�d�`�v��������1���� 
FU+*�Δ~v�|�D�8N-�^�m()�?J��7���\�����3�~K@	e����~�Ep(5��!�,U��mv����']�B[���ƫ�c��G3����$AP`a+Lf�$���
��#_Q�&c��"�1T#��h"%�L�x�T>�z�EޗyЛ���{���!�'�UL,�pa@x�\�;=�}�C�=�ɒ�c�J�U��D3��e�7��� l�%�̟�ύ��H��y���>3Έj_AlLoi���8_�)Nz=������'��0��R��d���\d1��Qbȉ�O����U��`��¹�feR��Ρ*^�wk�mZ%O���]����OFѥ}}�����o�$2��Q*�!�8�ܿ*N�zQ�>�F�dM��:w���j�Z5�x��b0���z���M����B#a(a�hx�LP�eP2�Ra
����
��@u�����7{(�l��vv��\%�&���"ƻ;8^F�5��;���(F�}2H7Q��/�m�(�ϓ����lK=Wu���@��xu!��������Oa��8�!lr�5��`�!s��m��!J-�AeS�F����tڍz���]�^C��8G���d8^�c(����#)7�������hh%փab�}f]�y(v����3�b��q�� c�\v�1�m5׈�n�M�+�6�A�ӛ�㉀���=nn8)�!��cka�,�2?Mg��d�R��;��4;{� ��:�w0YN��F�j�VWDk����	p/V�"��1��y��I�H6'�]%�T���� �t�
�g3+�iRP�+���C�+��H������������ڨ>�]��Z��v{��8��U��i(1NH�w��,��	�0�Βa��~q�����`R'#�>�9wn�64YZv%}�Ҧ��_��R��`5�H���s�����WJ�����n�����"�v��A���+���}IE�{�lC�)
�,�7W~�Qҿ��#}ë�3_v����x�M]�c�P�I����	��h���	�%L봜8~���[B�L�i���JM܄��v��M����WXχ�n�����-����[�0׸��x�rߛ��0�H��)�.���/O��%�la��G`�I�Y��ӆ�n��$��'8|g.���~0�
+���8}�m� �E=o�`��M�/h�4c����v���,$����AK����5��������1����м4�-���<R��bN�Xn��E��O�J ��m��J���ߖzI�@Z��\6dA��z��͔�(��|��	���tx�όn�*�H��/������o��E�4��i�6ލ�Z�T1S��"ZR��R��� ���LyKj=f�����/�Mk�g�b��_��I��^j�'m��vϸ8�[n���н_Yo�]�8�u8�ݐǊ4i�<	g��Py�P��F��9�G�h���^�z`��ϙe�Eɐ%��eɘ��Y1��
j����݁��W���WQ9.���|��TLY���v���ǱP1�Ĩ&"^]fYǹ��ü��NY��5f�O��_�m��)�Ϫ��:Fh���׶�+}��*������E��¨gHE<� Oe%7�A͓~.digX}A�M��:����(� ����ˊ�RQAb� ��
b`l:<K�Y�/r(c١#��7VSA8J6+��%YAȨ��GE�YS���L��(n�.H�kta���HCS��oh�qHQ̽$sA/�9�$��-�i�3cҠX;?�R��^.�f�?6X�C ��B_m!�����9�2�tI�0�����o�*u�a� 80�ce��lD��ߘ�R�J�MmX��#2��	D6�H��{�ȆD��`k
G���#k!�4D�(.���	����H@yMN�ؒڣ�t���Z{-�vu�ܢ�IÒ�B(�][62m�ec6��T�nT?�;#��N�V$����^Uv|gk��~�b-�9�_9���f�h�ѡX���%���~V����|�M`�$!D�%9��%g��;��QR�t�3��Ɖ�%Ԛ���.��j�H��I�_qhҥ��(^Ӌme�r��[�	�����}�Q6��;/��i7���q���_JC�����z�@DWV��yd6˨��C��E��I;�ݒL������.#�d��ݘpR3<�Љ{�����?/	��aɂO6V���`F(�v������5Dɬ�U�[p����JW�9�Z%��R�ܔ�=+ؐ�*�6��pk�f]�9O�ߥ�\J��-%���@N|�5#��7թ�0�'E�z25-rl5S���Î�%v;��qp���kI�>�5��^
�ˏM�U�я:��8�|�ѳ�B�s����;5�ӿ��6y0<=r�M��؀4���MU`�6p�>�����a6��x{���j綠���h�=�م#x) $�g>\�-5V�78Y!Q�+qK�8����5�MBQ��C�Č�tGȟcDg!u��Ձ̰�GɑS";r�Z+�����E�݆k7$��#��`��������/��G��=;@�]��O�s	��FХ]%"(#E�S�4zGy��07'���`�Y�k(����`��]l'�H��T�N��2ۘW�k97�ܶ1ͼ.]$Gq2~%��v�����oU�IB}Z/�"��>~\����7����o�������8Qܘ���M�)^g���bS��]__W��� f{2�^=պp���0�O�k�|�,;T��qEG
F_	���ԕVڞ�U�U�	"؆W1?���=:�=��E򀗨���wZ���+�N�2�,LQah	\����aS�C)��ʿ� F�*MH�0�u��tEi{UA��m�,�MQy(~4�H�a��K�u*?��,�������D�F�u���kQ4��|>�ʭrTk����z��*�}kr�|e��F��Ɠ�����_��;����?Oއ�5��91@�;��c\���Y�uB��� �"�5���$U<��T�4`X����TB�ߨsbϛ|D\D�d�@�XQ��������k�R?�� �Z�9����M��W=�~hr����)� ��+�'�Y�j�Ӓ�TG���S:�����9�o_�����dy��8�z�9��#$��/4�*��_w޴w�O�����4��n�x�A�,�x�{NŀOK$����W8>��c�}�)۩Q�i�䟍��G�u8"՝`�=q؃��tJ�9��ު�-`UG���>?��k�d�����D�IumC쟴r/�e_��[ wx�|J�CԐK���Ǉ@$;M�r���t�Ǜ IO���T^�O�W�53�f?O�o�C��3�y�o�b�Y6S���(HX?/��#AkA���Hr��;9<�u��{�B٨���*�b<<:1ZgA��d�>���$�N.�c�Ӥ��z���s@���mZ ^�E�.����x ���;Iec}}�韞�[����>S���v��d<�����s3��ڢ��c��Y6��'�'���o�]3k��iE�P��zR�W뾗qә:�-s0�|M�yc�&�L�e�0��!�I�V����SL��=������;���"�mL�����aj��nM3��ܜ	���m��mVU�[s{��"s���lP?�{$L�\eV�^:���N�ڑ�U���Y���Y?�GS��DHy�e4~?9'��S��g���
�L��-rB��NU�=sѴ�t�]�j
$<zL�%%����C%��X|����,�nZ�?Y%��	�HN;�?��1���t�(��B8���l�
`�jq�/owN�{'�o��n9�񮊌��*���1�/9���mT��}����̯�=á��K���u�Ƌ>ݺ�:���z�k�w˞�k�җ�\�aHk�?�.�xR��N���%,�q��U|�@�*����=�����f�Ĭ����&�*���n�S�����TGa�ӅIo�t�O�e�E�&�3F=��.�Er�9Q����#[�9��	�ٓ�릯�
��m���V;��ڟE���s!*�ę��i��La�G">��g��#��h G�1F�
1Xj�I=7��1�W���(���Ѡ£�ljm\&�lsaƳQSo�sqiIϷH�	A m�Ҩy{���7�����a>���a�UGIz&�D�L*	�P	��*�\�<۶$aj��a���>~�����L��آ/�鋺���N���ևZ�R�D$�W�t�8~��kcƣ� ��Q��i�uz<:�}���&�g�W���4L�l��mc ���W�wނ3�Y��;6�SM���v+C�6��I�$���(�^�_�#~�Ƣ���@�@f����n��r]�7*�%��!�iok�}5Y�LS�;5�K���HE�~���x��i0���0Ap,�����~�x�G��~8n[b��O,u<*�ɍ�̉'���h������D���J7�y��r�����a��|ra<��(n�_�F.�z���8��������}��j�}�7�����0�M�&��&���+�E?�
�^��1 `������(	ud`�=螋K�G�*�v�김牍�ù�K^�><R�aÿ�d�d/�>�&d1��/��g�=L�ݻ=�І�m��/��*��n���= ����d��Q�b9��J��T[�]��`@Ӑ�s�=��A��Ke���08�*�?Ն�I��S-	���a�l�Z�GH��]h�q�^�Ų�u��J����hJM3��寸i+�E�2��Yv�n�IcJͩQz^�k!��[q�|�|?���\an�/�+��K8ܾ*~k�7����YVY�� ����o{6X����}�|���=x����v���:�U�ݜdS�?:�>�M�T�+�xʩ��,�.`j�� ��A�-��&�����F7�7�w�l�_���ۢ3y�����4�z��#)b������4��,#w��3> ��9H|!mGY�k�g,�����|�c�=��c��}��]�[0�1����ϝ����a�W�f>Ũ���BJ���UL�(d|�VC��2�����P�����6Mf
k��q<hH4Ɣ�y�������Nb��$k�^��BYd��	��t�l�tJ�
�������D��٭!Ӡ�#��;���Qs�ϦGE����	А��Q�/W��f�.N�tB����\��z\F3Ȱ�Q�0��~���" #cq�ke3�V�m��g,<��^���N��ҨK�>8}�r�8�X� m�`i�Z2���k���j]U�w��c��Aڗ�x�u躹���xy�A7���|���u@Qi��$!+���N�HDҨ$J��瀧c����\��t���������P�=t¼1��"D���\�dܭz��L�_��������?����7�_���_w6 3H�n6`lڟHg�g21&���b��X��Nѧ�t�Ǣ�i/?���,Wx���XnU��l�-�?O�M��m�qF��c��U0ͽ�J��K�y�����B�Զ�����z�y&Fh_��I��MtTz�������E��˨�F`Rh@B�Қ�OI?��T�ӓ̝$m���Y��:=�Zi7�xw��1=�f&�����-G��SB��Ajs��������)}��@��h��E���ﲅ��M~��ꈈMo�,�ժ��J^Q]�olQ��l0�i����R��K�ӏ.��Jc�٨y�"�`UrXp��Di�͊����2��6�w�.:��;N�5�)=v��7�^Ƴ���燰M +�p~��bO@+@��� ���:e���Ͳ�W0�O~���Q��,PE}����O$����)y(ժ�m���|�A�7��"�-��{"�2D�l.�����Oa	v\G+2��_��Ӣ�	Õx	5����$Z�y/T#�&�*0C�YЮ����@T2"{�s�(�2~� B��k^�ʳn�D��Q����Z�x�qU�!8�u�瓟�`���2DSa��̮���v�c}�m֓;��@Ǹ���ONB|�OQ^�����K�o�;��Gʺv�5�*G�H."�{f�̖$T����@�f��'F!�?��F"~�_݀�ư��ȭw̈�-<�D�<�L�Cbv�mx� �{�o����cz��;=(�S%.$z�]�����`�dl���`�*�M�uN��>\ϧ˛?��o�8���a����6�&�Щ��s����G�$T�7�$�AҀ��ꨍ �'|_��+���C�&�q�t�ġ�ӷ�z�J�γ�{�Ʀ"�� ^�w��n��;)�=[�=��ַt�N������b@I˳�e���)i~������Ď{Ų�(?�[:���	� ��qyY�>��j�y"�8��t4��F�==�,����kE�KC�UeM���z�|}��t�~��/��_O�J����*�2�\�e"V�YR�L�X�@�K`9+n�(7DyC��d�qw����)�V'�Ik<B���Qd0"�ŤG:�� O��`@!�!��Aȏ<����}9
l.�ҩ��E#7��������@X𵶙jҨ$����i�H`f\��l�.9!S��-�qǒ�4˴��݋$Qx�:��44�4J��j���,^��NW�,/u2�Bn�d��g׷PF��"�rqYа�d3ۦxe�N��]�X+!�+�Fd/�X��-J�vB�G���Bw�o��>f���j��ܠ4�/j�K�	��^Z�#��Z��:-�$ԴiKd�ѥ�h�A��H�z��!���0J`�2���W�x/CN9�T�C�4֫�3
��x!毊<��Kh�B��C�k)o ����"�b�,�b=�&A��#����n�Ij_���/������\<^��|��� $�_M��~���?�5�O3��x��������@-�z�{>|�-�m����A���5xC��Γ��
��uHA;�T�'V�{���_%e��0��*t��@���e��j�/ԏ��EUoF�N'������7�L���8��	�yG���J�yM~E�X�{YЫz�k0<��G�E�-���(�V=���&�(|!��XD�L�6�%�����I ���Ŭ2�m�*Y8LC!]�s�^��'�y^�*��*-�q���y����d�-�"�۶.J+���75�zf� ?�S��_Q���@H<i����ZI����MP�W*��7*eI}���.Ԃ���(V�S��/L�j�l����a�,����y��	���/�ϭ���/'�A�{�����������k����z=k�������������э���\��[[p{&|4�ۓKQ�Bj�_ڣU�>i�/C߫���ow=�T�L'��a���;8<j�<�5�#�@�����.^�M������𳅿1��2�y�D�4\.��dAܠ�7�zaV�[խ:���v�ª!�y*Y�u����{�+0v;��W�{�X��IVWbv/pt�G���G'�p.���2yֺ��6zc!�Pr�M�ʩΊ�AP;�[�?�;$5T���/!�yB�הX���J!�trh�iO��g@���t�y��
������ɬ)ô�f��35���/9�z���&��"Sҥ��x5l6�ʑ��_��?
�$%ab{T�H��l����PIO��6uMh���B�2���$k^r�4a��F�g�
kB"q��� �yߛY�+EŸ�ē�X�V�r��T��\�
��j�3��Z��:[�����z���Fi3�2 ��aR�����H$.{b;?��#8�'H!��NO�=<���l+]zЎ��}��phBh�Uo!A�%�wz�JG�ޟ�o��F^�{�dc!�}��+�����Oؾ_�Kb�MX�#x�5j � 0��Y6O�	Mmw�� 
'2+��*zы���@�bV�8aH�RY��
��0	���y!v��A/��)di�<����Q�iOѽ����$| NxM$$��� ���ݛ8�V���>�Hs88Iᨏ�0Y�3�BIs��5���ZM6�O6���V��S]�����1t�s5���ǌ���3������0�������xc-��Y���S����z�&�-? <�T��tev-.�`L�p���'���"��wE�y P�Wa�jh<y$�5� �Q����Z��0A1�62�J`�"������A�B64_r�#�؊��� h<��ڻv'�Ȥ��]Xlθ���튕�($� C��j�#T�!�N2��"���Lǵ��}_�CO0��$��Z����#� ��P�a�r�J��LP�S#�^�� ��}լ�M�Y`B�Z�e���|��Q�e:������et5��`�	mCH/�䙙��'��0F�r�@(������t���R^��.k�i��2b`p�U3��H]�o��>@�p �y��S��$����{��)�[�ا�FI�0���A�2�����>�)����oܙ��L���Z"y�S����5�����:��
�c^�ϊ�^+��x��\uۓK�}��@R�kE�x�"GK��p�E�+����/$�L�7�\7��<��gY$� �oMA��Hc(t(5���ƵX�O8���I�dM���e�*�w-����(7��<�T��>;���3z�	�bV�#�y�!��&J*$&�>Δ��"9]=����]>�͑�$�����ѯ���[dg�a��ٕ��<��H�
��ZH�(��$��M�lN�k����Iʖ��?\��3�6��5��&�S�˦6����ԗ|݌Q�=dw{��ܕ���	{���{:Л�,���m?BX�K��LPg��U���������ןf���'��߯�y���y2�2�7���*?�ů����o���Jx��"S�Ç���!^#�7d(J@�t�Ⱦ��rͬ���>�����2�؊^�}�����Ms��7�.}5��;�iN}�j4�x�U+���;�u�{c�Μ%7���~5߭�tw�����}�g.�io�=W��2v6�Ϝ֍��Q�D2��7�\�O-(C)�h�E�,��/*�A�
��ƾ�$s�)��B���(�p�]�X-�|�z���J�M ̮)��1c3*aiP��4E[؏���4Fzga�H�]��?et��(3�Cp��n�k���!�L�z2=wa��E��Z�Ɓ�����A�:̲u�����T*[�I'VR��a 1��gRA%�W��y���7�/�����?�꣩�]��&�U'����|q��$�D�_��~�z��{���#(-���Ǹ'�7ð����}���V�B��F&X�D�8�"o�Ӂ�^|.�jǻ�;ow�������B�l	�"�DP�M�no��_嵶��\�����42�a�GM� �/��Ϭs�(F���Q�.���C�jԎ(��RK�^��ʳ
���=�#!K����L�z�JlՏڴ#֦��lΆ\;��_�]����SҶ�&	��@yM�$��A���QЁ� ��]�=|an����$EtS=�""�(�61��x9���$�!F2������GR��)+���^�`h�F��qU�Oj
����Ӓj5��*ji%�&��^b4�i��]���o0E����jQM�!�xA{�%�L�͈�R�nQ!'�,J���[��Ey>5+�D2՛�Ӛ\��T�|L���bE�<:Q��;�}��G����
��Ñ����Ԍ���f�X-���2�a(j��s,�ޓ*r�j�놾��ė��qÉp[�3{�Vnr�G�y+4�ya ��,>����,>����,>����,>����,>����,>����,>����,>����,>�������+� � 