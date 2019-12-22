#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3896104620"
MD5="2a2e24c3a6bf40f6405df716a44ed50a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20368"
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
	echo Date of packaging: Sun Dec 22 14:28:32 -03 2019
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
�7zXZ  �ִF !   �X���OP] �}��JF���.���_jg�R�0�X.�1�o��*)� ����g�PC`�.�xn�A�G�4WU�����Л1S�B�i�#tW"��3�T��<5�iq�'�/`^l���i�$X�I���:
�Q��[eݒ�);fRZ����[�224�l�� �԰���U��s��K�fׁ
�����+�t��-R/�e5����"�>����Z��$�x_����>�H9����H'ӊ�SZ����������fo!�s!�D�饹KUˈ�����犆��'{�L��@�ՙ�������6��[5��VJro![#�8f�K@DxU�WB��!Fn����~�9cxi���.Lv\���?�l,Z+���fZ�H-��t�e���NtNו�\�uW	����m�U�dV�z0��Nȑ�^���^��4��[���j݁6(c�HV�C����rS��)�'G�V���Օ`|8e	��FCG�R����rRK�(k��fW��Tǟ�\^/�Kڳ$'�Α��y�q9OO$����#����)n��������R~J�5cB�p�
����Q8�6CG�M�):��.V
@��kj�ra9�[{������\��o/���9}���u(�B� H�[���%#"�T^FJ��3���uP��u:�.�2CP@eYYb��ro�&�j4�L`3|�qe[;ޕ����.(m�J�g��j�V@�xwx!\�+�İ�q0 ~ފ�HMCJ�sۃfk�ɒգ|�>�&2�N2
�+���. ݅Qfi�l��&�o��W�x rH��3�2�U��ss:���������n�[�<r�$5�,7�xNп�qw3����	��Q�:���qU�����v9�A���d@�9��N�.K]��X�`���'�T�S �Y�W��!���,��F"�{�|� \���8L\�';�,)�3�*����N�����|������w����魀��=�Վ�f3W���*�&���:I5��s�5u�
U�>5F�BL��n�TK5L�b�=>���!�'���d���� 
���12h����u��56\��B��9l$�`(/%���TQõ_`B4��K3����.����O�L�c�lBԞ�E�pa�l�W�l�DF\F���ҙ����������[�o]m.�R�	�e��'���8�!�e#�]M���N������e��ȏ4�!D̎}��F\�I��=���t����I�b�Qc�z�.�Z��-X����3���GHפwS�>��Y�����%$�(��[��]_�;�۞;V���z�9�R�ST1�
	:U�Ɵ���HR?�����A ���~@7����	0�5gu�,��nb��~O-��n�w琇F��9���T�]�@3��5i�Xx��$��?52�#���y�^��z�{��<3N�HALZp�'�(H���Ge�1gO��'��oL8k+g�N�� Jqˉ����ɟ!���C�-�{iA��BG+!�Q�_A�a�'^N�{f��ĺy�����
�=�)�/�Z��2��Y���Y�8��$薇���,�ٰ&ha~u��ٷ���5/�L��]��m����2&m*L�yǷ�B�?�O\����Jq�.]Q؟$�^���� �P������R�����M�֒��'�iG'��޾|��~-����-�:e�PA�T$�g�M��ūV
�Wl�����;F�+�=�D뇏��ީD��O�iJb�� �k�C���oPfF��«�ua��j;C�����y��mC�'h�D�)bZ��+B2A)a��ۚ]�٩#�����J29���Iv��㢟Q����'BЃA��H���ͷ�N����se��]�%���D�d&�U�3@`��M͵j�N���o���?�v�R���?4�� ٥ zy�G��@�\��B��@h%�XXrr`�@�@0?�u�U{il��l��|��7\��MGD|Uĸ�����%�Ιmi�������j!�9�xG{����\�-�I1`H�mo�2`�@�����4���I�*��R��Jݎ��Y��������;�E��)�*�����A�����7_���6;ÌKm�_p��0�ᦏC:h��L�w�ܾ� ��na��.�ey%X���{��:4aW��{A�x�v�R.��F�-qL���x1���m����R/�A
`Rej�@*�|�p�j�v0wv�����_�LW�k7��` ���B�,��X�Ȟ)�V���[�W9��;���SD`|��=	�/,G������yx���M�	(D�ݎ�3����WCZx՜��fS�3߿V�"_@_0M�� �.O-�l��Y\<�7��s=�*�*���
�nDg	N�˫��3~N�@+8�[]�^���u�g����B"O'��` /���ԧ��O�vgI^��:Q��炲��t��j,��G�JP~����@@�r��:,{@�������~�`�D��y�� +��N'��
���m�G��(��-��EEK#fw��:�}
�w�
���R���=��*�
'�*�G�������Fs��6�O���ޏ�hvĀ8ͨoi7��NBN���j3�{!����\�:��_��uVe�>mDe��:%��s�"Bf����ܥ1����?؀�D���	VD׊U�w�_��c�*�̵ax<:1���Ȍټ~���3��8�lBp�OQ'MI��;�K�^|��#����K=��_��X?W�UIFjp=���2����L:ˤ��Y����c{��o��3�M�~� u�FՆ�
UJ7�F���3���՚��=��������í�
��<%,���`��n3�	���hs�XÆ���4=��|�,�^J���,����- 5�4��`ו�"y�M��Z�လld�t�s;�����/%�X���f.�VG0AoIi'v��H�1Cz�m6���dQ`�1���j4���k�RMDL͍�]����*53.2����W��h���7cS��p/�d���XC��&d�ӎ�%<����<���$�i5�W�g��'�8�w	���J����S|�-�XH�+BGizR�2�J��?��/�Ltx2Ssԡ�<x��I��#Y��e�RZ�Q|I�*@���+�;5���?���1Dݰ�ϱ�OI:�(��>c��Evt�Y�s��KCS%�Z�b�Ɨ+s(Z��ˀSu1�A��Y�rl-)�����pq[T�;�����ZO�kX��~�i/Wrj~ls�eE &�(5���l�$&ރ=e��ZΝ�R"6џ�X3;����*������L�ʁn�V�')M#�ޝʐp�O��-e�&)�cك>���Y�K���-6��O���.��\H�RB����r�]�@� s���}rgJ���裾����&�:	K=�h���'`�!�L�ν��P|f߃P�_r��������j$���9��8�{�r~.��O����׶�qehH�Ǭ05[C�����T$�<F]3�!�Q�����#�y�����3ra&���ɹ�� R��eɳ�Z/�|���Σ�G�3?�} �+Ա�#Dy�t�1��1f5��P$J�~�`�%��V!��R�8�{O=吆��Hs�����X$���ǉI�a�ڈ ��K��=������	V^�D���*�y��dd~�0�u���q��WVJLF����������ڙ?�7-~W���ĕ<��m��w�1�[";2c�R�m��6b�B����ov��Q_g3�{������9=�9lC��&���f���pk�#��# ���҈�[�}�6����[�F�0mf9��B�J�%��;Ӕ�V0�N�CK�n��c��y_��׳<����>p���I�0���G��V
H��BA�o�s�e�͝h��" *��M5ن�J�e<@�c��v2L!����~��O ��6^G̟�!�<,s
�'�m!?� � l���M!��J7�6��>ܶXy��x�Z��䐁9H^Y���d���<���y!�vG�΂BoO}�ϼ*�����M�4'�>z].R�C�!O* ��yW��	��V�o2ɅK���:������1|��N�J����@��gbV=?"�&����U��F�dTc�",��u'��<Kg-!�Y�-V���P���g������*zdd�d�,��:;�nJ����/30�mrM�L1��ܦ5B���aI��U��!:+��}�]�m@��`�JF�����oHn��T���y�>~%�$��>~5GI�)�Q�I�7K[vn��ǘv�,�I/M����j�4��+��80\D�g�0h4"j�_��U�5%���2$"�<wK��JA���>�����e^�C̅B��˙�G�rū�	�f@4�W�9��H��8;�c��H��:RGV���B���MW��0�]��t=�i5�Tv.K��9����t�6�8o�pG6G�n�`�
�]���G+ѣ������]X���DN<��N���>�@�^��]���my�
"x̼V��Rd���u�$SJLZ����~1"�c
�m;q�wL��Xо��?F3R���}�I#�x�\xT�/?'o��5�a2��Z��7.n�]tj�b} )Q�g�i�$F���ϓ�r�tسl���Z�?�|�K�]l���҅�8Wl����iإzt�����WW�����?�˂�C�K��bȊ��l2�=k�A��|��jg�<��x�`&�b��6�z�P=��������u��ݍ����'�aR�D����P�p����pT�b����Ť�l�Z��!�׼���O���F��Vj��bv.O��!0��g�ad�]�v����x�60b�K�bx$���2 1�{������D]�#-��Z�G�4o���L��
P�V������n�emCO���ҝ�:�P}&i��=t�V�An�'|s/&��Z^Y+VU/��1M��s\����C���.������_N6����i���[q�I��b��y���F��E�&�C3��n{�B�7����R;�������n�0:�1�EN=�\H$�"B���X�a^-a�@��g�O1 @eG�ᘲ��e`�g|/!��'\����%ǰ<I�Q��q	#3�4~�gg��:f������Wqi*O%�&u��C�3\����� �?�AJ�]'ж�C���)]�&x��s$'��[��M�M�x�t����c\�m�!����8�#��ò��p�{�}TeQ7���j[�Y��84c�g@�]��ʔ5e���%Ә�8��7d��19�0�j6d����f��Y�"jN����:qy��A�}F���NJ�3/��Q�+��a�v ���,� ��,%�ģ>ҙHM
��9,U4O�����w��℄/��^����@2��f�vs��������Ӄ���@{�z�BF�\��UZ?�)�&�_��o�$69�ɂ�9�h��K���N96>�K�wF9�1��x�G���s�a��y�0� X�%�A�iKt)��f���Xy0qA��4���9��@�]�W(��|8�N@�Ť}���)�S㒾ʯ����D�"���9N�?�hKJK+fBY�{�	�>���7�>�c��M�%T`5�/^�D�ym�x��=�E�~��r�j�7��+�����^��cdID4a��</�ȯ�ٞ��^���(�Ա�ի����7�GVhM]<g�����V�k��@{�U�Y�i�q�wЁ6'"��k��pG_�!�"v@e�/��GQ����-^����3"�_�����o��'���
bt����D�Rp�	�d�Э-�0�U���bQ@�X�o���oׄ�:�ʘT�3��/��h�G+�R�r��[e�/�)߫O�{�����t�d)R��9L��'|�V�Fv�G\���������e��FוQ���l��W։�(,���SPmU��g4ӎ�VmD�h�iA��Q���Ɉ�h���_��S�N�&���G������se�i�nAܮ��#�J���B�@@�����` Ծ���V���kE�	`�s�Jհ�[݌�f�(F�Q���œV�*>n1�oJ��b@fS,����@�١ǿ���^#D�3�`��N��W� ���R���Aa�?��	67��7 e���O���}9g�Kgmq>��G�3�(�%TT�:(K����_B�#kT�a39H�X��kY�b�O�j��*D�:�������q:�4R�\)poL�Uʳ!́rZ_b9ݪ@�>�YX�K���I�Jﺣ���4u��ró�a"�\ǘ�E��*w:h{�.V���N.�9���Ҫq�u�ԟ5�E�O�J;���Ҵ1$5�m��я���|�t:"ڔ9�˜� ����H�/�B�n��_���:�g�3/ް��a�z�n�X���'��>LVT�+���Gy*�ˠc���|�Ƕsr�S:�d{���j�|A�da>@��ר^�l�H�.��ȘG��+�2w,T�VSC�ɜ����V���|'�`T�d��K$�q_��O�6i7��#+�z��-�d�CR��`Ð����4
�_|�V\�8����J���6���-M��ￚ����L-5)Qdp�/6�-��+�*��ȩ�V�団��Ky]�wLH������5v�.}#$f��=�v�SYkeuT��ئ%�a@f�[���x�ի-�)4k�A��9���3t�{�1P!�����ѽ��H^%f�P�1w��t�^3�{S�K����a�4$��4L>�so�/y�ޯ)��?μ���Ex�dq��l�ҭԑ��dϾdj�$<����f�*�a2j�����|KD�i�-�1�Js9������H��mN����5�s�59�4sߓI�ӗX����Qaj����M{���|�߂Yh��������:�D���1X��?D��f<t�{|�T�P; , ����\D��Vu�/Z`Eʏ���)�Ӑ_غ[
 �CI��������ؓ���� K�k��������z���"�!]��L�Kf�(�i��Q�Y�Lڤ����gr�-���vp�ض�p��6	t��;�F�� �whըXtJ���ܧ���Sљ��W)�D|��a�U	����T��Ul�fx7Q��g����^9�A���	F:uv
