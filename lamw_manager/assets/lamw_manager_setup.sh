#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1787152970"
MD5="cf07ddeb2f27be63f0e677e1ea15d0ce"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25940"
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
	echo Date of packaging: Sun Feb  6 20:07:23 -03 2022
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
�7zXZ  �ִF !   �X���e] �}��1Dd]����P�t�D�%w*t?yc��R���y#�EteW"�˜J����6@�U^ҝV�&V���6�[H^SƠP�W?(��I>h4���Mز�<1���V�XS|�G��c^�.+]�V�8~(�Ӽÿ��Չe�F�I��!w@���S�z����e�1����=C�f�����H4���h?���>p+�rYR��ƃ� ���F�^P)�r��I'����C�܈�k�Q���i|j����)�������T�ȇEN�֡t��s����@�#s��r[!['9�/�,d����|s�7�|�u��j���g���"͍/[�DK�O���^�)�RF��ư�<p5�Y�Â� �I����b���m��]M{}и��7�%��YIt������vF$�U}������X�"��"�zЌ	9q�N�8�����DFM|ބr���;J�ĕ�����%�z
���*�+B��b!��U)ˬ�S��P喃�[�rk��[�)�ͪǅ��{�G��6dX�e����w~�Ƚ	�͠���
�r%�6+��y7ͅQ��rP~��ʞڭ�޼��@�H�wTG�NPhk�ϋ���O�e= '���l#�)�/o%V]�-;z���qs��9j�ϥk�ߣ�s�Ř����=����~��c�ѫ���M�N�/�|��K�|BB�]��>^n�Y7��q�cu��>]Ǣ,N[��`��Q�����zG���"�.we���o��@M�s�B(<�����;F�G�s�R��������i�;>�;������F�'����Q%�J��w��ow�CF������������Y��7���g��YM7�@"�t4y�˵�V�������Њ;l6�ѳ����ë ��e����NƳ�fuyAP�I�N�`�a����5�<|@c�6M�K7騍�f��#��#�0�y.��ܹ���vj�<s����xwG�ˢ�ʆd525e�C&���s&�I�?��}�^Z�Z�J$N�@���-C��pW8�u��h;{h�Ѽ)�_�� �
�r�S]����3�΋�|=��
<Q��\ѨO����:��TM�#���8��oL�m�o�r��b{��)e�ӡ�h���`�D�Ù���߱�O�ʶ��|�.����>f���ez�@dL�u͐�]��k��1�bgqh�Z�zq��Am@��zǴ�L�:�xx� a��?:-d���h"mOr�ܑ���+�Z�I�ꧢ!F� ^�؍ۡ*K�RU���K��N%��1�����9�6M5MK~~Vܗ���=����J�b��P�̡��T\'ܯ��MD�Kq�/A��8e�0�Z��d;���mE��B�����gp^�Ż�g_ā�}%�^�c� ��e����l�E�u���xb�(,�U�kD�LQ��3%�~!%����1@o+'��nA��\�E���CJ��
��F��mE���̸(T����� � '��U��`}B��@��B|^�M��F�����si+��:
�pD�S+�������'����=: �A�����/w��n�IK� _H�~�v���+�t�&�5�r�m����M��@����Y%WW7����=��r�0y�>O�����.���z�(�a�*Ud?��!�F�����c�p�%�g�r��-���z��/RXO��<�� 4���1�"�V����jN�VG?N�2H����4I��e�/�N���`D��U�wB��z��N�;��ŵU�v��`%|N�q����>� g/��︷�e���M�/�����쪝�[l>2�O�aS��������s_�K��f9�TOj��?�1�4�r<$w����l���\k5u0@!�'ڧ՟(@C=��q�'��H��h����	��1��"&��^�	$.�Ҷ����g���{@-Ēd& ��q�u�+�>���$�"�[c��
ם�WlV^6�AwIG��'!���5�3/4��!Q�{)�v[1X8�7v>�l�Ԏ!V������Kx����訠
�G���A�,��<*�A�2�-!���v�q��ӕN�P̐w�FNF|B�t������g�\9���a��j�S:S��$L��_"��j91,Ӎ��ë
�g���b�L/��Mr��T��_��yO^ܵ	$�%2fХ����'��|�s�X��g�~*܈_M�����ݹ��`m0�OGtQKC�I��q���J��a�n�C��S�؏���y����F60��[��
��Y596JN~ِX��i2L]�t�R�kت/���T�e�稆��� m���`�J7/����W��+u��Og��g8+�ێ+A���U�C����J� |�q�R[r��*��<I�?�Zc)i\BX����C��Z�C�lnI̷j��n�갂�Ϲ��`�4?/�˶^50�xwy.M�)?�QY��{?���ܤ`v)�!���ZĀ}� ��ruꍶ#s�"��Q B�՘�=�(��u#����_��~�-��?QԨ�]�072aF/D9��8S���y���pi�#7ݨ-���ſ�G\܋/G�s���`WH�+gR�)h(�M�$�ٜy�yu��Iǖ��m�����V�d�d*8p�$�4%b��'��)��=�)݇`~���&�&��_}��9~�X����
��3w���-���@/��0���&ԕ��z�4
qL���()t̿������7H��n=�-�X�.N*18��*)k��>.B�FM�H���{��깝��2�
���M��ä{t.]n��Hs��7A]v�m��6�*�����]v�fё�\Yu�{Z��<(��ܱp�
	�uÐ8A�~�'�{�d4:X�i�ۑ�=�d��;�v������Z��Q ��;N�e%�d���-��$�]VF�aO��1��^�P���?@�l���ut�H�U2jq��«&ª;����-��#U0~Ɣ9���f:T���m��@���ͮ�d���� Y�Q�� ��U��R�%��&�g
�Z�8�P&�Oz��5��c�D9C�������h�5���xa�W�Q�ׁ���AG��P^���2B �Ir9.X��"9^�p�q�ߋ�S;Hx�fW�K}��S mA\��'Ɣ2p�·���܇3f�[����'(���>�G�Y���yS��^�b�IkW�mѪ�T��M��T��y-)c�Z� �pg�P?�\q��z.�`�t�#���֞�Bӿ�ѭ�iN���f.�Q�A���P�!J��Ho��^ӲE�C�*�	!4�w�3&���:����*Ŗ~������3����㎇z%R2��+<_�3�����S/����3Z���7�|������+l�6@��
��d.��-d�<m'7/N Ἱ-1�!fc0�#�qd�x��
��L��s	�F���cw|8��l��4�>�7E������J��o�AƔu�!f�^@��ea�u�	��#��;=��ӻ	�SC\��@��C�H񰟚��o�1���z�r8J���^t#A*	~`�ۖ�J����ǗA� 
�5$�.���/�m|�$3�߭��e���my]lE�(�43�K�����1�y�a�
�͈r�	ZW.e�xuY���U[~<p0�a�*>��hF���/�ķ���+{��,e�`<����q
����ȟ(����sK��(G�ߔ�S��^���>��c�D��
,��iR����[�ȚЂ�\c�(/MzW
F��i�O+��D��Q�W�W�1�5���&=6�s�bi�:2@�����ݣZ>��������L�D����"��X@&1y�F8c@�K\S�����kg�]��1��$���D�m�3��Dr"���6D����*����������2�[�R&�N�ᙽ�<��zD��V����0gl�6g�.g����Ÿ�9�@�]v�?��)�c.0Jk������S=a����p�(���Ȟ(��g�S��e�1].����Y��S�
,Q����`�܃�k�uI���4������[�{Yk!��R�TOczi�����3&��#��gGZ�N�tی�Ɵ��������.-���{a,T�<�d�y�$hFf3uM���H>�pQ�mv�/[�	�M��4��q�EX:��.�U�7�G�kb�ͪs���Zk�T��aa�%�P��>�QN�����(������@g�;�~/y�/��4�(Ŷ2�A*Y����\gw+l
w����͢v6��j٤c}����?�I]UT�nM�	���*�8Hf&(�3��5A/��K�m�~[@(u1�ku��2}��y�9S�ұXZH�Á���`.����8p�ӥ|X��-M���V����8����M����jʎ����)����5���L��!�W�;��{T��L�JG�}��u5}==�C�L��,#4띮��s)W��i`9���n��v*4T�dO�� �/Ŧ�ȝW��:D
�c������A7'0|rќ�nY3T�e���_�ԩ�ɭ	ld�1;�?͇!�-m�BY�e&6���6��
������7@���%+�t�5i��h��C���\�e
�W<�\�\>X��W���j��]��B�ב0D�y��5K�jN'] �N�7��h[��u��98�D�Ka8,:G
�K
 �@�j�[�BfLB��H��AD�7j�����@E�A��- ���w��G�ڤ�ܭ�� �9q!��$ip�gI�S�w
~�!�	hy��:)ȍ��(4^�W:v��1���ݾV��~�9[$]k�8V&ǁ�N�^�b��iU�Ηw�����ڦ�z%!�7��XP��vY�h�D� �oL��`�f�ŐeOU���%z{��g��;eX�C��1.�Kޣ���T�o^й�˷��w��:>���΂����Z�3xlW>M�r���`͡J;5T
�SB�=�c-��?��%� x+~�� �&�ۼ�(�꽾�L��)��X�kT$�O݁t�e��]*�P8�S���q����Uv^�66G]ŗ������M��o:捍�j\��d��c��Ĝ/c �J�VE���b���ŭr����x�i7�br+���J�8��̅�ylVL�i1�aR�'T�^��C����I:?0��U��Fq=S�+'�ܼ�/wZ�Vɤ�!h�l#� -�;Kwa_
ުH�ЊB�c6�Q'"������^6�_����q���/���r�_�|ǋ����J=�?Q�C�Jg����ܹ$V�Ԕ��'+v�!�i(1�1YN9�9��UM7D�L�)��w[ �?�M�GC�2�y�j|���f��G#@�����p
�#�Mq��<Ui$�敿'��Ն�k��Úw��z�t�s�A������\��ȗ�pr ��]�w��y����+�`P��0������Q8��8(��oa�=�f7�j�K�Bi	.@MN<�zL���{�\�H_h�H:A�#��*��}�,���g��<�y����� ��c{����ʤ�W��_ڊ]ppޘR����g,�R2�_�=�B�N��-�UA�~SV���RKQ2bp�=V�@*O�U]�xsN"-A6b��(���"&�6�b���0��[�0��Pq,�뙂���]��� ��V*�i���H�[_�Q�ӼQ>)��$�.�k��d���x+]4;T�zP�E��#�^cWL�K4���O>���R��"�L���c?�\şN��4�6�7�)k΀n�t���]%_�����w���WB�H���,�|13�����ᬻ�w����P%��S]�����GK͐���D���Z.�]�z2�#�x��N��s!�����Eywl������_o�~a�R�ޫ.�{��7�_�����G��r��V��dS�X˦Z�� F)K<mO�Sn�j���
���E���iE�@ �������W�į/p	�$"S��rs�o��w*U7b��� �i���3ȓ�ƫ�����/��(�L|(Q)��둚P;��:�t���.4V2a#`g�\4�h��$�N�~�sj���a����N���5���t������.Xz�a�ʈ1���l	�'Y�J��@!U�WKo/e�[��y;Ԭ��K=_�Nu��h������[$@.�u];W�ĳ׀99�w냕�K�����E���/�5���~�����t̅���H���9@憷�Vo`N�D�+�
��dP;����}7S��M�K]W3��$���������4��
��sy�H��ɵ%�����P�!I�Ь�
p�zѨ�{��M-~�`y�t0D@�X���I�68��p�U� #�G�rE���,��<T����-�>|らh}��x�.|��1�l��~����3������4���Y�2�{�w���Ǧ>�PH�\��Vʁ����uxa����q��^�2�C�#�.�ׇ�!�B粗�!&^6����Dט�8�'��K$��4���I�z'
��D�0~�m�=�W��kϊ�g�N�u��͇GN?�}��ѸX�z�/�=��P����_,���$����wQH�$�v`&�֪�E��e�f'�慣!�9h�Oڞ!��z��2霶xE�H���lǞz��Ѫ/R ��*w|�z~^���$#��w�to?��.�e��	N�a���
1#�x���a��D�� ��rU�;~<T����N�K���]�n�!�}�zL�HI���7�T�1�l�!:`D+���X�e�3r�=9�3�����y�'�]��Ж��,�5������,�3�-_��y�"�B��Ը���`V�!�]�����
Ӓ�^P���m/	�u�S0�2̣�ѷ+�ɸ1�h�_Z8R*���/�O#.3Pddޖ��jUm#����O{>C�ѡ�I�J)a��6���cGI�= �G\9���i�0.�e��n\`ġi�6�Z�Z.������B���/�Ӕ�t�������mC%��_Y��NC~�7�i�������Κ5�z`�xRo�� �|؆�ٲ������gi�����%���q|6��
3}n�S���:?�0=|,��/�H�K^L4?���O��9���&T�f�!\ZZ���0���7�cxLQ�f��w�r�Hp:E2|��eC���X;���������i����h�.gk����IՠH�� �N���l�$���nYe:�d>-���;;�E�h9�q���i�`y��ڱ���M�(��9��:��	��ڜ��ޞ�b�%D��Kt]�:et��V|�{���be(���У��Abۏ����Q�Zo�PaZmWa -O�Z#�#O��yz�/���y�H_�Ô:Lj��jC���*>���|^��e�gF(.��������ȉX�{���b�
��"X�Ӈ�T�Q0���4�T`b����ȹM8X`/'4�Q�-��k6[��R=G�?�hۂ)��M��>Y�-����m#j��IcB5%�5�������@����4Gq��=���:� sm��ڀ�{-a�h��1+�$���E�`Έ���^�K޲>3�wN�&�\���F��Խ���]y'���/��Z�*]I�_�C��#d���j�=�V��`Ƴϗ|�5�h	���m��^��>�*��{��
��K⍄��*�'m���$����I��y�nH�h��$�����O6��OHw�s�+뜥, �7�:����Yy�|A�����-v]V��.����r0Df<̬ܱ�cƙG�Ҟv���9f�������`'�=��L���rd�I9<7���0�n��R�>�W�9I�|r%���.�C�A�v[> +܈%�!�^7?���~7/ZI��� �*啚*�o��Г������h�Of�D�X1�z�֮YФ�|g�GFJ����!X�H��X���=��QU���&c���D^Ģ���P͵ߛ�x�����`�����}��N\�`�I�v&�#S/����7��3�v;�	 ��Aӓ��؍�'6��j`��T��5��Dh�ì��,�\��S�e6&r�P����������!}�VD_����*�%U�>�%_4f���"F^��0|]��O�M��3_�`!&&5'܀CS?�o���D�έ��VmS�L�[%�gQ;���3�ܛq�d�խ{v}TV�0� ��� �w�D|��f�\+�i0j��$�����
E�\\�0-��td����P*�?�P�N>�r��"�WP�"FA5Q$��F$��pqc~�"c�*5��NL`���?�Y&�l�R¡�̑}�=�,˖g��ĉy�������0�1������iSX��:��ޛ?S�Ѧ�ߩy�s����Mj�ѐ���q\%Cp���}[B-+��Bc�ix��� �}8��;� kC���E�����h{�q�.�p��� ���+ת� ���?��Ւ1D�'��{3G�jq�_w��3��o��x�3%t!K)�4>�mΑ���2���9l��S��ֲr����Z~3/�*�h��J����2������\��y�EѺU<co=�%��Nup.��,t�H?¡�H�]�0`آl�[7�2� ��A�8%��nj�L���m�ۻ�z��س�%�?p�#�~c���ˀ�|�I��d�nC�pի�<���o��{E-�
3�,=O�RVHlʽ���2r7��1(]�"�Ƌ��f��RM[ժ@Eu*�E0��7�g�Rxù׮e��(���$��`w��7���(��m�.� bP��3ϐ5?�U������G ���e����Q���+sn��w�ܓz��.3��V�]��K�f��,%���R;hYqc������m��%u��f*������ʿ�mt�s&�<�M�7���}Bɵ�-ХM�Cct��N$�sgvh:�mHE+I����w�3�d��S��i���sU�F(:m���8#Z%��5G����V�� ������:ʨ�u�{�Rp��i0�z	{�2I%Q$�c�l>����yw%&g?w�Y�0��~�C�D�r �����F6�iѥ�0�M��x,��M�.ۉE��g�� ۯ/e�W����Tu�Υ]q�D�lkdV����;���UHq�Yc��&�����!���{��R�d��O(���̗�~��EvG(���Jk�[!���~ݬT3y�95Py"������X��6��E���d��]���Il�Y�`�چ��B^/�Nx|e���뒠җP�*4ڤ�p�E���a:��5�&MN�����O�*>�TyR��
��@$/���ń��ί��9�����`��A�?��x�[�~9A,���r�K��e��'#[i֖H7kw�g"B=���J�q���Ũ�r���\�:lk��T��S��Ji�H?<D�_-sV��P��XİT16�3�	E^����S����'�9ʚ��Ԑ#>`m�2F�ŭ��"�v��)�Xuq!��6*�Y�7�{u@��!�jW�l3�۷K�Ɖe�hDq��F~�mZ��d`ҒU��h���Q��9���=�Z��&e��a�J@�[���D�����W�bL��
���Ԟ�0Cׂ>����;}Ŕ�ˑ�(*�f������D�	\V��2���8��?�5��S�Lp��Nƽ�0��W����Vq�+	��F��U<�"o6�^r�p?*���pi7ܱ}��/��E�~�ف:M�.52=�%�L�e��6�ԄNs��n�Du)*dçV���m� �8��h��&��ㄗEPA�H��X���GT����曂-{�uX�����dڨ�u��� ���]���Ԧc ���'��1� ���?�!�9�㱴ፙ���Q{���FR#k���۠�S�V�Ļ�~�Yl��P�;�������V�m�[ؒ��D�g�*�K`$4���RٺF�����_s �R�� �ީ��bq&��,�g07ϫ���嵜��U|�*��a��KSV [��;���"�(WT�<�<�������`@Ž������G�h&d��w��eB6I`ă�S�æ��ϔ�k��D������l h��ˉ��T��-EGo�EJA}|�� �y�1�7Wa}�Gm,�
I�?���"��kP�#-/i�&,������h��Z��|�[g��%�a���2����P&x�w�.Tlf{�f狸����H�l�͖d�*�/C ��"�I��a2�!�;��6�7
��_��~�~��{5?������3��X�����Ο�ze*8�i��F�4�h�8l4�-�ٛ��tAǼ�p?��V�ΝU��0��@�p:f���]�k^�x��m+�&���L�zQ�!�#3�"w�}��膇���D/��|���]���^�Ϋ��P���ekki�h��T�c_�6�{�&cQ �"��%��) �N�P�'D<j��Iӈ'a����4?mM��b�|�D�������Aj�i8�-��q�d�\��rP!`{���e'�!řp��dLم��4V}d;�R��w�����5�N��8��x,�ҍC�Sm��ѫn]�5����3G��U��P"���P��.��B��Uw߶���S��H�$Ea��z(*8��PlƑ�]d�K���8��1N%��bm�V�1��1Ij����][R�W6:(9�g��	\o#�4����~�3�����ag����O��بH�r�7�kl؉���fR��h����>�,lKl^t�-�u��ݓ�|�c����-lj��K�%|���1O;]pH¨���'G��Ԍ��ƻf^����f#1H?�A�^�Ǽ����A��)U4Ghݕ�Koxf�PFgZLi�ٹ�C%ehv���`B	f�U컘M��5w�*�����J���@�xX�N��]s+>d�&ة_�|#Vn߆��<]��[<U,���KKCt?!J5[����꓂ $+lKzcJ��s��C��.�e�4ޠ�B��1��9/R�X}���xk��U����/O�E�t��c�_5�-(��<��mRLwjaJH$Z�l���0\�73nノ�<�I�A��sL{G�2׍��閌�3�ܮ��٫��٦�h�+3�]g�T�j�y	�tpMV�yX7f {���k�F���̌=�q��~��ӢeYئ����ΰ�؟�U;���6�VݚL?�!#�t,��u�J\��d���"t�RЪ�����M���v;VХ&��bZᙦ�3Sf�l�7;���eS��r���Qg�(e#�!��P)O	�C�o��_�&Q�F���D��.-wVh�N��J;�J�q5�ȱ�X^�55D�@ј`�Ϫ@Y��	r�Z���V���p��7�s f̖1\N�a���.��6<��<�S����{����� !�1����W�-�=9��������gi��HT���:w\7�
���-+L��QlK���7Bk���I�<q������Q��k�D>%zy�o���FQR=g�͕/%��[��c�`�j��-�Ұ6�Q��[��tR�d��Vʘ~"C;V>���2L&�tP������j�X
-��0�Up]�x:��_�*Qn mHT���A�F.�U*<��GT:�pP���T�¸�<��t�|�����eJKr2���K)^��(&�Q��+��"d���0�AY"��;��)�!��n�*_w��ГZ�nߡ���R���	��EƣH�ũ�+x�ez����3N#��/����Z�H�?x~<�3a�y<�qA|�:�n���*�I=�A�z�ZLW�.X�d�(K��M�T'�N�R��Z�*-r	�b��e1,� Ȉ��|@
��"���E����קR��Aw��®�✤����(^�+�L"#�ݿ�F�OmM>sZ��X����y����H�,YÆ�5;�Q�j��[$\fT����t1��U���[Ot'������MAa��_J�s����<D��x	T|���^lGZ��	�5;�x�����%E�z[���m
 N2^�\c&S������Ԋ:"%������H�3�s��| �`�f�ݲcV������]�e�ŏP��򪰕L�h�Z2��c��
��������)t!��i!ܾ�͏|+Pc*)�N�.��wy����JJ��ܺ$1�:�Ϣ���ߤ~+&^7�\뽵O��nB"���rQ����Q���~8�陵����v�n�T��Ī_��bL"��c����0�x`�9��_]�,��z�©�Ü�\�3UI�\v�����48�=�i��b�!%ҟ!�ͧ:�C�"*��I�!֛&$��A�I�VRL�k�
�٠�i�3b��nt�\����!H�c�c���U�xW2�?'�z�oF�h���#K	��sx��������A.3�QU8�Q�c����\�R�Er=6!Tm�o�����%Xo��2d��� �MUS��Oy�c��r!@���~f�V��r�V�������C�>��t;������%d�WJ.�lo�E��lN�V'l��_������H$��}h� .��'x��-z���K(�B15Sש��;��GC�En�G5x��tۋ{m�{h!�9V��.H�����&�Wx��~�*���<�i�C�����©I��`Ə3vGj�i��f{��	{U:~S����֋/W�:�ߙ �w��Y���b��XkH���T�̔�K�_K�?Ϭ��g�7��ټ���k+�W���Z��	ʡ$0#��5�9�R�1A��_�������t%Uk��3@�p�(K4= �^��{{U�s��׆�Qc�u�]�QkCC `P#e���/��<�����4�2����}Ņd�4��b#�wE�Ei�-�#�\��P�b���Nz"TFcBE����d��Z�M�G0�^�r�|Cz�D���+��8�"�y���I<�$�:�.j�*�YӜ&��eڬ`�ӲFs��NV��u��Z;bh�YX�[$�m�Zjz�*L�\�� ����3����MU9�r%���r�*�к��o�F�?�JSi������.͍�|�p.3���q8p)� 7c�����x|���<L
'�6R����Ճ��`���
*��Wl��d���1��Z�>�Z���X�~�^���%�ɾ�b��V�7�-X�9�ZDy�4��a
���;��=HDj�/���L���X�댌���}�Î��pz}2����^nI�`f3i=J�8=�:����٘97�:�-G��m_��# ����	&!Wo�IF��Fg��6� �ԓC��.��
�㼼n/@��E�{�kjy㨨��یy��QjS<����?�do��,3Hq��=�Md�*�u�A/8�~:�ܑ�@���4L� n�t�|"��E�� ��"u�Y$�u�Iu����g��T幷2�G����銌�ו�h�?\>gq�U�\�d��T��!(M�c��eh/,{y;�ĩ�����������m���1���mGn׏�XJK����M�����窝�/�Cv��B���q܉H&�y�@���k��W���*��A|�*Z�0��^��lG2ț�*����FO�Nq��k�
UtncF�Wo��"�6������a��t�9M�;YD�z����e��6�if=tHH?����ۛ��X'.L��"�b'. ���	��NϿ�cI��F�t�sh~N4����WU�K����٦2��.�o���/l�=3YK{!�O@i�a�J�5�Y%bC�vg�W7͔ZN7�I*��s�ޅx~F4}ot��7��S��,��ZP/���e�UGI�c������}K���犾O�_2�Ս[�y������2,aޓ�|r�q�Aj���@����j���&�YP�եè�� D`ֹ�"�'T�R�@���MV!��H��.M�}Q~�C�a�o�)F���Ϊ��*[J��7��""{��km^S�2�J*P�cR��T�~�V&H|�j�9��X���0�yD��I�Dq �RE�|��j��c�~���H���:�a�nYa����i|�P�r�m"�ng8M���8y@&K���e��֥1bP�����n�bFҏ|F��cy.��&/G!G4�Πo���jݵ��Ь�(⒂`�33����`鸖հ��r�'�Ut�Hr �d�Q]���O��>�\��A�� ��f��g�������ؔ&Q�u��n�b�}	G|0T��9�N.���8.�\�4�b�Ⱥ�j��49(�]���
,^d�b���0�����&L��T�gD�\G݆Y/Q}�Y��'_������X�έxK��]��3����r���g+�7��ҏ⒢ZQO���ĉk�߻'/�v�q	��4�����T{���ʀv9���
Nu�W�i�%�w��ʥ����
���@�<�_��+���	�:S9B�569�;�P��G<W������	q��l$��Oe�.��2�e�T�%�p�8���Nh\�~��҉��s�T�|8��N��t��ѵ��))�ev_�(W�r5��^�N{R�öU�	=���u�ėm8�ݬF�UYm��+�G�E���3D�ӁT��A4��Ƿ.����6=����C� �^��%����I�%�\�+�-�ߌ��$ox�|)J��^��5+�COAX�oD�kcq*�O|�6x���)�7�k��$~���.�pV5z��'��<Q��J���xnl�����=���->�8�X�K�B5K�F�UeV�1e"
��9���;jC
/�!��UP����<\3�l�x����t�c/�o�jǫ�|�l�^Ԟl~�2B���E*B��ov�n\�O��e>��ަLu> ��M�����$U)������z�8a�Ls�Jׁt��א0�A�RP�~���9w�-��}�{��-~��>Z���û�\�<\L�;{/lKR�Y���}�6���y�z�h����:�PI�Z���$����yi���E?� ިbN\*y��>Ug���a���H��-�g1l���L�\�+hp8�{ʹ��4l��t��Ն$�էk\�gi�W��z()���嘉������{�	�h?�������$�ѳ`m�G�d���������$���|Xm�L��&=�
,#7<��nq�6��t��hb�c�33b�q9S��]��|]|"�_;H|�Z����Q˨��(:��\[(�c��d':�ʪ�*ro��b
�[��jE����| \��R���!����@ DxC!���6��J� �ѣ��r� �joZ���$�l��iI�Q�#*�Q����Y�����ܿ�_7���F�����u�Ѻ�	�e��[?k���-p��o�((H��M�?�N�eP��
��U����
�Zj8�Gu��̲�80�"� �&�U��C�ٴ�vH}VY&xxIP�.�{��T�N�:�f׏�:��~צ� ,5N'��զ�i���c��K}eN�#������J�_���Q����Ǽ�*uu
OMqeuh\c����Fd3ϗ�w�Z�u��d�=dQ�3z�r����kP����ԓV�7���7J9&�������ņ'�q���_:��,鍱��6����W'�.GU���/��V[EK=>Pol��zcH4��9�BR
�M�o���/��݉j��.N����AEO���M��8����JĀ蠃�S��P��$,k۔����3��K��07S"\�P\!��m,�v����+�5��!��5�/���Ag.b�@~=��j~{54� �����S�g�?4��������޼Yd�����C�@�m���yxt�8ͦb��Js�7���F�TP(�C������ۻ����IL��Dzñ'� �Jt-���w��5� ��i-"Ϙ�Zi{):�螠�+��/�*��!4�M�|C���ޤ�"?��Go
���ɟ�3+,���<!e{��7��lX�n%(����ass3���8/���iz��M��)����,Q/�&���*�-�j�� � |�����`1g#���
�c��X�軰əV���jX��+�����d��U�����^��a�~�I;Owp�s�+�/��+OhU8�*t�pI���vcQyoʎ�����9[�H�0�`+%Cd5O ���-ǰ^�������i��?]�<�#��R
�X>�"x�Y"�P/���Es>{�&�&J���1��i��e-u(yP
*�拽-Z`C.+h�����z����B��Ӑ����=���~�tQ�N�o�!����+��A�e��%�C�-MX{�.1��c��z�� "��WK;E����L-�>3r2��B�Q�1�����@j�rI��@��::~	fɒ�7�h�/���˶tV�7��卿�g��_��Sx��1I����((�xz5��|���QI�)١�7��<�ӓ I��k�c����`7��������Z��ysC��%�����=�1�d���R��%�}N��<v��fp�DP'B^�d+,T�����"�����1&q0'�x��)0�� <��2]vQ�2<��)����lHH6a��o�0���C<�'�1^�C=5��M�����4��RKJ���ZgWԗ������<��+ .vWu���ub��evz)�A,��'�5C�?j\`��?�Ѹ,��"�Ig�*�>%��C�E���+�_�]�ip4�@�i�,F��+L y�/�O����Ϣ4������l����fÓ���#5ъ6�Z�+�:2z4��:����ȷ&��Y 0!c��f�U�U���lJP
FT��KF����y��V�_���j�_t��v
�_tK_�N�X�P�B�9����"�C8ǢD>-s�~�(P�Z���!��iG���>����M�gwu�Cd9�
�:��Q�rغ�l�
 	���^�Hཤs*eo�̪T�[��^�n�tvh<(�� �Hx:�lF♃��=��8J�w
 �\���ٮ��1�[����tIR�3;�b�8������	�'*���X8+
a��&��iƱ<�)�nu��҇�o��?(�>��U@��1��"�\���>c�F v����S�aQ�

a<ҍ�~z;A}>��ߖl�������jb�"-(�3��S�3���:Ĵ1Ѫ���+(Jc�r���	1k��!�2�>�$���ь�CV58c\�n�s��s��ESd�I&�|o���"�G��i����&�E	?縎��Bj�|�X,ԟ���w������ 1SA5�5���1��0�c�vp��\u��C�09�ߗ%*5h���D�V	lO�䟙� �F�/��nw��;֟��?�5��8fN�ү��F
40���s�m0��k[������� (
_�?��z܃1��x
3��^'���aZ�@��������PM��K8}=���@TT�tN��P&�Es�Wx'P!A8
)�ۦ��$�+�ڙh�遝���ɻR34�� A�����ؓ<M�3�����(`����g`�y�|@�`tzU�j���̓���:�/K~69�a4<�ż�}5��-���0��~Je�R�[��p]�Ux��� �;�D�Y5�Z�r�#xJ�^��+�<E���Q��w2����U�uh��]ҽsѴ3�(\�]�K��,T��#��4��Z3#?e����c	%�?y����]�'��k���2D-%?;��]ϧ��.4��2es��Sp�־�*_]hgy��-��ԫ�������2�q�(�Bt:�P�k�pH��ֆ*�aG�0�+_9~�L ��0t~"i��u���bt�Uz3%D��#V�\�Q-�o� �?Fp�fq�ڈ�&�Qv�?$buG�G�F��ÿk���1������dY�nJa�`��gê&��	���b%��]
��g@�\L#M�HǪRF�G��!�ٴ�4"%�������(�_
�$Ve�u>��FcAޟL�h�ۛ�h�%D�ީ����`���!���II�
A���awǽ��6H�GX�dA�Z#*v1p�J�&i��4:���B�h�Zqm|r\�r�n�5:U� y.�9�V�4����I��~�H�5j�k�����UI�q�#�U�#��?ܷ>R�{��`[��O���	��[b�ee���r~����J���I<r��'v�K�
ߘ�HF=~z!����Ӎ�.S�#5�|'#������^������<&\�0��|j��ZK6�.���.��o\�5+�sܾ�^fd ڔ=��_"��! �$�޻�v�o6�dWü���P/�tp����(�㜴<h��tDÁq�Лv4/�<\�=+y͇1Q��'L��yDΙ��1`���	Z�ҜY�8fv!�(eoU���)�G�f,�7y��-��Q�n"��Ϲ�c�M5�����ha&�5E�k1�|�Qy1GwU�O��&;�����;�E~�u�*m�����xS*X�At)����Y|��b�?����(��=y�4���^�Ë�n��e $86��<�/Hr�v@@�Nwu;y[\����W�i&x�[�1�8�M,�;���5N���G4�q���s&7'��$���E����C��k�z&?�I0������ey�ҷOl�D���D`���zP��	K��'G�8��aK�����z�g_�W��0�K�+�n-!a̐��y��0[��q��K��O��W�ǫ���<��I-���Ć��oIb�#���|>TW2�u	��V�1o�f��A"�$+�ê�7&��=c�5XЮ��Wy�|R4�A�*v"�$z����ܣ�kNWóCd�7�I�u���edV��n��;W�o���qpʹH!��Vȥ���ieWY�H�����_N�?+��do|b �a�Ɖ�|hx�2�;j*���S#�GZ����HԮu8�&z>i\{��s�7В�p�o��_��ڴ����K�p��;O9|JL�j#j!W4}'޲��Ԕre��qp�T,C�6��n�X��^$סLy�R���:i#Nc�o� !�0�$�s���9j�ؕ�N�4��2�g:� ���[hW�6��q�n�	ނ>w=b\��Q���d���&vi凶����] ��γ.rI״UFIx7zUSX��2�:
��"_B�(��Um��8euE�\wk��[���k�� �%q�D+ `��n��u.ij�"���d��,�<�M$x�չ~��OD{�=LX0)�#�[G���o�#�'�[x�����M��B�H#��%Pt��0�5����J���59pA���$fL��0~�8�I�� �ӈ�1��� _�ܙxf�uD��|�VD�?<�$1�I~+�1�"�v��7��e)�'M���r����: ^^+��_�v �&5�O<6��X�ڥ���CE`vn�%�Z}�5p�ѐ�ƴP��/�[����4�'��{����v6$�VЏG��H��嵤<h^ӕ�=�AƇF	��kA-��d	��)Ԏ�<G�lV	��
!<�c�z�iu��})�̬��ޓa7N��<�b���b�á�md;��\`�����(8a�L���n.��f:ې�-[�s����[gg�W%"�I �E�]�����;�s:��F��'��ژ�CT�+�	�=�:L2=�߽��a]=�6��u�2M���8��?��1n,�aQk�/`M���f���R�$Ho��'VTٮ����/,\�u��}��V��7�y׉ˊ��/�BGo���A�i4*/��J��,�q��[,5��3+^�4�<U���@��>5�#��\����@1�a�%�ja�����c�+"�"_��mcm�9������<�X�>U�� 3�&���i�$nox��:�[�OT���\y��}q�m��Av6�;NF�9A�O�[]�#+B]�}}�a�$Q��Z������(W�^?t ޲h�қ5�lo���d�4,���6��Gv��ƹ�Z�#x�l�*ٓ�U6�)7�\���q@}�9Z��X�>B*\�3�ޚ5���S9L�#���Q&Y!V�E��8�!�_��Q��A�bWu��(fxl�*�W(���1Um�E՗��uM��F��Hf��T�
��\��d�˻��3�J��/\�4Qb�a�BmT��(�2K�z�l��׫�ɛ�i�1��|��-����iT����ȞA(<_�w�j^������V�yr��@`j"	=w(���$�_l�9p�Kpwc�j$�[L��&��͂x�ΐOi�-�M6�Jt1r*��D-����C�#I�9A�K�b����#�Y,������bo�H��/SЯ@	��v*9�CM��Ȇ[�l��YT+��T��a�Ŧ,1�����xk �9X+�d�Q�?�#�Xf�(�[Q���rV��K�q>�3��)<Oo�&�b�Yk��D�b	{\O��n*���1*����6�_�&�x^e��(�@2�����r0�ܒ�6w��_�)(.�$��x~&��
�������o�}PDx��NA�X%s<HM(P� y���4�Bk���:ҋB'��U;`��Zm�+,*̪���/�a��y�*�7f|�a�JG����#�	ϡ���a�&��B��(ڞ�a���<��!4Y�D®���h�>u)9�#��T�˨�<��+ �������	�sv��oy�]Q��,2�t���0��/Z�W�\zm_��\��FuR��yقrɮ��F�P�nC���9��K��k��R�|qz���Dx{C���,�膌�{̸"Q��H�?��������ɠ��5b5�%�*o��2Ev`,*B��sA�r<S� ���|������=�$I��=�ml�A��;)�Aq
���Y��7x�BU��y���).)�j;�'/.0�5�
��~����B�����~����]zƍ�ز�},���4�ȪP��1���5_;�{@F��DsNKa"K��.R��*F��$�%��Q�r�~�BW�M�+Ǻ9����	=g��FpϪ����M$����PDBF�Vr�r�*?	~��"�ʖ!흝���K�Z�����d���F���A�����97��ԛ���c�n
T׸��\_��UKr.~Z�cj���2,/��I����7�^U��ц�������}��]�b)�ğ�e X����J�D���m��Z��/]�M�<�}�����h��@=:3�yE�Su�A�Q�ܦ�%#�����L3_!�J-XZ�}�#�i`�~o*�;��(giִ��4��6�J%���Ƥ�/���'�]�B��P�OP)������P�vf)�@:�';_l���y���*?WBL��u����,�.Nj�Z4D����	��p��}�b��w�>��D*(��������P����LL��К�T�Ե�"��Ă�NhA�{��u&�zu�d�����n��p�Au5Ӛ|�u
Y�|���iC��)�p��J+�V�I�+��CN��l̃�:��F��.�l�T5^��f���^����rnF	 6�{���ڣ�C�¨����h���D�[X,�{!��1F�� �� r���-���YM|�t���4����u[�z��ĩVۮ����Ng)�[䯫튇bQ�h6�͓v�3��@Y��e�8��Y˷�Ͻ#?���w��\�*����Kwx�EZ?(n��7�I2������z��  ��u�� �q��y%�-�Й���Ea����xة�j��9sJm�%�<+A�(�����/
� Qp��ͿM�0[��ֱ&v Oۆ7߲��!F���!���\��-d��R>��a��v_����.=ľ�^�KRw�H�S�JK&��r3�9��z�B�f��Qt>,�=�I�Z��aM���V|�h���JJ)՟U�L"ZE�"U�� ����\�$�0�b�?�;%ӕk�Gh�������H͛> ���htSؙ�t¼�1�W[^�C|�w�i�j�Y������č��|��*x~����a��y�I(�NǶ6а^�n�^�� |t���1�B���pV�`�a_��aع��f���7��8fz�b��;�ӌ���A������脌޿/�}�Q;���C#�A�o���Q_�u"%�!(È[`��uY����<g�a\�;9|�H����4�g�!}ŗ.�Nl˕��WJU�T���e=vT��
4T�+6��M5TDF��fd���w�A�2��K����ytu6D(�LY��m�А!u�9+���3Q�'��Bsjb�j����s��NU�3�~�X`_p�u|s�vT�O�0ca���nh�KiJ*�YN�V?K��iE��*k����W�}���®��o!*E�7	Fmq�	�L�e&�1~ q�7��ܣ��n���igU�z4���5޽I�ژU�����Q�gW0�l���Ԣ0�b�����?�?�F�tBK�aP��z�_��Y����w�����J�}�as,"q��$DH�\��r���M	[J~{�X�g[1�a�"^b��?�SR��D4�"g@'Ȼ3��JJU#p��[�H�ֽU{l|Me���~�B���K����&0HdeP&����Q&��
�;k����K���Ka8(��R^�Fv�������������<�ă;%�)hh��U`tZ�|ꊪ���JiF��k�>�!~M�빌Y��j�Wa5�!YC��N Tnv�Q"�qa��ygE��l�{}C��^>�Z���,��� ���Uv	�x��sN�7�[��B^lG �{�<3A�d�i�|��V�~�<�/K&]���a�.]�`���1_s6�
Ҁ4��z��ޓ�u�&9�J��\����d���G�Ã�`�]���V�7�M����8� ɧ�a������!���b����G�Z��k��Z_��4�"j�n���3?i�
�O�[,<�8_�KF��	�͛�[��b'{Z�)2|��o�x0L��K���.H���p��܇��~�w��$�?+� ��đJW�7����XbղҦZۙ蜂 ��\�����Г8��wS���%U�Y�V�RHE4����%��������W@�a�J8���a���y�FR5!����ja��(���dkg�ћ�
}���+�p��u���_��d����N��f2G��=�>����o&�������=�򃳹�L�z��}cQ�y�S��;�p#Y�+�9C���~��S�3A>M�	b�_fa1�x �VZ��2>Wmx�a{~[*��1&�R��AD��{����[g�zQeb�mڇ�^�ՙ�P<���+ø/@݈��� ��:oѵ���J���I9�?��s;]���C�� �9����;*U\K`��5���ݲ�/c��g9��tn�躣F@>;��S+��'
[�����K� �r;��O~}\�q\�Da�:�A�SI�^>���w��	ԏ���t�$��֝	/o`|���/��������Zk�T	����3!P�H� 	�ͅ����$�(~IKѯd�^����?���KE+��i�� Φ��iA<�1��������1[�R�+�K!_�*�HF��� '0��i�D��h�QH�/n�i%�xeq2 |�{��Z��<��
b{�;�V��Y�
?>�b�áo��2��>����ȬN�0��)G��Q���v���e18���Q%��.F���j��]B�s�ccq�j���Pm�^���0]���K���۳ X��h��K+Sߊ�F��o��(���w�vbn��LQ���25@1)+�C��6$���Җ�0SEo���Gf�����SM,��������P�!'����B��&NrN^����G�0�Kn��]�ar_o��̓yr�J�v���rk��+�yOuQjA��v�!�1U�N/���x����$���k��	����.0������7-���>�{Y�Bv�y&	z�3�DK㸾7�.�߯�j@�"?��L[����]а�mѴ�!8���u�f�j	��[�z�����8�s�w[��ԣm��r�E�Ha�;�8���k���q�1���<2L����Ý�MKm��0<Ԃ�x�g�t/Z!h���G�_P}렶�TV2���g��w��j�Û8��7��3�Y<��� ۟��Y�Z�v��}��b��Q2E	�eq���)S�>)�<�]I��y b�I��l�s�.�֛��۴g���t�r�%�xz�)/L���<E��iqL̞�]����Ch���:�f��2��|Ix�6K�E6lIU�aA:VoW�*ɫ��֣wkQ�}�	�5����(�Œ釐Me�~�!q�O��� �D�I]��,���`ῐ����,f��=7�m�qY�F}tU,܈)��&�&G&��c��m�=�7n1�(YVy՜Sg.��f���v)}JN�~�Vu	��1�H<l�q�rّ�,}�(�޶�IM�Ѵ�������Y:�̑��y��^k�����������%��������:�f*�J4�w�����_������	�I��WQԧt/h��m"�{xY�c�nw  �t��g��i�c�ժ�60iK+Q�wVU�%Wߪ.)d�7����r0���?�V�3Q7�_��5��ـ�ހ� �I.z�Y�\P<�Y?��Xwq���j��򪱴�fS�4�����v,L�2�<ߵx�Җ��{�vEFDb6��7�D��,[1˂SI u�t2)n����.�P~�NeD���E��K�{�%0A��D���[L���a���]R�a���l���NA�;��/?�^���5W���DX���3�Qx
���H�2�������o�_ ���M1�h�\Y&��M�1��ΔJ�j�`%��(�_�����3�I ����hm�[P�h��`��&��NZ�J����)�����ko���L�6�C� �z�� �Tp��bn�R -:[�k���;�F����ɦ��a��F!�6��c���d���>���G�zC}C���鸮���@�p۞x{�TUR+AYe4E�^J�VW�&��&�q<�Q��z7�.���1U���( ���q�d���y!�Z�x�Wg�Nq��gX/��cY��M ���F��XD �P�Y�64Y�j.O:ce�<��ɾ\&'�'p��VGmB�@(@�XSu]�߬훀��@��$��`�,3��C�Y�vP�kOh}h����.��fj��Qi�pt�gYjF�X��4����5�@d�;`5�p`J���Xka�X�g���H����:1a�EC�����]����������2�}ֿ��w�h��&����tYP���� Ʊ����,����A+�a�W�f��c����1�c��?9�e���}�� DW��=m�d���3ޕ�^@F�s]KPF�0�&�	��<�;Q����P"��.j9V|w���9�6.��Z��~m/�u�q;]2��<����;��Gi��ُ<��[[U����ZUo�޺��D-�:�"7͢�����!�ג�<� �0��gQ�ٗQ�y�b>�Z`�%��д�'��_e�7Ƴ� P<^�3:$��m�{�4�D�D�~\2��o�E�J���!M�+��o���k3��=����&�ղ�����y�?�Xɾ}�����%�XY�  ��EB�
Vl ����Q�����g�    YZ