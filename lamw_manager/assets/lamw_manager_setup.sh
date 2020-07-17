#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="213632033"
MD5="2b14224636a569cd2672c9f276c8be06"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20684"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Fri Jul 17 20:28:42 -03 2020
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 160; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j�ʉ1���ռ�I�l��b��9TcCU��@����w	�B�#у}h��1�j���ķ��0�P!�f_�g��G0�bS�R���0������q�ג��^qcu��v��Iou%l��'��ٮS6\l3܀}hTG�_	����LF���؊�>�Hd�C�,�	k��(Nl�����.�����ġ���V�����5}7-��L��$͓�����1�ՑOgg�V $cr�8c�d��ǀd�X��G[>��mB|���-��^g�<���sՎV�3J��7�4��Խ�3`IO�l��zY���2�����ة��a-�vئ�
0��W�?�����.��:��C�Ҿ���j3�YG�_MZ����A�����68~���2
Y1)�4��X\�P�կS�$��zaک%�Fv�n� ?����]қ��z�W<%���ܜ�5� Cl��^��T��@�_V&�_4��,Jf-�i�o�\��%���$<>V%Dǫ�N��1��8�
N(�� ���s�C�j �J��P�C�r|��|�93����?��(�KJ^W8|��ѭѹC���d���Y�����ު1>X��T'p�.rL���ܳ�Z���G�Ƽa��]�i����(��	������)0��~�����#�L7���N�{J�΢��G$=QeRq�]��M:���)&6Ew��u�ɨ�bba:�*õ.�ᗹ�U����}u�D�/8J*���E�k�!Y��W��f�$o�h���\�U��((��N�P����j�]��B;����+^x�n����?�^sʉ���պ����=o
��4$�Fz�s��!���Ү��R�Vo��M�%
��^��9E�(~��W�H��Ym����ѪI�!�����E�U,���U�*4r�"�@�%�S#���#�Fm|�a�<���rPr��j�mn�u�1r����W�H{�E�/8�>�OwG��lZ�DЃ[�{O��h�G�dg� ��g�a��&�C彫s�t~�����4��0��uF-Ϻ��{���fI����~f�pGS�}���TA���X��*����:�gH�>���.��|e�ߨ�E�����l@?Ld�ft�.���QƐ1����&ЃGI��\D�s^�w���6w�<�/ە����� K�����)E�
L1U���fV�Y߀w��v�Ӱ�R(Z���5q����BrR�xH���[n�t2:��셺�����W�EW(V1֓f�]��A��h�Ey�3�-�-�{.���_`(�x(8N@��.^�_	�ЂUih�}�*�����l�Jqމz3��7��X�T���qwtM�ߏ�����A�6 w�J%g�wu�0��*:�C&DEg"C���xҼ���{X^˽-��f�()��`�����k)�C�3K+���a��C���!��y��&Җ��9ؤ���|o��d�M�^l��-t��{�ŕ3"�f�?)!���$W�<���Y�w��g[~�ӱ��ak����n�o�l&�i���y�2�W����
.�� ��Ol�E��	V�8>�-�i�K�/Xr�+����.P��&��>׼K� <L�Fe�$xc���-I]5)��q�=����w-T$�d�e:E@���UԚ����K���J��v�����-s6�>�/���DB��<~t>&S�f���H�X��~6Ű3p�j�%����̵�3"D�s~�F��,�Q��'�\����[��$v^-\S3H����\F����On~� Y�sМʚ�ĕ��軱�zrS�+!�T_������g�;����W�t@�8�� ���p�hl�����aݮ|p`�nP�@x�\dp$vIT��H8%j���j|��K������Zq?��pF";�8O��˲�3r��헰��;t6l]��.���JP�S��ht����:a�:a)$R�L�ց6�c�u0G�ѧ�v�he҉`�NM�R��N�]�;���5i�DPׂ"-��f��6*���E�oo�U˅ ɝ�{�§��3�1cW�]v�
��5S|�ӷs�?�W�BJ����}�,�'ϺA�	Kf/u�a�mi������Y�DL?Ӓ6�H�B���0[k�$�k# ����xa���(���߆r�ݛ� ���w�4
�Lea^��4YD`�ލC0���_M���.b7��n��4�o�T	 q���A�h��5��<�s�q�:_8���/����hx>���mf���4��|��W2�.?��y��A*�QHO:����(m-b�<��j7m+�w�	�H�,c�5?�ͯ����iÕ4%��q�Ca�gz��Jx�>3"�B�j�t�R�O�^���N����"_ �<�?�L���o�Q���x�na�	���m��Oz�[�G��wqǳ�<b���J2
^�i�B�Xr~�0��hhu�J�no���D㼄2�`#�r"�py�A�ۙ�1r�^��z5��)��B��"�H�y�d�\if��Ζ�^(�V��	�L�U������VJ����'#�v#�T�M��!V����o��>O<���v��k��A�x�rc�0��A�Mp<}��nc�F���߯�b�y(���u~p2]"FGBЛ�&�4P9���ě�^h ���ܩ��Պ`�~�S��0�M�w��=N1Ԍ4�3��w�K^<�gvOl,�-�^���<����k�7aj�)��R��f~���,\9Ǌ�A]���*Zam	[��c~*t��,}���G�
��b��?���4������Ɉ���t�}�|-Aq����z�D��vŻk�,Z���(,�e���ee�����X��u7�pǓ7�1^�\�"�E�}����XpD��gJ� �Վk�z�$.� 3ۍ���(��y��/��	���݃7�ڻ�^��4��T(���$�=�C!�CZI��\@2ܳB;΁�@H	�Lо�!+��vLHDǄf�B�{Y���'G���v��8^�Q?�B�D_\��
Dj5b~��A*ܔV�R�ml.D��_��n�vYp�9��q�Y��Z@4V���)n�h�C�"�Q��b�k��о�����hr+��T&�t�غ��f]�D��+(�=�ɧ_$�"�PN���1������:t�K�z#���.�DO�%��J��@�[�ZZDR.qU�/X"2T�Yi��� ����tH݀&Q����k����u������H�a���+F��*��ɞ��o��w	r��8�!K�W�����B&<��1�%�}�>"{.��|�;�BЪ8��������<��j��I}����
<��y�p�^>�ތ����蔁�����;|/��y
~��y�\ô��Q3ɭ%P�>w��]io�N�����d��4dԼ�7�m��1I����k��&a�yE��i��Ws���f`#
^nB%� ?�\���c�wR��	�N�q�bjݜ�4ܒ¬�%#+?�^��+ɱv{+b�Y�/�6ee��9�zp�\��G���W�B�c�)�������E��:>��a���m�|T�m.޿�\���덜����w�Q��E�խ���CI���N-��c�r�I/VO���?$Y���c�R�,�%"ȶw�RynwHAd�xO��Ȏ��-3�dl�B�~/(�y*���xm_��mXPsc�aQ�M���:�zA��	k�M�`��q�aJ���4���۴F�t�YLB	���wv�N1���佌�58�Yh�] ��2o��._x�sj�a�C�T����}��=��M��C�M�bD�֨7��=r���@�{�I;^&�9SuDʨ�JW���A��%l�}�/�Dn9��A�3}��f�)��p��M0V�_&���ܲ��۩��;B�#J��͇���C߅�e�=�L֥Pe�v("�L�f���%�~�|Ɯ�����8�O��1��k��`L�e����ˎEMn�L����4��>��񀄓-���mG$�⣹�z+C:�̥�u�H�hI��^6I��u�Lg��釓�"�${��i� ��̽�v1� ��H��_<�T⊙h|��_)�cf�����훔iٙ�1�7v_��(� ��t�nR��B.�!lg�T�1mr���Px�6���σ!���Cu��&�v+�xcJ�s��/O����!G����%� �5�m=@��zY��5b.�%G׋�6x�MQl%�':�Z�PMÒ�\_�j�?X=�0����)�=��g��6n�4V6�欺�W�\�ݢȏ���Vx	��Lf��x��s'��$��Q��X�Y�st�~�Nv�����H��q��2
����Q��+��a��3�'�2��?N���\�S-R���\^��}.W^�|������e(u��$���Ӻ碗x�c�b�}��X����O/Qw/$��:۝Y֣�s��(�v�$�]��g��8� >ME2��\cL�6B�6�~To��ro wd���� YPʍ2]��z��Δ���g�9��@-�44M��t�����	����P�j�̄�D�pD�
po5����8�kq8�|!@N<Sِ��$�hr���v��%p��G��a��
mJhޟ������8�TU"�N�W���ś��E�GЙ"J>�.fcP�Խ�'֡��U��I�S&A�4ؓ�t�$25���\���8<EQB�i� .0e4u�?��,h|�;p�[�N���Q9Dq�Akl���ݏAӰ�<>5Ⱦq�O�`"n�v��ҤՒxav7drDk9��Y�R������D ������X���,(9���쫗3�]�!&�.|'�i^�$���TԠص�sĪ𒹍3,����wW�gZf�l���*��a������ �Z��c#�Y�_�mT��d�ۘ�����3�F��B����j�*,�P%�S�����Y��F̽���l�7l�Nb<�K�UqXZp��~QD�|0 �#�	dv*��r�ֈX= !�>5U�2!���'�0����Q.�$B�Ce�^>��ip��e���X�S6��%j�و��Y�y��x��f�ḊI{q�;0�VA��(�����Bd �j,԰�S��]�b �ϐ��>B!Z�z�K+QpcT3r�� �M{����tad�x�H#��FJ�	�#;G5KLyX7��=c����0e�\�B$�n'�ځ��q��q�0���yF Tj�w/�C��G�*�����Vɼ��� �4�s����5ݢ��6�.8�K�������*Ե������̠��g���03)�X��%�ű�Ї�Y
r���pC�څ�Y�d Ӹ����d0\� mID��c�A)�s�
u����gV�'�!���o�t�����t�!��=�,lH��J����؉��
��k4w���I$z���o��0�P���l��T��
�ȥܯ�z�[�	L��7�r#d iL	��:�K�A�#|�sU�i�����U7��fa�P6�[E�$Z��$��;
Z܃�y�dyc>�aI� ���?���%~�s����M�i�j.#�=�|깓��.4V��n�:�G��E�u_�Kႋ
���d��)';	E@s�Ħ�t['*|Й�*$!�DPc�������d����l�Q�z/���A&���z$�i���"���G�/>Ӽ�L}��8�"�����ρ�C����,�j�D���}\W�f�6b�])� �?PYV(f�	WSHVԌ
���ܸ&o�����o�n4W�)�u˺%���2kͰP�a��_}��*f����mܩ*Z��'���[�*J]0ϴ0�����q��#�\XTB�kM�ꗻ��^fK�;�'Κ����e;�w��o�<�zТ��=�2�6�O��e(%��G�OW4��;��L�@\�s��.+�B>
����#ho��8���}���2f���dA�j�h��o��.t]6���������#P�~	T��a�)+�Y����M묬,�4���Z�X��B0�S���|�t���G����vd?66��m���ޥ������>�i\�~��1Y,M*�k�ͰpDH!|�|i�5�UT�	T�q�Zm¹��3y��ҵ0u�/�l~�%�S��Q2�vQ����Bh����#��{8)Vu"�p)����@Xn�Z5B�E�=��n��Q�E������1��
�����-ᇢg/d�M?u�F'��:�y�C�V���_�ۭf���	ĺ=筯?,���rҋ��~�Wh#wQK=��{ւ�n��~���ՙ/�w�5%�W���N	ӛj�>�Z�!��T�����'	tFN�(c�&b�[>BR�Ґ�w7y�8΁D�.T�Y3YLD����F�`V���7��	�wќ+ɛ��\�Arf�g�M*��k�˼�?B�.�������ן}��V��C��6��	��Xtٞ�鈚�}�[_��YВ#<�KZ ��� ga���m��A(I�tk��XI����vX3�Ʊ��	��ە��A"�vv�V�������q��rB�������9�Q����*�����$�`�9њG������FB�ۻ2��W�I�2r��\�@ݰP�aV����'Z5CS5�\���>�0�j�
Y�(�3HO�U5@��ug�-�i5�$�'/�Gŉ��v���ɞ罱b?>�nyψ�B�����ꥈ#ܔL�R�ڠ}�&��sqW�t�ڒcБ�NB*���]���6��D�>��)l�'�v�����LJ��S͇�UR�E�҉�Z��U#Hι ������z�=�E=H9��&`��ة��QV��q�����5�.Ǖ
��H���
'��ե0��ô��*t� 2w!d���f����?�	�8���aw�N̤��0s��3��q�fGt��~����t׈7qƦ|	�ewg���s��T،	���Ҝ}�(bY���^i� 	o�'4:��d�̞҄_�"��𻾬
��f	����)�[����(�c�]0�HT��mEf�C�)�@�?�Gdmz} #�]\�N��됧o���@��d����5KCz�N�P*��)Ւ��zđbU�E�0CL=Ӕr(���&R@j���^����ʂV��a0S+1��y���z*@�z{���6xg��V��Ɨv��]�#͞�CJDa'��,]��t悅_3������^s�y�*]w��[� `�!nL�̩<��)'���;c��|}��w�T׵4�)�=����无�]��H�C�~�8��=$�v'ʔ'�1���Ѭ}�o2v��H}o��y �Ϯ�6G�Ġ���s3b�X�/�*�@��K���h��羒Q��q��gc5#��҉b�����|:T<n9����k��)O��Aj�F�v�8TX�[���h�*�몝/�mzO�6��h��Yr���п8�A����U�ym`��p5D]�U�4:C���t^�:��:38�z�QnD�F>�{�N+���SW�'�H˚��w��>ق7\���\W��`��ʚ
3q�D%H���g��-�U��x�	ӂ�s'��I% Qۼ����LU+��<wy����@�{B
;]Y�^�?�qW�G��g��3��2�9�#wۣzԁQ���1am�����ag�5U�(ung��4&���Y�x���Fxtn��sƾiN2�|Ϩ������Z�;o�AH'}<h�$8�^IsZ�[2%���8�gNjQz��YV�&5(����L~¼^��o{3y�%�g�g@�v-�S0�I�������Cs����\�Ƕ<N[tr�rm�~��=����x��db�(�;�rʀ�I�js�Mwd�W�<K(1ԇ�R�?:�0�3�#�Ĉ⇀�ֿ��8�~�+3��F\���Ms �qY�B���\z|[��i�+�<��h�u^X[�����)�?m�{�O�������+������U��w~V����w�� -��i��C ���\�h�UtQ�-��Α�Z�)L�1Ԧ��l�sGD���� ���|���x��I����(�F�R�3w���1f�:�8=�$Q��PR}p��ٳm�#���9��z������Nq�t���So��j��v�#c��#��H�x��a���?Z��:����A�1,�@Ox�}���
^�f��Y�50Tf�F�>h�ʥ�v��yg�̗NBt�FlMc3C2g�bI���z�*,�����vM�7n�wp�Y���
�ta�9<(��||�rLH�_��d�[rME�"ceH��a,��� �n��6ˀ	thJ?H�C�Y܎'��A��"/.�/��{��jYk@�Q�������uE#Jʋ��ž(����W:C�$����d���l?c�Q4���yZj�{��BH����-�H���dr�G0LFP�yh�-O� ����ꓟ�p_FH����Fp��~���4�B�`�q_{�Y�d��v����7��]!糞Ʊ�����(H��A�7�T?�F����:���茼�"qhۛw3�"=.��a��ż����F$oq��Ê�0�N�1�����Q�����Ǉ�d�5��w�f���Dfzi�2�6���(°���iL��t*~u�����M�o��x?�U�p�B�ڍ�u����.)���Y����Qc<,���sv%<&�%��Kը��]���3_��}���F����^��5:g��le��<C�/x�D:g~����) ���=���JV��܂�暿lж7��0#"{[Sz#
��V�g���wN�{����觧�f��[��� :}�c�%��I�Ms#�����8��rW�ژ�a��Ѻ��b �9��u�_�"��wD�ri۫��l���*�`2�3f+�p�*CN����є��U=X�f��U��k���̬�iw}H����������֡X�i'��ᴗ�w�&�{�'�rUij�� :��Y�7�����U3ߡ!�5����,,�>����K��x�*D��n���q&%�>����kJ+���R�� ���Kk����ǧ�oD���_/�����L� $iV�M?�p�m,�Cia���Ó�X�i�+^�����a�8%\@�(�� L?���	̃����g�<n��m��-R���/�����Rd���w*��Z�f�M�\�b}?��(�� ˤ=�ח�~Ǝn�~=\��(�23�0�GwFr}�����+3�Q߉��oda`��{��\b���Ѱ�%���w��@1Ƅ�5��'���y���B�v�q�0ʳ��X?LR[$��~P[�ϧcs���Ѿ�qp?["��w�%�����M[����\)>/hҮ��׃��+��n~���|��>7�X��ٽ����<���;�7��B�-�*�,s���7;��0 P���*�z�`��?�sp9�02]
*̤���ݥ�ڽ1xJ�w>����q��K.٢�yO�cv��w��+]��4Q(263�� �kԆaC�{zD`Q\k�B�O���o��హ�����
e6�`�����M'6�e���]����[�#��$�U��aj�����ދl^���m,�Z�`�`g�"���t��F�P�ȑ���X��LWn�za�����}g޴S�7�B�Syp�L�M	����+�9��{(�ip�{�+jl2s�rBYM��w�ۮz�%�$ЋEߠ!���RY���/z��h��J��-)����:��-@�Q��K�����h'�^��a�Q��,{[:�.�j����뀥�1�k���v/FGa���ܰU~_I"��/F�\��{Lg�V?������9��m9��Ty�fEM}A"[F �.mΏ�u�F��gE�6H�X���q��f�Wc��p��*u�\���������c ����w��e�/��5�B��L;J|��t����<���r���6]��~�h��=֥�+MHx�R��V���,���3e(�@% bbŭ`���`�o��%����A���pX����&6�ӌ�N1,<��v�,̑:��DD�l�jP�9��Z��N1�����bǃr���G��ۿ�8Ԛ�d�J��y,ʤ3ܥ�k���Ug�s���6IW҃�a׶����m��{�@a�:'��5m��6�o�Y;o0�t��'g����m��#R�*��f�;��m*~F����b|ܮm_>y�aI����čŇ:��,`�S�a�cx�4η_ݢ^�;��N�1[� �fV��UӰc`���7�ũ �i @rbX/d��~uк�<����!l,�-!~��J�۫���S��xM����B�!���@���|[ѽ�@��<uC�n�Y)�ܳ�Q rZn^8.h4E/UF� ����R�<H��8%����Q����8�/8̕�>P^��o��昫��x�z�N0�^AHˊ�/��}ǁ�_Q�U��:%<���v�����~��J �0v��S�X¥{��<�- 
�����e��"�3g�k4��Ky��P��0&�y�}{%ޣ�M�#��ٜ�3��a=�Hy�P�бDa:��r��z�����n�ݎG��)���Cn� �,�SVe=��DL��?NX�þ�Q	�" �+��������Y�3*�=��0����r�CTxk	��;���إ殈6��Zs�dy��	���PK��؎��E]S'���D6��Γ���>�RU$�@Ӑ��s�a�S9/�5!B��вvq���4�5�i��
��sh���_
ѣT Mu�*��?���	|.�����h+/λQ�M�݃7v�ˊ阚�)fj>`cC�&nJ�*�g�Nr�Z�	�i��Ҙ�`ԯ0�0[��z�UP��q���u̮��^Am��ڔ����W��o��,�\�oh�,λ��X��S�8��/[+�^^�  g��~�;��%oN�9�|ihR�d���#�d����j̠ 'Zw����mT{�,�ѕF��\�*�k%xܬ�a�ֶY�N=�ף/�%a=�g!�#~1����@D�yW�[�uC�Q����z'� ���y�n�ޫ����$kߏn:U�i�1����=��{��r���,,�Ɉp[�$>#[��w���O�j��yn]�V�S��Ƅ��d����c�$����\�u(grq�������g���/%�8���?:X�����xp(��ەVS��l��k%�lg	��1sG�����"��*��(Cי8p�s���UZ������߶�Y�[3�Ri��d���@��49�׵�K&Hu!��Ya�\��cF��*E�@G����%υh��P+�']�+�ʉ=xn��g������x#,|V�c�H���pHn�N�ts۲;ɟ�seO���U;�7*0F�0H=���W��?1 ^e���Q�$*��>�dS�'�����������Հ�I�$���8��`G�R��"�������麧�#�(B8����F�0=��nwOF����nZ��$���R��iI+ɩ��*����	 5��)OW���P��w�5�w.!����7k�������[

lJ��!�2/r�]ob���>AJ�����%8�3
/�e!��t������U��`cUa��Z�og1h��t`q+ڧ^S#K�ӵf�3��R5To�L�Xq#��@i?K*��%K��Rx�n��A�-�������?���E�{�͡�e}�0ߙ��3��_x�8ӈ(`0�ϣ�F�<��X/�bw�膭6O^?�g4B��;s�6_��Ժ\��,j��7kKc����v�?�\`�X�]Ͷ�n��uqeL	c�ju�$��X�	L���߯+PA�M3���-�������Lf�VjB��+�Ղs�B�G'T�Jg+7lEam��}@Cx�Ų�k�g�%��!��%�GE?�Ҕ ��љ���˹.�Փt��X���&�Fg!"���?\TΟ�X��KC��]Aց�G���/E0��5�:	U%a5f�}(�ή{4
�`6\�
:�	�n���.uhlĲ�.���΂5{���O�:�
��`G*Z��3���D{E��y�7pp���EE�J&�Gs*)��"��jDȵx�T�� ��+o�ۇCKle���1Z�LH�@6^^������v[���zH}_��׉�äV)�p0��mGj�����m�)�@��͒������Txd�_�!p��"���,����ҝ�!���El����oe��~L������W�)�7	iB�[��NJ��7��.a�\L�t7$��52�l�N�!ό�rRв�P�֪��˹�Ǡb �CvSX�Gg������V_�w��5\���z��O�c���aL:@�-~dS�?��c����Yy���Le�=��A�ۂ;:�!���\+ŷ����֏��z!eϟ�qX�B1������k �H��[��,g }uO&M��|AdO�/�F1'���ۿ��?%+�X�r��=
�#c�ǪhE��V�F�7i�eu���@lE	Ey䷱�=�{�!�Pz3ǥaL��kh��N�*��k'X��bgGW����=:�Ic�+��&�^�%e�:3���ߣ��������Z̷1�B��k����c����~V �$2o������;�u'S/)�`�C
��ޱo̻~lK2�m�4�9vb6:7�b�H��:^9�����W0�u�?�Mr��K��y8��e'/.e�iL��eV >�D���P�V�B#�j�+^!�C�g%u���V�}��1���j�Y�M
��|���Q����uJ�%�]zP 0�Z-��}��Kv�=�ûwYy+d�<��v�gR�yS��M�#w(�j��zU,�+��>W�.�B���]>K:��������*k�'Do+��G�}7���'N(pu�&��U<X�s�'��<w�a/�������K��O5��z�h$.�>�E���qG��$���9F���0��Vb!	�-�ag`��?��Ӟ~e�`���r�h��t��|�;`N��/�����BrՍVK���T��aڮ"^�ii�l�?|���7I�r��3Yp?�6.M��=l�A��9�1rWb����Tԣ�a_�K�G�����k���+��|�xDFmtqosce�
��Y~����"�]�����?��NJA�կy������*�EӮ�����8&AM�r�T����෬���vx�pAR�m�4UL���Y�rVt�}� t`T'�?���G��Z�h^����6/�$O��F�]��c��=�}E`�h ���z��7]0|��Դ���W�5o�(���G+��1�A�d �Sƀ�|�z��0	�X�&��ػ-k�:@/�Ň�,�~[|�t��dY0.���Bg�Q�r�.�arRh|�!���1� -�1��6t�jA��Y͘7�l�A� l1&Ȓ, ]?�ڥc�S�P*�����AX�,FЇ���7��yu�DŊ���O�Yå�� f K��:���z�X*��t��R+��f6�0^^��:U��T|���h:/��>G��cɥ}<��c%��ޢ6��ܲ�U��o�<�_]�YA,U9���0��^A���X_�����7��q�r���w�$]���_�fھ��G��l� ��{ȇ�5+������<����� ��c����9���Z4P;Z<�zT �u����8Է���{��2�#ݿ�$K��1"��8��R��ܷ,fu���"��l���l�	z��,����U����l+d7��P�<�0����7o�d���	�Hl��1�pK�F�6=�B�@{Ӽ�I���/˜��/���Ĥ��\i<$,�[ߟ�C%�TM�T�^;a� �$կ��|�"2d�<Q\�>�WB���7����<��?�g&\mz�X�F<��dyz����������<��#�P�E����i�ه5I�1�����.�6	��M�1/�7����1�u�@�4�7r:W��$����E��#��\!	��Ga�ᶴ��}�`�N��>���|Ejg��,7B{4D�^ Q�Y6j�|o3^%+Г��4��	>>F�iW��h���Y����dќ{�߀�k��dD$���I����T�i�e�uF��<����B������m�%�n�yX�hsV�*��Vs�[b��#�7T�b�)'q$m�G��6M�+ ��|�E�vi��c����"6�<V���:�j�cz�S ����l)v"�*��J�	M��u���S��i�'>�.�p[�%�nT���~c�W�)K�P�~���3@������sK}�l�VJ.�k�_�&7�\�/;ɼפ��ϩD�����itگ���'n�U�=�{�Fӿ�x0�h"�I���,d��2��՘�e��le����~-�t#9N|�)R����T���n��LX�?����+��Cw�*i�ˑT�Fg��N�d$2�� �Ί=�1X�?Z�CC��`��]T�_}{&�Ύ � ���R��n�^ *�wiT� v]��K�lċӰ���H�B�!�RW��2s���b���)���2r<v>o@�ʁyN+��SƬ��O���|	��I`��k�b�w��J��oO|ȭ��V���@w�T�6��p����w�E^��`�7,-TKΚK\~P g��`�@�O���e�/26�/��$Iρ��w���i�eu�iq<�����:xT	��X7���ݍ l��څ�b��@K#�Y)��V/����a�Rɏt~t�-�k���MdlQؖ�OB��#�۾��9�Sy3�1��L'K;�a�p[(�<_��V��[�a�QH����w���nk9k��0lsgz��u�B��(]��,P3��wͶ�_��!-��f�G�Jz6�M=|@S��9*?�o���o�}�i��Ֆ4�%���H�Pw56]@�P�����L��C5��q�2e���*4r˩&�'zU�ǌX(HA�Z.�D�j�^������K�r��|#�yT_b|^��%d�"n��,$�\�ihu�]� |9r%����}�TY�3^���=�Þ�, )����{��Bn���n7������w-C$y�}%���b�B?��џ��{-��O$R��z�f�.!&�YK��M��ێ�ŌM'�NL=C^hq{<_g��ρ�З�
�ʀ�2^���g��aZ�������mЛ�2��Z�	'Vi��d����]=�6���JN	ִ��I�ވA��+����"/��f��>�ߟg���L�J(U��d�Br� g�{�� }��\�,�l�Ӡt-?]r�ެ��g.�@��^s��r�BP���	�:nP�X�H❗�'�O� 愑'��W���E_������.F��/+S*yh�����r�ϗ]�d�l��؇�²�`o���[���s������8LQ�Tq.]�9 ]� Hnl��릖E&%�?8�enJ;:�aSU�RҪPWh-)�X��|F��2��f6�$����"��3�My�-�׹{���~N�ln���x�2���IR�6�b�wUb'���[��\|Kh�Y\�-C�lko'f�`˿� �"��q��\9jT��}Y�������i6�]�Lp��d��`�_u ��������x��'��*��(N���9�M�B�^i��i����J���A[.��B1�6]��k+����|�pX� 
�%��OZ�	��ʉ�B0�à�-���|�|�C���nK_Zg�� �}��|'�.�*[v9a�`&P��,�%������g��Q�b�jLT�z_�\.�x��ȵ&mKQ��1>~.��U�.���7#Uf<9ު8^��$Q�}�=��<uu�L} 4FK	Ug�dG�g�/�x%Pg�3\8\����˳��=�q8Q5�[{~���7e<L��R����B!|��O��06҈�)?XR۞�v��H�s�WB;=F��V|2E|���,�C ] ~e�J<˷Y]�����~��!��{�^�����b���yPe�f=�&�e����aHd����AUM;�9���E�@�%���o����2�ı�L[�Ak�@�!vq���Y�FF\i2����>�$[�����F����H��h�n�j�q��}tg����A��9���<ÆF>ܸI����/`��ڴ\��rUZ$�i�\q��~�;�ｒ��r϶�'xΉK3�G݅�lJ������r�nc�e��@:��E��f81�����`q�׶�_k2Cw���� T'e��Q�ȷ�����rc������ly[D`Er0���t�[Mp=�w/0l��տ�6�M:����y������	L�Z���Qg*S�zSF �f4�\G����G�o��Ql���q���2�����W�H]R�T�-F)�ϳ��b�$q_����'�qLZ��x��f��������z� �]�<%t���c�=F���S�h5�xZ�����a��B�U���^z���`)�����'�n7�i�����W'��>xxq�`�+fg4qq�P���}�B<`���ʝj�I�'ڷ<�f\Y�4\\��������2���V���������`�hW����H"l''4D"S�P0ߏB��k m�~E��+�vKD\Nt6�'�ň���mQ��N�K=�FU���^y�Njt+xc3E���s�/�{θ{�0�j)�l��q	D��0�Ӯ�Jl|Iu���<r��.��:'�!�y��ͩ��܋_uKE��7ə�J�h��?���4(h?��~��C��i�����h�71�a3�����&�_۸��w,E�-��_LGȞӅ&���`h��9�Y�$-n���6f'/�J����Pl,��L���N�pg-.��~ZU~����S1�V�X�}�1�%Nh<�uW2hP~�ɢ��u����sk}��[ϓg�R3k��/�}T� ����άu���������H⠄h�*榖qy�٤�/Gj����g		Eu�C`�0����p���^�⾾
� ��ey8��[�<��#E�HO�OvqΖK����ʦ����B�DG����(s�>�N��T�	�M���,���1��n�Nb��Ԛ�ڥ�#ْ�bb��^'urK��Qt�'����B�]~�y�=�\��*�� �Ŋ';''�
�wL�2?���hN�6��C�����m���zZ�Z�-"�A�kdH_����P�^+��ᬣ�jje��ݷ�.����.;�30ߩ��y oZ�<����5��1�$�!��:��d��$�>�w�"|%��u����B�ρ|�"��-�5s�ڍ"S���jZ%�IrϨ��\,���-��LS����9w��ǥG��{:�N�? ���Q	g��/�$*6��]�غl�\�j<]8��
��J�F�x�1�>���MR����s_u�f ���')�_��_�8� �d6���oڊZ���)��Z3��lI�)CqUK16)2���sXR���z,[}�zeu�;����±hS|�xi>ئ&A=������|U="̴gY�C�״���nW����R���qx�=���p��a�R��Ĺ�&Q��f�n�o�&�8�cR���xD?������ �I>�[P�q�����;*o�ָY�T��/?�4�!��I�]���4�>��i�T�Nt��.���Ɍ2����ԡ��]4��*ʖ���m4`�C(���Q"��
Y[�gA�"�sDX�g��3�H\^S#wĎw�s%
�P��Xt�2>�As����"���k��K��X�e�+oz�ڼc�$-��#щ]��" KU�R���E,?��y?�h>!t��X�H7|��+�U^;�(��~� UK)D~�n`��Cd;�gt����J�A0a����J�+�-Z*@� �F����a�I�[ ��a|�e��\A �*��]��k%���W�R\͓!V��h�{|�ɞ�[��N_�����~Y"�E4*W�Ґi�6� ����Iu�Q�����l��ٴ�1�Q��,���d?�;~q��h��pY�c�]=��T[	ʎ���_��� z1��^�:x7|��r���Iygz� ,��3���`H����j��uP�9	3Ӵ�g�0���_\�ѤìN��C��*���b��˧&]�4e,3��Î��_��1֬�,A_q]��4�j�&t<ӽ����lJ)T��9�C���C��O��q ?�����[���"�Pq�̡���>B�ΐ�	���L���d�E~x� <��a҄rD,G�R6y������ ��?^H��EK*��j�XM�I,�¾�a����p�Q��R��.Y����H��b  rd_kB~Q��*�O����ɒ}�J&51g=���cI�P���ɂ��II��J�޽m� �T�icJ�Y��K8F�Ҷ��m~O)�#�Ԕ°�����0�|���d��E�a���Mr�?�IYz��$��F|p�֯9�
��v�?~-���%@����A>&�4K�#5b��WBM),s�I^z�I0vDư�
��1�Ԛ���L?f����G��
�H�f�t8㹼��:�b�<ϋ��k mD�AN��9u�����[7���*<04���HJc����阠���!��:���y={�(����["t��J?Y�G��4�{9I8p���~)fc����A�t��C�iр�}/���o�DW/9"=S�Wy��/��_�ԫ�1��|H�����q� �Χ��j'P]���
�R��P힦�DI�g ���}�+��`���>c��	���0�C�aQ�@��ǘi�cSJ �Β��;�����(1���AF�O�����[���~n%d���9�+�T�Ŗj��́�G{�N���+d��y��T��D�sCJa�Ӎm����83y��Ղ(aa�GP}�h����R q�A��Vf��z}��t���r%1�����˟q��|g�z@mi�Ԕy\�.����/�k�Z#I�3	��.K ��{ O�$N�e�2���o��'��D�._4JM��68�q��?yjB�G\T�.�RS���YM����o75�ro�T�k�e͕����Q�&��P��k�l�BT�3&>��7��@��S*s��r<�(
���q��@�Y��S_���0 �ȃ��֬� 8$���c�[h�r�:�`�r��:=�<�O\6��f�cƌ{�Ļ��j�'e4���ff6O����bR ��� 5�8��U?W���5*`�MA&M	Eft6��侦~������hs�z�u��2�N������o�����M��%!>�����̹W4���]A�S��<T���C��q����"�n4,���|�ޘt��Qa�A���oxaB���X��,\�B�/W�e��F�"��(XQ�w����Uq�tj�X+�ѳW�F��]$^(�'F�hTF��̝�?���̳J�@�-tv��-�fS�	���IԬVa���E�%.�F<[ϞG���v$B'qM�����q�� R��L% .Ylφ\��$�����%M&7�2Ԙ�&�IU�@��(O��Vo-:�J�||?G'�{�_&�8�����9
O�T5���{�lzQǇ�غr�ä�M-	%�gv�Fĝ�Ab������=��0�p��b�D�Q�
�鱡��^sO���h\A����3}�+n�0�ع�qK�?{�j���eO�%I��0�5I������X'v����@b��~���Wԁ���M��N'�T���y���!�-u��<�U�&7�c��ɤ�gA�7$M�Y�ٟ+�a�\ۧg�8��=.�-T����V�
Z�LI�PE�����֌z�PN���&^�jB\ě�cA�A�sE+�,�~j<�p`<i��5�;*��h�v��!�w�0�Lq�hj���s�v�!���d̉S9.*���zZ���������3�1Ն��k������~h)�D����=r{�k���Y��aĿ����-]S��z
 �@{�g"g����}6q��$;�����|��1�*�H��ɥϢ�U�t�<��nY�����i����D186�Z���� ;ABG��p��������9i{�)\P��5��c3����4�oΞ����1}=��R$Tu�d��E�ʉ�lכ.[ʁ"̤��s�ܕ�dU���GW�`����;`�tY}d�.C�3P��� �n�qv�8ŷԅ|���ͳ��h�Ȏr���f���<���͍V�u�he�)wX�2>�bq������(�QS��C�	6���(�|�\��Wە0�k�	���5����d�5�C��c��#��w�����[�We�I�|�c��0�}d/Rţk�+?W-ܾ�=/�\UID���t��:�� �QӘ�P�>[O�q�\Wޱ�m�L7�(]B�j����R%y��bM�R�KЬ��S�.�{J�;K�t�4�UdKdZA�|mN�Nn��:�q�?�W����ˠ  x�T�-o	, ����A��e��g�    YZ