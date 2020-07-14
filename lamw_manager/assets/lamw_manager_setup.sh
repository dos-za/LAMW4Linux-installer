#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="898111386"
MD5="538bc472d3c711e3173098998b460120"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21292"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 14 17:41:47 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDUSIZE=140
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 140; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
�7zXZ  �ִF !   �X���R�] �}��JF���.���_j��7�,�N�5P����S����/E|����� O˽uS���n�,#S�����nm��^���8�1�-�3�e]�j�8t3���u�s�y
I�o^�:U�W6
�w��#�s�^���HRf�����0"J�S'(���ג��9��
 b��77|Z�*hi{dٹ�1z���{~�U( 5_o|/���T	ʠ�����!S��I���X;`�Ο?= �{0
���X���6zi���8B4�;��&���"V�_MQ��h̴�g�$��̴f�O��Ug��%�X��֎�&���z��IGt��A�T���#�o����-}��J���:/��>�Y�`%�]���*�M߂!�y�H�]Ɍ̹��IbO�P;(���2��1v���5Cw`z
��i��O��~�m;*���T�0��׊�Ƶ9���T7�ң�_�	�xy�L��2%H��e�l<E��r�]�
pߙ@Ƽe��)�&�Ke^�,G7�#�h5H�4�Bh�!�G�EDFos�q2^���s��6�zӨ�DxGE�Jp'�5#�q�R��r=Z��,�"����E!%����@����\{7���凲��vD-#n��c���-��7�����7�ﺔ�z$���XUp!�P��D_�s��gc[=�a� �a���2��s�4}�/5�%�e<ԉYv]�o�lDHq�w}�O�~�ǥ�/�9���cN4ˮ�h
Q�X���w�o��6�*�Z�/X�q3�� �m��in@cSG	
D�A��#�������b^����
����3����'���Ԕ��L�?�3��~���R;1��0�k1C�m��1��x�]�u���H�ZAF�b	�G1v�Mż�>ӄ��B�#W�R0�J��a��8��gr�(��Ӄ�N����G;��%�1c���U���=��?��D�Fz5������:¾���8�|����u9(��#��mL�E��7Ҧ�YZ(���[�ů��/ӷI���wbO&n {X�qه���9�`�$����a�ưS�=����Gŗtr�^�{i��1����5��M�(�u�(	L���O4��0[�|&(Q���p�RZ#.�愖{�cFV���+�q"�B02`Ռ�	w��;����x�ؖ�%=�����mVw�����w*ćhЄ����C]�+�;5�v4����󻹉`G(�vЏ C��Q�� �vݢͫ�=���gڨ��5mIt�G;G8<W�$�(�ݘ׍\.*�)�MSd��{�"�m&y��pQ�(CI�l�Q��wO��n�����z4ۚN@JW(�j7�?���xa�k�fL��Q�8�y��]�ޔ�*����j! V q�|yzbO�ASρm/�i6�UI������ ��O=�+�0�.s�DGe|X@�1����a��i������m}]��b�Jez%j�#��9O���S�j�^���:��c�=#͡p�K!]�����R���m���'щ�s�����Uzd��r����9@E�}�d�B���Oڎ؁p��R<7p�e�z�k[�JG`��&J̀�8�V�Hq�B9M}U�UM
EP�X��^?��C���M���N�ڍ:��ǿ��K&H�c�6�u\��s�~�����-n 4�;,�+��%h�(�H�D�6i7VU.f*&��	��TNe�����W-*B�j?'�5�F�w8C;˚�AO�m�Ϟ��]�ڇ�O�0�`��������T#���^g� ]M��NP��O�x/,Ql�kq�(C���b� �n��QO��<�i�xP��H�g�0��PI���Z��&߬5d�����3,��(V]� sYP�8�����|VeuW�a�>.��Ly�F'�`���g�+�I4�L��t�ن��U=���2��Q��0Ң+�V���n�T�5B�Jxy:>x駓B�X`M �����S��{�h��<�-�O����n���i�m��/�I|��Y����r��q޻K�����!4�����ł�\���"��ж�	��J(	�G����"6�AI�[]���be}/:���mr�68X�+��˺F���a���##"��E��~>�z��O��]�x�Lq)�����["��\6�׶|�$�x�A(X�U��,2���O����Ա�i��tQ����f=�e"!�D�m����=�]�)�N{�Gs�_p�b"6���ǈyp�d ߦe
���]nGn��x���a?v���j5'!s�;�u첔!�t�@@�a0��e��@Ѓ-;*a�%��; �N.��?X{�t��Ǐ�-u���ry�����#e�E�MƮ�o)q�",R ��<��5>��0i{i�*П�A.�\W�f��W�H��O�R�)��$����Ɨ���G��{Ca�K�A�k"$Ҝ����"���p��x���Q<o���]�Q�ȎPb�o��h�j����^L@͒j�	�X˗��ihӠpQ�*BM�_Qs)�V���ΕY��T�6��yu�A���������(ؔ�EN_�H�/N�P�Z�R��N�X����P��B�Q�'Y�~$
�>�ξ��<=줡3|�3�m�/Ja�c��z&�|%M�dُ��L�~�Ye�uqU����D��zj>4w�V�d�cݎ��M,�0|t�L��KX�ץ<�ɼ)�<��o����fAB��_ܑ�!��8�{������.w=��g��Q��7XS�����b�ͽO�ƶ��?b�l]�p����u�ɝt�
&�o��	:�\�l��j%,��D��9T�e�8(r'/�t�ЖйPF G���T7��V����\I�Z fA�ϱ�z���HS3y�k�QME������y���3V��I�u�|��]U).�A޾,���x��pӢ^qO�������K�7�뼡R�¥N�~
����5��:7�(�������f��@vY�s��� "I���7���kQ�S�I���׻��9��m�RӒؓ�	�K��q��Ah����t�;�g�l�m���>�]x���r$ՎUz��3=��b:uz�����ZM/ݯ��3Bj;�ֲ}S�X�99�(M�D�%JL�(D!x��>����H�����UPM~&ܦ�A��6c�קrmne���6G�>�3��)�dϪn��>�rT���!d�R-Y4d R�RC�����Y�������MqF5;�g �[�4x��j�����f�\A��>a�<����JLl����d��E�⪉���������ݽI�NV�	�9�dEإ&�m��'d8-���+l��)�g��4w<�t8Ṱn�������
ޕ�����M�WTc<�՚<Y��#
�5#���\V���Ye@%:Y`1�NW�8��f̝��4�6C� k/i�Z���	�J���ya;u.����=1oW	��Mb�w��2Iv��:�ϥ�´�Q�.� �wR�4
�Ņ Cii
������#�e�Dހ�Wji��]~�[;����)�JFqe�]�����i��Ӹ��	��3A�K�C#DTc��%�t�@�DLP�>3�8���?~���_�@��$��G/D��T>�Ga��mv�T���1�M��4���@	.� ���u:��#2ٹR�J�"�@�
�|tbXɷkC��؟s���>�����%��Ĝ5Oܛ[R�B;=u��zS��ǂH���M��'V��4�5�I�~061+dv�e凘�^�����r2�����
|π|�L��jcx�p������S."�2}e|�
^-�Ϯ�3�A�~��k�3�B�
�ߔ,7E��<�������æ�wf>\Vl>�/P��<N���i�|�W��!�(�E�kK�b[N��d�&��D/�i�|znY���/��te�^��C���輳���@�͂�2˜�hGE~�H`U��j����W�Rj����X2���9����꿤&�+�D��z)�Gb��ȓ�Lӎ�ۜ)��[-��*��P�[oo�����B������shQ������ے�V�nͲ��S�u��bI��~};7i�i����%MzM�a��N��p@P�w�ӧJD�Zﭬ�mK!`(0�)Moj�e�5��0�	�b�lMqs÷������A�Ӕ���)ީI鮏oc_��� DG<��r�����p�o���[i����j[��ݢL�P��kL)��Kuu�A5�+���[h'�F̓�9�k���QԑP�o��M�D}���%_\ת�G��E~��R���KA�X3���,HM	���K������C�?	;� �@��ew]qz���#��~�-��`��5�H3�8hg�w�2��5O�ѓ�Q�I�.r����r\�ϰ�&y��a��Z�էk`���Ե8x�Q"��6�u%����?������u\���)\�ާ@$���Zv9;�;�c�-)k��Qp�V97�}�����o��Gy<ǎ[o�< �_-s�ld��4x�+:G�yb
���V?]���%{w�	�q��Ӏ�u�� }�R*�%��Q�#E.���x x ͒�{Dt��,����Tʊ�"xBr�ݽ�?��r.>I ����Є�d�+k�Y�k �68NFL,�)>�S�)���UT�����7�Vg���K�#�Y�e��Q2��oR&=�ewV�dQb���^H���.Jxt�B�Sn$��d��n�v��1�*�V|$�`� �*t��s��୒\��Үq^iC����h�KCy�0�x�#ܗ!��@?���D��:iYg�˟5,&zc�z���u�%a�.B0�e���e-���m{�lإ&q��n�<���'��y8ߠ�F�+MB^�(�fs���=��p	>���%h�iS�9�rVρ-�O��|�ƴ&���Қ�:��B���f��4�$g��[�$�������<���@�E{��~ի��
�}_Z;R�~�v.Wų�G@�ߣ��	h�P��$Vt۴9�X���M8A�b�Ӂ?��=��k��=d��N��%��<�~��N�.��'��ϤV���7��u�����G(�F�ed0b�"�^a�֑��C��p�5��s3
��o�2��*��8����\6z��)�����k�� �>螐�m;�x\T�J�9����])`|f�x|S�+6&�HL�����u�e,T-���)Or®�H�ą`��ޥ��hx�
1�`s�^ڕ�2y�s�]4��n��:�5v0�R���;O��+HpR�y��T��N�0xR`>�i@;a@�P|SF-ߵю�02�")�XS�^�����?ܱ�7�̣&Rc��e����d+f��q2NC#؊��U#����<ax���A��	'��σ7����R�9�d�$�^�K�*�R2��������m|�[
Y�I�kyԟn�v�>c�:�H�֓!E�zF�F���+&�O����)��V��?����j�ʃ�ƴd�M�$?��[(t�X{ah!1�א)E��O�e������CБhy[.(/KX�e��&�,~�"'�\���b&=goH^�����9�W������N�P��{��� ňW�]��M�V��?�n�]�YZ��x;b&5��3��a^�A��#�v�k�Mɠ�46ђ��]f� pў
�S������ך%�~�r|G��|�P� �A�ҷa����d]���e4�2�yc�lkex^�4|^����S��B����X`Y2��`�C��*B僐X�uM&(2�K�����	v��v��γ �;�#WH��U[j2�Z�&fp�}�ޘ/%M�mO�B�R�Ze/�ф\��xR+\���h�Hf�;��PT�+��8<�������`���q?��b�ݹ���O.Lg��t��R�=���K��b3�b����A%X..���� ���"����Rkz��_�r��*�s
���Y�?�u�p���=R�B`��}�m��t��̹Nž�ɜ��=�H��K�M��w�x�F�ѳ��\5J��� xMxd�Mo�ښ.��h���)������f�/�q� �^O܄�4�r��֛�BY��X�O�E:�Q^w7��<nt+��v0�5(^i����I��;J�R.^��,<�������o
T�(��HOS��+�5�ʵUo1�'c)�q�_d����v)�]U�FZ�����޵�=��$v3�L@Տ��4���ō�]�я6�2��!��KQW���"`�tJ1���5�|_ ��5ݾ��4��*�feѶ���3��a��g�?�&�Sб�+�:70hr���,��
?�k��Ei��p^�Z���k��j��O�7�����,�N��d�^ �:HIb�v��Qz3j��dT�N]����{]�g�Ip����E%ei\���Ec��k�	�O��n�[g{;�(�'XUA!��Պ&j�����u$��<��W�´�6J�k된I�q���" ��*9���=R�Q\�AC8��=�|�ݱ��ls�ђSp,p�	�z`�8�� �`��E����9&xvEnX�p��<M~��0ꝛU^u����_ ��@�ǂ�k5?E�K	mm5�ud˕�m�Mo>]v}���fKd!7�9*GP��{�$�^%���z���k��l�I��N��_� m4�)���J�t�G����y$kׅ�f��S
a<��n���4�	�nC	<��3��,n}G4�j�յP�
x�����`0V�R`I0-��/�J�E��*���>8�n��,�0&iY���p��OHh��t��'59��An��-T��>!�:����i��č��@.��ND�{~��ߍL��<���C��FƩ�xL��=�Y}6�F�8�D-�h�F�' �_X8��GcEN��wi������'5�k�Q����t�lp�ғ�/'�.�ō����ј������}Uѭ{��ɳ��{0���K��m}���_O���]m�&�� �J��֛�K�-��5U|��|���w��d����	�g{wv���$��P��*5���3��=�`kZ���n�ݡ̪۫̄a�����ޡM���b����nw����gG�Zh_*�z�/A�$:��p��YV��<��:YQ��
��@�8A�p<���VJ��ң�ƛ�&�3�V�R�cp�Y����!-���:�߰���:?9�k�8j$��7�ի���H�|��|�ޣ{L!C�����;����xX��S�9�	��ug��w.�rkQ|0�<I�����w0=�7��.������J'��y�2���+��s��*\j�j܍��m�o����o����~,J�ק�_�Z��J1�����(	�zSk���	`b:=4=�Vۧ5_-,��; ;�L��7��xJ�X�Zh̩:���N*W6��0r����6;*�ٟV\�O�AL��;���y�w�Fu��j�L�����]���;�
��?u��9�5�J�����c�r��9��Mv��F�5�s�/u���.0P�p��`Jj�Mi-ͧ�2�PЧS_��_�<�u��2�C>3�`�U��;����u���D���Dϟ�T"u$��KS�eu�?�}��.+�����|2+�?�����t/F��TגP�P
��U!>G
0���LT���	�*2�τ�7���l��篫8\I���K>eG#-?��-��%0��a,��5r#�:F=B<4p/�A��n_p�l�^UD���igފ�ڥ��_-��
�M�́N�xo���e���ሷ�	>�?+��)MM<�L�B�	��l�剁*xҭ&�H]��k���i�E�r�5�0?'�$[L
@����+����La����ܩ=�O�V,겡൫dsEMR�U�iYfɔ͛T���~UEf��`��pk�6��J��{vH+�McS��y�g(U��(魒9�!dZ���v�i��iH��Dr3���W���b�#�߱�1�㥛(r�ۺq(��8.����mن.Q�s����5J���S�w���G��)U6Pɜ�a�CM[�J<ğ��+�\@Ԏt����ޒM�U14+)�9;�R�x�o�c	�d��=:�e٧3K�o���,n;��������5p+_��߼$���QԳ���ͧ��M몦�����6.�2���AF������b'�>&@|�|9W�Z�9Q
A�]��?�F۽3��(���64V�8m(~\��&ڀ��@�ޔ4��E"����/rR4�D�*|�MO���a��EV���I86'��%k����	?Bf�f���?������V{�Ix��*=� ��/}a�Z����N��7�֣�-�:�є_�Y����vH����#��<i�/n!m�9~��җ�f�ׅ3kt�lv	�gt��{O���e��_��@��RL`;�
"�f�yL�Y�SL#=|�"�;��v9�PɈp�ec�ZÞ��	�
��;�că�e=�e6���<#�����ڸM A��t�Q�
S��f�s�SX3_���heP�^_]p�;��U��c���_�1׷�c$̄?�_ ��t���ȦSf�O���
�F*��k� v*� �+yRS}�}��R�X/E�
>,Zn�rn��3�uPTf�he���]�����Z=o�/\�ȴ�Skr�'��:*՚�6�U	Iܣ��l�_@^�;p[v��e��8�X�=qB�遲[��f��%������@�7��S(b%ɮj�<p����������Is5�m]5ԄZ0^��ɡX�����
Ï������~�.�L}.�g���Wv��:��g�L-C��UF�˜g!S��$�o��y�����: Yώ'<Ūʦ���������T�Ba�A7M8
���d�SWq�����\C�}�9GS���yo�����m�H�S�R�k>4�(!� u%b�!V�s%+z�jy��cC�Æ���]5�K��!A�F���y�
��sl)/[r㹍��3H��k�M��0x�/��{y�{,-�8�a�K2����z��F�h��ef|��rqe3?I}G�?Do涍X�h]N��o�g<s��p��ѱ�M>u�щ}�V��x;.�Ɂ�<t��n�|"�0Ӏ���m����_��&�����|ƺn�W�ն�?�Ұd���K�I.oY���k��.?��"I�|{��U�V4O�6��$G��M��|2M8��_K�t ��c̳�A�&� S܄��엮�S�0�pY\�K�9R}��?�������C$����bG	]�����{�������N��B�B��<�f?��%�	��傓����!ض�j>��_����`��oE�CR�+�T<H�Y�;l̍o�q�����8��b���o�E�E$�"����<ߙ���g��N^�V"d�@p��8�l o~�kV1� 4��}>1�ɾ��"�Ý���<,���]U���А]-�>|�W[D��fv��
LM�z�BZ7G�g���?�St�a���w�=�ԚM8'���]DR�3��ڎZ�D*�SK:O�i:���o+BJ�<�y�F���T	���/������+�[^h������c�0�����Mc��,�\�)S�S� n�݇U��ңie�;$��'!�/O�6����m������`[2�U�w��v۝��S���?;Q��0{��	�m�/BD�p�0L�m�Ʌ�M���P�ς�l����������$��h$_5��}�|�'��v�{I�"�r2�P������:��3"^����^��+$�AF\���x��B�
��|Qy�WB�#�G`�9m������d�3j�6���;�&w"-8�C�7��z�%�	d���qHTj����;�+Rp,�S��5�F��!��`��L�/�%2��E��~�<��wI`��_?XkY��0 ��4�\��GYnb\*+�̊7�{&��WH�Ȗ���-�}4����y?��:,�w���r����֌~���'�Jv�u�}��XD�²�to݋�װcŹp�T1X����SJ�˳7��@C��B�G�7��0Ѯ��?�F����y�_�7L�2U� ���O�+�0��m��٨1Q���z����?#�d,����M��V�� �Hl�w9�K�*:rOs5��p��W+��`S
�`�GP&���:��+Lv9�l��h&�/�cO��f�#~(����٢U��
���0I�L�c��t�c����u d�� V��7{l�Wal3�FF&�ш�'U�:���4O��Ov%�Ğ�$~��:j  �3����q0G�@!Xk���,:���\�\�Tѱ����[�E]�ěP�4{~D� �\����h��˻L��K����.�qem��_m���y���\�Z�$03F�� =��)_Y�X�W��W�U����d�����B`���[KӀ|a-Nh�`qHzh!P��Av�u�ù���t� 9E�udYY˿�=OГ��f1�O�<����&+˙0Ll���V��r��J���J#/�������`���#��N^��R��!�֯����7�����N��|ܨ��w���U�0f�s�m(0��T��a��}�#ԗT��!J-��~��;d�2kNN�0�A|@"
�M����k/�����4y��E�Jj3Y�bN�U6�O���Xg�\�	��*r�-��'���1���3��7���W�Q�>���c��������D�d�=���ן2��`�y��ڋ|;�PP'q&�:���g�乢��ؓ�#ݭ�j+>�4'�=G-$=���*�|W;J7���%Q*�)`̈E:sb�'3}ὠx��0v���a�ݝ��><Gʮ����^�*�W�Y|�����URv�s����*��J�0ڳ���uD�����m3&KS�>΍��N��1� W�`?�ǟ�����M�9f�#p͞z��M	���-w��B�̟�)��A����9G��\�,��w�~7+�@p�D����NFkG�=��FGK@������jJS+���.�A��fI)��X�˕!�~;ǵ&C��8�fxfE�m��G޷���~��af�Жx}4#�F�8_r�0�s��.G�6,��mElc2����&�e����7R5�!o����r��|E����N0X'
հʸ<�l�A LYNi�;Kߍ�C�=:�la��y ���N�`��р�PJܺGRz�e����5���ِ.�D��� �Y��Z5���%�1�=yd(��o���R���p"�*�T��@jXG����c�hQ�p%���S���%`��цv�,҇˚ԛ��C^�n�-ԁ!����1�OH	:�"j�%���i۔}wy��z����\�ɝd�a�Q��yR�B���ü�k�W,��<5����c�������T��#���y+��X�"ݷV���� M�T�>R���w�9���y6^��m�c��)�M�k>2�N�و=��mAY��e)��G�w�۹��|��ܱ1t�]MmZ?Z�1�]�Hԛ�Hi�I6|+��{˪�M�T�����t�J�^D�Wž~Y�l0�-���TH�]X�]�s�&v���*Dta��؋�Mo���K����k�5���B�-�6�$<�ĩ;�L�c���Z���1A4÷q)yAi��>�y��ѿ��c`�У��e�k�f�\����>"�ȹr�e��t��.����]�Q<��7��a�!��A+"�=�s.��8��h���u'Ш����K�*��C�t��� �c4*�tr�����1۟�������Ȭ�X,�����gf���\ʆ: ̚Ʒ�����e�E��98m��<�R�,$�f9��y�;�6^ZS8xT7��h�;�l��k��������$8��鰋�)�5�a�:c`�l�Ju0��̇O��z;���|�yp�v}�{ƽ�u�1��,GW.:�� �ߔ�@���Ҟ�&o��1<q��-�D:M<��~�T��҆�ӧ`�-~�M*�q��0��J�(
��
器�U���킧�����<r̍ri�@�?��܀xZ����hx�A�{�}g9{b���ʘ����l���u�E��x~�6s���t1-����8��W��$����}�3�T;�dFs�S%ü�+H�1z�
>�7-p�1+�(O��%3�Q��}*��ak�&�.��J��S>X++v� @����� q]��x$O�&~LJ������dh���o��i�qh0��Fr�l!��U�V.��[�wȴ���eK�<�q��o�U5��L ��V����~������!�ÝEC���ro�����y�)�skD�0
�L?�W���6e�ja?\���M�o$ȩDF6[�����;B���WX7�Zh2�	x ����3g �W�"����ⴢ��G�JsP��j8����j�D��(���[��M_��Q�/�6��	  �p�8�=��D o�A��1]���OV�Ҙ ��� d;��![�Éd�ȋ�|U� �T���=5n(ٲ�M������M�������O��+3�H���1�AF��8uG���^&㵐x�]��E8!6�E������u�Q����z�r�t��ib>-�Jxm�o{zDEA)����Z�U(�_xK����x� 8]"���8��:�T���h�6݄���P0�j;1�"���H#@s�3R dd)�$Hd`��� �{�DW���8b���Cu������l�{冀�[�J
 ���ܫ��d�� ��G��d�-��r�)�P���Q�`*�V��.��@z-�d�4�_{��@J'��^A�|6�h~z�� �!>!�sGҎ����8U�U9����76:p�EJ�v0z�ǽ���,<�0�?�8x�ZQ3�kG[��G���b�_We��*mL8�e�]"J;������vl]�w��>,��3�#����XQs�$�Ka�@����Z�nVU�O�ܭl�s4�tT=gs�k5D6��`����[���֖�.g��m�~ ��W^.\&o��Q[�n��K�'m��ӑr���e�Sz�	(�1�ޠ�t�6�e���:?Oԩ�N��U/�4"�_�I~�6g��P%o�y����m�˂��4~�(�a����1�6�R�z���o�w�'ؒnI]�$v��)�����=*i(����~�#���ф-<�eL��+���Y�lS���-�_5�;Z���!>ĸA_�c��[+�����d��F�Wʡ�j���_=g^�m���U�Nv<����$�Wy,��0����������0`(f9���,;�-7e�ϵcB�$�TX�(����w+S�TP �,j��HT	s����#��O�˾_���W����@v���~�ux��O����'W:���*_�L煙g"��$%�B�"��$�{~��PtE����hqoO=�wiq\�����(<@�U�#��;�!�4�Ιe t��"e}�Hs�%5�:�j��"�$ꘔ����艬��p^�:�R7-$1u���e+���=xɎ�,�Xm��5��#�P��������M4��>j�肮�� �jM�n�V�"60����C��Nˉ�Յ~׾}�K��+�§�0��8� �e�����NK�Z����p��v?�a0��Sg)(��(�w�f��A�ܧ�2`_n��'��i.V�!{ą��D��l!����rP;go pr	�oՍ�]N����
��S�}���Q˱�*}xF;|S�-��n���y.���`�	W���Ӿ�IU  pD�W�����5'w�"<c����R�i�A;���#�R�5P&�4�*�Ƹ�$t�;ߎ��o�������)
G[��_��|��_Ï����A11mP��
�-��B�����!�a�a݇���ӯ���;}�@��COPAi��������I<*�(}�F��ޛ���?y�M���#��� -��<(��I.�ƍ�x_� �e�2�V�)�+��Q�^B�z�g.4?o#��c���Afz��T� rI��cD���v�ʪ�T��
oi�k>�Gx�{����x���J��z�n�]�n�<R �2_�L'��m,����Y(�r���A󐨿��*_�8P����=H��N7�)A*t$��G��0ũ�u��Ad3K�\�A駴e�30^h�@}��;f��}[�����x!�D�l��E8$@�2W
n���T�ڳ�����s��5`D8΅�2�q��1Rm �� ��ij]MEP^?�4�C�@:��A�܅�^jв_l(¶�r�Fw<~��Њ-]�&�ۊ�e�F�q���v���7���"'���ԩ�|ko�~����)T��@��4��2��=��cџU�A�Z"�OLn8�J�sV�������6�7=�z.��hӘ�dXr�H�`6n�§^O�K���l���!}� �&��/Q�/_�������dg�3(:�n{�4z�颌Hn���VI�c��p�u�WE���b�V�k�H����*֚'w{�4N�9��xf�f=��l���NFϋ�9@/>>��9��sFn���С_�B��f��ǩ:S�����u����d�d6_�Ua���i��lI�-(c�fW_��i�w:��h�צO�m%p%�r��%�b�Z᱗l���ʞ�!�C\��n����5��+l԰�� �������?#ΕzD�r�k'z�:%`u<f��9d����Lu���o��z��G4;P���xǽl���R�g���ضp�ލO4A`�d Q��ܸ�+/ �ĕY��	͢MMr�t]�h��a,�����L5�<@}R�HK���m.�� /W{�܌Т
�,��$�� {��q}��<�/�N-��.�'яJR��M��Nq���oQ��`Rnn!�.��T�+�ْ��!c��VbPd�j3��Y�yO�FB*q�IP6P��4�+nG��P�󯱮Mx�ړ������Ѕ�A��� X��f�:fȏ����l������E�zM$�`Y��@#zd)D�b�` ����0�Xu��!:l�G����l���uM1É���5^�f��f+���$GC��Z�u�RZGȮ�~�8��rE�(C�p��7�k?���`��ic��Wh"HeeL~�Ѕ}G����
��o�3���j��Jq�75d���7����j�<��tk��ν�mhA�y�PK���I�"�W��T�|VL�2l|�O�4� �,;䘀
�!6S`*��?!ãb(45`�ni���i+����"�"��-=�ެ*	�<FA��js�Y/;KEd�z�2�%��Ɉ�У���4�>�+���/����C-�wO�?�D���uD33���תe��id�,ӂݡ.��u�F)�1��0@�Y�	�Z�ezZٯ�I�Blt��x-b����cByWB�4 K	y����^��u��᪄��^H�����H�y�8+��R\~����偸��O��)��X�w�Of����vNu��s���Amȍ��9U%�^A�ʫ�΁r���z��<F���Gq�a�|O>�_=Y�i(�xދߨ�;68��9��C��=��ˮ����o�^��P���=�P�2os������n)w�C�$bM/R�됍{g�N=�k4~j���@,		+�<G�Á&(O���B�+��Ġy���⭋��7<�ˬ��N,������&Y���Q��fE���5���X��a�ݚ�5ЛD�S��f��<a�<����¹}��&/��:��*3$;�U�_t+]"�=�dOT���` �)�.F�jp�a#��4�0O�N��p��p�#��aO=M�2�[Y�{I�T�X$k�痨5��3o/�����lB��[K�����Y2�b�,��ta���:V̛����3r����?s���+���>��;ŭc�_��;mB�LH�SC�;�T�����u�Y�N�q�+Mظ�҅��u!y!����$<�DduM��<�Ei& �66��s�8��#���!7�ɭ#H����+C�ջc�}��g�%ƞ<���>�AwD�ʚ��Y����i^��q24F0#6����󪅌�Iբ�9ɀml�<S����+�U|���)��$;k�6��C���Ap�3o�*���m~]	Ш�1s!��, ����<q�bU~�`y�32@6��a	��,H�W٪ut̬5x
3w�K
Qסc\�RM|�,m��	0ɪD�Ӫ�Ѥ���u��GU� �#��{:�z��-XvX�kED˯����#u=g쯫�q����(��i9M����:�Z�ゴ�:h��[WQPɴ&}6�d�G�L+��9}O�+��UTck�����<��y���.2�e\C��Ckr���3�k*ua��q��I��J��� q4^��[�FCCT�Pۙ� ����m����@�:��kc(��m���V�Q� �On�ʚo�o�B~�4�j;�.��[3skwP���H�w�"��31&^����B�*��~K��n��1�lc����H�W}<ӽ ��̨]��T�8�ÿʷi��I�j�(��Br�C���)�����sQl����u"-�/��ŧ@�<�/y)u�\CJ���j�۞е`����U�[�'�),�11�魤��x/�v��_�z@��NA�J�
�\���hr�ĸ9-WG�%��'�[���p��h	A��}���!�eLs�k_�/f�6C�8�m�G:�#?��E���c�q�F6��4�7C�c�w�ϛ����w+��Nb(��!GK@S�M�44 a��x1��.��D��p�s�����îuR-��������-�ʅ����G�'�k���j���ʨOI�I�$��H�?].p�-'(�S>��&����X3_)�9��4Y���T$�733����N^�]�G�q��,rhWO>��ػ�	}m ;p��sRy�����$Hd�,���E���T��R=�2/+�	y-u�����J���YԬ5}���s�7N��BoO�p�NO����&{cƑ�֠ S�<e�������0Z@f���4�\ ���i;��|�n~�oWH�L=F�N�y�xJz�t�.#��㼍�χc���AN�z@��6)�\�.՛��%r؆@&��%J����c��$�e>#�(���
7��5��Gʵ!��}�]����^�К?`n�`��=��>]#/���A{�9�r6�?i�Č��JD�T+]־�t}#�����G�=�o	�6T��?XN5}�ŸG*h�pv����[zI@nZ�C���|a�ٜ�1n�ߐ~h�
t�O���r����S)~�Y�B�?t�ib'[���zl�;X	�I���I^�AA�����Y������=�׽��^�<O��B����b���X���z�s�7|��Vn�-F�7(�7�d� ��V �����1�������a�PX3�sq�+D����b�&ԫ�
?�ZA�5���<�sy�mx�qQ�;��F<7�K��Z��wfͫ��w�����Z�B�4|�oY��Ѱ����^s�1���u�X�����P�}�ɏ<C�$���4�{�U��	������-p��Ph��i�3X]���{ܭ#]��Q~�	�Q�j
�$	(�����P�W�t8�S	*e!�ŧ���[v����H��^�Q��x('�3@�x�$Mo��h��؏�cLw9_��N=��<� 1�$�B�X���{�1�����B!�m���M����6�1eh��H>�S��&㈔�ح��2�2���ȷ]S}�:�9�Ӧ��q���󑗩F��]gY����M�
�l� �[�l/)�������vL~,��~1tJ��d�����=>��h���L_�b�����<,�L�4����z��.j�"C[���1�/�Y����N�����d�@֪s�Z�}[���פ�G�;]�Z�=��X�h��x��=�g%NB����r@!mT�G���a,W`�����n�(��p+�oz�(tt�[�OI\0sP���uߝA�@q���	}m�ZjZ!-��#un�9g�м{�$^�w���!R�D<�3#�Y��c>Z�:� u���{���ж�T����γ,����h���`��������<�.f?�X-9��_j�va�@��v��n6\N��Hṏ�U��_���F�M�TN�Ӈ��f���.�����bl$�& hW��$-/�:�?}o�}����_	����߿����;t~���紲AӨ9�ʮ�� ��NP�>�� �����+_�xO�'�͟����2��ޫqS0�T���q��ܷ��	�bܵ������	A�}#z��g짲hMa<0Ko�${l���Fu�3D���Y��6�%��3�)7478�P�֜!g6u��g�u�g#�8�<�&���{v��_a�O��G��g�7s�	�[�����Pټ����#ߝ��Ӻ}0���δ2"�.��!g��Rް-�`���#��5w�0�Eu(�$���5:�#9����c^�`�T�;_�+q����\e!ʫ[u�7�o ތ."Ý�����.yHF�����e�p�qT����R�D��ss�Q���i	��pp�"J�o9q]���4H�'k9� u�>���l����+��^����w3�"��y�V�`c��o"�(�eV��(�C�U9�EcD=V��r8�$Z���1+%�����w��Ë⢼����ҳ�D��h8���D+�#�	m�|���QNJ ����D;�[7X$0o���Kz�����T94Nf��s/:�l�Q_�n+�/ԕ����2O���
��;��F�1��I5+�u��T�k��v2c���O�|�E���:fI ��v���C6�l��ِ�ՓǤW�=�ނ�e�ѧ�$-s�Y�=(/T­i���:8��8��[H���=]�	Nfy�K^��NfM�G���8G�b,YMI1Ϣ`6)��H���&g��j1gG+�%��F��5WwѠE��(t�@�t��#��c�[�:�T۪�&����0s�h*ʮ.>��P8���xqSte�/!�d+jێ�?�+��;�_��߉Wf���]��V}:9s���B"�})M����(|}*���볈���<�4�}�EV�k��uw��Â�N��J��a�nR(��2)x��I��B}�Aa��=s��o`
� k0� �x�q�Q�2@�nOi�>s�f<�X�-��i~�	OS�IK�G��Du_CL
�j9W�;��#�5}>UP�_�!�)���e��.əU�+�E��2�CsI�ܯ��7T	s����v��Q�r�2����1v۸��+�"�H�6gAD��ً��'��v��T%���`.{_����+l���,m�>��9��i��V��p�c#�{e�˖Q�?�P?��
>5�;mF|M�ou�B���j�����֭mj�z%�)����#���]f����L�c��D5����Rs~7�D;r�ɹ���:�����a���3m-�.�?�ms��j8f�pO8H�h��N$�����ȱ�~L_��[l�vst��F�|��/�3���x�J
^ن�^a�_O<x�� �;�dB��X%���n��'2ud��&L�l����g�te	ID{pr�~V��2�d��?�����SJ�CÓ�h!B��ȂBS��p�.����5	�!��'@n<S�F�7O@�� ��05�p=TZ3ʪ{1"C��!���y��)i#�9} ��+�~ЁG�@��m���ؙI���ӗx)��H� %b���Y:�>Y�6�����u�k���7���������NUl���9��݉��;��`+���^jh�r\LG�^$7�f�2��f ?P\4��\��A�A�	:	�.�G�%L��a��i].��"��zYB��4�3z�ǹC��V�g�xO���iX:�����g��P�>x�k����KPE���'q�����6C�K8������������Ug����i�eYe��i$�[l5_���A �U�71����
�GO��i���}����?\4��`��8ԧD��Y�Gz��sU�V��9>eٶa��<���B}�y'l���{��q�t���o
z�u� �,o�y�O�8q� I��T�$��߹)(�E"����]��SS��9G��+�s��^q����݅2E�0���7����:ras�S[L�k���76���@�W4K�x�[���\�:C2�(8�؀<>2&���
i�5RϚ��	��P��H��r�HM��R�&���|��f�]����E��}ρ|%І�{	<B�xj�yŻf"��#��.x��.Y	��
�������͸��@wc�KRћ�Wz�M��G�m9�B�[�a��5�4�KvV+�y���܃CX��@��-F����B.%)�t���zц��0������b8}M ���+�2�cls�]�o6������PG6��}�\0���@�5JT�_v��=���R��I7���CP~��5r�p��e�~ucg}釢{)M�aG�F�����A�B��̛�Yc|6kլ���>�֥p�lo/�Z3�i&���?�Z���xL����P�݉�YG;���n&VD������Z;�Ĭ����H�?�Hu;�%��"��{�ԦG�����^ѳ���޷ȶSz��߯��Y��ӵ:�����DoXC�{���V7���ׄoA��28��0�>9�G^�@����	:7Ђ�7B�Z�,�j�z,OC6V�&�92�9O*�	��
�0��UZD����0 �!�'!�,���h1�_Ҍ���t3��JȦ��g����J��!,�z6�YW���Q����S�}��W�'��J�HF}���:���8�X�ht�H�n~�4�ne]II�#�~8�2W�S� �§�0`�+=�4.\����1BQ�c�1U5j-��I�g��*�!JT����������ڈ�3E|K7�5�5���-�|��	:]�Gq���  D#�
���P ����3�j��g�    YZ