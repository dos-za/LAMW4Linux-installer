#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="473771079"
MD5="a041fccf1adfcd93d69ca4dfef279865"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21375"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Wed Nov 27 20:50:02 -03 2019
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
	echo OLDUSIZE=132
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
� ��]�<�v�8�y�M�O�tS�|K�=�YE�ulK+�Iz�J�d��!H�n��_���|�|B~l� ^@���twfv6z�D�P(��u���i����~7��4���󨹵��l��������lln�>";���'b���2]�������~�c..��5�4�������Na�7w7�������?�o�����+U��T��k/i�l˴(�Q��C��z�(��ȓ��0��J��E�{d8��;���-����+D�{�Qߪo)��G����o6�?Be���C��S��Ү��B��H�S/����u���@u2:0���20}�d�D�1\�4�Qr��\�"�T�����gGF#yl���Z{�&�����`�=�Z���
ɂ�"x�7�j�~6��/;o:�l���3�z�Λ�(kn�,���CE�JQ �h�X�Q���4��"�a���3�h�o����V\�J���ιJ��|�;����5�u�䞿��ɧ�D���z�r�KWH5s�o��[,<Wc�o��b��a�N`[�)�4���v({�qC�J�+=\�z�>���
YE��z�}X�-L�>��k��!�,�<���	l����l�@�R��!�i8����odP_�l?ݢKݍ'���g�A�n�b*�b�T*�:>��c��֥��0 ��g��o� 
?m�2j����sduCMhQk	�ZNQ9A�4ͬ��\��t=E�ߒ*�/��$�,xȈ;���7X=����2������4E���9�S��/[�)���4������7Ѯ�t�A��u����Ģ33r�@Z��N�&>�D)kOS��u��絳�=�mxi�bFx��C>�A��PwI���q��� oZg��Awm�o���	��Zβ�˅�(c@8"�]B����uu?���r�u�*"w�NA�����R�:�Er��*�L1�Ԥ@��M�ln
+��Ƙ؅i�)�
>q���|�ya�}*�Lc�Uc���Iԩ�2�!��V�c��)'\���la�|Xߊ����������ph�s2�88�V=�
���w{{m������o={������mR�h�&�)�&����x�6�����Ry$����a���t-_ɧ�b@�[������b~1�����?������MH�����l~�����Z%��!9�w|C��;i����Bڽ����٠s@&��(	FzY����@�E�(�0��QXp�=����B&	�O@�e�l�I �a|܄�ca=_X��}3`"���bAx�׃�U��8�'�&F[Ա6���&�;ׅyAuf����,�`@�5������y�lOדau�ӿLQA��rV�N{�A>C�ʑ�W��2ў�	������L��t(p�N�i�a?���y�ES�V?�Z�/i�y��_���l�~�����b�U�D�cѠ�ο`�������_�����g�����ֺ�Q�x���������vp �Ȝ�4�a	 D�]��xT��,���Z����m��\+�l�9v�jѐNCb܁����#3�q�e�#�6�z��e����lsiS^�4^
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
�n���Z���%̩a|��O�P>�1L��_z��o{_��F��y_��"]�4�$$�ǀ�l��i�3���)�W[R�$0���/�t�>�˝�w�����̬̪,I��ӳ+�c#U�gddfdd�/&���᫹�"�6�+� �Jݝ~U�R�c�l�����鍁�Я�]`^[�3bJ�_�7w��@Ʉ#�wxْ~���*�)
�%%�Z.g�=*ݨ1х1�_}�U�My
��t�D���� *��Q7J�z[y=�Iw|�W�	KHR/܍q��
8<>�+�e4VBc�rً�a�@��*����Ɯ�U�{�����&��ܮb0���+V�`�X��q0S���ɕ3������nT*�:�XT����=K��L*�F	�-�wޒ��r��{���Zw9�hVNl�3��������h��A��Ά�U��Ѝ(��rF�dA=��Qh����F��U��B'#�q��^��}6p��hMz�%R1��H3�!E*/���"�Ȓ��ᢋ#���a�=��|H׈���v�N��_z	��uG�X�?x�%��U҉����F��P~��e#t�+��x��m�ޅn��j0H�����q�ߨ���	t��Y%?�#����Х��������J��W��s���\¨#[�	.�=�0����)��1
��W�$����;��;Ĳ��?sL�LA8,�Þ�UV�<و�2��k���.}��BY�Y��GB�z9�/��a/�z+��z����N����F\�_��!���������	:��Q��9e���J�ɤ�A1 )n��ZH^�'�̒�:<��=""�1Z�����KEܦ��0l�f��Q�>��|EN��`KОJ���� �,y^j���Z�]�q�/�!��5M$(묜˵�g�lpf�#�]T�(��DT����T�%�*�������#/�?[�e�K��`�Q�^�i92��OY�^�>��J��K���!�:����=Df� �]s{�������9R��vJ��y|7���xnIf��s�b�v#U򛤍�*s�ѩ��q���T��D2�-n�=��܆�j�J^_K�R��h��yT�9��;�EL�o����u������B�by�/��0~��#5n8� �ɻb��r��x8N�>H�~z�kZAe�͔.�A�t`"r�ke8�K�"a��}Ua�H6_M�;b` 44!b$��-�|����e�9�X!a��S������3>�F%K�~�4�B��v<�.���ҍ�nr>t����ꆑYL���K������+��Hsٜ�[���:��M��o�//�0��2�q͑����97�;`?&O6]��F�(,a��`e�\27��{��4\`o)<AqbZ���4����*vZ1K�I4:��u�V��������VqJ�˹X��/h/��?���j�w��L+R��iC�`���-�S��>[ξ?����vV+�bj�K<��zI>떻Dr�߂������u�p:���.G�Ǒr8��ot?�FYo#�=��}�:�j��,ߠ��d�;敾B�g��nG�4lR͑r�~�HA[��մN;�3���z�Yb��U�$�֮bw�s��ݻ���b4703%ЛҼ�i�\Ͳ�����vFxtr)n�ˁRʝ��u筃䥻�c�b��`F�v�?�w�O��F8�8w͎Y�O.L������V3�Q���y;�&/�D~�����0�^V"9���z(ͱ�x9	���^\�%�6�Z���V\m���kn�~L^�̀h��6���-�l�=�g�T��Q��ϭ�E������㿥��k����jJժ�՗��F���R~���yAQ�|	 E�,[k{�b XN�8O8$�Yl��|��~���.-�K����b(Q7�K
��NHǌH�wH��U�{�EL��-�����*��xݙU����4�����#����U��˟���*��r�f�i�\��1&�f}\�VVY뇃+Kl_~�'�8V>j~����	�wa�i��'�+��?��^>��?�����Q<@�C?I��������-���ڻ���&�Ӕ���
	_��,�B$��~��*Z����k�6ҫ�5���-K#�4:M�´��f�������L��jY����z��$��e���,l�u]���?�OP�������L��Yy���p��/�
*g�T�^�e�૚!_�0_�%�_�֋(�4�	i�m�?���J��w�S4�q��
�\��g�N�]<c^_6�83h��8�ϡ�s�8�g����$ܬi� ��"����`[�b�N�xv+A�7����sQ��;���g�<��Ug��/����ب��5�?�o��߮R���j��s��Ya��1�b�={l �28F�6
ug�^�!�tx�>���$��2o^������}����:����Wq/�˧�R�����n��|~_�Zo��u���ǻ���jޭ��Z�/a#�z{_o���o��Nd�z�\��j��V��l�J����}]�F���fe3����I{���7-���U�����K��z-}Q����U'��%A�5�|V]`�b��?���z�;�.�S,�n;�EpfJ<�+8*us�vz ��
��J�.�] �̩�e>��Ɂ�����vGa���#�v�>Fz�x��� O�>���6e�l୅��3[Gv`�l+�3_t�01�������C����\!��Ë�#�V��!�
���:v�T��&Lvg��De����x2��.�/�ɠ+⑨|D?�\;�<�a��qs���`w�A3�d~��C׃�G���E�f�9!c9��H:��:��.؞Cm�K�����x���
�}$x)]&�I	tU����0� ��ь�D�e��0XM�+�J(?�q��:��*�|���6�B��7x��Gse�ŀ_}�!�LEe1���R�v-H=Uaz`^2�u���V;��ħU�^���>	^�f�#�,�X>�z�c)m~T~ڮ�}��ǭVm$-�?�´0���0'}���̶*�j]q�iP��"���1w¡a�ޙd�EV6������ݝ�����߰T92��*���`�vC��b[�3U�:I�h�s�@�>6���Yo:3��i��Ї`4
n�I'r/�V)t �B�����A�r�����d6H���:��(e&���2#t០R�&���(�&	.��7��R�L(�&��@[�6��[���I�'��Y�o��zÌJ��Ƅ�Y^�Oeπ�rЄ�|�TR��J藲RbYS �)�e��y�a���`��$j��a�\�G&]��4���bG����,�q﹐'9�w��0��
	�	�y��46���N�WrP�Td����4L�)Y�Z�$��^�l�,�1�K$�r���`��@98�岂����&e��M�2�rٖ�@ZS�{����N�we�M�_z"[�ƅ��
Y+�ԥ�>��H2R�LA	��ގ-����62ڞIhZX��9rJ����6+��D.�ԺU6���F�F�[��o&���V'SL�x���ߕ�-��vε��S �q��p�}��h��%46Ǳg��?aGA`�X)yOg�q ��^�h�����"OV׈��~�]
�2���#�3��(��!����.�`~W�Ud�_5�\�?��h�J}GL�Lh�N��봣��
~���Q��#��T���݄D�]���WאT��wD������X	�V�u��+
U�JZ�F�s��v�4n�	�����#�n��э@����qn���[��&}A��#�5�L� �p:�ut��N�$q�H��<� nIp��=��~�8G�#����C��a��U��$�ɬSk��H�N�-��O�tu�-�[1>�~�����Q����""�`Ni`3%?�x�U]����OPI�dAub�t&C�J{�-b�GP�p�wA4��	�:{(,-a��[6T(��&�
Sk��0���R�(� &!��c4Tc(�s�r�	����dL�EctE����m�:��r}��#��t�m�
�)�v| �(L�@%ىc*���Qk�p�%xX���.�o��Q~�#&�Y���'^\��=3��{�.9����x�I� ���Q��ѧE�/�G����~�#��㧍l���Ǎ����E��;����\>g��W*ֻ�]��t�`9�����^�B4P�}ݜC�HV�#��['�"��u�6�	5ݘƩ�j���GG�J�=�:y���*2~�8��ҬI(1�<k\eUF
*&szS���C���=�I�Y'z�:W��(N��e;��c_}0�pL��R������ʸ�lW`�M�4�Ҫr��f}�~�Gn��,HX�����YBӿ�G��0��f2[�`�X̑C�P�˩n*/!=t�ĵ��4���Z��5��jHi��.ҟ���,�c��d���z��df��fz�2E^�� ���q0�$,a��p���v�MSe�������fN�I	#�Yh�z�����t�g�|���[�i�2�@9�U��������Cj�_�����4��G�A=b/u��ÐKÓ�x(�VsE�W�V[T�P_��j//S8�֟� Y�8�1�eN�VAЪ)U���@���>u���P`�6kڊ*b&`J"d��7�[i㖬h�0V,E\˼�	�oj3@2ꊖ��zv��Zꃭ�ƙ.�湚�6���?�=>�>��vW�Eӫ3��"����9��#�l��fa���[C�/���M�X�)U8��w,m%�/���h���]|M�������Zu�&��A���ݝ���n��35�i���	ϣ ��V;����|#dg�^>}f�`J����}V�����v3}��Ϭ�K��F��_n��Us�)름[v�IB�=������@�l6Tp��쟴����M�vNrWCC�RO�hm��&~dy��}�~	�`z-4)��3kg�.ʑ�sXO�����6uYۍG'�N55&�o����iR7<�v�׼�_�]|�W�Pû���C z2�x�E�^{�=�}O�9�kc\'�|��ft!� ]�X����k��6���P�Z���k�׻�o��I�V�"ΨRNF����<�ME�NX�?��GN�$��x�� =�E0�=|�x$;��QB����8Jx������D��U��$3���+)*6앺4B�V�@�:�.MQf�J��\GhOC�0>T�K�-�]G� ~��ԒZ��u�5�&?���p�ˌ4��{
i�v�J+^t����6�t��4��] Af(���%0��Ԧ&�u)�MՖ!5&5Z��$�n8L<�c'ĻCT3$��S�j�6�k�?Nk<��f�J��\�����)Sf�9�`��5��P�C�Y��,Se���@�Չ�9�p+E
G$}a���˲?t%ɜ�g���Qc
y[�n�x�HS��<�f��ΒQ�[�y
uA�lU������D�2�j�h˨��c��~/�f�����J�^2�hvw��9[_H �YnAI6��%�%�x.6�(��l�����a��Tr�$��� .���Qv�n����p<��;� f.�֭�k�쭂�?��k���鴵�&�a6�Tޖ�2�7)V2Te���75`qc��1|�*�)�l`����-Q�-̌>"6���=h�z��owA��#X�ҋ:� �Us�)�
����K�h����64�ַ��ov�ۯ��3��M8Mh���s�E}���0��Ԣ��V8���2۴V��w[	��M�-��l��)�{3EѶ_'��,Z�	Ǧ�u0��']nM�%�A�k��p%Dt��?h Q�f�i�*8?����������n�J��h!�Jl�F[Sw���ܓY�E�g)�����AЂtvw�D� TՊʬ3����o��O���R��ن�����*�z�K���;~���[J(3>���.��@�^�d��n�<5=?���z��(6^]�T>�9U�y&�[a2[� �|S��!�"�zE0+��H����)e�P�3��ܓ/�̃���M�k80D���V1����e�m�Es���@z�U��`�&K��Y��*AV��b��:��g�,�
&�����3V?G㋑�3Z�ܩ�}f�վ��8���hg�8_�!Nz=�����G��0��r��l���\l1��Qbȉ�O����U���Y�pN�Y��經Tų�n��M���>���ۃ��(����3�?���m�D�t4J%�4�bgp��W�	]/��2a�M��J�s�Z-�֪U/�/>R[ƴ������l��/�	C	� F��d�-����
SV_�� �Tg^ξ�~��2��Q{�`g���5Qhr��H*b����ad\���_�1�b��!�t35�a���!ږ���+!�<��l�����sU���	d�W���],���)��� g�2�M���eȤ��m���"T6��*��7�[�n�{p�?��r�b��9:�&�񪦡l�����ܐk�'�����X�$b�}����Lʃ�o��茦���v�u;��<��B�l�k�@�5��wS��J�P��A�ӛ�㉁���=nn��89�!��cka�,�2?MG��`�R��;��4;{0 ��:�w0YN��F�j�VWDk����	�^���u#��xWS�ћ'$�"ۜ��*L_��1���1K���y6��V ռҨlp�1\p�5�P ��}�z�5W�Ǿ+�V�a8�n�zǗ��
�B �'�	���Җ�1:a��Y2���g �ˑ� �ɝT�t�(^�s㷡���+��7�.��%�,I��Ivp�����<B�ҥ�ཥ8��,���g�A�(Ċ�o_R���^�9��o�0��͕�B����h�H����̗�*(.B iSW��XH��2�]:C@6�탰��`�n�e	�:-'�ߥ����1Rw+c�R7a��ݮ}�{�{�k����a��.�Z�ޖ�o�w��-�
�s��l�F����_��b$��x�_�􋗧{�a����,�I��x���ݴ1NHΉOp��\j7�7��`VVZ1+q0z��|A�z���}��_�i����v��$X�u�b��%��\��bc�#
��z^�d:N�2@�Ҵ�pR�F�H9��p��r[�0�.�G~�V-��Vy��X��m��d���iC��Ϋ��<�Lɐ���7�� `U�I��~ft�V�D���~A����|��.��-Q��&Nk��Rk)U���{-��{a)r��a�`���L���z�����7ˤ1�}�-����K�=���KM�����G{�-����+뭰����X�&M�'�,�c*/ʒ1���0'�����k�oB�Y�)3��(�D�g�B2f�tV̦��Ze���ow``����f�UT��93_A�4S��g���.M�q,T�G<1ꀉ��A�Y��qn��u�0�CV�r���Sl�v�#zE
4³�"��㸬��-��J�>����(�{��0�R��.�SY��sP�Y�V_Pbq ��;��*J&@!/`��⫰�TT��*#������2EV��X�t����T��Ҁ�
`~ɥ d�ьݣb�����|�F�F7���5��0�st]��)��7Ds$)*����� a.�E?��T��\ �bLk��]���˅�,�Gb��bc`�� �r�@��K�-!�q�� ��/JW��OHh�VP�R���S9fF�OFDz���+�t �Ԇ�
>"3H�@d��t~�G���ǈlH���0��f�YT�����~�E ��d�@�kr�ǖ����h����k���s�%hN���B��ڲ�i�-��Χ�v���x�aΨvZ�"����p����;[;��\���k1�"���3�p���e7:���!�$���'E`vV�Ol+g$	!�-ə^O9�ޙд��¤;��-4N�-��t� ���LA;Ԑ�&����ФKK/Q���ʠ�y��H{����(
�ld�w^���nx��E�Gq?��������� ����|K��l�Q�C��E��I;�ݒL������.#�\��1�f��B'��>? ����$�҇%>�X]�=Ȃ�ۙ�bz38��%��V�n��Kb�+]Y�Tj���KQsSr��`Cb��۬�[�},�����4s��R:xKI��"�_a���Mu�/��I����LM�[���d���|��Î�'{`�oi�Z��|M�������c�dq��N�8�7{�,�����?����N������MO�\vS1>6 2S�\�O���stF�M�2����;io�:�2�owv�^
`��3�喚����pQ�+qS�8����5�M#�(��!�Č�tG�>ǈ�B�0#��a)��#�Dv��V�ӭD��m��nH6�G������s;��_6"��,�zv���R����J��K�(J@"(#E�S�4zGy��07'���X��f�PT��;ca��b;1�@2����t�F��Ƽ�]˹A涍i�u�$9���+�0�����Ow��L��z�g�������7�����S�/���o��+���q��1��5���R�Ϊ��Ŧ2S����^EWA��d��z>�u�,Qka؟
�V!�JYv<�@{㊎��*#��+��=+�B�:D��b~��w���x�h�o�^��
��;<�i}O__�w��1ga�
C{H@�
�g����M�h�+�V�`��4E ��p�%��e��UEtY�#���h6E����#5:�qZ�� �T��Yl*����4؍�� 	��kQDRa>�?G�V9�����yT=S�*�]sr�|a��F��Ɠ���'������s݅�y�.Ġ�)�ω��I��
�\�Β/�-�	�q�$��� =�*���u�����F��{�\G�E4J���%�n`q<8<�{�^�;�Wk4�8��� R����M�U�^#%�!yx��d:K��T��zZR��h�>�]zJ��{;�b��˽݃�],O��GV�<�~�d��FVE���Λ����6���F��M#/?ș�/}ϩ�i�d^~���
i���`�9��'����'J���l|_�#�P�	Q��=���(@��J�z�Vu������C	��GJ�N	*JԟT�6��I+��Y��	�v��ΧT:4A�\��>>&9�i��DXU���?�Hz���SyYg<u�^5��,:��<��Uw8���9\��ag�L�BߣT a���i�G.�ւ ���l}srx��C���Q1��U��xxtb�΂6��<}���IP�\�� :�IГ�z��N1�۴ 0�p�&�.����� 6�cw�������?>a���I}���e�\��xT5G�g�f�۵E�uN�(��l܇gO�O6rm#ߘ�f�>Qӊ ���	��Z��}/�3��-���g�fռ1{x&�2o���T�p�I�V����SL��=������;��ʢ%PۘnM������4?ݚf���9~K��'۬�ڷ2��vE��S�٠~N�H�޹ʬ�Q*<u*N?�H�#�O���/�~	�~v����DH׆�h�nrNÏ�!��	�"+�2Q�P^p����ˈ���`�k���TS ��c/)AƇ�+�T����e�vӂ��*�h�NxEr��(�1��m���E���0�f`�T �V��}y�{p��;�}k�w�Y�`�wUd��EUA�}?�a��C����j�V���|l.��e�p��(IZ|Xn��a�E�n]YK{j=�5�e��5O�K�A�C���0�5�E�~<)�A'Lj�&Ѹ����*>U e���?���k[�m��1�Ma��܌Teb�����>�*�~���(z�0�M�J�)�,M�Qt>a��1b�S��2^� �Λ<9�>2���n���=ɾn�*���ކ�9k��j��I�x��{.D%�8���=-W��"��H����~�cdS��7ƨW!K0����1�z5�^��p@��dSk��2�e�#��2�r�x���KKz�E�LiӔF5���~�hܐF�փ����~�)V%��q0�$�B%ԫϪ�s��l�
����Ǉ�V{���>.���2�Zb�j���/�V^�::U�ZXjiJ9��_��Q���ׯ}��V0�G����/����x���_�x�]^�JF�0��qs����j_A{��gD�J�wlا��/��V�|m<�FI���QԽ��s|1���I�����	 1���7���u�ߨH�l��������d�3M������^�"]e����j�E��Y��޾b��X:�}��W�����-���m�>>��a�(&7�2�5Q�X�Gǽ��}��%:�P�W���{����X�_p�F�'��N���s�2��o?������o.�u*�&�7.{��z����^
C����`�m"��_�Y������=���0���PG�܃��j�`��x����`8w��w��ه�B*9l���L����Ї�D��!���ea�츧a����<�І�m��/��*��n���=`����d��Q�b9��J��T[�]�}o@Ӑ�s���A��Ke��08�*�?ֆ�Y��S-	���a�l�Z�G���]h�q�^�Ų�u��J����hJM3���/�i+�E�2��Yv�F��Ф1���(=�յMg����}>
p^�u?� +�:J}���J_~W�'�p�}U��0�o:#Kɳ����@V�M?��l���g��W���������_8䎶������I6�q����c��Lź��z�Ȃ��&��1�:+�ق��k�H��5�9��A��d�ªn�-:3��n�m�M�Q��)?.� E,�SZ�6�ܚFښe\�+��H(d_H�Q־���Kn���&_��fg��e��wW��-���z��������a�W�f>Ũ���BJ���UL�(d|�VC��2����R�����6Mf
k��q<hH4Ɣ�y�������Nb��$k�^��BYd��	��t�l�tJ�
�������D��٭!Ӡ锆������Ԩ9�gӣ�Z��J�hHP�(���P\3Q�u:��1=7Wf���6la*L�A�,>3	��X�\��̕l[Dn��m����ׇ�#�4�үN߾�=�N�$@�&�����a7{�Z���ZW��]����l��� c�n��/�%^�h�do9^�vPT|>IȊd��S<�4*���9��q;b��8W(<��ڿ��ػ�T���N�7fv��h����ӝ��U�`{�i�k�|Y�����y�ߍ������k��ם�V����'����L�ɪ������y�S��>]G�hm�ˏ����]~�<�[n�+�eK�ϓa��A%Aj�y�X���mCs�v�Rw޼t�e����+����a+ŵ{�����bdҟ�a���9eG9�Dy�s���2��T�Т�&�S�.-���$s�I�s�s��NO��Cڍ,�<{LϤ�	�~�k�x��P�t��\�(fm�n�qJ�i8��!�<w��<����Bl�&�lfuDĦ7��jU�i������7�(YD6��ܴ^��O����%��G�Is��1�l�<|�C�*9,8AL���f��Tqr�{���;|v_���ݚؔ�@	yFś{/��D�L��}�&�t8�Si1���'� x�uu����:e���Ͳ�W0�O~���Q��,PE}���O$����)y(ժ�m���|�A�7��"�-��{"�2D�l.�����Oa	v\G+2��_��Ӣ�Õ�j���I���^�(�&�*0C�YЮ����@T2�� ǎQe��A�ރ�<3�g�R��v2Da�k:C�Zk�b�M�U!���-�O~�I;��M�=�3���F �Q���XO��vㆢ3t�;@<9	�>EyYT�O<�.���� �)�ڱ�|�mPO Wi�3#f�d��T��63��<1
��a�0A�����0�~Dn��`F|m��%jh�Qe�;�s nÃi f�c_|��?X�ӳ�\�Ӄ�>U�D�wڅ=�0�
������W!l��s�p���z<]��y'��q�㝅�8��6�H�*���J��s��a�P}�$���n"I�ު�6���}Y��od�FR�y��B�Uӥ�
���=��V�w����46-X
�uz��߹�"ݳ�C�o}K����\/�-��<��YF�~����'�`ե%v�+��D�!�ҹ�~N`�������!�3T��y8šU��W��`ԋ�Ӄ��	M�r��ci�j�̢	X�X�<���:��B^�m?����կ�i���pi[�H��2+�,�O�x,S�
�K`9+n�(7DyC��d�qw����)�V'�Ik<B���Qd0"�ŤG:�� O��`@!�!��A�y2"w�r�r(�\�S���Fn@���k#3lm���km3դQH$rO1�Ӽ���.����p]r@� �[@�)��%�^\�^$��K�Q짡Q&*�z�E8WO�x1v;]0pT�k�s1-\M�˩\��[(#�n�ZrqZYL���mS�2k'L��.g����y#���X��-J�vB�G���Bw�o��N�[s^�ˁ{np��5�%V����m/-�Os-�E��Ujڴ)2
���I����'�?G�Ax�BWAJX4e@���<	�^����T�C�4��3
��x!毊���дN
Ɇ�XK�{h4�(
,�!+��bq[!�C�at�߃��Z�Ɲ��Y똁�����O���ɿ�ǋ��/5���W�a���2�k������?^���2�6�A���_xKx[�<�p�F��y�е���d�B�o�A�#��힥��WI�/:��{�
��<�F�EjY�z<������y-xQѼ��	��D$ %�v��M6�}$�'cFBx���wp��Ry^�_Q%�^��������@�X��_��}��٪�^�����;�E4�4h�[R��YQ�O���^�*S����р ��4��>A�E~�5�bJ�Rjɏ��KH}�A��d�-�"�۶.J+���75�zf� O�)]ѯ�G|V $��KJ�@�$�ds�&��+��
�����65���`)m3�����3��}��g�6@�>Ibl&~���M�]޿->���a,?�x���F}!�}��7'������z��k�����������э���\��k[p{&|4�ۓKQ�Bj�_ڣU�>i�/C߫���ow=�T�L'��a���;8<j�<�5�#�@���ߟ]�䛢����'��gc�e��\��i�\J�ɂ�A�o��¬Z��[uV9��.��UC��T:��H�9Y�RW�v;��W�{�X��IVWbv/pt�G��=�G'�p,���2yֺ��6zc!�Pr�M�ʩΊ�AP;�[�ߑ;$5T����KH}����5%���2�bI'��f�48N:� �4ݦ��+�+�*2��{r|l&���X��yx<�ԀB�����v��ۋLI����l6�J�������?�$%ab{T�H��l����PIO��6uMh�&��B�2���dk�r�4a��F�g�
kB"�
��Fn����L���b�t��`,�D��V��P�*�t�u�`j�ř�n��G��-o�MO��V�`�^c���xP�0)]�
�e}$����J�����m�'_{Yh��.=h�������>�Zf�[H��_���^ ���ƾ����C�����?}�������}���'l߯Q�%1��&��<ɉ5cF�,��儦�;�e ����`q
��EN�g�[�R�V*��dE�+�"8�$��.��_zq�EM!K+�ɏ��=�
L�x��%,-�&�p��h"!q���`O�׀hL�7qN�z�}���pp��Qca�rg�����k8*ӵ�l*�l�Q�������,h����}�(�j���!�w�g����=��*(�ar������qc-���X���g��3�M\[~4@xN�8����Z\�����pZ�O.�ET=��@�8����9��x�H�k�=����ߵ6�]a�bmdj��,EX]���;����<lh���G���J?A�x�=�w�N:t�I�ӻ�؜qj5��+�Q0H��~_�&G�fC��dҍEЅ���k��� ��cm`H�t�;:��-|�2���{A��fIlt�"B�Jt
`��B���(Ci�2]H�_����h�On0�aBr $yf�;f|�ɀ�. ^��\�ppiz�@&d ����$y�4v)R_Q-�쪙Uш!���Di����aw�*:����jĈ*�뽿���)a��ޢ$I w�=�a�.��# �0���jʄ?�E�w&� 3�eޟ�H����%yYM�������g㳢�8��ƌ;=�7���n{r��m��w��ȖPJu�h�nX�j����h<s%b76���B������0c���,��0��)8s��^�F��ҷ�)�t6)|���`�:%��]����X��f6�) �����;?�ucD�<�P�
�b�l��k�5QR!1���8S2P���\����iM����Am�|&�5��~~��'��bw&�m��UY	���l@��T(>�B��ѷg	�6��h�8k6��&�ݗ�y��5�������07+��6�1�M���lX���5+�C�������}H��;���Ӂ��et֐o�]b�f�6��Z�8�����-��/��?���5O��_����W��d�e�o�[+�U~(��_�ϓ��_Օ�<E���=��C�F�o��( ��m@#�zf�5�*����=|�.�gW���V���۴�N�nz��!}#���WSk�s>���W�Fs��Z���̾S[Y�7���Y�q�.�W����q�m������w�����r�� /cgs\��	aݘ���d��k�����}jAN�U��@�/�@g��|Q�T8o7�E%�x��L���XF)����j�[���]�����R 3H�Q	K��5p�)�Z�~���-�w6 6E�~Е�l�)��E�1%�=��Y��4*��,Z&E=�����ʢ�ͭh��D�����t���l�F\V��*�-rƤ+)��@H���TP�������Ǎ'������4�h�aW��I8�@Չ(��<_�!.�%Q�������</�^/�ƃ�J�di��1���0l�{�:z"�%���AG�����	V!Q2��6܋��y/>�v���흷������#C���xu"(�&u��Я�Z\�a�Nnꌚ2Q�%��	 �e�@�y��1�Q��{Tʋm��P��%��a�Ԕ���������`�HȒ��_�+��^�[��v툵k-���!Î.�����*���/�I��7P�G�.I�a����pt�&Hde�{�^��/�(4H�kD���/��M̽7^N��?�{���a��(�{�đ��zb�J�]C����m�MW���[��?-�fû:࢖VjiF��)F��vZ�E��S$,�q�&�<R�W�G]��Dی�*5�rB�Ȣ��/���k��S�"�� S�98��	Q_Ku��t�O(VṭE8 �S�7�>�mt�P u�$�LF0�f�5��2hǎ��9CQ��5c	��Tq��vk0o�I$��+N��ز��s�r��<��[�A����,>����,>����,>����,>����,>����,>����,>����,>����,>�Ͽ���pZ�� � 