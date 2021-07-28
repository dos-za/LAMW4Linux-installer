#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="730155432"
MD5="7009dbe21096d16941302dc3b053ee38"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23532"
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
	echo Date of packaging: Wed Jul 28 16:12:44 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D���&�-Wݿ	�G����l�W��Xz��L�\g�lщݼN����ӷ`���?*'��R6��'>*�O�$`��ҁ�B�י	�&"�|�	T0�q'4�?|0|1̄�I%Ã��w�wL�.����b�-��9B��§W�SS<�~y��p�M�tT�y\�3�Y����d��cJ�D��&���6�bUM�����=*Y��������N��4&�KA��HWPBܪ�b�����d��ˀKv�a|&��~��^�&�����^��@m�k�H2!��c�+�zL&y�����_e�1Lc��W�����B�N/c�c���uW���J�oPש�?G�����j��KY����І��;c��O�I�94B���+:�i��ȸ9���>����^Rɟ�	Z�����aH�Y*??u�6&���М"��1���5�쌛�c7��pn��w��>�&���i�nF��!��$� <j+��d�M
��"���.Ƈ�ի�FH�iГ(�O	�d���:����w�uM�:,Afvϼ��8g-�vMcP̩��F���$�M��&JS��;��޺8d�rs�G��e����wy��� �@˄B�{ƹ�+O��[��Ck���İz�t}r.�qG����9(5^���)Fi;�lXܷ�8l;�$k�M����8���)睥��oϪ$�iy���΍V3�$U�WsG��Q���2>�^'��m�?�c:8���k�\�'���u�i0<����"�FIF��hG$,�#�*��� ��s�����S��z���~Cb7���S�i�#
�B�8���Q3k��ݻ혁-����ы΍��Ɉ�;��/��X�|�D�y3�Iv_+6�~ѷ�;~md�ً��Es[��;y�yS�\֩Z�㗷�����)�\�L��F"�~-�p���
�J
^ �N0��ጩ�C�v�m�¿ z7�jQy�[�������(`U��d�?�������++1�߼�tn�^�<+���1��_��b�V�w�����Ǹ���
?�`A/���.���C����4����>��ߓg�#�!��,u0�MN99��-7)�S�
V���+�����j]�W�7�@p}���i�7����v��?	�T��$�
�)Ƚ��t��;�`�-L4.���@�	ޒIi�L(��s����4��s%5��NgZ� M;/Vk`��X\w�N5�4FA�j�=��e$i�a�}0�=���Xb,F�%Y�+�h�	6�Ew؆Fy�x��lH�]��<DW䝦�<Nj@`�9ׯ�K.�tI�i`�D�I���
!���Y�+�Z>�թ��{���4��2���h��k�$��0|R����Ȇ���n����W=��_@�V��s��tr���iN�zH ��#�{�e]���A��7�����Ru�%/V-������G~*��Zs.��-�e5e���`7�wp=�~�%c��q�y�݄���
�G�%E�z�R�����@P�� g�'{�;��떚���Zzm+G-DЋE����j�X�ʒ��nf�^��Lmn_��:ӈ�]B�7�Y%#M|U�y��l���q0@�h6�7�Z���*�E��#q!W����r��-p�#�p�g�<��uu�1�괄G�$,����e2'6�^�����Z��x�@O�4?}���8|�J		
g�����֊���WI���e=�0U��X{O��dB���b���J	)K�� ^�pő��>���E���)]0'�mN����u�%*��۠�,6J���}�� V�i$�V�����^�.���_� ��I���zO_�KD/�Dr�9ب�y<`�����a����J��iL ��R_g�|_��=��)��D�?�/��f7d�,o|�l�E��"�?�^�h1�D# a'���}]�r��n�.)����k�����K�7��0V�cY	���:��8:NƋs)F���
�L� b�i�B�������TB��X���6e��zB���J^���}�!.���;7m�i.�S==+.n9f�at�Ĳs1�y���a;c�O��k��^V�&/�݃p���/+�P�HX�T�r^��{*�}���B�WG%:�KQ�3����}9K�Z�Ԣ��ZA��@�Z{`q*����`/0b��T���b4�e�f�
3���_߷pȫ�ꁶ��.��Lm��qa��q���q1F��%πT��>΂�*��ѷe>��H�����+X-�߂�`Za-���8��^<"����+p0��p8A_�m?H\H����χu�!9t����}�l&���Û�?���?���3f�p��q�7�6�5���?J-> �����R���h��Jm����<�t�`$x=UВ*�lF�ۼ�z>3#{X|�W�����P�̞jn�: Z�!���,7��a��"(75��n�����W��(\
���]�M�ǜ ���{�I0Ƙ��ƹ�O��f�fK�C}G�f�K���V��jR��+ŻY0��H&.���)�n8-\�r���k���O��Z�1���9��Aw��X�A+S\v	p�|͌�M�a𙠬.M�Ops̪�C��?d:DF�]�R��I ���਍y�8C�����zm����pb����ڤ<h����"~
�\Jt��ٴ��I���Þ/��Do�jr�"�=�v~�a�K˾q��D�r�!���DG�򦀫�� �A��� "�"�����Ն�_�F��zi���s��3U�b�����<- �ށg"�]U+i���o���|kgw�J������x�Qz�2Z���\�r\*���.k)Z[��q�ؚ��y����1[ "{�麬�P��m�G��tP-�o��.���u�	;��)/E�7�d����H [�5�a�Qжf�z��t�.�������iP�v¨��'�Ѯp�r�����=�/*u�Q�[��sl6�XԤ ��q�ưۅ��Ue�Ӈ�kL��Z�Gφ���֩�D��"j��14��1��И��]��SX��(���r|9�'�z�z��II~��[K)O��:]��K�̾�o~��ǹ�a�d�V���H]y��_��T�J�/�X���v=7z����ϫ݄,'l�?Zq�q��M��O�yt���m�}b�:=	��B����ۢ��u߄����g����}�d�1��o��|�vQ٘��c.Q��*JIu��F�]���8��6bِ�)�^�p��H�j?B����JR.BY=�5�^F��s)���T�B�Q�Ε�Ksn$M���E�N�zi��_x�z(�/��~�x�^�;h8K�K4>�~>��?HR1dUV�6m��d�˯�.�T6���Ij���b/��r�F ���M�������.q�L�OsU��wM�ǲlDA�.y?醓��0`�c8 �vsf�u�#�K�AIl�������K�+�\��;�+c\���u��E������x=����t��#�����^�C\H?����e�"%ꀹc��e�L.���R���[�IQr-��2��1qݴ�[�����0�`�>�X�����V{�nG\�`tJѬ��.ׁ�eSU)f�c(Dh82��ي�B2���11���:B�O��3+>߻�@���mg�i<�e���҇GEi�3O��[���ň�5(䦟q1'�g����k�����ŋ2����K�	IXe�{B�`�p�2<+Q���?"(�<1�j{�H�~C�L��L?���B�xMP���T���r�4XS�ěH�����Cuyb��%>�Ϟ���Z�&��v���4�!*��,>����r���d���Z,;6�߶o9��Vy���B<h6�؝褆�>녌L�£4���~�ܦ����t�DXF�O�g�Q�i�H)^��v���i}8k�(F�#�O�ѽm���'�ԸD	�m�1XW�]�[|����
T�)Jǃ-3���noq%�Xn9M�.N���'�0)���"R5�w4�)�r���Dl��ߔ�׀��}�`���|��L��@	��| ?�r�f�%0��q�>c�¦�	�/�i �se1�@�gD/�v�9�l�҅��cƼ�կf
�2|�D�	Fҏ+�E�A `S��¢�H&��G}!��#��%�H���6�LTZ��fv_Ǫ�zL�bW�%����X
w�����)!1Ȍ��r��ѯ���d_X�����;�;�?�?w-���d#��Rd=n*ɡ�Ǌ��0#@hF��ܱ��-����l�4t]��e.{$��ю�W�Pa붻5��auLX�[$͚G��՜�n��(]i�"�?�n��m2��r���]U�������2.��[
Qk�'rʰ۟M���!�ļm@���D�a�/{L�2#-���_� �C�T�r�o^���w���~LfAD��4���J��{u��Vr��f�����0�~��F��-��A���c��Ĭ�b��{:d�u=�&�6%��!��qV�<��U) pT�,�J��8ʻZ�K��dN���#K�pkKӿ����Z���t��z3Nu9�̡[��!`a�Q~?��F���߃���i�o�4�c- ߻��*�>�����'h͂&()�{������$ц�cZO��{�]����URZ�ݺ��?Bj��j��Z9Y��X��<	�/ި�dopU�O��W`�2��e��C��V�R�z~3R�z1'�u6?�.}�x����w c7�w����`�e��^r�������~E%�=6��L�+
N���!3[%$Ac4�kv؝���c7��>�.D�c��K�dw��>?ە%�60�@߳n���ӽ&��U�=$)a[b)����{���"���ؖӨs��~)�WPG6IuiA\�o06y��VB>�^�?q��\\�T���夑����q��X^A�K�s
�a��Mrn��g��
�_9���AD1J�Biٿ|��~s��e����9(n�x��@��o�GH�"/�,q����_�[�;!�;RQ�Y��f����r�{�~�T#$VL���-S_RO��W��>7kɾb܆���$�=�'0R~��(��љá���z�ʠ���q�Iqq.̂��Z-v�z��.��U��L��8 ��E���*��igۿ�|{+�d��CN춯� �/o;U[$��()���iiCb��bb�$<��l���2w�����	ܓD�L"��a��_Q���ޑ�x���g�$��[��H�a�\�� �m��E;#(A_��~�H�Y��:�0u��l�GD�S��,�N��>�@�&�Tk��?Rx��7$l�PU�\&և�RX���Z�C`\��e��׎��(e`5\��ze�a?�\�.6�0�n��j*k�>���EE��X��մ���.>��"h�.��3���g��]���5�V*l�\���-�����cH�_ٌ/ �����:F�[k��Q�ӸuV��S�U=k�R�R�VOdR�S69���������P�K@�p�YЧ�Y����˦���'�T�:�+���S�UG�qX�Ch�q��0O��lP�+����ef`q����L :�
)����l&�%������HMg�r��S-wc��"�p<����oBأ@1F���v;c�U^�C��Gl}?��ce�&�٠6Q�����!����������A|,�=��J/7;�3�_�Ԏ��x2}AP��������Ը� Xٽ���fe|H�T��>Sik��T8c��ä���X��/0m_�O�]�Ť5���$�9h9��z�X���Y���w�0���~���@�#���7A�%D���S��ߖI%)�h�jp�Xϛ��Z��g�o�Cy7F1�ߋ*��V���7��~�]~�E+���T̡o�p��ܿ:�����`NI�l�KN�и\?����
�Pz��Z���wl����.��N���c؅�t�aֵȩ[�G��&^���s�~��Rvc�an��$q�nߢm=�MM33�p��!�'����)���Eg(�d�mA��&���~�ѣ1�~;�S���q@'� p��TmS���#<��k�:\\�,D	d�x���� �#%}���E/]�RK�Eu ��R?I�j9��B8B���F(����ϲ��dV$�{�hj7�h�����1v`�κ6�5Hr�a�[���qXk��6�4ސ��8Mg���˵���{���RFd��v�,�TA�3qi�������FM?_�?Vu�<��i��3�p��/͝���/��O��Z`�����1�R[C�s���<幵J���.��G?�e���.���1~�L�1�`c!��(0��'#������H�L����Q�S(����c-�V�W�Id��C0�(�6�J���f'ͤ�'�E"�E,m����G��4Ȅ��v���; ��O����t-z�apί%o[C����8{(zf �ȃ3�XGܻ2��y� N�0�^	�.\�^�x�{V4*Gu;��5�F,�1z,�g/���&<h����L�[�oR�!ǈ�,N#	��h�NQh��+��MQ���m&^ubl8ݏ("��\�:�
��曓��gt��?Q� *~�S��_��]��i}ɏ��s������?�8z��{z�O�v2�Q�tg%���vT�qf_I�bBRN�����.��k�?��7�����6�s6N��%�Å�yf��}�>���܏ךH��J�Ǖ��t�8/d$c���P�͡!��MnR2S��)v���}5��u>�vBJ���j�D��h� �zr�{�)�"!���դ������~z8���ʊ��w�5�A|@f�!��-7'N&b�Qip�Yw�p�r�����KǙ�ba@�CYYOZi|�����`��0�-,X�"i���Fy��)�ɇFߧH���"n,����#�d\�^�X(�g��u5�o�UI��i�f��u7��|�<�����(ł��QLZ�ۊ�MP-�.%����Nc�r�#�x����
��ZEX;�T�.Z$JJG��:N�oWv�����n.��e�S�4A��M��ea�[0k��K"H�W#F�s��f�n���8�>���`�(�}�c=u4���ř�x���b���h��MeYX��T6.6H��n�Pn�*M?��إ`����Kjd�]Vf��|�^����:��x��:��l�0�������S�?�b�&?���%h=�~�[��ީi�S'�P�kc�.�����>��l	� ��rY-�6���G�f��)�w)���uNh�;"DIݚ�2� �������z�����B�������d��D��/ڡd1�����Cb&���E����.��޵I��<�cA�oQ��ߡ�:.R�9H�D�"�؞�6KRp���33*N�l��?[<��<�$��-�� O&�`�z��4*��$0x{���1�����׹�fLbWp�[b�0���
�h~���tnZ�(A^�6�E���"�#�Wg���|G��b����N��&���g�f[�-X@�v�o���?�ژ�3�r�B9�||���I��M8��l�=�I A�2Ȍ�����	U"�T���5r?��މ�������jl�,w�|�Xқ��'�ȕ�w�J�
B(�	�����X�`�Zr�~B�{I���A^^>!B�0L�{U�����x;�}|z�������^���t�`Ix��}�MT�W�L�F�ӻ'@�~f�C��
��BWC�.)��9d�(riL�s<���y(89K8ǉ�-�_;&w��⻿��ʏ���l�?(BӋ%8��JP�֯�&-ub�O���J��z)���Ge��)����`r..�;#����^Vb�0�*��o/��@F|�|#����T_�[,"��f��@���4D�#Uv�i[�0ȋ�o�nf�ê���艂gx�>���%#��JnT�4j�`u"܆[Q�ۣ�V�30���8#�����j�[�N7I����-��(i*Q=H�T@�+8���GC/)~<p���P��2)���҇���_�����T͇�z�x��k�!�h-E�_5�X6mrc9�4���] m��,��/=�?�M���ƽ��l��e���,5�K��������/���/�J��>�6��}����a��ȭ��� 6L~>��u���$Adn��7X���#>�Tr&�$�"sU��"��#���0ޜ��o��9n�L��?m��=	��qxT�4����U��rU�B�m�ؤ��ط�"�{4-��\7}P����CBΡ�'Dx:4�*�`n%I��e����=Z��%>�%���-Ul�q����I:�w4/�Y��%9�f1f�:�r����e��ql9���[�=\��'cc��7�e"RrZ�j���=�`��u� `I�y4e��}��zݱɋǂ�Sz�͂d�<�mz|�����LeQv��jQ�'5c���8��\^�z���_�.��S��j#f�7�T��X:J�fP��1C/ӏ%jww��E.DZ;a+�]﹪y�2������|m��4lxR.��hf_YW���D0��x��!���垐�4���+�|�>E���l$h��;V�Z��ԉ��cEHe��1"H��2�0�1'�Q��;�L�
�	�Y~z��*�S%�-D$?���>���S䝦OD��[���ts�k-�۷h��
6K`���zae�ֱz<�h��Hj�e��@ڹ=��l��L���5P����(�L;&���byi8¼��5!������S�'-Nqt�X�
4M!���b�in�d,J�3mY�e*��Q�^��Vޑ]C�U�z��L�+�?d��Z<˫p�ճ����%Mu���"}�M��c���c-*���S?��:͚98."�^R��	ۧ|����Ȉ�X�8\'��{��&��BF�/�+{I�Z�m?i��#A=�S�%I�jw�g�$�jjhܣ��.��"& .:���q۾7��^R������+�A��	�0.k�3�o"���j�1T��\�`0N��Yl@��E�__8X�kфk���Fj^]��2EĬ�>�>��x!����/�Q�����a4�D\G�嚭�0��P�����3Ud@��_ ����Fٰ2�.YEr�u9y��"�u�t�����l[��� ���؅&&<�$���v�b�$��z�#�U�*�����OZK��J�vv�ߎ=�֍0�_�~%3�	ۥ�⒉��F:b�W6� �[�&�Xec�wo��x)�@�pu�;�e�A������lƔ�x�!PC��K�Ѓ�)��5���u�"���G�)e�}��~��.�~�[��/w����C(�r�IY�5�H)�,i��j-MoK�n�V�5�Q3}��-�@<���T�o�
 c��n8>M���61���0ҟ9�L����HP�n8��!+��x�3���a�A��Rر'�g9�^�b${l����Mn;��m0���9���`��a�̳���`�&�䅀���/Mnj���N�a�b�c��B� 8B�,��q�%Uv]����Ӹg����''�N�E-�P��P�}NO"�
