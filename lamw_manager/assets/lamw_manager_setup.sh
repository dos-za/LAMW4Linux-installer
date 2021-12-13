#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3427824020"
MD5="77656fea032d602b77481fb8f9f2198e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23924"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 19:24:02 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����]4] �}��1Dd]����P�t�D�"ۏ�I��}��F?�TgF��Q���}�ߚm�NtR��g���a5��{O�12��?������R�i��m_K��SBmw
��CDGf�����>�eG����86f���]�8�.�ұ"R��ӯO	c�ͣ���[.�a٭z�BZ���C�2��"D��[�!b���tFCQkt��3z�����OU(���K/~���9�A6D'P+�1��L�Õ�W�" ��+2�k��_�θ	��ss����3�z2�Z��&�E/W�=7�l[�e�C#N* .����P�+<!�|v(U�q�A�@Pʡ��xVr�P��q�P�/�@�R�}�E�1�{P�Ϋ�  �j<T�XkS�-љoI�����K�"�{r6%�$�^L ̟�%�wz�-+�m}��ɪ?�n�ށ��(ܬ��S'�v�8�BH�,P����nS���G<�6+�HE��ԤOta�1��JU;ʖ��B����׻����`~�4��'`���tU��f���j}�=�ĜvSE.<N}�� ߁�o�cc���vj8��y��+&��u�1�6]h��%��<糽��l��S����3�K�c�NЂ��g[��0u#�U������S���C؎��FϮ�r�,,�ý��X��?�a"�$�Y�?4�s�P����	��b��/�`'���4���αv�X��o��[B��B�ߪ̭�N�?kK�p�x�<>=�%��yN�8W�D2Zx�}��j5���w�
P��3`�A��3����4쏽�5.ेb]J���g�j����;CDGH�6+�y:�ۦ��0���5���!�Nޅ�wA�5�U���Ǹ쯝׵%��xwS�I�pBzd��A�:6��(���0K<ճ]��gֹUo�T܆2,FR�d�y�����(S�k�z��+o�P"��-?2��a%�\�n^��xeEMc�yU{��J���=؂�z���l2|��^�]�����oc�����v#ڃ�!6��H�U�P�7-yC���.�d^�l5뮀EG���}���x���}G��Y[%�/�p/1n���[�JHy}fK�*��M�u��<e�*�i�� K^��Fג�o��y�2�{��h'���h�0�߾��7OGtڂSe}Ǝ17�eYѼ�����k�Ü�)�xU�uP���[� ��M�C`R��$�������QJ����
{���Ԏ�k�^�}�O�'���cZ�U���e�ԥ��L~+�PRP��I��w*b������s�J�dᲆ�fw�h�7h�8����[J��s(�SV(�����8�G�="�*ū ��&`�ĕ���M�gq@�!j���F\��g�2����Q����^�A�Ӡ��q���Z �D��h�����t��:�������H�貣-���8y�h3)��� Q��ْ����R�8^9 $ ���~�~Ѥo;M����#pJ�؊����"�TM@O#8��8�q&��x(�_J!���;�S$��Û�����,�/��t\��S�7z�B|ť��dRq�v� B&p\!�/�ʁ�Ģ{Q,��5p��D=q�q锞�B={kx���jԹ��;v�H*������doB�J�r�`_'�H��1+�IB�X+��O���L����t��BR|�P�;�9�aڔz��P��?w�D�/�Oi�8��_����A��Z	���`�Q#Zc7�A�|'�s�Jݳ\H�#�%-���a#Iv��yo��ԚlD	u���B����r�kT��ݿ��;�;�O!A"�e_^�Zy��)J�R ~0���jQ:��N|�L�x�A�������|S�K��*�4�LlZQ��5�,}����=��=M� N�'����<3Y����I}Bc[Y~���*5W�.{��Rh��6����>��S>K��st/ 	.�C��#�_����4�w�-������T6tϞ�s+{��K��Xn�;� �d
�ѳl*�\��
)%5a�y�o��0ޘ�"���k�/κ�#�B	����-�
�K3?�e	�k���&�@|�1 �箙q��g��v��*cr�Z�L�I��薋.�řk�P66�hC4	Z�sK	�v&�s}�	�,���:�y{�7B5Vp��X?�����|dK�)�A�K���	��*�����������i@�{�,�ځ�p9�� 5]����nF!�۬^3Xq����ۉ� ���p��t���{t�GF���'a�H�O:��*ZQVk���])]���H��Z�Ö�X�7�8�g�U;@)r� ��_�I2T��x6��BT��$<Y���\�8�y|�*�bž
N�#�e�Z�d�{�.LRݕ=�oenE?���MX�юv�sX��Ǡ��O��^9���ɠ�Ct��Kf�=����W�ŮV+�$F? =��;r�."e��8-��..�pA�邾�>bAg��&	m��|���NL	�!e�$,�|W���!��I0a�{�dh�>��U���}z�lɫ-���}��NR��o=�y�%�G�j�����>_����Aj���狂	��O��A�S!��0	�""�����',	%��e�:�s]�a{��S������3��K�N�HKi����l���_�|�R��zC�_E7�O�t�Uy,�0,�kI�M��*�yP�8Q ��]�.��˴�Dl�`�W+�L~�������t��v��87��A��)c�� ���!�&�;�K��H��ƒ߲f�26����'{3lQbNG�Iynn_�?˺^*��>�6o��"�bfK�} j�,|��M�����T���m̏6��ԍ����k b���& �]8��%�5e}il�r�>�b�e՚�4�s* ��[�b����ē⼗u��A�,�de{gI=a�����Gh1Y]��ãQO�>4��b84��g��V����P��g�d:hu��k)����^J�k�ȓ�K���nk�hf�ь8�5��[��	GVbA�V�25AQU�UӴs�i��O�K#�j�P1������X������(Y��o�~�).A�0Pԛn��
���E��"�K�H�h�$�*�nC�^�.�Lr�,����%^n<��E^���0�b:�f��N���K�FE$Ber�W�ю���7��[��0:�8��D�,b����l��sR�ˢ���D�����r4��(��CѶC?[�:�jh\k~���s�ޣC��������a��ϭUks6JPHWsDCZ'�Q��5�sq����$${]�K��o9q��]3:P����{���d��L����7L�[�,j
h�@�z�'�ҩ�y�A���ސ#�Qj����������tt=�Ow��=)�{g o!wצ�n�J[g�m�0�	�����컉�|����k��H�x�K�}v�p۳�¢{��
r�����=K�
��e����]��7)�V���4?8��i��?٣��S�>0�c�^�[�l2�<P������oml���m�N	_1C�[�Y?�Af��$��;	�D��֛���{ں�m�x�2��bQ�t_Ǌ�ȃ5�t�ֻ��ÚD~x�u<��g"0�?�~��v���B�۩2˴�a�T��TcJ 66i��/��CW����z^���=Q ��O�P�l4��6�n�� �hr��HO�o3E�[G�2B��|��+9�+z�!��߃O�C0n��0FÈ$..l_c�c�ft���>x�]���
S��ø����� ���_������vF�����1��0��IuJSh/ۂp�f��/X���w��che铥��0��7��9��(�pO��x�7���lA��'�cd� ��c0�j�����Jӈ�K�1��|�$���|��Ac%H�����15�*�Xe�8j{�n⊯/�3�O�X\{FǨ��A	%�q!����KXu1#vГ��%���"�~�����/�\ɞ�1����2ѥT#��2BϘ`[P,\�!���9����@��쳕���<��y��z��&zt�mq��ɂ�4��t?6�)1t��
.ɾ87��Bȶ�g�)d�j�(j�����%��[� ���ȼC���M��� �`�����5ѻ@�
�}���+#�䚦��U���{�OG��{sH�G���S1�B����o�72�j������2�/�H�%�o���Z ��,�#1,��<����W��Ɂ���'��6n^k���(�+2�U<���ڸ�����΢hb%�ixM�櫌�L6梌d#�d�czh�]����ԭ4�Ͻ�n����80���.�E��/}?��K���
K?��l#ڑ�Es�q��R~�m��@&�!FS�QB���T�.?q�EK4�պ�%��&��F�zzDLq��qQ�;륫Rco��Y�jN�#-�LR�2T~A�G��)v!CD��,�|�u�:L��ƪ<��`?��xg}Y���
r���
�N�T^��8K�Bw���+5��~��!���|��>�'Z˅���⽺��� j��?�ڢW��'�A�������tU�����J�K�	���JX�Uhq���c�9s�|@���KE��c�z y>�D��U�y$�����,�(%?d; ��(�m�������(��f�2�Vz���e�da[G$F�d:ܾJ��J?6���p�v�I�BR��dT0������}�ߨ!χK��r�P�3i��L|�ˎPd6���3a�b7�@i
��m�SN���$]�}�*���-�/Ġ(�EY�����4�Qt(�z$pa�1 �̠4TN?y�� ��A:.K�B?l��@\��c},^�kU�00[}j���$�<�HR�4i�&�V���*0�ӫ/���!�eG��ӤB��|�[�	qx=�}}?����:�ksL�gjy�U8�fnF�	�x]��v��{��h��������� ;��ZF�ȕ>@�ԑǨ�N�j%�������M8�F�k��w����VZ�G��'�SH4�����tB���,,���H4W�C�@scc��
"�cu��7�G$ �
w�{o?����d�eVt�uR x+��3�~��ݩ���4���,'+�ԗ-�Θﴋ�L�͜
i@��i^(o����-n�Ie(^g�r,�:�Q�ʕ�W���4��wh�v�Ipɷ]��!nt��ڹ	t v؇��bk���m�t�s��v�k <#�J���W�s2���*d��-���=����
��l^�C���f B�d�z%�:�	���̱'_�{>p.	mߚ�����gi˭n������D? �?�l��q��� {yT)孮p��FƦ�q
��(�5�P����X�Y^ߎ`���T  j$�8�6GQO���)h���Z�L�#��W��u@���@��C�h�%�nm���z�%�U�?1�}�z>s�.n1����)ގ�3-���u>����(�U��[JnzZ>�鼏�*P�J��GE����P1ߊh�T>-��:bD���Sk�ٻ0��%�cv��� v݃�A2�.�s�}L� �vx�d���Pb��2(
�՘05:@�=п��4\���WT�f��3�j�`<�!�&���%^c�^�dM�	�0l�>�i�Π8���f!,0��^+�9v�O��S�+�$`+�U)j�S>��@<�6>~��J�'h|ϖ�;���SF|��m�S�j޾�nV�^j�znp�R-����l��? Nb�8��;���:e�r�z�U���7/f�tun�j�#a n��mᑷ��C�=R`-;�[�l�ז�YV��6G���u�[���V�t�-��v�4�4k��Z,����N����v󒗙�&��|T�⍠`��Ӫ@���[c�]�8*�ڮ�d�`n���EV O;������G����~l��6 ���I�`_��~���	K�$���򅓞���CD���+b�9��]�����a�m)�����i�GXF�`�@Ow���$��S1a���G*F@6��뿣�n�s�,�:��^VA��q�O�h-W��:��Q���WE������	�ڎ�__3�}K\xCS��)���V-�0�T�$�(L%�<���gu�<`��˓z3��.Je�o�l~׺����w��
@�5zP�U!�&�PW(��p��,��+�8�P����wuvh`b�,NBj6��D��lC*^;�H�?�:j��X��ڦCtgqh��Ǻ@��ز����}�+���������ATd9P�C�H�MطP�0��1�Ak��9l���І\
����&��H�h+{&��iK�����QЈ�@�'W�iG��Z�9�n����i�5����Հb�Rc���\��ԽON�#W%._�����3�k�B��?���U�J�=9����@B�0�_�i7�R(R?���,ꠌ|��ycw�T�(�F� ?.3��\q}h��u��#�ӓ�i���)xX\j]/�3�� J��"e���G����=���ٮ�˶�H�=2Jp1� 4��@O	��?�����]	!�Q��L
r?��U�)�sN�:�kR#�bmͭuۍ����匀	�B�_���0\�)�On�x �X9���So�L����Ff^\~��V��ם|�VI����󰳷�ݝ��^�A�OsF�H�ܓ����������L��ͻmEM��g;:GT�9wxy_�E��.9�A���: ��B���.��r��$�� &����D ~myQ7�Yc5�W{nat�n�!}����0D1����n>򾦐 �����l��^-�*�Fwhz�THEl��t/
�����j���I�^R�bRR���G��%���;��`�S}6io��]ZUŘ����N*Ɵ���.vV0��|�_���R���-�x��F+2�y�ێ>�.@_�U��2��#�+*7 <�� #��|0S�eb�U��;�]��b�`�I	ܗ�1XR�{c�^q���� Ʌ�b�����q��7��0���՗ڹ}"k?EΖ���(��>I��q"| ������	�!�Ga��]1�GR�\�$�C��Y��ǈ�����:%z9�D(�8N!��e�~���m���oޕ���tw�r%%�_�jgo�%��eH@]��ǟ��HQ�'�ۥ�5ǩj0��M���yUE��*V�vEY��~o�]����} ��D��-��6Co�4��\����^7�RÝ������#9&3(mS�ܩ��E��'̾��)�Y��ֱ�Za�K�.�[7����?�����3�H�g�NB�'��>��Sڥ�Ys�ʍ	����xH��>m�N�^#����/�
�R8}uE�tA�w?�g�h�D6���L�b�S��^��[��/Ü��Zb�����-����k��J�os��8�9���L��剿w��8s ���_G�@iĎڕ�����u��wݭ�\c;�+"�(
�$y��6�VP�/ц�e��ɖX��,^-���.��ǝ6 Zj&��B�3�T	��#���'�����R��`u-�5�ZW��K��`L�]=����v�0;=0aD� 4#N�02"=?��(N��F?Ͳ��6��Tx(v]�_�VARDD��
��X �����*���>�v���G��#�GJp;CpnV��I�P�y|teq�&��$ܠn4!`Hj��i$UD4!���$��������>���q���:�����Q�~^G[�C/��;�u��9C��\�	���'���^Æ����nfW�lC��ؔu��]R)0	�EY��d�m��f�ON����[q��q���?� ���������m�/��w{
�ƯW�\'�	џu�[������LF�"*F����W�6��Kly���B�ףW�SN����m����\k�Tm��eӤ��`����T���T����j���jX'ҭ�K�������\#	+�=�Y@��lGy*~�boZJ,\�Ey��$ݿ5ӿNX����;4��������ץ&V��g/ߵ
/��^I
�p&V��;?�44OlL�6e�E���0�$�ǉ�>�21#�?�dc��C(�P�� �RW��J����7.�s�H����B$��铂>#ym3'@V8<�l��v�̚(�Ϊ�q���)�?~Y��4b{�0@�MDl���1���v#��5�J��&FB�Q����$��^�[�:etF�1��\�k���;������	��4���}ѷ9���FT�Y��n��ϫ�B@6,}ac�9�g?TU�A</g>���Dr����'�s/�Y/�R�1�l�8k�ޞg���M�d��3E液X�`�{�I���n�	����_e]{�����4����`�6��͈F����Z1�lƓ�QnW2Ʒ^r�Y@�aY��癓i��X�N�����z,��~dZA���4P�V����ݓ��eb��F��&l���<.nR>ؚ�΍��f��m&J�Dצ��T5r���Q�ie��t:�@�����i�C+����l�HQ0R7��v)֏�5�_ŃӔ�KJf����[���9��� ��if�%Q:�_����Vp�O<��`H��5�ҏC!�/��}` �u����t�q�B�Z\8�+	�R��K�oܞ��5�g���?�,��6��}�#���h�Alv%�t��=W�@2{dv0n��k�p��'4����ڛ������*E]�\��~���^{�˟i&�����AVb�-������f�b���������V�ב_�u�φ�}��#��֔Y$�"�$/$<xk�E�e�֖���G3��d� �E�Q~�w�/~3�c5�x[��I�����B�S�w�i�XTop~�`�gkB�����m��B��Gf�c���=��
`���u�� �-�N���n��a�mY~?���BkB��:YM�̦G��!]]�te|3���%��;��w��CFz#8d�<���X1�:1x�����g1�לRn�MYR��⤒�G�J�G�5�c2{�<�SU��[�F��	���d��l��5����eݝ�p(���5���+����>�_ߋ�S��,����ڮ�]�F��՝g���f�F�h�84=D�K:T�׹��#d+r��N��7�Zi$  �.$�x������8e�����u�P�%�b�M�w.&�;ĵk��ᒄwP������hΧ�ꧏ�C[�A�i;�ͯO�]O��Z4�i�:f��Tr�2���/K̽��|j0)�[���W�����P��anj�wuybv"(�N0��UY
��uܸ�˘t�G(W�
����'*	�O_N!w>����P��î�R�@r �yEh���I���fY$��ޒi�ՖQD�q$�Y5%�u�B���X{�ꏕκ�3oJ��?2�a�m�+j��i]��`E�QH�*�'mT���x(����}�,T�r�[B�0��AC����H�P��\�j���p(]f��>^�"��g��Хݑ����'�4��n�]"�9}xN]-&���0ؿ��!i�ܴv?lF�e;�|��������sw]�������#l���h��#5���T];a+/�f:>��JXF����ba�����5.��.(���|�˥��L�����7�Mޖc�=S�9�A�Y�K7c����Ӓu���yD���M�]q�@�{_�)��U
Z�D�+�MЪ�sU�v�)~�E�����Pٛ�ߨ�ܜT�k��v��c��c؇�2�ӭ���@�2��']�ы�fvh韇�<�Ѵ�06�D��o��T��A�EG���r��S�>בhp�x9�)��ε:H=��笁�݄
%�����H��_�_V���#�B_�U��s?�{霝�wU�!o�66�rdv�#��oH}� H^��=�_�M����!> ��}E�� �lb���ZQxȵn��e!;�0��x�߲FM��6&�T�� �c6�\:��~��}~���s���D��BK#ό�LN�İMf��;����E�~ŵ	$SF�w싗��=kޑ r�*���V2���K�����D�>�?��y�x�!�:_�q����<�z>���|p_Kӽ�Z�`��G��E#���-��������ަ��ƈ���ޙ��9��h�@����q�脳e@���O�
�� m�S���<�x�0��Ђ�$Y�t#��v�
�����J?�U��_z=k�tߵ��+V�Fu�;]��W)�F�r4��v�.Q2/A��N�"0W�z�ZΕzz�̾�����ɕ��9.[�4��!ġT�0`��ٖ����DeTW��N��w|?�1,=#n<�yfO7��Z�(hg�=DQ��-VL��.�#�[0����F/�g�P��ڷ�r��@�Y��5���a��D��u0 �g��'����L�F����>��@��"����ъ��o
�^�붖Q�̥�O�����`9��d����na�6$��A�\���S�&�v×�m�l ��%;��;�Y=i]%��x�x��GŇ�{x���ɿn�;�Ý )�)���8M��q�v���=o��){a얽c��yו�%�%�����c�ͤ��nދpA���
�G�_\�sd�����Y#�H�D�*�!f�s���Dk� \,��mU�	k��\+�gà�g�,ު�,��FƖ��wLE�R�H�*��v&OխX�g��/.�2{$t{���撪:&w�rc��B���6r����_�v���d�u���!l���B�rX�$t�j�.�~�g�=�no4�f�4/~��UV��7�!o��ڰ���B�ױUR��6Z���#���A�g���-	�8��錢�_p����	����U�S,�����]�d�t)�+�������L\���4���))DxR+/H����>"�~�j�/5岵���Q���FH�1�\guT��n`;O'$DH��?,�K�1�R'�����_Z�K<7�b�턖Cas��[����l�7�v�D�ٱ�>�Z�e<��3�9D�7M|6~�O%���:�isP@���������|��Br�g�;(��I��SL|h�$���ݖ�����(�b��AL��iA�r=�vK݅Lx#���(q�&�p�"���������E����)6�y>r]����M:3���L}ig�F��7� S�̇8�֓�+�0�����C0�aC����j���0�����K�`r��ǈ#�K��~(��?R(.�a���ѓ|*�<x��hV�
j%�C��� �ܚV�?�OSFs�5��R�N�K �f��=�e�'o�WNt'F�SvE�VL�c��ėp�Jh|mYp��i �|��cŨ��8©��y ����!E�YcQ9Sx�'�z�(��6e.�e#K!b�
��G� �r��]4�~�Ƿ@TR���U���i�U��sj�y<���m�,��Y��7�$�)^��ľ猡�W ���&�֟�0�-�K�v�L�/h*Ǩ(�q�W	Ӄ?}����cm�0�6�������u�p�L��^��OV�9��g�&�7�~�dZDgo�PY4�/cH�D�� ���0�^��zyB 	,���
��M�@����7�$
��}��>\�~-���S�'�wn��A;h���J�G̐����Ƭ!j�^���#X$9$�s��h�*4�M�b��Έ��R9r��RT	�7̻����gM�6���D��2�U�/D�P�����5�&�H�ҷx�u�B˴�`�T�I_�+.͋zږƺf���l('R�Q�+�QZJ&Dl��}�*agC�Z�_�o�ZېHM1��\>�k�oR���]��ژF ��@��Ըsk'=�v�r	��ˁ�K�$�>E���u��+*��(r���L�\��j�M�{� D(���ykP�3֢�I�ޛG�l��K-m�75��W�f�M3A\g���xY��a�(&�bX%`Ӡo��j�����"�G�&7Ty�x��`^T�b��n=���q��YR��-�L�Q�L���a*�b�K�,��C
�j�LX�,T��i�����M�;�&Yb���p�H�����c$��g�E�t���/�I6[�MZ�r�MY�IN�S��p��+�E��h�W�@�DZ��R�6�Q��tCnz��7 ����Ƥ�1�XM�SG�]=���.���ns��+y �F UlOx���W��]BG��P�����I�w$���A�����:�s�'},d�$��Ɯs���QM�u+H\�t3�&��Ӂ3��A���������>W&�偖|�<����/H�69�U��C��C�F�p�Ď�e��g1Iσ
gq��-����m��[�5T�����f!��+��s�`sm��]o^�����u/롔�v�j�dk7�2HBA�2Q:�<9JsYI���3��^Nx'�>���;Bkl;�*)���?WЗ���"��������?�G�V�kꍆ���Ka�F�E�74Ș$���6�ט1&o`���8������I �՞����ܦ�X�P؈^j|�x��O)�Kf��Y�S����P*�7M�����j�qҝ�3�X�5�*�ԡ'|H�D%��P�3�r~�!����镨/��'��#�aB������/Z~���r� ���� ��g�t���,钄y����E����bDG�M'➈fUo[�[_�>֟�l�b����󓋐9��o� �R �f�AX�[f��I�����b�z�J+���r��O�VpCYՎzn2^�����e��޽����V�s�w�鏎c���uʹ�p�Z�4b�([`�Ο���fS�%�Ub�!�0�hX���L{ݧF�^���^��D8ꑙ�m�')���ӈ?�z_��Aݗ!�əe�c�-�~�(�ep*�LV����K�(]�o�(�!�az� �=��:m�gfu���5�@]b#��#X�X��ox����]��!\l֕^©��L��v�̮0/<�P�B�nY�:���Jg*�E`O��]&\��&�E�җ�Q����|����Qk�����J�&������~���s�RϰA�Up��M)��W:Ж�LE�o\�c ��f�˕��Nc�Yԧ\�2�pX^ߟN�Dx�ո��d�ߠ`�+NE�R�\�hݛf1��G�����2�i�t܍�D@�`j��������<�w�֜&���)�k��a�����J\�3?	Ł��	�/]z4�E헻h�F�:J��M���"ϲ(���ni;���ն\q���k���fV��wjRC��:0D��%��a�l���cq�4���eb��í>r�ߚ�(����L3�Z�0��t�ލ�l���i	�[���fUV�?������*y�J��w�!��m�+�"��}�@��=1���R�/����كUv`��TǠ/kN�D룀�������o�4��N���� �mT1�[�Wvt�\�҈��/���-��bں0������"�5f��!nu������O��y,C��~ڵe�%�F/e�t!p�U�K���=0ǋu%u1�dE�Z6�0��T�x�8�PHT��}�M��c�e#����d�N S�����VP��}a��.����e�}a����s��31�_�\N�S��QȻˢ����*s�9������Ϲc�S�t�#����w0U&�β��[�V���y߽���0B@�@<u���P�L Bxj5�}_�J��M��Z�;��T���wrL�^�� ��.ދ���EX��b_���]�d�'��>i�ˀ-p����H��@�`�heR�F�[}N{
�����~	2�^l��fF`FSL(�+��b'���u&v��-�
����'QNxK��d�z�zWu �kP��oX�o���;�L��9��wu�y1���(H�?@�;�RжM�c�s6���tQD{��:h:�FWxd_hY��d�2�B��\ۘ/�pr��p�"����u�+�# MuT��0�9Q��=�������E�]N��9�H �^��>R< Y$>%���oi��p��~^A�:<z�0 �,�)!%rh��ʐj�"�1lO��`z.�߶!���y	I���wO���	�(��p�K�{�1}�|�] @o7h�����E��K�5y�b�4��O�<��$q]8ۦ���&	S_5�Ê��-�\2z}@:�ZY�.�����d���,0�q₂�#��Z�C���n�	�c����i���J�<[c�wp�Й�Ps��y�.���ba��yE$$�}:���CqQ�9tlw��7�N��`�X��Q|��+�����_�Q�=�x�Lp�/�&�=?�X�>�~ųD<�����D�q`�|R[��V;*cA$$�	�b|j�������G�O��T�V`R�����8��(-G� M��Oǜ�6��"���ʨO�Bh�DC�X�����Lp�6������U�x";�t��0��	��nR��&���Ie�e�@�pw�o���@/Y)>��&9#���$(��"/���@�Fo��?v�c�ȉ��a�ͥԖ���,tⷑ�@=��1H�9D�?վ�[G�e(��w�H���C�p��ѵnD��e�]��Ǡm�����5m>�OJn<��v�����}�s^�+�b#RF�A�R�d{q\rEv��#|��cV��+8����<+��t��+�s���3��$����z%�����L��h7�@䐪�]`~rDI���u�m�6�"P���]����]�j�@m�8���nv���b��V٢��E�1)�����)oX�3a�HbNtX��0�0��<o���7�bU���wu6**3�g|�	�����W��[�+�Z�$��-���;�X��b�`#�r0�	��87�x�F��P�����8#`�w��}5�WF��2?@��,��lX(C�}�9}�ʛ�����o$���,ҿٿ���c�F�,Z�	6]�Dq�·B�0oQ�׼D3||yB���E֖��Ba����="������N��,	BT��[��d��w_P���]O5���Ϊe���-�E���P0̮�+��lAK�hf��i�:�N���+)oTm}.�G�Kg�9��v�e���g�P��w@�Q#7cB����`!��XyRt=k��i�󋱷2J�9��Ξi	w�M�&tǒ/��^,��P�P{O.�b�x���	��է;�'�FFu ��z�U�ei
u��'�	N�m���=�k�<�B��"�*����*S_��3�#�d�H�`�إ�����IԋD��\�/�O�`<��_$g7Du�3�^�>,7`q�@&<�d+V ~���H�G����ݯhU�'�l�*�V�b��SQ�y*��w��
H�u�Ŧѕ�g�>�'z�фFfڈ\BN����k�A���>����u�b�	>��`0�i2@�X*	���%<:�}ZX)A�n5㝌	/���l|�EZf��-�!�"�m�S
����K!Je�ы��P<�zt���R�����Z����K��jz|�Cwf�u�tu"��9z�*9�=���&Z�`5�ϸ�ֲ�����w����d�e�8E^�u��*wwS�5k������U^"�%8�#Zo�
�\^-|O�0"�+�t�	�g��#������6�;v�-(u#T�����#*>Ny�(I���a��))�¶��D��	�vޕ?RS:�[r���h� Gq&�h�%;�L}Ps%)Q��:�7�����$]a��x�yy^�>����S�(�a����a�����ƧU]@�"͓u�-�-u�4�� *��ss�`�X3j��ݶ�5,}ϴ`_����޶pg��^>�t(�:�}pXGV�c��K��.���{�O��i�)HpY���3���0��KC�G��TMt0Ѱ�\�a���
7w^*�{��ٵ/�Z�y�qqAb��MD�W��J: ,��D��btXeNp&�ѭ���de-Þ���\H��?��#S��h�����]��|��ͬ_��h���,p� U�����^�_@!+,�u=Vq�a{�<	���.�R�tɑ �8��ǜԲ?'��{����F��F���H�����M�(�w�L����(C��X����H9�v6���F���o��
�8���y�l��Tڅt#� ӉIn$r=ņ��uK�14/w%�h��DY��>ʧ1�<�����ἒh˃�X����ˏ��*/C�9�d�nOyU��[0�j�n��\��	�Wn��*��O
c� �#f�r���Q��`Q��/x,���2�'ŕ�	
;�����2�>7�V�eӰґ����h=�\��8�{f��0���I�6'o�T�"�CMzT���i 0r_3�t{���%E<T9��?q�kp+�=q�z��4z)( ����˲BS�+d<F"�x�
{�|�܇t�������~{��s�M�GT�B�A��J0��~B'�K��y��Hj�h2S�؜k=0Qf�����`F���ҖSa���z�CV��6>\������k�,�(7�=�i�v�'׭@�U:��v�6iW��=Wu�S [&l���(\�5�!��q�]��3
���&�cW1�z~�
�V�'$�r�����r4c�LM�јu��"�i����Q*�F[����&1�غ2Se&��(�۷���4#D�{���F+
m��/�d?l�~�,G��w2�M���;x��f9( ϯ6���!Tv��e�#ޟ̘�BC�����N�H1��e���·}Q{��g�#P\���-=��ُ�I''Ŭy
�U����4����i�Q��@7vc�c �e�_�W&�,֠���PA���l�Y���iv6�X���:;��z���_zI9�ۓw�
�^�6��>�rK���[�8[}�~_^n
�v���Ύ[2<��E` 6 ]H��y�|���Y'��]��]��i h+°���ګ��o����o�c�����T��
�fRʫ.H��0�֥s�OdGš����y�E����V�X�uq���5����!��RH�����;�rX&�����a�ʇ_��=�L��_>u����� � �ul�g�Q���q�\�P$���pw�ߡA��`s��Đ��tfm ԫ*�$�(%�r�9���������?ڹ�#�Iol;��3� Q���n�&�Q���\1�ۯ�i���R�&���fV/�^�I%�r������u���:��׷�a��]}Ό�B1
ʏ�ܾLmB�V�k��aǅCh�Udp��Hv�5��PZ�2��&��v����\w$~�(.�G;�r�F��s�!� �B��Q�|/��zf=��'p��,+�+���yx��B`�2:,���ޒ}���7	��ȴ��yi`�LL&�HK���<a�/�x�{�_Y$���̓�����~��I#W��|VH��O~�~>F@"nx��Z�a�onx����
^#��/���k+�+�YxH��+���:��؃v"�����k����^	Q�P[���_6;b
={�o�~t���,��R!ݥ(��XUXë�O�u�Mu_�r²�xH���_�LB���	�-I���������augwb��1�/+=*�K��t��y��_����n�W�UZyD�n��B���7笏p1��;��3������y�-��$K���<ɓ) ��NL����M��t��󝖝Hg�
�W7�W�c�)�R�+Yb��֯�#+���`���K9B�?Hٔ[��@o��Yq�?�bs|���{�%��s�W�^�e[��m|���Yo�L�q�<��a�xn�]�!��\2�K6�b�����@m���W��M9iC��� �
���2�寤�9���9n� ��x��j���8��4^�26�����M��q6��I���C@0o�V�['�ģʶ$ۗ	����v��i��w"���(~�9B3cف��3�>�[�>�\	r�8��KoXndlP�/^@�0�sf��tn��9���i�_�/��A,�A',
Ր�#+ؘP�D��h�����ǲ*Cf�;w��T��U7�ч�U|w�3E��6�B>��a�`��c@��az�|j��GX]K�����K*8�Z�4���:	��r��`8�0&h���r2B�u���E��5tY\t>�>C.Q(��h?����,�e� ���r��c�
���Q��*�q�ѭ@V�̐�f~�l|�.k��/�k�G*4eb;G�0�Y�kB��H�tm��A����,R��(4�]�������b�j2�~>��|�\G��D`���L�����C� �����־��7��#P�r���cG��$��\; �ߓ�%���[	��蠪h��o~��z/ڗ]�xvA�tK�ڤ~�����&�.����P���;�9��78���n�&�����>���7P����w��=Ůn�#���w��H"D�bzV��p̄l)��+A"�����f6݈
PB�a�OU�|@��`8J'e��=�P�e1�]�9<����I()�kY� HFT�ĤU��u���� �,�eL�k�y�y�G\�	����n3:[[�3h�$���M���L:����Vu�ϣ`���Lj�/�d)L�4��l�7��N�Pvvzz�Kִ�{�FKO�r}�!l�
.2���fߓ˗y�7���3
֑m����>r������G�ழ@�0�SgQ~��M`�t��PA*`���RqD�r�NU`eŮ�T�ᝈ���Ԃ�)	�i���i�{����ҭ��VH8��1d�Q�����/�����xB�(Nu��i��!�g��{�i8��Q��rpu�U琛v�0p�B�n���+�E�(#�y�Ş�fD�="�W�\"�L��q����9�L����+��WꟐ��z�>������kň=��Aĺ>�?%�|09��]�OYj�+��D�%�ƿ�c+��ޘbR�$�[_�w5'�����G�����bk�$MG��V��Z��6��l�$g��0��9�ޥ���l�����t�f��[��*G���1��DY`?��ȫ��T��K-����h��@T��*���l�������M�!�[J3�A'�	7��i�m�f܆J�Һ՜�y�?�I��3�^rO3�	3+h�o���U��+�v�ܖJ�����\�����ɧ��t��W�gS،�G�e�f�KT�&�acD��@�n��)��������#�|@�ҫ�K.��s�;ǧ<w[���D��w1A�p�g�
�A��c���)�rA�-̌`$xOH�=���qk����&��~,C����\]l����$}���3���:���BK�1�J��:<~�yW\�����&p��?'Gs\oXB����K��6��z>F�?�hMj��?ϰb�ީ@lva��#H�T�fL�`,n��'����P4R����7�*��m��ҕK�;�B�6(;�슌�+�?(�w7��9�k��(a6�~N5W$\��R�T�˕�<�e=���k�`�m	R=��,;��V��@p����\��M�|E3�:-3�PX���Ap��!��0����ǰH�m|	?N l�g��/  �yZz���84;6���Kж�r�lovpP/���$������4JKc�n��}���-K�f'�7�,o�њwQ�á���GR����m��[��ܛ��)��rB�.��$�^���e{[O�1���Y��6g{�����0�)��	� غ����Q@�C
Ô@m-��]B|`���k�d3#���FtX�ȅaN��޴g�i���
q�>��!_�zZ�{���u���r#�gR�52ꇭ.�2x}�{�ک4e�3CE1m�;�94i����?O�#Q�� ��Fɢl�xta7
s6A�ϿȺ@R&�������ؤ$?�C�r�	�2��)9N�Q�}�=�}3ןs?��0t��L��+�����\��O�4��>�'�
v��;�V�O�ux�'�)�͏]u#�)��0��CL�,���|ifS6����З��{�VŖ#�t���ip.i��M���E��Z�;J��8���5�D�\|��l@��E�=�M���Q�����W&��	٣�Aݪ�s�Q��|�k��{���E~���	���]�!���B���[��-
k����}ĕ���E�q@=��?]�G � �G���d'\���Y^��//K�C`�����]yUl���N����Ĭ�E��
��o8������4�.C�fqN�OaDƶi~-�Z����XQ��Y�T��(�'EB���%�Z���̨���asb>�h��W��;�lh��L�.������s���J����E�V}������.��R�.�G���'	�kFȸ���E5�|� �E�/�����b��9�Qk�-$����P�����o5��]��jف�m�b��*G�:s��0����%���H����̉~��[>��9���+(�6Ѱ��F�i	/U��5�A�e�{��V����edƄ���\�R$i�~�.�b�ܦ�|������8,�f$���bM���ʥ��[\Ǥ�`|0�ˠ�vh����o8l@H�ޣ���������/M�ۋhb���vR��-��,�ahvԴ��Q���u���Z�h����~f����mD�?��+f���@2�{�Z�χ�D����&+�}+�Eb�榝�+F�H�w]K����5�s�&k�Ǫ�~���8��tq;(���"�������8�*���a쟪�Y\ۋ�c릨d����ҕM,����7N����= 1��Qt�d.Ik�S��b�6ort\0j(�栕Y�r��w� ��>���,v,�\��k�N�&�{H������<	�5|qӠ4�����e���������/4�M|�t�_.إ��=q3�/��vK��������_9�|�@�m�7�2>���%�;��:��#/�)��aZ[Ap���I��
H��[���(.���whþ�ǻ���G�djyt_>l�``�:*l&�
���[��[�͠Ͼ�L�7��b3P\�*v	�`���܉��=���s�����@����p��M��]�++�cX+F�����������r�[v��Э����T3L��3��$I�����e��Ǟ�[-�,}�d��"�.�m{���KL�5P��	?O=�)����<E����q��{�i .P߸`�kt�>%푤��op��V��H]R��Y4�ⱁ4��92�-����+w�Gad,	q��uɗO(� ��$����U<ĝ��8ˆ\(_P>��<bn��4�#�pM%H��]�@<��	�(v�$�1d���#{G�h�{'>ʄ���*����}j��TA�L���`�z$�`����.:��	)5�poZJLW��SY(��u��:򛁴�����e��*�'�k����YR�����i@�|ᵚ��o]�"�2��2]Q���J��[�T�f�y%�R�oZM-I�����e�oWd!�I�Z߄Ma�Y4Q��;�Kڮ j���MѼ�ʺr��,�a�lP�9�?uȌj,wBbD�KE�d__M}�Q�%�2w?�+j��BU�ɚ6N���@~����!YC����F����8h�==�\->�����]�ǝUȔu	�8!6���#�j,�-x�LXۀ��KKr�*ɹsd�:!�mZ��'*��d?��y�)�0r��'���yL��N*�.�SR���&~���z�@� =7[󑙟cX��\��(�q5'���|�嚔�QF)s�T���ڂ`Jt(���C�1`b����?�-huC0`Bb炤�Z$�)�����ET�G���U��'�y���>�X
���-�O@�qY�d�+�^��T>t���ehD��<�<Zb���"�V�%ْ�k�k��}�����N��U��|�0£Q���Y�fct��a2L6�h�L���Z�6���w� �HY� ��H��)���.[��S��x&�����_��ۛ߿����0{M�Q���͛c;(>�.��߿	2P�����(��hij��܊%�n C�t-�6���6���<sz��c�<�O�Zj�f��K�ïU�bJ.�C�i7r�2!�1��$���3~
s���Dmw_w6��o��z��t��@�������]�FDZ�5�r
���Dy���
��dn�f�w�t�h�x昅o%h�$�(����dO�B �a=��j��`����n�y�i�*�Hqřp�ۯe�/4��?+yxu�6R}�g8�M7ȍ̐0,��(� �P�{j.�%w��H�7����
�S����x	?W�X[�\�j�)�������f=��!�9�f����L�����B;�3���ۖ}���V��O��Y1
���A4䭷��9�`�G�Gf!My��Cɓ�^��im�ܵK��w�&iT�~��8�wO�d�h��4	���Ǩ�peT)�w��m<J|���?����=�������y�7�m���I��0�:;�fDS<~^I)��(����0�J;ĺhS����4����9������#j����ð��gz|�6Q�Wk3�����O�iy1R�5,'��*�|�����b�^E (�\���rO�����FI�R�mx�������%d�r	�OJ�U�&��� Z[7��T����k���8d�1���t'DP���s,١�L���!����"��c�,��5��_�l�����M"li��j�+n��WCv{D�d�)�L@�٭i�<�3 ��$u�8b�Rj�
�l�".A������8����R*ı��:��M����bS'�x����'�ة��͠�ª�Wvf�e#/���r�`|����u�~�>�nV4����g [���G�G9j*���sn�C�oo,�8I���t�z�kʫ�9���f��$2��)%��f�D�-��b:߆Z�}FLB��F!Qs�l6��[LjY���z������K�Fe��p@P��|�Ra\d�����cAњ�����Y��ǐp��&��e;�R�5Ǎ�M^ر~+�>�����"���{�X��悬G�M�)B�h K�Z>lI��N,�(��dA�긋T~hHD\��*���V� �!�k>��HCN�=^RW3���H8&���g>�N�0�[�k�^�ƭ���#�.Ŀt<�����U�O�&_Az��fa�9%[�P���o�(+�s�^z��:�������K�!���Zǹ�N��q�5���nm��d��L����$��r3o #�u��/�gN�R[�l=�9������-O�
7��<���+_ٜ]£�����Sv|�P,�F����Ʌ�a2��Q0fÇ��-t���W�9j��ź+*A�r��G�����B��/��������E�QE�%�x�pv�5�o�.X�,*��"�<���k�CP�q����9�vW�	��Qf��Sj��+-�����a	=�H���>��B�/z���b�{�)_�Ѹ��Ec��,��rU#I�Jrf݂~��r,�{g����/�b�<��C���o�ұ<�=���c-�>�İEw  �m���k� к��O����g�    YZ