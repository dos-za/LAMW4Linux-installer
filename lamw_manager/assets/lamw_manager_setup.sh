#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="948122615"
MD5="f0e46b58dec0f6cbd0cdc58d87e837b8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26288"
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
	echo Date of packaging: Thu Feb 10 18:12:01 -03 2022
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
�7zXZ  �ִF !   �X���fp] �}��1Dd]����P�t�D��f-0o�T>������ij��E�A~6�� )b���E�Bb��J�d �>8���E�ٗ�!���>V�u1͸NtJ��?�WRӋ1X�i9R�z��ƶ��aq�r��oEeC���ct �1py��� ꤵ#$�k=�8�x�X���>��M�>�10=����ˀ�\v�$�e6�:�bla�b�,�߇L}U9�E��C
t?��S�Ś�"R�H���4�6`���˩b��:`��M��p�]�Sӡ����
EwL	#�q��r�[ea�,�����*^��N�����V���^�J��$@*S����s�P��a��E���^�G Q�f2&<��Z��ߤ�z�b<$����	횏��<��c��#��5='BD�ń~�R�'aE��7��QO��?ތ�ȅ���O�Xi�(���z)j�o>��;oE|b������l��<l�~wE%u�<Pɕz�T<��k�ƶ��-8������&R��~���i��b8E��O�L�@Ke��;�_���U��R��(��k��!6�<4&h"F�&B��B#�UBj�.S�.�ot��z�Ĺ��S�����&g~�1��d�W�̒)�qozu�#��h2PgX���!d@v]Ω�p�"�j��� BB$B�X�ė�=��X_��#�����֥5Pe��3x���a�����HP��@l�,�)���&��r�9�P�Bz�<�@�i����S�X�\g���!<;5oY
MM޹�,��!�E
�rk<��,��MA���n7��B��U,Is�p�y�;b�(��O:� �K��xzDŕ���>�\�٭�O���&gU�iql\�AU�����Ct�x�Y++I���(i�]m#�B�;,!l�Ƶ����3�߄�n�N�2�N��D��訸f��\��:���V0���'�;�o;�,�1�	�t�b��j�L�͓L6�)]�NN��y�|�=[��[��J�[�@���ͼQ[�aWL�wU����*���� ����`�M�BLcw�*�5ܒ�[�Q��e�ڪ��aMED�`���Ï��ͥ��*oV's��ۧ���+ 'M�3�r��	�9z�n^���z�j
M����R~��f?��&�Ǐ�����C[�6�/�YT����*[:A��I@�?��2���l��-�fE��s��������z!%�K=���ui:B���i&7��k�w��i���܅��ݪ�ޛ�q�d�R�C�顰O�g�<9ގ�0<K�#O~C��m�b�n��S�u���>y�(�&�Vi&v.��1����6���C�sm樂�W��c�s�/�w��Z�'��dk@��0u���|�q��ܗ���)-�W�'3�>����P�1WU�h|�tke�y�
~��0�J�0�[�I�����l
�3��Q�)[;�Y%�ꨌ�W��&�����43��Z��ԭj��v�	t�(<M�#Ap+�	��R\����2�@�ǥ��g?1�����'6S,�7u�s���Յ`,����f��w�#���"�jk&˚�2*�l�2��P�4Jf0|֥Y�q><D�G�h%FT:jb'[��5�%������J?]�3��?c����?���2o�s� l��]��Lӗ��U�9unx������"��SUFV�M��'��Wv���K���}�0�k�9�P�^t|��6q�֗�5S��������y�ѬT�#�o���Tp�����wk���b�X2�(�}�$�1h@ŀO\n�5 ~�X�D��[�F��5hkQ@M`��L5�!����Z�:�I�k�'�|���gRa���\��_٥���cl����M�rWV�|�}�(ԛ�,Nd-� ��V"�\6�;h��A=I�Ĳ��$����=��}g��������p)�^��9�D�U���1��g�ɓU{�{�U��:l�ZC5���>1�M[`<�S/�-� me�)���ӈ�H,�%���%{�u�~t�G�)��������xQ��}�~S���6��^6A�\��o��g4�V4^6c��d!r�!To>#_�0Ʃ�ޚ�#�EOJ^9��@�:�M�o�z��:qn]W�P�r�m.��Ј���x������|�؂�jIr*��_��2�Z��Q���Lܿ�4d��� ����mV�kI���Jc�rXڼ |Bg����,.�>%J��gq��=_7�G1@:��'��d\㵟�ڠ���G�'#D�%��b��c*�6�v�k�[3���'��Hnp���\(�M���B-�˧��a��mG�/١�^�!;>=���T�Q����T��sV�i�\��N��"�9\�d%�e-�Vz0���d��0��;={�� G�i�o�H-k�=���PT�7oo�(T�"����jK����D�@�X�zpoW<)��ץ��z�|����)�LU��k��,�s��B'ƜH�� ����%��~B�&�y� �TL�%���������	��Z�5�,�]��e�m������*�E����ȅ�j���ٽ��o8,�{\�>d�b
0�X��]=I_�Q������|p�4�1�5,����HT��g�V*��g8+Cf���#�Ɗ/{\]19�L�o�K;����~��YA?�o�w�ϪHj󦱰v�x]d�\\��T�6%ED1/y5�'x��m�?L�3���f�?n̛˕�p���Ƒ��6�f�F1/��'�j-p��?n�SNa#�Ǉ�[��qu����v����������,�IC���A�3�qn��ۛ���+��������~b{/�4]ߞG��r�n��|<35m���ZRK�~�1�������y�g٥�/�![�GN;��_l�?��ΏT�����?G<z�n����͙�E��1f1�"_7�kD�0�D�����hf���T}Sj�9����'����pd�蕁@�ư^��Fay�����c�aS��Jz� b����$[�R�7�_����+	�Z`2[m�|���R����Z����P:��������>��v�gJ���dр�8;ս�\�g\��I�xJ��zH�Fؠ8�:0�ǥ�{��;����(6X<���?�[��0z��)�����/�|�՚A�P�61�H������#�<{W��(���j��䟅�"D�e8QM�XS�])}�R�N����_o)���ӣ�0'�kI��>���Jg屈�|3_E�V$�ح
�$w[��nXE�0��ճ�(��g���@�3H�vrg�U/8�ˉ�'}�%ay�����i2?N=θ��D%z���\ޛ�Qb��&���BvM��	,����t�5ǹ�e&��W�a�Wct*���H��O��B��Uj�7�$8��\pKT�M�"�k�V���<'�D�Jf�P;�\���m�s�O�IE?��R�A�̞���fV1��rD?�Ʈ1�y����OƟ��4
P��	'����Ҿ�~���iwIL�_��|����j��t��\4�h��Js�;��-5��כ|1�re��c�����(�\Z�c��#�N_u��2�ڏ��933	Z͆d,_�@����mw\?�#4�!��m|m�,�B�]�= _�Mg�l��By�B'�f[ ̌�e�16m���fG۝��:J���+p����a� �,�͢Zy��U�o�Y��7-�$HՆ���� �O�.�Ӌ�;��Gw��!���Hw(�����6����n�,���X`N�8�t)��J���z��
FKgW�AA6�@�9�����6,�  n�tr�P ��n�X�.#L�.^I�F�ɞ��pV�O߽�"J��	�ӱ��%�Ēɲ@���<����\��Z�e�5B�z��F�0@�~X��}M�cr��7���ׅ� �Ng�QBQ������0-]���-�n��%�%.XH"��@����qP���"����"0���!:��%���d�=79�V��q�9^�9������{����܎�;˻�9/1��O$�� ��.�J��{~�?�-�(v��\�X��u�:QH���M_?5	��W��B~٠xC�u����!w��(��� -/��4.���uv��UI䢻�1k��"�ӡv�4<1���+1����Wyo1���qN[�X��=���VI�����$��-	░�v$�f��(}��ziv����o.M����G����Qˌ�t�^(��*<��j�O��sZ( )�D�-�9o�]B{����X$������,`�g~��m� �@x��㣹j�f��,���M��*@�h���QZ�������X��%��"sZ�]��&�_i�����Av��r��s�~Do�mz�l}q!�(�f,É9D�����Ӫ�B��1
��R�k-�,�:9ds�^�
9�����l�l���q�	�1a\���m�.��ϰn����dr��o�gʇ�'fOyccS3�Vϑ>��
p�O*M'��c�}0~�^7�֜�(�x�<-�ë}-�2֭�����?�*,�ٶ�z3��p����U1�g�K�9���]���(���eѩ�;�ά�:��zV˥��:R���'_c�<��e��H�t;�Kl�T�}z�����(�JM%�i�ˆ���a����n�OlM�\�3�}hT�����鬪0SB1��m��=��ҹ.��F�Wɰ�����cğ-��	�i 5df�C h�qv[��f-ua�톸������N�H��9�����g��r)���Tj&�o�Ƈ,�A�kއ�^	���L� �OS;�B5y��e�ؗ��K��-���h%;��4�h�,������5�lq���2v$�ˀ^_O%"n�����k7FǞ{�h��E� �Y�h�ѐ� f��P��i�B������V�u0D�M��E��?����VUvk�"Cz(�{�@�%	�D�kC��a
���4�d$���i�;����SXg�C}��*TE;��l����s��w��dG���tk�
Z<��P����k�p�V^��)��q,�՜L��@�==��]L^KzН��6M�@~�q�ή��Ι9%Y�;l��/�Y��,B���E|�V�g�jx�����̺��Dhp�b����`�9}y)x�}��
+�$�G�u\����P�-�]�M�B=C+1!�f�t(s^ �!�v���l�/� {�E�����u� _Q�������%�����\���g�s42�Ӿ/R#�N�,Xbk�}o�f�v�/�������ğ0|t��Ju��������<wP�F�Ԛ�����٫������"E֪�5G�uчp�<:���*���e���tu��s�n=��
��θH�R����<	�<cͭv�礣�ġ��*Sč�$_-��%��,D��r3�P\��rUC1�DMn����Hp�Ȟ�'�i�Y�|�#uh��$*�1�L �˰�M���v��s�]y�%�嘒�5%�DX���;����tB��� �E6�p &�Bl��D\A]��_�RGQZN�Պ�:������ˏ2ckG�$����(�քd4��Z��$AS����h �hu�AB��t��o��%]�Ph��sw�(�\��J�Z�LsA����Gs(����|��x8����{��s�.��.��b�Ve� �YV��<�	��P�}�&
�[��X���8�����Ep����u��}Q	#�ؼj��W8Ȩ��šE�}� �,�c�֗$ՃMy�eo������"r����ӝI7�1Z�u��r�X ��*�=J��_���5G�n@�)I�x��"c��C�O!�j�<s�J�m0+��������QQ���)���4�Jۚ���ҧ��}r�6�]���!�'?<HOX4f����.�G|yp�hV�ڶ��(�<C�q0rɱd�{�h.�y��Բ,�H�M԰h�f㾩TD(�-�'ǞH�ǲĹ�!�&�0iw���'O�U�V�[0��0� 
I]��z�2 ^u&m)<��O�7�E�,
��z��aJ����ٖ	��l��I��)�%��n�n��I�+���b�~���PCRz�L�,0N�B�J_*�Z
�v�� �g��C�;J1˟�iQ�V�=��&���򿓏) ��G�L�{xԇ����M�����2�o����ְ�K�)҃�Шα�������z&`3>�f�մL,�1I�Ʉ m��%��pp#j���G�4��SC�IB����E �&��
yq��Y�?g��.�*�'W�����������	ϳ��u�,!�ʣ�M��Ȧ踝*�U�GMyq��^��za��O�h��^��zK�K��
1M�K$��S!�F���$��?����y@�CKg5�I�:��A0�,�M͠����L�"�Md�1L�_�Fs2�VZ����5`�)%�Y*d��?�����5Mqp�6�poX1���"���Ѹ�a�u��n���}p�.��!\޳�>%{m���48�P��Y��x�R�^ Hg���b�'c��󄿳(�^��p fA^�;���RϘlus� ��Ս��}:�����YH��(����Yt	��Z:��n3K���4@��:��j;Qۑ��5Z�{��$y1;��Jsmg���������O�6;��nwڢ�W_�b��{p{k�jX�{ �����њj\��F�s<�b�'�{ɾ)ϯ�tE�u�$��pC�M��k≇��ts��EPz��A,��N�0$�̙Bv��%�)�̃���Z̼�
���K�1&�j*��^/�t������u�?����:&C��R�굽;`�����Q��PN�*��'s����x�1��s�(�f���v{�j*�!�$U�W�/UT��E��B�1�[,?��V%X�1��&�p�J[���+2F���{���d��e�)�Dt)sT�Qqd|`/Μ���
ꠖ�m���Y87��M��!z▣�U� ��w-a��l�Q��u�%?�d��;�X����6���jm��� ��j'�rGV4T���:�:�S�0D�����7i�g5��i?�������|N:y��K�W*w+V#�V\L�p?K�2�r�*6��0Ty�}��n|�Eܗ9�Q��0,_���F��/9�$��ߩ]������A�}����%��Z�H�b+Ijaf�uR�<,��.��K��bսo���hZ��]_��N����� 1	T.y/�+]kp���ۥ��~L�$��.�}e֛�嵶����|K-����@�&�/�"t�a��beCJ�]2Hdo�B��K��]ރ%'��F�N��0?�%^5��LUޜ��m��o(ܘ�M�E��x�qma�{��*��F��U|HA8D�F̐�$��!d���$5֡��r\�EQ)<���ɳo�	~� >��׊�*�P�>�|��o�7E ��D}H�YI�n?Y!Fmxb��Vk�儾�x��ĹAZs�Y@�'�O�52O�|v�R��lZ9FA�0�g�!��r��ݭ��J���\0��	�X@����ێ���6�W8qp=$��Lށ��i��2){���ήx���A�!���y�M�� M����bg_�ow��c�N��O(����64�qd��'��Tc�n-j)QL|�8DtǞ�a�2�5���¢��3|*�RqvE	z�Ҥ r �
3G��3�H-}\��}���u����\;�4SNT�\*�x3䎥���G�٪t*| ��NVr��u7�o,{	�Ҟu$A _���(�2���7泲��|�h�fe�SbeyTp�)'�2�=#O�N���d������6���*y"�,խ\����oN�&$�9�#��^bR�gx���A�{V�G'"����g����i�1��XN��ѷ%������J��/4�� ��3�y�l��X�7��j�Q`��e���R&6��4-������1�|6��N)@'A�yGs���\Qf�:&$�)��>�*u��_atC���T��V�_��z�@�߶��E]��#a�}���4	�մ�P)�9�m�&�^�_hu.H`��>.Y���m�B�.N��I�x�zM>�l*/��q�W&[9gY��h+𖛓}^��;H[���?���!�֯IH�@���C���v�6Yɽ=Q,�t�K<�),+BK����S(�r��U��vs;'t��\�M�^��Wf#wD"��Dɝ����}�ɘ���'0)���y�J;�My(��v�"�$�b^h�B'�i}�:g�2 
Eζo�s�����"۸��6A�S	}U�?��c�Q�%G�%�j�(�R�F="��H��=�?��KҼ�B��b(����2\�$��m� n複����e*�ĝ@���h��U���ÿg�Mx�h�6Esl��hx!OP��o%���,)H�x�5n�"ҧ�=������*!��q�[b,3ɽN�a��Ac�$,J$B�gl�O�96��Ӫ��Se�������p���6��[�o_܇]G��,L�5@�*��m���$�5���\�<<�N��V|H����ݨ�/�t�����J�О��:I�/�.�����J3�RQ=��y�98�Ǩu�Ff^F~i�<��Თ�. �@x���	#����t��0+5f�+���vҥ��&|vz��؃���.���VcL/FL`~�(K9�Q9Ѧ����Ľ���bR�6柪��Yc�oIr����ZRe��]�1��$�eL�TI# ~�YV�r�%>Ϛ��n�|�xy;_	/0/L�̑���<���{�c_�����$9;�������@�\6vX=s�"����Ǻ|�ey�'!�����x� ��C	5��qn�A�S���~���x��	��U��Zi�?��z��t&�:�,�I�&b����<CI�z��� �Ƶ�gO����x-LPΡ!���~�쿟ᾯ�48��k��H��2+Wd�b�ᷭ�b^�
7zP.=��C�̚�Ӓ��l���ԛ߽�~����pǅ���?�-�8���+���ֵvv�z?ӗ,�*�W��
��P_R/�	�4��C��Jh�ɷ\cM� ���`���Rn��2�\o�d���D=�'�'�2(h�B�����>���'�m���0�g�b#24�-_�V�`��M+��F8�y}��:b�"�.��ws��e��5�r��������ob��_�1���Ğ�c�&j��#�������R��KE �t���w��].%��t�kQ��J��ҸF�rGx>�>�uS�5L��j'�SF�ˁ���i���&�%�Yv�i{�0������f��0c�A��A��(�gɱ��.g����p��L�Vѓ�D6�)���ȍ��d�N�()y���7��#�jߛ���OB�^��$�#��jؗ�@�V�l��d��?e��c@"�9+��_b��dP�h�����Yfӯ̝�. �:���Օ�z���#�A�����V��ÝqԮ��U��0k���R�Y�&/��nd��'E�k�1�(��X+d��<�+�K㷥6H�M�����ƢB��%0��*�k]�SĤ�z����+W�J�nm�^�%>�D�n�`�/<�U�1�8��U.YZ]��ڛ_�u�<�� 6;��V��~�)�(���O�Vk�X�I �_�7�څ���
���P�d��xT&ͮ�c���2��cN`�m�\���S֎T�!���������1]��u���K�e���t*N�Mk�jl��_����×���_�z�L_���el��Y������m���e����Gf?w�ڴ](V���c��k���{��N�lL��	�D����σ�-l�A;ϾRIa��_�g.I���ࢡ,�d0��F�9H6Ƒ�lGu��ʩ:b*�)@�R��Dkt�ݜ�J�J�d�z���d2ܔ������I]�{��^@j���s�{����i0p{%�X��~�Rv��a��8/�. 9�舙{���Ο����r�z4�lk���<��eab�U��@W�>f!tj�h{)�Ӈ��?��c[9څ�":8Ĝ�	9w�9��d�/���b{}vg�`���S�����	��/,�r�c��N{��t�e��
GQGe p���L�2Q�4�� ���>��Z�k?�k��r#y�u/S+f�/�2"�9]�q�$K�?�&35�%�N,��i��Nѷ��쀊��Ϥ%h�q���5LH���o��Y�ByfD���s2���L/���m4Ȅ�ā��XhѶ��t�����0�T�m�P�:���K�|~{�B�0����Z[z�zMʹ�����J}ZK����j�R�ĩOG�dnNf�L�w�|̊�����֝��Giq��]u�B����~D����!ɹx�ك�c?k���v�Wc/�e;���6p�r��]���_�*se@���Gb����5o�M����Of�`��g��T�l�G��0�����G��`���?���Q5�(]_�^.�f�\�C1S��{��C%	���õ��	�r/!m��T�i�d8w�=뚝��{2�(���+��2�;�cZ�8���£�EDo�߂(D���X������27O¡�p�M��N�[�T�tBP*u_	+#�F�Dߝ�1§�-j�5H�y��!m%8 ��N�1\�ݦ���1k�d�xM%������.Z�wD�����ױ��ZO!b�x�,FH�ٚ6Wz���P�-�#~���;�R��E4(RKSD�q��$?�q���
ˑ��t.,��k�r��s\zP�e6�p/�A��?5���|��BD�E^��=Oy���1%1Ε�ִ8p, �t�F{�sU���x��
�cV"9�|�`�&5�	Đ�����p�S`�]G�ms��8©J*��ЏX���)����P}|>��D'� 3��ZWz�^���
��UV�Q�m��f��Tq�MsB�)ے��d�oF�N�M?H&q:�����R��o�'����%S�X��v��C�͹;�����A�N��c�H�'�u 0�BAv�\�&sS�T�}C*��.W��e�;Z�\}J�o� �.K���?�`[��5�k�x�D�n�u���N����sCQ���7#�믏�A���*���	g�&�U�����B��]ގ2�u���,�Ѥ�*Zճ&�v�t�ů%����nNz���+��Z��� ���oc7�-�9[R�����]��L�,]�*�py΋�Y��Nz���w�����c�x��F���.7��P&4p�>HD����a�5�3U{ϟ��Z쟗
�Ω$@�����$l߻|W�G���g;�� ~�� ]q<LRV+f��c�xY8�.w)�%�sh����j�g�bX�>TA�1cJ]JÄ�8:If{.%��C{n���^�3�&�ӹ"=���G}f�E���L,v���6��[�"�w�+�,��`~X�IKtM7�e6,n��"��[Cd`�m�7�-��miTۼ�h��5RN�pQ=i��_�0<i;~^@ � +~��^�{���J�4��|�?etTcB)�_gv��M�#�]31E�1�]�u�\̛g�t��zom�e�zW»7Y
�]��GhQ0h�@ݛ��]�ud]����`
\.r�S�	E�����coެ�o��.��S��g�ܡ��L�n�"z��v�m�
-�(��`JL�i��b�7=u��Eك���!����n�m�M�&�L�j�Ȟ��@UP��C�o7�h��nz��!�4��`�;�]�?�[���S��¦'0Y)��ED�{'�i��᪻��|��2Ĺx _M�5�F$z�?(�鈩�U)G�̞����t;@j��P�H��[����}ls�՛?8v�lw#����J����?m�	���W�Ht+f!e���)2����!4�S[p"�-*���i��Ӕ��
�$v�~�E�ʬ��7�"��D~'^tj���*�m	����]�+�c���Fu&&01��˵��o�X����E�f�&%�@eҌ_S�˪�>��U ؠ\!fs{�x��"STf_F������{�n��% ����(�.ż�ޑW(�$xG��cJ2d��UJuPsl��Uw���I3�H�R6֕I����^����f2����w�#7GbJ@��v�=Kk����������&uP�@��m�+��ǡF?� �ʗ~ ���Ϥ��F] @�+��ǙlT�Ơi�G�B8'�Rc��_(��'�M�J:��:���(f�`��d�-�cG;߰��y�46�����Z�:���x�/)/?]�Ϡ��c�ih�K�����=��.�iq�M��4+���Ob��]�֮O&1��AG>�v� uG6É����#�wq���!4�{��0z^	��?��ʸ�J0k�Ck�N(#t$V��}s^�4VϷ}e�`(#�j�I���⫪�P-�1�(�ha)yZw8��B;���)I�P���0��*8oѕ����wHZ+W�7ėS��v+n��R$��_)�����ߑ�өW��x���<_�C��j�������T,̔�n�My2N+�<c�7is�_�~L)v6���_L�C]���\Xܶ�QML�v�:)�M������'�,�Θs����a�-�8��uY����9�t��:~H��1i��]���l�?��9h�`�o����ִ��X79�<�Qx	YȀ=K��F��Yό����n��L7��^ZR���Y�eʯ�� ���:5А���]&�� "_�(�(��x����Ծ��Z�Z��~�%��ڈ�9�Ե����Zf-B��Ni���_B?֏#^?rݴB�i�cO�Փ��0P��� �7l�~z!M�;bi�<	��'�N��.����ᴽ,�D��q�(8���q~_JP�]ۆ�hRX��Q����<Z�����VǋB�9z�[�/;�5�^0Gц~�:K�.4,������4�w��^��������4�{�ʃhk���J^4�b�d�Z�d	Z���6lx#�Lȇ��ǂ#H)KH��V������3�@"Q3�	�H���zx2���hɀ�C��}��������F;��*��;:yIƝ�"�idl��:�?WC�~��"���Drf��ץ��M![�η\?k� Z�uI��#۴(�j�*�t%��X;Y̧e_��A϶�W�ɉ�lw��i��J�	543���$/�:�����yE+�?��X�N�g!j��1t�I4X��� Hl'#��"|T����O(ℛH�*'��n%G�>E�'h\Hf�ݾ�(���W�4P�u��+�HxUCN���Y���7�$���Q|u�ڛ�q�u�c��V+P��]m����v���)Uu�}�d�yY�#'q��\a7�ʬ��?��g�4�a�X����g�y�V��G�޷_��i���|(!�s9�����	mH�|�<�}���y4�A���}wks?���F+��$P:9��:�f�hOЅo�&���SQ��W?��U�a�G�@<����oQ�eTW��CNz����� C����A�6��_�?� ���G����կ7�7%�H�_��c�+�H��n��ԭ��D����/ ]�=4���I�����E�@fW���.��̠(J�0f�ΑF" ��t��4���O����6u�MT�R�ȍ{�8Ts�{�Z��y�bɪ
/��o� ��;��X���؀Ÿ�#++=����ʼ�����*st#�vu���~ zz��b��F��ow�t���u���O�G���>�Y��<�L��BX�7���
��z�-X�f��?�D3��9��;ӏ;��̵IJ��K����R��Ռ�G`Uλȉ
��!*��x�p$a?�O���m���ئ�˸Y��J�zjO뾛nP�#*���7ޑT���'�� Y�}��$Ta�V
�S�ʐ�V���U�'��;��,�մ=��1���`�.��Ҧ�M&�4�T8ç��?�z>�P���&������<=���%m�-�	�Y�����#֔�v���Z�r"�W)�N��j�ads�n/VM�6��A��'��&ô��PI���WWy�|Ca���cT�w��W=,1Q֛�з��&��0g3Y?����Ue�d��S/�Ʋ����L.�Z`�uO�a��t�s��{؛ئ�:쇮�A��Ӵ9h4:��;��UhSӞ�e�lBrE`�81<�s�m�T�1��b ��E"U�����Jk����^v�]%k�f�_�_f�'���Q�_�����
j������r�[���+K)��/��G!��C�|x�\�����N,]��d!V�8a�GR��v/!%<K�����Lx�i�j��H�(;����O��x�:_	;�%��uQW`Ψ�6�B���'�E��	C���A����-��|�kZ����n&�oMy��߽������_������R��9awx?Cc�U)���Ǹ��j�5�@�����x����)�L�(�-�{��
S&��a�A��SH���p}����_�<x�U�A{Ǌ�DB�}�=M����F��C'�j�!����${�-w�'�n<>����� ���	�R燧��_2pԎ��LN���O����R!���F��Ns�<C@L��Y�C�͋@�zyNSq��A[������9���mؓ2�y�ޖ���9����{����	z��$� �g) &X���Dr������"�nd��T�g��i�m�q�[� <��qDX��
�4,��8��������c�G��L�NM�Y�	�Yk�G�g�v�`JM$���~c�B�{Ff�,����B4�0�c�oqaϏ��"�F~0a��m�,���M"r��U�]$ �k1��	���՝�b�u��ι�?M+�~t-��*��G�J���K�̾��8;�`c8#��d�y'��` R��96�-E�R�q��W��ٿ`�$pռ�.�p�6�>�#�����KT�}��@������$����Y�W�������'La���O��ש�Ǥ�������>.�7`:[�6��c�]d���DT�x�n�~���	�T
� ��T�+��8l!� �w&����n�f�S��=?�2$<�E��'�4�dr�����Oɞ6}��*Ŗ��ұ���wby�{u3@�C�XߒP�"�B����B]#R���5=�� nx� A�j! �W�y�u;(�}4�yY�1f�Ǹ���0d��ώ�2���z��F�n�W_^0��vi�DF�D#�TM~>��+� �,3�M�mOğ�[���l���MD�f:�(Q]H'���ں�2�<��O3��W��U��]�v#f��Lw���'�/{ҹS�z�n1W���ȯ�f7S�'1�tc���Wʆ��F���?׭���i#0eQ'���郛M4i���AF_�f̸�ft��]�gX����va�T�P�Ưn�#d
N�1Nb����\�*~-�Y��+�Ųd�d�������c�Z�4��ॉ`��e$�U�|>�	��X���WF�p��:�v"�Jb_���Z  �6�:h���Y{��zj�.�$O�[���N�.��w/��i���Zj�'VF&�H�ӎm�r���9�3QI^~�L�7&��ND�j2�u�VL�X��WR������qs#�ԍQx�(JF-'vlc�4كcU���Tk���>�����I��}5��Ag�٤��آA�,֫��₼n����s|=i�{�Z�±/�br�xbV��v.u�R�Y�%J��.�h�$ ���ã+n�ݤd�[����3S.!��t&�����S�8�5� ��$�!9��ݫ�% ��Nsy�(y;��_���<-ZjQ�����V�$���e��d�|\!XG���$# ծn|4`�.g�>��ڊ�+��d�u[����Y:�&�'m|���0>8��0���!���`Qi!$V�q8��_8��A��G�-����z�|�o4>AbH2),8a�E���J{�Wv���XKQC��d*��Q�D��{��?��҆	�Qr�qK��˻?R�l���@����e��F\�5�����s3����W��K��9.}�kz� �6w�t%�E��`K��3X�F�#M\W���c�Z�0�|�-��>� ^>��������P�$��`��~�1n�>O+���Im���@��W�x��	���Yr�b�3Q�)�{ξPYl � �&8��Y+�����ꗡ�EJ������T4��,��J˷��V�����N���{큱���2��0ˌ�j������I9�̔F�V��K�e/'R��iѸ\b�u5�|��C�9����e��D��.�x�.�s�3��6�>�Qڙ��/n�b	U�sn���͓��(�s�\׍��1!{�x�(�haq�t�I23A~JN�/1����w!�s)�15e�/��}h�Q������䞲�Σ�T�,��5�I8�\d��}ք�Q��}�
�)�2*$ۡd��������LLѺ?�DM��^���ȱ>��-�u ��\N9㢫�վ�
�웚&�E�F��Z��0I�^��#�C�U�!�p�`˦F6��jз���kf罅��C�)ݤ���y��DfTM��_ M��v���r���ư֑���,����V���Qk�0v���%�$uS�T`V��\�@.�C*�'����d��,E�"�?�be�nV�լ]��7�����̞��1*X0�����F�⫵��kx��b�RO�8�)��`����i�駱������X��dqQ�۲&�2Y�«�2'�8-�
������9*�{Se�I��v�8��G���k����f�@��&���S�jO��R-�Tp�����}�:�I̾>��?%1k�b��0���4�@&DG�9�9�D�v[)r��aK$�sp��pƃ�Ę�:k�}_p��
���d��
d�9���|��jn��ɚ~�� ��ZHҢ��#�=��]`���1�g�ն}��jD�d@ɯ�!IV�S���G��"���y�q��P����-�=Q�͒� E��a~����L�Z�<�f�S|!���y	�yW�Xz`>���_�՝���5˿_ʴE�1�qZ��xV�y� �I��� |lb��K�Q��WJ��}�� ��%�$�FU���>ݜ1�����5pOx��pwW��Mr:��C�=�?G�I�Wɗ%�n�;�ղ�v{���ܽ�#�!�-8r.������%��̹{Y>V��ܙC4Ұ,$�]�U�-ש����wb6e�C��������p�L]�Ń�Wy~�I�7pX<��h{w�|�1��~�9\<�D�U?�"po�
u��F����a�'����+���y��.*wŕ���2԰��3F��$�I����oGLM������G汊����_!\�!un�C~Gk[�y6NOpg�4Z��n�����Ir`���7������������EUkO2� {o�u����t������9�K��& ��\��]���s{KU���w�W��G������j���N�k�o���N�4̔ޚ8_�� ���`R��vs�¸EDP�n�:���Z��HxA���ܢ�L�ꗙ�(�n�B�P���Mt��C� ߋ�p{j[v�z��׎�
An�'�`Fj�����Bm��쒄�L����-,7�+s�{�"�68�����B�R�VH̱
$!�CBFs�h܈R͖<�����fte����>�@�U9+���H��z�S�HxI�/�4���v�z_�G�F��C;��vS�j?�Ұ��j6`<=#��A�� �V,��m����ޏ�H�s���,�2�fU���9�t����+|�k*�H�`��9 L��a16���O�/��|��/F;���GB~�Z�i��=CaW���Z�ˁt�{�;���N�b:U���@�$���%���Q��`¼�da,�'��jp�i���.ރ�D�I��?&������B�)$%ĝ��B�#N]����r�Jk��1^m��$lU��ƌ��]�>��X�=*���!�z�[��e@���K�1bm<�z��
e~	��hg��o,H\����ڨHR}мY	�Z/d=/�L�𨫎!�tX� ��l-�/<����
[D��Ϻ#����M�EVwH�ed �D6�@�����R�N����S}C�r�߄�>�'b����>�dY#���L�
�L��8f�<�Y͢�v:_��.)$�	�P�P�d�� �2<Tq�g59-{G뽧A㎔48H�Դ\���/���l��!ؘ�y��#��,�	�w��:L�K��YR�OkW�����)^6ξ�	���2DFP��X+|'���AC���n�ޘA�����.�^���Ƕ�Q6lAn�3�/��(6+���(��;mA`A�+d3i�r��¸o�m2[�xm�N$|<h?	��]-s�K�� vE��Yj�����p����O]7<'�^{��s���voA���2r�AY�bZC_�\�y�3� �܁f��c���i#a�7�֎��l_�"j�����z�s�T��8,�����0��P"��i�e���D�c&�{�Sqv�U@g^�PV#_\��Wgk�iG����i�+��Y�Խ�b`�9JH��?"�9)t.����s�.�WG3��y�L����O7P{��$�y�����G��<18�t�3e�A_��s�/�cͨR�>m� �����C"�V��-?I��h8"�3,��۰Z�	����H=���LD����r�d�_B�cx�	�����7�=�|P�F>	��o��3���^M��d�7��͊T�+���ʌ���k��CDA�?����8��ߚ�ij��AT�D��[Z*U:�50ކC�O`�g�W�Ep~~Q���u�Y��k)2S�{x���5G�&ЫJ}���("��(NЕj�̎`���P�>��v.�a]�#�}�MDŴ�X?��5�桍0��-�|iP�	�,�c��߲ ���g"��JMΤ.���L�W���q�u��&>Yn�;2HU�SS���s�G����n�ξj,���V��t�̏�j�Fܜ��C�$���s�q
z�x>�v.���TtId)�x�~��@������A�I��S����s�K��dѺQ�	C*<��,�6(��i^��-�ⱶ{�+I]W��+6����*7�E��t���"��j�-	QS)�13_k7߃(����%�&2���`6��5��d�?����^��D��GhzMu�k�;�4j�b0� ��HɄ	��/����0s:��f7u�~�akZ�Q�xV�(�!4������;��xw�zv�g�e@Wd88;���]i%�N��[��]�C��sԇ��";��/�=,���=�i��p��G�����5Ek�)ׄ��D�~j5�@H�a�L���.��o�3r�p����A�Q�k��{��i*9$}�,r|�5��++i$����09����`]&nƬ��3d����N[��GL;��~e��<�׻�����R�c�H�A���D�l��j�,�
ʝ.��	�FEEp��~"�k'\Èjuk���'r�҉$!+��)LH�Hr�C��`u~�`'B�x�@����I�7e��3����f}�E�ګ��I��s��b����@"�4�V��'[)y�h�
�h����R�Rc��=�O9�_n��t�L�\�E���A�HJ�\Jr�XWf�N��:b���cꥉ��5OL�<�K�dA���Ǹ2������fk+�`�ހ5��g/��3L�Ku9��������y����i�x��Χ��[W��"~u0'~:����^�k�6�*8,.ևy'9�����ܫ%��	@�2�ȲI+��t��m󙵧��sN�ր�ƸM�ڠ|]��a�&�"�/!��I���{��OP�p>hM'�A���7\Ԣ�iN��U�_�&��L6G�NgJU�6�!�ufP���FI�v9�,�kg����ۏǲ�7C+���xR��)f��.�o��iV5/H��^X�0!$��zL�hRB��={6b��$^}{�e�\��rM4��:��fiXy��6,U���{�4}!A�JM��S
��â�C�+�׳� ��-R�6��M ի�mp��(dgeLϑ���y#5�����}�H���}��\�Z|��@������3z����L5:����;�I��1�sY�՝H7T������Gl��zK~�;u+@ �Έ��Xy�dğt^��1!�}"=ϥ_P��L�[�=��Іw����G��}�j�t���e�����j(�ݯ؇�MB��O�G<x&L���,K�Ux��d�ޛ�M�@�e�x�턿�������ֹ8��`
��/�l�[}g��?��4� ��EJ�F�,�6w0��-Q�;�_���t���L�M��Y��5����,�P�N< ,��Z���q̓��c�B�Ƙ^q�(Ѹc�BK&�D\h"�]lv<bƖ���nkB�Fk��y��Q�:�h��N� �F^yV>����Q���b 'Q�tq�(�i�^�֩��ͣ��=��j��D�s�ӕ�1`�x[�"c�STs^�!0.�N�7��e�T�2���8�+_YV)ٌ��6~{^h�هY��s�~�� �y?�l_c�Փ$ا��oCNë5h"?譔͖�WD���T{�V*�nU�p�B ���A�ҋQ�&����R�I��K��.^^N��l6%Ba*i��Mh^��e�T(�(x&�q�3�%�e+l��-�F�r��p��{I�<�g�j�#N���"�n]�O ��K�3���NT�ϖK�����腍�;�xs-������R�	������`��K���
�����Jv��
��K���d���$O�q����ǭע08h;=1������N�n�|�L��9��Nue!���<D����0��qRΙ~�l��d�ʾ��(�r�D@).f,"����%�`t�a��+�9'��I�0n�^�� �Y	g��ºW��5����aԔ?&~�e�ٕ�جiGb�k����\������PD���
}�yr3��3���t\ �t�~��T�8'/�$���
���c�:G�I�$���l���xh9�2��*����ru�mJ��e���2	=���6�:��Y��(��(�	�_;wޓN���P� ��?��8Y��_+�G��{����&i���X��O��o�1>�dUen���S}��j�H���|(pn���T5:��ݞ�3f[��6b��E�Lf���2��=��Tܰ!=)�R�|��m�9��u��a%V�l0GZ��<��Jx���!���P�uT�*!՗;�Y=�բ�~�*��)���p�S�������~�5�V1��f%
������P�+P��a0m	��}�+,��� ���+���zr�wuW-G�*����*���2E�y� gt/�Y#���l)H�-#f+<���&)�c��]�2��!���w���4�I��fWK�:j�Cc�R_�Y��U��>Q*̢,�O���y�0ĸ��<�: |�EI_�9�cF?���]|%�����8��N�
*3d���w��C$ڋO����"��qw��WC�0)�Rc��A^������%-�`���#;�nF�^i�����d� 4p�a���t�#[��׹��6�$j��R&~������|>a[[��p�Y�N+���)9!�s������W�Ȇi��K]�1�{{���S�B��2�j���|�e��i�4���Y����V��}������/&�_{���θ��[h�|v�`��xw�ө�h�����OGh0j!M�{7ՙD,\�ƟydY�#�\y\B����s@�v�9�ј���>�p��Ӄ��}.�=%���1v�w��}�σ�����$�(p���SZ�p�p���.��R{`[a"%�茐6����4�R���\� (UΛ�9��k\ξ�<�Wk,��b�c����2A��/���D���
W*a��Fμ�Y�w�>uT���G_a�!v�7Ӡu�H�
qv����=2�j�kn�Z{7�M �#��i$�[�Ѿ��4q�s���x���~�����X�Ozj>S�[F["�OR��f}��\P��g����v
8w����1q��:��Ά{��d�Y��C-���^fMB��>�O-2��������A�w�5CO- �i����[��!�?��I�5�dC��_:��Y�%wH��D�͐CL0H����يj��=�tx�^G����2?
K��p����A~��x'�/"����=A����h���r�'��-
���	��G͸0���p�qeZ��qEy>S�r��m�I��k:�0<���\R˞g�r�^��Y�P��m�Ԁs ����Zn�k@�p���G�oQ�9*<�?(��o[$��g<��{U��h�ZhT�P��L�+f��H\��u�{0�'cӦ�$�vV�Q[X-�%�~�����h�ΣC��r���x�"Z�N�f�=��Tqԅ��Գ{+d�&�~fJ��"2�/^r���k:�\��N�����#��u�� ͝��Ϝ<�m�������՚����	�yKp��a���>R@����2��Z Ft�tʓ\���AU�z1u~�~��3����x���pn�R�����c|ip2�迪jl����$�{~*Y< �R]V�zsm _�%ʑ�dDH� ���X��I͓�{�tpkI9!T�^m�}��u��y+�{������6�cfB�G��A�#DC��8[>2C�ɫ�IuSi��.ІM;x#�w� ���)N�_$$9+g��:q��j�i�V�F�33�b,�4�@������	b�;2��EFbc�uw<�fz~2�PM��^w���zV1�Q�'v�7�8�����
[3�_�f�x�d/][}6w�:O���0c���B�)ӬU�vF64�g%�VC�k�=mldV��������ù6��3�Rƨ둆��)=:#3��ac+��#4^�$p�� �>\`���&�@���)�����^���3eЂ
�pty�6�[ĳ�]��\��+����/���4mT 
�* �2A�� �o\���(r���vңV-�|�*���\�
�Z��#Ë���\-�9�O�9��v� N�')���w�N��y�����\��j�&|Fh�r�GE1���ԫp	��Q�Mq��SJ�J�.YB�ga��랒��(�%�p=��H�z�sJ�mJlH^b���Z��W�4��@��Bk�!h���l����P��8��"X}v8����}�/6z�>�ͣ���?��eK|ۇ�Y�)�.u����.��R~�!�"�i�ٶ�i�*��QoC�w�rm8�Y��~���g;곡�f�z<f�\��f�z�|H�T?*RF2Y-��c���nu'r��y#�Ż���fv�]���u���T�V�%�uK�30�Q<K��8ZG=��O��+�,L��q��=Z�O�z�En�@�Cg+ώ�oO0�����R�Í�ҲO{�a�{���Wc��r^�9&U*ŉ��v���3(c��)�d����! 7���?�p�PP�+7���z�X�_0�L;��A1v�*m٘@�W�Hze�$�t�.�)!GQ���B���ї��0���� �%��ޗG��"?x�<����R�1���W"�"Ҕ\�	i`�,~"'!���zm�ʎ�E�H�2�Dc�Y���ZR�$_��	�-��pU��Ų��a��Kh��G�SS5�B�5��cW:�	%�51�&�`�����bO���Wu�6��#�y��I$���7{Nk�k���L-��&�drI�t��l�U�k\��j4 �8}�<��Wa0���Z� �K[�q@��/p7��]���-d��?��'f)���\ZFh3x��4��5n/��5Ҥ �}߬.�o@�x;�`�1�gi'؁�H���b<
l��,P�ᓱo�  �`�E ��k��ʛ��vv�0)�������w����PI��� �d��Na��d����V�`�ΑZʟ�K�k ��쨯HH��5�������w�nѧ��uF���4c#�Q�c�j������rz�~S0,�JJV��7}��yW{��i55e,���F!�K�`�����+U?oe#��Vw-�A��O2�eR^AL�`��E�x�m�'v�N��s8MrE�R>��Ϯ,/ʝ(kB�t�\B~�\#����ڸ��R�.{�W�=	[fol��HϽ��[�.u���c�<M�.�]\I��v�����MD�X�������"���`�V�j���C��E4�b�lX�KS����fM���^���)����tH~nxj����b��# u�m�8�O�	���x�+�9;QwE[I���[��{�V� �]|4X{T+���}C�h�sw�/;#�O2�EO��$��ԋT5W���k�(��hV2��M�d˄�l�p��E��!(�����F<�����Ӣ���R.?"������\���UBA�H-v���1<D���'�=Y�J��VT�l)zcH��0]�/�Yy=��20$���Q~�87�A���4�y�<�̊p&�ͪZ� C��+P+�H%�}R*؉�zt%��J��]��'G�]o�����Z����g?������K�~ԋgڎ@�C��dvFvK;Eh�ol!30��l��!C���Y��u ^�\d��lsm9E9�����-4�|�G�<�VL�T�恡~��ޜyX�ݠ*�p��ŧ9�6O�6S@��9��E_�Ip(ǯ�,_m������]���h|������]��(c��y3"*�yw`�!����<��B)���Lw��nKA�͈��M�6���ޱL�{����#upQ�\Z���Y��cu�/ث"�R`����Jht@�w� ���K����i��v�)�[~�Dm�P����u�:��!ܥ,���x�;�8`<��|F/:Y��m���O��߳{��$�������4�M#���0+���oj�rS�v��X�F�'�G!�&}"���2�O��^��W~Mzk��M1qJ�Z����wѸ~��?�s�~��[M%��5i�7#~�e���~��C��|.E;�?l��|���cT� �nDjD�k7�CD������G�����F�O�5��0Ⱦj`�x��iF~��}9M� �C�m�H��*�آB8�`.9�ѮNK7��K�i�]~J����V������U�k*E�1ə�p1{	�C>[	���~������Q��	d��t��1�h�Fbk]�"�1A�c�4J����WJ��Xlڅ�q�F��4�b���/��5ϱ��\$nB��:[�&Eą�����5�DE��ZE����>�P��Ud�y�Ӎ �!��,Y�%��~����H�����F�[m�1��-��0>�*�V����<-� <�'h�_Ֆ�,���ܕbW��J�B��W��f*J}���S!c�
�Y�ձ0
��mDM���ivy�ybJ����w�|��m��z�o�rOf[�	͍m\�
~�HcYϟ����1��C�ƚ��܉��?E��c�is�L��SQ��?h?+�s&8�X�x�r;�Mט�k� ���\�>r.sT��a�����P�9_�>{p�����Z��`# �!�(g���j6��Z�R�'��F�H�s��m�$K�&���P�C���#��4m�
���$�&mݔ#��'�~�^�Y���C����*\_]�� .5T��tu�*ԫ��l�#�#�ŗk�n��Ƈ�y/�ٟ�}G��G%��m�g�����H7�u�t}N$u˯�y���tح���*��9��9�z��C�E��\�A������R�@5�86�� ���;� ��^�FU� �����R����g�    YZ