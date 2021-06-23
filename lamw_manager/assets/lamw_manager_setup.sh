#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1275924148"
MD5="959932fc8a0db90cae3e269e13e84f89"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22988"
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
	echo Date of packaging: Tue Jun 22 22:20:58 -03 2021
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
�7zXZ  �ִF !   �X����Y�] �}��1Dd]����P�t�D�r�7����-mv���$��<Hމ�%��6Vh���;5��uڰM
�];4��"��}�A��]h�}&}�D��3i��V�K���?+Ǽ@� "8��Z
��Y|�"ݰ�f�J�lk�hO+�p�Q�T���MH��C�,w[�D��sUcFj;��No��o�923�XR*�PH���K+9��j��"�4?����t��Iμ�%�y^#��qi�-0�0�s�to�8}�I��2�4��l~�5���/����|4߻�C���l���W Y�8��O�w$�<�s��H�t�9d^y�)M�U�u��s(�`P{��^`��Nj��.>��~��]�\�㒏�H`O��L�d�M���}5q���%�ɚ��o��-�D}���7�ޤ��g~��y0����?#=k�]ζ@k9C~������̃�/��^�-�1��޲7�u���J9w߫�[�$��0��;����H-3��퍈rʶ�L�i?����e\}��X�Yf�>ڴ#I�#@]2��L�
���]�l��.��vyZBb��d��n�ӡ�+��A��橁�,�	n�wQ���S��aY����.��ǽ@�D?��?h ��ۑ�b$ԏ��Y�n&!|Ou5a���d����w�f&]x��Ng�^�D��#�Y�q�B&T��M����ŨĢw���G.ծ�O���(�'����C�W�%�'��Mt2��;�XU*�g��d|J᜷A�Oh˱m�0���ߴeJM��Ƶ����.��B�?�@����X�g^��(��8&��]H|: *�@H���p�SX�5V���Zr�	�ƛs���֥�����H��w^�E���:2ty��
%*P^>�����N����50��_z�rc�}n�� /�Vl��B���KU��jϋ����đ��C��v '��R �3����
�8u
�����Ym`�^H1CT> Ml��zpjK]�iQ��.�F����#"]������. �W���F)?�#5j�����XI��������߿.���Q=�e�[[�\j��Y��+n^|^�&t��1Hӆ�Jd�Ÿ��5�W�{�����P:��K���T��*�e���M��{�d2o�$<�23�:j���:�������Uj�"�dJ H�3��T3���Ӿ��]�^�X<_��O�I@B5���'���b�'�lx���l\����M�R��1ᚄG��(6��qw`rOW��k�>��ÛX�xMQ����:u�bt���P�X��g��3d�<R����; ��Y]��']޺x�x�糓Ë���g9��51n�����6��8��I�d��F�� 兂>�L�Se�B��h�T]3q�T3����k�)�44���eu��o){���$3=k
	y�eT*)5/��?��r��X'��D��{�1Wg"K\ɵ�S�F�Xr9 #Y�e3W{l�w^)>~�$[��.ɉ �K�I�b�?�MrV_��l�#O�c~xmN!�1�P�����!e�AHK�?&�̑��*8�K���g�@��$P��{<�D�#t���[��w�qmNK��T��J^����#�{k�'�� �b�}���uoN��t�c������(����O8�2�Gc�����љ�>x���8�'ATgH�?G�Aq�r��tY%z�:d�+)�^�/5�s�,��%�
��N#�X�9�"�Jî�@��H�O���^Gs�Z�Q�0����~��"q�Z�	s���=Ƕ�'��ë��C�x�"r�z�ʄ�Gc�sm��_�` O_�jw2`�����a������W��to���9P�T��c*.�F�`v��'�� !Bߤ�t}�Ѹy�-CSY�u-�ԟ)��Mm�(����C�2��F��o���UhBO���j3��$�iu@���E�"`����:ح^��D���C���ȳ��`����R
��g#���o��}��W�Po�k����U�AQ���F:9߽9�M����j��GO�W%i��l�d�Z�&rK�p�y���>a٨��RGc���)C�����$�gI����D`��"{
�uU�y�gm	:��e�UƅDt�>ְ;0Rj:�N%_���݈�����ޭ.G�f��!�U��K��u8Fu�����L!�'1�%�U�Y�i0��"��/��*�`[j�up0ð�̻�9,����[�u���.p}�$�N}b����Hӭ���C��>?�'��}"q>64T����HD�堆�9���q�Q�!M�	�%�ٟ��w�'�s� �-v����~�����e�]��75_���əmwS�W�$*S+��pF�D~� ���>�;������+	�2��ʼ�{�uf| .&�Î��k�Gξ���jx v�"+jp�N�^�t�l��vj�R��D�Q��K�(�@��5��� �(��Y|��g�Vz��n�MpB��()��q(�4�y�j�]�~3v�ϧK�UJ��f;�p��'��~�5��טO�4P�s��g��BĆ�2k�(���@i5�Da�f+�RE�Iff':/$��'��@��zi�*2�i�/?f��x��
N�,`�ߧ����v���%������)	�pb����3s%��T�2�R��=T���*E�@r��hS���_�Am�{���}^����f �s�d�ʹ\�ԟ ����T�9��QǊq���LO�����
�@6��_NǞ���������3�Q��[A*�o,V��[�_�r|�8FQ�:��V�X��KM��b�'�#w�_����P=��}~c���?�š��]-���r��@S*���B���)���A<k��)�@Д��G�B3����*m��fr��t��������,������h��C}�ǈu��Όލ�3�B�{��X�y^�~�� �h:
8ՖR��/�w��\�󽖷A�7���?��I	�;/u�Ww馓���/��k��U������ƈ�q��@2��&�}p�k
�/�!p�ݜgbo�b"����&z�bd��`9wx�" 8JWRc+Z��9�����Q� �*O�`�O�#��A�d�䕰=�M�i���W�/O��;��i��(��nU�j�*��=Hr���9�S�$���=)�̊�6M�'��F�-LC��!-�B����ٖW0�y���}7)} ����1a� 8��t6�u ae	���x�IBf)��#�����J��ౠ���^�T�-�M�����v�Sn��ٲ�����!�׌��@�p&�ۯy�h�;Q��f��t�KF��}PHhmB]}^�7������n� ��:,pm'��R�����.��yۉ�O������*����Ojp��JD8�uӝ�\x���Ж�O�Z�t^m��>NΤ���'��E����$�]�k���E�?�;5:~���̤U���}�cnPVW���G3?8z���º���b�*B��ON�bDLѵ�*X�o�x�I$���!!-'V�;W�ڝ��Б�&�i�#�-���ǲp�G�WՙR�F���#;��j�F�B$��KB�/�uE�Qg>N�帥H����Pa/��~�+���݊j�[�pB��T�R3���痡-����^E1~����3[E����p9�x��m�o 0�z`!шRj�O��hW�A*�c7�A�g�V�����&��It`�lfҵE/T#��~��r��21��(_�,�l����<�msK�oH��pr���1b0~���d2�{f�:~���F���+���p�~8��a�&���6.��A'b����sWG���[��uix%�L�xk2P�M����7�n'�\�թޕ���}��,4�z��ƅN�٢b�(�՞�x��ds5{o�Qa)a�v�0YFƨ��CrG\_�Pڳ_����q���K�R�5�YQȷ�ۉ�E@@������}gN��:PE�ҡ���=jJ���9�tEM:lJ����� Z `O�r��Nar ���GT︻�Z&��!���GR\�I�<֚:s�ܙ�6�R�0?ǳO��1��s)TF�P>,f|�1��nL�S���F�[w'Ά�=˩��o�����0�e,"��O�A���2���`{fiK���U��%'l�.m1����Lo�ND?,A�Z������e���`E��9l濲�د\E�2qA�ԓ�'���v��� ;�����Ǘ5Z�sPja��Zft���+Rc�Y���5��E F*I/F�[D������1.ٴ�����_�?�dӝ\[C��F��q���	�W�ExP;Gr+B�SV�Km�S;�:oA��5���t��؟��B�˖���0��!�Q�Y� m_�J�b��[�r�U�95�ѷ���աm��g�R���00��+_���5��_�>7V#>M�Nk&�[������~�,���Xm'<��!�)���o�"3�7���u��?Ţ�~]�hSh�e�<p�O;���%��e�;��~��g�âE"�1�|F@�j/E�\�d$`M6^�����ApķG�
�Ն��ʪ��
{�S���?1�B�mJp�v<�2���s:6��wګ��!�DS�2���^�_Bd|-�*E�N9���0�5��)5�乿P1�R���S�^��D�dмO� �5)��i._�tFu�$H�r{�#{ ��;Rg�έ�S�,����EX؟��cb���8�f)�i{��a��IJ �cfrH��С���j��P��Z�1�b��Yce���E_�P�5n������uE����W�P��QY4G	���j��g5Y���8���K�D�擫���%�~��N��ȰD��i2�(�8���=����+�ru��@(a�ka����|V7��y$m�'@$e�¹�Ng��lh��l��(�����*��0��im�A���#�=SM��aS(�%��+BaA�i�K�8������N߼R�^�^�Y���3n��\�:��٣�֛�]�0����kiii��o�,*��i�H� �+ :���9[&�o��,OL6�ebRO�垞�K�l�TgV��8��<5i�|�-M�����ݰ)/$I1N=l����L:��;j�۹q¤&�*x��@;��緕H%�^���`q2��-ϔ��,�1��c}�aA��h�`�)�̡<m�i�w��2�$��f[A���0�Q'��5T^`���LH�"��ckҞ�o�������@pxʐ�O�uώ3���{,`N"��b^YU<8<v]�H�����B�	����_��� �����.b��*�4f4��Cd�!%��g��P���'�@��{XI-�9'8�-os�� ��#�c
�iA�~ñd�+ѡ1�+l�36~�d����*�O�A_�{3��,��#ɱ�a�%|��|}	�������<�)�PP�ׁR���!�)�Wn���:'c����=��`���1w'v\b� +�	ĭ�s>�qҴ���h#z��Ͳ�"�p�_E@��K�����fjm�'{W׬�qv(�M���8ae�����	|�{�r�� ^��0�V-�S��>�#g��nGo~%�<��e�K��J߻�j�HK+��eMe�_��s��bbSfL�K䜛 �坑ġ�E�� ���tHv�1��ԅ	�Q�Jj�ۄ���r\��_�( o��h)v��
����_W�ĸ���cā�f$��=�����N��LRN@ڒ?���A�{1�6��:��r��_Ų�=����x��E$��*���4 �����k^�?��D�������s�H����f��׆_{��, ~�m��E;Z�ق9[*�-�;HĠыx�֖v�T}r>/�C}$;�E5o]5���/P�J(��'��$=���#�O�D���ڑ���x�'��]H�y��V��|�HW�%� yX��AU�:Q�ǹ������=����>���?�{���+��[�h�{KR�lO�[��q�T��؅�Ǖ��V���{q�c��o�#�P��6�0���}���ϡ�����Ԅ���٭��͕��4�= �3��m}�TY������a~�F_��pq�_�Y�P��H�-��g�a�q�z<0ݎ|a�%���*�F�P��<T��t�KBi_�p�����g#�j��n�$ɽL6\�D����2���;L� �I��M��W�l����t,��`{p|�p��sQ�(�}��iP�z���REw��e,�*��G �_����*������e+n����M�O��iwQ}-���:ҹ�R�`�L��ۛ����Z!����dMG4s���8Ba{��bO��K$�L�	8U�9�	Η��E��t4̆ʺ&��h]x�p������z]oIJ;lCh	��
�#��F�	Q.��.x^J�!��*k�Gy�A~�v�ŕNJrs���PNxӋ�3���\��Y�������!@��^bQ �~a�_��]2�C��!��)�N�8�d�bUϢ��7 0(�9̈�RN]�����GU�Z�8?Ο���G�f<��=����]��Qy`��E�	������}�z�����}0�Sp�����(x�#���<��U:Kj�-aആݜ�� >���ݿ_��g�V�x���R87�Vem��nIG�_�8�G#��0��*��:p��/�^�B9�����J ����1�,>*9�9��57	דN_�Ћ��	�g�mB�Y#��_?��I�p���T��*�ZP(����2�����)��%ws�C�I�u�c�s�w�:������v�x�H5������;�7Y�����L�,#�`?0�|�fuĐ�"�jp�>ٳ:���BoZ�Z7q�W�:>1ծg,\S�*��P�#]ԍ �����0mۮ)��TKd������%���@9�.2�g���ؤ�������q��!�����W>J�c"UO}ݕ��Ɲ�ί�ѓﰷ-7�������f�	�I���玖
�M�k��fH��yF��,��>��a�J�%S�`f�>1���˷��EVzܩ����Ia�ڃ�%u	�w_���W�'٥��lP��ۺδ�4`��BVT5�:�W�rj2Ի
�ݮ֡����4��4������fM�פ��v�}��6h�mmg��J�F�[��Y@�p�b��pq��Or�B�3����4�C� �1����.�I)^��{W��u�dcdF�yx�XƷ��&*���n��W�;�~@��X1x��'��Z�5�c`�rڙ��ǴQ�d'g2�6�C47nw��}`kF�V��-􋪡:&mJ�=��Ea(��W=�QJ�lDq�Xg��޽��p'p��z�)�&p�jS��(�b�M�֓��[�k�E��ȷ�9�m"щ!_�|f<>4���t^Y�������l4�#�]�����F���v��'�[�l�)���]	�veZn�Z`���*�����R8|�vVj����N����p��٠H�|^+1tT�^Ĩ�M�t֢��6�#��o��r1��~lt����o��&��]��?�6^�ꊉ���$��Mx��Ĵ��'j�H����1rH��Jc|����Hd�y����*�O�o_`w9p��x.4K���Mc<�<����}Lf^3'nB�\ZUG�|,�H�R���(���y������p���w-�*�<������=l4����砥"�ZuԳ��%^@ @�OX�\�|^YWp������O&Y(њ8�� l����o\��2�<���a�p]�t�;�O�o9���Aoq�x�'��p����f�g}��V�[7b��`���C�g�!̢��Y�ؚ�J�s&w�u�Ϙ��ܡ����L�icIFp0=�,*����c����y�\r�}��W���s���3���[A0��r���50U5���*��d�9��)3{:��8�&�Z�Q���.�����=S���ݟ 1��)�#�� �Ԧ�u�r�T�<�n3�V���[i,%m�kD�b�΄W��4��P�j�Y�L0��gJ���g˛B��%�/�IH_.��M���->3�Fb�^h��U��\)��©�H8����w�n�W�s��}���'�Ag�s-�.��Aѣ�Wk�x�u������L"�]Ң���?�l5za�{��mÊ�k��� �8��vn�
�2�{�g�7��M)�qJ���f�z�f��I��[���h�, �A�Fߜm��ɻ����IUP�mj�=�"
��zT6��ũA�_���sHmD��qpLH#�`O�h��\�ꪙǏ����Ȗ�݌���,��XgX�'��*��t=�m�����#�N>?ʊϼ�HBX:s��wu;�2�x[k���`Sڳ��b�@�I��'��	m��0�%PJ��B[(��NW�p_F��uH~l���	�+H"���f}ޔ�����+�1fN7�<{>$�}�~����eHQ�s���`G�+�4�A-3��j��n����ͮ H/)_�s�ۻr~�$�X`�D;/�n�z��ʎM�bT�N��T(v�u����&7�|uć������R"c{υ0��Ĭ4�����#���M�aQܼ(�wOĈi�O�D��>�O[AA�,%TI2�p���8O;o�~|R�0,�����1J�`������n���F��}���>P�7����I��z �5m�[�.[�b)�AND���U����QK ܂^�np���ۚR��]�g2�N<�g���s�1�^���)8��6��$����/��\�F['<�}HY��@ؽ<��VsZ�GnOg A]J!}�.�ϋ>�j����	+j{l;�f��<d����OBR�-���s���h�
^-�4�ƛ�,p�l�&�53�g���k�ŀ��,�n��ԋݥm�
�of$���#���{q�hL��Gqň�K@H&�e�Hn�?տ�d1�����j�W�0N�3V�����j�P��Ƒu��Gi1��8����_C�ʈ�~PK}��pJ`�Nk e^��1		r��ڷ$�Aig�⪬ր�����Z��ɛ�!v�9��f���;��|�9����˽�x�Q����8_#�U�$�Oc��(��iu�] .H�<(:w0l���^����)Kodx�G''�����������;jЪ��S��7A��J�?��	㜋�0h�YTw�U��	,����]ml+���X��0�~�>$�����-ZE�Ŧ�{[�H�l�_x��4�^8�\�˻ޘ����t���G��h1@l��t�Qw�\"��W++�����$x�R��R>�z���Ӑ^��%����HGB��<�~� 7wQ���fH��8}��N(�8GG�O�p�?���Μٞ���}�<"<}���)�~2�=��F)%���腯�T����2s������`\:����?Q�ҽ�������E;�6y�.�5�N��sˋٙ𩌑տ'HX=�c����Zk,��j��|��&m����U��Ш�������õ�%���_}��P���I�i?�D v��4lb'�T���*K�0KI�_�;�]�E��q];Ӭ�/+��L2^OF!��Zm����ܮ�8ީ����K�ߓd�lI�ϭ�V�I����K~�y���I�+N�
�#�;P=ʃ(�U�֏�bsV�O�n7Q�{�i���4�xb�d�O?���Z�����I1�u� yS�l#ډ�⒚�;c��F������G��5O��tf�e��w��X����k2۱�o��zu���o_(e���N�R|�a��[�<��Nk�=3A/��W�X�Z�K�݁��g���v������cm������>3����&�M+�><3Y�Y���	S>�p����ɈXE�p{@����Y\!�����/ɍ2�\�_J��>|b�JŒ����^�釰`���h��dٱ��}~b�g����Yq�0�s�
�a�͟�7~L	�	S��'f�E�C�a<Ua%�n��A�?#�zh�	��-	5j�Im`_���E��8��ʪ0f:ᬖL��Ou2.����o���u ?�x�֓O��O]%W�L �K�D�Ȥ[ ���k�˂�.tUO%c��Ǫ$"��oWs)+�i�]QQ���4j��r�Y��~��F��6�r���T����⏨w�~�zz4��aR�� �3��vq�%G�[�3Od�+Tf�m!d�ϖ��f~b�%a��&'������(<�De&��qr���ֱajV�c��W�n٘�V��MR��|L,��O'����~�bsq�_m���`z�t�,�Wæ��'�`�2�D���vN��I��r"��a�N+�^/�]HNJ��
̙�9�p븛�p^	�|]���*^oe���*g��_������Ņa�m?4��U�i���`�H�JלdwȆdG����$*���E��:�E�L��ɣ���?:��4��崥g�1w�y�[����S�6��t�-8wO�O����� O?!^�U��O��|:\��N.�?����ƪ �i��35%L.K;���p��x�˱�UO��$�d��AW��dy��6�
��5s��ѐO*� Kd�&�8_�Ҝ]�����ܐ����W�7��uQ�Tgi�FT�Sf�uDx���`ҵn-��e��'`����.�N��� �c z|)��M�M�S��kP�L^�p%`Z{l���]��Y��8��R���P��NW�@N�����`���ܫ�Qs�^G�]��^i�U^ou�~T=n�aɎE�-��P������e$&%h�O�Q b/kE�[}(> Uة�]E����h���/�4SA�zaذ�;>䦩���jԽtPt�����A5Qr��zk�������vYa�N�ۓW�8J~\Fπ����u��F�&�8����R9��;�j�*ظNEp���@���K�&+��Wͧ��'$7WK��m��9��}�b�ws0�HW.��ؕs��'��i�;��Si��o��n�]	����ڏ	8˹� ʥ���m��;<D�]��hx�����X���H�7Ώ5k,eeҩ��-G�ݑ�������ou�Dg
�LB�R'g��a~���s]~;<3y���1��,G1.
�{�~�NzU&���/�S��.���������g2��>T�������~��
/��߬R}y��GYd�3�CNo��u�=�(�i>��L��U�C�"C&L�y���.s��j���b}$cmĪ!e���M���ӕ�Q|]�X����zh������ ���˛�`i�f�<���6c�H{D��]f�니L�F�7g�,L�k蔭�$��h|t�3��E��`G�)��-���N1�_{�����]�d�"��UC�e��'�7Ok\�X�k�:I`Qԁ�AY��b�&����w^������m7��q<���&\�&˶1_5�ٺV��Z�$YӰ#�w����m��:ذ�>��W;U[TA.z��� h�D����'�?^��������Ά�h���������}!�s�@�H!����l�E%vb�  1�0t:Iu����gI��N�́I]�Tq�pP��R�5-sC_�K-Ʃ���E�y3�\id/�s�#�vr@m���j/���-I��B
�����Z�S��k�;�t<�k��HC��^��G�6��!%o�� "�ٌ�|��_Q�NkB��%gPX0ֺ�1K�$w7a>!l�s�Y���AiU���V�(�ҟ��;o�o�4��B�q�>k�RgyBԔ��^/�
��/_�$*��r`�'Mq!�%�Q��;����eu��8���q�bue�}��j����sv�����K�b�HN�c�K���T�� ��X��*��5���'��� �0��tI
������'b�8>PF!���aE������B�l��=.k����
���`ߔݸJ<��D���D��G5�	�c�~*g`H�e0�H"�+��/v̪��EcI�����+��̦��X�!���o��t*�9��oxH����g�2 �V��쉷@>[=��, {4�燎O�8�TL��X�C5⩅�� �IJ�1���A�?�35�X��5fĦI+<��LR8�pf���+�=��F��+Y��zV����ú�
6pg*9̢Lq>�NՄ;,�TC؄R����&�]���rQ���R������6E~E���9�w6ܭ�o��Y�|陇�,{|vq�g��g^
�J6�ƭ�� ��U\;��&]5�0Ep@�
��/����m[��ҟ"��C��Kzl�l���1�\��YH�[H�����NO����E�&[�2A�]Y�e=�y����{�Pt��Фc*~�
�Ɋ�[�Ȭu�s��FS����f:b�������t�sQ1�/��;/�#&����KA�&"�,τ����ŀ��X�G�/c��8ޅ8kX3������yu���9P�N����I�׃�����1c\`��5���q H����K9�*፬�\N6v�.�fKn��w�ч�Dv�'��a<���\�֜U�E׵�::��*۔�zx�|p���}��2���m�H��]���,s�BэBi��ۙ$�4_�c�',�������;0ɬ.YƎ: 9r��v�ٍf��O��� ���uw�O��.�1�4�l��k$3��iT`�@vj�#%Pej����o�֦Q�VA.K�'���q��D������Z���Nn������꭯�?J<���o 1��Z����]�zPU�hwdј"��@���Z�iK��K���}$����[|�I%���<�J�*�{*�Ht�.�{{�ܲ�A�/�p����
i��(��S��u-d$*�u��[�CWpEP9��q��W�q6>�a���}��[z�| �9k\BN�j�E��H�� ����oWQ!�.p���������t� �^�5|��߀�z���hX�h��)�b��"�}��������NUa�8���+a��q�oӖ��:Zo��c�
,��@��(?�+fB�7�#UB��01���v���q�c�tx�I���1�h/���@]0��eW��y<���W������Ɨۍ�XO���U��+X�r�A�Jϣ�����?���0��B�����r��7F���HB{ْb~C�<1~� kRF�O��$�@,�]7�`�`J��x�pn��R5}>�6��S\Xv?��r���V��\�<�]	&��d�%��i)t��5k��B^5�,&VU?�����F_������uʴz���v���/6߹ž����z�L��U��zog��*�[��f�"l���+S���Bm������à��cB+ h�̄ ��*�=���&��<3�5ֳ��$�mz3�?�-�)?g�^o`��*���OΜ%d����ʥ�ž�}��&�����+$�,�!:[ɚ
RI��f�r�
�7��,Q�"�1dPZ����]av���/ᕃ�(�yS��O�K�d?���2�L1���q���B�bw���<��4�#��>����;�P�%5�B�;�k�?8J����{k����L�}�?��kڨk��
Oa�܄'�O�0�ҿI&��i���k+G��?�C�5Y`���(�r� �k|�EGT��0����K�X�,3�8�ZD?���wPi�V�CoQ.��r�~1��{�r��a��s�����[p{�`���ˡ�`��[y�%鏍wd���QT`��>�`ğj��M�YN�	-A4���v�r}L��=��b����'��o��{�_K	��q[��f�pW����R�K���&:�Le���S�[	i.)�� �j[�m*z���5�RK5>�Ɓ����_��GԪ"ϰ7u��X�o�
嵷!�G'�����DhI_>Q�d�|;]��|��s��+y�����F���Y�G��$� ='���Ƴ?�?1���	��b{�Id�h����i�����C&�]�G9�˽�@@�(����<��� 4i��w>)�eT;�%H����
`+�� ��dZr��CG�$�2\6l� 	N��-eL����ͅ���t�����*�",h����sj��JqE���Bm|�\��y2�7��ũ^��S���d:>���Z���M
u�I݋f�G7soq��J7I�@p�����Q�dU]���8�(�m/�:�81^=��t�eǯ����?�3�!�iW���ڣ/R� x;�*n:``�O��/�0��`�=y���~��뭅G�A[�O�	�zQ"e��ۄ�:xO��Wr�d��A{���^Ă8|�~K�����S>B2�W�Z���`���m`��^���QjtG=_ڲ�E�j+�0�W�ϕ�m�{w��rɛJY~�����<��r��Ep��+O�:�7���1�x�,)���8w�b�y���x*	�ۼ@����>���?�a$�L 8���2�ȆaP�NB.��-h�Βu�y����5��� ���ww�%�) `|;���	���vN2���q���_)TM��I0z���O�eŗ����ނ��Z�x��U�mN��n�mG�~�f¯<��˃X���_�y�*��Á�`����}"s�U�7ߜ��ɣ�g���r�"p:�Z� ��������� s��&D����<��*��:��B=G0�~���jAk:X�>6��:���2ᖍ<�#l��dW��E����*��-(�I%�'�GV|�����#Q��;Q�Uat�)���U|@���o5�u�p���P	���!,0~�/����C��K�#S.v�C����6�G�&�1����:�/҆"*`�;�YR���Ȝ��)!.��e8�	�֎Ӌ��m �!�yh�!�7�	kl�Y�\N}��@�;�L�Lh�{�n��o�7��&C��mO�{����[�!ˢ�̼k�Dv��j��ƅe�(�.�T*�U:�/��:��qǺqxѹ >)B�S� E�k�8	�{��q������캣~�$O��K�̃QKZ�Ա�L|(��ۿ�ccg��}xN��|>Xo=Ș�j␚��\?0!�~b
�G�E�Q����m��ȎP�2u��EF�a�KF�S�&�,����n]�?u�W6� �����xN_ڧ��*>���ܨ(����<���&�c���T:j޿g�����w��2+��w�(�a��G�e9I9�WI[ģ�������Hԩʔ��B���L4V8���
�+5>N���Iޔ�h"�`�fG�r��~�(ྍ�b�;�N��ի���+g���z?5sT������1�b�;$�RҰ8-N�VR]ѕ�$����OlGY��zXǵ6�D�s��E;��'��������4���>��d�F�Ѯ�+=��v���	��Q�ѠP{�%��<����7�Z��Y�}��\=x�J�pR�,w�n�������b��"݃lznHf�,mH�q�L𗝍#�Vn]KW�~�I	~F\	�4��D���0����A}�=KLF�� �ȋߊ��3�lvƲBa�ad�f��������&�%4䴘� 2"�yd���MI��#x��.�̐J(����v���{�2�&��.�����5p�a�e��*\N�P[5۠�����_���<dX�>lB����Qc[Eq�oO٬c�z}ma���H ��fd=;����u���p^q7�]|4*̠��^@�FbBm}�S|���þ���F�,�4T�P�.���1(7���q���4���9�v9�d�kUS���Y��#������ܽ��a�O/i䆽�_�gs�@�h�eF�@'ᓁt�k�9GJ�X�{)a��-Э�?��}goMR)br=1��p��_�^�a�M n7n�h������#��{�����$d�!���������H/W�-��1�9�ŋV�U;����V�a��ES`�J��E��^�qA��_�į� �XXzW�]ƴT����W�d�STl�w�L}���y$����"��);�a\�Z�11A�����a�k�V_T����^�Xi21" �m)���H_2+��ۼWF?`�V�B:^�Z-�;*'Z�('{�fY�ʇLd�@J�+Rw�+�z���O�1ϱ@7^�����f�:�'���b�?4�D���Ŏ� ��ơ��{�8;aљZ�Y�A�	�Cw���GKw�9>�ˎ��%T�"�]CW�R��M")��V2�X>��&z��r��2��MG�$���
E��o���g�����ZI�i����E�V���Oǰ�Ƭ�
)a��؛J��<+��p" WԘ�՚�lX�W�ͱ~,�mp�|�t}�8���e٨��E�Jn!2B��x�X�?|�@�?!��W��(Y�-"�$��A�����`<*~��ʂ����H�N��z�d��ӽrіb�b�V)^kM��b%��t�Ž<͌�1�O���޴���E��,���~�0�����jH�<���(���� t9�~lj�I�C��/(?Jf�����5�9xgp��aJ8y|icЏ9�"J��A��� |����p9k8{��ߩ�|��[��4N!�_܀v�P����0�J�j_�g�ﰘGo���i���>p�&lZ�>��+"6�������Y�kk�5E�l��wr��FR���f~-�%�o���Ú%�-� #�,�0`��EgSU�]����2�F����v���F�S`z��E�Dd�9Q�����3����^�,\�B߫c�NT����[a�CV�M�8_epa�����E����ck��dp]�*`��[䕖0��>��l�ԝ7���ŏ`Ĝ�	ĢC�C, h��N��|�k~��фtH���:�U��M}��:9�V �ѯ5`�l�Kp~]a� E̑;1������H�2)C��@���Φj�,>n���T�YB-	��̳c���0Cy���W��i��g �7 ���1�U����K�+1���u�J���.��W��z@�զ=w�f�@�>Յ�4�Uɤ-�cvSg��u�8� {-��+p>n���P���,��ψ����q�� ��gN��|t����b0���p?����E�JP�!����/�1H	;`{~F�f���1��Z�����E�5^0]��N�u�-o�n�lm?�P@v��8�&"dg����Yj���lI�:���na�УUʼ�����'��햝� o0�<]%6�������n��w���4� 2�d.Fd�.��o��Fr	��c�p��0��_ 2.Kր(ޮ�Y���$de���)���eX#X�f�M� ꮂq8�\���L�V�����_4�&]]���q03�q}�T�Eq�e��bkLB�ݲ�<�8�,tb
�?�D�]��.���W�%l���!��Y��Ҩ+]�E�h��ِ���9���,�z.>��IT�1Ex~��̟T�����&����M�S��U!e��}�lgc�vF�#eV��t�\}�zt?���B��=2]A��Ly��G�;�]
v�
("R/����l]�Ȏa��lKo&���@��|O�U�p'��F6вq�������Rx��Ί�m��Yoe�m�{�`U�wdI��U4>)��:H�T�)<j�Hf�� s#� ��sdAb��c��1%�ր���Bv��6D~j2цVM����%�j�k~�¡Y��ً�� �������L[q� � ����Ή�'��Ѣ-<��*)�z�ᾆAн+�3D��
`�0��swB`� d���J�b�}��	�?'	s�g1������qX�F�2�NG��)��m��|�Y�w�4��q����f������M�o`�.݂r7��a������7s�uHR�L�W#Tzߖ��
�p���R�����y�>�,�ȸ�mwC��-X҄�72�xsR��/���mg�]��51�>1pά=��_�-։I��[�������# �j�����y�6�4ۅ��ݕ�U�d���2C&������"W�<J�g%���cʆY��C\l��f�c�1�����ִ�-�f`�9�ݭ�s�%����h�	�{9O*3�N��Ld
��������5��ݷO����S�\܍TJ�k�9w�����i��h���n$�߾���r9.�J���@��*G�͵tHF��C����Q>,@yw�P�1*�Ch���פq���2OW$�Գ��
����QP�'_����m[���WԂ;��,Ƹ�wz�T���/��n  g.H�o������9����ec��ys�H�@R��,M?���b��]3(��&������O#~�b��-�UiqK�e����������4�:~��A$9�t��X�'#�kǑ3;�U���H�067�f�%6v�8I�1��*���<Ƙ�u��9z�c���D�[�Z�B4�J��S���L|w%ݲ��/���M�kN�y�F�Bu��tU�S2?%��ȍk���ky��A����U"V8��#��(��B���U�������'/���+��������mI�V״4_���Ͱ�Xc%,&���#Y�9ۑI�KU���klg�-�2��Tǅ�ݣdU�7��7�Zh���әu �}g1-I��D���G�W'���1l`*�e���ϛ�����_f�V)��뺰򃟾āX�ת���=�XҔa%�ֽ�PY3Kѕs�U���P���cܬ��~߷�`Q������É���;P�%�F�&a��)��\��:d�5uwP���JV�PH�7��V�^:��5�yH~���8'
Y%�L�eem�*�5,~�+[0	b���%
��G���^��0ȏt�s�@�͋���1w�=��rcV��8u�s�l���wm7�b���tv� �I#k����k�X�Ѡ{Q���`��H�V涂�)���D+��EUɝ��d��;���ן4|�$�o�kn!Y��Ę���k���\ء�V-&C5L�r��C�D�H"&V)´��/F�Ɛ����gmQՐv�jI�ɹ���e��xx˖�b�`���dɔ�#��4Y\�p�(��/v�5 �u�B�������&�} L~�tTT�^��t�ￗ�0:P�����7nn����9��[I^hY!�`³��I=��7WT?c���%�����0�ĴI:IE�d,���sI3�Y N�t�V�c�I]�={�aAB��j���(<RT� 
fs�߇��w�mA��Orp�Z�]D≡ClJ�{�_!t�i$AS:}xaߘU�c~$`�M���N �"�슚�:}�1-:l$4�(K���2���J�v[Z�"�ҍD5��<g�Q��Pj<6.�Pा���G�l�ަx�{QD�[]��Oq��|k�)�"�n�=�KI����h���~9�K��Oh�-�4�N��G�0�2���4�}z!9(3.���3F��=��NĮ�|�b�^���'�Q�7v�Cr��GO�Nq
�Xi���0x���AQv�Z�NZ�v�S-q`R��zc�hA��Γ�U��n߄0_p�yul#�����wG�'��-X��u.F{����ۻj^�>:Km�����6���'¶�l�2��'�OC����9X�f@>������R*Y
���$d�^lg۷`̄(5�a� d8���#~IX�/Ҟ|u:>]Q$nK'���w��P�;u��Ipx�3��ķͣ=�����m��^w�������dB�IO)���P��a�(GC��*�xk.Iڦ�cB"���N�`^��!�}!)��a� I�f�c�	3��p�R	���-�rdeUF�R�!و�`" L̿́7C^�!��:%A��	't
|����Ev��������g1Ԓ�G�S8�����4�$�,r+���k��X�����W�O,d�r3��y��Y�*��n��G>�TV�)����Aj�@Wt��b}M,�
�=/EF|�<=ܐ6�٠~=��<�9��:�gU�j��"m���%���S"N�̧.�n��@��������!�BzZ=G�~��	��n�O�۫�|_V����tg4GѾ�"Hh�$KW���0}n{ca�n�6#��t>}'EI�[S�li���M9��$b�Pߴ�5���v��O�4}��D����1t�EM�0��$ԇ���ki��?�ԭ��+ޚ~J����˩��Z�����	�>ȴ	K*T�D"b<�t�9B��'K 	���71�H�m���[��~��.�E�;�e����<�J�jQ�~|�2�+�m9kt��^F�2B��|7t���\�$/T�g�ԵJ�3����\P��x8܉�?�Hh��_1�0�2�	����Y0|v��)c�����R�����;,���i�olq��=��'YD��W���h9���R�!�����	fP�����-�r�ϻ�2p9+E�J����j e��⮝\j���M���C8��_�v��Q��Q���Rq�&gj,����l�v�.��a�������g��rI�"�����C�P�h�R��*'��m~ͮ�M8�|N79y��*�����1���L*\�X�?� +��}5��C�,���!����a�״�{?��9W'l5��7>꿞�i��Vo�o���;qF����� F3ŕ1�/�
��i�%���+�6���c'�t��P׀�M:��E�G
I�>X	*�"a���Mp��Q�8�uS7�E��4����?&U�%��HjD����i�x�ݯC&�������&�������]" �O��#�3��8Q�T��{45�o��|!�\MfB]�y��t�3�˲��'�&˪"����x��+
�L*&Lo7BD�j�
G;���/��K��6�	�.���ĥ��þ�6I��iv���#�(e��s�Ŭ��i䠵�?��6�?��r�p�.3�x�c7���K3�yδ�iF/4��ۍ�tEt��Hz�&O�Q�V<o^�	Կ��D�*���l�����z}\�z`��-����>0b@=@�����`\^]�ஂ"\�j�a��T�x:J	�q�#G7�hyP.~����gt/�����֮@kQ\N�[���:�����*��oH>V�@�x��c�j����p���٩���L�N�qX�Q_s������}�ϋ����F��V}��	C���x��J3�?u_�<��,�����b�
%����'1Ek�'���\^���)��*��s�0�s�����>*����3�=+��R�>1\�c����4�=}@I��HFS��pW8���,7[ŏ��'m������f-]�.��m��@�D��B�'=n.�`���zs��S��^֔D�D�6(�q�!uKA���OG˜p4$ J�=0r��<K��G�K�P̍#�XʠU�DZ�̱J4����n��_�SX�/�ۄl���6B+և�L\�l���$�X7H�'� ��%*iPi��^����y��Hr�5E�860�<�:�~�ɛC	HDؚ��cmD�'q�Rʪ�l��vGa��%q���i�8u�G�4%ݎ~�gg�*�Q��X�i�fbW&�!u��y�hB�9�i��~���O_������"P��ay�c���o)��1S>Q��T(��:~�^�Y1Ž����O����a_��1s���
Ix�+6��b_��h�o�}_M��9�߭T�ܝ���$����.Lk	�� ��"˘Gܿvw2�����>��=��(��&{�_"̪�7�� �+�w�	gݐ���^���Y��XTմk��(!Y��s��U=v��g��=uɠ1A�I���T��PS��L��s	V5� �
b�%Q��_�4 y��8�s� ���Y�/ŷ�6���f�L�Yc��y��(�lR�g�.����ӓk��'�G�Ñ[�3h�b�YhD��},n8�1�+fa)QC�6��"J�E����)$��/��L�6�yg��'~B�]�+�Y\���R�+��>�~�Y�/=���z�L������>*L@Pz��&:��Y�7�C�U/�a\Q��x�w�~��+���u��1�|�`���ԭ�����z�+?��|�2^h`���1\����ߔm<Z�?_�{iX�B�B(7NC<���X��-.  �
�q8JG��Q������w_���i�v�u:�T�4R�)�(FB���꘸�S��k�I)��bE��1��al�)��:�p�hL�ӑL�6�v�e~l���`�?`iO�h�옲G��}7ȕZ��f0�n6�������M�4��������Ǵ��6e,�8d]׼)����M��^@b>�%S'��>m�ᬇk��Kn�1����� ���^�/��g� %uÃ=��$X)}T��<(�1�p�=w��YL��J@��'��.�@䱵G؃k�M
�̟�W�������P�dV���uA�4@c����lIV�9�)�;���&��͋I��q��+oH�n��|�T���H�z���!J���e\��ǖ-(l�#��%�:�9��V�$t�HΞ��&�DWB���G�񺡹��|/��m���F!�ȭ=w�Z�|3��E��w����l`I�����c����`�͒e<?���r��}pg�ӧ���?�ɫG:K]�����T��5x�#��`	Ș���`��{��v&-p�ǧ
�o�A6|<�b���0����+>�A��3�9�gg��@��=�4�ə�)I�`5��H䞸�挡�6�ۡÎl5����5ꅌ(���La2�a�g�  Dds�O+ �����jm��g�    YZ