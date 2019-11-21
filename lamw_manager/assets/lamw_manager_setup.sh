#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1347805"
MD5="99975e866ec0224c2f95837df67bf4ca"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19830"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Wed Nov 20 21:41:33 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� =��]�<�r�H�~%��d�,w�u�[�,�Cf[�$e��v0@�H��5(@�5��؇�}��}��mfn���n{�0#lUYYYYyWAu���l����~7��me��ϣ������}
p�����Gd��W��,�}B��\�w_���O]�t�rb뎾��?e�wwv�
�������l}��/��~�NMG��l)U�/��J�3Ǽ�>3ݠdN����'z��#�e�%����c�7�j�}F�hfRgFI˵����KD�:d��Sߑ�mq@[jcO��j�-��|�j��D�J�LLF<��;'��\������+����x	`�ɥ�{������c�)��d��R�*������γ�#m+~l�F�\{"������p�;�����
ɂ�"x�?�hr�~6�L/:�;�t���3�������8mn�,�g��sMF�JP �h�� X�Q����,p��"�a�}*�s�(�o����Z+�E&�q��RN>��-F�@Զ�u�䞿���'�D���z�r�K�H5s�o�̵m�Qؒ�P�-�7���M�2	������E���"Ub^���y���u��+d��� ���[�����sk��C!�,4\bS{
�#q�3F�A;P Ufz@T�ԅ��Y��â��/D5�ꄖQ]�3�N#[�n�b*�bא*�:>w���O���A���'sh�7d ��]�1��6��l��n�1-r-��)*'(����q������&h�[RpXL�Ё�����>�1~��ʛ�,�;� �
��@S���:�N�|قL��F�	�U5�%��r%'�C'�s@߮���lJ �Lw�w*&���K���$Q������vցk��/�@���f�������\�vo48n��բ�u�l��?썡-�M>�>�UR�Y�"{�0y>e�G�K��z�.�T7��]E���	!hq��b��HJQG�H�QR��JB,����pS,���J���1"��M'�T�'NV���]7(�O��jb$�r$���ur��y�<�e��¤vFB�	Wd��5�� N>,�oE-���ѷ����p`:2�88�F=�
�@�����6���~Z��w�>�����s�mR�h�&H��{��x���ZV�%�2vI?�?rÆ���0��O-ŀ�3 F�W'1x)�7��j�_G&_��������݂��6����f�_����ވt{����O��Fl��V���;:v�dz���`�[��6/��9&������u2I�}|b��97!'�`��qSJ,��|Y`5��t���.��C�T��"|�(b�A-�61,d0�ܹ��9eԚ�_�H<#sߵ����[2�1��ex�@U�au�U�NQAJ�٬��V�|���#˯<�a<�]�1���M����f!�t(p�N�*�a?�^�x�E��V?
�Y�i�y��X���x����5���We��A�:[~���}������������?���XW�/
�� rA��uRA4���>YP��<� >�(�~�
�Ó��D%���|W!M��]��J�]�4��@�w����p�ܛEi�n��qɠE�ިcY�����~aR^���/�H�A���b�,��a�Z�qR6iݡ�&���8`:/�>�Ϧ����S]~�I���^NB0�����|ر�W��'����#)�gRBN#%c��U���9O`���b�©�}
1�/V��ؤ��@_0էē���dK�`,��޳ɠ9~��j�|�2�8�CU3`��Q�<��V��E���q�9�h���G���-�Ad���H9�:�������%�޹$�����#^��O��1EY8�ʺ��~��H$"[�:a$S�?��@���ڢ3�k׏ĝ��B>�t	c��^�d�'�M��s�L{���9s���g6���{�&�"�Cv��W����~�c�X�gL���������.��0;�Ks�Dn��*J�fT#�k�A2ш,����c.rTY7�(�KU��&U�o�XAVJ+$�,�\Z��s<� W�h�ó�$1�c�%�8PV)��[����MV�j7+m߿U���PG&�_z��`s��wz�z���Ȗ:Đ�<��Nf0�^���G�ܐ��x[���S_|�KV�M��ݬ.��@D2X�" �*�cJX�Ҕ'95�� ��5��p/{��\�@^�H� ń�3lja4��mq�ԝMO�W*v��@f,�T�
��5FO)p,��q��g�1�����ƚ��H�ˤ?J�E�CZ��h$ [@�|�$Jk��;x�#�X��N��ZÝ�.T�r#p���QK�"���@F�g�VGp4��E��֊���*� ��ӋY"BV������>�ge�����#�,`���mW\����@���e�_ɪO��?<i��D8L�#)���K,|99ܬ�j��a :8����|-T%9P�fN=�"����6��r�T|bwJv'�9[��_"�ya~�]�2��������E�j��T�T
P�eƗV�O�R�ӶI�g�p9��=4_�>�����Dn��MDY��-�9HB�g��_���ŷ� �0���R��ʴe�t��G�nm\�=��ړH�
	�8�͍���l��g�A�}SLMl�y�琓3��bFHB_�9���j�FFLl�]�4ŕ*#�b2�g���?��A����8:#� ؛�{w��k��y1'�N��_3a�& S�a����ʀw���������������\�����薭���?�\ V���`=pH��:̜Z���8B<��]lS�cl ��^W�׿�aG��g�{f�n��|�	�dct�l��h�9�49dS�G���7��:���B�^vN���/�w�ow4yk���3H=+\ ^���A����Q*�!ާ�C\���5���y����W����p����T���b���54/\����������ꌭ��XW�����Z6�����Q�C==Xj�K!��G��x{�x�/C�^q���+�����7�@�8a��=Fj�j���tI�V�lDFK��$6�� M<�6������է�uw�ڰ�OP�U�8W=K@�m�F�Jm�N�b7B�1cb4��۰���Qc��;p]� ��r�v�?��O1T�-��(}�T6�n����B�5t̀��6>y���3����!v	Ԫו�7%)����D&����}S�'q�+