%*�����"����Kh����|oª�(>;����<�(�Ψd���� �>fk��6��#�/�t׏{9l-�vD���S����}���f��hUo"3ܠ��X�}�w�#!�r֗G`�����$aԻ�����C�m#r�V��G�$KF?�N(-�n���)m ,.hY��+v���X���z1����E�	y�3WU��'���D����ln�����KG�I٤�ڧ�����}�ը���Y��άo�ҭ��\����NF�Nh	;ۑ�8Ж4� ��{L#�����7w��^�Y����/� �2Р��M�lIK���{ݡR#xv�8g��	��5�I���(@4 �Г�Å��{#��L�Ky�d� ����j�Bz9�a�ǧ�V�Of~zX��%���E��V;��'6�G�6��7�>�u��V�zܩ�Rv$'��H�(J�5�.���M�_Ai;j񵨐���=g�Th�� d4�%؅�J��eG[���G�Z��j%y��s§��kZ�P�J�|�h���8	��i�L�i#H���8����uM� C�ޟ��qr'.���v��=�˂������:]L�T�t��o�H��!����#TD�#��5��.s���:�G��ۡS�e�RG�ʬ"�#����+�(��Z��}�#&i���;��%*��XQ���\�
�Ƒ[���S�r�J��4*d�lu�Z�d���o)[�e��7�N����ɥ�b���{Q����[bT��~ſ�]���+\�4��y��<m�,��\�1��PJm��Q���M��BI_L����R�`���� ��Ѥ��̠km��>l�r�*�8iL�I-�#n�T ^���ɗ�g1+�I�T����&�ci@8��'�S؀!��G~(��9�6hY� ��-c�
��D �C�}JS����Tc�ҩ���"х#v��7���) E��ig~���-�:՘"���a�zX��X�xoO5x�O���"t�(.�pC�ְH�7+����$�OF�� �2�:����j���vnW��}�f;��]��l�Iw�q+�m�k�����?0j%�p�#�6 /�(��"��l5��o|f�@�HEKT��LL�I��"�r���r׻�����*4Fmܨ���`P37Ba.�%g�n�V��}���3<��7H7llD�]��+0-��@r-�b���we�ş���&��	�&y�B(��)L~\��l��m����d���&} �6�6���\��o�����[��u�t�%������ Rg������u?�L�*l�.z�h��{�a�2��GR4	R�!�I	lh7�Y�i���~�<q�=�	M`o��2�Qeac�>��>d4��3�cT��Rr�P[p!�睩�vui�YD��a��<���S��K�%��d��z����v.�9퀅��l���$P�A��e��A��R:��8��T��?�B�9��������T��en��=u�T��D~��<����c��<'��B0�\S~\0/�%5��B��V���͛���,�Y�&��]�� V��pt����b'/�a��j�`Q��u�Ő��\*�U�Аz�oߖ)�=�m�Q�
��<m�0*%=>>
D�	ޗ���
�N��k��<�����U Zq�*W��g�Rg�<V`��6�]_���ZH=t�����;�S]!:;��f�ÜW�f��,�>�;R�2��-o����P�F^�L�b�����,����(�j���EKtL�s`��g8�J��Bʀb_H�&QYk�.\�	������Dd��<�P�\DXt����bx�tb_ʷE=���Ⱝ�DI��>��B�6[��Ơ5l�\`OG�oq���oW}�B���Q7�
/g�8���3��TW��{�Deq���"�s2�z������Kg��Y}F[h�o�#����P��K5m,=4���>W��,���',W�ӹ�fK�L�W�>�b��!��/ ��v(Gh �"��X��H�M?M�z���5Sp�"��/Ԋ���%x	� g��.dX[��w<КT�ix$!0������o�!>o�ڐL��+93�&��j�����4�f��*}�6�X��پM��L#�3�����A�c���Q0L!p6�2@2ՕsT��{S÷��78��!���MfJ�K%n��/�[���z�1��{y�J���A��9�*k����.��i+L<0\'W������ �aI��n#���k!g+�m���|^k�]����;�mxz�ɸ�y�mb�퐴����"Y˦+D_����j�?�K�p��d}���W�
����M�3�;�
�RA��+I2puLY��P�4���@y�G^L����g��NJb�k\{��>�m��m�X#�����L�M�%�`ax��������2!O�����O���Y��S�nI�k�L�Yb�W�	�*"�5�%5cQ�=���^Eb��&�����E7w��eʑ�L�n�/7�p���8��U�oY�}��
<)cw����?�Y�4^��u��M�DއTD�(����V���D]P�'ȷg-�$�N5�HMW��L5��$;��:�}	��9`åv��W��O�4g��S͕7T�Oԃ"�,�/�"TGI:DM\
����6�EqQ)=���񷐤��?ꨆ%�O�̀�^�?���O{���N_h!�Nb�8��(<X�r�h0�qơ�~���ӌ s�hq	�
�c9y��G���W�vQ��{-5���$�9P��M�G��nYm�aW7�C��"�iX�a����1� Wu]Em�YA���*!��x�r�H�.(��Q�n�I�Hz7zE��[�:{L�#g���b�.µ2���q
��+�a'�c>�m�H��ڈ��DG!�I�٪H`�i�Ģ�'�2����aqsPA� �IW���}���b�D���Ȫ#!e{�Y\c�{����ڧ.w��G2]"g�<8�>�|yo�a�<�*��E��A/	��!V�@�@:; N�9�r�3O{Wﵹ�?�#�)`�AP��A����6ll8�}�����bX��ĒKq1)쪴�����ֈgcB�b�7����=�'��G\ϖP�`�Q4F¥��Ǖ�蟔E��]و��q����}�.Q?;����eМ85�Hsvh�(�H��m!(��Q��Z^��J$=B��HF^b�:�&��e����x�yJ���.�$J]PX?Q�h}��?�s��r@�^/`7��&.zx�%������h�n(�n�|K
����&q�n>_@��6�<�jR�'��}ę�G����f\����i��͇��	�d����w]�� *mJiZ|K/�B"�B��U�.���Y{�lo#/�2���Ra8t(,@��O�|Eȑ��*`1��R�B9���e�,vݍp���>, �5iK^q��o-��~���a���E�)s1�"�R|��O4q���xu,6N�~��S� ^�޺�^5�m�a#�^��h�.P�J�~��97#�]w��f�5��_�~��7�q��
�F3�2�R�?	��]M�{[�x	 ���ne�R��z���a�V(��`1YsZ����D�_�VB�P J�1g"1ui��_�$����xa�1��hsCX�J�/�N:��0�1��(�
�KT��B��+�+�M���0���OcA�����V7��Z�;������T#�&�Ͷ�yaf�f�l����[4����k_-S^��`��Y6�6�V�p��㣋���ˡ5M��z��'�E�P�THfK��iawt6"����#�]�����C���ur�-�^����t*U����I��d^�A�\f�d��h	�����WN�+�a�L�Z�Q%V���n��#��>]�iH�c ���ۯ����vБ�v��/D�|�G��RQcmK�ճhQ�]{l$���6�ۙ֐1����4VC�Ua ��AN���蕻{j@F3T�V'@=p��ç'֢�
����H�e0�I�XLT��+�Bm���ۏ�즺#	;�9� k����&���s���\�^U P��?�dU-�o��C$�@��q?@u�U(�ގ�:Uӗ��㏜js��"b?Y�*:킶�H�Y$�1������WC��9�xר�����}C��8_�#��������j����7�[���F][O�����MaVٶzv65���c����}�g/PҠXy����{�����PNL���"�
�u�X���n5�6d���"5E^
�g�il��F1cF���⬖s����� #�p0���{�0A{�T�]���ˬ�t��f� ���X�O]H�ۚ�׷��Pɠt��?7!-�*z�'�,0׉-��3I��-w����N1�2RM�X��@y#����CI�q��>��2�R������:���>���(���dy�F���z���,��e�ټ� jb**2Q]�d��;�hi�V5��A5K�1�=��ѵEPp����1�7 E9�S�W+@�Tt&C�b#9@}���5k�8Oϸ� ݼQR�>Bzǋ���q5��A�gFX3OH�C����f��i���8�qMz��
;�z��������E��J����Yκ���5��{��!��O��=��÷�Z�7[��>��GvI��Tlӗ8c;'[3���i؂)����I�=7��r���l�pỉ��Q��ú��	��� �_���	E{��X�g�Y�2�PP��魺���-�e�����X>���FC�:}��|��[�y��i�rj��6�1*���$`o�-���y�w�GF�d�U�j�D����x		'z=���?�)��l���	fwp?���i�3�q�N��@|Y��O��?},Ë�nt�|��*����٘-�括�d�uj�ee�b׿�`l��2���Q-h�_��ߑY�$�i�U"���9��wJͼDU�lw���:<��`���<�e�W��i�=��=U���z$�n�=+�W����YLsI�ƪ�n��Ϙ�����ёa�R�}Y��.ZJ��Ug�N��� 4�>�`�Q�Fi]��qp��7�´��0>���[�g���P��"j�G�a�گ-�ZWS�8����F9��+p���V��e��R�R��.�;p�'Q�I�U^����'�tK�	�Sa���d�3ɫ�����M���}@���/���`�<������U��f����}5I�*�VJ%˩]�t"<�È��G�O:�R��M���FG�*���f���Q�fP	T}��'���hys���-tvQ��Yf�F-�|F��U���0DG���w�p�i�-"&yk�6��#rN��
EӺN�I�"�=:��r�&z�!��=����<�D���ν+ɢ��}^����eQ�G�[���md�J+h�v���hE]<d$�e<U����͋�~�����ݝ���5�Ed#����1�`>����x��&��%̱�Ҹ�^�<H�QW���.�N3��.M��+�{K���d��M<����рR7׉�*
�j���a�ȗ$�?s���J�^���S�����1�e��_W�!���/��C}<g�%�ql�� ������P��%@�(v�І]�� ��AvP(i���M}'�༑?/��'$�NmW3C5�<�^�����Z'��:P����0��f�g�C�Mb��+�ʜ� ,2����J��F>ljnN;'C�k�Dᐗ��{x��G�EBsW�"� ��h�Q����V)AK/i�����@�=�2���1^a� �FN!�,|�rˁ��"�	��Ҋ��h���vip����"�zt�,g9	�QJ�T�V��N3�4o6�-*(�4�D�C���s&��g�A-���SS��ӿ"7'⥴��ޕ7�D���,(�}�ʼhXD{,p����r5|è�N͚fU�7��a��mR����+����D	,|H7J=�8i�q/��3^-�Z<�#gVF�C�a������tx�C_�6B��F䝉%B0�i���_�.$�G'��0�)�8��4��5�9Z9�1z�;@pyn�k+�%�ls�è��`V=�r2�����Fy%hՊq�>�O��5��F2��g��A�O~,��������5������6nD*'�(�Xj��\��^&��\�S��Ik���͂��n*�c t�P~i�~v��zaY�J#	Accb�!�NT$/��#	��NT�@��`�%Z��	���\�d
l�t2«�H������)�S�B��Y�q4�>=ϼ���s�^6���8�5���hhݗ�u�C�&B��u-䷛����a��r�{��ZO�!M�|[�,�8�E��1b���V7=s��{2ù��9�ڡ��\>ħ�S�ȕ���$���4��uWh��n������W-&�£��wb
V=�Ô�j���:�a��� ����c���)7m�y8ݟ�s/��ȩi�S�`��y����)�L���K;�%�4�����T���X�4�eCw��AN�]�T���(�
�ú9�;��㸧[%+.
E�@����m"0D���-�!{;`B xU-1��j˯�w;�D���K��TD�3���5�'��(����ɍBG���C߀�h�>t�z�'��d�t����}�S��߰�2�ն��*�G�6tb��ED�4�W��=}�'�%�e��<5��Ǣ��Gj��*\BG)���#�*c��7�1�T�>~�\{��5^щ�ɨ͙��C_ӹ�?{�q%�݋m���Y�v��-�P}+y]���O#<v�-�j�<��<�Z�E?̭�%�b �|��f�_����u��������I<t��U��;w��z��<�>լ03V�6ݎ�zh#{��a�v�'���\�@�5y,���7�*C�<4�q����\N�ĽU˄�����@��ϛ^��]4y,�E%%[=2}B���^x�ͽ��Pc|�_���bDMj� щS�����A1�)"�.�Μ<f]uE���yAJ�vN�ܐ�R�U�5X�\?�S�"��N��Fen,G}�����?S�"������;Q�/�r��z�X�Δ`���\��9������BҰ�@��K��7e~���;�c=��^�϶�#��a���-Y�t�Z��'�8W��+���?ܺ�G��D J
�H:�&�IƬ�A��}��A�?p7UO-�tRE����{a	h^������o�(���d_�eي�0�#S�}��T:���:&�￪��̿�S��M`���^nճ�4�q��yf�F������Ɇ��ˠ�!G��������f������T'��U�;�R���l��Ʉ����q%���8$���#Y�2�X|�etZkM{�{�'�{����G��a����$��w����4$�����<v����}�*������m�$M���pb�!8�� ���c�r���t���{���P5��{��c���rW�v�S؏%�t!ݴ�K\+Zw>?��/�q���/���U�j�T<�Yʓ�8�|���~���E�E�+�� �CL�8�g�5�k� ���Z�	�gMFM*�3@>,4X�ۇ�����C�c���]z���=�Y�p�:ޙ���o��y:`a��.��`��Sj��ԈR��n̢A���]�"�,g[��t��@'�a.D!wTc���%��x�m�
�L��붃�s�����>gJ��3
:�
�ɣYH��QL�ϲ#��p��eCp+��R�L3��<���i�Lc=ɥpӟH��S��n@���8��;B�����z|z�ݞ~�8�on���� 7��(�M��.� �-��@���~�#`��y�դW�\�tR#b���%CJ�V*�o#N.��lÝ$_�#��79:<�}��M�R|�urֶ������`5WhI?hm�7)F	��S�ד�=������	]�ړ��u�,�lU�q*w����I.$Q��D�D�{����)�����>Gr;����L�G�0���-�������\�������]ߤ��k�{�ɀ���A��C5�V4���W6s�2���ݵ�l�bE�"
�?	�M�u�6��T7^.L�|-�����e�����a�z(Rs8�=gs�"�0b?�9���g�S�X���������(��Z��i
ڋ߭�B�l��z� x�i���5OxD-Ȓ�vVH�@9>ᣤ�2��M�+�VvΉ<����܂&�;?3�\լL��꒍�gV:UT�[o�s	�=�LIy��Q4�Aځ�������߄�Z�"�X'\�:D��M����Q�*9tD���p^�X�mB��^��n#�]�1'ltQ���s��tul��Ƹf�2�A@�b-������M�,?7N���4rZ�-��l��9�DIQt�)JlƪS�H�tc�n
���si,%/<��`����� �e��:fޣ+���헜��Ƀ��VGT�Z'!�ax����X������:u͍�@ȷ�ׇ������$4��S˦��r��(�m�R�]f�W��g�&��t��+�>�ͤ�Ճs�*y�u�m^���d.���q����Yer�����D,y��eN6�Ԗ}��AU�*^a���`���VA�Z��:p�_�75����л� ���[��_l(bR��1RZG~�*0�(���Y�˱�K�1m�/�r�����y#�]�O�>�kRϻ��J�:�㫉���3��>��>��u�[h	�D�,�Ft�Oެ,�̏U�?t�E�=+�2���B�<�#R��QY,�����Jg[�8�u��;2d,6\���8�z�^�}�L٠K����ơ�j�^w	#�Qс$����F>Z���u�����Ow�PEɶh4`ib���(j�	��F/ز�A�"�'����NVå�x�i�d
��S?�Ƈt��
P㯅���l�N
���dlԅ�kt�F��	v��b�5��`��H�K�ݺ~��	u�Kr�]ʎ�C��]Xߙ��3��ӕ
W�*YqWo����s�%�!, )���|�7�:97��eU)I��?~�B��"F��]����Q �]=Y6��
HE{��&�$(]�+c���PN)�/�'�'���ZX*��N�#(ɉ?������j�ۭٔv�&�t;�u�W���P���X�`ג]�~��m�o��7���x1Iƪ� y�*#���	\*�௷�X�ݞyf�5)���~G^�F���Mqݣ
c�TW������ip����m�f��t��ֵx#��`��<�ja9x3S�D���LKi��1~R\-v���|�L���d�a���C��ѥ��p�ޮ�+��'�ܵ4�r`�p�g�[�� U������5�2�JPs��VgF+��=��#�/*NV������:"���"�F���4il�~I�-��)�@*��'����=`���w�o5�$4�Uh~��A0*���v�#�����ů���=�<��(���p�N���� ��g��Ƈ�����=$r9&i�#�(R�h��HG��l�BMS	��������o^��-�����zZ�y�H�N�7�L�d�P,�f_����;֭�`�xUȪi\�M�[?5��q6,}���ǎ,���*��]+�ĴԲ����[uw�1Ģ>ÆX�.-�7����Ƌ3��9�%�$V�Y
�Q�;�'�WG
4���]��P��<�81r��oĴ(��X(d�3(���P�ܚMKo��_��=�Kp��?@��1��cu�_�k}����ZK� ��M��C6[�ӂ���o�%�l'��� ~�ю3�{�r��J�]�k����	�lS7z�{\>�D�ݒF��^����&�ƈVse��U��� �<�Y��!���� ���s�r��A�����d��Y
м����a���0�ZO��L��b�����ȁm�&���W�響�ۉ�	������*#��I[ۚ̌|�Ab�,��^@��S���P�ȫ�� �v��t���e�!�~{���d���df�������:����0�j�v��+	�K��lg���;��1q��H��Έ����ҹ�N:4y8�BՄ���A���k��B���:�D�O���,��=gja5$e�_�a-�K�3�\n��6jQ�0D쟰Ӳ�~U\"e�� W&���p�P��E6�����-WG
Z{�8)���,RLJ������MW�,�%����VT�VF�u���kB���zw��f46��a�
�j=γv��lD��~�82�C��Wى���?s�o�ܠ�7K\�v�łސNV���4@�	�ӌ䃧��7z����I8�&�.�O�u�g�f�L�W6L�����c���`�$J\��U�ȡk}+s҂��|�gspIh�7��{�?\I�����?ԕh��A���v��ko;���!����#�I�zLv*���M]�[jy�f^��:��s�:�0ί�1;�A���nY��C�x���yT�U�"�'�o��?������'� PTL0�EyF�R������Z�F�K�w����_�7�5f���٢���I�(�����>�t~�*j^9��a7�����P��,2���G�C��+4�ԝ��3������,!*9���3kq	?/���'�z���<��������ag��:�˳��-]BH�[��	�U��t�����a��������%��N��eef�Z ���bo�ΰ`$�mSXL5x��~3�ɰ*j��Fz���p�GzT����@HW���GG$H��spx?��6"���d��IVh&>sqn��r�*zu�����QwEϨ�@����U@/?��u��X����&r�x�[�MT�K`�!}/�CL�_��k��XH�����F?�*8�#�"x]���>�S���l�����v^M)ȵ ����zG�����&��{�*�Ѩ�έ�+~������u���!Yn�nma��*U��f����Q);1Ö����:�E�c@�f�:�ӤK��X�àz��M�W	>Ǽ��ӲR�0�� �3���K�(��8�ѵ�� �.$��>�XmޔJ����}��G�>�q�6e<���+|!��<�f�Q=���C@�`��|��6#��窦�lZ몰}?p����ꖏ�1�[�~X�����;ά"��t_�ya�`qx�ۦ\<�t�x�Qg�t�J�޿�$�wf�&�~�=D4MZ3 ��Κ�:�*��q�<C�l�BZ١n�B.��+W뚷z���g
K(���.��.���rf
FG�L�v�P��T��򗛳P�{�!�c!�&A�߹�2N����L���^����=,������A�-���m���C��2m�(��^]�V��|8���[�2�G_`r>�Hs)��)d�*%n)5.�UA����#LS�����³�q@�8�8�qL�6*����)��˒��U�$̜�@o,�0�d�<l#��g��'�wT��Z�+���{<��Jy��	�z�A(il��9���k�EB�����o��c�	�K�E�9=��Ud1
�@hX�G������4�X��c�u�c�cTj�2O�V��Ɠ�P�R���C��P�"-���(�ؼS���2u՝�	���㭐��	[JSM��i��%�[L�1Z��3f�&���z����#O��êĔS�n��F���b��������$.B��7�^���Y���L�t�����k��}�bt�5֑I)h���'|�� 	m���察�d8�{���L�Êjir�x$>���(2��� �6�b���Dm9Zd�\�V��vg�ۯu�v6��xV�ɻ�2|����/�ǣ��v�C܂*��N,Z:�(��%���g	R�"mm>yGq�{'K����50��T�^���k�҈�m� �t��+',�c��`([~����3˃�PԒ����_���v/� �����5�����h�6m19�_�7Y�y���РDr���)�,�cB+����=΂�{�ŢNBoiy��RC��W��nP���/k�x��^���s��P����'z��
J�O�_����o���	�q�԰����qy���:�Wf3��ƍ%s�WZK�U���0��{s�ˎf�@�Q|��d(�%٪�Kި�E�. 뚲�l%��Pka ��Ď��\L���ڨ��[i�Pm˘Pe���6�0�I �7����~%�rc_�W��?��;&�o|"+gҭ�U�T�n�u'�~K��i�ڈ�[a*S�:~B�	c���n��!�7�,Oɀ>,�`ҍd��Ci�ăH��jA�}x�G��V�.a�WH����G;��*+��ٛb5&�E�l���W����~o�3��B���"083��|Y	���t��L�56�]Y���|x�@vi�#�bn��1GP�˱W60X33��Q��_��K�.Q5��M��FE1����%C�١�h����f^��`#�`LglG\����xly&;��~m��'���/��#�V�ۏ��o�������&��1i�"&C�2~�RN�����5�}�R��V�17��􆦳rK�E圃�h�>^�~g�}�C뱊���31��[�Q����U���Myd����/_��{��uX�E�Qs�?���Z��"D�^�T������;��k��m��� Y!����:+�`R@n�������&i���lp��5�����K���Qh��1�7n�@���H$�85b�..h�k�,��Il*K��0>e�q�jJA�)��1�����RO�F��,7z�vVP[O.`�2��r�����%�:��.S.�D��m%?J��[.�����?���^*�d}���'y���ʸ0��?,�p���Ij� {����P��iEWʳ��� �&8|/�t �` Fsg�sY+ ���l�ұ�g�    YZ