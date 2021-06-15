#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1440135202"
MD5="1ac774bd5a4c19c06c68dfb1b2b30f26"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22336"
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
	echo Date of packaging: Tue Jun 15 17:02:56 -03 2021
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
�7zXZ  �ִF !   �X���V�] �}��1Dd]����P�t�D�r�;��q���I���7 @7j�L@Sj��hTmX��qCA�EϝW�1��Gu�x�� #ox��.
�	"�_c*]�@�e)fДN<O�x=C��=9+x�|Y���@�Y�Z-�LI��p����x��"�m��k����p����GW��܅c�sQ��|L�-���ZuI�Tx`b�x�7k�Q��h*��A}!ԇ\w�V9��R�����%}J� ô|gx	=PU���Y/u�n�ǂm�Ssg&����n�-�Sl'w��3ҷF� +/��W�G����� C� S!F�1�H�~�7��k���-��l��X��_cgJ�l�&�	L��m�=��I�ұ��Y��
�"ct�<<�}��_�P���y%v9�W�&��"{�~w"���_O\ҕ���]{!u�6g�ΐ����/p�`�~��X��r��l�qִgK������>����^3��&���NW�`�G�:��q.y"��s��.�/�J(�A�[�c����E\R+���\F�}q��`P�G������H�k3�L#0*ߢ ]z�������,��@J��U�ɘ�i	�����JvP��y�t�l$��$�ō�=�	��H���yJR�~���7���?;�_�������'t4�W)����\�e,IP^�zp�n
�����0�W�60�ì�O�4��a�����S���Ǹ\w0á��)�M��3&�a�U����?�"zl0�Q��6�=���kś��z>�jō���ӹ���"q�5y���|��ý�>11T0�?#����y�FzB���ԇЃ������=4��2u��c�Й�`a^gWܵ&7ԟ8h��}�".C�X8�D]�}���r!i"��3�j�\�xL���y�q��v.[o��7Ċ���)���!�x��0q���v���``HC�sj_�W�ePe[�ϕ�6��A��%�BopM5]�`-x����,�����އ����Gɒ]����_��qe�+TF {�P�I�����j���%��5��R� ���,�|n��f�3]���G�'��(��.�7iRJ[
-'�^�_
(80��z�:�6c� ���t�a3��qy�ƚTS��2�k!��������H�� PCs��^�2V��!i��F�#��6Ie]������w/���ۆ�f{Ji����P�B�I�"F�{/��=����eB�(M�^�ӄD�u��̤�Ԣu(�>,!)џw�D��;VK%z�ؓ~�;�2���f��z JIx`��+!�>�c��ĭ нI�>I��=���q�=��z��E2��1ӫ@!��kM��U4�7�Z�*�ξ�:�;��Z��I9��O���D����I\����?��ӹ���K������e�
��<̉"��ޣ��Y��͢��ST���KL���6
���r�s3e�:S|�;�y�[���0Jd��r��E~�����ןw����j�/R�x��ق�؈�$�^\|?#*A��(>�ɾZ!�� �C1��؄�W�/��M��� �/�x�TK���:F ]����sɯ���F74���F�耛�=>�DNxyH+��2�W-j'����j[�`Дw������Y���C��{O�v�"��4� ������T[�jM*��i�g��K?Z;�q��ˋ�(�&�/uU�
��Sn����k��Y����F����?�=.��vUl,BG���޹l�"���|~�b�
_����msL�}N�1�>bZ��ŕT�z�h�{X��_��=!�6��k����2=���0HM���u�������/7A��61��KfQG���w�]G�q-�}�+�7ȓ�e����:��V�0 /�<Jē(�߿���h����3����_�����rv�p����sKV����F'�(�>O�����<���ۯ����a��ژ�*-��������tqo�֝��O���<��2H�/�fx�g� ��z�	���q�&�W�֎��Lc.����<��w�d���Ch~Ek[u$��	T�	�+:R+��^��Zr�,چ�
ͷ7E����J4���e<��U�QaQg��s��u83ߞk�1��~�	t�t�Rt[D�_�F��ीN����dm��y��P	)f��݊�n�1`,t�G���28�h��	�3�����b�;$�**�~p,����cK-_����������Q	�e�[�W�pd�
�N��b�j��2ʲMc���	�qk
�"/V��Î[�[̚?7�[��9������g�5��˺Z�ITƼ�h,E/SL���G���~�B�&�h��`^��|�Ծ��̨�*#�%H�`��=�<7��j0������ԛ��D��G1�O>��
�@拶X]�e���t�\{OMe��$������|.�K�B��v�L\�	�Ե8KC�O�w��!$���r���u�q�0�P�s�|��g�m.Xa\��cݯ�!�3G���;���^�.�;H+BI��4}��Q��Gv�٘m��űI��&U��@��
{��)�F��Dǭ����1�k�%�ו2������/'8�����9o�]4w6܇P��̓��j��J[��ʼ�&�v۳�W۵���6�z�����Lh����I.���Ș,]@tTmvL�w���'%W-\�-ɂ�ܐ��,˰Yb�;z��Jmag��C�zn���ؗ@��	�\[�_�Bퟜ誎w�r&�������6�.��'sc�ÿ��%YShG�1���N�ē�xQN��q�E�q�\⾭�T�d�	�%��4�լ����g�w5/4|�jU�zy�h��s�����L�a'�v�2$C���V
]y��Py�{�_�u�����=�)=�}w8@ޕߔDܷv
)x�����Z���&b{:8��kYL���!csJk�+F�UYK0u�W4m��ej��.ٺ����7��O����)����!6���M�D�9N�0L.�9?�G��w��	"۰������'�c}�t��1ɍ- �z��w�us�=<�������v��nt��%��B�S�a��JM}�JJ+�L\�Ǜ�����}<����Q<����l].�MQ�)��]��?��/��(�n�XjE4����GS���G\�@�����/��2~|��[@!l��H�Kg��1h�#7T������n�|:J�o%�[�Z�@�e��S=������|��y6�r���3��	�K��q�;Tc��t�F���j��rl1)[��9�����IOL��I�x�ވ�v[�wW�w���L����xI�֨~B��*S�X�2�2 Od �ª,��ws�)Im�6�\OX��J����ɉEbᢥ���`B�Kf�I��"�%��2i�sJ-ɶ&9��<i��r��l�ܩ)�5��S�~q_G����nK�~k���|���8��9�O(�m����=f�Vv��f.rO�C���������P�<	�����q�����{�I�Ʊ�'�Sw6���f��>�(�:'m�=����عM;_�]�<U��}�� �=Yd0�T�=����[]9B-]5��[�u�ė�H�|#�׵�O�*��ir�B�t�f?v���kW�jq�E���vD�|�|O����C���Qۗ�Ӂ{�iu���b�}�27nHVri�񁘰;V��X�j�%�H�0�߅Ρb��|3�ܩ�m��b��
�k���Q�OV��G�O���-���VD>!)��2 ��ږ!iN�z���l!lmxȌ0�ŝ��)��@fro.ty���*>�G���bM�2�@�{�gQv��ˑ�/��x��(fg���*�,!�&�˞^|S�ȕ;�A	\�@I+�%�ة̀˩w���R~���ګ��*��z�b�C�2sY�J�m��0�	~A�x���p��Q�7�b���M���q��N,~N��s�{�	�v�`��K��@�9R�}aq3B:ɍv�����t�9�j�������~�g�1�v�?rC>F gc�L!��_ ��9��rM9�-�cA5�Ĺ�A �4���7�c&�vQ����ȴiԷ*��|�@�Ij��=zM��kHY,�oL+�X�Dl��{XmcCp���j�{�������i�Ln���݆�j�o�����ɀP�Q�	�	�Oë�,�'�m��	�^����)/�Ljr�K����OB�{?��Jb�$����aX��kB	�l鲗7�Tt�$�w���T'����?�ʮ��
��=��j���&�Et�s+[���'zXB�F\|U�'��}eCkn��_� �O�8�⅚^���L�\z9n��a_7;��9$Szw�+x��1ݔ4��Ih����u��|�S҂;�^2�Di��|(������R9�T���zAM�P��`b�ri�U�H&�R�u��F�����[Cy�tP� M�J��cc-ړ�o�so�ÊAI�{:(HS�
#L�gRĽ]y���M ��'��-hZ�.f�G��\ݴ��Z���~سL$��k���ԮI����Ih�]��,��Y�.�a%g���aG�Η��.����kh�84���-ϰ�B�ț�951ڧ�Z�����o����#;Ȑ�����uxL����b�%�qh�Mx-����V.�����_�����&Zb ̽a�'����"�I�E��vX��]�fĮ��?;�5T��8�g��\x<3��a^��7+ZN�}�2�P��\�	�r�D�H9��.d���H	i�WJ9�&���.
Pቶ�3�ܹf��O���^HBkx7�sTn�V��������y���/I����P ��)�m���N� X��8��=y��{D�#����S	ҿlz�a�Y5+��c���t�ꋀ�1�\D������ԝZ���.��]p|T����{�^��'Vhd��;'T�F~�Ҟp�(�w/�@��r �g��N	��yS�9�����V�_{���PS�g��{����$�����pW}���#w�[z�}-"<��&�`Yal���-����v�+�ts���4���=�kl���e,�M��Sp*S������Wנ�1q��,���ݧ�/2cі��QD���Y�᧜�Zc���Wcd�xzO�'�H��n�ǄL�oqp|p�b"J3ު�+�ek+yC�D(��^ufbV]r?P�%�".����� �&m�[]���S��G-\6�����"�jj~�G6x��Cv�+�i;��B0�pC�$��Ӫ�FB�@>:�������J�I�~WhP�㜫�X�r��	cI�X.�Nk�"u[RC�6�e�����[��0T�Dig��:��S$J�Mý����φJ�h�W�4A�F�e�!r��8@/ 仗��Y@}C�qtM%�}}��G�h�� ;E�b��
{�#q{?�Ɵ�xn�$,������Y�؄����N�'+���Fa�������R�Pc�n�;�Ѣ��k��{���<�EH�T*����#1:qB}�[�:Q=���E����X��FZ#:]���/R�0�y�lj)�::�4l9D=�R'n]zm��1{��&d���R�
��
#%h3ͨ��Ҍ��\{����'���B�{�[�,��~�s`\��y���g��[ָe�j�4>���Zp/�r�!5��L���#����ӇG�7�ĤLRY�M��}�$��YK�|uy�����`/@�Wt᜶�4'2cH�H2�Tw��)��a���>�����a��٢r�Aϟ���҉��,NT�2�����!�����{��f��*{���I
W�V��%Їc��H�'�@4���})����B�5[~��oe�m�n�XB��n;�ڥngUa���7L�o��(/J�9ApM0"�����T����G"�s�tg���7�MЋ��Q<�7�Z�K����A�􅤱"c/��޷��^�UI��G������K�r$�;J�=��nBs��Ubު�T����%�8���^��I�}������*�6	U&<�x���������$����ln���+�ϟ���jc��y�m�r<ue�%:z2���a&�X��Y�d�6ol���o㕈a=������|�y)ˎ�O�����D -��֘ ��ԗ���2s�8��ՓF8��a��9�p��E���>.�e,��� P,�t*/�����*Acr�����l�%�0f�wn�MI٘3�*!8��_���:1r�ū^���W�.fm7���%DFg#���-q��*��Y�
{�=��Q�mp��Fni� }M��1��^Q�l���;2Y[�ëF�<C�w��?���3Iŭ���N���ohG�d�\7L�0��IpZ��ܤ��2�N
qI�ǽ^���3n��E}��
P�5Bݨ�}���pʥ
*w�������f�|M��(J�$'��8ҿk��(��V�el����B{(�Q��K^������@;t�?0c梅��#sG�X�����8�+G�=��J���=Ԫܖ=�b��L�u ����6̕�G��S<.���-8�^E�o��M0=[�:N�$�PW������=?1�a8)���k�M%�����'t Bs��b���i�T�v7��s�#�]�� ��f�cR��It'�m>�8K��c�+՗A:�re[��>�@��jUu�:h�g��Zi]Pf_�Yim��z�L��_��bQ�?_"�\���(�cu�L�D��I%ЇJ/)��g�8a[0o��/z���?�	�9z�;����Tݑ���@Nx�5�ä`3��h6(&r�y &c���.��Zp`t��;�M���D��ۉ���ڗ��������x�_
3�-yL�uI{�L�5�������i/.�sef����)2�i�|2'��CpH\/l3]�l�s~��n�6&�(TF�ِ0 ;�/n����ݎ@�[���uju��|�v׼o`�b�����$����R����?\����PqE3 O�0Mh!�\�)b+? dF ͘'S��Z�Di�7R��v��q�c[�6\�s�Z��U��=����v��hu[�O� @���,6�5���;��T������*
U)�h(M��V"C���Sk?m8U�3ĝ��u���禅�Gd�M��%S)7�����z�����Ui���L�>�:4��1�����9G�lD#�~��d�~Qh���H�n:`��x=l�q�T8�1_4��^���Z:?��`�Jh]�T
"
W��W7J����8�3hN=Cz`7�懁{�.N�L�WE��Hc�z�$��A�®�Eo�jȔ�և{5(1)��p�*)n��1Tk�D���)�v5r���y���a��;��p�<�c<N����p�Ʀ&���ZD�e�7
/)a�`Tr���B���V�,cpܫ�o|�Q�ӹמn9�m�JJ�#}::��ZK䫤8|~A�yUou�Ѝ������_��j�{)�a�D1����u���{������g�&265��;�U��%�n,��~�o�-!M���~{�N�!�U0�AKt���ͪ�_ޜ �H��nW��M@,�^1�D@�+�̌? >��,z#�@�K�/q���;�#��30es�K���dau���j�aB�����2���7�dj�Q��z���ym���N!(썪��-eQ�#�������:�=}u;J/�5�GWT�� /���W��z��Αi��mB��5dK�L��40���o�Um�~7�Oe��Wk݄'z���ל��* [ȣ0^�
i�5�c���3�Ϩ�xp�+��� g��Cś�'Z�G���DmL^8�4!�!)��s��l�X�k�o����H�z
�0�iÝ�=i��t����Г�Ϣo.N�
 �3�5��c
�<��q�a E���l	տT?�~�m��嵞)+��GN�g���8쵩;j9n;����Sx��miՅ�0�6��=�?���#ѺR4E�Fmx7��N� /�;�JY�'�J ��?��W�Q7?��/@Μ��n�)��9J���E�H��L���
;jSY����M�n2c��F>�0P~5ɧv�G���Bj�1G����ܜ����Jz-w�#NZ$��c��첡ѵ���>3wp=�f8_˘Tp�k��I-��f8��^�����V�ٝf?jS�Ǒ���Q������#vw���4����#~&��n>�| �3"��<��8����U���~Y��ahō����p.�h�CfCd����؃I�n`fh|��Vv��zx��p�})��|:;˫_�Ax��(
 F��N���n��NxK��a�"�$m�p=�5m��5�f�9��=�iN0,�9�d�:"�H3U��X��]`�W���cO�_��E�������.�nc���9T͚�\̀|�s�i
�HJF)Bd)W���w!���iѷ�"cQF�T��~��	��� s��Q�MMP�����m|�V�ED�y��|7�q���J$�9\�'�RAo��҉��ME���ox�(�$����������U�4󎣶�ƞ��\�N1���v��P4����<��"{Y#3�?�fj�ix:��O
���������2���$��q1֪�;cB��mg�7!c[/���p�Ǎ?�x��d�h�"E�Ky���l�Ӟ�x�(^��@�Rb=,~��U�����Ys^��p/�~9b�;;_�;�3�B�E�=�����Cx��;���4����4fX������\��7)�':Fw-}gN��6Õ@�nD<7P�_ 0�p�[���!����}K	F@���*m��
��Fj�D�5�p;����D��^۸����K�I��w���o�𱴠��!E���2�lVv����&㹥��ť��Ic�9о�?�h:X-��殸Lt�l�����ƞ2��k��H��Zt�kUe��J�ms�[bO�>��a��Y�׻�g9w��z*7����R��љd'�	ݜ��W&��Cd���Pe1T�D����2=g���0i�G𑣋�e>�ЦR�x�Q��J���
��u�������ؕ[��!�<��\\���6���l�-��q!�_��KF�����5uq�M9a��35�yb�&2�oƟwuPA���,A��������W���=�fʿ�B�����#O1A2f�Q�՟>��*gظ��k<���� p̡��Xu��\��-S�p�8���G7����F
 ���t�o�n�E+�qL��@�-[�=�;G�ډ�x*�����~ƠN�r_����}J���8b
�*$��.zՁ��'�6N��%��'C��8a
lt��W�om����V��=��9�2�5e4���hC0cm �)	h�!W�#e�)����s���C=��S=.H��o*�[߱"6*x(�5�`�:f��O�,f�8-ǆ��[�;������:]�5�A�tz9��<����]Zt��	$�ڃi�0��v��@�&/������)��
�������3(���P9�>���Ⱥ0w�9�4;����q] N >KK��$���w��%U�Pz��G�k�'�����-m�_�8dYY&�J�fn���E���t3��+&��Hu�y���Ayo��$�*�͠|���6>�l��!��f˫u�w�6��D�LeU���W���%&�� Ꙏ�ዸ�$N��Y�z�)��f�`)����J� (�Toh��%kH�iJ��;�8�O=��'@95F^��g������],O�Bav�s�NZB`�\�Df�]�C7ĳi
~ ���S�����濞m��;U�m-|c��Z�~�#w�ǢE,�>�:5T/��jI?9x��i ��P��H�9� 3�L�����2�Җ,T�mL�6������L\��\����}���rcY;h󊈀�E,��Y{�+Yw��D,x2�$�y���N?����)	�K���l*�8QTq�Z}q�4�A��$�v�uv��*K�ڣYC�\b3W&h���8�;:��S[����瓯C��&B��HD�s��F�N�%s.X#��V:!@�x��v?<\�n�y1�.�.��J�}g�<�f�b���t�W�2B�I�!;,�$�H`���0����e�a$� Ǟӹ�b�\�Ѱ�ʠ��?BT���|R�N�Z>uh�B���'pw�Žٷ�{��S�3f�@�k'�%F���.�C����"�
�����D2H��L�*�?���QL-�N׀琤J!T��S���P��E'�Z��n�|����=�Ѝ�p$�g�ƕJ�H��R��}zٮ��	FL
Y��7ݢ��x�|��C@JS95���Bc����;6�`D�� I��ڛ{�3-��t|u�z��=���ճ�\�9�W� ���������2\�z�,D��G@�Bw(:���5�>�m��1'�	�'��ְ����՜oZp�>S*�QĆQ36��7Q�;�y��	�<��Z��o��LA-(%|j7�l�^d=w��TF�i���\����+����R�R�&��D�<f�hQ �X2���>y�kc1t����L�A����;�J��	���23�Sr�H�,�D��89�w��"sd3+���o٥�#�G�=��u9�Z����2*�ή�����d:V�?56��{��i�]2�c=I��Ǽ�F�F�$[�K����%ŕ3q��3����3O%�̀�ޚ�����T�< ���4T�8a�R��x|h��nQ��0��"�W�5ř�Q�:C
\|d�S���FUn{*/�]�"�'�K���X9��3�����C���$Tc����YE����%�,�������~)q���o�o��^�f�"���D��6Q�,�5$2ŖH})L���ϬbԽ]���-��)M���n��T�A�FI�q�қ"��{�����I�w��h��{��c&��ђ���G
�=�#��(�z���J����l�7~^�K�:���q�;ظ�RQ���j-<
7q4�H�,`���i��mg*�c�_~)�H��@r�6���\��1ɼ<Y3� �$�!$���w�+w����ʮ�n]��>������	�]Oެc6��WBr����?]�!�/ރ���	���(�I�h�:�!3���1�3�>@�9p��8Xt-�{<�	����	���RW3�6�fI��|n��/��9��_e�9��MWv=\#�Y��,]�G5	E�o�í}�j��(S�VHFQ�D�G���)�F��͍���gv'p,g�.v�f����c@��z ��Fhь��Iw<-�1O�s^=��z��A@�CzQw����?�H]������)����|Ts�����jp	�or�ϡϑB9L��%x�c+Ld�]'�t�amY|4�Jbc� ��7k	��)��9���`RM��[��>PW��C������_�z��>)&U��E�b���#���Uo˾�&z^}�c,��3������?�;x>
���A��7�	?�e9f��_J�J~�o���]�5���Bw��%k�j��9�_b�:�>�Gb
<뙻��!
K��s+���W3���A���Ca���nݺ�U�$XM��=������yDZ	�5%1�U���4t�"��bk��P(��"s��2�*xr\���i�S�1��Z!z�+�`�:��E=(���-�v���Mrc�w�|�h>�a�D)���y8y9���#� ǫXu���eM���݉�Y��y�'�+xAk-��l��sg��r�*�������	$֜�Ν&o��߯5�Ɯ��h@�
���9����,�;�Q�/�8Ri�d�H��^�����S�q��j~��Ea�R����Ma�o�%K�,�YD�g�DV֕�2p�y��*P�2ɨu�V����a����!��@k~`?����%��{�����U���y�~N�Pѭ��9�rOtlsg���}�A~��Sn6H4��m���5�Yo5�ڍ��}��$��oWdI��˚/��'~�]
R���rJ�֝�*7�I,v{�0�)3�⮋�+Jf��>:z���^���\sj4NN��Y*/A��揰�J�+���}�F9)�4}�U���/��88c
�<�Ȕ \��zI���pa��/쳜��^���� G? ӟ�j��p����g8G+��Աd.2�Ta]%
�4[�(Kq��ُTFpa���
b��<ib�
���|X�=������j`K�W����]��������%n����k�����h�+@�P��<��w��}֨�H��&0�����^
��L��\��b$�z���ύ�'��^n�y�l��q��>�i��<'���}K/DU�D5�����1�{�/v'����o�d�N��h�۰�2~��$"�q��U�`��iG4��wQ�kk�9o>�ˀ�>��x�q�G��]`�����]ڴ�}�@EJ��%w-�!\c��O�t���)��~6��4�l�G���@C�Wj���-g�f��d��,���� H=`�l�>9j���՝y����6Z݌��L/[�+]^R�d�|WZG��G�?$��8�������La��jPI׆�+aݖ}Z��Cd*�����3��}�p����`Ү��ΌvzQ؊�U{mnQA�ß}�$��гG��%�S�n�ί����(K=�b,?�U�[4:H�D�EvN�����~�{�U�^����F��c�,K�]���U��o%�ij� |'mߣz�s���U	>��^Q �Ёm�~�`�E����g9=6�R��إ���A�\F:�y(
�h��2[.ך�Zh˻���J��(ch0��-��Bâ��OPyy6��,2����Y4<f��)�����f1ZKA�{o���ȷHS�g��̼�N���dW=Zse��r�O����>���T�H��,b�d��Q�wxG�wp[㛹�l���ߝ>X�7/$�2$o�1z�=֕��n1����l���8`U��s��AY�;�B������f��OL��!  |P7�̀W�تA��S�o�x���_�{�G�m�,�eb�\ց�[����H�`f�2j_�ֻT���:O�$�

��t��^�r���G�.n���?^藶൸��%v<3eb� x��>�0m@��F�aM�Z:4c��e�wLj9��K%�7J��Y�n�#�V�?��.�Y�N ���!�NfVb�[��|���o)�}�N��*o�6��>�M�r�x�v?� ��bH��)�U�J~dk�� <�	�JvHw>E?��(J��e&0�=�Mm�]���)?�X��k�oI�Ce�:b��W_=|��I��aT!U<��wݔ�+�R$�q�x���Ac�/"z��!.̀�P� ,����]fE\u��m^l�ݓz)2�}�G޻��M�)�oA�@ p��F?��޽����v!�NX���:ְ�5�i�9�u��l&����G�ik�c�$�K�����^l��� T���~�s�q#�a�>�񍗘B_|ܫ}���p$s�:�{=�ٳ��2C�\CdX��S>�BP������;���(A����Փ{����uf�|˱����{T��L������g��6��$f��a��(O�x�hI�B���� sAaJ�'��(�:��,�H�����'6�ű�S�}�xTr*�B���I�A9�Mq�{�.Y���/��:ᖦQ���i�j��Q��g]��O4ƍ�Z���;�Z��J�A"��a�U��4��<�|a�&����m����P�.�1�?�bz�����嗊|��a�/$e�����X��K՘UN��4�g;_V�" aT|�Yݩ"���Mߊ�,�X<�C
���o��b�t+���B��8RBő���x�n縁�����ᚸT�������*�%f�m�[��0���L:r�"��Q�K�>����?Mw����E#+j�:.��S���'�V1����m�4��"7�J���M�OI�	9�zH��Д�]y��\�����IFŮ��3�c�����_R���	��)��[|�!� �;D2��"�<�}y�e�C��n;|[[��KBlb��g�3������}�ɻ�N��:W_��}q����d1��N��q��[L�q����aO�����b�!��סp����Q}Ɔ8z ��^�~����rx��gj���q/
O����3(E)���H��)��s��-D̸�2Jk!"۰+����逄�2ؾ0�ULPDWa���Q������y�1���(܀� �����խ���4�VM-��6����r��r�<��u�y4�"e*�-�_��$��k��b�j������n�9�T���@K����B�a���t��V@��t)M��	������-̴3�F b�H��S��MOd��d���� f�����?n�>�Tm#��ӊ�3�췞2x�D�������Cy֫%��P�E�Q�R��&|K��T�GR���Is�����N]���r��a����dѨʂR%	d�x�+� !m8t�x��#C���c�>�z�&�iU� @�:h�8#l���}�y:�E�P�>�tR\[�dwʍ$>�ۿk$���*�$�8P�����Y�e5nz9OW��f���f���ړ�)t���)q��ĶK4������!,4�P�,����%!�� A\ �7)�.�p��b9g��J9��n�%�vcB
��J��A�d����\��0;Zj.�
��1p	3�W�=㣴<�Hʝ*�餢8�e3�VZ)4�-,�� ��H���x��~��K����o��)��S|���&�Cq�I�� Ff�C��"�u����l;��/�Oof�4Y#��y_9�:s�o��f`o{�`�g1n��j��G�6������+5=2c��0���J�@�����of�a6��AV�ѣ7�G��@�҈t�^(ye(���tl�IO�'o��D����J�qm�z,��&���J�B�Gv&rKfH�a#���kz��'U��Q��7>�����3]�T3����U�ĤsQ�����v|��eāC������K��C-Λ�~q��Y�;���+�Ƕ� U.;�]����M��ч���xq���&=t��~-�۬���&��p��$)��I)�"~�&'��;��*�|p&�0��x�e�7��D�&�z{�$��{w/"ʭn�"]?U�j1�c2��|�� �;ed��ݔ��V��8,�9��Ϧ�0K�.%q�U�d��2�pQz�����;�9�҃R�����U��U�s��%�X��	/�o�[��� �V�iУ���F��ݞv�u�i�RA�y��g�9lb�:N���vL�6F"���+2�.E��Y0{%v��9�v��ˏu�'F1NNs@���O�RV��Ѡ�H'��,�G��z�P^�u��KGȫ�	�m2��F`I8�	����;]����l�I;���ր 0��x��Si�\PҨ��10�	F�@���u��!m��hXwm��.�4�^��|�+�q彪V��l֙�_����(�]
�"kt�嗬Lʍ�0<T�
�a|�������8�5��?�	��"@Eډ�f�2m�?,@pqP;O�Z@K@bR��C5VJ,��N<Z4,�y�6K:|������>�d�kPtS�zs�@B%ܚ]��|����I\���mK[�)C�Du��^-�6�
P|&Q��l���P:���C����|5��]{<��[�&��B���	���\�a�σ�;}�Yk}��6�󬖿�y"pZ ��bp��!����p�7�c��k}u��=��UK���,���aQ\��c�w����vT�O��ߊ��K�4^C�����\�SV��^�g��m�e��өG-r�A2�� �S�(0m�gc�%�Rr�%�C����o`NP�r/pMx��! ,��'ņ���Ě}�(���l�N��L�������P���u
�����w��[�k������n@[vC���qki�����	�`٤�d�b-�.T�ܝC뫀��*u���ʭ���̀A�s�`�e�C)�v�
��Jґ����^9.D6���8[2����UV3n�d
�Crc�@��N�M)�Y�v[3ַ� �kE� q�X��&4D�ƨU_8�Bу��E�<s<���o9ց�A˷2�||�U�ܴw ����pK��C�L-a-
-�I��Ÿ��Aӷ9w'�/(p'����:9��Qz�D�a��Lţ�WU���oe=E�55��������y���h���`��l��`*�;	ҿ%�����A&9-݌�@��7+@ci݋�X���y	�t����N�EW�����,jy�K����n���j�n)��J#��+��5��r+�y�����\	{3�`����r��q�GT�@�q�\�)�� ���	=�?�[�:�F�7�~:�ѭ�D ({I�X>#Qr.���Z�@&��8]��<r��11?��V%�$�+�L5�3�W�ԇ����آ=֡G���$Ąc0�A������ZŽU��<,&b��bAH����G��L�ak|���P��&��U��_톋V��c��u60�0Sgi{n.f^��:fOw[�G�����&�b��&nD
�к��s�����j�"A��,��lG&��A>���
mg�,J>`m����m�:'.�/�b�0[����S抖���!���"��ʕ�G&'��@[��t����d���H��Zhr�;�C�?zQ`��	?�&�����']�^�dwsEZ0�l�ߠ}�-�� 
 ����`8Ү���_���t*�B�6��E��UT>�OG㭚��� h�dSk���ќ�Z�Im���t��3��7}�h�n������[�ݒ�@N#����!Ȼ��C���7��	"���=���ü���&�OD�e�f�?[=�&�"�L?7��W���ݸ��6/tW��XKFLu�WFV�/�H����Qc����T�I}�{�3C�졂 �AEkY��2����@�lO=.ǫ�^�,����l�ZV!�X���Ҵ<r���Xd�ju�G;r��b(��iQ MN��]]r G�Λ����O���9��+���*aq����t3Y&�h/v:�TL&����cb\�'�i��0j�OK��|S�=n��ǔ&b]Az�K��{�{E\L���j.��K���,p��J��*J_z�|b8��uAڟ˨�7��"/F���Q�G�%�r�ІNo:ī�t��֛N�7Ld�>c�<=�iE,'R�P�F6�߂_6e��^i��!�:L���:��B @Ic�j�@W,T>�n$T,MmX��E�0q�����`�뮙�
z�ňy2Q.����&�f�\t��;H��i��w�ⱘ�-�.�q��պlY���^k��P�?:Rm�����p�+�ܝ��D:���ʂ��*���Gy��}�f�L_��/uyHΒ^�B.&U����AX,�7Kޱ��F�PaK�/~أ|i��d�3���\���{⑒���1��&��Ÿ�"����<�[���[1�Y0�W]�$+����V_Q� K�"Xp^O]s� b4Ĭݑ��n\8�JJ�	4j�� �'[ %}:I�����3����b�y~Bo	���U�5��C/�C;'ak���r�-��9xVb��6B�a��� V�r��]�cѩ'm��F0��(�棪m��	���3�%�n+��-� �;���
w��u~t�x��Ё����hэv�&G�n�כ�q�ѱ:�I�cJ�`����F7��A]�j�1�*�{�8^��t;�qo`߆�xJ��5��3�#Ȣ�U��/\XG�,c���<5����x*�r�P0��b�&!'|U�����Ň'�H�Ύ�:b�zYW���U�-�
Q4�4�k ��w���='�T��m�g�u�̩i��3��(Dul��x�Ь9␢�d�u��cڷ�>�\]>°���s�V0�c�q;��!� l�*���-���$���:��R7��a�0[D������
NiΩ$8PN�Wr_�AfTñ�u����еfg�6E�7�=��2���� �Є�0v�K�$�P$���Q���+�Ah�?~��!�%(��(�	���v{�)�����4�`j���C�#R��N��J!8M3�ybc,g
�e��*f�5��>Ə�"�D�_B[��$.m��g�C��Q5��l7���� �����o*I���T��&��J������4xzt��O�E���e6Y�O����]��PJ�=ol�ؕT�a}�=�Rfu��@k*]�^�?*0o���Sޗ��B|Ƈ�����I�Fd����	�gp���ʞ�=Sמ%&�
�,pԅ��/\�}�K6�<���7Z��� ,Tz��3�ƛ��m��I5+�Q�E/�:X`�/c���F݊���K_��s=ak���&��;�x��������)��hV���?1˥7.J���Zd�.)� ��2Щ/Ь�"}X�ӄ�[��Q0>\z9𖳵��}q5���R�mF���:H`��c��=��^<�QF��xk#�qc�5*��0�wwhi�TK���:����~��s�Qz��r�����Yd▽�I?��&�'K���=~�b�-%��aڔnh��	I�m.E����ᗠuc0?3�ȖX�
��������M��(*Q ��ya&�i��G+WE������
��o�����{$[�\�he��y���zW��z��6���Pے��n��оQ���k�L���$|��� =�}�|�h^p^�޵{wIJN��5YGq�T�_P���4�,5o4L�͸��1`�=�t�g^B(����AL4���k�N�Ǽ(]�#A�zF'�
z��(�'��D-
;͞A6ڜZ/Fg9V��������UAcb��F͵8?�c�:���A"�c:�δ��2��pyo�r�s�|�k�U�F�@Q�oV��)��z����\j�ǬG��:�N�,}1ƴHĮ�m_%�n��@P�^�t�ɂa>�)�D�` '��ƍ��>͇APH���B���!�{y"\N�Dӳ�i��J4*��,`����5�Cih��(k������a�����3ɤL	$�3a��E]��Bx��������H���������<r��h��a9.�.������o�ȡX��\�6��U"�}$B)2\3>H�?T�Km~Bϐ�t~����Z�f�Q��o�.�����Mf	+�LК^<���nb��=6F�u�O��N��|R}�t�O�x�"��ޑ��Om��o��EU�軫A-������vC�S|�u�;��4���i̩8T3|@�PԂ]��>^���H�(�韲�:V	�Ɏ������q��v������C,f\�k��H��o�|�M�I�n�����d��>9��	�	Ɂp"$q���o �6�6)-��������Ŵ��%��f��Y�Ҋ��ų��i[�eO
�4λs�
�AN��� �Yg�TJ���T���ר�*Gg�M�ɀ+�n3UDg7���&t;2���4̈́�}�L�!UǛ�vy���ee�B��X��,�@������8/��vK�>��NJf��|��r��ʟ�z�p�_�︊ �A���wM���v-B�[�\+��=%v�O7�
�N�B���e�&��IX,i<�Ø����S�ϙî��*��L�XUӽ�²f���+as��8-S��o7YP�iEY�S8[�=!{d�q��K�$����>�g�Y�cw��:����f���X�a��F!��[ƶ�Op��+�֖b���� #���<��x^��9��q^=����Q����b������Hs6R�Z�i'M'���a�,�̑��_X���J����׺nmQ$���[a���1)Gz��(Ҩl�� ��݌�w�A`�x�5��j윹2�&�ܥ��O#��̧���5����߬I���D�`���ߏ�Ȉ��� ��h�A�$��4�	��YI*g<���8�����]�R���<����%����ʆ����+=��_|͝�a4��k?Z�����8Y�����v1����Xr�t�o�i���P�����儥F��eץ�vh��bd�����u/4�r��O�$ܠD��>o\D�e�C��4$�A����u��wP_`���fg�N�WXC��ao�{� �/�%J9�*�	{�z�|�kVi�A��k�����³`_]Y��j���ɭ}���5�!ۛ)R��i�Ҩ[��@&�lt��#q CaZ�J��#����b@u?ub�ײ�1^�8۶��+��5p�[���
I�6%��ݑ�m�VЪ����A��.Ċ���­�N�����$x�b
V�=���6W{HC�ο*{O7Y8".��^'1sK7X@�����n��38�x���b����_Fw(|<C`�@����Ib��gn쟵V΂/A�������_��LZ�P�s!�gh�w��.��o�s�k!��)!/vF�)��v��<fy��j��\,$9f��%���sn�Jez���U8�"�^9����1�H!UW�r�Wv��l1x�i���גR���o�+P�ǎ�,�/�c9��;<�ӎ�RV�L~�����4x*��
����LM�ssd�9J��.��xS�Cin!���D�S�������4X�jxL����'{�2VP~�Qn��^�'C�4�bʓ�� S�#�u��2�������N���2A�{�8�n�5�d�n�8��cn2Jw�!��x&EeO�/na��\��4�IR���5��=��l
�=��#H˔����r~��O�gR|�T�9^�:�{w*|w�;��ڼ���J6���'�w=�U��/����bwYn���L�D�&��vd����آ�HLX�K����Yr�����p�����9�vqDJ��Ym-�D��Ön�������QI�zA�3@3(����;���}P�"��-��j���{����ѕъ�^����RC��)���vy��gޏ�$��+��c�t��-H��j-����Co4׈��/i�/\�Q8l��`垫5��*^�f�I�q^��0����E�N� q��u�`f�s�>����>lw���ġ>e��7���>uP�Z,'F�I|DG��� ���iѮ��d�ր�`NS�.��N���_[����I�1ا�\�\2ےC��]#M�^϶�Y,(�w��h�q/ߍD���w5�?��G�X�aD��t��!N��kj�F|'U�L�0�2��C����0߬b��
J��%+� �E�TB%�>/��c�%W����	4��^�U[�uUo�nS�H4�d�5�V<����\���0�(�9��~�g�nr^��SG�� eS��$k�#=�A��3n�Q,�BBu�>���kП�u����a�ReNyoE��u�Pe�2��:ye�8��_�_ ,�2%N2�����7p7���a �8��g9{��	m�試=�K�dt���YEP�)P��::��k0��zB���_�Z�y�K�|�_@s�j���LcX��S������uNuo���D/���{�
<��� I��>�d�f@he�Ұ�JuU�-2�H�P֖]����4���.�fg�]�Z�̳���}��2���^��c����Y1.X��L��U>���r'j��e��<�%��h�d�V({D�@<0
�);��0�/kt���o��0_�7`L�^� �U#�K/���)�b��o���L�S:v�&�������7�xg���+�c�zd�0��˟K%�˖�����a��`Y݌'�5u�av�C���nx{X�l��Y|�g6ꖶ���l�|7�����vXkW�}��@������d�n/���Ļ�ߔ����=� {	,   � ��#�m �����+�߱�g�    YZ