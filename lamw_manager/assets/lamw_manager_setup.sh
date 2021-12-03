#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1740403632"
MD5="e81e8aceb2c492721e46099c088a441f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25004"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Thu Dec  2 23:34:08 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
�7zXZ  �ִF !   �X����aj] �}��1Dd]����P�t�D�!<D�(8�Ŀ�\��5��W�W�o6�����+{�0;�+ks+/�Q�� Tz�UcJ�>M����i�14���d�}�Y ˫��q�l�Gi{�vB�Ϟ-��xD����s�j=C���r �C�Av�$�➬��ˬ�ٵ� $����>�)˫��o���薡W+1#EK�.�6���9�1́+>�#*.S�d��3�3ژ?��,g���z�&�iu�*@k�3
֏x��;��Mk����u��0�9?�C$*���՜T�g+���s��X���dw�t�Fۂ��4S��nH���*��4w#�a��۰t�����kMl`MFB�+�֠��fCN
yt"�ڮ�P-}[�$-���v�������MčHѷfq�g�^�#��ۈ\�	��Ob��c�ӥm�%�1vj����L*��b}6 ��b?�%�6��21ָV��G|�o+���a!〿�3Yy'�Y�[�K��*ݟN�g�e��*�b�^�b+A�.������Y_��8���Z4��'��0s�}H��J<�W��K���&[d2��8�گ<��j8:��Bt�u>4�l�TuoӦ����-�Qݹ�ӻ�[��čM�	�ȴ	�I�Zb�wv�aS���ܫ�Q��ɒ��wG�(c�0Y��q�+��~Q1��yz�C�abҩܫ�n�
�"�	+z�����E9�!�e}`���p�ы�y�7��8O��kX1TB�^�<�E����tj$�0�jAK�>�7��>�-&!���{��������l��]�{a�D��mŨ�%�g)�1���.�x�^ˤ�O;�l:q11Q覻`=Fq�����B��#��X��ۘ�n8֊��*��UM�w�%B	>nň�.UoC��Z�ּ��Mn�z��!&u>l�ݢ?̃�>(1���Ju{�pRUd���w�@3k���ʧ4);&���ύ��p߆�uo�܀~F=gz��!9���B��'�v�e����4b�"��=S{�B>Yf��R�D�
�%:� j����w�aՓ��vˍ�;(XK��	�8�DLG��LM�Ctn�al���e_lR�a{�4��#D��KA�ԫ�"�,um��,�U�������i����Nsu���x���K�V2I$�@���pkx��&��z�V��8��6D�c�c��yN��ef�𵼈�`�\���O��؆�8��;�À*=���t1 �����1�d�&M{�rQ]�H��'n^��.L��q.�d`�x�1{Z�Iℜ��9<5Sz���F�:���ͱ�'kY����*ՐE���9�6:��p!%V�@���2�(���+,�MXh�iz��{��RŠ�z1��Q�`
j~�����i+�bUL��]��ɵ��Rڪ�91�����m�nn]�TIkC�����!�5�h��-~�e��춤ˏ���v�Q\Zb�����
^g�j�u�5j?�<��ʆ���h�3��3g�;b�~��a��֛�p�R�V�dϔ�co!5���a*#g��<&�-�R$��|Bo� U���G؅�{��7/߈)�z� 0;젡(@��3��\��CW��T�=;
׾0�K�)M���-��������J~�(h\�za[C`�c�r��.��c&���Z�E�^���.iDC�����=�'`�!,t�_�W��e��������X�ns��\&��s�B`���פREL��?�>e�xxl��i�L��<�!t���Uxfu%tőUr�G��ǭ���0�-%w�l�%�?ꨶH����/�ܳ�D^��+UB[ԕ4p�{;��:T�����z�͛ �ӋR#�����B�ko1�u��=S���Fl-4~��	p���j��`ps�d��������C�C��`���?��ݯ�3�x8�d��1ߡ��.O���6��L5�cW2����3�eL	ؠ~��H�6�=�T��d+�	���"�=9�b���t�Z6|�Jǔ=9��:ń,^p���sꀔL/�'����	j�Y�(ǹ.ˤ��}P�|��>* �J(�BS��#��F4��lV��ѩ����Éŀ�n�%$�ERH���ҘN��ƨN��3S�|��WΑ�\(�Q�X��6�YΣ'��)�s�;�ſ*K�j� ��?�*���t)�͗�`f՚\�rT0�����R%�� �Lh�<�`�-O� ��z4�Q��U�+?@b:�R�TA�1��iN���e���ٴ�W�$D�$�52�.Es�n�[����uS�L>���C��j�şK�����Pk9ĉP�'i���13k��I;JE���G��" ��mwښ2I��ru��ܭ��g��$��&��`[������&�&�����H���!&c�h�=�aD����^�ja�VQIy�[Ve�Q�I��6�Q����5�!k�U�rJ*٪�,6M�ls$0]�l�\���p��l`���ex���T�*G���(�mQ��jE(M���WR�F/A����a��� è)������q_&� Ѣ�ߊA8�p����=5���D�kus(v��i����Q8�TO��ƀ�o�l���$�b��J-�hq�y[)���{�xWMrqBI �eokw�"���݋�Y<Ϣ���\�n�{R&�`3��9S������s��+(�њTD�_��p=�'�@����:�����"�L���~c>�a��zka�+M��3w|B�@VX�|Y<bɀЈR5��օBn������,3�����+����4
z�K��".r�F��b�� ȗ��WT+�)��"w����d{��S�#�E�/���!m���`�/��7�}@��a�'�T!�x0}M�J�$;�j_�*yΊ7=;��V�
��� ���	���o�3�=��a�>���rx��k��s/�x�^��^iZ�w����\�9F�W�NI�]��t�����L����C~+UEZ�h��B3�����\ �V	5�
f����$y��O���p��-��&P��F<�(�~-�q��<�`�Y�����l}s���%e�9m��1?�1o�8|� ��k)�-��+g�cH����☍�Շ���PL���T	�����d�H�i��@�̭��7�{������#i�rl��Ym���B��1o\�=��K�X^��Y�Ӵ�x���?�/�w8� ����^д5�F`f�Y<��, U���
:�'(1n��N_�:�e��M�am�T#6:%�l������Dj���Py�*H��f���v�ſ鵗�)����Z@�~eF��b|���x�����f���!�,t߹�Kj�3�^����K����߹7�]aE�"�� ���g��u���:A��(��a���Q�89)F�.�z����[��fU���Gl�1't�K1�&*r�m��|�c��� �3���ݻt1��8V�o�>u��2���@$�s�z,�[F^p]���rl� �k�aT��0�h����e�0�5��m:ߏ62���i���3����ж�3?��h�H��<�2��@?	/v�UY�Yn�q/ w*�M(pGj���g*l�������H��y-�Gj�R��HՔo��a8]�x��u�6��U��i�\ݩ�p�P����Gs�$p��~h�<�N�U߾g��k77�� ���L��z�'KA���8j`<u���me}��N*� ���K���f�g���������YI��w����V�p��.�7����j����{��:H@����@u�����ٰ�I����t{w��!g�߭��N�[��Fjft�C� _o��x�bZxb�c�	�\�l‌�˕��+|��Ѻ�/��>y��� ���%�0��I��J�O9CW�?�oa��O1���������� ~�.o��i��;�����F������B":���υ� ^���@�'��C&?%c��;��i�!Y�L�4�>�u÷&�܍�$��ȡ̧C�3��ߡL�Z���O�K�CUF�Y�6Kp-`2�F,���f��V>F��w58t���L�f�k�] lJ��1ʟ� h�;���i�L�Jyk���K�y�6.@�|�kT��h��|�Q ,y��������� �xb��i�-rd�?
�n݄,I�:q��5�qF8(kʛIT��0q�,����`�^G։Ɍ��vn��S�^�ï�?����AR�_�E�[$�/��
�����55~�y�-�-��s${eX��XZ��w�����ْwk�@~���UGM-Uh�Z"	��Zp��i��H��
��̾�8Ġ��)f�e0�m$y{H&����C�öe��F��N���]����Z�2�x��lX������AԠ31�U�hD���f!�8�@���@��#oi��|(]t�4�n�>�|F����u!�\/(�CXz[z��!mk*����y�e)��X�:��甅�#�G��q4�JQG��f|?�����j�\�>{½������U|#Y�=>����	'����5uW3�+�W�G?>d�!�������80M9�r��A��2����Wf
{i=����v����I�\u#��E�G���`�-�$M�7��H�%�XӭL��zN�փ5D���xv���S�m��q
�E�P�B�čI	@o��{X�����ڜU;���#�@��`9��Ʌ��Y�x_��A��c�};A��gY����q��KR:Pf!��=�h��l)Y]u���CoѰ秲3骭��ݱ����=��k&0�S =�vg	�_w���?�7��M��T�>�>��;l�9~$��x���u[�s����=�
h��$'����ր�֑�`��E]-�&��ۺ-�D���r2#��y��Wt�Sk.a硇���A��_�F�FZ�E��3����_AwW�mS��F�����u��ʝ��$f�{���H;+��K/��e٤a]Alͅ�_݄F� &	�W.�5��.��wh���p�ꮣ�mާ��K��^��em�͟[&IkC�\�� �n�OU����ߍ�?��\��݃��Y���tM�c�����\�܉����R:+"z�8ʨ$��6����3z���=7n<,���"\1��F�m����0���Yg-���>��8Q�C���"b�K�m��0+˿�$���e4S��ɳ�g�@��{1d���F����5#��J\�/�W}�B4V�3��~o�d�på3eY��R7[e��&�)��ź�d3\,�2lSz!k@ 䥤S��:f�b=D�ߨ=d�������|Z� L�5z��<���Nwt�I�M;?c�@�N��;�0�Zlo�+� �2���1���/QM���h�S�}|�"��e���O�FX�Oj�Ej#�I�/�r��w�W�0P����T�+��r�<%�'=��E �E�3ؚX��&B�ѷ����I�k��{���'�{(4���ld�:����[\k�O4O�:�M��������c�
j�i����qL�~�X�~+7��L�DՊ9	ʷ�)� �����p"X..�䝲<%�l�_����8p��{�A\&�������5s�$f�jфAh���F����!��p�m_cءE3l�V$l[hOz���3�J����n�k�d�+I���/L��};a��NqlV[����TU�����\;K����hJ��5k��k�+�:)%D�;��M������e�d����S�n���f���ji�:}���������vľ�'��9S{����꼩WS]-�<�BԻ���* x�\�N���g�J��̈-��W9hh�y�@�Nk���\t��=���s��� ���7��4^B�?����̬�au�-��u>+ N.�aX[�>����
�H�W���h/��� �XW��+~����`�Zfp�Š2p/Q�RB��nZF����9l�x1�^���%o�W>A��(��5,��"O�I�p讞47��ǚ�*%��@89��X��?�/�����G�a���w��&LH��n�?��K�s�
�1�Co%�] ��&qH%��Ի��x��8�<6H�6�s6��6?�ѾK�:3:�W@�7�<��Yz�5�ŷ��nOM4C�t�$��@!�-'�Nl��}�'J����666��������E��m��;%�5V�obmuu�~a���Pz������, ^yUb�4��8&MT$ʹ��T�f3�@���l��!9�,H��Q�h�8��0k���WPIf�lp�CR'���?�g��S�X�G&;�G�����}��?�߽߄I⃐��K���R�x�ܩ��{t��p��b�09��Tͩ�v��,ӧ�x}��˧��
�q�(�c.|.QT��͍�d�-��F�厜�$��^��)z<�Z�u��`nS�ɐ��wD���*��z㓤|�iU������8�K��H�.G膼�4���Ls�2����*%�5e�q��&+��u�ṟ~}|1.�Q���&���Ņ4c��;	7�����u�*�;�)��Q_g���޴G���hV(�~V��a�M����^���FL�F�r����Pv�GY\�o:�r��.���:\�{�4\C��-���A�O�Ki�҂��#U �j���몕�A�8�o]��Y�AR��K=�9�^��<C�e�C��	�X���P� ��̫8��$��k(����qxn��eƀ�"��a������Fu4���=^@0����xrRU��+����BA��Q������_������z	�O��Z�n�g��Jk�E�i�9jۀ�2�䏠�<�h�A�x�	.�d$�W��|!�MWP��Ɋ2�����sS�~�Q3��L`����z.���̰�u:�/|���rͿ�4��\ۡӬ��.~\8^��t��Cz�k��r�^V�8�n#���&�0|�吺�
t�A��֌^]��i�/Ucq������3�p
PZ��7�O��%/K"�J����O<4�O�c*������6$�3N��D�.1"�?*-trmUd3�}$���v�d[�cS��F��u
��7��S`�4)¨��l�,�ϓ���~��f���7|"vtA��E��>\�	��Lf��<
�.�Up����sZ�
�~��=�0�������y��`3��Y�EI��O �Ck�Ӡh�ZU6��z�c��5� ������ cn�Ri3� ���aTǝ�(���&�H�1X�]���(ƴ�"���fk��7Q��c�~�/��#L?!��j�#���7D��l/����N��(b���~��p��+<�Uy��<�����d0������N�S����.�2n���|�JW��%�A'��%����
F�/��Q�&��?���?nK��%��NU������:��ۧ��Ҍ��~b��h֭gr��|xj��M��I"��N�������E�]D��l���bm�VLe3s�<��i�ܔ�v��v��v}�{ZD�꫻�1�cN@��.�E)ހ���Ύ��z������`%7X��P������(��XVΫ��B�+Y�:m|hľ��u��>��yѯ]Vi�JQy0<'
Ɋ��߁Q	���� ��I�	�:�䢬�:o���UVې"n{�����.��'��'�^C��Tc<"���@3M�5
�kɎь���̹���J�>�щ ���Q�>M�kޫazm�?s�0���A��_s�	���AoM��e�D���n�H��r�b3fE��2��<��59�# �f��
`��������fi��,K��ƨ̀aY���'D3A�4_#��컶�3�����qu`^��|#��*�l�Dڹ�SHZ��7�� ��q��B��n2.�����U�������&�qֺ����%�2nxs���x�rP��·���O.""�;Ek�Ģ���w��>u��1(�qR&�^G��J��9p�4xu��W�T���E��p���P�x+U`�:|.�����p�9}R��op�Uo'�ֽ�N�@�f��Ya�0�����Ͱ��j��㚥dL'ϵ.T��m�z������8ɖ����	��X�_��g s�u����&J� �&����RA�#�����d� ��p㾗&'����s�9�h����mf\�:k���O�� �9����C��A(;gk��6w6҉!f����C9�������$ދv��'�iy�2�c��>�T���=��)�l+h% �m�˸�;�gK{��̯�j�y򄭐cT��c�]S[ۍ,=*��lɤI�Yf�k�l�R�)�{���˂�c��ge��ŭW�r�����C��B��n�2��j�छ��1^�M�,�u�"�����+���8zV�v!�$g��2Y�����`�{:��J`�{�	�Xo�� @����I��i�o:AU��;=`G$@����K�h<d�݌��z��Ur4����	��n�v��"�x}����v���������s6��%}�5�U�!�7�UXS��4B������M����5��,M�r��5��&�����D�^�+?.fiڤA���(h�c
_�ٜ"�#%߰L����T�O'u�V�o�3�X����7GA�c�-��K�#ћd�[�.r�]����p��(�����ELy�P�C�k�����H�9t�#:p���/��JR�j%����H��fiܥ�͓D.�ȈQ]�0s~Fn���Y@���
�BIe��}\-,�IC�,�w�6���뫶���"B�5����~T䐮�cN]�o�]���`���<�dzu=;�m�Yz�P���.ݯ����	)s�Jm���A�h�~�C��9�O��Du&5�j��j�:M���TOe�q7g{�k]'p{_M���{C�p���Vja
�s��+�u�������0<}�+j��!��-c<~?Z7b����w[D>Q'��|Ҹ��oӦG׆�'������l�ڧjmO�ɸv)_	�ʠh`få��#��Z[p1��V�S�����Y��O0��3�X'X�1���Y}rG�{�3���O��Wq2�``%�h� �_N�V�2����j�软ٯm�����'��&��'�~C)m~:�[$}�T�}��Y�8�>ęCk^����t�|[75��|��[�`R�@�$&�?�ޫG[+,�Yd.D�K�܊�ݔ��6���w�Ods����D��D.�±muUK�'������˭0;.9t{�z�A�6/��tv�����yj)������'��͜10[yٛP?�{��e܂v��Ɓ��oe�J���� N噢jژ��SXX��*����--٭��bho�B�u����s��q?�lqF�"�:� �E�u l �M���,E�c����V���-d^]ͫ���z��/����Nˍm�AnC�jژ
Z'a��F6\##�^:��ޡ`�� ��D���V$���[b�p�d��?Z���+�D"7�wl�+�0�@*?�Z7�E$#-`ԗ���E-\�Y�>��1�ur���h�]��&���bISP�C�����7D4Q�=�l7�0���~sU�2\��� ;�n}���Z����;-��DDu��;1s��E�;��]1�
|{��������['���B�W������NF&�?v,$x���_�=���ٸ��U8Z��PKi�-#�%Aǡx�Bygv���=QR���%�ǐ�dR͵]�ȬI�J��(��Me�G��G�"���q��� �G���Qş-�UBM2ƝRC�9��g�Z�G����C�䬏TR����n��d�[�B�ܯ-yJ�(`��}�
-�~U<eQߵ"S���lک�
����l�Ν��� %��PH	Lj_���/�����ך�݈{���;���}dZY7�Z��m�.-��`�E�P�F������/��$���Zo�S�)��$�����
����l7�&�G%4h�܎���0�lS<b�O��觎�c�,�{��X��Ih�J,�AzNɱ`�4���˝7�h��J��V�S����d�gz�fV��8s�W/R�TH��%ן���ё\��a�t�����7��9.S��{6�"j��dz�X�0"v9K�Tf#���q"�%�Cȉ]Q�!V,��wp�hs��&Ltw!t��nq,>Ԁ��w&E �9m�`FL�SV�����9��?:2��<��������	Z�y���4v�Yjή�rCX��d����Oڲ�;`�!��A�Ɉ!-Ed���}�N���J侁}�rHī`]=�s�a`[��6LY�?W�r����F������G�{CE�9�>�5��O��Pѳ�7e�����>�ʫA�7&�W�������
�`���r�dm���Z����_��I�:n��DD�۳�T�|�Y=�^֧�UpF�U��L�X��xquқV����5ɚ��LM��d3�+���"�	��1S��K�)eq��TAz�M�5��yʧ���l4�����iA9_�G�T 0bڭ�O%�A�}�"�H���ޖS�<�#]tp1�l&�n��LpW��.�]�,m��\M�����D[������(}ZHY�BP�tٞ��N�~�q�iD������Lb�!.�1&I�K��
p�أ_fإ�e.H�,j`�]RS��� /������耀��y�[����Yh��	t�;z����I�x #�9w�8��o��r��+Rڢ���H3h�0
l��0)�Y1YBc�v��ב�^��n>�Jo�t��̝�Cb��}�
h�*��v������z��G
��`C�`�(��a���yF>�d&���
y�Tgz����:��SB�1��S����'r�k����<�G�|2��L��XI��\���W��$rQ�{i-]w9.��H��`�7mUPy6��;j���(��>@e��?8�g?)�Sƅ`O���[��v҈��L�c�/,������jV}����~U²T�*GWco��y�ي���[4�R���y���Wf�L��3�;<�?;$���b�,T#ν�nm
� $2�RE�����(�Z�g�g�>��	��R r�e�"�@ �&���{���}9�m��(�/آ���'yN54�Dq��=h�A�4G����o�g.�9HkR�훭��G�Zy����Ę�<7��/��4�����Q����*�9��ݽ�N��Ƴ����n٭G#?�/w-A�����K�^')� -E���sLA-k�����WY���Ek���L�Ͻ�� Å�N��̴ǽ (I���%��6��x�,R��[���3���}����v6�[Ϙ;L�����fR���l�W���e�3x������J:��j��(�v��&D�2��(���W��j}����)dW��ԯ����-�_ͻ�_��Ǝ(��/��q%SD��QWTg�Pp5vZ����̀��T���VzK���*��/-l�
���m:F�:X?��ޓ9�"y��D�|/=���Z���y�fw\K����9)�V�|I���W*���F��[�h��$�)iR:�HI[���!]Q��������Ɂ��J|�ņ�~םф3⼋�-��
~\�N��E@ք^1uR/���#XZ���]��厼_~D�����K��x(a�f��XjR�\)21�g�T)v��e)N�°�p�Q*	`�z��-��r����ճ�s��cqĘ�D�-� 
���9��ԣ�S��Fk)���cV!��Z�)!5\�7��2q��� ��Bⷫ[�q�mqc�]f�e��:�h�>��V�!�L�>�4�t�/�.�Je\���m�p�3��˜��\�2h��l��W@2
(먻5�2�u��,[W�g�Sǜo;.�A�@��Y~��w�)a���V�$�21W��|X�[�o,g]��⠞���J8���)jV!{bT{��ɼڀG�*.�F0��Ռ�c��g�mG�{�K>��aa�x��8��*��u���r�E���/i�6�����"3�ȧ�j���LKZ�/F�ө���Ua:C{9��&������`�Gdў���Ԁ�e�=��@A�P�$Nl�Z�i ��o���J�*�W���nT^�x�A(��z4"�w���}���±G���M��X9���t��\�����+'����+�T�d�Պ�7��?	��4R7�I7b;e�o���3���H�c�qX(Kg#,Ł�a/6��j}�;Υ+x���s�"�P2^�W���jʗ!�v��F'��T��N�����I�7��^\�»�]x�D����((M��nX�`S���s�eZ�6Ѧ��X�v~Q��G:�o�/�h�B|t�	)\�w�[DN�p(wGر���B�)�`�w��
��(�'?���L�wA�;�I����dL�̿��&^���q	VN+�5��F��)YG�2m�m����=>�]	�&��P|8�(�]�:<�K��Os������@ާP=�Z<�=�+ļ�(K��3�"��m��w��=ewd��cVO��#ɇ��\��~�p�`D��TE}���6i�$�u�
-�x^�Y���Mn��A�D?(��US~&���u+m[Z	I��7�j�1�����mf$5�`Fz����x�!�i\.�M�����e]d?��ؖ�GS�F�d2�����m��Ne��m��h���Cj)�=�Y<)>�y���k6��,TI6��7A#M44�$̾:��:�޶9����y��S�;���v8�W���P{�O�%��2�:��2_�gg�ݰ����#��1�<�tnMH�psq�ֈ��؋m����,�C��* �_ew�S�,"�<�F�Ⱟȅ�nϿ|�H���*pmoPG9_�|:_AQS�2P��h���%�&��앣��z�����=��NH5���l�_D��A��
R�OZ�ҽ�bɾki �8�+�arN�`�09~O����B� ��h���6.~�e�n��H���L��y���"�j��	5ϣ�SmEb�Nb@��T�9'۩�ʴޤ߽����ӣ"� �	V�7G�ܟ~����ly؉�RH���Щ�:�r�Z,��IⓁ�ܢc��o�! ���y�"zJ��z�Gs���b�y��tЮy�Y�[#��5���!�]\��ʣ��
>�`4�iv��ܕ[�  �q����O/��Y�"jm �]�V���1̇�gʔj���(7P@���ɞ��;ݔ6�Ь%�يi�#R�@��69`���bs�_��/`{>����2l�a��p�/��q_\��:���^��*/4`��'gj��g�\uz#�f�)��Sse.|x~uZ㏭%�@� )���=k��	���OTh�����O��	�1�W7�r��lf�b�!��M :�FL��@!��(G���4�X�hB8/�����YW-�Z#�������l���:p�4<��A&4�W�p
�+���@���&�l�2�;B������`��5�Fj29�v���0g�I���(n��B��b5�Vk��4��7�<*�H8L	#^z�x�����z���Eߠ�9P�|tn%j �B� ^b*S�`u���->* C�SJ���F�G�1�H|�h�C8
�ͱ[T��c��踶�ŧ�~�����ϊ���1����$MR����/�"蓍��c�ۗ�]��%w%�>4�������)7��
W�!=�f� �
a��+��<��j9yrPV�G�q�3��Jʺ�X_�O��/lp:�U�V�}s52k�ۆ�^���M�
���&�y�K����x�+��x��j�� QU�+�\KP黶�����L�7�T�G"
�䎠��g��O�3_*X�_
b _�1���2�v41��e��W�=W!����s�(,��DQ�p1�V���P�5�#q�����^�/4x]0�s���/������ܼ}d�T���+F2�x@%׮���5)N/�Q��#�+�uG�@_�@P�j���S�8(tEJ޲؃�!��/�㠴�{å�0��cP+^��Z�s�Yn/J��WH޸gp��K�0c۷�qP	E��Jb��+0�(!��h+f�W�o'%8a�v�B��rj:-�?=(i u�$b3|`d�����>{��#2�ϣ7:�+�;�k������O[�xiſ�a&0�j�$��26R�y�\`��À����E���K�3��4pɍ�.b�k�(`��~� �-7o���ݡ"�R���Z4��)l#��I4��L��7ɣ�ƫڳ\x��	�"�~5nx~�羭���B�{����I���r���kq�M���K��/�/�J����tUm7ֆX_��a[�k�Zl�b>��ζ�Y�z��>/l	@6���
�����y���kBxz���Z\���5{l.�<T�~���k�@��r`]$���&G��85G��oX_'ߐ@�X��l��>�H��
���	ά��;�7�Ź?��A��F�n�yr�3�Pϊs�֯��Vn��.l�������J�қ��L�����$<2w����U�n"��0A�ٹ;��\ s=�w�˭���/a,�g��d����r����=�������e�/o���Q��8��K���Q�O����l�_[�O!Ϭ�Mӑ�dS�t��a|��L�|`���y[�Xed$��i{n�(C�f͎����!��f��v)D����7'1�j�\�&`T������E[�#hŔ�[jC-VY�~h���)���u{�ⲿ?4yi�)��f4;�,�1o���Zja�[����-�d��f�-�18+l$Q�f�>7�D��C� 5��9��>)TAH�Px�F�C�����,��Ju���4�;���Ƴ�-SQ U�Ա�R���@7i&.�S��A��ȅI��6��
�(�T�(7)�-VAOK฽PQ�U��]h�=��*�x�x����j���V�\ �@�-�����D���o(wO;����Ṕ#a�>�(8lT Z-��.�S��R'� j7�V�Z��5�&/� )�Or�%C�8m�5������(��`��A�١_�fy1�jk6��o�2��,÷7�i6 
7n����y�虹�#����o��8�~�M�&c�٨�Mw��y_�,=�.��V�M�����$c��s��,��,�5�R<�_�ɽnO�>�A�l�T�Wk��FٌC���b��
�(NKXϯ��њ6�#g�{H����{-0<#p��m��g0�5+�s��Mn�UX:�4�t�V��#��`9��}i$X����-�A�`R�&xkW�)P�����ATKD{[�T��P��1d��4��ѻ��Kۏ�)r�p�n�0�	�Z�H�$��$|ѕ��y6Q�
��/�X7>1)mT��uX���E$���C�9ň�2&I� i?�h&�E�df��&�*�-$�1�`۠�n�~^�hϻ�L"�.�LM�3}��"=�}*�1򳘈z��(^w\�SNJ�t�p������{\лY|�Œ=sh���\X��&'��}5�iN����D�U}��%�^>�V�@ޮkc`f�v ���Q�X�qyr����*C��E�r顥|ݕLw����&{�;�5�;��'�	4NGج� *���"�z[���Y�g�W�4�=�7��"iG��i��d��`��v*�[:��hCZ�}5I#4�T�� ȣW|E~�kė������1�L�����c�f+���
Ʊ���֬��;����OI�t�D&|뭠̷}#a���R+5Q֥��������"��׸��+�x���c	 �~u�̒�1��U*��srD�	'�=�M�2,[�� dw�{��V�P��9���%ޤ�=hD�>����yy&o��[�u���ʔI������R�����d�h��Ѫ�|�0��k�j�j�Mw�m]U5�Ī2f'�H�-ȧߺF^�������.�BA�1T�ȏ�e8��JB%5Oor1�)���oY0x�.���֯۠xi���E�D7�spx��Hw��c��
b����ͯ�H���M~Z���Nu����P��	jc�=���|��3(�@[�ޗ	���]V��ŝ�������]�{�f�H�=2=����
KG��×��>~W~(��|)�n���!}.��Sǧw7��'<R0HK$�nr[A^�ই��P��#�P5�
b�Ђd�\�w�_U���l�|�S�oK�Dc�V}�݆u�w�XA�_����5�:��J�t�.���aG����-���7��Y懖0ihC�Sm�.T�4�x8�y���D��5�D���
Y�vK�8�G���3vy9W��[.��QD#�/�;F�cq�%�>���%n��B�3G|,�^�� �X��+�N�Gk?aD��s�a1�CyP�p�� ��ҟB�&�����t�ԖMR6b?B�G�iZ݋�m������lX��	�r|�&�l��w���?���l�,�6�N�9��R��������U��""�iYt���!���b��}ٹ�h���M4)�V��`�4����񃉟�}X�Mކ�)�N�ו���k/�%���Jkz`|d�0b�u�*DEg�Y�[�;>d���#'cs�g���j�?�s&�dc�{32x�C;@Z'�"��r:�ldR�M����QT	��,����� ^�7^ւ��FkI�Y����e�����Ƃ�'`��Wz⚶����q�CJ��r٠��+���(:E�1x��O66F�؎�;�Yy�M7�+p	+e�|���k�Ժ��E�B#���T��Vezxo��2^�֛VV��e�*!��()k;��>9�.3���:�~Za��E�O�7Ʊ�:�����=��3����e%�T�-�����۵C�v��U\�E6:}�x~KB�B�?��el�$a:=S�u�K�Q"���]C=�bp�(��Ok�2`���q�s�<��k�?�_Fʧ\�%w~�컇�4����noI⌆8���>x�gL�`�=�IX�vu`��F-_�"R���E+��	����m+�ZjR������̦�]���f=���æ}�n]C,����Ԩ��L]v�+!�jӸ�ʋ�G�J/ـ"NP��a��~�?�O�o�H�/{�+'ȶ�L\7���x ��)�d�W�H-��{�!^���:���h���	b�+|pщw��BU#9�Gg3�!2����q�_����؂�ey�Ằe|��Y[{��h��#�~|<$��勣m$"��P�>ߞ���=\Ze��1�"3��<�����\�6���Ʉ������H�$mao�O�U3(
d����W��`W�m�aYB`BeW��N5�l�c��P�T_��N���pJhL�a��%9�7��Q{x\�&X .4�'Dc{Z0;��~p���M;].�M���mU���1�6h��?��dS�y��xve%M�(�[q�R6C~��ׂ��v*�t����cD`_���:�w�ǐ�D�8��$
���qF�u� �uݪ�V,Z��H����Ћ��m6�+�f�X����ezg �Yd����N�ȷ�ת%�Za��?�����wOՆ"\��f�34���எ�E����_o~l@�ݑ\eJ�
�5=���I̠ۜ�v����C���8�&R|cۻҙJk�>�ߡ�����W����U��c�� �7�O�������A2����7�٢�6z���p��9���V7�R�4�[��n�H���+�����aB�_�>[_&E=<���P��h�蘩I�k�m�rd���1h�X�鰙Xj��Q�RY�c�6�!�#�n˶;���c ��plf�0#���N�nM�:�p���#�3 :�?^�,�'��:׊Ȋ��:�]�*i�dj_�&̏L7O�U���PMLԋ�gK1o�&�W�%��J�*�-������`�v뭀n����~ﳬh�ͽ��S3�J�듉��������M-�n�ki���4��w}^^۶�Ǝ%D��!�H7�_8�x�A���5G�:���g��_y�%��M�,�7q�՛�KP�����n����q~�䥽�tbEk�/�yq%v�e{��S������[�7��R�n�ujT(p�Kz�M8������+@G�;-�(�X%�a;}f��� ��!ɔZ(�m��{�V��Z:�����۱��a��x#�
��fz?GV^Ŭ���q푻犕��9x��"ߜ�L�{���l��b;>;I�6��=.]m}N@���𼉥��{X�-�
xqD�z���#0�=$ \2����C�� �4�C{'ɞ���i_ֻ��{�������tG����YpQxl�ėN�r�Dܮ���
��iZՊ�]���c]�S���a�{����wr6����k��E~�̈́8D����7�/�jғyL[u��H�|'�6gwZ�$n�At�x&�-����)���%����#�^3�X��I7�~YL�Q�1�O����r���>*fXA`���k�Ċ	�n骉�p�i!��=�)�e(G	�~��؋�"�P�˲qw�ې4�%� �V�J�\�C9\
z�R�-���^������Hg%�sR�Ҳ�6%�|�hT�Y���\���xă���C�2��H���p�h�� ��,���Q���(��w�CWX�@�kYZ5e���2��<���l�e�*�L쨩���\3�Q�U�GU�펐�i���R,��3/�,���e �/̾��l�Վ�W2�C&�@����X�b�L��̖Β�����*<r?ڰܲ�i�l;�8)4N�:`/XU�wU�@�ڥ���%ޤ����-r����N���Rv�O�9��i�Ha�9� ����_��m�������<�3-���`�}W'�4k�� F(�	J~^��nR�:�p��n<]Z����]�1u�� ��/�r�`����	�?��K������t`�Jnٌ���y\��d��lk�2ُgv��$u��Ş̐""GΗ߻g��b���򯇼�
�D|�|ֱ�|����8�T�1�����捥���1�G��:�.��6C��N�.��$ө��/Y!��|�y�\nN��gP��>���e~M����k
��be5i,hyL/Aˠ:�A����c����.f�����qQ�������
]����ׯ��d_��sG?�o|�x7��.kb�`]�I������6�K���=?�]�h���0#�����_���ʤ0��VhW�t�Be4�%3#�+s�"���
�ۓ68�hWگ׿(�wS/�_!��s������FA��y@�F�D���uT�,�Z���w���{:8d�Dn~�3���`��+u���|1�`}�ca�������n�l{��=���i:
������ �\w���]R���n�ŉ�-�t��(�e�2Bƶ��±�R�ʀ�h]q_���]�s��m�F�T~���:�"��!.HG�^n�W��l�����4�Jl�z�À)�<����%���؂尘+�<�"+���F�ެ)���H�����w�(d-�?x���M�:}t�FǦ�ï�[{w)����� �
6���g����΄����B�yd/�1�7��
 ���	8	�����-��e�V�cp�׈3��;Pkk�1w�mdw��]C���`a5:�?���$��{	�@���tr2�����>|�;���Fp6�$��l�a�,�J��M˞���r�ݝՖ��s����%3�iҌ��qAm���
����a.�^���uA}���̹5�Q1[�5��튛6��i�=�J� 	�(넴��/`��DH$˥�SC�{�� �8}Ƒ�Ƣ���7�!�����4a#<S�B�Ւ���rJ����������I�רu����
˦:�<J�A��WTu�GQ��=S����ڼ}����r��oH��̅6��Ш������/2S�Id1�dF�Z[�߰�F(�z��c�jX��1��)�D�D¼�b��o�|f�Y�^y;m�7gM�VQfjv)���[0��6�9nk�OkwD@Z�dXR����΢�BB<]�6h�!*�4�/.�3I��y�ď��ՒP@r�f3�Q�����a�4T1���I$�1թ:e����
)lM�X�� ��X�vn�df�����P�YI)���=�&.�'�+z?c@�١w��|�D6�rt��Lu�������0ӎ�&F���J8��*��0�(�)k�/W��O��@VŪn9��	��Թn�9���T@���"�|���;AY���J?!�6��z�.tq2��M)$�'��*�P��+[D�=C���r���&�/69p����wl['�jyV�ת���R�09��ʤ�z:__�!� @C�T8G%��#G�ޙN�#@�B�S�Q����8RƁ|6_�;��V ��r��]���{Qa�/?�&�st�S��
i ��1H�%bT
DZ�z�r=]��"��<����D��R�
R��#Ih��lR����Չ��Rw���k��^�:F��p�2༉qTn-���e?੆�c������GߋԹ��m�d3r��3JD�7� �Ʊ_��}�d�X/^��w�<tF�@h��Ae�Uw(M��&J$]U�ì�T���O�7E�*���:�LW�iT���LD��r9%n�<�/�Po?������D�s��V+>W���1�h����X�9z-0 V����Y'�t�[��9c��y�G�k�s0�rOy|�ąJ|�_ ïcv_�Y������80��%f0;-;�{���U�R��W���>���%.��3;�vs�V�Wp�߉},V;���F��7��YD�7:7F#5�9��3�6K����1�:�@�a�M�M�Һb��uz�7�9��6#��4����d*r�����nЛ�Y��P�D���2�h�̆�{"��j�{�wfr#�^U�J:�,6��[��<:�/[�ew��a-��(���;��j��B1 �B�~b~��X��b�էzi�D�t��{�tl"P�n���Q=+�e�����b��ԕwd�'���$���Y�<-������T�k���Ee1���ڨ�4��\e�m���վ`L%Ks.�3(�\u��(���ʇ�L��gg��B�X����g���86�.��,F=�d����X��mSψ�!kč�=HC�8����m��X~���ĴV�3��C,�>Ii�l�_b���>ϵk)ew�:��&g^�+7�y���h�0�k6����:�c�^4��m�ɭep��a�WP�4/hTL�YHt��1^Ig[���" �z�8��֜*J�6�vZ��gsuC��@(�
c\�gka@�3{<bxBv���^O������3�S!��iopV8|������?�yb�L5��\�ph�u���$.M�h;TR�t��[1�D�	����4m��"A`A!�j7�j�!u���rpX� N��+�|]14NH����ʧE�H�$�
��A*,N��Xv|�	D���Ŕ�l�x��c���V��fA�FA妎����S�=��hLVpܛ�V�w�fJ!��J�y�g�k��1v#�j�?�5�~#�G��G�{fďs���Zj��K5���|����$�v�gAE�R�eq�P�bǴ��g�6w�pm3�C�b
޺��n4������XK��b��7+:j����8GY���,l��ᤖ��6l�X�����/�'0�� � %������Zٚ&�vB��uu򃸽 �m	�@iN��"��j���d��:[�DM1��%:m�Y�H����Ľ����Lnۺ/KJDw.y�wY;���_�H�Ed~pY���>�mD��dN�\1ޠ�1��c1�(��r;�t8�E�N��9"�&� S!�(c�C* ؅�ʐܦgj�Q�'��E��k��E�U,D�V����%z�����-�:?�]7�]��C�0��CR^oR���k�,����*�`�=���-Pۚ;��ݍ��M���U �ƿ�2V���ܓ%��:ʊ��`�]�1,��<��~��uYŉ�%����p��-�޳������I���&p"�T���0^y��<ua3�`�+�����Cy4ɖ|�D�i<�bJ��TQ�٬
?����4��[;Q�ռ�M���G$U��`�H���9@ %���
3�W���/!ER)��b�V��9p� �&����s<#\��zSy�	��-��S�� ����_��!��&>�`R�q�/Z?c9ɖ��e���Z�㹑4����ǅL���)�֤�pM���$!ਟ���ZM1����N���0�z8�Ҽ�/q9�	�:BaJb�W8M�H_(l��m��]c������<��n��dGu�ѹ��1��8�1��"�QTCEM7]�џ�H[�N�͉e���l��=�c���𒟳�*W�r�jT�]R �C�R�՘��ԟdi;��K]�p9�}�`a+����Px}�Dy�p���4��c0�8���aL/H����=P"u[>�-F�;.P�]\w���gL��Y&��g�ֶ�ۊWW��hM�@�s��!n�l��>���$��0�>-��U���z1��/cL�U0�ߗi����)=��Ӏ�̤u�⌝��('���Ơ�zjd{%妺'/��������^��A�q��)���m��}b��%�����^|D�O�[W�1p ��U�����I�Ǵ����*|n�[!;�T���35q""B���jNԪ�K�/eq��q:�+x������ ��5X�XC�wG���Oǎ[5oEhEK�i�m��>Q�(���y��Waz��,q7����խ)���60V�����;#d<�I���:k��y�h�T�}K��A�h-��v���GY}o�;xy]}Z�(:k'נIŝ�14!�e���{�n:X_���=�~!=>�8<���U�c�?��o[b��TQ�+,�ɻ	����F�s�e�Lc�UB&��(�ѡ�\�y��w�2>za#���X��ؑݖ.kk5�c�`���֛A�G�J
��gِ�p����j��39
��]����~��NT��8 ���Z�� ,a��'��f2��������=.�m�]�m�i��s4u��!?l��'���xW���nfV�����A�Z�s�֪�����CSٻc��A�ק�@)<�=��?r��R%ڭ��ޱ�9�òD4��a�D�+T��v�_I��V��ɽ�N��_�h�ڃ	���_�bp#�<|["d��gNH/��,�G��$/&q��͈gq�^�^�s�N��Nh��hq�M�D�щ��Ю"h�J�I��\6�Q��b�@��ؙ�>1�'�M~h�4&�(���8a8t�w���=0���N��Cs�ݽB8��Z��]�A>���=Ł�lbC�:�9���(BE>r(�!q�2F�	�̾¬�X��k$f�����j�IUa�8���SF���+i16E�n�|wA��.��[v�wV���m�P��z����P�6��7����,y�P5��MB��I5��,���Nޕ���ū��s<v9� �����l�b��y�w/
�1��n<�@������<]�֘qB�{.Z�Z�;�t3O?^-�%�u���Z��2o��LW�J�{r��p���\1�	?�?<$��ɖ�h=�q.�;�#�� �رWq"#�xZ�-b�l���֦f��c9�+X@��T����_ý� �z�n��W���Zhnᑃ��M�+-��f��M������Ұy�У�n��i.aXF��ڧ����h�z�5Ts��.�!�U�3Hk҉�y$�͏��>:c�CG���9���v��0�����)��?��VS�@ʲ���.�Gōo5p3<�B�J��'��9�)��^1��"�����+EB�,x�6Sm�W#ݫ���,\��8�Z��SҪ�T����YU*_w4*�(��R���0i�@�)��0�F�%qrh>��|,f� �� o\�+�����+5
<R��c�I"�>u;�4��tby��1`df�)+�������]k�� I������I�@��?w!Q���Р@���Y�z{��!�M=���"��1P6��}���1�e��#���T�>͊�u����E?����"�2it���a��J����1��wA���E���\ЪY�}�tF_����h=s���A/�@��]z
$Dj���u��;s��Fiz^����"�%'���o�ڱ���,"v�+���{;��,���Lĕ�-|_�u�Mj��1U{���~T@�4�[��*@OxAU�4���H7�hh�a6������~\>�Я����S�� �!&;&;*����[�fE�f��[��~��|jo�N�B���Nl�����/�X�݇��iu�D��$���l�H��8N��V�]ﱸ�E9�|u��fS�N�O�af���e���vT�P��$@�"j>���@�h�!��:oif:39ׅX�)�3f���Qu�!<�����E؈`�U�vc۪��1/5/Wd�ek7ģ��Q���e�}w��|o�����DV�eT�I�`#r����JX̟ ��$?R�a!��"��i�Y���u��Xܮ�I^m�FXf$���{�bp���Y���ܮ��?�Z��l�{����F�rJ�:��i�:D����/����6x��G�c}���j�P�F���~5#9��ٚs����M��z�j�QR%)^%���)�� ��H���c8*�e�#�1�\w���k~�L�GV"��   ���0�T ��������g�    YZ