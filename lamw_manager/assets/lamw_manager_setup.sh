#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="44664897"
MD5="bda16f7e01b48e70ac0ab1b6f2e4764f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23940"
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
	echo Date of packaging: Sat Oct  2 14:13:14 -03 2021
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
�7zXZ  �ִF !   �X����]C] �}��1Dd]����P�t�D�	��?��X0��?M��2�/~�BT�i?q�_K�K��ܪ���1�f����J��xG 9X�2?��d��n�f`�yW7\�GSd���t�I:����M6������f�������a ���{M�����~vػv)����W��l��A=/��n�(��Vw�P������_���l`u˝�o�����l�����RSy򚒑�s�mշ痿G(�T����<��F5eM��y�Re�`ofB�#�r��yM�Uъq�y��._���&(K�+�r��#<��=��/�Φڒ�d'�$�5�M쑳��+�
�.o�6����?G"����:g�l��S
Y�c�-��D+���O�El�\����!,����)��7N�j����(�dT�i�z��0�e����i�\LR���3�e�4��I����˻�	��F	���{��o���!��;�e�oA#g{�fv�|ov�_)��	��x�݇'<�����9�&����Ki�7ќ�zP<_X�n�Qɩ���X��FR5�Dj�v��5߅�(6�t�#�>�~��t��e�W�e�v7c,��K�
W�?Զl�#_u���iFpk�"U'�v-C���;"m9_�����zM@MϏ�)|A�(��#��^,�{��nU����#�_G����hJ���3Vo�~�e�� � H�whq�q�}�#�Թ +� ?X3д6(�<:���K��$�K@cR�&:�Q3�d
b����4k^�K���7~���7�fk���$ E1�̡'�7;ۮ��.#�B>M���ŉ� UBmV��#ծ�h��j��b��{ʤݣ �R"S��1����(AnV���5'ۿZ�h��XJ����Y�/GY
�CX�x�����v����mɂ�n�w��s��멯D��W�J��9�粂*9�i!T2qGS�������%���]��1c�~j`��P�F[*��o�(>}����=t�hE�0���&��gK����	Z�3��t�\��{pj��t�j���l�{�]S��ʄ�|v�D�QFV�Λl�k�*�����{�Q_P���QY�������=iU��ydy�G��{=��7f���ш�wA<���}(id|X�y��0��^�S�<�R '�[�	�_�Ep�"]��<m��޾25I�o��I�=������` ��M<G{%Q���W'�k0�ڬ�W�nLk��<}�\ƛ��>@/��������s���zL�R����S�����!���U���Y[�%�F������w��b�} ��B|xP����>�z�4���{��cE��i�kE�n��.�n�m��4���28d�) �����%���"�P!~��y�#�
f6q�רj��ԝ�`f#��Z�w�ط��jgec������@�Hj}���掫���:�z�!�q�DAQ(L��QA��W
�\d�����6>˵0a��ӡ��'MX�wX}��Vd3�`���Ew���5��0�6:xn���:�n���ɳ����~z<@��Ä�b���I��a��o��;���
�;��<�x��k�b�h�bO*eӓ��'�r+x�K����7�w��8�yK�WB�:T��"��?�F�\���=uP�؍a!�S�h���`x�BUd�A1I1�1���ĝ2�K.����ڈ�2���VE��i��Zm�Qx)�A����_dB^#�U"��m}[�c�[~���M, p�\�fj@��G���,״A����7s��/?bm(f��Mc��C�-����ok+2�Vi����	��ӧF�>�M�-�}f��*�.a7�	9�B�xt�$7�]ύ��K+ψo��J	��EA� �܅]^J��H0X��K����XL*R[J<"�T;� v�E΁ h"�2�M��$�E�v�h c�ߖ'�?�a	�|)�wʍ(.�/���8f�L����V0��h��^��j~����AlU��녿B�	��s"��f)���<��(Z����4�58�cu4�0D�yS��{��q ����瀆���\_y^6�m��R$���E�r}��G ��,5�#`<��.�:�}�;y���z�L�m��S�*0�ᬚWkE)�c�F����:	�����z���_x�>�NQxg��2�t������|�/?���Ǌ��.ר`��1��9��^waɃP�;���ubEA��V���-��ȨU�pJ�q������D��y:��Ź�J��`ʏi��G"G{7}6���w#-r�c�$v�>���ь%�J&#��#����/�WI���Ց������aKӀ@k�����E�x�P$~@�}i�S��.$@,�n���Q�ӷ�#��AWɃ��ǩ8OM�(5&��	-������pl�J��d�WB�#�?P"Y���v|� 	b>ڳ�6��ϝ���7v�oEaeN	z];2�ӆ��ר�$����z��թo1��#��t#�G%��7����m:�_ű�����JX���&;��p���r�k�A�=Z���(dU&Ov��%�ɧ�dF"�ac�+t/,��ˑO��dpx�v��j�3�>�2J���m־��PU᢬��9Т�f��Ӷ.�&���Z���D�̰�q`�;c��M=����ؽ�<o�ϴ�d�u���.�� ����66|;� ��Ce�D}t'��M�����B̵�;L�n�ʍK
xh�K�jl�\%r�4�=	�=�������&��f|�������*�5a�c���i� �)l�uX~��SU�17��K�1���*I��f�O�=xY?���Q�sJ��g��e��܊����_���������݅�~�(`��Ø�e�8l�4��pava�6谱�z ���󬡹��:�׹�:/��I�W��W-6<����H�7����qg����ɗ8)����k�`w�q�WR@n��zNm�(4��Gj�ީZ7V9�C�`��$�q5{���%qU=P���{򋏯6�n���Ľ�u��Aj��w)Q.ԴNt�N~�$ōB-\���E'0pOGV�8��hҮ@���>�T�Y�_N`�su���Q+�Y��O��]F�[(s�B�'�4��]ir��kUtd���|I )U�D��쳇�fmk����������^l�����TgB���������OY�V1����v��}���X����q��ś�y�2b�uk79&
>�mؑ�`��8#Kn8�hW��q���O�x���s��;F�6�Hb�M�K�#a�J,ɚls��7�<�:�\�R"
_���?P�z1�}�"���t�<r� �Q��S'~�h �6r�AC[P�X$�xFB!�$KD�{����7G%{�_�l^�3&�S�:�(~��9���Y�7���Ch�f���*�`�ezGkƐ�����%aMD��_�l G����)�.�O�&.�z�A̡�B\Ճ%ɸ�+<�b��^�a�>�%�8i�0��9~J������4�Pj�X��6���nM�CB�[?DY�{���P�ǜ���KP���r=��r��o�ӂ����&KT u�G�<�t�#�7��~
��fg��ҐrQ
R�z?�\�g��ᆺ���Hp��ŗѵ��	��81����a%~�3��?.+����O(T�Y� B�5A�}8��@6�R�>4��\iJV���:Pb�	"����p��p��?~R5^�H�%�%.g��Nk�S5%L�k7Q���˰0���v\M������s�U�e�ZSu�p^�,�-��u�v.�����~����U�����7¡Eeq��� ��쐅��.(a�M���m�-�©ZGp/���j�����i
���Ä Ws��!ꂀ])%�䗀��[��Ld��$�?���7��y�`�A��L�A�a
珥������m��f�q�0&�8�y�B��U������n�nU.�$ÙcTEr��m�C���TKt��,�)̢�LQ��Ψ3ͣ8��c����nW�!���\/�4��,��4��רΈ]RRZ��&ŧ4�wI��p�z�Zn׃ ��������յV/��{��=,�6�8�OT�ޏ�<R����g\,gY�G`�I2��S�nZF�Yﯢ}s�*+�U�c���_�[�%��Q�������M��w�r��� �a����( aЌ�%2�C.��� ֙l+帺Pd ��Q\���%���i*��}J�YA�s�g�Y �������Z����)��=��Td�fa֔�d��q�k����0��>�|��Nh��}��~I��������پ���l�I({أ:Rj5���YJj[�?��������)��
B*?2�<���g9ý0J+yE|����0E.�[nLE��H+u��֞0G���9Z ��
��]�[Ǖb���ɶP�1����!�-���_�����R~������[QM"�^pV�:�F,]݃��Ɂ@�ۢ&h�S}��oW5�ŀ�=��}�	�iv������§x�A��q��?6��%�Z'b��3S��B�4��gJĚ �{���9��|{�����<�a�NgL$���V����X	�ˎ}T�kX�r�K��$z�4YfD���	� ��Q��FgXHv�
�i��	��Q\��g�8�
�?�=}��?'v�8��Ld'3�n6'��-ŝm:x�p�Z�;2 '&�4#��~��E;"�(���p�뵯rgs�=�YlE�q ��{�2[!���m�B�[�cs �ݩ�$Q�#۷ɑݝ4�7�d<�z{�� ��ޒ�d�8�z"�5+S�&]��?���*�G´.܅Ł��(,LP@	�� �vw�hp2zs\�#�}Ʉϩ�ݶ����U��2��������Z�o�J�:�W����Ħ�m4�5�ك;Baٟ��H;o�>Hˁ�
g�?_���h]'7cc���^���T%�b�s9�_rU���lcAYOz�jE��j����M�o��:q1@�ɝ��aC��Az�ｃ-0�����,
\W�vR|5�m�gf��R5��}C�M�6ϝ�����_��(�E1��W|��R�\d�7�l�����r��O�ـW(��ڂ��)G�$�{e{�7�d&��9�4�R���V�wEEg�����ms�v�S�7��;��8��ŋH?���Za{c�d���]r��26g� ��b�{��w��Y�%f��l)�/��y5�\���k;IvP-�"�lޞp�I�2g��ҭ����p_۴�,��n�i?�{�Z%pIs�>YS�H�*��F�k�ZI/.%��XGb�7��x�V^��_K	�c�.-mH�7�CXai�9N�_�!��k�%��fܗ�#��p�47ma>��2А��1�~QLfc�1�Q��(M��\�	?{C�~ZT}�����e3�����=Ŷ�;[�5h���w�I�V�+j;���F�4��~Y�e��luY=�a2�>��ĳL6"QK���΍\��T�z#���`s��:�"���_5�dl©�^ϋ��8�,I�c��M�b��z�;.�! 1膘�j
<����*Hج-y�<:]�R��;1Fp�(���H�Q�<��wV�}��\���f�cܞ�s���,뼡�T����;�A�K���]�b����e N��.�M��J!}���_z[��Kn�ן����u��EVL �h�`�xq�]2`��9J��3��r"���W�)1�m�>E�"�!K)>J���������=�;b���d}tE>6��ez������|�
:�jQ�8�1�jӝ�\�F{ ��9*���P}Yu
6-�P�ի��j�)���T�\�p!�As핛�������b�VU���z\,X.��BH�s�:�#�������� �������� ��B5��up^��{����#�~�����BD]���~n�D�
�B%�_ē�[��{�}�R�W,클�QHB�@�btt�9+�O��i)>'?�3]���ꥯMoh�`��E���^[-���!Q����^�C���{���?��n��*�Fj(s*0��3�i�n��d�w��|�s�%���;�B�5��[��؉�3�X\kh?P�VLDRPS�~tr�r!���ok;��qf��ߵ>���(�Ɂ;��b���_Ky��P��M���CBY|WlK��`�o�t�`pnu��!-t��t�X|�>�^�<�{͂9msC�&��R4������F?$0ȗQn9~|�1�GzufJ��N��O��w�Y7 �)�EWƺRѧs����wK��;����DÍ�R|�Y�;2�vԯ�j�	�9�#�{��;.+���#���k�P%L8���T�^�-�Yg���>W�h"V0e�y,����m�y� ��'�X�����0x�t��~eu|��-��tc끄�]qS���Y(Nn碰�'��pݝ�~il���$i �񢷟~�[;P1�1v��|"MyKT���ۮ���q���$�������%�c%��f&����-���\^��R��@<8�T�>�<r�ց>B߮���@��|5����� ����d���m(�).�+��9��h�}ˍ������Ok��|!%ݝ��'�.��p�sybʈl�K@M�$�;W�m��8����Pd�ԃQv]��xPt��~Wt�V �W��	�hV�,_j��0�S�QИ��B�a|A�G�Q����g�°�*��$����4���pð�8���j5��z߼ []G��.�xx8[	��"�ޟT(Y�N�x_�3K�*���g�i:�O���G�LD9'O%"{lD�-�@��9}� t v��P�����j7J:'r]�e;�(�;�O���C;�D�}.
�\��W���(�d��C#���g���H�mb�?Y������NU����h�U�7!H�>��O��3^��3S8㚻�z�t��9C,r\ϓ)ؘUR�p�]K�H&��D"R��t�z)�q ��ϵ��J"�PA쳐��fUd���~��4�_��O��M���u�W�'w�2L4\^��:�7ٙ�����l,�o�����R��]g)2u>��Ҙ�����L��I8_?�9a���i�v~�"�H9��� [�w),$�y�n�hxN`J�E�����O�4%�ˤ�(U�X��ɭ��:�1\7l��à����S��M-*�M�"&9�Z��5��Z�n:�Ӊo�S��0�'b��rς��3D���*�;���DTX�0��'XZY�w�RȆ^��M=�psD~ocI��:�/�z�-�����r͖����#5ǴsgXIƓ�y��D�pN�Ҙ.��w��Q^6��H���gKz`�L��M�T*+��C�am,��g8��K^HlÉ��дmuDU՛��3��a��+���}%�q��� L�����S�1M�������)��A4�2�x�c)rĄo,��'
�1v�����5���C��<�S����H�&�]�}�o*���RH,c�U����`9C�#N��	(k������=2�;Γ)��~Zgr�X2�3�ZPמrTk}_��]2^�����.Ep��b��k��ڵkզ���^WDz�-���70�0�H��[,�C�#�F��! wM,�%��̘�g6�JpY��j9�8\w���~�;��}���S���w��@�����35�H=K9�h�n��?���F?8�1��5]N�K�=�*���RD�q�h���IP�d<�o0�2��W`]-����j2��&2h&`\n�_D|�|��[�(�͊%tޥ|��H�[+c���=��<�t��a/~��l!d�51+o��|H}�qc��-�H�|�2�Ն!���Hj�����jȡ�&g(�s�	��VN�J���5�?�S��x�S��Ӵ��V�5���/\������j�@���f�ނøy�:n�)B�������E�#z���7�!��ym=D���� ٪ک�o���>�z����0�� �7D�L!���@X�0��~�;���Z����8�W���<�?rR������|!��&�?�(�@i��6�b����;����r�b:;�f� �޸~�9���i�)���zK~����IX��@:���e��hܟ�c�UkN�}�LIq�cjh^�/��d0�.�X�nx�OOV���pz-�{]�i�I,:�Z�	����`=�5WM���)����x��[�!�=���*�0�5.����9�Y��壥;6���D��@���{��#�󪣱�R͌W�G6����l|u@� u~�&���ANXH���é����� -�}9�wU�� ��V�~�W�o;��M.�X��9	�6���x�h�EX�H��O��/�*9����Y���=V�.��DaT�]���У��Ҹ��u}�w.�,��8�b��l�3l�8ָ��h�o����8�����;�e��<��'i�r����f_���Y��'%ܹ�D�X'vߟ�_¶bv�;�a��W�NÒ��-��_����J9u����(�CT��0]��(�G���"π{[a��VgK� �hj���Y��F��@[_:)�{�)4��`x:��v�,��Sy�����,jc��cyu�xx��|�C�^uLJ����"�^�˦�4���Wmݳ��Y������쭓��I�g3��)='�=��;���3�����s�\�Nѵ�@���7j���}7�����;B� �Hė+�~7�!Z�c�'
.��J���}���2qJ՞�W䤒����k�E�h_OL��Y�3�+��)��L��D�#��
�����@�=LpP�%bo�e�oZ�]�B8א	��{�M,D��#-����B*�
�V�'���@h,wǷn�r !Q�npbk��|���w�D=q.&K̞�.zC�����jRZ�9a��0��@k�({h��$�-�[�����&��C�S��r��So�1#\{��"�@w��@[���A�V�
��������*Y�#���k�� �o��-@+��1Mm[⏥��G��iP����(Dy�݆Io�q{�����_��v�����}��nߞ��Q�������l��s���� F��e)�;)-�q�g�l�3������oƧ�p�L��o&�W��LA�#r�S|��-hv4�>q�l� !?��u����є$0�G�Yg�e03
�S%߇m�W:��������#
ӳ~B�_Μ�y'Kw�Z�$�5�B��s�I���N�?�Qy��Ռ���S�}�Ӡֆ���J��1d��݇��h��4;
-�0��Q�[�̆����'T��'�8�}fU	���XN��ګO��Ӛ�w/�2`����V�m�$C����i ��,�O{J:tp3�4��:t"ӆ_U�)h;G���ۿ�v	F;�udT�F�������Ee�k*2{�JW��4��)2��P�f�	�9u�K����uU��&(/��$�P��N��xZ�̍i����
әG���A��<��M2�ES�s-b��D�ǵ��&5���y���C&b_-������[S��i���wy\z#��'�Ş��G;b���Nĉ2r|�i&{M��x\L0�:��W(�E�D��(�
�'��#� \�K���ng�&mZ����;Pr��r�h�FspAp�6�H���|�*��UU�����u��/����NM޹oo��\VQ=����=�[M���y�y�CP�H{=~�����=�M��T5G�27��ix	*�v�W�J����y�	?Q;�퐜,�'�a�|*��wDoF-���ŏ���UQ%� �y6�C�F됍�СP��$���y�.9bgO�!�G�"�5�s�,r�|�ź^���Ϙ��_01�pK�,�ov\�T�M���b*@o���~���'���h=4"؂���a��cv��>)��pMz�\Yŝ�rp8���|�n�!�1��g��?6D�7�z�"c���D��)��Փ�R��g�}Hc:,��[Z�0���q�&�������J���5�PɁ��-�}Vȓ@�6��2��@�6Bkm�$��8 �����M(V����W�������m��@i��+��$ %�gA<��j��`�M�0��
Y
���4xPzLbA�H8A�LWUo rR5��.�S�4E���^i��ᯓ���O8y�u�F/�X�2�:�YP]�.f����[{6�D+Z�g�C�?��������7�?��א�5��,xb*�q���ɇX-g�ç�<�Y�~E �-P�YmF�7�E���eO]6E�i��9�j���t��I�w@O�$�-ov�t��D�%�X�.7g�7o����G��AO�"��%w���ͫma_p�]:e}T�O���0Vx�ׂ���`��G>�uh{�n(�*�_�'9�_UEt�,<~�P�� r�T�C���5��J����Wu�Mxe�EO��+��z�	UNt�+���Y==�&��CV���N�v�/&y���&+x��u�E�NK�1�Ah��m���<�A�H��Ĥ�N�O������8=M�G�9��=���������9���DSG��T5��S�f���pLGO6�f�o)t�Px��I)a�¢��Go
�b�o�r���c�\���@*��t�D�qSq�2<N@�g}�I�@.I�J	z�J�n����k'��8�O������^kn��&�)�H������EH��u=��e��Pay���B�pT��n�08P3Z����'Y� �������S�fu��c�?p�c�iX�4���)ٲ����̿��g���� U���c^sM)��Q�o�Eo�����홗��1-��b}����u�z.P\��$9_��]��������)$����:ov�`)���4��NM���n����2I�Iʮ7�Ǣ�i`C0p��V	�W]���Inf�^�[��һeD�r�4���%�i�x��Й�J��G�F6��)������,���a����0v������bi�Ă�2����HBD5W�S:ȓx�Iԟ�2�	Q��X�d�&���$�!C�93�f;��5��DPy����C!<��s50sRԪ k��y����.���:���BkX���Z�z�'�B�P�r(��8��h�Q������CԪde0���	�)H�r`f�<xZvM%����m�j�8`I\�d��CK�bVb�4F���FJ�u1����KW�t����6��p�ׯ�[Q!�N�䣚��[D����tv�S_/r�C@���56�Z`:IL�Y[��3#���{qz����aq�Z�8|��lZ��x4��SV]��I#�;�U6�~�7K�:;p$�^V��J(X��4��_��yJ�����&a4�Q(#rm+���>���9�y�/݆@���_�g�^�\�`�<��
��;��$�J�.*��w��"E�?��ō&�ƻ$d�� �9}�;>�iYw�P㮧U9ag�����B�;ް&ٽ�ܖ�`g�tBp	-���\Flu]�-����g��}�P���r� %�ҿ\�0{�.BF_��8+��*��|����M���1�m��"�w��y}��g9�bF���jB,�z9&�0�V��eT-#��?�ϽE�"�P>�k��ZҌ�56*4�xÜ��f\w���ܻVI�%YO����DrV�e�m�@ծȑ�7��yzr��·�t��)2�;S�èg�$����IH��֌���S9?��b��^�$��|B��8��S��J��m6`�xo�:�q��e�s��	�"��-͵��� -�hDR�&��y'�`���ԨЏ��|��ϧm�~��XD�Pg.F����'�|
"�9��y��l1p���=�3
�q)]K }kb�x�ن�K S^K	���<iQ9(��N �%C�$��4�@_>T}X�&4���I���l���
a��f��%�̾�X勎�L/ 4ta�p�k[x������8��J`u�KC��@X���D+�B�x�� N%,����2�Ҝ��R<L��+�+)�(�e�J�{q�ė��N�1"LV<.[���-c�KE��2���^qxX��7�d�d���톆���K�J�Y)���Y*����LVg�j��
�� ��}}f�x���-4ُj�����*JlR�?1�s ����O� ���1mb��@uQN2^b㯾M�ך���dg��� ��տ�.�3/��٧��/���Z�!�O�7��:�3q`�G�y E�b�A���ٿ�(�ྶ�φ�H��F��_���h*���������Y>l���xs6W��Tr��̽�ӟ�R�W�ag��H�>;E'�>y��
?k8f�UK���Zh{�^��$���Dꄄ��0���Rw���iB���&}�oؖ0��S����|�L&������Cv�6x;b�c�Yg*$��ڭ[nf5�>ۙ �NwDH�5L����S�l�SN�JKCTQ���M��L���|�fNnX@?��*M~��;�;6���5��1�瑣Z[��d�h4�H�yaP��􎦯���x+1�4 �`j�!�E1m`��En�V���@v��}VG[��96�����gO��Oj�[Q^�LH��C�;��3��l;yY�1Y�t�w� F�tu�ݬ�3u+ő��n:�R^Xz/ l�.��>���B�$\������$�f��5-�r�N�VNG'�\@|�rJ�����4�<�M��s�½j�q�/�[���Z��q�Vq��#6v�m�U^�'����b;������#�wtX��D�zB���f#�/o�})	�E����U暊E^�������Ea����Q��U���Y�^s~�a�E0J��"T3ҹ��%�̋�
9� �k��崬�����̙�D�eo&�iT�z�#�4Vt��R��M)��}6w���Օ�d[� =����n�F�
8�@q�,�M���pAn"�j	'�R�~�>�E?�)��]��9(v) @6ۀ.�������`��7}�=�܂m�Ո}EG�u�qo��Sn�@�.�ͻVz�}�GL����M
{����j�0�[�@�{�&��Y��բn ׳�HQ
�N&4�NX�ӑ���9��s20J59��NI�u�D�f]&n�)#{�*g����ޜ�5�^���ȗ:���6r�4���Ic��B	��9��#ڙ�P����&���S��\���V4�#C=���y	�����^6������8uY�嚨"�]T���s�a�FdN�os��a5x�I0)��8NEk�����Y�l&�`XԬ�����H��.��.<I���%.&E����Q�xQ^P|Ow�9C~���8���������:�2Ď�:0� ��Ց��է���;^%�"ȑl���zn~\�*8�&�4�Rʷ��HH�S��lV�c���[\�$4�0�rYa�ӣ���T�1���4�˙��n�N$�[6�<���\�Gκ��N���km
���=�t����;rz�o�z=��AV*���J��Ƚ��O����f�$�B�3��?R��"i��bܑ͉g�T��T���m�YK��[�a���ts�m^È�ۚ�!P8]���1����vhZ�-��)��55f�}j$!���U���|=�cɭ�:0]Р�HMseU����y���3C\��R��.RЛK�h�e.1s'z�L��k��þ��!#
��Y����8B/n�+�] ����GGCф(.�mu�(��uY��l���5��MӔ*�Cn{�b�Z���$�����j;�9��mjX&�b�,��������a�K.�9)�A�/͢�W��#�]配��T��O�:h���!&�b�zO�*��b�	1.��VJL�R�T��$
ID)����s>t����*�~�Q{Ln� o�uƾ�r���WޚW8�_�蔝��M��yj>����p�:$.~�j�(�SUԛe��K^����Z|�6�@�����Y/	x��{C4��u1勤��e����h�	/ �k��}M�U�w� �~"��[��bs�O�JQ,x1yܑ�Y~�e#����\]k`h�:�����y|��LG�Ҍ��v����0�%C�%��b���x��20�D��y�;�i�Im����Z�,]'a�����GR�D�-,��w%\NF�����:��V�x�=8o��-w�HU0V!�M���e��2h@���
�f �� �W��=J��|�����0�4�y�0Q�{��cJV%[��H�ג�C_�Z�r4�x<J��J�Y_��T����(i�STT�]��˭*$�!ý�-`�a���Uݕ�1P�1��ߋ�SX<ٚ��>�!X|�D�bs�}�}c����Q"�&N����KD�D5�)�"�t�����Rr���z�����i�ɼ��] 7ĐE�xL�ુ�1�\�(!�ɏ��&��^�ϭ����ׇ��Ecjo�&*�̈́�F��һ��/����'�?�/��
��#�3��j�.q���#�	���t/U$)���A��j¾��e�!��$�93"�Yc(��$�}��� �'/1��Li��o�+;�^����[ʾ��>�����	�T���-z�ﳊ\U�ǎS{�6Xa��#$&��lF5�VC���_�k��C�U���`����,�,p;���s~��ѫ�ŀ.�zr�I�6�����6gA���ƃ=u?��Q��9�v���:U����W	)k[�"P�Y�ng9GsH_�e>�G4�Q"��;G�t\�W��	�(��7�Kt�W��3��A� ���|!�a����6�Xz�]�_^���Qv;��j��3C��ɎV����cEz9'u6*>�B�a�O�u�t_�W�����pw��s��۠>�註N�(��Ҵ�����WĦJ�Rw[���2�d3���뷋���{g�Pgũ����Zߓ���NW���aR���#CZ����[����k��VB}�i�6��5��'ի�ދ�}��#����&�e��͖�;,f�>��lC��3z�^�R���T����Ҏ6��Z�X/jͰ�w��g$�T>����*_2�/�@��N�=�� �2�p1��͊o�aiqv���aq�ɏ�f��D.
T��%lʯ�w�R��K���Z06�o�]X�	�0� w��+��~?`�*o�$YO��c��&쭸�uX��C�H�a�I-�g���)��U�t��>5j��L�̹ͨ/�e��ppY�ؖe���,eg���w�.�^钤y$��9� �����mY3,�rn��i�Ƹ��xg)�ۋ�Zg�me'���
Y�]�`���y��t�Fi]��4�L��:gr�3���;�Ա7�b�c�e|��[��}�Bǝ���R��'�����eI��紋}^��8�3�5%�F��Z�͟���dNzv=���4�|(o9��5S��s�Q��z��-��e#��g� q*���`����ưp�>�c`��Q��Y����%�P��{[�5�Q�����OO�1@��TQ(5~�Z��u�u��|�qq�EYUm����P��#�����~��B15�_oӰ~d��҈��HE��[��Q,}�ů|�-�xn��<�t�ne�6Nj� �ǰ�������.֚�!0��@&�;�&��Vs�ۚE��r�2r΋]:��nW*����R�[>�����"��-���ey�\>����0��	��b�?c/�xp�{��/^��`3*G��Ō��ޣ�����4�H3ԷE���<��+z�䒛��HYU�"�F��C-�G�C|��tHS�u���D4�TB��t��eq*��`�U���Q'T*�Ӥ����	l�N瓢��W���ǲS���(jV���E��/H�����	7LKK�VX�XA�^��	s������ 5Xf#�m�Q��"�����.re�>�P�^pn���J϶��I@�LVE��x�*v�u�*�K�i'�Ԩ��w���6��m�9�?��`wW3c�2q�0_n��*���N�rz��1G\d����ZY!�N�*�e��i�ak� *��ԛ���IFM���܁�lHhU<����*�\�(|�¸gPݨ<�Zz\N�:%xkYp����(��1�n<��߬~H>�U�=��m_���[�Z������ʦ�o��CG�HgnlipW��1�a��Zc�ߧ�j�;+/��\�Ưa�g5n�^�kd`6֚��ЩQ��kȚ�2 CsEl�%���I=�>��&!�J��E���ڭ�yy���f��m�N�$��ʯ��B���iT�B���f���b�B�z����7�+��	��y�+Q��Ycyz 6�}�˚^����+uH!�lH��/P39h���u Sv��wJ�^`����uQ�_�G�`��ʻ���-�~ ��]^ۏ��<C�.)s�b���+��.���¼���U�P��Ȯ���	&�5J��Y�'i���n ��^��)q�����q�+�Kp����O}
���.ܛ@�R�GE�&�[�Tdٻ�Hy�����'��qв�Dz�;.c3�	r�j������K&H�%��+C� �>r�Tk����I��̏����{�貵&��J�}� *x�����B6&sTA�+�V��H�S6]�؏������M6gн��B�T�0L�ܝoHB/*�V�Lk��ŗ�͜��n!�y��7^M9��:�7b�	M�_��bEBl��a��㤑����$�a0
�l�����.�"��1�z�S���LR5lE����1\��A�`�_�w���Ȟ��JD]�����J:�����v�mZ�8����X*?����?LY*]a�W�)8�y�鈕�H��=�_��ݠr�A��|�m��s��毲���jb�w�zI�k���� t��8����k�j������2�ll*Y��҇�}�1bө�M��ȓ�[m�l;���m�����|wL1�n���/	<�����}#�ll�>�P�˺�n��.��D|�D/N��M2jѼ�r�������r<�%���*j��g��}[�A�eM�kq��m֧0
���wA�� �qcsvFj����J��}�Z�0��\�)Z�M�g����4*���S�
�>!��� 5J���K��:�ղ%B7�p����Y`d# ��@��/�HB�Z%�h���X��?��!��!
��i*̚˹���&���b4�����r�S{`f���M�h�|�6fã?m�ퟨeXj���^%�E�>�t0Y������}�t%�x�6z0Q�}�<(�G)N��q�M�O@���ӧ�5'#^��{uK$F��V�?c��iv��0�wI�H�,#�EYj!�D�@w6��d��4�\��t%.�C�<b��U_���M����?ߴ'����Wb����WP��ŋ��j���+�4��uZ{�n���ձ�h���{�h�2$jQ,"�|�ʊ yd2�)uQ�_���;R�T�7'�O�����a�2��d�9:�7ϪN]�3\�-s�_|���R�ҒE�-Q$��������Ymޣ�T�����k�[^6��d�Dj�8�z�#VK�y}9*��U蒸i6<	��{�0����I�|-g}i�_��O�/�ݧ0,�BL=�帓S�-��L��\(-E*���R�d�(G�?6�/�3O��,����d��ڈ+ItqO���9��"�;�K�F��뵕��@a��u̕�G׸�7:��w�G/M����y�^�]���*�G3o����La|>�\9����m]��t������Y*-{�,>��]LT�r��'��.��`��7Z�#�B�-f�4�oO��k�3/�Q����9��z�fv�AUf@|����+�����!�si�3Wy1p��?I�	���g�^KA	hg#��ae.�\a]�I����n��J���d�4��a�U����x���(�4��
=On\�i=�9�XB;d}#��z.�q�eFe��^}[F�_4y���Q�'��N:@L&e��v�=�+�΋������uz�\�Puv�-i3ˀ6x�������I�{K�SI��[�C�7Ѐv�Eږ�2ß���)��S=�ODPFnn7�����]�5��	q�K��
����@FQ�f�U��Y ��S�2�&Z|}�>pd��#�ܞ��G��оZS���B�J���v-30�W?m'�4(�:o͢7!Ֆe�J�O�	F��Z��%��L^Fޜ^�S8��d>���6��3���6��^0a*�\�m5�*)O>h�R &�������.#t4��f�Tŧ����T6���&�r:)�es������I�Q6��α�TVҼ؊�N�&�X4���̬�Gs��_�o<�@�M��z}�`�X����vB~��W�,���w};2�f̺�MȒ�|T=�{��~臚�=Mc�����:�7�E8�n�Hh����u��T�t��lj�nTzp����w�h���<�h�rz��"�G @hFxd��n�A
���L��ϸ�G9��0�EL�Z�e�̠mz՟������i��(��x��FOz��2�UqcV�?��tu6k��P/�N���d}5���W;��L�ti����t��v�)L�3����W\U/���Y�[ʃ�V��������s��6)|��.�!S����4�@1_ː@����I� �
�6�7���0�#�Avd�ş���hF����-��c!�#�u]�v9�:��j�)O��@��,(o�q��L����<�شU�n������k����䚷5�>}�%���5�Iγ+�Ma�j�/�v�J6��(��
Dw��Ĵ������,2aoi �%�U�I�a�b���ފ��%���L�@�����w��Č32��::gP�o����0ՔF^~)�|���%�;ILi�،�ûM�&�,Ic����,lY-����s�8z"��5�˜9zqpr�ͅ�C6K��b���ɖh�F�Z^<�g�yTyq(�vo{H�M|���'�a�� ���CP��	����Xrj��
���AVPe(��O2�&�=H���:��G��;�j�p���Y
tݫ؉�ˤU0���r���Y,q�AVB%����>�]����X�4˽�����ڧ'�<��aL���A�����1b��z].p/*�Ð���К��g
�:_A=�)yʕ�&����UH%� ��o�5�b��ߑ�R�����y�y�D���B�|"o�3����p�/?�4A
�qD�N��k˹��,	�e\"�b��~���hʓ��v�V����׷h곻�ngH��'r~���k\�&����.���Z���#dq�Gf�h�+�֤�u�f����3�2�e~���@��|�
�<@�:���Ew,a\%��X�+ц3�`P�)˞�;lu�jɫ�r<ǖ��mX[�uSĚcp'�]����[O���[��*�n�">��ݰB���(�ϯ�����puL�z	���q������v��H-���[��mTLI�Ұ��6f�2��4۾����?�,>m�m��`(X�7N�3Y���Wܰ:�-�g�R� ���3�(��D�și������֠lq&N��gÐ���4(8̈́LF^º���h�n�����o��7��F5���@x�d�'gq^�i�7��E\�+a�,���ZN>�9��e�p�e6�.����:��0}	�$��j�>�g��t�w<e�>{�=��6ҩ.��vܗ�.��(|*mD���c�e^�P�zD��""f����=�h��J��jWF�z����$���L�`��x�n��F������<P��ܭ�q	9�-���G����B ҟlgٻL�/{+�n%�~Ds�"9h�g�:n���`�e�;i8kv�h�=3Y�P�h�.�����>N�T�o�W޳���C2�i&<Gh��p� �1m[� H��[=�H���X;/J:I��k�|)(2bhG���)�;۝��>�vc��~��+L����zt?Mud$��|M�ƍ��<:��|��Im\.��~3�\û���
�t|n�������^��7�g.?����XN� @��~�݃C���E{�9TB$ݪA��K���.�O�ʮ��ܒA:�	a�8�����&�ps�ヶ���a�ʛ^��o1��ԗ�����K�99����}�|��Pf˲(m�O1kb�/��WfL��Gē�9<�L���F�+X,�@R�t�h�9�+\2�+�*�Lfβ�M�-.�#9�����{yzj{��E5�t�Y�^լ�:�[W9�>�!�+N�e1����}*iG�"ʂ�����l��P ;�����,"]�/�R��A+��}�vʬ��3�G������|���䥨�R��!�ߡ���g�>�'�L�յ����Oh��]c�_��YF�nd,@��pm��=��f��!q�8 0�ݾ^�Dv����زr'���f��5bs���3��t��|E�T1�*�NXmK�#�H��5ГO�ù��&�-�o�l������Da�x�h�8���m�'ֻ�5��yd�ϊ5~��}Ig�D���ZLWpO�g'70h��h�=��Щ9~�h^�d�=���y�1#йcL2V�;q|#^�5}QP9��m�������#��{�heضC�����JZ�V��N�	�(�Pw����}��
߼�X�;����O�)�q �v%�`0���R�~�`�%�2@�UU�%�.Ne�JL���r���C�$�GF���[�"2�c�r���i��ҵhS��G���]M�P�ц�_6
ĉZ����|��andxwTB���ŧ&�q�7�WL�p5�>
ұ^o�v�'(s�I��7�	7���zT���.�=m�rwuA�d�R�r�/��B٬��:�e��������ϵ����^7-�G.o�`{i���l�a��*���^����g��E�@.����#RG��]��I�>zv'"�+q7���3�c˂͌fwa���-p�F�ƫ��q����������
�7v�"���'�Ħx\D���u�����V��;���$��#��Y�N�A�Ƀ'��a��~GL�&`��7e{�-��q�,K�L���ڊ�)�n6��ϓ,��a �81W&��(�y�9/��o�-f���4��9���񩸐6�6�ʛcq+��O��P�o�v���OY�m�N<���W�8S:Y@,?4���a��:C��m��l��c/�Ȅ}�j�8�fk���P��~I�Xa��lq��!�9�s|�H��C`�b���7n�T��ܴrM��+�s�~x�_93�����m֒���*�˝yX�iYj�6F�d6�t��U�e�PwC�v��I��8�Fw%a?&�r��N�۹�rb����\[`���_;@� ��JÆ8�?s� Ճ��� �K �ʠyR��S��D�)�̡S�b�U�3��X�T��b�)��Q����#{V��� � �K��Gm��+��������|��m/Qs�ϒ�� ��ρy���,�\ E��d�[��юr)�D|�b�����[%zM�ߍ���7���+�ӥ�OL��[�3�~�o}�}�N��TdN���4&���=��W���?��ݦg�q�y�!�6�;���~��JZ:@��;q:g�K��s}� �Il{�U;ϳi��h���uI�P���3O�Y��+^4�tnZCslC�=o�
��F@o�hȽ�3(�r~�O�(�?|i�{��~�mf 6��0�!
�b̉� E������;�M�
P�#ve�=�9�4E��Ԅ �<#�݉�=�=v��ء!��S��h/�ZS+����}F�]K�d:��b4Fs��]���á�:}�2��ݰ��⬩QS�7b�����;�~m���;�^#EU�kgU�=Lz�,QH�wp빉1��3=�[w�qލ�17,SO�*F1:�8��Zn�#m#vS���*n=[��ퟡ
��L5!�@y� ��!1��cc�;d�(�\1�`��)#�]��|ŻE;��T�2�	/&��s����<���2����_Rpr�={clzeVw�}2Ӳ���/�ǎ~s�Yt�j�e��F����_�Ʉ�m��骄���;����F�c�C��h����*��M�=�_���bkVW�M���۷�*�M>(�`E���91�<P[{>�6:�s��ms�_1ZN)�� �ߊ�.cA�s2/a(s8tD��r.Kؠȥ�6�&�r�2~g@����l^s���cS��^VX����sv��6D��QT��t0Q�̣�D{(��`��&�E�Z�Fr���J��D2R���$fb��u�a��5=��IO&�[�Jp��D;��Z+��:.�o��`K�(/Z�����)�tS��uY���i�BZ��~�B���/��%�QK�[�W��FbJ�s~�ӳ�TSI&!^T=���qx��s��pp������Xĥ{aR�Ӏ��]q8lB������ �L�F>p]���1<���3�?m��x[�SQ��%��dpH/S�P�|�����a� /�|�S�%�,�i�њ��I��R#_�2���ݖ{���ֺ����j���!�c�Wv|$H�:pRnvjY)��qv��7��(۱%��I`�e�tj@hc?��Z?��G�����#כ*�~�P��&�3�wO����: f'�3��*��M��a�jt��𯜰�=�zT._���H�gA�t
={Ӱ���.o�Dñ'��O����~`��:�cs�����R�����8�U��6����2�z@.}b���8���dk��IV�]%E~�j"�[î���Y�^%1�&��w%�R\1���kI��d��#^l[,��w��k�',�V�̗�D8f�(K�G�Hׁ5᡾�@Dax�O�~qh\����d��}�s4���OI�3bT���:�ة�?����`ޢ�ެ�m�#yX�99�gh\���O���k4Oī�fP�}��)�M��a#?�U5G%Z�TPȨ�ö�s���IA���s�s������J7D脕Ւ ՃQ+��q����6���V$�w��w���Ҿ���O�?		/Ȑ��[�-UڻA�Wy���R����p��A��M�I-,Ǣ���a����]p�U�]�q�I��=:�MƲ��G�M	��<�n��,�e����Ӡ`J��@����E�>�;�l� ��b����O����R��2�2��� }A�Z�eg�|�DJ��9�ՁP8������X�H��坁H�un��a$��2!ue�i���kq��*4H���ٜ H��ޫ��^�jy�둌9�/`٬�ƍE�l�C�Z������5^̮�oA�6��/�Ǣ���R@N�mx�������v�ZJE�����׍�Q<�=:?R�Gc	W���IJ�@'�_��5f�?����{���Yѩ���u�8)xzX_V���QǗǹ"44�׉"x����H���kh�m�ɯj��+~���ҳO�	�vw5GXD��j{އ���7�_|	L
����(ﱃ�� 2��[Έ�и�{;M� �����x�g�F������}R�Y�W�6�,�?*�iP���Iv�w�b�1�:��$�1a{�e_F@�WШD�1�o���=����R��	����	���?�>�@�P�6蚙f��9�t   c�--h�� ߺ���T]v��g�    YZ