#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1728290349"
MD5="2078bca69625da751087f4cc513bb7be"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23832"
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
	echo Date of packaging: Fri Aug  6 17:18:46 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D��ǜ[��\e�5�W�@��fmXР�o
t�F��=��7�h ε���I�W �TBd�>�"�a�� [�U�qk.���t`�rL���-��]�DX$^sJ��8�[��O�!~�f�1d�;^�̚4``��RoW�C8������� ��l��,S��=F�Fq����ǅ��n��Z9{��4���?���ѺE�zCTe��s����n�����2x�,F�'�͹<"��D��l3��a��H�R��!]�pj�#�#R�� ��n���A�a���X��h\�b��	T��Z���Ċ1,!p\$2�ta�L�D�ӇZ��n7�%|`�E�G̹���R(��W�������Ѥ�͉�
�Hnt�݃Ls��֤G�@�x=N���B`�bI���9�Hrv�|��oh���vx���E�\>	���,F.Y��=cуh'J�H�~MF�i����Խ�F�8�]1��cI�~��W G�Y��C����l��Xn�?H�]'EЉ(��LJ��h��ѭl����~"m�Q4%ڛ`��ﴴ���>x,�1�㻚UT�[Q���k< 5�w1�l8{����	;����@�&�4��<���Gk$�z.q��B����?��w�[�@���o��R���p���~yj+A��>�_F`�ηRwIp0�h�¤H�s�(�����&]�\d��n\-����5����V�^���F?j@��(OuS�:��T/S�H�@��?Ub�kj�jB蝅Q�����}��p�|�?��A̝-�f!�$�#����!��Fp��(-�4��P�nɥ�!W��<��ZpXABu����ma�Z&��{E�����5
S¶�����h]�rZ��AP��CG�+�L��>x8k�½Y�>�~�%b�t��w�_A����sZ��zޯ4�:/�+�:�g�I��#�6�}�o)���:�=�p��V���a�STO����X{�.��n�N�H%�-
�oUI�.��^���ĈŶ��(�W�qj�����o��_bz��>Ny�8Y�gG�n����e҉5�M_`d]U�	�5�R�:�d�OR7��xD�]]����g7x�n�$A(��z�߀Ąg�9X�����LϬ�x�ew#��a��9J�t�]˳�����IY�K�8<�9㯘�ހ�x�Z��t������u!ݾD�Cg?O�~�!'~��=�VHb^%���rЉA�ϥt�� �"�c�xC���WbuRz�Ū�+<�O�fH�Sx�? A5��	;��UQ�5�*=h��� @�esnHYrk�IJsSY,)Â�Gԋ�K]������mh~�9�ؐ&�<���t�J±|��D�r���cJ�\�H{q�Gؗ�:݂�Hm������ƠfB�B��;�2��M����X�F���o�WGz:�y�PY�I?|@5����-vc �z���3��}�Ox��E� �,u����7���	ԟ�qz�\�nk�ȊÞ/D0L��	�z���F���q?x�Vnq/R����V��v�	"P*ÅђLx	���!o�-����vZ[$L��}?��^��9y�}¸+�B�*�� ��r1�9�������ٓ�?^ºr�:Ƞ���лp��Z^���ޕ���螀�%H}�7,Z����nmx�R�X�/L��3��M���³Q�ZD��p<���)�^�J�t&�d��1����Yt�y�@r�+났��v�ۂ%�[���ys�{@_8�q���aJs�WBV�2��O(�`�ɾ��f�dd5V�:�ɌM0������4��GAxW�
*��|�?)�M4�o:�5Š�M
�ߣR�lG���&y�[`�s^Ɵ���8/���g�Q��V6<QD�l��|p�{Y�&�jXu���w�jnQ�I��(��m�}�c�"'.��YÉuEJT�1�#5)�b����W�sIN���S�K��z���y�8�.ޏ�ȥC� �Ve2~�����V�H��Y6Eg��*�qhw�P�%�}zQ�U�*$�Ɵ���^���C��d�Dp�vG��,^P��A�cϥ���ب�����`C,J}�ieט?J?��*�"���H�8;��%��e���d%Y!O���A�e�{Њ��:��z��cL���K�C��}|�׏�$.����膁��w��Nu��b���n!g����Բ�O}�M�gI\�ԫy�`<z'��R1�2^�N�e���x�>��˿��	a �Q��L�m ��߫]�=��e �z|{��:�+	��	w9Et�E�'�ڲ��a\�$�$���}�m�. �U�B���v�*�~#Kp�e���t/��P�Y��,K+^�n�5*��2&��رJ:Ӥ�?��ES��!�PY>���u3�'/�+=���|�ly���d��EAϘ��Ǌ�THO����Q��r��w�[U��C��]G�c2u�Z�U��7�+L��^��mU�ܣ;�.�(�+�¨��9�A��6�����?��o���Ǜ���2|TW��;�*�����
<���W'ɝ�����7mց��e���C{nn�=�}��	9�x���8�!M�lEa���]p��̾����A�����i���L ��5[9�j�s���)��d����T����	���DHT��'p�� '1���8��ޛS��D�qnc��csb�l3T�dW��7` ������)��=g�f�k�b���8���k��Jb%Z1;�҇����˺�/�@��zz�=\X�7��ڠs+���,pĺ��"8����,OՌ1x��{z��>�+F�,}�尾"�QƱ!��5��� �p�<�a$�G���Ò�Y����6E9���82;�j��*��?#�v[OS��j\x ᶮ@�0���y� c��8����^����]��)z�^
�9�@h=	����?jN�G�Ƹ�9D����%�1��e����A	X �YG��'H�rm����]�2�e�a����~?��D?��v����QePπ(jGF��*ÇЃ��X/㿹d��<~�4
������2J�"�������/�y��.8Qj4�4X7����:�S	���8���bp��L�5���I�����
�$1�;�<1�"�d���wTi�	�`(��*)I�.:`K�����ģ}���z�֑	5� �7^N)���M�`*�&��U�r�����s�\Z�%�-Mv�(	h��W]�Cş@a��\��*�E�߿�~�Pseʵ��{|	7�D������N@� ��1{E� �Z��e3\���m=Ԟ4ܝ�0��h"�5]�������VxG���\�������\p��m�D����ھ����&m�z1���k
>@q�p�O⸭sL�j)u�9��a�A�*6?Hz-���ؼ�S �CƯ߿<�����N;e��+����f��̿y4��I����n0y�36.VOW���n�b@ w������b`ӣ��oXPÄ��A�
��v=�eBaDZ�B1Q��&�o��m��+�c\�;�i��r9"��`Ί�_���v�wvB�r���
��&sT��T8��w��|���.ʭ�s�5vQ$`^e�O��ZM���^�!+���ҷfck���w�а�Oj�S5��%VH��?��II���Z�u���A.�y��Ùa҅5��T��C�q`q/=����
_�2�e���fb�=s��X� ���h�d���Bӳ�S�-���%h�����P���z_�����ڈ�PJ���9�C���P_|P9�`V�'ʳLaY��mx�V�P	߀���u|�T�Ư�����Տ&\<��Z���*���TJG*]Z�����zv��D��X!��"��g�s���J�zU�⛬���w׫���=�g�l���t�'��s߆Hw�g&ܪ:y�з�CB����F��g��#$���YBw&KJ�B��ُ)5��ɵ؃��i���f�����ǎj�7θ�B�q�K��j���\��OP��Y������<ۥz��)�R�/�>��&���X
9@f�WpZw�x��k�?���G� Z�贋�&b�	)(�4�0+RL|{.�ѥ��tVl����}%"��	��O{��'�����V�i<�F-��@M(yx���t�8}(��I��&y�0ے鬫��@��b�������;�Z�� ��%��O��ZCw�+Y=WhW��0舑�lJ� �#���j��������B��+�D��D�z�e��R%� �C�])^iv�,DA����O�I��/���1}I������>nl�gZ������0,z���9	M���0����j�剠#nCI����n�$c�Η�aK_j��zي��Q~q��`[5K~�Z� ���zJ�}׺�aQ8h�1A坕_���8�� ��n����#��S $�'`�%xy����ށ��b��.�a���K��T) �����4�� ����>�7�?qw� �p�����Grή�� lJw�,3��E���<�չ4��4 R�������4����D��� ������)��/�Y����c�aE�`�\��A.������bR=M���Ƨ��4e�c��7���7K���H	�Rh�h�Ϟ�_V�e�p4���		��_^�ƥ�~�"vQϻx�[o@����>ϴu�>��BD-%����@�nݣN@ԦRQ֧9"O���~ρ=uOހiX�)�2�8�L}+�����_$p�Y)�y�2�R��h�.�~4�Ln��ps�6�����@c�0~����P���B�$3�(Y	�,��*	��h�?��/Y�`_*�.��5�E<d�Ǽ��[-�%�Þ�f�{�r]��ސ ꣿq÷�!��c�I�0Eٛ9e��>
�5�ÿ-�#��`;֕4��9��F���J[*�ih5�I!�'������������d/	�	F1]y���`�P|��:�l��]q�S�{��/I	7k>صJ��"\-/j������`��IĘH8�p\�qFH�%���$�݀�ҽk}�&%��w��ԟe{��q��Q��:����h${o�6Q��������y&�s��݋�2��JFGxS�; ϕ��fR��b:���� ����቟D�?�}o���>6���$.���w�������E���aib$�5�E�E��Y��|���w�9�k���t�� r�`���v��1hh��{Ɯ&��P(�i�vɵ�jT:���,����|�XޚF�X�	���)�5�+� /��e�-��x	�6��b����C�\��x������7���e.7R4m}������֎��t��o����Q�R*�z�0�;:�ٿ�:��J��8� �9��p���Mf�(|�wG�j#�O	t���w\�����*��yr	?Ə�4��)Bv�q���L��� n	S=������ܢދ�֪�@�y=WA��eQ	S���-�"o�%G [ҕc�M�Sz�V�g���h�w(>�vV�V�?�6��"��l��)��}Q��eI<��{�Wـ�>�R��՚��a�����8:�.���mY�fTG�>�|����c�PM3}f�L.�)��+=Z?@wB@�3��z�/��Za��WW�?�},�jr�)?��ֻ��D 8ʟ��Y�a�{���P�÷��'�L�i7N��~p�i6�IC�$������MI-{��y�C÷��jK��Nц�Ӑ���bK�^%4�~�:��U����#��9����J^��g
���x%�1�:�6_6I*��a�2ʸ�틨�b���vV�*�`���^�o1�Քl/�[A ��/���ñ6��3s�F&f/ٻ� �t%\�U� ��ΠE�Ռ�����ۄW��� �,{��Y�h��+Ii�{L�4�Y�?�1����	�m��8��=�#�z�H� f˝��&|F��Lu����;
�%��15S��#�r e��9p�&�L��A��H5"���Y&>�K3 �0=̮�0�T���~4M���,̇`�F���Y��ŋL�\⬴M��Z�Lq_���Rm�an���STP�HAS���w�ʛv�D�J<�+W�_9@�dd�B�$_7�u\&�ChL���R�y���۠�Y���v��ݏ����o������ҹTb��=b%<z����'�f`�h�E��C�Z)�d,�b ��=��JOhA�e���Q5m�l(���M��AK�.^��n쒴,��ii�K<+�b���)�,�e�T��Ȃ]�[o�|z�3��L�d2���a��k���`�B��N���u��80A��GI��i�G�I3�������,
>k�	!����?�_���:� L��
U�b������]~����j(�������Ĥr�ҏ@!p�Cͷ�ډ1��9s�Ӣ.��2zPA����,?f𰧈?f��_�j�[(M�Rn��~,�*ŇZ�+`V9�\�ZmQm�U@X���z��ߵ:T&&ǫS����|��b׼"�^R�ȷ`����۽X,p��b:JL��7\iDa��=>v����1$q(��`��&����V�n�Sx���l�1I�x�:q�e7�g�1 W._B�}{�+�m�{���&��UF\�]t��:i�<��>�%yShr*INu�'�<�`���-�� �OըaB��	��U����)����-��FR�zu�6�L31Sׯ��}~��5��V/����ʜ3�?�S������F�ί����.Cs����9���+�������@��
,L�zxx�9K'���r�aޭ�⪄Cg�f�$q�j	h�� |F��VJ0����8dK�5Hț$%�v��� ����M�[a��f��O8�����I<V�aэ=�J�xnj�=f	C\�a��xZ "7̖�g�-�~Q�i-��׍����cZ���Tﶪi?	������Hj=Dh����Z��0��N��*J�+TxJ��Z�����.A�XsK!�}�,����eǱwP�u��"�=,�K�8Mv3�8M]&�&�k+N��XƘ�چF���� ���B`�yȬ�C�Y���E'?�OA6� X� a�	bQX,�*ig����]$��s!���R�G�6v�c���|x[�eC3R2�&s�.ϕ��J��K���=���Qu�-_�Ɛ*}#.��[�Bf��h^����
�Ֆ�=�K�>2�0��ÿ�˯���<�(|���hr��? �����=4!*m�U! ��5A��LF~q+�yL��Ϭ�V�%��)��Xڣ��v�go�D�'V���u^Ǟ~�?m�_�c��Ɵ��ў0*Rh���2�Hlݠ�o���o�����n�Nڂ�O�S�p�"1��W��Ii5!����?p�ԕ�cr�s9V�y �����R�g�6�L���(vݪ&��9�4��3n�
�E�jV��g���/��ܑ�U����q�"�O7/��A1�m���,�}�^S~{;%�.x|�iL�[�P�i�]|���~��AP������T�j3��b��n�La�#�89�H�F��7�y'�`� /�!M��~��2�p(�)2 e��m�+xM�zk��:�ɖH��+\T����y�P����n=!��N���3��2�]:�Ɠ�>GVb��C�ܡ���fx���B���J`�5����E
���
����@���),+>"��F�S�N�Si�h�4��=FF͸�*E��4�g�k(tR�"����EQg!����2���Xj�V���,~<Z�c�1x��g֋� ,,h��t>��p�aY,sK"�@�c|=�߳����1f�*�H�l���#���O9�PpZ�c_�QcL������T�M�z��54�L��z����]J�Z���tQ�z)�Ƙ��g8v�^c��0�`ܸ�i>���Sͧ�gi�kb͞�n$���Mӿav+yHPG���2 �1�!v<���o������B�<�F %hs�Z�߅<(�l�s��� �Ժ�Pk�	�m�0a�W>x8��r���vjkUA�萦l��V�¦��j�)0**��.'�f	-:^�M0P������]Za�f�墯�7����H��O�X���|��Y�e%�N���[���C)"����'����z��XǱ���鹌D�n�#�5A���4����T�B�:f�k���H������bq{_?OX��Ո��ا��^^����t8��$�B��='��?�B[���`��i},F�+4��� ���
<b��f���(�E�0prq�JA��G��]gH��cFO�F�BO�d[��!�JF���jw�,#|k+��j8K�H�-9��>eK���&�1��.H�>.U?�dKS�:�!o���֩]߽}�|���,u-+��&��3�i�7�#�?"ݞ�R4��U��<��
���+���#�_�-o{�]ِ�s̮yF�ܕ�`���B�b&v�G��c���JN����]Cn2�|����/9�[J\v�~��Iy5b-���dC+yx����e%��I4�d�¾Mk녀o��3�B��0�>�0�j��&Gow*�#�5�0�1HI�F���� |�G�ezq���[H�<~�b��q+E��t>���RamM��^�ۮ����38Y��tH�ԙ��F"��,�T�l\�2n�����u���@���	�����zx�WZɊ�MwPAҸ�ń�n(�$�-�Y��HΛ��g���i�@t�*`-���،�D]�D� �OK4��M����H�'��\�n�:^#!\Q��?�1�z������ Z�N�C��� /�`]�qrd�:�W2w~i�4�uaZ����h����*��D��^}�� �<��bf�� Qa���
��}��P�Q��a=i�s���t�����I�����2���ם)!oQ�J���TQ�R��k�S�路�7"��Q��e���w�7 ���o����a���,�akg�jK	��p���OKL�����/���yI��'?�t����j*������cC�em����i9�{VbSCs������1s���y8�K�Sx��;ҏ�
���=�b�d�5;�<5�	 5"6�V�E�����>���MD\�&��<�����ʑ���9�����e��FbK�}�R/�<�R��ց];`�C��fF����8A��Uơ��~�T�$u]t���s:�G(���S�~g�'�`��]LU� 綅�Y��/�.|�"�o��bj��NpQ턐-��U��/9`V�Ɗϻ���@:?v�jȥn���|  ��}z���k�!��x�����YO!T�@&͌�4�]�K�dM�2��-�]��v���O'�V���6Q z=_4����.+�X0N(�-X��a����A�X�k�E�$d}�1�[L�9��SI�:�[�"���I�N��{��=�
�v�L�)�6$Zxz �ZBbmԊA�/¸�1��=m,���E����}hbO��Bďm�.mD	�#Hs��h��D�_�"���^=r��� %�$~�蠢��h�U���^u1��C�N=/f�����1��3�L|��^�4�%�a��u��7lt�u&k�Z��'eOC��,�A�b�G5� ��q�9�U�(E�m��||��vOL|�����w��V<M��?��h*�1<�jG�4�qi��L&���
�v�|�~u�<��/e��&�+���[^��q(��e Nv��
.̺�������a���H�@}��yr���Fe�l�h0}��VbF�+B�����!�ӛb�Y������u�s�L��X�bZר�����䦠m�A_����oi����&:j/�X4"Z�F�imu&���m�c�{KI���)T�=��٢��C3�"�=8�.�C� ��4}�!���h��7{�!��A���kt��8:��Y�C�,�����g�����Rmh8�������:ºy��``�.^~O
G�5��e�b��J{/�� $��������X;��p�i}(m����{��M*����^�������0����/aҫ"�u'�[��eF� ���R�g3l�����N��&�7̐�C�ۘ���(\t��mq�e0��9\/�!Q�Ō[t��ԜQ*\*l�Э�<�е��0/�%�>f��vH�Q�g��8����?}�̉vwJOs�6����y(a�<K���#���L�~]2襘ٷ����M�'�q�\�b7ȷ`D�v�DͰ�UZs��PD	���Ѐq^:�/_��ʡ��(�[�p7�'�IM�Ь翗��T�������Cq8��
?����kY��w�\��crq;9�*�r�d�"��vh=p�:/J���ÊE�y�\nv��c[���[XR�ɯ�"��^z`xmJ"p������R�K���a�� v'�v�>��nP:���R5R��ˀ҄���r�Tv�ߓē@�a8�w>e~"
<��C���@�2ج����|�ѩ33�^E��~Z$`��rR��a�G��t�uj#��!�X��9�,cN�2x�w�Ⱦm'U����b�jfp|'H����6�x��9��q��T8��e�����N�D'�I�|7��|ށm]�̇ <g]�3�߿�2F�6����?v'*H��g*���4�_ 654;�_��G�<��gG�~�p+XX]�����"OE�37�![�!d��y���oMp����{���j��cʝD;�׿��Y�E����P�Bq�B-�p�1{���<!}[���a��8���Ҙ����{��}�͢M��j�D��5gk噤�����(>VOj{��{ @�����g�g[���$����5�v�Ya+%�3����Q��� G6�0��LoE�J���^*�QJ��ۢ��^#�s��phA�V��^�8!-�%���R��ԥOc#��_�<��V�ś��1�,Y��= �������ڔ��ݕ�W}H�bޞ�8i����k�==���L*��ۖB)�	��X,�*D`\@*Ci��4q<��pq[!oZ���K6H����9 ��q���tw�.��X�B��X�O}���MK��&%ŨK]�X&���OS� 91��Yi���6�5�� �A\m��Q�P3I���ֿ���ąRs��l2u��x!5�U�����*��HIC{��MBr �~���a���PSm�4��l�,vC��9βz��ez]��=���351�+t̜���y���$��W�*� 2!�5�l�����n����L����\[F��f:7��U�בb|���û�)'�NW)���VY|9*D���y��^�|f|�D����i�ꭐ��k0���IEn2����e2��$Mct�ƛbK���Fc��J��XZ�@3����>��y�h�j帼�D0j?M1�<O�)��Z���`rc~���cJ�С��	�	Ra�~Cr�z�+���l62��w�� �1���I*��ۄ��8�Q�fM�s��nn;����,���Dd?	�rp��zD, �}�6D�k�L���w&3��֌��*4��.���hf����f�Q��ץ�#O�����T���^�c�l�/���t2�tM�t�rߨ ��k���n@�t�\?	�׻��ȇ��O�!��ݲ:��G��P���a��^MT��/��LA��q�E�����x
v"�������|�*�+����F�w�����v�7S�G"Y�3+�#�Fm_v�y�r�]g*��PJ9�p�9���Ɔ�ɝ����fm�M���P�d����]��]��G�h<�����8e�a�~7�� Zd0Sq&�zr	Cx  ��\!���q$����K0T1e������Z#�a�^Y���%����Y��b�ӄ�c�gN������8�'ߙp��Ŧ8��v�������s��A������op�+��q,�=pO���'~�����*�&?�~+,إ��ޮ%��I\WL����d�8ff�̋G�T:�ѼI}�������u� +|���K� �(Iq,����0�5����9��1�� ��
1hc?��@�-QS�Rǔ�>>�nڴ'�>$�`�G0���e��ҫ4C�"	Z�m ������-�s�-��J�yY����F�B ƣ����^�@$�}/QI,Ђ���ŶDx�Q�R�dʼV�!v�
�����4q.K��(�FAF#v�7�Ib7��\�^>�����5�&����
a&�� V��Yz3������6�� �:�2�2�#eѯ�/5� y�S��=�|���H���w_"�����un�@��y���Srs2�pC��l�Eǝ�@����%l]B	�z�k�t�ۓW$f����xͦg�
� P]�|�̿:f�Z�C�o����3����C`��ֿ�N�-��+�-���+��)t{��B ���6�:kb��Dum�>Op����S�h�x��~>�q�.��g�p��q2Tn��Η���^�y���M����T�ʂ;��gh떊�&���c���v�v�� ����BDOA����`�#i&����H������Q�'�,��RŌ�7v���I��b��(�R�U-�3���&���+�����7���F	n������M��@��Yj<��'���V��@��8�;��M��BJ��>CC�r��+���T����A��)zf��������B_��� F���� B����w[���Ũ̾6����XN��1��Rޞ��]� ���/�l٘�g�%�Oo~Kl�x�zd����m�A8���}ۊV�#��4��Q��d��5)��0�n�ƤL��C%l��}龱�	�I�,pv�Hӏ6��?�sau*�XgM?�{�xw��#!�������R�Ͻ]�c�"�d}J� A������]�~���Z!܉gˁ���|�/��[	�;�4UYܛ�f��%�L���#\�^��Gf��ܔ�t�[�3^��u��=�W�O�,�TFD��EF'�i�^e]�W�Ǜ��x�7�SS`�6G���<r�=�o�^M���J�/K�b�õ2
�.u�?vY�bq�'����!��\�k������� *�S����֊7��w<��C��i��H��Mq$��$�I���%c��S�pg4R⿁��<��:�>�yp����� ���N��L�#0}�t�D �!H��K�N��N��p�G">���B�}��(��v�2�s�*���{#2���d_�I`;���C�H�)�q��A�
���Ƅ�
a4�^�f�M?\��0햕��ߴ��w�<�}��N58p���q���A���9��۝Fd�o`�a�_dm�th�O�b�����-
����!��Y�b���d�)�Xڶ���@
�q?���Ol�餖��ۿ��dMm\���S�y��_�À ��㸪��o[Y�=V�N|�ŧ��?i�a���=C����Ȑ�-��Z������1b�=�Gc�ӳ��R���./n󑋶� RG����Q,�¤�$�K}��MY��R�; ��ʕs*G9(�mhn]�+Ͱ�+�ډ��Ն��Hl"b��f�Pqޚ�=��o]u�c2΄��y��v��T�<,�㝑��h˝��ߔ "��N�4��Ly�Qx��O�����tj(O�0����%�?�r1��Q�׿�!��1��-I@��M���,W�(q�t�����4�4 �Qch�-��>�#�8W>�os��@o/� ﷂN�2�c� c�R�p��x���w��U�
TwE�>�鴥K�Cv�Z:�0j�R�w.4�㨯w�O�S�q�0w��s��R�sr)vdo�p�6pp��F�]�A���	P�V�m��9�E}N��f0Vs���rĊ4�pC�߇"'9 ��%�\y��e�`�~.-܇�I�w���ŕ�>
�H�cD���.W�i��߯Ci�oHx��5�B�(N��u��R��Vȟ ��8<��jP��tm&Y'_�6�ݢpk!����d���R�����N�.Z�U���-���z������GY�Sl��D#����@��.�H�7�����XMȱAxH����`:o���x:�w�UoM�ԓ��j��b��!sN�h�0T��>��cݰc����'3�G�c_{��ǹ�?��y�Q�$�F��0�E;��^�tۤ�>�9�#M[�M(�/�/�8��&2+�_f����uS>�~�PW
_�������
�١�fmƃ]a�mx���#1N����ƀ�W9y�؄qE��rC�����m��h`��SL���p��qԚ�l�JN���"���� ��-�߄�����m�&�sW� R[-i�+��MuBU�
��;u��45Fh�+�Lkb�);��@��<cM���*��؟NǊz+��ߝ��nu��#���:�.��תG ���@�,~� ��9����P�Gq���/�C�� 1ƱQ�`���;ʈ��m=ZE�ے'Q�O
�e�|��~#I�Nqbv�s8�o`iA���+�z�,q3����K������M�M&F�AU�R13.�wO���reXv�6��q8Q�K���PHA���u5m>��[ҁ�#ϐ�I��A	��>\V�-�%����M ��'>U����iR�����kS;jK�])�!b���6�NU>Z`��ש�c g��yALw�)� �5���j �F������}>��$D⓮倉'*8����<w_:�7<�fPԿs^�e��-�=��/A�/U����ً͐hm	�Fa�g��X\�i��3/�������q�rc/�^�r��ͮ�,X��ՊQlTkY����� �
۲�L$ak>��}����G3$Ɵ��;�%Gn2��V�סn����&�qP��G�58,XҠS�3&�Ә��e?M9��슗��IRȉ�)�8�Г���1��'#_%B~��T���iP�����>�(r��G����i��\[=����ߵ�w� �	��S�/��KF���К[cd�9֪��I"�OԦ��ؘ���4R��w��($�CL9��J䓔*$46bgݾJ.D���b��&�ٸ�M̈́
Q:#nj��Do�2ޓ4���i3�w���ITp�nR�+N&a����V� [��%�r�ɢ�>(�$�YUMVI�{�֌H�8�0��ٖ[��]ʛ���D�1
��wXyS�hԱ!�sfO���cA��/�Q�������<?7�?�;�u�:��3p*��$�.\�s�/Y�;��Z��:ŀ���@�3��B'��1b�S�S�-o�������96��H:iq��|�C��R���t_6��6pp��FGN�>)7�K :��koqʒ1׏�X�A��d>r ��.�5ƧwO�ՙs�������a�6����-ֳZ��⼘���e+>�)�\rYU8]h�H, ��]�_�n�=={Q�6n5ć�2q47:���iT�)�n��"������^4��N�J�a{njɹS���~�U7Q�g��
�b�W��
2��2ȶ��Q��M ؏?��-�>���j�l�x�W��яށ�������r��UJ̬Ĉ�<<�TQ~�?zg������ӅJ��|ppE6y���ܳ�,��gJ��AuW��|�F�cU;�����V�"q�!����\��lx _����D��FHp$>�L����׋�v��l��L�i�NX�w�N����~�/�8ɏO�I\u!6J]�!&8h%S]�9;v�V�<��%:C�!kfbn�dA�^w&����9d�JЍmO#������G3ʋ�I)��-�5�]��2G�^H6��Be�ⅰeE�<�u�e�d�[�FM�i	FE�����3��J�@��s�.r���>���=$i�av+�l�n[3�%Ҙ�p�c@1p�ۦ�F���&J��$؃�Y��Q�O���	RzќH�v�$Sʅ����l�  �	�߱��s؁\�ǿ��@,*l��l��9�'j��Tk���ʏPw�d 49GY���d�,�P��n�Y���M��G$?��sXR�G]_��qq}ݧ�.tHj��80��>�J��ߡdy{�x!��t�����j��a#3�!�����j@��F�̵�&�-f�^���w��W���U����# =�U~2/�9�E��ڨ*�{��6����m���Μ���e�Ιzܳt&^���m��i9""�g�\�C!A7�H����ɕ,��Rz&� @��%��/�� a�gWbq�X������,z��Z�����V#��ck��xɳ)�p������g���wi�L2|mY�&4�;~�\̋��J��jf ��͵7Ti$�l�ۊ������/�^V�1�(����k^��=z�ӗ�I9=��V�������å�W��;gE�((��m�������%��c��~�$4���Q2���.9ª���t��禷-}�� �Q�w9��9ʳ�p��t_T��>��E��
_�q�hp��Q	�/32+�IRG�7��������l̊�P�I>����K��Q��?�cX���>cZU��d�I��w�%&�~%-�S�2G�㿚݅��l�����8�)��=U���b�($l]9h'Pz������~��#��YR���Ο�XN��ǶT`<�:�-A�E�g��E���� v��!�7�]XƂz�z��|��v����!0T�G�x�]n6GE�j2-��"丕B�������˧4�~�H�?�q�n S֕����l��YoX�FCt��� @,O�Σ�x�n���ۚi��<ڡ.�oIc�q�}1=��;�;��<P�����ێ����O/����z���ĝ�����S"X������ucf�9c���u�$��r�C��-��[��I�#�U��i�&�G�-0j���H&�� �\����~������#�GL�H"�k7y_GY9�gY���d��׸a�H�����ZB�q"
ݜ��hB<���s��#��K��$:���A���1o4��ss��$�|�K:�b�)��L���K}C�'��f�mb�A����^ t ��^��7����fl-��|i�+3��������Wͦ����h]��y��7�VHb��F`E�6�b����	��'z��4 �N^�����vkL��jE����9N�%�0'/F]��^�{6ۛ�o=&�=��"4* �t�T�u\ޯ^v��NX�0��̩�%��.��i$��x��o���6���	Dr.q&;���y��/�muF��%"B�`(��C&mO���@�bgN��h�$]����|�~�y���<������9�b�E¬�2�4���1�3� �5∄`=�t?y�P���_��"g�z�&t^���������XzMv%�y�������P��X_P\^']Ņ>|t�QBV3��fg���X=�w1۠��� N�>�g�z��(J���-MD��ڭ�	��ɻ���`���Re)k,�,�׫ݥ���%�7�3+w�� u���] g}�%}5wjl5����@u4� �D�ע��$[:������Z�۸���g��d� #���#�ze�|�<�3�GQ�i�I���_��2tX���E�6Zw$	�R���ߑ03�Q�������bD-�t�u�Ж��
��X��m$�8�/��%?ߺ�H�Ҋfx@7��(�C�%��}��*��d*�v]W�/Jf��4�Q���|���k��cz��[������	�h&���l.�}��i����Ɇ�7��/���&�q(�(�����o{���韅~��������e�'c�}��<NJl��Q�/h���	�W���"�k�b��R8��][�D�F&	�Q�\%k�p�Lb*�C�qT�����N�����O4l�t�a�V�J<	���A��tE���ɏ���3e�Q8�t�����U���H�L5��h��/�����p��V[2��3.�|��)%�Rf�O@������BS��ͻ>I��ZH��� S�g~ɯ,W]Z��S��$� �_*��2�!����fL��o���A����,`?c:u���Oc��MA1p�܆�c[,2�	I���;�.�ܗ�8E�#�RLÍ������d2�)��y�y{��I�_�� 	I��Kh~�	L�1@��\TzGl���'���� X"�ߵT�ه�q�*�ы34c���a �I����lu;M3�{�HG8Uz�-a�'��_&{h!>��(kR�`S���wK3gQA�
܄�k� �����}�nz����^���!�oЏ>��6��HH)�X	�:�Otp_�_��XUSM߃Òb�/,�ý����Q��Þ���A=T��w���M���U���1��y<Ĥɝ@������|��"wx�T�	��E�\���Fv's6 � �tҺ�;za��R�@��$��G��I��4�]�l�
�NX��=�vN˩��LJ�iv����Q�G|
���I����U�%LHͩ���=���=�����!�BZ�"2��>3���o����!Z�����,ϣ��{4�'�V�U֩?<ow��Y�c)��_	���3H�RfN���F���z��&/(e��"$��qi3�U`�喻6&X����s����c��-SsH��UQC�I.��}o@z w��7iy�@�5��T*�Ō+Z⛙zX^�E��Z��K�kϏE(����T\�O���{OEt�{�i�ʌL��	Z�f���_�#�]�[l���>>�~��:�6n �� "%�\���k {���:��KA����]�6�J�A^n�'�M�-M{�I�&�u �w��D3�$��鄩�r�oԐ�1rɰB��G��T��'ZW��02��>��KGj��Z{�����:_o�ֱ����\oM?�U��h�L�?�����T�������4�1+����e}�g�T���\P�U��(H���]����s�َﾜ}��X�Y��A`�_��C�2���ƦI�p��i}wf��K�ƙ�=s�h(1	7�݆e�,�����:��91_E�Ę6���28/�� �&!C�F9��4+��Շ$�M¢^	�H]��g�����:A��ߣ)�y�ey�3&�|86sb�D.%�2C���l<�聂nX���Y�8��i_��a����TD����d�R"<�}z�H+#��j���u�uԅ<U���>7alxc�2 �;J�M%� �
�~_wg�Cܺ��X���Eb �������ڍ�;VA� �mSP~?�#L��֑Ǣ�n�*�?��y}�Męn����U5}���yU�"��Ab�x�����Y�U�%� ��,R�b�z����L�-��_#Y��mE���$�B�H�O���'R౬6D�y<�_K>��BPag\�� �C>�)Ȗ�l�(���腯���D-��� &VO�f�w����T��)8�Ou��]�-?���*�Ǔ	A,�p?��8��a�)�I�a_�QU�}�;��C,�8ܕD�(9�������/�e�}-������=�9��zu�{� �F%�|���'�s��x��3[y��� ��a�����t��F�5���w7��+���E�Y~q��@B���B�c@���F��ix;�h=x����G���9K�$rg��w�/���>껫v�O��L��vq����tHkYp��28��+U�Z>!o	����6���m�$�ϯ*%r*%(o��(��fH�����A�挝��|��g7YqI�z=���;��vQZ��9>`�ډk���E��o�	�i�xxX��d���:[��wXSy����h^���v���eȴ���e''�_��ʹwԴǥ���Y' "�������&J �Z�]h�P���GKBr3��7Ԉ})���f��(�_�M6�����/N����G�a��o���쬈z]
p�����pit�S ʚ����_��7�\������������1<b� �X�#��I%3x'����	�;� �_�=A��C^��|;*޴e�=!��>	�A�:}_�^&����bCk���QkdN��Y����U�@}���S%i0�Jb*��m�ZI�A_Х0w%(�)�X�\���ѡ�*jF:�y�Z�ЫQ�q��Q����4�	�ǕF���P�H-PթU�.!��iU��v�"��no��ɦ��v��mJk���X6�pe����
Y��\��}�i\�&]\����!"�Y�L�7)0�MF�cHS-��[4Q��R�zt£�HnF�/� j����*�$�z{�b�R�fM���O��ikR)�)�L䶎�b|I$�x�V42�p�DE�ų�S
t��ˀ����2 AI��59M�d��ޤ�ӂk5HAX��㰬rj���tm�Y�.��T-�DFI�O�i|7�-[��G7�|�������pA"�|�x�EbG���A�L��A�.�g��9�'��k���� ���#J�W�q���i=�	��������H~=^�a���d歺0`(V˳v������k%S�P��Kk����eWK��?�5 �6�J9;Xd��%��Ԓ�b�j�j�2
x�`�����xF��h�~��Ү��MʰkE�F
s+�?8s��.D�#4?��RǺ�_tf��{�s����8��h�3)�ek�9�:}���L��0i;r)�w݊��?���FB5��i��xr��y[W�	��I�k?���(�D NmE_4ٞ �1o>�zF�$!�Iy�tO���T�Ь�^-,�bG���~ݾ��LJU�ɴ�0n��)�>C1Jn[֛k�C�c�!a9 _rUᕇu^IFԨ�K{o��T��h��56Y6D�:�	 4�{[I0��c<��p\� �Q�'X�Zӏ���l��n��N�Y��IV`�7>��*��1{�TA�4Ϻu�ǥߋ#-f}r��*�n��H����}0�d�U?S���	�a�k k����_����vȍ�x��|��C
1�%��S�$��C�߲�|�
�׾	@T!W�A~�ar��}��k���>-%=#H%��C�x��I��;�v*����z�zF�ҹ��P�RM��Y����d���g����c�V.��v=h�b��`@P��F�XH����_��XM�gHY�;0k���`��1��S�'ȞO�4
/ K������~^��9Xd��0	u���`;~GkN�gT�c�c��F@��>�S�I��iN�� 
F?Lf����6v&�@Y-���S9�?c���(r�F���݁��Jx<y�^X��_l�F������o�J���˶�?Ţ�hW>dq"uS/RN�Ģ��ϼ a5�Dc߲ 1��8ف�uK�R��[����,�a����,\�`a���F7C�(��ȉs@AS���B9�-������C�k�w�������$�.a��D,��sp�Ĥ7r X&L�8
w��3]ѻ�>m����*0F7�\&#�{�X�JM�O?�.춅��M�J��[�(����w|L]U><02:Kai���P��F4�l4Op��������s��II��i��9�B����=x�Ɨ�����W��p�'�_�� g0D���#�ZH�x����m�!�#-��:�h�����4}���9$���[�hϟ�d�9�0�D�� "������ǭ�6��GZ�Mh�QÙ6م�AO��s�,csMf:*�����9sŰ�_FGZ
�G��$�[��s�c�1A�
Ń�u�S����;QU��u�7*�� �Q>���E|�/��~�Ý�CIӀj�����O%��l�����b��E@����%� a<!����4�j@󴫵�r���p���}/
7���%"xKRP&H�Ws�k�H���ĭ�g �ս�f���ϔ��כ�!/vۿ�ꅔ�UɽR����6p��w����<��	�V)�0]��s-�$�{�j��f����-�>�:�d@�Uo�ڱ��4�.��rџ���h�0�x��ot7��ĥA/eH�ȗl�1�V_/>N
i{dM��J�e�׬��Ի;ɩ��|�nX����{$���&�rv��3�/�F�X�X��2�L���|���$�a(���� k~g���q�F,0�[��d�8�\|�#%3NPAl´k��t''1]�K�hÄ�(�>b�Ǆ�k�� �^'�^&
b�o]��z�Vݜ�G�sDagWm4��uv�%�o�M�������W�ll'f��6�,ޔL��9�)�%5P�=�&�_S��l*�n�Џ����>�2��f���Ϯ�Af�ǧ�Ⱦg%�1IH�Ǻ�㵎Ɠ�k��nP��E	�:�[�T5V�`����,���췠X�xV�G/e�){5z1�F�<\�ͽ	��o��=�"����N@sez*?F��	�QD�ʋ�F�a�9�ǘݢٮ��"ẋwUY!ίQT5�Ĳ�~
����f�����I,�������)R�ݣ$/�G��O���G��v��o�9��I�/�Br��v�x�`@�(�G�#�j:Gc��D �g\�Æ>��q��L.����S=���->��qy�]@�n@���q<J�.�uNL1�綝>�6�W�5��;u9d��s���\�b�^���+��6�Eμr�,"��[�h�Tǹ�n�0���*}����.��ǁ��z�虣���\�Q��Ցx~X��x�߃"� gn
P����g�#�؞U��cKǛgϮ��Q��W3���g�4�,��F�}�)`8R���x|q��zM�'���"؁��Z��^��L�)!mڷ/���'�7.��	ޟ��c!�jd�s�ײ�dWU���JbAV8,ͫa2R��8���J�J��Vk��o��d�M0^�1���yz>[\_��t�P%0�=��qiG!ּ(�|C�2��4ٷXl�5�)nN/���%�.�B�ӧFe�x7ΙL�<�N��F�8s8u|�[�R����ON�ݺ92��ͬ������DQi���H���fj�V#�#��J�0��v�����߮�8x�|�ٙ�ä4�uS������Yɍ���P��l�DǍOX^|����ճ�71f�5��z{��0��i��@��!�Na��Y�x*T�\ͥ�+N4	r��)���� �!�j$�7���wϚD��*�%�W��՜ݑKz��:��!�������(.%����ט4I/�P����{@�H"�w��'(e�V ;4�䰙����G�'��o��,�`
5�Q ���Mb2����O	�M��Z ���op�^�NV��D$��	�my#���N��8�-�Gb��j:��$�P��kx��^��-	pw�D������Q_X>%ٺ�ӁU�؁2�T�v�A���+��h�.���>#eֿ��s�RZq�VJ�La�&[��^���_�}�6�՞(و���Xg�/0]oO�(z���kۋG║v�L��ZO��   �ܐ�V ����8ϊ��g�    YZ