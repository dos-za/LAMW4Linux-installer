#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="821560106"
MD5="5c97d79c0f370778f1968745d05a1764"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="18987"
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
	echo Uncompressed size: 104 KB
	echo Compression: gzip
	echo Date of packaging: Sat Oct 19 13:59:07 -03 2019
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=104
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 104 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 104; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (104 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� �@�]�<�r�8�y��Mi�v�)���a�*��h"[ZIN�'N�(�٦H/����_��aj��m_�c{ ��E;IOMM�R1	 熃ִg_�����ǿ;��o��߳����{ۻ��϶w�_��F�������g��8�K�V����j��������1뿳��������?�\�W��e�ԫ��_|�������ˬ�ދ��gd������7��r���_�+���UʕKǚSϷLädL���������%�u{j`	��ʕc7�|zHz#�:#J���,��r�"r�C�]ۭ�+'���lk;;ڋ����#Ϛտ�D�2�B,��/ � ��ϭ���0ǘ !�k�� �	��	C6��X66d=2�L
�$��C}2v=R�Ͽ'�׻ǯ�TRwLϵ�߄��4��� ���?.1]2���%0l�4���1!>E0��?��gsf KdL��-�|z�9���HJ�i��`s׫�## F���!�94�*�F����p@t��K����0t����PS�`�D�f.,��6&��B0�_߁��#֬e9�9������~K��r<��d����v�e�5�)��u��CM��Nm�Q:3��a�\o�E�O���yԦ�x�;�l+&�2h5_:��+]�B��lk�TE;>=���� ����F�Ie��j�{]Y��F��l_�b�kK�J-���b�Rio�)�-��b�5&�JI<�� c62�:q�ܼ��#�w�T; ��q�E�0-����CD$�B%X@&B�1IK�w�z��>�di���aRh "�pJ`�7ķ��O������.�M�꥚������!��|��Ə��}��#C�B��	<�+17��$����(.��P;�����=�QQel��l�J5�H!:Qi�K1g)�.�
����6@{1�c(fo[M]��H���M9z�PgN�"�~���5��m[��M���B񢶭A�+1� W��+�Õ��!��y���[-��fGW�h�Z͋˷�W��[D�� ��{���ޛ�~��)��j2]k ;���`v1�v����D
���,��BG�.Q
H�+J9Q���p�B��&lҾ8m.iЌ��_\�L �l��K,:Fo��M�CJ�kÙГX��&�W�@J��\�7�ڀ6FK�_�ö�wlB�;��~�{���h�v��+���`���Bڽ���=����8����|_'����i�ͮB"��t�ͷ:�L�S�¦+���<%���J&g�}�=np�ʒ��*�#�Z5���X���5*D\�}J2�BT���Q?�����/㺨ri��w�'
���2ս���^!�#�D�h����vI�ԫS�dy�hx ȏ��wE���)�͹w���3�#����ڒUL�c][����Ϙ1�����+�P�[��CȲ(?��Y����g��6�O���n���)ޑ�Q���;r<R�E�-��8R��h"e�ʟ2��n�����x|)=L�+cI ��J��$��r�G��:��6���j�c�;���r)rH�� �wUV����sJ�%���������mLoU�>˙�*5-��_,�<��wp������l�������M1�������?���ӧ<�W��k��ԟ��om�b{!`J���FVK,����o���C����K�Ι�!d�YN0&�˗�_z�ƹ�+�?T�#�~���2�P�t�(����I��ԝ�O��}pp /g��%lgv8�ʕ�A��	(��J5/ĩ����*<�+�1�ԛ[��H<8	����C���`���5��.rKL�O�#-��S2��,h���op�P��qr(#C �I@r����š�M#D����m��d_+�T�qe�ǣ �`�8�O���(���I�[��e�5��ǋb'0z� {kF��LE�C�5��*�O�j�����5Ǽ�f� �O}M@���I�)�p!T�&BӂgӮ�.+�'܁�ڰ� X+�^�Gm�Qt��W�`�ؾ�J�i�^�o�U�:V�`�	6�B{��6^`o�U�j�*��-d�h�aB""���C�ey$�cDQ���[�C-��'�6p%&z��������E�IQ��5�ɇ�Q�P�\*A(a��� ����j$2j�0f�]��aَطF#S�"�6vq�O���	��9��㹨D�z��gq���3��5�|#SC��
`ӈ@QZ}};i��K��(&�bM��a��[?i58B`��N���%�kH_چs��c�{с�~>`h�6�8�^9��JU��"��SQ
'��VZ�T-l�6���$�~ǩW�7���!i�F#QS�Iː��Q�:�@Pq����x"��z/E��x��2K�T���i`YX� ɲ��1�.��O��9��wa}B����g�R��q��=ؿvD�f'S��C�( ��>�Có\�
�g��J�o��l���2�o��mqs�͎U\Ǿ'���LE�U2�Q�#�U��nTt��'��Z�Tŷ)����d��] 1Q�����:҄�G�v��s�#��,�m|6h����Zόu�:]�BV�/5�A�3t���IQ(�K�{�������'�\�� yz�I����J�b��[��Y���ly]�&5_�W���b����(ηf7�UI�X��c�I��Sm.���H�b���Nc�.���xX�ֳ@����F�kˬ۶�I�2���puy���]Q�0�,�S�0�x�����n�3��X��TA)T���=D�p����aV������n|�^QAџ��׽N������N�l,}���_����^9g�Q�4e7�v�$&�ի���E?����*Ƹ>��@p��o�[�*W� /N�C�U�iUi9���FV�)D�A��N����K�H�+��QE�|X��?[����o��2��n$u��5�W}p޷ʥ����؋�Z^� 
`���KĈJ|��M��E�<>�ƇW�&�	�CRăW�bL��d>�}v�����ϙNJ+��1�?irc6��y��I&��)uB��8,�{Ρ,9�����ID3f3��	:~�M���91��w�RylM|P��F_S�;/���|T3�hD���3ݺ֔j3��%�^��TkޯP�&�ow�6�vwI�	���|�\S�'��X\i��Q���{_�
�95�{���U�1.��\U'�b/Uc�<���p�3Bs����`r�U>���n(jP����7�����/��Q��,���10��:H��f[AoGy�9��[��_�]6���L���8�p����m��LS�=��b�
�]�ݩ<�툽��a�_�EU��-�����a� �8]��BD�c
1�v���&�Nm���5�Eb�:��u�<�B���L���Q�H�:�;�^px�V}}�P/`*sڸ���}�~��p��
�vH����Uy^�zF�z�Na��G�cR�",ڭ�48o\\���y^*��\��|{G��A����Au;�v�4)C(���Y?s��D���Ԟ�&�ay��	|���~@�*{Q'�eR����� �`�BؗM�Ч^�:��5�#��q�
9^\�P��ڏR4b��z�'܄��"n*��~�z�z��3c�"�d��X�7/��$%�A ,�G��P&Ιc>�@�r�r"��x��A�m�VTWV[Z%g
�[�Q�v.�e�7.����c^P����4L~��e*@V.�j̍�_���$����T�J�t��y�SO��
�<c��K����Á�%�e�H��T�~�����?�?�
ԀЍ�����\��9uF�p��y�q�M*�=�A���fm77��1�#��GDt����lm�
i����近�y�#I�,/����-��/MfZ � C��#�5]���@v-�NɊs2�c�k9V ���í��m�?��p3��C��)
�y]�Ό���#0�1aL���g��Ŵ�*�G{��)�6�K����%�j��Rw��ܖ����v.Bq� lV���
����[�ж��oo�<��z4�_�=r �1 ��.���8};j�2��������h+��K��!�#���+��� �Fx�8ic��ь����+\}e�ɘc7��<TS$�V3�U�-�LG�\U�/vF���@��-IɡR��,���R@E�#d99�.�-j)1fL�(Y:?0I��	���Ys+��;H���Q��{f��9����E~"&"8!&��xsu'À��K���0:���x��#��^��&�N1��J5u�<�O�g�Ox��ڐ���VƔq $>����18Ix�������`���Zd�j\m,�Q�0�$��.xSSiT�l�ϣ�3$2���kT�wBX5��*�U�a� t��[�t�4��p�p0�P�A��_���
"PU'�;��?f�Ԡ��W��"�8��W�^�����"�� ����A��ŀ�P�q��f*�T�2�J}YӢi�j��ՒUV�����(��I�lT��\W.���Ю�a�W�5s#��%��e�?Ƴ�H�=�i3`�y�o&ɶ�N���e�f<�ڛJ��]-�"2+oBA��wf,�%rSp�ku{ɱ_�7O@ybǹƙm
oɶr��1K)�ΐ���=_�%�nm���ǵ2�_Nr&����(��9����l[9m�5]�rC[��p�UW�d�Ǌ�+��{�ƌ%%jO�o¼Yu��s��z�����~�����t��*,G*gs,C���ѩ;�U��H'c;q�H�璸EN�-҅��%����R�]g�JZ��l���uZ٦";Yk�e�R_��@K,� � ^�D�P�.-@Ô=���G���r�/o�������,�"��B��.�"$�maZ���h"V6(��x_�+#��ík׾�M]1��g:\	_0�48_ʿ[�4M�wb)��o�����PQ�p��ľX�(%�8<�����N�!�^PdUH:-$9g�C��M8+��_�]]�/:� �R�H�-Lj�ҼSxh�Z���t� Q3�8b
���ɟQhɒעc����(��������<	 ����/qt�>�HB�I\|UCf5-fu��Q��/��W����y) *��+���-�@��|��Dj{I�.É��������8<h�^1g�}Å�e_��˼*z������b�-���
*3_r:&O����F��yeD9��#]�n��Y�0ew���u�3W�ic_iR�<�^�W3��k��Q��P�>(!E.
�'�e�DKn��>*������.)k"�Z3�`��i,�?c(�yXvC0b�^��o^��C�˹��O�W���̝�%W��M�\�g̲O� 7u���6��Y�V��ܹ+�v�U�Ѵ	4Wl?���#�����Q����
���o�/���EW�����2�����=��d�<h�ƪ�vOk�o�=���}W�J7�|���o�*�m|�J�X��ղI�g�������s�<n-��q��iw/�^~��_�d����O����+RW���(=�,rwN�j�v��wQ�i�q�;���ϝ�
����ȇT(� n�����$����}�#sB�1%��1�[��)k��{j��?Q�7��>�Ŀŗh����g"Om�nW�m�;��3Z*ؕ�=�/�mE���dx����g�#�W�9m���/���z�y\o�~!<��`�F%J�aA���}�7�J��٨�!;���p���W�]�%l͡�[��� ���a5��`�AC�e3� ��o�{��7�Ϸ62�
�|{����}[w7��~e�
�ɉ-�I��|�m9��hG��"�q2VWKl�=&�<�Mي�����u�5��N] 4��Rl�2+ٍk(
U_Q1��@�Y��&�L�����n��|)�n��a^��?��Ν`k�I��������ϟ���wpr������Ɉ@�wM��5��RDL������䉪�Jb^��4I����"{ʎL|�RSE�/����ۅ6V%�Onm�*3��3"�@�,��XYmܸ)/ra
�~��L���.N�!p�-���e���ݳۘ� }�<�N.�(����>����v⧻\S
��V��n��M$jJ�=��5�B�g.%/�fo���X����Y�@|�)�A�S�,�ڿ�i�!��
\m�vkѹ�����.j9��2����OGPА�Vjw�e��c����:aݮ"/����,�����?�њ[YTN�ښ_�ey᪚!_�4_	�%-W�6�(��	i�WmAh���U�s"ɥh'T8�p�?����]:͏��d.p̳�����c؋��O�~���U�ɘ(��rY2�&%F���Ii� ��'�<��mQ�K'���d���IN��kQ��;���W�<J�7�#��I=~�F_:�����������
�o��� ��"��[o�L������4�|�0 N����%v�7�G�e̓H���N�?�3��G�%N�{��A�/� Y�a�9�;��ك�M�o�I v�/�68@׌�:�C��<�o���ސ�/������N�2l�t�$��Z�Cz���̰u�a�ǆ'�-W|��A�D�4tRY��:��=����H� �	�(������i${���PY"o{�̢	�F�E�,�M�"�DK�#����A�#���xk�������4�I����7�b�%Q��iC���9!c-p� Ԍ�S�B�<���R�}%����_�n��z�y,��@W��(�n�c?!���x1Y=E����&`y���N�<��j8@5ʍr�ښ�Wl���?�ԇ��7x�;�֝��	��7"6ST�=�ڭZ�чc�TE��M&����	�6��ͦ����^z�)�(J��E�p@�J��y��=�2�[��K������O~^�A��>aZ�s���FSX����#ת��u��#�I�N
��ꯜ\N� }*Q�g������aw�߽�OX��F�N�9��$�.�d�W8j:S%�ô��<�T�v�dE��d��_���"�'�����k�O��)��:eЦ�~�n�%�R#g�Nu���¢��dA^�����T�SŤ�U�A�'>���<{r�N�~�{'�J�R`�&��R8��t��ֵUk=ѿ�
��>����VmC?�=��e@�r�RI�B��5���Z/�'Vʐ9O
�F�L�x�~���h~dҵN#���	*�#
@f��dȎ{ϙ<о���8$l'�%��`|�Hp*���jCi�c�6џd5��I�s��l�!�I��z�r��Mwd
��'�d+X )���L��	4/S.�%^LZSc�{����Z�/ʶ� U���iA�gR:*�Z颮�P���R�$#���0��զez��FF�+M��GN�BW�k��fEQ��H"��A���/E��ף���o&B!��N���q����+�Yj��<eZ�G@�^&�@8�.���8X#i	�X]	G)�p���0a���J���G�t�xP�����n��c!�U�HG~��X��lB���+J��#�4��I[���N�gߴ�X�/�����9��*�o�	ءN'=�ݘ�j��z�?B������*��9��{.����+��*��U�����t�^+ /O�$�Ë�g��k8՞�X�w}��q\x!��@��IԄ-�k�Q�W����,	U����Zk�E7���݃�=w�^c���,�=���$�ʋ���^�`�'R��Ke>�CD���/�;)0gi�z��`�[�D��z<|�@��`�'�o��0b����b����P��ԅ1�b�����֖��?��!T��a���Ay	[�R�.��	���P�%�|Q)�Hj��/��~����k�<��E��������������*�ӊ�/��s@ݟ *��K|��&�PS�a�*��b�����_�I� �DQ��șµ�vh�o`���y�y������v�}i��>���w���A�Tsdc��·��22��K呭�e3�ل.�@��u�:Ձ9bb��jv�9����R�p�q�`��u~<�%��W��?���c�<8Ō;��������t��m�lB����� �����.�Sµ��G�r.��΁J�6�s�8bo�S���vS��¯2�q��2�CE�G'uӫ���%����L�2����ft2����E��o��|c��+̌�]�����Y�i1#;\�o�+8::�Y���?}�2�	��ƛQ����Y��n_��!�U�Z����]����g�o(-�L�>����uv?O��:R�'�D��O}��Ҵ�l�w;o�6e� �tTW��2�,����>��v�;�]� G���xG�`,o+��@)�l`t��4��������&�=8�*���Ȟ@�  ����l����t=8�vN�h.���%#�����2%�G�.8�S#Z�X�"�LN&5X'��S�\�ljV-�|&����Bcq����xc��uYX`seA�U ���m�Q���=��@k��h��;b>�󩻭[[�%���K��3LV�?�N����Ą ��fX�=V�15]�x2���=����LL�ƺ
����2�Miy"��a2�/��n G}�+��+9=�@��Y��j�>��8�^��*yG�'�H|�؂��^��*jRÙ�&y����rpZ�2aQ��β����KW�|�
��g֮\�_�Z)8Xڎ;�"�~�?	`���'�]�4�7��a���{�v�z�βVL�4��ڻA*�2=]��s;IaD0د��z;����x�6�Ǣ�E� ڭP�IV���ΐ�.QB�`����\kxK�n&�U�"�4}E� ���e0����%c��]j��i�R��Ht�rcN�@�i�Ǒ�<����;�ꨄ �kp����A�,ſ�M�zXh�D�Vɸ
 Ҽ�ِ�XYc�)�$�e�p�"�)���n��QmS��L��E�����hO��6�j��pГ�وNj�	�>����'=�e@#�H�Z9W��%�.)9�����4ǁ"f
