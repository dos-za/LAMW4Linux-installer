#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3595563215"
MD5="29e4627ccab238702fe4efeb32d010af"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22604"
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
	echo Date of packaging: Sun Jul 18 03:58:21 -03 2021
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
�7zXZ  �ִF !   �X���X] �}��1Dd]����P�t�FЯT��ͮN���+@����˟�sc��������X�t[�1�ٻ���\ą�K�S=2>�Y�F���/��wM+F/�	զ�߿�3Q�4�[��h�K�"o:���x`7������-��0��'&�bEY��e�9h��G\�sPէ[���rkC1W�z0�zE�@_ISyt=ߎ��/�u��SxH��4�LD��ł�ğ���d����H������й��>I�m3�����M�(9i4yݜ��W,ٿgHH��W��a��]�
p���W����47��|�)U����1���G�ϨmyS}��q��1�lX����0����v�}�.���ҞE2����p E�Y`�N
UO���(�������%�+z��5�<�&��E�ez	@�8�5��s�RMLX�Pxr�3�gz�1����V�)'٨�YU�z�܅�3���M�
��y�ݎ,L�T!�[��V�ʖ�����X���B�8���
h⾠昬v�Ԭ���a�
���D�3N��w��
=�[�ı���
�ir��~:cZ��b�8��6'��bO�lsߞx���,kB��mG4�\�*�N�%�C��1�@~,�0����N�a} ]��uN�Q)-l
F���IV\m� u���ű��#�4�Ր�lԻ�����e"�O�� *��7� �M��kd�I���3��K|�k��*�������e{���c�np�'r}kS�ȝ��s�ƨ �W�5��qZP�e�2&�W�:��)ԗr�z���R��5$@]�9�.f�ԡa�%3,Њ[nܽ�f��q�H*܄9c��0�z�h�I0�|�i�S�I�f�U�����G+'���ӱ���ݳj8�@�`#�t$�=����~\�ί�a�p�\��4��P������.��w��P�j���ۈ�bta��n�a,G���`U�u�9/���9��
��F���E�7���``��H�����y�k�,p�Y�z�Ρ�CIŅE�A*I�Ъ����nJxf"�����λ�Y�ol{I�:�C�� :F�̗Ѵ���E&�h�,Gu>t6Wv V�JQD�Yn,����7��ùVk7��(�$Ɩ����6F4��(�8
Cwo&VQ��.ʘѳE�0���K�B�7t��C�|�"���oգ�捹��Xu��sƸ�Nh�#ג��k;����(���c�`*��xr=�p	t��,��Raw�#qY#�~t�g�>�t&!�����a,��L�Z��b���R$��&'P�'i��d�.2a@��?~�X�i_��[-��8��8�`>[,AپA��X�����!N��5 �q��2�Z��'��u ��m�����B" ��%+F$}�E�C�k}���#��m;t���S�'�a"����<����J
{5]#�J�u�H<����}3=z�E+���n����Ϊ������ԉ��5�{��$>�=^"�@�(�vU��n�a�hi�ֲp�W�02��"_����?.��
T+��9�B��Y��Q��Vnw�J|@Y9�Q�:�#��rAxo�<Ե���XۺPD��X���m�iq�{ȟ�|P&�$�>�����{����"0�0�ă�ŧy�@�)�Zv��T�
V`}<a��LV^���+�Y�U��>��xI�,RZ��Fw�-��O����F�Ea��-��Px-�&P�P��pC;r�;�yʩƱ�
5���N^��g����t��S�C���n�QQ�&TM�׼�M@Vf7נ����d���@;��pq�1)l�	堪iN��9m� ��=ּ�㘾,����P�����ҟRm΁�;<��U�at?@��?�z�b�4mp�B�|�2#It\�,�ٍ؂�d.A�6��
E�;�YU���\�D1��	��@�]p;偣OhB�Қ�:���T�4��3f�q�F,���,�P$x��ʑ��~��)��_��h�!s+9��l��l�o��su9�c|��0�˻@i��tK��(�գT�:/�]6��_b��V=q������	;�c��VL�l�c�o��0l�C��.��M˴QJ�&#����q_�7{H��P_2#�n�!����}��^ܼ������`�#���٬^/o"�d�n 
�O�s����ꮭ���O<wqf7�.^�Ď5�%�@�kݪ��JD���[ռ�X���jr�	��Pˏn;|o��z2R�k>$�����l&�P{� �-��l|� ���d���A�-w����N������Gfy���5��q��Ls?��Dc�z�HU���)*0�@k�{�����X/D��[{9>F��V5�_�ane"'�Y����ʲ/:����%X��g>�o�}���r|gA���#{|����#��Z}aN�ႎܷ76T�jJF�p���I8��z1�'y�X*x��yf�O1M�,-���.u���ݒ��ze�n6���'\(jq`�d���(r�SD >�>Y};�7{��?�M\:�gD��^&�[����n��v��l�jNƇ�����""(��HB���U�WW�/�֑sI��d�7�4?tI�H�{0�h�q�ԥU�;�"i�f\/���E�?��I�ئ=nU�?�|��%��$�3P�[΂��n�KO�D�T]9�6D����P�k�\ӕ�^B�c������vz)�Qj���R��P��	f���Yu��LG���,3�p+��ĆΏ�=/�HS�	�;KCpµ9�x��o9���.���~�A�v)����*���|9t^�FC�� -KEalN�7����·���-���<��뤐�	����� P26/N�@����X(
��^�J��f0��y���u�:��M"SFֈƌ~?4�.���C�rP�q�.�W�D�rR 8�'|emT�z%�K	}F�c���#��*)P+�6Q���c8q��j|d��S��l0�=��;��LY7�ղ(W��2`z��}5ۋ�*�`A�ګY��=�rl�-�����os��B�=p}d=rr�n:��M��`���)�E
��u���v��p �k݉Y����6S����G� ����W�ĉ%ew��l�naE�h�LO��l�d�v�9ځ^l��P~agy)�'��]S_li��Ŕrr�nͅuP��P�v�|l2x�;�}�>��c�*M:�����]5׌��"#�}��n~��\�!1�8��P��V��� �A�x���������HE��S�W����yJ��ۀ�g�	$�X5N�6��GO�'�V��~���t05i�e��f)�+K���~n��lp �X5ǎ�[��`��	��_�p\���1B�<ov�O�.��ӭ��(��Ÿ���v���;�>P��'�l4o+��n5>S|"�Qs��؟� ,D6��PE[��K�A!���0�����y�8�qN���^"L�E��@+�>d��CVKk�Y�� 4x&+��^L$�xT�_�l:��@k��T�2=�Yt�26��`��K�F��S���]ۈa�qIO/a���3��y��a�aK�s//m��BU���jx�rXY�'�b�����X�D~w��Ɋ^�w�)��9�_��t"���	�9�B�Ŭ�/�J�:�(��J�xO�R���L�S;Xq����d	�s\=��h�1N7gi۬��AA��k6�*����Vѻ3#��ft��/�����@�F������6\�Y6Q�Y
�G���|�&��������X�U`���,$�ub��&A�/��N��$���A@%��;.XQ#�<�:<i�o; ��7�PA��))��i�(�D�Z9�~D����aB3�~����Ť
,;7��U���l2��Țznz$����E��*�G�^%
�g`M*� �}	��� '��5|��'1�����u8Iu7��������Xġ��jz�������p�ݷ]����p5���b3޻�
�Wi��r�+��S��7tx�V���΃$'(��k"r�/��M�=鱺Ga^��H��ϊ������Uq@�Ղ�~j=	����y��/���c�b*�I�d���IbJU��7L�Y��� ת�e{ ���p���9t����m�E߈٬��T ��4t1Hi��J��fQO�G����8����O���+�K�
��q�^��	j���Vy��ͮ��z.��m挙 �8�����8v��U���}&�|a�]OU-�����yy� ��f�^'L��?���vU�JH�Gvzd�\o������"�%[Č��AL	����[�m����p�������т�h-�4�B5�A�$���8@+&QQ�g�~�l�)������]�϶��2X9\-��VZ�=]"-�&r����_Ɩf�am�j P��n�ҋ�ܬ�=ߢΖ��>�����8���Į��f~�.:����P4�=v�C�^T��_鮤֬ƴ���]?��a�H��z6�O��r���H���XsP���H�GR�v�yR���0>�n4�� �wK����7����*�K[���	�df�����p��/��+���(���"}�IN�òj��.6��;Ьk��?�7�� �j���=�C�k[� kco;C׫1\�t � @T�&��������r0��mv����@����� �U��5���z	���I<� Ǩu�U�t�6�ЮG��E�_U6��i,�huIY�J���oܮ����P�u)�e.�¬�_#m�뺁�&s��N��8��0r����I��R:�с�����36�R7'��;P�!�$�4�P+����I
pq�wˬ�Ђ��QZL�� ��-�|`{
���3����,��J� ֍�\H����P�
�±�8��<���QN>F\�� L�� ��[�[�)�j�`Y�km�q'���T&:�nS*U���r�`����]u��@uy��[�Zc{��D?�5SW�,̓�9N?�3�z^ՍoT�4�6Q��%.�ҰE(��p��$B��g	�eJ��!p/�s�J��l���di��&!��@�5�ӑjU���к��<�dC����:"��F]����Ȋ��P��R�����eLbsşwt��S�n�A0�$��0�'T����,-�'�A!����f4UH��MR�q"Q���,��<,G�p�i��f|�[3���/�?*eD�-�i��!sb�H�QE����1 2l�U�l�b���6{BE��Im�Yƫ8,�zJ�\��V�wzy��^R�8A�x���L��|��5X��6&C���#)��Ku*;���'l��_�l������S�X}p4_n���4X�'b�����[�`�ݷ7��~�o-��[v1mK(��iA����j���ә/��)\���0�Z�eLX[Nl��]��M'�"�{+?�$��J��Ô�u���wf�\��.Ή���k�'�"�:prwM6�͞�O��+�ى����#t��G�� ��1LP���Ou�"x��O�Fs�f���䊠p���e�8i^ئ2��Y�����DN|�
Y����j4/x�ڡ%,��ȥ�U�fw���{�'��? æ��s�,�=8 �EsN�e�)l24��pY\���bx��ŔY��A��uڤ6rVn�͐�+���8���� ]�T�=��e��
���_ğ1�H!�G��,��[R�vT�W mx
 �]�6�7k�,��7��v�r9����E=������o����!�X�P5�+ܷq�Ԙ��m&wV5�~��zRRq+���hש�B1���2��lFnS7`?P���_�1а�L"$B*�Dn!C@X�;���F
���$d^�몔|�y���#��������K�%���6��$B�q��0�s)%&츳X�s)���~��N�1:�_�Mš�:�=k�1+t��^���Y
�4���
1|ȉ+���[�:�(��l��K���#��S�Y���WZ�+���py����`���r�R��>_%�>��W��C�3�퇶8�Wu6��i!c�AF�By�����K1�/��^LR���/@St��!�I�g�:1:E�`9�Ԋ���3�%d�3��)1#^��=W����}���6��hS�޹��qD�+��#�V��U�a&<f�+-U��3%��t�P'A��cb�XH��\)^�ܫ��A?���(�ٙ�p��>�Q��L���y��/�$vF'��g���~]�S�Wr�jzU\S��D�7'��q!.�Ϳ����-��	�`�dPz�k������n
9��9{���l��=��Sp�_b<aWK��n3}�Ŷ6���a��G�-T]d�?� btԷ��EǱ��ޥqN����s�`�1��T�G%'�H��P������=��013d�Iϥ]M!�SH1g�t��,�j���W��*��Ҳ|J	#/�+:���l2�O�Q�~�����}���:���Yu�.5��LV ��96Kv���ɸ�.��VOy6�y���".Z��1�8;��JӠS��{�ʷ�P����!��"�}`�����r�3���BȰ 2��Y��Qg=�"�k�����q��`~[��7�EH�vj�-�������Kpf�� %�;��?����U�R�uĈ9�s@�����\�[�E2_�/`�g�Gd9��5u���\,�6Y �ڵ��bV�9Uqo�_���L��!zn8�j<��ŋ}�Y���f�ȭ;˥K��(�ps��j��������$�P�Zb�Lݰ-/��4���u��CK�yE��;��(m��j�"��R�.2v'�.I�_�s3;��Κ�>_-ǘ��			R'�(��Pp�O�}��|]�-�>��V]��b�i�i1~��"�V����)�;�9U�zܑ�H1�'T
 ���A*!���*�͚��ý&+J ��lz����ьjV�8"�C�� ��K�;�۩J
