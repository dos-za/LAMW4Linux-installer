#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1144479959"
MD5="15300ed4cb797267c39ce7baa54ae73b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21238"
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
	echo Date of packaging: Wed Nov 27 20:16:57 -03 2019
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
� ��]�<�v�6��+>J�'qZ���8�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ��a��`0�7@��_�Ӏϳ�O���iC�N>�O�n?����F���d�y��+|"�!,�u/o�����觮;��|�0]sN���o=�zZ������Ҹ��/��~�OlW���T�j_�SU�'����-ӢdF-���Gf葃�c�#�Z���l(ն���Ԧ���#�R�����F�I��R݃;��ЛO��F�Gh�l�~�P�SJTY�Ub3�AH�	�w���^���NF� &�� ����Ӏ̼��8��f� JN���_��
��=�}�����h$�����Pk�դ3>:����Q���X!Y�\o�CM�O��q�e�M����9u�Qo�y�e�m�e��5|a�(W)
���! +�
����^pY�;ls@{F������׊kQ��]�9W�����`~��5�ƺ����9;���(3[Y��Znp	�
�a. �z���j��QP��7��	l�2�Ft���e�6��RIx��_�Cק�;^!�H�X����	ۧtzF c�} ĞE�Gt1��Q8�	�A��(P*S3$:��<�"�����a�o��g�[t�����T��D�1H#�MXLeU�JEP���w�9�Ӻ��$�����M@���ZFmvxz��n�	-j-Q�)*'(����q��]ᗮ�h�kR�����e�`�0c6��'�7]Y�w�A2���(s>uj��e2�A��&TVհ��&څ��6�ܼ�Q|�YtfFN�� H+�aީ�D§�(e�q�T�����v־�ؠ/�P��gv�������.�^w�?l�j���M�d��7莠-�M>�>�UR�Y�"{�0�e�G�K��z���ԴR�N\E�N�	!hq��b��XJQG�H�QR��IB"�����)��Ma%�V��0m7�T�'NV���</,�O��ib,�j,��>�:5Q�<D��*�`2;� �+�R�M ,����[Q�6�<��������;'C��Cj�Ë����[[k���g���ɳ����k|^x�h�"Fs6iG�4I����9��d�W���#q�ȇ~��.�k��J>�"߂�_%���������
�� �o�����[��j6���?3��V��EwH�������Z�.Fl��v�x�{p2���e>J��^D�%�1x/
!̱y\~O&�l��IB���g�3rf7���XXϗV�{����d�C�� r��<$������u셍a!�����ua�QF�1�y��32�P tM'F� :��r�>���dX����STP����ռ��i���rd��o��G��f�ƫ(3;`�9�i�3
���w�a��7}^gє�Տ�{��5�?/9�������������)^�Id;���+����[+��ٽ����f���o>YW�/
�� rA��sCRA4�����S�<� �(�~�
Z���3��Vk�~�����k�m}%ǮT-�ihB��;��<byd�O�4δL�z��&Xo4�,�����6�6��Js1���� i��ƺsE�8���f�x0j��J��XD�.7�<̰����ya��z2��0"���c L+�X���|q��2^v����m7� GC��wI�9URr�O�z#��dp8��j���[�";�b��̱I.�9gz@
��OƍqC�0��a�����0T=b���ȡ�X{� C��I�Og�"�A��v�Ɖ_u�n�؈�x'���4R͸�(��@.m�iI[7.	z�;=I�q���4�AA��n�����_�� CP���fX��⏫ù)*Â?��R�:�=�&�=7Ï�����âK�2$Z ��0{1��OǞz|�
��-��=3��%�y�?]�r	�ױW,�3�����J�+a:z���y��s~jOO�ۋ3PMƶW��Zn�J���g'嘋��Mu���D��Ez��3��<�{2.����
	!?=SV��	�P���t����K����b��HV��zC��kPS��*\�j���w�����(&�s��nv�Oތ_�:\0ة	�),� ���Q���ǒ���^�A���Ԓե�X:}*�W��.��G�\��P�����֭4�I�CmuHh�!�!}�*�G4+�/& B1�����紂�8�=5�9���W*v��@J�]�`m�L�£�8������L����58�,`�?2T�B\@b�P%�a�/"*��C���ճ�ڳW��WOT�_���1pg*�U�ܘ\)�Iܒ�H%�� �c�d���J^���!z�(�h�$!~���%j�/d%�{ߟ^lsYv��m�8\�����]�t��v�>�e��k��Ԯ�{����J�ղ!���R�K_M�Mk�گbh�NS��b9[UI֗�H>������˙��t@+� �u��$`�u�LO��J��.��d��ݾ��|���kǋ�i/��&�Z{?��T4)Iƣ��K��
