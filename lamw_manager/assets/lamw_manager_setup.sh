#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="261012361"
MD5="0c4cf7b59ee8690ba44954c9b09466fd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23596"
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
	echo Date of packaging: Fri Aug 20 00:05:29 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�aq���b�	�a��d�⫢��)2H)��Ud�/�#�l�`?��g�Ec7F�H	k��Q9YlY�tY	��hl5�W�Ѻ�5Ӫd!��Y4v�Ͽ�z!���|���w컮����s�?�����@�Cn���j����=f����m�tER��=YGBY�V�f�΁/�w͎͝�����p? �?�i���=r&��ŧ ���{ƣ&����j8�W����l������QnhP;�+��;�T70����Ԩ��S�Z����M�ԭt�b���`2'�R-�C�7�G�0	z�<��'��%k�v�4�)+�{ٮ�'�1�L��!���w���*.��(�J�b�� �8Bk7x)F�?m�V��eblۛ~�լ�/m�bju��u�d�����5Ь�}g����KH�\e�j !im�f��������a
��$�X0��J+y}���"�W� P�5�`�Wu�r��q���1��%�éa�G���sT�+o7��1&'��rΨ�K�B����-��XόE����HU�	�ʟ��V�w���{����4ymM"Դ9�x�x�f�K�3^"0���^#�p'�ŠQ�"C"�0Y�;|��RC~��X���B3��YL��6�O,�%u�ϚƷ�n���E��k�`��:�[�Gkh�ӝ��df��YP"PL]Ja&�)��K>�P��޽!s�Ѣ�)�~R�ٮ�1F�<\�.���_�?�	��Z��u)���+���5�s1x�,��r�h��X��\������SDL�I��&��zS���/^"�`@���¡���� 9z4J9누JU��1��N��3^�1L��q�=}��o�{�#��0�twy١/��N���m����
RpVܞy���W(_�%K:1>��Lo!�|4�j��d���	��ꆰ�|x�0H|1cSA5w:��;���͙�Me����`�Rf�xb2wcRmJ�K�.�� 9�~:�t�9����3�p�k�Z�\��^NC�������b~�V��v�o���n=_iu�hԟi�3ۢ5X�y�<���: ��#}d����B�(�!YG4��A�z�V�~&-�
 W�r-��NHp�a���٢���6��P���*�5�rs`���⌆� 7 P�c'kδS! 8X�'a<�u+"?��G�LX�aj������a�h^�OC����r��(�@f�/Z�,���3�g�v>�kN!�<=<�b�����E��$�.K$n�J ���G�
u�����MGq�!���z�u)�0����o��x�j����4�j�9Y��m�D��eK2��_x�R�L4a���+9��J�E	+��D�Tkh�CY&�G�t,gxrJ<B�#���sS3�)��!r�_�(���.��v�ۘ�欃������Et�Z�m�%-�9��k�<:j��%���ӱ����?ckjp�]��� ��!3$��`*ty�U�>[��z���q6EOճ!������={A���י�xn��O�(q�K��(g��{��[��rH=v�W/�C�}U�Ae- ܛƙ^ec�Y� �Pu�V�"���ljm���eً�4�!����fk�	��*����n���dx�,�L�GX�o $��(��`t���y@�QoY�6;E  �b�߯�Wp���p�6�dY���z �/��(h�����e@�e5���Dξ��%�'`��Oj�yx��`r������U��}�Y�f�v�N�%���Ys*(H�E��F$�O�/�)ք��#�>��P׵����x�%����1c�bxMF���\�����ODU�
P��L<8�P]uI^�@��T�K��HHg�[d9']þ�~+����p}�#'�/M��f%�~�1 N�%�e!�;k����۩���#-��U�K#|�wJC������2#Y�����L�S���Y��h���XvP�z�{j�1ю,���`��`�ԛئ����n{�(B�@F�r5�sâ9A�wpE2|/�fɈW�r[X|��2L�X|�����P��
:s��j�mg��T�K�����F�KX������m_���i��g�x���>�j�I��G�b�nb���9s����hBv����bS̀+R�����܊Jh��/{����y�=L�<���C6}/ >Q̺���W/5�
y�G�
'�Q^mXw��ܔ� �甶z��YN�;OGS���'�p������s cm=�f��{ة�9"���#%.���i�M~�2w�-���;�����v�.�'���r�k���;�i�e� ��Q[	�	霸?�5~1���4L|�t7��FS�~��qyh�g����qVv˓��Ծ���&$$���.�C剶)(�r��J��Y�3e���[z��MZq�Jtim]�����k8���:F��Y�
;���w����ֈ��D�����M�M��en��&Z���m�>�b�8 �6A�]ꐲ6y`]��L Gǝ�iE�}�ׯC<E���L��8��"�=xgր5��O��ړ�dw��՞���)��r#a
�$���}�x4K(/i^���B�`�ΣQ�X��62���ӨA��8�~�-�rЕ��=�7w�L�p��K�h<#����i�·��WZJR�	�wm�q�^3��b*ۆ=y� �b�����%���z� ���y3�\@)K��g�x����lq�P)���+z��"�=���c�������V���"%�����ْ����\�G*��ȿ�|^a��f1��hLE@�Eʼsɮ�-�|.p�^?H�Xݙ�g�\�+��p#�6e�k�h�jy'���^�4�y}��(j��L��M�B��;x�����)cb�Wh��C	�gr���;�O��x��pś��h�d?D�#�,�^����,�mS,�J{������=�i���ͥU����xL]F>ݕꋍޣ9K�U�`i|8RȞ�;�W]�2�	�A6B�b37fyy�vs��fڱ���=��<gŋ�t��Zh�#��`Q��KIr,A;E�,d[�ec�eeZ>�飫�Ma��v�@��_�f��5�&`U�S_��޹<.���ޯ��lh�I���2�4��GS�}k4����Ȯ6�Eb���ⴒ��i�׋�Ř1̒0OU8������v�X^[�N��q-f>�ߊ�9�l���-á�=�j��S�kt�Њ8�����x��/��ǔ� �}v�U5�+��l�0�`{�c�� �$�x��5�!�q��x�ϼ�p��m��[j'�IpO�l���<�ǹ�%��h&���G�
F`4،:J�)3�gމ�DX�f޼Z��cќ6Ҽ���Wޖ����{8��p�A��
��Q��4u�/T�A4�B|�5��R�\FВ_V�9��R���ƭ�?��xbہı;Z��a�}��h�\a�>�f��$�LǢ��P�������.�ML�~��d,��"��QN(��S�0�N� �8�C����)�6����K'�UN��%G�Ҍ�:=LEh����R��.C�}�Q�PDs�M@C��f�Z��Qaꯋ�u�. �/���~��=��E�"����g�Jk��b��8E��k_��kC.�,{�ЙxX;��ā5Ѯ�4�'��~�FXl���q��P��+0Y��b�wz�~]Nt3��$��0�r��nO	�(K[~W=��� �������K���=���:�����(�+���?f
������č��_
�=�Y�O{����w��Gz���(Lɂ�_�I�e��h��G���|(w�h7��kL�y�}s����"Y�D�r�]���][k++��!$a)�\�`@òjB}ܽ#�9Hȩ�ۼ��Z������sJh���|����qS�E��|.4^$V!|�P�~�Pi[W,�2��μ+RE����w�-a���f'NbCc�\��:��G&�Xȉؔjͽ���֌8�2c��{")B�����-���S0޾���޳���V*ws]�l�_ ���L�|{$��t������X�uj1T�O�I���M�{ݐ��+<�Y�����K����#@NC�#���O��4Ђ�M�u�HǮ�㕈yqG��/¨h��A���*��b���h��T�����ךx?�{��c31�1�����Dx�R�aU6�6�L�%q�jP���)G���Kچx��~��������Gk5����{�`إb�H-�exooic�\Z��!ՙ�5?�X7A��p"%����4��<�xF���,w�5B�59�[�GW����DOp��#�U%߫�(�%��쏣�����#/~�k���
P(3K[�$u�d���`j��-�˕	C�������M1�8.��՝�_:��-���tl������ 
����ޗ�s����C���N���	PYK���M�vӮ���_��ؒ�Ee�㼶�زr�?�pÓ�w��x�`��.��u��c)MJ��3��؆��=�7�գ��I��0� 0^��bQ�N�y�����R�������Wub>����x{�}���X�Q�t}z�R��CGk�xU!�|�cf� �"�1%����s�����j�̿�O�喫�������=��A݁��w\r��Qⴙ��[��w`��y��~�FuJ���P{�r_a]M����W\S$���"�����i�hsx���Q�&�Vxz�.�=o��!ymP��[*���������n L��o��lU�_:w�$���+��r"�H�c��u�+��0�����hӔf_���am���%���7-A�|��;�yy��X��Ճ�q�!�kq6��� �mW3T���!#��x����y�F��,>q�ۆ%���
�%�,=�}N�����������OS�k��T�#��5A������n�z6BȬ�ئn�̭=��6IQ��M"O�%O���X&%J�k$'��WJ�Ǵ������B�ή�2��t� �}u���s���Vp��|�2b����q�����M�'�	����Zg-�Z���W���t8'i��d�V	"~$2>"�WB� �)%I�1�L8��1�-����پ|�z�]ֵ���QB�A$K�&��0n5q昇Ue+�����t�-��Fo��w�Cƿ�J�y������w���k쾵1j���#�H���l��PMn+���|�������5���v� y��g
��򄝲�V�/�8+��a�b�&M�5�'l������Jv�җG�RInώ���4*h囦|�lvw#g�<\q�B�r��pB���6$
����w9���.�g)^q����['�*�1`�ohe�J�Ũ`�iҖ�r��b3]-0��o��ȕ]��}i9\A�%���t̅-j�?ο�T����	+,-iAK�n6۱�{�f�N���+��o�&�+��SStN�yt	�Pc��l%���r�j�g��"�(Q�l�r��ܕ�����5P��5�Ԯ��ģ}�_2[PK�ħ�ف�0p���|!.��������k��Y�><��q+�����iQ���G��"W:��S+���&�Up�t5SS��1��+���D�(���R���OZ��j�4imyGy�ҟ�"�[V�%j�����kwWkCEa@��UF�ѐ������g��g+��;ɂ�I���sF
�m� �(��|3N�M��A���k�Xe�uƤ�T$[��M$I���=ت��@E��[��w�޾4JWU���_�ҮH\��=��Y�
·�I��K��̮kD�E�P����9��%E����lK*^@���v��L�*�1�9ϖL��N�ZO�G|�O�TEv
E��xkUc�P�A�VP�NLG#���V��o���̈�߮9���+6Y&v��MF���v0$����(;�fи˹�b�r��u�fz�w'���.h� ���8Su�=(>'�sG6�mW���������U�u:0��Qǒ�����Z;��ɐ�L�1t���:aD�vɩr�����i�城Bֵ w���b�9��-2�:���y���S]O��9�&H:\�_
 
� \{��&���J��+�H��������`D�_o^{�w�=���ő�p��,�S��=�i�cL��flX-]�j^��9i��.*��r�c��}�6�Rf�00�v௶�R�g�ܚn/{t&��X�-��ū_T$�	���.v�l��$� ��T5�B�ܬ(*,q�WU%Lk�I�������`��I�/�5�5�-��(��{]D@Z�7|.u�B���q�S#��I�ٳH���>P�@�&lB7Z:s����W�<�~)օ4e~������%�T�%�,���f��T\�D�3�O�ȱ<�PE�Ԁ��{S�v7L�6zl�S�!�F�k��9@X��OX�W��j����9�M���	%���NX��dk`0�ڔ�&�7��U�����p_�x�_�H��/(������sd溉@�S�m�Uj�E�Y��(���sx+5u���NuQo1�8A�ty*���̓:�%��0�E�|z|�[���Y���q���M�^*P^�P/	"�$~\�$������ք	���el��GQ����0Xo��UY��fmN�E":'lv��d����R �����{��ۢF�$Q�T����K���fO��珜pzŸI��ڮFr���kx	Z#������� �V]��c�wTg~F{��=��;��3�y��O�W74
�1�A��Hc���k.���*�����ͪ��'���(c�;1ղ@�\SR��O%����)�E$��^GI�C�օ�	���?�c�ƛ�)K�9��VU��^J@P��X��=X����ɶ<@Ω\$���\d���&�]���b���'�H��㭥$#��kzȐ �l�W��A�g��.-oi�p(�m�Y��Im��t��Po
Z��)��Ə��+�CC��B�J&5��lw/�C�L��gE��ظsm����.�{v��
���E�o�[o.j��|X綐w%X�qqaE�*3�|5Uܱ����ݩi�q�&��{����*iv���oVj
P~��Ч��]�W_�۵�%�;�@����9koঢ�����:`���X�����ǯ�ٗ(FE�M�ЎNy��eJ��n#ȏ��I:�8=��،�ع���`%Wc��[�"eE��?Gj��[&$Sm����y��.�f��K�~!�]�q�mb;��-!���
_�[k�:j �q��ᚢYAWl|8ň��q�H3%3iZ����&�CIp%���D�x�yb�Ͽ���)�D}�#�*��]�)<��Z��Ij`�5N]@+v�� r}ᄔ#\B7��#��æ�2
&h��<C+▭�uV���U�e���5Զ�%T�i�uQ��F[�߾$k�����e�͜�#�܇>n��/�5Ƥk�2a6�.n����Z����h��,����롥9`e\���L����jOg"�;,�����F�� �|\E�!�Q~^�q�1�e�/ރ"ỽy<��!�,�wOR�U^���9��p�����i�Dh]�k1S���T֖J0S����T�Bt����Fbg�E��������>Z��Z޸�$�d6�6��%�d�*�^R%��1v��y����1q81u�Z����5�OB��-�&F�ͽ5�1�J"��j/q���d^[��a*ԉc	z���=	]��xL�D~�䅃�:< � q.��K8k���m���!0�A:IB�����(U&�>��7�}Er���r�]���[d��� ğ�@��x�����͒���tma���}y��X/�7�,��h'i�l�1�>��&�AL��J�=�����2ʈ�KZ4Y��4�4j����[h�s�
k-ݳ�C�"?�s�$��;�;�w�`���~쏍MD	�8%a*����Ǳ�%�.���0Pަ}6.�^��!��FL�$��5�x��[遥�HZND����b?��3�7�s��R����0� ̗ʼ�+9/CZ���ƪ-On��!{��ji�:��.����Źic�ya���2��S�I�x�!7k�g�(�u�MNz=��cIP�d9�/�f�X`����k��Gp��5ٝFc���*��͠�ެ}�����w����^���l����3�荰lI�D�IXjs/,�7	:�H�IV̎�ߪo? 9S�O1�S�x��I�����\O���9��m�\VL1�8�����^45֜p�v���·�
`
7�L�M�����6K	m� �V�����{a��z��~�6�bH
6;����u0�:����0�Y-���{�Gx/�F���������4�p#r!�@�??@���,=5���v����@�;���g���.jeZND�)��S�J4�l�&2g�Gf�#�L���DK�X�M�C?eb���hi?tI4:�|�j!�2�X]���Q33�l�Lh�:�-�`i�^�}���3��i93gȵ"��V؍�qC+h�i������r�?Q�Сr�����#.;�s��;�*A�i8�U�5@�w��p���f�^T@�&���o��eu��=���
hvpC[H�	 � Ǟ9_�~���$zXH9t��*:SBP�+�HݠZ����L`m-8b�!ݲ��i��K��Ñs�%w~�c� B���&F��5c4ΉF��Vl�&8T�̞p(}Di��%>`�bɌ�pu���9ڜ	m�S��L���CK��WԚʰU@�)WV�1��e'����:�>�u�A�2���.������Q'�!<�h3eҭj���e8�Bpj��$GL*�נR�s2��0�w~�4�9�?a�k�b��ON�Sլ�+%W�	:2��-�>� 	LETiY�;]���,���yt:�]�q�\3��tq�O����!�Y�ʲ7��xӂQp���ZD75��Mޞ��͡�Z�&����<�cc�ܾw�it��&[�)|]��`V��X�zu*3�&;�WF��*I�o�S�:	�wڱ�tt8sb0��'ώ!�);�6w��5né���^�̆|�f]�	�\#�2lH5��#�t��u�B?��Jj����\�>{��!}�����7�9��H�~�ו���4���r�x_�����'H\�Q�Cϡ��dH\w��A
�R0�ژ!`1wa �����S\(A(�%��FOS �?n���R�`�ϔ'��O��ap�t�p��U�j��h�������^��F Vܣ�<�����\�|:�I9�YT;'6  �O��h��S-^p^E���l~�	�m����##�с�EUXcڳ����z��b�X��p��+L[�,�ą��� Hچ�x���O�Ϳ��]z-EV���B���د\�=#��A_��Z��aG��	�j�q��*����	������/Yk|�ޮ�7��s���j��e���x��V�?�T�[͚ѝ����������/!�C�dQ�5?X� �ѱ���_8��K��2b)�:���w����,+$4>�v�z��pT�l[��������Wo�B����Z��
�D�KȍI���S�Gg���)ȯ���\!zR�wN�f��,���=J9��/�~r��tv�����tAg�Q{/*�M��~�
?ҽ��g"&q�h�����S�A�?�@�ق�C�<\#��^�W,���ޡ��y���~�"ز+"��'�����ȠZ��#�^.\�s�:��y�(�IGL���U-r�KwVk �����2��������5����U�F/Y�>Jw�N��(����c�fj* �	�	o9*�i�D�a��F��Iv�75���������Ql��0���������A��7�DƑ˦X�K��[( ���̢Շ����[L��v\i+�W��"��jb��!.��E�;:ˉ8[���,]�^�>���4�ݲvE���X�R٥~���:V�S�D��+7��	f��Mi�
�
[�<V:�sn�>�Sm��������G4rH�|����t�z��6�Y2��y����!bc��d�I�͚ð�Rm��]3؅͇ؕ�����޴�� ʝ�jr�ޣOM4��+��h��[{)�����!��k�_ƭs�q��E�u�Z�}�|��;
�EF;�D�qu�?��R,��b�u&vN�^h���m��єs[<�:\K]i짣��0+NJ�>ᨀ�&�5����t;�� �*��YEEC_���aG��'.�F���,TNf��^�L~XY�d����y��V�އq���"�ސ9ꋈ6���Ts��K����y��駴�}���\���]�����k��ܜT���R��D��~o���f%�61�ƐV�|�P4/6U��{��<Wۀɢ��<�e)�6�SƐ�	��u"Ѻ��~T��m�Š�K4p���3z���*�/\1Q9:�d�K�������`���#f]���G�!��О.��M����/"$�h`{�\��/������]ˌ�*jdArs�y�T��>�T��,��[�_���A��lbtm�c1��F���h@M{v㒗���(���1'F������7�ƪ/PO��R�CdS�a�7�S�W�Hm1�Sh�ߚ%���s~ޟ8�����	�x�����E���T��8/�m�?��8�غ�
���)&���R��I��"R���Y��Z�r;�e�"|�Ə���i�/H|����ohr�Gc�|^)�.M#������Ls8��|oI6M.�!�$ɰ�,O���s��~��bc�Q�@7p-	��G=A:��{��T	"v	 ; ����L0�$Sg!<����^����,�g���#�4j�"�l�Nῲ�����Z�n6M�<ڀ�B�D��/�Г�$���q�R��Y������Z�l�M����G(bg�fbar�(��'���5�����5=j�	��%؝��n[�b1�ZM���pO�%�턣��##�@���95Q��$��!Rg0	�F���=�X�X?~W(zu��H��2��=3nr06� �/��LQ�}�3B��r+�WM��JFY��;]T����C�YL�:��yS�d��%��2�"��V�D
>܌�5āΐ{��
����\o*��u%}�Y�����>�G��+9>�r}�w���;����U�Zs/��V.�@S)�$�ɡy2��/�3��#@�:,�)�2p��.psW.Ч�@��p:�g\�5�drՍ���!!�|�/jH�ÿ���� M5	���X�O�8�nW�	����]k|�{�
��>�m�	k �w�̸��S�w���΄T�4���Wˣ)`)p����v�m�T�mJH޶r�<�ԓ�j�-���o�_
ƽ5��+9ˢ�[u%�{r=WT���z��3�7�gd�bg�����jm���$,���-�$���(�y���U9�.j���4��!����qZ�CAk���,��e���s���N�dEӛ�Q����t~H��F�����P���F}����%ۑ��1������َ(���pu��~7F��Q*��Tk Ս)�#r9��M(��Hx ������ŵ��5cn���OY�8גHm�C���x���������λO�h�������#U;U`�D4;u9>`�ۏA�3t���u�R����GC���J�6���/]�<������%�bި�:�l��A�{	@t�H>�����.�r�y�	N�S�>mX֖��{P�'�.�NV��R2w~�]��|�Bұ�;������>ݰ5���4��oq(�ytb,�����9j�)�Rr��dO����O�D��a	�$PW�b���$ ŰR��珛�����Sʹ���&��z�jh��^�;Y;��,����e���?w@`����|�u
�U��R��l�uP�5]�g�tt�*UKV�Yu��J�3m�R#�U y
�6<���#S�l�,��,K�4��8֤ܧ�9O�郾� ����v�� ���|��Į�e`�:��0����O��+���D�$�Ac�iႫ$�7�nr�?a����2��
9|�U3
�dO���7�
Px��۵��$d�D�/��& ��*�li�EIݽ����?����?}$�6�WMc�BhR���?N�L�1�L�zHDəw�|1��4�Q�N���kuV(>�ICX��$S��b 
u��3dA�$�B�����.��X�V�IE�[�l�+���$+����g��ꭓ�iM��f�q[~r�F��/1pð:#}��&���s�v�n���B��;�/;��f5�؉�n��o?�x:�t��־�FY��������.������:2�X�4�W�\ǲ�Q��.hNZD�O9�	-�s^g40w��s�+;_a��㋷�:��w����t��49�x~$�Ǵ���H�2�����;:O�W��|��tI�}X�&�MU�:���[����<K�Ћ��~��lĮ�)'�7�L��^�fh���zK�^2��`bu|]G=��@�?�E�=W��Q��@�PC��{G���\�h�qͩj��Q^:���tʗ�D�u(�
��8�,=uN�����/�}N����Q�7�)(d����%�!Z]�񵴽�~tB���h²C� �Λ�������rњ�RutA�E�Tͧv��"��g����W������X]q�m{�5Pˊ����:�nI�K��($t���ҩ�F<1Á���ine)�{��^����9�d���G$?�Ukv:��O��.p����� 	����g-���8~>�iiP�Ue�C�fq��!���Djqr/��P��=b}�f�
#�!�B$+H��\Y�Y�{c�qOV�'>����խ�˓+8�t`o#����C�7Ulյ�lk��-��(�F׫"\��Gg�����x��0�������< �NW�=�W�뎀��	K(�2�<���K���%'�Q�Ժ�O�݀����#�'l��N{ͮ�SFb�r9C	���1�]�t(��o�BH7��������qI�49��u?/�H�Ŕ+�U�k<j5���ow�����iP���W&���
;K7���g�ZM���ZrX�W��js��C=[9 ��/��%T��e��y�����xD�D/:G��+��/y]Cm��đ^� n��4ӁL,W���E�:����RZp��-��q��+_��w�W�?ê�bCש=�L��0\�RȆ���uA�#
����E��I/w����~��$�׹�6�����jLc�V!�`�/@'%�l�"$+�����"=��$u�s���;@4�r1�k=��̛m<���9	���.�!��z�2܉&�P#S�,�n����	��<Y	J�I�T�,�٨G������O�lWk��f���KJ��1j�S��/����FOāEZ�~�E�`
�m��f3i�I||Ĥ�ސ����)z2Q�]�Di���:��3Y�,�fwX`�{<�
����`L�~s��$����B��"9������hccE��l6��J��)�*@�T�k�����8���P�aLy��ORIXl��-�Ue� q���I��[��!b_� /9_y���ހ��A�YBf���I_�������1,lֳm�^���D��95p��05yZ���HΠ���nQ�l#�%�k�n��q�!<"b)H��e[Nvf���J&^`���#Q(b �)�	BM���	(`���efk�C���o�g�җ���EA^���͜ï��g��$45��d��=�����9,�򤿀ֽ�d,`���@Ԥ�;)��1(���aF$j�|;a�5Z\3V�<�R#ʲ�Ӿ'p�EF��q��qJ��#a�2�+0��8$j��5��B墟$�Y���6��� �Jf��x�u���Ҁ�@��]��	���W����oA��}����u��r�k��qi�<�O��AA����I������(b:��J7"����[��p��$1ńn:��Н܂��,����w�����Xv���}m{�e1�_<��f��H��Y�[$����0g�X�'�.�Ϟ�p��|w���<o���G4�<bSO^�hálY��l/��%eC��9���*�闖دL�.D�yq�ܤ�U��$9�.�.�5����1p�w7�i�#e�HU���u�5�$G�rE��F.8��h<7�jQ{�<t �ߡc��h8��}2m��l̫��5�p�zH�I�|�iT�4|)x�^�%Ƅ�$Uj�m�,��b,l����u�L>}M�R�]��"�J�#��seZ⾸[$�1��x%��dT���Sp�k�� F
j3�""�67љd��R���Q�ͧJUrJL�N�o	>N+no�$�Fd�'C�6��d��L��#���v&S�����r�ן�$�
�tq�s,n��r�?�9B���Á� �P��$��Eoӯ�K�'=�0���������|V�]�Ƒ\��na">�#f�`�R��v?�.uC$��%�{Xo��o��'U���HX��e��[��2�g�_��#_ޞ��ӿ���5��7���GS�wtZ��,b�)9r���"C�r�LXs�d�"������� x�Y�#���9��|���O%���끢��,�D�j�u`E�Ld�'���j�%�T��x�V�ɾ��+�,��\�=,��ӏbn��M�W��U_IUۘ�������r�ؔ]Q��bBF<h>����!:D��*�E��Q�N���)��"��˪�h�@я��DF'��`�q9!�2
0;�M�s�FܑMW��A�~cO��Y�vW�Z�VoM	�~f5��G�͓��o�&Gvrͽ1���+��]�$|�>tT������V��t���;�w/��]a��+���.�4�i�D��ði�)�ql��(n,���,Θ10k�̯�,�`��%��:D# ˖ϊ]����
��I�9�m�r�]�`��8 �{!��5E���0�����M���D�;k�I=;��O��ھp��T��X��V
<�c*�mj���l�ĥÛ��<���~���G1���SS� �~6�[��r"�~�m:�J���u������}7�w���M ��)�('��WX�����^4��|!=6�}fY����;<�M�|�5L�OČ�ot"���r�<������3�i�Y[r�ɪ�;�u�O��j�����
�>�O�1S�i'`2ݤ��!X�M��&��G�.�( xp�#:���j���G�!�A; &�K�~G�1�HzJ�0HC=qJ��R�,I���a��A�m�t^�?�9���ύJn6bjm���9���UM��hR�P����٢I� �@sa,	|uR1ʯNܨ���z��7k�ǧ��O����^qg�C�獬��{��%���ghi��u�� ���ԗ%�/�ی8��l�t.n�s(A��_��
aRzVK����	w�6>F��Kn\�vi � 4�u�p<��|a#.R�_�&���
�6\ve��eQ�t ��F���\�P+�u?�����Y¥�Q����R���<{���ԙ�H8,v��0p!�"�fT-�&Uk�A�9�Gro���7��U]�obU܆�ނ��w��W���Ŋ/UV�Ϭ��1m���9/��K��3�!D���`���T�I�X��d �6��W�6�����;�E�{���ׇA?�VT��>Y��sT[6Ϲ��B��f��Wc_Kہ�F��"�����d�d�^V Y��_6�����h�.a�~}�D"5��V0��n�y�Nz8u�hc�� G������w��x5 �Tȇ� �ǏK �6�@���a�����Ή�\O�4H�q�"��(�4ٵ�yUB�/�<�ɀ=� >ĩ���)�5P6|/��%�$�@d�)�����3�|��(ۑ)�G5�@���Ez��o�Ze����J�g��bX�s�-�N�G?�P�F�t/zq�6��gk�VWp��--��T%�'�Aa���DOkxp���4#rh��J�����bt�Myʿۘdj=9d��ָ�
�1o^8ǽ�_LG6E��Ċ7����V��+F���
#<��[�
�c�	�1~ȞS�a~���#Խ75�șкczxA�l������!)�*��S

���9��DG�4i���X�|,�^��R�y,��ʫ����2%�_���1e.�����nD��g��M���<ۈ֪��n��A��Y~���Ҋ���zlC��A+9������2��:͵V�/}м|�=���'�%ؖ���⸝�^v��`��^N��CWbO+wW�E:�<x_J�x_ r�zjSY���U�����3j���Q��z�Ѯ��C�u�L�h�gYS���Q��]�+2f�f�`��4�X��¼P��� 	��&�{�P�M�+�+{�������ȟ�2�
�i�U���ɛ�.���]=�GK�T�B]1�����>
��Bb��C92-�"����֪^*|���r|V[�zLsJ�vK�ȁ=�c�\�b`�2@M�_kFu&
��Ќye/�i�Ί�lQ.�	sg� 	"w�k�����T����L�`P��Y�6�O.W�;@R�+���n{������ܔ����wtX!��C�Z�����~ӚD<zbM��R��2ZD���ɫ��g�r�<?�^R��V��4�/$�)?Fjr��9���xy�������Aw'�%S4��XF��$�F�[r��� ��Ly�"���:T����{~ޒ�U�����MY��t�H�z�R���*jl��[}��Q$�e�������h���/g^Y���lB���{�i�o��]��!���Gme]����m(P��a����4�i����^!��%3��H��k�f�;��o�����N.�����!vr�A��o�s|��w�"�!��>�]���H~6խ��ٙ�B���eA�?1�9R,�.~�Bb���LF6�/��>3�]t���α}4�&��Nn�@��o�U̯͚�g?n������R6�����ḱQ���S�gȶݟv�TnLK�hZ@���+Y�	lx�Nズ"�ކ�_�lSD:����������� Z��ɲ�ܾ��o]����R%U����L��&���2v�M=��;a���0�?X��R��	`P[T^ή��[���z�|��A՝�&?���I����鲮��; {^B�����c�I�{=
O��.l�P�T�>�{"ޚ�3����_�4�l`!;䒝N�3}E;��:�=���i�7�4e�e�
e�E���n�>��L2nH'W���~��ŭnn�i'��,*7=����J9m�J� �4�`b��z�(Pؼu����'�!����6����A�����%�"���k�Yځ�G��%�j�*:5��eZ��f�1������ԇ�v�;�Q�"�l����o�ع7b:������[<=��L�	恆P��Ǳ����9CI6Q���;E����L?M����	�)���.7�_�び���1��Ĭ5�4o 7�+D��W�����k}�9��0�"<2o�1�x,� �7K�˓PY&��`P��P��G�t�Q�8�}��Y����6+�1vY�NK��f[)a�]�����Hˢc<|0&5>�@�HV�AH`���M��_M����iFB"MKvF�{�L� �JJ� �m-9gaS�#�K�TF
"�����35F��( ��5�,��M?�L��^��%�p��=�!]L�M����H8|w�j��^Z�L��sQI�����`��d'����y.�e�/) ��|�����|�b�I�K�͠�Jd�7��C8���(��㋕��<���z<��t_j�JZ��h�̔��$�1%SP��<�<!��`ȹ'U�M�״���  U2�)`��/p�c�<��%9F�����s��k;��b.#���'x6��ĥv&�B[�Y��ૄ�7t�H;���y��k��JǆI��Ё�_.&�y��G@��9�!ʭ!��)��Z�3a�#�_ON�����
�9]@y�2����OG���I�.6*" ��Dj\]0�=�36t���l>��b՟�1���`���>|�}J�T��O~|�V�Kf��ń�<�M*�x ���}(F2:�'-����m]��b�����1�x�+}���kyR�=T #7d��X��;�W�p�ԅn���&t=����^q13���E� Qمp�F��W`�kh�B%FLz����9v8;f�hH~�Y�ԕ��k˄�s��:z�$����%�W�C�hb���Q�/C?qpT���^A��&y���h�V���6Wz�Ea�z�y�X	F��J��O��q��bS�-��K6���
��L�u�0��Ʒ��l��_����E�;�7o�^`�/�X�$����]�j��n�+$��Р����ԛ\�ȠxQ�}�dv�E�T&��ŭ���9�Xzo�`t����D����:����xsd�V������&r��nq2Q����>{��kz��fN�Bl��9��U���Y(�RG\�!q4��Wi(�O�x��$\�)�,�ڿVg�Lb�����)ǀ���"��8��g�򑨛�VCDZ��`N����M\�,0��=����R�)��C�h�H��;�r�J�}�^Ud���0�N��Q�^\H/pz��[���V���='��@¨)�J/1R�k���ř=�u�W��;�֪��}��H{��ҿ�i>P>KD\3�� g=G�K%������;����h��+D/�"��<�:��'����u����B���(ݭR�uM�F>�g:�{*�0���߀}�rƜ7m�S6N�7f�-f�7o�Z�j�R�m}D��.Q��bȢ�;�f��0��w�]g�ĥf���6·�6���i�B]cf�ܢ&�s����٩-t   ���Y�C�-=�k$^E�	ǰ�$��Y���`IN-��92���DB%*F1{�T$.�q�} �I3KD�aq ݨ���A�[�[��P����x����&-F�+�=
��G��W�1o"�u#�n6��QH�R�X U�tJB��B��C}�Wr!Xs&!�.���~G6�hR�����$�RO��<��$Q4O�s��ݠ���G~bƙ(ռ���p�1�-��Xɞ�����e�T�v���D��Q��F����u/������ݵ��_O��5�r��,�L��K���F~^��^�a��$�wZ�� %�RG9fGs���C	J6��i��{3���aUlm�j����դ�E�ƻ�V��rN���o�a����� 4>��?��M�+��}@����BnUR3�
�Vw���E�/�R���1���Wf�ZAS#���6&'���Y�4�����C FqAAW���H2Y�i����Sqt�ԕn"�p���m�Q��i��"j�	� �TD,&J��8ظ`t�i�B�>k��p���Q2m�U��F�}Y���g(�@h�(��A=`����Vo"�Y%D�����9�,�
d�Sҽ�D�����)F ؍�k�����^~
�b��Y�'���)�CS]~�`����4(�K�r��[��k�N�p��!X�������>ɀ����%4%%���Ȫ�|���B���&��#�Y��-c ͣW`�qNP.*]��@	Jw�[�����@��O��.���Y=cI�2��n;�6�'�����/p5d�JK �������$K�x���O ((Ƹ�?M�S'�
lV��6���md[��J��ӕ�i��.�TV%AA��W{K|�4�2�li�Qs�"ꓨh���n�+BQ�
��Ǹ�3W�m[n6땕Z�H�HXP򇷥<�y���ʺ�!Di徯z��K�|�@mUV��5�n��3a�L�*ثyP��Z�(�L��L��4|�P��_|G �0�q/�����UL�L��������x������[����A��5P"���ݻ���5y�@�� �P�J8�BZp����_����J��p����pn��"�L�vg�cK73���a
����&��9R����\Uf���!�(��|�G�aX��c���������r�"Z'�(`�&�`z���6#^k���ク���a�E3ϓ�Z�bEP%@ ��>U�jf<�c��kuʹ(02��g~E����IU:��=�Ϝ��|>_l@kZ�¸78������7z W��89z�S��A��2�Q]:*n�8D��U�𕗟R��ۤ`4�<�nr�s�h�b'�vK��� �s��Oj�
�o׺�h������C�+�wh ��4��TuSɰ �Β�2jN�4-��`	c�p����Z� ���~D����B�-Lו�f�h��jԓf�ר��� �KWI>�����T���e��/�y7����* ���MC�Eη3E�N��9��k���'�H��8�`W$���C�sPՑ�V��F\�}��7���0��h�cVi�yjRV��]>�0���A�cx�I�Y�\�.1���D��vߩL��?��@���h2��sjU�<�_��;�,�_Z��v\������]�W0�Ý+��u~>~�'���^v��=f*����������ܜH���U���;a�X?�AI%��X��f�x�K1�Ic�\��-�~�ޝ��\�=
"���@V(I�KA!�pQ�*��\�k�y70V+�8k�͵'		�a��M��0-�zQ�CS&�r ]�1�rY�3��H�-_�9|c��	�e;��W���L{8w�	���I��L��:�g�{���c_}�vÑ����˚�!��x��`����*B��P3�� �4��\���Z�Xx���Z�Hsiym����?N�[��j�{��DA,Ie��ta��Y/	��mTd�Z�y��g���9gQ��ьS˺<r�>���䂙���@8WUD��oe����U8��"�����`��1\D�
^K5�,5f����#�G̓�Y��Mщ)�YQH���*���-�(�YSgN�W
K�2x�6"�P��@��]�<����>���pe����5}��֛��wH'#]�!=��L�E������s����i����IQGE��4����aڒ�&d�;���}L55�
t��J�[��??O*��1h���I�ʊ*zb�i�}v��|��<5Go�U�Mi��^U8�w��5�a	�{��伌��懻^Or��}�N��H6��OzT��7������||�����0�����.؃t#�'i�W&���2#C�5�@G.���\VωմF��^t<�i��yr�}���_��iI�*t�+�'0}u�j�ۦv�+D�p� nS��Ah��s���Ai�������GX��U@*�$�duj�x?n�dqq��(Qh�c]}X	�)�J��>*��G��h�=ٝG�`�[��n\F�i���"5�Eg6�#r1j6�_�NI����H��q"��n��#a���1�)	S�R�������K+ڽD�ݹ�cN�b2�D��t���lto�7�h�QZ��t��U�P��xļ=�/"�j)�����07z �Fix]�� 5e�Vf�+yV+�>�ղ�bM��`V����Q� !6e�٤��	��2j�$���T�ߵ�ݞ9zX*+�����J��.9̻�k���nV�V�I�*1ȯС�Q��`�%(-$:֝�l)���;S��PR&:�yJ9j�Up|��&���\'��N�g���pqf�7�N����m����d��PP�9�n�>�>��t�vG�L���!�Hf���ɇ�̞����*�z�K�߇iz���ܓ]�.^�h����*|�&g�(]I�=��r4�8�sT��<4��4�௳p�� ��E~<ɻ�i!..��R�)Π_h�ѓ}��I��!Q����7�U��@�\��]�9>2�B|����D"o�|/��{j9/���e%������X��gX_�?����w������ i���G�T���ˡd#���?�єJ��v(�N˴7��`�&�Y���s�f!�.���[�e���՘�} �)q�K�%���3��ߨ��;��6f\���{�[�,�X|?��g�)��hp��>^"\��yu\��t:��_	�ON��,++^���Z���:~����:�b�����G��9��̊�G&U���ߛp��lF@H�Ǩ�"JXB=S��ĳ9�@�Hڄ|Ğ�Ui��BU���l�q^�\H��iX���P(��C����i@R��ږg^��r��U���s�xi\�6C��ʃ��fg���ϲ�\� ؆ԁ��
�U0`��{�1��-2���^�΄��>*�X�%r'��Nz�j���_<�+E�t13;������/����D%��$ɦ�bc�T'�ߵX�p��>�$��_(j&�){����.�2�gz��D��&��6�w���)���δA��u�Ժ��vhCvrs7X ���G
������=�E����[�Q*��O ����-�!ܩ��h1g�t���cɉ����Ń�;�{���ۖd�� �YyR�r�_�H��*{��0f39��뫏Wl ImjP�1GFg�m�������l�dŜ_�K�<�q'�n�561�yzC��m�
��>AJ�˂+�溄2�y�|������O��	7aʕ�7#������1�G�ݺ`� kw�����V�����<�A��X���U�qG"�?�^�V������	*[�dh����zO��/��)D"�8P;�%���*��=ֈ�T�o��?�,�h�E�v�H�K�Ի�u%���&!�U�5���Y�F�;ִ�R��k$A��+�В'��i_$��y
e���H�/p�K�	ez������J���J8g��'����n��]�}^ϧpX�|Z7u�1�����O�x��5�7ܺR���YfDh�l:�hg`8)doP$�Z��N�S0&�i{-Z˪�h�~i�w�G�
8W�Sx���Ƒ�|?_ B��B.��;��e�Rp�s]b�*�ݏ��Q��?7ժh����ܭ�!sj���>���/y�_ٍ���$Uߒ�Z&0-��6�g;j��hD΄�w��?�:}�>�{�}�p>9�����)KeX({ES��-�y ���_�e��X�F�Q+�Ȭ`��ŷ�$�Q=$��и	��{��w�dp��h��]�x���`8"g0�?����\Me7��}�8pݐG�6��47_��ק��   ��/���� ����`�@��g�    YZ