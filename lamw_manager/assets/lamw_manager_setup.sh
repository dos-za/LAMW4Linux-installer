#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2028769669"
MD5="95f5b91ae7da45961129fc7fd4dbfaee"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25624"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Wed Dec 29 00:34:37 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���c�] �}��1Dd]����P�t�D�#�d�> ����6~�< Aiޏ��%�)r�\�����\���c9�l.�:F�6�s����-����`-��$\�7W@�ί@�evY�0��Ӏ8c�yl�qa͏��|�ѝ�m� x�HmB*O������}�Z���>e��p��3c,�燀l�PU�H�o� ���ܩ��Ѱ(��1�̎�-47�ʡ�G{So\�`�Ve^�N���1j�~��3{��3q��[^f/]����E>vy�,�@ѽ:�~=f�]���z�y������}cٲ�7��95�5VBJ��Yt��'��_啇�>�$������q_�e3�I�j��6�̈́*%z���!}�s���>������i's;�"T)�39����,;��������EŤ�I�/Oje�ـ`�*��(����D�:_�A�r��F���m#�J�g?�P����~�Tr�����XU&"pޣ)����~#��I+@/�+D("�.�V:H�����ZĄ[�f�"��$��+�����m�Ѡnݮ�}$E�偮,��\�|6�7�i�%��YJ��2c-��)|r���\Fb
��/9�T�rG��iC��{	�Ns"8J��?��$t%@L��s�ـs���zVYc��P�uRn��5�@��1���kin�4)���mN���5��t��;�Wi���,ǋ/�﴿�˭�:�� �,�UG9���&�OZm�����e����b2�@�����h��Iw�{l�Aް�K����^�m�ӯsf�9j����+�:����۵2	��qRe��u@{'�B����DL�|I�iɂVhǴ���fqtng�Ĭ�}<�w����J�Ja����q���5���j�I�C�h�����(k��~Ȅ���{�T~�'	lݳ$B�c�}�����oG6g�-ܣ��!�B*���7�{0��a9t�D=�TB}��[��:��k�p!�<մ�������M7���g@� =V�=��t6|d�^���o����b?��%���_�|��l3�j�!�Aۆ���yYO���~�WH�M���p�S��2�PNuC)��f��'�SF�p�[
���4�	[l2o�q��P3�
��_�1z�-�V�@�o��s������8S�����2�zNȘ�K��"
ɫr9�K����.q랎&y�OO|ͺ����2�*�m!���1Qk����pD�Z�.=�T��F���D	��01jGR��iK����N���f��a�r����H8��| ����aU(o6�����K\̲,}�(!�����(/*��h�bUU1�G�h��"]e��"�<�O�<��I}K�{��İ�9^b�SH:��yHh�A����5�쇢s.����(F�����x�8�P'5�Y��C�|��Gqdt���"*���BrT�-���I�(�c��|��9�K�*����:����e��r6�x��vpN-
놸�'^��E�`O�_��ZA�m�4�r�8�u�v� B2a{�..�gкt~!Hy(}B�:y��3��}Y����+=�T�����ilS_�%}y;.Q�G��#[������!�����\��wWY�CO����:[������/�5�R�*�ć!隽�*t)�J�Ŷ�?���)��t�9p%M���h�7��d׈�jޢc��(�q\��ix_��`�Qߓ1�f0Ƨ����v�-?��{7:�	�,����'��Ap-������н�#p�.tOz��6�4�K����QW�l׫%ި���.�y��/ǎM�� �������GE�3d�z�9�IL���tD"�JN�(�0���֒e�PEϜJ*��V
Z����=�f��f���� x.PU�Oi�m�*����t�|msK2[;>Z�`k,W�*�\&���d��`+u�NxRR_ e��.��ȅ�y �@"s/��9��i�������/햣悔R���<.�o$�E�4j�=SsC��f��c?bE���F�O��p`c��d�:a��hqٚ+���5Z^__�����Th�'�ٺ`���N�iDܺ4��1�62Pm��Mƿ����@�X��`2$�;e907pc�I�����G�
���;jmitA�Hj���{������I�@�T&Q+^D���|�R (���*Ŷ�-`�����wڣủ>�Z����ځ/�o���kE�B�k�-ަa��_�P$H��El��C�E��a���4���5й�f�28�I�җ�$vw�Ԍ"�6�Q�zE k��v_vf���Sq+i��*��;!mE�%������Tu"�|�,����Y�m����̥V �C6��,{D�ZK�_�%������Mʔ  ���|繠܃�L�m��6"��B��+�3�;�Z��]=���|>��nF�lm��`�|���ؽ��v��o|/�x4UF.$Ls,�����LH�����S���"=�K��Ľs�NP��A��������\���^��V�!��ܡ٥O��,��H
�$m�����E�I��$�.���E,'$p�������.�X��+��S��ҚIr"�x1�Y/	^L)�T�^�0%�XieCO�a����=/o���^�F��
[���]|�"�U]7M�g�`v�-��o�OU�w̴���p��?问G>G�Nbw�'P2��%„'�P�ֹ�/�|�C2�˄�p��P�$�{��V:��mn4��	�q{u���.�?�[�≩B��iu
�6yY�!�Dq>��9	ώj����[ݯsr�k5���Wc���|�!�Y��g:��m&�3��0�=�I��z�(���w�p�<W�!>�S��g�K��*6s��Z��Sj=���T��E���yU;�pH�?0�;b-��C�=-!�	��#��4`w۩�io�� '�+��S�լ:k��i|݊�:�Ι���I��L(֩-2�V)zI���B��˳	��N	����]W���N����ٖG}bl�����$�3n~�-X�+�ީJ< _�o��*�h_s����W��D�����o`��n���l��?��²��M�<r?�%e�O�RL�����nsD�s���X�:}g	��-"��}��xWf�i8{�2��':XŨ}��vaD���:�b�~��ɯ���\Ů���Rض�<p ��!�A���:��,�87@[����P��V��V�c�Ӎ퉽��s���d�Tt������#[�&�`�������V�@��*5-����-����j�����-F�e���g��J@�����>"Q�\�AX��C�Dù���:)��{ݲr��a�(}�Wn@�:@�aT6q U�v�t���5��)~z*i�ĸ
�ݰiw�R��3�ɡo	�bQ��  o�;t0zQ��ߖ.%-	�6+x��yܼ����wwh�ma����!��}�Q���~	��6:[����C�d�nG*�|D����B,/o︽�9����_<���5�O����{���{�NN�a+�.A)\	i¨Ɓo!��G����U �v����}�sq���� �1j��eY	�ܯ��e��D��a��T{����e&����)�.=k���ƍ�Nl�ʌrw�u :B<�Lh���iK;`�ЙM�)���݄�����%�����i�K�Z&�*��<]r��C\�T�0�@�#���F ���Qt�DDX�8`��g�yĹ��@R����C
~�4��ǀ�ߋ,f́.Gt~��}z��ઙL�ߌ�27�!�9I?����tu9*�_�<�B�b���µ�����g�������.2Υ�b$���@�oէz@���:gI��cZ
����>����ld�/�O�`CE�S#��+r \����P׊A�rKc�o��r��Y�:Z�L�Y��x&���=6��Y�L�E����\�e�6�/|�غ%S�U�e��L������,��c�uh��U��i�5������{��#��b6M<{�-b���G��+�E��w;��[b����Ko��UE�H^�m��<��`�!ռ�3�V�fB�<�Is;r�I�U�y����Y ����R�_6i���{ָy�mkj�vu=���N�F$So�YdP�V���:g���@,��ەT\;R&J��Q�*/E���R��+k�A��#cW4Q�T
���VĚa��\W�7�K#��5����P�E�a#N����X�ퟱ����B�Z�վZ޸Ä��69��,ՙx �t�|?4��9���q`_�'����Κ)��/;�a�@-m�@ٺ���$��pȅ���i���X�F���Ů���J���nE���^QK/��d��dcW��@C��hK�����?�Ϸ��Y����$H�����S�6Dg�H��(Ҳya�U6-��œ~�eL����v���d��a;���o��-�^���2�hKsp��B�h0@�,i� �����C.#j͜�Ro�\���rp�S`��[���q�t�� )�����U�\s��F+�a�Jl[�Ύ�<��nM}���(�>b�Eq�����\#�p���cԓ�����Z�u=��v�De�v�"a~��@��Că^��+�`.�>�q���0c� �;-�s��C,���ѰًHZ��?���
2���7�k(	�Ϣ�"N������޶S�?�W��1�^I$�ɋ��[�~9Z�ݵ�VL$��H�dg��S�F�M#�t�������1�}�Ww�ݖ�F���9��'��G\���a+C����h�S5�4�K������T"|To
��B���'�!Jq�����ޣ���_�3�����[4�L/%��<F���z�WS�ޔ'���\:M�$O�Y6���z>�P�L�2�D��G�>m����vb���X�*�.ub��Ch�Vt�_��}fn� �y�{��ƷryR�Ѝ�.ze��ʢ�YwmȮ���VՄ������ �"�鈚�#X=�ugM����ac���#ь
����F˄�̉�g��Z���I��U��X���~p��f4�}�/wkp��VRl����m�͋�s.�8�w�i(-Sb41h%W���Y����L����Z���R�[�E�=8�c�}Z�E�o=
�{�{c�6"]�0��A�I
���ܤ6*���3)����>��P��AIsHv�_�6�ɨ�A4�Wn�(��&���(b��0�E��%RwR���Еē7�,�uh�4{G;��mM1��Dx��
�=ţz����lP��&�_���tb�nL��^N\+�4�S
:�!:�i�kf��Dw�M�K�)}�E�wl�q����`�M|�-��:_���ŦVl��5�����Վ���\<G�7=W��ZUVώ����a.'tz���䶁�.�t&D���}��»�8G�7��?7��/�HBNh��d��L�S�(��)to�N��0�nVm�G��F�tz�F�7A:�z�X0�,�m�q�B�i+��e��տ���ȧٖ�OE�r*�+r0xgR�7��Y]9\J�K�^��wT8LJI�.wM��	��ޮ}7N�/6����j���ރv��َrlӼ�$��?�����6qF���2�T��wC:s(�:$Ͳ5��U��(ˆ��5��8��!��K���K�dz˜;-�3��E��Q�h2��/� ���fѭ�2������j��6QP�w߬��w��[�
x@I�<?�&�����	�#d�*�%@��������܄�7��'X���L���1U�FC�{a؏]��Uɫjc@5?i���~��4 �瘟��(�U�^u�!W����]_�c";P�6l�'v�,�a[�G��X���G�5��W�Cl��bF�J��w�_.[V7J��8T)�yc|bQ�bN
��~2hD�Θh+������8�y_�şK��xj�����>��hzØ��nH`���I���i=�2Ab��.2�>x��>���\�.�G����pS�Z/�}�*y�X��z���BLCj{vy�<p��e�YgaCi��+�a	<����=�>@�1u���".C�(q�M�9ρ�}�OJ�6<�y�}`��F���	��_�$�:02(�P`��2����$�.&��sWa����£ɬL��S�wY���<�H�\�M?%�v�2F�$vD�f����+�Q�D��h<���ȯN݃��r��l���?b�J�VE+2���A#M���p���5��>�vw=q3�����P[��n��(K��)����L;���bM�pq��(u;4���C�,tЁ�j��z�b��D���o���5�K��V�F�9a�A��4܆������G���欃� -��+�Hf+���P��5-c�^'��c*������ܟΠ�Xy�~Pc��R� 6;/�?RXZ�&{�0~��>/^����YPG�������.�?�ތff��5|��$�r�=�Y�ģkl���Z-uq��kZ�{C�����UWI����!/<|��]�T<˞`(�L'i��#')�פa):��5_Uy����D�{P�6'�.vz��ڣ0��h}�����K�4Ӌ1����x��K�q�����b.���I�D5exu;+�	3Dł&���hz��v/!��׺h�D9�����)$S��n�C�,��\�ơ���5�g����xΘ>��x�Y�����jE�p�<�|;ue[�}�>��fQ����A8�Ai"N�jV(4���N�o2������+E��{*�H�l^�)�Oq셐*ԵG�]2�Yٻ�����}�����Tq&i<�{XH6���TsG׷`x%9�d�Ȍ��.[[�f�d��\#U�Y^ԣHm�6w2̳�rІ���$��;�cĽ�#�X0W�8�]�'�Z��B� 2�ZaIs&ޛ'򂗒�L�O��8�4�Y�+d��s�	���n�4)t{n�ݼ,K���=aUU����b+-��~M�D,��1��y���e�f�6Ǐ�H������h0c�؈����.1�IM<�Z"���#��z� �g��J�;�Bx	��Z�B�!n�>���VɁ���������b�e���p2��#U�f=̘�}¿�rjF)�ŕ��x"�4z���2-�*�]가ξ}y�P� L�tL���]�e��0[A4�E��b��Gޛ�r�����{F�H��� DM����{�ip��� w��2�T	�	MA�A27}��|�u+z�'te�jnɇ���&S��/O��m_�5�*�M[<P=��1��*�ڦ��s�XKu������o�ٶ��XUu8�0(�8L4����2�t��㾃����<B��:!m44���
�����}��&��G[knd������D'mΩ Ly|� �E#�2��p��9TT�7F�����Z
�g8@wOb/N�g�� /���B��J��?�1�$��?S�BI�@R�΀�6�t���z-B:rE�v�ct�X"�lf~�ޢ�xM5��<����I��Tf7����R�������˦�r�2bK�3�M� ��=�{kN�!�f0�bn���P(}T��Μ�F�-�(������.,BK�x���NK�Ã:��>G�~�x5Ci�S�<MH_D���c��DZ��b���v@ĀC���ª��3��p
�$C,�y����<U1-�h�j�XH>^mj�,t'u�Eߣ1�B~I҇�u��-�swXw|��)1#���6��H���,riIד���s"��T�E��D��\��)��/E�{.��W���D	��[#L���g>���TK$ߤ����UH�o%�M�ʿ{&�qJ�·A��2���s|� ���8�D�}J�j�8��e�[��`� �p�E0�/,�@}3�ӧ�Tϣ�o�6d�s���Y�Mc,��~�4TYX�Y;�!pP�_������9��ʙ���<�����az���Je���U��^U��*c���R�z�� ���̅�����_W�a�!��/G�53�<�K8�XBb�瞺	x܄f���d�Y5�Qs�֯�M�w`��M���C�Ęb�����Q�f���	�	tY��8u��X.@�6���L�;է���y����0�\5�Ľ��.�:rd�_Xin����9���� �����DF�|�f�k���,/�̓2j��:[�1��gT��m�`|�\�{ݓ�Gޖ��
r�=�X�r	�XVq�6����a�j��?ܻ���!��2l�k�;ۀ���a#�Wq˦�;r�!��:o%v�� �pW����Z�Ԯ��Nd����a����ꡤju�a:�t�9j�\ѽоޥ�\�@��"@�XB�B�}�^j��/���n��T-�Z#��;v�P[���b��@W�eA���� �_��;�D�֍w�gIi�>�R9����i���YH�Rݠy�<�D �14<*�A���.�k�.N�)kr�ʖ�9>zR%y��2���.m��q�v�	��C8���XTÊ��\����W�v@%�?�{3Y*��|6f��l�iӳ>uCj�.l(Q,�W�ؐ�i�V!X�j�V��k��I�ñ:�g�4�P�ٞ�C�b�WH��3���5��䀽�!p���Y�$�Z�j���A7��g�=��̾\3AЖ�2%e{�!����Mm�fvk�Y`�1��G���6]���h{�#�B�ӣ+��/?;v@^)��*�8��k��+{��|o�	���+�<�ݹ��[�j�3~J���'n8Fb�"��)�Y��u�;��w��#[4�6+.�AW��8���y_�o�3R/�����r=��$88N͒Wڍɵ�m}@}��.@�|�io�j�w��'�6߫�*ls< �ԩڇ���X&)tP	,\)Tg��2<�c�1�yd� ���MN�:y�)����b��mxz�3p��{�]����o�vst<�Yi/.N��!mZ�O�f���a_Q枌�O^]�h��@�a���B�}�����x0��-�{����f� ��TL��W^�jp��çi�8�ݛg��Z���X�*�z!�-��os�ä�54ց�ҹa��)�,Al�~��	B?+�����R V���35���_��@ƫ�7Gt-'�dI@�H��%��
�k�-d8۽& T�Z;��/:�|Ҹ�vq���\��>��r�qfJi�>�7d�����Wһ/7�
�H���q&�[���Y_�Q�y��ƚ-��U`	�u��M�8�7�<bB��V�_�v�!��/�K�a9����=<��E�aXZ.��6�j���jM}9k`D�g�H~�F,���e�b�a;+�=����L& o� d*��8�E��ۑ[Nm��NW�h@
^ph���p�����'�FSً^�s�y�~��Ͱ��ų��e��T��&�"6��Q�J����p>�������&�������d�y]��!7�?�`�|(Bx-	�D_�0^�dF� ː�u 1eopw'L�.OH����tV�p�V=� �	�ϣ����B��d��A���3���0_��-���Gl�ʡ�1�h��?� �XZ�'���bʺXL�"�V$�!O\�_d���D��w	�O�Q<�>����@Zf@_�wҫwd�Ϳ�#!��Z4M�����7�O<Ib�J�ahq�Yv�Wd�,�o����ĩ_��2�%�M�[8�.X���=�\E�[�sb�Ý^5�����i�B�D?<ۜ8L�q��^{nF��!���JP��#����؂��0�Գf4@)��x������>"����TJW �D�z~� ��i7S���徃������	a7��	�龠�>�������K��H1���%n�7�uv�I�����#��?t��� ����6�*���V���Q�Y2��	+�H{�>�����]�sOR)A1�#�6RҖ/���\�V��X�30��;��]�������9,�<��mPfm���S~�{��&��U1�T(�^�h�(���L�2���vn@ӝ���C�=&P2hmO+�^��s�H$�}1a\�7A��9�¾�Į���dN�|��C;�Dy�@���}�{s§UT_����p6��e���Z�ry+xQ�	ॅs�`rh^���@��ɱ��S�;�Q���ә#��y��(�IciD$�x�zЍ�$��<��<x٬�N�\w�/�����-��tO(�mU:5_��[��$zZ�O2��TΉW�����5O��ٿoLO�}2�$n�Z�_QPBc��t#c�-�:	PH%�#\"��~�Ԉ�Ư�,_��{�P��w3�e�_N�V�o0�j�T2�����]�SG�Z�K��0Ʈ���f7O�]5�Zڒꡦ��p*��ŠE�')����L�N��n�׀0d��p%�!�K�=q�\X-�E�'��a�C�nӼ%ynƱ�{t�1�ņ�52��1�]���( �DoM��B&=��QU\�N�q��f��X�Mr���ϡ�[7b�d��'�f���Ԉ+�e8������[�������������N��A���B�=���w9߸1�9$�&�_u_2�7y�OaĴO�1��@+�i�����X�+�-k��,P����|�oF����ݾ�|
d]�)TՁ���hX+� �m�㔫��6����'�z��ch���jL����2�%�4�Gsj�u��%��#\r��&0ހ�{S[�m2o [~V�;�L��dh�jxy�O�J\>,C�C��p������v��a)�p�,5�8�d�)�Mh{t�Y2J���w�`sh�e�OZ�ⶣ���$���T�O��f��C۔�:U瑊����^�0���sO:{j�b���^!��4�pԓT2#SBD�l��`�3�W����DF�4KDu ��
��j���x_����}mO���"�.n�-�>g��R����J!'�}%�,W�"����V�tu����+O?��i��U�I��� ��};ѣ��~Z؂H0�zT�*D5E!�01�g3'�<�����)ĭ:)�N�uۓ��qqZcw�u����{�2G�ؾ��Q���dJ>#��E��}�\2e�-�M��`���t�Gܫ�O���W�Ql6c�.���� �.M�8�d�];�����҉B|}�^�$�?��Q1�N3���\Jw�<u�.T��D.?ߨ�(D��8gSms�����c���~��P̯*�o#*h�k��SD�\qEhUvV���Xe��?�*W�A`5gu�t(�z\�q{6�A4h�݀��a��T�]��vCN�*�ב8�E%%/h#�k#c�u����.�$�`ڏVn��-T�;�%%��ˈ���|V����
��f�"6e
�B��(��۞s�ܟ�]���Z����EB��r��܃~���_���Xo�+�#�?o-j������SQ�ڦ�KX�B=�䥾�m�����:����[��������|d>Ęl����M��V��ժ�ܰ|C)I��ŉ�0QVM,����U�!�7�dh/��%T�@t���L[5rq!l�/�����g���:I�t���vnh`���w�`���)��b�G'�ٞ�az�Z��]�ന���6y;��7ZȳJ)�����������N�^)�[�!^S�ZJ}*t�R:h�𧘢ĝ��ʤ:`�c�bZ�\���CT��#6���g �ʮD�V07u�<ٓK���'Ĳ��u�po�3aX��9��^���u5�62p:�87	x璛Pt��9�)���}Wb�;j25���k�'��,��LMaI�a���6��}��P�ō�_�]�[�[�(�,�"�������	
ɖ��:�m1@�CP�랣����K䳟���O%���	��|q
YwJk�3q��_	�w��F(9V���O��{��Q�=�
��s\_UIY�K�ީV!+#���/�1�jè��з��{�,�)�u{w�Q��c�`W��k`R��0^F���]���X�]{�����V|�][���%ٺ����=�c�p�1ײc%.h��%@VK���[�w�ʥ	b|���Nx�h�m"|�����{,�����I�m��aRpA,��z��N���y� JC�4Cx�7���!��ٕ����A��Q�"h���!�)<IH;3�o-�JSV�+����j+����4܋`�]��q~�1���]*��!��-b+ţ�P���/���a��N�F�'�f�4/bC}�՗����:�9ym<�X��W���dD8�.#��_�ݱCh�E���0�d����LT9f�J�����s���ғ^�wq�U�w�Q�L�(c���:�v�Y^�L`͉�M�t�&�[�	����|��>s+AG��j��e`�|�M��v�%����|��́3�����u+ð)|p+eP\ɾ�kT�n��I
V:��htF$bd�|52�sК�AeiB,&���8|���6�J-�HS�Ό�/���N�#ms�?1�g��-\���yNl�L44Y
�0�l���9mL��	�>�,l]Iw�/_4�H
c��(�����v2\߳������@�34�EV*_Cn{��GK������t�j��A�������Ut/&��lŋ��KJ�C���N�ϗ+�Y�3���~0Hq�
�`e��.�C�Id�Z�uRM|��4ޅX�̬'�鮗E�s���ʙd7_DB11R�������csd��爰�sC��T�t�H:E��/k��� �S-/�Wy9�%��M�0+�k��-�G.ܩ�nP��!|�r��¢�_�	��h+��*��6�m����0+Hc�(�5<'��B5g)��;�oW��'�D����q�w�T��Ȍ�\Þ�>�P��7��ü�l�)���@��-�/A·��C�U��W�ެYc�v�Hj؈8}B���Za�"��G,f,���9D��*��ʪv��/*�&z�����Db�Ya���"���`�kXw�ӑ}u�	e�Kc��\�UM!��k	���֍(F�u�#�e��l��� � �/[]0
��O'�p����[��)~sP<_�@����B�H����`g���l�!�i�zo��x��nE^9��$� ��J�������T:zX���Cݶ]a4��J�n���i�9���Ca�9\P'��f�ٖމ� ���L|y���U�Y����kЮh$골=Y��ͧW��W9��BQ�B��� ��	�0v�x)#h��ӯ^��������~s%w�]�
B�-�y~��9��ER��'H3ѰqSի8G���f�L%t�O�1��r����ct(l�����Tթ����vJ��C����Ѵ8$���<Aֿ��]�wd^y��h7�G����D�I@�d4�3ޱ	�����	�e��Ō~'�lpy��da�hg�����y���v�Uku�ܸ�l~��!E�Hӕ��a`I;��W7��&_��^����?v�>y�1��^0�h���"�5��i<��n?1�S�YqMB�C$�즂��^�y��[D�mZ�ĹBt9�������ٗMX'e����X��\���:�����&}:��nϰ�aN�^� ď�-��i|\�
��y
̳B}%e�х�']�$5ض*3ѝ��ـ�/S>޸��������ez����P8�]���U�)ep��a�j%�*�4�1*nH^|e �1�����sL��?X��Ȥ.{���u��wO��������ԏ��
��gO��Nr���[
F�x�2>���9�i�,��]�\�|TUP>]�d�	LMR�;�'�(����t�U�]ۓ��F��o&P��1�� \�i���w+��TTП�����X���0դuTi:x�|ߍ.������%ne}��ԣ+��44���c���3��I�Ʋ��.�S������X��3��/5��Q^э(1�#��m�]va�Mq�'�iA�u%-b�9��h��-���U %�
��!u�>��e0�ѩ�@Zg��l}�	`8)��0�<W������c�ѬFO_n�U.dAsr!G�B;듰�oEr�a^��H �t���EI>��Ŷ�."�1��E�;��H+!����G),K{��rX-�d+�<���e����)VFw���~�f-��{D�F����%4�I�qD�1l��׏�Q�����Z�'�!��>)����Cz��8�lJ�i����-v�Djg_�x5�
���a+�_Vt�~0�{S"���R=�gr����ɤ�wד�;Ρ��$��,H���x	 ���H�ʹd�}:�(I�m@�s�X��m��&2c�*'��T������x8ܘpؚ�My�o�c�)uհx'0��p/��?X��u��ړzg%�	8��'KP|9P�#To ��0��M��R)�ݫ����w�Y����l�Hy�M�3� X��f��2��f+�W���^I:�ۛ��s�ڻ�%��L�E�P�G9  g����:� �+A�|�pZZ����2�!#\��).¼W-�Qr�!Ę�>27���ܧbŝ�~�m�e ��2�s�qNc�<�x��T��$��!=M�q�m��T�P���N;�WQi��Hh�Y1��8C�D��+���k�t��7��^�ڋe��W.�85�m_v.Q�pJ��(�lᅿqה d�O�[�b�.b���v}w.Oǒދ�׻P�ԜbR*�l�hUZ��u�v4T|֩c��#J �-<�x�	��ȝy������i��-A�`��7�!�I�.�~fg���WL�$I�b�q��M~��5dݡ0�a͇& Yџ%�R��.��D_0��I]]�?1���/�d����w�߬���z�w��ئ.?� �n�В�E ;B��ݏWFDNI���^5*����EZD�����#�ܣ�R0�@|�8�t���oI�a���Y�;���o�>�"q|���C�VG��Z�JDe1�0���F�͚ē�[B��5�fȸj�4��g+�%qucχY��Ĳ��~JH�r�c���K��cL�wݞ�3ҵ��W��M��h��z�w� h�}�ܩn�ʘ�d��:����(�t������ή/^�G��� ^ޢ�.��)�K��!�x��~����KY��C^�����E7t1Ѧ�\�
D��F��i�)֝�wy��Z�}���,��k���G�ޅe	�u�
�D?B�_#��g��?�ws��6�_�JZ2#�P*��&�V�kù���<�S��5nI������Ui�3c瀹��_�5B�j�n��oO���1���[���y$�n8�X�D1�sZt$p곊'Z��8��x+&}���6(�]���[�~%��uN���/������=V��`�f�-s�^vN��In+�`2�����km$����"Zn����ԯ��A�i'���EW�Y��@Y׈�N��.����>�����Lm|���I�f뮠:��B�1����a�`���ޓ�S`�)R����N�����^�ߠwޒ[q����."O(���p��<��͌@_Vhk�G˔��,�β���]pg��߾�,�9���Pg6'H��fO�L��D-'w���9JY��:d�Aj;�H�^]� �N�5a�P��-&.���}:�*�rڼ��- �:I�=y=�&�&�*��� �����,�M����> �Zwg�Q���`�`��`���ڪ�d+@��扒E�(��&�ɜ����"i��է�^�,((���χK${h�	m��K
~�Zw��};A#��T�'���Ƴ�N#8O0_D� ���������QK��9{$[$�m������� l���	�UW"ן�{�+x����2��������I�^�#WNz��"JJH�T�gL}�q�l�@��t2��J|��bE
�q��m��⌸l���z�O�3:9��H1�܀RB}�.���p�Gz�e,�v1q���r�{��T���I���Z���R6 ��H��NT�Ae�L�NK�d2�]��R���*֙�';�g�\�Zt�Ն6+lD��e�km��gxa;h�D��D�
�sW9Ҋ3��rA-3�y'��$��Q�)p�(H�zFxN�p8��{zps�Dj=��ފ<�j�J5T+�	�+s�w�7�P������39�9�W;]�k��9�(�(@���!�2����X"�6*	l %�{B�	�F4�$i���C9��Cء�6��$}�`�ٓ� =� ��D�)�4�?��
J�[� �����X��~���-,P
uM������'C����< ٣�������XS�1��o�BU��E�ƀ��
�:-��k�:�m&ޭ}۵�h�, ��R��^�ڔ��&�z���4��߁���Ƒ�A�k˜m3z���n�|��)w�0Nm�j��3px[Ru�w�Α Y�q��j�7|Һ�J���FB�o�5�U�ҥ|�,(�~�8���Ȏ���S��U�l��V��Q�Mp8���
����Q��V<��FĦա�{� `-������?��Jw�Zїb"6`��'L��gY��m5��;Չ� �N��*>���,3vI��ڳ{��d���"	���ζO�0��M�@����j+m�@�[5�
}#����� A	e�ޜ^�n�����s��嗗��_�3�	"��	�l������cq�����e�:H&v��]M4�sr���+�w� �=�+�����Z�uU�pE[����H�`:�5;�N�w�͝C;�P�]��)(M�UL�H���YzC�V���)�P_�w$+�	�8�6�}���9bK���5;�k��Gl����;K�g�W4\�{�_E�{��u�kb+�=_)f���B*�_/�5B�w��v��Tq�8u6�3�dƥ�(f��> ���]Ή�eg_�l��~��TZc��f]M�3mC)C�]0�w;M2/���H��A�t%�]�#l�s� ΰ��V�\�ܔ���k�_�*�ep����GV��Ih�iV!�����j��e:�D�7�Y|��������2o���N�+�F/ƴ�LDF\�d�F���m��x���.M��=Le�q��:�5�ǁ���Au+j˝�0�	@�w����aN#U�_�ﮥ���C�4����|ꋪ��أ"q�G�����\�kȼ�R����
2Q�g�h��`�q�T�*�N�m��oZZ�����8f���;Bx��{F"*�Bҭ� �nd��a��e]9���e{�Hu����䊍H���Ku+=Ě�y���;�G�ʆ�|)Y�v*F���
dDv;~2��Rd�0հw����sp�'�����ܣ
��L�]�B�B �t��ֻT��2��9��>(ᔟ�u3��\�@>>l��
�ڿ~�ӂ�S�}V��R�1�~�qTh��J`�\9�dK'��&U�V
��ǿh��)���%#"�(��	Ä��g<����~YI�]w���I�z_,��iǡw!��N�gO��KE	���s�)��?�t��TGi�"w���K�	�3�W��
�D��m
��9k�"����K-�xe�v>n���5��M����FF �@��',d����M��*�_WDW����/�疬�O�(C4�M�A�J?�����콃fqE��ѿ�ľ���l��/7��<X{���{X���*d�.B����E�R/�i��q'r#��F�6r�s�d�`�P#�}�)�T��\ē
S��^�jdC ��8��O�������Ư]6];Ow�I )��H�Ş�X=GSe-�<�8F������Ʉ����Ŭe݁ �=�(}�F�%��1/r�������ɉB�f�3c���f>�1���]��W�v}�[�o���>;ri[����ݱT�O����Jbo5#)��o[��P�]�4��yڂ�wF�T��澄�:RI����S6��6���L.ͫ6���A�J_�� �X��@�wS��<
�'7.�$T����AUR�{�33C��7������|����)`#Dt2�UK�����lz��z򬈉7R�`�Yu�O֔�U��R�l�.:�7�l�,0��I8��,g��ݨ��.�S�?��L��D����)���aD����}{�M����h��3��,+��ɺ�d�����wR�܉�����00�?�eq�tF����t9��B(�-�q��Z��dщ��V��AӪ;> ���x���W}h�O�{=�E��
�/}CL�C���lh7�|���)�s�sux�p9_�NP?{�+�3{h��,/8?���$'����!��ШW�� ��zӪjո�L�Tͻ{��i�Ԡy7t�YoWƄ���[0�W8������R+S�g�B�"鱐�U^2�+�WH~�,�ﱉ���$3��ԛe=G�hK:|�^�6�NEn�V# Iȱ�0��h��T�����Ҟ8Jl�܌�#��Y��Ф�%+�f�O��7����!��}$e��D��-��"
�f��Y�a'sV�KK
��JK(�r�GyM��CO����b:R`x�B39���R�{���%��du��$�g�8�8T3Ў��Z<����t�e�bF%��;:L����l9J��G��h��� VJ��J7#5 �5�
�R{g��6Be'���I9�����R򃆜����D*:7��H&%bc��V�"#6��b*4���;ګ�B�@���no\�γ�D/�wҕ�|A�5�~�S��5���@��fe���ez)�(&�2�vB��G�\S�&
��A��*?�����*K�Mo��� �ҩ�\�6R��Z$=��Y㢗7��}�d�pKY�W��!U*�ܨ���'�<'.	io�x�Rn��5/4�Ε	�-
���(���2�(ʒ���1ܼ�L�q�Wq�s��Q��k�I���R5!y��*�r�!�����X����!�� �:����y�Hm�_i�+&�9�����_�:�B�0���oZ&)�4g�����f�/�gG��-�p��}�a�fcAb�/��n z��3kh~���w��#N���_<�We�㊱2:Y/�lZ���O	DeoI~�ه��0/�1���(Эd��?�����~S��-F)�}VI>D��:��<��=-86*2�nNX.`u��w_=v������ݍ����p�"݈`�1,5\���
u�aOG�6�eق�,$X�?"k�1���BW��Z�"X�TU����|�rb��rQ��B��;{�n�@�(M&���p�K�Zr�?%Q�������A0��5c��UpnsK�I���I�l/q��膳�.��:�ȕU{b8gyC���L��!.��1��Bڮ+\[��Ը�Ys��*Reɽ��	׼=Ě�d�Nfs5���H9謁B��Ϗ�Y����UG�D�����q�����C��H�}�"�%�������[nI.u��7'��{�i:�x\Yp��5�6hi�n���A�
$G�M��vh�g|���/G2�C1�DBnĺ}��~������l1���,�k������hI>D)W�d�K�1E�x��l��\r4����a1��dsE&�����C����-�����ϕ"���j�ՀOLO@�=�J��x�/��Dqwɐ��P�j^_]i%��j	��Kqu��'$��������b#z���a;��k�<"�])��W�0��XߟzI2D;Q��>��W�����	1���,�V\�hIR�0P��q <�Z��B�a+�.��U��5մ��:�@q@ڪ�&jQh���7#�����:9��bF�>ǮX�Q���V�e	%8���>� �%ۂp0f[�tT�o8W�`��h��0~��l�;�'�?/���r�Ib�?;BNp~Y8D�<���$��d����0k�,���:�/ �Z��!0��p���B�vt�d�t$�T�+���V������r����?!d1;��=GVA���O9y��$�@��Mp��|�q��K������a�5����#��]�3㞑Zy �f>��.��lQ�W��s+�L��G+/�_4�G�.}�_���As���o]+�b��*�!���������4�Ǘ�f�)�R�<(u8,�_�u���N��i�jm|$7k��?� ��^����F���t��Ǌ�-o{��۔P�u�p߇������=�Bȴ�`�#�PRɸځ�R:]~��T1���y�Xw�.��0t89jϥ�UW�xMr<l l���4��^f�k5��#M���^�?��0� �.�ѯ=,�$��̔i�-�`7a�yx��Q@�ӹ
�.xQ�{$A2Bn��,��?M&��)��ώ��Ȱ���|�b�n�]ҁ����� �u�DQ���5��V ;��h��U��Kå&����3Wg�.[�- 	3�ķg�F��=���~+԰�j7iIh������\�ו<ի'�0y}|�o��8���fH�;Ϡ
�Iɮ���C��)uLUd�1]���c��F�&o1b�R��3��D]9�X�;��T��ui�=�!|�)6��!�J� �� ���q�T�L���|._s��pꧬ"<$�`����NSK�v�k�_��'��o��ޕ�L�O���,���2�#���P�yz�a���u�K�r��t��3/8b ��^�"�ʶo���/�!�|pT_>֬%�.�b�P�{��v��'0m��$&��9	�m�����h`h�5ʇ���2MP�h� `�,G�0y�T	�m�$��Fq~e�y�.h�#N�/昶�c��"&*ͅ�RZ�G�׏�H����7����z4�?�^P��UY_���sNd�Xv��\�ą�2m��X>��8+��+i�LS\��*&�9�R������Աn>(�. ��hW<�=է�%�,tG[�X�ʤ"��s����k�[#���¤��O�"�ߕ�B*E�������j�3�M�E(�u`�{Y�7T)�Um�����6�r�G��L�r�X֨z�t��0�H^k h�Q�m}^K�8�Ў�'�*
}��e��iV��{{rQq%�X3�&���v�Y��$?�1�/|8�k��^��-��4�km��gQd^ i���֪Hǉ�j�3`8@R�)oA����� �t�� �{N�i$VϿ��ާ�/�&��Q� 4��0�j0�ϖ@Y��;������H�������7^
1�Qcig������:�:�́�O,�;󌤮�c�^&��h#&��DY캺K:�
�W�{�R�O�3��fʵb�M'X�~�>�{��R��xɟ�Er�C�?������I�Ml)���Y�E�ٳ#������g��$��H4���f��N'S2}���T�=���T�Uv�Y8�I����ڄ6��2B~f*������Ys��;�A���\��}��"W�r�T��;|5�x8Y��@���L�
�BB���Ez��_zp���ԉ��00N�(n�q���'h*��J��Ze5�s%�4�K����z,:�O+ن�g�ÂnG��ޛ�o����T�QڵG�pF�J����'Y��>d��v��z�|����#�o�����`p��Ʈ�8F)U�^B��9��'qzU�=�		�&lk(n�C���&��\=-�)�؏\#;��	e��K�\mO��K�n��C~��m{���^^��@A��g����K~fC���>�CE�d�5�ę�-�X�).D��36R;��'DB�T������i���aq+j����r9����۹q�@U�j[4�-&mu�w��M�S��ZH���l?�6M�7��� ����K8�qR�G��6�C�����DB#���;+>-���f�-���!#��W���U<-�f�'��VA�y;����-΃fѢ��mT�A��̟C��P)��[N��Ӱ� �O����%��|���a=a߷Y����;�4���@�7=������H�ݼ���$�6���h����<�I!H�]�����p�������>�/��q&>.��q��ni�=oh崈 UfC��cU��F�`m"u0�M:N�V&�US|N
)�,�?�Y�"'���h��ܤ� "zedlr�/2�����	ٵh{	T	{�:���ԙ�X~� "q�`%z�k���a�Q�N�Ͻ`���w�$�p�8�����l^q<�"�tcB!%v=躯P|�*��e@�� )�o;~C@;�R�j�� ��uR�xs�b�jA��N� XD$l����D�;�i���o�^A�v�/d��v�_�~y�-�����z���^��#s�p(p�E�_@�.)ݴUC�^�X�Cߕ 7ظh��eo�b:��?��A��ZP4����B�����=��T7\�
Op�����Ab�oTtX͍%�wy�`���6�r�2T}�	C�^���6D���{�"���j�&�Y�*�L:�.�� o��Bna��oz��<]bm\_Π�J1nX���3R�al�I�d�A�.�?z�,c�����V�H���^�c�YQ��S�U[*�Ppq��%�8����A)���l=�?J�\�}	�i�fbv\)�#!�����1
�f�-j�v;��w���>�_��<$ri���>\Ė	��V��|}�0�n위=�[�`�vB���0C���x�w��w����hT�i�,at.d�<~�B���{�%�ܼ����D|�!{���>�'���=������:V�|*?�?�ӌT�����{�$qe�iU��fr���Te-���,�B�W}���]�p{LYݚ�O���'����Jl&���(BW4�<7���
���0��A�S�0�r-S�<B��I�'�Hˋ;�I�+�{��W����:#��#�J�2�3�5�Sv�)r�m}��"��
��d��-�
Ӹ��ҽM%Wq����@~8��%�	��ݞ��Zj���:p}�G�p3Z5,Ód)��m 5��:��!��P�F�a��`���+�/.��e|������C�����z���'���D��u�V�����I�!3�A��Z�_�P~���m��]��{��1_y�De���.0���z�3�vS^��{��rCq�����5L=,���l�3NP4�\!�y�zEMK},�+d+�'��w��z����0�5J^�M*��`�"ԟҍ�1a��[��~c�d ��$.F�b60�/&�f�"�v��	tE6���A�&���
֥yD^��#���J���z���;�v9�o��đ ���_Ĭ5(����Y�_2B����)zd�n7;�(7$)�O�K� �HwŲTJ~`��2��o��E�p��@ȏ�1nL�k �p���O5�i��k��'��|��\�\�S��n@C�/C[��`d��#F=~8�2z�)���M �9�W	�wj�X�S��S=.�|�������+���O$�X+���+�I��?�*��w��b�`�����AO(&���7o�(4�m�Y�\�҄y]X�47�'�ld@��e���x��S=��]Q�5���o���o܍[%C����|����k�������NF��F��\�5��qBo���2*@P
�oL*�?%G���-���%��q-o)2o+UA��W��=��4�fE�O�y�҉���]\MM2����Y������3�r�.N��+	����c%�%�r�FF����/���SK��O����o��AM�۹t���CY�lʰ��Oi�'��az��r`0��W���ʖEgl�\�	�c���2���k_!�͇�������yR����n+Gw�o�`�QpBm���鐦]d�s�R-|��a3!��_F�ѥ��3�C�w|��[�4m �'_m�q���.ǳ���Sڣ��<t�}����d��G��u��W@�/Ƣ��}���NF�WM�Bˡl�;�OU��eJ
�#��GQ���%���Jz�;��{zA$���UK��� ��)�P��y������V��k�7b�z�	���Hh�nVr�Jtm����-Gt��ӍhA���D�ه�����qK�	�Ӵm�c���������n�`e���u������#6ᯄ��E�1]p��*kg!a:7��@��:�u�K只3����~�IX�t��I�ח3����M!f��q*��ǥ|�@$����l�٨@��y9m��>��w���9C�*\���þ��Mͻ	P�I^����B�y��A_:��_�]]�9����tɺ`�u M�(��$A�J�;�z�ҟ��^Em�,<�a�z��,,��/�C�P&s�Y�po��T]9L���豰)�i��G%��
8�e��x��o$hN7��E]6�^��3ixHv�r�P=����x����'!�j�g��Пe7�B�������)�Xj�Q�6�m�n�v��7��:�T;]��y��JR5UO����B�E,�v�`��R+���G�%0T�x�*�G�`=v�;�W5�F^��&�1�����S� 9g��a�2��T�0Ǎ|[|}���,�����(��"��VU�z��.c¡wCZ2�:�t�u��=�م�ӭ���ƦZ4���N��w�?1fj�k�h��U�L��tH�P�L�Zh�}�턽V�����E��oG�ϰ��
gG�K�Hwo�� !�;���~h�'>کu{�ļ^��G�� *S�U7�kK_�E=������j�n�% ���9��aQ驏<0��-�:�\3ҍ:S��v����%��)�xX�Q�h���J�y�v�a��n��ɖ  zG�g�8z(�LC��0&&R��$DË/`GGX�m�Ir��5S�O�C�98ٕ^�����Ě���7�X��,}� 4�#�u�����x.��X^��Sq���y���̿����kB�G4������^��:���t\3�3��ug�'��(
6�E7I}Ԑ5�>U���V��}��A�H�)�í	��h�	� �QΟݶ@錘>���K9f�@�=����&a�J���;��_\��\r�����j�@�=ߤ�ɸ!!�7�!���䐸~zA\�*⳪�#�H��񕛇��s ->ăg?�o��k�ùZ9�H��y�G�����%����
}S0���PS.��[;�7�8� 	U���������|�p�"�R����6؉a�-Ťw@��c�,n�O����@�Ȋ޹9��0�2��j9�޾[����*�m���ͱ�F��1.�j/Ĥ�Q�ڮ/��h�shVrcM���D-'�O�����X�K�[X�	[M5V�OĬ�Y_��U�W T�����&���#H1Y�'�����H:��SI��
"�R����<���D� ��ɜ��  �
�|���� ������p0��g�    YZ