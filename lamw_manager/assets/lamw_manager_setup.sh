#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3338669641"
MD5="922ee30c8ab63e7c1ab131dcb18c0697"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26012"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:25:28 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
�7zXZ  �ִF !   �X���e[] �}��1Dd]����P�t�D�#��I�(��ק|oZ�l�m�&�р�� 1L�*/L�������,�(��RCI���D��2�6	C�@��sx����&���k�Ƈ��ݭ{�)Ȳލw[���
�x��Y��:�j�o��>�O�--��>Ӳ����5� �h!T^��h儆R�������[Z�j���Sރ�<�2�����1e#'�%�Vw�A��<CD�}�	�o���r:l
����dp���V^��Ei3%k��o��^��V�h�	~,|;NЫ�Qb-��V��o6�Z�D����Zb���O5�,�8z�y���P6�T�&�&�ˣP�h��D����E�۷��V]u& �"��
W��lY�76��c���{0�q��r+~�E%}ߨ�L!�Cy0�)T��/��^� �<�''��E�C����>��3��ip��"hrxf��ĺS襦���t��|��N]<_� ��vȉ��X���R8gϼ���?�X�&�,$[����b��w�bM�Xt0x$4b�w�uX�~JU�ݚ�J�Hr4H	͂���̜��D��&����(��."K��Ր��;������2�����<<ۼ�z6��s:O��Z��L�>��S*���nZm���>��;�!h��|k{u��$��Qx7�����/Z�^��l���������6�d�D��S6}���,+c��en	<�!d�\����L/
�����C�S���]1f�����(#�����A����I��)'_٭����?����Rʖ"}a�h�%���{���ca8�}�Z���-����G��MB�F���[^5�z�o��-r���m����>Id�Z��)�eE�[e��-E�%��gl�K����;��������t)+"71s�Ǡ-��9���u�Ӽ�Lb�>)3�������r"�:�}9���@b��|o�C���1dۺ�&�ѱ�� �uT?��K6�L��#�B%��e���)����"&;F�C�GG5�E`���
���0��g��r�g���Q�oN+�lk�|�֭�{�D��_z�7����Dű�/��m�yMM%[@,��-o0h'|�5h6�d�˝�u�VV��۾�R��@ �K���<�a昖��jں��u=�����F^����T8	{��c����;��$e�~ėI�ǂ(��v������R�&�5k"���N�-�1�[O v5ٞ�2/X�TC�s�p��l>Ջ���˛��]�Q��~KKܿ8��˿ u�j6k�9�34�{k�"SG4���p���?!��'�68D���z�

[�>�[hq�X�3b��Sd�� )�`�=��lkI��fϨL`۸�|I���B���e����is�z	�$���
ի�zA�&1��V����ű���;Jn�����v���P�]�:�:�Ѯ�����'�*��U�Q��f�UY���p�|D��H��Ǟ|�^��k���^��Z�/l��i�R��І�%`�2ZE�<ZU	�ێ	��:�O�BIC9?��d�d	� OA���a�c���iiB��n����\siz�Iz�]k��cE���v�g�p���P'����NB����*�Z�hm@��b(�C'^���+.��U׫cW����)c&���*	`l�HZ��i�GNqZ1�d�C�����Zc��/yA��X�о1:��q ��(N���f�h ��g�����xj�~��W'nye7[�-+Oe_�CXBi8	>�^Bu%�P$K����F�nr	-ҁ���w',��Į�t5-�m��qL�����1+�i����dq���Aȉ��tH���a$�?���`�����'��p�a�y1�V��ν�b.5�3�M�p�t9�C�F����3���p��*�XY���1�i�qab�]��������.YZy �����TH}p�����[�J&G �5�!��M'QPp��^�p�A�;�N�	���,4�}����h:ڄҸ���"]��qņ��wG��>�Ł��%��6o����t_�8?D���ꗬ4�ʬT��ZQʑH�&�ۭ�Hx�[�t�=��2^�_k���Sz-ęY�C��[~��U��C���3�֫���L�����u�]�/�-�_
�h��Q#�Y���QX�	��eW��h=�����3��^�.t�h�u��@���,�p�\d�d�"��Jc��NR�
]����r)&��!���0a_��8��}*���$c�9�>��^>�0��r�3����L�!�N4@`����^X0v�7
�W��ֻ𾻅��t��,����6��W�y��"�C�Xa�|w��
G�yt��TL�2t���KC��eZd�G��p��Poh����������E����m���(7#�5T]�i��0��l$��|0��1��FO�����x�zU(�y1��3�i����1��!G����E�	��0�$]I_������*�5�Qʺ����?����m��f
�����jNx�J	��>�/\���X���َ���:
$���J����"
�gQ�k������7�1�5�ѭ����@�b�\G����Vmz��^��w�bL����(����튟��~Sz���("�,m&��%�j�I�� �6�+��v�m�`]R6����SBJMj��)���:\@19�a4�jT<������1�G4��<�C6�qdI��P6�ڙb�!����a���=��_m3�q���dP���I�\�t��5�d��Q�SX���s�#����摣�{s���J#���Q���wD�H�k�kG��?�
�qY�x���G�K���Uq�����Ք=�Q>�L�g����ĉ�b��c��R/p�t���w��eSJKƷ��9���ޠh��]�,[Y22�%��S�#����,��:��ɇ�'��P$5���1 ����'��]�r�{p�%l7v�<�";o�*��d���ݲ�LAݑ+�a�3���.���r-�#q]���o�on%�������4��y"�����@S*�����'I<f���.H�2~?ߎ�������FhƟM:�� 5Y�G�~�D%Ua�^��� A�t<|�zj�(��箁�Bi�հ*$�ۺ&��G�ưy�ƞ\�8z.�CS�8KU1t�x�\�#�A� E�����u�|�R�5��,�E�;)�j�h-�φ@
��WVĨ��_>����b�<���"�R|O��%5��2UB�JiO}}īK.�F���m���XML��y<H�j\o`]��bM�`�0[!�	��n�'�h��'�F�%ڎ����hqi�cs����Nq�>v^��i�=�qU���+��W#�3ñ/g�����6��ZB��C�ATjf�'�Lz�H������eǾs����W*0a��i����|�TE/�~W , >�(�."�	�Ծ�'�B�:7Ǘ��ȅ�t�Ddڊ�)�W����f&��vU�%ƽPC���e��js��x����r$j�U����D������~U32g}66�zO��l��Ή9|�E�a	����Ȥ�Xm9�<��_�Cb�W�~�~��L�
3x�%#�����`*E̫��W�_26�**�J�>�*�C�~ȹԢ\
�}�g��hvu�.LX@T�4�F���]2�D�!����5#� 8��!<�Q(B���$C�6��� �A�픤�-�\��\�s@�ʅc�9��������`W�јN7��iq>�)��v(1���i���jbV'He��T���I�S���?t��# ������ u��f6��i}1����]��F����!�f_R��8����}��W��.8�o�42c ?�_��T��*ܳjG����+��ˋ�n��:ny���b@�#�D��{`-W3������<C���鞸Yd���H�(��0�\�kg)��צ��*-�:<�@,�z��y��h�Ą�r=�]K��ޠ����v�R���̗[�W�L^�!!
�䷍�2�#Wf����Mp��*���]s��TJe�R8�>q��j�sk��� ,��Ҟ�"�[���:!��JEi{���������n�i�s�uyɂ}���.�R;o*?-��ʯK�'1ɉB��j-f��xD���E����u����R?X�d����M����M	���� `Y=���1�I�'}�>�ƥ��Cf%_�OӂPG��3+�r�)ݫտ
X:p1J	���#Є�/�h ���(�,� �5�b�0^8���q�������:�%��Y�p�A�8/l��&�wZ��4�W�8E�6�@�]$[��3Q[�y5�m&��r�Tc�§�o�&�m�ӝib���ԕ�gun�mﶊU�,)�bv�gW}�n�9����O�;��m�ʖ����5�Lٯ��RB�f�A�ߜ�t�<��MP��#�����KK
��|J�v��#:\��	F㌲d���%%f��F�>eƣ���R��yU9y;6<'W��Ku�9�`�$��N�ܮ@�!%�~η�Cz�=���UMen����R�7E��<�̰���rX�Z�t���ƞFo���NL9k?A3x�P�(
��:l*�=�۫��<�%K�o��B>+���I��S�~������=x����HO�V�qЕý��N������_l��Rhm�h�S��"1'�֯��#1�)��K2����V>�t��%����k+����qU۪V�E�ͳ�L���ϻ,B���ک�kk�d`�f�b���w8N�Anm["]A=N���d�Oj"�
���\0E��͎j_���$B��9�(�J�j�{۹Fc�ز�Ɓ��?MT#f`/�)�"���zZk߭I�@[�^�F�1=���zb��MrM�'�Y���l�P����h�l~~/���:Q�<�(�Z�ӽ�0^��kqq�$�q�ߘ��e\겤_ƞ�׎m�vt=�d7��M�C��^.�)�-tu0P\��**a5��R��g��!���4�8Z�G�� �|w�I����7�['� o�wI۵>ekw< �%�i��V�c,��^��[<U�*��e;�JS�"L�q �mu']�(�c��lz�����Gʐe�>�l�0��dj�i�-%��}�uQ��G�o6��9����K�u�M�F�==۝��������r��
���@��e���/�o]-��.�#���gR@g�:k6�^*��%�x>�y}@�V�ۯIq�2r���h���ޚ�$�E����~��M�X7%V�Eu�B#�8N*�2���A��k��lܱ�8����̐⵳�JA-������c�"t�N�Wg�:+sYY��įzR���6 $dF���zw3B��_aa~�W� B���BY�m�:5T�-�*���["����#��ݞv�#Z��ŐBtd���l8�2sA����XXό���*�.��u��*�('T�Еx>��^h/!��HI1k�sg�z����H���	�?�!�?�4��3�0�O:Y�|o��F�~��b�{�=w[y�WP��_�g=�|�9H�H�w����3��']܁#��H����s�uC�s2eL�)_C�E�IÔ��T�~}h��!�;�hM/����}������1���s��N�/i�_=f@&&�u������,���.��%�J�JH���E1�%�#���<��z�lC�3���O�}3X�v˯d�m6��<Е��E��Y�J�dA^ǫ�`�kw�N��m�<��&��h��-s̅�e���"/��fD����i�%",6NqE@$3�o��-;�KG������(�9�Ds��M��<s�H�@T��<����w���;���������Q@�����%H�o?�"�f���t�'�C3h$	��m*7(��u�f��t�K9�^;���Mq�w�Ѵ�K�:��C�\��+��R-ˊ� ܙt�?GC�A;��	�k��D'i�d	��)�4Rv*�X��)��)�E���#䨮t�&���e�F��%��j3����=ĭ���� �����Eb��DD�s*�K�)���g��j�������k�w��*��ZM��2ʀ�!���������@���i@A)���ۤ��3R�eLݹ�~�������kb���M�8&��E c�)�>\��Ki��c���K��F0:�r?��Q��D�]�"�}cЎ���Lxsq��ToXCN�m� wd#�Y����)T8�ղ�D��Y[��:.�s�ѽ�c��(b����b���l�h��U���ٵ�,�l���ȪQ�|8���#��Bh�|�����=�l��:��U�׼�	p����E4a� Ii<��H�t�;~~@'8d�;7�T?�x6�4�L��2Q
������5�9ꑝ�guH�b8�{�.����-���X�����);%�k��$�:�e���"���pz$U�#����=k�V#��t����t��D{���� -TZ;�D�\�}�j_;������&yn.�6;��g�ު��zJ	���Ν3 ���;�[Z�'��o�������Q~��.�h���$�#s�mY�Q�A�����xQ�(fFMo�G��)4)��\Q� �������Ϯ�mUK:�CHLX�3�;�_I:4arR�����sʩ|oo50|�G叩=�����>�ѝ�y�Pm)�"�����7�u�-���&L�pQ�O��w�O�;T�߹\㝅l�-��a2�u���]�YG�|1���f�5E�<T����L ��pU�)��ɿ �c9>�gO���H#E6���=]�l��~\'緓&�Y��������[8�I�Hk,N &'��م%��2yp(�t��^�U�i�1u�c���:��5�����,�E����㿑3�p�_[�r�()��JD�p'AX&0�y�]u�a�G[���`]2x�P����q�/� ?�<�'�%1�R�\�n�Դ8����r/� $�]�|5�gˮ��]���%���h`Oc1(\�c�n^O!z�|<Q D�ϣ���bmf{"V��ó� �,~BȬ"��8��:��9mQ�|�X��"�ڛ�m �y�*�1f�M]�z�l��a�����Ѧ�+DA�&R�g�������]�/��s�7j�Fì�:���܉��h�r2�[-�	���N64~�z)��x�ctH�����ӤA�h��rNL��^o3�H��\�o���\�o�7V`�s�����U�y14������|�BcM��HEƶ<�H�3�U�¯���t?KT"K��f�J��䕿�h��i�7n���mA����G�n��fɻ�l�6ؾ����Yc�߄�b�L��;�"W�[�e1:�#wq�d��q����r�n��G���Z���kS��6픝2�����G�Z�k����uV��n@U2	R ۾�I]4O�L����'_�׉v=�O��4�.n���t��{|f3t+��U�a���U�>�29�w[~�8��_M��ёl�%c��aVy0I��LL������$L�΅v-g(�R�l��Au����*�����'������4Qs�Y���Tl��LJ�񌽉V�OX�1V֊����xe�6�f���wT���=q�^�v]񴙆d�g�i9�svz�	�����\�o��]3�!�|�B�L�y~j�4�B����׽���b�E���||���_�>]�g����|Ep4Pa\�E�o�o�$71�o��#f)؟������E�m�ܽgVp�����aũ6�r3 �w`0��ke���PY_N��bb��EiI���u6����\"�!A���ߚ���gqMt~�� �Y��Y���e� #/��:��Cߵ�Q��{^��_�54^���'�*��`}P��)?hl�.7[�՜TJ}c�=�HQ�8^��G�d���U��$�]Y���5$��Ծ8�!�Z��X���oy~�G0��4ܩ�r�0<���aY.G;(����C$�*=�HO�3b	���[���'jL"�%ą�(�IL�!�k�Uet�����W� ^y��S��+W�2�BN��ź·��S���;��l[��jf����2�d1�+����=���#ci�%�,���!Vu���׊������Z��>�����E!*�������&�l�1�!��1|�e��Ώ!N��������+��m�tÐ��M}�;�'�čk��a�m.M�o��|��G�1�3ٝсWx9T"�(���$pX�rRfD[s������R<S5�]}B���{| e�E]���Tj	���;���;���J������"��k�I���6�J����P=:T_H�\�)K�� m@�,o�E��0r�ŜD���<
��AL�Cm�[�V����b���I�j��������&ߢK
k/1�y��ds��tf`�joy�9Q���&��]�u�+�piQs@(F7j,d���q��D�Cxԓ�i7x[D�5�D��s<��n�����nI�н\^�~�"8���!��>�|�[ӆ��ЉY��.!�j��w��=��2LU�r��)�v6�ZS���B�]Ew���=+��Ǚ�d���O��Pb����zApK�=�x?����SN'�ܙ�d^+n�8�+��=�>��$;���8��Fg
�PT��$�m�">��G��I�3�j��>K�u���x9|�X�f.�T�h�-��<�J&\z_����6��ݖ���
�1���eN����P6��"��4K����j:���!u���Q�Y�4S�&q��s)>ӫi�����m��lN2o�<�!ΖتQ
�Fߛ��sn���b!�#���w�g�+_P�I�V�C���s�3�q7�&�ߤY�z\Di�"{�FE7�y�<�[~�o�qˁ���E9�����~�YW��t b;�8�'�s?\9:�fT��j����Ïso��{X3.L�ƺ2喬�z������C	���������g@	`�jOL׃� 7����M����՚X�j%�PQ:�n���cr�/���7���U�Q�/�U����D��'$&х1�bV�q�&m���!�d�?9aF5#��ڜ��dTR:�Qį�b�]�B�D I/��y����A�I$Z�	Jűۆa��=1E*{0B���I���s���f�h�G����⽸������U��J͉����B�\%��z[m|q��� g�nS�.,(����1�`A�Q��cMCX:�1��^Ec�G�#Se�v������|�#-e���\I9M�G�~潼���\ٚݩ�H�vc�(�5�Bi�{PV�m�t�Z��W�?/�����v���#�FH�̯IΪ��l��0��#���N2�aK�g�g�����Tc{-��\��;�����1J�Y�NJ�Z�k�
Ni�S��Cn�|9O����{����Y��!,�����|S]X�-��<��'��Gs%�pk4��o��N��Xe[?�Kת�(��"[�� $��&	&t�Z�����!b�M��-Z�'F^�i�[U� ����H^��Ax���j�T�"Q߷��D���1�n[�o�����|��������aJ���H����^N�_�s��b<�=L��5[-���������f����MB �z������;:"s��z�I*��2�'�ϗ�~�	Ŷ���%<E�f@�[�����7sT����Ua6��r@⍶�F&g�E��6�2�����`���3��}�;�+C�9���|����{O�<��b#Q���P��~�x�-�:�sA�����$�JK%�L9~DpU�23�	
��Ȫ����Y;�6������ؼ�$���7�ƧϱɅ�ޤ�jQ��R�UM��r�jG���T�OT�_+w�y�b`����6:w�C�N�	�s���D$?N^w}�1�m/���0 �!���u��F�.~ �͸�\ӓY�F�v�E:�3C�Ͷ� 7�{Sh��� �~Ӭ~�|��H��QXKU�.�s#�6ّfi?�9��:!�n��U튑�.�G�[o]�» l��!
]��Aְr��T>*����W�3N08���)ʶ����?�`�sKbf[#�-!^����	��:;���H�ԎgYm9��&8�s�&O#�U"����9���%��X�<�/
T���&��a�����?���'C��.9��HY���1�"�k5��,�.���v).iʗ[��C̨��Z�_\^0��Z"��P���P�K��"�tV����0fQ_y�V�v
��	�Yl�$�J�E��C�E���v�d1s��}��z�5�n�@+�F��S\�XT&��y�f`|hs�j��~2������Y�_��
���KU
f^���f������1u�E�����)蟚M!%���e́�%Te��?P���U�{�,������C�q�U�ȯ��>a����!UL{T�r��l�5�󧲺�x�YH2D�D�=��#^ �Am�
l��.!�\�P�JE;Ub/����#İ�]<�k6�/AP� �Zm+�pk�ȢBZ]Sb㔁N��tC
�ߋ;�A��� ���¹�$;qRFP�=���?�V���jrI����ە.B�<5�o0�K��`�f��}�R�{gYݹ�G�pL�2���d�	%��l���% �Zة5)§�pyk�v�}Q3��C�N�zR�Mm� #sQ\o��5=�%,
���ؽ�?e�Ɔ�:�$PbAf�||;��y�������$;.�E��jc���aA���!x֩t�4c<]' �0���i����]}�D��^��Gd%|fNux1���	�3ۍ�e�U\�+q�Y]1&�	Q̭�5���Q�E!�n�Fƨ�dXW|g���ٻ���eB�P���Dk�%(Gο�EK�(ϲ=�B��:��-zl0��j�<����tB��
 ��:e���#�C��4Vg����Y���M��"���7���k�;Ͼ��8�K/��D�z� ��~P��/KWk&��@���T��ؽ�im��b��6�t�o��'c��*�7��I7􇍴dA�  K'H�
