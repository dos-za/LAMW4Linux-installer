#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1620630146"
MD5="ac5a9bc686710999487da94c7acc6880"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23496"
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
	echo Date of packaging: Wed Jul 28 14:22:15 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D���&A1Dp�r����	��s���ӫ������QǙr��	heVFz���i|	S@E�϶F�j�{�w�;Ǒ���b7�����/�&��.�>?�/Z#�� �x��������G;�}a$|�E+�w Ω|ӯT&
϶��w��
ǎ[�b�&Q[�^�(�Yd��tT-�c�8{EZz4�@d�"'��b� o�7��q�Ï�����µ�"4�*|���	Ǣ�h}9�'3iC��^��R!ї�\]��Z?3�70j���)��H�(��w�I�z,?��?,"���	��E/j
���K�Gp��?�X�tK�� �΋�+�MV/B0���.+�,ޭu|�d�H�<V��[��q�Tqݐ�]tU�>�d׫8w溸��07슻ߴ;QF���x���-W�q﨤�(� �`r�8�1�� )��*[�%��غ����r��9���mX�t��;�t7�o�n3�0�|G�4����I1_�܇g�wx�O�%<�$�'�h8�~h$O����M�X��ߦ7�C�����CiU�]�EN���r�3���\Ӧ	�E>������@I�ں2m�p�%`wj���y�,�R1�#��r����ꛣ�����>�Oz�V2�>=�H�+��?Dt�G��~���c��U�"�V�¸��1�U��d���S[�"�V���ji�b�@�˫*\�X��ž�Q��a�8���>�ã��U>���3�m4�GD6��	��E����9b�3�ٿ�M�c��ۣ�)|���^I}�R���G��Hh	T9���lU<3�0D����C�t׈��[*炯�T���TJn�[�E7*��=�L�Z��e�O���]�=E0P�k�E��ݑ�[�+�]NYUz���A��Cῌ�~e��C�5�~(��P�#�:��*6N1���+m�nZ���ġ8 ��0�p�����;[g� �8L�,<�?������5��y�h�����˦l�|�[�j2[J6u��=�_��������Y@�	�jK�H?��<9�ɰb�S���H3�U�O�z��Gab���y,=E��1�\�/&��Z�@d�ξ�@W�$�M�-Nݰێ4�V��
�/�a*�����Bnxj�]?�0c��WŔ��������}�<�phkD�M�XM5�㪁�7��a���r�^Mu�*���CA�<^��4)3�q~
��c�M���ޮ�p�f*i5Q���T�$s��2�DfV=��`�Q��n����L�vI��n�J�:�47�,�R��o5<j?4��Ã
���j֘��\؈w�p�^h�j�>��p;zY5�͢��<l�\�߄y�|ߪ4�,��������ı�U�p �	j|K> "�F�s����[e<��(-]9���������zS��h=�&.�܄[3�H����Q2b�}�]"�%j��a�z���0lb�H�=��u�ĉ
a`d�%3�S��C�+��5�Ӊ��"�CY�b�̻�0Յ�!EA!-.�"�:���Ԥ� Fk�9�:C�Ch�yE'Q݈������V�O��JE�!��w��|�;�`m�p!ӬW��[]�6��窼���J�aR���UO0�����N�����fcA%�z>9��8ʰYJ�AkKiFli!�@3
���y�1t�|xҖ����,�x�ؖ0I�vL�I?SdO �0�Ҙ�5���|4����[��AJ07��Y�� 2q�8���{wS10��߽`��Y/�k�Ū\�W��!��5 ���е#��ֆ;�)/˔ԕ�,�
]%l�r�p%�]��A����Y:�(Q_�3�� �^��E\
�+��1o���i�ۑ��x�����u�Y��`��!=��l�ot��» ׿�9P��EVQS�;|oQ�GS�^��]"[fD4�]�-�g ��T�Qj�d��[���H�
�㫤�����,e(6�r�^�u^8"X0C~|G�hO����� �Ѹ�U-�C�dq�X��5���kqm'Y7�*����;1oe�u9 ��U��l���O��D3�IHi���繏��/�I&�#p8Ih����pA(	��,�Hw���hmK`�#U-ǡ��&�Dp}��s��jSWM+	F���3��k��S��Į+��İp���r�@��3�2<����/��i�SH��.�&�G�s>�-INnJ^L��� 
Z����d�*�,�8Ԯ?�����܆�X|����4��{��ݟV $Ϙm�,�	/��r���"S�ҽ�Gb���Y��i/?�t�EK%$��ΓJ@�3�����G9fD��B���]x���Gf0Tx�H�����W��-\���v�4wh+����noz/g@�u��P��͋b�p������ {ę��U��KYA��4E�����,S<���7�W׾���3y���]���A�$r��bT�+2;��TW���Nt�}�ݕc��_Ս���P/�$P�ݞ�����ࠅm�%��� )%�ߍ��wN�z��3�[uW'����@9|Sw�k=�Kyݮ$�U�~��,�Lz��>>�����4�>�=��Y�T�@9�$�6ަ�6X�,�9�y�v���9��{4r]qG ���ԡ�^?�����;QsME�E�J�͘=�Z�##����H�B�*��
y�ڏخ��L+^�BDBb�U�갷��?	�q��c�D�w��AF/̬�<"e��4��+	&�RwFe���IO���N�QX��i��y!�\��rS ��^�s*p�sk;1�=��%�"a���@�X�����l�ɼu��xWͯQX8_�1��������7v/���{����,���W] "̯w��b��G� @�\�������5����̳Mkd�D����窱L�X�OZ���1�NW���]�0~��B[�q(7NL��V�Lى�v�^c��e�[s���e,\��Fl����?O�&DYG��\^�O��XV- 挷�6C���P(b����e�I;d�f0�Y
�H~�x�2�o��ie`ZV���ZX��w��	��B0���Y�N8O�L�����<�AA�ff'��|�����֢��K'�b=T�=#���q�
q#�9O�멷�:m)�c�ކzK�=Fi�P����"�n5R�z��:��.�[7,������'��S@^m���}���n��|�9³��U1)^��O�f"��^=,ثN�fx�m&u�R�����lֵ?;Jϥ�~�"�*�j�r�b�=W�����u�$cui���1�d*\$I�,���wu���$r�Ĥ�,�N�	�}�+�e;��������%��1��l���y'<Պ'z�g����E�*e^���R��J�e��!S������b�g��X37Q$#��5�<�:po6o�wf�Oͤ4^���F���F�A'������V�&=�O�4�{'��5�� [B����!Bc�������}���,�sx_EL��h�EQts�̇N�����SgW��bj/��Ͼ���G�Q(Y����X+Z��f�,�'w1�~�
a�c萤T�*��OW��Z�/"$�>K�[��r"�_� j�H�,�rKW@Nc�coo���,}^�"K��"����j�t�!AZ#c�l������Uk��%>|5^@�+mw��ܞ�'���P|QM�518����a��s3���V�]�5#��$dɴ
](~)­�D�w��rY����;!
�����n}�{Y�����k�',]��k�����#�k�@��Z�S-��A�A�zG�Pe1��0���!�����q����Mfp�G_sBǎ��]�u�'�;L��d0?n�P����A��O��y�J�~�8,+yLr�HZ�j2c�1_���ȓ�����Z$?7����d�Φ{96F��X?N��7v1��s̥E�����Y-���;�^���p0����{5f4'����T3z�//
hi�ޕU������s�/6ٵ��P��<��}x��
{h!*��B�f��?��cF��X�\ඝn����IB��+���d�re7%�m��1�B8՘���.s��,�&`{t�0�v�3��xkG4�yI���ר���0�U�}�jn:�.ȋ������{w��M+���j��V8���Y	լ����{w�U�F�{���jz"�TI�Q���'L��҈ﭏn��2��"�!�����Sx��A����m�[t�aGyo;��v����Q��y��0�<�@����@X-���:�G8s_ե�4�	ϝ'"���0A��r��q�WY<�KfL����	9�;Q��8	Ck$��;C��}X�;�V2rX4����B�� ϔ�LFT�6S8ͻ�((@F���n���/���q���75iЀ��$!1��$�e@MB5ʗ�TQ	�ڹjX�%�C���I)oj�L���݌ڪ}���tS�=�c�!�mS�$� �Kå��8J��i���Η�Z6&��9bf�����-R�2���sr�w���U:��TM����!@�C��s��\��l����ÜB�1����O�c�@'m���������%�x+�h_�$�񨧚��%�y�$kԖ��x��-��I�n��rK.o�gKi�Px+�=�Y�8������kC���ll�4Mᚲi��=��kr� ��.E]��xy^������JXh�=�LV�N=��ۂ��_�(�3{p�{ ���@��ReՕ�����8r�YP �N�Gz!:�_��e�IN&_`��)����k��lt�U�$fv��5U�[����6,\�#���P��I�,�����&
�:��%4�y�0��_�!*�^�^ٸ
i�'5%VJ�
�XM���H�+���t���B���y`ɰ�#���΀[�曬H�R�
�3���A�aY�h�ɉU1�v��ܻ"�f������NT�=�K�z+Eb~"�q=�*HI�}���}#���n�W�8ڱ;[\E�/���������?=9�%p�ny��|��y��O3�T�T���Z3,1��fnL�=i�_E�x��*�1�J��DR�r�\)>�ߘ#�G4N>ʜAm1�2d��|�$H^V�o?�2;�V�`�Ǽ�\�\�O �c��֧G�"�v���/{'���`eeg6]k�e�Y9��+��xĄS&�\}���˰�@��	;���镊�)�����>�*H� �F~�}O�C(�I��m�1ѹ����OH�TC��$R)��t����}q����	��}����0�"9Zt�4;<�&�	�E��I��l��l�v+"��e^��؅z�O*�:� �*�k���26��]�B:����v�/3�?�D�x"s�m������ ��s��Q��ĵrX���	�G|�j<�]��J]��9��F/ŵ����R��$8QO�;�vZ���_ &�ec�TK�uX7��Z�p�T��!R�>�%
E��RRpIO%��(Җ��K���R/��}藱��'����7��X&�%�o���{��$l�a�L׽�K���%-�����K�Y|s��ag�N�#rԚ�+\�+��F/�~��R�#R/���_���%�dab��\O�a��0�r���u:�
LS�:��7��-M�����}����CtN}@>�MsLtW���"Zз�-k�_�4ݩ��*Id����k׳u�w,LE���L��L� ��5T��F`X�'͐?h������w�˝��f�i��>4e7J���N�<ۥ_����3�H
���_�e�h:*��!/�$; � ����i��/�
���_v5�������J:&��#����[�]I�^�_ԃ
�ż��V$�#�Q`cÇ��K ,�eb�����J<y���R�B�,�T )�7o�QO�zҊXM$�����KC`e̹Ϙ��#]/|�}�~|v����% �<�
0�Ͽ�{�S$dg���7H��S&V2[�m��b��u����-��g܆q��1J2ł�^p�P���nhڴ��t[�����p�S�4.�v��yw1��nRDZc��ؒ�_��`��NЮ6�̆���g��RRr�L�<=.�w?���:Y��skr������S���gr�V��:_�h6�M���=�1�9\��Ǭ
8]��rf޴���~w���t��1���"��]�N���"O#J:А�k�X!h�%�4)�=�S��P�ۥ��I(���
�|x��׶_X�<'&�9�]/�B�����$F�CR�J��_�¦���l��"���9��W)WPq��h@�g�S{`���m���z\i4�bO\ި4@��HJ^�2{8dZ��s���!���8	d��=P�F��bV ����r�u-ِ�˽U�x7��������=��l�T��8*�^FBa����h��^7�$��<�	W�*f�^��+ sP�P�%JC3�`O*��x�w����"K/Xe2Ð��e���Q��5�ME���i�+1II d~���� qb$�}���8��������z�>`�9�_�����ٜ R�4�;-��æA����-a�`(/+g̾)�[� #��)����m����#GN7��ڨ"[�W;gO�B-�F�z��$E�*�	��J���O�ỡ�W�y������Z���L�s*i	ذ;�Z
�tqn���&}�)1�;�k��p��������^;4ͧ��>�Yȵ2ܝ�af�<>ɧ`������"�F$'�W����y�#r�d}�x~�4���oF�(y��̉�V>M���"�r��Jř��Լ�"��vQߟ�yۻ��ښ�NU���0&��ᆍ'��.�?�"��ډjF��]�3N㇔c�f28�uٌ���*���ᆩ���6�������KQJ������X����]%��`6H�1��p����O�B+O[��X�+Ն�����v�z��m<��K9��ɴq��{ �f~��:	�8U:64/y����pXtX��I��Ì#�a�`r�1��os���F��h���OcU+�ܬ�d2�݁J���������ٽ��L�ʉ�SɅL����cڌ�4wا���|M��I�G+�����4TB؄��$e�K�/1�[8�2\��Z�V��E⒱�z�I۞���b���g� ���] ʤ���Mzi��m�<���K�Y�؆EO�7�-V��Y{@��~EA��,FK{-��>�a-�>-5���L���z@`#z�U��2�Ɓ�%�wZ8�=@�u�;yXa�\�y�?�yk&��_�/:���e��PV���A�ykJ�X��7&���E��u�t9o�s�D�Jy��<��3	� �]�
�0�}�ޓqq"'[������[&��Qv��>�$~��.XAk�F0Y�������R`3�zo�/����B.95F�:�	��Ł�l{r]7���ןD	��b�ͳ���yD[?�?@"e5���綍.�P�K�L����a��5=��6��-L�[����p\�4�;U��r�?��Q�tc�����V<��Gj�5�Ϸ�IG��� �zB��z=����Xu��������e-hܳ�o�:.�1��n�+�؎�qG�`L�����Ͻ:v(I�_�z3	�L�����,�AF��t��˪��:���tE�4%�U�#�k�#����kK�C���5�+W����$��R�$e���]qX+��8��`ﭝ��]*��#���[��2������M0<�����*�>��4&}LF�[�T��B=���D�ѷ`i/
�ͳ��* ��h�:D�Ɉ,䎛spN��� 1k;�eS�ȷ�����?�.<FI�	�Bg��w|C8}�4#�%X�i��6���ۤ�2EQd�t���Ȉe�wz����o�g7X����z��1�X2��$
4�ze����,�y-��(J��,]�_'���(�flg�M/�j�2*�
�������T����-�� 	�~��W_����]&_O��3]%58���ֆ0i�qp�׬+IU3�l��/�" �h*���,�:��]qn���Րo�PH8�jAef�>��fh,�Q�t��Zu;r3;sR�^̪�����gu�{2�݇o0��j«d��c��1r|�å�OǶ�Bչʠ'��[C�K,���S���趭�Pˇ�EˁlB�p���k�}��L��L�3/P:����a1�
���Ui�B��Y+�lM��m���]WFC�����
רRQ�9�,����0A'g\�&7�m��ާ"�� �L�*�>'ҍ��2M'߫�4NUi���saA~Y����g���SP�2A��jh3W�C���jmw����=�=�k�O�������kRnWx�<�5(��"[�O��Md�]���О�x�af��M��Ϛ)܏cI,b�j2��ʖ����艋��_o$!�b}�wĻ8;�W�"�`�)as��Š'��v���:�����Fj��Ix�H҅����R�i$��n �E�mS�X����3U�B�l�w��rW%�X-�y���E��J�B�����r��!����u���8��*����d�F3|H�S����� =�B���|��0RTM�"p���P"l�T�������R\���8�����tQ&��	G��7����W�>Պh<���-�ܰ!�Z��[��&�	����[���i�v�ןJ���`N��͡|�H휶�����;�,���T��r��N!���u{�N���ڀyH b���8�Y8��8P�� GUI�Zp�>�"�'5a�S�rJ��Pa$O@��u�%��9�-�7������U��vy* ��E�`�>�vܱį�I�g
v�EmV��5h����z���Z̳mӊ����KW5v���$a���â9��0�چh��������
wT�rʫ�C��߳zx,�\L��� Q�j?#<ɬ���)� �9ٟ�$�`]}�τ��w��Z7�PL7V�e͖�a@u��v�ϬZ�߲�Y��*�Jb�P2�΀s�37g��k��6Y�PuߝJt倰�hI�]���	�е��J�	K��YGQM�vp�%͇���)j4$z�~4):#F3Q�e^M �B۳����݆�^�����\���s�37=������*o����s��}_��Oj��gЧB�C=Df�tT�W ����K�t�ͨr�mR�4��r����S|U?ǃ]ď��}����zO��@��L &�*����i$�	�Vh]��hN�a ������A�	� �ͣXI ,k�{XZr�b����Ǣ���[��hԴ�R����Sǲl���v+���~$��:���om�W	3��q�ꦕ-��2�&���M��LNvsT>c\��E/.�]}S����Jf���I�tWrekiuT1G�C�b�����?�������ґ;�aǑa��*�U-�f�qK��Q�*�-(��2(��cc�gQ���tOh%�"BI����~���\�<C��aE�Zc����b(+m^��E��مR�k�I��w��0�\'�.�-���P-������{P#4���gM�W#�P�����ö	��I�Y$��f
�L��	�v�"6�?�tM����תf��l�����Z�����͂(^&���~�o=��6��B�{�0��jX<a�����#)i���?��T

^��;���Ԃ'�h Y�����I��|p%���ZP���8�h��Z�Q���Jcu��dd�*���܉�G3�H��/g I#Iߝ�vQX72&�Y��L�Sb�o=�a�:��!T5�Z�߹����(
~f���#��ԼȊ�PM�#D<-��N�'`^�Q+,�i�d"��z���W�9�=�b��Q*��"Cґ�s��J�怘9�c9�oh��y&��8�KB�
�[��;��J�'�@xC�܂ᵜ�����W�Ҹ��j'iF�#��4���[��*>�a� L�MWs7�qi�lJ��q�w@�3
�GK��<-bB��K�׸%r-�\<�$qL}d)�8��E�~z�أ���X�~܏<�s�pm�\x�\��խ;�4�%X�7w봬�7S������I]��_폀�0��k�db�� %i���w��Ie���E�?��F:��f��e����l������Ċ�ak^�!^�ظgs<z��i�N����i*��Nᘍ�rG��\6F|٘�Ϩ:���g�����X��E���\�X�b�y���&lB.�����נ?���C�����cE�t��K��Qr���N$t�׊�0�#2}�9�o1�-g2>� �8�j�Q�Η�`x������U�
)�)솠�б6(�1���©����T��'�2�!<� �W�����o�E��HM��U-ѥ��oeၮ%ҡ�IRE�[�p�p` �z�5�5��}?\=G���UHs��t�����MT�G�ӦE�H��u��6W�{��n�ɑ�f�����M���鋆�����3��@\�.�����,������w��7�1��!č���!�_GZ���ŋ�������UX*��' �Z�-g��o�=q��Y���Ii���
�P�n�'I;�jgW&o��c�SO�4���,�72��Zl��j6�22ά�ê�&u �r4h0�`����c0�7�H��&.F��;߮"����&$=k��sf�&�^l^T�u	��9�꺁���NTe��q[n �b��_��͑��<�N�72���@���!����	�+.�)��-�4N��
T�����(�P�%W�E-8��ڰm5?+��g�.OD��5�d����Y�Ϭ��{������~��(M�9���Ìػˡ�k#J�.�����
�.xV4�:xgG5M���ޓ�=V�E���?��o4T�����,�(�{e��>j$5E˯�1�e>5q���
��O��� �񴷋X'�
`Y'k��OR�ò������?�]�ؤ�[�^�k�>��h�;VW�$�ma�<�5DA���nGsf�r,||l�(?}g����2�Sac��Fϊۓey�3��}��=��q^Wc18 l��i�@�kذ6n�j�x3�zϲ�fd�)���D��-(�@ڎA�?�^�ɮ�l��F���-��.Ľ2���|�8!L�G{�3hۢD��3D��\���V:�%k��p�����Րt�_�O�n3�������_r�J��c���	�ޙj+4���?�A$�9z��[�`�g8�nP��'Ͳj;�Ыt�R�`	֋@Sn�?� �\��C���*>0��G�~* ^\>�X �����6+'\���gFa�]��{m64Np���ܾ�������Mŀ�r�0����n��T;VI-�F�x=ҿ��B�N`+�T�_)Vj}��wjɭ�/�D�)-�b���"��0��6}���|Q�mYԈ���u'k8�����7��#*����:�_s�E����h�;��0lX����~<(9h����j����LBWW�#�����c�[8��r�7�&y���G����b��y1�܀�����5�T��Г�]����Las�����wX�E������ ��^a���F�����o@���k�.7`��9�zB��}KWI��ï����Ԗ1iD�D�F(4^�a�u���]?��z6yg�A˧��3�#��1�t�AJP�D�Է��FK6}l��ĐMY* �1�zHu�,40��_�+ލ �\�],�����P�-����+D�>�)d.=��~�I�3��E9͘i����e�O�2� x����Y>̐�א	�&���S�S�c�}�!T��E��F���Tz�cP�h�M�+�k�s�j$��0Ӛ���y.�T�N�Gk}�q�ُ��ϕba�
Ǆ6�z��X���RJr,�/�"�F¾�k��	xΕ���͌�b3�s-T�C4�C�~�h""�
ŷ���	L�|u�k���;��l�z�N$:�O&N�p7i7�p�=K�zg�z^��L�X)�	qɭ�{3�7�]f��鄜*_�O�����l|��lr�z`t��Λ�ﴛ��F�7��L��O��<Uל=?|�@�����S #�������o�r�����Ӎ��c�����(�㦴N��[�m���w�(@��k=X�8z�t���h�Z�!�O����Io�8�gHڔt$�5Z{*	F�4�T[�0�Q����~�>���⑸cr�.�Ƣ����*�Q����3��Ր�0���^~���+Ѥ~����\,j���Y��Kz�@=���������$#�*f��K{��"BZ��ZiI�oZ(~$j,�*O�x�FЬ�z����G�u�.���)^�g�:\ݓ�&���H^.��(ve�.W3��f���U`��kO�5m�
�1V���톫��,��A$�W1��R�0����
�8c�N�&/|���/��У�l�h~�в�)���[������5t7bP⟰��*�),�����I^s���-?�+%
�P'�����̓��-�䋞�t�C1,c��<�Yo*[� �J���,0�XGy)Nq����s1ʥ�(���%�7̸#h�UnA&�������Ľ�����B�4���iPQZ"��{�in�^������V�.H*��`�J"��'Ѿg�}��)�x�Xs�	�B5r��̗=�q̕Ɲ����z�ݕ�(���	NN)��R6�v�f���T�+/�$X�m�r��k���`k���A�^�R_�_�,��Z���` :D�xK���M���܍N�[Ht��x��Ҳ mϚF�b`��T�՞bE�����c4��L�~�"�*�N!�f����O��cty�����&ō�s{Z���FgEg|��a��6��f3��v��� ��Ty"�q2�<8����[��ti��A(�"�����Tr�Y;�lKy"�]5R]���_��|���7���s
ɀpz�S�=�6+�rt�3�� �N�D�O���n�(z*���8�g�������/��xZ����|���_�diZ	��2.�0U� ���e��)j�����ц_���_<�[0	��:�賛��/rd7B���d�ܞ�!�՝��8fϗ!2�sD�<�)�t�����*	�h1Id�P#:b,cw�Ы�+��M�p�-(a��K�ކ�/]D��>��)�2�_,X�]��=Ζ�Nb<;-����\���7V�Ӗ���)^%�OV���^ �\'���P 2.�5.���vX���\�Z��U�k�%����H�T�f��z�B`�]H����i����6���Ҕ����b1�G��%�q~ތS��eY�Ք�{L��ƕ�<������G-�KQ1HN\��`�:�u(�F���ܞ�C�}��!Ŭ!���(O0���'�c�ݢ�}�<]�lkϼ��m�^�@��:���	/�x,�����}Z7�I���8�ڒ[���/��\��䝪��A��]���M�+8���*v�4ט�h�a`��D�Zd�VU"&�e�738�M�~�U0O�P�jFNS�I�rt�� �1ͱ��� sS�X��o�Z��0/�ɲDp0�����ł2�1���Ԡ��~��l)̵췊�
#�s������x���_Y2��$�m�mf}X�z`C��M�&�M����Ѯ���I8����ڊ/��>�fP�7?&�~�"��	ڒ��Z���������y���FJ(�����	]�v�03�1
��ϡ�X���i��w�uJ"�Кy��|vJ���Z�!��@�X�	dVwH%��!�E5�I38��D+�y�t_`�"�c��Z��;mP��18]t�����,�;^d�7�@�L)O#��a%ݜ��ģ#ۉ*�5����D�T8.Op×[�; �#Ԩ't��Gᑍg��^�J������t2�4���y��S�p�={dkT�\k�g��4���gD=��� �@z:�����義�zJ��j�J��gc�bSғ!�&��Z+�7��>j�jcܮA4E�r>v�O�J�-<����:�N!�*2l�˔����R�������g)\՚���VF�:?ky�U#��ѡ�"�k�.��C�i��j�l��Ig��"����q����cԅ�[�.��N�(����}��O��#ڋ�1��)U
[�;뱝�_����� �xq7�d��7��a�X���~�}�}�l(!������09��8<�}��Z��fn�1�ám_�?���,���@=h��0�ɢ�:\2�3�YD����럩?����ENU��3�iV���E��UC��l�2�@��tkW�q���
w�*������<��E
#��![m��W��#�mۻ�k�(4kF��X[�Fد��4�p�C�����'ۂlI�MM�O�Ľ���A�0'�q�<�z���p}�~q�k�G�
y �c���`��i�u
��/?5T>�� 0�?6���>L�� �V#��������J�3����-"��HX善�C��9�p&b�he�F�Ӏ�j���&1��]`�����K���IxOb
�7�r�O&��N?�9��(t���tЉ[K�����RC��(��s]��c{#���k�8����2s,��T^'t��>�G�-w��� )i���G:�3Ȩ0#�;sɖ��4��瞼��Fп5W� ��c`���۲8�m}}D��63�h�W��
�Z49�҅0����#Q2�"2�xqܒ�;O87�Ta�Ď:t���ưGȆ�z�8,3�7��}2lcw��xۍò�ܴ���`����RS߳,L uI�En�{����goǄP3��=�|�/Q`L$B��\��/^(l��A��[�s\y+O�mu���Y3��B�Hz0X��6�CY�Uq],�>wS�Aa��MK�(�P��T��N�������7ّ�������Z���4���5���+N����A|)���J@0�5��S&�yM������n��o���B��<�ҡoůA�F�2m_A����5`��V��̫R�Sݝ��Q-Z�����T�P�%B89�\��󧅬Ր�+I���3��d�G�:|`P��h�����n�b��0�]��O��_�R_��f�'�I'�AH-,�GwS�y�;lE�;�����zz%���{��m��zC�d#mh�,��z�Vؔ_��Q���5�R�����`�|E�<�/�_��í��SM8慶(t� ��3����i��f�[�[�*N���>��g�R�>���0t�O�̐�)�Rtں*T�D���XL���o�(�_��^��o�.�U�;�|�S�r�H����ԏ��E�n��T��i�b��0E
���hm3�~_)H�c��N�yi7������ȍ`m���IW� �$���|�C(��ڿz��ٓ�e��+�_�5�#����ڟ���
�<�����\��%7��}���ϋ��U	īʨ�͕�#TBe�G���!�g"����Ł��CH��-��4��9{�1��9%�Jwf��&jx��~���A4���3AXδP� L"Ԏ�TY1 0R��!M���BG��cӔᔹ>1�n-,��ϧk�|��q��I6�"�r���5�)�?h�h���h�50^ a�XЮ���S2_ד�~�}����y���dU��}��'0kW�A��e�=������өD�<@L0f�&e�k��T���?1thW
�^q����\|�w�Ǖ�挜n�:����y���#������]4�!j-��
�d{�=�jhS>y��Jld�d�	�"tJ>t G�*P>�F�=��й��3��Q��_v5
�f ���*-l��y�����*��^G_�R�+����i��v#��;xn1���6���P�$�+(7t�,��5i|g������E6�Y�@�KW��ѷ+���]P�h%�<��
��j$����,fy�3�NE�c,"1�O��w���Um���H Ea�D�3����&���񈴧 =��UDɅ�P���Cc����y�o7u�$储��ԉQ���!�ѝ}rx�H��Q���z@"����¼��I`�R�Fz����(��Aǝ]o@:�IE_N������hO0NT��?��a`@�&<��-�^�1]f�^<e�{�(U8q�Q�Dy�]�p</t����I�V�2v! �������Y�ֵ<u)ᐷ���r?�n�v�W�l̲؅8
+�)!@W��-���	XI]a���s[$()�A��+9��4j����}�S���*�6Ppc��=�:]�Ӑ:�	��x�d����<�n~$ҍy$J��g'@jmyS��}Z�J\M���y�-�5��C�v`-�S��"��4�9\W/ ��i~qr(!j�N����/�×��YUh��a��g�m�?M����4NQg�[�Z5�����6h��ou�})ylrɠ�c���C��|t�����ΜL�d8�쪈�T���Q��DpRN�w Q�E�X������9F��a���)����%~ˁr7;���d0�$�M����;x���rpH��Һ6T)�J����Bo��=X���
I�s�`w���ռ�Ə��ؼL\��?Άh����/��i�e8��\�sX�R��|=5ި�b�+�B�"�=x� ���\���;������
4�FMy��(��[�����\�DiZ�D��h��ϻ����t��
eQ�d�9G�դӑxZ7D�\r�I����"u6�U��K���^Q�Q�>V`X,��	�C��*�� �"�����	�±�F�^���}����g�?�������\sF�	�
A9�<�(	r�\��8s�@Z����ƳfA'K5Z"�̧��Ϣmo�g�\1 �����HKS ��#�}%鲗{31����.ql=KA�B@���P��2�+�L+�P�J�o���[z�Gkro�!H|5�p�3��4���+�6��2*僕5�����?=�}�CG�tO&O&����EN�5jr>B�w�eM��v����2B��]���O��͙���+s||�~�<n��n*��ކ���O~.�[�x3�N���q�$�+P�W�.ř��j��1��q��kI�ӆ���m^Tp�!�4$�̬bg�j��d+8�;މ&��P_����	 �t�����^gK��t��{��g�V�����)+VN�ւ���9ͣ0t6�����v@(ր���j���Rx�6�8z�x�0�,�in+�׭��V�B$������Ŝ���m5ள �����O/�Y �ܧ<�����emv�e��y!C������4ffm�M���6���㏒�u�o5!�(Vf��}�#A��{���)�qF ��	jj��NM4Ӿ�*d���(Qɉ��߹�����d���^������u-����A|��.75s�zƽu��~Q���2�K�n�ܔYXR� �k؜�������Tux��]+���OƝX�S��R��+����![���K��Y��l4�g���,F\ڢW6t��B#g��1� �'���_�LC�l�F{�ljBA(�h?��1O�@ݎ�}�}�R����e!܍��E�b������O=�z�[�pu�[�2��{���r�n�W��A����1�0X�3I�e�,�UJK�[����W�:q�N������U�ݐ{(ag�T���q4�0�X�G��=�@������@�A�zO\pJ^��cͅ�!|T�YNS�������������Ǎ�][�#��KWJ�=M���
E�&�Nx�BnG�U�o����}2��# ���u
Zs8"��xt��!Ǚl}\��0��R3V���)a�+�>��r����5��l�db�H��P��hC���y�F�:.�i�37Em�XD6
�0p9�����H���Ge���;\�8���;�� eы����ߏl�r$m����>y���R�慃*�)ޅd�P=5�=�O�LF�v8=nJ#h1D�㙕��S�]}��*�<k�R�t�
��؛��K��NsB�/����j�����8�3��GvA�S/G��[�l��H+��;J ùڈ'uJ9�	s�tr"=sRc�s��2�AO �O���\�K�
�pHp��O���zIdVd>vs���� ��Y����	=l
�1�4Э������1q����>|T<i����>��R|>��_���<�^��}����$'`�� �AeXrkE<i��|�v!��븻���'��^<� �ˈRDQضBb����D��8N3�ߦ���2ٴ����m\�� zt�L��d�R�͹"�s���׶{�d�q�v�����F?b�*���K�k�#Q�!����N�&/����O��.Rl��������O�.�wB��n�R��.g,j`ƀg�yJ���te��qQ��ql� �^ł8b����/(���U|wV��TU7K�js/�t��<��5���2�u�Q�	d<�/���J+��~�f!��������SϹs�x�Rq,"�Ϛ ��?�5��@ģt\��*���#ÂO����le����".g	]Q�O�X��UU%���faI\�͓����'UJ�l�Qz�P��p���7P�ԡ�M�G'\| �.�o�;�p��Ohv��z�-���"x~��yu%��|� 2u:�a&�m�`��Hw­lS��2�JY�'?���nVϧ^s�lS���.ɖ��r�Q�9�������(��Μ���JE���Ze���E���l����30ݕX�U��"�"-㒱�ǪՏ�+_�֘}�_��V}Lt�hI��g@~��:�a��oNGA�����(�|��)'�C���G�s�݇�0��PݙB��Zs0`\C�3���~��l����i��O��k]�(W���Ұ
��;1�O��!�~�Z����l�g���:.��`����{���I�	�n�Vz��c�H%--{��e�f�}�z��}�+ͭz�����H��Q	�A�
2g�B�] �'�R�� ����� &c]��%�ص���������j�{��	�I������pk�7�ْlz����Ѽ���Ը �`%7����>�YD��uz�.��l|����@���y� �4�94GL��Je-��K��I݂/}�h �掄S�_�
̧l�s�1N��Ȩ�.�yX��ݖx�hЯ�˓ucc�c�8ս��\Uw,��̔��Gt#q�`\@�o�`�l��*�����z"m8p��I\�ԓ��x�m@��G <X��T��j��ceю�:N;b�]�q����|=ui5;v�����pUrc�?����]\!6)]1����j!�7�����[�����f7�+s���<a�� �W���;a�Հ�z7.N&k���g���ִ��m��*"�c8�O�;��b_m�f��qظ�O	_ْ�/%�(��J?�h���&����2b���l�����,���BHR��6����lɩ���H�;d'5@=�������*�Ѩr!��H~�ֵ���*�My�x��}٥��8��t�O���th�c������7 -B���¿���Z�1��O-�33�,MR��KX-dv�=!w2#)���r���ݥ>yL�?䨉Q_�9�nn�_ �7׹zGn���aV��6�0?�}cB�>xr�R{�'q�	��Um>2͑��%LA^h�g�����_���g]n��2W�E,�-���C�H���i�E��Y�o�7��[.~N�<ki1ұuY��w�1��|�z"�"JʆQ;��H�K.Ἆ'� �,���*�̜J�X��h'B������,k��-u��**�T�:���,P���u��\�����A�dR�Nqx�p;DB�Y!$��|�,�MD�As.�vFgr���Y���bF�c';�L;�{�tBu��Vy�J��a/��ky��hla�(�ݤ�K3�İ�df3X�i��]x�(��FZ�CF�ۅ���gF2���B*�h��_Eb�T&� �B����)݄��S{@�(�b�Lu�H��ѻ�P����t���-��7z�d�YG���k[p3�5¿��j{�cy{��G�2�Jy�"���� ;N
 �u����qU ���b��H����kӘMO�=b���"=JYD�ޞ�4��kv�,
��Yh%�#���A��dè	3���%���/{�8k�#Q�5�IQ�#�g�vUH*E��T��u�cB�-�����q� p�O;m�L�1�U�ڐ��Є�ֿ<B]�a���hZ�g�x2����M�E��;�޺�s��B��9�Ŭ�z̲��~יV��Mv��/E��W���82��a��y�H�]R����`ћ��[$�8��Z#�.��Qv����!h��J�r�����f�d���)��e+.�:�?o�4۷z�]3n�@��N�G����m!A}Bg�l(���b
V�mwQ6�H2#�8��1`���U)3oSm���'���)^w��o��(ib��9�9�jKPYz�e���Es���x����Af9A��E�U�9�+@8jp�ѻ�V=�<�>�І��E[[��GNj�ɩ9O���~������m_�e@'��>i���xX�K|A�t����U)�h�%UܹkޙR�����,��b���?
5IIG�Pu���"t�z��]�g�u���<� �V7Q�
�w��Xik��w'��D�eM�N�'��K�ph��n#��	@���-���u6'���tJ��2_�xB|�/�[<g�A���o8t�q=aq��j!�������������X����u q�l�5�<�-ŗ�\8޾~☿�ƥ�PB1��Cf���2p�דo�Ɩ���|�;E�!#*�� �%�מ��[�.��g�(r�y�*h� ����>�������r�u��?��%�.���]�}*�]%4��>a�m��^8Q���y�������J�_,[�Ej�Ϸ��?�E��쒘i��Z�%	E�֭��a#pO�}Fm�������Z���V{�MT��f��
ձ��q9\�������\�_u ψ��m۹]Y ����&Dr ����q��8�R[i3s[��x�w8����Ҡ�E[J�a��:a�h7�8=�`V^��>�W!K��]>�GR`�����hҋy���6�Kׇ&�P��MV��֙�ڿ���Ze~�?��Y:�-Vv7���¬L=��W�>6����f zk��NK�UaCߨ���`7~�]�r���a�F�����A�FY����	�ĳ�[!���\���^��qv�"�D�`�A���_qK#�¤ע�+\�%m�]8�y�Ԭ���}�bՕd��6�}��QC�9<��K0W^!|E� �'�M�#?>o���L�=m�B	��ڌ�!Re�L���o�.�J5��)��	�}(:��a�;����4�v���7� ՝��[�}xx��f�g�t��_Icyt"�E�d*��
B���7}�G�/�Z�i���ܶ�V`M����@���ʨA��F�¤�{@v���]���Z���ڿ3枎Y�3?�iX���?N����YG��J�Z�f*����k��*���	���TJ�@!J�!L��)>p�t��\[Cc�K(�?���5� Ʒ��ƺD��WB��U"��@�D�4�
�#�U�`�;�@T1 �o��3{j���W�x�=f��D�/I�P���Mʿ�����n����>��������G��1�N���L/� q�IxqHiv�=�fU\�S\�����-YQSLh����é�`B_`w���?r,3��A$U���4s0&;(7����z�x�����V?����7��>Լ��ս/��만�?�/v|O�	��l�nH�Oݯ!���@tl�� E!�H+�Es;,���8�	������������H˶%Q��L��[��e��g��f(�� ���W�L�mOQ1�@��H�%� ']�vU��4t.G�6�^7C��ɂ@dC��~��>nߦ�
t����W7B�9L\�U!�Ea�
�G>nx1$u��[�z�Z"]3��!}5����
�v��f��ܖ��Gat��χ��n���$�J0��l�M�����'��S��F�`�Q$�sg�[$4��
�0tni�Fc�ơ�����/D�ܩ!�e�d��8+���0|���8���	�RĎ&K�U0g(��V���Ӎ�}�Wb#�*.�a7w����kj*���'��F�3lg.����y����ī���F0`-�+jD5�8�|�����0(:����Ѳc#�̱��^��,(4�]��&���YF]Ǆ��.�/�]�׾�@�"賈��N~(Q�\��e	gA����L��$ں9Է0�/	�K��2�;�L�6Tk��9Km �j'Uc�}��u����e��h E*j�V��CXI`������YZ� >�����4���`��Z9��,�5}ɞ�-�3�����S'�T�����$����i1�4X�)X�*$arSu�j�a�	��w�T+����k�j�4M��Z�¨�%���'J}><�I�Q����Yמ�;��x�P^��r�o �yA6ʇ\�2x/��҃���S�1qi�D4絔�U7���f ��Z�h�[=fA�;�/̣@]�h�Ƌ�32C�(i��em������$��A0��f� 9����v��9.97غ��d���\�7��{N!U-�bq���Y�;����ij9�)B�����v���!��
�M���nzxe�n�T��b�OR<|��:�#f����gZ�/��д���
�6p!�����$�Ɛt���f�/R:���"�u�A�[1�o'8�H���}� \�V�d�яl�ԓ��!퍓��(�0�藩���/,#}~�Nd���!�1���K��ాH�m7��I׎�*i$�b����r���.��鬪�pI���E�]O���KPޭ�,����U�?O� ��r���VCp����p)xel��O�P(��{��Ә�HNr�$RI�[�/��s{+]հ����z(��/eM�[Õ�q)�[�,dy�G�\&���/ԯ�E��R]n�9s2�c�8<X��p�-ZF���ѿ�Y�I�j�e��a2��d�hZ�j���>��cB��潐     .!���(� ������忱�g�    YZ