#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2775160203"
MD5="510a8698d2d5b1f6a5edc6b485ab2b91"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20564"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Sat Feb 29 17:14:48 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���P] �}��JF���.���_j�َ��
@-3~f�����y˷NJ�p�N�C� �����&6����e�����������4�%'��h1�%Ϳx�$�H����M��m���X|�������?z�y� 4��d94wu�n4���S���$�Ld�~���p�6�?�"�^���}�T��}�T?m��}�SR���PvY�ga��D�u�$)u.~��I�؆� �� d����bRol5��׀�����4iJ��U��78��Q��Q$umÎ��1~�����w�@Zo��s*
�@�l�>���h�k2���h��/���A3�].`�� �G�z#ƴ��Ө5�4�+��X���rb���tl�%
ZB�,I|/1�Aտ�@��BjC����$3�à���)y[|> ���Q��1�9�}�8^^茶���ޛܩ�#G����E@-5�S$�!��s�/�q�҉0<_c���#�Mn��: J�#�r����=}56�dt�z��v#D���R��w��+�K��ab'ԑ�"�����$k�	�	dI�x����b����&ϥ����2tu��0A�5��x��S;	w�1��LZ�!�"�+�嘵5�����R ��iq�NGJ��i�A@V&�WܰۻKPVyq�ŕѳV�.*͋1������H�#5.�v7��룹�B����j�o�\�q��?��n�(��<�rb&Ay�� Uk�ہ�����É۲��so[��M��۫�ԭT�rTás�J%�Y^W�x_����y����U�V��*{;+��7�Zqi�+nQ�\���*�f>'Qm�����/I 糌s@|�x�]8�6�`�F�f�'��(��w�t�:�Q�=�}/E�{��r)�=qoD\ROԷ؟�����\��9��*.q���
c?�qc������ �a�΄�AEw��xR̝�@j���?��m����q�JNo L��TMA]����ɉק���Yc��������+�}�,F�<�d���ϓ�
�~��Y��g_�*G(��������mh�D }�ҷᱩe��ݼ�<��3�ܖ�����C��+B�N�Qk�t���V�M�L�K(%�����(�����7������-!E�q�d!"�'�.��nUN0�έaԕ�`u0-�R;4��M7�rS�-�i^��螥� 1�b�cH��]�#�@��$˯4�����@	(уcά�u��������}B\�nEµ=b�A�C���Tv��m�,hſ@��.Y�K�#����ʬ�c2����ZZ��n96�l���%��0m妪;�¼��΀f�,j��[�P��i�l`���;,�1�%�ٱXp96�)��%�؜4�,U�<2қ+�U�Y���� 6"�5L���Fz��2� 0������V*��.���!o���mU���h������!Tm���?Ih��3q��2�)����!�l.�(f��yS��p�D���`*���+�@����yy%̮�Q�N.eO��JT��P���9z.�mǇ{�W&�kF[D<�x�r�WĻ�u=���7�3��U:�^�z���"UhN��1n����wy	a�m���E��~S�x��Ɔ����� ��8 �ċp�"B���q4c�R�b�/�|��j�e6g���]$(����Z+�l����)��;��*%�_,9x�<��i�%�c��s�F/�����X�\���.+��l�ڃ
VH���AbԲ:�d{;��?,rǖ"d�<l�Q��9�}�@ý�rX![����0�S�������W��)?��fi�ʗ��!羐�rM�Gӫ���<��ϊ�s�h\�n&��p9�L[�\VtXb�^���-L�F3�+�0}BEC4~|����1?j`�j��w 6G�7�"&�jN7>� 8�[�*R�G�ظ3��o�:'��#d��cg�������	��_��L$व^ק�h�7�P�Ƞ�4\������ߑ�I4k�t�O�@*ġ����gjr���[	t�K���,�m6Z���05fDZ�e�3m�T�b��Ql��543�iB���t[����9�i���M$��k͠>�:���/Jr�[z$_���VtM�S�|`{u6�(�� �i�	A�d��8}:Y0!F�it�R4�e��'/O�.��p�9��XL]�{�"�G��=�3 ��-�S��r����6�)t��`�Ũ�뚻�O�q�ޒ,�]��D�j���L#��K�N���iQT���AP�	��<x^j#^�Ւs���"��9vA��=��X�Y�Zc�Յ�?Z8��`n3���Ʌ�  f�va2H�VU�̼�6��&��Y�hKf�bq#v�g܀��gDy�W#�1��x��TK�:�Ϸ$��
I��ڮ)^"G ��d����)//�.N�]�?����3o�)5��<�H�YQn�L�<�Pʝ�8����b�M�a�Up��[xUwKE�kَh�1�����z�ݍĒY�{���:���Hg>��b�9���M�����$�NU?�ﳀE��k�Ǔ&�Kf猇V�di��{/��j�e�KC-���&��A/7,�EI�����qS|z`�)�����
~�t-�Uv+�c۽�n��W��/]Hh���{�������!��r��u���G������:��5-��7Ͷ�6��r�zj���q^v�q=J���2sR6ѿ�w�4��W�^z����k'x�{C,)�����'�[�~&G�G������K�9���(���;/+�e�G��>�E/xߩ�ۻ��n�eZ��@�	�R��B����$���2.#qt�_%��l�
f�f���@�V{?�,��V8_j�R�:̓[�Y�`����O���rЉ:R �P�,�8I��0�%��Ϣ����(IW�nEO�
O�q���u	�~.D��CS6�Tx���I�v4}�ޜ��]�sʉ#���)�	U�*@����ʳ�@���;:ѥ}\��l��9׍��Bǥʁn�ٕ���+"j#N�ԭ� ��X$��"��#~o��2�� U<�bMg�c>��Ǔ!>��j~���"�E�_�j�]�bD}s�� ���ǍZD��7uv&�Q/� @Ӹ�ےH9@W�h�i��ul�!e�'<�S<ڛ�<14�3�L7p�ٴ��e���T��V~ݔR/�{G-���'��נ�):3G{�+on���Q��	����{q$�k��k�������*Z�������u��g�\[+-��rTԻh��2t���E��,�I���$쑣���Yy�j�11�̀L���T���x��'���l��Є��+�ob!�JI\¨&"'i� c�?��Gq%MPS���0�k�$�T;2/��#C� l�V�*�]�Y�F�nt|�Bfh&D��p������i��R5���R˂����p���Ą�Tv|Q5F%*7�F3�?�y�id�U��Z
;CsVv*I(��+M���-0�$O)Ԙh��S>T0 Ъ�����3P�ͮaz��t0�y�n@�K�5�I������SLM�%(�0b�J����f!���8ig=&�z�۰�}����]{lcd��AZ�#�VU�S"����,0�����]���)��p���"Qndz���\V�\�c�c�[�A ��ߥb�\[Ơa�vg-��m���3��	gyw<�(�'�,��Oq��.���=�`%�AL'_�������=}����B�ډ��.⛚�%����sP�|s�EW��e�9�1��qu#�op ܇��R �@�y�&�\8S~�M�Ӳ[�\"$b ��G_
2�\R7�=��؈����Sq7~���NFq��$mV�@0l5a�dF�i�0��=�j�g#@�%��r�Ḋ癋�هx1[e�i�PNW�mj$�b�W���菀�F�Ԗz��[�~��"XSI���?m@���^!��d�FǷ~C�8P�k��0qc�: m�:Y�J��9��[1��*��B&fk�u
A��d>��Z?ӛ|��,��`&@x��4�I�W��&�*j��	4�����ޥF�!f;*�D�2�ٌz�/���7ď�П�uD��\\(z7��� ���ܳ?ٻ,���*�`��> ���#�����0:�F�
,�_u�u?��}�-�����`���yO��Hm�۰���F!��+��p�瓄y��X�@�f�Lڒ�_s�I�/�h�)�M�m$E�ѩǇ�Κ�m�$8�mS513�b'k�N|��[���-��3�������N����R ��1޳�XI.��92}��=�^�-���Y2"4��6(��y����<"��xoTCq�@01����h?3�"�
I����p*��*�t�)��_s���ו=��|�頡UTi��m���H�������޾���1��{nT��(;VuJ���򉬸�=h�e}Q�Dގ�!=���K�����EŪXg�D�ŏ�9i\P2�aΦ�Ck��䥶�N�ݽ��wX�r��=g�����	x6�b�����il듋��en_L>U��B�𶳙L(3}B!&�KSC���I쿪)���_�	Q��k��i��7�3�(�N��#x+��t�����q�:@��VY�ؒ���)�:������@�"��MG���5��V���Ds�pYn���"KH�_Gʲ�v���˽�fϦ�U��&E��(ܒ�H|���bX'}y$��ϡ����[�YE4J�gR��{��s �@J:Dɒ��P;Ic�]�<�ʉs�X�*A���?FA
Z�,Y>�eƎ��+�t}��ݻi�L?.��t�������YR��k;>F]��ŉq@�X�τ�٨lc�A9�V7c	�=���4�)/���xx����e��[}JD�F�p��	AǼ;��K�8![G��g��(�&��b��o=ȣ$|V� �}�(�Qv_�{<�&b�8�r�%��ԯ���J�jg��,5i:���}O���?)�ߘt?ܸ��_��3�TtĿ�����8�X�
'�z�Go����T�i7�JX�B�.ꬽ�`̨���Tx��ݦ8��x�n]��c16��z���Ľ.����u;���:��n%|�b�\Wq�%�L� �pf''ehQ��P0 j�%��H���s��6:��2(÷,O��[�Ӟ�]b�%�@��V3r�^e�M��dJD2��=�/aH����ʽs���O,���g��ziP�[�^�v�0�*'��ҏG��]�ίΎ�xm�H�裛\:߉�*�i$k�ﮁ�����9o�XW���>&���X]n�3�#	7)a6�7����_\|h�j ]+��'�	�<i�����F�H�5%t|�$﮽�t78�I�R�,
�m����v�Co��`;����V����K:�F�{��+K������Q���
j�7ժ;끞J����Q�D�ၤ1R��3e���O�^%I����\�F ��|�2����2{}��2�<�D"ҺF��*����o�Sn���>F�,3p⅐�Ƴ���"BO�F~PבH�Eh��=:�9����pXH�ׯ_���b�6o>�eJ@�j�]����Y7��F�?'(����2���ADōS�!���¤�M~�y�\�,U?ʛ
Z6V�B>d�
�;�Yl���B�f��@�b���*p�=�
&�j�N+g�Q���F����R�h�s��t�2��H��gίϦ��z�s�Xl��˓����8�,Tm}��A��j񐞿���2Hgy���o+�z�B5��p&����ؐ�8���9|��vZ��	L轕,w�m��?�D�&\e��=94Ej�p��4�`(���c�)�k� d�H%a�Yt{
�|�e�p�e�Ύ?|ܠ[�TW9���琨���Y�R�AS����+��<�#�G�ir����L3�!m��+|ۊ��d�]#�:�e�@"������(��t멐�=5���G�/Y�)ol����C���ȟ}�jG��������
��s%�9�5��@k�����tx#FK�&f�az�;23DO!��hJ4W&]�7��^`��]��h�����+L���7@��3�L�VA�V4���4I�o���)l���f�g6�g!�����7{=��bT�vF�+�0�z�3/H�d�♧�R?�'v��ב�Z�y�K&��Kā���j2w�N+ʜr���ު��d]�>��{eϔ���\�����e�0$d�T-��'?ִ��[04�>��V�ӧj�3�Ғ����Ke�\�W�0�G��Z��.	�W8{��QzجU����䩱>U$�C�+nd��46� JL�L���'���t�<�w��̃8��b������-��/{�kl.�2d��ׇz�D���	����}�_�C6x,�Y
�:Vs6�?�����k�0yFd�!K[������*i���%�<�r���Ui6�X}Ϯ27hI�� � )6�����,#G�2(���<kߔ|�c�nZ��{9Pw��ZS~������&�Z��ug���*��8m�ѩT?�����&�'M���3�H����%BY�k⮒�����=�dC�9�XJr�s�j*������I����]Jyh�;���c���s15���n��}\*,p��br��)>��k� o� جd�^ݭ��v�!Y���[��ޥ�r���:,�*�k$�q%��t|O��]F	l��.�+��7�w�N6�J�=ãK~^y�l�1M[K��U,�<����P�R��a��o�!��\�ƴ<�nֹW3_��r)g���$5qHʗ�p��7�|�SYja�G����>����H���[n��7�޸a�T�O�NfU����`O[��69�Rxu7�!]Ud��D%�Ne�.Z;�\��AKl����-2ӧ9�[b=�]���v�̪:����W���\q�X�r�Z�Ho !~�,��|�l�+�}��*�ʄw��;2e\�R�	t�C#q�˼�7�"y[vg������Q�T�hT�u~Y<䆝!��"�����s�&4dO��dV.��0R�R��ሢN������ZQ�R��;-Y_%��u��]d2���
��%�;b˟���A���e��5V!_���6���cc&I}���.�ɑn�]Ӛt�x��{�Wٚ�COH��A�7A��a�9�K|�p+�� �����2Q�<e�Cp����R�Ɗ�8����sΐTi(Ê����Ű"�?]@�Sŏ}_I���&!�{_8`���㇘ːJ��֜��#0�R��Y�*l��{<����w��*t���+b�E�MM˳y��Ƨ���IV��G�#����b�e ��了��UQL�d�f����ȣs���L[��o8+��	WN��8u�p�?3LCe9 s#�H�b��K1��J���a֧�v���9��})�-���/.�:���7�j&�>k#yrM�`�jÂ���#���Z��$_$e|��\�ZW.̳�����=6�.E��3I�m�<��$��,�x����L��p#-�f�R���uδ-�y�^�FJ"ϣs�ͿO����O39��M���ۅ-'¥����.�~m�Sb�w��J�H�m� ���R��'n�����E�$��t��;��<�e2�ֶ�@T��$gNq� ��n(� 8�x		S>�ICh��ON�OD�BL�E^�>�o6�o���e�]����������=����V�Ӳ��~Ҽ,�em<!��jo�E#z�"�,M1q�䯙�	��2x��]Y�'yn��y�fm�r#���ek�ב�Ȳ��_��c/Ct`�I�K�kW�&� ��5q�jr}�?!:i&�Κ�v{,�$Zk]�L'���>FzJ�B�<rm;z
����;�'��D]�I�P{=�R�#C�Vȑ�R�-�c�K���]
��9����1���k�<�p���%�O�S�*&��OP����?گG����t�1xV oc~��Kԓ�3�1���a�74LE�����I*���M���' >�yG�7�Po���V-�?i~�����Г���G��ƞvZ�xG��E,B鍠����IӲ��Z����&`)X|߃�h��D���v��e��ɇ�G�b��v���0�*�u���A��|�;��"K�%�'�e��qL (��q�oLtȦ,�@0�FC.�)���m��>�f�,���MD1XZ���}D��!z�w6a�-���}���;��x�C��@�����?��elJR��+P�ܫ��"d����w���"腷\����^�����c "KV"^���';qgP��IN>\��8O9�]n}�#��ˏ �0��=6��
KL�����)�i���չ���u;`��q"�����*_�Rڰg+�FLN��f�=
�[^LMs�n��몔�J @��y�Gɞ��-D�z��
`a�bF�{�o�S��Iډ���kf��ۻ*�u�,�+�~����3=P$�;��B�hӘ�����I�t*M��2�!��5�p���08�"�W#�S����U&�<��`��й���:���4��.���KI����������E�z�g���B�an�jd=���%wS�x'r:��d'p���ޯ��4	�D��Š�4��"1�p�(��R�]�,G_�7+k��B��&pP�����><��I����Y�|��������������K���p��Q�JCd�#��f��
��NC�; ��z�?jS,C m�'�'Q˲�r՜<fP�����b�	�Ah	����Z�(��&�s,B#���W�*pS��Ȋ�h�^2�/�����eE8V1��C2��n�8����%
g���I�^jw%��w�c�����
[c{�PK8>3K`Q��zk��Ҡ{\�Ex�W���^f��ׇ�2��$+X�W��:��������y��k�ϸA�c��f�C4��w�.��G�7㝺�r� �PUB5V7J��!FHoY��)�����@o�t��lpQ�~���P�zi���u��hv�E�5�/����e�����	�T�a���<�����/��P�ɽ��-`�J��q;�U��D������p&�Im�&V�[t����~��%���%vFj9�u�8<+��?�C�=�D���� ��/�:��� z��p��8�CׯB<"�Pe憁k�}@^��"���¸�����t�[�j�سg���P�����C�`�/�̰K�@�B��I�ѧ�
��2l�A�dC�Q����Ď���J1�D��A��ӳ�)g�-(��Y����$��,�#����-��.C  ZC�-W�����ԥ={ǽ�>�U������7 �t�d���o�"���͉8����CJ%E��t���	)f�B��f��8Tw�|�BI�%LYD�J�Y�u�~�er&40b;Z($����&�!��Y����q�x*�|,���d��?%G�Ga�w%F�l������s�t��à�L�4�f�ud�dtͪ����|Gg���F���w���s�D
�P�b���XX7�ʝr��q#lF���c�F�,�����m={,ΏT�����7y�+:�S�aŶ0��]�����%a�&��η�|g�a?��D��&g̗��/�����#����`�K}��C��dF������ײ/~�� �T�����~N��Lw��
�K)I���񰓿":)M9|9V`�~mBJ�P�1ؑSz�D��m0�xW2N�����q���d����
�t��"�'��
$��nz� �bd�s���6:��#��@9J�	�d᚛R�-���F������(iW�m��8�Hn��e��M��	���F$2o���E@3W��+�1��j9]�gS��w" �-w7�8��cqUb��I�,�\,�5��?���*�RJw�k���� �'K�i�$<O ?2�ߌ|���0��܂;��%����1)6��4�����k�d�o#���{K��Op3��!�r�F4\VU�6Y����k��0�M�$�g�Jַ@LM-Z��0Mwo�N\��䕶|�_�S�qV��X��x@2i��HU'�Cˣ���T��f�����M�>5]d�X��{[��^��y�U����?En`X �ܳ�{�i��W`k�5��6AƾU�}�v��ⶰ�9��Fk�ZS��>l^G�.���ᇝ�����C^X�i�I� n�O�dryf�T��-ӽz��V�߳J���;�ؐ���vQ9j�X;�4�9?o�����2�����!t�3@�R*u)���z�t�˪:����qoYV5��T��-�C��?N�`FLX�2S�V���
&g�U�a�V�ONN<�H4P�E��r�LS&Ӎ9�,Zx���J����\
��D���U�^�6=���	u{!9X9�L�o���?R�ћ'�s�Fa��٪��$d�K�fG���c�LKy�IE\抉D6t�'Đ��[e�Q��H�4#���cደh��pY�&�^��f��FCDjЌ��/��s�ۖ�'��Z��4���
p֓c�����h��"���1C�w=u:r��FO[|"���U���1�"�S��9���Cd� ����1���E�7���ռ��
�A|��J�S�`��̙g�m�~���k���L�
��zQ����]M`p�)�AG�y׵;�!�?�f	S������Uny�6|���ݵ~9�9�S��UD��E�CΎt����X�
�AG��*�@b��LH�7ui�G�T���+ĉ�t�����5�)w���J��T��:w>G.R��;r���	��.���X�E����m��O���ḕ.�[�?��'5�׾Esޚ����H#��T�}4��E�[r*���	�ӓP!��[�,�u���v;:1�Dب��)J ��.�*�\k�p��O�\Ց� �V��}F��1��_�ڛ�\���� ����k4�0�Ya�g�����X�)���:��U͢l=3o��Bq́�4����6�5@�D�Kd�m�s���ܟU�޼8@��Z�!�Ur6���</(�v"���A��'�O���G�N&xҶ�`��α��b�IJwpx~�ZT9�v���7���m�wG�X"x	,���� ���AnyN[b�Zv%ńG��=(`3Y����F�*ۧ�0�O�ͥZN���!a 8�r��w��-w*+���f��ZeS�T����+�F�\`���yRV��X����y�?#
y9���uFb���Y(�K��W�ϖش�k����J�8�r�mK���C~ch&Q9���H֚]��K�����/�>����9��u^
��=caق���nLZ�F�;P}9�~0k��3i������2?Q�߭���l� p~Y��s{��<P��g���műt0p�G�S��MK_�(�i=�S5(!{j-���Q ^U�0(X@�ؕ�B��nګzM�Ea?��j�K�Y�r#����c�(� E��U3-8��S$o.K�ќ~Y�b,}L�X4�AGDe~�$*�`g�Y�FR�`�mbi��n.G�'����{M4�x�Y�$lp��-�9�Zd���t��7��T~�6+;vo9J~a�vb��.+�%�#����p�/�<�>,�k7̾m���'b6�w�����]�>� � �.���H4L[�/�;�����ta����i���I�fp�����=p;M�
�^?��I����^S�+��H�:Ng�'
&w�1\j.�"b����h�W����Z�7�jC�Wgc�����n�"�'NΛ88y>�0Y�2!�=����Ȏ�O�U���zCct�J�J�	�	����ʳ�� |�9a����j�d�!����$��c� �%���g�i�v�$16B6��5��l�O��2����p@��[���������_�GCO<q	������}���x�:�?��S�V�*�B+���.�^�H$�!h�����Rz��pGҺ���A͢K&�}+��N0�ゴ�X�h���*�|i�]Dw�ԃl@Y!)�D�O\��
��A+��[�eX��FlCe����Ԙ�-�K_�{wq8�:#e:v|'�|���ԟ�;,��sn�k�׆$k��}̴B�����T �P��e~ޅM��O � ��O�"�B�39'#[W��c�nD��g����(bc�`�ȢM_}��9T��1�׎H9�t��L���V7���G�^��t!��P���%-a�G�WE�p�6����\��#���ǃ�/��Q�$��@Ɗ����1)��.�2�����{+���@y�C����ĭ�!�<�
��hE����):q����x��%S�7�)����'K�,�C����W�����WN&�B�T��)�-͙D�ۋoS�B�m%q$-4��%�%cw%���܁oD�tvx���;�;����ɦK���~DgOf��)���%�����X���l�|I�?Ǭ]����w�I�ϓo�5$j��O��dm��р��\,��,����7��=
���͜%��y(���v�r.�7�:/GU �x��o�����;;^Cb�m<+�f��k��G�&��Bhysj�'Pz��X���$�+y��޽T
N1�V�����9*#^1�n��}u�g�s���*�f�e�S��e2u�1Ս�0�#�~�!����������!3��B��$l)b��y���������׳,����/O�>)˳EМ��ˁLf*]oU<͎���2i�>���v'e�MSBư�����!˪�K42Ο�f ������d>F����?�AB�������k�Qr���X�����v{ꎡ	�5�B�=i�;&����1ƒB�Dn�˭�0J�W�n���~��0/e�_͓2Kqv��t��#eQ�Xv�3�z�aGĝ'�im�Ȉ������E�t�>���iu���l�O]V�����1~��^\qTk�n�����x�F�x������|����f)������cK�Էy�f)	�J�)��7��)R�p�pKd��T�?��\NU#�8�r�{���6@C&�ۣZR)�� -9�[�~	���*fA��y
v�,�1��i�gPFS��iJ��������s�Z�P�ԑ�|�7d��R��U�>����m��DE�(�\�<ZyK����h����L(hPi��K���X�{he����B�8����U4Ls�K(�%���u
��`���n��C��1WY��5�q���Go-�@Z]���+Ō�i�ر�ǅ��CZҮ�t��AmƦ-���=�kU��թglt��o�q����V ��]9)�%�N/���&�8[М�j������Le�7�*�5
"Ta�ǀ��<V����[dl�� Yz���ӯ�n�GG�I������E���Ȗl';E���7�	L�\�P��!�*�e��P�\�����}'��ߦD@q���	ph���oD��e4�T1@͎D�o�	i��d��̣��O�B��G��x�8�EaƟ̸�+%#,\�1�|�m+�H"��oo߿?���b,��x:������ٰ�PH��j�{[�Z6��6�`��w.y�%v馈
��[�=0��X�(~%�㬵-r*�37��i�&�~����Y�䳕�r88x?�M�{:Yt7�h��2ʶ�0E��E�2٨�*8��f�oŮ��[w��8���o�JV����s�����xw60�󜘏{��紛���3��׎r:�B�t[`�����t�KWA�\ټ�ugTa>�R���S�㨘DzIsmh�KX|��g����^��@�y���^"$ q�-�Z�E�`�v�~������ĊZ�3����	��S�a3 ��
���e^��dj�[�C|f��48�R�|�0�)����uμԛ�y�]�Ib��\d���,�����{��I<�ب�6}�<d�"a�5�U�p`of�;�"�i!'U�W�nn_��a�c�J�s�/��H��]�a�~4�M��hH�mQ��W��	�+b3h	��x��E�BBX�9vE����?:�x����E��\+dߗ}*�eލkq|�˼���m��d����+7$na�),bTм-���*ix�݇�@���g	�Ni�&�Mz��V'���b�׬ǅV���&��U�#��c�ڦ�V�ܱW��yn�ꏥ�=��z�b���E�5x,��h��r�A3Qh�j�
�al�R�\ TM{r�=�sG��$�/���Fx��Q�;h��F�T�{V®v^A<�ؽ�@�(�~d:<X�qg�pڑZ׬�:g8Am�U^�\BO��D��3i�SǭE�y��QI镄��F�/.ʊ#���(jG-5��l2��}*�ZqA���y��H�V�'t�w}�����_�;�9<H0�)ޑ�~tEQ+�@X]�0���M�I:n��[��?�u���H2��CU��΍���+�\��^�����rU��@� A1$+���\��{(Y�����_�.��U�ѿ��^��@-�d�F��*�ev*�(ѿ�;��d�}���z�9҃��g��qZt D7��\1��0U$��6H��A��x.8�^�U^+��w�g�����Y�I���������r��CkLl7�1{S&�=�]Q0�R4�����˛�O��Vx�dO����ʭàC�xd7`ɿ(�г/3���T>T[QK�q��V89+'��,�0�d}��0||�]���Nx�����s`��c���zQ��1/,�J{ݰB��zIf�����-]g��t?��ͪ�ŵz�g��T9�Ԋv�e:I�Q`�M����].�Qm\^v�ʪ+
�zb���5�Ҭ��7�J[�M���������%�'�y[�'0u��;�t"$�#`wN�X�ߏ7�<�n�����ᔺ�L1OJ��v�
��­��wjh��2;���!]��V�FY L(9}8����ӌ���I0Œ��[A~��EIg�y�O�E�Q�%�M=%�<�9f�Z��گ|;D�Ĉ��X"o�d�!�I�HN�J�K-�Œ���	�1�L��4��p4}p�Q:�g/�J�!�K� YX�Nf86���׻��,��!mE���D�G�����	�i#\���Vl�h�/��',�,���a
����P��\�'X��:5`w;��4k�!mP(K�Q��a���~ ����	�<H�|��}���G3cƑT�!�pr�2>(-<�f�c��!��X5WH�(�r�"b�c��dF�-���gZ�%��`��!�=�ַ�E���M��O���$�s�7j��{W�ڜ���_��9����K���:t����7:C ����Jhu���r�5v�<&,�p U�ǥX���E}>�31��SKn%�(,/�Q��2@-1{��)�rq��#tI䣭�����I��UZ��bJ�VG�.I��p�py��Zm�d4�4�n촘�n,
H%�(��%_�]��vCNQ!�k���+{����:%�*r�N�kH�#����zi���N& �ߵ�{g�D䄣�q^��J5��U����R_�#c�'Db칏?rb sq���X�_݅�5p��yTi�%�Ҏ.#�m��L-��c���y�/�����r��l�=���a��b��������J��]%����}�ƙ<Q,��L�N`L��!�Yo���(\r��R05Gx,i㌐A���X$��
'��.cs��XI�o��hFJ�ec���FgY�a}%�(��4�5��؟Ԧ�'�~�1�>=�S���Z�gH+���O�C�e�l1��a�ļ0�oSc�-k�l��-������vw�6ҹ�\�)�<�k���3T!�ѳ���;^! &��6O?�h��V�62�O�@�MA�����ۚ�`�3��)��(&���wKg[
/����ʠ����AND���*���d���ݝ��a�h��sq�q�J\����rz#Nj���Ňh�N �����^�"Q�tՀ�V�#�>��{��X�%Ӭq�e^#������P >r�ND�����k
03M�Q9|��x��53i��Dv�އ�J��%Yݽ�Ң����<��H�ߏ�C����}����4D%J�d�O�Q�l�9�7I{�}�@(�K�K����v���^(�*?�A���P��oF�U���܊����%p���yHh����9���82�9�%��Qq�����)A�&��-k�}0Jk]Q}�sGVZ��)�E�Pz�`WD�n.��y��7�b��i1�Y�|� 2<� Y�6��	���&�ߜR�x͐_	̺wI�-I���y������m+��䏢�8uܝ�B�ԛ�m��D�R,
�x偲M��^ ��g��L�˲���S��p�	I?m��t�)��pT�0�G��f��_��Oⅷ���/���8̷c���6mg��� Ģ���6؉��a�9Ŗn�Xy������Zd~塀� �x���ш��w�L6�aéE��L\�3�J���
^42W��,"ZA�`���v|pA&k�t���EkW6/��I0P���Y늺�٦m�RxN�9���3�b#=J�#8f�b$3&2��������6����g1bGYZ2���Y�A�FJ���,+1j��,����8*,8��3
�Rvtp��ڰŦ�ï��ه.��a�D!�����9K�)D�&�W��`���W$x+��Z"�eU/���
�h���ۃwu͉C�t�~��)�	I ~�p<�M���HrAj��I@ǹ]�*������QiE�M�k�~b�"�L�i0��d�!�b��G�"`���U[	<A�JaAD����F%�@�~Q^g��lX��S�?jГ(�՜VkF�_ʕ�N��B.�4� b,�X��� k�ܜ�<��-�s�Ҝe��ΜO� lH��8.�H�Mc�ोj$���GM�)<���yy�>"�����o����6���,3���9]N#�s�bH?�hE�h=�������\�8���%���*>���E)��?����L�J�B{�Ǻ����Q*ӊw�fp��Qu�H|�fR��M�}q�����"����Z�j�CX8׊cK�������(���WU���d�xH�3��O���9|�H��T�ՐJF�O���7�v�V4�c_)����t�q ���*��cv��8�����F����R��GYy��j��"��̢w1�gDX	��G�@�,���7��,��0M�i�,; \m�θ�/C0�e�L���DO���yKH�YBx��;}� ��`G�g��FfX��'l���v���<"�$3�t^F�Ӌ�1����C�?
p���,%��q/�1��Vt<w)�b��u�y0f�kb}��˔&��O���]q.{ �:�-<��/b�5#9-l�����D�+¿@m��>�RE_T���KH�����C;f�o�>i��m�U�\�������Ъ=�&=�E����9r5��͋�kK�O&���{����^:� �ڣ���D`-x��+���d9O��as���qB�r���PrN�}Y[^{;Gr �������%�i��cgU
���p|O�㐻�g��0�/�t�C�Z�E��Jr��E���*3���$6E~�eg����!��c���]��d�,a�@0�,���֝>0�������Ww�����cm ]�<S
ٸ�f�j�����\S�勾۳���gqOt��Ŷ�P�D��	��bv�*��q�3��^\�5�vW��2�BS�x��)r(���u�s�˓8#'�
�|N�^�=M۩�|��"�v�^���퇊����c�� �U�8X3��:L*�U��DK�o�����e�'�pŲ��z�U��Z��b���뫈��`!^�@�n&��Ou�kԼ���wak�V?F���	�$�9�r'='�E�hA��>�GP�N�0xz���oj��0�T�g%�.S/���²�1w���Ͳ�za�9���X!��+XbA��/��n���#�j��;���V������N��Y�S%�ڶ��d�T��dy���oR���+�( �'�D�!����h�On��9��,���>�`i�I��7�[3�(�A�K�󧯶H�~����,��[�����5��fB��MM�c���[�Me���)�,}h�����픇�&'����|jX�ɒ��1]�\JTD��x��t�"JI~eo�30��M5�s�&�^ڲ�1bVĖ?]&��e3���.?����ټ4��i�jc���	�aqh�4z�I��a��<��ìG�M�����:E��m��H0I�8�ִξ�Ԃ���#8F̀R�FB����UP���]�MZ����2�n�7��"9(;@��aߖޚY��$�`�#��?���(P)���W��=���| �oN�K�W�!,qл��$��5F��~)�q�1��- �C�6\:$�a���&��Ř��(�����B%�-�q�&`��������"�P�`��A�&LaTD?�Z���?@��{�'�U�������� x _�A�S��������fT\m�8
$���D�]������&֓�4�GanW�v����(Ť��=]x.��\�)��G�0�<e����9��G����\W�)]�H}�K����Pmx��pf�L��u�K�	�"��0A/�oW'��LG�䊨�����@�9#ڵ	s�P}����v��]ѕ���f����w0���i!;9�JPn�$>�f+8,��Rc�.)��m����Z�j�M�͠��H�n?��R6��˗�þVDrL�/���iY���V�#3�� V0��h��q�ѽ�I��dZ6 �DE$0�PT�R�x�� W������ȉ��'U�o�ua�w��CRW��i�8����n��]�=R둢`H7���H,����	�i'J�£�+���nY%Z�ƨ�uq%�^g�`$_6��%��H[22I��=ͫ�A��T���{Z7�Za��NT:����x-|�dn���L���.A�FK�ȏGZǪfh`�w��<���	�;_p��J6ޡic�m���QpA�L�����%��_K0z��D�:�x����x!�`�Њ"D�e�a�+��;�'��;���K�����C�m�g�yd�)8g~
��HPv�o���令Xhj6J2�쉢�)���T"s�2�*��5�4gw�/��>}Y���b�R�A�2����FɆi|�q{/�<�	=��F��r�G!��vE���2����b#��67T���fmV֦�嫥�C9pI�+'^�|*�3'hL>b}�`L\��:]C�ڪh~;P�(L��T���"n
`���@�ő>�>��Y�L%�u�ȏ�pY�)�/����@bEZ�H�d�-��}g�5BFkՆ�*�0��5�UV�P-6u9��gx!�Se�� B�/��Kt	!7W���o��,k.]@P%�;gp��#x�'�>"����=��n�R_^�جx�]ޑ��ݽ�ܙ����^s��
�b��� h|�ߏ7�*��jC�F�n����W|�3[\�{�-������E�9g3��[L��ϲf�T��m��,�C�O��0Ѥ����C������+�A�C;2�Fs��A��v����PeG���DK���?󌁊`��#>< �6�w�>h�U�ޞJ)�?��r͑��S�n$��f��ٽ9y��<��y��Q����V6x=v	�`����_�4�YB��V�A�%��#(Jz�W�R�L,���:t-�ܞ�w��f��D��6���6��t2���:����#��iXs0��8S�y�
7��j|������|)d��4(��U�R^�1��J��4�����);�E6�B6 ��m7��v#�m�]7W�kÌXH���E������)FM���@�9_�ќ��LvJ�����U$T
��bqI;�����!�^u����u1���my'HT�4���@�y�9w�yw�k���x�1҅Έa��kY���h�Ҡ����,0��!?���^Xb�4�tf#?�`A@1s~��y��� �Y��3\���� ��W��v�T�/�v�O"���5�.�j4������XN2ʒ�E8UFA�t�^$�� ����Ȏ�c{a�
�Tg�/��xJb�Ok���z�&����m��`ד9���4�/��l��ֱr���Q49�!<��e'���r�s�ɫvF�.������شj��уy�T�d�:��Bf�L]�8c|�GHd�H����0=Q��3� ��S/{-�� ����=U���g�    YZ