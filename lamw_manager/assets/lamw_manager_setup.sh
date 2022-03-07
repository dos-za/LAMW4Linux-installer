#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2196165399"
MD5="7ad9181b0fff66385212b7d4a06d8d33"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26604"
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
	echo Date of packaging: Mon Mar  7 15:57:04 -03 2022
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D��u����W�ү۲�";٥P�c��m?<��V��E�EV�P�~1z5H`^Q�%�
�s9]}�v��y�k�^m�u� a��{>������1޶H��G�ǻ�s�Q��7�{z"`���#��/;��������W-����u��Z���@���߻�3\�x�i� �~���c#99q���X����$i,�l�_������}�u����	+X����Җ��j$?J�q�n�3��r��Ok�K�JZ�&=l�!C�?��	�]�����-��U�uI�s��:6���h�N>���u�݀�e���C�%̓7o|��sy��	�`�Y���pR`œ�q<���b��q�_~%�T�`(�j����r� ����/gc�9%Ww�N��$@����	!�6*���O�>���<��leo=����ڎZ<���#��W���< �����Bش2\��xTI�#L{b\k{YcP��1�湊�;�]�!�*��dv&�jUb�+b?7����:v����s++��4v)�vܒ2���wʙ�P�[X�Ti�n��fu��\n�����-�+���bJѢ�S�\�6�d��}�h�?�Ռ�i;�.�].,��?@�u{�}��/�8\7OȔ�Y���N��[6�h�l��	
�Q�R��̼g0<�4�㊺T�	}���Ť󉼼�h�yTYGgN]��l�Y1H*�6�t��j�,_P�0k�G� ������g��G?��3�ڡ8�+�c���������+�{���<B��/�2�29q�̹XajpO�~���z����%���E��1���C�B��F��j�r.zM����.�6"��K� ��i�N����ê|E`Ѻ��%1�ҩ���b+�Άdm����O�[e�N��)ьR���o
[I�V7fsdd��c�ٚbX�8��� ق&�����]��$��4���
�ߗZ�Z}��7��Ћ���S��M����ָXOU��J ��y���j��U/�G��QM���:�+�ddeП�:�k��?n��p���n���|W�	O�j%�$j)�L�\�[خ���M��ʪ�{��P������Ϗj)����洷x�"[�"��|b����˧;�?H�G)ЌF}���E���Y�M���)kMd�_�����Ã+B9�f8�Q���>�`\-%�ŏ,��?2�Q(�@iv�2���t,�c��z:���Q\~��
��oяņ�z���`&����VZ�3F�g��%�����VL��hT��j�� ��.�2�s��V�)�H3e�	_�R��:�p��
Ϡ��W���G��)�+�os�!͏�b[���k��P���k��]ע�M����1iw���.�>??�H�sLR����6��F���L�O����ØV%f?� �/=tK���}E��\�U'�P�Ć���=������d��!.��j)%Dk\K��\CX�䡬&Z�qU�Z������zY~]!*�Ð�\���:���.d�2��3����%�z#b�4����q�s�H3&[+|�����l�	'1���?��~S��-��u�&Xm�+c�W{�L�b=9��"���5�I16��:����iB<:�]��G�E����ŋh{�f�mS+Lc�~�������2�@uW�`��(�4΢G��t�@�n�}��b�;n�e!����޽�V��]��JW����Y��*����`*�p��׷A��k���:�,�ܗjD�&���*���Y�ؖ8����Wkc�h3��mk9��F��]i�\��Ә�TE'�R��fm�o�x��xj �.�d�&H���|��|�������\WA����f�Fq�2E�2ݩǹ��&�̩��+�{��X��/� f=���P��QSi��]m�v,��.��Qm�"W~ƾ�����%���
��: ���m^)��x9��V9*=�\�X�R�x�'j���"R���b"D��R��|������}�F��5lV�	oB
v"6�r��c�^�XjD������9�!zy��tfr���%��	���x渚m��Jw-�B{���yI�C+B�z���!Z��ta��R�ɴЇe��3h?.��)�L���2���t�6˦E�	�����I��=\V{/�� v�wB�T�f(L�T�O��$�1��	�GD�×e%3-�+޸����H �z�E����)	����Y��Z�y�p�lH@�}a��ͨ�1OI�D�f]d0��]��J�|cjL#���A�V�픮��f��0���^ܽe+�	-6b*�ݴڔ��ȿ�k�'��}_7tG���z���Gp�+�"e?i�@��n�5�P*�Ά�*��X����|k�����9^�䇳$�L������.̐_��{�j=����D��?�~}���� q<��gX旃y7���{so�����ա̡�p�ԟ����B^��\�wq;�i�s�o�U�$�:0��k6ٳ"��R?;�E�'�)	�Hc!_��r-���is*p\�>r/c Q��f�4��c���T_�#��9`֮CT)��;p����x#S6�eQ)��xF2�|��E���2��v�å#@���������#��C/��HaD��[����w<~�R�{�����U��3=����{E�Fk�)��G�ua�(�l��q��Xn��ms�E�fZPB���fB� �r����l$�wwǉ��J1j�!�# ��썎C�ݲ�_q��+Y-���7�.̟}���|Ri�rT{���'�q?*U`˵��\_�bɜ�c��s#�w���5�Rl+T~n�C�� -(Pk�7��B�SD��{�T��?�N�5+[�����E8�z����Y֟uE���&�ƥ�)���� �ó쟇.�)�E^תp;텂��%��c5�
�on9���C�Ah��
Y��v�2���J�d:1;�f3Y����i�1�b�[��b �ѫ+�D�$w�o��2<�S$��5� ���v#�����U6A��ם�L�E=kO��!�	��B��x��$���T�;W$�IM���@��3�Υ^<{�޷��+YDY�[��l2���K�5���bS�H�[i4w�j��:���3_J4�N(�GK�t*ף�A����f��E��W���:��[�u����ê\���=�;Tr^���!�X�S~#bd:&�F���ș����Bf�~�yE�t$|�T���8� D �D���%����j{WP~�\F}���P	��D2$�S��z"L9�:d�����%J��$��?��|��$�
��8�%E�N��/+fo��$�^�)��=h�+c�]. Ȕ{�Sgz��p���K��!�Z%�y�n�+�!�����M����>��l�7Hųu�n���_l�&ڐF~�� ����&�Pv�|��hL�����o�r!�9�?��!6h_]��ƫS	$�L��$�w��ƹ��ǎ#�����ORj�(��AW$�(��k�H��D�w���P��ZR��]$�suT-���H�(�:^�ݪۊ~ ex'Rw�0�O�� z*Ozƽ��a�����4�S�]�/���z��a^�Ǆ��.u��@Vޚ���q���
#�)��,�땘&?���Gӟ���	�n����XN��z�뾪�iX����&w���/꽾�'�F}���;�1S���o~�)����M�<���^��n��&�����x�Id��ռ�+��c�R4)�p�xB��>.��	�#�b��i6�S.�6ç;�=�t�F�uW7�|�J+Ah�̫��z��?���' ���m�CՐ�p�5\q�^Ӓd��+
���9���B$�Q��4ke�+P�/��_��fT�><}^���(�f�N��j��"Dմ8�#����}&캼���2�c&j���E��ƴ#�Y��x{��j�S���]9��P��1'C��T�WHA��xu4NM��'�?f�D*0c��K�l�,ϝ����e~g�AG��@���`��N��
��|����������V��h���U�on4�o�_�����X�����-k�rĢ�6g�����Z�����g�Ⲣn<qļ�Y���(�¦��aJ�����R�;�lDup�wR����FL�(�D�h���؀��Tg�����TK�iLRr5ݹU��w��wQa���}��O��Nk~�K���ZuI>=��"FiMV_��CQ�#�����>|�.��I��m$��j~�J"�����K�����~�Kl��Q�7w✈��@s�qV8Nl|�B��E^	���L���=8f/uI�����3��	U�X{e������}LB�3��'��2|���x��|5Hg�F������տ��#��Z$\h��Wv���-���K@F]��x�&�]���rdpw�z�]YK:5FӬ�9��v'y�q-3j�0�9��l�猳������佳7�fQu�]C-�2��ь׷�7�I� 8���x9%�V��b$@�L�^p�#a�Ol�ok�i���
�ugq�|�$�ЊK�  "w%�A L�}t���Sމ��T�?V��@Vr�� �:Q�g1�yǚ���a@��Z�-��%C�j0G/yE?����^E|J`!σ���a����kp����	���!x[��A-��s��.*�aT<сV�M,��{o�ܵ�8�YBl�ޡ�EG�?�=�ja�]
ī���:�1S�N� 3�HN=u�X��л���995�Qp����z,N��|�!~oP�Vӗ�����Zs]�}I���ΖnBMTI�"��rK��-��o�0AXf`�Tיp���q`&3b�BK7g�mv�x�:8F�j�*��?K���K�����+���b.X��P�gzJy!n��sp�H��b��3�h��*�!���71k�����$ڙ�|����w�� ����3Oy2:��B�~�d��+߶���j���1�8��j�I�ą�����1npc{r��p��_[�4<W��*�_���}��_	�^����yP�O�]�m��ԇ�����y�R3��ݵ�򶔇S�fXS/[>򶜶��A�X:>��BM�[�{�8MB�A��}�H����E�FH�o"�#��.~�2�C
nW��_L˚�͇��d����/�m�i��,t�#�w�����׿9����J<��R�I���U��%1=$|���0��ε��O2cVv��|5&�9��<]��?�E}ՐիP��'��2ԻA��`4���9���p�r��]�H|�n j)5ڽ��Re�Z���9xs�>�G/Y�<]e_՜�|�:Yɞ`��4n��au�j�,�l�G�Z��<������GlVܰ�u8�zgq\�,bɗ�ڷ�mvc�v�,0�����(�� N^bjwUb��k��Ε=���g�����ħch��8R�_�����z�q�13��c�������/\�Bܽ�YYCؔ҅�v��D�د�Λ(�1Q`��'�۫�<S���4��m4*��EKc���m.����^g�d71GFt�%��ҥ��S��*;��p;�J+ת5�E>��8/A�Sw�ǎ�*o�Qf�o��v�D��n+C��uv
���	����r(&�) �6�fWb^�u*G��r:^�9��´��Rm	�k��+�!�6��$��K�q%2$&`�Os -)Ag+�om`0��'H�8�-y��$�aZ=r��45vց���MJQl�R*�Խ���,Y;2�F)r���8V�
u3��wϜ�0[�r���X"��!�h2�o�;㍁��-��ScyR$��፻)֚��9���ϗu���8lM��������(q��f���C��x��(��Z˽��$%^�������$�PL�8��s!��[��St�{V�Oշ�\P�'�LS_��3곚ÈW^��X,��Y�'_�e���][�馝��#,�e��͛�`��J�$\��!���2ƣW���Ͳ1C��5�.&�V+��֯���4��l����Ac.�8�G�����Md�Y7��v��%��������0f.��&Z�N;�r�i��W}#S81-#�eP�n��@x��H^m�M��d`�ͲZ�<+�G��}����Ĝ���&OY�3Њl�������%�����Q��_k��]�\c|���l�.��&[S�E��:N�}"._c�|������w���&|�p�J�F��|�]�h��-�f|�����ӥ�Bˑ�)#���C�$���7�'k��e���ݲ��{�i���ނ�""֪��K��?�)�����g<���q�<�%�����'\�2�-��I#��p�S�՞���DEЋ{�t0;>����
�,F`)��)>H*��_������a�QUn�Y2�[�1ԝ���ʇ�H��mĠvkZ/,�/�S��-�j�W؃���,,�;̲����ؿ^M��0���d�=��t9�E�3$oF��&������.�	C�eǩ=n�(v�s[G����p��4�~�V���&Z����3H6+�A��%B"�G]�� 3��lZ�͑5���kލ�\a��k�8;�j�?=��!?�yQ�K�����y����O~���%���w���e�\� W�̈́޷T�%��<d��{��(�?�^�8P�̌��-�%k:�U깣?[x����"���O�����l0n���,y�c�X&�_��(K[�롁:ZW�y����=N�CL�=�cH$��Iv)�L(�`��*&n��V8wk�9�"Z�
CO�ђ�Y���=�`��8�!�ǡ	�0[��`k�?� ;����"s�כ�8��k[�@?����̡�չ=�����rJ4er�s�6��|�$��6�!�j��4��O)- B��J��j<�6�m�H�JT�oZ��#���+s��E����P�w7�ɭ�(�"Ͳ<U#g���)�U�Lc��0/�����pQ���M�t�ސ9��ς��\kR��Ȭ�Ӏ>oC�\6p�x��9Oօ~�������J7z��G���"i�5Y~֓nH � ���b������M����_�`V�iU���Lo6Io�_�KK�F1H�T��D�	��T;���H���p@8�Y��U��(8E�<�^�9? �9Y�����l���!�}����h��'t�~�A��!�6���Y3.hic�@��ӏN���$6|�l�
�f\��h�>fj<�o��F�nTd��x-���jS�ҩ��'�a��䝥��L�mS7p����7ʁ���w�5��TD~�(1�S��W?ʉ�,龟'!�����J�7j\�h�OX�]J�<�/����)л9R�N��&���"��0����������Lx�~����4 ��0/�r4:�KȾ݆�陭ڋ��n �5����R>�o�V~&-f��x�hoA~�.�2���z���.��VH�^[~^��)I<T��PT<���;�ؽ������b-���_1�@A�gҮͣQ��Ҡ�>A��s("N���ܾ��ǃ�VR��7|��3ձ)���R��#�
Q)T>�S�>8�	���	:s\rM,FI,�����F5n�-�
�c.v7��h*�G�)�ՙ���k��Jj�-Y�<����o�I��D����Ϥ�H΄�>{K��'m)�����bC'��7�\#����錳'��8\W־�>��$ �9gۄk=� Z�K�'���v���2 �B�=�\��@��w��?E��}UJ8�'>�&k�	t*~"!h6n`����7�^��HcC;��}e��	0�����ʶ�c�T�=t��dŕ]C�,$�E�2q8�� ����*����#���}!�
^��7c����8�M�����|��FL7�j(1���Զ�|r�D6.'�Qn& �8v��݃t����r�m�]����@A���M�"�+�?ydlȦ��	�,����:��w�ʐ`�{�q�q�}����1p^IH�G^��LkM�6�q/:X�I���rDe'���<��] �ځ�4o٩%��w��x�M�k��ɏq�fS��Q_1`"2c�6�(e־6��b�ԉ�`� n�Mok'\*��{lT-HoG���N���z!�dZ]ed'>�ٽ1�:Ã� L��'��|f�.*)z���zK ���mhZ���Jc��R;em"w�z.д�ȟ=� /knz����c^�,��ok�Z� Z����~hʘ��*�"bw0�>׾����Gl�nԖ�sָ�G��+���«ѩ^�I�/y���zLjK"���~���M3���m��.�3���?aW�F��/���k�Hr�5��HQ|)l�ܵ����is���ڼŘ� o���o��r ,1wd&k��U
��W� BpJFI.�o�Y����$��/zf���1!�3��q>�R��2������xE�	�������ea������a�����5э,��K�qb{?�'`�t˱b�|�n�N����Cqr:�Δ\LY��s����L����+����)L0�w�óG�?��WkI�-�J�]lVj�]���3G�
WX,�W��%5M��S�C^u��5��p s1XpPy�R$4�9)0܌5y��G҇�(�N4��J��h)I���b"�;J�$��K9KD���
�����H/t���2h��T�0dNC��5��t[nR ���Rl�������[�T@R	/��V׃�(Zd��r���cj.��' �A_xn���Ӈ�`�������(�h�ݤ@��{�k���P��gE,MvX�o�v���L.V�'����8��kjB�)��N��~7Vp����zR��A��p)��P����4�P� �KA��S�L;�δ}��-�?���g�0DY�����i��a�(�������צ�Or@��~F��n��Ġ^��d��ǜ���`QO3<���d'��_��/TBg�X5��,B� ��H=r�5y�����z�Z)���"�M�]�F�!9YVb$B9�$���mk?��P	x��N�ć�	��y`�k�:[I�g{�����$?C�?�^D �_X��H���sB��� �`�4,�=/��G&�2�]k�)�1Eޥz������	�[�:���m�[��o�^J�:Г��Z�$�Q���"�Ѕ-O�3Sj�얘����@L�Q��`l��A�SH�N,�X�����h��]�=��w<w��?4�C�u�(L@���^�����8$��`�bK��F������zQ5y
2�9�6��%g=q����*ez$z<��)��Z���]#fu�����U�8/.���#�xFcx�k��r2����<��#YT(aׂCU�/e�_ߙ9D�~@@�����m���-'9 �N29ll
"�ؾ�1��E�~_��gZ�Hl)(Lk8����iq�uVVQ�J���?�K*���)_�y��	�@-ƞ�:>(LmB!����.��^���cn�a��B+>a���8�m���TU"$�d�Tg�2v�H�r�C#U�t��HP���kv"���Wf=��uܳ`*1�=�F?�i1��
�6��6ky,��S����Ӂc7�ʉY���[���n��b�[��S�f?������8��� ��rF�ݵ�/���$4�k�k{^��4y������R=��{�U��q���l6��Ր�@b�L��;��]60�s`Yl��t(m��h�����s?l�?���D�[�(�a6Xy(
�7L���s�=��W�uf���
\��x|�h�䝇2�*��u��܇=gH�v|�S��S�E��¸�i{�;Jy��5�*�\^ޥ��h�U��A`ou��E0Zd���8&2ߕ�̳�|y�'?8�H�o�	N�n�7��t�v#���&��-T(K���x	�xGJ��U��碶s��?�~��w�sjz�7�������+s���ԑ`� 2�'|Y��/��^[�H����$��"[�f���^�/s×�Skϯ-a�a#�]ט�=�:��h�Rwau[b�tr�*�\�A8�ىm���� cKH�nPl�`�5Y��n���WR�����	�r_��3��M���EL+�e���+���Y@���ЇgtMW�\��aw�&rR#Í�B҈$������;����I>͋`}	׿�q:Xa~#�"S�</� TA����~P�0�{@�&�ţQ+����C�rd�?ʩW�W��C��;�Y�6�d.	�
ňk���D�E�)]f�t��U������T�wDC���=R��x�Ŋ�pg*�鱷�O4^Gkӿ�9?���H�c�����Hy�B�"}[� �5N�c�	)ɃS� ym��Av����[h��X�6r���x�)^k�~�p�:�S"'�M�_ѭ֫ذ�u�{�ɰ�Ӈ/����!�T���'�?����!� �︆;ƌj�P���ʘ�d��>����S\*,��ǀ�)����z�y������Ӂ��g[�I0���_;���l�!�!a��n�����*j-�9����
���)f�p�/��2Y�s��?q��D6�Y��D`���\t����N���4�MƧ�mmUx���EJ��.ρڝ.E�]F ��������rj�j[#���P<��z��}�Wn��� ] ��Z-DH$�XG����u������Ң�? H�q���ƚ
F���T�eB>��x&�z��䩦[�ge��P�5O��~6o����աB�[��k�F-����x8��l�Б=��=xR�J�TO�����D#�L9c86h��}@Si��#�El��E9�g:�B ���&��������<-��&�=��OY��Lc�+������k�^ds���:����*(+0B{��3hBl-g���G�4�2��$o~ź;ie7����?�_N܉i�U:�M��N���v(bݑn1^3�3���I��5���Y�LT��EU�i��j`���]�����F�����	�/��=�dby�<��O`i����b�@�Z���Y?��J��|��n�xH�t�gy�-������:M��.ρ��̣ř��,�\� ��j���z6>\�	Oλ��L�B�X?�J2Ԍ�%�^�����H,a�{k�i�8�n�/�p��&�������_M�Y� �K��\����@̕i/ݖJ��D�d�5�5��\�!�pe�L�6Y��hI�;:��͚K���X�D���?��C��}2_�T�U�${����l���:ꐁ���Y���#�x�\�L�F~�����uIە6��0��D6������Z�r�Q "�.�=4��o>��;���p���ĵ�I��J{+�����Mw �>�>>�k����	:*��,F2�~���g���!�I�a��]��b2ϱ�u˃W���}��ݠc�:A>C+�+����5z�"���V��]q]��Ѫ��=�&%b7�@�Riyx�!��VDL���&��b&���_�*7����n�lôn��"���*h$��iK)�#x��f�d�+�DK��A n!~�-kLI<��>���ZF�e#�Z�%Vrx�1o1H�vH0^[ե�`N��h�9V�U���P�9�s�"�ܳ쀞���7S��F?��KC������N��bX��ٷ�t
�:+�K�g������n��)�r�Lc�v�>9~_�I��y�5��m[�"����ɑ%FT�>�¾7�vn�S� �}
oA:��,QYZ�ھ��i�����	��N�;�^?w�V~�����H���N�7v��y�W��vS�`C;��Kv�{�ѣ������<j�rWԝ
���,M�,4��UTW����8��A���V�j��Ǘ`�(��)�����b+����J�w��Vs���9Vտ�� 4A<�B��{���{3���!�A� m�bwF���kL��+#p�sH}�ar�oi8�Y��|\��B�1�d����_����sq�qoЁ2��>�Pr�hO����Xk�Ύ~�=�$�j%<�%�,���,�&�u�vi� p�^5����c�y�,��?S��P��$ѐ�`��0n��L��PY�/#�l��i�O���b�=���)�7�3�˻H���Ԣ�N�<�8D�8(�~v��Q�bʷ���U%���P6��[�ۉ���D2V�x}<O�b�ū�g#s�>�����꽓��W�z9<����aE��s�G~F�hƛ�luB�Ҫ"�`�Ŧ�rW�!�j�E�禗(RivȽ��I]1���n�T���aJ~�S�b;����&�9�j��~~ab帵E�P�߳�q����^��w`�Z?)��{�pCS-Ndf�+�.��,�(;d���R��,ϭYa�-7?+&��v��7Mʜ�`h2������>b�����_z���ҡ�FB��~P�߫}%�/󍵱+����Q����n��f��p)�M_��ǜ�e"7�� tK쬬�	�aj��|�F�Sh�h���z'=y��c���SmV��	C"tHù����e����fd8>�c#v*���!#�d_���O�����M.�[.[���~���6��S乚jM������^�&:
�M���m���8��I6�=�0ޛD��iJSs����41âb����0	�gZ���g����,��QC�z�`���:��Cn"���S%=C"My�,ͽz�N�z>�H!.Ft���I0�nX�*�x��J�8n$U�|3!��7�8���8'IO_.%;�5����v�E�*o�*\�pE�I�זw�^F��<�x����Vi$������@�x��޴�b�8�����=��#����i���c2�oV ,���
+f����3aj�C@8�z�8�y)\����V�pU��f��$��J���JO[ی�r��M@j�V���%�b3���?��h�>zE��"'���M�	Z#��]%���h)1�@�6�Eu�@�:�~��Ʊ	���'}�`4%*V����y9�z�<�=�?Lc��t���ы�f�ps�䣥K	�]�� ���ǰ���p@���	����?$i�`s��T�Jf�_|\{������������&t�诎��"7���%�i��)�0���;`�)��؝J�kA.�K��&�MC9���(b	�g�њ�D����j�Y{x�S�
%R$K,?;�������p^���7�-~�dN�{���|�%ĭbT�lFs�)&����X`��AQC6��H�{�QLfߕ ?�G-v�}ݖxv����f��qK�[HjAA��z�\�z�"����t�+/��4�@�3�`$y��?����/��x@@�&O�[V%
J�u�'$h���XN�!��-��w,ڧ(L{��RN��(Y����&5��֛%���N�������GX(����<�
�4�< d���$��=q8�Pи�������׌2nFdf{����by����A����w��>�3��3H�S�(ة*,&�hB�s���C��G�1���)�#l�f�Z�����Ѩ�'��ZF���c$9����O�6�+N�%h7U|�ۼZ����_G�"?S��]x�����&f��P��K�xc�:	^�ߞGzw�ÓW��j	����ݑ�ܐ�_�!���g��(ǔL�!2��zI�L�I�[��~\�`0��W<��7���M˘�?��ac
��+���PP�+K�c�����t3c�ʺF�I�`2�B�7�B_�aR��w�]D���g��8I����OR�'s�ԉ���-���g�����}����>_�k�c�ε�h�7�t\�7T��<]� �f�_`��H����9�f?_���4����GR-������<��xC���Sr? �+��n��l�S�6,xf�庋{�b�pB!��Nuy$�k'������p/���Jә�,�U�
@��z%�ƕK/3ʊ߽��WN�o	���J�e�e��x�4V�C2vm��(n�#a�\��1o��������z�&��������V��^O(f�J˗��?n�J.�'�4�J�F1��ؾ�+��0��%��m�ki�7��#������k���O�*��ؓ�[_�-�����-��0���=�t�ZC�RQ%��v����Uߤ5��ͰY�d�!��R���p}$���g܌�D�<���E�	1�H��_��S�P���զ�tm�3E��V���_HK���VE���$�qw�J&C��QH�N$m��k#Z��j�@\�4��}�Y�qa������������@�����`���=��Y}]�R6Ņ�Uh[�r>�Q��''�5����^iV����D	H$L�n����ٹ`ƒf�Z�U4� �	�54c�[$ ��":A�^��L�"���Oփ��a����Q	��x3�:q��s�m�&ɯ#�Q˚֬�a�a����'�6�v��߆U���*9̑�i+0J�IQ�޵���Ɋ�;��=��f�\oˡ\-TW㭢,�'P�v�{"�4p�����bT���7��
X�Bd0D�P�/�VmgPT���bo����0`*DFWW̳�����n@-��y�.�Η�M�h�3���3����_+F���U��`�����*��a�bm.���k�.���Z�b�"�'�B�^���`���Y���b�ȵCJH_��y}U��{��,|�����[��t�g�Oe�pz��V*�
��a$��O+��eز���ưl�����g<���n���lQY���F����0}ʮX=]��δ�ӗkqu���C"���:���%�Tr������*�Hu�ӛ��-xU2�	Z��.)�0�CF��G��{�-��O�ը��kx����g�'7/P�ݑr?����ƅ�r��ns����h�tE����_.}E��e�5��g�)>�i�?�5�L�JV�Na/2��4�
o��kY6�-ָGA�����s"����L�Ҳ�Jp�T�W�@3�;�Ę�����[����<9��0pճ�Or#/x�z�	}Yy�.��_U���x�QF^�Y�lUZ;9���2��e���D�� !�
��}&)ت��R@o��6�
3�U��@�42�6ob/�)2KOqZ^"9�H1�e�E�}�~$n��j�j��:���V�<B��@�)��;kN��2H�#�<\bϝn��hM��H�7�%�|����8K0$t�I ,�w��$��{5��KPK��MU����@#A�g�BN�ۼ�[_Ϡ�m����7,�m'�%�Gs���7��)#D?�Z՘s�����쀐R��fR�'�߰v���-��	Lc�Q�l���c�k~m�!�X��E��c��:HL-�sFG��&F�A�ߥ�����+PS���zG���,�#���Q��Gz��ϕ��i@����l���d4�Hk����W0��V&�h:SGЦcN�k	��> B���[f��$I��H�&�T�h�K��C��74C皹��5�^=��XS%)F`���C�F-:��?4�q,����UM�
kY��������`� v�&o�T0�P,��0}R�S�����g�w|h��)�fk�"ޫ��+���)�!�)��sh���G�.�=5U�`���_�c�bn���}q�+��0`J�{��e"�]���.tw��$@�{���S�T3�_��9�	�����h7��&���(�7{�p[g2���czN���W>��>����� UUE�3��$�EV��2�=T�5��<��cǭ$Klݢ��ƒtƙ�'dsţS�2<�@ܑ�D���| �Šd`�1S{��Y�)�bG��� E���T�&8�����D��LQYLx�l�
ap�w�ￒOv�H��Ϲ���[�M0"��v�/Z���ݣ� �BJ�H	� zX8�C�3�B}�spp�x���c����(�Ǆ9���|z���(��3t�kYc�\Q��ÖxU�а
l�t�����- l��rD*]��	Ah�߼h�"n�^M#jZ�E��C��;3E���cw� �R�G�<玫k�u��@F�Aj`.xjɏ��d@�e쓋?�V|��j���R�9g�Ȅ�����*��8��D�%ˬ��'�;�.�FypY�S�2d�;!u|���SN���;�b���-X%�=V�.�Mn��"�ϸ��԰{t�-Q+\����B����>rR���Q�R��Q������C����S�L0��l�/�kw�F�+[�����Q�{���R+��������0��*|y���}��j�\z�-QLv��
g�7_z�?V��)��q�Z�xv�
b��� ��Ia�P;�j>��&��b��&-B��]*˗�K>>�|��u5#�()��L<n�*Z�5"B��pR5�R��?�ˆ�Ĕ�0�.���o��)�亏�g����N{߽J�11Sl�����!�t!K��2T�����jq ي�r�����Μ=�h6��Q���@z��P�T���4�1����GG C�jh �a`)��V�? �z�����3QS/��é��)��_m�C�ũ�)0��U�� ��3d�v`i�Obk���	�|�s݅j�ϟ�}����)Tk���@�KӨ�7�o�w9�m@ܲE�x�%��߹�N-����e5�[h��&q�]:�X�/�˥��;��{�7�9�$��+`���>�s�
�`K�(nC$T�EL�S���R���X��z���C�K�.��9���W�M����fhkb��e�'ThU��u����ɺ��."4�����Ɋ�8�F�ؘl��Q'���Q_·�[m�S�� U��3�w%���48��S�p��A��1J�����,@���&{
�Dd%H�JԵ��6w��6MP>Ld����6]��8�+�ǜ����W}�`ŷ+2�� ]��AQ\�3}u�u`P�遝7�����ֲG�W]�p?�_�]7[Ow�6r��..>��QZl���� x���Ti����#Wb�%���gP��ej�y̽�������)*����3?�gI�Y��9"�u��Q��WdU4�5��ܷ�X�����pH��� ����#��B���Z�1��T;��Կ�K��γ�,/2�m�4�f�dς���2�"\��NB�mU�����w��L��y�����d�b��4�
'�C�dk�zai,����� Y�C���� �Nhp�����Z1!�:���b
c5�	}<�-@�v�yh�|3�:I�l�N��Ag һ\R[3�"�J���Y'�Y����?��ڄ:�=����D#�S��EV��)].��
����{��OE�GX��T�dG܅gh3���#��V+Bi2hI�D�~ofO8o}��^�}����s�y��� ��֯:���+�SE�WC�f�aJ݁�%Gu��E��q��.1n�:��+����燥� 	E�N��+b�@ȊU����R�~�L`;����1�s���W�����=X��V��?xsۦhz�#Yć,%^b �cfuh�Q����o �{8��L-~���������ag��b�-�z�F>��G����~�7&�(�l} nI�������{4��g26 @Q�ί^��KL2xm��l�����\��(2x��A_Ŵ�z�,h��Wuz�&�J��|ї�?�^V.ҹ��I�����YX�����{]�9��b�$��n�٫�Ԫܖ<�E0>%�v�K�?�3/f]ĎEO&�ʤ�@��
�~�nH�_."!�D�Ḓ���s7�0Mp{-v����Vs3M�~�d���맙6�=�2V!�j��(av��gks�۪�WA�-��v�1�Sp-�<�v���3��{��L'��z� ��h�,Y��-��$�P=��|jMU%(Ϟ9;渌�-�y�E4�����ެ$�xҗ������ncI_F!l�1����������F��n�Μ\�����
�[���Y��#K��-��T؄�~d`���N��vf-�21�3�����0͚k��g���d�W.��G%$��j�pZR�k�78M�6J����-����Ș��#o�*�Q�9 ��S�~4�!�T*ɿlzB������'m�:��h�=�A �F�#8@J�|�����gx/%��o8l��;ԑ��[�G���D����[w&�N��~���q6R��p�+�ɩ*�+�0p���9P�h�^�u[�V�%��7l��i]�a����#�����R�}
o�*q{��zp�UQ�K
��d�.瀌�,���*�%�E%������K�`4V"��d�O�n����|�߬O0���`�𲟸���k/��<.���"Z�Z�A���J�B|�$Gd��
��ٝ�$fX�qaZ&�n�(���9��QR�(���+�(z�' U^��Nnԣ�Z����#Qa(�ߤK�匠Cfp�|�9R� 1�+��f5몰5�j<�LG�m�X�DH��Q&�bw$�U9�^��I�V!t����p�,WP���GN?
�$�dm!��l��˨�6�	�-_ n��}�S��h��.?�)i|���H/yw��"GR�K��?{��֖��Q�I|��#�n��d�*���t1mv����Jt`���ha�Ӭo4�ʌ�r�΁���CtX$��k�\�yO*'��b��_`@WO��Bߘ&��k�&<_�6_�AweK�������9���F(�k���Iu�d��!@�_5�>�,����Dk
[!�� ��(�@�v)N�R~Oh]X��DP�P�|���B�x�WK����A��%�&�"iQ��6�0֋�pgV��}�s��z���=0=�%�a�S˖��,*$Aa�@�N棞~;��t�\���ө�s�8� ��8�u%����������Z�x�/�����誯�(�!H�U`����h��y�I��U��I��x�����7�l�<�e��c��re�k�K�}�Q�������jÏ�"MP��N�d"��\��0������>�sw��J�u	���|�4�u ��_Y&��ԧ��F�k!#�Zn)ѯ��~�$�����p\�}�;�t����O�ߡ>Z��=�R}��,��vA��޺�,����V�4�R�<uZ�.�$�KST�Rg��HK� �EB�1��vi�D��K��u-��bwr�2x�eP���NN�7�����9�thԺ�͊P�qlAkR�d�q5��O��M��櫢�c$�2i�T�]�}J4��@7�v�BIK�O�9�(�3��r������W�߼nʙk�RE�I{�-�s��	2��r��Zͺ�����}[�]a�ǩ���,�����(�4F�S'�l��{�V�p�4�-�m��7�S�>�;������Fjw�V�
�cW���2�2^��<c��,Y*r�e�4��-���ʡ��(�%�3�?�&���	q}x3�@�d�]r'�Z3h ��w(�G����&��V�ܡ߯��<+�^)ʐ���6ړ�W��S����ˠ��@+�qXzE�%����d�ZR�G���D�!Y��F�ts�1�MA�ӫSw�A�'
�X�{P�?�q+k�%A.ӤJ෮���[x������F��zL����y{��Ǎ������<�3�f�6Q�n�~�BO��p�}-Sᬂ�b��~��c��`�4��!Pi�-�Fp�rg�ߛ�f7��Zd��8��F���3P�i�̗�gk���^x(���yP|f���SKk�@p�O�m���F�xY��Y����f��{���J�nH���+��o�rC���M1��g��z�T��f�m?�ȋ����h"?�|�3H��b�<}�[j@%���l3���Q�YO  �`b�z�%�ٟ��������|�fW&���#����
��U��v�7�����#o�Z(��Q�W��4�n/o��2�b�D��D0d���Be9��.D�@ �?���l�a�O[�/�Y���@���a�>q�*!�N<U��卌�i(@�̇v	��O�c�P��WW���$'�
������Ȼ�#\\�zu��t�����=]�����W�Q �92�ۛ��P3@4���,��(���t�c����h�X����H>Ӕ^)���=/�$���g
c��j��.��S8���R��M�;1��;!�}Q��F,Z����B�"�-e�E�����n,d5�+�'�-p�9v�!���/�"f]I%C�� p��!�G�ʬ��Tٯ}ȅ9����!/��::��Aj�3j}�!^�*��gL�tצ��`���Щf<��!R��k����J��I�?`1J���H���NT�i6��:/��EH!ݓs̮��K�Q�~-q�5���q��?L� ��G�{wh7�ˏ}��v3�.�3Z�ʱ��/�:�z�r)q���������UUx�N��A�6����`1>�vso��W ���}�ʤ<-0����_I�Z0��N���HTz强�1 `K�h֩c �=	��Zs QRfl��O(�40��v楷Y�W����\���*�*�Er�2e[�8Q4."��j��}�z�
͔'�5D:���z7�=�H����#�g9�đL��ݍ�*�Y�	�,�d�?a��:���u �8O�b�B���%	����=��f� ��AT�8�a���w�F�a�l���0��HJ�M���B��7b�"}�p|�٧k���炸�?�[�<(��c�1�����5-�� T��"��jq�)�w{�M�rFyT�ԜGJ��Qm�/��	ҥ���[�B�&���ȇ8���p�ϧ+�8�0�L�oe��|�;�k�T4�՚�X��2Y��whV1ݔ�l�瘟j⤺�6j��T�я#6�6+��U1x��m�1��7�U�:�Sn�F�>��5s�iU����@��S�-X�N�A�߂���������{}NUk��(O�Lq���_t���}oy�׾n���M�����B1�B�lA6����Ƃ�_��B��w����#�8��j���u�Y�6��>(���v� 󞐪��ѿ4e�K�c����q����+����x�'���\M��.g���H���x�.wb��1&�5p�NT���:[���b�՛_� ��'�}KYS�5_y�X$���c">\�D�{��r�!��`�->�)3�, dO��ZI�T�����9$B�P�®8�����誝X�SK�95uu�Nn���jӵk祝��bs���6�TL�8Nq��l��DM��OXa�B�d
pьi��-G7ԯ|��˽�Y;~5�^�h穠��8:�r���38Ͼ,3�U'x<񽙩�m�'P���N`�꿀t���U'fG���M���Hk2&�'S��#��{q:�F�B���f�}�Uodc�m�̣�T;D��F�9NF6�2l�x_�T���Ο@���'bĚ�-d8�`�flc%���5{�6�<N�}�9)�K�1����/`���k�)Ts�ӏ-�#1Z�Y�{ҡx�/e�@̴�d֊t�C�r�pf�xFj/.�p}'��Ӭw�������o�|r�s��բ��Ԃp1�y���&�'�:꛹m��i��i���i�� ��i}��t��2\y����ϓ���?[N6��ìq�r�`w��4�N��Km�h��yO��2p9�c]��<ɯu�s�`���oa��Z��4�=��I��-!h�[�$@�j�W��s҅����e�&��yILZ��KΥ2�aR�AQ��Wڒ�z`ݵg<;���Y�M|Yv��bל�� O�u-���@��C"��B��1~-(ޢPN|W���}T�������k�\�ňPQo� !�7�Ó�
B��KC���N�`��<����/��==�8�b+~ݶ��(�?%Jl��&�F���*k�+n7�i}�ʚ�.��v��\~����$PR+�i�K��[,G��т���zyt���X����j>#{������_��Qy5��tcˤ��]�s�@������(+A �� ���T�rnȖ�J������7�P�aLa�-.叿�D:>_�v���Ť|s���R �h5�P�ߖb%����<�7O$3�'V�o�ؗ~�2�FGV�wB���q5��<Ҡ|-(�ͅ$�*����i�$x`+_C��-	��5�&_0r�Ed��>��Q����
s[�vڻ#0�{����4�rj-\�w��� V΅��B+'�p9���~���տ��$G�����]�G����<�_]z2��"��f���{C\�w�HS�jxa��,��t/C-x�Bm�n�������C1����ؔ6���a�R3�0�=er�$i���Ѩ+!\e��nJa�`PTzß`��I+ ��?%�VE�,��W�����_�!�n��:���*&�n����?x���sh�n<��?�������܏r�S�_�a��D������,��;�[g��#wH��^�'�P��By��
3��!�zRH >V��\��kR9Z�86V�ȏ>��g�w&4��%[z?�(�V�R��(�6�\��*��{(�cL��q0�	տ�
��I�϶�����a�)��c�B�d�d��E�> U60�W�	�:���*K ��aA�)X����jV#���|�YB����TY�,�	+hT�g�Z�2@#��y&��)fqD2�͙헴���T�k�)?��yѶ��@�W�,K��5S%��+��R����w��#��M���[T�h?pJ> (��97��*�� tK���E�]�+m�!��,[�����*q.�-�CI�@���|��'��Ģ�*��{�%J<���Xס��1�L�z�2�zϯ��BeC�+��֧]����s����'��JQ	��1vj��|�?%'�H�P
�����+b�h�A�Y��i'1yV�(w��/(a�Ɖ���u�O��臨+�klL�ڢ�LQ(�0O�,&A�v���C,z�ж���>����JvZ6Fγ:ʥqM� p�=����{�p���_��%����5����~������f���4���-tI��]�	�1�k�z9��W��i��3M�s�M:����G��� Dg��zy0�t��$��i�t����!w�o�F��;hB�}�Q�p�@�9��X額�8�)��"��,��1����s:�� �6�^�:�� ���(�vԱ ��&�'��pš��UC a�=�H��<S��a��g3p|ăD/7������7:|-��η��S���ьҔ���|��r���e����A��~jM�u�y�c�I�ygv%�F�Sq
���˚����l�Ra�\uoj坑��]��>�y��X�k%74�g:�ё.����i/�P��4�:�3;��ӥ��*8Y(֯���#@�w�!�ܰmt1�e�X�e�;�~I7�����0���!�:=�/�[�j��F_����mW*��q�oz1["c��r���z Hj:z��V��)!e.��=M0��t�Q���W_�����+C�ҤՍXIO�8���-ZA,��0�&~���P.@X��b�P/�%j$Cg�m�5���>���
������{��ǀ<o`�HZ�io(�{9�����!�9�W�d���4=��k:p��ZƠ_(t�聯��,
�}_٢^���1��{O�{|�]����(�."	%M�|c��@{�/8���.�o�_F��9Ƹ=���<��>$s~b�p�YkǏ���q�`�2B�g��H��Þ�E\��a�K1�Z�<�h/��B��Ԇ�u]�ר��ԋ<��V:C������</j?^�6v��-��� SY���X�ӱJK���/�u��#�ڇ��Y�H�=��F	���&0�/�׏8M��F�N��]`2u�S��\�w��M.�#JK�.�c�р��e��&��Ҫ�P4�������Dy��������Ⱥԙ��dd�����Z���Z�~���-��v!
����U��L<`�%��n�n���L ��R�����b���j6#NO���){)kyTRɲ)࠰x[��V��㨹\>��#�!�v�8�^���c�`�燤T�\\m������Q�hv����ڱ�"t��b�����D6�C���4�^�@;?S����:���D�z% ~9V�$��b��.,ō]z�2�����VB�p3Ǒ��{�[#�~���{R�0K{t/o��`w�O	�򂘥﹤	s9���8/��c��#�&�{۾�� `��Z�f�~�� �󥖜�g6l*չ�h�+o�w��P�6e����_��xd�-���:ߏ�ɦ�Z`�u��B�'�������S�ɭ����ր�`p~��M,w���;�X�%84,A���u*H�X�t�ZV!G�����CL9���7ar���wr��>���xV�!�A�V���b�JZX��h�;������Y��A4��tW$ྰ�\^�boz�Gѡ�\��]F��Jz-����"��I�xͺ3�o�0k�V�$�h�ߚ#�ꄕbcY�"����Q��YT��?%2��Ù��B� 
*���V%5
vdm(�{���zz*�&� nG� �K����m�GE~_�㵌�R��W�b�'iZ�6��s�$�~���eZ��琥7~Ĳ:le����#Y��ʎ���Qw^�+��{���&F�ݑ�V�`�[,-	��Z�(�!�N��0�kUQ�8VY�Y!� 9���^�y�9�	I�H7�"Ϭq�(�_�U`�]ޑ�eP��O������j<Z�����!�كǊ�U�S�@V���(#���n9���-�{^m�@\��R-��3��W��9��U�¸/�I�E����H�����y�� �%_/(�@dΞ _�y_��{g������p�$�ox�]b3�\�(0�{��0ɾq��*'OB��6�O󉆫���3��J�T�1�����TUBF�)��vH��K;�^Ř|u"����A�{�Q�DNo[��"����6�ͳ5(�#k�%�::�#��o�vz�	x's����%W)ݮ@���خ� ai:
~[-gf�p�;9ݠ(HY.�\��)�IbѠ��u�����8Ki2>O��8q�%)����#����jfb��������wՎ3��?e�h$4^��k�s��4�M�'�����u =R��v0ʫÝz�6�����������c�Q�!+O�M?��}���x?擁)�]�b�֔��@���
Ir��⛅��8C�b�{�&(8��3>wnjȮql�����G#}.{��DS�'xO��l�5e
Wr���GH�KhWh��ܔT�/t]܎�5	�����]|:���tQ�#ς���܋�������� a���b��f�
{xX���_���{ek�yҵm��|'�Z��W�ņ0��--|a���zǶF��EV�y�~��[ q��mAG<<_֦��� ��Pm��i+�R�:�p2��P��3�K��D���o�E��Ǐ9*�O�9vn0����a��>����|O7�����|3��;��{��Br~_B*��C��[m}r�|�C$)��ڍίn����A^_�7i��;=��=�bd��a�@e�o8����d.�=��,���;/H�K����+NK!��ȣ+�Ӭ�j�;TM�����K�������1���uX4�������A�k��_�D6�0�"�M�ylk�w�M�� �$��gsa� u���Wt5��1�f�Q\�:ܨ���r���1هw�B?D_��F)�z_�ܯ����s��u�����Pg=HD����?��ǀ)!~��.K	�	J)U��B���m��I�Ͳ���q�P�$응(�U1��q���Qh�@�-9A[Ϙ2o�-�/Q���?iN�ymǍl<"Su�^��=̠��U�/4QR����C	m+����G�{�����p��W�|�[]ë������ۤ�F�\�X��CPKx����+4Hw�_|����E-=G���k�������e�lG�d �ٹ�C�d�.�-"@��>���Q+R+x*>|�����7ݡa��	���C��l�yg���*�'6��7j5-������ݍ��d��MG(s�w�ۙ��\��l|�͆E�ETc���|�`!f_B2Jڴ4مg��kJ�
��#[N}X*�K��\��4cKnn�SxWU���0jQ�f�K���x���!��[�_M5�<���*Zs&��*u     ad��kID� ����Z&ϱ�g�    YZ