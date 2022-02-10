#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1136148317"
MD5="72ea630d05d2b6ecd67e5880bb69d14e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26000"
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
	echo Date of packaging: Thu Feb 10 16:56:04 -03 2022
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
�7zXZ  �ִF !   �X���eM] �}��1Dd]����P�t�D��f*�WA;���@������BS�9���׾d�˥�^�
7��o�p���kFбO�ޔ�a��s��Mc����5�&^��3���fp���G�6;�D�i��n���I�m93����`��	Tݳ(�Y�%�"��+�m������b=ݍH��t��f���8��;nB�����uK�56�-�������'�;�c��+�+n�0F��|V:�B@.coUH^w��=�o���[)Y����������ط񫩕Q('Z^
xh!+ҧ�1�9��w���/_�����K2*�>�Z�Y�w�1hi�v��1PH.�Q	{C*X�_��o������K��c�
wc�Q5�O4�	��B��^Q��]���.����&�բ����)*�u.8Q����N�3Mg�f�P�0��Ő��/��%V��I�uͳ��c?Ǌ<|d��'��B�A� ;�*�b�R����R(���-D/�Fׯ����ek�B�|�=gPH��RYZ���&�d�n���i�5&b��%��=���J
�7����^����P��ڮ�X+��!�r�ͮo��VUt��hs��RZ����8��ň�8�q;l�/�O�ktL�����_����e�g�qw��o���̠h���ı�_�5{x�dL�&���Zϖ��P.���(q >��"EB9��J8��ۀ��XÖI>�a̖�N�����ؾ��ґ��}��ȓ�(�)W���N��%���Z���1�O����z�Ԕ\
�E���P�Ł�k���`��f�ƿ�&���}�6�0�d$r8���=D����L��W-�j��pY+T�Κ����,�����$jJ��?�o5}�|�k��dM"r�ΐ� �G��no- ������ y��C�F�����n�J��Atg�U��L5������9F͠9���5�8;��LX��>��(�+Rpv)Y��MD��7r�vc��F鮝FSvJ��>| ( v)�Un���t�'�;�="��2a�U}�"���=�#U��h��Av�f[W�x��1#���ކc�w`�7@q���I�QQt�7��w��u�)+ɲL��w��˦3Jo�X�fY�o6�"�NlQ�g%1�Њ0r���9�bM����(� �#DD�\Ŗ������:ĵb��X_�c�eS�D0����Wv+HV��A�	S���G��]=F����d"�Tӓ�_ފ;��Cت�B���^��)�f|-�&����dڜ2 W)+������tRl����T1Q[wѦv)1���$?D�CǞ=�%W#�&x���H�>��ͯ�,�e7N�*_���
��=ѱ�h��Q��xpm�X��Y�mi��@��W�y�#���VM�ܩ�������C�Υu䕏���>p.�f�["ݐ�5�U
e蛞�A]�r'zRv�����q�c�e�zϦ�Kp3�yH��'،���j`P���n�N���D������бs:*	;��i7���'�������uM��t�QP�QD�ǽ�2�R�gN��(ݞ}"��1az����%�еj5:����"�F�?����t�@d����vpz��wy�^�N��9Q��;�:�x��!�w�.f�7g(��-�I�+�
�/�	.������s3�Lq���\�����o�E���V�k�3Nq��)>o�O�ӽ-$��ZQ���8��v;
lbHe$ɬ3�p�Td��nM�}d��6 R^\�:�nREnh�"�\'��QGɞd�|=�4|h���l���^����^E���2;Ni���D�ep8�<!\�߿4?���ULiy�ŋ+�,Ϯ��I��g����f��\��xc���u���4�Ÿ�^"�Pa��#>����F��=ACFo�D�����	��@=XHB����� ���
���͈��!�L��pXFږ#-W���g3
�ϋ9����r�4i���)`�t�y�=L��#�.hm/�-�~1Pw(�H��~�6�*;�Ko:�C�_E%5��N�=I('���ntzbO��������d�!%�/3$���E���J�H�'N9'��O�!���Er����P!�
�=�H=����*z�M�}�-M�`rp����b�Bn\^h��N�Nw�g��q�7쐄 I4�2�-�]˓do�l<��]�͹K}H����(������4�õ��Z=��`�Ԭ
�ag\��}d��c�Ee�r�~��+�1����m��}����E�)�(2`d*F��\\[GX�=�Ìl�X�����h���t���W���������[M{��*�����Ԥ��7���Hl4���	��W� ��u���V-ٞ?��@.{��uq���y,RdOq�h��£S��2��ś ��}R̢V=�mp'b�.66�J�Vu�H��l�! C錔�g�^��B�q��qM^k9���Z+����`f����@�uL�� ��4'���7���w����Ņ-���sG7أɴb�� �M�>N�P��v���7>�;a�|?���)���-hԃ��=)�d�F:�W&��l��k�U�M��A	�&*S�L^��%ݸ��r��o�"�� >�3�r�,��tR3|w���_{#���W?6ˢ���k�8�q�=���&���kb�A�~���-f����W����^����0^	i �)B>�v�O5�JF����ANt�6��1�P�nE�)���M�"u.��n������-?9RX��_I7��A��X`�2np�f静�` ���S��zRE��k�CT�����u��TS�B��8i7��:0�$<K����#Y{Y5M�iNU�׺NY��u���(so��ET{
N�깣Ȋ@��Q�-�5�U=t��xR�P.�.h4��w���d*��3bK64 J6���ק�H�f|�HZ�B��(ù�2g�tNR����?�� �����i�@�K�*&¡���/�U�3�^�Z{\Ӌ9���&��+)������(nR�x�wN��# �f�cS������>�{|����Hj�|���y�j�i�jK�4��	�6��X�W��8kH��������q���_�=p�ҟf����T��`E�J�Q97U&s�U�Fќ�wo�-�g��%87#�;A�����hy޿��ҘN%d�t�/����8��ZRyd����W�|U_qNB�?m Zu��]l�カ}�J����S3���p7�(���qr�~]?�}��29M$崫�<4Qׄ95�U3It����]�2w�)�$ƫ�G�hb�obB���Q��-�=� ��� 7h///1��WΧ��/���{��dj)��f2E�^t�诸V�����aT��2��2:i��%-�'1�D;u�H<%h�| �}p����;����|��B���q���A sv��8��`�S����%��t����J@�%�d���Ma΀]6�F��#2!���� ��Q�<�,gj3S̲�f�+jܶ�hc�x@��6͌�J�mԕ��c��ڶQ��K�V_G0���矹�y0���~��B��[<qt�G�!�k��8��,�����"n���P,����53e�q�)�m3�CaVB�,][��&fws�8z�Ne���ՙ�d�;�$5���l������V�-��Mh�ijI��]����C"�n�5����� m>!L3�|�F!�������$}��k&�	��2u��{1%ݕ+AqJ��Od��|\��M�1C�+V��:�t�l2�')�UU׷����)Y'�&���V�7�[Q"1#�j7�kθ�j�����_�	 ���Y�������qy����Ȉ�/��<e��'2�%�k�����n����Ֆ�9]���C��+념�9~J�E*��b�p"��u�r>k�]a�z�9��S��N���*٧`�������j�g�	�<�nl+a�܂%�n�`�_6�IV!ʔk7��s8���MjZo�F
	g�_N"��j��6�ȖF-�V)��L��\�T�s�c�L^� oYo��M z��咰��3��ݡR	�����]��ִ+�K��Q�.�@Vn��	&H{�]qZ��	��1��&������o/�7��`��r��Ŝ���=�^�#�/O��.�@#L�8�Zx�	J.ͮ���ۍd��j�g'��)|c}9�!A�'��>|[͏-US���#tGO�fR_p�]n��?o����iՐ����ҐK.c/���L�:g���d���l��Q0m3��O��)��&���i�f�3��sel}�9��埓��qg��r3s��F��V����%mu�Ӈ!{j͖�:��4[6>��j �k��U�� �� ZmUЉU�~Xߨe���Lߗ/ɧ�љS�H���0�Xشy�[�3~���/��D����h.��>��u��㴁�9�������7wS�*j���~�����ka�M�YL��Y�a��/��  �.*}�z�����v�3�u��+^�fЦ���3���j���z�.���!J����/��uf�QFי��� ��(8k����=S�*360.�ڲ�C�o�0Mx�k֣7 ��v���;��q���b���^.Kf�/:��l�!�A�\qæB�����߶�z�ך�ֹ�iG�OİĻN���h6��A_��Ez��L��/�m�Z�h�ȚTb�5hLl���G��[�2(����i�>r}���A���h�:��+x�s�.h��&����|��:e�+?���Đ��mL⏞J�?l�o�*�K��'`#������cV� z�J�lc}�T�D@}����Ys'�.@u�=��d���"�THK%���?���O2 �Ќ���Ȳb!
�.k_!I���3Gs����/ffn{J��1�TɻE7e��ٺ�e��e�̳��[&K��0�b�c,�(B��.�vGt*�s,ż������)΋N3	��׋�ݶ��m� Hy:(ֲz՛]q�k�	s���Qv�UF�h����\�s�!��P����^�d��"����7��"�O�J�W���Uc�H��0@�Ѓx��_�%�4���ox���s
7�--��"h4ɵ��iF�-=��-#���:��B�M ���d��9����B]��F��8��z���(y�c2���*NCOg{s�ݮ}�hhU7N&z��(����S�g*;1��7�vu�Ռ~]j��8u9�>���3�8����h*�L:Ē�^�TaXf�;��+!�k-���m�6>�0�3R'6���Ⱥ��|9��8n+{��6
|��p[��G `�(�_�'���|2��p,�9mH%�8�p��)Y�	�u�Eeޝ9��[��
�����Hm���B��t��5/�>�е�Qxbd���8�ui�������\*[�a��7w����{f�_������I�בާ"����r`#����h���fm&�Dy*e��L(P��k�� ���ꁆ���+d���8�mry���o�R:zF��&\O�dd�.���ᵁ:r�#ăqa�d0��|��	�F�>�!�y-SӸ������#�u1�Qn汑��X��N��|rP͒�_vl1-$�GA��ň^T�x;�7����Gc
Tx�?R���@6� '���V���� K�P["�Fe�ښ�}Z16�r8��C�Py�{��6e��$�툕�����̰�;�=fb,m�ť6�.��ޕ���֘MN�B���X����>Y�.�"��-'=3l?Z]��O�+� �e�վ��3YJ�gH�X��������nd�WQo]�P��GF���DDC������x�m���F�(�$�2Զ���L�dGF� ���j�<RY9@��@��#'b�7�vo�4vAS��j�^��C1�nN�硡W�݉�<���g�X�S[;v�믎�����jy�����?��%���XEy�۳�
 ��gwBG��(L���3�9z�����P��{ɹ����:���"�z>�޺�� k0�y#e,4��)%UFm�Vן��)�nʭ�p#���뇢����q��3����[�D5�qX"M&O0�)+��r��^��V�Tf��]ԧr7�8�!��TlE���=�׾�w���t{���^f�������a�������g�[�B�T��ˣ��-]�j�&��4�y��S�7��6�Cֺ]c�躅��:x!0%�S*��]�H� c��s�'q8{�3/z�~;�+�P^nC�	6>ǒlˊFM<�6��~����[���J��{p4�V�����S!�^�ˬ��@㨪u��M�p���q3�2 �J췛=fp=r��$�w�Oӈ�]�X �#e�X��E_�,W	\�^��(]q)A=罅2φ=��o�>��O��WpOG/������W����ZbF,qR������Ls!��EX���8o�H�I�� &h��������9:���B�Ǽ4��	>M�����U��$f)�(B&j�x�E5�n�.��ab>�j�yu�/�I�ߌ�'V�Xb�5��i2	n�hAd��o�I9���K�*J�g�7���3�ǃ��	��1,�i��j��mO���������?���z;Nv��R��LR�3���6\6�q\g�q�H`�/s��Z�����'v�ϔ�
�CZ/�R�Mo�[��uz��a��������1������y����������( �z]�'u<�6��?��������֛����V���'�-ҭL���=R�a���@O�;~/��BٛY}Յx���N��F��~Oh�~��4}���t�{/�j�p��A�Д=K�"�\��+݉r=L��шHB�g�5�M��v�ɳ��[�?�U�nX�s�Y�.��t��hhix��ԗ��El	��O�uW�Y/E�3u�$oǥ�ב)�՞�L;�rɥ��%�8[̿�ܷ�
hz?�/yMW�{�"�|��ɥ�e�t�T�(2+`l�%TZr�L�0�?�Zy�+��3�/>�^+������y#J�����]��g-�����BUgNy_ϣF\;��I)]�V��|Ow�pmk���	^W��y��^sL������ ���`�-��w�}����7��_�_n��f��%Ϭ��Q ��p����6E�oe��:n*(!mV�	Ђ��A=��� sbX�/��N��lg�Џ0����-8l��:�7�k��u(՗�ʺ�b�+))_���sx,�h��M�Y8��ct½�	M�@9q��~}E�UÝ��B�z/0]���-�LfC��}������l
�����o6���q�Q�6�#ˇ�Jڋ��)4J�C�5��@���@�!� EL �?n뒚�G=_V,i�����SW<�T��'�1	F�����vw�t;E<�M��<��o��6@[����?�	f�O���g�!������F෥]s��wr_�m^Tc���
���^���WhZ��"r�k��]��x�BN�t"uX{��$�J����N�b5�_�.�}Gpދ�'�m��$�q�u6�2gst����������M=d�77?J�1��l���T���9�y�ݱ�hy�!.�Tf�M�#R�2��Ci��v|��m��_:y*IR�u����v][ä�O%�h��ｲ��-p`�$
w�����*'�>A0r�W��]�|.��U�XF��S?Q�����{��p|��³?C����G��`u^�,+H��x-��7�]g=�[�+�=6�빇�2� �z^�r�+��#��m/��}����%��қ^�r��i��� Q=��������+���=�2/$@�Ni�~��p�$��K
�)	H�! &�a\���-DmpA���W�2�[��0E�RPSJ��ޓ\`�&n�O����V][�%�42>���;��Ğ��x�R�gȩZ���%��Zb�g�e���z�dB\�L�șN�*��x9#�N�&�6&��\ߢA���ޝv�O� �G�j�#�� �cJ����}��cBE�Z��fB���lb����UѸ�����aU��eapG��B��2�����*�~�&@��]�����Ai��eV�u�����)�>"�,����^��߂�Dy�t^������ɪ� \��
2GĨv_�v-�z�����RCv��$�˿��`�sp��A�hP��%��pC��@�N��tA໼��Zt��f+<���s�ר*���*���$��(U>��N&(t^S�
C$��xC�F0V��z�/nO'aң�=}t���O��� {�*��K�lb�`��e}[2���Z�cF!F'�S�pA�K���c��u�I���Y�G-�rY�x,�Bn5���;��p�C�Ĺ��4km\w�N��j����S�Y;e���۳��h�������cdx�����qLk�aT��uϝZ�-q|�Ө�uS�bBŋzCB�>��	o
]V�k���7�L��hܤBգ��=��kHN���Ƞ�ȸ�Ws�{�߫�XS��	�
��zZ�\K�˃%��S��+��߰o��dD9Ŵ���	�^�ĵO�Yk@���Cs\7��^���dG/��?$�=�
�#+��
p�`�,B���H#s8v���X:����Ŧ�����]��5�~<�i��l���o���b+Ԡ(/ӏ�'B�JӸ\f['������pO#��6��2�g���l̏Ċ�����Ҝ0����n�wic<]���������b;g�CL0m����T�g���7���y�C�+d�����ߜB��O=�Z!�ʫ�H���KU����)��)ĺA�rs��>���'M!�"�kI���avE��#���W��a�xj]��Bn2�FE)��P�G0�����]`�2:[)<�����'��^Ca�M_K�Y+8��!~���kpxN�W��F�HW �`�Qc�}­�-�?��>Č���lv� ��i���Ĺ��!���T�47<���۩�DM�Nw~�^y�z�c�#�J�L�~�{Y�½�B�~���ζl�֯�?Ć,Ƅ���"�����p���GH��;,��OjήU	|�)<&������c��2Źz�D|!��Ⱥa�)7���>�d���"���餓q��-�]�:���It���-�g�1�>a������WR?������_�!H55^}$���0�N�l���ޘ~�S9?��;)�SSJ��C& r�C�A��	U@���ů3V��e(�D%���\x�y׃q�$�da���N@hٳUe��ݡĦV�4*���ȞK�G-B	��%�D�[�*�&��c��V̝0�������_y�W'4Z�7��eA甓_¿�*p��M��R4ӒLPr��s?���l�\���!1_��%�+�{"��i�����i�OS��\�� Z�g]uS�ܗOU����@:�MĠ|�e���|PK�8���^J��F#yö�����Y�$�y,@T��]f~�[�q�~خH5:p}���Tp)������o�!��?���
����Ł-]����63q�>�$s��0�r��I�2v[��K�p6��T�> bp86�x�\�7�6�N��h���B�>(�ץ_�T>)v!!����2"��܀q��=CWZ݊y&X���c���0��.}�����E��E�.�@���i]��y[wL���Z<���FCp�/�v}m
�]���2��܇o��x�WEY�qË,ͨR �F�6/��0���%_��sG҉�`�_w��1�5� F1ӬtEθ u�[�x��i��}��C3������#�����vl�{�tu�u��@�1�O����yU�!�<�ZT�� ��0�,�����i�T���ۻ[��ls�������K\-Z���Ӑio4D��|"�ٓx�Cay^�@��$���/s|�x�T�?x�������4�m�N��{»���G���mnl�j��;�a�oe�Lt;�b&jx�t_	��!�r#x�or3b����Vx��¸D��㺓)�QQ���%�:"<�c���UpƂ�a�Y���p�C.+�Pv?\��^�3�������9�	t��)�p�b����W��C�f_��o��4�t�ՙG:�n?c��ѻ<�QlfAHb����ẉ�`u�D�ᮂ�D�5@�ůI�tt��PA�lXCe��i�*��b �ǣ
��R�d�K�1�EE�S��Eұ� �Q����mK�:�k�
%�4��c¹R!]���T07U���Tqc�K���z��G-<  � rOH�����T�N�r��@��>�J��K�W�Na��]Ȃ���bЌ��}���d�~���c�?{��@�bd��D{�X�����]!��
;��B ,�^,�g�l��kt�"�Rb�$`�ӷm�$�
� ��*)��@t��D���$���z( � f�j�$e�k��ƒ�/[�-�xAf��'��KH��i����X�i�"�^l;����B�=�(X��������\�k�g�f"�NCͫF8����Ŝ/v�$X3�J�"�Xߋ�������x=ݡ��үՀv�����@�:�����4�n�B"w}-�qj�
�4��I���(�j99	~�BP�7@�QX�RJ�T�w�zY�?�E�ev�s��I��3A�?�Q\3�����Ī�΢m�^�{gP��X��a��]�#p x��n14��6ː��s3��i�
4��S��X�Ͽ
H���<��;�n�K`h������#��X5ꁄ�W�m��|�*`.���d���ۺ� ��Mdk�asYO��~�W,Y'M��3G�`6��t�vC+�@��S��է��I�k�����<}���BS�k-Fآ�s��W?^hrm��]�c�B+�+���U�� ����e�gs��� �Ib9�/�R��ѿ�Q��@�w���*���I����Q�j
�i��,1�H%k��>M	�(/F�ɧU�Q2B ����:��[����J7���^���/�N��^������	��x5�RdzUU��P����'�}f&�=:�3~�����v�U9iq��L4^Z���<��P�'.ȕy��R*�ǀ'/��*a�!��"��O:3��w�@;���Γ��/�ay���� ����+��i��]�x �L������!∜�&���ȓ�4JA�U���}�24�ժ*0�5>���uo�+	S�BH	h�/�$F�g�����2z��Nڕ\�/.��5�S����O��?��%y� �Z�Z���r�P�^��s�R��w-��;e�Rh%SI"�i��9	3_�w<<]`��Z���,=������{�����9/U��p �=���p�ٯ�k�7�����r5c^�"p�����.�K�|�ውpxoI���P��2�ؙ/�To�J>ci�eLN��Y�le��8���<b��J{��jZ����N�܊�̴Q5��������ug���&%-�HJL� n�گ'_Vg
Ā]��_�����;����� �7	m�L��2�5��2����hs�}N�'�[UQ׳)�Uo�k�)�� �3�ն�l��ťk~%ub�g�Ħ�?[V��Z�q㚾k-�CaD�$��	��r@wg���2�2����:���`�������]����0�h�x�Ϥb-
�{.�q��b>Q_,�i�(�K�6����,|C�������[Gvo�5Q�?b��q���h!"�:����2�:��9&��C|M,m�9<�Z��LQ�n�b�b.Od?��Z��*|h�Ҫ붛�S8���v}�|��'S*SAA�.��"����?E#�|v����t�m�*�׳�4b�����t��I(&�ԋ�
��������@,^d�+ߠ��ӌ\� �ŭ-%-���%�/ �H�z�À@;��MYD5�vsS���m��}If}<�o 2��8�~z��ﱞNz�f[X�m,�i�����kl��+P�NN�D[�!?e0-JF�)�&?��Ljlm����Z�
L&t-��li؅;s(1�w-�PL����[��b��������o8�v�=����Ȥd��
ߟ��Zv:�� �>�:h�Z4�&��Ι���M����}�ouh��� Y��J����rw+2���7"�m�`�a�@!�.%�6�a��(�x�Gl�ՀfW]Խ�T�M���2�]��/�Y�3��J����J�3R\���̡�k�uזS��_Uw�����?7y�r�^ ��� ���l�qQ����K+}dFm���T�B	Bs9p�Z+`z�~��E��d-ކ�n{k� }�ᑪ�^��?�!rFu��?�ß������m5�_N�f�Nh���>?O�}W�s`ʌəT)^�p��3�'���-	3�pex.t1 ks� ��.��\��_�]2��z�Px8�f�tIi-�l��~-�:
��ܳ=�&#��L�
��kA˾L�%:1p�e�K�j:Q�t���2����1c}y'�|��mV�&7�At�	���������F}_�yWb1K�N4���"�5þ7;)��D�U��V�Qq�u�����0"�`i�ƻ����ƖU.�x=�#�Z _>��*���|�����,}!��Fd�*^ߪ���M]�θYQ�aA�qǅt(�[�)3�&@��/j��0���sXx��ƺ/{'�%f&@������%?��C�*�t��~��-T��;�^��6DR�z͸;�.�r�2���yK�s(&��91[	���E��
��'�鄩��t��I*��
g?�T��(k��ZY�wM�֒~:��_#��=�x��m�|{Bacv�W[yB �����M!�a,�l�v6?W�STy⿏�0�;9k��ʅU���ng,:h
�����A��������d����0"��W|�P�h�|�I��������c�3�Ck�B�4
GZ|��-Z5�l���ɉ�B�[x5�6�+هzSP ؏���g�'PtЀ&)=��为�"���!��m�&k�
$h�Z����p�Ɓ����M�f��;��lb�B��c�e�]ޱ<�s��}��3�w��l/sH�e�Z(�ꮟ��OC�5�R*�0�x�ï���J�7&wJ��
�\���∰�%�'{����#B�D�>�g�pB�)? �̣�ck�W��m�g�R����G�^���u��:2�yX���-�������!x�,�NɧX�%����h�6��W��iE0��)>)o 7^]tEXC���Ѫ{�	�̹:)P.��e�8��=�U(e��0\� y�ڧC�0����Y!�w2�
��=���Z%�@}�su�|欴���� t�!T�Z"\��H�:}�v�>���/��_�]�⚇+��ӻ|��;��(K9-�ng�����>t�|�9$y�5 b.�l�K`Khiz�% @52K<�:����59{��M�����̡����O�)۾�Q�Ǉ$��$��6�Z������T��b���qr��C�/�bn��d ����W�pfk�8���لށ?̦���Ae����`�w5x�yƃ%܌gHFW��I�Ǣ��]ƪV"R����B�Ķ'�/�s�`ўy���(��i?kp]w�-�h�u���B�p:�#x��nۊ~����x�{�|g���eU��w?�5I��Z��ď�һn�*p}�Q
�6Ј�����	4IԠ�͏�I�w^��1. w9(������ʺ%�Ios8gH��������sw�����J|;G�m�l"��@ߋ�-�\�G�8:>�h<�M��I6�WѤ"CaL;��T�2	������O?�3r>��~AFY��@��[�X�aм����c�}�佾H�@B��㍚���芸��$������;Ӽ�ψ��� 36���(�t���5�?K5=V�؅�٘��s�obt�kjMop����4)���L̐�e!�9���(h�xi�|~�I�l�N����.�E0��mȶ9�"j��j�.ƾku}Pf�F���*sP�$��؅�z�PJ|�"t�� �RU��'�<C �$�^򥁱�H�z�7x�l�zl=Lt���h�E��I��o�'�z)Ww�wm!U{��������f��8��5����s��d�mX��y-
�V^�hܿ��r'X�gY)�.�!��r�J҄��ܠ�c���r������@^�M�	p���ل{��GW=l�,��Z�s�����J6��wo?��D9_ڣ��j��&7w^�BJ���5�fB*���(c(][|�Fӏ229�/P��"�D�g85��F��@�F2�h�6����U{���,�5�x1�b߰h��(��~�^�)\�%�c�����?�.����E�
Y�܁���IU4NB 蘆}l�e��kē�򽙆혊��v���?9VF$�ë<Z����.��2ێ�_��$��d�L�G385O�)�Q����x�@����C���"�'{+��j9^?A��Z�U���%�*�?1?�Y�?3`s�+�m�4�\p0=��;�,X|��&=+?>)"޿��D�!M?%QU�(;��y�����B����k���A�L�O����T���,v5�(����?)�TY�SV�]�n��� ����Mb��q���-���Q��h�R�i��,7+�xE-�-�m#H��;ٖ��/1}p;o�rc:3�ܴd���\��=�k� �,]�X��IX=̟�<��Fn����۹I��N��?|�uë1��������N�y�A��V!&U����Uq����k޳c2S2E����X��;|2�'�9&�}���%I=~\��4�ŉ|j{�_�Yj�!s'���$��0Hᤪq
,/��Dw��r���|�����w��O%pb*U>C�͚�F�O�I��6^%(zӫMgxW�6����n3:�]�l;�L�X��-�8����4,������[����|(�uD�>���M}�^���g�9C���xd!�^^S�2I�o��xGn��-;�p��)I�:�4$o�C:���<���������/�3�x'��]�-�|T]tC��.���(���
h�҈C��p����)!�p���y�>\Ӑ``!��`�B�!J���%p�M���=���A��HZ!���Ys^���T�h�%�w�9���l�Љ\J;��/`.�<�&4�@���R� �;��=/{7�� �0ǿ3��j2�TDc����dN�����j����G��BS��C��6��O��ϹK�+�ܲL��F/j25����(IC�Ԣ&��]xVo�;mf���'�p�~�8�bI�?��,a���h���5���6=C�5����
�mɕ���˵��m��4J�e�ٿVF1DC?fm�R5���s�qB��b�_2� �j��9��s�+�<\�Q�3(����8qk$�Sg�neFi��߉(���c�Awқ�?Mkv�O��Vů��ԃCq�aO�A����:�����z�h�6f���=�>E:r�&ME"���(������1�s A�W<^����e+Q�2��y���G�����y��UJ�2�h��0Xl��}3���V�~����zj����i*����@�)��=��� �O�����;(��S�+⇈N��,�A_���� ��)U�&Vi�l! &<3��?o_��� ���`�����	�,���r��?��Ņ*�R>1C�#����#$����q\U�_!�6Y�+��XB�7%�{�*�����gΛ�ӑm�(�2SZ9v@
�w8.�0�	�n�㶮$�h����ֈ��6VR ����}���X����6��՟���
#�����Uj��03=���$�ق�}��n��q7*M��:���=0��f��V#�E͎3�Z6OҨ��H��y���l�D*,��گ,Y�S���)DuQ��x�5sXx�VK�Tb�Ѽ�D5�w���l̉Q�k�
�S#����/V%DZR^��+�;�9I����*���X:`��� �R����B��ݸG%n2	�$�� �	����v�b�V���EH�R��z۩�P�M>�y��?l�������8��s�a1�S�bf{Q}=Nz��x��턿4n�Rc�o�Uz�F�|��.K���:Ah��c�6�GW(nSd#ˬ�*�~�Mgss\�LS��Y��r$ѼO<I��Y��7NW�{6���ļH�U�̵�,)Y=��2�~_,&��ԡල��.7*?���Y� F��[Y� �]G�2mR��&O�w��^��'ۄ�:sz� (��\&|i+���T��'�CW�l��B��4��;v���i��k$2�"t�'^�^��}(h���<���-�/H�B�k��+����{�-���b
�$��J��|�#�^9�R��b�*l�C^��W �W��j�� �l������lf��Sj�ϧA�qq�Y4p�x;_�AD����`��l�|��Ԣ�����q���d��cT���r �
�Us�M����0,��$80O_9	j�AKUL\`�Dۊ<�C��7	ڡ���<�Q����8�%(y�>/��gY�mq��)��64�@�����oY|{�[�Y�/�+�S�:�4�;�0��di����)�t�>U��:
���*q�tUa�N��)�č}.{vD�1H�au����}$Z	��Ds����`��jl�����\�rI�� ���,٨����N��g�2H��r�x9�(��)�S͉��U���X��8H" U:�$zT�[�7�.p����2�"G���굉�E��jk[��HI�		f
I��Һ���(���m"|5:B �V��{��_����* x���]'��&��X�HZ-�V�|q̵i^2^�.wSv4�a/�� u+#��g�`ey�=�����:�ϼ���l�_�=4����I���K1֞�N<7=zn Ί/��60�/r>��vh���?T(
��r��ۥ5g{w_��P�rc'_�ò()h��D��e�ϳ�c땠��G�4ᬊ��ǽk���P�	z4�\�Mt�q�ot�f��sM��1�̊'�6�γ�IA\Q�x���Ui����{ZecPж���I�DҸ�L��	"����36oS[(9Tm?R�E�3P4��C���:��P�L�V�� n�{��2]i/�a�&1A�hwN��v�pi����ͭ轹�:(�{�K ��G\�D����N�m���3�p+�XA�	נ�AZ4mN<p�y("B��f� ��^4}/�穥J�Ԟ�N8/�~��d}琇s��m���8���@$B���!jG�H� ���H8��
���w�h0�h�V�nuk�S��j��Km�x>���b�i_M��:�dm���W�����y��d� IF/6	�[a�@�L5�ά>]�p�2=�6Kf���2�&.����pε�[�d/������N9;Z|�:UM$㕧�� �#�D��ʀ�[DD0&��E�n�U)�>��K�u�pNg��a3���d'x��̹��^�Ю)$:x�P'<��ZH�{߰P���o�,nZp��:/�(���?�(�����l������GXn���2��5<G-�{ �֩�ƻR�f����ê�.���"������r`+����ʝpڐ�o��T���v�����^K���j)��&/�����	��r0�|dM�g�׸��(v�2��[����#j���f�a�%�zLfנ1��]W�ɵu�'O�*n�Ԟ�n��y�~��h~։��}֍�
�m��֞M���b�m���	�%�^fSY�r�� /,)(����cV[��������T��0s��R�k3e�Δfs�h ��s�#�o���g�d�G�w����lE	Qx����V�I�/��Ôr9Ո�(i1x7��.�q��yB=&�9"ٸSS��G����:FH�I���#�y����,�����[>�G�$�=ص�F6�����5]�c�>\��c��d#;�bP�����9�[˖O�ʕ�)����,4-H�����6[[L����}[��<�Vz>/�@�uCd�ܶ������W��l�U�����B�&�y�Jr�V��r��#E�p�>�_��H6�vp�e�����8�m��d?�Qg�U���[Ջ �ￓ�jժ��nlU}�/ԇQ�'Wt��R=�4�VN�"�&fo,v�u��
��z��G���Hޕ0\:�5���#��>L���2���v"/ҳ�q8��)���c�R@ft1�Wņ�<��>�P�\�_4"��G)�[�H�-��7:�K��RVHQS[�믊�d�r��O�����W��t�f�s{ �{1SV-����	��P,:�=��Z=��V==�m�<]ط-#I�y�����y���k����.��R.+/��r~�&)���8-�OD���~U;yX�D1H�{�`9�Hm�|�k��=4a�A�}�6h���N������9P5�r�'����kd	Z�?��b��)t!���%������MTɈ�hs��OGs�;q^*�e�C�-C cMbĶc�	b!�!8��ϧ�f:2`B �H[�29H�d�	�68�r���}�T��=4V����n%٧�誘�"��ǆu�������k�n=���~����:m��l�pR�	.��v�#L��UU{��ȼ����D:p^�g�y��l��B	�I/���u���z��57���8;:�7�XC�DЙ�
A
g���s����|��Z�TҀj��q��]�64�O��b�٣�p:!V"m���*��DU����3`s_�5�b�kM64���lF��̪v��<���`|S\@8�fn��'%i<�b���9G/ү?!�33�k|�>�j��4��Ƒ�̣5����2�F�E��ٽ ��(ƭ��@W�v�r� ��( �CR���
%�A׌HBܞ��Nx��;�������"��&Hpe|��,�X�ܛ+A��	���7�h��\�A`�j���P�[k���iz�����vkPe]J�-�EźY�{ˢ�"�,���3[t����ܥ��w>�_�WyI��/�D69�2SE�~��>�W,��	���[%aUvS?Y)������88k2	��x~=�AͿj����!�5_ʳ�����:��J�5?���N��nɴ�J���˶�؍����s)�g�F���A���;h�(ljq�������Qu����4ǁ�c��{���RK�oƩ�f0�u�a:�k��.eJAo4��Xܛ:v�*G���Kٔ�1�
V���ۓɈ�����x��Y�غ�Ю�k���<
s"x����bg�
�
 ���zj�)T�5~���%���)�!�>8�]�?���q)޴p��H�M����nҏkZ�|.�����<O�鳲�DVM �I�uE��I[�����8�v�>xŸ-yֿX��Sr%�\�/V��yyKޖ)^��I�7IzNd�w�b'sU� G�_�Ӝ�xb1�'��m��I�r�����<�y��D�Z�V!��ov�5�N/�\
�ih��v4�ċՠP���{��MV�����[��/g�u{����N�<M�/�[�G��bc��$�8�˩�'rup�9�D�&[A�Wձ�Oi\+�7��_.��ԏ��#b��b� tȏ-��>�*n�H��g-MS����2��|�R;�X�(������Í�fZ�j��p��ʏ�ܯU|��Yc�b5t<�������3�1J�	���%d�/��r��c��VP�R����W0}q�:�G6*k=�MY3�H�i:\�U%�x��k��JDZ��'q���;V��z�1((�
��yE��v~�oCQ1y��nd*�R}��!�?#0�� ����uƵM֧[w�{es�U�q\� �t#�z���Gc�$�����heltIm���Ԃ��9�8<f_Ә�h3�X�%RM@�Y�R�fݺC��>�WI~��b(��P��WۗvV�j*92�@I�,Bݮ[L��_�.ދ�LT�V;��>t���ܗ-p#��f�%��l�!e�\9�J��ã�o��%nP��GӅ#�fu)��#B�eY�ILL6��>/P�=g�Z�՝�AEe���~�K]W���Z���������9]�͂�/~;u7(9�/�+Ql;{���&)Q������bJ�4���+�Sgmm��g3^���D�n-	�m�cC��t���T���&�7�8���Ojr d�S�P�5���$��lÜa/��a�)�TE�W�HRVڷ�1�5h&�Ҫvu;�՘ ���	�5��m���F����i+Q*�@������k�=�)�X��`G�M4G������*�uy3'<���[x�������2��R����&�A���t�V֊�ֲ#�If������������q��d �
5�{ܲ�Kkj��v�m^�5�ԲS�z��2m̯�kgx+�ȥ�qm_U.��*�ń4�J��Ios��*�N�_+R}S�$�_�"}�l�5R��Jx�Y�A�'&��.�ꐕ�߷�ܨi������:��0ӏ��F�f3ࣴO;!�%$�y5��v��i���a{%4&�*�;����viZ���.�P�y�:,#j��f�?��ǯ �3~Ek/'��=�HY��	�Y,[`��#4yz@��-�E��K�J!tp�d�;�3r�Ka�{�򄪕I�,��HH�@���&h0�a?V�H�"O*�.fIJtTP"-���A!��m�Sz�&�D+�?��vhͳO��>��EMS@2�癴øz��N�.�����!`S�,o���aM��ZE.�?ɕ,~���@P����H>׬��29�u�
��r��D�w�7����/��¦���^��Ñרу|�F�.@|����q����iCooM��j_Tn����<}#�0>[���4�-ը��uc�P7�����=iO��ϐa�2lUfj��ʾ�H����8���R����0vMi�JMa9��6	L�u��c�&1��ܥXX8��)ȑē"�vs��:���K�0��+�z64m��19-��E���0�U�(>D�UK�^6��<z��Խ&���:
�y}ة���o����N��X] �/*��K�{s�,��]�
-W`nd��Id�V[��^���dJ£����V[+� ��hgM4�gzQ�Q����9��&�N0Pz^0__��C!'}����E ;���P`�j�|�P��n*�O�6�g������>��B�}]#aP�M��`g���(,���V�Y�<CZ��>7@D���J���Z�ZO#m:��,Ñ���O!I��u������:ja[�A�O.;����߶]kN~[��A��ɜ���!_�b�����'��|'����YF�]CQ�u|G��b���2��j/ҹGu$�7_ݗ�a���t��fL��� E9�Gu�P�`�B��%��'�9Ζ�� �J�QD��܀�kU�+�&�w�Z���;Fl��s�U��|����B�J�چ�"q��)����7�q^��0Ŭ�!�3ͻ� ��N�-'ZN�E!2H�1l����@[���9K�&��<���Al���Wߓ�[�����9	D;EuC�b��\��PS|��F,&OH�{bx�x�T ��Z��mV���xB��֙: JsO�~�0DEf��Z��l\X�1.]JR��R�ZJ�ybrH���K��^��,p�
w���E����3����L�w7a���H�߭2���� ��G
!�}�<��\��f��)��S#Ԝzl`m��A�0�2nxK�*�|��ֳ�Ͷ�E;�����G=��a�����T���6�S��hI���0�:�i����Q��h-M*��<��L��@�id�&�3-���o�p�l�y�c��3)X]�n�n�Jj'���:�WT]"�m�9��a��'S�)'�J��B����'W�<>@��t�im�/`��cB�W9m���)��aGM�|𗽵��3yo�5��)���q�Q^#���A5����2�݄��~{�{#��/5C��|3"M�P|ph�eYP-�#~e-�:��p�*�d�D҅����/,�Ǌ"ȷA�o�Q=(�d��ޚ�o9~#�FP��Ե,ۺ7\�c��N^�Q�%Q� Ŧ�*eE���2`� ��E<�M����_@��"j����S�l2˚f�]ܨ��&����ݖbbʿ�+?R|pɜ���d(DB�$�݁J��BY0�oWt����, n��]=+�5���J`�	�����Չ�E��,�@�+s���Bi5C*Q!���'*����f�������$��9)Ѭu}^=t+���ب5t�b9O�7��b$����A3��|9�*��?���8U5��C���jJq����DWYP�N���e6� 6��e8'"^��4�δ<2������|T����� �`��9 b%�jY�E$���WPp��!mw��4ǹ\<�!��(鵐���W��l0���߄���-��6���AQ�sWB"������D�SP��6}ְk��=�b�7�̚$�3�3�B���D�A"�*���V�B��І���;�B#��0w�-�������e 2�&/��Ŕ�3��w�i�����":�}�J�ID�k��o$T�AW{��8���&9)���&��V��[������*.V�6(���ΰ ��~K]����->
�"&���m��%t����	l�VW0���}�ڗp����]��ɒ�~��%Yu�D1M�	~z';�v���i�s�'�ٕ��uu�+U ֦�5n+���2��u���|g��5�m���8��լyz�:����Jp��~.&`�w��m�Tr����±/J/fx��Ԧ��w�ٸ[ɢ��b�:����������<�_c�+m���Uj��2����J���t ���>�n�g��Ԫ�|̣ ��Xf�/��}R�Y�e�zv�!��/)9="�@����#�whvsNE:|��:X����ӄ�3E�eɠ�4zY8M��'��0�v��rq�s��2e��E�VVͬ�|��9H�7�pt���k�vU��}�,�\Jca�Y1�b�}�-�4\H��sMzgR��8��:�(��{EX�!�0�*�8�yk��p�:*K��V�� ��:�%�3;t"q�"Cm�,��F����?�D��ҷ4���������zX"��gJմ��ԼMP��PB���ɉ}Ml�3o-ڲl�S��VK�n�`s5��$:h9�?�����v���}�� �텧c�i: s��,����̋7�,4#�YF�J�"@�Ɗ��b��q�R%L�55s}��KaK ���9Xh�G�*q��Z�ȭY-���` ��bHV��(�^���ˋD�~�X�V�ϭ�)}j��ta�S�������aCT��UH#���`��R�'22�c'�d�e��=!g���dWv������#����e���/�n�2ϸ#
���� �Y�E;?Κ���E��]�xݯ�|�tzɳ����CEl��k#��S��@?bE	�d��* Q�{�N���|lk:��n�,Fsxs �� ��`c,��!�xN>,s��+z�چ{"���&�.z�ݎ��%u_?ti�ȟ5��e�9��"�4�C՟��n��f�L�\o���O{`��,z��uP$��M�W3��'$��WiYuu�NZʺ9A
^�T&r@$��+��w@Q{�u޼��ZE�hĴn�)�<�|.s4&Pеʊ��Q�i�
6Z�/�y~'CE�E�T���
�I��-GKeF�"u�nao�} FrZ��`�l��O�I� ;�jp��%~�Ҋae68{�_Rπ� �r!������4�R�V�.�M��eǙ*��ߩR/8�r!��^ƫ�Tg�q� U{�;������ ��Z��#f��ݵ�V)M�M�K�� bFx�f?z7���x0�5�m�>cb���_q�1�]k�2E�ĝ!e�<�#���#V+g�:�|�!)�]�q�P�~Fv��|� �~�jJ���x	�4�%E[�������jo"�[��U"=���WH5�c�|��?�t-���EM�٨3"�� ZNr�����S���,�E-IVA@�V���L�
�������1	��e��b���y��9�㠺�\�:�������,>�
/�6px�N��z�sQ��oK,�#]�
��6���D�`D��GZv�G#��YP���{dqm0 ?�G�x��T"`O�����m�<�Kň��n��@�?�Y�J��g��|�����׏ݲKd�D~�&�+��4Ƹ�1�7{=�C�u@�r,1e-�˕�5+����a��Y��O���*jrk��m*0�0$J�c�CS�G�����o'�[��ML�˾n�Ж�P�en�-�AW	�-��[K?!���V7 �CE��v{v����%�˦\jVy1�@�껇r2a"�@��t4��J;� p���]@X��Eqh��Д4���U{���5N���=���Z�[ ���'��U�*���p�}p�J-�<z��zH8�ZL*#"�]^� �z�4��,C���ڄ?{�H-�wFN����K��3�1�0�XvY� �.CP�Q�8���틦����O�O��=��⧭X�c��A43zSt�m���VZ;DY%jRu��E��������<P�$hf�8���C�Lb�;]j�Z���B=�?�%]�.����t�?O�~�˘9��j�F�G�.3C$�<�Ow������8�,�b{08�k��*-���*.Q|�aò�ȠP
慺>������<z���������m79~Sd��3���oy�dȦ?E�e���sSN� ��HM.ʐ>,1 Fa��ܜN~� �i�����]n@9/Yii�	O��m�Lm��T,��R�6���:��8[.R�O��6�������ȡU��7~>z��P��w%D�����r�pE��S{B��B�v��.TT��/���UB_��h��a���z�u&�x����4���D%��ᘒ��ԓ���ʓtF�d��a��C�'��tc�6$5�Iy.���I�����W�o���&�����89�haQ mL��X���J��J��"V~A�3~B0"Ⱥ�<}��Ǧ�m`߼���z�!�����4���S��yv��hB���/*0��-�tE棿)p�_?���y̻��]�(�|z�}IJ�fx�L���ޱL��+a�Ŵ��ATƪ�6`w����2��e���'�<�����ʜ-V>0LЅl�ر�_X��$��U��C��)\��^�Rz^vj�+-�a��z����e������gUR��3���ҶQ*���i��	�:����g�L�B��?aĘ	h}��u�L@��<��eb�
��:�����}/D�% �����~�2��_\�䊇6ɭ� �3,��vT>�� ��b395ɖ'	W���%FG�[ڜ�t��/ỳ�3+�,A�6��E��&~�
��7�����ZE�ά�?zK��3!�k�zZ8���묳�����d���^���Hid1e��/��\_�~'.^i]~�Hc�N�>&��~�ߙat���NKQUt�S_&N���P
W��v��ߠ9��c�C���B��^�K(#|�Ě�M3��h{���q\�;�9�t����e�0���{?���ܥ2%�b��_��gjW�.�U�<�>ό�=�    =8u��	� ���� �w��g�    YZ