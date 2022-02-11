#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="316915473"
MD5="c72d4aac6d0e0cee60b27a56ba1c3d38"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26464"
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
	echo Date of packaging: Fri Feb 11 04:00:59 -03 2022
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
�7zXZ  �ִF !   �X���g ] �}��1Dd]����P�t�D���,�!p3�}�i���PV���DL�gy��RC��f�ו�т��EP��o���a���G�1�R�H��RY)�_X*k&�rЏ$KX�l.X�㽦��N�+��3(*�=w�A%J��+6��gI�H�%p���L���G_�<M���/��חA[/���<���3����Ar8�����s��4��`�V_z�ᵹc(u&FP�s��ӑ��C��D�K~<�5��W�+MB�
�XJY�}�v�YfF�0Mh*���`�ψ�c��H ��ǾB�~n��	�O:ްIYZ��B�C�$�ZW�@tM���O��D`�������RV�NV�6�\��l��� �5A�,��U���a��<�?�#���S���hZ)sڊ�R�<[��ƣ�~�.V�����������[�Z2^ɻ��Y%7!��m[vK�Aºhu� 7�RN/5U2	
�>�2��x �B���FB[UB8�V!|���U�ŷ��i�P�ą�0h������5���ч�;Յ�hψ�I�>_�6��d���a����$lH+�]�Bc]��Y��fvI��5�Opd4g�Y40�aS�1pg��z�m�����-�'�;e�\�S��B&���*��O�!�b�pկ�?!Z^g\����<�o����G�Jݠ��ẽ&/p6�%�лW6���,åF�R���P�%�P�Z���b&���e&����O'{��Ub�`����n���ςSf@��$�t���O�U"� �""�5���
���h�lK\�ߜ��j(b��N�����혤�tȅԧU�H�؋;��#�1���O:����
7�~(I��Pl��Y��c�5�����é��~��շB~���2������
ѧZL��p#Y`��>����%�/,�_t9^ԍIp�]t�D9|+����M'JK�����F�V��xHSP�,�H�p0�Jk,"_���jݜ�m��Oj��+0�^X�6�>�\��ͬV�v+�kۘ�i���Ǯ�d5 s���P�ډ��y'G4�.��g�wH�3o�*�:��rw58h'�"�H���#��SF���{��l�"#eٲlS���\i� �(�t�+W�G�����ss	�5���TJp�n�ɢB��F*�璠;C"#�79 ����aO6E�l�+JLPK��+����MMn�.A\�0�d��/��=�Z��t��F��=�b�"��2��MS�7R��`�0�W�������k/|��?^���6��en*�fqN^Pc��	U<�q3�=?v%]͉�Y��)�쏵_��b� �Ѩ�-䣂�i*eZ!���pp����zx���y`Zh�&XYv�@�@��u.��ѶڮB��s��2���ȩ�9�)�=�sw�Kf�zi�~S4'�#�߅QyJn��XG���SQj��8����P��*�8	�\����8C �����I�݄,Tz�%f����YS��f�\wŒ�%��(tj��;�OP(���]K=WY`S��%2i'�}��༉���Ep(a1I�EfU�V�[��
����6c����
�3���ul��m����
e�t) J<h���*��-fL�˳(��Ce"��r���@����+~�V>��p*u�~��NK������=<�v�u �B��n�ɜ������D�v ���ٕ����	ԧl0ɖ9�7%���#y��Tۨ-�ZIL�KbQ���Z���.�N���$Ԉ���t,.�Σ{@�g=�tw��������G�Ƙ�øaVFXp�'�TH�_��2J��=D@@
OP�^8�Ԅ@py#��B�H",�r��ֽmu�m��j��Ni�5Mdw�g*L<��'�:/łi��Q��>*��C=�=��̴��ɰ�|e�B���l$������A�I����X��So��I}q�s���6��Rz��j�3}�v2���\߇��⁇�cc���"D"����;L���ݪ�7Q�mv�������iu�����B� 
�Ie�"*'�����~���~�{��Ж���������U�k�7)Eґ�����H�l!i����B����dW�6��uZ�A�s(8K�=I �p�d�d�������Ҕ�z�	o3(,O��g���(=��*�0��UH��&�C�^�?~�Ǵ�ⅺ���Mԇ� �@!�$
���#���H�QRK��ON��oo?�
��D��|wȃ�N6�^�O@��?XKj����3N]�A&�^����X�
耞��r쑗�ɻp	�g���-��@}����6�e
EsҏZ)j(����Qإ����c;��5ćߩ���3R��!���阙��4� �k�Z8b5��ЫdF毸����]ie��G��� �{V6�h���/E�`�Ό	�ۗ�	p[.x�V�21�bx�n�\1�}ܢ�͚8">��������D���{_uU��.r�h���0��5�C33Ш%����"�U�)۹o"n��73������9�b�;O�ՙ�T�@8��C��.���+ͦK�^��#��fW_��#7��o��>N����P�g�H��1��nT9(�YC����m�˥��g�EqC�ݥ�s�F0m��2(���+���v����2�C�E�_Ԧ�B�)3OK$��6Z��KU���Ǳp�R��&XY;�So�OHz���p��(�:����9t�
�%muP��vpY)����{ h��y��۽*�"�RO�Ԟf��V��%c|��;����yl��(�{L�}EM{���@c1��)u@�,H�&b����%�dֈ?�r?7,#Sg�g� ��Fe�Vg�O��֓�ʠ��ҍ���﹞�����+-��ܟ���@*�[(9y�N7&2�P��Zyp㴳(7��� f
'�m�~����cH]�-�ѤW�U�*�1B>���'�W�kE��5s�/J��AU]Z�s�=9)]��.�3Ή���y����yK��.��7�coN�����D:e�JB�ꩳ/������|���Ӝ�z1�X��>z3�?�4�ȁQ�[Y�!�eEY9X5�.Bj�	�P3�/��i���̃���΂zOD�.���-�Ukxk��z7�b�	�j�j�ǖ�vW��>MBP���"a�43�Gk�I*$"��C�;M߲+���~k0(*��\��<�ċ<$mtJK� ��%)��)%k�j@�]���0�/��8K PM"�!G�����d�1������� �2+?�b�π�r΅G��M��0%�Ia�C7$��b�wu�\͙(b��Hnc��� FVZ��V�gyb �(��0h��uvN����uU�<�.�:�������,�����^�}�?��4���EPkyja0�ڇDׁB��"�ֹ	wO�r�Ƥ� �Fo�,����Э�"
�#��3�]�:��/D�Z��!5�����&mOQq��<Ɲ�����cjtۯ�pBͪ���O��{�Tg&�T�ng�_$F���D*s@ԣ������~��ۦ2�4��)���:�LA(�D�>(������y�{�td��nt��(㷩v�"2�J���6o29�ɘ$����*��Ue����� R��
�kYI����]����5��8��W�e�:ோ�H���9i�rX�V]�$������Xؗ�z��Q
�7�w��c/��ǰ_����?D� �,m͒�JGK�rvrC|1kLkl��_t��IVnn6W}f0��<I̔'�N�އ9EL�poPW��P����{����v�T�/L���b����It����:�O#�8?U�:�rÜ2��F��}�T��m���%�u���� ���@IC���(O��鵸�f��x�����a������t�$�T���x�>a9��:���e��;��[	�Y �
�NQ!Q�u
�t�-g��W���r�����9.�LW��=���w{��#o"���sl���[��h!��?A�M?��,�\�/N!D(������+�b>�;q�y�5�̬�۹Q_���D/3۬a��c	��	�����t��^��D�1�x�[�,kͩ@;Ȋ�U��k�| r��� �dv�&��X����F�񒅼�J؆n�K�Q��_D�0r��2�	!�l�{��Q�����$�!�J/�}�zf���2o9���w6����Њ֢(@�Y$ڡص�g� f�Bf�&�V1c{�:cr����yUq�Alp���m>m��-�G�ODpEC�Xu�{�5�_M4A�~I����>�>�Da��l�z��h�H!�4��3�^�p��g����?F��1m�9\��K#��>`���S�u@�
�y�T.��Ю^������E�k���aK�<�٭��t�('��볶�9bs2r� a�gP��*�o�|\
j�H-���q�w��NNB�i/����V��%���#�~r�y�k:�s	�Ws�>�zCm�߷��&� 
��M���o^����^.cz=a�`�P���vX��;n��(�1&��lǬ0ʪmrɃ6a84�������UGq���p8ʐP��� %���&xo�cK�>�~��%�ȧ�@��hyCv6@h����֡��:>J�U��`-��'����ܥ���+$,W��� �+/���E=����Jt��v�M
D��[ ���J$�qW�#���fHW�L;/��� �.��Gh#ͅ�tՑ�?�8�e�[n�����R)�����fZɾ��mI`/�+;����� F6J���@��]Q��9C��s�����H��py�#%�h"��h<LI�X^h��[\t[�`��������y�vZR����D�����%C��!�L�~�GG&�x���zSn�P�=]�e��OFOĆf��F�� #a ���0Ѿj�8��St�+�P�%y&������0%1A�߯����4�׳<��"G�	��g��B�����@�lV��8x�����wdc&��1��u�?��|��@k~�DM��'�u���"��&�(*s�����+B����=f��C�9FP͋�pV�Ɨ(�oގ�;"C��j���a.�/�X�t�'��o�����h�����~�	��_y
7�Rpk��b,;��1BW2нr�ps�S�)��dUY�Q� �c%�a��Q��;m���L&����U}k���n�5��3�$Ӂ`J��W�����̥pƸ��t^?��<�������?*����Ӄx��v�*���K��i7
�'��qUY[U]U���k�#(�(@����l7�d�z��j|VI���	��I5���$�����=y�����E^̺4�]��re���	�tj�𾫩s�!MIg�%�'K5��H�'���M����e3���-r҇
�<���W�q@)��6)$a�����d�~-���E���G�����;�)��Q�Zz�MԲ�Ջ�3��a`h�],�yeTn!�si�_n��0��~~q��W�&��@3zdg>����k�%@�������Ćd*�&
�.v0�a���q�r\m�˖s\]��n�Hʯ��ޚ����+�9��[��]Ǧf>3���*�9�Xk�ui�w����29?��{5h���EE�� ^�^v���Q�_Ed���� ���ē�2��L�O�����&������� a�@���"H_wU)cůΫh��AU�a��-O�,��*�!���f�<���Iv�m]�/m+KJ^�O��v�_��<�#���xxY�ހ��C�O?T~.b�@���J�w2a���m�3-���N� ] 1b`2"�P+(��T)�����d��)�pm��8Fc���/�ZC��2���\�3Y�vY�o�Ƴ�� :L��P���TP�`s%�4��������%���߀��������k�'c*�	97}n)��E�ޠk��^�-��o��~�C%zݧ&<�xj�ԍ=�P�E�����Z-��
���!,T�v8B���d S1�I�9�c=�c�	:EF����r�w�N����*@��e�DW�BJ��¬��G^��I�[M�h�M���9�\�5��d_��oL�z���Z���o�;���^ ؚ����\V�t�����>,@�-ZN�g/Y9�:���_�R��Zjh*��tgf.&��S�?�t/m����{�NSf첲��� ����_�������_M�����t��%j=��'U��.^ gͻ����`iϮꩇǤw���b2a~�͓|#�ɬ(�z#���n�'��q����7#��t�_���E���<Z�1>��4�M@W���z!?��1��&X8޳!�T���^]`�PU+���П H���˕m��Ѡ�{Z?�	(���^��I������8�b��ԛ~�Y.�cg�0�F`���w����j�Fd��IP:2lH;�{b3��h��.�ו�`Y��]>#ί�\�q�-�����c~ ���s��!]�r��b��W|�j,?pXv�|�q�e٘%�9�����Z��2OLQ.�%(��x�|�����D�uf�PG) ��]a)<�4rA`�ҋMH��z"б3�6�W��������ؖv�1�̏ɩ�OV�a��:i�3��.^i:	,���d�p�J�-	�K��d�W(� ʀ[�w`������h�(��SZ[`����Q����3����i��$V�j��G"|D=~л�&W���r���=I��?���v�~4�u,��#'��d�-���QL�f64�3�3�b�	���}[�cB�N)�e�[9�P7V�Elk�]dP׿�{@2��#�p飬�sL��QF��K?�D�m��k�G�؄,O<�5���}�F$y�����?��ժ�jPNM�^�?qdTH�~xG�o��#r�_�7���̦��4'o�����l��1mw)��7��]ԴyD���Y��"��^��C"�UO	L�P�������10n���t[ֱ��#S����\�Y����c
]��N,`����^k��94�
U�ņ��6^T�JV+͌�.���צ{�D~�nN�#���k�|�8����j|��rM��rI�CSܼ^_j�?���������\����jWh}�%���n�0�+���qX4�Իm��x�tnx.Q��t� d��5��Jo)nw-&��'&��.���>o��ˀB�:Nǃd�lruIwʺGu����	lݓ���v��'C(?�I��۩UG���&�P�A7��t;�����=�ä��������Fbݮ�QvU����.�_C�d��g��p�	�tm¶�r�YM�Ig��]Mi�wJ4�K�� )?���OW��������̀��\�������J��Fŕ)4�k�ƅas�C�o'�X��r�ac�Ő~@�QU؅�j[Urj�%�1��˺���Y�{����w�`��3l�*���N����?�&Զg���E�1��o�H�**x`�1q���\j�Ą3�;��G81b��y;�^<�$�N���@6�T�ە�W쵫�RT��#tf�4���I�y��j��	\��Q⁥}��J����g'������4�u�Hm�0��i���d+K�j�$�63*U���Ј�ڴ���{7a<�mlM��Z����T��tVB\-�_޴";�k��Z��V���>u{��W��0��CR��ƶ�~)����o�)"�}j\`���nK7�^E�����U6��~���p<��2��cШ���:����u�n�Yl��5}�y�,�/*��6@�)HƱ���e���m��0@�rdje��:Q\������?�b�����������*��+&I��R�1�rA�A��C��v�W��['�S��j ��Z�n�`{�=4\�5��5|���1v���ͷ�6�J�\��ʭ�T��ջ8O|���x�J�b]=�i1�mx�G�/8�����#�[0�?ME�NN��ɰ&�"�6O$�=f��!�m�NU�`�8yD�FY�) p�QB���ou�gSt�3���B?z��ZS�h��kX���w���zH\{g�y�4�9��'Vӏ� ��$Ƅ�{nbhƇߓ���7�ڔ�k؏��6�v'���+�ܪ⡡��â{]��R�d�2�B�R���m�\/�M��"aD���ݝ�.�&���r�������Q=w-!�)�v�5��5W@Nل���+�Ί�$�Lo�7h��g��A����K�1墒ZM2)�h����n�e[�6i�yvT\��O�aQ�S���Um_U�,UP�>���~N���W|�a�?������|��o�C�*��m���t#NB�ֈE�y��Mxz�t��'��9�lzp���q����1�6��<��B�VF�;�#������EA&���$/�$O6�,�	fѶaY���c�Mo����$D&Pn��T	�?��u�3P��)5��5��l����v_5��R?o��V����R *ͩ]ب*]�1�x�,�A���X�� ?O,��V�e��ր�C��2Ш�i0�1����F�P�0R���r#�B�YDd�A��jx�Dr<;(pA���Sr�|�f"So��B%���+�r)�����J������(���m���$�	"[`��n�
1o������|�7��Y�е�n�f�����"~L�E<�f6���l��OӴ���lwU�|�V�?�&qΨ�7�{8�Tm���A��w���l�a��#%��S]���
�WV�G+Y�� !����S�E���#z�<8u�J}Xa�����j���)�C��n���𧥦y��l�������CxOzi�K���$�1E�B� ��r�;����ۗ�(�^�\�ʚ����@�S���P���S�n�ج�x-��,��1��d]5��ĈWv�s�7� �t��ĳW��QЭ���H����b�F�i��9���f?g���f�#yH@Gʴ��9 �r���<w��Tx]�<�W�ҭ�6:�2��֘�,�~��hMRlS�o��33-f1���]��o7�Ol�_JY�R��)%5�28�5/�_Y����[Ž)��e��)b]�c̈́����N���4�~�kf<�5}�'6خ�E+�3O��P�YaE���eW��p��"�"���~�%�_f?#�����H�~��!HD�3�l@*wh�u6b/=Z���F#�*4���-"=��xwh^�	e��t`s���9x\BN�O����APwitWv%�lf�7%M��91;�z����=bI&��}!��d+a�x1���iI)�o���_+5tWw�������lŊ{�&�<���q�'�,��i��1}l'��]1��\�lO�*����'[dЧ��o8M�+���Y1�Qgkv�s�@_o%aE%��_] ��=����(��cmp�u�I��i{Sx�.Z���q(M��e�mS��qO�{����A4����P�]��$�s$!5�X~>.u� z���ܒw�\���ܑ���T��7���[9�R���Ǵ��J=_��F����t�_��'>��z����[�k��[�C��Čy��>i��vP+{nBy�p�&*�3�����x��teU5��Q �*�y�>�&O'yOW���!��f5(Ղ�����˰��]��*�;�?�/��}��ڡ�L�)� ���K�sԐY�����]F��"����{���% r2pDp�RR�����D��t��1S�#/����� @�{��.C��g���KG��?$��I��P�4�	�"0��{D�Z%�U��D��Ҭ:l�'W``���q��>	�յ&= 2?g�4���ng$6!1�����%�ۉJVTT�ܷk[����3=�ՍO�N��,-d����cȶ�| a�kaL�`�i.~!���Y����m������sFa���	�v}0)%�jF���h  ��i/��TM/4�+mkl����˴�����+���>\����V����r�~0���|C�kL�k��%=���S��u\.(m�*�Z�>����6Gt`��ccQ(�u�AUmq6YD�2+�y_�إ͢���Ȁ�;�'*������H;gA� ��O�vI���z��z�j��s�s ��/��Xzg�>�v2"ɒ��tP����4C��<f�7��m| ЙgYS�Z���/�/a�TQ����$W��NN�2�������J��U�zyԳ��F��.��#�89ҋ�)�Ñ�T<�҄�@�T1��5&A��7Z��>`�5+k�\�#���h�(_V��:h�2z.cw�0�l�;O�%D���#Rg��A�6�:
%�a��]��i�v_*�!uVdRD�h�x�9|��.9j�v�V�#�'��_�`�$'�ݬ ���7���_�O�tXt'��}זN�㷰�EyA��k��6���CO�����&bn��yZC�c:'��	��2���zl�4��h��5P�"� �a���gs!at�kҏ�KL�1�U,5�h�൨)�V�Jâ)����KA�BW�Ry1@��<ޠR5�Q���J�0�T�]ws)(�c�-��J~�!iK-{�4�^S�e2�&wJ|�|=�L5�X��'�*/�B^�5���~�>��p��閸MU'OA���-�!�x�POE�Fsr�6���������k�`��
��]Q1E��γ�/���Y(>K��eΫV nsD�xMЙ�
�dgi��Y	xtY�-{Rp��n����0���@0�~�rت�X���Z�n�[�з5�д(N���F��3��Q*N�l��JT�.Vf}dCBZJ�惕p��%m��T,D�i�qK:����,��?��K�5�O�W�k�&�4aq�,�|� ��r{��+�fX-\ScKq	H Q�ռ�ߜ��ߒilV���b0u-Ψ�`�0n�?t؝[5k�bWlá�׊��֠`����um�oZ�����;�� U����|-�����D&���	l��4��щ)d}k��r�81�	��	�W��Uv�����:����Ҹ'�׹m���+�!U,е���C��x�}tub�-��u��)���M���@.>e����bm|�:Sp���/��de�ۈ=�^�r��L3��}���X!������#��B��<�],v'���P���@�߆u92�yұ�iռ�SS";$����$f��w�D}��>�[eWw��9�	%�����"9��X9�Vcm� �a���כ���4�K�:�`%q��9g*.��sW��V'U)��H��o��0�~�����9�+OBD�G��˹�,4��D��aC�I[�	eioJ�9��3�*\N�c�y/�ok�V�_�Z�q62�����O5u'�a�\���g5?�y�@�6�t������}C�����.4̋Z}����*,ʹm���0tG�ۅ�mu�fN�+��O���<�"]x'�.���h!��q�1J�|�"%�k��e�
v����,:q�Db(��׸)��aƬO��J"k^	.�BO)��X����9�.���R/�忸����jWnom�O[��` /?{���~��ɼ:��s�O���� ���L��� hP�<�9Dik牌�<�YS�0���������ة�\+�
FJ��]���
��(��ilr��6���yA�D	�Ҥ{2�n!��؇��w�7'9x㓚��R�A��{�R�d1�e~Gi�%�O�r)��/$�Ϩi�+jK��ވl|L_�'<�e� ��^:�V�r@�ǜ^=4/?�QVE�<�_�:V	�^_�m�`DM��{�k�z!%+����A�縇	�������La<����1�z�7xo�����4�����ܙŻ��-4ciVf�BE-�@�|V�dO�	M�n�)�ULtf��!�za89��"Ӽ}�Y�ȥ��Bc��Y��~�$bS��6QU=h:Ű恎i�g�1�Y�@�vF�%$o������X�⨄dF�a��8���'��)uj?a�9-b ��Ʀz���;����ņ�n%����ML�%�0u^	��tq@{0�O��fPq#%���~�%ț�ѯ�p�q�Dū�@$=X�_5���ũ��OZ/{Mh^qaf�&,��k���f�S�3�]��i�����qN�s�
�xf�E�+��c�L�m�E{�Z��&tP;uw�ƌ�1`O�]]�<?��z��JG�K�wñ�g�6=E`����h&۱�Zx�����m��P��G�:����9��^�w��l9��J8�︿\>���.��ϰd�j:���X����$dڳ����'�������՚�%�sp�"p�܀\r���K��E�H.�.c*���0��r�O�p8�YO��XjYCs�T"k 䣉ĥ�/ Ee�[���������{��[��v������8ൊ�<����+C)B�X��{ܘ�zi������0���;��]��E~;}�1U���t\��â8$��}��F�C�7wN�>F'����� pj��5F�_lҔ
,Jٛ����N�Gz�C�CkD�_�P�x�Cxl�A 0�Q͘��T���5F������������8�1�Pͣ�LM��Q7�c ���[�J���rW����2ԛL����,���i
x�b�I�G�>}�Dř�C*�/n�F�b�O�&X�ñAkR���
4{7��:�0����i� �E��]��@OA��x �s�ꤱ�n.xp{�9�A�)�d�x��Đ���̀�zW��F_`u�xY��k�q�^w��F�nر@����6��j5��?:���l�Q�R�cp=<�?	��J�W�?i����	E%8y�c�M���I�؀/�2���
�I��W���6�����aiч5r��)G��gE�$T���7{�`:���܋�P�V���4�܄�E$��aa����fY$7��y"d��Zљ��2� ޓN�
zџ�s�������ތ̩��}
38��d�Aզ#���k�#�N�AYe�F����)F�l2�bT��;��A:��ѧ�J���id�t��-k^����1�/��孾����)䣽X�2*��RA�U�PR�i )|�B� Z�Y�[�y�J ���C�`3��o�c�ˁU��B��n}.�+����Nv�P`%��d�8�7�6�m��Lo[���� ��_��E�j���-W��*3���Α�=:g�4�z�dO���H8:0�a�ΏѦ�H����Ovgd}�;a-O���k�K�O�}�b(j��&^ȅ���=M�]��<=;8"TF��Y�*�ug��^����Â�
ۨ�k��Dw�iN�씧���@7'�[�ZJ�"W��������f�����&롳����I4	��QCJ�l��h�����	�&�G�7ly5�:������,8ѹ )K��6�=�cq�]�U��;��3�ʒ��	��M��.L|��Z��H2���0��a<_>�?��%/#e��.a=�X)z������X,܈R�:C|�z�\*%�7�?#�!!�j��̜`���X$ih�v0����3^���Gj�EH��/��ci�B ���ْt�]2s�qז�*Z<�[Ц��p��a��l�G5�]��s�e�ff'�2v:*��4����W�c(���d����э랊`��૜CzH����������`�aO{|���PK�����~�;�)�7�*���Є�OX��F�`���`t>Fg$�����X��Uh�mW�2��V���)�iy0<a@�L��m�̶�.G�ԙ���Qo���*��=�wg�ܣ] ��3{�NP�6r��.b~{ʓ����5][�e��ʲG��k� ��W��[eL���R��ݬ�&��nu��& ��ڜ��I����j�D�'Š� =�����TM��/����5R���ڝ�HL���MKb2������Y;��&� �.�a4��xt|y��-�v�y�R-Wr��t�=y�i#�+���T ��Z�g[�Ee𮕍0;!��F��4��2�}ʠNK��%;���fiM=@b��O�m���B0����LӪ���36����봨���v|>
}�k>CKm<�
ˋ���_`����X��޸5�����|I���t��ՔW�g��	�?��J�)'��Ҹ9i�5uא�#Sd����w!�����A����CX1x�������I&��X੶ǧ��^���{ȡ-����G���Z�_9���y���Y�j:�΍�#񥘑e�:���p�΁�����x��B�������+*���v�fw��l~����P�:�I���bu��Sr�Խ�G~q��={��"�u_ ����3����ݗ����!�2O�ŗ�Z�����I"E�����0�@(#B�dJ���Rcu�\RiZ�V�K���p`[�	�ln�����N���d�����r��ꣷc*s�LLsG�.Ձ��~�̟sM�|�^=u6v�&��w{��ޮ45�<%�a��1�̕P�k�63��0�=	H�e9����hI���	S���jxk�K_j����9I�S�M��y���k�ߢ�q��j Ր�F9��Te���"L0w����9���%�P#�n�مY����v�Mv������F��Q+�~zL6�{y"�&7eyِ�����Gni���ڼ&w?i�2]�'�����U�L�/���V�RKÈ�_���(�;/v�},@H[;`~���)נF�^���0��p��}�FpR:D�z#12����0�)�4B�2���{�,���#���-�yo�F�������sҷhfSM_$�Y�����`�o�K~^�2`�aF�c�e�Ր�E�{�=N��9�{�-&�|�xw�~+�b�tk�q�y�EÇ��K��3g����D����?���XC����_f���8�ܝaQ�1�Ƚy�M�i���УD:��41�&*����s�T������u ί�*V���$��I�)[Q2W#3mES^M������� ��F�
"yx�<�t��~�̿�6���s�L��|����A:�C����4/���~®u��<�-Q`�z�$9�;����1�TU�C�2z��P����p�M�Np���2��P�l {d�������ݰd)r�� �Y���fn��},ô���=<u%:�H���XoD�~l�'0�����Aǥ�����z�KD�\�k�<Ja�Hd���| H10���x��z!R�%9�-�RX�[�G<����C����O��g��~jM$��(�ڻ mi^޸' ����I�!xHkkv9���.��U��y�rrBn�JA�L�"�2ǹ5��L�k:�3�ib��®�k"�%$Т��o�TQ���y�L� �<%*م���ڱ_�t�����jQW�8N�o�0�-���c'�G�w�,^1gn���G���7�ʂ�l��t��>a�� ��q����e��u�SΉ�[t8��Z[%6�bZ8sr.ǡp�)|8�ȗ\��8~�_��(���F��4��Y���jK��騢�����I�4Ru�/~S�i*�;��.��h�:鉀ğ�V�o�P�����ܵ�5����@-4ؘt����3�!��xd�{�
�h2�I2nf�S��ǹr�V��A!D�h:=eӠ�kx�����$���<�>W��.����a��5ȱ�e��t��v�oe����pX����L$�A�m���gW�QHU͹;�>�!�4u�suvJ�T���V�:��k0��j)�������`Kl��x
a�{A).;Z'~?|�� j.��C�1�{�ˌ�DR��BM�2� Mnq�	����� t�{�I�9zj���L?�ȄO���'�\i"�8ډ5"<HX��������Z��](�E��!	�<��
��(;&"�Iz(��R,�C��洣(�2�[�gx<�!�h�o�y׷��5!�����0��]j~�k������6}Y��uB+�)҇{+':��p-���d"��D��>\�D[�W�`��3��ї-N9}��`���W��fC5 �K�zX{)��Z��3sr��ࠐ	���Q��7�8+�\�T�<��؟��7�gl�*s��d� �l���@�т��&P\�GE�$�����"�d*:!�0�%3�+�S`|*J$�Wٰ��jJ�2e�}n�=,~�/X����� �[U��*QJ�GWH�I9���{^��b)75/:~f$��Q��T|º���̧hK��m�uJhYu��!�T^=���	����}�L���7�앴�!y���ӊ�P���R�[��Y�`����^�(,��r�&��Հ<"RFfMƨ�=PkH6�Jīޭ�����p����;t���c��8��)ֱ�g�YM�>�J��k�¸rrz����g��	�A��Aɪ_��=���/ح^<���wlp��9�9mKT �bFA�(�%d-ߒ�B��V����\����o�y~�I;��̸3��N�G�J�5�,�z� t�Ho]��#���"S[Xl՛����w�<��bΟ�aS��1����������2"��5ƃ�o�-l�Y���R�O�����;|�]|+s�����8�<��@��4�
H.m4����A@�L*��"M36��a$�&ѐ������h���LZ׺��K=�2x{9�������%�5jx��a^��H)!�vBC�� ����0��T�	咒�F�U]Y�y��b��A��>mQ�!Rfj-ә�
Dd�K*���
`9iKܱ�z��7��8K�%���H%���IƁ�����A�k<3Kj���5{����>�vW����� �'Rt�Ϲ'/��T�8?N`ٷ�-�MH��N��#�tS�As/Ժ����q'o�)��`�T��ػ�Q�A�P/di6����#�~'7��}O%I�N��'#)�s��F �����D�}T�S������>u�����T�\����'�۹�M�G�7O� ����{^�'���&Y$�s	1�\�����'|�Yl[͑,�"��ټ��.Jk������68a�*^!�0I�P��d�����R�6�������<��|�b;et_���H��w`�AU�"�xlJ�ޫ� ��S���r_Ra@X�.��Sm�E�+��
��v��;zt�՘��� �����e�V,EIh	�=��	?$�8|�����T���C$@�{`���ų�s�ʾFV�Ok>�Ȯ��	��'�ŉ��=����5���S W��z}8��9���º=�����;z33�R�5�xb[H~�d�Q���K:v�{�����(��1���\�3��e�a�Z�:Ɉ��/al�:���˃�ʬ�~ߧ�zż(F!,sC��R�5vc�f�����F��=7�H��.#��@&�;=���4US܀�ӳN��c �d�iw
��%�fv��x��{�7r79*y`툧�r�|����`a�����>�, ���n���-Rc���l5�����4��F`OƜ :kdYp�T
�y��Ы�.�`�%�_q���T�|욳"������W+{S�P��*������JV�fǂ	���h��=��^y���[��A�SQ�[ ���zbM\��9�U��"�Tx{�i�8���h�Qo��M�b�6f�:Ee����r��?��T�Ԓ�Ձ�����3�s�G�u�K(s]-�Gy*/.��)E�=�[МS��d�sm�N�aDd��������Ҍ���}�rz���u:���g;E�@wՖP���,��}?O��� �O��9��(���&��*�!g�	���85�E\�;L,���H�O�YO�6��˓Bq�7�g���n�D��u��/M��6E:�b�gQ��N�n��R�B�F�hu����~���@sb�~g��|�Hk��w_�����z��l�g�T�x��bB˨�I � �A��A+d:+)�����q�psRD*���}��w�L�/���mm̘�i��/�f��u����D���N-��������V*��=�����t��
~P牎$������e��W�h�8�p��,����!����D8ǉG���]��j�u~g�p?�g��L���d�ti����U������ �+`��B�U8����} �_�	��l=77����T���i���n�n�l�-�h����"���P���;|�iJ7A%t����|��!ڔ4:��(�7f���:z4Ϯ�I$"���g�آ����Q�����@A�f������h��A��(���z��(��S@��k���]�I L�2�t�my=t��V�y�ڝU���������A���>��gf��lS*-^;���I�Ѹ|' ����s%ad�T�]Hü~ ��؏�)�#�rb�T_��K̍Қ\^tq��m��/(
���9�)c�}�(�0�$�Pye�������6R���-q�:dq������SM]/`58��Pu�����$e����7��%y�ۭ�<9��lҟ�c%��rKh�njhz	��hl�)Du�8��M��>���,��.6a=V$�v5�F��(���a���L���55p-�����.�H���{�ҧi'�b2���!�ޯb�Q)��Y�n���5b٭���߈@R�tnˡs����|}G:)�B���~A��J��8�H0|�kr���b`v���FK%e�����G0�ڒ�G���'U6C"H�s�zN��h57�+�x�ic�-AƥxD��~_O�c��%���+�|lИ�MS����~�I��[�;�M�Z�HǑ�cب�@���X:� �r�6�xS�1��}�æ4�C�r�B��4�=E��y8�����`��s!�C��Կ[�9o��wtÃp�V����X֚���`YA���o}�	l2yFtD?�~O=Rn��B�҅G�kZဢ�0�яG'�K�k���˂�_go���l��u�~�g��+yf����Y�o���+��MB���,�e�z+cA�N�>0zd)D���|�|��\�!B�]��pu��8z�S�s<�p�g6��f\Xv�{��t(��R�)_�ϝ�����p��g8`m�h]U��V2Ό���2�z�1������ܣ]Ao��{¯����:�����r�����Y�ƓB�4�s��H��93�6y�S�+(w?fdC\c䟷�!�<����y���~��m�����I�Zr�<�j�ѾC=1gγ(��{���Q�;���V�0�_Ū��h�[��և�iz���P�%S�fޣ��`����BI�``���2_S�/b�����~_�`���Y�M�nsW`a���H����j뗠R��WR�=Ľ�j�j�"%�|�UB.��H׾6y}D�I���xy����Z+WL�~Ƶ}�o��W@ɯu�����Z ���^ZX�L��J��7��z����K�[B���\Q�j($��&�GF�Ct�ʍu6�6N.�aB	=:�f�Ѧq]k�[5���͵��Y������[���7��	��O��@]w�yi*�o�$��˃�N�zy�|����ύ �vؔ�-!�׬�/E�"W+P=�s�eB���������6a��"	��+���@��RAb ���Q���P�/b	�~  F6u����W��q�2����TƉW��;�n�j������MD�HI�p%zi`�ڃ�۪���;��G/��8g3���z��i�zj5+a�n$�1���ؠQ��k.��l�W(����3�%����P�	�ޜ��X��8#,��2+DV"��EP9f$"A�1*/�@z/4Ae銜T9���
�}w$�TP��D9�=�噡�T���%<-�����d�8�>�3�v�j�1 �)k����9P*{���o|fd�&rrAɊ�g���D(�󳯭@�ZK˺��H����,W/^;���+�`��k�}�FH���0)���-3����I͡G��.���H&�vU��=���R*���0�f�Q���=K�}��p�e/E��O�( %K;��Wjy}�R�1"�`w����u�(X���K���Ď^���X���)i�V���s1%
j=��j�"��Z��D�~�>� �߾���F�ȫ ��3�J�2���� ᶤ;j���>pD�:�ոeNh �
2U[3��3�'c$K}�s�?M��q�, {����D�,se�~r���{yIY-4�&�q��5�X�E>�J)�4�g�40�W�Ӎ�ѽ�M5%����zr�[|�H��:��`2�儏���6lZ�0�3�kY�x�G���JD��t�G��B2|KZ����nU����� ��^���l2������(g�����-� 
�(6v�UEG��-�t�V.�P-��n�$���f��T��d�H+��`��w_�l�y�ٱMi��uv�_��⧓��9��O&�����]��@8�6��Ȉi�A�����]�(��'��m���[1l���?b8$�B_�V�w�غ}G�� J�*s�
F¼��\�f��_�����z���dPa}��p���ѸPZ��[|�b+t�ʆ��&.7Cz�I���!}��%�oǫ߳��N	�:�S�?�W[�
����sPZ���ޓ'F�oI�����FƗPe��FA�r����\:If��Kg7G�K�ᶈn�೗p�����<y��/�3G��[�ι����ܥg�h�禖*)�9[�55�e,^Z����i�L��˱`����z��uRu:�p����f���ω��{~�.6���J�^<����U��+�cQQ��b�7�)��+_�m�k�3�T�?=>V�0�{�y$��T�f�g*
�Y�|��|ۥ��F}>N�Gmf��v��V����_G�|�Z_pӫ.��O�{"�,�N��O�V�#	+SE��c�L{lл����C�.`J������-�r��؍n's��:��%x���B��*~	 M��<t.�H����5w�t����8�q����D��c\W��8kl�����՗�d�@i��4E��R�,|F��;��`bH�9E>}��D����$x���P|�����{�)�-�X���|d�/\�(*n4I`YR$I�����mW��p���C�*�^5�6Z����-.9�5d��]2z�N�v$S'H�
�,�P&f�5T�9⛿��8zRf�f�k\4L�=k�S^.���z��F>z�T%w�{��N��^.͑h�U��+x�F�Uj���a�8XZ���Q!Z����< ����̸}��Q�mMê�����؅�.t��:���.��\S�&�w^R�%��g´r3p�Z�;-G#ä-��1w]�Uپ���)�m&z:��_:�6���&l��s��b�]�x��:g==X#n�Q9G�6fK����:����(���a�Jm������O C���-SK�^+`�B	B��A ��ޏP���X ��?��"g��hC�5��q#�D�f������8bP�=�z\����5�I���R��yw���;���_��`���FRn]k㉠�'�V�[�3�q� ��r�L
��Ƥ!�|�ӫt	�~�o��	�a6@+�k�H��>9�7�kMAQ
��{���L(���9c�A#\I�3a�:���Pm�N��/��p��b5���{���,��Y0b\=���9��,�W���:|^l{<����e��)-�!%��?����� ��F�l=E"�b�uS �	Cr��dT�~1�HX����3���������}�����"`���^62`\�'�����`k���X~Q�.'&�>�e����'j����o�jk��ќ�C��XX7y�2����GS�:�q�|�2�U"s�?�X��)�+�m�#���u���D[7�3�P-��U�r�q|��26��N	��
�P�-���v�z����y�ui�m0�'�vlK��J�àbA^:Z���:�)ߍ�ձ�n]��?���ٶL���P�qF&W�ϓ8��*U�4^`V���/w�t<�af%�`��h�	��{�������U�:W�� �V����Yp�tA��a�R����Km"��@jX[s�v���M������@�0��1ht���Q�$�K��9�0�&���1G��!��1��~&m�%�U��G	��W�ۤ#&Q����ٖ�2�����7�����Y�&�M�	��UT�D��R�p�!lpEc� �2|�'�N�7s��z<~)�&�X}��G�L�4Hk9?��ӰZ�/��&Lm��.�kB�xzh����>����I���Ч�%��L�j�4�>�W���@+թ�꜁o�����u]���;���ޜ34�.?�QN���o���@������g��1���AՎE��w͙�	���ؾ�=n���������j�
��5^aeH�\&�Y�5�/]#4�Z~��'f�.��S��,��^�",�%�[��[X� �E�V ���s9���woŤ[���l�U�2��T	�SL���A��ys���L�ib�@9���h�7�p=�a4�.<��m�Yg�$�oG�h�AM_��dF��0�3�Yp�C����'F�l_��a&��q�#��oO��#���^�'�7�^hq�-�^|�F�/`�۠�a�Z�E,�Ғ>�$��酢�[���HX7�ʈ��(����7sſ���y�_������Y��iY�
�m�/n�w�Ֆ50.b�b�h>7��d-X�2m"JA���34�?R�a�J��ੁ�:��$W���Py�JR?��VQ�0h�dXq��f㟓A��xM�m�f�X������֓�,p�mU@ӂ�@i��tk��X~�p_(��sK��A�Cc${y����-�f�?��p�S�D�(�i�Hh��Mj_��Ǻ'�(qu���̫&Ô��\}��0
�.倈�Ǎ�p��_������r# &D�B<�DfXBK�c�"��|m(����G�A?�8:7n��^� ��Bq��Au�E��3�����ꙩ���1��ۈߣʩ����V�M}����u� :��ʁ����gܢ�\\- �-	,���=�N�c}��e�y(��m��/pD��'u͌������	Ax�uC/<"@4���Y;�l�PA2�l[?h�E�ɤ �g�eVk1�Z���_n��#9�v�Ơ7p��H驼�������F��4l�{��%���.A�ȿ��Eg�U�I�����L��R����8�E�;#o���_&�w�?�)�՘[ȑ8l����Qb�>ф^r0�gf>�[�C	偏;g2};�DB���	n�.��q��!����Cq�Ð����Υ%�G	*��WO��+�F=�e�<��ˉy�7(�5Y�m$a^dh���,9o����=�A-Y��_�b��0�{����Fd����g����3�����J��HVEK&F�'[����� ������9I�P(���D���.�O6�o�Q�=�#�O>e�e
V��[sM����A�qЩ;��	�@�Ķ^
��R���cbRس;bJ��2ȶ��n�������ٳͰ��kn`�//z�d绫��&���+��N]�("P�͒�=�w{��Z�<���Y��#+���6Y��[*Įy�7�$�����͈�}��|���״AIϒ�WG#M��@�Aq���zұ"&wn��/��\ҝ��r-��A��7�V:�!z]��N�I��-d�m5dlx��"v�@I��!A�m��%�?v��,v\� ߎ���>�I�Z��};��
���UE�y��طb	�6>������(-��[�K��=H�|���iM�CV? ��@	�pu]��&�WX�}c����������|_���;�⍘Ĵ��b�j����l����\�6U�5bl]@6�iR?@�y�ΚS�#�z�С�yL_���z�5|��l{�d�{-�Yÿ�o�Lg�:W>�a��H��^ ���"}_rS�%��s�����z�a?�j�~���M6#�*�ޗ�����fy t)���X�G.~�R�3̜����wC��	���'
��+�s�*�"6�<��_Nz�����;�Wc:$�T�/hQ *>)��#
S��s����bꃮgC��ݜ���魠�(�뛮$%��Ceq�vW�&�V��&e�w��"է:A��YW}�l�3��i����"�I'p�jzMn9{�/��֢�s���̟��(*�L��wM��k�ݳ�>�]>+`��Bw4.˘Ũ��MxH�5����ȯ��$��i*�]P����߶S�'6U���ާϻC/@s�H�Jix6tV�|��SB���Cⲑ��LM��YJ��}-�IR����JyUD�Il��z�YdO���B�Y��Ux,���hv;��|�V�n'�U�t8���Q���$����wb���������܄���k�N���c�V`:��V�Z*��%J`��;ލ<��ݗ��՞5[m���e��q�6��BT�eI�p�gdGp߷�e���7d�6:6����� (���xk
ԒT�_�hpGd��Ѷ5K(���+;�L)�o��m�l�M���J�Dp�z���_�Vk��o�ӻ��k����"��#������E�7��}���M��K	���Qrw>;�$�	�,�������=y��
&��n8�K~�<����x2���y��K�B��j�1�<�_q]a �Ӧ����a�=�&����]��T���bs �)�ڞP��`�x�ŋU*\AS��� �F�~
-����"z�����?�߇�'��X���S9���&f,0N�8Ҋm�6���)���$bÐ㺟K���6H�U���<nRU-��c~���p�(#:x]�Za`��0�d�đv� �k�:8G����"�WC�t�J2��j-H��##&�B����p�2_���X�N�O݉�w������zA��D���䆫h�7= 跫�|@����Ŝ��3��E��y&��1"[3T�}���&h0fQ��Ӟ�w*i��EE�|�$׫��/��q��hO~J}O�k�?]O8����q>Ȑ�U9�&{f'�$P˭��j����A')�]WզBq�iR�HXe�Xs����eB�L�G�"9���`d�
��˲�����Z8�U�b�g�s��E�uv����ʁ쭟���=@���+�6�R�F��SU��)�6�jG9�g�K�U�̋nR���Z�A����dS'��w|�nv"�i��Y�}4;*L�O�<F>���Q�|a�Ӻ�;.��@ �9�P6*�h�)�-���1x(.T7_��l�l)E9%����:{	q�Go�-���&!�@Ǆnw�J�}�U*<��H��j��E��ez3ҬQ�$t�e�|-���������+�g2d����z�n(�Ј��]�c��w*�C���$�e� �r�~E�k�����P���Ӡr�C~K��3M��Ʉ�ϻ�ep�%ҴA:�����V�sy�����U+4�zȓ$f�Z�@59��V� �(�jgx�{}��*\�q��Aq[#�8;t��&��2����W6�O����ZuKǶA�e'��*�
���;�����1!:b|zM��85O�4�!�ι��D5z�O�Õ>�	�����C �O�0�N��Qn�h�Zc�ʹ��u59����='�<��K�����(���x��Nϲ��)ȸ�{[�q��W؃J�h���H������_�$C�;����� f%��l��y�b�m˸Q榎.�k���������h�sa����6|�� ΂s�d׬VwX�Ž�C��b�!�z���QH��칝��2kR�8��7'�i�#�������d���:�Q�o�>��|a��L0md�J��̈7����0	ŝ�v?}�� ��F�2?H�;2���_ގ|G���an�t�nvp4�.ˠ
ː�1F3�+7ʥ�����*'���bJ��x�!��#���"���܆,X����2>O[4�#a��dл'H���o��#��R_��si���[��w��| �FR�3}M~FT��Y�"�w�io.%��Z-�=3�o `[=o����c�T���	�.���;l�m�.�.�*T��O��!��Gb�]�_���|�T�1,Y�K���Zp��8�ѝ���K�����������T -�B  ����<��� �����/kޱ�g�    YZ