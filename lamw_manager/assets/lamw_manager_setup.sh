#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2842469815"
MD5="549faa7f27304695688b75f7b688ae20"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21409"
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
	echo Date of packaging: Wed Nov 27 23:40:22 -03 2019
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
� �3�]�<�v�6��+>J�'qZ���8�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ��'O���IC�N>�[Ov��l5w6w4��ͭ��Ƀ/��Xh�<�L׽����������t�9�%���������;��H����O�}b���dgJU�ܟ�R=u�%�m�%3j��t�<6C�cy�r&��`C���(`t��6u�����A�R}��<w�4�[�-��#vI��7�蛍��B�4���Fg������f�7��x3B��(�>j���9P��� L��&�Lߧ�yQq�!�vA��:;S�'z�{@�~����H[�á���I.f||8wO���ё�B�����:����;�����N;��s2�ƣ޸�;ʚ�0��Yk��PQ�R5F�C V����:���w��*���!�[��j_�ע�w{�s�R)'����k j�u׹�osv��Qf���ŵ���R�\ �[3�����[��;�o���e
4���?��m\���J����O=w�BV�`�dVu����� ���@�=�,�,�b��p�SF�.B;P�T�fHtN�y�E>�+�������D��Rw#ǉ����|c�F����ʪ�5�����}��sƧu�E?H@g�4�*���۵��&����B�PZ�Z��STNP:M3k�:W��/]O��7�
�`1	=�2��`�l�VO(o���＃ *d>MQ�4|��>���d
8�43M���a-�M�K5�m�y���v=��̌�pC�V�üS���O-Q���T�d���i�}ϱA^ء�������K:%�]�����ը�?�����yo�A[��|:}�����lE�ra��P�v��K;$�z]��i�~���ȝ�B���q�|�����p�\��J%��D25)+qS,���J���1&va�nJ��O��.C=x^Xp�J%��X`�X��}uj��y�<�U���dvFA�	Wd�"�@X '�÷�&m,y���>�/��!�U/����lo���67�����O_��/�y�]�M��٤]��$=<��<B��_Q*#���#�=7l����+��R�|bt�u���BU�/��uT�p��G��܄d?�����W������U2z����Q��7Dm��֨�ۯ��;9��:�dr���`���y�m^ċBsl�Wߓ	<�.d��d�Y�̆����M(q<��e����7&�:Y)��G~=�\�*�#|�ib�E{acX�(`2�s]��QgF�`!��o ]Ӊ�1���l�����vu=V�=����~ g5o���3D�Y~�.�홙0��*��l�t�L�g��Fp��M��Y4%o����U������������������)^�Id;��������+�������b���on�����g � a깡	��� �m��̩Kv� B���G����)�I�5h?���H˵϶��cW��44!F���?�<2�qgZ&q=�o�7�X�[~�{`�K��b����X�Rx�t�ocݹ�To�{h�p<�Gi%�f,�u��XfX�O�����X=�Dn��u�1 �L,�]z1�8��	/����aG�]�c��H�����̜*)9͌��z����9�a���Ddl��g�����slҁ�zhΙP���ָ1n�&�2>�>�[�熪G,�{�9TUk&`�C �8i��l^D9�uZÎ��:���`����E�^�F����ȥ�{-i��%A/v�' �2.���9((�܍V֕��\@bJ3W^�+=�B�qu87BeX0�� ]J^Ǿ'�$��f�០Q�pXt�S��D�f/&���S��]!xr��a�gf�/�Dc�/~u���ARC.��:��|�T���_Iw%L�/P]:�;`v.���r{q����6�J�Z�R�ATu��s��ں��7�����p��H�Tyƛ�'pO�E�]Z!!���*� �
8Y�n48=yARC>�QX�ϱ�Ɋ�Yohpj
6^��]��}�V{|�C��`���#���������q�;3!:�� �C�<|y2j�p�X2�M]ޫ:�c}��Z��TK�O��zu�7%��h#��R|jUq�Sº��<əc��� 	�=D<��CxAe�(��b����@(&<\Q�aS�V���g�;�ٹ��B�n�Hɺ+�m�)Xx�����r2��ԖI�:����a���G��Y�H���7L�EDEڃ�p( �>@�|�"Z{���rK%������kw�"�P�ˍ��B��-��T�;	�8�N�ਤ�E��׊���Ob��7�OX���BVҽ������e���ֈ��k,`���́	�H'�`� Z&�&�O���78nݨDX-��*�,�D���شV��*��4��.���P�d}�W��3�
��:��Y�H��"\�JvYZ��lg�T�c�J�[��{���/���v<?X��2�n���3�!OE��d<z��L��L�pS�d��	˥��m�|���"r$'{.h^nߋ��6����1$��
�v�0s���</���seK.�2��`ϣ !���-�IW]�Z����������rT�� �F<	Ys�%�/Q��8����%��O!'�A�yŌ�����%1�U��HB�Į~��+�!E1��ssN�����N�F��R�~�$�k�K~�%	I��oj����G�5P&�Ze�����kFL�a�lpeX������j���N���������~5�Y�`��������D��YP�{.�'�]�zsu�x��������/��b�o�6�9�A4�W�L~ג.�������z���3'���%�_����0��p��G����L��(��ze^E`Z�2xkr�P�c��6ޣ��3J�N����J����w�G�R��i�?�S�.97	��g��������slj�&���5�m�%u-/���^vN�{���︷�1����<z�}C��hxշ�CB�
!���� B��'M-��Λ�F�%^�E@�2fO��X�k�Ҧ�%��jp*��!�=���%�E%UY��ʈ���oD�X9�ᙱ�`�yy�����"tI,��=��|d��q�x�֏AӌGH�Z���I���	�Ԣ)MQ��8OO����~���&5'�w8�Tiu�:�}��\-�Ck5��d�:n��$h���ԙ�������ȅ!��ˉڮ���E#�[T�X��P;��[����� �[@,�4|��#�ǟ0&��b�@�j����du��(���*h�#����P�0�G�Km/2p`r&	ћ�;�h%Ⅷ\q7�LzR�{0�kfGdj������~��������%Z�d��q5%�O%�D�JHZ����-��α��:?nB�|�-7%�T��@-fF���J��(������ᠵ��A���.ؼb��D��c���;)���G�a /
 Ceu�՚�UzN���RX:�mi�s���R��Ubo�t5�	��τ�݇<����Z��e�#�EK��O�X��[�p#_�$g�2�Ja��B�(��L�5�V_�A�r�)�cO��`��Q�����]f �{���+.F��"�4�ͤ?b��Q״��^D�ɣ	�cX��PD%�w�Ҡ�8i�'�F=׹��ok�!��j�++�cؘ7v|�:5�)daM%;�o��Xx�%�of{;���~�`x�skp:ė<�u�1N
)k�H��q欙4M����z^��eM/'RT��;yT�9/�o�?F�+t��8!I�z����%�)��Fc���v]�����=���6����'B/�~w#X�Q���'��c�;�=Ų�E`�x#w�%2}�@���țwE��2����ڐ#��.U� ��)�E�r�J�@N=�|�^���A^Y+?=Q�����=UE���b�6�'^p�|sJc��^!�dpq=�������ŌI�I���[���Cs����폥�ͨ��'�l���1���g����;fP+M�d_:#�x�|�&mj�Ca#����FQ,&��i����[DI;�eSC��[{�_Ё�+� ����ܻ� Vj�b],ajzW�7��:B�)n|S�BP� �"�ֽE�Dg&\d����[w�le}��+��w�{7/RgĿg99{)���@��Žu�˷`�yl �1ɖ��䂺���C���wmŒ�-�D7}�I�{H�����
r�G�7���A�rF����c��XX���N,��=)^����>�J�.�-���m�����y���7���t��w"wQO�5�-QSSoO�]���v.�4w�Z(r7M	^���&2*�'&�>�O��ʢ^��el;)A�)��<L��m�b<�
"6�����Ǎh��]�1f&h�h�����-fC$e�cC���l{��p!�8��;<���9pqO�}\S�:n;&cEv�vr�Bzꗚ�C�ǟ�c�� Ú�'
�}���AV ��--E$D�������gQ��1��*_�+�53Dmy�/ց:(��a�	�����e2ͫ���ڋ��vKY��eH�{7����a�!oxi:5��4��Zwk5|����=|M�Ht��V���nk|�99wG��$�/�)�s� d'�]��q��v�4�s���;��^�����oj��z�Y�^�u������-5-�k�]��.4���#ۢ�=GX-V�.E /����Y�p�hhR�2u6;�\�P�\8e��l���L,?r�И��菰����=�6�~	��8H�A�����4���F�� �����C�Y 6(Q2��{,'�R��9�8�n�n���x���L�Y�T�&���*9��Y��D�^-�Jb��J�%{o.�$reƣ�Z���B�N�v��wN~��7.��h` ��ֹf.,�I����~�Q7r�s��I[h.Hs���/����8�J<3�3^�_R�t$o��@ɓ��*R�گ������1`N�Tbck�~�	������R%G�x����?��ds���u��B���&�%�{r⊷� tA�8�e���x�&E '��/��0�X&y�R�Y��	�_�`���13�,�$%�q�� 4	���pi)���CRg�`.4^��aX&|�����%Blc%/���7�uh�g"t ����+KD~9N�f¥�[ ,ᐆ�f�H��!�R�-���~|�b4����1�~�h���i5Cdu���NqW�(Xt����Ï�~$CՕ2���@���3އҽ<Q�\9�8Sj����w���-���6�.@��X=k�SI�<�Y���5��s��r��s�Ӻ�U�GM���&�7�B��KY�,�#�TV�R�*��QЯ�+���0�����?�B�l�0����:������m$Y���rZ��$EJ��ezF�h��eI!J�3cu0 ��&	 ��v{��>�؇}9�p����mf�U@��ԲǳKF�"��WVUV^���I%��~�"�vj��Y�eO����*S�"�l�����@O�W�����JcFD��+Js��L8��˗���d��ϡGz2�k�杮������ xl�
�"�FZ��Mz
pI��]��;��fF����m�����_Q&t�=!I=�7�Z �b(���x��a*��z�b����3x��+sr�ǪT��oz�O����ioVW�p�N̅�,fj�ni�l9�Qٞ��֍z}:F�cT�5�n�x*r���QEwK��SQ�Xi��ŪOl�+�D�rbC�9���K�n�՗�un(�3P��
iD��pN�`TM���R[x0z�5�7�T-"݌dƍ�F�%�	8�5=�֚L��26��z2���^�������´�ᦋ#��d�OG9H.�kGg?�^��`��/����#��>�$��e2��ο���y�k:��z���
;7j��6������kx�����?Ł��R��@���F����u���.m��,�*�V�j_U?�UO���hOp1�hLR�M9ď�;�_����ﰏ��ˢk�8�}�)��"᰼��WQ���h3����(_�_����T��j͊o?B���i����'� �	�\Wm�6�	���ӑ�FT¿"~����:��$�&�,��`�RJ���̾���D1R<ډ�px����"K6�W�Y�iɍ�Xx��^��v�܂�&1Y�PŨK���W�4K������ؗ��d����ۿ�Z�>���6����e��s�9�0�T�NMsܢ�Jg��&��J؝�껠+Y}��:�Y��pw�"���^�_�I���BuˑY�|ʛ�
��h�Kn�:�5�e't&�+9���� @��~<��pA���	q�)���N{O\��g�X�\��6��n���]K��.n����ШT���t=�r#��q�]~O/�a�J�R�7��4� Z+wxA|n�o&�7���^�*i��I�L!7bE��H�0n�%58ȓ�l��b�ţ~4I��ܣ����ĚUPMdӹKq�;눜B�aTƬ��U��$�`s�� BC"F��7�'���cM� �}�Mtf]+��b�̞�X|�_��b���@S(���Gqx!n>�l�N������fX�F5��bJ��zN/6�����AZ���Ί�&�� ��d'}���|Kyy���̗Ńk����y^-x��rG�$y��bn6�XFi	sYs*s撅l?3ġa� ���	��O$�=/$�vP�����C�����3�����ǻ��{�)��b}���xr��3\z,�qљ�ѭH	*�5�ԖݩS��9[˿`�0��ݤyڬ�b����V�I1떽Dr�߂������udq:*��.G�Ǒt8��ot7�Fyo#�=�}mt>5ݕy�A���}�n�W�
9��?J��&P�I�g�v��3m�=W�:mm��N���cx�e_�t������S��"v�b�;������$C�s�B�.�������&�9��JY$�],r)��c�/Z�K���l�������Ͷ,���t���qn���H\��۟�Ս�"撣����p��� d%�"�S�����YDj�0ǪY��lh�Syq�[hT��k���lM��y�}�w-�׏ɫ����}g
^�j���<OI$������2!U��>?�>�[V�<��ֲ�XM��Z}��\��%��������b�
 (*f���K@r�ܨ�E��%A�b:�e�r��ke��0d`�o�-���Q��UB�f��xB"/�����`
��l�䯭-Y����y�����F�TtdЗ�,�i}��V�6C%�Pc�*�M��3�f�6F@�W\W��������`�W��	-�����j��pD>l2���U�������g|!��g��eGc4�? �����l�ז��q��S��.M��i
�4)�տB��(K�i���(Pe��YY�gMK�ճ��n�#�5ZM������E�/f[lL��ud)_�X7�
d�L�P��=Tk�ҳ����	�|�m��t��6��ٙ����*���A��V��S��f`�)��f��.�W�qI��e����JjBV��M[`��u���C�;��)�X�S��\)%�Sl'iO9��hp�94N�)N��k�F����Y0�&%F#	;i�-�A��KqO0�mQ�'8�A�w9����W0��e䑕mXC�~�����f�����������v�῭7Z&�����5�0i����a��,� �s��!�`�Q�+���K����岴�D5_�ͩ��;x��Ǿ�>�E����e4�bt��Q����t;����mkk�=ZQ!��lu���ux���라�����|���w_��,�,��U�X���2)٦�p��'{����9G�̈́�ۇ��������ur�����'�/�H@�Z�ԛ�|1I�����%^A�4�bVU`�<Fǟ��:kN��K����{��L�C�J�Y��x0V��Su��ylLΜ2Z�`���'�;
+���g#"�����C��|�)��i�n�4�[��g<f�����p��N]�GA����s�7�� pn��KSN�J�����B�}�d��k-�6�2�M��8pwVZMT+=��x�pT?��c�E1k1|D?�B;px(r7�F������~w�2f搹�v��C���SH��儌��5#a� ��"�ź��򀮈�������K<�q��^|�0>�0��7�$E"x���h�P%�2��0�M;���r�?�p�j*��кx�-$�m��
�o�y��ꚍ ��&7�0��iO��"��hA��������6���&���C݋x�'Ƌ�Tx�J��B��=��[���v����?n��f"i��C.L�p|`�pkp:B| >��Ve��+o!�vR�.m,�ph�w&Yl��M�po������>:���*f���De���tm7�,ۂ����qVG�Vx�8���9���M�&6M��űw�D*)��ia�B�X����s:��M-�λ���7HΜ�:SeTs�Z�Ă{��|�ǨT��I�+��I'^����5z�9J�E�0Ж��M��F6{��	���Z[�Z������`�uߩm���g0�bЂ5|�dR�Ŋ���bK �K`�H���3�'�{�z��}�ҵ�F ���Tlb�I?ɂϞsq��s���p�����Ms� ����I��JL����4Xx���3%��ۜ~^��L�,�[�z��,�������
@���(�-0c7��T�eZ���������[uߖm� T��ɂ,0�wTJZ٢�&P���i�C��̦3J�u�fd��c��({&�����3'y��њ�j�Ld�H��������x�1�!���A��膠�i9�[z�Uy�R�n�\��Ur�uE� �v�E�(\#n	��qD8�p� �f$�
�����i�A}�`q�N�LDV7�+���~�>�V��cr�����3/a�/��t܅���F��$���6�Ow&څ|!�(�	��I�X��w�� �VG��HS�y�	�.<vy>�We\ARi�>`�:L\����:b%�[VSi�B�,T�-ii��	F�AӸq�@�����<]�c��5C����k���v��Fw��H�ʚ�h � ;��=Dl��8O�h$I�<`���"�[�]#"�����ѳ�h0:�A`a��p�z1M�s��za"��3�c�09Ǜ ���
w+�o���G	]���!�#"0�60��c�gߴX5���t�9,(�C,��tB����)�X�T������?���
�
���eB�"�n��0���L����u�шy�a�Ou�P5A���k Nx]էco�-J�!�����t C�<�P���B�p��SV=��0Hq���J�G�Tl{�h�8xX���],���ɣvgL4�g���溮�蹹���s^`������SM"��'�J�}Z�"�M�}����<|�����x�~���,��:��C[�W������ލP� ��ׂ�h�'_(�{uh���9�'��DGn��qs��_�}4��1�3��,��%�JqǸy�2u9?G�v0��0kb�� �[Y��\B��no}H9<�E�׬�x:W�h)N���;��c�	�>�Ixt�D�8�b��9cw �:r�c���,K�[VU��V���o��-��	+bAAy�5Kh���ʃ_�:��<@fC�l��(�*]�dSEI�-&��R#^>����W�PÑ��e�3�ђ�ql2 �\"���Uo�ϭ�̮T�(�܀ְ�z�4�6yg�M�[7U�H����I�4sJ�LB�e�C㷲W���'�|ŋ7R|�%o�F0,�
���C�*G��ˣ����1^}H������a�&�Y���#3�:~�Ix2E�ꬲ�*j�Y��5����B��cn�Y����SW��d(w�@G�:�VͨJ'_��8ҧ����\
��fSPE�DIr��-�q#Z�,L���r��T����T�Rb�����.��>8�h�Iq����|\�Ϳ����G��ǻ�wU\4��p�*�y���,�n�u>�Z��J����#�v�Ц,Y�*,u@k�;����/���/�ɻ�K��b�6�us0؜���vw�'���u�d괲 ������}�y0	������2�{��>3Z�$��:��M'��O��+��̋���/�c���Y6���nJx��&t����=����̈́
��䃽�#�z�M�NNrWCC���4��&�&~��bw{�� ��zhR�
sf��
>��3�O����\[mRY뇉��Z���G7���3�i��5|"@�5��}ߡjjx��տ/DO�!�|�ל{G�CDߓ�z���1�C�|d3�|����O�~�/�s�#\�q�*v����zwJ`��a���h�)"�����4����c�>*l~�V�>�>bA'A����Fr�so:L|C��Kv��/4"P�����,�ڛo�{�kJ
IfL&7��d��pV���[Bd ���,E�sU¬�*D{2�q�RW�(n�*$� ѓ��V�D���S1�鸗F�	n3�h��)��S�H+�`����ﷹO�[˒��Ed��q۹����Ě*E���ҸfͤFɔ%����?v���!�Ŝⱬ�Ѥ�҄�qY㽌�^��L����l
�2�.�3D�9b�*�3E���E��5��)5:��gn�����/�����2�mIr����;z��LޖP�����Y*y�Wݜмγ��y�D]P-[c�D��|��Bsɚ�pK���c��~'C��>�k��R;i�y�m����A�l��@H��)��l�<[���ql��Q��}ѓ�#B�}���3N�� 7ޒ��b��8	�Q�GAG	y����h���0{�c��>A뚺|�!���}����R�T���M���U�,'G{X�~Z�1|�.�+�tl��7P�-�T-��>"6������=���7]`��
V��A0Nh�G}��B(�0
�%���U�.sX�����ݣ��7;Z�oaŗ�	����1��.��/wU�&ۙYt[��*�@����mZ�3����+�حd�l��)��N��m�N,�9k�:Hu!�`�_t�=1�4�(.)������D�٧ݪ��P%�W�V��{��^�� xz4�`r'�^�����r�r��,��g)Q���e@Kҙ�����T�)����f��q�Y��M()�?J�(7�0������_�����́��G���.Pj��!�,e��m� OM/N�2�6^�%����m��Gs����AP`a#Lf�8���J��G>��!FLR�����DA4�P�I<3*�K=�"��<�u��k�^!Á!zh���+K�/\��^tV���GW�}A�Y�d����T%�W�a�Y�òp4�¼`2�o�9�guc|��5/��ڧ���+�����v~k�>E��p�3�y,,��Q���j�8���x!��}ǨrȉǏ���e��
�yca]F�2I�m�P����5�&�7ֻ8.`�o���8�0��9�O�zS!���R	7���n��<��E����|`�&kf���km�VkԪ�ќ�-�)�0�3�X?l�`Ą��������e2E�����J�;��tTW�ӕ�o�_�"O�}��������ΪM.���,B�\�4#�&��M�GFh�L�fBj�� �y�-���K��>Ʌ؀��#���n���~.�Es15�X����oM�x�1�<욝Wж!}��m��ͪ=�A���
�ᥤ���;���i/�ް�V�ܣ�8�N�55��I�=|C�1xM��'Fb5� ����і����w�QtNRl�V3�`le7� ��6Ps�8�n�T\)7j}?�pzg<P�^��&쑕B�L�9��LŖ�q6ۘ&˖
U�����܇���:�D9��k��s�Z]g��׻�ǰ{q!-��w��ۚ"��|A�� ��1�bÔ��'�q�j�t�
^�0��mRPͫ��&�=��P#��G@�IЧ��n�~�h7��DJ,��|�a�"�.�A8(�@�J�һ�J_���	0�֒a�;ny����h��S'#�>�w���m*�4:lK�0�M�b�?�Xm��D��;w�|>�{�tY8x�rW�_X�G�nػ�r=��K*7�	3g�� �1�y�� 9�+/L����N]ѭ��B�6ue��CU^&9�g�Ɛ#�s6���bYL�N+�㷩9�Zf�Vs��Vf��4߷��ov��ƾ�\]`=�l{��
���h|�S�nW@_�0g�5�}���ni6���S�]���^�8����`�L�|��P�u��眸�o�%O�Q;;�Ua�e�{�� �s	,�E3x��}B~AK�9�%��7�����!�m�(.48��ۻ�lL{Df�Xς�L�I�.4Wf��'Ejԯ��n�m�{,o�k���g�@۪�U�T9V>~��܅��ѺlȂ���e.n432d��j�5"&0�E��d����H�V�����~�����\�$ݳ�������x����J�f������g� �(�xal�g*n�$�㛫�O]���Mjk��Ÿ_p�RiO���2�=a�Ƕ��"�pw��6<B�~i���q^��xxM+¤	�$<���BYr�8�u#�"��@[U�rˊ%B���,_Hά���4FP��Y��v&�j��>�f_Y����s�J�1e9�̶����ӈɘ�xcT���Y��qa�q��uQ��!+}��t�)n����^� ��|�׉�1�ͺ_��Z����*K~��t�gz���#aD��<�%߬5O�����f�%v ���k����/*��RD���0b�,�c��YX���\V@�mxEc5��Gi�fy���Vp�ќݣ$���Qe1S#K#�����j]G���β�f�sR��?`�9o��	��V�4ܹ�1aP����1�W�Y���K����< �����/���P�Q���#�P��$H�#B�@�j��O�]`<0�ee���E�7��2�J��lX��#"��	X>���{�ȆD�#/�5�#����1�� ABX��ϰ	����H@zM����q@���F���s�ʺ�`nV��d�ᜰD(�Y[6sm�ac6��TծU?�;��i���Vƶ���\Uf|g�f��z�a-w$:�
&6?;����ƀbqrH�I����`w~V�O�V�HbB�[�5�Zr��5�n%�I{:[(M�-&�t� �dt�����4�����&�T^ {M/��A�)B��{����(#md�w^�щ\:Dpa�,�E5��=�1���ʷ��f���Pnte���<FҌeW1�)q��uc�KK+6B�nL8��=�ԉ{�/���?�	"�a���6�*_/�cʰ�Y+f7����d��*9-x�����rW�9�\%�U)�J���H�*�&{{��v�u��<k�����E���RRg&d�WX��:3��K�;�50�'3�"�Q33:��8���0���h���V��_�o��e ���n��8�� sG��.=�[9�/j� �S�>���|��ӣ�]�π�,�T	m������azSyo�v_���_C�7;]��W=أ�����/��H-�U�nV��������]ޤ�vN�볆�U�� vb����1�����8L�jAf�QrĔ��ܾ��J�ry�ؠp�n�v�M�!�hp��ɟ������_nD"f#�lew�?a��,TsA�t�Ua��/=4v�`h��/B?��G�e#Λ]CQe;y��vb�$���t�A�;Ɯ�S�z@��Y�u�"9����KX8Elgȧ[�5&	�i����y��a	�~�,��i���oK���⿕��XQ�8��
�M�^g�����4S���j\��^��� {�,n�p�h�0�O��V'�JQv4�C{�����_�#�I�V֞�5�D�)"��1?a�;xsx�=��E�(���vzo��K�N�2�,MQ����3A�u����R4��7	�T�"[�9뒿|I�x����m��:V��~��H�a���u�?�B[ׅz]d��D
�F�u��+V6�L�x���r4�7���������w��8��������G�χ����r��5�����]�AY3J_�z�'�%r���%_&�[&"(Z�2�I���AvI�H��+]O����!������0N�{�ĊV7�9��B/���$��(ϯ눔��(�C���*k���.��<�Dy2�%�{&�p��)q�f�]z�Gۻg;l�͋���q�O�#oq�KVG���~�d��fVF���������6��:Z�ާZ ^��`��t�`��%�{�Cw�%��σi�1�>��m�(�4QuO���0�
b�P���a0dCX�a�S���t��.��Rݧ�}��GJ�N*��5�7��q���I��	�r��֧T:4A� {ut D���q/ƈ�*_��hHzjD��BY�=��^u��,*��"��Ew����\����`EOaCߣT�a���Ƣ�\�F�;"1����������������b<8<�Zg@��d�>��`�5��X�,�z��j?q,�)zqO � ܢ�Y�R�n�{ 7���$�͍���|��J��'�B���3�&�QՉ[O��\7k�����V�'ѸO�m�F�1�ͬ|�fL���Q��h�N�Mg����l?q���;@3��E�t,�����Hj��c�ޓ9p.kN)���6�,�����,�}�X�Ou�ӭY����g�o�c��6�������YG�9��n����=fw�>�sԇ:_:u���J$ۑ�Q��y���y?�G3�RG����0}7=����C�x3�H�(�[�	QTd�:|{N�1�t�ݝ�L5=�QI	<><x_O�(`h>^7=8���V��ħ��O� E���*YW'o�}�CS-.��Mw���{�}c���YMo��*2NH���ҾO#ؿ�Ԫ-l�Ѣ��|.����z������ )>l�����O�����=6����G�5��K�Anx���0�M�E�~�)�E'H��%,������*>�!e�Ս?���kG�M�b^	j��c�R���u���T����4���7y6PrOe���ó)'�93F=��.�E|�9����"�9��	�٣��+�
��6���l�6��O���/�s!*���L#���X!EX�����)�>�Ȧ,�/ŨWK�0�c���F�r�8��`�A�!*<j��6S�"i�3��2`�r�x���{�A�\aӔE5(��y'Ǹ-�,�m�A��S�YJR3�%�dRI��Jh5�4(g�qL�
����G�^�荺.���
�Z�ը��/R+�^�H�	-�7%�����t�8z��+cƣ� ��xt��s��=u_�����ٕ5��5�[�p�8��B�+i�;?�s�Y��Ol8�:�/���	W�Ǥ��z�,��9��xğ����p� C���\�[�p����l��1�5���,~f���[5�s���E�~}Um<	h��w?��8V����e�o����s���[��C��brc,s�e��b4p<{4�W8Z³�V�.��;�H��f�~��c~8��k^Gm���E���~H�T~���ڛ�w���	ύ��4�Ⱦ�s��`h;�(O��%ӳK.@f#�}���G��!CP�0�^�䕁s��.�E��x��5�<O�H�q8w��w��م�L9L���H_���Їc�D���Ѹ��uEau�츣a�~��G�)�a�[�(��-�J����xH��]��;6x��X뙐 N;��"o���5h�p�C�>�#!��xga}����$�D�?�� O\"f�V�wr�d���B3�zw"-e߮���4�9��:�4��^�����ΐ%���Ok֡Q�/5į93J/JuDӹl+"n����+��`��@��P�]��ߕȉ�K�ܾ,��w����]VZ� ���[l{>X�ʓ���=��Z-c��W8����M�����q>�v����C:�t��Ď��j�Ȃ��&h��h��݂�؛�H��u��_o�?ڄ���ko��L���tc�l�[}ʏ�0p+��֠�8oM;k�
����82�΅�(�����3�\�S��S��1�N���e���a&?f������~zMr�xY��ڬ�>�*�,�YoV�̏D�'��e�Ұ3�_�K�R�o�n2SZc����XA
�1�P�������o��;��O�$U��T��d����t�l�t���.�p�zr� ,���֐i�쑆��;���Q��M��j9"+%�!A��@_(�BR�T\���J��������2�C�=�B��0h|������V���J�-���g7�R��ۃޱ�Zu���'o^t��5�ж	�f�%؍�Y��h=j�de�k�����G)֡��]���؋k���-�;�]y��O�"���X(�J)|x�r܎!=�$
�O�����v�1���浞�!�m`��r'�n�38����_������q��wsci�����c�uk0��og�M��c�L&�dU�E�}�Kh^�}�G�h���z�������O���V�[n�fؒ��d@��h\OІgd�<F(�E[����;�>*u�KX.�:վq�?�e�֩���9|)�L�s8阠��ÿ ��Ho^�Ȼ}&U@�$4��3��䃕J�EOr:'H�֟s<gƪ��h9���������L����G귲���	K�-�b��[���Q����G���o��MnM�j��Mo�,�3�
^V�/�7�(YD�9�i����2��K���Ig��1�L�<|Q@��Z,8�M���͈�)����"��96ʵ�.Z��;N�ձ)���5�Nγ������O �
�pq��rO@	@�k� ��┧e�<�I|����vt�Yԧ�d2��H���PA����R�ip�&��)�74�cVO΋ޢ��'�,�U��BIlR���`���"g?a���M�-*8aز�^B�����Z��0�#a�&%+�C�Ю$��@2�� 掣��i����ʔ�u�*m�d��1���]h�u��7-�B�i�[����&�L!C8�x��jyjl�(J���'wx3��qC���!������E9yT�O<�.�� ��R��c��T:ڠ�@�"ºgN�lABu!8+��g���X��i�a$���{���[o�͉��$<�@- <��L�ClN�m�w/�g��o�
����cv[wvQV�J\H�N�У�\FQ�"����q�*�MUu�<n>\ͧ͛���o�X�A�0�yHn���r�dE�=]��x�#�?��M,	���ƈ0�V�X���ˢ�##6�T��d ��*�v(���؀�2��|��f��hÒ ���h�P��֝dٙ-�
~�[�'�D�z�nq@Ió���(iq����Z�pǽr^����-�K���n��ؼ,�r?C��"��3ZI:j��z�0DO~�Nh���kUh���Ú�2�&`���9�z��8�
9ٱ�·_~��g�k���m�"�n�D\�gp}"�C�w0UG�3�ƲZ��6Y�Q>\�����x� �1�]U�"��D���!� �c�	�ޘBB�уp?rDD���i�P`�J�=]r�/M_�ak�WI��&�z@,�}�ɜ�F3�ຶ��u�	��4n �[����Lss�}��
W���OM�L�d�b�l=��Ř�5@�Q���ʹt7�n�b�nmY����Er��eAâ��l�r��y'aFg��1VB�T��I��Ū�o��E���h["ظ���\�t�1�1��P�,����}�3]傑���c۫�b�m����вzBM��D� E�N��{�?! �b荃���Q¦)��x����CI�[�Jm��3�$�J�
1w��XTB�>��77b��Ѱ�H��{�X(�����o�|��FӏI��1�?9�O���ѿ��K�ϗ�@���1���z{c3?�7-�����2���;γ�s��ڲg�蹅6�wϚ�������:���A;�L��V�{��կ�0�����2t�3�����̲�xXA#����ǳ�����3�y�`L҄%�%$v��M>O���MS���,�+���y���)��H,ĳ�6�gM���l�DC�pG#v�ڪ�N�Ӂ�����9�X8�4�S�A�,+�H������T�A�di4�����T�πQzނ���Y��Q����eD+8�U����0̋dn��(�KZ���Ӯ�W�#~i H��KR�@�$���M�����0:u*�"���h(KjA%k3���_r�ˌ�>Øa$��,����0~�E
�����g��������o�����}-���X�h���˒��"���?A76Vs��oM��	sѬ�mO/X��U��h��F$1�\�����o��:���J�F9�a����?8����5g����a����/������G�	�n���ߘ�99�<["k^.��eAܠ�םViV%[U�:���S�������Sd<�đ�s����t{/�v������.��a8�э��p|?��@����y����3�X�d�0m�+�:�J� �7��~ wHj�_'7^L��`;�(�}'7��UTrh�nO�cg�;*�m���bpUE�Ԥ'��z2c�0m�����穜P����U���bp����Ҁqu�6�B�����/oE��l�d,�=�k�`�n�-�#/IO��6uMh���B����� k���I�)!�a(�	��Q��׌p[��7�DWy�fM�)�%�[㭇xo���ֵ.L��XS����c���r�S-��Л��X�5�u��j��/�� ��5p����@��^� ���vr������f[��A?���.JGpWBh�5g�8������@�ޝ�o�����y����R����/��{Cu|���
�Xs�l�Y���0P=����<���<�ΎE:! {�Td�g�qlyECxYy6��b�^:m3.CZ�S�5���?�,\�Q$j�Y|�� �S6����ٖ#����Y �*�0�M1ۉ�����j�4U�6�M.�S�Ё��my���!(B���YfJL����.^=��v^O}0	�HAA<�@�\���IHn��BbGY�5�@��*����5߂����%�����.��[�Gs�W%
]��_��S��2(0�Ar��������FA���py���G�z�&�#?#<��E�2�b灗�?.��)���p�Kr��b?�FgPC��F�y@��\E��zO��v�XI��@����#��#e��8�Y�qlE���O4��b�]����9u&��s��F�|����7N&�~_S&G(fC��d�G������Z��ޏ�̉�X�$;R��h��6�h���^7:��6B�
t
<�aۼD���(Biǹ.$�/0��i�O�1�aB�5R $y��;����1���Fhb#Ep���=����R^M���g����J�j��n�Y�q�$���wr�c8}bZD
t��e�r!�$�v���)�S�ԧ�Z
�8������/��B��x�sQ��W��:i���ڞ��Ӥa韕HN�ԃ���hI�aI��^0I��|R�.guX[|'G{���۞^�a���-�?R(��X/[�b=	)��Ol��G���C���A�ư#�V%�,�0)v�b�<=��h�J�t�x]�eɋM"�o2$Y��]�s@���u�`bu���_0R���]�і6���P(f�Z������+��5QR&������@���bKC$���M1�7��Y����_pI�˽]���� ɟ+���|��>�9��iP��IG��Y�h�<k�7\V���=��g��u��7�5k�k��0)�p�ljc��h]~�dp � �F����nO!�t%ߨ�C���b�`�=�s_@��x;
���7�Y<2j������5׿8����q��o�/��_�s��7�d�����[��5��i�_V�S��`_�Jx��,W����s�>����*�ZMw_��T��P3�2��of��K����r���^��M��wS[Ώ����^ͬ���X�S�\��h���"{�'ϯboLq��Mh/���n�K�u�3&>w���)���=*p����Oq�3ǘ�1�!7J�H�!?�z�e�̂r���Zi�]��2�|YҔ8o%���l4���P�3��G$#����|�VB��z����� �]�BU�c��Ĭ�,�D��k��0K��Y��9�,�?H%?��с�Ș���I��Ǩld��a�P֓ٹK�/-�Ԋ6|�on� ,���<[^#n�d� ��Ycұ�����#H����Q�������G�K�����RZ}4�p*��4�)Puª�ϕa�KbpTj��_���p]��8��BQ���EC�^O����*U0�_�̋t�*q
�`%i���p'J�at&4�ͣ��Λ.�������&F8����������ˢ�V���OUF52���p�G�� �/��Ϸ��Y�R��P�m�Z��j�Hk�U�M�p�'�}�I�������Z�_�+���2��H퐋�z�l���O��_��������&12A~��>q���q{{�	���õ��K'
MRHz��A�a�&&��t%1��$"F2������GR���+i���&���M^W%���2~PzB���:����d)Bj�%F��uZ�4�}��)�{��8��*�(�+0ڱO��h��~Y!�$�,K��v8����̬H5�T��O�bA��3��)�	Ŋ�yt��Dw2�icD:8���p$�`Ü�3dԌ&�AKcf�¨�4X�7a��{��ݫ�7a��W}��2p��1��b�xf���u!s<Z�Bm�������,?����,?����,?����,?����,?����,?����,?����,?����,?�����ypl � 