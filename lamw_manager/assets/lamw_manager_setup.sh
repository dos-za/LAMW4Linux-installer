#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="70106860"
MD5="3aa159b8d5aa892eaa1dfe67340f960d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23692"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Sun Sep 12 17:01:59 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X����\K] �}��1Dd]����P�t�D�G����P�1J�7>(�%����a#�Oydo�?�Q�1|�r���5`F��]��$��d2��jUe�=��ʞ�C�wٓR����4S�v^�0@����>ŏa:�9��y$�0�V��$��C$v`ȉ;t
o���<)���`,��g���zҐ��B&�X���v�f��:�_Ε�z�[�%ƿT^�X���2G\�������CQ��;˥�C��K¾�5��R���ӝUr�"J�j��&�j1�doq�s�h���hi�?Z#�t
�d���+�t��)�����<�4HK�镃A��;ݖ+(p��:D�;�ߔ��c���nm�Uo�4I�*i��;;M���4/��h�}-��mz��%����4��Sp�����@�\Tz	3��ޜl6�{V�p�JN��\ ��F���؂��gm�t	�S��,Io��5�,G~�}{Q�����b,�J��p K!�oЃqQ��ƹ���N��p����G��PDxR�Rζ��q��K�]���{�@E��e�k���ЪM�Q�b+�^A��ÿr�ͼe0Ё �)O�
��S5���=��M�s�mX#�@bo�
�E���\�	��ra]��v^Q3C�?J>8m݉�^��R�ɲ���},�%
���4B�??-&P��}�V��Z��Ѡ//L�U+Q���iK������h�~;�=O�4�[�WҜ���\� �gj� ��u�z,~�[8��(`HPnR��/��w2�e�=�`���n�-�g|��4���[�r�^N��)%�����h�:ρ���KA_#c���%M<`a�
b.�z+�����:��S
�{�2�x!�h����*�rB��"��(*&8覛Oa��8aN�D�y��3)�h�e�L%�{�4����f�ER��L���1<�O���,Q���%��C_�?y�,F��#z�^���Pƹ+�%�T-LI�1�?��b�׀ƫqe�%��#9~z�;UAQ��|{��P����N��zh.	��K��NI��M�}����N�V|4M�|X�?y���	dCRcM���ȳ��ꈶ̸I&*�g������"~����?�!�9���T�N��8�:P(��U�-��2(Ao��;�Z�!{Y��c7?
9�v�[��"26�S9��u7��V��S���r��)&g����\1�C�l��g��)L���;9��׭=�� 6Z����ԅ��XEk�\)1̔�N�)t r`hM2�3�c�!)}<M�^1Xza�rz��}�pv�	��l�m]������z�P?��8��y;+����Fר�Ҿ:�w�u��ƍ�����A���I��=������&#��A���=O@Y�J���-H\�Az�,�*p�Ȯ�G����i��������v�b�6�ܜ�B-
47�F�Փ��-�MB�;�zJ��{o}�R����kz�d���_7rV����
$_�>���� �u�d�ǃ9��,��"N\g*wT���i��-E�����I�X=�l�����7�<\�AS�C� EɥǼtJ@�^٫�o}@!��K�)�Y��G�B`<Mm
��s��/%����tMq�K�<�j &��*�U�ݟ���G�����p����|�3Z��S}&�{H<�Q�9����c��S�e��n�dM7i�L�ͽy �\���5F�k���e�[��f��lpG�b���Nhd˙M�u�+���i`�9*�V���O�q{����t�x��	�Xw��C0�E�!�zf/�B�s��2��z���%޿k|��(��C,F 1�2������7�Pz
�05���b�D^���D �(e���.81�
A�j�b��r_�-�gfnG����P�Ɩ�[#�;W�d>�=��{r�J�e]t�E�+ygD���$��&&�,��f�:�zU���#�f��oi/��"8t�+(�|�ּ�(#�!�󍔝����V��m�*g��=A�C��s��/��_[xq��Q�a�XyN�a_}�s��M��Z�H���ˡ�J4#�� ��d82"=���ūB��J��b�>H�?�����ˀ�/Fj����5@�:�3x��C640�b��M��7%G5�7�N�.��wnY�y݇�S�d�����܁�k�M�y�����$'@u)up�L���R�ַ��L��"]4�+^.µ�1u�A�d��L:r,�c�"0�fZt���w��{�+I�T�t@o�ϭ��%��FE=����ȧ�����7�w=_5�'AfS�>&�ܸ�n�Ԕ��5��9��k�`�yѝĠ��-tԮ��"�CRLL(;gmP�bD W9�P:F�s�
���K�㢠��Ce'��Ӓ\���/�M "[�#�������[G�`�����/.P3��z�7����T4g��տp�îb��C CK����:����O�. A+���s�>��q�A�!~~�J��#���d���؂���H�J�G�!��'Ȕ���zV)4U�Y�S�稁��<lG�����΅��+�v{𫵽3��c!�g�|8�������=�I�Z~�D�Ơ޸�iN�%��{�J�
�2�
��97)�6DOgM0M���bm�%]��pJ
^�\������*��4��Ð��%���/�*q��v����*@��Onɷ�2���0\J���:i5P�9?�
Krn�� ���ȅ�c��s�(l� ���$�~���p�[�t�ʟx����Ow��0���c���ƙň>>.��0\�vY�G�ы����:;a�!7y���;��_`���YV�CR�)�߻W��9���O^!2 u,)A���ݝ�'Q2��#*7����Pv�����@��ESB��H�;�k�oDSo��<�^�����o��$8��DNh�d�>.��|��'���K���X]��ȋ���s��	Q��kE��,��@����X��^�x���������-�b���M������Nv�-�N?��otI����+vԏf�#�*E�Pd��I��!�J߻�x
���92�B�O������G�JR��#t��&�,�hܜ3c�j.���̯ݶ���9�|#�%���h��X���:F��ǐ
	c}���>Z����(�P�G�a&^W9�P(U���3܆�\X�C�f��:�LY"�"cF���ȵĪ{���N�N��R";�0+�D,?�í�'p^�݂iaD�9{bQ��u�L�����*�Q�	m�@�{�?_'���]�����X֥"�S`���N!bG����D�PߑjΠ] ഔzS�<vLi�W�M��y���&�`�0q��໙}aZ,0[P�'=�����^ 
�GM��/����ra�������tV����<a_ٌΪ2�F����P�@֩���M��þ����_��__��,����h�up�lM�sG�و�"�jlx�PXH�p���K�|֌�o�F)�S�З�O&�L/oћ�:�x�!l� ^�qa-�2�}��2j�C���N��`��h��2�HY���91�|�� ;[�Y�b8�48Y����P�4O��t�QW�7���O�R�cHFS)3�`�����x:@S��i��Aa��M��� ��#���z�PC��+"��i{1Q��NY}
��@��ih7��C���Z�Y��Ӈ)���A�{�utC0ǫ���)A3�ۋu� RR��� ��� ��N�� �?l�����E�q$Yq��.�3�
�C��ꜣ���+Ob]H�
�n�@��xa�Z��XA���~f^ǔ�ȅ�N� s5D�Q�;�E��^D	>��hgժEE��F�٭	X�8��ĉ4x$R���%/c%��c�����UC�/��p�E���
]T2�dY�x�C �a���::� 7�L�a2�W���-h�& Y��n,�m���^\��蕲�WYcS���r�#d�U�	�>�V�!M�+TO=lW����;����Zg�t_��<�?Ɍ���7���������2f8���P�8�A/��K��Ȥ����E�e�,��DU�_���JyP1>b�A� ������״��[�Ҷ�-��h�blS���?���>��/���eΊ��x��dR8�!>��5GIR�G�8��0�J�π6�f���ʪ��6�Yo:��|�s������MA"6h�G����ȠnT��}�N�ƅ�G !Ж�)��
l���9W.XYT��k ���,����"&y����w�b<i @�t�����́Yi�9�=��]��s��|d����E�(�\k����C[��wp�k6�a�u!Ru�����.L����W�����"c�Ш�+�V��������Sz�����ƽg����~+N�)�ܰwW.9����㲶�l^�>�;���@鬂.��k�u�����N��z�s�P+�'���(�s��t�%&@�_�Wq�V��e�����b��;�q/q/�q�����*$��'��Z�kZ"ib�(gU��1$��+��P_f�=�֊��!J���q��� ��&�9�Y��`.�n�1�B�����e���=PF�a�uz��|��������;-ry3q��<��]L�z<��?������"mB��Ps��[;�=�kA� |"�Q5 �2�~0(�*+{}�(�i�p�Q�.f�T� ��+��z���[7���_�+i=�tF,c�s� >8�=;q\�X��1H�òA��#�!Z�MZ�5�۱^��&z�?�:��9�$�)I��{���e�a���X�n�*E�6yA�+��+q���сϭH
5�=���|I��)<f�7ڵ��kU|��~���J�5�ߍ������o��Nq�Y�W.��u�ɲ�XfC,+ן{��_z��T��t����He�����-�6��mӖ5�JU�q��dy��;A4�qߞ��O/p�F�N��R��OV���c��'���a�%'ퟰ�N����Rឱ�߶#�p���2��k
��nJn瞮�Z �$���e�&LN�1����i�HE���0ʹ䘧4/���w�[�E�T=y�2m�m��ߔb�MKSBs襓T"t�-�ɛ�`�P�D։	��/�ꤊ#Q�2���3�%)\B�/=�� R�D�QE[���!�l���'gj	���*�@�T�7�f�����q�f�	��/��:����8\mU�B�:�}�s�K�W��#�iGKK�f�G=�,�-g�8EE�t���^����3�� 	Nb��tY&��Ig-^<P��-�?��rjQ�5W0}���X���g��A�;9��<G,F��b5k�2��ڙ��)�&�w0<ܲ�r��aP����U���і��sY�Q(ҵ���L��K��d򖜸��X���|g��v|R��H����[� =J?8N[I��s��U�kx�u�$���	��B�7��/�*_�>��=L�B�Q���\��;��?�vǔ�����\���V7l����ìq���tk_��R��#B�RU6��x۱��6���d�UU�3+9�`��.��y�P���1��U�`�#A��jr�F�hwVi�?'4��h.���kY�-�yv�V"zg�A� 4��]
�t�\+>�1d����\$0����g�����Q�Ո��l�@�e!Z<H;!�9��գn��7?�����:�z-F�ǋ �&��V�1*�B=ٚf9����t�A�;�}5y��Ϻ���`����_l��!��u2�FK]02��*3���4IN�\C��K�Ԍ���fB\�V����N!�T�S���)R�u�Qd���SO��X;9~�$t�Mj�P5SC��ۡE�N��7���E��g�q#r|�M�eg\�V-O��Ӽ<�g{�e��Pk�t a�Z6rJ��0UQ~a�����!��$K���s��|S�d�<��O7�����A�۱:���.:�vdƩ�T��4'r
Y��a�x��h,��1�Hz��np�����n�}ʛ�Ƶzм޿���P�\�����}�n����PF �Ƅ�D�)���O.��a�u,\ܽq�R���RC�ґf����Ҁ�*�����K"����t	.�,�t+kM{r��Hy�_5���50# �m�*�t{�0հ}�XG?}��N��d�局D�6^�:�T[ܐd�e�RP{��&��0��j�r������i��Y�砥�#�R	L�u"��e����xr�^�D��e:��B�?9�Ґn�1pS�-5g]/�J̛�X=�g������. ���iԋKD�����M�`|�A��H�DX�ź%�7㕖�0��(Q��A����M�"�T��ܑ!�c���S�i��Ƶ�ɂ<6��d�f9�mX��&�~�P����n��z����%�������}�z� #��ǯ �X�=�8�fE��td<��F��~C�j:Hm�);7{l���hҗ�6�"�㑃�r��|�1������b�}&��}��6%L��������V;����
�J�s���Ȭ|Ӫ�<i�C�Z�9�ݡ���C��r6L��K��Ӛq�󔮳'�M0�v"(����^��3�):MOU���`캑�H��H
.aH�'i_�]�[?���3��_�Z�褫�kc�P���#۾1����O��e���y�L��Nn�p�J�/K�{���{��]m������ 7��UK���:�<�G�
N_��9 �=Hr1kA��p�����^�3+���������ݜG��+�I,a�勴B�\��.�EĀ<q��'��H��P�:���Hgߔ�<�f'徭���3i��Tvd�>%Cf����P�fs�.~��D��q���N��I�3��Z,�ֳ�����mEލq�R�<;���Z`�ƞf�\�0���`����V�y�gFͱ=P{,���.%��:IʭjO�R�	5�\(@xW-���p�
>m�hȡ!T�sWگA��V{0o�A����Q�^WL��w{I�o�"@cM��X
u^�\��%��4&#?�(6�@'��ԇ�A��?V�5���?d�t�,��[�����W8M�������6�Yn�8/˿y��|����((��I2L���]������ks�M�X+%	KM���0�'+
���7T�`�eo}�XV!plS�X�r���Ov�_0|���%��'�mӁ'�o4�9$f(��Ի
4�����	vbiY/��/\;I� ��+*�<�&O��^[KOf{h2ޒp�"��ס���l@%0�w�3{
���Yc���o�W!�{�P��	��NF-X��̡C�{ǣ쀙���}��ԋ�����E�(LR
t]�cV���8|(��i�"�	p�p��A��_K�M���(i��Õ
�9�E��r_�_N��5�����m������N�A{=�8��� 2�~��^g�f��G�N�����9*��#=�v\) �}�s�>d�L��ާM�J�k2D��$m%2�~@I��*�W��Fd'�Nb�:�]���*L6�7ܼ�}���x�$(���;(f�u��a�#K�i&�'�_YT�w[�ś����5{gĞ7��~,�syIlF۟sT�ʂd��sE�K�O����_��C��qBG̕2�[񳜽���ܧv�F�a�FN�}��Vp����e�y.���е���[ru��
8W�la���y�{������rC P�K��8��/._��0˱��㻘H�t��/����#OG��m*�)(������Tm��I�a�`��W�	��ٺh�����r��6�a�ߗ6i�w��!i�n��}�}P�;��Ii�n�s�D6j��y����&.�0v���w7<�!�~K�᫶�O�޸_��ӗK�&U�a�#�Z���f����J!�?4@<FV��W� �]$�cҨ2�gU�u�=˔/"�f����9y�R�惧o�6^-U�}����Mq��(�D����6!��[e���g�$|���]4(*)O�6Z*h?�0�8w0[Ȥ�y��u`yI��~�f*aU�������L	k����Q_#��(�8m�ݜV(���h���\�Vܵ���j�;�4��X�x���N	���+?�&�՟�'5���[V*��OBT�oh���ܻ����1�X��1�K���(-�O_/yФ��Ѱ�M?�8���T���;uT�����{��+�\6�@@�(�/:vz�Cq_|�t��ʫ��Ѽ+�/]��[9��h�������Q$�襋W�)�9/��Ң��kػ��N���㝔(ڒ%�>;m�(�,�I���Y2-�P��+E��� �ʃ�zJ�fCx�8k���V~�[�26��vS��j��	�\!�ȹ0�+D~I�Q��̍�V�5%p�d|�'��"rIf���������*Y JM!7����i(���XFD���{��
��L�u鎉0���?���]�5�^U�!����P*��\���Т�)�% F'B&ms�x�p-S��ah�����k�r<�/�6�x٤!h]Q�m���l��e{LY��b&����	i��\��O��l %)@��5��K�h��:��3��mr��
�VF[�/�7�	���<Dn�� .t��kmN$�n4G�Z� �Ωĸ��%\�ʎ���V��c��.���Y�����Y�����X��%s�4�!��"K��,�l��ruY%t���o6�w@�L��*��)"EC�i�D��~�����.֩d��z�P���ry�O>?��l��co�����l��CV�t�|n��#ۢ�kFQ=�a�rs��r��7a�Z�$^���gρS&|�wpT�߈�n��߄o�ϢRK�w��^}���*���~8&� %�S�/������|a�B,=Bj��x%�p�}�D��j�� [�v�<�����_�pL�L�8@�0��l-X��5>Ӣ��"^'�e���t���ԋFE��'��3�IE�r���j�<��p�]X�aK�+�l����s�dШ��cn��Oq�f����$�H~8Y�YN�ΐ��Z*�L��������>E5V��!��容\�j��T'ȫ�5��n;���Dҭ�?.UD �K�y��}��%H��w]c�c�`_������![a_]���;TMe�����9G%0�e!�V��=*2���	.O���k��9s!Ԋ�3��,��y������U~�{��^��	|1H���?�:���)P����r/ͤ������#�����Q��,b:�\���7N��V3��(��\�s���%�;��k$�/g�i����3�HCD�r�L:S���i��є#~m��#����65G	tib��D��q�K���.� ��+7�}�d�f�k������ށ��ŭ��<�X�̛�=��X?A�~H����s�a0J��o'��wO�|F1%������<�Wr���`���c	���s(�ft���ݨ�jq�w<,O)	˺���^��P�vOP��#ǫ���z��8F'}�)���`m�I	K˙��ʓ���rˊJ�)P��V��[���1/#N�<?���NШ����=ܟ��bC�gz\���hq
4�.z���4�t��
����p�S�!��6)����m�6~�Ol,��̆0+�[����L���p@�1�$�xv��+m�Y.鈩zFTl�9�v�	=ӓ��ݷ�R��Ό��JWNa�E�2���x	sx_�s0��-K������	� T6�Xup8��,Ne��6p���Sx���8��t��5v���S�ϡƘ(+YF>���ˍ�	���mFL4]���A���KRƀϴ�!`�U|f:/��|�jP�\޻P�ىdc�435ϲf��Xӭ5�č����������7¯�l�5�T߃����#�������,���:S�z��D���ƬG;�u��f��������_���|6��o�R<&���3�K��Iy��&C8�YN']sˉ��y--T�p���x���@:��XU?Ђ�gN� �+�5���1N���mj��o�J/[�!A�)��(�Gj=�	�¹��v<��>���0R:(��.=��usiU�V=����9�(�ۍ`^�}B�vغ�	PXb��zĐ�a�}ƽ���쭔�K�Z'�)��t�:f�*�����3�.�����Oi���E�T�y���"l���q%m�:�uO��#����ڽ�ht����66�M�}<��q�-��m�+�te�_4.�YC8'��2n�-��PQ�3�{p -�c�ܿ�Y�V�"����O����	2�	�t�A�@�k�eه�U_/~�(��u���8-��n��^`ٻ+b�����'�"<�O=��p��i�������� ����Z�T� �_j-:@_���О���jb~�h�������DkA7���7�����L������ ��0��h�tQ�r��æ 7'=��o��[�o/Cf�&K��vt���gW00��pOH���jv���Q�F'��3�ٸA��C���*��^�uo����C� :���DSJXlH1��4�o����2=�N�q�"�'��P=ʕ��k~�L�~�����Q-$�f��S�7=��Rz[�ܟE%K��dF���mq�F��\Oˉ�����o��r:���9e��I���,�3��3�JCZ0%���������y�6�`��z�q��7����M�\6���³$����U0�[��ѹ@J��m�����`*K��Sr�7��+��֩��N*���9�p��(�fWmZ!y�G�2���NV���+��U������z��jB����B���N~\.ex��?���Pd *5���'�H!��5�����S}+	b/���f*�o��\D-Ct�Ӻ����zmC�Ɲ�{��)P׉<x��@��O$���l��o��tAgZ�E`�����>ࢰY�d�FFTu�`
�xe���/��T2�z��CT�x�#̗R����l��i`qPW�/]WB��t�:�M'I�,c^o,t��k�#'�T���>vz�eR(^�yڝ:fQĩi�mJ3؎Q /�W��ץ?�Z%����Y,���h����Y�)�V�n(D�w�W������Qͩ�����oh����+q��G�&f^�ĺ�)]��ݱ�q��J'���}㗮 �g�t��N����[��]<���|1y�
t����������o c�7_#���Z�h��G4ڪ��RO;�.�L����1Y80s�u��
�-W�^A�L[`��}��n��ا1���j���������(^��7ɩ^��h��фZ���9	�xN�s�M�%�=6��J/}�?q��Z� �F;��j1
��O�Q݆� z�
�i:7����Ĩ�?�4���K)���yx;Q��g#��z��`̴�?~U-��)I��Y�R�:�ۜæf�v�`�&LCR���x8�X��څ^���vI!��C��?O7�'1��#ϏI�џ'F����	��� �z��_c�T$���uٚ��hJ�Z��]̍`=hTsZ�Ya�3�
؎�=��vв��f�l�E�9Vβ	ZK��o*$4����ڨ��X��>�`�C[��>��s�f���[X��r�G��ts.	6�tݠ"I��B#ov,j�.7��Ka���3��4���_^�`&Q{̺�'�7ɮ-:#X�j���`���|�h�t��R��7L�L�υifҜ���.M��Y����R�C!�ETM�c �yK3 t6
ိcɄZ���uJ�P��Mc�I�]�H���}��L8�5�gL,[���:9���y�!���ҵ�1�Vu{�d��W�!���'����ҥC�NQ�ӣ������d���S��#���;.(����ge�ܞ Ya.^��a�v���&$����"����~8��rcm�g��t��ѩ� Ӱ���Vc6�.�}��7��j��< ��S
�L����.P� �v~xz��fV%næ�W�v�?��ǚ1"<w�&E�R<�xd�V��ud@���j�Q��K:M��V�J����D�!,ls�;ǠJ��bR(��ND�ޛ���L2�:/�ި�PK`�e(e��0b��~@5C��L2Ϗ����]՚��8��2�!����m��1B���Q���7*�elh�T��.D��s����蛼_9�G��������\�0����B�U��B���;��m�o���jU��":fo��^��E��	�]��n;���9�_��o�J���W��oJ9�X7�p�]3�����̿c8	B*��.B�=�:�w����Vy�ŦW�Ǧ���҆��x��v��L���u���!��PR���#pp�j��Kb�
=�C}+f��9D{��:���[uнxyK�H�ج�}�[�;��S}�oM���g���6z�wc}֧�Q � ��,�&���l��P�T�=��-B-5��G��K�7ӂ�-:�U�E��p#e�s�5��?����֊�æ�;tC �2� ⦄�E�0�o�բPͷ�@eu��8���q��X&cʱel��hZ/���B)�Ss���|�i��4k���#��^� ��H��W��<1efoӧ ��`�V�*l�z]`��6�Ȼ��@)�����5�c?bt��i��% �.��g�F�eJ���H��r�@�QO�|�"׋��?�d�bBY+E2�_f*LU�~��n��8�9I����ۄIEոٸ���t@"	O��Y�T��7��z�˸kn��<��n*QK�οwx�����Y1��S�H2g��
����������#IQT1I�m%Q]Qi�n�0�F�0/~L�1�)����y=���	�]0_�!��䇸�ɩ�aS��&�2\��AM�
5�F��jPmU.����ّ�������{>�����"c���ܝ�S;>I�	SWL�3�k�|8����|���0Ts�P��d�ê���+�P�H�;|LcM�Ck��C�u���ƅ|��o� �F�=rZy�m�,䮫
E��"DX�"�h�:��j��1��}o�*�e�W�lr=JY� ��)������2�=j�ʃ�cQ�9ý���᥊_��*h���lw�X��(�x'��D� �!�w��uוI�j��;Q�v�Q���f�q��(���&.�גV��G-Փ��#w5�a�h��q*
	��K��iM�t�T��f�1�ǳ>2�UU�wu�� 8�r���O�Q�g�#Cl�zҫ����=�c���QO ��>�3�Gb-~t/2SZ�us��Dm�*�M��x�"�d��6��\j��6�(.K�B��9�U�܈����i��4�GIb�s���2OVߑƫ
'O(]bɜd��W犴��襷�,}ڮ$�~��0�u���C�
n����Tnj���8�*��sShCt���fI�0V��D�!�����5Ɋ�>�H��:�Z�@����ZD )n�`�1b[�W�0AiI!GJ,6��O��o��L,��9�(�&�"2�������׭@?�mb�zR-t0��K��0z%\+��Ⱦ/�X֟RQ�j#��2œ���8D<��?	e�L;՘��t}Y2�&e��[�/���҇%��1tݢL�0T'�nd�&��P�ccy7g�ݫxw��1R����s�7�;�0��]d�i�m�ag��0p�b�W��6{R����K���ew������ �[zd�`�a�^g"�)��*�F�4����q@���3���6�:�X-�����N[m��Q�2L���R�@���8������Y���LA�r�b��hl��,��: ���0�"�p
�h��ܳw@L�XV��kl��M��n�U�٩�;/��q����"�a�$�"�^
>���ܴ�,8^�J&�P��Y���	���2�!l������\��r0h��hJ�z�XSg��Q7��W�O0��NP�R��"2�g\�v�t�{��F:�'�7�P�����qI��Y5���Rn��i�����V�����ؚ�	��I�u?q���AX05I\)&�B�yu,�q���N'�W~~�d��5�,05������P*'��\��AbTA�@RH��que�oF�gNڒ�JMx	����`6�����\WC%̿���h�pe�����F*����r�.���:{��ݮ���+U��'�
�]w�%;����$��*Q���=��W;4��b��H�?.~2k
rW��q|�j�d�Ï�?�h��{��Ro�0�G��~B���dT�Y�<�~��ϴ��s���s[���=kS�,|̆�����ٞ 9�RU�Es��4����`G�JG���2פ�k�SG����7em��Ε籆Si����L�g��C��V����e��� ߶� =3�����2��C�����c��E���:�i��
�\��-T�p�1:�<T�Ҳ�4�9�8`}?1�k�kB�h�Uj:D���˭Z�஬S� �%��K͟K_{m5�H�{jCx�I��g�ľA�+c�t�XDu�k�k��[��yh�~QK�G&�,�������7�>ϘlZ�#c����4qv}L4I7�jը|�`�?t6�q��/h�4���y�wi��I��
����E�� 0���A�`�<|X�z5���wR� �;���\Ӿ橍�Xo�k;���9#*h�{@�;iD��ϒ0���Wy���Ç�,O�ӣ7����f�}zV�(I���oOB�	�a�1���������M��x9vmEPR�PM[��%_S͌}�>��b|��\�Wkzhj�eC^(�h Ҭ%{�<2��4�:E�����&��K1W���Y-hx�%�Y�@1��sŷV�ӿ�������X�O��i�*�L��Y.��:�_����RM�Up��!�q�D��py�P�����76X-�h���xp�p�}
���NPD�=`ܦM�R�Y��ї�w<�e`PY����̪�[��9%���< >SD�D���ֺ�o�_�$�qx��~�V"j[T��4�(�ClU��vD^0��L5�$���ڙ�H�[�~�&X/<:0��Q��q�k .j�_I<��?�47�FA���*�b�x::T�G�1dv���7�I�h�y����G��ˢ��e�1~5Gt��LU�F�g4�eA��2L��kk���D�(��@�����gՍI��].�? �>Y%��<���0d���"�\����x[���B~��ˤڷOdkLj��AQ�^k�͑L>�<>?m	f�B�l��'��oy6��x����)�qp�-yi	J� �.�!����}cL
 ���]���ekFe��s
Fl�X�dK5����(�4�k^ 5^����D�F-�z�'v���B�kh07��v�
�R%�3����&�'��9�ʩau���{��8� fy�T^u�w�v���I��VZ�hJ����o#n��<��c�� #2�g����Y��9y��`F,��G?�Pә�
���!��5���!�PY�mO���ϞeCgeY2K
��k�e�+T_k��M^/���Җ�Ԍ}?a�4�޿����ª�w!�<��	��M�eVh�)��O�.~�Sxlj۪�'sal�ss8�!��C~����������m��)�m|������wĻу�7���G���%���r�)�x��S�%�/8iҔ/>j�=L�Vc�zbB@�Ac����X�Ub��������F���?�%�*Ր�{�R2b�6��? tA�M#tv�4�w�vc��
�1�@�v޿^��9��8GՐ�|،T%1��+�Ǔ̏�n���B�,����,��SL���	�Ep¹���:�c��\v�F=�
(�a~��E*F��S�֌;K(�CE^Ŧ�'Lҝ���=#�o�d�C�s/�����m�-�pWY�3?�;10�`�1T�tr�U����D��B������9_,s�z��;���ǩ���{ �E%GV (�3�뒜�9Դ���f�b�[�[J<�|�}���'��E�ٍ���{>rG7V�[�TG�+��҆Q�5�K��.��-"Cv����ݑK���f�M���'$A�H�.�9���Ӓg��8YU�o't�ŤM�c>�	�W�m�,��#0l��'��[(ykUF��`�З����X=�BP�3v����G��l	����w`WD^H��\R�z��lS�}~�_��p�.\#&[��s�k�u�zQ����0?�r��������on��8�Y�K:�9,�^��3��#�"s��*��A,�t]�-uDF����0N�af� ��Æ�!-�l�H߷��m�D��u8�%<"��Bb%����۝ƒl�:���#��	�R�\���K�_A��0F܂|�����D�RpJiD���׭�Aٚ�>ڗ�{=�w՞�<�ݚ�I�H��hf��v��� ����H.��Su�}҃�$��Qk<��a6c�ˑp@f�{���=�u�w��d�<�����Z��{�voaW��l@>��e�e�z���t,Z�z�I�|o�#t��0h8O{<Ifߡ��g����=bYP��Ķ��hA%<l�~B�AJi}�ؔBt193Ԝ�Lu)��9s����Q�9,�:���OS��ڱ�\d���¨����y���=O�)2h��܁Ny��^�X��C,���;�;e��$�O�ǋ,��[V�����ڝ��v��I4�{��=��<��jK��Ib�\��s���u?��("�Vl�:��Q�=�}�����;B�T����{��?D�EaB�g(d�_TF� �- ��b}5����Il�����"+tA9sŵ:o���%�M�����R9K����Ft����E������X����k�~���HI�r�zx����~��,|�ž�B��D-�1�k�`�y����|!X���r8����*GL�ä׽���ƭc~�@���������1��@/�,c��Fb;n��|4F�,r�!ю�-!���J��������,������f$����x~B��u6D���"q�=�1�t�\-&b [�nC���	D$ao�Đ�U�sE�˫��Wˌ5cQ��V�M�B�a|�9����0N��g6���F{�6�o���ϒF�ϛ������9n[�V�4R�������C��I��4ў�?2�r�O�X:��+y4q�F�G�2�FB"Xd�p�{Ѐ(iX����5����+x�|�6�uߤ4X(NB��l�ދ��qp@�2,�%�����I�ͽ~��'w��'�͗��g�e8r%%<�)]n׬�b�h ��-4�GR�mj��w1�VУi�o�*1�<ժ+DC&��\�Շ���� �M^�x/4��� �|0�<<I�ׂ
�;sB�����H=�;K�%8��A+�7�>D� ��[NCC�VD�s����6�ŶG��	��-�h���9rxSp�A)�!r�
��>�Q�>��%��W ^
��WSi����:�p��g�cT�C��)��\���DXbS�"q�#~���k�t��!)p��q�;!^���$�H��A	�����;a��T��W�߆Ů����h6O�j��V�����G����l�+t�7�ad�a��sq]g�xW�R �ĳ����2Hlu��m���fԉk�R��n�^0�����\sVo�]��ĄCWb)��ƒ�M� �D?諘]|	Y;zuo~����z����C�����\��+;�ژN�H B�K��pOl�:?����-۔Ж��+8T[{�b��9��^�5x�7۹W�6fW)t��7I��H��s"`$ E��GF��~�a �G嬣^B=´�t�z��yX<�J9[,�h��%}�Θ$�`�ﴙN����ȸ`�YW?���'�h�w��{m���֭EKM� ��퇊�`m<�|�e^�~��ˮ�ɥ> �H��CcбEi�kԟ�ߐ����G��@w�y퍕N׀� ��Um�8��q!���'��F��{�b�-��-���N�%}�.l&F9�����Z��NGJBӒ��9O�#D��#f�F:�*d�,�F$�ҟ�'��6�_��}�[Z���� �;��t�j>�n}لɰM�'�_�h�;�04�B��&a���h�W:P=o���v��I����H�j�?�y��� ^�����/���?]�_�ġ�V�Q#���I��k�taԻ���_�`��/I1aW�R��E���?�IJ��т�QQJ�yն'������. ��=e�·��>�"<���z(+n��|2��OI���ْ�gx�%�'�'����q�kZ�\��R�dр���sq'�+����hm|BU ����B	�*��E�^��+��%4�ӊzj�/�(��- ��-L��W���)���[!�r~N���{0�� ��ݏ�f�fu�c�0vq촼TEOc��/r�8i��ԖI�IjGn�اEwVj&-b��O��s�^F}@�)���J�����{M4�{؜]��-k���ǹ�~��(�[G9J�9�����\6�Z�j�N���X��l�S�OϷנ��u�J�!��i!�YM>k��C�-��|���ZqfN\�KB��S�����Fw?G�U���_Y�e�+d��}&��^�0�p5!zL~�-*Vx&��Ю�a5P�B��.XM�<�Z�Xœ�w��_c��-�����:%��s��k8�pV��01�d���?�mp��_9��7�z�j�`��L˥�;vY�5�/�)�\�o���D1�ߠ�����\�[u��8�0qyv`�q� ��a��4�#���&}�J�>�vF��;�T�U��&p��eX��S�	>-����]�1�]� �Y`��n��@�x����`\1��/Y�8�o��u�K���fᰘx2��?���ǳ���h�i#��6X�m�^�ޱ�=n%H�9�c$:�,���Y�}�O�-<\�y�	Pg7(#�\�-�׻��흙g���3�������f�� ��:6�T��� q��� \m@H��%M���� &���	��.���<���Ja��7�.�oP�j�#_���)�
����`dU���{��EY�XP�E<��ɒ�/#�e	ԍ �Y*|a߶|���W���6m�g�D��Ֆ�6���4�AEu��Km��h��YY�~�/���<�d���W18��6Dϰ�wEu�� �U����Ļ��ClLu������&�ᚨP}���	rō4.������?��XK��:m[wT�{�Q�3Ӯ��c1�yk2�h	֤���=��t�M�薱f M���9@�k�M� �Nc,��K]�ދ}�yM�@
e��l�?ZIyHa�r5�eL*�)�� �����9G�ǅ�qza�{ � N�啄��ρ��,��Dv��	7�\ǂ��ۑ.����B�tc��:q�q o�%���]-�l���JH�l���70�q�U1X_�`�m	��KM"�b��,�e�G�U��ҫU��>��/g?�P-��xI��󲴖@�W'N*� Bv��K�]����u�-��Ug�����u����v΅�������-�m/!1�-BY*Q�-s��(Zj%<G�	_%u�Xr���VEnG��7��S�0W�Za"^�^����U�BֵC��k͹��;���{�21�Ė�3���y՝�\��q���O3�^�=�8<h'�B^ʶ���A��2��5*�X�%�������0� V��3E&~�9lɘ��O��f3��Fi����%�~�N[|�k�0g/�H=����:^6a�tm�xٔ�y�:˿�D��Q��8��gќ+�Y����sL��١P4@(NL�/؛|��������S���� �§۠AYZ���j�7&��+s��ҍqd2[B�[7�];f�/l�����U1���i���Y�%|V2��[1�	�gS�������{���0PkF�����
n,}BQ�{GE��6h>�Hj�]��^��5ڀlߜ�����v��P���d�Z|��<X��@,]`yK�4�!HM�]I��7����t���u��>T-DI����<�ӥQŵ�-��6r����ts8���*韑�W����w;����t����fF�+5i��-
�q�n@Mtl�oSx�aJ�����i�k��0-��s>���׈��m��u�am��~QԽ�䄙���M�V���G�)w��!���b�w*�S�i�H���#�.j	af&3e�;�4�ձq�&��jsc)�q���{��ɗ����8���+�N�<"7�/��h$C �8�(F�찚���7j�2uٲ���y�̆8�7:p�gؓF� ȷc/�B3�*DC�6��E�vO�nw�}���"�&����T���	N�L�Z#��z��K�/C����H�D�e�y>�L46���շ�[��K�+���]����Zr6��y�,F�;���t2�W|ھ͞���k`yj�5삐�16,䠒�����t�e��G�t��nw���������)I�O���嘖����������r�=�������d�q�tT곰~��0&`����1kC p&{\����D���{�?���=%�N��2wsmn��s�ξ��k��v� �jh�{5ٓ6H`0&��!S�o'���]�r��y�:0(���w��h�@��; $JVƤt�v�e.�c��u�����Ue���+��!�#�1�<��8�T�Y\���������G\���!�����Y�����=F�i��-�߬�����曞��vXU���ʮ^�y2vg��E!�K�Z��~ �o��a��.�&���w�(�����{e�'񨆊���	+�?�s�"���u�yУ��A�_��,�E/wA��]����$�;�R<�诹$��̣����Epu���Nd`�,�����s'_}7���=g�x���m�s�2�j?EMt�k9[Mc����wh��X���mC������5ߓ���/?��)e��:��z�	���M�{�󴭿猈��V�B�,��T�B\\BP�ͨ_wJ�1���bHE&2U�"�x�Za���K�+��������w�>�t�˧S���3!��%6Q���Y;S����.Uh�ʽ�$�j2�]�\+�����9)H"�6���@k[r���Ȩ��7�2,ք�=2�{̝g�8��0|}��W��ek��S����z2�Z�k'ۓt��0��Fs�) Ǔ�z��C��N��1�R� �ܴVf�[���⃳j5x�76W��Nx���雎捐�=��z�W䘝"��I��l�u���z5�E� �E�_S�X��C ,m�H��[�!^��Ŷ�3���x�]��9Iwa��+�� ������-K��(�.�3�[�`T
�I.a{,z�D�3�k�w��Jҡ��+d���Z6l�%�'�
�/�$�����z�J-�M��R����D=%y@pU���t�#5����h��'� �!D�u�sӰ���H�/5>Z�%Ӄ�e����X������8�g�N�Q��(\��U�<yq�R�>��P�;��f�d*�|(x?�C����\u�iv�\s�G!T=���H�>S�_�uF�Q1>�9�S�g}�c`��1�uq�_�!|��te���#��7`{���P��-#�1/
���-G3:��VP7@�kvG60�W �8)�m��2�[ms�ya���4�/	?rz�ȒV���k\��n�C�nu|�|� �/ө�D3Yp����D	�Q��� !n[�T���k���!�닙���],H9��f���iI8��*��8��FJ�bX9E6~�֩�u��O+ԝ�M��=�WN��ߵ@G=rP��gȋ��Իb.C�D�az�����W�n�����#���wK�7 ƐE�("J9[��1��n>����f^�n>�7Jh���|(��-]�ǘ���Q-!K��j�Y�c<@�����n������u<�G�M���
C�� �<��:ƶ��c���2%y�f"r}:0ži�	�E�!�n9φ�4}�:�}�F����t�[kȳ1�6��Q�#ҩ��}�J$z~�O���ڕS���K��e�P��b��:�
�i������JQԏ��ځх��i���Kh�����u9y��,�b@���
CU�1����͒)�J�kU[{��Kn��*�*)�$�������u�;��Q��rL��O(�t@�TH!զ|y�RJ4ՅRҿ�o<�C�4����O��vԅ�����Mr��zO҄"��O����6���;��ϐ� ���cȴ�~�ۂ���n�H�.:�]��9똟��st����9�ͺ:�(�{�b��Z�P �'��
M���4������v�66[��(<��'�4ni��,8"�S�gH{49������׭0-�~���_~�4�βn�?�9��� �v���IY#&�D��X�S�R�>p�y�%��2:LyY�4�$m�����*���6�o>㻴��v���^uN�뤔����y�*�U�h��ƹb�H�n%[�>�j���l���U��[�HqL��E�Wk�h��}̦}���-#���z�l]�>3dI��P8T�&��)� `�ܬ�_lPݍ�mlt�^���H�p D+����G��&�5r�d]パ@��T
���hXy�:H�V/���ؼ�����1��dXN _���mE�f>B��+<�G.?�n :V��&����>"s/fN��C4(����K�ԙn���9ﲙͥ��e�A�J<+�6O��[�7�0,��!�Q���A��7���xf�=�[;���y��muɝ�.?�v[¾3"�i����*dr�j���݁Kw)ߴس<#Z�°ǳc�ˇ*��"sMc���G�`v�
L��]���iYM��;�į=�zٶ"��z:Vq@���a������������չ��j��P4PT�mfU���?���I�1FO;��J�u����Nv,S}����H?�eWx�%ŚMa�e��U�*�][k��
@�j 6���C��l"RC�?7�kx�=�)U?d�f�f�$���@�7 ��OD��
,=�-���;���J�%�Cc(�C%�Wқ����oɢV��V��hJw`��X ��~��uMn�;�?.&��k	�KE6}D����ZJ��w���)���~�?YFt0�r&��iH�T��c�RQU18��u*���������}9
J�~�HT�����e���#ok=��/��k�L!�ϲ�>�#F$E�DN�?��9�R �0�Z�fտ9�ͩ-���t�$�D�>a��<��>�*0Y�O��K�}p3z%@�VR���[� А?����CvmSxh@R� � �HA�����������Z:  ���ޝ�K4 ���:����g�    YZ