#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1495845105"
MD5="2b665ec78381ae937a01d8fc8b820f82"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20208"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec  6 18:01:52 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���N�] �}��JF���.���_jg\`��^� �-��z+8E�8���KDc��ѡu���Vq����L�rV)�Ӣm��.�IwnȮ[)v՚d��� 1LV4YG����7̧E�W֓>KY��{~ ��W�.�2S@���â�:7����5"*�J*ݲ������1K�.�jC��bfL���Ϭ�z|@�BjQ�W�f�_5�݉��W�����C��0����W@��Չ��\ȼ��[���K��8v�T	(?k &Ex��z�x��o�5�7h{s�7�CT�#*���q�FE��U���o�
Tp}!�TVl_�-G�TP����ҎR���<����z��lA�tV�ʎ�	m�+9��`Y�8�]��]�2�"��� �y���8�6����q����V"˕s�N���g!��/���B H�@G�VVy��&8�xOy�btנpD��2�K�mhc��/5]l�K�1��d��xC���B0�j��s3�(�

ȻI�އ/�����׵|���L#�tkz��x�H�Idߖ	5�~�22f4���z���v_m+%�����Ԡ3�)���b\�u��7�K��*�����^�����Ύ�d  �U��9<�����:�~	ٷF6�d�;� N��A�)���v5���s��%N-�G����f��{�s!�ON�j �y���l�	0K���oU.ʾ��[��&:kz��(�ڂ�7eꆵ*�7%V[Z�/�x�k_��]�bIt�3)��ϑ4A����Y6��.��gN�EU6(���w�hQ��K���pf�B>>)��E|�vJe	�bg�Y�,�	�"-� ������k��O%��a��M�/�f"x�)�1ɞ�}�.O�N���-�Ԁ9�v��B4�s��x3�,y߅��Ue5�:�����"bչGE�2���q8m���F�M�H��M^j���n�j+굗V�9��:O�|���<��0�mc� �A>$�)�i�nˤGdp���$�Qf� �܇�{�JGW/�l#�>H0�v�{ �@>e�|��3��\��)����-����Y�e�tt��-3I�a���O��@��r�_w��2�d�~H���{L�����������|��_��}�M��0�.#��"T�e~��ز_[n����N�Q6,�ݶ�=���cY �f�9��ڼ�cΑ�@˨�wQ_b�Y,wh|��%#+�#eN�+:�}�F��Ӑ3���֧�h��=�P�P��W��v��t�F���X�dGx�'�Ꭸ���Ҵ��w�w
�z����<�3o��e� �P����\N�_�����l[�����zP
�$��Z�>تS2�vC�*}�n�i���Ԁ���Ͼr� S������;���c�4�&�����z_�-b�5����3��9A���w��������@3����2����͒$u���h�!ǎ�/X�oY	4�<�	���Lp�b�m������U��Zpم��oe�F�W���B�!��p_���>�L����FBIڅ{�������^W�G��?��r�DnNao�4������~>w�$'���\�iK��w�X����5��~m�{��_��?hB�%3\�-�]�L܉���(#�J�q�q����4}���$����3�r��rR뱍�PS�����m?r��<hF��rF�����5`m�0�����/�n�_�*�`9�H�bb�X�������q�BK-�zi9�om�� b��'��@�����NK�~=��,�σT����(��ɧ�Ġ���=��-*L����������^`�i2Ui��S���N�=�y�����xF����㱿v\{se#�+d�D��7N�Hq=��%e�g+���{nR9��r���F�q�\!�'�h��-�Ş��Vk�ȶOt[�Qi�4��wI����Na�H���z��ЏYl�3���?�"2��4�L-VF�i����/�����g���E�̩�0��6��j�@��D�6�vP�j���S����I1� �37���3rk�ԧ+�U����x�X�N�,H,;�N��[>�K����V�O6<�Uư��?��E�@M��dU���^A����X���D.�FUm:]-Q�ZHo��O�Q�\��f���nE��{}��p��j�>֛����nu�c'z*n�iǪ.柕#�������x�C�c���q�:��	zM9`įz6Ӧ���o���wB�yׂӻ�OH��:.�1ɑ�������$죓٢(��giƹ�yР�epJO�4dhˣ�8װ?����'Y�K�Y�rI����hG���X�s���9@�TGq�)d
NsaUP4m��w�J4�yN��@;�������B#e4��{�dX�����= �������,��xI߉
�T���|?������ف�1p���6��`���Y�=��e��s����*����E�<�^��/�]�����������'��[���[ͫ��-�2��i����h0�9����Y�K4 ��6j!�՚��_ �K����W�?� �]��=Ax��s�I7^�A˓T/O��M ���cY�2�s�N&:8�!��&�ߪ�Dv/�)I��ힼ(��<59�z]"�6x��!!�[u��W}S@Z����Fb��U�xg�j_Q�mhH�$PW�dc��ီ
(C�<̄¶��k˞�9�{�;]*���=��3w�Ea$�l����G����'5����h��I�/rI�e��Mĥlk^Q�-S)�V�,� �Ň��mB0R���U�C�	8]�?�lc�3y;{ؑ$��&������/X�����7�'ܠw�������b��˪G�%�Q�K�n��4�*�5/'��P	�ڔ�Ɉ8�Tز��;>�f�9�k��l��4��(",lM4���ECi�oE^���e��a���� 0+���Q,Ӊ�OV�\ ���2�+ؙ������0��V>T4�2A�����������9�����,b,V����W9&��o�>�����\ZI�}"Ďkr��A��w͍��U֟#�Łݚ౥wM����{�_oh��e�|��]��65S�Q�AD>l`.<�2���{�7_a��9�a��/ 7%�J|����[!)�|���	1[����P����d�-c���P�!�%���)γ���n�J���հ��#��%�M��h�C5��U��)���G��G �U������= ��z-
���O�/R��-�B�r�[XF��E�q��Y}{��I�Й"pfLt�uFt-�X1~����P7�u��P�B�vp�2��b�AU=�?��@s��y���+u��LX�T�J�5���y٧=u:�2����2�t����/pį�.g��m��ǁ��bd��,���i�k/�*A���vs?*UE���5��L�������~���bo�]��Hv5ޱ܀4�Ìw[,�gY"��1	�x�h���ޮ}N8AP����G�c��,+���n�o+�G��ǘӼka�>���,�b� .6Y*�6\s��ぜ���DP9y>󮍑{������Av�����:�����؄ P�J�P�J��%E�q�9����F(�?G���B߁��	ם�2}�1�������q*L�u�=���rtK�W�j�MѰ���0!�/��ɘ�7� ���0f*n��tƁ`8!�yD+��i3��<?��uE��S�?�_�U.��|�Oc�S�{���JP_�E�*�m�W�1�Mp���=���t��h���c
������d;�V��̥�i�Wo���N�����Y.�]%xz��O�S���^ :�e���Z��-��.׹u����?����P�|�ܿ��=䰳8S8�L' ��#��6�AG���YЎf-�vƘ/��¿�K�헖--c#�=(4�������4a3'@'ᗩ]�b�gnN��f����Rg�����t�N ���Q�P�&M�F_T��m�z�frt����������L���4��q�b�q5��n���߹��6��Jw��4�1$f%Z��5p���2�^w�P4�aZ�ݏ�盻���y}vX�)���2� ��z��ߍ���40��7V��b��7B���7�(�X��l�<��yZ�V���j���|ALP��WT��$Nn2�a�X�)x95V��4� �;��h���c�֩l���:���n�R��E��dp��e��T�@^��k�֝�G)�X(�&'#߳�vy��K��$I���l{`}��-#�E�T�\���w���m�l��mE'(:�?�`��k�G���F�Jz���p��]�B��]��f�y������< ;����@	���djU]�~9�V������{�����!8=T'�3ڔ�uǹ�+��P(-��a�B2��e�;2�C���B�'t��z���hkR���t�j���
?�Se5�F�|(QU����Z�S����N3�w��&<��˙���,AܤY���8Y��T7s�����~�7]g�jY���=w����+F�3�-�}z��f���x�:�%�x� �����8��빽QCu#�����o�S�E~����09�0C�������z�V��wʱ�X�hң`�C!t��w���X���t0&yn��`���8���#
v|����	�NN1�D�Fn�뢋�V�U���}��&'�|i/_����ivʱ�-SN^�1�&���ҹ�d@:=�#6SP	�%b����\����/��b�Z���Չ�j)�}��>Jrŗo�J��4g����'�6KUG�å�-T��_B��a�Y�����#�A瀲�_Sd���G�$�P�,�>d�}��@�<=n<}[�+�ן7�B��J8�0�B����?�iF���J�w��]b|��X��|ꮨ*h񹅛�s�]p'ڌ��&q	\J�SIO��&6�6�j�9��C#Uv|i�"
���7>ݣ�.b�^�s�3w���ݢ��;��U�b��)�����<�.@�,U���ɱ�	�u���݂Ā\���>�/@އq�E���)/�f�
1Nq�������㘷 �e��m�5��if��!��5��'���I��B��h��t�\��K��
�K��?~��5X�� JT�,H�_	�+b(w���|�] �De;3fu/�'���4¡10�2)=��������b���A�񥠐R���ҽT/�A�}Å2�By�B��Vy��k��
OG�y�K���#?>����˭A�c�����L�Y�W�Jo|x,q�8;����<��|�Ѭ�o	���Vͩ0,��;%$^u�ϋ�Zc�������o�sI~M�l��e jc1���-�|��s�lLZՅ�Y�5���)/ �g�� �Z�!B�DYm-�����o҈^W�U4<�zO6�Ժ���;_�e�pK5�c��\�]��c#r�&�\o���ϣ!P��P�>�Ir��NzK�Ź��m�X�5�?=�F���F��G����'��fyy�о�˫O�����j�k8X�[���}��T��5�Ǯ��^��Z�����k���r�T8i��*�����%i;i�K�< U<T��5�'.O5��H��,�v7��f���|֬��6�ik^T9zS��H�,Z���X���J=��� ��3[�¹<�G�9�z��3�p�S:�s���*\�4����cB���T*������p��5��F��7x:�v��v��d=��������������q]U�,��U@	�$OHr�Z�� ��M#T�����l'��՝k)O/�N��˯k�,����W���Ɗݣ&$��4�䦶��}�������@;��ݦ-����7�|S���n�@�9��L8�&�`��W��(Z����ņ"0,����kf�X������!p_}1 gt��D�� �kH�4K �qݴ��׋.�_!������Ki�:?ib�{�I1����Bs(Ӭ�P��3ֲO������J*�δ������wX�N��
�e��rZ������x"4��l�efu�L�h�\b1�o{NS��>^����~1"���u!^�	(���������'�xw�u��p�,�oG�}Eymc�A!��:e��[R�g�
�~}����
P�Sd���_����5C�'=A[���_ᛍ�?�È�*Wo{/r��c-	�]�Y��9*H?�z�7��w�36fz=������FG`��=�nC�6�V� �W��zM|�2���{롸�%.2�g�������+��F�"�
큂
�d"��>�PD?0ٛ����0ҁ��qUlP�!�#Oky&5m�lP֢�<�<�u��74ӱ w�wV�I�t��5���!)��15UR��\�(��K��R����&��\��}S���4):���l+�Y��1��x��7m�L¯V~�M~��TOC�[�z�x.����K��s����l���M��߃�"�����]��`Ef�I�M��3�H�bN�K��	��j*���H���T^�^�C\l}[ �����trL�1s�K����f�E��p��o=��1�B0{�������,hu�1��a؃�6��Aٍ� 7>o��Vo���"sq���(�@*�QKU�y1�ǒ��5�K|��H۸(�\���{��4GG�?x���
�N���ލ��Xd��G���c����$��^�Imw��6��F�k��Vx�0$��� U��QT]F.���Q#�K+��*���j�D���B��[�s3��g:�����V�����8w�ʏf����;�qr�׷ޝv��}��z�cR���|�^��}�D@�IJq�IRGFj�b���P�o���3-�[,��{Q�;8��$��}"�����:t�������(�o�r~F��՚�!���Fo;�����у�WU/�p�P �D�m��!��ڳx(\0C�
q�ߒ.�Di���O�����N[[�\xgh���*-�c��Q	�?b%��D�af�����o2�x���o��^Cψ�i�+��7(�� Ϳ���~�"3%ar�	��z3����R�\��9.nb���@,\��7����4|��7+� (�<��k��뒟M@��6)���������t����/CX�h�Q�!�oEhDd����k�mI��6(��ǯ����%T���*(��ۿ˙�.-��5���xa?�����:������!����|����}MT�2�q��楁�E��?�"����wĵ�Ym}w�.�q=���O܏���#S�OǈM�9�@z'q}�o�|�_�@
����ﶸ�a���ƛ��[��9rb�vq��<l�e��	s����l��B6���uN�%�iS���/��6H�^�}�����B���z�y MEr�}����|pn5���5�v	��(�ovk=�L�\M��&A���=Da�.L���&�`P�+����
�(`G��r��dis�}�y^ʹzͺ{�wW�SZ[�g�(�&��E�^]Υ�����u��-!з �m.�ٲQDT�4�z.�1R�Ù7�?ږ�#@5%`3�'�
M[g�����-,-.N�^E ��$B��B��)�10V�ׂ���˫����!w�vF�eJ^z�#%�N�`�{������ƕ�1�X��q��;���5@��� z�D��@�cc� Ĩ+7�4q4�wOO�UVX�-{	���r�o8i�%h��<kG����#�f�;�7]�����W��M�5��+XD���^��o�@/�0s����F4�6eD�~��t�U� �;�:(�=���'>����WJ�K؃;N�r�(��P��P�]p��r��Ȗ�x�Q�;y��w��ݏ�������]oldekoé��A�D��J:`k"������n�|S$��f���W ޜ���aV���Ý�<L}��# ����ą����N�V�T�t_�:���2=���G~������+�-�� ��7��ɇä��:���
�.�2�f���s��L5RN���6���6�4ܢj�C�圖��և���T�(v0:c��	%���0I��MQc:|xH��+������Y�%��G�U�e+�\����Z��;�`$�c���8�Wyq�ָ�$?�����حX��\�ǥs���Ė��
<�?:�Wv�̳�oa��@�*H�!6O�����x��'�����}�����P�������QMP������7j��n#P�o$�����ьol�� ;T)�	�A����˔f�/�IB-N���9�b.f���=�f6nC�����|�u�#P�G���=�N���-2����sj��8��i�c��K-����5U'~����-�%B�p��J��ց$U�ȓ^Ѓ8���m"	�\����>�|"�!\|�[֧s��� z&�b�LF]��w�fj{H���J�	΁���#����s]p����x��Kz���`VEgp4��|�����)2�8Q���I���r��(�^L̢�te��r�j����k���8zuG�������?���18�3�6���\�i�"4��<�(�hZm>����q�G��,T�C���,\�.�?��Gs+�[�E9}p+���}��oc~%iܥ�gS��6�"̃/ ��	����0���危��6U|#��?�v;g�9<̪ߛ#n�Z�oB�W���T^�
�	ʭ�]~F�!&��Ax��*}-^�+rf�bl���oV#�%�c��i��Bd}�<�K<� �SQ0g쟼n�U@�q!����K=~�ܑe����rɷ����/�-�b�MI�N����9����&��:\�xlS-���3y�Љq�	�VL~4��'c�n���������2�q�tױ%s��m��[����J*�F��3h~����%D.�_��y>��� �BM�tB}�@�@�e��B{����|Q^��7xy�S��-��j����$��j8��}G�	��A�)� �zܕ^Ru=x��)�ު����H���@�a�=&�F�D��)txr���1�ZF� �8�<�m��Xm1���4%���K��4w�QJ�D8vhc���l��ˎL�{�jM}d���܂s�r��c�A#&���n�Uw��@���Aƙѯ�z�/f�
�s��J�2�4������a��hu�1�/��r2��:�v@7V����J���%�>^ ��b=���XK�6Ç�)5�����E<@g؂�W��8��$�u�~�?�Qc�@�RU +��b=�}�g&�%M��D�����Q]VZ�8�16Y��Y&g��>B�+���{�ipr��T�ѿ�[�p���j�G�,Uk��a�Hy�`lp����/%-sh�{7�Kv�6gQ�#�p�#�ܤ:H`ݴ��18phʠ�e^ ���$oY
�m0H]���@�x��C����>��J3��ͮ��H�wy;T����ж�"�z�>\�"l���FC�Q��?����\T!�4�i�ԣ��7y�LW�F�M�_��
ГrI���ɨG[��}3E��XX"�	�(&r�`%+:1�����"�����?�&C��Ҋ�4��� ����*�N������Ņ�1o����@"�ӯ�Hh���%�a&e{¹֙�����D�8E�]�*'�����s�u�pI�˵�=�;f���V&��=��|>{�j+[��Ir@x���{Ad��*�'A60RJ^:�P=�B�jX�\X���RD)�~���ze�ѱ��o��fǔ`����S����񚫧1��8�W�A��V��A�S3W�]��&tq�Pew/-`���k�����h��V�e0n����`�����~. p��̣Μ&�Ob�9���v��I��2l���l��^_I��w�������D�,��j-&�6�ڼz�������/A-A�c��Os:o�+Ӛ�6��N�+W[L����Pw�9 jd"mFw�� �+As�s�nǻU�7%�&��裲3��KJ�Z���y�y���R�)1�'���nލ��o�~M9K������c�\��Y�Sp^�c��~1����bL<$�q玙<ܚ���o}�\�v�\�=7j��r����$Q Eh�r3b �(��]j,�.X��zv>I_mʉ�p�~6���:���B:��$���~6R�|���� O��l���[�����`�B��&p5p(�є�a�Ԁ
0�6Q.�
9���ܶ���k���S��R��x����Шj��&�6�6,v^}�yw�j&Խ�r=[n0��D�5'��t!\H���ߘL�h�a�ϋ���
м����H+��N!��D�`ۦa�dH�X9\��<�� � �Q�]+�D6C�X��닧����9�r�`��~q�����~~^�;�� �˧MP�Ʉ�8�FţV�b��� {to��^�߾��Aq���b��i�yǡh �@]�c�em����F�Q��R�cOt����SɈYe��j]��u�Q�������~I���&��ԯ���nQ[�i���jo��H����˱�W��f�W���U�f�����PIg`Fe� �Y�&�����@��� �KSR�6WP2�e�'Wa�R�y�\,à�/�`��ͮ��1�e�����e+"R3�՜xD Ga�9V�;��AK�~���!2{*��$�$�x�����`��4� ��-��4c�!Mlz'�Nڟ��~n�O�@��v�R�UZ"W��-�T��Q�Y~}�;��ܜ>�fJ&�L���O�+\C!�K��F/f�X�x,O�vN�V%�%DF��4�+���bO串��v����v2`�^Tdi���Ӕ?��[j]��쬙M:^Hv�Ђ���`��9Vz#v���7&4�DP%��}�q#o���9�d=GÚo����(U�C_6����Fu�G��}�cXJ���_���Nw�2#��VیG�ˋ`�6�r��&�1�̷F�j\��{~��y�7��t��o�1_��֚&�{wG���eH����^G���ꞩ$�g�Ƞ�1}�{0ʅp*�Դ�m��sZ=U9��T����_&C���ۇ��x,��2q�����\���G:�UqX���%���3��bm���	�4�	N%�6�̭K-�=�Cx���O�g�����_m�Ó�	�Ns���q<we�IUY+7��Oe��)�'��1D�:����`�!o���|SR���y+�\rCB��m�y_��Ŀ~� ��H�-��)BhɌ1�z��Ǻ00����Zfa(ƍh֖�-Zs{h��T3�~cڄ�-.���oa}���� �25�_{�px^�'�O�H�(��?��:��y/[�^-G)1��E	J�o��,��y�Ra��r(���ȉ��/ܗBB�bO�@�*��vOս���_X��O�`�$Z����1�nV��v/Cr��gGXC��IUG1N���� �|�k{���h����"�7q�������F��f���UF�#~=%���HB�X樐���ߚ�S8�l�g�g~F��*[��� �?��I�_Ѧ�d�����d�>~8��`����py����wu�J6�,:��pd�&�`�Ċ̊�����i����
�:7��,�>[Eh���1�a�d�-�{J�����Scf����t3�o��n��9RĲ��k�ѥE��=��+��Vu#2����ģ�ӽq.�'�����Z��3�s��p��:
�4��	�C`��C4�S\�ىr=��r�L���*�$�K����"��Q�H�������u���s}ȭ�{�<�����1�A�JߎN1�}r �L��d���u*�gv��1-�9͊�F����}���m����|i�*XI���d���K}@��I��bizn�ͪ���J��GfL�nH��h�=<P�P��J��`��^�=5�O�fl��2V������ͭ�6�|>�[}z�h��F�#)\�i��Q}���w0����+�<����ݟ�?ދu��AjD�-�v{$�&JK�$�h���-;w��=ۗ�Jܓ0���,�YB-c��sH͚�eRN\.9���������磱�r�i��f���=��T�C-���#@��F|�#"�V�|l��MR7����Vm�gOF`�u��4Zʔ4anP���^��{v���=��9U�����f�d�H`T��Z���筚��i>
9����]��H��9*�}Vi��k�!�1:
3E+�AÅ��'r��	�����F���'�J��ݖ��qF���QJG�mA(���2�C4��3B��P&��S!~F4��n�"�-�JWżv֔-�G����I�J=��X�D#��IN��Ǆ�/ڎ=���q�cr��M0��
~�� ������I��P_
I�|�S�$do�Wo/����f���n\�.�x8�K�o4P>Na��{��_gr�B��Q�"�Lٞ�_���ߜ[�O���J�#�L0�p}t��z�T����y$6���w��\�;_�d �{D ~O�������7�#�Z���NI�p���'���ty�/��i�Ԋ�tƂ���d3�m�Y�&��h-����8;��cy}��Yr�Ն��J��~��,���?��a��^y�o��.����0y[m�&�,Qs\���G�ڕ|Ξ�Fӫ]�1�����2Ȍm�_���ɿb(c�fZ���ъJTx���)����=��"�#�z��`���x�^nz6F����]H�n��u�-:�&��o+�H�~��;���S����xh7�L��f��ga;�	��a������&���Ϛ�感� �
��[���8���ږ�9p�WHm:��\ ��dC���}h�R��a֫��z��Dt�r�$�s-��b��L�7)wfn|�q\X�]~Z�1��]{��l�0D>
8+�j%}JQ,3b���X-�O~q^�T`�M|�ԄnUJo� kO5�8EL�	e��4�R�f̟�m����h�[�'�B�/z'+j�q�<�笃N�)��]��J�<ߜU�,��i��D�Ε�CN�<�7s{U}��/FA(\<Q��_Ⱥ��~7��N���n����m(�s:�&Iǽ7?�e ��oٔ��b�v�G�9a�r��¸3��VɎ���r`V���NE[�#�P#N٣��l�5b���&紕&#p3�B�.�ʬ	�'���#�5T�[���(T+�luL'$9Ew<�i�O����7K�[�]g�p~L��ֵ�{ٰN!ʂ����e��umgٮ��Th�,�H�����KU%�bhMJC!MSm�����=Go~��k������Tg�à�D��i���ʠ��=}Y!�3b`�(kA݌{W�0)����,`�:���"�V�z�����\A��	�$�M��c�4��*�jD��:�>��K������3ɖB&�����|WW/�:!�4n3z#G��{�թ�/�ؚ[��.�<d�T�P��( ^�i6k0KVl:���ɛ-���Y��?p��	c��p����}��Gi&h�daB���e�Q��1����c��A$�Ԡ|	ta7E^������cVAL̆����������ܴs"�\��Μ�-W����T���|�̑���%�i ��&�
��ZGIр�c�>�`�KJR�!4y�}_4���Q������uU�i����Q�S'�&����h�ez �R0G��1R��!�>b����
��J<R�#M c>��e�^k��E���I����{w��ѡP��(�R���n�P��4�ˎv�ν�nN����+��IM&V��X�H���E�m��d�5�O)Q&!������`�˥�I fj}�_�*��Nd�(MP��9��������|t������.���v0��a�Z�V��u3������ ���!���k?��F6'<A�� �U���oSֶ+�b0vӂ�U��ګ]g�[���?Lfx���9���@@�[쉍�L��ax�@��9�k6X����3�|�J��U��ldd����Q!��j��[�%)^8	�q�@ټ�<��87�uM�`)�W�ٻI6��`e��rpLH�ry6{%�Da��}���	�W��1�q�ė�9#b �t���E���O���@����"�-��{�L����2g�)�V�(5�?r���|�.ǼP�kx.M�}��4D��S��WRv�!���."b3�ͳ��bɲ�TL��dǵʺK֊xH����b��ݣ��'��9����K��W9�$�����;�z&���1M7lC�h3Ǿ��T-���K�$MJq��a���j*Ƿ��T�C,�٣.���b���b��,ƥ���S'�ː��W�g�	��R�7v�(d�+׀�L J�>�'�h{�q�Iàۧ�!e�a�{Cq��߼���x��?%g�j���y|�����������T
V"R1l���ʾ-��~��^��ĉp�b�E�qL��|T�j/���[i+6Y�f�BȨ�::�� k;q���I��&�='Lk_=�!~u����<��i3m�Ur�,��'�&�>��n0���[h� ����U��9)�B^��h��G��qXT>5���ۚ�X���EO���<��d�\M�̔f�p���{�����a`'Yh���=�E�*��<P��D����I�����!��MK�8��cߊ��Q�/�;��w��P� ���-�n�9L:U�`>t ���ƌ+�(B3I�@ϊ[�~��p+ee�/\a4�P���r.�m7E��3m��y�Tɸ���F�#��^��)�h�	�	8�����P��F(U��H��+�V:�ؼ��p��)WG�?��#���^��v�s�[�t9}��ui�����І���;Q3���x����>��ekލ��*E#��rS��B�_�,�0�	��;��"w�3�ep���F�š4�A�ij�.���*Bɇ3¦�]�����5Ac/��T.	�����FP.ע�$�h/7���E�m��]
e��ǽ��^�����j�Hy�J�b*��\���&�4A���U!��/�g��z1f�u{�;Eu8"⡨Gy���
1�-[�6� ��K����5�1�&�:�K���O ɜT�纩��B�^�Z�����t%��*�⳿��P.�{�a]4�b@8�+?E�U�F�%������Cxn&�q�� �$���wO��8�m��Z������%��
N�^��2�)s?�o �h�{#C�
%�$)��P��L�٥�WC3Ad�yZ{�):G.����\+.�^�W+��V`���Q��rY?�)�q��{�b�f��`��]u�:�Qߑ��?�� LL	��E.�=������UC�d&��0l�����Y]�z��*���:�}��[IeCo�9�JУ�
�igS��jH��pt�-d	��ܑ`�v�������<�\�A(�(%�>I�g�ԡ�L��(�'N���ik�R	]���&�C�0�FL%��;ԩ��k|d��7�b�[�üTg��	]�:b�����wuu�?����9:Rrax�ܐq�m��1$�b�BZX?���[�gW�[?Վ�Iؾ�a��Q&��/#:��uTz̚�Y3p��3�1����e��J�����cګB(1�!E�;1NǸ��F3�ْm	cie�w��J��PFZ����.��m�S�UE��+(�����F��H I}����!%?ތ��@��$6x<�&a�N��� �Et�A�P	�Gn(/2���.��A	��&���b�Fȇv:�K�*Q��'m%���@��������}��Sl*�����9�oH�x�f����d\�������)F���q�j� C�E������9��99S/���59�vR"��oj��U�)�0��h�l��q#�[��B�`�Js9�UGk�����8��a/����`W��)�¾�OB��Ixz�%y�v�^um�w��F���������u��C�I��&)?b�!�瀗N*NF�C�G*�b'�?�mq�������/�$�ۯj>����ѭ'�g���p����̴c��aM\���3��H�S{/2,���db�	�����W���w�en��ձT�$߳���[������~@K�m�g~�"�V*yٶY��][�r������Z��Ѭ�t���3���yRzLd_�RL��z���00a�
d�K�6�1��f+%{?�v4;���q܏#a�B{)�J��I��`�p�?����;�	rmw��e����4�з��L������p�}�=wJ�}�ח��������3�򘍄�>�\����￬GuX�j���"��������jKL�l�_��FDL���M����Xb�'���Ji�tF�Gx
#��ys!���M�el�w� �%ؖ�0S֍O}I�O���ZRx�t��e]6D7UXa�����M�)���52i�'�f?�"1�3Wj�u�*��P� Q�0y��=�[`̆��� J�/i�!j@�g+��^6�վ�uKHZl��,��c���{��#2�K�lT����J�9S�`p.��)�v��-���@��������������9=G�c����H	 ϴ��D�W�c��h�f��Yh��������6�0خ������m@��]_����Z�����b�w$[�WgU�>B��B��Ȳ�L���|���%��Ub����q�V{�/,�"�ژRN Ȑm�b�s�D��&��r�%N��9����'m�J�j�k�:�L�y��+sk�o���;c:��S�$�J$�Z� V���_4��#���6I�����Ђ�a��X�@���D���/��,���=C��+
���,\E��.e�4s��I��� ��;�dJ���J���j��x5GS�7�`��p
U��������1����ÓN	}����M� v�p�t�Za��Ծ��X��YP�FD1�rm��b�v�[`zì4����\s���u�����rj:I��I��_��&w�R�z�U����(�<�̜��c�߂R��Z���hQ�2!i3�3A�i�?*^+��cմG5�>�,#��V�÷� ���I��IvOv�G��vK.��
�	�֖�D�[j�9�/�6�R�r�.l�`�E�K��F��%�_K�e`D�7�b�r��D�����A���a3x7X��� ��5F����A�|��&nE_�k��j�$��)�z���h�x�0۫�ʒ�E�+�6�k���.���WT�i��8H�Q�n2@��+?�����|s6Wk�c���,�!|&l����6��M[��g,
Zuoo�^xۤ�e��\���W!�!'�3�<��m$�|6Dc����Fzz��3�����L���	�c߻3�
9���do��йd�~�P	)%e�.�j�!2U�ZW¬�4������*y�1�N�1�>c��;�<�Χw���o�OsW�q�-�s+5 q
גT7��@jPVF	T�
D<M���3*5�ؖÈ����p_g�ٿۆ����6��ϒ����Ġl�H�"�&�E{A���y��q�3� �aT,"y��͑�ֲ#�=�97� �>J��r�Z�@����Zs�4hnHJ(vKC����Cy^!��@��0�,6}4�����ہ�xL�!=��/C��U���r�R)�<Cz��%���j��|<>C�q��_kp��BG���uS�)�C���g�e�sQ���R������fɂ�
N��\�>;��g�����訌w*>���#��g�*�=F!��Ũ��)��)����g�s=�6H	+�J���16E�2�Bbh�
�M.���O�͔�[¡S_���g|ƕ��P�|�݅�ccP׾J//�����J�6�U��(ie{���g�ΖK8����XĨ�G)l�jUł�ڒ��j;H({�c�u 5�c�.���(����%��a�ѫ�����6�++/ �7d,�Q������*~́�q�H�n���>�֭,������ՐF�E�"I��ՠ�{^�L �Gm�{��+3D�ԣ�]�p�e�R/��
xD�'evef�ho4M��j�l��oҙJ=���6mqv��8.ށ���]�Hm�-��R���`�Q����}�2p�3s��[{@PwC
�)�Y�#���,��ǚ#:�m�b�K�V^M�Be� �<��[gڸ0���5,=�X�F�	ԼE���`v��*��Ε����<���:��e�S�'�q�6ܺ^�����:�ᜏY��Ig�]j�(��9�x�gH_�  ˈ��SS1��ŕ���w~j�[�N�Ĩd����8�Д�Dv��8�J8�E^���п �uBZ�,�n�:_'����O?K)�	b�f�����`ke�]3{X.��C�4�\���b[3^�o=Y	H�#9�{N[��j-[��������!{��,���:���2F�f�B�s�Gܜ�~S�'��X4�(��i�!�c��h�N�7����)�@�����`�������{�f�2��_?���쨟 �y�*�KU0Uڵ��$���O�^���L����R��"����6����xЗk�r�l����@Vi����u����_x���5�V0�Q�D�蒒q.��(P�ij�yԒq��?�L�_��#�l�f�;�ۊL8X"��m�_�������C�"m�_#�*�ض���}�0�\��lr:,?ʌfG��Wz5ݢ�N����p�q���2��g���']���w��X�%��^�u(�:�
<��/
ԴK�k���S��"H��ҕ���ǭ���4��XၹD԰ :�ߑ��@c|��T�����wX���>Mt����p���}&�є�4Y������3�>/}�o��	�0к�Sb��R���V�z���Z���G}FB���Y.D��;�م�M�e����x�PH�6�htЂ\N#å��rF�'�-;k�{8�I[_��)�݈V�!����"T�nD{?g�1#�b'���n_��L�Vv�]l��S�>�ϒw�Y i�({O/��ş-*NҐ�$>Խ�ą���T6Tz�4�W�[�x�T���^�BVE^O�G��_�ă !����ʄ���`/I��3�4`���A��n�f lBq�~\!&�!I
6yE�vr=��,�e1�?��I/�4�J�hx��hi�,�˖-�NI���{SI�����'��5��ʀV���ꗠ���}Gw��yr,ʐ�V([BU� �e������D�ۛ:����j�v�H�̎@'��N�dL�2�c�jt��&)� 5��/��UnfL�u���MÆ"�����r[��/[��ŉΘ���1�K�=;˘C~iAt�o��7�����l�e����PKAX��I�v	;^f��\�ԮE�3�/hn������  ��G��ֻ�v�{v�}�)�ʉ��V}]�{�NZ�S}��Cr��8p�s[<�L��q}�iȡ�G�+�q��p�r���~A���iW�y\��p��*���e�!��n�{|�j�¨��<���@�ޓlZ� N�ŧ � �$YcE��xhi�Kgҋ
h_��"�c;_�Y/��f/���Ho�����I���G�r�����\J�;��nr�f���l^���~�͞�_��9{�,��9�^^���}���Z6�C�<���HG��5�I��D*��R��:X���n/]��Gp� !�;	�\W�>�+.��@�h�V[�r=���t/�4=�_�Nh��ȯ8�q����1��)��r�8e�p�b�z�\�F�
C��z���AFY75��A�?�4n$S��}43���+�葿��Q�P8{5�;3X���lT�� ���M��-���~����,銎n���w:�-����i����t�� �mۈB�/ ̝�������g�    YZ