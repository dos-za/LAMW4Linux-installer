#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2028677705"
MD5="9321ffed83f06e4dbe3737769a6050b2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25984"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 21:59:40 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
�7zXZ  �ִF !   �X���e=] �}��1Dd]����P�t�D�#��IygO{t;�n`���oɢ��g��t<�{��#�:V���_���xo��g:S�9�����V"�U�� ��-�'�K)����2��۳��-�'����������ax����O���13MN��/�}�X�<��!푬�Q�A�ި'<H���A���5��\wM.�>'m4��6IŸ�
��~[!FHD�m�F�I��;Ɇd����_dK�P��������E��yq:��@�g�ڣqlL(llT����M���GÞ�)yY��U���QVPu�:+j��0J�����eN��k��V{�s�u}�^`=M9mtd�� ތ���a�c/����?� ��n����b���R�<}E��::�p���L��H��\��X��� ����l�j���^?�#��D�=Pl���+=�� TUڄ�MQs��M�2u�$"��܉u	㻅��u&�%ED*Z��6f�.�Ȼ���5cLQB���X0,M��[k2�V�$���>�j"�ٯnЇ@4>�nzۄ�U m Qmx�����q����R>�6Buoi�-s�uN��<dtBɠ�H��1ݡ�P]e_�`G�B?�P�w�	Y� �L) cҸ&��ͯ�A�F��[�{;��?p~Sr
W"��,��]����<�������p���g�*"XR�\��Nf3���q,"h���V�2�.���)k�pc<9�X� �`�:��0��\��S��u���C�LI����mD�w���X��`��3�P\;���`�J&A�S�&/�B��[�ic��y��?ąA����XZ��B����� ��㬘�^��\��S>���rPR*d"����,��8SD�T�<	N\���'y��Y�����ū�������p�� ���;_3}�m&a�C(I���7��A2����"�2y�?�}�%o냠��+�<�jz�1}�P�u�s�V��F�d�w��l�w!AH�������~�� ya����9�;��9П(�M9�������'��ϐ�κin~!b��P���E�}Y��{d�qO
Y	<�0���p��\`�E���}�M�N���&�f�h�r�F�$W�TkW.�̯:�#Rkaz��\����B0�ƵS�����8���d�1�b\�S=!������%�C�(�ƴ��|��<��R��B�>:ʕi���k')���:����m�(�?ś�>ٛ�;t��5��i�����O��ج����E��ޱK��@�	E�O��;p7����K&Ǹ�M����^�ڶ�p*�p�{�;��ԍj��,7T��Y�A*g��a�����c8X�4[�5��+�]��@с��nJ�5���k�Ҥ+ͷ�%���{�BD��1
�
rb֘s�&�$Z�~�g\93�L,7vy�>�G�1�c8�W�x��maۄ@�A+Ո�*�����C"r�6R�FG�d��
�nkp���`bE$���L]zF��h��W�4F1_E��ڕ�&{u
�h��%��
2~{��d��߅#E<h%��Р>6�[�~���ݻ}��D<}[G�+������;I�P|���zK&[�_���d��<��m$0` W��8�w�����e+��Bc��wm.M(��y�n�n�)���~��-��*�w̯(�kؤg3�G�T�Q�����z3|v�͜�1�*��&� ���(����� �D��e^�@�I���N�߲ �".0����-�N�߅��5�j���B�a&=_,���i�.5�@S.r�n={�)T#`mw�.����4�:A��D,�@���W�,:�>�9.C��b������(�BP"$ �E�̝jl�C,�ָB�T��ũ���3$�f�B�}��~і#2>Q)�<���������b���L�m�V[v&�=pV'���� �70�`��"`N�� Ʀ�E��幰�K���j��s���!k!T+:���h4y�|��#��7���7�p{ ��T�:|۲��b�6�DI���R8tƔ\Te��Ӫ�'��}Y�7����m�?��D5>a'r��٧_�v�p{)��ӼBp�����{KW�Dm�\�#��c�`��x�Q� :2 ��ڃ�p���]�W��%����+Ƭ���� ��Q�[U�ߺPe���,'���U��(c,�͓�F�`���"���e\Zl��(�0��A2�7<ʟ O��φ�Fa׳ˠ�9^G�zVS���@M]������x$ڻmM���5��C�{uW)���K����H���a���� �˩��ר/�k��%Xƈ|W�!����O֜��>/�b���ڙ�dG�d'����0�������r�7U�ޙܘKIut�(�{Y���u��'d4v�����>l�icuD2/�.�	��>R^M��;�wV���W�_��yK�Q���(ih��
�7������^q>wW���hu�j}G��m �ΡOR>��5�,L���>R���;L��2tCPݝ�*�<pt6�C�����s��7)]��HO�x3��
T���gq�a� 6����d:��!I0�QJ 1d�T��)�?i�&o�,��H�R� C�e��>�r�?�.�,5��N����Y7vVo���ܗ@qH��U��>{%����V"�}�`2��S1��W���;�DUNR�BM�.��&�TŶ�fW���HC�ɔ�ݗ(U��RO\�}�S 2�\ %��Akl~��6��`	?��Dw��|P�q��\/=���q�5r�2o�M 	l��@�X-���nf����ick�Ⱦ�x?P%=�
��7�&1�/x�� &��n5q@����+�;Tn���*��&�Sr�D�tAzZ[ò�b!X�]���
��tR%���U��0"ͷ�$P�����O(6�� ��{������r����3/�
ၩs���#K�O.�o�s`�0�(��"�dU�]'փ:3����H�zw�K?�ȎPԑ�	��3�d2��b�fJpG�3�E�!�h���͔�'�)l��Ȕz;�KR�����9�B�}��)5<�@��Ȃ�>����)rh�8*|�L(�����e��R����>�~[_ʁ�8!��RjX=�F�=����t_�O�x�Ơ-Vr��eX���pbI/�|��{����m����	s*)�+-Ǡɑ6s�#�DE�Kee[��-e�ꕧS��(�����CU��+�GkB^�����bC\9��2k#@�E�IO.������)[��K�Z���+{������*���k��NӐ��n�
�����'!���x��)h[-�V�_}`B)&7{�iV�$'�	�x����g�׬%�ߑ)��yt_2{�+�&P?�4إk����ջ̳:i��fW8���3se�E�6�y�g���]�����`OG���&X�ڭ��QOe9q��)qQ^3|�b�Y@W�r��"7�cvo���@��rC�E���A��g�sJ���d��[4�U�o�5I�Zl�i��(�����v��\A�UR9k��̣�jo@e|:�Bx;a�Κc�hE��Mc3*�H�Lר�A9������W���S+�%�n�J��9f��Kw9q��"y�2����#��ǌ���"�ؓM�{
*D4Ba�J�n+��+�ڃb�2 M*Qk�]~|���
���c(2��ӽ���ę�ث&X��*����}��&�G�������X��� �ɽݮa��a�ۃ����bj�[�E���@C"K���Y]J��P�7P��덤T��a�K3q7���=`)K�\G-}���SL��"�h����Q�ƅfy� ��-�.�����#�Ս��Z�Z�?Eڜ�C��3�l�A���M�Q�0T5���ό\�$�.y�Ԗ��U�#�v$�{����ɢ�G�k�?��]�k[���2?������	M']7��)�>%	,&El��i�C2ք�gb��!
�JO�
(��z	��e�\�!]&�a_n׮D�N�3QМ�ϓ0��e���?J\�_⻌ߍ=<�,߅�)O�(�b�l|�*��貿��|�ya��-!%aħo��-Vb�0�6!��M"�ϲ^��;���Eh��B=��[�J{��]�9��h�klx6@��x��(Z���!�@C���7���L�Ը�oK��P�n��+
�ag��3< �8�𔣡�Sp$te�|!d��~E4�@�ms���9;[^�S`�m���F����o*���<���9�D�`"���E��Q��u`��CRF(�9�G�?Y�>����״Q����6B���[P�(2s�u�~�`�nƑm����P�ᓲ�{��3	 ��O����r烣p`���֯�����͇���3��ғ���Z��Ł$��,z���SMm�L��!|B�^���\���?�Y�TV!�\�������ZU
kj�,G�МҠ�4����}�^���3�������R|C��s5� j�9�[F0�3!���#������B�q���\���ud�X�#�+K�S1��{B��A�SoF���|�Y��d�G���6�Y�2��:1N����+wW�Ŕ�����~JnSce�b�~2�3��or�Y�@-�7ndd�i�X�{QT���>�L{�~{�b-�o���,%�j'ƊQ�oN��r�z��g��r�|\KB����q��ceR ��1���[��%aV9G����7�9�Fl�<�,�|T��V~h��e����7)��k˗eҽ��
NS�T\d:ւR�V΀tMdA|��M�Hy}䀦X�g�M|g6��SW�Ո�S��g�ӜNg�Ϝ�������<�prlg8Ґ�Y�����*�$�+�� ��n5WK��7� J�,��GY��+��TV�c5����җ>�����[�h�óK+z!��IĺtiQ����	&��D-��T\Y�w���j�&]��$|�#��*�l@�'΍ąr�TCyW��e.�/P�M�1^/O
�sU������^k�:ǒ�?�&Hڡ����ǁ��\U��b�3����9$l��� �U�T�a��#��ui��np���|��KK��rF6�d��8�:9���#e�����%�+O��v.�:�}?�k��<v��^����������*�F�:���}xahi�,��f&�zo��W��ц2�,C)�Hg�	Ó�@��f|�i��TU�����N�<o���3:�&�7�ù3���`m��3�N
Y�A���~��Ut4՗'V/{>Hs��W7��@a�}���C��'���&ī<�-��{ܘ���(T�.���N�Φ)$m���#���V-3% _|�R\��C�4sqX ��y�vy�rzi��^�O�I�*EL�p쓨�U�OK��֋Z'�3F+�TX�W����L�'�ɒw�)�ӈ��b8���!'��ෘt~`�6�m
�,��D�֚���K3�����B>כ00TZ(�]id��k�}�ߌ�+��r}���ٱ�s�rb��,����XJ��^I���!E5��`��+iEp;�pN��.�뿘rb���OI��{*��Ӄ��@��yYS?�A	@����b�odDY%�Y_RJfɌ(�m���&�GP~*��|�ˊAe���E��:jY�z�I��I��GYr߱��[����[:htL��CX`Տ_V�%��;�2t����Μ��c��p���;-��)�ڧr�u{��PC�h��[�R�̲���Vx�2�� �Iԩt�XP6��CA���x\9�q�_�]����0�U�|"2��:K����/^�^V-W��� ��ظ����H�Ԅ9��jY������pq���t`�+�S�3��IG��|��>&h��J�&��?Q�<�P��h;�� ���4����7���ȉ�l�F{]p~m�OtՄ��E��U����&�w�m�������<A������8�O�t1�}F.*PD%��I�$�0O\#�b��j�[��q[��*Qq� T�b;��ձ
��C�e�ki�"��,�!^����4�)I�4jX�JK1����ѻLwm=ܲs�����3����e���lf.m����D$Cj���O�}o�����܅>����g��9YU��U��ӹ5L18��x�5��g��q r��g�H	�>�=��i	���{��\�G��耉YdA+���>�jv�h�Z]/��ݎ٠͹��_���]n����u� UƐ)��?3��N�ޗa���NL��8��ֻ�j�)6��1�c�x��V�"�L瘍�Q�}�:X=R��ܗ�g
���˲�-3*���*�`	�p��;y,x��RgG��)lu��P��+�4��~��T�9�g�������n�
\�'o��e��2L'����ĉol���� e����6�(��hU-M�9�P�8>T*5r��E���P��$4�_�	��8x
�7Y�P��!�a%1`�㆑E(�HB���e�Մ��g���~�W�`+�s~B)(�Y��0"Nx������6;��� �%�XO/���9���; ��(F&gn*�b���o���� �W�)-�׹�)�U��Q./�+��	I��[X����[�E��`�A7���.
������r6*6=j�l�D=k��ۧU.ZfhDhz#�����Y{���9l��wgQ�Z^
n/���ç�q^F��o���U\��1f�:xRME�[���x�w�3����ic��zK��ȇ�2�����Z�}^*,��S����߇�.���k��%�\�Ną<K�^�q�F?f��9�nڠ���{!�À�-��,+T���J�q���G��;�E��E= K�:�<.�U�����H���E��
b*��m?6����!�Hf�ȸ���)v{�Z���(�{���zJ?��D5BF�ǘh�����-�F��n��@4Ð��v�>@�BrT�dg��s��O\�L���ʹ� �:��� � �*ls� ?�e3q��/���hU�3�>˔�njQ�Q}��Q�r��4�Nvy5I�0�S�2+Xb�B�6�0��rr\ե��*�!��ݐHSS�$��6��Z�l�M�d����+XZ�F7�k÷����y͉n��j\gU"�A*4��ר"E��s�m�p�Ȟ���r	��#�(Rrm�a8����g�L��hA&�T�]*�	R8�A�L!��a�G�����eM��������B����\ϕ�0����S�ک8y�ͫf
���weE�o�"G̊�S��̀��E��""ɺ����,t��O��q� i,��Sd�- �8�3�Αg��n��ѿ+FaX(*tĂ6c̌�D����n(N�
)~��{�O@����2���Y�|ѳ�t,��-�u)תbBv���6��ܝ��L|U4|�ǅ)f����U�^a���o<"p�
 Db�(Nq�P�*[a��H�^a��O��DUaX�����(�~)���C��(Kj�7��%���˃�?�)jFf�Ҍ����%q�l v�T:h%����r���fJ�����	K�6xG ��i�u�3�0$=�M#��bE��kJ�+Eg�S�2-N�5��Jݧi���_�O TN�vܷ^+D
y�jMD�;�>6`��T�B�ΒT�� 1]B˒�}���R��u��],�ڻ�X�q+O���o�e�9�fIL����s��~�i�p�?SHL5$-Q���X�ؠN��N�]�G�?��9*(�d�99���S��\xؖ�Ԣ+>��l[Z�d�����Ξ�Os�j_]�)gM��	�|���M�a��0K�u4}x�^�t����\�Ws8� S��f��+��0j���D�C;��Q�4ș�w��2@H��> ��2�`���B�8o�$�ߗ?�Y�b��_��A������A4��HcLN����^�$ Ј�PAض9n�{Ft�X=�L%9O���Q��C��U=,e���ss�Ő���ci���*�%�]e���ₒ?b�����a��0�W��?L5�]o�M��͔�ᦧc������:�m��@�������R(��w���
�����;�q%̣^�A~��mז�*��T����ju�c�qSX��OK�-O��ݪ1����Q�My�L��%��+�`��9��0�֩��6n�jx)I���sV�{5�(����5_ �5g��^�ƅ���:2���Վd�0	xD2#��`Y"�X(�_\��7�VMmX�FY����E��pG\�`ƿ⥟��E�ͬ�$o8T��q���=������ڹ��z*��u)���Q0�������Rp)�@�νX����ݼcO�4��'�޼��7!����(�t`�#�?�1u�8����
y����DlⅩ�Q�[a���4���&Im8\6�v aq|J�^�BKƂB����tdҾ������U˛������z�Y�J�%�*5����L���Ӛ��m�z=���0�W�GD��rR]���3C�O���T����rl;��:�����W�:�d��\���f>o_��Z�2U�]���^�Y0|�G�=�� p1{�?��׿�c�ŝ��S"���^L�4��,�H��SМ�h2I}�����|�
���8���ڕf�q���|	k~�[�����t���x�g߀���L03ZH�3�p�xX��TM�`�!g�g�w�AE�|(�[�$Wh���1��S3Y�h[`݋��ȍ�O����Mx ~�>,SOIS�P�ֆcC�4�9o �ë��LC�-�\/�p��n'lm?sH&o�𛵨ҏ=�{�����ͅ��{\�>���y�^2�G[�BSn׿8��������Cݕ}�.>�Y� ��QV�m��+I��;o������y@d w��44_e��8�F4��W�o�`��s��
a���!�I���\����j��4'�<��T���O}`�+�c.�ھЦ��[����2��8&��t�>=�(��U�Zr��O��p��~I��&���K�"���i$iU]�-EeѫQp���,{7�9�Q����F��]�1�J����T%����E�(���@ГHC�&�1�Sަ����S��p��L�6�-�@3�#���7%OC�L���7�Z�������kD>Om_2�u5_M`QI�i��'sԿ}EC�f� �1��:{��R��7�`�US^�Q�7�b_8E&�	&���2���{-��:�����!jv��[T�������3�r�V�s�|�Ś�.nv�,�Kw��O�(p��}����I`��+��q�t��鶛`�_��QZZ���~��cv���|�����@��]��
h��ۈ�B,z}�^ɭ��4?>��\+E���U8��[�����ը�IӭBH=�Z��&?�V�!���U9eш��@��������� /�����<���g�,��`�����
�FY��&�4>}%L�� ���h�����Ї*m��q�����~	�Y8�n������|������_/�t0й�'Qd2��6Z&��v������>�2�i�s���yXXPӿf��`�w
���c�� ��Q���	�m<�IEŃ�.D��DG�#�V#Q:0����v�_����[-��!�8xE�i3+�51�9��,q�.h�.�.^��⾟�V�:L�~]���}~�]/cc���w���U'�H��k�R�{<V�lI1�А/�#����o��v�ӓ�T�����}�D�N�
���E��z�ƖHT)��7:8ڂg~�;i5R_�a�^�i�o�B����a�r2߇���S�	+y�W
!Y�͊ r~f5�z��z��7Ke�%�(z�Hb�@\T�sn*�K.�j�,O�w���
�<��*+�8v���X�[L���&V��>����H����!�uI���t{>rB���/�c�Ê/t�DAN}�f-H�0|�J�&�]f�lhԙ��+����B�o���j�H`�t5�UhȇRxc�'�nS�w�jN��
����qG��D�V��u5p!�����jB�$��t�&L;�d��W�����Y~^O�|���~ҼFL	�!oSMߛs�5�*��XN�w�ƨ����%�z�f5l�U��.4���%�VV��,#�	\��E3��:!!P��"rA:o�ɣ����Rɳ���ξ~i���:�L������/�J�T�����e��m*����Q��\pE8�������|�Q6��d5#����}qa~'��{����#տ�%���1�h�]�"�PUһ�fN�Ѕ���>K\ZE^E�T-O����_��ee�~HǾ�"e3^���Z��˗��T�Q%���$�r�)� 1���׶�i2�����RU�L���w?���?�z�lR/�xDnBB�.�f��Q��\��$�:*�!b�ap��\q�K�EV����YoF�;#Z9I �e��RF?6�:7[w�=j�嚱�+�_���^�������I$�(8�pv��R<�(I�	+ieÉ��Ϗ�B!4�/�oX�����X�`�?��V$C�"ɷ����"�X�eA
�V�5�ˁ.�G��i��%/1 ��(�p0taN��fx�@�>�9cI��CJ��
X�&�+9�d�B0���:���o��I�	+C����ߎC�O���	n+B�����P>��P��q�*я��Iz=Ygp�X�'X=C�,Cy�Y���l���J�)��H���:���UXm�k�޵�S#ˎ�Ș%����Ԗ%��n�-�kZz?\�WE{x�i�kO�X�V'h����)a�[w/|��'H9���7i��Gq��h@�4l2`&���׳���ދǳ"�� ��Y�(0h߰�[I)-v��x�y����l�^��a�4Ŗ��S�*H�p�����1���i������>w.�Ѝ �jh&${aU�6�u�2`�Q}x^�c֘j��8(I/bS�р�Pa�0#�tv����'n3�m7�pz	�u(-���<|��]��8�F��ѻ��w�c�e��k���J��j�=�
�-�O�ݥ��_JDJ��Zj���G�+�n\�����;��G�M��w��uz@���T� �4QQ���7d'���ԭ�ϲ�:3��}���Yj0q�e�N#��������T���E��J�9J9�c���J��4�ez�a���Xg������)K�+�~ ��W����;4��q-8�=�) Q��C����QI�����hQ��!�[���IZ��u���(�����8��6�sw�D t����U)��j���F�΋�͊��{��A��h�A��@��*��*�*�^��{�'�ꨠa]�Tk��@�]�y���J�oT��,L@�Z�RȒ1�yǣ=��-tJB pMoeQx�5�&����	l�#���h`�֏��V|�p1D��Vi �E�ia%���k���EH�fn���m��v@V ڽ�U���'>��X*�~y?-�Q�l2�D�,zվ���#ʋ4�\�:���oS�w�������5���%�g�%�:ޒI��08oAs-�Z��idHDr��/c�ھo�'l����~���ݞ��Q���K��n��l6+�2��.oK�T�v���o�a&��5�XWPF�L9W:�S_3���S�)�%&��1�vž�A_�vM�����գO���2��4@bmH�c�]���IQ�C��H'k����%�f����ɐ@���37��_7&4�c�4��¹��i�Ȼ���JBk��b�v5t8�l�#�I���8�"~<��;8<���8�Z�D�RZ s����P�FCV��jvԄw�cO���+9����"�rމ7>��t����|�@	*:/��8�h�������R��������O�$��!/#'��-�ů(C��>��4g�~:�Xl��9\;���7&<TI�b�3��/YR%�W�dWp��X!�*w�_H��
��X����?4�'���y��?��L�ބ�W��hwv4]�r�/��5��8�s�k�͟��,'M����-����`����]�w�G�lc���.�_=�oڢ�Bϒ����F�Pb��dI5
��ڼlh�uj�ҁ��D���E�.��et(CÍ� ���ȉu�4F.IY�Ե)��F�m�|Mu��~��fs:��q���&��)9��2R5fDg��*{l�Y���X _{6D�<n������T19{U�[��@5�3��.I�C0�2�R���yH`MQ0�ُBQ^�men>��������"���b��ʑ��k�
Ś@j*_���D���þ��DL@���@��o�7Rɗo��S�UE!*�$E����5���2e���^�}y��΁ž6`Á���d���3P���i�+!���K�u5ͺ~c@�v��7��P��JbU��n��1(�+}V��ӫ����p蟮7}EK�ј��#�Io
���[|�+K����4�A�3��@�H������?�n��*�dX�u):��y\��)���׺#j�C���@���",Iq̙֫#P7���$(7�[���#t`���b8h-��L����!� .Uc��?�$��8�ܝk���:kt��ݼ�:O�c��7q���d��NZ����"xq]lN1���ȶ��Y����.��V��#[p��r��� t/�>��=iCW "��*��m���Hp��:�ޢ�Tp΁z��~s6N��C�p��;�x�z"�D$J�g��-S �h���܍�ϵ	qv�φ�o+ƙ��
8y���O�px��[�!T���*}Q��������r�z���jwH��M�i�"E$���o�����GuR�"��fp�� �=O����ڮ�B�r 1���l�.	P�W�rb
v#��o���O ��,�v�u�!z�k���R��T'<:y��6����Ш���[���D�`.�yڑ��˓���{j��pU���|5	��I8�/p�Y��,��U@�T��v�f��kllXYQqKz�x�RÉly*�rO=[N�ܲa�n*}���=0�$I>l^y8����d�\�X��P��>،b+�:RP��U8��v�^|�23�_Sm��許;��*�G)���'����=���J�i�3>54�Ӗܴ2��IE�*�~��yKA�mb�H�!ܒGa.�֝Y���2�
S�27�w/�7L�S����r��}HɏQ�5���@��kk��H�um��CD�>ޤ��{��G�&ޏ�%�n�:)��w������z�Wd�!kHZ��ۀ�R8��Ro4P��Ӂ���4)!ӌ��0@���uӺtLK)n��j�L.~���z�`��:�6�-�لZa(C� ��@�D�c$����gB��zyxz��+���&�� 	���x	6��~RԒ�C�@m��,H3P�	jP	�r�(Y��'��6���ݓ���g��`�զ��@-�����6C� g`��Ơ؛�Q��Qix6�����&s��a!��q�`2��-k��{�@;y-Q|9o��U^	*K.�~Jϝa��&CO�~%Xsq�|�p��n�,|̲	���Za�,,c�������?�ޭ����P=c҅�%���y�C�u6���u�Š��k�g��T�p����3����gL��3A��z�W=�.}f��)
�c��:���J����ϏO`��hvIԁ��x<����X�n�;h����G�~�u�:��-WDYU�q+]��.`#2��(�� IcZ����5�(���V!�L��һT���ƞ#6=4�K�T[��Iq��[�ڗ��(ꤾ�a5�Qp�<�iU�0��5>����X5�1^��J��2[�������|aJ�陴!�5n�sb`Ǿ�C�1��V��)jZN��?g�c�i)�8_@�W	b?ro��QO
&fB۸��GfƆ��f�1CS�.�ѓ)�b$�DF-ɹ���}���MKo
��u�j��i)(\������S�T>hf����G=;4�&�R��kr(��t����(�$�N[7X��7���K���5N�|\�|���5Vo�eY�o=r�U�^�
��Ց3?�oѺ|��^@�V�`
�Ͱd���9ݒӝ�m{Lhj&鄂[�3�έ�\#�#L��W�����i��%m�4�Oad�#�]�cG�`2�^��g�6��i	�=�v����Y4��{m�f�4V�&ox�x䎾�KF��������R���+���wlq�e�pixet��r��g�튛La��T�{B	��ʑ��Pt�����������Ђ��(���7�u;���&Ǽ�~������L!�%=)ĺ�ݻc<��A�yla%J��C}�F���Ŝ��~�,Y�����+�a��5g'f}�N�
��Sȥi���j����S���Z��uɶ�L"�gib��t������ik�3�����y��gcі��	mǝ��:�r�G��|}ٜ��1NS��䩋�S|9�����b�x}��VQ
���2�yl���ti�e��M5��Sw��	�R 廿̡�iN�ڠ��	28�A%�����
��(a�p?�Q�m[u6�]�7�j\��jOB(j[��]��0��ʽL�S��Н&�����?�gn��\�!��vV�6����n� �:$�!�m�ȵ<7�����r����8�c���{�%�wO�_� Z^Hb�����כ
�iպ�.1��Q�����W�L}��#Cd��PI+<�>�b0�/���"}v�n[�K^ɋ��בS ڋ���w��9��Qxӡ����9מ�Q+�$ߙ)�O�d�2{\�i�泴:+�13���nIYx��ܫ�[�<�Q��CRrI�}<K}��Z�%� �^��$�^T��8��`�ה]�_���� �������SLX���\K�~=�i����q���P�PՍ�w�����Ů%d��\`���G��*́Г�v��C�������:��lj&�腞{=GU�*�5�a���En�b'�Q-�:�� �B�S)���゛=�{_
 ���7�ȟ}������O1���#�5�Y�i�Ҟy��A��u��`�s���Ao�v#;��rs��;3����^�vU��ڴNf���"ic��}G�>�ЛDc��0�����qA
Ӆ�1�,IZ��ٹ�Gi�)�s ��_�{��6��=H�2Y�m�0*��br��֭�8�YQ�8�	U��$�Mc��)�"���:o[U�'�/��\'Ϭ"�c���RN{6C{�ﴘ��V8�� WP�&��z���.�n?e�8�[,-�"%�;�/>���X��P`�^x��JQ�u �i�;�rGF��κ�$�?ٚ$Q�����&T�Q���b�j�v�|��^K��=���4)vf��2��~.pOx�,�SS|I�"�=^=V�B�|+���v�u��9��M,l7��R�=0jh�����8XMe	[I�����2�3�%�T�E�~���`��\,
9���D�㺋�����J*q�π���9ٗOʳl��Z�S�g,�id)�T�G���\�h���6[�Vք�A��b�f�JN��b�}պj��O3ߍ-7��W��#���iv����a͉�VTΝ(�����_Y�֨��E:��e�O
O{.�q�)$����.��h�����o���~Ul���B�T;��1|Z|m�#'�)܆�P���?p���E�4��q�PiO���@�sk�)w�K�xJ��֨���T�0��I�ޱ��Ǝ6b-hU�pV8��;��f�"���A=rܯڑ�^l��(Vb �=����~d�S7J�ǃqI1�ϔ7+7~�;0��KU}� �ߵ�E�:����r���7Y�XN�%��D#�u0��E�>'� �<b�<}cZ[��M��Z"��������֟_�t��~��˽�W�+��r��Qo�S�7ٞsv>C�L����� Q��gkq�h�����Zb�n�kr���K!���p:�W���S�9�d�j�� �s�
Q.�x<>����'�%(O�H�qO+7ڽ+�M�&e�X�G��(c�:���❓hKyh&��m�8gV��U�|�� S�����8�[�0$/��~��W��]�ٳ�2W<����NTZn[�R�y��u�|~��V���)>:ֳ?m���u�"m�p�g�2��� _�r�yI�U]�����\~��;˫ĵEl��d�����[,���		fW���6��JH*>�D�����Ǣ.���!Wx9�����td�-"��R�͆A�B��j���d^���T ��y�PjXD��Gc�RV�TYl���Z�����K�VV D>2����:!>��0匮�h��Z�D8��~�j1��	���s2�c=��S�ax�O+���s�5H�$�=��;������s��a�L��>.����<1.,v=
S*�;
�S����e��ǯ�;6a;�-hpq��-�«5;�	DT`  ��~(�Bߠ�MP���B�������P��S�Xh��ђ� �ś"����ffcWPܑۢ���7+�Z8Qar�9�PI�aO����]-D@R�I�^��s��������>C��.������17$�W�����H�2: �6�u�y��9V�<�7ӟ1����W�%-�{����G�}�"��W�H������;����T��
�}������i� ��� ��̫�(#�2=bUpMiP+��tyug[�ǲ�i�����������+>�>�y�I�X:6�]��(�L	.6fA�(<�[�j�u�X	�Kb[��"kg�i`��?S#-��Ƭ
a;5G'��^�AK�Klv�.�ʹ��8�һ���C�X!�ҩ3�,�����l0�w��	�P=�K� S�F]z�xC�ꖾC��l�tv o��Q*4w��
t��IX3l�L�t�i��^5�k��{�J�o�[a����{�!���ފ?s��4� �P��?�7��ַ�|��F�0@�s�Rgy�4��887���
� ���b'ݗ���&D�;!j����m"��%�b"Ir~�%�m���4*{���*\�s���g,���9\<<�]QʧMX��Blט���<�( n}^n�9U�{��|��������]I\r�-���2�vIt�������+ z��'�"���4�m`��D�%M��a���!c���]��K.1���_����4I ��9U��{��y坍NZ�����s�!���Z�_QT3y��'�c{�Bb'z��Lp�~��n�g��Vg�[ nNQ����UJ��}[0�<�Ԍ�t���R�S[B@4�u/JE���:G�B1x�%�����:�kfzG��g�'7c���d �o�=�~&��-:GCV�f����������.A��J8�5�m�Obf̷烇�K�"�o�i)VY������4�	M8[�M�j�+��]+�R_��5.ң�T?Q[�߇�{�|��P*4_���
�:h��l�[TD��)	�~��[ ���M(����@媢��S�>̄k���Mc�������M���#��������ܺ-�Y��¹��5;	z�q����%�M=��C�����P�Z�3�uB��Dܐ�DfLrtM]	��aGZ����M�9�)j��ɗ8�媛�
4��ers�(Y�8=��x�;�x�lJ����!QG����a�	*�����>�=��)�u�:oY�_F���`B%t��0��T-	��,��de�\u�\�����؁id
F��V��[�|,����)v-�CҬ��(��oR^ۑ�CL�?Ρ/&鐂����_��QS�X���x9^9<�J%�)�P��U�,��e�2��/�|���=�_���j�m��U����n��$h�
�-E�qT���	�	s��A�.t~�˃k������~T:�DZ����&�l�&���YY�8ǫk0�E,��0��./0�ۜ�[�MB�:M�Sǃ�5� Q�`��襻z�b1=���!�wzbu��,�8W�;�eī�降<���{TW�8+=�=��Ob=<�"�W��_e�hy��{A2��}gSn:u�����y���ðP�������ߔO7 �J+�䗎�h>�c:ȑa�Hn���X���'M�B�χ����Oo�����U��x����g~�<< d�!�dcS��0<����m(����"2 �T�;�P����<M{�tȩ롻eŽ�~P���<��򜛉�A�L�ճ�__W����9�Ux�T&<�a��j�X0�`d��I'��&���!)�ۋ�2N�ݳ���gR}v�j��сܜ���ǡV��P��ۋ&o��VK}u�AJ��Cw���h�~6Qx]���[y@8T��Np�R�`7���`e�q�������5��("�]s���h��O�{�'�-�m�О���Ď.\�R���tP��3o<h_f��Y�����W�1���@Ǚ����i�s�eS]� ����;��RQ�9�E]r�?��"c���_)�3C׀�;":8�����p\��M�t�m�Mˆ�[��Ҡ~h)X�J�x�y�%�ŖE�P����z\�F�T+	�h���o����;�C���HpCߑ��p=�*�$G�"mnx�%OE����QIhyE^����P	��15�-E��M�#��OUI�4d5�(�c�LfX��L����.���K�����-[�3�� ���U�t�'`kIXT���l�7H�J�8�k��V!hgW�wC'W��>�u?�Q�[�yRl�@e�S��)���!h�ܻ���
ؼ���iN�����%D���FN��M����`��U�=ID�n�ɿ.G���Q�[�<{b)P|�QkJ��;��ꅭG�"K�AŎ�#���jv����C�����Y,carP&��7�'x�������Pc^�j㮶:{b��w�<%�l�E�64�Uh�ʛS7�	(�����t����	��y�BփQ<g5�B}yӈ���!F������j#܄$�������`Vb���eR.lE�oU���t�%A%B�b�����Q�$��
�s^a�7�-�e��M���Q��A�8�.h(�;y#���ݜ�T��!/�*��zՎφ����"f!ߴjA�!��U�nC!� ;��?-��%b�K=YiES�퍔P�"�sB�E�����S���F`�8�E���W¼�_�B�l����uB�]W��{~�&S���0b��$��o")�
�j��YI+�r�R������H�J�23%&=&�C���R��[I����J8�S����A�w�6�l X��w��%^ڲx��t�>S���ɨ�ț����F2�Il��Zڪ���&�MfA�|�(�����l�(�"������=_�%q����Agf1�%�?&U�y����&��Tݺ���������n�:8s��+�J�UHc?�%?)	���S96�fOB�K��t�ʢ��UD>����_��{���iQ%�ы�s��_��
�������Y_j��ł�Q��v�� 0��|��g���=&�-E��؄k���5oek�
U�����]:�I�����?*��ߦ+��8���%��޲�d[� 10ڏa�?�#��7�r֧������;w4��~�J�;`=zfӀf��+�\���_
���an��:��}�;~�q��F�#ьX^4"҄ZE�#���߬��d�ݲ���zj&]"�@��txl�Cp��_�Y/r�� �l���⏶���-���j p|R�<d���i��]��e�\/rC���?فi�l�|�p}�.�ߺ�w���ǳ�7Gz��i3d�x��0�}7�_0�ռ��щ�D8>w�g���+�z����Mej�۪�8���?�v�M�ԅ��+����(��3��o�uO�W7Io�>\͂),�)Fq��N-0̦�;KE 3?�ut 6Q�Ap���#P<!����{����ѿ
�l�!��:�ó�@Z�9Ӭ%�����7�Z�Q{�#"� ���f6�]��s~=��}��OT���`>e��fG(�&���e���(��Yf�:��i� TjF��7�p���/�/���m�hw���{Z{��`gaD���?H.x����pR*�#����UcE49W�T:��տ�{��,f��&66����(C���^7���ƿ��a��	-V��vPۉnp���	U�jX�����!Ӫ��+8���*GO�lUD\�a�jg������6��RB�:�\�����i�v��,��ȫ�cT���6tG�+��)Y3B��P�M'���;~����&d6���PǤ����k�}gQy���4�"�[_��>sl���Κ �I���\S�!QDB`;ЦsKG� a����O����L�H��/7�;X'���Я�0_-�,�b��{�Ţu12�.s.��������FV�w�0,�O��h��lZ�X��������	�z]���Ft��P�9�jLT�������cHi�A$ݏ�4Zŋ4��{�F�3�U@;D��Zs�\av�1�I�4���t���T��yv~�s��Gk	u9|�q.�:��=f�<�	@�^EB��UL���D��pm�G����m�}U���SK�P��<K'%��L��y�L���БZh┬buN�oq;��i^��_ 4q�L:T5 �����>L�Þ�q
�U�
�՝�����еC�`b-a���������E�(��ߨ�Z��@������H[`�\ᝀ��_M��7�R��Hz63�I�&�Ɛ��0�9� �jb�+�Ċ矸�(ֿ]� ��! ��XB3AW��C�J>�H&v��n��_��P>a�ޜf*��q+���׬k
����R8�/��G�ڞ0B�Z�D�֌�P������w���+�O=��1H��� ꋮ���V7-��s�T�O+f"�p���d�c��TH�Q~�3�cK�8��1����z��S�k�P}"iv�f��)Y	_�t��?�?��)��XL̛潈ҏ	[��-� �ù�E#�Ȉ�0��BS��.ܻ�պs޶d����
�1�6��g;��V&��ђ��̂�Z6�����]TZ��ҢMC�J�ߟ!�E���e�߳�ln�0�wd��Q4�N(hvCl���QuƉ~�k�#�Z��3���Rp/I��\�16#堰�~��K����1�	&-�d��i�RL�ɣ����6���}E�m?���\�X_v/b�)��W�y~#!�ྠJ�mЃ �H{���Юm����]| u�H#�Ke������j�^>�U�`}�\7-C�L��T:�;7���	����B��ߎ]5)����Q<}���b��
� 봮���NؤԴ"~���Wff�i>����ԬR�_�����p[�}<� �U48Ɓ��7|0�M�=U��n�շUH����sNv3}�{ҩ����Z��͵�Z�?^�&g�5���R�w� ������/\���Fr{�������Q���r ]u�W	���*�ɥ�dH�q��Tp�C_д�Hټ����*�9�hY�V�|o��)s�@��i.��ldV�*V�S��
��;�D��"K?l���f�F)��Zh�[��T��v�zN��^���� qy�}8���t����t�s�a�f �P^A�F��B�;��f-@�l���l#W$NsK�*�� ��Ĳ�{�]0��ȍA/)G	~L8�6�ywZ?��M�-��k�觪������I����L�/����?ؚ�sK��ȨF��[DH�<y�����4%�D<v��̅{�i���
����V�Ƌ����E���TQ�����c%���Q_(|�+c�Cz�G^�W�r�v����~��Ux�AMÈ~5�䎳�}��T��vpCM��"�R�{&;�	w��v�Bp%��+a�tV�Qp�mP���&/���l�&m�3Xp��#m����t	`��_��y��O ���|X�g×L�6����@��j���ᢉGqղ���Oϙ9Nfr�y"��yĻtbK�<�at>;n4$���Mv�؋{�7����KF�C깫�|p���I�[�r�w,v����;[&p7���֢���\���tQ�jȎ� ��^��@-��~��7�](\�� ��&*!͊�RX�+��c%]z�X����rp�W�x���~�<H7E��>������d�d�Wc%�V
�x�O���.��u�����1Z�y�j�;���|���^�0����δBf*(��٩�;���*eO-�������A�Q��V�R�� ������I�7�w,A��؏ϮC�W��������;W���>����X?����d*!����W^�0��|�����":�	��N��\TE�8*9�ҥ8�"?#i�����R��6���y�ܕ�h^I3�#hk/�or�:zń�c���F�t�]�� o�+��K���\.!cM�:	��c�2m�g�*v���Nҟ�Yu��Ln�,)�pO��F�=��(	�NH����c��lŭ�'\E�x�n�eۂ�s�τ��V�w,�����c\i��YS+s�5Ğr$�0��hN���@3��FLT��,�/�煼���(��<�H7`�ob�ugx�Fo���-�JA2����=�AY,ty��c��tH@�DG<�����$�M�Yc;39bu�b�!��a��I�]����Ӊ8-����_�����w?��)����\(�MWXK��RM�����"�ȉQ���WT�� �<�2=��ǃ~ٓ�^*����˺������)���MfY|i���w���Pj4u� =���(&��C��Z���t�@�i�Nge��&k_�Y!c�&XD��*=�VR�҉
�㱔1�^I<�A������K�l�]XOC����VIG? �v���2
��n���C�;����f�C�@>ߖ;�)wE��7�jS�MŃ�6e3�U�ѿ�oX�-����6b�&�!��������/_(�mഴ�f1�z"� ���i�]v��D=��G�ђcP(;��3�ߗ�iΞ������f)m�E��F�w�R�\5tm�9}��`W1�C�*|����	�wm<1��t�����%���	�C��v:�Ä� ]�I�[vWT$�;���+���z�>�Պ�0�cT������<��H^r��ii�a��Ӻx�h��?]�|����2-��W:x�NYB�]�f���|���MՓg/�)��IY�͇K;?�gs(�'
4��w�،ܢ��<�\���!î�ܮ���U�̈́��=G��K�4����ܘ;6D�kL&��&*��a�X$ɕ��/�&�����գ/<�m*}��s�	�XM[`�z&Sa����K}襤t���tG�e��#|T�li���q�	���i;m
�t�:�8#Z����j�(��.�����plk�ۺEP��Rv1���O�$��f,���l4���[�
�Q�z$�� ��D�XjlI�,�yN��>"�+l#{���(��3��i%#�c�.��^��=O���3���l�;�{%}h�'I�D���r�vF�G�*�C�g2�rn�[K����Y���͟o���5vv����Vs�Z^�������.;`>�X�g3�z"}Xl�Ki���G�6�i�8Bj���*�㦒��/.C[(!�T���p��}nk�Z.���Qp?���Q�����nh��i��$��Z�8���ǂ�7�c�< /H�5���ǉ:���'Om>H�z���Z���[���_j��vE��ŴV8Tw����:˓�-b� I|��/x[C-D��HMnϼ���[��[⮪�o� ��qR��|5p�ȇ!�i�e-}�<4ax�^��Vq����P��э���cٜ��v~���������ch��\�\Ì�b�J���,i����X& �	C���qR���<xM{�%�u�E����4L��$ �� �%$���ʴ3��
~��Ba�=�0��*K���3�*j�V4�֒�7�C�m��O�"�5����R$,?�<�6dh�r�����C=�����%��׍j$3��`^Lv�f�9}������Մ��͵
CE�w����6�.ulҫr�&��!����_�l~����>�UOh���� iyN��UvY��G7�"L�q�bj(/���>����.����;�6a���l���Mrq������KyM�˶���g,�g�3v��Qrr�d�I��d��Y�@����n{ɠ�wO��h�'�c�<+�Jw�F��ce��x��ܬ�4(�Hl�bJ3;��:�lRwxI���P~��˃6��t�I���4��%nՆ|B�xz���W�Z��!ޗ�t�D�d�\J���𩖽x���u��S\xq���t���.f�Tn��_:�I�ٮ$I�C�z�O� ��
Z�d���=���l����<��Df<_���ϻ�
�����G����i�׊"2�ϔ	����\�5/̌n�Pouk�%�b�?��r�hY�%�p?睄����_у��`.f�_�����[�Rͳ�D3� t7�r	�H��0���9��F��[���=�����$�T�zk�2IFB��clYs��p��댺, Hci���n�8��dH9�~�a�!t�oMt��ۻ?~s��zr9��hrv����iln���B>]n�.��Wm���sF��J�<���Gq�6�W��C<ao\�ܭ�w��9��[L�(7n��Q�xeO���͐��s����5�|����ag�`1��c��XPe�E[#���㐾$>���"�S�O���s8~�U!��#�Q��@+� �F�x��x>�d���h�kA�Q~��e ��ېRkӃ������S��0p$�,˚v�eZ=�U�hT<�>�'�;̈F�|5ae_z�
.��k^4�@��Ȁ��ؒ���k ��.PiT &�Pk�-�5��܄��K�vc�S���2=R�>�,��7���Y��[��5�(�U�|9����n"
H=j-�o�B5�2���/�湦��Y�:`������cT�ǵ���j����O�=�f��e
�����h����AŮ2N����>�Eh�7:갺F���M���"w4�U��Ckm�g���YV�nr���:T���a��d�:Ȯ�~�F��D�yѣ �G�Dԏ�@�wU���v�nMj�w�KOVu��V"L���"��$��D}�>�mng�!��	�R)�v�l@//��a@n�D�h�R�<f���W@γŝZ�"Tn�c ��V�@Z�1�N=�PO�w/�o3q�jp��+��z��bЖ̍�Kx���/�LC6�>�e�od�����.��{`��s�X�ׄL^�e��O�zP�%�##@c��=�h8�`�?�R��O��2�̻�:���º�I\}�sDt��R�ie�=�VsR��rG>�	��<������\�V��/�d��6Nɰj��Ƃ��ltJ�B8��k�?�̶|�܇��$Tv�؝J$    ���:v�� ������s��g�    YZ