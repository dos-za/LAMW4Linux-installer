#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2960554833"
MD5="38aaa78501ab3f41c826cf0ad01d0312"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23016"
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
	echo Date of packaging: Tue Jun 22 19:51:20 -03 2021
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
�7zXZ  �ִF !   �X����Y�] �}��1Dd]����P�t�D�r	%P%
 ޶UnG_�qǖ5&�\�t�M�۟ Ǐ+��3\���Q�͟���4���þ�њX��K�L��� B�lS��b@�yU��||�!�%�ӹ{}�4�?�8��A����S���t���c@W2��jd�+�`��0%�6��9f	�g8h*�y 8�Y�]5��h�SBn��A�}m��u��:��<iX�$�����h�1�}Q�O�'�?�=��F�#b�ǜ��>�=���:�6(%:�y�D�t�OR�`�_�W�(*ב�U4���QH��c��^Xb\A-P�޴[�UB�s�Y+��k��p3y�8�Q���q�i��Ln;b��h��s��Y�A���/.�Bh�2Ӡ�Kǐ��uW�����/�"���>�?'Yf�J����H~�y$t�X�҄�o)�By�rV���`oS>�Oآ���ښ���J�A��cA���"6�ֵc��4�_;������$����?�FE�h,iR��r*mU���W&�xH24��W�xU�<�Y٭v�Zjc����̾��~����F�� 5	1fѺ)��J��ߔ?���x��4�q��\f�}&"�4ִ������̓���3$]ή��~���[iQU��ˉ#�J���>|� �鹁m�U�(��w��w��|V�OZ�J���ئD�{8ȹ��)�͆e�����^3�W�e�-�G�9�M1��9L �m��OC@�s���z�b�"�����!��E̘?���ft+"C1ȅ{+m�?��j�й���9�8E��32jI�`3��6{B�ՍbȄ�1���N�\x��}/�9�u)�,&�����p��'�~��=��7H=�d�IGa��հ���l�D`S�E;�)�pT�ם4H�U\��iy�[q:ǘ���ai���-���6J�����İׯ]�"����|���`��NmOWYA���<)��O/�q��u �����pJ�����0�=!�S�!6��H����z�ee����rB=���H�Fn��P�ΓI�������I�#wNqb��l(�G2:��\��P�F�V쥇�Gb���:;�(\u��F�7���C�����Sd�A��0�-WS��3���Y�A|��}"�� Τ`:���&�r8�;Oq�>�9�-A{�bouj.`�&u7'��QWs��Ġv�H���������0*	�Z��痨\����j=�\�FMT� �˶����_!�8Pt�,�<f���nP]`���M��p���O�}���ot`W���&S�(g��5��ƽ걓�&O�Mu��ڱ�3'U��(O���-���&�����j��� �G��HZ�T�o�G��)�2 u����j3��k�#Y�t���=�a�PW�5�	�	J����K�^�s�o�&ӲܻK��t��Nq\�ȶ�-dQ�
�Џ�(��Cbc�7j�S\�x�5(�+n6�,��q�u^h,��HdY��`}�1��nwo��	�Ӝ@��lL�ʦ=/@��:=ӳ�e�>\Β��{�
#X�=�(��L��M�\J�hg�9$��[����Ī�x.��~�.CvU!e���i��r��K��U�^w��J0�HgXK|�BbEvjva���0��e7��H�'�uj�H��A���`mw��'����Q������m	� �4:bU��L�ђ@�jf��x����!��0Z4�7�5l��SB�%?>���S�q�!e�L�`�� ����a�"�E+a�L�)�~%q�k�mѐ�����cX�r'��@~	hx1�E�iS��E���&ޢ�^�yƩ�*��20�m��J�����5
ch���~7a��]�<q�ѐQOy������^�?6�Y4��9�9��F=����a`.�k=ql������Mp0;C����̚�Ȍ� �2b��2�{�N�2j^�H�<}|�+E]XԈ��O}��ԅY��35ނ�)�RV�f�5��v	��#}�jT�a����t��w��)7�|m�vc5@������l�,�A�6ӡ�I���
.'�ܾ(���A��Tm>�d�ߎ|54mc�dJ0s3]�d��F�sTtm�z�Eh/�L�v]-�x��b�w/oL��P�W���`��?��4�:y���E�!�P����>���T���]�0uN�7�/<� 2�IMhi���I��AR�
h|x��x�5j�+mYB��W�yt�ie}��:+}�1*���#�ċ	�Z���O��O�d�1�*���JS}/_���M��� ��K�A��u�w-x �<�66�>��lY_�=�r��uC���7H�E-�\�|���	v�y�iQ
�b��&-�Æ*�5,�k!�g��r+�Z}?t� ��'u���)��6��	`�������
�U��>a�[�N:��Q\ĸ��L ~��Ң#k$H@��WZr���X����o�=���싧P�{
��:��9��M�9sh)����^0Q��Q�BQ��X�,���[ �P��DY �b��b�p�P���{m^Z �;�� \�VCX)����'7ȡ�����g������n�`{��'y�	���I��~����d ��U�6�����a�[QP��;���N���_|k
����*��|��Pt�X�$%@r������Dl �;�����D�@E�!(�o�L��1��f�e�9�3���NI�Aь�;o�9&��V����_�!$-%*���֥��2��o\����)����6i�E�L]��^��rO�6c8�I�[�{�^�7��V��ng�c��)R.C����>nL��y�נ����F�4g��S*M�a�5�c��@�9�x���sV���Ԏ]�P�wuy	��AJ8�0},d�/R�7}7�B�7Б��Ӱ[��( �_7�ŏ������YG��f���v���ͭ��]{�9�h��5��L�*_ɨ�"�W�L��;g�P,��	Ў	�����K�0�
���_��Q��R������1���Vt,�½��Ʀv�`EB��U�6l��/��i��>�P[��c��F�z��d�D�SI��U��V��+�B{��ibA�3� �kT:�Em�����H<���8Ii���c/-�vPV�#�`�DAA>��G��rfIC��#�Þ�˰��.Ѽ�zZ�#�lj����hlj�3���M[iH���0ezL�I���р����S���4��zd�m�����żp��`/��6c��8:44)Շgr�r$N��l>�D�5��X��`���D�4����0A`9ԟϽ�b��V��x4ͥ�{�.ΰ��;J4:x���^z��ܞc���S	<z��ʋ��"#��'�����Zբ1����r&+��<At�;�Ÿ��@�����bF_+��������?0���H���!+4�ܼ�g��j�>0d�v���r��V*���۳����}P�g@٬41�S�Y����ݠ���h�6y���J��@XF�;�h9lߢ`/K��4M�R���7� ^�y�ạ�HD���i�l�m�������OM�/��!�r���mz�Fؽ`C��*��7���Z9��B�����0�����!�Y6q����kU��zf]b��G�޿��5:́U��\d���׃�,�����a�>�`Ǝn�4N�;1X�u~w��:�f(�����k[	G0�����[��+Ș4R,*&-�?B�Z���8S�s9�'������-DR�!R�JL|�1�r��i��R���FqU���Z�J�J&�S�:��r���J]Bu8ͣ�2w����L.���t{��'mg��B���� �7���(s�i71{L.�#�#�(��ơA�J�hs7M+�������C�u]�=T3X(���=����5y�hYU��9�ҽy2��Ӻ�� j=�]�����j-�a�aZ8�<�<�{�0D_�i��Q���?+��.L���Z"�"��ЏU6����}��ir-��G+y����tMM+r��Z6 ���&�`dz�7���#�~|^JͷzW���u��%���̋}�lSf��r�<]S�%�B����ǟ����j�A>}�5�Df��;C4xؾ�lmw]:C�b�$O�|� ��������U|�Co�id��~��:�f*'���U%[�E����n�3MYh����$aBFN�&yЁ��72�����/��B
���?ZbϿ�yM�ש�3&�a|Խ���:@%��x����V�`�|�1H㚁�l$eiLO3���ȁ�:���ca?�O鷷��3e�j��{��Lj���V;B��8�O>c����W�Xr���8z�,����q�sg����];K�U
�O����!v�S��X�(DN����"t�o�ok�R�N�0 ��	���%�V֬��|ߘ�l�'$�.��g�T��W���WWFе63�:����|����@��kbkx��lrd����3 Kp(���*��O��}��Ń*,�[��D:�M��	�CZy2Hģ]2}�f.�����(�e�����c|�Vx )Bp,��0�Q|I���C�ܵ���#�ۛcύ!K�V�Gb�V:gV�\R��.r\w���(�xr��}�>e��H��n�#\ܧOZ�W��`�}��I�U�#?�\�ll���Ge�J$����B��]����/@��s��|Fh^�RE-c�����:O�1L��g�'1��I�Ϣ��&�-��1M�3r���^"������طqR��/�i�����ΡA@ȉ�7/��e�H6X��?x5V����pq��4<�K�ܐ��G�;�T�D@'[4�2yml��:��]��j]5�,��y���~����������TKG����T�z�?#�ݭ>ٍ{�1�)��G]p`����.tN��2�����(f�o��iQH6L�;�D������Gq�M�+[���F�׏$��'�N�c��j����m�K�6��R/ʹ���;�U�Qp~�ĺoq�6X\c隡(il�ܶ�&�9��H��������� q��y9p 7����tg��E��T�\[����n�,��V���d*j�t{�؊H,[�+>	S=L�5_�� ��l���{Zz���IЦ��Y���wl�l	v2��Q�8(nI�S�`h���rPT�e\)��s*�ȧ23_
��:e�;�.�P]x��6��zԦ��|Lj�óc��2E��vN ��؅��7��|U��	BJk�J�T�C��t��e�����=��Xhʟ��&��qf��\E�-j f�����^:W����!����9��2�n�����ʌ��A��#j�Cx0>��g�N���J{���A�[{0)���90H<���s�2�d�80U�~ձ�LQ��l��ڌ��B�@�Ee[,�QR�~�"\�e,����o�t$����7��8qm�_�eA#��gi����h �"}��Ǎ��dnA��v�Ą�n��}�ɨn�� ���8 %^�n����)1.h�3�R,]i�z|���)���i!(
E%�����|C�'ŹKFv���jJkԨ��� �A3wܸ���m��$��0+�y�A���@�4�XJ�G?q�tl/�mf
�ڦ�b����h����c�t����]
�z�F^7rI	^�td�d���SP�����P(������#�~$;�fe|�\y�ʸ�CbN�QC�E�S�6�B��׊�G���Af���i�O��U�A-������@m`=J��C3ޣ�!�+�[x�8���3�ʓ�.L���s~�bSk�d�^[���p4�T(� ���)P5�e1��'���m 3�g܈2���`4�o�;X�lu�a ]�0��m"����H��@�B̠Q�}����x�ڐNxs;D�wp�)3�e�Z��|�7���#l8v�\�T���z\{N�D��Y�J5��x�J�ﵢ�J�"s˾y��O���z��Z���CoK2|W�b��&/Z4���6�RQ��`��]��
��9���\vs����eT����������iݭ��[�H�L�P؇{Q�Y�H�^[�����F%����L�d�8��6���V�6��z�NM�==��n+�
�K��=8��\���_��,ǫ>�� Q��ݼ�@�-a��;�HDf�滿������A>�/ڂx'>��Qʑ�c5&�\*�Ϲ=����W�h�Sڐ`�����9V����<�����Y�ς�	·�N����+�����Z*�F�wB���Z��hS�Ln~�-�ME�����r���b��x��"�W��|5^8�U  ����S����I����a�w��ɫ��dgэ(X�C� `
�p�s�^� [	+%ua�ъ��+�>j�e�g�W���9{4I7�Vx%�KU�������DW��O�� ��b ��m��m�8!�!Y[������4��(%�MG�J��X���.bq��WF�d��9��v�V-K�/t����{1�+��
NX�m��w?\+��s��[��΃Si���2�M�@�G�f>
C�@�ƂUv�:OjXr����~b=�����q����idǓ�6���^L��ㅭ�U���?� /��Ħ^T푑���KL=b��;���� ;i�gm+Q�5�7��kr��S�e�U������[�7�b!�nsZx?]p�
	��fx�[mD|�v]�|^�󞭓k�"����2�5��c(�NU��H&1A뾽�Vu��2���z՜S����0���u/��؜?����[�|�Lא/��*[lQL�	Ic�'��E@�G��;eZ䑆I���74T���5��<  7զ�0���Ϭ[��gE��@!*�)�ckR09�(5�Dǭ�̅� oi�n�5w�����|�U���6�(8CsS+3�u �Q�UI�]���93+�'��� FS���f�É|����xbp�_N����7�����u��!��m�I��ne��Ԁy�Gd��`������dL�M�>�o`�1<�ӤKYF(�.�/��@y�Z"Q=WTx1W�-;�qYJZѸ��J�\s |����p�EɟԘ*1�J8���uǧ��L�q\g�5��vk�����O�V����t�?���a�I���uq��?�C����մ��2lD8�ES6�������.�\�W��t�Bz˜w"=��7\d�=� ת�S�N�+���Q�
 T�RZ��Ca.lj`;��^�~�y]K��/B�Xp½K�����5&#*=�>)Ow��u�&���w�xrRˤW�E�9:f�"s#
�k�ӹ5�i#z>�g�G�_�]�g�e>�����%��q/�]�f�_q0���q�8��]��
���>KC`*3���Ne�^�S�ì��k,��r�p��=�oq�П;�g�fcK��{�'��F�\����-���ϰ�d�J��,f��n��_;������d�|�dc�teוTr:Ѧl%(���n�V��Hr�����J������Pܬ������YߞD�v��C���)��̨r��� �Ւ�|�����[��۳@�\)s̭m$�P��Db��Hya�U�ZQ��#��l����FI#��B��X�5=�� �^�GB���T
���'�$��s\v9���RVLS؉>���s�[7�*0�n�f����������~A��#�"QY��d�n���b��l��5'��,�J�'<d�}}��;���KB9 Iz��NQ��JG�1}�0�v���H�Bu�������9��d�C��mK)�5��׋��,���F���gV.,F=���L&�Y�ۻ��F�wݖ��Ey�����3�H#)(��ް˚H�#�@��\;���������(�6����x0(B���v5��P$b?F��uǧӥ�$ ��Ҝ��R�M2�ۖ.u���\r|��� ��E� �pp��Y�+�kwޱ&��V�V>�6�x/!��Y�-2�i q�`���e-�1�&�^��R;&y���.���җ���o_\7q������֟
����ϊE��^����<���ݓ��k�N�8�����T��z��9�˅+4�X��������!�F#�(��3��:��q�a���j"��ZT�Mj�dgR�(���M�7[������?��m����Ё.1���>
U���,�Cڿ��84�+sv$W���&o6�W�BK��+g����y3�T�"�]�%p�=���ec鍉\��9��"���<z���8�����MU3�=}
M|WP:�=�u�&��� 7ɜ6>Q;BCIe�� ��9�^���_	jy�NF��a##2���{}IlJNXWhHm|��0`%!?�i��e�'���͓���vO7�_9dNW���
m������x*�a�u_������b�Ӻ��7V���ނh�K�~T�mRKk��9�v� {�%,	$�$�����>��h�c�l[s�&�
�GA`ܟ ���Yב�G�
��,8�i.>&י�ڧ	G��[�@�T�p��2�a�>���~��E��ʦ�:F%[��	K͸^��?��P��o8�4D�-�y����Vp[)77|�U��9&���nk���6;/�}
Hc�y,�J�:$D�Л���b�:��k2a�.S�#��D����ŝ���#
��N*tarV�h$kSJ�g�Z~D�fm�\���D��`�A��tuK�|��,��J��gk}���*��	�Ge��2�.Η�,��	@z��Zۏy�5v<d>la�n�i���)pv;	����]�P�\J,�v4c�� 1@���5%)�<TJ	��.Iz�i�^n�W���IN�+N���`�9d�@"�ȭE�JVY]�*�%���׆%�F��������k�C���Oe�Y�� �lM��mQB)'a�r��<�e�OB����!�)��1���׋��Y.������O���DA�gZ������w��Z㈲)aD�0�؁��ӳAU@e���F`� ��t���Y� (���%�h �[�"���������F�v98ѩ5P%(���*�I��m3��K�X:�5��s srݛ��}��uQ����2E<�R|��2��T����X[.y�m`FF��+�HB��]��Pd���FH�l����<�E_dF|��j���%�(�Ov�h�IǬz瘌���vb%CN����<�3��кu�3#ŗ�;�&�S�^8G?��ژl(=��=04�1'�\A�xb"��Xθ�N�i�`X���6��>��x�pZZ��Yh����C�o�_YeG����2Ȏ�%���-.Y2I� ��\e����{K���.(��.
[A� )�Hf�@�p�f���>j�s��������hc�F�y����_9�z���^i{u*�2a��Z�=x-Cl�/A��#s�6D$���2���9��]S�'�eH���5Q:
x"�VIN�Y��{b���i�{��J��j�x9b�|��5�>q�|Ï��n]l����V��W\�FӉ��tȝ��d��?"vLA���h�V��~�Z�W"�α�Ɍևۨ%	o��Y죏,;^���[&{�z���2��#5r��W��ɨ3���ypb���u�f�,}���W.�c5(|�_.)�+u8�z�	?��X��ˠ����O.3�]Ԕ�!�b����+�x���#�+Z����T��;'.?Q��s��9֩.^N�R�}�HVT�Z}F�A�G��mJ`r��K���'�L)�
�ʬ�0��EZK���r/��	_�ґ�����}�c&z�	���١yA?g�-m,Y�\�4bH�U��]��@���T�H�,���+����<�&�"�c��]V�2�"�MJ?�C�~��7zp�MY�մ�;9�8�P��o-�\0�⭰����5>tcΘ�kI�")��^d,(w�h'�򙦺��u�<�H���8��z����6/ʚo2r�@/�0�i�K��'�)�(�ϣ���:i�����Hf�cl�'�Ҏ�$��e����X�Wcrx����Q�(F��o��i��>���dz��SYUU�_G�2�vc�=Զ�]#����q�!���N ��WP����Jͦā���=$�|�lq��C��<�T±okgK��JN�EJ�����ɮo�)��'�4�B�Y����	�[��P��ݴP�2����К��F��c�`��� ��$A�D��m��7��m�.��:�f�s6p���!���->� H��b��J��!N��Y�F�wky��� ��-��)�<���pHʹ-l�����p/<6p�D]�| ��MK�l-���=E�����E�E��1�} Eb=F�w��z�p�M���ӭ�'�o۾-���J�O:��λ����gB����`�4�j: �E�I��)b��� B$F�]��{%��%x�V	"�U튈\ ͻ�)���]�L:�oF�c*[��p\T  �erWr��������s����J��-����(��yj����b�9�y�%�g�rP����E4�s^�,�`Y��f�8˿��UKz��\�m���f�#��!
_Ȣ���W2N��P�%�ݸ��������}�<����ejН�U� '����� O���Ӝ���`�8�ǥ�4^��3hU���sQXP�dUR4�5��.�H�6�t����]��WB�>`��
�\򇇒 �����]�m����Kk��i�#2r���="6���i`O�$ű%�Y����AT�Q:K�qT6���S���L������3F��R�
ؒ�GC
�j�G���#�;�Z��y�مg�T��c�8ك�H!��x#����G��2�ᇎT�6fL�df��0��#�	-H`��\ϑ	��w�ö�����u��Ͷ���ד��Z��nH!�+)�f�I�������~݇������&7��R�/*�w���{����G������ ^Ԣ3�t���յ~Z�?X�w�q30�nȴ#��p���[8�1�GPAw��T����t�P5�j��$y�:���C�OބU�f4�=�m�H����;%�f�-�`L*O���k)�&��^b���IB�J����dL�2�	�Af��i	t�Lv�	G��~��Qn0��n_�'��
w�$ �ݝ�ó�Nrl�%D\�p%���d�����>���}�ԁ}���L���iy,��:4�7"w
\n��dk� ��� (�mԶ���7��^gn\跾4DF���k9�Z�1��k��0
 zz�{{x�Ӵכ�S�\��%�\+�#�R�@7�������ƙ��]TP�С���jP�	�a5��zH���%g��Ԏ:���
t8{�}�`?	�sm7W�ʏ�
�"�Ԕ���}cb�Uh��:�1�b�?i�޹>/��c��No=yzP�A����0i֒T��$L8�3Ֆ��{2�]�#����ړ��|;o y#�?�B�C9��s�Ty:�(���òHR��B*^)�M�H��=��W��l�K%s������L��)�2�Xs��~9ջk`*3�Uɝ��p,�V��]�c�ì2�
��Te]E��,%q�o��*~S��Q���r�A,
*W/r�����FZ��e�kh�V%r�$@��@��&�q��?{�%����m�%`�KZ<T�>`���m:��`]N���yq#>��G��J�v�s�������^o�Jbi<Bp��1�=b�~@�y���p��
"k�]C�:l�A1�tS�a^p/�ýL�Tq��+v&��ٮ9��)��'L��tu�>'k�e���i>��J#;��c��2x�b��Tz�fO���0fƊ���Đ�Ɓ;H��������N��=<��J��W�P5��*V��О�G.8�2�G��HC�Z�������0;��2)a�[��&�.�
�z���F`F�݌>9휑��"zyG�ܪ%S��>5��J7�+�@�}g��\7���m���D���8���9E����K֫�ĹֻEB�S�fR+�"|�N2*Anʬ����w
4���P|�*�#�rͱ�
���O�ƈ����GmX�H9.䔖y/B��/F��nkXbbJ��\�IP���	�	��!-���ꘚ2��qGQԱ��|�U{s�B�X�V�P��6��#so�� ����$�S��Â2�k��$��y|"��Y/��eC�ΰW�\&���ؙ���x���:� A����9���H�&�U-�,����g���e+,���c�wyX{����ޯ=�<�>��=�w�� �c��"J��JF�+*�8x���CG؆�	�y��.]r��SwiZ9W�v�xZU���i�ik�����s�4����6���5ʮv�ʄ*"���٤�"�=�l��yg̝�Y�SMq���f��ʫ>Ms���֡Zh�������+�k�]v�����穁�]�h2M�
6���q]����'�ٓ5[0��H��� �W3Nw����i�i���t�ކ�\w/G�"Y6�s��7�	��tkv�͜��-�7\�֞B� n�K CQ�Ƈ��R�*Vu�t�iM���@Q b�l,:*mg,}O�ai�kw�8�փGʠ#7��g�ƅ���u��=���M��Y8�TC�k7rAò�+�A}g�]�)�3�i)9;j���X�H���� ��3��pjz/k�����w~M�x�>�ί��"hgy���2��Ǫ<}3���i r$��Xi�vC���$�4��Mb��>\��"�4�4/���R#h[��뵨�B�peǈ-�zQ
���?�g���mw�qS3�!�#b�k"&�B]]F_s_V�q�xQ��%�ߪ�C��X>o�2�
x�U��(d�G7�&2 q�k��[k�O ��V~�bs���H�ذ�N���+��BLs8�o���$g"�\fv��q�-�Kn3������ؑa��k��ض�.p��$�����#n��H��ht�c�x��[�f���N*�7l^��5i�u� ��X�;6�\l=W�d��z����5�G���#V����i�M)l$t����x@�g8���»�@�(s%�(]%�~��f��$�ưbB�+���vd�oE���z��5C��i&��W��C��ln9C
�E*x�R����mP���o�5
�� W�KsA���>����� �x�l�S�U���O�p>恕��\�7O3��W�A�.��e,n��u��Fy�뛖���vv[E<���VZW�(�o&��	Ob��?������7ʽD�͆�2W��\�E�3l�n��]��׵y�Am��L�P��2������׏�pˇ�R�a~��i�

c����	6+Y�1p�]��4\�Վ��� |�)�����F>�}�f����{gr �qX$&�YЯ��y�!��)�o�)��Г(	�o��Udw�$�K�y��o3�z�@|��j~j�hM�j���tqJ�x�|��es/�dS�`��x��
�)v���f�4�BʡȻ�9��	���A�Xj�'�a+�0@�o�شx�7 �f�툛D%�� 4@$M�Szz
WJ�%!��H`�Y���b�US�h�� �6Qn�����X}@����{А6Ih����OXf�*��(�A�gD蹂b��\����%b���28��=d���2)����dX)Ou��II�w�<Ӆ.�)^�n�o:p&�C�I2�M�.�;~8u���' �Ik����~۳>�{���$?aB|�(�X��"L�q��� ;��B(C@!�-뻐��*@,I"�z��ǡ�^�ı*���R���|@e�?�s�TЊ�����䓖�;k$![�t����i�S����T�f��G)��~9/�����Șd
(�I {I�J�׬��NW#{��u=(E�/��޽�Ij�1�Lg��x�F��j�����r��q���V�gUp�)�4���-����G�$��֌ʧ{͒��ikD��`Рp��$��!*7oq|Yf}���������ǐ������F�F��X��ѻA`�&E�����0���&z*�Hω^���n��}?��ȇ���١xfi���h>w2� �u%�r-϶��R�(Z�i5�)���\�Y��+��Uv�}����� %���W�?�m��
.M�IJ����+`�J� �m�{!ؼ�t}��YyzNӃ��]�X¡IX~g�^v�����:�?ki{��U�Ae��*���M_��2P�$���$�~�g$��r0'Kt�(��Jq���sq|��e`���9��\$���mk�o�Q���h(��\����	�K������x���r�C �V�;��dP9t�e�E�=���̣k=�'���9��*8�ДV�Պ��	Z�.��Zl���r;�Ǔ)���K�N��{L3ȶk�V����9Y�gV�kA
�bHF3W�������[A�]v{W	�ZU{:M�lJ��WB�, iS]����Qܒo\��*�nmi[�
���o}���ϡ��(*�бU��H��ʭ"��m��� (��A��$�r�Eê\��̒|n��ufI�'�T�}������9|_ڷx<ӕ���}�����O=�����x��k�ku9]�)#K�aZ�r��E��m&q^]��S����l�m�C,E.RW�d�l�j
�1\����X�*=�� lԬ	�/s���l�b%#���߰��$�C!�����bl�cʂ��F!6㨜*HIaN�9,;�F˧�?دf�Q��쥻�#��_���:����Z���|�ׅ5��(��`�V���#���\V�R��2'����8�h	W���"��qዱ:^-��G�Zz� +b���hB�$�2�ߙ�b�!7�KR}M����؛%7a0h�+�LC>JfUjή��ok��>�\��5x"664;l�/��Y<Ϧ<-�|nrj�0�c]�8{�ԩyg�7�l0Ͽ�2�p�NfC��oQ3�W��&�9Ӽ�Rs����y��8^U �#T�������Z�(?{iT6Sk�A71+p�6� 9�c'��m0���I:(�YiU^����t���]��:�11�h�䓵y~#:��ي�
��T�������t_��8��=�E�bW�_�I�)%� 0��yGaRh�E�o*�)�g�,���w���(IlvA�1�i��BܺZ��/9�e��^�S���q��9/�O���|� gI�(�C���&B���Ӳ��Y`C�\��@�g���z�t���o��ƕC��сEn��6�Hv�R.�:�3��!8�����v�⻤Sd]ip�R��x,�a�Dj�#�u�����Ͳ�xn7@_�Inz�T����-8��"�{�q�� �'��pq��a�Ǔ]���9k�:1ۇ����˲���X���S�a�C���קּZ�p�� 
�x�g	?��e����=������m'u�a*����;�����@@J�{vu�ώM�HU�+cl)�gfz��|�'wݴ��j7�<|�H2����$�3���@�+wۗ�fS�#�A�����&a7�D���|�BW���!�g�9Ұ�|�
A8�~�oc׳y��H �JMPY� �yTd�+��T��3���Lvn�5n���� �븤)�a��M�FTH�w��@�t�DK�?�,]�g�dT{�g a��w�EI0�U�1y<��G9�	U���gw��sܱ�����4�����r�?�^����8�G�_,���4����~��:\�>��:S���5�aѧ��/>�4���~����za��x�8@���~{g�Zv3]J���M� ��m�|�P^
|�ć����$�q�cBRm:��q��n����e\Ȅx�<t@�Aҝ�+�b�B���k���L�b#[��3���ef/��b�S���$��&o��h��+�z��·�����k<�,Do`X���H?W�',-�F�:�[;�z18~�4�t�.)�I_������#�hн舩SS��^�K�����=V3~��^H�V�Z�رC� ��+(��E< ;�F�������k�]�����ZN���<X��޼ Ƽ����eq�v<\D]g��0h���~_y�IA��2��;g/��)ޗ����ꆀ�B���}�4����"��"�O��p�5����w@��}=�C��I!^�'�����N����� ��E�"#�_��yq��(�7E�+e\�ΰ�q����՚<I�݊�)X�0	�� 1�$m�F���>h��o3٤�Zf���XIxg�B���	o'��'�B]yM���������'1�����&�%��3$m�OV\�ur_�0`4�q&r�p���Wy�el�5uטĝQ��AE��'M
��� ����[�t|��U�c3׌��5��a�BVڀA���Ggn1%��uw��н:M���;gQًg���c9؏F���}&�F}�%���]���6��aK?��9�I]�( ��F�Ceb�
�۶�LA��Xb��$� D�kK����3�ξ�ϵ�/6��"���X�v�˛�="z���������=˕�|�����y�
�ٕ�Z+�g�q5�ӑsb_>���"<�l�Cű[R�}ܿ6Y�/��)����^�A�����H������� ���>�v�"���jJ�;�: �"Wm����~@��>S�bhz��lFh@m-=��b�Zf��%�lg��=��SD_|Fp ���S@_�	�u�|���El)H�[&^���o v�S�O�9<����B�3>=H�o-<);/��YLgL\]���C�Hf�>��r��1 }�~K��z�|���� ft��&��7�(���� �w���戥K��v�NǢF�����_���覂���HrR��T�T9��#�4e�B��M m�E֓��'�%��]��b��D=�/:���l�����%Ő<f���~�4�0e<ܴ(�P2㧰#����\Ql���<%��	<&t�HI�!~"��BESxNǨ�>�������$��"'P���l^�;�{����
]
�xĎ0h�G�!ƽyƸ撠�M��7�SWߧ�����6XL r��cb��V�_����	���E�kH]S؟s\PH?}��8�e�I1*\C���i����x�jqvImA遌�xc�ק���ta_�5P�,�>n�|t���ߕ;I�~L_���y:o�QhoR��!P�T��D�2���8L	{QĢ�;/���p��+��T�rx1Sj,��Y �?p{Ee�/�H<� �jΎ�L���U���I[������1��T�}`�7��π�<Q���IVc[&7-		E�����+��o6�{.W��[����ؘ�`84���yآ���8S��%q1-Œ-T���"l�{�+�nBv؟.���|�"5ǖ�P�������:�!�v4UO�s�g��1��QNC��G~xψ~tjwr���þl�qg30�0��,�P��78r�J�	�v"��G�{�C��Js���Cƺ�J>�;�l�;�H���7��:3Bf$��^�W��T&�d�꺵�pEB �I��b2T;Q^����{li�ȁ�1���J���)��>t���Y,"D5��Ԏ�_M���&��˄������&(Pi���N��7���H� k�W�jY�k�[80�P	�fۓ'�y:��(��> b������!6O�Vت�TY�%����p�(D�{�;��S��u��{�n���
խ"+?_���L�2E�沑U�m��씓(�Rԭ.z��!^�e~��j�9�X[��it,km�!��#�P˙�C�T��P�L�{g0PxMz���%B3O��,-(hzj;�'o�dpY�^�-c�L�9i�����a���T��%i$�k��@�&�<|�	������4X�X<0�C4�D�R=�f�����0V��Ob�r\7�����\��,&x�B>�/ʐ�?��}�e�2��տ� F�{l���9�w��\�;��!���ad2 ؜/e��t-C3���с���Ʊ_
Y����(���q���A���f���hk�J.�f�]�|�d��8��'�}=1���.p(�ů��GZ�p�'��._Y�M�� �p5�A���vu#�ct4�T~D����|��)�*�e��/`�ڭ��%�hg�4��Ն���ĦE�G��`z�<�t�&��2�T!������R��<
����q
VD-in	����2A�3k�� ic�^��ʮ�fs�	d-_�P�U�eB�����/��������� b%Hs��T{FX�P�c�_d�c裏����P��۰X�R.�W�BN|����o(/��&��� ���w��I�ؔ�
Gr�n�Rr:����&3��Ħ����GLb::><�j(��5"���"]��/݇�2�WP�OO,if�
Co��wN
c����%�\>ro��[��E�M�,QWi{g+�m[93(������S����C��Ͷ��E�_�%������Y���Q�}�U�N_����樎=h��;р�(��Nwc�UR3�t�l��o�BQ���U�,��n����EM�&V�h�x��,�$�uK�"&~?�\�(Y��%��acav����XtRH��`����m���BS�@��Qêƶ7�B�A��vAY��r��R+cn������?yU��>����&��k �.i�y�y�F���Y�"���S���3oy�k"�b��
�`���(�.���B�9�ϯ�����֒��-�`���& tV���G������x�;�eɗ���C�����p�}'.�*��{��8�: ��̧*�T��,1_��(m�Oif�p��A$�b�T�������Է��eC��ե��;��͡f��r�)��C��(�J�K�G��Y��p�H^|��R@�ʔ�;��>ш(s�8����T���@�����'���{�(M��r�X����3�Nb�b�������n�i�2�r�Ln� kv����������J��ÿ�+�`y�ɤG"[��� D��(7vCe������]�s���׀X��MzR�P��`F�*�mG�J^���rZ?x��Z�2�M�v���a؍$6f��`U��j@)�.���0seTC�d@����>��F%��`�=�6�73� ��6G���MKEd�oQ��{)[0;f���HO�PrW�_Ȯ��Ȕ��#��&���&��%�^��k>�X*O�ô������Hج��S�8��ƺ&���M�Q���W�$��T�7�=��/�m�@d-yؤm���>T,7>�wr�@�[�h��3��^�}A��3��tTl"�GY��24vi�Dy�3�D%�Q����KT����,�������0q����U[G�#�$8�*X�0��;:>�nX�X�������ŧK���*�)@�jV�L؋^Ι��=N�߰"�n6�x��k�G�烂P���J��i�0U�+P`_�Of�Ӡ�P3�Jy��
��4���!2.*���yN���WB�'�>{�^7��s�21���-�9&?7W��EFO�#�	v����Orn�����A	�X@j��8�a��(�ʞ��Ȝ�:a��@��=l�fmk��`�PK�*�d��M�Mkr��W��uǹ�@���j:���� >��6y���������J}0�7���c�v�ՠ����<p�k�l�����%vK���S���Q7��o������N4?���V�ѓ��z;.$�L��/h(޶r�Su;�RyIù��Z���|`�r�>��q�z�;w*>�o< �s/��[��>R�`9���xh!�1���Rp�<�qC�iC0}38srL�sC@Le�g�gO�	�ow�R�Bg>(�7�^���oZ(�kZp�,��3K�� ��Y'ײ�t�o
V72:�j^%�Nǹ2ͤZ��L��zkm��n��+�&W�dB�a��j�t�2��O­r����j�؇�i�$?y���Aq3��=g|Kh�_�U#��X�#�G�ݳH~�QE���Bx��N���H������m��rY�[��zؔ�Lfn�}�Gh��RՏ��89wX`�?8��7#�vS���KL�$@8�\O}C��|�kB��:��t��*�Fq+yfs�A�h�sq>f��{����|���-�_��� �����a3����i��r�r5ƛ�]�/��}���^��M��.�C�Q�˰"���E\�ߚ�����M��c�f������� �Y ϩ�"�XX�4<����%���EJ7YF�7��E|A���B�0wAߗ�`9/��[�a�}���%�w�r�����\����b����)� P�)��?��AF�$.�%������ޠ,���⇼�D��̀�t�Ą��L�!�C�����)�J�����i�]�2'��"d}����$\S�_n��E�73�_V��"Ӎ"�
�0�k�},����輗�<-�
�w���j��1��`���O��XH�2�tБ����\wiP1΢�9p⼊�Q
]�����<�V-��
?�ЌF44y}� H�5=q�N�U7'�����"�]K>�����1#�	�g��{j�_f�� �V�JF.F.m@U���@�vPZ����jl�E�(@��ce!�ҫYew�Ll��W�'����|��;Q��.�6t��n͙���y���d��ER��0��y��#�x��J�
t+z[�p�����H�(9����%d��o_V�y�o�(�L����%2(�Xav$�����o��4m�s�($7�i��d�6sľM!h8��á��۫Iy!�&��B��5m ���Kk��k1�ԫq���v�$�-�=j:q;TC:m��X��~7{��a3g�K,�|��/Z����y��o�6X��Z��ݰ]�krf���m����5CPs�]�0��*8��UFaN��"����{}���4�:
���/�c�?{W6_'y5i)YU�q�^'!��Uڏқ��(��z�Yz����B]0�ͿfJW^�%�p>����<^�?q&$ �@"?o��v�I����CAg�(El����)��Q�^�Yz�y��:��𵰐������o�K�����0���-�,���X:��aZ�`��5~P�3̟���&�J������ N�9���|tS�_��@��u�?B䟤�����l���xS��\���>mM��~%�'��9�/�#�~P���U��u��V�Z�a��������p`#���o�]�V��z�b�F�����{F����P�8�����n�����GTO�#AK\���5�u��ImN�Q����TRS4��n���'o����-Q�J��	^]E3$kui9�H<_j��>�>�D�� �����ũDj�7����S�D�Q����g��Ժ#,PQ
xN_ל@��Oy�*�qK���ʿ����s�\e*�'���)	�V� ;3a���Íi���I��V��cM0sA_����!��U�鄇��(9�Hp�4��/sK�Kf�e�x�"	�Adp��c���+�=x�<f�#Ki�1eS�\*g s�+�%Tء��=+T���X~V@�7�
�b&:i}�����"�$&�p5����*�R��fxJ!�H$>(�b#�����;E��_3bT��7������m�1w�K�����M��=���J���WYD��c,��U	{��y�Z� ����i`3��gʗ�#�𿈼�P�n�P�</��;�2��xcVv�A\��Ђ�+������z�֔m���E�|-��ڎz� ��s��V���e�M��HʸO��Q�\������q�s��L�*~�����v�1og��;�	g�Rx������v�2	�ًBg.W�G��Pﲄ]{��tH.�#|h��Z�KU���^ap��4X��ͯ7����*mӅ�'�]O�Q$�;Gw�D�@�S��m��#��[����P�ݥ6�/#��
#ש��_�̎�28{�21���1�&i� ��?���Y�t��y�O�_�> �9�3M�'����{�:;��{r�M���Me�f��<�k�S���I|���E�F���Qܠ��#Wz��v�Һ���th]�س���}k�_��co��Z"��rg`�����h��X1>˞��iS��g~�egY,ݕR¦��,�_��7�J���0�S�@��_'?���<>�|+I��g��H�b��䴎�A[�=�{����O��!| h�Q��\�����+;������w]������=b��|>F&�ǣߟ�ɸ���a�`�tY�p��Y��)��Kx���%�_�-�Gb�V�_���@�7� ���	f@[^K�[n�M��z�'"
-�,.<�'nty&\у���f_���o�V�@*��� mJC�-��fq^F��%w��NUrde��a.(�$Nd����_��H���5H.��:
_:� �1
�./t���S�y4��1am���H ]�(�fIysP}������PK���c�]����BQ�yۓw��5�.����`6�IcʧڡZ��}C��Mk��t�c�.�A����F�� Y���,A��;ن�(-�#z%�|bH�O�灻\5I��/��N��G�LmAMأ7��x.��>"�s0�G�l�U�ta�o2���w�JIs�\2���ժ��6�^*�ڶ����q:0-]��R��fss    mJ��r~�� ���� U�B��g�    YZ