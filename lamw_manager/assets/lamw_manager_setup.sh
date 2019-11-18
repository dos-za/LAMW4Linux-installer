#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1209590168"
MD5="82a8b783b78b620af23e5b87c6856dce"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19637"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Mon Nov 18 14:07:30 -03 2019
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
	echo OLDUSIZE=128
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
� ���]�<�v�8�y�M�O�tS��鶇=���c[ZINғ��P"$1�HA���_���|���k~l� ^@���t'��=X"P(
u����j�y�������5�;�<�?�����y�t{�A�^�~����>�
���f@��tݫ[�����Tu�\^���k�i�O���';�+������Ծ������'��OL�P�ڗ����k�ӀٖiQ2�L���c3��a�1�Ggib��rӋF��pjSwJI�[�t)嗈�s�I����D)�`�>������]��-�M�j��D��]%6#��ě�z�^@��Q��Lρ�d� 0���"0}�d�D�1\�4�Qr�l�~N*�����V���QK�á�V�I.f||8wO���ё�F��y���5m?������f6W�d��G�q�uw�57a���𹡢\�(j4�N� ��)Potz��*�a���3�h�o����^Y]�J��ιJ��|�;�n���6u\瞿����7D���fWr�WH5�
 ߚ��\z���o��b��a�N`[�)�4�K�c;�=ں&J)�.}=]�z�x��"�r3���&l.�� �
