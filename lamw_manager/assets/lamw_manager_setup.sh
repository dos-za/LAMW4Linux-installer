#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1191555416"
MD5="b3e2e1d426006226c9befb1bc71546ac"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21500"
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
	echo Date of packaging: Fri Nov 29 21:29:32 -03 2019
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
� ��]�<�v�8�y�M�O�tS�|K�=�YE�ulK+�Iz�J�d��!H�n��_���|�|B~l� ^@���twfv6z�D�P(��u���i����~7��4���󨹵󬱵��lg�Q����j>";���'b���2]�������~�c..��5�4�������Na�7w��������?�o�����+U��T��k/i�l˴(�Q��C��z�(��ȓ��0��J��E�{d8��;���-����+D�{�Qߪo)��G����o6�?Be���C��S��Ү��B��H�S/����u���@u2:0���20}�d�D�1\�4�Qr��\�"�T�����gGF#yl���Z{�&�����`�=�Z���
ɂ�"x�7�j�~6��/;o:�l���3�z�Λ�(kn�,���CE�JQ �h�X�Q���4��"�a���3�h�o����V\�J���ιJ��|�;����5�u�䞿��ɧ�D���z�r�KWH5s�o��[,<Wc�o��b��a�N`[�)�4���v({�qC�J�+=\�z�>���
YE��z�}X�-L�>��k��!�,�<���	l����l�@�R��!�i8����odP_�l?ݢKݍ'���g�A�n�b*�b�T*�:>��c��֥��0 ��g��o� 
?m�2j����sduCMhQk	�ZNQ9A�4ͬ��\��t=E�ߒ*�/��$�,xȈ;���7X=����2������4E���9�S��/[�)���4������7Ѯ�t�A��u����Ģ33r�@Z��N�&>�D)kOS��u��絳�=�mxi�bFx��C>�A��PwI���q��� oZg��Awm�o���	��Zβ�˅�(c@8"�]B����uu?���r�u�*"w�NA�����R�:�Er��*�L1�Ԥ@��M�ln
+��Ƙ؅i�)�
>q���|�ya�}*�Lc�Uc���Iԩ�2�!��V�c��)'\���la�|Xߊ����������ph�s2�88�V=�
���w{{m������o=�������mR�h�&�)�&����x�6�����Ry$����a���t-_ɧ�b@�[������b~1�����?����������o7_���3��V��EwH�����NZ�.Fl��v���{t6���u>J��^D�5�1x/
!̱y\O&�l��IB���g�3rf7���XXϗV�{����d�C�� r��<$������u셍a!�����ua^PF�1�y��32�P tM'F� :��=r�>���dX���/STP����ռ��i���rd��o��G��f�ƫ(3;`�9�i�3
���w�a��7}^gє�Տ��V�K�^r���7��_��_r��Xx�&��X4���/��fo����g_�����g�����ֺ�Q�x���������vp �Ȝ�4�a	 D�]��xT��,���Z����m��\+�l�9v�jѐNCb܁����#3�q�e�#�6�z��e����lsiS^�4^
��m�;W���Mqm�g���$�یE���p���)��V��g��#����>�����ϱK/�;!�e��}>��v�+r1i��𑔙S%%����Uo�y<g��1,�P���-��,��A�Խ`�M:pQ�9��P@<�7�U�X�����~k��P���cOp ��J`�ãy '�>�͋(��Nk�1�;'~���S#^���k�H5�:�������%m߹$����$Y���c�4E���ʺ���HAi�ʋ�a��S�?��@���K����ě��?�4
3��.y��hA�������?{��+On� 7���l�E�h��ů�t9Hj�%�^�^��Ϙ*^�+鮄��%�K�M���==Gn/.@U4�F\)Wk�A*1������c.rT[7���z�2�_�*�x���ɸ�B�K+$���BY��$<B'�Ӎg�/Ij�G8
��9�r Y�6�m�AM�ƫp����o�iOos�㣘�/�~|d�}�=={3~�;�p�`�&D��<�tH���NG��[nKf���{U}��UKV�
b���\ެ.��m�r]�B- �*zJX�Ҕ'9s�� ������q/���\�@^�X� ń�+�sljc��
���t�4;�_Y��-R)Yw���2��W<�4XN�?��2i��ƣ��32L�����P5q��c��i���H{�`��W�ZDk�^�_m�$���s�}c��T�|�1�R(��%U�Jv'A��٠��4�ȁ5C�ZQ���IB>�j�	K�~_�J���?���>��<��q�x�L{ѻ=4���C@ˤ��d��ݜ�'��[��eC�[��%�����J�_�������r����/c�*�|f_yY�3��C�V�A�� QI�.�B+���n���CY�vK�� =0��%��׎�+�^F�]��~��hR��G�9�	���nʽ���m§r��iۇ$߳u���ɞ����9���m"w�&�����6����s��a`�\ْt�/4��(@H%noKm�U��������F�uz0�uƱ�<�8�OB��l��KԠ�'�.�&q	��s��yx^1#$�/�mILaU�<�+���e�JeHQL���S�q:����|�Զ_&	��Z�_zI�@R�A����{��k��	��V������7A�F-\��V������Z���y��������K���,�߱�K��Z|�X"��(�=�����.G������xL�N\V��j����vI����CϜ� ��R�+Y&�kI���|~����C��h�����Z��/��bq���� �O����~&^zQK=��2�"0�L�5�J��1�e�Q��%H����q%y�J~���#��k�ش��ޙE�������3�xx�|��p�915b�{��7������B�^uNz����w�1����.<zg}C��hx�w�cB�!���� B����SZ�MH����" 	x3���x��5�bi���K58����IV������,~reD�x��7�Y�����X_�Լ<B@T�rR�$I�� V>�E�8]<�a�Ǡi��I�va�$�Un�Bjє�(�c����7V�b�E\��w��[���Z���k]�c�`�L����d�x�I�	{4���r���q�Aw�y����Dm�����
u�-�qY�Ry�F���?Ka��L�- �s>�������c�K�t�C��{CQ�:xAIlI4o��INt�E�T׍cۥ���809���m�=O���S��u&=��=��5�#
25��
�Ņ�s?�XPx�����-H2\�sܸ��ЧU�N%$-����e���A�X���7!b�h������`�ȋM�3�Q�R%���I��v��^�h�:8�� r��_]l^1�_#��1�܉���x��#�0�������jMf�*=�K��e),�ﶴ׹^��
)����*�7F:���^�'B��C��MCf-Gr��ݑ	A�����gb,���h��/A�3rM���	yu�^�G`&�a��/y���t��ϱ'e�B0`�(��k|�.3 �=~���T{X�f���l����kZzS/"�K����1��l(��ٻti�r�4�G���\�׷5ĐH_�P����1l̥;>Q������������e,<K�W3���Xm� f0<��58�KϏ;�'���T�S�8s�L��T��zS=/�ײ��)*��<*���7����	y	F���$Q=����� 
�'Ol��o��vS�������}���6����'B/�~+X�Q½�'��c�;�=Ų�e`�x#w�%2}�@���؛wE��2����ڐ#�O.U� ��)�E�r�J�@N=�|�^���A^Y+?=Q�����=UE�㠽b�6�'�^p�|sJc��^!�dpq=������.ČI�i���;���Cs�������ͨ�ħ�l���1���g����;fP+M��@:#�x�|�&mj�Ca#����FQ,&��Y����;DI;�eSC��W{�_Ё�k� ����ܻ� Vj�b],ajzW�7��2B�)n|S�BP� �"�νC�Dg&\d����;w�le}�+��w�w?/RgĿe99{)���@��Žs�˷`�yl �1ɖ��䂺���C���wmŒ��D7}�I�{H�����
r�G�7���A�rN����c��XX�򥜇N,��)^����>�J�.-���m�����y�����t���"wQO�5�-QSSoO�]���v��4w�Z(r7M	^���&2*�'&�>�O��ʢ^��el;)A�)��<L��m�b<�
"6�����Ǎh��]�1f&h�h������-fC$e�cC���l���p!�8��?:���9pq_�}\S�>i;&cEv��vr�Bz�W��C�ϟ�c� Ú�'
�}���AV ��--E$D������gQ��1��*_�k�53Dmy�/ց:(��a������e2�뽽7�˃�v
KY��UH�{7����a�!oxe:5��4��Fwk5|���<|M�Ht��V���nk|�9=wG��$�/�)�s�!d'�]��q��v�4�s��:×�^�����oj��z�Y�^�9u������-5-�k�]��.4���#ۢ�=GX-V�.E /����y�p�hhR�2u6;�\�P�Z8�d��l���L,?� �И���O�����=�6�~	��8H�A�����4���F�� �����C�Y 6(Q2��{,'�R��9�8�n�~���x���L�Y�T�&���*9��Y��D�^-�Jb��J�%�`.�$reƓ�Z��B�N�v��wN��7.��j` �օf.,�Iɧ��~�U7r�s��I[h.Hs�������8�J<3�s^�_R�t$o��@ɓ��*R��o������)`N�Tbck��� K!?%�J�͏�D�$�*���%���<��6[u	 L@K.���o	�7@��s�!�$�|��M�@N�e_8+a̱L:�^��6��?���/�cf�[DIJ����AhZ����R��3�})���86>��\h�
3�ðL�|Q-�K���J^��Vo��А�D� ���mi�����0r���<�Ks�@X�!��8��C*���[('��� �h$#������S'�<�W�i5Cdu���NqW�(Xt�����O�~$CՕ2���@���3��ҽ<Q�\9�8Sj����7������6�.@��X=k�SI�<�Y���5��s��r��s�Ӻ�U�GM���&�7�B��KY�,�#�TV�R�*��QЯ�k���0�����?�B�l�0�����m�ۺ�8�4��+��Ij� �K��z ���� ��ݢN(Re(LU�-k��>�ه}�>�0�h�����TfU Ҕ�ΑT�=#####��g���᫾�"��*��X�aO����,S�C�l�����%@O�W��ӯ�Ս�ү��;�n�d��;�lI��ov��xtO���c�U������a0���B�䯱�*u�&=��t��̮���QvS�n������z��{�W�	u�#$���X�UuO��$Rh�V/G�9������^ј��>+SE �W�9�<�Z���L{�b�W�d�\����`���-�-g:*�yYmݨVgt�1FeAZ���*��"�Xet���9%Ս���[����p-�hQNl�5������G�h�7��M��fT�B7�tt��$�3�&�hLD��<�ǃ�hW-"��dƭ�V�!�	���{�5�=�K�H.G��4)RzT��|"CnLӚ�L-Fr�g�A?O� ������v��xȿ�b�;F���$����AXK���0��Hͦ�;/��d�_�s�����.t�O�ռI�����?F���Z��@���Z���u���.m��4�*�V�h_U�aȫ���%D�2��r:�sY�&��r��w޿�}�e��a��)�E��I���cND
�ay����{��v@#_Q�ƿ�_o8�� ��PVhV|����&_��E?��AO�s]o5��t�O��l8�oD%�+°�78���O�p*��bo�v1Q �D1����H�L��!ŭ�H��I�*����"�1Ϡ���KEܖ�Y0�$&��u��R���f���=�#W��Rr��>�0��۬% �/�!���M$(뢜k��g�lpf�# �.*����"*aw�w�d��Z�fj��������m*Xz��[��+�S֤W�O����&�R'=f�t�Nut���`��o��x \�,�}BݼD���L	��'���3� ,��@O�}n�A�֮����Q\enhT�lclw=9�b#��q�]O/�a�J��W��ӦԄ"Z+wxN}n�o&�7���^�*i��I�L!3by�/O�0n�%5n8� ȓٲ�ł���p��-�G7=���5���ȦK�� w:�9ŵ2��P���{_Uh&��ͯ&Н 10�1b���=�|k��~��l�5�X!`��S������3>�Z%%C��{�B�}t?��Kq�1t�����&Cnm����adS�x>�Y:�`H��i)��{+B�|��3�Ɏ�D������"ӹ/��)G�q�Zr#����i�x����n�����Tf�%sؾg�M�F�6��'&O�ɽ�%�vP��)�M�����3��z�����7�┎�s���_�^<�9.=n�w�qt+R���C�$�ewJ�T��V�/���{7���+y��z�Ͽ�Q�Ϻc/��w���r;�{Y���>G�ˑ�q$���ݏ�Q��~��y_�Ouwm�o��rr�;��B�g�RnG�	�lR����~�LA[��ռN[۳�����1<�ү�Iʭ]���)fq�w���hmh`fR�ץyq�.����r��&���JY��].J)w�c4\����ޏ����ڃ��m���)?�fQ��5;f:��0ŧ?��[[E,$G����5y~�
�3D4 � �#�e%�󐮭���b����iN��Ul�Q�jc��c r|�	W�g�9�Z���]= Z����R��ٓy��JT7*����uB���]|�mw��,��g��-VS��V����\��%��ʃ����b�
 (*f���� 9AnT�2Y���g1����[��ǵ��:0ٷ�C��!�Q��UB:f��C�,�n��%��`
��l�䯝Y���΢��H�K�o�*:2��KE������֬6C�Plc�*�M��3"�@# �k�����Jk}re��k�����G�m�6]8�!0��{z�������s�������*��	���ILo`�}��kK�����[��:��ԅq�T��_!�W�%T�4|o쫲�xV��y��Fz��.��[�e�H�F������y	���l�M��ɷ��,�s�f=T�l���r�ʺ�,��u]���?#�'(����9?�;xVY�y�Ώ6���rJ���3W�����
0.iu�L�U\@��AMHؾm,��.V~�}�Q8E��|ʰ�k�D����3N�kg�S����5�Q#�a�,�x�����4������%��bT���-nG��CND��F�����2�(�֬!g�d���Vs�����X��X�-��J��6k�͂�f���p�$�����a�&�� �s��!�`�Q�+8�|�K��������D5_��)��?z��gߵ�{����վ
Ga�.�2J�w��n�UY;��6v���52������W��n+}�;}	�7�]|��v�t�ND�F�\ɪj,��F��l�H����*`;}ΑfE3�q��������Nn������K��z-}�MQ�'��j����� @�q>�*�z���d�:N��K��m��F��b��2���6�#��XNN�����cr��2� ���8��{r������!^;���	=B�A�d��Sq�jb��6����23[Ev���Vg.�~���岯�7s@������r�4.�Z���;�`]W�mRe��<h�q���,�7zJf��u�~�&CF����tr������[k�G��5˘�C�V��7t=�|�h7��B�Ь4'd��	C�Y-���tI����O�~^ᾏ^��˘�q��i$)��T�G3�2і9�����+�=�P~��UT��u�[H��PJ��	���~�uf5`**�Ӟj-ElWт�S��%hUi�#|����u�iC��)�O��)��5�2�Ņ�XH�o��O���7���a�D҂�\����������l�� |6��J; [W�>B��H'\ۘ;��4�L��"+������Ig���v��R��P6��tr��A�톒�Ŷ g��w��Ѫ��0}*l7��zӅɄM�p�>xQ�� �JJ�@Zؠ�4*%���NicSI��n�%��3��N�2ʙ�E-EbA^�a�!�cT�SƤ���A�ФS/F�~���>E΄RiQ2��kS����Ξp{ºZ�Ǝ��V0���)ߘpݷ*[����X�`.��r�bꥨ��X���1R���p��`��$�׫���0^�G&]��i�;�M� &F����,�q�'9�w�^����ݼ�o���gN�WbR�T�����4u�)Q�dsb�y�ՙ�Y�F�.���X�?���sW�,���/P5)Z`�n��)�˴����5`�ΟM��}[��P旞Hd�q!��B�Ju9���7L���d6]P¬�#��:��͌�gbj,��_8sR��IV�Ee"�Dj�*����5Z�6����<V��[�t1-�}K��P޶Ԣ�9�jc��`u�0����b ��$-��9�=7��Sv��R��7�t6K<�o�B�֩a���*�du��ܯH�U�ل|1�9���+��K?>�t��V�!	���	Å�ә���P�;B
fB;w�}�ӌ΂��O�����#��T���ØD�<�_e\CRi�>`�*L�����&b%�[VQi�B�(T�-ia��)F�AӸ��@��� <�|�N��(�W���J��;��fcF���5N� &Fv8�{��:�q�F����0~Ȉ��"�[�]�c"��_���� �h0:�A`a��K���7>����4���1L��$HW�N��ヷ�?��㘎���t.	sJL��X���V�'�:C%]h��e0�Ҩ԰g�"{1��}�	�O�4��B���j�P���{2L�>?So ;#H�Q8f,B����c*�s�z�	����l�ͰE	�"�Íl�>,�P�>T��r�T6\�V;>R��j�����&�^��4Z8N	Vq1p���t�<���Y{�3g����^�[��=������,<�$r I¬��ѧU�/�G����~_"�ϣ'�l���G����g���������:�/�界�n�r��?C-X�f~�"�����ʰO���O�|�Jt��q�7�Ƞ�C��fB-;�q귚�{�h`���R\�1N��̻���#� ;�0kbR� �[Y��BB�dNo}H9<�E��Y���u���R� ��v6-Ǽ&���'�=�U���aw�ݑ����
��CD�,5niU9[�>j��#7WJ$,W�EL��,����#~i��� ��k0/aK�F)T�Z���KHZm1q�+!5��s�P�|u5i��]�?# -Y�&��$2��^u��da��f~�"E^�� ����Kf1���{8el��o�TY"���'�=��S�dR°4C���:<�9��+^����y�4�aiV�<�U�9�%�h���O��Cj�_�����4�#T��q����ÐMÓ�x(�Vk�U��V�U���`:��)<�ֿ�3 �8q�b�ʜ*����Us��ɗ}2����- $W�#�Y�TT1Q�@\�&Km\Ɉ �a�Rĵ�+� �MmHF^�Rb��W������>ؚh��⾩����Č���O:�����wMqN���0������M3��\kViоֽMD���l�%�R��hMq��V��E����8~^a��P��Vm��i[0���n���[w�V#|`��y�A�7�GS��o��,�O��C0��L��>����t�~�,}�f�Ϭ�K���"��/�i��es�J릘��>d��6{����JEm�����P���|�ғc�=PO��)���I�jhHñ��Zۤ��9���k�_ �^MJ�BE`���ZAm�rd��)��?t�k�M^����	�S-_�N��[����4i�׆D��k��_�C|�W�Pû��� z6	8�E�^s��}O'�9��ƸN�����z��^������B97�����N��[�����wgF�%q�V�"ΨZ�΢K_-�?U���'l4��#t�'�v�2ҳ_x�Q��#��^�˟|�����]g	��9���YD�o(-$�1�������b�^�J#Tn	�- Ԯ���.U	��� �i�ƅJ]a�����DO��Z��Z�Q�`�I/	�Sd3�h��S{��+�VX�p���wm���V�d�vQ� �� j�v.��G�65��J�l�v4�Y3�Q:e)��i��>���!�Ĝⱬ��V��qY㹌6�^��L������B���s��k�ء�L�<�t�ifM�jJ�Ndϙ$�)R8"�c����C[��9� y�G�]����t��w�4�<��nFi^�Y2�s�<O�.��m0\"��A�|!�d�J���l��v����`�5#h)N�^2l4�;;蜭.$�,���$��˲�;����:*�{/{�|D��o��q*	Yb �-�,�j0��p"���O�0&��c����ږq}m��U1�G��uͻ|��N{�>�sM�m�A*s� �&�JF��l���~K7�Ux_�E3ŞM��8��%������GĆ��W��^���mt@��#X�:
�$&�9	�G�P�aZ�K����ի64�փ�a�M��u��U�V|A�p���r���b��r_%[`���E7M��Ī�kܦ�:��H`������Z��&��rzo�(����򞋖o�DW�F�!�E�㉙��� (ypA���.?@��hf��U���Lد�V���N�ש���!����k�5�WPl~PP�=�%���,�#jut�hA:��i""��QU�ʬ3��?�,ѝ7�sK���fJ����/M*g8����j�%��4s��q8Dp(5��!�,e��6w����']�B������m��G����AP`a#Lf���z	�#_x��Ɖ�kaY�� �H	(S�$�9�/��|��e��s�o�^���!zh���kK;/\�^�����GW�}A�y�d��Ey�d���(ь��aY8��¢`2�o�9�gusc|�%�5/��ڧ���+�����vv�k�>E��h�3�e,,��Q���j���<���x)���(sȉ'O��j��`���Eca]F�2I�m�P�һ5�6�'���.`ٷ'�I\��������J"m9j�nb�%���UqBۋ�����ț���֖��VX�Q�b�/>R[L�la�玱������K/4�&^����ZJ�_*��.�QA\�N��=h��C��}��;�������M.���,Ļ;8^iF�u������(�j����4���h[��W��y�+?�'��sU7��	d�W���],��d�[S�3^i�&�f�46����mޠ5Y�G6��|�Q!4��nA���ǃ����o�d����~ͦɆCѤ���!�<��&?S#�}3�3�h�͇�p���(:�)�P�w�0��e7� ��6Ps�8���T��R2j��8��=�(}����&챕B�L�9��Lɖ�I:ۘ&˖
��)(��݃%x)�����r���ʗ����z{o�O�{q%-���;�mMGo� �}����`�2�"=�6	m��Y��lfe:�@
�y�Y��ǐ�k$��H� �9)����5՚�G�-�R�a8��v��#��D �%�1���]�/���5�Ok�0�-�8�_nh�AЩ��NŜ;7ۊ,�ے>Ji���/�g�H��H$��ι���y��+�K��;�8���j�=�v� ��Q��S߾�"uýs���`ӛW~<�Qҿ���:��Uי+�UP\�@<¦�ȃ�p���$Gt��JD�c�ѻ��t봜8~���[B�L�i���JMܘ��v�������WX�G�a��5���/����[��׸�Y{�rߛΉ[��b���x����/O���la��`�q��x����1NHαKp��\r77��`QFZ�(����>� �E�lo��O�/h��`���x�w�X�v���AC�[���1������!�����\����Q?R.�b�V�Xޖ7@�#?�+�ت�U.�9V>~+��́��ѺlȂ���e.N4s2���j�"&0�r|���~ft�V����~�-����&I^t�cQ�&�k����J%3U/����g�"��O� ������z��*~��46��u��#����ҞT�饦{���G�E���Zmx����z�b�yYG��y��&��,�#�e�`�z��xD��Y�����[�mU}�,+^�Y��Y���Y?��i��Vٽ������v��,�ʪ��n.�W*MƔ��3��pH�9	����'F0�:�2�88.��0��]Tvr�J_�1�|�����~D�H�FxVC�ש�1�ͺ_��Z����*���t�g>z���#aH��<��ܬ5O�����f�%� �������/*��GRE���0b�,�c��YX���\�C�1�������4`�<X_��u4c�(I0kjTZ���҈���d�Z�&|���44��������a�?y��d��\ w�bL+��]ʘ�˅�,�G��!���`�{����ߗ@[B(�(�`@��H(\Ab$�1!e��[A�Rݧ�.0�ʲ2*�"қo�_�P���6�F��A�,}d��?�?ZdC��������{��ŉ� ,��'`x�'c7�^��=��v�.�����of\�Ү.����9ic�$,�nז�L[n٘my>U�k�����sZ���m�G��0W���؁��B�^�X�y�D�W����g��8n('��T�Df|?�vg����M`Ŋ$!D�%Yӫ%���[�QB���ӱ����arMgP
F���jHK��I�_qh�R�%����-�@Nw�*��w��%����0�F���2	O���C$>��~x)YSkߣ���.�|���l�Q�FW�-$�Xv%3��������Jwc�I���B'���< ��_^D�Ðoo���`F(�v������K��Ya�`���Kb�+]�Tr���KQ}S���`C�VI���[�}0��y�./d�PJo)�3W��+ljV��N���!�֓�i�e����v�ϱ{�q�D���-�\�b����7��R_�X7YE�`�:����=�;9�/k� �S�>���b���#�]W�ρHß,�T	m������azSy��{��N��W'PF��h�G�<ڋl��p-��X���d�lD��,%��&ojԸ9oY9<��s$>o!���aZV2C)��#�Dt��Vʗ��&��v�ݐl��G�KFNv��tܨ��r#��0�g���+�	;6a���ڴ��CexQࡱ;;@�w��x��d߲,�8kvEq���=�vb�8	���t�F��Ɯ�]˺A涍y�u�"9��K��El{ȧ;��&	�i#����y��Q�~������^῭��n��V�g`Eq��(7��x�5��g�L����v\y!�'���>��D��a���*�W���I�VU� /�B�p�L^i��Y�`JE0�!����x���q�s��7��/QE���uw{o��+�N�2�,LQ���
�3E�u���
�R4���7�T�"�X�9뒿tEi{�A��m��Z-V}�~��H�a��K�u���,��ժ�Ρ�؍�� �g�׬hH��|��[��o_�#�����w>��(�����Ɠ��9��G��_��;�n��?O���5��%1@�;��c\���Y�eB��� �"�5.���5<��T�4�Y�����T@���sb��|�]Q�|�L�(au����d�5z��b�_�ќ�IpqSE��G�Z<LVQ{��t �����,�?S5���(IY��5���S����v�X���^���'ˑ�8^�%����t?B2��L3+���u�M�}�F߃^K��L����B���cU��D2/���±��y0�<��'����&��Yr���~D���$�G�h+=�<tJ�ɣ�Ά�[�U��c��,y `��D���)AE�����6�?��^<;�w�@�����J�&�! a��G@$��-�r���p�Ǜ IO���T\�iO-�W�M=�
f�L�ߢ�י�<��v1��)l�{�
$����X䑋�� �}K$9{ߞú�0�D�,�"�x�A���O���&.��O��6�y���8�9M���l5�Ot�^�3 ����a���T���� �&~ܝ����ʟs���I}���e�\��xT����s=���"�'����I4������۹��o�]3+��yE�Pn�z\k���qә;�=}0�O]E�yc��L�e�0�m"I�V٭��L��{� �e�)D��@w6�E,P٘�̳�g���T7?ݙg���y&��:��On�*k�ɘۛu����f��9�#a~窋:G}��S���D��~E���(H��0{4g(ud��7\ɻ�91��S=��EV e��o��P^p����ˈ���`����vd�9���1��� �Ã��X�b����e�vӃ��(Qk�Er�q��t)�bQtE�p<����4%����|_:�����΁��.gս)�U�qB�U��}�S�X�v�A��|..[k����9T#IZ|`����xѧ[U��ҞUM�ݚ�����%� ׼)FFF�:⏢K?����u�QREC�l������ڇ�\G�5���Ys��5�(1�	���u���>�*x�^O-�*Lx��%y�(K�T��8Q,�1�)�t/r�C�͉��V�� �I7O��g_�\V�Mo�͜��Y����ʜ�=����$�pOk�5��?d�9�<���ٔ8�%���`�&u��>ڨ^Mj��O=�3�A�Gu��z�]��lsaƳQ,SompqiHϷH�	A l�Ҩy{���7����?h��b�KIj&�D�L*	�P	����,9�i[�0��{�����u\Х�5
��-��"���[y���T�Oha}��)�LDRuHG���7�]��V�֣���e��x����kϳkNYk��6n�q ���W�w�gD�j��ذO��_j8�N���bL)��ϣ`x	�3���G�I�����	 1 ���ov�.׶�"]��Z���W���4p���bp�(B�Я?T/#E����&��n�M��vw�G�q������'�:���X��e��|4p�{4�W�Z���Fu�_��w~��f�~��c|8�]h^�M���e�H�~H�D~���ڛ�w���	����,�J��s�Iah[�؟���ų�+�@fc����D��CP�0�D^�䑁K���]�?�V	5�`�x��H�q8w��w��م�L(9L���H����Ї�D���&ᤊ�uEaU�츧�I�}����0�-]���\%��n�s�$�}{N���(��f�$��N�5/����4y8ޡ^�߱PF�����]�S}�H"�՟jIP&.P3i+�;=F2`�t���޽h�E�w�"�+�n.�.5-س׾�-�3�*����uhT�MSjN���Z]�t�؊���7��
���p�-��r�ٕ��]�������ⷚ�}�YJ�e�� ��o���g���=]˾���h܃�B��!w�ݮm��p�d7'�����N��h���;�r�)"���6��u�DPg�c�#�nn���������������D�?�A�16�v�ѧ�ȆA�X�]Z�6�5ʹ5k�ݫ��$2	/��(׾���3�L��3~�c�=�%!��>K��z�-��z����n���p�y�+H3�b�f����BJ���U��Hd|�VC��4���������ě���֘��;�(H4��y�����4��NB��,N�i/U{!-2�:��}:B6@:)fyW^0�{r� "���֐i������;���QK��M��j钕����Q�/W!�f&.��tB����l}q�q- �F��t4>���3�����_+�2k%��[y�³o����Q�DK-�����Ӄ��nv���6��̵d	�1�+6k�ǵ���E�&g��/�a�u��y����F�n y���j�E��糘�H�*:�C�� f
��&�#DH�s��3�J��/���.0���捞�!�m`��r'�n�3����_��-����[�W�_+���_w6 �H�n6`ܴ?0<���dbLVE_�ޗ_`��W8E���u4�6��X�\��'��r��-�e�#
z8��h��L�*o�F(�ek��ah�W�!^�.���\�'*t�}��Kq���1B3�R���`�2AG��N�Q�>����ȱw�L�� 5HhV�d�)�K�r��d� iS��+o�S��v;�w��3af����r�>!T,�6�;�Y[m�~��wD���6�C�:O{�6[�	��V������ȢV�13�p�e���|�a��Ed�C1�����)���=��;}t��+s�D��9��ł�$Jˁ،X�2N�|/b^]`�\����d�[���.PL�Q����x6Q7S�|���`].�TZ���	(�tm�l.�NyVTȳ��W��O~���qK�,�E}�O�����	��)y(Ն�m���|�As4a��"�-��{��2X�l.���6��Oa	v�1K+2��_��ݢ��-;�joO'��G�	{4)Y��̀v%�8��ك�;�B(�M���+Sz֕�����c\�"=��oZ�
1��n�|�/��3��\��%������0Q�&`=�Û	T���0@�o��ķ��)�ɺ�j~♀t��M{�P�H�P���S�h�z�E�uς�ق��BqV([�\���'����Hޯ�g��C|Dn��� �6���54�2��]�9�᫯� ̰Ǿ���~�(<=�gQ��Ӄ�:U�B�wʅ=�0�
A���M:�W!l��s�p���j>m��y'��r�㝅�8��6)�NVd�ӥh��>��� �꾉�>��Ø1�̽UEm�?��e���I*�m<�WM�JJ9};6�����<�A���il*bX�u~���߹�,ݳ%�C�o}G���(]/�(ixv㳌t��%��x�TK%�W,�����s�����"����C�g��Y&�p�C+IGq������g���\���X:lh(�h6���é7���W�I��ǰ?�����$m�\�� �l'�uK$�=C�)���T	EΈ�*MV�f���pE�;fb�
s$Go�M���DhwU֊�"R^�F��M�T�x
 t!FB~䈈����@���"(��{�(��_��6"����6SM
��D"��9�	�l���Y�%&dҸ4nY�b�&s�{�$
����OM�L�d��l=��Ř�5@�Q��R+3-�Vv*xvc�e��-�,��N6s�m��W�)��匱2�"߈L����4�`'dѴD�q?k/T'�����֔�A���k�f�E�t�+F|��m/�舅����B˪15m���]:�V�����Co�_"�Е7F	LST{�� ��)��ʷȕ�zU{FAR�/����x	M|�	2|`2b%��M���Q$X�W���+������co������0���Z���d��Ǎb�V�?_j� 	�W�im<�2��[0ߙ���W�_���2���;������e���m����]K38O�.���6 �0R�[W�Y�~���l@�\���E�EjL��;,�����y�{Qc�Y�"o0�I�b�zbҴ�y&���}��g	?x�)wr��Z}^_Q���j��:����@�X��R���1{`m���j�����,�g�L��L#�E	�gYA�1��e笃������9�H/�s6]�Ң�2�%}��@�oix��-�cN3��x!��c�mSZ���Uu���'����B*:��$=��Q�ހ�U�
J�8n��2��v�Ҍ(�4��8w���������"2؆�F']��7�	q��O��Ǐ����?�����������_gy_r��6�����Vc���e���E�o�n���60k'ߘ��S�Yk�.Y��U�	iG���tcp�N��;lt�T�L%M��fNYz{�Gǽ��c��<r4D�����%�)<���@?���gc�d�m��ix��&�q�Nߴ�Y�n]��z�e���4�����XSG�ɺ��c�����Qc�hGg5��C{Lxt뇣�=��'q.�t�g��u�Ce��O<X���0m*�Q�Uu�$���eߓ;,5T���/&��LH�הX���J�J*9�Hw��ɱ�3�c��6�z^1���"cz����z2c�0m�����癜P����������Q��4`�C�I�b����"�L6I����5W��ٗ�QD���T��&�m��b�_]�B_�5_r�4��ϰֆ��(x�F�=�?�D�y�h�&	�b���େxo��gֵ.l��XS����c���q�c-��ț��`�6/�<�&��}���Y���7ph��B�b�yN�j;=���d��և�����.L�p.Bh�gu�o%�F��@{ߟ�w	��F�w�ѓG+�����	[M8f"����z �P��z,!!B��0�C��9/=�%v"ґ��2�7�K��}��)=G��|�x5ʹæ�k\�#D�g���4�A���ږ�*YCK�Or>�$����: lڋ�X j�����"�^OF�7di���o1�}�	��~�Þpq�0j�S��0Wb�ބHv�E�z꣩?A�1�g���ل�jn���K������N^ј"����mz�l?��9�nӟ��5�*��U���w�����j�8�U�����=���lUl����b�ֻ��R�tw�y�����d,`8h���J��G[[9����������r:`��Ŀ`��B	t���5���aqK9����x15ǹ"�\V����9��|���k.�[�a����ygj�˥wKa����&8X�	����pB�2�c��/�~��1v����ـ�sJ:b��C��zy�x�E�TP&��fE��x6�79��뱞�0�6'c�`H"u��>>��/L�VG��=#��$�t�%8���4(��B�'��:��΢Lb��F�����7�4�-) �<��u9>�l�î{ ���8tr�{�Af$ ���3ڦ�ΥmE��Ԣ��kzV9F�/N�(��'�	�C_E
t�N�/�߉e��{���)�ԠC*Z9�����..�TL;�x�s������:�����ƞ��Ӥ�铖H ԃ��iI6aIv�_ϟ&|a>-Z��:�-���>`��ڳK�M���G
�Rj�EKx۠[C�+!�Y�-�h���q|x=��0h�c���;��цII�i�i�4]�F:V�%��C-M"��R$i�,nA��Zb�C��`0�:Xt�����j�������6���B1�Ԋ�}|F^+45���2G��gN��X,� ����|�.�fɧ^S�o"^���{�~�����G��d@w0�٬��fEߞ$p�i����ͳƾ�T:K��X��+-l�x7���Q�Ҥp�]2��!C��M�e�����1^��۞A>n�N�������x�=��}_@�v ��%�o'��hl���0���߷Կ���d;{��l>^���"�������]�Zol����Q��]�����7�Wi�LF�����y� ��r�� m���0����2�J�3�����2���*ɝ�_��!}#nc�W�*���Vw�)-_�+���[��
�u��J]�-^�绞�_�8�J�c�O����m��hBvB\�g:`#��e�0��>3N��/�"���g�-(CN� 1hPF15�(*�B���ȣ�$�4s,?� �\��������>�m,�d����Jl��Zϵ1�舅�I�^8�e�b>��(s�}g�f�"Ky�y,@i�"�(2�cp+��L�m\�$���CW4�v0E=������L�N�h8�偨��t�k�oi]#�k�}�"�{�W��p��DT�7@�hO<���Ϝ�͒�kO�ȢF@��F�d�r�}�8�q��_��o;����n���/��?Jh!�����3?�@�1+�C�y����Kd�Gj�q��>_�h^��8��Q�(�.�Xr3�[�������:�
�dŉ?�ez/���\�:Ի���A��U�c�H��)��^� ��I�6����V����TF52�׎p�G�� �/��ϙȮV�,DY�R���;�#�jT�H˚u�M�r������*�����%5��G&m�a$6�G��1W������T���;��F���rMbd"�,�*�${��wƣ�@M���.�~{�o���i���^hnT�K�bc���b��S�?1��%pd���r�v����&1km��U�>�(�6 ��'tkxWT�S�,EH��h�N˻(M�#`��+CU��F�����hH��h���âBNH	Y�Z���|��yjb��ğ7��u� ���K7��bG�6:��;�ݴ7��t'�@U4���"�Y=����S�Bca䜟���>�C�:̴�א�ՆuX=��:/M���|U0ī�1����z�7��
��K4�nb�2�]}V��g�Y}V��g�Y}V��g�Y}V��g�Y}V��g�Y}V��g�Y}V��g�Y}V��g���?�Tl � 