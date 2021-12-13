#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3841130579"
MD5="e56eb2d438d1527fc24545c571784c92"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23932"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 17:49:00 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����]<] �}��1Dd]����P�t�D�"ێ �;�ѐw�jT�w�O���`@�|yw&��4�������rl}.�B��uA8
�3)��h�68�]��c��\�B���.��	��M�JX.����M��SdY��dA�y������ �����?��W���u&�m-T8���#��Bz[!�a���O0�D;��3  ���r��|&�JB��	^]�<��)���tծ$��)�d�Ƅ3�IA_ެ���|K��FU��\��84/�3��`ߓ�ݞ~��e��������L[�e��.�A:��(�ȱ@�8W��%���:Uw)���:ԑ�LAOK��@��M�S��CI|v��d��b����"�:I�1��?�1�E�ZgM�����RQ�)M|6Bqˌc�[��K�]2ڠ� 8MxĔ3i�� f;��v����ߋ�7$�L�������`��Q^b��ת�{��O�>8V�;��� �}QƽR1�8��������G�Ѽ���]�ao��Kz�f=XR�I|�j1���с�9�����c3�/�	9�
�hi���|~5��<�o��@�c:ڔ��1�TW���'-��o8������5�����Y��9�v�H~l^6��*�u!����S��mK/p���U���~��(ݤ��>
2�D]��D��jC�b��g��7��Е���[�נjN��c�c�'ӄ!,���b?7�݃�Kg`��&o��Xe�i�s0rR3��I��d�_a^.�������F�,Q�LB3���=��K7h>_w9�p�RR��
�:���S:�id[�C�K�Q�r�7�ΈŒ��t��/�	�T�����k؁�n%�v�0ɑ�\+>�b/��(�2|���-��y�B��I#��.��}��������Td��;J��b�p�-��9|[�s3��e��w7��Zcz�6l��st �řt��d��4����٥�V�
o-x�h��:�&ީ���%����w�z�e�%����Î�}#f�2���)qr�i���.5���&V��L=��x�/�V�wh�Ӻ��z��Ԗ!���:７pAv��J�����tW��]F
2K׿� 3�A�0���*x��O�X��BU|���x�a�S�3��H [�⾝Hz�F���K�����]�b�Ϙ]1y�h��S!j4n���X7�����FНu{3����I�o!iwy?�<�al��Xs��A%�Ny�a�`�B��蟇N.s��4F�+�?yA�t,�Y��8�d.@5��p�+��1�0�'�ZH�E��t��0�O���%
�&N��ٍ��ӑԌ�#c�su^j��a � ��ٟ����Dp� (�ƙ�V^�ʸ����"}��Uc]���4s�'?���Hnm܉�̈́d���2��)��*�ͤ��P����FRpn&���BO�pv�E�cnG�s���x�rV�tV�Rz�������j@7G�F��5�&�i\���<��O�%kJ���_���no�]�h�~�a�ꂱz��L�s���KnM��	=��׭I�d�Xۑ D¢~H}��F�/Eb��8z���hƼΚ���1����@]_F�A��@��X��`߀IY���Ȧ/�S��Z�-4qQ��QV�Y�zC��u���x9�o���؃��q"�Xq���ꖴ�sR��Ӑ}���t�� ��&�Õz��ѳu��g�P>������;�ںE�^�����kP,��� ~ zm`�~�%9ƋY��p=ȆD cn~l� ohp���nL Bb��FŪ���D\�1m���ya�Ȣ�ЮU@5�f�P�tt�BS�6��F
jT74�8	50�Q�CWAU����D���g�����Ш�_�*E��)%���Ϻ���9��1c=?	-;�ۚ�˜P��&���6��o�i��c	y.l���0g~����v6��p�	k��
���D���˞	���i[ ����ZZ�	 *�?P�.�S���E/������WQ������q�o��O.����/Jn����dܺ�Y�iNY|������w�	��ndM�YĤ�Y81�ЮK�a\�����v����?�����u�=��j|P9-T���סmL�h2�����A�Q*�q�P��RV��'\B��X01 OS�u���)��O��iH��idK#�(N���Gh��A#6�؉x<�z��*��+E��躜�(��x�-YFd�ω^o`a�qc۾�.�pU�����1.����rCm���P�=�ISE|��OM�"L���wM󜄛��3�Ss�%��TȒ�E�V��vֽH�ё��=��]�z��y۩y9�Tyb8��X`�QeXnxd�����g����+SH��s0p�Saȍ:����H�6~q��H��v�k�����%N�Pry�
6���j��� Ú�x��N�D��[N��Ԩ�`f�fW*�#ze�\�r�/�,�;��7���4��yN�p�.Z.�;�|Nri|{�iK���>��tm������=���ӓ�q�����1��vE���=,�
D��J�k�{�e�G������M�����}�"@���ύ���~�5y�G:��YiMaHF�!���.�ӡ�z-sq�­��2idv9�0$E:�;=�O��g���L��9IZ�lM��&z Pu$؋c��b��ȏI�j͔;��|e�+p��������Z�����}�^�!��ŖUvW<�{6[��4�Z�K��}� ����Y�� �8�A�6�j�g"\�ߌ��S
u��3@�/lm�<�v�B�i,��V��1�\>$��lI��kB&���K�����p�Ĝ�j}��[јCGX %>@�{����9�R{!�:ܞE������aĂ��d�~H]��0_�y|r÷���42�҇��w}���v���A^a=}D�a�Α��v�gq߅R�i0�� L��0L5�^&�=�h�U�{����!�y���x�� ���BT8��?�����m�A �pS���5�NPZ��M) ����x���y�U��!6*�9C�Q`M�7���bR��W4�t�y�f��h��tcJ��y�h^%��V��R5p� ���J��D�Er׎�JZ��ta6�"o�6ȧ�Q.�����~/9h�Y�e��!ÊS,��%��q�2\f�p�`����ey�P�`Հ���P�e�$&��l6�V7_�,4Z� �M"Α�˓�����0�M���f����T�s&���'��킽��^&���|�d��K>�N��c�L� �ދ���M�+F�� �ԗ����5��/fa$	���|ʟ�q�p"s��!�Z$�u�����r�þ!����*�)���JP"6�9aV��]b�|'כ�	q&��dL�r���.dw>V�C<c�	3�!3�;S�Ȝ��3�;WP�����Z�s��?���V�YNx6�O�jd`�`�Y���@������yF\��6�4@���=m_��*��ǟr�M07������IΜb:CdfwLA�m��W3W�D��3��9�hG�U}c��mi-T����X����9f�NO/W�R�2�Vܽo(kv�AY���B���t]�8`��\��Y�H{*����#��G��T��j��V�9R�n6�#���j�r&�j�Sh��*y4�vK�|������#M ��N]P��>
�{������P#��:�g�P�{�����ܨˇl�#�^�7T4jMH7pS	/����[p^_�;�Ak����e���Ȏ~S�1�O�ȇ��^]�i�:]������HTi�[�F�+��( ��BC��<�zs��k�@$-�vFH6��#�/dcuA����zgM=�!c�"��Qa��z/�1����:z�,k'F�f:��<Z��7-��EI/O�
M���sJ���~p鿸Da�l-�~�m[����9����͓[1:��tYt��k�ւk~��v�T��ݸ�\��;^��&S�e��oU/2(��"
��ZG-z]C�,��y5��k��Ed�J)����Bc$�1����Q�/�յN7�K�`� {3:���8�!�pu�/%+���X��<��'?~��]Q��t$w٠"����@�w6d!X���Jݒ�����Hd��B�;���
�b�C��yܭ��}�����&/�f��|+�!G���͉�0�s0E�Fj���d�#a�O��K�=a
�9~����٢�R�Ă��]?@N�H�k攌-%�6����A⑎�;���Ȱ�n�e��V��7u)��S;A��a�N��]=TE�����ض��c��� �Y簬lm5F����'}-$�����~�	N~��3-O���du�ݥc
d
<(���I�X)P�7|�)#��P�@*0��@)Џ�=l���4�Gx��&Z	���jEM�2y�M�l������ٞ�&�z#����i�.��F���m��2DQh�O������N셳�y�])ʽ���l�!�����uNn�f�4ũ�"����)�r�G�S���?wI�:9;�-L[J=e�.�#��h^:#�]��d�w7h��g�r��~KR�X�nV��ׄ�a��P��&B�9��'&����6���|���ͣ���#�?�����`������:T?D'!(�M��8����*�F���V5��~�H۶V"J�n+�� 8����"6���HA��Q3����������џ��X�.�5��0�:G��3|�-��ݑѦI�~�!���R�ڍ��X�S���d�����%����)��(s��B��d����[^�a�HM�s�o�<	��ē����tA1����M�~�XF޺�	��z��㏛�I�.t��߫�J� �������2pI������/9}�8���!��cE_���e�j1�䛳�V�⭎�����F�����/ݓ)̱��8̦`��\�T��5mv���e�]�����5B:���$��|�`a�yd�z�I 8<}1D0Y
�촮�_u��ߥ��:�c�)�w�3�����d��Vb��Е�=�m\Ӈ"�CŃh�^�{�:��b�|�	L��t��2�V2_i��w�ntQ]�c����1��R�s2�DG�ѕ��NB���p�V�����]�0��Ti�ٰ]N��e�!��ѵu�I��eC(#/p#���l!���J����<%ޙKc�ʧ	/'Q�>�����CQ�����~�ɵ�ƞ�}�m�H�{�E���{���ݡ:���)a�p�-EjJ@��YЌ��/e.�8H���fߝg��xm�
���
Ø��!	/t*&CJ�n⼪Y6'��nv�bb-�kV7��&j��^�����6#9��ȗ]��|��[k�?�D���p�G�r�\d���y��'�EZ�r3�%�o~�| �|��z3�6[K[�p`2�����$��`P��x�^W/�q�$��or�S����Dœ+��W�����3�T�2����
�:X�67i�b�+*���R	]��@S´e�8�N&��y�:u�g ^��c��/�C)��A7�4�yd�Z��H�s��nn�a�+80F�#�ÈG�OJ�Pa�dy��1С��B-X]�]���˨��w���<����K`��3=f~ca$|����)�4v	��8;�
!�B����U���6P|Z޻�E��쟂�i��a�b훬��i�+��m@��7c���d��nƒc&vJ0�[1 ��8
�^˵�{� {Ir2�,�t�h�Џ]-����������I
�![!���������~��Y���D���ƞX)��p�����o��E� ��g�v��x̼�2gTF�J�g��/^�H5$?����K�t��/ӵ��L�?���	���ދ���Ľs����
^;��x��M]MJ"�\BS�QX���a繱�*g���OK�4j<������;��ʀ���pD2��[�J�p��
d��*�%L���hv����o`w���G�%���A2b��{�)��E��= �	,`�N�/�'YN�G���HtW�rn�8�ao�g�q4�t����9�|��P��x��^ݐ!�}��l�2q9��NO��������&�/�~Ui�:e�M�����p��/�T7�cxX:m�c���7�J�����z���N�$�;���8��������}����	,򤣓.�k��L���A�~�
�&�ͻ�j]�����x����-rO��� ��\��C�H���~��O����[�1�R����\�m�	5~��R±E��Ti�if6�	�.�-]}�de9��Qӄ��2��u�Ύo��C�C����>��zK�������D��
Y�jl�H���,5�S�+���B�I
�k.��W�0���.�d�(zzͯ���#���̏�k��"*��ό���v|=���&��=i�9aU���v������� 'm��ؗ��g�i�T����q\2���y�"ʭi���֏O	�9}I�6�	�*���n�}��;\�>�VӚtH�z� �#�_p��i+8�"[$0�@�4]ޠ�wm�Rf���BH�H�J˛h.�o��-�@8�2p�:�|���#�3�[�f�v����zJ���[��Un��I9�g
67!vM"N��x�p���l<|"᧱�A[��m��_��_BgD�Ɋ��0��J����|�c�ʠ?+ z�D�gQ��5��A��������M\L�I�ŀ�Z!9�*q ���@D�fV��2V��KL�*�K��F� �>.�4%����n���7��V�B����%� �+ ��������A\	�3*�;�3g���lg��v��Nx�[�!�+:�J��R��ϒ��/��E��ݩ]UyMa�
�#�P�������E����D���ο��6���:��o�#qy����~�]��ۃ��S8ȫ-�uؐ\�yL��Φޝ���랥���d�M*7��N����.�~�z��/���*XBFRuu�3�c���������Ǭ�h��r$ /D�CI���l���W�m��N�)��Ħ"��a�^�m�d�dL�,-���#�"������):޹UM�����j
.����	&n�����C�ݾ�1�%������n�v%�#!k�4�W}M�T�1)��w�XR�4��y�(>�Z��m�|.�ei�/6��֒���]كRk�y#�
%-��׋�֒�9�]�`���sn�h8��z�ұP�B;�i���|K�K̷U������T�IF�*d~�>,o�
���'�^�Kax���Z�9Y i$1Lڇt����k�7���0��r��C���gǏ�Qͭ��`��ݖ�T���^�\�Ӄ�%G������]��L:|8	l�D!�e�w{
{���')�I������|}��J^����LipG��Y��0�_������IԲ?�qL	�Ǭ��+��"�<lq���}Cɜ wg3�覬���p�����EW�M[���]����.�Nr޳SL��I�*�ݬ��ċ9TT��3����&T��b�#ND�<.��fQ��G C��`�)7E�#`�M-[��.�EH�qs#��˫�l�&(��p�c��2^�9[9w�8\���c"�o��u�r�����u���Lf�B�����I���8�� ��H�]��hh�7h�wX�K ߺ��
��|�zD_q�t�� �g3����wc��ю�YQ�?u�<�E�̋�N�\��ћ��5�R��:�I� �,�z����Ԓ��Fmw���羦>�����h��/@�}Z�@��%T<b�z�,<�5� w�$���c)�|W�2�Y�BʐC�_.ό�����T�a'�[�x94�������d[�@!�m	��L����o�%b�x���8[T�#A	�ӷ|Y@�j4x�&e��=\d���ڠ��N��[KX��{�$�N@I��Mxr����(�m��:��"D��._فt���j8A�e�'�)3��(�9%!*ݨz������B�_X��5�`�΄�V��`���,��H��&��l��(,�:�r��Ih��\� �b�e�2o�>�e%K�0h�s���v�F�J� ��l1�C�N��Dٍ�#���2�
�M=��*ַ���nw�������Ǣ�K�v�A���d�ί�IX���'��ȃiURR��BtӞ1��*p�'�ѧ�����1�R�p/^� /�e؈�Gp��<k�}�<ϑ��xY!���\TĢX��Ϸ|�['�oF�f4�������=�i�(�`ODE6��5ܓ�b���e�R�{��s�Y�E6(�W���Yf�%|i�@հZ�2W4~p�3���@0�&6�X�"צ�hV)�5�֡�@\��9� i�_`��>΅y�[�t�W �pu:��E�wLCؾ�[���	�>>$"w�����J��������&#e��ZR�+��x�U�$"[͊�c�<�-4� ������.b�|NU]LHvJ6l���`�chF}�zV���q�N�v��X�m�8��Q �_M�)y�h<�fm�Y�E_��.�p�m{C��0h�[���=�zn��Y��|S�Ӏ��][������^����aq���{��
'k2v�>��[�i��e���R���o��+�ZQY��`��!�x0Dt�a�U�y�V�Y�dv]�˝W�Ɋᐾt��ع|��İ����W��W���1��ѢY�E�0 �*#>����_���=�x{M{�����H�uy��r�N��\R���4a�e |�����3�Y������/�̊Ct����=K(���xʝ�ve�k��L�hn�g4�1/�!��e6�,�G��[+�+�xك1��̷a�A�?���e�M��npge�)��Cj��K
���[���7�#^3b��Jhn�ӊE�Q*U�brg:���H��9#;="J2N�}I�@_�О��z�Ld`�\�O��V��Ok|'����j���-p�_
�!a� ��1�~D���������w���v�Hڇf��}V�q�]/V$�.-;��v~���󘜨�M�5���������M7�zD�H�mo5�~]D���V KO�H�������C؜ n���K�a��^F|1b$��8��.��W�xa�<��g<�;�BT�]@�����N��R)��ɳ�q�`��O��n-^�Z���Kf�T��3��/m�n��i�)�W;D]����i:Y|��?�uKsA9f����y��sa�,v�T��|��6�o�(�~K�@��c:J�����~é�a�}ڀJ7�~b3b�s;1n:�����1��J��S;)!8���_HG�,=��*v��f
�%�3����
g�)��X���U�j��C5�zћ��ӊf��Y���7��7��ATx�(t�qx��z:_F��M1�0����S��;�)Χ���׊�{�{*��%�Ԯ�Es����w�����DU�/����`�|2��jb����L��۴�@V1�N�$3!X���G?���0͸��>��n�Z�K������q�p��=�M��_�c�  �_	H8�/EH�j�M;��|^�s�]��v�A	v�]�y ~�X�72��n(��CI�t�U+`bz��|җ��*�v[���那v�mR|U��su����/3�����3<��������Փ_j�6�UU����R�%'j`+�:%��y�� u'�����5�%�3&��i]�"+{R��iinG�VCN���"f��o�����|�k��5O�}? V"�R飐�X��햻{�ggx�I���T`&�
ĩ#I�?������[��·ҋ�N>�v"2�k�3�!���j��
5f����[�qӤ��g�h��� M�譔�=NYq�p���%*�";�bT���W�-��T���ݲR�����ն{�z^.q+Ao�H5X���&	�����N[y��c*�1Q-�����\�x�r�O�+�I�zQ����7Tm���0����Ǔ}�E���Z@�dtJ*�ď]�[&^ R���qo�&�	�s���a!P��1��h�
����.⻫�H�]w,���fP/��Zu�� au� �_��
�a����c����l�ge,�	mX�b�8��d,�#}W�ͩ�r��K�R�_�^�l��J���%���	h�v���l}x4��"��m�]V��%�t��4�^����!�x�Ěwf8uz�	��Y�F�;mtM�a��s�Χ.N��2��u��N�ѓXb���!�9�T�$N{(Ա�2�b	7���!�I��쐉"+h<���}$o�#�E 8;��r�r
�hX{i��<*��=��F�nȫ1���Qd� ��PK[��EM����� ��UO�PP~"Ђ^fg��tOe���L�Q`�B�{l��#���]���Z��0��,b�o�Du<}Ň��;�7Xa[oR HJ�{Cx�=�������C\$r�
ؚ10�N�@as��}>UP^�g��gf��m��6��)yΏ��6)Y�����wO��yleHVE,l<�Ľ��/ܯF��PW6W�~F-��\R���獺�����f�~��2���"_S`�ʝE��{Aj�=��P�4ګ٥�ֱD��4*0��(YNq�wU������ l�j=Rֽ10��g�h�]��Úʽ�]��#�� ��������P ����BK�?��E�)J&,)-yv�
�p4�~���-]X�I�;M����v�)�
8�H�"��;PX1�\�#Jl�~����<���������M�~Q�H\����q%�ҷ<G�Jr�d�m^��#4�X���ow�׭~7�+�턥��v���E���w{G@K J���p3��
X�����2����
�4%�8�s��8řy8R�����a��24�~�ǂ+�f� ��~j^w�pI߅FU���7p�8C�j�l��[��3L�Km��PO�z�܈Ϫ�:0���l��m���B[�ڈ6�&�8���\�k��q��	�;u�3vv���|�g���(�!��,�G.�*�S�����,�-��<�Ͱ��u��0ճYJ��o���M�,l�=��Gu���Bb����=V2,.�^�R��X�4�
Ww���I��*�c��l\ɑe�d�����3�>Dn�v��ҷ�f|�,A�5�v3M��JPŘr̈JG~]�OF^\bD�X�����ǘ#�iNT.JP�v1r	�բ\~�7lxA#+�v|H���U|^�������.��� �!� �8!h5�72�LR,"]��w�Z|�ْ�؁�ݴ��Q��ꂣF��}i�'I��F�����(�`�C��`�TW��~�\��C9���n��S����ʔ6�g��w��<p�����ŸZ|����yD!+_�,����2 ��l�n4��e�@m�D��T{�9�-�o�;�7����&!�� ��f���`½dgj�	��۝��+sǴ�Xu[�33�%}�T��V��@*�u	ȶ8�=�ӷ�l�b#����O��N~���t�r���Rҹ��G�/Gۍ89	jО�Nab"��܇]�\�����/�Y�Z@�k"��|��Ō��E��@��p$v�0|�U��e��1�<��GEHp ���zL��8�ʓ7�W�/~��/7򯔵�ULH1â1~�xU��F�;9��\{ז}J{�����L��mbzdL#�ۧ����wo2�����9�׹���۶���ڃ���q������>^�l��܉7��r��aO�
�5� �5��6�R�Q=�~����ss*ظpN�,��x"�pJ�|��[c��;�{�f� ��MxAk�-B��!�_�!�+��9JЀ8N/F;P�8�֯e�E�1�!��X�4ݰ	���ƌ�jݨ�l1�i�������#D�e�\N����o0�+�6̴�"!0�qj6]c�K��~
h ��TS�RJ`$����nv��T�+��Y��epv�?V��y[����+� �c�۴U�מ�75@���0Z�xr'�ʹ�f���k��j��}�k�ο�$ޙ�2K�@�$��UD�sd�5$��5vE�Y]|e,z��Z�<�T$r���YI�1QkK��z��f���=�������/��dT-A���y�#T}�i9�G'b0��x���Cs3��?�c������$+~wq�SqO�x��GرJ=Ҁ����\�dF�[^8������3%�U�����C��D�A��S�za�8��.lC�� _	<ֆXՕ�Z��J��m�:�2e1�~2�Ͻ�UGyT<x�e���@�e�A``��6TD�I�_��~DG�� L~����df_ӥ�P4F�����M�t��w t���=�[�a����c���ŕ[1����k�ìޫ��+�⧶6��m���z͌��w�~/z	#k��{��d�\�GY�]�#��dhj\j+�X�7UGd�H�q2��Z�֓!e����egv�t��Tlۈ���D�r��:m*�?�����'���V��/D��m-�S˜Ɠ��1��i�f <<�[Qg{H��e�?* �y��q�ez4�ī[�Em���Uc��o��I@h�w�զA�}阴�Z��J���ò@�C}��b��A�N���$�4_Q�dV����$aOm���6�`�W��-R C�j@��c6�e�����(��Ƀ��'^�/@pLJ
n�nP�3ym��m�;��vV�A��S��bx��|�?�2-���va
p�`�8��7�K:d�B�~`�5K'������U�H���Իm���Ղ������P}���V|���B�Y������x���g ]$�}���$��q�q ڜ�x�:r�[�fQ� �O�|�}[n64�ARԏ��j��tk��G3�)�ʥ��Ab`�_8�%�C��.+����Jӽ���uf|�MZ)��, w q�������"_	�^&���7`p�l�)�1���;��^�jL�TP��dn��������z�?���Y���A���u���i�*�\廪���8�5�y�1�V]�r#h�#��"B���g�~��#}>:�z����Z�vh�֥�i�gUh�>KKJ���g˄�ml�$rhS�����3�0dG�3��}�{������E�d/~R�'=�/H���Um�z�^��ZwC�s�?�*�H�IX�|�3�؅����&n	�6fX�e����_ci(� f2�_���[����+A���X
P��wH:X~�`����^�Ȃ<�0��)��E`�s���c����[�>��-;�b�H/ESg�B�.��$�0X5:���=m�y�����3�~�^4�������sV���Z�g#��nj���U�@�1��@�.'A����˘��Y}�l���-	�98\���^�udK=�d���t�2ڇoI5I���M��r�b�z�y�u�<C�P~-��	5�����#��{��,�<!R��+��B���E+�.�N^�l�wV���"��q�'��5�E~��	�Ķ@gƸĸ����2w�������to_�]��^:~(kJp��hq�k@ɗ+0oGu��yT��@��`��~<�1��Я��97��Lr��2`��Q ,���y?P�1E��i�E�|ؼ?���w�
8�mΞn�%���`_l[Eh�0o�N^z/І[ֆ1�ge�jz+��H���C�G���!����]��sM�]�<�\�7%�+��e���k�M�w!�7�I6�ˆ�&��lSU%���,8m�G��n�ǧ���a¦~�W>������G�NS�7��֨ω]��q��|�ѫѪ�[�	�*t$u�C�/�n_Ya9�̊��֛�Q@���d��[
��eT�]e�.���fNPⳌ[4�g7�/�� +�G�rXA,xO���_tZ'��<���'��O�at�_�!����(���%��*i���D�nxʗa�8��hA.7���F�vnr���2�~m>������C��|�h3�)�Ep�T��P^��6��g�聥���(;�Aܩ���V9: �J^���/̓@0�t�˽���h�j2�N�\B��xY�����z�@f�NGcHC)��4.���˵�V\�3�_��˛O��1Q��f� 骴b��1�t邱�H�ڿ"�K��
9�m��`�\XzT����H%��A�!�ߎ7t+�ù+8F����_o�oj�M���EZ}�e�Ư��{d�U������K�ۏ��eg�@Yԕ�N,0���%iAˏ�⺝�f���U�"{�l=fo�8���!L}�Hv��My��}�~���Ț��.~��P��c�V�������E��D�gz�_�(Lb-8gbL$Z[�C�x��a��k���#�L'O0H��	��tX,e�O��q߿̄��(%��i�J/���[�, ��`�t�]���O
�y	�5�o� ���H�&�anr�d58q�F׶�Xʉ�5|"�76�7�:���d�tD(���?��}�Ҏr	֗N&K-S�.�Y�y��"l��n��$��a�\?�մ�[X���b��2%�1��#u���I���-����8H諓b��0�ZPD.���ĕn������?�"Fҹ�O\�+�7?)6�^���*��gc�[K@ێ�X��0z��m�z�"0���t��8�w���,YC�53��^:՝�p/�X�壏�ن��02+��!�1�������Z5�o�?G3(�'安��e�7���Y�b��wxg��	3��(��cDR(d��D*��-�4��f�R8���t>���зŭꁤb�����[����.d�d|G6`�p1��d}�Ny�a]]}.@H����<��g/����_��W�f�%u$O���B�j�ie�9!�j��}1��#~�)�����p}��y���w�j2s��=�J��ۄiTxb�>?wD�r�K�E0���H^�+��$DI48��=�?q�h���~P��ݒݍ`�~? I[�a3�<������隙s�*�xq������Xt�[-P���vo����JcR��ݥ�1X���G�E��A���;o�%��-��Ү�[��១&-�q|j<�Ň�@��^>�6��=�s�A'#|v[
�W��),X�ţ�=7� ��[I_B�d���~5���THo�&g��q��1��;��Ʊ,�����f�1u���}�̚ʉ%�J
�v>�͇�DE�H�"G��4�u�3�J����_�x�˒J�c;�P'5 剜%�^��w���
��e:g�� �r�<�KW��?I3�p� L
6;���֥�c���g�\[�n���`�CP�vc��HJj�X}28�KK*H���^���_:I�=���,\\k�Y�5�ďuq�>��K���?�{t:��ժ�/��5���2�,��&���xo�w)�Ϛ
+�������#�J���*@~V8��D��BE�fMc����'u���	�^��D�F6��� �����T�7��H�Cx���x�B�p���Te� ���I��6F/�k.t�A���yJV;��|٣չ��)����N���-��l��F�샎?���L�~-��`��>7�L���-����	�b��巙���]�1�zƮ2��{�/U�:J`��G_�z~AV4��*ϗQI���,��&��_��[�`���?��`g�M�'��᫯����FieCM񀭐 �zc���[���Q�ɧ�u@��O��j�Ht��yYHJ����ͺi}b��L���5Qw����Ƒ���!��n�7^�=��v5YÁ�"��Ia�j�=!���lfj��R��-R�5�/�AԬ�1y�H�n���TW��c�nV��{�N��߆��9,�ʴ��CC-"Q�&i&�>r̠:�Y�~e�nu��籟#��7˶@'�d��[��D��e��rY�|�V��ќ�mB����f��[����6��GM~��&M���ߠ}ћ©V��`C�e˛�AiΨ�� ]��]�CNd���+Ey��~
� �l��-3���Aʝz��4}�wX�VQu��n�,�\�;��s������\3+�ԧ�B
�^dk����n�X�I�̽�(<a፾l�F[7�C��(.��7�(ht���&��OL�C�םU������%��=�|�;ہ�L��bi@�o�����}"���2ר�$W���R*�g�q�u��&M�}b�e�c��FSI�)%�2�F�����.)ܒ���TV�&�Ez?o`�A���Ƥ{v� W#G��/z�邛>��	�=�,���t��a)ᜯY�L���EJ�'��y���,�?d��v�����y�YL��N��"J���#��.��&R���^�.����u��)��枌Te����g4˴͜�O�V8�5���d����^.�k��'d�q]֕��|P哬��^8C�40Ъ5��0�e��������+nJV�+��0�M�T���3� ,�-�^��:�Nj�.�?P�`�<��xG���G�]�c��&|�����"�������t�E��ÉĠ+E�Vԃg�������.�jYe��� ����"$�A�ݘ�ڴ.�9����G��V���y�3�lx.�Xk���[#p2�u�h���O�-/�wH5CT�}}��C�W�r�r,q�.��ҁ���?cM}9�p�����y;v�dM<vV��z4���w�|�rw_!T~��B�I�0��V� Ƕ�p+c���n�ŧ�1���}����VA�ńWf������PQʗ��e�?�I��|F:��ɖK�]j����KB��3��X+((Z�s@+��5�~�|]G��FC~y�I'�пA])���r��QѦ!%�(�?j����N����lP�bF�9ϷrJ�֥-bV��F�h�����n]<S/�T���i���8��|a'A-75�]�b4�k���=�Py���{=al.x��V7L.���5��y�e��'�d�P�y���dx�=+rd�)�����Ӟ{�c��6�������$y�e}1�:%�Y�社�K�����9�%>�ݓk3.�e�KI��y�4{��uS*����]��o^b�+�m���S{>�f�+��IoRU�a���'{�
9| z����Y4���ҨT�SYM?���CKxg̫��h����(\�ۓ�����^I]Ǒ���{?�Е*a�p�(T�Ԛ�����XI�/�y�Uhd�w���X_z#_��N���w��w�g8�d`XJ�wn�Rյj1ju^�+2S�iҋz��j5�:�q\�g�Y_�� ���Y�Ų�3FYXF�%� ��jSæ�ݚ�W8��F�����|�
B)���Ua�_�ߕ�[|,��ac���EQ	�vkS@�J3g-��gΩx�V��UD�T��=����q;�L?�_D��{�R��ݥUGz*�]&=<d��K͇�����^ύ�ܗۢF��I�.3����й�U�T}��Kf�|N��&�!�	yXI�١���_�bj���j���<�vN���#�J�6a9����!���G�K&����Э9�K�	i�}�T�K)��,~�	�i"d9"�W���n�r7�}���Ê�5�x������߽�5�}��;Ok<�tR!���Y"�|���0��G�__�gi���`�C;��I��'׍]v|��;?6���)A�V���`g�,=�̀8��!%Ř��C)z�K>���5%SCܵ�l�^�m�-ɬd�ǧ�Ŏ��*@�����D��⼶S�S֘��E䆘��θN��wL�
0细��&'�ܐ[z� ~б�L	��p@2D��#�ND��󣖄M(W��_����3\�"���Xe���wIh�[؝�r� ���ٶD`q�h�uM��e�t�������d�����9��Ăh�:��E&%�['�x�'<*Mg��R���H
�4Yh����s�ɋ�9$z����џ���3��4��s�â`�E���q��_�׋�e60�ilQ��۝��Sr�s��Xe�z�0�1���i,$�>V������k���y��o$ǒ�gM�s:��g~�b���D�����G\	�37&Q��7�_!u�G��}�D��MM3���AaA�0��G}3����L�o-�/���b}s�,k��꞉e?�VjԄn��u�:��?�w�������/$&�K�
2��B!���Â������	("���؁qe�7_�.;\�s	�������Bϻ� ����Ѱ0$�B��� �����wM�r7
Y�6s��K[(<*%��γ�i�r�J�o؃��C+�Ô���-f��� P��L�9UpLh�ʐ�g��I ��'��Rq Q�>�7Z��Qσ5N��t�em��W��6���Vm��5���E�Rٰ;�-�q��'_��	!�.�,�.���N�h����'D��$chi���p���e�pǘcH(�ה�s��i~�p�Տ���G��Y8�T�ǤI��~C�T�4��p&���Ȅӑ��ӝ�Y�4)�sz���f�>
	>�u�`Z��6D�L '���:ҍ����q	+���:5�7'E>R�;/�����G��:��z�1��*�����/�|]ݍOW�u\�A���i��9��&����Ec{�ty����s�p(3�/45�\(52�N�9�$���d�JL&a�/��Q�1�A���t.!�&(�RM`^��h���]Қ���gY���kS��$�k/s�3��٠��?ed�0�URJ���@<�@�7�|�9���թs�GG��&��Z��(��7�ƜX�vCY�w �N��M[��m�c�R�E�=�Ysl������I��Y�!���ǈ���=D{��ZJ��*JΠ�lכi�ҤҸ��K�g�L o�b��H�t|�,��&��Ŷ!ݯ���H$ь�	Xn�gBI��ȼ�<�� ��Ow�!+�t&���e�A��ƚM��[����O~�g���-����vs���i]n��A���sj�ۑ�����B��k`�B8�f�/J6W�#i���&j�m�S�T6�>�-djI���!M�^:���վ�R,��]'lǟ�v�A4Ȁ�Y�������N;`�02�nC�d�5� ��&��V�/x�z��5�c�E�� Z�P�FNg�m�U+V�$ax@��)(�N�Pbm�ƻ��@��;�=��	;"�`�7�\���`��~��I#D��n��yU/�FOLA���2S2i0�񯦃(+�	��d4tj\C�~y���_xʑ�O�c򭕐���?na��+�צ�㎤�%>IQ���U��ϝ7�1[�����O���-�9	��-��vH�QX�bbi٦�I-r�Q�k��,�d�����z�L���I(j�ȵ�Q��$���p�E��Iq���zKΥ�����7=���W {�B &����2W�X���K�jf4c���y ���{�TPb�T�h1qᦧt�]��2g�� ��Z8�?��8��jXO�ƃ�Q���:a͎q�$��ך���9���Q�&���
����>@��k�� �Y���_ڛ����βB+CH���<�<̝�x�Ō���`�)����O1���o8LM�b��f����Rh�����pUj�ؐ���-�������-��9-�G�ARG,���@f��}V}S�O�q��XU���:����;ҡ?/;��	��g!�e�ZE��h�r߂)��F�`�m0�@�q��DǼ�h��Z���KDeFm��hwS?�&���?�maj[��mԙ��'��9W����)�U����QW���'�?PSJɆ��V�O+�/cl�R�l�gO?Б_��Kʰ��9w���%>G���4\�q];�����6������K�'�6�XI�g���3!��s���|�mL]J��H(�H�����ŧ�ME�B�6S��(�M}Y%�d�tMOf��K�����M�ő(���~�:}� ��o_�����Hgnd��B��C$��>h�Y��.�t�\�)�B��K����gl�>㘈ʯ�6�����l
���b�/��☭K���u�6�
�@'?3fR*�=˝��?1��l��`1� !���:����|8�
L�/�%]U������~N,�"q9)nsp��Z���L��V�;i�v��v�3�gì+|ne�`�rq�/�%#�-1�x���W�͇��tr�g�x��n�|�6A���r?��a4�;t\��~���ϵ�	�|�ю�)��8Bd��]'����v&Y,p�-�87�/���'�zv�k�J{�y�Ժ$�ǚ�$)� �f�S�\[-b�u\��E�}A:�x�UdLϟS=�	�$�f��^��bx8�g¥BmK+H����&hh�����=�P���d���ɝ�����,tع�atΊi
�U'?D{oڅ��^��G����1��I�f&����7}�)g^������6ɷ��
u7�K8#_���?�	x\�eP/ˆZ� WIU��G�r���������w@Mg�����T���4s����,��D�K'��`�2�EKW{�J��ĉ��ޡd��3a�,�]���}ҙ}�r���)�m*q��.�b��q�讱λd�QϽ��&�.b���*`����c&�g��Turo�����3Щ65Wz�3���@�1�~'O5� U�/]e9�X�pƚ�V�]�b?�uS�|�E-Cs��Ӽ�kL��5� "
�r�0aS�^e�<>�N+	ġ�;� %r�Q����p�g
n�	����z�������������Е�և�"�i+�\�ׅ��:�tl���S�d���Z`VY 	],+K��v�_^N$��|W�� D*Ȃ�1�X��IB���#0�h�U]w�Ofu�,�
�ߝID� Ǳt⬗"Q-#S`mF�	Ap� g�߇�GY��[��U>m�R�3:tC�!�"������i�sNE�{E5v+��Ii��<Br�k�
6M"���*B�F=M�"Z�X�b67��:X���O3���0b�P�������v7E�~�G�_�X^۾gB2�b��J#�i�7"�dZfd�eJ��:��$⹵y �W�ӣ6GS�;��E�nE O�U��&�D|	:ń$���v�E*���r��?G�f#�yU6�Ӧ\#n�e�[��>CR=?�a���K �ZkE�Yq�
n �$ԏb�,�%�=Z�~?],
{!�)�u:�ǬC?�����<9h�m�\�!H�+C�} ��×,�(gq���]�%�\�q)y�}o��e�B7��n̶�j�寚x�§�-S� ���|\mqEȂ!5c�4k�h�mƞWM�H�T��B��J��,tՙ�\��n�_y�سn�<���1&����~<n�B��~D�b�5�<�Tu�;7<��fP'R�2��U�̇ԥ�w��}[��;�+�HS0�t�� ��wa����=Fa��|NK��%%;� 4|`�X��>���C�:����ܯf���N_WSM�wœ=��#F]�g����]6�_�e��fG-%O��9"	�TT0ړ�n��8�i�n%丰��?O4Ý,���e�q�J>�@@�	ӟȄ�#���&�'
�u�	���G��=xL��� ��}ɭE����Pl���\P����+���IN���(Kوf���e$��H�̶�&��̻ԙ鵐G�uUTٝ��M�d�Ù�ŭֹ����a2GA&�(� &�<,��=���r	���ybgs'�X��s�UY�9'my������~����ZӾ����W� Zr2����`v^ 0�W�K�
�4Z�Ǆ�\̛�ܙ/g�� �%[��D$eE֘�ZH��bA$��;����k�:l+�s�<�LIv��Ⳡ_�����=�N�N0���~o)׉Q�T:��i'r[����n��l�P�'���"r�-�d�Z$�`�+�2nu�Aj�a�s�mIf?���A'��#��w!���.�חy~�W9�ˇ�kW��6L�*�
�T������꿱{� ʗ��iS�f�~/����������yW��;�*u�&7��K�O,�h�M���'���p�mhs��=fX[�A������?H,֔����LL���T�+�N� 7���F���(5|+ˢn68��Ħd��ŞcN�h���2/��3����H3����!� ���:�Ǒ�n�-��v:�g�LO���~�s�Ϯ̤W�GLד$���ɓ٪�5L��M?�=�Z�8+|�(��ihH:�����+�����Kn�Z^��[s��]g�=ʤ:�O�
�TB���.!0L�D����-��Vw��'��z���p�����݉&� �G./�c-�z~���]A��E�b������� }x�be׳��U�%��i��0
KnbKB���,�)z-�C�h0�&�m[+�zX僝H�:U@x��h\�T_���W(��\��:���S���*B�����KxX�&3d��upf!C�س�en7��ʄ��unк��MT:�����o����*h�xG�zpG6A����C�{x�Va��������&7N���mKt�F����@MUc�s3��s��I�RP.vB �����ʜ���__��)���23�IP�Q<Y��}�v��|�f�Aց7�#P�-k��bC%�5�����a�B�4a�Qm���;Uh(�E��@nD�6kc5�oN8�P��5�qM������d�g�x���^�C�)�(ؘM7}6�<���_�B�F#e��E8�xc�i�N@�J^�NP
�������?�� ���ޓ� 5�F�,>%�9L���GᾋV�Śwے������,:�4g���<"~�&�ة�(W�X9��K�l�O���)`��AyȲeb�(�s�+�NIֶ�U�9��#��ġ�<Ԋ��V:������m�e4��1�"9��_wv �v���,Ĉ���*co�qR8��c�4'�+�)F�c��J�ϕ�j��S���0-�*�d�iʢW�@�{иX#�F����J2��g�tV	;g���E�=���H�Ǝ���p*GA��� ��{t�6�,[�����,����MD|yX�+S�Bb�5�kJ�Br�`|{B�:dGNM���_��Ov��/35�A֠d'�����mS�o5����I5�#����-U+�����u����^��a4kbZ�b,.d�@��w?�Dw0�fw/����֋0�����y1o���3�* �`�e�Q���I��)����[d7^@�0���Ȋ�͊�X~��(7]V䗘\#�̷�R�U�ȊN�a���������m���Ê4���>�xx���H�c��=_����0���?��^嚕7�� _k��։�;3�Ys7�L)�څ�	�!�r5�E�'�T�|���0c$ɍ�ѸH�Lf��~�m����M��?���f[�a� �B.vs2pG�HKlK6�Z�h�܍����B��)����/�ͧ�����0Nug��[}g��Kq1|���_h8�WǸz�`0%0��`7�q�J��ò�z��"�I=�d���~b�X�	gF�m��(��0������c�Q��  �}:a/�$ غ��"dXk��g�    YZ