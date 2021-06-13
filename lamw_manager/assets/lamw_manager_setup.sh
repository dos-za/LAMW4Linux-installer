#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2911175301"
MD5="419674ded3066d4d1c4094ea60d63a1b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21236"
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
	echo Date of packaging: Sun Jun 13 14:34:50 -03 2021
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
�7zXZ  �ִF !   �X���R�] �}��1Dd]����P�t�D�s�]�����3�:ɕ�.@%�����`�5�C�,���r_����+��� ��Q�iWA�p�>���M�C�[�u̷H[o+��f?����$W��A��������HK�:�	3R�-�Nc5
�� X�1�wӘ=*��m%z���z�����u�oӈa�g��`�b��ғ�&!�`6�^��Yz�Q�YY��x�u��4C�(>�{�)�AB/����M���B-�10���q	S0�����Bc+��͔ħ����� �;�O����Ȃ�zp�KI+kUh�5��<:2�!������o�\��'s�ڿ욞�-���~��ϓ�=��3ք�(�u�M���+W�P�Zvo�̝r�W�[ @
V05b�b�9��"�afG�=�~������J����f�����{�����Fߩ|�U�e�<Mr޳�VC}�6(����:�2���#JZy	��-�;�@�C��S�{Ћ}`A�?��o��,�m�2JM:5c������a���H���n����Յ?�=���m�U?�Y�����l)��%X1W�!7:8�F��.��.�vmذe�(bw�w��|�$�i�L���@DV|��5f5AwRyG�̾؆&�=���t^gWy�_}s���{��]w�(�ދ��@��5�#C�U�T0�O^����_-�dP3*A:������?}��A�:u����j�I�n��>gA�1�󘏅��BbI-/u��W�?Tl �+S�>N�Q"����C��+J�O��P@�GmE�,#�b���L�����A�rƦ��5p,|�#yu?��ҁ��G��3FUA���[�ֿ�%��8dhB����`Q�ai˱B�ߣ�tp�<~%�����m������w����N>�~'�|=������0�D����Ez�"%�`�ω����]��ح(0[�7Aй���@���q��p��F�򚖀�e�6� K�S��w��EB�KV�尮�鶻-��z�Z��>%P�ͨh�~r(J�ᏻ���A�_{8Oɓ�~M�5z�O�{ϖ�~�o����ZoE�M��7"I4׌�5�7/��	r��x{:)�g��=��ϰ��me)$���f` ����o�.�����(�5�*xY�����@w�~����q<�X#�He���vB�F�h��!�qk="��Q�0��$�u
�xNv�3�5-ܭ���4�5_ ʩm��R�M
����?Ra>���i2��C:Z��J�������?�a(锹��R�o�Ƞ����Ey+_�J͂�Gx8���#z�`	ۙ>i����)8=����VUN����ߏ�i/LC�<�:f��9�ɳ9�'��%3]��ګ^V$�X�-.y���*�)h�]�Q��k������j@B�����q�e�~��Ű��C��p1j���={�I���5
[$��s�<*(&T��Rq=�x�)\��ڟ22�@�O�eOIN���- ���ľMFo��W�#��v�N�ю1�^�*���4d�6�A?Ȉ��Ȍ�9�p��D��d���ص��$E��9�L/J̎��(ސ>��.�T|���Mf���=揉���R6�9��?S���C�՟O��I7��6���t�|��Ax����{�!s@�k������������'?t����ɡ����}�iv�kzS�+zha�=I$o�!+����kx���Q��%�5��F�{��x�C�U�,(��d#�^Nb��w���k'l�3<��D�t��Ih��<�?錵��Ig�"zE���d�Ă��x'�'�+�<�qBEX�|ձm�S"33%�F��5��XN��x �@��1eǢX�cJ���&m�&t/�\u"9=�
�����p�5q��u�;�)}���g@.*���i�Tnf�&�2$m��o����i ���F���c��~@�+F�,z9�n�Z��y�J��}nG�f�p��) �w�U�a��Y=!?k�dr�V(�#�������:�e	��!򜳰^���ãMƐs��2]�J˩��G�k�ft� ��vb*�b{���w�+��B�v�#��_�E�>�b��R9��;�����2�s�������V�IPY4�q��@EV�'d���m"�_���)5#�E	cnUWIƥ>������7C瓰�G��� ���=~���Q�I�*N����'CP������7%���=�>oR���.�оr��t]�A�NI��kY�ZH�!��w�����#�L��fw�"���~Q5]��]��A���ᯮ1��7���\�����e�:�o[՝�1�?��m�����5_0�串#%��7݊	��ۤЙ���w�*о#��vB���+��"at|�w߂$ʚ|L�5��������Q��Dg�VJ�+�Y�Z�=క:%a���-؎��w�7'��$+K �"��Z�n�>��M�Bp����Nk�V��1�rzS�׀�p�!�3c��2���id���m�c�#��*e��INg� ���T����Le�
�&Ѽv�|�DjQ"Հe��'��r[o!��W��}�0��\�q���e��0�Ю#��MK��c�4\����Ý���_GJz�wk,>m�
���oQx�����5���1��Z�G�,Ǩ�OϾ��J0�x�.s ��8���_~H��U9�_��քB\�_��r2X�|6^SQ͒�M��B�
v-7����3U�ܛ�������ʌ{:���b��!�Q�36q%#)��C��6��lDE�E��#��e�w�h���8�|@�d}O�6�Ov"|h%�)i�W�@�#RJ
����t�|�#$�����OfnY�}����	�FlCM�B�e
¦)����KL`m��9�Da��/6��t�n(�	Dz����y��t�r������#�ۖ�j<�)����u���%��"�	���p����r\��_~������}[���LFo0��H�X!{7cg�DxMT�;Y��F�9�wKN�)�j�1�֐x��u��)z#x������ry�I���l�E�?��හ � H�ҽ�pŢjH���s���Z3�w�D�@����5J4���QRB���F#��?���օ�o$�m��zW��^����]加q7�h!"�E�dc�:3�ϼ(�Mr{��V$	�a����0q�i�q	`ڭ�
H��_�P���� �J�K����䇁��B�UI��vI�2& �yz:+�+s\����l����e͗'��H�o 4��>��d�	�B�@tE0*F��;��xh]�~[�d�J��<�֌��A1\�w&"�Bykj ��Cm�cH���Y�n�S��e�2�Z�	��
G�:�v�L������O����fӨtj���7��6�~�%�ߖp�;�Y�;�s~)ۣ���Ro�R��2�ȹwݗ��"�A^������e-X6ě���k�/���6>��۰$�
�E�	�ܝ�ͅS,vxvܯw�����Ze�j�Q"�9T�@��`|�z܂���N�qW�!�! x�|n+�q� ��&���&�E�/�@QZ-қ�H��E�4�6(�;��K��� 2-j�t��^�'��q5о�6����	0Xt1qc>�i�D����
��`ô��|�P��h&��*���P���c��`��\�۞�횉gӾϷ�,�*Sж,�����2<�+�oʃL�I����`��Q��qZ� ���N>�/Fܰ��2'>ӋA��L�+�(���g�V�d1�x�C�K�'�}P�$ZL��{�}��f�e�A���y�1K̦��&o^S�T���#J��ɧ}T���i>�a�[��o�N*��pyr�=���,*��1�<1ĻJa>�/�U0qm�
�{��7��iG��@PDx��2If�x�x92�h,�e{�踳lߎŧ&��M0�j��P6	��-m����"�m��ţ�a��/��M(,l���^DW_�𔼃��e-6�
�wbM=Dkd�7�Gs��w/�8F|��~�'P��J���g�TIS�|�_m����<��mf��"�Ȁ�ul�{)�ȝ�MY<���᪗���tH����^�� Ū��m^��������Mں��G�t�TJ�����{�j�xޝ�z���|W-���й�-kk�MG.�J����8���J-�
��Cg�D��੏�Z������l��?��o�/Z��ؖ79�7�|�9�T"�Kk�'7��g���`��4�����|�B#�_��h�ޮ�uDy+VA�R�`$�'Xydz�+��)�7\{��~|x.�X��*�a<{Ϫ\jܱ�kV��S��q�7	�3�k�m�ڪ7���z�x�]�(�S�S�� gdM�pE�wq5���
<M�B�M���o��.��C4��t
[���xc�����a��V��M�p.�f-C���RA����,A� ���7����uC�燗��y�7;�@)s��¢d2����W�g��t��sn���tT�<p}S�tZ��V��1���S�q��mV���������aSЊ{M�z�� �j���J��~Uxąyp2�O|�gcV�D�S)���tqw,���T����{�K&�ZE�v��/b`�WX@�C�4���-+"_���ຼ�\�Y��ME�T~���T5`�}�漟ntz�58��,<�/�:Fp����M�y���OifPڙ�G7Da
~bɳe�o]�g�mxr�ے7�v��$��󲡾���Ƅ.F�M��:̊.�T�R�_VPPS�g��{ˎ�y��2�+��Xsn��C�A��k��ŷ"!F���C��XP�՞9Z�i.�� b�����2u�a_ZT=5d����Kf��D,I�_�Urb=��R��O~.:�ޕ@d��՜���z�?kH�k
 5�� ��k�L:u��i���!��/���֓�YK�����#�w*�6��)��Hu
��nA�VX��u���f�4�����MM2|�MP�b���\(�}�7B�?����8��fΞ�HW���L��;�xA=�5�ǻo����X^�I]�G0"Dz��{k( 
�gv=Mc��((vd3��N�5�e�T��������BV`I��)M��K��(.�Z:����q����Փd��5�K�jjІ��-����V"k�/�O��u�4I$�-���
b�j�w��r�K&m�����=M��O;fBg'ʀ*q	.L����S��Q�@+Y��g�{Q,�c21x�I��^�
GsQM�훜T���u��îr6���fB���������Zi��=�z���%3�IL��1%mP��������4<4�}k^��ǯ�R�	7�$D���Ls�Ɣ�Բ��:��WdqL��S�n��F�40�XWD���R3��'M3{��VAYj���=D_��!`*L�i�~>���%;#�w�$p,�p�)R��ʜw����-��&ݒeL�W�$35WX�8n���6a~s���y}������뻚&BP�FAU�.������k���̧�U{A��e�[4��ݘ��79y  ��<�Z9�I���U$dh�6�n��I�n恚����#�j�D�.���1�!�å����t2� �ʀ!|�B����:εk܃�K����D�>�Xp_�Oa��=@�He��+LX>xt0*��E� ��,�2���6��w]��τ���d�+!a�9��])�w�t�-/3��7��˶F�/�Q�㇂�oU�-X1�Z���('3��%�T���id喙�@]ϥ-��c��"�����	A��oT&>�Z:�bc~X��h</����cHQ�Ǟ���ZG�uj��s�.Y�˪S2P�e=Z
�o���xi�V�_3��q4c���i���=�h�N��$�l�-��=J\��=��=�ͺ����n0PO��i�P��_yo�=�3��ь�*�~��� r�h�Fǖ?������0}�8�t�	��\IC)5�2p����Q�;�|�+;��|�۾?T
	Ä@�O�]z�_���~e�'��d�)��zg%]�s�c�*��۠.����0��{���r|���^N��W���7��|���^<a�Y�Iω�g�������+���k���oŏ��h�p,c��G�{Wh��$��c�D­'�g���}pC�9��)\z���h����,Ű��0rF%@�v�g1��W�Üx���5nj��kԃP��8^uN���^�����4.Ϣ�0[oxyW�M���l)O���&�F��8��UQX5� ��%��#�L��֜�q�`���Y�G%�����!;a�hNɭ>N<���Lr���ɒ��F�8�&���D�3'(Ɍ�,�K����pco�-��b!��"�:ed�����ؙ�t���������)�J��1����B�э��?��M|�l�mͥ�f'�mv8�μ����p�h���8I���)q�G�)]����s��jׄ���Ȉ��4K�w�"잆�j5������Ȧ4s��� ��yݻ{�S�o�<����(����/��̾��A�� u�lmt���3GL���������䠼v�sǈ��`�lv��O'�=��O��D=�:�v�+��ޠ��Q����<�2�� 18'�#`��&��Dա;Jb'�W|���#b�2&l�5��������拱�/�ط5d{��&��s�XB�[��#����`�]Fv'��R�0���X���ًH|��K?��F��e�a:���<����ݱ;P�ܰ��@ƴ4���_{R.��u��e���{����6FV7�y��2�pW�_�#��'�G/3���G��M�f-6���V���1,J-{����I������z�Rr�ľs�v�FM5L+�{��OQ�c��(�sݰR�-O�&b�Й`il�2��0&n3]_����pu�x��;H��"/���[���!\���:dGd$tqq����3(�9�V+�?'��>��M��ҙ�S��)�Xŋ���Tյ 3�uMD5|�6��-���t��C�Jz0B�1�~�j���W^d�|[�;��ĩ���Te-����^;(q}���ջ�m:����3���'6��������D���ީ�K�1y[� 9��5��V�좃M/ۀR��
