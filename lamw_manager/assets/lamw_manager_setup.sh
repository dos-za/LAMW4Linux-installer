#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3225464792"
MD5="60b05fa993e8204a1989e3ea2e0e3662"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22512"
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
	echo Date of packaging: Wed Jun 16 21:24:56 -03 2021
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
�7zXZ  �ִF !   �X���W�] �}��1Dd]����P�t�D�rj�u���I��	S�\KY��Q��0Wc���py�Us�����K����3&�7��"#�_g�I"�ſ�*��d�[�ȣ�ő� Ȅ�ha�-)[,���-	�ۧ(ū`�v�e1?B,�nɘ���A���j��#5�©5=+'����ς��2zLj����t��6
ƭ�H��p{M�Ո,e�Z��H���v^2N7n//�` Օ�Z�m&r�BY�'P[�g��������
��"��,wG(@�)֛w#X��٪�n��h	q���@U�c9�P��w��\���!k=�3wP����Ib� ��4S�?��Yii�!i �P�^ɛ�ץs�:%e+{����gM�d�X/dv"��uX�f�1�n�xC�fP��<���gS��M�y�ꤟ�;h9��O�};������!�������w;����I
���8xn�ӧ=�7�<=y���~g)�n�u��ֵ4�A����+�F$�l)��kb<�l;2���h��������\L����U���ѵ�8���Z��5?� Aar�N����&��,��5���-�pW�)6p��홠�т���M�m����)f���V���Uk���X�J��ì�������L��`���Loej�^�.x���;b�������;�&<9�F�Jо0�;�3��TejG�HK<�L�8xf �X�P�׀��$$����o�su,�s@f�Z-���!XP�.����������Y�R����w�寰�E;�$y���-n?�r�k�m�TEXj1�����F��8���0U�ieNs�M\!���>��t�J�K!��������*�Ƙ_y|�o�L:�&��sd�L�[r|=��H�$C"�8^�����t�Z���y��a��3}R������f2��v�����]OI�K4X�`�{KՐm?d,~��G2�:C��r�8�#�HB�<�wuH����=��#P�u��A�:J x��5�`�B<U�I�q�ʪ�'L�4��n1;D��EMX�ޛ{{?7��Yժ¦ޱ�+�@�n������<�|�h���a	f��_�#`]�񴊁h���t0%�L��wߚ+�z�h����sG�Ut���6U�������8
���.���/����T]�>k[�YiƺȌ��Ȧ0�2W�5��6�=�"��Q�e��w��,����Y�@x}R9b,I���i�л&H��rO��u"�s 6h���kԄ?�I%>���~�������1�2�q�/�1Pׁ�����P9��AW ���u��0�B��������ٲ�P������CЗ�CU��R��A��j��%&C�2@�����[�J�JNf��>���	4��`qY�.�������k��Ton-�G��;~7k1�� 	����uj�Ӗ@V[}�_E�\�X�avޛ���m�>�a����٠��ztKx����{��W石�y|u�Ͻp�:�5�=0�~�D�6��$�1Lp:j&�=�ۄZ�4���Z*��p�X� �Ao��>lU��b��\�T�Ʋ@_[טRЌ��|���a�*X�����U�ٹ��{���;y�"����f�L��h3��NhN5y�TS�;*~�jڏK���`�nm��f�=���T�4�������
[��(wx��o��A?��P���m4z5���:��aY�	,�+�A���G~L�E�;��Pb��_[�=��|�*_�;h=B���oRU	�*Bb�ж@F
�M�<��b�bYEBA9���,���=j9ϖ�1L�x��N
Se�
�h���N�$`�c*��(A�	$V�
U�7�o,����W."�[������P����C��W����q�(�y�)3�����O6�v��Q*U�M�X+_��I��D��g	W��1"Ĭ�ʭ!��߫I��v�����oo}Y[7���,WVB�#[��L
|'5o��J�v}e�L�۬�eN�l��,�#�!��`�����N9��й .���.�0�
hW`�[��/�X�6)+�]����/g%%�e�%xyK����f|\���0�>�0 m��
����N��6����	��\���De�OM�R<$M5y�1GN|����`��>n)Ұ_��Y��V��5!�ؚt&T%�?�h��0�!��5�hthv�;x��/�(Ҿbe+�۱��ɳV��҆�3�f���wn=�G }��4I� Bo�71i3��/����d�Bj�4��ނ�4��Z��x�
�{)�p,�r ܧ��m�B���K8J$�dT�UkG+��pD8W;%;1�.��X�.�&"��4E�O\|	�;���=c6s?s�w�Q�X�L��T���`5��3χ�tPa}H%�.Cl�ub�����'_�Z`����[����+TY��Rx�o7��<��t4n�\t|7x"
�pt�CuZ�����t�3�{s�t�9n���oZ�s)V�����v�4d�`~���X+b�N���c}{AĢ�1/��N�Q�>pK���,}*������c���F���^�G���0�:y�|J�4E��@Hw����Q8+����}��>L},؁%?�T��E�@��{H��cٚ��T7B���t�`X֋��5���@sM-nP�,����&����Et*{��Pa��,�ۃN�Y;�/6�#��@~)3��MH$�1sW"�%+{��u�ȭ�ɟ�JW��-̪77;|���~�e$���V?VL��~�E3��/Mq�}���|Y��U�i��+Pi����
�Hm��CN�MiE)�Z�H˾���'����I5q�ŭS�2��Ds�3�פ.H����r�ˊ+4q�29p�7w�������f|�AߝX�:u���"�]�VOD�O%x?���Eeն̿�p�W����]?�);N ���1������0�yW�5c�xݼ��q��?��ǹw�d�j�
��rO��fIޙ'��~��*��Z�\���58��l#ݽ��h��0fx!�n��褽l��ħI��ҷA��+�}2�epTL�l��S����^���9�<i��r��Vc�����T!|\����ҟ���W�s�]Y_-���fH���]��P���,��ܽC]��&x,�\L��h��أY3]V�{�p��&��9��e!�f!V�^q]�����Ἱ��|�<�5�ԛ��j�Ե.ԼK��g�?�|�o�'{�s#k�%��V��r�^�����T�w���YKa�(oJ��\z��E�*l�8؋ە�J��]��ztÌ`%8���� 8o�t��u&�맩2���5e;D"J2��Sw�Cxw4��>�!��=;K�']$a��ط�9��O�2�84� 0�}�e���K��2±�������W_|@E=A����H� ��}����n�K:�����J��<�=9��R��(����դv��7��j�X��C?��Il�v��8�C�z/�A� ��I��+��@��ˀ��q��B"�y��o�%֮���3�v��{D�q�0���A����I��oY~Y/'�vp�j�D����$?.�2�/ܙ�pW�H�M.��?pW�A�����LQ�\��p�o��#'n�q�)>�+��`|��� O�I `�����m�6u�4Y�*�^��K���ޅ����;��|�8�ڬ��QJ��3dԬnW��I<�j��>�<!�C.~N����W��\M���~�?�Tm�9�l�tE��T���|�d5R�8��a1��	b	�3<�k9�)? �b|�k�,��f(Jڹ�#�7NZ6+�=�����:� �v�E>ZPm����*	��Z+8Ӫ���0vI�u��
z��.���������@�6r���������My`ap�փXy��^���x�/v�
��ӻ)"z@�,��'���<-6��,;���Mvñ&٧V<2��-�K��6�DFR9}�nVX��S�	w:#Ǧ�qC10�}��/
���C�q]Q��K��<�2*�[��D�,�]�U��q���!!/�Ö�d�:'�Tf8t^f��~�%#���.�ArW/|�^�76ܳ]*N ��bS��h&�����N�kG�l��W�� 8o/���8�6����31�c���ס��\b���G��P`�����n4�T��1Y���D�ږS���o� ��ḭ?�-����$��4��6���T���U�̫0�i�t7�&��>$�xQ�k���ԃc�9t�@�g��+m�g$��:�	�v<j�5}�uXF�s��[����*pe~^ vu���w)�ԛ�6*��h``��~[9�s�N����Uj��=���_כ�un��{?��#d��?�;ؚEn(3nW����O��F�+�` �X���A�2�˫��ι���0ӳ�+}[D�yA���*&� tL�YDI��>u���{C�AA� 7��cHu�G6eg×�!n����~�Ո�5��n��7�H��d$!�F��9m���o�� ql��0u����y Ж��$(�$&e�9��|���{�A�_��~r`���Ap��|�A�M�`��fS��8m1���_̦�AԀ���QK^uz˷�(��Zll����gf	�ca�+�i:X��ԞyEU��{�/��^#K���;�O���X���%�g�Ekˮ9�J�Xn�"�'X�B�_h�-k@��L,���� ����<0M~�f��Ψ�-pt�隘j�����E6u٘;j���tkr�ՆTf"�~�eĪ�i	[��[���������"�͝Oe��J�p,i��gV#&maX`%\f�wL��D��q�$���1��r�0��OS�&����r��o���NM�#�I�G��o�yZ2�=����.�k7��~�|�h}�k�Q9��V��"�h�Jiń,2�g��>f����_|�,a�1�ukܫ�֐dP`2��y�*�7��?��r��c�	6��=��5NQ��/j�	�/m���6(t:�&}��Bxt��yfϐ�מ��$�E�����pM.�f�@ס�A�K�~n��^d��`��Vy_�x�,�>�y�b�Wd���.zXá)0W'�8 ��o?��Ǖ���,Y{o[ ���O8��1�ܢAj��܌A	zR�;
��)k����(���&�x$����|�*B�|��CX��
�?���x��nc\��n��yJ�q�{�/6m�FP�1��e"��<�,�����;B�����IA0��Y��m6�&¼I��W�o��&�,�`ar�z�)�Y�Yy�g	�\�1��kS��?�:�&��Jw���ߦqE�C�N[:ػ�����}j5�?�<<q��ds o�~A�-�^��Ƽ�Pc�!�h�@����bL�oM��Td��.]��:ÅG��O���E��h;>��9l9�_[#6*='��Y��֊ό�-ׄq}�rn���E�{���b�r�G��8y� c]����L����m�o�2.Yv�+W�|�g"7��-�P��������!�C��[&���eECv�������K[M@Vr�3�wJ�Brd�Y��k��;0�L��q���������s�M�8��=��cj���i���_c��`8��V	�������|t
�k��d|�Y���
�5�:l_�T1�L��:ZB�/�/�X��\���g}
2�c���G
G��L��ݧ��|��+*3��b�<`��"#В��$y�F���__ArE�w��!���ꨰ���N�e��Xn\Ff�d/��(�y�]�k�!3�a~[��1>�d��a�Ԑ7Ks�l%�[|EM?{Y���<��dq�	��ҦK���h��`�7�څ�^ĝr��n���Y�G:��<�1�e���H�i�w��E��b`eەo��A��bΗHw#��CVE�(����skx+�����;ծ��c8�/ׯZ#�eŃzm�6�IJ�<Tb�M{�N�$i�]�Ay�(�`l��lkf��tZ;�:��8a��)f%����MR����_n佡��W"[�[���
���["Z�Q2����j�G#7!N8B�H�_���%���3T_|	��+�Q���_):�|9�YY���bCJ�*o���&/#C33"�7//δ���e\�}��:��8;@����1/=(��rp��#���w'���p�\T��b���M��O���Ґ��z�>֜7wFe8�-~8s��>2$2?oGW�.ś��-���ew)\��W���ӛ*s��g}T��vn=�ڨ���Я23^����I�Qc��9�2���/~tǋ��NTLҍ{�����R�*M����g�Ȝ��5r<feW�n��¹�I6qZIu��W	��b.���o�}Tc;qd����J��S�$Ҥ�\��?�p�S~:fru�?Y9�?�s!�$�����e��}�T�DйJ,��'��)��b��0K/��o��ܲ��R��<n*s�˲�"�ޢ�3֔	 Kb�9�S��fl"._� ª��
�z���TaAl�i�+,����k�(&���k�V�6dh����� Ȧ�{x*�����ѳc���=l��l�sS�1GRLں�T6��
�[��������*J涉4��<�Ԋc?��	&��A���!����{՜bS�*�Y �~}7�7���D/
�=�qdV�d�A`�/��چ&�=��y���菖�;�Q5&��vH�ť�ӆ�xz9 �g��v�{5�Ӊ�`�Q��v-^�=a˚��~����%D{(��^5깢���ܼ�~
|�I�_"D"x�[j���s���j�����q�� wU��*��#�$�%��ǯ)����+��c!p���=5�R�cD�x�)���3�RgC��m�c�1�$U>ĩ8W�U�b��W퓘�����$��M�M�@qc����r&��U�����N.r5�{ej4�@�x���T��� �������rt,�
�;������;R�!]���q�o�p��*�O걏�3谩�sW<sԈ��bK�r��~Ƴ��y���I@��cP�w,F� ���gG ��&�N���?�L{ۘZoAP{}1�L.�s�J�&.�C�*6������FRw�ef�g��x�'�����:����n@N�K������ A����I�?��^c�� �'�L�HŘR�o��룒�<�r�k�潃S�.����\�a�ZCp(!U2I
3awH}Y,�F���/�>"+U{:m0u������)C���Y�]�ݸ�]`��^E���m+s��Sx��$��@�`q��}�a���7�zv���nX=F�6ٚvFUZW�Si�H�1��K�����m�A�rݶR��)],/4`�*RX_����c��el( �ng@C*. �u��qT�/��p�]�6yW��x�ۙ��Vx�/�-� �X,�	q.R��$�/�3�(/���������gy�;�� Iʥ.�!RX���8ۿ-��0������\��Y*`�z�q=Yk�K
�*'��lJ#DHv�!���ѩ��nL�:?���:�&�V�n�f�:LSd���S��מ�����8�m���6�J\wM��ĒQ�)K�I�
p�H��RY�������4K��}?����`C�}Э����8�$q$�(ol!5?Ϡ�6,+�.�z��i�SGp�4u-S��B5���	%�����3g��~�q>y���%�LX�v�/'a��� d��A�7�db�5�� ���Y�������<CE�"yj6��s�<d�4OZ$��U�����K�U�6Дpi	�I�����"��<&���rrW�i�ah�FU���]���P���a�j��.o�p�(O˴�k��WE�J�k�a ?����?���@��ۺ��)h��ec&�߉��1�{p0f�@�&Z�m�x��A����������
|�:��s�z���q��܄m��WO-<� �7ӳ��]�bF9�'OM��%�Ӫ�����/C��}BYWΒ���*���Y0��gZiF���L@"��2PJ�M�VbU*M̗F�n�b֣Li��~c_6�_z&�4���n��(:��>�+_s�O?f=>�ڈ
�/����)k�z�$���l�]l���v���n���tX?��O2CEs��f������M:R�^U�:7��*�>j3��\O�ʎ��Ep��XK[f ���>�����gʟQZ� ��I�x6�""VLM߲�lB@Cnȵf7��
��|Vjіc�C�!5lz�%�C����4�g��|q��H�=�s�h�Ȳ,�������m+Ԍ��f�b��x��Ki����L���]�)�Z$|	�ߟ�z\a�SC:�!(�̳��@�o��W�-t���$�?�͇�}OJ+�A�����V�\�[���!p���2�%nsjf�0���ERӬeUg�P�ٙ�m�[wY��d���!l�3��؜(T4�x��`6,�ֻ�he0~{���iFk|���:���	��C_��@Y����H��e/���K���yʪ`����v�cю�NqӔj��x'U��\��M�ԁ	���b�Y]L 8h�~�RՉ���)�pHE1(�Ǽ�D9�+�o�&cw3K���>���]�қ%��1�lcn����'ܢ;��s��ăP�Û��ٙ��Kd�f�8c��Q '�~�������0�@��ֵ�E���IvF<��7!VHVo��O�C�� �:��6�ZPxjja,�>�*z2�T�KvY=�$]&�6]��^c�.����?���7�
����5ՠO�"�M����7�O�]�Ǒ��.��aU*{��G�%2����-�(��W��!�\�������>�!Kv�$�:lx�|��n@����������Э�Z!ix8�B�:�	�pcٗ�^o������z��`�ORHɘ�X�Q�)��Ķ>H]��"���K�U	̼u ҙ�w���$�K�kꅮG��#"k'n��'�K�z�#Ӵ��5/���JN���5�6s���V�+��g˼-�,�v�n�
4w�#e�a���M��v�e$G�ǯ�����s+��~�������2�۶��V��|�ɯk븗�lE��M��3�����+�*ٰ��|!"�E�ϗnA����םN���ǿ�ݹ�����1y^��Q��)�R*�/LL�I�sO~|�.�&y)�4�=��}Y��3���=`�`�el`l�M����R�w78��L��3
�N�>�2�ړLM��8䎽B ��2\s��u�>G;/�}�����f�r-�^���F�L!���Y�@����)Y͟���EYR��L�v8�E�h�ɇ�;r�:>@��1�ɋ�="��4�ɣ�A�KX�h��&o��Z�Y�z4�ai����f�x16�"�z1�{z��v3U� ��]I �.�c߮��Λ�8ߖ���3?SR�|א��wd��Kv��6(>m!��|%��%+7�s�j��&�C�`�~/����}&_�������

KݩnZ"6"�#��l��ul�fU��=n ��j��V��I(�p1h�F��������I��b$y����[�.%�-_
j��O�p�uؐ!"�1�&�q�' ��H?e�����ٗk$�;l�b��!�#��Oq{�-2P��gڏo,�D�x���&LdJ4Y�_4�k�V�Rm\�$������� V��	Σ�(M�?Aaf[�g�� ����̭V����;�s��д(��-�ĸA4���o�@2Z&0�G��	'Q�����lC^C/q7���EQ->~7}}io�"y<��&��$l-yI=��ZW�!���0��[��g함�.6*VҘ�Ij��P���@���*�O�f���`�Q�vѫ[�� =����'Zt=��ϫ�]
?}�� ��V��c4���L3��T�;���)�r�����+�v�t)C��&<��1��2 ��<�Х��)�fR��J�(L�OƧ� Tٹ���ܿW�̈́�*c~: ".���"�<'�**280ܴ�d=
�U}�*�W�7��ʲ"&l�E�Gr/k@������C`:�d�0�Ɯ�b0����Q`��U��$T@��c��Һ����Bޜ��G���q�@<�i:��lYo; �P?�`�;}[I�Ϩ����&��(ؾ���)*��`�(UKz���1[�2J�-�/ܚ]� �����UI:q�O���~�S|�X��F�7G�W���ϕ�_�V����FY���`}e��` $X���=c[3ސ�^1�����up�{ -t���U�d����p�u��,����>wV�\}�ƣGZU���r`�I��]�Ui�n9���i�ט@yy���+kE���'O�,��Ð!KݘԿx)�嵍���Ȼ�~��q%��!fh-�[T�U;���(s�'������M�^x�x)x��o�˓���gX���k1�p����	��N��oxV�����{���=(�.����c��GG�D�":,�إJ�:g�����`]����^\��!	e��O�8��F8t�N(�����:�r�Iy����˫�t�����ْR���d�D��"Z�>��V�فڷ�F�����@|�7�Ԙ�T��/-�v��T�����n�����k*?��6e����(�	w��;�a�P�P�I��MѦ�"hr�L�]q4�2<�KS�}���Y��_��&q��bA�|����;�{MXl�'j�z,-�x�,&̏���R ����iý�c���V�]��kTǺu:�	׊O��K��_�:1��D�|9NBJ2*�KK�E7o?Q�@�˽�H��&����o��� z��jq.Cl)i�B�c)��	��Ҩ��J�5V�%Z�*G��"hOP�>�M�$�Hx��g�^9l���Ju��@)g�'o�&�6��^�t��l�"ٿ+V<�_!]��9P׍ҳ����e��2�vJ߱� ����,sH��`���R��w����*�����	WO�{N�و]��M�EGl�%mU�n�����F� �>��S�>��r4G�G�+R�M�|ue��j�K�u�Z79��*�^�?��W06{���*a���,P�#f��V�֙�'8]������|g���stJ���[�nC���	����g�WW��z5�J-$��.)U1�̄�皹��k5�Ы�� A��z�l�^W�M����W�����3I]? ��*����#����rKV3�-�01���2y�*���i\;�ċu�i���W��TQ@��H�Ϙ}��0C0C�+����b=/ᖎ��i+}�����W.Z_{�`��$�����,Ƅ�5���Ȥ�[�?�X��]a���6#C�	26����L?-�=uu12��u�Gs�_�����2/���+*�KZc_�sQ]>���k� -�:�Ӓ�AoR��E�Mt9�W�yL��m����B�l�׀*~gn� �_[��j���	E���u�T�6���MC2�����^?㩗(��s�a���)�l�V���w��z���l}ti)V����ݴ������:[��m�Z%��;}�{��ܿ�0R�|I�	��6��/�vkݎ[�����[�
�ѻF�\$�RE�W����1�B�L֗�7�7�͹E0����Q�,�!�F%b�uM�5[��G�V�R�)U��H4�Qy2X`�m)ᛮ;�?�%��B/a���Iy��*�������fV�FJ�~�F��qg��A})�g�:�Z<?����U�8Jǽ{�{.T��3S�U,���	2����@�MW}�����O�Z�(vq6/X䆔��"k���8����꜇-�!A=<�TF���}��M.c�����5�rh�b&���〉 ��t��#:L��k�`����h����٨��ؽ�baP@1Aαrxi�N�f����T�^���=X���eQ�c��Y�� ����ua�.���@��5º���~�R�nk3�:`C�����*Y^�p��
�Q�9���|w��g5��V������.󰑻Erc����n�<<X��'x��SFzٙ�|8&���Sm_�۾ٷ����FF��^�W�7v]�b}���Q�U��#�S�v�k�E��(C]"��Q�V���z�s9A>�q�����4���h�^�Dյr{g9�[u���'#e�J����
��B��Ne�'�9P /b�ԁ�ߒ�/=��@��)'t՜�R,!6#bډ������n�g��O~8�Ya��!ѫ��0�C��6�eE!9�T]`ĥ�� ��Gy���X�0�c\z
e24��Y�(<6lZ���Ť�ݒ�/O��v��t�U�b
�,���ab���y�C�xD��&���(�Q�(��a�޺�-bTw�x��5):����i��&b#���j�a��Ӑԃ)�m��d}�K�a�a[t�IC�K�l��_�^o��MOV�)d��l0o��}=dH�uw;t<b�8�q$Vb����&����8���q2u
�}�{΃���؞I��mU���t ���v)ƣ�K�:��ryd��(�A�"G�\όdx����'�z�8�[G�2ձ�
|����Q�A��8r\X�}���=�yAܒY+��;�C�Bx��l�y�in����#�e@8L8������k(�f.j��`����b<�D��K]�Okp�B���E�9�b�-/Ɗ���%B��	���_���B��Q	K��>�j<싉���C9�i�}�7}_�%L����a��,[X&��G	�%��3�5{�;�z��{���㶵������=��PI��|�2_�i�ZTu�X��s����,3�eoQfQ�I�0R�!���^��S?��7�^�p����슭Q�i0\�\9]��ng�j>k����zW�/CA��麛�Xk@��R����+vѶ
a����N)p'CΙ�HM�I90��2���*!t�	��A��OT� ����Rw��'�Ƚ���[ZC���[v�\&6	��t�BrP�"H���P=�ׄ�lZ��"�X�Mo��ˏ������FC<�����t������g �#F�H����P�5gq�6���A,v΄�����ĆZR��Z�h�O{X���I_���ي+�x���IN�p�8;�H�۟��*qwM�l��O�{41�ؕ$��`�gMv�ݯ�&����Pˀ�z�p|��ܗ�,�6�&��TH"s/v�nUfX��xQ1��#aC&G�*�ǡ-�L�DvL{x��"�_5�W�U���֤��T+ZB$���HjS��^��Q� ];�FN�������[�"J�ث�?��7�RA���d���b63g�Ҹ}��{Oٻ���t�Z��9{~���u��/�l�5�C8!_=�����Zh@���wT@�c�!��H~���o�c��R�a9j2�, ��}햓�����pޚ��Ϛ�ش���d?^�4��Qc�c��N�N���l~J�XYorH�9���m����ߺ�d����A� 4�Z%������\ю4�c
(ae��~6}���1S_��$�q.�5�h�ި)��9@�;5�^�Z2�R�C�������3e-�jx�e�b,T;�\�WQq�Gcº�i[��H�{�2C^����C(Fl�H0^nw�D˚B��dg��=tg����q�I��q��LJnϑ�*�?��?�M�7/�q�)��X�GFyh)���EY�w�Y!�g��bf�e��a�v3�(#n�.���6Y�YW!��Rb���������PX�TE���"u _�jF5�M<���`F$��#�Eu�ֿ��7���l��L£��w�!uzP��Z;��]1#�'��d���<l�D+LǐkY56j9�ߤ�MGP�)�ʹ�b��@k,H�����E�on�\7��s�	G
�%D� ��P��^FeTh�&���f���B��d���&�Q��@K��JtA�u�EX,��������V�s��mJ������n'�J�2MI��k(�P��>����.�Z"��l,ʵ�K�H�dҴ;�y���n	��C�ԗ̫�j��u���MZ(��kn��[vVՋ_�\Q�i۔�K�V�5
Ρ�3�8y$��'K��:4��Y�^@�s�[�xb�o��^^�4r��8��(5�;q�����Lc2Ƹ��)`QZGj�9��#�k,�"ޤ��cE����,�r���������qA
���yt�����\{�\I����	�+�Rs���Fݯ���lNsu��˭:R��A�"�L��m*��N�PHCu�㪣^$Ei7zNIM��8�wE�p�����%P讞�A�i���C��k{@aS��>�(����+̲�R)�P
b�pѣ���TqW����1�;P,�8rk�,�V�<>3x��&�]���	�����L��Mz1t�Qo2,-���lCq�oڂ�Z�y��g"PȤF?c�4.ek+��G�<��!����x]�|`T 7M8x ~�D�<Axٿ�(�@���R��ܭ6���{�C2�6[�-����L�A+!�e�*$���r���k����z�j��?5� _[j��ŏ.��"	RtSh~&f��Yu���Y#�j�3~�ȴ���p֢8K�p��ʟ�M��/ꤦ;4����^�;���p�ܣ۽ޙL��$��nPsqM(��|��+���ޗ�V�8Ey�UwT T��e���3�FL����Md�5W}�T����pZP{�����"=})�z�''���2Ps�ʜ�)o82����IrwM��>�j�4"�ǁ�&�S_H�c7����mB9��y�!>�z���
1\������u�X�<L�������/;p������9#�#~�@��Ƶ�ˬ�K뵐wCV��5/]J�ǋ}wXpn�-I�o�A# J����B�Y:%�`���>D�]>�jmp
�>r/��L�{B��l�w��@�M�Ԍ��3�ӠH�<��x͆�i �3�㱯o+�ϗ	�M7�ޠ)�y�p�J����=j|��2���.?��t���N�6?���T䌲2աV�tk\�W�_	�j�s�D��!�ʧ���b7�չYu������3����=�ʵ���3�R���4w��_"t��aCwT?=�١�,KR@�;��o
�s��0�k4y1��x`'��sMЖʁSk�]�U!cY�~>�7���ߘG�7a��P5S82|���?]\�i��S����<�!�����N�d�4.�g��T�Dq�]���h�m���7�6�bz��??<�  �d?���:��,u5Y� C"p��*����S�\X��/#���������E�e���u�k����,�<��4��b��a"�� +�]T2*�9NgJ����<�zef�:<\٠�X9���͌cK߬մ>υ��
�:g).���ku����b���.('=��/A�EP:��Uw!18Gq�v�Dm�|Q���Lod�\D���&ܴ+	�nh��Nݭ=ڤ
��4]1ۛ��wS��O�"�����1�#a��m�Y=eY��CvEF��-A���n���^#w,��Kǜ�\�'=�N��hB�rV,'��G>��g��BWb�����g�˨=;����зC!y��f�����6'8R}�T����˶��� �shoጢ\��R�F��%�����9���*���_l��Ȯ1����~"�.F�����f��%��њ��f��7���F�tю���R�����k�k*3ݠ,��n�L��O��+��ҵ�-�P89��H�B%ۘ HV�G�wS�k�R�!q@����iGZ� �ؕu/�^�Ney�+��%F?{�P�A�?�A�\+��͘< �F*
�a�S�i|Q/̱�x�`�|��>����$vb�2��kr�a����Z֟�3�c�j��(M�&�GB�-1pO�=��	F�C�u�V�)Wu�.%��|)j�eE~�P���	����]n��-Z&O �,���w�o	z�G��Cݣ�r�~ �ߧ��l�;�I$$�pT�5�	b�ӊG��3ڣ0���F��֙ZT�m3l��!�X�ER[e�:��⺞\A�	>����{��;Y�n��~n���E4D���������r���z�T��:��w[x�k�X@��~�m�6c'/�kv>��L�y����&�7�
��Ev�X�x��i�&�U��( ޯkۄ��ݟ��=N*���AD��+����2�?ú�E��z����h�
P�J������n�Ԉ9��|�hl<��v��_,�Ӭ�%Ai�J��]Ί�z���V�dO*��1�+S��N�V}�c
�T�4gR�P{������T�0�2���dK�=���.>Z���W���
�aguL�C,��ÒY�)?��u����Z������7a���("0�$�]]�J��s��4�N+�Gq̮Z�v���1B���7o\ ��l|���2~�\
�_�G!�9冖�������H׌�$Y?����⎊���2�[��8��fg�@gy����m��7pq�
`����3�R�yNzK��*n\wA ��1
�]5��+�PmZ�FT=�c�P����8Kڻ�lgٻ^�t�G�ɯ"ب��Ha~]��Q�<�3J��� ����tl�(�����ݬ>�$�۰O9��^6��l^�C�l{6��.؞Tl��%B��wM�ar�,#5��Cp�9��M�۸�lʰ|� ���zyřGaA\��09�Q���,��}B?�n�D����ۼ�߳��@�<��E���v�pGJ��u:O��a�v��[��#m�T~���B$�8߰��?���r���P�	+:���چ�	"��&k9�Ң�S��Q`F�(�������nT����U(�ޝiʉb��e�A����N����%�m��xZ(/�J����rڹ8�E�g&a���+��ǖ*�8��o�qQ��X���C��0�}��������Vɩ��h��U�:���f(�m�4��@LO���I�$�rG%M��-~��|��P	)f�R��(B^���[t۽�j�#sht�/keɓ�|�z���[h�Xp�*L;�X�E���dO��P���G� KK[��X:n`�������w	��3$�`���f�Z��J��f"�l;r��42�A jnv�$�֚3��A#�h��g���]�%��(������8���:0���`N�����}#�K�����]�r���tfj%��ˡ�\%L<[�2��1����ܛ4Y7.��r}�m�xos�Or��b��a�|��8(�1��1㺐�W��$�}�.2�����c�eeL/��\ha24ōC������76DG�M��)F�B���(����+P�ֽy��(���Q�7r�&���p����=�T�&x�K���/�����ȩ6������g��I��X��:��{�0KA���>�ܴi�
�[�\�EF������?�%?�_���ln^�Ā�3ږ�]�n"0����������[�ě,�9⊟tC�e���Ԏ�^Y:.�A}��W}�-�׍9�L7x���xHRK�u���b���Q�c��3 �9�����4~3v{��j�َ��L��P�K!��]�~�O)3<,ƴ[N�hN�����>�sA��%ڛ������=�sZ��\�naI��6���5�׼�������݊�C��	��$�ap���6�m�6�YRᵗ�/��
[�m���!�T�;�t��7��qj����J�mlۣL]F�pqS�@��ȆT��U~ d�q��bL"��$*G�{�(O�J����}��# �J�����,j�e]/�ђ1�)����9$�L��^Z�P�!J&*��[�ui�Q�p�cK��5�j(����j���Q)8i��@���Ρذg��Xoy���d�M�s�E�O����ѷ�ԃy+[N����2�i�Waa�i&�c�.��L��3ͫj&K2R߲�]�PЖH�o�q�ioz'T��s�`�ߪ�M��v���C�����bpH����A�����;�^G�6�i�\�3�7)/�0�˦ox�FX��>��|�K_��'��_����ר�3d�M/֖����"��O3r_¢��ۚ���U ���\@���8Uu:\1���*K�`nwPE�+Ɩrth�+��*�V�U1�>X�����������1�H�0�e'�I[K��7+:ȋ]�W�iMH�5��Tst�ūF�?v{8N�x���6[i�%Ui�����W���bE�"0��%	�|/��3"�k��I'�>!�{گ	��	Nhfg�my���S�-{ԑ

���|<�wrj��DhB�eOQ�z��U�hA?SSLw�,�]�_)y2�2[:F$"����N	�m���Kx���3�^�1v�����JI�}�,y��OV��ƖH H�����.��V�9`���Mg�a6n��X���wE�:@���%JЪ`�����xs�B����)���|�Ѳi2~�w�W���:�/>����?\g��d�Ig@ �ݘH�Q��Y"������C��|eI��T&"|;%E*<�\� g�*��,��J1Y�Z����V��)���f#mH��K�,��Y/ݾ�RD@��I͝�^N�<�������>QV�8��x�0O�qH�4SRt���{��Fc��r��/g����:�Y�F���{�*�-�G���G:�f~+��1�xΣ��d ���Gx�����1 ���d�>~Z�zNeo,�+ ��:���=I\����x`ȏk���/����:n:����l��"+��Y1�"�}��up i|А���{��*Z�c�Q���~��^��d���@�e� �p����=m7?��=��X��vs�B��`_����Uy|�('�v�3�g\k����<��c��x�^���Fy$��z��ާ2=�x%��#@ NUA�S���|c�����0x��O���r�'jPv��r!���e�b20QLD\kRr����X2.�;'ޗ����B�$��e��ĚK�Ŝ���\���Q�~xL�'9�Ѱ����
�t K�tKېZ���M�/�}�#�贵e!�.*�v��Xe�m�(a�ٝ�@��.[h���;Iw��n�5!��%���^�:�z�0�|��MS%|\�f��y}�M�����Y�{�&\��ۻ��'H�8%�k^`bCN������ ��i���oΆVЎ��!"5 ���8ci����)N�kI)��!b+�
{I��>sK�JB݂���w.�������O>]����*A�6����BQcN���`��,8I�Z���>GvncV�������	qӺ�	�q��[�d�a#8m�@�)
ЉR�mso��G}��J���c
�?5�4��s*�y�B{=|�*��c<�5��[P�<IϺ$2�
9骵�#f��)�${���Y�������Li�hA�����Â�bfY+��j��n�Hz��e�_h���f
�s���n�QZ������(��B)�^�Ħ�u�cJ7h�+T9 n����h�����d�m8��|������<�&�����x��\�YÑ�6ۙ$T���h]{�v�y�2�x���T$RO��t����;��L�ܣ6#<���: l�S�
F�	JTǵ�Ć�#(��&��B����e����)ϰ�
ga��ܨ�\y�q������m&{:OA���f)����W����dm��@u�-|=���M�7��?\�$��%���Z �Js��|�>X�DJ:{�I�5r|a���Kh��2�BrXb�� d����xE�,"t��f�%4�H��_�`�;ӛ h���8��8nH����~l��-����>'�^��P�Lz�o=U�����U^S�]�>�����{ZĴ�=5�db���#DKC�����+�IuE2Ҋ�g��5���ı�''�4�=����"�:���o}���.t��i�k�����ޱ�]�����o�_��"�WD�^���J`�v�-�a	u����>.�֒�E*�H���;)�WC1�C����.?}A	�kT7b��]g!�م�Ջ��.=H�����2dA��9��>�����W�x@��x�+iT�my|�9�H�����,ڃY���+��zS��E�(p��x�6���զR�}��L�H�^�|� ���Q��,�+=L,����TG��t�`G��M+�>�+��h����$����g$+���ɐ(����~�gI<D�`T�@�6;�j��NBN1�8s�e��?���������^�����_Uߪ�3M�c�"��֋ f1��ۛ�b��Q-F��C����Jw�L1Oc�ec��!U��J-b��d�,b��$���0,�����ຐ�)��6m�]��>}�����&� {ᤀmU�<�.��Э�E����ZJS�����Цib>v (��g�ū���YR�O%��ܻ�*L�6�}�p���Wft��6�ݴZ~*vcy��������w�au�D��?���Dg�/��{���mȫ0h�@<�������*�� ��\�N��^[':	����(b^g��W9�3_g��IC�J|��X�2����6�-uR{)W���ր�nS��gI�E����-�]�xq\�$K�:�&��KQ��lq�a◳ �Y�r��2��}Y~v��/�n ҹ'{A�VXu��ԋr8+�*�����a[Ë|{t�`]3#2Y��Z�hq,�H�5��e1�}'J�� ��ɓz\`�3�v(4����S2��ْR�>�yBQ��N��YeG�\|����(�\��:"�tbj�� ,(ʪ�뜽I��*l4pb$��*�����(L;�7ht5Xʊy��z����(�5w�!F��6���ƌ�,�fh����m:'�_Y�c�Y{ȳm �-�5��`���"UM��ճ1�n\Y�G�n�r"v�)�˻������W���q��Љ�
����=r��!�"\|S�����s�8q\��W'�z���A��}��]��Y�$:b%���?�S�ˉ<T�]�` s�Su�WF��1����Ƶ\�W��o�׍	T���/�.��0��&�ؒ��v^��#]��%�Wq{�����d_#��*���X]�붏��3B{pP�y_�e�}�gu���9��1��j?��,�fO��}Ǖ�ۺ�$v:8�ʷ��W(�B��2���
�G�+�}J4X4K�������M���A�� � +�H#D��r������ls�J|{tx7M"����ȎX�����v�^[�݁6�n9=�8l,E��6���&�gj?�^"��A�/�?f�(�!���~�t$��lCS5\]U���h�Q.)�I�ߺU���|٣?�c��>�u��h8����W�Rw�:���Wr�ޡ���[��#�*Ŋ�-��5�Hԁ?Q�e^1�$�
�&�#�mh���P�ܦ�U�T(�ȯ�v�cj��1������v���l��e3�$��L{���͍�'��'���Z�;YT�ќ�K{����E�qT�=52=E���d[ө��Cw,v�+s��^sL�>�Mh�H��8�f�������H��y����K�w��%�0���qN�E	-}X^��-���޻ی�5RP�+�5Ȣ�mk�.��a1I�Y�ƊZ'I�җ��0]�U����7v'�!�\.����>`�����'��c6�֫H�sP9�
�3���q+v+ k�[Pq�BI�?Q3����f�9}�-��Ao��i���L�CN�g*�	>n�y]�[��f3"���F�=N��`@Q�O�q+�җXt��q\	_/��aՋ��Z�ah:w4��l���G.Y�2񐽃�̻�O`�@X�o�o����8�l����3k�S�/~�su�i�(3���/���(LkM=rV���Z��C�=����H�)��J��濱��33���  �$���
�.���<:���%/�-���0���9�A��������-���
��X�Rc�����} ��2�WZf��Ք���r�@H���զ�1m��D�!i��F��K��x��l�����*�R��?�0���W+����g�|��<�W��?��(�e�8�tM�F�`�ϳ��H�x��b'�=b�;Kv*��z9u�EYk,�����,�����    ���F0 ɯ��������g�    YZ