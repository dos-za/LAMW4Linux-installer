#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2078553016"
MD5="a5f5ea73954740cee1f0012415c8f286"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23440"
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
	echo Date of packaging: Wed Jul 28 02:12:11 -03 2021
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
�7zXZ  �ִF !   �X����[O] �}��1Dd]����P�t�D�o_�, ƣ��#��4�A�`+�6��!^l���|�0,��#혌���H�I��OC��k���;���.a�Tk�h�M�u���0����{�>�
\ϰ-�z	�4�k[(�ˠ�Ѭ�F�*'7%0z��R�ڹ�C�⡠�ڂAG�Sb��]u���C��UJZ����.��p���	�z`��9G�
�Eԧ�҅����m�#I�e��2�@�|�P����IJ�ZԽ��-�_{8}��`s�^J�	��63#F5O2���~�Q�z~:�uMou�~W�8�![5��])A2�>_�3���m����qi�%��/��{�:�- �>�"�.��!qhSty���v&�A���|o$��`svBiR�l�k�,6Y��T?�B	�]ݱ���+ψ6�@|Ƣ���J%��2��2q����6�ט]#0�<`$�:jհ��db'׋b�>��>���e�\uf,[�[���O���P�RIH����ќ$e�QLqn�i��^V!g��_��7�Z��7 e�2,��������_s��,;�h��%���GY�>�m>L�җ��:����0!6l���!I��� �k\F�K�c�V���� #�}�҈J�E��������}��0|�[d
�^;�MB�g�����\���qb��he&W�~�&�A��e��k:��;lO�z�\,T%�!(���:�Ɓ�p�͖������Fԅ�[�����	���Y����_=����#'ʽ��O4��N�Q8X���Q�eM��ľ�pi���zl�m4G)F�GF�&�T�X���L��$��-�_�Gï-�r1͸⒟7�C?��'��Q3ӗ�jf�S�}(U.�͜���1�;iD��F�yj!WHq�=)(����0n���W��{YC�����?�(�C�wK�tR��ɖ��W>�zA;�Ge�cq���t���x8���ҟ��Ӱ���K��;�!�&C/���p]��8�w���ʂE1F����V(T������԰����c_C�a�y�˞���~��@���I���ؚ���`�$� �-�����
�=�]�A~3*V,�A���������;P�f/��<�ZY�L-J;�bH���]���k��hK�.Wċ��L-C�x�C�7�h;cB#dno6cI���Y�sl�tH5r��Ś��g�h��;��G�0�6����H=1k�u_�pP&v�B~_V4b<�"ε )&1�t?:/��N�}OPE	���q�sar<��2
$���T��Æ���XF .�r�Y��l(CqT	,��m�D�$Xi����b��"_j��Ұ��B��ߗU��8�����֔W�͖ �^x�ڮ���2'�o�S�Gze褰��ª�e���N8�Us5���yj�c��C�]��NɴF�}�V1�Js�Um�J]KRƖPNkK���cM���� <3���ݛu1��q��7�����J���8��%�5��S��[�n�^�[e+�ץ���5�����l췾B��h��=6��cY�����ns!�󄵯Ӏ53`I���?��N��f߶R��Ym�T��s�P��,|���}�Q^��F�ev3+�֩�߰��)Jm[�n�$�&P�Dk�����Zm_��d_��*#�#5��)�E����U��	3�z�>w�5$�BYd��p����h�)*ѹ��,nV����j�QFJ8'��q���,�����|p�7��p^��L6�M�B�>z될:�p2��dk���,��@�N��0��F�! ��t~�����A��$�&��O��B���꛸t#Y�_vR���������m�v�̈�Sm��u_��V	�����ӆ���T�i��<��'B"�R�6�O�=K���J�ԟ貭�H}F �2;�͹�rg�"/�j�/&]�)�[�"�d��usn�E�1����,�@�HC̡s.ҭ���q&��Mz����g��lj"��k�_�J�����=�A���y������)��~���1�� ����ș>M�Q��{�1�'�'��#] �*�uM��{E��l���Q�D[����l�}'�b�Ž%٫��ʂj��=-������[D���FH�ϧ�㔿�%D�oD@[l9Lѻ=����f?|X�8֮���Am2?fN�PZ�(��A�����DiI���'�&�#����{wٺ#��4Ѵat^7^�E��M�5���M�\͙*G��i
*t8���Z?u��^� �ަݥK$���* 3D@/���M	��NW��H��Z)����������j�h���]-gu{����[8�*<q��A�;���{36��5 $)r�I���[͕S�x�$ޖ�<�!�� li�<#-��O�S[;}�1A�}@����r���<�;�q�U~��sZ��Ϭ �#K!f�wd3ս�>߀�z&��~͂v�$�v$\��Iͱ%��[��v������nF}���� ��i0W��t&4�\܆}�&H�=�]�P�E�u4��5�_f69��2i~pytb��m9��G��I������D����*��un�~��}YO��JA��߇�O����H()q�;��]|�҂ʁ��C�f�w1�VSZ8��rs�l}u0LX͈�@��>�:�x#p7�doti�x@U��Fm
�V�U�f'��M��P)�ȅ�!?�x
��{Q������`������C�ac�D� ~i���C�fi�����+���o4�� ���!�L���!���W$S}d.^��^��ظU@[��\��0�������co�Y�A�j����g�W��eF�G���Ea�c���۴ް�/y���SD���CfD#-��dz�c\;��¾# q.�����P�4�qߠT��*���a�D`��N����ͣ�q���+�V�W�+���څ�=�C���l$�nj̙K�������12��j��D�.r�εU�%���,9��l�y�x&[�x'`=���`��Zڅ0-�d�NQ�/����Szď�wv\0x�	���q�������H�C�cΠ ��tmm�S��� ?ҿ�?��і�z �K2r(>��>�!�n��#Z^|�e�6�_��P�T��t��X!�^\\0r[����Y�V�	V\C�|�ZN�b�o��q�g���*���~PRbR�zp��cJ���R�C"���[i�㞛�-]Nx�H�!N�E��Ѻ�`���dT�җ�5�2_6َ�\qch��n�� N���DN�y! E���YǠ�dC�� �8q*/�߫۶2��@��E2ƤXKYQ褫T���\Uф�8��ܷ�z��aT0&���9^����G��$��} ����]������7���Ĺ�w�\��<��ǔ+����Po�y�6�/�V��Ma����B
vC�٠��NİB�u��Ꞥ�XS'Oˏ�����J���WD��3ҧJ	r@a��Iy�$ sy_5�Go�Ekt�;��P'�/���ہ����O���)i�Ȕ��ڔ�2C���VN��@��?��*hRy6��������s,��Q*���<��-`��dH���p��ڡ����3QY��v����<���{���x�ɵ��g�Hԭ-�޿i��H�L��ػØ2ܓ�zS��f��X��,m���E��P�����t3�ԗmeI�pe��dN���m��FpB�k0χX����<�,�o���ڹ�.c�|w��u3|c� r��u��U`��Q�G��6�[1Ҁ��$9�x5K�Ӝ�ҧ,�jл������%8� �m��\2.�R�$G�
��Ε�2�ٽ2����H(�'$�� �>�y��/[�����6�3�L��%�I����>�/���t�4��:X�a�l쌟(Ir�O�y�88h{V9Vi�_�J��ו���o�䢪�L=�f4�)dAC������A�Nj	h�Q��'y3|KŃ����XQ��Aӹ"�S���p�2|�K�A6����%/�a�*�s�:�*.8��ov9�Q�PR:�Ωem^3<�ǆ����Ѥ�6��A�;�L�뙥���)h(q�k���>��`��U>����r
�Ԯ����/��E�`�~�U��Oje��[Iu��͛.�P�vą;� ���������BL4^��R^͹o�G�Fg �O=P�|$�s�*N3R���(�k�����ظQY'4�Rf; 
91���L�ܒ�l��j9-���!�H���N�9�����7[�M��L���5>���Zjx$�T#S1S�D��p�����W����)ANZ6�D&���8���co]}W�]7׊��@����OY�4-Z?���c�?���I\��A��2���vQLj+k����f��2;b���*T�+m�}�ۻ�ś���;T�֟nhł�5O���ŧ���]~{�]C��J�aI�h��H')i�qh,&�!2+
�Ct�r$>�~���_�F�&Z
ܖ�-�}%���Kę�Ca)D�rI.�I"�N@٤c�<K�Y��hv!��^l�Bj�,������<I*ʷ�1�:�j���-R��yow�1�E�%�s@�&c�tf�޹rt�2zm[��;�S��{��`d�0>�ǟaU�dK�<��������V9}���B��T_�>T[��pP��v[YvoE�We��F��9������U�=у-�^N|0K)h�w�?�^X+b���P�W���w�4TX�.~Q�8��ϫ�i�7����O>O`H��1��7��Uej���6�V�P^�OW��<�
N��jwӋ6���~$ dDj}��UB��@]E�J��0uؙ<��6"�wjgh���ČOk����p���I1'�.�~�v4��0'�� cv�t� �,���#z^���-�\��݌ɳeBI�0xu���ѣ�|�am7ݚ	ۢ���A9���"��!?���םl����R�=]T��=g�?u�pˑS��@t���{�y��O��-����m	�X�O����r�v��Oak��R�L��?C���C[;�T�*�jP.zKr��L*�
��e8�����3����*��������%�ld�ɧe�B��F�J'<���D�ѸAO�W.����[�I����Ē�ZF~��\#6�Ocw�Re�#Z����ڠ��Q��d� *�g ���	P��.�dNm�'�槁%�R�,��VvKjg��T/e��oK�j�ܠD�0r�2�@�nEr�CX��7�:����G�U.��J���r�v��M��< b���X\s^�<]nQ��'jw�5���X0�6B�F>�8��o��>��:13�nިg��Nm�m�7\iX���P,���gȍ]����,�f�������b�9C��{O�^~�텺���}$3=Q!�2���D$��u�暽*�g郭�b��n��؈-J���,��)��\=�	�"�<�����{���y�_EC��Xk�;�E ���l[O�G�O)�ԋ�K�W��gA�HKf��m�?\�b�W�P��Yor)n�K�t��!�ߠw(e�:����w��ͨ��W3�kd��,⬂$n6cmEd:5Ay>��W@|����S����Q��d҈���6*���nR��;$u�����u�'��:�0R�|
�o�\Dh���~v����^�aQ���i����n1B�^&�RͼcB{(�^�>Z�5+�@�����ɢi��Cth@�/f�Юd�[�^/�7�ÅҌ�o��6��U�
5�S�so�0D�+&���.'�"�J$Jt�<�����762l�1�Q�s���H79K&R�B9������!	ֹP!��a���M�5U~~�B�����s@ŎVm�q0���_īik�F�Q8�-��)�"ҭ�Y;�+X��:.өIzMU���`#M?�u4��~�N..����]���7�K�	&��C6>��GNa.8kÊ�bb;I�*Kx���<��1#���'�^�8h7�z�b<�|Q]00(��� ������ Mr�JTGa'������ӂ}�6��	�b�Rhg��GU	b�Z�.�Y��M4�9X���^�;��Y�D�j��ȑǷ�����,�Y9����xϩ��ً��ش����K�z��rQ[ye��t���,S��\^L����*��;�|�צbL?��͂�˖N)"���c
�
�8��: �����2�? �v�9���j�e�ӜE��m`$�N���Z�i�g�uU�9�踦yϙ����*/w/�۷ڛQ�0^w��f���0x�G���{/_�];9t_��6�j���)i#������Cõ���� ԣu<�e�q9=��c�U���xEZӋ`���,��iW���~��f!;�����l�����fӺ�iۏѦ��60��r��CE��׵�W�3!��-�*�!�OP��-6�^�SK��X�F{�ֹ��$��� �-X@Fu�6�x�`��'HM��M��uF��/�{N,�잮�� ������?�w��'$S��@W��㷚�ڼ�h�6;"˓}|�}fzf\+������M~�nq�W�IA:���x+CH���G�-���o��疮�j����>�I��n*T���(q�5�=� LYx�����,ϭP����xPK��,�,�����m�}b�B����+u_%��6�������>�P<Ճ;6i��=����Ij��_�9C�:oӆ:p��o��f��dq�����$��K�Q�=D3��%���1e�]3%�2NZ�>�z�w_��n~��O��K�I��u��f �KɊ�B�7&a��b���c�G��m�����&+ԏZ�d���L�
�.���E�^r4U�Tc��
R}3G7����l�����Z4�PL_� �O�P��
��G	
�[q�3|�H��Ä��zV�x�&�L�W�Kb}4��g���A�^�h	��:~�e�8� I��("������*��9�y����N���핅[������<bS�lK�8팒n]Vq��-_g�)�榢A��2��������=c,�o�w�;i\�tD6��>��N�̻=����!�2�����#H�%�&0�tW�N�	�<��xy6`0E��ؓ,@�dAR��uq�C�bǓ�f�M��V��8â(-_%c�`�R�&M���ƣ��ӏ�<�K�I�����oſ�5'��Uz��fϒ��ih�*]qt��*�
!ǡ?�E��z��<m�\v@��U�����S��M��N9�z����KI���{$4�8�R�TI1Co��x]�S�݁�a��>�]��ymr��\+��%��R�$�%�d/��e<e�s�z�z�7]Ƌ�Ԃ����<�i����9-�U��wx��������	a�G��z�}8!���T�Iȱ���:,�|۬� cl���$xX�}���-I.lƮA��)����
y4�A+d�J|ՐQ��A��H��c�L�B��ʠ�ꗜ�8�@����0e$���rwM�]9)E��z(���lSWҪ>���6�p�U�b�4n�Y�z�4E��	&GS�tʎ��@�z�~y�jK�;��k�V�������Ob�Y��<"���mҕ1�o�#Zz�jC��+�J�Et�!�����W��^T�yx��Ԅ�����	�s����:�U�.��ɸ>t�'i&�u5�qe_�GQҀ ����B�]�XڏGc�lHx�"�R������t�b���`�L	����";߫(4��Ւu�V?��g-�Ci��˶u"��c�+�@Y�Z� ���O�����!a]��
M>��m���v�1��Sk�A������4�кģ@᠃�1��P�*ݿ���G����M��ֆ���!AIo(�zPW�V�Sj0Gn��f���Y�ro��>���H�=��=��#Ы����d�Y�T%��:h�"?B���Ti
v��(�р����>�kW��Ϲ��W�պ4R�tD-�Yg���Q!h����E��,�1����lnӊ�X/{B���4��WvxC6���h�-ɐ���3x
4~��Glx��{m���N��x3��^��&�z
ŝ;� T����8ʎ�cןYT=Xe~շc7�a���4̦��6���N��s����.&K�{�=�5����%&�6U
�@2�D%�|����ǵL�"���0������)mX�0͔a�C����;3Mh�T�Ea�:���{G"��L2e+��H���]F�������n$��ʟ� Z�'(����-��Ck�yN�����"����b����v8��z��s��@�(�
"wp8|�ABh@�9�@]Qd|AL$~ ��WÂ��z������!�<Н��js�� �ݚ?]/����xJ{��-���B0lƜ�1c��w7.Թ�nhO���ɇ/?�}r���'�佭bB������_<Y������~�W�;I� X�nu�����@���n˧��36����AL�>�'��ӊ�X�⑬�Z�c,R�|�-���9j*/93qZ���	9#'+Z������W*C��{��U��H̖P��<�S!s���sg��)���S�ɏV_�z�A�Lݰ�"���Y��8�{4a��d���+5�!�s�ur��歓�����P�����*0R��ځ�@�BO�����%2x�i��G�Z��f�	���&�v�
����l�����X���-<y��\�ژ�����/Gj�=��Zu�s�~-��Xwᕗq�o��Rp��_xCXۄ�#�ˋ>���p4K�H�)쏝v�t��/�%��E"�E��r\6p,�B��H�E�����+��rN@��L�ӕwpQ%.H��x�<��xD�b;�u[w.�M�=�R�� �f�ʿ<R%�j	'���ta\y
�WI|f]x@���x��9���^.,��ڕ�i8�_ɹ�8�%���=Q�-��K�s��P��\ʨ�Ǭd��M�Ip�BO.�*&��$���n{�Њ�SL�0_L�g���#��*?6H��kc�a��j�<�M�'tw�&@�S1yiS��@aHۣ�|��YJ�X�'�1�|�m��U���tx�E�KN��AZ�.l�C�:�j��KЊ����E���(�H���R����;X_zWZ���,�*���P�E�[Y���:�#�Þ�9:z�)��@�:-q�w�*�/jW⬩�*��G1�m����Di�H�	5����G�����Qs���FÎ�H��!��L���b0H��ʽD��(�_�Axdz��Fqˠ2	7�V�xx�{��Q���K�m�7�Z�B��ife��D���e
�T�v&M���nƉV
�g5F����:(6�\ ���|��k!�(�o���R�[S�bj�@��TA�'���[�SQ����_��:��Y�ܵ�o�� ��wI�CO�=SFz�5,�4��E<9��2�Y�w�Oc���B����}},��.���q�^(	
������>��2�����C���o
��|ĪLd��/jJb�P�(�ĵ<�����Xd��IA�� 
��7�?�}�9A�dW���\��C�R�U� �Cp�Fl�S� �4b���a�y<a�hvꁐL����m�HFt�c*��ڂ�K�A�Plh@��e	;��(�S��Pa.m<�6�������|Li�g	��.2m>�@�0q����x���_�}��'
7�R�a�K-��i��3X�ͳ�`݊���	0}�)��ʍΑ�U��m��/������O�F12X�0÷m�䕛2����X��åT��@^�9*]?��t#�y�L���n7���f~�-B��pۡU	D���M��M�������ʗDq�e9j�DA�
�	��;��0��=�F��R<��+z��΍P�ee�9�{�g��zz����K���]7xPE�~�k��K�պ�*�ֈ]-�D�����I57C ��o�H�U*[�0�j_���HI�>�F*&��EoQ ��_e3���� >M���"���~%���gʜx�Z/1n�!�}؊��kȩ4e�>ynW`��1DNI���>��Y�Ω0���2���+'��㾘ژlGK�e�mF��lg�nb.����	S?r*�������uT��r�����%�Ԝ��Z�X7B[֡�q[&���*l:o�p|U�F{e�g]�A�������7���L��}T�:G���0I���G?ǁ�[�u��O4�I�zG����<+��F� Y��k2⯆�o���ȝ�����̚O�+�OJf��D=M!@�=��i�^��*oB�X�O{���M��ߍNӓW��,��кA�q/]mk�
�
U�@j�?�A��Yϻ���~n]ǘ�7W�R���Ő�z��ά�Z^E��Oa�}��v!�ᒺ��N�e	v=ns�+�hm�əM%�ӷ�p/�!��KDT��TlLU�HL��T(S%o@4��q�!�\�ע�#���W˩��
ù{�Q��C!�>�8�a f�ꀶ��9�?��ʂ�ң3���������z<p�9L�E*�E���ƶ��	��� \�T���5/���^��#��ޮ)�7П�k	t�`�����F�Hx��X,fPt�7�%��O�����8i12r2�G�Z|�FLu�A$.�+��pE�S�@uj>�y����_�q�Jx.C���c�p��C��{�����G�
�Ć[��v�'�ћn/XX�ي�B4蛜�Q�$/RG��
W�,����$C� {$��n�΃�2�^�~��"�M�o�J� �KĔ;e�:�G�I�M~/�"�	N۬`��M�BIzB�{N�:y�if�eNR͘��.�6{<���/�K�!�q�޾!s
S:2vbڣ:ओya��!���'�ܰ��)�3=����%`�#<�*'�g�_��t,�ꅑ��k�
���e������NǍ��i��e�y��O���H~�1��s��8������*�R���6�-���qx���7��9uq�4��<�|�Y�f>�CE�,%F��6J&Q�ȫMO�tx��f_kݓ�Š���:�1aa��m�I�-��[�P9�=:�GsQ\�B�%�Юۊ�]4�z��-�8PH�+S ������U�X���CܹLY�/��?�d$/(w�:�� [������6!Jw��7�`JJQD�'�h5ʗ���U����W�xޠ�r�IJho�����r��4K�MI/�m��|��=�Os���^b9{�yGQ�49���Lo�Vc��4ʙ����5�=�L��v��'�S?����V�����F	��q{X؞^G"��LH�>0Q%u:��ti�.X^�	�	<��� ��+���:q=��R�7`�L�0�;�nx �T����n�0�)A��
��Oo3�&�m��{@L�vAf�7XGF!:M�y=���X@@/�k�w�d.Q>�tU "|�L?��qZ񊛯��D�'�z�����0��2�
��8J� �Rp�Ut@>C�%$�v�q��T��@����P� ݋�c֙��}�W����L���vv�ߊC-v=�C��Ԝ�5�BM�Z�����w<$_h*���hL�f���%Z��L���
S%�O����3�N����e	$��6��}���E�;_��fw�j�x3�4��#� ��97oaw�L��}��M�o('�Q�"�%��8�c��@�`�Fm��@ XuO�����ao��P^�o�;q	�Y}��m}X��*
:����׽��l��k0����\�c3 �6͵�z��� ��nQ���%�4��<k��J����I[��M��]A���]��/���s߮Շ���,ʙR
��y����D=G��U��E��K���vTV	[8�.���ry��d��1�qȄN��������|�Ƶ9��qh�J���0U�g�5�و�$��:/]~=�pٟ"��Z7��MU7�k�܏ȍ�z��4�Ԏe.۲(��$3fG��p�P3�����WXH�t�Z�����aOP�\�u
[V�B1�l �|�!���)&E �?��ġ�c�9D�U�<w�g���e�9n��c�����ﳨ��x5��tK�Oo�!WC7e�y�X_�ҩ˄�i��"&�g��e�<�뚲|i@��Rv�-%�f3N���̊s��� L�6�Ҡ���Y@�U�߽�T�X��*��);�ًp�����f�gPtq3e5_[�����XH��(I�A~�(�9C ,>���=O	TEk�^E)5-m��g+Y�����?tᐄ���&�1�$�=����+�%B=��Y��<�W���j���Q��FN��^IqI��Ao�ӣj���	@���,�1Nmt�8	��DְE�I� w�o�*�eS���y.Ė�����˾�BwU?�ɠ�L���Kr��
ϯ�/�@��!�:���s%w�F�M��y�*܏R��a1�<?��M*�c�����S2X�8{3y���X�k+O=�]�b�������b>~*�UL��U���Lȹ�lo���{I؏��LJ>䫌y�Δy�k�-9+�O]�1I:'օXT<�5�������1��oC�%�1���f�Ś� ��Hl�۶���P�Av�-�辖1����g��^k��j5�)����M�U���j�c:U�V��Wx�B�E�Y=���@���7M���rA@q��ABU�H�'��y|�}.h^<�h�PSz��4�Uo�@�I��P�D�A��8�PDѳ�R�X
�N�{.����Q���k���X ���kRέ�� }~�{�}s���W"�$��}V�9a�Ϭ;��Ց�X����oM;!i�X�a����M$�̳jΔI�ʓ,_Os} ޵�ܶ[�����<����O>�Vp̸ZFm~ǑT��fׁ��$�K����87_1�i"#��k�4�+4�O�`}/������nFl}3F�_��I�\�?�J$���P�F�%Z�~�����	�)ŝR�F�m*%�yU-Y��6j�	��Q=�ޭ�)�ag^������+�� ���>�(#��hb����:���S4[Nrl���R�x��Eȉ����5	��T{��n#?����b��u�W�H�����>aV�eB����w����͇۶K6�t�BCK:r�*��t:Y�6u�[&�)W7�;������B���R�<iD��y�xYУ���k^�x�k{� :{ft0~� Ґ�^�����&42d�uG�hϦ�"̄�wk����WZ�ɕ-�vS/�C��-!�T��
���� Д'ꂙ[Y�?uf�����0H��^������rY��{FN�paG&�2��%�\��ew����M/3���Ay�\<&��I���I���.С�W�b�_�vv�Q�s��x������s@�$��ԭ=�SH�A�(rSd��+�aֻ��ew�����.|��Y��н/�����*��0/0�J���ud��W�H�{0t��M㥙?��&������g�~�v(n�4gxƞ�g��0�:I�Z4:5�1�X����8������/M/�+�r0,��Z!�3�䣈�ֶ�d=�b\�[zIh���TbFr�ӤV@�gq�+u�I���Y���<�n�a�n<
����e�xZ}�M+�@;Y(8����{�H�D�f�3�	T@0���y���!��͚��1�� ൠ�g;=��<a;D5��nn�r��:����xJ���.H�� ��I��,w�Y淶gI���#&>����d��l��	�m�Ψ�6]:�8�To����}�9K<V�}�nsxo;�'�D��>+NAC�z�}�;������ܼ�LF!�(��D6�z�UVb���	���w@���?���)	�߈и_�xz�bW��e�l2�����w3��UB?����/r�������U��j��& HkG꭭I&Gc$ə�����zT)�e�����T5�P����lߵ�� 1���R���MlW���cSKx|4U%��Rk�u�U��)��yH���&e��@�)���|2~9 �䴖���ˇ�ͦŢ? i�c��d����B��u��B���IVs���]�Q�[��c.�݌Z=��$�s�V�֒��� �SPk�T�P���mS�)h/��%#��C���Ѡ|p���r+�K���=O�Q�����Z�P�2��T�0?��ن��Z�*~���Yt��s�q�t>W��N�n8��T����eR̘�n$�P���ARM�W%~���$^ʿnr�!�	�@�pʤ�v�4Ӹl�ja�5I=9?i��9)\�C����UJ�o�9�u���`����I�pWh��s�t�a����a!�\k���RX�� �"��!���#_����Ji lQ�7�u���j������"Z��p����Z��"��j\��!6ꙸ&=���F�&��>�B�
2W$.I���XIJ����Y�%����k䬾p~�T���3�<��=��뾭������l���"�'�������_�S��K!?�N�`n�U���j	O����i;���8�[��JMS��Fê�f��	�q���?�=v�~q\�.��6
0���I8�骓��� �!b�YG��tQ(��gp��9��C.�*�Z�/Ϳ�V�qa�����
x}J��v��&�uK��#&A.]b�05�b�m�AΡ��'��R�"�í���\;]�C�����%��?�av>�;���~��K��I��.q&	�[`������Z��4�u��@_B���/����"/� G�	]E򽱂H?� �$��Q�6������%����o���2B�g�t?3�Z$���]{g�l4���6�O��e|@�]Z��ea��AV���g�!Q���老��
f�gZ���y�&�.'E/e�J�dԩ�#w;Sͷ6�O���]>��,�՗��-�R�	1ʔ�U�.�&^����@7K��8+��/ɖq�\��lu
�����*-��_�8�^��6��}�r����NN�Ӹ3�AY���V�4Z��.u�pe@$qv��K��B�L:��@��IY����blk�*+��Z.��k��s1y� �o!�A����t�A~3q[7B��#U��e��e�Ś�bc�M����񗯤cyu��X�[ˍ�0۳]����ܝ.�l/��3���6�=�zɗ#��֠O�s�\iD���5�5�H���j��.�;�wr�I�U�B��W����~�3��
;@����D�Y.���n�[)7�i/���ˮ�W�`��)�%�-3:t7t_�H���=%0'�ÅAW;p�i��yTsj�˦�.'(OV��p�����u�<���h(]�L����ALxh��֘�y^��4�ߓ�L��D=S����p8/�X��ӳ@�Q(͵i�i1�A�Wۈs�-7:�/��[7��u�ރ9�P�i�Կ�Π�"���������69�g-���5�z@VXW��;�^d&E��]%,��"���RA��	��u6sW<���Ni�߰��<j�Fv@ߠ�uZW��ϛ���01�Ǡ�ΈQ��IC�h,�Wy����D�r�cM�w�mOK���	7���K��X��i����nc���˾�ˋu�����n��r���c'q��U�1�7�Q3�� j׋�*�d-IK��� ��"��3�a����d�x]��ב�r.����h��hҧU[��%t !9,�v��k����C�O+����=b��T!��r��b�C�"Td���lUTS��|Ao�$�(�k�v%q�	]��R���u���#O<ڷu���*���3��A+N;T�P��9eJ��X����J$�M��&&x��T���C�H��͑����3�R;Kʣ)���0Wg�N�l@�\{2-��,h�@��V&�f�H�}�/�x���FV���S�
1F��1?^��B�	׬�z�����|VJ����'��2~��ѷ�{�6�(z*�%h��@�<�y������L��2&6q¦; ���L^2�;r_j�PDY?'Gd�TbI{��eK���O�ֱ�h>�����!�5"�}b����ξ�Bo�6��9�u�e��u�w�67i�l�n�|�9��O����?@���<�={�v�
4�򍨵ca+ >�JgP
�5��'�~X�At��ce�H�E`�- ��]�d���f���^P��v~a�,e}e�/L�B�x�}��ӓ���[��w�r�n aV$����p�}w�dB�aF�/:�,h�7cwg�t05���7�5��ߘ)�^���I�^�YoF��M~.!)�/�(G���=v�k{e!�G!QH�>�
}ǵ,'AΝ~ט����B�e
j`���
W�����6�2�����Y���V�f%��"�=v�t�t��kh�KD��:r;)*U����Ĺ�oT�y/ �˶��i��Q����l�jr��Ϩl��A���� ����NVO἖+~;��v�PHޗ>'q������j'����o���Z�o�;�-t ���n����hLص(��	E"A��PΨ��'�<a�^���r�����xny%���b]g:�bԖ~pZ�εT�69+F���/Ժ9	�:��cv�t�t��+qd��eUv�kR��6�����7�v|Zd�V�,��"n�i�Nr}1�t��}=�GW_c��
�g�����\v��:���--�e��#oV�T����  g$�F��7�'2n�$��/��Z9��A Ԣ;��fT�u���(�(�P>��c�]˧M��+�t**��ȓ�g��2R����v3���: �L-�?D6��|����>n:>�$�t�a�^��\l3P�@��ޱ̔��#̲��΢��О�=�$�a�j.��47"_#=�j��6Ki�� 2 �T�
�����o�` ��c+��N�)�t
�5��-���02c��n-�n�\��\�h��j�e 7��n�%����vht�ʅ�ɫ�ňK,�lz���;JD���E�qޗ��k*�:��F��"HV�D���E"�P>����҃3��[�3#wxk��u��"��"��H�|"X���h��h� D���A}��@���Q_�k^����s^�JZ_�3�l�E���"2��?���Z���ZK�D�mo�X��2��(��<�M�4��h�eM�)p�l��7��+���~��b[�.��^QF�Z�Q��2"���K�D�m˰�2�5������8q��"�4j��!�Y��>�n�T,��,�{hV-���`w6B�!��:�����*[�����R1:e���+��T'ٳҥ*�r~(�Q
Z�vZ�O��,ޏx�S=��́�b���Soea�:*b�3�c�<�T�����|`ԓ	��������^�O�\A���5p7�~��g�?����3^�bL�+kKv�=��W��ߤ�c��m�%�8���f��.�Ʉ0h��ܸppb	�V�ʈ�~:;NF�7x���k��^��a!u䌋���D{?#$���\��XV��.=�	�ѭ��u�D���0`2���_;��c�������? �oJK(C�;@�� �#�<�O-d4J�70��mV[W�֋Zp ��?)_�N�i���Du����
���\Կ>��h%�Zܳc
O���g�'���6�*�ݼIN�R"�?��"[�6�ݽ�',5z@�((��Y�|P"J�����];��H�K<5����L�!f�x_��V=�	�0�Q�	��
�;�6#<c��iQ��\��QTU�1&�ٌ�N.L���w�r0^iC=�S��b{�����Z�f�lI���BN�3����\����l��%T�2�l�%S���z��I�c}(B�9��/9C)��1	����ՊN�S��y�b��N���1���F�+������w��L��ȹ�y
ͤn�I��m`݊�����U�AX������$�7�{�v��m������9�q{���s$u�K�ь��q�u���É	�I�nx�/�^ށ�4���,m��Mm,���p
�
oϡ�ߜ�b2��� �e��e0�^��#�n\��d(�@_/��o����H"���+M�@� ".�1o`x<^�Zj�|�Czi�[�1�}_)�8�oj���ػ�P�\z�3�{q4Pj*/'jr^p<Þ���c����5�Z+�슶ς9n�&a���gJ��;q�f{�ԫ�(o�FCF"�f|��Y�n:�8L�ط�|7,?7h��5slp�@���P[u���헹Z�����>�QQ�|'���z��}�lU$��n$K��5h��N���ȿe���%�oAԮ-	v���΁
fN@|���;3���P�oC����=���&Ǡ�H(����2೑��Xd�����9�T��6S������$��H�ͳi�X/�|n��� ̜�ڇ��Pu�町�e��|�0��*�&���)������$h�i��˙��(�;��p���%�E�ʿ �*�[	�Vp�	˱���l�Hӄ�VQ���>VJ��?d�P�Q;i��_�H��VG*���T�=e�a-7��2�6�#�R/.䁋ZGd���G;�z+;[��69@� "����k���T{�%��B��1t�Y<�(���꾶b��i&S�b����2>��+��H��N>�W��FJ�J���A�(��N�� |
�
l�zU��U�ڍ��lkB�xO� q�梞<�![���u2�1�'v�����DL��pc�p]�#.�M !�����<�[sY�K���bL̡�JX!Q�+C�4�$�Im��e��o���su�y�@�>�2��F�ڬ�1���v�x3��nW1��E�>��!��$|s׀��;% �e-���2~X����#i�0+MF�Sǈ�-�r������BWI��$E4��=$\�~��8��5U�S�'����&-��sB��v�'��{y8��bc�N���/+y&¹�EY�������
"�A%Q�&�^��5��t�Cu��sES�tV���;|��s�#i�7��������͜El��ͮ�-�;��@r�)��}l�#H��ip/���7�k�a���c����D8�͜h����%��[b���O�&g1�����$In{>����h� �Կ�C���W:�H��j�[�K/����8$�0B��k	�<�^���:�jî9I�)���܅W���Mݮ�,τ��I���lw��oIs4ၚ���Mg���� �dVw\0\M�����N�@aM�%���i�d"�;f���D�$��5�:��+\pk��K�$DO�m�h0�4ø�1���)&ɁO�(�U�1G�~��a��.k��`ӊJX�����G����q���? Ɋ3 ����H��g-�Aq�VfZ+҈5�AEA����OQ!�y�+G�MpeS�dG�L��{[f|�=��Y�����Sbd��Ϥԗ!��H�l~��\L�q#z��=�(�܇RU.���~���y�{��X`�3��W	W����fIq[`)'��!cij�[
_O½\�a�ҙ`�EO�e��� d��<c6l��Ȇ|���
#�GX����z]L%5乧�r�܉-��������׵o[�}���#x�����l1prQF���?7}`�ê���Cr �IPx0�/�~��)k��Zٯ����"���/��O� ܸ��&���A��m"�-��?�V�?y
�&�[p��>-���
�� *�O�D�$g�Ϟ�Y�!l�uh�����
�ڿg�X��:z��ָ;���n�b3����P���-k�>@�?]�@D���c�G�i�0�)���Cv��p�"�э�,�[��{Zr���ٮ���J�$��C�K�K��|��4��2��Y��&�ͨ2S_���f8�EM፽�,ƂRR�[��>�9����@�\9��-i�?��P���|�nPe0��>O!K�8���G�m�U�jV&�{1ٗd�PH�EG�"���w*�z�_��ђ#����f�'C�'�5�\\o�ڋ�ۂ�����&�3]�Q�m��{W��[n��֏��j�[��gUc�,`%�&<�1�x�h&��J	Sӽ�K0�@N�fΣ����U��8Sͽ֐L�K�R»r��Y�.�f�U����k�^*�Ȭ���V�|*�
n�`�U�?���I.�I�6��b`V?g��-/qW�1���X�t����Z|��j�1����"r݃�:��V�ogxҌࢃlyZ|�>K�S/@un�ū�j� s��'���=�(���1��H|��|�� }���1�(����%['�[���W�G}���2)���g$^�ty;�k"�R�[:�{����֘�����R>|��A�?��w������O]��M6(��\�\��W��n`��TU<J�p8ڝ���<�oՈ��C��<�b:U��Rs��5�1C?�)ZР[���3U��Ģ���٬ ���D7�����}��ޝ�Y�9���e/A���=����1�08 Ή�zf��T�L|C�^/�7Hq�4��>)�^-�k�$+����ȸQ�&o��+��gU=5y����sj��|(D����C��g�RV�ZT�O(�.ɽ�lާ'�O�����ۦj�Cå̔��F�T��5�n��b罚�	�5ї�`������¬ƊԬm5g��6�÷�22yZ%Kc�d�V���"�E��lB� "��Z�<S�IC�^��(c���*�J�HNJ��j�P��{&���3��M9��O�Nt��Nb����g�'�ᅛ���	R��R�E��#�� YZ�������5�٭�ie�㷻=�5V��I��"�4Q�����M�:�j�<&ĺ�Λ!/�.����-��O���5���hk��/��٣er�j��)�Tf��:��6�s���0�	��2�,w��m���*HAR�x��4h�z;���=��d�*��>�V	�S|��	�:��Y(��6:2ũ��,�f�y�k&��\�"�;�
[� ��{waǽ��Z�iу�o�������˒}
����2c��p_M�5Wi�4�q��o���6;�7l�N�۵�Ii�7"Ne�^\$sn��j��\܉�Ĵ��R{�z�N�J�����E/o1~����J�}�n�N<��6�F���3��'K����y��Ad�y�r
�U~H�(y��-���h�p2��Ӛ%�sg��U!5�n�ns��eǎ��Oњ�O���e����'�i]&�۳����I��*�*��s�Nuw��2J�x^�`Z	g3-:R���Y0%��}�-���=w���3~�`�sC����%	aY�!)N+�[`6��u�b�g��ө5�]fO(�GŞ��aym^��F��֡$�u������Z�	�� �(�ڤ߀��:TRe��I��r��{�^�qk��ޣ�JX,09�`]5�.�6�'����|)���^.�Y���o��4@�U���]Q���zf���r,po�
�j�*��&��c)��1P��?&d��`
���ol�4�xC,1����-������	�a�by�C��H�⊫�0�,RՐ
2���o��ǚ,�|��ӗ����1�x��\&j�%�h���^_bR�P��U1XP���pR^�h�^��ȄA4E�x�W��������_m-2g6!Ӯ�r4�[i�Ś�Ð㒲iۆ버_0}]M��ق�R�4(UJY��ܦ�dZ�>fN)9�~`I��l6Ã����Q��3t2]a�(���nV��R�156�e��oҋ����2,�H��z�f�]�]ӊ�Z���Gm� ��-�H�}���
4f�Bj��]�Ѡ�Ex\�����,c����Ϲ-σ��6�A/ճV}Z��7�{��o�;7��ٰ�cI0������S�z��tz?����W�6��7n+�i!H�#]���[��O��~US���I��B��z4@iо�� Jw�����!%IIT�٫�:�P��8'1�9ߵ�#$��C��)e��1G9�͞JǞ�&�<��KcCD�^w�Q~y�I�ɠ~Y���:Q1Q(l�T�i2�A�𞲞qӜ	b��F�O2�)>e\���-���PI��1��{uݭ�S��� Xl�d�,���<)z	 �!�<g\��Nv�g'��A��홪]�6��9s;���>�睹���Z�˺'lb�p���A���Oi̱_�?lb8ܐ���K_�]��AQ���Dj�B��q�q
�v��:��;4Ƒ��|��5��@����Oq؆�"Wleu[����	��s�p�	��5��G%n&(�2�]8q�G�7��X0���c3%�ɶ��{b^K�*��[��6���v[�� �B�>u�3Q��<�d'qJ�RU��ڢo�+X59o������A9�D2� ? *��u)���ӥMR�`0T�Z�����Ӏ�W�e���r��t�_��v1��p���.;U����ţ8T	:�:�p��b���w�����	�^��f ez}p���Ml\$c�Ua3)$����.���=An9PD[e�@bts�%l��'V��p�"��p�{�"�TeU�ï^ s�gipm�U\�.���Bq�t��3��X��v��񖑌�lʡxζ#G��.ҭ��;��j��E���nԳ��r��4����Ry!�w2�_��l�F����g��|�{��=�-o��E�BĎB�|�HOS���FV�]���{�k�7dQ��4 �2�a�������H�1J��.���=����ˡ��:���ʨm��V���2}>@=�g��+g��e�y�2�@�;ж�f�k�C�����pR�4��
�HQqNo�}����z���'��Rȉ��q��#Y�1Do*Z�5Mz���]|�(_�κ����13VLw.)@��-11��̋�q�y� "!��qqUQ���EԨtJ5��Ջ]f+nO�����V��ڑ�p�	Ď}E��O�(�/a��_H�t�A��BT���\�Q���:&Ap���s�[kމ��P �>?LZ��?��B�%/oiQЏ���v�7����6�f��]Kh�;�&*�S-�0��Z� �<��F��j�)<��R��   2��Z�g`� ��� �F,��g�    YZ