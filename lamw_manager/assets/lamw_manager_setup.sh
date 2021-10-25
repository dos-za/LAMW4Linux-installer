#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="855023632"
MD5="4f5bbd5ae96e24210bbccb56c947b51c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24104"
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
	echo Date of packaging: Mon Oct 25 20:39:15 -03 2021
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
�7zXZ  �ִF !   �X����]�] �}��1Dd]����P�t�D��R֔�g����������J�eK�
�>�<���8R�I��(�W/$�[j!����n������� �gu��u����?��^V%{D�j��Ɵ\Rݐ4�Q��GΟ���U�a�#(&&\��i�vJ,I�w
��%� �zfHJ�!�0e84Sŉ����T\X続�_a<h�`��*�-���-A�4�sq��:ܓ���6��f��W�ZH�n�zϖ?� ��#�~S/���;��/G�8���S��?��vt*;'��_�8�ȓ) ��� �Yl���8@9�iV�'am���x7�cL�i������m���\�>2�.��I�h�"2H��*0�($�y�م�i�h	�v蛎���p�(l$3�LǠ�Y�mz�!���	�X�~���"(�O�=)�7~d�8��hd872�! p49��z	_�B�r��|��2��CF�"��e��9$��\i\��Iʈ������D�#�����gN�l������D;�k.�r�RG��s��t���]�?'��Uϟ�B�_��C+����T�_�׌�<>����a?�sӻ�0SO��Є��G�:r8�n�0HY^~K�Z����`M<�d�̧�Dê!����͛@w��6��[�h�nbYȵ�\S���M�k�?�(�U�OJ�J)8�#D�خ2� �ywbB?C[m�W����RƮX@�Ϭ,�k�-+�:��Z�%���|��YF��P��X�(9��p����(�+'�
w���YX�ؘ����w�
p0��x��K�_��x�r��W��YEJײ�w����߰!l��ز��i���h�B��˓u2D�~���%�d.(��9 �<a��>er�T+�7FX�*�{+�>0�7���h-�T���\^����)�-���Y�`W=���!�Ixx�IG%7D�@w#6K	��وգ<W�Ғ�q��������iD��C��w��F�-� ���?&�ĕ����g@
<G��;���~G=�=��^�������{�Oi9Yl��A'�M�T��ǚ&�
XD*�b�/c��H��Q>{��s�ad��}(cq}���n7��!F�-�4��L��b�0�!�㰊�B�p*7���&<ŗ��ptѓ���+nTC�s��6�Bsz>�ic�z���>k�=�Z��t���=)���U��L��psH(#΋&�d��@eA�vǑ	��!���,���5ɣ)��*��C��qݝ����AR,�
��f���
��
��$����Y*>!���F%LM5�N���32JN��:�h���hHbfO�I�_j���v�1����S�͛N-K��
`W@�>w�'S�-�0��'��5��?���he;%]ǃz(�2�W�K�kHO��!�KDv��d����Z��MW�`�ڥM��5��M���bDt�W�F��C;�lE�|�&Zm^�#Wd]ڱ6#�}�(:J�+� Zٚ�xo�B�3�X��U!��r��\�s~+u{>�oA��C�CLY����;�6�8�@�)�}3��f.�U�w��2/
vZ���B�ߏX�G_�A"7���lڀ(,�;��[�j ��WF�����O1�IP#��c�����1ڵD�O$}| ��騣\r�9���Et�+���%�2�~��k���oM��"�Z8��qR������v�a��� ���(T.��I�X> �P3�� �wU���1�2?qu<U?2{�/�E�)���|�4���A5	.f?@DDj�b�լO�ؿ����v������Fu/^�!�[���_r:̵}n]�k2hKۄ����g����Ϡ	�V$)�vGt�����}3��"��S���D��r���!?))͹�j=u���f�s����L�t�A��ebu��&mĽy�>�2��5�C���k:�e��
��NgUr\���#��ġW'�UƁ��ޟ��v@ƍ\���|\���F�Ú��VA�V?�Ω�����}��_j�vyR�8^À�9�I���C[�|~s\����=B$�15u�T����r���nE�=��RF��������؈��������$~+}.ϊ/ο\|NVk$�ϲ�0U8/
���3��{���#B\�d��V��M·��nO�6gm�S�,][�����HąG�7��(��~M��I�����5
W��[E6czϦ�E��r��V&�o$�� �����t0�T���<`ޡh��_�w����Ƽ��P:Qp%�%���W&�>2'����t���w�p�9���0[�4�Np]�ǵ ���)��vkxuS����-��_K��(ͳ�g�$CH>�gЊ����o���Z�@@�� �]M�d�F7E�mUX�^؈�	���>�%�M'\:����HK�Ħ�i-��4�����Bu��s����h�n���Y� (+a�L���F����Xc��
�m��q�cH|M�4_0't1�eS�l�TD�;���d*`-�#�4���5��߬��bl�Q�Ҫ�2k�f�����ь��X���Q7�5r/���M8D�gz�w��W��ox���t(,�8L�T�}h�������N`�� ��QUi|�1L<�.�MqJF'H���#��XMnzS�#�M�?��:�Ґ0lcW՟��ZH[�Ls+�s�-5N�{Sr��t���~V[�@�/4�ҏf�2��<p��@�����!�\L%#"�Jp�\-v�t>�CTi2Iqb��Z�"W1�����~�ʥ<lRz�=#Χ0� �X0� ��^�Zi�m]*K����!��`�S�p�U�Hyh��*�:{A�)��;h�Y����-�S���ci_�xh6z�_��3��M��Gt��+�ߵm����ykЌ��)�MB�A�4!��jIW>�G��	`(��9��ԧ����w��r� �+�4P��Z;��3LYN�b�H�]��s�F&��/;6H���^�~�W��kVt��a� r�s��j����Q�\���5q���a�i�7��q`��]gw� ��f�ɩ����ԛ�K89����E�u`���k�n�{1@���0��cg��Z�y����2[PQ��t�yJe���r[�+k��9Ю>] ��R罭D��td%���u�FA�[�?7����#*�|��������¯��p^�jr���ރ�T���������J&?&$ ¾��y�"��[py�lKF��>��"J^	�UƁ�ї�{�{�(ǀ��?�l������-��V�7���N���p�H�4� ˂5m�c�L��I�>0�Jt4����E!{�آt��&(�S���ù���l���	���}A��8�H��c��2���h���<+��.'���Xk$�'I��ٞ0�γ`�p-�T�
@.p�\��v����9�e�3p����2<�)s����6��O4��w"�A{��|hF����%�Yی����a
�3���z���Rk�]̡}�{�� Z����  xSl��G
#x�����<pGd�J�L�1Ed�2?���p�ړj�\l��?s�8��;�{N9��of���{#�u �"�i7A�������k3丯:����bU��UEmX�l��U<�+*><͞MH��ۄ�"}���{'�tG��Tݡn��u����γ�]|��߅������'?�@��á7�g�&oE"��+	�<��:���.��Щ�#d27���E����aGZ��P-^���GK���	;�#������m�d��$U�d�����FQ���{��E:{{�8\P� �	�����8�{	V=~�]*)�v��ۓ���+<��OgH��]��o{C{�
��w�׈�H�2���[�e����1508Bb��r��)8�%�-v; $��n
���BQs���(�����F�Q��*�  М��&1�q�C��Vjt1&$�2nf�R����F�҄����&�"m��w�����G2�B��9(HC����,�����8	�g��pN�-�/���D��K�z5���X�X�(�4�:��XJ��P��|��X�=ST�f{�28�'���d�������(Ѕ���XJMl�J� ¼�����H�~X���Л^���Th�RCl}v�4N�|�{@~Eؙ"�͍Y��j8B���l��j�}>��M��R�Nn&6<�h��{�{��M8��	�	�>r!�S�����nΰ*��evP�Rw�ר�4U�"�6<Y�nQa;�␓���:�����(:�}���̔=fV�;���OQ�\�sh���]*����{�<T�=r^x�	�|�����A�Ag�s���{j|}k�#.��!f ��슣&�a��c�gF�/U}���� �4%0_J�'���
x[ծ�B�����@Y���>��l��2��ު��Ȭ?F#�赓�/�uUc���F�{^fY�����=EmT[m�3h���N�9�/���,���u;��I��Ql cf���H,�W��� T2�p�3+��>��11�a�-.�r����e����Z�;�v�5p/�ϒ_�{�\�b��@�R2,��E�u�����2��N/ W���z��r �
�����_9=Í�_�8��)�WkX��,n���������4��o� �Ӧ�$�d���Zsq��f�`
�]Ss	��O��b5��qFy;��W��6�b����بc��G��b�����j��G������0������$��ݮ-*w:��B 15�������������^��(�ݰ�>�PM�NdI�JT��w`��3�ܛE��^�9t��Ǩ�Hp	�h-V���'�.�!q�+�D?�Y4(�<ߝ�J��q�%#����T��JI��?G@�0@2�O�u[nv�Y���H���y��.�*�b�J,�<CHaS�T�n��E�9��[F�e�{W5��
d���3�#�
��z�n:�*�츤Rn��z�^r����?�-�4)���D�8��g�pxE�CZ�����^�� �P�3(wQ!����j)WK�h���e]r\����xP�n�a�>��A��j�I)�Az�5aB/��HDh�����УB�Ŵ�h�]hc���J����	�8������o0�Ƽ��[��6
D�^�<�Py��]qs�~�xD��ށ��(ޠtwUW��G�u^�
��/#�R��L�D�_���X��v��\�V�$�PD�oP����-B?�|L�yē��&�v4�ߊ!}�Z܏9h�<M��v�܋��W;�;5�� �Lʇ�M\�C����(J!�*� ]2�M��g����wK,yG}����kU�A��*/�ʊ��E���Ģ*��4�A�)X<|	���k;gl&�c"t�t�A�e��l�%i��Dw�у�%Fe�K.څJ�eX�mO=B�Zqg���D����)#Ӝ���Y��W�2p&���0�1�?<��t`��,�@�u}&lb���������2����Ӌ4Jꭺ3�R:ܟ2c�� ����Pf'�7�1r	
yR���KEÙ�C����F��<�!��7�tI��\��ףx�g�#���	�.�K��f;��^����}e�;�r�OL���ױM!���][n�&v�����F�a�A��k�z�"�&;UVW�PNg呗���3��8�1jh=� �+c�e���B��a���u��h�n����x�~lB�>�C�|�~Z��[�(uc\�9K4�M�>�m����Ԉx��^6��:�X
J�.ڂ���o���(��4�?�IYTD�P��2J����Q�U�" r�� X����yZ�:4]�(��j�:`�53���*8�'�;��3Q&�=>�h�13�t�갢��f�I��l� H��,����t�8\wэih�%� Nҁx�M;�y=�E�9���<;R�J9JBl���I��%�+r�n2�8�>uK�{З�z|���J���������q�g��Ü9�\+���qt���c�m3�8�l&�|5���3~�7��8����_�á��_ �ߗ�ɸ��%�D�V���~�f/���А?��U��eP�������#�ѕi�k[F�Q��y?����Tl�Z��̌n^	�-C���"d�-'C^���ka�{J�l81�<Z�=1L.)AU�;�*^�mYjg� Dr��qO�dI�k&��C�B�6�^���Ez8=홗�o�P��H�qF��s$�I�k��{��H�L^���8�
��KÍ|*~�n�r�̓�5oa˜\��������ֿ쯞z���/�${y.��hE�ڒ�,Ni��&� ���J6��|bu�H�P��O���h���J�� {:��z����ϝ���u��pN�>8FG�m�HO`H"D�aa%?�j4���Ϩ,��|!6Q.]��!$:T����S�y�5=�;��3�	�08Uv��w�	m�R�]��Z��l"�в	����a��q~kT��[�j�����H%&x��Ns��^!�� ��=Z�(i����k�b�}:ڱ��ȶ��̖F����C^gX�W(�A�>�)��(�X��h���*p�Y"�c^���?!���˨I�!��q#Q&vJ��U)�*��U����Ӭ�^�U�S���$$�{j����s�"����#�����,.#�J4���-��'�M�t���t(>��y����Z�òG���tK����"�B�B4��%r�IO8P�M-8���/�(d�R��#���)��`���%x�וά9I���d�B�]M�>9 2�HmY{�|���C3u����&'��U.�%�#��@��J�������f�g�p(~������!8h�'jZ��Ӌ��I���ӛ��a�IPa��T����̭�?o!����Pe��A�=���`G�n���7�8��$��Qӡ��?@>3"Q� i"zT�%�`KOg�}����f߽M[��!�����Y�N�|������y	~,@�����8�
�e$�ɖ2[�\ć8��ɯ���*B�c �J�F�����QQ�����z:״�����*�ju��z�ݲ�܎���_��}BЧ0}Ψ܃*�'��v.Y"����b�z�K�z �;���.��B�Z��P�z�셉K�l6c��Z3U熥����[�Ru~Ͳ.6�k}�4D4�Q��Q1Au�v��.�����m���5����Z�����ۢ�
�EF���/V� U�J����o�4>Q��[����H��떕W�$g��w�Hr��p*� pS
��֬z��7���-p�D�e��SFeY:�0#�_��t-��c,�i6�N�:��Ŵ�:�%�U�`�S�O�~��4��-Q���u�2Ǔ�n�Z��6F�5K��pa��kXT�:�$���J���-؅-9<\앎
�G{�9;�O61�z?{y�ަb���J{3�󒥕|	�x��^��ޠ7D����ty����IK��ֹ9��[����妻�Z��~K�.�!��ޕ��x��U��+��>�
��J�Cd�R��7���X#�Q������xiH$b�����)Aqqǅ�+��v ��w������D�xe�
�呸���xX��ݨ0�@���)ĕ��e/�!Jo���=�u��l�?��6�	#$��At�;Mέ҈aO��U�Gb��w�kS�@�C����$C�K%C�����x#բBjGErljH����r�&Lk��P��Xe�1�y�'�����К"�.��| �e��aC��rق��N#�E�>�Zz6�Q��Pf8gA2D��$��y1D��	;E����q�fm+�zh 6�;��:�1bL*-�����t٤�^/`�\� �y�+���eV�_<'0��yoqƵ�F ��氊��{�@c�;�g�;U�w�w����5=��]<C���w���>�hث�ra�G )���h�%�j̓��;F��/G�u�t<��t��f����t,w4j���Y�֗x�&�aj��&�å�_î)��N��8��#>q�@�_���Q��V� �!��N�c�b���*�h��{>�|��$<�,9���)�̍P�U�vm���֝�V`.G�w��4ߪwV�VX�&�/`E����,�zYy�<�0��������V1��/i\�d��u����SY����������}�~v;���]0��s�h1��?Q�1��}Z�n��I9��JKK#/�?	*��+�V:�m�����e�N!=���J��Rj<6���w���V
z�V�s����i{�PҠ���@�O�[�?÷hv?̯��˵_�%��WVG�ݦ Gi�~��&`�~�0g������[��8k�9��ӗ�6��=���)�+�!����w�I+�2���b�e����j�Q����I���O��aڻQ&<�ňn+��_�WMN�n�hfN��J��#�Z�R��%�׬�^�FF��*0XW{�"m� A���8j}IHs#���}�N�X+	���%���I>�����M�[�v�ύ��2����d�4]����k��;$���kE'_ܪ�EF����v��9CJ����"� �"Z��,>~}��{�G&5I�(m>�S�����j%P��5%&Qo^�};��O�9BD�@+��t�ɱ���C�Me=˯P�<]t,Rl_~Ø=���<+uD��0�`�׫A[і6�"Ǳ��	���+O~�l��p���M,�g�}V�i��&��?]VQ��Fs	CD�9�qI��yj��Tw��(%�B]��+m��{�p�<����nf��Z�8N�'!B`[ު�@/ )�h��@���n��s�A��:t��ʱ���u�`�C�5>�)U���!�gtL��z D�r�~J��j���+J�n|���!u��9�@�������ݢ���,�����Շ�O8�����ԝ���$c.K�Q����r��5|��O`j���(t���cQh�5s�A���T�w�.�W�8���ךl��D�x��'hǢ�#�qp��%Am��%J��E���D�2�m�ec߰_��Q�WΥ�V���ÓB�.�����Oџ	99_���dyw&��gC��e�os��ok������6Ӈ�5WǼQ@�Y%��PoT�.n�h��z�J��8#��y�x��0�\�HˈT�[�`)3R\0�X�A����FVk����T�+�(��f����}x]u��I�`(b��I�|^����:�*ZXG!��(�� z
\��@`�W��ɻ��b2�c�&qՊ��U�73cꀔ
V��m�I�M��Tb����kMr�'?|N����{�Qi�Q� 2�OM��#zF���p�r�bx���o3��+1Dc����,�c���ıa��T#��n)�v��HS�o�������ƍd�};ٛ���"�ZD=塩2���<�+9�^XJ�-^Ξ���.��!�y�`@t������� �CI�)A���x[�3�a`�nВ�1fML@HӉ��C{0j��A�ú� @�h��
�hB4	/e�{���6C㛶D�we	<��k�u��_�=V�;�k&>9�����%���J�;��9���S\ܺ]���Ym)�)'�W�?;���p��;�!������1>/������R���U��|H�hγ�����ݟzA'�mU�&�l���H�%W�@�:����й���P�-��
��=^����Y*+RW�'�����~=�b�X+iM��~Bs̡80ظ��a�C�+��&a���删e�["�P�RV�,�f����j�9k���'wp^�� ��8U�i��4��0��ۣ�*����Vk6\��˴�t�6��g$�6�qShNq��P]���}��zg�7�OW��_Ǚ+W4JV� )6���Bտ���u}͜��xJ�}MY;13٫[e����E�lP��x j�j�<�����@ ����\;�niI�)�@��h1����Dϋo�e��~�4dUD�;�I3
��|�8Rg?z�ɵ�Q��h�մ��5!�,Z�k��(���iCd�!�z�_���اe_E�K��X�a%�|Ҟ(�<��k�"Šʹ����A�pT�� +�b���,�^�A�v����s��/6�����L��@D��{�����p����oj���#�L�$��3���$&K'�G�����ﮆ���&g�b�'
A��`�R�l�B� �mMh�D���Z��u�}7��jLX��Oq��Yo�7qI'{>�^w��z-��N���%$�f���*ޖ���NMVT(�t%.Ք�b0��n�<���E��z-7p5$r�5��k��3��oubZ��Z��X��te�;������.Ц�=��J#B��$n�vI�&�����(T�T����R�/�F-pA����qH'n2
6y��]v�rQ9�"Ɩ�UL��$r/��Xܩ�8����Y!4<cR0�����׏HigX��{��*dJ8١��A�����x���k�Fk�a���XFF�����5�C�&�#v��|�����sl!v�P��E��qS��ַ2��峅@N�+kﻗ�׺H%�p��(���V��;zbi��	K[�KA�ӰD/��Q�cn"Q�jd%�=J퇅6�`�%04�<�꼜�ơ�ﬁ�(\�� M ڞ:�?�;�8�9>何����ˋ�_N'뉄���X��/fY��� F�hW���	�?m��6Dx�o^��!dD��zl%U�X�q.�Ǎ�*���	�q�Φ4��W��q8
/�����'��Ϫ��z�#�#�\ܚ�����Dߣ��h���F��
����!��e���踦 r7��
&�"�o�CS�h�ͦȏ�+Q�W]oQ;�B��~W�o�����(?t��`�W_���	����<׿Q[��YSC��t��D�Ȁ��B��UI,%�����22�۵�NvǾ-Q�.�L�_p�w&=�l���)r�*��@�Z��B2����|�]�h�3ͤ,]�ӻ�h0L1
�Q�!p�n1�v�_gC}�k`��5#O�	��K�8ϿS��ׯ-
�ue�8_��������]����P�� �첹gN�^���?�Yg#� ر����J� ��k������T@T��V����2i���?>	���2�
�s�S�`��IBm����O.Y�~M���rfg{D�`�_b5��	$��b#�AdQwC��w���~B��q\խ����J(2+���b��Ao�gq��
��n�Y���a��Ob��xB5��p�5�(d)��
o`3���U��PF�+���b�z1�m'�g?=��r�qUȔO.�g$>�G�>-)ԯ�P���\n��O|��&ې��:׵�\���_���
|����X��Pn���mQT6(�/F"�� G���evk���VG-%��ׂ��q�_��t;��g���Z�g�`�E�c����G>bȬ�{-2�Ϲ�Yd��snV��!§� � �k��!t��$-�٫`KX��l}X�F�L���\��P���=)S���<*R��V��blu[@&B�5(=�����6�1�ݿ����nb)b�k	M���(��;$�Uk;�����V���1g�R'�򂅊�g,�"�r��ru֡�r��m|i�݇MŰ]���̪۾�sv���d��-ece����?�hj���Pi��yO��b)\�I��\�f;��	+�bi��C�m_,�>��-jA+�����>^�`f�nm�TZي�*K�G��r��P̖\�q9�#B�`Y��fTY$'��"r[���=�*�%�{�'G�l����O��(�͊mO#�{����f��&8���.��?�Zb\�Ni�S/�~6� ��<��L�0s	��:��C��6��\H��`� ~����P~��� �����Ŷ(᪇ls%�f�M|�#M��q!	��:s����L!a[m��[L����]���}��Q�h���2�ܠ��a��j0�2�6��#��M��YXN�$��dw�0��n7ժӜ�=�o��؆�7@l.�C@����iqF�6���Ǽu����~�����R���Vn�9(Пra��=�L��b�rX�x$JN�u'�`�F�e̪_-_&a�CVA՝JI��-�F���7ES�A���$�
g0�n%f�z��6/#���5 �K���*E��h���%Z�y����?�jVd�H|��x3�ѮD"b -����Lж%l��Q7�<u��	y��+]�#� Em�/m���E+�}�@t�KC�^��}EU^s�4�*3�in��=W��vx�����Q!L��]���WB�^SU���궜K
L�7�nEeM�K#�zt=�rhN���ɏ^F΂TZ̵�j�U�Cϐ�@X�n}=\�_�d��{n��[0��_�ȉ��k�q��~_���x�!�e	8��t���=�Ó�����>��� J� t�yA��e�fT�"��� �1�B8 w[X���(&͖IX�0�[ڙl�L���	S^k���� Va��K�X�V��[ض�L5�'���I�w��t�,� �rY��e,�c,��뿎���g:{u���m��;�JP-��ґ��G�@ T1C�������8���~������
/*��UB�{҄�(�3��	�ʣ	��]O�?~����m*�#��۲>��''���e)9
�I��q�$e�/y��.������0�Q�>}���-Y�����\ ���Ԫ�����}�G�x��q��K�F�SQ�-�4k��W�6?Ok��Z$� ��?I]c�af{���;��k�"Fn�B�LhF�냬5kܘX�Ц�]j�t�9j�m談��Cx�V�#�	b�+��!N�\�e�S�Òҏ�����@C9�_�7�A�a��N2�t�.����!���<:M\�O��4�v(�����r�/8�D��x�A}.a�V9K�G#����s�u� �A?D�{�j46�i�a���S��>@C�L,�� ��bޖ�
't�W�W��h�*�4��EN��T*7�Y��P� =��4 ���_^�� ���+�K��#�E�A�n�)��Pd#(�jZ�}8�H�D�f��/PH+Yh8����|��p[�;����w4�h�>�޷&�� �ɾj�if��O�Y��i��Qz��=_�D�̴N�PLg��2��Rگ�x�mE��;U��z���Q�9�߭��������T'�cA>�v����㷿�ƀ�Y
-�ZM�{��H�u}�����h�q���~�۾�'���[X[�u��9�2p�l�p�n��yN�sb�>��3aۈ�J7�2��x�SEH�ǘ?�#��g��Q	���A��F����Z�+X��Xൺ�
��{�'�C��a�4��ԫC��� �2��/����F�����kTZ��&/�`[�C`��Z�����!A�l����}}�ĉϛ�>Y����BF^ys�I {�Ҥ0zUB�z�������u� ��\
���(�͗e[���5��!$�q��H�_��@3������1�6 �L�� ��J$N4��Za2\&��S���6nM�����v��E/��&_W�i��^Fb����S��MM�����A|����l�F/4�Q�͙�:�̿��9��H����Gh�Xt%����HX����%�l��yC�_ւ(AU��E7�(��)rq�/�.J �}��2��V]v$|�w=�.6�h�l�ɶ���Ɇ�G���Vo���.Ğ�u�����l�8\&E�x�[�����ϒ��>x�q�ҊAp ]�wS(3�G�j���(�В��v�n/��~k9�f���Av�5k���T�q�#E� �.ɢ�7�"�6�u��T��zb`e����5-���:\#��gR��,�9��A<�^I-����_�:Jp �W��3B����r��q.z��v]tj �&�_��^��FPr�6��H�r�y�R��Z�����}�c(������j��=����N�5��*dɃ/�����*�j��.?f�U<�wbCƼ�m�ӯM5���'�y�ơ(��n�"�ZÈ�˴*&����(�)��)�ā��U<�ub$k�1�M"v�������@���_��6�B��z���N���O:^�W�n>=��c]�~��d8ls�7O�W��ٍ�G'��6N��a!<�}Z����"YcQ<�H"���?D�uU�H�I��'���[-�1s�4@��X����	u�lfR�+����S���j,[|!�װ�~�q�+$��S�$@ ��n�$o񓱾܇�+����*�U>�\U���a�^*�d���l��6[�*�쀃�G
먻ɢ��wj���U������kv���	;�*���	�j.͉�KS����"��3�HqO��`�����"��N� <�&���\�ñ�j�oS@�Gu+[����ww=��IC+$_�VXc��.f+Ǭ8��k'4�;�j�'���"������s�p�K�+��r�7#��>����"�b�&-�������`��f�Q���B��'�?��)��:-���-U��ڍ���~_��T�+���doC�D�2��+���1>���2��U��]�����!X[�\e ��(
�e�pRY2�I�68�LCdt};�mf%{�7
 ��@11xx�X���1GZD��t�v�"qq�ž]'����_�R�z�q���C(����7Gd�ъƠ��g&��[[������	��*��/g�8�g��%���(wѿ4L|/-��^�i�vf����ٛ�H!��<`�pܣ�I�uƉ5�n�WՍ�EY!Z�FZ��F-
���M?�/!?��*
��e�h<Ϩ��2>;#��9P�� DA��G��n X�@�؂-%����S�N�+k_2#�q��ִ�4�V��i���C�uS輲��>n��g��]��:V�p�����v��?T҉3�]#g��� ں�X��� ���Ң�(�x�����'�����%A\O���n�2�Ui���Q�`g�a�]���;k�p�\Y�	�4�6�Ñte��mj|�x ycY]Z��j��#���t.R��!�5;�m��rb����������g,.�E&�H�2J��l9>c(��C����S}�j�"��v`Q�������FdJg����ւ��=ۓ�Poy�����,AI�a���8�:��)��˦T8e=�W͸��J�=K�r��s?�� e�+�B�
$>d2�~ <��g�Z"gϱ�9�u6����0�^������DDW�=T��v(�j9����m�%1,���Ι%NIDcv���r�����2�c���-B��`�c��~c�}��$,��.���]�s՗��b�`fGdDr������Yy�(��B�aƌמ�ĵ|�(����Tى�&qq:�qam;�vtf V�+��\VW[���$��V�=R���SQ����`A61��s��hvu�x�(��7\^���P�!��,$�{H|���LeG)Sj�!��$��Yv�>����թR���ݡ*�ʗ:�z�]4�SF�/RȇȞ�S�!���|�S9�����E���4fM27�L�/ �(�I���{�U��3��������n�w��.hS/W!����C� �kr>��]2]ܡ���W:H�z�DI�L��+b�ԝ]:9O%Ƒ�v��:"N�I��ۑ��W`D	�H/(��U�6&����P��?��P^�����z��!pvn�7�Қ
���}����ZP��l���|k�_����lؔ�g6���?+<Zkg��gs"�Е����eY�``�v��Kx��W)�H�3	�\0U���"��H������h|ԗʓșp����YAD�����e�Rv�GhY���Yn�sg��b��
ۣ3��^����řo��;%k�X�\Gd���|��}�v:�+�S��^)!u_3'�e1�ϬA������:�2c2���i6�u&����-��/T���Un�!5c[/��H�/�����.44{�mj���f�R޻ƭ񐥒�x_��2�'9���bkr�;��^�f�f
�[lߡ�4�
	�׌�%!X�8[
ي�=���-�����ijG��:�i�=Hy��ݬ���,R�e��R�����0�e/B��\H��~��B+��6�mx��$��ʔSƷcԍ>�#��8k����~Caq�cB
��� ��Y�`|�Ȇ���4i�����j��1�|�2�&L����MN�sHhN��C	[�SG�g~r�6D�%��e�V�����_u%��(�g6~�#"ֆ�Zr ޜ��0���oX� ����WF�yn!�P�U����骮���JOP����%?T�o�Nu��d����S��p&�b]��Vp��0��2c��$Z�z.%O�v���#���g`���HG!��cٌ�o/���N���9��g��t���[��sLvf	���Y�6]��?q���`���VN׮�z��R�t���y�w���b�`S)���kJ6��3�u]+�`wI�f�89���i����J�W5��x�v0wA�&�\Ev��6�W)sX#��cv\�~�v_O��+1(��ʑ�t�x�g��v�J�B��PA*��a���iI��E�5ܘ���x���gs̀e�i�7u�LF���j�؈������% W!Y	�@�,�lB���z��l8���-�H�H�Nŷ%^�hk��E��[6�&���L�}
����,��$��7��L�f���uL�RZ!Y�m���8ű�#�JM�Hڪ�ػ�-{/O��g=��k=N��?R�%&�n{���r�^�;��y}J����C�`y. *�Z��m�̀�3�W-*����6�_��V���D�aM�9��b�TJI�8q�n�\7��9f��m'�V��-�?��&�?���)�~|�8�� R�
��N�c]�E�~��yc�D��#���w�tε��V/��(��H:̯#�41 m���s�Ƥ�kkPJhl�ܾ��3S�6�8?�Y��a�$�a������3^�iy��B�og�Ys{Ҭ�֯�we�f�C)��#����i6���/;�xm�u�S��MI��y�y�B��Tq.�e�T{}��$��<V����!�C7�n\cU��3@4�:)���#/gmy���g}�� mZ���y�E�K�V��Yk��G��]����(��0�j�ɋp��%�7rP>�T=��|*�!1*��fpx�]���X�߁[��� �9����VHBc�DE�|�f��[�	H��Q��f,x�<����b�A�(�.D9�ͺ�JC=~��Pg@��}
�ƈw\�q����VjFd��&����ϣoB=A��Xe�d;�i�T��(�U<!k��/ �,�� �-����S�[`d�Px�b�	�G��/�˷�R<{�i8�Zn1�C'l9
�޸��*}���v�]�??��0����^�g���j�n�9�C.}����`��{�!0�{m���;��?�a����ϛC_a>���r�DnW���%߹����.����P'f
+���T�M�h䆯3�aY�S��㬪\UD�3s�-�J��C4ܤF����V짲س��n=���@� ��������v��՘
ӱ�?1[���'�f��l&&`���2�!,�+�����~D"@�2)nE%��\g;�9.Y~�B-M�b��`�R�h��sǽ�d	�k0����a����qO�No�w<h�R�b�vў���mǂ.G���=�u~���[_��&�-)n���y��-�B+����O1,�����1"��E�ۓ a|����!�,�\٪� ���������vԊ��#Z�-�x'}�.����wi��0)�*R��!��p5�lw������j�5tg��%��!�#b=���x�f��6�$d}lykn:�[��yY48m�l_�P���0L�6U�t�e�%�M�큤��ϣƊ#?a(U@�fA��V떉��� �:���孯�%�xQ��<�ݵ��Q�F����M�Lpe�K����&a���+�9U�Fy��AD��_���9�����)���W#Qq��I��dꨂ�O=�]�}�Ї4'q����+V�ﵜ�,upPk{L"x�Ÿ�U�2A��;U%��>��-ĕ��� t��8�����=�i�'"��Zо☄ళ��9#�_���N�8c���mS�#����Z��yvo�U�R��<���7��R��sF���@*Gh��J���*��=(JF�	U~�A��{���!n�Ix:d�&����eq�Q��*č6�cB��o����nA$�9G��4��	�G��8gHf�|n���!�?�?�+��+,�2K�2�p�|����V'w�>��wpm��~Gp����ߥP�
Z7:e�{��ʷ��g�]G��o��
�8��qA�.�@s���o+����+�=AV�6��Iq����� �֐�8��q��s���:	���*���ڴ2)ǴAV����B�޷���x�r�u?�N7��5rh�� �}A���mK&q'
p�ǹ�����$BN���دa��.�z0�/�2y��,��Fĕ���Q�C����~�T�� �9�V���%{��e��̛��C�)t��p^�M���)�e#	���^;CB;.թw��՘?5�R�u�9���%�S��dW<�F�}e��q�}��a�V��"�"b�=PE�I�Q)[;D��]lU�D�:��k"�'�VΝt$�A�z��Ԗ+QE��2�����)OO��jk~�K4l�q�[H4�m(ZM%'�����I�6r9���0��·ZFO�f�A��f GM���!#QK���xIa���\Wk)�I���n�[�ERxF����� ���L1;�vY��wR��p"S,��K;��K���7��]�|�3�|"KȖ���c�Ez���o�
�,�3h�%�i̟eGy;�z_��]�p�%��d�\4��)����m'���N�X�ģ�²��ג���\VN��_��+��Y�Z��]@����ੵ\��gE���8�:�}nAF�H�{���zT9TP�Z/.��n4�ybzH "ڎ��a`NA�۞���DK"������U�U�p�o��}�3+&�G'j��k�6��:� ���h�i%	6��������6��Jo��
�`����������Wq�+x뵿�s��Lzc�b��Ͼ����2�G	}#I�yF=E�0�@�;+���j*�R��~� )�0C�w�	��
Y��"6\�`��oڍUGܐMNS�IBt�ʳ�I���U;�)�%<�Фa��=���̄2��d�,2�ઞU/���BC�Ƙ{�"r�TnU"��KA��Y��J�c�j`�0�k�=���M?�e%\i�C���ҪŹ���U�V��#ȥՌ��e�@<>N�@�\���s�
�}G�6s�*ԕ��݇wh���>�DM;ӝ��8��O=�5)]�g�����b\uO�y�z��]"��v~�M�	9�7�i ��5�4�U��Ͻq�B8~{�k�����l���,��`�#�sV�d�=]yP/��v5���L��ǳ�=�4,���x��(g	2��R��E{�%�KN7��0dp��C����Us��'e3�|�z|!-^�55R}X!�"#/�;��]�By��1 Ǎ��f��)�Nt&��Ϝ}���HE�ඵ_*��ްx�7ζ��~�b��"^�8=���l����t�F@��H1�B����Ն|�a��߱]�NO���Fb��׶\@�x�lFٱ[���Z�U�MՎ��݆����f*Lk�X��T�����w���;?3���"gk �p��Οz��w(2�l�+���B��a�p(��Ķ�m��W���㛹�	w��ˤ^�s�`IA�T-CQ���Nf�=gHN9��q�X�6��Teg����]|j�N��[���S}
���|�L�.۰@‸�r�f|���d�-ztz����R�{�V�;ΩB��7Ams����j���5�n�:��L�C�ֽ9���,hs�6��ݷ�Ț�Ҭi�����k�!�Vz��i )��� ���ñ�Qm��-�j��/��"Ã��4kd=���������<[g��ќP�{����lF,h��?�D�V>��f�F$ޔ>]J-t�"���W�O[Wrr!z�[�_������%�Z2��
&#?l�ۆ�"�Y5l�$a��(�z/�iw�ٸ�q��(K�`Q^��������(��u~���<9�����2�w��x5ˍ�r��C� ֊�\�l��K5���g�~�O�F9��b�v�ZH�e�Q�r���ExJ����T�Qz�|������[YD�@Oƙh�\E�3��?)��Dq3_�:�<^'c����\���ȀKu���f0��4��p����)��@�8����0;HPu5]��ʳD�Y̉$e��t v$w��4HV�v�;��|g�-���x��nW�� �.t�"O��_���x`�_�a��jN��vHQTw���i�f�	�
��l\kmVt� ��󁆙c���I�e-����|bM��J(��o��S[�����#og��c�����hL�����>�y�p����l��jV���-�%(��(Y�qJ����=��0���(j�o�f J�X& a����n��pm0
��2�aE��Z�MdI� ;�\}��n�����@V5����7����/�,��e���uU@��t��W��ɛ�c�+���5?��|�:ğ\ǜCV3Jk��^:ً�ު1�)٠��a�^��P�pn�[�FW8��7x���}�z�vʎ�c%�m[M�u��3#
�I�=��� � I�|s\��&<DG��n�o>O�z�%t��Cp�I�K��PQ���q��v>������ z���9V�a���,,X�;/�B//$��U�Ô�FÎWXK7D/F8;"�.R�O}<�ے���I��2�H�`���>�T�;���w�v��0�;�Fj�0Z����mюnm�A�?� 3��D��O���L껎ܝ� _�ba-������NO�w���L�1�l��B$�{ք�Q�q��6:q2!@l�#�}���j�#x�O�z0��T�{���B�x��\����4=�Fx�WHī,��O]�nd���Qͼ�!�G�5<�$�Vv�IRC[9=���U� �;l��?q&��mSWvڹ���H�qܚ*Tp4q�#��Qͩ���.jW���c���p�^�J�&J�陋�@�M�+P��C*�v�(�A%���
.�E227�UJ���M
�����{#�˫Ҷ��e���_g?D,���.�'Ul�x���
�,�����dJ�u�ٶ�D���k����z��D�'jxLՎ���=Đ�e��V��y�PҼ�D\�9�za^��l�x��^&�/�_���n4�8F�����ű 9(�0��,���{��'�kz��$m�nR	�����Q,�e9#��,�ہ�OW�s�M��<�bI��Mpkڂb�w$`{�7>q��-�}���ْ��
|�B��!l֟�`�r�-���W9cEC9Nݢ��{%/+I,59��.#=PF�v�Aٞ��0�:'d b�v�b���~�e$HWZX�iy�x�,SnTT�#�]
�Af5Y�o�}��̈�U��(��]u�7cS�Wk��w�]d���꽋Laً��(8Ϋm��8q0�7m�Ds:q&w7	,Z#[ի��7�k��x�A�R�����@��;��$�T ;Ь�x�l	������X��
Y��hn����v����WYT�)g�~�z�$(2S�A[ �^lvxz��k�+���Q9�#zw�ӭ0M3�?�ŸE�2�/��A�ˣ�k�[�A��4���4�ңL�s_�{?�)N�9���5f��F�n�
\�cwog�x�N@RF� �'𮪒���T�����$j_D\��!Լ��Q�o��Ģ{Z4Ò���*�{�L��'��h����T���K)5/�+sZ��"-dr�Y/��m`Vؼ	�PQnH�O�%�JX�#N��}'l��+� �{'E����d+]6�׃���b�p�d�^�J4몜�"�i�m��c�����^��V�If���>(D���vN�*��\N���x�;G^�ی�����'w�j%������K 
��?ͱD��_U�#�B��?[0=��������C��ךN7�7c_]��S�AJ*Э���	����C���P�K2#�i9�`�t��51u�(jX֠����l	�xl�a[�~v2��X7�T1���E�6�,�M��5�(n�E�s��dc�q������/����H/���5n�ӝa@s�h��^��jm�g���;��dlʸJ�> V�є��^U`: �vx�kDen�C#�K��&���[����R��l��w�,6lRF� �Ю�z�!�T��{NM=����������A�����C�zo�rm�D�<�Obw��	d��c_�A��3j2�̝��0�e�Ԍy�^�ɝq�~g
�_���w-����ݴ6Vh<�܌Ͼ�us iͿ*��Ã[f/�c�� �E�8�_�K��vr���~Ā�~xqe"{�d���`�t�T���h�[S����Sܮ�������DK��>�%�"la��sbt�H7�d}��W8�л���2Q�ߢMe�*-3*(]��a��E�~�\R��Mt�+�DxT<��#�*����� �9���%��Q�-WB	���irEM3��ǖ^��2l��T����z��x���X������c��"����E��.���D�'�bG j�;Dj���b6��ˊx�� �-�8��C6��@L�Ѵr�1V��ZFF�v4����I�����}f�;<��p��}?'sl�[ їs��oƷ!�����zy1H�#�)���FG�"I�����g�i��,�H$����7�R��O.�Ѧ�X��_����}�՟ez�A�Pة����*�ឹ�������ƫN~˨��n>VtN:���I�_8-@��ʪ˄��/-��7�t�jɑ�v$ޫef��qҨ�  XiOU��56 ?cih�b��:(F�ST \B���*�xL�Z4Kx p�=+7T)��g*R����$M�Z�IGs���9v�{4�ء�y��FK�9 Wɰ�@N�]�T1c����|m{�
f1�H`f�9{"��Is'T9H��=����>��1`�s-�(�������'E}�6�r�"�YO˛�<�S�Kp;S����	��b�8fpzB�	_>���"���(��_�*��ߐ)�"f<b%���;��h�o`c��C�񑈖@�P�WIvnfO&�L�^��p	����>���[�ug�YR��9����ȁ>���G�R���ml�����u�S�0\�����F_Kq��jE;��DD]�2��4�~�<�V������49;��TB��� ��)1a&=��B�]�^�;�z��@=�7�,]�6~՟��O�y?6�`z��B�6yo�'����H^H�;@r�7<Ѽ��t?E��ix�8p�,q@(�ɷ!��c+>�D����l���#u0`�a����)!��_�݂��S�:���<�s���s7�X�ʸ�����;�QRp��6Tj�1�Őv âx�Ø�띓�a��ӤCN�D��G�"�$�Fps��{����/�/���JKB���5?��$�j��i����<��q�5�#����.����'�/S�>?+�F&4)����&'�Yh�=]f�$W�����6   �EHAB �����iQ���g�    YZ