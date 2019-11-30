#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4119861063"
MD5="02878fa3bea2ebe5b5cb8b75e909dcfb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21492"
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
	echo Date of packaging: Fri Nov 29 21:00:45 -03 2019
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
� -��]�<�v�8�y�M�O�tS�|K�=�YE�ulK+�Iz�J�d��!H�n��_���|�|B~l� ^@���twfv6z�D�P(��u���i����~7��4���󨹵󬱵����~�h667���G_���yd��{}�}��G?u�1���s�S�{k{�������#��������>�]}b�s���џ�R=s�%�m�%3j��t�<1C�cy�r&��`C���(`t��6u�����A�R}��<w�4�[�-�z #�H��7w��F�Gh�l�~�P�sJTY�Ub3�AH�	�w��N^���NF� &�� �\��Ӏ̼��8��f� JN���_��
��=�������h$�����PkOդ3>9����Q���X!Y�\o�CM�φ�q�e�M����9u�Qo�y�e�m�e��5|a�(W)
���! +�#
����^p]�;ls@{F����}�׊kQ��}�9W�����`~��5�ƺ����9;���(3[Y��Znp	�
�a. �z���j��QP��7��	l�2�Ft��eO6n�RIx��_�Cק�;^!�H�X����	��tzA c�} ĞE�Gt1��Q8��A��(P*S3$:��<�"�����a�o��'�[t�����T��L�1H#�MXLeU�JEP��>t�9�Ӻ��$�����M@���ZFmvxz��n�	-j-Q�)*'(����q�������h�[R�����e�`�0c6��'�7]Y�w�A2���(s>uj��e2�A��&TVհ��&ڕ��6�ܼ�Q|��XtfFN�� H+�aީ�D§�(e�i�T�����v־�ؠ/�P��v���/���.�Aw�?n�b���M�l��7莠-�M>�>�UR�Y�"{�0�e�G�K��z���ԴR�N\E�N�	!hq��b��XJQG�H�QR��IB"�����)��Ma%�V��0m7�T�'NV���</,�O��ib,�j,��>�:5Q�<D��*�`2;� �+�R�M ,����[Q�6�<��Y��mwN��Ԫ�W���no���67���-L���_��»D�1��I{J�Iz>x>��y�&+��TF��G>�{n�0v1]�W���� ��$/����_L�� ����=�sss���� �U��-��j��^t��{�!�Q[�5�b��i�N�Gg���\�$�Eda^s����Ga���dϦ�$�>Yx�=�!'�`��qJ���|Y`5��̀��NV�1�_"W��C��h�mQ�^�2
�L�\�eԙ3�GH<#��[�@�tbd�c:�#�a�=]O��mO�2E%��Y�;��+G�_���xD{n&L`��2��3�F<ӡ��:y����{��uM�[�8��j�����%��������%���WmَE�:;���?l������������?����7��������3�\�0��Єԇpd�����w@�ԥ;H !��_ģ���d�����_�nk��Z�g[_ȱ+U��t���|��X���8�3-���	�M,�-?�w`�K��b����X�Rx�t�ocݹ�To�{h�p<�'i%�f,�u��XfX�O�����T=�Dn��u�) �L,�]z9�8��	/����aǶ]���H�Ǉ��̜*)9͌��z����9�a���Ddl��g�����slҁ�zhΙP���ָ1n�&�2>�>�[���G,�{�9TUk%`�C �8i��l^D9�wZÎ��9��`���D�^�F�����ȥ�-i��%A/v�' �2�~���9((�܍V֕��\@bJ3W^�+=�B�qu87BeX0�� ]J^Ǿ'�$��f���Q�pXt�S��D_f/&���S��]!xr��a�gf�/�Dcw/~u��ARC.��:��|�T���_Iw%L'/Q]:o:`v.���9r{q����6�J�Z�R�ATu��s��ں�6�Ö��p��H�Tyƛ�'pO�E�]Z!!��*� �
8Y�n48;}IRC>�QX�ϱ�Ɋ�Yohpj
6^��ݬ�}�N{z�C��`���#�����ٛ��I�;7!:�� �C�<|u:j�r�X2�m]ޫ:�c}��Z��TK�O��fu��%��h#��R|jUq�Sº��<əc��� 	�=D<��CxAe�(��b����@(&<\Q�cS�V����;�ٹ��B�n�Hɺ+�m�)Xx�����r2��ԖI�6�G��a���G��Y�H���7L�EDEڃ�p( �>@�z�"Z{���jK%������w�"�P�ˍ��B��-��T�;	�8���ਤ�E��׊���Ob��W�OX���BVҽ����.��e���ֈ��,`ڋ��	�H'�`�Z&�&�O��78iߪDX-��*�,�D���شV��*��4�_����P�d}�W��3�
��:��Y�J��"\�JvYZ��|w�Tb�J�[�����/���v�8\��2�����3 OE��d<z��L��L�pS�e�m>�K�O�>$����E�HN�\м�~��m��m�cH6d��a�0�-�{^8��ʖ\�dx���GB*q{[j�����Ƈ=4��ӃA�{0��p�A�)�x��fKT_�5<qv	5�K��CN΃��!)}9oKb
��呄X�]�,W*C�b�7��
�{�9l������2I�mעW��K����x���O^k.�L8����/_��׌��	�4j���~�2����������γ�����X��Lga���_�^ �����`=x@��̞8��v9B<��]l��c�u�^W�׿�K���x��4�j\�2�]K������o2��Fc�Ϝ�7���0<x)��L4?�}���3�ң�Z�I<�y�i-`���uPz@}��.�x�r6�(AB8%wϏ+�CT�3�?AwH]Ħu�<��,���$�l7���ó��_��Ήa���ߓ�h4���WԵ������sz��}'����6vww��h�;���Ds���s�7�(���8����4���:oB�xI�˘!P<-�cU�!K�f���^z������\�|`L����Te�+#rƛ���"`�o���������*����%�H"�����-���j�a[?M3� Mj�{k'�F�r$R��4EI�<E<����-�zd��Ԝ�Z�}��R��]�B�3s�`z��@'���M`Lؓ�9�ߖSgo�
�C�s �|G/'j�����P��nQe��b��c�0�o�Y
#�G`�o�����'�П~Ƙ t�]����������Hb[H��YxC�Hr�#,B�¸n�.�]��\��ə$Do�y����r�ݨ3�HM�����Q��	.Vh.(.l���Ƃ��f�ǖ8xhA��ZH���Ք�>��u*!i�>�V�,�:�B�x���	�EK|lX���SE^l2 ���"�*�g<Nj�����jG���qG �{��`�B�I����^�N$�H���!���(����Vk2T�9]J�.Ka�|������WWH1�O�V��1�i��'�b?�v�h$n2k9�{p��L-5(�?cq��DÍ|	����h*�-Lȫ�<3A�[M|�c=���x�=)#�F1�_�3w�p��a�cF���ڋ��|0���Ef`{D\�қz�_j$O&��aefC��ޥK��㤑�8�\�:���!�D���
@���ac.�����X���]hD�5�x옿�.c�Y�\ڿ�A���j�1���/���_�x~��8)���"�*ƙ�f�4��_֛�yYg��5��HQV��Qa0�����-��M�K0�D$������P��<yb�}�O���Ĝ�O�����}��F?qhz�`��[9�⍒�e?�6XW�A�)��.;��s.��
oGL�޼+%���&vֆ�}r�jQ��M�-����P�rꑸ�#�2=]H��Z���ug��*ʵ�K�i?���S3�uo�r�p'����l��u!fL�O��`�޹G����\g��`,emF�� &>e+�xg�1��?s=G���0�Zi‧����;�� 5iSc
!m�l4r�b1����`d�!J��I.��Ľ��ڀ�_�i�T,��޽�R��b	Sӻ
��Q����Mq�����"���w��%:3�"{�L�޹�e+�{�\������y���8#�-���Kq�<�g,��_���c��I�,�&ԍF��z���h+�\�p%���N��CV��@_P��=¾�F��s|���e@��B�/�<tb�H��^P��VZwy�h1o�n[�]���#�̀�=ͤ�/����zj.��m���z{Z�"|D�sE���7�B��iH���5�Qi<1)��|�U��.c�I	�N�e��`"X�nC�QT��`@W�F>nD��횎13A�DӵO�V�o1� )s;Rpf�_���sy������Yxmρ�����"��I�1+�����ҫP����}�/�} ��?Q(�]�t�r ؜o	h)"!R��X޸��L=�¤�y-V��^����!j��}���a@i�k_pg?Ϥ��-��i^���^t�SXʒv�B�߻y���C�x�+Ӊ�Q���7��[��[�@�v��k�F���҄�w[���ٸ;�$	�Na�{!;���n���A�Åx|�����<���txS��������Ω��箷��n�i�\�욅t��m�E�8�Bh!�
v)� y�E����ÅSGC�Җ������"�����$KgK|v�eb����H��l�F��Mf������KHE�Y@���]�(e���7�`��eM�����@��)m�c�8���tϱ�ywk���du�ce���E0����Vɑ�̲�, *�jy�USV�,a�si&�+3�d�b?,:vj��^�s�3D�q��V�~�.4saALJ>m���î����;(UM�Bsa@��#��@X���)�P�!�������#�x�J��U�J�~���V�_Os���X���'� X
�)�� Url~��'J` ��S	H6w.����/d�٪K `Zr�/'�xK��B��Q&�����hRrJ/��Y	c�eґ�:՘�� ����3��"JR�ǏB�Њ}���1�K9$uƱ�)��B�U�a�`����j�H]"�6V�Ҿ8?�z�_��|� Bpm-0oK;�ưD䇑��l�!\���ihlƉtRq@�,u�B9���(F#��윀��:��I�j�H�"���w���D��+.N�r�#���1ſ�g(����>������q����R�'�1t&��]�YwZ��:�!X˜J�����8��%�Q%�C�F��$��֍H�w<jr�|�0ɼ�B�_�Zd�Y����bT�Ս�~]]����95��V���g� �	��K��h��}[wG�漢~E��1I�  uiQP$B2ۼ���[��)E�, ��*��e�٧9��/�gf�?���ʬ�@��=3�9���gdddd���᫾�"��*��X�aO����,S�C�l�����%@O�W��ӯ�Ս�ү��;�n�d��;�lI��ov��xtO���c�U������a0���B�䯱�*u�&=��t��̮���QvS�n������z��{�W�	u�#$���X�UuO��$Rh�V/G�9������^ј��>+SE �W�9�<�Z���L{�b�W�d�\����`���-�-g:*�yYmݨVgt�1FeAZ���*��"�Xet���9%Ս���[����p-�hQNl�5������G�h�7��M��fT�B7�tt��$�3�&�hLD��<�ǃ�hW-"��dƭ�V�!�	���{�5�=�K�H.G��4)RzT��|"CnLӚ�L-Fr�g�A?O� ������v��xȿ�b�;F���$����AXK���0��Hͦ�;/��d�_�s�����.t�O�ռI�����?F���Z��@���Z���u���.m��4�*�V�h_U�aȫ���%D�2��r:�sY�&��r��w޿�}�e��a��)�E��I���cND
�ay����{��v@#_Q�ƿ�_o8�� ��PVhV|����&_��E?��AO�s]o5��t�O��l8�oD%�+°�78���O�p*��bo�v1Q �D1����H�L��!ŭ�H��I�*����"�1Ϡ���KEܖ�Y0�$&��u��R���f���=�#W��Rr��>�0��۬% �/�!���M$(뢜k��g�lpf�# �.*����"*aw�w�d��Z�fj��������m*Xz��[��+�S֤W�O����&�R'=f�t�Nut���`��o��x \�,�}BݼD���L	��'���3� ,��@O�}n�A�֮����Q\enhT�lclw=9�b#��q�]O/�a�J��W��ӦԄ"Z+wxN}n�o&�7���^�*i��I�L!3by�/O�0n�%5n8� ȓٲ�ł���p��-�G7=���5���ȦK�� w:�9ŵ2��P���{_Uh&��ͯ&Н 10�1b���=�|k��~��l�5�X!`��S������3>�Z%%C��{�B�}t?��Kq�1t�����&Cnm����adS�x>�Y:�`H��i)��{+B�|��3�Ɏ�D������"ӹ/��)G�q�Zr#����i�x����n�����Tf�%sؾg�M�F�6��'&O�ɽ�%�vP��)�M�����3��z�����7�┎�s���_�^<�9.=n�w�qt+R���C�$�ewJ�T��V�/���{7���+y��z�Ͽ�Q�Ϻc/��w���r;�{Y���>G�ˑ�q$���ݏ�Q��~��y_�Ouwm�o��rr�;��B�g�RnG�	�lR����~�LA[��ռN[۳�����1<�ү�Iʭ]���)fq�w���hmh`fR�ץyq�.����r��&���JY��].J)w�c4\����ޏ����ڃ��m���)?�fQ��5;f:��0ŧ?��[[E,$G����5y~�
�3D4 � �#�e%�󐮭���b����iN��Ul�Q�jc��c r|�	W�g�9�Z���]= Z����R��ٓy��JT7*����uB���]|�mw��,��g��-VS��V����\��%��ʃ����b�
 (*f���� 9AnT�2Y���g1����[��ǵ��:0ٷ�C��!�Q��UB:f��C�,�n��%��`
��l�䯝Y���΢��H�K�o�*:2��KE������֬6C�Plc�*�M��3"�@# �k�����Jk}re��k�����G�m�6]8�!0��{z�������s�������*��	���ILo`�}��kK�����[��:��ԅq�T��_!�W�%T�4|o쫲�xV��y��Fz��.��[�e�H�F������y	���l�M��ɷ��,�s�f=T�l���r�ʺ�,��u]���?#�'(����9?�;xVY�y�Ώ6���rJ���3W�����
0.iu�L�U\@��AMHؾm,��.V~�}�Q8E��|ʰ�k�D����3N�kg�S����5�Q#�a�,�x�����4������%��bT���-nG��CND��F�����2�(�֬!g�d���Vs������\��X�-��J��6k�͂�f���p�$�����a�&�� �s��!�`�Q�+8�|�K��������D5_��)��?z��gߵ�{����վ
Ga�.�2J�w��n�UY;��6v���52������W��n+}�;}	�7�]|��v�t�ND�F�\ɪj,��F��l�H����*`;}ΑfE3�q��������Nn������K��z-}�MQ�'��j����� @�q>�*�z���d�:N��K��m��F��b��2���6�#��XNN�����cr��2� ���8��{r������!^;���	=B�A�d��Sq�jb��6����23[Ev���Vg.�~���岯�7s@������r�4.�Z���;�`]W�mRe��<h�q���,�7zJf��u�~�&CF����tr������[k�G��5˘�C�V��7t=�|�h7��B�Ь4'd��	C�Y-���tI����O�~^ᾏ^��˘�q��i$)��T�G3�2і9�����+�=�P~��UT��u�[H��PJ��	���~�uf5`**�Ӟj-ElWт�S��%hUi�#|����u�iC��)�O��)��5�2�Ņ�XH�o��O���7���a�D҂�\����������l�� |6��J; [W�>B��H'\ۘ;��4�L��"+������Ig���v��R��P6��tr��A�톒�Ŷ g��w��Ѫ��0}*l7��zӅɄM�p�>xQ�� �JJ�@Zؠ�4*%���NicSI��n�%��3��N�2ʙ�E-EbA^�a�!�cT�SƤ���A�ФS/F�~���>E΄RiQ2��kS����Ξp{ºZ�Ǝ��V0���)ߘpݷ*[����X�`.��r�bꥨ��X���1R���p��`��$�׫���0^�G&]��i�;�M� &F����,�q�'9�w�^����ݼ�o���gN�WbR�T�����4u�)Q�dsb�y�ՙ�Y�F�.���X�?���sW�,���/P5)Z`�n��)�˴����5`�ΟM��}[��P旞Hd�q!��B�Ju9���7L���d6]P¬�#��:��͌�gbj,��_8sR��IV�Ee"�Dj�*����5Z�6����<V��[�t1-�}K��P޶Ԣ�9�jc��`u�0����b ��$-��9�=7��Sv��R��7�t6K<�o�B�֩a���*�du��ܯH�U�ل|1�9���+��K?>�t��V�!	���	Å�ә���P�;B
fB;w�}�ӌ΂��O�����#��T���ØD�<�_e\CRi�>`�*L�����&b%�[VQi�B�(T�-ia��)F�AӸ��@��� <�|�N��(�W���J��;��fcF���5N� &Fv8�{��:�q�F����0~Ȉ��"�[�]�c"��_���� �h0:�A`a��K���7>����4���1L��$HW�N��ヷ�?��㘎���t.	sJL��X���V�'�:C%]h��e0�Ҩ԰g�"{1��}�	�O�4��B���j�P���{2L�>?So ;#H�Q8f,B����c*�s�z�	����l�ͰE	�"�Íl�>,�P�>T��r�T6\�V;>R��j�����&�^��4Z8N	Vq1p���t�<���Y{�3g����^�[��=������,<�$r I¬��ѧU�/�G����~_"�ϣ'�l���G�����*����?���qu*_2��+���.
R�Z����Ev/O#�a�@7g������ȭ��1n�A��~̈́ZvL��o5�G������[���c�<ru�w?G�v42a�ĤA�5���х��ɜ�$44��rxh�B~�N��\壥8*��lZ�yM��AO�{��$J�!��.�#ב�Ç�&fYj�Ҫr��z}�~�Gn��,HX�����YL˿�G�����2�`^�!�R�ҵT7�����b�WBj�������j8�ܳ�HF@6Z�,�M
d�Idқ������z1��JE���DA{���b.a��p��n;ߺ��D��ON{t3��ɤ�ai�,4~#}ux�s��W�x#��;�i�Ҭ@y�*�)s$K<<z���ɟ�ч�|��ۯ�Vi�G�A=�(u��!��'U�P$��:���6��1���6tn/.Sx̭�g $q��/�H3�9U�#ZA��T��/�d�SU[@H�Fj����"b�����M��ڸ�-@&Ê��k�W|���������8ǯ����R�A}�5�<��}S?W�q�7�n�t��퓽�:*.��6���a^c9x=���fD���*�Ҡ}�{����C3��K֥
KК⎥���(&�1q�.�&�����fm��`4;����1r��L�F<��v�����o֏���/��2�Y�{/�>Շ`N����}Z������Y�v�>�Yu��#~�E��_>�B7��>��M1o�?|�f1m�<E���L	g3��[�`��'ǈ{��rAS������А�c��5��Io?r
y��>�@0����������������9�S��2�V�����r�Z���Ƿ���3�i��?�� ׼Ͽ����F��wiY�2@�lp�h���;�"��N�sq��� ��7����)bկ��rn2��+[#�B�����!^����?J�,��E�Q�:�E��Z�>�M�-N�h<��G,��O���<e�g��f���G0O�x�?�B#!�yɻ>�^{s�������PZH2cJ1��a%Eņ�R�F��"[ �]���)*\�f5��Ӑ9����(FIk����1�,9���V%��g�^N��f�����NiW ����L�/���ܧ˭��T� 2CԸ�\s�JmjbE���T�hR�fR�t�Rb���?v}�;D5C��9�cY%�ik����smf���������L�=T�d�9*��C��"y.d�*�̚�	Ԕ�Ȟ3I 7R�pD��������$�s���5���#.I鶉�i*y�G݌Ҽʳd�y�D]P-�`�D��|��B2��`G���c��~/C��>�kF�R�4+�d�hvwv�9[]H �YnAI6�
�e�wkuT��^����P{�p��T��$@�[X,�` ;�0D����DaL^u��'H���-���0{�b��>A�w��!��:}����R�T���M���U�,����,n>�����f�=���q*oKdU3����{�:��NF��>���G�ju�IL\s�)�
���(�����#H�W9lh:�a�����N���`W��-���6�2���4������J��d;s�n
�Z��U�׸Mku~���RqyM��ԗM�!>���JQ��ױ�=-���� D�rC�.�3AI3AP���"l	]~��$*��>q���C��_��t;��v�S�<=C0ɉ��hkj�������{2K0F;�YJG���hЂtfw�DD ���YgJ7;~�Y�;o�z/w�&��%T	�_�T�p��3�~K@	i��O��p��.Pj��C Y�0�m� OM�O�2�6^�%�����2�.Um�	����F��^$��o��G���F������DA4�P�I<s*_H=�"��<�M����F�C��Ó�2&�v^�0��h���H���!���d�r���T%ȪדQ�Y�òp���E�d�ߐs������"bKFk^:5�O�3"�W���8.�@}����g��XX~�z���d)oy����Rd1��Q�O�<a��U��`��º�e���֡*^�wk�mZ%N���]��oO��(�4��3�?���m�D�r�J%�4�bK2���ℶ5���7Ys+�-]k��Z�V�F3^|���$���P�c}���1�^h$%L�/�
��L�T��!\����*P�~9{�~��2I���w���kk���\�IY�wwp�Ҍ��c7��Q��>��	�i��MѶ$
G���$W~`N�]!��n���~�.Ds15�X��Ɍ�� g�҄Mv�.+hlH1=BۼAk�r�lP�)�R�Bhx	݂��;���i.'ި������(�M�5��I�;rC�1xL�M~
�Fb5� f�g�і�����QtFSl�V3�`l��n&A6��m��jq�ͻ�Bu�d�:?Hqzs{<P�^���M�c+�4��sl-���-�t�1L�-^�S,PL��K�R2�j�d���/�ju������ ��JZ��w �ۚ"��|A�� ��	rW�0e|Ez�Im$�*�������tZ�T�z���c�!��H���@�sR���u7j>�5k�\["��p��Q�2/G~$(�@ZJcһ�J_���	k0�֒a�[nq����h��S'#�>�9wn��Y�%}�Ҧ��_��R�Dc5�H���s���� �WJ���wJ7p����`{��A���+���}IE�{�LC�9
�,�7��x䣤��Cuë�3Wt��� �x�M]�c�P�I����1��h���w3,���i9q�.5�������\i����1���v���?b_3�.���FÔ�kjh{_4���)B��+��q����7��0����)�.YW/^�������8�:g��Oj��c�:��c����n0n����*��lQb/z�'}~A�z���}��_�i�h	1�`�P�,$���Ճ�$���+fc�#2+c=�/B2�v��4�-<)R�~�\��6�-o8�.�G~�W�Ue�\*s�|�Vři�uِ!G�U�\�h�dHE��DL`�E��������ƭ:����[ع�)�M���Ǣ�0M��ƻ1R��Jf��^%yq�EnןzA6#3�,��8sU���ilR[�.�-F~��K�=���KM��k����㽵�������?Ď�&��X&M�'�Y G�K/ʒ1���0'�������ڪ��YV�(�D�l!�~:+f�A��{��;01����Y��U���\�� T��)ˁg���s2�O�*`"�u�e�qp\Z=a1����䐕�Xc��7����^���H�S/Bc�u���X雇U���|�|�F=�G*��y*K�Y#j��s!K;��Jl!@0x��7XY( �,_T|古�
a�0YƦó�LU�,�2�:bxyc5��Gi�fy��+�9�h��Q�`�Ԩ���������z��#L�]gih
3��9)*�y�27
~���z˹@�BŘ0(V����1���Y���C����< �����/���P�Q���c�P���H�cB�@�j��O�]`<0�eeT��E�7��R�J�MmX��#"��	X6�����{�ȆD�c/�5�#����1�AX�O��O�n$ �&�{l	��']@����̸p�]]27+Cs��pIX"ݮ-ۙ�ܲ1��|�jת����j�e+���a�*3���3ÅN�N����������N�q4�P,N��$���~��.�j}���IB�tK��WKN÷�&�m��0iO�c%�������.A3Ԑ�&����Ф��K��E[t��"�VUaﲷKvEa��l{�e��+�.H|����R��־G�?]Z������>ʍ�(�[$H���Jf0%.u5n-vii#��Ƅ����N�}y@~翼$�҇!>��(�d��P��L[1�<��%��V�n�����W�2̩�*q�����d�Y��ĭ�n�����`���<�]^��E���RRg�d�W���:s���;B40�'S�"�V37:�=�8�c�0���h�[�����_�o � ���n��8�� uǛ�=z^wr�_��Ax�f}�7��&��G.�����?Y���.P'S��%:����2���^��ۯN�����n��ex�3؞��Zl�9�ʿ��
و<^�XJ��M��.�qs��rx�'�H|�0B�":�ô�d�R%GL����k-��/��L
7�6l�!��������>���Q��F$�a6B�QwW.�vl�B9��iY����Ccw
v�F�(o�"��ɾeYq���*�s{����qU霍,��9��u��m����Er��+�0�����Ow��L��F�g����ѣ�7���������
�m��v[���x?+�'�D���] ��9 �\<�fj��׵����=d��G�!�%�=�S�U	�R�N��ް��y�B���g�J+m��S*��l�+������������Q$x�**|������{K__�w��1ga�*����U�)��k�7U8��y��[��i�~����
�Y����+�H۫����Gh�'�j����fG�u��\��S�/d�ep\�VEvM��nd\1p>��fEC������*G�~�ZxY��O��aMF���l6�l?��no�������sˆ�y��Ǡ�)�/�j�I��
�\���/�-�	�q�$��� =�J��嵇����F��{^�#�"���+fbE	�`��G'{��K�p��*��$L���*"�o8J���a��ګ��0$��P�Lg����1�GI�B��Gp��r���w�{��/�:�'>Y�<��
,Y�����Y�g�Y�o���6��ZZ��gZ ^� g��t�b��%�y�}g���σi�1�>��m�(�4Qvϒ��8��#�P��&�?bG#X�A�S�O�t6����S�g���'J�N	*�5�6���I/��i��> r��֧T:4A� {�="9�m��DX����?�hHzjD���N{j�jm�YT0�e�?�Uw����9\����`MOaCߣT a����"�\�A�["1���������%
eQ1����xt|��΀6q�<}�'��̫�.�	��iR�d��|�X�S�� N�E�.����x 7���$���'z��J��'��B���s�&�QՊO��\�k�����V�'ѸO�o��F�1wͬ|��B���q�Qk�N�Mg����l>u���[@3��y�t,���LP$�[e�֚O0���8��uG�٘W�@ec�3�f�9�S��tg�a>���[��F?�ͪ�}'cno�Qd�>��M��|�����.���ʗN��g��vd�i1�e�o� A�O��ќ�ԑR�p$�f��~O1�7Y���b�EN�W@y���÷g.#Z&������ۑ��@£�4^R���Wc��������M�'�D�����i�Q��?H�m���E�����z`Ӕ �F��}9����N:Fz��U��xWE�	�VTD��I�KL�ba۵q�|l���k��Pm��%i��Z��E�nUYK{b<T5�wk��k�җ�\�aH�?�.�xR�����KXDI��U|�B���k~r�����f�Ģ���d'�L��v��T���z=���F�0�M���)�,5RQp>�D�`ƨ���e��A]6'
xbZ]$b8'�<a?{�}�reX7�7s��g�z�+s���\�J.p&��=����"�������~�cdSL���`�+��z�Աc�h�z5�]D�?� ψ�ES�w׳ͅ�F�L9H���ť!=�"y&��iJ���	h��c�F�ƃ�����)6,%���q2�$�B%4jOk���8�mH����Q��ow�qA�>�(���Ƌx�"o�٫�S)?�������3I��!5�߼v1f<Z	�Z��WO<����q��z�-<Ϯm8e�i��ڸ�����j_A{`���ͪU�c�>�B��:��Ƌ1i���?���%p��b*�'},�6��' � d��*�٭r�\����tA6pk�ۚ{_M?�T����9ۋ�]����B��Pm��	h���?� 8���7������=�=����7�
��0xT�c�O�!����q��p_ak	�?4ա���e�����i��|v�=xA6�/X#�a#}�!���K�ko.���&�7.G�d+�F�]'��m�c2C�6�ί�����>��5�FA84�ly�G.�{�sv	�(Z%���]l86�yb#e��ܙ��%�g�2��0���"}�CNH����*���Uѳ�
&����Sh�d�tQ�[p��K��������=8�;6x��X��� v;�ּl�k�4��<x�z}��B!���΃�v�O�i�#� V�%A��@5̤�\��ɀ}Ӂfv{��-e߭�|�4�����Դ`�^������P$����*֡Q�/4iL�95J�kuDӅb+"n�G��+�����P��fW��wzb�����j��-kd)q��V���*���۞��t-�j8_�ap�����v���:��ݜdSk�?:�>�MOW�K�xʩ��,�.`j���O�ֹA�-��.�����I7��o�_���ۢ3y�����4��F��#)b�wiڈ��4�֬!w���P�$���\�k��X|3I����i�p���/�,��z��`�C�]O���Oo�i�� �|�Q���g�
)M`֛V1�#���Zݲ�Ұ3��_�C֒�o�n2SXc���l� �S\�����o��;	ُ�8Q��T텴�d����� 餘�]y���10�`�[C�A�GZ�7츂?�F-Y>7=*��KVJ:@C�
G��P\�����8��	�����ŭ�e��{�
�a�����,22fG|�<ˬ�l[Xn�i�n����7G�-�0�R�O^v���{h�K3ג%��`�ج5��2�k��MҾ�	֡��]��?�����-�;�]{���b�"���Y �J��)|x�p܎!=�%
��+9ڿ�;ۻ�T�~�N�7zvZ�h����˝��e�`{\h�k�|Y�_�����6�6W�_+���_w6 �H�n6`ܴ?0<���dbLVE_�ޗ_`��W8E���u4�6��X�\��'��r��-�e�#
z8��h��L�*o�F(�ek��ah�W�!^�.���\�'*t�}��Kq���1B3�R���`�2AG��N�Q�>����ȱw�L�� 5HhV�d�)�K�r��d� iS��+o�S��v;�w��3af����r�>!T,�6�;�Y[m�~��wD���6�C�:O{�6[�	��V������ȢV�13�p�e���|�a��Ed�C1�����)���=��;}t��+s�D��9��ł�$Jˁ،X�2N�|/b^]`�\����d�[���.PL�Q����x6Q7S�|���`].�TZ���	(�tm�l.�NyVTȳ��W��O~���qK�,�E}�O�����	��)y(Ն�m���|�As4a��"�-��{��2X�l.���6��Oa	v�1K+2��_��ݢ��-;�joO'��G�	{4)Y��̀v%�8��ك�;�B(�M���+Sz֕�����c\�"=��oZ�
1��n�|�/��3��\��%������0Q�&`=�Û	T���0@�o��ķ��)�ɺ�j~♀t��M{�P�H�P���S�h�z�E�uς�ق��BqV([�\���'����Hޯ�g��C|Dn��� �6���54�2��]�9�᫯� ̰Ǿ���~�(<=�gQ��Ӄ�:U�B�wʅ=�0�
A���M:�W!l��s�p���j>m��y'��r�㝅�8��6)�NVd�ӥh��>��� �꾉�>��Ø1�̽UEm�?��e���I*�m<�WM�JJ9};6�����<�A���il*bX�u~���߹�,ݳ%�C�o}G���(]/�(ixv㳌t��%��x�TK%�W,�����s�����"����C�g��Y&�p�C+IGq������g���\���X:lh(�h6���é7���W�I��ǰ?�����$m�\�� �l'�uK$�=C�)���T	EΈ�*MV�f���pE�;fb�
s$Go�M���DhwU֊�"R^�F��M�T�x
 t!FB~䈈����@���"(��{�(��_��6"����6SM
��D"��9�	�l���Y�%&dҸ4nY�b�&s�{�$
����OM�L�d��l=��Ř�5@�Q��R+3-�Vv*xvc�e��-�,��N6s�m��W�)��匱2�"߈L����4�`'dѴD�q?k/T'�����֔�A���k�f�E�t�+F|��m/�舅����B˪15m���]:�V�����Co�_"�Е7F	LST{�� ��)��ʷȕ�zU{FAR�/����x	M|�	2|`2b%��M���Q$X�W���+������co������0���Z���d��G[������� ��f��x�e�6�`�3��hk�����"�&�A��q�O_8%�-{�_Xh#~��o�Z��yrtQ%׷� h��j�غrϒw���g�b�=�.�/Rc:T�a�� t_���ދc΂y��?Mb�����3�L<�Cv>K8���N��������Z� �/oTs��aD��2?���E��k�8�VK���$d�<��g��g�/Jx=�
z�	�/;g�@��M�T��ADzр����%��,���}KË�xn1s�!^�����sl��Ұ�����{h>�<�R�A$���}���d�*UP��qs������fDQפ4ǹÜh�����d���6L�0:�e��N�3�Z}�;~������ w���4���/<�:���󿵹������J��"���7E7FTV���oL��)sѬ��g����e�*Մ��#�Tc�1��]�����:�i�{��&af3�,��ã��^�1[s9
"f{v���]t��G�����1s2���D�4�\J�ɂ�Q�oZ�¬J��ZuV=�2g�	W�SQ�x�����d�M]�����^u����q����桀=
&<���Q�d�㓇8�\:�3Yֺ��2z�',CJc�6ƨΪ�A���yò���*��Ɍ�\&��kJ,F��%c%�Z��A��X���|�~=�\FU�1=�I�c=�1e���C����LN(��KN�U��y��(ЅY0n�!�ͤP1�?���[��&�$�Tl����������(��Sa�O]���j�Я.c�/Ț/9vs��F�g�
kCBq��#�qߟY��<��q4g��y�R�n��C�7P�3�Z��F[�)�֊|�1x�s����l���k0J���Au���>C_�,Fp�84��!b1�<'|���|s�u��|�Cz���y&c8!�І�:����#he����O�����Q#��������e��rӄ�&3g�� ky=�l�po=���!@l����✗�;�HJ
Pߛ����>~攞�#xYz>
^�a�f�aS�5����3LIzT� �� �pmKN����q�'9a��S�[M
6��o, ��\O�w�G��'�������V����>zq��aO���P5ީ�u�+1eoB$���"D�	=��ԟ ��órm�lY57OM�%Jz^G�YB'�hL���u�6=x���UߜW���y��E��ު�y�O]��zD5R���{T��J�����T�B��~�P�]D{)G���<ύ���204��~�����������oku��{��w90�m�_0Ax^�:����]�^B������@�C����\�c.�B�W��jh>~��5�@�-���}��3����;�������m�΄q`SC8!dƱU�R?EИ;@{��l@��9%�g�!�f�l=��I<�"T*(�CT�"�V<���D��X�}^���v0$��{l���&e��p���^w:�BQt�ـ?_��Fd�HgQ�1�y��zZ��Ӗ� I����t6�a�=��	�F:��=Р��^��mS|�Ҷ"R_jQmx�5=�#��C�V������!��":�җ��D�2�뽿vv�bjІ!��d`����\*�Y<ƹ�����P���	FArc�D��i���IK$��AI̴$��$����O�0���y��iw_�\u��%?�a�#�B)�͢%�mЭ�֕���Ԗ�{��~�8>���o�r�1�s�ĝ懋�hä$�4O��p�.�R#�S���䡖&��w)��N���P-��A]0�X,��{NF|5�H�rȎw~Fڌ�yB��ujņ�>>#���DI�����3'Eb�
��H�WO�b�o�j���	����7�����K?��\p��#��2�;��l�Ug3��oO8�4��D��Yc�p*���{,��6a�����(aiR8�.�Ɛ!L٦���`��ԍ/��m� �t'���C���a����NԾ/
���x;��÷�a46j��sH���[�_^����h65V����<x���<�������zc�?d��?����o���$`��,S�������7�*R	A� S1a^��13�ep�gfHÃ�e�1�{)�U�;]�*��C�F�Ʀ�nU�o˭��mSZ��Wr7S	�����,m��&[���w=3��qR�6��s��	���ф세��t�F��s˘ad�}f�)-^E��)�Ϙ[P���b,,Р�<6bj�QT��6%4d��GQI6*�i�X~0�I4#����l������28f��فkӆ0��$j�LS����X���m���N�9�,e!dƱx ����Ș��=۬�i���hh�Cn�Rԓ���/�`��v1Y�z�L7����3�zF��,����|�gl�MDuzԅ���������,Y��.O;0�5�&s�I�����&����K��mg����[�+������Z)4�����̏(P}�����#��Z(cܼƾ���E8��x:���@�,���;��L����*� ���e��Zl���L�����:���Qx.l��N{��d�*�1�����A/�A Eܤp��U^uK+���g*��F�kG����D�ܗ^��\fW+F��,P)����h5�H�e�:�&Q����}�i�O�^���_�#���0��J혫�z�tɆ\L��_������SR��&12B�vC��}o�[�Q��&Hdd���зR��4I�k��/47*�%k�����1p�)̟��t_8�J��u�G�k���T������D�UB;����5��*�)M�"��Zb4�i��]����0M���*Nu��f}��Rs4$�\4h	�R�aQ!'��,J�o�s�A�<51SD�ћ�ӺX��T�ܥ�zB��C�	ѝ�nڛqc���X�*O�f̬AG�Ωs��0r�ό�L|��!}fZ�|�k��j�:��J����FA�*�����U[�ɛfiE�%b7�Zɮ>�����>�����>�����>�����>�����>�����>�����>������?��!1 � 