�C�<���4�p_
�j�N��Xw��u+�~��n��X�뉈Vb�"J��Hr14�Rғ�j�L\7K�:����la
oӟO|��F���@-hh��6N{ i�9q�bޙ_�7ˬ�9'x�_�R�\�{f���@�%m���hb�>Pv��q<�K�^*�V~
��1���r���c3�)�1��g5l➱���p��W#�h�J�[�k������>�8�[�q����~�V�hc,��)2�X~H̕�#9[�g�cV�Q���w��A��+ �P0kq7�E!�p�T�x7�v��̚���{N����
Z&�H��4�E�Prp;���-*P���%���0Ϋ&3���1ܦ"ݓ�q��R/�G��6^�:����,XלV\�U4�p��qO��ε���i�4NeM�
��i���ab��z�uZk3��a�k05�u�����|�(���T�@�p���2n|%�%��;�e���h͙�Uw@P������j���8=;��Hn,O�F�A"=������s�t|�\b���m�ћ^6��D	�����{�^�s��d^A`�V���u=������JcV'�Y=V��f�A���'p͌�
�+E�g�������9*x
���\<�`ʦ~�/��(� i��a<_����>�ڵ6���>��Vq�8k��h֌#�҂(�d�v���yW-���*o�A?Q��~Z��.��ۯ�	�($YH��I�+�i/D�?O$X3ՓӋ����,@�[�6��S�Pp�Ѥ�d�5�ц�l4[��A]O֍��((���������[
�����	��{pG�b�CD)7���^m�-�����0ӣV�����6<�e��o����7�p��P��-�7�d��&�P�8ҡN:H���`a%�1�L ��,��K���(���V�1�#E��e���a�F��5vɗ�ԣ����Ԧ�e�B�����Gu��YU{d�@'���|��{p#.��C��B/	W�`t��>)u�`�8jrF��c�[I�qȵ'v�z�8{b�Ԩ�m�K1��T���)�>��P˫3P���=���/U̫�0x��1��u΋k�AX쁈������5h~����-�ZB��?R��r��v����� ��^�V�v��m���ꢘk���*�ԑPDS��H�1�@���#ǅ���(_��"�b\�s�U{!���"T�>�_ƪa�i�tH_ɟ���[�.�%����
W5<s�c��)?8(�\X��� �����E}7ht��w�A?ׁ(�«Ķ���(�y:r�𫎌�;�b�E#k��ܠ�z^��g�q��WH�pi:U��h���g���AmF��P����=��[�/&�(wgCw8Z�)l\�b-�k�(�+BU����sbj{����ZIq�fd���ah�c��H��bu?ש�B��j{�h:�����l���A2%""��oD{;u�'��RԀP&��svUELuZLwLsk����7���S-wtfI��?-�S��-��9h��H�c#�$�iLGEw�h��h�P)���\p+��]����O�4u[V'�F?�>��ş(�ֽC$2�V��F%�e[��k�򹍶{��$�����x(K#��K+"%�-��|�
�&�:��O���V��=���na�o��XExH�M�Oڥ����Bǹ���۰�"\Du#V[۝vpr�[�fbv����w¯�Kz}:���@�����W����Ƥ��t���WIB@u��5�����q�<M2c�9i�"%��zȪ�e#�]��������%�C�n���Z�?xx\�> �w#.�6�z3���?���v,n��(��\���7m�a�a�쩖���(^s���l�s``Ps*���fx�d-�2��f�����Z��2y�#�HK2�\�)�������YK�lک���Uɔ]���J3fb�(���~AT�����!@�[پyk?S�e����	\��J�����[{�����íP-���L?)���6���!+Ӟ�  ��ñ��\e���� f�& ː��]i�_��7s`�4*zQ�D,�q��M���>q�-nէ��x1)
����8��$0cD��֗S�Y�J-���m�A%dY��q��j��FlL=vo|��\ԍ5y�$���	�)�׼�p?��7^	Aq�ʿ����1Z[Z�f���_0~�z�Wp�!w�v�����4ve ���i"��?�C�VeM�e��0���۽R}Ktwʢ5��������ur1��yڽF��U�$��{y �,)$�"��k��[f�O�"��hڬ��$=��҆�S�������M�UK�^%��d��ꏕ�'��~~;�틫-�l��*�z'�	�ez��Z+��$�=A^�O�C]�g��f��3�h�*K=�L���q��1�s���`��?Ã�8�ϱ~����Ǣ$>��Hh��/򰤻��>�Ld�P!X� ����Vy9hj�N���SP������j"�;Z|�1���Z�5������Bm�VەG�ߐ$��12����0�s����4��+Oy����rܗ�C3��W~�7��n�n�)&���F̄�����A����ӏ�[�m����H2���)�,�U��JjrI��� q#J�ۘt�� ��=R9Ș�,¡�;�c���+�͢��h���*�0MO?Ղ�t�2���&���Bu,�����DG�Y��k��Uz���U/�PW;���5۹��C,�d9�9��q~��R�@ָ��_���ʡg�����([�G$,�y�ن��~��[i��04�JɄ]��ṀkD"},�A���T� q��['����)�,�;�+W����ءu�%�MFԺ��:mG�[;����GGp�E�!��;��`0Ϙ��1��3ۮ���=�k���4F��� se��ȭq!�q/5M]��t�,F�q�b�H��̡�x��U��'��yc�h��D�u�C�{���NP�3#�3��3d�そw�.�ɽ�k�R�`�A�o��t7�p%�e��M��M�{*�n��&Q�L;�m��%ݷ��a�P�K�oY���QЖ+3�<�T��æ[�p����(h��8����E����T�[�;�ʴ�w���e���,)-����>;ϕ��I`���@G��~<�� �"I��{B�iطB��݈�b��Ȝ�`���Q�3)�iɑ�i$�xB��.+SVʷ�4,�FO@�GRD]��[(��et X�u`0hD�8�����CZ�����������䞏S��uZP*�!>����fϣ۫���;���,��U���p
�������U��fod�i{��t���9�qG���V�j����
1�נּ5[8�8r���(/��Ƨ3u����� }hs��M:�p��kV���mY�]/��#��c���Wt殮��Bȵ�S��	�%,r� ���Da�~�"��Y�!(xrh<��?��,�

��1��*�9暏��͂fh�É���[�6�y�G�'�
�2��a���ګ>ˉy<K�j���҈�L�~��czD.se��o^����,b���9p��^�xJݶj�d�x����M%��.��$Q��ٓCj�f.G�,p{w�3��i��?����}ĩP+��D�';�O/y����������%�fD Ч�^�C��52Q�҄! ��G\Q�s��}IqXr�^k�K݀�V��a����+���K^�S�7�=Q|Ρ�\������^ȩ���5��Z7��6|P��@����Q�awf�Ʃ����C�rd!$�p䭳q�#(hd��	9���:���Y��h�E:g̬� �'��C�$�ֶ�EOY��'+҂�mH���۔S��H�"���~��(��!@�h���P3l
����"���\x^+�C�b�#*��B�л�Mb�&�S�;�`�)�f$�މ�a�4 ���630E�5[:9�%�Ͷ����KUо�5Z�
}���*ο˥�k Z��&l�ZI74���ZHm���n�V�� �.��h0S/�"d�Ȣ:}��Uc�*;|9po쨥~`��>d�w��B)�:����l���C�ٲ�1�d��T
S�-��:Q��ͮ���EJ�� C�-#(f���+YK,����>�*^Ϳ�� H_��]�"�t;�.
�0� :yʝS=�!�
����
�R8r�[�ܡ-M�f&e���e��th]��mHg-�X�� �0b�&������*k���j�WK«���H�)i����ӛ�Ebj�ȄV�w��j���h@��8�H�@F��E-�;���LZ�t�OB<��Yn�
�P{ѩ�֪wI7���,��'h�@�>s�+L�BBNO�_���+J6�)4u;\n~�l�u��\1�&P���r u�Z�cw����%S�|���1�.)��3s߯��¡e0��?B��T^��?6���o�rTO�~v4�z�6��1�|Π?l��K�hӝa�/Ǣ�餸�*���$X��0~_����šG#��<qA=���Qa��4��R�z�Ҏ?S�/�f�l
#j��,:8�[!�Q�;h����%�K#��%J�O9�Ҝi&ɶڤ�gh�f���Rk����LV�@��I)��D]N�
Z��FN�h,r��ҝ$� ���éM:�c>=�������Xzՙ�k����ې�PMn����q�-/k�N��2,\\�
���)��]�&�}'�{�?�Jbl�>�R�.�"+˧�v�H���d_�^�P_�5<v��r6߮+s��7䨶�����w��),	ّ�@;���,g��s 2�'4�Q�桑?���<�F�?��k�^�~n�ǈ�HA��~zĴ1�&����6R�j�d*��k�0��z�a눳3�K=ɵ�r+?u�O:A�P������η4V��8��y }���G,}`���0-]/b�fjû��c��8��,��4X��q��믥9�r��s`�lb���� �@�zc�v}@����4
�	�|-W����d�a�8��ْ�e}�x~A��pܧ�a��ϸhJ�{ac|hǃ�0�&��/}o������E�_n8��9ʆ�%�A�p��8�3N�c�?v���9�����V�9Ol;h(3o�v-� �1��],zI'\�[�>�b�z��g�IO�eO�~>I��R�4�E������ci���jo-����*>�X��z�Tsq@p�d&�D$�y��\~~�����ޛ\F�V�������1�7�=�
�>�'�Q)�S�L(v*�BL��G�������.�#��e&c��C7������*_8Du�`+�8�O1�oh�myE$F�D����SE�@DB`�⴦����6h�1�����y��4q��%%��7I�Zh�}�!4{���x*U+]`k��58�s�<��q*��g0Y���n��m�Tb�j,�����4S�9fz����|٨��݇�)U�m-5ԍކ%˳����0xGODn�!���K�X�90K��;T`�Yy	������@/]]�>^q��4�FVSh%������R�����MV��<�j���Z�F�w0��k�w�r�Q��רe�HD�~�:c��\�4�A�bs`	�����] g���&�^�����{�#S�d��{��z��;�RoARp(�q�T+3��&bE5r�iFk��TYme��P����#9�N k��r_��'��B��a*��we�}_N�
���D����rW��"z`MH����&��b*�{j�Z��L��|�o��8>����\���A-o}�7�~�	e#I��ɢ�*�T'���(YB�A�i=^�ʶr$Ot�J�.�'j�j��O*O7�U$�Z�q�d^0�pa��?��� �|���W3�ㅕ��g!�i��i��jF�R�]�lG�[�� ����n�^����&�nJ&i*�~����&�1+N�o����ʧ|��-s��V(��0B���g��%��ؐu$D1_�5W<��r�aj�}���Fl�X'a>��Y��]u|z��=��q�9~06T���&������<h{�&�>L{�́�ލ���$S�,���[z!�БP��y�0.Uv���7|��0G� !�+�d�%J�yhf���"�;�}:� �Fb0��>YE�`(�c��>�T	�!�Jp�z/�^�o�����n��, X@��-}td�x��P_)@}�.�)Z�P���6ү㏉O�G�[���;�`���^�tDޅ�N!#�o�te���ky���I�j���t�W-�9�-�����}����{`�+���E�&������{m��]���rJ�Mn?�@ӡ�%_�2��*ߣr���2�[_Wz��0#k���Z�,��
[�͛�u#K|gLs�:��x��y2p�C�ҥE^�ԁ��%�n���5�ؠ�^��o�o��wz����zp�Q ��n+����s��2����AK4��>M*���E0�kvP ����Js�τ<�a�	;�e��L�����d�9���r��		�z)�x��jl@e���_!��ge F;���*Eg6TY�{$xX#���������d��ʣ����>�&��0�Al_J��P��hAVvj*ܩ ��1&��1�u,.��6=HAw���Ƒ��=�~���8�����!$�)Or���cYq�Sk�ލ��vI�L������w&N�C��ԗ`�g�8VO���l`'���8S�y-6UҤGV����#LAK2+�l^=����=\�TQ(;d:6���>08�-H����Ѱ���T����;�N�6ng&P�([�hj��Ek�{ �W?[�*��1}���>�$h��vOu|�Fr4�vž9����2��on�}�T�JԄ�ܮ��Qt-�ʆ@����{C�D�ʀ�T�(F�$ ʆ5���~�@��~�A~z����u�E�������}���U�Z8iU����� of���q�c�*��������Pf���V���z(_���f��%gC:Yk2�pe��0M�,�+�1Qff� ])��®������*k@^85�d@���x[��c�A��9)\&�;e�� A!
X����sX��
�JmN5'ʾ�D.8ʧP�M��-(����xu*�șb�(tIyzvʨ����%�-SN3ƣ}VH-��QU��m��
rf�l�mF�󕇝�u呤p��l�1Tj�!CX�1Vv���OE�D�����M�E
k	_�$�D�l���Ŕ�~h�̺�A���mY���.eU��� X,p�̈́h������>2��W4�j�I⢲�!��Pt�K݁�@4�$� 1�8P�1Ȥ�p�
���Q����"��3��$�󨟩��/~c���x�2Q��Wj�(c&����g����U�]�yīN�:oۣ�gD��̱jL=W5��D��ɸ�0��  kt�n ,��ar՛Ka�qo`P7oBY@9���5�bWƼG��t���Y��c�N���ȪK���6a^�0�Z�y�M�9��+_����d�z�IW�F^cΑ�a����QѻlEխ����Ϳ5j%�l��L�dG�'�t�>.��db.��")nN<�P	{��z�]x��U��t���[�$���L�НN�����Y+�n(V��.�X��߹(^qu�2��ϦFM��
���ĦwF����F,B$����"e~�l�u�,!��2��h�:��P6����T	�Pu�����LF���CKt	K!�+y�p�C�88���J��R���J�eqxZ��iv[��T켅�����LG���P�x�[J�U�a��B��H���[��q��f습�c`����/�
N'�
����T�A�YB��R�]N��fv,���\d�߅��m�GݸH�W������u�w����&Am����j��e�x�+�i���Id�F�1/V��*��D�#�V4��~��hZ�q��->����}�o15S��I�[O^�Z��!�yh�������f��A	
QR P%O�Ḻr���7�n��������K`��)ha�B����Mɨ݌U������P��^b�ã�D�<��5ǡJ�&0����tf{#1L�� !B��൒�T��5[�)�n�5u3��Z�ӄţ>Y�1-]IYCc�Pm,Z�ߔ��K��u]ۋ��F	��Ҥ^��*�21��p�C~���#\��j��p���&��0Bk�(�yyt�|B#x�m�6k^�T�K�S�R�;��A1×j)����V|T���g���x��t���.'"W��KJ���)�J�OG_#R|��4��O��,ꩻ��R,8�v��#S���
�8���pF�ä����W%��K���=�=�����G+��lݰS�ݛլ��]^M��R�!{��%Ȟ=�+�\��!Y:j�5�+Kj p���WF3�PA%����U�"��r�vR�.���8�&�/`/7#�sP�#{�k��ǿ���{gn��,�a
�lxh�=��{?�� ����.��U
������8fK��!�E\��&�n��DfeO�����|"���Vw�5J�;���r)P�1�&�H�6����VMx}q/ڈ�mabwi=�݌N��3���]ޣx���G�a\��u��A�m�y;N��D�m�#I?.��?�92E����~�-�|��?�qi)e:+�HvDH-�GQ��
����Z��T�K"b�S��ɏ�L�~0K�HG�'�nt!�Μ�'������3{����TX^�I�hV+����gς}�r�x6�Nln�&]j|j�H�E@�1�L��W��נ=�!N������x��h�L�a�vo$��%�o\�S�a@�/�2� ��������U�d<HJ &���&�N����u�����d����T"?I�E�l�Ƌ\�iJR��V����>��!~�:���؞fx�� 7���W����L����3��LT	;��.�a��H0���j%p@����'�u�0�L�W_�D�#�*� �����hu�����`� 戨�U�v�ْ�7�l n�|�����
����9�@�?����
T������[t�R�n.M�l�U�/����E����oR�6V"���zT�U��\D��-�~�-��7��wCKWW:�{��9���ŋo�V���8�l[&,w��	jQ_$�+��7��gq��þo��z�_���Q��{��������~��i�B"�OºD�[�+qn>:�	�>Mٜ��J���;���_"�!��%0����B	̰����Z�v��wb9��$3��?ZQ��%��.�
�H��z	8�d�S�f�Sa�k5��ͦ�ǳy�8T�i��WD����գ,� �S��x~8��,ʖ�g�$a�:q`��:7~��o�h�X�/��>�)�	�{ez���P�F�XDHp'��TU�oec�(�X~oђj����)���n@��>����&��B�ϻ��UX�	�B�?��<\r��2R�f��Z���^K���ʕ�Tt���4ы塓�����h
��@U��=_��.�t�j�ix�7����:c_�_�7��/��|�������"5n��Io�x��>��~b1ڣ�	�`clD0�j�vx
4��t��Za��c�i����m�kGɺ/��������$�t?CJ��]hH+�8�Aa��P5 ej�B��q�~M�݋��L��3zs�_���[�c�����D�.�\�>�F������rM�����w�5ڜ��|89���4pJ3]Ǽ�6t�H;]0�c��oL��Z��b%~ ^v���h?�+���R-qN�Tʕ�����m�W}�����(�.S;�2=~ج?F��N��!s i	
>i��p�h���Wܙ�<��m���)���\E�*��ƣ��mJz�p3'gA3��,�j�Oh��k��O����4�-�b�I�ifx�?MM�����o�X@�y�<�"$�ڡ������*��Y!U��)��ތ�e�J+�̎?0ѷ�������yi�?�Ӧ�H󤶊���MS�L�5�^���^~��2��z��M ���uJ�a��i�c�	��t;���dh�����

1���b�3^��1�O)�x�?0-�}_���
<�r�iSP��#L:��h��r�!/):r�a�sI��z�0]�QHW�H�y��1���
�
��C�52!;�x+�F���*��F�חPW�PM.fl�ԭ�uU$�G$�kD�Q?�}�.P�^���q��D?N��n��5';f�-��ˈ��Ҍ�3�C��� �|cS��ZXԂj>��	�2R�>�|���
Pw���U��x���j��p�g�y8�&���|���O�SCc�ǂ�G��>	˦O��kq�,��v�gP�om2������"}��m*����d�SX��(��H��ԫ�ә$��4^�w��六���� ��p�1P5��
�e~O�P�r�|���.l>�m�bӲ��E$8o��P� {�۩ܼ��Q�E'�f�w�憴S���zf}Aj�;�:����?VV2|��oQ��"�H� %Q�䉠;>�.�����A7��}}X^�"�uC<
u��hH�V��*��Њ65X{��� �6+`L�
1_�t�v��U/ ��^dX�v>�@c��Џ�F�](eR�9\�p�%F6D������	o%FB�no��i?��WD�OBvb&0	s����\9�������wo��|t��ѫwҒ]�@+d:Z���R�׆�a���|0nǵ"���L�5{�NR��P�U�!�H�4�����n�ϟ��;ʮ�i#)�%�5��< ��2�c�mi�̓E]LJg���" �ɕ�<*v[%8G��ki��OyH�Il�$&�����XW�J�-K)K+��u;��`:��I�-�3>�#}����L��p��Ľy�t�ЮfԸ�u_�m͘�loq,�|dR,���զ`C��A<�_1�:�-��?��G�@�}#��u�Ϲ8�M��$����T0W&�룕����A��8�bH������B3w��]uL�?Ͳ��t�\��svm��j���.���`t�q#�� � 2�Y� *���pg �ijT��x�כ�)Ԯ �G��7}0a�]�:��x�QW��Q�N��@b�?+aCǕ3�E�n�����=���-7�`_�8L�K�8�]���y��p��e��H��DąN���7��ǁ����H������(|O��~c�b7��|���N9����N٨L}�J����~a��q��W#��Wh�Ӿ�7ԏj�Z�Ȕ�+�����G��� ��e?����?j�Ӽ�b�
�tKلg�jL	��rl	�#4��%�U����uy���i��\��Y/"C��P�j���h�O_���'�iY�];%Է��A�u�Ӧ��Ӿ��
Vź�>a�s������;�{�
��wʮ���%{�����'dp�.�Z�nȦ.
+����B\OKz���+��NXY@��t��Uj}��44�"\����8"֐�����EK9V(�U��A��,i?Wp�	�m�^%���K,��T in}�z",���Ə1 b��r��!B�>-Vj�mF�(���P�f���s�/��9¹N3��$�t��	�7�4�|�+�Rh�aėW�+�w�
M�Z�2�\���7�F���)G(� �;l'���Ԝ����
[�Y����ك��*{w��RV =����K�%	�@��/l6D��kE�
r1�&4;=�ؔ�,�"��̧��>�.}�Cˣ��l�З?��	.(-#���D�kw`�9�ak�:ⴰ �O_�(hC��^��'|?Cx�����f9\M�[��m��b��
R;��
�x��g[w���{0�v�J����|<�ɸ�b�	9l�ܰ�ű��`/~-�����# �~�kpO~��	�<�ļ c���V�����Q��u�T�ᛸC	�{v�� a�5�$���ҡRDZ�<�em�?�팦@�Lp�y� e��6M`�8�E!���r�<���[qR�h�u��m7%�R�w�3�X�>gn�?E6 +�!�Z���S�z坞g�Y\�S1M�k`����C��,����+�,~����t�2��,[ҹ�ڿ�w]����"�k�[�Wާ�'K�������1�7�G����T�w��z�l�u�i��=�է�;آ8N=���y� j�#��rX h3��pc�xe���i$�¨�C<I��]�:�5�~ʜ��ؑZ��~�����f.��;7lO�]��K)���C���e�q2n7�<Τ�x�0����AX���,ȍ�݁����*&W����/Î��i�D�z�|�Db��cw ����gkr2J96ip���9�fr	Oz��s�N>�,2ad��ճ������i�o�׺Su�Dk�N�Na����UJ�s�>U�3$Ն3Q�b�Ee"��0ݖ�7m'B�CL����/U�C��i�&e뫴�!��i.Ӆ��J�`f����y�@Y ��꛱�.��rhB I�a⌑���	�e���'N��-����ʺ��3i�m��ϫ��Yk��9.F5S8{���[����6�U@�J��$J�SÆ%��n���s��<n2��_����~x+��s}'Ds��Xy0]�|SZ�&r~K�qp��f�E9���3XK0�# �O��N�Z#j+��i�$8�m�u\���p&)Ö26r�e,p�0c5�pR0��k(�e���@I����,L��~�<��oh�gO�P�m������t�F��'X6��Gz�h�Ŏ��jF�c6G��%�����O!X,m�.��ݽ��}I��wؗ�Z��DF����<���w�D����ՍC�y�eL�`^@�$[]ŭ���:ꩢxY;��?`�����W`[�*��J~f�=��N�J��K�icz�|[w��1:{�����qt���W��~��5��_�HYi�u�e�rO��)F�����wRR� ����*�:����{��v�aY����_�!��
�ǀ5��%G3��I#gn�b|��vrƂ[J�~��tC�;
���2�
R"�V/�TG;b �Av ��^�NO�A3�(�ލ��T�֛�)�Sڜ���g!�b�\v;��S6��[!V��u�4�c]��pb���t���S���-��4��u�Vi��N%M�?2E�G�/*f-;{Q��m`�|���lX�z�A���iJi9}���oX�Y�2Dk��Sk[��$^n�NL�V��X�U��FKE%�^��S�}ptp\~��YK�ٙ7�k�k�xց�L���h�ɱ� ڣ�&$e�PP�((Lƾ�X�ڍ�H���@n)���+tH!E\H�aD����lN��XEO �n�����T1�'�yB����8���f��ć��v���<q1�Y��@K�Y�/ ?T�ld�:�h���^*D:s�$��J��e��mH�������z*�vϪ��G޶<N�Ywu����������n��02���<y��\�Q�<���l�l��Tl�������N����`i��a�� �T��/wm��*9�� ��{�;	�R\eԴ�Jt��-G�t�4�h $�u0��-���x�6�����~
R�:w�t����8��pͳS	C4؎M�Gm�Y�W�?5���C	�ל"H`���!�m??U�M6V�E `�]w�y�I���lQ��2��:G61� �Ś�rZlv��q�I�~��!�yP��4��g�\�+�Q�8Nnõ!"ɚ'��n$.�L8��DW��x�d�����ԫ�Sԕ'?k�[Ҷ�{ �N��u��'Xg2�R��a�ᒲ��K����V�l �p߽�V/AZ�� v+���bhJB���&��V�s[�?�GG�ꄉ�:��.��꤄����eJTY G�u����������:�bO%�h��ߜ�R��JP˄��`0�q�T�;���� L?pCk���H�q��Tp[G��Vc5}3�q�l���� ���ZPl�>U/,�π4�t����YI}.�?(P�A"��6ŋ޴55�3x��� a%�����ς���r$⾢=�e�@���@})J�(��?�>Yb�����+z˫�vѪ��UwL��������JF
Qtc�T��Yϳ��O�Qb�}�>������U�w�TUݳji�
W��h�3�6-��K�(�p�⨀�F�<39��e�(ԣ&��(�ʻ�]�5�zf�2���]|
��Qpg�)�j`�TPry\6�1��|�OM�A[9��s2��=N�&5��ѓ��O��E�����ܑb�{���|e�_��׍II��m[�ۺ��Z(��>�(^��%��
�rء�������xYx-�����P
a�"�Cz�dʬ�Jgml�8���~�[*�)mrF��N�,���o ޢ<b�!���_:�<5,۞�<�:II/���qQ{�ו�'��܋%�E�O�a�r$���[]��	�{'1�'݈i_xK����M��%(@�,Ȃ15����N�w�T64a��|Z�Kf-�b����6��솩�"��n�o�2�v|+
�񪃷�$�Y͎��S�CaҨx�/�a����t��8N?�_�ݞq�����	�_p�u�u�	��'hf��l`bMgԔ�����C C��������P����&���4��;Ls��G�g,�ȇ߳TV��ₙ��`s��A�t!e�c�a&Ѩ�^�G��E���e1B���z7$�QjxWK��F��|)�v�,ܿ���Xhuf��q�IT7��Q���1�j�A�τ`��iL0�qA��WT.���_�ev� 3��ҋ"���������q 'u+��r0'���Yp]�uU���`��@ ���A�x�U>&��r�]Z�Q=��'և�C�;�G�),
O�S� �U����ݺ�8Z���U�݄�_x̲���8���kd=�d��R��N8 ��_�ł��՚�
�8��I<y>�]Ht%��YC"��)j9&��E�����kT� ���(���$ݥ��Q\�X��7�.��	�뺔�8��$�#z���>H�h�w(aN�c1�ۃ��Tԅ�5#5�$S�����F��(/������#����Ӱ��D�Ժ
G~�����e���ܡF�����7�=:'4�I�>�����J6M���7� %{�Zd&��rA;ӏ��'��r��.�ˋ`���ы֣��ihbI�d�$�UP� �;��e��#�ć�Bc��q��)�~0/s�OC�$�3?�.�TM��e�h�2�f���f�   w��5� �������s��g�    YZ