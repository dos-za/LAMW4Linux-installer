#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="388377373"
MD5="b848f536692b0e8f9d77790a72cd4c76"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23588"
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
	echo Date of packaging: Thu Sep 30 21:18:31 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�|�V���c���p�3ċ��L�تa=�2�5{��Mrd���BRݼ!=�L�GDz�G���\U��'����<z����S^�:\u�Y�4E�S�� �\�+����fs�-�K,A ��|�e\H_�����_�"�ɞOf|�o(&��%a} �'Af���Ah �P����V����`dXT�/D���瀘�[ Pg�NE}V �8z��bp}��,�n���
B0����y���"hv�s����7Y�[�����O��n� ��5j�#�5%l7-#����>lB��r_�q��V��z������3�Z�)CW��/3'�:�< �ˮ�RE7�����^S���}&��a�Jș)YϞ���Fnfl���I���j��U.��`��w@ZC��(�%��c�����j�
U���>4,OX%%�_�I���]?kMS���-��q=`��_��E�mX��ؕ8�t��[?%�h�����pf��̐�>H$v]���	Oe|�,�4&��hr�v���.�Ax;v�BM��Z��p����Q�RLp�wm����=�4qB)Y[C�������W/|s� �p�I�*��U,�)�oUu7�N�M�.	wmd�;&��yzh�jh�3f&�M���~���F�b��qk��%9�ǀO9�&Y�;/��}`��+�6tq���n�_:��NS{Y�NL�v%xY|h�x�a�N�4>f�2�/0F�	�˯(]��ǂ�@�*���B�"�K�C�=��ଐ�!�ta���4��UWx ��CW?����7���M��a�$1<�V�#"Ms�����\x�+p	��8� �v,��AkV�3eA+<qݬP�&ڍ_1��<�=S�B�����8�h���9�	Ҍ�%J�_���ҍ�|B{-h��+1_ǳ26�la�z/!�I��1F����s�$�QWV�<�@�L�|t�	r��i6W��iF ��!+�©�w�/�ۂ����m�G�0+�2*�9��i6mε�n�z��_�<��8<�u�`��=�i&�>G�ث�z�#���u�q�cѕ9`x�nh�c�n�g4���H7����<���4�H�;)6Hź��7l���|�r:e(����~�`��������"u*baW��4�.2�}��%�*l.���p�L�Q:���¦��6<9��D������iq�#5�!h����Ĩ\�=�G8v���m�P��� �U��g6�3�l�XY�D����2�Z>2�;_��aG`�S=��(,(ʠ<5��Ȓ!
��~ث�f��`��H��<M�Џ'���!<y/�������� P�q�UZ�Ӊu�%��L)^[��mV ��jJ-}�0%	���Bp��nӿ��+<�Pȱ8w�Q�*U�*�z�g�g�U�_�E�h��:h�qQ�	���ڢ`.�s�[����tɅ�e�5��ɕ��G�"71�Ԕ���p�`��K�)5������ �MUeq���w��2Ă�TD�:�qA'�]^F1���#}R����֏��"W� Lz l5w �0� 6쌈0��|^�C��M�'|¢�U�0�����哌s���'�E}I@0�u�4��#+�I^�a9��r.1��Z��/� h��V��T�X�IK�kX��
�٦ލ��$���t��Q�8���f.Qfc��2�T�Q�9�у��ۓf�rÂ�"��'�S�i���	����̥=1�i�0�#����BCtB��>P02�E�^�OGљX��d�=����n�;9q���a�הE1�4��I��"�(D��W,.�d/�d���жU����q�$�[GPX��#�Z�/.GE�Bm.�����я�k~]}.�y��6��M���.��As�� ���t�܇<9���reX	-c.�:�D�?��9S�����=Gz�U�� g�򉏘�W?}W
(*ҹ?�ZL�4�TĲ/��}M�����YR�g���O��z�i �>I_�ú}g�ڵ:��QL^��VJ��~�79�I��WJ���!<����Lx"�1gݙ�/]+�v��=T������ lT¶����$)��[Oz��R68�^9��p���L*;>�������Vp�ːlmu
�?�� �j�>2��2#�:8�e�p-ѕvx�<!��~I@߫��Q'EpF�;Y��S�1���� �x�v�1�H� ���\�(.f�\"�t2^P�� $����Hx*���<.�tfbLX*%7-ϒceȔb���K8��A=��KA<���R	Xݶ�\��#�A����n'`��8�TĚz�iԤ����|4�����So�΋�7�m����?�Kb� 'D��X��A�У��?�7�L�b�=.*�^ʣ�c�^�3m��D��_~�����!�5�y���S�B�ɡI��ǟuW细Tu:D��������PA.����3ݛ�*���v�5Ě@AH�lL��� �H�:+���~�'T]sW�l�Ky2d��/�p.� Q[�$��|���L=�M���d-իGu��F�ժ�<b3-�w(�����@-ړݛ�U���qavv!=�I2^e�y�F���H�
����1�f���j{����:^�������	H�S P�'�;��P_�P��eB�[6,mL��KQ� AÆ����N�{(��	��ApRe^kC�\���_)ax���IS�y��n�(��;��{��C�a��#b:��ke0j-���R,ݴ�,�u�"ٝ˴��U=�X��y��^��o����t)�®��zWj�.�|I]օ��A�n ar�/��!��hL����c�w_���x����~��	0�1��s���������\X�q獁��c�SZ'G���-���u��O�����]�� 2�h�)%�2��帔���bZ�?Z���M��lQ���F���e��(h�L�d���閵6?rh�a�d<vef�8�5O�]8XM_\
�u���Uc�.��ܝ� c�5�d�7�Q�X
���M���|�&I�<�;���Ƞ�H��/�,JZh��xD�(�����d�T*,��������(at"5B
61�cOq��{q�v������r�5��,,O��2` :�t�Z9��9-9�[b�ƅX�@�M�v`\��h��,�,iD�+Η?����ޒ�uM��:
*Y�X���7��f���0#������v~���kqf�����a��! ��'��{h��a�bzi_�yښ�g� f��~�/�	�	d�4�7HpǮ�RQ���Q�e}�e���m�ɻ�T�Q�S=����!e� ���ĆC-�̈́<ٸ����7eo�tL����3�D����zO��Y��4�>���	:�T<gY/I #��0����F��g�V��5�a_�;�6x��Y�����w��x�g";T���|�dkD�`�����pI��[�����=Jo�K��\�%ZS~f�?�7lb|�0�?	����7��#&ǎ9_}c���Aᒢ��k�D<+�t�@���/f�+�� O��3���B_Z+�XZ�JQ�
�)����5�ɝN�*��4l�i�*��S���3C��s��+���U�260�*�!�o��b3yV�e��b΂�jt�4�>�=�Թ�����r���m%�������j[��O��U��V�wG�ۓ	�*��A�qv��`b {+� �*���0PEtZ�-�~��w�G�f���z(Li]��#:KS��ӯ�ºacb<W��CI%ɣ6Պ��qM|�E��6��w����_�]�m�~#�KIC�(���Ugir�t�>�����BĖW�Z��R[%)�+�#�d��A5"]m�f�P/g�#iQ�!N
{�s(pɋ`(I���X�9���WC�.4yW[^|Z����\;�F��n���P�������O���"�� ��e2:�ԏ�v3u�N�p���${���v\���+B���A�	�-��aÍS&�R���PE���� ����D1�ж�͉^���FSՍ�/�0����\vͼi�	,�|\4'*(�3'�&�x`Ӌ*N?a���;!ϳ~c��L�-;��4�~�H?OF�$G���K����a(�Q`r��&��$��x^W���a2$ȏ!A�@�N{���YŤ6u�N�}U��|ƶ�e��7h~߿��щ,|�(?r�Ҥ֋[b��]�g2��)'��r��F����߅g_���d�iy����H����W�- �)����Q��tH�a;�sˇ��r�Ob���R���]�� [Z�U3ql�$��r�_�,��M��c���~�=r)��<�&��|�(�L�����C ��U��+��_
�M��
�q�53.VGPrH׻Y��=�K��w���<9�fΨt��2P�������L����A[��b���?-@��|��A�'y����#Ph�5� �����!e �]�b���7 �A}}�	Ie6�:;w�x����6a�#H����`j��gK�N��cU��������b�x�-�Q��G�P��HǇ�q�-�jkט�����������RF�+cg���pp��E��jj���^�BqW��m��?Ê�,��ՆQ`�����0�b��]�yb��>�N�
����f�ieeGV/k�(trk	�p\����nR�V��8��?F5�y�(����{���	�௄��?v��C��������' �C|ۋ�|e����g�}Sۣ�	�4[u����gw�`�*KФ�8��n��Q�4n�;�.��Vl*�����N,=�U;OQM�v��|������?�We֧����Y�w�#_ vIV��O�Ci�&2
9`���Ҁ֕����`��b$�-L��h��k��{7�Q�� �oE�Ηqgs,�@�9�{-8�pS?Bp�.x
��  �S` ��(� 
������/���}w��=���_���c6|(1���C�#_���5?���(�g��z'S�Z���G?�U�	5��!4���W�Qo ��O }�������u����V�h�z,�� r�$r2�>�%��q6�#2�2�%.V1��OJ�r���U��eS_] ˿��#n��_���J�����W<Hl�5��N��[��$r�:��:z �'alj�˜���:J�\#a���:1�ݤ9-f�ғm&�)`��2�J˒^��~��?�Hi� qw�L얷_d˥��*�o��nF���&� ����(� ҈�tT�'mΈ�5��c}E3���е��'�,��Y�:�<�䨅PYi�"��6�?.b.b1���k��"	��>K��I����B���n�h��*�棭�ļ�x�7���;~��g�(0�a3TO�mx�טu7���jc_����ڝDz��wW�j!��ּ:����P����W!�٭��{��m�'���N� �k�F�p��Fax��3uvw#Or���'C�L`Q9&5�w�(���z�{TM9@�L�W$��<�͢�X(+2�"+Ȉi� �w�#�$��́���-]�����W�+�����d��b��EWl�gNH*�'�X�˪D�$�lx5j�1�����~8�n��5��_k�[ Ö�w�Db�(:^�,�SV��e��I��SI��jqO@�ȮR�r>���Iȅ蘞�T�gE�kl��� `��� ��0(,A=�β�����M80���"�� ]9$0L�t�z	H���Y�'�mӓ}G���b�VP\�_�+c�] Y ��O�%9l�u����ܜ��U�)���q�ϟw�X�ە��y�pEU�r �K�IņӶ���,�<�MZs g3�l~h�ͣN8}9�7MD��SC�,�z�cc|����BT�S�[��/T���[w�3��ԟ����}�^�fIGz�W�t�t@մ�y@V �W��I|�]ͳנD�;�;���CH	7��ajt����0P��x��k�O5)�Y�B˫�0C�\ߛv{t"�z/_YV`�,����*;��7�PD�Ǻ:Eb��O%�:p�ϐn `���٨� \ݧ�5�p�k��r��]^����
��e�r[��f1_�>�{6�����a�&�ǳ���1�t}��F��ݬB �crzŸ%� Bo�`8�c�c�ݫ��gL���K�`�l<G�J҆�s���=����ɐf�������Q���.��;ݤ�
ٯ�[�{o�t�Q��y�U�x������.��ʔH�..�.̈́�-�(����|��f r���0F>li �w�Ž�c����a|�j�l<z��<�!�b��T����hvv_��^e���/.��=��ٗ8OEi6J�������H�6v>���]3�Sopi9� v��P��Y)V� �>] �zY�f ��.�qZ�*��j<�ש7j���C|҇A��$1�-��� ���GpW����fNY�;���*sj�����kv����y#nL]7����k��:bQ��s}̷��/� U5?����V8^��b��5C��Z"���嶱�)D`Q�����rb�I���:��[�nV��K1�ǒ,�&��M�P�ƃ�:��g"�$�!؊z�~e�WY
37|�[5��!�ǲ�.&��|���C_����}�x
v��E�? �«�g�#��0M��!�]K���A��D
k�E��/�(@Y�����)�G8�5qa��T$#^^=+���,F<_��8�H܅��vU�v-��i5�	�ݗ��)�QP �
��y��Eq�]�V˛�����Ռc4��@�@��mܕ�"aWj/^�̊�
�Ϻ��(7?���rեrb��B���w������ES�a�BEz�`��K��'ju�WJ����Q���t�,8�"_K�	!����hP�Y��]w��kN�2?H�|d���}�0��l�qi��#�t�����
vsΧo��e��R8�2a��h?��-���f),_<A&�/�ґG�r#[��lT����M1�ڨ϶�����qn���s^�[BL��n��2�[�rD�o��f���g���ο����+��4
υ��@��V�~F8���x;��Ҕ�~��XRE�Y1y�"W/I���Nd}<>p{p��{�S�d�O��D[����l����*��nO������Wu��R�X�Ԃ)�P�LK!�Bd�EѦm�j�S����b"�! \MH�8p�V��j�a }=�N������f�B_=b��>>vtm(#�Ϟ��*���
�R�u	�I��I}y������n9�kI�5��6�(�9*`A>�q_B0���)��p�~y��e�'v�V/`�q�=�ؼ!PIpXZB��+$�M�^���2�K�S��\�2��VSM�E�Q��bmwK��z��{Me����"܉��>�����ςV_p���×P?��p�K�[~��=�coNl��<L���>�5V�5$"�� �B�n�5���|rlM(�iM��S�HЍ|)5e�*9�e<��N���ZݒI=�^�y���@�E\��)����0p8�D���I!cM?���h9��e��9�Jְ�r�����}�Fj8HnE��Vw�D:��g�׸���M��9��E��$ߎq�&=6���F
���\j�D�XLӂ�����7'J�ޚ�,	[Q�x߿K �PI�R6��(��߱����qpN�2�t,'��>?�\E"�bYh/ǰ�U����VN����� ��3�D���M<�o+�&��$fj�9n����8�o���\z	��ȿTYT=.1��� ���C-�K���ό ciW3/�����pN�Nږ��g��U$j�E<H+C��+��i��t�b!�u���kd��}��'N��N��H�3�J-�焟3�T�ic8���Y���|�~���ZL�F�����ƸQ,�G������(#�cjJ�{��}��^L1*�z�,����|�����N��5d"�d�Y}_mN¿�qx2���b�exT������XG��+X�9���W���NQ{�F���/`���>9ؑ������p,��"$��&�'�Ŭ��脰��ᘑ�e�^��)JX��}��)r9e�I�.��o�
�Ƭ�񍞵���"굎E����B˫I��8�
�u8��0�
�<��@�,�LU��	��<
���9�O���)�8V0�S�%�Uy>�JU�~'$��ܥ)����L��'�I�[� ��p�7�R�pDwy�ŕ�B��iZ�������τ���ӳ3 ������5�[\�I5ܜ��,�#�W�Q�m*8mќ���-����867�u0~�=�,q�����`�uݺ�Y�#���t���l=:GIG!�L���,��"�"�X
�_���ڵKnkjDuXԍ$Y��(oP���?��ˉ��Pg�a���x�c)i*�O����D��y �z5l�)QgSI��T�ha,���W�3��6�a��1$��\s���/�Ơw����l����^NA�4��ڒ�t/���!��]���
�MR�Lƒ���b@^j��Q�@R�8��"���1|G��L	9�(�>�\nҖ/Wg�����h�;�P՛}�N��KG��u�{M|��Ĉ�X�rw�����A����Mr;����Z��ΊUYq�x�TϮ���x�"~׃�75���M6.�8���r�����#k��q�;��p�q5����ؐ�-�����ƙ�T�Ђ��B�ǃ�F���%!"�{�����6��G>}_&]�؝���К�SS�g�J9�^>x�_���I[�|#��{�.g+F~G�d�DSx:�1
WGm�1���N�ॾ�,��
���D͝���u���$���s��� >iù�:�QMǮ�i����Q��2T��IJ���X����%�ì������PY݁6��[����/̵�[��.�^�;411��#`���S�����4�q���T`=�A�]�v�7�H�+}N21e.����R Y���pAˍ��Y����r�����e���fP+ycb(�m��`���h��e
41ο�e%[iF`6��|%�����z_���� o�A,}>�5%>��������i���HW�H��\[����$w�g�����]0ɒ���eV��(1�r�'�ZW��?��*�.�@³Z�/Vh��8����_�{/"e�W��&����EL��"��
t���w�cSΧ���7�6�b0��@K�j��Nn7I6*6K[T���x'��x�$��	�"��u��e⛕�HB|"���㤓g��ע�a(�OъF��t�틳P�$��#�BHo�F�D6
���	ߠ��_;V&��B(���| �:?L�@�^���&��e���[_1�P;�6!��{+���s���Vm���%�������@�BWo�s_J����\���F��r�y[~]��mY�]3��
���E��YMè��/B�vi�������%�y&v
�]j�l�Ծm��F�&��,��b��񔁬�V��G,�m:�]���'|�����r�L���7�|4�c[�ۖ��[9�
�H��X�)%Z�Z��������F��<�&ĥ��i�D���nD�S�uj��/
��@A��3s���r���L���~�T��;��|�еL�mT�eh���N�����]������
'�d1*z�r����QMX�|x}%�r����$�h�Dk���[�=C"� Q|�Ge����/�)s�'��~���\ ��)la���+��/ T��++����0�`i/�o��mV��;�SWJ��	��\zP���
���@������@��0	P��dD2 (k	����@����.���`�pxi�l�&�/ ��0�����k]�qr��!i늵���{��A���,��7������i�r�i��n�M�Y�@(��̉כW�	D�{�j����q�������$�0�g�ˢ7�e��ئp��� ���W�Cx�/V��p���T�l�}�t�]f&)a3�~�-�'�� �z4Y �c�
3�]��oW�����6K��kr�Az)�H������"�԰$1B�s��T���4�Qؗ�yM��1�;#up���Ű�CO:C�`ac9G%�L�`��)a �6k��z�y3c�|���:y�w�2�HO`�Y���'Mųb�%�EH���:��sv�b ��e�1O�.�_����2�>��
G�R�!��`�@:��@Βl�ofU�.��?��q/�l�C�i��:���E�_����z���{X�Z<�iևj�)wB�<R�+�)�<m����,��C����4����zk�!��`^��f;m/�~ăVg],W�u��J&��F+���c�t8�ӜF@�``N���l�y2����Mꗹ�Nk�)0��HD�qC&X�ДO6��޼,�{�6Y��nN	�z�D
��l�ܡ��ΘE+�O�Ԛ��A����K�@�ˮ�]|���5�ɿ��(W>%oR�u7$��.r/�ƿ1K&ŷ,3m�ȭ�;a��p�}�g³(g��(?��e枦oglҽ^�w|�����(o
��CLy|��r�Z2d������Y��`��	)\�p4(�yh���C<�e���1�ʵ��8u�D�[����Wc��g\�k�*k5?`����R������>�a8���KM������bb�Rfu�x\�ϱk��w�I޿����"�D�q�
�ޠqC��ɖ��or�B~_{���[y��%3 x��ȩ5a�Z\.(Mec����9� SXpZݴ�I{1מ7߄��Q	Z���G�'�>3��:�7�9�U�Ղb���B���E��e,���d���Mq:I�)Re�7yj�ṑ� ��V\�Z�!�QP�u#	χ�P�0��{�*�҆aUL�@S{b��/hkw����`b$�H����Q�b�'鴤F�ؚY��:�j'F����a��P�<�lGG�F�%|���P���\�I#9�p�9�%���XT�ढ़��2b����W������\�4�FÔ�h<��>(`58�`N��.�70C�%��Rs>���fs/�?KI�+��i�K�ͱA5z���'��[8 *@Q����e�����1�|��6�2����p��ZO	�\�������+�EV�M���<#���Y�Hm�w�id�И��蟟#�B�?���(>a<�_U?|�D/�?F�!�H��Bۄ��o2ޗz�*�/	1_�����ӛ�T�vf�
�Rm�����q��:Q>4��b�N�K�#p�'ۊ��@��7��yQ�3s�ASF���ZS���6���*4R(z�P1�Lox�h���#��7X8ȑ8�����UPbpzC��=)�����+�l,�;C�9vH��A��L_�}'�_�#h7��Ԑ�����2(�<���o��㢐k�삎�S&m����w���4�Z�H��B�q���1�<�L}�ߴX��/њ9��4�E8Z��>��Tu�F#H������A��'`��|��X�l[B3K�*p��� ݓ#�Wm�3�gu�<��B����pI��7��^	؅�eZcO��T�Ʃ�<Z*���ւ2�C	c=tk
��[���!A�K�ml��P�)��y�����K\Q�-����.�t�[��:}�fY��!��׶��f!7�˟��\摦'YKI��P(�/���q�E=��˜��{���-WrFM����? �%��p�狭,��$@bo;���ȵ��s7�"����=��2�{#�9��U�n�����ʢ�7�,Z��jkM���]8ϧ)���zC��+ ���@
�������l���d0D���)c�>��6ġ�G:M��>�)Lӛ�w��cw,�Z{���u�S��>Է�-���y��F��Z�,��{�I�ȴ�������_����9c �9.^Xh��0����W\���H�ma:���X�|���@T�By#L�/_���n�����l�5?��P6_g�qo�+<V_GJM	�х1rVq��f�%b��p�)U��m���H^��T_��F�OU�2>ފ�Q�<��f�.(O�i#�D 0)H�b�#o�0
3��Vx4�}�~CϜ8����޻׀q�F�����A8&�V@���mj�)n� �!��U��x[���4�u"[��1F;�K�����X��?Fyk���1R�5I�8�����'K��)���SG��yZ��mAXA��Y�#����Ѳm�3��aP�&A5�L)�)�C.-o�݀�+"w��jJ0��.N�<0�H��i��{c+�@J�|�클Ne�M�K��.�G�OuڒxK�½�KK�� wY:�݆_b�D�2�B�;ݥ��]��T�4k}Yo��"2�.��x�St5�pA�Vإ����!M�/�T�	5�����A���'��$Id��s��O�渞����u`~	�kAg{y
���l[�#. ����+�݃6�7u��%Jp>0ۃ�c�=V{�������$�*��%�;/�ӄ����e���Z�~�#۪x�f@�P�Y�0���ufـ56c?nG&��y�?�[��i� ��ю��y��z癠�i�0 ��;y�wP�8���5��@.��꿸�6ѐQ��G�I6�9⺥S[�w4'��%��M��D�|N�hɛ��)0ĿE�q�?3о����l�j��A$C�� }z�o˻on��0ۙ,�L#==jjmjD����͘���W�T��h"�IH�a�r(�b1�a�LB>i��l�(ȋAF�(�Yٍ�RQ��� ��H ���gc���YD��mۏ�S�Vl֧������+^�K}���>÷���X�im�ǿ��w��u�'��+�d�B ����Iee�k�8�P7$@<�~)�f7ZZ��"���g��*�2+�����
�������rS�u��߱�_���3!�4� ��(`�Z��Gʩ\�����1�DІ�����~3X@��Z��H����|�
��L����8hw�́t���ȅCT$���Hq�]���Q��գy`��SC~N&#��2M�
k[�磈���h.ԁ�<�l}Դ�K���Շ��� %�*{*VM�_�.�o����������D��]�+�(�� P��3�F���6I��{3�8V���5�b��xF��(%�&8��g%q��750�*��WM�Ŭ�h ���!U�ڶ�0
��nכ[�K��g+).R߃�F����!��"f�����7�G�s)�psh�����.��A���8�l�J�Ǥ=R9�f�C�d!C>�%����	x�i�	�Z�$�����6O3�{Z�7���ˊ�������{�H���J9�7�tz�X]qog�P:|����(?�.��
�@��k��W��ǐ�����8����m�3�TԠҬ<"�ƻշK�Ѱ:CZ;� %�5�w.���ZheO��5��e"�w��"���2AW��)'�OKi� :�����g�9=t�N�_��]ĎmuZoH�a3�.�cf>M/W|�s���i��ʗ��W&�������ƥ���	��ӯRfP�����x�?0�0��P<iRc]�f���0�T�r����<�?M��'�;^F��t�0B�0)��,=�71�0�����L�r�Tp;����i��;/�����h�j��z�NÀ��G*�_o���Rb�1d���K꾭ϡ����s0��\��A=Sڇy����}�o�o������<o5�U�IK��h�a�����J�8~�<�!���mpr�W��\��5�@�H��z++��H?���S�`���5��J�l9\��<m2!�8+����ř��~���Ƣ���=
���a�T��y�Bt?���F���0Ʉ9WT���k@ޒAG�٭��g^�1;�Xv�HN�xo;t��������Yb�3Q�����~YY��V��w�}ܡ%��̤#`��*�;�jG��d'D6��If��C�.�v)�d`ԭ�Vu��
��U��y���%)>K��D�4�n���?Tb���vg���#Wm�R�Þ:U篜C�L����)�g�	�?��Hϥ��3��5��vuք�onM(7˔9�֌�R5J��p��Ş��;�O6����d\઴)
��ⵐ�R$�/�Cn���&��P��w(�}x�eO�6X!��o��t�I�%��g��rɈ��%�vf���� eK�Ʋ���6n:822�����8��Y�3������� ����V�1�Ft�ugF^��N �c�뎕��NxTJF<�/�^���i{���N�8�&P7N�����.��ؾ��c�:��8%6_�oa���L!�f�*/A:�|����4�v ^!onK�ev�7{ygG����>:���� �d��!c�����p�Čp�102RsmP���OE����n_Yo�fsʡ١��50��u� �㌦��m��^�������.2o��£�Wѿ<@հY\��
l)m����m�><���UI��L���U7�Sn>�j�����|os��@��xد��h]��Eu���4�4"�\xb�'z�ȧ4�W�rY�غ"�g�m"��=I�@ufh�q����`�<8���XRl���0m�$�|7b,W��0��و�U��R�Q�6�z�c^�����ź�f�b�KQP�7���v�$h3Ӯ���������&��~���)�;���⅏w���^�-�R�
Lc��t�$Ǫ
]$��ɑ���i	r���S/�ӏ��L|���ܼO-Av��b��:�  �(S��N��'+��jy�&Ѥ&�:]F�)�G�	�J�l� q��y��'?M�98x`{���*��rx���d)<�o��n`�k6{O�v�B7���g�U��jb�cF�d���6 ���fYP��B�}QM���ۍtrM����x��N�ۖ0���ۢ�b4�XK�\x���v�l�X����h�V��o0�[{���Β̇��bA_�������m�	I��S���g�zsm�<�ܻ��|Kh�qi�ե_��T��l����wĜ�G��<A)�O^z�%�O�Ęv�#e��#>E�C������kC� N%Њ/u���v,Z��f@��0�Tmr���\�{��%'bp�n�Fh�#�g%EK�������a���
�k�+����s�����j")>�l	��<����ß�ʼ�-He�s݈�l-z\8b#7!�Xc��e<zb]��ED�'+���A*�E�p���ʏĨ�����U��̰�Y�0�3PK!������lq�b�H�U�������T�&��j�M�Y*fU-�Ѫs�ut+~	���!��J-b��N]�։�V#Q-�6�����؁�[~� 1x¡'6?U:LQX��Q���u�0ME��8&����VQ���mq��O805�s�КR�.~ɰJ��7o<�L;�N��E��{cí-_����SI�p�M���}���I~��!�<��E[.��l��U�9ѓid�9�w�6��T��RD�j�{�(�Ɣ�����;��kkm&���uWt&��f�����6t���/��c��G���O�����:�F� #|D��򙳻��J�@���Z4�0�E:W�Ff�g��a��?r��6'W���E��d��Ib�0�4Jϭ�&`pE��Kh}G���i�N�{Y��4���z,vq�K�2���9�=��<���\�ۍ��_�ڭ����[����!��t��-ω}�љ�y"X,Y�ܥF�L�eƎ��ҋK�@�V�G������D��(�b�Ye����������-��PS t����K����!��~�eN	p(%�T�GN:ߍ3�E}��N8�!ͨ�hBl��fN��e��K�D`�7����jѯV���=���}ʳ"��a��̶Ϫ�g(psP���� ���ve���;�po��쏸 ��R��ך��6�'��⧪In��V��������_�q7�q�@��W���[S����?(�ĺ��_M��j��d����_��[�͎�tP�ԑk-��c�d�Y@� l]G/u��ID�(;�3�PS8��CX��R��z*f��(���p��8wΫ	�i��)@q��C��=K�p(۔��h�5��V)*fA-w�]͈o]��ris%w�t\�}�\p8�K�d4��X7g;6[�},q�a�Όv2V�ب7�,�\~o��C�Z�f&1nY׏
}pe1l�4�6��N )�Y�[YӾ�V�Ja�Pr��Z�;�>��y�w�n�lc�r�!�q�e�2�j�-�daH��	8|������#�n֦��{	b`1�S�ם�G\~<ͪi��z�Q�R�I
E^�'�0�'����%��.m����vQ��Z�����&��/�.�'����-v��gg���
�_�æ�or��*+�G���29o�O
�����S�����I����b����k����n�>V����h����.�hy�55�D��(���z� ,���vp纆h>1_`�W��Q|l��o:�y�];����@aH�dp�wz~u�G!��k5����	��X�^n������z��\ "	,C��MTnM��OdB}\i���U�
�)��i|�qv�uW2�r��{��,�P&z�{���\���i2����� �o�$dM�!B��
<bW��suh[���	&�w�����|���fp�����.#����<+L�`"�%x�ҧST,�֒?.���+%����^�$��ya�eF��K�2Ԓ�a裉��]x}�=`�tzL̦��%B�m�;~-�g��B��C��X|w�i�:�N�l�<8�BV�k�%���A�q������6��FP�_`.��;S���SЩ����^H�Lb�M?v��ԧ-㏠k^�y����v�gݛ^nTO����z�g?Y�(|�D�C3�@�pgFk�d"�T��.���Y\J���j�?y
xY/�!*�7m(�"C�Eoԯj��>�F�Ũ��EBg�������2�IPo�K���� !]
�V-v:.DD��٤�{�w*`��F��ݻc�ߚ7�>�0�D��*Ջ/�����-aɐ}��T�:������˚�:D�y)t�.�gCK�P� da��3�53�^'��T�m�"�i-V����ɦ�p7^�3���q]!��5'�=�UO�3�_�̤�Q֊Z� ����J�e�V��Ck����R�cɪz�$#9|���\��2���y2p@Q�S}�KR��QAP{Dz=5�˹V�S;ۨAԏ?^9	�q��k9�x��3w�!��qڞ����s>�	���� Èم�$�
�3=(��a�A�	0����76�B���%���l�'5ƀO���Z�ny]h�����>�'w(\�z@��dx*|I�M����������"T����)� �;nsj�f���+�� �v�|�.Y���CP3{�0p΁36eIɅ�V��<�k��r��ɧ�� >BC�Q#K�.[�/�[� 2&�[9��{$��Y��'?���$O-�}��\W���Ld��[L�O��J��+��%}O�e1V�g�������\�P�|q8�Oyh��>n����0>�V�����(6��33m���>�¤�15����0ʧ.�*�_G�e�/PH�#4$���6��MV�&KD�;�r�����Pݿ��~��6��'���@��U	��tu#�V�����t/ې�P��2OER����!?X��@HR���F��� �Ja��6�ca�n����=Q�67��4�ofee+X�9!4�6|���i�V�K����"b� ��;�p'R���T�WSd��]�^>[��g3X����!���x>����H�I󉠝Mc�PG�[������zLK�fY���[q��rގc����z���.HN�^����]�o��ID:�*+�
��$�/���ݛ|�	��+z'`m��_�\���<�T�i�0��$_��	.��!]:�4�q��ÓD�2s�d��B��"���-��N@2��Q�$K͕�AWp#�!;-	m��%6X%\*!�9N�I�7`�p|z��evG؟U>�U�f`�� �I��,�ee��6�K��z?��M�D�T'a[0����Ļ��9��ݜr�[�����F�;�+K���U�	��? �`!��B!�Y=�}H��9��h�b����r������5��:�#{ς/%��S�p����~�����ea>Zf��ɥ!G�G�v���i����\3��1#�k2{�3I���\^�U��W�e�� �8� 13
bzy�4��}W�`��DX��&}^K�E@�z/o/��}���䌚)�=��2���OM�0�$R��>/�k���r�����������V��\h��eȐ���2Ur����)Н���R����@7���ӝ��7��:_+�ڋc��tJ1�Cp�6l�h��1��)�������ǔW��(��Ң2z�cT����|#+�8�r
�yi[_����2ʟB�}��2��ڦӘ-n��1���Z��a����V�صJ?�2�G�������H������&i�&+��`��2b���c�FT?~��ъ�}�U �3��OVX���M|�+� �qn;�rG3�;_��=���C����jW����P�A��F��j�w�J�����s�*���GC+E���@r��=�ӓ�D�(0��5.*q��Ĭ�0F��!�/����BYi{�^ɷR%>Gl��ǩ�D�~�/���h|ً��<{X�*�j)���v͠K�uQ��e�#3AW.��(�}Ŵ�:�lo��,@��U��A, 0�w�-�%�㹁�\�0�߳�Q3V40-��~G��]Z�K9��&�k34'acy_9�*~�_.GK�Mx���"F�S�=e܀f�i�Y��E���/F�������G���a��n���i�Fჱ����٩�a�\sRwܫ��n�H���"����"�G*�T�Z���>I�)���[&�2��|�J���"[�/�XO�2���pHNk�&v�9��
5�6���M�7/�||�����3����r�4�	�SЧ`��Ev�ϸ��Ge.H0��4]7��c /P���G [���i�g��&֢M��vO`�6"ظ$k�9m�|��F��
I��h��.|y���Ø�F�Jp-"d�g3��@ڻ���"�u�$�+{������\�Z	Wt&�1���4򉝅fA�lA��g��D���4n��d&N�{;T�H^e��E���.��
6��a��W#��K��J�zz��E0�$4�m�� �kDPП��$2"FP(���c`������FPy��0K� }]I�̃;
�9iN0%�ԏ!J�I�� �q%'87%�NˈF��O���o�v�tў>��}5�T������;e�<�pț�����uA�;�̐�����W����V�-���Xߧ�i�=�H��~�����u�W�Q��f�/����o��9�
]E�3�H�%��^��P�/�-����c�5��C p���l�0!�γ�3y�U����Z¨$�;�!,�PB��j���!$(m��P�\��"��+�� aFHh��/*j���/�����]�K �&?Ѽ����X���i<����$�oS�i���j�pAZ'^J3�|~[���V�P��˞yѹ�1���:����J�0���FXχ��t�/-W@6y�� {C�%�hE9wא������V|�$�%�RJ�Lu��{U5z��u�%��Q/���$�y&<8cg���nڭE�}c�_h_��t���9�C�� �U������I�������ϰA��,�w3ǏtX}�P[���F"SՈ��7�������M�Y�S�7��q	ɴFP瓗l��nB���M�_A�v�6��#r8���5u�����w�%O�&���i6���h\��az`���ڱȭ��hz��(��/^d[�6syW;��I^ˑ���h-r�RC�Jwe��!�ƫ ��ްq��Mv��9�/��k�*LTj9�C��T��}��o����_ڬ*�	��o׶J(ڟ��9��y#���s<�Ҕ �c�[A�*S*����WH�^����@�iځ1�ɘ�F�������D����L|��o�����%�7p�u� ����ߤj��f��Ł�~�3y�t�[+�h�'�5�Qza,�
�Q�j�� ��� %���&H�h��zc��x ���!+*��>;�4}U�O���F_Q�*���t��v�_���C��£Z��o�Ρ�8�!��d_��'�֥�D�!L8�Z��&��g�}ԛ�k�����ɕ�8O##dt��hF�	��R�G�k��|�NX4��>#N�Q[ͱ�����I�@�������WV���~#���[�CB¨�}��nJ(�,���T��O³O0��'��O�*e�Œ��6Z�~�t�������C�o�*@`����UF�8Iil������ ��=I~�v\�|bT���P�T�A<r����d(q(*<�Z���s�-P�ۡ�J+cK�҇
���1LJ���:XNr��P�_�a��{��Z��z<u��.w��ʚ������D��c r"�B92�-;pf�E�2/~¶�ຜ��g�Uǃ2�0�#ё{�	���?dv��x�'�YzӔ��[k��z���ޢ�B�4!'-4M2��
ݾ"�����\�[�z�0�B�/1��U��b���Y�ʓ�~�f��J�.7:���^��F��>Ю���^���M6Ό�z�(���0}��p#���>7p	$�&@�H{�h���+C�x�q����+_�L�X�P���	�egǮ���xn(`�Ǫͦ���T���V�V:�H���~G�>�)��?������։ܯ;�������tlE��D�
�L��o�~�<��A���n�;)f�=�1�^F��^�֕^���3\�R�_�1(\7�p�|�} LV~{����,0���^�A]�2��K�e�^���-r�X$�M	ᾢ����.��ͣh�;��i�3�^0w�Iޝ�⡗���1�%6I�EP�+z�m��y�t��,jh��,,Ζ�]��#�d����Q%��(U�f���1���^M���q��K <��z�s�t�_?F��
�d˜T3'��$HL�����9�:�)�^O�%�Sa{���QQ����������(P:�Bg��g�jXs��c�[���A�Aڟ��I�^�G���@䢿z]����0@<G�7�-s40�s�L0i]?ϝ��]A�({+.�*�i��SF�U.���Wq��G%�To��w�^Ƙ|�K�J�yZ�W�P��ʬ'j�/�=�=+���LGE~6�H`W�����]��į6ig���0����ߕ��P�F�c.�e��r�5ks��ʀǔ��k��~>�\m�J���Ob%Ȱ\0� f>��\���P+fUѽ�"� ��8��-���6�2��%n� g��	�t�>7��ڤU��Ԉ!�����[v�x>>���&�Ԝ���QowJj�D`}���?�����@�B'�rO�� �?����/�p�͋�	��^�R���M�2���%b效h��s��}+}���}�����o���Ä�;*�6#��]�D���*<��Rnж�qp�e��-�̀�E8s0�jAc=�,�A˂�aLX�>�������A�2&���u��c׏ ��\���s?=�@k�[<S����sh�i�2�/4;6k%|�v$�[��+Ĩ��Nix�7k\6�?�V�*J~��㻽f`P��m6a�j�������y��А����D x>�t�?Ys���/y%i��k!t���!�+��z�d�T�>5��׼�V�z�`��3��j�#?	庪H��P�9^�,�0�~GT���ODU�!�-jO� p}ocJ~	,����ߐ6J�'e,��(��P�l�WȲ��Dc��,�v��\����BLf_�z���7e����~��;:�%I�lj���m,��������I2�fȎ�HgN%ߌ�nhE��f3��i
d��%�]�Z�^������I�Ç-�}�t�B��9`e�ϲV2dK�R����&~��O�%ɰ7n�!�b����؇S�p�t#Wc�̧
�!7�,vFG�:�;��\�'�M������,ER���;숊�U��`*RWV~�z�u~@~��aWME��� ?p
��UJH����;���� ��J���ߔ������\�SC�2Y����m�.
�Z�,a���Ǜ��D��5l���n�9�RT�S����sX��?�]��hAɦ/������®sJ)G[��$�V4z {�-Zj��$~MV拄��i5	-�q-9�����4�喐e�c��I+�.��>Yv��!W�c���xD�7ct���q^�~@Q0B�H��nʹ�����ו�+�[6���w�ƪ$�i�<3� �J�7�a0��ndM-X���oϡ�{S�
���H�ih�����J��p�d;��|'B�k[+�}G;�[cj���t�O���^�6�דŴ:���T'P��� �1��:�V��V��!���q+3�w��f_��z*@5����m��yX�8���>i�_n�S�H[�-pO?
���N,�5}lOA�6�~#�9���G &HS�z!�A�j.����vm~��۞acK��rb^�c�b��FZ¬�Jl�B'�(�ҫ���Ք>6��?��Y]k��יԸ�x@0�b�s�2���p��sPqAqqܜEf��~�<�q�q%zb1�7hw'G���T&&��W���eV�����C*��"G��;L�99���}�,��֭�!�����'�4�B��=X�N��T�V�9ab	CN�Ä��/Y�[�i¢*w�w������3�����1B�T\��&�_9s)�y��q��7��^<bљg%S�����R=H���v�L1_m�#%���B?O�/�˨��q��������mqȕ������v��A�ݺu�%��+[�������B�%ؐ|�l�H���Z����4*&��5,N�K�f��Ө +�GLi.���h���)�)����4Z'�4��U-�x?�2��K!�g׬U���)k_7�jlR����[�s3M�BǑ��S����i��B�b���n�8Mȅ ��o���k� 0���(i�� ����ؽE��g�    YZ