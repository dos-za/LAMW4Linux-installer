#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1942072223"
MD5="07408ef711fd5ab4c1e18115ed04cdad"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26384"
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
	echo Date of packaging: Thu Feb 10 22:06:37 -03 2022
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
�7zXZ  �ִF !   �X���f�] �}��1Dd]����P�t�D��f5)Ђ���1����e��0V��J���g�IG��r�`|�Y$�#X\5	h!-Z^2j�1�DN �Ҵ��aV=�')Y�b����	�PW)"�{tH9	��M���9�~ҿͻ���hR�	^*�����)U�93�Q��J�G���/\��&̀EH&�If�,��H&Yᵻf"7K��ޚ=��B V���C,av� $�%�U��+d1�l+�_��,5�{E����\x=�?ϱBA��	}�řh��Hd�j�Pd�im�S�T�U��b�}��2?����=D�����9��T^�="�V3�������w������s,W�G��C\p��p�M��]��Z$�ڴ1���
��i�_W;�CL~@C���@X�ZX�L<T�7�~��d�?� c���ěy��q�\�;r�l���2��Ֆ��3B��s�S�n�)Y"i�qB��Q��S��0{L��������4��Ö^��ཛ���5��{�?0P:�Ҫ����<��(��ш�|JQ�����J:�5y��{�	�wJ��!�3��b*LTR������*D��Z1i���m���;�V��W412�'�c��(��p�<����u��c	�ka�%�wd�m���绌��0K�Ueo	X#�Myq5�M7�|�<��^w�?�a�t)i��x�3/�]^~��!�~\تa�XQE�ދ�D|DAN�jU���%�ل�.��;�C �Ow�����/�;|��g����8��T�x�] ��jtJ������"`��#�Q��e���%	:��
A�����A���v��p'b����oܺ�Z��fHj�I�߱C�/�~v�N�d^e	�̸���Y��.�m�&ǋ��`F�7.���l����G�$v|?|���w�C�:��ҫ'B�x?.]��$��G��E9��F+x`��TWr�3�+b�πI����P��/����$�\~䍣2�W�w%��-O}BಓAQL?b��o��)m�`\�� Z����P;k3|��P�E|U���<������~���<�0��g���X[��$QuVE�#����U���к���;t`�]p�Km�,����w��
�ݫ�-2yk��.^u�J�+�D!��Ib����Djˋ��FK�\'�2�h�ٕ�6�;�Zrn�g����'�#ﾓbB��Z&EF�5ޫ!��#��R�xQ��)�]pC����;jo��q�&���������FG:�#w2=�������Nش����'tm��Q�l">q&���=�W8�~�en؆�**��`�E��P�hGy��ނO,O&5K%s�8���%�<�$�=�>##�ds��r��j���fA�3>p�DT����}���;�65fBh���l+!���,gQ0	�UzpuX�@6��Ll��Ew�4P 0�g��y��v�,�ibP�۹C�f#�6�g}�#�%c���Ţ��d��;^�)���:��4Ͳ����RP<g!�$VE��C��2V�u�����_@�L��`��ٴ-�$�M��VqBW;P��Fr	�|�� %����P��6)��Ƃ��z�9s%ɵ,N���y?hr��y�4�oǬ�2�q�#޲C�57�z���B�a�U�'��$��$Qh�X���5����q��Ma����:���rE���C��G��"���8�-*Yr��l��ߦ]p�"�x �d����y�][i�`�G����f�e�l�G�e^<c%��F�{A�d�n���:
y�z#8�Y�:��Km�m���oes�$G()J"qx�ڎ�9X�/���4�����1�i� �)��7)v���$�b��Ԝ�l�\j�E��Zd���vj	](Z�f�F������4�_���Eb�{oR)��w���@pӼ�����|:����$(NVi�#1����a2]�Z�n��9��$m%�S���+0Lׄ	�-��o�o����/�}x�Ū2���+6��!��W1������6��>/xxZ�+�/Wr?�*rq*:�6D�M	��WD��>�%Ԓ�$m#x#�l+�]��@)e�zދ9�^Hޏ�VqA��T��/ ��!ޮ}��v��0hG:}�m����S&�i��B���r9��Tl��Ox� A�FZ�i5EnS�|[�1�lm�z����`�T�������+�!h=z@�b�M�e�-���?C�|�a��c��2�F晤�p�H�1"��Y��(Ϥ����VFZց��t|������(u��6�`�
��0h+��:.;f�TԆ�5�p�s�񤉚͔�U��tzR��3*�~݃nl<%q���L��վ�<�v�&�څ�l_G����
�B&��^Ua��K��UI	������@y���o�ȸq�I����J:J�:��j8��{��>U2��� p�6��M=�
02�CY:=k�[B1�<ۍ��� �
����*��s�����ZV�$����̚�s�O_C�)<8�fH)ՏL4p�h�"F�f	$�b���Q��:i�{:8�2��⧫���[����e�t]#j���_yN ���/��(΅n���	�F�bG&C��-.��{��ݯ���F<҃Td�S���S����|��ԉW{����P���������M���l�M�LM�<�cn�B������-�e�����<�����L_*��=Xq�ۢ��~K]|�ꒃR���@oQ�( e�#2��n�>��K�61����m��݀t;����)���NO;*ơ�L2�}7�*���k��{�4i#?c��Q"�߅�
�u����@Q2w�Ae-A�&���yBT �5 �΃�8|S#Ry�]�2����䌱�	9�wo��z���WA3ߍ�ǅ"�u��By�U?�?ۚ'RkA9ه;1�x��I�U �+Pg�V�d��������>��;Ѿ��c�X��X��V��*���q�ƶ��'ʹ��B��ôI��w5�SY��� Ǝ)���Dq_��9y�=`{�=���[������v֫�r��s��f�'�rH"�����L:Ȧ���G
�=4nت ���_�Ϯ��P�}�gИ,��v�Y�j2k)��<3��ǥ�yb�ފ��X&�S�5�:��
���J]� �Rɷ��h��{gI�Ώ��l�Xf� �j+y,�On:dR���5��T�Ŕ�8�r�Y;��qi��<��V����`clr�	ʹ������h����ڰ� ��������+���ڕ�3Pls��gQ�_V<�-�{2����'�8n��� �p]}�[L�8%o6�t�B�rԓ���ƴRA���Au���n�e+O����7�����nWo��$��g�v�p(J~8��xL�xi�I�7�(�n��9�2i
�w�0Y~Y��; ���;T��4�t*�A�py��o��΍ڇ�e'�x7h�"_` �Vz��[n�F\j�L� ��A��PĀ4�T�k�ť�Y�O]�}��=�z� ��I�Z�g1E�@��+�Lڊq	z
������xl�'l�trՅ�4�oK@��y�K�7ӱ8R���1��R�p}+�$�䌵U�+�W��y+�j����4���@��Ȃ�|��&G�YʜSe�]��o�ùeq#�U9+�(#��c� дq�#�: ���� *�#����W$��������=lBH�>��>p�QR����NZ�����R�Y�1oZ _�:li�q�Y�&��M����[D��]p�B�REk`�ڴu�]��j�V�t@��ܚ*�wR2AY�<R�9��>ݢ�G�eUj��]}4ck1��i�fI^�T|ꃳ�������z��<�$֘��gJQ*ֿ�`_�,�)B���W ��#j�/Q��[�:c�D_�Z�����~^�Eh�>�h� ���B$|b�EG=���dsT_�En�ū���ɑF`K8�=�-����PE��#ꔌ���j1d���c�N���`y�R8�8͏m^C"kַ��97��-uL�&�Gn��X�`��j����>l���ȟ�H���ܭj�A���d!x�}�������i2��gb���X��T��m�l��N���.$oE����E���C�Ň��>=+>نA2$i�^���үk�M�r��~W�>d}O@��\br���P��o?D�]P�ds���.���8ZL�`�o��3�aO��L�C���Prv-��H(?>A���5�fY��<�7H���^���/p[M#V͘�&�?�J@���ɱ��Z�4F#{�!ø�+*��*& 0�=��%���s���w�O7�"�5������{!��uL��,�2r߉hG�`k��-��/2{j3[��w\�2�vd���#��k�t�DQz���}9��ho�y�������$�n��[������]��K�h�ˣ9���vѽT��r�~{[�z����]ҏ���^�5�Gaĩ�X��έ�e��������Ϋ귓��t�eg���5�j�Cc�*��^>/��66!a9`7j{�������p1�dn��ī6`�hבN�J8�ym���0e�2?X(/��Ob��
��+a���}�>�*��9�ݩ�yG���9j������r!=E���b߬��L�6U�"�m=���Q��G*��ϡ���y	��,}&��|LOv�Q��̊�ٲd�a�\�A搙^Z����#�kZ�gk���f�by<��zU�<ܴ =�j7�Hg��GR>�Q��᰿
�v��������h��	���Ͳ��;���O�Ԉ���<�������7��uwkgg��1SoRQ3u��d�)��
t-�S)��#�8�P������.� �%4�ʪ�o��]j}���\��e{��V�{��o����.�`,�k���[�8��ǯ��D�0��#� �nu����ol'���"�p"��T>?PY�#��Cr����м�cV�r�����^X3��#{�e�4J�_0C ��G"S�-������g3֍3m	}�H)�����c$Iƍ��`G >CO.\�aD�l5����� !O�z�3�o����L����$���%��	�O�`(~lX���_�!tPrG�XUJ���]���5�D��E��"�&�B��Est9�-2��F ��Q]��D�kޙ�O��� ��k8I�$q.��"�!�]��9��J{ғ�۩ϵ�k[�z�´��1hH�B�KǾy ���1��4���aqP�T;�0S���#��vW�T��-�V�!�o�@��b��-��$Q
0\���t�:w�T*Ǉʀ���	tÜ�h�	��P��d��5RaA�Ad�0�%qn!�Lo�}ך������6�H��@�|h[~����d�w�eD6����X%��Zs'���}�rq��WQ}m,q�}��_+h����J��=i/	���+_��|��_2B��&\�Lb=~z�F��mj����*ky�{N�)y2$�ƭ�y�� ���Ē)u�rǸ�Ƶ{jG}�.?��¯�Ͳ磧fBN$h�����h�
{��W���w�F'��Rl�%}k~t��B��+�R�E�{���sv](y�>?m�𱳺��K���|سjO�%C�,T��T=�\*a�I9֨�ޡ�N�J�gD�_�)^��<r�����@#���|�qR!擷�`D��K���ڀH3X��Ջ����#&��r�q�`Ʃ��+om�#�U�X<ɯ7*@���9�Y4�
4S����P)X�=^#�|r�	Y9
�Z\��;��>�m�:'�E/
8�������B;'ӵ��\s�",~զG|-o1��7JC�U�K���$����(���͉'b���������w�%���=o�gb��{
���_\��S�:�ObU��r<�V����B��ǁ'�N���X�?��2h!/�4�71��,˯�NH^��LO<�I���)��A�Vb����h�h�br�C��?�� ��2��ȱ�/�x�U��}\�l�к<Q�h|�Oe\�M�AJ��~5j*[�î�K�!8�������/���$��Z�;���:���P'���R�:�S,�vF�4�O��n�8Z̯96������X�>蒒�/E��A�ڟYH^r�J*=�Ѡ4��m�Nj�:���J(9)),��y��Z'���=_�7M/��1�ʱ���IO�����M�#�����B1�D���R��e��E��/��o�D�μ�aZ���)�p��mh;J��R��YEJf��vJ�N6,:�n!��d�bմ�.���I�~���19�x"4����19	��w�,`*ak�NZ 
N_�bƒON�b���X�v�j��L���~y�����|�_�Y� ��tj'z	b�a�0�poVT�0�phJ��� Dw"M��Q��q���#�3Y��V?�o��<
�i��2�yI_��B��hY��ʥ����%y$�H�m}$��GG�;X�n>S�.��q��M!�;�P�S典�� k{����P�S]kb�������C턟锶t�m�-��8p�\6������V�>�}��� ���^:����1pα��c�-��>0k�O��o
��g�5��@m&�ԫ�C����:�&�n'��(UK��I�k� �u��`�ә����%gs�XӅ�sH����c;���U�[���q��W��>��W}9H.�3gu*&����+yJ*l>Zҏ�n�0���|T���n����5������4yڜ��I���n\�� �ѭ�\����<J�.��Ї[QM�dBC3�2-�Nu@�nL$���rE6�-�]��s�yg��jՁ)}YrC4=�v��X�n������O�ރQ��^� Ɠnz�|�E�m���I��߂�2��.���J�ѓ�#�%Q�g������{�<�Ӏ���S�l0O+^�i��`]����}rb�p����5.�rܰK��3�A�܈-H�MV�@��-��g Շ���=Pd��d�N��h(���6�g��Z��O�1����mr��Nb���t�C�y�T����_C��I_w�a��I�i*�\�Y��K�;M����O`m\D����Sv�yO�^���,�Q�M�.�O�ʗ�����U� ($���L`4Yg
c���'����b�W�D�]�ؾ�$<�+�AP����jA�0�.0D�MR3r�SI��ɝ;�.apL��e�^���vP�h�$!
8�y���H��5�B����m����i�w�l�y���Y��t%q��u��Ya�Z�����3:Ax�/e�gY�+Qm�vڅ+��a�u�\����'�΋ߗl6&ڇ�������Z��-�-Vg�	���厍�����O���W�N�+�~�{�X� 㙙]�}O`0�-�D����χk�Nu�%�îrsSv*�*!$"{�Ǹ��e�S���Nn����Z�ú�Q��Z�R�>�v%�5��S1q�a/��U�$$:>�d�Ld&x��n�-�Xc՘7�����@*����Ϧ��,�Z��6P�������O���m�o>���ml��&�>��ע��������Ӱh�+[7-���O*�eq�(4�����\,�]{�"�r�N��r\���Ϗes2�foߖ�~Zg@���=C_���-�����7�s��V��a��v'�3�ok0���*)�q�I���Q���0��1�i�S�����cT���+φOy "���F��ܑ7����|�.�ȭr6@��ag�M�UC��
ڶ�%��O5��iLnu=��
���5�����W9���{�-+�>K���c���h$��6���Ǐ����cߩ�C���p��D!٬�i|�6N�3N
�V�����J,~�B�������#�Gq����3]$)t��m�Ⱥ)���)!����23$a:���#�������&Ö�9��E�僃�Z���|G�7`�?���e3��4�3�WN���m��HE�e�<��rP�1��t� 5�0.��@F=*M��,�8����O�^�㳥�ŗ�T��.R��Ú�5�b*~���)�S1# '^�@�I�Vۄ����!i(����-O��uR�m�kn`t�����0��uE��sð:��p�"�%��[����\�jf���Q�тJ�O�aG����-��Wq0�ߊ�(m&�AWF��Sʉ3 $X��@	r>P
l�)P�3B�*����[Rh^N�Z!HX�*Q��?�\������!����o#���ԜA���3ٔ+_�I��"�+����.I�]�u	A��Q����#�u����v�Ld�Y�H��C�F��7�kGtn��)F�R���_�n̋D3wUoX��I��ِq�J�(�h��z��]𛠾'0|�m��KhhI(�����������^�Ɗ4D��&�"�հU�U�"ۆ��!؎͗5�NN2���ywם{ܻZ�GѠ�h�x ���Ϟ�2:se��8H�ċ��d��lbE����v���!�YBOb۪�#oQޖ6
r9Q�q�A�i�����\�h�w���K���L
rp��QnH�0�O:ٰc���n�:.�0%}3�eDLH�o+`]�;���!?v��Ȅ��Zrw������4���&0�W��4�x��YrO��e~O3�;d�w�Z1�� �5�U���o�=m��[��A����jV��=&���(�r��Z��� n+RZMb�_���283����5%
�b#b�E�3\3i��!�J�It��8�F�������RI}��V<�{����!Z�
s�Ȣ>Ȼ��0��o�W�?'�"�L߳r� ֍��>��n�.�:�Ʃm�\��疣t�$��k+̩)��I$r��qà�5�c�=�
.�crk��	���g{�$�iR����ӱ�r�h�yr���b�[� ��_r�G���=��BFː[�2y�Mvw�k�V����F<`��E�x�{5������i�؅���&�y�~��ޡ٦wd�(G�8��S6�I�,-���<��9F�!�n��6��a|1�dU�>�s�8\�g�]	���������x�q�pr��%�:)e�G���K6��shN{e�*� ��G �0y��]��- ��V��j����_#	��d�����;���6��O�ýP1�`2�Ǻ7�ዅ��f�?[�ML���zc�p��܎���|=H�k ��d�Q��WLAfm�5��gQ�v�[�6����{I|X���c��!�hB���=S��y~��wE�<V��oc薫���|���66�X�s#3 _HI�'netEY���Z�t�f�Y��� ������	7�G=�D�ʝ�j���7��!~�Ƅ������0��.GTϫY�w9!�u��Ps��t?b��wY��jz���[�z�"�ٷ}�%ҍ��H��g�@����-b����%�8/˿�fx�k2[��hS`a��/W���HBӻO�o���~�\;/����a�P�й�ċ����o%ݹ��n.��C��g�yI�w �#p���p�F�LzΏ���H������>��0�*��ǎ�W9�_�v�_ג����P�8M8�{G�� ��3Z/(Y�1gglg'�p��z�˒�)��&q��T�[��XbP63(�N������τPYx��v¹ŧ*����ېn�7mԑ���gm�j��!�j^(W�L���# �m���uy�C�}���A(��Y���@�W�a= QP����0�}P��1a�< â�=�3?����u���丛4̮X��c�hcRӸ�O�����/����B���3r-R~�A�I�F�T���,���!R�2(���?�l�,7?��@2 �:��Z��Ŗ��S�#zF��zXO�g8r:�����LJ71�y����z�^�hNU_�|��b>��1vj�n��^I^���:<�H�s��0��Z��uM����_@�&���f6��*b���9�������ڎ����Vm�*�2�hѿ�gL(J`_-��Ǥճx
�>4�_�L�Mo�A�9�O�\�B�N��y���n��������8D��\�0ȴ��?��1Ye�10./T %�T�[f=ciU�Cv&�v8����
�6]�K�6�g��UM�ll�]�4�>�y9��_��I2����i
)P@�]�}�C���'e�G`��1���'?xb�PY4m�o���3��� t��F	H��}����5EK2|\���J8�_R��蔼��c�<i�CN�� ���؝�:����׏F�{�������d��HJ_�A���A�=AU�x���=�}�iuN���܈ ˫��>�'�%G��y��d�;ϭހ��j�]O�FyxJ(�eD=��7V��Dϛ�nI��ע�zPS�1㴖e��Y������{��c�L{q���<ou�An�ٳ�vW8Px.�r�Gků3F��H��"��ՙ�*����V�kn�X����+׌D֯�L�l���-��~&�_��g�na2���f�2]'4�+��ΙÛP,2�ƺ���c����-�����c��x�������Dj��!^�J�A'�x4a���"��;&%�?X�"=rJ$���٣5<��C |!�d�c^Q[�hP;��Cd&��,!#~��� ��3{;E�����"�R\�u������<���d������k��"�La�x��E � �U�^f2i̐�!�������fj��<+�#5�����9�f搿�@�J��_���@��d�Iͱ�9b-��C��D͟��e��_j��'Y����-)b�j�5��CFM�q]?7Fδ���9�����G2Kzu�,#����T���~�x���\NOF���sD�o�����F�jB�֨�.��2@�ʤ�l!!G����n��<�x� �!-��������{-�=֧�׃M��P$� �/�߫����EBG��EE6�n�9�����=���?2��־�����n��Ӡ0 �jz�o�y�A�(�.((��̈B�-���.�g���8�f�0F3����uC2�����D����A/_F�	��k\�cd'�ڎ�@̐w>v]~J׎��a�k���S�9�K7�=D�Aa���(d�'Em�e'���4��k�����.��9�8��=(�՜�*���sM7��SZ�Zvʫ� �$!:��U*��9�{����� bn��3઼��w���k�%?(f���O��hH��r��"�f�����Pϫl�	��.��
5��C�3Q��2𪀇�����Gy0D�f��� ���X�������Q������:�����h =Lg��T�A��T�YގܤZ�vs���Z��IY5��bb��f��G���z��A�����A����$#h�2C!3iw�4�E	��ſ���WvʽMg9�f��r���m��ϰE�;�w�.9�1Z~�se�����^Q�;��eX�f���F�����D��g�����nFCM��m�TtjOƵ#�����2MBd��`��7��}��P7* ӱ���Ӂ1��˨���c��x%�e\�,&�\�2x��f�x-/�>�c�I"W������WW��k�Q ��IG���{*�}�?1L�'�I%��Y1x<��m�/���j*E<;�D�������(���b�N��,�7�;����;�j��P��CU!��q5�l����K�v�",E v��ױ�i���)᲻A�T�z nf�)���_����(���v��hb��
L^�/�o��n���U6�Ɗ4�O���j=���������ƀ�����TE���#�~�s�1��`�"�(M~i��=X�5�� ��
ޣ��Q���>�Z�B�����(0.�'�KxF�@��w�/�TI�_�קs4۝��yf:.�+�1]��~��2�B��uvy#j����[9���1RJ�^[��ݣd�ܛ���x��6�_��.�&��+��T�*!�x��?��W<�I�p�y�r�z��í%
��DJ�q��w�a,c��2|k	+F����n��y3�vv����<Z�ۆ�8u��r�l��arG```o0�sԤ���K=-՝��R��E��t��$��c�k�y-��<��"`\u�QV��'�a�e��<5�x75r����F���T~B#C��#~�?��URP;r���ָ���E�Jwm~ߊ ̀���V�d[^ٳ�;Y�|%�tЧ[^u�*�:F�F ɕ{�p>ۊH"��`�*P��(qa��[���v��ڃ-�������~t}�����A+�9�(�K:^�$p͍�D�A*��4�0���Al1�ޏߨ�����3���f�Ԗ���;XI�IL)��}��s�����X�|%�r�¢x�U�,�b�6\�S� c{�������+�~�Jb�8~��_/����B��'��p, ��U.����CP|	'�/�}�M�	����x �<���K�j�j�fY��h37�S;�����np��r?�U{����L�,4�%@b����dk�M9��ߛ�g2ئ��1�\�i7�h�cȋ�?��m�z��mƦ�ӰLg�`B5{[έ��2�4���7K��P�$�ү�����2U'�V��b�2&�y�����U����htѷ\NA��ed�:����
�Q�7tf�>9Y1��$�[)�Ϫ@��0"@�ܝ�}��y\�������
x|_�)�?.����[�.^��Cdmd�TOV�Y��*�с%$ ���5�}�w���ƶ��.�mk�������g؛�!z��ɿ�s�`�guU����Rz 2�r�m	�dɆ�a���=(1}�z2��N�P)��7���}���Փ%�k�}Ryn?fOA�C��ڂW�)fe9�����A,x^콗N�q��<�t&���>���T�l�yhJ�L)��`Q�2�<������Y+���/�p�����qn\/�H��I RH�/���:�XW�Mg�y�:����H��F�)ƩJD��H*ie���������,�me ��r�Ud��/I����M�K��FG9�Bp	�
cn�6���\���adEa�N;wCh���� ���d���g^��s0ȅ�$6+W��~�(��6巡a��ԗ2��&,Z����u�J��.ޠ��"󄗇�������b�YM�N�_B:�m�Xi�	G �cd�"�c�q�����-�`�1��wJ��wT���h������2妩b�@{St�����\�`�m���9�d����4J�����z{h}�%�lÅ��������E���t]$�����G u�54T���-��%��8�ߊ@AE��.��<�1fv���'�o�9�P"�&�a�1^,�܏���Ξ�ɤ��lGp��@��V���U3��̂t~觩�O�z2���ѐ/��J��*]q'C��	�VZ� �O��С���s�-�|7݋�\5�yO�B��$�" �wg���i��vGX��3�k�0����.��D�!Gx��<�噛w58�3�& �dS5W���E���(襩�@E7�\6�r�!Xn�Ǧ���ߤ�մf~C�p�p*ka�,�@�#�����Zk��t;��3�Y�VY��F��S7�a���p���0�N����ˣ�S� Bْ�W�,��
�s�<�H�]�����|+������L'�JA�L7Uɡ��Be�E���#��'\�R��e���{�d��_�j}�	��l"?^i��Y6�	��c����*1�r� �����bAC���Ǘ��M�[U��r������b�~������Ύ�:��d�@2��p{}��s������S�������6B�OO��5˲����B:�ݶ�&���q��ڸ`�U��h�fӼ�>5��z@,�����f Ϸ^,k�f��VKJ��aZ�A>�������k���x)վ F��禫�4�Lٳd�wv���H�I��-�5��Y
�P����B�Q��a:n�b/`.J���z�`ꪺH:�l�sj9ɭ�s�{�EG��Mսe��v0�+�똽�g�oYv���N�i\�{��n!v�/�m�o�t0h�^.3�v�ǥ� �#�)�'��2f�X�BK���ݮ͇y�T϶<��b���);��d��U�+�á_".���V���|��2<Ei���o�B ��$�J��DNi�!G��+�s2����W,fZ�ﱸA!|Lw��g���}�mY��%��jY��L�O��c���4G�&�n�;��!��"[��^+�SN过�d�sU��B��i��H�3̲����;C+�����0=,pM��>s�N��]�t������ھ��p�x��ԩ������q�%O�V^��-��>��D.���dӺA�|2O���c�8:�x��x0:
-NeU^R��:�4��n؞���WDVCĢ@D�>�j�6��=JQ�dl�B7�<�dY���[�����-	��L�|�S�.pS�bD[] � ��0M���?�(	r��.�I�8fS���R�a���ùT�^��|�HnJ��0D��O�JL�5wOp���Oa�kjZ���������ф`H~iN�uh^h�S��)��/��b����E�w�w̻�2!�������\��ބ����3ƫP/���}�VzY[&B1��i�ZE��{�1�����kŴ��e#����f���\p��:g�z�J.]"NŲH�������Rkv@���%t&`������w�Th��,27q�]0�)��m�#�.�<����0�O�=,J���1�:�&��n�(���`�@\�Yr]��a��(6$R�6�/Ƚf��1����Uj2��.�f|��}�J����O��)2=��>;��\ID���ҏ�FW\����%�ڡ��;3�HFϮm��/��@�ղ�ءF^�����~!4�� �2%�#�XCY̴�3���W�|b��F]�%'�b�;9O}�~-JKp/����Zq�v�� ��2�׶���(*tf�O�P�s�K=蟱�p��������ŶvS};8
q�R�2�����5x~6�0vן��_����'�w}��Ơ��Ā@�ʉ�di-`2[��c�1��p#F���N�ɼԆ�c5W�0��S�����M��j1]��[^�e���\�߹t��fJ�D�~�[��b� �>*�zť\X0��Ş;s��aQ��N��'7M_9r,%-Yf�>�=�>���NxbP4XU��J�H#}���>�+Tv��4`��9\y���� �"m;d����xIDq4��㫄P���z�AS�N���5F��T,�wۡ�\=(̅�~<4�`� 4�'x����=:�M�gmIWv�s����B�'}^��9Հ�
�^����m$�0�-�^�&{	���H��.��oU+�?z�,��>$w�w%	�L��f�]��<�h�s� g��Z�-�3$�q��9�s׳�3k�-S���`�A7ۙ�>��E��a�`�{��%;�à�I2x�)���:;��h�% ��m�`��W�w�� @�A@H6�@�{�%�ۮas$I/��9T��N�n�y��������&�*b~;5�e�ե��V�Rpk��8�!jV��*���Ar1�9iR%)�w��d��D���m�aw�&�������4ky�>�G��/����~�7��D-6������iHn�z�3��﨎�L�,]XB������߄��w^��^%��>�9��I�r�/Tu'@���{�0 ��}����P�[�HR����+W�:�x5����RD�A�  w�S+�5nw��1�!�鄈���|�+_�o,<�A�i�$o:Z"J�o `���
҅� �Z?�
W��}!�� ��o!�z^[������dvd��N�GbR'ш�_�d�q#��/�ĚHʻp�S3��n��[��`"�*&�
�Q+����d��,L�18�8���F��Um ��߳C!�o���������!Wr!�G
��p� ���5h4�q� ��E�(#S�Ѝ�ܴ,&�����=YC*ٻg=���&dN<�4��wJ�?�S;����5ye4�c�*Y��H�U�N�9��9��F�:�m|��Ai-��i&ø� �����[���sT
����|!;w6����Ҁ��ٴ�7ŀO����T*��M��(.~;�[���K�����;����x��^��]�2������.K3kM���<���X�{�mi�q���آ�ڗ�
�P3�,\������Ys��-7�
K53lB`@���G$ȸ���㢿������@�J�D?���"yt�,��kۖ�[�ӻ�� oDsƍ^���dd�=�VEd\���D��*�Êj�%��ɧ3�bG���Ι��+��?��Z� ?��.9���!��.��r��Tkv�dm���T���mr!}وF܄=\Rp{Q�|`�����b�ɀ0���u�6*��0jV�� ?��5��{|C$�&�	��i>7��]X'�5�xt��~��8&�&O��M�Iɣ��M<>O����3�2?�"�1Z\�Q��^�B��;9cG����ɩ�Y��C�4���ZB1T�o�Y�e��b��%�Zt�s�D���{�3��GP���X��$Դ�P�M�u8��U;��p�����E+;gE;��x����gc	�1Xr�U^��.pCjk6��2�.�?�ÊT����+
;/z쮎�=���1Sc�E땡��6R���ndq� �p��$�5ȩ'n�����U����'����K�Z���k��V�z�|_�D>�������"��(��|Ï�t
��%<�BCf�#d���j�	�|��ƍ:�c�B4,b�>��].�����M .�kj��Dg
7ZۦG�K��]��!у�F�7L�9o���� ����s�`�������=ns\S~��82;k 68h�y�\{�j���V]v��c�	%�3�2�ظ�خ�Se���9r���1�D��}s҈�o~s��`���G���<ǯ��ꨕL��L@S���u�Rf�rKP���I��$�Z��5 ǜ������.�@�k��G'�@���5�ٯq��T��Zx��vY���^��iZ�1���i��7��h(b���e��Qi�Ū T���d��=�(��4�!�Jq���������k�����Ў�~T�\�-Y�=a���h� Ń��q����\;5K<��� //{��x�;�V5L^��U-T�K���&��^8�Z�8���Fc�73�f�����%�
�W���VA� Q���	�v�V%v���8$�kqy$��^�D(�,d%�I�_�H�?��)� ��{<�ȵ��If�~0l�*7��۾Й�JG�Iu�S=^C��r'8k+�Eâ��9�e�\,d:8{_�|�d��D����%Aec	j��|�0���0�K}�I4�kwq�gm��&��c�b�fC�Q�L;�积�KCw��Z��*�rY���|kr��sׯo9�T>�tX���(M8;��>2���m����ȣ)���D3đ
/6(�M7�t�N>�bU|{KAжt�}N;��I�4���]Ō,I �Ӵ�kv���y>�s�-��Tq�Cܚq��vM(�i	�J<���i����jO�F�vEd�/_�:-K��H	�:	НI�Lr2�Bm�4��S��o��p���L/*j1��?��#ӏ���?���������K6(�	�]}�~LEI���[��
���Mb c��/� ;w2�k�/>	g��$�-{/D��.w��(3t(N��x�q����d-��m����FUGT����S����N���C����,�⁇a?�����Z"������աs�ȍ����:�o�n�j[�ʊ��Y�I(.|]K��M��c�-���6̞��dkv �����$�4G��ZG%�tP�����E����?�i�p�]����D�H݁�������D�4�^A�_�HR�a����
z�q����u�s^�wO�Fȅ*�	�Ǟ�47 �f$=F-x������8��2�|�TZeiql*�]��qLH;�0Ɓ�ZѬ���8 r��vft�"`V�M��������&R�ر��R��
-׌�K���UX�/J�\ˁǚƨO9p6B�?�K~^"�R�ƒ����l;��w�o㯰t=��W� ��������P(s��di7iF �,Fޣ]��S�fg�9%���	��
�,�Z����,��j"'��UY�A�\m�m}�vj��6�},��*�"��p��{���CY�A���l���T1�SV2�K�^�wI�`]2����?���3�S�H����o� 3{!������ ��$VF�*��Wİ�a��^�p�N�t܎� ���f%r_S������"��yE�P����Z����c��h(�^��q��Nw�E�)y��kZ�뀺���w�0��:�/-w�����]��<�=>T�d���$�s�j�3��l�8mJ���铨޲ݝw���5�����{/ZX�s!������@���l��7�%,͘���B�q�^� �b��IP��{ `��Z�cʟ�8�L��N-.����:a�+�&)�0`��z����%
t )X�/����+Jv��
��C(�4��~���yW>~i\���Vc��8�����F�+�^�� [��Z+=�O\����!��u*�_s�B���w�'�w���fN�Djmo�~J�q�W����_B����Q?S�q.����y����nzӗ��W�L���"$Șւ��E�}9��E�2�gH\foW\�	'�1EZ��Rn`�o4�ry'oQ�yG�S�Hz�
�t����l�@e��1i��`��U �'���5ú���Fq�l�Q��P�U�z��$�]�߽`ɇ;� F�#������ �<��:����ȿ�ߩLN���5�����U�\h��WkE�l��WC���?,R.�>}^t�_��a���9����в5[4<����p_���C@
�{��l���d�:�g�[%d���E�@��/�gJ���=��w��$m�>s(�C8�������Ɠ��`�m�Q�kv�@R�1m�2�|Ő��UI)Ϻ@���H�z�ia�����H��c�L+�>���d�5p���I}�i���`,[�l;���sn.��lc��8���d����B�X��,�"��
#B�Mpa�q�K���t|��]]�)k��:9� �`�ru��Z�;b��-=��4�b� ��&X{2<�c�"{�� nօ$r��㹦�t��8����3\��w)�6l��e�h�+�7���%|k�v����`.�Î������\����0��\H5h]�����j�i��"<x� ��2�we�r�<�'����������w�$l)�m�;�a��h��f��V�G�>{���}�mt�W�>-�ML���?�P[�r�M�ǉ�s�������ǔ���TC����-'+����IZ����&��|d�=���9)dt��!���,9�$V� ��4�}g����=�,(qK�Ǥ	�uJ�tS�3F0�]i�&?Q�������nƛsQ�Ϟ��`:F��ӷsI����찭P�ʬ�U0�/�/�C�\t�y�ba���5��C-�d���6L���w�,���W֪g7���E�S���m٦2����x`M!����K�W�E~�O�I�fI��a�_�#W�>�-.��V,�8�ae�r��.��P�.֣�+z	�آ�XGeDeH�ue[��7R7��n�v�G��iy��ǐ�kI��@��-�:����5;��MFd�z�3ʱ��t��f��-w��U\�V��]3�V��a��?�k���#�{�)�C]�Xz�XC�(��<w��N>@x`8�b�s������$!��%쯶eTt��qO���1���,�W���9�����в�gg���g�~S_EѪfsO��)��b���u��g��[��"�?��"�%�fyAB*��Ӈ�֋���k :V3%'�k�}q��ڬ��ze���9Eh��}����q�tP���]���O3�/�߷Q��(���s��:i�=Z�Yˤo*$>�B"~�L��,(~ΚĄ�(�h�e>���K���eb|��;D�f'v�]���*�Ⱦ�x�/���Oцqlgt��Z��%E�� �.����B��/=<e�����y+�6B=^���M
��` j�9"|S�n�n�-�� �W��M!TQ5�(+�T�6�K����!��.['��Li^�C�FW�� �l�'�G�Sh!�yv��#d��#�&��������$i2�Dt�S��mό��Џ�f~b!�6�N�ub��Al�x��3��j|pK��Lf��& P��f��h.y+e���)��$pTG��r{� ��Փ��e�j	�Ͽ�����-*�
�,�p~3�C���ׅ1����	�:V�A�A���� _G#ߠ ���Ll�H'�ro�n8���sh�YA���<x��wd��y*�o�]x�������<[ev��nC55yi��P���ƲWd���D��n3z�݀�Ť�g&��%_�=r����V�Z��c�mSd%~��P[��� ��d�u����9&�0^���eo0! "Sѷ�@2�)�dC�r߅��"��f.�W)��Ԅ �:�Q���@�U�h�èDP+}w�r¬�H���B�Tna"��"Z��4��&�E�(X�C�6��X�.���b�]y��e��i�0�b��HsI�qDZ��^�(1� ֵ�9�����s��iȖoZ����
ƞ�)��]j�ZTU�d't@�?�����������\e+�d^�g^���h�'��P"��1�0l
v4E����U^ҋ/�p5����Θ��;JF$FQ��#6�r��Cb�{ ����\/A��IS�m��^u�k4>�8���)���� a�j�2(��wq�jZ[���j&-^��T�*@������!���k��UW���}�>�� c�^<^��{�!ӫ���X�Ϭ�S�N�R���`�6� 9����L-_��}�K���0��g�"�W�Pz$�LK!��A+��H�N#��bp���MfF��ZF���ū�wdQ�i�f��-�r�k�t��u�#2*����Q.��:�a�1z�	�����Vv�N�d@�`����BG�9X�i���K�����	^XӼͱ�i��~Y7�A5ai�����W]�D��r�KJ���U�Ko����ͬ�$J�Ħl�n�k�@)���HSneu4�d��-��\)w��͙�P��WO}x�B�͗�IaeҽO��)����4(�H�s���2���T��:���ŒS�"u?�H;!���}���h-�����ʂxрS=�b��z�qmi�M�DsȺ�1��f���F��H�`��#,�h��N�W<OD�ck��F�	�-�M��;�;�Һ�1K��+�3N��h3�F���� o�k`XEs� ��]�,�P��&L�����Y}�
��L���D��7Cb���FTf�|�Ĺ�}�NJ�Xo-�=�M�|���>��9�#�_�=t߰>�x�)�\`��w�d	0ҶmGv׷D��f�.������zB��V��L���y��1��J�|ӁZRA��-X
���GI~�a��^pܠ�_=�|���h�z&a��q���)R ���h��V�p9�tD`��o{�-���:�6��لW*1!!3��6gFr�sl��x�AĽvAIr]vFX-*�a����<��q��UTٱ�(�
Kd����+UV�ܛ�K��p���sZ�9G����w1�����l�Ef�8��{?x��Z�3N�e�a0��>�I�G8��zNc6��e͉^Y�h�ܟ���L����]	~�Nd�6�F�u,��ۺw�������ܾ����[�4�
ltF�1��i��h4�o �5stR�|��j{W��Y�2�q�4�"\�@��u S�7�S@��h}L���N���Dd:�)j1�h� �z��<N����6p��4����?�����(�dG�����n���Lf�x7kcԌjNy����r$����e0܉x�!���\�.u>#�!N��
��ݻ�#�U�N���AZ�G.j��{��'f}O%ME'�8!��v7VA?���r@� #9�	�m�U[	ӛ�e�À��������;��}Q���{x�����)�~���"�ٚ�Xљ���)n�IY�wm����B�9`��,)B�WL���nԦ�m��adIR�\�̶V�S(���Q�񝳬J�<q���?Tm����*���tG���:�7$M	�yؼ�+q�"�#�6��$䘂h������1�zZiɲ�t�������R���"J�q7	-5Z�oƿR"j?81�F�a�Ϙ������tE�(���,�s��#!��b��>BJ��-�
��7��%�8�����猕���S���S�m?����""��n����%���7.(�-�M�_M���g�9<�&VD��m��	>���y�k��n�DiG}�+�5Bymɕu�Mj��x'���[qhy�m�ѭ���!��k�i�C;���-�[��~�oj.��w�2��y���	����N���p63s]�K�F�o��*����J���;���ХpJ��P�ٮ�ʣ;m�����נz�U:��+�~��o����7[ǭ�G���5����%��e1J�Z�4H�T��?נq�w��Ѐfb:
|��/�  AR���-���{	�h��=0;'��U&ϽŶ����7�=9����ڬ��$"v���={�}Rڨ����is�|Ff�E�@w���G�[`�Vn�(�Z��E���.{
� ���u�9`���~/��7�$�ϡ���o��4��i֥�8�z�V�'Z���>-_ �.���!��Y]��4�Փɴm�����.�`!T������+���/i�l��*W�>`��9{C�R����
Sr��fL����/s��=*HX���ʘGGm�Ea?�q;W�|V^�P�+
���	^u݂X٫2�|��s�"_!b�K���%���cYD�$Zmᶲs���9m_�G �P#���#�M�Xa6W
��P�z�g���M�
6�B7:�n!e���QR��`�DJQA���`�͉����oS��V⋓daO�������qq�Ycؚ}GV���X��ő���Y�0�l�$B��¸������
�]K��'����������d�z#��|�X�B�p�;1��*[E66�y+�Y����ZS��p�OJH^~K��R�(:��ꄊ?�ИʓTQ��L9���р�e�C��3)XE�.��bZ���"��1���J$�%ځa�#詡��i��	��)��V������:�o�$u��j��h�U�a���h�E���ܶ��K��7|	m�����P���;ҁ������Y�v-Z�6W~���i�Uv�S��qԈrk@���Q�A���%6���%�c�����x��L�~C9c�ۃ
�E�*iVb�A��d���ewЍ��v�W�襹�z7&�%PW�}��=j�
�agR���[�8}g��ry���.8�uʟ�AQ�d7�;e�P�v�C�!� h���_:�x�T�k%��*�*�C�ᙜ��y��읡���)�:m� v	<�����ѕ��X�'=�뾉�֛d����M�R�RT4Wv"�]6��ٮ��4,#��N.��![�?|��v����ISX�O7	<(�B��ʀO�uࢥY��y���o�p-ɃI�A�,,U�O4��om�E�$_��ZЈ�Z��ͧI�\���[���Y����Ϝ!�\<yf;�*�u�k.��?�՛_?�Y�|����+��؇�u.sd3����g�<�T)���MdOH�P}����.��>�>܇���6c�d���/�j,���!h��*�z ���A�M��3���r-!D��2��@�$K3��l/����f�?~�vV\.yoEE_���u�rZ�=��O[��Z����1��2
��vTJxiz
<�̸�7{���v�4�آ��2�q@��ubp9���T̬$ܢ� ��u�7�q�����:T�Y2�J�$aq�}�n��?��$�y&�����R�-Y�-[�5�_��g�u�x��yK *���*^]̆���3������9��*�9�KO]��'�B�
�}�n.��>7�BaV+,Ŧl(��s�/L�ת��d��yҋ�>b��f���s���i��:Ǽ����\w(<�Mr�+L���,K�6��n4p5㊛��gl�gP�������o�{W�� ��{gX��!�G�c���F��d[D�]T9=��d�@�V����n���x�FO�c�a����o
4�S�,7KVc�빳<�6q�>��%uB	y��{} DhOn��o�O��M��@KÌ��ѲL s��w4�ក�R���-Q��{t>��Of����P�J�!B��R�ʐE"�o�p��H<U�`����E��h�~I�{�*3a2#�@�	ʺ�1�&�e#�i���{�@�v v4Z�z�[<�
�T�x�@��ˣ��K���I�u�]��u�,�H���y"U1��o�i兆���sȽ#띕%3� H�k���@�������㝚��+Y��m�kg�Q��j]��k{.��X�B�R�@B`�Y�N#�\ݙ �l,��1�R�a��2L�)���Ќ.�,3f��w�q#�ؘ�I�_�
�v�OZ�ܶr�����!3y��O���W���0����t3C6��T@�L\����N�8U�#tp�9С�n��ȶ�ٸ��4z��8˥�cw�x
V	�L/��|n���S�U�M
��/��R�����GI��mr=Kve�od�>	 2{�-E#�����!tw��G�SO
%�y�{>��n{�X�����|���xN__���3q�>�&	�X��D`�-��?yZ�j��<�R\"�Y�J��/�$-'ᖥă��e��ʡ�P�-�2h�_M�:%�\��w�Z,,ؠ�g���[�.�~���M�T)X�
@9ۦ2i~V��a#7�nZ�xṰ�߷�eX��g6�g���Y��N���O
�(��{�����лT�-';~���Yǎc�t��v/;���N�Z�+�v���'y��/�ݿ�6����ڷw�H-c>|��#�&1�M�D
B-1D1�u��0۟�g�����m,=oy����Pt�Z��[��*�Rlg�?���T�uF$3#D��)��ۧ�|Y:�#�a�!n鿊����:����_����,�x���r��^M�{̣�AM"����<칚4ٰ�X��ۉ�����1T�s��;����$���C<_99L'�Jjϛ�����O��?I)!WY�%9�+�Ķ�tV�12F�f�:�vTc�ya�;,ґ �	)炧�C��'������숈�i��Y��
X����ڒj��G����z�E��R����ޕٿ Ԕ�����_���,�X��^�j����3��g֛PD�m}N�������+{қ�9�Q2Q�J�?�x �!QB��{�k�m�5/���a�eC(r"���~	��)��
=Q햔�)GR�l'kFj~Q��M~V6w'��Eѷr����=�'5��p��Ց7�a�|_��N�'���(�z�YB��m7�!�� �NCM��6=z�[�pLg���7�r<�x�{�tfW��N�,�d�+�(��x:���}s/g�*����s�E����ޜ������T���{p��_�?d9�t�E�NhE�W���7�0��^�/ښ���<B_�3�Q]g�TS:eӥ�ɷ4(����o��yl�    -b�7nw� ����0̈ű�g�    YZ