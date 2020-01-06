#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1877483209"
MD5="104e6183c869d6dc4bbe0bb3fc28341e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20364"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Sun Jan  5 17:54:36 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���OL] �}��JF���.���_j�w�D>�v��\�$kz,[�K �c⺧���gh�Z�[gj����(��§UXje(DK�Ք+�:V��.�'m�^���Z��X�Ŝ��6{�+�����RN���)��@��6~�W�`�!��O}g"~�`:��Љ*'`�F����S}�t�����?�9�D�ـR���?�bWN��bh-�z����	�:B7��yd@����/&.�
�A ���Σ�����*��n>D�6ܻR�$�	T�^ÿ�I�Y� ��c5#00 �����@�b~:��1��o�~�S;f����ޏq���lX^�j��[` .b���3XL���A��$�_Р��7����'Y����F�G!�����e"�a��ƲM�#3����Lwo6������c��=�΄�>�rw��b�([�E����l�*F�C9F�A�_�����jj��ڠ|��$��2�rM :�+,1��5R��G(�W_�g�vq�
W��y�g|��9�=�;����}����z�\j��2j������5����QZj+Z핆�fި���G<�fJ�kKnKWAO*%���Ȧ0�����>���Ե��Zc��+��jkگ�J�(�R���8��,�G�W!dZ�g�����.��O�#sۼO�Y;��6Ɓ��pF*��(c�{Z�D�����mE�K�n�(���G!����`�k1��ѨۖU���D�.d|,�����~��G��c���\	��F��3S�P��~F <�|C�=JLf"��l��78�f�~�o��m�ͱ�l-,A�OJ�Cꡘ���;(dBXn| �-ې.I�s�pp'�����a��d�R��[��N ^VG���L�\|u󴌱���E��A1�vHs�܀
mM�̋��������ǭ�lg�k�|J3 `"E�����b������܍�A�Fd�"d��6ؕ"��k���Z.K��4D�y���n_����{�誦�9�w8���{䏚g��`�"�ċ˂�sW�e��!D!��Jn��)z��R�}�Sz;�'���Dv&�f^�zgH\�5��Q,������O���覩�#UF����V��gE�)�Z�k��O?�Z��s��`�T~f��S��P�G1���g4���SN��$�A��5�C�ԞۏG85:ָ���]��������j�6��9V��,��d�7�r�@3�҃�ܲ�-�=�>����-�0�s�߭��֒�k\Χ*����V�t�n�a�@�\ʢ!�,��욃ns��R)��(q�[��啺1���(��5[�������Nl�Jj�3��ns���hmO铉���)ݒ�[�aI4:��e��.�9B��#}|����#m�����D�8K$R�y��9�EX'��?������
��<R�sI�ZCp#TM~��[��'��s@ ؘ#lQM�S-���m��}��cCU}�&���[x:^� r�P���ޜ�<�9-�:u��a8�>lt&k"��z���ל�0�����Xd�N��\�rЈ�y2�̩����U�4���Q�t�/�C1�2��ϲ�>ѮR�Acw_�}<<ȗ���F�Ʉ��
2�E*��鏴��?x���4�d>i2�?��6��w���"w�"�c�D��7�}�ov����:�Ƶd�*���:ʬaE��r�{����\��^W�ǜ;�Ԗ��c�7BՉ����!����FP:1��z��z��t���2/�b�~�Hs9�@���v����U��s�҈|"�gG���a��pm�"��[t����k�t��	������f�an�@�����>\b��t�k\*�.m������kAN�?�H��Z>�ԇ�-�����K/�	B?�+l��^-��$V��2^[���+��a��9���P�,�q����)L����bk��<�n��鮂�>�:�6m�Qv~�f���<�dH�E���L29	�n����3�b�]�����ץ��W��p�m7�j�|�s��6���7��
��L�I)~�۔��7�Z{�
�q7;Waf�:��q�=E�l,�-�܉�{M �JIo�������\+��a�n�� k�:'���%���Y	��TV���&L8�5��%P�ܱIpŠ㼶7_�Bo)��ɻ��Fq���?��J��kr���h�� `�0T�t�����QEn֪�߷6�e4#%�L��'��`�/F��7��Qm�d,��c2'm�;
�������%F8�����㍩�|)���zp�,{��p�����^[�zl��擊�)�J�RKk���$	h|H��W$bB��!k�������S�<�I̢�̛D��-w�Old����u~�4d,K}��z����e(Ǔ,�<W�G���Ç����jy����,�¸^�D��N/�G����F���[n��2k��	�+�]�K�N�@�K��`�e�{�����5���;+��#�Zmr�CĶ������Ҫ�M������*�&r_�\�d����a+���3@��y���e�y�c!P�X��&���lX,(�>ݢ�H����"p����@]�
�X�J�[���*PՁ.�X��~�.������ߟ�>E𴒅OaHϫ�h�D�'Q�!2:��	I5�W�m̬_B�k^�ҫ.�Z0�W�kE�/$<J�?�]�"e��MK����ȏV)�i�n��&2�{�tvj0~���n.R��s$l���$s�L_9W�S1"w-�"y��{SOk@�u�Ic=4Q�!B���z�xX�<#��~�2+���ϥR�e4�񏫤 )&��O-�̰rK���,|u��+�0��"��Le0�����y�6쌁NR��|j7�|d<Mo:�'���9;G��]|�J���OS��j��/�L��.ʎ��hgĀ��$�P�"�i@o-�uN�d9��M�6u�{m3m�Ӌ���9���ɥn��� zy� ՞lj��=�ơq��}`Xֵ���:�A>SC> �=��p��=zh���K�m���� �R?�5��äf�+���>��l�h��� 4��l��_��v\ֶq�u��N�$�2 �u	����P���6�Ɛc��
(ɲ9#Y���5�������Y�㡔�#f&�Ao)�QRe�ln�?��&VM�Bc�̬�����J�&����}I�����q厦�VW�J��QYtT�ߒ��/�bx��G���-��+�L�g��b�XBH�|��IyLk�H��n8�
H����K+�tNv�A(��?0XW� 9��d�@H<���2��t+��b��.�5�!8��_İa�e���?�I�����MN߄���Ы/I�O]?��0/�Sn�h��/�ܦ+�c���7ii2��6�{���i�mid?�P}J��g�?�l�M�%r(Tw�d����0�K�����S��)�g���E�;�����0�I����|י��K�Εڨ�i4�	3+Ⱥ�n�9��fsyPT�r�AS��5��ĠU[����yl�(�l ��6�h w5jz~
4�:�H';��h�X	����z��D]ǱΪV�:f�����eK3x�H����Bh��T��O�}߸����a�8��3�[�G�&�
�3�(����a�=Q}͕�N�~A�bw�2�nF_cY����2-�d_s�c�yd*���4�C!�����Xb���V�w'��C�="����8I8��� �&���17�*1�̌i�v��aGq�gs��r�*�v�Li�� ���a�������.���ޕ�ɔ]e�O�Su�u������8K����ٟ��t�? ~�W`t22�=@SRV��B���Q��a<��G�t�����w���6�����p/���g����$ګOU��R��iG^�Xu��c5���[1�p�n�q�[5ئT��fR2��~��`׾�,Aw�s����,?}����\�-����B�Gp�*]O�D��A⊗[�F�"AoԱ�QΪ)���p����<���-㍥&�M���2"a�1����ަ	1�Ǘ`}�'�����"�v�uo�H�����9�v�B�x�2/OïYp�B��3���X���2J����*��<�^���Q�=����[��dZ�-)�]T'T����x��:2�GpYk��ۡ�_�K��J���K��*jE�O*��2ִ���:2�5}=��00  
��@�!��}h�!1ye�Hy��y �����f1a4�Va2\`V��:?K*2���a`����<�>��ia�����VN
8��n�l�<���@���%�h#�ϯ�P�e[�ܢ�t�����i^V;K�4hT6&�wð,��v	���_>~��o,��]�l�^��;���Qs����~=q7k0�wȁ�,��.�Ḡ�1�lDY��Y�@:y���އ�z�e�>�h,���B��^���ﲋ�ψo���p;U3P���*]z-�7��b�'��+�}m����Y��96�<f��%0 �AT/k���T�z֏������s~�.*�;�V=�` �F�I-�k��1�C��[��ehz��7+�A��d[S,|n�M���� I�-�i-ҽ�  ;D^�K��^uu5Ɋ��u"����rt(Ouk�@uq���Ps�Z��He�^��0jI�e�n�iF���T��ٖyҁA!�)f�W�↫&�O+d&��t�z5EY�n+�U���A -eh���\���U�J>:?=1�<��L�ui̤�¾W�|G�΁C���5{r��d͞:^Xs� �f� >c�tB�q��t�g��P6�z (�Ѝt��dBP�ɺeQV7�Z�����'�}�W�$��ӡ�� �=v�6�����:��8טAe����Ui�B�>��h-X��5]�L�6�Jd��¥��W������G��|ʼi[m�����8�:T�Kb���fkGq���*^5���*W0����������M-�ood�;QQE;fJi!�6f`�gUa�:K�
<ߙa��i�_������#1	���Y��S� ,g2�0T�k��������}rK����\6E��������+Y��R�����ߓN��Z��cs��1�`��7��{��R����K�3�u�)�S3���ҷ H��{�m���.�_2ۏ������ݢ9������*�����DG'H�JB�/(���|R�EW-���/R�i��:G�.������_�� g�2���E]����pc�O��=����c3_�L�L�b��2�*���P���8h�̂hB�T7� �~���b�7|�Kt��%}��k�ʘ��/[��4)���#�ϫ���)�κQ��7��ns�2��4��2b��'ZK��2�tg�d,�b�f��J��8���!�H�0�^9�N���u����!ƣB
���I����F�.��;�$Y,�#l���pϜҶ���K|��Q�d�ܐ�ڲ�B��3?� � �&��-��O�~��V��g�[8��	%`�hRԄ� �PgOt�x����[z�9I�����+I������I�<����u��n�/�)��ʊ!��kXF��:!c&+�X�V�!�
%�o�Ë�a����4J���H���Y�����µ(���<�Z{��1kJ�&�s�Mx�-KS�����L�f�tet��5RTT��Vz�2*1��,�Z�W1.�a��Qr����P,^Hh=(@,�L�q��z��_1���墖S�����x-������'!�DYT 9�͉E;Vh�#�jX+X��<�VV�~�'�1�c`�2J�ID�+�Q����F3���ݬ�L1~Kie�H��s�b8�~/)r�G�`��k���ˎ�(�d�t��E�u|tpv@Qn���6���29׹_�y�7�?��6���"s?� Z��H��^�:S�r�(�'�:�����"�k�*��a:i17��yD��k��2��#�	/��-���!��:�mУ�cM�V޽���{�=9v}>jy�_<w��^��~�B��C����R뵞�]h\W������ʷ���1{��޺Om�ǌ���M���lj;�GV��l	v��.Å�;A�'�c8 ( P㌡ä�=»���@r���,3�H��a�_���c��|�Ng�4l��s�O�R`��#d��^+T)Z�虘��1υ�)��8�c��j�22������#X<*��� "�f����\�̝���.޺厅�p�"�P��Ȇ�f�4��g��k��P6P�Aڮ0���J^��,j���ys��{�[Ow̾�����6p��ː�l)7W�d�1��h��$3�l왂���G)3V��_�
K_�#R^:�|�^^ѰW�͖[��JHSq������̣�����P�_�b�.n�w��=� ee�ė&i�kFu���.���� ��쳱���&Z�BE��H���o?HM�	cMJ��C���L��^�Y����zI9
��w���E��.��3y�.ta�ua�n���[b$��Ŷ [�T����Q�e[��S0�=pmn��
u�, A#�בu�ޗ��Cm3p|�G94<��g9�x��'�(�?c�l~9��s���m�)�L��Ȟ��*?(����������~��̊�ʛv�9�&3�� 8Q���Sl,a$}��zd���E�S��~-aK<G�dQ��a�g�O�u k�l>CN��� �<w�ޙ>S��@88D��Q�!���|�]��><;^�̊w�;�SeC	~S<���� ��+����u&_�ꕢ�Ħ�wi
���]@�Ӄ�2!T;�%�;�VSȽHZa#�Cĩ���GY�&�`'�έ�!����g����Vh�Μ�QDC�qrv�B�ʂ=����"�#��J�pey��������Nh�C�O^\���p�<qԝ-�L*��U�X��.�X@*�����PU��J�@}Ƕ�3YkpY��˘#m�n�u
���3���jʰI����%��m[4�oUA%���P�A�7����!�-�aL��9�w�8@�"�7u
�}T:2���z���)*�2�tF|'�G/���ˌ4�ﱳ�Z@/�	��8�� o��&j=L�B�ˆi�\P��=�g{OS��-�jo/bP�'\MO8 =�B��_��Pm��2���ϫ	��:��t�l���ϓ�+�yE���6�d�ET��Lr@�S�=����c��ۀczLT�O�����.f�Sn2�TkN1@��5�8Qq��d�
u.�=���I~�~a��q�=NF�j�1�>�я���Lz��4�!�Y��M��[Eb��+HBJ�4�>p������)��w�����9��JO��mK ؓ��]�4�ną,�y��k��JQ_�������د���b�Vz�86~��&�v;3���$�#��wbN��tϲ�۟N�GH�����ry>������捏�ʣ�du=�@j�KhJ�hG'#�S~���P�i���~^w���HC��ԣ�j���_��x��Kô#��,v��Р���]��$�׫��Ц���$�I�CAQ�(���a��I"�e	,y��J���A�}����� �!��=��Ń�W��i�F�P�%�>M���+p���%����}�$�|����nw沫7���)I�ʨ�� d�K3z]+:7=M�İ�n_�����X��"��Z,S�v�� H��o|(%!�犇a��mP��X�������'7/rY�-j �/tv����}�%�{�=į=�/6ެ�"���+<@����%�9��;���3�	�
��>^���8�c��,�SuJKJ��5GZ]��+���jkTS��UJ*l@�t�z�������{���k
��pA��<�սl(J�����%h�����Y�Ŝ������/��>��- g^���Z�����)�����.��ܕ���W�i� sv���r�B�3��56�â�����G�v%
9!f97� ��Y�{����� �0论:���ɿ5�TƵ���Y
N��f�c�#45\!F�k�l��W�F|���&�oa����`a?��{�cm�Y�?�4��c�`!4HX��x����2߫?�Ķ����1�-ux���]Ã'��H�l��0�TAڣ����Kv��/B�pj������2�(�\��
�Tr{��;!��r�]��D=co�mU	P��n_(y��$��>��	���.ρIa\-ǗY�r^���ӹo5���\\��;��R���9�����L���C�Yj�*N���'�WD���_��,�ߺ��x@n(*}\z�šȔ�AF:��_���J��2��y��%*�5��"i�p���p��\+�9Û�jӯށe([*��s`R1�Hk���-�?���q�m�O��~�/�_q嬪}���xo��g�$߮UozA�b���3�`h74[�s��)֡T�Ǡ�p�n>LF���uƃּ���cԢ���F:�^�bz�`I��ӥW�d���K �˕��Ā&!J,���5�nY�l����]6>�HͺS�Տ�L(��5�>b���D��o.�|�"�o��<ң3����S.����Y�:�����9�����l:���h��E�������9�v/ ��V���5�P����?�k��9�����ZgcB�Kg��O�g`R*���Y������=Kr�0�<M�a��z�m7ӷx�מn�!���
��S���-�$pN��9K�<LS�$|�K���9�i	<cX�_)�������o>�ߎȡ�scr|lG2CH��}��T�ENz6$�MQ�@7��8؆O����Z�����r
� �w �OȔ�!����|���Yb[TVĨ����!�Kj�t�e�V�eG%�mh��sVF�Cd<�]��e��wN=�<�4T���$ ���V�&�)d��r��l���z"�ѲA���4{�Lz�-�@��X�Z�Φˎi�롬 �iB���-Ϯd��|��
����>FzY؇��ڭ�6�Ya3�[���s�3�<ln~�8-e�՝������!��n"�j�Ur!7�y�U-�3��fF3mXS��t���ڙ��zRu�K��th<#%m�HU���[��/��C����>�yu�/���4����E ��ʫ����8�Q=�9Y�c򮥈�^��%*$�q�xe(�������[��7���/�H�zw�H�6v	�~��_�e�� �����Ŷ���GhH���X�4o��hXLH2��F��7�2�p��M��1���σa���*���qO��{VTT�+86?}`�}��ڰ�AI�ݫ�������&K����9��X�m"_/����ۅ�Ψ��B�J8��.I��jlbmL\��e$�L��,�{$�Y�e8�gO��8��t��)��h�����:�lS�*l!+�jt�|D� �=GY�tqi�wb�2I�����2�6ޭV��� I�b�I�{+��<]����u�XY��OPЪGi5�V�l��#��9�Ch2R��5�C�m�ku}3������}Mr-2�=�I�TH\�c�	rv��k�]v��UiN3	�fP^+��@ng"0v�ڷ��R妱[&�g�Kֹ�
W�2t/���b&U��|&ۑ�+�q���+�Dj�Hu������/�Xl��歟�������6�Q�@��f�7�G����^��ɔb[�)r�?*l�9>��&y�~^����E�R��d}�R}e�$9��k��ZO`v`X��յ{���5��EN$"�/ag���9�B$�Z���?K���/��_��K	��2>9u�X���P1�+:�Ů뼓_������s@nab�(�z~��gjJ���a� c1Ĝ��^z�m���6f�b�V���r�j:�=�`�c��_iE�mS�	�++ݮDu?޹�t4K<�mƓ��X*�O"�I�B%Cļ�X�Xq�X��95\'�A7-Ow�+J�����|'����$��$�u�i�?��qL��Ȇ�pX�܈�O�(�4>�9����/���ޖ'@;���Z �j��l�!vc��d��&~S�����6R~�1�M(cn����d�b���dkS��Y�uZvG��g��[O�1��u���@^� p�	�B�����O��T7�zqUU��,�Xr��w"�t��p0��d�I��*�2C
��rv+�/�1���r��T)�$(t���!Xa��	
jI����56F�Yl� �����S�R���NYH���BbN ������&7̪ƃ�\��P`�2e��7�㋽T�l5�0����H*�&G�sf�F��(�9e��\�}�t���ڱ�ݺ����j�w���y��eֻs�Ƽ�Ƒ��� t�P�.��h���`���2fx��d4zvV����C�t�z[�IX��we��G�]w-W��h D�>GM��}?�^1/�?ᴧ��F~���b>%/P�)�{->�DQ�r�;K�Jj�Ʒy�S���XD��YM�j��vbt`�7�>�_�c��q���U��1��ɍt����:DIS�������4� l�W���/��`�(Q�0�'��!k��@�9�+�WD����G�� [�y\�A���C�Ov_]���� �Z�=I���G���k1�!b)ܖ:�3E7�ӂ�/�o�9Z����.	�V|İǝ1%��5b��B'2��;���{�DȄ�|_.~q�C�-75��#g<���X�	'��a��N�ɼ�79j�|����$U�ѧW��f�^�	J�h�����&�45c�y���Xz=9����:T��Jt�H;5j՞�	���%���[�7D՚O��E����x����]��HDwE|��p�A\��'��&Q\�%�B2܅�P�	�-����������W�y��t3V~�k6&�|'?/)��8{f;�I��<t*�hkjIv�G�KWQU떱��}�����]2�X�U����7��l:
4�-�8	B�t�@Q�l��ݵ��7��R��!��.���m��6�o��l�7�6x;�8\V���lR�ES��{og��-�����*�+�D6+�Z�>�38E���#��'�`�^����V�mK��A���>�o�V#�N���g��4���Ʋf�C�W�S4��d~�-��
��ٴR���ى��(�I�|o�Y40jKH���E�c��zI����p�}�����Xy�������v�1S����+>� +�\u �Wv��+Q	�v��|�Y�Z�n���V o�D@F�/��P�,I�>�.ʊ�O�8����3�k��
�d_�Sh4��QҷW����*�;��V�5*�D���ܽ`���1�����v7�H�1��}%���B0&��#&a��WF���� OCs!����R0[����u\\����G�S� Rהʷ�"�nL��㦩�GW��4(,v�K�vW]��ӫ��,�r�h3�]Z��q@ZMK�N�X~x�JR�r�IB�����c)!+�]��5ț�o��#Loٖ\��"JCC��>d7�;����ʍ�>�y�a����k�m�	z���I%�!^N��<�~f7Ȭ|)�����������]w9hR� 3mM�)�3����G9���"P{���z�|���Q�>���"�es����a��w3�I�L�ca�$9,�2�0(4N8�op����Z�yn��L���Έd3!8��lQOfC+�t����3�_~�_�U�V4�ȒmJ����o�k����~+ë���)���zf�\w���(�J�䤢h�'cpt��!^�824Z��gTf
��Ƃh�_�7�kET.�.���vg>�C�Մ ���徂����!r\�.3o7�H�ȪՒs�%Q�U���\�-�ηNh\�\���pY:r[1�=����j����c<Y�,zt]��9�Pf!�a9<��kςu�D�����c��q�z��|��و�R�/�rC+�\?C���ɤ���,(R^]��K֢����l�ǂ�2�e	 =��0e�3���z�N�(��ޢK���)���V�j:��Q��x"���t�?z�{��;ѥ�[��e�y*��O#i�mR)o��5Nk���\�)$B�������2()�/Ư2'����7	�4e齻�%��z;԰�?
�ff���p����IG�l��?�k aܘ�K8���NI6�
|Y�w&ˆ���[1�SWP5^#͉#�U�⏍g2��@jb:ӈ�79��1���M��Ƚ)�O�5�	(����Z��4 �[4��C���¨���¦w-/���5��;�k��ʉI6S�����m��e|�����m�2Ot^>]r:�ٹf4�Ʌ�p���~g��Ѣ���D�����{0I/+U1dH[X����+�Lܢ��e��}�+����>֠��R1�|�m��r�_��+�tP4��k�-�w�n��ld�B�O��	��O��#�-�"=
�ßR`�C���.T���8*O�x�空�
��6��x]Eh��K��j���?u�|���$��)}]�`�5I��1ڧX�)�s�T�|���|a���T2O��_��z�%��8�� rk����3����}àr�,!���l�Էx(�:1A���	��&��4l��:T����={��%Ne�����d�$e6M�X�˻)W�t�Aiշ�WBr������#��вI�x���K�^�V.��ε���,iK����3P���C��Qw�J��� ��L_G���PV$_@qL]�b�w9o������������a��D��`њ�~J3Ԑ�m�>�n���+�=���K~j��r%47���ZH��C1�QK,��l�yG�p�7��V�Џ��p��%���o?P)�x	�����x/Y�8 U��~r��I�l.{ٜ���7�����$�a\�4��ɗ+0Xē��x������&O���ِ�5���65Z��ԋ�A�^������~!mO�~���r�;�Kp��O:�>����}7%��hz�Ee0,8`{:o��6�\�mh��}���$M� ���l�`�H �C<}O�,�I�7.���v79������Pہ����O�{]�]	�F������j�x���E~��Ĺ��>t����#�����k��
�������_w��g8��Ì�A"^Pސ����Ӓ��	S׀c�s�ʱ��X�^.���v��+Б7�t�U�-�à�Mr�����<(��W��Ɗ�g�'�;���f�L��:w(L�@H�iJ�m��u�n6�w��/�v��E�fZ�C�O��;��5�uc�����w��v���8H�d�{ UX���W��2�LH񦲺v*� ��-Ӫ4����{X�9��h7�>����K�+0�5��� ��b	��>upb'��'�]�#��(]�'@x	S�>����=�3�����|-����$��+Z3��m���/瓨,����@vC�=��᳀I�O�m�װ�4�^]��mG�ɂ�%��{�@%>�(N��t|��
M-�
�֫�&����y^� �̋{�xiܼJd� 6\AC�qs�fH��r�<�t�[��'�)�I#��ŉ~�c��x��`i�x� a��ѷw���kx��=����]�R52zo���j/4�X~>5�Ӻn�J2�Ğ�Bc�;���-8�7�.��⾟�/�@$M!�m��jw�[�q�[Z��Ύ�^H��A5r(7ȁ�7��SX{>|#�lv̖��J�]q�t0�A�b���m�KI�eu�ߜ��i�B����IKS(�� �k���	+�Tz���?<�7�|O�VQ�髓@щ��y0e?*.���p�<D1U-��e�~f*Gڍs�L��������5�E�{���w��)d�B�-g=a�y"�#A(�mЦ~4�jgֺ�r�D4�^�ku=�:��K�U�=�~h�=)�e.�N�b���NW�ϕ_w<���3�aOز�\�H1���Nz��~r*�F�@wW`�mi�����0�R���O��1H�HW�#��xV�͡z��+�k ��c���U�jbl�)V�I7�A�������7T�'��l�B8��n�v���_��1�ʇ������ޥQA�R�кG�����&���˃e�I�v�wŽ���H��!�,IO��h��F8�!����%=�fzF�6ͪݽ��ir�����"�
�����=n�73P!@i{�M�5j�ыNA1a�߉��H8�A�2�$�0���K�cd'�����'`��Zd�m�6��\���G��b3���,}9���e��L�+#��R}Zm7\��\�ػ]o�ܘlg<����Q��@����Ba9����Hڐ;Z���c�N
֖T�7� %��H �dT��;_�����h�/�t�����6��9�y��{ũ�*cmї`b��C�2�8I������4���z���˭���Xr���#٦�FdeZ�ޜG�\�B����n�Qpی��N�>�z`�_��v�%�ʴon��Q�F�[�\�'��F��1��K
Ƃ�A�kL��L˖�@�p]I�*h� X.����?^��lԍ��%g��t��� ����>�����_4I?�2:ziX��\�����a�)WȪ�x�fC=/�Pr}���x��p[u��:�f�`7YX}c)W���oC���ƴ�h@$�r�d�F�)+�_}�Yf�"��5��vW�d˗OULcu)�S�a���ƥML*�ơ�hv��||�2T�B������V��%�4}P��zM�U�k�u��n' �FV��]��9u(T�~*���3�������R�A�L�$h����f��#�QmVX�|��Xy�'}�w�U%�~z�?OPt�P@o� �^�K�S$���n�!�_��MQ0}X�s:���&3@�e�s#�F�Q�����v��L���UxLjƤ�f�T�C���\�Ph��c�p�6�5��T@�SO��84R�Wզأ���	H2�Gs* �����E'�-��F�IF�k���Z�'j�q�����\��j���0a?b���M�C�n�d�b�ZG����d�j�0Ւ�>솷O�3��A/^Ѡ�켴y�����#QM������G0�?�|
vg�����X��E��� ���T�̗;h�5y�����$-ȴɣa�V^Y���	rm�%�����7�kSA-����V\�5b:8�����ݠ�n�
@HS�0]�4�����U]�T?(|�l�4�3�UP��(�\Kj$�PL�bn>?���iBw ��u�f|���5�0V��F���ad/��� 1��7�$�<��ǡxT��+g�m��HW
(�˗�H��D@��@�hX�V���{ɫ�ct�����d�B�?�����*Ǔ3�������o�YL(ڱ\yA�}zF�P��ǨC��H����|��b"m�$?�-5R��Y����v�����,+�����T���T��
�3&I��`
��W���?�۱tJ�/E~8�N����9�b���.�w�Z��oez-�	,bp~����ǘ���.�
T�����D�+�-w� әYa�� ��b��b�	L����E�&�GġE���#�!9�'|�A7�mL��|Е�T���s�S+��0��Q8O֓G�}�p�X��`[0\��(��5ȸVϡi.��9P�J��)Nʺ��&z��������B")m@P<���v���\or� 2���ؿ=��4�N��"�H)��xۛ1�=�ӵ�L�,�t�����,ȐV{�m��8,'�դd�C�>U����x�%#��;/l�caaw)PH��g����d���{cW���VҰȎ*F��̻�Z�:��f�k�=�̃<9�'w3H f�T�ZѨW���#e 7�;���i���Q��n�� b}�"�fxԜ�+��HK/����y|� �2�����������3��J޸��&b@	)(�=~B�]R�/-��MnY���V�yW�t}���xn!�p&9{���1 J�����iݙ�L&�i���s9w뎏��.�� ��~w�r]q���6�sK�0+?���5!�Q�h��lvf�i��To}Qw��ҥ�8C�����1tk$V/!�9jt+���)�K��#7�ͧm�W��T/P�� s�$���O:�zE:[1�x&�ᤍ��ٰ�6��S��ڦ�dUs��!��X)hő�}8�ÂZ���6SSL�V���DG���f%�rg8��tQ�O�k��_��^bJ`�-�)�I���G6��ޱ�"~����O�o�=&�ff+{Q�A��?'��̬��=��l�y+�=4 �Y�i��\	Oj�r�g�Ѹ�'5ěXa+��0Hx[)5�o�����
�O����W����@
��yJ�Z�5����Q�ޏ4ZF�l�'���י��.�I���>`MG����}��7�-���qb�SQ_�G�g|��>Zѧ�eC�lCJX�T�z¦����â����&3�h(�7�h� {��fBw������m��/=uޙa.8};v�rmK}U�T�\��݄�y1s��>�����u���j����3�U��y���-Q�+2T�zZ$��m'j�%A�����2����G>��*T�I�{0V���D�u�Iu�/�<��u��bu3Hi5���/��1dNSw Z�};m�&3Ba29ô'W���z�8ҏg5���(�i�v*��'ټ��x.ݷ�Q1�����0#�����_b�?����������cz��7��q�ܾ.���?ݎ>%�v��Tk�K���oE��%�_���7���m;Y���_�ȕy���x.A�q���v�W.%�[�=�� d�~�z�4�M�"����,E\��/A�g~�6��^��~g�Vc�j��qah���I�"���ߏ�����Za[�!I9�4��A�nM��)��'t������R��#���vkm��r��:Sb���p�0���P݁�����TT#����r�t.�'��˛1fu��0?b_{���H<��J�_��Bae��V��F_ڟ� $��Y��|�A�j7�AU�-�ai�x�
iUQ��D�º��y{�!�H�Eك��q<[�zC���ԩ�� �7�ʣ�3�!jS�b	P���>�Vʮ��D���ڜD�$\��Kf��[������6��ۤ�9	4RPr�����K�3[Bc�Y8�O.M��OD��9i4!���h&fvJ�nSMr�5%���[(!k"Pp��F��_�'�C�8&��(;YU�}��'p�ʁQ	�����_k�i�qR�;���Vt&_ý�4|���P�=�Z:�<@�R⽧�ivО�&�n��㑢'�a�08E�툵��y�nQ��Yb��?ZcZ@���ح���EU��ӎ��d�8��4_�#4��6�ظ,Ko��3HP���[�eK��7 �y�nl�K����Л�9-H�V^���X�{�P۳.�+�DZ��`�]*r$5h����3�u!��	�՛F�p 1���'�|*�N�;ر۱|�M�'�Ne	�t��3cpt�l�g_ e^����q�	��d�I��Ѳ: ��c��=���-�쥈GuΛ�dWeHD~EvD�:�C@�3��p�Y%CFR2��l��?�� q��ng9�I�Yܕ?�w ݰsV�ڈ�s���zޒQ�
�غt�����T��L�V�a��,����̷גդ+8�M�x�BK��2���1���w.��'[(��7�ۍ`�i�3G#mV��y�K��w�;z0�e׀�d3��v���p�Q9�`��'
�����Hho�f�+�z!����q~��7���	�Ɨ��ǾK��K;�gJ��2reɚ����N�{8U0�ҧ1�#vܮ+f���qȾ��x�I��GU8�i���z�|�(��j���*�'���k�b�T���N�a����@��z]}��cG�eX��~��2�$m>S-/Ǡj1,+9!Z]Ӟ#�xZ4BH7������U���[�
c!��m:�9�T59Y�)9�o��:��$n�D�J1!:��|���O�0�sw�=�x� d�է㚝�΋�I�3��G��z\���!HQE�w��4�զSzo!Z�\$��fØ�&�E&z�#L�sK5�-�*�OB�%���>s="\3XNw�Ad��]4>�ӺI�K~@�S��ƌ��GdvJe��z;�e�*{Ĉz`�I&!q��ۓ�m,sRҲbD��*��@w���Co�H�De)��8���ղ?����7���1y�ec)�`pE��6y֩U�H�b��^�$�]� �x�d�Pqm��'�Ko3B�����c�z�U��^vs�:a�f߳jQ��.�X/�&[�!��% G��9��]�yt%��]�)��?,����s�]%::jM�s�5���d�[� �+�<�]\b<� }�qɞ�{�e�s#w��)HAF5����Yߤ�������� �m��f�bo��� s
�&�Ҟ��"!̯���h��E��zg��-Mv�E����=��rax_'[���G�y=�M�*F�+��^q>܋�O����
Em��pN��g�����>�W}	��j�˜<�x����G����:���.��$ؚB0Յw�}�ㅟ��S���M5&���2o
H�Z�1�d���t����s]�gwI��`���?�-��$��>�U��feҮ;�sVZJ��� Z�p'����P]쯖��P6�~Ӑ&�y��䴀_�E�U��Ce��ࣕ�����
ː@�Tk��2f���=��g8�>�5%*A~$�E���Qa^�\���1���Ӓ������>�i�|it�D���HjϻҾ�)���� clM6�[©�%�������K7�I�eR����BO�3�9�o���i/#�i���)-�|�Jo&q����Jx��W�uT��z��~�q2���������O��#�D�ŏ�%����k>|���h\;'��):���P�|#���}��{�	�o9�=K����{�Q6��
���۔_�ֈ��u� _�s>oZm�����}Ko�h#�����g�O�`HU������B�+á�U���>d�紲�k_i.��~/T�1��ܒG�i�v2�)ģ)����Ϯ�����΍��J�8M������j7w����}⧸��;s����J0iC�',�~���������S!�u���\�Y�*g[�t��T���J�>DZPI_?Y����8�8��-��r��(��.F�v}�ӂ��j���#��UOV����.j���ߔR�/B�?&�}�V�"�)ߌ�����"��nH1A��*�������<��~�~Z�1ֵ�@���G%��Q�E;�Ķ߿�9M�����L׹��=rb߾1[p��%S��X���N���N��A���}��+�s��}��{ m�f�׬泓_R�TMP�~1�W`i~���Xj6�{���A&�"���(���.��$7�CX���?q.T��!��]C�w@Z����kH�a#�3����|��/)t�����% ��̘{�d���<[�A/]E2����G���;_>����p��AmV�
t?���p��HNF�3�����9�}i&tfϽ:�%E�$ٞ�S��朲���5��sbQ��b����~��P��gw��?��f\��rW���Je!_Ad�Ŕ��7�8�A�:\(�<��|�b�?�Ch�I���u�w{ѱѥ�P�BG(������4�����Ԧ���Q @tyo���&i��n�i�̘��B&����n7V�F^y���8�vť?1��H�q�> ��fҪf���X�KtY���X���8&�ÍC���Q�u%��"�z{�JA��/�w�O�+?�鼈���5a!��Z�P��k
�g��I&"�=5-�O9���C�׶龻a�����=|��+�[ro�7�kl���'݁.��5*+x�S���3MOqn�eC��K�8w�Odl�m3�!����'Ñr�_⯐a�F<�Toͻ���T�{X��@�(�d�R���0�#�ZT4�#Z����Ha�mh�����!�z��ٰ���%�� ��(%v> ���z��I��g�    YZ