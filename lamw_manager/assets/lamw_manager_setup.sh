#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="386987962"
MD5="66a8e6d69c4322bca28e3525eeea6862"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26004"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:23:06 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
�7zXZ  �ִF !   �X���eT] �}��1Dd]����P�t�D�#��J�G[3O��
h0>��o5i��_Vw�``E�՘+J�9-X��:_����c
�n���r� U�U���2N(���@?��4p뉺����X��bB*c�_�I��:��^���K�yV����+2�Ф�MZQ���'S�y ���=}�d��+��,��3_�(F˓ =���_�U� �j���N�;��d��8.u�Wޓȵ�9W(
a�<J;��:³�5��?��;�&�ԓb�v߅���P���<��OQ�;u��0Gz�p&bZ�p���>pY;z����fWIm����V>p�?����p1��Q�@h�0,����?��=O�zibM���r	�R��53�'��R�B�����|����: �EV.�_��3�C�Ɔ���%=�����٘���_6�����`��;!@�+��ip�P�~�/.�>���u>���l�[��ܛcE��iҐ^�e�4��-KSd��duJ2��ZDJ���| ��Mr�֫�~M��5`��G����@�\��>(ͦ��C����!׮��4م\N�{<]&�?�r��$tw���\~츧�ߞ���R���W�׾c����h���������ٓ��w�j��.�+�Oq��Uďx֭UBn�0�z�Fr�/ǃ�&��:Ǔ�LZϼ�R�����v���p#�E�=�bbm7�����_�~`h�C��)���e���H���u�c+E	~)e*��z�tMb��@0{�� ��v�TC�D�"�3;��$X�Op|j�p���;�W���b3��Q۔j�����<�S���m�Ӵ;1m�� ��{�aoSx�`-oӢk�O�kȞ����k��� cs��J�
�+4X����[�@H��w��a\28�l1)��7Ϥ��Э�s�%��O�ʫ,]�
���_�U9��R�>I+{�|��H�.X��O⍐=^�������I�+��	�;p���|�^�V|�����j�w�]��d�Qe�/�ߍ�65��4%��ݽ�{C�Z�HE��= <����,�z�d�0�_�p�Z3��ss�l��&;]dL�
�I�?�t�Yb#�X�n�Ԭ�n[ �0Ǹù)'/C���
���7'���W��[<�ME�i�s��\1N��ř �1���/ϴ�G^�\}K�2��?�)՘����h��KMͰ�m+�iڏ��悘�1@�Ť?ei�3�v�I�N�5.Z���TlE�Ó��1�&�'V�Mş�4�GS�c���J��K}�)�6՗V��G2�Q�։QH�ߤ�7z��!����ϣ5�L_s��Zb�Z��][6*y�Tf���*����k=_���!JQ���A��\9v���v�������"��/)�-1����WIRu��	�7�ƭ�������U�F�P@�F� N� H���2C�ndNX�G����@gژP���As��4<x;��q�^[\�`q�e�tv�T��Uʦ��	A��;��`|����d��E� �bh�[���J)�3�K��W���0���H@�wH���PB��]�+OKľH��Fw�K�-LR��9����uw��e��m�p�z�g2�HY�	-��� ���Q�‏���"!A��6J�g���a쓞zxh�-����Cg�aIb�Ea����a�h{J^����(Y��
�_�eU�5�ҩ�J['�� �]�
ܔ.i%91B!5��l��.֔��wP�+��h�%��NT��YG�LB��Rv}޹TV[��;]!� ����:ř~+��Q��y��V����Nꦿ�2w�-�@	�d���x�_�kMf9�G��Oo�Ə����Mŵqm���~��^�bz{��-	:
ѵ�� �~u�^}��a�i�^i���TX�cy�}�}�mƲBvMC�2�	�}�]�Lʉ����1F�NW8(�G:#�<CTc�#㰹 �,.����_џ�`_^��qF�nv]�-pƯW��1)4�c�I��ܜ8���������}���`� ��4ҷ�T6�k�5c80'���
/��W(Qs���֊sz��݈>����J��	�{�,���^m��Ҁ��9�R4�_��\Z�s$���~�I�9�_�Wq��4���%��I���`�����h��h�5%����jc#�q�E̤�2sά>��w��m� ���pa��aQ�!D@��w�4�s}P3ș�`��cq?"����qХ���F6f"@$���We#��k~��=��!#�Xy֪��:U�h��}�������ڶ��ܘ�b'As�&�px%<���:�8O��=;�O�z�{'����-c�d:;&Z_�_)��dV\�ɀ���{`sl9�m���I�ΰ$��Q��t��2��hD��[��5/����}��F�`j��.7aK5�CX&L��](Ed��Q�%K���D�Jʜ�SH��V��%�2t�uB������r�r�G���2�f*�8�Q[{�	��/�	�L� 1 ���QcAI팴��+"7�Mz՗�[����f�֨�?0��P�ێ�;�11N���3P���De���@�C+A��'P&�z�UO�T��;=zX=��DO@�Q4�Y&��#U�F��so���ˮ���r�
�Gȹ�v����l�{�6���g��ʜ���ڇ�?�:�ޤ:u��c�#e�V�峖�Yd؋�@�*�ׄ�+������r�qy.�="�J�jO��q�yb0i����Rj\���&[xP@Yܽy�h�����A�����|x�a���u�{���s4��s����Q��P�sY�Ğ*ϲy�ј������] ���`F��-ƈl��X}v��vLr|M�i�zK����Z�Df/5|�H�^S��ia�،Jc�#�~���&����?�<�ׂljеZ�M����{W�h4y�gf�(�����oT����Y-/ �	��j���m�k�[�=��\mLBP��a�ޭܴ �1�k�YA�_�x��K�],��������'�mخ=��כ~�ۻ�o����Z�?��Yթ]��ug	a�V:C1�9:����O3̺��^��U����`��X$AR���
f)��eP��Z~�ඦ���/>���,/#�N���/X[T�]��|�]Jb��� �����Ǔb�8�o�dM���flw��*��-D��N.!l�H`�3��$�=D�7�=fB�i��'Ǚ�1�K��h��������p�����Z.�Ir$�p�0��;泴:4�j�㗎���o��	u��̃31���N�X�ֺ_jJ����뎍S��2|�3�ET�Y�f� J{�����BP?��Z�� � ��H ,w B�L�l����%�y�(���,j�O|7!`�@�_�!�}w�:k�R{)�߂�̪p愷h�Թb�<�p9ΌȤ�R���;�;%xʠ{�fy�gD��MU�^�ȸs�b�nVٖ��i��5	0��V�L-Z�H�ŉ	NiP�u��ܴ�)�ȨB3�(���	�k�qSMT����a�i��ofqe���Q"J�1��љ`"=�#�}�$�o��F�w��d1Li��5��08���󀭕���bl�݁K�Z��v��_d��t��ެK��	�K�y#�t�SB��2��vMu-ӥ���H	gvi��5�8�E\uo��ɇ�3s�dW�u���;��H8��0��0�*>�!gyW{6�#xzspa1�Sp��+�-�2	�{��p��kD���C���R"N��jp���beFH��\�-�kR�n��8@9��������Zix��ԟ�#t6F��mm�';���G��'���,~�f<�W�i
0/�	�5y]LE�S55=����O�Cp{'	�CVf�k�����7��h/j�^f"B�@6��+Ń?}���v�������)3>d͛X�g�6�1'�k<��n��B�׌/��9�t]��[�F��X��:挹��W������ۖ�]7�	t���]h�"�(-4�v�i�ĭ�Z���~{��?aS����Y~	l����L7pș3������ߍ�T�&�Z��Mx�Z8џ��mׄ�J���r��e�Pw�e�V���-��G����[���2_`o?
}�\pe�,�3��<���<�b�,�4�_]��.�v�L���\���Hv�z+:���-�t��X��a�?���'{�v��p3ȨK�'�AQ��d��>�u-d�؝di���~T��K���a����E;�ԯ�L!q��
�\��9m��}�S�r�q*b���уb6�N�'�#��R�ߧ� ���(�]�Pc�_��U���p�����6���]����� �@A!xr��en$v)�	dC��v'I�ˋ���S�95�J�d����g&!YC�L .b�aPf���XCf��-��3)�g#�����^c/wX-��a�QFI𧶀�&S��mƾB�ӯ�M)��l'��3!�E3�f⠬f�	�̗{���j_�RQ�}�k�d�+T��۹�i��)�+�P�@�����7|���"t���K^W��X�����V��aJJ8��}ci�ǮX��S����!�{����]�É$��4<Wb*�9�Q]�x�Mj��y�q���[a�&���.qKy\Cv^\����=����5�+�O�̯M�|�F�{�V��<�|t@�(�|�X>�B2���+U��;�F�]M� �(�~��.Sd�,�D"�q�vQh�S���ytP��
؜s|��-MI�<��v���Q�����Ra�ɴGt�9�>"����Al�ƹ"C3A�Z���n�؀FL�? Q#żznyD�9����*�g霅O�Gj���<�fy)��{�����+��x����_�P�aV�u( ֧xW����>!n�8U9	�9LX��w>�x �����bN�8�a,+�YCcn9m^6�c��#����z<�|丬�b�/Cϋ!^Ɂ�~+�/�ƇG��Ui�>)9a���_�|�d&H	奛��N���4^�L:Eɾ6��~ǆ��Gf]�������;"��Q��k�e W�U9��: �3�}�Z�d������M�i0>�� ���wvNj�`��Z�ݸ����2�$e������y��_���*$�+L��`4�� 6Z�5ǩ��i�\q�MU-�Ir�����Wk�߂R]��70���5�@/��á���9��0��ɤǴ�mF)R"d��%a(�煙�Ԡ��~Ҍw��äu��6��=2�]�nQ���.�%�a��K���[�^���N3&�X�R�K��Z�5���^�ծ�1�����ms�y���ҰTN���9�Q9�I����r<,�&?	�Cn7ۍg�+�$7�a���ޣ�
��3�LxA�8��ٽ�M���&�3�:�~�zxG�bwD�qڭ%�b�� �,B�r�97ϸb��ut�R(�(bީ��q7�\��=F��Xxc�Xǜk�R����h!22�|;��d��=YIݔn��*{� Q���\jYt<�����A�Xh)Q��%Й����w턖�,��E�����Y�!1�y��ޑ9~�̋Cɯ�FHe�'{o�i.Pa�<�Z~G��t��T�S���Pc�-�����X�$�P�U����g-�/��a�ΘC��m���勍Pp���,��y��K�x㥃�>�� ֦�``�^� O�n����Gz�<�-��7^Rh�x*yU�B	dC��x���-�X ��)�?�R�F^"#ޡe4�� ��
�����������.;�g]+?eSC?-8��}�p��L����
N��/M;��Bmg|�X�,�Kz���A@� �p6������`�F��Wo0�2�%Y���`RU�`�`qǇΨ?�i�EM��d�����x�-bWld��}��|�)˂�C�
�_^�?z-�֛>�����W�5Jl�Ě�B�j��m�ޒ��u�Wt��!+�+]�]­���dI&���s4�L�Vڔ�&��`B�XI�]�$R�HQ"vChK_C��{r?��E�X8��9J���b�Ym�F�>~$a���m�N�˿x�K��D 5oZ���|�Q
����8lm�>RxX����A^�{��q�Jw�XC�ax)�6,��Y��x6��b��BނH6+�U�<�:��_s"�o��}&D��'Km�gG�|��w�]'�T���f����I%��o��,��bI;�̉�ɖ�R�� �m�+�$&&�@�D��T��Y֏7��>��<��p`�-h�;�8��Ĥ�n��ܑy�O�!�M��:	��������7�B��M�i���G��1����z��R
7��{.S��MqC�c���hs/�M���'ǵLaz�eŇ�`3��n��dQ<��� 4=�+�������A�Y�V/j.1�ȑ�`��B��q?o?�H�h�V��ڙCi��z���Am�!k�l��ps2���s��v�A7�}���QpEI�TA'�����dP�^���M7���e8�`r��O��`uUD��f)��6I��p�ۿu�~
EA�T@hl>�~s%dV~EB��T�)()��.I'ħ'��zH���o|ذ(=O+I.U<�pp�Hm}&���6�vl7]`�9���tp�������4�]�fq�׿�(��%{�f���C+QC	���
7�}�7f1s�'���=C��d!���LI�.��:U���FJ��YW��X��զ�?�a��I��A8�Ùl*�h(F~y�񄰣�f�p哰�\�,Y`tHoy��m_��q�G���|��;W��\�3���^�4��H��Pp�NC�D��W-OA�����H��{z:B���;���/�H�ܷ$ϥ-`^f�d8�f?W}����)�B2���I�+�6�`ƶ���	��t�!r�[��&�A͆Ʊ;�ܞ<���qMp�""V]�;V��d��*�ccN=h�z�H��q����������b�/��fS"�c�N�4�`<瑅��O�R%|n��^>�,.�8�AFy��'J�t�Q&c�o�N�]c ���m��7����Z�$@���;"l�� �*�|���mzu��r;�ގ�A���n2]�#K07�M|Tk�5W2�}��{��U�UXz���.�p��x� �u�2	�	^���O����C���bL
se���
���N+��qK�CW��z�B�}�������-������v"�"u���H�N���a���Bl:TV#&*�n��F�
��ɦR��hlU7��� et\��q�OZ��
�IW��j<Ȕ�[M�l�)d�/j�J�jd��B�s�5�uw�����	�`�`Rנ
���ARH=���_�'/�I����&h���7���;����Ձ���iA���]������� �p�PͲ��C4�8=�{�iU����"�i��,�)���w�arf<�u����э�R�ފ�v�LK3�J�}�A�]�y�����]�˥��J�P��ݍj=���1u{����k��v�Z�Q�"��F��0�mY��J�������ֵ̘��� �P��e3�F^��~����R��Z����I�8�4D=7#���VFuһ�8����K���(,��ˌ]<"	����:$d�GDc���.A����26�>�*I.�,�1m�ڥ��_�h��D����6�$�G��[ ��[ !��q��Q�,vo��#�f�H�#���\�j�Ch���,�����qͅ{_�J�1kK6�=�G� +����p�'�j?�UK+�=���zlZ�匛����0���\��
BWe��檾[����t-}H*�,NG��~�{{I��l�Oӗ�%n4�2����ʻ��#��i(������.��`3�y�`-j��O�y�=P�d�`Hܣ�l|��ᰣ��E hF(9��NdK�2dΐ��`_���/늛I���9�divX�T<(�%ۜ�d��Px��px9/��9�<���R�5O2kK�䇼����L���4��YS���ᇺ�g�M'�4�^�d'�0�������^�i�l���5�ʭ�G�9>xJn�����k���-\K�*!�<�y������(<� �@]�D�&��d��Y�zR��&����ve��ߤ�c�E����N1X�i�8�tJ�>OED������	������(�ګ�'�.v�qN�ד��l1GӒ��7)~
��~������{�J8��V�д������W�	�,����;j�H;g��ܙ/zK��F�b��TKfG�3�h��9f���o5V�θGv��ocZ/�,�S|឵�M.�{�Ss����;�@ѥ�o�\�ƴ���!�6��m�8��fSn+�u�)ȌȆ�	Ӟ��4@Î��4�4[��Q����N"����p��tF�U|A��U��I	if�>�H��.�����jY���(=~��dw+D��0�� ъ�3~F�V��9
Ɵ  ��tyś���˹����~�8cfR���%�샲]�{��t#��3'���0�,��Wfdr�R�?F��%�
m�J�,D+�_(Ӌ����,�`d�O�%�c�ɏ���m�Oio�����t���}�[����R-��"<.~�Z<��-\�(�����^�)a�%���ӼM^��q��0�����-q��~�jcd�w)�� ��|w�3�y�8�ƸWǣ��0��zr!�DNȼ���A]�~��|`K�D��.v�[���"�H��\�`R�N��k�f�ީ�bH(�5��Yp��4Z���EJ{w��Q��ف:���4� ��3Tǈ8�e��YI�*c��5u�=��ȣ��+LYa��^o�p3#��Z{O��l��K.��p�n2��k�z���ۜ�Oˮ��Me/T��� s^��%��v�Sv՗# 6����Z�D�ɚ
�iV]9�Jɶ���AG�+vȯ{���B�Zߊ%�WW����^��G<+�U��*�NG�ĳU�d^e�8��(0�HH&�fK؊6$#�sinl�y�=2�:i�yYq��;e�֠li���M��	B�u�E����#~	!�w}η�Gavh�˰�t'D7���72���	Cʤ{�< ����:da&Z��I�n����C�m�2�����6I��:�]�
�z�׼4|˲_t!S�H�W:�0{aq.E�(��m�`!F�$ti����;���Yƒ����f���8`s�����6��S6������[�3{
]�2�B��p�^3�Xe%������������a�z0z��C�|���]9�m�O�!�wV|�Ʌ�.&q|��ųW�� .�7�����"@K|��˼�	l�.���DT�$<�Oe3\�^�]�מ^�D<g�+б������~���
�%CɗlD�8]H��G�<;n#���g��H�nP�G5 � �]�>{Pp�Ο.���h�Z��;���^�QZ|d�f�"'�����|�KY�E��/
�����Zl����3g�9�Sz�\��QŲ����)_���D�9��)9�I���G5\���`�[/
�v�����������j����c?_�$B2�K��cd������C�{=Rd��H+/9>)�zء�Ӯ�!��Z=D�E���M���CX��
ᐖ�f�%����(�@l���#R4cJ���O���UЙ�9��y����ΜM��������g�:k��9�	!F>�[`��8
�X�|�M��'
��h�7lζ�����{��a�ǧ(n�]��%B#�-�����!��B�����>So6F�l���z����s~ڟ��5�������7�G��o��b���:��{�IE��JK��T��ĖQ��iz�V�c7�+"��.)���؃��\��F��B_��,^p?쪈�Uc�����~��˿���[�8L+|-aPk|*���_�5�}䔞Ѯ���  <��۾��%"lך �/�vT������4Č,Ꙗ4C�zc�޿SZ]�0(aݣ�2=(�@8 �/�'�	�otM�$!�A�d�i�B�~뜏����HŪ������tӓ���-WP9=�T��T�J�� O������(�z�ۉ���G~�+��/�
~����AvT0�3��ũ�m�XB��7�%8�ne��b�g�m₭:&��vRcH�Ԙ�L���j�I��ӣ,�p9-�D=~?��p�A����KN^�
 E�$W0�1�+7�};b��;����~��MH5:�64�^m��A﵈fM޼i�d��]ʾ��N���u��p� �߽��Q���+�>��3dcZ�c��.&��+�(|U%�z��X ���R��[�~���!>�j�z�|��$���E{���U�����t��QhG��n�.+Ղ�(1T�o�8�-4�0Pg3}q0�͖ż<��i�٫coe�d&������u�)�xϣ���LJ3�������K��`.�]Kh����;6���̑��G�j�D'�R˔
��c��)�:���_�p��R1(tIyZq����6(L7�"{�k�;�?ֲ�*-53��PmuC���M�{���,!n$]�q��!��`)ԋ�E�}�$,��ڇq��m���@�E��RX�Y�]���[��L�Ǩ���#`4�[�Qn��8�t��u�&���9k��b��)�Nbm�s2�Le�ޚ#]ԹW�w��*�o�'awP���f����~����
�����O!�RK�c�����w��켂o��"�o�$�OZ�_�f]�����n�vC����Cdʴ����?̾N'��N�OGybIl��`�ΏG�x��K]���܍���:�`s�����A�����sPg�mOp�� 	�ߢ�L���H*���S@���:����	����Y�u��#n���Ġa����@�M�#�^��������Λ��ͧ���/U|�h=U�xgK�.����U�3u���i�E�j��޶5p��"�Ę��<�n1M�~����
�7d�ѹ�i�́�0}TJ���sG�+K�Tn�Wڴ�[񞉺[�b߈[�2��c�xo��f����A��(ҏ�*˶�1X��������%MK��ev�+�)�mS��~Þr�J�������\��dX����!$��r��t������I��a5�Hˡ��b,Q����U�?�W�����gYۑ���UFz�ln�"�+�9``���lv�@hMkU����Y�@B�8IG�q|��1��fBX�@����^�C&�v�y�����zڤsI�N����U�����%��܎�d��
��N���_�8�e�R��]DS�TP�=��㨌̲�O���V�,DPY	�� �82du�as��1F���H�.����i�A��ƚu�oSr^��'�_�q?zi)�K���j��N+�
�������E�K�U�o6�`8$^��qQ3�Irl'u���<�� A��Q��h�×����WtT����p9��VVf��������$-1?��Pi^�~�^b<��ە���Pّ�#��tFi�*�����C�9S�v�,��(�u�Hu����e8���<�wKr
4�C��?��d�&�Wi�s�g���ƛ�=8$�x��#)���N�]PA���+�J�\d�Em:P^	��Vk��N�}Q�	��/("�KH]C=2i��iq��4Ʃ���`��t�j������v{��Y�~5�J�R\'|��`�����l	��痢�<�Q�����6t���\�b ���j���Q�`aX�zm�Rwǒ5ޏ�.9���2S�2/9ͳ�fip&p=0ݟ*`1������bƟ�F?�]q#��ap���6ئO&V�8��s��j��*��}f�uK�ð�[|��m�Q��1*��6�;O�0����	����U}P��.`���0!�z��e;ʔ��P�)��W�&��H����ܙ�H�I#qei�	у<���v��u噇!|'��"��"\�R7Sp�u3���L��l��^5�ρz���@�[������@ᡵ2Zc�pr�t6Pgv�Ą�]��'�C����\�fh�� �g`�V�Fu#	��^�T�ӭ ���PR�x����NN9zX�j�:���Í�c��-V
�뉙7�꫈�G����<��c�=r�NKlV>�,����C?��aX��d�z4���k��q�1��Kq|��A�%�
�!e?��;1JVJ���H4������r��T�q]Č�\�@	�[�T_��fF�(֋6��{��!�jRRm�N���3�$4h|4|�r�l�U�B�ڼ���	v�,�tv���w#�!dR$?a=�$X-�RP��i�b��;W����<���~��~����	�
�OV�̔��LFW��A�Y'p�섛�B���PDJ	S	BB�f[Kgݘ�wXj�a3�~E9��)Q�����*����bE��QV4��>���o���F��}�훘�-m7�V܀����#�9n�@��X��3�,�@ZK��w��6��U��� I������;���O�	�A/{E���f�ہʉj0pj�ꨤ�A�E����&���j�����%Z�XX@/��N���"���dH��?�	�D�9x��y��f��*^���*+|����!�a�C;h��a��WV?�t��dޱ��S]���v�S2�uO�A��ϸL?�C��3�F�Գ[ЁY�8����?@ �y�����&��X�1��p�AGDm��@�h|*�-X���
�HL���.�7dZ�O��`
�|հ�f�7��Ut¿��������2�;-���?.aj���C���|��L-���$\��H�4b�s[�$RZ�1ځᆼ77+��r��N ���C�Ye���hő��olE1�j�牌S�x2��_E���ౙ��s�v��!�3qH�2a�Oh��Ց0&w<KԽ1X�.�<�͕��G�JM�<�.�6@v�Ȟ�;S�W>���F��o��1-�8�$ȀD#j�q{�6-{4�R6am�<�^�;�4���W�`ITj���݄�-�b��\��kWeϖ�*r��X��j��3�"�:�<����_<eʸ�l��ڒ]��Ev��5�
�ZL����&ꚧ�{�ogu<O���W˕ܣ�	�D����]TL(�R�	`�5~�}p�c�U{������cؓЧ*�J]� �Ck[4#�Ӧ��?��ū�5�-�z>O��*�q���t��H��$?������!ǆ�~	-��֟x�c�o��Aj��ymDTl	f���>��\���il�O@k��%?�����`�W-��	��w�7��vU��|��d�S��8�͍�%�X��7�K\.�
�,ݻ`��������bC2�hlW@��h^� pi0�\�z^Ԑ�:�������\��}�9u�a�2hu!?�䯮Mˉ� ����ǐ� ���g�#'�qR�C����1ɦI���A�O���K�a\_����9,�J�V��gM1�"���P+�R�u��Og�/�ڇU����/�ݬ����/����#O�����Ql�>J���W�2���m!ek��T��k����r�S����TV`T��Q��T�����tR9#J�w���J�{��Ƀ��=�ac�B2z`T�Ͽ1i��l|H|�cr�f߇k)���I�K�4�ER���q����y��
��=C�1.r�T������S�.�����'v�h;I�����MCV��*��R>���
���bb.cX�J놩��F��L���&9�k�)�At`l���E��1)�&�:�T-&<��x��;��KS:��v�)B�-b׏'��1PD��da@�Г��d���^r����!uU��=�X+	�fq#�s���8 B�~|�����+�!'��8���]��)�D0�w��	m�{��ܰ�-�k;��n_���K�����4�ܪc�X�r���VD�ѡD�	i	/E\o���c�ˬ�Ⱦ�/Oh��n[�s��S�ҩ�ʰ��{"��o� �rw*l#~Gn7�vh�T�7V�؈���D�Mz�c5�&2������ŀxĀI�=�:�8��<z�kG����5�H+q�U��Wc�"�>��)1����;7�i ��~��b��jʱb����q��&pٯl����t5-�Tc]�G�	��0�rĢeK�vw^�G�Cj3䥦ܶ���oQ+<0�ݾ���S|R�!���G��\i�`�����A�9F��f��9	���1��v�&;���τZc�a��]lGɆ9���+�q�\��S��x�껅5�̚�8>Y�M{��vM�����WI�vU�bU��AhN����0B��e�d(�.�+����S�
�z홧Q�"����i~�o"�gG�΍� �0zU7Z}Y���Ňf7����ȏc���C�)�u���FY��uAO�R\��tQ�����I�kf�����I�AN�-�`�n��z��@�k]��5=�8J�k!�]
Ej�[�	>J��3D�ʍ�Yo6���	|6Y0�� "@�V���	�$�Xh���k6rBa�d�=vzQg�]�����@?�]�~W�� A/�tw��V�;�4���Q�;��v�(�I��ݨ���lSM�2jo[t7��hW1���%��p���Ux(`0Ii��DxA��6��qLBY�U>ǯ4)�w=�z����)3����.Mx�C��d >�XH��|<�`���������0BO?StU�2񏩊W6�/g�5�]�/�\�mO��1"v��H�$��ͧ|��j��bC63:�����؎˄YW�2�2�������V#D�d�V�j� ���>N�E�*���I?�@�C���,�H�7$�&�i��gP
��,�v�ٖ�������-�cT�F�����h>n䱦R����Ъ��Z�ѕ�8��|��Wp����i��p���#���ǂ_��n�͹��.�MH���R�һ����L�{�(��<u�=��+��#��y$CXX	;9F����c�2�p���r�"����r���!� .X�@�#6��{��+D^�㳥�s����S���[>���l��MԷ]�_fM�k2����f3ҷÝ���0�^0���?����+��m15�)��_9��8MM��<E0f��;�!���(ChKBN�酶gF_L�r��BX&åt6��߸�b��>�cM/��&"�Ť7=�K���*��A$["՚��l�Jp������ۋ�����*0�Wr�x\����d�\��iO��'r�o�H���έ.3�_�1���GPj�I;���5n��cx<�`�V O�u�ս�D`?�+���#"�*�>��e����S�=����\CXe��)��9e�e�4@g�|[��=��saF��_J�3g\�i�2���]P4��N��C�W����$SPA�l��qk��:K�P�?c*��[�h��/A������\<?��t���_�2f�+
�^X���`My4Js݂��(��8��H��&�LN�q����IEo�x�_K�� A�J�1WEz]vHdTG���u��F�����3S��E��Şb�����j�>$��NHii�9 �l���_��NW�T_C#����F��md�~�o|@����+��o&0�*1�u%��U�H��H0�����}�tܱ_]���d�>�:w�)�o3W*G���(]���	k���D}�^�[Z�xҁ�ԑ��u�fw:#4�� ��H���E\}FEztZJ��Lyx�5o�#���>!�$���m��\��ݥ?>�:�ͳ%&1#7C�"Qm`�����YG顩��mI���cٗ3�XL��19��q���Y�f�?�=U���Zæ8�@{��1<�����/���0e�-� �#%��3��8�!?%��� 1z�$�>.I�-;���Fit��.��:��h
� M�k�<��n���Cwƽۣ�"E�25�CE/����͹v�����:�.������[bT�5
Y(<�����vg�$��zl��Fm�P��
k4\sK��HU�CF���׳7+,�`/(deyً^�,[c�O]�uB����	���/��q���B�G�����Ef>���D�Xwׅ3;�gq��P)�����lbL����W�\������I�r���x�':x�}U@5l�
�֊E�s�<|8�Y~��2�/)g��h�叴f���>��+�`�e�o�<�r���7���X˞�(#���	���Ԧ��e�9�⸁%� �EdBF[�eȹ�����1�@��]��.,W���F;��H�5L�J��B#{��f�²�8�N`���M4����;�Te��gv�zY�u�fJd�G�n�Q������A�#Up)A����M�.�+	$W�}��Ѕ4�������VR�(�.>o���E�-�"�)�QYW�r���-?L]��/��L����K�O�h� �1�?l�m�/��$v\0v�q�e_�d�<A�r�Y�OE�iJt��g�q�V1.�#nP�n�K`��S)��Fq_��c�X]k����~���Uvr��[yl�����=����j�'-&��g���-��[�;,c�C����<�ɭ˦X,zձ�$95C��}� �IƌT9oC�8ľ{=}��O���"�B�O%��W���A��C�ޱ�5WV�U�-(b쿦��w9�$a��>1Z� �(�ɪ�ʊ��>&�֜���t�Op=�6�t�C�����=���O�iWD��.�t/[�	��A<����yv٠(��A �؀��id�yc�4̏I�xQ B�r�2d�1���ǌ��]�A����#ָ�d�����d
���{xp�rJX1���#8��'�����H��P{M W�wrc��ycW�\�M��\�<��Ǩ�����0_�k��F�&�yY��+��1�~����4V��@�׸A�U��������dw���A���J�� �{��ޥ��"��R>;0�0�)� o��%�"�%q�L#K�%��R�u9�����5H��=�h��4}}Wˊ��7����E����%��w�r�rBh�{n��X.��C�_��H�{�a����� X�v��5�K�Si��]?�p�:�5oM��9%o�M[d�1-ccך�)l}�?�i����*��x���3��{^'1�������hz~��N�m�d`)�PA[7�G����c����0��t���:�q!��뗪B_�B�qvw7�Czr�E��#���+@X'��c���y%9�N[�L�<��cf���`J���!�.U��s�K0}|I����"�6G�q�ڏ~����J�V�0]иw�����v���E��#�R&�"A�I͇��ۿK�Τn���&��9��_i;<9��ӌ��?�GL-g�Ȟ�N�S�`�����q.���{���3A��+��:��&������_�9�'ۥ�f����-��$4kn�M�5�\�\�ǿ�\�e�{y���i�K-���"�V$x_�P���j�{�����oE�$�6��y+���{,��ő͂8�X�|mϵ�7�3�]Om* ߜFc�����'�@T�v�W��#�	�rۨt�-�\�W{��.%�`z�Z$�W����N�������V毾r�|[7�ܹp�jU߀��a����Z�p�^����^�D!R��Q���C-=��e�lz�c���X;x�_�=%�X� �`%q��<��N3HX�dFd��M�}��2�jn�W�u3 m,|��1���|�/>�i�;Ⱦd.	Y��gv�1<���
��	S�	�;�p!/?_3)��}��F�~	!`%�K��-��$\N\�� >,���L��ƪJ�[=�����+A4O��8��I��
3��_�:ˁ��ɜ��9�&�`��j?{W��
*F�.��/�l)���mY��|�����>��d^�.�"��נU^���q�YXu!�hSB~W�n�cg���6s!.$o�|�(�v�a�P��ZFʺ�$���r��1���uS/�)HT䷱¨��^�\9������'0���X�׾6���D�-`�GP]��1Bd�C�>�~�
�KB�_�|��5�'����Ɗ�܃��D�螢�b�4�$��k����E�0K.�d��i�x�]�`������+y 3�*!٥7���]�g�!���tlj�h*as��E�0��_���y���ɱ~G�'��<?��o�b�~�'�[�9���J���lST�i���%�v��V�<�l����;_����AHH�](b��!v�)�u8W��̺ڡ���6��3���&���
aΜ~�<����n�8l
��q߈M5X���t�I��DsR��`LOF��j
��R�!*=;�M�L�fdԐwuI�엹T��|B=�P�eS@㈟���2qp��fxrq.\�����_�	�u���Ǝ~o�*V�� [&���:���l�EF�&A��C����[��bulwwAv}u��wO�Yʞ��a�/Ҭ�O�ءw��Zc�k&Rq�Д�g�潺���tvX)�3[}��m������24��A�*�ȴ��Y�����jz��W�^e�
up/��/��6��%;J��P)ˮA�vM�`�<>�Q)��Ҧ��v�䪧��	TVǼ�9;.Ц��U��61>:�N���i��FpGa�1N�"�zC?l	p�[Jp+�?���:
K�6QkdaO���$bymjy�'�|�ř��IE҂>����#!��^��_�<�)����ë�9(���L��`;>ɇ���77�<B�e`"J�ԟ٩(�ܸ��k7,�M`G0�ҡJ�6��*��-$��"*��[A�NV8Y�ϋ��b�}~7�U��:`�}ѥ����[&N��p�ҮϾ��*	ϰ�r�r����"��YtP��%0ۚ+~��������a��N�ƹ�5~�.Kf�R��(e$�m�P�a��&��ɓ,%���a�ђ�=!���Ld/�Arh{�xcO6�h��9<�%e�)z�#�"꾽�^�� ^6#� L>�8�-0+]u��GG�@�������C�̻zN�(?�ٱ��F&��V��ޡ��z�E~����G7�s�W-�ǨV\!NH�4%{� ���x�XM�p�<k�Z�Ѧ5�Yd/b�����){9�,jD)��]���\�}>�X7V�!����E�gu�=����3�l��f����볲�(��n=�6iz+�";P4Z�������iKǎ�$� b z��<��a@�n6Ŝ�y�垓xA�ܡvV�w[_8�*<�����o]	I���Γʨ�2db)E<ؔ�����
XD�0h&"�	��s�sg�[:tRb����r�/�[�z(�Я"%���O ?,�8À�btk�9��?V�5&x�=6�w�i����^�h���ߑ�ף�d��&>W�("�,���T�0\ER��F�.^kΩƷ�J��24�Y�q�g`�`D���3P-uܻ�Vk�V�7��!�&��Єg��������^����9������ �x�|�g*)��j�:���/u�� �<�{E�]��"^�p30���0Ʀ��°12�ڲ]��<�_�3V�s�qc�L���0r�S�C"�Rz9ܻW���༡ԟ��~�@���"2\���npkv�^�#���$�D���c�q�JT��&�Sl����3T��+`�#s�K}{t�/|]\
�b�Dt�g���ۣ:��֘�y���mZ���P���Va�9F#Kx�u�#B۱�H�l\���. �*�v��F@�����eĖ�*�n^�c�O[�g��@�ڥ�WRX����%@`���%s�8m�u������3�/��y�9�6�z+#6^�ÛgL${���]���s�C��҃"�:%����Ἰ���}&�á�禴�G�wޡ���'��ؙ�>p�ۣq��>B�!����@��ܛו��q0������t�sj��`�|z�x��g���(t;ye����9x��ٶcN�ة���0�|�C�:r���"�R�!�wݸ�cPzW)f䍅��+�lw6�@/�D�?�oɹ�I׉?�u{e^��l��g��v~��Ã`5�������p��"�_��C���*��5:|u}��g���Ũ\�n�*F*-g4 $N�B��f�zo�+�%n\"���Jͭ�_�5��w�v�]����%��4mk,H,O��SÖ! �굝ZM�מ�*ڷ0�e(����u��Acx����ϡ������Y�_�8���g�3H�F�̱:�y��d�������}o�\;fv�P0����Պ��$��s��Y\ɢ-7���M.cY�j�To�#����4_X�R43����Vh���Y,���ɻ�$��#�vƁđ��x�<��<�D����}U����2Dp��V�yY寖���s!�ڂ���7����m�_�?![�,K�X�7�3��f���TU����UC>������O��Jr��VFbY|կ�޻�����e�o��qxsDl�QCQ�T�r���a�^�������i��Q��k	'J�/#g!C�'���wAX���2�$J!:� �kO�QP&im_u��m"v�%���'��m�cx.u"5�a1.xR�;�����y��)�H�pE�z�k����h�6ͫe��L����U�J�]@���z���=�3t�x? ���c����Ds*F�x4d�#_�.����ק䦐�or��R]��I�%�����I�9$�ZJV��+�#��ɖ��{7��(8S:���4�g|���&��ę� �����:���|3�e
@�e��B�qc�oC��D ���"u��6J���p��y�r����\\H-�OUi��I3`>PFSX��5MD�N�&�'Ή��pl�!gX�tę�"0��ɯ�`bHf�(-v}���Q�R�w�^MK��#q����d�G�>����]����3#?�~H�sXV��TP8*d���[��=�'���v�!��x������,�Ǯ��^��ہ���X8Ţ�t��b`1��G��q6�r�=��)[ �Z�޿wsW58�\�:Ֆ#�R&�";�*�}�5���X�L��3����DS9{�)7��N�t U$�Y�m�F��Q�_R�P�m�7"׻,C���XL^6�&"�0ߥ��$�r�`۸��n�	(�#��Q�n-�Rt>, `��q,�u�� �x��o�6�:X �(���h�G��F:�^k��x�;6Ǩo�E��Jc��)�ي�d0��X���a}���3���?>�r���~�{�s�\����r ��Ea<]�ur"�c�Cֵ'��y��E*��񄈸��?>],�K��%��SȿI�L!����N�f1�>vOu���3�%B�:ݾ<ak��1��V�٬���@�����w���AjL�c�J�����4��t*w�!q�,�UW)i-DTJ�;XdO�$���rEP�EC�͹�9�%�|���'/vl�E��B���;��� ��뇹�_���?��a*��������Mr�s���Eޛ)�����Kj���nt������1r��Uq���}0.���eUgNq�e�&u�AA�q�ʉu�����+=�\�a��K5����|jVA
�:S]\��nf'r.~, ��������J�H������M�U����ݘ��5��E�b�;j�w�蘟�'��З�š�$��LB��U���.�ð������f?�s+�߮��N۹%�-���VѲ������1����J�������Bxz��@�+լ4&;���*�PO1�;�V��K�3߷�" q�d����,���<�'�70���&�H�c7�n~�_J��}4(V� m��j3�����ɋ�Q�iWA(�IQ���Q��K����[_��<K6�.hS�<��� ��+�oS[LuZ�(�t5�nd��!������$���`)^��dm���A��o��o�S�fܐ��[+M�8�"szj����uܻ}�ɋc����o�O�#���2>^ۉ�]��ˎ�#�[�Z˳��:���tka����l��6���(�j�h��Z*��|UlEG�(��O9�"�,N��u�$����M}O^w�Ep�$-�6��hx���)��E���r�$�x��#���Os��"Cu�������ks�[��t!�3�t�iR)k��RZ�9"�j�3�Ӯ�r��݌d�5��89!n����n�e��ٽ� iF�D��b��q��þ8��h t���F�@�jM�<˱����^�e�ki���js*|Y��3�O!�6�s�m��i�+�Y�=&����9�u�N׌W1>��#-`�%�͕|ŧ!D�'U.2!�4���&)�iN���^�����c�9��g���	�|�	� �����a�ϖa ��`�ţ���F��Ӎ�Ȋ���/f���P}��Q���"���� ��%6��R��SwW�ir��ʗvO����!71 WFc �皂��Q�cH�������blM�e�>�8��a���\������N�"n���9k(g�g������=���/
�uG�(�S�K��&�lm�uy!(�d�z7���eR'��}���>S-E�/YQ:�Ta�J-��k�'9����_C�L@C�q���oބ3�-��Ӓ)W��N��R��_��$�	���6�圼a����X�2��Jb�az��{�d)�iZ�O͉���Je%���\���Z�
� N���<#k
	r��h����~
�R�Ee��nu���NN[�B�Cer���՜��̙������ځO�	4/y��w���p=��ƃfx&$y���y�E���#���7g���'�Z�xh�c����*�v����Bar�-\ǡg�>q��S?�ޭ��G�7;n�N�#��X$�����wTq5k��E��3��(T}\���U~���c4����_�h�y֎؃���Y<�������X��U($��l3H���P�M�a�?<_�W�?�\MMԌ�pg�qc譁Ў[p�pen�ëV�2�%�`�<'��jajj�,ɻ1���JP�PE�����5HP>x��~��1P�E�ln�#'fw2�=�t»�x�4��~:tm��7У�;d�n����3�X;� �(��t��r���Q	l.��'=5#�����1RؗE9�`L�qW�r\��Y��o�l���x�4�2?u�a�]��ᾈ��-��ٴ� q��؉���{�7؂ oXyl15p�V��&���7n��^B�����9��G��J�)� ymFẩ����1�~oS@���t�/_�o#�%��ĉb�I�@��7�ܨ���q��J�!�B
�kU
�5��x��z����$>��*��w�/�%zo<�C�ԯ26H{�g���N35���"�����*�i��i+*����tB��3�^x��3�0���׺���[�Q�޲�'|�r���`L�����A��s);}n� ��3�oDI@��J��yp5[V��O�����!?���N�A���T�p����)�l,ǌ���x�2|����	JKoDN�h��@'L\�#?�v�b¥��ć�>q(kj(f$����J�ڰ>����GbfH��>���{ਗ਼ٖăY6c1�°���4��n��N�RG��v�!�Dqz=٬����(�x��q�cew�Tj��dx�����kh ��j.���"�2?�X��v>$y�J��N�0�Z�{f�����茳pZ���� �SM�z��0�p�3~�!��{�`9H�̳!k�R	� ����};к7}6��L[k�(�Rی�M�I:�*���[a� khx��
�b��'S`$v�����W4��Y�+�������\3�8	����ؒG��.�N0��va^��l�W��?;� ����;t�����O֨ck��k��� �]p��{;�Ԭ�ڞ^C����緑ק�_�Ꮾ((D��V'��
oOK�;�H��@&�>vvK�+z�Ru]�|;�k�0;�����=.w��gE�uM�B!EqƟ�$��j¨��YLq���~A���ɍp��N�ʆDVG? TEUH�$v"NQ�	�(��6�p�Pj��m�^ńp��Tӫ)��	M�`^
nm�*=7ܙ���B�!^C]��i���b�%��h�.��Z^_���c�4�pTy'%��)=x���܋��}WIq5h4�ԛ�<'z. 9�wv���Ȏhg�0wE���4���~���v�ۗ;�����%?l�q��9X~�t��M-!2
87�$(<�ӷ�ŵ]��W�*� �jb��4���	�	ה�ȼ���+�W�J��e���N�`��Ş����8+ي���u] �)%���]^��3s�w�NpX�b����w��Tz|�V]F�`׳_�X����O���	��DD�"o�>d�Ynd���W�*��E	�ݤ�,G�;*���,|���D(�U���-XN�&T`-�?��Bk�w�{���55�!���{�!���4u[��6gU?t��2��9��h֒\��v*[/�Q,�Gju���ɕ�C����'O_&�q	9�4VJ��,h�e�j5Ê:����0M����E��4kFC뒃���u���gp�A�W�q�e����	_�6S'Y����g�	N�?P��O3hU���w!��^��ߤ�%}�����E^�!X�z�'�f��\��?^��K��v5�}(_�/"M�RXEt�i�Y5x���{%P]�Ӕ"j��8�Z����F� ���P���  
ֽOF 4���+��J�}M�©�6P5�](��&qϬ�����ǅT׏�Uܲ\��GëWE�u�] �I���nM�KW����:EP�����ó$���8_�Պ����B����� '�C��l�ǖ�8��5���f6�?��44����e�Cz�G��� ��%^T���궧���M�/zr�Ĭ��VyO�sI}_[��ʾ-�M���*:��cko�n�m6x������}
V�1h!�� �o9\�e�6�Z�J	�"<8E[�׎R��᫑>�����x��\��'l8��mr\#i���&�ܚ�H �K�<���X�7��y��ʪ�	���.YO���F��d�Q}R���� �|"�����"�%Xyȏ���%��PKO��I��$<íd�4&å���y9Ur���P[�e�C�x��V}�%*��iM|֍�B��}UM)�6��a����4l�|o�Z�I��)+�5&ٞ0�Y	�}P�(ҿe�+�����m���DA.�SUwd1�'�[4�������e���l��nCN���N ��vsS{���W&h��	9������8J�0E�%�K֭�i��F�wJ�<?���J��Y�)���V�6�" b��j2�Y��8x���I�FQ`��"rX��.� d�P��;^��߲iEĿ��=&��qzC�	��\� �h1���Tem	�w�3��vuRb	Pq�oV�����G��V�	N���I�  �����UfJ ����sCqS��g�    YZ