>]�_ˣ�������܇^)�`��#5S�1�x�qPc,��$�7�p��;U�3K�����D��˟��~��������/G�4��@�}+��&��U[3=�a�]���]F�tG�i��<0�_�]����������=�䊆��l����[n�Hݶɻ9e�[	�$zh���wqg�6<��C۵+@U�r{uN�k�C�⢂#�Y�D��i=$�(�i���Z��[�����}���g�{�qz70pI#+�����]$��0�����'<�O�vF秽-~B����#���R�;��`V��O������E�zys,	a�)��c����ğF�G~�G�=�d�Ia6v�80|���Y���,<��Sj�����&��g��=�(�pl�W��q E?��)����	�>�dn\H�)���(7���Uqj�r�Î�a��'����Y ��1���gV��r����ᶃR����0�!��
�KڢaY���-6#���L��1��^�9`�8�]~W1���>ن@���&�d
*=��噸�Z'�
k�N��a�������-�#6�.C���'lzU븓���Q�y�VՁ6�
��[]Z�LQK��ǙҺ�O�����@���1�{�C��g�r:R�����g_�P�2t�"c��Q}�GP#���e�j��qv�7��� 7�+�Ɯ�&���vy���#^%�����@K�����(8݄�լ/f,�٦�nC�4���H��ƫٰ1`�!]0�lp�(@+{L�\��~	Sx�
�$y�z ��l�S�ԤD�l!�ԓ�1�{�Z}�`���9:[�\rC=D��D�2\���@ܗz.������XV��0�g�$�cdn�<?��u�g��ᢆ;�K������.��	PYL"��zS�O]��演4	�ɺ�=7@ˌ"���*=\�(@��ae`����y?l/��Y�k WJ�7d\}Q��x�/]��?�Q2It��/�J��d��:�8V�2�=y��Av�4y%�=�X��7 U\��!��1V0�-������	��>�1_�3Nռ�;��[x���Ω���y�`��M?�3��h����[]��~	%���!U5R�dB�/Ѳ�`"Wc�Gϟ��OM��\(xIe+�(:�v�oX~��"��8C�2AP9��X4�Z0�꥿�>���Q�?�P-�l�#��Ynd��@��hrł��H?%�Fd���DkZ�&Z'߰��v���'��]i��թyϓ�5�8npm7?^Ī���Q���k, �6ձ�c�s�}��B�w�ALO�a�7�^�=�!|��+p�ǂ��c-]xuU
�c	���o�_�M�E��G��.s�oi��g���{��Ak��E���$��")$��01ּ��B�+3���F��]��N6 ~�KE1@���ɓZ����S�K��'�Q���L4쫛��
���1�U7i���9�n]DN��&�����բ���+|$�\;�`��KF�#��0�nmʙ#�
'8�٣5q�&�|����\O+�W�7�؝]p|2�O�hDbU_ԝr �u�A���:�C��9��|�\�γ9����)��j�B�?�|��q]��*�o�R�����r~}t.��iܫ*��UI�i���p�/��F]T0kԕ�p��[��þ��>�}�)�7+��������t	�2kV�s���p�'&8���ꢛW.��k9��.�$�	R�?�r4&3Y��P5p�&��yZ��"�0{dNe�����!wq�S�r3ՠ9�������2�uT��_�P��
;w�ʌ.2L�"������b���NFʣ�q���"'�h���L�q��hN���$�� ��,|_�Qa~��V#�]���sVC84�N�F���|P�h�3�~¨LՋ��2��F���.�`*�@���J�#66�@��W��E��	+:f#��>l��5�l�]�ëu�����O�ϼR� B�R�%g�y��.p��3ρ2S�PG���j�B,�<h�5��N�e�y��q+R}���t����֑N���RϺ�p{�#��m	>*�$#����Һ$�s�T���������o�dG��Kr��{���+a��Z��z	��!� O{�S��P����sv}�b:�J�T>~�U�P�O�u�\�$�֖����[�	5|DL���AF�}2Պ�v�k����N6T���wn��=�~֟[\��Nh��kފ������}��i��e��_9���O�js��uU�V̄�0.�s�[��>&VI��a2�/����[M�cU0V��`�)2mng�b|0d���l_���!�ّ�T��<X�pbs��Tԉ�yհ����'yY��¬�n���9���U���� h�7B�)0�SMk�ZSG�\lE�D��V��"�i�c��{��&�uݸ��Id���|�R��a,��J�f땁�_��=�wQ��s����Z��M�7�!��b���.�� t%�Ԧ�^"=�x�/���CY-"5�1>�W�t�O�Bb�~4g� ������_Υ�o�ֳ�Oy:���1�	2�E��*\����$���~;} ���O�����������[@&d=1b�u�����)��פ�Rj��.�(^<X��#"��]���o�.� ��O<$�i�d�c.9�?��������zշ�*H�W�#����҈aTFS_\�H.��i1��� 4�e�3���T�pR��[bG�B$�(���um��C%\�M�2{"=���+����.${�k@��#D{A@�^a�-�"��)�������%h9�M�F�|Y��}�~G|-���pz�o���wޢ:op^p>���0r��K)����<_B{��� C�����, re�l�rZ��e�����"�.]Zuv��َ��k���x/��
��Ϊ�^�o�H/�6l�S؜{C@�l%6� Կɫ3����XʦBu�]�����b��`G��Í*M���;_�����Q��y�spsW�]�q��tf�j
1�I�ջ�И8��5-ʹp)ńu��U	G2���+&�q@9�La�O�n�VȣO�n�+bȿ?�}�uVm�g��nvz,����YȎ�����|Ycy���b����>�s��(�聜�۟h��dl5DFؑ���"˴��W���yz��d�U�Ɉ2���h������ݭ��9�{��y�/ni-�A�S�$�]^�G�oW�~�Q{��\�c?i�������_!�=��;��c���˙^`4�oʢ�;��nxs��:Y�����/�|`���;MXbq肮�xe8l��d�3��?Y!�%x��� ���=����za������.��ߑGc>; q�W�i?p�Ls��[�m����D�ۇ0�!���kc��h�;=@�k�	���ͱҽc�4IAk�[�.�����I�H��4�iL�5��Ű�T�Oy4�t�yh=�L:�(%0^���{�:��F���"V�n\B;��YG�WT����77���-�(��#��a��1�c��� jHihG�j��s*޹�p�Gl��+"X��F�3?�C-�[9vayŰU�&[- ]���/^R/p� ��.`�.�T�dXz�ۈ|X�O.�y��d�ǜ�bxV� 9����#o9 ���|O����kS�� '�*��g��'�9�tc�N��6R�.D����U�0Nt���(	Z�9�$$���81𸡔����ÙiǢ�;��<��e�Awd�F���ʏ~�X�*�Ђa1�1�E�~���wzv���\����K�'��������5X�Pb7�Xs���x����f`
����#Q"�}�OlW���fև�v�}+��8��n����(+�IW/��e�ho�NZW߷ԍ<F;��L O39��>���-λX�i�QL6��(�{�[��W2��\���H�k�>Mf8:��L�í�\��-�߼#r����ƌ���Cc�gq_p���\���XoH�*k�9zWȽ8!�k�C�eI*M"
~=����D�DL�'��^s�;�^H�}��Z�	������ ���dP�*�E�0���th���yǀ�$@��������0}�)�Er��/�"&��ີ=4��PH�,�����l=�Ώ��ɓ��;��o���?�X��߀��y�n%�{���vN�7��ZR`�����уjRq�t0-�Ґ�.��a��;��R/"�J�T�"��F�F�9�V1����������ևF�2��A�PV!�4*(���c�wQ��s�'Ȳ����sh������qǏ�(��g�d"��]��v8P����3��g�X�K٭�������І%ɳ��ۘ�[�o6x��9X^pM_]��D� ����&����.�.j�r� �xi֐G�ij�Lҏ~��H	�����)J���C�#뚑<���IؿZI�2��,⮮���V��b��E��O�!�bf5�u5�6��B]��֡8��$���&��G~(��J�ל�W�;�8(�!nJ�:�zc+]�'�o��������Aps�ҽ(�jW�|Z+z��M�N���}v�{l��Q�+�A߆��R�L3���wթ0�H�J�U������� �R��i���ȴ��>� N7ˇ�(^����e���8võ%��@Z�l)'��rY	�H�kge�ƐD������o�_G܊�g�V����UA�)e>�9�&/F�g�+.�6(#/Y�ȫr�G|H�i�禆��0O ;`��渎A�4��I�4��Oe���]jm�%�?ju)���C(�@.��&Z7]�RՂv�g��Ó"Jɿ�ŵ��Z�^�%��?�Ԥ�Ox��|	h���g1��-���@ز���J������������8��e�a�`|4&w)P7�u�0����c'1��3]8L�Tz��R�ąۙ{Vc5�ig�"ۑoi�D�I,�7�T��]���J�G�Q���z4��T[����6Z9��������+�Ըַ�1%v!KI���A��鋫�%K�7��~:t���s1(PN�h�죥�YN�{�t���Y(s%�a�R���i�<gO�z3����R� �s��Y>�2��A}b�^��ZȔ:�י��2�qYʻ�.�l/��)�4���hW5�/[}���:�|����۟0L$%�|�n��X�s��A��f�,S�K �VI篱:y)�(*X�8j;'`��7(3+Gޏ��h����f���>ղ�Z�H ���������ƤI]Y;Q�g����:����^��MP����Xp�I����0���T�8��}��t�.g�ri #S���5z�DO�� �s�rgFm��qH��x	2�		�C4:��d�*K�w����'M�Bn��`n�)m��V�Y�TW���)%��!�}i��������AfKh�0��"��IW�*n�T3�����q-����w/�U2��esoC�钄�O����G'�;5�[-58���wQ4�ԁ;�О`'����1}>��x�)�ӳ&�&��<=�[��#�Kx������G|�NhΪMl�^܍�׉��eY�_e��5���~Da+�����AX��J� ��$���y�Reb�Xa��]�O����]=�'��׵e�N�<j��l�t4)o�׊�p<��R�:�)��	�gY�Y.�]
s��8�;#�8�F�w�v���5ۄ�U�g��ib0 ��-N���kW�:�Л�OԴ�i`2���{�����ć�q0>D$�����v�}�*�-�)����=ϱB�Z.wB���*�8.ї6��!�{���q�.ե��*���ΰ�b��1/��������peTP��i�ou�����Rߵ@�)�.��Ͽ��9຀�|�Gם}d���{�w����u~س�Jv�%#�8I؁Δ8'E��t���6�M;D�n��|�Y�v��5��>�f<������_�V��p#FT֋��Cf�B���/��3zu]��Gٮ��{���,DL����GnQqt�r�%3��Q�"���F��t��葭�J�y�fj-c�Q|S���lR]s���e�`'mI��rW����B��Q�e
Q��Dl�T�O(����G�:�`��ŊI�d���A��+�����ܘ�f���'�S7&p,�饭u�y�v���Tr���g����5V^xե����}�z&ż
�Do���um�}�thc��[���=�?�� 	����(���Ƿ ���m;b[8���Eҍ�ɦ�gw=�΍l���1�o��/߮�]�}k�{F�!��=�:,����d
��i&����O]=����Z�Y,]�,=�Ì�c�e���E��.�1�J�����\��'�4�<x�|�Ef��A�Ec!Ч�@��~8�����p-�Oi!i�!�:������q�b���<�K�s���{\�ZO-�'�Xe4uX�>v��͝������pY�d>���o��[�+�IXjs���b�K��;�����M���ȉ,����-o��X�c�<�V,{�r�Y�_��[�&%|̊���RAT缄,%�vS��@����Í���y�v
`��{v+����9�|I��c�������H�i��BR�gG|�\�%=2e�ܹ4&k��������MX�ZO����Oq�P(�E�d�4|H�%�=x�T��@e�ٽ�����"�tbk�*��#\��[D��v�\"|PRa$?�͜u�͋�^ܽ�W����k3 ��r�ZVa�����f7���cR]���?�tㄬbN?mG�>�d|���P���m���x&���0Da�ٓR/Nm5m�al�7����(G��D�꜑����2�4q�-����6�h2�E�Ģ$���e�p��x�Wy��>��(�cV3=S_i�nA]��ڔ�*ʗf�t�d@����Nj0Ha Չ� �*�mĮ��"�dc\M=q�k0�DF$>�y��F�r	��*:��'Pd���-r���"!V���^e�e�S���{��|��Dx���>tXD\_l�39/�^���.�i�P�Ӷ��5�klV�Z�6CZwL4��E�ɤ�)�J�ɪԼ0&�f� �rHG^�a��L>������O���|�ʷ�p��c<���v��8cm��Q���[��@��K3�]et<�TpD��Ѥ-x`5���oic�{�ͤ�눜�'n��Fu�����3�$�i���Qb�	��h�?e��Oq�� �q�'����*�}!xt悽�~��I@8���}��ɱ�oy�J�4 �р��wq���j�pP��Ԯ�÷z�2�?��+�axө������l�byt$�O}��pRf����cN����n)����!7�oz���dB�0�,ǚ�j뚢�#�i����L>�n�tBT}�l��G0`�p�GY;l����P�PC�Ř��i�씧�*���<�ݠc���<����!��m��~u�vG��
3�m=��D*�?֊��s>.�)�wZ��*]�F�jڜ���V��uc<�J�s1y#t���]��X:�JQ]ȸ���:��/zqf��=�J�P�Oq%.�!���ڋި�^3���ą�o��*��cX����io-܏ב�[�E���cNӐ�b��x����r�oK��(*�٬v/;�Cϕj����QH�I���>��>�l���KbF�'�`�Q��gH2%���9�ot�)�����Ҁ�#s�e��>�F�ٽܓ*bNG�<7�e7a2��~����B�ߐ]iz�Ql��˹*�����?�n��8��z�iW���ǚ/�R�i4�������s�`��D-J]��Jc%���3ۑF
�D�:ccV���;}S���2V
��p���z��kG�Xe�hw���3�$8�18��/�m�3[(x5�5���7�*��Kѯ'��5į�����d�E�B��&Z�Ȱ��"�������S��"�f1��U.���F�T?��T �LV)��tU�e�#����C~�|ڭ7t��6��Պ���:}��t�GL����v<����{`{�4ȓݾ��"d�l�][�{�8r�98h�o.q;:����J�X���?�����4e$�?V��	���t��h$�[4��������g��n2<+��j�*��v�x�לq��"�F��;72�M��#��������A�4̌e�J,�@�u�������	�~	k���8k���f��NJ�q�G�u%|1fȷ%T[���r�NRH��+���*�R�ϩs�vFmT��ot���0�{Ad�R(��*�m�~���ʣ��-�pդ`}\e�(��G�N��d�|�j���ѽ\��y8�vҧ������c�EdS�VJ������@�V���89�L+F��Zd�\�!��O������F���V�%���X������[�V|(�'�W/�v���X�D����� ��2�p�tOigg-\����v|�����K>�Y�~�_P� �������3J�,���^e����<&֦�0B�����)�{d����������rLW�@��(��v�2<=����Ơ�*	�%����c�aR�E_��.�.^�K�f靘�WJ�i]���U��7Se�^���b�$�a0���b+��W������1��H7�sT@�/���ѯ��{��Dok�xxT���!��<5��p�2�ufW�+��X9�]S��?�i`91q�{�IPFm_��h��A�����0RWK`����L`�9X�n�J���#�� FO��ˢ�6cAC'U�
C#��!z����|�%���@��|�麤�y%+:]J̵Qa�������X9�$�߻u�l�>�~3��6��j�s�|�Ӎǿ7&wg�Y���V�����;f���q1���j�}��r&Oz>W碕4皽�������'���Yw�� ��o�@�SL �[w��&-��M>�����h�v��^'w����
�f3�2V�ߏ��b&��{�����|���N���,M;�W[��i�gn3G��<�V#���b�ݑ�QR:=m[� ŋ����jkX�'�[�hż\(2,0�2ʣ��*�8�C�(ܶ]�i�>K媶���Z̝��s�!C�*{��<T���_��X��k�����fğ�h�Y�g�@���a!�Ln��}�h�t�jc�~����.�SM?���xG���H�<iD\�c�����;Ǳ�?��<�F�ټ�a �|T�eT뷥��Iاi-�/MS!�E�ͯ{:5�;���K4%�d ��ж����R&)^�����-P9�#-�HE��(x��#� �ZC�6R�A����YWI-�\�ત��@)�G�����l��#"��a\�էx��\�0�Kq"�,��g�a�[�E���$�O��x8�<�q5��$�5��6�oْ��S���B���j���SAl��C��`��~����3S�Mm����t�mŠ���R3$�Эl�[|���4O�D��M 篫��%�rd�=���I}Gi�E17�?B�?E$����B�d�$�×w�I�H^7m��a��1����O��#���c5�U�ٛ[+�����˞�${�NGV����,l&�	D������	V�e���ԲlU�bRh��2���������>��w��+5bZ/�H����>!�������Sψ?ױ��(WCY��1�Xڹ$ב��
��qQ>f&��z�թu�`�=�e��(*/���|�@NV=b����:1��~:}��+���W��6���&���y�ɫʥ-1�.��ȹ(��ɤ]�\�w��[��s�f"������3��P�
��B�YI�0�|���(��.�f�%�R�[�~�9;�s3>.�vg]��%&еG�z#_�9��u�o�?m���D.ɕgQ��/b.Ex���s\Y�	��"V��@�8h�c��@x���~v,��M���i�U�ff��9^�O)c��L#��oS��X=n�p�G�ɩwAD5�^~��*Yֽg!:Mw?���3���?�y_^dR�>�ќ\��[�[u�����/k��e��؉����v�t�3�f�����mOk�텮�[���s]I�昮y��|�T���y���7yf�T���~n�r�Ai��'i�
�ƺ��ٳ)ٸ�%%: �:6{��(-٧%ly�]\��D	m@�ⲅ�"�n�65�:���n娟��|%�j!�Ń cȋy�H�'o��(���fb��}��y]r�h �8������;�6AWغ��iB�_H��)�$�fS-<ֽÊ�7NBk{�(�s�����#,���y�`=���Р{�>�	��l��l�A�>�B[����D��\<�=nu?,eՋ���$ýgl��Y��NtF�V�\�)xŲ!�x�;�w��<�.9
�� ?(�΃^:C��SHj%sf���7���ı]�w6K��t�˲����b���A	�"?�<���r���u+Î�:CHĖ R��0�w�¿cȹe���'�˹>k��𹗐E���JD��:��6�Ђ���ϳ��3��7+�0%�/����;��>Hqlt'�*�br�&K��|�=��Gkꊍ�Erf��-��>�ȿ�:��ՊH
}� �*��v�a$�6���<M��aēx/��ɓ�Ug���:�`cԓ�nJ�v��� �IE\Q�S+߅6���L�ͅ^'��e���X��3�����~c��s�X~��9��v�J��o�$���K\��7bm�����X�v���H� F�=v��[X��T���jV��\�u\�,���DI-=�`jǥ-ǳ.J��i���r1MT,j� M��򓢍�@1�Xcw[u#�+� M�`����j�n���QSF�v>�G�f��l��Q��9+���C�A�)z2�3ڍ�k�V���2l����������{�Q_L`��y9�C�Ƞ�����'Y.�P�!%X_L�q�+o��%f��y�fӽ���аH�9}CUۼ+����;���>Z�X່o�O� �İ
:��%8)3@_*g������f�[5
p�X�K�<���&gW����Lx@��.l!N�X42�>M������� ��w�� 8 gc�^?����o�T�Ӈ�E����-w�t]U���cTՎǍI!NO#���Ig�~�ԃ ��_7-�pV��X|�OOL�o���B\��K��j"�d���P�_�;�.���v�b1���&с�%� ���-ޥ�kBy���˦�a�޷����&��M�\�@|Tѯׄ~����q|���C�6N%���BҵS��Wa��@�S��������U�Xʆ�=x�p����jKR�S� ?���Ug�8ScL�m�;<���Q&X�$����	����4��_�>%��\߹�q�������9*��Ƈ;ɴn��}	����j�{�T���Ka����&�h�w����@��ak/:2���5Z�x_PR��yiԃ�:l�ܹrV�������=�������«;�%�A�͵�ϡ�O5��?8Yfr?�� ;�b|`>����T�6�u��@Z�%�vE������3��#��HG�*����=��x�-	XIdJ�6;a�Ks�+�I���P���OY��U�N0�g^�W7�ۃ�Ͼ��X�WRLy,{#��DB�Ԕ��#�6����������j���p��^�Au��`�]%7-������b�͗��"PU��g��(�l���go8�J�@2�6��̌tO��x���9:�Fٶ��Xa�q0-;Dv6Y��j+N*��LwA��(tT��p�ݞ����f�}Mi�[A��D�Yp�ܮI���ܖ�����!�vU2Q�d�ߕ������������؆#d�G���脀�)9�Nܣ�D��y1\>/��']d�&�8@.�	��k1��A:����ߥ�!�A�'���b{�.R7q(?�(T�5�FErw���U����؏n�Z2�sD������t�x���I%Nil�P��u�WO��_�A��g�j̰1'vUT�\o$1-��I#������VM����ڈ��qd$d��L�D;o
���^��s�����Y�.}�*��6�e�<'�tCT�	ڔ��h�ӑpk�E+Y�XZ�~D3~w���#2�����i~�{$X:��5"���x2��$scJqp�bF(<�����
����]6
���q��Y�L���˳�N�Cët����%:�cc��E��9�� �xB�L�Q3Gl�p���#l">���g�	k�9�,t O@s_�S������,
��i�d�!�����Y�J�h�y�Ȍ�?�	\4�x�,")@�Kj�m�*r���\�QB����i�͜�(�fn>r٢��97tp��o	�S	2�&��D_3tڠ�#����U�9AaeLc�,YLqlG� 3gǊ�����MGu]s�0g�7�]|����>��t�y��Z��C�6��jn
���:�b��� �6,��{�g���)\C���C������^Z�5���:mq��B��j.�����?o�}%����J	1�J�H~�uբA�ʹ��+c�����sH��cC-6K���
3��g��o������
�{?��څ>7d�X$��k_�����w�ʼI�&�H�JuP,o�,���|u�90��I8*�s��2Jy��h08ê��ƾ$�����)��k���ߠ'���C��{�~�N+����-d�>E=�����J�K��j>5c��h��ɋ�B韬�-�1��h��>��!��HL,$&skMr�o�#���X٥���j-A����˝j�h�!k/�������	�Z$�~�{"���B��-*
��'J�(6-�X�	!n.$�9���y��eJ)���s��ϒ�bE55�.Ȳ��u����}��@A��~FB5�\uf���+�$�*n�����T�'R���ջɶ�X�t�E�[$��7�Tw4��+M+6�TUyl�|�O��ryW^��+Z�*�� &N�!���V�#�D��i���#}�A�ۘ��ր�Igx�K&��"pR��G���t��V�B��~��i����� 7���b1`E�]Nh�>����MۏMc�ܥ��>� '�V��#�]��5g�\p!�e�W �!c�?J�I�O�N�����hѥ�SLT�H��B�
���I;��2̇抖��j���n��k��dl�f�	Y|m��@��J8���Y09��>i�Po��r~�(@�f�UW�?R4���ǲ���:�Ci�$f��{���:�g����FU�P9�N W9��T'��l"G@�kqkQ2G�A�ޟ�I������&F�/���I'�	�M:C��Z�����ǆJP\M /+H�Q����!U���N�~�?�8��� �J�=�6��mh�n�N�5����I�Ϟ�~�jD��ź˚	S�_¾��@�E���zY����i�H
\���q�ym���_�j3�x��7� �A�`o���~���T�k���	N���I��n�T��,����w�� ��"ˣ�Az���vZQ���u)X�)�� m��R� ȷ������g�    YZ