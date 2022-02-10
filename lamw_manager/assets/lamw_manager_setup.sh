#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3086488559"
MD5="0f16efc5c4c5e0ea54963ce44a262b27"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25868"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Thu Feb 10 16:25:06 -03 2022
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X���d�] �}��1Dd]����P�t�D��f*�JK����@�zs��Q��zv��D�ꃽ�� &��������/^��3�Dd��*�sm׀-Q���0n�.^o�&�7�N�<���U�"�D��j	g����)�Z�͚3(��R�+$*C��G�vQ�[��mn
F8�Ѵo���BY#��̖��1�9=GH5>�E�|�����lQ�v�A�ۋ�	��N{ͻݤ1;�HĘ6H` $Y���_�_P5���|�͚�7t�(쩞_<��4 ��� /[��R]ˬ2��:@[�xN~�>�yŜ��2�(�@Tf�������,Ώտ8cJhz O�#�TB��)�0�7B�W�B7����zr4���;y��&!/�����(tj�{\���,<	�&9��=�ޗ��/�9����W���hA�k=����:Q�Ƃ��uhJ���s9�]Q 2� �L�ReF���M
������R���8��[ٹ��Q/�P`vq������x򝁼l��:"?�cCR����s������ԘS__�$��Ϡ�+q�%��?PY�R��>>͟3��2�ӟHL�X��Е�QU{'��Kf�h���z�H@	n+K`�A\L�������X%��B�Ť�5��d� L~�Mj�po��������L-���E������N7"���{͗B=� �����Q�I��0�s�?d���>���g7�C����9���X�4��	,�b�2�p0ܛ�l�n�'�l�������-�G`/7��3Tox�K@RL��7��ͼ���Ǩ��ͼ�'��A 6 �^���:�&��d�k�__���%=S�n69�pۦn�7b=���)6�3�3�xH�����W��zT�(��3<6A���&)���0��i�g����`a�C��*�ܖ]\S�߲�Ģ�Z"��)���tJ�j��lO��'�g��lU���9U����u�h�E�ғ£��HO.�$V�����v�;�<iǽbxۋ<{_VPb��{_�k��N��O��=^J��U�A�|�}٭�"U���h(~��_z;��^�A�Pұ�'Q<��鼌<�v2w�������J�`kIq=���p�d�h�Lv��i�o��&�@ W�g�Tg�1QQ�}���R�-+P?���<����|��֎J�t��v(PGȎoV��C݈4��R�1�M�b
fﯥ6��$2d���>L8��#�HoŴ��0�dq���?�I\3DE����L/�&���y�������y�s0���̲�(޺�\��+n�Fi�=�ꡎ��%jך�k��&=rc�	RQa��]K����coM���7ߏΠ)Z�,z˾���N���sͷ������*;��"cw��%P�3ѿ����o�t����o��ѿSN���q��-|�n�O�r�Q�q{Β0A�?q�����,.ekދ>�TM� ��@6�̚��
1�*�	Aeҭ"� ���Xi�ܠڲ��M��_���~a(mȦ�K�;o6|�f˗
^���;�!T�c�5����H� �֜y��]��6��(o@t��=�g?1�^�e�@�i'#K��Z7Y��|��V1/r&�¹G��=u�,�͜к|���Y�P �+'�֘[DM.�E�!�,�>q$ԗG�1��D�9X�w�AO�؆W}�K�M�w ��g���6�K��7^�	�#ݦw������V�>�b�\���֐��e���d 4��Uߑ���'����j� p���@�������q/2���F'ȳO���h�<ݺ��y��z��w�X�� 2��I�r���z��۔����M��S�u�=B��"���P���-��zE3��� B�^o>��v%K����+�'�VmUexZ��X~�N�h͐/i�Y-t?Ew|���;�c�2n?[[�eZ�jm\���9"����|���"�������E�h0i���!m3��袛�ľ�?Ҵ�y|��}�a^�C�*#mk
�n��zb��0��7,z.�T��C�Cҹ���˶��E.	(���Hc�@_Uic�4�q~򡾂.�a$�Yg���D�?�o�g�V���~"�(2(d*��-�u�ߠ.���~��M].�*�*��Ҕ9n�.����`��L�fRT���He���nZ>�]P@�r�z�W�UwVˍ����0�1�-=�e��+��-��@�\֏	�y*Ҏʮ]u�<%�i�Е�~�b�YVX_�쁹o���~��w|�o�"�6ŀ�W�"����4ka#�'�A�~�nA'+"��Oy����v=	&���Ve�1��ꐋ�W�16����h�Q��e��]�� n@[G��֞B3�O�{���P�_�v��l�Pdv�L�)��
�����nS&"O,��Gb )wN5�ͤ�m�fvS����R��QQ/5��e�w��
�J֢���ʚ6���yh;����]��㚱�p�l+���bErn��������d��w9;��h��V疮\DU���&��� /�W{��������o����f��M�]��~_�W5xñ�0�C�ҒT/���ˑ��k|O*��9��X7|$~���r��j�-q*'�P�_#�"H:l����Ue��|d쪔$�(��u���5蕵�a&��½���H{+0&��'�ǱW�ѕ���~�boDA�l�SlR�/���۲�U�>*���=��mQ@��>�i�n��(9�`ͽԪ@+�����
��p(9Y92[��4���Y"9d0
�\�D�����w3�յ��2g������ ��A��!��	�8y��z̵@���� ������i�4�J+�xc���&7	y��la2�]�,Jjh��6��®�=��,��P��v��m9�07u�eEC�U;"����7�?[�f"|�N9'~	���C����5X��@�]���������z��ӕ��*��2�C-�n&Z���9�y5����`���$S�
�:��'NI��� ��e��ъ �#a��y���H�4_� ��t��7h9}����š,�a�sW�S������7��*2�����!���=�k���>hr���q;����*����05���<��9^����VX�Șsǁ��Y���li=1�sR���@ ��\�	�c�b��>U�;�p�C��ŝ�O\+�F�ZCR��Q�,r�?���Y�Y���� ������a3������3���ѭ)����'��t �,�wg�aN�BkQ/'�+�J+ۚC{~]J�+�9_>�N�֡n�|�Ky^��<^���YQ����:[i)0�k�2vGm��H��2SW&s�v+�n�˃���1V諞�)��_'�7�bn�<BX,%hPG��t����[{����Sb�!���(�c�0�Z�Z�������+�B�nn�k�����C��^�e���*��>s��^��p�n!���} ���u�>4?�b�(ab�*�!��y��������,[�iG�f��E�E!�_��2,N�pW=��Rc ,�~T�R\uU��v�i���V_��6��|���Np�~��t�r���8�J%oad��_��AT/K���G�[��2�y���up�y���V4����f��s�O���t��^U�K.*t|�����t�����ݽ��b��[.�Ѳ�_O�)zh�-"A���*Rʤ[�e`�*�t'򤺗6�u��gj>-k?٦��n½bX���Y#��'B���(���~�	(<��ϔ�M�[�!M��* V�F)��.{������N������V�|�@�ߛݒ俪�B';ƒ�&��c��Wêv9x���fx���C������G�aȼ#G�q(]��h/�/������J(�����-�_4�=]���|)�����T��Fv�a���t��&_5��U�ꠖ%�șrB��C��_��yB��z�}W���jC�՞��wG�+�\�v���W�L��5�y�+l5�>y����.��Bh�g��������y��,�~Y�ɪ���we)��0M�`�_�B��>�Z&ׂ�N���{�c�^�9fl���3å�c��t�	�w����DToE76���J��? X0�>�/
��C��YJ��EA!��t<<3@��_��S��
��v�������!�`�߰�.5�"*�m$vLj�}����-���p��M�˸���P2_�(�yW��9�F�,�p�����g�#��1��ԫ�I��/�ʿ8��z~NK7���&5	�來%1ʩ����V�\��5��W:��3G�S@��/x�V�� η���_��Å�g�K�l�r��Qa䴒�O��_Ց��M��:
�H����˅�9:���Saۂ&`\�����h����GE%�RH��D�^���y6J��y�3����d*���F>�k���b���~)��!���cS��y�󄀹�}t�����Lhu�GR��b�������IBI_TSJ��H��Li�h焇m�@�85�"G�ny���p��/r��y�\�B��TLR2!�ťJf�R�"�����f��9�nJ��7��8�ػxjU]��nU�/]�����O6~iSm�M�JCR��t, �{����λ���$T8v�������<Ѧy%NƇ�Re�
?*aD���R��)!�n&�#������&�7V�r���^Š�X����9:����k���Q&p��Y_�>m��76�G��t�-M����7m�����EM1����sK]U�QMa�������k*No�>V-�Xo>_�;�F�=j�����x��^=�m	���'�&d�e{��S��#�a c�W �LPˈ�S|<���^�a�I�;>�����(R��Ag`�x�5	D!���rGЪYVX+�J��:]ߜ8'
X�ȸ�B�0�1_v�����
#n�O Ꮮc���"��z�����sX�6����g��78��6��� ���������酉TCb~�#1�/Lkx#�y�Ug�n/�bNI� s�q_4g������t��?��".B.�'�f�ؿ	^N�ۏ�\�./�9|��m��ud���Ob�9�o2Yw�W��B^)8��t�ҽ����s��$|XᏌor9M���]�������Mf�\��]��G�r�R�ȕ���k=>$B�㤎��M?��*b}��O`Y�x#���4��?0����BG��w���=��H���^ނ˵��s$r���b�j�A���QW�K������	CԐ��(��F�_�~����Pr�!׳pk��c�e���#:�� ��JL�����������S5~�g�*�-�D!ç�n����7b�?�ff6z8��E�3�9zB��gK��]���)V���k;�
\��Þ�E�A[e��Υ
�/zD�w(��4��\9���P�T�"��ֆ�*��;d��&��TF��p���"f�I�C%�����ʔ� ���CE9>)�Jl�����}I�ϭ��"���zŽ!��E]}x&��(�-~ߎ�L�ɤ�>�j�̔���	��[���Vx*�`У��w>��@�z8��� Ⓤ=��~�HZ�_�a��N$���'Q��7���j�s:��D�8�;��.H��C��)b�@p��P���(�%�2���:��k��p��sW㑈/ *�ki���SAēOSY�S�<E��l��3HC�>�⑦v"$	�e5�	1���9~7��pk�0j$�;1�u����!���:�ԝp��4�P�Y`#l���G�[�� D>:�ݪ�a�w���s�_N�"4�G�൝^g3��zb�]&m�U�jY�e'�򞁶!����{�ƫ	 ��l�%�[�<7/pC�Oa���޲�
��\J��$Ө��_�V�`>�	�r�E�e`�s]6՜��y�ѭZN��X�������ڦm.s~��Pơ�[|��o l�,��@�սNݹ�-7r��ٮ�ֶP��r��f�� ��Pj��u���t�{�Uk��k�6�1�:�����j2;��q�ȑI�'�%WS��*���S�j�*24��[7���Q+v+���WUcN�2���H@�ŵ^@�����&�D�ɽ4�[��B&.��v�H�Z�c�O�5m���o�i�Vg��i�<�/�wݡ]}��8�tOZ���@����(�@�1A��sm d��kE�wod�wʽ��)=���d�^]���GS���!Z8�f���݋ �dm�J�"ZĬu����+�ە[NY6Q����3J������#������w���Bl��C�ŎAT��h��R����"%e��n�?sJw�{٘�"N������91�w��<��p=��2�h�tc�
��T�
��#�!4��yIR鉽\9uUZ,S�Ɖ�d�sݕ�,� jek�/��8y%iݾw����fa%2yT�����J#Ɉ��%�,���؁������MhB 9}�9P��F��Bd2>慢��K�R��2�:ub�30�^	�{u��J_���0
���Z��ri�1��Ϭ�����h�x2�����3*��f��Dh5h@-�b�k�j5%^��L��� ʱj��F�tb��'c+щ(��}���'�uZ�Ɠ��@9��,}E��]�ϯV�]k�"֫�ӓ��K���,��7RY���p��S�kК�ONM�o���n=����,B�|$f:iG�;��ԜD)�+a˃ey.!?��hL.����W\:%1�(��Oee{�L|�^������385����W��I�s����m��s���)�^�&��w��iY����&\�:��)o�qlQU`��8�]��aIݸ<Q�A�{��~ö^]r������4��K�5G���%�������~����vT\� %�o�#Vz����Ĵ�j���)���o�S�k��U�&}P�un���y��;8pL~t�8K9��'º����G���]�Q�/0ҋ�~�<Η
!6��P�+ޢp��[=�e��ܨcT�����q+�Iџ���/�
��V����f�B����;c�W����v�|�KI��L��=�0E@R!���<����oʹ��-Ƈp�ilv��2�sҹ��	���up*b:!��+e	]{7�#�>���P%<b�Cʕ0X�W$هS��/읉���T����-�/�_5D���h=��=��g�K�,@QD/l��=�˴ET��#��Y#	�W9�`?\�C��Ώ}I�|�M�`�kǨ���������k�D�o$�z��A��p���/�`�]���� &�pAv �(j���)[����u*x�b����4��Q+��V�����7r���UiS+�O��勝a�V%��Iu	*)Ӂ��k?��?�C@�Y�6��[���n�t�,ù�����q	�:�b@�Y[�aK	ع���LHuK��0RӼ7�C�t���3�����Y�7o'��L��r�S�S�ǜW�^��s��Ÿ@�57��L*�����6L�7Qז�T%�읋z�������U3��Aۛ��a/�z��]�kC�;`C��tK�{}��a�V �l�F�u8��D�vn�1t���K�}S�u�Krt[��|wxoz`u��EN9��SV�F��րCI��
9"Z�N�~�a�/���$�3��6π1�J�l�0Ƒy��ogI�ԗ܅�1��c��Ѧ�X�H�e�0�'W�%������-=��~c[-MՁjw�Y$����L��`��]���˫!c����?宜��r0>h��j���O�\����0��CK�ij�mq�*����rQ*£��/���;ei���#ޟw ����H���f�.���q��� �c���l	@�$HB�RY��N��M� t���q��*��^���{;0r#���,b�
P��������y�$R̪ñMf�����Y�ƳX���h6�*y�my ����I��Ʀ����7BU�E0����ƃ�S�Ϳ��.����Kl֫�`�95��r�[�|bQ�+^Hslȱ�I��M�н�m+W7q�� Y�'�Yl���5������!>ȘŨ����*Y�⺪<�!䝖�v�,.���Y@!�"ܾ�E����'�pO�l�	�HF�#��$�xsB���*��N�}�3`k�"�A���4�D?�˕wSY����O����iل��/-����Hд�����[<y9�K!l�1�$L��
��4#m��s�/5�î(�}��z��^*�Q��k��r�D��$��a����׊r�0���Fn,��<"�${|)R����K&ӊ�!s���G:O �u+O63���K��s���B��%�h݈��'1WwN�Ι��ULӯ箋�2�����ڹ����P�4�,]dhaWh�T�t,
��29G������5�������w�[,;M|��a��_��;m�i�W�L�2^2�D�}�����(&O���^�vt�����9�j�1J7�!��(�vL��&uߝ_��'AY�|٤��C�j̰�Rm�:����_����WNȫ�W�5�hlxIȎ�.�}@��~�e�B�V��~V=M��m.�(=���4�/�v��8Q�0�o;��F���gC
#���u�e��Qۺ���4�-.�������f���~9\܅OӖ7���p0dE�����Ѩ4�=����0mT[���Y֝Z�6u_i'0�k@����n�%'^�4�̜S�s�$5��ĩ���9cR�/&�,H��J$�v���m��V�^���`	�
*����-r�4ϒ[�S�R7���S�A�I(��O��Q�̊���Q���(������L�XN�h�0~�u�:L_��uqW�\C�8,��9o����5#��GZ�8i)��h�'�t�ɶ}>A��+���c�ى�?��ls�4[ :(*�KH�!yS��O�K��
8d:N�_x� y4��ƍ'7��溷��R�ҿ���Х����Ϙ��?'f8;])��/�e֒��xgQ���4P7F�C`\�Ă�©�;"�q&3�~�N	�K�g>���}��=`�(yC��{���(fh�nΆ�ϛ*3�a�f��l%/��)s�T�˧��h"ژ�
���R��ˉ긮�W��<�eJO�iɻ�J���?77�EGL����*�W�{�fz������4M�`�Ӌͮ�)��I���`���iU�^����Q��RJ%:��d{�����d��yBp�f�C��9.V���O�el�{Ǖ�;Zk���eQ�nVC�?UF5���D�HA��������A5n�x	!l��_G���W3��\�<�۹��D�19�ޠ�48FagS<����p��m&�����{���|��Q[���^L<��ц�\�zi�vΚ�|K��rb���m�%8�a3�b�j��ؼt�U��V��;�M;���8>ꏣ��@	婿=F[n!�l	���h�[}�7'4���2���*�EI>%#(�|��}�hI*j�j��Mp�Z��O�6o�|�M{n�ƨPR���u٣Ӡ�?�@��@2����kAR�<n;g'O���WQ7i��Z)zˬ��/�!�ōrMBD��N@a��BAŁ�%�)��!V�lﰼ��Z�Po9�d����>�����*3��
����RN�ƒ���ـeRx���=�,�$B٦�����i��Ld���� ����}Gx.��
�*]�V�X�5�k c٫����e,{ƞB�] m7���	"_�X�{����v��į0���9�u����CKİ�k\��s	��@���S�W�s�f��;��BZ;��Ư1��
b*��`�!��:*��("�DD��H1�Ij�����{\Vc+�>��g��s���y��������K�Ʌ���d������xD""XG��^E��j��]�(��n$�QYd���a��?����6!�p;��=d>sO�q4�-�����7 ����[;�uS�9�.-�	u^�)�?׏�\�Bf<͆*����әJ��)qc��G���<��Ӣ}9,x�`%�[lǙn��N��1��yb3�<�+�}݅�2�=���-��}�aw�\��`Q��D���%s��j�3��W�2E��X]�U\�ŰK���u2`���1�/f��LN�w���Ҋ��SPI��=��	驋wL��ڟO�n���]��hI��>༰����;��Y`=XSO-�����(�V�� ��n�T%����f!�Y��Ɛ���_	Ax�،�H�{��?2�;7�D�n���ǽd_�$�s-ΆhA(˻�^��#׆_�h�\��}����0Rb3��Y�\�+��v�j���`[�m�_�d1uju����N�?����Vy�GXP�{�
E�PX^i���X׊�䎺PGT���O���(I,�1Y���E��J#��s-d�\��*���}���yZa�V�q��ݫ W�<w����Ck��pް�G����aw/f��K�|��I����ό#�ųx;,X�	�؄�6��<
����-�S�<�2A�.��J�rp��yL���6U��H��n��s{j͗)odO%b����S�i��/��e�����d6�x����,d�'i̞՛]a��k=��c�2@�g�^���BqgT��U�ID�e��t�/Pk���1�1� �?'��W���m;R�uB澖��ë�w�:b�'�1��Z��4�c�|9ĭ/XG�|At��@fe�Y��pC~<2�դN���M���kr�g�F�L�q�9 ƒ�_}�Eyxaэ���!Z��_�e���-�ٯ�����5�wC$��a��c޿�>��`;��Y�c��ڛ-�,�}��66
���yaGp��%��7���9M��7!?ߚ0f�:���ת�NN|��?b�>�H\�	��)Vr���W߫�~�|���7#��8��a����A� ���(�͐������fH�(����]a�g�G7�8����5��
����W��F�%
t[�z�xL�.kf�(�?�YHK����^ۇ^?�@e �ݶc�o��\K�\7u���%q�+���I"���n�/��n§�v�fm��|oA~��{�����$����yfX+:L��!��pd��}S�L��K�c���5K����dR���-EuUj`��W
�f�X[vy�` �>�V��V���ECYgm����_�6���[���h��Kx<�N��v;�t�X���$���QT����ߢ�C��w`2�i��� �v�hO"�f~}�۠~0ӻ�&t����w�d�-IM@���X�9��{QW`�Ǧ����x��n-?��*��7M�1�)�#��q��P8)��l����M��J%�`70:M���]v)PY ����2+fw�9ؾ63�P`��u�����,O!�y�K�����sq{I�	���c?��Tn��Au.V�+��A	�^V��̺K@�5�֓�5T�8
x��R�+�#���+H��݂�C����ࢣE��]0��Ѡ�C�9gL��p[���)/BO�m�榠�����#<������NC��@�N�7��/��ldV�ϥ���/�	 �VZLf
�YLʲ��4���Sz��Q~��̿��+U`�wN�2�?"%����J9&�!���3���R�V��w�&g����4t��ɥ�
qj9���l�/���<�
u�#��#�|)��n0 ��I���cd3��f�Y�������9��=3�m��(�A����e`ι���C�l�0|�0[b�l�ִ��ADܢ��I2M�U���:WWTA ��6qU%�K.�X���Kiit���g`QV��,���8��[�2
K���������y���p�-�^��2�-���?��e+�)i`eYh:@$���y!�� .�� �c�J�������2���i`��#����H^=d̴�
 �HR�[1�|�1�	�Դ�h��&��x���S���7g�C�4Y�Z�Χ�-X0�ƫ�>3�˱d��ԕ �!_K�Q� M�c�Hj���� ��`�cS$����<�@��c��5H�k�iR��BT�Up���dp�4�#�(������b���WS�`��}�"&��u�8�X�R�l�����5T�.���(ȧU��zwy�����)»��[�`,)�:�(�'���H���8�)bY����*3�oz@5�Dg����R�g"�f�E��fGF�R�*Z�ݩ=�~K���J92.;X6��e��9J�	na��z3.Y]zq|a�� 2���C$�O����H3$/5��<�Ox5��M!P_��&1Յ��Cbl��R�p+W]�)�9wz���l!�nב�D)�ivQW�>Q�5s�0�(%���`����8ܑ������~0>��K��	6�M|�k�A�a��;��ar��s������ �^bbK���=)�MV�>��|��x.a��Ӛ%l�2?�I*�.p]��YꛩD@>�88'j�4>�Rz:��-8�?��m�-q�$���h�����(=4ɒ�!���_O���?,�d��!#��s�#4aI����%+\U����j!V˱�dM(G�7��v
�����Ì��WY%�� *��i�}���O~C��In�s��z�TYZ�<U ���C�'~Ba�J+�I��j�\0��N~	�˝ih���k=�:ʸ�uSi�I����LN�-)B[�m��43x�`*d�٭"�'y�4�Ç	��& s�i�v��I�_���/�&p1��2u��}c���Cꙓ�f *�3�e<��>��Y	2"y&蛖/ ��v=���nf+�;d�X��H�BF x�hP�J�,~�`�0�ʷ�,��(��\L�O���A��������?�u��t�#|�]�a�T�.�\-�����(�����!ݐ�`�u��W�.�/�r�*:�����!�v&��R 5&� �N�
��?V&���>�}
����o3��dX�h(�����0�%-�����_d#��9<�\�l����R&�4�����a�kP���� �=������� "s��n�����ƛ������kP#)y^�%^Ӈ����Q�'�%ݤ�6ѻt�����z�+a�"^��2rU؄G�I�9:�#|.�V47�ь�:q$8�;��H3%��m�
eE�&�b��=���g�ɢfZO��F���ٞ�U]��rF�XxE���������[:����I3���TJLuG�,��c��	�?糷�6(�-��6���G����ѻ���:)��" [\�z�]��{���GMQ��ZT�2[u�D��6����I&���Ҁ��}�2��E	\uk���o2��|��_�c��t�N'��ր.����Ԝ��`�b��"�&䆸G��zEn
�l\% ]�R ;ϰ�O>�L]%���E3Ş��;w)��'M��55�qE�TNzߑ�
}M��rX�AL�/�|n8v#�i}CMh��#B`;%J[e!j_���E�ބ�I�O$F����v�	��$����}�G��܋��:q�;�_�~C�M��Kϰi�T`�z"��|y1�39�B=b�����"|�=���4�YV�A��|�4��������)�Kn7û���:jMTt�:uF΄�����_҄�����`�i+]r�s[SE�Ѥ��fr�j���h�kf9����ג"ŏ�VEYԮ�/�+���G[��Ȝ:�)�m#�����Wq9e�R�	~�r�e��4��b �^�^S���-w�8y�D���<g��8@8��:�H�;�]
�e����v�ʴ�?
^��;ɭ:�6B���XrS���  ��E��Us�����3�������UcK�&���^������'����G�_�<3<�I1��EF�)�v���*�-�����o!�a���'���m�b+Hɒ��Mv[Lgxc�6�����8{�*�q�x�,S���.�~�dܛ��9*M6��c�+M��adu�gm�*%�<�v��^�̭�����{l��:R�L��=�Mԝ����?bW�J���5��ER~._8к�����Fc��'׹fhM��.��46��R�̫�Ϣ����hy;sR^qݠ|�A�7/��_d�:P�z$]@���N�M1<�؜ٶ�9�'��Jp)�$�k`��LJA�2醰߮��%mەG�/f;��>��NH�n�3���;+拳��<�N�#�W�i��?"ڈ����[@UC�
�?K�N����p>?�;<�0ى�hb���yҋ���,"C��8��RLD�e)�*������*<�c����R=�Ac�w��Z
pG�"žOݛ��aOm�C�Ǐ��O9�^�4��h�1s9/Ӟ��)m�ӧ���\1]Aw��Y}Y��GsS��<�xP��.3rm�ߩ�,��p�]|��ߣ���7�yI�+��Sq�ZN>lڡ�m%�Y�F��Ch�޿�+���A��`G�u�l�@` ��S b{QX	CF��"��ZZZ �ʦ��Ne�H��kؔ[���M�<�)I�l�-a�)�{�
qE[�eb5�`+k�����(�F��=%@�*89�s%?�x���ЀV�M]�Ԧ]/����r
��K0�g���m��Zh �6砲(+� ��@�~��d��b�!�v8q�r������*�P�,ң�M��s��Vw:"�b_���E��7�.�U9��<���B�����]���Z�]@�,�U�Ԕ(w���J�ďj��St7���m�笽)��m	Lo��N*Eո��G5�TK�n*d��DOv���Y�z�K�(��c����Wih�MY���3�����Ëz�S�ԋ��EJ�@c�ʳh���Y�O,<���"E��0��F���;e\�v��4?�W�g_Q0��h�1�,bN��@ �������+@@�M�ܿ�z(����
#E�ׁ���b�8Ѻ�ro�[?;Y�@�et�l���t\��gI5�C����Wx�`��9���U��J��L�gE\��#�=�Xph�i�%��7����v�ݫ^�$<	�U|z03J&A:!,�VN��z#��$�І��\H���_�W+��0E�R��a�xՃkg����Ю44�p��{Kz��|%ˁ<62�����p�Y���_yܦX��F�v�~��d	S�Ă�1�8 �`9C�9��H��4�j�֬��j���]��˭���ò����Oxq-���ˍ��_�[4Is�Cr4o�tV͘����u1����y�Uca��ӸTݷ�jt���]iMi{�o�<U���Ȭ},֢���Ry�w�TcXv�T���^
j��#��D��̱� (�H�7`�ͻ�6v����~e?��o(:�L�| m�-����t��a����:a�٪y̙fL�i�(U�+uٓ�0	)�j�!U�r�9��GN�����t��m��ͯ�v��)�LùZ��b�D$��m����~��Ƒ]���A�F�$�5�lx��	�qD�^>ɑśw'��+�Zh��!�/0�̜g��'x�@ݺ�y�9ŉA~R)�`]U�ٷ�_C�n��e���K��׳���m��k>_>�(���v8+��t<|;���س����Ht��A������2��k��k.ѿ �,���X�X��ò�<v8oT�(��|a�IB�/��iM��Ş�5�$:�	~Jc�A�Ǥ/�W�Ҡ�DDҊ���-��bKY�|�XC�F)�D���z�SH+P`��(�љsR����f'B�2B��,�2g��ZȃN��\d�a5��3e]�)�BI�N�W�d��@~�l3D@~�KQ>�g��t��ճ�ʴ��n:ar~~�}��8�O_h� o�������{��P1j^XÀ����&�2|-����)?� �ݗ;P�1��P�k��� ��ѠNP'�T�Ӎo�P���H�R0�����:�u�&���B��&B�p�|�]��Er�
93��yJ��*i�
X3��lآ���;���2�i*����i6�Bo5���N�>)�J$�QL��rKB/�]j�����.���5\�N��j,��H�g���>,ë������a�J�0,侠nCoj匪�d��A3�������T��;/��F �Mr�
/�a�3tiNĲ�c�x}�0$�*hJ��2��\P��@Ea�TO]�f��p8U	��$�L�9,��q�����/ț���C}���V�VO3e�4B0}Vŧ8 ��u#[,߇�"H"p�5��ag��N�B��DW��|������q�Ϝ	n�>�C@Լ?��g��A�?��P(�cd�Z�r!c�je�:�R����N�^6����q~�	k~duDwѮ)7b*O�q)Z��\m��P�!�Q�E�����uo�\�Bm�*e�w$ f�XԔ<޷s�.~'鮄�[Զ��HRM��2�E�(dd�{��=T�l4�ImU{��d��T�D �Q��k���kG?�Hx�h�]����qJ�Jo	R�����*������YJ�����p2!��F���[�-�=��@�!7��-/}(�Mv���`��?�ʗC��}H{�C�J�d/���.�{K���eDq�X
 M4���o���(z��(O�� m��X��b��+��4���[Е� �<�v�k}�bط����fގ�n�J�X{����7�Ԅ`�nH;u�D��x�y��z���^媉W�u��v:��N@�0�=Pp�-�V�M��S�5I8�͜W��.z�\L��"4�C�w{��ڂ�V?}� ����} j��(5I���u��yz�H��S�/g{���L�0>�d��� Lˇk��6~����B���;�m�N�㡗�MF�ֿ����<CR���B�������_u�-{yD��x�|�����֪��q�*��O�t�|��Y��c�w��;e�Ո��~�/�YzL��F�"G��N��Ii��ھ�H�d��N:H�({��R�l-�c�MD��">�F�Ф^�m=޽u��ˍ%Y����C9nh2:��{�5xU �ִ��
��eez/���إҖ�TA<�sѩ����6=�E
�?1C���V��V�%��� ��A��5��6po��~���|?��5+���v��ᘋ�:s��G:�t��5p-}ƴKp�� yP���Oz��f|���C0dz��Z��Ǹ�J���2���Ƶ�>J�OոT��9�M��f��ȓ�X�_ۺm�~پ�|i��V���(��郆��o�(�]L���0Њ�B��l��#�Rۂ |iasļrj毾�R����o�V�t���'l��N�u�����|2�D+kE�NB���|�Q��Jv��F<�d�ǹ���{g������� �nw=�r�~���($5Z�Zdѣ��?��- �ɩ϶����Q�����i}�I��	f�*��1� ��
����ۜ>F�r ֪�h0ft�*��U�P��!ܔ \�޶��$�H1�@r�dr��\���J��?|w����<t����J%'�.G��qD���0N�:P<��h�A�r�Qg�<	�U�X76:c��<�"�O�F��CI���@K�wB\8$�r�pXS%��]}UN���;pwċ_�;�n��Z���:���N�� V��2m��#S��KR��w@q�Id�YA�����r9dY��x�^</6�{���d�"��|�*�.� �qH��/��"F �d��\���(/o���1��ly�$1���[����ޜ:�PCj�Х����L|������ɾ�K��A��|������^<oW��ѐ�~��O��~��tb�y����*ř:�R�	x\r*I:j�#�c�����'���W^�\~�\&0��ev�:-�RR%w/�g����y��ЈD�����xT�������#�U� ���R������b|�����O�Y�곲��I���5ϗh6���l����� �]'U��j��(O��u��G�&(r�l�g-��OE�Z���=���N�p��
,���l����=E ��!��n=�+dk�}�$�}y�uN� �� H��(\�	b���9w��2�)�8P��H��A������{����
=��9��C�?o����~� ��I������[r�� �����i��H/c#|��$a£\�Z�`G����`84�],3^l�ܪ�Vy�E��O,Q�&¬��[���-�1��Q�\@�})��1u�
��L�k�S��_냉�EץM�w�z���+ v���ڨ��x��.kr���T巧S5=�s�S�&w4��3�'��- �aQ<��uW�����q�;L����Ў%���g6���H���r��S��r��,�|�R���i��(�P�692PAPl�ţ����ҧ L��RX�<D���n���q[�q�6�	wR�M%��B��^�KP��x�G�\��F�7��D����%�
��R�������'=s���tTQ���$������3�d���7�Bhҵ^�91�Ǹ���K`�ަ,����,F�<~�}!�Rg��β"��~����*�6X���O�x���R"-Ԑ�I�1�8� O�.+Q�h�;����d\�w���{� O8�E��}� �y���V&����+��p�d�0�Ūi��J��H �Mg5��,���g{�%�, k(��j�Dl�Z���j�(���R���0>�RQ(Ҝ�Kh�ޜ��\mX��a�(�x����$Z�|4�X��z�������ҋ,,�(����E��l��E\��?��D����cz;.��mr�����i;�*ڕ��T�X�HudZ}1�Iǧٳ���X\���n��"����ںŪ⨦A�0�[�i9�����d:1��RMJ�Z=<*�(��0F�ϑ����;�6!��&����~�X~����.C�+]>�Wȥ����8�ZcL)��gZO�[���,HN��aW�J��5|z/���r�VO@>K���]�v��N_H)©"'�ܼ�^)�96�?-@t�Z�Q�|d�CHbb8���$�K6�Tʕͼ�o.���*�#��9�����f �����.�~@�u?��	��<	�,�0�J��^��d��WZ��wZ|$zA�c���+D�+S[��.��anr8_��2|��C�b|#�-͚H'dO�MW����N�h�胪�&d���9�7v|�\�3��7�D���g�6�VU�KQ^H�l�o8��+��^����ۜ$4&�����%;�� ��

:�_
b,h�!R���u�Jϳ��u�hfvJ�+�_�&sb�|^)�Rm:
�&��_ߑ?%I�|�:��&K��B\�q���"K���[�6���i��
R��ƍ�ƻb](Et�TKY�Y�s�`����fO���IO��5��E�4�XԬC��Vx�͸"�G2�2�$F�R�#�O�����sT�
���/:��%��W^+9� ��7��]�U\%�N2�ȏ5����s��Ge�:-���-�w,�\?� ,� �Si�q�m�d�7���'�?@����7X�_�cb��sCk����5%u/r2t?-�R�a��+syc�w/����}t>�L*�Y�I�oj�69�����)xv���+�~�ݔ��ko"Z�ZV�s%�?�.^��g�<����!���� /��a��ޯ�n"����p�[n�M�⤥�����[�Qd2�ũ{�مN�V�[g��|)d��r/���7Z~ɍ���5GU�)��*�s}/'ՕS�E]z�p�����R��ו�8bzQ�Sq�P/�߈o���C1=���Ȉ�������
����_�8o�u��u�e�6w�����@\~��Q�Ԝq{�DIX�m�z1�s<<>�d:o} �<���U�z6�D+i�ey^��h����=a��aT��v�hZ�0Jђ��Ѣ���@ˈ����f:Ț5!���\PCx#_�V�C���M��TL5�J�'�ₒ �������S����p���=}q`����V��y�j�#��d�<��Ͳ&i� 02���ฎN)s��:�����BN��^�}w�X��;b ��ǂ��,g�m�������g�l^]o�z��R٤!��
�2mы�Ǹwn�օt����5I��x��'�����^X�S}@�A�������,����h����eb�t?�g��q����_r�˧ތ7��,Vrh�^��O�����5#V=O��Wa�]��L�mt��v����ɍSؓ+t�t�8FB�.z��p"�^�{����f�<����/ث��>�a��9�7���|8v����6� ��T�<B-v��܎ߝtKJ��n,�`ǶVK��$�C���Lخ�la���x�`�*���$@��C�n�d���J�y�)g��At�p���{qF�<g,^6�aE��҆OX�С�3�HO,0�i(l��_a�r)�`�1�'DP�w�~�Ai�(�g��۩>��,Jp���vTfCn������_�ww@��.K�
��y7b�7�E���P(g�o�1�:�<S�ŭ�� 
 ��������B�)T�*�P����������3��C�VAU�ƴ�z�$�6�����D�ed���T��j��=��J��������Z>Ņw5硔s��[�@ӕ,?�)k��"�`�Y������Um��$b�7T�S���r!+���f	T���8�[)Lu�f����&�$��.vC���8Vx�s�za:���?�ꜱ��5���U��% �V�[ ���'�j�~�����çY^QH���E��m�������ަd젡~��([q<L����l�&��'�Q�H�H���<��}nݩ/x歶���%�V�] �Eѧc�T�an4J���i�1�X�NH��u�ٛ:�����T���e��n����m�����t��;�{�?Wm`2E�P�����zE�^X��l�fd��%-�u��>�e�9��	F^�����c	�`q�/U��̙Q�b[�	�k-Rµ��/��[�e�=���kx��~�w���DYI�픒����#v>��E0�����KP�)�����������
���+f��(ᒌ5p�r�^�n#>�(`��P���p�P��fD�$�rDk862��HIM�OG����?���m�q<c�.�rK��<���ր,݂�~w�n��[o���_)��F�VʝYfd�G�й7��\T�9.Y��r"/7������{V�4��l$}q�/���zd�!>��;����4���>��L� g��� ������ x��������Bg:�5�*�/�%�ѧ��p�uB%��,39̂��Ƙ�o�M'��w���]��}�{P�=��1]3���]�����{U��h���`A��ҡ�� ��FI��"�$��.�e8�/���(m뉘�N� �3�pg�e;�!�M����z�aϵ�u!(`�j(����;z7B��`(',\����E�v��2�`�Ȩٱ�xB\�ur�+�Ѭ�-��Ò3gX��>�0��?��0�3���z/���µ(��#�C�n��d��je"��hpcxL�����H+V������\��@�����zj=Ҩ�[p�ȩ����pd�wG��$E����bW���cq���帰[�cИ$�o{��P���t�sg	�_[�j�e��!0����^_0�"F �s0r�ե Ϳ[b<�x'/���x�~/���H~���%�H�	�}�;�	PN=un!"�8j��5���0�^=Ҭ>�3t��c�ulod
��A45B�ڙ ���1i�Y�>�`	Fȏ�@�_��������wO%��;�������� 4I8O� .ЊCw�
A mB���k��ˠ��F��|���7W���V#m�a�_�x��R[\�˯=.���9<!�w9�b�a��ox���v��n�{5/	�#Ǻ�'m@ʜp\`8q�v�*���UhX�:b��]����&��t6�R�7ntO�����߬�72xڰ�S�!re�0�1�H0�^Q�~����xj����g�%��-I��Hd�M�lz�=��o\h/���$�jU�����ޖ��e`N�LY�:��g������d�bO��P(��a3���4˴�͝��2���.bS���5}�w�9�>{���!v?v��93�I�P�I�kE�������E��(^	aBr��H�s�3�h�Dq�*��X��%|��)���<�DW홳��ر���ֹ�sG�=[�t������8�u*�{��kB�DEf7����55{\��oD�X��Qp�m��ِJ�?�V��L�U��� 6N�Pu����-��&��%�k?}��߄�JD9 ��eO��c�zY��NOԲr���[a��y�m���f�;#X��t:�A�_�L(7�cڳxE���RҜ�8�o��D� l�ט���b�7=����Է2�z�(�s ̓ge]-��IN�*B[�IC|a�x���1+�e_��x�fz����"�}�ř����=��^��d�S��vI_;ݨ�F;�={��|���6� nG�g0�Em��('��&����c���ā��u�2׭�.� ��!;�m�3}K�1u���!l��ǚ���ĢA�^�Ho�ct�+�Vۼ��U��юP�I,hq���a��OW����<Xj��ֳ��8*l a?�_ܮRH���"Võ�_I���P��7Wv�٨��Oψ�,��@��e�<[nW��8�L�㌠RPb��.mI��͝�?�P/{����:��X=��Sf�oX��YZY2ᦵ��(Pm4;�պ˻���ޛ� +�#7��6�{��3tX9++w9������.����KU1���~r�^P.gb���@�V�y��+&�ܭ)�B���	�z��O�5��f`���U��e�����J���^���ݯ�m+M-��4c�;�q�K\~J|9��m=�V�V9ؓ/���Qdq��C��	6/V#�z����eQ��}zm�OZ@����M�޵C�y[V���֘K}V-���;��}`Mq� �1�q�,I��ẑvo�E����7��]#b�!�'�m"L�HDąWN+��[�M��+����BTn ���*��T�P_Y]@�,���Mb������(8V.��3�J��S����s��!�aTd�~mn7�;I�b1�Ff���>�e�_�vl
�[�Z�p/�B~��K��-�lA���t�V	�r��U��G[���OV�:���'�X�>F߅�˙'�f�نa�-ʮ�,��"�����|�bV���j�ϼc�c��;�Qe}�����ci�g�O�!1�m��>PV���&(�9� ���[�g3dgɘ���E1H|!L��	�x�����Č%���(�O9hE�l�
)�h,��)��?�ͯBI��wH^?��K{1���8��Z�s�`v�Y�֙ ~d �@�,t��� ���ж��?�No���"k�Y�����N}	h�3=Ha��9w_fD/L�l�6P�>�oʑ����:���^h�Q=�����$ű���1*NM�Io��Kt���5)�y�9|�l�06^��HX�c��P)L];J�2�{#�\3|�8^�oT����Ys(wG�?D���L97����"BT;g䑄�CU�Rr��>�!of� ������A3��/�>���b'�������T��?h�(;�2uN�Ejc�����H�\k�����&jC��y.bgA3�D�2��ݎ�Y8����l���p��+ێl]w����#��ǛM���q�w��bJ[����HŝcKC}IH��'��R��L:�zՎV�h�0G���$Aa����'3<���Dԛ(�d�?��4wR��Ā���I2 ^.��+��*��� p��GpHk'��N���iE����S����q�#�A�J+��7C:2���m���uK2� �f�� z*�]2�1���F��:�⧢|N+[�^J��`�Ր[e��%�['��Msb=�vN����j�ŭ�[��c��7�܂���T�14�歰�*i/1Ɍ*e=[�ܐ�h���A�n�뗕�G��z�.W�F{��!r�5��aꐆ��G�Gd54G��ZU_�D^�@Ï��cn�n����U=Ht�d�B.d�����K����b���u�9`��J/"��k���P�����16��^�b�ꛝO�ٜ�
X*��g��ѵ7CjǪ��^_��v9A�:' ��>	[y��/�b����hf���N�k��ȏ�Q��R9�ȋ.�i����
�X�ι�D�ht��	��ЎG`)%8Ü�b8�
�;y�7(�{�ӏ0I��~˷ym	�W��ۄv���ʼ4m�곶0gA�����JR:yH���6~
ݚ���FZD���>�'D�W��.���W��a�|�&��-&S�-�"���M/��%�膹<ԧ6���u���٩�?MFA�4��a�G����j��xT~�-nQ9zڟE_-}�,��I��(�a��#$6����F�&<��!/��+� H��ʔ��|9p���A��i#����
Z����]'��b0����3�W��_�q2�笒l?Q��f��	Qd�{|����s'i�'��DʲA�x�)D�?�d��Az쾫�im�i����h�7��"�3��g�5�'������i�ư�Z���K���D�%�2���,F�O�N往e|��x��}6�g$���M��@�㉊n���̚�^�	��ؓڛ�ʎ �t�:(�i�1��@���?��M��N3	8�"�����a8�<	�~�<�P���{^�;ҘE�7n�wH��˫��{e�xJK�A�*�3�&���ٺz��L� �ԉ/�����`ѝ�S R�K�ңR�,��*q�l���. ��_����V�/�W#�e��]�0�7HzYW?ً��q�;jq��:��J��a,r���Lu1<u�!�l����v�5,� �v�[^C���\ޖ+�&�?�-�bWR;m���1|����+��!��y��z�I����L\�NKTq��9� �ޓ�穏��0����I����c�g���BPIQ�#��]y����8�A{��qq�_7��<� dpu>F��U-�/4�j�`bPO�LTc�{G(2��p����[�lї��w�.�.�Y�5p�>&wlY����@g�R�Bb�-]���7�_�$H\|�KH+wq#odD�|����R9k6b�aYs�)f�T�|�LjR��X�J'��Q��w����ո�-vk�yw�t1�¯������V��s�/����.�����y���Iڒ�f�:f���m�&&�3M��o���.�N~�+�ӑ���߿$U�5D�}	�/u�j� ��"�1Wx2j��|��4�:2��ݶ������R�?��/	[}٘���������q�);�P��g Yb�!Ij��΃�п�}��Ҿ@2䔲&�������� �*�o/�D��0�i[�    ���R
�' �������G��g�    YZ