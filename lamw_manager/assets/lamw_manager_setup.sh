#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1796252353"
MD5="95e38412700f347fe640301e5b91ef11"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20872"
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
	echo Date of packaging: Tue Nov 24 00:52:09 -03 2020
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
�7zXZ  �ִF !   �X���QF] �}��1Dd]����P�t�AՇAwa�	���]�3�� sd�+�!��b�ߡ7Ѐ�\�+��{r���
�FO�=�'��O��
Z/褮�=���i��ï��e�%.aW�Hźv�;�6�M(�,�9�w����,e��`�W��+�V��#���Ew4��N��P���C�Q����<��Oڕ�E�lՈ*��d_��O���.�y�Kz�d>��*"����5&�����h��$�JO��6pf�0 ��4�G���z�Oݢ�xҴ܋�w��B�#�!�A;�.�a������۹�SN"�h��N6_-�K{bȼ�2��!��p������SzD\���eHV�̐����M����>������	�
��w&��?[{넼�U$4��y�hFqDV)S!K�����j�F��Ќ����	B���jRY����Wb.���J%���n��<���B�_�2��kW��Џ�H����`�1�~��-�h�FR���wP�$�os��N���^�6�1B��R�ꉻ� 9�* �5�[�<7vó+O�F1Q��͉��5�ჅВ\������O��Q�����d�,��\�[��p�#y|n��%
�F�MC�H����.Ҫ��.��!0h-����M!C�0x�L��������۾2��)��̔!(C&֣J�v�=��A��C��e�E��xٷV�+�����Izç��ˑ������PT���$��ىg��\d�W�2��GY���Ywa��%0O�@5i� /�PJ]nU{g/g�4��UԜM����pJ�� �RئF��� 1��"V�`D��!�$��, 4��9������7���{`^Y�G_w��u�⺲��|�+t�w����i&+��UK�>���V�w)��R���<y�M�1Ӥ-Tsxd��S�=�d0v�6 ܌�˝|�a���`i���p���������@#B�ġ�r4G$Z�-U��SpO���k�\;��kC!էհ�J ���$���5���D�ۯ�!�,��DEMQ�޼V^�Y�B������T^l(�)eN�0
�R���V0�H�|a-��<jE����4jE ��_i ���P�ޅi��$ƀPl��C�Lۇg�������S�1����+��y�C�矸2UI�<�Y����z���?�.�����"8�:R��K�'J�yT[������EQH�8IF���u�%Dt��
�NN��G���	��r勫��v���L9�b���0_�&H��I�u.�E��F��L�k�-�^�X��Q��ʹ�Zp��Ж��s!��*��g}&�~7t7!�U-4�6Z���Ҕ+-���Q[_׿�W�F`h���5=�=���c&C! ���Z�r�6��:�c�E���G,�6��z��wS��&i��tʊ�yH��(g��9�O�H��D�ή� !-5.����:������h'�eyY�!xѥ�[�L¨��Ŗ�N}�ot<�V~�	i쟘���"�q��Ī�db3� ���|]��B�M�:2��F�v���u)C��䪛S��6	s������x>j���A�W����>�H:�W�P�#�ү�H��Y�r����-k&�zS�{LQb��&����L}���Ɍ����Z&}y�U�;���R�>�C�e��Uj�\5��'��t�˦�p5&!�(���"�dK��5PC�S>�zj�ys�Q0;␔���LB�M
��_*آ�*��Kr{;q�иb5 �rA��0V�C�p/�a3�������9B :������2P�n Ɍ�pg�u�n��?v}��t\������c���8rM�1�dK��j�%�
	U��A,C����E����M�>��z���ַuo��9o�?|J�:�,�%ԺT��T��^@�i=��Ke�-�UA]tx�� �$�[����=G��1��r��v��r}��}�B� >�rA2�3�~Y�e�	"N�5��`�[�=���Jg�B�gmޢ߄y*��\*���<W$�f��3�<Pn��Y�C��>L�cc6~A�#Z�q �T6ɑl y���}���&-bT·�iCՉ����/��
>�:�S���)�����X]�ƶ�3!�!�;����I��=>/�
������G>]��'���ua�����5�'����;�r�ˠ)y��1YQ�n���;�#- >�<����+/->���� ���U���^|G��/���
ظ�2,��b
=B7xc���O���?����mÜ��y:}L<)����6L^��?���Gגm&��{,w@�8��+���Q1�kX�@Y��\�9�ud���e�_�R�Frꚗ�\��zp>M�2����j$ӈ�S#X��� ���-��y��>�*�ܰ��z�[�<'���1k�o��}�<�^^�-���N���@�b��w�
f`8W"��7E�F�A�.���(i"Sn����:��[��a��Jه�ۗC��M��U�^�����T�2R.��*���"�ͅFc͟�񕦴��,�54�Šbkʶ6 ~���l+�݅}k rw4}߉`�T�1�B\{�G��FBP�`�z���7>W�e�[���N�O��z���l	(f��ڷ� �+4=�)�u�O`�{g�8�#�dR��Y��ì\F�����5�ډRǃiz��Ǚ.o�ϊ�a��|L*��mõ�`_�O;)?;��F�h��]	��(4u�&-���e&�x�+r��B"U�>E�Q���D#�;�S-����
>�Re�4T�v-��g�9,ah�^��uG�n���Գ��+,���[�`��<���Y|�>�T_�in�oknP�(h�`�02�0�Nշce�N��b�v������Wӽ��<!*<qmp?�\���A}�
L å��ϲz���qiA��?W�2e'�lF�ͮ�S��S�l�#��gaא7f%��f�0άt+���6F[�Tj�XS�����E@Pj%�[�r�V���0�l<�_</�#�w���ȇ%�"_�TlO˪p��Ah� �"�tA^-�JQ+������4����Cm��V<�8��A�p��;�:o���:W�9X4?cx��RT9&���4�U�ióS��6��X�J��Mr���?5�$�1�M�6v	dd���$�e��;�q��4g?�i�$�|aK�<�A�m����$'����Q���\:3�|Yu��a�gZbEv�p�8��83���*��p�h�)_EY5t��tIj>8E|�)��"m�eh�)5�f����:�<s�g�|/���������mׁ� �묎�j����6ET�_��A�8�ڶ.�*�U=g��>wwI��_��j�2A>!i�g�bGܨd�Q��}��IK�̫:�"M�ˋ�I�d���R�(�0��4���"��s���{[i��B]FS��l'���q�Ed�+<�O�a5�I��e9	��Bv�4��mC��.�pο�	�`[��QԾ�pr[�xIϟw�?)�b<�kq؊�T7/�Λ�峸 ���.#�/�oƕ�x�'����f�zE��������1c��rG,��2��8��`M`����^"�\�N�Z&qv����FЕ*��d�ଲ@hh;���W(F���J>�[b����ae&a�]�o�Y��s
�&�Շ?����˯��Y�qE~�!������"C�>M�DA _9�zz� �u�8��l+�ƧObaF��z������$����e �[�I(Ϧ�Z9�
U�2H�c�G��y�����<B��X�=��f��t:�f0x�h�ƛ�%*�si�X�UvT�Kk�/V��&Wɉ,s8w���8�/��_xX�[�-Ih���u��M�*v�M��{�l���;���������.�F	�׈Z��H�GO=xu؟���p8�S~�?�+5 }��Db�*<Zy벬	��Lw���(wiCB��ׯ�|h�w��nv���OE���d�W�^�i�;P����(_tc�'�FZ�0�I�Nj~a=��h�Q,�C�LS���N�%<kM������v�0����ʷ2�׭�����v��X��l�t�K��t4��v)��� 梄ZC��&�99���}��[��][�0���,���@�"F�Zd�?"3BW^�s5����[�Q�{��^{�
�&ӳ5r��������Q�u�h����"2!�A�V$)wʾ �d��A�&���;t����Q�r�V�߰��o�w�R���'d�>����a����o�Ӭ�N���7Jhsď����-�
S-�V�+�@�z"��uXg�G"��_CP��S���^6��ƙ�Z�"�>�~�}��Vɜ�-m�<�`�h���	���� L�%L!�<}�p�J�6 ?�D��r�EM�n�*����O<��b+g&0������<��j�Yc����%!I�\���?4���vz�D=��Pjdw�m���Q������o�|��8�����N��)�A(��c�E�66���ƈ�O�EH���;硼�U|6=�B��/�.��~U�o�dV���ż��E�j�1�54Fì��S@�����W��<Y��	&@g4�	�P���\�T�A[��Tu�5��h��.�50��q�mf?��m	T��R�ĕ�h�=ӷB���&r1��G�~5d�樕`����&����0��7����9��,��w%"ư���bđx'���2��*�?`W<Kͩ~9�����/�C_z��{��t��j:Z6T���}��U�BJb�;�G�~�Y������M1-�qo�OA4��|Vp!�ю�Kx9*k8�tk=T��\.߽�Q(��˜m�
�ʔ�
�d^��@	U��x{�3@-�D�;/�5^'Jr�~�G����1��mU_Cv ֠�1�����׺̔�C��K�����!�B �,���3<%�,�/r���b�Z�ޙ�%�$���3��0m���1�`�5�-$�N�p���)����^�~Vj�n��u�MÛI^�
�B9�o���kv��T�"t�Ol����O�|ɍ��{��)��m��n��+��P��ķ������#C���ȀT-��*��K�a)'Ū��\@�~�(�}@�&���1rM�$@.lV_�p�p��6$Tv�U5��	�m}��Ȑ�b�����Z�x�K0ir�ĝG�т��a��$BPB��k6����{�:�0��;���R�_N��:�q{ǡ�L��+��@�̅s����c�=�`÷Rf|�i�l�w|#�i���81&��q�2�au��������xE�e�KN*H-�����sC���4�$�����\`������!��2e�'A,���e��Q�����߯i��d1���Õ�ǖ����&Q�HB��ޖg�vf�+ď����87|� ��Y��4I��c��Vvn����˭z��|�o��X�e���i�#x��|��@ �����@αAK���5�\lj3�=���ձ�@���*J?��$i����P4��2�j��d^C))2�!�rg(��x�*�o�$1:���T�C��h���2� �5�(��T��p����&˭�X�ȠC|,b��I:�~�����L�1�i�CK<y��6ܑݡ�J�P0�n�v�E�ЭQ��;�S5Pt)ۓ>��J�,X=��(q;���Y����[R�0	sN���,F>ͧ�q2�D;�y�Ie̦ �&^t�hǠ��RA�x#���,��u���Yr�Q�eX<3mN"�6���>��)[�{@��Z��ޤV �}�zNgaf8�����:=i�h���33�Ss3x��D�e�<�j*����E��1r���/���^Ћ�7l�|8�RwHKﾙ!&��"����r�%��%-o~jFW>
�n�r�$��K�!A'��)(R{Ŵ�2/���{ ��ç���k���b*���gVP�>7TJ��V�2
[ �]���1��H���Dm�/��	��^��X���3����{0� �0�܄>��<��D#̀0%����b��n�UYI���&�<G����k:i�f�.��,��'��!y���d���yk�y�j���E�#��_H�������M�d��Je�#vV�U�F�h�`�:�f��2��k�>�0���F*I6P�p݁5��+Z�9��@����=y�dҨ
R6T�ĝ���e32�vK�eL�:\jh�Q0])e���`�#����r��^�h�w���f�kS��)lڌN��6Jw}D��k��k(����d��8ۓ\e�Na|�s����*�Ѱ��qtLS6�J�0��C-�+�XX�N��������mn���g��5P�E~�/ q$R\��q�i�����Q�ua���X���Q��f�0x6+&��&��\e���F�_���X���o�-���^E�P�E��K�|�̒�~n��t>9�(�y'?���H�МX������èR�'�瞂er��@d��M3
���:�N���@2��C��z+����Q=/9�|����j�T���E�E��4�iQ��c�;�`��Z������ҹ�o����t�<,��w�x��N��C�5x�л�ff�Lj,�ĊB��_д?�ך.�������>��NX�e\�-�Q��]���j�滁�2D4{w�t.vM�ᄏy��s�z(��.#�*J$�uЯ�]��x*����3ur)��mm�G��XY�#N��#�z��K��&�^-�s�~��N~L6��#c|	��C�$����&x��N�\����9_P���k�d��հ3���!����T���E�֍�?,Ӵ����W'Pn���4�7��?�����-AZ8Bɰl��X�(,������ժ��ʽ#-�Vs��qcѣ�{}��t�y��J9���w���+f���������v�	���:�ɫ5~�rQ�_�R+Tn'�ȍ���]2���J��=�����ۅ�>�,y�`߸���i碴陰�ځ����M4���V�='�`�}PP�Z�ě��$��҂��8�b6ֶ�4.�E�5Q�4�xT�K�d�s.�H6��s&�y��W�
"��v~�M��嬕��]ZϹi�r6�=}���8Oj�r:c]�Lm�k���c�`���BI���)�7���:�@Bv��H�Aw�� e1}�N��Y�Í��L�"�Y��P�,B�QF+�*�ga貭�*E�`P�^Ʊ_^�����rAE�q"��5�ڟ^���1� ~���e�=��29X�Vr,���nމ{j��a �])8�ՙ����;;�pt0�L�ƜϊCB
���0Q�j>qA>�B��K�Q���L�F�|��r�AyV�x<�'�'h���3�9���0�� ?<���dH{&����Y�!�gM��3�hk�9%��rYT�&?U�zcqNT�9n�|��+���9��5�?P�<�z$Z��3�Cĩb3�=_%[N�nU�`m��t�#�jY�$�x���jԏ-k�eu���"m�·�[ע$W{��(�jzNq��9��Lr��G�UGU�U�O+��o5�����ۤ���eM����L6��T5�Z���K�*+G��Z�B"��/�3 ���{�N��;���*���p�Ԥn��bY!{Z�-� �$���q��Xc�}��|w;�e]�ܩם���m?���	�\��F<�s%w��k�	��}¿�-gI��Pd�oE�7�^ ����Ha�(,`�g�1z;��=�^����3h-�'�8, z ���N�1�3�*PB?#j���7�Zt�� *; :z�+��`NSo8����o-[P>������Ph����9���p��|/�CǞ�}�΋�y�����&u���G��v��/7��1��i�����V�����b`���0n�e�2"���m��l��Y}�YdrG�M���iϼ��f3&�t�H��/�}���(�+)�ʃiZ�.r�ɡ�]�+�@'3f��R�pDڐ�X�!�q4(*Yg�J�/~:S�q �|}��MN[�����\8g5`YS�D�ml���K��n�]Җy&_2.%�pL�j-q���b�<�/� ��n�&Ht�H}�_0V��͚���fzG|��~�C��D�?�1?�u��	0�SE�ßtbɱ�����c��
���FO���b�rA�^_;��L��]\���`_���"�G�th����x���k@����S f���mB�t�;�� �(6�tx�{���>fܴȓ��R�� *��-���c�����@���UW_�Z�����X�����&���J�܁W�=���u�Zwy��W�t���u��.J"���yL�i������#c!<���i
m`�w�)}ޒj^�^B�/D���[T�A̗�b�ޑ�g`�p�f���*�f-��iWR��#�1F�a0��8��[-D���P�Ԡ7�����X�)誊!ˤk�K4������<=����]����� ]��Gԅ�N���f,O�JԤ��ȷp�p�g�
�w(�`=`��پ�5P���k����b�\���9x��\SJ�f�������m.W]�=�}��C��h0rlRv6�7x�R��D8�l�󋔱*���`�PNn4Y��aeӃ������:}�@��"��λ~;�p�%�3�E��7ҡ���:>�G5��</��)RK{ ��mq�II��P5��О�$��CB��v?0����R$�R��Qz�Q�j�01�������H0��}�$�n=&�7F:<"|Lc�ׇ�-��Bn|[�3=L�眏��l3���{�}�0st�W4�Y�@��5 ��`���$���4*�P��+��ӌָD���#Kg��<���a}��ve������ߜQM��ǨF�3��q{�����K" C>!l�"����èc��6�as�Pbg�5��qL��=8��U4?
����\��9gjƾ�������[*'[bPD����S����U�-��K�Wq�N@yq.��f��ap�$Z�2V\�Z-��dʼ�L��$m
+\>Ȱ$@E3a<��M�+�"�Y�uY�Y~2��ҷ�ra���U�X'}�q�_s�a��8ȉ2�̧%�e(:<]���t33��uG���a� oVN���S'o��uʹ�X����zwL ��qM�����Z��ud<RK�L5.�r�>�>��(�y�O�`�]�K1b�eƾ`�}y�n!ȟl2�)�����<�)գQ��4��q����
�^{BYpW�=�@3n��h��6;�sn݆�V�Z������n_��MWs����J\��%�Dݹ�tr����}S�1�5�C1���?��'t�m �'���T°Y�e�j�{J���Q�_���"tIJ*�ѢRi[�i�J�R��a]ak@]:.+{�T��i�$K7��^����s��m�d����Y���G�߃˥�"����~aE�� 5x��(��AU{�������2ydTǭr,E|u8|6-u�:�}��������)x�8ai�Harw��7��
c��X(����	Ec���U6[����BHM�B�z�v0�	��V��� r�j	�y���m\3�qh�{4VL��{n�6 ���{\qL��?��dVO������}:,�&t0���\l�`�
�Ž2&n��M��q>�ev�,��=w����j'�l��:O�e�n��6)�`��C7w&%*qC��5�*����c����w�bM���丙ЎN�>bOf�zQWS����;�ߏ�v�1��u?H�h�ZN��Nce���q�w���ѕ�u��jR��K�����J]N�ߨ�� ��=Lʌ�Q�6]�x�%��5�R���<+�Է[P�\�Lkޥ�
8yC��x9���#~�/ť3z��O�A>4�]{Q�)�.'+�}u�K
x?U{o���9���XZ/F2�f7�f����!�b�h�"ɰH6�v�Y�D&��x�����˚/��v���]��*���_&�+��� �����w���>�lPp:K�9D*��qBv��ye��P�8��7^��0$�:Ə�v�0�1ż83�����Od�=�cs&_pP��Bl ���&��3�f�*��O��;a�(�qS���2��po����k�2D8>��Ę�U*�0`.հ�U�O=��{�
��pqr~i3��&�̷Y�&IC�&:�iWr,7a⊫�����E�8��$�a��R��G����듵UdZ�^�{`Ƌ�����O5����v�pl� ,�B}��Ɲv4��H�+�Z$��x�G7���Y@������T⫷ >�V�X2����
Չ�@�=2��3 ����s���Ե��ۦ%�jW�d�]a�m�z�&���U�I�(��D�I��z�dj������r/.��r����k�6g��񸉅�
���U:�B-xZ൅h�5���{�x��ZϽ໩$kSK;���j�"}�-���U��������`I��4D-n�n��a���T+�]�mJeU����6H� �f��ځ^If(�%7�AQ�f���T5�"�sGg���┍�X^Np!��n���zč�Xyc�i�BjՎ��-���äp�o�9��Ey� �8Y/��0��YMZ��\4��S�E�j�X���2;u�:�l� ��pF`����>��T�0D��/ro��)/\\9��+��[���Jn�u����	���ִM��00�1�"T�T���V;0B�>z"WS-�� s�Z;�v�����R(/i�a�]��+�
�i� O��#�GGy��[h�?�az���H �9��<g­�3��Xi-Lr�A�p��2��֫~� �R�x�s���+N,�܍(j,���K�������U΁���mAE��
��
��#�FR�$��P*��(˜fg� ���[7j
p3���}]K�$ �z��y�{��m=��e�{+����~3�6U=>�E�ߙ���06
�P����w�2�s��k��8#٣�]��:��KA4��J-���P<�y��a�+�r�V}���� �K_�J�/�A�����B���ie;P��B~>�fM|����^��o�nO�T��Y���,�Ș��/�>)������h-UN�c��ڎ�VH�q;8��\���\Y��Мέb�N���{�{��)��A����@Ԝ[��#��Z�h�0-9ֺDOA�e�k����]��Gr��$
��T�s��Ie�&�1���uˉ�jc�8�d�h��|{8I�5P��ֽ�!�iV��hu��t�2�G��5���f����g��՝���-�	�/��B��Vvz o+#��z'NP줿t��b���s/��jG[uvi\����(n�ū�o\�{Gs�������~�9ҳa�OA���)�,��Ҝ,ݝ��)Vڬ�ҹ�n�?U\ՙQ��8���~uM��J��m�N	5+��A���^���l�?�л��D�Rݲv����2�#a��D��F�P���-�D�kc��KA7���D�0�s�N�)q�����:�"++��vq"��:��������2d�P���d@r�c��@m1��G�,�w[�a-s2=�����j4���f�<l�����MJêr�{�p�պb�5�/ᫍ>h��{��K� >	I�ZU�Rє��N��a���^�3n������"'�B�鳤�7��llA��ɍ�N��1��O="q����p�8W�oW^����aC�o��\�6\2|�?���X�ەY�V����6�D��)�P�D�<n�!BV���W׉){!u�B��WV���������a4IZ�Y&UM�}�/�fjD;��DVať>��F,���En�	o�W�R~R!�[�i�v�B���*lw.�9�#�L.��W�"ő�7��Ơd��OS�WEu�ߢ�c!S�xvK�&�l�&��M�7�GS�PE�酊�J�U��囿���M��cz�8��{p_S;�9��{#8� ����.9��E]��ߕ�����ZQ�rX�����߁��JE������[Y�P�T�Ne3&X�9���W�E���f���=��e�{V؈ZTd�el�GM�hm]��N5̘G�j7i���e�h�=�¼�����[�j�V�3thH]���diuF��e=y�.3o_4X�CN4��㞳w� mKv�֝;��B<SWj��[�b�vuj���C~^eXh�H %(>��
:B5� �R�����000�2�w�ũ�Bt��c�N,� �_I�$�Y8�QF4��L�i(�;a�"Mb��IT���}^q"�j�-ٮ�T�2�)°{��Ϋ�Α'�_�pq%��&��~�+�>	��W�N
 �����`?zÂ��w�����tQ��N����y.�N�lL7G����E4�eU��i~?y	c�[��&����3��{�V�����N����@e��|�-"��qg�=�{@価eF`:����ľt�QZ\=)h���Z���X"�<���ZM��!-��EmM�T6*�>1��\$>�uB�E̎�f=�3A)��IҜ;'2�q��eUr�7���\3Z"��8�H�N��uSAG�tԦzR�ӡ,^��V&�%I�o������ \����.1����>��&��z �5aH��HH���{�E�5{��*�o�,H�@l��v��	�쯜�?�	DC�w�!��Ӗ�Һj~?���R�D.��IKՂBLxO&F������k���%Ψ.DQg-�P��ҳ�eqH(G�����'y<�nL���'W�J�WD!�LDwĂ�k�����;������uNeT���b��p���^ZӾEڮwS��������8aZ���"B��CG�O)���8�\o�`��=e4���K#]/�EKhm�D�D�k�.M{uD�٠�	^�T ��Y���1 O�͝d���qt�Ы�N8�r1�"������!a��#Rk�m��|� �$&�c�OyH-N/dja��mw�����h*��A���ߝ7@�2j�Y����`��"��?���3�e��f
E�:�iT��UA�z����q��?����Q��|���C��oU����̻�R>�/+�b�W�2]���iO��%�rф).�I�ԫ��KPI��۳��Oj����(t��Q�Ũ��Έ�u%��^6SM����q玥R�Y?a�ƖL���el����l�3q�n܆��c�K�w��:���2���|�J��p��1�Q�(	�������P��Fl7�\�B�K���d4_�;_��n/�<�O���t5���RX oJ$��X�:1�v|v~�:2��b��ӗlk���A��2���e�&��;�Q}��S����9���c3ː֙��luhA�r�D�݂�|_�}℞�+?N�� <^�\�B�����̮���K��J�$������U{��䢃s3(m{m;Э���'�]�qNj6;c��*�ɋC��#�_�b� R4��"��]���K#���:��nMr����շe�}D�k�Ieۊ��9���:��~�`L+�07\�UK�x������hI��w���H��I��X'B�ذ�Q'֏��������&ڄVw.F-���jCu���}u����]�/�'��������|$N�DX
'�2�;�G6��zJ{����Z�c@�_�������&�|M���'*l���s�ؓ3I�̪�q%��0�>\*��dm��AҘ<M��]�Wdk�'\i޸!x�=/m�7+E��Z�zz�L�.��z�d]���g!T-]^pU��V���V�8^]O��]&{d\��I�����r{`V��u���������-��U�x�R[i!pU� v�	~]u
,~�>�,5�a(l���y '��\<��g���kZ����@����=ǒP����H1��ա()���^�Kh��!���di�#�S����6��/�>��s b�-IsV�Y1�
��Ҭ�����5�dUWA��}�s�#2!�lE���_K0"OR]�����6�=a.gsPVL'��Tqv)b�I�\g��6
�@D�Q�x�{G~�C̽,��XK�����7D�n|7�sk�4&�j�B���z��ƧX8���*��o�� �KН��"ގ#����oв�xXpx7w������DQp��I���=m47�v�6$M�ФV<����P���lHu��2�Y����:��5ɦ��4b�+g��"^�tJ�:�Zc��f��7�5I-�R/�-��p�q��'e�[��ۃ>���7Ա�֭o�U�_��z�l����٣*)7�a�����o�
�u̍jw����t����s�Upֵ��<�s��+�wt�-��
}۶%�����^z�����$�v$ap���0E*��(�����Q�*���тyv��*���t�@g�aiky:"��&��b����������V<q (a�>�@꘥��'6)�<�5�a�S�Ggjg6�,_�����lP�{�=+��5(A<bv����Ac��pÅ?��Y��
V�YNX>�¨�l�ڳow��D]�.�<��s؏����Eԧ�?`Qa���n�
�$́w�h������B&sW�[���ѽl�s�!����d��J��[�����#�H�^���e�a�{s<!	�&��ps���$,{�m�ո13V눗����p?��u�^��o|,�z���i�O6	���=�MI��0�m3���Q-��!<�'�ì��A�����lm�~AwB�5�/r�uc�t��܊i������]���C���*�0Fn��E�}�@����I��2�"��K�kq��}��m� ���W�����RIk�����D�޹t�dUyNɡAS-|���M�n�0͵6~�M/�Y
�)���cL�¼�M����'o:q)��Z����A��K�R��v,y�]�^��8?M��ރ�E�H�3�k��[>���h(0V��=�2j'����T��T����P���1��p`�ȡU�"��[�ߡ���tW�5f(
1EGx9�.]�]AJ�4���CG��ؒ���ɘ@�<)⡱�%ū�ɺ*,+��(���Gİ&�y籍�%��
�0 ���$4�'�������s�=��{"�c�Q�.R���G�Z�y�5w� �C�d�`�v����"1�Qݬ��w�h��.g{�K�p���PI�gg-�2�Q�P�F]Ĉ�������h�@a��j�(�I����%w��j��	�Wz�J�q�x�<|Pgq�r���OXMK
�1�,��*��P����w��ť�+k���4�;l�L�z�cl��⡠�p-:N+�.�
Ͷj�]NK$&Z�T�F��&#eD�K���s��`�PG���]G��ȁ%��Emҵ���L�<?尕���S��t�S,�e���.~D�/Ӱ���~�ҏ�����M�PQ�P��6.�5!&OH�����#Z�ܐ���;�^�!y�ԣ���P�C�����Mx�����H�m��)諘�^Z�C�x6V���r	]9�\gC���5������K�tP?��s�j���(��F6.��*栎�7���y�f�����Up B��u�̇t�����s�@xF�-J�Ak��6�Y��+���������O�5oj��x�g���T�;;�.���"�T�"��&��v(-�1���;�S��!��?jB�ea`W��cX����)I>Y�#��N[XEI�#a��cR�uf#i����C/�[_��#{�;���О&"%��[���E%UQh�Wo
柒5"�X7C�u���6+��z�/k�`�M�~�
�Ay߮T��SoWwc���?xn<j�v�]7�D�@�k��`+��2C9�0z��X�'��8W�E�'��\+f�Ցm�sӶux�ؐ�� ���s)�s���'��gU�DH��}أ���cQ��"����I1-D���
O�Z6�?`�l.���19ʱɟ9��q�Ӛ��oآ����Ŧ�xsa~ xAw�g44���KP�єvi!Pda��H�]N:�!�圝��M)��1c�L@�M����T�Џ|��xJk��6��iC�[E	]�$s^P��Q�"��mӫ�f��p�ś5Lp��0̣
�����S�t;b�u�H!DQ����V�����C���8�x�Q [��w�Ⲡ@�����/�朩]{�+[(\��6���(��c�GE0[$k�m5c\I,*�fO�|;��rsp�a�dU3z'!]ΑB�K��a�)��?+ [�1R9-�gx�	w�?`�G*�i������uz��C�E��}=v�񜲓lʾ�m4��Q��TqN3Z�,*&�~���.�P�7�U&͕�;�-$8^�o`҅��)M��!��s'd2n|*�z���^n x��K��Γ5��mF)@�`ϩH��b ]����b���0ցq�5�q�!�7HgK�3V�����v>%�!�:󺌮0�D�(�,��Q�-�T��3����+'b���}g��"���	��! fO|Oo�@��ʅ=��!��"��dU����67��y1�Ǧ��+z��D�B�S4r!��'L�(ϸ�F���H�t0�Q0�k�	�
Q�7�s��n�#D� ���݊�Ǎ���*k�Hb@���Q5�у95�McΏdn$LB�	+� `�#��?�ٰ8��ũz�0=|$㻚�Nh&pĦ17U��ݻ9��	�,7>���i�G8*�h���' f�܏E�����`�d0�ﷂTk>�G��5����Ng���?���l�T0U:6'�$ј�<�ҧ�9p�q�� � P�~�J����K������6��<(�:��FD�U�Pi��~��,}pX����:"��� !ҟ���W'�HS��N�]���U��!������I���	0?���1�#H��|����g��DC���@�T~҅��`�c��?C����pBԑ}��%7W��(�K��@�y�,x��	`7��Dl�i
T�����
��l,�{}�u���W��:�(�s��/���<<��_B'��첡iVv�;�7�_�,l�~<+A���1�����W4>�gG�+I���O�g*�Rk��Rh^��tj�hݱH��b{cf����*ر��R���צ�g26Vy1�ٴ�ލ��g��]��c݅YP�BE�i&M��
�KJbbB��@�%��0���thB������
�of��2x�B��F�Oꆭ�!�x�!�.����&:�-��B�m(��~l��֖��x<�#}�D/Y�[����)���ҼF`�`��Ý+jf[��`��[�B��%r�Yj4�\����~w�(c<E��#W�5u�T��x�H桅����b�b�u����ޭ�		].�?�x�o���:�0��^��ĕh�	K�i[ɶ�/8��pu`  �@�=�����ic��8�	+��ǝqv���}��tbu��Q���9#���3�� �<֎�XL��gd8U�~�����1�]�:�B�}'&��)����a�'d�
L;�]�h|��6ov��C�1¶�}Nw&�t������]����'H@ oY?�$c|��S��b�[�`m�U/�&�����nȸm���,F�uc�}�c)��撟�;��	�\�cIU���
Tq!۠ޜ�Bډ;Q4����s�P
ã=mW��zoԤH'|���y�Z��s�\�E�.�Lo8��TM;�-qU!y7O��H�!Zdu���m��0���g�&~��.Z�=|���e������J�i���^j=wԥd"��ӟ{c��C�rd�5X�ˇǝ����p-%�g*T�{R�\c�7oJ����1[��}�n�o2��֋��h�	�����ذ`ͱ��.|���h�
`�G.��L
��Y�X�����駺�2�n���0��#���hc%u����)��'vWWe��}F�'ZE���>���f�]�!�<��c���`���c�0��4T|B92z�>�Ε�9q�^�L̵�!�����Zs�Ā��κ �waW_$s��I��V������onu+�Me�mOp����5#��4��3`3*��4�9X�?��#)�B����?��G�?3`�Z� ő,e������=>���i'���k���Z�|�}�U���ǲ^٢ֵ=��r����p. _A���4� �x�WY~l���ޑ��C�.�!y9����+(7_�MGt��
.�+�|ĉ=)�>LD�Qh��G'�WG��!Op��|��P�(���mK����n\]Fx3�R��R�l�L���d��A��)Eqi���X.���/�Q�Wr����o�|�(e�hΜ��X�:tD��^�E�%�>�q��⚁�/)��6ّ������U��m����+8��W�!�{�7�5y+97��^o�a�B�T84�������f�Q8����Ӎ������e
ŋ�.��.TsԟQ�u	�,:�0|�R�V��J?��ϠP�n���c��>�5,aI���>:Y^�S�p��ۣ���~�#@���IM��ԙ���=�6UM�[�Vi��Hy}��"��3�^�
��N�?I�V֝?�;�/'��,Z~B�S�/YC���g��J)l�9�缠���Ќ� �^^�b��t�}��S\���oq����%J�Es?X�/Z� ��aȌF����ہ�r���� ����oʍyCl'uY��=�%Χ���j�Hug��<S	��9��T�a��f=f a�F�q/�{���=q��/��N�GdK%����Dm��3�ⱨ��v�t���e
1����i�^L�*>q���ï�
|�"U�:-�N���hmu�@�6�ƐL�7X��di�#-Ba;��#�1��dȀ]����f�v*oݔ�	�tD����S�@�����n���v�(�C���!�ٶۋ���kq+�[z(��R�����t'�ؾ��p�����g̫��T���Kz6wс�5��]��ӎ{�"U����]���@ �H����=�v���cچ��-����0)S��As��l>��%�F1�,=Cd�|!llS6�^`�^�G~�X�K�Or�����Cz�r [Fv�K�s��i�Ş�:�S�huVL��6���F"bS���zK�$��x�,�����_$e���ѵ�_]p��r4n[s(��5Q�0�{�@�lޚ7�_O�wӦ����Z����!�Wxڙ�����s?v���_ �X-���Z�v_`���d�%lg|�L�&�a��;�1�i���\�$�XR�`8>C�a_d/-'�Eyzhq �'�p���$F���D�Mck�4јC+��2�]�R��Qϡ�Hd�W�W�yDV�����l�=�9��u]n��ծ5D����7f�l.�|�Y�nMV�EU�2�2R��6N�)� �U�2U�1Ll�6m	��I��!�BS4˼�����;��&_��0
]�����,�Ith'�z��M
���f�쟕��(�|�h�򾯔 J��K�ێe�Ø\2"'��`TAq�:ag[��j�/��n��ߒ��ғf��]�ԨSv/���Ob:\�} �O-V�3���W�EQT��7�"$�Π� Rd	���OJ�<v���`�}���N�x&홪��s2��{��)`jg�{�Z(��U'�:1'��rYQX���6��`Ӷ�b��i��ko(��b�k��Qc�CB]o�[��z�e��i�����$����O$q�ѨR݅���s���w��A�,�7{��O���29l�GU�?@}�xn<�.�����;�Ն���=���d���*�ا-��?���_�6�;�I���l���ax1ɛZ�^>���)�Üϻ���U]sy�kk�k\cȝ�6����I�$�E��H����*z�|��b���nA�����5C����G�������a�M`��y�L�;'�?��D�je�y4>�ݐy��CϙCk����j��F��/ӏ%��/��?U�5�'��P�EnƝY��{g
�Rwn�!+����/��2wRg���Vq��y���fPYN���myb��o�ju ���^r�����������ޗޤJ\*F�k�9��b�r��&�r=tǴ@�r�i���J>f7PV�3��MI:L�miC�t�(p��-V�u�&}4<e�JI������O-���k�$L�q�SK���S)!���ozF�T5g����B�8�	an)D��p��+ŏT���(��!D�J��]ib�E�eந�\�K��/vm�N��O�]���x� �����V�lZ:�=�X��a�d������y6�(��=�"�Wwc�&�Cu@�z\�3Bl�N�h?�|��8�'�6��gY;���� �;'�0�D��B5�Ᏹ���5�	�����̎~�hQ�K����WBӯu�m���&��1in�r]١ػ3�1�߭��0{9lN����^{]%,Q׀<�úW�l�D����:������je�sd�W�wK�h~Fݟt   �3%�td� ���Ϛh6��g�    YZ