#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1086234423"
MD5="04da292c51587b82583bf7e8c2d618dc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20867"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov 26 21:34:03 -03 2019
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
	echo OLDUSIZE=128
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
� {��]�<�v�6��+>J�'qZ���8�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ��'O���IC�N>�[Ov�nmo6�n=h4�[�ȓ_���y`��{u�]��G?u�1��s�K�{k�Ia�7w6H����O�}b���dgJU�ܟ�R=u�%�m�%3j��t�<6C�cy�r&��`C���(`t��6u�����A�R}��<w�4�[�-��#vI��7�蛍��B�4���Fg������f�7��x3B��(�>j���9P��� L��&�Lߧ�yQq�!�vA��:;S�'z�{@�~����H[�á���I.f||8wO���ё�B�����:����;�����N;��s2�ƣ޸�;ʚ�0��Yk��PQ�R5F�C V����:���w��*���!�[��j_�ע�w{�s�R)'����k j�u׹�osv��Qf���ŵ���R�\ �[3�����[��;�o���e
4���?��m\���J����O=w�BV�`�dVu����� ���@�=�,�,�b��p�SF�.B;P�T�fHtN�y�E>�+�������D��Rw#ǉ����|c�F����ʪ�5�����}��sƧu�E?H@g�4�*���۵��&����B�PZ�Z��STNP:M3k�:W��/]O��7�
�`1	=�2��`�l�VO(o���＃ *d>MQ�4|��>���d
8�43M���a-�M�K5�m�y���v=��̌�pC�V�üS���O-Q���T�d���i�}ϱA^ء�������K:%�]�����ը�?�����yo�A[��|:}�����lE�ra��P�v��K;$�z]��i�~���ȝ�B���q�|�����p�\��J%��D25)+qS,���J���1&va�nJ��O��.C=x^Xp�J%��X`�X��}uj��y�<�U���dvFA�	Wd�"�@X '�÷�&m,y���>�/��!�U/����lo���67�����;�_��/�y�]�M��٤]��$=<��<B��_Q*#���#�=7l����+��R�|bt�u���BU�/��uT�p��G�����.��v��U��3��j���w��{�!�Q[�5�b��+i�N�����>�\�$�Eda^q����Ga���dϦ�$�>Yx�=�!'�`��qJ���|Y`5��̀��NV�1�_"W��C��h�mQ�^�2
�L�\�9eԙ3�GH<#��[�@�tbd�c:�%ga�]]O��mO�2E%��Y�[��+G�_���xD{f&L`��2��3�F<ӡ��:y����{��uM�[�8��j�����%��������%���WmَE�:;���?l�����|�����b���on�����g � a깡	��� �m��̩Kv� B���G����)�I�5h?���H˵϶��cW��44!F���?�<2�qgZ&q=�o�7�X�[~�{`�K��b����X�Rx�t�ocݹ�To�{h�p<�Gi%�f,�u��XfX�O�����X=�Dn��u�1 �L,�]z1�8��	/����aG�]�c��H�����̜*)9͌��z����9�a���Ddl��g�����slҁ�zhΙP���ָ1n�&�2>�>�[�熪G,�{�9TUk&`�C �8i��l^D9�uZÎ��:���`����E�^�F����ȥ�{-i��%A/v�' �2.���9((�܍V֕��\@bJ3W^�+=�B�qu87BeX0�� ]J^Ǿ'�$��f�០Q�pXt�S��D�f/&���S��]!xr��a�gf�/�Dc�/~u���ARC.��:��|�T���_Iw%L�/P]:�;`v.���r{q����6�J�Z�R�ATu��s��ں��7�����p��H�Tyƛ�'pO�E�]Z!!���*� �
8Y�n48=yARC>�QX�ϱ�Ɋ�Yohpj
6^��]��}�V{|�C��`���#���������q�;3!:�� �C�<|y2j�p�X2�M]ޫ:�c}��Z��TK�O��zu�7%��h#��R|jUq�Sº��<əc��� 	�=D<��CxAe�(��b����@(&<\Q�aS�V���g�;�ٹ��B�n�Hɺ+�m�)Xx�����r2��ԖI�:����a���G��Y�H���7L�EDEڃ�p( �>@�|�"Z{���rK%������kw�"�P�ˍ��B��-��T�;	�8�N�ਤ�E��׊���Ob��7�OX���BVҽ������e���ֈ��k,`���́	�H'�`� Z&�&�O���78nݨDX-��*�,�D���شV��*��4��.���P�d}�W��3�
��:��Y�H��"\�JvYZ��lg�T�c�J�[��{���/���v<?X��2�n���3�!OE��d<z��L��L�pS�d��	˥��m�|���"r$'{.h^nߋ��6����1$��
�v�0s���</���seK.�2��`ϣ !���-�IW]�Z����������rT�� �F<	Ys�%�/Q��8����%��O!'�A�yŌ�����%1�U��HB�Į~��+�!E1��ssN�����N�F��R�~�$�k�K~�%	I��oj����G�5P&�Ze�����kFL�a�lpeX������j��	�}������.��������$� ���%�z��2�s�=q(��r�xЛ�ب�����e%��V�n�~;���9�i(ո�e�tI����(8d���؟9�o0�%.a��B.瀙h~��>:��g�G�ԓx(�*�Z�4��[�����]���l�Q��pJn�W����g�{>�&�Mk�Y�ZtɹI��n8#��φ�G�c�P#6Q�'��hpm[/�ky�4���s���}ǽ���6vvv��p�;���Ds���u�W�(���8���?ij1�uބ40,�.���1C�xZ�Ǫ\C(�6��/���P�S1����yϘd%(�-*���'WF�7_}#�E��Q�ό�K��#DU.'�Kb�D�!`�3 [T������~�f<B��j� �Nb�P�6H �Mi��<�y�xzm%? �[���x7�9�������J��ֹ�;f�j��Z��N&��q�4���'As�-��<�7�p���@.��^N�v�G�(�Pݢ���*���A����F^��1�b9��Ï�?��1A�<�J�=P�7%��D�Ķ�TA���8��DGX�J�q�8�]j�x����3I��4��D+/<劻Qg�3��܃Y_3;� S\��\P\�0<�C�����L�-q�Ђ$õ�8Ǎ�)	}*Q%�TB�b}\�nYXt��^?���q"����ذh�1(	����d j13E< U��x��@ym�������@"���u����%���=ǝH��H�'P�?BxQ 	*����d��s���]����nK{�����b����{c�Ө�O��~&d�>��H�4d�r$w�(��4(ZjP~"��~ߊ��$9#��T
[��W:�Eyf��9���2��zH�;N�{RF(&�bܿ�g�"0� ���ǌ^q1J���yo&������*���7�"���HM ��̆"*���-�I#=q4��U|}[C��U�XY1���\���թ�(O!�Јk*��1�]�³ ,��3��ۉ�v�c��[��!����#�qRHYKE:U�3gͤiJu��7���x-kz9��2��ɣ�`�y9|�1Z\����`�	�H���|/	� Oy��6{�O��Ĝ7������}��F?qhz�`��9�⍒�f?�6XW�A�)��.;��s.��
oGLG޼+%���&vֆ�}t�jQ��M�-����P�r꡸�#�2=]H��Z���ug�.�*ʵ�K�i?���s�S3�Uo�b�p'����l��u.fL�O��`�޺�����\g�h,emF�� &>e+�xg�1��?s=G���0�Zi�'�����;�� 5iSc
!m�l4r�b1O���`d�"J��I.�����#�ڀ�_�i�T,��޽�R��b	Sӻ
'�Q�����Mq�����"�����-�%:3�"��L�޺�e+뻧\����ݻy���8#�=���Kq�<�W,��_���c��I�,�&ԍF��z���ch+�\nq%���N��CV��@_P��=¾�F��3|���e@��B�/��wb��I��^P��VZw��h1o�n[�����#�̀��ͤ�/����zb.��m���z{Z�"|D�sI���7�B��iH���4�Qi<1)��|�U��.c�I	�N�e��`"X�nC�QT��`@W�F>nD��횎13A�DӕO�V�o1� )s;Rpf�[���sy������ixmρ�{���"��q�1+�������P����=�/���?Q(�]�t�r ؜o	h)"!R��X�8��L=�¤�y%V��^����!j�{}���A@i�kOpg/Ϥ7�-��i^���^�w�Xʒv.C�߻y���C�x�KӉ�Q���ך�[��[�@����k�F����҄�w[�����;�'	�Na�{!;���n���A�Åx������<���txS��������Ψ��箷��n�i�\�슅t��m�E�8�Bh!�
v)� y�E����SGC�Җ������"�����(KgK|v�eb���{�H��l�F��Mf������KHE�Y@��']�(e���7�`��eM�����@��)m�c�8���tϱ�ywk�w�du�ce���E0����Vɑ�̲�, *�jy�USV�,a�{si&�+3e�b�/:vj��^�s�D�q��Fᾷ�5saALJ>n���Î����;(UM�Bsa@��#��AX���)�P�!�������#�x�J��U�J�~���V�_�s���X{��N ,���ll�*92?��%0����$�;��֮��2�l�%�0-9ߓW�%�� �r��(�^���S4)9�}ᬄ1�2��{�j�ڌO ����p@��qg%)���G�Ih�>�KK�/����:����s��*�0�
0�3�E�D�.b+yi_�X��CC>C������^aX"���qb6�.��a	�446�D:��8 x�:n��d������Wv����O�D�$_5�H�"���;w���D��K.N~t�#���1ſ�g(����>������q����R�'�3t&o�]�YwZ��:�!X˜J�����8��%�Q%�CnG��$��֍H�w<jr�|�0ɼ�B�^�Zd�Y����bT�Ս�~]^����95��V���g� �	��������m�mY������$�@�ԥIA=��l�iw��@�"U�  R�Z�_�ib�e&�a�����\2�2�� ��5�*�f!�ד'O���z��wh�4OR\����$���Rw�_���Rb�l�����O`=�]͇�|��/f�(�|E���q%� ��eK������(�w2�k��-����.b�	b�F��#��`I�Y\G�F�O���+�Pl��6���Q&t�=!I�r7�Y �b(���d����D1���e?>��3U����Ɯ�U�{�����&��ܮb0���'�d�\����`�Z�/�+g:*۳���Q�L�h|c�ʜ�V��]�2,R�7Jhni�yK�˵��X�ُ��r.Ѽ��gN�9�_7���V��C�e3
��P�Q�:&�	唪I�z<��PW�F��S��B7#�q��^��sp��hM��%R6��H3��E*+���"�����!�E����٨ۙFj�|H׈�Z�Ew��~���1#���^���*���I{��E�k:��x�lD�.~��W�^��.��O��Ä����?�C��8]��N2?���'B�x��&m�g�F[+��:I/�G��qW��\���a.��	�@U�c�w��I@ߡ����;²��?�pJ�LA8,þ�)+|�mD42���5���A�G���r(�Հ5+�~"&��T�t�?d�~��(��z�F�pD���@~�*�O�a�/��s�G�x$��bo�.vq<�E�+e���J�d���1R<�ii���z2>e�t���קA$3Fk�Yk<��R��g6�ĤY#��/}A�_��,l	:Si3��ؗ%�K�3��Q�ߥ-���A6��"AY��\��Q�8Sw�3[ItQ�tV#Q�S�S}�t%�lT�g4P�W�|���Z/�_�M���BM͑Y�|ɪ�J����S�>����Щ���\�#2 �$�ǳ�H$�n�7/��߳S�i��F�#��
̴�p�b�v#U򫸍�*sC�Se�z��)�+�d�[��{����Ւ����6�*�F����s�sw~k0Q��r[-뤩�3$E5�̈�9��:/T��˟����@N����n<�ģI��{��[�X�
*�l&w)/r�C�S>+��_j 1���O��$�`��� BC"F�qD�e����0�hκVH����e�>w����Qɒ%��3U�P?���Ky�d�t��O�=�6C��}�0R�)�MzN/	����AZH��ފ0&� t�9�I��nn����H�tfd��Z e�W�W�w��A4J�m�}���� �QX�\���ʌ�dn��yh�V�}��ŉ��Ir/r��T�b����t4��LQ�v��d��]�8���L��b��Oƞx�I���y<S���r:PC8���{K�T+tΖ��o�{?����y��Z�￥~�Ϻ�.������2;r[9���6G�ɑeq��f�ݏ�Q��~O�}��/5y�m��r����J[!�7���fG�	4tR͙r]�~�LA[f�լN;�3�����gY�����JʭM��f)�0�w���ho`f��7�y��.W5����S*��ѹ�Hp�X�R�TG��h�/ݽ�+��sJ���9R~1%6�!ƹkv�
�D�����Q�֊��5h߷�J��H�gHo@^#�e9�󘞭GR�쀗���iNm�U��Q�j��1 �lU�ՆY�}�]��c�o:Dk|ߜ���T�m�T�M��J%.�>�LH�������IVG�f9��jJ�ժ�ӏ��F���R~���� /F���b�-�^ �%'��H�$�Yl��|�t��/"�q]Z��L�-��P�^�9�<�g����l��������kl0�N@�t��֖��Jb�3�49�����AeG�!}�U���?��e٩3T��1f�2S�8#�1�Ex�򸜮����W۾��q�l��zu͇@7��i��'o+/�?��^���?�^��W�8�
�!��$���=�-ūc��3��!�5���I�4%�5?!�+_�%E�4|�`겊hV��e��F�zY�}15ݲc$I�S�+L��`=/�\��n��h`�]�#M����YUX6ɨ���B���,��\��9a��H�	Jw� ����d���W`^�ǫ�Ҫ�r�J��Xj
���5
�`\����.`����C����q�8�c},���m��9E��|*��˅���I��g�֗8��z)Nj�{賱8���ͳ`�J�J�i� �M�/y�`[�bN�t~+A�W9-��j����_�MFY٪������W_ol�s����?����]��okպ���@��|Fc��v{$v��P���s.�4��m��
�|��]xi��}P.K;HV�u0޼һ����{����]4jos�o�~<F�O�����N�Y^>�׷��e�2|���w�Qk��ƵO_�A���Fo���ֻ�����&W@��G\�*��mX	��z���H�iV6���N:{�o�k#��׮���>^⑀�kih0B�b2I�n��R$^A`i&�������=�[���]
T�'_h�NЏ�Δx�W�W��r/����9��=Zw��1���D:�&�.>ߓ���O�ٹ'D)���A�Nm�ɫ���n�4@�����3[{v`�+�3_��01���⛗���C��-�\!�����Z��1�
���:v�D�h&6g��De����d:¹.�/��'ⱨ��^�8<�a� ��|px�Zv��=d~������烽�`vr�"A�Ҝ����'�@\]d_�ϡ�%�W�ג?q�y��>x)_&���U���$O�!;���j%Z[�X	j�\)���{@���T�~Wa��(֐D�!X-T(}A�͕U���� �TT�=�Z�خ��P��%����>k��ZM|Y5��e
���El��s�R��C���=�������v�k�?l��j#i��C.L�p~A{p:@| ��l�������U;��	Ks7�i�I[�e�>��=9i�t�������ʙ�l4Q��d����%��m�����IZG��f�T�V�g���dR�I�r@��8��E�V"���*����)��s:e�M9��n�%�R3g�N�2J��E-�ł��=�OP�^	�ҧ ��IGA�D��-�C�	�Ҧ�h�CӦsk=�=i��u5��-�[�`�Qi(L���u*{c*�mXˆK%u\����5���o�-+e̔���3d&Q�^�A#�>Z�tu��Hdw����MG�b�O� Ƴ�B���܁z�` �4�in �N�WrR�Td����4L�)Y�"sr��&u�d�cL��^��Hd0�S��<�%Y�H^�
E����Y�r�l�yZS�{����N�we�? %~��eA�;*\Z�.%Pu��F�8#��d�0���e���fF�3	=��ϝ9��n�)R�eEU"Gj�*����5F�6�\o�z�0���!�lZ����WֶԢ��c���`��DN�����`�����8��"F!�(�+�!o��l:	��Q؏���2��U���1>ٮ�G�U��!��gs�GW0�ar6l�u�w�Z�%�����LD�zR��3:��I/�:m�,H�/É�;�9Gx��0��a/!օ}�g]��S�5$U��]Q��ąx���!VƊ�NzE��\I=��v������	Ԑ�y���#q2���1~�;�Dο7��t ��|d��&T�I�n�"��`�G�&I�<D�a�"�[\�Z��~�_�G�#ԢA�#��i���T��4��Щ��D�IgLǖ�r�7Az���جޯ���	]��?�ҹ@D$`�)0������E)���t�=,(�C,��tD�RŞi�X�T$���CM�B��
KKت���(�I��Ԛ�3
�p2�=�"�M�b�����ŹR���	��ue:�آ	�"���l�l�P��>U�r��:\�V'>�8L�D%ٍcL*���YK�p
�%��f`���2�(?����,�����뚹���6~bϹ�%'�?O7�@ҟ0+1}yp�U���5q�������y#��g�ic����������?u����U����7�׻��]���g9���W��^�CTP�s͜C�HV�#��['X"�����	5ݘƩ�j��ޥ�]G�J�=Ϻy���*2v�8��R�I(6�,k\eU�
*&s{S��hC���9�9 ��N��\���8	*��lZ��L`��L�=0EK�!�����C�ב�
��CD�,=niU9{[�>j��"7WJ$,W�EL:��,��_�+~4L��y���3X0�PJ)T�r*��sHF]>q�'!=��s-W�z��j8�l�]$?# #Y�&��$�כ��탓��b�ٕ�y�����'�d�0�M��)a��|���
��rڦ�9-O&!�H3d���i��a���.�x���[�i9�2�@��U��/��x���Cb�_����4���(A9b?5��ːK�xȓVsE�W�U[T�P_�&���)�s�� �8q�b$��*����U3�2�/}
F���,$_�#�Y�T�b�EI��M�VҸ%�[�*L�K�2Q��KmHF=�Rb��7�����>8�h���aޫy\����{'�����[�/��6��7�0/���C��P��:\kVi�}�{k���C5��K6�
GК⎥�������8�_��R�����Zu�1g4Z����R��L�z�<�$v��(����G��O;�	�Y����/�!��j��v_T���t�y���.��3+�Rr��1㗛��f��J�)���'b��a�)��G�k39$Д͆
n�U��I[�[��2�����I�j�H�X�I�m���ϼB^�nt^�@0�6�����������j���9�S���wզk{Q��:���\Ã[���¡��ϫ=Z��k���N��ij����y�DO�_D���Sq��{:��l��~���W�l�A/"	"�#�U��K���,����0W��&7������;�I�������3�TF��e���*��P������:	':n�$g�����A0/�d�C��HHGu��Cg	�����$b�j)$�1���|YIQ��ԥ*��Ȗ j�pi�2sUR��:B}R��R_*�hn�:"� �'�M-)
D���Y�0�ٰ=�G#$3Ri��)��S�H+�`���i��m����i2]�,@�̐5֝K`�Q�MM,�R��-�k6Tj�LYq,�p�x��N�o�(fH2>�ؗ�d0j.������^F�Y;�_�{�������^�s��kf�C���^��d�"�̞�zJ�Nd�Ā[)R8"ic�g�_���+I�@�<�E���ے�����'E�J�?�U7#4�p����R�S��e��_>���7b�IV+G[F��kk�{j�����)i�yɐ����q�~�@H��)��l�<�$���x�l�Q��}�V�#B�}���)'��I����/�ܪQN�^����p2���;��f�֭�kK��?:�k��K�t�nul�4������:&�JF��l��㽦,nl�ه����bφviL@�k��naf��ao�M��j��oﷀ��+X�ҏ��0!�9�;�G�P�a��K����uT�.sX�������q����Q�{��m�m�c�/h����-��}����fݐkj�=�~/�Nke~���Qqi���ԖM�C���LQ����Ϭ�pb
Q�͐x��hb�)i�	J^\P�+!��w����D��!jUp(�+����^k�ݪU	��!���F4ꚺ+(V?((����Nq��u::� ���4-��QՂʬ1��?�.џ5�3K���fJ����ʍ/�U.p����j�%��Rs��� �!����p����6�S��U��(�E�����ئ2h�V5��\�X�r��>�����`�A�G/��Dٵ�'b��EAk"]@�:��Q��Փ/�ԃ޵N���-2袇�B�*�X�}�2B�6�\�}�}�C�-f�cf�J�U���X3��m�/�� l���,��ύ��X,�y���>�ψj_�oLoI���X�)M�}�汰��go��dW��˞�ㅖ��;F�!'�?.*�Wcd>���6��IYn;��x�ޭQ�i�����q�~{89G���y��'{�����؎F����Xl�n��8�+��~ �zɚYiu�Z���Z�j2���#��pB�-��16�$��J�P�0�Q�2�"Cˠd��
��׎������w�ȓluvvZn���@��p�WR��\�%��؝��o�(F�}`2H6Q��_0Bݒq�#�'Y��8�>�,z��:;����B6S�������8+�`6�횛W0Ȑ9b���Y���6頲*�B�Bhxz�E�;��i�.�A�!V����x<MV��&�u�H����5}:�9Y��`����ό�+7���w��茤رZm�붃�E���XT���k�Y�ߦ
ŕ�P�� ��͝��x�77aϜ+�!��cka�,�2?Og��d�R��;��4;�� ��:�O0YN��F���VWD{����	P/�"���j��z�$�A\6'H]%�T�)���0��t�^�0+�mRP�+���C�+��H�����$�������ڨ>�]��X������8��U�iVb� ���*Y�Va>�%��7����rCc��:�i�QL�s󷡗��aWҧ�ڴ� �K6,eIR��rpS���|!�J�Rw���\}�&��=`�A`�fĊߩo_R���^�9[�o� 0��͕�C����h�D����̗�*(.B �SWd�X8T�e�!�4��l9":��0c�a�e	S;-ǎߥ����1Sw�+c�R7aؾݮ}�{�{�k����a���wC� m���w�<tK��w�9����k�����w@��'ǻY��Ow�$�la��' �I�I��Ӂ�n:�8��'8|g.u�y0�
+���8'~ �M�h�`��C�/��4g�$���{`X�u�b����%������IX�Ë�T��]:h^��N��ѼR.JbN�Xn�;�E��ϳJ ��u��J���_K�$s!-vn� dt^���fF���m�A�TT�O:<lgF/n�i$Ў�����N�/I�{���4qV�FH-R����{-��{a	r��Q���fx�<�%�WMO}�A&���3n1��/U��ZO/Uݓ:xb�o<�.��ц 4�W�[a;�e�7d�"U�0O�Y �8TV.�%����a��.Z�c��˿	=0v՗̶⢤�Mϲ�d��鮘Mc9�ʞ������\�����ST��97_��4�S��g�{�m�I,��G�1j����A�Y��qa�u�0ߢ��CZ�r���S���:c�"�Y�p���1*㸴��.�CK߾���S��"Dka�3$"�	�]���⛍�A͓v.�igh}A�M������(� ����ˊ�¾QAb� ��
b`l�<K�Y�/r(c١#��WVSN�K6+��%IAȨ��G���FK��9Q�`�]����:/�u������И㐢 �{�D`�~�s �����s����I�bm8`��G�{9����H��`]Rl x@�}	kA�%t�1�	�)H�s@H��VP����S9vF���Gz;���2Uځo��j9�$O ��G���[�����lH�}L`O��=b��0D��6�E�3�Ó�	(���[C{�,���Y�eL�Ү.�[��9ic�VE�k�F�-�l̆���ڍ�g�yg�9��Yي�6���}ػ���l���2���)�b�"���S�p��i2��]�������Ȍ�5����Έ/�+w$1!�,ə^o9�ޙ�ԍ�̤;��-4I�-��tF�`tymWCF��I���&]Zz��5El+�.�S�۪N �]vwH��!�ґ��y=�O{�G.��8�{�TdM�}���Xt��[Z�g��jx<�]��;1���}�-�Δ��ߚ�2�JB�̍	'5C����,������ r/�lcu���f�2lgڊ����_���2[�7(ω�/we�S�]�;E�C�ݳ����nC���� ���,�]�K�e��b)�7�r�+�V��F���=��ړ�j�㨙��N���������[�������pz)�/�*���uS�q|�إ��B�q����:5kӿ��Wy0,=r�M��؀����MU`�6p����B�0��e����=�l�9�2:��;-�����A"�x�˵<Rs`����u�7���˛z��S�ڬ!��<J�H|Ao��9Ft�Y�Ky�9%�#w���R�n� Z+���p���S�6�y�s0wұR�e%d��P���Jv�Y(e$�.�(�A�8
Pٝ���;�[\�y8��,!Ϊ]CQE�wa��a;��@2����t�A�9Ƽ�S�y@掍Y�u�&9����0w��ΐ/w��L����o����ӧ�o�������������oE�~�N7^���&O����cs���Ԯ���W�U�>d���k=�K�����µU�R�+�޸��㯄
��g�I+m�ʪ�"��l�+���@����[G{!O�"*��px��~O�o�8e�Y������3B�uC���RT�+A0��T�"[a뒽���2��<:/���E4���X�h�B?-0���T~�Yl\*����4؍�� .���hH��x�ʭrTk����zf�*�C{r�|e�O ��r��O������s݅�y�!D���J_�y�X'�r���%_��[*"(����IRŋAzIUH��� MO%����!��IG�E4N&���%�n�8��E+��t�%��x]�T)}���&��*j���.��<�By2�%�g*��W=�)Kq���&=���ݿ��C���z�up�����-�+pd��{�iGHjq���*�v�y���>�Fۃv�p߻i8�倜Z��{N��O[$�Ck���σif�~_��(�k��M�&G�u8&՝`�}q؇��4J�9��ު�-`QG���>�<��k�dpJPQ�����!�Nڹ��~އ���P*���\��=>�Er���/�������?�HzzD�P�Xg�:@��kf��~����C��3;<��|1�.�)\�{�
8����X䑋����}GKr��;9<�}��w�Lٸ�2x�|1����M|RO��jwT��	��iR�d��x�9�S��6- /ܢ�� ����j�4�U�؜��������جDI|R�)4Y;�1�������u��(��!���~�����Y��F�mds���&jV��;-��U�պ�e�tf�i���_/ռ2{�L&2����Tאʤn���r�9&[�́sY�
QwН�Ye	�:�[�t����?5�O�f)�cn΄_�a�d�UU�VF�ޮ�H�}f7���	�;W��9�C��N�ig��vd�i1;2k7P� k'`�h�P�� )m��&��D~���L0Y����EJ�O@yƩj·g#�6�������R�f@£�4>R�+��b ����i��d�h�r'�">�h�v'h6R��"��dtC�ph*�A�����N;�'�}+��Ϫ#|�"��(�
,��I�KN�&a�:Q;\>>6�9z�3����$)>�[g~ �hӭ+�ciϭ@]�-{��y����j0B��CZC�Q4�Ǜ"\t¤Ƒ��&T��V�)�p��~���L[s8:n�57�J�#��{!Uy0}︵�G�J�o�S�A_&��ӁR4E��Gj�OyQ̙1�)�t+r�C͉��V����p�=�F7}�V�O_�휵�Y���"JL��Q�%��$FwO��ez�<�9�<�����TDC��M��U��RL깱}�Q�V/�a8
 O��j���Ip�Բͅ�zpL9p���ť�=�"y���iJ���	�ScܐJ�V@��w^`�UGIz&�D�L*	?��z�E�r.y��[�0������l����},��%֨Ƈx�P����ѩ�P��PsSʘ���J����߾��g<j	�^���P�ǣ����?7�>��ꕌ�azg�nh-Ծ������a�*>��j��T�W��|Lũw��Q�(��b$�8��EU�����pS��
���o��e���}����d�3M�wj�o�^t�"M�����j�E�����ݹ��Ʊt�z����~�x�G��~8�Xl��!�8��|r�/s����z�8�=�+-���z�����;��|b���c}:�^�� ����e\Oc?M���&���݊�	ύ��t��~Q��0�M���&����� �
�^��!`������8ue`�=蝋K���UB��b�s�)	�sz���}R�aÿ�d�d/�>�$x1���/��e�=D���=�P�ɭ��/.�*�H����.,��w�f��Q�|9��B8�T[�]��h@Ӑ�s�����Ha���08�*�?�F��b��R�D�B�ʵO�p�o[�����H�e�w�"��v7�u�����_��V��de��f�94���*��jN���R]�t.ۊ����`����'������
s}9�@N̑p�}Sk(�7����]Vi�� ����o{�Y���l�P�zݢ|
�C�j�Q�@�MnN�����d�ҡg
�v<��SDd05auN`��A�-��&�����F/�7��m�_��Flѝ�����o��J�C��������4��,#u��G���A��;����<c��p|��'[��l�ٰ���}@؂ɏ�u==|��G�(� �|�^�u�zBJ���U������YͲ{J�3
�����%�'n��2SXc����PC
�2�|����ί�P�)��$?M��V�j/�F�X!�0|OG�H�ج�*���N���[��R�=��>p�����`��zTT�1i)� 	
%�Bqj�L���Y݀N�t<��+�[��h�2l�*L�N�����& %cq�{e3�W�m��gl<��ގ��O��R�KG��ng7k�nl�\K���b�ZV����Qvlx6L�rO�]7w���.^�h�\�r��@�: �4>MH�d��S<�T*���9 t¸1Bz�+��#5��W�{���}�0o��	Qo+5�;)w����8W�ײ7��������������������Y�X�w�c��D��8�?��1i}}_~��/�p�>ݣ�h��͊�\��Y�����1ߪp�]�,]R��+	�P�,��r�h��a�{'�������,��d�^�c]��)����L���#����6訴��	;��e��E�˨�A`Rh@B�ҚС$\Z*�)$��If8�9QZ�P��v#�waO)L����g�����焊����zG>k+uӎS�NÅ��Q繇Z�i��g���������b`YT�Ua����2��clQ҈l0�i��a=�6<���4�_&͕2�ܳQ�0"�`Urhp�Di������x����;lz_d��ݚؔ�@	yGŗ{/c�D�L�ǰC +�pq��bO@@��� ���8e���Ͳ�W0�Ov���Q��,PE}��F�O�$����	y(ժ�m���|�@�?��"o-��{"�2D�t.�����Oa	v\G+2��]��S���+;�j���I���~�F��MJU`�x��]I�/o�(dD� �Q���a�փ׼3�e�R�H;)�0�5�!���O���]pZ��'?s�$��e�f�/�]oOÁ�8�'���'sx;��qC��� ����ߢ��	�a'�qH���lwj���umXk�*C�H*"�{��̖K�"gŎ���%.O�CZ�pZ� ����v��?&��q0ǿ�P��54�2��89��ѣ�3����ih�,
o��]T�����o���(N�У�\FQ�"��5Fg��U���y��}��O�5���vq<e�xg!�%lzL��S��t��㽏l��I�~oI�}/���l�^��O��,��Rb#.@��M�!��R�Bi�o����ڝg;(��0�MEK����C��;wR�g�B{�٭o���b�饿ŀ��e7�e���)i~�dzP]Zbýb^L��-�K���f����,���j�E<�8�j�h*�
��-=�.����kE�KE�UeU�z�x���8�
y��·��M�z�6P2���V����.�`���d��2R0]��Y~cE�!���,뮈�c'ƮO!p���(Lړ1�]��"�1� /�}�L�x�Cr e1zBz�I��uv���i W`-(��-]4r�/m[�ak�_K��&�z@,�{����fv�um͇�2i�wlyO�L��޽Hb�����OC�L���f�\=�����t5��Q��R'1-��Nr*iv}�e$�-R$���lf`���;	�uF�3�NȜ�|ًH�N���,���vD�����M{�;�/Lw�[��j���Xiv_�L�X02�=���DW,�͵�uZVI�i���8��I'��G�?" �9b��K��
�@(�hJ�j��x�9�PR���د��(H�S⃘�*�4��N
�ۄXs��Ch4P���se1����0	���A�_���nR�M똃���2�?����?���?_k��8�������Ӈ����o>���__[�g����_g��||��;^V,���ɷ6$��㳪؞^��_� ��|�U��/C߫����-�V�8�I'qFy���w�ڻm�n���3Pp0�����,):�8��~¡?��s/��J�L��R�L�8}|YQV}�ҭ:��1#�a��
O�WV�q��I���c��j�9ޥ�z���h��h��������>:y�s��U� e�[��Go�aJ�Ӧ�r���%J+e��!��*��ˌ������PהX���J!�trh��G��g�f�t�y��
����HN��f2k�0m������LM(��SN�.u/?C���Ju4`,�W�f�P9�?��o�e��jRV��������XgK��]�B��uM*h�6�CC�����\ּ��i�+!ðkN�p�� �m)��l�AW��x
B�4���*�j��@�ν�̬�8Sڭ���c��vY��pm���5>N�����II�+Ж�H\�F@�(5��"A�p���vz��᱗�fY�Q@'����C<��`M�W=���w�'��n?�����>��W�[kl��������W��oxꃾ>>��~;�Bb�қp�#8�5Z &�0��XOK	]w�� 
'2��l6��q������z���n��JQ*�����b�a��d�J�H/�/k�+�VȒQ?�����C��K�h��9�}4��8^���'/k0h<t�b�z��b�O3���!NR8�/,V��f�$9��Ί��DG��֫�.V�K6yG���NbͲp؄�$�q<�|��VC���y�h�U�b�Ļ�]����L��Wu�	^֠��-Qj�/��+��e<�J��Ah_b�����!���4�+�M۪�#UO���̲U�g��83�G�M��tq̳�K�8J%���jܥ��F��-~��<l\����_�F3L����{�o���_7�7����s�[B�c^-`ב�K
���D�kq҇�m}>�d/Z��+R��b'솃�p�D�^>Z�����C{�<��#�)���lQ�ԓǑ-(��`T#3��V2#�p�pq̈]Tv�M���P��,6��XH�@|��j�A�m�Y�J�Ф>��b��$��Yb�;����"���@p&%�jf����5�v��Z���X�ݼI�9�?�|W��>R�A�FX����?�v
&��b�b*��b�|D�B*�E��F�m�	�P)��7gw&�+������H�j��%$ү��j��:�����hBkL�(Ze�zi,���=s�r�mO/������_A)յ��a-$KB������D��M��`�C3�_��
.��B�ƌ�A�7�A��&��!��ԸL5O���;�$�$"E3��-^s��J�Z]0�X9��e�! ��ta �����֍��B1+ԊU�}<#o50 �DI�DV��������T��������59߷��9��aF�P��ޮ�Gz�a��oƢU�H���zǚճV���6��9Ѯy��Ǭ�&��G`��d�����~p��X	/�S�.�6�-���ǆ �nb�,����n�}Y����F�,����t�O1Y q�2v!8�%z"$�������AN�_���-{�\����������x����U�=~���<m��7YЕ�*
��W����o�+ԓ�"E��Ǐ=��c|F�/$�J@�t��~���̬���>� �����e��E�{��Xѻ���?�1�.��Y۝�4�~r5�cDk�J��S�~�7���Y���.�W���L���mϘ�w��ߙp�j~���|����gN�����(�E�x��7�<��,(�RAU),�Zy���m�� ��T8//�E%��0���/$:-%.|��+�z޿-�n �kJ lt�HX���3M��v���EH�@ �A)��'��㧔Te�t�Y�����<FE#;o-������]����^�����|{E�� U��:p�HVI�*�-r�����0����3��������מg���66����#�?���S����U&��$�p�v�G�7� ϻA�~�����E
c(-���Ǹ/&7�����JHq��W$(��X!NC[&�B�%�@�Eu��K���qk{g������ʤK@�@Q7�"nRs;K(�&/����ΨG&��a���jB��_	��I�Q�*D���i�b�|a>��F��R{X!�.J��}��������U$��X��&��E˾uu��w����=%ѓl� �d��տGx��=]�	Y��q��$��8Q鐠q� &ѓ(��E�&�ޝ,'֑��}4kMF0%r���MBCi<1��ZUD�F�l�M�@����+��?m)c��7Xm-��k��w�!��*$l��{j���^��,	zZ�	�U�Rs��*��=�{������ÿ����?�Q� h 