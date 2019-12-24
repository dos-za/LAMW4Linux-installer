#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1631288042"
MD5="87a268071591443fd4e8aa190ed7f30e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20356"
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
	echo Date of packaging: Tue Dec 24 15:15:26 -03 2019
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
�7zXZ  �ִF !   �X���OC] �}��JF���.���_j� {�`�C�緥���mS�H�ZH;����9���H9��Z���Ll����M�=\� �/�&� �QfY�<�+pD��&5�6�`��th;,��F��t�����Y�u�wR��*5)��>��l�yHB�ӪA;w[[��b����N��.`���j������NH֌N�jK�3��h�;t�������g���nW�a��Pc�VaS�'U��m�(�2vDA���q�b�"9'
P^O��P�[(
F��d��!tF�E���~�4���ђ�[���D�e�Qu����_8,\��d/�� 	|�ty8O�i�����V
ϋ��dFF����S<(+=Ιt�g���Vx!�iԆ������-\~l�CC<쀒agAl���Ӽ�?D�6��a^܋6�6�\[�%�S��ܖŠ�������9R�^������=�G�1(1ښz^#��f�g7s�_a(*��xhʪXZ2�6ag_�.5��-�51\���.��¿1���qY��
��6:�t�]rGl>%�ػ��N�g��1lx�ީl�J!�J%��I��-mpdT��c� =� ���d4���s��AgH�zrp�� ��)�Q�Ռ9l.i�W���d�}7��!enУm$J-�F� �!��>��nӛR�kj�[��c����'��c�7��f���;EN��t��_l��I���`�����Gn�;?��Q��ZrdH?ϖj��B
��eRo�&8=�.� ����#d��*;6�5��ފ��k��v��B#{�o�<Y�`��b����z���O�yG�.%��Rj/�2���ә����X����+s�w��n��i}��Z1ᬃ`�� �<8�7�	k����H}p�X�b�3H��֥Ɠ���^9,�0�eOX��=�������@��%�
|�>FtL`+�/bb��	�C`S~�^��4��R2l�>�&u-���I0U|&�z�=�#v�|[�q�h��\z�?�6�x
���m���ޮԇ�n��@��IFCE�ܸ��Ngۅsb��x�xM[n��ؘ
6���j���rJl*�15<�{��� �;K�*<��_hȺ��´&��L)F�]�uJL�Q7�ԓg���C�A�#�y��&e"yZ�P��\��y5��:�ʜP�J���	��\ᙋ(���Z����N�hX>���G�?_�����=ꂟw��~!����S;3��U��x���w�T�"[ysj�����O��`�k:6 t�2�@Н�zeb����(�	��9�W���=E����U|-4��ŉ����Ă�~q���LH]kg�������WZ��F�fUa�u����6�Іp-r���f_s/(c 7��ྐྵ\
4ig0�_�x̾Џ���X<��@	9��6-���Z"E`V0t%b<!l�Ҩ�@�O�#�Yt�P�{D�a�Op%�ʳ�m]v�%:y������"S˯?�zJ��P�<�H���S�ԸMNl�x�!!�/={��P��P���Dʲ��%93�|:�K";E�*7s@����8X�첚�v!Uop'������;�>����V�#��r�sS���K����Z��/����2hW uLĩ���ty�c�����F͛T��KPC�}��H(�xSF�ws�[vM�B!/�e7?@�e��!�ͻ�z.��PI�/��O����]W�.���8�+Q�g����~R{����j��L��<eFn�9����8�,��CX��^20&�p��� D[X��R	d��:nrY��z�ʮ)��f�˓�|,���ġ��ƔHU�?"�$�:u
�X6"�����m�{�a���Ƭߑ2.�Vu>�$�8|ʲ��v�Vo����0T�hP���H���O�pkGy�G���@ vO�|Ԍ����<L�=r�iV �����f������w:�Ϻ]�bн�}��s1r9<��I��ힹV+m����H���LH�Q�e����\X3kcNa�e\�|�x�]�t�{�Vڪ'Np�a*|��e�1�0��]����JԆ����IW��1��<�oٰ�w8J��{��Ȝ4�;�$j�@�n���f�g|QN�(���f#?�H�����LM�(<ڪxҲ@����"���byG mm ��:����oؓ?�����:JS�����{_�h�e#�����5l"zk�.w���;Q�g2��5#i�w�p�5i��F��PQm��]2B��x��(«o��y�5�u���-A�˖H=��U��Ɉ�6Zg�6l ��gN��t��u�T:��~�x��398�P��2�g��El��6�G��K�NN���Z�I��#L���l��*�	x��Y+J���|�h �?!q~���	���<�?�,dk=���xT���j^0A|&���.!m�%"�3�}͒	D�0��p�ܻVd����&̧*C�q�<g��1W���m������+�u�B������i.u����(äյ���쭡!m��sQ!�K�] ���]�4i_�7�~����ƈXA�)���嘊�ˣ���k��#�[�,Y��m��5�_<.�(���x��~F��4U5��q~��?!��?t��ԥD@�߄��H�����b�F�����j5�~�E���g������08�,��8|��=���䬈�;K��;
��H�U$^�8D!��	�������u0F�����\��5q�s��nsГ�ƍX�~�n��v��<��0�R����"����Z��5�P�q&��%�>m?5:�+���k�\���ԏ��e��2�"���#SG�=�M��i�γ@��w ���f�	,����<�2��"�ų/��z��myIT�/�H�3�za�&����{���Kɠ�%����Q�/!�T�hTpψ��� �,�dc�94��'��5��"��y՜�2ɤJz�r\3+�pǸ�ݶu�����R�/"_ _+�?x�b2�>"n���}�_�pc;���F�E�Ӈ&@6}z`����5���]����C��V�����	Q��3g�S��9�e�����屳��\'»���92& ��� �����H��f�����U�h@�k�� NN��Q��%b�����8̰��e݅�� �̱ �q�L��ݰ�pȘ�L^]_V�=Z��/�*b!|j)��hd���@ۨ��Pk��ݦ�,<��Ơ2 �P����!�$�E�`D�D���(�vK"l<,�����_�҄=����NɵM5g8���b%{�o���(W̘��:_��oX��`݁'��0Rsv�us����IU�F���<O��\ҠF,ڱp���).�}�>�D��������B�j��g�������¯^�T����yHC<%�4̏���(�xP݃�tc�5c���5Q�	I�y�>�\�e}S����%<��� ��=훛<��Q'@I<�w!C��/(ѣ�آ���s��N��{its�� �t�h��]���~�i�w�-�8�n]��3\{��"����cL�j�1^����q�̕��+#S;��7K[�۹�c��P��\s8"��c���b��c�/)=ǕyLʛy��1��Q��7�,�39}���`
\��!��I���yY�mM������{?y-� �^yn�?>R!���?YH@&���.��ڦ�//x�p8gup�`:*$(�� �O������[���1� ��5-���d,@�����]%I��l�f�^���t�Ž��zr��.��g�ZR�Ғ b�s��yC52�N�ì/��Z��q�(��eMh>����.>ϫ�׻v0�(��A��¶����mQTБ��� 1�(�B��떇�O@�j��pB"����סM�zTq˦|i<]�&z��%4�x�Ǒ�my�2��+��\�m8-��&@�������-����[�|���ɨ�6�*\a`��| r��D=��B�$�P���"���̼T
xPh@�x�KN�縡��$��p���c�� �&�C��㠯a!0��=9�uxze^�gZ�P�w�1�������d`���p}���X6X��1�WF��'��-oʿ��F��b&90�R�w���� ���i��I�P��2|���m_�CɅ͑�6e$~icw�@��>���;5L`����F<��D���F#^��%��j���%S=ي��:&	-�ou��ԇQ�su���aJ�I�����<�����_�Y�u1���7�&�l~�"��fg�k-հ�;�׉c�?lL�I�=eN ���
�W~�Df�ex6+X㲌(5�y�,qB� �ju� ����9�k\�	���q�"`� }jm^*�����s=N<x2���l�D7�ᒑ)�qc[�G�u�RY�ہ�ۆ�ɪ�����p��(a�)Ȯ�ov����l�7n�CP�s$S<��Ip(��̘P��T�-����\�l�ٺ~7w54lޔ���C�['���Ȕ��hM�sܟ���-9"_dVT��^;�,>��J���r�i�a֪��L�
c���
Q�J��'
�wO�l�DN�ԇ1���	�p����]�:HI�����#�V���NÉ����p:������p��lW�t0ㇾ,�ٵ�F�F�Ϝ�~U������]�|nK	�ͺ���� L̇��ur,����:�͎'"��ɾ�i��E��.��w��M3�k�"��
)���uV�xCN0խ��j��eIn���q)�W���Ҋ�� �^��[���?���lC3���4)o�>���6�<R ��읞���F*ʯ����Ð	j���+�U�(��	VgW2�jG��4^�ɥ�®�����J����䚿U���P3�˖���,�|�O��a�xЅ��ǁ6>I�/��
���oOI����rgQ��jl��cl�=?�O���.�hd/c����^������n}�}:��%� CW�����:A,wH��x�ҧ���7��Oh'^�)���쓣Zm���Y�Q�� ��2�T�g�B�] wf�_�E�D��1߉�"�4C?�|��Y���7eY������d1����+�Ne3�fl��>�w����/��6�B�ӎB��@�&�쪰穜��A[�d���Aa��a����1�=���%tvaP"����܁����3�_�&������9`)��V���lv_�uy�[$haw��/=S	�GM9n����K��ϛ���D�~(ˡ,/,��2��^�9Q��K�TT��'@��,-MW���ߨʊ,�&Q�wl5"����p�V(���`ЛG�>���XT� 9Ҡ�|@�e�"���� �/T��m�MZӜ����c�Uv�=
Ǥ�[
i1��/˱�UxH�[[	a�lD%)w���?zx�Ο��)N},�Òo�坜H�|{��C�)KMp�)Σ��-2/<���D�.L�uD&��o��$�Ϯ:��Dۜ�n� *f?�g��)brt!���A>�3��9�{];�.c�"��m�s����Q���c|IK*��Gڙ޾����.g2?U�I�a��`���MO�6W�Y�G,��>�y����2�}'f�����m�.E�-YSm�=���]
�U2|��E��\ �<CB=h�R�dt����bޠ���/����mh�oTj��9�h�������r]��u	\���({:3��׆o�*��7��n�����@?Ї�� �@�/��Y���gNL���-T�ՊCc�<JC�n�u�	���M�2�yq��Ui.�ޜ�"�P�<��-3�%t��T��a��`����fw®�ۀV4�Y�2�<��]p�ȃ�n�ƫ\����T��Eh%����R1]ێ̪�P�|��8�,��j�0£��N�tN�~�F�G� �.����3��v$��/��A�`��T�#ͽ���hê�Ѡ��!���KbM)��W��pEbq���C�$�I_v%�Z^t�ܛ.�G����O%��;�x���Z��
�q�('$���ǁt0�G_yc��1�`�9l@xeiC�(���"g;�R��:���wn8��m���4_e�<�i���c�R���kl�-��ͩyP���D�kz�)��N��S^�AMj>����UY�c;�^^[&z� � �7$L�Ey{�B�=��O�Edt\��e��@�^�G#8q�$shNLm����<%�'Vqw���7�
�:��%�1����f�z����f��3����Oʧ��fu� ��	���
@�;���>�g��;�Upc�kb0FiV�c���t��`��Y���J7S ��m;�-�����һg8�O�I#��T���L��:9
�!�]f�uK����qt�����˽�ml�Dz��_��ˉBû��*_�ܨ5�f�ĝ�,���������f�0�)!Ij�A�{�����~Y���+V�=E��4�2W}c��2�nH��o�3�x���g�_��!E�K����J�����V�G�L�eW;�H��;Ǉ�?y?b �D�D9���o>��;,íZ��錦Ir�[��(B��ԁx+Кb虚��`�Cr��5��}�������WEI����d��FK�!�&3�c�cS����� ��l�.�w�xC-���������ĥ�V�.Y�Qa��]5�.��N�|+EQy��
*	�M81Ձ<Q��$UDx��p��5e��j~�I2"���n5s+�9�C�����O���:ZNy��ìRexzq����G�%{{:%�FmG,f'�l�͹��+���I�Vb�IE��"��U�f4�#�ζ�[���T�fQE(�fEX�E\Pp	g��}X�̒�D� ���.t8�U4A��X��!�2��iC)S�Ջa�T��N�u�����1�F4��k`���<ޞ�OVp��az*��hlEVR�	��"��$W���j6n�:�Ϙ�2���h��u^�u�q�x�wb��}�n�|0(%��+
 �����k���]\��Z����b�h.Bջ��thO��w��l+V7��A�4t6՛�N� g���aU^��C�&)J�����{]��t���i��!1:t�؈K�S揽Mk�'��t��t�r{6֋�D 5ӵ"]K�ǐy�
�yő��; �Ƶ�{S�^T{�����oxQ�lJ��T���{^��IQ����4�5Y}�8�p��0X����Y��U���?����]���
�6[���Ͱw�Y2�ĥ�ﳝ}�)mg�os��Dʾ+��������S4��~�'LrR��d	�)�as!��OUt�c7�l+�3�|*'�$���v3���O7pzF�M�	&�[�†^ �W�Me��mx�S��(�u�?`�ԫ�j��]�?O,;f�0�3Oa��l���A�fF�K)���bzK��K?� ��V,E�I)�c�*��l��M8j�:�	g�G��ϵ�6T��Ҹ\���q�N�%S�w]�R�RQ����6�}E�se�Kd�@�r�hA�l)�����6�yܗp��Uo��)��!]�Qz�5��yŭE2ʠ��7��c�k���"! ��:���`h������0��xQr��D�ZQq�C\n�@P��yA�˃WC��N���=�\S��f����� x�࿵��^(�Y!�?0d'"W����\�V�@��H��A����MAn�<�dɃ�1��Z2��\��QՂ��Pf1eA}�'��#���2LSe�c�Y����~7͆��l}�{�)t�5��?S��N�U��G���J������~(!A�v���o�������I�Dm 4��mm9mz�ӌMr,W+�����-1��c�t��%F��J�#��w��xX�w�oK��Nv߰2H�l�0��N��UK}j�ۣ�Rk��[m�-���-��=˛O(�$����eV�,��U�m^�<�*B�j%��hL���>�qӜ��V�J�A����k�'��G�GB�ؔ,��奚�[��M_y�ԋ�h5��¶\�u1������i�v���fb�n��pϖ($7�p���Cdn���u��F2��v�Y�c�E�'��"Ȇ(���*G�7S��z7�E���˹z;�t�ܻ)'��R+�p�"�����s4J!H��B6�BX �P;�=�K`�=�s�M�m��{,��,(���W� =@���E*F�n
�;�u�Z"�h4��e����XaZ��/��*����.�\y8�����͈��7�"עg�c�Ɇ����%Js�m�(��k@�#���W���J8nd.U�H@贿L���"��yX���)i[	0�:5��;�@s%MV(�ŮPp�a~�uȱ)M�G5Kd�&z���
��<��_]���㙇��7U�e�K]!(l��G����pM$eOpcO�C�#Q������΋}5�M�HU�6��R:i,T�qʗ�v��Y���r�[l���'Z+@��Z'��<z!)�& �+��^np��ųWҧ�8��(t����_ʰ�K6V��Lc�=�OB�+�t��!�hgp8�Z�C����<�Ê)ۚ@�`�|ʬ�I�F�v��
�>mF~�+4��E/������S�s�E��2��v�T�H(Zk?�3Gn�_������-��v�>���2��ҕZp)g�c��
�E�F�o/�4�G��R�#� �.��5?�z��z��H�;�|���̘Y���н�sz�~hs�q��� '1�!��u�������'���)�6Ơ[&�*6������8�j5ǚrN�CBt�����"�X�K��)�z�X;���'�����ϴb_FL�Se�h�,N�ֱ�ӏ�©^�8�-"�[ﮒ�[ffa�C�2�$�`^�� �6\�՛��~ �_�x�~s5����1�R��#e�â��8r��@"�Q����Q= ˋ�j�։c�t�˲N'r�r=\�l�����*A�^���N��?^@�,���^��);�Ż��`�z���N�yʟ�a��ҝ5f�;7Hx�m��:�OGc��� �}~zpu �dJ�Z��IJ�"��m���Կ���p-_�Z��3�
�h$�_�[���l0�̼P����L9�P�$��v��H _~��<��y[�ݘ��	��tr�de����5�|˼�3ҳ�V�8+���e��L�!>t�b(�j�v:[Q���_Q�ĩ��\!l~.�HCU�C)4}��.G�!,SJA��7�X��	kl�OZ�fT*TH��.?tR
��6�#��sԡjw͂^���,����:^y{��:��<;��@ Sks�E�>*"�;	���'��p�;��{?�����^?��}�~.�n�sN���@�8�_��b���sŦ@�>�h��1?>��q2�0]	�Y��?�o1��̔����H�B�Mv�}.S���T�&����]~�#S{i T"�Ψ��)��>��i�oiq�-�̟S]@�QK�M
i7U@ǚQ��o��V\ښ`�
�
"�jw�ۣ@[�衴�=S~�4J�W�B�ݠ��j1W5�!1��P۟���Y���{��M˧�L� �=Z3�p}wܱ>�����W=�`m���7�ԦΕӧx�n_a�o�L�ڝG�6=�B���Uw�ΐ}��K3�
�`�lo� �Ӥ9[ql����:6cK5�EA�w�}B�,86dz�(�Wa* �����n\
�9�͸;��!U���7�k�є��d>3������B��AeF�A@��q x��^��z��y��7�W�D��Y�T!�}���M j����w��]ќw^�ZNHI6��`����X��D���ϐ��@��_�ȦX4!?���S�"1]�͕J�?Š�O$��zz�|�~]���8�K�p,�I�\���L-VըFz43 �5��}uM��o��뭻��`Rcf�������>���{����U�A��^�Ҋ�U��P<1R�A��H��.5@:��
���ǌxH���Su�w�@$�р/g�����)8�Q]i�F�2��F|9��RCl`�����D�um��L\]F�m91�..�t3����"A��Htk%�b�E����>N{0��'�F���|4V����Ǌ�����oI?���w�f|��,͹c۰���
���X����H�ObU%�o�Z&S.h��t�a��EL����=��/��L��EA.f9��"�a0�U
 cwE�O~w��;�ڤ�4͎H0�_V �%oV������$�	Ť`�TK�+q�����+e@2r2��;���c��.Ņ)yF-�q����!!+ڗ��I���S>½ ��'��-m��>vG��ޘ��g�������D� 7>a��?�J�w�	@KGex",����j��$�.1m�NI�x�\4����t�㋌AU̩@|v����%�R�f�S�QVߤ�mn��-�&��|�h5>��%����s�u����=�oԫ�4��)��h�oW�7��H"@g钔SP��N%4+��������9�>�a����J�fI�VsHoxN-�Hg��(.��,��#��|�z�<�"���O�6S.i7e`�v��D �MP��A{�h[";b��r���r�b$[V�&�Pnc�0��"#�}��5jg�B�|�5�;��&Nh�k�K\�1����;���k�x�t>�G<�̪fl��I�%���!�`v�:��;�aP�j��(3}9	����/χ�ɻ5<���-~�S<r�	�{�:�������p�j������7j{�!�(����VZ�y�.���N2n|���v�0W\�Z����D��O���pq�OC�T^&vEt��8����-��x�c�h0�rod�P�>����d��sp��
t�B�'Ha���t�W�r�-K0����Ce�O�k×��Λ�1���.e�b<�ʵD����}q:tg�o�h��+�p52j���:l�������\��˕$v�mMe��eruW��0яEa<"�`�����nYgc��	3�SߗWT�ECǅ�tŮ+4�
h��z2!fWr�RLp�8"�C�o�z�I�9�~�����ީ٨��
A���l�������3u���t����_��oገ3ٺ$A²�ׄ>�K,�$�5�	������إy��Q3���ܰL�#�m���%�c�ojlf{���+2��>U�́�$R}/�uD������W�����b���H�So��IRH�vy�jJ|.�u���Z���K�u�w��Ŵ-&��r�dz��i�w���+�;JP��La�֡���9M�d�[@YC.���3��xz}����e@���@����ᤸ��ᐯG����X����d̤T�x��1c��,��c���ڈ�}x�G
��smHi�2Y��8|����I�;���C�{y��H���C��Ӎ���yS�N��h��t�S"~@�$)���n��~��SK��y���, ����R�W�57����f厀��Fy\��=�厜��6Ȭ����`wVC�II1|٠��� 5���ܰ'�nQ5��-�;�H��6Қ�UM^<\ml����{�ˌV�%�,�g���:� �$�@�����L2Ew�q��~�m�/��،"yh~f����f�Ñ�yɵ���-�3#��V�f��V���p���崾�d%��)Kȩ��g}T��VK�"��۶-H0�@dw^mSi?���l�"�p_:o�F���j���w�0L�2o--G�Ď�}@5������~�M��8=*��L �p�����W���Ҙ;�^n�d�v-X�%�&}j�E�+�4���n����:>j��l䃾Q]�g��#���VB�SǄ�2��.� ^ѿ̷7���yJ�z��Ō]�r��@L��B��P�"c�����ן~r�#a�Y�@��m�K)���-���#�K�[G�Ix�z��0�����M�9��۟�B⑿�b$�����u��AUW6�!�h~ؚ��#��>�,�FJ{~)PI��5`; �����BI�&��d���'w�5�Y(F���)����~Nt�^��^X��:���@����a����ׂ��N�ӈWq�ŷ-�h����x/�V����,��;�	�w�����:�"�PN9Z��v��)��z�s����mCa��RP*l!�M��9���"]���݌��@]�*($��RJg�qsrV��kT��� {�P�,��/���k�ml�B��������薝�a��/�;��x�]�y�����G���&�(�x"��]�L���r�f[J�/��H<}|�@�5:O�D{���g���o"}��@�>�0�0a�d������*�R�)�Q�m�!�V'>k�TZ̝��G�dXBb(�Z��'V�!=D�_J8nq�DMYUҵ�o�����	��X�Q>�yl+S\G�!/�P�n�bo��z:��39.��%�����N�h	��=���jc�P�%wNA&V'�A�Nl����7ROH�g�&ӱ8�Tj���w)e��Z@dh��gD6�T��]��%����aeє�E��j���X�̆��ץA��Ӕ��C��B �����WC�Ϧ�~��P�2�]m��	ӽ��l	ޗ��-\h�A����<G����Q����C�ċV��/�2������H$����-s�a��;s�%$=P�k��B�y,�!1%�/�tJj3,sfL@����<EE��I���"��rf0q�	�S�[���%�2�}l�T=���	��D4�:�-OVܸK2�+[���r<6@�6�������z����.C�vP�l#�q ���_R�Y�9$�i�ջ���^ˋu؍��B��t���D���P]�A�+._���y�:�pY� �
�{���	x�Z�6$3���|l��ғĊujAt��z9���r�5<�p ��[�� ���L��SC�����y&��cɷG��"P�C�Uzg3��ׂ�B�_���E_�#�n�!���ɯi-�'����`��ϳ�-��/���YҢ$�^����#�)��D�yտ��A&'����Ps�=N[.¾h���f��C/��b�cTg畿���Ѓ����5�.�}ri�Y	 ��+i����`���h)�� ~c?a�*�>��v_7[��u]�4�j)��cH]�#ϑ(	���h�f��\ϡ��cX:ǁM�qrz�(� �+�'*{�����<&�Ug�z���V��{�!ό�+I�T,@��r `���Ǹ�$%�%ěX�)D�����{�^�z�<�F��`��6'�tHv\h�#�)��1;~62�˕]�x��CRR��n?�4�I�)\0D�cH�q�c��G��(�p���(�'���j�cZ����]����-�?v	�ِRQ��͊�]����Kv�1�Z���(�TD��x��U<�I�{�����藀�� �/�%l5;��ə(]ry��-+9��H[�K.n" �]2�آ<>k�f�'��ϱd��cj�U�ɾa�k�;E�h�$��!i�1ǕI��獺.��=�	���]�V�g:�Zd�����4;�fy,��F���<%�<W���A{i�}$\�ץc���%��:�IG�6���� RD�,�1 �=Q^���;��k�`��AQV�X�{��h��LX��F��i.�>�??��C�_ʍ��ã>xL� ��4 Sf��e9߆X�F�$j�ІӹIg���@��/�B�!y*%q�|�j"�$ Z���J��\������X�\9���D��x�/!�S5�qNE�u�^�tN��l�a*�����%f:��&��]I�x��r�*]~>w���U�w�4蹐��a��T�*Tҫl�խ�"T�#Lt>1�xӤ��ɺki�q���%�i��g)fC���m�}Y��|Z�	�L��:#�u=
D����6=s��Ξ�Yeʧ���P��'�@'#�2Tě�w�y�"C	��KF_� B޻~Zt��p5�?$Si�0��N�4�޷
gK�L��'�R�#�P�>��5�1 X�TF����ʤ�����\�Y����]�p�hV�G<)k:u��Ҋ�D4��ⷩ�����J}�@7�L�����N�Q�XԎ�荓�b\���@v�Z�
ҟ�;jVE]"�.� +[Erd[@���W�!�Έ�I=�rv�N��4�1�[���<�_A��>��C���̮��Dk��P��Jq�O@p8����X�P��e�i�x�E�/�����������H2�J�b_*��&�n������*��#g�
d����Y��=?*��d���c�vF]��`�@�m{�dL�z�.�G�J�v�yu��$A@8�8��6��|"�MH�p�Տ&ȍ+��I����Н�^f�oJmrB�	�9�.����"2L��#�_%ҙ"pK�t�_cJ
���q�_��8����(9�n�����0Z�@�N�A��5����E�� ɬ��N+S�j&#��UJ���-�����o/����*Ώ��I�VߪT���S���:�)r�U�nV�������C�ʐ�.&b�J}�X�Ԏb��18ʙ��2�y�͇�{��D��ڷ,6��Ͽ6CMM[�֬�u������".E�n
�V�6'ѐQEY�+ԗ<s��:��WS�6��W�w%�CU�<[��{g����H��
4���6�Z�TS1�7?��~����NVyu,���x��t��R�rg�����U�=p0�\2 $����ׯ~'�3�pzЕ��껱~v��͟�9p;KG�<�z�"d�S���cxBd������j��6�cJS_*ޠfv��Uo���Wd�W�o��)U8IrX ԯ\��/��~#l�Ip��a�����x�5;�'ѻ��#g�Ĝ�G5�Bi0�u�+���5xԎ;�p�q�^i���\t#�P��[(������G�#)x(����p]�[�����~��Hf��f��4=�4�S�-�vl�F�����#n��y!���8��;�a&��[���9t\~ӺC&�n><�<�Lڸ٦�5c����A���e,8F �,,N����L�5���'y��ہ�V �p�`�&���ۓ�iy9J����/y�K����&б�L�B����B}�{�?Ң<ݤ٪Z����xrW-Uo����5<i�_��P����"Ϙ�B���5a�L9�:`��;Y�\)�5o��?�S����r�E�77�r#�#U ��ck-l�r����f����#ɲ ����O$V�#�&������
�C�p�*ħBە�q�X�2��N��H��ԳC���%x�����^y��i����d���\j��o��+�+8q4,j�x�;\􋅟����q�Ԩb��iډ��{��J�*D�*���piwG�5+�#o�:2�o�s�����!���ҡI>��l�yS'���۩�dZ�W|"5����r�{��& Ns�ՑY ��� �nd'	��O��q��g�m��
-�.�7zYg�5Õ�K5���.�9EA��M�+g�`m��a��J��5���Nb��H�b̈k���W��Yن������*��~���:�j����|��߂s�����?qO�P]������:R���Gg����LYo����?0�.���4��d����hF��O�ఢ=���O�z�v�n�] Fb�԰y�����p/���J���X�iU$J�6�:X�_	��f����Є�#��=s���A[���o=g�(��q�w� ϧF��m�%� ��lzK<�����艞��+ϵ��{��i,��O�K��p@y��V)oK�Y@�\�����f� 8ff�ۥ_8�ؒ���PEq��L0�R-�	@H	�i�� �ca^��z�Ob���>4��~��XBD]��Y�/!X
CJ~Ŏ����}?Q���}`��'oy�]0���s�}�d�I�֕���F�H��^Ӭ��*W�Nvz��ud���� ���#�i�Nӂ�G5-<�"�ˏ*�0V ~�\p�P�@֡V����d$�z���(�[����8�}D��t[T�k�<k�@���u�ÿ���\r��_4���C 
�Ϫ���,Ȋt H��WR)2k��Z�H�K���b{7�=��<�uV��5K�od���'"gm<>5���{�ks{TM��*]�Ħ�^����m��Fآd����,�'8vl���6q���7��)�AD�s��:���u�����Z�䴅��C��'�Pq4�	�S��Fu�>n �u@��1����v��K0�2������(��]h�Q|�Sy�O�������1�[�~�	d/øk�#(�R�x�"��UO�����)����qS���U�Y�'�1짂	�YvE�����7��z�lE����C9N�1P����t��+���$篬AF9�%�0}����tG��V� w&�n|Xk���p�y�#>TP�E��r�,5O�+�N�[��$Òl�4>G<3��C�Γ�T~k(Z k�n~4Cj��	0���A�.�x���dɩB��fW�0�G�.J��\P�3�c�K�+���k�����C\�r�/M)8�st✑@��ۗ�6���ڧV
Bs�3͛ �*�JL�X��L=c���*������0+��4�Fх-]0�N��Œ��wa�jO輖?7�F�>?9T�s"���O�}M035��&a�� ��)���c(��g"����ʲ���0h�ZĦ���݁cRe;SCcE=�W�Pm{�h��':�9+A�����ܱ��':T9���F�Ԉ1W�+W��?�`u�g�H�#���P:Z�^��	jn8D��1�~��6Mށ8��vt	��OC��ۖ�:o�T��� &��׵�P�e� *ȽgU֫�t8�l������zː��%ߔ0�U��9)9#�v=}k9T{���:����f��p���Y�Z��,O��V���JU��{������3���.�Be'N��c�5����V�u�BiZ}�6N���kZ>	�Pz��[�;Rjp+ޓ���z�ғ���tA�>�eg��=P�I8Θ1�S�����L��A����#�}k�mc��w��O�����&Zn�� �L
]����@�*���Rc�����Sk��d���.���A.)ϵ�<���/�uk�9sCq��������R0�e w�-
jx��̙n)�u+ץ�K�K��'��ݳQTՌ��<��;���,@=9��/�g{؂J���3��Ǣ��-�êM�5z�"�t�1G*1�t��Dn~9��.2<�c�v8Q� h� ;��T`(��ci�3�����U����1AH�x��J��1`��v��R*�^��-����ͩ�<�}�\@�Ma��'�.SU}Ơ�=٫�%mdgLk�1�u�{7HA+�c���b�?��/@��)D�%tA��Z�{��Wa�2�����8��F�#�C��9+cx��a5�I܋����[�/t���c���̵�;�1��>�^��7XES����QVǈ0Ε�Hw����%$���֍��|��w��k���G H=�Ŧ��%���]�TD���?���B���/�(�-Ⱦ�F��V��V'�tT��,��B2��mF?� �P�!�����L�U�'�{�C��iF+�22���rq��/a��ԏ��Fh�k=���A
�͆�R?�6b`V��#4	�Pǜ��Mg�܊��¦5�(���lɘ5�#�bw��[.6�{(���+����<�uOHVĵT�8F�F⏗�������&_���ζ�60��Zµ��EZ�x%�b
�M�E�Y���Qܝ��=���d���ӳ����(rPv�DDxG2�s�[|���'�<b���`G�֛j�3u2)�ݦ\1�����ʋd��k�ɤ9i�����`���V�˞9*����a�V��v����۟�Ӊ�gBi�]a�r��B|#�/��Ѣ)ǒ�0�H�u�z���������Mj�(J�.�����2�ӅAå3f�S��@�X��V��9���i k�XԅC�Y�xz77��H��j��Ÿ�ed�pJa��|����Bt�c�^T'��j�L��G��-S}[KH�?>�I����L9`�-�:3w�`�ך��)��r��u��B�r�v� 	v#-��<��#\���Y2�7���TLŇ��Fg��$��0���"]��6L����[�%�6#vx,��ME��P�EO(7�uE d�f��~�b3IvNo��`���F`���ڸ���:�H?0?�٢ ���ͮFv&r��dP�D����� $Zԕ�i�3�"���R=�ҿg�֋Oe��8SM��K%�KI�(����j}�w�,��Ų��KgF�y/��yt����1|h݀.'�;c.U� y`k\E͑Z{5��M�}�/��Ĳ�ȐI��ٴ$*�"ۥb�:`��⊰'+y�~8� wX�������3��|wd��BH��r?�t�^
��d�.�:{�l�Ӕ�p�8���X|_�Ֆ��x�s�m��;���Ã�����2_~���.��+�-�L�+-�W	5�N�Y�/d�+�Ў��Y��n��!��Q~�O,U�jV���[Z����������Ǟ�9<K{R�ޞ��m0�	�r�4��5�h˾`w��4�n�A�z��8|�
'd�;ɉ`	���覓es�7�Pp,���g��mb�,���> ک�adچ���~8��!7�ge
�����FV�c}���f�Q^U��!]_쥖���ʀ��h�ȩ˄c_��A[O1ѕnަHɄ��M����p���oAMz�x����	�GG�:~���e��zI�7S���L���$rO
���1́�8U��Fp��+�4<�Ժ�J�[;PG�8G��#��p+p��i0l}����0�|�V��k���v����x`{����X��w�}sob��瑂g��_i��!J�Ր���� U\��:+�**��2T��2�c3N�Eh�r�[n���G�Fzc�=B�u�����_��6�r����E�קve�?@�?t݋:{��/f��b������ ��0��ިS&}J�ĝʃR���E.ث=�ns�dzD2ed��}H�4(�Rd�1�@��߿�W؞�]���L�)�6H7��6� �s�qh��f	��X	�R_�TJ�Vֶ\$LO�Iy����4 ��O��3�l-Ii��Yr�1�JHٴp����P��P�CC�/�j����րx��URu�b`p�ײ�ϭ�,�x�3φ�5�̷����p�Il�Y9;�=��=pؓ{`5��W�o��DU�4C0����,;��t�cy:�K��������T6�>�$�����,��hҚX ��Hdz�D���K�b#�aso|�
-5��I'���#���%X}iQ�`���Dc��u�g	����XX�����.v�
�
1ͭ7p����[��>��������f ���p���:oÄTX��OJ̎["#{�P���e�J�!pU]�����8YR�qK=gfV�Ʋ����ݴ���O��Ŕ������~X���5
�ݫt?R�3!D�`T�7\��r-��x�S�݀��&�=�k�/#^�e����d3u�F������9�j�����3�>U̯�WG��D=����p)Sڗ7���%l-��Z����.e�-f5ɹ����d����!�֛ �7��,��+��AW���Da�.^B3^0R>#���~@�i�����|ʯۺ[���A^���p}���A��F�蚜���RT'^��Ɔ%���
#L���{P��F(T����y�� <���p��!��8���1�ݻ��7��VVM�v��X�p"7�F���_:N�)��4y1-��13�性rtw|��V%&A!���]�he�Ai?��j�2ѓ��h�����"��䧲w���XS�`ǹ�!C�hN�ҀV؜�A"�M�xͣ�;) ?^����вHeu��<�F��W\�o�5�ox���Z��I�@����K�`hQ �%Qq�>��	\s^��Pp��)0�����lq!�ꫜE�����}ݪ�E�G��
PgSo��[���c�����e��=��R�G�Qz�r6뙬K��^K�Ԏ�   �R��=C� ߞ��o��P��g�    YZ