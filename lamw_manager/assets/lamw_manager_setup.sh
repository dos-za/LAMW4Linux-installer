#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3725119383"
MD5="078422cf0eb81578fe3fc00f4b0c3bd2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22272"
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
	echo Date of packaging: Mon Jun 14 22:58:31 -03 2021
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
�7zXZ  �ִF !   �X���V�] �}��1Dd]����P�t�D�rHd����fW�VQ�`T-)xjR�N�iZ��Ց�_/�!bx��{2���Q�88S���w��L���m�W��Cz%�A�����L����O�H�"͑�3����'��n�.�J���,�,9�����1N�w=a��ޮ�����n��[a1�H�L��fO�3f������˰j�U5��]VI�Y�Z ��5��/����f뿗_���4�)>4�gv�gP��G�'��B� ���i�zP:�)�!���t�osY�ɩ��QV%�[�w�
�G2��[���*�X;��xz�4�"$�ޚ�=	kHH�}mmJ���YS�"X���(z������qQּJ��]�� �� 
�;3m�Z��'�!V%1]%jԴ����-���,;�R��ҡF	kf-'�3Go��O19$�N��W�(p�|��7:�`�B*���DOL`�wwt�����o7��RH�8rI�B�
��GV'@�o�TԹ��|���o+#n+~§�n������/����I��W�r0x���-)U/�
�XF L=�uYΠ/���1�@.�٢kޒ�����XBG5��H�NO�Ի�v|��ҕ����^����[�{�1�[�(�
�\�m�01���<�˨ظ�a)�"0�U�N;9p=J�u����*�"�P�/��&�,���݈?�-�:��q������S��	�r@s
�t]�q_�0����.W3���{�>1��ͣ{�AxԵ�%?��v�|f���K��M�<�ސAR�vr�n!by����AÞ'-���tJ5G��`� �h��rNHGA_��)z����M>���n�n���7M6C�A����xmq%Xx���7��,�!����gn�Lҁ�P%��%�1Pn��yI�����;2��ݐ�c?F�6q�	�+S�9��R�Y��Y�%����Be�9zlǍ9U�竧�����Vic1�Њү�3	��K ����B�e-�-=�;IJ/�>mw1�Q�~�U�y�+��a�L���S^A�P!N�8G,�J�(����
�l�
z9_�,��~����Sh��T/���̛��>�������y�󠃻=|���zJ��� ������ܔE!�E>D�'�d��4������
0s��dA%S�*C���<�t#���]��v�G]����L4�]&j���@0�nѻѰx
h\�p�#��>�����XRV0���G�����S��ӗ��МN�m��-v�v�Q�e��f1�e%9���E��tu����ӵ�I�!��@���9��M:��-W�?j��Y>_�]��C��'q�F��~:���ٔ{xV������x�A�Dۍ�Nj�NC�O�@DƦ�k7A�����o��D���.�s��er�!K<%���B�2��s�b�)�����R1x�Vv���i��(�0Εj_[�V���լ��KW)vhT����M.ӽ�	���-�rr����\N�@�*%:EM��j�;�Z>�R`�LǓ5�� ��/w��{#o?�a�ܮi���}�O�l��s� �������}>�O.MoT�5rT|�U�,����Z���1��X\5:�9�X~\�ln���]�U?�`��S��R��f|
�iַ/^`�(ݑ���#���bv�e�cm�4��}�,3�W�^j%_����[�r�T%��O4H�![ N�^Q��Ӂ	iH#Ԓ�EA1(�~�=�<[�c��<�
����
pax} ��+C��r����X�Y�C�8ؔ���'�u][���:7��p�\85�)Mt�P�N�L��0w	⟹��Hww�6�DE ���9�gu���UĈ����h�x�������\�T;���E���8D�?�@��x
"��a�q}A/�^4Y����_N�a�eI�D���8�k����`�Zp�U漪9)r�#���:��x1my����d��>��-%O���o[?������G>��Z�����ɫ�e\{0n�~����g��'D������n���{�qc�0ܱ�>L�� �}�n��հ��B�~�Jl!��fmpQ�K��ʐDϚ�s)���:$%�(���iR~�n�F��fU�%���M�G�t:��d��%!U�Ir�eL1�$\��=0�e���)�r�����N� \��'�	�Ï��d� �-���Ү��۰�]��n��e, ��D�	㛽�脳X�:���w�w��|j�^���_���2ڐR !1	W�"�k�:�d�;��N�3���@���T��a�,c�q��
9�����8� �D�Kڝgqn�(����U|�"ew��Ar���F��4ʌ���P���ZZޑ�}���������(4������]:���\��a��Q�7|�*t�8!���{S�z�M
P�i��Y`.ymA7+�&�"f�\cN �'�����"��$�g����E2�BA��_|嗃6꫐���\MJ#=�5�����[��m����*���g�f�HA�B]���s�08�/��R�D��_ok?�ۀC�s��ct)�,M��g'<@_k�Q�裙y<"n�,�UQy@�vzRC�ӵ���a�9�%������Γ�⋈	�*��W5���[K!S�A�)sr�"td�֫��8�U�k�524K��>��(�F�փ0��º)QQ_�	����ւD?��żѩD��W\��K-H�)*�ecc��X�RI�}?u��]�:'{8��K�����;��h����ؒN�m75�߅����	6��eo�jJg�I]�
.��&x�B�6BL<d 	��:o��������l�00(�q1�b�ǯ���`#R�
C���t�3�,�������]�cT�%?��<
��SR�In��vr}�L�%,���`�K�aV簼�B+0D��^����w[tD������jA�r7rbDJ /8�ͦ]�fo��
&��U�ҋ��w;�07y~�w��M- 5l;�6���l�"�����0J1�� � 2#��	Q���?���1믔����'!�|�Ħ Q]�=x!E/G�-��(9��b�l&��f%��=�vcNk�?z�V�7�KC&i_ ��˴���;��E@(��-�}�&�-�����3�'u a�����F��Ǟi,���h�}<\�D�B���6mgaC��1�9Kc���Ҭ���Q(P�m������[q�cw�D	�IB��[/�<�r�V��<�X�}��4aHz+E�u&����*T{���Ug%�Z�T-pM�ͺ�I�6�h�S�H�x��\ȕ�C�'5��>"�~��H���/�1��[�A�$����6v��#��ԯ�]FL��Oh��+��gPZ�F|�ƚ�"}�;S_�Lm-��d��l{x�7|u*�[Z�̡�i�y���U�;��@�?��kÿ՗���.����d���Ld���'����+ƙ�;���+�N
��I;�c�9ڡ�l.73M��%�[(&�o��������D�@��"ַ�C�ˑ���F��)�AW�|9'C������H����G����D��	�ߘ�S�[R�S�.��4�HシX�%�'��_ �Ξ��'\�~\��6_PB�����"�C���r�������f���0>Xz�t]!R�61�tMV����7x
j,`�s�v���n��'#����a���{@��|� Y�~1w�_�P'[�8��m���B��~�O㤌˅d�i@o����46C�Q��~��F�SV��H�	��bbo�9��ͰX׷ )ٹ~�߅���֎�z�U���L��_�n5�*c/��I(��@�w�Hdr�Ge�(�[����bH�7z�<����%�{�Bj�qԸ��� r��l�
���Oƹ���V�"̞L�6�*ڍ򆱐��X�n��D��;GlϬ"��u`3=��x͒+�
I�yDe;>Lj�o|�C������P%6�Hٻd!�Lƃ�ɗ/�tI�g����Ey�_�u*ez���+����K��G�c�� �ăH,3H��=��)&���^����$��Xu���K�Q��L�sP�m�i���`�x*Z�>w�P.x�ܸ����=lh�\Zݘ���ŵ֟�<hd���0���(���i7����p�� AB�h&�PR#��[9M�k-EmV9{5�ӒϜk�KK�]��8�,ۊ��R����'Ɩ7����zV��!໡�<�`��e���OY��B	�b'<#��\�}η`�A,���!�=OV�^���}fj动����dO�=�s�����ۙ%x�r��K��g^A��lEI=���0Ra�s�*N1�]�]b����C6�^ڥ*i�%��kTi�Y�Ȯ�b{��K�%���E��^�c�Ϸ�#N/��}��āuv-ps�M�x��q>�V�3^����[��Z���������Ĺ�V˽�3�N�/q�+*�Sq��mc����ɔ���j������D���y	G��;��'�ĴW�Gz�i���l�=n[ݯg,����6*���+'��'Y����ˍ��x�6������v.���=��*#]��M�c����6A�H$S�o����[3��`�(D�A}���C������\����p@�Ȏ�ݱP4-�޻����@ �@f�
� ��z�ӄ�W��Fp�@���iU4���i~���^�C#;1�@ᠰ>@f�� ��Q=����U��Tvh��'��"Xp�%�(�/�[�VJ��']kc�<]G'K�FoRy��Q�]��V��� ${�¸XJ�
uey����U��jd�6	'�p>U�W�sp������&_WJ��N4ߣ ��6?%��F6�|�~ފ�v����´e��������b���m{S��d��m1��O��z�6��>^� ).��[������	���y�m��4n���D�W(� �"��6艕`������&�9��1ْ�6�.)[:'�Zl,t� r��w؁&��Oe��2���O�2�ݠI�yv\<���`�Y�˰l���t�G����J�A�x+��Z���{©�}�G���S��G��i�8t���f��+= �<h:�x���JkoC=%��!^�b�C�G�UU��Fk*J V��%0�!��s%F��^
8�8��W��wX��c��>f1YH�+�:���ZkT����<DPk���7�ԟ��80p�������^�pzJ9�s���	�ڥ�Π~YG���=U��5�L�o�/�+H���+Z����P���3w*��25�*C#�T��,��i�W�����[Vb��35�1�Xd�K�?ShH�e��Y�1sZw�C?�~ybZ��޾���f�t�o �^�5��
l��+��K��kW��-��aꞪ�D�ꑶuhi��Z!܋�f��g��
�cV�S5�S�6�A�[C��0��o�9�[�j�w@]��Q�i(��`+<�f���!���	�k�v��i�a bOz)�Ḵ�XB� ���`�R���_V-a�G�f���?��'Q��S1	}壏Y��s��J��b����d
҅�<�N󄞶����Ћ�_�)�B�:�f�v�(�j����v߈7%ð8Z����ud�(v����4=g/��[sL�~��T)��
fRD�ڟ�M��.2���
p\IGSӆkp�]�)m��ޱH�L1>h�`:?)�}�Zơ��C�,r�s,/�?�IY��"�,��m��i�a�jw��옞�]�F��!�{_��IӼꇾ1�b���yI/�ۢT���(q��I{j�߄����;��d4��=[���	�r�hPO
����3�@�g�#���F�i ]0엺)?�xcj�3�sx#��?��B�.z`$���"�Y1��-���A1ə���I j�?ף�?�@�$k�*��6�2�ⓗx�l|���$5y4S��	�N�?E�D��G��	�4�i)D9�i��~*���F��sϳ8�N��������6��	���B&�c&)UFCP�6��R�X�T�N�^Z�F tB��.�n���R���Ͼ�h�MJx�& @��_1dO�TuZ�q���C���p<��-p��у̀��H��8g,s�(�hwM�$W�� Ҩ5@bZt�wCB�X���R��߇�Z^�b�d
��Ұ8ܞLV;�.
������A�@ϯ�CR	�7YE��z́��)��Wx�͆��������o�W`��.��sf�hzk��u���8�N���~!!ΎlN|�$�P~���lb'�hO��� �0�x�:�Ȇ����:VP�*����D����݃|AG�/OCߔ�X�l|-e1�Rm*�S">�����*(��h��t����m�K�'P��ѫ��6C��w/Ĥ�C�K}�Z��2A!}�;ȓ����9]�._ԗ� �XJ'7:K���@�a��i�����$��<��m�5Y���qVڲ�[����2m��R���:�z���AH����^^ڼ� e��@���P���0sG7#���B�^�i��%ҙ�rq�*�շP��]^�%�W�4���D���:��?Q�P���+�=Qk�L�W�0R�6��AZ�o�<��0Q�9��Q!�����G4�F�v2�}p�����S��7?5G!�/�A�PQg�B���n��}�K�Z)�4L�j����F-VPc
�=x��u���#?.`�����TtǋȔ�^p|r���A�s�C��$A����\�[4�1{{6��'�)S��&�I��|�o��R�wk��IJ�R6��Km2w)G�q�o�O��- o����?�ys�i��=�ז8�R��'X�K�O���S}͜�_��?u��-p����d��[�������'�����Φ�r�.`�+Þ�[�(YB.;px�y7�f�\�����[����{*N� H�?�ϵ�p���(Τ|�6i�
0�KRFZ�5��g��>�{���+ǧ��E���|2z�h �n��#ב����w�'��#}���ۻ_�d�^S]�3��ҥdN ��~��R�S�3��5�XX����|��;C�{i�<�W�e:�:͗	1<��'��"��������q*��U��A��k�> +���T��<pѓc� �Y�\T���!�pd�+�A#����@�uO^0�ɛ�������/t��	�
{��l��՜Ԑ���|isv >�wQ�7�o�j��εD��d�^���)���(_Z(��.���|Cp@���aT���Oe���ц)(]m̰�hS~����@�lt&&fkz�W�����.SO��ZΉ�K,S��������f��f��%j��2����Y�~��S[�޵�d�m��Hn$u��4w��'�=��)N���Ҁ"Ȭ�8�3���{d)?��j-u�)�H��<s����x�����z��{�$jϖY�;�9R���9�.�_��:C4�M��7�v?t���|�L�\�3����jxwY���}.ѨQʜ��UA�n��L8�@݄��}�aO����H^.0|-� .b���ZG�e��]�2�ɩ�r�*9�u��_f{�=�U���n������*����J�iGm�
`�܇C!5�=���/��~|)_k�
����L�$ҕP$z��#�#t�uzմ_��m=��zhp{/��k�R.�SKw��k6�6��b�3��'�S�@+��+��z� (4t��Di����̀~�����R�oa�#�x��ck������K^c�����kd��a�a��@%�������#�������Z���`'��7���q�%��_�c�ቨ5�p�1�/��ԻRx�qqH���S�.T���I��eC�7�R��݅=�M�R����Z�ͯ�[���e����ɉӒ�f�f����~��#�༿4��~�+�wc���jx��}z���Dt�Qd���-�{I��q�_b3����^��c(z��;�n����*#<�'Q�$o`J ���U(D��\�X+�q�p_\��λ�і������i�=.�����������,U��s���a��XP�����`}��l�k\�S~QC3���MЭ�ݼv}O�mT��+���p�OVk��Y�#��IV-�����l2%�"m�@2��.��ô��2��d'a��I3�h�A�n��7n�gy������#�3Ը;�T5okS�Į]�ԯ�� ��o���i�/�f��*���-�"«))�<��n2�؏<µ�/[���e�I�4����7���L���%��A�c��8���*�s�d��go	�mY/�Q�d&2gv���p�������DhV�5�B�O��P����<o	&x���w'-d�����iZ>�*2�W9��v0-"�?1M�4!`S)9WopZ���r�{�γ��ݥH���ʈ?[�J�=}�R"ީ�w�v�o�Ғ1x�?����������Ķc^KV\pK���BM�f퀲�"A]��U��V�1]i]
������G�8�6b �)�OV�XJrU!J�J��@�2�@*���b��>`�W���,z����Ik����I���F�\�3�f��������SfQ	�8�s����OlV�ap,�8@��ɰmK�!VN����W��u���1ͯSH�S7���"�!�7Y�ޒmL�h��OIz��M� ��@�N'y��9��_�)wl����"�@���	9+�ӯO�^ͽ��M>�����յ��傰�7��T��:*I�v�ó'7��t#8 ���@�}��,�� N����.VJ�v��$��� `D5�#%X��N��Mf��5�|�Ȃg�Ǚ�5�=uq�?�)�Y�I(�S/�A:�=]�������N����%RECk?C'1Gk보�rht��� -toMj���y2"����=M����{��R��nk�Ui�A�Z\&Wie7��H�Y������n-r�M8<�qA���T��H`�2�~:��O�Z=�ڍ��ڝ�iK��S`��u��.\�s����z���r����_�/Z���>ى$qjY��M���L�]L܊�S)�����P�xzCfY�6XOB��7��r����~�dK���z���A��y�f��R�o��!e�$�.:������j��4�vC��U�o��qtqS^S���N� �|���Y�߯(�Bk�RWi���A�}��x7s��.uF����`�ܪ��Þ��̔�Oe����p:B�i�)�F�_CG�\S���h�f�Dn�>���v1iW�)��2�k��`$�e	��:ma�c!M�V���l2�?�D-m��Ʉ��C�I£q�	]��&�����Ro�ɔyۅ�M��QހXЎT�\�F���D�c�y����
�to�-�w��d���Z��`���V1�Vk���[���@,�V#�G���z��@�k1/�*h��y8���.i�R1�BS��Y�+��`�U�e��cA�rt_Aa���\Cm���+�U<]�&��4N@&2�h��j	Ά��E���ޥ�Ma���FŎ����]&���-�ARt^���0XӍ���|�����륡������G{�<'�@��0>�>b�_l��m�s�5����j�������L���!3��i$li&?*��j�6�V�e/ֺA	ّ���FP�l9��}�w$�	�(��#o�a0�hR� FDF3<�D:�C�I��>���\AJ�|������]{BKT�5mIM6�K6�8�m�ӕ� ����FL�2���:���i@�̢}�?5d)Q�˜�e��cﵬ�=�V�3%�;����9��=�}LR��P[���K�^��K�"Vz?����>ǭNf�e`̽�ҷ���.9�o'���kdr�3��~��^����_��|99f���Mh�\=�j��+�W��7mM���m6��]�f" �J`V���9�GR�����GH��=C����5��j�DQ��cml�?
a���E�\;���7N��K��fw���	׈�6v���Fzc��
�t_,�4*���
8������|��M��)��JS�:�P�k*�ys�Ն���0�V�CK�z[ϼ̝�	��ʐ�h:r�!�}u���E[ދ�L�jmzG��H����ŷ� ����W�apYdϩcc��\�2�@���uFr�G������������"-��������~��V>7�i�	���RNx���L�N��)�g��GV��s�;-����5kT:%f��ڭ�ׂKs�ӚU-�]��]��T9��Ln`o�es[��M�1k���0H���Tɴ�j��B$���i��:z�:j��o �J�6��ƻ���`�?F��#�%zL��}����v��-!1����g�,[���j�r)um�w��6��05��j��,	M�j�e6�c�)�?�{=�D�K��V��]F���:��5���B�~Y�����-I��0�m�ϯ�ɣ�i�͟egtQXJR���*7���i�����Ж��0;Z�0���r���kgP6t�|w�p	|ɟR�x;��g�n- ��\L�r�����\��sQ�5;�6��t�H����$��������ڻDH�kv�$1wb�XPݟ�m��<Z���������C#���\���Qԝ�����K��}{�.%5�TݏѴ(3L:�̔Ҡ֍��~
��&��F)/�-s��E~L�o�?��>kx��+L�?6�y=G�-|���[��z�"�O�%o2� .��W��u��R^IX���6�q>������ؖ
=�h~�d��{M�}�جI���5�BO���n��./^QT����X^ ��⻲���{��pT��q2^�[���$\�2���`� &��dHdYrY����'��o㪽�G�v�g�-{�gP�F�F�^�KG�#�A�|30�m�!�do+�QF�V2Tnt�*��\� ^���P��r�hF�#=<��]�g��`Gw��]�=>Ҭ턽S�1^��}��b�5�ӧ1����aQd	RN��lO��@Qx�	��M�0�};����~��3�M�pQ�Rc�%A�0?36����"��P�Z��_��PGs}GFO�B��f9� �`O����6°��hC
{�{��$�{iM���ȱT~�3h�<�x�1�pxk�f�HBI�"0G�ؒ��@J#a��$c�dh�y�|8�?_�c|$GO5�S��<]��/��ϼz���p!(�^F�ceP2��S���ťK�o���t�Na~]�s�=t7�!y�^B�d��""�W�yaS@���C
�n	��: B3���L��}�r@���?-߼�ٲ!9�C�l� ÏV	���s"|���V��;0w]-�+�V���VS��	x7���EaH�B����j}�^��V�� XS���B�*�PS޻�І<�t6�I����V�1*_�d���Y��{h@p��@����q�ի]�.��w�d?SS�0�C���$��Z�έ��!�@�jF�!p�S�K��N̻Όt��Tt�wRo�<��y�A�W~��!���F<}�^g�:���`��G�
�@A?����4�
M�Z�U��/�r)��z��D~}w��\|�fZ?��@�JU�D���qk;+��M���Ө+d�Ѫ�qo���D�-
����/n�I�4�[&��P�'��͂��0�t��	��#8��a�5���1��H����%M|�#."n��1��'��^Eܶ���B�����^��"��t�I�+T�"�x�is�1d#60�"2g�u���[n��	Yt%�q��S��c�� �~3��~�f�˝�׋�F���w���>�$K��'���
��
y+	BKz������D�.=RRuM�j%�.N6��R��PC}@|�����r-�����O��'�d�8TLJB�Fy[��Ψ�0�~Ɓ5&RH�;���-M��Z�'p��[m/����4-%gG٫����E6����t��u�*I�F�`X���H� $1@@������V�9Q�&?�Mĥ_�8���m0��;�-�>}I0��=(\�R�H೦6z��=�Z�h�&T�<�A��q*��BqH���t�;*�T�S{>��k�%>�7y�k�wqk�c�0�����d+��3�{ۙc�$+}������R�oϞJ o
�b��̧$z�}�#�,�+Y5�쟼?v�xĆ
)���W�_�i����b9����ʝ������U뺫ʂ�#� �w.{F�I�]Wq`ե�Y��&PHP�F�K��A��c���1r�����x;ûb%h��c�;[|���i�l�P8���d��T�u�~�Q���X
d�ȓ&H�S	�_��4Ev����;��35�oR�8UVE�wC�s�!	!!�s�q{/JI��x����n��(|*'v��h�ś��U��I�K��n�P�+&i��|s�A}��{�1�`MX��=�<�<��J�Uwl]Ҷ;�,_Rj�j>?|b�e�{$����kz�eŴ�ߣ�ȵ�&[;���7��b�@gjnJN.��4�]{&Ws����g��!ζ��'�_hn*�!U����xj�`V���b|�T�o���h	�V�"9�3�W��f+����/ ��ث�д�0βL��7�m+��=ۜ
J k/��QC[0��xb�0�Lɷ�����t�k[��g��UU�u�_�,<����\jc���|��J� �I��}�d���W=��w�<@e��lʢ���輩�«�����/&/ʐ��y�����	�
fuoq���^r'6���'���*A#QO�����g�m�O>4�+� %��}C:�����s���Tv�K9NAK.�U���"`���oZd �j�yM�D~��t���rQ;Oi�룗{��� ���X�h���$l���gP�_�ơFa��b?���Q��f'A2H1��P$ujc��<_��B�j�I$��k:�5
v9�:��Gg��?srj�$�sh�3��{k˷ص�u�A��8u�*��f�g�J��m˗U�z٤\��Vh��l�`�Д�/pôn���!Iwy�p�m�hxK�̍L���6�����p¶��h8�.C�\�c�G��0�cx  ,@p]��?L�*�z�o�����9x��g��J �z�K?��n����)%��������S�z�S�\Qk�EK3&�v��#.-�����=㍺0����#�K//T��\�B�L,k��5F1�]wϞ��A�x��&?���f�G��;�q�A8�@S5]�2l)�r�Y��'*=*c1
	��E��H.��m��!���vTa����&����D�Ce�CۓU/O���*&�XƜ���ҩ9§�gQ�$m�[z�9A�Q2��5��x�:p���,x���������H��'J�n��q�	���A���{n��V�9?�|U0E2[��1��Ș{#��x�c���3���e��D�o�#f�߭D�e.2��W�6�a�jC��#(P^b�������37��z���@�O'�)Uw�2���oT���QjW^U? eYg(�V�x]���0-�	i��b 2g�@�Rհ��-���sR�XC�� �K���U}>E"/�̲��fi;P���:�$v��X:�{�*h�t�G�<�l�c�UѼ3M+��h�ò�����B���;�<����^Лp����T��r�~�����!�lhO����Aj%1�c[-�����?���o�M>�㟺m �����K��K�2�Xb�UUP8򝖸BH嘑��ު:f�vUY��H���p)�J -F)�+�*p|H��b��f��g�\.�wi�ޟS���FJK�*���!��t2�Q�ͳ5��Q<,]�F'�K�m3E��[u��]��8w���O�Ne��D;rPg�B�8T�M" _���D�#�k�/�M��&�}����5�O1й��U51�Q��nL'�/��6�����Q��)h�v8��^q���uQz"Bb�)
�i�ӵK���������2L+�7ڏ_K*�e��}�(�ţ
�&|0�ή�ٿ��80���G�������6����0����
������A�t�h�f��1��rϣ������c��.?%�h]fQS��T�T�-:$����F��>ypfqN�,����~\��,^�����ް�	X�2J����*�yR�M��R��Bn	s �)�4��C2d��?6���WX�T�1��
a�m�H�٪�M�I�5�ęڠ��@�p�6�׽�D_�(�Q���L�n�D[d�D<'�B:�! �ХuL���8&3��� �օ	^k�p��������\��>�ZHBF�6X�X��<��뤏�o�G~ɹj-xJ�/T��Y�V�l&���׈�mI2b��Nm�W$��#Ơ�n�~��K���CWu嫹���Gu�ƭ�G[�&p+�rd�z��G�+,uX���J�%�dQQwj2�W���T]���^�d�@�i�+P筑���
��ʝ� 3�����@d;h�]	Ko���hVSd�u���u\$��Uj��g�C[S�}U-ܵ���W�[�g�g)��Z�M�����.]kٕ��]翲FY�t�E>����ʣ�yTe���9ē���%4���=?��,�ݹ���6��Sy�]u-����w�-�� 9b`�J�vY������LT�.�N�gQ�Y������ҹ�fw�V��}�O�N�މΣ@Z	�WNKp���3�ݳ	�}d�:|.gp�2�/:D�M�ķ��Ü:Zb$�p���5��O=���.���*E,�5 �Tl`�wc ���i��b��RԄ�v�����+lM�⢲�����ġ��&�-�0�.���F��X j�uu��Q<6ޛ�����WF�S� `�2�|S��1�'f���v�Y��8�=�{�yTW���,�F"�"[�95X%�`�"{E�p`m��Gr�W?AW/�f�n�V)Xhoh�zgW��>�M��
[���D`��!�>D�/r�ǟ(�Ds0V9��	{F%��K3[	�S%�Y�K�nVA��#{���DfZ�Z�/��Ya�[;ڔ���Z �_sփ�x���^�}Q���8��[x� 6����>2Y���E:��梴�*���G8y�� ~�@��tX�V�V����ߝ�R����\��v���%�/���ޭ����"$�
|ZI�e1�T	In2�|H/��2�����hS-���T�,i`,��xy����_�&��2��l�� ]u�~�~2A�k�RƀsI���GՃ��ז���s�7}ɱ�I�"�GZxߩ {4W���9��E�'�"7o���G|-�vxCj�^�42�!8I`A$�\{���29�6��
�+M�U��G�l���vW��l��`��m��{����;P��f�VB�*F4��.x���-���� 8����ƻ7�E��ΉT���N���]Ee'�����qot���q����Ң�ih���R^ s��~�g�zO��k ���v��,�l�m�R/)��I6J�,T�.���$O9�%���f��>�Ð�D2�����R��d|,	��!���_.��H�wE�,��%����ԥ����9YЏGc�O��t�G����5�x�6���A�axN�1�2��#���l���9�K�k;��_xV2A�f�R*ø������fsHIUK�+�����}��b�=�J!9`Xz�����T?P��ǥ�v+j6M�sz����i:j�[��^ϔ��R���`T(���I��r�{�`&�ɜI����`�Z��wP%ĳ�vQ�('�lgb�dt��-�28�&N�z.U;o�]����VZ��	��>K}4zP3��L�Eu+�W����/� j�C�cP�)�R�u2	e�� ْ��+�1ø18��Gڮ��@�ֽ���n�!;n�x�l���U�+ �q��!���@��om�_�Z��Q](��A�:��(���%N׌'���KX���P����5嬨�n�L5P<-��?�\'6��*&?渥I�����.b�8-����}��r���]����SkO�ftbG����9iԚz�s�av�o	�j�>�ھ�`���<���mp� ���A!J֕�J�!��U�1���,�p�&�$3w��%|�̥�q|Ss�ua��r��s�ٔI��$ zU0u����G8�By�������5�n��� '���[����2[��O���ck^%e�"=���I������zN�N���Ѡ��Bu���$���q��l�Y�5�^�U��^�Ȱ0��z��d-�}������h�z� m�����gӖr�'VɟH�W�o�?��nr�ɥ��*�5\�9n���?IQ&*�������w�;*M���8��pؠ�VO�n��o���IWk�,҉��u�m�x
p�?�
��\��NV�=mP�MO )sj��\Ր*��ՅC�N	E9�b���3�ڏ|[�?72��8� ;�/��aM�W,qq�5�z��W+�I��r�A��_4;
����)n�6���Ks��8�C�Vg�c��f�L6��F�2e���>uvYڮ���8�	_���j��0߄6I���j��~\��m���E����5��-�,�̩�� A�N��7���i��� �9z��|so+ŷ������,����J������S>�b�'~n\pd3��%	DV�����!�Y��Z�������+'�)g/�@�"�;�m���Օt���FP0ȸ�$�Fv�ؤ��R����{+�K�%�����#Q�y �T��[_}`�߰L1�$�!-��)_8�g���J��2��tlS�/�s �<qPl�� #��F��bD	�>�L�E��K(���ِ�eL����c�8@;;X.$[V�/�ح4�4�����(�G���J�����g�����:.�^��F�������+��eݎ�SЯ7dJ�y�|B�Wn�U���;���t�	G�0m�赹RV�T8?�v��<&�n@j�&;�+h��H|Kê�ќ؃�u�p�����S�����¾M���xle�P�p+����:���/�!�Gֆ�D���@&�Kv���H���Ӣ�q��v�"��j�t-���n��2�+�ZRg�2{9|�, p��y�&���>%�o�Hz�w-).,�.�C��L2b�P�k�ۀ�o�s9�%f���~���3B4�d�U��J�EӛU����ұ�I�������iS>�3�+QJze�~����vX��ʝ��S|����8=x�g�kA�N+D�Ǿý������Eg���<�;�����G�!� �`䉔U��3�Ϟ���U<�':�(m�I��l�~�Y,�?8��5�a��1���#�̛H�0��������X�O6J�%�yګ?Eˋ}���<���K��t�Qvܣw��T��H��:�9e�K%�j!i&sΌ�w7k�R����t��+��;@}9����V�9H������M6]�]im4�����;G�+a�����J�n�E�s(��%Z�K7��r����k�V�/�x��L{P�G�p�M�Jv� 9ҵY?4x�Ň	CL��a&�gFmĮ�Y_±ڥ�G�䈎��@p�	���K|\D���)r��[�)�c� �Z�̇s{�7X���n�4��n#�F}�ǚ�oO����~"Z���P��j���3x�q��ct���v�F�[�Û�bw�QCPn� 0��an%��IDQK8�2,� 9�/4l��ZZۍ5>���M���A��c�G��nJ���m��76����.^��l���ֲ�?�R$������Z˂R0j��"S�CB
r�v��-^\�M(�`4E��F�7����� U��ۘ����-�]]e{㠫J�X/�	�D#�A(?}��΋\��ܲ \�z��K�0|6�o+t��V	F�ݎ�(y����d���&�:����/+r��JZ��D:�=`��3�[l�3`�Jc��Fa�P̴넖)�\<�xY�c+" ������Ί��0o���%E8�"�2_)+h����
��r�y�m��Gg&���fP����dxSI�)��4�p�~|'���.��@̮f�s����_��)�G�P�$��*�E�8?=�V��[=B�"��>���`��ktJ�w�®;�A��PL�sƐ��L�z�VXZД�%�jP�E�)��<^�����5f�|�l*+[؇�����;K.Z�/ř���-�V�����ͽ4s�k�:�}Kv��N�j6^���/�{��d� ��\d���+G!�=Y�@��n0ZEz��K\����Ks6o��9�|�4�a:]�NjB�����U�"Mֱ���¾ {2�Ol(�e��uZ��v��b7�ܪLIF�����وg-�!*�I���\>�k>W���v	�Le'�7��A�.ͣ��5��dmA|\qBh��v��h5���0B�u��:���mt�L��c����6��Pl �@]�+�-+�p�aD9��68��k*[�}���ΛbF]�^(F��b�|�&e&+z���0�Qr��ׁ'_c�@&���$e
�7�Ţȼg�;��/�#���bl� a���Q���j>%����\��������Q۵�G%������*M��*��s��������� 1w�����)���]t��'���a4N4�ߥQ�9<�!��x�$�`�s��i��l��w|�� ����/ڮ�P��B���nW����/��p0�#�wT��-�ڨ�q�@Y~����@��%}�l�!��>v�����	�0U��p�vjL�����{U�{5��"���q~_>]��i� y�,n��.�����r*�<�{Ӂ`���-�x{ww��8�d ~�g|(�-^$"j�����]�4��'�odH��I4O�3����
�G;�쇶W������qGMn�N���{쎿��8�z���I���+��p�|g,����b���`�k��'qO�RW
b.������<�צ��׻X8x�Kf�}�$ YA1�f��?m�C�X�F�v	i��A2�S�5{�Ӽ�j������є>:\�IpC}���a<���{�W�R]GZ1��b��j9�Q����|�Q�Z1H��ZN	�j���]OWgX���hȜBˁ�-����Vh��
�N��<2ŀ��6�e4ޟ��bm�
�8�%J:�IT<��xc=G5US���m�,c�B��S�����/c��@s��Ĺ8�]���UA���3F����7�L��E�q���vT�������rѱʯT�ؘ��.���ﱌ�B��@����R<5�2�I�B?Ӵu;y_��L������.�/�<{�Y�%&K'�����?�����)C~�l[��&F��%M!�oX�m �������f�B��[ay�g��r���h��K�~+�tޗ(�Q�����eF�'�zu����6���!p�ޱ�*��[x�(s@d��+���Y9�w��4��fƟ�N�82��䪮���X^�����(��4\��&%�~��ib�#c��6��N�I����+�1�ڞ�,��UH�WV���Ϳ���2$�DZ2����,}��	�h���,�io���7��#}�~ q�G{�E�S�N�!��)��&�<���o��d�`��FF>(11�������;�l�Z%�b2#Z�/�1��<�&9�����jkGd�*;<q�;���8���"O��v�rj�� 7�	�*|�hNԽ��A�,[�j05~L�B��D���-j{:�a�/���%�¬�Ԁ^�&�~A��Pp���M�
a}��p����y��Nc����ƍy�n�hh�N׀������'1���C
�<������L�����[J�{���+������#�m1�s��x|#��L�1oʇ��Wjџ��n��Q=+l���L23��o
z�<����?x�@�-���s@ИI�固�j�Q�QT�Ë׸���!'g��5��H)�>�j�cv3q�<�2��<܄~)�jF{�e���a5��$�z�g�2���-� f������?��'<�a,k��7����'T�6a���9�k�&}�<FlsP� ��Z7�\)>-pz�{q��3W�y�ޅn\�:� 0��|�.�h�;h*�� �5xݻq1�9��,�Ǖ�q�4�.���Ԏ�{��X����1�8 �m�$<.5R�0,_\���+1�ٛ��K�������ט�<�:F2�,��<oA���0�V�d�'p3&h��?�"-�ǹ���H�	q����9�p�J� α%i��v�����^�����?���l��8AG�SE�Z�ܨmc�6��bڼ�v_[|~i�*L�W7+��BϚ,'�W�xb��M�N�W����{�Z�
y�0�Q&�jH+
��`�d}�.�Rd݅�@~*,I~�!�u|�ќ�[��O��N�*��=��
$��������AJ5�d�$���v�DL	�M���i�գ	ҙ2øL�Qj���\f�s�?�n1��b�W�lŢa'�y��V�ğx� |��6J�S"dⵡ�#�;=%ܤ�kX��l�пr� ��uM,u����<��8�C�"Cl�	+Sa}����O\Z4ܳ x�+���`�����f*��uHs�*٬.K��u�E�vJd��k��\��4�kZgbu���^lAd��ja��!��\r�)y��q�KW'mG�V�US�?�8]���M&#��`^s����9�'��ˠ����5��l �'*��s�-8-��H�x)�1��DG"q���z�XlU�l��;M���G�cC�-��"�hH)��	 ׮*���\�O�X�CkxU�5M������m�7|�@�$�t�"4�"����$�:n��-��#to+�DI�����{i{�UI)�m���#�p�ƴ�͔�>�9i(�<[�r[�?�w޼�1Wm�������_
�s#�;~���\�ʌ�ܼV�\&��`AD!'�4��$����c���1�c�t�C��Cbֱ ��[T��v��a�,Eg���l��.���!��M�XϞ���G��}�V�5�7z��*���z�B��p\,�l�Ja:D0�{9x�89��h���zQ���]�]�	�=��]|Єe�'��:XaiҒ�^l��]藒��	iY��Fy0����н��vc�?d�+\�/�>���x�h�'9�؋��I�y*�.���d�ɟ�H��̫��(tB����4�j�E�Hܠ�@J��tՇ�rJ�����w3�o0ݩ_T噫����X��E�UGH���'S��+����-M���ӳ��%���[U�Yҋ����d��oKx�F߮������qP��FY&;'�c\Ԝ7��k0�vJ���K��7���pؼ�wE=T��#R��C�Q�&��Ω�����J��������:+QM����>�ʡ2m`���%�T�:���ʽL�+�y���d3�dZ�!`�6 o4�W��%.F2��h�K����[) z�	-T,�O����K���SipAX��R���橐�K>/���զ	'�8����QW��6�)�za[ذZ��VIDh��&b��r9����4vD1bR��s�����^��y�^�>7fǟZ\a�w\`��Uŷ#�I���e�7TD�r���tP�f�E��"�>p��1J�-Ј�d�$!49����(��Xн������Z_��UIJ�_�<}�Y��&�؇Йt*<����)xxO�Y�z� ��n����>vJ�$^v-Ru���-��E�|��i��&B���
d����}���
�h� )���!ND������q���n̷zXɳ#`��+���iY'Z��P��W���W�U  	Bf~"1 ܭ���kH���g�    YZ