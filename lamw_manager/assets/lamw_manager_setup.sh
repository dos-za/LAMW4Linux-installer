#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="499566867"
MD5="2100807a37d41d918e1bc84fb8a4e290"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19058"
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
	echo Date of packaging: Sat Oct 19 18:47:17 -03 2019
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
� e��]�<�r9�~%�"��	Y�.�h=KK���$rI����(�@�Z�*N:�����>L���l3�:P���ĴlH$��3��=������6�_��!��=�ono?�񼾅p���Ϸ����o�x��<1t۾[ ���_�����i_��������;��!�G��y�00-��5���gkk���W����������_���64mm�{�����*�ʹm^3�3�`0f(n���T�8"1t�iӚ�����re�	\��Bod2{�`ߙ��*W�"�ޅ��fm�\9��P���u��F�'la��5g>A�/(YAW��`��>8c��ԁ>�4O�%��� ��'p!����G6�����0a6n���	|�f������A������B�6\�4�	��b0��|t |�Ƴ�^|��l:� #0�?��k��&� Y�O�����^;��?]��r�0=0ƽ7�OG��G��y���_/�F�����pHtʥ�3�|�~ �k�3,����Af�-}2��� � ��u�����NL;��S������#�����r��26k��4���� ��P.}��j�wm��.c3��V�q'Ԥ!�4_�x��,�������"aB,��㗃N����h��j�9���"��E`DCQ��j��$���:i5{���p�7�n�}���Ҳ��4RI�N(�� ��V����-a/u�cx*�x�?�P�,ub�}��=�w*\Pb�rFBmI'�Eeq�;��pHMAP	�	w&i����kNt��?P���@i��r.S�_�gN���a�#��]p����a�gl����A�o>?��rPb��rd�QH^��GL��+鮄��5�K�m��ͥ9�$jO�PUT�+_�RMR��"-s!�,E�yS�z�����/Ɓ=�����c��n`_��phw��׀������g�!6�}�67M$+��چ:D��`�<\�c������^�yr����P���N����^�O[��ޥ�1$n�s���ޛ�~�����k2]k�;���`w��N����F��!c�C,ć.��F�(��5����j~��К�C:4�}vx�`Bs�ByqBaB T�_R�>E#MwJR]����F,�Q�-(��,q�4կ0�AkL�R|�it�D�`�w��f���o�h�ڝ~CQKl�(����"��n����3�z�	����a�ͦ��u�����LIP�·�+Ey��*[(����yw�%(*i~�s�hլ`���Dt�`�"�(���������v��3����lȦR�\�#
�U��PG\�r]�݅CD�I�We��~<kwO�'�
�ibpT-h~��OP��
�������P��
V#�K���Q �(Xݦ;���*�U�Nw$� �:��@P����0'�E�[��"�Cy5�g-@�Fh!E9('R@B��_[�J����GK^�:�Dj��Ś��VZ��t�2��񈉤 sY��3�q(��q����3�l7�a�A$"�ulN� �a��Ԗ���I�hp�&�<;趏�a|T���4^��(L�������7E��,8o�rR�����K9GWXK�)Z�D�N��K=Fb��GW����M�`���ʥ(:���Bx謁��������"J~����OoT�>}Ӟx*3L��_������������m�ll�^�����M�����T���?�@.�SQ�+���]���3��=�1��@_#L�y�ڷ��1[�%6^�ι���5����a�w���k��:m4��*?@���~4�7�6�����uv����}��VC�����/G��9��3+� ^��^�z2�D�/�V�h���]WC\�M����&r� ����(�*���)�����vHZb�~��\i)4Ւ�^d�+�\GICU����<]C � �6�����R��"�
w����b3 x���\W6E=�"��h�������SZ�R9><hB�V�##�%DS�E_� M|{kD��M�G�/�M5�>���v�? ��l�J�Y���?��Z���X#F��1"L��?V�sxC�x���;��I zZ�j?i3�Q�k�[dCa�^*���A�)�ϵ0Z`���[P�&�_{���#Ƹ��&��ju|�d>���Im-#�F�PA��
M�*1U�ǥ�Ĵ�i��qPT*	ѻ��<�,�y�AzWT�r����	#M��JTJd��6�2���DGQ�lb\e�,���he
(Һ����Ӛ����A=�|��:dD�y����������X�Fn�E�����z��d,J�hm�E5^k�w�G���IK D�ZC��h�|�d�KK����a�*ON��>B,��+繪T�m+��x+J�9o%Φz��1�MdB�D�+��Q��)��� si�F#Q�!��#Y���;�B�p���X{$�,���f� Iʘ%k*��L�ӧ�C^�Q�,vt����:��@�=�0t�:��O�D���.����(��fʕv�6��@wMPT��\;#'�V��a�O��ϣ�s�,J5���M�"��o�cǶ� ����!��J&�2�QFaFE�/t�X���JU<��<�-$O�";'b�A��5b����&A��FG�%a��}��10��1?�!'�K�\�,�إ�88>�S=hoR������~��I�ϓ$�+0 O�<��sK�FI[,�t+R3S�-o�W$��K��aU�o��U�V�&͕4�%s=T���<�E��Y����'�f�OQ4<�AT�n\-��L�m��&Y��4�ę�Fn)�	Æ�<�N�C�:�*�^�l\]�.(G�b��
q�>>�*j�g	ʱ=vv�(¨P���50q?�8�)�K����i����	����3�ČQ�Y���}���R~��l�ĄC��j�AL|�Ov,}�!Ƹ?���P��o�Oz	T���H'���)_c�J�i(���p��2�w:�n��@��I.�*9���S�o=J<�����_=�FRg߶��;���}�\���ۍ������P� LQq�Q��3�)�]�����p9����L$v�H/�����(|8g�hw9%b_�_>g;)�ħ�@��͍ML�y���$���Ɣ�PG;ӣb�)�%���
���A4}6�LqA�KҔʈ��.]�q��*�8�C�a�%s �e�Rg����L�p���'�0+�xjN�6�(O��զM��F�`ޕ��x�X�w�Z��޽I�r�OY#a�Rs�u�F��-T0}�*��Tw�T���<1.���T'��(U��<Z����3"w��Éps��]����8.%5l���̝��n5�:��h���F3aK��}�	Y��rft�jg��CH�9�<��z���	jN�e�	�O{
f���[���4��S�_��n}�V�����pcHX�7Q�swĊ�L�*jbY) jN�������F*�]�{F��pRK��|��А^CT��:bD�C���+��=A��4��u\g�\�nw��������V�Y��g69��	����S����V�5$��V�B�#��j�g��s#�+�Y�`�ox��i��|p�o�F�Bš:�%&_��-���YaNC�vp�LY��X� J�32uq��1Dw#/�5�Ml��E�ʵ��y>����:	L���-a TI�\
0/�����ڥ?�jdG�%�$r�\�P��Z24a��g�O:�V@	��~�y�fG��qg�+�0�aml�ώ�IJr�����d!�*���|�$vA9Qڎ���H�� �2i/�P�{Z%�
�)d���̅��q�_��>���bw���/1�L�ʥ��k=�W�����o�S�:�U��oƕ�O<1r+r�U/a!
s��e=���"����F�c%��w���*؃J7bC�ݾ��C��:����E7��c��~z�8q�8��S0�F�����P#��ￇ�u��������9��\Hf�%���6q�R^�� � ��W{a.j86�7��6�%�d�
��kڦ/�g�#����Tm�;��
17��ƥ�ٔ�н.�sEgF��1�o�΄A��)��i#u�����<L/�e`���d���.7r)gG@�ޯ��|%b�YM�[צG�H��
��c�8-s���1��<̑����˨������56����):ut��`���mi7="u�?�St��Sn�$��=��Ur�qE��L0K�tw�Ք9j��N�j8���0\T��F��5�P�0,I�R�̍�A) �"�X� u6�1�L��t~a�5O�oe.���V.�3H���1T��;�̽k�S�h~�."بt��\�g0��i5/FG�t??�ޑD�Q}��j�~�_%��:tN�˧��|�'z�q�����V.�q!$>�E�1It�����Z�`�����PMX��ksvT�s�:1��hj*�*>�����j猈7�	He%��L1��{�K�1*]����7�7�.?�+\L!�bD���W?1�(TՉ�1�[;5��s�=�
����v���g�"����ЈAQ�!f /-G���=�L��\4�h����$E�%�����[�Q(��nT���W.��X�.����5c-�l$-�pd\�ߧ��vx�s_\�AO.�f�s���+�K����;�,=��Ud����ef�"K���m���R`�pnq��g�1��rd��R��#G��z6K����f���52�*�ܙn R���H�柿e�����e#״%�.���"}E�}�b�B�Y��K�ڣ��hVݪ�/8Op�o���4�+�>�_z�+sa1R�6�"$�ٷ.�:��Uˈl2ձ�`;��-r�m�-�.	�����tOI�ߊ�2���(�P� kŹ,C�+;Zi�������<TlK�pcO@)b�Epi���˝R�}	"��g)s���G��y,��p�^��R�\��E�<���ʀ{�b�U��W�K6���̄K�6�'�K��� MS|�L,�X�$+]�,��S	M�8\C!�8���:��C%b�s;�!b.�,�@�ZHr�(���J>u����vI���h/�H���0�KH�N�A�����C_BD���	���X������[dDd�A�V?^�M�Q��g�\|�����E"���p�Kpu>d��ҭ����ˤ{�uO�8ϻ��"��yb��o�gs�^mO#I�e$����y�A�g��,����J�3��A��_��ʢ;za�	5���W��)t���c�a`�rv�(jvO��(�A��N"҅�溜S~�1�)p[;����.���^�|�5Ͻb��:\J�JH��� �Qc����%�~����H���J��L͙��Ŭ4�៱���/z!�I������C�˹�ۏyW������O��M�\Yܘ�?�3@����>(�����l�(sW<�B��*F�&t�\���нb��� �p�zȗ}�W��/��/��/��/z·�ߗy��}����L�˽��-{m������#ǆ���_��a��/�@���̩���gr
ײ�W�6]������r��e�q}~����ǽ�,xz��_^����F|��a�+ǽ�ՃP��Qpt=,J�NW��0�QW�	��������������T)��n���4�$����y��cJ:��c��C�>�(L�S��3����"~�<�ww�o�%Vh����YxOm^���1���7Z*4�G3�_�v���,��]�'�=�?�:����I���y�}���{���F��9��O�.i�X��Ƹ�2�n��p$w��S��XRi�$l���:��/3g���m\2�2�"	�f{�/�i#U�523222�;����t�$i���)گ��=�T�=fU��t�a��a����%E���wZ����v����]!g�)ڲ��rŨ��y��^��_[I��Q�v%��2Cb�z55��E�$�Ȕ�v���K�r��yi����j���<�|*���������^��C�QR���t� 6�6உ򡻦~��h�)t25T���TET�y�IJ�F��Svd�ӗ�*B}���>���X�?��Y��4�.Έm�`~`e�q㦼�ѕ)į<����-�m��]8��}�(���������+�� }/=k���(���!����v�g�\S��V�n��u$�K�=��5�B��.%/�f#o�뢊X������@|�.�A�S�,��ڿ�I�!��
\m�voљ������k9d�2�����PP��V*�ʁ����1l�֌|��n��x���Lx�ieF�~����S*7f`Y^��f��,�W lI������
�jBR��M[��ba��Hr)�	�$��/#,V
��)���Nyv��)Ne�׋W�'cr�$�e�ě��"�'�� J�||�L�.�A�.����V0l�o&9MүE����_��(��i��p8G���?|��s�4����?���K��y�W	��z�a��=���%<�ۈq&il�{b��{#��ZF�<8�D,��;��pf�(��Ix^>��$��#�?'~b�@3{���Q��8	����G���� r�*��M����پ|�'�xbDn��/(�D���9�q��t���?xHCJF����qN{�6s7,���ѧgN�O��[���~l8v�sş�53�v���ӭ�)������G� 1P���4�ۤ�C�x�d:��*�6�%��|�i4��Mz�_��Q_��h|D?�L;#d�]"4�xm��>|�^ɡ�M2��̾!�� ǃc�`v
�!�ؒ����v�jF��ӡ͈�@gz�*ɾ��R�Uׯp�C����2LJ���M�D/ޡ?!���x�Y��e���v8ίvqE!��T��(毭9�|�v��L�>�X(}�'�o���M�?�)ED���⹧[�]i:�����`2%�΄֕V>��z��^��L�w�O�$}P���W)�YH�WY�c)r���?��[�~��Ӛ��&Ȓ
��8\��7���(���V%P�+n�V�vR<֦e�|颉��e����w�8�i���ʑ�l4P�ङ;`�*Jf����3U�=N�@��#�H�O��a�J��M�k@�y@�(�q���Ƚ���F��D��;?�Sm*�w�FR�� 5rF�D�_N-,j)N�e�����A�:eLJ_�$$q�#�2��k�i�#܊�TZ�A9�����m$�']����JcK��+VT�+\�ە�T�h*�-X˿K%�9]�R�@jk	����!s�2���D�z�6����H�k8�F���OUbL�D?�.��y��}���!pH�N�L���A,y|��pȐ��$ZC�c�4��d5��I�s��l-$�It�z�r��H��'x7<s%[�H7��p�v��Y�2��/�`Қ
��K�OG��~^��(�N�=���Q��Ju9�����?$�l���Y�n6-����62��YhZX��;rJ��\S�6-��Dy�u�j^�~)
m�n8�~3rqotB0Ŵ�g.��]y�R�n�xk�*>bu�p����">[��5���(֕薢�T8Z�k���񊧳�ă��� d\X�L)�'�tF$G�>E)��#r��}QB�F������p܂�]��p
=�Sȅ�ҙ��P_��C�B;w<��X������;��K�=�T�_E�7#�3|�L���/����7��[���{���<�'��^t9%_�)w���
��Ç�������΢:�t��E�_�k�z�I��GUhoX�ZC/�#�`�D��%�Y]x�M>\��X�%�1����Ã�N�h�GҔ�K�=>�CD����;��4��0E�Ai��mW�q�j5�W �UD��'�o���0bժ��b�����P��ԅ1�N���������?��!ԃ.aw��A[�M�*��	���qN��%�|Q})�Hj��/��z����k�<��y�������������Osc������ ��� P�T_0�Sj7a���2��Pa�������gw���֫v�wp�{���J���Y/?��c�+�~Ȑ�f3'��w>�o��dH]>/�G�ʏ�Pd�PqZV	�MV�{&��a7Q�N�8��; sDဣX���C[���s0N§tw�ׁ���ep��8\��[Z���im��u�P�[��b�s]规R'͈\�*���#��i>�,p�ݠ�V{!�,5Sd��*d�n�OΪ��@�3?�K���>�:L��j�M�Dz}��>
	1�ڙ��"Q��l�]z�GWa��4��pe�1n����d%��;����&T��n� ��/2MuR�|a*fH-SV�r#�(H+�A#u��ӑ������"r�o�Zj�%�~�������;?u��%���B����s�^i���ۦr���}�ڡbq���In gۜ:�kņ���.�`��9���*^�sNC���B��!�Ʋ3��lp�D�gz~�	璎S&�eT��E(9��t.rZ�BAt�Pm(?5#rAE�����tRu6�%!rC���M���ZO�����B��\9����8�.^�0�]*�\�Pv���do��i��aX��Z�(n��㾚���uE��̞��.�.��YY�y���t�OǴx<	��܌p�o25]9N�0����79r`��̓b�:[M�x"��D���~�i\������D
+]�����4�I������I۫T���k�Cf/��+$a�o�h;�S!{ d�.��Aܻw��*H�#<�y
J��(3����j�?`�K��5#�;jX���+>�n���~��?)�����]x烸��f�"Wϡ�����"���ۥ�~�h�+��hog���9��"V;e��8�E=��z*�U�TE*��VUb;�۠^�_��ڽ7��c� ��c!h��7OU����ɋ�۟���	�a���ER*��`�{\�D�J��2:(���z�Rs&V����C��[wR$[s�{AD����V���MTj5�����[*.w">�AI��o0�H��J�b1KT�s;7�˜��(+Lқ��lR��_�Z.��#��$����Ck����&�ƣ����?�>�� �.O�)�e�>[S�?j&j^���A MP���
Xp7�3_��=#�=/�,�wPH��G������㤁��"t �H����u���(S<�)���iZ"��H1M�Z�l�ʣ�w�N�]Y�(�H��Q$�cB�/�RLGxh��Y	W�T7`@bo��9k���SrUШ5�̘�[U�Ne�A���i�o13�j^���8j���e;��㓮�f*��q�$Gt�ܮy\�}>CH0vm�{�"I .QG�������S-���4��`�3��uz����B^��l�N�8o1륙N�1��<k��5�W�{�N�z�B���W&s�n�ɝ�7y��'��Q�Ήܫ���,oy�
���~�N�>����Iv��g�K<��DP`KG}T���h�spd`j���R@��1�k�����R�ȍƊ�L� �N�WI����A/iݷ9���FW� x���gȂ����-��\�|���7թ_����?��m>L��l<\��,�n~���y�?�ui�ؽ�N��,H[\��M?N�1I�c���G����1�`�[g*���C�����������ewg�q,�n���'"�T��飇<B3|i^Y�*im��R��vK���^.��5�Ye짜�d��t7�rl���fn�i�[�OܝC5$�����E8�����Aw3�V}��L��R��x2�����2��ǘ{U�%~F�R˩̛�r(?g�t%���6k��0�I>�`�)���p�R�LG���dmߔ&�-B�ܩ]HV�_�I͖R;w��M2(n=]yV!u�#�������'dL�_�ׯ�&m�Eh{�F��p읇?�|8�M�n"&S �R�4��'�ѡ4�?G�Po����Ɠ*�����~U�2�́t,9���t�� ��{u�g@�t�F4ت[�VV�%�zJ�W��ڥ�>�+�����2Ю�v��rG;]>_�'Z�?��j��Fm���"�H 5������^U���l��x����*ii:T^����6�I�<DN����A����-۬�Ϥ@Er+��q����D�I׆�U�����!3�T:e�5���c��a�OHqL3�,��{�8��/��c�}eS��� Ρ��wZ�)���;����H��	��u g�I��Tu��ݴ��wIY���?��(����FFkR�����sCx"T>t����7�ĩӶf�ZO�K_�x��T���l4�G�wu�?�K��D�M��7L|M}�Ż��Z�G��]ט��B�T��kd~0����,%�-�#�r(���u�%�/}���v���C��R�չҥU��:t�XۢV�S�
�$�䧣�$�I)�.�Z�CN.�+�V��2��K�-6tr+I2]�,@j�����MeL֦�$]���e�҆C���(�m��cG������0|�*�5�5���󳦎��㉓$C��TR9�J)��-6�<75�ӌ��e����뙕(p�W�փ�Cu:��A�D�'��<�&L�w������0 �8��ZʰO&z�3g�S���8
/��j6��l�-�:릌�Ej���^� W
��X\0
΁��CyS��c_����6,/0�{ܾ2&��ڀ�m��ݐ��}���$!�%���t��uL���
3'�k��ӑ]s2�2(ma������Jq���a�%Wcoi�`CXGc�W�cWXi	��$��K(�`K�d[R��%pF�n�=���I��vl� |�1�^^�Ve��`�Y��Z�=rĠ��0���K�;z����^g�J
�-VLѦ$�,B.B��|:���ax9���z�Ë��ܗ�r2����b������7��G����x��=���l�n}�\M1Ņ,���q��������.�&�������6c�O0��av����_����{��&p@x�)C�����kw��1�̚:\��'���U���|cO�ȑ��ձ(����@��9�+W`9�� �Y!����v���V�]�Q �HǓ��^��T~�BlA9_H~���D�H(����CЂtvw�D��
���i|O7M?�.ѝEǙ�~	j���|F���@��=���N���s��x�ͭ�h� +׏ryy/Z�LM���$�Wj�b��ŉ�L壹K�XgrB�"e���vvz���ϟB�IKp�p�x�D�̉b��IAs�\zv%j�̨}�����2�5f�o�'m��Ob��Q��e0��qh{�=�#�(FLSv�]K�qx��9�g:�?0�}
�m)��������0Le���lĶ�XM�~�f�����`��M�1���2�?~�XT;W3/��Q&wf�ˤ��+���k�MZ%5Z_��fC�*j4!��M�,�}�\���(��\�!��ώ��>�H	F}Rx�:�L~�W���l�Rj�'�0}��@�lw�\h_;��U�F2�	H���?�yc&6j�먪�9P�E���%H��j��X�=�«�ċj&����R�n��I�h j|��0'�gb:��6��|eJ��(�7a�a��cR_�\����~�l1A�/��-����Ϗ�i�Y�W<
�`�]�1��J�� Le��5/-"�Z�f���!���⡼zS���#��@��$��BK��.M�>��y�
&�M�
_�L�h:����pz�	�5[�%o�o�����`,�޶�MO�T��
��^&��p�f�j�A�*��Եj2U-G�젛����ƛu�&S$� 5�6���@�L�pJ��q��(�k��嗐l`��<�o5��,��Kc���������G��,7��)�����Z<J�Iگ��ݨ��֬=t�Y{JP�>b��3���M�{�<n6�d��m۝�!{s0$����5�r��V�d�6n>�f��Y���j35vSӤg��)�	Z��J���C61Y�n�Z."?7O�������H����粄��������{}�[�fE���..���*S�1��?�!q������#�V:%n��W�)�Z8R��)�)]��������ʧ��%���%}ͻ͔�i��:� ��} g��A葇ة+�UP\��F��gBm!���$�q6@�� ���0�0l��n�e���oQ��a��ܬ}�{�{쫅(��p�O�T��͖�w��4��ΉS�풟-�����Y�1��|�Tg)��{5#DQ.%P��bfU��➙8}��`�̕�j_���N�sx>s׬�6�l�̿�q��`q���r�6���촙u�5��G�4�b��R�T�����Mx�$�N�jW�7�J�ʌ�4��|���B䑇Mx���:�p������N���r��Ɏ~7M����1M�m*Ʃ�^%��-�[���/}��ۗ|T�N�ɽ�6om]G߫s�Ee���'I�?Z��ho���袯�^�>v��:�%���b��p�W�T��d�Z��Ì\s>�0`wq�d��O�J��ZJ\H`�zU҅�IH�Nc�v��V�{�Ƈ��"|�|�Na��+�9� �#,P�p�j�#����6�B
T�������w��Q�����LK�$+JJ�|�ߋ���:Ȥ����s�E��.#��<�Q���\���أ��>	��h���9�:5L�Q�e5�R��=8���k�l�B>�)+��J�	�e^4�Ep�^2/�F��8ǈ�&���E�
+�q�A� ��}���6WS-mB\Z̄8��֘�laA�]Ǡ�t]�^�B��9ǎdj#IG���!@&��Ϟ�P��r:t�p�z]��F�3~Х�ݽb�c�aG)��;:�z�%��/aV�pZ������U&��T1N�!�2ą�JӞE����A�['�1�ߘ�!ɛ~L|J��Ljk�a=��_�'�g�Л�:�^��}`Qn�ÔQֽ�3,s<y�����v����t��m��{�)W����ehN��iUܘ��e3Ֆ6fS�*u�h�9��Sb�Q�lEky���+�X9��H�%�:����B�7eL}��5Q�NHpʣV�)�~V�uge�}�)��#�B9���̸��Mh��I�0?��e�[B����QE�jN�v��i�;���^��ؿ/��j`z�R�| w�_�N��s�o�<��1��B8��xO���Kk��$<��W��Lsl?���S"S��2�eP��О�8<�7�5sgn咄���7�(�dx�=�T���S8������q(;X�ܣ͵��A�K�T�Τ�����BL�J|������ld�����Z���K~�
���	�.ܤ�.�fgq��\�,�t�:3��\čuV�Y��0��������%b��(�����'X�c����p�,�G�����4	����#��E'{{d� X�C��-�]+�h� ��c�TV���`E�͚� %m�}��{�@g���B�^8@�=��^,`3棱�@3� �3�uPװ��c��)�S��,�rx�'cBs�Gȟ�A_[Ò��(I���k-�������3����Ґ�Nz���mYCH�S i��� �:.O�'��s(Ë�(F<z'��TN	���PwM�CQE�t�m����=��GRK9cwJ�MN�V���e��Y�_��?
���ly�篏�g�l�c����Fs3����������=����O::ѭb?1���}��2F��?�d'�ѱ���v;fe�����hWԋ�A���?�W��n#y�=yr�w�]|��K�oYZ�\]0�jr���2)٦�����}]�f�*e3᱓z�ᘥ".=��~�Hc98�/=���1m��@�Al̀y�"��ɽT@ y�;���Ў�ZQS��N��WP?�C�3��5GoRub����(wZ{��0v/�گ��<�%�p9YSV1��ȸ�+�N5�?���[�ݽNw�E4�z�΋�����N��H���
�.-��K�p�w�d���t���lb�Ԫ�*ree{�X�Q������Z�z������ ���g�:k�����~��z�{�9�a{���^��Q��n¨SRq���!��T�Os �@F6���D��=�?�5�D�ZwP(#@�����p��c�1V�*Zﶻ��9�����ѱQ�~⒝�ȟ�Χ^mz1��΢$����h>qr�U�➚h	�5��������֨~��.[Z7ߠ����̲_���:<�5j�Y��l}�,����L�93�f�V��(_`M�4���	)/�ɻ����ñ�W�ψ~��.6{|��)�J�,ۭ�0������k�ӑ�fC�g"��0U��<���B�e�9�|�=j�X%�܅S<�[9`Z/�u����B��޹����v3��R}9h�>������\�G�Ea(���d�c��Y$�$G��fm'�L��|��=��IN��3.�����[|0M��mwvZ�/���Yc:���,i��Q�	u���l�T7)I��2N�����w V}"W���]C��ޔ�}�%j���̢��F�����^�z�T��Ļ��,���u�x�9D�1ͬ}��S`��f*�/��I�P�i���5�E����d�D��'5�(	��֋��E-�v��V�@=���
�#[T����st"-��Ѷ尫I;@ڨ�����{��q 5�0����c�J>:�_����r�
ʌ�a���-�6��X�}�ɉ�GT�r��*p�m�?���2@�|ox�%��@ƿ�0��G���E���� ���:�*�Q��<�B(�
�M۩Џ_���g��ܪ�_���.��%d;��]���|������	<��i�j� ����!��:ΛN��G]|b��e.�=��;>n��@ª|"�W?����5N�=N�anp��Ѩ��+�T�.'�C�_ =���g���DaS��5r6��'�D}�&�7��Ϋ�&�.��F򍞻NU���є�e7#��ɳ��X�<� "~%���/����ȋ�OK�^�������D�^s� �����u� 9���O�<����u�>�V�7�/8�pT�λ��*�}��c�}��>�f/��,��)">�2��FG�n�A1��A�9:�6�M��O��]��:�S8#�N�ϒ��[�F�{w��?�ǩW\A��$���ۧ��$��M���Q�I��F�}��9)��J�]�V���
+�Tљ���?^�H��/��_�񬨾�P�}O�U���]%8T����S�ӻ��G1V%�ܵ����Y�	��������`�����&�<&b<eIw��*Ԥ�a�fu:��1=���o=��9������J˼��Sk�y�<�h�춈��3֝0�w���������Fj���~}r��I����>��LK���_5��k�G���5K�c#����:�`F�J��/�/��No+������9��ަ���D ��Xh�x:aG�}lΔ�[����/�{�
�y���6��"D-6Vj.w��U=#q���l�TX׻6�����Rz�z�N>���J��C�T�[��p���>�|ܝ�?Qjᙻ@#-��I��5|�64���"JjY���G���hL��V��̤�x��O+����/�J��z3�����j��,�F��P�>�����La��m~W����;�o����0=R	�]����k�=Ya�����ˬ3�d��m���{�W��1��\F�}����������ZZy<~�����>)��F����å��]�?�S�a�+��������ǩ�o6-������?������)`�6���@�њ^���͓�׺vRd�K��"U����s��k���۳�sG�b��ȥȏ}6��$LVuu*�<�J�{���{���ǐX��g�$
G��Y3�.�����t�W3k�u>��ԧN�9�kyB6_����9�7��Ж_]��J�n����#�#&?�ĳ��!�A���p�::~���$Ѹ:}�{ ����ci�&�'����Q��	퀔��C�>�X`��X"u)*�I�x��7��h���|�]Pj�,�^),КY��c��r��R��+�
KʛÜ�/-��lRMFSF)�LM� 04eb�`�s`��G6���Y��?��V�յ��&F��^%y�:#�M��TS��'�Xjxf2�]Ou]�.TQ$���ɫ��|��ļ�UeƄ�2I�18r��Z�a�ix�&�*;X*���p:�`X?�~�`�u�FE��GB�/�%Yؓٹ�/�-���XN�=��5�����QB������FP>�%�W?� ��P=�j�H����Fd�'��v�R٢\�=�,�Z��zg�[��7-�w<��J����X�h���-�w2��.
:x6~e�jj���'�'�5��� ��&�%!g�:�N������c�A�3f�E��5g ���V�/X�9���D?�8��1�p2��l��4RD�4�,Bn�Y���[uZ=�2���c�y"�Z���zN�|���q&r����>�`������uR�җ\�f>PbI}'EJ!J:y�H���Kg�JsNF^I\AU��F2k�0m�i����y�r�88̺]��kD0�`/�\�_5I����5����s��驒�kJ�Y���yZ�Ӣ84B>�6|a��Z5po����k]	�V[rSڭU�2vec��b1��,ϑ�y��<����>=腽��'C/�a������[��!Lt���\\F�����o�?N���K��N��������c�G>r�X�ҋ���E��P)N��iF3�mk���{.B�%�����Ҟ>�C1PX8�뱿����l<'�Y���{�X�m]�t�X�D1�%&���"�"�-���brtԯ'�U�j�Q�l���ʌ�vk����}���Hk9�ս�I���*@�5�B�Yz";�.� (1�0����ɧ:���G���N��O��.�|��b�?��F1�����e��'�eZ��V� +�3�
#�@��`�e��U������BCt'T�e���*��_�i{���B�E��G�$�$��^w���;�� ��]��5�1�;:m�D� ��"x4�� x���&+��ҋ�"��c9p�zK��k|l�?AnT/��76��F��AG9��A��\�O�s�%N��\5�j^j��dB��
j�'�� (0Q�L�g�T�
Z��[(�kb)�g��
�s��K[���76�f�?�%����֖��y �9|A�!{��a4�J�3��;�?�ߛL�y�=�^
2z�9��싪8<��g~����d�B����7]�b��l:Pj3���QxT�޿�S��>7OZ=8WMǵ�ݳ:�19]��e�<�t�wD<��F�!�`��c�3N�x�'n�(G�DH�#�C�ɩf���&t����J�6�3ԢQ�����2���T�F� `�VJWך^�@����FtF(��n�B)s�UѢ��@Q1D�I^"�K�Q;َ�L�#��$���,H� ��uk����y�85Sj1��-��Dj�x��A9�X6�
�BC�r�I߷��#�b�D��P�J��VBA���m#z��bV�kf�xD��I��^�g���@�XU����\=���Y>�-'�9񚖀M:���=q����~�^�H����_N�v&�#�>b��O	�6���q�����v$5��<����7�a��k�X7f��S�C�PCh�:�'�l
`u��xT[�c/�7�'iⶦ<+>(|��c���W�Q��4C���|;b:#��l��v)����]�-z������������w'�����M��[���%��$)����R���{7 p	��ɫ���y��L�]�;��UG��ng��mN'�9��;��=��$u!.Y�w|�k��w�<�A_���w�.�+]�J��9�{���;s�;	 �ћ�z%��9����'@���������������I\�2�4܉	�T��Р����w>���x l�9��1���^$��f@��/�I���LH��X!�h��tX�ơ'pfڋ���"8�?9�_F�t�b�P6'�J�Ј��ef����e���wS�p$<�`��^��.�,x��ە���k�Umq+*��ߢ��j�3Zs�O��^���?�2��G	����a�#`c|���5Ki����D�+�_�r�9�5 �9��Ɲ]��]T?��6����4��kU^��9����0���(��Y���zQ�k��ma�G���	����s��)t%v��G���+����5���Y�]ܾ}m�bq�4y9� -b��$\$F��V$�ߨ�b:"?iL��?��z*g)AD�,X��,g���2I5֠&w[±�a�����ZJ(�Ԭ��y''���)%+QNXWNh���:W-f;�Mo�~&i>�]-d�d�@� 5�CCQ1V,�����!��x ��q���hf�7!�R������eq��^W 0�����Z�{ȱ�N;�w��⒐3���w-����鄍��Gt�@��o4���aا8/|����|1�I-�����iHE[�MGN��"wxQ�r�?����o
��#@Q�.����l2*����vG��Pw�*[-�ws�p��)ՠ�W�Sϑ�*�4�����7���G&�]�Z��Ӫ�l�h��UuҸ"�ؗ\�.��
�M�t�_�|�|�?��o��L��n��h������fm{�:��e���N�5�S:��\�[u��`�lѥU���˅��,?����,?����,?����,?����,?����,?���s�����h h 