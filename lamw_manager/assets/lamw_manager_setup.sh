#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="927531632"
MD5="2115ac1421e6b008dabae0d4c4aeb648"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20708"
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
	echo Date of packaging: Fri Jul 17 16:07:54 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j��}fN������t+�8,m֬G1��C_�����d���L��X�d�vB+70�?�H�4�J��"?8&Z�9�^�3�d�"�1��	��4��pG�an`�2 ���UZ1K����v	n�u��U�"�(�{z�z�y�&�s뜺��v�D��>�s��
�u"��o_�>�Da�:��^�]m,-j�l-B�I�������g��ΰ�KNXu��M�����}:�TO;U��'8�K������'[w@����tZ�1����X��w*D�����y�G�`�z1}�e���Yۜ��C��_����[#f7�Pwbզw9ܝj�����e�k8�\�������	^Ȁ��Vv0�[��u��
��0����n�0y)�p����[���&�}���-����g��ʒ�U�cm������V@M�3)ӎ%P��\���8��s����
1R���X���_�f�D���@9���K��Ȫ!ܧ-��-o��C�CtYUC�V�(�>��Q����U��<_�*SF�7���娒�������B�x�G���,[����#LL� ���� ���L�kWd�c�]�b��E*9�G�P�x�9?��۰r;�ǉh�������&����|S�I��|�������x�f��ٴpO��F��;����r�h�SD0gsg�Ke�p��_�LF�E�N�sv ��\3%���α0#-t��澍���ÈJ�"�� �>��1��蒛NEJ�y1��LG��+��:�!.2X�ȵ���32|l6[��7~����)︡ �����ph�sq�{٥Y:_Dn���]���Y����uM����1n/Y�	w��]����<�5�0�FF�տmGcz����(��-�,�F ���|�N<�m��hpJ��#��>�ʎ�D,v"�E��3�?��)��
��NNdd`fޚ���	FnP��R��-10La��ʧ�PZ���e"��_����b�LQ�|�5�9��uޯD�e=�2E4Τ�63@5:��Gʞ�����aU�~2�Nc/k�?vf�ܮ4���X��ql�]�!Py��q�D��R�~B޾/��'0���%�wP���L�D�mc���o���wPQ9~��"K,�A�+
�����Gw!�ݧ�':rd]2;ҟ�2�T�BE5\����5u�`�C��	ԗ}�5�qHK% �_(A��T��K�}��lڈ�� ��]����=r��?�dz��`p�Ebww$�C�A��iO�8G���QZH��'�©��WŅy���>S�M+�A��qX�����d�s�7���c��<�f��va#�ڄ��ԇ1�|���HB4j�$����f��("Q]Y2[��#��ݗu�O��UL�qʾv�d�ú�c�z��qjh� �1�B	��v-���f\��G*��R���f�|���;��,�*:-������q.�C�������������،'���YN]s'�����\��Ő� XQ:v� -�b+n!�z8��V�J%�ɥ�O�hԔ#�#��ln�����<���M1#;g|Jz�����'ɐT��1�����R��Q�y���И�Bf�T��0�F��ຜM��a0 ��s}�pmg��L5���ǵy��1���@�$�נejP\y�����_��O�����준R��8]>#n�U�.�+�G�H
�Y�]��:�����W*?ۄu����� ���&Ds���DT�m�ԀA�6w"ޝ0�JU*��%�������ҝ�����C�B��Z?e{��=p�2VtFC�4Qw�b��W��9���붦5ܝ��@�H����O*�	�ʽ{I��z��Z�������R6WǦ.�M�R}���<$ק~<�J�Le�H��$����a�ԨZ�K��C�	����1Qř6����9$&.B��q��ݽ"�\��ʿzy��ex�zZ�����(�vk�����2��K7�!P�F
(����Whb� �s�*��rYL���jͨ��v'p�9$��DT9�A�f�]S��M	��w-����N���E[�\o��~�����j��7�|��_-�^���lb^�7se��9�\	�˙�~�C[ֳ|��>�'B�{�xڱ|-�|z�#^��ѝ������d����T(~�������(E�d��@�)�|NU���&ՖN�8S2�fx�\���+H�������V��<۴��3uC�+��p�S�: V���E�F���G�Ǯz8�Ӄ4�`R$�.;��c�t�&Ӳ�퐲kwǛ�	��u���o D@�u�t�s�R
�Ke�]X��_��:�J�*�-��i�m�q��+Uĭ���9�
���n��D&����[ꃾ�J�U��~j�8�f���-�i��(�|}�%-*T1��3�Lw.AN��?�};X�k��p_?��Nv�)��Y�H����K�7����o�R���uc���j�YdlV�e�o֬�/�E�{��v����P��!��q3�b���aqu=�F��z���rj����Y�yi����T���P��D�e���1�]�nG=ٸF����8jDi��4#Xw�k�olk�����2����)���-EL�e�raӬ��A��ִ ٛ��?,�0���c:Գ����ꉁ̭��z�/�s��e�A@���e�XI�*�����Z�O�ߊ[���	b�א
wA˲�ܬ|�E;w\$u|yx�N�pcF�{���F����i�nt�{<���)�����_�"���|��]_��ꍆ9��.0 ��5�%)@D�>�2p�^�g2 5ߖ�^��-����&���R:��[C�zM�u�O�2a�W�x�ѐL������#�H�rͣLG��BE��L�����[ ��g�;!cT�Z�gE
���ZD�D��R
��v;t��Y����3aLz��2�J�>�ty�6ɣ�]�������q�����]�(�SKZ���Z�\���
��S������u�/-T�ӥ����i��|�%V�ޯb�
�o��(�r+���*�?�z�V���i��a��� �>�Dि*��A�3�~_e֜�o[�xL"(����vy�Ѐ-{�KBjҤ.��V9�[��=�B���q��4�D-Y�c�4�G��I�_���69=�l���w7�C�x4y�,ջ�[��fS���z�eC��Ʊ]ooH���;�PS��=jW�sT-d��yP[S����"�����l8{.���jG�1^��(�ξ=fK���?��<h,�`*ݰ����yK�tGLP�[֤aT��zs)`WeyQ,�5�R`��߶�_9�BPv���N��|Qԗ�w�sgw�
�&�eB�
��?S]���#�/WJN'P�q5�Vw��r:]$��&"�<]UWC���@E�h���S���qi1'�����	 ���� H ��(�Fi)$w��fF���8���^�I��l�7y�/tn���&XU�Fbބ�N��rW= ���f��΁�1�w�#�����VV�!"[�E�Jo�7��93vUny�9�����"_9l��O��(��
|Ȗ
6�"ixn�����P�g�#A�/Z�������|��c�ᖗe��C-W�2ȿqJ��!g�h�yDG�%��DeK�b+4imo�~/D���Zd~��%\��&n�K����؎��.bf{�Y~�q�i	,���$��l%�m�[�텄�/�iD�Jq����;]��+m��'�m�&�?����0������2����yy����?��gر����R�j��[Ham�@��ɎK�g�7|��|�NC��"8;l�T)��ӂ�^�����_�gRY��_�ރۓ�=;��:n�H&t ��G���� �Ƀ./2	����L�ĕq��6B��o ^��Њ�B����ܪ7���%8�V]!�։B<�#^���T�Z�Y�h�s�PI�8?��;�K����،�������I|��n��rNP�&Gm%����^��"k�F�ݹ��Vu�r�Y�����K��e�ZI|��xgɷtY�^(��F��4i�Xj���5!�ʘ+�(���=Va�?r�K��w�����(i0�}���(`�4@�O]�ó:&u���ڮ
��5���!���6O7���՛���m&��V����3@o�_v3�����k�BYƮ{B0Wޘ'�*�g��e��]����I�3�'���TJNQ��Ca�]l�1��9�Ο[#l��6�>w��'�G�����=ST�X�n]��i���'	���b��Y������=T-����"������E�i�[5���юK�ாx$�ZS�w\�`��#��ۜ�W�.f�w�*F�MeW���	�3�t̝�Ũ��ru�ѧ�����5��T��E�w��؀-��]@��]݅���܈l�m�u�J��\Ba�������o)�x��K.D~Ś��o$�8����'(G�������9Iћ��o���������:�[���.����fep;mB.z���p���Ϗ؛Rw%�����E ko��3(�h��3ve��`C��!U��0m�rf%u
 �H�u�.��۰����c[�ҰO��Vy�j�à-sa�8,��Մϰ���%W�2��!hzfW���ѓ�ß�g��_�	P%�S?D����F>S�/�� Y���xN��?�75��aע�
�JC m��� @�9�a��~���f��p�>K�Ո�_��=ƕ{�H�� G�z�Nj_B�h�,D^W�[��N־���O�S�*�:�a������__f���{��f�����wv��p�}ڠ���v!�� F���T�ō���1�;GL�Ja�Rvx��J;Z����$D���<�.�E�u��[��寽 ��I ��f`J wO"����t�( �;���O_ ��������Q?:G>枯���HM�[$,�[�ϑ�L\ܾ�
 ���MQ��.�a�m�g�!���8g�C���7��ojl�έ������:]�����L�Ub��=͡,*�n�X�vV��U�3���`xP�7�dQ�r>+�w���Y�R���>Q�2�~R��UX�h��߉�C��m#�t��џ���q�S��qJ�s�Q��6�`�=u�S�{�2<p��NЯ���rՄw��oy�������b�?6�V�t0���!H����Ҋ~�_,bN���+A:��At"(`d�?���"̽�=(�7���t��!�.�em�|����(�]_�;0�K�˝F����K{��±V9������
#d"��M����O5d�ѫ��]+����d�;��5��:�[�n}�~���ԜwA��| �(z;E94��Ff���Dʤ��l,yN��2�]��O㿫mӒ���/!$g\.�!�0a��O!�Ѯ86�%! ج*�5A�)5)KW$�o��=��3��:G�C��Q�/qz%z�� r:.f�5��TPk�0���fL��H�pDaAoض�>U�m��Xƪ�H�֣4}����n�j�)6�&����ϲE$��(��W*|<�TI�{R"�xᨕ�.8��ߺ8�z�u�,j,��h<�7,ߪ��i��O��o�X`\%�u��6B���xG����)���W#�0���u�j��B2U����{.���p�b��+��56�&��_>��5Ё��ۿ��n�G�Gk�� (�MA{˜�u5C�{�]�l���s�uȑE��QGp�l��i����������At�`�MxbVd�g��L�H�Y=���mI�:w^�,�G+�����Tw%!������ĺ�{���&�u�h�iC���{�bKv��	���X��� ���;��[��o��J�]��i_8����B�w����R��]w A�`'���k�k��ҙ����Gw�V{�&�p�M�n��OSk)����W�pE�/���F�H+�S��F��]B��iG$ڧ;�^�UO�e�K�s�a�,R8�s���,���g��´��v0��G?�̷�
����ro�~ML�5K�)�,%�v�0�K>�	�U��-�a��
!/n[L�]�S�3HJS� Y8���q��C�t	>F��㲧.G꠳RM/hd, ջO���Wǲ͐��O��%�<o�n���K���K�l�΀Q�=NƩ�?Y�%)/hiߒ�̇�!'B����sK�� �a`��%�֑�A�x����6f؄=DT"���ΰVc�gX@���U���� \v�}7��0��H�?������!:Z���!\5
��#�����5��=��Qo���%} �R�&�<�ٰ++�T��DR���W�VcLS�}��P�� 7h�K�����k���Ƅj�OR^�|�Z����X�~�3؈Uk�����@�v�z~@~*[���Ջ)-S±��Ay5�Q��{��-o�u����������w���⫭a&�B��rI�G����&Q�ִL�$�"�<�(Sg�E��	V�x�1<�?���$��*ָ�%�4�JY�5�����Oi5��:���E���q����E��<.,�5e:~�.ga�[rr餍V���u��z�����O�Cr�;�~�`M�����R��;�?����f���Ng[�Y�W؋��G��髜!��Œ1t%��9�CG~��S�-�BaN����_�vT]���8&�<Qu���}��.�o���wx�{��^Z�r��^�9ǽ�'Zdv�XA�dtZ�?,A�B��v��ф��Qx?��������=o����KoZ�&���6=����~��eC葤ZX��ecl�4���tg��8(�7\żW��n�=4Z�2t8\?������d:�I�1 �	���LdbBL�8#��k���ƚX���E�p�#;P��N�i��x�@0f�4��}/�Xg�6�3ySΊ��Xc��<͌�����.*Hn����ɠ�]q�0 �Y������� ��ސL�R�nyv=܀���<�E�)�M��?�2���5�J��MPò�+�caV<R��v�"�
����c���@�L�q�PW,�\����M���.�O\	q���L H�M�D�Rva�ED�m0�P�z���
�Dglt���3}��%@�����W��x�V�T�hU(�@��'SV��$dd�邆���G)k�q&dJ$����t�<��Xy3��NZ�	��&�k�L���PC�kJ&!Sa������ �������,�-d�u�d�/�l ��T��KA5��Ly=�p�����f�~�P���f<��3�fH���1��7�o�7R��z�~}�6�H���dܩ�������j�es[ �\wy��Y�B1-��������~6�l�O.&��^��x�&ݛJ�_EY�����;JK���� �x͙qp��'�՝�"ݜl��Z�����B{c���G���s��մ� ��2.d��Y;4ͅx��QJ1�S}�0�Qn3b����xl��̝g��x��;��B���?����ѸEG�T��)rz��]�μ�s���e:&���0�FG�n��u��s�8��T�oRA�I�3~���m��a���k�6�x��(���$���bb��6\o0?�`��"�* �k�J��	W�-.���:?&u��`�Ĥ�,�W䪖Py��)��Y��$n&���C��aD�e.����T�
�{��/���e^?�b鋱~'�U�,�?jr`'���ID�����fO��sm��i��(Z<;˻�\A+�1���"ӾnP|{.
�µ�D&�X��v)��0G��$~��ᤥ��m�/���-����V�=�B�3xp��[��,	q���O� ���mRU4ڔn%���oeު����9�c��|�x���Ӕv(:�0���L�kH��jF�;$�o�b|�=,�FD�9(	v�
fh�x��xA����� J�~3�d�⭋��f05�ΕHe`��(\z�F��ҡC�*[B���՘�Xk�w�����XT]@�!�)�v��5�'z�6��w����G�pȦ����ڠ*S�[]�>��Cxz��h	�e���OP��v�6�J�`$�U�j��g���1B�}Y��<g�~<6���������5G��p���4��$�S�³Z^�D���,�:�S��mx� �2{1����� W���b�No���%6^��I���u�;�fh�3�-$(����Bh��=9�*r� �j]ik:{	\2u�:��j%"���cA+��݉I4�oF�����d��B˽��k��V�Ӳ[Z�b����p�
.�\�v�'e����u��FvJ�v�?�in���1�=��.��a2����XZ�s�yWFPMY�x����]7��!�$B�ۜ;�"?=��TO&�y�Ҝ���B���H�ȑ,��s񱄺O���]�`K~���LK&��$8H�Ak�-(2m��g��� =n#��Y9��@n~�'� �E���
Y�O�b_>��h��)N٘�)��~:� ψ �μ�+[�v��O��Ek[*�ܻ�-k�@S��� �G���#�G�M�?�Rp
�!���&����ue������7&7g�ǵ��j.�G�qG�_Ǫ!_���WtN�f^��� ��6��� O�8�w;�i�8��ԖpML�q��iR�~o�,+��r�4ˋG���H>���%�g��Lf�U�k�O�7�e�Ûȇ-�u�H0�' ��e�Cڜ�����/��0�U��M��/-�U�ǀ#K����_�$r��ޔ��Z�Ѳ�v���b:���ߛ�g���>0�5��!��P�������yQ�f)�&���D�iv�6��p�ܵ��8�3.&�o5bƅ~��4:�1"��:/:�y��. 1�j�o���fS�Ր���8.���()�J>�D��m��{QU܎cŀ�-��w��Q���7��ax���3]r�Wu�f�>	�R$\�&��S7r���hm�Vi-��B��8s�b�/�ߑb�֞^�z� WL�����@���m���&�ʄ�^ }�r���'�[2=��n�`��@/g!R��F��*�z�C��FFuޝ\_�N�3Җ�F;"s�2����\���0�@�i�{l|_�dP�7oR��N�1�+`��$駤s��8X�]&�5e�	e�z<nh�
U��hOJ�J�m�oJ̲���5�_��U���ԥw���(^6Q��d΂C���Y�K�j�ϕ#�|?4���<����G�Z��^�o�$�z����7��[)�HX�cܨt9�ר�,	yL��ֱ���b+�K>M����|E(B�I¾���؛�ܥ�+������7wL���d
Za��գ�3{�/T�+.350o�����I.{��)-fsF�� ��S��k��ī	���[�ve�����5���sQ�g�]jL\̽�J���U@��Ӈ���$ڟB3�7�q��v��c�2�)��wN�u{����۬�H�C�_q�) �H��y�+���}
�x����G�<������n{��f��п�*w����`Y5�8���?����/@�:5#���V��:G����=X�y��HM��b�؇`��oC�,�md�CBU�zŇJHE�W`��UxT�%�)d�4#���&��`P�Fy��6��`�/i9d.״a���>~�� /�k,�<sF�}D�T�:�Fw�D
�&l����8�.AA?�;8��GK�\7-:>��e1-0��O��|�r�e:X=��E6�Be��jD[��r��u��|��vЀI���6!+\�f. &r!��^��L�X;8�S2��'� C#�-�����q�E�M���.�h�ђ���Ym3���bbIOm3r���F���Q�E�VV'/�s���EO��צЏ^f�d�t<�\!У��/DA�7��k�c�ԩ"d�8�^+�?"�|�9����6��oS����m4gmNy��U�D ��GLյ���v&��g�.�sw��@fٚ7��"ǇlTޞ�'_\��n�B�����Bm���Lr��G8d��Ө�3I)vx��D1�N;����y۔��[(�
�~���䲵X��2x�<{����Ν��B���/�� !���<���бtF@؉����Ӗ~6��=8����F]S��F��3;w�LG?�<mU���&NC~��f�}�~�52�t�TB;��ˋmc�f�,��k�I~">E�+X��3�W���27J\���͙�_��*��m3�`��m=�<%��A/Ѷ��ӌ��YX�G�zg�0��=^C�V��d�9\=�#\�z�}A��e5#�΀���{�b�����d��/?{��2C�x���2�4���8�������$d���2��z�[:��:ya�.��p�Փg�W�E�4�&�!(�el;�c<�� Ԉ��dl��M��@����N�,9I[�Q��N�	�Fԩ�!�?+5��������G��A�����8��]�!�{/����#�� ���� I0�F��EΥ}n���}�8�ep��	&|��̷ެ>���1��3���awZ�Rp���iV<W�;y7fvH)�$z�_�辶���u����:5\�JEqwG�~�K��9���r���4S����F���s�x�&P�h�ں!�(k
��N��1����������p���.��DD\�$g�����W�j5�e)X�*J�8( �fiν�K#�ε���8X���:�+�A1S����f)�tl�a���]~ݔ��?�{·0�`0�c��F��л^�IT� [dOy����I�_��L�)�.���Hg���1�_zzC�)�+~�g�� ����+����]�(
E&�:����^��֡��mAr��b�c�Qd;����Q<*���_�L�T�l�I�i�Y�2'�~V�>�G�.��?GX"n�i��(״��
� �r��_E�Ǽ����t�
���o�Ǉ�[�E��"z�����˭>#�ȋ,0m�=�,�X]��2I��<\��pA��
F���]��/	�4�ܹok�W�K�^|���q��#��ks��`��ĩ]T��F.y�z!.S꼋I���@��O�.1�,���d3���+����l����#F���(w 9�#���n�\�Mx�� Cws���N�I��A���𤷯���Q�����s�g��B��'�Xk�b��.�:.� ��%���W=�����x&�4��\O(/K���fd�:4�ڵ�m��m<X
�ܩ1u͚���r_M��S-u��*�ct�]C<s�ӂ�"h�K��";�]/�:��5s���6tvM��Q s��;܇����B��!�r���V$��U�!��H��Z"����sH�����C�qsAH���g�X�U�̹Ajd���ó��3,b���n��@��U��$�h=����͕H��n]0˕x��:6��8����`�[�~��v���`�0u� ��,̑?��ޅn�Qr���:�[Q�V;�{�N��nގ�nc�nЉ��#���Q�?ܜ�,R���3�ϛ��j?�� >6d�/���:,Rr;Fl:�ꕿa�|Qz��ֵ��Y�T3��I���1����r�˨6�� �Պ�-�4V9
�xp�h��{(��7P͚Dm��4�i���rOJ��#m������~�ـ��f5���S	<����(*����jV�#Q������O�'N��DΪ�́��b�'%�jѲ�}(p�х3�&k��H���O�!f:��g�����a����� e��j���K� �`�?��ǒ�?��s�Ju
��=�Gn�����0V\�!{��d���:%��.��;p?Ty��8\����iw��(:P�yWjp����rV�ݯZwJu�@0E���\ĵL�p"09ɳ+X��k�
�P��������%\hp�T�E�Tҕ�x��恏Q7�����<�wC�(_!0Ce�vIn��8�qF�����H_�Z�-B�mk���9䙼�J���ݝ�;H���6cN<��
0"q�y@�zRvNo��ա�����!@ؖ�z����-��YJf���J$_qk�;d��k-e�˓#���3a�2ʆ�{[�� S�ȓN�\eyq%jii[1�2	�IL���T�J�#���!���
)#�UA7�Ʈ����ݨf:H�t��4�I7<���^��iS�U�r">���(g(��yG�X<+-䃍Ԉ�OSs�L�~dխ�~�0�K��yO�N��n�������k��k�z�-RjR	x�_��Zc���P�����e���\Z�U�֡�DkWt�,���� �v�%᪍"�ٌ=�%ʪ�,�n��S�����:ݷ@�ʥ�"�eH�,<��FV��'ǯ?C�o
)�Q@#H�mqK�}�o�&T���U?��C'R���G�:�<֡���+�����y��ҙl�����y��Q.��M�4�T��b��oMÊ��E�-.��A��H*"��h_�UZ��5J6u��:	'3o+�>�q��=���w���t�j�J�L��ԐF<����X�*����=c��fi�L�	�_sY�vщ�=mX��K@�Uǡ����ReeI�B���Q�&��E�0�8{���r0|"�f����E|=ȑ�3�O��7M9��罱��Yx�o�ݙ�t�m�F�i5!#��{�A�a�
��S�Ai>*a����
)�*�ޡ�����mҹ}�M�v��z7�����0�}�"�x�;�~.5��EŅw���9|��'�:���m���B��O9t1/��-M6���ZPF��<d)� T��@Z_a�U���;^6��	��O�q)v2����`���W�Z�"h�ñ���]^��]p:�|&�k�{��7=���$a<q���X;J9j��&�l���X��� %�@k���AP���?R#�����dt�^gЍ-�`� ���~�U�������2�2RX:v�/ʩqiY�EJ���y�'��Tz�k]���A�;���v���t���S��	�O;c�`��uy۫@{|�3_>��<7T�_�yTpi�|w�ߌ�~�bHI
�L�1.�����9t��ܷ��w��'�|���o+��[��aAh�5^�?��Y��=[�ɧ�8�I�w����D<윝��/88��2Ȼ۝	9��Aו�	�@�q\�J|���7y�A0�|p#|�`Ü��%�q� �R�R����i>�V��E�f�����ʻ�Rǻ�p��Й����D�P�lr섴��ϵ��A�4��!y��Q���!f�d""���a��օ�kk�0#yE���v�>�ׁI󂞥d<��vx��q
�x����ݟ��5`�b�\A��4>-ct����3vO���[�b��mc��M:ڬ|����<{���J>ܞ���M~�3�zf��(6��
g�TTB2�_�@S��PPXt�&�҃.�Ra��OW!*����ҟ6�^{�k�Sڎ�%�����(:>��Ҧ��k�_ޛ�X�YL��3�{u��������BshT�.�0��wI��:7[���G��F>>�6/j����.;�ya�����VӁfH}���g-ߗ�~l�p����VZ�^�X��15i���~�|׊��*�7�;�������Qq��q<��!�5�s�#�
	fF
�h����'b�Eʢ{d���tt�O���){��#���<��#�P�(Pp����PM$S脪�y���P����ǲ�͆2�=�g�S���F�}���p���P� �b���[�8_￡`'��>=J\�O.Xp�>�U�sX��AM�2��r�6��ܰSU�V�*��F��=�x�AV���ۘ}���J��/�E$�D��L/��t��P��S���Sy� 0�,���M�i��U�{ވ�;F+��)�p݃TQ��,�-pǖfK=	ǻD�9;@k]�EZ�g�LV�������`j���t���z_�6A�ze�(�"�+2��?��2����7����t�	w���������e��O��L��(�e2bZ\�aeOz�Oj�>9�y���b�ѹ�/�5���"F�;��>w������=�"�d�����;���k��9ga�8`J�e-Q_,�+��(F)
ڶ�;f7�Ҳ�:����3l�:�d���bW?��c�� �m�`��&f��Z_�����)\+�W<���n�9 �~ۮ���zB�*���j�	��)��v�K�4N�`���g�k��	�^��̮����6�L#r�D������N9vfy?J�#�k0��h�L�Оr3�� z�� r���aN���S��L�n%<�J�5H���o��/�C��/c��X7u"6��^{&+ރz�ũLѴ���\�H�I�ʇ�8��!��ș��� 6Q[�NR�GN�F@:&$�@\�ܠ��*\��c2����'�)�Y4:9����7���\\ay�N������ۗ�n2��"�]䭫k1�)$��ۼ�+=F*�h��c��F�U�����]� �:~si{l�ߑ��,!e��Y��MAЗ�}Ł#?�Q�t�5�����
����s����p���hA�撾QzqI��I �}$�f���R�R�^�v�L	4,�tC!��������|+D,�R�=4�I�Z�4�y�Wg{:,��� �"��<f�6�0�~�������4�̚Ϗ��Vx�qy텅|�S�C���P$���\B��Px,SX�k-��SCF6��h���?����R&�D���f�,�m%b��^Ӯ�.#l�#�u�?�ϼ<�y� y�@HOt���K߷Q��I:_�>ƅ@E��}�Z���7��O5�E���J�S}��T�I��{�R=�lK���
4�+F�ҼA+�KE���� �㹫v6�Fumx�$x�,j����\�"&D��$��%�K�`#'�S�l��/�u���A��aAf�P9~�)}M]���.8�U�(�b�\����|��@O������~O��៫���<����YD�o�F8lM������*~i�3lRޏ��,k'����c�0�,�:��	�����A�x�Hb%��k�����dL�g~�|���������Z}���8BL��#�4~ՏyNlJ��v`������n,?VE>��,��L�yf�" cܛ]+��Sq��w����쌹��A1~�vPX:�9�Og"�cQ\Ra���KXO�-"P�ϱ "���<��)%�0
�:� �Wz�������fs�*�΃ļ@ �C����P�c4��nvB#�f�!����҂�����Tw� E�%�/��4mEc�7X> ��~��ã���0%�p�u�>:ii���d�������ʀ/�]��d�a�Y�D��yə��}��f�nf���Md��\O�jRH�}F`���M�X�<��=����8J^�x\	gW�:?�)T���w����S�����<	s8H��n^�⸑���,+ۼ�rߙ��h>�a����ԉX���Hb'��S�Y��Ԋ���8o{��z8%�[�5�bʑ�Gpbd8Y";Z;5i��7t׍��o�V�ԊJ}���j�@�RAi3��`W9M�ب�i��}����l�V����2M������]�ڛS�.\&�-��k��Q��ծ"��b+��j�����0*y���`Q	]��w�Z	@�/XG+=^
d_b�R����!��C(�B�LuwҿI}����SFI��r��v"p�Sv;��SY�����'��^H�V'w�X	��W���q`����|���a�BTn4�@6��\N�}�bǊ� ��6����/%ggm�9}	MR��8�PbJG4݀-�ǿk:sWm�����U��.��D�r����p��z���FO��m�N= {*N�Ș-���h%=k��bE�7��?�~��"`d�'#��nf8Z F
�'3���o���J ��D�f�BJ\l�Z�tE�l\@����k"�G��\գ�nB�X���2b�u@(�7�mF�����ff���L�:�"�A� =Ŧ�����ʔ�E�[#`i���r��ef�����K�0%�f�'����sm�jBD��>I�"�rU��zK�&��կ9�+Dڶttp2�
��3"����6��y&~��@��u�f (�z�9y��cˏ�p��0WVw���<#W_�������n 9�h+d(%�ZŰ�Պ�n����(�=r�"�##�G�9�L��j}R�{�f��v���L����\L�r����͝�q�F�*��{��H����Q￲�`�a5E�4���Y��iX��xX���Tֶ����\}��JAR܆"M���04���I��1S6�L�f�����R���6�۾�Ag؀=�9gbm*������1����d ��rjO�<ZsZ|]q�6��Xp�_��#���|�}c�O�;j�&.i�(���p�̂�b���d�0�K�ս�������'O�}���&�(��B)$�&�YNY<h����]�f�E�2*������7�c��<
�$p�<t9�J������ L�FԋC�5�TT~�uĈ�uE�<h�M���C�k��Ż����	3�������;{)&�x�Eh�f��e}(�_n�I��Iݵ�$oER#���P��e�;����ѵ��ZB���cFf�M>��k�2r�q��/�ð�Y9�'�W�������{����*����Y�N��Ink�n�y��^�ҥFq����U�� �m��(�[�������t�|V��b�J;�j��A�7\Q���!Fdf�[��7sw|�[������ض�BeY"֮W����qNg�& ʆ2'��3d	���.����x���1�,��t�6���ii��9��$h�6=u��8����`�[.Bx=�A��`�.H�f�<D?H_* �fS��$%t�C�3�Յ�e��[���m{��nn�п�9��W��v���Gdk4��G���H�r�l4��ޞzg~67W��!�r�����|UX�B3$�_�h+��f�/L�2���c^~7Vt���Q�>m��mAv�%��O�(��M
$������:׫�.Ѡ��^~�GL��`��c�]T�l��������1P�[-7�Њ���oecC^�7���szwӈ.���Qe;��=���&�q�k����4�-���S���8Λ�('�C놑�
b�ֿ�J`�o4-=q�D>�IŇ�Q�ҊX��_����V�,�%�FJ�ͧg����WVKrU�p���۰�V�G��'ź'�t��O�!w�Ā'�<��~�q1�|ą��$����jDp�j/u��`�\�t"XFJt�L�=�!��;�g_/ͱP�o��v�dU�������2
��ci�k H�� ?���7{���[(�xR��`l�y��5�FW~�t�%����~E0���Y�f�i督����h{�.g�̇��_�&58���Q����g�i5�K���G!E�����jO��dy*�X�zu0�gCA�S6���"��q� z�e�a��\���gcKAˊ(�#Rȴ�+/&�+%<۝�Q2祧��fe���"H��z/U�N�| W��V}/�R�p8��G�+c/2���̹j�<+��nG�t�ύL}뇕�U'HK��3�Q��Aו����ŊJ[�;umm�uQ>��io�1���6�k����Qp^<�"*��$5�!RÚb�_W���`.��Zi��s<W$�s�K�P�c-]d���B���f�"8Q�����STs������
+[aj��`�&�b�#��K1�&�+x`�X�bi��nZ��pR��1i�ފ��*�,XB���U<5�Р�(�#�h$a?+�o��Y ��h:��lBa|�N��<r&(�王���-U�̶��<�H	H���u�ߗ�@]/�ZHiC��Zޒ����b��@���Y5	t��}�.�����k���ޙ}�g��k����V̞.+׀���j|��c�/{T�"ܓ&��`^�+,� _f���
��G�/���^�ă�q,`���Xw\n���h���Ff���H�zbo
�#�.4������8��a*�ryW��_a�]E�չ���i+�fp)x�H	��Ğ�,��ӈΛr�������"i�9��w)��-[�<N߂�΅2�����qi��n`��j��B�G�j��C������� ٲ�z���w��~��!b'o�^R�O���As-g۲L�@{#ײ�gy4Tm.=y,XQ�����8{ 5V������돷�� �N�ʀH�y)a��9_$����t 9j��d#��e��B�G[t��xu.S��=x����#���<��<4D&�<���5��Z�x�����Ҭ���x�ě�x� l����i��4�+~j�M=�K�	�4P��~}���.�A��<1�jH� =��P��E�܊��l;���r��=p���0�]��J�X�ȸ������`�q�Qe�i����f��p�ʎ�x����C�5�f�o�$���BS��Mƽo	��6�ˣ�B%Е澔]ڎ�I��Θ*Ļ3�?1�E�|�����a�-{�c�mZ�xwf���}����8B�fgo}	�	4_,����;}�K]L��O ĉ+M��2�w۳�����^q�WDFۺ7;Y�ZoAl�:m!?�2KK��I�$bmL/����<A<"�".�}�%��s~v'Kލɒu�[V�GX���a�[�^4�gf��Ы���;��wt!�}�kKZQ�jW���1 ��؆�� �OX���T�JӘbf�I����3�Wl�!�e�3�A�<�5=(��l�Ϸ�"�i�x�@`1�).	 ���>�/)����'��}���bu�7�ǣ���*1���I�$gF`U�=�"V0�'*?���Z��_�;B�X�[�/a�\߬@�^�~{���^��϶C��Ad�(ou8B���*��/|0�F��m�����-'�޿��"}Ny�JO�������:r�9x�˙		�x=�Z�R]m:�yȘA(b,s-#4hw͌��g�����UoGg�<��F_a@�`	�:n��b�./�䖛r��e_>�N���|F�o���m��g�l���*|$���BPĥ7T���ԹB��]J�ϩ��¯K#��!�6)����T���6<�8kA�k3y-��<�Tz����z�<�ӯ��5�3���8I�Q���= �A�囹��?�P���]L�+a,
����޿ě�5x7^=�g���`��G��ە�,ͦ��d����qKd��AP*����ky��o�$A�̥^���k> `�3&���g�@��Eq�0��	�}M�Rx�`^V�	����<�d�TF=�oT��3��w.3Ai��
Ce7
��N|qG0F�$��W^
�
�wV��%�Y��!C����/XMP2��9=4@�]x:�XT�n��x�U����v4�~��znCXG��F+!f��G�.?�7=��P����~�3�UD��m��X޹�өZ�V��W3���	?_e���"�C����=��u�,�a��(��}�h �a�m���ZZ��6�#U��K�9YU),����<�{(�E½�O�{-̬�o���^ �w�ͅ	�] �F�p<�S\�dN����z�&���q'g��A��K����ݱ�o��c�أ�7m��bv�S��G�X+ �����(�W���?����!��L֮<:��o$֟�тڵ���Ńb$����|VT���R}$S��>s0ލ�iX��v�������l���S׫>��D���$��������㊶���Q�ܚ}$��i�����)��N�C�8h��ѹ�=pT�Qg(�Ղ6b���^�ݺY��O�F��6�N)����A�n�����3㳂爱ּ��3����Y��o��"HF�/r�8����h!F'�JPw����;�z�C��눆�:����� gCi<:��ii���$w��.�%ɂ����t�.���U.�����?���@}yR�|�vz�!ݬ��T��/�
~��`;o��D�W�pIiq!��1�x� � :���d h������gR��,]%����GT����Q�+ɼ\zaa�^Q��Kc�׷ąg���2u��lD�J&;���(��  m��{m?ҋ����>�8:p+�x���8Wz�bFI)0S�I��X�,�>.���n�F��O&���q��.� W�]�0*u^UI{gxǱ�����j��}vo�c����������$д"`�Nz�a��o�)�9Ɲ_���	7�l��edZ���<��e�����@�B͙�55z���J�ً��������У�̺�r��.�.������͔MVV8P�	���A�);�g?���sb�~�  �ܶ�$Ժ ����b�c{��g�    YZ