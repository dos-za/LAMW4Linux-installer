#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3874799723"
MD5="5226a8887aa70a68191b09558da86826"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20736"
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
	echo Date of packaging: Sun Jul 19 02:13:21 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j��}u$���.^�d�ȅ�10�P� �R��l�NVoВ�hH��0��h��`y�V�%G�@�O�G0��
�"�{]5�P݅��}��Db�M��
�	�㷟{�����b�����:o8�<Q��D���Ui�	[�
"�?[���Q�$��@�Ͳ��!*������>2����_H��:#!:�ш63�_c�E;��u8����˒9L�XG\.�4�&m%��X�@����t���ހb�@C?pK(P�~����O`�BR�'��rW4�6F�B�X&��D����?�AiJj�����X�|g�z�2Q�t9�1{ܶ������h;�Ζj0nA�䷿+�7�韃��R�0"J�vaS���!u	���gP��1玛Q��C��B�u�k����A���+}�� 
�2�u�)cPHmm&�+����RmҪ��l�!���ƾ�$P=�$����³Ms��#`�}pO}q����<I�l�k%4��w@U��T�C�J�"�黩v�'�`<!���q�YSS�\+@U=.��g���_g��J��P������^#��q�H�P3��J0�޶�e��a�.<_�ߜ\��ϛ��alh�V��t�#�I;ȇ'�	ElP�q�$�U�YR10���F/Ԃ�
��䱼l�$�7�iBN����B���\D�|W?Q��G�mMD�-3gUx��`J�s�M	�bT�����)Z~�n�O03|r�������T��P���$:�CL���K�8vJ�2	0�Vt�eK6�=�W�u&�tJq,�N@����^BWz�>������,X�\硸6?8���o�Ƹ�\���(8���@��+w��^�{�r�;���}}����PY�G�K����F�5�K�7@�d����
�L#7����E���j��>>>�fT��B��>�	y�a� hR�#d�&����P"������Ѝl0�ۣ���� ��p�����J�F�r���x�v�i�8��+>V�	��#�"c9��@:�ϗ�w�@9��ѷ�U�/t��X�Rf��b�k��H`=4��k5f��5p�i6�W#ܼ���+�	|�����Y�ڇ��Wa6�:�f�ȧ��e�����9��>��b�*mӕ��'��G�q����*0��8O¨��Y��/�g��%��'��M)��Ɲ�hlA]U�ŋW
��([O������}B˅�s-!���XR�A���ʏ��x��@����M��5.v]��&���O��m����(�x�4wx��@A}�=����z
eP��&�T]C�����I���_>���	==P�O�a�yVJl�͋�b2����b���]�u��O2%n1|F���H�͔[
9��m�O��V Pڇ�IW3v�X�#'���z`^C�,dj����Cf�o�c�}���b7�����[Z ��4R�2�i3����!|-p�?�'��y�4e+�oD��r>���>ÚX�WA}�f�'�!"�A�"]��9���6��x�̧͝�Abz���.W7�C����.�&���R�|$g���(Zw{��5���(m��K޾��?�l�'���΃��0�o��s�F��ƀj��>� q{���K�RE�$$4vIc�ث����v�P^������sg�;~(*#���x�N���q��� 
��2O�
�h�%���"9�'3��}�+�Nd(��>dz�R}�mJ?[�p���((����g����o�_����"���%0,ǸWrOB<�7C�IU��WH��(xyt�x�R3���~G<xd�ᆼQ��&����3w��Dj����x�	�`���	�֓�*���J�U,J�a�T�/�<V,X��ޅ$�f���g쨊���G�!����@TZlBR6�3x
Z�m��s�Y�vG���G!����,������nmQY�؂��n*!���7��E�;+J8���Ћ��Hi�x�pqu���S��6����:������*=�����ׄ��%4���Wx/�0[��^��B�ӡ�;˜y�05ӣ�p�5 �[ZxwdzstH��
dGd��"@���D�	@��:7��ތ�>�����ܷN�Q���}$w̍x�Ȱ'\x�z��0BN�!LQ#�Є�ƒ�d���T�!Op����,G��������9�	�s�5��5GQ���Q�_��+�����V��-�����a�K.��_4�e�i=v���! �M&�ǸT��v	%����� ��C��߹�������T.����6��rMU�_�;���!H�o�9P�_����j�3�R���uq��������Ld�����mU[h��p���G�>�����ڗ��1�UA�j���#c+?��� �X�q�3��(�?�oȠ̫%g�U@�?�
: 8��W6-���l1�0�ezv�H	p��`_�e�Dw"��ҤM	b���P�l�TG�9;��!������8E�Yy�q�(�+��uBG3o�O���A���7h�K��)"N��1&@p�]�b�Rzɐ���$�3݈��R���S�%|�(���>L�t���}�E��q,v?$aR�Vs��[^'�L��]��`(ƞGK8o��rWA�R	̅��K��'q^�W3�)�nj�������fCq�N�����"(�L�p�\�Y8����-̳���o{Tm��$��!p��?3_�7u�W@�2.O% �s���O�Ѿd��#ǰF�&�kn��|���˦<K�Oe�b��ڲ�À��
ٽb�3Ò�`4�)"�%���SfB�6�O�!�n�8��g.R{�P`���15��	KŎ�ک_@蝥�[���P�3�r�p�/�'U&�3�k:t�6�uVɏb�t}?Y��턤�c]8Fy|xրo����0���n�5s �z��K��A�QKzT*u����0!K%��(��خ]���F��O�c{n�3 ��9�O�	����4��|D���ӑ]���xo��~KF ֿ���Nφr��&7���\����:W^�jgY6Y1+La�_c�{�O=�~��al���ÿ��\P2��ˣU��9�V`�g�\�5�#`Ɛf��BO�ԚgO!+ۖ��0ߦ�c4�X�x1̧]�A����Os��&�	�ݵ���=�ro<�hZ�@e'������܁���Q�C�Ə��ɕN�z@�'�� Kr,^Y��/�D��)ʂ)����&���T=���;�=����z�/]�ڦ�#."�U��@~9�����7�PY����6&B�(yC�V��X��C��c��S!~؉
b�Kh;=�u�L#�Z��OufE}@)4�g6�F�F���g q�(jz�kN����M�P܆�g�)������淀"X�4X�P$H�?�%sg\��f�x�Js������魺��vm�c�a1O��awaE��$�ŶXPʊ\�Ŀ��9-	�I���7��x��	zr�#��0���F�M�`9�c�&B�b)�乄�^��:f ۯ���M?�v!��T��4�6&f�
D��Q��P�"��n�7�27C��HƜȔ��������y��Ъ4��A"�f�V����F�x�����,�'�{X�SX�f.���� ��K����&����ZC[����*�%f�u&�x�)7�C�F*�6wi��!���.�3�4��2|�K��y`�ۊDG�{}+���F�"�0�i��S������?F�?\���r-�R��m�Һ<�������"�#FʡQߧM�_t_e8�]�}��{��q�0��N��:%�$��G�\�r��@*$/H�v%��M�;�p�+[���"c\KE�:���� U�!���_�r��.9?3���^7,*�����$@W�������3�HĠ0�����ѿ=/E����#RNH��MP��s���� �P�ݻw���]V�n@w="!(g2�c�pʜ��w?`u������Ύ{?9<�[�K7$H��[�촠��c�(���*�-=�͗>I��m��������7y�+YZIu*�׊+�PyP�)� �����#k�yG=sӮ�fĕ80�^�iih��-��}�P��d�.�����=5�,�U������"F�p��P1G��)��2	>�*�Jx�i:7�z�h���O�������2 5o��;A R/�(ub�3�Z��:V\�]".��{4�S��W���-Hy6w��5X�Sf�@������{:H!���s�߯R<3�)�6{�;�������m5�<���ݝR�@��ڎ�gߏ���ά��;/�U����%�~5UZ����&HM|��ux�w��+���ys�����������,7�Ti�dH%���E~�E�CJ-�2�kρ�ﴢM��afWR)�%��D����C���X�פ5t��Iw��f��v�ۊ���N�/��^-�����{�jd�8`�ne/z�wd�j���27���oe�7�?�W9��_
 j��v.R�N�'�JfB����\(=�_a��>A\aq��<�~�R�����엛���y���^=N>�B�R�V���r;<{ 4���}�KU/5�D>Ti�c�����r����X
�?�� �w:�7�9N5�VH&�d����f/t�BA^+G�@S����xQ��u"�F�y�fi'���ɍ����ʩ��A��q��[�9��<G�C|o��BSg}��%������}��N�!�aĊuS^(�q~,�b������y��U\%oxj�7{ߖǛ���̹��������d?�|�bdɕ�G"�c�!g���J���·���K'v�ɷ�q&�ߵh�Kʶ�9�n./�V$y�>�{)bG��6�$��w����}�]>v-���|W�T�b�<)��
�ѱ������R3�tz �f+��4�*K�µ��g2goH�w�y���À�P�S
��5lK����ō4�n��5�6d��x�g�o���g5�����ȷ8e�g{�L���f�@����I������j��VU* �z�*�䵡{�=K�>���� U�������K�"phnt�J�����fzٓp���"�Oݭ�	�N%��s����:,�IX���`[��$�oNiyE3����`���ٴ�&lɚ���	3nc(Gw�NɕT?�3T�)"(f Y�zbgB2]/�X"I�q��Y�S D.���ݖg+v�^7�'Y7�*]H�.T����}@L]���]f�������;}U%�����LTfR�[�]�0<�Kv[�/��*���`�P����E�S��.@�����KU=����$J����_҃�SD�o�3<��5p]�72l�!L�On��� E�	��y����!� 	�:�Fџ�= LL�C8��7��7��~C4?�!��Q��������AR�IN$��D�B�geUX3xޗ��L!*!/w���8c/Q��`���R�e:ɢ�c��"wzΏ���8���L��Ӹ/�"�Ѹ�K/ܞS(�ƺ�.���b_�M�)�u��7[�|(ad�E�OT�� [u�?[�� ��o"��fh�F�eȹZ۫Z΅�� �N����6�*�����L�,�S/����
ߪ>C&~�9ǉY��c�*oy8��]�����kס��si>�r.���,^�����9��x�
��1��')Aa+[�Q��QجE��Ͽ
K�4ī��r�Y���V���CJ���ӭ���&���d��a��k&w�h�E9�%�R�af+�4']j���T[<9�݃���S��vɬ�����y��s�U���$Rf�	���}�X�$�`��i�:�n���E�F��_�-$*ة8p���~���б]�i�َ����[[ �����!0}�9?�_G��2�寊<��4�TC�_P��l���z¢Z�$�{��V�K���O�h�����	�L7�HJB�C��˸l8��V-�ei�uo��Z�wc廸IK��0�\P	�z�����To��>���A=�y0� 	�o��B����5��������+��^���*y��{��d�E������Z�� *�Q��+����j�m|Q���1Jc��.����Q/2��t�x�9|uߚ�Cc4`�R�2fUS�cl���c�ӊ�%s�с(�q
�*^��U�N�Zڤ5RZ�1���Rb5�Xw��Yr�(����\�?Ҍ|d	��
mY7���m!��M����N*�+H�L��7i�lUQ5����q&M�Kh3���:%r�}��J��[�r���z�\��Y��%�VJ`��~�a{�1ﻬFo��cM�Md�O�,��/Q��$jی��ڟ|��^3�����E2w� � Wa�����-�V�����>*��eCC� 1��:�FC/O��c�L���O72W⋰���BJ�}O���E�Q���xXԛ��Q�d��s >������`ϡ-v {8�/p���.�]%�;��Eԩ�A���ǌ:��3�(�zʨ��S�l4t�A�������1%L�a9+ߚ`%|����J?�3}Βs��8��o�Y��q&J4��{��/W��u;���_��'��0��r�/ ��I�@����*0��a��$��u�l�#b�aOl�z%�J'<R�G��i��:Nv�:��ɯ�Z(T ����d/7��58 �E�N2��j�7Z�L��i����_��"p�c�]�8�U��aTd󓭰�.T�'u�MM�,��C�ӫad�I�Q���ǈAc�"�����I���H=�!|/����5_��.���(:E1� K�{���5e��~
�"�U�1�hQ�i���m35�=J�,��u����� �$Mm��`t����i)���3�(˺U����jqY��i+���vޝyj����ҪC��N&+.�W8�T��^���L����߿sf=}�'U�CL|��!>��tG� ��p�&f'��ի��0�j�0g��M��!K6�G���'�ZC
��i 9��O���R6mB��l����R�%���}V��I�"�$
.o�i�va3��{�J
�6e|�>�Ez{���mo?��>�����R�z;���+�M���\��q�1IzTƈ�Ww�aP��5<�lt�
+ЛT�}���@.����r���f�Č9�}�Ɖ����;�\Wvq��Lo&�>)v���;��~���w���I=����?�����kL
���З�#�k0�����A֬�Ѥ\4�Y���e\_**���֌��HV� �eKEr����ϔu�.��:������lRZ}`E�J,��w���%�~��Gr~��y������/˒t>T�q�j2P[#��R������)���f4�\��K��{�!LFȻ��/t7gn��R��{~eP
��T����B}>R�Ox�����cZ���b�9a�ݴ �L���9]F⹓�瞓�8���	������z��@��/�� ��#e���pDK�7)w3�Pw�,�y�Q��hB��8(��6Έ�3tVu�Q��}��/��g��3��W�)>ǵ�܉I��h�"�nY/?yʌP���๙�c�v�x��� �s�ꂍ��;4�u���/d�x*�YS☭�!��-��l�+�Z��8
��'�v�1 �����0�����3�ZiS���P��cNϩ��e�x�ߘp�(U8$�&A���!1'x�A��?#�O#H�3�SDs��YF��U,�_���k�
rEA�Q��/�z	O��0���*z<�;���gg��.���c%4��>����i>؁�^�T��*�i�� ��/D��2ɗ?٤��,�h3��L����W�@Lˇ��a���R��l����YεKx*�n`���U�W���r�qM}�ry����",%��ժ���^��O��	�v��7Q�*�Xv��i�l����\ϝ�ϗB@��q�^`�n.��m&U @]Ԣ[�`I*�R���&��N�e���6���&��6QK
5+��ai��	�YT���46R���c+�2a6���*+&�P��2�X��C���2�r����e�gKf�q�&SjeϿ"
~�W�a#�;�f`�d�ÂM�	
d��^�ChN�,��Z�'G�ڳ+@�`�C}*nL?�ůD�"��a���'���SY�pPo�/��uR�dO�S�
�ˑ6���6+gђ�GO*$���̫�'m��t�(:���\B2S��Zs�K�5��6��'�u����Y��c��VW��i�<�O����L� 
57l�\~�n#��W�	=A\�� B&��]�M��;
^p�a��5���P��~5*���-^A����evsO7F�]�b��ZM�����h���:c��iۉ�#�n̨����>g��I���^�5������" �� �C^B��ZfS#��!�O���A
�����P�L���^�Tr�I�:��$}��ص�|�;�����	.Rc0d[<�KQfq9z�#):#��#��d�\Fq��U^"i�����Ht��/���W%���Dǰ����c���<%��UR� �ѭ�W1bo�1t�%:kn2B�����K��L�h��ij��5,&_V������)U��p8��{(����7��r�6��YȢv$	�H��UU`�jF�h�HTeŋ'���CX�q(驙f&�&�v��H��x|��1ѡ���a����߮����&��]Ie`�y�U����'H����[�Z��!�1'.ߗ�s� 	�fs��9��-���S��f@!��4��fd6���m��1��C�ĳW�U��W�q]�����q�q#D���A���hؿ$�G��x����a<�H�1�=�c��*������F4uO�^�!D��(��p �����"�N�y�,�7"_��sFK��x��\�����~zv�S�C�:3]�*k�둊���D�typkA�ɾQ2�A�hrbC�E�� F�U�܄�d�O��[e-Rp�ۥ�*~!n퉯��a�Ł�U~���N�N?m}/H�T��{�q; z�h$�4������3.��d�~ ='��w���%#��1G"iR�9����zq����9�bs18�L~+�׉���ϫ�	���V*Tj��΀�xs��KJ��T�̧A�~�I:/iȵ%j�'��k?�@|�~���Sq��qz>i�:�3��
Z�s�����u����AȠzs�?�fE��)�i��n�0�U��������qF��G��y��{,1��	�t�.)'�N{���$��N6Q����$��X���\%C��m��ok|���(͠�@�3��Oam��zN��T��E�a{jDv��f�Ǫ�A~C%�}���Yi�0��Zu����ǘ�r�Q������(zZ���.�}���iSBn�.�Q��,u��-��ׅ ��&bTt�I�N��fJڤm���߲4j�V,m��EZ�[��3uu�]S�%t�F��F�V+S��X����f�m0�H�O�4w��5���mU���
&'Q�*�1�Y!�<��
ɠ�i,9�j�������l%����w@FF��Y=�v�m��Мp�j�ˈr�W�0M-֪��C�;�|C�7!��.M<�'���i|�ӿ���+���5x��R,�M�5�U���S��m�=7aR�~+y�E�U�@�
�$=�͕�����:2"�!��S�ex����ʀ�e��==h�n�븭��(���`.���:$��v�흐�� 8��3<i�` �4W4�_4v���Gq��fk�a��p�z�lov.��:��z;�ہ��]��o\���3�A A�����Y�Ԃ�i����O���:���Q�F��6���_��u�YZ�լ]�NY��R�oc9fȂ5ѷ���M?�b���:/GN`��)���� �<�<�ջq |��b��Ω�s�c���!���Y��~(�|�6��*�~�ST�Ν_� �6ߋXt��d�7%��t�Uʂ�3���V-�8(��H 5�O�rV��(|��ͤ��-�����&��[)>��{T�uV������5~�&�XeT���MRi*e���`�8�_�=vf��`�ڏ��`dJ'b�` b 3m1��*Vf��~ZF�X� �H%A#b]W��q���ϯۺ��I_{�U��ї�@�Ț��"|C��9�Ƶ���?�����O0k�kЭl\ڐviTئ�?�K�B�Պ��Pd/8.� rFW���lÛy2�	�O�G\\�4��*�m\:�r_�a�S�I�"L`Ͷ�m�t�K�n��SZ�����T�|���ruoaնQ2�T03� \�����m.�������4��zȤ��l�F"�`�0����!�y������>�Ʋ(�o��[۪;=Iߌ���RuR}<s�3�g-��"���G��杣���v�A=
���ڪ�3?a�b�+Vܕ�~Dy9�0S�NZ��JNIy�6Ԫ�ơלb�As���[4��~�8�jM�����^�+v�[T�0m0��T�� ��DZ�$eo �\�ʊ&a����o�`'�5+iwh'�S��L��eg.�F�rm�2�����M�P�&څ9ѧ�;���/�Xb�-7�jV#i�B�=����f�����f�
Q
d�/�_��1/G����fW���O$�i�~��/Vk��1��m+Ӽ(.c��uk+9�����|��BAP�����g�/ڳ$�	G8qO��f?l���T�W���+ 9�%���]
J<I�o"�Jź�k���I�Om��)= �e�6A�:[���OkY^Pġ�ϒ L����?`��:��h	Smu��9�`���?!������
���i3�ʲ�W1�g�Z��;�R -�7�>�#�)�.j�\Ҵ��܇����$(�����M�d��5Us�����m�?�Oi9({��:|��n��O���(^d���Hu+�J[����2�0�΍ݭ����HC�x�1j��S���sV��z�}�I5�h�-fk��컘<��|��f:�&ŝGT�rp5�}׼�m�u��(�f��z_${��n���6X+�ޗ�����]T�Rҟ��A��%�3E�����d�5&7�&%0�fM*�N
ۜ�C��R/}r��&c��Λ&���T�,���=�����wf�E�'�4AK�Wz�`��I�ٯQ��xr0�A;Y��T�Nk���>g<�5�̓�`��F\���[����CԮ���ϯ-[n���(��X�eɱ�M���
p(�f��+�O�����=ٽ��-usK$��J�Y���*���؏�c��\_���"I$v$cvY��
�,�9;�/�������h-Kw�~ș�lq�m�8շ��c�o#��/�:�,���,L2�B	�����і�A?U,d����~M)G��&��o��{�����{�n��s�T�7�U���˃S�-����^nOa�)�8_�=x�˫�b�`�s��f�\���נ�/� �����8]���c���w`��a��	�<#5�`�H��N�iM_��xj�8�g�	�r/�'�Rs?���+�c�w�xh@�>��d�h��c���+]"����ーt���}��Q��#};��֬��#����3T(���*���Lo�u*����e�g*޼%���4$k�*D`�7��2	+���r^�c�_�h�[��8�W�o8	-���q���:��JOC��^Id��̨ L'GDRѤ(D\u������ `��ZD�"ʻ��0�C���� ���ݷ��j��~ΐ�U{��,����aXFW�U��0��9�g�C�]��4U%?a;�t%���$�aɑ�gqi{�a��q���u&6r"Ag.fS2?mj�����_�6���9CQ��	_%_H�jg��1D�P����7�\/=�~���!}%��z���q����\�}�*c��R��kt3/�7��_��#U�Dk~Ðu� �h�I�O.��SIS3��QQ�Z"{e���~�J���HmL
�<����##��&�ֶ|DInv�TN�r�*b*֍�n�
AZ��Gh���1�������{j�.C�#^5��0^?r��]q�;3b��%� ��Z�ٞ�i%r3�f�j�]Hj)�j>�W�ȎUv��-@�Gu����	�n]��9e=2��>��D�fl15��f��e���1���d����b�IcrHo.����;���r�v�+���4U�质`�T�?u�+��Hj���$>��c�[�S�<A�0�G8�\rώ��]�������D���J�Ϋ6ĥ�]��րt/�9$�
��X�@��yG�k�5���{7n"�.��hs^�靅Qsh�n��V�\�(���,�(�ؠP��L��{��n�*}�t���?�ˬ����	���Ƃ�9t,�9h<�q�vk�m��9�qn��)CFU.> \�~>���Bi��{�u>CBQODY����O�$�[�8�ߚI��u{�mr�i]D+>���U�y)9|��2���F��H������6�A�� <i7�8ʫ�8�D�"8��Bx\Mf�+߸g����p����}_c��J!���0BPq�N��TCH8¾��� �x+x���+j����s��%�	�}E^]���aJ��{8*����/�d~eC�HF��jsbV|�E(up����>fE��S\��"���\,o!����:x�S�ъmЁ-��������+N�=�I�6سd�2�BA�����I����6sC��p\�m���M�C{��x�^���]Ev��G��N�	e�#�B�� ��`]�_�\v��t��J�t-|ف���Bl��畕4.a�\cg�<F*��� 8�fn/G��XF]�vC$3ro��G^,��_⚴�����;h/��B]k2���&{��q�%d�yg�����BgS]!�p{o
QV54ھ��V�)��,�Ȉ	��8֊~|�Z��}3CLg�=46�"9�n6�sLe����f��̀â��%ӓ��'%��s�>���������0�!?��s\C�z�k/<ќ�X�
��V��)�̬����z���?�r�ޟ�Y��~+#Tj��@[+k�ϲ���� ��,���"N߲�/��r��)�����_�%	L�{!���L>%o�π�jEqb���D����#/�x��(56bVb��Y
=��'�����͙FPZ� T>H��%��,�i���V��WFO�|V��&Cδ��������D��������,vV3��3U"�
�r��WV;��#���%<?��Oo,]��z�%�H�7 vb}����G59Bi�����/A&}�u��L	�8�nq��)�����+T�p�falڴ�&T��?�}H�4�N_ؒ�Ԑq��7qz]x/V��7ȩ�׫�,�}���RFF\2L!P]�-N�iz�r�za7��z� �1��ME�@�J��iK�?�'�Õk�+ �V�uJ�Ht"���e�O��:�{���Ap�㧊
nަ�I��K��O�_K������}��^ރ�]{�FkL�mn��J�b̢&�<��]��M�-��s=�x��vi2oBe���Rx�2��*;@��{�ڄp%�;�iog�1���L�"��3J��t�x���<��a�����Wc#�%��%�Es�HLܙ��4d�:��d�UU����tz�Υ	R�Ͳ����4X��򮃆9�qΰu��i[�9�QK�$�H+���� �jo"@��si�`����l�}UpϤ�����z炫�n�/ı\z5��1�<�x���0 ����6�_"_��o���4B��z���ϴZހ�v��0�K&��8}l�S��.�"!S;��X�Nޟ
:}[m��R12�]�n��9�FL˺Z�B�vs΀ _zn�l�F���<:�����[w��<-�K3c����ˎ~O��*��@;��\7oV���C�D��t�W戭	+��k6$r���p�#�R �ϥ=Nw7�d�dŉ�����p��+A�Y�W�*EB���K�hy��)�Ǡ��M.R/`GD*UB�����L^{��9��7d ����@��ýp��|
QOH�O�.5ƛ���HONu0��&ޮ:�@���d�wR��~	r^�A"��/s�K����u1��*k�]���>�uL�V��u�(<�>ƺYeX>"�����W�Ss�|N��T�i"���s=Q(4P�����k_���lZ�ğ�8>�4�N�k?��(�����M����.�]<$�k�Y?Bc�d�u�Ȓ�"���si%8���(
X��1���j(.;��-���ã��L���"ݓK�WM����k���2b2e��T8�]�o1qar�6�G�]joGJ���R�u��vY�U^��+;�X]��Q�����k{�D#���q@����oKK �P��� �@2'��A��n�֎O*��MPN�8�H��A�kH�C�g �{O�j"�(,���g����@�OI����E��k~�/���7#�]
��'�@$��b�,Qu��}�/H����lH#�p�.�/Z/��L�{��|�6��"[��NZ;~�M��Fk}(�7�i���?��ca�:5�	�~%�٥��$hd����R<y$,��E	���W���Ѝ�*gE��I�R�D����(��e)�)4?`@b?�_L-�@��@\�֠��۫Ȍ^�EaFu������ZK�(.lo��J��!��'����&w��|i��3��H�'D1igƌ�I�T�S��ۼFf	�O��Z�� ?y=o b6�e ��@�b�y�����5.?~����ab?�9w�"Č�_^:�-��E�cp�I��c�b�.����¸l�E5���~�T�zi���ӀLyQ� ]ә�W.1����\�Q�q�e�m�ZrL*BEE���+>)Vc���k>{6��`h�oҨ�;��G��!=AyR�j�k*���`�,�f��$ˢ��ƍ(�<��҂�%�/�Q`OhQa�-[����W�'���=��{~;C��K_r��=�{"��G����l��-�����1��y6g�)�v��?������Iq)^�ԟkil������:��瑪���ªEE��)��N��q޲�$�����N�z�Mk跥r-Y8��%� ��.�z����ܑ�f�+5��,���0:+��_-�tn+:��%�.G�x��JH��7����K gj��N�E1Q8���I���h�m�I�s�zOє@װ�!;�Ne�A�}R�������5�Eqj�	�&GhF���YZ�]T+/f�zlY{�a��1lJQ�4�e�g�F*I�Gl&ޅ7��%���@���h<�w�]'�ېc�q� ����H����Q;A~詿�5n��*�#G$��#�[`��W��2}�K{F��|�o����J���E�d�b�����n�� ���^,ń�����&�-ϐ���0�(�g;����Uص���ӷ�`s�MW+'��4Z,�l�9�Γ��W�ϔ�R�)�?�R	tލ$�Y��1�W��Za�~e^(�o缢�"�:��F��^�����_���C���c4CjG2�d��N�w<�Q���y>�_����H�&au6z/��ֹrH ~�I��%OU�[�0�m��Z�x���G1�"`�A��*m`Oa��/���՝�A_#D<��-N{YKL�b�#��$ot'�d��Pd���PC�i��$5�߭:�dB;�.9L뚨?aI�/�C_�)_iX��8P"4g��#��]P�м2�_sTֹ���W�Z>R	 �K/f%�nf&�D:�^���l�����`#���A��`d1؏���ԅ2 Z�������u{�$��\�z�J�8V��"|+�#��aA�� 6xAڑ���i.�=�(�v���Do�	��|��Fa��I}Xյdϩ�h/>����lsE��B-S����a�e�>$g��CM���k�l4��K���Gfx@ ��zM���^mi�~�?�|C�:����Cæq@��〩%<���p�+��@����Jq��gn�E��������)��k"EiC^��D�%�o�˿���4�N[���D.W�e[t�G��9G��_������`<Y.��L�3m5�6�	Ƹ]��ӢW�1<A��>�����ⓝz�	j�d�(C��!�(��<�'K�n�����Ғ� [��n�O�et=�JE���8��2��:.w�W��<�ŝ�;�6�e���ơe�A}ֳAr�ge����j����\���!D�Mܽ.�E�405�H��,��9C�(���ߣ�����A}!�-�)��:�\^L�i��:�],������v#��&C1��upa����&�Mo�v����v�2K��X�!c�.��?Tģ��*%t5
�1|ګ�<U��L��Ď�U[��R���VW��N<���Z��p{D-@Se�.��ZE�����F�: �=u#�l�b;;k�J�>�w��a�;�d}hC!�����\�M��^�=͗1V8�Z�gF]��/�����Ib��9P��������6.de`
s�:ȶ���:��+gi������$��C3������&rO�A���)�l�����%Y��oP��&I/�@A��r�[��G�	Ģ���=_Q���D�R���Y��45Q���<��.�T��W��;�1��8��Yĸ��hX�'�(�l�.�F��b�$}�s-��]���3}+5�1���!Qt��\�M�*5��X�6i��(��h�U�a�Z�yX�N�����ɞ�Šj�9��e�径̲e��W��s�ч�b�0kW�cү_�'��?'g�΢�А�VA�#o�A�f�vӎ�aW�I�-�-��̎�����n���]$v��9�����=��a�w���c����YPu�!<�;
�	i�ʪ纛̇ x8�^��Q���D�\���X��m5o V����iAj�+R��_��b)���;��9�0�vw���#k���쥏�f� NVK��w|�AOυ�zH���tn�:/�8���M�K:R(��Nb��b˵�@W�)%��k�)G��?�Ӭ�:��������0�)�*��D:�'�BZ�P\�d�/������ 
p�̗uPt�0a��Py�����<Jfek����T�~�H��\�G��܆�n�V��(E�ÌZ+�����X�Vۭr���;�R��W����|��^"S���ڍ��!RK�d�2�R�`坒��k�VAh�^�a�5m�����v�5��nF�&�\6~�+�Qo�9�)h�1�W��L(.2%��hٽ��e��Y�{��O��lz �0c�T��� �N/���v"�b������J/��(,*7�	m�<q#��p��9�x0i��D���s�-	N�����Q�����7��Qض�q@ �ƾU�-JA��&�q�"o��cr�9i��v�@��|V&���A�M.�����UM��4�\U6��׃\��n���Q�b�qWY�5ʳLm#_�80T9�9��,�;��(�	V��\�ȒA�K��_��@4X�zQ��y�i��eUо�EE�{Cޕ��	5�"";`]�È{|2�Sd
��-�Ai|-�D\���M�b�,Z���7V�P��?83rd �q�u��y�]�y-����)��"d�%R��'�es�1�x��>����Л����!��c���_RAӊ��֠���v/�AK�X��D��<�c\���7�5�<mc9���<a��������Nh�7({�=�'w���mW���츣��!�a�ZL?S�sh���O$iL�?�-�a2��KFP��5݃�Q��"�<e�:�l��a��Y-�j$�dfx9��>Ê;����v�w�W�̑���P�пt.��c�[<f��R#Ù��3��/�BT���<�A�Ô����H_@ՌB��9Ї{�v��b�Hv�m )���u���z���Ud�v��w;�����z��CE.q���0nn��W�J	#D����"��a	��K.4y��|�I$H�h���J�%����_"o���J���J&|ǆ�bd��p�)(���֥*��-��`��M�-ػKn/E���+��3��yO��=��Dh����Xf�F֑s=p���t��G��7ZE���e���F6<=���X�=2r��|�3��Ve}��`��j`�F,��f`���Gօ&D��(h1��$���WR�"��8���s��F�d���#�X�6��	�D���?�y:!���|��d�:U��Ӡ&��h2����tw ��������LXe�ɣ�ZD��g2Prw��&VW�)v����"݅3QsY�,.?.��?;��m�ǿB[�w���_ � �~���3�3#���ޖҫd]�t�ž���/W^��	����2E)T��^��
@���ש��po���v��*N��gK4d��H�<[�Lm����
E��:���1B-�%O�Ϛw/����`�B,q�e/&T{�6��t �Y�Ǵ���k/c/	�DvoMS����Y �,����۔	�3�˾b��3Đy�;|�4J|��E>"�|>�y�=	������x*��0�m-�w��ؕZ'GkC�M㼮X\�wV�U5�]��W}1�\�NLj����M}Q���ٌp�X�}�:^���&1R5�߯l%�F?�h����J,�,�-�(��6]ڏ�q�,S�~/����g^]�g��{T�2Yw�תhf��k���GE����:|2����0�]���/2k
�w�<;�(�GZ�my�j�;��q>�:�'��7Y!ߦG��e9d�,
k��Ș��2ڙ����`4�_fe�7%���-.޶2Y0|;}�ݛ��0�D�̃nx�:��na/6��Eac;��nɈD��h�	+��mV��
���8�k���p6)h~�$��T�.{�X^k�>6J~Œc�+�F�;���aeL7�v�A<jϧzf<��5o�-�<�c�>*\��U�x;\���HG����q���"��ߊ��%�� *D�d�m.M������QA�qvA4�!J[o������㗙�Q8�:�ul����Z���b��\!	����H��S�����M���aV�YFV���3Q.��.���'���aE�Y�$	�[z�Ki��)�9��6���k�å���(}�u[M���a�����X��R�� :�hS*	�ϗ�QQۙ�i�d:v]�}�D[X�p^�\��(dI��3?����������4��e�#R�7��:
���|�w��p��t!�ٝ#�c���M�Bf�Ì$���x2-|.���;�nJٟJS�h�)���CgE��k�xZb9�A`���e�1���������n�L�,�ő�"�7�P�1����tqE�����D�ɗu��iz�����-6	>����.�L���J,������.:6�1s�]�W��*��R�_�P���"�C�rw]9�W)7X�C�����9o$EH9l���4�}�<'uc\u7�V/����u�gy�r�VXG���K��z��Z�"���䉥H*w)AQXq�ܗ���V��/ܰJ���į�1Պ����7�	���G��4v�=��R���D���ÐE{�i���|��&��������H��N�|�V�=sBԍ�ⲗe_CS,���D�\��̛����j�烘��Q��@��?(�ys������Z��b�!�����j��	t۾7��ji�#8���j����˘U��D.f����%� ���`,��w���?�(�J���c�;e�`�����k|⡗0�X�F�,D�,��/�RI"�R�(�%��Xk�����ϧ17�L �f�[�c£���b����<���fJ3Y*�펤��>�Y��q����vů�z�Y�8\9���'w�J��!:�@�IkI	�O��:,I29���FސEu�S�e?�ɞ����}5J�W��|� ����V�qμ{�����J8u��u�j�2�즱f�Ǔ�F��)�<k�m�HbFLD�k��B;��!��vR!!�Uc;�̊�o ��̱(QY���<Po�j�B��Xo9�b����H�[u~x�,y��<��E,�*^<h��Ob�W��]�81ZL�w W"V�����'G�Z3��o�"�Bg�*��:�>�}�"5�?>�<��G���c��=�S��y!&g���!RO3�k������v���|ٗJ{�\��y���3�mw��$�������L6��/��cE)%���i�Q��*��jG���J@���pu��R��zi!�� ���`r��&�n?�%~曏1/ߘD��϶��
��L\��#P̉��{�3�\�b�AI���gl�y�c�W!���:��͢�̇����`G�I	�a�Xv�j�Ő!���*y�8P�)��-Z�Zc��:��Ib�~?��(�>-�-�� ����r��3 ܡ�������g�    YZ