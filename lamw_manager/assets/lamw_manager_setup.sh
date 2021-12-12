#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2168952115"
MD5="0ea66062ab6049f6d8eca11a551955a8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25512"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Sun Dec 12 10:44:43 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���cg] �}��1Dd]����P�t�D�"��'���7�3�$�r��)�f��?z��F>�|ИBK4�������\�2G5��w�MAx<��J7$�g�{�PGzE�l������5,"`L��ʅG��P��]:���]:J��� ��6' k1c�hޔ�t	�*��t|���K�!Æ2~�S�"�b�2��}:N�o�����g�%�aS�+1Ո��T^:a��װ@m_�<�ܫ��F�����48z�5�&u8��������>�������0_�@��5�H�Е��By�_�4%���o17ł]y5�p������r5B�l�'�fV�ٳ�serI��2n����7c* �y�u��DD�_W<��>u*�J.1����8��~�Sdvp��x,��U�w�'��^�E�0��U~da��5)-:�5�^R��UP����+�vC�X۴F���0��oϧ��!^��~�8���� 1��MP �Q�=��G����1�+��e�����$+�5�
�C0{���v�n�en��wY{�oW.��Q�V��|r�T|��,�9�F��j����^EL����+)��2�XpM���2{�p�<�"Byy�E�+�E*?<��癶m=h]H��ל��]�py]q�.�	�0D,�Q͝����P���["�v�&j*0������E�>��:O��It,�e-������[4���|��2C������2��y`�N�=�D����4�A��N���o������U}ú�~�|�p���h��-B�D����kD�&̘n�aCt���)���5�xCeK�c�J;l��M��LV0F��q��1�!�$<㪕^ї�^��b@}�[�NI�~Vcm�$�<Z�� (Ӻ����cpq�K�x��yK���Ǌ�9��!���TF���F��7ĳ�@Ya"ZOYf<鱷,�7 ��!0�t,�U�t�v>-@�� �Ѿ����3��/���g_����W�@�~bk�2��)u6&0��豭gk�p�o ��Yw�3��8���C9��T��g
� 1�@sIX�������]{�38����k�û�g�3:��%�F�ik5U����zAՂBb�G"{,��7�ɀ/J��m�I�WTf�ڔ�:���I�_����G
���2�U��i��W�U'Cj Ƒ`W�%q�r��I)���I�+Iv<͝?EN��r!��{�br�[;=¾z���X�Z��=!�k�]N��eN}� ��[z��<��^fŒ��?J�	�a9�R�8����P!jU�2T�d�ŮA�4��EC�%��'Y��ڷ}�B��Е��Ƹ�e�h$t��!���̖l Baˇ�����}��i �NP6ĳU� �������e�Du	���%���̃-����v]��%a0�Z�+Jk�tw֋@jWd��q��4M �P$`E8��M�u5U�*�w^2�AW۵#?~ �[��^�|�����B�x�e�8;(�vQ����Е�Er���!�d��u��/�!�'\���ن��a@����c����4��1��!-�%�h��B^3@e���m@��:�+f��R��C�)n��wZ=s�эffV�h���楟4������xOT	�x��3�#��hf��\��M1v&��r|Z�s�T*������IKWgf�Rq�(p��௰P&����EA�y��M����a��L��G���􃿼�Bt��0�-�&�+���J�D�U�.L�-A`k6'�p�y]�fW�Rcc>�Dҩ���7��ב5qS���HO9ſT�}���z��.\���0�q���O��������G
N1&4���^�Q��k��]���h�&�ZQ���ʮp�_Iŵn!�����|������I�${��ʷp$r�Y��&�����T���G{b��z���S�� $^w�9z�ǈ���qO �g����{#"�f%��IP�W|�n
"J�.S����oG'�4��Y:��sz�6D�K��7�]�̽}WҦ&P�F��b&������ƃ>��G����17�d���9���H{]�L�b�&ؾ?��k��
�2\B�Fg*�cY^AO�[�0A�If�|W%6�����.�_K���)�e�x�n���/B��)�sd�p&6f����u�MIl; ��ʶ�Wy����0`���)."��-�;K��c�a��}�7k�Wb
\ek���5��n�rX=s@��`���>t�J���I	�A�r�f�1�Wc�>��z�^h�a_�x�D"Y�੸���N��2�[���g	5��è3���e���N���D��
�x�ޣ�}ST`����e%���?LF�V�������[�"�|9E %'豽�w�b=�ǧ��U�vD�σs�ω��wf�1��0=�	s����xsֲ�.�2v!4v-;2J�+r�s��c�5���?�����m�C��R��&�����=d6��4F�C'�h�nKjl��P��}�?���c�ވ*hi"��&M#J(��}h��ݨY_��b��TҤ��4��*W��oF�'���w�`,l6*v__7��'��`�
����*����a������+ӈ�����ߣ��,�"Z+�$���d$ �%s���\��� �R��WS�Jo!�3����HQ�O�B���r#������-K�g�.��ľ���B��F�QH�6�&#�o%�s`Lu?�n����%������F�V��sSXqw�m�Z��51[�J�>��	�l�W������V^�&�+�D^Z�
��M���X"�����	?d������W��O�<f�s�Jt���ms�ƥʧ��f��n4�zHQE�L���n��؍�YWvE�?���_%�	�&����b��jU���&����6,t�K�y���fl�9J�_w���v�f�oN���ys�Z�����R����e
�(��*tB$b��ף:z;���*�+��)�A3�z1�֬�;�g��),�e��HgkQWw �)�����n&����D�gb�χ�G7t�'d�Zt%��C���ܚ�˟���04��@Qmǲ��ߒ���v.��Q��@M������u�������fG�WBǬ-0aO��bO�/�U����,� ���}��G����`~{y"ԃ�7�2�z�>�����$����&�'9u76{��A=_�o�ѭ1TCŭ��4���P6����#A��@B�)�LH�NyY���@GņX��*��V4[�DӾM�	�JHU�O=��NW@ނ����}n�g�<�;#�i��;s9,��c(.�7��L��ǋ)x'�hC%�<���~���q�h��M�Ըj����>�aHB���#Ӎ6:,�p��ki	�nX�a�S���.O�5ֳd�_��>A�=�)ݒ��itͱ@n�R=�G=P<�ɶ�T��N~����(}K��pXx�Jp�Ϊn�:�h�^d��s�V  ��s�g�u,f��p�-�V��c~z�B�B�wyI��1w��(���.�����;Фao�%�W.ԠIT_4�"�..@���M({��
�����J��E��e�`\o��^�Y�!���^B�|^�ж����rw��\��9BX{�۟�B��b�v��
p1#�=� 
����~
:��GvY��M��N5������|�d�(,_˱��֨WTR�P���J�꾰8Rcr�2.�x��% bq K�2,�u��n�l���H��Jp�M�wO�l�-�W1])}�����K�<�̍�sf^:ȩ��Y:��ȡ��
6�0��q���mo�d��Q>lo���~�Z��T�ؔ-^�N�L2�p�E*��H��%�����J`V��	F��j�������kn��1^g7���ݞ����ZW�)�Z
򿃁���U�jq0}
瘡?i���o�*L*Scn8�d:h���hHtI ��v���~����8��j�|~Q��2jr��5���F��_��v���H�G Yw�K�6�=�N�k�������<D�Zx��ddt�:8�i�%�!#�	+�� m�j�̆o��5��F/Pw�0ʹ� VЃ����T�]��3�>KqxN���!��.�1-�<��l$\Q}̌v�kͻ��lX�uk@�?̥L(�KS�|�7
V���1���ԌtM�q %�O��O�"o���w��Qb������Yף����cid�A��f���3m�A֠@4 3��T���5�T�}Go�`�ݪLZ8�'e�����M��ĉ�8T�4�]�:�� �n�S]�
|*�	lۇ�-V��| y��\�A^5�.������Z�	����o}���M$ ��޸�y�Z�,����7M<�̆sID�%���U����#��d]�!*����99����'�IP�GB�Ϙ$5�|#(�>u�G�I���+�,|A��m�����R'2�jWs�q�1ݍ����ˀ�ߦ��6�u;��i���Ne��%�,�_�Oy�uҡ�)LblMA�u0��[7��ԛ�ңTeN>�!��xa�~��+���ųQI�J�����7^��^��Q�OJ4����?b�6���t,��r*�!ꊴ{�UZ�qָY��no��}��f�F<J'L�3W��j�HD��붫��(�nAҫ�ӑ�ܬ��m�N�0N���v�p���x���6���ȗ�A�4��x<t��v]s6��pP({4@�p���{����C��]#�a}�=�6l��FT��A��^�|��\9�)�c|� �&-�U����D��[��ڠ�nS��}ӳ����Σ�`D��%(��Yv�zCws)䳼&6�p�������u����3	�K�|"���\�����I����M�v=�7�y�Ud��t�.$����r�!`e_jNS�*��]����{۳��	��=��*Q�5ލbh��\f�VP1 {�j'�l8����q���ۼ݀t�|�*�� �����������;r���8��w<��7?������r,�Z,�SN��g4�lb�xB�	�d`���O�ꊠ�q:� b=
�&<��3û�2{j�%�+��j/Y8�$������z�d|o+�Wv��*wc��3��?�!NB�ƷT`Hh˝dhApm �nm=�d�|1�_�.�����2H�ۉ�M@��9��Ǧ�(���ɽ���� ��u�!َ�a��2��g1^�?��h��;�� J�Jz p����&F�7�ߥ�-�9:XTMt�<�C��r	�)�COm��{�W�`I��[*}N�U�Կ�������ª,�t��9�<bV7f��|ه�=y�u�m��L�;.��>S���V�d{����4��"��).�㿃�-�a�^�5?����l��]1�-���!<�%V��f�Ce�i�4J��U�
]j�j� �!�`�o9S�O.�A��f��z�Hۧ)���ym8�˅ZF����A��^D�9D�O�{Ŋ����u����=�&P�ۻ+�={i��q��3�t:�M Y%�Ge���x�<����O졦�?"i|T�݌�d�9���S�=�-��S��'74@D�㥳t�)n�W�2�t�
�r��K��~Kf�؊�"��;�f.�@f3��n_��PR�i���/��,��<ށ�¼��B�{�;]�Q�w,'��S˧�F���xO����n����%Ө�/9(�T_��W�Ɩ�s��N(<��D�:���f�t�*u���������K��zs`����/��^#��6�a 3U�	��c.���,�a�7I�S��4���7Y��Z�ok����}��e'��H��j2��0ZWt�ԩ�S��d*�F��cp���N4@�+�'�v�ü�#H]�����Y�sVȓ�L<^���Ͷ�?m�1aK�)R�s�!H�צ�C;�:R'��lu?x]Æ�9{�Ž�B��"�}J�gY�:JO"r��� ��;���֑&a���Q؈��^9��ǻ����'��&����!��'ڋ4�m���`�[���y�׻�7f� ���?�#[ћu3��]�p�^xW�v�|�h��,t��"̉,�g����\���e�]�ZNhu��R�7���4˻�hH�,�_�|��.�� ��j�fs��m�''o���%��k����֤���F�-�(H�\�lC����>L=��[�Z�3)2�Ƶ�T���V�"���� �� ���)��o�����ߙ)%�%̂�El�u$��8�&ک���=�v �M}��Ebu	�0���I�~�B(0�j��3؛�B�=XZ*	��iu+)�كȷ�Jb	܅[���$�&IԪ��^D���_�,NfKp�|�8i7�5Z��������í���1��V��\�a�N�mMl�M/e��|�>U5.�� ��dŵ2��p��a/��F6sp�tXc�����Q��l�G�	k�2�������7�<3O����*���
��c�:��p�f?rYr�>R�Pԙ�CY�'Θ����Q�����V��_�3�S�H�?]\��+-��r��?�jS*�j2j��SVq@&�%|���꣖&^��=h*�p��:�����o�GV�_-~�4
��o�_�e{�5K���1��=��[���H�m�L1�"�^�BN�����9��_�����*��EZ�KX��3�����@|�(ԩ|!/u1ˎe4�*�F�~A��߭����ثw���[��s��d�Z�����ۭ�5��z�44�Q�>h[՚f�=�S3p����ÊقTs�y�x{W�l?&D$i4��K����9k��cY$�."�=�����!Fq�L��z���	ؐy?!q�O���v<����1>%ü��n�b�)���Z�"���X�$TF�[��Y���Zw�D92�W������n���y]��֭*  >��'�.2�\I}�I�"_ڼ
�m��-�tD���KV1��	����{6�?�9hޔH9̸ZxN�8���nN�a��C�d?=bga<���/yaߨ��\"��]�(٤j���4ͻ��U�	ͻ�#�T�(&&�����f�c�����i��m�'Ţլ�s�:&Y��j�(���/�hr[�3�����>��C��{#�n��qdKc��V|{��B?�ku��io�D2,q&	���U�j
��dO�� �>��~���:u��jH�ٻ5������i�[.5%btQ;�Ի��b��=����C�b���%�Q88�3�+�?S�")�cvNNGꡬܳ�		l�PH��WN�� ��ZWl�r;�c_h��߯@)n��qw��]�qg�y�QT�>�}�pB�k�6~B#�^
ŋ���M�y�qy��r��Ď1���������u�%\v�p�-����`h�L��ǿ���)]<ˠ{ԕ�8�ڸ�ǓiZ��^�_��B�un��cT ���ט)(įor�H�t�:�o���o���*N�#D������{�B�����j�?�VW#@��V7hЗ��Ig��3Q��&�V*�j��Y���QWnb��|��H���_k���Ez�p
4s$ś`�Vd���3q����8�'��!�3�Ҩ��m"��ЭO���a] m����2��y�I�l"XR������	���ݗ	��@�9�?�]	�'���P��bgrf+��1������4�#��d���d�Cmh-8�;	`e�]���',��vh��7�8,�6ϴ�/)#��o��A��X�c�<��s����-p�0��,1$n�h���*�d��_ �:���4�,E(*q���}�N�I��k��r���օ��XM�$)�qKHtA}cn�W&.�����PY6��K}��n�̼sV飏6+`����9���^���TT���!BeՊ�~��B�da���u拱�|�,� ����`/p(��L�!F�j,�/
Bq3`P���yȥ$
n3��>�p��l�)0}	*t��N�(y#�F��t�8'J��i눓�6]-�?�s�^��V��kk��E�#��f�N�G-���qp��c���4��ą<V1#�\i:&�u��J'�����\��!/ۊ��g�{�uUr�L"�K�����Oru��]TmIxeF:Ͱo�g	���r���H*N��1ߎ�&�qd��ai7 /�K�����������=(]�<i��zP"�|%�܁��=M|��x�?��"kA���ݺ�$iH�݀%x�졯,�^�$�O?������������8kg�V&i�V<�~ /K�q�kQC�o�!��V����>b�M�@�kM���#��C���ɫ�c�7.�&y����1�g�앷u'�/�§��Z��.�dm����)�%$�*�k=�&���s�D!���\���{h�/�kF-�j�v���������a�6�sO��NH&��{���q��(T�~Z����y
��K�d���������M�:�?%�`+^і����y:��O���X;��Od��w��jg��~�'
�a~�7>��A୥`�\����iuU�5�`��9�0-�_�bø^��\�%��A��݆�j��DI3��bl�݋��`�m���+|.�0����7�V���h�He�A�uǟ^A(� �k┎�%�ui-�@�ge�]k�G4��ٿR?�*�	���� ��H�*��]&�v1r:u[t�aJ(�'|O��o��'V=5�u�`1��1��
`׍ ��I�5��pKe,�C?�X��
����0��:�	��ٔ��>�qH���=w��WS��#������ˬ��v9��d!E�q]+1p��%&�c�������ң�t�R�|�fq*^�BE�r�/J=c���iW�[M{b�E<8~��?w�{�ǥ �ƞ"��{�2��X6���?/A�|k�^'����ǔ�Rj�1wYp�Π��a�p��q��q�OG�6�织�͗�~�����t+�3������go>��N�؅�_�C>�������g�r�T�B�<z�_�v��	+%V����v�kwޒ@�c�O��a�[.y�%������;��s<��u=�z�T����-y�3���E^v�6?��L��z),[�#%|͕7�|q�~ޠ�+��
�����
ܽx����,S=D�=2j2���f�d䏽�+��"���a"�1�^��c�j�n����1S07�;�5>q�fk���j߆(��+�c��� �4M��u�xs���/FIt�4��Sd� �'9W\�Ӵؠ��<��8�e�g���(�9RV	&}�������3��7k��yS�� }�)���)�w͒�#�Hc-4�� T�¯�ݻ�O�9�ʄkHR�
?�I?��ܱ�ک�T��$�N���j��T�~�NPjD�Qc��^������3�C!�^W(�{�~_f2E�Y���!]�Use��O��I��/^u�R��{3��7�?�^7�(���|�aPd6{pv�<X4�h��	)�����\���;&1�WH��kG�Urn�22��b���S�ើ�nL��L�ݳ���Gg�f��lI��u�-Tzi���>�W��&>�"~���p�Ij\�ė��ne.�a�R�@o������ƈ�6�PA�WGG��'vj:�-�C�T|��0�X 52�{�sl���m"���O����n9�5�Q��:E��0�I2?h5gП���_X7����P'�L�aOl|�E���p���oӕr�����s�����I���'u�w���&�Dr�4�f�����h���B0J���^�%^b���e���%��Z`v�]1�G��O�S"�h�Kw���c�F<,�?XV8����g�ڧ�+�~=��dj�-���]w��/'�"{�7�DV��)����݀���<+�pͬIaM���H�Q�k
�y(UU����A�2L<�5l����$���� 3f�\`�p��r�PZ�	�r��!|~K2��Kg�s�����"��}I*wlQ����p"�I����`̀�#�����L�D�o������[�G�n�c��O���Ms+�FN���.�h\D��3�*������ygzQN�G8���ES�������P>�����f��l��*cu���`H'�R�$I
w�n(��#��
����?���@��"�KTo�e{��u�H��D�J3��H��9vc�CE$w�An|@c��~T((�/<��!z�q�N�Rn�2��V�oIftT�ɚ���K�(��3�"�JC����_nrZ��Ѯ3�lM��R�s��Ep��C�=�Ѩ*�ʇjW>�񑺘�����u�(���]�\�1����B1+^N\ w�#3%��N9���)F�����DR���4��s{��3i ��~����A����&�Ғ� ۫-s��)�^� ��Q!�V���k�NJ��nt�XD�^F���P��B����&ؘ/�O4�=�X3�"���B(���Z��oPw�X��:s2��h�śHH?���ڮ��N�@��\d��m��w�e}t<�}Q����N�O�J�:��\M"��r�a��&�L�.t6��2���E���`يF_o�De���h̀4��W!�}�b�V1��!z�g`�X�6aV��'(��t/L�GB��V���-DFdPz*�6լ1x�?(����L]�����F-*+>�5`�p9�~���rK?I|���q�%#�R�wo<wI�z��w+ZDHH�k��hÎS-�'K��U���T��H؛~���:����Q��.�1��x!��,�*���H@b셢\�.��6t�OA������G"T�eq)�u�j�hNI�)y�%��{�tLѕ�ƅ�DKe��.M����X���Z�.�0��w�r�o������l1»1C��u���ٴ�}vضQ&B̀�ӧ@4KY�$��ru<2��]�g;��u�;�re���Ry��5�y^���:��B��gn?��V¨���8o�N�8)�:�M�^���Uk����/�E����f���B�U%���Au�� m��?~�S/Ʃʔ��ɷ?_A���~��^�`vYw�n^�CS�ܦ~���D1���|2��Ej8/95��xV��ǈ���s���hH�%������*�p���(�O�:,��lB,�����-نw���Ķ�D$�$��
;�mS���
<ͻ)5����t�h��L���v����48+Pr�c*�)���fw)��[:L���u���{�<�;i@C�Y�)��#0�ǭ�s}��>M����繵� &8�)>�ў�R���O�x>�%J/�PRD23�9e���8LZ���00��G&�i�:������,�����L.���R�D���z�'qT<R<�޷�9���]
��#�����#�j4�i�}1[���Y����'YM)aQ�*��)$I��c��F�i
�����6�9x[��{�����Z>��4�����*-
��׋Bw�~����f%�uم�2P����z��x��d�k����6(���3wg�H�I�~�\������3D�}�tۦ����e�ǵHt�4`\��H��b��ӎZ���j91��E�*#��wx�ot	3j���npG����SzЎ�����~��	.~���������&D+��l���8=�%�:�����
kв�.��R�G����Mzӷ��oe�L�$eCH,��;ǥ���m>Dɼ���#�}��M�[O�Q0􆻊Ztm�)��u��4���O��ט�V4���=�,gnw:����o������fA֐��e��7�h�L��xB�ca��B��3�z&Z��k�H���I�6kӎX��M�S	h�]��z�#�)x�X�~���	7T������/C�ѯ�J~`A��K"���H%��/F��������;��˅(�q�ie���G�c�z��#Z`,	L+�|���1����P��Nmv\�U��o��t?ߪ���C�P"�,�i�z�B/�U�͗��:=_��X5\�5Z�ߏ�.��M�!�M{�Ӳ?���J��SC5Ql�TA��D��AEl9*�vpǪ����GV�uuT�4�����[�s���`ۖ
���&9��XڔD�UX.m��H�Ƥ'�����=����Z�� 6H��2�sj�o�Ϲ��%1N@j��Jg��Q#�_.�B,A7���'7͊Y�X�$Rt_pm��d������C�]�n#��\�8����< d��EI|�XD2�ֱ2���^�j�?�>��82�P+v����E�P�w��,zyT�ӎf%����{K�kh�~��X�^���e&�P��E���^�A�Z��|��,/��~GS.ӏ��;��v��3���p�5�^��3_������:�a���؂������'9<��rO���Wrb�ײ�d�g���&�0/2<�m{2�/$;��%Vw���� ���)G7��׭�j�X	�9?�{9�r�{�d$3�'5	[��s��o�wvr~���]��y�ɰ����ۥ��%b�@����I��J����o�����mn� ���5�eU���� WE:��?��z���F'��b�4"U�#%9���ψ��x�6���#e"B5�\���H�Q��ȄӛW�i��ڊ�knz��f�@�XwNE�+`�Qk8�VK$�7��I	G�G�� ��H�ht�t׾Μ�B+�F�k����]1p�֬}�&=�)$�R�Trcd?YJZl�"�{�q��[���?�����.T��R����q��5	�L�0�+�=Ϭu	)B�"�U�`ξ�:؈_�f��hkkm���o�@ K�`���}��L�s���^�ǔ[�n��]�;�"ˉ�г�zwB��'���9���� `�W��T�G�B���v�S�pAԇt��*1|����?/����U��MH�$��䛻�Ei�I�ѿj���'�m!���(�,|��{6���r=�^�~e�e_�ب6����!�,�)d�8� :�`f�"���'�է�FUJd}~ʬId���Y�/��Y���s3i�)QD6l��[�%��V��	�W�*=�I.�T7��܏fOA/8G~.�븂���&�v�1Z�	ǹ�N�c	��J�il@���Q��7��]�[+�&f��?�{� ƕq�G���#����g�v���<���c�pP�cs |�Lp��i�۰�!R��J�@`�j�\���x������������R���Cu�n�E���я�8U5�C��`��7��7@Y�@j�_8Ѡ׾��A0yam����bOc(^��n��������OR0��9��e;S�K3�g�co�AH���-��c�Dr4Ƅ��گv(���,�sM�>!���<�>���{x�Cq�J�����hN����	txu6//�(Z|zcZ���W(����S�� �KL�����x<��k0�U��̰n.������Ҟ�
��5w�S�� V�ޒ�:Ϻc�X��y�>*ݕ�2F�LVd���\�Z���"	� Vz���._��x���X��bM������ڴTjl8�.��;�@q�������4�m->�*6,���|�����d�L�.r��֊j��8��2{$)ɑ�ۢ�\g��7����a2�i�ַ�Q5��,/�96B�xMa*Ҙp},=Ͼf�;����,'����'􇇍�?
�����֕��Аhy���B�\����F,_F��"U��"���e�J��uM��$Dyi۹�dӊM7�k��k��`Sm0m�B�*�m�
g�%?a//`|ӕ\Z�;xj��Y�L�f�Զ�;m���
�9d����	n��lk����%�����Oc�ؔ}I��YX�.~W��&Ϙ�*?�(�� ���$!l�R:��ب�eY
�E��g�˅��#��n��E'�@>����y���S�����QL^Z�E�؛-�y���=!�xkB���ѝ�����K~nV����h\>�����O�h�9|�dt��g+P����q��!��:)�A���]�_10Ȍ�].��ଔf*�6P;t,�N��\E���2�� Q����)&]��bL������;���2Ž�ռ��R�E_��v�4�߃�:��//�X/������E0*_
ζ�ɺ_�;em?�оYK�!���׾^��Re�x3*4\�G���3*���L���l����K��r�nI9���~�d���F�����9 a^A ��M%�9~8b��A���b�`z�����N�JUȈ���I-��b����NV�#`蘛��2$�:��z�G�::�^�����9�l�m2��O���5���h�.�7.nqZ���-U�&Tρ��	��+�(��a'�'=grj0�*ԿT�;��@uc����^�_�t�[��j��\�C�`l��X�4�P�+ kݿX�S��� ڬ�[�dֵ�n�:�������,�9:���$���N
3����d�3�fz�Fl��i��7�/�Ń�Q�F�&�a;�>?�.�&���$���ɬ���W-��bᠰ�}�OZHOd5-2;U�H#J���33��0�G�P���9MzdfʋV�ym�s�� �T�>)���Ӕ ��Y�>2%�~������b�D�2�A�ߝ��m~�?D~c�F�E��*�X��ǽ(�-���R2�}K��UNY(��_��5B"�=o�(`�6��ګ�3$�I�N��1{b��v`�e��*s��<H�J��#<'��MЊ �Z�Q�-s+����k:Q�����5�W�,��c�pE�˓�1RIx�"�������ז7���Z�>�*�)����A�"�=Ęe����t��fmy�fĂ�#��n�8���8�������T����]���f'���s]��O���ʬU�*�9O�"��L��t?�|~�wp�%�/�ef�w&�cc�7RW���:nP��4䭔
4v,V��I�U)~�c��E֜p���|sG7��ܽ\>9���Iy?�oےk{a_F�A�!�}H��'������o�� b��&�g�w�����ޛ�%�9CF�NR��*E�Șm<S �gS˵�g���0p�eO�~>��=��?�Sb����&��Q�V��ih��׆5On��3xG�(]��On�;4�I�~}�~���:��w]���v-�*�z}1�#*a�)�*(J'TJt�')D��!��y(%�Q��$�'hjW�c|Ø�]z��p�1�iڐ@�tZ������Nn2�Smdzl�cY�X�����i`��b%>��S��2~���5��I�|u�5.JH9�u��Q��\>�'�N8���[9�A:DD��t�?ǜ�#�L"�H	]�B:�Ð�:�$��"�?����O����|�� ��"t�c	�Ljg�Ѥ�[/�8t�	�0v��S��@����k�:*
�[��Bg0��(���y$�a˛�bNtiDˡy��3�c�86͂�u�R+92��"�bV��a�}Q%��ױZ�A�a���P�fN'd�GJ����j�֢O.Ex����Y&-���!zkG�������3Hփ��%��@�vl���eHy2�S����EݪG�~@苰���4k�d%�:w
^
U}U��Xs0|����Y~@6��͖��DM?2�k�y*�
W�&�E@Yy~Q�m�� {�����X�̺:�eO>X��M�7��ba�VÛ��Nx���E㐣����T������a5:Ϙ�䕞��jp�-]��`�\B;��q@�Ѥ�v3���`��黦v� �i�^.!yO��?܃�1lND:>�d ��5��NS��9ZF�����A�CO�W"��{��;O�,�v<oՋErm/��$��G&�組/�`N�վ��G:Cw�U�{8�V #��m�0�g5j�V����9c���s���iS蓣[��oߕ�/vݗ����sb��`�i$�߶��bHA�!�]�0ah��8��u��9₝n�%�ד� ��O�J�Z�idఇ�C��M^�w	��@�<�*���a�+hHS�}%�Y5oA��^�a�2�}Ap��2�AfS�oR���� �d�6�Č	3V���nY�}o�S͘a������3^���v�&?�Ms�(e�%f�1@'?�nep��:I��;�D�Gӂ��V��]t������=��β����6�x��+���ve�/e�Sʮ~d��Qb��^W�ad~�J35�N���l���]�I�(r�C�iW�g�Ql6^��Y���y��F��J�ĥe�y�5K�|����O�p��I��ep���&���i���Z��q�U�v�g��b���S�o��"E��?�xX�F�����9���\����O �>*�^�)��I؀�������k��+ONizP�a��csm�\�D����C� �`��P��/�������sPU��ʫ��M��,S�0&��YEgJ�����-���s��������J�Yi(� �6)�>G�׶�F�lK��?Ēsw��m�_��rLO34�@�`��t$�Z����h6�2Ռ�:�_~/ ���Ymg��.�c�6`�)W�L摪��r��@��W�6���E�61��X������-���Xu���3�?���N��H� ߾���Sj�2��x�!>u�Ȕ�>�ē�Zz��(BNj�6�����ָ��$��ͮ1�zp��҈;Ʈt�(Ys�1�����G��+@��f��(j>m�k�����H�p�+Ot���?���\i(jYK�@��F�m�5�I�7���lc���Ƥ#0c�U����N�bAI��$��{y�ozg��s��{%�ǏS�Z��Qz�L��.8�Y�,��z҆����Y��[�9G�n�{�gS�!{-\09��HЌ=ֻa�z�U�%@uNK���z��A�#�&@���Mx��f��2K�}hux�E�/N�"������8s5.���)�z��H�K�j3���{b	�> Ju��
�s��gg���}���O6���>��i��Ó��{�}�ʸd�>ۓ�rb����2�o�ʔ���X��V�Og��!a.N;i	���E�N���V��u�kwG���ȋ���������ay&����4-��9Y&�]	�`-�5T����h1J�6�#]-ѠQ�Ôճ�>Kߕj�<���C�#��?B%�)��P�䗀u|��Er��Q)����'�VqX"��ߧ�s�1�����M.�X�W[*B�5�'5=e�a:qw,0�w�G�y�-��b��T��x�u���u�M
��=�ױ��x=�NQ�S�D����� ?&ʅ}v�2g��*�w⑵�7�䂬���Ij�M�ٞ: �j��Ѻ�^9��v|�gt��Y1T���j<�Z8!�;��l1�q�_�`�|�[��V�B�Pk�����U�OM�������9�^ڏ=�j��cN*xǩ��Q�M�9^�,���´\��^�h�����6�l��UM]Ǚ�2��g����[�t�=��� 0���?#�}��UDBE��qم�>'�	��>^cM}}�+
m�")���(��`��V��,��~$��c�����hvg��P���$	��,ț����D��F�mm�^�1�R��-��Bɺ-�R��S��s�Ke��c�`��	,��Jr�L�z_�R��v���y(�w��0H	B]R����bc~6���w7*�4���G����+����g�g;��2�*݃< �@s�5:Ef�ݖB��L��J]j9�P&��	���Y��IϬ,"��%Wڷ-C��y<�cU���F����ʸ�<��*������7��O_���0�A�j&C��\�#r���s� 1�"3{� a,��7W ��p���$����c"�W��L���f'ٵ�U�Y�|�7u�ޟij�.���H�<�Aя%��	�{L��"o�Yq�f_�#[��ђ�#�YGq;����l�n��o���:�4��
�
'] yŗ�K���� r�*��.� �*BlP��[eDhݷ��=�r��j�O+bu:o��3x� �~�0F������{U��5���'��!�vi��<�HE�%��O�{F��]��r���Qɰ�O�Z8�ك�D#o�jj�Q��U�nȇ��2����>���[���Tr�,�ҽ*����{��(�q�h1`�,
�������R?�?I�G�"F���kbA~�!lѽ�]cR��gK�Q���7��t����~�u�mk��~�����	���*�C����1U�����6k�Q��Yi���;��k��LM�^{.Ź��~O�PMc��[������A�S>�.�����E�!�3P{�A�or��O]�=�;Y������{)��G���~R�us/���^{���iQ(�̻��s��&'�.Vh��%B@>9g��w%#p6? �k�-e�%�1�/_�d�%R��78&0A�&����"Ό�
ÄD�wc_�8,'����H���5D<&��G���9��7���g�㌿	������ܾ�M�~wN[����,ۛ!��K�3ʟ�����-������c��2����?^4��V��>⿰��;�"O����Iƞ�p�ⷘ�e�d��m�����JI(����h��>)��]E 85��vU�ovc$E���i�A�j���Fb���T��a���ި��ǚ�JT����4Of���+��L밹��">M��:�0�t�]�GD����(߮�mޡ��f�ߧ�s<�bb�*����"d<�ky(Y?��]���_�!!�w���]?����	C��U�.��Iޅ��2�*���؃Y�DԪd���#SK���rx����C_�&&���e�<�n�t��*Z��?��R�+o�TGﺋ�{�!�`P#kr܇j��� �5�ט�v�7��5��RO[	�/����c�&�Kd0�h���R8���e5���~�	U�L������S������&���:�4��S�GŢ����o~�E��_i���+׸��j�8�c����C��D��oL�}��]����n�F
��M8I=���=v;G��ӸR+Eq���`�Eu�k�^��pVIȅ�a:^����Vd��2a�iJ����|bes�6��*�s��!?��BDQqt���L��h��UoQ���������T}���ݯ�4:
8��[5x:R6[�����\W���q�U������c�|Kj>pc�ƴ��]���П뒘~�����%�O����f_����: �C��>dK3�)�r��`n�E�)8�C%ҷ d��x��]�x�����;qZ�� o6ďI�whg�t�j&���q��>�Jk}k��Ӊ�(�ႉ�Y>=�_�;#����%wVn��>E��\8i�o77�R�#���B���^�Q�8'���-n�pJ�"��d�L��7Ԉ&R�u�)~D���f��c ��[��m� �n�"�&AQ���2p
�YN��$#���~��f�Tq��h��t����E��t��;jqT㲊q���wҝC��!x�aa��\���h��� hV��Yj\�P��NQ�\Y#n!B��l;��e�(P$Ԟ�wq3�>�.�D� ��R����A���^��q�� ���9U�F�T�I��l)S9hñQǅ�o�z�i�~nq��Z���rrSz�+Qm90�kZ.g����=�R�o�]�� �.pP��t�H�B�s���ܛ=���kz&�����!8
��D�oj��G��R��"a׍pb�0�3�tp%l �#���~�E��:��i����?O�ng�Vc�?B������9.	�%ӻ�L�Y�Pp@��̾�g�8 �>BW���xd6p-jm;Sw��}��D �gc�`	�eᗹ)���RS�L�x�o�XhS�'�*6q.�f`pю�����\��|T��Ch�2R˵�wϭ��q�)�	R�p�s ᇵ�f�����$c��Ki�hg��3��Z�����m%3*Kn� ��"�|�3J35f=ζ�@�A3�X�,_�TN�b��z��,hg4�/�!>>0��~=��ǚ�p�)���8���>�0��>��}=���h�p|���7�n�#H�s�8��_�_gj/I�M��y"E���+��c�%x¥��@ �;;�]ON��3�i��0�Ҭ����;m��
�>�0=h69+!�/p�Sf��t�Nr�>i1���A�� ���I�7�4�wz�CI��1d�[J��G��;��mGGő��ͽ>�@� (�Ӂ�5�n&b�^�H��c�5吆ْ'�F�>��*�_E���b�xؗ'@~4�Rr����p��������-G�����%m_/���Tz��L-�4CcZ���c��#
8d�ʃ�,�;���݁�~[/���S��5�W���ٳ�#��;	����7gߣ�4�-$|ߞ^��-c��^XL�h{5��ٜ�ڣ��ñ���J���Zd�Nvc@s{m3|)B��	#�[�1��p�^6����&ۈ�͂26�6���̣AWi/GLam�t^&Zۗ�Pǟ7E e���:�v���.��+�#6�je���%iL��]�,>@� ��9(Ќ�`���2D��J8 ��+fu""��C�c
vl�K�
]`]�W�F�9 d���Amm�[��׃-�GZ�~��fȮ^p���fXm��^c�Z, ��M��ŋ�H�����T
�>F�B|�U��r4���bj�~O����N�V�ʜ)�>�f��a���:P���������H��$�喇a�>I�C������B�/�e����R� {�ĈJɰ�f�h���=c�����\*3B���Z(���h!��2h��R���'w5Lշ��̾�$�����6H%�w���!7	��=O����e��!��W��d]��ҏ>ҢE�xJY���̾�/�����Mb�K��5�ﱍ."�n/P���m+$���W�z�6)����D���e7�c�:�g5���18�z����j\��_����?ڲg,y�am�0�	��8����tsS���%��:�iC�(�SY<��nH6c�Xfẗ8���Y�7a��:t9�NQ�
0�Mh�5���n���&KJ8ne`�'�0yq���v�LJuu��g��y�@S���i��"�t�A�e� �&L����^[�L�PЃ�	�E�
�JId���(`ֳ5G60}�6�!�9�&���门*�Y�c�05ĝ�3;ѧf�E/K�˝��֤�fG�=�{8�������ZO��yC%1�/`��3JO��t��^P�&K��'LapJ��4xC�[/wO�#��O??S�����o=H�3#��0@4��o$����� hӈqꃁM�6�>J4�;�l��/����n��o�vb�3Ŷ�Qv��绒�64��S8�
?�T���E��F�Z�Q�@o{7<K��H���!@����@�l&M�fQ�I�����;O�E5��yT��=0�,��|{$�7�1%����$pY#G3����X�p�*���x���G&I�
��}˷J���7�����'�sŃ��k�|axh����S��=�J�m�i�|�3]�#���&�<>+y�l�4�_lw�~T����t��r�E��`q�vp��zIN�o+�����E�-�>���sbC2?�^]/�;����v��Ȥj�]���/wH4�p�!�A�{T�w�
rߔ�o�������XtU��>q�	=&��M"�oe��R'�v̛f�V��`��#��?v�Ҫ�
�(�
�a+BY���#��~[[Q�{�]���.�(s���d��07��2��r�U#��`y�F�I��P�8�e�}8�q)q�?�e[�0gh�D�p�5�	����)<F�ȥ
9$���U+�A,K�$x)eц����A��o����V��%5�T�D��ˌ�|)g��t�E�1k�Py���z���r{��ơV<U�c+6�j?Y+?��1�j_9[Ya���t)�ˌ|����Q�_ss��O�Xӽ�j�b��&Kl�j�������6N�av��n ��`*F��%���iuɭd��q��a��/�έ���Z�2�N����a�R �����3!r���*y�ͷ���5G캶��Ⱥ� Wg0�;}�8f<�v���+f���^q���3���N�ۇ��!�a��A���k��&�6h�e]���X��UސCB�L?{L������Rڕވd�a��Ћ4�߂Y)y���2��1�����L�s����l��n�u��Y�j��7Q�U�T���x�\,ez��<2�V  ���A�Awk)Fq��.ϫYc?:��F����:�4��G���.w�j��<�r���Λ�X���{.��6��#��L�Eί
cV=:"gf�Jd�X����i��ˏ}O�``��)�Lj<�$Zw�8�����W�F�凜ۅ��a�+5�%E����>%Iǯㆶ�k��\�U�ފA�r����&'v�h�UX	C��~�D�
'Ց1�7�D����*�;�/۞��mm��|匉{6�Y<E����Տh���n��%�����,Y��0����?
�B̫��*ǰs�&�ޚ�
-3��2F���?�'�7يԱ{�� M#�dRI�"k�I��A,�H������+�%���F�φ�zx�$QY<�+�лH55on���9��zf��>�=T)��#����h�������_7��&3u��}��Bra|7O�������\��V���0KuR!�LH)W "6ƶ�%~0�d��U
����֝�BrCh͌��	,qvGm{��� ȝG�+�vV�h|���8c� ]䱾��ر����N�V^Q �`d�� �����v���H���p?]ɍ�7m�����)���Z�{��gz�@�r2���!p�>sngM�Ѱ*s�oY+�O��<b��Z*�4�1'�0�1�Υ~��3H��x>c�=�N�@uH��Q����I���"�{��S�J ���߆�m6��(?�b	Iv"Oa���l럆��gt/	�2m����7��,��{ɛ<w���R��G��#��#|Ҟ�&oZ�NAL;~90�s^���Į/��D}MwH��5���yϹ��vP�#M����<����RJ��J�o���C�A=����;U�)w1��4����V�F��I���L�A{����!X��]�R�/)����Tɶ[�U>��n
�>��WLAR'���>���x�SK�&���c�>��yf�p+�jy���;���;��k0Rҫ�_玹��
����F郜q����gW���|"����D����q�<�b�j}��^�9j쇆HF�:=�Ƣ�"��D�YIEm�u�L&&�FU0�w�X*h��=�'Pl]���+)|{�ڊ$�e�G�a�2o����o��ν�$Tqc7kl�N���JS� ���H�I����	τLj�pq��l8�3�ߍ`��{�hNʊ�/$�X=��~��.m�e���J;9�u�|D�sz��:�@7�צz��"_�֧5��.綥��t��3�{�fV��(�,�5)�Ǻ�^��QX�%3oP�!y���1U��d��zY!A��E�悺n�|�� ��߭a�TÀß�4���m<�_W�����`R9��C5�c�;���4��'����:�`���L�Ε�Z$vpJ�s���m0��l�:��]�,�^�C������Px��g&c�g�o��īBn�2�xwx]�H���T鴧��� Ӻp�UE~�1G�P}��ܵV��Lʇ:wWzD���ݶe G��?v&�b˼�
��䠟��w5k_�TlE�\I_�ocF����U@�8�s�u��!���_�>u���"K�}=ه�{O䘽ȗ�/��P������P�(���`K�CMe���3�%���̖��	j��&E2?���>���!��U�R'e�bV*���f�&���j�hi��7r�×��sǾEf��{��,�'��Č���ީ��=}�����E�f(V���
�F�Tv����x}�z� �wg(�4�h�>Ɨ!2�-�H�,痯Y>ɒ�L�p��!��V\�U��:Z�U٠�Ug$�6K�֯f�-�E��f&�D�M��DNr*��a#�i�^؀���q>�x�����}��7�-�]���iE�P{҇�k�qo����jZs�g���8��\4�W� ��#O���xp�od~8g��ه��Vt��p�� �����i�RW�}%��>qX�{ ;_Ԏa�����f�n���]�������=�e?�Jlϼ5r(U����}�U��0�f2��s�G�num�� �:)�K`ac�i����/�g#ZB�L_�,w���
��k�T���������t���m��,}�M�5�MQQ�;�G�%�������c�g��/����2�Ycd�p��/VP����X�/�uf8fMC�O>�pG<�$�3E�� [=|Q�����4(ֵ{ ����Q5�؛c�警��@�S���\\#Y�v*�P��a%�dvG1ĀP�S�3*w�,:��I�w�ߚD�!lj���O���v��`����+Q�Y�^\ ,PJv��+�r˭:߷�!vښ+Q��l�S�!�o�v}�uEd��Ϥ�ڑ"HE�=�`�4��&��X�C콏������j��"YM;5�
p�G�Y�k")]P�Z��ؓ�B����Ŷ�[����.WF`�f��t����T{�"��U�AK˭�'��V$QFhRYP|�\�BW�d�H\S��xJV��k�.��!���/�-�e��(����L�U���{	x�n��C5͒�N��%���3s����=Vэ�r ����_8��U'L^_�ZHm`y�����+n� �e���JD@�f�5"��Q���'���sDC'M��=x)���c���&�f󅶠v�ߋ�c�Q'��x�*��=��
ߋE�+��U��#4�hGl�pg�\��;�w��4�����ܡ�z7L&����ΐ�B6��g�����B�M�1��h^:O�*o���%n 9?3������*'��⟿$��"���~�9�`ye��F�X�"��VMv��G�.��{�b/��0I���P�޻�R�jES�}�(���+$��o������S���J��gBKq$���U�@�X��8�F��Mˏ`A�7o\[���   F�U�F�y ������W&��g�    YZ