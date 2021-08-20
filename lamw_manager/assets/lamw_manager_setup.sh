#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3444310902"
MD5="150678665d936679ff06fe0dc368a923"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23600"
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
	echo Date of packaging: Fri Aug 20 00:57:09 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�aq���Ň�N���e�p(��8�KM�rY����~gE�9�7h'���y��!��#G�!Ր<:Z�<�Ϩ %�j$)��$���Х�ᔻՌIZ��+��%S�6G�![��R|ıZL~��nDJJI�������pF�t�_m�و6捯�C2l���t���3��g���o�\�)�<�
T��C)t/�����m?����]�>U�Yλ���ꩱ ����v�b�'�s�G�`���2=����|o���z~��sM��M����\��S{2V�:j��	�^>R�N4i:�}�{�Nc�7"F�iN?�PeoZ�!�"l�DQ��5� i#��3���D�������?S5y#�Nm.���a�����1l�ao{���M�"���� ����/�j�$v-���mݰ1�s�.+Cp��aSNq����K3m*�����H,l��A�q��Umg�ln{�]V.�p˚�ѫ�B���^�f���ߗrF�7u�9��t{���!�?����'i�M:j��d��ߥ��F���#6�o n�M]o�&�+��k��@���f��/,��-��[9��ˢ��邔�}R7h���7�Z��5t��f�_Y!�H��wٌ�D���Ӈ����?��B�G�@yⅴ��&R"�\w�K�JN�v����Sn�M^���h����ī�k��q�Ez4�+��1�E�h��UO�I�C�2�I�r@��{��ЏN0�Zl��A���8������������Z���A#�1:��
������y� �Vc�)#�1�#$ ���=�致΀M���I8&��лT7�R�c/eHJ"���$n�B�j�vV�b����;��vx�U�beF���0��	��0�O��Y�j۟�'�31-;w��=\��dd�@�����=�����m�d�|�%��)�OɎ�uw#�|�s��Sɘ�������ş����]j#���P7�/����'l}�0�R��B�O�\�f�m����00p��A�+��9��1Bfs�7��W.���#���C�}L��X+X%WO��X�cE	|@;Pf8rb��P���*`ٖd�����S|�Q_]Wo�.�V�$�����ڇ�"�D���
���>�)查��ԁ�v��Jd(��lz��zC��R�>X�_�6�R�ΛH��р�s��g0S��~��g��o ��l��KO�Av�wF�ڍ��^=��f���a���N�0��>.���Dh/��mSqf=5в�\���߈�ѽD�:�S��5k��n���4�g?�0�,η���a�Qܵ�T�S|�+"f�\��o�Zyj�>0����a	�
����ԟa�0xSz�C���i���n��&|��F_��׉2�'��PƯ�4�g�I@A��lHA�&���P�Ăד('gi>�;��G:�ˏ���z����s��W�,;������Edü��K�`�bU��t�b�u�����:�:��z������5�iz/7b�Y�)
j�~��qm׀M��>VJ�L���s�����2P�`�Z:1BD�����28���qG�2��ZJ�d�H�\t4�BN���a��EvƝ���7����N��A[��Hkj���,9X�&M��Ç�����v1W���j��a�x����hr[�3řA�+�pHA����ey�I,u������Ϥ76�-�S�� �g��M���@�iҶ?�\�x5*����]��@n	:��	�U���7��5�BE�mM1a���Й�er���K� \2�����Җ r��P�qx��'����hk�P���G6g8P5\ߩ���<6f�\�{�Ug��K8X����?(�b�JQ��S�E#C��0[X��4w�|7כg헥X��;1N���m�Rmxl����S���&�#���M��u��7�ё�4��!8��DA�� �{F[�{�W�W�$Q�p�ЫR����{ͻh�_�m�u�t�鰘E7#gݼ�Q�m�嘆�|�h)���9t��$�N��`ɡx��Ȫ��iV�b0���-_6�b^��Â��>�w�9��d�f��Sj]{F��t�YV���f|�+/:]�Fs�4�ܫ����ĪP���Sy��#c��*�8�
ǉ@��=� s��4昽D�� ��w<ͯ^��	� qEw1��7>q��F��p�Y,�����Fysl��*�ɕ�V�۠��=|�hf���ʇJ:Bs�ӑ�|-�V_�?ʽ/A�Ʋ�)˴c%ɠv�r�!�	]�B�����#��i%�`���%z�U������51T�) o�'v��, ` \`8+�*oT��]��!�fK&�ZJ��@��X�_W'�8-O_�b��t`�`vt(v�yO���)F�o�ce���W~�v���)ԺI�v0��$M5�w��)v~kjdU��$�>��a�^��2�.c�t#�X�C���.��N�|%�{>��zfw�ͤ�P���!6Oi�
z)^������[���J0����i�{X�eE��d�/��C���J�@� �@�&O<V��`)��o~a����V�3Ҫko���2�`��0�lWq76N��@y�$Q�C(�����ISν� �5��Y�������OJ��R�h��:HVn ���p�9 #�sx�߶�yw���q�G�YH�(��g؝���f,s��GL`��r7ӵ��C�9W	6|
A/�zHüFk:�s��+�-\�E
ɖ�0������>Ad'���mu[�(��TMQ4.��),�=���#�d�?�Т'��j�v:��=�?�B7[��t~�[\B��T������(�?�5��&v~~)Vt�2��i��Fjƕ3z%&J	'��a�m2��MP0�]o��u��B��춦�dB;]�d�?�r�.'f��f����BhI����1�@�"���j"�N6�GO�H�>��P��}ɇ�y5�Ҳ_����|hϑ.�>�5��Cw�k�w����ջO"�Br;�ZL����TWHC��\~,6���P��*8��9k��D���n���l�Ϗx�åPp��ω]�/`�R�G��I�N+_���H��-�*y�:��7j�q]�I=�ti&l�������AN��L�1o�)E�TiՔ��`'�.�}`��l���Y�SI"��i����g����vM{�8�&�%bu�-�B�~��!��
���S�LQğ�[R���dYU
�ܠ9-F64�=������L�"` �5a(fɓ���W[���Q����	���,O$��g}���.�|�^;S��i��$�y�]��K���O�Gr4ṫ��7���<�Q:��`c#��}�:��>D�Z��O^��R��6{:��p�bnKU��wDQk��O��ȝIH6�^G��(��0&{���u����v#7�`(��tp��=�65�9�[���/�b�t�"ˈ;�����A6U�Ռ��{Yu�G��K"�#5{���fۊ6��Բr��������+�=�_{���u��Y�%��d�0����_���54��7}�K�E_������-���9���������*�25U��_eK�X��Dx5}%�
����n���!�E(�n ݢD���Pj�J��%�@\�M5|u��2-0w6%��,���Z'��m������y�^>ྨ���B6���Ӑ�N���cM,X��"�<T�E��?
�'&e��gSv-B��g�v���ކ�*鞺e��4�����gHK+B0���X�U�E����$�������Fide�A��_2$p�j��{�	���ǂ�jȌތ8(��
}:ȅ����L+�*�w�����7kd^��vl�'_?"��O��{��9�_�EȀ"��av����ƿ*E{^���;��C�x�"��Dm[nGQ�0<n��3����_%�]#o�< �����o�!Z$��|l�s�8�T0=����S��w�J!��\8����.{��0�5ZZ(��L�د�i��#�be��Q�}qAk\!��	cu��`!41v�h,}�?��(2b�@���5��NI���p��H����E@��ɩ�0H�wD�)�Y����b8D������P�?�\p�~��V_��hz��:|0V ��h<���g�~�=�vW�?_�{>�:�����T���9؎����?0m l���T䅫}���߿S��n�6d,���V,�!}���"����]����@�m�	��s����1�3��f�����H�Ȱr�o�o�{{�S�m�8�ԉ��L�(�U� DM��x�s��!��el���Ҭ办�Ü�q��}�c�}�/~`i�~��U�:T=�]�0/�_ ����H`��Kg�eζ��=�\������Jp#�Q��Ԡȟ�x 
�}"B����e�gᘭ���g)A�S-LȠ�f-)�8q�򓵹��%M*�k�'����eF|5���1(U���l`�	�I~n�rId�U.�{��Fe����.�E�l2Xi��L.4Kڷr���3�	L�["��T:��m��}CHzJsڛ�'������(A�ϩyG�Yr��O+!��1e�WB�!�_$<Yr+��%�2��pm0Js;�;����U�Z�?�6s��m�.���V��G]�{�o�[3_i��+M���o�#�?�T��B�8ljg4dM�0�h����L��F���	���]F!��j\0Nt�ou�r�,���kǊ}���١��Th}�f�f7Py��m�GB�A�#��C�*�oTD�U���Yf�H�e�Ն�C�o�I�K�~,g8iN�p�x�4d5@������F7Q�..�����p4BҾ�ś�2�V��A$R�uW�!_@�;B6�U���:����њ�����$)�.��),S��n ���隨E.� 8�te8��w����l$>2k��ư4�TZ+�@=R�<`�K��v�����̱�ԕ��Lv�t;��@��y|�Ð`a[v�m��l��O���Íw�g����H�ѽ��~��Z�i9�:�D��O!��^�	��śF��H�!\6�;#2��(O�B]5�RN��"@���X8�|s���MC���8�����L)��P���h/��6j��sՖ36p4�I����L�mވ����C��J���6i��R}�t��Q�t ��>�8�;܏ƨ�?b�o�4MMx.CMI@��jүN3���ŧ�t����~�o�2G,�l8�W�Q̻F�������%�br�9�/�ҏn�jT�]�����J�6�u9��,�ٜ�5I�=��Ҫ�憼r�Mz�ܤ�[z�(90�c-���*�z׭�O���$zGCH4~�I���'G�Ao�|�c�6�'�l/A��a��W��:zY�1��Ξ=�?�Lc��Ɇ�$"���!�F��p҆�:r��#��d_4�1�α�{O�I���7����:kM��84��b�Ӻ�,�.o��'N ����/#��tM4Q\�b�mp)-K�VY�v#�:x���i�C�Cu�Us`�5���1D�{;24��([���k����-Mj�	G�l¯�����&�5h>�nR��_9�O�1���$���S_|ἒX�a~��yZ����V1��q���*��g���R�S�0#-\鰗����=vk()�jT��ݷ�4T���Gp\����L��y�N)7�bm�a�t$�!���V+�YH�3xC12��v=����}{�h����O/�L���-n$ WG)�F �S��8������N�hT��TL�Ѹ}#R�ﻟ�t�ܻ<Н�t��-���R�
&h$�s1 T����٨�b��[n��������F=��y����ܘ<gZ�B���EuL�	���w��]�@y�6o	� =�����/�D9�t(I&$�U���=�>�|���-�k]��@��%��L[}�kWT�1�E��f�"����,:e�H��߻ �z���yZa*N������?m�DR[��0'��Q o:�,(�b��ڿ�7	�vD�\^�����`���(�F��x:c��eU���"�|@�%q����(��cfES�I[`�!�c�M\��W��
�D�����3rJ�����hY=d-T�"K���%�!�XZ�-�M`:�\P�U9�p�nH�|��DS�M�Lݭ���^y���� ����+��C#���� ��R��U�F8��&���[>f`�0�/��7Ka6�
����������:Ӱ��X�3{����;�2����.�0��AZ~��Hu"��֎p,R*q�I}�l�	�i|��������]R�~gx	jƍ.��o=�f�>�P��TE僼TZ۴�-�^�&��b^�����i�'�H��r�F<zZ�	�ox�:Ӯ>��d&X@�B����ꪄ�"a�KS����^j�}`|��a��\6e��4L����q�U{D��"���%�E�ȇ�ǺS�����%MMsV���ԿN#w�Wٍ��j��Kˤ�	��.���=���| ��㓩��z;hI���� � ]t4T��1���7����;�����mQ��&���� �j�L%�����󣧯݁��e��~��*��U�m��!	Ɣ�ZP�O34KS��s.�]�tq@?����gV���nr��g����.��yx��Ik�;u�V�3� �u{�W̠��R�j��zN<J(�,��<�u�F
9!PY��bM�c�{�Aσ�X����*�{�5��'$]���L]��!2Voq�����G NWǉl��ŭ{.���J#m�P#�g��q��Sq[�'�p�.��^m�U�}>�%�)'��8r���0�2���7�炅[���%��ڜ�������y�z_����D����@�����u6%{�b��g���O"
���vͯ� �<�AŮ=�{2+��G���
�3C5��o7��������ɴ�o���b����U��k�s�EN�/yn��xP����ڧ���)���_���c�n�rf�*��	�΁�s^�	D�Ú]¢o�R�>�İ��.~�)��b���D2^�y Z�8��TA{l�>�?>D�q���+�$z��y�ؽO�5�􉚊l�h�����A�FH��`�����.�~Ţ5iB��w�`I�]ف�c��P�xT����qSB�����j΋��;�g�v}����c�7J�;�cf�+����$qJ��]��&y�O��:��t�ǰ�u���a��/O���I���6�h�G"�z����Ж��e��X��s��	H���l6�14�g�O�hNa�mJ��/�*�t��˜/+�@�h�f�䎣���OC&^77[&��,NfJ?�H%X.$�����D�-���|����`���Z-�y}�1��t�S !���j̬���K�KsX����
�i���|/]3D��IM_��:'ҍ�����('B��3�&/��j�C$�8�7et?f��"��&�s�#�C�ߕW����x�H�J���u���,#o�EpIX=��(aj�\\�5l�4IGn�g�U�0�}� O8�z���$�ajrҍ.µ�V�S�l���1�O2��0S�n5fq�'��M'�Z��;cT����w<E*Lg��x�x�@B�hT�i��
�:�܅��]]F��8vip���se�����f���9�R�sԊ*(��֜bβ<֋Rv��V��˦�� �V_�@���n�-wFYqtڶb�7fv�$��疛�akڴ�ø&{���/�hQ�%u����c�]�U$�Ǭ^ik����)�e\�����z�MC�9s��/��FE5mK��Ҡk�1Z-�,���.�)c����l���HpWYl.7�N����1���w�l��w��:��s8���7����`mZ�m�]S���1�M�&撇i�o@�~�\*������#�^8��
���-$W/&��rP5#R
$�4K�E�6���Z�1�R��vW��`�ھ���I��=ʒLʃy�a:����]T�	Iu���2`���Oݫ�U�տ�����{u8�{� L�Yt3\,j'���
�K���O$05�s����˺� �ӡ [)��������(qşpw�薹�]29`�6��Ï�8�5���#M~����YH�.�`�s���5 �̂������#0���ǳ��*;@��α��wI
�غ����2Gjk�Ticو���\%`ay��uB�LU�]C�^mq~Wx,�#V�2g.LGIP���Ċ�8�x�^���-? QL��rE�(�4���� , �����8MV��Ȓ�ޤ�� �:�{�C7F���������\C�S�'?s �s^a�g�a�������y������փ�ͱ�R-�W%-=Jr o�Q���}�j�"�Ggs�)�r���=X9�r��8�C{wa�q4fgN�rgg˪�\e�A�0S���JM��gbD���� ���Ě7��ǀ��5�2��+ˈ{*��H�'2��k��?!k�K�y���ƣ���a�|�F�S������i.�+����Nn,����H����Ȇ:�X�p�3C��zI�������<b\��a��1m={�TT�遠s� ��iGo���$m�KЈ���� ts��2�i�?�ݻ�����`/fO-�3����(��Ev��7j��?�l����c�nK�:���8�� �jUX���y�̮�����1T�>$��]�Zq,ۏ�d��K�o �g�A \�")�6����S8��'�����4����8�^~}T��������>��4�n�ȇ�a����ᰃt��?;����������]��4 ��¿�U�M�\�+����As�O��x���!������P{P6G��}n����t7��;҂���Ҷc���c��>��N<�w�=�8=r̙$�K��f������RKa�t�J�m�+W��ka�� J7<�yF�L2�-n�m�ܕ�\+f�2	Q�
����Z�f���*YT5S�kU]u��P+_o��¯I$��e^r�x{}Lm�B0�-�˨�����u�I�o���T�o�z�#_h��p�Ln9�7'3�t	l��r��ܨ�^0״�']����-<M�䛩�Y�Æb��� C1<���캚����o"�x�|��e|��Hm���
�˧��Y�R��}�܆���x/�Ê�h[�q�v�����v���p���J��bhcȘ*��a���n��
�z��J�Ú:0���p�8,EW'>��c{]���ˢ���8�kL�����y-�C��	LQ��]}��BTܭ�Qjtv(�]�J�����<+*yzX�S  ���sV�ή�%��
��0�����eļWz��Tv0�ܤ�h���l�9�7���3��-7�`/Y{*wA:wU�Lah����C��,d)+ac�@<ޚ΅�N�-�P~�MS9X9�ꦸ���뺦#c�PҎ#X�
���fJO� 2�ӳ-Y�Ɓ��Y&��J�%��~XN��[7�R��Q�]�����o��P����h�/�[-��sZ�7�Pq|T%���Ѵ\M�ڭCWN��4t�Ɛ}w&�8�c���y�����8��]F�ӆiq�s���+r� �m�R��[��P�x�i70Qػz,�`�^�SX��E�u��s�ґ���к&�b���1���k�Cƅh��j��=����'ޚX�a�FP, �*BH"_���n������l)��Gq�"V�n�0y�<������rX�-G�?~4<�z ڣ{.ڨ(IC-�0w����AA�,�Q��!���F �E	90��z*�Ǜ��OP2��S�����m�A�u����/-�ɥ�����6�<�w;S�yx�*�-�� �A%�E�	8�b�^���Xjo_�
�]<t��7�D�/�������P0BK<�V��G��-�r�_�\�>OR���zôǅ�9�����Sk f?��V�T��Z;�F@z%���$v�R��@N�D���Z�YGwh��o�)-���'j�i��ۍȾ�O$�Jy�m����k�b%۩�+��P�"���v2�ڹ,�H_�0/�(g���lL-�a�>+0�`Oi��������r�����_Q��w���s~= ����$�Cn,�ZG�
�9�����>A�+�����V���Td
�;���x<���N�r]|���BY��U����F��56�����>�8f=R���r!P�D��º�C�4��|�Lx��5�7,M&������O��h�*�i"�wG��ǭ������H�^��n��	:�؝ �p�u�m��䧨
�_ѳu!wB4_��?E�Jj�C�1|�iko�M�]���($j
ef�ޘlh��_Mq�Izt�ݤ��!l~����̒�)��;S��x����3f�adBj���
����r�-����рǬ�Ϛ�-�:T:ӂz��n��o�N���l�?�"�@�G�~�P���Q#>7�/x_��+�/����o8��晇q�%�߻[V���5��N�����,�����I2���gX�v���dӦ*f�1������]\41@��w��ځ��'p�bC3Ɯ-y$;M�-�O���'�Op9@}�������#1M/�nm�'��bsM���ЖWD��W��6���'�
�O���j�I4~x�s񺓾�A}L�T��ux:+K�7t^6�u[R�$��ٸP�+���q��=F�a��P�:�S?X�p��:�=���4A�V�Y"!AICH�w�ŭ�k�&M�X+2�K���\��I�Z���k'��<K߇�PE�Ry��ه�bɬ�Ȱ�G��N��;�j�v�񘏉 �A���d���/�������x<�=��*��Uk.��b���E|�����(כ����L(�OK�v'c(cn�m�0X�3	��Dxw�߾���|(�������X(;ո!�k}[-�ʉ��Ƈ6�c���MtH��=]a���&�r	����wJ\�GPr�hv^b�'l����V$S F-���7�{R��^��,i��Is�DH��l���1	�}̑�J��X�� ���/LV̔�����w�����C�.�+B�Q���̣�E.�v@�X?�D9�R��k{qG�J�{�b�#< 9�d�)!������1��S�y�ȉ�Z.;���	'ӹ��xe`T2���{�XߒͲ-t��){��'�<=�/����\b��Wb�W���d��{Ç��!�D}����y�|��T������!�VÕ����F˧8nt��MO߅�e乙3��.}���PXG�N+c�E�Һ�N��Od�{�U��ף����<z)5b~y��  :�z�����P6cK@�@$��8W3r�j�j�l0Y�yd�J�^�h~҃��� "�ߥ�F������d�lv=I�L�����VM=�p�ȳ[)�s��H�f�A�Ȫ2�A�]�pe��B{l� �����G�4�t�k������Cl S��Ϊ_�VBS3$�Ћ`4�w� _���ZL<��T�qP|�A4�U9�Ԧ��E�0�g±_=�߰k�c�r��D� �{��3}���%�-S3���	Z���Z�{�shlW���q����t��K���$���aʑ9��g �k�Q�$��КG����D��פ#��O8�*�K1#Ta�Qmd�
:�g���t�0��p�2�I���Ji�Cʢ,��`�8rL��w��f ��i<�	R�P
Nɓ~iM�F���>�3����J��"R���u5�Ϩ�c��F��mi7�Q�6�V'�W*/y|<�����9��C�4
�G�p�6�I�7��b�}�G���C%K��%F���,�lsf�a�g��-ܯ"o�~�x�.q�mg(z�}�	!������E<��;99���о'R�;-*��ө�W�	=v���.�k�I�Y��L��e�9�cu�,� ���
SfF��h�\寋��^�PލT`M8CG����o��(e�GNf"H�d�g0{���<l;�ҏ���1��}� ۃ�u�p�	��ix/���>x���}�_QA�}a?K|B�^ʩb��1}�e�Cl)8@ے�	�Mu�}�w��A�X��+��~L{�	3���T���!�a�0v�s�9�Z3H9��;�-�v���D��s������B_>�f�w�w��h�%��%��GU%yr�d��3N��ބ�?�B\�8)��U�eJ�1U��"O������a��'����C���m�e�/M�b�#� ���ml�;O��,g 쌜S}�������=�0Y2,�l,ǌ��L�p�!v�~����0��c_dN�A�ѯ� Z-�A@�Jp?����Z�v�#����x��Jؾ�ı|8��:%��NX%qG3���4���K`MR��������3�]�;�f��*�6��<����gv����It���Yٔ�-B�vj�}zu��֢w�G�-mJ��`:��8�.KUX-��$��[)���Wk�W��"WV���PÆ���l�.:��B"��|���H�T�G���#�����.�����Y�W*��"�|������Scq���^#D�h'ww�rYe��ݝ;[lU�zs�*�lp�Z�)����ⲹ�N�>|S���%�����@��iz�F��-b����t�{�1J5�,�S�Q]/��˅V����%p�Z�;:F��\ü��=b�\������	�ݔ{[�8�q��Z�HO�Hϣ[�9J#`���r!�\~>�4*r5�'#Y-_)��Xk^�yu�ZH]	�g��nC�Xդ�+0p���8+J�5�.���n�M�}%�S�S����r��Ņ�?�<�<��ҙ�h-�\���<�\6�E��k%�]�����A X#�E�}��^��~r���+�dV�tb�!��G}�
X�.��k�9�K�>���`�zLbW7�����@�#��(
w���EC�=�"6ב�����A��L��&��dm�f�Vu��<�@��[Zf��C�p��Z �ZZ9�èS_[�to'��S�1Z���oWYA_f� k[$�;�$�t��_���5�I�����P���'�A��Z�[p���g�nK^9���\���"�G,��K"�U�@���goP8�	�]E{Xi�,q�|�I�� *�䌦I�ri�'��N��Śu�R�K��qhz�%晻�����H*l��
������J�?*0�W�A9�!u��T}�7���>��ͅt��Q��SԬ�'/��f�L�5�ݵ ��kz�;v]&Ӊn���5	���4d���@z���L���lqJ��@u��=9QgD����hו��ף+�L1��s�j(>�0��p�&Q�ꅲ����#>�58�-d��a���S��;��Wf��s�n�������,XSNk����8aJB%�`�+s[/BV�:�b�N>Bz@���#܂�pi��K���~�oG�Tt7!i�{Ֆtx��܎=b,#O�~�j����38@�{�7���_<��m�:��+-�!�u��}�^��/��/�B	V�t��|��lj1��D /����&I��z�FFn���Fm��^3�T�%CE.���y��-�DU�~�Q�T����O%z�h��͈��yI{����6�>�T���k(`{I���>ܡ���x:�5�b�����^Cb�m�!^���cw�i�.�����_َ��97�l���:���#^r����Wɾ��<�M�$�$�8�s���V$�>��}�swn������ھ%��k�[�2��q�^[=F���ߌ�����|��x�;�v�ϫ�3�ɪLѥl��<Oo�2�r��E����)};�z20:|�rj��8E����jc��8o��H�Ҝ�8����KA ��]���%�����c���㯷�!OyÝ�>ޯ�*�<RƑ���M%Y��>��x��!��?��U`��,��|�n_�SLlM���3���Fb�h�s���8V���ş��A�`k��]�~��ۉ��s�!����l"�� g�|�5����wD��ڪB��jS��;��7PW=Z88��H@��R<G̜\�$H��W�+�9ĺ��`x�R�6}͂y��T��I���$` �na4pB����8I>AkE�8��y]�)S��BY>x7h�u�\�Z�%�3+�K�������l�"�#��C -(*��0Y�1^����3K��	L��Ʉ��j��>�t�.P���On��I�}ﻛKՉ�1(Y���p�&WҴm�ރc�:�/�HO�4�JM,K�f5��J��Y]��In$ZN�m� �R���3��{ʔkG�F#ж�۪�G�Y�
��FcfM\���;G�F��/�/ya���%���W{��5fb��g�䂫~8uT�5�S\��Z}��H�I�?��b��}���vt�ls%]|��K�=�J@���?���؎Lx�B�i���"��������6L��z��֐��y���w��<����Y^���BUY�:|��y�����_����Y�XW�,�:�OV�?��v3;&�phgX�V*[9J���ֵf�NެrSsLK��c�v�f��s� z��A�j��}�����ё8�Ȟt�V���]�2 ���]����g�,Y�Rx`~����}����j���_�*vz�Fq2������&a�rf'�|e�j5a`�r�&
T�k�\�F�l��1�w��XjЕ&�;J5��ꜝ;^Uzw�CL�.e)5\���;�s�����h?��V��Kw$He��݁��3�D�F3%��~�0����ܩ�2l�>��$�ż	�H�����ү�+�����Գ�a���.��J���`��QC���W�xEg����S����Z�T�4��0��./8MC�;��[���p1B@c����HV���{f0�f�&*�WnYI"*;ӝ�����#ڬ�9j/Pp��E��$��	�#����1��o�`u��j|������d[�����J!n�� ��)��6��
#"{�M#UN����ls��^^O`�{��b���m��`Ke����p]R�/������s�K�0`gؔU��kO����ϴ+���	�I.�L9DPg�=0tƴQ�夏�(�uDH|���SB ڭ�F��Sj��_���l8w��Ў03�}a5V�U�V�>t�k~e7��t{c�?��qE�O��7�ؾh�- {����{�����7�Tg�α6�X3%�����䲢Y@��1�.V��\���B�p�ж�M#�J���є�C{r��K&=��w�,<w���J6}2i��gN���S�¥;��2KiO�0��l*V��Kh�������Lj�[rϻ�� (]`�j:χ�P��r5{#M�B±�>�vJWt^�y��l�$w��L����O�� !H�MC��R~w)٘+y�ю���I�s���	1� �0��pNZ��=s���s�vd�I��3K��@i��$vI΃�`�"�&t=b�O&ͦB��:)'z�bƑ-5~+���L$�>R��)z n�J���a�_�؂����L%ѯr��N���GS��	��-�/��8�`��Cd@�#���_��U�<�0K���؆��3�<��^�<��Q�
(�JGy�:�hV�A]Z�ަq��8_Y��x<�^�ڑ���Ӯ\��F������osr�$Ņ�|�X��_�s-�FXhp��48�U�bp����(1v�9L2Z)�K�T���� �'�3w��3� W�׫-E������L�����q� �ݻ�i͏�V��R��@؏� ��j�HE�T���]��"�׳��.��5$�8����	�.T��;�q���Y���aף(ߔM��#a��r���ƂEڱg6��&y�}@E7:�d�]�^08�.&�3�Fnh�Rl
�м4�)�����p���<�+*`+^��%n����^��~�-����nѣ�	r��b������3c�:;�յ�5�f����q��F\�WHiJ�&�6˅1��ΊO��8[t�/4L���3�}ߘhdYܸ���������F{�짲�q`τ5���r�tj3&�X�b�q��A���9hq��k���.BzT2�;�R�l)pɝ�d���ws��Y��ͷ����b��j�04Ӹ��Jy�v���>#����{�����X�3T�VS��Jm�@��Zq3�9�.�7���� *w��uC���[��&Zф�ς�o�K����� �/2"��P� ���]f|8�ɐ>F�`�����I����/^���b�����8E���M��MU&������w>Ӡ��A�A�Cqq��g�_~?�#t������ͣI��ޒg�/�I�Öe���)��::6���;Z@��Ba��� �E���7˺�`�c��1:4꛷���ңϊ���CAsbĘ�"�j�4n��b�r���$�L1N�J.a�'o,�S{���vNgc�6ѺRLǡ��q�뤆UۙLH���Θ���vL�X�ߧ��r�C�����\�a�4�՞��Tѭ�1�+����sK=��]���E�ܐ�Ԧ0\ܮ�=ӣ�$��Vu�ꦱ�y��s�m|)T������SZe��=I�����i!�i��,� ��S�x`��}��gf�����	�tU=xʲb �<��*�킖��)s�c&���|% ��C�W����/��/��zV?jj=B���k�s�Fx���f��(XWflu�$���? nÅ�Ari���>����6NTO�s�IrE ;k���xT�e����a���0ۭß$W͗Wu|��WZ$@�����645��5ޚ���d�Z�?��o�q�_�q0��'�|q��S�h|T_Ek��悟i�߇�ȿݡ�}��8�s���ZM��F��I���W��`�ʾ�"�����Q_�M�,�@�q,^Ơib�R���p|�������[1���|΁8������W�'����;¡ܘs>�ʮ��*�_�8�/�j���9߇^N���=ǿ�ϩ)B-!'�:f҈.�^T�:���Q��:��
�m4 ١�*�(:;�Y�P�]H\�,+�*��z�-��mz���.3����Ԍ0#\�<���x����M"��bZ�b�
R������]��2+�!o�l���f��yDR��&��!s�	��l���/���/(fl�W?��1�V]�$���=eA]GM:�������CE�=`��<���qTQ���9�]����s�,k-6�O�o7ro��`J��(�( 7��K�QdX�Ԇ�����H뽨��P%6���G6��Δl���X~�D߾_ݦR�[�І�R̘TB�Jު�=.Op��;}p!s?�T�!O���㦔��`����}غ3.��M��b�,fx�J�d���J�WC�n��W�2�'~�g��4v����ݕ�7U��qB�}�V�E1��i��_�C�U|y�uUDߟb�
m�G�$b\���Y�'~Dj��bW]�O4ޮ�p/��.�2�kE�L����2�!�^O�\�dio��d��Z����wJ ���g�f�n��P�F���h��پ`W���eF�>�ׁX�Z�ÒBjf.����џ�}���~�F�8P��� �f<%�ހ���ZCO`- 57u_6x�9�s�a�u`%���f�B��7'1�6v4��]��{��ջ��R�%���G��<�;Ȳ�zQ
�'�X]����^�$�u8�km��Ɨ��fb�*G�`�[�t�f����$^.n��8��gͭ�a[0��ߺ�����<�f0��{��+z*o~�M��6b�����ג�p�:�?�W�A�>�]��~񉥦z���/=A
�Z.��(E�Ud'7s�Wi��ð�p����0?�������Pu]����Av]�y[
I���ޛ�Ҳ����1��P`�w�ְ\������.-�{g<V�s���
����pmJ��N}k[m%����>�i��]�L;���̮�4r_��d��!�����d%�#��&�
/��Ny� HZ�̹z	���a�ބ8~���+��(��"�`�++wvߵ��������v_\�7�R�2{���0#�Rk�*��m���D�ވ�sO�=�_�m�����_̯ptYY������������5P��DҮ>5��~<$7������.3R��r�)7(��?���B*��IY�QhA��GpY�PΛ�F�U��ƻ�u��x�������h�x�BJ��n��^��E��K�Ұ�,ƙ�nL�R���+�E�u/9�u�-`�~[����/j+�>�s�8�'鵭h�-�+�1$�4�{�OA}yw��<�q�\
� ���\�����y��!&�ӳ�3�* Ik|���wHl腃��?Q$]n�J��u�C��h=��z	���%��s�c�6�g	���<�2�ɇqny�)����:c��M���T�п�|�]~~T����y�mD�+�C�����"e�?����Bou?҄��W�P����c��b�ժ�aX��0��|��%�q#���UUҐBN��P'�6q���3s^F-�;���"~Ω[[n9Q.ͨ��9`����u��5)`"��=�_�%:ǥ��t�/Q(,����q��Ht:�Oچ~DE��58Åq�򭶽a�Uu����ڶ,��z��jvñɞ��w�����tKPp��E��i���h�T�M�?�T�e��A:0K�L/��{�Ԣr��V'fuYs�H�\0�π�H������"���z흏��:*�� >��P�l	A_"�����O� U�-^gk�Zv0]̃_����f{��	�=�ܣ�|���k���V�63Z�;��)v.Z���}t~#K���j�̓���~t��6��$/npE���'_���iݬ��$��'o^�����.g
����3t�SWg�7˩s�{���V�r��M��/_A�c��^4�����AI?_(�Lt�K�NS�Z�g"�A� =G�-���:j��F��sJa�;�"
_A=�Al-���S�?�|�#����ׁ�˹�<�F���ݼ�Hw7��F�L�썶�-��ךz0@P޺���2g9� �U���0nr���'A�{��4�E����Y���o��,~6�Ry%uɖ^_g~]=��A삩v��B����� �|��7$�l(��>���܅�܋��*�d�'���u�V���X�<���	�����Ǘ�w��M.������\�u
�"g�#B�
n�T���%�]R����ʯAﶩ�On���*��,�b��Vy�qտW@�<3�B�t]+֯� �]�h懐�	����6,f� n��<� ��m�D���4r��V��9�\����T~�Q�n(�B�K��̓K��(���"�t��>{p!QÇ4�/�`�Ѩ�FN~������!+ѽ�bFs� ("�sqm�<�fQYe ,ޗ��'����yK�`�5��ܨp�~3I+����IԌ�:�AP������I/����1�K����ZJ�Z��Tg�f?WPRS�h:�D�Ƥ�V
�Y��n���B�+��ë��h7��?<��$5iX�Z������e:(Ah�2ܕ�M<]���n2|\g^��m���H��}d*	�c[�&k�(��@�#f��LĩD3��x,﫺HKZ  ]�=AD$�5���0=4���VU�,�̫�O��+�[�u�x�
֖��G���n�z��|�)���B��޳�v�-qg����Zwk}�tS�1G�$C7���36ߤ��:��=�����2���޶�7�+����B�tsTI����K�!���e�.�c�JQJ�>�f!�q$�sgSt�4������7x�"]ՙ��膦v7�3�ҲLh猊N�v�#��-#�J�D�!&�Ӱ69�I���
���sXoFf_��Y�c~���1�5�{���#m?�4<mY֩�/�`�Y��4��;c yʝƃ�˷D��8��?�] ��r=ds��a2��S��~D�@��l��4��7�X��?j�"�x��G����u�*�,1�4�(_���
��5٢�kc�~��/E�	 ��F;e��ǗE�Yl����C�ϓ�.(��rGkǞ�5��4�_Õ��ѭ2�����r����{�T["��S#/��Fly.�$�,~Ɂ��)���~��)��~���׽��y���q2��.�뒮����P;Bc0Y����g��|��Z�z�\<��ӹ�S��$���+���!�֬e7����mV�P��K �����?ې��=e�	��Db��v��@b�?�LP���Cj�_��[RZ
PH��/8��s��^�m}:,#Aϖ_�B�5~/1��	cb0��Uz�i��������Zx�ruȫ\�^�BHE)��SE9��+��T�]�o*0��G��w�V0c�I��F,�w��d�#��E�����������/Ci�>�3	�[�9J&lb:$?�Ђ�U��3���&������&&@��z[�����x�HR@�䡓}І�d�y�g��Ywa��e����E_s��ł�X��􌗻�N̯2�}9c���yb�)�IE;� K<x���3+�C�)�-OM�b��������Fr�{hΣ�1|������q�++�QN��R5Pٌ ���=l�c
(#W3RR����c`P�Mvf�ܜ�%���RQ�`v|bȥZ΃���@5��k}6�gR��w�o�)��J���:����	����cA:�ز����D���srM�Z��B��ٰ�&��!�C�l���t�����|����^q�u���t{N�t�=��|�KcҧK0!�(a���g��ʷ���"Z�C/�(��
�g?�|��<	q�㤛̔�!������Zn�7����<*�55�m��T��ܘlb��w�䭝H�����$���bw��[���7x�A:V��o��OնsӠ�d�0D��y8T�	@�����#,Z���������AK�P�ŕ��n��9�6L��6�[OY���!V��^���s�w�Bi��I��Ao��'���=�.x+�#*�dS԰�h���������I����&ms���+�?o~h����(6V��(���K�*d�B�̧����� ��KS��5xK9ұd���y�Res��\y����<�}
���':�B���YBs?q�L��~��÷80�t���t7a����p��z�׉Qγ�{�+>�����װ� �X�ucP°��8�w�8@���S��d�waf�L"H���<�����s5��EC����/LC��H����'©���'>e3�n�wrY�[s���'T�9 �F�x�0=Γv���RD��[��7�*�g�Y>�gD=�&]!�z���9 ��ԟ�WͰx�aI�H�nA����Б=k�?~譆ŗ�H![����( %���c���V�ji��ծ$K�b��e�qN �ѭ�}A��T���Aqm&�wk�����"Li�Π�f��W�u/�����xr�k�`�[�$C����Ey�X�H�܈o�eL1$��.����6�gc�-%�U��$�䥞ׅp��ߝQSr�&}HpB�����A(������M�lJӺy����+�kz���-�Kk�,^kW�r�\G��a߁q�z)g�U1?���'R��:�E~XJ�Y?}���j�|ڬ��%@�n�&��+	�d����p����O��zI��ۙ�cX��î�w"�Pea ��a���m� ��0��!v�5�?�RY��x���Y���{'E�~���8�y4=��=��[��Zּh��r��ͅךF�;k�\+����m��2g��۩�n��0 ��<�ӖQ�/��(�([�e�1K����{&�`	SG��x��Dl�=�F�,��Q9ۡ�����DdYYH�*fѡaۉi�,��D��pYV6eC"/l���MA=�-��`����jN��|Ǻ�������?��"`���
��W����.� +d�C�-u	V��t�߃���b�2�����S
�I����>�1����BCx�(U�$�r�J@h@�^;�U��0�jXvV�/���J����Tm\�Ll���ߥ ��l���) �����[��cѵ69�FG\�JX�2jHE�a���B8*(��<��E=��_> �K�h:�3,�a�\�c�5X�ۃ��Ց��tby>,���,�l��H�
Ө��|��,��ҷ ���(�N����w�������AO�h��fH���ֆT��bb�iD��˘~['�:�����7n�ީ���Ep=��أ �>�ך���:��5�-�ߜ���N!l��A��Bn"7�4�e����l&5�:�I�0k�]F���-�����s�47P���<��vO_"�F_�ᗷ�j��#X�`�����&Q��gM�F�Bv0��0mKw>~H�D��d� �%��[ۑ�}y,���k���k:Gq R;��o��#Y^�N�3`�`|u�^w86�i��bg���yT8]J$�A��*<�I/�^���R��;$-ɼ��ӟOjw��@{�P� ?�� G�U*@R��L��-'(� �~E�jo����%r��K��+2��λ�x�����RS(��;30Ÿݵ��s,¹�<�XZWr�G�=o$l���ޠ���g��6wM�������3	'	[�VL�%��Bm�B^7��������F�O-Y������D�n�a��ctYa^��c`ޮt2���p�1�^DzP�l{���
�������t�Se<r$*2�.�z�b�=���f�Q��cy��[ڄ�#hܿA���`�#�D���[:����/B�5�Fv�Yɵ7�Ԏ\΄tI���,����[N�|�/$�PY�|tf����h+����#c���H��Du@ 	��\���wL'�ԏ���b��gb�?o_��# �x9�ّ��j;Iu����O`��s�>�i�� �T��9y.������~�2��|p��԰8�
���m;m�l�$�k��eS�%��������[����f��\��1�e@�S���+�BUU�@�������ؾe����\��ˈ��Ţ��nγ�fPEv/�w�ƮY2���l�Pqz���bǼ�jr^���ꢁ�x��MG����HfƆl�7@��te!�L9b���*��x!�d[X�B�Z���R�N��V(��o8A�l��Jlnh/�    �"���s �����Jֱ�g�    YZ