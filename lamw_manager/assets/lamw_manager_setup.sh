#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="499553623"
MD5="d1622e2f1d1ce92b70c3efbc270170fb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23264"
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
	echo Date of packaging: Wed Aug  4 05:20:29 -03 2021
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D��ﲇ�掅J�,?uI��1'���-�[MN�ud��G�*[�рy���OG��+8��?�Hr`|m����b��P��4��L=��8��+{�$ᤴS�P����}���t(KOc��{��.j��N����u�����|hK��ʛu��¦�'�V����G��֯����3�������֣#�wj$΅�y�mB:��� �����Z�[A�>��B�0%83Q�����Z�t;n���\_��b�ͮR�� ��S{�p�}*h�\�]��|�`�(bؒ�]�\5�r�*��pr�������7����H�z6�ʗ�}>��5��}ߴ�Kd���o�rI|^B�d*ز/��j������|��2^�}���6��5v���\͖<Wى:����u��oX�G<�NJb'j2{sU�gr[���V���0��Ӽ�l�-W��h;Z��%�-u|������I�ũae�J@5�_�T�m[&#��ޮ�t�/_�s�q��{G��F��-ƌO����1~G�ᘐ�T	.���p�5<��"�S�SºV�����[�˙
�]��-i����щOM|��
ƹZMf�u0l��X��"��z��a�[�@��-�s�B�ͤ�D-=.I։�喇Vw����#x��+������\�����rL�);�&����|m��;?�bıgi](W��{��^���E¯e�3�ij�Q�Ͽ���Գ����d��	[3ğ� H���-Ue衯�}�� ��~�wu�s�U�������h�W�����J�]ڔ��(�-ܯ�y�urB��w]��9�n���)0`�<~BϿ����mFv�����M�X
�̕�e�-�z��iC]����K�"��j���R�F[�:��u�eT�����.��ˡ/KK���jA����)5�>8,�UY�DhO:�ר���;���	��KDH��$�X��{�䛓e����������]�o��ŉ��+.�)�.�"z������s�}Y:5E3|�_֚����AF��HP��&Vl;[sTM��������`�P���R������������Ū�} �g�W��,{�@��Y�I�̻B��~�mh�#�������uEմ:�_l�"+��(�W?��;�%��&�s�	��>j>�AHF9vZu���L��?�L�	T�'ܨ���~xJ�!әƗ-�Z���zqq�gS5��?��$Q����~��
�}p���>�#���'d��(!��a]�(���� ��ݳ�`�gg���*�p����-��E,�2<��p*+����X������O`��H�� �[_���]z��E�_�9�ͥY��>.��ɢY��K!������3����Ĉ�Q3$�3k&v˶��,d�~�gQ������K��	r��s��P�al!�[���g];�D,��
�IΝ��3h�'�&��h�J�A9��M�ܜ���<���S7/=�ß�������A�4���>�䝿 ��`�ӛSF���!�C}��IR���HQ%�8�+��e?�;���w�լ��KU�JF��L�!P��&�(�k��@eF(v4����O��.�I֟��G7�+���z�O4~I�~����R�t�x �QO^�1R�
S�!�C�g1����A�K&��F�G�O��F�w�YW�x��v�N�7v��+d���x)���s"�4���sӲD����qd�
�Z��j�"A�����B�����Ƣ�D��w˻���fp�SЉ^�L�����e�鹎������ϥ�$M��
�
�ɥ(�o��PP`'��ڇ��y��&�0�� �#�\����h\Q�:�$�9�j����
�v͈���p��m�@�@e]UR~b����^Ō��+e>}X㓻�і �8ڳ(��~��1`��輞D�i#uK�>4N5�� b����4t瀮�g!���~�D��(���@������b�kl��O����gT��0�&l���֊_�b�G����!�*�g�8�đ�:Z���de<|}��.�!�V�K�_���䭀�WxS�9߅M �A���p	!�+q���z����#��,�a@Y�כ�Q��cZ^�S3*d��O��
=�(�	)(!�
o�Q�+��"��2�i�'Z���_Ls�F�_q���--�Up���^��	��`��3�eq�yy��	�9����G(u���u<�N��`���*�ԕ��߄��\��@�.�ѮZ�G	�Ԋ}FN�+_.�&R�.�)���G��I[�{m;�/4��hVh���1}x,{����\�ֹ4<2n���OL�7e}{���GR���xο�l�F��!=g��`�Ն%���K]��~�	8d=�>�[��0�e�&�xl�:r����t�� *��#	]h
��x`�Os�2-)�z�AXbO-2s�;��x�nAWP=p�K���t�R���1�&q�☙��]H���)]vvڥ�}5\�x��1��\� �Ԯ��o��Y��k=��=f��w�Z�E�Ov����<g���V�95M��˗�m�ڽ��O}|�4R;���ڈ��cVeJ�-�ֽ�~x�f��'Cc���ps�@C9,	zn��C������dP/�[�U���lqX���}� ?<U���n
��w�5n��B�
���;���X�>f�vMA�PEI{1 ��j��;bBAؠ�y����n�X��7���v�6\��GZ��j��WI���KQ�z0ZQx�뢬�V>K�8Y!\F�RQ���T� j@��u�{ph���za3�z��ɻ���:A�u�fƹ���,��E����R7<̠x�����̞�&��G�c��Ε�7M������~_2[�B¾_;�����,�W�O�f� ��A���Bû%�(�SO8����u��.��Z���ՏNʰ]xܿg�첹ԗ���b�~��c�zc WQHf�|��[tPߔ�Q��RYk����Җ�.Ma'�\t�Q��9������0!�O�+0R���`"���W{jj �x��,�ެ������\����� ���4��	�I�0�![�>�-ɁxY��c���Km<r-�
ٯ@EDG钞Z #�t)O�������Mm��N*�S�c��y���L{B4��� �ڣ+�4��7�l��>t�/��wY�el�\�>n-�<���1[�J�q2�����)��?�
IL�E�s&�V����ݢc%(��IV�iS�{�/P����)	7�k�k�W a�}�`�b;&{<C��,K�"�q=�՞5b��U��e�� 4&��,?�U-n�"�íI�6���S���T}49G8Dm5��	FR`�`] �����+�O;j������3�����>H	'����E����[����q����q������.��A��u��u�M��0��[�1Mz%�u���*�p��i�C�&�}9�ۯBf�2if���r��_6��T���)+��&�:O�	�ſ^�/�����C4������0�Nd3~���'i���Fdt)i[?�_��$��Y��U��F�����؝�W��_Q����a�{7ѡ	`�-Q풉G��΍k�A�9Cˍ�Ihj6�Id0��TXӷq��у���G�dC�sbnr����^'�S�G�1Ɂ��CY ��0 ��tle�۞�xi�`�^�y�8�<���<c�>x�r�z9��|}ʹϔs�򷷒,=ȿ�T4u5H.4��Y��ou���P�ޕm{����=�>��������+�e#�����L��K�����2>X�to'��yu��,p�[������{t?�')�,d&���.���\���$�f��G �}��fW�E ~^S" !�랁H�C'��B¾q� ��QÄE;�@�@�ڦ�ҵ��������m��������C븝��U���j��($6Rá��#��SP{uj��@�þ��&���(m&��H��{"~�8���m���W��1�	��υ�G6�V�qN����Te4��}��L����{ҷ����g���a>#4myfD��?�t�&�Q���FNL6�^jd��TPG.ֶ�ՙ�:��Һ5(�wIY��GDЎL1Tub�o�U�Ʌ̯?�6�d�$��ZKw����4GX��r�WJ.~���sԈf�3*�-oZ���%2�@�=���ۤ�zw,ƞ�����zMg�K�#��γ�H�K��&���M�/�6r?��7U�1�l�F�<�����f�������ʿuB�T�)8�������=@����k�!�@AM�g5��ތ:�Q��&��H��$�d�Iyϑ�bO�3p�m]�<�s�KȪ0顏��A"0�U�S��3�!�=�� dy��d�P�&�k��3uh����D�q�I��TZF����y��Z!��~>F�D�E{�E�y�g/��T��V*jF�Q�W���w�ޢP�:�u�u9&*�_��H$���R<:Kԉs�\=�2J�}{@-��@v�4I��Ƥms�T����G�;,���8m���V�І�Q�S�����n}���$��ta�>uV���y��\�?&mM��oz���b��ص�Q,0aMy�$����M��ZX�[�K��Ȏ���ՁY�̒�+T.��]�&��7�;����S�vd��z�v�#�AU��$�U�m��� ���vﭽ�
觝CF�F�w����i��3���o��f�>�Jp*zì�b������J?�e�{h�B�T�J��vX�b���c@��w��׼�OK��iKt���$N؈�}�&�TW
/��i7e��Y��N��TX��n��G���/��8�S��$�J��3�n�b��٤h�,tT�0��_k�\/d6~���!�ZoB��;�V:�n��Gu���8Д�kJZ�	���^��*�����#��� 9�_ݮ�"����*GW�#��;� :S����8�W��@ �-(>,ӹ�PN8���տ<e�������6�������a�IѳĒc,VpE-S�ؽh�f��{�L)��"D��5:���v��+T���Z&i�H5�Z!x��gŢ���t3Re7g�2��s��<����췈^Ȕ����9�Oo�g?���w���S�Y�Hv����ƳY�dqx�JA>9�UY�,Ɔ�%��A�w�{�-�Ҧ��X������1M���O}�|	��(M6�>�.���5���M���io1|�Z|t ~W��e�?�t�T�X��d�$����v�(��A޿b��̩j�ho�����ݺJ+F�wwrؙמc*�Nq��rv��.�K���,Ld��ʮ}�1zX���g�����$�~�`��[��M�JS,.���Ek$�� L�Dp�z��\��MO:�Rp����:qs�W~|Ja�n�l,�X���0	BOYWTtb��Zm�F("]:.�80�ɬX_)�  �p]q����`�Ǐ��	���s�ؒ_6R��
.���ü�p�*�Z��4m�5xb�q(�[ۙ|��������	\�}Ei�����dRm^�t����	���	�]D+�x����y���mA�*aP��n���hn5�����@3�2J�G�G^L��������vBc���U�cC�?A2x��+PT�bD�Bvq�΂�8h�X �<S�����yW��;�)Ѹ��_�"����k&P�5�qyI:��ƙ������D���MH��׊�=����I��i; �q�i6{UP��E�Qk�\�CL�	Q�љ�I�!`��dRt�N�A������RF�s�d@�=�*:�+��E�V>B��Q쨖���������N+)Kf\�V��.A�?)�9�����ZT���r8XP�Z	�^AIڻ���<Ų���Qai�5?��M���o�n���,�S��+{^���3(=[��dP������ϡ���p��L�[��1��iV>���0��Ë��'��묡���T�@�f����D��P�=G�p�B�|#B��<|z\`J� �u�\$�nwXq1�p$�i�M1 �8$��1����c6ȣ��K~���e�o������Fu*��5T�h�Npz��c�Ն\n�:=�S;��&9�藺�e�Q_<麙:@{��VrVQ��Q�l.n�_v�/:K!c��u^ 2 %c�F � }�"����?��>W]�f�&^J�X�S57
���VQ�*�R;�����a>m�6�S;��g@`@[�+&�a�<�J7ǣ�a�R�V���-�@��h��렟��
F?���&�CCS��_L���;^������m����(�Ch� b0�o5�`&zN�	
�
��ߤ���I2k��"�虔̮�c�f5�B�~|�g���cO����['��u�Ʋ���n`��I�`��p��4{R�m�9K�A��en��D�祃�=)g�;����jG��PZ��
�wH<L����\����&N�Ir_����UYź�D�sf� ���7Q�4�6?���jCI�G�La�Ud�����x4��A�NQ�S��U>����[w��§W��
������L���I{��މ�\��]@S{&ř���'�Tr�f6Dr����0�;�#ΚQ�4����c�Ԛ� x��[s7T�?&�FΦ��.�L�E��
��=6p�0##�@ur�3's.:������~��vv�6ڎK�ǥ�2\������ԯ�S�ر,�����v��F�	pb-���>(iN�[y#¨��#8{�l9��o-d��1H��
�[�N��I�l6[	���ۣT���EW�%���٧��>z����W���wP��B��s?|vjAཝ'��M���Bi����e#�殂6��a�u�p�{�[q����טim
N+�݇P!�Q��z��Ϳ��� J��ǹ�z�ZL~jz]Z��g��W	�f��q��[;����t�}��4�
0��;�,'��;4x>��v��/aX����n]�1��B�R�9�cﴫ�Yd�&��f4v��:�s��ZZ6�W�Py�l�����[�W�t�r$� ��æ����16��H	�}Q��㚴<H��M�p�c44�8v>V���R�G>���L��P���;�f"��ד���Aʧa��	��E�#�z�u�1��o�~~�K�:z)�5>mCMdޑ�>�s*⿎�c4@��'�T�=Fkd �_��Z��5?,�?2��_v��C�
9ȓʡS;�ΡV�4='â�&���4�]-�Ή�����!g-�& j��(��I�=���X����;z�B���(����{}h�B[7�  �ۂߐ����x��Q��������Ɲ�����R�~j�!o4�3o����8���(�r���HcմW��i��d��������B�Iq�=��G���e$�cJ˻;+�1�v��n;6_�s}���wT��7w�>VI�]���]A�����H/m⋗[;����!���>�Wnd;�?�^)Bw����v橄�"Vo���Q��k'�=���������q�?��p�K��	��ax�	�Cr����,�UY�|����:��_h��ue�3c�0���U\ɮ����\��or���IŹYӢʡ����%!�s�)b��Fݙ|U/��q˛1�ДK1?9N*e%���M���5?1�,:�Ω�.P�������E����������zF-aB�~Y��+�r%o�
��){`8
��&/�'�gը��WT�0xVr���@Ä&��#���J�=h��*�Y�߹^v�j4�ZS���d�:{z�$�:ZZ��\\e��
b"ǐ�l��Rfl�F�mY�؎�i�X%0rN��|k��fwT��2��O��Gn����Ib<[oF�u����n#��G�`9�*z�S��� ��f%�f�cP�V�~`��U�������>��aXr���׭������}-Ò׎e	�A�A)�I*�L�b�^�1𨤢A�U�uUg<�'t�b��/�,Ϥa>l)�R2�m�@,�bJ��)�Ӛ��Ƥӄ[��k��\A�3h����7Q=��=&,�~��39Ք��.5����'�?�6 ���z�՝;��|�T��96� ��#.o'�C����x@�3�Iw������U�UTT�?� �2�L�0ߗF3�~��={���� �e��b$߿ԕ��̘ӵ-� w}��p/���6cq�}ˡ@����
ӌ�3z���=�DdM�8H)��
�g���(5a_B����r�p"靲 g/hnIQ�i�95��'�U�t�IM�.3h�aJ��ϚգU{�J�v�%+DֽM2��(�����O�3cW�Ecu!'�P�3Y�;��h��'��C�X((��	
v��I$�z�t �[�GB綤��[ȯ6 q7��kZ�
@)��j�S�9w�>��ĮU�y�iz�>��yHK�h�m<���V�~LsE=^L4@��r����(��}����p7�һ�̂���%�#��P�:�d{��-�k����h�R߹~ݭ�	JH���<r�55��G�v�r����t�⦎&�'�������Lc�I������g��>��������n���M��W�
�،�K����;p�&����x��%�hJF`���]�p�Q�=<�҉��	�X6���)�|��-Q}�H4�$D��L��3�3;�S�< �rVP�*kD�3�5S�ۨ`�b���{�U����j9��T(���j	���<f�g���e��f�9�L(^��ɖ#����UR3vi�o�ҔEߊG���!����Z��v�gg��m,�a͏^��-ꌨ�"$ F�3���6k���:�Nᩭx&'R�t^��m֧@�����H�R÷��e�@�^��e�V���'Ƈ�&z�k�Q�Ol�ѭE�����CF�Ik��1!�����n3<}Ҝ� F(���=�c���ǓM��4�ŭl�D��h49�mݶ���8�H|�2Y!�iTH[�ٽR�}��7l�N��׽]��*+!T�z�F"��S�U�^�����y�L����-,�'�r�O��!;���3w�������%�x�Mi�3>��XiCPZJi@���G�w%b��f�eĄ�>�,�������c+8�O�A�Ƽ}�e@C�S"!�("�t�(��	{w���:����nU�R�B�'C����LI*�q	���n(E�@�4�Ii�\.Z%�B�z^�'��Ҕ��K�4�{�Oi1���S˹	L���+f�ä�c�v�>��Ga
2^����} 	5��(*b7�wa��V>�����0��"f_ﵷ�/G�MT��F�U[D�d�̢�l�F�<aƥ�D-b��Ҏ^����x/X��f�&`=ȔRT�
H�b�,����O��]/����✼\�'gYwBUAg�E��+7���CM
�M���))!d{^�����p4/F7%�aB�$��eW�A1�M��&|�N�A$>xŰE&a�*=�}�|PB��F��_�yI�z��{5��MEV���*�)���V�z�p!b��w�V�K�34��D��� ��Ι��[D1J���K��$��`�;���Թ��K���c�q[aq�yne�A��F�n�o�p���Sֈ㊛S�2n��}���愭6���H��y��P?�%H�n��B5��2������K�%Dw�X��v����P�}>�XA;9�Jʹ� ����35��nٍ���`:�o���D`ō��ʀ~W�����_S�{��R��:!*l�ǳ+}����:�Gs%FR.��?�)��ӵ�\ �̃]8��^�Z	�؛%�?)&Q���x�6���L.TH��s�ů�<>ZxSx٘d�!��1��<���zC#�y
i�\�ew��W��9$a����r�;�N�Tw����C�����*�9Hg�� '�fJ,/��E�ˇ�:�!��d��^:�	Z�d�����O'J�|0�`i,<��$,���q�$���	7Ĭ�t�SG\K>����	0i�0���A�M��-�]֊�����=��{���lEW1��n�a\�c�^�/��ނPX�Ot�3�r�@Rlja�ĸ���0s�}"�Rq������?Cse'B7�5D�pr�~�`l��\�FZliDh�后v|�L������r��T�p@d���l�D7��c��O��k����O�i��~Y� �#$�B��@Q~Ċ�R�u����7Џէ�6�}>�C^�ֿ=M�H��E�z���QڔJ�9`������s�n!��U�7jL'f�?8��zR���D�[�^�~>N'R������8�d+M�WFW�]�U�+�?ږ�j�6�O���e38�3�*c4B9�n&X
�����Ի���O�bǯJF�߮T�A����D?e0�H��y��j]C��+�s�����ev%��8:�F���_�v?�������)g��0���_=c�v�IrCF�Y�F�BJ�YJf�!,���Q��Q�X��Uw-���Z��%}*���\1E:r�N�梦eo��+��DW���R�4������~S�v��ke.�,&�6V��O`�N�}�u�TQ2�@��.0�5E\x�;c�c�[������F��s�l�i��ӉG��->p(4�X/�����"�f�e�ưG!�3<�5X�Q�kd�%O�����l���4���f%�7���������H�c�p4�݈I��[e���Ep�]������'tL���q1����ڍ�)"\,P�L��Msd�eE9���僅�Z�J}:�A��B�r�{�dM���2@k�S�ɻ�/�߷f���_�F�1��@�/pPt"��/16�ЦLg���D�vj
_t��|���~t�A���N��O�l(&��tl�Ǝ?���¥��<JmO5H����R�H#��r�����R9����_�)���qK��+4WEbc�xv�8���n�y~Y�C2�x*���3������l��N���$"�Og8�kr���� _N�?���9��v�� ��\su�/ ̘���:��h���$K��������.����jC�&�l����:!������D�42:e��KA�(܇w�Ň��kP�#r�/+�?ĉŁ�7�����8\��T�d���n=u&�� 3���ǈ�B�;�^Z�W����A�)U��un��yy��T���zb�`Ǳq�(|��g�H��#�;!zL1���	�I~�bd�+��h6F���jBZb�P�x%vN��[l��ӏ���3�Bh\�3�p��~��zЎ�R�����AI���A$���-����HN��!yh<���r���fnVy魄R�$��������ѯr7nS\z��o�C�٬�N���,4}f�D^K{�ޗըZ*����W�H~��p�⮸!E�S,;�[�k�����D�sDI)�B�:al�� HWO��.w�����Ыck,d�2�fg$Nhg�w�Ȫ�_�m��zML#2-�M^di����A�h�ս���uq�_P��r��=H����rb�շGMd�Ĺˊ�:�Z�)z��D(^�aC�|��A�}�$�	%a7�/�W�34���+oX�gqY�R�4 lzكba�+oa�
#�2�`8�M{�P`�8��� �z˖" (p|(1�T�H�%�s���+�9�8��O{'��Gܯe�3�u�!$]?�����P�8f��;)We@h-����� s����/ߪ�������Z��	g�@�A��R�/��ԆC�7ï��0�I�Y�d�>ڳX�Y�C��}G�(m����7�����A��.mf<0*���'VIr̹�-(;���v�
�����z�$so�(0�>�ϰ߇΋B��G6����۰�В��z���r��¢���[E�q"��T=T͆р��h6�ΰ���^�r4�_��Q4�Q�T���{k.a�UmJ������\�]�)&����,A�V�����V$��/Dh�18��݅	��5��o�xЅ2��^}��{�c*��z��,�~ ���t����0�gCBD`�\���*��J����y���S]d���g��c!�ͣŁp�dw�R��4�8��IH�m��s(ꆫ�&x��.7��8k���Sra���#�����IeW�qKϭG��mt�-��;lT�U���~��5	�Y���C)��O�����1X�a��m;�bGS݆U����y1<!����5:�[�#↱hmho��<}��uFx��z��U����>����}��Q��ז����1�b���k��NV��#8h�?"�/ؙ��&l���M�2	�E�7�W������}K���b��T��1��/c$����|�%�
�uOQ���1f�A9��3��Q��_X����%ދmj�|եx��)��{.�S�&S,� 4fGQ|��v�Mg�nM��҉���ɥv2� �E�,�]�EAWF�|W����B^�*�t�E -��TW�����۸��?gᗡ�S�9���E1��e����3�h�l�$�[��j5[�o�B?���3�V�L�&T�8��Q��\!D��,�=iO�F�CikTGL(����+�d;jlDN�}x��]�4�������9Z�a�)��m����
��D%�iӡV�n.�C���$H���،X���Yc�ܝ�YD��H���U^�G:�)~��ⅱ����t$.�XD�5�zM���n>`o/`��i�f#��[�A�T�?݌ ��bh��Q��E�Z�� ����N\ զ��4�~K��r+:�^�1�n.>>�e�g����&1w0�L��ov���yM��+��1��y^`�|�7/��P����3��<��<��q��Y������Iz3�?N��K#,{�M��E�1KB��^Z2y��P@����Cʎ�a)�N�R�ܮ��@��)�yn"�eӾYzp&���W)Q/��?�pJ-H�$���j�<i-���=7��� �PB�;��n��2M��)�Y+@��"Y����HB�t&o�O�g�X�(-ڊR�g��d�%$���:�aˆ붾kȲ�?��-?���["k�r����qϔdf��38�ڡI+�w�#cQ�]�T}�.p�]Ғ@��T�:5��'�g�z�%֨7e�,[qol�������������gѴ���9�C�@z	����4N(-VE��~~e��%�i�O�C�)���Ԏ�ԦY��k{�A�)�r G, ����G��
��R�c�,5�V�f�U7"�ڄ:1!	�k��I@C}V*+jÛ��2���Z$�n�n<�
yʲLg~��XZ��~8�q�WV
��e
N��1�/�B_;Z/P���kqu/�@�qCo6e$( ��?'q�_�	`Q�$z,���U7ƝJ����	��';��B��Au�f����� �A���n=��BgV�L_SfWv"��#Q1��ڐ����#v���"��������	/Cf׌�9P����*���Z�VC�=(��@��uE�'���l����VGD��]��3&;�~+��o�k�E[�D�g�aR{�Y��hfi�Ptx{H���
��qכ��l���!VkJ^a7〻U 	W-����iw�xoWq�����z<L�U���
��#;��W�˶ �R�փPw���Bp������A��c���by���ş��X���oN���H-��Tю���HtӦ���lω����wJK�w�)iO�]N�iS�P ��%��~���Y6��]D��N*.�ƿQ��Uً�����HHn��'�Խ@)�wd���@ORԷ7��؈Dx�ֶ�e����b����k.�o�p�R�iE�����G#G'�]M��E��t�ŵ2�X�����A�a���G�q� o���x�n�(�h� }��  ��iZx9hc��i�Bkb'�s�c�Ƹ����W��`�s�Vv��U�H	kVJ�Pٽs����X��g��T>v@�xjW��{���E�Bx����l�A:mU�.�q�roG�L�|l�&�;����%|�H%'�7�{���>�w��C�I��G��P\�0hC�pQիɴsPv�WD�ٝeβ�#��d�Y�.G~vH�?l��T�S���`T^�{I�����"(Zڦ��-��Ɠ�����$�~��p�C�����_az1�Zj��T�����ߣ3�﹗'�v����+�O���QٕnA��B� �1"dǳ_�M ]���]�7D��F�s�Р�ϓf��#RU�=�$����_|��T�q�F�o'���חAO"�υg$ҺxSrH���{��~NV�#���-Y�߶=�j�`�a�<����j$�i#��{���b�*
�Z��0�f�Ƿ�ͧ{�3��*�IfB�$5B���C-�~��%��-�pct5�c��Td�O�ϒx�Oo�A����_f���4� �!�� ����	R���j��X>>|��Z�X����4��B��V~-�CD��8�~�B�� �g�y�[��~tT����@�׃>+и���YDtuU��"���d�lOb���!����1"�G��@GD��ܵ��(�O���e����
{?������Ό��`=  �_�[���Q���� ܸ��bKu}#��S�Yk͎�rs6�]7q3I�2T��r�b�lC�_gh]�;�/���,y �Hx�2A��/Nɋ��Ę���t��K��a��aMX鸫r�/�5��4�.�}b���B�Ϥ9�B"��րKq�-�����+���y�C[D,i,[��ǥ��D��g���o��<�fx�E�9_H̢E*�D먗�e�+!2٤椪��-�o�~�*�5����jyK��ԫ|1$]��e݊��$ܚ�;P��֏k-�V�͒���7��?�|��A��T]g�u38;�N�6�
"vv�9��r�\ح��C��j�7�'W�,̾�cE�ߤ��Du�+6���I$��'�H�­8 ��&$�j��p̷�y#�S���*�&h�5�6��k�kpA�±vb��ڒ(���J�J�s��M�M?X��kŬ�M��]ڀL�Un�������ih���^SOT��QN�c�4Ө)F��3�^VV|UZ_:���Ƒ�4Max*.��HY���lѲ�m�	w	@��}iW�άD���%$��u����xy�B��U��n�2cG˶�*F�i\=H��z߮a���\������"t�H�R�k}�3���,��З`�!��8L�u�M/{��(D�i�KS:f\���K�я|�B���{0�6g����x[F�R�mʨe1��R�bC�S�� ���E���ޙ�^���A6�v��ۆ}l�}/ZT.r���_j�}��/)³�aL�$U�{�m�F^���"5�`s�(�O�lV����Bɏ!�|Q��5mX �B�r0�>���O��<G]�����2hG��!C�K�=�<�,���ۂs*=��
U&�G��%�/D'���!-ؓ�mp��P�D�\=o%�n)C�{�"�$�!;e�k�+K�D� �2�C�4������TL�(�6)�CnI
(l�|�;�X�{W��ބ���ԥ�,��M���-��V�bO-�"�Gq�a?��!����0�������3�.�,$�)���Ht}���=�㫾�rC�m=é4��8�w�bZT�!dS~�Ew�w�t��pg�\��� �3?r����]&I�ǅ�y1��HAE��ϐd�Y}��8ӆ�4ċۊ4��O�6��O� �ً�7�&��eE
��y��B��!e��kHĴ��`-��o�v�����?���4�f��U�|Tʇ��1p����$�:�x �
b��vW��_��Q�.��Y��.��6'W�����	L��Q!�~*��quSĖ��7)��4R��鏨����ܲ3��hf�C0�{B`�������`ˀkŮ!>sdZ��ե���ki(ZYp݀�'bv��+a
���%��m��'=SQyuIA�h��1����D~[�N�{�/�p�Ea�r��~By�����V)��յ"��n�B��K�Dj>yO��'��#�|V�g��GE}�����If��/*������#��TW�!U5��QH��3�4���I�ص������1Ћm\��v 񎫕F�W�X�o��L$P�ղ��oG�y�!C�>s��N��;��0�9a�������t=gcÎ��2�o�վ�`-��Y_T����F�9�Z�f���w�9_��}�	)���err)A�D��/���z7��=:���è��/�ެΐnFgչ�l(ͤ�*�p�΋όz���^��0oo���Ź��K�ڠ�2�yi�C
��j��g���_Bl�����ÿU�w�wQO�K3n���	q_����R@�5?,�K�^xNz=��4G��R��2��n޲�9V��~Gwԗ��[�D��(���!<M����״�
8 �f�s񊩌[��z�IL�����k��P������/C����킎E�D8��?Ҹ�@����s�U"WR#��R���	A>D�F��v0�Wl��v��.���g������x�"�U2��7���8�PL���x:��W'���p�Y8�l��.A�/�Z���N��
��"���|��Q��GIr�y�+j6H;��ÁAd���������]��)[
J��vG��?�-1g��u)��QD��M�Z�*��&�d�Y��#~ۿ{���ng*I�#m|�?r�����)���s�I�r������>�=So%�q��v�E{��Xb=Bq�w'�鹜��xݞ�p���$�x�'o�x��OL�*M��� ��l��MV�h||^�БZ����KR��7ɷ�S⁞h=�t�Љ�1!�Z2v{�V}(��P�=u�`?)�!t����*u���N����
�,��rg�h72 �A��'C�L�_8��46y��U(�w#��ۏ�eͼ���N�*уV�X�c0&�	_�y\8��&�H��w��h1>MDF��7�z�p?Z�z�sP"_�h	�-�>mu-+s�K�4�$"ή�	���j��3X�UP��p���_�e���.���;�Y���rR\Cyv��o��K㓌��'_	?���c�Zw��Ӎ�>�����3�����m4�"\ck H�Ys��Ѓn�GB�kV�8�3̚1��Rp�@?�� ��H5 ������	XD��o��䱁�4n���4W�V"S�:8�n�y��N��Y�]|�֧M��y:�|�\<�K�,'��<�-�Þ�w�ӛ��Q?d>,f�˕��	�cp�}��n��9K��z6�9��d����Zb�ukV��G���^*�Rr�i��PbOu�'�O�wZ�R��M%-J(�{������d*v�b�1�j¡��M������z�Qe����~'�褡v�o�O�6_�1�2����}�	N����'kqLP"dgj,;���A���ږ��qM{"
*�IA��R�b|qRut���.�'��a�־�E��<LQA^�1TS�]�:�j$^��E�RaV��G!c-��X���͈����w;�ue�.���8�;a1v���C����gR�)��5_�Os����^D�DV���b��|�r�e5�x���>K�+�s��Џ< 8=��,$"��t����1j����6гߥk���b���&��_~:��t��lb�ne��{��O~46�~FO����H�� �@:A���-�lu���΍3�.џ��W�j���'I�/�B�q��S�VT���Ȏ��7�ށ���h�J�	�g9!�o4�&m��¸��}VR�
-<9��J�ĸ�{�W5��,9�Jq�y��y	��[_z��^������ziJ����F�ʧE�M�Ai��^������_,N�K����F����äc�����m�vqL��A6�&����']A�|fF��B�`�ŽR�W�̦�3��;�����ID��(�/tR���[LX������s����!��[E�)���5u;�q*�1�M��M����QS�e0�+A�sZ@>E����J?��P���g�
��tKݤ{�����]D��a���v
@�+3����AHF
��
�:6qm����Ϊ�{�l�G.����)����7���	@��Sj'Q �zڏ��{f�2pR��G�	@��$R�.Ζ�]\���k%��sgH>���t�<���V\���Jk;�������9�(�
�i�*�
��x��̱��-d�qk���;�"�J��Ee���[�a�Z,?��M������++)/�*��;���ŞW�(g9E��i!�z����E~y�AM�*�B��9�Np<���" ���/a�����a�wC����������7mV��I �\��Wd�t�{qHE��0�Lgr��w<"Y�D�ӆ����L���EH�MB��<��l9n��C3�$�ꀂ�{�ՉDg;�f���n�&U�ڊӨ�Ȯ���bx��ه��Y���^#�2ܾ&	�ڋ���jD����L��n�M� ����E���g�a.�^S+Ee���!���l�� Ď�����޸d7r����F����]`v�q��6�*DsFO�!�9��G�@�{-3Ϛ��۸`���N«��C���L�׮�H	�d=���[)�R�T�����o�ZhH����za�b �zC�Y>�+�N�,}�B��Z�&o1����*��[��i(=�����rW��'��*����Y��3�#Rk**���Ň��I��^�/���̟U��k#r��y�&e�H��J���e,;�������Q�E%r��r�&�rџMfqʳ�P/������l&�c�f�2T��3�B=��"�#p�C.e<窼�;7��ā�����X����#*��)�{x�*��#��[i�h �َɥ<:�HH� ���7��kKP�{N;��Ya ���G�e=M�##E�$	�K:�M��0K�(��QU�E~K����dTA����>{
��)��k��w~�5�P��'���K�[m�>T@�Ѫa�)�ϋ�����]w���vn�R?M�@���}p��1�D	q#�{���~���~�ΞeE�2�őK��b
�= $߱iFay�˛aT�a��5CU�[p?��ݡ� /%����S���k��}+��/�����S�P,A�MY(��'3rr^}�ͼID
���p���%�W%�uD��h?|O�WH����c��n�˺�֥m�=w2��������'~�~�#�#Ps�L~4�6�nH���dm�P����˜�F�@�ŧ\�{H�̥��7zp�w�����0R�0�Y$���u�l�kB��1�3�B�º���;�n��|����\lZ �cGZ�X��@��vS��(Q���ye:�Y|2j�^���9��o��>v�X�M�ډt��6zo���!��i@��a]bȁ^
c���>t���U�5�����щ�e�N�z�Q���!	vt���,
DZ�y�:�����[���Ǩ�O���b᳘�J[�B��؝U�xz��ϵR^cv4�'��OʃБj�x���v����`�������[Dt�����%�M�o�![��H��t�%/� �6ɩ��ɭ�����"�z��[�a�d�T��	u�M�:YjF��e��gTN	eޙ�#��|vi��[h3����%=�X�р��^���j��@6ǜ�Q��(ՙ�H����.}�R�G������tf�� ���A��ؕ�R("�����Ё��^�-�/p��j$��j��M72"���-�ю�qcq�{��N��X�؅�w����-X�w�!�t�>ȟ�ٖV����#�q��	F��޷0�������vBi��@Y�3f��	��%�~W�Y�����z�N3���m���Cc�������}-��R �Q���l�ͺ�r�P8�~ȼ���&|gAu+�h�
F�c�:�x�.�i����	�Zy�%��_�48[�R@8��_M�Q� i��EFR�;��ئ�v��k��zL*-��GωӰ��]A�%���2�>��㩇8:�篢�PeK�/O�~�'�i���.b�=Y���܅>�"_B�{%��
�!Ԕ�R���(PG�5b���		���H��y��n2I9����d0F�z��b62�B�"ʂ!d<��$�qL��`��jJHc9��_��J C�T�/�L��v��z�m���Ja�'D��v��СO��^�,�FQ�kX$�*E�%�����S�P��'�esX��ev:`�W�\�l���_gj�gE#����<�{m�Y%�
d���{���ؼx6Ԥ�$�Z�f��O�$ɷ|��V���p�<p�R��k.J~M���C��V��̇�rV�H���X#l%-]_�ݺ���u[�LB�� 0.hNn^ ����Z����������Px���U��i�u����%V&��7>[�8Fi��v����A�.|������AQ�
c)x���G[���U��'����m��RbHB��������Y�W����4���I����������ηI��H;���C��/���=`�N���|���!*�V-�*�VgW�IU������^'O57�DͶQ����%/Y�=��{�_,K�6Y����˯���E��̒ذ�voR�,�S�y��Z�.h1�t��U���'� iŶYI��A?	lǨׂ���/�����90���<��V\?�-&���+#CS�z�=bKP������6�u��k�6s+;B0f�ʷ���� ?�Kt"j��,'p:Lo����̜��Ơs�+)��_�OnS�"�LZP�Ad�!vU,#J^���%{$��o��rb��Y�!�hXh�x�'y*I&���_�SR�^�~�-
���f��[�5�ZY�;����)8������T@P���-�~��m�%%�\��&Ԉi����7TZ�E�M�j3��()y'��n;�	�)�����j�ʶ(��Tm��(���:f�����6"����M�#G<ش<�Q(E
����%���Y���`���+����O��ί�ڊ�F�0T��W}(eO!���{ ��[ܶn��V�I��
mP�8���^ox���o�t"�����r�C17�-#@\�����㒮�N�X�*��H�[Nqۊ�O�w<�3�嗂�e΁}��gM��=׺Y]�9�LZ��O��0۟�
�oy
�O!2��ۭ������z���Xm-V>�T����`�"��qS�Z	���ϰ�U�w5'�%y�P����!:J��섢?�z�����yi���4�	$t��j�G����R/�����;�@,�$���G�
V ,�����60E�/op�$1�"]rF4
&��GPk]����@��:�!�'��Էl�Y�c+�m�k�id�	�И����UL�E���t� �\�}�.��<ĝ�j��r�	K-4���˗T�K���j�&+�`���\n�x�o�L����7A��B�}��,��K��b���L'��L�[6!Q����,ԦI���j2� g$6���QL��B�HI&�����5L��fXq ��%�^.sp N�櫰H��k��эa-�Ǻb9�,qb�|�	�@,�֊���R�o-��]ÝFZ�����%�K�ڹ۾�!�-6��~Au��a��c�G��̿�zO�/A��y/�Ȕ���Y�f��2���(�\�ZO³�D����g�6�����:f!��Siq�LӪ�&�	g���7�~I~5�&A]����zE6��ؼf"�2�!��� �ڵ2v-k�qve"��&w�za+��bkrO�u2���m�`�OۮÚ'�&��m<��բ���4��J,��i{M��������>�:���= 2�j��sA<�T�a�R�� +�A�3P(�2u������0��3)��E�(	`�a@4r��؛�c`�,T��F"rw&5c�+<��˕E@ճ@:H��4����ּ�`~șv�J}�@��;4�������{�+4�z�Zs��q�Z� WRNħ�k�z)���C��w��՜�vx��p��F����oQ��ȱ4`��&sLـ�^X$]���c��>Y�E�FD������e���qsJ�:&�9��א��c����t06z�N���-|��⟾&��O/&�4���#�R�BwՂtb�Vk/b��H��e�Fn}���5C�եD5�5��v��O��Ք�0-:W]��jnOUFj��
��5y���c��E�!��W{� ^vk�.��#H�V\/���.>I]A�"�$�g�]�~!�C����I)QZdi&=�����=�N��4�	��6��?p�GCW,E�����D\�b�N��Z���Qv\q��S�SɊ��Z%�#O����&:�?�{W�̣c,ڜk��D�G���_�#W @qРp�VJ�!0���Yl��,��V�#x��G��2�-�L8?��ۛA֓~��1&���iH5�C�L�R�u)�~���a�g"�#��1�ռ�h� 8���^��7�<XF���-8�S�J*E�$~��n�k�̠T�uK���E/��y�����!�(�AU�����ߊ��XV��Ҿ�F?($��~%K�!qD�<��D�������1�}H�%3�c�����&S<@	KA�,'��e�I���
��0����Z�\������+��H�Htݾ2DnUF�ፁŕD��<r��D��H�^
�	ԍ&>\u��;���4p���UH�?}&7��aM�	�?q�x�#��f��~���ڍ^�Xd"k��JJn}�!V1g�:����o폏:%��]���cE �d��J-�?+��,�J�47�tG���7������j�M����c��,�8����S�   �����= �����hg��g�    YZ