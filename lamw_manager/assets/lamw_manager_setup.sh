#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1419513837"
MD5="af6a6943221fe8c60d07f861333c2444"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24540"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 18:36:22 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
�7zXZ  �ִF !   �X����_�] �}��1Dd]����P�t�F�Up3>���U�E�!g���C�ك�g�y�"c�($��a�^����w�̤��NM�GyC���&��z���:�V�& ��^P8�����h�I�����%�w񰦮z���ܦ�Q�7Ɔ/���!���;�Y��-�(�A��N02�S1���4Ud����T:ˢ��{z��s��5�@�w?�y���dB�d��.=oC�n��l&�=��2�� k���x����ޙ7�����92��sn@O��Ǚ�R٢�<�X�v��_~@XqR���g5�t�w�)1E�[�Uv95+�o�xw��_��M��{���N�}�޺X�e����2�#ITU��*��ȱ�TC[�J�O�#�x�Ŏ�¥�������O���_�Wz�| �O�p*`�U�sn�5��u5�IHAf����x��nF^498RSuL�=�"cy������n��)H����
u��x��\ɧ��u!
��O��Gh&^��:��aW��9o�b#>X�[;�1gRb��2����@�yW��22�B�	�B�٧M�F���D�fO4w;s<@C2��U�ႋ�'-����i�h�������qC�3K� $ ]a<��$(�R����q�$�I��p:�GQ	ۧeR���&l���@8j,�yS7��ʮ��������e�x[��R �{�g%�0o�'���UK\���go�9�_����`y��rx������b�#H����@�s-<:����Z�=��8�	6{XooL�k������i�~�G�f�3f?B+%MLvk��ZG�|���z�.����c(2���i��������S3���A�ц��E���˕W��I�R\_f����^W4F�lX��a�c�K��Q@»I��(_}cN����c��$�󻍾�ē[�࿧�a��6�����9�j��::d����r���~��2��W���P+a�ٲVwU���Yz�?^�\Nr���^00�A�P�(�5���A���l�P8:{�_�v%�z��I�"����cə�W� ���sz���$�����f���߃þ��⃻�_rv���.��h_�����=��."�-N�D0��L��d���F.k׾g?����|ʧ����#�Dv�LMW
4Aֵ,f�G �~U�oS�m��5��cV!�Y��v��O���a)�<�x���z$��L����V��>-6`� @mS�7H**@$�H��W��~�\��~�wG�g6,��>��g�<�w�Y�[�MC@�s�@3�]���9�D�����P�L\��&Q�JԞS�6<?�V�<yI
�j����#hP��=Cv\*���L�E��>�¸�_�=<������-KG �R"��l�1A+D�����ӵ�7�o�M�NӲ����g`l-\Z�	�`�I����fUcd����!�xq�;�!��XO�?�c��M�.����q�,W���>`5a;��*8d[L�����2����?��c�d9�o��L&��V��v�1�����m-�Ҩѫ�椯fq C���@��q�S���W�����K�r}������pKɻ��qhN�2������?�>�s(�d�y6G��i}��pn.e!���WL�0���TL2&�u~�V��XWk��ݺ8}GU2޼�,[�������WФ�U��l�d��wWF$�<�%0R
��C��6	���_2n�ļk}�(`e��q�b��z��H�I��
^����ex�� K��h7�2�(��{�ao�P#���D~ 
�5U��τ=/�"�(w�]Pȱ�Ah8�|�Jf!I�2��u ��7����Q�$G�C�筗r�_A��W���������$�
ʢ^A��0q��լ�P�hB�H"���O^,Vvl ��}g!����_8L�Ӹ2�����Xag�(�Ӎ���<k�cb3��Ӊ�5�&O���#�<q)p�o�xq��������A���΢�f�dE�YF}���������v���%i�wj��m�<`�z� ��@�C&��i���)͟��]���%�(O5O�D6¤-t0���l�	�9����\>���jj�Zk?nT��
|�`�ޫ�"�n��%H�{���vh��	v:Δ��%� �� ����f�m�G1d���W��(�����^�2i3�.�}�S_q-�.��S�6�n���%�%�̳r׾S�����e��8�v%M�{7D!?�����'� � ��&�]u� ��#�����n��!Ѣ$.���1��Z	I|b ?nƼ6k3`��g~�CY��A"�e��(#��u�u�#���*f��p�;���Ǚ���7�9*\=AC$a��<2-����p�z��Q�{��W���F\|�Z�����b�b�dg�lK$�6x��*Mʫ�ӲJ�����˂��3i��}��u�'�q�0?�L���{oE}��2
��ml��f�4��r5�˸�9)��W���A0N�`mb��gK����)逥u͌��N��
FC޵��$"87�{�m?]췙�pm��Yy��ҫL1�Hq��{����P��H�����ŭ�uz��b�۾v'��es��Ʊ+4��f;v�Ǟ��FzJ�'	K�Ą%��>��mz���H�`��q�M����h᷉օ�;�������!�b?A���Ը��z�i��\�t�c�{���m�hn��U�3_�3�T��� ���+	��Ge��B�L�;��=`'�`��Y]q.ϋ���p�>Cd�_#�O��m��VO6w]r��0i;�75��]��W���VL��&5x�īQ1gl��Z�)���y�n`ʕZE��+C�KO���;���fu�Vh�{sɤ�&� 5��?+<鑀��f犍�b*���n{-�����������n$nv7����C�̍�}��߳#�S
�?��|񆷻V ���Q��t�Ɖ\ڠ�\��]2��K�G����ђ�Y���'�e�I�)�7OH���A�҂�;����kr��W�
�*���ﮮ8�c-��i��_���݈Q/n?D4����(�y�N�<�k/]8O{���l"bJ���M�����5.=t��߲�G��O�)���S�����븡�*I�#���7h��Id��g]kxnG˳Lb��Zp4cO�%���\�]��>����Pl��i#vI���}K�<�S��fw������fA8�N�+0����ȶ\�og��C�_�J*��4@�~��o��]�w�E`[a{�i��1ᩰ��F�mZ��O�P���V�ŠO�G,3p��[��X	��*��UX�-�O��c�@��ޱ�!X��0i�~��R8&��"�.�����Q	���������k�ƶL�#k����E�I�8펦�]�7m� Ʒ�m� ��X_��SD��Tj�,*[���T��Uٚ_�d��AVa���=fa1DO��ii�y{F?3N<�ʂi�SU%ʽ�O�2�T��Lbu&�UK}�d��(�5
υ��;�Sf��~EÛ�j��Zҕ!�O9
���%$��;G���R+Fb%ݦ�ĂQb�v��]���6��)���>�:�JK�T�3������.������D�=�3���Z/g@�|%6��3��X쿍�S���!����ݟ��z���6�|��`лS�'�R�s,��'�Q�6��4,�
wd`�s�Jv�)đ_��E����i��ɯ�7�=�Q���c�>�*]���A�,j>5�H0�Jf���֔͊'P�CSb�8S�{V��68�M�8L|����*�Nq���H�:�!H��qcW�A�3Ж�$6�@=���k+f�b�8�ʘ��煆������/U�h�~tX�	�12b����-k��G�iѕ �;����!������	8�r=�~5ЧB��Bd@�"��0P������QZ�X@�5v"c��-Y��'{��'I����p��A�NE=�S�� D<��B�ٷ=dó)�%J�c��.��m�g���v���Q�d���&�$���CNT!�uNG���|��+��@+G��p�Ȃ��!���,.ୣ�+��X�:cU����}W����sdN�� @\�~~0�s�C�o���E��SϨ�����٘2ȅ!���'r�Sh��]E�MKh5�=E�<��ap,EY|���U�oF���/�l�ܔ�K!��Y��M�����;�0��0Ȳԋ�x��rD��*K��q8Ǵ-�*_��E�
���ߪ�&冣=�.ME͍f )�ؗ�6����
C�V
�_�f���cR]�=Hvl��|9P�y!���>O�![A7 ��A���	N|�L���@��|q��̖�W��i��}�E×Q�����Q�L��;+Z�&���?Hғ����aV`��Z��[~��Kf��.���,#2T�>@�Pl�G���*F�#���e܏�iL�7K�g�Ԑ߅E�ug[��l�KY���y��]��Q�M`�������I��-"�Ú)�o��z�N�"���q���~�	1C�>k+��>��5�z,�u���� ���L�uG���:��CL]�DD�y��U�ӵUh�e�v6�b�'�����2��QИ����m`�iu�=�s&�ʯ���|�r�ο2��Cj:�I�yGG���5'�ǼC;�I�rZ��P����ŕƫ��цG�s��
�(���
j�ؾ�`%�׎�ó�!mL[�h
��,T<رG�Eo�g�`�4�m�z|��/�����<��|�]N�����i�PZ|���DXX+�C��������{��65#�(�0w�n
L�����&(�Ysq�{h�
"��N����������L�!P�=����B�e��Úpբma�S���ߦ��}�X8���m9�+М��:�apo��.���~ڦ/�8�к	���7-�&���o�C�>.c��|�5#���.�Բ�9�����%iJ
i��y��GNÕ_��a�g^_R~��D.N!pm��DyEE���4Q��Ał�ͪ�s�E��`��rݨ�}F@���{�������uC�����l�<���t{s�-�~  9�%�ƙ��g��q�>�yM0p	t��D�}T�3,�2��i*���3��f���H$i?���O`������s�Sm%f
jn\Hi�Ñѥ��7��~�G6�@�qx����S�Ǿt������%�!vy�f���W2�m���'7�lYG��zbM��x����I��Jv	��>�a70]�[<�p���V�*�iE���əW��9߅"�h�w;5��a���L�No�+s~���_>ڄ��d���+k�R�����P�>*2�����G	��X��Ć�B�C~h����V�]k���=(m͏G�ٻ�h:j�J�)kn-�H�4�\$�O��.�(����\X.e[q�Ml��v��y~ӵ�Bj��YT��%�+0yZ�x^�o��Rr<;nIbH���ŕ��Ldl�w��Ö�����*��&�M��Fl�P���UU�7W�wL�[r���*��
Hî�'T4��R����H� �Z������N��h���BM=�ʾM� ��|/��e�>��f�?�
I1���ŐW���xJ����Vױ<4%{}��)�n��zN�/5<hl�f��߫��΢��B�v��k��raw���݄MA/��A^�l�\���0�Z�jC�n�O�;k>�$B��؆e�;���rJ�+�;8�	S]A@+��Xɋp�G����'�_*f18C����5PW�a��U��M�Kn�Q�C,����3�=�|���W�tv�m�FHp���|�t���w�ϻ��=�"u���Qx��w�#	���&��8g��Eyd�-�A3�0��Gk%�;���Y����k�X����Yd3;_�P�s�+��d�J��	�D�`�A���q���6�|Ҳ�-W(hV�Z�g�W-���~1A�C.pp~�+;/iα�
�̠��Nq�EZ�RG_������0�G�r�L٥����Z����?IyO6ʒ��Ҁ��Y�_�S�V��(��Tr�H��x]������M�/;ݑ�p͹�+������ a��f)b�䯾�;6\�JG�l{�n�9��k�[���w�8���e4RR�� }?��s�6Y�H.Q$ �wT��D���6�#V�cKmT���<l�0��J��[l�f><. ����&K*�_6���jX�Z��=|�l�ӣU�"�]k5�@Ǐ�����(W�KPm$��z^��D<��j"��d��	P|��G~�V��zg<oX���.���#ʯIv��/�3��쵗�/7�D��:J�JP<�m%9G�@����mNМ��sgr�)L��7C�z�č��^F�/��xz�&���Ѻ
j���?S�+%M5wd���J�+iR�� @�	j���,�>�������4����;V�09�f�ÁDQ����i�����u�\9�����)��;�I�X��>A�pVL�k�[��6���!�#�ƈ[�9A2�U�sr�n�k�2��)�Ȫ��>���k�4���xf�.,w���/�cQ�f���tK�?��0�D躾|1������;O�5��+�x@i��x��hA1��*��)��`*���8�h�a�Zі��F5�9o���W]�un
��;4V�M�l1P)��#^ݨE?��ɜ�N�\{t����];�[���Ƞ�5fЋ7K�o��J�5�kj�@��| ��2�t���Eͼ�D�f:K+P���b(j�`�i��M��6ă�}���Q����+��M�� a��=2�u�-�&��<K�\_?TT��9����J�����ک�K3��BJ�.!���L�"�d~��jh���������lGُ����Q����^:Tv��V�+:@�X�l���<�׆��w��=L\5��a��T�Xu��_6�nO"�ht�p%!�m�}İ+r�pK����Xr��!�	k�7OeLq�
q�Ω�D	]��$9Iߙ.��(�Ш��j7-�t�"��7D�ߔ���2I����4Z{^�RX1��S�����>v��'�����}ż�J��i����9�d���+��{R#�gΖ�X����3�Qza8C���2=a�%��)�U$����_X�}0z1
�N�C$By!
X8�̱�t	FG�E"�g;mgd4ԫ���j��N�?>4|��Ѯ�\�m)v�g���BcӊiU?�(� x�(��T�U��N��v�h��c����������G)��~-��FU�(�:��(f��Y�C�za�k�����a�h�4-Ѓ`%���Z�^O����S:"����4o��B����Z��	T��x�"�Q���.�����?m���G�Y�f��/v��MVZ��UJkKC���.�J���D���}�fĩ�
�RU�>��q�]b�*� ��ݭ3O�8�K���dT4���'���Ɏᕻ1�����	��O�2�s��4Ա��&�_�E@4r��)��kg����w�(.6?�����&aC#:v���lmϋ�E��Al�{���[
�p1�3E�>J�g�f�c(��F^[+v21x9QF�gv{���M�乨3F54��#�;i���:}�uz�n]��efs}��*����7I(;v�Ӱ��ԝcq�|��D�d�YQ�6#���vxd��C��)"�"�m8}���/j�<ğ�.}#�9[w��?2�~�0�%(Tx�Z�u1=P�S�˜�X51S�0��醄A�6Z�mp�hFbΒ\����E������8�ǳ�4`J��F��,�k��T"������`ܩ�We6�n�4�s�n�yr�9��v�[UMWv��ZF��t��7����'�5����$c�-�EI���u�g�z~�b� �?.���]��p��;?�&}��‣M��Пb�)��"���λ�W1K� ��*)���}PZL�pPcO��i��ZF�!�͓�p��͗��h[��\����3��Up��c!fK��F�67:v�i-0N<�}�>�&��8ե�a���������"T1mX�v�/b�9���Z���2�5qv�»ѣ��{��2R68�ۋ4߶ō#-� ���{|��(=G1#٫�L4�^�Ϧ}��yD��3U���Z��|w��0T	��dE�AT�5�Qb�S��KH	sh���D �	O�Ȕ�NV+�y�"��]�	��������a�!h�Ik�Ę���[d�<� h-��~�`8��x�V��}S>!�e�y�/8AD�tZ~�B��H��oaJ�!A��C��x�JOM�1��,���>?a�q��)�c�|l�����	��-��{��P�:$�~#_"+	7b\��a9R��L8��X���M�-�:Q�bSu�c˴ǘ��i��L�w���MO6>�� �L��J��\�\��t�,M��������ѵ;�P9��Pc��n�3�/�}"��o�46,�c�Dw>���0�P��?U�.���6���Kh�Y���< �F3�`�a����l}_t�a2���j�y�J\]I����KF>3��zW�2�+��� ����%���9� =+�We%�Az���ȴM�ڥ���-R[��G9`�fz��Luǉm>=��l@?+������XJf!��'ӔR!�P
o?��� /H\�~ugͅ��,�]y��TZp��%7?�з���˳�Ҋ2�c��bv�J�?��> �p3G�ޑL�����s��V��E��5ϘF�t����*�N�����(�Qmg�e�O{���)�W���lG:Ҳ"�3�-÷_9��C�C"#��w*bv�9�J+@E�,��0r���F�粨�TМ���������y�I��^�#a�$Ø�~N2)�)gD/�<X@Q��{;09�j��5�J=�Pi��#���+� D�JS�3��eP�i�;GyQ��آT�K'�Qe=x���	łE��9�_g(��v�j�k�'��-p�����Ze��}�QDn��g��k�o��h�ͬ�
\��~މYٙ��󚚽��U�<����v�s���o٦Ga͓ʟ�RHd��.�����z���aR�q�:v�v���Q�#M��A���� &�1�P��^~��t���씃�믆�>����Qn��`G�U�}K=e�$<�[́���KmP[��=͑x
���6jya8>N
��gj���1�z7�\o;%%kc1��r;9�� �����UF$�YnR�����y����nv��(����cr2�s��	[����ӄ�ZQ�/D�&�ʫ��cY�4��Z��.�������p��"�ŋv͒Wؒz03�{͆��ۓ��w_�7�r��{��B*ڼY��`D��9��5ڿ9���n)
ߵ�قdW��*&y'�à�����ce�ªw�(բ�3����v�$N[�鹧�?r%yD�?�ol���%,a06D_�]�90�>����qHI�}w���W8����t�K���!Y˼9�8��}��Sƙ��	�m�o��j(6OA�~�daU>���[��^_��o��UI��HoE
b��zN}�����;˕��*(��o=�B�L~>�H�������` m���R�+�΃UP1��Wq�q�uv���S��c9���,{_G�&��o h��n����!l����sW���q��-���W�jp�;���H���ǣF����F�ϒMK���b��W�Ua�_J�y���H��*R��=�>p��,틋f���Z����M�8�ԕ&�d��2Q
7>
!h}@����ER��1P��9�+�n�YD��/�����WgX{�mb�$w�4����Jc}��`ső3��fH�l�O�3����1ؖGs��DC{v��#JѢ^Ώu����Acg-�V5&6po��jB�u�?(?��<qسȀ�����	 ͡��⬝K�V�xbw��e!�I$���F�ﳝ���w����l�h�8�u���΃	��Ԫ/�Wn�|83c9���.�:��s�B�D�^�@�xsDj˼|�����S���v'�sH2����Zg�B�#q�PnMTfn��m��o,W����9D{K��8���"~p����td�'-���W=��T�F؛G	1?��mI7Ա9a9j�V��Zt����-7(�*Ei/W��G8��O#}3�;���h��VF(����_l�d��@QO��Z��,�@�9�1��G���M��}��,*ܶ�17y�h}�s�ƶr�{�UMM�a|������g��)��++�a� �@$8��;��^EFj��%/H�ֻ�X��ݖT�'��屵��l2�vt����\O��������B}���C�'鮰ag�1�̊vy5�ֽB�^6��1o;?�;"���UnPY�`��������@��+!8��\h�([��z֊�	�hB�֎+m��>SMQ8��ʗ��A��m0��J�п��!���FN���sP���"bE�r�W�D�w���4&�:օq�%E#?&��a�� �j���sr�u9�V��e���v0�pؖ$jS�Do��C�syͭ��.H�(�����2�\��{��ӿZ�%8tZ9��b�s��D+�����sQ��˞�q���$��0ޕU��Ԣ� z�c���!9h����v��ه&�#5�����	ː
&�tۜ�4��z�2���W��z+z��Ө�I0��[q�)��Ђ�l8���8[j���2��tV����A�g%�5p���v�]��c^��aY�/� ��̎������zp�	��(��M
#�e�Aٽ���b��S	��
������d�<L�C��C*�`�GW ���.e|J� dwC���0��#(������]z������]6������s)�$n*L���=WȠ�'P]�d=�:���? ]��^�.��>dI���R�H�_���rw\ Fbs9> .ֹ���3q��P�����Dc�B�il(ѷꏒp�^ֈ���8Y�:����N�r�P�WwB��!�������^_� ! P[p's�Q%I�fGXϱ��>���P�7 ��q�B�Q�n�GZ��ҙF���2<sC�xl'�dPXP�}�K\�u��w[r`9��U�'D�Y�6�^�1`�����?eZ߶\I�Ó��ڵ�����d�5���z#Snx��H�CoS�������r�������*8��GK�IUE 2�PO�x�"��5�cSUP�Apc��&%�5���F<?k����{da+�{����A��K ���(��!sÑ-'�7�M��@��i��y�Ƈ|���;�[h�{�R�����$EF3�!�?�A�`r�FÔl�w���G�3$e��<��-���*>T���;����,h�J�8}mt���Nk�s�c�^㱼7d�Uo�=�����`E�H~��B�������G���%�/0T��]������xB.�&�:A
m�U�M���XRa�G�#6J�7;���KN��(�0�X�4�˰���x��*6�c�݄�r�Me�&�G9��"��τ^	'+#OsTArΤ���1�3���.]�Ǔ�# �s�J�A6F: l�d�0�]�'w�7��.��~F`v���Xɤ��K|���"����}!�%����|�G����^��C�̱�P�5���XW�YY���>}��$s�����=�;��1��febq���$|�s��o36���sߗK�����ˊ���+p4O��/`-��'�VX��	 F��f_����$(�GT����W���VȊ��@�!��q3�J�+9N&7�jjDt�������V� g��t�`�F����T-�'�p�7s"��XX	�{��}���*�T�X�fՍ�Kwo�0�|h'�#��s.��[�8��ڹ�"���Y��|�ɽ|�1�x7���?K�[/�z}U����!�rɅ���44�><@y�]����&ɒ��,��Az/�8���e/8D��_�ƽ;�����HM�ц�Pl�]N2vH�ڀjt#�|�Ģ��:R��'dB��>]t�(��ɿ@�?%[
zdՃ,���kg��oO�))��5�/�v��]�ǲ�G}�q�X,8[�D��6d!��-3���cE"j�ч_J� �.�:�l����W�LG����A�����B�4KbLs�4�̸�����l��� �e�R�2:V�o���L�X|k��/�nְs˾g(�e��h%N��n;f�U�#��>ӝE���yD* Y,y}yvc2E4�k�M���췁����U�^�=oI$\/�T��KOH��a?f�tD-��f�*���������e�c��� ^v�l�IȺ�&��h��v4�H��8Rl�(�l�}�N�@������}nv;G�[����o�L!T}A�����>�&���3ݎ�̋�po:��
3��2)��,~
܏�$���(�T �T2�{wI3��Tp��6ǢI���ge�ivp=ͿZP|^[�ؼ_�����?��/�;ɀ�t#73<�V��G%����Y}>ޯ7v9.������.�QڬrNKϤ�v���Ȥ2�pm����T;�X��[h�������Wsoɇޗv�}�*�Kcx���"#e� ,���;��,ifѻ��4�8��B�J�ȣw��6�x�!d_���U�C��y5�x����7���<�h�`O�T�vU��Q��$�ڌ5�N �!��G���g��[���bR8g/usx�����:�:_�7��}�� ����-�@Ѯ3�F;�l�"w���Η�{�}����~��H#m��Rת	����$�69��Ǹ֪�wBjz�:�L�|1z�bB�������dv(Kaf��(Z�+�߼�:h2��.���:�7[�U����\&�-)G�����n��Ψ�|U�5K�x�7#f�8��#�"?���ⰿ齝�{ȸ��ὑ=(bx!��
	�'|OoFYf��Bmh+M��۱�קPu�R*��0I��B�񰻙2�^�Hi<���J����j�0&����n!2�ڑW�F��;��F6�	w(�;��pN�8�,��է	�I>�u��|y�oE֮�Y�X*]v��BY���C̍��Tz�4�v��U�=���y0�f]������`=�!��\&D"�?C��S�I���lު�w������[z0>1��8�6�p	�$8m\����'�:#\�Y��%o̶_�-J�/��s���I��zq�����|�U�P�QF1�R��I�~����uI/�9�*�=��G�҃��$��
́9�UC��Q|��ͣ�S�.���۳r���yb�{b��G���9Ȋs�~+�p��ZB�3@C51��ƥT^��ʹ��o�XL%��
�Z���Kj�v�ܙ�K��Z�nLE�ҙ��-|)vY��>�M/�m���a8��[��n����@^@����~U1��m�ۜ�L��}��f��3* �N]D�S�b�x��ک�=�$��V��C�u.<���z-�^,�?ݬ��-}��GL]qB�i�|�'y��V#}��{������w�/�R!$<��-er*��f��ԖUUx�d��491d����C��]�k!V�T��⟺��XP`��&LX":��}V�K)����������Y��$b<���3,1��o�}|����p/F�:�kEL�H4[~fg%L�<׈��G\�|��
�w��w�X� ǗFa��ǓU�4��:�׍�#&�Ѷ�>V��vaE�	Άp�]JH���ϐ�Q��*qSp	y�(Ϳ��d�u�{�h^e��3I�T������%Y�
ho�C:��͆��k����V��eU�#u��Y�p_�@��O xv�r�3ӷ�h�����ppJ��f3y��糊�r��Rx�Z�7��� � �����q��ө-yl��uNs�����]8��F1^�_�n�qc���y��D9���/���q2Բp�k�#�~W,�sO�-�8��{�$�%��H�5yi��(��ù�%A�������L�D[�����7��!J�����8�jd��n�b\����� LԞ����h,�Zq�?<���m��s�(��.��I@�� /����;�<M[���C�ȭKy]8�7"̂������>/���Gϥ�������vƻ��.R�I��/���`i����Q��QK@���tB��q�A�����;�#�f��f��Si!���_���v�rU}Cjx ����ְ46���9�)E��t�}
}v�/X���S��TL����џ8��"�{��5~�hc)����p]��J���-J���A�܏�J�\��� ��1%�6	@gd���Ŕy��^�=	�!������r��U��dPm�6 �<h�)?jI��|�}��B�E�^�z�#`��c���%����9�H�����][��� #��al����9I�8:q+�ќ����q��/��o^�Ԙ҈�����+򻻎�G������}xt.s�͖�b��դV��);�p��hv���|�B5����꤅_R�ob̛��xW�ş�}{�

޼�FH��8!ГSow^6��ybpA2#97�a^Z��������il5�@���m�Bt���س@cZ��vp�����C�"�a���V4[�Au���dg���lC�3�4���S��X�����7�����AF%�ۄz�YLN��r���8P�_�F4'Dg��,gރW�:Ɵ�H7s�'`=�ƥ�F�{��l_�*�а����O�\h�¢��l>��$� ׊�+5�9
R����o���2�.�n���^��=;;ݫ/av�-���狉�*7�\�
j%���x�Mf��̵�UZ�pO�Xi������'H>$ �,�3'�p#��5Y�'��6�>�(��,�Qw9}S$��ٯم:A��Ө�����o{�.Y���#y��c�8y��Y��h,�~�)d��Z�a�7�iI�����*1�
�{vr�Lf�¼�x�� 1�$����_��w�W�B���g���q�E���P5i��f�(x��\<8u�)96�w�J�'�T$./t��o�$��Z8왻���L���������,��1����D�)�q�b��bHpVM���,�����䲟�E�?��4v� ]֭%����\�T�����O�4
�xɭ�Q�0�Ns��nS`����!��AX�l$�/U,مC�p��qw+S%���s�ԇq!;��=
nn�pcI�ֽ� ���@0/���^�C���ߣ�����D7]�xb�u-l�Z_	�Q�I��iYh��Z�u�� l<?k�AE������nJ��M�9g���
:�g�p)r�G~~*���Zb�C�*Ëô��G!u���f,)���_�A�w�|�^yݱ�FH���=a�s��w�]@�T-n?�؂KZ�)���/-�p��[jN��a8���#:B%A���ۯP�S=-NM�*�C��i��P�++�%g9}�Re.I�Z�͛������LS��\�n؆�{�R�E0�A��|��vnE����%xN<gf燐5W����m�W�=��&U��zkKG=��p.�c*�4�BB���P����Fpj�:@�T�	(h6������c�\��N���|,i�'.%���d#�.�Sg.�D��b���Zz���BfD~ϣj��>6��&\�#m�W��SòH��|/��h�q�ɻ�>WQ@N��2�(�e)�����7="`M3��R�I���]�s�3�7�`�C�5�6��_i#��(���;�o��c\G�(��%���<T@`4C��� �|����?��I��D��;���2���d�ϋ"�I����֡��y,ޡj�;�z��{
�S�V�����$�f����p�������{jB��O5�ԃ��Q��7���>yh?��mw���3_�fB����O��؈^7�9�u��̤uh�9)+�"�5���Sþ��Oi��a���p�TCg�� r �
�	1��tO�6�Kd����V��o�Q�X+�s��J̡�ب^p��]b4G�E��hD�|���BA�a�~wO5o��5�"�'�	z�w׍c���.�C�P�}k�dpgtGQ���s%���`����׀Y��XB׽c=T?���� '��=ea�o�� �����F9���̢ �T��?�����2��������.)��#���˱"�8�G�WXf�i���7ֆ�*�V���b;M��$Z2N���:7��[�㩓&���J�>(fw^|{_���\�?�5��Q���&^J���U�<��g�Lw S��j���t8iē�Ϫ�Y���K)6KsѾ�E�\��3��S�#X�਱���!ۓQ�r�t�Nwp~�z��M�r@*��&*�u��-��Bӡh��3��.I?�PV���j�aQ���-��,��qD*� ����Q��D�� �W��*pCN�n��o��������E�Q�w�G~Q�ӌE;gP(�W�wc���%����=��r�Y9�svh��޹����6�_���-�U͉���,�%!�����~�:�a2I�^-�������h�Bs�*�z�e��:d����<���p��~�40�C��o�
:^�Y�6��$u���ɝ�Y���D��2�����5���A���\G�N� e���� ����0*�k��A��3a��($i�nW�_�n<t^2���>}�C��)��U6���mS;+�zd1lw�V<є����d��?��+���M��@����hY�O[��N��_��Z��Yl�Q� �	Ie��%�����8�m�L�Fo�6�_�8I�Z�	"'P=�p`��[��&��n�@#��|Q8v�I
�ʣe�g��Q�M�o�����$X -�6�ȼp�5����(��+��'��5c�N��ՍX>f��C~�~��L���)�o�6:�[�B�ܬ�AE�-	SB���_�F0�֔D��V������`�e&�[�|E��g�/NU�+�e����؋~!3����*�{�,��F0�A����$lC#�O�-"���z�ږ��0�3����<�p=�/�̩�T&!шX�,�w}��)��-7Dɚ6�#✧x2��b���#~��pD#ӵ�s|�<��貈����`-r!L5�]�s@X�_��:�noM��Fƙ��@ {�w�H���x'�/����x�C�����yF���<C��[����J4�Y��s�a|]鷔i�ưZ6!-���s�q�p�M�U������*��z�3�26���E/ã�����2�S7u��L=�G{��=~��h����qR)����ȳ�ME��Q�/k�2*rq�P��sS���K�tﺞ��i��E�T�R�̭�K�
w�(�]f��}�S�3Mbü�ɂ���֫@�	��u�R8Q�-ʹ��{����E��^���\����t��] x��B]V� �,�}��K���|˭Pss�77P7]7,�>ѱߒ�y�>QX������i��I:��A\kp�2D�������'#G`�F�o�'io�up>|�i��i'5��=%F�qZ��i@6�~�vpB;�Ŧ�p;���\?�q7�#R�]W�`!c�C��2���+�7m�ޒ���n����ĿK$^�#��a��h�+�|3����3����ư��� �6�ݲ�d���=�H�d>���z��p��s��$���T��|o�Q�9/��]{��Ϭ�Fp��k�D���?���UnDl�%��Ł�Eo�t�k�0w�Df9<���ʇϯUg"�m��QA���,A���k���C�n�Q�aػ�;M���X{��6���r˟e����-��U�D0�8��:)"J��>dݎa��]e`��{ew�r早�T���P��Z��)��^޷�5i96�Ů�M/�?����'bI���Q��~�F���p�B ,������(�b���iWZ��u�9,s�yBi}��l3�DMؘ������?xud�˜��kY�}�;.ҰyVK/��V%�C��5�Ʉ�1�����
Lh���7e��rD#&������5�GHRf��11t)�M{��H��F����W˘a�ɹ֑��5&�n@z[�j�Q���`f_��4���n�������י�r��:2S#�ҟZ���vCS�9����1�N|�K����i@���B��:���Zd���{�{O�]�Ne�!�S>Qyr�����Zf�����^��{��"�JbG:�<~�;7��"��dM;jЁ���K��m����:�,��IKa��s�U�'�C�Z���#ק�}��c괙�Mhъ ����Ow�^޼sG��2U����h�R�n��+񊦔�	ԡ*�@"�� �է��.�\�'���b�5�^�7�R��Pʍ�Z8���M�܀o��`$����h����E9#����\q��4�l5U���<�x o!�(g]U����x��ť2h���r��@�KY(��-�K֔p�5��C��;J�5�S<p=��0�6��C�/����x���Ul� �ÎR�]��>�k����Ǔ�ꢌ��V}�����&�J.{6���[�]5`��p��O�Qj�m���N}M=�����H�?ΫE��{s�xCɝM��z�4�S�<S�~4�dmF	�׾#�(A9�NgmR����"W'��>>��1%CK�S���b�m��X����@����p.k���gE��/��3��U(�[m����x�hG�����c�>��ep�� �C��������0��X�< �ǹ/Dj��W��At��V�׍�4�͍�8�1ώ�h���~��`�>�=�[�3��܏��)]g�Oݝ�.�=ި�'���Z��HElx$#.5Z� `݄@�p��	�ڗ#V�*�
�r�����R�n�ع�_��"(\e/)����%	,w�:u��a(QW����0�A꨼ቘY���S�STx��f.�x���g�۶���>���~���C�L}�������Y�s|��(P��� nq�/�:���`�C���:�(��2�f*|v��8�\R:L�A��Q�U�s	Q�'wqy����e���c��;��.N���[�<e�;y='���т�)H݂`��}��*}�Jl�A=\��ns�bB}􎠗�S���-<C�ۆ!3� Er;�_����wl�=����|�D�n��Ӛ��G&I�����R��'U��Cs.!�! !T��-���N�x8[[|{�"ed�-�e����;a�\&����X��CK�W�4���.���Ȣ�(l���Z�L��=�jΝ*57�P�aeE	 i��:mZ[[X�9�r��zS��d7��L�j���iP3u���%J2�1M�h�����+�i���Z,�qc(抈ўj#�h�y��ChJ�q�������;�#_�K
�ϲ�� �1pW���A��t�Jǈΐ����Y�@�^X��zaé�X����UĄ�蜠��w��9.I�,�.�*�MC��g��ub%��DԼ�A��7��|����;���
4v��ZC��6���2��SO�g"'+���Ǿ#�dl��)���%̤�~�-��T��75U[���\s	ԟ���g_'`�E�R7;U5�h�
P?�����O����sfm��~��U��G�P�!���v��5��uc�������]fD���^I���t@e=���R�M<Æy��v'~�m?N��4�,#TĠG*����]�����)p�`�x.�A���C`5B���,�U4�}f�ߙ�&Ʈa�LN:�9��쪱F��O���ч�n��.2}Rz}��t8DT>�W��k*�-l�4M�Y@�L��HQj��co$��R�vIYv��͂*�&��
ٟI���/�_� �*!�z��j˨6Z���������7���u����L&���?)�kT�wD����v#/��*��Ю_���-]�i��µ�{G��Tm=�KM�����UE�	}ft� }Mqɸf��l�v샦[���:F���&�!S�%%�QS�v��7vg<?-$��y��@l�Gz���3�\�.[��mŐ2���Y`Ȫ|W[�z���gT[]�8��	ܹƛ<d¬�� JQ[���l��go�ɵ{|�M�^���u�x0�>A��P���t�e�yC�S�3���vxg�(4�5�l��!�F�/�AC<��8+ow�n���I�RU�j�Q��(��F��_=D
�j���1f��{ro��A�d��JҪ���69!��?�͌H�N~����ZN�*��'�+�Eū	
��%+�h�I�Uk�h��X�?]�����Y2 �}b��-�N���R0_�5Fu�ra�>�� �[s	�0'�oa��@Q�?|���H�:%�)HI�+���zF(���n��h �L�
�RC��K`a�[@��Xj5#�����>m��f�-/����R?�@�?=-��۬PA+F�Z�χҡ������{��'!��K�h�l��F�8z����e!��d[��)��Bb-���O��� �B�"�=\�Ƨ��B�^���-�����::`��r�J��(�l1#ۆH��b�ʶ��uY�5����������zȟ-�؀���\*�P:�\jO�%I��ՐS�����\0�ߌ��@)��3;�X�Hڷ�3�F<��b�s�b��28��<_]���ϵ�3Qz
Y6��\Ölh�ʆ�K��Xoʈ�;DJ �f�Ν<�I�ъ*1��;��y!Щ���gRX�|p���M��R������P��`9r�jޣ��DO\:~�7�t�<w���q�F�-˜����.���[*Tg��ʩ;�]x/T��l��X�լ�|ӓ���7���]׃�7f�ɸ4oE�Y�c]�t�H��) �S�d2�űY�/�e�J�YQV)�`�m��F������kJB���s�	��s\\�4�;X�vK�$$6jc�o�.{
��i��M]~��T"��J�8j���{�\#3�h�J�5�r�J*xz�k P�i���H�aZ�h����a�����=�e9|�.��BX��)juEf.��{�{��YQ�Ϲ���S.��i9�D�e��)Y=�y$U3$�����	��@��m�l�~�<%d�މ� �*ڀ�2�#N�"l�f;ܒ���F�����pR�b��zf"8��n�c���h+q��ɭ5�0�g7�]r�4Q���^�����m��z2��zz��
I�3d[w� 
�ٽ��A.�aB���]�r�W��}�4���~5�T[N �z��A*�K�P�6�(��r���� e'�R��0�.�ȿ���|I3<��kT`����M�2�c��g3�
�h�q�2 �V����5�߆�(�.`�!����Ѹ:�P�!��9����H��_^�4e
=�V�'$�����q����> �k���Kg�j�o�9Z('�@�6�"4��XU1
��_R}�Z�0� ��t���f��Q���UP��T��:��iv�=����!�Qpp��)���g�lq7v��5Ҹ��viێ�^{O�v�v���G=	C�_���2����P��;�ps@�7���f�P6%��~$���><�f{Q^l�m:��i x��IV>>l%3�TIG4_�����
|�	t*�;x+�(��UZGDr5��"�&��?��S!���U&9d�w�w`��r|����
1L�1��#����P*M������R����/�u��8հA%�x���G�\�? Mp	���q�����#�{��LL�����RIX�}~nV-�BO�u���S�	K�i�)i��.)m椈"�eT���� ���C��9GohsHa�M���I����ø>�|�����yzۑZ�nx������j��w1�J����q�'f�����~M_Bۄi;7nIyJ_��];��������&7F�o�,��� �A��a�A	��|�`�
���~���j���?�.
΍?Nm�r^)��S����ӡ�h�s������t��$5lX��pi5l�C��I{��k��!|�l��\(&tx�`��Dڠ�?�V�Q
�VY ؈��Z���xt����t�������^
�w��!���z��Op�>m�8�(0���:=B�ö����?$��P�&��[�'�HU@��5���;r��,�Hp� d'�������RsF��2ſ�Y�D�GކC�F������u�����<5ӛVQ�ق�7ZLMI֍������5^�VRLlj�#o�7��$MUS�T��K��ޱ}��]J^���,�1���O�2�-Asa�!`ʂ�Xy���vV������.��,��ݶ[����O�̴/`����3Q�]�:�.���h�Kn~N�R����#��隫.�}�k���n�<9�ǡ%�zh�-��KxЊ��&��$|ɉò�2qZ�=�T�[h������x��b��$��I�-�(B������
��/���V�q��7`g3uî��Nsk��<�C�i�����������'���Z��ik�~�^tӦqKBƂZ�%b�sއ��X���a�YoDLY�;���_G�?n�Z��%��qn��`0I]�#�Fx�;�8��rq�6�,�����W���y�d6��/:H�R����!F71mJܨ
^9~i�~�7�c�N��fܐ�?ܩ�TT�M���vĭA���|���os��{b���7Ȇ)��&#�A�G*����`B*{��}�U�5-c�3s
�19.�S�9�`�%*���<L������Z �#~s��\y	}�5��*�s�}��+���/�r�ΐ~'��d)�.
TFjw	d��ln�U�Ϥ+̀	��'v~��T��,if��,a�&��J�Hf��/ ��U.���@�/�p�Ȓ��Y�����f��9��26�ͱ�6�2��R���yiR����f]�`�ݞ���~�8֐ő�r2�Ob�%���Л#�M-����`'䉁̨92���E��a��%��۶�܇��i�Ģ���n�p��=tn�0wu��/b�߂aH�b˞3��&h��;�$���[{��hݐ���y����9���_���4XY���[Zp]���gZ!a�Wo��R��+vg�5���`a��=�@�Z�2�m�N�ڗ���,j��mlS��-�$3u�iaW�D���i8�I�`!���WVP���Mn 	ޥTJ����x����E"d�tl�ٜܫ�/+y�~��G����m�F!����xؔr�Q�[����`�^�-�1c�L��L#'���x$�9OnTi� `�9�^�1�ªM����^�zP$�� U*Tkx(;F�)�ǿ�8�� ���5;V�߱x?H	�b���������A�������� �v��*w"A�a�<��������T���]�n��mg9}�vO�%�o�y��� <v�VF�b���@�9��E�7(��ʋ��\�C%�!w}ԅ'��} �1�%��\F��]n�M/i�4��^��yA9x��^���U#�'��vC�-�T�ť�����R]@��y$���$��z/�'���Ỡ�`�����/
��bc^BI�1s�����ӭ�[�)c���ŕ�aq��T;+p��뤨j>ډ�F9$ͷ��꾄��A�MՍh����p�p�L�I)��_LzzH�j�9���:7�۱��*���ʩ��� sM�W'`�Ul3���!r�x�0�ZS�� M��0xL
��F�Z8z6-G`)���(/Y5���j���pT�h|��9���}l�j�)���%�*N}��t�+큮QJ�|ȟ1����8�=���E�o�<�+s���=K#�iͩ�w��sōk_%��yɔ(@�^�ňO�)��EX��ʡ@R=
����=e�v��1s���p0���~Y�~s���Qu�����tʕ��0If�]�i��c#�a�[�	�X���e�kV�&��t�2�r��`o���q����+�m����/�w$�^=�A�}tl�H:�#��L�\��ZVv�/TV�����H�*��/�d�V���xB�V�����NBpE��Q5΁��l������c�A����j��s��Y�B"���[9����     w�F[�)�& ���������g�    YZ