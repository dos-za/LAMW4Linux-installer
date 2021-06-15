#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2254716907"
MD5="6b8a5534d684c06fef7409b8e227813d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22272"
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
	echo Date of packaging: Mon Jun 14 22:59:37 -03 2021
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
�7zXZ  �ִF !   �X���V�] �}��1Dd]����P�t�D�rHdV�"%)8�ݭ�7xE�����������M��}j�:̋ 4����eZ)��;�;3xLR���ж)sX�4_N�/�^f��߽o4W��MԦ���۳I^�Тt���ε����δ
4��6�p�v�}��م�:<p�֘	���F�^Q�k(=���C��Z�9��{U�s�ۙ��P�N�o��<�5��� [��7c��x��IB�X��\v&)9�p`·K�|������L	.�j��T
�\�f��q�lC!JjW<�H)jY4�H�E�u�g�+]s�0;�)��*�bI&��H�>Fj���ёH���F<s���=���m���$n;	�l����l�(Ф�I��Ԇ��қ_b�x���%�pw�r��u�<a�Ћ8�蓡ўc9�
֔/��lD<��T��+�8�0�Ԗ,����5���bL�f�1J����'��<�0SV��{0�b"e-�W�t��9WCgV(���!��q#ɀ^��x���OD�Wh#�wѧ4Ru�1ϏՍ�)z��?�T��ꩆs9�d��y+��uʎ��a�N T"Z�9T�Q�"-o��۩�d�&F��{J|I�S���]��`cD�b4��jh7z��x�MS�W��k�6���^��!A݈������5��]�7�����:裍�:gޙ�ab���e,�䳋������x���{��g1��{{�g���5�k8W�|��Tb
�T�)�P��2=��cGl�R�MI�a�����A82I�D��r>%*{}�d��K��q����qP&� ���pkx��g��R���OZ0|���}Yܠh��{���ʞ��(��=1l��֨ʒ�NTkU� R�*m��UJav���."�Gye�[�;�c@��	�
V�!o^�j�Jkf�ZŅĜ{Q:�dv@���ԝ5K�,�Ć����"b��.O�boK�v���\.�ᖀ���ٔo{!�>ۨ}m�vwg���ppO@ՎGo�)��o��}�����3!�|�خ�Y~�{ຳkg��t3���#N ?!����a�F�80i���{�L�w;�S��H���t\�%�4�W�D`^H��m'@
2�_��.0A����1O��VG?��I���%H����( U���{)�T�k� A�[��0�gNt$ȄL�Y��"�Nܫ^/i�25�	��//�ˮ�?X������S��*���,��4���<��2!�A8t
ofY�w��Os�T�_\�!�ʵ����v
�X���_DZ�d��q��7��Ue\Ҡ {�B_ưx��96������V�y�M����c��y��t5�*?C�0;Kv� ��ԸRJ��%$AN��=�-�;�7��c�@�T�G�E1�a	j	�>VS�ng}0�qЃwx@4��,f�0�$$���k�Y$���%��|O!)G�@�X�2)��T��D��Z�9�]��)�=�/�y�Ϟ��[UV��Td���Hf����
��C�Yn�$�1����ئ�̦�����P�ج�T�\�!�#22~��e@[��&01?+ǚ�D�T��ࠇ�h���D�}�d );����6Z���9:ds��0u�����>̫>���m6'�x޷��_�&���T��Sc]P�h���Q:f��t���}:5�D��)i�ˆ���9,\? $^�U��($�� ݩ�P�1���C�:p~������.��s��A{!�>�<�؇�ĝ{��m��������h������%�a�Ӊ�!��f�;�`�d)�#C������7`����N�����iy1������[�Ճ��CxI�e,m������8�\�o�\ ?�i6��8��)Yu�;5��+"nB�ƹ�:�r��o��ux(7�� e�og�[�[��C?����OS�i� ��N���1�aЅ@��E�9�S6��ޓ�=l�W��[Ӿ'�`�B"!����G&�V�>�z�<�O��JН����B}\kܳ����+�k�N����{Λ'�L�4:E�w�s@��K:���g�Lў�A,�
�k	QJ~+9>ބv5��H&�i'S�:�tN���>�3��x4A���G(���Wz�+KXћN�b�-?`3י�ͪb��Tx�_A��N�.��?���ǘHH��|��-@(�y��JX#��0T��+S.��o�Λ�[��pB����~���[]0hƄ�*���D�����z������T�=���v�lѥ�^�q�x�Fr�"��-�،�iQ!ꐿ��r�J��6�XYz/��'�09#��!�J�T��bj-�z����MOl��h�Ep�`J�=���w�%$U�_��U�*#��&5�y�E�FOF�$/�\m�0�����8��u��;���營R1^�ͭ��d�4���
���:����i�*�rI�w��˩E4qo��J�NuV�lS��aw��,�|t}���j��?�8���6�Z�֖=���q\G�p��w�#�Br�n�������u�1���_`��Ҫ��a��mPE#�[��y8�4J��aK�V�E���T�xk
���K�"�����}���K���$�A���Q������vtJ�2��dũuy�\�X���6=޿���w]P�����́<`l!�1���/��dxdWUIqs����{UA��+�Zj?��8
�'�ԍ"Um��� �|������8/`ր�Ĉ��3���!����ОpVo��̇�d6�>]˗�X �B;����#��Un���]l�F��Y��X��$�7��� ����}t�i0F��8�֧����Fq�'�Ǹ���>���;.o�jOWL�����Z)�'����_�����ͺ���r��p�_�{ro�o�����@/E{�B��6t�������V��@�W�ض�<@�#}�Yz���=�,�I?G���%���	���݀��D��Uq"]r ��.�>qNk���\�}P�p����^�UP"����.e��;8A5.�5��J�˘~���9��'�˲Ț�R.������y���y;6���ޣ����cM�:/(�qݲ��-���8$�u��R�X��if��O�@K��V��[FY���ۋ`IK�x��[L�y��:i�,��դ�}F�o\�a3��p�p�x!G�P� S�rt@���j"�ґ��r�� ��>tg�#L�ڦVpA�Hؙ4#�W�9U�XEy�yqm8h��4	#�σ-
'Զ�0c�#S2o>�z��Ջ@�U��FXEtS�V/�/x�R�A���P���g����7��ނ�F�7�4�����=�|}̰0�i�qN�ʺ�e��-vٟ�٣QliђO�l�*�G��A�)�9��F��G�=9�c��R��7�l�b�"i�����2\D�z:��D�Չ�	�k�eƨ��B���¡QI `�Ps�H2�~�t�pz�P����3��� XJ�C����_{f�9�%O����s6%G���m	eu�f/|	�{x����Ü)��6~{�Z0���L�M=�
W�W�PL�l7�r�ό������.{IC!i��`~��.�R�-�uFFGe�2�Qn��D�������k��!�I�ʒPEإj*o=�]����7�MwH����V�Ĝ���b�SJ�Jԃ�ߞ�eU�@߷���Vs�>��p���b���K�u��T0�A\zt�/�����e=x��=�(����s��|���2�:o�2��.A��x-�;���l�3p�=%�S�W-/Y�ӇÌ�ɽ3
�R*��g-` 7����� � �<k�yZ~ܼ	��q�~=� u��+q����+6���B$ O��s����d���+��GS����Ky!��n���  �2��G�ߛ��=�(!3E�������]��7.�JN��X��	TW���0ٜ=+���`U�%3e�b���0&��?֟����]�p�}��:�>��6�S��zftw$[��nys�浕�o2���D�R�>�lh�w���,#�dht��
2(�b<��C��U���lV�{������HTܲ��\Uѿ�\WS��R��5�s.T��g��<�Ǻ����k��sq�F�aߪp�?�w��@�N4�(.�.��>Εܱ�u,_�xCc ��A]z��@yJ�z{ÊEn��?�i��v���ba�.��)|JD__	djM��/��}'jg\�<9��rD�����Oj̇/�lw��٫�qZJ����y�"Jț_�³xL���%,
Z�\��s�.��u|FMg��ON��D����yh��(��\��I���o{`O_��-k���4�Z��SQ�-Cp�b6�9����}I~��oJ<�u��F�%�D�Zɭc�0@�5\���K�����l0�ޕ?C�ࣥq�nX��é�,3�ѷGѹ�v���u�i�;g�t=ǔMF]���t���>ΰ������҆��������4�\eT�^˼t�k�]!4�_�J����VR�f�8>�'PFv[��D*b227J8�������Dn������	\0�� �>��U�0?ߛW�C��5^vح9�� )s��я0�M��k�&��W&K�ޞ&՞�م�p_J��'榜�i��T��݁���EV���i�3���!�Lk1���ݶ��w{Ϡ�������%�cngY�T.w��T �v�=�,�����{�~{���\���=�8f�o�����-팤���G2Auڻ�
��T��k���5�ڐ%�X�v�Bn�=d�PВ����O=}i������O��kU���w�46�l)I} =|�����U&uHq������)&.m��L;h�h�V���_� a�����ר
��I݃��F��M��T_�=������f�� �Rg�負�8Z�Ӝ���1�~�# d4�]$��y�<��a z� ���C�v��l8#.w�w�gK.t�[���4s�����U���t�VUaE��"�!2$n��c�o�oϣt�$)
�G	2d8��%z��o�X��^L���4|��Ɇ[92�S�J�d�WG��&�*�j r9���r��DI�E�۰y�J�X�E�;�C�1*UpH]��|���7HQ
S��J��.
� �n�����_=s�9�}f�L�����Y+�g13һ���_ҝ|]ó��U�}9�J�,��&#�`x�Ǯ1��ث�'�U[�++U}_lXW댷���^���^��#��0<�mÊ����g	��#�8"X��Y���<�`W�����m9yhΛ|b�Rz��S���>���J5՗���wO�"�DB����`h�"�P��ν/��'Q��㳖~��یb=�����Z�,�&�.���2):�)8�&;-�+4/��6ѩ���I�=P��5�y7�K{������f#���P����<+c���suȢ����U��;沂� qCI'�V_42Xwe��M$誎�d*}i�{�,Q�ɴ��3�^!
z��[c�#U9\I�$��m���j8*���Zu%4Ĺ'uV�e�'G'��2���Bkڹ7u�BG�vs�X�ܬ�bh#�¸�1�0�㗸��&��a�,����/����Uؔ���O"zRO@�Eǋ�:XEn���r(�F��	}1��x���Wٖ�.�<�Ф��|�$�+��#M��ᜅ����(���e���O�&�������H�g<�B'�m�<<�T���*����~���������g�uL�<8��[@�i���FҌ���'����y�z;^S hJ��ӈ�>����Z|y�!�|�qI�ʻ�r�O������Y�e�v�I��n��M_H�����m]NE͏e!�p8 ܶ7[��`�f��#��?�d����B�>�?������8u���h0mL�'��gSL<S+ĸfD-��W��y�zϐi���T��1��k��4����3�4�b\)��p��On)Nn��*��89U�3S YO5��)��j	�oPN�a�$b]��@"�sY���N����+�dm�oUl���*�xH� �ͣ�#���hЩ��4���@w������L^�ͤ��_�E~?ҽnkk, ���\�.�&���p���B1�.O\R��Q�izi㠦�-�vA��x���YPw���J�O��oq���q��\���n�b�I����p���v@l1N����s��Y�`;J:x'<� ű S��
�4�a����K|��[ ܁۸���<�i��C�IX 3�[��܃5�W���lZ�}�U�L�w��J�|�?��iy��bx����@J��A�V��ŀMq�k82a�j\|%�΄.$A�1��/N,��i��A���!)_=_�ڲ���~�G}?@�᡼
R�y
�~`�8�>XYn
s4[xڪc�S&Ƚ��brH���g��AՋJț��b�b^��	����{{��Վ�y��`i_Os\@�k#iĈ�Ql"��l3�?~�*��|�i���y�i��b��P��J�����zصw��O��e�#���7�x}ٴM��6�eD�� RM����P���ɳX<�G�o��?�5s��X��.���E�9��L��8��m�L����P�N�8�
��y�<aʂ�(2j��P{�j�	���c���7�l��g]������n�2Pd.�Wk�p��Z����_<�]���y6���-��D~؍��io�s8��N��L��:��[��f{y�o駋ⵓ Q�UF�F�`f��f�� �n�te����-��jy=l���F��r��X��|1�G�1x�m��x�V��D��c#һ�	����Aխ��,�ğu���`���SF
j#
I�-U�<(�W����Y�W$'�0V�1W#��#7;�A����I�56mV�PU��㓩��v��$�d�o��Ǥh���jD*�5�RS�V$��s[���K{��(��z�¤W�

[�9�qZ���;�~����]�ҟd�(&<��P]@c�t'��P��I�iI�D=�Di ��X!F�
˿9�;]0-�E��[`��
���ŶQ(s���k�~\ynJR�`�\�.�����]������C�T�
�W{[�s�e���AeK/���*�\X�㲫���&4r�����}���ę���1��ꙹ\�1��y��$���VC�rX�4cI�g)?�WA4D칵�_�_?.0��9���a��F�'k{������������[�@6�1�v{�Y�S�ذX���.d�Y����1�V�������?�p�af(Z��1���Ɔ;^U3�ڪ�~��Ս�U�Մ�ot��Bv%r3�h�z�{�ľR���c�`Y�X�H�����Ɲ��B�0k��"V~׻Vft�m��Dcj�vkh=yj�ݶ��44��N��p�x�[i��I�K�ܾ$C�:��R��V���.�Pq��ؒ���O�mS�f;m#�s����uX
n�K�Æ�P#b.l�l�,$�����/��(nW��E�ȬD;&v�O���D*�$�.�J�\/+�9c@k�/�#������	Y,�E��F�qM�b���qr�,�6���n�k_�2ҋ�3��I�H6Jx�ԶD;�&�FD�s3�-|҈�� R�t��;��.n�ɍ��Ir|$�(���D����j��5\c���ڽ�5O,4�������@h7*���`M ���4�]��sW�� �J�SL��u���F��n�#L��; ��}��>mw��Eu��f�Td�~%#�X�#t�nJ��m+����y��&�ս6ȩ&����::�oZ$�^�)��Zf0@���ܧ�7*7�����tcx��U*7�汉�{��%R���y�3���S�y�o���̣�("�ߚ1�)��{�V\�?^��l�bds��K@EؑSVD ���3[$z�BF�q�F�Q��z��FM�լ�������/r�2�U\8���)Y�K�LI�c��,��.+�պ��[��,��A�#���+���z!�UC��V�2�f���j0>�՛��Y�
�=Q�з�3���1+�0��~�yB�A����y��`9-�H���T�8��O; f"Y��X'�z�󑟭�@(+Ɣ����<�Ix �"5�6wI'��-\���2%S_�N�_r�2U���� �	����6�A�w�:�?N��wzʥQ��kW�[���_vN�|o&@2����I�Sy4�?��&��W�+�m'Wh~0���nI�u��p^(82��Ҋ���O`c�L����I��oq�jV�iݙj"��6�A[��0f����u1���T�@�������GW҂?k_��\�v�
��,�� :�,�F\i��0�<tBE��\��Ԑp[��Z�i"Ԑ�	{:E�Ţ��C�u������	Z�'���ĭ����!��[��<��x6Z
NF'6�`��*u|�*G��xS�<׻�ؠ����A96��V5.m������3��2n�cq�$��ؐ�G��Oܛq�1�D03�G��'��^A�����k�oJ*K���0�YG��R����!S���g=��"�3b-�@�s��o�H�o��F��9�"�#���9��l������> �̇�^���{n�8��~����1~;����S ���d��d�C�G x-����h���}�Թ��!%� N�	�mp��������(�-w��pKԝ�����ޛ5pq�u�s��s�̬nܘ�����R���T�(m����j�� c>$�i>�g�i*b��O���DQ	��AؚY�������[�P�~�T�V��0t�.G������ЧXKL����������g&۴*��\!#���\�z΍�j�lZc��k�ۜ���ٴ�!�4���Ֆ�A�_��k�Q���u�owOVQ>p�T�~�7'(��'v.{P��2|��͡�C4�$)��Q>tSA$����S6�D���U��1��jU̯kB�A�gu����DE�W� P��x�t��@�?����7�:¶!-H�C��]��,^
��n3��@Ԑ��Nz�{� �f(���vњ�ɡ�U�����x�y�_
&�],�|�c����&Hv����k��Z�cY���M�o����06�n��_(�Iy\|�ѥ�n���;ڧqV��'�LwO����VF���\d)��.X/��ս��(D�Y�v��4���+�Ŵc�V�*���`�S�������6�K!��:�b�;�7�6�JtC ڛ�-ߖ$T�����G񜹁J@�͠�(���]g�,�s"��:+��&R�(f��3���=T4��E��ʪ��C5��	B}H#̲g�ԋs�������ڦ�\Dy�a�ʮz��wq1�	G�/3�{�����QA��Q��!Q�P�;=�SIJ��H]����.�dTE2��q��5+�>�X(�Z`<~>A�!㣄�� 0�P8���}ٺ�ɂt|m�i�ŴŃ�/�}�Z�<�!�j�����Ġ�@�����x��,�� ��L3םwſe�[�GO�����b٠l�$��
��t-Z ��O��ܱ7xF�7܇�9������o&�C3OISd\����+�;�ug���.Ś��}E�%䖮ʓw����硏30��-MP��n���2B0�d��%��y����Fv���R�J5��a�}	 Ms!{	q��%҈���6�U��hS#{�<����n��!|V�S�Xvn�20���.S��,��$u�B��%����`�'��aD��A����d6��]���B
��GƕCLa�<37�`�c�y7G����b���]r�3���\�~��ũ����"]�e�n��Y����Ð{����E�q#���7d�6�E�O=G��Z�5����zhD���vL��c�"̏@��g���G�"��SDy{Lw���e�������e��t�3��-Q�"�r~�"��L���{�闧�������,ōK�-�k�e��Ր--���d�r+Z��8�߁����&��TL�g�b�Vk�3^X~i0�Q�9���B�c�`�2f��Nt���R��;<�]�W9������}� ՗WV-�7�5��͒��JIJM		� �&Gˬ}NW�2`�_+S�|�?��Ã?T���:�+�3��_]��DNUr��̀���p�#���wˠQ:6�sZ��t�̪ʱ�qU�Fm<.k����h��{�y���b/Nа�T���S	�4��5�Aj~W�L��?6S�19M]�I�H]�)�4���%��\U#>��=��J7 ���%�7�aU��i;G�y�aU3�\𕛋��-�:�NV�FM�[UZ���F��G
�T^��lW	��@��9��~oԧ���"0M;z��z��}�$���`˽�����>�n-�pꏴJM��ۡN�ضo���I�:w��?�A
y��Y�L �J��aϏ�������韛H�|W6�>�%cM�3h�ț�)��� �7o@���;$��H�Ri����R���]�F�0c���j�ɠV\ARw9z�����*�.�#,��ʚr߅�4�B���E�U�ҁ�4��j�bצ]4�0�8��ŏ5 �O �F.{�|�]�&���/����p@���笔X3IǨq�1�N��X�Zcö��Y�́�����΃-@=z���c¶R�w0N����h�?r�$p"�v%�8�Q�����
Kd���CHv����=�X ��6\`3���5��:M�_�i�-A�\�U'u�4�C�8��8V�d\<9g���98�%��Z������{X��W�t��Ϝ���u�5KY^l���Ui}���d��1�-:3�s�Wj`������q�&�)�O6���d��@�Ӽ2�N����^�(���[
�1e=�����CVo�-��0ڤ�bF����T��ħ�@O���no��ƈ��>.i������E��5F,�A;x�NFH��~������0�8�46�����k1}���-����ՠ��ӗ�]#0R���_?��(�DFs��j��t>�BZ�n�
ܕ��[��(J���A����R ��-o�L��E�~�nn���HD<�=�Rc؈�J�Ev=��ߜ�����ZV�xl"s+�v[w���sg~It�n`2^�vFU���U;j�	��KY@j���ː�'�x´�N~��Ԃ�~{��D�gY{..t�8V=
�&f2M�\��4f��z�b�X|�=L*�a��y3He2lP ��K�O��4
R�־��`ss�*��~���>�"5�U}b�2B&aJY9x34���F4�m�j� s�u�O&��&g>gN�3�=�= �;jϣ,t�}�TYt���Y�Q���6��Q������ݳX��>�KCh�=���>d���̺�㜻_����C�����8�9	�(���Yp'� F8l/`Ȣ2^Ve��)YFj��US�w7	��uz�,t�Gﾦ��	�0Z;���@5��㍛x}��L�a����a��A���5�����2�هw���p)�5�w�!�41e�m�JWZ����1�T�J��7���Qo���s��otQ���^��Xt���4?_��$��V�}����ț˛�`��Rm�\/(cz��j�g������|���t?c��gl��Xn�6�\j�#�4v��P��/�2I��y�naZґc��1���*~y*h}s����9뫀E�>E|�-0x��c���=�1� ����b��5K���~Ҥh�C��Y` ȳ8����8��>b4Q�}p��~��+��5�(�ԯ�,��F��h:���â?!��q�	[,����*ه�W�ȝJLDK��	x��NŹ/��Y�t�=���'��%�+����l]:���f���y*��{� [�
N���U�V���Z}t����LQž�{E���,�D��	��{d������ͺ�Vອ^���q 	����;|v��-hOV~�]�Pȅ��K�S�lz���r��>Jg/�<�|8����3O�ʠ�3�m$���|�����P=ɪݟ�v�S�TD�fTX�떙\�Is�-�g���l2Zd���`�7.��q!=z�ң����2�QA�̋��}���>}�Ƈf&��p����]��~�(�R:t�TI��yY9�q�_�'�����+����H2�I��a�l�5�ɢݚ�M� �T���[�Ҁs���3�9
^@�W��3���U�3��ֆS6�y`�~�Ja8Ψ������'5\��o�I�d�:�0&�o\����Y�n��Q�A&X�U�䩚q"��PSs0�Ɋ]�;ZC�՚Ô	����I{�τa����I����\�d]${�%iFk=�E��c�9���0�q����N%��&�S�%��Qa�G
���Ɏr��x���f9�q0_���J�^^�&�9��b�Xa�){�'��H�'�sB��#���k�Z�z�pn�*ws:�H���O-b�=�i�����qF�RSӔ����6RHi�3g�aڽx,a;�@G�P7nae�F�J�[��G�R��	ڈf,��3���p�a����t�4|`�TlH]]�֞��	����M���:+@�|Bѷ^���HX�v��xt��D`�F���ە�e��	hЉ�|�Y�p�R�H��nw�c���`�<��jފ+(���4#��^���^��{�g~-NRSEr�^���Z���]�<n�I��� ʭ�M��V�6Զ�h�XVur�X���I���n3�>�N�ȯ�����7�O�	`C�%K�{����7L���VM
5�R�����Ub�u[z�1LR��~&,ѱ���mf/I"�+F�w�*DJmL?@�
N�̓���`[q.��>{�c��R����'t�t�[��;��9��K}{ ֭H�
����l�*��ˆ}~��h�J,�e�Z
�ҳ�Ae:��Z�f������I`����9�:F"�}`�	C�z&���z8�%HF<J��5.�ꕧ`�C<��
������w ,��va�����^o#�Vw�o}\ʫ���"ƮN���P��e�a�?�	�sE )�Z�(>��Ot�'+��K���������� hݽ��.�\?	��5�~�./t�l�����2i4�CJ�����cH�f�ŬƱ����گp+A�0��j;��y
ܯx���񗭂�	�M�y�L�;�ް�X�^-<�ۗ��W�Ӥ�t�����5�fN��x A\4���HWIg��Ю�4	�	Eϧ�e��T۽�/m�}ep5�[�K^x���ܿh��u|��ݏ��qn�� "�ٓ-�]����p�,ǋm�������=
̜륃�%� ���9�����bh����l��1���1 �=�X'ThL����!PX��q\Z�R�w�����7�}����{����|����4�6��{Ŵ�rٽR;h2Ӑ\9k%�\��4��l!R;N�zٲv���_�x2���~F$����1Oq������{�)k
hIr*n��Z��k����
�בѠĦ�a0T<�+-Q��>���}SN`:���m1Q���$�����H��x0w��Cg(kH��䶳u��ye��e������h3�Π2B�ښ�c9��l�ȍ�D�.W�-�5^)X�?>�Si1���V2��0��J�8j��@U��d��^�p^_�$�#EHt�c���v���U��Mu����w���;�������8��D�\�u]Z�Z��x�6�Y��V.�=b�[Sx�5m���#y���u^O�<x`��,��+m	(�(�K_D�%Oz����ٌ�j⌱�"e)��A!a��.bW����r|~�U��X�Z����<����*GOJ�`.�XlP�������tGI���%��_.��;:�ީh��t��PFgWy��
A��c��I��2�u+ɡW]�|��ǘ^�>@E�QtZ���yOz�3�"Z����ך��.������2W{��m�֒NӜ.��l�x�����b�/'�	��N�U�����>��e���zO�8��#�����T�jQS�ZM��?�8���>�(�7���ٙ˕��=�,�4~%��g���/�$[�ɰ�֯顡�ص"�
C>)���Fv�+�N`.�iԩ�-#��4e�t��w�u3"�s�o!��5�S�.�C���1gR!�~*%��Ry�č��j0fUpazG�d&&�99�:M�B������Nʕ}uO�(#|�ZW���"�I͒�h��=�e�A��%2<m!�P������zw���K{UyH�<|U��� t��r���]���5�+���v�O{T����u��+B��5�LJ����X�0�OQϧs��- u�"Dҗ_��AV�i���b��G��.�֎J�:��1��u��1�kZ�����d:��-�_�I8�\�ٍI�nM�d@��� k�q$�h#'5�M\�XúfM���4�E6����⏘f�4����}���ih}k�T5�W��[��I��N�xkCT´k���_����K�S�$��Us\:������Q<Ƴ�{#�M�z��e��o��+��jVØ=GAPC�:����;�,8�:P<|J,=�s���Ys���>�%�TQ��) �'9�~�S���;�j;��Z������f���8
����D���UC<^ED������V�&:�qR��"��LT�:���W�g�u�9�e�Hz�ˠA4q�]wL���r:�N�Q��(��,�����~�
���Z��b�b���R!�j�,'�%÷S��5�K�����_�R��f�dR�P�,_a�_q�ήH���n*{C~� W�������yN �e.��G42nSP�=��R�v^��W��!�ҮO�o؊P�d�Q��<���;�hp�r�k����EU��`3ZU@=�9�T����]��V�g��U3�)8�\Ra�U�Hqh^��|A엿�+�p��:��mo��R�������W��cw|tTGY����Z���6�q���&�'0��� �h��au����9
�#����N��R)�~��3.�����a4��R^ ��
�7�;���������5T�"��"�c�[	�;2�S�k��3����<{�c�05��G�rr���g�z��q�{!�p��:J���i�pu���ƌ�p�*�a���6'����zW��m�YnٌKq�~�/%R�(ꢿ��������ªH�$�}Ԙ��� g%C�'|p]�H7�Ent�U��R���'}�L>�K�wdj�\<4�p<w���� :��Y*!���XN�0�U�3�y�q����)K��-�Yk/����T�L�ė���_}��	+'��'j�*bLs4d���Up_��"Y2�>��!�Pd[�H��6�0�_��Q���*��ӟ��4���F�){�smS�&��e4��8�64i��OŨ���2�:z�iɖܾ3���L�5 ,j�fu	�-��Q~E�D�am�J��(;�OD��#V���-V�I�,��xn,�j&ڵ�Ts� �~�@��-����$�����RT�>�T���m�7<��H�Ӧ�h.̡�/tX��m�)��V1\�R�b�J#�0R�İS)�+w�}�bF2w=Ms��Go����O+�� �gRz̙,���}��|&{��vz�w�������C���z-㑟/��*��2x>)r��U�Ʈ72�k�
��D�w�̧Q�w��u�Z)�}�N}�^��eNꏂ-;����`	�p��Ϧ���iYa��C�i�4��K��q�
}�f*�=#�M-5�{�z�0-w:����)��A�;R�������j�̛�ٶ���軐�mu�CU -
����"�ɸǡ��L��#��umzu��C�9]P��U<��@u3�\�R�4���@�IlsY�{:��-��6�m���M���3r��"R"�JD�:S�4��)��]t��g����H����>���X�2�0>`E��%R��EU��>a��e�̣ɱ}�+��+���x���^�l
�g�C�e��a�_e�"�P콷���k����d�p������q�����We>œE���b���|U+�a)Tn�>Š�yn��8��x�%��;�X�w$��O�� ��Z<_Z�w}i���)��1��K4"ðf��L0�֗�D2�uQb��UN>"���7%����3C[�'�X���#��ޔtX��6͖j$b�ݼ:T�{�WX�1�b
3�e�"$��/�o�2T�߁�����0��rd@� �fۋ~�y�'6�����U�P�T^�Q�� �R Ϸ35�u�s���<3������aK��qV�Ʌo:"	�u8 �b�()��X����r�/��[�$����݂�g`�̽��Q��J��a��s�f<L�rU��W={�=��u��1
:��-�Sm ��
vtj'g�K�Ê7�,%�S�c�.$��#RiQvf�Z�Q�����j�L��6���ݧ�x�vrI�ro��%鄽�����C���E�?��I�-���,����C��g�`tDY_x��8�<�);qU[_*B��87��n�E��D�r��|��[T����h��&������:Lo}`!`��NJ_/WC�K����a��|��{u�����^�쁠$�t�M��OX��ucɅ��D���P猣�ӀT�*�v��fvZ��궗 /H��H�%����#�Ta�A���9o��/�(����U��qm�p�-8w�U�=�s�O�(TJᢨ|P��k5��B��%��^�9׌�a�����r�Fa:<*��V����,���ʙ(�8M�Ci$��~(�툻R�	5�L�B�l�
<}#D;�W�ÉC���b�vu��/����]
bSf%�,�[�M�vR�S�S:
&'EM�?m��ҏ�IeV���t���I����EW�y��ň��X]��-,�4�*��{�3X���f��%Dw�<�S��v������s��dz=u]�* ���-���x�}ՎI�C�&%f��$�f�ݸ"�Y<�e�$��(��&S����]0��c��p�eu�t�<��tw���\p�7���|(��ogvt���4K���E������!���_U�������s�vJ�~W9+�>�4�L�6U�J0��,0^Aٖel�4QH�)q��(Z��q��gAR.��9������0|u������6���`�8�n��]r��#hq%ב=���_�e���Kǟ���>:���3ǩ����+��ŀ��`Cʁ���X�ʂl1�N���^��P���_��v,Dyo��H��zv��[�?}�É�&0y��w���& �V^X �~2t%��x�z��w�kc9�f����CB��ɯ|��I�s�sn��˱�?ڻ�̏wy��.,P9���b��_�QHr������>��:3q׃�s4/�	�}�"s���Z �R���f�o�2�Y/�bp�M�D��o�%7E��//%^ٷ�97��A ��P�#�T/�����ykF ���2�s��(}a0:oY�غ��8�}<9[���ȅ���/�J�b7��Z���#O>LR�oM�B棪�zM?�s�R8_g�L��@L��O�4�����j��^���35ҿ^�W���y+��O�1���v^�K^:h.��(��Rj1��0�Z�(�|ҝ=�M,���3��p^�/���U
{I��;^�t�Ip��kf��
��
T;������D�֡�%�̏q?�g���k����eWk'C̢�M��;C����}�x��sqᏓ�M�Y�Y!KϬ����fEn�s��j����'4�ӣZ��7A�|��w�@��;��f�RC䠒�P�LD\��-J#hy��݉*���J�O�2ߌ~"a��9��T���c�N��%��&g���~��X5�z)�8����U�Ͻ�y���x`�KQD �s���;4G�/W,i�p)����[%�^KC���L��G�_��̼�Q���p��"��޽���'e��Wc�̈́�G��GLcs�x�ʁ�"*�h�Ǽ/�#� �a:<�gH`�i��9!g��,}�����l_���]氜X�F���4����L��1�)Q�����o ���XHe� �jX�u>t��Nxf2�2w��u�����=7#`�m�z���X�X�����;(�t�؄T� �	at� ���&�f�H�Nr���7��0�t�x��/{$�b"�o�C��R
p��⻤�l�CK�sD����GL=sQ��|U�bYT���Z�|#���G7=O����C��ER3��H/�Xx�W�K*#����:OÕ���?Q�	���˪�iVd~�����l��V���]p�CC��3[AEЌ$�(��M#'v�b5�~\��BDlJ�M���m
G`��S��qZ��G�hNNv�5&	5��Y���C_�ul@�֋ ͆^��R�[���$N8��8�H(n=�n��cZ�0����[�p�������]����D+`o(��2Pt�6�6p��kˆ&��w*Y��sP݌=��Z�E���õ,��9�����V`ς�9�N�.�w�r�[�]��;�6�]���Z�S�E�?0.`����|��O�v�,��i���BwM8��,?�:��x+y�^k�����;$�C��GI5'��֞0���ڎ���_�_N*��t��)�3�������]ӵ��Q�{�
>��/u2�[Fc�z�J�%�*�)�b���Q)���,Np���]����9멷ESkn)���� �L\����Q(&f�vЌ�=9CZ7`�~%%��Bz4�������e�j[��B߼36 �8\�bsn}����!J��0by�}+2�_�<u,��]���-��q�%<n���#'�:�q��/�Gl Αd�%v�W�0����ɣ&G�{����@o���xA_=�RǷ�8���px�@�i�{ҽ�k���tq��ݘa��;.%���Q]�L.#�)Quxe�kod��J:B���(jEp��|$�Y��gw�t�=oi6���V6�/�7"Ȥ�e(��C]��{}��5�h��WH�8����~����"�.�dQ�u��B�u7b�Xa'�d��C�(�m&�x%"�Yi@H;�2��pղGh�tM��}:�D�<�'�{�h��.��L�3�p$�@�$;�i�?�L�ȸ{z���ݓ.��-�ׯ�H����Ѭ�̂��y��@�3S?a�n�)l�ѽ�2��X��+���變�OH�R�"�����Q����Y�ek�Q��qW.�ѩ�.���"����I��~$�_�W�M�o�\Ĭe�W���P��S�=�C��P�ٖw_S�~�����iH�f ���oc ��T�j�62�e��q+�ȗ]L_�a�YԞz�.�F�t "hB-�]����� �+7�ZB�U�����6���|H~ZC"�)ONh�].	N���0�����T��K�����[HM�=Di𵵿gK��*S�\���R�R/t�^��݂��
�sa��y�2���\�=lǇ;����EO'��:��d{g�Ɯ������r����ԓ����͎��^�P�I����й�f.T�-�7����.��Pdy���9Oå�|�|qkO����C(�U�c�����mX2τ�oPO��gbέ�а�E.��a��QD6oa]a�YO�S���a.k:f���	~�_�j?1���/�uv���"��}v�-�L[���E����1 �{2�������`��Γ�!���_��2=B�+�J]0��}������+�'|�.q� �^���N�X�>qմJ;(5�2ƴ��nQ�!�a!��O)XiQ[L��N'��>�-��oчg�o��-AGG	+\h���у���=�=ud!��]v�v�x*�9�Xd�v��wF|$�f�H��9�9�g6����e�f�d� ���9���r'���%��ǸE>38��s��q7:�ݍ9 !D� E		�v�&�E�)�w$#��|�PD
��YU��5�s�\'��h�aȚ�..Z�rY7��k8�o�Z񜲗/�j�s*�_�D����lqk��J-�����t�\�^�~n��޵����cwT�j��s�OӒ�n#��(.�{��e2��^QYTW����/x!�Mk�
߈��NM�]c����s@�245Ũ$9c�.fE���H~���.� V��W��T�3�6�8���i����;�+`�Fs��?�Q
f����L�?b��O��1�t��*^���S��G=01J*�D��4b�a�nEg�v7�0�5# ��������!���D�g�$��2��(�U�������M+�
Ylu�њ�	�_l7���Ӣ�8IVZ%,��.�ta��]���U����:k������G:34�!E@Ȑ=|Ҷ�In(�l/+�r���3��R~��z���?U���n��M��V���g��{�{�	��&���´���Eݼ���K��t�m{��b↸5��D|��+|ϻ/�$�\�~D E*`y5��� o$�^�E�q��Y��h)}��L�04�y�Eԗ+�@�[��}���5j�䙏SIҧ�>���@���>��Y��Ӥ�^|;YjP��o��F��Nxw:Q�S��(�� @J�P�iu�s��xekld�uM�5���s�\M�Е�:�dq0�W�'p֩��)�f��.����it�C�_��/��yWq�u�`���>���C)+�Є4�Ґ7W-	7*�G��n(Q�����a��T�SsU����ƀ���۹��~�b�2%\}j���}K�}-��5�ee�VxY��4�$��n�R��J�J����]���Y0���s�a'���`:�Ja�Pr0��|q0�L׻ebeZC<T�O��[����F�0,ԉ�5���;d�X�a� E����P�p�g�d�X�[̮{f�'�5?թ�'�4D����#��=0�U#�i �xUm����*�T�$��>�CvB6����f����nb�l|�!ųXԶ!�ÿ٭�0A�)ö��uޕ�&N�M��ΧԏOl��Xu�6��������wGR_*�&���i��6�B���q�q���`���Ikj�^�	󽟁qM��/�±��|eW�?<E��8�S��XMH�u���<�E5c"�δ_eu��+�ޗ�������y��A<uؠ�u�u�4%M���wל֎Y�ro�;�(uD9�I��y�(I�d�(����>W(�pw,��A�S�b#�*�v
���̔���������4J(q�G����`�3n�{e�.��
P�c�nd=�9��,���g�T֕�G�,��R�P�M�7��muJ���K9��>���������r���"����r���I��گ�M{��p�L);;o����Q���L:�ʌ.�M�����`�
t��Ͼ8���	���1"g���G�$��lC�Y�n@Lw��W��C��ܝN���D�_��[�|��1�β�ǧ���q;�k���l�ȫ��jF��yX��s��QB���B�'�Y�M)�05T��e۱�����Rz�vUѝ��J�a�@�6�dZ���1�>��ìyaj#i��GùQ��'�b�e���/Ғ�h�����<^�����d�P����+��f�M��b��(!�}��xk��tV��H����³Z�12~StF��3n��|���]�l�dk#��Ġ؊��w$[
w_Zo:V^u:�6`���B2�¤_�_�e����q��D��a�e���X?Q~r����[љ�؇k[�c5~�+i��JPY����pA��[�(U�}��N3B���2!B����g�Ը�9@������Y7Ԭ|�Q8�"z��7@/�YWگ�+���f���B{#1�:�����	�     e�Rm��, ٭��p��ڱ�g�    YZ