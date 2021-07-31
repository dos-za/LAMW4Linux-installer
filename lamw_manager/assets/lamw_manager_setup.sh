#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3176199758"
MD5="600969fbe39182543df2fe9705649d17"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23080"
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
	echo Date of packaging: Sat Jul 31 17:06:25 -03 2021
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
�7zXZ  �ִF !   �X����Y�] �}��1Dd]����P�t�D�`�'��5P��"�?���O3�엤iyH�p-�'������D��ߤ�2��$l�^6�栒7ŋ���-0V� t�;��ழK
�����
G�<c�놑�*1�l���-�Y~t;>���D���1�FSo�A��]z��KUq�5B*���
�˅Ŧ4��Y@C�M�ΥoaZ��h+d�4��xx*^������1B���{/HLjhҦƧ������PP3O�-,��r�b��d�埜��9�>G�|��B1��������rms��X%&M��s�3W�O�{,�Թ9eȗ���������{`��~O�`���`��>�
��DJ�C9J��h ���m���am'�?.v;���y�Hw&���=��ߡL#�j��6�)tFy���gC@�7ѽ�~'n����R�����24�l�]*��#���SA�H��ʐ�th�+m�jR���ؿ}12�4�m���ը]��caFX���e���OZ6�Tc�zF��i�b������$j�w��#�i�fx�Zdx7�1�sqC5`����6d��B��ȝ�c�ͩ��.���P��j7,����I d@e&��r���@&|{��O6[�Q��GGn�5+@ ������Fe:�6��&���)c�GzL8�X�NQ�&b��Vb��T,�V���u�T�����b(�c�e���K?5���
Җ��d�{!l�LnȲ���D!��;�Ȏ��;���=-�'�Ř��χ׺���4�#W�B͌ۙ�����kw��W_�L�R���,���n�b/�~!�pQ�ډgiᗱ9���U����5����zK���:�(U��a?ヅx�X�%t1���D�jƛ�rNߠ(�4C�e�P� _3U�i�@f��f��8,�h��^s$!�Uus��mk���U�	%7#��~��N��2�����!��I�%�>�V�� ��l����#����6G4���k�h����	Z,9�Y/��(��X�c��	�I�o�/���c'����)����=G>"�ҡ�'wZx\�u����ЛOcCg��
�b.`(��*�7<8��t�IG0_,z7r��jϩU������`�#B����}��n�}w��/ߚ�?@�4�Cں_
ȣܝ϶��*C���/��1�V��/���	���dY܍	��H�M�֡�x\��`Cz�3���1h��P�"A�0��]����W��^�S�T��>���{xa=����'M�|��{��8󵇴*ש�i� ��	q�nt�E�Fgm�Q�L4�џ��q_fm�ۼ��쯾V+���Ҭ�&����m���HP#Ap_TQD&��d3r2�z��ud;H�<?��#�=�^_���=�O�[��Fw�,:�l���%��+���!�[l)-��hZ8d8��=� ��VoRIsW��R�c�����Sӛ�N
�s�*%"�<�@r}g�IiU�Nl�ܽ��ؽ���v0. �@V�u�V�G��?����R�x���e�!�Өa0�$B��/4=/�H�hk;���>�i1����|<϶�x̂���7��(�dNx��t����ٗ-���p��DE��.o�1�YЏ���(�� �|�S ��CQ-(|��֋�_�F� L|��s�i�����2�U��,���&�S�XZd������ɟ@��<Yq���ޕ|�# ��Nr�!h?v�X�2$� 'J�u����A�3�$��P����é��7�|��/s-Ce��"�&�1i��{��z���#��$�>_�mx4�W��ߗ}�U@n�DHYb"j�*�Z�<��ǴqF�h�4z��r_�������Ƴ��I-��f,`�K������������7�P4I��lc�![,Z�b�"�AbU�v�����Wc��ɇ��' w�;Q��%�t��x�� f�f,��lx.��.�Y�Df�`�h:]�vȉ�Z�N��c���Wm�Y�ټ�E�-�m?���}���W�+�u�h�x�V_�?hU�_�ؼ$�Q6�;��9kB�՗5��vނ����Q9�C�w�1Ӹ�/j"-�Q��MZɆڶ����=58�����h2��tD`O��ʆ�e�
���� ��o��$�eB�ϕ������1_S�ӏ�}~~���1��N���);>�c�dX���	Ok�\hڹ�y�8��Qf��P����^��n�݈ۺ��,���� E�J�'�O�2����?�����F�B���?����A+5��^F��6��E�hA�������D��!Lʽ�K09	�eNȢUYa�8x|B�����1�5}�4�]Y�X��H�^��r�r�a�7Zʶ(s�ӷy�M�+'�.����Ytm�a��,�U�{�<���.��X�0wTPLT������v�@	aإ�9$%�Iu�q�I�����&ZL �h#��\�G�� g����&\��^�-�ߢ�X���flH��г��<W����pMX����UcI��5_B�r9/�#��7�fu� ���r��%^i���Ƽ3��.��D{�!��@�%\{$�U�M�J��?�T7/߾΢6P�a�l���Q34>{�?7fYWuHKI2;P��u�Ґg�&�ɦ.Ӿ�������P~o#�^A'��q�d������Q�KC\��*��ߏ=L�ϭ�C���h�Q�;'߶"\�!��Jk9t�K��Z!г��s���V��{�l��M[o$�0�7���
���V�M��_ጰ���"�:Ҹ��j!�923���8��&����߈��q���j�a����>����6*ޟ8�:��L��&@���7Id� �¦LZZ�}d :jf��μ?}�CqҸ��~������,C~�x���u�{^B+&)��}�Ȑ�nw�Qˢ�a0i��xF��r�$�d[�ے���P��.����/pe,XQ4�V�ږ����blTf�ISşm��mv�����Hi�g�u~�G!�S���3���O�k*�䥢����(T�)壳p"uvwR�b�b�ZnMU�8��1��8�b������o�m�X![j
{]�')���t�IՁ��r��+qh�ʍ8�Ƣ@�����d 7ǯ0�pA��ZF\i
�����+2!*T�D�=����uQ�-���rs�ȣҨ��Q豴-��n�4�=ȃ[�"�a.n5���p�8��"��ʅ�R�,�c��Z��ᑲ���]0��y�����n��|G�S��M����JAʖ�ve�r	���t�v�xd���>'J�E��S�Y��+���.*@3�rs� $����O�c������-.~(N�4��G`h3�Nw��Ϣ� v�mca��fH��0o��$yC	�Z�?����:�����.��O�)nx��Y?VE"��	��ɹ$~�K�Pt��Y>���l�;�5��~(?\�:��)����c����@�m~%�)�~�܆|N��O����7�B���_T�����&�;J\�90$��@/�?�M1!�s�� �2�S&CTT�NZ� O�F��1�����	�#�}x�Z� ����n�$����P�[.%�F2�G�W���68�����Y<R_' ����l��U�'!�����i���-��8M�Q�-�$�ŭ�&��9$}##�k�L��Rxm�(�Z#JI���=MXhv��3�ZҨ�;
���~��]8v����#�SA�E���<*�Yii#N�K��b�u�sDйo�0>`���^�a0��������P1X�P;Q�L8�ӈ��(bĒ	Q�-� �&k���4]wH�z�	��ZW��:?E�/�� �'��ȅ����-A_
�-3o���D���c j�:-����=1�r��e N��p0�iO���z2w��{_�(#�9Z��|��c ���fZ3>.E���σ���,o�6�%BgY�S�%�q`*�ZeR�j��c�������Ib%G�T�
��4�dK>�����R�)�7v,{�悉����U�==ŉ6��H��޸��FZxN�|֥Y�$��#&�^�f�B�	�=퐡SBF�)W���_�����G��{dH`���;B&e�@�>�CJ�#-cĹ�|��un$�^���=� �\��%:�eal�pݚ�!B�'�����hz��^��������jBW~B��p��w����+�|��;�����`yX�n��ժ�����W����A`��8��(;v���;�Հ�	�?\E�G�#��G�'���*c}z�0�42�:w�����P�F�u�Q#_�]�L�?O�N�5���8����DPo.��00e$3��;F\�Z���Q��4���5*�2��IعI]Gp:(^���z0���a��;�u��-��N���f]��Ԛ9=P\E�	�^lAY��W��(�@��^B={�by�.6E�P_��u��g6'�g ��+�	Y-rO������y�T$��t\yk/)K�X,�6���.�2�ԁ����^���-W��{g�-�v	��B��@��Mo��<�>fdue������sJ���Cmd$"R�H=�A��0nЉ-��&�9�f�j_����(42#�vԂ��@PYD ��|��o+[�<&�a��d5�\9l�k���`ǼZX�����<����ry��u��d�w�C4�Լ?T6]��d�IO�̳?.#9N�C��Z��`�6�eŜ�iiA���%W�t�ݖ��T-�����)-�����U�G.������ aR�9����	��nCU�/ˣ�Z��D'�m�b��Nn�E��]�<��& ��t�#��ed��2�B�%�aw4�?������� B�ڔ���= Z����z `g��U�L�w�<�~ŗęO�pю]�G�L:�\����^n��z3{��E�6��a�50�q��9�V��!�0�r�X�1#������'gu�he�(�#}���!8�뛭��@�	9v�)���G]i�po5�=٭��5Y��4Lï���������X�3�4nTf��-�����l�.@$��Z"&by$Fi\��#�����N�!��l�*Z�_a����7���w������pO�pH[�N���<B�?�:�BV^[���Dk�Z�R�y%R��P5��9�O {���{bM��5<MY(�)�D� ��]C7�&\X���#׮�ztq=D ����,�<7��Oùn�0yZ̺�5��"��l%����!��ќA<A
B]�x�ѹN�޷���[\�..����7pܹ��I���Y��{&/�%*�K���6Ƴ��$��w&#\�(0U�D=tF�S�ȹh]sh��=�Ӱ�>8I��RK��zT��r׳"{~f�{��~`<����'D������#���3�͉0��\g��a!I��Kh��e/����#x�A�2���Ć��~ev0��YF�HH�ޣO��<�qg�2�|�F�����@av;8Fz��Khh�����i�!̱mr]Twv�ݡ�ne���x�K^�1*�l}E͠0�N�N��|�KѠ+�m�7������1�M3^[�	��g]y� �Tx�=e�W���F�O~.˽��LK���~�M�j��nĲ*��Ŝ��Np'7&-�z"ޝ�&��S�<��^[Ⱌ%��^��r���F�.�b�������{��%RΗ�e�hϳ�X6��@__����߮P��z׸'����r('�o�U���2���&����t�7��aK8��$�q��
�ǅ�������&Y(㸡��-onZtOɅc5�#wرݼ�{G4�4�8j�:�sk�Ӣ_�� �����/�XE*��Y^_+ۖ�dډz�"�,����4"��77}+*�`��rh��P�
g68[[**r�"SQO@��tV3b�s�	�bI߫��TeC^�]=�y�ҧ!�~)R!��~3��@����j�_�g�����m���r�}O!4[������Q+7����k� D�1sY�0{��:��k�s71^���A*�1��9i;�,���D6�K�=��������%�X�`9�z�%���%� X�̑9�/Pcsg���zu;�;Z6��ó:�,WO�9qR�M�?�?�T��-쬡��\To��z��ٲA���4<\jn?\F٩@Bl�ܖ����pr���ן13K���QQD w�O\]���lث��V5 �/W��dJ����R10j�Ng��If7��ט>��zF�����aE��ABdx 9*�e��8���[H�qZ�L�(�����sw�[�eۧ���䔠�&��!�*�S�x:����T�/��'��G�I��įU?�ށ���oL]��|������V�� Y%#N�Ά�/oy����1+��-�2�u���{�m]HiY[���'�~��F�D�����PaH�èB����\��V��z�מ�t�T�J���W���;��,߱��"����`�\b�w���	�j�~�Je�~� �7��vwA����/��$	f�Y������^'���783G
�ߞ�	(ЗfQh�c��8�H�Xzb����A
SpUl��Jɞ-�򊱕�p�tv����f-r��(׃ ��ފe�AQ�o�r���$�U~fAk.B��ЉȚ����t�����38�q͡,���V%j�?odyz��g�t'�s���Ϣh�J���� V�]G9��e�	�b��C���3H���y�<f���ۮI:,����>�9�Ѵ8� ��瑳k��!��V�����<�N+t||p��į
������r枚=NP(6a���5��z�='��
�j�|�V�r�[k�M�U��\(y����d��V$d�ёӼ2��gV���3��u-7��^�@�2k��ݵU��2'y��;Y�g�v,/��Sg�?U�TL+���M�]i��6c�H�MBm��"�!��(��)P�jqdC�o_#F��@��"�ٜ�@��Ч=�$�M}4P�L�2
fKHr'؜��y�-��P�ný%j��l	����8����g���Ŕ����� ���s3�no�#d���J�i�n.�F��n3�'u�4"�/�	���ޔ.��;��K��A�U�y�����[U�L;�3p�l�������hjv�ו���鈒�i�o'�f���Y�!�Bg�9��߃�J���e�g�n{��*ۛH���8i��p�T9���z����vBՉ&���0�ODk)�AoV�h5��Tc�
�Be�
<��4���t=O�#[*��,�ǵa���H��8�ށ�h�Kn6��-Lu�AV�g�# �ᆏ����{(������.O��^Hb(%�$�C�5���偙��5�P�k��;B��#J�<��L��E��d3�@^�Wk�2���}ݔJ��q� �_���V8g_�0d��Nz.[)�����Y�V���jU�K@�#�G���^���.���g�Ս3^~@K!_����?�{�#lD!���}��:��3?�?&ybB���<��x`�;�YVZ�USf*�����B�����[��F�1\}M>q�#8�#g�����v����3P<��'L

~�i�w g���:Y،H5�67x�׵���L��m��*w����M�;;�+F?Z�_?��I8��	+��{h�jb�ڔ\���*!�u����!������U����*�[j���)W�S�<6���f�M�A�;c)$��P����V'��/�}�q�C(HUcF�PS��,�d����MB�@�o�:#9���%��u%�R�b[���g�v �"c�ʊR=�2���{t��~:l�n��?B�Q
�F�DYw��v�f*Tſ��w��n�F �Y2'Sd%�p���Ͼ?��LM���j��Z���8+�X���������q� �|�;$�I�����Ra�ϗ�q4��9̪���E|3��[��'�VZ�ʈC��?n)���[�@I
�Lro]k�O��3L�s�)�nh��󝱚���@�'ݻM�'ꟺ	��8BD�>���[��~,�.g��R��-�)�&%#����Gَ��fW� �E����,������6�n��3��m^�/x��6�,�	ГN��ֺ(+յ*�Yݶ�_��/;u�4% 9Hf+�6mjP0	6.!�됒w�~#7KN��ՈgyD�if�D����M=3"I]Ê����vw7,rNrI� �����D�Ҁa��{	NG��P^�\�����H�~C�J�i��:92�j"��$c�/u��W��Fn�� ���qCT]�.����ũ*]�/���%�߇=6�ZtR���W�P�c<��yM��d�^M4�V�,��!���u�-��C�k�q���u(��r�Ë���S��L�4F�,X��V�U���Y���5*]z�i�I����`Xx�`��	ʛ�A�Ž*���<L���נ��C�&	�o��@ٙY̤D&{���A��B`~�W���N^�2WM������=m���JdA��d�x^
� 9����TH8�E��ױ�0��x�bCu�"mN�x._}&�Ju,�f&rl�l�7����>uU�x�ޟ+�{�}�>��Lݵe��;w��~��A��qqF���$n�����X
Y0��5��%콃�ItBKU�m�����i�gS,
X���Ǔ��1&L��Kľ�eŀ�'��f-@Vm� �I��s+�0�.4-p������&�����iK���^�<� �}��)�y�!�!z�Ǩl������V��!4�ڑ�k_P��"��.��HpCu��_̊��v��ဖeT��*� ��8����Yn
v�����y��[|������'4R����S_��i��}{q�X�xu�k���x��F�O�P��g+_�����,3�g��z�ҟ�����^,�tl���)	g8�|�@|u_�h���n����UR�<�N�V� ����2�����m`�h'�����+�*L=��e�yP��\@�²G��T�ZC_�'1�I����T�� ��k���'F[@k!�>c�s����T�����73 I�hA�2��`-q�����m3t�J�>x0�ّ���Yz�)���b�k�����r���mqo���Ns\��{`��b37/'�g�š����H1�`���)l�-P
 YMNZ��zF��pYcY�KX_Ԏ�QU���_�x��!C_���T��Ʉhȉ�c�*sI @����0>�	.fM����Ӡ+m�ǰ��A�b��%�>���:��7�92>	Đ�\��րj�#w�����
���&hM�J	vv�,.y-BW;sl�\9�|��{�܋9�Z�Z��M 9���������ڴ��^LiR�!�{��*F��4���E�f�Gx��f&��[{�@�� ���k����'	����h���:�7Y�α��9�S�M8�=�t����<P�������m��`'\�)|�vS��v��A;r�.U/�_OЗ�g�Q�����a�xb��S���d:Wm�FXwA/��F1��Ix������ݘF����R2�=e���l���Y�,�!Kb�gF���X�D���C��:<{�9.�N�^,aD���'mN��?��5�Λ�ן�~��r�;�8!�b�:�O�H���4�$�w��l�}{��F��2�}�gR�5�@��ç�2U��@�0�zW8���2^3����C^�0��#gc1�z���ߘ�4�9]A�)��c�A��,���+��@fF�.#WM,�ї��;,)�_����2⿐>���%uּ�{�P�R6���`2�-p����������"[;��^e������Ӂ�E�qcYD�%T����k|����ݫ��M��Vi�QS�T����	p�p,����7Ҽ����A���` _h�5N)�d�d�}w��ng�p��Y��E;�B3��ǭ ��'6 M2`��w{I职R�~��ee�l6&/<pק���:΍F�2��JQ9�~m�8�efj�:ܧE#/g'��W,�E��	�Va䖈ek�m�������+���|��P=�qg����sLNCi��l]<T��ۓ����(s�{d61꒽h�{k��[E�o`�n�{[=H��|D����$�&R8rĳ����?����W�1>F�3$�"b��a7ڄ���OjO ��)����~ �8�kw)����fb�E)k���t#!���Y����Z����X�p����Q}ƚ8�d��� ���6����Ĕ�������
�ln�_��K;/(9��ӴK齎��:�pQ��j��"�6P����%���[Hd�2�:�J��bm�%��e��QR�!+:���j7��CH�(Ԣ����2J+S"��Oq�FKH���I8�n�hV/�Bp���u�6�
�ejYi9E���.��͂��./������1㷚��r?&A:v�Bӡ�X��^�MZW�p3�"��(�y<sȉ%W��K���L88,�	4p@�^ጅa�ϭ_��]�1؆��8�!�rw�f���+V�S�F;�,�ף8o�gi>͵�Ϯ�Lhe)��|�8h�����7[�YՍ���o_�Pn�p[4�*�
�O��ϲ����	`y-�Q����
������K�K%�X�+��Q&Q��������z�֙�S�H`��C��TU�_*>�J̾���6g�z�k�x#�\c�x�b��������������҅��s/�"������	E)���W�#������ 0p�+a⽨��:���1�%TX-$*�KG�Z�`D:g��|.e/a;J���R���rD�F�9q7��Uk�%�9�O����ᑰH�w^a��3^��t�,��`�0�ph������+�1@�T8�F�3���c�,U@^������iS�?)�ևP:>þ�I3g��N^;��+�R�L��B����e��R�� � ��i��&��qO�wā�R�`��8�>`��yKG��tD�bC�6�0�C���3��37������������~V9VSZP����~!�1�|>p2y�37��]�����
J��5 ���1=4a�R_PJ�y���%p����3�im�-U^� 3�Z�IE�-��_��(�=��ܾ�f[��*b&F_�VH�ւZ��u�/A'�	A�H3�%D���C�?ʔ���m�)���ҟ����}M�`y�l��S\�e^F���<,��* t�����P�^
�"���F���Dӆ�d��ޟ��I�Ʋ�Q�y�
:x�P���_�rC��h�n�?&�Q$��2�c�Q>��u!�Ћ�&t��Ki!�+����"���v__x䧴P20�]���8�i�f��	rUm ��}�J��U���k�@"��'*=(�~ �=B��.Ͽz+�EG�.ǐ�Kj���I����4'8}Y �C7(��_�M3��k@�ܘ���D�T삹I����Tݖ�u� ֶ�,ˢ��@��^xg������*g�َi�y��^a�!9K�Ѥ��r ��}�E �ȭ�k�6y~�d�&�ЁX�Df@@�����_D������_
u��H��U�]�|V��6F2^B ��U�A*��E�7��O���/��s&WQq��H�m�j�<�̫�{���Ks�Y4�Ւi�)p{򗴺\��>�wO �:,54v6%e�/ܔxS��.%w�ce�Z+�&�W_����Ջ[{���9����j{bvl�wI8�'QȎg�N��N6��T�'&ׄө7/oJn��(��q�I�G��M�,Y��#hl�-&��P�]/Ԛ&���$����tx6R;㤷2C�k�/N�O�Y����*�!j03�����ʘ�4J��4+�~�i���ȄN!)K5�mziO�}�t� 6��K���+ڦ�C���������:�B˙�	�3M��I���5�_~L�>�	b⫤-��6��Ֆ���D=��$Os'�A���v��>s)�c�B^kOBR(����ad�/��L_eSM�0d�Ți5��	�F�F���s�ťg~-��9v.�H$���8�cȺ2Ѓ2,W���`��z3!ˎ��_K%��h�8۹*�l�[���)�c�M!�\۹p��p6�5NY���փ�QI�b{f6�G8���m�� ���oA���z�`JX� (ɥ�O���ԏ�et���R��۱h���`Љ9��^^|�����1�?OV�K7:��Ѩ���<a1���31m佨�p�F����d�%'J[�k�d�y�ؕ��3@��ǈ�n�\y��Ia�uL1����;]��D��*=.gBc;�NFj%&̹2X�q|� ��[��Ժ��YʀEF֜��׍<�I}�b����B��'1�tvP��Y��[�N�|Xx��8�O��.tm�5l@p��%�<�c�t��o�����c�V8KL�w��©�o.��e����m��8PH2��CҤ	�tѤ�$i���g2�s2w=z��4:�`���m)X�S���?1r���{�����%��̨R<�`9N���x�Փy:���4�]�7����^!���b���5���}j(������vGT�,�c�!�T`jz����u#��p'p�ݧ=���7��ʉ��j��P�|Mk�K��Tٴ�d������-��#���×��&�䖑x�@˷������n �)@+ 벜eM\���@��-!n��1�^�آ,73��U:���}��ypM7�#�'w� �͛��.Ӷ,�)����#^ی���^8,C�f��\�z��l��֚��_��.m�j��%@��j؞�2z�$��h͙1��"Y|�
�����L7�󳪴@�"�a�W$H*eVa?��MlU�荑�{s3�DJ�]��h���X��WV��b�yBEK,�`j�#~�����C�
.�Lu��ݤN�^H`�q_� �v�7X�a1$���.ӭ���m"����Gy�G%�f�� �7.<	�&F�7#��[��z�����h�p�h��Zm�QL&a�Xp��-��wI#0��ݯ�x3D*ָ���Q^�s��x����w-�"n��Ȁ���*�0���Ԯh8�)�n�Lm3x�r��~[�7��l��/����,���j힀�Br];?e#�k*RRm���#��y��h�=�~�'{�i���Kz�(o)	�����3�^S�ͼ���O�(��!�E��Z��& ,G�~&"�;ࡑ�F��X.p`���5�-�`I�����V��'^T�cɺ�C�[��)P�$�����	��K�jߵ��$�P�d�M�L�A�����&�ԍ�s�D�k������F��5�|�ۢQ����Z�*^�����\�'0f@$����}Է���0��،<��61/�:Yh��Ԫ��ݔ_��)�c]�c��j�z�!fgo�ă�M�<Ph�;XS�Y�^�v���l���:8ZZ28�J˅�2�X�;�0����JW�J����<S�^p���I0��j��J�8�&��uf��J��������L���6y�K��o��\��2!�{^�5ɍ��*H��K��kA�ж/�yr�Y���M���IU(��A/��/1�����J3�>d}���{V�ƹêhm��܁��&�p馍�Қ�;�9I�m��uF&�TV69��OA�M@^�c�~�v�a1R�Մ������?=��<j���]ؠX^�ZE&���n��T�=�B��14��"�TtNM����X�c�nF��H�vd*���ZnV��*����}p�:��֓����u&zǸ�9g�P���|(w��~��WF���έ-$e	e�z	�9_Qpln�L�DJ��Ε��c^�^_��vN+N�Z�[�^<?g��g3�����5L�"��Y�򳚲�n�bI�ߣk������`Ҧ̈́���Ԛ'�)9�X2i�l�ٌa�f�EBv�h^��{���w���B;�ٵ$w�i�����6����.i;�ߐo�j�Zr�tb�����к@g�޿/��_�d%��r�3s,͔�{�����Q�:rj�6w4;�w�Ugxƌ��`��j;����v�x���1!�S��U�぀c�Ϭ
��vV��� r��@m�	S2:�B�[�p���h�>'kXL�30p���_Z)en�4��%�A1���gY�]~����D��`�����	p+�_nS��"|@Cld�K�0��e�ց�ZY1xTCgZ 5R:5����� ����b����5O1�1���F����Sj�O��>)�A�Lo/�Bf�Ƅ�I�*I�����Z�/��� � �8
�4gJq��r��(w�MXBE��v�fY���Z��g瀯�I�E>�,�-���VR_�!T�� S�����C���C��-T�(����h5L�M�h7�/��&B�=�� u��?�ǖ�|[$xSr�I�&U���d.seYǿ��C]#�AT��8m<���cY�L<;�]QhG�?���݂5�A��V4l�P�5���2ln���D'?�$��B_+�q��}���Ri���ݻ�@�35�H�"J[��$�̯fmyw���୷7����nL�Eg򪲱R������J��4�"	�H0T$������]�����\��ڂ��h7G�a�2��Ɲ��_Si�~ å�%Z)�GA�t?��>�t��'cN��� 3���!D��q��L�k�}3���U=��G�㌩46��b߽&���LJ���Q��殡����� �݂o���m*�`������քD�Y�q����Y[j:92Pp�-��Sv�����~|ھA�g�8?���\��L�8g�+�� �E��J /:o�����0�6�I�P>�r�gȗr��{��|cnꊕ��ձ�»wv���;giw��X�e��!2X|iI9 ��7�i�1��MB?��c����=�$r�,B�H���"�lNX�U\^dfQh�?F���-�\&��E�VS!��Z����F�;Q �<������"�2�Gf
|P�'�i���������^~�Q��_F�\�<c�#[\-����\��P��x��X�%���L�d[����6�<�jə�@�/��E�7�V%@q<KyO�Vu�r�㵑%�� �Ũ`΅���s���i�
��҂&D������h��4��>��t�{��]<�k{��#����e���šۍ1՘���(��&	1 ��?ϜZ$����1yj6�J�J��:0�s�W�drDj[׺��c<( �#�,%�������u�7�;�{�]�F� ��V�W�T{�f�U�3�Ȭˣ�
+�_������	�z�^��0u�x�|b�+�#[tH�@��6t�S�s}�kM�;���3%ރ�R1�il۱�v?���c!e�5 >|S��<&Z���)se���9R�[�Z�ڪ�ED��6yD�>[[ESy��<
uh,�\�,�[h��GC�o��[� �bVe�X|��� ���rs���lG��Q)�q"@6>�U����ľ�_�H7t����2�8t����V\y���(�g��^97qgw[�f�*d�C\�o�A�q�B����+;;Ֆ�s�J��m�� �L��h{ၚF,L�_�SL8.]+�0I\�e�Y���4M��6Ȫ��S�v�K��WS���d�% ����R6�X���j��E17��-�d��Gh��n>�bzܞ�" ��Jr��sf��RU�䏂�pL4�]&�YP_~��D`����t7�V��R�}���S�*��ӭ�׃��Gˈ	B��Rc&���3Eb{C����EN+�m�f��l��0���
 H[i�[�-̟(�ሊ�,��?$��lT�w�)?�C!����HF�)��]��Ge@
�w̳z�Z����+Dω�d,��U�����>"8&���C�AC}dOɠ^�<�h<�sx,�N���鱠#3��2G9�(8��㙉���)E>~���?�P�$S���"]z��~��zg�����w�e	;���
��F���X<��y��A���x����^����胞���=|��A9D'俔�n���P�e��)������R"��g}-���Z^vGӅ�H�]qٙ��P��>
��5�p�-�h
,�Q_�ɓ��n�l�|���u���5�
Vܵ�]\�g`��iŏ�T]A]Oh�_� �$�ш�k���B����q�cul��AVYQ�/��U���k��P?ߴ�Lrj��t.]�X����K��9�.FHC������U��-��I�80Xt�����)�}YPP�2��
�?���8t ���'�s��iJQS6���-�Ԟ=L���y���J�2�@ݺMB���d��l���%\s�2����ٔ��kS��w�� ����A@�(+C��&/�.���=�V�]�$���+H�V�-ѐ3d<X���+BY���#�?�1@mP洁���������4�[�f�8��c2�dM�B��Y�
Do4Olt��?>Y�2��G�`@cL*�)DL0,#hڋ*H��sB�TZ4��F���R?�'\�u��^������;��"�O�Psأ�wA�z��S�#:�t{ﻪ�gF�S�U���}%��L�gU��'�"��'��$&���7�A���f_,|p�Ic�!n'q�Ery���о�e	pnq�Kh��i������ZY������xV�%�_��$��t��#9��2��b͝8D>���+ý��A��촲,�ߔg��2|�����([!��,�	�0��W��y �N��td�TE���ڵ,�zN�S�S������'���16�q&}�z4f;o�rWӥ��:/�����W�u�2�H��~��1�(y�n�B��J1��INM�S���ͭ0��������y�x���#��,���?g^7U���mO���6������0��,����1�R� \�v�]��Hy��u:Lߛv'S����%#m�R�{2&���j1�țP�o��.<�ⷐ�������ه���x_��avq�W��]�@28Sf`�,�A�>�5��6���i�~vm*:ׂ���*���e�	/�K�����r��=rg�C�`�eUg�
	ガL�2��&�U�5�r2�M��#r�4+�������H\8����f	>���UbC{}ggH݌�³��]xMJ�,���H���� }9�J��C��L�0T���+`� ��Z�@3C�^�*ZRZ�X���%݈y�_�ϱÄ�g�ў���
���.v��n��`��Ae(����ɱ�^$�o�~֡��<ܞ�e�''�$F�'.3{,�Nu�m�`����Y�0Y=KN������p\��uT�:�)�~�4ŏa��IJ>���j�`:�>�0�$<6�����_��$5^��b��dba�Y��h�3���A�������\� �iE�T�xWo�=G�.#/�g~"W����^�L'^b����[P@�� �B�f	����+��V�L>`)��Y��[��/э�<���5�۲�@���}�^�-����\�n�4|_(�L��X�g94	��ì���Wޚ��؆�h���(v{g�T�Q�d����%����UW���\���4�N��`��]�|�&x�n��Üf&(�d��BD�փ�|��rDH2�෕@����������d!~�e��z@>Eo� �~}f?�>.��&߂6����A�Z��Ϙ���F,�5nj"�Nc0�c��,�Ǫ���#M��[������!�o�>ͫo+�Ք�ܞގ�4����Z�kN�%_RI\/����W�'��%Nf��N3����Nԫ����*��D�!Q��?NzxI�H;��͔�W��3u9Ҍxa`Q�j��]#���� د_�%�{�V[|�௨�@H�ݟ���u�V� ���t{0�Q���?�H`�����i�(�z4׺s���@]����9�Z�Qb�|���G���[
5��a���,�.��w0#V���,���^����;�kd"�us7xSpWl�*8�,���z]SmIAAwG���6vw4&�:�S?��|���z�<_�)�v61kZ�rMP��ݛ�K����$��aJtڤ��Fk*��Qk�T��ehMuf���=GI��j��G���7|�X,���^��o�="s��B�!�&>i,��n�@�%-õg��E߰[s�|� Ƭ�X������v{��(j^�R)Z�2
�`K�ަH ���=H�>_Cyn{�>��#��nG���;5b���Q屒�dƉWYZl���������5]u��S;�+��~+�)�rN}�S^"�C=i��`fؒ̑o��\6����Ir���/�ԺhH|mI<�U��E[�0���%�,��¤�\�D&mڛ��ԓl�b����d�n�0�d�A͠�ud��P�V�v��bq��P={�e�>�i�F�^*M ��v�@�R�-��6~�~aY�ѣ��t�SsK���B���Z��&�U�<[}����� ��e��f���Z�J��`�tT�]ǃ�"*�Cb�z��x�l�o< 0]Ϊ�X0=&��\ZȘ�\WM��c}�S���+N�2�Nz�czn�7�C��B3M��E3�[�"�㰬��?��E�����[�M�i�a�\,~�r�������e��Kܹ���i�����v9�D?�N?r9%�%y�<�	��
�=��ۨ�o�}���l�$@Pd��������m�2Tk2pݽS�
!���,J/�Q�#���U��L�䏦f�+���al�CC�qЃ�,3Av�"GW�5q�{E��FlL��\g+$����T@�������t�S��(�=�n�R`�a���ٽ4_�k�Q�o�i��o*-Fẑ�ɨ IM^m0m�3�
��ϨsT)A�m���U�)�3�gd���B9	�?�F�s��+J@i�7|���r����z�Kw��,�bP��8��f�+o��=�dZ�3���J;,��$�f����V:Ϙeo����c���?�W.�W��hm��f5�E��?n��k�b	�
M,p�o~0��6�d�`��7ҼJ �5�@�S�����O��@��d%TD���S���-��n�����o�v����@��R�n���`�O���p~��	f�)m�#���g>�����޶�a�Վf�w���;t��+wz�6C�zL���g�T��௬|����>�������JNH�ɋ����56eY�7xHFIjy9����i�D���%d��.ҵQO�)�`&IT����A���H3	�d�(o��rHhP��L�yYK�ê���c7o�������n���v$A=KV���S�����P�Q"*Y��;�u�b
����][�]T�T��ˬ���H��Pj�ni�K�+Q (�݊5)hF����g��kS���S��˼�&�T����3�@0�hhm�Nm�i�
��)K`�A�	����.0�h!Y���)���(Fq��?Yh�'����v��4����|�~35���^.$s�m���qN��^�K&���5�"η���ra<�ΰ���@�9}���.�ܙ߰n{��I0	�琄�;\O;D�ւ��0=�)�FD��ښ��▪�{]�,�"wQ��)_����.�+gW�y�5�:��_u�������Q�9:Q�a�5����W`���fARA�qr ��'�}�INJ��2�ی ~��o@8֪Ͱ� �Eq�xr�������ip�*�Wi�[taf�3g���[��zvA�1����9�����ۡ5-�\�1�lf���ӗ�X�ǁ�-&�u��Z��}DёE%\((�0��zqL��}e��zf���4��*�Qx�C��^���ڼ?�Ot�c:��h��?ێfW����M/q�Y�Q�M1�T�7Q�'���@ح���%x@1|u�p4��X������*cc����z�(�m^}�Qu��Й����N��=��T��Tfͷ���K[�e��bM����Ϳ�r���$N-����w��"了�Հd�і��*����Z�ѕ��B��N�Y���@�Y�j�^���2"�n{"#;OS����̸��;kIbLMHxUKV<�>��4u��S� 2��>٢���%�8��]�k�]HZ�'�g�ihL)�v֒�w���.��ݖ]ܱ���FS9W�����i�b*8ƃ��5!l�%&�P�w��<K�����ʎV�R�D/�߻T0���¬�m�󨨄����1Ĭa���ww8k�I�k�_B'E�9�W����o���"�����*�"�e�<�=.�K�;���~�_�ޜ~�q7'a^<㈷|ԧ�v���S�r���Dƹ�������UR���
�>�����1�F������B�P>n�>p�/�xJ ��*-�ؾ��0�?do�߁��jfh�k��̰��X�+���u��$�څe�|
�J�GbF���/��;]��ߞ�=���]�U���@��UJ������i���X@�i�\���əY��p�9	!q ���|�L@��or4g:W51�wi7�ltk6�BtQ��_�o��)���d��eYZ��j�V=�-�drY4=�E.O��&��kf�I/>�@������H�e���ѝ@]����ˉ�^�,��/�����3�L_�q_�ٹ�� �d6�E���>�6��t^`�<:��ҁ�JM�P�����Nr%����X����̶b&࠲�%zw\0ྃP�P���ND������sHY�@�>gvϽ~[��}�x,�Uo(7�5���Iq_����K����d@e�_Qk:�Ha=F��P:pVk��&V�X�s���R�����u$[�y�Fo
�whƅ�	P�7Z�*B0��۔�]J��x~P#!2����,�;���d(u!M-F3�Wٳ��+U���n������e��r�3��y����̲`IJ�m ��z�ڙt���<���] ���5��7K��������[���'��������"�jP`ԁ��
+�qyR�rl�TL��m�M0����h6�Qw�v"��%���\�I�?u�bm��uy�Ysjo���]z3,�.y����B�`�j�d�K�nZ���l���g�X�ԥUVr��w��'�k�3��]c�����3(4F�  �<F�h�H�'�)q�퓩	/a|F񺬒n��|#�u�ә��>k
Y@��	��(�]��p񵇏e�K�a������P�����p�nC���5�u�k:�]&�9f���p`UQX�weͼ���@t �Ǹ!����
K)"����Dî{��.��3�m�_�@V��O=��b���4b�����9["|L;����nݪ�]r��_�<�6PQ�H�!��q��)@,f��W��j�I�=d�ԏ��BO9B<�뭌�1�I���g�Ι��:��I �\RKJ�,p�E=V4j5�nIJ��--;�Q�=���P}H����V���?���t~8ܼ�u�z[��> �R�U�`�,�ڱ,g=��f|`4�(�;#k���C%l�S��˟�Q��G}r}n0�j]$$��ƒ���C,����=��*a�I�ԭ~�.NVC�����u�OA��Fg��^$D߼&+��_�eY�$TRl��?���v������xi�BG��ӵ��9����|s����	�T�#�u�&p�I��^.��$��+��scēs��0��րshI�*�4�D��Q��R���]�I�@8�T���H��TE{=�,j^��(:v}��(5��lP.�9H�z��S�B�e+t���ܖ�-�[�y��xMN�NC�=�H��đ� �z��ծi|�L#���ә�MA��N��%3�����>�����V`9�,�&Y�������z�Vߙ������{闓� � U�4O��!@> ���(��1/�o��_���q]_�s�)][P,��BI5�d�"6�I�|�\S�۶oogQ��{����XI%��̶yP�������$/]$i������H]��4�$�
��Jϟ�	���}{���{rE>S�O�U��c�ͮz����qKߦ�Tuw:�A�LTTaB+�8F7N�N�N'�bIT�R�.
n��������槁
�����ܪ��c�8E0P��ڴX�~��F�6��}�N��>�9��9D���ǀ����K�O�&	T��.6�L0&�@�nm$��A��C$'���d��ző�Xnv������
9ϠFZ���>�+`t�7.J@VU�q��r�u/��xfi�]Z^�����̩b��r�/�x�Ä���$�v�1k��N�,�3~S3�L=DH����*K��_�����Jw�CՅ��~����OA^��e���sM�o�=���m���(ݯG5��g���xTh��_¢�gb���sNҴ8r���]��������8=�Q������t��z��dT��|W-�S��	�'+�7&�o�E���9)&�ͼ�t�;����p��4C�OGT�x�;��sr����ʹ8�/+�t�ׯ��S`�!��䯚B*�[ՠ����淢!��r���_�ĥ:(!R��1W'��.	��=ÒiT*��"C#.61���28��L���e=H������Q_�����
n��?� 
�$��H��.M�jV=`͝	�!3K�������-�KYAY���Y|���_ 6$���N
����b#F�
Fk�WN<���
��R����/u�W     �,� rҟ" ����|�����g�    YZ