#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2656538955"
MD5="96cdd85a913707fda6d0d18b900c79d7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26468"
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
	echo Date of packaging: Fri Feb 11 04:08:08 -03 2022
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
�7zXZ  �ִF !   �X���g#] �}��1Dd]����P�t�D���,�FX��\�qua,��z&ĝ��XvLa���ZlBD�)�������̙���p�y��O3o����?�;SM}��d���R�TS-QT�aB�����c�1����ut�F�qcQ�JkX?q�:v�"u��A���9)��g�旀�� �	�y6���;QviAt<_;Fme�	��܍��jE&�(���ݩ��N�0ƶف�����oN�\�����w"̉���-|�kAM*�o�c)�Z�'�T;>���'��FXO�8�Phw���ΞG�[I���oPU95��h��-M�bc��cA�y�rg��A���?���^�|�����7,����}#�f/�mS��?E�+����{1݇�Ր�^�������,`�����
� ����(�)�ƿ��=25�AZ�5<#UaR�)��s����7j�)����F]b�f칉8�L�RD��g�2�[�L�L�ble���5�R�e�cf��m�ͭ$���CM���B��D�
%7���Ǧuv�ڱ�}��jW	�s�yv;c�~���^��8?@ya�;��VO1�\�=p��>SyP��"�7�)�A�CMI8+�V�@�q$�K�������u4'�"��2��5\��:����-�1��$/*��{X� kD��xԇ�jE�G���E�Iݒ���"1�W��J9�XY��|{�;����y>�E_�&�CA��2؅'=��Ҧ�'I=���ϵ1�i]�<@5W:�d�CG�0�;�D��=��^�Y��225�l��'k�"cH9$��D�#�7�R����=�����O��V�V������[zD����Y�e�%����#�=�K���z1�̕5j�}�4���hi{=��c��HTEfX��b��m���|Q��R�x:��uqj�`/�W�$SCwP�������X�T�� #�<IݡK���mu
����� ��ӎ8)Tf��G��q�T�c9�2W�]�� ����������H�(b M�>3s�#
���"r:�<s�L�0���0h��7�~M�o�C�����WB��WBw��x?c�O;�c�[��KG�[�P��G5 R:���N��v:��:����Ƈ,�TS��.�ߤ��A��-��hwl'��]mf)�?s���S���k������H�N�G����~Q�Y�ٳ��V/̝Ly�_c�J,��b��3
��1;5Q���S$a>&I� P���p&���P6:�ZW	��u�H���Y�����7�V9G�B�@�R��'=;���
�,�y}���F��{��\�Q��;E���ʷYF^s[�{c�k������:�]Z2^p(�H�Bɢm�F�(�Cp�=Zhs�y��3|����yd�^�=���Ω���0������j"q���#W�g�U§ā'�Ǚ�MX㊵V�1�
��/L�
N�O��^�1�̴�!$�H�E�@7�b茘�U+6��zw��v|u�v� {��zF�R?{k��4�񱲑�s�h*uru2���k���	J�9Z�zt�)�袺_l`�~9���
�i��VL��]AVd�j0W�z�9\�;W>�6�i�)� мۿ�D�]�G��BN@g
=��@'U�f�O��(�LX7��Qp���(����
.,��+cJ��#�E��ֶs=Xb6ܮ������-��S�=�-�tkl��oyms�-i����'u�@��"�B�.�O{4.�mn�^��W�~����a�%�Ga�V���m�]/���k�f����4�AZL��D ��F�b�:U�M.��sǭ[���Z�%�Rw?��"��#N-�Jܰj�%D�cT�;k��_���I��h]lGc �1�xZ���1�앿8��^����z��+/�r��xb��k���A�9�.N�{�k���w�Ej�(kGBӾ/��Uk9��x?�2�Y��Q��P��x i������/FC�
ЕHrL���JB�驰�L��^�0!�2<�
n���@��a�*�*�qf�p��LD�b^��~��vw��UdD��)�Mw�����΀]���+�U�Z��ASՃQ��2�."�Ή�X�8{�[�|��{\�p��g Aӄ�"�[$ǨFjn�̮��-C����WU�Q[ȫ�W�E�'�}Jn�} [�İ�������륩�!my�v9��G����Ȗ3�5m+jL燴6
8�|r��u-^πL�o,��xaF�g���o8t	�[j�}�9�)���)Dx�O��^{3Cw��������j ��#[dώ���!�&�v7�l����x`�RU�,�W �6�����m<�-y��
+���1���u����?����-�?P旇��0�WҨ���k��cs�`^m?�P��Zg��&�mt�����G��'N�i:���7ttG �O�80����?ĳ&}:b �>��:Qv����*�|�_4^#��ؾ���lmI��M�om��b���F�.���{�T�\;�B,��K��|�wNfZ
y�6��8h��u���nHL2�����o���a���D��-m|?B]uqgTWMv<��t��	��7�]Tj��F�w��h9\ڱ7�"H�؇:b<= �HB����u���U�� q~���$���)�C�R�sJz�J~H�Q
�wǤNY��N[M�����3<����|gH����h����#�c����Q�4C��0���A�Ir��$����n�����0:�a�%,����.�J����KrCю��o��I�"sq�O�|��-9��b�������Е�{2���3B���5�z�5��0�1�y� �~U�@����FR(�K���d��m���$D݈h����l�P-�Mu퓼���7�.���_��G͞��,��UALC�p���/��ժ�A,Q�O[t� Mo�&�V�(%dCyG�L��c��i��H]?��\���(��wcs�6?�7��\tO'5"1�B��]_ŕ ��#����)�+��S&�q��,����%�Ȕn=��[;��:�7�#��l���J����7*��
��*�y���Jh�V��cq�3��ek�\=��H1�AkV��m5/�&쁤�t��y�3%�N� K(�R�S���\؝���&"���+B���@T�uW�*����@<�"�f��G�0I�9���̦��bśj�WC�-�m�mU�g �����`�>�7�O�j�4�U|�J+����i~�Ih�	@�o�Rl��*<�I�{X�Ӱ`�@��ՎB�b� ��9�g����'�J��7y��e2�v��5���0��$��c�|3lN�-��Jm��O�c0��XO(�<�8�~o���\Yft���:B��|>bY��bPʩ��^N���ν�ԏ��("�;g�qNcKkҷK-{CP8��^��"�T�S%��TO�.���b�幐��j��lN��O|Q�X�����e� �̘$���-|����D2;��^���a��3S�UaI˛��-�:�7o�_�R�֮Y�4g%-��F� K�ڬB�mE��4�?�1o��ubC��@{�){��p��ڕ
A�/gN�?b"��;��͆9)W��O��*��*��>!&�����L���u��!��n
�x�a�����3"��ي�� �Y�$^�~�d��5�;rE�a�(պ�w�RKi�P��l�Vd�Zu�z.�&;����'��}96�9_8�d�F��.��^�⣵(�[��#�)6�<O��?x�O_�[���v���6������َ�v0�G��?�&W��dC��=�v��ƮOËMD���H�驊������"!4�	(�C�k<dP9�O����X"��)c]����49~�z�xCi"��_��	�W�������j3����9A���X]>{9c�_vb���"T�v�/��Zp�����C����Jѕ�Fl��g?o�}i����A���w�S����D���ʗ�&���
��Rf­��N��ʓ���a2�o� �=��*���T�Z�,��Z�0�L;�P>�� `�"7)	e��D�X	L���"��\��a��Z�|#�D5��<+��ᅨ�o�4*�D��M�E@��+xm�"w���<jبZ��f��b�\���^�.���:Uz����g��@��� fy�-�j�U��@��	�s�U���X<��^�Ԓ�Ǧ�/���i�7�4����� �}�`����a��|wr]�|M=	?05����A1��qy6RG������ME�W!�Yvg�&s��V�p���3S��5*�B]�Ĳ��+�:��>u�Q1<*�j���g�H��Q�%���Sg��ii�]��_G��$od���U�Xg�_�"`�.��̶��,P2Y�fQ|����iQ9N����M�AIS��E����wָU��	�b��v*�׵ �s~9%=ȅ&�Qu�&A�g��=@�>>�X�#H���v-�ׄ��sY��G�A�Ƌ��%_�p������¼�cym�W� ��=W��\6��e;�`�R��6(�ý!^:C���[x�F�����ebW��W�Ա���;~��J&3ַR��Ѥ �=�u9/2�w�y���NA��S1�΢���Fs%-�o~�ދV�C������,l�pÜ���W�U]�;b��:�s���i�F��͕����QBWS�j<x��y��m^�M�w{�Pͺ}g��P�IDf�r�u��q�Y}����M���� y1��*���j�O�+K��Ml�[�:^�X�[;I�`U�N��1)#��ʱ)���X-���-+�q�7z�S�z���1$R��?��_S��|?vcZ��iC��z�j�� U':w`�u��S���pMk�E���x!�%�4]��}v�󮻉x<�Q�uML����$�G�O���k
kzz] ;������L�x 
�{�t0����G-<5�Z�q=�qC�6$֔�(�B�?><u��+��,Lk��navls�V�r��{�E��Q�K������ (O<n��G
u#�Wox�e�i?K���̫��_�%}h(�Wnv����â�k$�(�hO�>�g{�+��ۅuQI�mv�K�;�X��;'���eZ�qj:+T ����`P��@�z�ʶ_�v����N�d����c�=Klq�#�k�3?j�6�o��gBjW�,��z��F^�$҃��@�0��@���Ւ3�W}�_}���]NOW�Wg��v�о�f�+X�ʇR��J[?5�r"K�Q��MGZH;���\�"w�'��٪�W	K&z�sҖ���%4�pt���<�[�Z�*�`��!ܷ�9�� ���v�@;��H���ev� -�O��:���f��F(`��f�ףi{R� U�pW�Z�X�p�͋C������
a]��-1m�K�vbV;��4P�0}t�A[�8�jH�-gQ�3�%׻n��D�~�y`��h?H,���9'�����ܾPS����
��«�NC�� m����)x��q\˴Ug �A���^�(�N�h���h��σ��<�)�b�6�O}�M�k]X Rs���A��m;�ݽgM9;�q�W��i}'JM]�O�PFVZ")Kъ6�<�8;Ӕc�Q����_�f(���ֽ��#�P1�v�u9�!G��U~T����V��0��Tz*Է�M8�)�^G.�aP��~I��b��+	����B�>���O�>��M�=�N|�m2���q
и�}$AR��{��n��D����`������)��9����<_�>�[uI��z��>���9J�H�Ie�V!��~&'�T��鼖��(���X�tga���sV�{���H�F�2��ϥa5�C�(�w�N�Ǽ�W��̚~uOX���R]�\HrV��V����c7�uH��r��)n~	�!�q�;�D�����%����@}#�QJq��q^�N��Z�"8�UCa�����@����Bk/���NT���"�s��akB9����t���G	'VV�T䦺jQb��Ho��d.|X]$�J ㋿�����n��/�T��|��)�R�.�z�\7{��D�r)FtA��
��P_`�Գ3�q�1�D���4&^v��ܭ:�[�T$ �k�{KC��ck�\�IY�O���n���C:� $����cAgU��kYɳ�+�;���m�R�Ql�灨����;�q��/���E$�gBʓ|�̫hoR<�e�Q�"3��ju��E����_X�a��D�7dg�E
����̿~����s�<_�+ɿqbh�ЯL�spqM4	XE~������gΎ��Ctw ݬs��nW<1[B�c�,��=u�"T�#W��Q5sL�^&�҆՟���I-$R("\9�Ǯ5)�-�H��$�ܧZ��sP�"���O��5�/���jC�S3�޵ N ����bK��$� ��vy��_��4�m��/��Cƞ�ҌRv^�P<���f ӳ�y�-q����WڭĽ̨�z�୎�X��|{f�C�~E,Qoŵ�
���W����!s���]����ی�\w;MJ�ɜ�<��AA�[3�J��-3y+��=Ͷ��Y��1�d��iԅ^���4���Ӥ-Qtx�ގі�����P�T�;(����l�h��b�N�x-�6��d9�sPT�x����sT+]KCd�4ӭ�ey�Pp���9�ҨB�����Pn�Rj��c��1z�XK��/XR����sZ���M ��Mb�& D���|l�>���'Qt��\�㩩"݀;��?F�6��eE�����SC���O�۳JJŤ2?l$����õ#Ҏ�"'��1d��!��q�Â���WC� %gL>G���&����e��=��/Z�Bh�j���с�}RϏ��S{OU�ďLum�-�׈���+�ōH֍��e�E���q[>5��{ &��4�}k��L���a��ޤa�ǯ�WU��m;o�~4eŒ��U�P�`�>���;�DM�[���0(w�X�����S�2���MJ�5�5��Y�|.0�P{���Xt�����Ͽޅ>J��y4�i>��|؎p�� K��d��& 5�3�e�0��q`��I�+TB���&p��NB�|I�<*d�su�sVώ��~뮫��b��sB,"AM<@\��se�)�^�Q�����J/���;���f���:�`��k-��D(�jX���t�9��W|� �� ���\�c��Ե��ݨ��Q��7��⼿�K�t��kNݽ�?!�ߧ*Ulΐ��<�}EF�����$�O��$�A�%�#��ĨӮ�/k�!�o���	�t�2�Uܔ����nt��ζ���8Mq!~� �D��!��秝��St��Sari6��h�7��*�����=�c�B}I�o�zF�}N�m/��P"�X��t+�2v���r����*̬9;�U�~�4K�Π������&
TJ�d��bD:B*m��Wm��X2�����|	��ݔ�r[�������8ݫ$�yZ�KS9)��ˆ��0�L���;�%F�
foD��'�Q����{�;�i�>����ݥ�4p�����^<Q{{d��y��bj\�8s���\A-^_c��v��ۡ~tEA��ж�*ATߖ�x���K5sY�K[]�_�X���7�=��zki�L�������2��e3�m�}�?��nxVl�Z���ځ�3-��fG\��;�ּ6���:�':���8Q�x����cgwc��Q�t]��{z�6�r�9]�Q���a�>B�d���9�x@́[@�쒱_`��aP�Z�X�*�M�jQ�$�\��	r2��	�1LJ���&�3��J*!����%�c鋷�g��>�6�I2)ܰq����/ OÈ7�H_2ͷ��������q��V���.8u�w[5?�D�8-�\԰ʎ���h�٧s�U��5��#iB����6�ZJ��!��j�\"LN� 7�R��Yէx�k��e�ʑ�qjm��Pc�)����޾��
�K�P:KMo���Oh�zs
����y!E�
Q�*A�����>�	;��k��q���ρ� ݹ��ݯy�\F�dhآ.!����ɦ�%�n!��Pu[������X����0^4h$������B�,R<BZWjy?�2U ��*�6GL �ۢX�4�������&��������L�K��H��l1 �|�("���8RL��D;�a��)J�H��1���l���a*?.d7�}P��R9��&�l����A��Ռ��t���3>U\�0������Rn$��F�ޑE;`S� �v��!I@�p��S��CC �"٠�b���0�B\�5��Ru��9#�(�!���uD��$f�u���S�C�=�ˇ����\��Y7��H�����|x�_w�w����!,#q�3ܶ!��Z��BU�;"��J�dBw�b�Lo�l,��h.�����ַ\cF���s�Y؟�eR�H=<�������;��I{I4Ս��)t�n��Xi���{���Q.��B���Ƃ�!��V�/a���Զ ��&�4���I���@ k7x'��pω��5L>��������e7=ck�6>��h�5�e�����>Og�5���j>���������Y���i"�pO�zS0y�O1U� AR����./��z�L�����t]sM��A}�p�kJEGdK}P�0K�ouF5(�ڀ����L�HPW��
s��w��V��d�ҽ���Oųk8��JR3����.h������]e��j'}t$mQ������e#`�S��G|�`��4�P�q`�"Xo�ԲU�]�q���" �V\0+-�c�ob+�W!؀4��SFSTZ{dO2?t��ŦN����Ż���;���җM(�
�ͺ�b=�k������ۤ�e96��K���K,qc�,��f�6P���ɹ�h�*����5^	��_}<�`�"%

�ܡ��+�.�b�TD�4d��a*Y��Ⱥ���5/(%��_���-���[���NnYf����*x�H���y��2P[6�՗c�(9v���`#̓F*�Aǥ��N*)!�f{{���$���[���cy򄍭��WG��.��~�c����|D��s�?Md��!r�`O~F�`9����T�9�6��;����?��ՏgLp��=�y"�k��d`��㋠�5Ƕi	���I�R��f"�J�0�+m�?���9��z��I4�u|����z�7��tȠ�P��K������r:ӳ��*:�� 4 -S!�B���Hka��~��9GoJU p5K�ûTW���6�,I݀qz���"������q���?�# @&���h��b���Xf�-M�=�X^���#��˹�@L�^� }�(him�Γ�i~�Oa�@1砗�IM�d�6/]q��X��'tߓ*��&j]�z�3,m�Ζ��N��t��i/~�d2Ab��W}DT�4�}X Zn�=�����w�nK5��B�0%���2�&�aM,�AUbQ=޾K�!=Bk��`���8�ؗ���[��h�<�!���`��tU�:S���਩�/��g�Ϫۧ������r�^hJ���0�X�0:MI�`ܳ��HNAd����pW��ܯ-�5y�Z��\�P�|��v<�w��yɭc�Gk� Q����g�'���b�#E�2GW���VT��PaxI�2���1��"�����a�㳻����K=����UH4&��@b�^~a3�Ia��S�}:��J�Q��̪,L��e?MYt�R���I��Җ�*	۶��.&E$S�<�P���*���������[DP�`r�����z�irם͇U���hQ�[L�o��׌�w<��L�����v�a���%���i�{��Q���GxV<���5Z��ajw����Ri\O|d𸹼�Ή�M���J�����Z-����q�1y��aČ|d���쌮,_�aZ���3����
Ħ�E�6s�!��>�l���qt�}`��c�y�٥�hm~��� �����:��N�p+�|�p&��0���o9�R�-�[�ie��D��f��U*���![���%Kzr�]�4�Q���ؔr�6d�;^B|�f���Gg��z�R���u�T�Ӵ3e:����!����+�"^���0�8�Y�y�S_v>-����`}�p�:@8�]�ƙC#��H�#���޾ѱZ��QwC�O�!�%{�!�X�9��3��jo6���a���ш.�X}R��9��,�}.ފ:!�$�1�j0�V���Ka
Uꎋ��
���	��J�F��0$�`��yCu��X!U��D�!����F>P��<ͩ�����n߲T&9M�U�������� ʶf��C��)a��34�)F7�݆��Qߌ!Y����F[2�PmϠ�t����ڙ3�3h��is"�s�6����6��d���
m�[�->����ћ�Ѷ��~)�s`1��]:#��D�:������t�@��B=Š���7SA�kĮ��6�8Is2���o�ᩭ�a&�#kk$!����De�y�F���hS]��C궢2�0=o�}��#:�����\�%�f�1"�c?K3����s9BWEL��)�>��}"4�����xd$o�����yVn�Jٽ�=�G+Fs���V�Ҭ��$�q�5�r]��"�h�����?.��B�	��Hٻ���[��EU��Ұ�^�Ɣ'����06_����E �Ty^�m:;O"QG�.U��k<��0w{�Fkx��=l�s�2k���@�������{d��z�;���:�,#$N}�?q@�����m�k1�Z(૟�!�Q�X]�v��M��G!�y�Raϡ�P���:7)�M%�@K���XV�d!l����y7�;��&��������I�\M�2�__N3�%&Ʀ[��(AFM�.�c��A	�-�'��}�s�e�kCwM�]τKaq#�r�OѾ�Mb�gx��>�}Z�-Y�Z��(ќU��!ӱ�&#�`hc��o(E���(�����k��ė�}�}E�Rva�+����nz�/źoQ?| tyη��$�r�R��,���ŗ���#V��N��>!^�N3��n�M8�r�F���)ϲ���`ʨ��E�EQ�}@o�c`��
��H�?f����0�?�L&���~뺐�]q���l����u���*_i��
�QXs2aa���E�oɔOT!T ���"l�"W>�Di��@L���*m���R�0rf)�{�������Z���"��!Pb �Z�Hq���yp�]-E�,N��G�2�em�f�X�t�*���6*`�µ�,G67K�?����f�ܰ�J���6���n�!�k����머<�|�=o�O��m�-9�,��f`+b�G��-����號��1����%◣F���Ė��;5<���j�-��.]⠸�ZҰ�__
A��d)�7���H�������X��t3���/.zDaW��S@�wY�ey��'�BE7>���?�[��.A��&��)/�w��D��� �9�%���5����Ѭ�9E��WK+�i�Gh@�n�D{{x��Ux���o
�۩���ܼrj�2)�C��>����[��2�Pu_W��iq��p��b��:H^3�6��*�P&�Y̨d�
iJ�Kt��ī��g��@i�%������.S	�c`�p��qO}�6iH�MgW�����>`�������͖��)v�o>��)�m�+�\<��,a<�Udڈ�,�yT���g���XH���M����T���#��Jn�-3ʍ]��_\5b���{E��RJ��'
��oNi�#3��`�/���ǵ[�U�i|�`�v�K�{s:x�M1��bw�6�!.lk�4��r������B��:��E�|0��t\u:l���g;,��NcMi�ky����9�d�Ǿ�^�z��&�h%��5�j������Scמ����pj���O%T�2;]Z�a�}���Fi�p��OM&#�Hg\R����H�����b�"�&�`���I+>�:Uô|���Q�ܶ�U>b�- p}�TpD��U=���'z-�)���X��F��-�g?�H���Y�`ؓ��j����j1F&V�)�
�a/������Dn�jqb���_�5b,,ܸ����L���jaGQa�� ��:O�Q`��]��6��!�T,�9rԜ݀�����OK�#�l��!�漷��vx��a��4��Ή�V}=1Xk�:���5�J��C���+ԣ�Q��# �qK�ٱC0���^��������L�RW[q%N���/J�#��q�J��mp�5��ԭ��~F��"8`W�����/^�Pc���O;����5��[����k �F�tx��h��XXQ�&���~h��s���%i� W%�� c&܄K+:�����wZ�������a2C�����g<�p����M�EM�Yh���Ԣ��ub�ĦϒL3�׮�ఉ�#��>�M��`wn�3�ܕB�gR��k��H�����DSft�(҃?�y)05�o�A�D���Ji4�oNꎢ�����O
/[r�j����(�h�{�H��!���P^=���g��.n��C���x���E/����b;8��`��`�$24����5�n��������7N Tٶ#-Ms��a�e{��[ ��/֗�P6�*c]����u���YhEIƐ�ߛ��'c-|פ�R���V���r����D��ԘQ�Q��u�<���Ψ��,D���ԭ����\|i�Π6Y���uB)����l�N��G���n�Z��h��"�	�?C�kJ?���ݫ�}ے�,��T�)T���8���I�B�g�-��~/5���*���:!
ܰ���%�5��[�YQ�眶�=L����(��(>䅹&�5)�2@��-�OA�%Aٳ�(g�7�}�Ϋ�͝����F�a -��B��.dMV1�U��E�dt��ގ�=p�5�5�o\�Ǆuo�@uR�F��'p�7���+O[����W�v f�W�ʋD�������IlEh��!��SY?�x�䗳��e!�����c޵4Ai�is�޽�_�*u�+�1	�}���}C0f?\��� �t#s���y�]�����t��G*س����&v���1j�"p�6k��Y咝���lGKx�R�,%�J�(���F��n⩼u+�@0����>aa���&���9v��N*�,�
��8o�;��W�u��G�f>����s�w��bޮ���?�7���
D)�̊x����gi��l���ۭl��}��a�K�vH|A�'�r�9���`�.�Vs����^��������_"�ǣ���*�[�]�|rM(�M.��XS!6܅��{2z���|]�oRn`s��GVi
��}�&�X_n}���;�@C�I��	3��a
�s/��A{H(ZP���>^�8��KߛY���Is���i3�����1��܅�;���`�wyg=1Wx	�
���Xbs��|��\���j��=�w�`�
�v�XD�7�mkD�ʩ\��Aw��,�-�Q]:$��9��BG�uYZ}B��a��pv��W�����\u	'��H�i@�nrY&� `;�{��e�; 7/
T�o3�.�M�����|N�LB��e�c�6B���,6��)�Aw��1$z��"h�R��}��={Bƣ���B�����R��d���U��:�	��Mu��~Q!�p7|����Gq�g���w�;���S�P���˩�'����;�3C�&��;3��w�6�7lS�?N�\�a��;����o4G�������/-|H5�r���O����?���Y�?t�zc�&��e�!��>Y�/xB�g�F��!VJ��c�{Sk`[

� 1#�Ⱥ��`�x���K�����Q���_Ħ���k���`kR����s�����U�؇���3���3�W���T<�'�e(��s���8��%dV�"��{�!�8M������2��#�B�F�A�Ȍ��L�*��b�]m݁��,�B��J��*�Q)����|08#GP�:$y8�2y��޻�W7���#�q�'2(M��8�7�����l__4����En��������Xg�$���6�Rn���w�5��>�ד��t��P[q����.���X'��am ȯ�������e-ZG��"�@���YC�T'�˚�h�=��
��X��Xv�j��XL�/{l�8�/��y����MPУ�|��bo���اb���&SZw�ײ@��� ��U�������M�+�Z��S:�G ���-p5(�)���=���4����ygR�׏g,-�B�θ�t�l=ˎ`~�x���u�J
�D�O�* ���:@jts&��O�,;$����-_�)�?X|_�t�M\�c^[����h
����t��y@��~��o�֤̇����Q����y��O'�Eewd�;ˢk ��7:�u�g_�?�0!>�dqH�^�:X��֟��`�j{m �R��P^L��m�|�eKYU�� |9Ɖ�NV���1E��`�&7g3� ��BI�@z�z7�Qm;�I} �Mh����m�]��F�/����9(���E����X�*�r]��Ŀ)���ڰf'yL�5c�]U�c��n]� U��(CƦ���)��@-�Q_��a�h�� ��aѐ�ް��}d����e�Hڿ������ס˻��o���g���<����/:b��0�KD��ʀ�zN��\
ѱa�;�;t�G�d������R`�W�%�{r��S�1�?���;��6���g��L��%�� q�F���ˬ���.j59����4�"@��?Kf>>���`'�o���k�{�W�mO,�mںr��;��\��%�Y����R����!�w��=�]���FPqW<�`���4�4��V�'�OR�#��7�(�6�����8��CE8�,�����oL���� �����?Q��I����H*��>�f�S��<G�jp��g�ʐ?�� wKZ� 'L�0Tl���u�[�H��"
Uo�oz�@�Q���C���2��6~�x��V6l�}��EZ���i���&�l���/��KX�b�0U�ȍ�vAmr!gU��齪���]ձP���:r �y�����ڷ�I8�'�ڃ��I�7v�w�_8��
�r`	[��nq`#����U	���׆J��@��]辸�U+&��R=?�)Xk�q��� �ژH�ɠD�l�)�K-[�Q�tG΀P�`��O���k�|5�2�N�xk��n��/b�����Ԣ�.j�� 9l%X���<�Ƹ!/=�����["8=M���v �@~�"��L���NaQZ�ǒ�����5�����9\�3�p�.Ì�������c�9��v��BO��SN���3����w!9�H�Y��[�5�7��}�p�����7�n_6=ˎ��<<�a��5?1�����Ȍ�	���y8��kڈ6�v��o?ҮF�Pqr�{�z-��Y�`�+M�8(E^�U����u/d~&�"��<�t��p^�C��CbS�oq`�k�59uY�^�S!p4Zi�1��r�.x�z�8Ӌ��4<����]�$t���0 ������g������0�F�c�V]��!M��D��^MM<�E�?[D�ah�Aa@'�x�Zav`j�&�mwUّ�6<�]V�B��
י��N�f��|��|ˆ��N뙴��kR��a�P�D Ąe۟'%ܬ<ˁ��A�L�Pdݕ�:Q�y�{a�s�tW!eN^:�,�K�+,��U��bb.�H �=��� If���ٞ'��$�J��؁u����7ւx�fU��zK���.M<ix�BƮ�Kϒ>W7����cf�1�p{�>إ��ds`bE�!	�=Ƶ��
o�ݚ[���J���à�@�ۏ|a�j5h� ��޶Z{đ99�K�gd�.-�'�HM�Z{�wW� S��&�	&�Qj �t��'i��8xY@K�Ɣ��QLQ��B�$�t+%��?�^u��۷ٹ_I;��☁�~N?�א��=�QW�R�ֺ�/)�,3��EU�/)n��k,�(�C-R&����w U�@N�Uk:pq{
[۬8�%�d�ϙ���w�8��$��A��jN�/,�4ҕ�90�
�y|*=�I�%I\'�R���(�u����3j*#��6][S@LY�ו�{"�Z֚g�E�XJ뜻�z�s�6�m�А��غ�ʋ��y�=�����_/��Hpb�'�8�Y�w�KM���nL�O��mY]���cXQYtƟ]�d���r$��9fY�=���{Rh9z�N����>��sz=���H�1����jeo8�)���Ūo����Ge����>u�91���ǜ�y��y�/S��l���E�>��;VCs޿ݗx��0�04�f/
��s^(��9Ȋ�;r,b��|@�|$���Is5pٖ8�x����W�}7����u��,�LP
n��.��1��aR�t-+�ve��x
���]�F����Kz�#���t�#&���~+6BT�`όt����7�RY7c���������u�zi�S��+;@���Xhͯ`�Z��RKv�Kٱ��?��R5�
"��W8}���iƺ齚�ֈ!�哒+�)��>��2@ =�BBn�u��n���-im`\�}�Y�a5QR~�����).dE�z�D܎�������D�*��i�O	�`��3��=v���)���a�R��:Q�@=��@tM�ϕ�iG�K-r|%�����&$����[���χ8�x}�K�'�G^IT�ԐN�&C�:z�����:&�YS�[<�[W߀�ޥ�f֝,�oW���S��7�8���r��D����TB�itcFSA8��f�j81�������>o���o�x�:Ui"t�<�b��/릢�`R�vs��ʕ��H6R#�)���	�D���ZO�@��NcD����p���#��Z��å���(<ԅ.��0���ɦ������k� � o��B��n$�|�f42�kxpa=�}FL��ko
�߿)K�剅4�3�ɛ3%HQ�в@�� ��7y@U������^ݽ�Ӧ�H��Z� � �nU'�Lr�z��o��%�T9�0a����E�MD�SG{�-���
ls�94Mؤ�/j4���>��Ys�-���Dd��%��Y�����$(��S�x�[EJ�Q�H���`6O7z��l|�H�K,�m�*_g��"X����B�~1���J��<�r�d���6�6����l��t�
o�
7xw���8`ń{�<Y�K��oG:3���mg��JBDM�K2��$0PSG��@�\�&���#�3Y�S��Y�w*�@9�w(Z��}��<yϔ�"(�_���+:a��m����Q���l����	Ǐè{���_fh�$�����{���];�E�=�qL�܌��s��G�Ps&;��B�*@��ײ�_�L�z���r5���4+0i��aI�=�)�"�h���`�\�&��=��4�KśY�)���@�1�Ҽۻ���M�K@}mO��\W�q�����iP���_�.M5�9%0H"�q�r�&��l�f��LX�%!�鸂?S�z����.�G�T��ǭ�$�}-2��v���z�h���s��(�[���z��/�m�V+%��h��	���CUc������W�Y�]0PH��H9l_�'n}���9i,'N���5�ܓXB�*�f�H~&�;�~z�P<0鬞�tl�$�� )�|hD"h4�5��MC���K֚x?�7+���H2��"#V�'H��!������.�1Y4:e�����l�!{^��NT�~jV*����YW�(q�N������LyWu"��"䦶;��ҝ�I�E��-��K�-uto���^1L[C��q� �
O7�$��A�sXG��X�㔵�ŕ����rq�_�8��Er����_�
�g��G��o'�!T��2�P�����-�c�b��لk��n��gY�`��g��sꌥ�V���鬥���A�%��T�#�}Q��@:9g�#�uevK�E
͜��m�[Tz���3�~��t����?�W�����*W1����.��F�k�[��M���z�iB�G�m��B��:�U�<'�1UCr8k�?8��D]u�e���n�5_}ܘ�7�����Y�M�[��+N�Q�����������1����}\�����oq����+�Mg��x�]�69l��,{��Q��['�y�?���A�<�Jz,m���Iz��3�u������c�(��\$e;T*S�4�;��>�׳cNk�R���R��^���k(�n5{���x�c#X����Fm��� m ����H����@L&G���*������J�f�߁���o�܊�����!ߒEi`u=FN�R�.a����tУ�oy�5�1}7M�2_8�2�@����x��
����%��&#�-#� '=�KΦ<�f��!�a����~�h���z@�g���wk+%�}e��%��Ugg�E�y�˼�67��䊜��v1p'��'d�b3�M=�5li�����0BzRJWc�//��4��e���r!����˦����Ez Eâ��L�?��v�kX��l7=�~,�1P�:\�kȾ37ܓ?�lA��� }��O!��c�u3TG����Ge�Ҕ)�lo�M�)_����z���7 *X��"�+�[R�Ō�S���:����eJ� �U5w$$��nC�bJ�;9�:4�:F�[�I�X,�l�>}Lۀ]4�ۡb����m�ێ��n���â�Fe�#�G ��Z�cЊ����/��������_�r�-a1gC�ѴԔ�-�*ǯ:嶫��kS�r~	�5s�l��K�2��V�&��r���G��b%h1B�\�Os�5l5�)-Z7ťUT�#�2 KW4�m��~)�sW�^�] j=���~~��6��٪�6��[�_|8�Mx������1tۑ>�(��+��qW }��c̜��!J�[����*`�!���b;މ��X-z;����))�>!¥���+*ND=m�d�O�~����Z�����!̆u��q~/�"��΅G��G����j����m������|A�u�яᮟ���p��±�Ѽ��D`.��®��V�C,b�����b�L���Rb��6OH�E<N-΁�Cf�%9wfdKi�Mpw$?lE>D�-�����f�RISRL*��y�=m
8��t�r�+OQ"h���׈rZ����]خ��I�Z�K�g� ��eQ}"�g	��G52o���w���^\:*	�v���NΆ��:��Z�t����#�}�b����y�Y52c3�2�o�jt�m��J9��8'3��uG�ү��bP@�\Pb�e��J�����~�ڦ��R';��Rs]�;8�o��4	-H�n>�M��(�,쬐� ��kd{�]�8���<J�����#��&���:�7CmZ�NH�B�E�O�$X&hq��w�G���n����@bCr��g��Bg)���S�����f�4�7[�>>��/�͝�����n��Mo��(��H�5���-oNt3�"g]��9��rQi���F*0G�e��M$��
��dH`�{r��Jd���K)+
��ڹX�o����K�m<.'-zw$c�#C�D��4��[`�M�N��ZϮV�~ [�Y7J���1����i�pi���Q��!� %�w��M�`[�3X��\�!*P$ű�=�4�x�K�W�xp�~��R=����o��i=`���m���1B�����m�[�d��d�M�1�K����K[��vw��@>_#��5��\O.��� UF���E��y=M~��{j�p��zj�W 3���˸<F�'��:�GP�A�A��!y�L�
�.jq��)ŏ�Yƫ����)�o�|u~Gr��@�J1X�NJ�����5e�b�����
Q�.����N,�A�Aa��0�~�s�0ں��r�ga��^��E���k���=k�B=�4���A8�B�q6T�����l�r�c�yaHL��R��0%���bǁ��FSa�wN-v@�+A�F{�0�J(�t����v�6�Ӟ�1+U}6f�y�V�uXo}�.�]@���*��±�p"�#�"�=����UnvHG�-E(z,�a~�����0��'���L-�N1������^U9�� ���W���=�Ǽr��m�Kw*o(l�p�4 �b��� �`1�@������
�6��R���$��"d�lk�����X���(ug�v����q�)T<Z�B'�(�L�1Xw�\�7K��2�(���E��u��D�9cF2YY�� SG�ؐij��|h�t0�as�*��E̕���~��S)1[�-C>z�D���$�?����?�J�)h=:���A���/�!$A�y��״KEP "N���g�8�Z��Ӄ �*$z(*��s�A30q>>�
��	"w����	:#, "�P3�ܦfZ^+��j݄UZ��6�D5ϲ�����a�uzV�h|�՗����[�ɟ@�E2��E�A�~� �SZ��K{6]��
�F(�!��T���C�*\��.�^��(�R^�,�7
�K�)N��T��O�Y�,^�v�[��m��!�M����	����d����������u�P÷��==��ɼ.�dd�����aK"��o
J��bN��)��o%+<u��/"�0%���'V9��}f.L�fk\B�G��%�>�U�Qp�~��.�v ���O�
��pxI6c������b����9�=�1�O;rwX��Y*Ul�A<M��%8���Ȕ��A]�i8�Im�6_96�
R{�֜�M1��\Z琄�k��Ѕ@ c�b��!���y:�?T��y�9��Z��K�w�qߏӥh��Q��֩�.
�mn�sY�Kp	���Z�?	������bTM�'H:�MK=�C��te�D��^D��X���{~����ђC���������oͥn����~2]�Z����������Z �a8l�xc`�����5�#a`���1s��p��~6
=.���a7��U޺��?��,�Yn��}w��˟��K'��^G��]��|�&��m4hq|���cI�� uaaC�x����LG��?t�a��'�5ZaM�R�2M����y��$�=��N-_����I_-Pg��f�͆��W�u0�x�K��k�*bh��8t�_KS^�VX�rWE��'�L]2'���\~q�(7+k.�����U_��Q�]?��4I(d]��#L��)��^wX')~��|��~" 5���μ� sG���-�90�'��6���m�%q�I��Ge)�����L:�
@ܠ_s�<t�4>`���P;Ȫ����Ә4.�<�<���\��N�*��y=/��?��rH��qoе�X+�P�JS3�<Q}��Sݚ��a1�W�:��`hk�G���6�*��x��)��p�#�`]�{Q)T�;��i�g���4�!e�욘0w�P�����Ҽ�����V���亵6AQe���F�=��y4h֚3��e�a��^Z$Tu�a�zq�4�M�J[ONE� 1=�UnŲ�s
�6�NT.�G$�l7e��u�YY��p_�/��tk�l�Qc}��@a�H�KR�_D����[}M��=U���gE��TH�6�o>[��*}�E�:�W噮G���-�
�Ƹ��i�<k�z����f�T~.����CE�i�|��Z@xT���1$~ ?���N=/��!W�Z�"�h�?N!��5��븛��_P?����ɪ!�\]����j�Be�f�"�����M�9cb/6t�2k�憘�zYE���*�*��Ц m�����el��@���� �]3����4Y���{x�a���E�?�E��9?�?K��\&��8H�����%���F�m���2�6a���/
��eN�a����ߡ�B��-a�{��hwp#�F|�������Ʃ�{�E.`��U�DA�	,��簃H���BEKRw�͟�yb7^N��>E���p�����hG����Cʩ.69�2��Z�כ�&���V���*��T�7�!٤Gܤ.=��7g�o�	IA@a�%d��f�[s���c �M��L�m�ͥ����k�/!�|�W�)ɢɠZ�1��P����Sל	��h�i�ٍ>�Z�/U�+9�&e��_�C�%�n�t��??jN
�mNظ�;�*$*A�{�����e�O+�u0���e)<W}<�mp���;��c|���y�$-�p6gJ�1�6�3竌���+��,@<2q���G�Z�q�y"�X�oӧA[?�<�r�~�f�Pƙ�w��{�ey_=�6m��'�.s����^raZ�e�ϯ�r��?�A<]�+��j��/��?)��Ė�rTK�� �q��䤫��K�5��o�9���ٱ�]cag(s��^8=��
)9L�
:Qb�`���1�o�K�"��Z��>��=���Ƒ-���6�^g�u���i
�
��2Gh/�O-�'��:�oJ��	@"�Z�P�orH�ڗ(��*d2�N�U8�^�W}5������IĮ��p"��uͯ'�"(���ص��j���D�aԮg���Ծ�H���!�?v[hn�%>��|
�ڍ�_��1z�S�/,=��Z"����-Ҵ������1`�j-��qk[P��EW®;�{��/;e�HU�fq�8M*�M�\�z�9X'Q�]$'̛�vk�M��� �?�2��9��$��l�*�wm�ػs��x *�1���dٖ��a��դC��_�=�Y��<Iٿ���%�of˲C)��v�ϔ�����Aò7攞��ep"��u�_�%H7�9�bV��>�0����ZR��z~��}�\����]:g*�XͿ�=&<�Ш,������2��4(ҥ�Q�RjilR���%��Đ�L������hf'#�P;���|�.sy8H"��{,N���~�����A�&�S�����'4��'\����p�.[8���V��T�ȭ�-I�
SQGJ�D��(�K"�t���!���P�-�)H��� �U��������Ub��z�p\����h�i�������
��q�,�u�H,�i�C�;e\[��[O�ǡ1vD��K���_�c%�gXf3E��̠���ac�&Ra������d��n��C�<�ڛ��{�|Xa�q��u�㏔��?��'U]����kY��}�is
m	��z���������j���*V �n��#��]-.b��*�y>o6)&r'���}2wMu�̴�=�_[:�}����O�9�뙏�u�2�y��'�`�9x/�NY^���	=�̌/]�	Ț��o^?:Uƀ���!W��WYc\�"n8F>7��g;S��ʣ� w�kO����~�y�O�r��G j��h${�EX��yw��UA�J������Э�0C�|z{iH~ggG�m8ӻe7��.o��vc�2�A���t�28Jn��z��
;�:�K"+~��;�w���Y$�p�(��2����u��e��H��g"���Ev�&�nʲT4���u�<߄}�+�]�\�V3q�|Cv���-Q�|��=�ꃚ�țG��\�3������4.��N[U�z���׍kMfZϵ�G��r�9�=��oX �p�Cj�fj�L������!󧐸K�ǧ�{�׭Ѩ���;��Qɺ2s�j�S��D�H�#�EϦN��e�1n��Z�A�C%�'`V������߷&OD��]N�F�}I���:�ODèjq-����ZS�|!�A�q޴ՐU ������KP����u�D5�˔oU�7S)�l)�J��G�&��ŭ���{ag��g!k5~8���$����蜤c,��L`���9f��1�/�s(����"rS�����J���b"��)v5~����|�$M$+�6��F׺�:'u���d@��K��t׎����	H�(M���a���+��v��/��LJ_w�2��PF��/�����p�<�H���k���*�+bN���Ȩ�i>�K&�a�]�|�@�K�����;�羨������༑;7N�pj���f!�<榜��E������S>�Wx�-�}�T�4�HV�1��ϑ]�L�E#�:��[zv�6�@�}4������s�_E�>-��@�.��b��ٗm�BIjJv���Щ�1n��4p/WR[W�j�:�r�����m�V�UaO�9#Me��|~j��Q��l���A��3|���3o��Y�p:����Q�N��������ȥ��,$���Qv_��E����YTiU�V�h�r��Mf�21����Q3�}�A�Gq�0dY*$�>��14��D^wypz��J�eEh���T�����p�ͺ�Z�T"U¨r'j�N��VoW��<��e����+�/?y�ST�x��7mXy噓:�tX!��	3)�=��Wx��id ����$.혠���f��Rr�n�����Z�+:�Pٵ�{v�-ń�QQ��#:(���7Dg-+�3�)��c ~X��Я�\��N������'�?�� N��2����-�/� {�'k�1�OuK��"�|�!�>��GG,�8D�g4�)���f!����+u#ۺ��R:��*eC&��q��#�n��m��9���hUW����~�����4��w�B. v�]3jb-�$���*��Lz�1��N:y?ж�L�9����
��a>�z��E���3x�ye�Z����]Xt]Hܔm��"���'v&3��E"~B��8���8ݔ�),� Y�3�<l>�y�K���.�U��G9��N�E���G@*�Yz�ع��Β4��>q=����/A�%�ԅЮ��C�H�a���Ԕ?�7��I������I�.i1~�� �`���#�
	o��cޓD���?��C�_E�睓s��p/��M��6��k�	��؃?e�+��Œ?uH��h�8��j���!r�::�U�f�
�H�!�%t�w�+��̷?�O�<�<(��1�ƴ�؀���p���Wm���)"��W�4xE< �F;��������A���S�Ⱥ��k��v�(9���B��	����	�h����W�H��LuC_�y�s�%�UqO0,*#?��u�uʸ�uVR���Ws�kjϷ0�mg'6�u&V.] lHDgS(�^#����r��tT���Jy���Bf��vc!·��,�%Fo!��G�����T`BN�d�R���u ��n"Lo[,��@��!� �,���d@�iT��Z�GuUO�{�'}��唽��L�}̸P��)D�O��*������|���&��_�2� �70���=�G(+L�*���?�ֲOML+A�B����GN"��УE"����D�'��]�b#�5��$c�<��~��u���B���������o�x��&o��_'�[�_.=P�;�e%p�BP��2�w��sԐj�����%��T)�w��W��t��@�tA��^;��/��^29�y5s�e7�#Qv�
+�V
�_����(�+���1���]_��C�3�5����"��yZP�C��u��V��$x�#h&5^#,	BEa"�ԑ�:������N]�˛ˮ��z:k�̑a�$8S�w�r�w��W�^��a��c��Š��Yo{s�����h?/x^�qm�h�l��n����ISaC�n��?=YC�>)
��_����>��sAPb��Ƿ٬���n�`�s��'ƙG��n ߃~���L p�I3�P��o�{Lo>[T�@3bz�<&��n	<l�Q��Gm~ �"%GD�w"�i͢�i��<  �;��r-,� ����
]�X��g�    YZ