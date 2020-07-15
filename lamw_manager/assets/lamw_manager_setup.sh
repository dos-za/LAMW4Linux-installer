#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1605897572"
MD5="30af5278ad5bfa34fe51c09baed92ced"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21368"
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
	echo Date of packaging: Tue Jul 14 23:23:09 -03 2020
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
�7zXZ  �ִF !   �X���S8] �}��JF���.���_j��7�j��w����fs�dM��х�=��.��؛w��]�~p}�r~�wi��+!K�1�,����n�
��!(u7��E��F��>0��9o�
��*ʖ����� �ﯻ�u����
}���'L���)���D�ӏ{\���|�`����Y�hi�0�7ʴ�A���-A�(�fc1o"ͦ�1:�n��;j�7�8_r���Ŗ��d���d?�k$8� <s�����:/^*�k���D�]���Z�|CJk��Fw�6}�YV���3��l.��v�$��v�F<k�l7��$��GX�Ni�^��n?�����}u��VN��e�%���� ��E�|fZp�?��yՆ6m�Ҷ����M��.
_�6������W�JhJ��U��0�<h
��֒���x|��C���z��n��`�='}R|�?@۵�FgU�܃|rf�UB�J�5��i�@�t���d������O�Ł���o���� f�ԃ��F�ȢMq������rj�y�<�� F�_�
�$~�]����~���VH� ����κ+��z��n�&E�+w���2�rؖ;������yM;R�HA�r�4$H����e�B�������Č��p���U�@6���Cx4�v��~�W���������iP�9�� ��ك�fl!��
��tdr>0��¥@����l������:NP���ǻ�.�ic_�C� ~��jC6x�|M�ôj,�B>t��#0��z�|n��7�ʋΒ5��`����ĀMG���o��\�9�00)�O��C�e����gB�a��,�;ǒ������ב���T@�qg����[M��fA���4�ʵv<w�IѽvL�\�R�*ͨ6j
�
�F@>�XބF�<���+�?H�Y���ט�	��z�؅���꧇ǡkI��R��-���#|�%�vrt̖t������ś���y�6���5����n�S�����iJ�X���$:��s~�#�9���w��P���K0�oQ��fB�t�dEb)s�R�t�0��Pf�e���(�?��H�aq���UZ��Al��@��9{osF�"_*��=�H�8����WC@�>�����\�Q���~�w�������-�����Ǎ�;ں6u� �ˬ6;��D�D&�/)a��Xc�(��y����|���%ôsv�2k"n���5%����4�@�A�E1����*8BBf�"/(	���^����R����P�e0��TS�.DaX��5]���ʶj���������	[�����c�P�s��I5�v &e��d-_��ruk�"E~4�w�Xn���+]��C�8C���Q�D���T�KY�xz�tY�_9Z,=��,mx.]�%�|1��;H�euF���9N�Q�S?��c�	9���E�mz��"g���jq:?��&$n��\X�X�X9��uO�l�ٖ���j�0�}�8Ǣ�-v�)�:�?�?X�����`*:~X43��2T���kI�[���O�Aý��s"�ͣxD�HqO��bSӭ�a�ue ��>Np�s��`�n�gy�� &�.��H�u��0�x󾆫�
�,Gr$�e:|�1�e&qXX��%��&i����g:X�i��,|��=^r/�:\A�<ۋ2������]�&�/?a��bU��d�`���"V��tjg���J��-:�]�m��w*��ΐ6�f�lu%7,�;��hk7��x�g|Üxyo&�$�0'W�<h؉�z�����&$����%��\��f�w�/�L;�*Ɋ�O�/&�"��~�����/Bd��<pTJ]b���@�j�{xrR�R���N�4�>lw��<�ʠ��I�!=h�$������O$kf�̌3�����#6
�0�5�����6�,��V��o 	�9rr6�$�nK��
7�"P �)��?ƿ��`a���Rg�M�ڲqQQ]���Q��i8��w	�9��Ym�d䩩�����׋K�mٽG��4�܁��ǌ��J�s�Mx��-��"����@j�c�\퇼#��̲��2뮑?Y^��D4�)̾~Bꜣ�(�@������t��J����
�0+�-\�c�.;H��K"��� �i��3���*`��������T�Cث:{CE��~7L�3$z��� ��z���Z?p�5��
ÿ�!D�n��,󂃨�g�n��2h�*��s��@o�����\�O���V�����D�����-m������f׎@Z���oR�ɯ2E,�
�	޵|�����܉[�`}]M	0㯻C|� $ X4l[�OA�s?�,�AW�h��,|e`�{�����`���H�t�Ĳnqw6�"�>�،b����ӭ��ޑ:���9���!��h�����!�<�ĥ��6´�������̬s���ƛ�U�3x�j?r���$
�^s^�<���|��K󄶜�٤�Y��5G[��ڨ��UV�b��V��P�X�=��+ykI{Dy��@�YH��R�o0<7�P�6w��b�Vqr��b��)�T���7�ߺ���w�l"��Z�"Q�eA�ڨ<��kyDQ!��Y�k�㘲¸$�#u�
�6 ����p�9ki-�Z1vepϦ�nII�z�<)T����������j�#��@�3�8C�ҙ����8�%ʁM�,����A$_<���f��k�s]����b�9c���àJ�o��N���M�"E/����>�;w�����-
��y�o��m؊�6.�6K������'�'�hWBG��*KsZ�ɓ{�o��j��ĖQ6�[\u�&m�����#N�ߚ�vB���#� �ʈ �P'O�jPSwr���6���9��\5v��83u˩�Z�2�LF���,�NZ��|�����;֠����$� �5E0y|:E�4��rb��ގ�s?m�}�L���ewu6.�����R~} 5:9?�]�v.݃�z{�ŕP��V���˅�<�U+|��� F���Xy%aI�Ŕ�w92,�rȯ����n˚ϻ��v_,��LH]�4�Ah���Y�Չ�_�9Aʌ2\��J0˓9����93<�Ԙ<��i�R���K����� ً��o�7����Ljw5����=O��'�~&nZ�]ů\���Md�P0��J(&}�tw���I�O�ShS�x6�L�m�~Ōc��w#}Z���Ó1�H����Q9`�!C�,T�f���`�@�/�	�4r��)V)z!�m1�X����>}��
����n�� f�����J&������{=��D�!ݰ������W��a�s�J�G8m���!ͥ�)M��T=����_m�.Rd�~�/SjK������ǉ(u[O�Ȱ��qv?�f9�}2Cp�Z��6i���e��/�lJ,�1�m.��<����0�Q��;� �w�P+�I�p�<�������uO��d�:���3v# �7��%�yy��P��Á��O��!hr���I����6����e��>JK}�N�:/0|�\\u�Of٫��!�.F�bG���|��1kPb�+1�����Xb���I
��Y	�O}1�/��I"V��T�ݒCi8ƚrDY�	pr� �h�?|�5g�P�U1/Z�Fpm!P���z'�wW'"/��}e�[)�DG��P)�ch��oi@KIf2[�"Q]�wZ����2��E�I�4�"���H`/�R�Uk*���h�� kFԌ���v~�BG�)L�x¢p�1.��ƞ1kO����t��`�p��&��p����	�"�;���P;u�)sz��Ha��Nf�!f,�r�3�U�̈́P�߇r<����v�����?�1뻹�|,��a���b��YҝfC��	�U�ep<�,�@I�Y>���uǮ�ڴ�荭�:P���T�D�
%#��I�3w�uMv-��Y�Y�[9�h@�#gjj���']���@=���	>L��;��pdߥ�[�oV�vi�n���C�x��α:p+�Ѐ�R֬]P�Z���"��.��K�@����s�h�~�28��5l��F�MufF�D��g��?��3$��KvO�jkg+Hlʽ�O̡�[� S��뗓1��/VBO] T����{t���LI����CW�%�+��|��[`�кF�mH#쨄e^��9�cۿ��B���\��)������|����hk��"�6j,��*R�I���%��Yˉ��k��f��L�xb������E��ۜn���O=�)�����t6&�a�wEX�[�]񤢘�'�fs�d:l��װ�iy�T�-��U�x&�FS���W�@.��G\��U�N�b��8��U�냁s��\Dz�*{uh�|m����<�щQ����٨���9��m��aQC�l�GG)n���=�L&谇�N�AE�� �qZ���&R�W��p��-���i
#���xkv�d/7����3$Y)]������}C���2����5�
��+R#B��f��xʜ�~I��OR8��v��Y�.�����;~�xPC�r��=���eT2�E]��˽��ƋS�;(��X^�G�t�
B�
�Y��> ��B�O��!��?1#���y2>�)iy�sǕ�]&b�Y ՘��{�H�.�@Lܲ!|�C�/�4���(Q1���H#_�i��"��w,P���byo�Ùt-7`;�L��C<�����HZ�!�����G�T[h��Mm������×3���V�	�h=L��,����pg�͏'���O��j	��W�����N_�������U���	���U��qR�����ܧ��ØO��V�hR3��ۓRz�#�`��:���/Z��#4q�4�����	�3�^�P9�p�Xrª�$�Y*4�:����-�\�U�#��`:���/��g��ZҜ�I�����dq:��Tv�W#eC�p�<Z��\��(�z�G�d����}]Czϩ��c����l����]��(l��^������V?��q��l��9��6���T��o��02ꍢ�
�c�]#c�Ք�_�wgU��^�TY�6��UߖT�}�؊�Y��H�
7���rn�tiN����
҆u��ܕ�7��u�g/���!��n�ED_yV���|G�` 8~Sx���:����l�P��V]
_�
D�Ԍ���)�/�����������P��&�o�@J��&�����[j�ù�US�^��BiИ>�$��c#D�g�T����E�?�BSi4���.<�	"�o�4�h_n�ka��t;VѲ'��L�O� �u؈�}�a�>�m�zſe�=i�̣�R)oz���gĲl�`=� �C�!����O�R�����CC
,3�)7_F�����Q��=&l*�5�Ysz7.�� �ʾ������P!8�Rw��'�^H�#!%Pr�*s�	0wRJ��nYK����,���G�6�`��Pd2-ӫ���{�w�[�)���1��8m9�z�*[��(�L�s/ʬ'��zNɜF|e�K�0��tx�d8_�������9��-�u����m�^�Y��ur�جg	��|)�qg}�)2z?`Npj��(Nv˳F���Jt���_Ǧ���%���3@q�RCgl=ٍ���hդ
vB��a*V�2����{UM*K��i7�j�)�JN���3U*�$��Fv&^��]�8e4��a��B��0�ʑQf@n���8���X�����m�m K�*܆NR2��3�[�54t&�pL�3fĹ�#J����h���)e�7L\ި 8ƘF\�~Err	c�+�{���	s[��P�=A:�(�y7�<�OW*q��dR?��lm� �&]�(y�������m�P�}��ٶ��V�0t��|..�"���,��	��N�[A��ms�2do��qh���d��0&o9A��n��� �m�L1���V����U�;f��D�ox��d��K �``�s\���0����'�e�o�AKA��k��Lj/��+�����5G̫��ڠypO*,'�M�.�ǽ��|qXz:������z1���
M�KB�r��fH�cL���U!}4��n�j��;��.�=@/��c���������z�IDI}ì��($���{W
}!!A�t"���y9�6�R���d#i� ��~h����F+�T'~�q�� ��l�y�v�P�ή���$M����p��/�����
":�axF{ ��R*q�(�tw �J�F�֡�P��c �Ɉ!�?3��v�
CVq]���%ɪ�*���W���fJ�ũ�j�x4Pˀ� /�
Z�nm��{h6���M����!E��������4.3bWA~%|4h\�����lC��R�UMGU�`���Lmi�T�q��d����x�]�t͝_��ǐ_�rkF�!�fz]l���ާ@9N�%�ֳ��G&R>㘊3��{5w�d#����O%mW	י��fbG6������[���H;����6k$�8y/������
�m� �Z'U�IL�wT����f�y&�	�S�����
��k��s�,�����Bߒ�#�k�����m�1�H�c��w��a����#h�!a��%�����F���c0�yL��0� �ͬ'_��ïwW�co����$�M�h�3�.A�A9��ewf.I��P��>�����uh %5!)��~8�Q�I�gb�Lr�����]U��j��]�tZ����
U�q��(9,�2�2��p9ɭS"l��&��N�������g�L�/��M(\-����ל����ɘ��58����#W��b;(RЂ	<��7���b E�v��/?���7�N`]z�����T�5���z��8��^���Eue�.�Y��k��R�+�K*���ȶ�8�. �2�Km�eU�R�"+-Ʊ�!]��������Wᓠ�R��g��1T�T�ɿJ�5~\���I����=%�����y�ɖ��>�[N(i'���$Y�X�6��Ѽ�E[�M��<d��؆%�^�~�#]�×�*_���8ъ_�4c����N[&���(�K�$aд+���X0S�������*Q��w�ozX����(Ug��.���0$����}�E�n�^�2��A�*dQ��=0��!���(�~�E9�A��ʙ����x��3t ,�����I�|�C�Z�TuX=V]�Ú��� �!jF�~��>��*ž&����j�M�
O[�D�+:�vZ�҇������(/w-x����[�S�ab�;�x��l��C�M��[��\�ޫ��%�3���i���a�}-Hv�8�
�Q`�gK"�6Ґ���L�4�Gh e�#�ǈ8wi��w�\��H����֨�_I�9
��ma�+g��{R�l��s�n�����.g����n�����ʱa����H˽3m��E>Ү��J#�>d��'��~�j��h��t����)��IfG�.2O��4U5d����Aﷀ��y��Q���p�۩�C�%"5Kb��0��r`�#�Ņ�٪�?����~
ږ���	�R�y�ѓt��I^)d:��4��:p��Ĺ�S�B�C�i%�-ȵtc����rƟ	]lt#�p���8#ص���&����p��}��u��I�Q�X,E�u�8B�������԰&an\����!;�@��r�XH��eA:qһ����)��I�S�_WC����7�H�cM��!pU鬶-�~�`pg��] �4��P�	:DU&ʵ:j"�zU��,~�U��r]? ��J"�r=�ɵ���t�  �t��{#�g{#6ި��m�x���z$RH��2棷ɿ��}^u0�#���+ش��,��<c��+���� �_��ذ�>*�)�''(���A^�.�����Q�NQ���'�g�"F��Q�^s�)�wu����6Ą�Lۓ�|�8+s	�ĳm���z���Y����x&<�V�9��a�N�Z%{���R�D��7��R!��!&��0�ϻ��6��s�ݼz�5��q���ÌM��V�5~�YR���@]��[�H��Fj�|'�ĦX�/��l�y�@py��SӞ�D��z��%?I0���,���7ɟDqr"x���T��~2�4g��ըY��_�9��gPi���f�ZH��ܖz6�f+.�|m������8`x��?<1��ݑܤ�_4�}�X��욅����n�!�g�6G�N�Y�}>�E��� ~I�G�����;�͛���t�9L��=$kݯMK��-ލg�Okw -�DF���0�me�� l��3����	�����n(�o�mI?V��P�]��l��(K����z��e�v�hc��,P��Rp��t��������V s��Tz1;�G�+�Z;M3/�2����B���l
�O҅t���3�:4�riҹ�'��`BG��/�ƦFe���Ǘ!Ka3�Ϸ=��#L�&���@�x]���Y�����h2E��P]���u���O�2_80�\� �r�h��Y48@��AjlxHזR�>�r"y:�Su�ClG�*���<�%��a�:�4Yv@U�����g��ՌZ֙w�_�$����GZ_$[v�r\�O�U�G��MQPɤ,���G�-�6f��D}�ڑ�b;Ա���]��ʒ�����^��}�4~�Q#�	 ��S���h���}���ޑ��FO�s�ߏ���LL1z�f�K��Ev�)��t1ܩ���l�
B�g�|��(����N��4�'S�7zijNjȼĘ́\�p�����ws
����	È!�R�ki�s� t���p(���A�E�_���=^�g��o��;x�~�3�՞ѽsC���\�b�p�"%r����>������"2T+Cv�\{h�j��Ο{���[��l?�{�}�3�f�����9uq*J��[�k?N*rN�.v0}	 ���ٖ��{����G���`���y�ƍ9���M@�"�3��;	���� f	8����GlU,��y6n��?5!&��u��j���檫_�k��S�s.͓�@�X���~�ө�#@��P���K���GFݏh�fE���F��;m�_!�&<�e���˓=����uA4t��Q�ޗ%�����۾Gҡj`�A]tv[��y��I4�~<�}��Y�7-C���u�C<; @V�;��[�Kq��ۚ��@�X�ITz�8x7}�d�v��U�}@����i��l�O~Bg�M�ʧ5n�~���}?�Ͻ
�WL�#��?�y�l��߀�l�`ux��7��؛����F��![푇�_mywUJ�����ʽ+��i�����Oκwtd�m��aF�>x��׆�T���XW�M�VZ�)���Ϣ蚩�qd�����2��9�����������p[o�Zhq���˪8J;��:�v�O��z՝Y���q����8��� hm��~�p[
�����%�ԄEZ���(�mu�ø��/7�20 ]�F���w�jY��6;���,�שd�s67*�-l"9h%(�*7�YObt��c�=mW�<������0�~g9�6/�2�Bs�·�u���z�G���-��DἂYG-o������4c�<x�=i� �s��TWۇ��s�h1"��@*���1��`#���Ů�,5nZx��h0ss&76G3�3b
�a�V-᫡ޓ�2����*a�|M}Ӑ�F��@d=�:KЙj�9�-�W�6 �����k�8LB��^���|�J3���%$�\���� T�6��,�.�q�6+���ࣻ;�����E
}vו�1y7R;m8{�Z-�C��T�osS'^�-�-��4�$�Pޞ���K)��.BBz�
��A��+vE)�_��l����1�Z
��hF_�K���lE�}�Q�ۅ}������5�;i�"i[�h.�?�����$��ت����l����.�p�?p�U���k���@҄�4%�[�{㓳���g�3����˃�����di��H��������ZT�/6!�6}/��G�)d3}��c����O�~��N�ʫ^�׎+X��,�E��A܎�����l��;/�M�����h%q�4���S/5�.�7���oa~Ҩ��j�]gA���S(��,\����2:Aj�#g�\�d��d�Zܕ(j���u��f$��l��aR�n�}����Ա&)�"��x͍���h�����݄��K+12:��
@��+H4o
�:>.��Wh��n�]�F@��&ݏ�z㯹���^4J��E������H����I�b�9ᗄYP�;u	�kTEq�*'��g����؇*�6GL'�}���ø���>�;l�AF-�N�S㟜��1g�Y�\��*_�С�T+��`���'�Y�]��D�ӑ�V< �,�+�m[N�_��R)��1,$I'!�iSo�L0K�Ş�m5xp�R��q�>�Z��1ѩR�Q3��T�%Y�W�P�����K0OU*��)�>�m���VϛFl�ȽQ�S���Tw.�U١�a�N��:��O���ۙ�`���у���sm�Ҩ��#�>�
SW�Yĺ��t�X(��A�H�.�������4'd�=�kL��/\xG���sq���qͨ����]f����tk�<�V�A���n �*�����UEB^K8d��
Ņu^��G�F���W�JL�-ײ�[8`ì� n��G�dl*)>����&�'t�����������Qݮ[��JG�c�Z���dy�#�qnDK�����
`k�y��=b�`��cQ�z������r��>P��'K&ީgҬ�~����Se�^�����/�3,T���?�P��J�� �bk�����.�qձ��!�����f��(�7�a/H�����͎ZegJi~<��Mk��O	�)&a���?���Z�]Au7����ΐ�TG�WVC���@��D����eo˒6X��l�:��-#)�<k�#ƖE꺽���R���NtgH���/���F�V�Nd��ָ�e��m �,�Y�ڸ����hQ����'uɑ���E�� y��e��I���͟PƖJKYg
� T���� ��x5��^ӊ#V8�L8~	2}�:Z�Ő���� �����1-x1Aj1��S>d�%��㲆9;����7�;��w%>"�<���X��x��t�Q�/�y�jT��y� �����h��K/�6��>W���Ȏ�U9��f+7.JCjo���e�n��[R��/�r��E�]j���雓I�-4ja)X�)�fR<dZ���z���PDp�ܛ�����G 37������a�_�V�,��Մ��o�Ҍ��'��@���������Ÿ�Jiѳ�Y V
wܢ	A~%�`!���dr�c@���D0���` ���͹)����|��X���4�v';�R�p|Be^�mTfN�6����d{�@��Q#wS@�����g�;NiWφ�xemh-�qv��b��+些���M,[�����]F��>��j���$���wݪ�Yi��pb��#�'��������ӆ&a/����#^-.�j��Ey�C��Xq�zQ`5��{��ʱ���F�r-]��+�f�̓�7��Idϗ�n?�퉻�����{���Ą�9����l�����o���^d��8�̍��3V�H��-���s��UΫ2;�`"����<���=
���?l)� T�yz�l�����D�B�� 3�pk�I>T�i�
 i�=U�ܩ�Đhd{<)����u9Ƽ�S�}� ����O�<�U�Τ�LX`DKG X�=(�w~Q�c��e3�D�GĴ\�1p��A��
��-Ilԇ'���v'$� ��d ��7�	��;�)T1_\����QU�ג%[���Q]�9���� G)�5/�Y�B]z��/5LEo�f�n~������9ґ�e�y3�D7g
=P�"L�����܉<gIr�_V����SӍ/&iǽ�����{�!]xg�T |��Kc��������Xm�����!"��Z�����XiHs7@�i=���i�e\XA��p5MyQYTT�����D;s�Si�(���К8��D�AҲ�r}@�	� wqM���;��x��~OW_ÚQ�v�v���R���G�`h��w_5�5��5��!Ǜ����D���3gtK�\0�m}�ʟ no�v��mϵk�u�6��-IVW4����l�������9P���\�Ŝ[V��'�(��v�.��S�%��#�K���0���aE��0s��L4�b8/�y�C�ѕ���)ǈ��?�&(c��f<�L��4���|]��;�i�E���|�`�d�VeT��PԙF�Z�2�G</\��>/F�c�Ê���fI��f��*ٟP�]�ׂ��lG/�!8r	�E������g�LF�y�}�O�zB�BM��q�b+���� �������_c� Hf���S�RhI�ݠ���-�i�bf* ��X� �.G��c�GW[6T8RH/���j��{|���Ȗ�Mm60`�i�5����㟊��D��4җ%��5�>�[k���"ň������b���]8b3 ӛ����j���6xߋ�ʬ�� ����9p� C�
�mq,��G���0���6��J˯9��ۓ��.g��C���}^��2�-�	^�=J�e=Qs���V7���%\�"�Aڵ�Cm`�M��Ăi�e����]!W��Ŏ��ܮ�n�3�� a���@.�j�_?���Q��ow �-�P���5/(���9�����e�_�W���b.!�K��y ��9�a��O�*�[
��$՗�c�1��`uS[�J�ض�	�L� �F.������pD�vɶ��#�D��e�n᳏�0}U�����@|Tym���/ ��Q��{f��G׫Ǵ�1��n/�	��$ƀig��J�턫l�ܰ��,*�ÇR�.D�T�u�e���+���b�W�%6�OxA�J�oDt��G��b3��
�k�1�#�~�rB���_
ٟ�Zo[�B ��>uy~ _�4X�l �4+1�Uq>�.�K~6�7F3�!o�#� 3%�%��o���K�c˾���ov���m�~/5"!�<Er�q�@Cyp�P�����������Y��������*_c�{�	�g*Z������������X:A�E�0�����gi�ذ����I0��ID��c(B�aZ� 0�m�l��S�,6P@�O���=�i<*�k�=���Q�n��o�+[&����S�2"7�4��W��u�c�����6�}�/u�������Ֆ=��w6`o��\mO�EGv�A��K�iK��h=��0!�����u�$|��F#�[>�8�y�[߾Z���2f��
��4���L6�*1�Ā4�M��)�s������o����m-�=��2��
��`�86y��#^�*��8��
�>yz��E����>��)\x8v!;�#4�~ʴ�R�T �L7�~ �hv 51`Y�����8�&ڐ��|���׆�^�פ筂��`�Q�����3��«>���!�۹�qxXْ|@t�ň�$�H�gT�L�����<�b�P��T>x[��i���H~X��Sn��W�Z��~�p@Ѹ�*{�O7��	�_vs҄4�چ��*F�t}��W�F;���H��g�SICK�0K]�d������E���/��w��zZp���$��C�T�O^�� 0,�_LfD �!�S�P�E�SU���z����
��xx��������g�L�EX#!)����XU .r'A�_�<Z���q���b)��H��#��,cKTd�ry�a�.�6�Y!��Xw��m� "�9�������\y���PEN�����	���L�$籐���Q�A�P�� ]��� ��kJ��h;N� 0�+��?t��^�Ǹ 9�+���e��	ns�P���j�|%��t��
74�C���˄�U{!l{�$��t�����6)����S�#>�F���/QDTx3�p����Z����Ǩ�5�q_�a�D�~���N�ni%čH+�1���r�ر��R��A������~�Hz"肋B�:$NX��p׼�x>_&��"��w�ڙ�����Їm˵���
!{�*�J*ޮ�ݤc=YCt���3-�����`Vث�g�"-����χ���S*zv3@q���9wI�9�+�i��Q��.��[q"�Y�_�1/",���.U��`q|:�S�]�)��t�u����ɿ�Y�58��q�w@u�_��j�p�u���c��s�h�="ဍzyj�d���?�=ɢwc���eCY��m04cq@(Jvh�-N��-�\Ò0˼E���}�:{��I�E2
+q2��m��
�{��]���&c����%"�mF
��&fɋ��H�N�M���#ږ0t��'٨�s��s�v�����#q��0�x[#\P��5z�=y�����y�r�m���Y#�J8]�����*dp ��~��9��H.�T�k�i��oN�>A�u���єi�(h�:�6`�F]���Cc�y�wýZV��bRf��K��lOx5R�ҏM<��ںg�Px�$ﳰ� �;A\}��,� (� !H����=�r�Ϟj0H*��=l?��)w�=�M
5���X�	��&~Z�L��d�I[�u�?�&;���H�6�b��Y��gÔ^��K$O�
�$�gA�pwZq`�i_̃��^�3w�N081v�ǘ#�*Zd�?�����r����\=��q$7�̠�:�`�p�,���7뿾�H��4L���,�r�d��Q*����OS����v��Q�9�͔>�5�H��lxet]�f>�[z�<�49�H��9��ls�_�G��4��
����Ꝥj���f��T)�R�#mW�����南^��_�)s�=9�>��;,'D�e_���v�PX�K��-ҿ{eQ]qe
����u��Uƚn�?	v4ó$噶����I��5��Z���+��ue�TA��z$U�q�fo��=�;y<��]������҇�u\������d�`|OF_�4���Z7 �nS��������4)!{k�n�"d��dnO����}&�G9��+�ʃ�5ۍU��z��l��D.�\��5��[x�,v��" >��q�q��zd�?j/�i���d7A�V����ft_3/�4��힦y�gN�C?�s>��R&C�$��-����޹PS�U=�YbB������4�V��}����e(���W���P�=���ȕ6�PT=�6����]�Js�u����BN>�6�u���T�w��H�]MXH��0��|R#S�,}�8T�v�	uPoB��^�C��86o)����5���n�Y=�M���%�먾-<gcP"��i�1K�)�����pQ�*���k%dk� ���m?�:�h�{;�S��[з2C�s�w�o�s��>����a{ 1�ϩ^F��<��i�p+�X��drQ�kj�a��+.�|��R3i��%`E8(O��
)�۝b�s�m�4�^�kU��Uh�M�J���DY��T�R���Ǯc�2��ά��f��T���gR S��� �H�>���T�{�����dADh�dX�)'>�#���X�����[5�V�jI�?e��4c�K�6JF�+c�v��<����n�������Ep$|���ఫ{ݮ��2�ˑ�dc.����Z��O��M���
��#v��Ӭ�J�����{���1�s� Ŭ�E�c,�Q�9J�(�����ٯp�/�2�P���mH3�"ZL^i�H����W���x�VN�!�/xJm*>d�kպ�(�8	'��	J��xzE��C�(d��h�E�E\��לU��$ �"�ʎ2����5��O)] 4�'1ɾ{���{^�1o`D��+�[�qz
�>Y�h��9?-�O�4�*�<XR\|=�����-e>!�**e`J�䊹l8gߌX@+>�x�ԯ,�2���ѴQ`�h"���9�wg%�A��ʑ�i����&�C��29� �x3l��(��f�?'T�JY��G�'��3c��������QE~�,���Fc��ַ�s��2ݚ\>VT��-uQ��$�wW����Kr��[��v�߱L�wa/���.T:�ֆ��_(��{��8�x-1A�X:��F��'y�W�8X�O+�R[���z�s�@髧"(���a�G�����տ8�_[���kBv,�8zj��X&g�K�k�,Ĵ4��0X�'M�� AcO� >1Mj�!��L�H8D@ި��%��h�LQQ�ZD�ڽ�`�0�N���Ƅ�}���x�=����쓶�P���Ym�k)�� �[[yB�{u��qo^-�1,w�"�]�g�K b��@��Pw9�S�7��89I
k����C4�FGШFQ:N��+�+�{�+��W���굤(Ԫ��)zh�O�ᜊ�ޢ����}s>`*���ү�W�R�Ӕas���z��B�eiV���5NS��^=���.=��2��鬒��mW� ����B@�h���U�t�����n6��qkI�S�-)K`6�Le��E �vݘO;)�9!��|Oz�,�2a�ӽ�K^�����vY�`���f��(�4 T�Q�aB���?��|3'��I�%�]�kWw��P���F۸e�9�������uF-E�:�<V��O�b���Vq�2���7ݍς
wO#���J=E����S1_��Ys_�Xju�3a�"��K�D������z�8�N+��s���п��=���tm�h���6��?�X�|�nc�@��|���y��j��@(��pOզ��&�D��')�$��})�O�}�}%�S�z����P��oBJ2���N�xn���$��| ��k�}|���I 9Ϧ0�*�|5	=��҈�7�T('5��T�{���@eJ#9R�خ��f[$��|}�kJ	��ޘ��T��b���(}��yoT�=(W2p��Lkde���A������ Xl�#Pg���P� ���T�c�4X^�р����@��z�e�|��)n&%v�'r�Ȑ������֋��{@a@Ԭ��3�@zX�)\8촪a�L+�x��J<�N�5%�F�� 0М|TPYcm\T)D�1���\�2�K���*i���x�NT�:�y�U=�{��$9p��Sh~\GIj4,�	�`8�{zO����y��7#�����I
�xdC��55ì9��1���2��x���-�r搤�k���M-��6��(,7��B�O�g�<-�+�A�3b�������И�i�J��Y9p�����1��&S|zDr(;����m�<�K6E�9�Ɂ���jɪ�;���e�@"���C���^���q�j����s1١Y`���G������[��8��jr��b��i1��^�m?�K����sn�̶�	�����~��%�Xy��V��U��"�^km<������H�N,gO%��쐨�]`�TC/5;�sH�iq���_���2���jU�0���G�RP���<ID�ɹ/<1`��ӥl!��cb��xo��kbS����ޠ7��������p��{-HW�w;7�	_y�rK�5��Ng���]X�ѫq, �a���^_�k$U&�p�H^j����oL"%A0L��6����� ��(T���x��Y&����5�V��f��L�4K��x^����J䖧��b	�f�yh�B�W�_:ÙoN�"��M�#���A$��6b�(���U�hO����K�ކY��C�hΖgbL��d�C4z�r>�u���Z�2��w'�=�N�^n&�ID@\�7ɔ�z�ZB��eGk^�*���hQv9����Oc}lL�A�

kdR��Y0�sW'A�Z	V�J�PӇ)`%3^���w%��s��7�p��iv�;�,��"7+z���b��i�8��`� ����N�л�������yݜ \ 7�=�n&��L��+�	?T�s��Z@��g�nW��F�f�5��Bt�r"��#�5�k)�y���LAZ�ɊR�u1�sƸ��0�LmV<(]{n������ܛ�G��ULK%�<�	ذ><�.������J��
4ʶ	����'���3����e��U�����~/C�P��MRR\h�y`3#�׍T�ho{*B���"P�>��l�!�����r�ӗ)�[Jo�^,3}��s��7�Ch�؊�X�QI��V�o=�c��Ū�>S���䴬D���i���e,��Do[��]yC'�2,׸�kKW��L˝+s�B�Mv�S�|/���K��4��(���H��K��|���r0G�Śϒ�) �_T���ݲ�
�#�I'W�j�ǈ��J�Hc�V���'"�GU��f�_c��Aڶ�P�J2�ы���u�᫁�2��!��p�h����%g�L&���2�	�=��:N|��)u�b�Rϰ~s��R<�խ^t�1<v,�,C/��j�C�h�:@��|���<�/��I��%��;�|Q��S��d�z���:l�dn�٦��3�۶��r�����V�:D+PK�����Kw�=08����s`�:�7Yf9�	��>D].���A��y7��Jxb�gP��%���wa�Ѵ�|(δ��DZ��~5�N@gvH���-d���wQ��P�r���R����
?��׽���w��C#sr�5M�*r�`�/�����.���5>u�������W�O�]׬- �`ŋ�_햕C����5�8Zߜ㫤�T$M	{�C�7V�`���d�����R����xL0q��(iݬ8����3h!��s�.T-�=ZM�yRI�+R�|��ZMUћb�t�B��7� M�>�l-v!S(��"�n�G���6j�����fjD���A���y��c��S�\=�I椎%�{�=PVo�
5���#𺨖�D�~��H !g����
�$�$�S�P�9��=�.ό�,���A����6�������
�M-C	���<i��q<�_t(j��4�_R���IF<	a��7��tVƗǼ�c�tŗn�3gl_]�W�����A~"1�W3�tg�+8��Af)��1k�����ߏX\���6�2b�����#yZ��h�O�x��Uk��f���$~y���s����y�\	yD�f+mO�N�g�K��吴ݷ�������.}zBrj�������S}|��v��m�3����D��$���.�q�)��e2o-�L�=�����`��B����:��~ ^:�d�(m�Y��\Hښi��m��U>��rA������́��|�H׊�[����ײ�M����EpgF�M��l�U�T���2��z������jID�CN�&�e���+X�*R������\��#{� ~�[��>�W�7=��M����m���\MH��2I2����
q�����~��+?�O�3f�܆�y9�'�|LfC6&�R&]�i���� ʚ�G�����dd
>�Q�_��S�$����Ă��~��0�M8z�E^.at��
�|�%'�/�S����9m�yY����ZMi`x@w=$�PS��:CuSL۷$"�>bB�4t�{�r�x��y`[Ȯ���ބa�<F�H��I��C�c�	�1d���S`�:����	"on�|�Ci&Y��qY�#᪋Mp5zxu�>�/S�T)6�A�(���~�C�i�!#���+6�f{dT��Fs'�D@�s��z����I��è��E��Y`m���8$z����
�U�o�Sύx+�����}+�w4�L��;Ɗ�L"K��0)�#1crqr�Ƅ�V<\�Vʕ����C=y���t�F�e���Dɛ4b�=�(;^���O��R"i-�E��'��6M!f`Ӣ�jIU��Q���L�Bvȁ�I����2:!\��^���>�m���o��3��,����ӊ��ܛh|ĸ.�4�㢡T�-��=�8R�z�鮘�b\D�ӫ
G��1��W��Z)�'�yڕ�[^�yy���}��K*��M�T�m^k���l<4�����(�+D�8'e#���!J5c��������eWz���D����>�/������O��t�I��">�7��@��p �a4i_�F���Ϊ�_oʽp���>����yP;��4(j�a �C� ��-���=��4ٍ�����I�8!�Tde��ރb#$V�K�!�O�%#A�w6d�O�CO`s�_���Ԥ��A6K�v7L��.�;1R�BaC��V�qVEvR��r�����->
���������V7��b� Ⱦ%��OUa���l�xnv��G���i�*�Ou�Q{7<�6T}���pcdO��'2����59�D��J*~r�F�7sO���/���:*� aډ��U11���OI�6��6�������<�F��µ}�M$��"
��p�l3@�Ƹ�r�t%YUė��� ���N����iF0W�5����1���e�'�n� ���ʖ�ٶ5��@�6\�z2���Qe�Cny���<�p�±�`0��v���@��,�9��6_����q��	e	��گ�[6�u6:�ȟ�Y�4��nz���}����$e�@%��u���"չ�R����D�8* ,���~�.�����j�r�6M��*����9.~����i��<SR���o��k:G����o:{
f�<���%w�Okb2-���	۱0�����gQ0O���D�p|1�Z>�$c�| ���V��s|Z=�L;�������9����;�
yt#%��eY��ڋmZ
F]҃��Z��ͥ�f2�.p�Q�G.SB���Yf�4$^Zt�"��_��2�V��Ȕ�(o$l�qx~��T�R#a��Z�f<& wF;�6֌\���na	7���Y�?1�co\Y�� �W�`\No����0^��͑/v%ti�V]�!�\��%-��ʹ3���D}ճ��6�O>��L�<曫K�,Nm�g��Zk�;�A>���������L��!�ڣ A,�V�G6I�f�M8��LzK��  �'	����� Ԧ�������g�    YZ