7�Vf|i��\�~��!ɷl."Gr����֝h�o#�a��C��� k��3�il����a�>W�� ��<
R���R�t�e��u0���l�zݽq,G�;2Naē�57[��5�ታK�I\o�rr�W�I��y[SX�/�$�J��gٸRR��9=3�Txܽ�~��p�(��I�n����^�0�Ԯ`�����_�Zse���*��}��_3b�&Өe�+����7���W��O���������үf:�������7�H����|�e�ġ����Ao�b�.����Z��u�]R,``����3�0���T�J���Z�%u<�����A�7c���@������K9�X�f��9 ���t8����E�RO�̫Lk�@oM����{w��{��yF	�)�y~\I�������C� 6���wb�%�&!~`��<�<�:u�C��D���F���m�������ӫ��^o�3���:����ކ��A�o������}H�_!d�T�#��D(~����Ŕ�y��h��k�H^���i1�r�X�4��D��CN���?��c���䦨�*��\�3�|��h+G}3<5�,5/�U��T�.�E��<��πlQ5NWc��1h��iR��}X;�5B�� A��Z4�)J��)�鍕���o�#�ݤ�����}��*��Zg��!���ch�:�,^�m� c�!���:�xCܸW�z��0�;z9Q[�u?�h�B]t�*C\�Tj�Q~k��Ry=�x�圆?y���3���P�(]w_-��P��^E�BR���`D�a*�u��v���E�L�$!z�x��D��+�F�I�@jrf}�숂LMp�BsAqa���5�~03=���C��B�7��$��D��S	I��q��eY `}�9z��C��M�X�/Z�câ�Ơ$�*�b����h�T�>�aR�]��S;��;9��C�W��BL�>wL�w"yg@"%�@��A<�E$`���Z�Y�J��R�wY
K�-�u�W��B�y~�J썑N�&?�������G#qӐYˑ܂�lwdBРh�Ay����}#n�K��\FS)laB^]���	��@�j��@#�!]�8�s�I��0�q������|�3z��(�^�惙�G,2�# �����ԋH�R#y4|+3��d��]�'���Ѩ�:���m1$�W-T be� ws�ƎOT�Ƣ<��B#"���c��-vς�����bo'V�݋�nN�����Î0�I!e-�T1Μ5��)����T��:㵬��D�ʰz+�
�!<�����hq�nB^�'$"IT�w7�$��<��#�h��?ծ�s�>~�k��0��ġA�%���� �7JB���$�`ul\q��X�:�o�ιD��(�1z�h�\���Yr��ɥ�D��7%�bR�2@iȩ⒏���t!=�+k�'jםy;���(�b�S,ݦ���ΘoNi��׽��!�Ý.��p���b֙�1�?���9{���wh�rq��ý����B���x��Xz��1ƴ?��A0��z��j���Ig���/�ԤM�y(l��1���!��d<<��{��q�(�b'�ljhwj��k:0"|�"�!S�0�{��J�_��%LM�*�F��_�C7��o
W�>B�޹7ȗ�̄��2�z算���rs�vn�Ej����,'g/�U��_��w.�l6� :&ٲ0�\P7"5cs��w򎠭Xr�����;�{iX��|AA���C9�RNi�=��B�Y��s׉�S�#�{Au_�Xi��Σż9�mQvz>��3�vO4��<�^�.걹�F�%jj��i��������@E�i �3��DF��Ĥ����3TY��k0��-'%�;E�����`��]�GQA��^�]���k:��M�>5Zپ�lh���y�`Hu�]�mwB�!����']�=.�
��k���Gm�d���#�NNVH/B�Bww�S�0`��dX�D���v��!��`s�%����H�6by�,�3�,
�:�X�Kz	��b��-���:�C���#8�]���<��B��C�y���F{��юa)Kڹ)��}��=1���L'�F���h�n��o��ڞ��I�N���J��m��:�'��s�$��:�y�)���R6����}��^g�r����t���MmST�:Kߋ:��_��ނ򻥦r��K҅��yd[�g����*إ�A_?NMJ[�N�f�����,Q�-��ᗉ�GB�"�9�	�7���ކ�/!g�;�wy����~�HT�Q�5y�>��%J��}����^��=��ݭ�����Q4��?˟
���>�Z%G�2�R����ܫ�aVILX	��a̥�D��x�]���\�ةծz���/����k���:�̅1)��A���Ս���A�j���io�r�*�>N��L����,Iƛn(P�� ��T�����:�z��4��X�څ��p`)�dc�Tɡ���(q����O% �ܹ�v�����f�.D�	h�ٮ���-A�]�[�?D�D���?��I�1=�g%�9�IG��Tc�f|� ���ž[�(I�?2MB+�9\Z
���/�����؟�Wa�yV�	��/�%B u��X�K������������-����F����pi�K8���'�a|H����q�$���d��s�|�$�'���TZ�Y���߹S�U'
]pqz���Pu��)�=P<C!�L���to �G�5W�k�ΔZ<�x���3y��*�ͺ�:6�A�Z�TR-�~���D-a�*�r3��%�\�nDbո�Q��䫄I�M�r�R�"���*�դ�
�n���R���%̩a|��O�P>�1L��7�΢Ir���}[w�F��y%~EdG��$EJ�D2�-[���n���t[Y\	ɈI� %+����Y�0/�k�<&l��uAP )Ev�̐k�"����ڗo���')N�Ve5�!�6�����e�Q��m�q~�?���ռ�t��ҘѤT�����J&��eK���+���#=rJ��R��V
zT�Axl�
�B�FZ��Mz
pI��̮��*��Q7r�Uz[}=�E�9�eB��Iꅽ1�pCG����_�d���ax{Z���o�h�ig���"`�+�uO�����ioWW�p���[�3�na�l9S����j�F�:��A�9i������\0I��(�����)�n����b�g?�+�D�rbC�9���+�n	��W�un(�1P��
iD��sN(gTM�ш�B[x0z�5�7�T-"݌dƍ�F�!�	8�5=�֚T��R6��z2���^��"����´�ᦋ#9�٤�KFI$�5��`��Ӣ?�/��G,�|����Wq?�%��}\\�������`�ǯ�s�V��r���5os}?�����Q�Ӈh��Y���#���ХM���Q��Ҋ�J2yՓ����/Z�\N��`.k���@S�#��{W�أ���;��;����?Nx�ñHA8,����UT:z�=��2��k�+���
*
e5aΊo?B���i����'C�	�\�M�6��;LG���aX�.���$��?����]�F4)p�D1����H�L4�I�h�������}YR�_���`HD$7Fc�s<��R��f7�I��(F]����"�Yz���L��ȅ����'������m�q�/�!���M$(뼜+�9�g�npf�#�]T:+��	DT����T�%]ɪ��������#�����m*Xxf�[��*�S֤W�O�Á�&P��^3XzB�2��sy��p ��?Џgu=.H�>!n^ �p`�����w�q ��W���>�� fk�Rſ��(�2G�*���'g�Rl$�1n���酘mX��������)5!���]D�����D�&��kY%Mݞ!)�)d(������ ƭ|����` y�[4�XpѨN����覷>8�fT�t�R\�N�:"�P+��_X 1��jU�f"I �\5������Є�;������X�;��a�o�Y�
󼘸,�������*)�}<#�
�{a\���!���|:pk3,?P#���ǳ���Ӌ�W~��9��"���=�}�:�q��nn������t�����@���<�<H�8��`?��f1�A,����,�9�s�����а� �H�	��O$ɽ�%�vP���)�C�����3��u�''{�o��)'�b}���x2��3\z,�qޙ�ѭH	*�5��Ė�)�S��9[ɾ`�0��ݸ~V��b��K����q>붽Dr�߆������udq:���.G�Ǒt8��ot?�FYo#�=�}�:����<ߠ���>Bw�+|�����܎2�٤�#e���Α����Y���g~���M ��K���&)�v�����E��=�w�����I�^�慦]�j����O�hg�G��"��b9�K�S���u�t�~�����)�l���I�I��0���1+��S|�����U���@c�};�$�X~�����pĽ,Gr��z"̱*x9��T^\�e�6�Z9 �7[�p�~p��]��c�Dk~ך��W*�>{2��Du�Z�]&�����睝��҂�ѵUI�b5e�j5(��V/��V��d^P#W @Q1+��^ �)'��H�$�YL��|��~+���V�C&���b(� �9J��JH׌@�OH��5��d��P	ȖN��ޖQI|ߙW����4�����#c��TdL��_~��b�*X��3V�n�\�7�1�Ix��q9[Yi��}�����X����ں7�~8�M�垞��>s���z��/D����=�
�p�&�G~�8����R�:n1~��߅#�N07ua�&ſ�WH��e	"�o�|UVў�f~^���^=����nY���j����`.z^��x1�bs����ZG��u��0m���p�ʪ�,좺.�sB;�q�'(�5��Mg}v&v�
�����5F�ʍ�f
���5�`\��p�*`����C����y�X�c],����#s�1��a#W
'�����g|��hp�4N�)���k�69���ų`�MJ�F��i� ��%����`۠bN�x~+8���&9M��E���������֬!g�d���Fs�����X��X����J���k�͂�f��s�$������0`c�����y��(����>��{��rYZA��/��������g��t�Щ�˫}�]>e���ڝ�v��r�mlo4G+*d��N���_�û��]��%������M������w"�4��HVUcy�3ʤd�F���6��iV4�����^}�E�ɭ_y�rc0y�G��ҧ��q���^��O/�
S3�gUV/"t�\g͉�w����b�z�0�;S��_ƣR�V~<��ͩ�м�ؘ�9e��G"�690�Q}OnwV��?B���0�#�dNy:���&�)�a� o��1�Ud.݀c�q�A�ǚ?��}����v(�4唫$9xx1y��*�=D�A���n�(�d�A�Ӂ���j��X��)�Fc8ׅ��E8X��G��ɵ�C��6
�V��+��$s+��R8<�f��(4+�	+�kF�P��EV�u��9�]}%y-���Wx�#��^t3NJ���M��H�>P���4�LZ��ik���E���
PE�1\��.^qIt��B��7x��Gku�6��*CD����sO��"��hA���ZUZ�_���z�}Zӡ�E
���ElJ<rM���C���n�W�y�������?��HZ@ȅia.��N`NG��G3۪��u��#�A�N�t¥�����$�-�����w{;���߰T12��*���k��d��ә*鞤u�*�G��C�
�����tn2a�$\9�^y78I�L����F��*%���Ni����y7Ғ�ɑ�R���rfaQKq��^�a��cT�SƤ�����Ф/�M��=�}��	�Ңdh�Aצsk#=���u�*�m�[�`XQ�S~0�oU6�S�3��X�`.��r�bꥨ��X���6R�|��Bd�ғȽ^=�����h~d�5�F ���Tlb �I?ɂϞq��s����p�����Mc� ����I��J����4Xx��3%��ۜ ?��ou�d��ѭK�|��,�������
@��(�-0c7�ʔ�eZ�iu	���g�;uߖm>�\�ӂ,0.wT8��E]��j����qF2��(aֵ�M�T��FF�31E��sGN�B��kr�Ͳ�2��#5�ʺ:��(���n4��|��D��ꆠ�i�[z����ιV�U|
��a"	���b ��k�-��9�=7�FN��P��7�v6M<�o�C�֩a���*�fu��ܯ@�U��|1�9���+�K?>���V��z�Uȅ�ӝ�v���w�̄N�8�X��w�K?�VG#�������ĺ����P/\�qI�9{�U�0p>��눕�oYE��
��PU���lD;'iM��~B 5d �t�D7Q2����J��wڼ��E�tP�8A�A��v�!b��<�¾�a����sA�b��������5z�F�� ,#L<ܥ^N��>���4���6L��&H�k��݊������QLW��w8u.	sJ���������}�B��$���?�Uj�3e�=���}ؾ����'T�C�T�V5�M�PDэ=�V��ׇ���(1!�����1�s�z�^����؛b�tE�k��=X:��z|����t�l�
�)�N| R��j������^��$Z8N	Vq1p���t�<���Y���g����+znn�'��X������T��$�	��G�����H�1'�?���?mf��l<nn,�?���w�������g���~^�X�F(wQ�
�3Ђ�h�'_(�{y�h���9��'��DGn��qs��_0�{h&Բc�~�i>�KG}Kn��:�q���e�*2~�8�h8`¬�I6�<kleU�	���Ihh�!���9�N�Y'z�:W�h)N��e;��c�	�>�Ixt�D)OBAvw�D\GnW`�M̲�Ҫr��z}�~�Gn��,HX�����YL˿�W������2j0/a�F)T�J*��sHZm1qM���xA�\#�����R�{v���FK�űI�l2���f�z��dn��fv�"E^�� ����K�1��{8��n;޺��D��ON���S�d°4C���:<�9��+^����my�4�aiV�<�U�9�%^�h�����Cb������4�#��q����ːM�x(�Vk�UVQ�ͪph��5}��s�/��S�8u�I�2�
tD�"hՌ���ˁ>G�T�L$W�#�Y�T�d�II���M��Ҹ�-@&Ê��k�W|*MmHF�h)1��w~�}��rPM4Τ�o��jN��q����v�p�dﻶ���v>�$�WX^�b�Qg��
�4�ֽuD���t�%�\��hMq��V��E���b��ibIj(�o��^[7���P�������Ɠ��H��خx�������u�[&:�x���g:	f��I��gU�?N:o�ҷ+��̊���{/�c�rK�,��LZ7ż�����t��������̈́
nU������@=匦�H''���!�R�khm�j?��ro��& ��uѤ�-f̬���GV�a?�>��.sm�Ie� �-��'����sxt�|<=��&��ڀ& ����� ߡjjx���{(DO��|��{G�CD�ӱz���1��y����x��^�����B96���+[�������}Q�;%0��0��p��pF��d]�jy|]}�
����xH��Xб����~�H�~�M�����ϼx�?�B����]G	��|��׷��_SRH2cJ1��e%Eņ�R�F��"[ �]p��)*��f5��Ӑ9����(Fqk��h>ljY�@�:8�Z� ����I8��6#����B�;�]���
�o:��n��t��4��] @f(����a�Q�MM��R4��m�k�Lj�LYr,;�Ǯ��C3ę�S<�U2��V��?.k���a�M��^�������)���o0CĚ��P�C��<g�t�ifM�jH�Nd�Ā)R8"�c����C[��=� yv��5:��-���m�'E�J�?�U7#4��,��a�'QT��.~� �?��L�z%��j��Xy���9�~�0Zj'�2/�m4{:;蜭i�;E��͞�b˲�;�mkuT��^v���P{�p����$��� .�X�AN�A���#?����O�3
�C}m��U1�G��uM]�ؐN���sM�m�A*s� �&�JF��l���~K7�*<���E3Ş����*�%������GĆ��W��n��������+X�:��8�]s�(�
��Z�K����ի64]�փ�Ý7�N����V�[X�m�e�c�-h����-��}�l��vf�sj�G V�^�6����FK���v+�/�������V��m��-�9k��Ot!�`�_t�=1�4%/.(�������D�٣ݪ��P&�W�V:���N�]�<=C0�k����^A��AA9�d�`P;�YJ)jut�� ���4M��*Ae֙����5Ktg�qf���k6��(�(�J���Ҝ�	�=�����f��>
����R��������+Sh�\��x��Ж�x4w�j�LL
,l���v�#;��@.�x��/b�8�~-�K�1)hN�(S��<3*�;{�EޗyЛ�	���F�C����kK�/\�^�V���GW�}A�Y�d��Yy�x���0֌��aY8�fa^0��7��ų�9_Dl�h�����qFd�
b�`zC����bԇh2qD8���W>���YMv�->��y�д�}�(sȉ�O��j窀F�l-��h^&�m%U�*�[�n�*qc������89��KS}�Q�d���i�Q+�p��-������^�<n�	#5Y3+�-\k��Z�V��f��Hl1N�RϤ�~����	�	C	c/D��x�-%ӕ
3v�� �
T�+gv��!O�s��;�m��Zge�&~�WR���W��qc�&��3
B��&�d35�a`�y�-���+��>Ʌ؀���`�sU7��	x�W���],���Ɍ�&g�ҘMv��+hېN1=B�,�5Y�K6��|!�^BZ�A0|��0����6�*|�{�E�I��h(����c�7�������`b$V�Љ�y���-7'���茤�2[͸�f��E��L�l,j�@��⬛��Bq�ܨ�� ��͝�4����77`O�3��Ԙcka͔l������`�l�P�N�@1��,�CHɌ�L���V�<G��U��{�wx����1|l��)���$��9��Ul�2�"=�Sm$�*���9��t[�T�j���c��+�H$��@�s�)��5ך�Ǯ-��a8���v��C��D ��Lcһ�JO���	k0�֒��-�8Ϳi4"賓�N�;wn�6մ4:lK�8��F���}��$�V��t������<@�ҥ����\}a5�q�A`�fĊ�Է/�H�p/̜i�7C ����}���� y�nc��:sE�
��G��y0���LrD���!GD� l,�1z7Ų�n��c��Rs�%��ԝ�J��či�o�k�����qu��|4�ۻ&V���D�{��"t�����9k���{�>q�Q�8����u����޾@�-,�� g\�[��Ӄ�nz�8��%8|k.y���y0�
#-��؋��I�+H`Q/������Z"͡�`�u�e!�m�(.48��ۻ�lL{Df�X����L�I�.4�f��'�٨_)�b�V�Xޖ7@�#?�*��Ue�\*s�|�Vƙi�uِ!G�U�\�hfdHY��DL`��J����~f�q�N�~dh���vnv
�I���Y[�����x����J�f��^%��g� ��O� �6�3�7X���U��K�&���r�b�/8~��'Uvz�鞰�c;CMp���F�{�����q^��xxC+¤	��<�|��BY2��8�u!ཚ�-聶�>e�/J�,Q�Y���Y?��i��Vٳ����뱦��J��j���s��J�1e9���`0�Ŝ�L�|��
��x��2.��'�+����Y�5��Oq�?Ћ�	��j��u�Eh�c��W��+}�����)���(g�HD<;#Oe�7k���'�\��N���[�����5V�
y�_�C)���FA1Lā���,,SDU.ˡ�eIG^�XMm�Q�Y�/��u4c�(�`�Ԩ���������z��#L�]gih
3��I��`��G�3���=1�d��\ w�`L+��)e����k�#q��bb`0� �=r�@��K�[B(�(!A0 �H$� 1N�!e��[A�Rܧ�.0�ʲ2*�"қo�_)S���6�F��A�,}���?�?ZdC��#/�5��{�Ƞ��G�� Ņ�3lx�'c7�^��=��v�,���[�g\�Ү.����9ic8',�nז�L[n٘My?U�k�����0sZ����m�G��0W���8���B�^�X���ί�����Nm�h�ѧX��Rq�~�v�g����M`Ŋ$&D�%Yӫ%���[�Q����ӱ����frMgP
��)h���dO�W��Tz��5�ؑ]��ݪJ �]�v��( �����}����ʡ	$>��~x)YSkߣ��.�|ˋ�l�Q��r�+�v��1�f,��L�s]�[�]ZZ�Jwc�I���N�s&������ r/�ds��G�3L�3m��f��_���2[�oP��_��0���ĵ*E�C�޳��[%�fo/<��c�.8�g����(���[J��d���
�Z�Ug�S}avG���djZd9jfF'���s�f>���~K3ײ8}�k�8�ė?�MVG?觎��أg���u'��E��wj֧ݝo�yz����i��ś*��M�u3�=]�3Lo*/��x���Io��	��;8�m�������g~�Gj��op��mD^��,%��&5�sj\�EBV�}؉9�7�p���aZV2C)��#�Dt��Vʗ����7�6l�!����猜�9�;�Q��F$�a6B�QvW.�vl�B9#�IYHexQࡱ;;@�w�x��d?�,q���*�y�l�;l'����X�Jgd�c�)8��d�ؘe^�.��0N^����S�v�|�#�[�`�P�6�?K��������\����K��%��m�ߊ����(n|�'
�M�)^g���bK��]__׮�+/��d��v�p��w1�O��V%�JQv8�B{ê��E_�#�I�Vڞ�5�D�)"��W1?a�;:8��F�<�%���a����n�-}}�߉SƜ�)��C W�>�]��o�p)E�^��y� �@�)���.��GW���W�x����O��bՇ�G͎T��i\�S���2�.T�";�&R`72�� �Ϫ�YI��|��[��o_�#뙱�S�|X�Q���?����Or����������sÆ�y��Ǡ��L_�z�'�r����_&�[*"(Z�2�I\ËAzI�H��k]O����!������ ���ĊV7�9��F/��]�$��0	.n�����(�C���*j���.��ܿBy2�%�{*�p��)q�f�]zʝ�����#�s�r�}x����[������y�!��}�����~�}���9�A߃nK߻���rf!�Kױ
\Z"��߷�_!-0|3���ɜ�V��9'��Yr���~D���8���h+=�<tJ�٣�Κ�[�E��c��,y(`׾�d�����X�Im}��ts/�e_p��Lwxi}J�C$�@���L��ݖ{9F�U�Z���&@C�S5�
e���z�Z׳�`����-��p���s�~+�����G����yE�"�\�F�[�b������1���Kdʢ*b��k����Dk�m�y��Oj��W�^�`�Ӥ��F��̱@���m N�E�Y�R���{ 7���$�͍���_?�n%R��L�����z��jE�g�z�۵E�u�	NG+��h܇gOzO6sm#ߘ�fV>Q�� ���	��֨5\'�3��]���g���yc�̙�˼a:R[�MP$�[e�V�O1�
��8�5�uG�Y�Um���t{��>s,������,�|��3�Ա�~r�UY�v��ެ�Ȝ}f7����	�;W��9�C�/����@%�����(b�ˬ�@A����٣�ԑҽ�2H�M�ic�i4��3�Ld&��wBT���ߞQF�LD3]oo�-S̀�G�iTR��Wc!�������M�'�D�����i�Q���O�m���E������z�Д �F��}9h���N�Fz;�U�&��"�X+�,��$��K���6k�}��B��Z�W͡ڠ�%I�a��懍}�Ue,��P��߭8��y:�D�7���CZG�Qt�Ǜ"\t���_�"J�hH���SR��^]�����pt�6k��JPF��>�j����i��S�b���E�7T�	o�PrOe)JE���O�9#F=��.�E|�9�����$6�s��γ'��-W�pSm���^?��{�X��_��BTr�3���i��B���#���3�}��MY0�+^�Q�|��aRǎ�Q�j\��|�A�!�ES�w׳ͅ�F�9p���ť�=�"y&��iJ���	輓4n
#K�AS��=�k���Hb�8�T~��g5�YrӶ8aje����t�uA�>V(���FE<}�Zy���T�Oha}��)�LD\u@W���7�]��V�֣��S�e��x�i������ٕ5��5�[�p�8��B�+hН�֬Z�'6�S-����6��I#9��y.a�L.&��âj��{@�g��r�n�����o��i���y����d�3M�ܩ�����E�(�P/���Ƌ�PM�{���	�c��~���}����ݣ�8�wz[��C��brc,s�e��|4p<{4�W8Z���Fu�_�w~����J����$�p>���� 
����˰����ĉ��%�7���UY���i��~�箓�жܑ?�"B���W\��F�{����zC���a:����+�ܽ�9���j��.��<m#e��ܙ��%�g�2!�0���"}�C�I���*���Uѳ�
�M����І�n��/��*��v���=�b�����ޱ���rXO�p�ɶ�y�x�^��!��;���;�1޾wT7k_�'��S��S)	���a&m座�8�7mhf�{/�bQ�ݺ��J���sMs��/xhK�Y�
��U��F��Ф1�ͩQz^�k ��e[q�<��p_�}?� ;�r}���B_��@N�_���U�[�ؾe�,%�Ҋ?_ Y��|۳�BV��d_����h�?���!w�ݬm��p��nN�����dӡ��%v<�TCDd04~m�'0׹A�-��.����\'���F�'��vu�mѝ�����al��j�G�q.b�_���i��Y�ݽ��� �B� ᅰ��X�|��q�}��*���,	�_�Y��z��`�c�]O�������$�W�f>Ũ���T!�	�z�*f~$2>���-{ ;?��?e-�>�f�&3�5���L�
R �1�:��̯N3�)��$d?M�D��R��"��N����I6˻�!��10�`k�[C�A�)��v\�P�,����!+%�!F��@_(�BΚ��8��	���sku~�q͙�]�B��0h|���g�#�V�2k%��[y�³o����Q�DK-�����Ӄ��Nv���6��̵d�18+�k�'���u��c�qڗ�0�:Tݼ��'{y�@7pz���j�E���Ә�H&*:�#�� f
��&�#DH�s��3x ���?����P�Ct¼ѳ�"D��T_�d�-{��\�_������66?���n<]�-����� L��w������&c�*�"��\�%4�p�>�'u4^��g��X��O�]��'��|��-�e3lI�E2 lz8��hC�#�H#����ah�W�*u�KX.�:�q�?ꦸ։���|)�L�s0i�����?'�d�Ho^�Ȼ�=&U@�$4+�3��䃥R�AO2:'H�ԟs<g����h9���������L����'귲��O	K����b�V���Qo��� ��Ӟ��b7�=�%"6��iQ�՘�V8�jte�ѰE�"�ɡ��M�u�)���=��;}t�V+s�D��9��ł�$Jˁ،X�2N�|/b^]`�\����d�[���.PL�QQs�d<�����|���`U.�TZ���	(�tm��\^��UT�VE�+h�'�`����cȢ>�'���'Dń
��<�jM��6�My��9�j|����=af�L6�Hb��ȧ��;Θ��	ï]o�nQ�'�-;�%���N�%�}I	{4)Y��̀v%�����1v�P�O�=x�W���+�ik'C�qMw��Bk�S�iQbNc����g^0Igr����fW�S`�a��&`=�Û	T����G�o��ķ��-�ɺ�j~♀t���N�6����k�����b�=sbf�)T���@�z�2/�E>M8�=�D����;$p�G��ys�k3	-PCs �*(��ۅ�q<H0��⫦B�������E�֝^�խ�S.����Q��il��l܆�
aSU�3π;�W�i���;���.uP6�w�[���Ǥ$��ȼ�K��}���AB����>����1�̳UEm�?���p��Ȉ�� �6����J�J9};6�����<�A6��il*ڰ$���.=Tm�s'YzfK��������)6Q�^��P����gJ�'�x�TK%�W̋��C`��s�����"���C�g��Y$�p�C+��ڥ�^4�ӃߥcZ b�Zca谦�̢	�@��>{��8�
9��·_~�����k���mg"�n�D\�gp}"�c�w0UG�3�ƲJ�U6Y�I6\������{?�&�]��"��D��!� �c�	'ޘBB�уp?rDD���a�P`M(��{�(��_��6"��60��6SM
��X"��9u�f��umχ�2i� �,yGm���z�"�.QG���D��d�b�l=��Ř�5@�Q���ʹp7�n�b�nl[����Er��eAdѧ�l�b��y'a:�H9c��̩�"s���� 7�`'dѴD�q?k/T'����4���ˠvYpϵ�f�E�t�F|��m/�芅��.��B˪15m���]:i�>����Co�_"�Е7��6MP��+G �W � %�o�+���Ό��*%*��5��cQ	M�$��+.o��E�E<�x�\Y�ݖ��P�{}� ���a?��:���'��i4�4��=^���� �_M'�����?�77�O3��x�������L �.��<��pJ�-{�^X�F��yސZ��}rxQ%׷>� h��J�تrϒ��5�>s�3Y��}�w��Z֡+���B�x^�^�s�4����I�X����x��f�i��i��p�_��V���W�x�yÚ��q��K4�Q8b��z�Z- n�`�IȂY�A[NI6�����"	$>�^�+S�ɒ�� �C7R�>F�E~�u�bF�Rj����%��~� �;��U��mZ��`I��Q=�z��댮�W�#~W $��KR�@�$�dk�&��U���*�R�W_����ZPJیl�9h��'��}��g�6@�>	biӌ��\����[~nu��X~>���Ӎ�K���������o�o4��_�=-��/2�g.��tcCa��1W;��dܞ1ͪ����5���P����h�jD�K�uj�o���A�1M5�T�$�S�����qw�똭9���=�x�5Eg��'\��gc�d��l��ix��&�q�Nߴ�Y�lU��zƏ��.2��ܑ�XG�ɺ����mw_u�������.��a0�э��p��<±@����Y��G��3�X���0m�+�:�J� O��dߓ;$5T���Ћ	y��5%�w2�d���C�t3x+��)Ͷ���
�2����IO���dƐa�|=�39���9�z%������%�qu�$�9C��嗷"��L6Ir���5�4��ٖϑ����T��&�m��b�]]�B[Lk���i�g4B<�6PX
�T��7�p[��7�DWy�N�	�b%�[㭇xo��-�Z��F[�)�֊|�1x�u����j�M�k,J��� ���II��З��\��v�PX�Gp/�q���vz��Q��B���A/�5��.LFpiBh�5g�A�����̕�2��?����<���ic��}��+>��P�p|�F!���'���C��'*T�%�0D�,���&�;�������!
�����OC��[�ܩC��n�Ue .����O�8/�nx=�� %��[!O~D�bT`:�St/fH!��'��&׋�Y ��y��I�&̉U/B�O��M�1��0&�L�P�<��:��l�&7����(��V��]�Ĕ��1d�5������3.����M?������a����������u�<`�ێ�`��Bp���]�^B�p��ϧ���"j�sE�y�P�W��jh>y��5� H�(W�a���~*L�M��L��CX��+�8��� `!'��/y�#Ʊ�R>A�x��=�wL��ȤΩS�m�ч��l�Q���:�t2o �1]�b=��)�	���6e��hAHu��)_'"I�����[@C�{�}Or9���=��	�]��μ> �yy0�{&j.'�az��H^���P��i�����u�I�gʳ��2���l8���T�U�3�ē���&$��Rj�EsjӘ��Ib�2<󉸋�E����Q���5���gA��3
f~�3u<O���p�R�LS��bQ��H��T���x�D���bbu�O�wq�C������;?�mD�<�P�*�bMo��
�j��L�#�s���@���2\�N���i]����Am�|��k�/�h���;�H��~�ݢ4>�H9��4 �pʰu�f���O	�6�Yh�8S�76gp��8���F�?lsaF���a�um&,<N��0�1d���.�l2آ��u#�@��;p�e����u�1{z��{:V�(��`�v ��%�&حhd�Bę���o�oa�os�i����|���}��Ç_���ɶ����6��C�)�X>O����*�E2�L�:�Ç�F�o�����i&��)���f�e���;>����e�q�$}��X��E���7B���Y۝�4�R�i��^��u�2�N�ޘ�k	�&�^��������4GL|�S��Q��y�{T��B7��c������$Y�����i
��3�̔EP�
4�E�*��`���@c[T�m�43ԸL��є��B].[+���z��������I��1����P�3MQ�b����H�@f&Y��Jv>���YvQdLIp��g���rQv	�uQOf�.��h�g+�9�o���n�ꞧ��5�J�n�T����-�܂�����3�����<�����O֗�����%��h��T���Q�☕坙+n������y7�}�/��0���h��4�{
�,���-wϕ��#�?$3"��U�4�g�$��{ý��χ���;�݃6L{������T�H�dB���q��[��K^RJ+���-�QQ�#�pa6ԙ��ҋ��|��Պ��(��_w�}�vt�h5J$��{�D�(K�i���
����a�DI�Ư��I�h���Q�u�%X]��`C.&}U��`���(��$�I����ϣ�x@ܺ��=��>������o �H?~�D�A
�M̂GA@/�-̽������C�@�'0~b�ӳP�*~=�y%`q�o�M4&[k���J�A5C��rB��
Q�j`u��HM��Zb4�i��fB�w	� ~`HfSQ���>��F;n"���TPT�	���R�~�#�9� ?����I<՛�ӺX��T��!�.��5�n���̾E��m#��D�Sqb�?�`L��	2jB��1~aTf�����0��;���U�a��W�H\54I�N�W�m<3�h�&�9-Z�F����,?����,?����,?����,?����,?����,?����,?����,?����,?�������_��v� � 