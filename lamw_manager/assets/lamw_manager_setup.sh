#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3663605655"
MD5="8f7bd22b1de238d58aa9d1bab0b49548"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20668"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Thu Mar  5 02:17:31 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���P|] �}��JF���.���_j�E��E�qF�Q����h\8<���r\�8����;���ޡ���46d�9�)
�+wG�:VX���g�X�v���(VH��A���g��l�JfF
�h�>Mx>O����%ۦ�G��P�?�*��Ă,�Q��yibjK>~8t�vױ���_�=R��h��0t�`:r�9���0�c�$6l�(h��@��m/YY����㨘6ã@�o�r��&��ô�y^T_�֭ķ�0 -4I���y�Q��0Y݅,�L?� ���d���)�V��-�rJ�� ����:r^Hf�$[��	^���k�J��D���(�_��(�{z�^�yHzS��<nr�	^��L��'����e����Q��|U�����!������F�{��5��,W�e���AZ�=ɛ�?��z�?ƍT!�S�:�/uҠ���N#�2A������+�g���M1��HC����ڱ�ϧ`���_�|
n:%	��� A33��Dӛ���e1m�d���J#%�u����Ҙ#O���B�Y�,��4�q�!zfz����`��?��%�͸�?� ���6j���`�%��N�Z������31>���F`�a��z�+����������Y�6Kh2i�c����X+��]��oT�1�0��$�-՗��(¤ŋ���3��w����~ս���3��(�6J� �g�EX�X;��N�4b�rrM�\-x�Nf�cFbzF��´5�M�wrR��݌% ~�~��W��|�U~8J��xC��'ӯ���i�2y�}&�Ƒ�j���
���i?��d�6�	! R&g_�.�'��u��ٱ1~iㅌ+���a���}��E��q��.%X+���޶䜢A9ҚT�=��,���v'����
Ki������5z����l��U1W\/��`i/��s}��##b�;ͷe�[�	����wF����J'����=#�~�/�@��n�@�9�0�a��k^&1.NQ�o��{G�P����i�x<{6h	��g �� Kph#���u�m��z�M �h�;c.���3�%P�u��Ţ����c�c�Vx0x��DM+2W�a˘����j��ٓ=�9����
�;E�����q.��ƴ<`Ye�zA�ܚ|�ՌO퍵�S���(>��/)/5��V	in�ܿc��jk�E �O������?�}��SD���~0�su�����Jd��.F+
%m��E5|5���W�h��NW�� YF��N���G/wu~���?�κ�Uݙ���/�L�{��4䖀���ԅ1�*u�=
�n�H��,�I�si�tR�vA;���85������z;�>O& �~|�+��mY��|�$N	M&��S�ⓠbNcA�ى�.��tԡ>=�'j�	�Y��}H��E�O�"zD3��6[�\��� p����ͯ>��n��N�:6�c�'��gM�sb�����|2owb�n�P������Q����P�9:���eJ��ȇ�����6@�K��<_�&��$w�ZX%�xfW�"��@�4ex�Dl��f���ȅ8RP�o�6��JM�FW��U�:�d�)���s�N&���S͕�0�kہ����+VI"�IIѱ��F��$P��zl]_�v���UVjk��)�����V��L�x�0����q�.�� ���[�讍@^�O�J[r���m���� �~����9<����u�a��/4�/r:�`_�&gĄ2۝�D,%)u����c���_Sf��UL��m�#f�h4���~}��^Ma���p ��=ML
t�aأ��%a���Zr�sq����V�-�}��m���T��8�3Bǿ�@��=��`/��ļ)��0�=��I)b>����CG?����]��J���
r�EEK� v>��;.�����Xo2R@�HN5,�@�t<ʶw1��%���ݤZxs������H��}M��9:���!��X0#>��^��ֲ��>b$t���w8�V8��v�̽}��9���/��i���nzQ��Ba�\�&���$P��q���)x��<�C����0*m{�@[*�#�P� 	t��]Q���xG�Z�m/��_V�"-X�-�󀶪(O�]�1(t��6y��H������(~Z�:�Ĩ�D�����q�2u4$�'��s��Z�~g4�������t���z�]y�%P����~�I�2�#������\c���͍Ua�����In�xR�Ҳ��3e~�Y2����'Te���ެsb��u�L� ryc	�Q�E�,U��knZ����]+�E���H����so����L�4�Li�Û����{�}����G��*S�]�i�
L	ʎ�.�Hq����\;!�Sa�[�j_}d����wo� ۿ�8��M����:�f�Q�1CN~)#��R�)��
x5��#7���Hƪ���W�������OZ���a �5���{��r��|�f�
\ݕt�=*o��K��Y��G��lj�h��#��+��=��I�?�m��X����]BaQ��P�Z�����/����c'/��LN:�t�,x�'~Ĳ��:1��^m�t��w:I~@���ʲ˲�BH�e�����hj� ��L��� �c�ֆ]�U�:G�d��#�����Tn����4zh�<Y�#�Fd�^���|g�5҈��׎DtX1N�*��V�G�8R{vtg^�d�q���TwM��,�ծH����7,�^-��3%�i)�8��k'�?�]UϽ8T���(���y��n-\�>ڼk�[Q���9�q0T���$l�
=��r�U���\3#�uT�Fʏ0cw��0Q�k��� ڀ��%���� �R��dK�Tm�Ycyq�U�gf��$�����J��6��@p��-�VM0p~'b�c3u!_
O���s�MU<�����`�+~I�R5}â��e�û���4s+�M��KҟAYK2��C)��UoY
���B����.}�7Y��#��dpRQI{h�"�������[�{o��ֶ�+*�Ӈ���;R֣��
���&���,��>WOx0�
])_����K����<��(��f����QoD��@ڔ�����iM�9%���2���-��k�j�Z�����v�h�U}6U��rj�०���G�ؘ����C�K�i�I��}����OIv~?#��ϋ+:�-�7�#Z��xNʢ^���W��:�#u٭|�����^�I�wH��6Rʿ��U�jXcQ����v��m�T;�����I�P>�O�͇�U��p_�ҲSI���V^�cq�[��Ez�JW,������@`���d4YC���}qm��9��Xec}�/���I���(��k ���p��de`��^
�m��ڛ����{%$]\\9x�a?�+J4�H��hE��b-og`7��K�d]2Q���]֍Mls ���K�#����7r�q��gx%;�������^a��V4��������(��µ���&U���<�A���^����E�� �����3[��^�x
�t@G{��=>e�0�!{C~i�q�_�΀��!���$�o����Ң�F�~��5
7t�!��ي.��&��wh�ƪ�H��c��/�)�=��-S��iM�z'���\�9p9N��jB�P�YwK5��ݽ�߻ �Kj'�XLJ����d����p�UXf�F��xh�!�ˑ0�.!������K�ʏ#�Ķ櫑��U��a�&�Rh8�C��2e���2��nI8�lY��e2A�V�Y��}?�s����~<�j�f�m#�ҍtO���ϼ0�ZΩ$;����ک$B�[	��Z�K�Eo*�����g����2˷�Y���^�:��{�b>�ߝ(���+}π�Uδlչ��D��'J/�E�@�g.-q����c#Ș$-�=�"D�us�T�:FV$�S��g�����Yk潱�Bȴ,q�/�4?����
l"�B��R��U�i<�9;�]P�1�y)i�L���m©�vN�]1+�>�����3Е�uؾ��E8��p���o+��2�]<�C�{
V"�~���a,f*
�ƴt>�\�;�vַ��F���Ɗ�D,�K�=��^�^����y�t�"@�4�î��l5�uO~��0�}�� �D_&��^M+��G�'��"�v?�o��BRf-벥L���	�����_dM�B7=�`�,P>����)��r�� ��17���!;!�y��q�	ŋ�c����������O��P�/�T4|�[�	��}�e��O���y$� ���nҪ���@)mb��������g��=-h��N��?�W��v�l(�W��w!eA�\��kj|]��d�{޽�/���mZ��X��*զ���R2}K���x�,m:R(������`3 ����M^���^�����&Y� %�Q�����|&�8�K�rɪ�i�����Oϩ���~��Z���N5�}��xw�]n��F,��8#"Fb"N:�}�4B��..��'[#���ݜ�%�I~7#�[f�� Ȝε�vvbe�ܫ_b?X����+Q�w+�a�wwq��᷊���)o��Bd"�����) �!Q/��R����GV�P$*�~-&JX��nQ��{��ygS�<t\��}�9Y��|����<�e>P���%���{�W�X�F�/����=������ /�Ʀ3Y��)���N��Ȍ;��D飫��zǑ���ڙR���~e�tR����o����e��j�c�+������!�p;���2�'硳F�q�@�
����tJ�� ��K��i���0�a�d����?^��\'ޟUo���7�}q鸪�H�hg�dQ v��h�����\���Sk�Ri%���h0-9z�G�-s�����?+����y��K)j疫�P�X(��8���?X��hzL�`ؐy�?st<��&t v��(�ͩ��S� E��a���'^���(��b��S���9����.L���z{�j�i%?Co�!̕p;8k�$���X���H5 ���)�a#ٷÍ�n�	**��T`׮���������;u��D�	�G�?�_���>_��+����{�[g@�j��5�E�RjHMT:���3c$Ai��e�8)��;2z�� ���J��,�8D1�L���^��D��T$1���.��m�ڐ�3�Cx������O]���6sE�:v��X5�T)x��o4'�/���W/�D�n�I@��9P��{G����Yp�x5��^)c:�� �"�A��>�����r���f��u��l[��?q�׽���9���sd'����
�u�f퍉����
�RIR����Iv��Q{�a�'n��L�N�MT�Z_ �����1/�s� �XS�O���*0%=� Pt�k#s�4��
����X�* �Lf�~�S��2��*|��`��g;����������
����_YS�bn�n��x�eO�1�$�7τ�k���Ⱦ7It����]���l1I��k��x}Q�s%�++S**G��*��m���Z��&�ox�Di���]�Q�[���������
ORʴ�p��1���C1�2x_s�5��7�0{��tU6�������I����jy�fo?����%M�pͺ��~���/*�U��B��C"MAī�BR�QX�Kb��.DQF�68��+Ò��(pm��4@/|R�,��iс�$���Y�0�I�Q'x7�*;�k��\@;��q#���Ż��:!V<�4Ŝ�c7���lc	&�F�'Y�j��9:��L�	3c,e��d�(|)Ma�j�B�A/�����6��==s�ʮ���OV���jI�qI�|y^%�&��YM���J�i��Öh�i��i���)0]��d�g���~mX�"=�z�v��������#��1Ջ�(��KrRó@�>	��+�6xk�Є��5T}ˮ���rN%�k��bg��"�S�Wn�ۉ�R@�O����	�����sx�#M����b	u6Û1�wS��9�o��N��(�Dm�z������i��A� j�G�	�j��p�fƱ ������}u҈2�@zW,0��άۘ7Sk�޹6�����⹪�Y��~T��a/��9@��ǳh�k-��އ]���x��{���9��t`�(�ҶR����d��P)Pg���R�A16�Ţ^�&q�Cs�I�j�F�0���&֫���5���Ƃ`1���Y�}#؝�l'�>�j%����}�yB)gє��M�^�e'�(��ߩlH��{$|䒝dK��Ld;)�*�`���D;�*E�����Վ���VЏ-�Pi������V^͹��`S%�#��RǏ�;V]����9q(�K�H�6)�����R[?�~�g�(l*a�U���:1�O����`x�&=��dhU�&�3�"�w�z���u�\s�	3�D��RQP�,�9�2�ʹ2�%�褳�u�*O���?'��,[=��W���4��oT ��}'���a�w����G�f�,��e����)0l��q��:��s�d�]U�L�>zF@�*��,�a�����]J\���{�jX�I���� �$�E�l�en�`�*��\0�+��F܀9\��5pL�*��!�	�ΥjW%�����|�J	����Mp��&Z�_���ZG܄Q���&@m������V�4��� n���bА4�j_�{&�):����+t��uR��Y��<GiJ�x��A��8O"S5��ssڪ�� f��td���p�vݭך�N��,*��u���wS>���I�IPN��4{�	BMP���ʣ;��м��k��#�j؁r��_�{}����I���hZy2�B��w��ܣ�Ki���5��z�$���ˮ;p��E,�jt}��6�v����\w���(�G&
a��a�|��������?��Y�ߛ�{��]Yb�*5VV9:45o	����%��PʎZU&K�M3�fmF�.�g�3�,���9�H(��~%�/�~p�g�[�Xz�bw<R���|�X)V:�����99��&tv	x?��Û�3lBQp�~���<LJ�D�%?z�������ߡ�ʬ�q�ư� k1ЊۓI��NC�%K��h7H��=X�m��76�'բ� �E:�/���t"4��[��6f(���ɚO�iN��w�Ü�����ZV��J�5���;�j�t�3<>΄���@�b8uZ��m�����T���¾jC!������w�h�����%,l���B��1�%EJl���G�7�xjc��0�IC��� O~@��vM��G�⟵����C�y���גN�Oytk#��a];A�E�ξ�������5��5���)�?�w�|�%pbm�g�� ���Q>����#3K���(#c/~����7�0Vum7�@k�����5�߆�%�4�p'�����8��ќ=���%�^��L�����71)ֽ�h��Y�ǩ���J}����(�^�Z��5yq�"�nOj�DG�'Zy�}��`�0Ĭ�-�;�6|g��8u�[h���~ @c��`�Y=��������%�H�cD��4��G�2�^;��z��sm�ч$��|�N2G��U�J�S�l�.@2/9��]f��a\b��/�v9�j��V �6��@�:#�P�sWa�]]+!��$�طu�U9��=�E@'�!����J�-�#��~��܀+gA�n\V�v[�Ɂ^_��Ό�ވ;Q^9k�f��������ǌ1'�Z�^{���?uq�v7���h/�W6iSJG�yl7$'��%���{��@8��S��d"�^/T�$0��gg�ix�˦j�#���Py��{��H�[a:��#:ϧi���z�e�fp��=Rq�ZF���hal�Lw�=�W������0�06���*�n��x�\П�l����咯@f�[�#�Zp�=��@Z�ǎN:��q��](�@�m�F.E���]�J��Ot��N�!�T�����.Idze�~{65M���bϲH�z�x��*Vm��D��f=��ϲ:�4���Et%��[����� �gY�z��%kJ7�+OL�9"^�Օ��L�`�R(�]	/fK�	['S@uH-K��J��C�Mڰ|�iđ�c戠*��_'�b��P1Q7_r�L- ��x�e�x�7.|�Y������!�YxX��QD��ŧ��[W)�Z!5��4���tJ��A�� .u@��7xr��럾j���� �H��Xc�g0Ț�K��I+k�Б�e��9��ϝWe��k�W���P���a&��^F���5ļ��O��Yj�i��e��,��%Y�b5���.sI�FDs�U���|%��fG�ɧ�o�����p���.�%�n�}^w���o�0���~�s���I냩�5"��q��'EDDK~��\a(�%�?�#s|��	�`���`#69�m�"��4u����~D�ҵ�N%���[��h��S�C�ٽ�1�x���E��z�[���2���І�a�~�X��Wf���3]+�?�_����f,�g�$L�������#��:Cd�L�Ī@��}��1�X�.��#}�MM���T��o�E���z��0�s�R�3kw�Cy:��,�_����%�s1Q�
 v����?�h����gS)X�2|p�TU���MH�Q�ά�'���:Ӡ$޸12�5��ñխ��r���B���|{,����{�k�ۡXWR��$�T	�(�k��]#38� *WB�^��p	�}?Eg����a.M��Ū?ů�{'.r�p�mə<��w|�\�Ƭo�F�5�kҀ��˔}{�XkwCX�]چ}��i�: v�Kc�*I�6x;<�������%�<�!��T�5y�����h|�0z3��(R��û9@
���k�/����o�y�K_�z��y&��O�pݜ���[�����'���P�O���0��̤����8�<��M���w�F�%.�ٿq�V�kR���F��F�^��&�D�����aǇGف�^Ie)�۱ܟR���z�NqX�jx���ڤf�ǣ��Q4��a����ǝڶ���=�0�WƯ�%�9��c����g:����E��c�r���w�5@?\��£��|�z8A��;�bw�[�>�"��?�]��P2�Z���z�����j.b���h���w���78���k[�ĭ���������mQ-�����1���Ib������(�(A�.�gI��D��n��b�[���Yi�D3�%�������z����m�zj�xʇ(���㼻����d�:�H�7�����ዋ��h�Bo���99̣��0�%���@�/IDKi�u<1kZ���[p4�f�Vڌnnau�(�ԛ8��X�6ޏ��%��c�7�n�Җ4�XE�R��R�*�Lb@�.�s˞P�g��`V0�b^���0� $��r��h�!�tW��(u��=j��� ,��|ī|��ȕ�n	�VT�����45��G���n.�#�D�]��q���`,��޼^�]�2�f��{��p�vB���XW�Ń��ф/N��+��0�4��� ��e�'���
B���k�}V~��������^��{		(�a�����|ˌ�F��-�!O�.	?�����|�z.�f�k�I4m�(��!��},��ﰔ�ݰ�SH_�獗�-q���}�Au4�N�(�]$�zE�U31��JLn��;d@��>_C�u ����ٜ�y���n4wED!7�"�B��J���5ć�HceP�d���3���2R��5���Ix}햱���i���yW쉁4eX�}�6հo���L������11��<�"�QA<���q�UT��qYU�1�u���4�S&����]�l���,��s�9NA����pA�lgk�옵-8�w�_�?,��ȃ6�����ز���P����)Q�4nFuf��؜6�!��xbk=���E-�)N6ʹ�݈�_�����}�I}�3�O��zP�u������}_G��|����8�F�vkF�����I��M8�K8�1p�]���,�0�%U��}T=}�i��+!��ӑ�s�����U�Z�{(g<�/Λ�a��LrL��OV>@s����[-�$�!c�Ah��~U�8R*���Z~���]x����oЬ���X߽������˃���2�#����/a�u��a$��v͛_�@з�Tu
wŅ����P��0�ث���#�D��?����zӘ����S�¦"�RO���#K�U+��gT:�O���ۇV��[�gN}��i�����4�C1�*EC��&�3���-S?@�/�vPF߾&d��������ֻ*l_���o�d:p	;R2�W�Gtu*��)������D�0�O��'�_��A�o�E�0�?�	�!��t�{���Ρ#G}��&8����g��垹��s���u���Tk4�=`@�]\Sb%�8O/5a�B|�%�vJ�Fメ�i�(V=�{7W��l��ay�6\��O?�{N>��\8V=�;����[見��hF8�%���AÛn�	�h0���]��$���$��.�����a� ͮ�ED�*o��sj���U�%t]��fƵ"��?'3���D|���K�TUi���4D`6�iv� F�¹����3�)�p���d���lmݍzt�����<����ؘ����g����H�T�
�u;fE��o�N��Y�p�\������^4�L�'�G6�𨨥�`v�~�U%��Q�G�,g�Ok�T��_�a�=.l�U7� ���8�d}��,t���0�8oC��/Cܸ���r�L�C���j��V�-WΎ^��9p�b$�pܼ�d`�L�_� ��]X��诙�E��yP����%���ڂ>�,^�R��\躉�+��+��4@��Qh��\�B�[f�0<�~S���!�?�ϩ����}��i�0�y�C�l�t?���pF���F&=6n���m�6�\_�b~x�N%�?��nS:�˃!y>��ވ��+�����=J��Tv��� ����Ⱦ(<��zRK.u���5 N0�C�8Ƃ�oO��o�%�U�]iڭ�!�X��Zf�sy�)�e���]��9��AF8��g�*����JV�L���V�r��E��x�|-�*H�nA;k���3e2��T�2��޴#��^���u�S�m�A�����6o����I���q�{J�r�Hv�L�v޼�UK
,d�"���D}�a�hL޺�TIK?�N�^',�zwƬ���
����}w��D� ��;�>Y~������٣��}-� ��\;L2z����L�/����?�C9M{��|c�������,4��u9c�tЩS>��S��U
�E>S�格�V������?^�����6���,�Ar'=e��i��֡���Nδ��������1Pra��a��uW��b]l#B�%�$�� /��g�����|I,�&���Gg	m(������� ��PJ��b���9����9s?���������������%�2�kg��&��0���SH΀�\���l|�W���������/�S"�[���RH?$~=a��
�'�-~��1���7���� �)M'' ����K��GƎ�!���7�?'�J��<jf�R�_!oT� ���(��D,`K�>\p>+�S��{&dw]H�x��.(�ps��/c����[�J�@�*���E�p��
�p�<{�]} u���ux�$<N��.@i%H`�
�]�oEJ���;�a�a�~]�/*ii?.�a�|p�~V�K�wסV�l"[����1/v���t��Q>�gh��$�=ţ�u�fi��7E�#M���Dc��c�T���5�����j�����f�խGD��y��8hG����2��<���=�bU�]Qt�uU��6��de�q͒��T���.ͱCVl��[ۘ���Ԍǟ��s&�=d��S��Ry�s���v��A븆��4ĵ��d�mMYD����%�ڧ<�X�r8��CO�׽��|ə��X�P*�mJ�I��5=ȡI����o͢��w���h�1	��ͺ���g�z%G"�^-<ּ�K=�^��ηv����ӊy�� v�2'�pW��E�<�����&#�����z �+y>��DO���^S���<���L~���z2�R���)��s3p0���?��k����F�����Z���j��܃³[pt�r������k.������
' Ǫߨ����<M�M������%B�/�¥!3��9ًk��J��l?��օ�+�$4��w�0{HH���}
���{���?�ǌ��=9~�Lf ������#`���d���Y�H�b�H�4W��9���tάgV]�q�=e�ϐ��j�����Z�����*݁aiȷ�'>���A�P��x�6L���߱�~�^�% 1����$-A�8<�)��A���+�Y�6�e���y�3�
�C1'�<�S�a�?&�Գ���s�&c)Eɇ��v�"�'ʮ�p�B��g����E�q�kEZr�
����h�i�M>*NR�8��������}.�R��0-����D�l0;u�y�.�M�R��53�P�ޭ�;wg�,��M�VN݈�X�*�g4J�p�0��>�Z�z%���,���
� ��ZF1��`Ht�R,D�:���K��Y(9�@w�Wlą�y��1ޚ�Z�i�3���p�m)��beC�� &V���J y�ܦ9C�*D>
@��!{<���3��7ڀ���ݪݳͭ>��+��އ�s� ޺�݉�,+�a����t7�����C�P�H����/�p�೔�t���p�W��C�P���Z��)2�jgMǀ���5Q5$ܿ��Cg�@�_�zȿz����Y��WƔ�bi�<Er!��.�G����Z)_���++*��
T���/�����(u��R����?Q'{v���0#�0��$5�����T`l��3�L�.����Y��B�P��E�/u�����zK�xc���n�^�E㳳pg��)ʱm}�m0g���k/Q�(C��w;��2����$YD!�R�-�n:���QMH�#R��B�j���}�[~��Tٵ�G�E��mf���;�g��C�ٴ;p��^�	��Ӯ���h4Je��g��P�h�.�������l}�g�$E�Ʉ]�e�����ɓ$���s��í�1�LK�v��kr�
������ �p����plI� �����ժ��3jU�x4���_�*p/K��7\��d��s���_�o$G�:���ܥq���p>�����`H��)W�t�a�����X��|62�8��@�&.�F��a�AI�R�]@�PU\U3�f��/��ГO���#���ik��@C�H���#09D���2I��g*��"�[ӯ����q%|;k&~��eҫ�|{?g��&�`C*�j��|&��cqn馻��LY(|}�5�L
o�U��T&x��INن�GC�{grh=į��B[�:�B�0N�;ox��h:�Jr(eNȂ�  ��!la�f|Cz�Q�$KkS �����"�`@���p

�� �W�Ξ�WB���Q磐��J�ҹ�R���ns)o�ڈ�s�WF_"�Ln�Bq��b-�A�5Q��$���on��#s���f���T����Ut��M�:Z4�Rs�S����>X�� ��@��f����v�?o=�Y���
�N�o.�XR�Q:p[� W�@�m����f��v�z��J�WX括�:���R�g�����h~1�%":�)j.ģ�U!�f�c�r�vĆ*{!�b��;/��/��]��>�_��9FY�H�<˚�_m��l�[Oy��~8���y*�Π|h�	F#L�"�0V�v�DŦ�9!s��-\�4��l��ݭN�k�JI�R=! !n�FZ�.��]��3>�cp?#��qb�@�UPm�#Ϛ�N���Rr������L�ѣ$G��χ��4�����Y�G�u�����Ϻpsn@�l9)�v�/��,��fd�KP>*��Ĺ�7�Q�<Q
����ּ)A	!�������tz�;z��<���xH�U�`H��΂�TЕ�H"(<9c��'D�6�A"v�KOg2f�Ы�7�o����&f�*8���!��|�n1��B֚��%�0#��5��g.3ȞWgƣ�y*f�LH�*����&�<Z��6}�#�:�q���U���'�q=\��Iޤ����@Sk��v��+����.�g�L78�\8���R,����HV���'{s�{�e�.M̌H�(5�i��
[&�δCH�B�V������c�ס�h�_���jkW��\X&�a����U7��>��MϨ�m�o�Xu������8��4E�vw�k�r����i��k��LJ�3uW$ng�EZNBY���]]�>Z9>懹4Q�u�(���8���8�2|zBٲ���GE>�F������x�'��u��}-�-���+��I��wVX�P��#��R_?潕��F��hі�A۲��?D9�Ԩ��v��
uʩM�����6X�D΃�:U����n' K�/Bkh��:����)4��8Эb�ڎ���ޣ`ɷ3t��d)Pb�+���gw�s��s3"�H~���z;��/�/����x��W�$NW����tB��=�Y�8�v�@�[��&�S9���^�"!�"��E���P�Q����ǻ�=k����������;l�E5�BI`�#��*�AY۔�&[��j�S���F6!���:EZ��C<Gb�b�B8v���m-��x?�c��/n`�;��I�@��	�Ҕ�Ù����`�dC��]���?^�N��a���J�����	
x��&O;�����J���MՐ�K�sl�WN {:�!���p��p�����:S�E�eXܩ��6��OﶮU�?�q��pU���oʠ����TM�Y7^���j��#�׋�Kd6�[C��[�X�
�m�{HU�Jf�h��.��(���p�}����p�z+S�˰	bԞN���O���^���a�[��tW
'@��MArH�i�)�������<�PCϖ�i���N���@?J��mz��$���v�͊�t},�0�����{�Et.-�f�f[>�Bbby��,Z�@��m8�3J�=.����&�k�&D8W��5�]$�S��ӛof� Q�_i�����b�������p尥7d�&��	�Gz�t��n���??�|�@�,��C,4���8-��<�ο*�i���+���5��6�a�o�A;1�(���{c-v��GT��Y�͘���c%�c$�!x�����	� u��y!7�M�Y�N�������.�f?;7�=�i,��C�o:e�@�O[3=$��r�W�u���-d�]<�MJ��-�tM��P|���;��T�y-Y�ЈZh�TR�C����X@K�%-���.6�A-qn�ѭx����x���J���_�S���;�����,�ң�,�GZ���-Yo8
c����wtͤ��ndI]!t]�?����ޝt��Ee��7��-H��b�))Fms���o�,�v�Y�d�K�7~U��܄it�ю�3�?�T��s"���~�蠰n��v�^�X��*r�p�$���P�k[T��1��ܥU��
����1����͓�%
�������4l�z]�s���*T���v�`˕&���������zG��5�*\�TJ�`t�����tu���}]�L����T�$�Њ�OxL�v�'�xc�VY���9$�s*�{���vkS��w���y�5zj�?�+�3�0&y��MyL{�ɸ�pF��K���N��E�t=������'b���U>�9bi���Q{.W"mGSv�zy	�����g5����i��㟆[�g�徼Z��~��*�؎i���Pt��Q�ʲ�͑���#�����(}jh�����`Cm,�V&9݅���,�]
�RfQ�E˳Auo�Q�]'�|�IyP2y�E��٩te����\)�al4m�e88)�:���q�~����`o3��^��:1I�QG�p��ES����0�)1�4O�y��:��6@�A�j��Nj~ٹH�52� ���э��>��,�S�Q�ļ�B�)����)[��a�v���e2ZlրU��6��wו�I����a/{z�V\�� )�vNA��Nӥ?�I}!�d���cq�s�.��SLP�<,��d��6m��^NX��hP��"u9K�i�3U
c@��@�b/{���U��=��.^��;b���B�D�t���r�ʼjN`w����u�92�*�Z�[+���9������&<wd�kN� ���7aC ��g��� ��6���v�c�o���W��1������aZ�V��Z��:���n���?^��A�Nx]'Ș���$����a ��]M v�������O/|Բ��"�N�g A��<��,E�ɔ��b��mKY�'�e�P��_���C6W�����΍��2!�(. C�Bh�S%U2�@}s�p��vsp���最�!�~,���*�/R��U��]{����N �{JApU`bw���/�;��й���9���jB��1�����ka�䲜�.4�Q��y���Ij�o1�6�i��%r%���ᥴ���uL�����λ3�~�hz^~1���U��ɲ��?j�eR��=�%���tA��z�������fy��=�@���K��lP `���\ʁ ���j�mY���ge�\�wy|m�z�$ #�10��B��ݕ���=T70^g��4�L���EИ���Y滼;ڌѐ�p�/v��u,����rݢ��Ӗi��^��)���j���C��6i[f"7�tdAg_`bh���p��}�3։���� ���g�qg�v6%gm�H��,~}��4O�GmՄ?T*�L����Z�ekΙ����qi�/O8���2�Ԣ�\��D:_D��+�T?o�E_\(d|��5���j���	P@(���I�dԀ���<,٭��}^@W�[��Fv�,8�f���#��:��L��2u��6����N�,)��b��\��B��I�)4S��{^��IH��΁`�����x_��6�J}oj4骢w��d3}lu�]"Xĉ%����>@zF�H�\�yC��	��
�;�w��I�z�k���1�CD�d�)�;:-N�J̪a	42���!+��Wo��˻��=أ��F��I��!=��y!��s��	oy�%e��'��zZp@�7��K�����n��C�4+z%$�h"캙C�Yz�yS��5�	��u�{=D�@;r���o�:����o�M�g�6��&A�9Ɵ���� �̷�k+����^{�$�B�b�����v;+����H�G7����v�i{��,�9����j"T}`�ު���7�)$�NK�|BU�S�-��]��~�v2�rJ�����Q)oB	j7k��(�)�IN�ݝ�Hݣ�(�T�ǿ�3Ώ��v�uW���6�.�&�J�g��7�V��/ԪR}�K�ˇ��U��u;�KӘ��]D-1=�7˭�l���ʴ' �|^�ƆN�<6�<!}g"���7�1zg�z�D�r.MiB��=�>T��/+�\�3K�@��{Gh��{���	�
��E,WҌ���_�1���z��}(����X'5�L�q+3&����]гYL�B-�Im�o�6���L�f��h���x�?�=`�"��K�����Z�Ȭ���+O��(��I�Ŧ��烥ih+�#�X3\�t�`��C����c3=��yf>Wn�יGCNܻ&��<f,�;��yR��"�`ĳi��;����R��^s�qK>��HB��-;���y���m�ms�gF�����Lp��G�n�"�׵̎�l�y�"����:½}ɚ����,� ��Ȝ�Ʌ��S��%�K�~�/���,�4��%#���g1'��n��[( V�fQE�_l���O�^��-�Lq����]��JW�=۾�jf�h�T�d��2!�Gm� k�����A�~�F39��)u�Yy	41u��
w���nf�źR�r0���=�ʨx�4��!��"P� ���H )�Ĥ4W��n�w�s���_kٛ�o��M����.�����H����9�r�F�'� .*f*��8̼�l��I�%��X�H9��+�Rz�ݽ��x1���C��?�P��N��dYjn׋��ƹa�+y!bc�Q��w�V���[�ӕZ�.g���Zd���>�H�,�U�`ΝQ�w�^v���Ҍ��=�"O�i:ɸb�vwj";S���Uo��:D2����@= ��H	].�P�P*AbEo�W�
 �H,�SA��x��'m�j4Þ�L�jcz�M�n�����y�v
/Au�����{do:JS���:�������6?cW�A�b�k�}cp�QJкS�!�d�"(�29 `��`~)
�D��S�FP�� l ��X~�ȹj����f�F!9����y4��4��/C�+��k�~w��ݾuq�9��~@��[�!�]\��R����$�~��H�X6t�4��0�K<���Xl�� �T��PF���ߦ�9��帆i��n�X�v"��M��D��v��%.0v.��fG
[��<��3pM�x����R��0�Lu%��XF��A=�;�*K�Ӊ�Yt�UZ�g�P���@/]-0&��K��MS�z�A]��p��Fs���s�ްSn\� �_֊]�m�x�������碧�V�|c���47[[@b	e�O<��6���!&�2�G�y1���t��|q;Q�A��`;�Q�etϓ����2�E4�J�R(c�5P�*�9�$7�+|�Ѝ=8��ϰ�O� �@k$�.�0����%�jf�C��x%s�!e[�!^��,�
���F��6��E#ł��-{��ړ�l�����Χ>��@~��^��x7�=��'��� l'ԝ�>Q�O���
&Y~	v����9K�D��D�H����:[+���˛`�#X�M�-q�Ĳ�ExT�Za�'~�7z����G��E�w�,��v�e�)H����rN\�����8a6�8��{�q2A���H���5�/�IbEL$�/�����s�G�$0�|`UFC�"am�IѲy�T��%�l;N;O�h���"��cw�=,���F��ͫ�q-~�&E�"�A�S����g�j�'����ʇ��I�P�Q_��*�%�t�R�[;��t�� �.9��I{B��4_�����iY�y�K�\3AIJ��O���A%��姮��V���ׅ�	�%Tެ�4�6�D���!��� �� Ѣ&K\��Y��`�I�4PͰ�M�>|�Sa������.��P���S���Ck0��O�y>tG�9P�Z��!�HVJl��3ߐ�/b��.#��-cc����7�뒖q�c>M}k�`}A*)�'[h]Uk#Ur�H�R~�ǳN�O�%+�[��A܈�Z�+Rp�J8�;�wDܙK[	SYp��%�� �mdۙ=N�KAJIR��H�Z�5�T��S�-�d��zJ��ZQg���C��+m���G=���	���v�� �'�0��S��53D��x�GS>]8���n��g$͎��:TI=��R���+���5v�*�������n�HxXsKw5�Rtl��Ɩ��W��c��)�J����6��y�!�f3frϵ�ͧ�N>h6~H�o;��c���	[eb;jB�16�e���9K�c��1UV|&����ہ�@�aM�7qS�P���8�]9R�(�m4C"�HE��b:e'Pj]�;�%��*������2�<1{Mә?4�Q}���g���_P���y{�'��ù�woo�ً	���4��/u�����1V]:�2�JMw/�w��͘�KW�i�H1�v�^,+��pe/c^5�yHEpt-W/['��Уt}� WT��pJ��j�i��5'��&_��\uX$�ti�X��ֆ_��ے���o�?)�GNͼU�ڠV�܌�x@���[u4�B��a�-&2����dj�p�@�zk�d<�'xDd��� �^ɉyrD��B;-1�3�[��1�uSpU��z�MoB���.�AP�%݊�)G�kf;�*J�0A3�i�<�Cm��)X�=j�S���ݽ(T  ���m�1�� ������a��g�    YZ