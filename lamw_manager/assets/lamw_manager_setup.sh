#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2075171539"
MD5="8c852099a70708348ca17c521b51f7ac"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22788"
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
	echo Date of packaging: Sun Jul 18 02:42:18 -03 2021
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
�7zXZ  �ִF !   �X���X�] �}��1Dd]����P�t�FЯRQ�z�������_������r�G<O�z���i�P�Z������w���/��=�;c�����Ja����<5�^:�n�\��P���K�1�u�|��s	'�����*��
��9�{�3FWԸ�3��v荸M2��/i���G�ӳ�x��1��N�3����Pg���5���n��F���"�ˍ�l��y�Ӱ�s�?i��<�UC���4vY���B�=ؽ��<c?����6������� ��	�I#��L^ƀ��@�-�K�ՀߓD{���F$`������UКXS��D7o�Ts�����Pr$w��Ĵ�z�6I���Y+�R�04炓!o)�0��`�u�p��FS�eQ0�9vq\�
�j�<`�����R�g�;��8;w�Į�Շ\ܳ�IL.�\K�v� yQ���Q%S��78c�i���$ڏw�L\]�t�j�j�k��g��ƱT?���L֚�����K.���7�=OK�U<�7!�J\���}�|D��T��G�~���Z���0���� �~�9�<'�jH�f�O#��/�b�۟��LY���=��ʸ
�ep��p�u�j�ğ"#�!EC�?�F=� �'�x��+BWsп�x���0�nKP��]\�H	w<wap�MY�,�SG�l�ɱ�H�7��M7u��W6�aȐ�$0iû?���� h�u_ d{�a�-=��b� +�d���%I�AH��Vӹ �ATX�p�r�")"�+�]=ģ�ѯ�J�pJ Ʊ>ә�df�u|]�Jf#���RS�Ƀ�E���=���oK�9�1$�<%��Xَ�R �]���(S�!�\o��Y+�1��J��������7����H���m+�|����<��ؒ}��*/���������A4���`K�_Ĵ+}\�3N.m�� �ܟX�o�_	>��wK~�ӹ�v�A�D�lW'Χ-/��.�gg0HYo�����+T�����S�E�G�O���e�d��^���Mn�yS�~τV�N��Lj8�f�����۷G��(�fGU�p-N-:�Ш�/���TI�U2�,��ȘfOa
	��O��H��~�U��V���FF�=7��'����d��Qt��Oe�K(�"nW��ݙ�(|p�ly�͸��8�c%S�R}�1�������-a��Iˠ�}	�C��r�u6�,�
