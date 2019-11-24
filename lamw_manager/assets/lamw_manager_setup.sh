#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1137862967"
MD5="fe403e5a92c54872bead549af5236eeb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20452"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 18:48:12 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=124
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� ���]�<�v�8�y�M�O�tS�|K�=�YE�ulK+�Iz�J�d��!H�n��_���|�|B~l� ^@���twfv6z�D�P(��u���i����~7��4���󨹵����lgsk�Q����z���<����f@�#�t��;����?��뎹�/Lל������[�;������yD_���T��'��OLv�T�?�SU�g����-ӢdF-���'f董�c�#OZ���l(ն���Ԧ���#�R�����F}���T`�i6�掾�h�-�M�jtN�*K�JlF|3�7#!�N�������k������`����}���p�lDɩ�s��pR�W��t����58j�4�b�'G�q�t8j+$����ޠc�i�ٰ3��鴳�:���`<�;o���������/�*E�Pc�at6`�zD�z;�����|�m�b��[�������Zq-*y��;�*�r�q��0���X�q�{�6g'��ef+�Y\�.!\a � �@�5So��\��S�5
��C��y�;�mQ�@ӈ.�Cۡ���Q*	��p��y���sg�+d	�A�aU�0a��N/`����س��Ȃ.&�9
8c4�!�Jej�D��T�^䓿�y@}1,�-��Dt�.u7r���ڟ�7i$�	����]S���܇�9g|Z�^�Àt6�A#0��(�<�]˨m�O�=�!�5�E�% j9E���4�6�s�����~K� � �гL�!#�p f̆�`���+���;�B�3�eN��N��lA��3H3ӄʪ���D�R�����9 �o�����	7 ie;�;5�H����=M�J��ڟ���������������SB�%9��ǭ_�Z���i��^���e����'�Jj9�Vd/&?��U��`w	��CR������V��׉���):!-�W�WK)��5J�T2IH� S��7Ų�)����cb��*����2�����T2M�V�:�'Q�&ʜ���[�Lfg��pEV*�	�p�a9|+j�ƒG_?���¡������Z��*����������B����Y�k��%>/�K�I�9���T�����ڜGh��+Je�8~�C��cӵ`|%�Z��oA��O�R诊�����
��@�ߓ�777����l~�����Z%��!9�w|C��;i����Bڽ����٠s@&��(	FzY����@�E�(�0��QXp�=����B&	�O@�e�l�I �a|܄�ca=_X��}3`"���bAx�׃�U��8�'�&F[Ա6���&�;ׅyAuf����,�`@�5������y�lOדau�ӿLQA��rV�N{�A>C�ʑ�W��2ў�	������L��t(p�N�i�a?���y�ES�V?�Z�/i�y��_���l�~�����b�U�D�cѠ�ο`�������_�����g�����ֺ�Q�x���������vp �Ȝ�4�a	 D�]��xT��,���Z����m��\+�l�9v�jѐNCb܁����#3�q�e�#�6�z��e����lsiS^�4^
��m�;W���Mqm�g���$�یE���p���)��V��g��#����>�����ϱK/�;!�e��}>��v�+r1i��𑔙S%%����Uo�y<g��1,�P���-��,��A�Խ`�M:pQ�9��P@<�7�U�X�����~k��P���cOp ��J`�ãy '�>�͋(��Nk�1�;'~���S#^���k�H5�:�������%m߹$����$Y���c�4E���ʺ���HAi�ʋ�a��S�?��@���K����ě��?�4
3��.y��hA�������?{��+On� 7���l�E�h��ů�t9Hj�%�^�^��Ϙ*^�+鮄��%�K�M���==Gn/.@U4�F\)Wk�A*1������c.rT[7���z�2�_�*�x���ɸ�B�K+$���BY��$<B'�Ӎg�/Ij�G8
��9�r Y�6�m�AM�ƫp����o�iOos�㣘�/�~|d�}�=={3~�;�p�`�&D��<�tH���NG��[nKf���{U}��UKV�
b���\ެ.��m�r]�B- �*zJX�Ҕ'9s�� ������q/���\�@^�X� ń�+�sljc��
���t�4;�_Y��-R)Yw���2��W<�4XN�?��2i��ƣ��32L�����P5q��c��i���H{�`��W�ZDk�^�_m�$���s�}c��T�|�1�R(��%U�Jv'A��٠��4�ȁ5C�ZQ���IB>�j�	K�~_�J���?���>��<��q�x�L{ѻ=4���C@ˤ��d��ݜ�'��[��eC�[��%�����J�_�������r����/c�*�|f_yY�3��C�V�A�� QI�.�B+���n���CY�vK�� =0��%��׎�+�^F�]��~��hR��G�9�	���nʽ���m§r��iۇ$߳u���ɞ����9���m"w�&�����6����s��a`�\ْt�/4��(@H%noKm�U��������F�uz0�uƱ�<�8�OB��l��KԠ�'�.�&q	��s��yx^1#$�/�mILaU�<�+���e�JeHQL���S�q:����|�Զ_&	��Z�_zI�@R�A����{��k��	��V������7A�F-\��V������Z���m|��������үf:�w������7�H����|�e�ġ����Ao�b�.����Z��e�]R,``����3�0���T�J���Z�%u<�����A�7c���@������K9�X\ f��9 ���t8����E�RO�̫Lk�@oM����{w��{��yF	�)�{~\I�������C� 6���wf�%�&!~`��<�=�2uNC��D���F���m��������W�Ӄ��'�;�t����G��Y�P}'�^������A�F�(�Gx�9�P�,}��Ŕ�y��h��k�H^���i1�r�X�4��F��CN������c���䮨�*��\�3�|��h+G}3<7�,5/�U��T�.�E��<��πlQ5NWc��1h��iR��CX;�5B�� A��Z4�)J��)�鍕���o�#�ݤ�����C��*��Z��!���ch�:�,^�m� c�1���:�xC�xP�z��0�;z9Q��u?�h�B]t�*C\�Tk�Q~k��Ry=�x�圆�?y���3���X�(]�P-��P��^E�BR���`D�a*�u��v���E�L�$!z�x��D��+�F�I�@jrf}�숂LMp�BsAqa���5�~03=���C��B�7��$��D��S	I��q��eY `}�9z��C��M�X�/Z�câ�Ơ$�*�b����h�T�>�qR�]��W;��;9��c�W��BL�׈>wL�w"yg@"%�@}�A<�E$`���Z�Y�J��R�wY
K�-�u�W��B�y~�J썑N�&?�������G#qӐYˑ܃�lwdBРh�Ay����}'n�K��\FS)laB^]���	��@�j��@#�!]�8�s�I��0�q������|�3z��(�^�惙�G,2�# �����ԋH�R#y2|+3��d�.]�'���Ѩ�:���m1$�W-T be� ws�ƎOT�Ƣ<��B#"���c��5vς�����bo'V�=��iΆ�����0�I!e-�T1Μ5��)����T��:㵬��D�ʰz/�
�!<�����hq�nB^�'$"IT�w7�$��<���h����T%�}��v���` 7��C��K����o��p/�I���ظ�bO��u�!�ȝs�L�%Px;b:��]�(��7��6���KU+�roJlĤ\e��4�S��%����Bz�W��OOԮ;��pOUQ��8h�X�M�ɥ\0ߜҘ��{��C�;\\�%�hesŬ1c���s��=/�М��8{�c)k3j�1��([���;c�i���`�9�����J<=��H��)_�I��P�icd��C��xx���#�QR�Nr���$�՞��t`D�E8HC�ba>��5���XK���U8퍺����n���!|���s�/љ	�#e���]/[Y��
����ϋԆ��oYN�^���)�?cq�\��-�l@tL�ea6��nD0j������@[��r�+�M�w���(�:�2���\���00r����{|�؅(2�|)���@���꾨�Һ˃G�ysvۢ�"�|ag��h&|y��]�SsA�lK�����b�#��+:�����M�@�fp���J�I���g��(��`p�NJPw�.+��u������� �:4�q#,l�t��	&��}j��}���I�������0��*�4�C�#�F/��κ�k{\�v���Oڎ�X��'�����^���&���xa�X�Ȱ&��By��b�C����|K@K	�*m���E�g�Y&u�k�ʗ�l��Q[��u �J�GpX��;�y&��lهL�zo��򠣝�R��sR����l��sb��^�ND�:0�?����Z��j�_�6�����&l���tN���Q�$I�Ku
��s��wW�lt��0�.��������� �Ûڦ��t��uN�>w��wKM�Zg�,��?h�ȶ(j��B�U�K�-�$�~.�:���L���N71ԯ�'Y�8[��/ˏ�< E:4fs6��o2;xƽ�_B**�Rw�=��D);�'����$ �,,k�}�DJ�Li�ŉ��{�5λ[C��%�+�h(S�?(�ɵ}D�J��e�� eQ�W�ì��:�d	�>�K3�\��$��a�бS�����ӟ!������u��bR�i��vՍ���A�j���io�r�*�>N��L����,Iƛn(P�� ��T�����:�z
��4��X�ڇ�?��R�O����c���=Q� ���J@��s	l�&O}!��V]� В�}9q�[��� ��2���<E�"�Sz��Js,���שƬ����@0�����Q���8~d��V�s��p��y_�!�3��O�?���0� >_TK�@�!����������24�3:�kk�y[��5�%"?�'f3���-�pHCc3N������g���Iv?>@1�~e�|?��I4O�UcGZ�Y���߸S�U'
]qqz�����Pu��)�=P<C!�L���to �G�5W�k�ΔZ<�x���3y��*�ͺ�:6�A�Z�TR-�~���D-a�*�r7��%�\�nDbո�Q��䫄I�M�r�R�"���*�դ�
�n���Z���%̩a|��O�P>�1L��_z�����6�,�ye��Tc�Z @�Ң�J�d�y����t �@�*��(Ѳ��L�þ��>�>��؞KfVfU Ҵ��CDH�~9�y��9�If��ߡ�y�"�6�k� �Jݝ~]�R�(���7�=�]ͻ�|��/fD�Z��_�ก�	G ��%���U�S�;rJ��Z�VzT
�Q1Ӆc࿆F��#��`I�Y|������*u#W\���;�1,��џQ&�����^��, W1p�>Y*�e4ULc�r9�Þ�3U����Ɯ��E�*����Q��9��ܮb0�͊�'�d�\����`�Z�/�+g:*;󲺺Q��Fh|c�ʂ�V��U�2�\%4�4�ݍ����X����j.Ѣ��gN�9�_7����kV��C�e3
��P�Q�:&�	唪I�:�Q����xQ#}�Ef���ʸYݬ��9��b�&}�)�|����"��A%��'��ƴ0�y���H��l��N�5H>�k����N�ް�_	��cF,�<L���*鍫���G��D~��e#��+�����o�܅^��j0J�����1�o����:����ɏ������_�4�8XZ�������\��=��d�8��d �:��T�?��{�K��n��>��,����)���d<�)��}80��J��'[�|E���A�O_�A�P(�4+��HL}S����"��B<�'�s}�l�I?���Y6�߈J�+°�7��s�'��D�Q�^=�b<$�@J�\�W�7�t:1F��v"-^�'�̒���<�hɌ�Zx��^��6�̂a��4k$�b��/H�+2���mAg*-F���y�~30j�wiK<�ݿX� ��T����r��(F��������[tQ�tV#Q�S�U}�t%�lU�g4P��|���Z/�_�IK���BM͑y�|Ϊ�J��񠯸	|�I�"=�S]��<@d8 �i�7�g}=�&H�>)n^"�o���>��w3�8 G���i��n�l�F��Wq�U�F��6��֓SP)V�(����!��Ւ����6�*�F�ˈ�s�sw~k0Q��r[-뤩�3$E5�̈�9�<�*���O��x�X '�e�����4i��=��N�y�e6����ӑ��)����/5������S��"I ��4������Є��x���ƻ���M4�]+$��r�T�;_|�ߨdŒ����P���ѥ��X�Q:M�g�>k�!`��n����z�N/7��]�E������aL�+ ��d']���|+yy��������D���<��<Ho9��h�<�
v17�A,����,�=�u��v���pQ�}��ŉi�'���^�S;��yŬ�!!P�h�ՙ��:����÷�┞�3���]�V<{�9&=��8o��Z��Ӆ��ԕ�[ɧZ�s���?����vV+�bj�K���I>붻D2�߆�����mu�0:���&G�ő28�oot7�FYk#�=��}ct>���E�A���6B��+m����>J�e&��I5g�u��3m�?W�:�l��N���gY��_�M������R�a"v�b����0��Cor��]R5����S*���IY$�].r)��c�_��nߏ���_ۃ��m��?)?����6;f:Q�0ŷ?wԍ�"�����v4DI^����+ �aĽ,Gr>�g�T�*;��$lh�S[qkh���ke@�7[Wp�ap������1y�7���m�A�[)�6{*�s��J%.�>�LH������_҂������b5%�j5����U�^�_+?\_�D�#_@Q1���^  ���F.�.	f��0�/�Ջm\WV��%S}Ko1��?�+
��NH׌H�OH��u�{�56�B' ]:�k{[UD%񾳨49�����ʎ�B�RVE�/����U��P�*�ǘ��L��⌸Y������te��~8�����D�ce��׫>� z�>l2M���M��Ǘ�����ʋ��*��#T�?"�b��}�ϵ�xu�1~��ލ�a�`njR9M�ͯ��/˒"D�Q0uYE{V��E��F�zQ�}15ݲc$�F��W�<�Y���r�r��6���ZG�����@6�d ���B���,;�\��9a�ϸ���:�¦�1?�;xV^�y�6����uA嬔����|U3�k�+�����]�fq�5!-`�-p���XX�1�#s�
1��Tn#W���I��gL�g�S�'��5�� d�a�,�x�����4���t��%�'��֩إ�?^�
F��CND�[�|�w0���#+[u������ꍭǛ9�_�������]��oպ���@��|�Fc��v{ ���H��s.�4��6ruw�A�.��{^>(��$��2o^���ѫ�}��N{��;\���`�ɧ�R�m���j�W����ۛ��v~��n�q��m�q��Wp����[:�����w"����
HVW��ZeR�-+��_O�u[i8#��fB���O��;�#�w�Aזģ��C7W�ao l����c��bH�v�+��D�����b�H:�&��>��9��{��9�/��(q ��A�Nm��ۈ�bn�@������Z{\`�l��3_��ab�i?��W/9�n	:�rE[~�F7���G�5�C����u�6��|<lfJTNe��2�t�༕��٨/Ʊ���^�8<�Q� ��zxt�Zu��=d~����g�烽�`vrU"��Ҝ�����
��[]0�g���W����o�y��1x)�/�C	�~�H����G�G��і=����.�\+�u�TG���T���׽DF��"�� �P��B�'h����2�h FQYL{���I]{�Q��}Ί_�֕�?��Z�V��Mz�o���c��(�Rb�M>�a�%�}P�i��׍��X��`�!��y�?�`0�58��>�f�UiT��G���䁄����M���$M*�~���v�;���_�T93��&*����`�BC���Y�3U�9I�h�sA�$C�
��j�,�\�L�I�C��5��D���:A��X����2Ʀ�~�n�%�R3g�N�J��E-Eb�����>�T�W¤�U�3D��� �M��-�C�h	�Ң� �C��k3�=i��u5��m�[�`XQi(�V���M*{c*�-X˶J%u\x���5�p�Z/�m+�w&
�f�L��z����>2������hϤ���I��x�\��;Poa���ͯ�o���0�y�{��T/�p�87�IV��99�\ou�ĔcL�I�\~$2��)�Ϳ��r[�H��E���O�y�r�l�vZS2�{����V�we[< %~�D� ͈��V��K	T|��g����f]�Y�Ϥ�nf����ca�S���hMm�YVT%rq��k��L|W#`��vcpCz�Ճ�����d�2V�������������=O� ��� m�u�P	�U�r���cu�'DL��ͦ�7	cF�40Ƥ�y��@WD���˓x6"�[�8� �qtS~&g�\�`}W�U$��_5`���3�.ԗr�19��;��C�����;�e85VG=砎HS�y�b]اx�?1|��Jͼ'*������0�XQ�i�B�ȅ�+i�g��	z�A��Q8%��O?��y�~ N�k����qoe����,����!I���mK)�d��+��˟0�	o�-q���*�0�[�w8�"d�1�2�x�U]��(a�!�p��wA4%G�:�꯬`]uz�3�Ss�x�Iጃ%�I�}>C*z@&�T�*�@*�w��23,y�
�a=���*���0B�G���
��e�P~�c%���=珼�l�d�0����8y�;��f�/r�����2�_6Y�ߛ�7������[��Ҽ[R���^^+_ߖ+oY�v��7���_ȳwi���*f4s	�M"Ɏ��o���+����.��4ݘ���b���%�#k%��gq���l�x��g@�B��uz�e���J|��B2��6����/�4�Ε?9���b�Φ���h�f�y�]��v��I�~��l"Z�e�qK���[��Q���R� Q�B(R�)0	-�:����a¿-䵞[��X"�RJ�JWSH��0z��j?=�/p�j����kZ(�H�eo����L�dY��$�Ȧ7w�;�'��4�+�)�`~��L��,a���GӍ��m��*�v���C/@ZnI�}�f�B��Өã���=^�2F�I�Ս�r�dh��
�)1�!�a�x���Y������_X���<�k8ʫ�Y�$荧�K���ȓRsM��������u}]����ڳϥSl5�81�/$��0�h�TAТ9U���@���u���+WP$�i�"& JȈ�<귒��Xh�0�V*E��D��/� �H�q�_�{�[$����h�y��yIP:�n�AT�*�;�'�����޷-�K�8L���P��ĚC��P��:�jViѿ��D|�Ρ*�l�%����hMq��Vr�ғE�8!q�����fu��a�X0���n��w��N�z�:�(v��(��oԎ&��O���Y������!��j� W�U��t:��}�Ʈ��3+ZQ2�������^��gJ�%���Gb�Ё�)���s/����͆�m�U��IG�[!�2��|���I&K���i'U�0H_�>1����9�@@����B������jy��9�����7d�\�b967��н�m$��!#��G�c��Q���lx�|�^Ԯ�B�L� u�W��:x��_�}��7B��]ZV���`<E|: ��M���C��ӑg�bt<$pѼ�}�'� }r��˿cE8��mǠ\s�ȭ̄�fc8|�Zzw0M�x��$�N�2�ŗ�^��<�SO,NX�?��Q�6I8�S��L���"���P<�]�B#!=��w]�%|��s{�ܿ�p] I�'���T
���.�`���D���	��(3�'�K>D�XBz!>T�K��N~�HnA�d��%�=R��l�#L~6�LǓ	�R{��R�'�
��� �#�i��6:��i2]�,@����/V"K`�Q�LM,�R�m��7tK�$��X�~8I<�c7�G4��$�H�li:�4Wk�?.k�8�I�Y�2{ٶ>�I������䂳b�73GΚ�~h�C�� ��*I0.�^$�@ϱի�͘�V�@GZo���c����J������_��dK���!��𹖦R7&y97U����|�$;4^sQ&Y�l�������d t�f�=�af��n��<4����;,���{rgr�\��,�:��{�:�F�o�6��������UdKXE�E��+6����#:�0��ㄬ���'p��g�M�9�R����.A��o�r_:���
��*Ѐ���r�b���Q6�i{���u���kVm��b�Fvi��*�H�A��u ������a�Ձ�m���r�W�Je��QB��h�%����_�G7�t��r�t��Zvw޶����F���:/h���~Ac�_]lQ_�d��7�膤�5������:��98�VGťUs�VS�+I����Lў������pj
2QV��ex���̌�̌������WBDA����
ehf�v���C�0Jq�i��[;�V�J0� �NmD������r����(Q�A�c@���M���f������v���q�[�]�f��d�ʷ/m*8��qt��o|��X�0��J��L�o�����Iת�V�Z��x�Lc,S�p��L9���9v���~S ;���"���.�*;�HL�ID)e�P�3��ԓ/��a�m�_$� Á�dh�!���d\.#t��5�7 ��W�"d_P��Yj3OU­��h0֍��aYx��"�'/o�9�g�sc|�%�
/���g��P�+���-�{v�k�9E��`�3�<�_�����,�-O�|/E�� %�Fx������
��|�[4�e�(��0vU�*�]�n�*yO�����Fӓ8����3�T�K�MeE�r4J%|/��f�m�W�	]Հ��x`ԋ��J�K�Z-�֪Uo��6�捦t��P�c�I¡��s�4%��1*�&3dh<�|���C��D��C5��`���$;�ݽ��֟��$P5$��J*����+C鶆�`���':�G�ޘ75AL���	�����k!�>�"l��N[�蹪�d���ǫ�\L�&�~f�V���YQ����ܼ���#fz�7hQ��'�F/5*��6���~4x�s:���rb��=:���d���P6�{ǒo�5���O��J���L|f]�y(w�Y��3c����mGX�<���5��n��
)�Fm�)�l�'J���܄=qRHC�9���qe�ΞRf�IT�*���v��v��:�%��Q���]b9�{�|�4au^�~����mPg�mq5E^�y1�)��	��r�U>)��tM�>g�/s��)��Fe��k�f-_�Hv���s����ڨ>�]��H]������rV��R(�5��q�`q�|"uey��W�9w����3������i@Q����oK���aW��)�Z]�{S6,eg�m
Irp�����<BΗҥ.Ͻ�k�6�,�"=d�H`�ӊ��o^R���]0��2��a��+?�xK�D�G�&��eg��VAq��H��"k�¡*.���Y�K@6������0S�n�e��Wyf	oQs���z��C��ү���aGv�����ﱯ���A?�����+����Zb�k�XlD#���u�f#|�$O�e9��#^���K�Ï�q&5���.�v�E_l�u'>A�;s��`�HσEUXiŢ�A�>�v�q]�/�!����
jZ--�b����=v��X�hq��w���:�¹���cR��7z�xe^[8)R�y]v�m8MM�-o$M?�+��U���Rb<x��2H2���'�!-IF���\ކ�dHY��kD����I����赮2�Z��
�Xع�)�J��s���M��v�����T���V�J�����pD1l��)���H�7W����/c�4ֺ�ؼ�_0F�ҙ�z��j��1;��xo��6���R ��q.�h4�&���y�9�PY�P���F��9�G�!���ɿ	=0V��̲⢤[��eɘ.�=3��rܔ=�݁��02�M��_E�]�ͅ�
܁�F�h����i1O�B�5��v
���f]�mXW�+;9d� ט����a�S	����:	b4�wY0h]e�%�}Y�/���E�$���H�8&r��g�<-0���'myHY�P��hS����uQ2��	� ˗_�%ނ�VA�K���ty�Z-�*_���CG^^�M9&`Oج ֗�
BF�̨N*̪1�,���hDq�M�8�^����D�E�~���Bc�C�Bd��#!���O�$1Uo)�,�_(T�
��8��A:v�r.$�m�X)º��x" �뀌X��hk<bGB���N'�2�4wI�0��:�ju�*Q��� ���ce��hx]�c�_)S��Ԧj������,O�����{�}D��`
k
G���#kG!�'�`W~�M ��H'�3m:�*M�D�!���ݍ�F�L-�꒹E	��6�9a��s��le�r��l����ݨ~.fu��3�����m�?ʥ���l��	,,3A���w$:�r�!.[B����G��M�ͧ�$2��Y��8�3�3+��IL�2�r��K��pw&4��$3�Ng��L[�5�Q^)]A۝��&{��b��++������|�|��	����.�9=Q��;�����~x��E�gq|)�dSM��0]i����,�m*X��M,b$mm+�� ��7f���r#T&Մ9��������?='�܇�>�Z_�=���ۙ�b~38��`%��V�i��sbw�]Y�Xj���U�Pr���@b�����G�]l������p��R:����\ȉ!�a8��f�$k`k^�jI��f��;8q~����5'{`\�o�"[��|M����r���X�Q/5�Ǘ�=
��8^70XVUBZ�fq6�����H.�)�����X��
X�g�7SW��fS�������{'ݝ�'PF��h�W�R {t�8��r-����_�f�ۈ�^�kXJ��M��.�qc����<��X@4����1"А8���@�X�#�)��}����r�Ȣp[o� �C3��c�:����$}�c��`��˞������/+�� K���Q�W*0E�\�D)#1tIE	���(@Ezr,�
�ȏq���>�uV��*ڙl�;}l'��'����9�2ǜWp�9�ܱ2Ou/]D��d�Z��˝2�3������L��o��������}+���޸������)�_����ŏ�}�Q��	���V=`�.�+�>T���`̺v��z��pϪu��O�k��M�,{<�@{��5(��* #ߩ羴=k�B�Oz��L��J �*��G�����_�cD�����w;������n��0E�a]$�p�g�H �nR.�6-�V�`�}�T� ��0�&8���2�<:��	��Y4���P�`��B00��V���jl\�*����4Б�!.�7�hH��|�ʍrTk7���z���T���d�|a��F���8���u���~��c�דw!:eM)}IX�Ib�W��g�|�o����^h�+o*I/E�^!8�9o4镐������>".�8�>6N��H�����d�Z�_-�����5�գ���E3Mv�U�^#%	 yx��v�g��T��{�� E����J��;{�Gb���^��œ�.W���w`�>�T��U��������s��v�����ሗr*3F��9�&>-�L�w���8k�
Ї���٦l��Ŧ��6=��?�1Y���(����(�����Rz����@��c��l�PB����a�)!q����Ɩ�?��"�e#��� �"��T:4A��{�>"9�m��#D�U�V_IE=�V�|�4B�b�3�vf�L�ߠXי��t\���V�.�EJ�O�z,�8P�Z`�!���oN��a]~�_"SW�A�{(�9:>��iQͭ�C`#�b|��rVT/�)_hMKƯ{.��,F�ڛ���p
��'�f��x�9o��[�%^oGϢ������֮dK�������?<a�%lKM���h�\�d�q�ٹ��fmQ*�#BI2��,��ٓ\��,鶙�9ڼ"��wa=�֫u��XH�ӎ9��g�^	y;�&�L&2o��T7p��I�
����SL��=Y�³��%XI��ʢU��{��Kϡ�kj�nϳ��ܜ	��6���ՅU��K��"K���lP?����\eQ�^:���N�ڑ�U��Ȭ�FA����ݣ9Ci:�{�e4}7;�����$n<��ArZy��N��oy��jzȼ5m ;]wo��R��8����>Wx_I���� ���Y�?�D���������ǰ7E���.9c��'���}�3Y�CZ-���ux��;iX��l�}�LHz!�QT8���1�_rj��U���c��w��*G�z��5��@ۭ3?l�h��+�ciO�@]ǭzD@J_�8�<�D��豈ĀQ�G�Qϑ����a�V�)�pm�~���L� 8:n�57�J�#�����<���n��S�r�7��a0ЅI�t�Ԟ"��#G�3&�3F=��.c�l�9����#[xG��	�ٓlt�W^+�T��Y��Uk�Ϣ��>1"�����D�VW���H�����>G�"�r�Q���I=7$�1�W��E�� �hP!�&�Z��I-�\��ǔC]�]\Z���g<\Hu��iF^���;5���j4̀z��Xw��gK�ɤ���P�>�R�ϳ�Z��V��:��N�@�FL�c��1Y�u �R���O����G��Rv\t����&�>����.�QA�z<�z�B]N�ۭ7{n�uyu�+M����-�6�=[�}�q�#8ÚU*|b�9�DS�~�2���PB�S��Q�v���DqH��&�	�2���;v��(��dw��}��w�d�3M��j�o�^�$�C�'!���j�Eo�I��޽��Ʊ�n�m�Y|����ݣ�yߵ�[�c�%m��"��蒝�D�)>��������c�^�W��_N��f���c}<�]�� �����帞�~�&S�=��7b.��*�&<7.��f���}/En��p4C`=��ίX>-���P��G����@<FŘ�� ����{�?����nB�Ke�s�4�m�$�_hDe28�!TH!��_��sH�uwH����G�/��Q�������y��cn%#-q���D���N��ľ�ك���B�)r��
	�Sm��vI���(D��w�l ��P
#�|��yT٪��6�C$��R�$�B�)vN����-hf�s'�hY���g���E]4��g��<�w�,Y�^v�n�6iJͩ=@^hl�.d[H�<Fp_�}?�;�&r}���2e�+Cs$\n_�vM��2y�U�� ���۞�C��l5�;_�n�|
�{F�j�U�BẽݜdS�?��>�Cϔ�+�ʩ����.`j��(���A�-f�&�����A�7��l�_�Սآ;^��E�G[�z���6\��ߥ5��ϭi��Y�ݽ��� �B�&�����X�<c��h||�/D�V��t��a����AB&?���������x���
�̧	�c���4�]oZ�܏rx@�vh�W:�Q���T-�>q�M���su�g#��z���o���:C�������q�L�V5U{��]�A��s=�e@:�fWA4�gx��,���֐�����������Ԩ%�gͦ�Zڤebc$(p���U(��)�����x<��-n=.�d�Ag�J�Eb�E@�������ZɶE�V���ܺaz9~}�91RK�1}xz���.�$@�)X���,��g�F���ZW��[����l���p<�:t������xu��N���|�m���|
a�,!%��v*�HDRg%J��F��)C��M�\ �������Lقڿ^��i�ZVj.wқW=���^��]�۲��������O9��{��{��E��V 4H�v:�l֒H�*��wR1'��/���/��i��h�t���޺1/�Saܿfw���=�/��+��K�/���G�u�qF�ɣ��x�ԗ����J��W�e󒄁峲B�Եd1G�/~�y&~n{�Q{�&M�W�_�Q�l�B��"��e��"h��4��EiC�P஬���y��3�q҅(mR��rH��ł���&�����[��@�SB��N�s�#�Օ�i�,q���퇨��G�����g�A�������CR�E�ZvZi�.*�c��Fl�a��D���)�_3� %�D|�4�����F�Ĉ�[ɡ�|,�e�Bˏ���/�l���u����rvm�zl�'�U+��Uu3%��a�,@�4����S&ֆ�P�(��A�����E�</+���d3�7M<U���d���D�0Zݜ�R�0����2^�D%��[Rg�		�Q"��Ų�}7���/����l�����{	5����$��� T#��Ҧ*0]'Z����"��(��A�K���-g?��TV�+%��IS���钗J�u�~mo����Z�x���&�Y.C4|��zy����x�5lGa'о���I��Z�����k��5�602�S�����𝿮���Peh����H�����5Q$T��M��6���4�D�pV��#�����<�����{�<�g��N����>ծ�dw�.��h��A�zNؗ_54����TT 7�T��/���(N�K��W0%|YI��P��ZpR!���s�	0Oɼ\�Xn̦�"aC9^�2p9�z����j�TE�E1�x�#�Ot˫�Es�O� ^�>Y�/T`�~�����I'�u��?i8����"2d;(�0��Fە�>��E�����HOl���Cl���;�&*�[��V-L��¯S�����[���f�Ŝ�(?v[�����`��q���)���z�x�N���]�ă�|�&���;ך|Зz(��2j���}�c����h)楇�8~�Y�z�6P����c���)�����d��2�`��W��1�rC��D�I�	w�N�]�¦��I�t�1�ŕ�"��$��I f#�O�9Ӑ�1����ȓ�����ޗ�@��"(���4f	��mK+�a{X_?PM�"�S9�#����^d''d���X��2����E#�B�~%WO5��iI�n���Pv/un����s;�{v}��%�-R[..�l�>C-:	S:��3k%dNE>�l�-V'?@^a~Hy��������Н��ۏٍ)/�g��`P��5�%����^Z���:��:-�$ԴyK$�h�K����Gt�p�蒣�����l��iJ7��^{��Arʡ��|��^��Q�T���J]��X��}RH2|hoĚ��A�aGQP!^1W��ʗ�&A������ǽ���ֱ �?���z���������Á^�=��S|����/:���×��͍�z��w��������������3�늅1T=�چy&||V;�KQ�B��;�O��J5�;�e�{����p��ٺ4g:�t���,��ã��^ǳ[s{
f����ˊ�.�?�O8v�gc�e��\��i�\J�ɂ��o�3+ʪoW�Ug�3f�!�Z���
6.$V8�_QW`�v[���=j�g!y�����>�F���� z���G8�\6�+RV��~�f1����0m*+�:+Z��Ԇ�\E|�б�r|��x	���������2C)ĊN-2�ir��, �|�;3�\AU����1�LfM�-P�4��|��	�\ʩ=��<��Adj=Ҁ�8^�M�r�����e��jRV��������X�N��m�B�.uMjй�C����
�$k^r�4a��F�0lA���4�`t-Ȱ^J|3Kt�(�������+��un=����
�;׺B����Li�V棎A`��c���� ��Z�6�u��pW���#� �ീ2)P��"A0p��vz��Q��B��)�;�����x
W����{޿��{������ ��Iu����[[Or��=��������LU���ވ5԰w��S$p>�M�(� .�`J�px
�sH=Uϻ"�<�v�^8<�G����L��䥷�"��������w��/j�����ʋA�R���p�"�ы�82ց�v*v����P�	�{��՟�P�Pϴ��x.^�×�&��I5y��1V��t���1�����a��91ӿ��QΧ�ql�f x�TR5�J��2x#`O:�	@��j~N|��$�i��z}�����F#����ޟ[�@H��.������=*P�8.�*)7o��0��i�<��3Q_y��g�D2(�f�x/j@<L]��60�N�Dc�Y���AJ��}s�r�����nA��J�n�EH����D�++g�r�`,*3�_�7�hAi%$�����\�=���!��`K(5�)pZC�=(4[�h�&�8���$�^�v��E]0�X9\c2z�\�H�` K����֍���B1kԊu�}<#o��&�DI�4}������ �+�	�N���iM����Am�|&�5��T����_�2L��������/ɀ����T[�MY}s��Ѧq6'�5ϔ���B��;b_���yࢅ�����S��&�S~_�6��Dn�/[�wӲf�Ufw.₟mH�'��`��/�OG���q��Fh=}�^�Ȣ:Z���������?,ٻ�����7�>������{���<|���<�l���,�Z}��!��<���{�	/�Qd����>D12|íXZ���ġ�!?�xf��Y�Q�B�x�P	�W�A�/�$y�ڧY����)�K���v�|"ͩE�Fs�hy����8u��{c��`H�%�|5߭�t�n{���.��8q5�F�� ���)�x愰$��eFI��5d'�LS l�[P�R�1{/,Т��%z*�/*�A���@b_T���9�1���D2J�_(���o��o�[	���5%�7:f!	��(�,�&@�Cʎ�Mѯv�z7�����A؃(���D��O=:�.ʌ�������:<FE#�h�'�����]����V|��A��C�|�O��:�F�V�*�-r�$����a ��3���������Ӭ���D���_D�4��GS�����19*KDII>�� ��6G��ϻa�z��(R���H����bz=	�����G�OB�BaA�5�4�mº@Wa���x�N�r^�j��R��[NEKCj��9�}�̸�n�������j�� �˽�/I�|q�"(�:U������nZa�N>���42,Rb�QMH9�� ���ֹk�
��di�3�c""�V�\I���Q�]���_yV�����U$��Y��!��e�F�Ŀ����XŞ��I�Y�8D��Ā�AOУ8�AM���.���}��'*4��$"zEDKQ=��{���:ғ� [�	L����x���OL��V��7mS7P(�'�6&Q��ӑ2F|~��h�����^5��WTHx���j��D<(�RX��������U����?�������s�����?����?�����u h 