��q�?6j:x-���Ҍ��z�#L~Wzu��$�Z��FZ�$3L��JPJ�*<?@me���TGQ�lB\�H��D�cL�L�]2!I�/��5Dk z�w�hD��`�;:~�W}�����������>�AQ[�������F\��&���v4l��;!��p���
���5��,�9G��7�3�G�!�<�AF��ʵ���s��t�|o3;���I1���G�+ҩղO2��B��>�&�M-�Z��e��%������X��;�p3^�$g�R�Ja�������u�,�_!pA_�p(�#�����(�=etR'� ���6?�p�����,�{=�Y���K@T��\�37$��P���1L=7%Q��_:�oZ�~����u]�TC,}��;�UA�aT|��'�x�}%�(��v�B��|"�sd&�����Nf��O������%�LK�� �5 ��4?辑M���>dq�.��I�-$z���k�.��/���/�?;��y�$��ʏUV'3����Yb��{ 7�1U	�Vm��n�����P\o��%�n=p����q�3קjSv<O�D��t�/����ֆL��S��f�K��F����.���q챻�Fn1C-�|r�hQ�0J��7�@]�.�G�b��
I�>9�*k�g	rϙ�hdaT0�>(���\��9��F}����N
�;	uYgɌs1c���g��9��Ң9��q���	� �V+4��O��3�3��9&8�~�x�B�4q��v��0��;��j��x(�tfc��;�(���l0���B$����C>�=Ư�8�8�{��&#�Frgߎ��k�A�)U^�t�I_�2�׊A��蝱H��0�0���E�<���÷�B(:S	$�L�:�0�{��������9��ڨ��{���J�u��X�[��U
�<_!]#鲰�aS'$��as���N�-��W��2>D�=�J.�'�Ju�E��}�]r>����%��kA�1yfCCc�� �x�X�<�b۴��b���æ͍�Ffݠ�<p=�����M[4���N���nS-�9���E��j��r_�}"4S�][����+<k.u����V�>\Ʈ�ԛ�/���D�nՄ.ƃe?d��l��|ܘ����6�A�DӵG�f�cZ #�j�2�r=��u��Bd�s�숣�ã���\ �[�5�ޫ���3Vd�	l$'+�W�z���q��)Z0�}ҫ��P�g:Xnd� �9���RDB�J��v��I-�Z���+c0M��bȡ�Oi���Pp�0Ϥ7���\�V^�;�),�v��_%y��߿�LCx�K�
�V���׊�4����@��v��_-։s|g����J���sz6�;'q�T����̌�pE��A�W�Ӡ-�,]��X�i6H�pg�.$|:O^�YR˫/�/M�ȵʮY@m�?(��4(j���A	�U�K!$m�2�ח�m���$���$�u����~e[�d��T���t�~� �Ј!��O�����7�3�|N�8�MA�ǏYҳp�/�20���:���>�@�."�J;pY �˹{r-c�w��|��W��j�C
aMZ���$�Y%'�Y.Jʂ�rO��Y%1qZ%Ȥ�{�B��Y�=N�x���U�Tj7�A��W�۝n��x|��Qp��n��Od���/oF3sw$���j7�9o���-�B�݌N)q	<�Β�]P�h�t'hxv��2�7���U��p��a������!|�	Q��~ ���J���wE�L �# >Ig�%�d�o�t�@w&oMWZ� SЃ��(W5\����j�{��D����A&�8��ሄ��j��}����dO �
��k�@G�vo,>S�D����	���_1�Kx��"�S����0�<+��������t��Y[II���~i�C*��j��0�k9DjZV�f�%i�/�܈�v�C�9'�Q����׃�NۊG��0'���_N�E��j{�Ռ�ձ���;���A;���K���'W;��J�\�!�J!�L$v#s���5nk�ΉZ4�x���0y��Ӯ�G��*6�A����P.g��D.a��q%�n�+��Hh݈؈q"Ǘ�W	�X3����KY�,��I�����c���Z���S��k�?�d6
s���:���.�_��Y�����i�Q�IħC�.��@��� �	� Y����i,ʤP���w��]w<.b��������6nd�yU�
��I>&)R�%��l٢M$KK�ƙ���ZdK�MJV�������:���S t�IJ��3�ŬXd7P 
�B����(�;X}�i��.����.<�T	F P�Z�Ze'���12Y\E�w��&�(�V�m��&���w��9���pW�I g188:^(�E4QR`�r��}��������ў(QA ���9hoR)l6�"�ioF�/Y��}��r��L��_�&WΔ+۳���Q�L��zbqeNZ���,��2R97J�h��t3�k��cѧ?�z˹D�rbE�9���ޥH�WlV;9۝f�==���4J&�x`��U�L�k�zJ���{<���K�f���5?�!��,�TnYp.3��
DML�9\�юɾƘ���gH���k=�6�A������Ōʁ?�yH��ˤ;�Nz��������c�ϛ�h�ů���I����>���0a[���8��Q�Ӆ#�$�'?�#4V���1������`j&�N�q���L!�ʚq��q&�Eu<���G�u.�I@�C��w�F�w��H0�pLFC���Fއ}�,t�>x�g�+*��+�z=�
R-?Z��ۏ$��7�r:�_$�q?�~+��z��{��N{Ӂ�F���"�~F�靛?F%�Qd��.61Р��'�:\��d�����EZ�^O�W�%e�Ux���D�q{e%j�mE�� j�����qN���[�m����?3U�P+�IS-�:�|F��`KОLg>s���E5�׫�USҡ	^�R��/y^j���ڏ\�Bq;*����5-�(뼜˵9vA��rj[���Qx�_:��ª�ݪ�:V6��S�V(�37G.|��K�K7)`�^�M�4��E�c��VB6��=%���Qz��Ȑj����b��&ҝ�a��K�5�̔Q�-�����Sɂe�{FY��@�	P5g�� ]Z-��� C�&���'��ق�]V<��9�0]MP��/��;��q�N��T�[B�/�ː�uW��4�$���-*
~21tNC��)pnzG����|ä���������%l���ƭ$�"`�	}|Qg����8|24�7�=��NK땄mi�^�KC��M.�}|I�G'o1K.\�LD�4+�+}�u�����$���]��L���7لL����c��n3cg�LvI����o�L�! �;.��&о
L���Lr���.�hA��#4!�=w�aßYlt����H䮏���)��2���
��pPd_�ca���j{�[�A�v��I<~/���>&��Ի�`ݪ�x6��{!{+�3m���2�˥N�ș�
7��]�6�Q[�:�^��������+�|�:K��.�pʪ�W՝C��U^�'��f���x�/g��y��ǜ� �A4N�l�}�
Q�見�"g�Ъa�n���]���r��q<]�}4��?×ԵI�H=6)',�����{�ȥZ!!��}!~x����i���R��.P�U�'��[n���5���k�����ws��\-'W��:���n<\���{*�y_>���y��n���+�S�O䒫=]3h��=��U�Ξ����Y�v�g~����g9%�_W�ϳx'��9��|�ɋ{&����𑢯)�J�9�m)X�kd�%��b�t���w�2XD]$GF�i;fk o�P���s~��h�&z��fǬ0NS�9�FQnJ�����"���L� ��a$
 �d�+� ���*�U�lD�.ci�Yv`2J\\̣���M�JXT�%1d&��*�0E�׳��P�߱oF�k��Ksh�R�v)Wy6��´Bs�[:�S�p4��G�GM	��l���]&oi���iu�Q.EvX)?\]μ��\�`#2�3�ƨWC�.�%���,�_|>_ʿ��!����u۪ږ^�R�ވs,)��uB�V���(������7�B' [[�kkKD�x-�GMr�M��!��l�0�/eEBm��>.;���ڬYf:=g��a^��ٸ'S�:���◟�*H��׫k>���(M���u��ՋeL���/=o/�x4DߛrJ�������%�=EN��Tk��U���J�j~��/|&%U�ĳa05��%J�}^sT�<��f���c�\��aJq�Q�-7,�A=ӡ�!�ӮڑcL�/S7Fɸ�zGT^Q�m�5O`0�f\�	z� �amY���B�<-�@O�%�W��UAt�J��,�#_����
�_i�BX/&P�7PR7��U�Gb���Kr)�9{R�<].�XO��?�ѽl��f0j��FR+�5?�%y�.&ޠ�h���v�)m�s�/6�:�]8����`\���r����? ��?	�QJ���tw��ӟ3�g��s�޸��s��9��2��\��M���5���oȀX�,����a �"� ����*`ŢPwp$��O����
m�A��τ��%�@J�FCQ�z���A'�������^��D%*p��7��OoȢ�.�n���!yf�h��d x�F��	��R���H�@(5�#�C^�=�sP�ۍ�� ��POOpLw���u�O}������_<o� ��
�"��\!%����#��� )W��+ױ٤�D�8x�`>�o:�6�y���4��-�&�G�aO�bQ��~z�zFF��q���o޴�<�Y��7�apL&�N�{$c�2�#ߎעܫ3������&�$�J�X�wO?/qoG����"�J��M��H�!P�׸%[6/a��lo��W�(!��\�*�8���^"_�12:�0�o���ʪk ~�E�����Ⱨk�,7<�J�OU0�%�ƌօ�����i�&>��Ad
<��pEa��8��R�e@yS�-���A�����*_n��jc6
2�´����0������*m��]q��VՓ��0w��n�.�xb�������qk��}t��W�*{��QG���]���5=@��;��TH�8-]�2�@��6V�}�Y�97���m�8��A�F"���*� ^���9�2xSN�s3RJf�T��ӛ�RfbQMq��Z�9��/��W¤�U@B�й� �E��a+B��
TiR
�[c���tyĲ������g0̨�)oW8��u�T�x*�MX�S%u��~)K ��5"�[V��<<(d6�!3�Z��C�h�G�#���q$}&G ���@����q�9��5�w��0�
	�	�x���7K�16��d�z��Ǹb��i�^X���I�s���JV~��X�xe��Ȅ�H���̗�
 ���2���fe�岽^���~����᭚��6�%���aA��R:*Z�.%Pt��Z�$#���0��͆ez���zF�j���s{N�B7kj�͊�*�K"�.�����Q�������w3�	�}��)�e<����Ӟjt3�z�W�	0�h4�(a����8