OPB�.��M4��aF���<��z��`h��0��KodUw��H�d2\Z��N�g�ڨ�{�ĺik�~5'G��p8N��=AO�}�8E\��3�W�t}��T I�����`�I�	�w�J�Q�&c�m8��1�=����e�I3G��E�1u�.n�����r37���/�?!��V�F�@��L+mp9�;a��[�[t>'_C��׵��ꟽ^�|�Ý�yΏ��8��O��ѯ�CY}�1�u7�9�n�5
D�>��q1i��Ƈs2��绎��/2���Y��j��7ڂc�7E|	���Ye���<w,Y�B.O�d���0}1�5�Ӑ���H�}{��Ba��I#�5����OY>v�7�<�ث�J��a�9���M
��<���s+[-Çt��ſ*�����L�S ��Ϫ��&�?w�_�2A���Lzqc{�����b�FI��dF��nzf���'�ɒ�zF�İ�R�n�3[���1&V�q�9�,�$gJ8�O��Z�*�&�� ��!M�C4�o���r�Q4(L���Ja�r�Ew���dm̷�)��Z�zt��
~�`����Yۓ�@h�+z���g�_0�e��m��\������E����eg	����l6k0��Kp. �荔��j�$�l�5�^(�
�5;%�C�-M;I���1W�̏MqR�߬3]�쓾�޻t|����f�|��A��8�L"�a_D@�{��}Ȑ���N$o{1��A�؟T�Xi4�^<Z�D��b��S3A0S��$�[>gHc�s9��e=bC7{���\�*�J-��|� gq<ϝS�,��l�*?F����c��z:�9�qF�������~�=�j����$A����Cq�~�IO0�}����xqf��)z���/�s2�
�v�W^yQ�}��Dar��4����X��0��Y0���\�6��W����rԑ�1�Q'8t�մ2�����N��> �##n�|���){.�P��|���<G>��|� t�/����-��U���x�$G�����=��L�1��,��9�D���5lU.ˈQ�)��0�&Q���;�l�ָ� S2��<�u�D?tzY򉃔�t��h�z��Y��`�cŞP��9|Έ����ˀZ9���Ґp ��X1%f?k�>H���F�@a�
@�Y�f��bS�k#5��9����e�?����"79�y(�KȹF�������}X��`<�(�=N��fӧT�87-X5���a�@�N�]**uDV��t�6�Z�0�ϰ5~LB͋�	��h�1w��.�ǺbxI�y�VD�����^wE�yQS�[$$��͔�v�a��Q��)��ٿ�vE���>7q��Q�����}�����y�2��o,H����9�S�W�P^#��Qz��
�� ��ڏ��:��U����		�`B�wJ��ϫ���S�;���iu�'�Dr��X���{�h�\ �szV���^�YG����$�&>|D�N!��H1�ŏ���[[���Rd�>\�!^dDc�����M�q�w��ld��Y8L��_C�b>fK��8��Ĥ�%\���t�ŗ��p�_M�`���u����F�f
yk�l���@~��)���	w�ޠ�jJ��O#�z$��Ax2@
c<�5�%RFNS-
�6��Y�Q���)�������ퟵ�ez^�zmC�z���;���W4�]V���$�[<b����
,����ڻ^T W�zMZ+�`��¤<:%z�����j�MGq������JʇY�� 9̢[�:_y �����\Y�[r;Q�TDDn�x*�l@���M��A�Z����?o+JȄ7���I�A��н/��ӂ������Q������2�o�C���i3(��
��6�&�>����[)��&B��_6Y�$���6����a�7�t�$�;|��ƵƲ=�p���P�UU���eDʳ'��)�sǵ)�@���F>�J�?��Ѱʐw����S�S#�p#4�d  P9�um���	��U���h��7�{{DJ/;�T=�w�i}ڳX�U�/�fxTE�X��%ݺJ�:��ky�p �= ���2�լ� �����)�$-]g�G*]G�'�՘�n���3��j��ۢ/\�Z��<�l���)!�wz�g4׃�{<n@��%�O��*m �Nj+wiI /���7��C:ua�Xd��W���L��W�8���8��-�5=��Z�^��&�:��P�ц>�@��11/!��͢���TL�J� `*��CؖY3���Kz�R�1�O�0�z�Va����=�?ej�mT?�N,�""�2z�L�b�o�Ky�l_o+-f��|7��āE��.͢l�V���o�S[
���������.HA��$K3k�k* &u�ɛV^Q��#�=�y��+���H$mKm6�_PX�'�C�g仗�6���[+���9M Ԡ�@oF��gJ����! �%۞]#>�x��v�89�A���\/#����MYX,�
�6}��]��3�����Cd9h��B�R��Eg'��V6M�V���-u=z���`xL�U��!�M�j��B��nX ��IX�c�����#����vy�G�V=E�*�r״,�R�lDG.�>�$���������^r;FC<�XQ�\���nG�������� �Ld%;e��y%��t��vXBy12����=ǀʀ��9�|ټIZRF!��˗˔�s���#P�8e�r�ț��F]��_T�m1��-�t�oV-N�(��d��$�>�t��0���f��7�(���͘�R����_��"&"_H��כ���e��!XAZ^�f'��J�E4L�P��0�����NL�j&�IT������_% ��+&�@�\~χ�V;�����L]8C>��dp"���P�<YҜf�\l� ���Ns�aD)0�	 ?�@��:��_3�&�ك�����Jz C���L�
��r֔g��؞�f������P!�Z�֚��\n��P�k"f���d�9k�V��UpǍ���xqbOQ5�f>q�8�	�N/*y�Z�&�?s���&7Y3��Vڗ�=��=���:4�T�Ye�q�u�]B]1F��l.��A:J�O�=��2)�@������������n��Ѵ��UaY���A�Rlw/��;'F���'��Z�K��ʆ]�b#�|��3�r�����i֔�U��mR5�Մ�㞪z������E��>����58�P[��x��d�:�*����:�zB��ntt���b$ٿ��ZcBv:!�X�D��1��u<�p�E�8�n���6�)�Hc�-.�&G�B�g��W�n��<J2;�VV,����Qj�P�=we���{t���pW���k�(�,kR�` �C��ͣ���Բ��Q���Q048�2�=�w�K��ğ]҅Tk6��\�pT�9<ipe�4���$����`CL �9x+����c�9X� n֊��H�->�y�xT��{���o[5&J�I�Hh>/��H��/7��uj�����,&e�ވl	%����C%ឱ5y�q ��D�WEh�i*��8��$}�إt_C��f�_#���p���-r��]"T�*�Yj�jW�R�����V,� �{�.~D�y�L�����{$7�����N����u�2� ������Y<g;�=����"��hOnR��`��b��y=���ӈ^f��pc*����s� ,+~�1��6�#�A�g���H���4	�4mu��ьҦ?�i��,ң�K�
��Nǘ)���\���m9X���/-��u%M���t�۸:tA�q�ؓ,p�_�J������!.��y}���Vq�{�e�U�A=���E���ڷ{,�u�9�v�B����?�N��>8<�5G E��<*�v��t��lf��Rݬ&M%.)\P�K1�Cis}��a#��VuJ2��+H1�����0�" r��-g�3)�)n7�V��]���æJ������W�KF���+�
�����9^��4����7m�w
�n��p/�����M	@H��r�%�W!*���Hé�%$[��/5(�d�Ć.�"����h�S���u	�Ƶ#�s \�&"u�vy�����ތ��c/�?vrx5�bi��,E2�N������H�#O�w�9Z��j/d(cj�5��W���Ԑ�0�ò��$�+�#���P��17�v�����S��?(MC��CH���nV0f���y��j�q=�p�G8[�%��5��E�H!�x
lf͊]Z{����'�U�
��CV5�����B�01�wN���h��$��6|���SJ�����������oHKCU���E��p+Ε�j��x��"K�~�fX�h�m�;�+�(���y� ᾎjh�s���'S��,�!�IV��]�[�����,w���Y��8"����
5�����:�է��D�x	Y��\Q�C�`x�E�5�RĠө.�U�=?��Y�u���
E��T��)��f:a���@O�~�z�C�l'�$?(�� W�X��% �'���,��n�&=`]F�s�$�/��<�q�^��N�Sp��q���*���Ei�YyPR����t���0yy��)��G�.��a��rt6�1�2!�%L���&��EUi�a��Eۨ;��#�O��ǽ�z��;Y�<��.SƆc��j
�mH����EqV�Ҙ�/�:m�ε��+���<��\r"I��gk�6ة&R�B�ء����D1���b>�Z�m�늢ou�.��f�v��"�l����tH�(W�<0:��lm�sO�P� ���p�(Y.�*Y�n���XB�hdD�c���J�����ע�M:톶pp����5z�������T4�a�:�s\����⃨���`�+�ħN�Z%)�YJ3���X�$�_�{xCgIF�z	��z�J�mj�)�D�6+D�5x��E��WW�~��O\ڛ&7s�"�|�A� ż�L�{�O0���W%��e����K>)��lc��T3�-��b�5	xM�0G89��i2�����1i��'CAj�B���D���/s��rs�0�|�q��i#������(���E����/��3�����3|rq;ʐ?dq�1���=C�/�xVi�?u�jo�:ӝ���R�G���7����h~��+!�s �S>�c���|���`ٺ+�"U3��d���t�Zt�vl��,p.�ڕ.�%�5��v���ɗu�"�*6�w���w���퓡5x�G���X��ڗ)9ٺ%���K��`� `}+'�V�:ga��48$�~kI �7K*���h��&���"�◚1��X��-���g����6����B�VF\$FB�!�-����N�VQ&�"ڒD���B������3`���t<��<ϲb�#(�o`,�cN8�K��z<�x��}���wj|�3^�f�GX���r��3"b:�օ.�y���ꮽ>����}E=�/xq_�FA?E�E`.'����G�������6ww�4���CO��(`���8Z�i]��)Z������O=,;��a���t�
p�%9EvZ���"��B-��Pjc5N�P��ᵧ�^֔h�=Z ��@Ł^i�f7���U۬�	l�Ǚ����b����m�7(d�唡P�>�����^�,V��Dc#�4H��!;�$�ڶ��J��b
tB���n_'@T�*uD��P<2_�������.aɖ������=8��Ug�g����U5�<_�W�2Ѽ���d0x��>1�o�>��Ƶ���eKf|*�V�W�������Nm��7=�� 	L�Y�-�L4�}����&�b��Ό���]���.�xZ�ʠM�xW� �)Ĵ��80/���2X^c�����`�F��:EJ�
�l[����*�N e�p��c�w�c��9����
���J�EТ��:���kVͺ�g�&�O�J���:�q:q#���N'[%s^�qR5sĽvq�����oǇct�1q��!'`�]�4���c.�B=��UXd��l�S"���Lf,E���ģ��h}5��*�"ACŤ���#�EZ4���N~�D��{��GI��y��P<G�z
l'��� ��W��7%vb��bC���^�ږ����s���>�VbP���y�)��B�I>C�vl�	�mnp�U�0'f�e[�8�	�4�>�eG<w�N�iJ"4	�Gi�M�;&���_������'�)���PCm-D#�MR.���C)�G�`�*�jx����h�L����,�S('���l(=����`�O�8V�-2L��9�ų���&���so�P����)녦"�f����5�.TO� ��9�%>���n���D��N��Nrd���!<G�(׋�nh��݋�N��<VQ�Lǖ�q����g39�v���,E�#���5آ�$��\��%J׀w�ΜQ�$�tmO��~�?��1�B<x�V�dY����o������ �o+��w�An�6���s!yF8H���<m�^xbPH�(%|�.d8i���@�Ғì�nml��rP!��+zOc&q�h(Ĥ��򍅖MՊ����X�M��S�c�:]��/nN�w���v���D�wi��ݮO6�R�B7��VU��d�ء�o�Ĭ�Ϳ�Qb��u���b:�0�L!{��]���QA�f��L��*ӰU���N�Q�ἂQ���U��$�^=�%�4���υ��2���/��` _��9Pa<ڎe�@0�ulQeN*�H�4��&�4��溁<��Ù.�x}֦/���|�o<TBU�*�T�34^ws�q�2p����ۧ��5!�Ϻ�Њ��A��-���M�x�lA+���m8(`�J��4��R����,�@��5��'�
&h��ȧT@gO��_���ڒ+��������-�|�<�ى��1̕�N*-� DB�-�[�ޭ�����C��O�q��^�s7�
�S����3�q�b���`a�E����X�h�L6�DC�ГȠ,vjVg�G�@H����;������\˧��1��_aL7�.�b1��B��'7X�*�8�eF��3�bvHۻ\�B�%cI�ɸ�)PP�y��������FFjب����7�E�n-�	e�"P�Z��',/o='�~�7�[:�H�����v�*��[�3�ْ�!W81�64����t�]�J�Ed�7�f����}U�; ��ԩ�4�%uy"��^�~��Q��L7>��s��ך��'��ߤ��^�ǝ�n��a_?�lA�&?�,�-�$�Q`1l(*�/]��T�+��Y�Bvb
�Wŝe{���j���n�����r@ƫ�6�4�X�?�%~�Ⱥ��8�U��;R6t��JA`������ w�R�k�C�iF���X ���G��U���B���H`1�b��#��Rg8?��i�=4<C�I��?��'�}�,���vu�3b�H/��vg�I�)�
�F%�7�Y�͡�uY�1�í$�N�伉�r��*�^rC^a#TlQ��]%��5�E|)m6y��%��\�6�������a����B(�(�/�Oc'�)��q8�O�<�����HsS7,�f��7�5
9�~y�$�߭
���đN̓ڪ�4h���%�b�+��V,�ع��AoД�6}������a�=�:H�}�]�~�c_�S���Я�����.z/���ӫ�4����둓�
����i�\��?��k��:TT���H�s$��8�T|�׶V�T#�?"O�G݌h�/6�y�mE?d��[�����n�<I����_`Co��Lo��f�p��
�S��F<t���aZ�d,��(����d�/H�[3����?aB�ے�C���㇒���T����s�z��)�i��I���Y����T [�޲��8u�G�7����x�z񗝁*�;

��ץ�����p��3t�˧�"V�B�=G�/ �=w�?������쿹�(�^Vep>AY+{b�r!�o�˱��������y�\ճ���Dld̻��&�նZ�D�Ě}) �5ڼ
�z��{R�t�#b*�v�4�;

�umEY��i��f5t�֧�lm�B�ė@������Q�ƚ���ݶ0T�/��o�FL�4��]Oh�&=�mi7��7��(�����z��	͚8�߇a�0�q2B�tW���0���\L��^O�yZєdBhw�&Yv�<"�6�w�Mbec�+�3]7��^P&WV�JaQ�b����ԪdI{]�a��0�H�m)��Q�r�z��'�@LA3hc|k0�դ��O�˛���J!.C
3������7�>דz6�<����P�1��"+&1V hQ��A�c��߲q���R� ��ȟ�̔�����z!I�E~Om��A����.���~-ҷ�7۵��#�	<��r9���W�_����C�;���>�c�����2�#����ҞD�$�e`��}3�0�/��E�c�8�ئDgl;�	g'8:)�M�~C�F������m	��\�P/jL���C��G�H�O�aeüªH��;��o��s��W~1m�ꝧ"д��wV�8����(V؋�T,�V�i�74���o����@|e~��SE��s~ml ��0(�����1Ӹ@�=�����?Q=���7�D\� (�6T��7]���;���������,1��%��uD4F����P��ux��9�g�
f���#E��S���nm�@ɐ"=��9�A~��X��V�t�+�md��O{�Sy���Wػ���U}��A��yo�!+볘r,
�����g�C�Y��f-�C�ri�S�'5&0 ��ۢT�Ց��/QN�a�Q���+��K��gH;���-�5˦����C�L�b��E������S�5��6��YF��ð%m��{���/�tX9�Z]��"з�?ߴ����2d?ra�s8L�{,��@�]�)[�'�
� ��`~5GT)����崞ZJr-�&�5z���z,>�1b3ê�Ǩ�R�ܱ��)t2�ح ��򋢦5��!kؼ�ci�qnK11������ǁ#�z�X�=4�g��,%���t8�"ׅ&�,ۃaz�{'*As�6h/�Ŕ���9H�I��7`�¿�}S MZ�������V�G�W�����!��Ȗ-������ ��0��?�n�����H�_A��1!�{vA�ؙ�|í�"�h�{$|:U��4}�X��ٱ,�,�Z�pzSb�:�&``[��c۲�龜���;�EP����]�>;�a���^��+����A�e}� B͸gݐ��Ur��r��5�8q��Z�����TE
@��y6e;^Z.P��/��c��Ţ���V�R���>^1��!���ߍ�ڵ~���d<<���u+���eB�Јs�C-P�̱��'�)�?v��eS`dX��&�u��W�փ�wRv�Ά9�5�g��3�A�d�C��|(�"���3�l��΅�>����>YM�9w�J��R��Rw�r?�����a��pչER1������	�A�h4��?�U���]L�Jz%�X�o�A	��r�B��.x6�$�72yR�ש�M���J� �|�K1������ڱ�sԬ�욅U,!���gI	���rq5���O�G`��@?��P�Ds���ڬ�2)�[��^��}��@ԍ�(�#�jT1)�"1� L�.C�m�0.�����Kj�7X��s����[�����ªzɫ&�	�0j�nm�\S������D#�Yw¤<7b�M|�{l^��ڳ�}�) Ŏx���k�@Lӄ5�����X��w�Ʈ>̊�b����~f�<_Hֺm`�ϔW���}�UwFV���&)�:�/-cL���>yvo������7���7�u����4_�_�U6ɒ�v�fP�����E(���|�W�d#�ײ��~Z�րl
i�k�ty���>/4�؝�`V3���%gcA��D�)u�OK�Ea��}6S�����)~f����U�Rp!]�4/�;;��kPp�3iQ�0'N���&yD>}���fݪ��.�VS��(�{Ä�Ɔ� ����a��Et�l�}޸ �-[�ny:�T]wX-Z�3�+%&�1�GM��?h�S�?@�G���I���S�Q̃�VA�'�{`��� ܕ����*�{'��eE\��7������}� r|c���Q�N�qyH������T�(�	>�nP�&�u-r#���_]Z��!l��m��;��a6��鉵s�$�����۩igM��K?�ޗ��1�ӫ�Fk��q"����<�EN�d��ڛ���6�r �a��ZN^���ѭ���k�(3qE�a(d�����JiD�c�!��<xcxIM8�K|(��矯7b{SUN]�2���؋�%d}Pw|>�fԳN���+ s/���'���-�L�	��U��˟g�X�!e5��/M����{��"�!��1,T[O�J�M��8kV��
��d��Rr�]�Y���)P4&s2�U�}�M�W�o�V�O��E��e�)Eק�~������K���om����߸��UyI.��*Yp�/��g))�xj�~�����rA!Ƣ�X��z��}[l��h�'�'�]�'H4T��J	�(��=KJ��aM:F����è�K�fB\i6�_Y��%����/��e�_�L��;�^�wr��>� �ڑ���X�0c+��l\%T����li�_s^�q-a�Z� WB>�Z��J�h}pf]'N@E'n]��*e�꜂ �{�]y��	�i�,���!�Q�Cv{В��'i�djU::�� ���;�a��\��:(n�-g-�\C��礈^]~�Oi�R+�)�
���D=��"�)����\�R�	��c�c�Ǽ����M���~ظ))\3D�w�О���E��[�y�(Z�(�]۰�D����7�	�a����K�0�J��"�@�̃&�ke�O�U�[5�.C}'57~��K�&M�g2�SZ�L�M��@R׼�dh��oEAͱ��y ���l��t0.��~L���bM�u?j��mU�M���9�"#�ȟ��X��$�,N��Ѿ��W�D(O�L�\��\���V ��e�C�+7�x.�[>�6�g�+�GK@jݜ��?_1M��B�ၕ�}�%���w梨_��	�C�ԊAkZ@w����4����rLR�Za�k	�q�P��5d5����u02��}@�<�nY-�@M/��g��l�#)���*�?��f�T�'�� �������&lp���, �ud�Q�OJ�cK� ���R�;1QX��ҫz!1��X����dH]��X�D2 C�_����N���22�W7��듯�G�.U$gA"A�ˑ����ue�۹���̳��x� ����E� �n�}�Ql����1m��������������_7۪B^�_bVЎ
�;�����j���d7���ۓ�X�x^B���^�M�C
�Xz�������l~^��*�[���H����P\�E���	ڢ���l b>a0fC/��;rj� J[;w%ԒJe#D����WvZ4�C�h!�����Ł�I�=fJ9���O��V������e[�� ���� S��E�ʛ��٦�(H�GZ7H4眷����Ϸn~�F���	����2����v��
�:�<NX��i�ln��R3���G�
E�AN���f����\�pX�a%�n^���q��k��4�o�R��>5r��	پ
�Q�"ǡ�(%3j=��M#�oק���^���:俥�ku�_��!΅��/U���"k�P��)�����/Ӗ��,����
�1��� �I��wa���9=4ʞ�������Ƒ���F��.S-�I�+��@�������D�bC�Dz�@L����c�4��͐�Գrˆ�+�z�Y�Sr�"�>0y1�!-��Y4�tZ�� �c�mї ��R����2��I���c�7l=����L��pE�2q��4�K`f(���Oj�	������\w�;_�aL�o=@Q!�ȳP��t��`��-9w�~��%kz����uV��S|Fp~|z�`�'AxQ����Ԉ�����y�|&��o��5�s�.���]O�I�Os#@��-�� ɰ'����T�ګ����){���a���%n_���%(��T^�F��Vd�ݏ��fs��k�4)��hv(�^��Q�)�d��bx��aA݄�ih�3�p͞��E��x��nk7M����eܹC�𹓑��h��ެ}�|���:��=�s�Cs���B����F�F3e�M�A}�-�D#��Ez�]b���oK\�B�����}�
) ']�?�@oXO���>;���Z(��en�s?�][W�&�rp���
��2jO��-���D��z;�1ʭ�`�CVm�;�M�h�6�DJ���a��ut�.k��BΣF�9+ �$���?�G�w��;��,�E��83W�7�a��vS
q�v���BY=d(m�fS2��ފy<:]`��d[hk�ۄ;W+�	�_�'��pIZ�>�5��v2��� ����>CbFh�����ŸNP�Xm���pevt�u�V���p֚��1]��z��Mj/A�Ǝ/~5��;�㉜�|�'�.��4-;J(���q~�ϕ�8�����̈�2��\k�i��{�1g,.���M����r>t�U�m��T�Z�r>_yo?-�%�/d�ۤǨ��UxG$g���ie�%����3�z�%;ч��>&�:R�`����{9�?盐iV�&7�L�$������IE����<� yY��赚�"�N��\d�ݓ�i1��{�P]�����ب��_���3�+m!��<�0ί���sq���;��I�eq�g1��Y�N���2�Ak��y�3?h@�Ҿ$�z퓬����7�MG�;cU��U������i��$���l"��)�d{�|(�q���
a�i�����el�)
��Q�X�4u��9�KLc
��N�����ҧ�"4����@�}K�¼�n�)���#5v#�SqO6F��y����~��֞��8�.���s~k0�dĪ�W��{��`Eqn	�*����|��Υ�͡}fʡ��.����4KU��nY��1�oݏ��j�~
�uv �0��1ң+\h�	��G[��d5�v�t�bW�r'+f���4_#�i���e�]�7��(�*�+�`�z�������	:�d"5#�t �N�|LY
�NǏk�mz%ZӦ4�t��1#��"gOtX?�cl��������l�0N�u�L�dO�8LDE��{��,�;��Op����S����h�=��s|�D��(t9=��tF0��v�\(èO��\�6|QR�V=oY�!BdU�YΨ�M{��4mr<������2=�	�C1�F�쎜��گ�A뭝Y������m��m"c�p�����Hҙ�����-�wMc���������)���J������6�)����I0���^G|IQ���w�{w�K�B� U�*�VWۡ���Ɣ;�sɸ}$��j��2κ�lgl;�}Z��B��h�;F�"�\�F��˅!2��_�>��{�������Q�:Rlu���-9�/�(�����9�3��Xp�l�>r{O�)�a>+3�a�d��j�d���]4ZS25��̬
����d�˧rf�]�d��H2O��Y��� 0	�g�W͟����>-)�,W�����a�K�N.�t-�NQv���"=�q�<���@���#���8s�jД�� u��O�H�=Y�Hֻ.'���vG���٠����l�C��J��JN�Q��$	��������8+�'���,B�R��5d(�����T7��(@��]#R�#�x�S�{z�d��m��oK��̡,;{�&8,0�
����&�����&�:���a�h�o!i�U�@V"s���Ο.]IX��1��P�րb���z���4��]�~jH��|����O9�<�g�$T��n��Q�����9��VC��S&�s�"0��(�v9��ƀ�Y�e_m	�BD!q=�A]	����3�z]'k`F��(�O���6��tV��g��p�� �������ZAc@��se���7���2RG�]ݴ#�qU�C/4��s#���4��6E�m�����N�fN�P�<�K1o�k�\\���ʔ��[:aO� A���736:K�uq�����	�U����8�;:.�P'r"&��ȝ�9<(&%ܛU?�������i��ղ7V����1�}Ѻ��mU�'���p���3B#�kD_�MoA�����D�%<�Z�N[������~5����OX;%�$Ě��|�W�g~�r�cj�,(Rq͍���vV��I̛p�5d+W��ڮ���W�r:y�v)=��v1��q���]�W���(Ψ&4����q�֎� c���	똘(�{Бk^��ƈyp�i��a�$�,��~�����G��h�:ϖ�P��4��W�T6�+���3�\|���cA����xŠ0̑���K�a��`u؟Zg��>��e@Ly����_�L�������L���떚������)K��}/���;����:��fj�ca�~c�]҂l�m�+Q�`G��Ṃ��غn���a2a�L])�_.���2���N��xU�!r���Qn�H�Y\BZ�Y���YS\�nv#�-��!��!������,L�h��cႱ��%�m����lrlD�t��t���z�tTג�Z�A���7���1���|�`�E	P�B8�@��`AH��6t�i�4pF��?��AL�&��z	_�G�,H�=|�����L��b[d=:d�l)�/n%�Gt���,`��_�l�w�.��횳X̦��x�4��{Z�ʔ�%����m���	+ir7��7^�4��8�f����rb�HBS�"zH��P��2?�
0,���y���b��w^��!���U�����Z���;�r� �&5n�?)&��)�Ću�XRP��z�*c���7��Ɠ72�����tA����2���R���i��C����G>�����.�ao�6!ye\���+6J�׆YV�m�&Bw��˲a4?��\�φ&�,��Yl>���`�?!Հ�Ѳژ7��SQ�=	����49Ut�	�g���Y;!�����}�U�5��Oq7�A0�^y aT�iL7*�+��[3h�Be]���v��'6)N ޣ�N}���0�G:g ��Ga�A���
b� �j�V���;�!�J�������}[1V00E��'��u�SK2L�苽8��������1f#)#nbʔ��0� �����	a����� ����@d�D�mnxP~}~�k�z4MR�%�ý���_�B�)+i��
p�k�jGq{�]�sk,��%��%���Ԏ��O�W�<ty�)U%��3A�h:{K��D��%�����:f^c�9����[��l �8���^D1��$�Ց�������,�Y�%�O%C+]-̲(�� �΅)7d`�˛�ʵsN�ʂR����ٳ�u�G����Z9��}���ӇH����XK�J�Qȓ~#Ά�Q� �ژ�k��<A���B'����>�����	�
��qY'_
���5{��PROaR?��QN0��j�te�\ڗBK�q��������Jy�z�A�H��F���3�`S�<�j&�fɹ�j[�L�H���]�Iԅ�{�v����0s;���|��}0��D�
xĪ1I������ߕЈ[_���+/��S͉�k�Y�"է��E��E�C�S8�����D6��AI=���vN��b�h�a|��@F�P� ��FY�Sޑy�H��Lr��[��-�H��^�6h�����%?�jx�F��[��vO�n��Ve��XhE�&�7��Et�����{�}�v�[�.n����@,y���J���6d����^�?'�������#�U�-�Ǧ\�.[]YI+��He��\��1�e�c*��B6��JJٝ�=ٶrs�\9i��j�{@�x��0d-ep3:<h���ZXV����JHLbĥ�ӥ��GT��d3��>�O�^�p�wN�WL�O3|L���]pa�����9tS�k(���:�D�$%[��C���3�0��j�I��ӂY*��lE��w��� �.8Щ��QF���g����pϦ9�
$Ș�`�����k�;)c�N�j1m�Ԃ�Fa�CcN�˪��0�-H� �L���ܙ�F�N�E�0�&�JMd���d�9�-3`X�Y�#����RL�\
3|O�bse����?E@]u}��@�_d<����G�̘"\ ������2��Bb[�1Oi-ҩ�y�LQ�Hm��^e�t���G�q"��*�t& �<~��d�	�b����s�K�ϐ��N/;����s�0��e@�UK�̈́<|�C4�������l��鉶.m���g*������B�fA��E�}�y�g�ܤ�l��5	�d8	�K�nҋs>idA�D����m�U�Cz���ܜ���^n�8Hxv)GXO�y���3�3��P%{Q�ʪ#�잇��������E�Z��b����j���Euu���!z�Z���MN�t�C��s��'	������	Xl~"�;×�<բ�^���AJ��g���� N�8�$��yo���N
(��ra<Bo�00���I�5h��+��m�\ò����X[���%�\�U��j_/$����-��QPEo���jqRg�K�Ǌ�:H�T Z��Y]?gw�cω*砠��ɇ�v�BR?�8=����ql8��ΐI�;�����3B��Qĵ\����<P���M�3��N��c��N
�@ft@Ĳ��4zE��O��lFI�Q���"�}x�4IE��B���l�A����X� ^��1t�L0t����;lЏ�[��^�(��wԏ�V�����BR�T��ϲ�0ݿQ^���R������/���l���7� m�*����p>P&�0n Zu���q��?qd	���;�z����1ֈ�����O㐽���&̀v〖��}&��~�M�(*�{U�j/��� �A�d~���ZC_T�%��UEۘ�E>�or;�#�3�3��i�N��-T���[�:E���	1u�SJ��&��N":L�eҰ�y�QEI{2��P����o�(�^�#Ϥ�!G1�a�Lt⹊���������E��q���Ğ��{�m75���#�ߩ�?>��]�~����[��;�SՊE$v�}�/����M�V��#� �b�گ�*X����$���/0g�' �Ze�A�1az�*�pJd�$�
�<+�}{'�x���R�lB�9��2��M"8��;š��\9����Ʊ~���`83
��f�_��K�T��;8j��e=˥Śݓ�Y�f��v6G��^޳�+2�s��,?z0�D"g�}m
ϣ^)��Gi���VyQ�:s{j}�͢M��\.�����ͪi�7I/��0On&�)ٳX�
\��$
�u����a&���N��̿f�n��}c]�������uDKcߊ��W����'4��J7��@$'�9�X�k��)��O̢��\�e��|���B"Jጪ�YD�*�*�T�aIΫw�&f�y`��'��L�!l�"����Đl��bؽ��ك^AF���.E#u�e�tI#G ��6�;1 / a+��=Lsz��q	���߭�������>Ai������m�;�,͟�I��e��@��iV�R��&�=_ ��a��^z�.s�V�tq`��r���򁩣�Ɂ���l�w��{�p��:ZX]��*��}��$�MP,��x�<��V,�U���R�HР*���ʑ���_4��
�."���Ӊ� �u�*��۱�l�����O~$��%��|�Z�QWx#���C�3�[u"Z �'f����dRYV�P�h3Wi�0�<�v4�����|љ�,x3�,���zq3�� �{ׅH��eR����2Lf�4��'��1r� �%l�+O�q��N��,�{z��|G�y!��&8N ����?o9m�Im��]X�Mޥ��r%�q�#G���`ho�%�SC�A?���w{�ڜ��1�!�p��gY^�X5j��mo�eb�f�c[9T�+fw0E,�~����F@ˤ=�Wi�u�$d�����avd��͍��Q�URW����0B �0��l5s{7�9Ⰷ��H�p�L2�J�?�[�%�x��e���G褈���~ L*ra��ծ=�
��ߕ-(ꩫ��~(<}Mx@^~-*iFy5j�� @�
�[�Zs��IdQ��^a�zB� /���pN�!�:�y�����Ϫ�Z���M�s]3�q������s0�37��c���7�{�(|�:���^p�b���zb�?K+�q7Ƴĝ��H��9�r0�շn~~�dW����6Q=c�ֺ�C(�I��)�N4)��ߓ���*��uww�������G�%�e���*75�2
�3��|�;<��ȵX��M�F��s����e��l/
�O��y��y�J�~���|�F.�Z	�Ƃ�ޘ�]���ܘќ5���^��ЕWG��C�4�-KN�io �B��z>��J�έE��K�� )�&���5�W���X4<���:Wee}�a���;�A��!�L}��1R��D�~��1"��v�M�!��ץr��.>� ��5���y��.�q��?��-\�^�bE4�]7\5!�x����j/�n��||_�uM�`~��ȋk��}��':��	Cc��ow GmP���Z���_S��1V즗6��܁����k�M�*w}a��QG�m���~1�#�}�B���+��Nv�v='J��0���B ��O`�:4o������cs�,j/�ԕ�
�O�C��bXaW	#�F����Xn�n H�K� zExĖU���z�⿨�g1�"�8d��A�2h�sn��\m� �&���̹�6���m�飔J�ɱƅ�	��rߺl�ԸfY�0��w���&����>-
mU���zm�c���[�+U��bG�i�Nb��8�d�@6�C� ��LP�0�� �:KA��<�G_���j���X�3����+�?u�y ��s��em%���5o?Gǩ�_��H��(�)��׉��[I_l���T���k�d�EB�9�sLm�e�$q��9�н�� ����y6���ؒ�H��P��p�Qk�F;J��.�x�.]U(pH%�|!�^5CU�U3L)�A�`4{4}u�ƊV.��|�e̕��K��c�=Lg=;$��m�tU���/�rkU����������YL]�I�HύV0K�y xx8ʿ6����?��t��0Wm%�/�#O�`�N��\|���*
����|�0l�����JǍg=#�b���oƥ��,�NأM_)ޭ���+��t�Ͷw9:�ޡ��y�xgL�Hϑ��KU��Ou�Ɲ���ξr���C.�ҨEUvI��nkȦ_�+q6���<ʦ�	M���	:@	mCp%�ޜDw�-w|�.�gd���nTo�"� ��p���:�5җ�4�V�������EN׃�_�'n��S��Y(��%۪�'KM����5&,<4��YiJ�0RCY��.̧c�ڭ�QsxI'���� �%��7*��a�3�6�|U��͜oE���}��.��Z�Y!:m�|a�G_|�`;���E�vF�4�6��|��8��~�®�0'�!x���)��(E��� �z�4S6W]��,�O�s�:;:r4p�̯��!�������������m�¸1���G��қ����(�H�뷝�F?XR��f���*8H[�u��K3î��ŧܝ�!O$H��HmUj�ӂ���L�z�"�V��N �<=�f߼2�yL|q���̖|*i�r�L�o��8��k��oŪ`���� R;o⋤��AšUY�v.��vW!�q#���hE�Yz.0��Pb��
��鼭[��)5�����bUX��&���Dk��<�~�z&�n#�}�h|�v>���bh��q�;����:�ۿT��B~~�Ra��R2(��Zt'��͋�ަ+�I�<v{@A������V�V�`ģ��T�����$�@��pv�3���<���]-�%o״n��H�8ciDZB�E\��G8�P�L��x����6A�]��}��gX��2��l����<M�g�t~p�5����r%ZD�|�J�t��ؠ�pb��#N<A���:|n!d:��6�x��B��ù`2�vl�.ot��+
;�6��Wu�d ��S�X��?m�ij�����t)����.�?ui�^��6�O��	��Y���7��B΅.�u"Z�5��Jf�<�V��b��&�����(�ݮ��9��Y:���w+%��N�eb�ն�h�Ӹ�2Q&��N�da��͎^��%Uiۚ�|+FѬ럽ފ������OË^G���<���FT>!��g��l�|{d�o%ڐ]2H���%C9��e� d�S�{oJDE�6����Jf�xD�����0�U����g�6ͭ�+��� �A���x%�<>Z�����9+������,b��Y�K�{�H���K��N�V4b���� �5�_�Qv�T�.��m`4gU����%�5�4=�?�GWy� ٯ*M6��lӂ�����(]~)= Xwr�@*6;�Xót���Z�o�����p�`��7�oF�0k�L;V=��f�muF����'�5�g�΍�:TU��A�	.��L��d$���
s�s#�$�cd� �G�S�:���?%��k5?����u�6`2���)�k^���AW_\�C���e+a�g��!�Ƕej����d�Kุ(ם��Y� ���H�u^��r�,= _R�<j�Es!�qB�G7)��*N�zr9�B��1���/��錙�bp����H��W[�C�J����^�7tWޑ�Ӑk?�$|���������㸲)�/�Bb>���(�C�y-���c�r�Z�"C��K�-}�_R��|xK�I^���
��l�ުt�Γ4%��T��:+�n&j�$���� *�!��}r}G��|���6�.=�ݣ(z����^SU���x���^��#��;S�s��?6��VQ�,=3q=I�I��3d��ߑ��ܧڋ�4��   �l�j��{T ޱ��K��b��g�    YZ