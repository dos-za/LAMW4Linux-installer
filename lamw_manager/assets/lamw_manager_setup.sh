#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3730462219"
MD5="07b6e6a37e308fead057ccf8ca787b76"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23076"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sat Jul 31 17:14:49 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����Y�] �}��1Dd]����P�t�D�`�'�������~fۧ&/��k�H\���X�vF�(C|T\�5�`��_�ؕ9V6��f�_ۀS2����t"��溯";P儱[o�s�D	Ų�����g3�ڿ�e�țK	IfuK*�z<��$ }�a&9Q�`R�=���MK�i#"��ʐ�j����J�Df�r+��7�Bi�0�=���bK�q��,ʺ��*Xճe���G�Z�(�����WW�k�����y^�l"���@�_W�+6Q<�:�0G�8a���	{bӓ��F�����o�>G��LV�|TLS` ����~��w��O��ل�ٰ�bO�l�c!�ưD5��'�2FJ>�ܻJN��Z���H(��������S?��8vB7�V�M���q&
����:�AFQ{어����E#lb6�䱕��2�y���+��%�{��E�*Ό��Buձ��a��TH�:%��X$�ğz+d��d�Ϟ����_����bH�s�HsA��Ʊ���m�ƘD����j@(�!qGi�-@X�xo���	���͚�C�w(q���x��;����T�eЫ/cc�����c~;)S��-���)�佃������#"���qyHX6�6��w���&l�p�G���0��=*��!c�v&��O��R����]`tFE���v��]�a�i�~�|G��1gp���OU+[�q(��U:@�{���f��)%���ѓt�k˔��	��/�/���򽉾{|�8Ϭѵx^����c˓�M�S���g��օc;��v��أ �ͼx.J󮧕3q]���GU�� Wf9�&,2��<�� ��F!A��B�yԦ)�޼ Х��k�O�v��ۍ����F8�T��"�'v\�,��T�U�H�{�ߡBO�F��t3����%ԯ�l2�!F@Fϧ�.�7	fe-I|��ŧ�7�a���)S��LR[�d��)�e�G۷ވy��#i!l.n�LH.UKj7�Sש��T�뇆���<A���A��|R3uL��}�Agեy��_d�G���L���(��ۇ �i��=�M���o�H�H{�����dKĠ����N��%�ɊS�_Z�[g4"=�m�f�*hP9%,b����!ӻ�m~
��>�� �f�\p��g��D���LA�F��Lɻ�4
��T�h�;���f���e�Co5]k�U���7o����yx���c���LUX��k�f���x��#o�{Ϭ�E����0�?̭�����c^ن9��x�C�phf��-��j"u���k�2�?�A�����kk2��q�7A=�C�Z�n땮�L���͊�x�?6z����ɰ#�D�dB16Nd�ǡ!�8E^7�
���L� �;�����<�`���Ic�� y�haa�"�=���,4̰���p
�EDG�L0v�_3
f6)�
)I+��!�A4C%�'i�{ۆFs�Ͼ)�K��9��n�3�DJ�ʢ�VT� �7V�	L�qQ�R5�t���u�K^D�))�b��Rr_vK���	gֱj=b�$$�Y���:�R���&�XS3-3m;��
j�	���ZN�g�-��.�҃��m�UI�B�-��v��+5㯅g����o��B-b<"&<�5(YP���I�Vp�Δ�#4~��#O����TxP�����=!����h�����i��Jzs�Ye� ԗ��s�F�'q�%�?��@�n,�񔴬I^���n!mݾ2Yf�)z`�Wj�l�nһ-���C��P ��w����/cJa�\���7�G��Q��
*&����#��\�M�l�a<�a!Ȑ��7�{t[>A�J�6�%<󬞢�8˵�4���j�a����/c2�\I�#�c�<�KH�&��4�P�#�G�=��@aJn�c02,Ӵl���������A�,���r���%�By��wٓi�w����֜`i;�b:8ǘ�~�t��סu
��М�F���wǾ����]$�/�lU�	�O�G3>.M!B�+�K��ES�n��/�7���L��~9�MJ�,�z�	��5����X�Rn�y������y5塅�b�Z�},{�o�UX��i+��ҷ�1w*����,у���uF$���mFZ8J�G��"�n�qY�L�[���6���7a�r����*�$wD��W����"��`"�)5�K�U��q�| (���1�����_N�l�co�t%R�-�T�2�o[W˶"��N����F.L!�`e�F��,��G5t�Ʒ��
f��N<'���-��n��|54�D�-��`�u�P�w��&}��@{��}�ֶѥ5n
{SGy�Z�A��vWu^���!X
�	�E:���則6i�@(/h{����!�

Hs��׽�ڧg���|ԛ0$Il�i��E_a��8eY}	M`��V�]�H�so��p�R��1\�#��c^Cv��Z���&C�,�g��:�&R���)����D/M�|�K�_b��6̞B%6�
��^`�uY$�_&`�<E1g�6��ۭs�C�"gV�@MS�L-�`���ɣ=�uKA���Gp���y����!����	��u/3D�ί	&�:�l:=�� �b�F�����y3'�qC�{T�Y �ի�U����-�:�W/��q�.M�9�0N��/-�9i���5����r3u̧��u� MU��0�I�hW���vA����zL�_�(����4q�Pȿ��u���)%U�yb�k.�?�#�6]Dx}۴�Y4.$�8�`�;�����m�ׯ�)v�t>��C��If�Ȟ���NMB����o�Ֆ��x�g�/yq��
��$��\ߋ�������J'���l��K����n ^���Ͱ.��ٱ��W�����[s&�d�^�fF���� (�}lĜ%>�RR�'��wea���Y��)�H��Px������.�� ��D����Y��ㄬDS/�����eyP�P�ߔ܄��x�O�@�	�:kJr��x�z6�s�X�WlT`�E�,/ S���wE^yf�,0v\5�<x��v٩��nfbE<2���0��eI��U�/��KYy�QA���a�UxO���)ޗv��#�I떊��>l�i�c��3+:���E�>Q�`�Xi�ш)iǉ?��xx��-�>��Y�>{I�r@j|�a�.��۩��w� �_E�Xl^���&���{��P�>��ml/4�d9w�~uk�8b��X~�Dذ#sGF�[8��E��*�w�>&�� R>�g��s������]1�θ}}�,*��ǖȕ
�;˴2o-oO�d���q�Ij���C³�9e}%�����gpg��\+��4��ڴ(��J)�b}��&@j�e[��Sg��S��n�(ʹ�=��0�ϐHm��l2JxD�ؔOݜz�����U�=Į7���uԫ�+#Yy�a=��s��(o�b�����wp�ܑ�Q�VΆWe<\ 7T��o`ͻ���y�c4����\�;y*����J�Z���R/�`�a�TIe{�E6c�s����QBx�!�qT�k��0�w���f�T�9���D������?�:��iwCm�|`��q�d������)� �ض��|���������= �����J�f����S��le�:�} �����W��/V%��
����k걅@��������,0aؗɥG���43�����E��b����vA���aQ�^͟~!�/i%�<�~�y��8_�걝I������N���#�����s�����Kȫ� �iH�	�F�e� �^£�Yt�ɾ����_�Q�H�Z�R�*P8�gmO�V�2��+�"x4o�^�����$:����b��^+J��V�������B���:��\��C���'%�4�����rJi�� �B�X��2�r����7��!�ps'��KC*E�j�m vY$XfW6��(��Vo\�%�y�+v�hg����z���4���	�:3k���R����`��Ȱ���	��x�(EY=������p�EleVX��g���,��>R��LHj1C�q�5N���1�dF5�Ǹ.�����H�֧�0�U!%�O����`l���#��Z�Ͽt?�iЄB� �J�'U`��E.��vN�]fݔϤ�M�� 
���.6����L��n�͔����h s��GSք��`I�n�v>B�@��[V��4���;�wz�MDX0�l�r{e-{G�[`Rn�a��'B>�W�^R�5B,yc�\��ʲ�J�A���W΢��vR�\��2��gw�u ]�Ǹe��@�=�zu����y�H�(�o'���Ǔ��mbN��sY�x#YN}��][V?�O�@E&!�qU�WB� �������g|�eF�#D�aX{D�
�������
�Gv�3V�� �%�m��|7�4��M+��^�UğH	�&�ۛ��IT�,�ׯ���� �$�h3IH��i�E������'l�2q��t��������P@i7SzA����4��|:{�L�n�j�$(WO���'�dh��&��N.�{��R	E���f�k��l�{7;'*��Ű����BD=FжƐ����Ne�r�0Y�8:+�/�E(�[�R�eF(hCz������>����yHvP{r���:qȥ�zK,����S�i�!���K!ښXV%��f"I�p�(k@���>��{M�ݫg�	�EG��f!��B�1_q�r ,�/�5�)��~tPg�"�L��C�N�Uj��6���[�7��Db+d5� �1���X��K��#@�%{��j�Ɗd{AR���:�#�!���&!:�;�P�]���H�H�Hw|n3?BM��히�o���?��4���Y�z�������,/@7�sG2#�ϕ�h�2``x43\���n|��P�vN���M�),��i
?DwóP�[���y�X1jӬ���i�`߫�/��n�B����;��ȹ� c㛀�����M��E���P5�C�,���ڬ<�ݳxյh�5�����������[In��2���N�������[�b���Ҿ�	�^8˗�ث��ǲ��^��vf�ji${�#���,ՆӃ﹥W�E�2�̬�q:ް���8������O��<��K7Ȏ;?b�]�\0+�g��=��c���egP����ak�}�Ǵ�4��{�����+��OK�V�.پLa_��A9�՝����*��5��*u��
k�X�2B�=��i`XAO�3��W|A��|?h~��Tf�3��k��SV�V�
a� ��!��6�x^R
���������*�j=�,�F����̠��oȺ�����hC�}f�G�ɐ����\��V��`��j���2�'�Ɛ��]`]�2��At�s��A�W'�xc��Pi�����d)��&���Q��ȕv�F��A|?P�LFKŪ*dl�Z@8q�����$�
��H �6�_5{w0l֡�f���N��f�����!�A�r�?2����
s|n(��C��Ft���b��G	��D�Z�u�[Q��_"�U������`!XȮ����se��gVH�U��[��oc���L�t榮�ޗ�N@�e%k�j%�Zb��pL|���\�T����L"��% �u�Ě�H�!�`��w Ҳu��+���9�;�;�vx�vI*����q&�Oq��<_�d0X��Q�( �h�p3 c�$)N��UP��+��GILJ��&�C�v4N7~$�N�1XP�խ������d�����;h|ꬷ���J�kd=�ھhwH7�:�!���ã)��bվ��b[.]^�e]Y�s��?���R�*Y����0e� H���w�lN<$���^A�['y��l�hl؏O3�T�e�@A_8̦�����j&#GF�'梁�%��r����_�.`$T7�.����vliag��H�JsQ5j:�#Gݮ�O��S� $-Vlj�M��w�㕣� ��8
��:k��Wd�Ѹ��<0��PT/De)�- �[e�u�ͬ�5�����\��U����!4����Y%����������`������o�ZωSx�܎s�d  �������d4b���a��&�'��1�>� (f����<�X��j��N�(�e��Q�
@�l����sгy�e�sS~K���Y���On_���0��i?�3�h3Q�s���"⋛���D
\���kC��qPT��a�&7�tװ�9�a� /_���cAa�f���0�-v��(Å�~���qm������s��ɶp#�ĉ�u�]��0��}����P��H�vf�Za]�ZC�h��6�� ���%)0�v��p:�V���n���郚��&X�� ��J\��t!��H�����~�ڈڗhN�_�;��2#�����Sy~Zi�?)o��z�Z�f��sK��S/�����cVW�k{���1��pR&����.H����:-��C���[��"1�W��D��+3UX��|˖��9��qU+ۢ�soP�Dc��*�4�u����u롗`A����ƲRQ�8&�z��2끺7�(Ne���F$�m^�N e{W#��<b��c�)��޽<�(A��S>�L��O?ߤ�L��R1�>K*1E���+�Oc�!�'�sq0>��[)G�PX�%L�4ˁ�u�I��O��]K�i`�f
׵�;AxDz�e0*@	�Vn'��\������@nGM�d��t��:�b9u[#y��T�A����;���:�5 �0���	<u���P�*����jZ_yqOJ�$�B�f�гk�ԟ��1Dҷ�X>�(�J�|�zl�t�.$naZ%��R7�G���ڙ�b��'�e��tWU>0pq��:Ϯ��b% ��e��:p���Ϝ�`�.��#�]��`���:&�Hۏ;�#�B��o<�s�d��|�s�ab5uå�U���jw��<���'�p�:e�x$j#
g�Q�v�5��,	�25���R3͟�,q�Cog�6�V<��)���5�-J��+���+zL�j��[��d��{�o�:��->ۆ7��K�.~Zn~�i���3l�x��a��^��z��)N	��c�9�~�υ*4j��0�O��
�C��إ`.Ƈn�l����:����2^C��r @���C���υ~D<$6ej�W%8��о���v'��q���p *�F�����=_B����H(����N�*��.7/&���������v� �t���*oXy�Y.�<OK��V�-ڬ\�ŧ�U$Fn§?�U��:!��`:
���pR�d!%�-��51z�����n�|�``�MbJ'a��Z�Y�A�PI�j��%S�[����s�a��~]�| ��e�^؎���n T{��iT�q�VU�)n_�4�,��ngY*�Q/�
WAƅ}2^[3
.��b�+N��.1���|s�.�[bn��*���f���G٤K��\lM�`;�r�2~��)�Ws(���H�D�O�s�l�M�?���'���"�Ɂ��x�����5(Ԣ5�UpV����ۂ�al�@�*�놗�PW=�|��?�^����T"lq��i�p}��3�}뜲���98�T�w��{pL�`}��o>}�q����g
� ��b����X����eRZ�yۚpYyU�0ᔅ*'Rzed�$2B>l.~E�)�"D�竃5p�py��G>�7j����=9QJ�t��!�|wLD�u�[�D�H��=E=�Z�+�5�~ �A�>"�Z!��g�0�����k�D�N�B���������nM�����y���9���f��i3Z�f��'}B�9�#>{���59�{��lOUR̳b���=�ޅ�Jd���C� rU�������# �@rgl���z�k8(Z7�o
~>a�\�'��J΅���z����Zt�kc���p��p}�������U;���H�v�m�_ 5M�[���o��ѷq��Ev�젢���9)�	������Z9� �o����r8�̕Ox<�B��yH/r�V&z���"�mF`RXp��,#Ƙa�i1��e�9[��Q��a�N���j]P"V����^����F9G3�k���L�������-��섍����po�`��U�����6�?��&��-�_�|��R��v��z�6�)~i�j�?>ܲ�O%1�LT*b�c�����M���C��=��TS�5J��j}�]�7C�4f\� �ڱZ�F�Q���|�VM{���@~۴X������(ώ�T-EϪhI(���G!1�LIg���J�mw��o��a(�&��Ƅ}���u�4��o
xVA���^	���5ޥ�u�x����q,t���J��JR��}�C��:�#�~�g�+�Vqsۊ�:|��b���T$�4�����s�;�'�`�Ja*��z����t�TB��[��@`�i_ #]�O�1������Nx?���u�J�!4-�׏������	uΠ�.���K�����BWF6��+�o���ɥL�I����f�O^��Ц2�?�Vѻe�5�:S�o�x���]��/�s�v�g�1�|A�M�[�J�^��F�b���m]��?��U/�,>�u����+|<�~' k֞W���8��<���5���k�.�	�D0�S�kZF���p��� ����"=��jS2�w� 3�Q$}�ٕ�zvv�� �+��N1�
�
Fԛ(�x�4��y�+���?OB/��h<uGc+������HH��2���� �U��U?���@�����Ct
/R��M%�!er�Juiq3�p.�g�v^Z
���܎jg�t1���GO�q��u���WLq��m��y�s�_�z�M�H��́>�cB9���<�_��xQZ��Fɑ��4���R��ha�ʣ��ǣ�Q'||~��}�F�m��������WR�gµ �ߙsB���-��]/g����a7�9�cg �p��� �>��ަ+�á75�9F��K�OlW�������q�X��?�ѿ����)�/���p_P��a7س�?�e�L\�궊��b��(�������h#i� �����ei"ڠ�|F3�jb26��v(E������?\��]�3�Rȏ��a��~�Hf���.O?�����ߕHx'?k�+���TF�!m~C�[+��d�LU�{2����e�j�w2^���c��u
�hi�/�]X��.Z�q2����d@Q>b�"``�z�2�K
2�ꭊO��:{�o۪����Oj}�}OS/����,�#j4���Z�PAPdœ��679t9m6	�z�y�Vb�8��ͣ�^�*될�s�m�ʃV��S{�
�}j*X�F��Ά�@����躭�~��N&�G��r�N�
�����\8���+��W��>l��f]í�EL��C�fM����A�Ғ@�$��t�}��}�ϬIu��tf��ߙ�Wt;4�`��ucK\꭭�>έ+ZTu%
�dpC3��q��Z#H�k�6��X��C� �>�q���U��H���N�Ë�(�ծ�vG6$���������4+�Ə�Q�B�[�/�4o�͊�i�,�����V��QY�\z5���2��ߨ�̮Н���~��{;�k#�^���ZU��F�OV8a��%2ݨ�"��=���@k����ը�ʱ[u=�a��f��esO~���i%���y����l�q��Mz?~�a��Q#|iK��#�5����Yy����0����3;R��n6�\/M��Տ�9����5����pX�p�nT in�KQ�3�ai�}����b���3��X{��)<u�^��\0Q#oL�嚓0��Μ��Vo�!G^�${ XR�9��7�V��cd�?��jG�1{�8VZ�X5�I��ڡoNuy��7���� ��4)Y7���k�n�����p6+)�� �ˠ��װ�������/7��I'�,~Z��w�����;�T��Y�*���A�֓S�≾�z�uԨ�߷vB���ދ�N`٣��"�o�a��0Ѵ_���"��,��[��K��B��o�q��s��������a��k��tID�N�2��#����yP�sJ5�LP<��X�,*c�,��+GLu�UE�qm��
P��(����"��y�i�&	]�R����W����FD�w�G/CE�n��J��R�
_�2U�(X�|N<��#8v)_�&��%�w�	~�@�2�Fߢ��t�R2Q�a�,�7\����uF�_Pp��R���n�J{���WK��Id=�@N��םʇ;`�$��YEIk[����0�g����d*
����@̎��H�
�O`����nJ����$`LLI�<-�� �-��N�iiQ��� �w��Z�<t���/3��= n:�����B��z� uϚP��+&I�����˼�{5P�H1ir3O��wz�,�aF:�*�j��Ȅc�����8�E�HV�oW[\�ȝJee�w���^��g�i���3���`D��_q���,Ua_O�a����^uB/-�.���)���
�+�:4��r�U0ٵ�u]?&��݄��˃E���b��� 
9R{���}Ʊf�'紾���
;��󤴤^b��ִ�Tijs>�&V`�9�M��(Q;�t��&���O�ac�:�	Eֻz��$��o��Գwf��i�AP�7ҟb� ;#��_)̼GoFz9d8�1D���E�6�)����8h"�/�~ϟJ�r �&���+�k4�,��8�@�K�<��L	B8�ߥ���=�<L2�5��aM��h��	�-얎J�q�&C��F�$���׻H���9�`�Y��p{���ԃf8�ĳ��5��[ü��^(��=�x�{8Kv�,U�YQi�0~@���󦊔
�Bek8L0��=���x0���̺U�^����NdX��y=� #�Z�:�� o\��u�ޕ�tY�B-�j�O���x�a���&9��Z�*��.��L�3�;~Eנ��c��Eր�1���[^�>��lfX�kڸ�	b���K��ٞ.�4�u��� �����,��O��~���w��8}����RJ�!�5m�g��Ӄvۏ��|�B�W�9���-����h�i�lV�A<7�p��	��t�>����ts`p�����p�!��I]�	l乷Z��^Pu%�3J2lH��F:�<g��[�K}�+k�r>Ye��_@0�ơ4��J��O��+bsL��e]?��?�XJM�KN��r@���ңt��/`�;\���/����﮷�R�JS[�
�CzM�Y)��A��yk�S$h�$~_�6��$�\��*f5��¼�u�2s�V�r��pA�[���zI�����QH���k:9�"����M*1��������.���W��~�3�A�<��4�@��Zm��|�i�h�9/r�6���T���b�?��!�q6OKw4���T�kD��S�eH��Zf \zqv�Rmo�n�b`�i�{$?I׉]���Ҟ.��'�{ʜ��º�� 8*,�&q�J׽��ǲIBgg���@\�+4�7Vnz*n�~�9��r��DiF@V�R��2{X�2�ؚh2�g��?��s�ѽzr�}(���J.\���\�#�;�,;��ؔ�x�5+�C4��9��X�������ۅ0�r� n����U���Вy��U���� ���ot����)\�UN�i�<�ڤ�3����G��Ti�_yػ�$�ã
��2`�5�,��� ��ۤ�"6:m}�Z^op��v�׮{�{pwߝxbE�:�a���S]�U��n�l�z�����-ua�g�w#UG1E!�Ԁo������l���	�=�������v������飏ê�:��i瀃����9��kk9�U+�W����h���H6+�Թ�Vń��ͣA5���� ����9��d�9�Y�)�5�\�Ҟ.8�>~������D����l���f�p�������O�^�ؗ��=#�*�^�(2��[�5���Z�
S$����v��]_&b+̳UOT�l�	����a��U���+vG��4q�E�4�M���r0�%�����oE/�6��M�m�Bii�x�U�Iu{�/,[�$&�g��^��\�bX��3Ɣ*j�ld��l��w*i�ۊ���J�]ԷO����=�_�N'NB����[�2��f��)��S��*)�����5��b.u�VD�$��(q��VT�r{䑲�9�Cߒ�]la����|@o�V������#� 2(W���ȊA�A�\x���1�j������dˣϤK|�s����5�*S�dB��̖L��u�׽"�)�-��#n.��h_he���+e� ����B��. {�6���u�lNS\��$=�J���f`ۦ�1w���E�_ T��O�X�6�h �b2gz�K�Ձ�`֦����y#����l���umƂ�|(�V��Wh����惬Cm�@�g8y����%�GD�BȪ�0̈�}�+`��d0�!�*>��<��F�"NzK^�.�)}|_�Vuow<��^���I���հ`���8�,J�<3̢ާq�n��RH���^"���M�b&�$��{$�k�C��#u�9U��0�I�I��4m��ik?���+�J�#�@���.[��|N��ad)����It�Y�������-�:Zp�M�EQ0�(Cv�bh&&��df����]R���@�[���T�uGˣ����a!���i*��tC��q�f�! M�g�����ǴY�v�P�^�Η�+�̈́Do�����&x�Ϭ�̶�E���ըB��P�_,��%�t.i�{��T"�e�V-���;���xn���@��+���D.��l?]'a:b����c�mõ��$xl�N���xx���Q`��
��y����|SV�Xg�MR2�Q��`L{&�������~�(T��؎�(޻]��߿�$9��(���/@7:�E/�LP�&_���9����O��;��ΐp�Xv+Èˍ��F$����o8�B���%�ޔ�%����^����s�K�����FIl��/>�C�ێG	)~��� �}�	|u{�!�[���-�x<(��N�_���O\� �P��\:�4q�_�����eW�������V��q~t��9I;�ł�աzaNN7��5&���z�M{���v���	��=4�-�d��wvH�㮑r�*#���8��↰�I���dD���3s��1��4�N��u_@����R��)c�Ac�[Z�
��i,� �S��?�T���is���y�G�2��4 �m��7ɥ��v=4~w{���\u��g��{�/u��$��7�q��������o$w����:���`���``3� [�N�Օ��4�Ɗ��11J�����W�'@� �N#y�f���$���Ъ�� �?wK?zC���֥��[Z���++ē�7�2o#�4�5�A�F�ޘ�E5�� ���)��uK����C�����R���TN����ἁz����!�j�3��e�s
����{`*�ؾ� ����ȁ�~����FT�7-�?���P��r��L E�5��k�6AT{����8�9%�{@_M��S���-��ٛ�)�k�S�.&|����O�v�ɟ�gAJ�w�l�;�4�D��,X?�� mwX}B}��kQ̤EKVOc\�K�'܌3�e��]��˯r��Qk���6 ��m�<�*��\�]7}�l;*l�v-�� �of7��Xi�Kh�8(��Na��a��*,��������]���I���抧'��ek}��Ԡ4&�D�h�vn,W�c�$�y�%�<24�c���ն�_������v��\7:TBݼ�y]�B�l�K��8�u�۱m�6Wx,���J*��]��R��M��V��	|0�O<�t�-s� ����qd+���9���͑SG �]?�s>�Ъ���l��R���b��OE�K'lьO\Fú�k��gC��\��WBR�Ʌ�oΑ@nX5<�)ijk�r� ʤB!8A&h����E�B��`����w*�Ů06>Q�1�4���r��Z���cƼ*��e�Y����s��.��mp#��W�!4/q�:�9bL����1�7n-k�4B
f	`�]+���Dcju��p���x)?o�`#���V]3����}��|����Y�nZ��nȻ6�l �0��ud:�c8�ǁ�B��\*%�ŵ���=0��$s��6���,L�m�!&���u�����/@|����,�
X�_�@7���M`ν�;5"�b�g7/�NI�k����H�u�߲�{���>ݷ�nmǿ���J%P��C��uɐ}�b�����[t�e��aX FW��`�C՟�U_�z :��o�rBPY�=������&W�L7;n[������a���	B�n���]u:�'k.qa��^��1�w[�EO��F����>ȴ���p�����0j�Uk������5u��vJ 7k_������
R��h��aHԥ�O7��� .�O�I�Jyb��b� u�D'�	H�����w&"�����ӊ=�/`�<��|��LyY��P�9������[�O`oDx����vk�៼�H��t��:,�ɐ�,Za<�y���f��+�V�d�{���r��cT�b�X�X��Q`3!OD4|���P_���Z��΄Ij�)ۧD��:��f�Iy��.��:]#�(�?SK�Xܺ��<������m��t�6W�-5`;�rS%u�Y-���Ji�n�pAИ��г�mKͷ<�i0������F҃4��29h	�׏���z�\���8�N��%��j�fL��M[��f|�"{V�_�P�L��������^�\��4%^AQ=	�ÒT+��y�+�g�f���=p]�sm�ȱ�2�c8n����U#�&������c+�_^��\j(�t�|��T��;�Z�n���I���W�<�[U�*�yU9\$F�"~\�r�O�dwem4��έ7�=���~�3W��p�cD���_�5#
�ɓ����Z{b��8.��\]�V��-H",^��y-Ydb"���Ť�$��n�8�z��l-Ej[&6k�u�:z<'�)�~���i�u��u�J%�/���<UYw<5�2�-�6�P@����-F�BX�eP�x�������L9�b��uSCk^q7��.h�ɣ�X�!���E�p���tN�iƼ,�mdY�X�J��"�6���9Ӳ�Co���B�ǟyĠs����$��ϳ<�	����>�yz�g��!p^�η�F�����"'�ؘI� ��.ej��@h�
���.�C����kl��f}q!־��� �Y/O�7e(�Dd�l��eʬ᎜S��=���^����َy��ռD��Җ�������|R;0y�	aUߗz.�ln�2B�i�5;'��Y�E#ܢX@-$ũ_�Ќ�Dy)�K�23���)L�eO�'+]ܝ͸o�h�����8���Q��/7%��^fhٱ�){پ���F9J7��`�|�X�E[�.��=>��pG�.Kk��u�۶�x��%w"�xq�ƻ͡M����0��~ � 0So��p#�`�`�م�E��f����[�v���iK p8�u������nm"5���n�qe�����o�����l{� պ�0F衊���G��°<;�A/���ni�"�"�	.CG<V��n���A���4�������1ͬ�Q\��N�]��D��/ҌP�G0��wS:���+�	�+�.�����h�z�g��>;����+Ic|�jZw�͌Y�2�I�k
�ag�M�Z�h�R[�->�d���+&cތ'��<��q�.=��| n�9�}������{����Ia��|G�+���vA�o�kkR+)��
��U�Jw@'y?�Q%�����7�F�=mu�Ç��+x�C3�g[eT�w��;r)�A��`�)	:8A���.��h��:�Ug����?(`�����h�'E��>�_��l.�B�����~��ꌲ:9V	7�q<
S^�o��L܂���΂_.ûq%��U*���`r��Z����~5#�d�~"x7��Zh���<�*��=Ҝ�a_k��"a">�v�'G$٧�����Q�@��(�3���i��R�� �ō���?84�/�U��qQ����,�d��`�:�G�6۱�{�� ����'c��:�O���o7��4�G-I,S��P\E5͈��FU;����v�4@�%ɬ�}emk��w3"��O�-k����ax`��vlFNg(�sx� �p�|!��b?p�{/�|1؁�t�C�?���4�R��W���+�?~~��� $f�U:WA�:*"L�s���̬��a��Ԭ|#.a1O�a��+Ն7���U�nCؑ����7F�h]������wP���G%֪���;m�6��m4��ןx��,���xLD�a����� W壃�ռO�ك�lQ.A�dW��X"���#3u]5�+�VT�	؊�zǼ\�F����G	a����M�/I�.h}�������KH�!���Jv��TҨB��D�/�d[q���a�eY�)jUI�Z�G��ʲ�B��ㇷ�����0���2Μ����1��z<���ж�;��/\����z�jݻ���+�����/�%OUU|v!ɦ�}�6lxK�4aύ񫄞���=Z௻5�s,�'(�}�5�D4��¥���v�G��C�=#���V�O���R�\vO$�����^,�\�*
�!p�����������h� �vv�Bb_��6ߏ��y>���Γd�#�xp�WtQ���`�y�T�c�Uۏ��[	����Q_��{��4������m��,9�7���ɜ�R�a��q6�$x���ɕqAo�u��q���π�2d��l�N'����g;Ua�T7��=@4m����.��[N��\z>� |�đ���>F��� ��K���������B�@��JcSyL�8м}ZAx�-���DR�\rl���QKiG�(���W��{6���F���c�Ř;Wq>�q&�@G4�ұw�D��"	��7]Z�s�Zƥ:�h���\�hcQ��9!����ń��� ��wIK4a��\!�����S��Q3�Dt!X�?V+����2
�{�dw5g��{&f��A����͂���M܊�B���Ċ'�(�⺓��-��^���5�*��$4IljP!��._�!G�k�U��/6E�wM����W<[\R����������Sy�2o,���'|zIB %�/�=f̦���lV岷��b��O�2���Ci���H�0������3�'nu���+�n_s���b)A�=wxӤŏ�&�F�M׭��oP6�u�|\�T���ʾ�<�&
(h�wU�npg�O
�n|�&I�1)Y�פ�\���
&ZH���|���*	�*,�	Y<Q�xI{�����j��P
�Y��+e&U
FUʺ�;]�u��+��f��e��)Ϥ���U����ڣ���Ժ4U6������$0[:� ����N\s��V֌TGl.]U��+'���6���#�J�_�	�6�@��ۜ^L}&mZ9�		���w�R&<7�sKN_d����|RRb�,�hvf�&�䄯�\_�PP^�/�N�nhw^3�,1o�L���u� �?�y���qɒS�?*;r�����v���S�D�z�l�^LL�ڔ����t؍FYL�*�A�k&H�Ft �G��N��Vb��� ϲa�,���g.�s��$���3��a�(���G=�R�ñ�ڨ�(�}�Q}!�!AT��NnM9g�S�)ږr�F��Û�2��k;���˅�&Ft�A�S��=x��)~g������*�����m��M�$�
�ITN��$G;��}jr�8�h�/�t�d|���[��b��mGL�gx�Y�2�\���I�g=0�D8��ꥹ��8N�0q���1�-��$��H7�t����.f�����ki0�1A$�G�6#zH��{��[�����>��ON�|����E���7Sx� hʍF`�!�4���z-����)F�uo�L���k�f���W-$����t0���.>ܲ�me��ʥ��0�&Eg�/�XR�dwʺ������RkI	��a��EW��(���-]B�dʕ��F�G���f�y��`c��n.6{!q�ӏ�ɒ3,��M����36 Vx��(�`�_/�!e�D�CQpS��z\Z<��mU?eW�<�9��T9,�	�eG��?�x#�$�5�hEw�D��碐U�}ͻ���ݡ��}r��ǃ���)Um�eBr�l�{h�h��\uP�i�� � X���q��Q0=l2��E1� �ڴ�����^�2n�,�r�i=qɺ���amM>k� �c�I5������P6��e;�C���fA~����n�J`���F��
(�	c��7�n�Q��3��oZ���2� �7%�QT�aG�Q9�Q�k@b쒬 v��������9]�#����dڠ]�,Na�{���7�$���Tۈ�+��uZ2�<�R��ω涁&>�b�p�V�^m1��=���Em��V�m1�-�ƃ;�-������N=�Ӏ}^87f�u�+Z��Q��F��u&�Ī�6��.U �M�A�c�d�B��+1�NGDUW}�%��J�@��!@�ԣ��o�N������\���<�U^H�v��Qwط��bu��_�,,G�M�ߍ�_��>w�������n�k��;X�4X$P��
�FLhWqݪc�&�g�'!�d�UW	,�8�5�p��YS�fY/K�U������}�>u��L����0�Z�ͨ�9�-uj�ԨS��x���?v���8��%U��!�OH82]����RGd��Ǹiʃ�Q�4@��XYB�F$L$�e�)JE��i��b{ރ��A_�G��H���u�F���G=��$jޠ���1J����<uA22��-'�ɑ\����,���
,fIѬ����w�J���pD�}��$=�/�����z�Oc4s���4�lf�='�����j�mg͘���i@!r�er��9�%���;��Om&Du[�n��]Ή֎5;���r�c4)���ܗT�k�:������(p�R/��/�K�l��[�4�fl������[���I��Yb��w��O1���F�G�ӈG��dE�ѭ����ypO�l_����B�e�����V"�I�W��=�~o��~�3^�R�I!����}?	˗�%oJ�1�uRۤ)�dp]��m�)Ҹ���B�~�MPq�R0�g�u�	i�swn���Q����qQ�KM������0�\[�[T��d2���X����Ś� �.T���n	{JS2h����}��Uy��ތ�i��6�(��.?����ǳ�N�L�$�|�&W�8��Y�0w��ƫ//*V78�i���b��4FBQ��2�N0�d>�	iy���a�[���r�p��VZ6$���	�'�W�l�"����_tL�@z��pe��?{Kǋ��0X��u�!����d�)N
�!P�W�>���H������ǚ��޵!h�N治y�h��T��^~�B�0 �S��[l����q�w�|��'|bk_�a;����,6*���~�2�JN�w����� �M4��{��.4OV?wR=�O�V ��Q�ar��_�W!PsH�($��,]��`�nՁ�웞���^O7�4����{)�34�
֋��K}�o^��}�g���f��YVt�s�!�{%��3�L��S�%
�ddD~(އP�0���:F	�S�J6aD��� ���R~�ks��Տ��V9�&jo3R ��P��`�;(hTnN��99�Mb���U$#�@��t��6����c�	h6�7%�K��(����ĢYO����m��3�Q}:b0�y�v:pQ�N���X��4`������c��	��v]�\ߗ-���x ��ޡI����e�d�YN�*rnj����5�p�����HF9!:����+!�x&x*Y�P'b��.�o5�$�*ژ$�3�iA�ߍ\ �0e�͞	��&]fKd�i9r�6���Ysw�)�����r�]��2?�Wt2����s���H}H�����YҹҎ�?��"k��3�c��3;gB���lc��rG����y���7��KEv¦$C����0�Ґ����N��@;[%fQ�S�����\���x2��Ҿi$�i���Ѯ��oM�E����%�P%ї�E�"�-j:`^<� �(��@B��
K$����(D�t?�oZ=]����P�L6@k<@�p�]$����3�;NU�#._������)��}��;w��ˋ!Wr�Ir,O���	�*e$���bH�R�LL�B�� |�L�[��{>-ʢ�#��+h/+K���;Z�ƺ�c��8@C��4��6*"&ke7��O��$�[u�G�V����h����Ѯ��O��h�ϋ�����B[��Cx~X.���Â�W#�L���#�[wL��<�2�~Rg��i�M� gQ���n�v�^����gS^�2�L���6���E�������3X��������U���E52��r�r�y����H�� 4����ƿ�c�� ��)}�����GNOw"*^��^N./��G�@��^��\+x�U��
��_o�(Mo�ޥ��O�Tx�`���}�3�+���I9��NēIP��X����fxw�M����ٶ��`e�t~�2UA �yp�Wv�3#���i.�^��QF����*��x3<T��7Qj���3�\��[G����H.��F��Jrk��%����{���z�GP� �SR� ̹K�s�k��&=9vs ����\Ʉ���Ȇf]:�OEu��/2��#<-�:Oz������<1�G�5�o����%yT;��r����
T,x�}g�����A�D�7�5��8͹��&˩�(k�������%�)&P�i)��̮�5�X�T��z��!�P�ʊ��'_z�E�HS�zW���l�:�����������Q;�^�C{!����F��9=��]ep����Rk��R�|5fb"J�;Z�!m��Aj�O��G$6�`�m;c\�X����|���\����O&�Hݕ��z +�=gR���쑅�p��1������N�*��̴h���%QTrG��9*o����RjZ��sZ���1���6]����tx������*�2}�ܸ!����ߋO}S�Y8V`H���?����x�F����[������I\)�iQ�cC�`�hL�CD"�󘷯o�m_����(=__6МY��Ҙ�0;�Y4��q�@����:�ړ�L�.k:o�Q��$�6X������&Q!3�(R3��X�C��L��8��܅ ��j���MS�eӀDL3ѩ�oQއ�9�̧�SIדO4�LBk�M��� �2�aMdT=��+o=R!��N��3]G�`�b�$��뺢�5��Q=�!Pl�Dex7�U=���2�N����)�B�7=�^aO��[�� ��I4j=c�q7�. }��<!%�`�'@Q�8���[z��q��2��4wU3U�
�5��F�)��H��m�.q�t�<���vf*�G�����:�,9��ʆj�2g�14�xƉ;�f���۴���)<#nÔ7X�럠��6̟��h�!7T_<WZw)�5~��E�vH�_����M��ԼE���Z�|sV�0�4R��j�^�A���)Gv$���#�c�^2���l�U)��	B����_���~�@B��V������#�h5���JdB���R=;�h��-�ϙ��*�z���!H:%f`]?z�����0�F`�B���.p�FD%o-=n:�����?K�;�.�;�}�K�A-.�ĺ�7M���:�ʭT�Q�ֽ<�>��n���+;`6�����_���[����Bɉ�D��D���ꢊ'8�#EEW�}�Ø���� �Ҍ�^��Br8�9��H�K���'�t3f��5�c<-���M>259��8�X4��Ŗ�T�
��UN��%>�x�o�G飻MVQ��n���
x˛��" �pdHG�hs��OI���p�p��٤���/�q���f�\��
&U�:����9j"u���t�<��0��5L��L4?ヽ������+{�<B'���U�E�����J�����m�'���3�p��!|��"��\���?��+��U٤���
����<%�T/=ȉ��8�� ��	zx�j��>N6<�����cx�.�|��L):Է�	n�bUPj�(�پ2���C�S���N�#�&K��oH����q�/�;��5���o�b��ޢn�;bے�\�^��I�(����H?�K\y�Z.�I���AЁu�}�Y��SB{�f�T���9'���~g��t�6�k���׆5oYs������AT��Nf=Y��IQ/�UN^�T,y��8O����Z��3=Z4�q��9�l ��#x��Vm5�yT9����(y˕pz��(.W�m��7`��8[�-6&c�W T}�}Ù����Na�1�.���
��ǲ����RϨ���2����ϟ��S����
G��k�%P��HV�    ��?^l ����xཷ��g�    YZ