��u�+�Q�( �\9�@�_!�8;�X�d�%H���PI�ߍ�ځ�_T}���ݓ��R�~��}���)*M���H��#�5J�q��i1	�;�m�l�s��G:���_a�U9�0���9�hs�7���ڪ>����Iu?��)� |��^�S��|J*����ș��m��Q]�5w$�����RN7Ehs�$g-�(3�!j���*A��By����P�ы���qg�N�|a2ʀV3^�!��<Z��]��{�iŒ�!�P�֛*����D_+W`[���&"e�?�;�HǠ��iħ�����?us}�ه5K��Q<Na�}��o��Na5�g����#���y������Q�a����c�8���/���y�Y�s�*�w�}簉Lo>�7<����{Y� �O=��1���6�}� {\y�=o��v����x�t���IX��8I>�����z��R���^���xg�r�y�7�z|掛��\Q2*�	�<�׵�b6�B������ˑ����� ���n!~.E��p�d�:�>?s8�z�l��]J�J!9���%B��抆��.Q�āTFw8YP�(�	��7�n:�2�v�	��Q��ӳ���n������sD����m��A8oꥄ~�ue�$+t��=��P�}J�"���$��WF��X�V�v�`�z%n���2'z}�<f��4�y�$��
���_��f^)��k���Sޓ�3�t�@���Ȅٽi�tU7T�%��h�G��2-cq�p�$�=:m'a0]In��sn��#j�=��������^�ը�~�!]T��=캙�Y�� W0��b6��
E�-ysr*��%���72]�o�Xwf�n5��B$�e\N-Z��B�ε'��4��Z\s���9;�v�	�q�K�Yb���P�������Ku'�]Au߶̘�)�Z���(���Ec��)̖ذc|R.R��� �U�9��QGpbzr��Jy�.�%uk��&I����af���[H����.W�hw� ���y�'I+'$9�!���lf|Y5l׃�В߈ᯙaR����]��<i��íT�p���ʬ�z������:��Y�:�.58�
D�8��P�>���ҭl"}�2��.xr��i��[�MZg z�6E�W�m�m���L��b����G�s���K [�c4|���"���{&Ð_�0vYΑv�������*U'��;��2 ��Cz&��^%ڦ<y/��\��l����5�6NP�b�O՗D���N��"Q�^L$o�ACYsο�M�����e�fqk�:�?��!;�_�jT����dϥ�A/2��V��a,س܃@	L���\ +o���}yjm''wi�e�ɺ�x<��Q��5ɉ����7��s�ed�NK��2�T�77Sa���0����1���^�s2�:<�_Ma/�1J 󶦋e¸�����։�Kg�#��ܫ	�I���ũ%\A��
�����z2��2G�Em�
���c��H��L��!'w�o�,�,g�]�ކ��`��|���TQ#�t'w���=_�V�1<�Yݟ�jJ� r����6	Cd�����Y�\A����Ő���-r��2�{w����b��q���S� �
2��--]+�p�0�����!����xvu��w��-䔮ݽn�����A���f�&NC��&����P`��ĵ)���}���JР&�q���V�7"yxh,N�lJ^~�r���j�r1<T�fZ1��BΑ&�U�� ��;C]x�W3�]X���TN�Ѻ�;&!4�J@PŪ2~��ϡO����o����N:�`N�r��6T(y9��ת�W�P���X�V[e�XiiW�rBH�-F��7BF�W��i�w?�T㟟�-5l�.E@W�	��{l��Ao�H?�o�5�Uޥ0�����Z�ԥ�2�VjG�K|��I�/�L�u��U�������i2���qw\� I*���4��ϫ�u!����Ĕ4?u��m��j����b�kn�Q��,��l&��-��-�EC��J����ڌ3:�ׂ	�S�K�h^�ϻ�Ez�E[$;��&������2��o�}�h9�x�E)���O���.���P��t�l�	�����r��'�e����P')1�d�3<��1$K�:��6����{-���z5�q����^+v�{���'�P�?�4�(�R�䷖��ᭆ(�r�� �Xw���a@�4���H��{��CT��ޒ��\eNbBy����0���>Ae�����|N�$O���L���KP�t2�=`��F��C,X#@�6ޘ�i�BӠ
i�L<.��3���"'�C2�~nOm<g�ֳ�ᛢ�%
�����a�C��H�&��`����hr�]�5EY�K�����a�@�@��'�:�f��)fK�����3���aOsd��74�u��oƱ����w�5��������O٣f��j�n����e&�Q�0z� �X@����̭���fy�;��hOi����V�����̱4M��7>��*������cߵ�%���	�VB��a�?q��	t���^`v(��6��9(�∕���0���
Lj��-�h;�7Ex���g�^���;@�V���wʦS��o��}������0Î�A�u0����S[zթf3|�J��j��N8_n [�_�2B����,B?�<vLVo�����=�B���K����`\��Q	#�l�n�h����&bI������F|�B�p�N�LŴ��-[���s���N%���ޝ6���8D�(iy�^Zd�����#�tY1"��V��H�N�����dn:���[,��#ֈ_��s��J@��ά@N�Ǘ"��r�E�J��������*���	=�����+T9�2��uq_��nz9�3Vj���o�#Im$�ݴ$�]M�?����7#��c�S !>ݹ<:Zߘ��^��l���i&^)	u��k�N������c�%�&`w�M�Ѹs����3�^i�P1o��^M$�F��K�<q'�-CG�^ܢ�ܒ���"6H=� v�ܶM�I��Z�'M26hK>�h���`
L΁1{��z]���<�h�y�zP0E�N�<����K7���k�S�
�Z��(/qE(�Ʈ�n �\�.Z�5tT>��^QW�<r�d�M�
��*��]M�KׂZ0����]D+
~�$J��)v<l�/5�U^��zs�����O�A���Jy�m���?`��PwS[���F��Œ����2�>�e��U&�K�e� *0�/��� ��Ip~�+�7��dW�����~Q�*�>�wA�.��~�%�LY��>���c����F"ʺYjy�Cߔ~��"O��	�A��+8n�[a08
U
z�1	��䕉]��$��C8�Ӥ۰�`��m!pz��l8n�m�vv�JI�bZbr��]����ͩ�q���s���Rbb�5�$X��"XQ��\�����Y?�b�����/1j7C���Q���7�}ӝ$��V`Y��6��e~Ycߥ�ߚ�������q�+,�:`P][k��U@!��>�D=]�.�_.���*�*�H�c�"M�?��;*d����� �ʱ��0L���?X��=��G9�~r���κԒ-hbawwP^O�@B
��Kr�R۝��?r�Q��v�/\��z�}��C�0�_��g0����+���ɵq��6m��SS�l��#�OU☡7���U&앟��SD���	ܨ��8�UY�G�#�\6�g3�|�� n���L�诉�ӹ�k%��_N~�Ao��nO��=#����������"��䗎ڀ�.�'�s����m���V��:��^�ȍ���.u'H��!���sv�����.�jM�F���84�ղ)�,�Κ���7K/D{�!p���6	���zt;�v��tR�����	�X�#yFyx�����($��³�fy�2��)�g�0����ѭF*�f�pơ3���P���sR���j�:�E��lY�A?�+��D�O�ӆ6O������w�I&g������
ߎ�R��^�Վ��ڥ�e�B��T����lC5�����[�|I}������
�jv}1C@��[����Y�B��Ʋ[�˸��:��pe�L@M�	�u����b�zS�p��Xxj��n�c�L��Dy���kB]��91�BȚ� ��������j��M`G�����n�c �l�K�l�Fy�{-�|��ez�A=���b��y�ޚ�}��1���!Lbjƽ	���.�"+�ux�4�a� Æ ��'K]��<����ߛ,qg .k�=G�wI�,��*�i�|푤Tw&M/����^��#"~�$�)���������>�J�R#Np���l�|�-)�)��/[��C���l�kܻ����H&q��k�M�գU0�=���T \˛[�9�?ܴ/%b#V�\"����V<8�]#z?���4 �__��S1�>�-�3��mK�ݹ����~��A,v��衤���7������!Fk�j#i�MA�F��X�U�|�Z9����i��
+�i2�h�Ű��ˮ��)���Q��Q:f�Ȋ��C1�m��	{�z�����Ox .�-�fX���Py�y���ýL���$��_l��&6Xv�����Mq{h&�yeM�9��M>e�1^�)�^��U��[�c��$,�۳���l���W��#ϊ .c�����)t�)�lR"Rr���8cC+��s������3[�R� e%¤C�L��2�"��Ni\��vP����ڛ�53����x��2Jvk6�B��S�c+eD�8����� U��������TUq���N�HDЂ��aIW	Y;��r�����-Y���η�Ċ�K��nQ=���T�z�.{1H���Ț*L�ޒ	8�^X���&|j�͓RBʄj���q�hͲ>4,-��csGf�D�
8���uR
B|4K���`u��R���=+	n+�B�v<"yj�u�3A�;�V'2'Avr1�)�"�8�G5�$���~�\�S塉�L�!V�uǇ�^1�>�9��R`�����G�	�WT���h�Z��QCԀ� �8ތ~~p
�8aT����w�����[�7��"�$B\��<��zm�q�; ��Ĩ�;����c}E��Q%�H�>���)�V$d����㓭)�����I�H>�@^�9�4�������[��`r6.��,0���*�<C��F�b�D3�d3V/�k���d���V��{eikiVa�'��fl����v�TE�.LmrC����D?��L�9���?�NZ�'cuS. ��P�vd��N9�CMb��; ��+�.��{�ap����=ǰ]2��.��%$������T�U��z�')8w#*$&̰9��oO'7K�?�7+k@az��6Ʀ���̘�-m��c=�*�u7M�E����\�O;�K'䊾$����Bw�%��㋴��@V��j�p.(]WP���� � A��I��%u~�d�"���v�!��&�^ث����S%��b�C�R��䅑��bV�^�
{�fkl��!d�t8�(g��'e,'�ٰ�P���-Q^�ج�
�婅�Y(�����04�=��p��T����)wA~Ȕ�Qi$�� ��q@$��\fO��0��O��OV~�d���q.����=�Tj�46@Ȳ�L���_ѝ������{ͽ��7U�_=�����f�e�RɟV����Bj2dP".�n/ta�dZJ-��5?av�l�!~hf�U=��{*���㥍�2�Q�7/b��BjE��㏶�5�є� .�6N�،��<�'%�>��[[�����Z�� �}'XM�+$�B�)9
njɵz|���'A�%�.Cs�Uðe*��w�e����,�U�}7 �KJ���?6�#e��ηP#���}�3|�Oj\wt�-�1'�^Gi%	��"���V�[�]�S�3�B<��^��N'�1���ז�a�M �v� O;�	f��_�'�0U.�H�Z�Բ�DT����ݎ���]���-���=�JB��g��0��۪��R�R��a�£"/�5���2N���LV�b�%~;g��H�e�g�I�lD���r�nmC�L p�N�χ�l@����d��v"h^Ւ������^X����召���E�fĤ.��2�� �!x������rрj	�tz��+_��p�nx?,�Y4�����Æ"a#@���ܝٗ�Q� ]5*�oR�*L"�m���.���#�:��k�-g x۪�8j�CN俚� /g�cK�t�r7���sP�<xzar�	�+�{���C9���H���g`sxh��8��-u�T��_-��gx���Cn �Q�=�pƨu�F��EEPjk�G�Ӟ���+�_�t�vx�e� j���&��R�`�lO]7����9�	2���i�慙[��X2�B�{�1��N�b܈�JuC1�;>������T�W)} [&q�V"|���,�����u�ݩ[���$\�K��y��;t��yx6��(�%H P��BQ�D�[䊎Gh�&��ы�[� r�U����J2p�2�8��[du%� _"IQ&�w�|�ԇ�u��}��x�ڭ��a0@�цu1�S�*�vc�}ga�q9�M�x�V@9�\��2ul�!��ūB��ʚ���IJW��*���cy���{W���CZMU��)���ؑ�sU"�ec���ܷa.Č~Nޢ�42���C�.��fob��1}���{��cė���ML?hHm�F�+�cZS�Xp:y5��h2��E�%#�郤�Jk��v�⯏	?~}|ˆ��ɘ<c��+G�6���s����{�{�#D�|�\�șx���B�v~���*/���|�Tݾ�*����цa�~��#�{��_|Ec��pf7RS��H4ќö5��םLq�_j�,f��	Y�e�mqK�W;Bɻ����?�4��O}�ł�'enG<У���Eb�!��-و_��n�׸�r{M!CF�Ϡ�jyr���ދ�.Rv��1�Mg�]cV�D��7�w����A�:Bb�)��(�־*n/�����<߀V�� v$�"=��.Q�m|��IkS~���3n��⦥�(�J�}�fƧ*#��G�cZ�����(�?zeA���+m6ۄ#�nʾ�����G7����a��|џ� Ղn��R��R^X�������#rd��-]|�Ճ������u?�Bk��a��c[;��4oL����ԑ[�+w���ȴ��������ř�M��s�Yo$��IY̩M��
 {t,Eƫ28k�[��T_z�`��&�e�$6�Y��� '�5�s�C�9����*i=`p�Eb{[��m�,��}��Ɗ<����CSa�Xui�&t����+��tܲ�z@F���J��8�Z�c�E���h��*n�dTr����`r�`����q��S!����GI_݄�ɃF�c>�v�I`+B���?&��4-\~���G]����AJ�Q�r/f��ݷ����*_v����c�L-�C�#w�J��>���ɜ�O%_0�����yz	bA>7�m��C�Wf�ӆd(���0/8���;!U�<���
<s��1�l0B���yG.-�°��߻ju��Y�Γ>�=��Z���z���������)���7�<�f	�ﺯ�=0�d&(Ia+^�jt/|.n{�(;A-�o���ݨS����l��/Vë׌0I� �Sz#RKd�w8���F�K�x��T�1��5��^�p���1�֏]�/�fY8Ջ��HVP	QW��ɬgk�^]�	�C�o��%$�+������g&�a7qL!Y�M6h�q.L���3���S_/� �H!�0t�<0B�g�O�#�xw�K}��u��}�8>{:�LVe�+��i�Pᦦ����n1�� k����}�e���q�(K�B%j��q��t��,�
��_侞����4�<�9�*T*�"��4av���r_cL��� ���U>� �;>�|�������������j����~!|ho-%�w�K=n�!�
�����Sg�o�ٕ1�����K;X҂Y�1���&v
%{Ȣ�LCH9�G!��h��H'lM�=�0�}nM���� r�����MS�{"NS�;�(�\��i�޴Tk���ຠ��,�׹g�u�^���U�����y^��f�NIT�����oh��|CoO�~�P�����82D�"+v^�R�J�)�RC�*;�>)P�nm[�1|Uq)[��� ���/�o*l9����qN.���{����|Ne9�4��8�����4��w̖D�� {p�|���(Eh���`�I��)ף\k���l2�t��s���Ū���.��D०��X�����^,�f/$c�	��t������g���ɴ��S0�Sv2�^���C�mF�g��w��K<����ӎ?�g�,��l�E^2̆���@2�)�ZrI�"d�������> 3�=�����)_���	��YĔ[e�9ek2a���~�HG�ט��hF���1�fq��{�'����:l<-�=}������UE�r����s�ǘ�(��8��<0���Y��Q��Y��Q��X�w���/�#�'�aZ�ăGf�]˞Gzq �<�p�g �U&��`�t6�g���e2O�� �U�*��Lyn�tB�'��@��_��9ou�"Ǳ�(�/���FU,���\��b�%=�\Q���8�}�D�q[C%1T#9�^��-���\ow�HA� ��_��%���}��F���!!f�+
P��/�γ���
'h��q��2Q���Chy��]4�$Cq�
��^�Fu�Lydj	)C���i��iהf�<4_�ޥ���C3%a��N}x��\:O(�!��s3��]�A4H9J�%�{������*��;zr��2��X����s,��=����cQG0�Se��1�P���cL��_������1�Bi��P1y���8�Z��uQ��(�O�\��+yۥ:�����I��y��	��0��H'3��	�u�E�6c5�L�'N%Z+�!jp(���������dD�7������pO=E[�dc��oWF�gν�WV+/�/{��Q\e�J�S0k�\�ԙ?v'0�Xr/J.z�Z�+�#2���)�ox�釁�Y�q��B�c�'�NF�i�_���v�s�
v|Z&\=
�?M+�}�&��k$}D�]�ܟ6��*�)��-��d�t�5kw�b��)�E+�m��bKFV��Q����r���\�,)�tzgl�;@��q�9��≦*Q�m�E#�ѫ)Zm�|���ǲւL�	$����~�$qe�+h�,��b3<��?���09)a��ɯ#�;�8��ܼ�
ശG�l6�w?74Ek��\u|"�3qk L_TGz�&��q��spCc}�Ӭ�b�;r��t�l�<Z��3��II�|�#5/CK��}S(�*��������������r��@E^�^M�b��T��JjXk�Y��K��^	ΕԖEjևE/Y//�Y��Ed��2��7*C:�UD4?s�������LY�6�c>ٮy�h��L\�L�F¿Uo�R�{Gs��T���2ٙғ��R>+yV�Et+���/R��j�hL�w"7�TsB`�!����m~e��׿9�����IЉ�k�@���,�? �f��T{�S���m�j'�juo��4VV�?�~+���*}D��-V(���,� 5^�]���N]����*�����:���L�>�|� !��y$Gz�C?���Ƚ���Z_��k~�"����Q���r�gM�Ô�����������;� �u�R֐Th&�`������qEW�;�j5�o[��&��&rx���C�=~�?"7'R����O1�dk�VXͿ@�����s �&(���Vz�H_����9�r��1�{��I6s;<��1&]�G��"
��pad�TA>��_lG�mْ�
P��R̖V�|d��FdH�q����	v�P�Zz>���]�)ڬ�9su���)�U�C���y�R����T�S,y�34J��
n�-5|w[8�4I�KÃ 	ȭ��� �]m�Oȴ����얙�eFT�k���ݨpͅB�X(<*�� 
���0�@����e��r��(��K3����a?T�@q�)�:��%�C^��o�djy`����r���qw;��^����P��,D��UQ�z8�4�0&DAj�5��?Q].��m��9[Q�WsÜA"��}����M)K�u6�	4�����o( �&��2=�
(�K�@���o�������3D$�/��}�pf�$W�<5�d�ŢSW�6��Oƹ-1�h��ˈ]�|[܀)�ڙ)cUf٬X�Th��� h��}Ԧ:i�FU�/�f��,�A\�^�_bȇ�.��_g�ua���qqӨ��~{��d�H��f�O��L��X�U�����r�j��b��Ax���Ⱦ�Nxgl�8׵����8�2�RG��>�����hX���C�X_+09�Jd�%�Q�"�=U�^�:I�R��$Lm��͕��-����j�J�������@� �y�_�vаd���?���=W� 1����h�%#<$���fAH�l�V ��N�
(c����-���2�W*Ik�4�t����k��V'�$�빦-��f�<hNcijي$��m]�_��H�
����
���@p]�k������]�J; ��Oـ�p�	�}V�B#W�4%�t�����_1m�� �41�$a�F��98�ϗ4]F|�ǈ"F:�rZ`�U���ƀp�f�b�
х��PuU�D/3�L��n��T����u?v��r/��+�mz�-��j� ��1��A�0��:��N�W�:��Ѫ|��Px��0U�It"�٬��������5������K�J(�{�Eu��������Ź�I�[Ӡ���1Y��������5��V�1*��n#�ڇl��;�u�z4?���G=h�]#$1AKI͉��U'!ă�k�k�ka��	�Jw���3��������҇�iRP6�>݄ �\x�.�3����mPT����������8��=�<�ԏ���X�q,Y:^�'�ʙ������S<8r�2eupg���*H�Y2�~�^�c[�1SEg�7?~�<�8У�'P� �f1&;m;ߏzN-��"�m��y;��7K���1~�GP�nu�-���&H�SLʹ�NfDBt�\���z[���{M���N�@��(r'��~*�0��iu٩��d��E��D-�����y�>�x�m�>�Ug������xd�z���*J��6֕F�h�����t���ol�(I"	�:����/�t��fl�H/��������߽��{��$�CÓy ���3�:��`�:��i7����-Kk���١�'1�1%�����7������E"�4y�X�ƞ���9��M��`l����~��_D�/l�7n�DW'w�dzb��q�q����s�(�q��JSO��/i�ʒ�6���^����F (��Z&]E�^��B�S���e�]W�wUԠo�8����� W�bX{W����^�/����i[��Ku�=�?]���C�[B9��͒m~^ۥ���]�.�
��^����v��L怀$�S��`l=HyD��
NJ�fD�����\�O$��K�m����k��B&\ADO�[3z���G����O?Ӎm����ޮ��!�2�������9,@%JځȨ�b������"�4�2y|\�!���ȣ�ŗ�]����J90tд�=���m鄩�?����uQ*��&��IӴxk����[&bh�\��5[k����=��2Y"���5Ra��_�w��	�X<u���6ua���E$�O=��Ũ��LzW�4~��.�|��h�����y����J���;�����tԃBꩳ��}[S�P���֬���;����%jy��ԯ����X�n^���-#-_�C~�}j/���P���^&�c��G��{����ㆡUs�y�%N�s��0J��3P_L_�ϝ����񩁟,�S�
�{N� 2ĵ���u	��Q�IIs0�C�z���y RS�:,�o���ÿP����3L<�nay�vV�-�t�~�Nh~�K�o��֊"l�(��& +wq��r���{lW0��cR$۶�:��{�)'D���U�WW¼h|���������A��<a}Gt�Q��Ŵ���n?�+�-��:��[���I���9��@�Z�����-�ɸ�}\�8s�!��rs+��jJbpl@sO�"�H��0o�Ǟ�UV1=�\9�~�P�W�5r�R��K��ğ��~ryW�I�D��;�c��4�⏊�s���R����ؙ�aU��JvNG�Y�J���P��V
�v�o��}_��������G�S�N��d��_�(g��XNst��80�@)
��P�n�Zt=�/�9MAU�u�J��<�)�L�eD+W=�6C(.ׁb"�&��O���"B�􅂸������p�n�b�J�.f�0��T)K��Z��2V~vmI2�^h��dq�_c�Si���c(b4���T�P1]�!gĲ��RZ8Ψݻ���x���5fq�l���⥕�>���S:����A &�m�埆����y{��������[�˵���	�b�5��� �LJ+/5ov\
Ă9��G���"Y��j��JR����D��`3�^N3��(�P�t��2Mࣹ3ȕp Ҿ�t��?ǜ6_�P��'��#��=���J���I��`d}�I���!&,�+�������Ǣi�κ�]f�����O"ڌP�7q�VfQ"6T�'Q	)u���sr�V���Er��nJw�K��/��ɂ��;}	8D��ɾ�a�b	���b/�C�x �L�9�E���nӏ���%w.��|�U���
' �Z��8�+o�kCB��W9�7���Hc�����/4���.{Ĕ:Z�Mʕ'/%����lQO�Gv�Ҳ���qH�i��h�FM������5ٝ���qR���.x�Á&I>�y�C�3�*%c�j��Y#������>\TЃ�i�u��˛����v�C�(x�jX��!Ѕ�$����d�"���f\�1�S�գі�9��hۂ��(����u�+��"��z.T��
6N�P@xN���m~:�WC�X-���Y��gFE����>ȒQ[��ܗ)/�������*�ܚ���>*���U����7� %;�t�̈́*�l2�>���:%20�U7��
�.l7гT'�Oh��L4_���#��k��� �l|#��F��Wa��:�$�)��8d�6-m~<� ���*N��NnQ�b�m��熕�ќ-_���R�U�H8?��JMnM���������n~x�E��T�+ۈјwkp��=?�L�i�~����n�a��P��_	�
7x�vi~W{G>-O��[��<m�Y3�N�,rE�%j}s����f��1���y��\�ֵ�쪗y��d�|�#�6J�����Z�Ճ���`���5��Qڗ:��6����R��5"h�0�{.��#b��[���N���W�)\i���@V�冓�Է��>%@���rt����0#���4�+��e������= <zf���5���&|�
����~�B�t;�k�\&Ď�Bt�\�mf�LN����1�5�wQ��#��\�VB�
}�u�v$��Ր��X�z��p|� �����a	���Vi�YH���+Yy�����4s�k��9��W���@���З����#���hZ�JHL�(���^��D�3�G���Dbj��������|V6&�	�՟7�F��,�p�^.�c5·�*VK�v�D�(��N�t��������h���3�a`ʐu�5�l�k҂/�M����n�k��{�c3��#�����շ���'���|0R���!%�,ƭ狗QI��e(�/������pW�P8�:���3�5s�q�x�xF�l��{v�} �g�����&jk���h9��,D�ӝ&���N���������!�j�a	:&�SP�p5�P���;`N!�~���$	��q�l*���u�f�����>�y�n-�7���X��n��i��0iAy.c
=�NR_���Кodh����>�+�;��{���#ǋ�$��@����9��F���y�
������FPh��3��x�����U�����*O��I����Zo�~`�9(��=�*�G7U��e1�0�<��$�#��@����_A��hs_��N�����'GY����}\��B��Z��C�x�'h��U0m_�w =���A���n�=8�4��n_*����KA���(*i��t��{���P����ޮ��l�e�]$���2�x��R�|'Z�)���#ܶ��zJ��8*� rL   yʦ�q�3 �����stN��g�    YZ