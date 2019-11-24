#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3237766929"
MD5="974250e6bde59c3eff2dec87251c6de7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20447"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 17:37:13 -03 2019
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
	echo OLDUSIZE=124
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
� ���]�<�v�6��+>J��qZ�����e�*�쨱-]IN�Mrt(�S$� e�^��?���bw�HQ��6ٽ{����|t]��?�y���ߍ�;�w�y��������~���h��������<����f@�#�t��;����?���9��Mל��_���[�;�����j<"_������c���&;W����T��k/h�l˴(�R��C��z�(����37���J��E�{d0��;��������KD�{d��U�R�0b�46�Ǝ����Z(��"��U�v�،�foJB�x���͓W0=���9�	48�$����4 S/ *��:��.��Sg���B�|h?h?;;26��f�h`��'jҀ���G����y|l,�,h.��������g����������j���Ѱ;j�����2z�<7T��B����� �����NB/�.��9��=%o��V�:�kŵ���>T���a0���
��ƪ����9;��(S[Y��Znp	�
�a. �x��j��QP��7��	l�2��t��e��o�RIx��s_�C�'�;^!�H0_����	[�trA c��/ĞE�G�t>��Q8��A��(P*3$:'�,�"�����a�o��g�[t�����T��D�1�F����ʲ�5�����}�3Ƨu�e/H@��)4�*���C۵��&����B�PZ�Z��STNP:M#k�:W��/]O�귤
�s`1	=�2��`�l�VO(o���＃ *d>MQf4|��:9��d
8�42M�,�a-�M�+5���y���v=��Ԍ�p]�f�üS���O-Q�ړT�d���i�=ϱA^ء��/���_�+:!�]��Πw��ը�?�����y��B[��|:}�����lE�ra��P�v��+;$�z]��i�~���ȝ�B���q�|�����p�\��J%��D25)+qS,���J���1&vn�nJ��O��C=�{^Xp�J%��X`�X��}uj��y�<�U���dvFA�	Wd�"�@X '�÷�&m,y���:�/�� �U�����no���67�����Ow���_��ܻD�1��I{J�A�>x>��x�&+��T���G>�{n�0v1]�W���� ��$/����_L�� ��3r�������]���F���g���*>��a�M����Is����W��v����2��GI0ҋ�ܼ�6/�E!�96�����M2I�}2�,{jCN���Ɣ8����r~�Q��#�#�D�R���>�41ڢ�=�1,d0�ܹ��ʨ3%f0��xF��7
�����D�t�G���g{���۞�e�
JV?�����[�"V�,��M����L��xej6g2�x�C�3u�V#8������,����q`��*I��K�f��F��������	^�qd;��������K�k���Z����C��ZU�/
�� rA��sCRA4�����Q�<� �(�~�
����S��f��z�����k�m}!ǮT-�IhB��;��<byd�O�4δL�z��"Xo4�,�����66��Js>���� ��ºsE�8���f�h
0j��J��XD�.ױ<̰����ya��z6��0"��� L+�X���rq��2^v���Îm7�"'C�ƏI�9QRr[���F�Y�x5�$"c�>(Dv�8u/�a�\�Cs��:��F�U�XFǝg�^s��P���c�q ��J`�ãy '�>�Ί(���vs�6�;'~��:�S#^���k�H5�:�������%m߹$����$Y���#�4E���Һ���HAi�ʋ�a��S�?��@���K�������?�4
3��.x��hN�������?{��+On� 7��Lm�E�h���/�x9Hj�%�^�^��O�*^�+鮄���K�u���=9Gn�/@U4�z\)Wk�A*1��.���c.rT[5���z�2�_�*�x���ɸ�B�K+$���BY��$<B'���g�/Hjȇ8
��9�r Y�6��\������j7Km߾՞��P�G11؟;���t��sz�z��{����M�Nay, �0^��G��8��x[����X�����.���S��Y^�m	6<ڈ��Z@DU���n�)Or�j�+@Bc��^PY=
��X��x�0�	W�g���8���)���hvn��P�[�R��Jkd��x�i���$�e�ꝍ���Q{h�`����j���*��~Q�V�;��P/�6�֚�<��RI"|�~�������.T�rcp�P�qK�"��N�$�ݳ~�-8*ix�+�赢`���|���������t�}r��}d�y:�5�p����{{h.�/�#���I����S�9��O�Ƿ*Vˆ�+�J%K,|5=6��j���:M��t%T%Y_��e �̾�
.gV����`��A���]օf09��.Շ����v�z`��K$?��������j����SѤ$�s4,%+ܔ{��m��r��qۇ$߳u���ɞ���9����m"w�&���������3�a`�\ْt�/4س(@H%noIm�U�����谋F�yz��vF��<�8�OB��l��KԠ�'�.�&q	��S��yx^2#$�/�mILaU�<�+���e�Je@QLz��Q�qڇͳ�!|�Զ^$	��Z�_zI�@R�A����{w��k��	��V������7A�F-\�V������\���m|������;�үf:s�������7�H���}�|�e�ء����Ao�b�.����Z��e�]R,``����3�0�&�T�J���Z�u<�����~�;a���@������9��_ f��9 ���t8����E�RO�̫L+�@oM����{w��{��YF	�)�{~\I�������C� 6̓g�wf��&!~`�ᔬΞ~�'��Fl�~O��a�ƶ^R��[h��e������N�mC���݅��~��g��� ���]#��Q*���q"?K�ih1�uބ40,�.���1C�xR�Ǫ\C(�6��/���P�S1�������d)(�+*���'WF�7_}#�E��Q�ύ�K��#DU.'�Kb�D�!`�3 [T������~�f<F��j��Nb�P�6H �Mi��<�y�xzm%? �����x7�9����Щ�J��օ�;f�j��Z��N&��q�4���'As�-��<�7p���@.��^N�v�G�(�Pݢ���*�5�0�o�Y#�G`�o���p�G�O>aL:kb�@�:�j����du��(���*h�#����P�0�ǶKm/2p`r&	ћ�w<�J�O��nԙ��&�`��Ȏ(��+46��PcA��{3�cK<4!�p-$�q�jJB�JT�:���XW�����c��<t~܄���%>6,ZnJ��"/6�Ž�"�*�g�%5P^�ſ{��~��-��ȭ�:.ؼb��D��c���;)���G�a /
 ey�՚�UzN���RX:�mi�s���R��Ubo�t5�	��τ�܇<����Z��e�#�EK��'b,���h��/A�3rM���	yu�^�G`&�a��/y���t��ϱ'e�B0`�(��k|�.3 �=~���T�X��f���l����kZx/"�K����1�̬+��ٽti�t�4�G���\�׷5ĐH_�P����l̥;>Q�����������e�=K�73���Xm� f0<���?�Kώ��'���T�S�8s�L��T��zS=/�ײ��)*��<*��������	y	F���$Q=����� 
�Ǐmcc���vS����ɻ�}���ց���'B/�~w+X�Q½�'���c�;�=Ų�e`�x#w�%2}�@���؛uD��2����ڐ#��.U-!��)�E�r�J�@N=�|�^���A^Y+?=Q;����=UE�㠽b�6�'�^p�|sBc���_ ngpq=������.ČI�i���[���Cs�������ͨ�ħ�l���1���g����=dPKM��@:#�x�|�&mj�Ca#����FQ,&��Y����;DI;�eSC��W{�_�Ё�+� ����ܻ� Vj�b],ajzW�;��:@�)n|S�BP� �"�ֽC�Dg&\d����[w�le}�+��{�w?/RgĿg99{)���@��Žu�˷`�yl �1ɖ��䜺���C���wmŒ��D7}�I�{H�����
r�G�7���A�rN����c��XX�򥜇N,��)��s���>�J�.-���m�����y���7�����w"wQO�95�-QSSoO�]������$w�Z(r7M	����&2*�'&�>�O��ʢ^��el;)A�	��<L��m�b<�
"6������i0�]�1�&h�h������-fC$e�cC���l���p!�8��?:� ��pq_�}\S�:i9&cEv��vr�Bz�W��C�ϟ�c�� Ú�'
�}���AV ��--E$D������gQ��1��*_�k�53Dmy�'ց:(��a������e2�뽽�ڋ��v
KY��UH�{7����A�!oxi:5��4��Zwk5|���<|M�Ht��V��nkt�>=u��$�/�)�s�!d'�]��q��v�4�s��ڃ�n�����ob��z�i�^�9u������-5-�k�]���5���"ۢ�=cGX-V�.E ϵ���y8w�hhR�2u6;�\�P��;e��l���L,?� �И��菰����=�6�~	��8H�A����4���F�� �����C�i 6(Q2��y,'�R��9�(�n�~��.y���L�Y�T�&���29��Y��D�^-�Lb��J�%{o.�$re���Z���\�N�v��O��7.��j` ��օf�-�I����~�U�s�s��I[h�Hs���/����8�cJ<3�s^�_P�t$o��@ɓ��*R��o������	`N�Tbck�~�	������uR%��x����?��ds���M��B���Ơ%�r⊷� tN�9�e���x�&E ���'��0�X&z�R�Y��	�_�`���13�-�$%�Q�� 4	���pi)���CRg�b.4^��aX&|�����%Blc)/���;�u`�g"t ����kKD~9N�f¥�[ ,ဆ�f�H��!�R�-���^|�bl$#������S��,�W�i5du���NqW�(Xt��im��Pu��)�=P<C!�L�wM�7��#�+ǵBgJ-�\<��Й��w�Wf�h렇`-s*��G?+�p���F�|�A�p.pZ5"�j���u�e�$�&^�)+�ewd��rR�QW7
�uu-�C���0>[��Z(���&���^�������#Ys^ٿ���1I�  uQ�J�d�y��g�t �@�j@c� %Z��;'�a_Ή}�}���KUuUw5 Ҵ�3������U����e2;W�p�_͓	�Y^��@T����?%�j�dx����`
�v5���Z��Qj��~���J&|�˖���W�OQ@�d�)!8�j98[-�Q)�G=�L���V�G4e)���1��M�	e?U�F��B��w�cXt�?�L��-!I�t7�Y �b(�}�T��h���J�r�Þ�3U����Ɯ��E�*����Q��9��ܮb0�͊�'�d�\����`�Z�/�+g:*;󲺺Q��Fh|c�ʂ�V��U�2�\%4�4�ݍ����X����j.Ѣ��gN�9�_7����kV��C�e3
��P�Q�:&�	唪I�z2��PW���F��S��B7#�q��Y��sp��hM��-R6��H3��E*+���"�����ᦋ#���q�;�� �����{5��a���;�O��0I�﫤W���ޏ..�_������F4��Wع�U��`�����`��{?���$��Q�Ӄ�4�:I~� Ԏ��Ф��������J��W��s���\¤'[�	.�X0����*��1	λW�$����;��;Ʋ��?�rL�LA8,�Á�UV:|<يhd�+���+��}�
*�BY�Y��GbB蛊�M�Y�x�=����f����������FT�_���@�e��?��c�G{����!R�$��}�~�I�cc�`H�h'���Ez2��,��ϣ������g�xn�,n��,V�I�FR)F_����"�Y
�t��bd!1�/+���g0�����C���u�yM	ʺ(�jm�bę�����E�.Jg5U�;�[�wIW��V�~F� 5~��ȇ�_������T��,�/���W��J�D��}�M�Nz��	���
��"3�Nþy<��4Ar��Iq�)};%������a�8�-��L�w� fk7R%���(�274:U�1�����J��HF��-��ImX������)U)�6�]F����[���Mv��jY'M͞!)�)dF,����P�/r���b 9y_,�^.�ɰ��I���Oo}pb�+�,��ܥ�ȝ�LDN���TĬ���*I��	4'@��&D�������}6� ~��m�9�Z!a��������36�F%+�|�T�B��n<�.��ǒ��ir>�Y��t�H-� x�ֳtz�!���/��t��c�]��8';����[�ˋ4L�F��%R~�y��Az�	F���V8����b�%,d�̨K���̐����c �'(NL;<\�$�"���A��+f�	�JGs�����i�����������m삖�����1�q��yc��"%��.������J>����l���@��Ojg�r*�V���oi��n�K$��mh�̎�VG���͑mrdY)����Fwcn��6��3y�7F�s�_]dt��l#t˼�V���죴�Qf�Ts�\W�_8SЖ�s5����,��?x��X�u�TI�����,�&bwn!�����L1�&7/_�%U3o�N?���a��E���r �r�:�e� ~����/X��=XP���O���)�1�m�cV��S|�sG�X+b!9j��oGC�䅑(�ϐހ�0F��r$�1=[��:V�/'aCӜڊ�XC���&X+c 2�ٺ������w-�׏�K���u�ms
�Jɶ�Sy��H�T*q���eB���]o��������4�)�W�A_?n���Z���j&��� ��Y���� ��$7*p�,pI0�؆��|���^Dh㺲�?,��[z��D��s�(x�O:!]3"�<!�������`
��t�ԯ�mU���΢��H�K�o�*;2
�KY!�����W�:C�Pc�*3U��3�f�:F@�X�ӕU�����b�W_�5����_�n�p��}�d���ɛ�3�/��/x!���U4�G��D�'	����b�kK��Xc�̯���a�`njR9M�ͯ��/˒"D�Q0uYE{V��E��F�zQ�}15ݲc$�F��W�s�,z^B�x9�b�h`�]�#M����YU �d<���l�Z^S��|�K��0�g��	Jw� a�٘�ɂ<+���|N���uA嬔����|U3�k�+�����]�fq�5!-`�-p���XX�1�#s�
1��Tn#W���I��gL�g�S�'��5�� d�a�,�x�����4���t��%�'��֩إ�?^�
F��CND�k�|�70���#+[u������ꍭǛ9�_�������]��oպ���@��|�Fc��v{ ���H��s.�4LXm��
�|��]xi��|P.K+HV�e0޼����W;��۝��w���� ��ɧ�R�m���j�W����ۛ��v~��n�q��m�q��Wp����[:�����w"����
HVW��ZeR�-+��_N�u[i8#��fB���O��;�#�w�Aזģ��C7W�ao l����c��bH�v�+��D�����b�H:�&��>��9��{��9�/��(q ��A�Nm��ۈ�bn�@������Z{\`�l��3_��01����@��C��-?\��Ë�#�ښ�!�
Xo�:v�D�h�63%*��D^i:��༕��l��D��O/��pN�\=<:l�:��2����г]���^h0;�*�`ViN�X�|�C�v�.��
ֳP��+�Q��7�����L.�C	�~�H����G�G��і=����.�\+�u�TG���T���׽DF��"�� �P��B�'h����2�h FQYL{���I]{�Q��}Ί_�֕�?��Z�V��Mz�o���c��(�Rb�M>�a�%�}P�i����X��`�!��y�?�`0�58��>�f�UiT��G���䁄����M���$M*�~���v�;��Ο�T93��&*����`�BC���Y�3U�9I�h�sA�$C�
��j�,�\�L�I�C0��H���H��Oc�Sr�t��r�����d6H͜�:}b(e���2����OP�^	��W1�]���7��k�@ɣ%�J�R�,M�R,��t��9��,׷�o��aE��|Z�o�7u����\�`-�*��q�:R�@�%k	D����1�<L2̐�D��:��}d��=N#�ўIy���4{�칐7,:w��0�	�	�_��47L�a� �9�^*�1��qn&���Fmsr����l�)ǘZ�^��Hd��S �;�嶂��%�el�J�2�r��0��d����ѭ��ʶx J��dA��;*$�tQ��:�x-�!�He3%̺~3�L�I��h=#�����3�x��њ�j���J��H��^���F�h���������	z��ɦe�b)�7eK-��ѫ1V�)V;��j�p�}t��h��%Tǹg����p� �e�.�������4���� fMcLz<�7�tE${�>�<��Fdx���s]��_��٨�-X��jI��W.���L���"&'#tr'�~�u�^Sp�������a*8��~B��Ϻ`�'��T���D������+�:T���r%-�,#�9F8��6
�C���0O����Z z��︷2	�~�j�\gv��ܐ�I�̶���w2zܕ���O������{��a��-��;��2�L�h���.�By���]��� ��#�r�U�WV���=��Щ	�9o<Ҥp����I�}>C*z@ƒT�*�@*�7�P����<E�����M�B����ce�ǣK|Y��
R��H(?ı�yx����q6L2_�����W�<�Q㿲�9�w��{�/[�FF���xs�^����N�K�nI�K:zy�|}[��eA��K�p�b�|!�ޥ�$DU1��kH�l�Hv��~�\47��wQM��ƴM��|�.9�9r�V��y���˖�g��p�Ѡ/�Z�P�'YV�ʪL.TH斠��ц���]s@�e��#׹�'GqT,�ٴ[m��L�=0��+�!���/�#�׏ߕ��CD�,=niU9{K�>j��"3WJ$*W�EJ:e�#��_G��4L��E���sK0K�PJ	T�j*�3F]>Q�=��S-Wؚ|M%i��-�����,�c��d���z��da��f~�2E^��/���i0�%�ג�h���t�MUU�����v�H�-�/�Yh�zux�}{��+^�(1鶺�Xΐ-@v|T�<%F2�;l0?�pq�`�?����Vi�O���AjV5z�4tIRQyRj���Z��RT�����us��B{���FG F��$F�*Z4�*�|�Q0ң����|�
��3M[ B�DI��G�VR�-^��J��[�(^��E0$��)1���wa�}��?PM4��@�0/�J'��X�wg���>�9�����b��F�:�Ս�֪ȡ�9t�ڬ��fa����@�'�j!��X��T8���+m%�/�Xҕs06��F��������YO}@G�nx�����8�q�!;+��2��9sZ-��
��;����4v�=�Y��W}L��|nx�U�}��[na�$f	����^������l��fY�t���)���d���1�vRE�����Sȫ����+  �R�F�_(o�h�:+�������v�}�@_���|C���9��c_�)=��F��J2B�~�8FX��ˏ����7���E�*`̄�	P�y�O�1������8|�ޥeu*�ųQ�"�ڄ�8D�=�p�%F�C�K��Q��H�H�ɛ���Ċp2t�ێA���[���vp��9#���`�d�R%%H��Je<�\�z����<�8a���NF��$����3A��`6�zC�,Hv9���t�L�uq��闏�}s����Z�G�<)^4_�R�f8�ui����%�ׇ�4E�9>�Z�!B�R	�R_*�hN�CD"�'��.��Z�\@%&?u��x�{�T\bY���I�i�&���v���r�L�.� (�܋���{�S˺C�h������+)n��O����E I��Y��������t�vV��^��m��|w�%� ����f���P�5��J̀��	'�sl�*{)�ۂ�"�Α�v~vVe)幒d.5���4�09�m�rHO0|����eI��Mm4e���4�!���\�IV+��g�~h��;@ƛ��fOo�Y*�[f9��K�j�d��Ǟܙ\<��"K����ޫ���p�[6�M�1,>��i�L�gQ1�zp �c���I����1��5�b�i��Z`�O�%�W�Y[�K��V��pYWQ���N�cR8_�-�f9m�75�n�y��̪�4S���.��Q��:�[����{�:�:0�흃\�X��^8Jh��]r�A@�0
M��~t� �:*_L�M��`�p�m��}}�kT�=��6����4������Jv 9{s�nH�Zc'��߫��Y�1m%pT\Z5�n55��t��L���َN��a����D�R�]n����������p%D ��O�+P�fvi7+�<����vk���iժ���zB��F4�]�+(~�/(�^��N���u��9� ���4@��jYj���ώ�o���ǹ���hfЎ�E&�h�Ҧr��Gg����J�%
ø��#Pj�/X�`*Ox;l�MM�O��
����ƫc�ʠ�K�Xg� ����ɱ�>��ى`'�A4@Gw�T�x�Gb
�H� �H	(S�"�9�/��|�w�Ko['���"CC!o��&��p���h�����!�����x�R�x�nuF�X7R��e����� ����,��ύ��D,�Px���>��j_��Lo	ݳ�\�)��汰��'o(�d)oy���x)��)1*�ӧOE�}U0F�ݢ�p.�E��q�s��W��u�V�{�]�6��L�K��?�B����TVd,G�T��B��i�vxU��QXA�F=�ͭ��t���j�Z�6�1h�k�hJ�-��16�$
�.���P�(�QO6�!C˸Y��ǜ�&p��}����;o��'�9������%�Z!���"��E�^��5t;����?<j�NXpQ���/���$��,����%������� k �?^]�N`h��gvUa��l�e���/��A��9��k�yC��i����RcE0nSz��G�w{�b�.G��!��ܮ��d6��둕M��ޱ�&r��,���hl����L|ft]�y�w�Y��3�ee�n�mY˼�����5�pn��
4զn�)�l� �J��Ǥ�4>qO�Д�������t`v�D��":{o�O`gb�+�	����U>j!�[L,gw��!�&���R֕:��Z�-���+>/q��C�;�]\n��� �1��������	��%�A
�y�Q�b7\���W+�3)���_{�x\mT��DZ���m���e_�*pj
��T'�)wͧWW��@}U�sg�0�M�8�nnh�A0)���v.��ZtlXv��xQH��z&��lX��$�T�>"���y��3�K�{+�p����"��5+���#�+~ʿyI��w�Kڪ�s�Y�k��x�E�CM�� >����[�EU#��l	���L2	g-1�2dt��~�|ٻ�%�����E��[�KU�V����V����7�ǿž�60����t�7����l|��k��o�qܱ���։_�����|<���Ț�xu��/1X?�Ɨ�x��P�u=����̥�a#=&Ua�������3�h~���}��YPYk�hI��`���,h����I�9\�������΍�<��I������ym�H��v�-��4T嶼e�Y4T�4��V�6�J������ �܇˟�ˆt,�V/syu��!�t���@�.��'�1���,hC�Zba����,yj�ݢ~3M����m��V�6S��"ZQZ#��qM`���L���������7ۤ��}F����>�ƭVeL�������{��!�Y�ǎsYG��5��H�*̓p�1	�e�h}�z��x���!�5�7�ƪ��YV\�t���l!��~f�Xn��g�o�;01F����������0_�3��d�v��>-�i,�WD�Hj����Aoi�}ri��u�0�²�Cvr��J\�����"�!K��^����]�Z��a�`�aE��)3x&	i��P�`.PwM�qP�%���gPb-��;��.J&T a `���p�da��*}j��:���R1FV��Wv�h�˫�)��� ����[Aȸ��KE�YM���4��(n��PG�kt����H�7�bh�qHQͽ$0s� �)�$��-�\M�emR�Z�V?�M��^�e���UX��B��	�c_m�#vC�V0 �b(Jc�	sH���WP�� ��]79VF���v;���2U��m�Ik��l��t�{?�W������G�>���p̞?�Fqy�} v��'��O�x"�i���6mez�,�����nd��Ү.�[��9ic�VXA7k�V�-7l̖���ڍ��"^g�9��yي�6��bث���l���22��)�a~G��+�a�D��8���[%[�jN"3��� ���:#>�ޭ\�Ą(�-gz��xgBS5K2��t&��4�Z���������i�'	�+v޹��
�k��Q�d��ȧ]�@�����I���»��j���+�.��8���ԳM���>��	��J	���f���xhC�"pb#i{{[��1�U�1�e���2�&���^h澀З�����9A�>,^�����o��0e�δ����+�e�
NnP��[����R��w������g+E�do/<��b�.8���ߥ��,��A,%��@N���7v�0�'Y[y3�lr5s�w����k���:���~C-ے<}�k�8�N��M�YD��z�i=�|�QX�G�)���Ҁ7�z��/֢0Mr�M��`��A��MU��6�����B��0��e���;��>�2�G�-���أ�D��̗ky��`#�7+�F��J\�R2.o�vA��P���vb�p��'�?ǈ_C�0#��b%�#$�Dv���V��mD#��mu�-�˟v�!�HGx�ӒT��ф�9'/{N�NB�����{"�,m
;D�^����s1����%}%B(#�D��[��G~��0/���ب�Z�PT�μ`���c;�I@2���(u�A�9漂S�y�掕yz~�":���k��/wʸΘM��E�U��Bi� �U��<}�� ��o���ԟ�����������Oω���>�(~�KQR��mϕnއ�W�U�d��Oj}�)�:���µU�0X��*�޸���/�
��w��.m�ں��0�Ix%Fv�v�x���1"Q ����ڻ����k�N� �Y����.x��3F8 C��WnԒ�+A0���V*Z�dXB���2�<:��	��Y4���P�`(�B00���U���fl\�*����4ڑ�!.�7�hH��|�ʍrTk7���z���T����$�����F}�q����������_Oޅ�5��%1`�'�ub\!��e�e\���.�{�5���$U�֤Wp�`�׼	ЮWB�_�[(bܛ����&���¤Nl��G'{o�p��jy�(�FװW����4�WQ{��t����J����R!���i>_
����*�w��"v��������I�'�SwT����3o���&)��J3����i�mww�d.:M�}�s�/�^�H�s�=|Z"���Z��q,ּ����M�Ny�M%�lz6=�?�2��FQ8GX��$@��J�{��t�����C���{J���%�O�[b����x���� w�t�R��5�!�M���p��_�aWEKl|�0���Z��)�u �57�,ڙ�2�|��I\gvx�q�b�[5S��)pX?��ȃAAk����Hrv�99:�u���L٤� 2x�C	���	�Nchn5��!�Ӷ�����zA�]H��Ƃ�Z2~�s�����?
���,��.�S���8��5���3�{c��/�r�;z|0��v=�Ű~$��T�677���	��(qYjÆ&E�:&c�֜ԟ���n��?"�$��ϲq�=�>�ʵ��n�Yۙ�+x~�uՓj�Z������1혃�x�땐�h�d"�Z�XHu�X�ԭ��\m<�d�ܓP<�^!b���>�,Z�ZAw{����ʻ����<��͙�[j,H?Y�Wվ��U��(�����s�9���Uu��P�Sqi�D��~ZȄ�]$�Y�=�3�&�C�7\F�w�s�~�C�ƃ��$i��9��~��˪�w��KN�Fð�u�v[*��h�/�p�����Dʩ1 =rYx�u���J4Z�^x<�{S��)�b�3Fiy2z��8�F���|_Z��ݽ�ց�����ه}�ّEU�c~?�a��S����j�v;\��6W9z�3�ޭ���'�n��a�E�{]YK{j�8n�3pR���y5�	�H�5��E8���=
�z��E4��z���HY�k{��O�g"��qӬ��XT�ad�܄T����vkg�J�{�YOu]���OJ�)�,=R��|�D�`ƨ�t�e����]6'�rZ}$b�(=<�<{��n��k����9k��j��Y�x��GB��ȠӸ'b��J���G">��g����h7�i�G�L&�ܸLƨ^���0�g@�
A5���4�Lj��g�X8��j���b�o�<��B*��N3��tީ1nHU+�aԻ�0ź�$=�X"N&��_��z�Y�r�x����0��}��tw��6br�������@_�J�x}|��'TO?�ܔ�ĢKE�O7����o|tI�*��'ë��/�����z���&^�W׽��4L�l��mc��W�w>�3�Y��'6�SM46��+c~s_�'�8���$�_��9�� �bQ���=�WF�3\W�ٻǮ����l��״�5���,��8�V�5ۋ���}��$D�~Sm��4	߻w?��8�ڭ��?�ow�{�{t<�v�b+|��mT�Z]�Ӟ�<�睚��c`������+��
�����{ج�/�x����#�D���~����i��i2U߃�{#��]��j�s�r0�n��(��R��?G3D�������b�O/p��I1D�`\��hL��20����%�#��P�RY�\�h)	F�V�L�}R�a#��d��@�t�!F���ea4���a����<�P̭&��/.�=�H������w;{p��\�3E�B6R!�v��y�.�7���<�����Ja���08�*[���ƓI�a��y�ɳP����c$�u���܉0Z�}�.�YiwsQM�i����mŝ!KV�����C��_��Rs�џ[h��VDS?�#����}���\an�2���9.���cK���q���*�|d����m�:�Y}���ڇ��^�v>��=#w�ݪn��p��nN�����dӡg���?��SD�u05auN��Y�����_�l��ؠ�	��O��/��Flѝ�L����#�J�K�q.b��T���4�֬��^�G|�C!m��B*޲��<�Xr=�����Uq6��_6,}�> \�����Uw[���Ǚ(� �|�@q:��z�J���U��(��j�6�}�������j����mj�֘��=i<�T��������=E�����Y2�z�T�RWk������w��\� �����`�[C�G�GZ�v\cGP��,�5��ji���n���QBWW��f��y��tB���|�������a��a:(-��gi`�#^+�3k%��[y��s�����Q��H-u�t�����V;�X� U�`i�Z��Z����j]U�o��c��Qڗ�x�u躹���xu�K���|�u߇�a�,!%���,�HDRg%J�7��)��Ĉ�r� ���h��?����l� -X���Q-+5�;i���������?���eM�e��뛏�6r��[��������n� h���t �0%� SN��bNZe_Dߛ_�������>��uc^�¸��
?{_,�S W6K��_&�$�G�u�qF�ɣ��ɲ�/	��%�������%	�ge�^�k�b�:)h���L�z�����6Үį�I����e�E�˨�E�\si ��҆С$�]Y)�)$�(If8âQڤP��v+��a�)L���'��V�Ч����T�zG>�+u�JY"����Q罏ViϿ�bÒ�e3��x� �j�*��<]T&Wv���K�##�71�Sj�f�1J���e�\+�_K#r�l%�/𱔖a-g��O����.�Q��2ס�G���ٵ�����BT��2vy�͔8߇]� Y�0�˛L�D�hZB��Wy��˻���C���ջ|�49TQ�k�q��	dausR8J�n���~	���x0��"o�q*$�2D��b��V�]<4@�	�_G+2
.j��S�	Õ�j���I,��A�F��MU`�O����E^�Q
�ۃ�;6	��	Gھ~����BWJ������%/�8X���:�r�ͭ�n��L�\�h.������4�DO�x�5l�`'����I��DK�����k��5�6P2�S����𝿮���Peh����H�����$u�H�"%�
�-lf-qib��Y�;������d
���L�'��{�������9�R��LvG�¹��$����}�UC�WaQx�OEr�N��ҏˈ�4<�}SB��Dl�٨'B�:� ���E���l��*� 6h��.(������!��NUd�Qc��>��D߼�9P$!0��D��U;D�?���x�?Hǐx �T:���K��Ix.��S!�A�����7ڮx��.Z=�m�u'Ezb+$��¶��)6Q����j�`X��~���OƠ��6�,��D�!��Ҵ�n�_h�Ώ��O!�W��[ƕw���HG�R�`2��·o�	-�s��}���n (��^���<���.��b^zh?���U����lk���Xlg�$o�D,w�x>��L�;�.�-�̢��-Q~���ݱcW���e:�`&����JF���$��I f#�O��Ð�s�~�I��uvy��i /{K�N�vNu�˶��̰�����&��A�{����fvA�m/���2E��w,yOo���z�"�^��b?�?������s�4��d��� #(��:7���Թ��=������-��I6sp��A���)��ۙ�2�"D6���� /�@=���p8m��^�N�����Ɣ�A�s`��f�E�t��"!�v���V肅w���B�*	5m���S4�%Z}P�:[8G|�Qx��XW� 6J�4���W�=鼠9�PR���X���(H�S�{��.�{,��>)$>�7b��Ѱ�(����+��m������V��q/���u,���O���^��;�����K�?����?��������o�;|����جg�7���_d��||���^W,�����6$�3�㳪ؙ]��3_���|�U�!�/C߫v��;-�֥9�I�qF���t���;{�n���3P�0��g�XVtv���~±?;�s/��J�L��R�Lč8}�YQV}�ҭ:��1+�a��
OoXV�q!��I���c���n�Qc=�u|���A4b�����P��<¹@�!^���G���7�Ѱ���iSY9�Y�2�6t@�*�;v�����e�KH�^HM��X���J!Vtrh���H��g��+ݙy��
����HN��f2k�0m�������LM(��cN�Q_��i="S����j�l
�#��_���L��PMJ�
����5�` +թp��P�ԥ��I:�bu��U�Q��d�KN�&Lq��m �~r�����K�of��1Ŀ��Ћgp%D�^�̯s��T�ܹ����gJ��2u;����[���'i3QP�0)	w=	�^(����D$��.`��NO�>j{Yh��>t�n����S�
����~w����G���t�&�a���mlm �����������d�f:���x��F�����F��"���x6�����)���)|�!�T=���{��<�<���f/�/���t�._���<Q�� |6��W^���=�SA�^� Pő��S��f����f�bN����������Ԁz����s�"���6a���ɻ5���e<�#W�6������������(���86�U3<I	*��Y%pZ}��'� �p5?'��h����M���@f~Q�V��f�O�݂	 �@R����qo���pi���7�GC�4M�Jݙ��<�ֳuZ"P�W�5 ��PW�	�S�1����� ����9J������Z����ft��T7�r�"$�CU�E��̕���H9_0�����] 	$ZPZ		p��P��?��y:�Pl	�F2Nk���fKm�$'��֘dq�ˀbЮҷ��#�iLF��0R=X��g�;?�ucFo=�P��b�l��m�	5QR!M_�yp�d H��r��>�zZ��}�|P�#�Ix3�/U����z�������n�o��K2��dj7��vSEߜ$p�i�͉v�3�n�C�3�oL��g��<p����Ap۩A	K��)�/Rc�&��˖���Ĵ�Yp���݁���gR�>&X�-���ӑ>�dh��b�ZO_��-����Zhp���q���]s�����O�f����ƽ���|>�jt�����Mt��΁���|���ֽB����(2�?|�y���V,�K_�'��!?�xf��Y�Q�B�x�P	�W�A�/�$y�ڧY����)�K���v�|"ͩE�Fs�hy����8u��{c��`H�%�|5߭�t�n{���.��8q5�D�� ���)�x愰$��eFI��5d'�LS l�[P�R�1{/,Т��%z*�/*�A���@b_T���9�1���D2J�_(���o��o�[	���5%�7:f!	��(�,�&@�Cʎ�Mѯv�z7�����A؃(���D��O=:�.ʌ�������:<FE#�h�'�����]����V|��A��C�|�O��:�F�V�*�-r�$����0����TP�{�ׁ�c�iV��q���=��e��GSZ}4�p*��Y8!Ge�()����%�$��Q��7��n��/�� ��"�	���`ۂb��x ������JHq��$$(ıX#NC�&�t�qox�w��\΋]�uZ�t˩hiH�|���ʜ�ڭ�݃���Rms�w���%���Q/�"�S�{K(�:/����s�Q�L@#�"%Մ��
�?o��F1�O��?;&"ґl5ʕ$�<E(�E������g�_�{XE�h�E�2�\�l��J�������*��DO��ȢOBd���Ox��=�=�	Y��q�\��q�D�C��=��DD���h)���{o��XGzа%ÔȉK�7	�Y��d�kUA?|��6uU�z�k1��䟎�1��FGK�4m���1����Br�\�O��Hă�)��%AO9!�jQjn�<_Ž~����s�����?�������s�����}�?2�N� h 