���ll�'ɛ���r�Z4�|�'�c�eq�5�V��ã�\i*Ύ!��?��1����V��B�bx�0S�d�W��b?U Q���z�-�i���ngQ�KR)Y�ho�����$�Ύ��J���h,�x��z(}�H��mq�J�W8��4�ԑl6�U+}�z��hg�)����)g�"�g�\�����S_�&����U��\�ڛ�!=�A���~�N�>����$���7�
�# �����d��������n��ЬzL횳D0%�u�+$��6$i�fG�vw^�:/�g�n��]J< �DVR�Fm\�.#�7O�c#,:\:h�z��������?'�X:c���t*���*N�x�b�9-�K�]�<əJd����R����\o~O���=�~_���b��\����]�k���5�����yx�	Ǥ)��fE���H��;�8;�=�-c6��z�M�0��r��wf�a*ǿx���6<ؼ���۸��X������j����ZE��u�ܽߋB�Y��)�����)���8;Ept�.�d� ّ+��u��`�zx�8�k�s��ktZ����]Ǳ���Zlw��0R]���>j�#�ڢ��W"ۗ(JANr>)�LŹHv�%��

�Ѻ��L˱u#F��$�v�^��'�$���jH4D�aWe�p n��)�V�EO����R��ǔ+� ^�Q=>ƴ�[(m��v.���(������%r(?w��v�8�]�q �aHB�_OS�(i��ˑz��]���J��>�ҁW{���)�{nV&UO��O���Aq�����1�h���O<!c�������¤�ÓM���a��TN��0����Ԃ�d
6��?������+u��4��K��P����IFC�}Gh��%�ǥ�h�c	
&��-�S�߫;ZӞ���4�a�N�r�X���0��fOA��^�T���ӊ�$��8�/���E�;|�����D ���ƽ�Xo��N	$��T����� ��^�t���<�}�P���	�*o��F�q���(+�'�e�'~�6�%wvP��
C���Dz(����!q�,�Y�Ќ=�MYz�(9�D)����	�h��� ��%�K���[<���:��0�
�ȥi���^:���l^x�3��	�l0I1����ߡ���.-kpW��:��`1�$]��/G��p�G�����
gt56%qFͧ����ק���*�����'�)[���Q�g�'�u	r�8�f���G��G^��O���+`���YЮ.�Q����F�$��0��bQޔ8�,���X�O������%��5I�rׅ�\�!���:h�mQ��P��$��Ǔ~N�t3�����bv�J�h�����fkn-M�k��koDxx���q��K1����_-�_�j[��ؑ?�}�#�3߆{M?Y�nt��Q�~<q�dh��I*gV%ó��`��f�g3���e���񛹕(p�ׁ֣�C}6��A�	^���TS&��~�h~d} c������'=ۙ�3�;��4
�٘n>��l��:릌�Ej���^� W�X\0	N��Cy���c_�f�/7,�B����6&����-ؔ���]6��4%��g��v�tL���چ�*��=�إ1'�QN�d4�њBٜ��3m�����X�O4V�!�����+����$��KVI������It�g�����������x2n���hH{)SX�I�ҽ��f}Ԫz}���¨n�/���� x�z�+*$�\9Eے�����H������ȗP�� �(�S_��T{,��Y�ڋ���`�Op��'���-DF�ޕ���%x'3��l���ǹ>w�ww^t_��L;]60����O�9��|�w�X���4���:ο������0��� ����W\����f���ꕟ�
FTWidD޻��u�+G�֧�Dw\RDQB�N����^��4H 煘������v;�n�A��#O��z��t���%�|!�ɢv�%�h!�jAK���M#+��Vtf�]�,�\�Dw��%��	f��Ȍ����,H�7�:3ۯ����Ec4@���\?
�qx$�Ր�0�65=?�z��^�%��W'�2��.Uc��	������{1�}�C��JZ�3/���ȋe�.�����愹��J��S���/�Kd`k0L.�@N֐����?�Q��y��8�u�=��(GLSv�]K�qx��9�g6�?0�C
�n)³������0l��Mgl���XM�~Ϯ����`��U�1���*�?|�P�{%3/�Q�pf-ʤ��+���k�UZ%5Z_���C\�*j���L�K@hO?F�W�&
��Yo�*�����<��CR��&�7%��G����L�Rj�_�0=1�@�lw�Th�I��KU�F2�	H���?kxS&6j����n9P�E�7�%H�I��h�7���U#���_��%-��z��[��j�-�/(̍�g�Cm���4_���+��NЇ���W<�h*��1>[N��˽[K�f5�Gf5Ĭ�+�S0�>��~��re�6�	 &��2e�Z�t�d3���������P^���ix/X�}��k�%HA���w�� LVp>�Fmq����l����pa.	�5[��h�o�����`*����AQO�L��
(�^%�pw�f��"Kz%
�27��k�t�Zn��A7_k+�7�M
fHD! JjJm:�Ӂ8�@��?��{Q��xK+.!��2��_�jY,����}scc���!]n��SIs��x�H��_]ϻQ�~�ݸ�%�����g}�"j�8�%��dy�l�/*&ۖ;'C:�8:�`Hb�%�1oBL�'%��޺�l��/�g)�s����MM��e�H'h�*9's��di��ʺyk����<M���?,Ox#���.d	�*t	u��y����|͊ҧ'�]\J��E�c<LqaCr��RM7-=��G��tJ���%��7 ��p�t)ހS��c�7�h a�O%
�9�K���K��w���r�u�#��q�2&��#7�cWv��� ��H+�2��RR��I��l�H�A�	`0a� ���Z��_��b��Z������We���h��hM�-��䀨���]���ڥ8[zc�7.,��cr���RR��jF��\J��^�̫"w�=7q�g��+�9�*���<.��6��b�Y�m
\�w⟅�@X�8\^r����
yiv�.D��_ɣ�W�Pm)_�r�w�V��&�]�^'d�+Ѹ*�����`Hê͗LA�"�	�^�g�5�Xع�)�~^�s��黎��x=�i�M�8�߳�� օuP���/;;���j��:���歭��{u������b�DtF�����>�� :��{���e.k2����dZ�ybOE�RQ3.JfERsr��,�D���B?+�sf)q!��V��q$!�w6���U�[��#0&���q�U�{�\��D�h�b��NC�k��`tJ���4
)�	OKk�}�WDY���2;,���(wk0��အ���A&��VC�Р"�P�.#�� P���(�2�ǱG7F�&�E�z4!�aҏ�,�)�,�������;4\]U3.\�2ee�H�8!�,ƺ�L�E��QV��0aŲ�"6��H��p��wj�+H.s��cf���T˚W�3!.hDy�5�*[XP�F�1h�]����yʱC��H҉�zO��$LN(Uo5	N���\a��?�R��^9�a���ṵ�^��n=��x��0�B8��ot��xx�*J���Bc���j�?�i�"���W������o�_����>��	��B&�5�鰞������f��K`a���޳(7�aJ�(����9��Ɏ䔯�|�?�9��?���3��iW��-�М�1,Ӫ0DWk�f�-Wl̦:U���7BMg�2��y��0�,�ya�$c�J�#����4�b��ޔ3�)��D;�|�Q��e?+Һ�2���0�r�P��
��f\�&4��@X������Vp�����L5�b�W�4���@Sȿe����i50��(c>�;��/;G���!T]˂���'!�ŁK����ǥ��<	�����	aD���q�*dj�X����������f�­\�p�`�RT�
b��O��c�Ӆ��uJ'��q��39eK�{��V�=Hr�
ۙ�b~38�M�YQ���s��rԗ��,\��B�0s{)�Y��W�إ�ԗ`�%��<�\]Ȗe���RRg�0S����j3S�f�4�#7y�6�D,�@E��>�5�kCp,���.W��(�C6��1w�\j�6Y���Aஏl� ˀ{H8�,�źk������a����9����ZS-��,��V1��������{p��z���X�g�4P�����������d��M���PT�8��װ�#����h�-��aI*y�$ی����V��̀����Y�<'������!$�)�4p�d�jFW��U�9��E��^	�#��	(4U3B�>T�]���PT;]�m;Cl�¥&��R�ٝ2{�S��z��`��W:��8Q(����hc������<7���z�jo���6V�W������Kǚ�V�/��b(\ ;���#o�*y���ЏƎ�o`���v���z���V/:{�^ww�_�û��]��9��w����~,deiiru���)x7�ʤd�V��_�vu��s���̈́�Nz�i&�)KE!L�(��;0�T+ j}�ל�|���lLgA'�2����vl-Bá�����9��$�/�~���w*��k����ĸ�#�[Q�uv�"��a��t_vy�9v8����)��~]d\�f���_�;����N���"�]3~�E�c�JAG�����u
�[� �2/e��C7������?B��^�u��qqx{�X�A������Rl{������ ����:k�����}��y=x�ۇa{���O�Q��n¨SRQ���!��T�O �@F6��`SK����?�5��ZwP(#@����I8���qx�+Q������֜���`���(�?q�Np�'�әט����I�&5`Q6Z�GN��Y�cm!���vє1p�t������eK��+��8,�Yv�+���B'��V�e�#����E��2��5g.����
������ҳ3%�y�����:�� 0x%������bs��k��ɳ݆	c�9�o���v:�l>4.z&����Q��s>��d\֛������D���p��s+GB�Ū.�4\���;����l�<#�[�/{��G�����K7�HH�QTC��1|�,��#_}���T���N>V�VΜ�$��y͇9LTh��->��k�;?��r���l0tJ�s�6X٨ʄ��Qp2c�����ig��`*L�; �>�+���[��!n�Eo��>���F�un����Y��S/�	D=�G*�`3��cC)˥|v�,�pe�;k_�B�ذ��J��zb5uZ�Gtn�d�����hX@��A%���zqؼ�%��~�������Aɖ���EC�88���[h۲�׿� m�u�s`߿t�8�^������
%��/w~�B9�6ʌ�a���-�6��X�}%�)��HT�s�:p�-�?�2�box�%N@�?֐�M�#~2����{B�
�^tYg]��(�vD!�s�-�!�_���g��\��_���.��%d;��]���t����}��	<�����(���� ��;Λ���G]|b��e.�?��9<�nÂ�u@ª}"��<n6��5N�?L�anp�ժ��TNΓ����/���Ǔٙ������~�9[�ۏI���^��xs�j½�|4K6�o��uR��-w�Oft/����DEڣ��<� "~%���/��f�ȋ�OK�������|��D�^s� ���T���"9���O�<����M�>�V�7A'8�pR�λ��:�}��c�}��>��/���,���">���F���j�A1�A�9:V6��$���|�n4M�1���������#�����ޝ�@���o�i�W�f>��8���:��	�z�*�~T�XR?�����wNA������|���f���
sU�fm㏗5R����Wg�Z,��0�ŉ�ѣj�0�w� ը�=����.�`��Q�3+wmqk(`�|BCkdDh��G�F-Y>,���I,��OY���
5it|�y݀N�tL��w�WтY�G�}L��^b�5�����T�`v[Dn��NȻB��MW����C#5�M_�>�{��e�j썧#Vf�%��-�f�փFKU��%ٱ	F�R}y&X�#���?��K���ۊ��#�p|��z��騼�=Ȼ� �a�&�H��͉r�R����b�Sa��ZT^��i�+5�;]����8��}��b*���jwਝ=r3uS'���wx%��T*ɭ��N8t~ۜF>��ݟ*���]���̤t�>�}���%�,�z]䣊��E]4��L�o�̤�x�῏k����/�J��z3����j��$�&��P�>�����\aŚm~W����/��V�[�az�L�� ��-�h{��r>�[�Gٗy�f��/�е;�n�n?�d�o�2���_���7�Fs��ͯZZy<�����>��V�����+������W�r���͍�3��n?X�����ݻ�LN���_S���Z�jDgv.Z�D>O�_��J���_&������ܽ�d$��t�̑��� r��c������ê.�I���gXI���A���"�R�+�4N�pr��5#O��������M?}5��k�iN}�4�c��'d�e����zc�.JJ0m�%��5߭�pmw�/z;D{��ǚ�x��0� �3�ܽQ�Q��p�`��1Wg�y��Pַ|�#��ք`�TB��5ʶ:��RY�a�]��K̸򑃃+B�!C%9I��!;�f�Z�b*����)˨WJ��E^�AxØ������>�ʳҒ��0��SNK��^�j2�2JQfj�F��)k%3�-=�Y>�Vκ�����������>�41:f���*�+��	�l�_g��4<��R�3���z���zt���"�Ϗ^m���(�5��(3�$ �I����&��{pLó,�ﰃ��=g����x�k%S��4*��"J}-�Ҟ��]�Yl�l��r���?�fxƏRz���Gt�5��,��!H�䥀��T�E"FO�p�5"[=:�~�����	gu�����;^�����`u����7W�M����F+3���lu����?vQ����@�+�T�8��>Q=�qt���.	9��a�u���{:�s0�,��ح9Y,s�:>{΢��Y�g�)���9��;<���"��dr�+ͪEtݪ��1��',[�S�zlH?�s�森 �3��%�?�����l����������4�K�;R
Q�ɳG�B:�4PYp�0�J�
�*s�0�YC�i�NF�c5��k��a��ufX#�Y{�
��IJ������h���/��|MO�D�]SBh�b����Ӛ��š������z��{<.\�J���R��n����c(;W�Y�e�x�L̫��a'+�҃A8h���0{��ל�d�%��0iБ�sq=���_�:`�����0+��ool�����	�z����̏|䂱�:��<=����R��ӌf���������K��#(-��=~ڄb��p$�˩�����t<#�Y���{��Cۺ��b��b�KL�'�E�Y�[s9����Ly������(<���5{���^���L�9���r<mz�`�@#�3T>�VkD���&�Dv]�APbDa�C+����uFM�(C%���h�m6�|����#��bT!Lϩ?����DǴ�ۗ��AV^g�F�h��J��5�ȗ������'T�e���*���_�n{���B�E��G�$�$���w���;�� ��]��%�1�;:m�D� ��"�4�� x��w�۱�ҋ�"��S9p�zK��k|l�?AnT/��75��F��AG9��Ao�#\�O�s�%N��\5-�j^j��tB��
j4$�� (0Q�L�e�T�
Z��[(�kb%�{��
�s��K[,��76����?�����֖��y �9|A�!{��a4�J���;�?�3�Kf�<�Ş���5炐9D]�&��#3�1Y����u�M߸ب<������L��)nզ�o�X<���̓� �U�i#~��	oLN�A(s'5]��0��p;����3:^��8ʑ��R���lr��$u���0��?����heTx��cw���5�	!��U��uf�(������Ji���P�rU�hj)PT��~T����d�N�c4S���`��	#B�7�!c{O�ڦy�t�5N͔G�1�w�5��/�1tPN=�͹��Ԑd\Gi��)�����*�<�q�R��U�P��w~D[ƈ^{@��;Ԋ5�}<"�P�BZ/�2q�d x��BQ���.6�x_-�V�ϜxmK�&�ߋ������~�]�H����_N�v��#=�>b��O	�6���q��=���v$5��<���U4�a���K�Z7f��S�C�PCh�:�'�l
`u��z�X�c/��7�GY�vf	�	��ď��k�+�(�&����
Y�1��S6���yN��~���ծ������������J����?�-�����ot�&� I�t5|�T+����\
7u�*u���^�3�]����{�S�[�&s���_��L�U�}fҺ��78�t�9L�@_����[.�+]�J��9�{
���;s�;) ����f-�����'@����������������I\�24܉	�Td�Р����w>���x$l�9��)���^����@��/�I�0Bm����{�F��4��4�#�C	��̴��9~Ep<?9m�G�l�b�P6'�J�Ј˂e槝��e���wS�p$<H0��� /���-�c�&íZ[�Gõ᪶�5��-nQq�t5�����'��l�b��E�Cۣ8��X�0��� ��Sך�,��_k"�������a9���6 �9��Ɲ_�5�]�?��6����4��뎼_s I'azY�Q�[�(kw��2�|��Z
�?	���	�9}���?��;����O[5�E��ך;��,�.��>�6^�8[��C��@d�	.�D�+��o�V1���4&��{L=��� "qJ�,R�K�3AM�t�dkP��-��հ�C�X�P-%�jj�N���If�t*�J�֕�~g��U��Na�ۥ�i���8dWA٩�,:@͇��PԌ�+1��� e��+H�X*���9��MH����-��jU~��L'�/p�����r��ӎz�m�ǲ�$�gb�]
�!�}��1��.����?|�:��o�1߉/Fa�4r���~�����T�5��l�T�,r��:���`$d�Pe�bt�m��f��P�ąŰ;�g����V�Aؼ�C���L����z�$W�a<E�Q%8et82)���zC�f��@{oJ笺��!ƾ��7��U lR���F�1�
����z�����@uъ����{4h���<v*-2���9��-kl�r
��	����(��28�K�䅩Ws�Y}V��g�Y}V��g�Y}V��g�Y}V��g�Y}V��g�Y}~����-R( h 