#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1095628638"
MD5="9850975466dc7c40a10b5686fad49b34"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22920"
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
	echo Date of packaging: Tue Jul 27 04:28:11 -03 2021
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
�7zXZ  �ִF !   �X���YG] �}��1Dd]����P�t�Fв�@�/����y\c�^ID�oϘeH�Jn�jj]��s�,�d��ԁm����xK���U����
H�1~��SYl��Y;uҦM��D������a#E��_�8�vZB�-#-1�Ci>� Y���0��}I�A$\U0�G��=�a#��{͆��s��d�qP�$���q�����wF�_BV��|�lC��3�c�
�=܃�E$3�x�O��b��ٹZ{[8l�d���V@�<���7c)z��Yj�Cւ�����)u�)�.\|C�n?��.򼼈0j�T���g�:��b"����]�e��Tt��V[�O��0S�Y' ��4���%-�$��p.�7;������N���w"�l�]<Y��Z�=\����u�'����S2�Qj�(p�GC<=�{|�NlM;�) �f��ۆ��E ����4�6O�O������XMYJ)��^��A�8�>�R��8Ɯ���6{1�*��49�͖�"��Դ^�#���s�{e--0��kBV@zl�a�ʜU���2�s� ���?��wBa�a�
m��e����mGK�:g?���~�(ږ���X�cM��%$�D�F��}��z�aV���f�����b���{���}�edC�\��[�v��"
���s�ݷ3��,_�~`	<�P7K{^�g�C�������������k��� k�J\�����!2وt�b��x� ���(9v����u�q�W��y��c�Q��^�t̢�a8,��g��LP4$�g΀�*��}�) �c^�)YD>WNugXֳ��[�O�������ثU�:��{Y=���e�.�2dȝ<&�	X����T�����BS�ޟ��ʮ�����?Ef'+��M��7͢�,$;��6�zA��qdI4&z�
����R@*5��P.}"��E���1ŸX�_Nb;�f3�r����f�� �	K�ǽ\�-qN��%3o�t�S�\x_�Σa��֓'�A���LI	lJ�I�C:8��k��u�x>l��h��KU�S?>��c�i�K��)����X��1�0�L�3�����ݟUE�b.]L|p �vA9�D�¹�,vou��-g�N���X�FiJC�b���{|�� :���B/;3qV=�4��5���"�j01�l��M��ӷ�w@׻m���3����[���HЈ���*����JT8oe.xM\{9$j�� 1� �U�<>�C�jr�m4����2�~E�e+N&��Kz�'PeU�}/8�7l	7eh�D�D#�=���w�O�j/ӑa��z�&�oL�UC9���f�d��TY��߀��ғ�c��M������Ӄ唝\���^�S�;/��u��i/u��	�!>2���HS���g} �wN���ȫ����З���*�,�]�$.t���p}HVF!��!V�Z���+(�3��h)����W��bN���N`�]ں���/��ĥ�(;����{����%�� l��P�����}��P�ܤ,݅ߙ�w��	R7��k��7���l ����س�9U%�={a�ۘ-k^�1���ܩyx�TU���"9�Y`�HS��5��fO`\ԕԊ I�f��6ec۰:qtL�񨎌�E���-���O�y�c�"�����S{�Я�l�������I��*���,���nKC^�}�F�K�|�W2��Z�e.����{�ZyKXp�G:�-�Ǹ%~���Y��-q�N�u�P�A9��?UC�uu�����JGF�y�rd �o7 �H�F� �uH�Ɔ �?�ɪE�,�^GI��V'�3���.g���.
���>����Xu-P���Ȃ��V]e�L{ʒ�;�?�x5b~D�o�IO�u����jf����}�t��o� ���,���!̺ܦ��L�W-��!�v�KHc���3s�r�A�� ���}I+���N�;�����)���o�$����"�eA��d<WБ��O��6�P�HX���W;��2J 6�������-��{`�� �K6B�AԾ�͂��K�,w���p���Q�";ju�y��#ˠ,�x�5�����8�b4Α~n���`ЏˌԴnA͜�L�:v�q]v�����t�O��z���<�ɥg12!A�>��Y�yz��8�K���Zv��Q�X�ۧ��1�(�1��g%oַ�j��ER�TW0ܮ!l��mIM���h�o����f���o�D:�6�=3�	n�$�%e�g>�;8��N�6t���M ��H)�q����N��)�Dk��)�m&\��M���|�.s��$��3p�G-�9g�,�P�p�����G�<Q*�����prQ�>^~����knk0�	�}��h�o��V8����0b��3Kni��_���oF��d[�f�5/g�):���*�Q*XKQ��_gH�h�Z���~����+�	t2W�/�3�����Zg
��[O��Z��c�J����,�6�?�w5v52�n�z bY>���Q���/���������2��~��@®���Y��f��)��JM!���_���A���þ�^T�M�<!��Ɨ�L�UCڍ@OP��.�����sE�� ����]n4iW����V��������.��y9�F�'kU��C���\�>�v6�E���4�38/��:Q�U�U5���F�q�ʧu �i�>�U\��sr���'hV���K�z�)i&g Ccg�-�7l�2�L�#�ߙ�.�t"�ׂ V�*|�V�`Y��h_y��9x�9 #~̌�즩�s�����g���]#�����rt���9��'�D�c�I׃�Ƣ� ��ǣ'��F��Xl�o�t�^����hfR�e�B�w�>�Z�%%��
&�!�V��ǔ���H�_��'�X���\I�MrQvV�O�M�����ɢP;��H��ёD##�r��S�W��w�S�L�v��rC�R,I������=�>�t��<��>P�8r����ݳ���!Ě{M�T-rg ��`��0���y6�����@߄z��^�&�/S�"�2��ȑ�m�M�^@��o/A4i�חK|��Q���S���8o�J��z�l��vW(�*X�%���I�?hM.ls�<�^�+�*c dOTE�}I��F��4������ 9���"B�fuBi�R��Ͽ�Rh)�X蚦��?z\��v׻�%��&4`����Qa���9
K�2rTFxk�ih�#�hVU�Sa����RS$��L�K���KS^�	��S<`��p?�<*����a��l���냇UW����ۥ�ǀ�A�B�+��K�Lk�M��-�#������� �$Z�P�,4�9lY��}?��"y��MAm�j.,�
bF�F���VA��v���� L���8���Z��T�O�M����=-!
x4���!����.J\�U���}�i)��H�D�"Jz�o{G�@�]�>�5N]MD}��DÒ�h̝�����q3��x�q�7�K�F��E<W�p��t�bRNX~a{�m.��;���GJ��f>9�#�*47r���b����М:�$�Z�*�A��(SoF�-��)���.�����M�Xߝ�=N
;L�v���Zkv�����0Ea"��P{���u.��`�XvB�����|�����춭6AN�Q����ޘ���g�p%+���N/|�j�'>,:�u�@n�wU�g;2������3g�X����T.:�/kUv�������{.�T����"�nԝl$��������6�q��3�����?��+Y�j<�	�L�C1j,����\n��(��#��	�����d��k���-D`X׈U����9�j5V<���S���{�6�A��:^��k�W�&�
� Z|�DB�j7J3�?&�d�+D&Pɗ%yGޛkyj��F|&|����V�!2^��s0�V��/X���殒����^�2`E��8�y��*=�@;Ő�3�Y�3�偤w�����Y��K<)����s�\��&�j�|�ʓh���/}�m�P9G�^��I� q�\�G�$������r��~��M�M�f�MۦbE�J9{���]�'��s�}�[�������V-tFLB���o��������H�&vvm�".A��P��I�g� %�e����W&���������^�H�t�j�f��� /�`��zb��.�T�aE�K��v�$�e(���O�'xi��>#�w ���@��}E^�l�O��+Y�c��<�6ϛ�Q?�
��V��e��r<�%�ep���6]V������ LK�?'��9Ԇ�&����i6A�(o+�)emvMBک��Z���� ����O�Q�ɮ��)������(�(f�JW�n@��iޟ�<���z>�[�4XCQ3�A7�`�c�(-� F�C�㸚�(:����E8���`[I�a�}�sv��*] ���%�1O�?(���x(�P�hؤ6��Б��D��0k���@��O�I�����	
�YN���8��`�s�������#���.�5\��N�C�f�~�M�ۣlܢc|!Uf<54��RTp�bR����f|<o�|L]��Mް@�֤'�MD��i��nG�nji1e��0! ��k��EF����m�`����#�pTA�|HTtc��/�E(��Yy0O|�M���X�s����;ďQD�^M �uS,�������Z�T"�lA��ufg�B��q��YQ�se�N������Ѐ�V9Y+vQx$I@�g�men�X��[������*�4�����i��wXЊ[�'��ГD>�I�)�6q�D���~��ߗ0���/�7����pV�o��O+�a��(�:�Yyx\�}(K�s�OЇ����<��>"�j�k��
�K��1`Z�Y	���]ծ
��7ѽ��>S��f��՗i��xѦ�鷜�c��1lwR_����uv�y`�"��'/{Dp��d���;_�zla��7����.h�j��>����uݩ�7.�ZR	�Tq�2φ�Gn!�� ��ۻ� 6!�w�o7'���w�����ReU�����}�7{�=1RU�Nzh�HaG��pq����(ͪ�h������!�����G��������c��zbI��g��ȨѰ��A��#vVW>B��*�1�{֘-���3+�ѻ���|�BT���b��u�ֆڋ��{�k����g2���ӓ�H�DH/)|�B��N�$����Ix���@�\v��5E�;h��a�H? ���Q}>�i}8=8�H�Ӯ=Ǝ��3����|���T�m�.��x����V׼"	.�������Jኇ�&��^�#�u�$N���0YyK����au'�=*�D�Ɂ�J9��gK
���k]�2?�9$6\	��剅�g
-�O"��?bI�B�N�o��m�+�
�17�D<�[צX�n鰐�����$W�47��+(�;�]Fx���,��aY��5�*�g��g�V��+,���u����	/ؕ�y���B`�)0�H.�M�zk��(d�pQ�+Ȩ����zNl(T�*�}0�׊]�����'D+���ZhW}���0!v@����j��g;Hp�����o+�,��1(�J�qX=�?�hVի�oU�!ӅYd��;W�4����h�2`�Z[�E��s�A���$��; ��|a�~Ԛ����)�n7��ɮ��j�P��1��4cl�*����X�b��ǂ�wah�#��@�$��Cؐ����^=��!��ux߆�0!� {�����&���9����:"݆�V����� ~�/���m2�6���g��hp���<����|t�<r�a�|c��7r��P�!)��ܬ`9�y�D��P��	#���p�z��b�+-@����s�������?
����ZW�mU&rM�ҙ�M,� �cK���d����)�i�� �P�f�9�{c�~��cL��_20}��p����T��'��
`�U�cP*�U�uU�)_�ޥO��=�����̃5�m^��Cr]+��h�WZt�أò��_s���P�ɢ�.����pK��Q��`�v�#�鷳7�	��Tv�����E[x�/'�>%����=}(�6�f��{ D����QIz4̡���yo��O:%rSe�na�ۇǵI����G�_s
�����@�+��)u�I�qH�e�p����/#s��om!o�m:p[4�$?t.Q����x�y�p?��Ia��f�}�� ~Spizs�ಬ<̐0")��_����\;唕�{M�+�s�]�Ӊ+9]u��z���Y��Ե�����4��K:f�s� !�.�Jj$�����1%�ߣ}�Wf�F<샘� 'ס��Хp�0����ŮRLSs�(2�9ŝ'�>�I!Ѱ���9�gf�5�� 	�P�:�fŶ+=]�"��2Q��LFM�bHtW 	��W�G?a�6\�t�\�4!<ƚ
'�`J��Z.1Bl��toqM�Hb>�(s����e��^��["<�s6S�Ґ���=2���r�8%�Yl�l�^���|��d���ȊHʡc�=�Z��G���[,��b�o��Es�t��Ƚc���.l���%RB�r�-h���ŵ���&�hY�E�W+�6���>&h�tz�*R�?�r76{v����MV���
H���I&
w���Sp�8Fc���)*e����#?��^d1�ڧ�/�����jyT֌�8I�B����OG6 %{�hEX�v<�{}lGZ�1���^�9=�n���8+��kO�2�㊉�
�+��*t�����mF��� ��^��Yh(��0�x�+V+k�2��=�_C+���Z����ܓ;CvLs*3��݁dG��Q���Pb�4SE�=��,�]SI�}��À*Y6m{l��i7<V�o��ӻƴ�1�f��N����>��Um��Æ��2�bX䩏���e#׸���x�L�}��uR��{q�#��W8�yG�U/�)�7X�]`�`m=���dY��W�y�珔��Q/�q%*��%ӳq�ņ`�Q�Q�8����Q	�z��Ȅ��oP�'�L�1uh^���9ʔ��r�Cb���3���^p��?D�����1d W.y��>���u���0���R�C�="A�B?Bn����&����"S6��+�4Q7�a7�U�W����
����B��(E�O2���=�MW	�ѓb-�p�-�1߼Qu�b (��@I�06F�J�ujf�n���rJ_��-��^�gұ��1U��]��~w�����y�I��nC��Z��ڨ��bq�Ͻ)O}�_SL[�$�d�l�W�U�0��Ʃ��F����6��\�V��ME�Y _��6��i��H{_�L7�W�ȋ���QśB�n>�m���9v����()m��Zq\�����uII�/�������Oo2T͋�����v��\4�ۧ]�tC��>b� O~�Nq�h�]�EݗEL,!n���q'hEQ��5֍��aVC���e���}����_d�F�ᴖʉ]�z����>��P�΄�|Pf�r^�X��Ḿ�p�L�1�v+Y�uZ�GƝ$'�����H����?�]��\� Mጧ[���`��c�\�z�a��B��t�B�f r�\Pg_	��w"�Ś�B����U�c%��P����^��4�EjGn�Wp?­�)G^���s�E���� �m<�m^�̚����D��eK}De'|ā�� DM�"��&�^G>x�I�ޠ`�7>�(|l���D�ky�ń+���ᅛF~��.�q��'�������쌟17ݡ.��}�	� P{R�����n���-�u?ze0�^я �]?f�!W�!b
l*�C��D!7>�2>�0�c./���H����a`�=���/�d�>��f=@sy�(���?)�^T�$/{�C{.����U�8�
:#��ߕ���Ƿ	8\����rc\�TT^?<m3UnMp��gR���d�C�W�@bY([KYh^�3X�_��T��k�_=ѫooN"�LN!ȼC�p0v����&������oaH��L@���5�좢V�{�M���Mr��Z���'4�����3^꫈�uq���|�LȎ��z錽Oԙ�6"E���^vj�����Fq�3�-k���G��w?*�=8W3��S�����]���Am��$?S�}�su` ��f�j��&���,�]-�(�G�>"������q���ݯ{F4;ۚ'��Ά�Ar��̢���a�Ai�y���"7`���D��Ic���̓���S@�ɳ�e|M�Ḍy%o�ܴK4 R��j)��I�@9�F��])�f�#�G�]Z� �N��X`�_���k����u�J(�zh�B�=��O�� F\$"�6�eɆ7�a�ج����k�F�R�RD'n'	lCy�-�*�Ĵ�4[��� H� <A���t��&";�GA�)K{=�^�.�CKU}�pķ�i����4�\9�oF���=��^�!q��s!H��L?�_�u�ѻmo('nv+�6���1��G�LoqƕgV@y��{3il����jҧ��=e:
�H��)6�\}��pk��#N�;�|?	݅o���ҾVfZ���"i�F|A�A�D�}��d���0DkW5�ӏ�+>��*FP}L�L5��e�۲���},S���7�s�Mbc,�=�'��5���"Bx�t���6c��)���p��a�5��J��J��$��ƍ$Rh�<�aJ)��?�m��K��G�^stn�^K%�z�1Z���F_G(�J; T�s��@g�>e�@�V�p�>wx�#!k�0�{�[g�G1�Π�!iO�)ɐ��m<b�:/}Yp�v�.��ˆW�ӭ����o5�Q�QhR����A,�}�n���*�抺�=,~���ޢ�.V��a��#;������);�U�# �eq;Ղ�`YTlI"�pU<�Lt���R��묙� 0G���M�=����
����Հ�L�m��b�ڮx>�+6���pz�5L�*��6�eAd�9��-m��.�?O���2�(R�M|�_6y��&���O�~�D�gi.N��Le���s�pJ{]�(��[pk��[D��i�%�~�����9`�*ʜZ���k�Gz�ۢ��i�i���t��撾٭~K�y�+]���+dl�U�ӝ�z�3\�T�Օ��'d�f1��'}*�k}c�
Pm"#d1���j��U�%��H�t��QAۀ���k�L��Fv��E��p$����rH% ;k�����o��/կ��2��ZhW��@�p:!n��s���s�[���Vs �G�gj撎�I�o�o�
�2�T�^b�|;M��$~��y�\��fU�Q�c��]c?s����õ�:	���nNr��؊l��) �~+�&��2Ԋ��B!ݚC�{ٳ�vh���9�U��Q:=�r������퉝o�WV�;��ŧ�: ]$:���e2%�1(?�#�r�4����%�K̉D��sP�T9��m��y�I����ɌH�x����]>��h��O�k�)ȹ�gd:�)Q��aIv�l4����{���`�[SsA񠖙�����޾SA���	8e�����ê�x�8�X�& 7�%V���<!�	�w�$j�Q��c{{u���8�.����J��E����pO7e&	b�r�a��ό\fϻ������YBq2���F۾����W�<A�+"$���cy�p.fy�|4P�77@-�����w��Z�k�w>���W���7W�hv�QA\)�s�X��+��)ޟ��Oa��Yik�`*xD�#�KSlW��/�K��O��FuرW1�~Kϧ�T��@��]�۴p���&�%1����4$�h�o8�8:�~��t���T�Vj��������*�g�a*<w[9�:di�F��Q�G��A��F��R�?�P��ի^$|L�`��VL�'l�L�F-�����@�BW�<��M�k	b����/�|����त#�e[���n�������rE���b����(�v,Lُ��Q�L�w|�$��s�/�%dǌ]��V$څ0@�eRɫ�ڂL����<k�w���D�L�~͕2�z�SȬ�̵їj� '8��]2펳4��}��RR��3��F!~�&��f<�ڋ0��q~�}?`2D�)�s�4C�R�m �A6 �&FH�C��X^e��Z}�(-]�~�O|���$����R�R�E��md	��U�xu��c3�=�5��Ͻ� ��/K�Z��x�\>�ho4���-d>�
A�^��fa�`���c<�}�+�H�o��0�{�(�b�2s��"��/9zK��pup
�S�L�	1����'����Ýw���s�O���_�@�p#Ct�,�$%���֊m%_H��]V��J5e�jG�_"'�H�d��Ep@�T�DD4��P��}��c��?�����%J���
�dߜ�q��JƄm��=7�2����Gv܌�l���{z���N���U`�
�A�qA��p>;K�	�8�)�*�8ݪ������Ȱ�\�T�h�rT�މ���~t��d{�qT�z�a�E��[,��yk)�u���S���D��O�׺����3z�5pm��GN�!��F�p�׺�B�i6Զ��x	�LE"5����u3�?���S�흘�Y��W>���-�S��I�0+��3F��*cVm� ܡ�Y���~�������tQ�Jp�?�h���N�������u �w�f���[���Xa# Q1��j�"��w��tj�k�x�QJ4�fh��ҝ���Y���i?���0�W����k����H6c��c�}���������@���:YMT=A8..�����ܳd�n'�X��bҶNX��$s�ޑ��B�hT{t�J�׆t��P��6n�.X$�H�[Cկ�2�&Z⣪�%;
L�h�����J�][I�ǵ�\����RO� ��7[6�v�RNK�V(&1��'/K<�/�oEA' ��@CyA�w���G5�:���^@�5 �ٌW��9t��s�W���N���S�����(,i@K�&�+��tܟ�j@6�x7 t��t*�ov�I��)R���9��lO"R$i,����J�Z��yNA�&�fj�:,�?$�V��"��O?�m� ��C�T�̠'���5�Rk��6���f{E7m~�*�ɰ��4�'�56j+��9ig�J�'o^��2����޹������O��7m �Pyim	`3y���
?���[l�ƚ:�+?�)ʀ�`����
Ȃ<�t<n� Cڕ��Hto��tq�h���#�x"(ň��=��?9_a02@kg! plM+�ߚq�@��c~�{7�������oN�u[�1(uZ}�F�	P�\��$�
K&�'g��ZZt�zI�����|'k�U0Z�-,�j�=���������p�cK����9�svۍM�C���!~����.��G�����}��\�c�H/��8�� ����KE����!7Α�wi�ɲ)��B&&�ҭ��#�K�&��N��2�^o�j{]��D��c�9�"�bu����������Z�(��-9lWM*����	�~ހ��%xL8aF0 ��!=�y����J'mq1�"z�	6�K#�K�eu㼈1�_��^���]lS� _�	��e��(�VM�h���'����b����AE8u:<�ix	�Y�&��;#/��>��P	ٴ����0��,��O����uX�/���vN�k� %��Vn�0J� !���4�"�U���Y=����K�T'����̅p?_BT����E��ǡ�2���Q :]�����
�:ۥ�G�-�!1���W}�5R��b��ѶͰ�[Ƈ�Fy�$"�'L�90/MS���������W�{g�&�A43N�L߇|xl{4�ɸ���q��,�h����t�G�ףK��+�@����L����'����A�C�Q�h$��a ?^�����gj�~�H9Z�����wZ�s�/mQ��{�����V�<��6A���|���.�YĠ念�OiV̭��d�"]\Q6�+x����1I]�W�s-���v�.f].��!V3��c�ȅ��X��0h,��'<�v|�ܢZ�/���gY�J>_e%{JF#c�fߕ�"(�(� ��.4��r�hU/����rG1�I9kcwZc��#�S��EL.]��&��������Gv�w�z"vW|F��"�xt�"��fU|��:�>Ɇ*V���;-�� ч���0ڴ�L|�EguM`��f X5���R��^�����؆��yo�ﳾ��)"��ҍ�T#�\P�=T�#KE��ym�\f�,�f���-H�ݢ����u
�r&���/�e"9���繚VK��&�+���#]T �f�AU�-P-�;s�(����@P���eL�f7�R	�ڜ5����薧�kk����@��Z�T������Q��*�qk�֟�A|z�P!_�C����,^�ƣ�9f���}���p����^�HS�:�4�$$a�'�e[��`�:0����t����5�"`�/��+y���1 �N��V#4�vaLfC�k�D��c}�Lhk��x9[���1z����B�.H�<x\�u*�B��	�Ԅ�li�-�	*�r+-������[K�� ����l��.��H��6�k��]-C=��
5AO9>JQdA��t��Z9���|Pݷxt��tr��
Ω���?"	G�%R��/�G#P��7���e�V�(��U�~@���Yܲw�]�,����|�;y����3�����5���B'�+�v�\����%�=ގ�,�mZ(�/��K�t¡%ɻF�8I��݌�;�!��U��SH�$�bF�vh�}E)T<����!��.`�:���+��235�4Z'�{Z�a L�윿�9�Ǝ�+sQ����1 լ"��<lbt����;�X�L��5��_�C�?�!�C�T/H2��}����ߊ�D��?Uy�Lj�TU���/��6������hr�w��A�4��lJ��fi[_a >��4��<@�oS�=k�D��j�]$W��]��>=��9�m�Zbss��P&e�+m|S(XO����ɵ r�Wn�	H��Z�,�K����Q��t܈^J����NG�Y�3]t��/H�"��!Q�-rF$ϐ�e�Y�n:��UX��/��y��0D��2��ӻ"C��%<�ʭ�B=�}��*=xP�uu��|�{��]�8��N�UQ跆���s$o ��W������HL�[�T�]�W�.h�o�b�W�u�/5�@������h`��갅PO}��c��瑚�V�$�A*�C�=\W|M}1k��38���o�T��^��-mMV�i����6�b~�Ђ�4�~��`�T� ��J�jcYq����E��Sj��˧}aCie���a������j��ل ���A'A9�-`����v�B��JE��K���Ċ��l��c���������D���"Sd>V�h�⋰�oq��.F��8����������[�!Xj57�K�-��)8`�b��ѹ�."���P�ȔJ;7�	����L�Kk�g�x;�� 
^AM`~Vk��@T�j��6�7-Jg_pV�g�BΪ$�v����*�&R�NWL%�S3p~X���Fm|=�Y�}��7�y޷�ƽ�6�����
�)��Вi��3K�7���8ڝ(!�(��c�-��ջШ��">}���_}[��X�Un�z\
X�J��jN[������ʙA,l�\j�\ˇ��nɎ�lUS�vx�n�S]�b/�joI�ҥ*�炐^�Ѫ�
��dѫ2tkH*��>7Ey8��C�|qz~)H�R���"@��)��S�N~o��k���84�����&��D��>ziM*Z
���
.��@Q3��qҡc�Ω�tó�N�
��ǥ�����)W^.p����[�2�J��lŠ�e�`iS� PIJ�0�f1J������!�$��"�)리��qIE��+�#X���вڑ�߃~�*1������q�~"gh1���z�B,�e$�8�������*���x1�5� _[�'Ju��ʪ~�yN�ǰE*�K��O�- R閉�J�3�M�{,6S@�����Mr*�'����
�izW#��{�խ� ��gju6Zg�u���|`&�3{�>%~�:�܇s�O�Jn]+����M�e;�eƑS��c6�X !����)��%�)�1r�����ζ�Cf�M"��"o�*�0==׷��Q�����p��gy �
�ؔ������G|a�A�WM��~��%�у����L�#q,x�$�'D��²JuO^�֐�-�"�9����Y�џ�n�R�N���٥���u\�z��ktQ��}��z��N� �a)�6�Q�s�T�қr�_�K����OM����c���1�Zn�՟JAZ�ȯ�����Y�`��a���f��]un�c"B=��}���7�B�#}�.u3v�'��9���'d����hbdM	Q`|4A;߶���&�=4�Art�Ǻ�0�&xED�6W�䀃T�p�Y>؎|s�1�3�u���P�ۣ!GI�����e["6�1��P���M!���IJj��o\�[�E�"�<Jvn��X������d��p�hd�<�&gE��V��v�.��5��K�fra�9FcG�X�����p	��L�&*�'���K+0��7LhUś�<\9�0]"��Q:6�������k7�cF�[rV5�2�\1m�H/G����q�9@b�?7A��C���׈�R���X�o��׫2M�E���\ޡ>��2�:��ſ'^e����|D��Mr~`�}��*̫,e�V%�:Պ8!1��>�Ρ�B�4�66ީD��H�.�1kr���g�|`�Rߧ*8�OS��_$F��/!շ�f��^���S7ʉ���N�W�,H�u�lp��І��V���f�9J'P\�]�x^��F�~듐=g��i����ϻ*U��I�΃/8���	�;�;!�*�r����{��(y�f�]`�xL3�>����T��@��@��~���#b3��`�1Ώ)W�ϩFq��L2�����������D9���0�����X�}ඞLr�'�����R�O��<���v^������$L4����H�,��$�\�m�0yA5��9TD��%u�,s����44�iU�;8f�ЈF�r�Z8��ƭ�@B���Q��}Wm�=ܪ�]f�6G����{�c��縵�;��-[ry�)X�l��{z�j�F�ڶ2��7�6�c�ၞ��oE�l<���~\N���tj�O!����Vʬ �>� �.'�")�8����������
qm��q<u!f]��qfB���Z��/  (��|K�i�h���������O05&�~4�疌s4�`᥌S���zg9J�~�!��\�oY�|Vx�5��ʷ�"e�C�P�:���(Xu�D��o.�.�6PAв%KS�`�ߋh�?˫��D�Tf��ם^%��x�=+a���KD���%z������y��r��Լ��a�� �H�NsW�l�Y�BjX�rn�3�	zBfЊ0�9�f3Q�񓸢�mI�4,�.�����q��A��ׄskn�*���42��UM[T�jC_� ��bC�_P�W����ꥺ��.r���<�;�������o�df�h�9\�`����
��Ŗ�(�d*V5]s]�|�z�e�	��Gb��Ur�f���;ſ�}�d��9�Ccwdf���~%��?n��v�j�3�Q�R��1�ݪvk�CgD��?���3c�Z�7#'�}T�	��mT&ji1�5�-�Ŕ=��<�|�i���8���嘷��m)�ZN�D�����^n��L�#>@�W�D]�\R���(ֲw��������76fw��1�=��P����	Kj]�L��H���c5��6*~���c\dW���۠���� ��n$Ǒd��5?���|����˚���jh�D���f ���a�r)#��C��6��=���]_���e	C��З
<F�	�So���h:Bnx�t)�N�����^�|� �T�O��p��$�����9�LJtE7�z
F-�:2=�'����ނw۪���C	�iO�1?I���g4�C�c���F��;YA�W,�@ɒ}J�/���@Aӑf���w͉'��k�5����JK*�� F�M�*X��K?rD��qלIӣ:�Gw��
��i7Vy.��JԖ�r�ʶ����	��6x�Jn�W��������"��o���sK�C_����^�~3�Q{s���B����Ҝ��-�V11#dQ��l�\
�(9>�Ś;�L����g�X�1��r��h��?�pe0�l+҈8T!~����>}�
s���DD&��6�/�]Ĭ5�E���*X��6�h��
KJ�47eC9���%Ro-%@��W���+k �YLx�b#������P��ou�L��B���]��Y@��O�x����=o��2{�p<���3��b\�Wf��ӵ˸u}�;�h���`�@Z�G�OD��-b�(2`m�!�UN�Ri}�`��0@PL������e2�ϲd�t�����؟ߺ"�jE[Z ��W�L9���}B��x]���ɭ�n����Iџ����l����Iv�����J�Z0o���Z��Ә����&Q ��Zj:FƗ���ő"D��jH�pJ�+ݠ�`)�����D�VO!=�L�es���yr�Zl���^6����2�q�@�z��;�'��0��-��O��<v$�X�U�(��l��}��F�+��"��J]�OJd{IY_�c���uD�����(���sr�� ͇7�dTI.<ap��V/8�1n`-I��}'�>Cd�9�^,��<�n�ΰ�i�>x����j�%s��� ��n>�iޤ���$�{��%��:����j�����q�̃�p��}�r�-��Ć��Eie�=?zh�����ٖ�^Q 0KG+�n,�]u���3�A���J�m���!G���-XO���V�\P_��:���8�2M�2���,���]b-��Wm-�z�9�A2'`V�@�9��YM�؜$Y�����m!8'S\�D'��!�c���'�7K
>�f
়v��(�kEM�1�J}��k�t(�U|<w�������e����}�207�F=^�T���@�M#Z�LĢa�^Cz�>'N��]R�yI�nX��ꃯ&��6�<Sz#I�CJ�)u��8L�=�ݔh'P)�\'X����=�ް�������grQyY�����pՅ���d]|�Ix$)5K>^G�#�`�~PĲڀ�1a����rx$]��� k�0c�p�a��'�����`�A#��O�C��M�'��M*O�ؗ
x)z8��S�x���^b�Ue��������~g�˚wt�wɌ����"�+P�sc4��Qqk%}Ly�ڂj�C1g6�]�X0���Hn��Fh�^S�b@��l�QC+qQ�t����	-��`Ժ]�����?��@J��>iϵ�,+cE���X�U�(��������w e	!�����p��Fѭ��]lGF��wV���ΌKYUU�<��v��qP���]@r��N#]W6w�e���GqĘn�p^|a5��<.�keu��#x�j��wr9���h�+���(�F[	��t1�2�H�$�D>��M_n�����d��R��v8�D��:]
�#��9mw�>�,P*��j΀���%۟�%����������b�=�*nh�� ���2�R ��q�e�1����7�T�;�x��D��A�N��� ��] ���j�݃xI*t�@O�X�SR�`��M��sjv`F@�E�����e�u��.������J�	�����ָi��q��*Q�Q��
�m���Im_��L
RG�<�����e��-��M��e6�yV��>���*8��9���}p_�>+g��3���ݫK�7Wc��r"Q�E���|"4&���*� H����E���^�oWN��~ߐ����ҷH���`J��,�q��,qđ��,L�D���~\�4�3�@��	�~��m�����'��b�gV���b#��U߁���X�0L�hՙA#v���&Rg�CT[��A�zY�w`^������A9�"�����PC�?�^���@eF[�����~��U��Sd�l�JP�� �	�����a�#��a:o�vb	�zM
�H˩Ǫk�~��%CT�l�\
V�4Lh̊�릗�[�o��i�E���X�u��|������o��P��Y�q�O'8
��*\�� #��v��;���|-,�{+~�%�Gv0��V��k��ᦓ�	|��6���{{%�4:L�_晄�(VLE����l�G��quo�Ue�9,4HhJ&r��J\hi0ǯ�����"�R�E"���i���2��M#d�~ۛ㇟.[@�5�sb����=)����p=TFc⼨�.5F�h�tBE]�0Z�A���	2e̟�I��u7�$���X�uK����Ub�@�/i��'ꎲ!�6�IyN͑B�a<�������U�St�i{ ��)2ej�W��R��_�B���(橡Q�KwVP�CE�NOy���Ac�C��C�ISf�o�P/o�*aA����U�c�2�ou�F�~��M�E,�Z\���x�e��ë��>�Y���7d1G�S���)��Ɓ��/@b
�>�)���梃9ߌw�S1"f�f�I'��~z?$?@H�s����_a8ÆU�����:�_:p�}�Mm:�O�-$v�׶�.{��QVr9�QH���
�bDױ�f��;�F�8L��|j�����4_nh��_��g���l9��պ��"��ɕ�s�����qJ`������i��|\ku��1���b�nFA��9(ʖIv�#k7��nh�\R�p����\����醭�ƍ���ξ6�G��TF
t�9q��~�� �g
̜R~�K�t?��mc��R��C������>�d��Q�nR(����mɵw��fu��co��뢂.�  �:�xM��R�Kt���6��O���)Qx̃��O?��PH�7?���L=��u���o�A:����[����;�B�
}5{mD���q�����wc����p!y�=����9����cJ��=II���v���1��ρ�����H'�#9��
���@l�	{L�0�^h�>>g��2c1�e���:��Hw���*կ�t��!g<��JmlY�j��َ�w����%%,�N�?���,~�5��AD�ku]ȝ���R[
�"��_��*>�	*�+�_ۀ���{��<,^�괝�+^�R�!�ǃ� ,�l�Ȱ��MV�L�*��G1�u�E��^���o��FU�Gɲ�D����)d�t���U!���p�9SeQ ]Q�a�~C5}��&DM�)�&�����|(/�o03߰�2��������L
=�ބeʡ*
s�猤$����y��5D�� �;�T�0�m�E9{��XD%��CE�az�wk���1O�Ƭ�d(?� �3�l��\�y�Y����R���<ar��}���EN�|g��Q�2<���}̉T����n�&�s?��e��¹t���Z@Zk@X�����3�D�k�y���ռ��Ɛ���e�V��$�ﳒEF��e��*t��q\N��&�Z�Ɔ=6��Kb�Q�Z�ݤ��eT^��B��ϥ/8��(�S�4�P���̳u}�6"�h
dA'k�ǔ��&@3K䘭���"�a�����*yF9m���Q��.�P�ſ���̪l��߇���V�x���}�����N��J�vʹw��d�o]��۹���b:3�ɝ��?S��(>l�r�6|X~�_�GA��J�O�(�2��I��W{pB����3!�K*�[��rBff�)����,�T�w��xRC*�q՝j�'0��OU�Tk����b�Ѕk�:U��Ae ��Z �r�RY��2�T�,���ҡ�g�l�tZ�J���k�����8O�_�c*�X+p�4�Cm� �.�Ư��7<�{",��WĄC�(e����b1���� K��$N�?�� �M�*��dd�LVL�+���C"���}H�bM�_2�*t`	�j6���^Y�)�e?�N�B�.S��;��+jHD~?f(�g��#{?������ɲ&��2�,u����H�#+A�	+�z�i?>�k��{~�Ll�=v
3����� �#�Z�"�y�M���!�53��G�
���
�C`{�� ��/!���h[+Ň�iKwgl_�&�:��ppF��Κ��¿��j�7�D�2;�"�M���h��j�_aH8v�h���q!�H��o9�}��1����:�΀N�%�rA�<Q��õ'F����M���ٔ�6��Tuń�Q���]3�%��5e�mgC��~l1PgX�(��#S�0+��k�jA�qĿ�N���Eǡ�KF98�N\�D}�S�u�fv�3��s����51��	\�Av	8àK˟�k��^�{<�U�>���.�6�lj# �h@�k�6��pd3Xl�bݿ�"�*x����Ǩ��p�<�Y�A)Q�X�#� ZV@	!�~u�/r��u��4�j1���/��TR����
C����jl,�*2�0i�HٴҦ��nj3��4
�茞X�ҊX��ٜ�Q�EjZ�¬�L_З�g,ƿآ/I��}�_�y&�5C�!���&����)4��E`Ŕ=�+#>-˛'|4��f����@�����%��f|#��SF��K<�7����菗T�S0�����z�}��!t��O�Ӌ��+���x�5�x��αvѿ�]�0�D�J�0!�D��`���i.�:�aj���c*������ջ��ϩ(���skŭs�G�_�>���Ln�ԅ�U������@�C�Fq{	Z3������h��ů���yJ֣�ׇ+)�%r�A�k�� Z�|MG!KS��(����-��v%�v��
H&�W����we�5������S���7*�U~��\�ج$N�%i��'���OͶ*k"y<���bDP�~�;�~�c;[�M8�{oE������?N]�����UUvK���%D��1Q�qk�.������PmtnQ�*jj�+�i�����io�Xe+/n���{~��Vk�:�6�qxT�P��]H��!K ��|Gp."�b�ش��h]a���b�+�<)�G:�i^0)cƟہ������0-���[�*�U�ςn�S��A�k����ݢ����pl�5煱����G�l�ID�%�֠nnR��XU���:�h$�l���L��𣎮�����ˏSɌ�M�I6�5o5H�P�?Vp�d5�����Zi�NW>*�9K�Ȑ('laX����<��>�ɍ�Ѫ%Gu0���fvG�29�R�X#��θ�x#O�	��_��ԃk�s��1��E��I{��y�q��& ��P���Z����	lU��9�E���5����oi��,>���#�yc;~�j�rf���0�����-����#�W��?t�c�Ԙ�M����]��z!��ѹd"(��'|�=WZa�lz�W0<��n��H��=���<ϸ	i��$i	J<�-��.v'O�</ƶ'
 �?��?˳"~��{��Sޛ�]3%bo�,/�JJ�e!�H��R��%'�/�������r����j������ ܒ�3�_��Ԏ>g�e0ډ���w��#��
�����5�0*����������g�G�KH��g��SS9)�x�F��^L�Ӭ�Q��%�V�YsQ�Ƶb5;l+�5���rf�h4w���%�Gy�j��ǪkI�~��C����;X�hx������N0�[�)���H�j�W~�� Gj�ڑ�`�or��X�u�����Ki�S^�����MC�"��h+��Ȥ��s#�\K��"m�) ˼�ɹ&*����mi��F�L)J��Y"�)�:�ց8g܁Ш������0�;�]g�?�zX?�"���������,��1�n��w�P�`ϱ:����XF�\D8�9OV�Ks���񤟸���L�y̼v���o ��6\�<�'~��v�4���W6?�����	lxS�>�~B �=D��ߟ��>�0`s���19I/[�ѯ�[#�hɚ,9~}�*�@��DZF6�>)��qõ붟jv?�}-A�u�WR������ő\_'"����.v�3�ڌ���j��D-eY?�0M;V�H�T�.+�F�ʗ��{s���6<��������t�*�Z�]$��kY��mt�4"��d�?Q������Y���fr�d^���w߿%���~*oC&~F�q����U ���H�O�L�����PcY8�J�.[,�����A4�,��e�~�r@�+	�ܵC{kΎ�r�VRD�#5J�"|&~�����CL*K��p����A���m�^��7c��/�@�A�/����hK��6�y���5�/֋�2�(�I����z��D:+���V�0�a��N���-��[���Ͽ�5���N��_*Q	L�T7��^�6�Դt���o>����$�   �㑢�#[ �����ԝ��g�    YZ