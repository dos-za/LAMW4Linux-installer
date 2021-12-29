#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1243617099"
MD5="1eb3644b80103f1b4908ca5ac573ecef"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25668"
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
	echo Date of packaging: Wed Dec 29 01:02:48 -03 2021
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
�7zXZ  �ִF !   �X���d] �}��1Dd]����P�t�D�#�d�L���"iK�y�P��U��Ix���"'����ٝ��Љ�X�l��J���i��a���?*����.hƇ��N�w��Oa�� 2���}�s�� ؿ��%)�-��I��[�J���q>�	b�E�]��Z����Me3������Z&I~U' 	˦]�KZ쨿�[�� ��|D��C|VY#e�X������/)>��fS���]Le�U�.���G|X�`�IW���Lן��=�A�	{�R5���d��'.(l���q�m���N64�l;j���i��uó|/��(d7B�5�C=��Ū4G�M��E.�^"j�bkq���;�NHd}=^��G�X���Y_h��RH��H��魀�eSO�o�2N�.�c|GtH���Zǌ��9)�囵o����Y<�7�}w�p�A�Ĭ>���9b�oT"����U�5�.���sа��m��l\'pz�X�����|�O��q�dPFn�k�AK�=]a��Ƿ���Œ;��\��%W	T��߈,m�ת������}Q�*�W����ԕQA,<�ĉ?� �+��U!����=��r�~��e]aqJ�z=��=g��`s���wЛfj�	l:[����)��y�́�|��gr����*����9G%���,�v�Px��W!�x�E:!�eq��~x��i��X��D�@����Y/�VE����w�;�N8��nЅ�49��#`w��c��?��'�z~�ݱ�	4j��Ȍ��x3� 9'H�L7F&�o\�k��`8�>a��^J(i�ȡ�D�&%��?�c��.�t�|�i8�a�ȯ(u5
���4���E�����lo#?}���g�EwI����J.3�c�d�2�,_#�ŕ��ʂ��^;���-:U�2�o ����l�}��"���L?4�,�X�ϓ���8E�J�1�8>���&�ۧ,5�$]m���!L6��{�8X�q����lO���z�_����isԢ��i�ȳ��̗ˣ�s#'H3�D�����>_׎3��r�����T�V��KF�]�*����3��S��v��E��PcdF��{�E��U �A�ʡmdj���Z����R�M�w�+O*��˖��x۝�-���.�`7��T�U�s���W#H��ꨯ�`��+P�>���)V��s�����P�`�&�䏇�{��^�ù�0�?��4�xG��@��#Y����(}}���	W�"bʟLWPX Z� U����.zu/�֫Lฤ�HT}x�)�U���va߰9�m����TxMT'%\�	�� ȑ��W����pQ��9���k����\K����i��V��DSZ�@��*�B�' H�$@��2�N��m�n
p��>꠮-[���ƹ�K���t�ϒ�5�۫M�s�455��F.*�;�P���2�R6��ޗ;����bǮ"Y��E�c`���G�U���Q��L�9��Vd�����x��ez$�)��_.��8���cS�=h*=�o���6�	���)H��nЧ��q�����H��?W&Gt�&"o��V؊���4�V������u���t^g
I�3��~�*J�;U�/u�8���Y��#�$=��˪{�Ѯ=��e�`�j�[�du�]��$ϺC�PަGu�fKaQ�<Ż�0�WG�t?�s[�( ��s�=p�4艥$�$��8�7}	�p,��?�6�I>!=�L3e�i�Ƃ��=}���?}�b��|��.���Q�Ӳ>�#�8���d����in ���w7��fC��#{f��ɦ�6����wա�=u�Mn�/wp���|�滉�Py��^�j�̅eSDx�jz8|J�	�unSz���J�|�z�h-���
�4t�<,� �.vt
��_4N�����3�V�P����8���݇_;b�{�TU���Fb8�[V�\2t�E�\���!p?�W�� :#���bw���%T�ȓ��Y6�N��%BӍd�i�W%%�=�8��*0%�y�ߏ���/5����x������mx
�}:�6Yb�� Ā}�s�� ����$>��}v/���~��H��E�@��&�����L)7>�����p�Ň=\��
�42��ſ�c�i�v�v�(�,�i��ŵL�J�x���o\�t@|�i%I������n��Z,��UO.D۳U�u��\Z[�}�|}<��CZ��5�'H��B掘�1��(g�c�.!n�ᢦq�?0O^KQ�|��W�U8E�C�w�U���I��M[�d�<z'�^�XC�Y�"�c�^�d����_�P���(�M�~hC��I�9�u�Z2UF���G	�ӆɆ�
�	�S�@�^-T/�ïqL,#g;�<d}��>�;h�T���U��6J5)��I!v7�!�C�|�W�ڱ�;) �8S!��~��U�4��S�	����X4$�H��՝�>a�9�])	:!Ɲّ��V9��Z�O�r� �muU�R�⢡܌=�pF�E���/��͆����)�7{9�6����J��I�yz�{Ӌ�p���5����(i�u���4=�836�5:=����gH�W��TE�h����=#�SGn�A�(
jN�E W��3)��Y�u������v1�@>��(M���6F��ez�C>ĸ끴����Rh�^�b�f5����G���n���+�&������T�ʉ��-�'����LrQ?�]`�5s�{4G������$Ge��sq<U�ƍ�^����3c�D�y��/�U3S��0�Xi�������[�i�e���-y�9b�m�Y5�:8-% �&�5zf����c��uh���q�8�L��B�XP\�f�zy ��-[b`>q��AY^�dF��Ӌ� ���p�r�׭_����3��RI`華�Z��A�XXѨt0�~4_A��.����������61���V�����P��`�s�ȸ�V��� E��DS����kO�f؋Ρ�ҦW3y��y�o�'���^ ��OIg���������P���d{�_�^����U8[�ÄO $�;7DA�jԍ�-�-� 6@��)�d�Aa�ޕ�<��
�(�诇�qɋRѡ�B(+�C �q�~���M��]��?F�vX:�\ܜ@�$�>`�2l�g7B�B�����D�xI:0H斕zS}K���]
�r�g=Jh��%ɵH|t�T�/���:�6�ν�<�9;K�R�O�U��L���]mՖ�*��y����V�%��I���P��k\QC�f/$yY�/�%[Vw�Q� �QeS�#�A��̳��U*�'����2�[�-|$E�E�A��߰�u� ��h7���⳶���c�q-< ��-#�?�:M�:� �b���ХiN-3�.E5��3z8��I�Ã� 
�wP�f�T򛇡���a4�(,�!�wf�#%�9�R��#���ܚ�V]F �~{���Df���a�dO�S���� �P��knlva�s��ޗ���Z��B��N�sI��W��jg+ܒ�a��R���v|�>#Q�ݽ�tI�����d���>á��f��UiCE�]`��������
ܥ��+�(��R����C�z��U��"�y�+��^h]�]��n�m��?��y�[�<9֫�(@�pi��q-� T"V �Rj�!���YY�Z�9����<hrA��l��z�۸��e�IH�EopAJJ��Ș���mM��<��+��a��}��G�$���W�IBPz��1��:K&w�s�lb�"��W}��.4�x��Ak�n
�%�x�U��=�C��������	��sϊ٤�O�V���kՁ?������#s���9LI�j�;i�{��Ϝ�Ǜ�}yF��m�Kwtn���U})�D�-���r?�:J5��Ϭ�!�)��J>��]��-\�o(��xX�(�U����7���
7�}P-����|�Q5�}6M��5�@E:�!�,�>�ԝ��L��7��$Ή95��X*�8cmH���U )	9u�[��~^��TN��ixe��;P��Sd}U��4���y��l&I e�O� ���۞� /JN~7�]q�B�j��Mz�	�2���6��,��c�V"��rA�'P��ͥUb{�V��:�,�q~#�#H�b}1��7�6�0g�_(��z�\�#��w������C6V�ߘ�DE�פ����_��2� �K򠐼*�i��G#���t)5pҎ�><i��-5b���>p
�m4�b�ƃ���i�	K�p� �{g1P�%�§LK�j�|���m�k�ʪ��� ��|��Y�5 #]�ڃ��z��u���� ������0I�8Cyl�8���oi�������j	��%_���Κ߲YK�қs���L�[�sv�ڙr��7��~s�J�D��,yY���5�P�I_��<+�]g��Q� ��Qx�Վ?�i^�I1�����8+�P�a�C1C�Q�^��	C�KC�ukD5�KVGȗs:�%�s�Lm^��nj�պm���+ۊ:CH+�[��;��OAT�In	6P"�#ٲ�y�Y9d�� ��xw��nRG��E;>J��?���
���Yo�����
��G"��EaG�)�d|]���/���+��ֳ;�<ąA��� E��8��"�/��x�Q��GfYKN
�;��7� �	[i�<��ӱ�+��F�Z�W��#$
��Av4��k��c�m�C���+�����h��s�{�򥣴��2#��x�S<���~'K�\���}β�!�����o���b��j�h��P]A3Q�[b�~��7�ث�t����b	 "7ʣVKN'սa�տ���X�#(�%j3���G�y��f��m��At);�v�n_>�!5�g�EC�m�9{?o�`5�s8�������������t.�z�����a�ӟ)�=�T�F��rD� yQ"�_ۯ��s��Cm�M�V9��F��;<�wX��C�o��1?J���l�z<�Q���`��b�~b��?���UЮ������7=SD�8E/6f:<y�U"@���>>�f��2����Q:E
2���B����-�X5'Ƣ�cz$&W������k$�Ȇl�����?�#���*�s �����k��f��ጯ����;k��eC8^;4z�VӈM��U���y�:�F�}��PKl������Dp�P��L�o[H�ʕ&M/�z��e;cFr6z|�K���P�[km 	^'t"����(ɇ���p玞��f�qh����鷅��(0d�����0&^���v�^��ճ����T3Y��:��+��]��Ģ_�7I&��Xl�� akf՘M����NH����s�k0ɢN��H��(���a�e�q�����ku�6�{x�w�_9)i1C���.R���R�B�΋Xik8��6���<e�z%�x�[��p����p���¸��$r��=�}��'�ߠt��s�� ]3�0��h�x��)"����{�o4��\����DmIU��O��ƫ�ȶ��d��EX]�%HJ�5�߷�\�c�N�ѿ��2z	����#��Z��30+�����ט[O�/�����p�Y``8#��&��i�ƻ�R��Tѣr� �j�m��K!pS���_l�>:�:�>�w��@��pl�ґX"���u��7D��@���W���n'�������d�[a�*Lq��0�HdM܆�k`�LѫDyU���umP!�1�xʝ�5t��]�!H㳉���j���� }k]Is�aa�=s��RI��C�����t�EJ���ӑ)���l����Q��:4��x���4H�F��b�Q�Y���*.�@<:�;t���Vi�cj�?c��]��� ăd7�o��W�:#pwT����4�r?]� cT�R;�_�2�cfZ�N�Q���*g�bW�PV �oޮJ5��Q�Piz�{�s˰:^�^�5�8�!&~�<���7�`�gx��fB4}M4WW@E�d�y�NzL��sq}���ru@����%{ �@�ĸ��O~��!YR~X�k�(dC�q��BY:&�(��_��hV�7c;(H	��)T]��7�upj3����ȞNjHvA�n�xh�٨���<W��a&���'g?#2�g��{�H��GCB�[��G��a|������^y,�-��'A�=�Y���OuJ�����+nfMJ�bw��e\�:E���
��6�vvr+���`}d���E�%��{aa3C�Ľ��1��alz��d�����:�8���>V��l1Is'��i��V�!���:"� -	%���O:�t�E�F�{��H��4ν%�n��5Mh�WHe�7$���N��S`�0�W�%�˫�3�����n��g��4r�"i�_N&>>�V+
r>"	ɜ_H�I��)J�GK��� �?�b��"���A�Pq8�UT:�S�
IT�n�pug�'��&@Z��
hy
�mwz�q`[�v�v��`����M�3u�� ZJ+��J��+�m�|�)6Ӽ����[�g8���W<V�7�=�}���\�eu�Į��]��7���j��!5	�g$<u��!F�Dky��\�x��<x��TK)� ˒ ]�~�+oLeJ7���bkؼ!5wڑ�1<�V���T?��hֻ6"	��r,�p�i-�}��5��/�g%S���oዦ�Ir����KY
C��+-����ĆY^6�M!�b=����@F�f����nE��O���C�@�&.f�%�I	�X0����o��0u�c��ǎ���cs�*���L@��ط�n�uJ#��zB�P��W�*�;��Wl��������$������E+�Y�����`�P�ů�I30��q9i�jX*�|�[���p�����Fz�ZxW��&���2�h�>�MY)C��c�n*�ʹgǏj�����Q9�P�r?]}�0�t�Ơت�P��2���L��X�{+�~�8�6J��aA�7��=\���U�~�&B��]���GMo8��PfT�s�Y֕�f�D�����N�.8�1W����߬59hM	���n�0
���@��s�6/ܝ�ķ�#��(�L��q�Y�b4P �F�0�n̤/�	����S�e����0�Ȣ�\K�K9��_���Ԧ�,gg7:҃����i�45Y����#��\i�c�-lEz��G	&?����
|��ը���ѲRx�Q_�Q��!�K��FЮ�������Y�](�Hr��ԭ��s���U�[�Y:��F�Z�ZơL���� �i��GWX�@� �|�@h��4�G���b|�J�����Z�W��$ɚ�y_�7%A�� �����T�v��WckE�@k@�2fP��1��KGj̇���X��{���U}죢m�	����k{|�����RF|9�E&���C4�Xnu�N�))ȋ��3�'�}��ŕ�d~�i�^3���j;U'���c_vb�ڵ��v�"���Rf�n5��"�z\��y�i��x߉�~�I~��=4~�Xv��Ӄ�r���3l&��Hvł���ΦNW5�n���d�L���%[�.�����Cy�Շ���Uίf{�l� �Z[ڨ|���Ȇ��X]l���x�W��߂J1���ڔtT�T��"
�6�tA�)�1��?8���uV	$�}����!���~��ԬufѤ�DQ�ͬ�D��=d��T�~~g@V���¼�/|<r�
Ѐ��{�W�8�!بVmH��C��uB��X���*��!.�s��8^�K>å=q�L1��+�(7OAt�XdȺSv��C��{�Vȏ�㥶��>]bQ�G!2�nxO��Jj=ĳ�N�-�Y��E�C^\��Jc;Y�[��h�NA��M4���Q�fj95���;��k�;�+��GyD�!�����Lr&S tOY�&��}f�i��|m��$�*��%���8�"�� B�K �k���o^��:,��9a	C&Mv-�Sӿ���O��^M��k�xd����N���q2��}��(R#�]���S)�*��t��vR�V�A���+A�k͞���.���mI�e3Yr��yV߾���s���P�$����1'��I�������l�*Q� -x_�8GG��V��s,�U	�bk~��B�@z͍�&z<r��+Xx�yp4�y �o��;Z����E��r�8�����=�>J$s�����_SdR��ĸ�w,&,�z�N�JF�Ҥa�3-Ew�(Dꄩ�}(n��J��4E��lд����k�,���W�"w���͉�O�:�ުz�;�8���<C? hq����R���ӹZS����}d�����H�`)����~�g��q�3��?��z0݅
���z2�]��Z�F@�jO�z��3�;�����B�%EJ����~���\g%T�A���md���"pӑ����D[uH�H,����& ����S I�4���c�Z�?`,�|�4� "#�x�~�_�nl�hC��4�-����DJ��hj�$���Br���*��$�ߗq���b,�������kt$���6���,ű����K��f��uv�aN��'m���%J� Ҋݨq��(�����r�ou� ��8����!>�ujW�Xf5c��4�Z+�n+�dNO��H��]ˆ�W��P���Q���c�[	��sl���D��	'zU���x��������E�2G�q�nVH�A�0�y�r�2�qs���̀v��+�K0�R�����CE#[�b'��$}�XV����\�x�K^3V�*�t�c��oq�0(�P��	r�M>�xE!<$���|���i*�J ۞\���[�q�Q�84�T����BfKI~_*`��(�}��^�7�&���C��>�����'��j���8�����L
�d��m�� �u�{�\�}ܿI_L�G�zB�ܥE�����(�"�G�h�0���V�yZ<�
;&܅����;�j��	�_b��]m�<��K�]��1�"���M�|ٖU(��A�mJi\a�+�Kg��옒W���r�P���0^�R����ƛ��*P/��-;�I�c�����7��&����>Eݴ��?f�Zp¼�|�{��{/�T�Ia�
��_u, �7ݪ�A,�n�Y�e5͢�I23Rc�T؀�--��"�A�ť��}�'elfӖD̤���l���"�n�M�z��v6Ea�4:EȲ'Ӕ��T�_��C"ќ���AH;�:�;x���!>�y4٬!�M��<}_0�ȍ�v6?+`)�s�935���L�ac(��u@�7��b��0�5��&�Nn|٨u2[�0�˽A���� A m^j7������z������]Wx^($�@~�܄�Y�;b�W�G3ǱD��(��h�����G8�ʯ����v�&7d�����Aa+��d+-������ e����T�WKN�q�@L+#���ԽU����(�\�h�� P#����;��8��u�i6�RT��E��z{x��w;�ھ���O��O�4p"��E��������.�QR���� �+x��t	J�/�V=��9~�lN���/����u�z�QL^?����~�*\R�CM�c;o��T�{�5[�P��:Eki"_�nP5��Ϛ��w�	��Zcb�+I^��nA����H7�6}�F��ޖ�� B\�̖;��L���i.�C�~ҭv����gj�?�IŰ�8�-l�d�(��h<����񆵚1���2$����,{�onqSe8b�N����+�_Z*�(�(7��f�T/�|=���̓��y�c񠔟Ix$]n!Ko�G٪�M�<!�A�^��h�#P	�v�����&�����"�>a1�ڛ^k��l�Q��pr���G���ކ�+o2*mb�"������%Tn�+�M��1��W�������_�p�.��W(�l�Eq3�;�ù��aOƞ��_�\CE~2I�6�NV��"��s�v^9'��O��˰��[6��3u���Z�!�E$�\�UGN�t$-�^$(V@Ӑ�����X��}�
5%�q3�:A�삷��E��Bћ!���e��I!���l������!>��Z���v��e�PY5S�ZoN[��-+�]Tg�$�ouUP�^�5����(;���v��]9=�Z�{u��2x,>��� �-�������Uѵ&����KБ��:'��]�M�b3⍦O�����2���B��)���bXA��7Ƶ<M2w$2�%�g�x���F���+
�n���j}���	M���������m�O�6��^s��?o-ٺY�(��k��*AI�7��D�֞�"�� �(�%a�0|X��w��ID�?KE_��͹gY�E�������s#�X7��RzU0�<\`��g�TfT��Sd���Wg��B9�A-l���{ JԴ�V�S��WX�K���-�H=��OV����+��ފ�_�kc���~��>�,�!����M��.�8��q2\7QA4�K4���g>�7�4��0xo}�}3��-iX�FGO'�0T��޷����pѥ��֦�&k3�d�,��g� -���Һ�@�Fˉ��W=���I�6�,�eiB`��v�Z�騊Nc˳�gއ��F�9�쌅��NgK��^%���`��ggB�AOy�i4$I�1�rϛ�.�Hm�B���D�v�M�_�U��S5#�����?�]6[����"2�(,@MG��
���-�� ^��U�����Jú��Y�f�!��݆)�z���Ş{��2��TF�[�p��C�T*;&�5���\@��@E�t����}R�ǃL����u�#�>겺���'�ta�H�[��?�,�a�	�n�"ꎮ�B!�9�FY�0�y�뻖~۬K�#���ۜ��J�y�m���|����>����M�"u��X��܉n%�fR&��0�BC��qj�o�t��X]�+`����D�Z	x�X����*
�`�
��H�w���v�&@�?K��^����m`f���0]=o%<#1�������=�t[��1!p�kK�V�	͏��xO��6���dˈ9"���a���
[�
��r�@WGNJ���������S{���#�F�<p�C+�}�i�CS�
P"�;���4��y��{G]�c	��|���r�&���g�{�� ����џa���-�����}1P�C� �c�1a��
b��uz����]F���Ii��S�y�g���&�O�Ja1M��[���[n���.�Lk��J/�+������N��A:��]�J��ީ)���mrD�_�P�V:��M� V���_�͏��7�Ow�S��e�0��F;�B�sR{�l��o
�5�O0����Z���w���3�Pq��;�Uk�Cт�D���N�L|!ӵ97�1`����
[v�u��B�x��*���Z��0��!C��jj9��x��f��32�3d\	[f��B�biGƐ>��%UJn�X��f��!�$[mU��ۘ�{4�S�/y���z��CNO���'q�w�#�S�9��v)�6��"RP%�%��g��t\'�����{��j�P,��rӗ�F��m���u��!��57��
[h��~ha$�+!�l�ʞ��P����b��� {kI4���m"N��������"��44�V<�m?��w�(�|��H�D�F�$V�^Ԛ;���;֤�����{��OJ�_?<�H;
ð;��J�^U���g��n��(�����$�K��&���'r�SU3��Ez�Χ�mL�<Uh��&&���ͻ���>d��ܤJ*��-��!�JB�����uQ��q��a���ŏ[Mhg������^��g�|��۷`��<~��K; ����(Y.xb#��'���ی��ӳܪ
E�,�����D��7O�xe!�"°k�wt.{�����Qf�<�.��M����U�#/7e��Z�Y�E 9C�A%��c�(}I�qٓ0�i�M����f�Yq�E`C��V���A�!�ڽ^�0��)��]&�UCK�Z�5�{L��n"�v��BJ�N���{]�N�i69I���2���5����Xm-Q�/LN�D.����U�m������5���o�*������)���V����;xͨg�ރ��`x�9����Tx��!�Mf���i�c��A0l�S�W{urW̶U@�᪝��ZFs�a��Ր�����rh2&�lm� `��BW0e�܈H퀼�.n³e��\�+��@O���f�T��X�E��g�ܦ��l���<(�\}���z�!n��jֿ<Ki�����*$�r&=. �~S<���w՟c�צ����G.�r)�(E+�xp�A<��17���M	����mT�9��hΘ5q�?DO�U�V��~h�?�l��r��R��#����~�*��~X�vp]>Tu�
�xˢit���~>0Q���ߦ��x
�����&سϓ�S3�X9�'�5&�9�J*Md:˒a�O�ʑ.q�� ��s�n���x�z�7^���`��ڬn-k�a�N�E��	ɿld~��D�L�-5��:��$��Z6��k��?��������dA(t��;�Z�F��i�z/I����=��d�f���ԍ�!x�c�5s���p���'X���/5;���;obp#�d�)I_� ���<uJ�i�h)���� �5C�5��z�{��_1��PcYRb�~c�tn	9����a��N��bc&����Ӡ�}6&@�A�.�����{����ZBa���ܛ�r���WgNԷBr���.�U�r�-�j��\�	Bs~뀈�S�)��5�� %�|�^3AH�4��hL�o3�ؔh[���@����9��UPK�z��B��^>B$R:��gl�5{r��X��Yk�b>*����sk/G�~�PX���v�V�NRKb�f�:�<dOƠ��RC�,��H�lp�%��X����kC�Δ�m`��ը�
��m:@F�/�^��b�P0�0�r��H��{k Ix�/�r{�,T��U�:�	r���E����Y�^�;�#\{�6
���x����.X�=¦n�/AڜDP	R�޹7�'�z�,�Q �o<E�s�m!�[��!I����[\z����M����<{c�w�ݤ}.R_�bh&g����.S=YM���Yߋ�q+���M�-ڌ��Ώ|�?#+��kU�tj)���8�XPd�Ze��H���J����b�땠V�O�+W�R"JX*�Nx]��+����x#��_ǘ:\扌1y=bISǓ�M�u���r�H�ӤL�A����O�sdm9���F3=,}�.^�Vx����]3�6�,7����MA43�ac��dz+M86�N�6�̴��l�T�"�EZ����>�9�U��39C��9;��!~8*�U���	qLs�v��^<�:O����Ҹ���@1����Π_��t��D�8'9���g',���=q! ��Э/���Gg��������@7���ZԪ����T��%�VR�����#ڈ�
�v�$�PW��-&E4��W3fvb��`cD��-!�
<�N@t{�Sa¤�?mȘ��Ɉq��(ۑ�5�w�*{��DGJ$?vrY �؛�b��`��|�����[���w�>z IT5� !�!L��A���\/I\S��| $~��=�\%���K��s3�D������-x������k6���M\we�����}������b��O�!���C]�]z�>�G�'�y�M�����xr˛�fY�y�������%����������HPu\�U�>�3e�P��#�����k�h�$s�d^�)o�՛�z�ArRN=���'��A{���┰��Ed 7xJ.�3 ��ĵ#�X���	�#
e�N�a"��b��]]�DѪ�ŷ�U��dZ_Q[_#)@�E>����d�4!ѽ���t�������s�Xzg��ῙEFc�5jt�߰f�?�_�'�t�������+����Zi��K}v����<M����<ÿ-c���s���@�5�4�������P�6qO�P��}����k�3њ��6vl����NZPI�1���P�E5���cied����El�\-==��BJ"弱T{W-�pT������\&�L}��ڥ�ձ��[%E*�g􍲊��[�|Q_����K��������-�
��.C!�pyVQY�yDK񊀰�zCr�m�� }=GX?�M��Ѷ��KL��4�%��dj�����џ���؈��Iw0%O���*���`�t�ق�i[2\ąS��a��W���oi}�t �UGx��ג}�w�:�N���5�շ������	�p���O7G1��Ӯ���d�m�'��}��ҍ���mY_[C�~�.	�to���]@�[��Ҙ�,n�,B	�x��뤋����KY������,+�����ו���wJLW̑��]�"�E���^��~��0�p�y������\��sb~�S���E��h���C����{W���m(�jo=khӡ����H��<s"��P�=~C��ND�V����p�%����ߢ�d�^�x'��bu�"�IW�²Q�&�9m�P��"�P�-��T�R��*Fb�_�e���>m���Wr��{�Hmb�u���5'0`B�Y<Z
G��)�$�7cfxb��9s�o`.�+��e]��Z�vDfA�зTf[&摱&����b����@�����̙����lJ.���X�
��{U,��TY}�6tt�7������6K�+���}y
A>�\T�]r:�5�rc��<���B-��W G�^�����֫ukO���t��cvE�IIv�ځ��[x���a/����k�˷��fH���9x`ʣ{a���h�
g��a�t*d�'8�(dD0�e�P�P�N��&�@ևu��q֐�>/h�+(m�Ǯ�~��!�'�l6���ro�	W�ͣA�4��l�$R<�6��9�S]��*�Ň���Ņ@�:*��ת�I3u7!n�����扰䂭��b�l�ȸ�avy�3���c��{��&�0�y�T�*��m��)z��6L�ʪs�`��5��VH�}��*܆Y�����$P.3G`ߛ�?D�U�=�gl� 6M�w�T��k�D�yJ�7'�&(m�SWX�%�Peu*�O�W,�}�M�PKy9o3�=�z[����;�6��`��bگ�{��*��AVT�2��m[Ɗf���$��y�q���|"�Z��vol��zuI����]{)���ć�6����&��L�%�׿��}�"l�q��UU�Wڒ�M�����=`����6���J�(l����I�{G���:3���?�{Q�>+.���h�Fs����kL��X)�o�k[�Wַ֤�`�_W�\t��B��z6�ĺ�\IPx�d˒c��{�5��1��#A�����2e��R�u�J�4Yj9j���8���:�eTMDo����a
$�ç��
����dY��v?a�й�_;��)��Ua��+�b�);g�����$��\Aw���"%����޻7��ˣ�?�A)�}�^N`h�R&�@/-NOa-ɡŴ���c�7�U�nl�.��͜5�DL#Hs�$�[R-�i�t6�/�l�\�j�½���U@k�]��3I7~D(��_X`܇��n��G�3�n�ueM��$�'C�Y �1j�v7l��N�T�X�.���1���;7���fU98 в�o`g����[�'�b���X�s����xQ��������p��Ԃb?��r�x���@[zs���Ձ��U��Z�u��q����U�c�~C
�rO�%J�?��H�7�X<���5&��s���L�/��g��%V51��vY��x�n��T.��ě@�г�g�;���\����eP�1ݚ����2��т�4)�����9����s����4�L��o�b�T�o���o���#�\4���[�1#1:sD c�V4�KMu�x ��;�jF:�����:q�"(�ou�n�A��>μ_lm��ȿW���c�~�"��^��
��h���Ŕt����9G�مnSx0�Ds����ڇ
ü�9�LE�d��'�κ�,�'"�U?�3Bs�4�N��ctF0inu�=��������<��eYw~J�)�[�C�u)�k�����txE�C�r�Q���Nm�������V曩��|�܌�a����Esz��/`���$��g���FJ,�o�ʮ�!fKݴ�R��*��(��yoh�cK���l�$��ZV%%���m��;-�ʹY-f��C\W��a7	}0������]�z�d��?��9��Z���.P�Qa������uk]������h�#����K�Ӷ��� ��c�)��/K�R1Ӊ�T�����-���?R_�"Ҳ�g�]��*L�R�.7OZre4C�����ͺ�(Y.U�>�yh�ð@Πd9ZM-Z!��="�w���{�fİ�q&|e �sM��2�+;�ףv5b�`��23��T��{�'��W� ��g�u��dL��4x�؉m���p�������Ku��c�D�ȁ��l���֣�H�knŝ�j�ru� B;���RF����(�,�A�c��핸��?�KJˇ����@x��V'	9�Ul��ޣjؓf�j}#���̨9c�y�����2w؇�'�;�lk��]řI�ϰ�����GPOng���.P�X���:��O823M'S�.�@�x��:���IoB����6�3��F�������p'�
rw�?7�I�;�ug#z/|�JW�*�kt�J�1hC8��<�����U��{�q�}�����QbeN�C��X��P�`�9W�\�FFv��]rɂ�ҁ䜱)��w�q��6)NRmt'����$���&OJ���a��f��Ok�*`f�O'�y��
��yU>
��-tG����#��՗�/��hR��
6d'���Ч���oS�ˊWQI+��ϰ��B����$��%��K.M+�h�z�H|�o�D`���p�U �r��*�� �6+%2�w�i��F��pV�5\t���Bz  �;H�����r�;���� �gX=ߓ�=-��A/��E2�s�Ipφ�B�����z�,8/�R� ��$K�L��=��7U���G�x�)A@�����v�F��k�m�O�U��;l$#\�@�HƛgƅXX�iI	E� Z� ��$�OI���[��Tއ���}���D�t�x$t.��9��&�e點��d�79����5��mm!l��,�����}�@� V���ÕVk\U}�;�N��m�~��w���<����z��j����J����q�0�G�_/2"�����ꈽӣ1��.�".{jfH2׽���>K
�54ܱE��|�ב�[���F3Y�k�[���=�a�3��j,�4���<0<�B"&��"r�iA+�.r�y�P7k}��SɄc�}������1��H�9h�nA>`�w`r�MSϤ�C4��{�}r��G�����O�'�o*�*�b�*5�"ْ��=|]���I݈���>vt@�ǿk��6����i�V�ݞ��,��G6������4�P
'd��z���t�絣sSm{�
L�������S3xe�C�
Kc5� �s[h���p<�_=z6�#�#a���f���bM�,Ȇ�\�emV+zJ�a{��
�'����9���1�O�����Y�v��}��ߓ�J���\���Ӥ���J��(�,N��0�	 .��+�A�ryW��i�%:~M�Q�ɛ]{||}��h��dۆ4�xn��)
��-�����q-�S	"�S�#q�ԙ�����cM���E^  a� �ԃ�� ���<5J?�����-��q���Y�DT��6�2PY2�3��U|m��oɂ[�@�r�5��Yz���$�VU���P�	�HQ׶��M�<�֊ߵS{�FR{�W�t3RT%��G	c�s'?�k�� �ަ��'K��c���J�Gqe1�xk���$9������$^'R���h��2S�D���S$G<�n�ET�C��ôt|tƫ���M`�N�@�HD��\B+%�g�,��螷��rWa��x�`�TU$�sK���;���y�F$��L>��N'��R�᰺
� �u��/���o P�X�)�u����}��' ����nç��'>/E��؇p�pܭ�ř[��<�V�"i�cj�y�~����$�P������{�7�{@{���T�	0w�}�����L �9��@iҴ|���^����|r]DV9�eP!0�a�r��/f+I�^�;�V�}�����(�A$K���1!������m92gɈD�+|��b��	�-�ɶ��D���O_)kN��]��Q<�{��O����Փ�.�����}}�߬����w�S5����;���J���LdNs�m����5�K�֟D���t)X����-ʹ��%��Ǡ�v�����g�4Q�y�p����u��@��ub*�Y������t��T��(�����ؐ�E��>���h0�x:���*3thPɳ�cALޏ�?��Fה�` �o�ZcB%���! /#Cu�)�]:�U-�����9�2kP��S����8'wd������*��B�}!��w��S�s�d�������b���*c�9�x�$�O�5-,���S�����X9�5�. $ �+[��U���}��r�2@�܊\��EV������ҕ�Qn�����%8|�p"Z�#6�ش!9��2O>l}0B�JoD�k��}�?���1�3�5 �Ϭ�B��w�2�ŀi��b�������0�Or}���l��rJT���ˋ&D�C����`��q��r�(h�!�^W4���u7���T�e����VD�΂�W��ZK0��
���^A�ʹS`�D#��J��z�u�M��jw?ggaG*���ų��]Q�8d�9N5�H��{"����.r�Z�AbJn�J��G"h�.�p�c��DS�0�$C�s�-�v�/�����~�2��!�ڨc�	��T��\��*X�wx���N�y�G[c����cKI��\��-�julgk���s�޻�o��5���RٷWKʍ�X!eJ
���rZc��?�4"� fJ�
�b2r�Η��1��9Y�� �6��Ǜ�u�z	Wq� ��2�9�-LB���O8��<����v�?��K~ny\�.�Ť�)��,��,�����5>���VR�Z�������1���\j�o?�@L��_V����	�O��n�2�bٟ�W}|3��:��#��p����ۑ9�(cz���2�u|��S������#O��ڲ�mLCkd`
=��w��*G�[��N���ծ�JL�q����LL��[`���l��F��,�*��6�Z|W�yL�Ԅ���g��QAF��KS6��I��;$٨�ߝ\-o�D~���T��=��k�e��G���$y�R�.;��Fn�G����4G�O�Ļd�[��O2�Cؘ��J��~��\�B�H����C��-E(��a/�D���B�w�ZZ���5�l�&��2�f.��C�$�gb`Jz0"XF4��H�q���.Gܛ�x?��p�Vn�G0�x�PS��[Q��(W� �S�pl.�% *����x���3���9�ݡ��r�o#�1����#Y�-����Q�����C:�U��م}�?lU?���UE{��>���Z��I@�?�3�nncb�\���w���+z�T�c���sK*I7`�z$���2�4�U^�D0h��_dJ�T̚��Dx�M�o1qD@yd�\���k�Df�z�0�d��8���l>��agV{���hШ�`���H�D�$�n(\��
�`���%�P��M��W��U�Rsx��� � �\#♒��g�`��J�@�����=7L���t�/Y�w�hg�+��Ӳ�FӅ� ��bd���<"�}o��d�CTi�5��&[��$!m^eh�q'#h+I��3���Y�̀���k�<u����S���Oqv���|�����YBL���Ċ'�"Mqw���M5އ����L�t\oo��x�Cw�d0i4���A-01���(3��h�e�ӶI����r�v{����AG�yfM��S�wۄ�cG`4���JyG�d�*��ƾ/����o�]��6л1�{����6QB+�01��&�΃/P�ֺ������TМ��1��F��P<��� 	I`s���e)�֫P��'6}'B��U�?�a��C$O�̇�XA#zWZy�L�8Q��{<���m!������߸��W�:�}\'�z'���u_�[�
�"ćh�P4�9��)u���_?W+�K�/1�;�Q��8��.<MwPt�c鑬�sc�RV�
��� I��W�ܫ��N>؍��aGғ��"ʂn�B��7h�Q�rX��҇�vt1��{��a4��$�D?�k�?��]�Ob�Pݕ�=����3lN���u}�B�s�	�r�x�Ę�9��W��~x�����.y�Xٝt���houk�ڒ�
Rx�	]I�L\�֓3螣[�1o͈�g�JH&t�����a&%��C�4� G����jG� ��W�ґt�S���� ���O�m���S�������z;��^����`ɕ�`YD�S�k�m�vwѨ=j|:*#��xjkX�qR�ִwP�� �V��k��{�DU`$�~�g EW/o��$Q �2D�?Q>�ky�b 3���A�� ���Hkϙ�,*�����II�D�ǖ�+ ��W[[T�.�|\����A��䴂�'E5�Q� �����՝c���[��o���C��̵q	Q z���(:��'��"��&�M���`%��+0Z�KU�؏��-4��Bn�ujs�����/(�_ے *X.!�Q[�h)�MP/� �M�Œl��$e6�{�HFr���h� �Y�{?��a��P��.i������_����k<�� )��y-���_�޼�T�+�u
�HQ���<F������;�M���o$�\��J�L���HLo<L�@NtX�ͽ!�A���E��F.e�9�e��Tm�1��Ks["&���.��sN�dc�X���HN�s��7���o蒣J��A��ۣ!)�l�$U��T�=�t[�Wؒ5[�]S�7��?���;�/�)��F3R+�mi:�6��&q �#;k�I.��w莤�	T�T��mh��\*��2��a_�h?�i�_M�&B8?Nԗ�M
����(�#}��W҄��t�ȿ��
O�Y���T�U��t��)Æ{I5L�'{��@��@�\Km;i�z�4Ξ�9�F	�^��_��	��zP�P4H�H�rd�j`@�j��}4ZL!fUD��� G����U:)�Zk��L ��[�9��{.�U��9o�X����x��[���ܚSI�}۵��|��F:���1�-����U`?�+pڷJ�;�1�_���7)�����tjKa�I���{AӺ�:�%����`�x��&�sC�#0�ׅH��p�S����w�[u����{( ��g?�r�Ȭt�� �������u/�����H�l��y�U��tS�`^��X�)\�C��%�e/�}v>�7��3�k
Pi�ܱWI�:w��`G����v:�-K���X��`� B�~���!0��hx]�o_^��˱^!�I^���y�-���X�,�fl �[�U�Sf�v�L���N�V:�B2U=���D���
)c�����{�Q���fg��������r��������- *��5"��ej��eg�� ��	�TP�`_X&�WFЙ*[�����bB�����Ã0���w9�����%_�\���1�K
h��3냛��ҩNOG ;��H�Q���S{r���D{>#SA�{|"�k�k�n���?�Y$�"����#�ᷡ�v�CبzfPr�^�==�/ �q�<�Lu��C�l����`@��ݭ�
�N� ��4������h�z�f$���=��tٜ����H�f5&��.ST��y
���	��^���a�Y2�(�Ii��{�	�Vz�ǂ��Z�����v3��Q�S���D6�P�g��2��H��vo�߰v8H�<ƻR��(�Q4�UV�2L�h�8\�x�!K���-���V;�3IB��fz�0��vk�߲��G�d�\c���2��mig\5@J����6�V�B�2�~�y��4O4)PE��� Р<M��J��e��h�����.~�2�Y����vL�ޥ5��j�;������O�J&�[��{NJ��$q���ԙt��T�['#.P��U�^���U2�۸±7HLU�m�FcA�u�4�Si�;xV֐��a�5�-z��R����9)�Z�l}7h�b>PI*�{Yxș��g'�[�iŌ�䙰�S�Vo:�b�rx-��Qu�����@��4���E�>V��7��M�������'P z-����L+g����&��8iS�/�\ �;�޿�5��]�@/Rp�4f��D>�L)<�̽%[����� s���6�S�y��/��Ud�,`m���:��wp�I,��gE?�_QNٯ�_�[����D�c�U
�o��Y��Ȕ�4����#�N��ү�;��,XA+ئC])?��jN�򥴭2��g
3u����H1,���/vH$[UfHq,BA߅,XE�
F��D�����^bJdĲ_�*X�q�XcI�б֫J�0\q��qp��.^4��=*،縢��c��h��3��i���~j���uxэ�Ρ�n��QGq*o*��m���d2du�/�?�pW��kcs�Q�iR�\��'��uu�,���`�1Ik�H�AB-0�p���d��^d�*�;�B�qT)�O&ή�!(~�L��h�<���br�oI@��X��2c�5��&M�@�T-(fr�`���9����u�l�Du+N��%C�Ԉ{02_�0P��b1Y���Ҫ<A�{l�f�Q�h��Yդ�@9�3��$pc�ʬ������t�Q9jn���+�C��H�7I -hT*4k�xdiY8��Yn�:'�>���;"{0d�򐶨i�h�Sl�X�AC<x��ܣ4tt�ҹ����#���
� t���fz��w���^�y��0����~���̔3T���1!��N����m_�V]�"n�~��R����$r��"���G��j��iX)!;;�8�����ٟ
���p슢�c}�+�,!��ƾFr����u)�Ъ�3ς��	���q�p{��!ڢF�0�~U'��ƅ=eF�idv���������G|�6�k?W���L�Lt5nr~�~т���7�D� ǳ���z�;�fe[.KTQ����ۭ>��e4:;��z�Y���nA�#,Mߩ��j.l�[��N1(� �7:mk"^�}��¶)s��>��?@b�*ځ�V��7,˗���4�f?L�U��1��A�6[%M�5q�E7��S�w��U��@O���Ǭ� ��X��ڇհP�A�˭2����ߡ�t�͵�^��Z;߁�w忷jc�!}�6i\OG9��sP�J�-B�c�����t[��٪9,�//;k�d�Ѕ ��\6�����2%p����,Mܧ���Oc�W��U*r�s���I�j�3���g�.&xi����Zrg>\���"�}0��jD�ք�L��>62��%7��I<͡d���a�h�L�\�d��	?����`��S���7ʻ4��_�A-&�<�t�4i^܎�/����q�3po�d
%�ot�]����8b���?�C4]��r��4~����5+Cn"��G��u�k׸��iL�Zk[�X���A尔�t��;��!A�y����כyf�w~��<�"PB��o��
چ�YG���4°�A�o;�"!0��s�`+<'Y�T`��v��J��*����#9�]�&<G��n#�W���KG��9�J	���Y�6A�Ly%k �)�"هbe�R�bl��YM�#�b��b�0H�$�o�#� �6"0!y����0~�[ȜX���P�y�Y�5���nAq��A���N�Ё>����tT�ZG>E���X��LpK{��AP�E� �N\�t�|*1ﹻ֙�3>tQ����d>-��/���%��CoE�9$���:��:��P&�F�RRM�g�⑚,J��=�]�W+�|�)o斍_��5�*C�RO'��GG��-YD̄�ɺ�W�$�Qr ��v�X�8��@�*��u����/Kvyժt���h�(���&�q�$��v?�����Sc�:�:l ��7�ZA���7���-}}	%�5�W8yM��@��/1ɹ�Nse�~���`��p1��E�*W7��0a�~��*�G�D��P�X�i^ 6R����V�j�ڳ�8=�2(/��f6!aIf*��MXO��?���j�,N{�d�{�霆���k�+K
�&�qZ6<���0D�� -����֨�Aҩm�h��^�z�\RdM��i�j>�D)�3�gd5m�B�=��A/n�����]���쳘\B(���0`�ܥ�߬�W�])��_�����r6ts
 ���L�C��踖E�=��9��ωGgӳ
Ρ9Dx9�rI%�D�����@Fo��i�[���Il0��~Wi�b?!��G��w�^O��f%��R���0-C��*�^�4��\7��w>4S$���gz����H*=������t���Dҋ&��!�0��_��k����j�S0��ka
DdX��;�����)����B��G��Li��6Ld���]�JoJ*�Z���ب�g�:Ī��y�Q~����sƀ��jP�Ɉd�~(��MO�C׸���FWn��N3����+B�&_>��ED����j�8��fA�������|��R�
#��Mm=��Z:���J7�Q�����ڕ�a�o'�j��?��V�	�˸V�ԉ��Z�$�(Y�aH=@��m{x���,�ďQD��B�ͪ)�<�dBz���,�)}�L\t�	�H����܈��/1��vj����b
H�W.B�>��t{n�P˂��/4<Ȑa�@�/z��i<�`\0��/&�TH�rB=�0�4���xRh���n��۟��|dӆF��QIK�F?��D�W����n�젒��~|,D���6�8�q�9��Vd(�Ȋ:X�k��z�(�n� $���Գ �����?%��g�    YZ