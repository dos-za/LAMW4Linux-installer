#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4209186877"
MD5="f6b0ef291422c06af850dbf72474f35f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23564"
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
	echo Date of packaging: Fri Aug 20 04:17:08 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�aq����-��oݗM�V�)��I'�9ۙ�nJ���� e~�ر�L�=t�*~�n�$T��Ir�T�k�g�7P������������
C���q'W��H�J0�7s�-����PH;|j8ݥ/�� ���&;ޔOu8���CY{��%��K����s2�_sB�݃��[�E([������2B���%��>����N��u)��D��Ɗ0���8\1q$Ƌ�`����k��z�\� ��֛�fG�5wղ�Eph����-,���6p	��+�j9�J�`a����?S��j�O7l�b�}q{����["���|�>���y����09�q�f�z��8��C�����&w>ted}�KƯ������*�d:ۣp��ꥃN��(��-��[m�Tg��P��#����ża��^����S6E�������}���l�J%Տ^:G�C�yL�!�U!�v�:���3��/�W��4�U�����Y���4xD������p��˛��@X%QI�d=9�^\�Kp����xmt�B�4}:@'�3���X��xbS��m�Mk��#��DF�s�2$~���Y
����㢭��v#���u�E}J��{$y��&���u]�f�����>�� ���u;�J݀=U�`O��RMMe�|����2��'��T�S	-Ys^����0�4s�Z݀��|�E����\���f�(x���O-�Gx��U���J���G"��U
a3\�@�#M�����X:��\UXL�:_L��Q�lp_h�6y1s����C*��d�G���1��h���>�!�=Ϻ�,�����j]�&�=�\Bܨ6o��äv���|j�εs��Cw�F���8^�ᣁ���	�/��˿Ɯ��[!#�Ζ��)�DB�0CS������13��n�|p�n�Cľ� |������En����`���^�qJu��^��,����=c���l�lKα�,T�p�D&Jy��n�2�lH��e�����h�U�8>��,N
~)�����y9�\JE���7��wyӟH[��R[�D��	�\�k���'�Z�Ub��%��2���?��ߚr�"1|5��c�!�Z||� ��"��:�ޥ��|SV��a�$_a�f%�$�����)��s�\mQ_\�TQ|��3���_�|�y���ټ-Ť� Z������~_��V������6����uZf �wS7�����=�a��-}�����u�s��T��CB�(A��I)*�庅�;��ؚcH���p���-�гn4�Ĺ5��ɘpҟ�0����?�e���<�}3T�@��:)��s�����^2��n�t��8���ܮ�[#�I>�[FB�{z�l�L䊣#��4�Q,X,���$�a��������"�-Rf��ܟ�RÂ7��X��(W�P����*+r�
�n%N��C�>�ElL�& �U%"-�����'9������}	�ũ%RM�޵D1wc'����M�Y$]�U����δ�:|�B
�­�s(V��LF��ҵ^�ԭ��lj�v�W-�P�9�㐏}�v�c�;q(k\�dĔT��e����}���r����4�ٍ���ITF�pP�Yu�j�p-Ԝ��e9ɟ��G(an����m7Ǔ���q *ԣ]��pYT��ʱ�|��7�+�/5����׈���o,�Ok1
�8����Hm7��;<ٹ��=�p!ͦ�e���r�0����Yooa]
�x�[��X��)XӅ+�zZ36�\nq�o�V��co{��1�6-�<,!^]]QZ��7�����X��&\���������_���c��pT!�'�P�#⇏�L.�)�&�M{Xx���3;�ߜ;r5u�`�H��q�h���Z�ZHM8� Po��?�I��t��E���wR��z`ds��е,HyI���dy��Xd/��t
����g+JA�&e7`���(L��o'@�Z�),��TY=j�����J07}Q�H��9�V��4Z�!X�-ӠR[/+��>�Z���E�iO�;��'��oC�=4ˡ>�eZ�����$w�}P�ʈۡ�B��W/�X}UB����.Δ�3WI��{$1O� r��a>n�1 7�1l�7���C)|a}����>׳YT��>7���� ��>���x ��$"�&z>��S5�ٽ��c|���}�i�3扊]����f@���h&�$⿞t��"�vPsЈ
���r���E�r~$O��1���0_�bȯ6(�V9���g�;��2a׌Z3����w{}U�=���Q�U(��.Jū�X��Bu�|�x�I�"��j��7f�Z����f��R� p��_��6����I?f"GvDOj�J΅3�C�1}��o(�I�Hr���O���w� �z$��\Ə^קu��1�ͨe?�sp;�罵q��k�����,c���6��e缙:�R�]z*����T���~~L���ß���&��)x�0$���6.�خ�l�z�g�1���]�����͟K$��Cы�R{�Q����D�ڷ�V�j���]jd�Q�<wp���vC�&�/�ĭ)�2|9���&jf%�� ���䔵�1NP�����~�Ժ'}92 ��D]�����`K��o�&��6c��:1|W"�i�\�n7��'����`�І�ՍLZ�X���}i綧nr����p�;�Mp��jO\��iU��8����*�֟�d$Oާ5}f�C�@��Ǯ6d�p�K>UMؙ��lu�,b�^���E��EI�/fx��v���%�Q�5[x�饔g�>w���>A3��rmN*}������VN���ձ��o)��&@J�0k��i
9�^�.�/~|�.�&����JZ&�{7;��旹�w3���w��xV�0`���}40=���F�^0�b�Ğ��d�H���9�`\m^o�]�����ۦY�c��{�T��pc�9��f9@��u�^kJX`�yv�����L$~e���܅]o���r�1�]%Ϩ�*)�N(7��̀�m!�
�j��$s��4�������w(���f�ڻl'=� &/�\�",-��M����S\D�{v�U���,%]��ak�B�`c��I���íM�VK���5[����l�ߜ�2�*�=�Dd�u��
VbC�bG�F�1E����I��Ҩcz�����`rſR�+~��V�^ڃ����)�Ͻ�&Pg�o`_��ㆽ z0�[A�g�Ȝ�� .:j�c���0����.�@�n�2Sy�=J����)�kI������R2hA���I�����C wd[�۝�)ˊn-�����Hv���Ց�D�EEs�f!r�K���\l5q�� �=Vn/����@>��1�:?#��}5�&4���(E���.Z�{�2%�654�!�0�R8�T�U/���YA(ACK����~��9g[�E5���@���*Ov�<=J��C�O�[d�����X�^�1�'-�q�D�` �^)s��|9'�J�}�wĥ(1�V�RTamɨ�����Y�H^�g�f��C�b&=}�9�aXb]�����Ǉ�B`��Դ��r%�^����b�n�[����qg�k9���)pV�W�w����|�&)�����|t�Y?%3���^j9���i�>��=�ːvO�g_�оG�f���$�")}������9O��K�\.mdDnRZނ8���˗�l�S����H;���hwS���N{"��hq���Fr�*ȕ���A)������nF.t�\�5 ֋�o�a��h+�}��S��s֬nK�o�Ƙ_S����Mh��rC���	jW	'�*吻�2�{�P�������������ƀ}��V�x��(i�`r[9����Y�}����@-E7t�y�#=I�v�I�޺�'%�;��ƕ�H|P5�J3JT�8��n��b��	���iQ���=n�6o��Yt������o8v�c��(_�������Rп��]-�{?唀����C\��JUh�*//F�T)B@������7��q� I[;���J�2 8>+��Uݐ�Ʃ�¦I�eB���W�_�������|�*$�k���ӡ��n���0毺"�ݵ�\���3)��V�u$hQ�&�g1\������xˣV�SAΨ�^ul���wǷ#���5���'a"��#���ݟf,?v���f���?�H����߲�y��*��H�n�6���v����*w `�����пR&���X��� ��y�{��;�"әe���R_	G�/yY�bĬ��X"�g�i�@<��S����g|Խ6��j����)�*NYJ��zlImɨ��/V�p}���>�d���&�����
�?�+��1u�I��lΞ+B�҄���K��M���J�$$�E_z���.�#���F��z#����~n� ��av<� �`,<|;�-�R���ǟ�d^�y�hE�bNf6U�L��~�:��_���0�	(uky޵c����?Z���gh'w�r�[6�ۻ*��XM����-Z������;����o|���G7�z]�Z�ɜ䢠CH�7�',���*�Q�d��b�!��N���BD�\���I/v�����ݦj��Q��+"3���-<�1��ɷ���?��;eB�e�5@�Z^<e��u�h�)��O#��^�p+a�&JN~}_$_;��!.��\{�@(fH%��*")7\��v+ـ�,�\�7��D�	U�.$����$	��K|�_)%�2t�~N�TN�iJ��NG�N��~*:D�9{ ��R�^���֔��%�d$�^�umC`׭�r�Yt��@%��(���OE��r�<<�W�.����S�i;ic���y!-t���ly%�3�i��]=5����@4q�Z2.)���N$� o�\��37�$E۬D��3������Y���Ɍ��1-�N>N%n��(ǼJat��Oh�����]]G���|���nQ.+���S�=�Z�l�3���"�T�G�b"��]�k��L���,,q���U�_�}���,�^,��r?��4�@
[�qn��d�x>.��B�!C�i�4��=:(�V�0�Ȱ_�c�u+D�MM�?]��"�$�P$��혔�ޒ��-&m�xp�Pu�JF�``3���
����Z3���֖p��]n���*�
|.�,Qv�^@��<l�Σ7���u�;n)/���C���ův�5�(�qՙ�!o���,�]8���ǟum���^�ʺ<��š��������mg虯�K��N�!�G�s�+d�������)�����j0��Itx���8�n���3d��J�R��1�(��?��u彏����ްX�`���7Q�/��ү����E檓� ��b�/�mj�QT�Sn� b}���JٮC�
���|�C�)b7)��ld,���rL�p�]NA5���1>)ޭB/�]��ϸP�fJ�z�Ճ�!I�����B���N'0(U���	Æ:����2h����$�L2�h�4)�c����?H<F�?����F� �n�ӻO�%V!\�GM�Û�XA���)��U�����cB�����}�IҰbdC #�Jan_�������R��_��>X� ���j{-w��w�e��V)�j����y��a|%ύ#8��9�����m�x/�<�@LH�R5�d�W�R ��;�J1��\��Y^�4�e�1�	�����y}�\.xbc����W���b�l�ؘ��r��.A�A�I�Gю�qѨ�B�w�����U`��d�=��*O\S� ��]��Dz�1��� ��l����[T��R@_6�{%0��p��ort|�v�������C�zCe�	B<�٠��4�t��Q����Gt�<�#�9����ZG���%"C��r��9�ǉa�/�Մc6ހ�c:To���^ߟ����=,u�%s�ቝF��^��A(Ȣ�8o>�K�{��LDx-I|RR"ű�(�B����Cz$7�i4�Q�ѻ!b���=W�$�2��d��	�%F��&����P�0�:s���n��q����/��dN���y3���$H����\U��,��,� �'\@���R}��n��]�+�������%�h]t�P5G,��I�<�<���t2�3�
�B�"����
�
\P���3rw�VyJD[d�lε` �$}�L��fk$�lΘl89��ʫuF�dE	0�V��_�֢�T���@�]R���I��9=g��]z*��࡙�Z/�F�����N�\����F}q�i[�J�;�}�3�C��$���i4�ė
��z�S�����1^w��m�?oj�\��E�[�ny�z�p�/I���Tp!��a�u���$��Z 2�{�G��ǀU��Z���t���zt��#":F,'L����<���A�r�	L=������fֶ~�6!��l�& �_�˦�<+�YL�8<����.��z�Oǝ2���}���_�% H?�K'Q�:UG�!j��&�JfLL`}�#�h��%�}i]D�w�a�|!k<z`xF��#�V�]�b	���#)�Xc��ߤ���l;e[c�tug5'�χ:H��&_]:�~����G���m�2 ن�Z�2����#n����xOk�������I�����3/]��S�d�9yz8Ǔ "�(���j�][���$�-F5�(�3�������yU5	�.��Ŷw�������eA��}���ϵ[����ں�芫�����K1Hm���Ġ �bj�� a��Ѹ�s��`,�ю:/��M�րXK�7��y�F�*P2ݯ�[�r��7����a�ɧ�M�������Km��@�'�����<Įo�7ݠ�@♁:mK��.s�����̾kP�ۅ��^'��M�at|�I^���#�j���f�\&���T{�V#���ɋ��'�� �c�;͟�����Ԫ�OH�Τ�v��wP{fE��_�#��`ŦD}�R��Y���>XI��|�J��5_S�sP����6��������VK:,�����/�4�8z�ѥ��n�a)���4���o*�����z��\������I��۶�+w?�]
�����{Jq�`����2ȏ��a?q�˱va	��
�2��=�B��3���t�I]�0�n�0�Qf-G�W\�(� �CH�K��/%U��L������;�s9(��΢'k��	CI�	�_+>����_׌�g��x^F7$�C-���*�-��S��j|��æ�h1�|�p%��ѕۂcL�*����������� �n����NDs��+gC��"#��?
2GR�"h��pſ�.�	T"��t����Ǜ���l`r�'>�1~'dԬ�&��7���v�$��s_�x���)��d=i�cژ��Fh�W�(�K����ڹ����X IRDo��SAϤ�C<��{��H�9�>�5h�g��z��~h�z�a �䥆5�(X1�Rʹ��7i��Ð��1{IR��{��H����tK��S�G���v�j���_�=B�ߞ�G&w~V���j��f}(/#���=��?&`�[D.�%��0M��z���![5m�f�u�����n���lS�3�9�$n�Nw�i��aVs^w�y~\=�F�����o�����#y�����~����>CȞ���wb��#/�	�(N�ӝ��1��a��D(�JP����Ǻ�ꔮ_�bS2�*�s���}2��5���&0	r�,�&h�L�1��k���"Kc��Z�f,E33F������a����ͫ����!���ys�0���������D'����FXm���`����s�Wn�LP�w�b��;.ʴ�{��|�JR*�L$/��<�ߋ�C�9�<g!ȇ�I5+F1mP��Ą�GI��(W�^#�&= �V��ak���+j�ykyHk�jir׽����dBH�^�>��qX��e�2��Nx��@� �a�#�A96��+=�'m�
<�.��)���j [�����wst�C��}�s[hN��x�\ ���L	)��ܺj�1.O�
�Z6�Fs�����~HEi��2�sk�o�	��X5j����T����u���T��s�/�8|2��g'-<~��ܐ�gp׽��>w�ڃ�:���	̥���(�5��H����a�k�)��&zu?�>��e���H���B:}��m!�h)[&0�!f#�B�#����^�?�N��ic5GmWĵ҄�ź������/��͆�i����%�*�o�=Ҭ{ڝ�f>�w�*ڥQFrC�}L@A�c�P�⦫�c	�UCك2�ґ��0�O�O�l���>��vA� C}0�Q�&����1���e�<-ڕ�MB´2D���
�B�I�B���P��.�_�8/��LV���s��hK1ԭ�]���{p.z�aD�pi�0O;�5䖂\7c�P�L��]�'N���`뢍`o��ңD���I=-.9ۡKZ��VYO?a]7�k�˩�5���=�W�UYc�~��qD�F�[�4�|~W�q�I�Ɓ�I\p�ˈ�
k�T �%�D�{�P�2/eYr���~�ᄫJ�I�xַ���@"�H��Q8ъ$���bT���6���p'K��tqF<eU�#�.n�CەG���Y�U�ݎ4�G�O>^����?95�טU�:j���xYZ��x���p�h@7�_x&��rOX$��ҵ�Å���]C��g>���*�X��,}�f��x�r��6�Q�j�7k���|�����8��_��	�Gd�.~�Da06)���:跭��u� ���{�m�6�%���N�����'�4���dl�vE��.;Z�1����F�$�q�<�e�#-�����~����@���J�{W���E:äJ5��ĉ�� Z����� c9)T#�n������'���[(֒���F`T���E�x���q��:�G��ě����F$������!���^�s�+��0������h���Df!��M4H����������l�#���Ac�����*��r�[�Q8�ݒFÓ�a�.Ïun��&����8?�V��m�v*�8�J��hVr�R��l~������>�m�RB�3�w⋴���6�ax:�#C���H�$�V�4�=��<��r�o���
�2� n�2^X)��{G�Ң@����g��(�����=<��
v;�|�#�R� �׏宛�U[�&�{R��2���a�b �����D�)?��7���+鬻�"�L2R9vE�:oRGMl�CHv�Y�Y�ȃBZ��f@��.�w�[v��R���֋�J�W�XK��L/�bY �*�'�%i�:}X�]��+�_�	YF��k��
k�^X�� 	Lxt=	PPh���	���<�}�5�	�2���01����~g���l�KE��xᭆ�cP����x6�:?p�&S�r�ۚ:@�.E>Փ����W]�9w���z���QHDSTɐٝ��v׶��a/
zco�
�݂m<��D"��=�Es��mF?1���$����\6�zr2:,�j��K�����@e-��`���UFnR���n���{��c_H��]/>`��~t��s�>�6�E�E��c��ea.yP24Ҿ�d����#����}o�u�g���`Z�e kxh���6�⛀{�U�Y�<�j��h.�ca�b8.���pj�pik� �dk���v��>���Ї�u|I>\{Ŗ��a@�Z7�-#�� _������6��*��V��[��rA�QB*��=��[�B�| ���?1{��5��Z���~��JyW���${ë��z-����R���%��Nʁ6�XL� �� _�y{T��m/-�u��2��N��S;M��Cm�ms���+��Qh]HK�dJ-��#l >�E������
�y
�}����?�z���)�0��}3d� �9Cc}l���`}�Z�f,�}�7���fB&��Z��NP6�G�����sv�1�;|~�B�0"#pqa�n~�G�7z9x�z"K��u)�U���7^� g���pfQ��]�E>�U&��>X�.�>��
Φ4O���(=��L�Ţ-I��
��$��ѿ����$}�x��w�9���<W��֞ŷ�RTv�٬IKy�J!�?-�
����q��"w��ĉC����-�Η�fh��	#��8�ݘgλ�ה�D��X�����߉�7V_r�5˗��p������Eg!\7��䋙,�'��/����*����ʉ�a�z<��Wr��`�U�ZL��K�{&�{G�IK-s��'���Q ���A�.ɹ�Hx�t�m&�ή��Е�������ؠ��r��A���f���3�C(�iW93��Z�Ĉ�wC�����ZE��y1_��p���q�͚�B �r�,/E��T�����f|8��e-�l�b�i�tL���A����;>E��KQ�%3S�AG���b���M[�]@3`l��R�|�̈�(����,8�غs�"o�Y����Ϭ�9��+�R�:k�>��'��m��c���e�����!�C��xʭ�O�o�w�M�2q�E���(:��KYX��'���s|��:P�G��e�]0�г�
��T�e���z��Ͼ޾:?�*�d$���ߚ7����?D� $ghG#fj���%��uF�k��`�Mlfb�"���(0ۥ92��0_���ȩ���5z�6tiw�(k��P�?��yQk���6��meu��������9E��e);�^#3�ͻ0_鞝�AX���{��<RU�f��
ro=����'O;M�e�F��X�_�Ku���H(&����e�驋T�9h��9�|�%�k��n˸d�~����%)o4旃'P� =<	�6��ك�H�[�3�	����Oڟ��λ$���]�FY*	�᤻X��ҒX�c�`�gv���|ʩ���
u�r�e#uEq����
���-�b�!�yT2�W�J,��
�F�cK/��{üm����8���>*�|Q�k�be)�~f�R\bœ�Ʋ�[Qܓqj֖H��"�버w��{ ~Y�8��C%�e�S�����Nl�A��^�����-�Y��n��W}v�	a�7nz��dn�	����C��"�7�*�oi���ꂡ�� ������֡�eOb���%}�x�O�%{D8h��!g���'@����~�'�ª�}ӆ��o�Q�ɰ`���v�4V�l��!��g�r���V6禫�a��`ݮre�+e��r����O�ݪ�k��?#����_�L>�l������f��"3:����k,�v�)��~&����m$��j�%�$�j��2P @7��&��8�|�M������$Yg#������v��G��x'4򩖠��o���,�<~5���,�(}��I�
�ұ���`u���:�W��L	�Q����w�䗃$����⮱6�x���9y&�^|+�W�v����������7�Z�Ͻc��r�}8�|�x�>z�j��������w�\���_�O+Ხ��}���3Vi���頻㺛�����d��v�s��6�D�����V9���-�3p"��_�`gMl�gW����kw�-`]g!w����e���aǙl��� ��bߑ��k���j'�Ԓ&���4#���&�+�%�
>���KK�E�T��ެ�d��"�ʷ1k�B�i�E���I>1�;�:w3���6�[��)s�O��3���gjQ�7`�>Cھp��������~��j1��J�G[ӈ*��E�ϐz`uF	c�~���B!T#�G��a�s3��k|A��[�jv���a���D�i+�d-��E�*8fA s����@�w��
�@fCΣHn�EP�dU���h�q��`�M�`��2�T�NwSR\r&VE�s��r�Ń�T�Љֆ/3x�c��P��#FL���P��b�4�{�ʐ�]��B[��f��5��|���^Υm�^��pL���B>��� 9�%1�
F�`���Wœ�$t��a���O����*��S�-��Ik��-441�y�ґ�Ƴ}���DOut9�oBl�aG������;Vz;�g`q�BDי�M�G)c���p��r+�X<�����]����8xҎz�4S��%bi��Q{�KqI�!�es�OH��m�*���N�g��\��2�h����2�,9�:ø�c��?���&m^�wW~5�I��TR��@�A!Y�G,�ll3�H��w����C��c��L��Q���s��U�R�y�����2c�l��ذF���0_��H�v��}�� i����}������h{cmq�k��.�~a!�����Usel�FOL�ffB3������-�ڠRF�e/��c+v^� ��/5����ia��$��ْ�J5S����G�m��L��$�P������5�k�${R7�5�x.a*`ː��7�=�p����"�2�J�����h������w��{�.a�DI>�>�[�5�c�95����*��;�0��l$�Y��n7oj�l�jt��N|v7D��M�|An۩�s/};X'5�W�T2,�O��)qX�x�+&G�c��+S�ĥ���Ga+bƀ̌s�E��� �S�o_t!?�ͯ���R��ns�t"�#� �F {�A��6.�Ć�+����?CQ��o[��R@��s`]����%`�l�����b:UӼh��(�a�,�aJ��Qv��ЮBb����5kQ�a��X� �2���eQzZT����q2���툞{�F#�%���Qf�?�i�[��k�h�֗�St?�VM��iy^T7?@GȒ�1"j,������y��vFNS`}3=����v +��7`c��.�x�,=-X�t3bS&���j���\U��h��u)40-���_u
1:��@1Oϝܩ�jmC�`V[���P�Y���\�@��P�����"z�xT���=oM	�h'ЃA\I8ɡ�2d�9)��)sN1�*&�H���Ӈu1�Wt� Z��VˠG�L̯^�'#�=ۺ�e�@���F1M�J1c�	b��%�?	ޢkz�~n������h^��,��ǜÎס�'\J�A������\��6���6��S\L��(�դ���\�=��g}�jf��z [6i=�i��Ud)��o��:��4);�������-���v�W	�1�4(Ǭ:�_S�
�5s쐰bGx;`u����`�թ�B���X�?t���O=��A��%�:�Z�瓾�:�	F9}O3'Y(��Cd�A���!��EƬz­���RU������q���m���|���6t�mN��Ȇɤ-)�00���,��}s^F��O�׷F�<��/�ipA�4�T�@�-�6AK�1���8��l�i��សi����٨��.�t��vb��� @���@���
�L���G���P��2�(��&ݏu�f	۠Qˍ�4
'3�o*Gp5����|p=����O�c�f��$g�N	3*��m��m@� $r�B��M��ɵS�ſ�xI~��w2Ky�����w/��W%��w���!�j��Y0|��m��� ��b%Df>+!GiX0�{�[�����%L)j����Z�8�Z�kip�k_������ǳ8���⳩�N�. "��йuߨB�H�,��k�|��ޱ#�îx���%���R�:X��A�r�nV�N��	���*�l��2O3������N��J�>s_ߌr��Ƭ-'d���u_Y��h������*&z[�?U�GL����\>����4h���$
��MF�*B]8�f&���~�_J�c�k�n���i�/b�(Q�͈-9��G�ǎ�e
�"#�Z����E�{��<�_�a�� E��$9S�d��	����]��D2���O�c�vџpg�H�'|Y�3<�*�u��W�i�؜|ɑ�t�Ę��Ĥ�~���
`6���a�̢���,�n����v6	R.�C �5D��,~�)j*�a¢9��1C�_/�d�6�Y($��5��dj���>������qA�� +��#,q���Q��
һ�*&�{re�􏉯��$�b�����"ǥ��AJ�=��$Y���O�]��3E�!�-��Q`M��Ԃ����!z����͡8~�P>��bZ�j��uG��	'���o�_�a.��!��P���+q��.��6�t��M@�8����ATҶ���	��:T�Ҝ�Q����M�/g��`w�Y��[2��f��wQ_${aW6+��l����9:�@6��\��=�1�TV$������BgND�2�{�U����|s������y�N}�1�)�)�u:([��!ߓ�d��&��+E��B�h�n~����)!mg���f���A�e������0��V@�#r���Q�GT�;X�N�+�g:��Ȫ_@X�`h��pG͉Ľ���&�K\�8_��囆h͗�9��p�/|ۿ��B8�"h��h�5�)�Ċ���K���9L�i�ZT+l�jNմ�U��^�&r)V�~�l43�`��׫�� ��TR_ů�Z�y�o��	�m��-���6|��u1�0gWh� kt���|�z��mrB>��Y��I� S�É�r̯N�Q��'w	2TJ���ZC�*���n�@�!x�T��뮯�3m7]	�V������]�Xwb�Q�*�$y�N�Y̌
�u\y{����J��bion��Gi�fo��s���~ڍ�P��-��i���=5(� ;�A�� .�M����s�j:�3H��NT�
 	Ww��yU�
A?�IK���#��^�r��k�G��y ��:�(C��Ί���3+>�>�vd�e��O�In�Ԝf�Z�W:�#K�FѼ�P>E�w���6$7���%�~By�.�#G���]쓕���7*���3Uz�VZ�v��{c2�Sr���W4id-�����mX����N�i3�N3��a�E{�	7/.�0�Q��|-��5aC� ��֔�08��O��%�=�R�4��Z�0���
�D�hӚ̪R��6�󏪙�;bx"�*��)��|8�}�ґq�A] �-�`s��ݏ��bd?���'�|���O��/���48����Si"S�.���~3�	Axjg1%�6#�X���ש�#uF�N�^�}�D�"��/,�^���:�rG�=WR��K�-֫�_���<�Vu����1�RN�G}\����;������t�`D��<���y��*�;�r�㤭!E��`�����6��Pz���^�`f��Q͍�y���2�����.%�,sË؎(��w�~5X����?������ʅ��P+nT���JZ"Ӊh�����cBJ�
L�"�
ߋԹ�[U�}���絿w�r|�|��w���iK�G�2�:jX�Q�cY�|�*�K�A���;j�[�S�B��/�ݱo�3�2n��-�=D
�(����I�p�n=��3s��5L��Ӈ�׎��ޫ�:�{P��ĺ_r�^���d/S-��� {���'|���u��-P�����y��ʳ̭���$^~�>&�B*rũh��j�:L���K9l=$7�򬕠Qc9���Z(���
��I�س��!�f�Ӽ^nzk݋~,��#�Nbi\XV��J�����4<��eM�t�9�#2~�n1ܶ{к�; ˙M=ߍ53g`��}�Q�E�]���������chmbp[Z���E	�/9˛�<^�˜��,9��6U� ��YZ�	6H��5mva%krj$��s�'`T�-Nu'�{��>x�P��p�6�H�߯1A�N	aY�fN�1n�v�#g��zy���v1��zV�к:ޗa`FBdl�ݷ�QZ����y�	��u��@��xS�Ol��I�K�`Q����R_O���T_m�gg��t6xk��IX=�Y��S�7�<q\����=���|Bɶs� r�ʖ��]�ҹ&$<7� 5��b+ʃ� �"��=k�.�7tj4�v����g���R�AJ�Q�,�A�7L3,�%"��a*�.t��'.a���-v�X��-]�s�Hn>�J�������m�o�DR&=j��k�Zq������?�1�#)��a'���,y�ȼ�ڂE��b72�`��!�f$�$\'T�B�ˮ~�s�Y��$z����y]�f�S��r�y}���F�,��k6�Sߺ�@{��Y��rihq޻�"�C�&�c�����ca��$���5&���Av�,5���>V�3_�`#��JS�?���i�ihG�$ɱ@�tT��籼T;>}�q�ށ`e0^��'y'����+�z��n����5s!�K$�[pT÷M6\���<��9*=�n64�D��So���v߶�(<O����Cc�T�2*5�@i;��k�����T������Kv�ܿn?�k�ض����YӏD���"��V�����ʄ6�b	p���ñ�_�q6�#�����թ��D3��7�����H�dNR�
�i@x/��Ck�d���s@����P��KA��<�R�새.�$��x"MJ�����ܵ��/V��QIg`��p�]/u��4-�ڡ9^i�r�)'��d���A�sq~��_�R��=�):I�oԑ"�h,We��`�3X��)OpNE�MEe���O���rl=�{��e��*Q�1N�O��%��!6e
�p3fSM���r!��3g�5h�������D��="�}��p�8�3��4�CD�wq� +���H3�Ɔ�4B,�����Ya�OG�հk�ڋ|b,���)~&;f2�]On�Z�c�Vq������}0����/�2�^LY�ri&���k�7��m���&,[r�^�pW�ߝe�6p��A��YDo�zX��e_x����☟tN���!w���j� ��L�AX�I�&�u�!JG\Y��5� )�F����͑��3�"(As�"�E̓3��'�r�6���a�%$t�jս5v�je�+V��`��nߗ-�T�KE�Y��� ��?�3I.k��E�/�0b
@��T��ݍ�clt
�+ˉ�L��2�?�Ԟ'b���ZlւQ+�M���[�F[d7���m��r���������
�7�G/H�|jxM�B��cXo�mQ��AG�ؑ/ETL�
_��/'�e��R@�ᔀ�N�e2DroG�FlH����^>z���ck=�����gBW4K��lPR������ ������#�
(Ռ�ua���u��^$�#�o������l�H�)5S�7w7� }u�o'Φ�K^�����Ѭ����U:��cI�Z
fVnǵ	��vy���'_G,���Ӆ_�h�k@<�\k��a��a�4kGOo�����)�(�؂��/�.�P�w
��k;w��~�7��.�p��8�䮳͝�b�S*]��N�F؂\X� �"��3�L��]&r�usq�."��q���}������b�#�)�i��G�4�>	�K��*b��0��yW�q��p{��ٳ�iU|�?��׏���Ztg����S�@&y�xfC9)�_�k��w�ąՏ߄:��7�p��~c��ƀM����9=�Z<�5<T�,�)X�Џ~��֯��y������)�D�ܣ�U��0
���!�� �iD�E`L���REQO�8CpX��Xk����5����ՅN����Q(h�q_���iʋ�a���vM�W�������KN�+`�������C1�k���SJ���5w�~_&n�Ø�5A��2�2�%5*`�KôF+�F)������7����I<TU��?(��e�h@�y� Z��!�:�F��Å/|b~m��v����BPH:7B���Ų��V��*���3l	6CUr$m��:�B�e�sflD����4�w;7AK6����彑�i��[��?�W��O�B�ʐ����(<�p�۰���/�R���rGu!��_'�LR�&��9��2
Mb	YL���㼿{*�`�%t�
^Sh�b������'I��� ����J]���oJ@�A��O��-`�F�)T_ђ�r:��s&��{n�� /��t9��g���oX�N�@��W�Bx�nHFXϓ��!�N�H�o���n�>���,FV)�π�.�t�)�L7��sb�<�o_Ԛs{�̎����k`t]q ����7�	���҅2����SQu��.e�Djd�D����:��-���z��
vL�x�f(����Ź�Դ.Kް���x���H.ʑ������ǋ�cq���0�!�|b���eWQj�o��*�4�NH,O I�!� l�F�'Z�E3���]�/q�hC�[$eQ�PV��X� tH%\��~c��ٳϭLf*�K}
{b�$���%	ߤn�#��A?m��5[|����9;�`팂��W/�S�wȆ�Ux�L�k�ͬ1 �eo�vB�}��A*�g��vW�)6�R�a���^�G9T`Y^c)Z'�^B�z��O��$u�ezA6�/(AW �|p]AC l\�&���=�v	��O�F�;����h�1!���:�޶����m�'��td��e���Y�b9������1�f��K[��T���.�T�ھ^̌�L���Y�N���;.�f���(�� K��`8/2�.����\"S[��1
M�1G��#%�%��^h{�m"**�����smOr�(�0��S�x-!%�9�BUV�Ć�����m��m�����#�ۜکH�%���JW�������/;Kq;�W����� �[��j2;O V.'��,J0N�;�ke�ؔ]��aE|�2t0�X�D�Sm��Pm��-r�<��j Ԉ���+�0�������[��A=�����Xup�J�D���S��rf'���[�o,;�;F@�<���ݢۉ�8���'9H�FV�Y��ݰ����",������0��$e���v*�������[�\x�nz;dp0SD��� *|;��`�kO��V�@��U�k#� 4H�.�R���Ϫ�@�k4_���LˢN1@S�K[cS��.�N�5�G^���n�߉i(y������� ���&P��`�cK����E������ }4�,�5`,���g<��'�iN�76�üh�������߸��Z���� eyT�:͕$��vr��9Ɵ��^�J����ܢ�h>c��9GABW*]!,��:<���w������B�2BLGfGc�u�����m�gV�Ǣ8d��[�>�;�F=�����A���S,LK	�Q��U��p����� <�8g�z_y��Q����;�M�~�z;Y�o����P�D�#U~2��7��ͷ{{_5)��U�
��\p�L�(D�9c� ������ 5�|�}��Ǵ�%~n'�A,��AeM��i��JMN����{��ˍγ����P�s��P�t�&P��Kb�#��h � ��GRrBZI["ёHh��X�o��� ���KHU��z)�ae?%�%�H^4$ְ�j/�'��E�r�l+��$ �F�N����4�%���qbM2%����[���鮣��ڲ ������=�~�;P(�S�_eM��椘��0�b���'v:��*2IgI� ����E���m���Q���a���U�,F +��^�h��Q�c�W���#��s�j�4ޒ�=���t�\�W�\u�{��}f������jy�3"�B��� �)*���9s�SS�y��=3Z��I���A���D�^b-�֜�0�aH�.~Wɒ��� 1��������l��s�9Ǳ�]ԉ1�$�E�Y�1�j�K����g�(x0�ƍ�;3��ip�f.��p#���������팴��¥�,��,Uk.�d�<�`IɔY���[���-����E�f�V�s'<#�tL����k�Q~�`i�g� E�k`yL��~`fV-9��O'��Ն�7M�	s[�.��ǫ�d3ͬ�MN�ƞ�R�9�|^T�]�GFu�"\x�I4A5}V��SqB�'�~y�& �ĕH��,�:Ϋ�p��%@Ho+wl0D�}��H�[��M:Y�mҋ�s ����M�TNBӸ�v�����̍S����n��u��y��oe�G8uQ,�_���}��<�nR�!�>��~h����
��?��m�w��MEj��:��w�S��C8�ґ�)ݳ��ċ���"'z����=�
[�m�x�tS�gg�&� �%�T��H�rEP_'8[A#x���+��u`2|�?�.�S�u�����_6���[1���qa׍�&�;��eL�|�<��:|��KiR�@�-�[L�Q]$Y ^hw���kR8.��"�?l�M�G�:���H�-�)�]�K&U�y"�z������k��&��14>^�6J<^��,}o�07ӥ|���FL���d��X� ��h�
���Poj��rq����!�ʹ~�b��s����$�~��J�11��V��%Qy��\g�e`Mp����i�����u�,�j�X�$~:��V�<��c���^��Z�M��X�;�!�&4�	��eDZ8�WU�p�1y��?n�bJ8p�s@E�O��[��]��` Nj+��x:;:G�{k`-L/l�����MW�][$�_�In�o��V�1"��j�ܬ���_/c¶��=�cX -���w�������n�F_=)�y���8yB_�_�`�AG|�f� s��\0��oI��}҆]`�}����$|�zJ�����*��T�����v�W�@��$��s&"07��`��U.]cf+����b���B[� X���4��C_Lo�|R?ݚ�j���W���.�Rv���	�8��x\��(���<��Y1UPF�Vx��m��C�1e�229%[>�8U���Z�)���E���,��'���F2SVU�7ѰlP��
���.�K9л-ѹ|����F���P��]�TLލq.�����;R�ׄ�7�-�v���#��W��Ă�5���j����Bz����L�M��I`��}dؓ�9ѶItQ��Ir9fӴ M��ʟ%C����Gr��&s�U�G��'Tֻ��`<�~AU���*C�8đcQW�E��(�p!i���d��lY�V|J�������чsW_���?�63�c�m&`v�\S���Y�g�mƑ���e�3��@�g
�[�JS�"��a�%��J�>����I牕�#u/6'�ݎ��n��7������A�+��~:�:H�%���
{m��pa{�!�jp�K.�j�>���ǧ\�Byst���� <7�8Ɛ\�\������I�	?�.��\l7�:q@{9ϖ��I����y������t+W�m|Hе\H�����Y<-�$Ɯ,/�Z˻�E@���h����Uk�Z�
�
Y">�g�cF"=ι�N��t̀8`������s �˕����_��:�W�D��`���C�5YZ2���� }W�Cc�_uČ�M�^g'�?;�h#�����"�mJK0Sf��w�u��&5�\5*K ��|HtU(�,�VF^q�={}6��R�TZ�ȝ�W�ҏ����!�3������}�؆����}�l�*���h� �ę��tcs�9�����'����)�2�O�GŞ�9�9�'�S�_t�F�)3�{J		ao8ڣ`�������Ff�Hv��Yv����Ǫ�e2��j�L`�~ߪ���@��r���XDR�!�}��?�"��φT��?�	T�Hdm3I�`���;�>�liƂVaہ;Q��>�Oً�|�������/�����jا%��ֶy��{��G�7�O�?*OK���We�VMJf��� ul���2�/��J�V�".v����a��y���*�W�c���b`Y�.� c����YR���V��0�W�}����)�zl[3�--��(�Ta�Ks��ab�dv弡/���%r���Z�t����ʳu
�<Q����z�>vތ���o�Y��$yv3��
7S)ۖ<g�V_�zY�x8���u��S��1G����Y�ب�����p0���
��s�`�@�P$�H�6�%g��X-S?x}q<�8�z�\z�N�K]+��[Ģ�������w!^�;�>5�zb�e�IBfV�K�r��x�d�̟�dy"�����־�t�]_��h�>s�=���Z`�����񌙕��L���e���2�ᎩoVvv��6:��#��w5�5���ǖ@'�t[k4��Yd)��Py.�6w�Z_����}�@�������Y��y0���`Q�����Юo��4���c�W�\�w>h}��z�!E�þ"��^=O�fD썶����Gﵪ��&g�8a�&�eb�I
[���	�M"�`�}�h��� L�N%:Q�� �W4���QsO����07�~E{���\ٛ����:.�\(���O���������J�d.�S%�n:�%\�S��_t����Y���ǢRŶȄ?����%ڰԕ�3��e �wo��XΌ:���@������-u3�K&u�g�r�������Ɵ񊓌c����>�@��>�DP�9j�S0@[[���������&g�]r��K�+�u%��Ͱh}��ΰ��\.AƮ���:�4H��"䁨D���ߘ�509��:w�X�j�Dg�YlwD�TS��uv��p)�`N�(�I�H'�p���5��)�pm�.��3q��3w>�B�'+F�n杮"�7*d�8����i�6O�9_�%��LY�WN'��@�b�K>Ik}�O���T(N	Y��Ց	A����b��ɨm����ͣ's�̏��5OỲ�{��B�B=�;�B��w�b���
Q2֕M��-I���D����ek��!v&g��0x]Ҥjܙ�Y�
�hf���#-r$�z=g�����;�	6N�526�+�,"���RI�����QE�*��cN]'i��i�9�X��G�T0 ���%'��w��7z-}�N���sjBrQ@��L>'+����l	M����c�ÄE�TB��V�� l*�f�J$<v,���5C��'|����1�WX���q�����k�[@��/�����n�,�x�J��μ

��O���   ��I񒀆 �����f��g�    YZ