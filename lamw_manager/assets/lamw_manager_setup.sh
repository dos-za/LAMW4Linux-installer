#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2938265433"
MD5="04144f6c0e79505c40a977610369a983"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25576"
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
	echo Date of packaging: Mon Dec 13 14:08:52 -03 2021
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
�7zXZ  �ִF !   �X���c�] �}��1Dd]����P�t�D�"�cIz��;��'\v2� ;\ʼ�9�:,c-P׀�a�I����eE	.�o]+S+/7�
��y�-��V�Ӗ?'sΝ�أ(����B�s��������}�x��er�fK�u���M=�!��o�:�۵=e��^�ş0�lED������Mݤԟc֩�1�����Jw�&)��n$X9w/����.���0u?}��s�Ȼ#��_%�����q�R��U����������a�2Fx���ح�. �b뾕����,��2KE�[����8�)ĞE�M����S��AQ��r�%�2�x{���GQa	�ߪ?�j�&�/��d��!42��e�:��>�B=�IU\C1�9��9���(�R*m�H�{~�ib��*B�ى1喸Z�PH���J��w�4Bo"�\�%i�$�;WN�E�W���hCի���Y�gȑ����r�S�W)T��v�Zʼ���Ŕ��8&��Y? �ʴ��}uG���Sn�=���������f%���Ȍ;���������e����z5���+�B���d�o�y����1ʞ������=���Yv�vm~�N�%��at3�l�[�u�0�_�ӴN$���:�P2��M������o{xI6��o�(���Ը���#�L#k�p?d����6 �£[�ee.(	-��-�4�`=�5뀃�w�$[���ai?�*Y��^�2����|�`��|xH��ŽB3��z��z=(�>�2'o
~�%�W������N��N�i���/�\8�����O]v�����R�\"ol��ہ���?���2n;��T��V�t�\��'�9�����bd����p+ �oz�A���-�����Q�2舶Ek7_�/%Ȯ��Ξ�X�W�ƭ�h(r\5jj=�d��==�f��;zJY6jʇ;�稅�8�A\�~�Ð�4�ܞ�ˏ"f����~ K�QO�~�(��?�6����[q��աM*�t$}9����H��l���1�m��_�S᪟�}�� �W��@�D+/�ge4<e\�:��3��;��bɞk$�t���~��I	���4!3��)�E �^v|��*�&�x�A���pb��T>��u�X��Ț@��͏�#��Oo�Lp֟�é��$�sni�:�{	�em)F�S>Qsn�!.�,>?e��g��-^��.i�$��GQ�T!G0��L�3>9��l���q���E'��C�TG�T��%�R�Qj��a�G���6N���Qt�35�e�U��v})Ѝ���*䟏/�|�����-�!���8�d�O_#��E����P���؃MB�K�+˒�&[W:����l�tx����f���i �v�$��Gʍ��A�4j�,�Y@��^z�`h�!������IQ��:�xM+�ۨ����X��ẵ$(:�/�H/����b�lK6�#ژf{
C�C@��ӣ��U���6l�l���7���Qn�,[ƎT����ܜ�9p�:�O��� aǞI���-�l���/�2�x���*��߂wY߹�S����"�wMuV���+JPðO9ªX��G��������`��\�tPECX���j;��|J�ᜍ%U��7�2M���U��c5�3��+�g72,�W9�R�Y��P�t35V/M;"��j����������"d hF%w���*���GvF��h�O]�����d���9����da���X�RU`5�Q+�᝹�����e1����.����N (�aX�t�D��0	u�ó�0Bm��.���R�e~Y�w|#�K���� Su�TQ]����sЈ��ܲ,�f�W�73A'=Lc�Hz�6H���`�������5����Y{ȵ*�_�����5=�^��%�p��D���׼�>@�����̲�
*{V�9y�9�x��I�􏾆I0�h�7��M��3˗6Q��;E���Ō.ܙ=0*��ȳ��=M8���^�a��͉B��Pglo���ůH?j�v���D�7plQ\������m�VćV��k|_=uɅQ�����jN���Ûa��C���q�����+�ˍ��O�����<�����^ö_��ZVX������H9X����&�CYRj�/h���&�в�{I�|�-ӎ�t6�2!�<O���f
�2 �'kd���%ɰ]�� �����o�E���f�	aN{�\��-���Ӳ2Qt̴�[�]��mp�(?6���D��j��HU�*��z��4�]z��ZVy�ۅ��m߫��o
��f����83�V&WT�*~r3$	 \Z<qO�1�-��+�35�&dBQTf��~�<���p*�E��\����T��2F�v��,)�_U��iݕ� ӖF�:C��j�'i+.��^~�x>�C/�)] ���~��~���%�U�\t�_!}fv�'��4<�Ĺ?���J݂d�Bw��e���t����%럻�1><��P~E�,r;Z�f��֋əޛ
4r���y?�f�6��@�K���i:�"�4��Č<�j�8P�ӄ��|�}�$���Z��Ü"�=f:�<�?���(�Z���$�tª���;/�e�;�x%�&��O]*۔�7�>cb�Y�(��ibb�;i�q���J<D,���}L���2{@��ƖGW�0�{w'<6��ݠh%פT����$9�L昋;��R�W����O۾���o��1�n񏫞,/�L5� �v�!���ѳFΥ�$a�}R6��O����w�"9z���8޸=h���{������Ϝ�;���F�q ���L:
�#X,/�e-9��n�3�݉u�3k�_�1D���~�P���IX=0��	�4��Z^�yi+�и)e�#z
 � w��� ǈ��;��Ng�F+�[d��NC�:xKDo�㉗�?�O�Ե�+�v��0ƙ����br-0S�/8��׀��ƔF�%���5j��ɖ��RN���+�y���.�*�T�5\�(��ǥ�hM������y���pP��~ն⏮X��B�os�5��#��R�f��/l�s��4���I���#��ȏ� �s��,1�,ڷ�Ӱy굤K��T��:��]j�x�S҇㭝�.�c,ԋz��W_5R���0�<���o"o�C�"|����1?�y�VV��s���w�� )ٴr|�����'�g���7`9f��tNc�e�;���,u��yv3��)%�Z[�(_��i��E�����b��^��x�߇��Q5X�
p��S8u�����s��i�:Ip���$	��U�XEW�{0��{��op�6Q8Cr���c!<6`l�{��NJ	x���BT鹣L;o�Q.J���!���ʎ
;`e����|u��m�lA^�|_�]�_Mo�S�bl��<�C?��ś�����V^zd@��݉��KI���Ե5�SA�$����-�P�[
 L�� sE
?��~�okG��6^�77�n��h$H�8.�݉�eu���bI�v/ơ�����4�Ѯ���{)U?�>菳Әh����|w^
�
J����Kuy�ːaӇ�?4%��g��}�[���g���	94��rI��ھ0�=�D�^�[YCb�1���g��[��)k�V��}R��&z���p
��@D�Q���Ϊ�Wӕې�=��M�g��->چ�5�g��l^H��/_{GO�SiH���6� �wsH LW�Ā�{H�UX�n���j�Im�ɣB������Z��h���b�ͱ��'���@�����sj���SyzPڜ/.ߍ]���f=6���$8
��^Y�2�r�},%wyy)����'OM��Jz򕱟���q�/@;Y��<�l>������~�a��[�0�J�!����$�Q�b���J�x����E��VAC��\8��N&�Ap�.eV��_d<镰g͗VL���rB������@G�\8�)�Y(����i�",�00���јx�7q����?S�QM:#�l��cq��KR�����ؐ�����D)Na���w�с%���Rm�	>�T-��n���.�Y^Q��l"{1kֈ�`B^TQ�c۶EsR��YT��0>�k%AY�J_E�"�R�o	c�iP�T��4H�ޡ6�bB3"L������s�ٯg�l��S{��[[�'S��o��->����e�S�=�I
�*MݪP"�.� �������+)���O��b[ w� xI�Nw�ck0�5�@�V��qvwvj?���"�沚'�r�&�|Y��Sb��`��&i��D�����K�5�	���ON��nA��(ѥ��o�m� ������[3��aC	Xr�?wt�ϗB'�h�H��!mr�	�qr`���l)��zx
��J���s����k��L	:���
����	"�/�Q���rj\�"��sÃ�rf'y�Ѓ̈-�����[@m�#�w�ZYC����0P�� z���M}��)q;�/H&L&fo/<������%������B��KE{�����й0u��I�`wB{EG�r!*��Y�\�}���ą�$L��
�����ɏA7|W}]���	�)�X5�Q��d7�ҍx����L���ͨ�2ːf!�B<��}Μ��r��q��}S��G�h�k;eBv���
�.̭�Q��\3b`.K>������?w��HZ�ϗ6=�g�l�6�籐
)��¡�+�{��D���ʥI�`� ~�N:Ɍ?p�믞9c��E�g���/t�H�,|ڃ�C|�a�S���RF��
�y�MH��)�y���Y#q���W���=�n������z`�ʓ
��z)��v�:Q	w�?�F��ß���l���*�3|�Vt>�[��ú�#�Jcs��-hH��h	E&(����@�L��*ee��ץ��}�ȸ0�H̩��#���
v�]ʯ���H<�:DO����hk�A�tB��秤%)I�͢9���f⾓^t
�����Q{Ǘ���;��X�� ������FH���!�c��4�
F�z6����9+��K�9����5x��Ep�ԋbh��i�'G�Q�o�m�D"C��7�2���X�K��2E��gh�X���QS���@x���Y�\mPS{=iU$�����)θߡ$�P+���j���|��?��jwb{�,#*�i����³�Z��g�й��dV�(�99�X�823�s���<�<u�\�?�S�l�*�l�O���o!/`�p�@U�Jd�����С.ۇCxZ��,?�6��g S.m���Q�0�[��U�yb�k\��P�{�4�"��^�#�ç����(�p)^
n+ZFȑ-�e_���]oΟ��4�-s�#a�˓vA�|��}����tu/y[.&ܡ}v� ���Xh�3��'�^�O&wS�"���$zw�
/dVc���֨�鼫G���
�V�����8M�����I����LOjt��.��a�5�!@+�K�Y�R�KsRiElXZC��Ý6�������Z�R�Rx�U�&3���t�gYs�M$NJk{{���dVs}�GD�3��2�܅2�hW=��h��`�y0{eG��K�#�����q9]��Y`�����~�p�4M�^A����:5՘��X��a�i�i����I�zO��`�*e�;�F��v���O��� ���)P�7ؠh�]���%�i���tW���t+3hOŘpD�ֻ4@����[��1}����%k#�_���<J}�P�N�?M�{���P))����ORRE�f���cg|;�i9�MRl�R��+�Z�k�
�R���	zx�^j*���U � ���]���/m[_���d��o5���y�?>H4�f�	P��24��"��0���}2B���;��@ ����Y?Q�P����~*	m���p��{�鶀�^��n@~[����U��i�C�#3c�q�މ��]�3�zS�MSX����
�pk[�V��dy���*~i�s�%6��z�7����ê�d�&�I[�E�y������1�]d^� e�ԗ���eo�{-�Su�գ0���`MCt�}���*q�������`�v�EDG���.�NLьX�`���/�E��|W���� g-��	�N���+�0u9I.\����v)8Ůig!�X��~�DQ;ÒF��ۥ��R��P���?iR�W#O)g(��3h%96�ړ7�}�XU��k�M� )��x^2/m�����,j�¤^�*�����O/8��G{3�=����8���0��*pEH���	!�\:�h�/$�܋cW�^��vLl����T���~���U���kW��մ�A�('���I��î��d�,pD�n�#(�9ц�($�r`/#��L�\,*�0��,5��m�^�\2?d9���%�kͺ�V%����ᝡI6�l[��m@ B�������@���Pj'�9G�Cߒ��9�)��=b�v����ol�L=�*2��ǎ�q�+K�A��,�~�UZj��R��p�=�/VC�e�7�f[+�!��&$B��ʅ��":9�u���ʆ��+��*�Sa\�T���TH�C/ŭ��t<��q���]2V�,/�y�f@�$�h՝',OeD�g��C�ǌ0�7@�X��??l��j!���f��h�d�|A�{Z��I��N�.M��(��c��FIpꄲ�p«��� �>�u0�8��a`0<?f�q�D@RqH����i��?̟�}��\�+��:�mbU9~�	�]��w�,�ʬ��xO�/龌��L+��5`�A��=:v�:��3�n����
���#B���|Ne�3!˶�
.���ći���Or�	{��B��C��8����W����h�0���۴
���M�'P�F�u�I-���򃻔Y?q�*!X���n��4+�׹E=}j��NQh,e�Z���-��u�-Y8>dR�m�����̐���IС�m�N%��5*R.�ml
����멵;딈�ȋ!Ԝ��ȇk^Q����$d 8ǲ�p�c��i�;�F���gI�?���7�\֗^�8h򖓬_�ҡ�f�7��.J�"�4�{�p�=pvJ{�ŭ��#f?�#po��R"M�/�i_��T�f��^��l\�:�U��7����ޠݔUjc��0V��9�C���䄃w�#Q�xِF����C��H'��Ř��jߢ��a��1�d��NVmב�K,R�rȒ	E�rD�<�W�QP��=v6i����bs�r'�������]��"%�5���S;���˒}\Ñ�OY���VV0k�~,����)/��Еh&vb�O��>I�ߑ3	H� {.��-�������l��Y�?�p�:�k�[%o3v����@�����!1������m�_��[Ҡ�u�e�?.C�hĉ(R{�W�l�f6��\8Τi�t�&ʴ9d D̮�I�p��E����G��ܭL�\�	2�-��r��[�5�c�p�<�U��(ֆ�\���/'��+G�~ZM͚��³q�����ц����\��BAu~�0��|�Z!�RދiiJ�9;�ɢ�2�YJs��N���7�34��`� �f3�;����3V�`�Ё�(����.��c.ZϺ��)�"Ž�J�;�`T^�A���W՜��"육�ߪu�8_��1q��7�%������q�X��y}^a/p����ǳ/ЅY��4�pw�e���F ꈇaX�S�L�����e�����}>o��"�A�X2�eH���L�_�K�
J�I�#��oϬ뜖��9Y��n�fd1�)=�L��B;i���]/���,H�S�̀����O��`]���ǽG�U�g(79�bV��Y�}�떚&����!�{��S���O�m�W�� f�p�sRp�7������'��U����^�0>���p�
s�Ӏ�	*N�|Q�,��6-^�ZU]��3Ѯ]�4���Xn��6?u��/���hf�� �#��|�5Bw=�� �{oa�2�) R�A~�ͯNFw�o,}��R"%y�3dBݒ=ᨆ^Z�z��ц�Aj���1c0h��O�~�~����$𭛓�U�=�p0����Bk�J������������������e��&.�@EE����ax$�Bi
&PM��20s�=ǂ�H�&��ȋ�>aʀ8ɪ.�c # V���d�9H
��G���כhW�� �g/�+;�U��d�%�{܌G��"1�|q���'#�o=�0f�[�}+�2>6��(�S���Eڅ,�h�SÎ�� ]���N��!�0��Yފwɷ�Q�uq9/��f�7���'�1��������ބ��h��E��'(�aȁsz"�0c1H�7��<�E�<T$����O��1C��G^qk����X���q�,���p�e���#y���Q5�V4͏iW��8�3U��7_�D���h�t�������HQ��	�
�2b������Fy֧�BsS�2��#W�C�6ä|w���'��� ���O��1Z�[��Pd3��b�b��A{#wd�/m�$Ұ^�@J���kKr�v�Ԛ��{�W�2�N@J:k�R[�H�od�Ɂ|���-��DB������]�r��6<���J�RI,8��'�#U��35���ħ~l��~V�<v����]�`�W~V��F���A��m���D�	1X������ ��R栊�he�/�_
y5"xO��߳�sn�}�#�� �Q���a��Ǭ����� P�ZS������;��j�n*�s�g�Cj|�d2���VÐ���9r�F�@r�{�T���%�=��؋x�EJ��CRqE3��g8	�B�!�N���R��fޛ�{�zk/._��j�����ڄy��E�֒���A<1�xkA-�i���O�m��e)G&�C�+�?��I'�5��0�X�֓6h��VX��4�r�/���r-m��%0�v�8�An��I�R�J&y��qA�E^���"�>� p��nFw�C�T��KӉ���|�^�j��X�q*�����qre�;�_�臛�z̴���S��ƥ&0z�{���$����.�n	�bU�n�g㐎6�`�ǳ��r<F�u��Fu&)ާ�������r��J��pS�"�ӟ��p�Ӳ�7]P ̥�'X�� us���^��k�]�~�>���V�(z����s�3Xt���U�Ǖ~ �$�=��0�N$Cx�h=�o��J�IZQ�l�'RB�]@�-��S3�$��@�	���p��m���2��lE䫄OMk���A�C��K�bjb>мr9夯a<�<�a4�[��fK�ʰ���5�͢���K~,�X�Rf��-@��̤sA[�-�qy�?�U�
���Ylq S�<����*iX���}� ������G�ARӥM0WJ؜��J��0�9���J�O*K�J�&��E��	�f�f�`��\��.�}�O{�Z�,=�ԪdU�S�M!1�t���Z����x<�ԣ�z{�+6(�iA�3B��[��:6�Ҋw�8Pj�ɫ���ST&��r�Մ����Х �e�&K��	���\����,�����q7P��q�
�!�1���I9��(����!A;�5~��n�&
�C��Z�,��uٸ�]*�g��w�Di*eQ[�,�)��ĎvzɁ\�Op���P'���C<�2���gV[�hCVy��v��kJʅ�]]�.��c.�ld���h�c���Y�B������#o�`�8e0���k&-����it���bZ�s&������̤Wp����ƀ���{˥|������n�}��� �MzI���b�yy��Q8�6zo[4t��D6gB�� ���G����C9S$p������W�P�2wF����E�<���vU|�eS�ѣ�$��6����^f�ֶ��Tg�n�WJ�9��i^����r�]'��Av��1l4�R�q��N���׹nl� @�
`�ļ[����n�z�����r+�b1�d�R�!�>��uBmg�ؖz���̉WZ�����g�;	Y,Cm�~m�JZ�?m��R�R����~D9�=�7��\2�a�|�ό�F����GF��z������3�
�U+�Y��ɀ���@G� �UL�B�m[�����X�>��擄Ǭr��`�Л?��Լ[��
�L��Kt!��d�|�ݳj��.����K�[	^SW�p�>0��+z>IĢ�_uK�G�@�Tye��'>��&����ʚ��1@c�[TJ='��>�/��J�$�|؜e=�T�l�ӓ���A�[k�<�w�k���~�6�� ܋�@O�r'�R���o
uԚ��Qf�o�f�uA�n�1���u�i��U�G�!t�
O+Ғ
?�/��ZZ7��ݑ�=�6�K�a�>ɣ����W,���8���A���[� �����~)��|!��rg�8�E��Ie�Ӻ��Mڊ�E��ś�# �dP�9gD��J�HkN����`b�>TZ��#0���yF�}/<�k �!�.LDIB;Gt���'Q�k�����Zf�=�4~�6����-b[2B�t���
,�ew]b<��+�7~x�$�'�+�n-�}�Z�P��e�(^�{���iG33����}�	6a҉�t�;}�u�Fk���3o�u��}��6��I3�����m.~t��\x���{`1���5�r�XW�6w;"FD��7
/W����y���@�JI,�8!F6�[��DC#�����'�z��
Pi��O��Q�-v�ڮ�Q�� f���K�c�	���w�#Y3"��%E���;��1��Q8Y vt�0n���Ⱆ��U�x׍��qJW.`�S�(~g�U�����z�;�> 4�	�p;3e��Ǔ�,N�#t A���%ku��jǒ�Q�
�Ag��NԦ����������4�Xϖ(6��ֱh8�d����jW[�<'��!�7~l��?J(�^kHP4����Pl�`�u�f��v+3G����-�����RU8+�UM�H���$�;H͈WB�AԤ����H�)ns��¿�?Fh���z2�����l�.ǪJ\8΂��UE�l��l�ę_{��H��b{�'j���U���=�r�|l#�e�J�e�'��-�̋Z����k�B�i�;�^/ؒv�ٚ��%��W#�OjҌڦI�O����G�%k��'X�����2��&�Lִ�Y��[���'��:�7�o1���� w^H����@�����m��1诰fv;,�x4�2B�ZF�T�(��u��l��0�c)����-XxN��)/�0ã���ߜ����W�������!��8&G>��^�'Di:A�b��T���1b�k��n���P L�2���jv9�!d���x�ў:�Qs����h'�)���MKdl���
1�b�1�+���JX�Ϭ���#"�.Qj0�0	�=4}�|8.�Cw��@�֖���C,dv߆��λ�4�?)~=Ӻ)�^�i1��m��O<�*�S�]#E��T�i���{��!��co^~��-8ƛ��(�kE���_z�E��U�o|7��X�Z�r��z�n�~�'Z�l�5�o\�%k�_�}����@�6�Z��PUD�}�W��-����b��T3��~�%Dh�ѣ�r���Cs4�ЕQX�����e�g*�������B�xn��s�A��{���Rlds@�IsAa��{�1~�<�Ũ-&eJa�!e������=$�_Ϸ�<u���Fh�K7j�e������fHj�Ц�g�
�֜�=���ʹ$c<���?
Qs6�v_�jF����>�=�fks�L)�?-�C�
j<���}���$6sѓ�P�̈́c�e����RU���`8#�������M�1&�3�XLМˌ�p����+[ H�S�k���9N=���C; ��rq(4߭�a� _��3�ISR���Ra)	���EXD잱!%e�Tۡ�8NL�,��5Y"�5�E��&�m��CϽ p����V����/zHt�(t�oʎ0x1��#����˫�]M�`k��zŪ���R2gۑ���RҨ�j��w�b�Mb��.`-�t�|��+5&eR�f�6&F����M�1*�nܔ�g>�r����k�Kg5u<��%�H΀�͕��D'i�tAӰ�j�>�ܕ�˶07��pFj98� �!�*W@9J|��-r ���F��)�+K������D�S��
ȓ��4���b�[C�,�YjY��ݼ�L����X�휃摯��<#���(��B^�*ĸu�X�ѝ����N�D*�J��HL���x,m<�G�)�r�6�]�q��̺�]�b���Xz�%֬��S���=r�Hc˓�w5�7���O���v�a(�';Kb���8���AO��Ov)�����G�6e��jٿ>tI��7ӵ�p��'�W�g�+�]�%�o0��T�+e_.�|X1Hܔ���
� T;�r���3r r.�q����O���pӀ6���Ʉ�:�K�R���W��̐�y�E�(D��畾t��7\ZY���"�i�[Ǳ�6:L��j	1[�;��%�T��H�a����4!3��m,��p(���C�⫔���p����%һY�x��up���i-g�_�ʲ��nd�:h�b~�+3�]�C��A�K &�Y	G���k�+TF�4� �v-U��e��a!�g���Cv^I����J�E����[�I52��$�,���=�	����h��A��FyN~�WYq�T�@K������Qe����25P�6?�f�b���=(ӻ����9xk\ 5%�"�"#TӇ���p����}��Fy����'����T��\/�S����4��'����� ���m:Z!�i8�b��%tF�3��0M��{^��sV��褏�[�q�����*���L�R#���4��y���� "dޓ+�Vqv��]��%K@��D������=354" W�bb��A�����0%�G�9��+����������lG�s�E��t���+�(q3w-_-�ٴw�����0*w~��`'�Z�]�=��6h�z��^�7#`\V�.M��6y�7x�&ft#��F�[c���#/|SMt��V��4QE���&~@~� ��o�Uj��&�:��؉=���U�-:'���\�Ug�:�ׇ!��A>�b�1@�,k�t�����;[�ּ��4&u�(M����,����U4��o���׶�c9�b��z�@�5��-�4%����`����_���ɢH.�xT<��Z�1�޵���lwq\�������Q�ی�&V��_V	��C
�Al'�Cal��W�Z'9;&�r��t}���}Tk��|���؈Tq�7�g;����Z�
�m��1�0�zLZ���yq��T
��{����=<����]�4�C�5���7�m���W��+��l��M��������9KEӪxr?āq�+~��ٍ���6k�Q���/��b9+�+�'0��8��^ 3e|2�R�޵���:X=��2�%��� �,���[c���9Pj�>ր���<��3��ٴ�!��n�h�x��E��:l�tR)҃=��*��\�K�V�p�����	�m��I$�U4�U�Y/��7�yxdlLkV��>j~�5xm��=i0��IuP]i�������ʂ�SE��Zw�ƒ����2���Py���uݡI�;q�Z9����<S���`�Ѕ0V�T�=�β��ϺS��'�%pk�0�K��Q�
gj�q����)�X%�b�>��'����K3���Ño1#�<F�����K�,U���ܳsW�|;�%��遽o*��c�j�g3�]:���	&M2��h�~�~�LhSg�}V��WtF��S��Ak�v�R�ޤPs�=P��m;��c��i3]�=nu�zգφ���>�	5�yP�
9�u}�邐�8,��tF�_s:T6H݅(]��f7rn$}ܮ�'֞0g:(=�/�z����&4Si��I�s�y����æ��	�(NN�L�8�&�<��9�G�����u&!h�:4E��XU���ir���*RQ\�'���p�>!m�-d2��\0�@�a�ʫ�'�8�W=�__�����Y���̀PY+�ib�쉭�YU�A�v�K�'���~�f���|�q,�G��-ÛF�R''��&,��R_t�b��|��U�B�5 ��m��8�3h��.iF��H�/�I^݂w�W��*��zdO�Z�g���Y'u�Z�*�i7��A{�Ċ|�ɿ�����mZI=T��xP}�C��7G���^�� O�����H}|Ǆ ��G5�'9��Q�����+e]����Ȭآ��Ϧ.��P�	��h��3�TԾ��Lc��L�~;�^W��#!;��^��[��Nw�"nEL�c��i�)�ϧf4��D^�r�����Iާ~]�v�oN9j��:6YV �sӶۻV�9��֞�A��g�*o�&��0\�/ֺܳ�$6�d)���񯋁}��������g�&�i��ݱ�����.u�T�A\Gƾ�U8��YYy`[��]����/��SvU��{C�Z�溙����B���9�^�>97+�B�;�,�s���S����wA�S�K�	e���e
5�u�|�.k�7�K1Y!/
��i����;Kr�ak,��U3S�5�2��*'���ȧ}T��RƝ��,N@n�@g=��F���ƛ�\�.����ّ�Xrz�SZ�c��L��7*u�}T�{��b)qj)_|.�}xZ���T�@�P7��Y�Rc���In��;!�!-M��P10�Yh�l���W��Ij��H�w���(�)߮�"=`n��j�S�C�\��p��2@=O���O%��"&�"�c�����(xO�m"Ӥ�a���;�{��1��s�i����"HSʓg��C֪�yJ1��B��o�UB�oN�b�-&i}'yչ�o:Lh��2�V��rF��}l������J�?B2&��e�-hH�wW�A� 4M�M�m�@x�K���w�N�����$L��upv���V��F�Q���``�?V��Q`�����Y��&'�s�I,"�B&jku�c�܍jr�\�*�t&3����xwm���t��2���5G
	��-xi���P���>_��quA��n����\�Tj��hY���l��9;n�q�Q��'��ǃ������]�J>�3>�9��5oP���I|PO2Ii�0���uO�/���m;��S'|2�,}b<�l_'�uOvj��hݟ�q��nh����!=��g��+Wz��b�����g���a����v��Cʫ�f��A�=�4�5aK|�Ą�OF��m���7�v�&c�2U�W��jiK�E���u�����MP!��ю'	0��f=�'�9�v]j"��r'���Is[�"B��� ������ފBP2�������_d�j���H|h�{�r�h!]W�/��7^�cSĚ�����N,����K�y�*w�C��\7L�d#CB�P���k�B���P7�R�ub��)�@P~2��#��-�����+&�v�����..�`��ؤ��@�c���ο�R6��C+��~g�X�\w%;!f��R����e{XsS�!I�V��8%�����s�9�nKj��yؾ��A�4��g�x�u��ߩ�ޠ�^�ٮdW�o@'X��LɌ�!�]#;̜ч�Ɇ6��j�(Y}%V
���r���$q�z����WZF�u��{i%V^ўP�Ex膣�����;¤xC�6{�ƶg8�E+������5�j���^y6�*�v�5�?�d0
2*K�Ѵ����t����Ǔ&���i����aN�9u���Q|3��t����4ۇ��xH��5��{��j�� 7 �퉌#��_]��N�*l|o�BOA|a��l�#S)�r����U%G������~���6���fI�.����o�'���Wk�e�^��T˫G*������e�~L�!|�ln%���ռ�����$8,�kS��ih��ٗ����,9ZM�K���=o���N�78x\V�yQ�	�^r�6�1�8�HO�,
��N�bh��v�C�%�3��e���i�>�x�H˞���#~�/ڬ.KsOu,�'�C��b�7��`��x�jX�K5�W�W����G7<m�pe�fd�`��\|�7���^%�ٞ.wWkLi1K�{�|�qU�M)���*0{\bp�@�|׆4�q#+�y���	7�	��{0�ę�3]¥ j�� /)�4���"֊��3�� ���9k��D5�Ʃ�c,�9�FT�1��(�^EWG�`��;�nNG���}�Ӯ�u���G2T�z'+�l�O�9'�A���蚒�[���64�1e<E�ji�G��{�LuؼZ���)FHc#���H�3���b�U��Q3��gs(oS�͒q0��a���m|�ѣ���;Y)j_l���C�0�:�܃p�>5	�������2���}'B�'�|چej�^�[�Ɵ����5���-�+�4��C��B4+.��@o�~
�^`��N��#��o��h�sM�-�K�9
���b2>�OK���u�F�I��D�n�?H7iz���$�=�Q|�is瓕��ҫS�ߜu�.�I�r<w3��h;͂�����U"��d�>���jOL� �"vd�<�=�l[�+n�<ǐԆq:I�]�fY��v;grq��	V��`s�<�Z6O�5˴յ��x��SեelĂ�}wƖq��({.1�B���9НT�_]�}>���0̟I��:� )� Bh��v�<��6V�hb�n�-~�Aj�L�@|K������R�>���W�������H5?�W �6O5p��<?n ���wM�W��jH=H�����]*c�-Z��3�h2�]_�c�2�P(�"�G�q���f߭�����W�LY���}.�U�ѧ�l�?J�/?�Nn�2�n�J�?�U��A�q�7���|ԩl#��:*Ǎ�!<���Rw8vvDt�Ҟ�X90"#�[y�yZ�3b|]�*fRn8�H_[��8�T:� �]�+s ���\�Yf6*�M����)���%������扺k0����˳")E�׽%��|:�=�j��
�жQ!FL���=�G栖��/W�mڧ��X'��(?'�8����r���V5�$�	J^�E��x(S�70�%��Ʈ+7l$�s4C|��z�cμP�з8b�����Wb��l�-�T�-�1e�wy7n�J���u"`�L��7�!�;ɚ�%�bm彎f��o�(�U<�D�e�,>�����8>�'�,G&�e�]ZK�E�;�W���	V{~����	�(	sw�;!�zj�����Zi����,�Y|WU;䖀׀$qc��b-|���t@�cc��ʡ��/ϓ1Κ!֟�)n��6�a�p���H�ɵ6W�R���O�L���*���-o�%��|�v�P�u�Ƙb?U�p%u���M���Es���?�ԢF��
����.�M��̍��u���}� ���m���Z݁ܣ�����Z$J���k�ḭ'������X� �{��>�Ne�}p�i$@C��z��96�	�V~ߍ��lC����d�s��t_����g[�D��b+ w-P�������~�x<�����:
:�Rŵv����!J��AЎ�˦�g�9J�FGr��d}��B^,^��ɀ�6�C���^R�!�7u���i��26�X\��P��������G��?����"�^|[�{(�E���.A�猄4�.E����f�W�2��܉;������Yr/�(�Ҩ���U�!��SMI��t�S&��$�9Ү��j���I�h��}� T0Hr��z&��;,HG����ۉ��w3q�ީCt=�)�|� ����
��-3���do�i��ք��m��Z�<UEB
��.2Șb��H��N~�ߊ�UF�HA����O�[�
I(Cq������Ү��=�C����K�����E�%F�ޛ����Y�ldK�# (��4L�A���m�&�����A"���I��z�(��Q
����N�Y8Hk��jnڀ	�-��t�#��z=F$���[�t�i��͞�35�����rd�
]}�e@������u�DWj��-�H��{�, �!�[S��2u��-ZpP�Z�h$>g�p�M���r�'m:��<�c\�i�f�@����!�I�k����x��W�=㴉u,�z��!�Y�ߩ��i�ߎ�2�G&��h)��p�>�Z��g+H|'s��F 2�2Xl��Tm&�h��U�`��Ƣg뺛]7R�C�Du��}@p�ww1@������{����lb�sN1���';�MD)|P�R�&�����D�_�=��9a�\�C	�	�z?��h�`�P'Lp~A�f�,Y&uϼ���&�W���r<l*��%?���@��Fm�hUe���������E�VƋfrm��J3�4�\�w(�Y?�G����|��iJ�㔟Jd���!�TJ��=�~�%�W�>�w
|�F��*�ANI��e1w�Y%�N/�K�4iV�����J�@.ҩi~���Jۑ���nld���7*����.��ʰ��'Ԃ-�	�n���w�G���)s�)[QO��ǚ�q8�R�[���b��;ӫl�	���?����?��~P�N���M���hnh(��	�|���-de%@(�n��m�� ls(,�_���~ه@��-�=^�u�*;|��`����F����!\�'о�p��b����Ӫ�o0K+����> }L��c�'+�Q~J�h�Ք��߯4B�s�84Ž�o���-%��J�o���>�g�h>���~�+�Й�'�9�ʾ؇��6��۝�>�&!�e���]�@b7|EE�_��@���;�V;~׍WB���!�c� }&��v�Spp�A4�I�&�sO�Zn��鏦��E�ϸr��8,>�9W�NRr�f�{�K���p@P��ii��'�o=���%�i]l�tk�~��u�Do-�Xx�hEbH���O�J4W_@��D%�H��P��]5�V:ؖn��%�F=�C������T7ҁ}�S�!��4.��IE����h�����������O�Հ��~H�nZS�Q�O*H>���ļB����q<K�<Io�Lͥ,xzc�id����]�����p܅��.T��|ˇ�3ց �aY�$�.�ڠE^�����}�a&ύl]��c��.�h5��@�C�"{.ד#!6iS���li�	#8׼�N��E鯛؋�Ĩ���� HL!Z���_)���(�ǹx�D���g'>J}��r�ɼ�OΩޔ�X�k�u]Ч�d�����q�{��Vx>��������#�)�n�v��K�2�t~�D���6O��r��凟�9�0Ŧ��fZ&R�����^�$��G�PeJ>3����N&�/���+��0H�}��!,���޾�k9Ø�Ӳ�s]�����x��@�����y(�ݯ�VWqd�=�1��+�S�w�mI�P�/�����-4���1JE3�aD~�;A���<!�����H���M���lLf�T��#Q�M�M��Ȏ��6tj�C�Q|	>�ܐ�\��
u�F�r3ٻlF���/����	�TL����6��&�'vң��p�8J�'�������佄�6ye����ӀxX����.�iNjU��S�o�g}�\��5���`Jo���M����r=N�PI���9v�&{��$XR2ya!
*�����Z�H�n���OH-�eA�,, �<|�#�J����6���8S7��{~#`��ۖ��94�CE�����9D�4VA$TSTy ��d�?��ƮmR�/��S�f@�4��қ��Zx�t��W�h�o�� ���2V��[%��;"�-�9w'���ڒ�~��u�(��?SS�@Ή�;љq�����9���0Q��Ņ��6���>m �F�2�$9:����G��ʜ�o�晎��y��P"�|�_�0e|�t{��&a6��U=�F�lh�R�Z[��zF���eQ�� ��)�*�ZO"�Dv�Y/1M�}�R���vk�Y��=4xcY-0'��cD����+҅�gu����@Q��l�qrnL?��;�E���}�����x�z���%Ir�=m;{[�q��nf�	��U�T���'���J�����g]����AКb�Y��5T�GN���!߃S�sK���t��*d|Ѕ�FM�Q���`ZK9�V��{ʠ�����:���sX�[İ�d�z@�e�C����z���Ԧ�� ~���I#�wȳ$�j0����P̼W�q��2Kډ�)�IȩWa�B���a�(�����Yr\T|T<h����iO��D,C|��fV\�e-躚d�uQ&�Ou�R������W���Ӟ��Z!�|�Z�)�<�t�/��+����T.y�{\��l�ސO� {�vn�v7W��|��d�@8m��#�Y�3�:��$�E����� RD۵���g]e�@�QޒtCd�T��&r���t��(B�y��}�铬m$��wY��	pK*��f?OHF-Tbd���VEc�s�Rn٫����mq��Vij�mDݰ_�[*�ُr+s���쬴F�P����"���^�+H����D6�nV�PH~�i������^-�LjF!�����8��Y�:[*�tz�+�`��VԚ�I��0&����o����U*��$��U·^��F��GV\2�p�s[&ܱ<N�m�[�P����P��뾷D��{�Ǆ��i�*چ���?L4�e�\�,r0��H{nD���Ԯ�Z�&�����\�Q��3�d9��+��
1bJ�۫�E�M�oҝ�!mƎV���'�8F�����k�.���~?�?垑�&z��c�K����o=��"ְjի\~�n=�͡����%��27���,28#)r�����§���ɖ��Ӣ��UX���5q,���(��.p$s��])�n$<����{i��y"K��ǃl�{�A�`�����;�c�[�Eo��_-}���h*�;5���9�l��	��i��%U3�g�(�)J���c�i�����7���h36_�@���A�~���DN�dv?!<w"��
�61A�4d�~�u*=�e||�Ä�uy���(w&�E�G4>�+�	Q�����&���N��C`��v	��2��2G׊�m :iY����N�`篚\�-�-����h°�5�&�C��N�x�{0�4fG����u=�s�C�L���@���?;����gX�Sb�G�7]]���kN������c%w\P�J�o8%��h0�����r��P�(e+/�0��q���D��u���?����p����r"�^E6���{0jk��D�� �>�2�Dn���3��M����o����Z�H�"��]	��:a����2?eq[�e�X���A룖TZ`U1��K����:�e�����*�Q"V����~��ٽ1��>��XN�����k_�W��Y�Ď*�1�f�ΐR��>$Rb� �8	����RV��y`��.�A��ZRuJ4p�J�\7��w��^�\#�6�(b�څ˰D+l<�4�D��'����S��7+0qM�ֱ
�i�EqB0M�p��c�9ҩ�Yv|ݬ�#�n�UΩѥ�s�p,�v�5�_Z��U��j�p�=Ŗ]�5˵�U�5�|��R�@�/��}U/�nj0]tQ����|6� ��۰0��CL�x��q�Q�V[rV������0���5��A>�uj���;6��f�s'xE�Uy�O��_�/��0C7"����b�Y�nw
T��HS#�h��}5�)LoٓD��_o�Z�I�U�kI��|��^�/���>#C[,�*t�$�)5|�Y����\�D>��(����Dg|oKb�]N-�E3��xʽT�8-�w~���2����@�_"��3p���<ΉW�����?s��uh����]�K2�;�"��<փ,�N�m�"��::؇9�=Rv(��z/�n�hūrT� W��^{
��q�����b��Q� ��f�0	 ��V,CV�f����-�B���m�/ҽ4�M?�]gP�-�G�*�iI�5�k"�'�F�%Ȱi���_�t�7xر�a3�rH��>��[V�[�U��G���2=���3@�*�q��� %�NH�֗�1�F�`P�<�1�?��A�kZ������rl�S���؛!L[3PQ[�"��#4J����P���+`ҡ��yW%L�O����i�l|��-���ܪ~�}Cc�%Z�-p�� �0�;v�.ni��I��r@g�il�ǅ��
>��!05�\.m(6��Llnj���9W����-����(���r�GX`
��x+}̯|?5����1mN�(JϔC�����7�>�&!p�3&~�S��(���	=�j�ť�*TԲ7��C��R���~U�J&����Ԥ�?�U���y��Z2���ZO��KBh!Q`��2mp.��̭�I�v^F���t��?����Ȭ����<r���z��!q�ߏ7��$�F)��Fx��� ���TƗ �~N��)�����c2Խ�9u`t(����Z������7�=���D��Dr(^�K8�X���Υ&��0�#Fka�G��c���@r����X5�6ܝ��pb�d��?�F��)�X@�7��',�XL�Q���b>�2G����G��Xp�4�����=��3׈�+�MdpSk�8�c(�wXv1cD��x�������$�dJ����r��ͯ���k�BT�'�:@Ft��̱*�ƨ�%�7�7���� b�U��M�X��&c�L��6a��W�)Dm�C��i���BK��$��\g��/!�Ǒ 	���&X�h�K��4}`��
�We�V��󧪲���~����=k��J�c�|T�r>�{W�}(�P�Z�Q����.�@2^#�%0��R�&$}�D~�W������nH�c9fg[W�c�4f�~0TjMk�w��&�	�<(�1�8�{��8�gs����56�1JLX�~�yP�r�\�m��F�)v��L����6�Z^,����?8�D��/�~E���d�a��pb
(����O�����fP�?�Q���<��A�k��@)�	GfHk󨫐�4ɼ�!p��L����&�YI��:D�c���g����x��gƿ�ࠫ`/���_���I4�B��L��'���_�(Qm$[U���|K�ckٻ����$Q�
�fmv���)s�EAe��W��_�-���s�>��۝9�RV#gאj��^��3O�:�ƍ,'�O<�'C{��B-ȣW���e���a�;����9(��8�ѯ����e��6@�fgX�
'�h`7~�,]g���N?D���m
�k;H6W�~~�W�M�-�w��ͽ�Jb'�ُ �/�]�1�pM=��	7G���U�'?뻖Źl�~+���k{
f0Q�HA����M����1�O�J�.	�	.\�������L�����q����
���T2a�� b�	�A��M�O���v�S)}u���+���|��uֽ��AΪ�j?������V�I�����1�;��må�_>��!6NY�� ��f(��N�G�J�����Vn�����!9�w�3��SA7;+����N�����N?���z'A�ӑ;��I��'M%4rj�M�T�$���d��f"�Tx��nj�������6ވ��kζٿp��Q�S)��$�n�<l�i��+ZH?��3!��,`�2�!7��ÈC��ѳtPg=G����ݔn_���$�/j��H�*�@�snٌHG���B}�~q�̛kE�s75�[�s�P�H�z7�A�3�g���=:���G.tT��.�[`xgX5�Y�;���$�?mX�� �O��"�a�G�����ت�n��?��@F�f�rՑ�j��H�j����?]��]%ؒO}j��Ֆl2_�u6m55[�}X-�Ž�(�(�M�d��(���k�y��q횋v!�YM��E5�	�ͅ�׼%J{�fdL��t�t�@��b����1+m��e?Ф��8w����1)�G�12l7A�!�d��'/�g��ƶэ�����q��Cm~���ka\�^_m�s���cŏbU+����4�����v��6̐�Dh/�{�T�Μ��a�X�.��[
3 ���4I�Au#���!7M�@o؟�cR�H4Z>X�  P�b�z��I�?�*-@,�/�ZĺZ}�/���1dH��R%�V l,����M%��%��V�*o�[���~�_�ƌ�8��ӽ�KFr�eb�	�ecD?�'�Qch�B�o�����VW��+���:]wޘ�;d ="��ڒ�ZU�#�U��\,M��zzw�+ϴf�=CA 4{uwS�
}��Q�u)��R�y��� k�^��hCx�[OժK�ZeM�)fV��q��,��e����.�D ы�+�A��b�xZ��~�tge���믦�T/���I��6�Ǔ6���}0M����TEM��lBE[�%˹N�O���-�����d'��y��x[�Tڜ�l4P�N�+���|5FD�J:Tr��q�"pH�{�C_����mse�EW�$�iҫ/���^j�k�K�@Q�+�����w������{����JFr���`�=�؇���]��|���]۽J�ؤ�aE<e�:�J&���`�+.�eY�<�"|��)<\���o�t��iv���^�.��y�nդ�X�4[�i��.�( �V��u}��}QWl�pɖǱ�EC���~X4��r�J�B�ȵD��םczF�d|���9��-B[7���2Dn����>�$}<r'��L��G��gj�ޚ/RӸe4�h���?5�wDIʫ D/��5�!
���㔏έl��jK�Zbw,'�F]B�_6p�U{X��)U�<�%��.=�����J����,>��]`���KI��� -���&�XI)���]2�� ўd�
�����;r=�T���2R�U���.|v�Ҿ��M����T��_�.���wz�)4t�i��$�v	�n"��(��s{}������4h�I�GA{���      �P��t�� �����S�d��g�    YZ