#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1133053987"
MD5="49fa30ca5232154daa472e9afb1f0fec"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23828"
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
	echo Date of packaging: Sun Sep 19 00:13:10 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D���4��^��LP4�-:��Q�0�-�sҕZ`��<�G�c!Vѩ���̖H��l��$���.O�S]��L�^u�IuTXo,�#�2�=�N� �Q9F@�vMݽ�~���5@�����mU����i��4�z�u��}i�av*���G����,- �G�� 6�u��u ����1Z��Z�Dc�6�8����
,r��Y�6�xq�1��"/4��Ũ&ki��$�`�~_T�E��"\a���&��rъ�OPL>}ć#%�����K����������'��>�tZ� z�.�Q�ߝ=w[��抰@tj�f�Q�e�q�s�AS�L&Du����BZ�%E�g�Z_u�Մ<��H��|���X\s�T�`tݯޒB�ӓ���) ;��խ���C8ߠ��;�}0��-�g6駹a��Ϗ揿��T�tJ�ŰG��Ü������tb�}��^`��Xaw��8gm+u��k*�j��Q�y�|b�$r<�=~9y�`�|:�*vp�� ����^�~����,�O*����$Cut�����Fb�?n�P'H���W���b����/XT*��!I{���i
Vc� a���o��%VR-_��V	R�������hȠEG�ERS��,��s���mn�>��L��Zr�
�s�.���	����;�9���N��v�u�w;�� a&�7{ۃ�J��2N�5��X�2�.¡�{�ZI\Rc�����3$uL��$���5!69y�uQ��s�:z�����T,�#�Ӭ�K��o��$L���5%	��6f��'�.	����[��.�z����e! Ρn����_m��i�Wk�4A�/��9��yl�EiG��/�0�S��ǒ,愛��>u��~�MqR��T��|�F���n�8+^**�-29�ej�L�����0�ey$�E�U���f�A[]/m������a�4*�:�ج� �fO�^�p�KD<E,�]~�گ�IJ��v4=Fw��؆�6����KhÚ�=�91�wK˝2�Y	(%��R��!��L'�{�'�F�<�T�u��1�v��\6����Zq/�te4i8;=��+6;��N,�Y�|���3�	�+�[?+����:��D�i�P�p��_q��}�5�
�5����lo�����U^u���47�c91>�L��3*���I�p�[�#F)�iJBnr�E�@g5��F�S+�;C{�L}����0
(�#I�."�3�<Ǟ+zY�B�ʂ���t@\c�-�D0�t`o�'��J U�D����g=c��[ �5�:����	�B!5q��uL�>��lC�P��A�������P}�ֿ�W \l���1�^]o>�p��꧂m��SF��U'��U��A�ԛR��O1�T�3R2����B��%�z�a|?���O2�X|�g����h\�E���ƻ��j��M��d�@6�@t�؛�kqq���Ff�[<��HB�g�bI���̃~e^���'�� 
�`Wz��o�Pzြ?�:��O�3tA���y�� D�r?�X�т��Ms�ތM��"[-z��$�!� b���dg�$�_�{aN��1<�l�G;�h(_���CEL$z�K�at�<:�����;ϝ�^�}��Y>NQ2c|��h\�&ҽ)�O�2�PIw梇.�-�Q��i�Y�����Az����Ef��7���~ѴU�P��q�5�$�Du�!8�Tf#�E-�IC��q���;zq?*PLTX�r���ï�s
f�7[���L?cm�w�޶}���a�V�}Y�Uy��\�2Y�:��GX�I4�Z�1ꆨ���F��g�A�E��#�n��+�/��!��6������,R�ꉏ,ب�K���1o�4`?8*��R����l�C��;sm�7r���oO��x����ۣKt2�Y('��pICJ5p�L��|Y@X�66�KI��_�7a�����`LRb�ۼ��H�=HSA�}�)`��_!m���]��j�=��m�	S����p�n����~M�	7��	��3_̳=�gـ�����$I�1Nt1Ԉ���q4��A�_}F����dd�jߠ����{eձpL�6HRS��,�.��`�ʍ���@�����a���P�"|	�P��:~����τH�������GUǨ��k�C p	vʭ�[w`�|��D�ޥk�R��<O=]��i�S��i��+PX�K��z	����⶞:���y�'}�'�i���I*}$���1|e����Q�=�2�A���JS�,���(��6I���0�d��$��#�NJ�R7e��s�7p�Ef�5ۉ����'�����`M3��e4
�t��� �ax��H��{I�Ƥ�1d0��!����d.�	�q�y3ƢɎ�kM?��,D��W���B��j�
0��(ьJ8W�0�|�T'<E��2D,����;�!�Վsh٢R�:H��c2��f=
���L̕��d0�v���>6|E_NX�?�:��T�Q\�<el��5U���n��h{,!��8����g���B�� ��P^(��T+������	�XP��^�؋�67��,>"��f|7�c���!g_�6k��%�+mR�ȅ��YC/�i:�2�Y`o�ϰ���gkj'��]��޸nr��+xt����n���|�b�@TT+���r�ￊ�j�^�6�;�Q�1��C+�,s�/�м2��o��T�gD��󡡿�U&ղ���7��G���9(��L4�(�$V�0�DOR����KI~�᤼-X��o=�#1�T3w�u�f7L����ux�֜8d�J�&c�e��@�/
�����xI��5�X�k�i��g�����%���<b22ہ�K��Z������V�+P�ѱ�ލ�K幣����2������y
E�w\N���8?�{h��<�d���*RF.#��8�NU���-�K�pi߆;������r�a��T�^JG�l�$>���`�2�E�t� [��O�wBN5���
�Y*RP�NOS���s��*�,����S��5��JY#yV�P��Io��i��2��������"� �������F݀���yI.o��=)�w;]��jM͐H�*������H��&�����I���)�-S��D����.�MӃ�R�mt��޵�Nlm�S]��	b0-��6-Ǟ&�����b���NA�RY�Xj�\R���#-�!Ƀ!*�����s�<�#�0��TW����X��ZǺ)Ef-l�D����$d꯹��I%�s����.Ƿ���'d{�'h��*�C�YB���)����Iѓ�:Ǥ�'ȟ|FX����h���l5�Ġ���n+xr&� ���U�)� O��Ϻa%C-;�Pa�����J�����0��� ���~��
��s�|w�{��m�̝���MC�~w�F=��e��n^+���0�`�NOi�Y��9~��܄���D�"����3W���K~Zm^������x�9��xPf��y���)�UT#>�����$Ո�H�0u�[oymp��7��q3&�I@����
I�ˮj;$ل�2�P������,t��t��e^ta��9$B��;���O��+�eb��6V5�o���� 
�c�4B5���(���
�q��UlC?E��ݠ�y�tڏБ�vo���d|e-q���m	����ԏ���gt ��+�d~N�NB�b�҉��بۮ�&:)���m�p&~����w�6��I��Y����u+�I,�p�T�����o���fh��S��r�%+�{�ش0�<ɗ�+�no�y��\%Ej�.=�|�����w�
, /�3��-��ijbhe5�Rw�z)�u��g����3MN�;�[y��m�$�_&��-w����j�<Ǯ�mSҏ˦:��� ���U��N�|�֚pG)�@yb�����tf���@ɳ�f��F��o�m���?K�ҹ�M��q,���3-��|̪`�+U&P�Ԧ�2�r��r��I5��pa�F�(Fo�նܣK�d�z�â0#�%���:��(�-a��$#H���n������GW`�ʴ�HH��4�����p@�������ly� �L���y�E�C��:�H?�2lO������ebe}<���:���PSV���H��A!�l~vb��ixQ! �OZa�F�ii~Bw<�1�T���P����-�=2�ٜ\���.�h+�y�m<�ۂ�@T����WPA��[{��v�f'�Ŕ��EX�hy����A�v>��Ք��L��4�2��V���d9�eI� ��6��i�wa1Z3�Ӛ�+��YV��'�qd =�Vu��nsW6�YŔ[���p�,~\6	H���bOqq�ofYh�b�f&c_�V<[�@��	�f(����Y���c7T׸X�l�]_6�YL.�k�a��^1X���#���i�$��������6�J��Õns�_(ŕ`�^�z�3@�����'1�!���� "��y��I�۽Vh�� ]:�87*��V��u��k᪄K�_%�;�A���#1�٬����#����tfB��7�aW�Œ d�D�>�Rai����OԾ�e�
���q8���{����������(L�2���T� ^����r�$g]ix�&he=U5�̔����tkJ)N�.@��P�R����C��0�˯ala��Ma�Fͳ��8ћx�&���cy\��}<�����,��`j��s��mĶ%��!��l�a��^;��"�Pfè�ҁMh9��fg�0c��Ŗp�(�#�.��e�ϵ./o�p���oE�:�3^��u���bJd�c�*����UV�� ���U���<⑪c�9*��sE\�@����+	��D�2Jd�G1�LM�nj��	I���m����M�G7��rGO�J��k��]��=}O{ůŜ�1am� )㔦~�(Jp���m����h�w�3��9�`��ܽ��= Dp�C�<t�cX�D�h����K㾌�E�e�߷�߲sK�(����$��o0�,F�V'u5��jEs�K�@�j�q�|0���5�a�fr�g@�(�D[,p��Y>t�Py~V�k1;�Tm/�E��)����ę�%2�u�Fg�0Ȧ�L��Ů�l~�����Ly�9i����Lz����|;:�:^h�����g�Q�Į`y&���ɺ̹�U��p����b�mjF��?�q��ɴҦ��-���{K�b�U��F?�W�tWߓg]{�R���K���a��S{dH�A&$����Y�o�,m����t�����D��b)��jk�K,�\�2���y۳o�u}uH���W4�h��6��l�A[UOZBԲ1���|�nI���P����11�k͋��ş��C则�z�r�`R����Nӿ�����
���K�ܽ�:y4*72��O�d>�A
X� ��z�����{�w/�}(���.	}�冼u(��y��>�|g���&�(�k�?�D���geՀ�	^v�3/l{:�(%�KO��\{j.��/o�Hͫ��QNΚ"�2�NlhcĠ��F�ȷ��,l�D}n��R��G��v���ݛ�H�B�ħGNW�2qlk�}|x�G	(������T��'E�����(W��e��P�l�G�<95,��M!©���D�X��y�@��x��M��G�q���gp O�hh��+�e��ݯ��4.�~�� A���0��Av��a���
!dW,aPi��9�H6o�|��}���z��oU�:���e:��U���2�#FY��u�!<\i�)��񙰐?��o�qT�Е�R1l����R�&�����N�J����ɹL���^(��́9�E�������Y{��aP�'S��=��:x�j/zdI��F��\�BmGH���7��/6�0��,]�݆����Q�+B����*v`��If����,�3�Iϣ�؜�~�r��@����=�� ��g�c��U���@u^L� �Gq=14�7)g�~�͐�"vF�rK�+{ع�qfh�3N�S����C��~s��֙����+[��bbY9<Î�%�oZx�艥�E���ˑ�K�K_�p���=3.kx��Yv��$�8'��H�ݑ�K��.ժ����b�%-�{�M��T�9�D��4�|-L��T�d>��
��ڲn>�O���ć��kW��_E��I
\�u�7���d�)�n�~*����O�Z�#G���:c�4�H�܇i�6�$�9�������Cδ��6�b��/f���5�)Ϡ#*��%u!�r�]��?����f����	f^���k����Gvf$�0���G]67>}�z�y��Yx��?��c�2"r��X�6��wI�؇�h4r*���m�/䉤���9�^b�bfSd���*�WA��Y�?�T�Kͨ��Qg���]�ӅZ����LK��ȫ���$�Qg�6^�oHZxD���5䪶�����=V�YU������EC�9��ͶW�x�b;�%���|R���S%ܱ�p��K��t)���e�eL��D�P+Q@�e
��GQI�v��ql榑baE!=C�z6�2�Uw-���EQ�EnY�c2C��_�1F<���7o5�*�j�d�)u�b^.�»ۃ��p-?(�iqRG2�����F"�=��s���E��w[�s����8��;%X>hK����#���Ԇ����8K�"Gv�ˎ�z�b�+�t�>[��\����oeB������uΦ�*�u�l���g����\�^e�L珘� B9kǙ�����}������)��h(s��NT�-���Ci�D�DI¢?��!�E�;K@A��Il7p�0��S��X`fG
<��q�����LYvpD�I�"̂�~�v�:ѡ�r�S�$3���|<��YbV�ﴍ����\3��:ot���׉��H	:;S���9��Z��Yu���#�q�����&��;�v�?����Y�G=����?��fJOq8��Cu��NU�3��P��k��e�By&I���?��N&�`ʣ����6����IΩY�<�H�0�q�z��Ζ>�T׳/� �n"�|1f�J<|q*���{!D��)�u{����>���%ET	^�+e��n��ڊ��?��W޲� ����;S�"�-L�O�M�X�>�=yP��qU�|�_�?�9�X��Ȃ�c��)���Ow�7h$�A�ϢĴ�,�s̱5�AT�%k�1��������������nw)l�Ϡ� 	xg\�l!nn"v+�Q��"h���Z���T꘿+ꠢڝ�2�.��J��u�d�!��+�_5���j��S����l�!	���9w�b�\i<��x��}�L*��-�����<�jP��0J�'L`/&y�%H�I���t�g(��,�D"=��P�I�A^ԗY���i�ԏ�� 9����I,��B�	k�Z�I�����TR�`#
��LY����8s�>b���B��F����Qc4B���V�,�=��s:�E�1р�t�L=�X]j�=̩?6�&�R�c���J���y�gKR�6�+��%�F))�ڋ��S��VU1SU�[�m%�[ `�a�@�X�c���S�|�_��F��ObI<�0
�a�(�%�N�L�i�
1=ë�>N� �D^M��^��t��1�D�$ �t�-j��Fa���m{�֨���g����W�뫂)���(vb�i+��ݲ����6ЯH5��ZB�c���w(�3�X+*�j��Ն�E���ʶ��;y''�����A�5F~�/|Ic�#r��H����uy9_�$ c�cJ7�~� h���oy���tPv��e�m���`�^@����
)W��5�ȵY������&x0[޸��L�hj��Tq.(�%	�d,�����Ҹ�;��S=���\�Z+\.���s�o��~�uW�� ������n�/�f`='bU�f�nE���+�k�4bC�i/+��O���]¸[ߐ��vK 1�jd��ι�-����`�q����xm��
r�@����h<�QRe��~���uv�����7��}�G��������ؗ��}I�X�����ҲƇ��-�}��L?��͊� �gYO����(B�j��쨘�~Ox��V���CĊ�
I`]�&���&$�F�G!�EL(A�"[:��l+��/�	����FpXF����Nk�56迳�=��49I򶛱����[Uv4G��.�Rk�?�k�;��C�T֚9捑�)�csL����c]1SY��F�`�E�Zr-J{�9�#�#��L ���P�W�g9�m��BN�^��*�	��K��Ii��7���I�|*<L'S�з�_��<"T���Y���+`A�&D�-<X��̹��>��*�(�J�:���6z,]�M��	/g����vY�Ő�zZ�[\+��2	>]�$������Rۋ�����tu_�[$��y+���O��q�"l#v-� ��h�]aX��*G�阂���؅¢r�ir~59��t��a�S��Q�(`�!�R��[�е��,@D?[bݞ7,�)��lj�/����p�\V�m�oϓN�Xܰ���3d�f1����.:%!����j�x�l���8,@ٝ���(�6�z��E��E����+V��jD{y$V�*�@��3�+���G�KZ׍�K�� :qnm�|rSN�O�|B�.dkp�
�U���-��p�+{j]������P��b���C����?�H�Y����?tG�X~\V�f�\����xR�����Y{ʶ ��z�N4]d� ��uQ��%�v�P�]�1E@C�����\�3)VVS�	��?|~PD������ිU�7� pC�l���\l?�F�:��`o�N�2z#=���ɝN}��-�uU��%,`1d���4�w>�? ��0��D4Ƀ��,��g�-�i�!e9_H��l:�K����W?�[�OW��3������!.
�գ%j���0f����(�n[9��(��v�Z`�#b�U���E�C���!�7WKH����q��D������bƧҖ�'����_���t'���qu "����M�̩]��QX�n]@��U��9��aش��J�RH{�xG$C�NK�}G�X�W'�c��N�V���?͘�O4��y�"�S�-�������%�yP�*>��� E�������Oam�Bz+:�����-��'�A7�w���ά�=�})#%nbN�_A5&������*��Y\I;*fI�F\�(�&��A�v���!M�kW���#m�c��{��$�8�����m��W�{%��G.,�[3
����0��x���Ny��䈏�h����;�249MB���l�5�J@y�7!�쁯@D!��Q�X����=����SB-3�~��N���� B���6�&�1�	�K� qq\����	��I�ܾܯU�
�Z��Sc�[�[��*YA���:�֌�A�B4���$�Ў��dl.I4�~4�%"s�oZP��:�4�x5�;GxXFd%�+�v�"�_����>(��hН��z*�)�%�ҥ�~y�EL��9�m���~*��>Y?�",��*Wic���O�ߏ�?1M���y\u �5��f�L�����SP�=���]QhY���r7+G~{e��i�����l���}������7��"��.4I.���j#��JIp;D)�ַ����w�9�Mb�er9R����J�ؔ�}΄:��d����(�ė��CZ�.�4��b^�;��s��j�5���s{�4K�[;����*�,��+�K䌇c�[���:�� YS�߸h�xN�F�i���I��J.���wˑt&V���J��e?���6o�>�1aU�kp�̈��9Q���"W�i�K�C���p��
҄��<���EQ��|*"�2��0}������\�@���s�Bp8���h3�T��������s�I��/f��s����S�y�G�����5@G��;��j�����Z�G?O>�	iPOqBv��z�&����ø^ӕ�8\��,h�'���S6��&߈�+PT�d��P��z�^1��<�������c�&jPL�c�nԡG�9�A������l��|W�����%������C��}�/����}w��ry��Wpi"{�\|�ˑiV��2dQ��Q�� ;�'�`�l��o��y@	�),R�\J��I��i������	ou�A_sTC�r*��Y(��%%��
��`+��%�]hcc!��^� &��R��6�țPL�.����7�w7Eޑ��_�?���>P�����(|�<�B���7M^c8���wÝ�ۊ%�-��|�7� ��,a��3jVX@��3��5�^Ѥ�Lw��A xv>֐dt��ͷl#ed&r1��[�[mR�|M���E������:��Eo����lA�w�	#$}�z�#�l�qrrj�ū���*�ɔ4��ÊR#��v +I`_��������=���8V����u�xn�p`FC.�# y�@�
�v3�Tm����͒�Lwg�pM�w���d�R�^^.�&ƙ�*�I����*q~O�[ ܄h5�31����<U�#�ea��Z�a^�6�J"�:4{6��|��CG7���%��?�҃�(+W�_S�����+Ǟ����X˚Ѷ{*�տ�#d���`At�5WB�w(�ʜc��+'K+�i3a������J�A`wT&��f?5����߶�>]MaK�!n`��,z{L��
�i����ܬ�3�U{tR�&0����&]#���Tm����Nh�鳉w���-	bh=��#(I.����=+Z��FL��穃]Pq�E�=�3�h��L,l��7�du�����d�jK���8B��=��itW�Ŷ$d�H3h����&����L��z ��Z�M���Ԫ�(��k1}��X~�Ӑ\��M%�603v
�������n�O�:��q���x)���	J��H�r��*��x�Sh���V�K1��LM#>�U����&H��H�v�B���2����D��F*���G��/a���0��$������o=͡���ZG2y���]p�RB��4ky�]��2yz��[l:��8	�z�ی˸�؊����0��Џki����n���(o�N�-S\�f��A��8�g�|�Gʤ|s)u���B���ǝ��qh.>Á���@�*��7f�?��H�������'0p�_�HE������3��g����z�|��sw:z�l�sL���-�g��X.�4�Tr��[�SA݂����/��K��*��O�_��<|��K����x��eڇ��,J�O�#�g,�7~CʿӲ�h'
��D��Āͷ��$�P�~ ��IO�YCN��$�ۼWU�W�~ &l���)�-�Y���:��,RT���m_'ѫ=\� ؟2~��3���e]L�?���>�k��M�:������t��
�cX��M\�f�v���V)+���vx����-�&9h���&
3�j;� �v��qpuZ�!��}x!����?�$��SWL���/�T��!�p'�kB����v�����G�)��\��}��������i?�e8Uf�7qx.�|j���Ԉ��&���`�u5څ�F.�UcD-����8��m���i|60�;�M֭fC��WΛ��!�c�E8�D�<2P�if	��tEkb]*��8�n>���{&��C������lkϗx�7{FoVL��e��}���*�Iq��j��b�'^��6}��n��k f!�������o�A���U���D�I�q	��d��YF1�b�=g&�������*�"U���^l����}����@;:6�W�Z��"k��s[&	){�@V9n)p]��uUvV�m��uO/��N�[��s�?�b��y�<xmv�`r/� �3�d�t#0j�d�~�����)�����0Y�j6qLZX+��	h����2N��wʢ�0��3���Y�23��*���v �!<]Zȓ�8�T�0����%Sl9Lj�E��:��.�b9CJDڼ�+��vs��ol1<�v�ػ�p)ƨj�V�mY��@�-���DŊuF�R(�q��D�p�
�	B��M��$�[���N_��;�G�ĤBf�H$E[~JdAy$a@�:�t���z�`v�0p��^���\S˪�J�Ee��v�h�2�'�~r7N[���/^��/g�s~ӝVFmG]ކ����Ǯ��P�lz��7�b#j��!y1A��9�T�og2N�Jy���?F�-L�Rm.�L���^s�%��RեI[q�Z��V0�^�KyuX�O�b���> Ç�)g���GG�c;�<�U�|�+���g�VXZ��,W�R�e)*��A�Se�k�΍Nl���"g~Q����bqr���;^x�@�5 �2��}q��#s~�>PH14�X�ؐ�-��x���5�O*L,��#�q��ϑM���!0�_>׭��]RQ�����3��.~���Dt��%9��Kx!JK��?߽�ش4}m�I�(G�6��h��"��2�������������Vϖ:d�L(<je4��(���5Ϲ�ӯ$ihCm�n����������s
���j�u�^�7��݀ߓ sXVY	ui�}4�n9�ݔ�����I�iL�f�n`��\�4\_���0�%'	���jX���ǹV;��w��b�f�{0G	0pU�I�~}���>��4�{�����^�R*P�Ϙ��h$\C�?�C��๊�v��EýC���bY�=�n&U3����K���"C��$5�f$��������G��c��i�~ =da��nf�0���A�����$?� h׸-����AՌ�:�z[c4 s�����\��,$V�=8�c,x�Q)��U��u�E�N˸?��xU���������B3���׏�7���%�1mD�0ra�~P��aǗ����5�
�I�Y�IF�W޼�_�0hE��]z`:A�=�1��~�%�gY_�}��f��z����g*�%�0I�dd��ѣ�,�M���2}ưF�lN#��!*�H�Q+�5���S���v��gC�O��B;r��s-=/�p�l���O�T!P�Q �,[�S3�pB�W�����8n~�~>�H@��v���xỸ�%�%�K��HA��O�wƢ��-F�b踙����j.�z�,�+�^�T4�I���4�@8-# �Ӕ�y'��H��Cdџ
�$ղ:��0�@�T�nx� 2;�w������Z��]yA�b�+Ns����q�Q�O����@1���֞���Ō̞��ў���� �n���QC��j�w8���$���n�C͢���N��/�4f�s8��~Hh|嗷�WZ��Μ�:�7�d�� �`J;H�>�@�Y�䕈[";/�S17�B�
w4q�v���o�U�K�~UE6؇��	B�j��7[�N�k���Z]h<�8��Eо��;���_Fb�;��8Ƙ ݝ;	�A��yX��;ba[Ѵ��(���ԓ����xr0�e��EA��"�c���X4H�Tm�����{~wK��P;�vz�OOdnm'��-�O�/v���=!��^����Q�x����#�sqE���C���-f����!�kb�揜u��Bw)����Ҳ�T����d*Éc��\e/|l��)y�6{sZ��2ڙ�tѦ���+���u
!(�����֑�����c�S�eLH�_�X_�HO

�NM=�����MqA ����c��!,���-M�5I��Ɋ0GL�o�d�/�K�t|U)	`����(y�zo���!�����ps��$d��v��P52TLwUM�;�	��|���0��B�lx)q��s��H�0D�q!(�I������u%(ɀb�Ӆ���p���	�w+�����=�%)�4R�����︈�s�Z�^<�%��_�o���ښց��-2�Y��K�v���Mgf�Vi�3[�����~DS�Ĺ��}!S!� ����%�4����c�A��p�rz����.�MY�\���N&�Y��~c�oڟ�Pbf��4@���b���XGal����4�mY4���������Z8���o�j�]���^��/��8��K|��v�U H�%��u9��Y�!���)kj�y�P�@�i���?���>�yN���Ef��8����x���ӂ��ُ��d�i��+ȝV��B��Dm��?a���O�E��z	�#���Q�03ľ���ixT���%�	@�>P�.��_m�@E���5�D�J�OM�)��g�&sDԢ�'Zk�E�5ܿ��t��oCN��9c�Han���Dw��q��x��K�,i��:�>�P���\Ώa��< dۇe�&8PB��$3�D�`&�U��ޛɏ���/��P�����T������D5����l��z�ĉ�BTf4fŌ�T���Yd�|�f	)�Ɉ�_�!P�ZD�5Y)�$]����D�#�&�k��UI�0F�3S�l��-�,�#�SR��0E���8���*����k�i���>���g4{Y�Դ�����m��	������`�{e����!L��G�y� D�p+<����SM��A��U�]Zk<_�&-���t�z���r�Ɠ[�۬��i���U��i�ϟ�|���"Mp'd`�ca��(v)��ly�S�5$�>kD~x���Y�TH���1亖�������	��Y"@��Sf�S�9��.�L�#Ṝ�OG��ϝA㬎�<�e���M�h7G����R��s�| �*!�$^R�]>�:��e���?�k��8���;὚A$��A�[9�7闘�a�J�ʖv^"*�ࠁ!C)�0�w@#���U�1}X�v���E�7�?��o�m(2����v7��\>��!��YNi����0��G���9+>2�O�����B��.E�e��A1��L&Ilb-�bDs 1�/�t$r�xA(1S�B�S���N>��èQb
��`�P��`Bm�Ç_N ���٩&C`h���))9z�"��t�Ո�HR�
�/��ʅ1FxF�&+LȅTT�Ի[��|����<i%��q��n��W��B%���HC'��X�@R_�<�Т0���I���v�P�����\��^a�A�z$���?*�������eNf4�ה��=��N���*�uU�#���
&�k�@�z��\��$�0A)�E��D�BW!�g7]0b��gj���_: ���[�CE��o�x��C��a���"�#+� 52����\����n|5����/�Z�GFj,mX6tM-��짶G�9��<H�%!
c�P��P�8�Jˌ�,���ܘlV�?¤V7fPk�����M`N�8e���n0�g9�� ����0C�=���!��
2��|ҥ`$Λ˄����hj�]�"��O��p�g�@(1�ÂH�iyx�>R��{׽7A��T�F�N� �v���Mj'�LH�O�Ln��Q$5{ǂT�Q�����c���\��J�Q�@�t_|���i��@|{�5Ҁ���m+t�	6`�#�tv����%���c{ܗZ�%�MZ)ScR݊g��'�����P�����-z�����	�3����AG�=��z=} 83~��Fn^�3�����<�cd��>RAR.U���!����Ƌ�d1#0Sp44�2�s�~��mx�d�Tb���ϠzRoiGfn��Ւ��#�*��|�����H��LF���\E�(��rQ2.�ϕ(��RW�su�Eː��N��$��,�'��/m�>�ogwyL�|j<�}�Zʻg*��ؚ�!L�@���w�ZL^kWx��1\:�B�R�g*�f������ǫ�����Q�KG�d4�#R{b~V࠽24y�P����>�N;l����4��iJXr�jU܁)!�@�z� ��M��i�������z��n�5@P$c|�%�5}��讌����|\�ɿڔ��8���D������(���䒓�<n,�*���! �3hy�/�9|����mœ����r�Vd>�:�e�7��Ĺ��S���2<^����wW���y�I�w� �Y�Cd��k���{�>��e��=Y+����=�c��=�F��4<��]�r���_��6����bu9"��O���ߪ���z㶰��|�m(��|���)+ک�1��	�Q8$�s��R��]���1(s��Y�_k߬f~w-���o�̆C2��"x�����g0�'��[��m���VZV�
C��5�v����4��򢍼~�-�)����� [v�P� � o��$�6��ʀ��y(�M1������6��d���Y�D�q�Q�eO�H�<[8�-������s����^�?�6 j�J����S`?a�.⼪�ceZ�Nmg�N�t���dG�,�-"B��a��Z�I�� .�=�߬���|���=樔�0r P��͹i�sH���,=�1�L��Li�BTp���+�7�b�%�:5-i�m��k��
�yu�#��Q	o�����SL�eAB�R�Z�kG��J�ZX�x���aY؅�1�/�� ��ɻ�J���_ ��4�3�ab;k�ܺ�)��B�֑�IM-�u9B��*������q���ﵨ-o��ea	�EN�K^g�Jk+2.�����-��#HJ��;�ӓ2�3�OG���u^��P��ݓ!����LOL��4W>�&D��>1?����>e͌�a�1�$�$�z��/�?�]�<����u�7/����$D�3�<�g�&��0�p�1uAさX��8���4Л� �1�;u�a`�۸k{�y�H"��26q��1��3��񭐻oj�F�J9v��
py�Q����@wa���Է���al(3X�� ��j�?`����4}OQ+g�k��K�R��6����߰/(+���E����D�*�����"(�#�n*���E�����p�l�K١�D�����"�T��A�Ϡ�%�C7갞6
&�C<�*��+��Vۭv�z�@����GiGP�,E���'��7���"�}��s�R��e�1����^��Ӂ-��hO'*��9a0"m����!M�iTv������.���?Aq�ԏ����#=�3�&���
b�s_f&:�--_o���l��#B���a���k������nC0i/9�֪�v��]�t/����نȴ��&�|FzY(�C
�,-C��ʸ��c�G�}�7�� G��Z5H1���j���d����|#d>w���U�;ڽ1�,*�vC:S�F��Ә�Lh�2���|l�_ƺ��NF��3����7�&a#��k�e��,x������F�hƬBx2�������}�0Jlv2�J-Wo��O���e`3^���>[�B��3�wj�i�}��I����	�)Y�U���-�����X�^epd����B"ʹ�24�'��%�p��zhn�,4��&R�c��\�[\�����^��MP�,h�^`�T�Y�ވ�`�*�,�_:��W�r`��\|���� Vb�/�=�qϋ��ܿOV7pͲ���4�Y�F7׻�l��!� �qr��x���!�	,k"���]�ǔlj���^V�=HCܤ��}	�i�y�R�*|/3�>��	���F	?0Lh;f���,ʛ׮c5/�v�J���q[���� �>��s��x��8N�J��)���ԋlI��2f���m�6W-�LyL����v�I2�'_,�bжY���Q�{V�럯<�Q��c����Z��;�zBy����X9�x����ڼ� ��Ɩ�׏�ZF�G��R�ϛ��ɛ��=��v�I���Y&I�Z##��c19��PGϯ��q�9��*L��q��n�L�=bsA=�M�"U-�%������uj������: �G�E1�B��8�����f��_}�u�&oX�H�T#���&_z.�v��RRWTuN��+w7�۠��cf����!}{ׁ�bO9/�� D��M�<��T��R�Kz݋=TZd8(����5���@�fB4�J�����M��{YYŌ�Ϩ�}�ʵ��'�Tm|x��R�xN��/�"�T J�?J��g��{gչ�ј� ��@���hG>Ŕ[�
*+w���}vI�I~{4�V��h�K L2�uQ��<�<O��>);_g�b���-'9�pUJ�/�j����nO��6�W�B�sd6\�������km�=i�����2
r�a���m\2��V���_;��� {4U*��6����*�&�����98�"��a�Sh�w��T<]p��u�&�4.�n�~�*�yZ����B��L��p��C-T���g븏��jqM#�F['�k�/�H�,�g����is����b�-�Fӊ� �x�k�;�|)3_����c�,+��Μ�[R��P��K������Z�b�TR�2H�B�M|X�ū�()e��eOQ�QU����d8��_��Y��"r�i��=+�n�T�/��#��Jj=��!�0�nƪO�ϏP/��εl��v�[��|����V��*Y�=��0\VoƓC�U�a�@\�!^�y"�,(f�hU���"R�4����|�8��*\P�H�/���YLU���.�}�g19����#�	��-�y����&��� q�$��QHlͻ�Oǎ?��Tkb��1�	��
ʍ͢rv�Uk=ų��b���l~��j�=%�S�1�LW1#��(V2 U�a���ه�FF�����I�����?H��?����nOVc��;�1�����.E1��󿄜�p׏$��w�[��yb�h�z�"7����C��B�b��J�c�h'{��Ur�q��f����R#A��S�6�F�uPY���fi�)���<�%�m9��`C��y��jY����N����/>ʝ�a����b�=��ϗ��)�'�ً�&�"}f䯙]��~Q�����_��y�(��q����j�c�έ�M���!��Uβt�t�i��WYC�AxE��:�x}$�"����JI��^G�����=5v�6��ʘ���؈1�miPh���5: ��]�4����E�8��7yB'���b��	���dA�54z��\�<u�!�w�2nh�s��y����G ��ȯ �+��?KM�J���9ɖ_~�dp�O��+G�������0+���^��r�>���1��xz��A�������+(ăB,��*�s���](�m	6�?U��I'��<��S�Զ��T� ��	o��y��Y��!<8�����}��
�y�� �*���D�s�\����e�O�9y���Ym��1�,�_Tp3弪�4��Tq�|e�}�<Ӣ!�49���|?lJ���}�o���id�����LO˲�f�o�V��?��*����P3�{?ϑ��L�*�#��؁��1��>�<�1��U��amƶ9�{oX��Β�������B3�\�!X$�o��J�Gb�H3k�y!��zO��F�������	��؟DoMC~y�ڴfw9�ك9?��h��uj�s����<{/T�u�j@�4OJ��yMQ$FK)�������j��O��x��s��]���ԙ��3?��t�n��� ��hE���xn�4N
O��4�h�7a$[�B58�T���ִ��1�!��|s�:,`0b�ݏu�I
�z#C~�	cz���D3A�uC։D�������^����6�e�$�!��G8(��z�y�������f������`�S������uf�C9
K~>8\0F� `s�!����Sm�u#���a3jM/���
,�-m��ݳ����;��W�M�9�"�쀁�x�Q.R�О	�hX?�O�.,[��tI���)A�7�G��q�j��R� ���}lw�����es.���I1M0���\�6�At�I�!lMv�!����[��"ͽֈ�������#z���BA�1�\U���5�.��|�7�0)�pZoB�=������"$A3���'��yƪN�@{�bg��������`*01���8����,.~�.�o��M��fU/�5������{2������@�ԈH����tT�nIވ�G�!!����E_�%)��e�Y�y���8D��D��?_<5����G����sSi����{�� ��y ��e�|��Xn��a�=��N��(�e�?�f�������j���a1����N�Y@�U�������8��&w����6e����3�]�n��zn@@ �.�x��hj��%9�a�4@d���1��wѦ�o���eW�s@{�'L����T@F�?I��t�`v~MЭ4���7_�c'BQ@�4a�Ҟ��$�.��2^� �>�s^�/�W�f�f����0���+�۱�+LK���1V�[��ց��8�_(���FCvs�����mhl04[�8s�^���B�/[2�^�K5��	��!5���Z�n�C��k�@��������̲-?�ۺPP�eםޥuM�'�4[�5R�.�&��}��@�2�Ѓ�6��t �M}�6%`LT;3��	�i4���d`�w4�E��۵�<�1_
 !]סka���ر���� �E��
��i�a^��30kT{w3�VNq*	�fKV	�H��*$���S�~P�)R^G���-��^�l}��Mӎ��#�ԛ��=[b꒗�0�#�
8�Z3}����0�WFb:��2���3/��fJ���c=5�P?���w!�+� \=2f���Mri�*�T��������ʹ��������V�m$�
���	A�NU�`k<�'�>go�j(�)�lĲ����ٖ�J�LD"�������7�rK~	á�̵z�uM�~ʔe��I1�ƚ��kG��[�(V�e�7*9���' L���l��?iH�f��v9�8���nK��a�L��*���8.�r3t��b27�(@�p�ŘX�J"B��V����6��m��(���t�c'1*DDf�(!�[�.vo�u�2Jm�b�Ǧ��}��䷳�@Ι��Ń>W��C��`C�W�r���C��t8��`&�ʭ.�}�A��N0��{����Cw~��<�~o�8�OyL��4�s^z��!͒�Fm�f��*��N��ڱ�kM����z��������n�Ha�@_��w��1�����RՌnl'��r�|�Bx3�rz�e�� ��<�O��4�=�xGT�_��U�1>f���l��P
��Zl'�R�~�lV��Cdі=ê�;Lz#�N�\�$��%Oz273��C)����K,̟x�@��H�Oi�ǫ�#�d½a!Ŗ�|�M�F���?��₿D��vn72@CC�b�
������$��.N��t9�E� ]�(9
�$�FL�%:7�y�(�e��?D�8I5TI~�!��y��`�D��Ֆ�X_!����I��;J��0~ZF�H���x١��P�;!��T�m��:ֲB��Eo]�zl�i�F!ϔ��z	,H� &��̚����N�3���$���1A��jp�o��׉��ܳ`ݪ-�;M�<��l�I��dY�}�izN=��������	�@ ���3TS�I����u:�u����Ua$�+!�]��lw$�0u�0�(�k17��rM� 5�$�����x��{�3�U�����3V���|�%���oэ z����=�0�����gh�F���]�9GXu�~��/���GN-|�����۩�^���W�� ��[~9�:�9���6�Mi���n?����������5g}�?�:j�"�p��ixȂ_܌^��/q@���>׵�����qAα�H$4���#im�wZ�{F؉��J�ڤ�xG��p2�#޴�Y$�<���N�>�	`�>D���s	�Y!����x*�f�
��"�b<?_Y�uZ^�AO![=an$,mA�#�)G�ȸp���F��)�s�cHj���%�â�$`غ����[�?�R_	vmc�)y�J��Dn�Q�)X����Bm��Ep<�QH�#:8W>@pWL�P��OD:_��7U��@s����Z��4� 4�;���X�V3�0Xg�ϊ��h#�Vl4L%qR{
�h����Q<o��2�H ըU��is�f��=�"dϋ�/An�6M�cc%٘�ƕ�5:��YE��#2��JPk` f<8�8����߀�2r�\GHB669<K�,=�nv=�E�	غ��(��A�c��wB��������l?6��L=�//s=!S��[[��r������U2�ݽ$k�a����{�sO����߷3�cO��/�
���K�e(h]>�VшyL�e��[�ܠ���b�5�&�L誔��C�jD<�8�si��)$�S��7�	���u3��)q@ȇ���F�`�8b�&O�����F����Z�Ai::�Ѻ�x?8; ���a�iL�v�'g�PU�k�p��[P稚ܞ%&���	,�~���Zj��l����p�tj��)D�VW�<q��U�f�+1�bv�'*sG��5lҍ�<�G��q;R"y�Ԃ��A�_}��R���Y����C4{4����L�|��#�-�>��D�1i���0��`�pU7��]>-on��w���
�P�C\xp,����P)��o=d����pqx$�ۡfyۄb�ݙ$�0M��g��hs�iOt	L��m9<!��꩚��dhR
cjq�����,��,1yV��U.lr̥��������m4�i<�i�j޲QjlK�x�@���2��Ad�C!�u�I�3���IF0b�?��#�{�:�}l"��yM��IķjjrQ
���a�F<��S��/�f�B2��ZgA&�����h�ǋ�cIe�q����/�d�4�\X�����[�F[�P�k�q�-u�44�B6�Uw|LH��p���6Ro��굏��)Ծ�z?KU��G�;ˬ>����=��*��B�B�5���0�� Ix�@�|�#�t��d1��75|
W���[���j�0��pC��\A(\�%V��肋�ƶcx�V߲q�C�d�eC�[� V#C�t�����U�c*�9��1�Q�_������Ȧ��S��ͧ�o]��r��	�1���
��7F���Sۻ��t�Z3(�y�8�	����6�o��L���8�￯ξ�n�)7+��@�"2?�]Yx #��*�?/��FH�#�H�h�Bt)�(����+쐫�e6#�3�����+́1I�ȸOR�����o�ę{�,�K���h��S_
�������HF I4o*L"�,6h��1+_�5���4f!TZ�3��{6�� &xa�f���������    ��hV�ml ���B�����g�    YZ