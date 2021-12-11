#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="34802408"
MD5="7403a9923681c7fcb8e1ef7f531831af"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25476"
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
	echo Date of packaging: Sat Dec 11 10:33:05 -03 2021
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
�7zXZ  �ִF !   �X���cA] �}��1Dd]����P�t�D�"ڒ��Xi��'5#�R�.|a�N��SfW.�#{�g�&n�>0��w��[��MDŎ̜x��s��^N��U�%�� N� g�g�P�Q�r�W��}k34r�$�TDphc �𸸠_�h	�ņ���B5��?Ut���&�RV�Yl�An�rܖ�PR��cWy� �P�3��0�-�G�g���������c7;��`�ď�n�g���򓐸�-gb��=�s��<K�&	�QBG���0��*��Q��������|��d��v��L+cuHI��l����<�"bH&a�?Wt@K������+��Ȳ-���4K�%I투��h>�֓t�����+�����[�[6�-�RH1%X�w�#���Ώ�h�`�u�֚�y��-�L�U6��=��{l�{�ۋ�h���}��N��މӥ��Eh9z!`�Ԋ(?}9��X�5z�)����~+PP��:�??�G�T^�},��7Z�(�������I�k��՚�)�\��L^R`�[P1[kFҝ!cQ��7 ��@]�ԵI���_*�OP]Fu̸݈���}�!,�������$Uy�ǳ$ܲ��y.F�3c��>��:��w�*L�b�X�����r�˷2��Nf���d�?x�2�4Qm���@�m����%IGF`�\3;�1J��N(<����v  ݇Y�lqR��Y%���fz�$�]�N^?1GoԳ��l�$C�+Q5n�G9T��D*Q�K@*�B�d�6ǁ�qk����U&�ú\�K� �Fq�+l�[����zv	Z���)}���Z�Ӏ'Q%�:h�����
̤RY������,��3h0���Xm���0હ>(o�@&F���E���x�W���(hV/D49�WU�Gw�� �������}>��=��Y	dKW�NΕ���fG{��n���Ҏ邞��C`{ݮ/�:̘X�<�6���r�-��ɳ�L��-r�xr��;�& d�5�{R�!fQe��4���m;wl�E'zD�o�~&�l�0���}�G��T��S��?$�ƒ*��di�EgyJi� ����4�+bU��ː#�gwt?lio2�#C��n������ۏڟ)�jE�k� Q~J��8[�7?�Q�6��3��&���IMڪ���f�uS�`���1<x�C�l�ں������>����������6��UM����6�$�t�}�Q�&CN�FM�4�9�h��l��B�_�-BY���7���M&�z�7�����rܖ��f��X�\x��� q�u�:y���59�K�|iîuJ��3][��@r�	��������&3��H���{�:)�;T�ھ(�܏�u*2_/
�,WYl���G��C ��2!h�I�CLC�pƛ Z��|:�G-��K�.'9->KوgLK��b�?�/��%�	k����	����Q���;�����qҬ��ITS(�£��]fi�0�����*�����p �@|�P�.� t�J�KPi� D�-nB2l�IL�~.c��#�J�GPQM�.��}�~�V�d"�����/Wv?�8�;�[�����Y��MVi�KY3�ǥ N�D&(���I���$()\g^厡n���E���r���͟e���3���q/MPsmP��xf؄%_���ú��A��U�n8�8�e���?�Yb{���a�����:��yH�2x�� j�� d��v�E�Bsu��5�.�4/5T����R�[��srB�Ɵ'�DM*�$O�P�QN�
��������$��БG��
j�.{������~mX<�M��ޏ��8��>O���,���N�Q�R�,�vE��[�3#��#�pJܻ�����j �]nf�t]��/� ŐI�Е"�{(�=vG����J<"��#L=8tF5c(���ed���I9{�9���UslbjP�� h�A@��탆�Z
�J���z<����~KO<P�Qz�e��8����_�\\9��˧d.��P|?���@����K�c2h+�|I86I�͛g(Ճ�Ņ����3��:w�~B���J���A�.�x�h�2h���jv��XXa�z�y�b���@� 
�����`�����,�o�����_tL�>��3�W,�ͣA<F���J��`Tie4����u��9��\��<�Lǲ@)��F���.́��ƌ�ѓ�͊9[4t��r� Z#Z�1�iP�hO�U��|��(��v�f�/��<L[Rɶ��d�mf1��ξ��Pm[l,5Ҝ��v��@��ߟ�R�=s����(��.+$2��;-j���Y~��>|��}�H�s�̹���~ːL�mۢ'D妩���Ŭd
[Q��2ȖF�[�����bVƮ���<����s��d[��=d�B��]]���ͧmrڮގ�5�H�8�\-��8��>�锩*F�G7x�V�7yb�N��Qk���+�ig!XcGTHj���iAJiͭ���wL��8EGMu��nS �aF*���h���S�j�]O��H��+쨕CX0b{��|�2�Iz�>���#^f��vT?��(������V0�瞖_P6/��x�=����mO���#���/,K3�Щڪ_�7�N��4�Ȧ(ȶ�j3/B�#���Jk���G9�U��b*����;�Ap�C�:m32V���mG�e��lO�p�Y�7\���T������R�w���UFW�i{1�;�魄Ax9��0t\��K���?<y3����c�NRD��*SF p����찟��+��ڂτ��"�l��G�T���J��M����t��}(�n���d�c_4��O��e3��U_���`����1խ\�}J�:�s��6�k?�l��" ��v�©zϙ@	<"��nQ�aqj��ۥ���`;#�
��~�y��k@��#�P��������F�F?�N�l����!N����Js��Q�@)\�<,�i����g���.�F�QH���U�|�;ms��'vR���@y�iv]������b�88!$��~S;K���t�;�E=�_�}�N,H
]�3{��B�J�Q��<s�3��'�lJ�F�+���kC�D+���E�7���<sAPZLaS��~G�NeV�-B5�?ToiCS�wu	Qg��W�C(�E����97���>�;/��X��g���T���{��f�Q$<��8[J8�LDd�8�R.����d���X�l��@��wV!,���>�+fhj\0�;����qƧ����>��E ��f �Y��n�����o�JJ_�p���?-1@��0���U�]��N���|@��Lo���v쩰����by�[ɔH%����'�|�����b�R��v�5k j���r�������\Ld�[M�G�j_�+l7�ᯚs!j�� &H��G�ݼ��2��s���Ҥv���
x���ͩ�{�|>7��!��u�`��t�<�yi���A����D�<�K����ߧ��d��kI�a��a�@z���xzh�#�D�H5Voە����_9��P���ҹ��&IRD	�+���&�B�<�kC鑇��Z/_(�OG�z0��L8���yk��ן�>��C���6��ʐ��L'�u75IU��(�g�GSQ�Q8��a����3`Ͱ8Tv�~��P��jx�4���H��@��[�����Xt�|6gۍ��fd�i:+@,X�L��~�"��C�5�D1k��O�	�(o�a�0K���C��d4S���ؕx��jo�%���~�-��]z�P�������?գ��~4P=_�v�LRFa�@��e���>���{�f�߲+LO��ԡ�����VO�+KA�_��q�:\mkl>�~���9IǏC��p��Q'-*;��3x�ͦ%K��5�ItF�)�u�R���"��D��i�#�Ɖ^ �c_�C)�8i��!gL��p�OD泧��)����4+���� ��ô.��i�.�)A���V9}t�����X�~�k��(*�F���!����+�eEB��\�T+Q�w���J|��c����\,HU����,��j�D�Y��O��"�+�6����S�(�߆S��:��n	���&V3�=�/�~_�޺�Zm��>�U����E;��F0�t�@����}d�Y�Z��7���	kX����N�q�5����bD5|�6��l-��춄��J{3��Z�GE��K1�K�V�$�_�)���,Q�EY�,��O�՛
���uɲ�"�m� ����������T0��LV�5����q��,�c'p�@��C�C�;����O	�Dى� ģ�%��c��j������nR=�:�J�	�H�$fe���9УVj8˷jNB���ȴ�L�R���o$��$Ao*6�8	f��Nu�1�:3'�Rcj�Uf���Ҧ7�r��F��?�ƅ�d���p�h6x����G`��B�:�˛J2y�*`���tS���*���S�I�<��Q�1#`72A5�����~uLN�#�mp�gU:�,��]��Y?�f��_}�&���9h��;�`F>�]V���R~�0,a?�N܆}v"�^;i���BPk'#C���4#��m���ږ�TQ_����7�j���+�ȏB���������ͻ��I���.㪗Fo���� ���?Ҙ�V�jߟ��]z!�V㼿·o�[�82�[<��U�sl#�\�;�4Icak}�מ ^f��l+iv� 5Bq!��2I����#�=�B	��R��\i��6��*:
�C�Z���\���5��!?f�;~��
K��
E�9c�'�;|&i���a���RQ!����� �Et��}<I�P"f��x~ �-�ӌ��G�
t���vF�8�iE�M]�`��
M�#Ӑ����NI�O@���>?�p�H�<�=�-"��M��i��-}V��EP*��j<R�m�|�����\�5N#Z�'����P�`|��QQ_%���i���N�Z۩�i8!�W�WN�	�V�t3�{ӕ�N�t���r�T�_�~���d�;pr�q����P*��5KJ����>�
*�ى�
�K��$���������@����[V�jU�q��;�
�G��*L*��%���mq���w��E��G�y-��,�K��Ph�鹹�,����m���^�E����d�ω,�0Yy���v��r/M�ڜJ��p��l>v��2�����o>:��@`d0TiW,��H�����F�y�.�J��5��k�Ϩjm5�m�m�3��A��RI
���k�|U�UFF�
�܈Ģ����6�|e#<��w�q�H����01`�sTm�`V��	�s�T��b/�<3K�Ty�%�[��ӷ?���
SХ��Į�t��I==�]�Gb冊oJ����� w����8$�	�7���}��=~0ۅ�v�>�\Z�fҔx*�W�j�v,�w��m��	���n�꭛��ӑ�n�$V�%)H��`�K�s���/�ܣz�т�잤aJ��#0 ��:I���+&�r��N������	u��F�Ⱦ���k`%Cu�m	�
����f7��
���kL�S���B�I�j:7Hd��)a��Y}��28ǝ蝞3����Z�����V�qs��mђ�X�!�btRdCh��j���P�A�1��8��=��X���f&��O5Cߘ�lB����Rl1P�I���W�\���F�?���/T]IR�X!�~��I���|��"=T[��j^|S(�+Ds���*�TOl� f�pb��&+M���Lr�Ck�M��jU?��ǖ��(	��OX��N{H�!�,�מ��3M�w~,�fUn3b���/PU7) 
�a�!ĭ�Ifm凰뒂�*�>� al�U�����F`s�Xȍg�S�o�@\��������������l�����f���F�  �&NB���t��F�n�r!XIQ��ݻ!};��͌�Ҽ����ra���g:��ֶz�K5�"0��<�u�I4�Z�^,�ye�m������륳�W�	� �	M�a���'��Ls��H������e�sE�R�-�
8�i���(�M��q{��ma����
�J0�S
����7g�[�@ ������oG}z�X�oO�������B��iLK>6D�Ab�6���X����4�Z�F���� )r��X�����8gQ�/Cw�6n��"lnk�á4'��
T-��Me� �j}��'n�U����HM�-ߌ�������K�4�?s<�a���'VHn����ܝՁ�slv���ī��D�7��/���2J��(�GaK��?K#�F@\���e\(tC�xؤ�
[D��urc��'[�$+j�/:�E.���~n���,3M<�}��H������UZ.i���`M�[X<S&�s��p@b��m���Z\�V���x��ɱ�*�3Axg��.���B϶V[qԱz�L4,Z�	"X�ZN`
��m���ğ��>LȒ�Y{]T��c;�z�+�4ƹ�,0vt?�|u�3)���M�G��}�88���Z���V�~8��/�ͯ����O�ѡ��#=������^� s#��%w���Wn_(�܌a&���^*�-UD��������+��G�-��$��4MwO:}A�j^So�7��A��$���,��֖��
O�!�7)g�w)^�tV��z^��8`Ng���.(��o��X��O���5��1�p/���G�a���	�o6�^���dF���o�KM0>��wEP��v?m�ڴGM<��\��#\��N�������4-�ऍ��?l�(��A�(��w�v���	��y dPq<�����Xt V:���"<E�`�xһZ���zؠT{��I���������.H݄��ߏ�X��	d�F�\B4y�K�v����h��5X�̵'��Qt�h ���<d�͡�C�@�	6O�f�*φ*�����|Ή�̫�*ȴ�ݫ�el�fj8�K��g'��Ur�g�MMU��3�w� #X�D>�Όx�TYR��*X��+��F�Q�*�%��h9��1Vb`1}^��z�J����UQr��+�:����o�����"�:C;�5�U�&Ynp#���6۩�TD��d��L(����e.�A-ȯW�}py���V�ؓ!V63�+�P5S���(��1S,�o��f'P�ׅ������.ff�OR%�"x,;�����i�{��ĸ�F~���\$;u��]�t�B`n�w��~L��?W���s�|���6l�a[Q[ ��(���5Tj[�� (P~�p#�uЙ�sT�U��f��Ƙ}���L/n��bc�y���^�j#߆�e}fB�n��},��c�*)��Mt�Ɉ	[L[�«�j�w�J�7bpp�<���J�G�`��!gn�κrg����	��z��.���4+�a������uW%M��p!P�	�;CeBE��ۜ��C���a�b�GL+X���݃�Q4q]��H�1�D߭6'��M�>h����Gt؎�h^�f��xI}�N�5��$��Uk�$9�J>~�Z_��yZ�T
���M({�% ~���ƃp���x��z4Lf��3�}*�׀j�è��$	0EĹ����dG.��%̠�I���C?o�����'a��Ȑ���Cv{���QG�jqhS�<�9��^��7����*=	��c�;U�V�A?�u�r�ړZ}D7�{��HB���7�S���8[��ݰÍ]d�*�jk�u�ۍ�/>ʑ^�
��J�5���7>�f�v���A^���#�ma�}U��oa�b ~�UqE�����7���d�����$���%��9m�:����.r]�.-R&,�i�ŉŬ�v�cC���� 8.Rҩls���z.8B�AY�V�����ʬe�0|ǝ��zo�3��޽\�#܅�����n�k���x����b�HP�$y�)#���u���"���&A�-ֻ,6�3�ߓʼÏr��w.���bNl��Ƀ����{C~RY�u���-��g֪��q۶��`�o��RЮ��ף���Aa^Z�C��T8�_VX_5�*0���Z����T����RDJ�ku�FL�c^��q�L;U�e�[9�B]�����dl��;Mt�4 K�3�NuJ�w�ẘh�#���w��������UW�~�`�/C��$ �)gOX��F��LSG��#O��TEw\��	q�P����: �#�X�6�$�җ�����ь@��+�f�p��cQi���_�����=\��@�yx� 뮿���D�QE�O���I*D��p�)��BB�lEU���	Q6��ٝ᥇�hL���>o��
3D������:��Y�nc����Y�
_�ĊA�t��|U����)���*m��A�0#�3����F���(���6����_�K��m,N����]�����n���@F�K���ɻV�!��z4˹Թ��֘�QYuA�͚ug���:p,����ON��َ�9D�U������et0Ƕ�4����i]�ׄ�G{l���1A����B0���tRq�$<BC·�ݜ�h^����?��(`J����^���$	g=M�N��Bb�}�߈1�����4i<��چzh����~`{�yY���'�`J2�Ii�Ɍ}�Ԣ�\�4N������{Y�pB�=*�LjتU�S�蹠M�+����-sE&��7�7*�^����xލ	�w��ȸ�"��>j:J�9�/���}Q�h�>?'��c�M��K���f�ӛ�[��AO�֪�ք�`X�|����!�׾�f��G��ǰB8lJ�c���(�Hv�β\yD-Zv73�^gOڵBu�=o�J�@Y�҂�,�@�����Fi���1���� �=k��7�O�R\#rR6��|�,��:�W=���39���Y����Y�ce���xp9h�lH�r�t��1e	=4����d�~�e_�$��?D�EF�\��!��X�oy��6U?�J�ٿ��5��Yڜ��5W3�� ��-���[�P����6Z�k�T�����hq����l�ug��omM^��������e"������H�]+��CT���h�B�'��՞�Ub�K �"�B0�u��̝��z��i�"cl ����C$��S�`��0 y�ڂ�^��bJ[aQG$�5��C?�=�"�V��t3�f�̂��L��A[R�J�l�G��d�))���@;��<���B����wu@�w�eZA��c�\���)ǩ���
����3�L?����Z	@�b^���#lF��r�T�FԴh�=o갏��Y�FA��+z����#:�Ő�V� n�[DU�� ���E���H�]�N�(xQ3Kw��T�� ����&6�1u��S@zŬM_��e+6�B$���^ԥ*��AU�8�\�	�Z�D��#ׁ"����F*��]�=l[�;�Ȝ����ʯ�%�rk�q���ݲ�߳R�q�5�Y���H�nnR>Q��� �"� 6z�z}�d�Y����Q,(�8�Ο"AZB�o�dk�Y�y}J� P>��M�������ގ�j��4�ܪdLǜķ�#�%���k�fꬤ �H��G	�����R���/Ȃff/�V]2�7	�T�t�L]��)�:��nI�'� �5��T�ǈSa���Y�4��-�J&LޢZ�2f^� *�t�L�*�,�Z�<��ˎ"��
<mI������9HlV¢���qg<��t���#3<��	�DxX��	�b`A�'��yz�V8<_Z�^)^/h�-�µ���gUJ�J���LH� �S��N��o�g����6��HcDEA�QL�K�Y��mm�I�=MV؞!�Ki�u}�Ұ�|H��K�|�/���L��x���>�XW?r.p������X��N�V���w�\�,I�-��� +U�IfTL��2��u t�[?��7`�i��Dl(��-��8�����Ҭ����`{y�߻�ά�%��@l�@���I��H6o���dh���!��}^�Z w�z�+��D�=z 	��3̚NYFԶ�YF{����K�@�u�����A��ڔ�/�?�- |<���	;w��%������[�͏��Ю��ps�_��%ch>x_۱��ߙ�y��6|��=�A�?�ܧTg ϫt_�΂��� ����O�^�&���{5N�w���HG���Tua�(JQ�Ciu�=Zx%K���i6	7�	�>rհ�e�g�=��
�����,��Z���<ĩ|�P�.�p��/Y�i�B~o��9:|(?�&��mr�4M��e?�u���դ!�$�|7�``���2���+�^k_�m
9��aZ~���A8+�c����
yQ�k��-a�:�Q�$�ɜ��z:2��:�����Ҫ
n\��G	7�]>fEң�p�B�� �#|?r����R�F�1@�4�����3��?�����?W�Z2�� �Ȉ&�Yތo���<��Q4�	B�!te1r��M+�~���fGM<C����OYX�6��V��X蘱غ&~�P������yM�����EŖ=�h|\@��R�J}�����{��
n�I�{�������kI��$x���<ډ�1�H�Z��Պ���=�O9Y32�M�e'ֵ�ho�uǰD=�� �6 ���K�F��p���o�����`cf�M�آ$�X����j�eF>�䕉���1��գ ~t1W��6�,>���8�o���+�ț�&Rn�l9��;�Z���|��]^f����r	�_{^0�ǽ�\��=aC�ҕ�/ok�6�ƐNu��&X1��X�R�˓@ ��5(4��ѕ�u�������S�e�����8��Ѯ��5MV���("�UU2���!M%щa]�hp�B[*۟v0�O	�!�M2���S$�{���X\KH���u�_���q"���BZ�ঔ�'�ש\k�?)��u��
�$�{��"��)\@��D(��"��B���Yˍ���:x%����>n���?2x����Đ�O���dJ.�ᯇ�8���)W	�B��q&ł���~���$�����@��Q1K?G�na��C�ҫ�V�W����Օ�%����w!k��O �?��o�qp7M��zә��OQ��
u��B������s�8���,#�V��y����Q���pO6p�������k�lX�H���Ա��s�j�X�D���׶e��؍�v�\�zL��j~�a�Q��,e{fT[$�������KK����Cc3�<�!�����)\u@,=^�V&m�<���(�����
C�%&��Zv��Jo��
�,�?����qQ5ޢ�b<T��<��3*w�-��e�9Ћ���z@Z���-[�̤`Yl�����w��Q���Q��5�f	1+M�Y�+X/A���J�e�:+z;%��Xw�hB�����8z\�j ��&�����b7ux��H�N�~�P�w% �3�Bo��o��[$��!�Z/�ʍ>��]d��٘�H�������ug,�6/��^�Ie�2":�D�"�4�6X�x�*����L�D1�����"�J<���Ɂ��uc�DC3��������\��5x���Ҭ���-؁x_:�!QO#&�D��{�q5���O��q �삟,��7@��j�h��~�<	�,:�!�v��r��L��Y��$'�1�Rްg��9�2�C�il��sާ���rE6\��Pv��Ŕ~vZ�L�N��7@X#���F�V�!k[`ȁ7[2[Ֆȅ���GJ��g]uyMhȺ����=+6eT�n9�Ʊ��tJZ��M+-��-���:��l�=J��]>u/�/ Ƿ���9�t�fl��lS/��a�)N�Vy�E���?�P��Ou���S��>�F����]��v�q�ʅ�$;��3�����V9��}H����h���Ik[�1�[V����������y(�RCChhV�(I�PM4%��y�@�>��ZN&.1�X0�| ��1!�[�Щ.4GIZ��Ź��[���f�Qrh�&_�s���%�c�\v��M'�ȵR���w���j`��a.Mc�4*ȗ$������A9�0�	7R����k��4 \���(�xK�(%kΣ9q x����_����Q a��ӟ!�FμSϻW��p��[�~���b��!NT�dd����͑��{�4���G�{|�{ǿ�yfz��d)G4����O��$}���T$����5�ݻ�	�q�=#�_5���fS1b����z#n�r�U��G��l3�I%*ő����Z$+�{�x��ӣ����Q�؋^�ޱ`�_�M�S;���g���#	\G�}�S�.�hs�����r�}g�][S�X�����D�m�������+���4-{�I�qWɃ��{����rꔄ���fiS�B�;��ᰭyH!'��pȈ�e�)���}�|_J�4V����5,�6~v�p_��Z�%�ٺ��t�^��͋��X�����P���ҭ���Fj�5@����E�>;�k�JJ�y5��_lY��{d�B2q?�{nO~���K�??���8\�*W�o�NvD��Iިj�w� X�5�LnI�)Jl�ε�`e%�0[��.��J�u���8T�c�#Px��'�g�!���i��!F0E\/#2c�KӺJR�F�AR�j�6��G���d�'��r}9�N���dUx�?�?�a�o�ehrz]b�?��:���&6T3��R���m`O}r�;��7�h��Qn�O���zV8�s#䊅�	I�3�zŇ:P䏢��#ޏ=~��hO9g�r��=J]r�����t��[O�b��k�:]��@M
~�,2����U,�e96�
��Ь8����ō��|�+z)��`��Ǌ�Y��v.�rG^f)֌����f����Y��vL�+D��˥�_%'���R�Q���G<'u �M�Ka�@h):�.K�)�jh��}I����b�l��?�#^g���B0�%82WLI'��J'4�&���O�����0Ќ�8�b=fnzRJ��,��
�M�Ja�h�tF鳃��t�����ql7�*���`�I,Wl�"f�#��F�f�0�Pr�&��,��.��ֱ녠[�}O���猕��ʺ�T�D��~y��=*z��GLTX�F���Iܿ�7>+c9Kzފ� m��g�32X޻+�:ɢ�8~U�Uls�:fWc��y���1�gD�^nD[s�߲T�)4#�ȧ���I����@���$̓�G�Χ�0�GEj\�l��`��D��{�!���[�[E/<��w�WN,�Ood�x��|dc%\�Y�H�����!��H��W�p>�|�s�b���2�f��	r5,@ˢ�ըMc��^��H���lq&���H���0K�D��1h�����3�X���6Ь���5����rKX�lR�J��o����䢘�"w�.)���
�ʉh��PP���n��;������y�0��>��<����ܨ0Z,����5���3�YE`o��+]��s�9hA2U��4�%�ʊѦ��(�Φ��G�I�)*�=�f�4�E��!�!�a(CpI����d�#c$�J#Ji���L��k�8IyiE���~�l8��w�Z;��I��A7���m,4x�����@]���*gتo�HE1Ǥ�譂^B̕�ި�6Hh�$�1J�C8*�#z����-��Ą��~��T�8:�������\�P٣Ú@� �A�u�Y$��n�����L�H:�ē@�^s���yJ�w��~�"��y��A��h܍m�(���D����ȣ&+��:�.����k:*�<|!#�iĜ]e M�NxЕ����YD�#�I},Lc���R��X(1"��ċﴙr�Ʋ�����W$>C�`��3n�\ӂ N~\}�Vdh@x$��pGsN%���F��P��<��,��ɪ�*�I`q�4BCn�0 ����\>��7u�>2|�e���Y��yש�<��ǎkj�F�m�̮�CP�'[e�i�^�X�㦇��25��d����36����`�G�'m��iҍ���F�B��BF8������W�=-ܑ��mH|��u�z�V�|\h��=԰ܟF�m��R K�G�ʲX`����V�燺��Tj<��(�d��ٴ��S]#\ٱ5P򩛅�<"hh��ujO|�_�E��^@�����N���I�DEɇ�z!�/�Ř�We �L���(���o�`A�(UU�c��P��k�ң�w!���KKi�c3�^y�I�>k�#?�L<)}��re�4c�!��O���|ƘӋ�e^����F���qS�M��b`�Dkg�ě�sE3;��g�ecj)�i�=�Q�'���"@�-�6>뇐M�5s.E��sx�h��򈕔'�/]�]}�u��rM�����8ͣ�e<�~�RBch��Ue������ͷ��p�u�>�.�aWT
|�V��]d�j�M�l5e����S������y�n0�����X��2�;���6ݓ�S����Y	�˅`޻wB{N�~���J.�(����]��	�\��ص����2�擜�̷MGA��AN������h��m^{���?Sb�a�wk�)�j_�д�T��P7v�?��$c��q�	��@-G�1	��dc�*L��S��4�z��4!1�G�S�D����K?( ΅я�4m+�@1�"C��ќ�����=�T7�����V'��܁7P�m1�k8bz��z�����9ޤ��u��Zg_@��t��W���e�_�!8�����ȹk�R2}���Yh&Ýf�T�Ʒ�����1-�_�^L��ܲZ�N\ƩW�G��5gcQ�@n�=��ؐ�lj����xB��6��i*����v���w�Dh��}���U~����1yXu������^%����ܣ����j���W%��^?1��Tq?P�*
�&���1�~?뒖�nZA*�z������ʮ��pH�q�鄐��8������Zb�C	�Gf�a���(Sz�JΞ���Oc��f�z�lh�D���DςC"y��T���H{�X��H-P$?k��Sj�L���/Ph�@�6�ւ C�%ʱ��8�x#Xi��?��&�j�$'Yf���p<���>X���>;ڹ
1��B�/8��AM3�����M�����̨Z��G�{#-���-t��e+,��9�����ʤ���7�b ��1Y�+3쑛��x��o��ŧO,��K,G(
�d�b����Dֿ�h����.｟���©.��|�{��ˀ6+���!��ohо���.;
�\X%���#X���(�(�~�)WR�GG��d
W��DD�x�FVR�U�Ѧ��c�F�Iݨ���Y�%AQy7��&P���:���Z���*L�>-�[`	��L�r� PU��U3�5�q?�DL)�,Г!G^�""�N��y7P��#'��'1� ���h�Dͮ#�T���0(��x�Ӈ<�ti-�h�y-�F���+���w���A1l���h�%U����#�j�P ~'��t̹n�K������3�`,����^R���P
����B���I�vxi�^�rP�ު>IC���=v���b]����j��*�TmD��cm"�F{�:���<`}k���$��|c.����O�{P���7��Crdb����G�lyέ��Y�I��1�� ݷq/�d#L�c�K�빀�&�6TWթʿ�I�ת�KyN��Y��ӿ
G`u#6v���T�j$�y�`⒔l��u����F��Ŧ�e~Go�u�OP�Ky��X%D_���.���R&��<Iun]�F���tpf�9�U�K6����h�_mt�T������6O,'紇5c\�7�M\5e���L
��v��5/�k�3ʕT�5M���:B�NXe\��#Lr$}JH�/��Kh���^ni�/���y�����k���	���}�ad�ܽ&���_��aF�G���=�]�~�w��f��V�ɪT�q��Ӱ����k����#s�W�\F����q���ӄ��e�㗙�9ip�V�J�?��xT��T����]Z��Ǌ-�w%��_T?_�9i�̕)��+��s�y0���������ªUѝ�֖
���P̃.[\��*��X�W4���VcL��D�ID��=�+v�:,gW���w�5ptZ�+��'�%�"ǿ�����
`��.����C�c���I��'�fߦh+\��P;(!�sjڔ��kK����U�� t���ݗVk��3PG�QK���t~S�9k�a��8���<)?j?��[{ڱlrU��۟?�H��0q�(t'���딍Y?�y$\�X?0�B���P����+�)$:���P2RA%ֽ�.'�m8�)����ď*�:g��%a�#>�B ��K{�6\�[��@�
Y��Y�[�x���s���n�&����w��7$Z=;8��Ԙk~ި��~p[�^�~�!�kc��[U��H$�-�S����@F>��G˸��.��?����Pm��棜Ѡs̫�ɰ��9t��G��g3�l�g{M��謫��NܖHc��ȥIi�p!�i(���ɆM	�΋��*�3�5�D��7Z-�I�;
�_�'Z\۲��ڝD t5�!�&StX����q�5���G�4މ�"m̍��L���?�P���J7[���m�����m9z�%��D<ǚ$>��x�R)��P7�
_9!��m���#��("F��x��Ά�T�fL�� ��7�;yR�(m��mչ���=�)��M|����6ј�5���ng��?A5B�9t�Z�����mʡ%�%E=�\?��H�R�s�L����}��]�yä�ř0���Q�m�'���0-�$G9	����[zUA�V��y\�Y3/��S�B�x#zӪ�]n�StC<5��>�#����BO����Z�f�%���7-g����\��K�k���)�gslԎ�'������1����3���^/��K��_a��<!` .�{B��-(�D�Xt��(x#W��wbcYH���+#�ٻ�:��l��}��;������q�����V�
y��c)�~�cТ�0j*60{O�w� ��;��@*�C�;?���t�35�;Թ���ЎW�e>O��x�:���8")����?$$���51y�E��̋�Ni�",k$���W˙!���;� $�m�G�I���D�����	���`l���3�\@8���H�Xz�z8�S&��{�"��l9㿙�о�$�)�5-��M�+V���/z*��<m:d�ϵt�|�T۳z1�b_ߚ�YG���7\sB´���߱�=���f'/�i����ơ��W�/��Dk�l������񛒞=���o�i��Ks8����܇hN��t����v�fh��D���3`��K(���s�,7p�IZ�8� W["V��kFn��	����:r�jQIe9[�.LO*ge<V�����F���S��w�F���!v�G����ĩ�o�fqkWQ��-V?3�����зn���qeF����Z|�������X-[�#t�)J���x��J"�vZ��+{���	�5Q�l�/��V�g݌漴/=w�RCR�:���+z��[-��Yw���$Y�� ��������.��+�_M�%v�x��oz�qu��@�@�1�e>12��k�6�0���7�j����"�Q�������W��x��"�K,�d?,�u�9���̽gmy�Ís�"kNDFer�W�m�q*�>ܱ|nP�m�\��"�e��<���n��O�������[7絷��b�M��B�5ƹMK����%�%���7����I?<�'�R��e:���/�tt_������ٚ��Ղ;�.���`m�^�ɻJy�̗�XP������~�~��:�Fea �'���m�a��,��9��������@r��2
ӄ�I7V@������&xhz�gN��	0i��Vms|!t�+剰��x�v��\��b�{��Av)�)`�!4����[��X&6����u��kA��M��v��38g��<��t�~��SLS�z�U�k�7�z�n*��`LC�F&�?J)��|;֕��7H��8i�'D�xP��Ya�2���_vWa8�!��d0�Oi���zs":�E%N�#��s�?��{��Y��8�)[�2u�5��;*�84�������f��k;�k���ѕ[+V*��i���G��6B�k&к`zA��\8�~\���-f��٩T��KӮ7����0DR~3Fy�ԢL�HV���L�"Ay�e˙����~���7�U[�,BM'S����� R���Sw�ZX<qX�$�.�� $K,�;�<er�&:j�o�!�6J!�q���I�Ȕ�ZR�����g�=tWMOr�c�1��}�@�g4����` ��v|����3{�i�1�4��>���F--,���ܫ�(��hأ�Ӡ��X�m~⽜���^?�&��)��K.�M���	���kI�������w��t),�h�fB8yim���p��}Ϝ}ۺ
���o�E��>�0�jy��5���Dٴ4̟	Ō&����%�:5��QJ���C	_�,��-q�lN0���R�Y*:Qd�k-�|��n~��[; Kh�W�ſ�vP2��7w҂�J�FU��f���	~dߤ�6� ��be 5���g�%	M
Ƭ����̍_�h�[�׍T��v`�<p�p��ٜ����؁��v���:�Bq�T;3�lP��Ӏ��A>��6�*@;&�&�̦����<O���e��y�6��Cg�?�����|��S��KL�a��xu�0h�<�{�Qc���S��n2�	L�s�S����@�d�������ҽЉW��-�I`���E�=�kL��2�=큕�hGB?D�K&~��71nٍQ������e ^��u�O[o9}'&]2�wJI��i��z�E�T�l?ߗ�Z�bM��U�˙@�G�^ЖT(���E�T7�����V������T��Q�h7d4$��UETD,�4B�>�,f����D�Eh8�����o�D�����065Ż��aג���c�dsusM�f��-S��,BF%<S��N:
89/_��B4�,e~{|I���}E�0w�81A�˫p��SFW�Z$��z\bODY{���8s�����s"�W�1![H��r��c1y�8o���
P?S�s#R|L��΋�����c盉�3�c��s�$z�Q�[ 1z��v�i�#T�Q�kL'(�{n�z���:����k���n�A ��B��x��n��E�{�8�'cJ3H���}�);�}���<����gO_�p�R�fm6��!��:�K�O�������)3XF���A �8�r��
IΧ�?z�[;���1I����*�_�6f��03H��pA�������T��� �%2��\9h��q�A����/��d���N�8u����6Ã����"��"�S]��ǉf`�w�ePE�K`*w���[7.�|N"zf!�!F��~�|CbsN��s�TWacڄ�D��+9Y��ܓ�hf_Y�F"pZ�j�B���2�ɪ�G�����˨���H�T�2;��8��P�����q��q�����uf��s��+����k��`vA��Q��I2,4"��T�����CL�׻��g�l@t����ﴲ����C����Ч!H��"v%M�٨���3����_��\F�i���q��R���j]��*<��'��
D^Pg�O
s�X+�q,�s_�z.hߩ�*yH���Z	T[�"�Fs)�}��Q����T�ߚ�}*l^!�4��5��EȂ~�u^w&,�_z�)�̬��$&!o��x5��L��U�չ��Ͱ��^�DE��\=h���?nm*�����l+p�����8k3} ����z��x���J�!r{|��v�Y�?���kX5�7wX�����x
��蠌R��kՍ_^%����e��.Z
�w������JqՆG#;>�v_}�����f�x �?Ȟ58,P���~[�{Y�ڜ%a��bL����<�N����
�L��=��j��sE2�������Vh���rfjX*�|��maS����	��W�O�+,8"��bѫ�M�d|lʯ��n���o0�eru��#�/~#�/ߕ���Ϫ�
��jۀ��^��3j74�����å	ld�V�-����&�,.�0�8ngN��s4��n����\+�JT��rfF�;H�w�B�z�ߛ��84�{�i�v^K��Y%���M�G�]���"�|� v߯t(� HM�!A�G���t&�Z�mV>�'U�L%7 u�s���jʗ�L[��a��+i\���v[U�"�����G�L�~�c*_]e������r�o��H1;+K��?όCFV<Ђ�&��z�N��[ʑ��aҪb�χ.���ctj�
_�Ӹ�������,�o�>�N?��$Y1�̶�Q3�(sB�.C^�T7����(c��U�$��efM�Y_�Y_��� |>!��xȮV�Q�f���Q�RE��lQ h殠n7}�k��-K�kԟ�ឫ6X���*��ٺY�t]�*>g����<��T�l�\���a_�^���v�Lm�6�"�/2�^�-��e��TTv!@w��Ⱥ����@m��%I��4BX���U�{��q��J�Ⱦ��Ǖ�	�2z�����Ӕlʥ����`���GG:&lI����Pd�ƈ�G5�06���C��(���a��y)�'&~T㟨�U���f�It"c_S������6���>}#�N�m�_P�Y��X/��ջ#r�qE��w�Ⱥ{���O��X�!]j&�֔yb��L���O�D�'b�����+]W1~ip=Cw#	�%, �w���|M�����gB�WpW�[��>#θc�d-*1�]S���>���|kA��	�0 n|����~1����L��/Ia�-��ޑ�2;:2�f
��:�J��`I�	����	�ŀ��윪���%��~D�oj�_�HE����*뷜.�ְ�t62����̖HC��Ɉ�jz#��h���QU�)��v�c�h��������F{�`��O�WVLw"�9��R��~)I�W`1ꍍCB��9�q��%�ɮ҃��� CS��9Ud��{�:U�Κ� ����a��%�f�Z�@�e5Uua&�r�p\J��YrB� 7�$^�-�2��yx=ғ����\�IG��@��D]�dM14���PQ�;���ڵ1.Y&Mw�p@5k���\9Ή ��TB�/팕gHg]�a~�sk�D�'T��6�h����ǐ�2�K��'7ʅ�o�̀^��pkmG/�$��D��@�*zw,Y�
�V���c��.i�m:��OL~L>;7j��g[7�躟��Mr�C6uGV=�(epuB��]�X&�WS0��of�c��<��%h�ګ,{F!s'r�W�(�w:���n~�ڥ���3�x�Gf�0y�B��?��o�\���!e�'bst��d<�;�uc��-�����Îj�9�k�%
�U*Λ�����Q�y���)ɒ�(hS+r[�lFX�{x&�n�L���Z��u�x�_�|�+ha=�@��4IĳC��x�]���Z[�K��(x���Jق�F��U ]Cy�VT��z	q$�\I�C����%jC���!�ңD��/Yo(���Ne�&vܡ��������� ���a�
��!�n�L����sk�WK�C[|�v�V��	Շ���ܘXM�n�&^�a��;��+�AC�Kn��'7L�ɭ�|�{�����kFL+�S[�7]�`yE�Ec���˗O�
����F�"��0yJ"Y�'�^#���п��/FVt�@��z�K{\/{�J{�xNM��͛q���UEx�ݸX���&��%{�ZG�{���)M�A��U�Q�K�#W�m1�d�^ogc҆!wg߭4�A`���vu� !Q�ˤq[*W>GD*�	�8�(�w:�Yn�@7�sw����I�3�s��o�{=��+�%�t�,�fc� C�Y��qt��uҳ,�寇&)�u.GC������^R�6��j:_g�0թ�	]�IP��C�C͵�ƍ�;:{>:<�e����(���4�2!Ҩ�PvL�hsb�?]#�6�X%�~3P����Zj�x��i�Rg�--wa����o�0���
�-�Y��N��B:��S~M���<�i��ܠ.���͡��uվ�19&ig�2U������V�=W��xf�^�/H������(�:����{/����Kc��0E�{�$���a�	�XK]�3��p�WU������j�"�,͆*�z6���%D�,#Ҁyv���害Ig��I���T`���Z���cz�ɑJI�&b���E,	uy5[/~$��[@s��+�^�p>3��#/[�c_k�	a�����.�):�&�8��ܙ�sq˻��n�EԬ���򀖯-��
�bUq����+�z/Z��:A�ja^��ͳ=�,WPl����4* ����xk��a2�q�dy�ѿ�P��w�4g��,s�b�P��G/�uG����r�O�� G��m�;�t)�8�F���\pR���+l���:���B]=��2��S9���UF�с��#��5�h��'@Qݥ
}�
��Vl���Üi��{8�u�&�`ެC���F[5�֨;�ǭl4vwO�Ȥ��|3��� �X��.�z���5U�p3xqd�<�j�m�F�)B�y9�2�'If�j�A�bp���^�#yt��hҋ�2'b�'���t��Ь:��U$�9��x"Xً�z(��~\��F`��s��ֆŕ����� q3 Z>���e���-r^NƔ��O]�i��˼lW�]w��@�n/�����8�R�H?(������nMC��;ìT�ƈ�
&�X@��X���{j?
C�7�'��^ENЬ���>p*��܌6���g�J!�\�$���M~L�yt���]X�,�d9T��{�q�،|�{�/����a۠�9P��*8���1���X�2� |P���)�T '��+0��`��� �F�_���f^�.oUnt4=*�W�����۰�wBǱ�JҪAʋv���N?0G�#!����$!3��g����)[V[ �P��y��S@E�832�7Q��"b����#�qBl��:���[+ޘ��2O��c�I�n�M0��&��R�f��\��R���0d����H�� bGR9j`�%2;�_��G�t���/��g�FiF-�H��չ��d�T�_�N��E	{�]�"�B��}����y+<1�m�#��1���=kx���y��{� ��Dnm�8p�%�?+�ߥPp���m��1gqj.�i���)"p�Em}�S��]� ��F�<��[� ��=W���� 6<��?�]bEg�������f��,��`�K��C�`	;��#Y*���\�̫�3,��1���� Y����d��V���Db�#،��s�>Zf}wWUwC[¢�M~Zʖ�-�����I�>{3��fM���&��"н��֊ �b�,�����7�8���5\}Xℛ����~`���,?_<���$'
B�\o���Z�hq�"$���cG�����3#��μ���~f��Y_O�(���J"�/�oϡ�Z�Yext��ۙ��-Q=h��㻕 ��F�Uy��q�]��r��X9���d��u��dTb'$�2�QR�E�0u| ��1"�eT z/U)�=���v��(����;pL�u$�-:�[�X���\���6FG0��@A±*��m�\d zu��/č#��p ���E�S�R	gU�w�o"t���\Rm�����!z�inm�q%�w�p�j&���c��WS��SG��u�S���~��V�7�D��=�[������������D�Ȯ�tp����~V����i�9�jH��g��ږ�|���6�O�޼�u�Ht���+���ҟC��>$�!����o�r?��R�1VtB\��ԓ��H��:���EѲ��#�D����� �I���c�-q��Y	�����z����ϐG2�@���S�N4W�{׸� �F�sv��qI�	RE`�A����q�lr���o
r�I��>�0��IS~����ԚWQ�9�o'�J�t���@�����`ي�`s��駖���a�s|�3��Uy-�C��"ˡ0f�JG܅r��Vn�� E	�yϩV��K�t�W[�D�	�EK�Hv4�U:J{4n=89�
ѿ�c&���`%�Ì�:��|9G�@�O=�^p�,��L&�z��T^��
�n(ɵ����i��m,,��.}����I����\w�O]�9ȁLUJ��Ŏ4�0<��d��.=a} O�s�kߗ� �gX��x���+S��rM(����3N�۔��;��߼�H�K�밲�I�� i�ܯ��W.�,9��k$�`�Fơ�쌰	�	B�ٓ�֜���x����#S���;iEI3�l:j�P�c��LN\���F�a��م�6�J8v�$�ާ��J��� �,n���W�������X��;�A�&ω������r8Û�Zh���UxVڝ�Ly�'���k��!��BNr:�1!Rq.�,@c��z"�>�MF�}i?��7�.^w���>����Tx�T6�ÿS<@�8�!�sG��WJi�sq����G�Ww�ϱ�1��|j��/� 8?�,�p��X{\�<��:��k�..(J��z��I�Fr���3A�ee��a���JU%�.�K�����֠K+�ɗ}$	Cw=W��A�/$��|)�%��Ey܂�¸QQ��Xc���mp+�O�7ȣE�VU�-e�l��׸��a���i��M�}ZHE��f����IMl�Bz�K�0+�ѧq�]0���     e�R_���� �������-��g�    YZ