#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2534626875"
MD5="71f1a67007288e706de672cc3e9a9c3d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20728"
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
	echo Date of packaging: Wed Nov  4 03:03:19 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��1Dd]����P�t�A�|�6 Kx�C�CR�<&ڠ���ϣ(��5�S�Z�m
f-пT��9d*P'�J��%��D���0�`�Q��4gyƕ5��;�[
�ٰC�|�cw3P,��J�R�oG�K�~��K��|W��
���u��L!vC��U�D�o"�UݐJ��'��)��ߕ��Ebq8��u���߽�i�_�q�s��	$���%#���A(�#����9�z�!m%o����دh�>��"'WX���j��^j�
�2��/�0�lTd�_��&�py�.���:!,��Y�\�:�J#I�C�q`�����ӄ�;�b|g�����-�X�	R�1�-�
EK���g�w�>�[�g��j-.L�������w#�fd���Vkkp��L�a^*OX���$�DHaٛ��Ru��F	�N��eu�D\3�A��)!U���é������|򢆫��b����.x(��ۜ�����n�Yw�.��m1P�غ[%.� ��{� 6h��&�F7v��6礀�JT�󠴂D����8�Z�_��}(moM��2Ľ������G�}��Z��1V�S�ޮ81݅�"��f���/*�u�b���L��֐�V�L�B��e0@`f�^=���V�	H%�T�y���=���C8e������I_�v�Q�mj�8}��gR�j��=x$�P����OH����;K��7y�Q8��ޡ+�Z�r�u+0�$�^��rݖb�Su��z���$QJ�8�: S��
w�?p�B��c��t�~ˇ��號`���*?/#�O,��p$��F����ENF�a߂�K'�Сז�Ik��v��#�a������ ��׀�*6S�9��AgJ���Ib�<�'�Oݢ:4�O	?���]�j�u���_VR���#�@	p ��8� -1`��F�j��7�S�#Y��HC ���M4�l�]Y�%�������_�{�~Y����������2Y�|l)�1/)�����}�IG)[Y�hR���=q1��KH�U�-N}�;����	���]|����OÊ�_L�F<��e�TE0Vd^�z;Bl\��Q������?�=q�^��O(q��+�E&����R&�p�Zq��*��	�W��C�]�>���>;t4
���N�m5e�]v��Z��[��]��ԗm�����hdT����������,�B�^���N�{�`dD*�N�x�-�&s>c&C��`������D���Z0f��V�1��2A����
��y��tJ;�R\]��2��}�H���U�sm!8����\> \�bֵZ�h���C)�+ݏ�&�j�G�:�x�ئql��Л�8�u?���Σ��	l�d���
#�A�����lh����!�.��M��tb1�7�K�	�M��UL�����LEQ��P��,Y.y�?�/$��(dO��gqjC'��;�e��L� )��Z��d>��s���JƑ��9J4�*��p�&ZU!�Uxw�2r�l�|�77� �I����ϫ�($���Șd�S'����y�-i���H&��b!<}h�ɪxo�)��X e��]�&��FV��	iK��5��',���R���°�,v�G��'��y�+H��\t�\�#u�s$]�:r��KE ��+k���n��A������sH���K��ǽ�
Y?k��߮y���t2��pA�����io�t^ؼ/Le֩(�me�8-O{Қ;���x�5���Ѧv"��WQBM ׸ P�:�d����q����#@��:��m$����v��%BB���H�-�q���cmkB�WN��h�ݧE����4��"c�qX�����\)��fk@�"�S��w����_OLO�ڑ�f����(y>Ж#�
� U��.X���^X��#�Ç�+�� 'P1�Xb��OiC(�R���G1 G�Qҩ�}C��Eft%͜%���Ǒd�}�o[�mMV�F3�St��	EjF£��<I֑?�9S+���N(��WWeݪ���3c��fl1�p���LC���D|w���q.����4z��	�S��I�s'�	_�н-qU�G��Vh ��VtJ����.�m�/VfIө�mgذ����n��틇Ycq��"����qV�8aq(E@W_�c�ɛl'T/�
�?�}O�,�D���2L}�Wi�5X����
4e�@�C��G�J�Pj{��	�1{l�������LF8BVN@	���?%9���
J��R�hŌ�?[����՟�P?��kOա�2*3�#<?���ZL������[���;�K�y�K�=?%�pc�r4�Na1H���.Q�U�h���M�f��U�8�d1!�6�,����d���^Y5��R/��L<�/0���M���������@�R'i��J|DXp1m���Zz���d����~D�����<��Z�<�C��0����� xP:�:��/�6���P/��M��m
�gf�Ȥ�|R.D����/߈U�\��84	Y�r'f����&S��H,:Bջ�r��/�Im ���
-T

)��m�����êa��)9��Vi-�������Gn�����'����i-�(dB<��C��P��h�2�i4QG�����sz��|H�����.�Y�\�Z�/������U��6
�l��"pU�*t�nq0������|�x4�-ߍ?�_�|���/�{�����d��'c�w���%;@��9
�\9�̺�h��o� ���}1lINFꬊυ�fO�]��˳�C5n�{ǶPwG%?�w]��hZ�ű{I��<x�r��������i�i����������.X�cvd�L��\�b�0x�g�ߚ��2���V��g������@�}Bf�gބ\���W!И��4��u��8���p/�h��"��ltg��Tv�5y媮���A9�x��Z�%��;S�]I�?�㏊kO6�٩ew�<P�gYYb�le������ǔ�' Y��i�� �Ex7}8��D���ca��o�T�H�C7@���%~/QϬ�g�yk�QZ�#��M7Z�"5$�Q6G�@���o�=�V�U�߾�Mx���3gr��~�Bt	{3����7�l4�d<~�|��(��ɬk�"�5ƣ
#�z�y���%O�HӒ�׍�+7�j��t��*������[��0�^�#W���>$��Z���DQ;7n�9��37A�h��J���b����P�4A��ip���Q�9Ɠo��������9��u>�ls�y4�~oI�T�"��zr/�L���Li��|�� 'c�����d�n����S-6��h����J�*�ܗk'd��6J�8e8��Q���csa��ӻ
�N?N�����p�,����X�rFV�FR"A�WrF��몝>)<b���#�M�� �'��&�:���_�#p~�,L�6."����O=�D��0�PK����b�I�\qU��]fy/�c��x�t�~s'fUm_�IB[T�?%�^6��w��� +L��]<m�G��<���>�}���"��8��f��30�o��.����jR�!�>]-�ynM��f@p��Wր[V�����N2��()�(	�Q
E�n�<(������g��R+D_Qt�Ot�F*�d�,���G�#���y���_n�^V6ͩ�c[��_a����Xz��K�����@h�肙3���S��ou����{��������ʹ����@�n\�X�D;ӪC 6�qV!����˘�2lfX ?>�#�s5�X�����^i��9�8�q�� ��:f+�ZV7هa�=�@q�����Q$a�-�+���x�*�W�o�%�^� �z��M��jb�t�x\�����헒�mo{���)��8���"`�([��O�<����s��0�U<~�[ t8��%:7� ������3qz0q�Nu��F���W����5mC;�_ܑ8e�;��c��n�x�#uӚ"<Iȥ��D����0D������ȷ5|%f.��L>#��,���`ꕤ@[)��Gh��w���;{eu�n��Ӆ/@�e49T��L��������BG����Զu�~n��@�	+!�bP=���)��ƦfD�&H��ρ��w�?���AūH}_���
J�_�
�Ʈm�� r=<��R����:O��ޡ%�Ow��,���T����m��2����w��5R�?h�qHp��+i�i�J3�s�u0�db&}�j�� .Q�]��w��C�rON�(\���*�i���TYʳ���-��M2����u��bqQޡ��P���z@D�|��91����vdy�t@���4��4��-9K_d�L���(��(?#�N�5,����?/�y-B�t|��������������c"��_)����5����	H~E%����ܟ�J?9n���eK$V5���l��������,�����?���i��)���?ڗD�+7a�/=�\D�u�l��y���v�.<6��������Oq�zO�L6�`��W���K�[`��g�X��E��k�1�_F�<G��-W-ێ$�(�!��*�m�XI��Smg�n��f���KN���}���+?�i1#�=��]�G3�M�a,�M�����
�`6�(�D��X��Dj��pJ�p4E(�L�q��ɉ�d�Xt:�M���,������q6VO�{o��l'����,U.���$�eA��]AZX���<����AP�s2�\��[!���@���o\����^��sH�;'Ҹ?��v4��j��P9�O���N����Mj���?!�ō@���d$S�a�Y(��� Eog��:���i GMc�';N�&�	��V�d:�gGN�A ��t�'�)��R?����6yHQ�k��^(���w�K�~{����_�",>�/?J����-Z;{Pz�7|c��)� �;ݼ��]�S�u�^e�:HY�l7p�|�����T-�.u�W��;��x��f�5)�/�՘��J�K��4�Q��x!�a|����o�R�\lk.˜8��2c�]��`�1�g�;6O飤���^=*ق\b:�
C��ů{!��ԆӅMy�P_��+٦�lz'�--�2;\8����\]&��

��i�L
֋��-�+��Q�͊cu��z��Ϙ��Id��*FO����/{̬� �g�>u��t�B����!@�;y���-�=�^)��qiZV}��x}q��-��^�>�?�jA�x�n&B��K�|�)��Ed�t
V��c��� �n��1c[+Y9���^m)�՚�M2�3\�r�[Tț�A7����X�v�A�DUFW�e���p���#��˻�L��P~ʗ	Q5�T&�F�2[�Rb�ߨ�t�t���F�Yn��R��I
ۢè&��H��$�����l\s��]Vvas�3hxz���WPE�I�Еdy�E�6��8O�:1�m��T;�@"������<��#��N�cx��x+.�P�`�ߴ������ʒ~��p��TCKR��������]'x���T<����%�7d��H)���#c����d��<"%~5�+�|��K`GD�h��^\�8Fm���(�c^��aʬ�L�8�`rE~o\]�`ۥ�ޝŤM�fh5�|6���a�1 ���'p(ÿMI�&��nU��]%FþE�ŖHN껽��5���D}��)1F�w�����ă�?��lMf��� r�&��=U����"�z�x�Y����RLv&T�2l����(vK1���2ђ6*��9�ޙ$�\۪�����@
����j��䉘����W-���7��V���{Z� �mU7��%��ʝ��=���K�	�Vbp�~F�⪧;�+�!z�D�����T��"}Zw��R�
EGWGA���+���
�fS�j��N��h�[3;�9z�W����|���Ve��5SB	��;@U�U*��
$8��d�GN�z�(�T4�(4��ɡGhJ�fʹ��:���bV�q��ɝ5نk��&#�Z����%Ŋ���=M&�Y��g��������|�c�S�!{�ˆ8��P-l߭N���,�//:/��+��bM��G�`�f������2&��ҳ'M6�;E��g���x|,C
���A���3Ӿ�uGՄ@��;j#N��rc�W�C �ѡIK���� uku��qer�Y.a���<+�+Q�����-E͵��<R��eO��Tv��V���xaf E��w�b�o�k��^�0;ȿ��p�	�U~�!^5��lU��do|����XzFJf�-���#A��he�� �M.g|jR����1}�_���E�9��v�I �-͜�N�_�� �ph�Vlh��s���[&/�S6�����=�?�'�1>W[�!8i7�I�w�'Jْ���/��G����ܸ��
�l�A�H�W���o�ɎL�Z��7Z)����r�n����S/D��͑f)K+)t��t��ǅ�T���U���_
V���i7S~<��4�+���:pN�u���zM�6҈-��Pj��e����q�JExAG��l�iӕ�&n��&�f��5Èb-��l7��}e���\G�f���\�Y��m�E��E�ܣǧ���ǆ"����#&Q��*���S��3�ǌ�ǉ?�Q��փ*�+��s���$��nN�0}穴���P���Iʘ�J��ǜL�����t�����i��ĝAs��	b}�5
��6�����L��S����1��H���B/�3��X�C��Ԣ0\��4%�Q���8�cu��UMx
��$�Us��%+!����ɟ<^�O<u��}��'2I:��0˴�Ͳ:1j��I�zs�i��wE��	���cȹD�#*�A7�Wg$��u�ǆd�٭x8S�c��LR�u�c�A� c��<�t���x@,��0A�W��L,Ro�s�-[)��nH������U�w�9�XMbry@�Oo��8���SR���$u�=��	UE4eE崐���R��B��5y�׼�[���`���ΐ; e<[��g��~nT�N��a:_�a�� {;ƹB���=�ڗJ�$�Zm�P�������?�|A+�%���.�%��ܣqj`�rRΊ%^��ɶ�3���I0��P�7�yBމ=�Y�/�� ��6Ac�R{��~{�M;��X���4uq8_y�4������)��f���p�R��uQ��⡞ ?>J*w"[O���-��i�G*��K�rƿe��p�|q"DJN>�.�7��]7�
�h�)�!x�9sU�*���ԗ�����	K�$Dъ��h�5��.�{Kާ��)�/\���zN[�C�����_���S{���u����	�
l\p"�k"<<K�u}%�b�'D'3
�8
~����m�4	��:��'3�� ��k-$X�D�Ez�B�hܠ%���
3�mF��iVzɔ�vGo���;xHi�}��}�@��[(���./IUD�7�����1��OoZ;t��%L�A���\�~=5�g���匤4���7A��Z��L`�W(p��%R3����[�<aL��	Qq��ϳ���(��ېD��I��o�����cGq��*� ��a���
�;r+�4Q��tn���om�_����U�cV�g���|O���X���m�>�q96ڰ%[=�j�Q�j���0�?��9�+�7`��NU�$�E�8�����b7��P�x��:ѿ�n�{��ߘ�{E w(���av�S�I��7n�+����F�y����2w�HB1�&�;� &�s(�!T
�ۣ�.�ݍ�+Ĕ����*�HD�7vu��~���ۋ���8{�h����ɈC�oF����lGi>4#�A��_{�Nb��ر��ij���w�B;�{��#��j	+�ǥ�!NYk������*f|$��SZ������!�1������C�J���q��ߡ�W��I�VS@ ����n}hq�C��)���T= ��L��[>�O=�jk�m�םi�0|W�K����G�m�p���W�����?�x{�Iv�;D��'m�1o=�ˊv �,��E&�5(p�Y���O�΁DmBr���R�)���VD��uH`c�HX��;��~�"?�)w���Ԅ|��~|:6��洮��b�t&�"�G�~��C�W��m'__�evK�=Hn݅i��r�fk�*�J��"/(���QL���u,���W����o��rĐ�Z�T� ��zGq�1��Uw ��$ �M�mUSZY��.�>_:X�aS�`�
�s����̿��TF����#���)�n�l>�j}3��x�`u7)vF����UJ'Ӵ����`��˭3�@" -	-�lĔ5������m�`3��k���5��A��ڼo,``7��)o.�\���Y]�&!�i+u�C��c$v+(Ѹe�����������]�9}v����ׁ�w��g���%�շj@g㤰�!�n��Nǡ
��qӜ���K����`=)2�c�.`�N�[S��WD(�%�<�԰�VJ�(�;����U�ѝOڧ�<g_B�-L���y�BX���wߍ�S���޻?�w�-�� `����<ٌpE�\�+�v�KE��m��6k��I��G�G��V�2O���d]��t��!�t�"н�4Hc��[�>�4�M*2(��lp��NЎ��A���|~�Đ�c�qm^~�5Н��-Y��}�ӫ�o�bt��_Rea��@{������guӲ/�:o�wo��'����م�·z�j�ϑ�4)n=�R�)-��lwd��>M���p��������܄ArX+��B6��l.5Ӟ�������%���e�#�Y���Zq�0灌|�p��0����&Z��$���l�+4�,�`M�[t��F�ݕ�J~�(�ļ�<�{綛Z�"�9c#X-L�i����97�u�2����'U�@�oM�c��>ԁ����W<	� ^l}OK�(a�󰭴��t���V�����}i��	0B��l7M��D,%�EN�wg�	���[���/3¼mJ�ǯy�}�"K����?5��T�K?Ku�9�	���L)�_�)Gx�x�����?�-a����_7pQ1?N�&ٌ�u�T|�4i�������A�)�ƜV9��O.F+� �������IC�%Q��J�$�/X;)�Q� ivg�6�B�Λ*��|��$%F���Ǘ5ҹH�[#����~����j޹��>�f��A�R�/�5��#x(��k�k��t� ]�t3ڕ�v�s�a���^E0�,���&2��܀��-����O��!�H���]J[<7b�U�Y���i(Λo�1z����q�9�7k�d��� rP�ڏ�n�2��#D�s@ >8������Ӹwmf��ۡ`>�98r��T@ R8!�e{��b��.�u ���D/~��:0<�?�P��?���Q��Y����GLz���@��Sk�W~�p0$�=�B�]@�2���FV�#)��R���V�M��cƮ�a37�|&�{���mv�����i�n��w�	���X�1>¸������}K�xm��ڢ���f��fJZG
@�����K�+����jH7�q�I�&�aUO���^�>�A��P��,�Vڇ*�)I��oL��W�`'���)�􏑮�֮k�X��^.k
Ho�����CiCur�p��3~`jN���[(���&��L�iZ��ۢ%�l`j�;�s��#_��NБз}�h���*��Њ��*L]��HLt:�eIZ�4)�9Oʱ5e���Ɓ����MY�x=����o5zv�us{%� |/�ҟ��b��&��),o�= ]��,&޳��K����Qe�k���d�o��H�3dӅ�yi�C�qo��u|CA�2i��tL7��S5��H�ʋc�$�L �~��;}s��G�,���QI��L↉��!+l��	.2�
yR{���I����"���J�UU�r�i���k�!D<>������q���nR���� W��FZ���#���'̰��BP6�"���:���ú7��szS��Jܦ���n�uTU�� ��\s�]�F�8zY-�ZLe�L�nԼ�K��+P�VNЂ��U��j/Y����F P[a�l��0#'���r���צ4�N�����_�c�g�@���w�
���B��r���v��a�W��}5���`��t�("�'��>a��T1T�;샏�`�0�ۄ��	�Q��O�|�M^]{��Uok��A�a-���!�v���%�Q�Ʊ��IV'=�&L�r�#[m����_t�՘��_o�z���i�;iT���A��3TvG��'!�)4�YB����*)�jTc�T�%Yy���y���e�Ez}�@b�b�1j!]�V�B1���W�,xÇ�l�e	�-���b?�:��x�и���[%�({Ŵv8*>x�m 8�rz3�bF�)��P{�0%� s"!��NKL�R	�%R	�<[�9?��ad��A��P��\�m�������b�����"��S��ϋ�r�����	�d�P+@�����W���N��掿P`���`#L�I��*��wʰ�;K�)��Ƣ�ڧ��͘!�9W���s׵���ܹ��c��q��Kyy����"�Q�;��o��ʭm�v!���p��Y8ɫz���'� �nyѢ��:a*GS��/=�O#k����W	�
��n�	h-��oQ~����%�h��RZG��9�W��h��"�7:䉫�j�o��8�����(�O(E����|�G�Yʔ�\�-��\(M���oj��t��R\ ��J�2(m����s*��v�g)�p�i�7P�+�~� �V)��NqR�#��ҧ����.�a�����g4Ĩ�x��(e��Qb���սA<�v������Bv5�N@kt��
ݭfS5��As[�H�7t�E�^dC�Ył�݌p��"��n������ٸ�~ʄ�+�F=�#Ϧ�m^4��]�n�� Dy�4�#���|γ�����nL?��Ҝ��.���!#2Zg�m�u��y�P��j�����hץV9܍�	G���3.U��}ׂj[��Qe��M�d�@a(�˂�u$��jO\��ԔS��笘$��i�q^�LL*YPw���\&*��͐�4��`�99�|L[����Z7��f)�w.Hl�����\�ob�cǶ�,w�τ�M�&:�\�]�Y�mq-"kX*���n=Sm�e}!���p�v,5u�}2�j�_NsR/��{��d�/;��.��ܵ�ʖ���x�Tr�;��\��"6m���-����җO��Z�Bÿ�K�3֡Qzp�-����h��~WiB���%�f�#��@����K�T\s�O�s���7����`�"��,h����������:Š9�L>�ت"��ʬ��5I��v?�X���c��0�ӌ�g��K�t�[�7ι���H��D��]χ�ս:�IR!s|���.�^���Q̈́dH��a7�b�0d�i�a(�kdt������!� �ٌz�&����稼������NX&B�%t�g�y��=�$���lO�Lǋ#X+����������堥D��r�98|N.� ǎ�/���I��=#tA7�򘽘g
eb���,�a��}�M>����E@�<t�%50e0�c������F��ĄU�T)���$GF��u  &Eӯpe�+�Ň�}#Av���Ofw��KgF҄��|�qx7*D���
�961Q	���!f��+�J�ʒ��v�	}_��]��.�:�����AFyGw��ЈO�� ���a�=?�z�ldq����H�@�<�Z�fV��_���S겿�W,�_38�.�u�Աnl)vU�8�@)�>��vc�?U�^���������f��;Vw%a%���������X/�ܤ�0�![��b�װ iojHm�f��Z��e\��{":C��2H<�T�?ta�@P��Y!��+I�1�I��>)�����k���D���T?=�Ƽ5���"���]���c-�R%�������?YP����3ϩ涳a��C�c�ˬ@z��k��d��e����Á7�Ͳ&>�Npd�.1n���c��ђ�v��<S���O͝=�����і�%��~�@o|��v�)�9�=���@�Ѹ�r�z\!�	��z�H,^�ϰ[���PVu<��Yݓh��X�*��t��!�u����;4�d����1
�s𭿤t�F?*��]+ܫ�����Z�m�6=���\y�1&��� n�	���ͧ\�.�.�U$�QԎ0����~^t���vw��	ic+�B}��1`6 �"�(E�-%-�kŔq4�tI��!��e�*2��!���`E�YSc'0�4���\0ZPZi���`@���QRz���g�H����ia�v�l��Hl�S^dw����&i|�Q�h��{�`!1�����N�o�k�Gw߼�,$�-�΋��+~�C{�>�]��ک0���x�ٵʞ(�&�H��Ա���*�ϩ�i��a�ye2^���Z��\&q7t������?�v�����}��cyh ]#�˚�48�%��XB�����3��?f�4�����@'�%��n}�U�����>�@������|?	p顟��8��Ioqp����ۅbȟ��G��՘{���l�qu� j��xЗ��y��F_�&)k�2@)��۱�7������F��U�t��F��[O��B�^�ۛV����e�]tc��>��FΑƬO*��Z/�����97ס�S]�ǒyf�%^w�D��Ħ�_uˡ'}Ek�M_v*c�����Y�7�<�n*��Na�@p��=5[N����B]!	�D\�7˯g"�a����) &#�v2�oo���~���܋"��V�K��& �}��0pD�	��ڥEg���u�!Z`r��U<��I�г����󷣈�w���\�����jI�q�y|�X7���XT?�M��' �_y��ay�Jc���˶}eg��4P)�u��.��nU-a���"�3�l|(���3>8�X��i�\��R�z�8������{����48��%8*֛�o�n��9�3�Hhc���\/,�.y5�bFL¯�3�3�re�'����q�fG<���=ZSO�RK��}Tټ�oU~��)�0��A�~��0X�_�B�JC�;�"��w,k�Ƣ>G���a�I'S�՚�`[S+He)#�W'�:�D�aOXv*��w_��,YZ)�Y�@:`�K��:���3��3�.�oрU��.㺀������B�������T�� �ݥO�$�O��P�B؂���*fS�;ɦ-|p"J�sA)	�����4AMj�,�7?Ty��8��fȘJ�o��S@�4�u�/ /��i�4�������495��3c;Ҿ�:������a''��,>�:���;N����u�����*�(&�'ɂEz�"�	VM��\r�""^�U�g�1l�}�i���/�t:.���~>�w��(pR9�Q�c�n0�M���.���P���V#���:�Ca�Ór�\0.ʺ�ͫ#��nS(��-m���d	�=�ĸ	��b�y!�:���������:M��V��<��%���9�K;6r.�%VŁu���bU��C=�9�1O��l7L��I�����G<)�޷�������X�w�J�x��JI!����-��fJ���c.h���uAfԇ9%3j��������U�?0�����+��C��@�a"���0+@��by�0�\�?o�ZqϤ1$��	��	�d����ʤ�Y�9u��*��B�Qٰ؜;Z�m|t��8F#-���OL�% Ӓ*���I|̚���q�C�e�6u P2xS�!<����N5���1���ĀYl�s��!o2�=��\�1��k�� �'�cpNg�2�7��e:�#	's�z�xǬ�Uqe4㿟�W���9J�B)�n��k~w[��L���|�+�Th��:<x��-C�h��'�$�w�z�]�Ƨi���/�^x�7_�#B:>bEMoH���x:DCP(�����x�΂�^�+>��@��:��gP�&ܐ��F�FK��aD��o� ��)N1j�zf�eJ� ?��|���"�%(?�f�&�D��(hQ���ɳ�-��Ϧ}t3�Ĩ���a�\�8\�
�J����f��V��\Ɯ�sd��)���ܾeI�B������{�lZ
��P~��R>��P�Tq��e����-���QD�o��J���ق8�u�(�*���H�t��Y�'���٣E��a����P���$�"��%B�ՙ?\�	��%P.��\����dz2�>ͬ���ԟ��<�	�}�n��#a�W��:b�_�N�p���ML��d�<��C��i0]_�E�8���;+�f��B۠y��f�t\�u��.�[D�B�$���F�'iB�78/����v��O�j�*���%l���v!sB.��S��#<��Q�9��PYS#�N��4�?� �$�eE��y�z1����<��S�����\��w��mH+jE�g�/�!_�av�~�my��-k W�Z��-��wk��6�Дc�z=�Lw��^�fuq�Z�*rM��+�ӫy���a�h�/*X�5�Qe7��G=�!���C銤��T���-õ�9f"��F!���69����N�51�(��U�bͻ�u���+���Y����~1�'&tCf��Z�����0ҕVb)tڊO��� �,���,��N7���'Y��l6�̀.����S��Q�M�3Q�=�F�h${)���g`a�g�ٜ���jV�,���d������X6�X����>�QQ��e��|,�4�ܐ'š���Š~��m[�{t��G'E�|d�~����*�JE�?�mK�9,Z��h�0!fA��zfJp�gA7�?��Z��.c:mX�m�4��,7����yM_���o�p){�(ڳ�����~G�Y@�_�r��g�>�)gk?�E��{��9�;��!;�롯8�}��u; b��.��|(�:B��+�X�P{��Ƴ�qC��+��o�ҭ�]w��u7��%�t�6<jz�8��q߳-�qpn�d��x,��!]��@�ҩb��3�������FuR�I�_���2�(O� GS��Q)d�/� �����	���4G�(���	��j�3��"�:}�,f��4�?�;V���q>$z�u:p~�H"z�21���{.���� E�W��$�4���
u=p�9L'L�~��R���r��>����E�ǆ��xH4i(ie���&�^'��B��R@d1��5�ƞ����SZ� ���lWRdJĩ��N[++IdĆx��+�4
�"��^���.��W3��&��\L����hq� �<�@E~��ъúJ�D�^z�9p	(���$��l����ݱl�͝R^Ƹ���gb�u
�K3n�ʗ�kE'u����c����op���`�I-��%��M<Q�Z�E�����<QJٌ*�F��/�K�@��T+$���?����n9橽J�RZ��q�P	�p�{��{�e�$wX���Ȥ0ŘN�
�c�-;K����+��otc<.�`
?���clr�3B����ZP�ʞTX��>7�P��\��g�G���p_ �&ߖ(-:��u�cv��B��ӳ��d!ߖTZ�;�AȌ2.l�Rr�v�kb�`H"9�a"�wsa�I�A|{V��r�f��E!M�}����_�Tq{��C���,`�1��8�mߢ�����V\�&1w@�+�F��qB�7yJM[#Т���z����p.��N�����27 ��v9T,������K���}珪�2����u$Ҧ>hT��Gy�^�V�(��5d������9����D7��2?Z���n��j;I����5�]�ϣ�FS�@Qܮ:���7V�ҚoVor�&98������T�x�G��Fo����
LJ�A���s!z�I7z�{����=4�/��}(��͟ݠ�,h^��=�� �7�^ҭ��[w�BDR��;�`]Ԩ�f���7��1�N����V��L�eØFti:�Ϗ�����vXY6ǌ/�f٨��v�b5e�:y쳫�4B�eT��H'x�=+/��=`Xn�$� �wo��07��7���H�<�9a��Ƹ�}����R�o;l��)h��̗߳��4�Y�wp�� %J�B�r{x��}�-+C�~GG#���?*ѷ���WIu���"Df�� 0���a
��4�͎n�&�<�����=e��֎\���n���(��K��{�tA��|H�ql?R�>���"���ޫ�����'F4NL��Dls�ʗ�|��*��ɩُ��?�|�P��=�'+Gڱ�
u
���@IA� ��%%;�Ҏ�ӭa�FcAY����?_���z��Hƫ@:��6跳1��E%�B�Eh��H�b��?HO9��pT�5Of/����U5x��w��,��ͯjJ��@"K$e=H��n�����sY��,�	_Gk3�Y��M�6c&�	����Ͽ�����t��$��؎G�[`g��}#�V�ow}�X�G� X���?@𺇳��GjðKNߙ�K�
2*�xf0.'�W`ԅmޯԮ�BݶN���/A��mS��_Y����&���Ũ����i�,��9+H��
I��Ihn&�����'.��[=�� ���g����pn�Z���z�>�bߜ\�cZP�����AU�i���Pّ�5Ӵ��;y%m�l+(Rh���>Jx:�B
��25��TS��3�I_�Ϊ`�%��wa*)��Ȁ?X[�8���{߇�G�"��*F�.1z]a�*}p��ScE���I����L[~M�n-���d�{+2�Z~�8}v�>���3��񁷐9>k�|1�cl9ͨ���/����FJ47pN
#���IE]� ��y]��������@�g:!���;��7j�o�m ����$E��rkv���D���k7���=uȜ��y��T�sR���NUv,��j�pM�v��FM���9��G��5���1�������f�'���.�1TL�_���BD{�'Ԍ�jT��	pO\΄�{�h�ˌM��mZ�=��!�t���R�O�iŨ�m��3�b�N�w���9��� m�NGH��� �E��e��ф�{�f�Т���͙^���E�� d�j-;��4��<��t!OD�G�4�%�|�$��%���~�n� ��D,>����h!��4���i'��I�R��p�Ybܷ��z;�-��#n��{@���^y��?;�����B�ԦaV�躟@~��?~@8��C�e�-��Z��H����X�P���R��݅T�y_.�7y8�������L��)��Q�ğ���yM�����s��m�T?�0�^�[z}�B)�A]�^�b�ٜ�6u�	�WCa	u�Y�/;��Y����k�D�<��lw*���+Y�F�%_<ц�Jv),�a6�l,��X""O���l-����	�f�mW�K����n��65��d2T�^dp�,�S+��jVB�*r_Q��	yP��b��d@r��G���Qd�D|�n匃$�֗��D�'���	֜�Iƀ�);ᩭY�=���>Rj��fi/F,���]�$Q*L2�,���O4L%�;3���4��Ṱ�Y(ǋi�t��"�w�h2�k
;Da�~���%J���9�Γe����^Ey�3%�̄zz�3��	�S'��%�= �K2��o�fѓ8-��I�`�������zn�4˒�R�g�캕}}+p��ڳbmj����G�V-$."��ɤ�M����?�K��u4
�G��i�/0�J�1X��Cmu������3BXG��e�X��#����&K��O{[��zmO�w�߬�bwLC���}}G �L�tEe� �]� j�;��3*��N"<t��&\)�b:���.�)UCD?9M3z���"��
�`�Nd�(�?�Ճs���3l�i\��	�����>V��X��M+ocD���S?�E-����|�~_(t�`H��4r��az �{���� O����K�ы�LH�D6��7�f޳�E�e�_U�f�X�Ċ]A��h��ﶌ13v��F��(���4
�ϋE�U󃼎�@��1����F�=0�.�)�Z�����;歿��u�C�E�7��e�ڭ4?�[����f��c7���gbkP�|��,������\�PB�U5�}I�!Jִ%2K�R���K4D�S9O�TӞ���:��Z;��H�F�8�tA�{��͹�ϋ!�c4�n���q�q��;gu.R������9���E��l:�׉l��$�3�N~�E ϻ"(>{�^y�L^ȣ<��Y��t\���Z�D7�1�Z��Up�Bܢ2�=��j�+�I��� �����E�d�q���ȮBs�dvEpt֨��Ȁb��#$jߥid��<q��1G��*v~�%��H��;����LR*ZA�z&���] ��'� �c�<Ἕ~��R�}�l/����b͂��!�x.�r�,����v����8�[)�g�ج�A��bx_��;�	qQ�߼���iB�tn���j��6��Xl_XN���iSX$���Dv��>��C�Y�����; A�M4��}�0����t;rk�-՟8iYe�����%W�;В}�4*���~�k���'~G ��x~����2��?�{�n�dE�"��\qd��	/��6�?�]��}	�x��=���5;}�.e�K�WFz����F(Fݷ����B[Hd�{4���;)=�������w���<��v�Z;(/�4���{��*�������|r129�Lq�����(ޣG�jp8I�`G���/z>_���Zo��9�+����Z���]'XӔ��Xt���yd�]���_B3
����z�	t,&�+ou��\�H<��&A֖���Vo��팚4�h�hҬܶ�Hr[���X�bҩjx`J2:�t�,������컹���\l�r��ow��`
��@�q5�e��B]�������"�,H�e�6ٯ�&`
�Ys��Ӱ�9?؃k8q �9g|�E�d\=	��Y�M5N���t��<�`�]�@��G�q��&������Ke��Zd�s�-����z�bM�?/[�p��3�?�&��%؛��*�F�|�B@�/Y���~���EQfL�*\{\�'�x���i�Aܪ�5�ɍ5_���#��Y�Mg��mk`.���$�P+�pRpoA�!�S�R���)�]}OQO+t��\=� @rl���lYq���AC�UՠI_�R�{��`Wt��h/���/Pa��3�mJ����CD�̱�?T�"��K��Q��E��b^�%����;x`�h�_��č���dxfZ���	�������=3[N��J|��Rk!�-��lR=5{@k���؉�+d]���r��G�e�����{��k�H0W���<a�y�ӯbn8�&o�ZN�\��)�e۔�)؁xvBq�i=��TUE���-��s��i�9Z�4�L��z�'�^/c;�]�z<���ybv"S�Y	`�h��i;{��:�m�/�(;v�Sv)����aO���
�����-Q]�j�Q�=owYk�Th����*� g�s���	�q<;��Y��z�W�eį�<s��.d�}�C���j�6v����׾��S���;�N�<�oG/��\�c\��tL\I���$<� ��r罱(���Zt'ڂ�g/3�C��'v�#�*[l�jJ����f�ƪoKn���,0tr2���'�?I�'Q}��gh��.����#�����|#pL����!��+L�&b ��tSL&����u��Ye��2��F��jZ�����dF$H`�X�'��������?�|�9iњ�ވ_Z��G��Km��j=����gzM�/FLK»T&�L�s#����)>��3��)%9�AD�Zw6�S��~�n�")MI�.��vC����)�����]�O*�>Z���P�0��:���b����W�Tα�LFQ&>t����T-��i[M@�.�܍�e��+���OD��x۽���~	���P��Zp����ȱ�V#9yN�C
J��N�&?�=��� j�|Z�賥�a-����C�[\�'x��+�~����f,�s>%y��UK�I�� 2��mXks<��3�*b��ɠd��h(j�5���!_��V�2a~��菥���	s q,��g> �Hl؀P�{ �"D��f�W��SA &�g�+��U���/&�K�����p�����+B�$NKx��   !�(��e� ҡ���	ϱ�g�    YZ