c�B�ω�� 9%z�)�r�|q��X��RZI2x�)��j�bC(A�D��t��`T�R!0C�=�;�(����=_7��;�͒-����У�r�2u�W�+nem���8��3)(�@S/�O�B�`]LPl����nfh�A�+�s������p�{�]n:������7�8ɓ
����P\eD����ݬfBx��v�J��ט��v$�T"�+h�����]���D��M�Q���4����י�c|����nP��()�W��wt)z��QR�9���o�
�=��i��q�(��@����wH�e��92K���7~|&������em��q-��v+��; ���~Z@�ھ��(\�d�b��N��7|6��U�c/����7�}�1|گZc��@�[IeK�"ɟ���5�����]�Z4��>��ɬ���oT��|M���V��6���g���t+Z��k����G,���;w�������|[�O� ��Ny?�+N���5HZv$��x��o�Ց�8�	㸙�[u��[�{�����K˚3(~Ժ����=�/��"�9'O��SQ/Q�S�3�>��W��
":�~�%���H��b��=:'�0��^�ݲ�g���̹��x� ����ٻOi�M�d�7S�Tbk��f%c��S/�0�vI��%~�=��t���#4��)R�݄��O��胈�:� ����I�j]`X�4}���O��X�X?��d�ԛ�5=�����V~��y�MJ�7�Q�K�C�^��&!Π>�xnȜ�iT̤��,XLTݶ4ȕ]�s�����0�8�E�@��	���`�ه����	U�,�27����f����������^.�.�a�6Kp��1�k��5�%HbN�	���\����*�!dO�9:)�=#&6P��71
ߪWalӰ^�dP���������U"�����u7�(����$�Y��w"������^�7U���d���U>$�d��!Bm�����
�S���L�Q~C28M0+4~�jf?�&YS�a����&z�X&bS\ʫKK� ��Ѵ�c� ^�.{��;�
-�6)Yc�,Q���n�e�£c�NBÏ�9��	��=��L��c�S�H�W�*�fk������M��l%�����Uɂ �
Ȅ �aZ�$��/�<x���	���b��'6x�N��Q,��|��K��ST!9� f
=7b�L)(��Q�p���cc����BP�-0��I� �0�W�1�̗�u��Z�Y�Y�l=Q�v�F��+�s$^���ט)�b��i��'Q�8�ﭐ���|c:J�P����}�B]�+P�(]1�|��C[�U�uHs�!�����Y�cawޕV�3 �^�[�A�.�;�?��(� ���j�%���/�17���=���z�߻	b�҇~��)4{~��L ]H_t
>��R�s�S���:�e��Ԝ��*?��C���9�4�����_��ȇ��ȍ��#��ʜ����*�2X����I�[�[GQ�l ֞6Y�r����8A�;�S>�l����h0�4;iǳR��Kn��?N�� ��$"��W�?'㍼h�-V�}|�H����7��w���w	��haУ��+��[�~>�;+����"�����[�O�f�\� ��8���I���z��+�em4�j<�!�vV���D���W�߅���C��o�ɆpU��I��a6��Œ��ѥ�Ш��5QL8���-�,,f��#%�ٻ���vG�$��d�G�9��\t�᦮�z��wctQ��-�y�EBl����&�n��u�"6U�`�����0-y���r�g�& [�����m�-h�*dN�L�ߙ�ʜ%D�b�7<+�|<ˑ|:�Ö�ղ�-�)���V�XYlG�nsJ�0�?p��S�����r��ƣ��\!�E3�r� ��<۳��и%�SN��Z�
�Scƍ@�	#k�[\�L�x���y�L*5*��D<@��-����W��E'YxC �.9�&{�[��J�JTCb��k�o��X�C~�>�D��f�m��q�$���
��s�fN?҉X�8b|Տ�
�k�S�9E�.�<��pܨ�_q������f+Y'��I�u� �����1��!2�ΰ�w���-��8-��`A�2����-pޟ���&#� '}�I�q/Y �RO:���k���Ԅ�p�9��6�u�����'�Y2�a��¢�O��*� x3աֈ�:t�4���ĭ��Ɏ��Ҫ>���G�>�}OF�$H��^{���nd��e�X/sE�Y�]
�c��A�n���=B�
�΀�%A�'�\!��0Wz�!�F�~��Fc?�5��s��k���>�h���b]r%�*]&�������&��9a�F�.�Є��^-���B~���V��S��|ڨ�h���J�Z����X
7����Y��M��@.�?rD@�b����W 
s!$��r�.�@QH���������ATxc�G�´�@��!jD0FadB�c�e�[�\��C
NFͨ���<`��R�5�N%�v�v�bY3�,SLR��)R����t�i�6�R#�aš;�E��pkZ)�����}�|<4�"���c
�����Qqw���M�sU�յ�Ε���D��>6[U�S�D��x4����֡b��t��p����
B�ܽ��L�Ě���Du��ˎJ��yE<)��I27�xO��_�8��%�Q�>��&7i,��7�[�D������K3�.y��^�C�����.�g�7j˅8�]#����H1�p%{��0���V��������5l���&��ga�^�L��qٰ����Xڬ�?-�5L�:Ӭ�C����K�A�H�k�{���K�]���F���~�)6���a}�~ ��Z�GAI>ѽ����w5-Ge���&���"x�@��p��\��Z��y,b��l�׹sj-k�-L?D{��U�FT�+מq�.����*��UkxDe��7�e�?<:"����!��4Tf�8 �y�3�%a��X7�z�$�;Bm������A��Hm����<x�؁�B���y�.�L�H/y��~�u����ݟ-5^^�l!&�A_�ڢ_�"=vc�S5w�m
grJ3c�#�ֆp���x���d;��u���kj|Re�>߉�
�1��ڳ(�)������~qW�F�������đS�م��@X��'cEw���xy�4�h��A�M��y��=6�ʼ����ȕ��h���(���4�����(���W�:a�~�E��q�F|	�J�j��'�^���B�@K3`,|���x}�	�G_#���˯�G�dl�wH0�q�{�P�����<�u�ߢqXM�kĜ��A,K(���ZkP�f��[�u� p�fm���t�>�?�,Δu݁Nη��Cv��>>kc���C�y�8��22}�(Ʌg���ab�^�<3�s�7�_�,�Km�v���z=�{�� I�-��uэK:?�jA�wi\Q�9Z +zm!�z�`���t���%ak���K� ��Y���5}�9[׻U�̌y{�aԏk�IB*���|k��sIݺ���)�=D��4��I��^I�P�7E(��6�S��4� y���/������^:nj�E�-!fI��VT>�� �<�~�y��#j_&t�ud]Wd�4�#*\�� !�F���w)&�H��O�������SoÔ��Km>$�����I9����ڄ,=m�E����.|�)�_���=V�7�\Fp�_һ��D���"rbgy���B����\W�[&[��sS�a�oR�L�r���YGZ4�+��[s3�ZHE�\t
l8=SO��P��qh ƺu��Y��,��u֔�*��>�Ok��_~sn�:vC[s޿7u	%e�hK��7(�Y^,J"#��ftB�F�$@��lc`�������<J����0��kJ��B����>`�x������Sɭn��ۑ�V��y��{��T��5�K%�D&���IX�.��	�y|dqǑ�%<����'��*	-}\k��Z!=k����a!�����h 8��@Da%���˗/��-Ѧ����~�����tج��$JS�\?��#��Gz�Է���.�_f�5�w��ZY1�S�H�a4��E�ı���M�u�?�ݬ�׫a������OZ��vpb�b���/�	m�@���qѬ�͎N�&�ϒ���󮃯:�y�J��ⶩ��� ��L�Buo�0�아%�F����VjX-JckULZ�|8��S����>x�,�qL��SD奎&*�	�T���-��ؐx5r���Шx?I�k����#8ھ�L��2N.x���ŭ�൴I�S�vu3PS[e8	0���TwƠ�'@���V%*��8��Ηb�W��YRK�
�� w�sTԑ3��?���
���YF�E	:N�YN��h��cFk5�D'J���8v��H��0�I%V��V����r��B���Y�u+b�oԭ0�C���xÉ�D��j������8���#��
?�U�˗i�i���j@WŮ����t� 6�^�u0�̓��{H2��LX�+ߌ�����v�ne�_�nā��7��d	.�DRr.Ma[��h+�Bo�N��ޅ
�h�X�\�8B�)Rk�����[��H�I�b0#���?�����C�?${9:*�(�����4�p�rK��T�uoQiՁ�α3͇69;��f`���DzO��ˈ�� F
�q\ipQk =rG����	��5#8����]+����G�+�A��hJ  ����!;�΢#�&:�g���m�Б�����lW���=S;� )X�f�쵻 ���~n؟�
F�����9�4�S��'��{��Q��3�9~+'K���E��-�4[S�@TA�)�̾���+�n	���ʡ��/ū*>��n��oXcɏ�3$&�Y�#���YIB�^�?�G`��U�k+b?Ȯ�-:ow�L��J@K��p��C�[�O$�lشAjӦ����
eZK�����r�8HZBL�L���f��nZ^~B֖p�1^.ܳmA˸1�j���x
t��p7`�Q�>�ka�G����^89>��B�`�����2b��S�(�m��~�����H�,(��ʪ|`�?e���h:��6�����̞��fU�_zI�Ci�e�_�7�K�/Iy�ս �Lw4��C��:ـÀ�4�
ySy{����=O]����hd~�����1� S<H����(��J�դO�<�?k��7���	��A�1��.�22����#9�'"�
4�;�D�2C��Gz>�&��Я��1�C��ٙ�` ,X|�o�򨽩���H��� ��I>�@�a�]���'X/����4�v��c}c�7P�d�/a������w�y4hl���4+I+�b�h��`|g����\zl��Z��kyp��m�C��a�?G=��ޚ�w����Z�0�/�yߌ��vʅ�q�"p���f�~����h���L��'͎*�\��8IcV�Lx�RK�-<j	�`b�\p���-VBf,��F���4Ač��j�Н�kiX�>�}eOw�1�O�u����.s^��eE.��!_0{4�|��V�p3[�W�?ƅm�D�E.��sOYQ0�<�Di7��I��Uʪb4F��D�������[8OMP�NCAs?�Z��pm�g��ǯ�5�}_�z|��c\U5�wc�!J�䧎�������#Da�%ϟu�9�
���O3��I�*k������#S��	����W2A�&���;��i����6-t��R+�(���^�E��4���-V����_�S�[���G��7�ZO��wp�Գ�׍5�l�TT K]8�q� 6BC�%�\}ҙ�
�ˀ����qH�a�E���o��@�'SQlUg;��5SwI�GJ�� �o,�PǢЁ-���ZvI�#���	f�3�]}�J�;���/�Jer�~�[u��=���B���؝ PY��i�.�+^��\�MQd"8��\E }�vb�(��=��f��|߰�h�3���][����{Mr��qu&���D��}J;Ef�Z��`Z4T3���H	$���'f�]):�a5|
�2�p�:8ؾlh�>��AU�f��ΧP���o_ .�9sjZ��S���A�k��y�r^w�FR�h@+�q���|d�S�_�h-����w��YVB�R�NE��M,÷ l�`���;�N-�ecza�obb;.MSƣ[���;�m�E�=f}���I�K�D��{�+�<3X�,����(ET����i볱Ad�Osz~q$H�(/�0�G��E��:BN���֪��*�*ͮo�אUk1�M���ֲ ��gOx��֡�G#`����޹<������ڟ6�����9��?���̵�Y��&t���[lmR�a�.�� ⛱Udŏ��D�[���7����%c(2��L�����YM��g&-�ɳx!+��J% ��ڵB!�k����0���e�a�@?�!_k+z⎃�L)�ϾhI?/
�قyG��_�rF�wn_���� �m���[�(����,{��^�ȏ�7b�Z�
�Y���K�B#�&���:[�2g�i���r`N�]��[-�}8U���b"/��WY(��1T��S.��;��@�C=h1z�x��!{����Y'�J����uN���:��b{��0�X�P<�a�)b�S��Mw��~#}��W��ˎ,	�-Y�5���(>��TklN>Di"�Uh��w�����xЃ�֫�@������=���j��|�+�	�j�N5ϼ��R�xh'�h	_��XF.�!�������Q��y���ȹbn���E^�D۝�t��h{����`��2)D���)Z ��"^mz,q"\�ț`4)'�d�����t��^�[Ra��rH��u�N�Pe��ţ��Wb���o����zF��,{��l��X���<=-��ܜ��m;K�ї�Q��e���_�-�m755z�{B
�@_0đ���6h�S�Ig�b6@�"��;O�����6:�7Gx�Td�E 3�^'�m��z��~]F�_pH#]@�CIF��V�Q�۸p�fbQ�]�aGʡ�NP[�iQ�h�﷨��z��/�����q�/�������'H���m�g"��υ�qQ0n��x:Qz̡,�ݑ��;Y7* CGOm�wu�F9��~DE�����zX����քqT��x�W�c�G�)�����;�MW��*� ���?�c�����a� �-2���`O�`����w�,V�om<��Gچ_>���vq�`g�X�Vr96{���(&�W_��6˸K7���3�/�(=
��萁��!=�o���U���mn!���B�k��0��T�&�ƁHV�q��A15qrgCV�����v�u��Y����52r�}��j-s�!�H렀q/p�@s���ӿ��`5a��N�a�H=��F�EI[��o-�_s��QCm�Q����"��uzS��ߥ��G��.��'x���5C\��j��
�vدm�ԊX��X���b�3�?�G1t}ǉֻ�8���2taa�OR`nȦ���e݈����d���$�Հ��%��~C�L_�%!g�����3)�L+�Mb�b���u�"���Dp�S��^S��.�fp�� 蛑Q�|>/��L��w׆�k[�"���Ts�S��1w���S��S��+tN*CLj{�U����# L�cEIh�)��M2\�XﰜQ�}봫�|���q��Ӈ#��� �aw���:�D�^��WH`?�W�T���!_�z�R��^D�%JZ�|�����<e�z�-���o
x�Tn��J.��4vH�we�����U����#U�#�Kc�<" 憨�l:@;���@욒��-fm�$�v��8�m6��qTyf���;�6�L�T�J��&����nqr�T�N!T��~\UH�py����8�+\ ˒j���G�
�'��g�PJ���K(�в��Uv���W����iѳdH��<�����A�R�aɮ����������*:�>��{�*����R�{�� 1���L	 �<��u����T[7	�P��NK3�.vWq�g	��e�'	�q�Χ�)�2�w�mep��ʥ�Y��������@�C	A�/�|��IvoBxqG�A)�`��5��af�M�L�½3����=L�5�$��*;��3���dc{W��!h1�`b���# ����o�w�~��f7��)/P���	1�t��,����H�'ᐿ�w!�sه�+���
>2Av�����.�$������d��~�u���c��pSWl��4Z�iχ5�G�_~�N��*��+AV���o��,��}�q�o��6����x�/	���F)�ȔPl��D5��9�	����ɾMの:$�B��r��&U��7RE��}H��yc���t4� ���e��`Mu�v�����Ɋ���:�W/?C朊�}��nNz>@w���<��·&��E��ۖ�
���볏0��e���Sb5��euN`�=㼔�3�g�E�\e9���Q�f�"��z��F�;�/��;\\�X: W[4���([���g��_3Y���4��_ݹ�0��!�X�¥j.�#D�����c�^�%�Ff���5��3�i�<��;K�������@��uF�W��;��J7J��%���,��*�s��!���-{�O<(P�b�F}���>�vEpA� �m!e��ky�'ZY�	����׆աZ�נ�酮�2��U ggң�s�+)��
������.a?�<��,*�~wj2;0p:s����͚Zls�͒��\�;D��5W�FGĢU��k�����Z�oO%@��������&���q� �l�B֓�\����i�����6*�Y��Y5��oX�c�r�Jw�RN�� �t�y�J!���S�������on9��B�]cPz0ҍG�1k�l��-�T(�=Gd��p��8.�D��q�LB�ҭ����D}�yjc�H,,�s���\W� �5����=X�x���1��Oz���2G�p��ߵ&3���]e�
�Q�g���E��ǏH!w��qC��(���"4�� ��ϥ	�:������0$c1�?��*��[#v&�������ٴ�U�$C��*�c1��Q���1���y�����f@*T�pi���,@w���R5�� 	�Up�~��*4�3`1lfOz8KD��ۼ��uJB؍��*� ,*G^���?G81����hM�rrKwe��ɧ=�5�=��n�~����V�,��"җPj�jBB��6��B����W:���/Xˑ�"G�Vś����H3�,|�z�e��3� �l�:��YR�ɽs�xe��}2u�#�
�����J�/ ��*a��&���aVU��6�� uL,�̖��Fh��7�>�9��+�N��+��Q���Y����,$��u�ehwN���*�)�cD�q�������ե+�L m9��K�k\����b�ul�9�ڈ�v�z�2w�]�v;��M�L�z|IضE�|��_ґ������B��I��'F+4�����k��H�y0Sr��ڸ@g\����#��
�|鰻��������Ġ�w�w��O��ɚw�!j���j��®=�x(����(�-|���Z�@/sp@L��������=r&]h���F��M3 n���Pv^�'��x<U�*�!���'l�}�ޛ��|L&aQ�9���#b�՚$6��qA�M&����O�&��q$4��ʯ#�'�:�֌�G�_p�������0����`p���Mt�G7�`O�P��0��e�됎�z�{�jB!�Ћ���-\�C4^�aÖ��p����]v�
�"�Vj��=9VE5R��1�����No��6�
��ܽ� KU�"�#������ �t�Upb��|�{���i���Je9'�Qkec�|��bX��քF|�4��Yuo�����>3�w�B(�V�\��O�4�����k�璱׈�y��IՊ��R����tO#�˶���@�m�|�_fJ�oFa�65Ke�S�r�;��7h�	��[��c�� �zV��K��`���(|s��cԯH�a��-%��J��4�Ul��;������Y�HR��"��.EXF�d�C
�λ��E�Ş1�����#�bg�j��=Rn+Q'@:�&��*۬�$��9	�Og'w��M_��m_��k7�}��C?�K"o�*�7�!g���gQ����I�$���@6�X�S�˅7w+��\a|=����:��!=��)��Ȱ9��L{�m���{�dv�~��3��6FaĄ*�u�(TՈ�A--�xP��Y��U�#��_���^d�SGp�-�/��|"s�/��X���d�Bt$���ǵY��y��  )�m������g���	�1y��[���P���G9O�3G�س#zl�% ��ܓ��L��P꠩����L}���LA�4��}9G�=��뱈P���8������v6]94�M�>ZM͙Yg1��D���G���Xs��zT�?�����ko"tĹ@��V靚�C�X�{�c�r��n�z���zGQ�Z{Ͱ�3L�A��F[L�?�9&��riz��C�vA��Y1̽n�?��g�i�2č-���2�G�=��GA�2�_��iW�躡]a����5*�����~a��\x��bd���G�#�������Y6m��Z�iq�h���W ��-Q�s B�9���`�$�˾q�~����B����zh�!Bn)^뚻�7K;��l쮐�Lݩ�����2�*��,K�D=4�g�T�lj�z�
�D��,M7��N�!ck��&rr��phlj?��Fmd?ɉ䌫
�K<�y�{j��-P�E- �?^�w�p���\��"u�@���.�KV�݊�/М^��I�w��7/TTn�u�}���x$�0J9<��ii��zo��a�+X�#l{�ԇg8z�#���tb=&.5P�H������<�%�o`/�G��y�ҷ|��#���T�!��5��}�Py���w�=j��?s����}:YҬ�m����8���-��
}M�!�uI{�M����B�����=[�t\�Wj��;9�
��Ss�Gf���3�
�b�����tyD����`�{Ob\]Л�
^wWE��U'B�0l��O��(Zk�T\�3���x`Z���om[�v��T�F<=�4׆�^:����[�vI[�B�ZG2 )��I�q>�'�~�����d,��Mk!�'��)�u��G�cm�}̬��]c1.h�z�����1%�MvA�����|�xg��1�4G*b<��Z�!�4o�ᴡVs��U��b�mL���}D��{#uI�hNp]Y�貯���
�7v!���ڄi���V���U��F&�4�L ����;���)$AaS�����8y4��b@T ���H籓e\-���	Mq��!��y�'�c4�����?v���Č� ����79��:�Y��`X�%�x��	�����2EL��e����p�k*0�a��9Z�G9�cx4���1M�:Қ�R�m�uƯ)�~���2�:Tӥ^�uv�H�#\�ja��,���Дj��C�ᡤ���d�o=��\:?	,�pt1��Ղ��;��}��\�@~�vwCKG,�-���-'Qb�\u�}(2�5G�s��Bu�r��Ƀ�up����P�8R`�1��3Oz��J��M�J���[&6�̳�ƐV���װ�ٛ� ��T��Bu��<7x��nǐ�Ʊ���ß����}@��a�^��F��Pxy��Ϙs��('ɜ0����h��GK����rƐ���r��E9�O���t�Q��@�Տ�Y�<�|}t�G�����}9h�0OFWKd������(�j6{��PM��*=t�=�� ��!�*��)�p�^�R�TׅB*��ݎ^�]8���K�6�NM���F@Ny�J��c��W����,�M,)>���	��2�e;m��M����H,�n�y.�$��]����1bJ
�����yf���X�~R�Dc��45S�ǷA�v���l2��51>���|�1M�G�4�K$�e��X9,�3u����2�� XR�B���[m`xB�@V��DItw� `{��
)��"����zz١�J�T�r��~nԥܿ٠G9(�d��ugٚ:p������\H�HQ�3Ej��g���#�e�0�3@�f�+�g�a!�|�\��Fkg4G���SY��Vb�%6�;�?5�+��X;B�|�F5|k�]BB�t��s�$��d�_�t)iN���;��_}X��t�Ĕ����p���Ҽ���T>�������A?/�C^��"��'�XA��)���ڬm��]���(�$d��&��e��y)�]�����(��;�x�H������\^]0�eE-̥��BՒ-��1$q!^ ��c���1~H9϶j��!H����v�9I���r�c���c0���BS"�0E��C�2��!�&iI{)�W�����C| _Ҙ�::z<Kg3+��I��'��i�~A�d�-�|�l�?Y,��_����4����ڽ�b:�?��D�.�C		�S@բ |f<� d�)���U}NS�۟�<9]����̶���'=���]юR;���b�0`y�A@sAk*���{))�s�_�&!�U����� ����X��儶Q@�� ���bG���A��x9l�iB
Dq�Q[Nh��
ٱ0��OS��|��f <r˩�a���t��u��V��әe��o7�B_�m�_u�zwK<?l�U������Un�O`gC�Δ�E��#��2�]@ҌM,��}�t
���)}����| �E?yg���(���W�f�vG��b��m��"�RS@�	d*G��K�5����@�JvY�����r��%�\�S�S_�M��������l$�UUK!*BͲf�LNօ�qE؋�ը?O^��✭�|Sנ9*�gy���Nn}�V6�� �aQu�n�$8�%��z�T4�؏(���\�|UZ���������(~�Πk��Gư��k:@���D��h� ���A�0_��m��e\���d>�sםl����v�.B�m�ï6��~=�����=�G��^�"@ǉ躕�b|s���i���y�E�^$Zf�4r_z����T� �aK2!U��cf��vp96:=���j.�5Z��Ķ�%���T�\PF��,U�<fF�R�9T�'��ӼO���b�I㸖|���S�+�Ze���Ңޘ�p�y�_���ֿ~�ӂtkP���Ʉ�ub��o��0�sLǜۑwE�WX'v��V�|A%�|�y)������q���l9U�^3b*�0� q]��ɬ��>Y�q�C��j��j��=f1��+�K$1�Rd
�P�_t;����m�����/Z�!F�)<'��I5�rl�����E�9���%��Z뽝�"Apc�:9�<z�m�e���+M�lݽ��Dh�WIEZ�%�0�kl�Mr�aFN�3��#8嚆�������އ���%o0��S����?O���W,��}�&��q�[���ңo�
�!�ܐ�3��;�B���Y9˭4�tz����.�H������mw| t�)�Acz� Х��y��ͱ�g�    YZ