��@�=�,�,�r��p�SF�.B;P���fHtN�y�E>�������/D���F�S]�3�� �d7a1�u��+%A���sƧu�E?H@g�4��*��ώ�ZFevx��@�P7Ԅ������NS�ڸ�U��K�S��)�XLB�2���x���1~��ʛ�,�;� �
��@S�9��:5�[|قLg�z�	�u5����v���"7�s@߮G���n) ��v�wj6��JYy�*���?o���96h�;3���9�3zI����������y�8=��#h�~�ϧOp�Tr�m��\���2T�#��%��I�ZUjZ)�_%�"r��tu��b��XJQG�HnPR��IB"���+qS,���R���1&vi�nJ��O��.C=x^��>�R������@��$��D��y~��1��쌂���JI6�� N>,�oEE�X���gs�^8��9BR�^�_ ����٘�mo?]���<}Z����s�mR�h�&�+�:����x�6�����Ry$����a���t-_ʧ�b@�[�������b~5�����/��;���6$�y�ߩ׿������\&���!�t���!j�7F]��~#��I�{x:h���*%�H/"K�������<
�~$x6]�$!�	�ҳ�9	3���P�x,������oLDu�R�!��j�JYG�D��h�:��ư�Q�dr�4�(�Ό��<B���( ��#c��>Y����u=V�=����~ g5o���3D�Y~�.���L��xef6g:�x�C�3U�V#8������,����q`��*M��K������޷�����)^�Id;�l���:��W���Z����V����}S�U��y���������vp �Ȝ�4�a	 D�]��xT��?%:i4��{;i�V���Wr�J٢!��&�(���#�Gf�4N�L�$�G�M��F�r��3��s��b����X�Rx���7��\RJ�����nT�5`���V]naa�a	?����c�t�aD�?U�� ��.��9v��8� c'd��zp���ntI�!z"���?�2s����32�Tk�Z���hK4�$c�nuP�� ~q�^0�&�����u( ?��5U�X�G�g�~c��P���cOp �*K`��a�<��V���(�vc�6�['~���#^���+�H5�:�����s�%�ܺ$�����#Y��O{c�1E���ں��~��H$"[�:a�S�?��@���ڢ3�k׏ě��?�t	c�=��B@�%�������p���.<�т�0�3��q\����>��� ��{{�>c�xm�������.��m0;{�@n/�@U4�V\#W+�A*1�����c^娶i*QJW�</M����p�����HY䙲��<x��ю�'/HjnG8
K�96p Y)��5m\M���p�뵶��j�or����/�~|��s�=9}=~�;n�MdbHX`'%�×'���7d3�Te�VAw��j��R�)�>������`��X�A@D��qL�֚�$gF���$4���>�e�ͣ ��ȋ ���By�MM�F�R��.LwN�������"��%VJX� S���)�N�E_�#� �f�t<���=2L�V���P5q��#��i��{Hs�`���ODk�^v�/��$�����6pgJ�e�ܘ\)�Iܒ�H)�9 �c�t�l�J��ʁC�ʪ`����|�`�	K�~_�J���?������ԛXqx�L{޻阀�����I�2i�5Y}*�'��q��F%�a�)�]_b����f�P�U��i.�g�J�bG:�T� ��e�m���N�����쎴9�[��_ �ya~�Y�"�n������� I#����(���Ɍ/�ʥ�m�|���"r$'{.h>߹�����܎'��
�q�0s���</���seKn�2�%`ϣ !���)�I�G:G��q��6�q����q,G+	d���&�`n�D�%jP�ߔP�Xp��9��><���җs�$��,��H�����R\�4�(&}szf�)���Z���I�3R������w7���\��p�����5&n0�Z6X�?�x{�o��S�^�����v��������X��Lgi���?�^ �����g=p@��̞8���8B<��]l��cb ��^W�V��a��g�wj�sn���g�������}lj�&ꏤ1�m�%u-/���?�l��z�_���jjmoo�SH}'�^�������'�T��"�OD�TK߭k�?��&������! 	x�${7]uSe��)f���>�PZR�~��\i)4Ւ���X�����������y��@4���P���R����2��/�����W��ue[ԣ0���cH�,�GH�Z�vZ��݊*�Ad��hJc��1���k+�No�8��������S�z�1ʴ�Zg��!���1�V�ҤXǍ� c����*�xC��Z�z�I zz1Q;՟u?�����P���J�N���s.L��v�xޜ�?y���3���P��U�����R����"�$�0It��I��XQ@T�K���R��k�+80*���M��0�]�q܁z�VT+r����I�&�j�����Ux~���Lߛ��Z��ـ�ʵ�,Ǎ�Ǆ2��]*!i�/��5,D�z�B�xhD��`�;>~�W}����ի�ւ��>N@Q[�Q�Ƃ�V�aR��&��_94ZGm�D�!p���
���5���=C�'7����	���� �� Ce}WՊ�lUzN��.�ﭴ��^qᝬ&2��8tE:�����_~!d#��h$n2k9�;p�L-5?��~ߊ���$9c��T�2!O���yY��r �1���u.w��9���Pp�&�b�S�'u"� � oo�#
ou1J��Eyo&������*8�so�E$�<� >���"J5���A��o�c�u��K�bH��\x��*��0�JN_��oգ�d�>ٖ-$O��";Gf�A��5`�p��g?�6(/��<K����!�AKςH���`����9�]Ȓ�]n��nKH�Ͻ�&.��/���/�?;j�y�$��ΏuV�3��$���X�����՘��m����4��i�a��n6O�ϒT��9M~W�8��S�I��SQ�-���h�f�� Ӹ�E��D�"�C�Q:�1���v{�ͻ��[D�p��А�O��!�F)�W��K��P\L^!-ܧ�ZE��,A�3oM�*�
F���&�'^p� ��1G_�/��F�����NA��,�u&fL�O���Lߺ�Q:4�79��Q+e�5*+b�Q�b�w����3�g��3��&xҒN��)_c�H��P�iicdÝC�xx���#�!R�Nry��!�W��V�x��F��o�!d#��o��ٕ� x�RJ�P��4�_�2�׊A�����X��0~e6���y�*d/\ߺ����$��"|�n����s����D�k����YN�*�;�)�?cqo]�V)��<|�t�d�ƒ��4�C��lvmY���BO'���}'�П&*�)?�����| �!�3���/ւ4c��B��fy����bqsO�����(F1I��7mn��76�eg����/��oZ����}�w"�VO�%5��PSO`OW�Qn_�i���O�f���4�+M$�Ϛ�����4��y����u����p0�[����`9���0ۨB#7���vMǘ��[��ʧF#۱�M��9�gP�x>^�:���!��Bq8zqpx�^�s��p���u�tL�V�}��
�e�_j�r����ރ�j����.��Y9 lη����F����{��EaRǼ�|A���X���Xr�P?�?;�9�3�M?�|�W������vK9��ː�WI�e��������t"jT�i��&.�j��*P��<|��Ht�_�� ,:�w5>n������qR{*�),�, 3#?\��q��v�4h��oI��4���txS�����,��W�.��&M�ZgW,�K�?h�ȶ(j���A�U�K$mK-b4�.¥SE�Җ������"�����$��|v�eb���{�H���F��Mf������s2��In��']~̒��~9G���QV�y�>��v%Sھ�Bq^�ݓ�X㼋5Իݰ��%����6�5<�O��urd�r^P{�<�:���*@��ޛ�f�2�Qv����R�N�r��O~�����4N�F7��u��K�T�i��'?�[�������\��r��7����nJ'�xLw�Ϗ�)X4��
4<;H�rR�u��{~=��x�����z _B��:����)�#���=Qa��	H@�Yy�<���<�6�-��J `zpv窖�R~s���@��s4Q��;l�v(E'��/�0�X�y�R�ؘ�	�_�T�w�(3%gJ���A�Z�?�R���WL�R�H�q�{����wf��a+0�3�3�d��.8k)i_PY��oCC>�a����s;�C�����l��Y����ihl�9t�sr@�U�<9���'tF-�/��_9��I�j�J�"���;w
��v��%���?�ڑU�J��ٔV��TbJw��M�pᶲ��9Q���3&o�}�M��*���UP>0�9=T�Ù��5QX�J��܎ wE6	m�1�O��2�:a�5�.ܽ��Ȳ��RZ�/1L�:FA�.��1:�95����Jf}E n��^e�$9����Sv�(�F�Qh�����[D|�	���sZ>���<� S��r�L%�y0x���u�������$Kw^�_N1�X��`���.lX�����J�gY�ɔ�T��ߙu�K�:�Z��ξDDFdFJ��L��UF�{��ر���e8[�o�G\?E��"� N+���JA�JA/�B@ ���`��h�~�Uz�,#��e4� ��~�Ҍln�b��ǰ�Zߣp��B;z�n�� \�P�A�h����Dq���yt�I���^٘�־(QE��/{�>ڢZXm�U��^1�`�r ��#f����>�r�Tٙ��Սry:D��*s�Z]�W	��\0I��(�a��-�n�TO�c�'?T{+�D�rbC�9�����H�W�V'9�f�==[��TJ&�x`�h�U�L�k�ZJA��#^�H�%���������g��
*7�8��wa��+��nݨ�d?cL|�ƻ���N��N���_�	���bF��<�<���E�U&�3�ދ���_ӱ����z4��W��Q�WgAi��?�`��.
��c��(��t��Y��9���743��itq�4���U'鍸��G.!�ʖq��q�ye<�8�G�v.�I@�C���G�w�e�`8�>����2a�|��WY��c�d3"��W��W��z��Z���0!����o*r:�_d��~��v�ˍ:~��1������f	E�����;w�B����
���x@�gJ���p�~�I'c�b@Rdhj!yq>_e����i���2���ը��=��5��?���6��ֶ�DI!5���TXI+�I5-�3)oF���-�<�����d֡Z�������b?+L��ї</UMbnJ�E.E��x?sg��A�u^Ε���u;9�5q�(|�/�T	uS��ToT�9]
˛��	�~P�wG+-|����S�£0�PSijV!��&��i��)���;�HمT�c�X
�r��X���C�7^k	.�)#\$W��w�������������؁riɧ�,���0�E�|A*����u�|ǚS��˂R$���N���֩�ܷ-�d��!S�+}b�o
b���e�k:�#�l�T87��svr$���ZP�M�����*lQ�S�$�(f`�	}�Q��T�U��|<4�8����nS*𕄭}�>�C��M.�|���?K�KaV8mg
24
�}�Jc�	��q>�Yc�~��k�g	5��&��I��}�}�t�+�03E�d״�C]���A���7��x�_�	!���<��)�;-*O��� ;���P��,w�!�8�v��Ef|)ps~X�5iAbb�ef"���Ha��hy!!�{~�m�~G07��N�7��1і��L�	�q�z�!^�t:�D�mGg�i��o���K�r�3�93
��ݛ����"��v���=Ro��\�m��_�	�l��� :��|Rl�v���|E�箣����D���fطK��+��n��Y��j���GG{o�i���@�M�W0B͠̰Hu�79[T��	��e��I�}�R�۹������I����Gd�V�QPV�'����	pcZz-{٬���Z6o,k��Z���Rv������f�d��T��|��+�Zo���[o�W�z_ȰW��f�Ps7G�%���#m�=V�:�l��N��M �2mN��߀�q����������o����'�#Y_��<rV�\����0KΙ���B9l6�u0��H��w�~̖X���)�n���3�%�t�-o���<QHN���k�V�KJ#���[���0P,��(�#Q 3$�fy�Vy��B�#ҙKuϢۮ�y��r�bX	�J�&�dP�5��f}Q�~��+�^�M_�ͷì�\*ن�*�=~��l.�L'|dZ$\�!����kZ�:ζ�����Fa��@������k+�r��K7*fe�Ę�jjR��dI�1(�m]�ϗ�o�,B ���a�٪��ϵ��7�K
?�g�hE$ۀ�&��������	HcW���VQI��+MR�]}C ]ّaH_�U��˿��yũ�X����f�2�t�8#n�����Ƌ���	�&���k�f*�W�VY��"��`Gi��G�����_�`J^��}�ysxţ!Z�T�p?��R�I�79�(���WU��*����(�H4�PU�E�ϫ�b���1N9��ЩF�%��D�j����a�4K�g���ud^���gG2�CA=5Z^Uv�m|O�0�f��	Rz���aoY����=Y^���K��Kk��Y*�f`�/��f�W/�W�K������
�jBZ��u[��f����c�&���#���N�l'����^1�n3H�J�#�����Ɂ�<,�oRbT�rOJ�@�6Y��7���p���[�輿��4I��� �o|�#�z��)�r�.���?7k�{�?�����?/R���J���|\u�Zn���5�b{>{�p(�O�9܌� �ru��~�.��{^>(��$��#�O/� ��@3������(�G�Go���nx!Q��
���>ŐF?\:J��%C��V�\I�d��E��%��a���ۻ Pj4� �C^�=�P��یŰ �X��'ا��?�b��k'���Āux�����s�v�	� ��������@�n�P *`�-װ�$cD�8�3�6�F��y��4©+�&�F�aO�bQD?�\;#=�G�8~���o�+��$����H�p<�'f'�=�1�	�#��עܫۤᑅ���$�J�T�wO?/�TF����<LJ���M�$O�!;P���%�[6-a��jo�.���lG�vhY��\[��
�h,�6�X(}���k�	��W"�aT�=���r��B ��I-�U&��t�g�Z��T�����A��+7�E�fi��+-��{�ol�c���?���^���k6f� /L�p~Akp:@��l������PkU;���r�i���V�i��5w;;���_�T92��*�����,���Y.��L����:Є*�2���9l;�˹�x(3.�C��NR5�8��i�B�����A���;w#-�l�9#u��P�,,j)N���#GЃ���0)}���u�8Hp�?�B؊�<�B��(:��Ь1Ew�HGO�<b]��ڶ��W0��4��+\���*{4�ˀ�e���:�=BG�H�d-������r�;O
�F�L��z���h~d��<N#�$���ؘ8�~��>�=g�E���!�8AO���}I`c���G���g����i�%�Qۜ$?W�[�-�T8��+���;���_O}��`$4}��A���جL�\���֔L�Q:2�Q�]���į�8-H)�LrG�S+]ԥ�>]	c�g����f]�޴L�I��h�l�ia�~��)^�zsMm�YVT%rq��s��N|[0�x3\s��n"8��uC0ٴ��=���,�E�3�7h��Z��D��G|�Q0�ֈ[Bm]_�ۊ\R�jM�#u�%�g��M'�7�#ƅ6 	��"y���;"y��KQ<�q?��R:�.`����d؄���J��S��Wu �Kw&څz�>>"�@tr'�^�uڎ�����^�'Gn���"��O62���{�?���o���4}��|AG?���o˕�,H;�����xv�#�_i"��M�h��������v���@%��Vj�!S,�A/1qב��a}ϳN�\-��/c݆T���/�
���\e��4��9"��+����H~E"��v$�ز�L˱�nF��$�v��_�OܟC��p���,e�UV���3����R8J��m�
q�qIwIgѧ�{��w1��*�@� K���7���7���.ߪ��US������M܈<'�I0�&�M6q�ھ.L�4���I��E��4Ci��F�=�|s���@�(	ɶ�g-]�z��U��%FDD�5�{�Op����������MF�1��xI��wP��A��ƪX^�?��r_,�ք�{�2:v��9	�P���F�IFC����A��fԢw �),R�[ X�2��5�M�ӈ����ou�[��Ua��Y�╉⩨_ 2 #J�O�q`_}��~:��@CK�AuCN��ɇ�%�L�/}�oT�+�+�dOx�j�5����C��m��Ө���Ob7<��!�p����wB�Op�e�[-��2��;�{�V���sz�U7�wA[����7V5�]�n^�{$�	��]�e�����R�*`�����4��4({�/��=��� �I�W�T�J�="k��֘�rL�k㼪���J���)P�fkî�%��9��&0_6e�nyl���0Z�	��2?�����8���x����ͽ%
k�ۅi�1�]8�D��^�π�0<�yyZa�"ڴ�n�P�5|H��<T.O�Èw;�Y�g�����x���
]A	\./p6�@�$�D��\���HM�̼�o�\���wӢ��9PN?%��N�dT���-A���4>���S�!l�b����C���N���?����L΂i�a�Y��r��5�:8B�v�gо�k�!
�
�"&3_��ӑ$�!�df,��.#:GT�e�v��e�ϡ���Cu�|�Ԍ�eD�N�E_TR�!�nK@%&?�'���=���b&�\�v��GL����֋���d�vY�� Ok����x#�!5qY�b<�ol��"J�#,���q���!J~�������oht9��y�fSreٛY���̑���x+;���K��[���ٚ�ۖ9B�]Y�hGT�ܞ"p������ey:��A�Dy{�R�iy�C\��A�~����0X�r���/��e�g�Q�����Iʋ8 �q��Ec�X~͌�yAY�s�5�Q(��AF�MU��#��+��p��Q���q��$%d�p�?�Eͼ�lX���B2t�~���q��!�XֳQ�+*.�����ųY�[��9[�Zf�j7�{2�K�T�(s�t3Kb�������z��bk�M���)�6���F��e�s����y�+-!Z$���9`[�|y��/M��8#7�@( �4�ݎ�A��Q�VgW2�U���y��֬�ZU.G��A��0��%8�:y`c+:[,��}1E뒤�����H�*��F��P��@�W�[��T{,�拙��I����ŝ$�n�r���]��͡�\���!&��q.����q��{�|�n��eS��@l�{�͘d�l-�b!�5R�j;:�Ǘ��t%	�o�	\g C���k����ً�X3k�~�M81�(.�&#|vgt�sΐ3^n�oE����.rx�\�˩�����Fo5��;�f�B�
b�xfE�桻�b��ీ���B�u�9Z���n��6��jA{�����ϷK�g�qf��±�(?�m������ܞ�	���3���x ��w�}�5��J��13��;r�m����Aׇ���(6^=��T�]��:���[RۭW�����\{&?�>��L&��A<�FN
���˹ϞW���/�b	�~�~�t�D4����ߙ����[*�XR������?��+i �d����^���g�b���M�)ҡ�Yc���GC��-\��_KVஈ�c<e���m�!h7[4�����j2V����Ƿ��)���䧪�c�/��N��ӧ�ܺ�.�k�<_�罓b���f��N��x�VD9$r�?'�}�'s�Ѐ�l���ә���y�=��`O>���@Ր0F��A�{�2ʆUt�;��q4B�]8^H<����:0��JH\b��]n���Q��b$c	z����,��J0`b��K|{@z(��	k�#�_��k��z�q�*� �|��h\В//����$V�ޔ���tAhD��hm�ŁVlKՌ2�\�9G��zD�8�Kʗ�-���S��tX7�����x��N��u j��Z�����5/-��Y�������!y+�����ͬN�=����]@�/�	mB����!`��#�j�A�.V�K4�	OǓ5s��F�m��ɠk�8�k�o����hl��g�9�3	2+���D����.����&{�U�=�5��f�d�ҩj�q�f��\ݱ0ܤ`�D��Q����&� ]�ɇ�9e���Q�k|��KH�Lk�[C��!K$�p"1�6766���I���>;V+o3��xK��_)��q�q�^y�YgJ�_a�Cاjn'�"Ƥ#��fcs�%�dk�32�c��c��C��0�&�c:mL�r���i�X��8ύS�45���"����P�9�d���鞊g��"�s�4-��~�8���5$:wKPrC$R\{vZ6aJ��@%�E{�GB��@�3��sp����ݟې��P�M՝E�����`RI��y��w$�x�
H�DO%����D�"*�j=`-n��Cg\.�W�/鋾��*��tS��!����u�2�&��\��_v���A���s��f!���$�{Vǥ� 	�0�0���a�e�9�oP�m°��^�f����W�k:/�~/�Rњ6[����c�[��'�~rgK��x���:�q(��_ª�%U�EB�RU�ahV�����OJf�=0͠V�cS�:�K��9��o�z���s[=�Fd�C�h��<,U5G�&#W���wƃ���k�F^5GmV	��j����㷥~"l��%�uB:����4������U��ByX����ӈT�P�O�����- Oș������x�M��6�Ʃ��K=6֛D+Q{i�?2��zgo_�z��=�����{���QR�-�֤O�륦����Y�{+mq�:�),?�����\���EV�R��$�rġ�,�,&�KfERs|Mw#�~��Bt��XI�3K��^a���-$cVE"�l�[�uĎ�`\�V�U�[����@�h0����h�NFB��E�����#�kIa���ق(��`��f�%���a�:�0�ub
l�OJ�\=��� Fp�񘶭q�	�B��?|����ջ���!�T�QƱ��&�
I͜�~���D����&J&��E`������d��X�]�i���T���()-K(��������{����2�4�ܯ�ZV�zi1MjG#�l�R�]'���.R��6�t��?x����	��-�<r�sm}�[i�z�����[l�ɪ7�5����;��d3����0�FC�Єi@��1�	�ua�Sr@�跨�Zi ej�!4��:X��K-���W�$�O����D&�%��v�G�����J3|L`a���>�(7aJ+�>�	�9޼I�]����|��D�C��w6:���al��s�4'm�
E�zm�̴嚍�T�J]�Q�LD�[fT;+[ƒE�+�^I�y�t�a��N� ��M9�#��2J��j�r�d(�Y�֟�������#�B��:��f<�9�Zz�!t�31�&��-�
ΨBP��f�&2�dO���9ĽD�"v�j!��@C'��W{���T�F���쾜��{�ɺѨ�ot�<E��4�\��l�҃�&�y0K����&�c3.�m�K�Eծ�FQ*��)��l��[�^�^���o��!�`qrO6ז��\���v�����}�`�U*���Ay>�vy#�C�ߩf/�-�9p��𐺍-�����+��n˲PJ��ԛ��8�g�Ylf!̸AG
�{򐷵s�GD�2�I�-�#_�L������k�Q��_�o�����l�D#�|�MM.��a�¢�$��q^ȿ�P7�!���PE�E
�a�Ma�����MU��6���W�B�0��e�9��{�w��yuet��6�]
`��1_������+ܑpQ%qKɸ����95��"�(�NC؉D�Aۋq���=�ATҳ����xn^ka���A44f��<��J������'_�l�+BB��
���2�8�hO���PFG�H����@���a���cwͪ�CQE���v���D��dt(��3N����E�S/w�R�Jg��(����sG��`�������C�_?�"��>~\����7s�j����?���Y���D���>�(���A|>%?X��-�h�r]#���Ӹڃ�S��n�\[�@%d٣a�;*k�AA|G����)�k:i{V���D�q�L�8/�h<�}�����V�p���)"QԆ��w���{��
��� s�(3���e���W��2\�Q�]�-�8B�w��@����A�<�e$�By���gh�g�h��C񃡺it�� ΁�+���al\��e��!��;�7C.�ע���_<G�Z9*����yT=3�*�Ck2N����t�q=��G������������C��hә� ��$�N��  �ܑ�7��ը?���x��\pᎸ�r��mo�+*b��N���Q���Ƶ�_�M�۝]����o�ߴ��d�Z�\���jq�LJ�i%����.`3g��L�R1_u2�f���$����ud����j]�4�RWptb`n��,������I*9�)��Fv�VԔ5��"��������
��5O_��c��{�?}Qj���M��ؽ�k�=j���ݛ+pd��۹i�L�_hv��~������Ngw��n��W��S�1"}�)��i�g"�5�_!-V�%z9m?۫�)����LN&���0&��`�}qЇ�*��*�)��ޚ�-`U���>�<�@��dpL(������)��ڹ�g�~�3"��T:4A�|��ro�m�u� &��݆>D�p-AA�����)j�ʇS#ԁ��X7��ｔ����;�6�7k�cB(� ��������ҧ�9�q��v���׼�ã���Q�u��0�T�Ӡ2=L�cO� h��3��f�eb+��@n�2�NvS��vv�li=t�R�Z�Xe��x����FzO*�J͌#���o�Eןq@�Ԛ7jif�B��DN4!��%rBJ��h�azJt�q0�=	f�U��)���Ȑ��+�ӄ���a�O��:{�M�j�#���g0� �c9�rA@Ws\�ӾkJ4Z�^Йr�h�hP���	�5���,p��j�8ߗ7ͷǝ���+��L�c|����(�"��3l�-���|y���T���N+8+g����f`� ����=��ß�V�wX�`V�:���N�l@dB��8:�2�MJR崌3��p9��	�O��+��7_9���"US'�%*�|tn�&��Y�� �	D=�����:	��ѓK��{Y�"����'`�k�H�qm!5?Ro�wXb.uj�g�ff����@>�&P�<�PFI@���wg8��%��v���z�­Mr��RYW)�F�}ux,-��;z�ֿ��=�e|G��}���_Panǃ���/�v�j�����\�
\��azg�n�W-Ծ�� ��zȆ=��e�J�����^y�Oj��fԑ�9��9l����U�?�c4�2�����u��M�������V���4ܨ�_���HsIA���Ƴn_O�{���	{@��������Nk����ku�s����	AEޑѫ4�{��u�/3�6��a�N?�j�^x�����#�P�p��������Q<��_�F�G�4��$�����s��[V5��pޟN6�o�{)�u���)�=!.U2=�`q�C�C� "Z�-���P~:��Xۜ3��N�9�O�P��Y�\�-h+)	���J�!TȻ��á*�����Vp���hX�>���2��R��Q������u<ܚ ����C��t+E��4{��wԨ���5�Τ*�G�*�C a�+tn��wk[�~W��I6,*��+�!5##a�n����8����(N�n��}���7�b�G>��pm�z�5�����T��ĭ6�c
+�Uњ���@H1˯�_��ST��H���U{�T!�*�����!�Z��E�Q+`r]��zv�Mhh��qm�G�Z�|~�*��E/`�!b��+ieX\��4S��mV7�:�sku~�q͙�m����k���g� �&�R��,�l[Dn����0�W��##�|0��o�߼l��k5	��Vf�%�I�}l�R{R���P�$;6<�}y;�`��&����)^^i�R��r�X��2 �$>M�b�]<B��4�Q"�*�N�>u����ʪ��@Q�׿��3L��y�h�pef�E��r��\�K�zƢ�<J�g�u}:�C�$0�
��)���w?�\�R�$O�08�����8�PFG�,��bo��7�Ǉ(��6�����H�e�7�"�P�n��y�sSZ�ë����ew��Zv�F��P�6�R������p�+@�1�q0�~@n;�|�ާs���W �����Wű��G��Rʾ��H� �
i�F����iԟe#�!(���lC����h�ԟb2�x��8��,��n�jw�D����������w��W�x������xr��q��1G���
 �T���='����T�E�NTB�AE����x�^���]��saܿfw���=�}N*�qW6K��_$�����u(qD�c�r_�U���=�r��w�E���B=Y�W�X��A;���x���Hf;�G�h�?E�@)m�3L���[�*Sh!5ޘ�+-J�B���oi�T���+$���nm�
��i7��Z�(����dQz�J�O	�G{��t��ҕk�	�/tz!�=�P�4%�{;��(�/�N�)�E�RvZi�(��c���P�1b�N��&Tj�`�o�y�X]~��EAĈ�Nɡ��XJ�HP�V��V���6�wj9t/�H�{��@�56Q&���X|Pq�~��M#�-n;W��aIk�9cW�xo���[E�l-+�p��d��6LClU���x���D�>�x&���A�3���=H�9Sɼe���rr����8v�D���~��iRpQ�+���7|�z�l����3�j���Ik��~(	�ƦW��-�H��K��[q;�#��gd|�5�%�Eei�T�ݜt!8�D;���Z�����nq���b���`z]�e�fb�.�=ŧL]Iǣ�D�6���d�k'�~b�!E�������`ᖗ��3�a3�!S�{�����4�ŷr��
&��مq?��V��d�K\��C��p$����{٫O���Z1\.�3��	P�C�Ӿ�d�.�h����[G8bd��&��G��(3ӑT~�*�b�+�Z*<��Wu�����T�(w��-3Tn�����0���V���~���MΛ,۠�Ǜ�	q�W"M��ꜪȖ�*��td�Ų~I�{/�z��ԮR��O�uk��_�0E��7ʹHK��H��z.���Ԋ6�A1���#'ڙ���.Z=�m�q'Ez4+���M���16Q�U��bg��bX�}~����'c�"<h�(�������J׷s�B��t|\��x��_�Zo��)ޥ�:zsjq?Bh�''�@
ֺ�f��C��D��7�a�z����O� ����i�@ə����v�}�L�+s'S<�)��%0���Y,���X~��w��؉�+�Sx�n0���9�F�ALO0g�>��C��N�rC�:X>0B�K�y�׋<BG�@_��ZhB�T�������A����+��kդͽ��q/1��|��.����PCr@f�([PƎ%��-��\o^$��K�Q��GTr�T�j��f�/�v�`�Bd�R�fZ��:�SuHo;�Y��Z���� ҘSgZG1�ļ�0�k�@n����ȇ�=���o�sExz�p� �h't����$�����9����f�Et��!�%Q�KKt�"�m�E���jڬU��v���`�kD�>E8�ax��(A�J�7����<�"�9%)�|ki,Y}l$�)Q'�_�6�Հh�r>��b͋��Ѱ�([���+K�����������Fݤ�E똃�����O���ɿ����?w5�p�W�H��t�v?�w<����]����F-���Q�����?�QB5F�t��X��omK�g��gU�3=�g� �\����I�T�U���Wi+��iz�:݉N:e<)K{���a{��٭9�=��?9{�Ҥ��������7�^8Õș�˥4�,hs{�0nEY��K��|b>�yG+<��Y�ƕ�
'L�
�n��~�ڣ�zY�c�K��!�|ԏ>�b����"����@|��YІe(]L�
Ωβ�2(��7d� ޱgel����������ʪ��XR�ːR�%�Zd�*��8�, �l�[3�$���Hᕄ�l&���hI�yx<OԀB�?�4�S�3�����Lcټ"�=C%����2�B5)	��bc{T�H��W���2C�R���&�h]�աE[^D�VNk^r�8���a�i&75H�`x%��Yʄ3Kt�!�Vww4�#�8J^�[5po��-�ZWFV[�)���|�1l{{�zb����)j%�i3Q`P�0)�Z�<	�K]	(���p,������oZ^�`�G�Q��oF�)���y������?C���?�� &Z�T�;�Z��X���6����F��~�l�<h��x��F���=���K2���D�Kq҇�S��C�G�x�)�?pН�N��� �<T�>~�-=O&�hx��m�]{�yU���i�]zޏ^��#Uo�E	h@�i�/�%������q%��
1ϫP�,g�x�FNג)zt�`S�31ӿ����'����d�����"�>�b˟W�s��:t�UC_��xN��.���d�!�`)�Ŭm)[p��G��tj#=�RY7I��92�hj1P�K��?s%b"2�bn��+"���ázMO��y�S��Ӧ��85)5�0tW$4�$9_�1tP��\�\hH2��4�{�bbu䯅*�ψC�T7�!Ǚ�w~Dkƈ�x@��UjŚ�>���.j��B��3qfd @����zs�*��z��6G>s�����_��7���<L�K�nI��r�m'��ki�>kF_J ����@�ƙR���U�);W
�+`�?\saF�Mp|�1�
��@FmAk��V_6lu&\U�B��w���	{zE���Po� 4T��m���5�+Ń�N{��݂�ﶹ����͍�O3�_���^�w'����&�m�_��Y��q�0"�'���W*��"E���=��C#�7�뤁��q��c_�g�UU*��؇��q~E4ޢH������.z#�!��b�4jfm7�'ҜZ�f4ǈ�'���S�j�7�IA	�$�]������!�GL~nS�����{D��R7������]�Jr�,^Cv��4�֙ef�"��Z�"F��f�
pLM��P �-*�5�9�1��4e�(�P�+�
f�%޽�n%�"`�kJ4kt� !	k�()N�;���hi���Ƴ6���MD��$��O?%tV]�Sܲ��=��L�"��#�%�.���܅�Wm�lE7���n)関�y�n��U�wC��EN<_qs����к8�I�|�x����ןf���7����w#�=��꣡�S�ߧaL�JQR����b%��Q��7��n���F�����1���`ۂb��Q_L��a���� !jH',�Q�J���^_�D�$����<���	�ˋ]�uZ��t�)kqC��?:��/�W[͝�7M�����q���W�� >:;��q��dW,�4����e���\���5e��lX&S\�e�@�y��5�Q�0=���ϻ�=;&(ցl5
n$4E(1E�돽��ge�WXE���ewm2�[�l��S%����׿[��lG�Y�8D!�zĀ�AOЃ8�BM���.���
=��'*D�b=�"�KQma��Jb�ɨ����D\z�Ih ͂'&�\��z��������Ѓ^��L�iK!>���hk���5�jq��P!���� �H�3=SX"괐#�[����Uܿ��?�������s�����?�������s�����|�?}�� h 