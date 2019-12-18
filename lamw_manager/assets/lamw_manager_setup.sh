#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3900370764"
MD5="4afba1e80713d677640d0f0d6e594913"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20300"
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
	echo Date of packaging: Tue Dec 17 21:31:39 -03 2019
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
�7zXZ  �ִF !   �X���O
] �}��JF���.���_jg]77G13��]�%�gc��g�V�s�Z��ȗ����]�7�?� T(��Zj�~�x��Nv�zK�☜#��0����hH;z%=��8��Z^*�}� �>�_m ��#Z:L o4jQY�Bt�X��"?�ϔ0��¡�x&H�u�r��ɛ�I�<? )3H'w���c����{|^WpM�~A�w+�E(�o�G�D�������Q4ơ50�	���95=���7��s��!�����ő�~LV㓇�P�O����ܨ���`�v�v���n����b$� Ro�#ȼw¥��"�]�},�y��O����1L|n����sES���Zo;摦b�,����<��fU�	�\e�@>��P���-r�8�u��uX\��U�֜ـ�Ǽh�����#@�`2Krm9w�y��G-�h2��K�ب�;�.��ٴL��@�y�����8GZ��eh���g����鞷ޫ%�\_;�da~#�^^���J��/��#�Ce�2��_��� d+Ճ������a��8&�A��G��߶�&Qŷ�G1�SX�� ��(A�����I71����b��_�G	��;ޣ��x�1`����	�����$�Dl�b[�Nզs���1C6u�K-k��z���9��CT7ȩ�f]Ղ7�ߏ�H��j��2/2ۯ�iq������o=Դne^ė �� /�^b��ˑA����*L1��ugp $-_�[!ek���4�:�_��>�ذI]ID�\�:ĸ���}X����LC���'p�{{1��X�ˁ �����;Ĩ��j����4V�-�P���B��U݌En��A�W�%�@d:�<�`�}�"3~�B���۪e._j1�,qT�Qls���@).�������V������Q���#(�ʤ�]W���1NNF��,v:�'}G�|G�q�zh��L��+��ƛK-qՁ�@���C)��@����uQo��s-s�63VD+����/.���<�d�
���<�OT��O^i���8i��CX�FQ9qb�Ӎ[�'܄e�Xr��2��=�� `Hl��~,vӶs<�u���E6[-Hp�P��%�QH��Y�䊲 +�xY"%��ϿM�_.N�
1�.B������/�^g��N��n�~ԑ�q&(�
����4�qP6GzĖ1$85� `VEtx���A��B=Y��/��]�6��xCO:����åRŇO.$�
O���5�a�̀��ɽS��D� �|�f���������W�J�����#P�!�C��`�ݸ�� �����J@�������S5��]����N��C�1E<���s��b-�Z��%��L�7��Dw��nk_W���KX�;R #e�?D��o����c�V���C_xl��3~��#-NHz�C�Á��M�.]���W����&�=��ÎJ������	h�=t�WO&j��ƾ��v��X�N��6�	�Կ,:V���x���f<�3yM��	��VF�M�t0��0Y����H�fR�ZwF�q��;/���4E�@GÁ����x�� P�V�I��;���B�P��\"s~�v�X#DIQ-�0������ǬL![`��ZR�>�6���R�3'��"�ҹ�7��)^g^*���>�|�7���
,�f<���h���)\��^" 
�m�n���m�\�r���N�G�7�Ay�P���WXSc�v:a�KD��~�dg�B/z��ԙ�[�/ (���ǽ�wu�f8g7�!SPN����r������S��e&����ZZ����VwX�K�/������{f�tYX�J�L�q3v����搏��KGK�ut�_�h���E"��:�)\�o~L��Z��sR	%d��=�D��5 �ң̌#U��=��VP���i��YM�EI��D�ᗀ��(j�����P�$N���W�P�W��7i�G߂ �2����i�����N�z���Li4k�v2@�l����v[ô���0�� ��f�]������M-=���ΒZ���S6()�[!X����d�@�~7boS�B�	��3{�#��L�9Ə��<.0�� ь,DfᲰ��da>k@̖�`�ܹՋR�&���:�ɷӲ��?������%>��mC�ze䆡0z4_濟��Qi��7#�q��G%��������LB�nqqH*z\���
��3?�3�VL�v���䚚,m��li����,�x����S�6�j�]������0��s
����+��L�V�S�E#���W!���
�u��꜄Z��.�f�܁��U0gj<�}������ӓ��٢�u��Iܽ�b�������Y2���I
�Q���:�v�F�3~����K@�� h a�y��el�@��/n����y�u��.��?H��,ƈ�hK����53kֵ�w�����1�5����O����7g��d�ñ!E�1/V��ur�}#U��8T�t���7Fo��j�U,�C���@d�^�6��x��0��B̓CΡ�ež�Z�S���z��g�xOޅ����V������"^��^jE*Zcwߦ��r���
��>���խ�Fi�P��z����o8V���s����/]L;ł���B��x��n��d������u�.uH�����q�L���<Τz�jtY��<)m!Ua�yF ��B	ӏel{��t�(o�k��<��k���˽�;�>���:�}��?�����'�2�;��+�[���V�m-�w��>�I0ǈ���MA�,��nf��H\�uO��Y��`�~X�{A�2L26� Ύ+#ɤ2�Nn�9� j%�4��<����b։,6��`��	�
D�]b�Ѧ��N��k?�e�̯,�pK��zW�O�"_���lw�C�%�[���B��[ ��U)A�12��3߽J<gJ.�������v��=���G���UD��%,	�<�V��ĕ�n�v�������t��W\���of�F~M�>��\o�Y�B�n��Bn�pb�\��r�M ���H$��"�b^�k7v)�[��w`�%:e�;{1�^�f���?� ��;rQ|�Lb_ҔAg�z�Sk����STK���&Nm��'鰺_�u��w؊`.�ړ^�D�3�É�5�O�dԷ�%e�[�N!~�� 
�
<LQ�~Eg����G d��d=V\XZ$���>G=�uF8LxFN�O�!x�4H�8�9�.	����~����s�l�/�\l��QTN�fe�eXHIF��:�1�*���|3U�ۿ�"/$�/�(A���Ֆ�s���ig�%�������#�;��xᱹ�-��{oB�,�J'�MDU�:��Z��i]ˏ��~u7��*G#,Z�G����C;e��� 4�v�į)i�oX��v�����DS'ۏS��uw�M���zM��=?��j�"
o{�Ȧs/�yU�����[�3CQ���"�O�z%���MԼ�x���7�^,�J���CÜ5â�>��H����n�D�d?��"oGEԈ���B�@t�QI����B=n�������ҹ�R�������pJ�*�S�������:i�� s�gq.��3P$���T���5{�FlzX�ZV�`2�W��`�"h�q�����i�i*�'A���J�W�M�k��b&K͉�{%�)��� �bm�IV�/���R3X�x;67n�{��&
��� � h/���CV�?|'��k[�.��b�0��%$��)��7Y@W��s@��m��K�]��K-V��j��
���rK�S�.�97@%��M��@�O�u��*�!���Oa�(��ݜ��k�1���G%x������Dd��X���.��>ҹՋYuٺ�����d7x���?�C���('�uؑ~��.':�j7lWI�%�w��W�#�}����T��9�m:��f���9R���n�����ʊ}� I����p/76W����}��B/�ye-�c
P�
�ok٧LŢ��{~���рTw)�M��(��QG�;�D����0�
�$�z̕�`=A%fOI��M��!@��;���@Ft^��o
S��{t{��W]8=�%�c5qѐ�ql�������!�-�m�C�(FY����ؑ!4��\���@�����[�5�l,7�J�{�o���{Դ�$I���O�`+9٢�4�s<�kE��y#�'���>_�n��Ze_�oۼ}�_Gdɓ�"Q�3՚4P:{��ɏ�;O��9�\��3�0@]蠨d� {�! �ZgS�JU�]6�q���g�_�Z�3O����࣡���Ice�1�q(�4@)X���b@d�2�"��q�r�ߖ�|v�%��K�Υ[cXc�s^����܉0�ũe�SY�I���W>�k̎�.�R0Kk���p	�5�廩��'�ؠפ�F��D�:7�}E_8����͔��&0�ɠ��[p����9x� T���0T�\47g�G��]�ү5㶠�� ���2��2#��ek�U-��]�֎�����+�%��
���F�3R�G� }��l={@3�_ӠA����Yե�iǄ�;
ַ_Gi<�4��CZ��SK1�Qz{�RgV��M,f/�6B~Er��Hp	�I�c�P6�)����TI3)]��D^��"�GsBu,C!�����7��s"f�?�����i³�u@�:�0`��M|�0BcBʿy?!�����#��t���J��F�A�ӽX���n�MIˇ׺ʣ�\}�S��'?G�{��q}{I�bwF����w���5^88ڭ�Zu�*�f��v1�lE7�ݧ#�Q-M�C���9����?�E�@d_B����7e�����:��y"a`�%�fT�NS[�"�<Z��B�?5�5~��(��x�V�pV��v��_��պ�]�t�gO��F���jA�-�J�D�q�4�v�홠ɏt�칄
���O�I�˩�o%��ըǔѫ�[M+7&�SO����WÜ]���!|�k�[�Fy]�0���ߵ(1󟄈�O�_�S��áP���Q6�Ie��zH_�[\Ŀ=��
��R�Z��z��(}ԌS�N��7P�-"_�gN'��!�}}��<*L�f��Sň��c�Q"k��
~���S�l�1`>�O�Q?�Ax�W�و����g���w��fC09�o4F�m��fz)Ņ��Z�Ur��i�TL9��Y-/N+����|�e�]f��xX�`��}M����I�n�fӡ���H�/y��R|�~�U^�Z<�-h�<�0;�K�	=�#	�I#�`8��Ԁ�-,k������L�\CV'_��\�0}���x�KZa��fW����:b�㦼H�_�l��5K���Y��^l����(R[��P�o�x�0Ro��1\�#<�/���4{ם�����h�u�VI7D�6����ݲp�CZ\j�eɨ{�,p�O�P�i� ��̀׍=T2Jj7v_"�D[T�����_�2�$ :����qBT#!ٹ�FJ~M���j��@�͢R bmi( x֏��5'M��`&��Ʒ�|A�yAs�Ft��شR�[�α6� 1ƹ�y��jv[���x_0����^�ԋ�����#4��`j~����ǉ~�!~����o�'�w����q�2��v�5�R�8v"�t�_Z@S��A/p�<�stÅ�}A��8m�� x3{7�RY�}2�0Rp�~�FD�9��N��ܰq��f�"�̨��P���&�(i�R6V{��W�h�u��s�L~+8`?�,b���?@0e������^�\]���M,ΐvA�=�t�/ݻ��@6��W_�N��FL`��W,�[�jV�wa(\�/n�QG��V�����(zY�l�̏!�6�����|bo6v~Aʞ<�����ٜ��I� oI ���/e�֗g�^�=���ur�����o�O&QO�m�eZ�e�"
ݔ�DUG&��9����+͞z���r[>�Pg�4��IQ��Z��w�q/��h'U͒Φz*y4-�͂�y
�*�W iVӑ�����)������y�f_��Ũ�Ë�-+a���Ni|�18D�̢���𦜴ӱ��&���ƌ����U!��S�A�������R}�����G��Ջ���S:�թ���E��jK�����ME���=İL���3���7�WA�{�G�b�N`^�d�҂������vH�՗'p��x6�����T3��P��� ����9��P������̙R!gJ`N��~fG��zYI0����L_j�!p\ܿ��
	%^�G�_c����Ki�����P�
;���ى��R��Sk?�1����:�<Gl��$����1��� `����M�G@l�M���7R���d�RҴzIE~ #�x*��-�$�u�DO!������V�+7��ɱK����}AR��պ��h��ޕ�H��!�"���gQ�	���r��Q���`@ƴW�A+�<Ti����x#p�$BU<��"|Z���a6bz�����*�p�fk�V��k���'u�A�6:GЅ������"U�s;���q����B���-��ZA�SDgP�87��T�
���q�i:}��5=*t�<��<"	�k�o4Pb��'Mri���;_�^�Y^�QI��Og��0S&�y"�I�]�[V�����Xo9�áI�jR,���"p�R����<�3�Y�ʚ[��q�ZjK���� [���/�0	=���I���#�'O�q[Ⱥ_Dյ���k�Z7OQiW��<?��F�!ZDaV�:��	�z�7��afDq]��s7�u�VDE"���,}��]_j���z�E� "�=��3jѿH1�xt�n��HZ���%����oPP����O�Z���XےN;�|?�,�������-��f��:3����1�K<�e� v�4��{��E�ǌ��ޢ�eBi�Q&.�)�l=�b�uA����Q<��1*�r�I�3�(���e��贫.��^�_ޘS�롺;�6չ�?�c`Fi�X���t\�f�uo���4����Hi �!!p=�x�-ߏ��뚵��/`�FP�9���uu�y�Ú��N"C�#M&�^Y�|U����i�){�|ۯ���F��x|c$�9m&�����4�4��
���Yᗂq��6��Kҡ(����\yi��=F,���93���޼ׅ��4���>��ռ)p���1P
|�v�ys�a�� �G���:p��y/7aIՇ�L�v;�^�|ٝ���vv��I��� ��֐��%]3~���s���Xb�p�/���_IA�E߿��+�A��N�$�""J�3N¶h�5��oc���*;=���-t�c(O�lwxÒ�f<o���5�
�^�JW� �Z�9]��������ͼ��p�|-�ki�S�L8�K%�ea���ؙD�����#'�ެ�@ٝ$ge�f�Q9S?�%�e!9m�g�m!֨���6i���y��`��7����F)ؘ'B`t_y�����xB@�g���H�I��m&��J�W�N[� �����sA�(l�uAW�?��#C0N!7�����}7�i��?����;���<t�]�#����u��<xI[|])ے)]�a`Gɇ�S������$�WB	��[��t���? �]|���V��n�X_{������93�$��4�<����8����y����f�"��I�]d��@�Jp����Hu�7.ә�.7tU_ kƭG��>oO�e��s���$WvH0��F�3/pjn�	ӕ��~^ ��x���{w]g����*����-O�`of? '1��/��2�a�)i�M�����*��(�G5=�����z��t����-�����}+SAxi�ŰSl'Z��i�n����?��S O:�a��V�_HQ2��M�N�A5 �!�RG�&�� �ȯ38�p����i�q`����s�����	�)FwF}5�_X۱)��Se~�f|�G��m*!����H�R� &��a���L/�+E�u��O?%&/��'��˗�]�'g�� ��������1aK\dTW+��`�x������&�[=�R����7��778]�b�䣱�¿�+U�����V�D�X�	U8gH�%�V`bN�}����S^����B��[<3>"�S�E��5���ʲ�W�yM�u�2��/t܄&��#�Ҫ��?���R��C��е�_,�Pz�Y�е����O��r �}B�9�1�
(����-���CV��(_�TD��O�*�PD�N���O{ -etv-�):�n�bcԘ��rDg��\���&�Wp+�Pu��}����8D��}H>w_�:}���{.	_�A1"q���A̡�ֳ�2苬�M����p���v  �5a�v��6����������=�ɏ�v�
�ew���i��hv���Y�������bisb �9:l8;��@���+�e;����i��;� ��ȵ}R��O�ʀ�r��K�`h�$:ˎ�ֽ#uG��5�ܾ~�}��#�c��^/�S �H�SUA�_�l��T~�+��czzZ��4cu¾vE{����%�4G<�i�&o:���gS5��q�S�0T���?����d��Ip��i41�	:O�@�M��I����l6Jw\8F&$1j���6�nle������z�g�,��"%e�A�����cY|��?�_#)R�&G��0f��eWj���l��t�c���?�WD�t�&���7���Q1g�A�D�1 ������i���ff%��'�M����
�FW:e��
��YFjڑI��n-}{f�̶��zō`_��1��.A<"��MY�����+�q}N>�hā\��j���r����Li,��O���(�5NT=x}(��{9��z�ڢ��}�:: ��%T�����ul���N2�����!7.��C�`�T���(QcN�d�&Ksz Õ׍NA���/y�������|�0}8.[�ƩkVY��D��Sᙪ!�� ���p1r��'ơ��(BQ�n����ZqtG��?�JP��{	~�Ta�(t��K�8����uG����g� ��qhB,{����s����;ӅP�j�io{u@Y��h ,}/�$p��3LY��į�أ+�R�]��ڧ���AE��� �
������
�4<��R���4f�e"�)="������H�W�.�����d��l�w�ybH��J1���5���o��BXTXV����! �~łޡ)b*]�������L:���D����j4���@৞���¨T�j}����v%U�2�������g�j�0�<:�Ap3�{���4]��H�J��	�<-��\,kC���O��Њ�9��6P=d袩��Ơ�4�!4C[�XW�� 'J�/}��)*���km��54�W���ђ��'���k���W��R�N����	5Bo(�1dԳ��En�G�7Ն����@1�|=�W��'j'��ˤ��wv}���]���a��'�Śzn�R��21�8��=(�H�-*��M 6��İ�.��Ο7�C���b�Îq�8�W_�9�1#��	 ���k��/��VE���i���8ּ���@��D�\��2��kkvC����
 c`gj/H}*Y�k��&/�&3�OW���S�R��q@l^�c�K�Ǧ���V��Y����'�p��?�7�b���O�3FB�4(���X|d��ì��J.�Ф1��gRQ90��K��!g*}����t��4�d�^GS�'�>T\(��oy,�?{��ѱFn�Y��i@o3t���x$*���a�̏���1iZtMB�h�p��v�KF�K����:h'a���JX��Ę�����g�Q
F�5�P7a�hmϫ&'p'p�e/��+/���_��xc]I����YtbD
'߀�M�X��4��_����D�F;�d�y����)'k-N���l4˥%X��0�8_��U�cy$j�o����gM�ҩ	Yw/��\��3���j�����e+Vr��Y؟�緷�?Ka|ew#a�cC꽣�m���]s٥�]���;T�V���D8HY�瓢|��&p�X������8v	&.��}K���A������͘�+���I%d;j�!�_u���у��01#m=��
Av3㷉%�R�afs�0�L2��v��@b�`kBt4�I5������6修m5	)3����ɒ���m�4�  �f@�*	L��d�s�Rƅ�f�_�K��K����K)���$#F�6�����T��gn�Xm�)�9̴2>��y�S
���D_��/�p�c�f��0�%���1��E"�[��L������8��v\����뿅���qGFBg�qz-1r��1C�v��\��?��+�y�e8��N���Z� t�����5X@���6T�����o�s9k˩|(��2������[�ZH\B�u�iP�H���/�*XFO�̛�9AGU�S	���u�h�ۣ�'��@��ޓ��ճf�Ҽ�����DIUC'�'{������գ��j�b��}�$�����c׻��%��8F�������'s�������|ټ�)�'�7y���Y��G�{-'�����$`��QSc0���5{��SP�ȳ�[[�-�A���-���&�z�~�|�6y�#����h���ʴڙ��b�3&�� 2�㗂4�O��EGA��S�ȯ4t����o���2\F���t˯��4��I����g�Ug�WO8�ݖB; _oZ�|;�N�D٠���=3k�	�;���|���꽒�j˕j��:�r�-�*��n��l���GtN������Lb��U������]��fU�\�	S�'0�m;<��c^`��O����j�9������**�������<��$� Ȩ��=ű
�o�ޚ�~	_��Ϸ ��9ڷ�4�h����	��0$���s3V;v�O��h�Pm��M�ϐ�5�w���i]�('��(��-D�{�C�}��%��t�Ɔ��o�k�-DW0�е>n_����'�&[݇��2�{�Y������н }��p �D:f/p@�OP�qX�'��-����qhY��^�w*F���/b���yt<�.c`����[g!�jJ�$>Ա�IT�#k2]�p{�p��:�J���3`�_��X�韄~1�U�F�3��L-�6�8��,Qm�����9/�dn��[06��n��z��j�.��F�
���������ea���27F)K�2�'7ޗ�ݒ��Mi����=��:3π#��!����c��2%!�i�ІF3
�4�>��H���I}�u�����������.QEw4G��pB�N/�W�%�)95'��*�]�z�r�Ȕ�����V �H#��z����J��va�)_2&k���7Ydn[˸�Y�v���u�Zuܵ:�%�'✈��U��SS,���%U-YWe%B�q�˸+�j�?�`�6���A���wT�[1g��jv��>�S�4yҒLT�!�7���� �c���tw΂G�d��Pº�߶-��d��ȏ̄+�'�M7�� �C���e�{D*��$��(1~�Jԋ*+����Rs�ժ�xL���� q�'Z��q�
Y�y-�˛��\�,y���t�����4���袕j$8c�Vc�K8T�g�r�C�/VK�`-�42�ˇDy��~������*���`�_fz�#�5�.�y�g�^22�\4��}�6�Z� ��?I�$�� &|������B�^���[���p�P��Lݗ\Wn;���*�"J2�=5�!Nđ��%�Z��s�(Ur�ƙ�U%J~��s�v]�}�v�U����ˤH�Vr��9_�U���<�õ��ݮ�*|3ܛ�-����/�C�0���,^tt�<��f ��j�`���9�:	�)1П�2����B�%x��S�<�tfPQQ�P���p@�:)3����p�a��@?_�U)°N(Xc$���l�T#�q<,]�TE�3���HP�g&H�~�6����nW����P��Sgc������ h�,wV"=t�x'�qJ0~S������o膔a"|^�g��fc%�,THq3�d'w3D�ܓj�Q�5We�i/�#w�i���<�����A�".���w!i��Y��%'���ܵB8m����i"6�eGW���W��d�b��'g�����n�g�b�Ƿ3b�Rp���Mwz[�:k���,��b���O=��4D{1gA�\2G���)~��z�Nu��x��oX\P�Y�Ͽ����4�W���z�6
��vx4�^� 
�"uk�u����F;G���^��ubi��i����?�ٮV	=� k�cVu�7���eal-͒�V,�d0����׏�C\kh�.����1���'s5 Yx<�4u��W�0x��EDB0�J:��kB�Z����K�����tK��uP \�	p��CL{����
dSv%��k��&�0h����1�Y���S	/4P|�l|r'��D�)�*+��M����1D0����\�8|4���+��	�]��
��>q��OJ��5X�Fڵd��²��+qKD"��=왇/�5?�~�&��H��|��0;���\�rGLpi�<�@��X�L9v�;�m[���۬AZ��ѕ���*�(���ڨ�-� �A'-m�e��Ҽ�>ua>�-��t`�Z�������A���Ӷ��s���3d�3�)y�Ս&P-�,4?�+x�-o�����z|�v�؊���AD81�����؍�C��G��[HhS�٠ՈqT��a�C�{��~�^y�ɄD�}���z5EB��v�fA�˸0
R��@j�K(�N��,�Ҋ�O���%%�5'w��=N�K6�	��g���ٜ�&����]�t�D�켪��6 ��b.?�v��[���>.Fx���Ô���b�d��L�?�����f#�=���[���h��k�G;-N���":%��c,+�Qm��[�O	�ݷ<�&l�ڨ���I-�1�;�J@@����,� ��\���{\(��F3�#�qӫ�4 Y�b/�s�؟�/��a��M�{�{��ggO!�5Q�$�����Xp5�N��Fհ�=i�H[��#L����k;��z�2�9qe�߂]{�C�]��k�f_�(�rĽ�3Ae"�إs���y�pG�%�,�6��ٌ��O>�Â1��*���}��^Cbt��?�C	ʎt,n�`E�o�'����z0=�OW�����m�˒��R`{�-~'�%߰=yNV+\����5���7w��zײ��[��L�߼�#_(���k%˰)�g0EV) O�$�-2�S�E#�#���>[��η��W�p�17o/�,kN��d�y�*ƽ:�g�z)4� H���d6��.I]KR����;4�E�g��w~_��I�~��(���C��G^N��Wu �t
��{4|�b9�Ҟt��R�o���n<�KhAy����!t����-|�
C��Ʀ_:�5RZ��-�4�A*�h�(BV�\�֯+"ͤ���������	_�Eg�F�9�y��i$|R�����%���V�^����
���m�V��K�6��R[΄�l���bM\��m���\�E��}N93-@-E�a������LJ D�qڻ�a��"��`�w|�y��. tѬ+VAQkT�������e�_���t�z'�僄Q�0M��=o�%ѩ���sU@S�T�;ԌeR�)6o�#�����3���)>6֩�m�.���9���Z�``�G �#f\�?.x]�L�Y��b�/��:C~�ߡ9�s�0�p%#��3*�Ky��a8߻iz��,��ty�5Q�z9� ���3[��5�;����)�'Y����_�q�K�e�,$%�!��y,9FOɠ�3�����'ޅ�v7����r>dxH��8uYg�hN}�.�?�x���0z[\��8�(��p�.\�"r0B�/��3C�:�"�� �`��|"n��y�-���W�d;�/�w�D�@8�����
�?��"~$�,(�V�L��y@�K��'a:WC,K5����L�����eE�]�Υ
��RekX�`�|B��$�� r*B-�����I��veJ�B�A�;B)�*�������w��lVKK���k@���#���X"��Y&i�ǐ6�hn��"":e�>���O(L�O0'�yJ~�\'�H��Je8o�J�P���w�k���o٠�ߖ5B�#�����T�tC_�,�A�٘��:Ժ��,�U�9��Ǿ�����
S�ⶺ��@^���梓�a�#杨9�݅><��d߈�Q�)4��PR$ĩ�pٿ4���@���B�$5\�.m�*��nq3x�U�E�
��5���:
�
��5�=U�4D��a��^)'��8_�M��ʄJЋ� _��k%����3VY�6����-] �Rz��|�I�Y��( �����a��
�w]-gj���Y|`��p�wąW_���细g��́�eT���c�!4�.�6�JM� Y�Y�������u������|k��̋EL�"eK�ֿ��.��K��=db�_`͍Ȉ��7k*zw��ƿ��ܩ��vZíIr>�Xd�$"�K���	��n�֭�`H�ކƳ��b�(`!�P�dK���r�6�M�/S�q��w�7]yq��ZN���&{����!UN�G�g���4h���E��r�������HT��q)��i`#ڷLt\�7��g��e�j��u�n����Q!�&�z�u�(3�".�&��pؤ�v��й��P��~��༒e�H���`�
���f2�����3W��dɈ�ili��ҵ��X^����0�8�jǅ��+�IXVV�.����k�a@U�b���㉳L&r�,���
�7��(����<Ν[������b�r�X��B;�����*�@��`��bN䄉�Gy�O���/z x�6����Q�x�Y��`�;9�[CȾC��?��x%W�9j�H���g]� w�  4)�f�v�,����p�*"�����fF����$�)O����5%����H�#�����^��Ƒ,շ�u�U���N�����w0��K�Y�;cI|��A
�%�VY�H���-,Ãm��5�_V�I��S'=�10[Lm�[0����o�9�c���1!ڊg�ތ��/ ;�!�����j��9װ�F�٦��D�ɭ�B�q��r��|B����*��p�-L4���Ӝ��;�'����iwC�mz�fai�����s��h�SCǁ�����1av�q9�w�p|�l����fD�ݘ��mԄ���c��}b�����G��W�f#�8��^��.L^W�M7t�6��c�is��A���0�e�%:��Ӧ�C#>��&iwx�A���1�D��ȥ�77ܾņ���Q�G�#�b����{.���H��OY��m�1�4w���5@m�e3� "V��b�]	5���V��ٳ-A���W}6'��Q����zX9b�I$�+3Yް�m�A���Zs���r��Y����ȷz��|p0���!�D�S0q�ꧻ�E���lc�	��1i���0̩S~�*��ߧ��;1���R��]B�O��E�[���2�zq�,T�K/�xO�U�]l��s:ڏk_�����i����=aY��>��2.��y���5_dE�1��
��LU|;�"E�rs��������,��nnb�A:,=�p�u��9���3�y7�_x-m`D��,4b�Цy����}���B���wը�Y^"}ݘ�	7=��b�%m�H�-7�	�fZ��*#�����N>�t*!�Y�����\7�@��,�c��1n)�a���m�yZ�ڣ����YΥ2�4����ތ�<1�A�
Jwb~2��x	@�򤠷eõ.Y�TE���Os�"����f��ht��D*7B����C��4dL?,��Z�zn-�w��"$-�Z%�I���H8#��,砙�'��6�����G,ʼz��D���6l[ЦP�f�$v�dC�ھs��~A?��Ġ���x��RsԾ���PW��g��ô�E�")�(!*��}�	��?(�552]u�����u^!��w���d���?�I�Ho�Eu���t�G�o(�P�?�n�$i{E�ҟ@��I�y߀!m�g�xd���`��C�5uޝ����K%mTJf\��}R�5���:�������J�Qb]�'�d�8Ӥƪ���J�9�|��"��>����r����z��$�x���ݳ+L@�ܿ�q�P�*�u;u~�L�>C��������M�0� 6��z��7qr�z���=(1��}��tz����}^1��C�w$F|�pQ�%d�i�"4�i@J$���@�kT�C����da���u��q�j�#��������y5ib9���w�L�Yt�HL�T@tTu>Nw��e�>�c�w�$�1zv����*�L;}�y@k]. �l�8:v:RP���Qn�J�A߻��=����}�W;��?����(�0&��'
������������ߵ8V]{��
��<�OO�e;tk�r��32�~*ys#����_���n�3�5�Sq��S1բ�!�өUAZ�?�f�\r����«��F��Q��H��k�/.�*�Bp�>�#�%cD��>[U���׌V��j����.1�$^aa�-���6��Xl �O{��H9�����m��O#��A���j��xY�g��o���Zv=֠�n_\*���b����ہ,�@��:���x�L-�E�V$d���vc���V�k���m?��c�zy�(�=:��]�P�[�b��^2�в�c�rl�6���Om(ne��Ŋ�Hi�Ui�ǞZ�7�]:Z��N�BB� �4���Kc��v� �J{��u@v3�`WQ��q�-���L�(��d�J-J�"�gƔ­4����5���\j�޹�Y��h{��@-���JXԠx�?	��פQ\as��r�a80*�Z��mnW �@�I�t��6/�h[.Ъ7��	܄:_aER%�O����Dh�(��}f$�@�<23�}Hn���?w��o�/4��o�n�J���*Щ��4xW������ק��vE��4�ZC|R��p��?B�?`�8�դ$��.պF^�����懣g�vfB6E�|�<�0����팘k�c�3�nTp) D�-��l�&G�O�z�u��*>�sٻ�qF[Bz�J���$�+ƻ�����C�6N�dT��Ѧ75�G�BV�O,�ѓ9/ȁ&]m� <�?T2�=$�$2�1�ȶQlK�w˜�c�����{��-bGv�O�ygj�{���\�cQ�A1E�?�X��O�%
�x�x�!���&s����vc��E����Ԍ��]K���&�F����؎�
�:r::P�T#��ݽ@d����g�;u�[s.`%��J���e��yb�u*�Q�
����7��i��驄�m��Xy
� k��j�OVe�^a�P��.g����`����k�� 䠼+5N����T�o������[o[��~x%K���&	���t����A����x��	����(�P ����(8l��d��O��߉Q'O������c�|������V��ix���B��)#}o1����ŏ��_$��8_��E�du����X{�]S���q���a��I��}z5_振	C�oG�_~��6��D�0y���Q�a�RP�M�(�痜�gr�E�׫ہiA�����Zt�N�4f���>(�3��c�e����]l����o�|���7��+�.T��"�$�Q�z* �	󤭊�E!��GX�3_��([�5�5���)f����7W�_ռ��"��Do:�9�鴽�C8d\�+���wX��;W1���r����ޱ� �I3F��t��TiO+�\���_����J/�P�W��:'�"��V�_�W<�f�ҠM痠���Zc?u��ȇ�js�H����� 'A,C2~���x���IJ�%�Vw�;��EQq��"�z�΂G̻�QZ*�\�U������K��&Ǎ�J����{����U��������S��W���Q#�����-��iiz�M�������G�H��*�Pވ��S}����tB�|X%�_-�������*��j��`������i�gv^'ڵ(w��Ҍ<c���v5I�o�c8"T'�����H$��j�6j&O�YdT'�����H��g��jF�؟2����E/��9�{�_��~�4VB�����o���6�Ż�����фH�d�KKn8�л�`-G�<���|-�<���Г=�h�ĳ��Y�s��-tOV�<�h�dշ�а��0Q|y89�0���oh�YR��YDdM��|x)�]3�Ȋ��� >����C������N�J�3~c}�2��f9���'��7
��Ɣ���*^��/6.4�9ǽ0�2��9�crV!6QX�Ыn4�]�c��w�nu�7�^�r��xQ�ex�D�*� @�'��:���|;���<G��|}���k\�<��p�Z��ΐ��U�4�F�u88����륁)��� ���d�w���Q��ٷp��D/IeHV'!����!����չ�?���0�z����csj�ME��_���ϲ��^�x��٩�ֻÃaC�C.� �_\F���c^tx�o�0�������2�EF|��D�NJ��v�K~�L~�*�f㮢	�Kf�;�m�zqP�W�����ȸŉ:	=�0�V��\�Ô�������圹�{}��Io��8:Hxw"L�����߰��g���-r�ȍ�0�V� ��R������U'��EWѝL����	�����V�{N��<I�q	��T�g��~Dk�X�R&�Q�[Z�Ȉ�0_=c��~>唍G�d%�}�{˻�r�b���+*h7��;��=�����E��;ҰSw2���"8���H\ӟ��l�b�w<��1Y3���~m(a֡oq$O���8�Wg��u張d^��!�q�7��b�e�JBt$
H(�R��2�?,�Tsp�����og4**�gP��W~��i�t2���k�d
eH���?t�r���8�(�}��HP�� ��C��5w�/b��2h�����X�R#�r���,�i6�����#S dB��/2VC�.R������q6�-������� ~���u�"���.��oi7mԤS(�L#�x��C�Y��$6�w*g�e;^z���w0�Om�2����yyx�אu�����R��v��\��)R"�Y�i�E���ɹ�����@r���!Sv��7T��� d|����#)-D����=iε����� Dגe�ے��2`g4_�g���$��Vo�]Z����R�*��	�4�U�.�`7;�/��Wn��N�T�A.!e>mܿ����gAfB:�s��s�>?��$�O``v����x��&��z����[u�=�WjM���*�
�I|��G��k�Ps9�*>{�@I�3�zW�Q�<.Yh ��en΀|��O
8&Y@�3!@\"���:����آ�_N�}3U,k��y�AnC���g $Nk���2!��ve=���f%�������9<$3�S��Dh]�~�F��2�օ����N�S������B �-�$|������Q��K0:h|�- ���_���բ�j {b�*'}��
�/I�������
|����c��Y�IC{~���8PPI�+���]��E�3�>&��p��B3{u����=	���?����"�οf�4g�t���R3�S!~�wx�/a�Rnr�Ȍ�e�\���t|��n J���}eo%(��N�\H'�8����E	��V��hD<���7�X�z�1�
�l親�{�I�    ��c�[L� ����f��|��g�    YZ