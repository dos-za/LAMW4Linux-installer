#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3865205926"
MD5="2af1ac3add663113f44832cbec6b9507"
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
	echo Date of packaging: Sun Nov 14 20:13:51 -03 2021
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
�7zXZ  �ִF !   �X����_�] �}��1Dd]����P�t�F�Up)2\Z�#�W��ey�"�E�
��r_������*uU�8d/S
¤m��4�o�>�+��
x@@�S
�J�L��*���A���V�c%i�\�R<���G�|ը�q��5�����Y$E�_�e�nMuF�J9��h\��3�m����%��C��IBV1_W�#�	�r��x�< ��l5�ip��R��#~����0�����Ж�D�U�ҧ�"]Yl�H��c�'��IɅ�i�ˣn Q L���f�,[�	���L~��6xL[�ҮH7�/�%g��SnFg�m0.�YR���'��I�Pc#��=�SC�j^��0�^�,�����s�]+ɒ�Y W�	�ܤ�/1�R�f��������l�ߡ@�QGX�Ö�o��a��toM��	����ae)�S%/U"�&�W�:ub�ҟn` #5>�h�zV����96Cy7ty�Ŭ$ȉ4QE�l�9Dt�g%<��v+���"n���p >p@�*N��Jk��đh�י�����G羒��o�������M���V�ÍԘ�U�p��t)�aj���/VQ��,�M6t�	�Qr��>���ê��}���ur�7��ߣ��0~~�RI�t�^��Ƌ/*�4�*��b��)���\��$0�����x�҆�[˄_��S��on��0��,iڭ�׃a� ���k=@�NW�x�)�O,?(�'n��d2�%��bi"I��4���QU|"n�m�׆KjW��E���	��WQ�Tt-@p/�(�b�a�L�G`�t�I�]�s]��c�=�ѝ��HOJ�<��Ctp�_��}�1	&���4��$�@'5�!���-��/�1���9�w0tiB��I�d�h��b����5 O�Y$ny�d[W©������t�ʳd�8����I��v�#��B�m�{5�[����8��%ʅ�3f�iΔ&�CVH"��P��&>6M�e�m�6��:�#&���K�94	sU�7{qs��s�@6'�����{<`ȝ.�Gu=��R|���>.�����0�c{ �1g��ت����{��@O{����&(�Qn�&����t�/8��L�	g����c���D�����%�f��������b��CjAbWا� L��J����0�tB���Krpu0ه��Q�\]�AF�t���n����$Cv�\��q2+9���Ϯk�M:O�I}�~�]Κ������Uw[Rɮ�r�qMw���խuɑ�ݱ��Q�,��x���[�y4��֡1�{���G��o�'i����S����%I�U`D��X/
�,^�u$E���A9/����txՑ��`dN�%��2L3Frɘ?�o ��B0��u+����8���9�y�o�y����^�a�X�n����M�#H�#yz��, ~\"�' �����Q��>����t%���0�{�g !����b;ݏ�C3|V��%$�wK�����W�P�����
�+R���po޷ܐ��o�VF��g.�`��q���u�?Ld<E�#�.`�np#8��4���ͺ�P�i(8��'�-'�z��w\�V�:={��o���o$=J�G=������e`ivh���4$&�0X�^Z��@�(���گ'%�ۧ-�R\��E�`�Վ�j6��g���1��L�� L\���/Q��E���尨X-���؂F}pT�܄/�����BY�D��9n8B�+Ӱ���R.c/)�p���,">
TK�Z���m�
��x�7T
��/���azوk��?�c2��Aa�hج�P���ӂ��F|��tđ�����,$:Z�+ʨ?��2D�F �{���V�S�3G��B`�:���O.A��y�rIYItǕ�����&�敞��>�s�!�@�����W�w���78M��2�5F��\��[�.@A�����n)��8��jӃ�:<(��QK|*�,�[�e�r�Q�U54��(6Yˈf����v9!yy�XH�S�� ���B�8&-�K�N��/�|��Ƶ��?0)���\��f�!���1�ԭ��Sq��,�a^f,k�һ��R���9�Ct�V(5�e�KBطd�-���{��G.ꌼ��Oj��2!I�>(��ʦ�{�I�敍���t���>~8d���$�Nn�.T�	�~^�[����t���O�%�("kL8�TL�0�e�4�Rx�^�$��i�]r�˔�KȔ
��Ϣ��,s~�5�F��ie����`�L�Rt�:OY���W(P,4�-\yw�6 ���9�*{1&������ü���9�-�x��rI,�!���~�V�.>[��ُOn� �yf��6 �ߕ0�)?$�&+̦~��'8�k�G���8��5XY����Y�nj��@h�:fs`6D�PA�����{_8�C��ӌ9� V��F&N�E �QB|(
��mAKz+��!�}ba����J�����a��WL<��@��6���>�{�s`�c�usp2-�Z*�d��Xt�G�AZ2�c����/ηO/++�I�2 YBx�?�d�$B�5Ek�X�k�������z>!K��/���(�ų�m"#[c�@�TX�-�y"+����F�.k��.��k�ͱr#3��n��M�����vȂ�˩0�E�ݸ���t�O@{-U�8x�}�\"O ��u���,^�>���uBΗ����\�~��}�2�CEhrQM�:�(�2�o%{��oU�0!KB4�H=`��ABg�٩@"�q���P�n_L��E��{���y֣2���p��Ҧ�s��������M�{0_Bg�.0�B&X�!�"����,�N���o7E_�n����/�Hb��_;���K�}=GW=Re��gw�{�'���M!��v+4�:A~w�<��z��X(�3hܾΛ8��[���g0�,4��kBSOB�]dŃ�	L��G-�ZAq����d�e��3��B�=���r�85_X_�1�t���X����M���k�n,XI<�h�������*�����E&W3)�H?������$1D3ݎ��EK�Zq6�vטY�T��8W�+�*M��Y��Z5ύ�3�O�|�R�p���2١Qi#��Թg�ۤ�Yk�{	a"��Z�[]�vygR�1���ؐ����톑��l;�kv�W��ǉ�*����C���8e`fF`��.�]�(b�*')��G��6b{�h�"��0�KRF�sϼsFд=����=
�P�̀��Z�5<NX���Pu|���ٔ;���c���'�Ò/_9��\�T��kJ��0���5glk��X�3��WM<�;��Z¡J8���[���Z��-g3~_��HM��8e``e
D ��@�r��R�X �힒ϱ_P=�r{�6�1�f?p��tҘ�?���AGrζ������|�AG�P�oY<>D�W����#ذ�a��zp����%�$�aC��f;��l�-x�����sv&����Hѓ|�.�>|7D����sj���!g����Z��z���/R�Ռ�4q�I���#p�^4P�6�A\��	���MJ�xa:<���P�`��ީ"ʄ��$T�u.)Po�bk�(��|�M��NO����Jv��� b|�__H�H(+r1"���=[�gѐ�?�sL��b�E�;�̶�`���x���S������o�|�B����B+4`A�g3�6�0��Fe���]�&�$l��:�Ń� Rػ��E�X��c~(���d��$��vtD�ƾIn��#զ�j$A��&a��x�4$�8D��&����?oIh��Z�E�B|'>g���V��$G���4c�k����i�v A#���/��1j<1�p9H���P����踴v�/�]�ߣ'%щ$-|��j/%�Y[Ș�W���o/�ZЖ�/��F���ˈ�a�!Զǡٲ޶���0��r�3���߁'{������q$�S����&(�J=�n�-��ۜ����۸~�qX�����1��؉��2<5;�l�j�M��-.�rr�&'&��+����|����meEӆW��d�q���F�z�}��6�h�?�����r
&‮�8�~b219(��]������ѻ������/t}�Ux��7��R�h���vaB�<�S�I��m�ۥظV엿t(!��fc�<��T�W�r�`/�����O�s-\��(5r1(f�s��F8����m�K:9����a�L>a]��ƹr�~b�Q�TM��N��L����7��'l9�!ۣ��J�τ9��﷚�L�L��'��7l?�~�5�Ǜ�ξH�}���>6zSP�vf	պ�U���B�0���;>n)�I�Ɍ�C4�olW���(�T�w�����Ȯ4	~B���W��\®�4�1�H����ڳer5�\���tFȯN��9:nvH�gc�ۇ�W�6�w,݅���o�.�{�~�����������Q���6��*���K��6m���%������G��p�J�M��c;G�,�jGAt�4�?R���KMdrj�M ���g2i��*F9�	)��D�,�}9�'^zA���W��Z1Љ�՟R�@`�]�qV	0;pa=?��I�@�9���{�/;v#c�T�}r��l�e��Q�G��Z�;�6,�����f>c��?�<|�l�����
����	��,|.h��)%�-��"��#j�"P���~]$�k�.�|P&J�:�_;?=���Uru�6q�L�ř���o\�1��5��&%K���v����-�A@���^�A��Ч�O쑷�.���ɷi+y��.t%�ʿM�Zʹc�CO��V6��F����Z�s�:rbg2Z����2`��������\��<�T�59�r��-�J�t�'�J;���â���H���H������U@�C������jJ�n��9��VYV�WR��ҡZv<�0B4�F��Lhv>���sڞ�ɔ��WR�[��"��j��
kd�����@� Q�Z�;]��b�]��C�#z}��/���=j�( ���5e����p��S��O�e83}v��o$����!5Ilgm�#[�^ =�縇h �g�KC��1ڔ�EƝCJ$��Ex<�j�N���H�F���"Y`Q��������TVZ�%4�RO(���K�0�˜���p&��?s���	�Z.����lZ�a�,��Ŕ�.W؜o���m���m��+ɷ���8M�7¢i�x3:��,Y��4D�F76�A\oIΡ=D��nGyE���j!���
Pc�[l2,%s��f
�����s=��L�:Hi�	�2�������[77��_ok���~��#8�����;��uJ�^	���:�{��_q$�H5b�ÎG��V4n&��Z�&�S6�d�P���μ��<b��t��z�Ta�<�|�����%��e�qs~G�� ��<��4���L:���R]R��(���렻9�N���E���ZݦN�_���g�[ U}U��4��qUh�&V�V\!mM���<�A�[���G�2^ј��a�;�ة�7���[k4/6p:�sB7������S3��&�WGŢK3�қ��2H��r���D@Ţ$	$Q>k�9��yD8>wזX�K�����E�� zZ�B�⋁@��)��-�RG�p�܉QV�����CQ�"@F���R�D�o=D�~=!�	N�M�,fo�zc6�J5��k�u.n��1f�nM���5B��	J��9�
��&5��V�]�N�:��|2ꪯ��"�S�	��6`�ƹ��I�W
Z�����ӳv,g
�\xP�xn[ng��t"Ec��]r�֘.orD_@���NAr���]�p�k2�7��Zy�R{�v���g:�i�e�� p����f�ƛX� �L'�\t�m�ٙ�����i�WJU��4��ݩf
�U�tU�zS�i�$^r�v��E�p�~��/����6�ʗ�N:��
��j�� q��"�"��P�*���J��VF����ZerYa?Rm�K�c�z|3݉���Y��t��z6׆I��f�)��.�u�_��E(�r;Q�=�^����Kё�c�X����ӡ�C�	%��K~b.)vm��tve�����|�����CJ��P@UC,c��&��?�	�8C��U�^}�M����Oc�λ��o�2.Ν�r�-l����"6�N�$`iYJ!�9��݂}\�C���8��Ka�T��Yʉ�绯l?}�Uf��@x>ý��dȝ�կ��82k�#%��9c�~b���P�?m�x���gy�E�UH��E�_��W�̘��c���inA?G���$�W��N�S��uc^�)F�Q���R�iW����]��(SOu)�W?�gL�*�o��!0�������4~���.ܯ9,� �[�+ґލvtq-��������/�Gʶ��<i�oo��'�ߓ��:��:Kd��Jt��~Mm=�D����1��@4)��1q������:JwT2a��K��(u���ބ�+-���5~""Ù�ei���GG��%��� �뮬8�#S)Y�{!ઙ=@�W���q>I���<�Wc���E�X�M1��=��߀(�x����N�\�*B����H;{FCt�_Nw��U� e��TMj�k�$���<�^����n
D��ݹ,��[�ܵ�'>�ʞ(B�F�E����j혙�	��-����x���Nŵ�2B�_�Ѹ���o_XJr��c��()S�P�p-�\WT�g\R�_� ����v��ғ�M� B�l6��&�q\���.��2�-��j,9�g���\�3��Hu�!����
z_
20J��U1_
(
�ѥx��!���y��{�sGĦ���q��7��,g���ln XG�%���5V0��"?3_ߣz�C^�'���$�i궄C����E��I9����$�("a�B�A�ۃf�񀶝��߯h��&�	�1f8VЭ�4ا{��^ށi�ҝ	£W��H��	�^�F�9��%�2�B�9�m��>B:r�2Q!����+g���7LB'	�z_�̝�n�����LK�ܗ(�Y�.�g f)��Y/���h����X{/_��%8���,��:��e�x�K�dD7�_�G�8=�([g2������ڒd?�Z@]v�ť�?}��Y�Q����w\5�)b�p���V0�����b.��&lJ�
:��"{�.��&���/�O}V�'�"{=�Af竌U�2Tg08ٖ�z�%��ʾ{��}荎z�c�Cck��-�[Y0�<���es*:|}B��q*I�m��/H)��qv��3��7�ﳘ5F�h���X����.�5��)���<�)'d���Z~[/������R�R>�=]�N������"���Oy�v�;��R������?�Ð����G�i}�֝.��t~`�cR�/��S���ݽW�X�iphc�� X�k��^Z*7x�,Ӭ�/eP}|:���xU1�zy��p�����d�P^C��� �����ߘ����k?����{U����P|"�jI�G�9�heGeAX�=���Ʋ��u�8��O�������(<��7��#�9�O�Q���{ �H�B��� ��)Ph�� 
�� +�����tA���A(ꌺv�ɀD^"��=��W̫���S��^W"�v��z��c,�֑2�X�߻�EӆE������`�?�6�5�3�y�W�
\H��߈�����Nx^�m�����D�	����y?��Qr�o'C��"����bGf����dg0�G7ݐK�rY7�ټ*�Q��\��\���̒�|��OLA�Q�F(Ū��=>���Q'���'����x��4F�����ƀ�zOBH�΁.�!f�\�uO䥨/�%3ɴ2m+�Է���Ѣ�'�Ecw�B�8/b������#���`Ґ��E+˔�������uJ��TM
 ξ�x>���D*�S��ˋB=���6�
X������T	�*��4���1X^�M.!)�&��M(�fM�e\�>e��_�Ѹ�Z���xnd�-���|�{��J�R����{	�&���ל��YĆD�<�3j�ߡ�U��5a���w�g ��
�������!��*uO�;�b�N�ܚ�U��9g8π��Ȏ95�g`un�.H��x�ӝA�7Sv6tB�(NP��3"��ʖwl�#�q/�?����sD��	����e	j �E��f��u4�q#A�2�Kl��ҥ����`p�l0J��+A�9Ԝ���˵A��/5𤣡tg3�>�UZ��GH;`�b��?�z`�M�)���+��L�d�Yyi�:�D�+-����6~����\����M�Ce�Q�[�(Z��,Dۡ��5�� ����p��Q��k��vh�̏�\Ҷ��z�^�>Z��f7�d�	ߔ�`���+����N����eCߪ��T�����6}f��QX��xnN�PBsJW��3�4��͒5��p&0�@�"`��D��=���6����C�\���p&���w���X0���e��6qH�C=��
W�~:�&��x���p��Y����F#vN �{�.�񤴯=F��#v���ř��Ck6�Щ��9Q������(��VcYc�t�a���7or:M���&��rx����h��;�T�k��/��CQ���{�Mt�P��kV3�EMQU�c�ީ1��*R�T�H���f���<�	-��vz�]!�v��!=1�z�� a1��pZ$��V�w@��H�8>v�.�^��c��W�
���z��t$F�	���$L
7A�:�_5�G�f��ѯA�w��o⺴1�fw�Laoƿp���������G�p�������!�dQs�~41� %��dq߹[@_�Y8?פb�P������~�5����g�LӚTr"
�Y�G~8`�c��2������^7���1�ְ
d2��Ȁ��ӳ1 ��Ռ���&6�$i{Ku��z��^z��-`�T��8@�O�P��6��r��on��qDV�oc��Z����:���Y����A�d���p�d`���(�^��M�͟���$�u�r�4�kՕ�ڈ�Y�g��.�FL��'�t1k�=��#��P�`����m�%�5�+A�`�s��6 ��_�����8z?�\WZ�a��u����.f+�V�����y-8�4]��#^�H�߂fr�؛���T"��Z/4j���l�����X)o��'�d��M�@�*����	��tA/���V*q��X�ͫ̃�9��.ݥi�����Ӄ�īT���}�@ f4�_�&k��Q�dj���x��/����4���Ȓ������\�<�#�I,K�{�����F��ì$Fev׀F������9��9�x�mϱv
�!���r�y������ ������iA���*k�*��,M�:�,���_dc���o;��6&�כ��0^�Ѳ�K��m��R.FB�^2���,3�E�Nu}�H'g��r�{#póL���k��1,1��L��B0���X0�n�/��6����S/C��!�Ϣ�t����:����u�DF�\�2D���&���(���0�$�K�]Z�|A�ڄ��	A�	N��c�|�($�����9��9r��M��o^L$w�g�@�'�����e!2���A1�C�u���L���69����z]E�q�5��H�[�v���{8��C����Rv� �ש�&�Yu��\�дiMC �Y����dTj�����Pp	�oB&��B��;x}^\����<eQ��̹�P�-M�:$-��3��k������}>�_pf<]*�j"���\Z"1��|��0ùg�Z@y���pf��7s1T4��{J�a�YoT.���W�>:�Ǯ,Z��񝎣τ���ę0��J˿�"Q�mO�Du
;��Ig'>Y.���Y��sR��J��w���xn����M+?�9�[͋3�hUc�F��쌩@���+�Y�j�]6�gx!�g���J�Ю�1��	1��s諺�ȻW,F��5A���;bе���@��L_�@v(�3$5l
����Q%�Ł_f*���w�B}���_����$�����`Qt�I�d.��jޫ��t���Q����y�֮�(�q����v#0�<5����h ���Y��ٍ��K?JG�ޖ�A�JU�D�p
�N'~����Hs��Wýa�ZB_����Y�,,���M�W�h���z�z6OE���Vfb�U`��\��X�>W92�r%�X�π����~��qֳy�$v^���@�	!����/:��Fb�$Nr���ř�5�~��&� -k���o���-k�@��`c�Z�+�X~&#d_�KYvt�l����$rV'���;p�����K��::c���N��S�3���O�&�ݚ���Sxё���� ��`�[_�}�{:X����	E���[?�>�l�{�O�#	r��dk�ҖQ�-�	=���A�S�v��9���Kcv�����{&�[=_�ۃ�h�e_�r��[���B~���=\��b�^�r���H:��:���DF�������$��n��~?{�'��D�x����e�w\���t䧵o�X���M�MG�h�A���c�z�m���K^%�z�xe��T#��Eg�68C�P�[dt~F�P��'�	�H��Ɣ������Ĺ��S��v��*���@e���	���U���]��Q������b��x�%kU5Sm�N!��:�������7�|ژf���o_�dlu������_��b�����	UG�/�����oZt��Շ�X ��d Ե`=��ğf��\��`��CL5�qGX��oy��7�F�K<�O2t�}Ѓ��c/6�������	5�������~v���3H�?�w�[]�{�(��*o����Shdyv��l!͂b� q�v�#�M2C�`��G������xu�ߑM�YŉZm\疌c3�G�P���2*������tk!��tϚK)�p鶓=����&��O$Vsx/�9�4i�M$ ���������(?�JC����ߥ�a��[$��Ơ�}��B��o����Z$�q��)l���I;_L�iʦ��_Ȼ�'�5V+D�A�������L�OM�?s���%����Q#IK4U'3z~���]���\t��j�MR��ֺ<�7d���O���,=9�F��`U�܁�N�~��3��ִ�A4gHG��C>#QZ&�]f\\5'�h)�0�'�6�0/?��W�vr�����~���R8�f�dw3J�=ua�C�(�%nBu=����6C�TF��	@�Lޡ�O�њB���Hv�Ha��z�<go��#��e �����!�4���*P7�A4*G
�%�1&�uI�[��J��$p�ı(ahlB�����.6De�<�GQ���ܬ�h���D&�����$&&c&,���W��t���f��C�I>�]�rG���K4WQ�OsoY8���1A��bw;��+.)����
1l�1��`�n�����c�%?)ZE�ל��@9�7�3�U�M���s����0�İ^ǫ�������,)�d�M�d<� ��|t�3��o��*����h���OQ�3�4������M����g�W���W�{�Q
�dɷ�~/`p�t��M���r�_(<�J#i�蛧Dc����[]�w|���J'���1�7�hf�7�����}5Bz!�'M�_��7;��?#�v���'�!6�F�aOPĪn�-�&��y����J���;ώ�x��{� ̾�ݲ���g��q�t N�T%���
`Yuz��#���qr�ʷ.Ӱ��[+���w���� ��͙W(��"�x�>����!n-�B7e�b�[K-xW:8�����])��V����r���{t��ѕk2� '��s�cU�^;�i܃	'�Q�����?K���J[=��z��5U�q�.3�g�#��8����c�]U�D��GujNF�yvc����z�[�t`��!Ǯm��lЇ����F�X�0zp�s�~��+;�0�ƞ) ��<Wk�Zz��8�F��#�p��7S��1�mB��A{AT�[��<v�~� `3��ǅ�M@,�QcƧ�9Os�%�Z,Ϲ��j�� ����Ð�BT``� ]��0{��F��=�	��D�1Zz펝Y%3!K�� R��x�3\B��4���h\�8�����L= �� 2G�(��H
:�`��eHw��V��~�����}�6ڞ������U�M���3�*O\H!�R4:�:��Ħ�~���,+�g�B��*��Q&�H9��m���z��^r���NA8G����$G	ThC��M V��qiZ�\a4-�j�$%KW|Ͱ	X�w��Ila¦��@�& >���	yN6�>6F+J�i��4��(�q�E��%��a�F�m�O���<[d)�UQ*~�Ue�ct��6��&��F�J&Z��Q�x��k��w&*����&)����Ƈ�m,�i8����r��dc���ca����7�l#�ߞ��8n�`aCCڋ��۪n!K��9��Z��;^E6���sa$#�P��L��Z������}"Z���׫��B���s�2|*7�uA�;S��m�����w������t%��-Bp��T�լGy�V�'�h�@$]T1h�����v5~�͖�$�r��'I�a��z�����a� S+��T���C���L-����@)L$WS��p��tH��&U6)X�����X�OiQ�Ov��QmzgqAa�}�t��/\�`/�yzs��+�:�O���_W)��ԩ"c ��۠��S��ܫ*p����En����� �e��e��J���ՒQ9℣���cb�1�����7�fQ��ʡ�t�m�^��r ��۽�}5��������]�u>y�1�7*�R�cܖ����c�Z�sU��mV�͐q�k��hYYwRj������.v�־��x9c%�'�I!����R����&�n�yx�F��������
�(#�M�~��Ĕ�w��U�h�T��Mж�= ����������,�d8񴢼����z����_��S��L�=�0��e&�M��'��Z'JWi�vk��IK_��k�ET����b����Cg�i�w�`����]�5�3��!��~r����䈕��C���Sx�[�W�R�-;�/����kM9F��������ϻ�j�|RJ���b'v/3����n�#�?��gs)J�����t�Y���B��u,��d�ՔXO�Qm�)�:�_�D�:�/5[�b��� ��X4��$�r2!J=���_O�5��E�������"Sut7Xhy�0�Y��ӑ����zD㕉�EY���X*@zdk2Ԧ�����H��xQ&VR	����*e�3y�a��	i�HayS���8}�؁�,��y�ƶ���,��;�>�B�c�Cd�J֝s��#l��Ǩ1��#��hq}8H6�����{�����c�Yw̻��Ø���0B��Ԏ�"�� ��Ǭ��~��0[Y&b}uH�m��E����lf�����W��'c�T(�¡�l�G�l����SwKx��P���Xlϟ������2A����"�Qx���[`�'��^�U�MČ��f�6�i��B�=4�/�=�L������pO�v+�7t|��v�\���T\k�"WP�X�p��b8G7�8�������FZuL�H�Ae,
:/ԭ�G��'�d-�A�7�����Ćw@Wb���w�t��Pܭ]�pmk��oBo-���|�k�Nt ͙\�T.!k�� �#M�@���3�K����j!PǸo�h%�T�~jޜ��7�)���͒�Ǘݯ���T�;?�
`K���2�@➆X���k5��mB��T���&��R��DMd�KΤ��{*|>�Ud�'(UNR�S��8C[��.px�8��yr�6@X|���t��+��bD�q�܅O�Xo^:$,
����Fj�u���G�YHyqL�)E�X����M�Y�F�h�)�`�N����+æ������n�����եӂϒ���:0�{��`Gq�G]�<����X��7�Ѧ�O2p��w��� 1�<9��d'�]JOSm��g'�oؤ�$��Z3�{.�2�b�Oܞ�{��e�ҨIi��uQg�C:�����\J��5Ƅ���y��6ow���g?:`��Ѱ��Z�G�U�L@��S���C�ʽ�S���lh?�<�#�I�:ݼ`��"0��]��\a��D�_������R�cTEյ�ͼ�7ʡ�ѝ�p�M�����PI���y�/DO��w�tU�a#LuF`M�a؏ �@F��{q��{�+%�(��
Gw@����K�8p';� EPg���I�
��^��G��ap�딮P� �7��-�v�eL�������Jv��W�xG�m�yWw�ŇH|?o�Ϛ,�@0���H��Sk��!�;�/�L��;x�"c�ߗ\�ad	v{3��x��w���aQ��e�#*	O)\C=Ç�<G�.��lf9���(�?5���ô����Kmrg��-���i^�\$���j$��:7�А߈�ϸ����3p��`�m[�*�W�K}���f��)/d�F����ȴ:���W�?Z<�Mf�8P�cH�c\qmp�C
�=��"<TIV'�(`�����Ic�B�g�z�w{Y�U�O�:B[�9��~�8�mM�W�@�=p@!�M:���F��&��	RW�Z
S�?Iq�-Mjo��Tg$���8���&V�9_�OD����-i7Xd�,/��C���<���H<}j� 4�F1+v�}C���II�]�n�sEJ=�*?V}��:��&��O�r�K�����%F�!	��{jR���?T@��������y�ڃfx������ƚ�u���y��^fs�\]%�Ĝ�z���q�%{�ᖖ����ӣ�����P��Ht������d](K[�m1��	c����4Nu�a�&X�*g�e��~���X3c��"RtB�d@FǕ�7��8�
m+-��:����f@wWA��T`f��ׄá|��w��u�lF2i�4��%�����"�9�Vyn�(oϷ�-R�ݶ[�(�Keg�cزJh��.�>����V�С0��?�E�m8��>�^�ֈe���H�	R���WV_���-Q~�7�`��Ӻ�jJ���g}%�[J^Ud9iKBs��j�P��[���S$�1؃��Նm�S�Ă̓Ű�{�H�[�ջ/���� �<��x0,Z�i��
%ql������v`pW�R�-c�=��N��=��[gd��d�:�
��{���+�á����wX|F�'�M�~-_��'dPc� �ɕ(N_Z�[&Wt���\�S�Rg��)��LS�V)���a���B{��RJ UIM�$_\�`��){
cP�n,j��}�х{���oA9��Gs�ʔ���	���誵"x���̌��t�a\�R��%L]fc ��
��T��j}i�O�Z��9�a���t�>bY��V Ʉ��"+�|��ט��F��K�j��,�3��*
%���!��l#GOa+^��+܉�����}B�F��=أ��)/%��`��Ւ�XE�S摁P��DW��� 񒺡�u�c�g�B�F��m3��x��<�C�0M�[hF���Z�[���F.���o�Ƽ�2߿���iː��xK����M�8���:iu�P�>R���<�_����o��T�*���tn�VLQg��dh�#���a\���8�}���Z��?����C8&�����TM~��DIJ$֋Uq_���3��N��SU]&u��B��n�f���~&�K�E��+����x
���
G�Զ[H�gG���} ݧl�&��zTh�@a��F#�")햠�߽�B�ʸ�.�F�NtM�}uq
�
!��m��*�Z�ò�l�L�M��)@�[F<Bd�|I��۽m"	q��^�?��W(��-���Ӯ�t"����QY;��gl3��d��B�*��ho�2��D�H��eK��k��9��V�x���� X�^HY'.y9ض����?Fj�{�Xgם�C���c��|�"�YR��g׋��!�o�����[Fӝi����%��N�A	��`c��No �nZ�`0�v�J��x�F�j�
�ٱ3&v�ݺ����`r�΄t��ܳ�}II`�b�2"���x��8�®�_+U� �o�Т�����+S��Gx7��j��Q�D�l*NP)�\���0f����C�"��R�
���"ש4 X�ϦM�{z͸ܷWo�)�=�9C~�\���g��;�,0�>�EN��$%�9ju���\45���+�(!�|�CV���v�.+�h�ɟto���l��C�J�65�p�Y�N;�L�Zb�a�w�=ު�p�������8��0]���ݢ��:d=�hL=����^ufkD�'����'���e��-��O&7� �Z����'%�B���Ǻ [���n��"��Mh�:xptq��C{KE	�j_���W+9c���,�,unϙ��J}�k�'2�r�)г�Z26��,7��[SV���j�R�I_��d����YN����
	���b0�+�%J�E'��L�-Ε"����C.�_wV�X�QT,6�]�4��H�ڏBr�Q<u�I�[ݳ��E��y%Z��D��z�����G�	Jï7ν?��H���//��'�b�s4r�BDw�@-iH�"7b,��3@���Tt���o�mL4DAɭ��
��߯�x� �	 ٳ��Փ�B��'Gsv3a �c��_Z'T�u�b��vb�F�|;�E|��'�7�iP��-��.�a�@Q�ty�Y��iZcIqGv�kC0�b�����ˉǆ'xRM��L�7"����*<I��1p�x��(�,�zz9�� T ��m����Y�z�LaJ�2����b�0e��`�\*L����_$ށ�^��\}E	�y��.�m��n�s%k�	E6�k�"jm..���wyDCE@"�<������,���O>-�&�pLՈ�Ս���|����6�q����	v��FFDщ��j #w\}�?.ʨ΁!iV�`�$	�}�=�c$�m�)�բ��o�"M�/X�~�co ���hg
�G�g�U�Ir�u2@�ȝ�?q�j�@k;|i��)�þ?0�y��9���#����:�٩͎o԰xI�7<�ۦ3_��&����ݾw��8�WUt�4�j
Bc"���9E��P|�)(wO~Y�9)�
H�����s¬ڗճ�}�$ajگ5��9
�F�n~>U�@�bN�y��Y��L���jK׾��6��][JH�T`3�o|��Ew�9����L�����J��u�X�r�!_�����1��k
�fX�s̒mk�0.ao�jN1G��Si���fP3�ްM��}^;�M;EWR�4c����+����xaʦ\
]۳'�%�xʋ�0��g���@"f)���4\��������fF	fQ���*,�:�y	�Ɏ���Sţp�.ff�*E-%jb�exZ_T�(]1#�����J��dH�t$�t�qqP�t+�E���C\9�+MCNU�";qoo�X��-,AQG�b��9��~r.�Α`0*)ۍ��öq(�����Y���^Vi�ͥ56k_u�Oxw,/�n|��~�.7^�%Ѥ�-�
0�t�]�8�å�r j�[��~ԣ���a�r��%%�bm��t�'h8;�k����M�K�O�N�w'~:G�5�_�	OЯW���0!��|o���!=����R'�͊��N�%����I�s���G�9pf�59Xb��8ľi��<7�pܚ�t5�vq�n�E�΃"�X�4������B�_́z��o�l�
0��?+���Fq��.5����
m��`�{a���*~���Y����;|0`*k�6B5�\D����!y�6NNc	\o͟:C�\ow]L[?۵�j�����������{�>�o�LB��{����3WvS�<��>��x���*�cm��L�����q��V��2"J���z8����H�L_�P�ü9���0�'/�����LP���)�u0�~��GQ�]�W�5�x�����7��k&�>^K��Q�b}�_�m�Gu6�k �'���t�?bC��:'6#��c��ם�H/�S�P?���a�4d��j,���0�;K��F�?O���	)$��&ʂ��Z���t*
Y4�{�g��ل�A�㉀y��z7���=DYa�Oዲ����G,	"��,�9j��?�|�;YB������� &���f���M���݃�V���{k?��Q���i�d�����[^g��D�
���ze�)9/�T�@'���%mpd��I�"�9x&���_�j3 �LR@I,���3��t1=���=�2;3#^B�����q��U�����.����N�	�^EZS���S��)��NN�T��~!>GQX#�\�")1��Y&DuHb���Ayvpv�YT��Bq!	�Ҧ��A�Q��Q��Ϳ�;Nm�y�zu�� �'OH��B�y�itX�ʥ=~1�$���4�q#�:��+�0��-���e��F�j���.�
�J.w�h�)�|ߺc#��E^��!(�d=��T�.��6�̣�\��q�˚������AOY�Io�ͩC�ε]f~��*#�r��9k����ȅ�;��.e��a�e��48��S���N��HAI�ۄ��,�?e	�t)pî�]�.xD���Z5`���0V����H7��7vy@���5u:п���T��RڮzD$����d�|���Ԙѝ��9��a�/�U�0������[��w�_�~�õ�@H��f�+��=<�$i�99q�):���9��f<�r[��TH%���~�`�ϸ�  ʣ��q�o ����]={'�;���!��b�q[�1��A���c�#�&<�l�歽O�ɋǓ}7�i�`�2��H���,E%)#��2�lj�1��j� Eu������[b/Ε1w]�i�Zm�����S�7'F��8k��vd��7r�;�ί�� ���ht�ao��lf�'�&�
k����PF���7�@ڍ����C�`��G��7L3i�	��;7}��v�G������a��q���M��Q�,/T������������.���!W��J``�����.p�|��te� ���|ՍlR�V�LOP�cȦ��}��6�?M#��Vn�VF�Y��wY���Ԯ���ʦ��\[.���?5�Ұ�fsh�A����8j!P.���˳^94����3��&�T;:�8%�n��?&���dP)4.S�=�����FƷ{�̿���`�á򛉒YT�H��Nr���W{DB&r��a�K����ːt��ٮH�nһ�9����n��^c�u\s�LȬzx�q{c�(fL��F�����y\f������@��Н��Sn�Ɏ�
�B8��XW��Z4�u�{@;�14�1�}W����O+�0�o���A� _usP����͸\��I��*��ӌT���4�7��� 22h@��igp�u��z���v�Y�R<�+χ�+Gg�숵ͽ�V���_v�� >V�� �Fֳ�o,���N�˔>�uW��.�׋��[$�c&�v#� h���1�Kx�Dg�����֜ooHL^�BI�Hn	��}�O�a��H�Cd 8�'��L�X5/.�}�H���Ԍ�A -��zۄҵW3<��7��%\�K�%.ػ��b�x.�=x�	����W����:�󦄈�H������TM�}��?q*�i17ҹ��/C�����Qm�����P��]���g���9Fz���ZD��(�*�+�3te')O
��g?���a롡�r��M�u���9g��zS�2W�zy��	�!�3�b<]嶇��I���:V|�O��~x	i�q�����6^qqz���� z@xP�:���\�:@�s�FyV���ZzZ}D��l�-m^d�N�H�t��]>�q������+@˞�:k��ߢEI�����X�lĩ ̨�P �\do��W�騀���񖷮�rm�9.s�Z@�"�}�tJˌ;PM��	�n�X;�)���id�Zh�R�,��8��}���v���o�$���s�����ѡZ�|��y��B/W%�({$%����;���t#�bQ!aɶ�*�=���Jxި�̀�>y����g�+��U8� �l�3"�p���`(?a	?��L\�H���﮿���ˁ�=�g�Z�b�S0����!J;Z�aRX�Ryb�ݯ����1q�Τ2Z���p����x0 �_Z �������	_��|ϙ9,����dg@D�.��K����(���_�b3�J���)m46w���sL�y5J��mph�5!@4�:�'��=��FP+Y|bqm�Ye��U̽<E�k�����V���~�S�?�4��� ��YA{��z��j�;d5ǀ`037�|b]�g�)ʧ��d�`�z�r*��2]��.��0�s�3:�0�*v^�X�B�$�#��9.��&��i�Zf��%QK�V[���ԛm��L���bY��F裊>DkU?;#B�+�<G�0�&6�P����m���J*���e�3�kcC64i<�B�vIKK�{5�!�m%���J�j
x���=�|���x��	��RtK�5L�@�E�z^o#q�|*��(����_n���B����7ӄ�y��T�>�p\0�Ҥz���ߖ�8��5�/-Ht�����=�#�<�	/��T����OR��W��^s��b��5`���l��&G�=�:���@�Tg��t���]TY�]�h�潝�a"�/��*��/1|��ISg$�t9k�ԝ9��b���v��W���&���#��E)�i\�2dBe˚[���fw<C�{%+��������0]&����j+I���mx�$�1:#؛��[2r����	_���z�&QzU!M�e�����E@����C9�2;�؏��Id�c�
�)翬ǝgK��-��D���'%}���+�[-� yc��'j����
�0�/���Z+�S�e�t���1�n[�(f.�
F����U_���z�p���Z�>��ow�	C��X�����X�@�N(m���i�DF�F|�(S�m����#�Ί=�*�f�,���mb|Y|�l�o �z�*/�e�xӺ�G*
b3eI)�4�[8�4��}�c�M�0���9�@j:����?�,�vU�P&�(g:�L����0�\��UQ'��KIOK$�rm%K$_�������y��(Yp��'��_�)����',Z�Z�k�.݆�B�����W�Ӹ�����7}Gd�#/��ڻ����i`��R�SZ�5�{���"0�(#�"���h�ڕmaX-y��J� ����l����x��Z�����@>�˨���۟�%/,��wI7����KI����9��ض9��P����\Ye�$x#{�9	��ڵ���֢������G#lr�R���
���|�wGM��WY��mMɫX�ѹK͒��/٧�I"t�p+��hnǦ�OV���4.mK�Gڏ���������b��OE�q��:�(�@3�nH�p��+���_~x�$[�+1ȖI�JwiZ�	�n����  'Ʊ絻����͉��K����9��#t���I��/P]͇T1�Uw��)FNT�<gK�Fa��=��l�\�=ߘ�K��['~����]�xs�r�����!M�@��- ��q�!#�'��]��8�+�V3�����F��a�^Ky0=�����21�)Qu�V0�6�Qh�C�Lk72+��t'PO�i�
����.�j��v�����y$�߇B�@,�Lv�=��a�z�^��\��'���'���P���L'2G����#Dr>C�sK��`������Fws���7��c*5�њ"5��)R?���G��f��]J�,⒨�F���VO�H�RK{��V����n���ep�N�a���#!y�Ӵ�>YX��_����G��FN�ɤs�3���"%�m�=ȫ�Za�Y�/�����o���O�������g�ֲ��������Qߛ��;
m{Ѻ�P�=��{�s�pk��C���$Dɂ[׌t�]��D��i�O��8]��eޡ���هyv��:�~��FW�w�/A�
�KX��ϡ1.�ܿR!��M:��]['����>���H����,�kXd�v�1S���*vIi�Y���5�?Bl�=����4�� M���Ҡ/g�`	��Uyw6�8�F���Î�YB�E�kο 30�Q�hw��v��7��;G"���W;p���,[���"r�ł��q��Ȳ�p��Lԡd���b�+���Л8�6ԝB1��L�ţ������?����z�hQ8E�øF�u�H_��i�i$��;g��ݳ*➫�4�"¹��e�E�Fbu��R�-�Kn�L�ܱT�,��>���$>��v��)o��	�>�^ҹU��9@G��DG�.����܅w��q3M�ԥ��ȴ�HI��ru��}t����W��E=��XU���l��5lfd~od�>I��P>2�4r�B�����E}N]������/=�؎��*�/��C}������4���8�Y�=�m=�JM<�syz�,�V�0�E�����h��5`xL|̬vӡYƎ���;����3�+X��*�-d_�-���U�?�i�$�-�:g��u<����9,�&������\xar*�X �5Ȥ�QV���/���ܴ=)P����m�(C9(���o��S�����2 �E�t*��㲆�@��?o�Yѹ�ʾ��%��Ao.E��b���4mAa�P����x��֏b�x�L�c�'U�	*FGs��)����Z�w�#��D��CM����'�D��O|��â`K�׈�!��ɟY��:�C���j��m���1Q��c����/����Q�z`<���9���{�<����/��/GZ�L4,�x�����B������*�p��8� C�����9����{h�D�'k$7�ע�D����� �j�GS*�*ee=Z����:�ѧ������l2/�ʳ�=��9Y��L�2�q��Y!A���=�]����C�x�ʰz��RHI�/��1@u��@K�"��S��O�4�$���-���ʏ���&)nB�)�O�wVI����[a�;֦1�am���_cg�-�'\���!y�PC[H1�~۷U��OH���Df��ebh=�M�{�T[�D�0<FS�1���dM"�W� '�&7���)�{�s�b�S<_�4���b7c��1'}��<%�����)]�G<W�>����6�_�_.qnX'�؞Kjo ���t��Y�	t��sL�b��T��e=>,	 T6�ک�	�f_��Zާ�_�
p�o�1SG�����Ju-�9틜�@[�
����+�by�euQ�i�����WvҾ�'�����S�C��Hnorx��T�>ߋ��M6�Q7���w�o-�R=-�Lʒ �Ò�Z�Џm�!ZM�������+�I|�s2G��S�r�a���(�>@x��Qc�LeZ��QmuH�	�寁�w`iu��[�e/��]$�$ib��.w;�ǳ��/�ك4�h|Tt+��}ٸ�M��pB���Đ���L�8�x�z��QC�?���#zX%$n&�ϛ}f�D;:��|��A`y�� Ľ��l��& �}bH$m��x��W]A�Z���~ςC �r�gݘ�y:u� �3s�}W�0��ڍ��5ZL�þ�,�n�0u��:R!;���!��H�7��R�?|�fW�����}�sy���g4��d�]m�����AT��!A�O7r�65�:�J����O\&�s�1G]�tؑ �۲��чb��5�~HP�߄A�`|��d�/�ϓ�Վ� �� qz�����
=ʍ��6k���Li���1��,1��̻��[    �c� ���������g�    YZ