�*IKh��Kt[Q�C*�	�y���񌧳�$���aĸ�$�R$OVWtF$ �E)��Cr�}QBJ��%t�E��[p܂�]�Vq�������D�PO��G�v�d��L;�ѽj�3���3����^ �O�ɓ'��������>��������r�/�畊�m��t��^�)���Ϥ�+��@����=vCB���P�!7�1|�����|B�JM7�o�Ń9�>'�:��m��y�n�+���e<ސ�����_�ӳK��9�I�9["R�������ٞI�]� ������Dc�63�c+݌ڛI���g�d�?�k2� ��Y�#W�V.��s�ʣ��R8�d�rDx\2\�y�!��^G���A�@)����D,�C]�R���I��I/m�+���`�/�j���W#9�.�E�QB4�0��3*�Kd�7w��o�疋if*S�N��=	&ӄ!���/]�n�ݦ	�����Oڤ���:ш4CS���zs���d�'�|�tA[Jr���q�)YR��E� N�?��IH�������3��x���x?u8]8m�J�%�}�4WDy�7~!*}Q��
i'"�� �5��A+M�2v�Ɠ
�p�>�|�Q�9dS0,�.�`��*0<��Q�D�a��W�[�g�,l}ELyK��2�x�黎�����ر�ޅ��h�0�`��������DΉ���X�V-��Wתk˖Sx�j̵Z;��C��-\g��4�r�A�gQ0D�`����\a��ق�
c�Y����c3}����s��Ug̷A��Ŧ!WU�)�^�{$�	�[��^���)j#�6����q[q��NX<R�i hq�Დj?J&���LSz����,1Ac�� �y�:g�JBM�J{�li�T5��9?܄ ̦,5.�1�SFo�a8!d��gQ?�\?��@���O}���Q����a�02�����ˀ�)0>O`\�U��������w�͇ޥ�:Up��0��e�Q�w�:{2���k�^	�./p4�@�$�D��y��_�H�̸�	o�\�ÜW���_�FbJ`��$ɸ�u[BLT*�i|�i�e�!,�b����CZ��J���?��	R�����G��gA��O>/�"��=��4�홫V�@��)64� R�fڒ$V����*�}D�(��"��"���{[������":_�(�$��Z�v�
�0��=�Ǹ�I�V�ɋ��)�V^��:���l��_N���%��@1���#��F@G�bYS1.���Ը������z�8�䏝u�x\g�{Y��gQ:��m��ߐRY�Z46E&6K$:u0���!G�Rf��3*��f#�e�cU���'���e�xtU��f@p�Pa�[*�-�:�����2��F?�f����Lu�^��e���Q ���I*�8��q���c)X~ł�y[�sʟ��^(�[�A��	]7U�}$��3���.샽"��I<Jȣ������Z��[,;�
����}�$��v�CȸlQ�<}�_���oR`_� �f99�kjt��f����4C�thS�T�Es�t3S����l�:��߁e�h{�ug~Y;oi�c��9�>��u�+-!�$����������dwO�<�8#7�S�A�a�[�ȯ����e
�0	f����,�jU�G�JB�ЫM�%�=��!���9�f!��9ڐ,���E�X��GbU�b4���O�^wdHrI����X͓��:�߇�N��Ɲ$���
�i]q��ᯜ�+�.&��~������~��}�z�n��iC��@b�{��d�l5="^��)"��:ɿ/-0�J�o��d �"�k�s����ٓƘ3��|�u81U��.�.6�wg��sa�3�|�4$\	1�B%<4(�t�P�yA��qӏZ{��v�V�����<�^�����b鹀�]�X ?Y�N!�R�:��-Hg77MDYW��B�Q���Ϸ)���8��H�6*��%��ṰG�@ƿ�י�~C���[3���z�YT#���BE��fn�z���&a�RS+��(�i*͝��<��B�[�`�G�:{o�-й
��~D}��L�?�x$&P�4&̩�>����'O�&b	����FE<�'�Ud77�5̏�T:bM#��FW���d���D��	PX��ų�9Ɲǋd�Qj��y�B<��Q���w��!�2҆!;�_M�P
i[�PY�/�G���~�_U\,���~�7I`���c7a���Tb��O����e�̫�y�qΪy��R�ɱ�I{�JݤVR�x'
����prG��K��6�W���Y�<���xc�����	]/��FsE�@�X]��ja�V�iL{�E��F�	m��d�BjLj_� ��h*��E�=�-|W^���@�0Fm�A��@�5bk�y��?�h�� �b7"�<b�$�vZ��JT%]a�+]AU��<ޚ�X��Y���*��X$((+�!�P�`�����ƤR��'/7��HY�q��O�}z�l��u'�d ��s�XGt���mD�|e��%q�vl!3��Q���*�'U7!�^�ptΑ@{��+�%[��x�j�*Y���:�c`gq��za�L�?Ec����'���nq�GI�r���T�<�U`Lz��ɒ�I,��m ո���$@w��T5}��Y�Q��X���.Omv�%����	����϶��R�Q�c��J'�ڨ�Vj�hy-V�7�5g��4.��|-���|/b���p&���:��$"Mλ`�9��ދ����<7�T���汻6T�^���N$|������/�T᝔�f��b�p�pȻi*o��WvK~�x\mT��D�&��WY	Uٶ��׼�w$=�6V�IV��?#C���;fg�qm�%Fș5��i�`0U�7M3w��,�yn���iչ��� -[]%�d�a*kK��{!�)Ϛ�E���՜}�����`$��逧s�PF&��gg�W-D�"ڻ_�9*�
���wI!?A�ϖ`�y2�[���l�����Eڑoz0���������N�DO%����D�"�?`G8���g��U7��I��m/���L�Y.���f�*�&���
w�S_6��\��Z���e��U�4	y��ikH ��-��"�9;�-J�L˅0�]oV��-�#�US6��	}����fM�;��a�~kz;p�ݷ��l�M��޸W�ͺ5�e�+��L5��E��x��1�UD�cf��]�r7�3�U|�xw)��dd�����^jl�	�\V���y���bB�p����.2��l����}璿�$�E��P�:�T��m��dtm6%=Oȹ������
��X���P�p�����Ȣ2��m>����N�f$r����a�8���[4�eS-��/Śd�a]V�� �a-��Gf[^o���uT/��紝0�|O�0ܰrr�.�ׅt��}��pw�-�"�3=��'-��6�i���(+��1O�Y G*�Zʒ�˵0'�t�1����P��?3�cf*1Y�XY"�B��Ȧ1w���V�Glt���P�m�_E娰�s�h�A Qez�M��H�Hɨ4�a�z���-���{sNZ��z=�-���(����a����ȤJ���9b��pyj�+�w���$��C!h�0Iȏ� �Q��6S�?���PŤc-�p6Pi"�G�}��ݫ�d"�d
Ҕ�]�}���ĒD4	��'+8ym$QHj0`�Q�����U���
`�i2p��C�����b&��JW�ڥ�5�N�z�7]��b�XT�md�0P�$�dA?�)�J�[ʅ���:��·<�tl7/|z��3�dY������3)��_��9�z*C0D�@&�n�	���` ��b��iv%���W�����b�o�_��L?�<V �Ծ{I����?�-�?F�\�`�[m���ŹaCDy���O0���M~b4���]�%�}�	���Y�e|�Ӧ.�[��:ieX�U@b7��F�.7�̆:U�ҍ�gB�g�2��Yي0�,ʠ;�L2f�*�>�kIA�N!Q��M9�4�?���j�-d8�Q�֟����#�	�3��
���L�'�qo�Lh�oJ�Н΄��$��P38c#W�Q���H��1����KK/QD�����i�H����L+��$}��w^NF'��t�����7�`���B����ab���A���2�e������q��	��H�v3���7�(�\�^	��]-|�p@/���7��Pv�$�'�KI.#Ra=�Z̮���`VT*X��By9�ne#��S��i�gn/�l-l1p��p���%�`���*��.˒(����ԛ)�8!��Xmf�,�qw
�{r��Ͷ�KD�23���#�bO��Z����ח�_�o �����ش���
Q7��ŋ�]zM$Kn D�z@{��Yܟ5��8)��S �f*�g@�1���B_�������t����Lc�po���qg��1Z8��� ]
`��1���C��+��pQ%qS�8����9%��b�(��BX���������{ڞ��i)�g�ܾ��By��hh�pϹ�������ew��ޖ7߃<�%�K(e�q.՞(AˁFG:�P�t�A�������cu��p ���t�j���Zb �d2:�Z��Sfo�
�"算�f���#�p�L^�8�����1|�s��*A&��~��OO?.�����O���O���7�-���u���p�hW�� ��R���r����P��.�EB��Y\��ѡ�ưO.�BP��hX���*:jT&TXFA��%��>+���b�Aхx��b4�����`��u��W��/Qτ;o�v����W��c�Y��� iH��W*��1���.8����[	�q�P �[�`��K�H����
���P׏������n�h�A\�hSy�7�X38T*2;�p*n�d\(*�EK��|����n^
�Q��X�����d�|f������<�������~��5��c���C�#}Ap�Nb��(��ܖ|��TȫQ�����8����|~_�Zo�Ջ������Z�w����K8f~����7��7���v�e�z�\ٓ�b�:MJ�a%���ɞ&��>g�YMx�:��d0��L�KJ�x�I�
ʰyy�/��iq�Ο��\0�y'�B[�H����]@kL�J��*��mB��K(����'ռ���>HM�ax������ݿ��軗��7�-p�:xr���y45=�ɖ��NՁ��|���>������F�M# 7?�ٛ/}ϩ��i�g^�m�B^�xK��r�~�g�S	bww�?��NGWaL~�;�0
���U��S@)�U�k�ڙ��!�}:y(�w��d����9E�IumC��s/�e_���>�dx�|Jԡ
��;����o:��`���i�CčW�%T
^X�'�Ձ�T�O(��53���K�9� ��oQ����,!� 	�����;0��OFc�Jz(�t4�i��=>8\���;��A �'#�a8�v�Auz>��Ğ&5����g�`�$�i"N���v�3�Nv[��.g��t��չ� ��-����_�I�^���șlf��&��3~P��������Za�q"'ƒ���!e�E4y7=#>�8� �3�5H�#��a�/�U3hFF�۴q2�t�ݝ�J5#z���T��}%�J1|����Ӿmn��(��	/iO9d�U4�/i����DM�A74� \��Z5ηe��椳{�ڷһ��Z0ƫ ��MRU�D��4l�#j�Z_���~.�v���z�3\�-�_�?n���3?�mw��_GjO���$~��9Q�R��;�0������1���0���Tef��Qk{���"a�S�à��IO��Q�?C�Ҝ���)�9=F-��'�{�9q���� 6Q�������u�d_K]u���[y��a�<�q��,��£�,�6	.��RwF6��7��]�Y�6�$��g��iȗ�M*IH�;��32����>�@)'OIs)֫ϪD	9�P_(�g�)��Lu<:h�;�G�깵,>.ہ�$}��˯O�WQ�B�����'9��wX�7�}<[��(L�xp�4��A�Z�w�k�P�'\�j��Y���ƈeկ�>�u���.�J�=`i��F�W�u�|�%qt���tK��|,������	�3�u��*w��XQ�(��M{�����g��ܪ���J:j��W��U��n_�{��	k@��u�;��]\;ڞ���c��>>����(�7M�Q�rχ��&�8l	�هz��/A;����J��x}8���A��̑�Q=}�a�L��`��xs�[Q%�qџN��o���R@�?�S�iBx�dzv��41އ���]�1�}��	~:��X���p����O��P
�Z�\�Lh))	~,�0'hq��S!�^v���L����sRˁ  ��a��Kb�I�#��P�������p���S�+�T����x������f}p�*et.�,<���\c��MV�W�p�;�d��:��B�J~H]�H������h�y���O ��n*�E��.7-b�G^x����zl�����B�M�Z��M��8��[�7H-ү�_�qsUT��H��ѱ�{���
���*!����e�Q�,`p]�_�U��h���p��G�Z�>���rD|��a�gG�AX\�4S�pV3�:�sse~�q��m���0�q���3s���x�lf�J�."7�y��Գ����Zއ��oN�_���s5	�Zff�&\��v�ZR���P_&6<�my3�`f�.h���/���(o�_l�}P|>M�f��P<���ԫQ"��)<�����Rϔ�x������
�O��	���N�o�Ps����jkZ�0'E�����g�;䏺�.�Rdr���k����L�apU6�_��q��2ƵJUu�"(��e��>9D�����<j߉�_Ҿ]��b7s^͓꜓��g<*�1����f��]�B�T~H�
y�{�� #�����������x��s���]���_��k�*~k8r4��N�jO���	��G�7�ΰ�H��,�2	���*�eR7Fs��J���0���r�����z��8_N�T��T����q6��#M�c��鯙]�?���>���6/���������9�ύƽ�Ͻ����[ C�v6@l��H<�˰?�q���Q<�w41%���b�j��s�`�d�n8Q.Y�����w��]~�<�Ī��]�,[B���?V���Y$���E3P[�xJ*a���K$k=e�^�c���5}�y&�$�,!����6��t�Μ2��o�MO;������nQZ�)�A��Juz����9#lQZ��V}!�FS�!`�?ߐ@�����T��3fL�+u�}7:��^{hx�2�{;���͌~t�����V��N+6E%���X�d)�`�r�y=���w��kA|�4W�W���"�%Trش�1��2�y����{����;���7����k\$l�Ũ��hD�e�]��8B߇R���w,:1=�������ږ?�l�,+�x�����6M/tE�cm<�~x"!/l0�N�h��|ٱ'�ά�Յ���Jr�w̄�6Q"�e��A�T)�*�O�Q����lVŴ�����	U����+��a#�p���Ϥk
��ă=.������1�)�⹨ܬ�J���-c���+U�Z�CD;.E1X�5_Q�����\�h&���Sp�4�z<M�E��O�v=��}tS>@\/	!��yY�C�835u�pGQ���Q�-Wi`D�q|���*8�w?�Ybe����C�%"����r֟�.��f�~�.7X�+�spz:l�؁�}�<x`ۈG������i�43I�+�J^����U!^|�а��<MU�r�O�h��
���ޅq��f� _�O�!0�nt��1;�m#r8n�2��9tc	��q� [���v<ӑ_W4e}}&�D�^"m����X���ߨ���`�6x��y�R��H��z.���ԅ8�@1��ix3Z�~��&Z-�u�u#E�5+���C�n�	VQ���[��g��Ⳍ� �:%ͳO�9�p�e��b1K��H-����t���i����q��?A����r��-5)�O5t���
�~��|NNh��u�����Go~�F�/ݟ��F��/��Ӵ�R2m8⅋�LP�u��o�,�N�x,S�f�)0���\���!�O����;16Ex
L���aҞ�8�m� �tGu>���~:�S�7���#�f��G��(Nz�e7P����N� �[/�l�ak�__�RI�םd�S9�+s���Yښ��$;d������^2����$I�]��b;�+O⒫�ZVs�4�a��U#��:���Թ��MzˁJ����ŕ���:3�J�q4���X#k6dvFތ�l��G��-��������m`+�۳�ƃ/���@�6����%V{�Eu/-�q���5jVI�j�fIN�ۍ���W�}�Xh��a.�>���n�/_yB�9%+��C�4���6
��h��
k��vR�T
9
�k���w�PiXT�C\�ђ2���at����ި��>is�?���ן6�$���|���-��G�������3��i�9�}m����]o���~��?�QC5F�}<�X#��olO�g��kU�=��g� �l8��$I�T:U^��Wm#�l�<���T'��2������ఽ���ڜŞ���ٿ?=�ڤ�����!�l�o�!�p�+�3ӥ4�,�s}�5nEY��K��rʒb�	ˎ���f=6�,�s2Q�� �vZ�WG�TY/�t �~4䈋����Pl?¾@���&����7+ڐ�2aƴ��ʬh-�2��''�#�cE%�������潢Ē�^��B,��P#Ӗ�:��g�f&�y%sE��4��f2��0m������Tu(��s�4\�fY��#�2�ƺy�6{�J����/��?U�$�����QM#E>`�c�3�T�SӤ��k�:̌+���a�SN�$<��ց�)Fr!^ru�:��]a<kT�M�Ĉ�R�_��C	�(`�9���UgJ��25��]6=1b�)�m�i5QaP�0)���<	��]�I�u,V �3�m'��yYX��=�:��|7��I���������?��ThaR�>#���������q���y���K�#�8���H4԰W���I!�l4��ax%��`B�p���pH�Uϻ$�<����Y?d�����/����$/^�i�mo>��_�|ڇ�����xI՛vQPi��Kl������~��t\M�=����5  �l7�(�g_2�p��,��b&f��S�^y�5�r�T=�fAIUf}^Ú?�A��h�Q��I88C)���w�k��a���A� L���lq ��Q���F0~�R]3Y��9�xj	P*D�h<s%b"�l�o��+�AA��á�MO@��T�C��Ӧ���5)5���$��$%_1�Q�"�X�\�K284�{�fbq��
�@ΈC�T7�ę�w�G�F�޺C��
�bլ��k�8%QR!=o��932rE��>ڿ|Z��}�|P�#�9����_��}��q&٩�|����9贓�>i�GkD�|H ���fG���R�M�S�,�� �q{�����~pr�1
'|AFuAm@�V_6,u&\Y�B"�2wΉ�/���ނ_�q2��$����� B���B]� ��ދqw���k�oa�oc��ӌ��X_���}��Ç_ϒ���)��W��0"�'��%W*��"E���=��CT#�7\���q��c�g���%��C�x�_P���%�[�B�z�����j�����n�O�9��ͨ��Z����;���[c�P04An
�_�7+�]����1��K�gFJb��Q��6He��W�sBXӷ.�A�x	��7�([gʌ�E�!
	Z�"�֐�f�8���(��Qr�aN3C�+$���-��Ղ�o�wo�Z	�
�l�R�3XH����T�	����{vU���~��Ƴ�[+���D������?�tVM�Sܱ��=��̣"��c���.j��܅�Wm�hE73��n�閪�y�n.�U�wC��FN<gqr������؟I�|wx�#�7֞f��7��?|.����fu=���{��&%�Z8�_ �R���|��a���|����HR�e� �Q_L��a����� 1|H',DW�B���^_�D�$����<����	�̓]�u��tɩhuC�?:��/ЌkG���{��Z���^�ׂd >:?����NM���zJ:�D�hr�:H�a�Fnꌚ3q�u6���		.�2H���t�d��8�y��gb�D;��Fō���5��r������j� �$��Yw�&�Ei#�����?ů�Ȟ�nG�E�8D1�z$��AwЃ8�BI���.���ï�;*m���$"zE4��(��ܻ����ғQ]�1t��t{�� ZOL��V�"�cCn6�N�
P@wzmD�2��-�xx���Ufzl���1ԩz@�� ��G�pD:����RQ�D�IoY��k(�Wq?|�����?�������s�����?�b��Ԭr� h 