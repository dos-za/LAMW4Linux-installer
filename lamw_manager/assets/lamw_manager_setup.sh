#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="50767096"
MD5="e1f77276178a6bb107a415cf570b4a83"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26152"
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
	echo Date of packaging: Thu Feb 10 18:00:10 -03 2022
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
�7zXZ  �ִF !   �X���e�] �}��1Dd]����P�t�D��f*�o�C�U���	UXL�:Za_�}=�[�! E�}[��P��G�ɁCB7��%�v��V�sHuT�#ܥ\�ZQƊ��\�)�E.�x8��Z^�}3`n���	b� A��mRK�+"�2����D+�;)gan����`I[�k�ah7+���)���d���8tk R
��k4�����KO���
آ[�5���X8d���e�`��j���YxP���Ԁ]��G�*B@rc��/�k6"U���lE��P��#E�
d.����6��lEII��tU��c�p�<�A�"q$�[rs��L�FS��@/�=mM��h�s�����;���l����W|6 I�j�����M$�|~1F�CR	A���~y�{Q���L2�4�
�E��cvW闭��~�X @S]�q�����gѩ�� `�~u����Bb;��oU*-�.8=v��UW���$ov��6lor+�oӆ;ª7����=�>���n����H�\�<�块4�J{{��$B�-�_�@�p;���l���Ij��&�b�y{l��vVǉ-B���4C�3�zn���
��c�9ώ�Z�a�<;s����l�HCdI�����fyF����s���l��8�L��>�]?�������������N���o?��k�}�'�,��5����g�'=��I������~⏃ݥ�w�I�ƈ�7��c����W� �d>ޡ;O�d�����	$��A�{�<��7��� P�S�[��i��$V�$yD�?��9��HQrW����K�;7t9ڧ�� ��Z}��"[�S��M}�{���!f���,� "����_g����9 ��ݵ�N�Y��goJ��Q�u�",�&p|8��wmݻ�F��/t��&i-�D�hD�f��J<K>�*9O��L�V|ʚ/Rx�?Qy*3�7+K��]�$�Wm�&H�ZR%o"<�C?��|�5-� �����z� �a����L�*U��ߛT�����b_S>x�Mn�О`��È������*�@�vUI�"�x�'�������z]�H�g9	���2�Kc/-���I �ڡ�����h�(���n�<�)�7d	��l}�ɾ~�
�;k�}�:3W�1eD!��!&}����l^>�K��A���`MKkm���Nd36l�n�ƻ9� ���͠*W��>>Ɩ;�Dox����DU��ףq�d[8�1xo��H����A��$�J�^�������L��.k;C�rA�İ@H�}�X	e���rY�]Xx�I�Њ􁜤��H�{����N�����Z�� R\��%-�"]��\�"Q櫺�;��nǍl���nV�iC�[�Z���UB����j�e�^
ӥI"���j�=���`�]�̌҇�?�X�k� h~v(~�!�B���E�nى�	����e��=�~Ʉ�>>q������H���?5k�|C��֔ag9�������� V��(Xyx�.B0Ɩ;�\�xxO��/���7�����>ҋ��}#�fA�`F�b��l���nC�_B%�2���V;ו	��m�-)���H!zc��o�}3	Dl�?����l�O)����Nm��f��J HԐ���g�傃s�W��,��D�B�*[�F��Ds���p�&N(�v����(Rr53��������F�3��t�Ӣ �� Gh��̵״6���r�Ư ��������M�ύl���b�G�y�g�0�-��R��kB�o̻���áDg/F�L�����07��q��M�,z`��6Pډ3���@�2)91=����@|������m����;�ς�-�:K>b���z<�mG�f!⨽�^n��ƒkM��X,;�	{�>x���O��H�X�\ؕ��2�e��c4<���`�	tQ�B�'�w� ��ls�ʪ�5��IX̀q����ҵI��9L�a,�e�4�����) N�_k1"�J�~M\S}\�!�0?ϲU1����v���Shuٖp�u>zK�����x&��MJ"O���?����_%XR��6I�E-�G
J��@q�T�)�����Tg-_n)qj4�p#��<H���~2S��U���7D.<�b��C�ޮ
H���LvtO��/,0�8��@P��,w?���g7�$��;�|f!P6ua�k	D�-w>���xĩss�6b�g�k�����°>� �+J���P{Q?�9[X�'ܲ�mD�U��q��l��� E�B�ј҄�����G��o(���$�η����MebRk�N��/���{Բ{ z9��,������0M%�F��W1㔮��b�Ў0f4T���`|�iBշ��% q�h#��,~!]��5P���עy�>"}�P�//-�zX~a"ߞr�L���^�W��J��6X:S\�!�� �r���0m����S�l�l����#�]erA+�fSU��v��_jT_x�4Df���!�c�| 9�E�3��N�O�ߧpiAH��J,��S�Nсڥ+0����P�7$o��Cm�1ؚǔ�ITM�1���1��;�?��]	�Ïg��B�G����ޥ������D2g?	�/�kE-���n{R���T��e�����M�T#(+�!��B=���γK28�sP��Gܧ9�V['���cLR��y
��֩k��'H�mV05Z�Ԍ�跾��q�H��tu�E�o���@�E?^����]�� ��'�+)oΘmn�%�~�lߗ��ZE�&�56��Dh#��"'��)����F����*&��(�5�.p�̛-܎ ���]`c[�z�5	����DB�ˬc���q�����J�_��/���`� ����;	-q�>����y�9<���*�1�a���SOr��G�)y���cXX`�J邨4�{19w�-;�C^��0Lt�㫀�(��H_Vb�|�����78F{$�(J��Z�(��h8i��Jl�C��G�T�k+xK��9�)���Ǉx�Ԉ���m:�~�ϢT��(f�*ZV���bGm�$&4���*���)YE�:Q�s��+��[!�&�����T��Cgΐ��M;�ep���O�1UҔ9�~Rn6�
_�o��唄I���Xݓ �<K�6��^��x�OcJ��߯� ��l_a�����6�C��o�^��ׁ{/#���������T�F���ĭp���UO�����Z�v
!��bơlX�/C��R#�M��7� k0��قZ�
�~<�{d|��he;mf�,���*4ݿ��k�z�쨐�3���jb�o�����H�af9C��z'��k�E�ݟ�@S�^�,`�����!��Փ�|�RI��5eqش�O�c����o�8֕�E��{�Û�����_����3A�0Y����(]��	������$RB8G�cI�4�BƟ
��[Ҕ�_wL3�'R����ݗ큒jYs������.	�/�z�Hv;�����ɤ��/�P���x���$�E?�݇
y��3��uP�"��𔴓2|w#�p@�&6>���e(�p��
A���Lf��g퇇�X�P=��"JQ�:�r�+�iL3Y�v��)�!��|��pqZ�9�ܝ�)9�U��s���e��&Z�0}���[c����B�U����s?��V���Ǚ:��W�i`�����]%�($�����+��J��<����ȑ�ty���g�q`a��7"-v(�;tS����W���'���j��m��,nx`�C!�`$c���U�`3`#�Ag�����cxN���m����<te��-�9pi@� ܖ�7�e)�^��k�qQ�� .`�X[1��Z޾Cړj���7Y^���m�^k"����W�;ڗv��ٵ������Z/�4��U��+�Ɩū0	��<1!9 �HM�0k%��E��ef%�!>���m�Y�fdB< 	��5v��6N�𱻲�.���i�0�GPxz��"�s؄h9��}sQ���A��_&)� �����X�D��`T.���0�����ۦ]�j�7���1���8��_�[+���E�Ӣq8an�5�cq<9��������-���Ŵ��r��ʑ�-Q0�C��ʿ��ӹ0��豉��X�T�Q���n1Ka��
=�VS{T��e� 5�?9����\�	��"'�>�4��7^�uF�����3�3�ݞ�⨝�E4KL����}�[���О0%T[��v��N��X�>��ՐY:��Cbj��`���'np$sH�ѷ�_0^�G�8������;���	�xr@Nz���Lϓ���a��n V����C��А�p��=ʘ��:�B,CR��k�?�K(���w5��ʹ��x�6�LR�D�Pq�*���=rq�ǀ����m�t� T.��#}��#�c;yR9�2���fDm�V#��ټ}f�XTR��|�J���M)��"�曄�^S\^(�F��F�m �Ҭ�'�A���/�����j��|,�>�>��7�ָ�AkΒ������^HY����*�a9!M�J���֍,J-(à��Y�,�Gy�0��R_(�O��3-�ѐ��c�!����1����i����w)!���+�6i���`�7�s�Z(	]���1 �r��`eo3���AL^�T�iD��	�氦|6�dɧ�$������,�R��n*�t��1c�5r*T����j�x^�xn�%��g$�����5�%i�����{?�Է���rP���|aQDُ~�}�-z��q�
�}�-}�O�w�|2�VN������ٓ�ަ֫���Ѓ�gK��t<?8Ǎ�ؠ�X�2&�(�Ҝ;��X��iɅ���*e�I��r&5����+�]�u�t�mL;l}�X�u���H�S����n�"/k3�*mĦ��=��/�����Û=��C;�,�J3(��Jc��٤��;ɛf䦝������׏E�T9��`f�v-4m�O����{����J��(�1!n"Z�:�a�NҢ�>|��Q���n�� ��ԱH�KHN�P�&d|�BΝz<��"Q:�}�C&.a�	_����~ %� ��~�+����6�NF��v�%x`m�������T�%��jw�[\�}�,q^I� ΄$�lϹ�mZ'�}�QX��ܽ~':hM2��G���ΘkvA])x�T���)naL�����n7��|����ǐ�':TA��t�A�]�9�6x�Є�,[�QqИd��p�ڠhp������g�D���qE7h ��x�J�]����m=�;s��vY�lh���B~�$n���<��?.�һ��#A�Tէ����zy��M�Q&C�M2�����(N.�����_뮧b�$Y��P�?0s��/i���ئ���n�d�`6�����6�u����0%զ,���9�CJ�Xw|4_Q���j�Ai�b�|-�RS���e�a]�Kf9.ܡc+J.j�s#�ɏ��G��/��>����'���	d$���\��^��UZ�Z&˗��W�N�4��a�{?)�	�%��j��5j\Q<n��@ٮ��	�4���14g�t���W��{="`�e�4����a��o�V��
���Ȧ�#�'���fײ��;]�
.�}![���Kmΐ�u��/u*$�d썾��Ȣ�}��G�
�ū��(Y6�_b'���gxk�.��'^#6�X+��r�i�"�smfZ��x{{��H�HK.8���'&p���+��Q�fD�U4��KD�B׀<&�8xJ��{&NQ�~��d2+M1���jk�-��Gʄ�(�v>�R"���j[��an�@%�
X��Zq_($�F�,n ;��$o��:����&�>���U޳�t��ߞ�\},kNB��-`Pm{���B�*��a$"�ʳ��Նb�T�8� �f/�����jk�H?�(�m7����s�Jn���iY\l���� ���CͺƂ�ԣ߽֔��N���9����;�Ss�;�1�ǭ[�A��o����l�P�%řW��ǟo�Zk޷�^ ��?�V�8'��%�� &0�@�NqD���]i,'$ą��u�ر�����{|/��nf�g�����፰!1�^�^lgT�僉2�9Y<l���)����9�_K��
H.�
fB�ӻV����D�.8KE��j@�� ��&�+<<,t�<��Ծ΀��hd8�#�"7R���)�7����}/��?B�z�|�<�-PO�%X��P\UxmS�W{�J�sKa#*3,UOmG ͪ�9���燸>����*���K�/�GmcZ5
���̧|�����
?��\	���g-��c����X(�o�lizS#��#���~ߜ|�r��j�#�D%���fțw^��K7o+Β�՘��ۦ?���\4P��2N��� �~О�B������U�EzhfC@���M�C�Ț/�r+	Ӵ�V�]L�Z5b\r���<ӫ8ЛV�\�Bt)j7f�<�5�,ZJA�Q	���=J���/D��ѡ3Q}6�p�G�Ŭj������`j�d������P��qb/�X:�:�=`�'���3�x�2ɿZ�������U�:�
��t�ox��ֳ�΄���4{6,�Ƴ*�ȈjڏNU~fd�~Ռ�Nr޸^��ٕ�<��O��Pͺ����.�D����ˡ�R�2�u�Wσz����o+���{�<OB���:�%$�ڨb�P��0#K"�]�'���t�)�?��Or/c��-V�A�W�JRj� ����~��R�#��q�?A��5~O��<���Q�Ј$q�\|�w{2��B�.�9�.Z�!��{}��|ĩ\�,�����}�-��?XD�qC��������jm�g������ ��� Y�xVB�6Ý��
����h��)�
�
f:��]_ݽ��l��?��;��/�� �����_��F�L+r66 �������`ϝ���ofk��Jm�.?�cnc��$��ο�֫���0!y���`'��W�)�������/��P��Q��VP��;���]�i�\f��p�m;aOT�^t��֓O��V�j� �~(ܧԑw�M�7��ˋ"��@�EX��A��R�V�!����	�%�s6��<�.��Or�"8Y�:y�m���X �t�4/Q�X���|���&���WC�* �h�VĦ(�sn����y���*�X��Y���-d�!}������ҦI�"���T����g��`�D�v��_�OK�\/�S2|���f�~|V%[��c��_�{zu���X3�%��V>�A�fF�
�u�	G�X;@�v5
��G���v���&ʈ��h|�c��:t= ��oZ=�䒹��I瞂k�c�iKf>?��D��I���E���,��,l��v1����w��,�#M�����suT�wX�X��/`?�?�!n�~{��jvGu�w���̕�/d
s)nb��"�F�JMu��C���#�9�M�����0x�;wfW/��}�j #�B}��w�"���r�T�_�`����3�����lk)0{�M�N�X�S@ٳ���=�N��r>G��w�M�4�c!n��,ܬn���K�8���UJ��b�n��ǁ��x;H��B��/*!K�v͏�>E>��7��v���A���:%����g� 8�VX��e�X���ϻ�HǢߒ����^��� �"B�B�:�����(�H9����2�m��G+�KT��\iীR���
�5��m}�/*/�S��\�\X��PN�ғ��j��Z�h��@�M��P����F�:�T[��m|�>��]�A�y�DWn��t {��R6���M2*�I*��a#�BȂw�%��6!��ir�"x]���J Ҥ�a���ъ����ȵYc��d�k�`��-���+�n�x�͑�kC(�(\e}J�J٭>%��.u��?�c�e�T'};�	C����Ι�j^�%\*�u�[�~�$�&�^�s'�1����[����@6t,����`8"���?������.�D�����܂TL���#�z�)->M�(�k������;�	����l-R��=O>��'T����^8��|�.dG`�G���y;8�H�*Ɓz����B����5���c�f�-�H���ß�p�,@��-��D��G9N�t�p$��EI�R��Q�儮������5c��&_�~���p�2���8���E�~��@k�����D	+�C��4�g9?&�?��]�Sg�(ob�� :��bғ����e9���Pv����?���]�(�E�?އ��$�R��VlS�`��� Q1��z�o,�Ăe�l�)�Bq��/$M\��G�9�$�h��=Q^8��b���W�ڸ�'.�M5�){(�2��"ǲ	���U�P#~,
_J@3��r���nL�����z�H H�h�G�E�Ev�M�G�2���A��>�HZz����o!`Vc���^�NY�Fa/��d�Ï�͛��XT�j�����Q��[�(������!�
G,�*Z�>X�Y;��j�hw�</�C��G���Z�ߖ���uV�iv!j��!q+)8�
D1-JÔ�
�;�lm���W{��,��8�7P0�Z#�O!a��Hj�f���r����co�I�9:۲���(�+�z͒0�ޗT�5�K�k�����xe��aU��&[SC���60�}�hϙ��a��+��u\����RuX	E���ȭ�^$��R��� ٛ7�E�ZIO3��2d=�ӣ>K��ը�-�5��*���?r���rDѐ��.r��E���NEU�@F/P��R;���#�8�Ytt'kn�[�1J�m��T�QD㤯�ڛ�A��x� �D�.e�Jlo۠���g-d��q>�=qka����p���TF|]���@��:~i��4i�xG�-¸�ãL�	]�8�b��qE�L|v�2���#wꠔ�x���XsZ"��h��u�L�ɹ�|\�	࣠$*�j�Ho'4����srN�cy2�(�+�a��[V=/�������'����GR�jJ��Nh8׃�&�%�ױ�fAҫ����N,��Rpf�yN6R(��
X�U��:h�q��p����9�'��/���t������G�i�@�,s��/���{�~���=G
�w�X���(L�G�ke<���)��y�>��.B��E%�pZ�d�{�E�C4� T��_G���+�z�#�w|��Sg�o��P�.���43?�>Ax�����]v��'\�
��o��m�8鮑lS����g+;y�R2���L�p�P���b� ���
Vo�ap��"�(����`3Tc�x[lJs{��\��.g��'TB�z����}��/\-yN���{��g��>�g&�݄�uE���Z�g�`}ɻ��B�l���aF��֪��?_m�.�8�s|�,9amg��0��w��e�GQ4a�~�TW
�k�	RpukH�
�Yqe?�50�4�
{_1���0sF��$~Ɠr _�}����_�����	����R�p�zS���I�?�Z,Z6t�ё:�?"i/��Bn;-�xI���&�[�b��0W�vK�Ԩ�AF6���y�*l<f��]���B-&5!J��<�
������v����a]Qa�C{�C
9Ｈǵ���m�gd��/3��G~ң7�ʀ����5"Eɖ5�r�w}&��Dy�|a��y�:VЩC%%Q7���t%��pqS���?m��B�(�g�w� �B`i]��S�g�br��,z1|�-�s���*�5����O����<�s$<�,�o�޹�E���*�:5��¾���sX���T�ҳa'`˪�R��J81���J�8��e�qI�.��:&K&��|iM϶n"J��ŋ�n�\B<�l��%%�a@��f)I3K��8�R!���]ױ�nwqH�I�O޾
��k&d4[	Vg�[!o|�F�������^��R���į����QH$�6�=U�Yk�q ������-diG��*�[z�蔖!L�%.> ���=�D���=_�f����nhM�D(�n}�:�Ta��Hf�'!%*��|W'd��lW�49s��p�{���|6�?��Q�w}��
~���� M��)#�Þ�E�%yv�g@KO�v��nF9�Sy�A�\�C�GrO�4�m��ը��]V�2E�����&)Đ����b����n�-
�`2�����Րl����M*�)lA��8�0��,��Qyq�@-�ۥ�v�0IgHc�y�s�X=��y�7��${8X��҉BH��!:f^b8|8�CƄ샙̀�X�wM�+ ��l���`3G��G�_��������%*�ҼE(�z��aPL��&";1c�u�W�'1>�w�boP�]�)���to��+�j8S���/�㸓t�%���lI1BYN�����ei�g(�_n�xٜ��P�h��Ξ���M��T%)�<�6Ƥ�L!hb(�ѻqd7[�6��x݆�iz��Ol�ȹ������s�(S���ɵw����l
���e��7�VyYdމM�L�4�O�lY�����F0�\��O|n`Qe�����ܯ��7���[:���� �q�=��}��Wk��_}�h�����M��+R��^�4w�o���~��d�?�J?�z�^��
h� �ބZ��">��>|A�&�	lek�q~�h�נ'~�8J�Q��Y+�M�X��5�����
�(�E�y���&ߧ	�<��]����Syn����!L&w������Ͼ�e�w�%��)}�7^8k�zb�v��Ό^�$����G����i-�îEu�=$�(@��q��X��G
w9�8�(q��]DU���RYw�'-R�`��g�t�:��}��qjr�� [",���%������`�F�!���8��mLl�'-�5���9')��@�4��+Iiw"�|�EņR����X��B	�X0A�6�^����L�YQ��H��
�f���� �}h�E�G�y{D:2�pq�=�o4N��ǹ�qE����/BR�꟏(��N _p�  O����?��	�:j�����n�{�>�%2�E�Z=�2[+�s9[1h>��ߖ�8]��)��Ϫ��	rf��{�U�R���=h-�x_3d;Օ��2��J=���]?`n�zAX���'�?�����_4������!�_D�R� ���|�g���~�"��b�`+�[�n���fN�^��o�L%��&;�(�� Ld�:,���q�j:���U]��VR[yN-�3��������k���3ZE��}�6�a8�m�ݜ��除�2�횘�͎��˳�!�&��?RD����`��jȋ�
���C-?m�=�T���U#���Q���ch�`v.&m�3���i�0�V�vw��o^�a��;X����Ï_=<�ZI���9��0;Υ�#�;M��|�m5�_�N��pTk�=<[�r�5<�H�����q��e 2];�Ԉ�)�S����M�� �� �;�)J�HF}�˿�9U��YX�Q���牺~�MO�&/��YA���% �'/>.l$�u[H��sK���]��dnd`�t��H����;Lu��7)��KC�����Z�9x�~�.�M��7U��;��%RR,�&z���'���~��ń���"_�����D��3��"#RN=���V�M����/��P>E�����C��뚑��r�SBG��*[.�}_��ϜǙ�F�Y���C�|�C�x�)�g�7�����
k��rk~����8�՞Z�d�/�N�{���'�_%3��y����kL+!���C��y�����I2R�}�\=/����
{�����1c-�P�q:��;JW�`�`��}�Nqx����y��t���t�@��,���tvi*�N�"���X�����WpRO��R�h���a�����u�V�y�/%1d�h"�E I��ŏc[.bK�i�~������L����*�v�{�23>ɬ��:�{��[e\��:;�r�rz�\9f6@�|��F�IHGPP2C�����	�iϞC,�<����ig����!r�3�եG�\��f�C4��uP��[O�����UU�����FP�)@&�9�B�����CMA�:Uƃ�ff+��A�C0�\z��:<v3�œ��E"bܦ��JQCD�J�U��$�f�.=�+?����]� ��XCE$�@'R�,ޅ�w��\�$�3v�*��+��|�~�>M���-A{l�0���G�OȢ�ߩ`��^��-��P&!g�Cf'�q^[JJ�Հ\��\fP6x�m�-�H��v��|QGX\qᮞ���26�M�[V*�D�8��9},�>�Tt�������ц�Q�bm8a�~-x���j�`]u~���3��r8�3C	�R��E_�>�`�+�]٫3r�Hb�#�:�b��,	)GC`H|�!��{�1N�\QV�Z��ΐ��#��;k�EՃ
h"��O_ܓ,.P�O���*�5f��H��{��C���n�/�盁�kCj�<S/�SQ�H,�M�m�9��d�m�<{yph"Z�%�?�\=�-r�c�b�o�O!rc����c��Mx�Ý��ȭ.z���i� e����ju�f�</��i�~'3�if�K7�F���T��)*�w_�L��@(R�H�^���m���\��5� �a��p� y���(��<9�7���Cp�p60��G�s�d�"=K�'`}L�m/�u�+օ��ɨ��k"
��6�؆͘�R#� ��W���}Z\@���(�׻�.�1o^�ϑ�-##8b�Η]rP6����20��Nea�z���zK�K�^=��wtݘ0�>K�u�A|^m0G5��A��/�3?��en��u���J@4���T��پ��ރJ�b篻�wnaN�8X�.�q����q"c��\��L4˧]��{i6=�+AF=���=b��8�J"����AAɥq*G�<��B��^@x���i��~�GA��u �Kְ�n�d⋙׃�������8M ���#+y�;�E�~�"�P��h2��4���ط@� Ma�,�������8LR]�]��s��eKۺ���o&^�@N	Y�V�L|��KyΞ7�P�B$t<���e%�b ��3�t�C��Z��_i][ҹ.�0I�,x^�O�(��l)���I��үv=�\L���s�%j��*�mΥ��|�V ��j�sh��T��]�W��q��b�N��$���҇s��̓1yC͡�l;0)��0t������c_����^zԇ�� r�T��D��7�*U̝,��`�T4f���+��%쩻����㦃��Li��e6ʾ��1Y��x�'�'��#�$5qx�+���"ü������% �B�8��O��Ro.��U/7J1���0x��8J�ݙ�"��.��l��g�ZT�J�N�D�GScE�4\��3��1�_����
=����Ո�c˒Eʄ3R��a%&��:���!����=#p.QT�UŚ!WG���`w�Y��1T��)�&��Fd���U� ��7�V9.c��M�H(�t(m��8bƑ���yvy���3��k�4I{ؙ	��|�0#���$��<lȪ�'T+�� ��![���l�՜!`�ȫ�y|fTP��P�3��)c����3��[��
���ٙ����1��ƞa��.���(��/ȔD�D �� �Υ��S�U!{aj��{@~��A>�x�)�`8;%|�Ⱥ4T��j�3L�!��"Rz�f?:6��;�rgjȘ�Z��fʸ��M�.�EW��J~�x'�3��[�*%��E;��~!��r�R���Xm��3�I��y���k"�5ύ@M�[��Ge�VP�����D�Ѧ�9����rg/j?#R�)YBQ��lm増

l�IS�R�u�T �p���J��1f�&$46+��5�� ��_�7�K�u:�IO�� ��j8�f��-T@�M�)�D%�����H��Ÿ�ʼ)�P��3�"èq������T�ga�?=HK�}�'��f�9&{Z�N�b������ٟ��#<�� �|��g>p�MT�t�?˰�z��v!R G���6,�6���"��ʬ��J��r.��AS)](�i�����-��SY�q�Y������!*s0Pm)��+T�J�z<a0�樶�����!�X|*H���3���?3���4{��s%F"b���U;�h!��6c���Èߪ��r|�߰ӷ?	�_�v�W�|6���<��OU(k�T�Xp�'W7j?��*\��H̐�A�x�D��dk-N�U�N̽[˹��fh;���{O�`� Y�!�PnG��5�f3ȑ1r���9�-�@$����,�QV�H���!,hETzW�T62�+�-o΅IటZQ�D ���iP��W�^�u�tQ�a.j֖ ��M�N$���7o���C�~0����+�!�!����%rz}6���~\������̆��?��2(��0R�x�ڂ��H�'{kN�� �FC��6H�1��r۳+G-�-x��Q�ޱ:5x#�.ZbCHG�>��Z��{���XC���ļ?	m��T~���s\�����!	|�����"��CpA`����g����r�ҟ����6^�I||��^2/&���.}�����{(�ę<�y�T8r�$�c��^t���ˠ�fs庱�h��[ԫ{��{������ѳ�I���h�ć�LP���~��m3�Œ�"�C���zs�t�7�=�'[n"�����"�l7��ǭ�^t5w�VD3_S>�8Ŭ(���1S�s��&7���,������lŮ?g+@7A��Z��SH�M^�6��O?��~�̛e�(����C/�/"���D����G���sk	���؟�95!~���0�@�&C��<���+�m`@Z8���B��7k.��d���tޕ G�Nu��pNq��`u�ZR�$UR�g~�`&ԑ[�ue�z��;�Y����Lаc���K��R�?Y��Kx=k� m��4��`��bgIA�+H4���L�ѩ��Wf{} ��^Ѵ$�t�X���NH���]�)��q�E�o&�Ќk�Yd�Jɽ
sD����6'ɷ��p(���]�Ow�̮�S����(������3��L�OwiJ��}E	F���,  ��"H2�T�dŨc�3��dpʢN 3�QQ������<���ǃW������q��̉���]�PK!�~ SY}�Z�JqRoj�H��I��ݏ�C0�^��1���i&�cx����qwd��K����v���$m2a఍8\�ma��^�@_��c2�SD��/�����]����Ӻ�l�A0��{���M�+�9BT("���>NKW��\EKXo�J�HOs�G�o�?���ĸ/���̖�T�"X�']�R�yن&�m@��w�1���hq*΃]@b0���/��v�4�鑳�0f����[�D�6�{Ĩk�e����U����� N�n�����^��p$"���^���)Cs࿘P��u��g�q�!*��QL�	QX!��+N���y������0Ȑ�ڴة��>@=�%�;�(͂��;ւ��e��Tg�NG�@��(��9�Czuۉ�"�_ᾳ ���s� �!�� c����7C�ֆ?�x{r��Y���۱dF����Qb>��4�}i�/?䥱֌iH����9\�(����
�da�KR$�ű��Ag/�>p�e��w!'��a�32g19j��z��Sؕ�?!rJ��mWw<�l����8F��B���1v7e���(�$Z�G���oɵ3�62�J�xIG��<0� PZ7_G��/�<esSbӋc0b���.�u~���HgF�n�K��Α�B�f�L��c���3���ՇDܾ�BT�w�6v�p�smh���E��Exl�߶�r��!����#�f��\ǽ�����BV�U�C�Z��7 ��JR��w�䖧�pq�h�$.hn� ��I�H�~`�����a�U�ey:�����X�*f^1��~��)|���g^�:gI���0� �M�|�"ƒC�oU�X{��%�ߞ�FD���:���H�Hxy ��:�U�&�a�>q�����8��Z?��w�1�z";�<������BhN�ZM�]M�5!�0�K<�j��޵��[2c��Yd����n�[�]7yNF/ӹ���T8""S4./˹7�8lQh�4�Q+Cy!S]�� �Z�wJ	�M{���uc=�C?(��=�!�L�z����� �!-�!,#8���..�OP@}�g}Na�d��Dj\\��7Ӷ�#r�Nɛ	vd��J��w[�5{�8��SJ�]4aj���h`DRĆ�^�����\U(⦼f�f��r���@��<4��}k�xc�hTCK�Sm~Q�1k�:���_=�����y�}i����82Jfg"��c�O|�幟��n�@����W�cc�&	���K���+i�Bw2�4<0�ࠫ����\�p.Dk:��*�|NXӻ�Ot�Š�u�o�a��ƪނjAݡ t����sQѩ�fE�}]����!��^!�DȯZ���\Yꭜ5<�^�Tb֧p+�����ɩ��0e�u��t�!n���&K\X�#����T��V���d7uQ��c����#Í .��������nL݉�ێЁ0��+c��ƕ��C�f�!��f��yH��6�Ji.��*���X�؂%{B��PGx���n����f�k���#'������&��K Հ��N�-	�G$�do4I*|���Ȉ�&�nC����:s�8�E�wW�$b���r���O�jA���f�F�#P�k�`���~%���^���a����gL����������Ֆ�
i���%'U��@�]n{�pJ�V���\�4@fY�g���{�^��G���K����42�gV��in5���c$��ݔ2���<�v�NwD(A����V�}qv�f���M�aD#ɻ��qA@}��,�>Y�CCL!�*�n@��e-k|�����$�[5�U��1�z�Fv�k��Bt��`5j��r�a���W����z���z�!I�;L�����^�@޼S�73��"�3m	��	a�M 3�*��E��Z-\��>>�/-����d�%��sЈ�@ż��s=�aI�T��׏p��H+Y"�|��<��@�O���n���f����h�A��Ҁ��HSoR��X�2�U�6�+�����Ч�������m�J݂ã���U��¸����i��	KT�jY�20k(ۦ{T���g���U#h�С��|��,%���ҷ����n$x�
�Z�ҳ��/r�OE!��,:'�1��@�Ũ��|̎�`��^�/�>�A�{��)%��gR݇�3(x���.�d�5c�.�bD��`�GrG �D���ࠈ�K�o;��?�g��#�Q�H�htn�NO2��|���I3�z�*�7��WK����
-��?�>y�x�#L>�2p,�A+jd}_]��z[*ƨPn嶨\1�I!!�_�2�D���~�H����7�k��'-H��o,��gh�.W!�[wܡQ� ��(�濥��E�l���.�Գ �*>VԚ�j*h3oЮ$�r�k��-C֔��K�#R���^*MEK�e�>oT�n�P*K.j����uC.Ƣ�X[Ky��;�kȻj��xT���т��&��-ִ�)~S����ʟp�z���|Z?�s�!O�Q�j�ZJ�Ʌ�9I�O�t&��8�4���M������:L�u��S�'�y,��e:�������������bKAI�;���_�8U��;�gk���d�OD�ث[�*	8�k|���d�3p�1=E���;�n�����k�_�֗����S�Y�0��i]�c����G�a�%��W��G�Uu'y���)@40d�o�5������c�ҪZ>�����L6R�X[U���qa3��.{�^�c�G4��` ��柒n�6��ii��irPf�K��]�B���f.����s!��4����>H]K�!�@>,���c|ꦺ���Y+��|�9���lsrX�~���{�[�s�v]������@mf���a���d5/%��?�3�@��n�#9k�0� �|2�y� �$o<E��e:u��޹T�8j��=��	d0�wX�Ey�߾�e+��n�ek��-��3� 9�u"8\i�q�(	a!��/�v:���R���pk'�N�G�����1�k/��QFKj&5=R�"��=�!�}Ä�|c�.W�CV��w��b�	SL���V!~ڧ���h�ޟ/(��zI�[�����M�F��y �rk���
�bf���1��0�#0	'̝���H �[6��Q!S����.%"�w���Js��=x�� ��� �������eb�D����xF?�U��Q��&��2_��uA&��[��}�
�g����E�¿)�\H����v�qu՞���챇8�8��L���'uDr�!�H0O�~y�o{Ǟ�%_m�Q�]�i�i$�6m��0�~�]�?�^��<���B6v���Dl����%��|9BH6-�Oۮ�G!��o�n�_�sڶf%�Lhn>���i
�S�Pn�|)�E�$�A<>E�#W�G:���l0��n��G�
Ov�YN�rI�Wx�.Y���T��B�D@ئ�[�9x���M�,?���1׵�&66L'�z������?�ש7;`��޵0�����9��������V\�JsP��v�4�*�XP�#H�á��a�����GuwqXI��7s�&Xs7�����G�Ҿ!\����P��)�I�qXᩧ�I�ݞd���L��^#������q�V���	��JS� �lO1ƹ	f���8��A�{ٮE|��/��'8uc�O�o)�F��bn(vx�V��2r�*.��lJ=m�^��߆�e)�9^�ϸ��O�&y�����Xem��������S�8�<�2�_,j�q@��?��`�z1���-ޭd	��>sa  "?�,Y� nj���<M`���{�K�K���X���}�r)Ԣ�Kj'�[N)�\�j`���x��rs�|��� 9�`@�z���-M>�h��|U�;�z��3˘�57����F:�,]�bL��@0iw�����;�]�9GӜ̫o��4i����� �%ѠZ� 峴�������%�S�b*���YQ���C�~���@�E :^�
����Vk��s�8��D�֓\����h���%���� ~��0��~a�����tW��Րn�m��H_��h$
z�,�[��R�*<i��"O����"���� �E��])�t��B�h��Q������/��4�W��2�n�KI/_����]�p"���_W��Yn����nv�r�����779]�6A�I��������B#a��K���c�o�9S)��j]l�2���	�Ece�H�ЊW�
���>Y�k��`M番e��"��*J���'Q�W�j��S> ��7��K\�7��m"S՟��V�Br��`�9���~	�i~���"q��?Z����֓�v���^��gB�/A���������]�%Vg�1�Z��UD$�a�}�;V����aG�٪Ek��P�%�z��M*��.��ސ�]f"��p�!a �-���#]�G�}���̲y����l@b�y���7�PL��~
�j����T��wJ��v�NA;D���s��v#>M��ꄗ���z�%�è�,F���M���l�=ƚ�8sw��x~����
��-4���X�s`;�u�O��\�vq��}TuuC��|}���&� �U��v�У���	��N8y~7�Š����^J�K�F���	+���$A|� DH�.=�qF:����@X�zu�w�c�g2�~᫳�I�t���cB��a&F�
�Q3O&��;Y;��u��	��Et�����˝t����Yl�V�o�����3=��Is%��C����_�����홼`7��^��{���;�/.�6>�K¥?���p�ye��G���:ڭ����A��R��.�ौg��4���/@��ǽK����7�+��Z_ %����@Rb�t=I��f�F2!�^6L�d�������ך܌.��C�,zi�b�v����]�� ������/2p��v���C�Q��U�Q*������(�h)F�x���#ǀ�w��)��V�~�S�o�k��j5^��Z��
(�/�5xݼ����u^9��T�0^�q��N<�*s�|���i���橷S�%_V���"5��g�`�^�
�A\�hb5��e)x*������|{ks�x`91AEwh3U1�_�X��P?�ĲIF�J�����SL�io��B-�V@K�iV�g�D�jy_�L��8�:���MP:�E����=P��^Sx5w=�f�\�9U��Qp���uq��t{�#!!x!�G˷�3!	Ռ?�&\��~C�{�e��3��Y��2ȭ��2s��%m	�)�E�!���K`9�n����>Jj[6Se}~d�YLP���8)(�И��77������L�b�`9%V������̅�5�}�`i&tZN�7������W?�{��n���	x5�ǉ��fX���@Û���W��q����\?!fT�*�!9-�e��B��V����S�d8���G��JW��LkZ� �a*L�>C����!����@\L(:c�C��Z�ġ�5âj�.���F��s1�ڿ� ���tk��bczx
|a2�>e%8~��~�S��o�f��J\	��$;Φ׉[����㱉����ڤ:|$@a��.�ܑl�����!ENB��"��8J!!���sX�䂤@����YV"1m�o��ڏO>�����)����k�&�󒵐�P>��iNR��"��G4��QY�@�<���s܊E��i������[�9DO�.X���L/l��}X�?��M��T�M(m��^R��%�T���+�zP@�-'��hyH����.>+�a��n��=M4�%�`.��N���g%2�}�dr�����j�!��b]�iN�|#��V�6���E0���_�q�LZR�υ�!��&<G�@�'(YQ��h#K�$`})H ��Uk��$ 6�>W)0 ��P�.�8�I�a�q\�	|bl��;��+X���}"yA���Sr��`w��� �;�P/��'�"0ǳW�	O ��4J0���̢�q)�:�#�J(v~MG���Dyݡ����f�,����2�y6<*��}����Ɨ��|��Ͳ�`���W�A�Cʮc�Ɍ9��Z �T@:�NBߕT���UNxz��e+���:���mrۍlpn�(7�(�'XQ�)��@"�v�$���m�8${��jv$"�p��ë���3h����]�"��[!�����ϐ��.�4�������JE$o�<��k>���̈́�΁,p�ia�x����7�<�����f1�ٌk�z\R_�ʼ�[:&E��T�0$��}~7������6�xx�sG+wo���H����<7=q|푸�V����_GY�'�|řH�A۩�>Բ�씟ݚw\�55&]_�3/�;�@jF��<�*��0�>���R���,�͠�T���=�u�о_�٬�Z�i|o��z��sbĸ�h�$��V���K�m-�1��C��Kz�2�C�cխ��wr��z�:�he}�b��f�MBݻ�&Т]%Ѳ[�f��v%�wd$�=�g��/}�
ƚ�YzB�HVɵ��ם��5"+��vx���k�'�W/)�����h�B;'<v�ܜ ح뉖���t�V RK�/K-u��EZL$�j��@t��i̺�`L��l� b��!�#UߢC��IJ�{F�q�l/�\�Øb���Xs��g��[�e;)��|t��tmxw��0_m���	���s�����[l��m�ԩ[�|�inq4T�4�Ӻ��1a�I^-�^��l�u������i��c�O}{TP;���)oǧ��>t礠u=�(2�=4E���c��	�R�R�eI��~�T�%�)�~��4;�_���<Ln<���.�����Hfo�*�>D���r�b^h�!MU�Q4}~�r���`}O��v�#s!��<��ňZ���r�F@S��FP�У�W��#z��W��^�g��mt�J�bE��
Ρ��|`��
1y$���'�azZْM�7W��0��Ɵe��W�@�%z�X�Ql�����w�!����k����*ެk ��Y7n�	1_� Z�1Ɠ�F�IR㖦��K�h�K�9OQ���r}�ӥ>�d0��O�Mh��v�y��Q�yq��)I�x��� i��=�1�p�ޱzW�)�*��D�L9S6Ϛ��6��
�B���^R���p�UU2!�a\�vr�1�a�~\��[V�|'fsVO����P��ݽ41���e��p���c�
¼J�_�Q��|��Q)�l,�k�wF�ݏѽ$Z6�S)�pؑ�ߙ23x�_�l�s���0�Dh�����2V6�\:V<�L��7I�������A+
�dQ*\O�&�dU7��8jM_rC�ҽ����a�w���3��<Og�YBĳ��a�m笘hZ	S<v�A�A]���P�l�h��5��m\�즕�O�Yfn�b�@����D[�~x����Bܟ1r�~k�~6�e�V\9?���&�6�K��v�R�v�d+`��~�vyP���@�����K�3
�c�2.��2�j/`�j�Utٰ�hh�
���T�g\�4M������d�k^M*G@��E�H�"L��{�X�F;�j��z<�ؿR�j��v�h�͋;�rLk�����P�������&�>� �N={K���������yu2�b�ID���#��(�>��q�����	,Ҧ'a�R�F�Y�eּ����V��q�i�5R͙6�pW��H�
VN�Lxu�l�I���AM�8���h�\�����V��"S;Ө�$U���k���4��K{ڼ���@&j+-�Ztq���X����͎�SL�Yӡ��!�T��җ�OesVE�O�8��}���mj����y��/�tv�g�W`q;.� n��{b�E�z49�\
H�c|��D>����@*}����f���)�L�������$3Y�k�9#�����{��b�� Yg�H�J%�@����I~��Ń�w#��q�T�hS~��zAs���U���s����dN	X4�q,�����������r-᤻��lwl'��!�}�c-�(�6����m	���W���j]lܮ�lJ��ͱ|�N{��T���X���w鴋o�><���m���õt��������؁p�IQ����Y���
�'�-76����rY!�J�~2O؍���;6��?�7n2c����������H�q�qR}x�[�W귷C�H0xlj]�[��M��>@��և�-������=[f}���T�/����zyo�W��Z.W���P�z�0�ѓ7�L;���@�^ ������b6! ���P����ڠ�ʽr'�,Z�1Y/�F?^��6yٖ������7X�J��4k�ɢE���J�HGK����O�5�Y����ƅQ Ԯ@����Vޚ?�=Ti�.JnྰO������Լ�39H����A)�� s��բ��L��y�fMS��򲄁t�#��?J�7Y�4د���fk�QXJh�7ŜJ�`D���pZ�����9w� �pW���cF�I|pN%;p���:V��mTy2�wfR��hJ�������9{�.%����%-��4I��|�qɖ�e�1/�P�����T ���4��}q�B�6"k�#���kP�<(�
L(I�9)�~ϼ=I20-g��v��)9  �����<�/�Pm��Q���	a=%XT����{�ct��t7~_B�&?e����;��P��)�^���Dg����J֢e�ÏdW���d����D�G2��0*�LUG���z42.9AE�f,yy!��K�X�����Ib�}��DBr�=T���8�cP(���J$k���[U�tn?O���@\��Hʯ�$�$��ƕ��*rp�lW�,��n�L#�B��ΪM�?F�i!�!����d��������\��`N������&�S������T��#/��΀igI�&�����D$7�IC��%i�t	bx�`G��i5ؓ��Ӌ2���b���Ҍ�;���G��]�Є	�~�߾�c�����CJ[�-����꾳#�Є�M���Q�}gΧ�����?kO}:��5?�g�9�d�\�o�(�U���;Q�v��^�����b�����Y���tR�p��\XU���ƾyv9e�.H�&�*�&SUڱ����8�������\#~�PS���ZQ� ³:Ŀݱ�*TE{��3��8��&H�#��+���w��Rʶ���~�YD���@�t��3�������5���R����Z���q�%�N�<@�_iL%�@��n���EKőR3\�L^�N���6����<�3D�N>\��J�u}{9*=��ǳ	�$��Am�~5�F���������qmR�`�����/�i����9.�[�@Stk�?�G6Q�]v�t��ܜ�Pi���&��ڷnr�����gm���;G���w��N�Zh��U&�(8:�#%A��<y�:���;Q4LYn�]:�6/
Z�G�⸘H�+��}�rX��mM�X���c�`6��a ���.�_�������J@��R��FG�@��
)�J&09�؀����!F��D��bX��=;�g�π7����m��T-ٱGr�U���y�#����3j�m��gV%4|��HJA<��uZ�T����v`�$�'�If鼎���
�fS�Y(_ݱ�'��3+A#��=?6�c��T:	Z8��N8G�m�\ۓ�f���2���q��cO3��}"��T��x"�:,Jb�[����Gz����e>q 5���R�J�,*/ϐ�_�4�rT�7p4:�c��e��=�3/4�r�XD���Q��f�M	Bݡ� ���~��*M� ����P�����43Aikg!g��e���LsMs�Jޠh_�Yq<>�����;�aTѣ�l��8n�#�M�hp�2+7O�GyI�M�S��Q���yb���c�H�K>��A$������_z,$�=����F���D��pd"Z_W�y��&�O	AD;�a����_����(�Ou1����׉[ׅ�������N��1��{}ɮ��]��Ou��F%�&}-��T�����;��V��	s�{�X*9��H�l�VV�Vj��k2}:��ݹ3�T��'�z��^|meVk� ]��2ֽ��\}��lG���;�i�c�`d]�/@��Q�V%ɵ!���R�6�4�X���tē�D�$�|��,���X�X��=���5@��_m?��>B>Mu�b����%����s��/�$�,}b��,��#7�\�7O�Y�\��kf�S�\+>/����<�j4D=������q���'���vu�RQ����7����7/�T�ڸ��)��<5��7	���+M?Z�"��Z�A�-�dguޑ-@[�*��~��MG{�"��{lo��|�&a�Z'�Z��`��%e^��n��wq�G��  Nk�.�$<F ������L��g�    YZ