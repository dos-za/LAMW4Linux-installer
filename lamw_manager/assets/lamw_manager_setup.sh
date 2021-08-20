#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3028324151"
MD5="01631d25971ddd07cca6878313452454"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23596"
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
	echo Date of packaging: Fri Aug 20 02:11:50 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�aq��\�!����$���d�S+�7MI.�gRFW�L)�줁�5!�;��h��MX�x��e>x_����j��*�'v(��B�H/��t9�7���؂��߈V��{^���lZ�����0��1��> AlT���5��.������f]CV^ⷄm.���S����1�RS�͚3خ|H�E��}��
 �H��to䊐ҥ|=��-͗��ԫ�g�L)0��S��>>�q��^�U�3À��>2H�fC��%Þ�Wv�[��i��1Zj�����	��-���r�m�z��8����$��8)�1�{ vɚ	Z��ۢ�7W�����Bk�|!~�}�M�П�McQBbY|s����Xxz}:��R§!y�?�FX�I�^T��"�jm���s���F���P�[�5�e�hr�}����o+N!��8����3ѼZ+����a�<P�ܲ�����/7D"�ێs;">���p>2�ڧ�˕o=/BN �-f+hݝeo
��a��(Ö��)�ŒȓA�C��9�wC�A���O�I
�Q���ac0��ge6��9bg��)⭢��+!:�7��T�W/���t4_EYA�{��]�o��ڲ'!�
3�:Y(x,�)^��E�j����I6�� /�2��Q��&ǥ5�Һ+E�q�����{��FS�ok���>ǈ�%�z Kg���Q�.�*�C��=	��6Sbm{=P�m�����3C�J`1����K���xذK�����s�U�#���R^�83c��n��oLhA�\�ZV�s����������
��v
\mZ��d�����R����v�==n=c�{��5����s�vYv)Y=�>`���E��Ɏt4�Bgi����Sv��z����&�Y�J�M�Ρ�c�n� �B��a�K����S���l�KG>s�;IМa�|z����l��D�>g2�ٙ��\k3�Ӯ8	��)�/�|� i�sｓ�#�J3^o��|����m&w}pGuƿl:��,�Y��� &x��-��}ƃ�
φ�'��DD�Ґk:�����F��xi��N��9�� ʞ@�O�����Ǫ_�K�d���J����q
����F|=�Ž�2.��+����k0��NP{Y_�ޓ=��"��.�^$��;K.a��gly��h��N!�ز[���Q�z�E�
��+B��Cߒ�����4|��� z\��c[���챒oۀ\E��;-�#"	��O�'��Q�ؠ^ۊ�%AAA�!��"
G+m��"��I,���Y��9بbj?�BEMׁ�Y#9�� �7�m/��V�!h�����!�Ƹ��D����,�s�y6V�2��j�3��`c���m�I�s�?��:>eS�L���I�]��5:B	o{>�O�U!�2l`r�|�6��i1l�vU�#N��QL�w-�(��+ThN�w7����D� ���x��m�ɴ��AM]��D�3Z��&���Pp�q$�&D�Ի��?�Wè3�r��w�����u�o�K�����Y��E�`�J�2 ��u���=����{��cջ��X�� v@�R�3�=朙ǆ�ꐳ��|��͙��Xg� �q�����?�`x�7r���[�Y�5ȱ�[�g������n��=�0t5MUJx�ES���?��������H�'�>ָS�b8����,�U c�&�8y\2=)�������&Ht�_^3O�1�Q�O���T��P?8�"�H�V }�ץ��7* �T��`B�t61ۿ'��L�f"�!��MQ�I3�CR�b,�M� [(�Z�-���_�Q�m*��f��67�
I�c�=����m$��]�����F��������^^�����[���GdX��ړ���پGpɍ�2�7���LAR l\�R㐽�!L$遾^g�e��_f`o��ہ�mٷ��)�"����k�:M��x���3i��;����z�7�{���S��5�'_g��`�E�����f�dG;<(�^ǍP��$u͔����dI���2Y�h�3�p��O���H�������������;	��(Az#L$F�<��*q���Kz�����_�3���靬�զ�Cx�S�7�v�:�Lo�ԋ�F�A��M,�aޤ�π��E���=��&�+Zb��z�F���=�ntԋ���Ű���獻�rnDk��|�]�!�z��C��_�l�W�#�q"	��T�A��"����k���F`��[S���3.�tX6t��A�J���&^�۹�@^������U�< ��V����"��r$��.��n
E���:3�|@�M���*�D���]9���a<�1�#��Fzm5�~��^N�@���R�LeU���j���~�ܶ56�I�s��lT�W48,D�.�D�H�/�=N��u�<YT��ɍ�n\���l��=�\C<��dYrs�'�H`4l�T� ��V=P���#�Uڷ�&�\{�=h��Gs~,p+�r�T�|}�{z�l��\���Z/�(�;AR��T�9�#�������>�đ���*	
+��b��,!��@�
c/@�����yH�'e[�ѭA�Cc|&ә�&U�'��>��_Tn��Ob�"����d�֞uzQw����,��8��������^k;����&�xr���_��Q�!#Ҝǋn�K/}�X�YQy%ݤM�B�i�_bNj������b�Q���!��S	�?5u�ˎ���H��n��� �g\���/��a(��%�Ms��v�M���c�c�A�`\k;�O;����?\�Jl;ތaa�,߲�밥ӿ�j<�V�b����*���x�d:��8;nmN�G���	QX�����'N.0�*[i�D��Un��ǈF�|��~�Ħ}��ao�$gd��x6��X�lk��w�jB����� ,{%C�[x���]�R:/*����}��--޳�B�2�'����W�?f�0l�[k[tשNej�[y^
rA��� 3�=1��1�J�_x����U��z��R����!
��Z�F�dy��4��.8ȓ �(��^RkMI꘥�2����4p�(�����C%��
�#XU�>&`H-K�z!�T<��`Dߩ�v{��G>��δ����Y�����ǳ�8&����uq{�O\� ﴧw%�7`�S$Ӛ/���ē0:��%���v�R�e�feȳ{����7�<VEk�'v�}���lRM��ܶU��ᴰj�:��}�[�G�j��/��.k!�L��O�HP®-V1T���bo�hN���[�rM�w����,݈���g[��_�� V��� C�@�����{y�U�����?s����R����:���w;�A}i@N���!P�C~Ђo@A�k�rDl����c''�c���h�a�B5*��O�iȈM�� �Cݓ��p��Si�g��qCA AW�+7-�5�B(/�	_�� %����>G���U[�������7m97w_�&�c���0�>���،?�I��_�륻+|� �R 2<������������!�b�v3S]�F&(ش��K����k��� �)7	����u���u�d(	��u���t���4�H�ښ0�4X�a��%�l�D�D~�EA�)_�~��&	����q��dL^��3�5i�6��'���%���/�f�a�)Asx��n��ΔJh	6���_�`�O �^��7�<��q�ބ�[ډ�T�m. ��`���`��`�_9���9�z�ل����1��Ty�3�B�嗛�΃�1ڷnC��[/X��.�n��	��}��N������n��aѩv8�?5C'r����Q��=DSOtɨ}�Z|ǘ�2�$��z�Xt7�*������a�m�Z/�F~���i�f'EM7-)�ܫ�ˆ����T~��iQ��:'1�_3�hZC��ݘAT
Rn�����`3�*�f#��q��R2���. ��]�ƹ�q���j��,N�T�qU�fe8Ed2O+�s��	����zȰ�����0#�Vgb�x�o�^�QR�\������*k�p��diT1�]u�5V�l��F%���Y'"�Z���4R��˩�"���)\>"H�_���.%(!�����e4�0���u�s�K�m%�^H�A6��ky��p�d��O�~�v�D>m���#�i����V<g�Ŕ�l-��H��G�ͅ���j��W��i�$c�+H�W�ր��h#T�!8��>
���C��SY��6�¼j����|S��˳+(I����+�nT6!R�=hI1搫�	�|bS���&h���cN��d>�bݾl���/ ���۱r�mZ^�c
� �٣\�!	���z����1r� �2�g� N��h�&�ʲe��ި��ؽ��u��Uk��W�D�P�~�Nt��c}�]\=�!�!�8��� ��e5Ze�M&{7	���H��>��Q@G��@��}eri���B_��D"�89{�r���p�*�!s�;d�[E§ɿ%(��qS��dMa�Kix��es��$��ǁ?s�nf���
Q� ������:�������;�窬�?ꥎ���Pw�Ϙ�^��x�e_�I��{��������{�J[��_��IU�����$�
P��I�*�}�A�U@�h]i<)��')~�)9����<�;=I�KiU�M)��/�=f� �ǌn��[D��Kw^\*��b�74��r�+:z� ��|Y0k�$��i�W:��F�/��Ӡih��ֱ9�E�ɫ�|6_�T�&�=���F@����Ң�0�
�,�:�~,��p�4��Z�\��7L�� �G��=/r�9oyx�z��C���+C؉�S��� ~A6�x�y�L�p]���ɮE8�E%�PN�}B�����z�0gwm��]�Y�@�j�=3����J70�Br���f!��a#�~�e,{-j�
qB�egZ�fm�˟!
v=�����8⛳�5a��=1�U<����3ԧ�f�P����!QW��7��֔~�tU���z�-R�n��U�<�`i��>t�:/��׮:�ud0 󘉢Yְ� �\?��v����[+[�V�^�[�J���0�Ҳ�iK�!�[��
�+&����Q�5u�Sb�M�DM�8 ?�u�v�=4���W]b��.�?�M�����2�����9$0�\CԖ/��@���\�ZS����9�xp�Qq��+}=A�L$i�mzpg���N�6��x�!vZ}�G��8��~����슴�^�UB�� �
(�m�o*�:�Ŗ��ۦ��ȋ8RE�^QkvK��m�k������؋h�WG����PEyR��v��{�v[	��y�P�(�q�#ר��G S{���ױ.^Xxq�+_�/�n�3�J�s.�s]θh��!bqRI@����5='�:�2����|~o@����JoJ
�������21� �D�f!���VG�V{%O@���̘���es)WFp����gUo,��_�������E����7sC���y������
v� �j}oj��;t�6������ �f�N7�c�'�ӊ�{A0��$1b�:9z���7]#��B���9��Y�YN|�I0�,�����q	g�Ie�"�Y�%�5E��1O�@2zaYQ���ֿ��8��J�`��J���4��(�N�'�H�<7 ~ �%���a��xK��p�\	y���2W��ɢ����p̒/������T:^E�Ź�N�(Q�y/	�������0#i?����K;]���kh���1�rL���;I�c�E`E*�h�r�U!�E�l䏗���Q�W���;���ǣne ���7��ܓ�����E6��Z)<1�_+B̏���b��m��ه�j5��ft�^����Q��R"ʃqm�)��Ѥ*C��ܔsT��F?�-���,��R)0X�D���"������@���Z��u���5��ڂy�=�ț:W���!9v�V��8G��t=on��F��E�#�T�}�T��2d����� +?�z6"�4W�@��n� �U�k�_t��A��bQC:�#g�l0Yrq���d�'	�hb)�(l�cPnr	\�{����N�ߤ�y���!HZ��6�@2	b���H����7�@wVOr!�ҟAC�3)OгK�+乫���ӌ����¸D2C�Q�M���?�0l��ق]�����)�?5Yy�>��҉�*`އ��0[o+V&k~%y�Q AŘN���ٖ� 
�v[�����7~�
������F�r�`��Qf����6�7�����#\����|nr̰��a0����ed����=��\"�U!]�s���ԯ��q\s��3���,ȋ�P�ck<l��<���1���ff��u�F����z=7ϡU��R�up ������m�Uw��s�2
�x���h���+�}�G��j�e�^�N�P�e�5��Oqj5�ɿ�$E\#�`�=b��5�S����<D̫q��Sr��7����_�s]�}�b��/*!Ƃ�OA2m
��M�Z*�Yd��Θ��[��+�����?
��,o:>ma�]z�!0+V]���2��0e��?���e}�Z���)��,09����^���f�!�WEi���rKI8�N���>����^z��q�2[����v^ba]�R5,�Ӵ��C9�q-r��n����ml~`�O�vO?獗�Ճ	ď�WDFSZ�dZ��v��d�o�o1l�ē�{�d~h�1��5�qc�3����#(I64,�8u��^xr9�q3�<41�)�L&��5�`Z�1گ�n�Z�������z�Q����< &2O(�勻ކ}��R'���둪��B:躡��k͋�G'�:t���:�7|� �#������.B���ՔnieW��u�/8r�����?`JRp���7��HC�]%W��w ����Y�&|�Ȁ���36�4mK^��ʧ�t��y@Aݱ<|	�蠔�>7�1{Z�=6��lah���4�����y{" o|��_-\���=)�ϴj�1�O[H�a�$L@���ъ�EO��"�)�aD�<XEYn�5�4�e��<�f�l˦Yu��:������ƒ�+���=��I,H�ɰw6A���L��1�Pze��-�P�R1��/u[o2���ڸ�>�[�_+<E�!7�|~��ӣ��TM��r6P-�n-E���k r�]1�{g/+i̅7�C}gS���h~�~���m��0=��%d��,ǼB1�.ߵ�������x
��7$ŁxT����zDO�D���I�P��M����[��gH�}�~Aj�5��{ƃ�0�b�I�BfC�C.L��$�$T���Y��Z����������/�N�Y�\7��{1ȋmx�]���9����(��RHq��2�y�vk�=-qb�QE�t�"o��5�����	�jD͔�g=��~QW%k�0���6��i�Yfz���4�ҡ	V�q�ݓ�+�)�Z���#���F���W���]5@j����16'��	�/������M����I[�B��y��Q�A&�Q*�k��jUΘf��z��U��
�:<˟f�z���n���M}����(ؤ��)ܕ�g�q*5�E$"��gy���{�)we�+7)㝷ڈ���Zk� �K��oށUfDP�6��7U�.�V[2E�p����[�t�~��˵Yni��V6���?�؝2�|�� �!�����Cn:�B1@�nY7�y���80�d���~��Qi�t���5��g��o�R�8��6p�=��q�>Y�A%�uI���;��p�RLE-z~6Li���T�;	ߓ�{I��F
z�>$�UEJ���np3�d|��\m����Rn@���\�0�^���폋6��i+� ϟ�9��n�Y~r�mT:��k��4`���l���|�A8����ɱ��a�hh���=(�������5]?y6+l��=�K����%l!6�UN�?�[�濃ї��K�ۤh!��-&������T���S��q�N���ĝ���]|yٔ���UV>n0�uR��H�֬��5����Y�3���'!�G��$W�l�z�FFl_�`z��؍��J��aъsH��c4�f]Ћ�_�-,�}%��MUS4iC�ڇ+`M���df�64j�D��&?�Pm��;/�9�:3��X��M�q��֨3��
��_;Ѽ�A��m�>2�L�y��Sa���0q���$�=�{�霋k��!m�3i�P�<8g�4rW'8�-]���%1bL�q	+�w#��f8T\��xn�R�s6�.i�?[=�;���_|�F�b@>��6nl��]�T�Ǹ���M3�	�p�������i��@���Π�[�	Zʮ�k�k{�'���B��ϜԈ����W�r�N�a��?6��(-&K�Yhyti��_��w؉��d,�kX��������Y�Q�Z��E(��������9��4w"Q��@i��-�S+�O��P�E���LD����x��>>��h1s/3���(q1]�M����g?�}�n���9fD&��w�Z�1�:�$�wDN�ev���-�G0)������};a���r2{v[o=!k�C�s:�m I�P�g�x�Vf9%��R��B�QT.�&���M�Қ�sh�E#5��Tv-�a�m��=�4lQ�L9\��G3�M��B�Y-!��`h��g���>[`�5�WQA��0r`�����Hu�����nBsn%�OHc�����#7-&��a!�U�-�!!J_(�e"�@�pјh�K�~,�>L�1X��p�z��:$R9)��1U�������׏�@�/i	����.��(dk��vr�ͩ� oC�@� pC�b{9���4�@ǉt(SI۳�8���`䩽��M��-as6{���&% ��^�A�YO�>�����sқGZG�U�qq���6�����!���j�"\��(v�ʽ-(�I����4���6S���m�9����Hg��1^d����U�5]j}=�`�^٠rt�ѧ�݀��i��c�b�+o�*���[L͇�G3O�df��Nze� ���KH���#�=���x�P��
;�̡|kQ���	
H��$6��Ȓ���K��{��g��Z��Ý�����d�i?9Wn+���#E�Kn<hX�d|˅�O��)��֊���W�?����A�I�"��E�j��`��
ZB{��˹mx��a�b�LY��G����U�+Ltd*"�.$] ��#��D}��V�ȡ)�ڜ��+�#l6C�q��IxHX*/�}O�O(̥��_��B�#���G�͠�4�	�
6Y��o��NَL5�E�M)�P	�g8�
�B��F�(��.{k�rR�p3��WC �u;xˣay�4D'�F�{G����P�͉�G©2��#���bC} z�,$h��%@�I��˜��CS��g[�u�=���R���W�������2��OT$��4Hnew��5�;�؁C�e�9��Bd���N�U�cAȰ>�������7L�;��%�ŢI�^��	�^���߮�����huH��z,�������i��T^����^y	摐��y��,�Gp�$"�-�W'�|'��;�
o�Uq��aXg�1p��4���W\�sfi�ۼS~��u0"j(���r{�1埴�u�>RcGV�F�ﴋ��{]ߎ_�m���i�L�:��3�v�O}ܷm�<(���Lp�M��sa�4/��; Vp���Z��: Ud!�dng �j��3�W��b
�/�ܷ+x�����}�6��l;&fU�/�6��̝N���_K�e�Bq�T��_z.=�m­�"�MYs:"Ű��ֲܭ����==�{��;}DA+��ƥ�!Z���8n�T'�s����]��-�N-�o�C�!�����jnD��~��셀0oU�9�i��D���F�K��Y�Dΐ��H`b42E�8��DF��Z+~8����M&U ��?ý��>��]��.e��������>�ie�N;�Rj>���`_'%�RutE�r����X7/�U3�i˧�C��� i��m,����Ag��(�TQ�� B~E2��t|�B�
x^h�i{��Ev��=	!s�l�P#|�9]U�H�o�B�Ԝ:���/��s�(�)�G��x�l�c��1��=)�Tj�]k��K<�@7��As7��	����G(Җ���[4��h�/��Q�繴��l�.Loe������.�ɋ��U3��z��T�&@]t!�6hT���u�:����B�X�1Bt��/'����[�l��h�{aAb��cs��W�����r��5>��R_�X;Wt��l�jF�����֦�ڣ��N\9⎠=���{fѵ��/_N��R.��/��bqCk�pݚ]�L&�e0�˝����v�&���T%�|�U�U?��q�t-r=�caݔo~k���GCl��S:�SG��8�Gh�&�����~660�3�}I���#5`�ͦ�\� �B�-�U�Q%3�x:�sH"8���K��ha�DKI�'�p�*��W���Q���KW�_!zo�Մ�qt�q����2�6�������^�ֆ|�K��ܟ��@sR*�ʵys]��>s�`��O����<��Zjl�����w!�7p05#	����>����[u;�*�p�u6��t����پ� j{ ��@��ˏ��3����ac�Z=D�l���pL5�Ou`c�G��ͯ�'�ئT�7r�%r�5�M2�K|b4z��nJ��

�)�"����Qq��Y2i�<Sy�q���Ce���RL>J6��p6.�O�d���կoD���R�d��^\��8�pO&��ӻ�Ʃ�F����p����k~T��[��G%΀�}��AW��hfO���C�8�`��e�:�Y%��+ʝ����r�(��@~���{� &F,�IaL���;?��2�Kb]��ʽ{�m�}�X�I�K?D+|g(z�����	kv��3�<���^�~���T� �~3�ep��V��Ĕ���C)�A�S��Qͨ!����K��+���l�Py_䮈C�bk�2�PSc����-�>wh#Uo�!63�7�bf}��z0���6T	���?zŐ������O�\��1��Ib ��No*R>,��2�9��J��v-���F�'�Cn��2Zg�??����
2�bL�N�qx߄�Q	<���n-6Z��j�{$L�ě�>�b�}�M��S���*dQ���_*K�H�R��z�0q�Qs�:
��<������lBi\cMÔ�}jϖ�����M_����<��x��w��>��t�!
�]�v����%X�_GI�OV�;����d����U4��,v �O���$�_j|�yH��O�	��������fLV:)�;�w#�Vk�2�����-!�&!9v2�<����W{n��,���;�F�r7����U��e��~�9Ou?0T�����}�~Ɲ�[>>�-ֹ�����2T�I���@I9�`MZ-b՘�I����̆=ph7�=������qnBT.��a�7��?���+��<[+�[�\�b�k��gk��i�d�[�� z�*�Km�'�7i��] h�_K�
;��ns���A��t�>�3����������}qY���k�45Y��~H7$q_�¤�(T'|�RBRH�Z�#��*�<S��@��FL�X�H�L����������,"3==���X����W��K�7���N����{;�G�9�$?���|�>�s�Y@��'�i�"����a�ސ���r�Fk+3�1+�Y$�����)�w�;B^�M�����#E�x/�{�%FX�� oy�����W���������2S��G#��fx�&�p�/(�ǽ��[�8z�^�(��� ʊ�	+X'��%@���A](/?4�BBo��ۉS������6�,Mo���Re#��/z�6�]��kA�#R���z�u��s?mh�4�)�h�(����]�NR;�a#>�?@#�Gt����d%���7�]���1ȁ��:��݌��M����F#k���x��*(���]�������J奼����_��rK�wљ��q���
�Db����v��	��b�D��r����������F^����o�ϧ|	����s�d��O���ue��G��ͮQޠ^9�w��x�uY8��m8�'<��^�m�_G2p��EZ�5�$�$����L�/�
�*�"�oؼYǮ�ڟ �l��8��YHs8z�QiQJj%U�N�� A(K�S 9{��MRt��P�!���yDU�3�@V�߼n��(�n�>��W|z^̷�����G�o�(�|~d�D�
ћ�h�\d�kX��޼3�T���C��<���b�2!��&Aj˷�[�śy�NxY{��Ҁ�A��Ij'3��gkR��5�IK[jY�´'>`a5d�B������އ!J|]D8���G���I�)�8-��u����3�k��Q�D��"^�y��w�.�X,�ӝ�
���Ea�8f�5��O�{+.{9W*>���&yv�$����yr��鮜w!��d����0.��fȽ����I�K�+іh���������Z�>�&�f�Xt�,�d�p3�л����i ~�v<�������`,u�!��P���-��?��?�`�߂��M�1=(N�����!��
%�9�n=Ɂ'�Sk��By�)R:~�"� ���>利���MM�v��-��/�W�ɼ��MN*B�l�YZ" �:a$Igd����L��`����B����Q��#+�$��.;��Y�Y|#\4�Vq��h��c�Wy���猀��y�o�3�������Ey��ȳ�J��yCB`��֨AK\��rFG3.��u��Ć��x^IB�y�fC���l?'�w���o!c�����;JK�蕙CNb/�,� Ҩ�p����SJ̺d�;�VڟC=��D(+�w"Q���%hf�k<hy4��&�_��M���N���K`F���"��6�$���˜P�Ҍ���9���:����Yx[��_��(L��O=l~�'3=��TA"#�n�*��2��vh#{y����s3�_f�)�\4�� -���1����xڜ�k�V����A5���ES!2{:�a=4��w��SNĚ�㉿~��璛J��U�����/E[{�:Dn�Fl�{��0�����P� E�F���?����.�"#}X8� tȣ���D����O@�N�V�	�3�m}�ЪnuQƅ��h���-)pV���:�W藠%Ye\Z�����;��[Z��h�ߡ�=����>>I��i/RC3�`8_F�Gw��u('���-�l�LfeT�P���>W\��|��6�GW��>C��y����wz�i����F���G;A�àbF>.��"
�>��a�9��k��dn�sێb��A��I�o��y��ͦ%���.kN1kg)�>v%�sB8��4$CXn�E�Ƒ<�E�J.ֳ���]'gc�Ԓ�̜c0$a�ɴ�,�����+�.�%�~�ٳ���Z���gz��m�:`�"�d��W�uU�w�P��v�����cj+2���Q�Z~����Z�W�d�w2��ox��JH�4�'�q�ͦX��\m|��©ߴ~�$9�{R�-�7�K"��OΔzj�t�O���b>��ِf���a��]�hʗ��}�� �� S2	��%��;\�\�8��ڲ�������k�ц��&<��Ǐ��1�+������w�!pN/�9٬=+D:�����ZX�h���������'0���T�3[H�ºWh������L��;�Ҧ�+�q?�̦�[o��C��fnE��vj�:|1��+�<DJm~�a��O�x5�<T�
��5bh�7�0B>1x�7���Z ~���;|%�@�-L�V�*s1�/�[��;}�������<���a���G|Y�[
k�C}���IAm0�e��ȸM�{��6��a�xZQYh\�9�$�P�ʧ������ȁӫJ��:���ߍ;g��h/�8,�� ��DLQ�ތ-�� �`C_�²`�v�|��x�%�$���c$
��q}�@v���&de���*��q=h�:R���B%�⊳�c�1z�ZmQ��}�o����k�)D���SA�����Ԉ�@��4�( ��&x#�[�_T(�]�F�eB��:�Il�����`L����7��EK۸+G=e}��3	�f7��ܐԙN��!���=������J���Q��6n��2fh�[c(f<�]�am��--����h�g-�웿,gUt.�7&����,7�)P���1�G��[��I����-!�P�3#yD.�Y��YWv8��+�����Y�V�kԭ�gH�Zd����/�巛ٖ�2MX�R���WGN���$Z�@e��b^�������{�C��U��I�B`y_��T��?�3��mK�Δ0b��V�~\Va�P�Ǆ�a#���R,p�~���k��P���7�FV�ߧ�ϱ�Yq�ڛ����S�v}qtМ����WE������2���������x��Kg����]���F/�)����X���z\2AkQ�m��%�̇Z�Ʉ0H8ƊAU�f��?��;x�	�v�▄����R�:�jᾰq�����6�3m`׫};�@����C�!�a���(�,���Um@��To��}U��5����P����9lᙥ��@]��T�>�C�;�/x:Ԛ�~��Z=;%���;0��w��|���N�
~9��/���d`Z�N�j[���lmp)Aq�Z�.�N}�®�־�lU�-��R�!�g =澝Y�ƅQ���.�(gRn�88��H�*�P��%_�ɡG:uБ�{�B�5��?U}i`䠇�G��.@�L�6ex�ml�O?A^�P��YDA����޸���a���!�Ã^��rX�VQ�j��h�O�i� �Tt����@^`%�i�������r�<p�$�N�S��oͶN���͊�W�)�}N��\[4�;�s�C�Ի�Jdg叉ub딐�6F�9W#�	��b�Huo[����Xe���#@v-R~��tUڰ��i	Jσ" �ڻ���$��� ��5��ӄ�Tx���(�Б��Mw�]�D�#�Q�����o�k���G� ]!EЧ��T������pY>�s�Ô�4�z��g`�y�O�����S�W�*��E�>*�f4��(l�^CUN�6[m��楴�%a�#Q`�>Uv5�@�B$�'�����+P��X�y�	Ш��V;n!�7���^���MW�����Ę�L� ��*I�����O�qk&�z�y�����I�;�W���R{�7��\gێ�T*-������z��a&��x�#H�P/D��0=�>��g��?͵�>:��&۶��am��M��,4�E�ȴ��F���Yp)բ��r�k89���d<nl�>`3��`N��D{�*D�oV	�Ds�G�ԛI���՟53]>��T0N��J��zd*S���L0)�br7f��2zﴀ�i��҆� <��	�X3A 7��"����PI.GlHP-�o4!L�JA�9F0����\���x���<�nv���`����I
��J+@Q�Dy!�i����ji��Xnc�/!و6�jǗ��1׫�Z����4GM���	nY񢋷��9boI�&��Sc���TW���̢�
$��2�g�1~P?�8����jq�k�4��+~�l YRߞ;��YjO�lu�#g9��4�r�1��2E�������%T�b�����b�_v�(�lb��������6��am^Ym�Lǯ��F$f!�Nl�O�GA�aV6� ���<HPq1��d8T���F����A
2S�Q'�P��a���������H%#�vow�4����+�� ��=	>@�eʦRd�_�!p5�A�K>���|?�։���
����#f� X���A+͉BT*+ax��^��}���!I�.�␕Ԟ#�dQ��=�da��\Qj��y+SX�)�ɍ�o}��*t�d�w���V���l�J��6=�$/ŀX��d�����5�W_�_��b>� e��n�J+�4���$�0Ε7��W-+/�B%;�w���P(�MF���d���[���'o���#��_���\�_J�S&ER��UzU�$��A�����ʮ�4o'��6�pk�"�t��Q����8vĔ/߼r��
>���ݥ��9׀,UF`��D%���M��q^c�h�:�T�.��PE|J���_�7�B4%����slU^��~�}&�tـE�bYb�#�|$M�[�FvT�U�>xGR�M�S�D�hȮ*g@Lh"�����v�f�gq��*����(%���@�r��A�Dl!�'#ސ����zGt1��Α�&�f�za�M/ �z��,V@wU/�V�7�� �>�̸]�/��S	c*�@�t0pY����Nuc����^kc� DIG�N�|��2��F���iw�W��9X�r#�|��S9$��KR��|�;J<�ϙ"F��~Bޝ����I��!y�¯q��A7���Ͻ4�91�pɢj�����/�����%񤙟���4 #��[�<�s�4�]��K��G��'��P�v�E��丐�Ji'ía�U�s���yXÕ;4`]�0* �KTF��B��%����<x��J)���t�
�R�#FJ���t�F]���$T��:������~HE�*p"�$p��;k��e����t�V��(�9����ir�,����kҎf��\�D8�(�e��Cԛ[�J{a�;�
Py=��Y�.�p蓦����C���1���Y���J.eJ���E��*��U�8؉)�`�ɨ�̄V��^+�4ҎC�=�HQ �a����g���<�L����Z�=t�ZLo��<��VZJ�~u��h(t^�+X���G�X�G2N@W�L�D�u���Z�}Z��S���L�y@ �C
-l%��Д@"Ӑc��r��]��)�n�����H�K� ��`�����_�U)� o��z�}��Q>���hm�[5H+�H�r�縬�42O14�,�?;פhȒg�'#VO;�F0�)�lz}T%�C�%����Sm��g�]���&��2��BZ�FbM�6����C׋<@����p���%]���j��$��:'S��;�\� �F�t��N ����q�٭ͭ��u[�԰�}����[������MI^M�Yc��\�g�C�A��/�ɉ=�~� {i:EG��V޼��uy7?�w�q�C@�0Z������c�.g��g��؛gP�����U!�f��J+���"��<z������g�ge[�V�>yʮ0���VRh�/K֒^%���TJ}cѱ�츁ui���ho
b�ʣ�hdF��of���8��|���9+��:�ʍF�����+�9�� ��R���}םڜ����
���}|ù�~�x<��ҳ�Q����؆~��ȹ�Q��p�w�n�es+csA���Uv�����v4t�pǇ�� ?'�G��RH����{�(w�������{eA�ٰ�o�D�M2�y���b�a��Q�W-�t�R��A-)�th?�_�����w���$pg^F��h���6���ٵdE;�"�F��-U�߽�\'�K�=��V����h�m0�a�A1#��n��_{�?MvJ� �8�uPHd�(��箘+:����v9�L.�m%� C�0t���8�8���j�G+,<�xBW��u�eN��4�.�`��[��Bq�6@��aJ��p�������w�3-*����xIi���`��-����3x
T��R�l�\�|)}=�Í����~�\3�����鰋%߂����	����C��R&ǌ#eB/����H�/����>?����z)Rv�ߡ�`S"j�������#�9��%��@��R�m(Ed��	�{�"RB9;�gQ!�dG:��Y��������7Z�/I#5���s���0h[�`Zwr�����Q�*7?m�;zlM>�H�����Cq:j�D#W��� -j�\tI�/B�~�
��b+��Ӟ�w@A��|
<���=6S�J[�sx�7�pe�L�|�5f��F+/{7�Z�6��B�7��rZ�W:�q��'v�u���p�������t?�/�K,����m/�7Z	5����>��n�.7RYS�xD��?����j�'(��B8���F���kH��ZNhJ��V��Pp��D��'��`Cm�EWox��A�!Ӕ�J��yn/�L,=VC��ʭ/Ւ~�u�����Z�D�ovѠ^�D�e���=qY&��5C8������'����=,8�Z%I�W~��Vz�n�0��
���!�kݼ�4{�X���i0=X{hn��N.d��1z��H�VQ$�����6S�������[c|�Ɩ��_��3{�h�Z����$�`�WQ{^V1�u*�.�/�W q�FS:v��xz6�׹`��r\ Y{�لh4[��"dyr0s$_�.G !�ϸqW{pv+�J�[��h�Ӭ
�q9�#L��U�Vd�t6�7x�����R���Dɷ��@8!�v<������?�
���^�"��S������W�>1B���h�eL�J�W��c�_�nK�03�t�<e=�}_~��.�q4-+�}�:=�2YNz���y�M"�t��E��#%��nL>����\���jI��~0�è�8TC��wb.EC��]���#�`�t�Ƶ�>�~���P��?�� ��8��\&ųuP��m��u1N��ԉ~��4�޴���$W���@�<�J�CuT�u��Σ��w�G�Ӊ�A-��\�Y�8@�������s��j�
㸚xA�.ԏ�����'9I��fv�<�7?��q�?��J�J�dLa�����dSo�q>{[�����	$�=��TC�Z*yT�����*E��χP[\�8+��=�44�N�"��ka:&Ś��N
��F^l�D��ʨl�(�	�1p蕦@O�¹\M`:A��a�9��
�c�:�{�!|"��E��uą�q]�����u]�ӸR�L�{֩7X/Կ.�t[9Ɔ�Eͯ?�yC��u��8=���-��v�/�2����s����!5M�S��oxa�\�%Sҗߒ6��ig|P~Z`��/��;��~��mccBi����%��A�Q�)Y5cQ/k�6n�����r��kلD���y��]�܍
���9�N֛~����d�O挫dp���� q�n߹�HR�^�����c���:�ZY���%�������1mN�P��i(]
�g<��"v9��7e��1�}�w�Jx��*�G�@A&��rʒ oܭ��BȚk�<?DWE��^�4��_*�>�\��X������|��,s휔߳�H�%�R-!�%�D���7�b�q�y_���,!N�9K`��J�����8�S��2V�y�T��Nq�w�'lٽ���3g:� �&J�Z��=&�A�p� ����p6�}qgE]Ɩ+9����/��h~i�=��NdE-��x��-�����k:����7˹G�K �/���Iw���!Xi�
&h�+Z�0�p���`�����o��*�
7y�+�R��bB]�z����H^6�f�{O�r��c��#]�����L�b�7��@�y�%`��=����y�Sf�j̒�Q�z OV�㈧ߥ�:&�3k�o�8����Z�R~��-������2�/��y�x��,9?��G��i{%!Rm*�y�\Md�i�I:-�)�X�]�i\�B��!�h<>�V)-��%��g�� ���n�x=p�jR������z��v�����c�����l~߾c�̴&��t���U6�Ⱦ�r��ڢ|t� �Y��I���+��[�����st˹�v;zg��H��nC^�Y�W�����rY8���Y��:.<d�p�a�<�T'Z������)Q�r�����Y���9�����]'�`����QśK�sf�%�4`��"�����P�3�b&a�y3W7�9�

#r��e
J��)���cbf������,��`�pٛ���F��H	�mQܮ?�7[E*��1ףN����O17��ا�:&P��s_A:C�o13��_���-h�J]S>ݩŠ`⛻��i%>�y�n�, L��J����&��+��*;3P�Չ]h�ˠu��y�z&���޷*}az�ʂh��|���@�D��M}��������Po�S<HM(	t�k��o��>]����1�>	oEI�tyf����CSn��'뙇��I����L`��7'���,�R�A������]١�PS����5D�Cj��	p�.'fc"IIS����5��5� C[O�5*�
x�c҄��t��^M���ŸjGU8�5���|������;XЄ+����ĻE a�n�dȕ��N�Qa�No����a@Ljd��������� j�ν���;����p�U�<N_B����7}�aվ��c�ml��t&����ԝ\�e�ī���mtd�=���Y ���s���_mVcr�Lf~DY��G<n���s<���$ײ���Ͽ��OU�ޞ��j͊�J6٥��t���p\Ƽ��r4|=��z߽�W���LW���>�ˋ����F��E�C�b���*h��xYȥ�����*{�E��0�j�]r����"��!t�}��/K�S��U7�@sW{�4�}I�@�e���h�3��v�L�j��P�J�d���g�bB*���w��e���S[��N#갯-�������U�FẦ�i�;S��h��R���l�,��r6��=�6]%���.h����=[�s�|HI@�G�w1#�H-c8+p�9���<�����^ܪٿw��4� hU��v���ȣ�,����wx3�[  M�/E�O=��-Ώ׌m��O�r��ٯ��u2�?����}SG���^���צd
V1�'���.M̰(A�7�j����b�>	�w�e�v�������8ZQ���j#@:�؝�'��C�9�h�Pu������I�C�2��0]���	D?���4��e���F��cƚ�|&��l��zI��Al%f��X�U�Պj�k?w���8�F2��;g�$�ܨG0]������Yx��z�ޜ[��J�6�^��GV�$Σ�G�=ۈ68p���c����u#o��	'3,B&/w?5;��QNA9��M*pO�&�*{?��U��"�3�X�uw/
(�,�)m���;Y%U��{NݽZ�-a����s��Ʃ����_�5FƇf���p�{숁E�X�W���a&�,�Z��(]��b>Ɍ[�6����ir?	/���8�6i�܃�-�%nq6۬� @�ߙ��@ uu�>��8���C�})�[sy���4'�,`��FW8�қ���J�|���P��]=�БA�,D��
)~}e��ONI���[̣Y��SR���n�Lh�fL.?�X���\;���E^�����Q����������_H��_�k��@�1�M3�F�"TU�z`�:&"�=*e��P����-���e�>�i>�o���<�w�x}@QȎCjt+�#�-��fe{a�K��1"�6�lPq���+��mC��R���Q������Cb��rjٙ���/���!6�l�+b�Cɿ���츱�9�~I�t,�ќ�{/�<�޷&,I�W��dު�`�#�`.Ɓ�gI&�q\Z�/�B��Y'_p�bvdco���>(8_���T,79'�6��p�����.�Y03�'���F��-�i��������^A�􀎃J9��7�S��e��0��]ӴzUl�Zv��=��8ȁ:���q��Kȑ��㌝G�� ��0�l��A���ko����M��/�	/��u��Am
Z��arTm�+ߣ�0�h��<]�+�R�xg����	MJDq�����%�~����
�Zst(]�n����q,��ᵪ$���[��ʵl[�>A�˺?�L�!Ĭ�Y��M��qW�, ��W�Ɛ�4(��6>���T{w�⊏�
mH�ed�����P�;y��K�3g_+\4�}ˑ�d��z��J���+�YU��:1j�܈,+�2�_ż�wF4�֋��r\�>x},���F��K<��D�0⏿�OViH�y��^[7�}��
t�q/=��2㎩�x�_u=}o�7Z�"�9�{c��%?5�3���,��(9k�u@[g"��l4�]���2�N�Sq���r�˳_}���Z���^�y:�a߅dt�W�GTcxW���:6���ǯ��"Hv��{���0�~�D������iz7d �� {�E� �/�m�l�-�6��DI��N���a�(K1"��8��˳���<D�P�M�{�Y���V��=�
y�9n� ��]��[�?�s�rSm�j�d̈��z�
r�>u�&��ʥ�R)�ە2��v��:,�1����t=8�uR�4��"��; �3�#�q����΄Ҙ�~뛔F�_� ߋ�,SBʌ��.0R;��-p�F�z�e�'�'<��P�]��d��A��яNK�'e��>�}y��Va��W���s�u!D���flo����ގ�7�����ڋy��]] ��I���K��ב���fm��7u�޸�|S��n��ڶ :��O�V6I
���#dn����y��+I=#o+��6���=mvn��,8W�!(������O��F�Sۖ��́ğ�In�f�j�[ �O�y�T?zǿl����1�Y�{��Psל����c?�M#JJ�iofa3QEs���Ɋ%g�<b��� �WT릧�Ws�N���ee�Զ��kI���5Ҝgǰ�R�f���L��J��"�*���%�Q�-�5/#�?��0I��G"@�Qz?	|�olC(}�6�tUZ�]n�)�-���iB����r60�O Xː���)<A.����'�IP[�wB7"�O��IbK��(f�M'T,t����=�l��Յ�B�G �)���費��F2��3,J:8g���w�)���@NtlY����(?��S%(B��`P�U2s���}��1�c�7]���������lI���dE�c`i+A9�Ԣ'Kwj���� �۾��QIu�zN3%y"����     A����� ����k,����g�    YZ