#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1381913976"
MD5="d613b14565e7ce7b0940bffc7df78f4d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25808"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 00:45:33 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���d�] �}��1Dd]����P�t�D�#��ϊb�b �V'G���&KR�km�%�E_itgK��<�C���$<,��_��ԇ�3���ϧ��1��9|�	�X}Z�D�w$У����{���j�@�P���2�eI�2��ês������Q�����y��U冲������s�t>�����q��|JbćRp�hR˺�ӏ6jQ�Y'��t��Q���>
ud��J�f��s6���ϏaR߻'Ż|XȰ6�+�Rg��$�W�(�A���C��gF\X�g ��N<Hqm�B"^���?Nh�HN��?��f)k k3��5?���w�	~���1��DF���
4����1�\��|r�RҢJ?� P�M�8�CQw=�V�>I��7�f?�u���Be��W�;�Z�4B�T��}8!���t�,90/:�����!<P7��4�O�{����o\���WZ��II2'	��v��+bWVnz[�� �-XU9=�c�k�1��C¼̈n�+��b��L�fょ��n��#�X@�.}H.dN��;��5�5|ԟ>PP_#8�-~��n5A�Sm*
[��]��?&2��ɐ�'��חKgr��s����	V�k��
l�]��O���d�4������L�����ͳv<ؒ�[]�������@5^��I����5O�����D� 
_�aɜ�R�a�I���e�n�ʷ'P��t�`F�E�+�wS�D�:��O�گ@f탠{���u��S��]��;T-D���j2�/x�i��� `zhR͟4k�h���2e�W�=�9�YG��x�:��'��'��Q���b7�É���0t�I�7J��$5%�\�)̂ýބb��<4�Ȭ����3�}KX�/>�h]X��
�tLz\Р�o���C!#z��8s,ekt����!������،}�ܓ!��Q��� ��ByA{gx;���\��'MŌv�kZ<BNΜ�A��n��=t��+�kg\���o��|M͘�h���~VV~�.�?�`1�P*K�e���Y�!J܎��yz����R{�R�O�T�.���0��@���e+X�{*�(Uh| �M��q����YP����"�RĪXv��*;Y�P�:��3|��:JqQcĸ�gj��9�8�@�0�B������Y�$ʥ�;�Z����po��5Pr3.0[yh�ƕ�ۙ����k����YA<?6�M�z�"r�e��ڱq}�նh&a�M�C��,�YK��[����L<2�[A��n_�%U����)l��b5.i+.*#E~�.y�1H\�Z�hgL>�r��eV�A#,�į\n��|�h�/�h�nS2Ȫ�ɞ�&:���#E�~�|�Д�[A�QZI��T��%��AW�c��4�ͮ;��m�;D2���Ňηo�	%4�ǼȂ�RhK����W�f�ؙ��H�y����nv�k���`0��kޭ���K�&�W9�5V~ޙP�`ԋ�S؞�P���Pm�vYuOY�X�[o�v��y�'�k\� Y�����!d����vP��hk��,�x�� ���8�Z#����O�����O���M{~	^	�X�1~��؊����Glj�����5��m|�'J;b[�6�<-p��3䲣��
���-|�Y�|Uv���o]�z޻Ҿ�~�d�HF�٩��z������C��M�=�33UXG���LY�JubZS�ҧW�}�F�ȾrzϭpLs��1�s��g�O�0[���x��a)^H5�_lb�|��ɒ���2N3��!�HiG����y�'�Æ�p��fw�Ɛ�ݯw�+�US�y�Hi�]/��ZٵV�ؙI�Ǽ�����?�0�J���K��,�0x�\�e:�����#ݽVy�
����i���I�%�?���&���e?����[�s���q4GPz猊k�/�x��
�L5��vやF�uyIt�f/�9�g�`��ޏ��`.+(���3��5���A����RF�RL�*�E럱}B��u�~t��<�I��H�#I�C�{vo�Qp�vf3u�ᅀfU�yX]�~@���b���Ǡ ,�1Y���u����32Zt|��U�]��-ۈ�h����զ�Ik/�0�����P���������dک��0M�m��L�h햃oΑ�;a#���ǚ�(����$pk�F�a�a���!K@� ~���6�2�(�@̮W8�Pԃ�0�Vtq�evszX�MZ"�`,�����_�^O�a��������G��q^�w�m"Yp/X�J�-�y:��*K�Ca�D��-L�IYx�fU�>il�O�'�A�-�·���L�؀�+�t^��#�|雺<Y���|󘙱�>�'e�-_�}���Dex4�U)��.�wW5O��k���9e��B0��(�iJ%"��X<*� i"d�_�g���S�� #dxN�6,Fl����а4��F�٢�Ǜ�BWc��w䫏�3�.��Ax`��u��H|S�ȱ>�g����I����q��\���v�M�=eI� xL��p�C��C^���]k�y�j��o>∽���2�Tޡ�b���̓���ЎrB�$��A@Q�i�;�߲���H͊
�W�J<ES uAh����\_�LФ1���_��L0؀�s�xpa?�����O8'>�d��%�aC".C���B�Ѳ�e_�660��X�S��1�]E�֬o���B��<�V�<m<e�y��[<%P@k���m�C��k�%��:2?����+���m7?��
=�܄O�����`jX�o�Ա�z��k/��jVU(C	8"A��<ucS�x������O�j�$��vH�It�s���F����K��Mr��e�e��c'1�5�-~v��0H��}����4��p8r$rmy����li������}n\�����/�'�r���$�S���aVq�%�}����ȴ�qh� >/:~�iY�U5��<��.75e����x�e/��$��YM;�rF�/[���[g�g5riҌ'�"!�o�۝j�Q\�oMzJq���ES�N>��OB]��}?j�Z���>3�+��(��PC`���B��r]/���>�4�f)�rl�8�G:�  �fѻ-��p@(E�v�N��qHD<BD�r΍���{J֧�{_1�S��I���SWŦ��q����':Y�1���~�Ah�
�k���w_�á�56�w�\y��(\t%��P�b�ޔ�}��k�'�t
eƏhB��J�~\�/xTag�L�9�̶�^��uNӝc ��p"����=�{;��E�iENn_Qנ��Sa�?��O���"����Y�,�Lꆗ[a3���������@�ڱe���'����ǅ�F�iڰ�c��F���HZ_�m�e0���W�n<H��;V��b�\>�ސ�C��)	���i�� �� 2�lмHR�1�������$O� ,ӭ�}nM�J��3��~��)�<�v��X��כ؅0�QG�"B�h�8��ӥ�^����G@E�$ܞbZl]j�i ��G"�4oWS�&-�ۭ!�q����$�zhV��H�mQO��V�� ���[h\
���(a�{�0(拣��տ��l�� ]�G+"8{̓B}0��0��f&^q���ǿN�@V���	���a����^y�C��TL�"2�Ǵw?�Wy(�����"��Gӡ�`�f.�1�@ͺ��B��˦*��oq�PoWv_�3���^��Z�5��{��O�:�G�w����ރ�sA���ln�ϡ^����3�LZ���1m�v��KY G��ȈoI�u`�G�ȳ��l�z�5��-���-��ԙ�ZE
�t�/(���7�z�B�?����/bzi�5�FNP�6Z�`��E�T�
��)B��-�"�'4�bS�I��:��4u����W��<y菟u���^�T��#���G[�x�+�ˁj���=���D&��?8�����<�S߻~�U�ƫO<�Âs���t�(Mb׺���J�]�d�4d��y���XF&7�5����E��I�~����^[�'�0۱�K�[ �C�%|^׌�����善C��4Ct�����R�t:��+��𠗛Go+=�GNR�f�}�χZ�J��1��𡻠��&PVc���t�s���p6=�n:�7{�ˌ/�#�_N&����`;̾���%0C��r�0����pQ����ϝW,F�P�2�w�G
��%�-M�'�<�Ag�>ɸ�=�$����D�#��6
Kv�g	���C@ó7Dx7��3'&	b�Z46'!�Ȅ�'i$U�2�Rb1�UVB�UV���N�@^&V<���7�n��G�B��S UH��B����r!@S�1�k���yГ�;�Yێ�Œ��փٔ�?����u�F���lV�m�-�z,�c��C-�&�\�3O�b$w�u�,���>����:�1�撏����_,$zwn�(����0~L���ݨ��l�EW|�CN^e`6��qHW�JjM�yR������
9u���Ov�N��>l��ŋ�C"�qj�?��4������9n��H'$P�p�0��Bv����tq~�џM�9{�ƴ�����B�;��	����r�$3Z)1��u���&5��O��>����/>��R�o5hM��r�9H�����e��2gqxyƌ����R�;u�_���BW	; �jpO�#YP�Z
��#N�ɘ��9�io\��J�@�t���ۋ��?hT�j�A˕����#?/p_��nl��<��$��Hm`$5�(�1u��ׂ����lh�V��+����ъ�U쀡�H�5r�qR���tV<�v�/W��/=�#�o�zJMt�fA� fq(n=�j����Bb� ��Zu��Ϋq�ü#�tK����xN�l�Х�9������a���C]j|��W�><Q�0�*%���._�#��rvM1a��>{��|5��R�SX;q1�٨nQ:��|���0�hsL�n�E�Q-�!cc���߁�_kރ՞Nh��WP��s&���/���8��U���?�a�-�n�f�֣�͜�v��@�|Xp"1�Ð�o�b��Ե�EV��f��]��
�<<J�鹡i;�/g.� �7i��hS��F�$�����n��`5s�Yղǉɐ��~|���Z���	{~�Q�CF������a-k���/�j;�[ QR\ߛ�S�&�H�(����~���Lք:���yؔdmë��XuϘ����
7�x�O*�-����C�m�˩.vP)}��8���e�3���9��o��Vh��o�S�;5=9�B%n�T�X�=�gP9����g�G^���$��;��cu4w�0uv��u@��ho�1�٢qA�3����e�����5���피:uA\��;2����X�J�T�jN��O8�z���%
�6��&)wtМf -sn!��"M�7H|Q��b�`7����<aI���zB��*������5}w�����l�����H����#�1�����p_���7g�$/)�o��D8��nׄl����9B��ж��A�cEf4.u��r=�4m=�q���O@�n��~��zSP�h�n����v��S�O��0��� up�n�q��� �`�-m�Y�2C?h�)�����!]c�8Bw,�n��up.Я�h�����qw��Q�a�v i�(��;�U��޺bmˌ:�GE������K�r�ز�5`�pl	^�]T��Q{��|�742���fP��wO棙�����?=[�7v��k�_w��G��se&b��Ֆ�P���#}kʝ��V%��ƙ��;鄄xR���1;|J��zj�k�T��sI�Ⱦ���{��Y����t��֫��I�Ma3Q�|�7Z�@~����\��}��^Q"�I�tS���;��Q�П����1������/�-���	��Uń�L0�{�LC�<�J�����������E� b{^��h84��g������R��$�M.��NuWa�Co+�M��n�H�E6/0x> /��04ւ�����	J�3s�V[�M�J5�H=�\��T�ϐh ��֨�)$����[�_��s��է�׉��դ�S0d96'7I"���C.��/"s�^3�Ɵk�o��������\b���5�]�;�]��3l{��	���Nр�9�wi�K����6��ކĈ�����NN�n�q���&�:�_R6ݻ��9o������o �Uґ.5ˑ�q�?+y2��Z���Ji���-0 �jr��]�� }ɚ���+�0�g����T~��Sˋ��(}��vNF���k�MԼ�����]�*$O9&^QS$���~�UD����c��^���w�@�o��8��։�}i ��SA-�o�@����ئ�'8>(�2�.*�m�%e���!��{��B�B1׺Iy�ȧL���s���8�+w���Ur��j�������9|��ػU
/r8*�?D�;DcJ���7�d6�}�Y��kPo}:��BE�eؤAe�P�R
�A��I�-0hW�)ڄ��D�o��\�&�0�O~�2��
��)=η!��y�R�S�ڢ���mg�[.����d)����"g�
�S��ۦ~ �D���z�Ha�z��sVT=��t)���:�Y�4�	�n���Ylok�n��	=<�7V�=�[��RF���D��#�?/W;�W���N��W�GJw�i7̉�6}L�}����*p�k+�H��:���V�0�%KTG	��C8ZP�bL[��lw�Z.��,,�:�ܒA��~ƌ7���:�gU���I"+�2�a���X��~Aaݥ��#4�H�g����!�,��E� �ezW����'%���?~u6�}��$lv0|>RB[��Y#���u����E����[j�:�4	�؏!&���n���\S%�`��˨���,@ �<�~d���=�n1�p]�ԧ%9�v
04Ⱦ�5����^,:�1;>��PY[���#\7K����s�%o��djnO��H�vOܸ	K��H��b�U�t.XI�q���+�6<�~~��PBG~��u+�Q�D�����F�5��{fo����&�G����N�H8Pt2�k/]f�~imP�ܐ'�����Bx4W���?6�q������O�G1�ť���t�>�{�#0�~u�؁tB�φx����m��������gǐ't̂�;�Na|��//8�f������"�d1ȹpg�ŭ�U�{�4����.n!����l]�c�Hp�M�*���pp�V"7`�Ʒ�5�Zn�=���%���M�����>�J%�2_��	S�S����-+슃� �o�ƏQȩ^�%k�v�7"�qn�"E�)s>{>;4q<��%���ILo��*�mӲ|}$lb�1k��R�xt G�"�7��=��hR���+Q�E˹�c��Ca0��S����j�zz��n���o$����W� S0+�����r�.O�g����F�.g�Tזģ�=�zr�+��O�m]�U�;-gz�
��(��7m�9�f;=����޳���	.���00P#� ��|�؊�a��J���!)~ s�	�DŎ�g-�꽸�&�����(�<��l����?T�B���2��)	1XH�������|m*�w�����K�T�^����(�R!�Q�h�!�B�v4'���
��p�Y���M��+���^4������Ƃ-�����ͣu�gb�����J���l����/�	q�A�sv#ޅ��3ynH$[�ky砗d�v�lS�ë��8�2kp�w��@�����ɘ�1�C�4 }�a�3hcl��H~_�,��<�!<ï����/k�bЊ���K$'������P~�UG��Jr?�
&��J*W��k+�Q;�ΞT�.ɻ���������۬��й�G����e�\����<��;a|
HSRt�],�g�r4߆������M�#a9��=/�Krt%���oY�u�%2��}R $8�z��Ț�A�f5>-���ms�Nx�g��4�	8Fo�} 
W�O��*v\����>���OU���<��~Q����F�Hj}n���U����쎋��ѓ]z)㴁g��b�rٮ��0���B$܂D��2>�*/�-QES����u�q�P��k��P%}mG���L���[z�U��fW]q8�(���k;�0�)�+�Ϝ}�+�X��R�]�*��hQ-��Q����ff��i�_�M��nμ\|7w� ̮�><Dx�}�m�+T��N��-a�dS~M��J�U#�J��ڴ 5#��}�L�;D�j��8צ�n^n'�R'�_t�A ����iJѻ�d��U��bt'�7`=u�.���K��0:D6�"�H�D�P�8r�6�VGh�-C�r����/1;�\�TXG��&Ѻo�WO������}�I=κ"^�+nɟ�G�������H���JD��@�9+o����Ӫ!�ˍ��6��&�#�Ȍ��ǶJ����P/����:�C?X
g�����g��ٜi�XmFU��A��N�p9V]�}/_��1��Pp���A�:��IC�XEµ��v8J#X@�Թ�D�iwi�N��'5�(�+��$c�f�"헸.�����8� �4��*ت݆DDv�kx)z�� ��8L�J�(��ԗ�xgyҥ �8L0y���̏&ʨ���-^��:��{�quQ�0:�OHG��*�8�G�G�sٔ�����K�Љ)4�;�-��e�����ˤ�A�����@��3N��'�Lc3rt6���g����:�����!lMOW��!��t���b<�\��ӗ�8zj@L�R����*��=������D�3'�9�xNnذҐ�a��>�V��)�<�u������-%�~�^�(�ӽʟ���c^���s�|:����ˬR^�`�@�A����j���ѥlC�������68�)�	[-�aD����8x5N$V}G	 |P��7�\��er?�'g��5~_��
��s"�����D�X��5t�y��\�i�T-i2��_��:s8h���쥂\��{A�
�LD�$����w��r��G�T���Ox�؞/T��D��][1a�����Q=�����wͩ*m��gq�����
�G�v��
[E�#)�}�'?tZ�5d��AE�&�]��
ә����zȀP�7�}��;�`>���F&��3w��[ �D���;�Cu���- ����b��ڳ�{��b���*�2�Oٛ��T��y�X��1`�*-ؔ�� �&>ꪟC<'#��:����^4�18�/D�y���0}����p�/!��_�� L�0���I��`<:���a�6g4��󱋩��H�9X��u�c�А�����>�n��#��tGp�}���O�@j��q��m�k!G�_>�@�ڧ|
��3w������<�l	��N�;��q�+D�A
��rT��g6��ܔ�Q�R���wա� 0S
w��TF�H�@��o�v��U��k8�!3�w����VfR�w�9�^��knh�9�<M�i@��|��\���&i5�y������METW혱��E��{��nT J�NŨ���m���.��WO�n���u2
�,�ߊ�Ud���o�.VL>�<~�*�!�M�I��&��[��X��!G!�1�R�e��	N�,�-�g��e�*;,~h�a`�V�[[#i���ijJk�D�ՀC� t���D���.��M.�����k�7*�z5B��A��;I�k�te�B������](�1ي ����q���N�_kS{Z҂���l����<f@���{x��R*3�_G?��=YSJF�4�e`.��D�.���~M�f���]������p�"�k�b�����[�؝U�����:�y�%�x�ɞ�%Ǚ< m�X4"���#b�9+�>�_�.@�%�BRگ�lH�Ja9lLVP��+�UA(��s�k�X��ɮMY���	�Y��g-e��;�����W��Ô�0t�5�
B
�ja�g;�	 e�܂ޛÌV��c�/"� 9�At)y3MUO�����(m���u�~�M�����D��B1��1(�?��o[:�]<ͨ"m<b���%42��X���AT|(��t��e|�pp����Ϣx�^�]����������0������� P�=�hɳ�2���F�h@��h�-k�2"b�x��X5��Ot<׀�bٚ�h�2Hj�Pm���Y좙����#d7��X`�䘘�'�g{*P3bW��@U��h}�S���656%��ej��������^M�$���|@���Kӵ�"{�5�����Tn����:\z1ѳ�t]Z>��s9�y�*����߽׸ӝ�mq��E������>�`7��wޙ�X����Z�J/�)$"8 ޱ�c�-M������;W5-0���}D:M�3��s6�]���� �����.���{���Uf�q�V�#�mZ��Gv�th��h�ǕG��V�0����C����!w�:%�2��U5>QR�5Q ��YX�KsȤK�=^�Ł8)�s���<3&n�b�[i#ϲ��ǭ*lLg}� ��Zt*2���!G���s Ǝ����8��=��s�iG���wxǥbө�|�2�՚�]rP~��zJ ,�]�O[�A�3��6<g]
����m�3$�!'�.A���숉�SQo�[PS��K~�]t�B�q���|�l3];t�#�d{%�Z-�P���F��$m�v����\ɽ*� ��Bͷa�ͻo8��>���ѳ�8�ubX��9|`��LA� ��,�w��C�-T�e�]q ����x�#\��x��h 7�1<�Lv�6��20C,����OR�3ףl��s���X���33�D�4/	(����^�Wo�39_��)�����+zLD�XFk�c��@�0��=���h�@����z�^��?j�u[���]��H/�=��v�����֛�1S�=Ɩ�i ��@���bDarߤ� �w������\(�wF�?��g R�7�B���V@S�>p8����+%z�M؂���D�!�`����|��w���-��h��d�oq��;=W����A��� �X2�	�{O�M�)%؁�͑�����ie�U�m�u�{Gϸ�1����͂�n��.�L�ס:=\پ�h_
��-<G�G�F�Ԋ�VI�6zy�G���:�$>��h_�}�(�xv���0���a�����mn���� "��	9t�](wF�3��'�(՞��3���O�?�z��r����;"4hr�Hj<���͕��������/��-�.�I���;gH��v�b�@�(=�fdY�i�)��s	J�/�-���]犫�.u�{��ҺZs��1{o��u�w��c@�BF!@+��
!��ٕ�mQ�����o睙T���������{UJf�LO�G��gᚰX���ո����(�\�,�Xw���"�c��?�*�`/��E �/79c�F�rE�J\�F�-�D9`A2�	�:��̹���e�f�I>9�ۊF�q{p5�&��e3��/ڋ?�G����i�ӕ�S��+�+�r�'*Z� Y��O�U��D�ゾ�O��WQD+c���Kj���͵����Բ5nu<��Hk0�_��;p�9Ϗc�o��Ѭ���V� 2��3���$t�U�@y��`����'��I0�r� �m8G��P"��P������y�A�����;��vD��x�4�V呛`�c�+�{�=���}t��_��Lx�v��}1��R��R�]�������\��˻�	�g���phՅ�~{0	�4^|�ψ��g�M6�r�DS2�Ͱ$� ��]������G������>܄#6Ь%A6Y��0��O��K��N��2�P�wy�eu���F����p�8�x�5��[#>u�k��/���9ҟ�ݡ��� xB��$����=p�V][�a«G�{�kYY8�36��oŤ4��g2	���\B8���9��钷�S���w7�f^<�Tĕm.�r���-l�%ӝ���z�tC��A7|+$@X�Y�EaP�&(y��.p|�y9����ʔ���:,�M��\���D�'j��������%1D����UՇ6���|��k$]0yy#�'�ŋ��O�@� j�`ۏ/-���m��@H���M�-hå.+==������1_mƬ��T��NK�g�0p԰/gsR��������b��ݴi��ùr����2f������vBƚӫ3?���ʪ^��I�de*`x��k�v��
���R��>Iԡ�%�cJ�_i!昈��63�D�b��~���%����R�߅t8T�Qn����Փn
��L�=ѓ\&���Z�8m�w�c�!�(1�4 �ޡ[5
xd�lO��%]M�C�=�=ԞGnӍ�:���:�b(5jf����WS�&�Z+? Uj7�!���m뽳J��WZ��GP#��'ቇ�6`�m���5��m�����w�ߘ�#�ƚp�ሾkL�Ъ����� ���1��y1�c��	PW�KhfZ�.%�>i��k��Ϭ�9lW2~��l�5�O�_!�����BE�H�g\���\H�1��YE�%f`� .o�sx��	Z��7uSS�_�[^d+��76�:\a�2	��������+������2���(�**�'*!QN�~�X&�p֎VIA���p�#�b3$~���zk�6���K��W.!�j�2���m��;�=��啻����r�1k�aPcgHU�Ib1�����l��A�d=f�C[�P�mb,T�̬�����ws�`�-�TyqT���*)��l��*-jx�lVRou����W�O�� �Ζ]��,2�Ͼ��g�_D�"�R����"��ɯv&S:�(!�e3\�C�'F��QGǒ�*	Z^5��3��[f]�ȗǪ�^�3o2�_BgN�#����8��w���	ZY*�)�f.����+�c�?2�ݾ�ľL��r�������j�h��� Y��,$����|@;�P�}N#�f��.�������/�^�{=?�N6��'u(W2	6���X*7]r�>~w��s-9Zm�Qdϗ������P��ST�3����	��|������M�Š^�k����U�X���kT:��V��mA��6�|��E�' 0�p�j��T������9�����t����M1m}�h��:��VV�>��r_֐����S
D?�b��y4A�ﮀcmty��Ϥ:A���MC���U��f��ֶ���W���aJVEf�͚�d�.�m�&�'O��욫��XӇ�����:���t�vÔT��I�� ��ʹ�jH��}T��[&/�h�sWR1�~>Ply?騌��1��q�r3�C7�WO��"Q�jb����9��9��KB���nz..��0��\d]�]h �]�Q2#�3�IYc����׺9D��FԘN���nWp!� \�Q���W�iI:~�%���P_�W&D
9���°}0�
�GT�!�.��+�`� ��Z��
&�.�̐���#έ �U�����X��'�EJ>��R�M*�u�N�B�Iv��6�9�g�ʫ	j�Ώ:�~�|�j*���	Y`V1.p�U�@��1ۅ��h�6lh�7�N�d:�	ք=�Y�jK)��ċ�Ճf�mƒq�R;I��8�z�#'&����a��i�9zN�,ئ�W��J��c�K���P�KN��س���SL83�tt6̕�F#�/ ;˕:��jr��Q�8瓻�P��d\�ד
Jf���lH����kڞ�*hM������g�%��y<��}�n�ݸm����$��?}��V��QM/ci@�:f�f�Z��:��۠At������G�DѲ�y���)�դG��⮚-o��Q���jHW�\l�!�q:����إ?	���^V���E�D���z�%�]������4�5��HP���� �e��m��|M���8xN�ߔ��\!����^�ŗ���Z�
��Ȼ�/�pM�p
�j���b�G� b	�B>]���3�m��)�=����j�g+���k}�o1��c	u/1^���+���1y���Ѱ  qW�,�(�{L��Ə�!Ԥ�"�k7�]`�C�6Hƿ������nY�>&��Q,l����P�q�d���Y�p����!B�9�)����m�I���Bq"�	q���#Դ���'d��]�#U�#!�@�w�fƮ����c�m-����B�oH֕�602rG����:v
��22s��#.RD·��+zߣˬSs�4�V���5"�d��kN�駑��A�/����`�@�>�e::wpߧ���|����"�V5�V�l3��	a�X���� 2���1Ԧ.7h�^�Wf�Y+��zM�2�Tr��<���D�d㽮�8�������2���Q���ꔾr��A�.���m����Qx�)���_šV�p���G��3<F1����(V�-�*���^>�V��O#�,˙����j�) KH.Cľ���ɀ.�w}�C�˜�T#{�!y�������U���A���<�؝�7�.������ZO귔=�M4�)�I����*�̨7���X��4��F�M ���P�ϫ4!��ҕ~�)>�k����%��B�hۆL��Z�9Ł�
a�&��ts8Y%��=M@z9a�!��f��#1t�Q�u��^����T9�p����Z0�T�Ap���%	e�����!""�E��`
7�9�PVA�����1�0$鏵�k�tT��3x�7A�c�S�
[�Ǽ���mpg�Vx^(K�Y�yK*�/@3����V��i�J�H���5-����yW���6�Ҭ^���]�=#�� T��yԞ�B�A�mj�?�@U�%�(��s�)�ϕ�j
hۓ���ZS?E�
va�_���3�*����]�B���Jzc��Bg��wK��F�b�q�5O�<0k6�	Z��)sm���U=���PEN���Vԅ�ԛ�U�Ux�ŊPe<�~��}s������L3
5=�>�R�b�w�XZ{��[��Ѕ���!qjy1���!d�@�s���Ը��_�F7���Z[�\�(�2��n�j�N�&�����Gn9�?���sP���z�hV[Z�u���p6�_�׺<�C��ۦ�&!l�.B����d��20�³�Jpq/3��Ъ{���8�/e���+qu������yj������ F\���J{�c����#�>���#�yB����U�ݲ������W	�%	N�����y@q_��L|��C#� �я��]"~,�o�⪣��1U(�%;eM�� E��;�W��g�z�g^����,\��9U��$�v�u�S9P����9sF�{}�J{1�$����`O��L�5|BD���AgiJZs[ZנRd�2I��/A�Nq1-!هB�5.h���e�i����>[$�g���>�[
���yC�}�"c>ق����Mn�ë�[�RZ��g��\�POW)N��0)�8od;{�!|�7�������k��D���}�ڠ�*���a�_`��b�U��Z�͒z��J~�'���E�g��+�Jz���m��1G����lFy��3�geo��%� S|��������-�˸�e/�O��C�nl�/؄��B܌���QU��y$�$��х8I_`��忮���T34�Dv�=�4	�Z�0_\t��Rxߛ����U�;,��@�yJ�l��8�|�['��_�<GU=�6)���UK���/�q��|�x*\?X0��Q�{,q5��R�@K���p��"H�5y͟m�0�#�]�J�b��HӞ�s�m�wy�g������T�x��q>!��D�*LĄ�"2�d��q�+��LE��(�v.)���r)���&͙h��E)l������������Yt�`K]JQ��/+�'��z-��T.�! �$?i���������m�Kx�$B;N�!����n�"1�3CwN�ts�;�{��ܝ񪠕�W5(=��X̬|�9�{��% �M�g��ůVᆂȧ[ :$�t���Xv�$[8}�|��i��ί8�%�kϢ+	����_d��i,jje1Z�Ǭ2��#}i��kh�E������퀌��;��/��������f�����\���S=��̆�"Gj�t����Rz���m(7\v�{���_g�]�q<a���Ď��G>��!�MH�cCl��ϸGw=�(I��GGKp?�/Z�HOY���G+���R�f�߯y 0�`}�,���I�	�	�i�R(�����M+��=�3
����:���^��u�V<:*�M`�W䩻�.9|h����E+��k����վ���
N����a��b��-�/bn$`8Q�wsU���
n�K~�F�N�>���&&
�}��wÒ;4�:������b-�����������'��/ȇ�+\U���K���֔w<�/'W#º%jDA�5����U�	g˩���;��g)@X�ņY��2�"Jjn�0�~�-ּlhpb�'���!�>�"Ѿ�H�\Lj��&�M:|�e�Ҋb$�o�Q2K1�J��9������p ���bZV�*CV��f�5d���鈰�] 9NV�+~��v��2v3�L�8��N��%�C��7���P��NC�kD��9�b6[�!��0�&j��%�,!�@��x�{��"�5��y��\�,piH��v��mmZ&n�P�_�{�WO���y�S�`��H��L���|��\_#��\��]��,L���6.�02������<��G���}[-�O�.�7�S��v�R
�����Q�3,��F#!�)T��P�͕������hi��,�U$�n9�$�@��&i����������k]�*�)��E������"
��@�1�D����k@_=l�A�w�D�C)�vLԐ��H<�^��"$4
k�2k��c����!g�~hC�n���Y���� ~��W�`E�YMk����^4�i|�U<D�SKn8ĵ��x� �P�i�J*���M��z�������k!���?F���L���t�9�'v~��c��JGᤄ!�%\���p����6���a��,�7����^�{{ۜ��3�q��W�z]�	���A�)|����.h1H�X��z�J�bs��{� QL$c,��D�r��	2��꜕�8B����U]e�[�I�(���XX7
����a���F����FK��75�d��`MB�ʛMNS�<�D`�O�"}� Cz�i ���/RX���o׍�e�v���0��v�h�����)<(���Bh�JdD�B� �g0�f�Aҫ�B6���0t��d3Ww����c���� ���#��J�G��ڹ� j�_�Uf�����ѯ܌XFo�.�l� �]O
���6�����<��[nűN(�ę�+�d=�5f�Z9�Y��@���=av���3����BăTu#���8L����
�����+s� K%�b�T�_���tj�>�X�V�<Y�b��m�X+�b�{���+�6�4`сJ� i��?��������MJ^���[������d3�B 4,3��|�M�����yv��g�p������io
,�2��� (%���I����xnH��k�?b8�W�Ą�#'��$�*H(�����3F���Z��}诸�����D]ơX\�[v�pg���߮�X0�ͧ$� sG�W���+``�e�E��9R���=���C���o��|��W������~��$�Y�S�ޝX2�5��g�WW�~��?� �XHg���1������l(R�}Dd��7]S���:�d5@�m\�����O���棭��&��*�@��8���|�@+��==F����O��^a�=��o\�%�DY��Q�_`6'�O��'2b[fTn '�\���썉�g�Ks�	�E�";O4[��#�t��_��'&�.'Dj�'����%�bÉ�#�%��.bJ�۹����c$���~����b_�P��ѯ���蓢��IwP���\��(�(���s�?���pDCQ����NIj���4�V�a:�uY@�J����	@vlkn��ؓs]�]g�SJbt׫auB��=��z2K~���a�-�@���P8�)��P�0�ac5���i�>m1���C^H<�-��#�?���r��]��^��Vk��<,�Q��9�������<�3}���ߟ&Q���}U�\��T�.�8
� �xNM%ΓؔK��}T��~<|R�H"�2;�Iw�]ǒ�J���V��Ò.e�o��1%$�a[7��9�V�����J���"�;��ϔ�"|(d#YW3*O<F$E��N���ׅ�%��S��(E��[1���=_T:���|�㇙��@2ݧ����Bv&Ѝ{.WY����҂L��� (%swrE�E�,�z,��T�?�^� �e�����l�%X��u���U�z��(2Q�r�P�(�줂?���%g#���|>�s��-��Iv�j�:ǕMx�)�q��]c��^��%ekSu˦�;�{�Tm��1���%��]�e��١��,Vni=J�T�I#m����O^�l��u�Û+��l�g���uk��l� fe�j��Ŀ���/7���<��(����f��0+��+��X�?������qY�)��U�h+ol2��PF:=2�))�,byi���!4�,��=v�}�x���D��F97E��R��`qzlY^��ad�1�!�P�|_=�^0[���+n������ T�J����i�n�8��N�n�[���B�rO㹃�g��|h�][���}�*F�}���崻_e�/+V)�a��������Y] �B�����ANg�[������>�e�W��$p�lsqw�lZ��ӥ�N%�j Rz�H�N�Wr�-�9�
��1c��)�Y������z�Z��o���wT�NZ(��][�\!
: gl��
 �^`7,_"���H��[�N؃�Ѷ^#�*W���,��ɾ��6�F��|Үa-�r�.
��KVq;��H��+ Q���~kN��(+ '��²�����)�Q����[����C�5Rt�6�z�z��N�L��Zq�bVh�n�Oأ�Ba=D�[���?�{����x3Q�b��i��u��~oʣ��Q�dU�x��	�9S%�"1i����D��*`��\�1j(�{���S�o���ف�(��L�B���/���P+~�m{K�O�-���6S�ƀ/|���L�������i���ʣ5/��zS��l���*�iT@v�[<ppUʙ!2��
�������� *^'C�j$��NX(|�{�D9ߙ�L�kU	rrK��lr�s�lՖ�z�����9��nB#�%C�|j���GvP�s���h_Ӏ�!0����f������f�(�����α��VBɾ���d�#�뿣Lc}[�2c<#��k��� ���1��Q�Ȼ�#���J��Қ���,���r���+��K�EiEL}S��ϔ,��������v*�]�ׇ��狋���܉�كO��q�^��2�@��r�zW����:{��O�u�f�g��P\w��x�DԵ׬�rm�w�����Q��v�h�.-�K�qDᦩ�X$wp:��N�R?{ �ݟ��3V��]Bӝ�P/r����zN�͕fl�p�w2�i�����R.��Ye@��!�(I�<_�����Қ˘����̸��4p.a�g��Qm��:��X�\Y7d��f6/G������b�P���pb湌���uƲ�>a2$�l�ȩJ�K�(	=�=�lL�K,"�9���ĂCy.�ܓ6IA�{$P�A�����/n:��!f����;i��-��̭9�Y�-Ruc~,�NL.�I,�`u��5�����o|�;G�64�i���r�� {��א7��^�̹wcS�T`y��6=
�޴L����e m���!l��K�|A��fF�߭�����[���h,��"��Pܛ��}������ Ð�_i��f�S�P�V6P����W3�vS�7&�(���"�W����W�f�it���T1]_<o�!k�c]�Lc���N�Cn�ιT���:}e���_ب�ۦ����O��?_��.�����̚��;�����z2*�]��.����M�v��ۥ-�7������H3vGڍ;3��1=)�ė��7���4�%t��4A�m6����t�lO�}Kn��c%R�Gz2��[NA%��O�8u$��"�
�4��nKnG��+>��lnH\��,V¼߳
�����Eo9��A~t���lH9�!�������!�\ j��{=�&v��ǵ�r�MJK՛-Z��ŕ[ϋR���QN��V�i�k�!a��t�Ϫ~���kT������j6B��RI:|	����nR'x�����zQ��G������P���*��Q��H��,�^���z��a-�uJ�.�'	g*��SN<]7B���ߦpd���#�
����ߣ��9d��Yфqʆ���
�:�UF�P�Qb�"��i�$������U-U$���á��xڙ���j9��a%�'L����F��������I�u\�?��*���	�x�^�"����l:��?;����;Ӽ'�xM��]1/^܄�9�Ȓ]��.�{S礟 	�"i�}v�\�\�Ӛo�)j�ɂE<��fJ׏�Ç�t^;�Ϗ�r��3��ʹ�@���ti��|�lU�s�1+�aq�4�]�7��"�m�T��d�=�9�@z鮯w(�3lZ��,)s1AP��P-��pZ�Ʃ$����V��ğ�)�p$��E)?cW㹾g'��i[��GG	m~9,K�B-�9�,��ѕ�#�V	��b��PDB+��
�9\�3$%$���H�]n(/1*�,���<`��NG��ɭ�5���8>to�J�΅M�'<�Djo��Y1�#�9�I���.`��^�m±Xr�H &|����q���E��8�^*|���b�.z���J-��H��(���5�T�� �ֈA!uBW&mСP9���^�C�ĸG�SMNa����s�����X���m捻��Ȥ��^8�n����A�J}�p�~��n�eO|)�X�p�b�������J�j*[���ޢU틂O�Wo-:m��imj�!6� �R�j1m� ���������Y��8��X�<���kѺ�0X�K6���宨2��r����r�XY.955�W�V�߽3��C�&>�^t�85�V����A�r�[�av�v�,���������I�um�u:S�SJ��Ĩy��"�,��@4��$Q�Ն
th;)�O8[`�wy��:��ܗ���Vj�����
�kӬSķ�	v�:�1��K%�qߜWb�kG]�!h���l�w7c�>�:�2�&3����/K�}b�W�,;��u?Z�$���{�'�����?�5�z+vA��\%����¯�")T~l��+��S��$���q��3�⫍�;D�ƶ>l+�}��U���54�9/f|�� �Yc݊S�)v�z��!�-�%X�j�?ȿ����x����հ:~x��;2�a�-G>~�:�;��Z~!io�D��J�oS�s�zGؙ���O��%%�ڳ?K�?go���tD�~��L�^+K<9���G��9�F�)%����2�b���]�<w��c���z9S��r���h�#�&��~ �4�M\�!X�MIb�ȈM��jm�SY�Sy�ꯎ�8�x��.�J�+0Q���«k?s%��l3I���� �8Q+�pˮ)��q%�|z�aD�M4�g՜��G2Բ�>�
��b�!��З�6�Iy�-�p���3��HN��}�����"H��#�p�õ3���ȥ�7�C�J`9�{�`�z��8\x2
��,`�r��b"Ts�s��f��ONSA"9�o�B�+o�ɤ���a
���Qv������&�N7���	XSD�,n!oM��>z���U�`.Y.�:��s�h�E
1w�"B��A�3Aw)?�=�ge���ԓU�5�կ�v�Nw)���i_d�t�$�ɕ��u������7�4f\\ﱑz��+��B,Y�R-��4�Ro�E.��f8�2G�驟��4�`ە)��"ЅB�Eqjb#b�ȖB�,�o�?�l��(/$ê����XA�;��)�]��Iڏ]�l�	��:_����Tb`��u��UC "ko�Y�V<r�����_���BR���H�+3�.l�R;���5,0M"I�)O���a�-��� 
��&��d7W A�Ύٚ]��U�G���/�g���I��6o��P!20��(�h�q��{=�׌��>�a��.y.�#����ř�XZ�Z�����_��Ф�|���&,�lվ-�3{�Z�)�搣qϽo�E8-�ʶhIi%"qyD��I��\bd<�/hn��$7���9>Z��͘��ůY�@<1�u�%���i,�e����ז�(▥E&4Z��v��xX�$��
u��lT�E�B��
}�|)ր��I��K�]�K.>� N7{������?���>d�c����{6?�}=���g��'�D'~u���Z��O����C`�U���D�R��d@x�0-�����`�؍`_��9�Z�^��X$����%kq�������m)�~�.N���V7�L�6x	�v��~�15
Y�3=Mwf@bwҪ����޷���:I�Q�J�F���~���[N�w.���\�đ#�I�5��z����S�/����`CbȺ����"�i5�b}�`_h^C��/��R�`���8X�h�V��bHC/�.f�;�b)�Z�8>��n�IK=�c�߂u��_II�����Y��v�̡�����?�A�����}JQ���&
ө��Y��+ß9�.�9\���70�9[�0YD�ZJ<�ж���J����V�ƶ���[�e���9�[�x�0��n�������m= ��t�#^/� :����P���A�3��^�}��c�}'\�b��ǧ�U̥�O��͓��WM�����܋Q�ܠ��P�
���L����6T���S�e�E־U��"���o���[c�g�I����eZ��<�j+&���33(���:�r@�#��9g�,p3�O^K$�����]j��Rd��Jx��!����P�8&ƣ��8�W#S���}���vf
]��s+N�b5gP5�t7��`[wD����T�p�b[Btab��7xG�ᰐ��G��3�`���\����ׄ��a!.�
짭{��0�/��yT���v�]S����9�%���+=;�+�y�R�b$z	�-���+�@)�$I�܁_�!G-6R�����`p��]�S`v~6�R�>/�A��S͈����	�+�i�k�bќ~��ULHp��1��]��-#�%D>����ۑv埗c4P�$I�:��ȧ� h��r�$[�o���I�wҌUڒ.T	9��r	E���y��o��t�9�I�BL0y� VU�ԜT��T������ؗ&
Y��>�H�m=��#n��L��4+Y����C�`��M)�Z��n�-����Ї�"��Ll��cT��>����%;����8�%s��̨ל�c2�j���N��nH謐���'��;[B[���	�-�G�����u�mt���'���#�Òf�5EE��)t�Mɩ�V�� `D+mVQW��D�;�Ǻ�q����?�ȶ��V87��Sk���=�G��/5����Uw�e@z�/�������	+]Pt�`���� dcX:�ؚ�;ɗ��p����J��l6[;�6��M$�C)EZ����G�<`���F�o'�<��RQ��>�ĭxOq�9��2W��ԉ`�D��3�����+;��{:��+ϊm��j�awӇ�=�h��*<t
0�{	�E�#��d\��L���3��	R�94v%�w!��i�5v�$��1��K�4�\A�h+'��:ٹ��v�	E��^H!� �f���_z'R��k���:�g���.mV��j0�6�I�S�em�#�9yg٠p>ձ3[\�CU�NnH�+c���
�c1�����t�N\dt���,Fv��2����r?�TJ��a`=�Fª[W�B�����x��0�����2���=����G�� ��y�Z�`�_D�&�H�� 7G�%AWm 5-�|��֊*����YL�t[�0��	|�l��*k�t��e��+Z�p�֙;��?�3NM8b}|��b��,$tn�C`nN6�C�('�oS
�&�(z��2x<Q�s�F6.l�'�kje��ݫ�5����{���H)3(�D<�ޓ�u�K|��˚B����Z��>�£���Mq�K�֡���#�XPdT� �\
X�Y��Dhu���4�s>z��@���=��\ge#�9�!Ng2hK!���m���PQz��z�`���@m�:2}�&)�}x�;�j�A.e@T�~�	a�y��Y�!�}q��h�����΁���j��]�Z|t��S��۬��Y	h��yl^��{Ci:n�\ F�<���Wӑ��&Ís;�h�t������A��{�}�k3�\����������^[\����XڟH�Ƭ��2�H׊fP�ҚkM4��ߦ�?a'�d�������M
ڞ��4)�D{��D+���%���"v���:Զ�L�x�6L'�ኬ��6V+S��80m�eo��-�G�5
�����U��Ώt׶%��1/��)�K�L��zI,��@L�͗��˦�0E�3j�&l�\u��	�tB�2Ʉ^y:� �	�+|��[V=a� �A���[�ϭ������GR��ֶ��O4rd^��-��r�u�1��{Z$�K2���Ò�-&v�^/�ժ�>56t�����q��j��%Q���V���h�D�3�'_�A���uq}6�\e��=�;YT\���*���xd��i='48a����|��x2k@�4Xf�A]hB�/iEm���1}�OM��W�ȿ�
��tSYI������֭۳9 ��pF�I�\"��AOZ�l�Q�fh�D�vLm����#�!��T�# M�gؑ�pi�$g>�
o�˿>��BW�d�a4�c$��)�\���x�ϧL����o_��X���ϥB�XP��[�9V�>c��v�E�ۚz����a�}�U�s���I������G0�L�¡$B�Z���Z˧�=����]j�eσ��C�	i���-au�C�����趒7��{@��6��Y��'۠F�?�~趫^�č�*A�K���g��F�6����-�V~�.�F��4I����@�r�w���L<�ԯk9��@q3�Km]��}Z����0U)��`��]��r5��J��Z�YE�D��� �[��(3 ����/�o��g�    YZ