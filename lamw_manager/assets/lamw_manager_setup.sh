#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3523223089"
MD5="247760b3f200303cb3a76dddba176037"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20568"
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
	echo Date of packaging: Mon Mar  2 16:39:23 -03 2020
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
�7zXZ  �ִF !   �X���P] �}��JF���.���_j�ٽ�,�z��tE6sݲw���'��j�<{���q���)D���`2����H�:ǐ1����"�46q�f�?�MB��G�d�(����}LL�8�A�iT���ӼyB����CW�ɤ���g�]�e�U�r����D�-�6z[�:�����x}(�4&Jf+S?>?{U����T������wx!��	���[�q��۔&%5(���FW
���F��;�� A�]O!r���8��F0l$��6~�/��׎"m�:�����B:@��±�AFn/§E �h���?�9���xԦ�f�n"��sf=�h$�Pc��ǶW��iS��	���q�̌~;�,��|��Ȏ�Hy�>��|P"ܡ��f��w<*=���7�����k1[��c� * ^Nlj�ү��r��+"����u��.XI�X\!�&�����%_�Xxt�uTEr7'Q�G�B:��[E��Ͷ�@��=��psRV�$�'c;T�))�"Χr~~Ͻ��̰�&K<�7Wm�f<��h��=�$�x�tދA�3u)�DH��u���p��}����b��:4r+�I�%��O���ZY��P(ip�r`�粿����+4�o 8I�r�B������M�<C�4lVY\<��FwÀ�>J�fŚ�mR�΋a�RS��S]�|�m��F���
AK��GU$���G�#gD��l.�y���_�w�|J���<Zc⎟�J�����l�yƾjG�VAa`�y9�DXA���J29[�Cp���y
���w��zb������)����t�К#��W���|Q�!i��E0?�U>�	 �(��Q7&}�3����(�_�]�7Q�B���e�#.�ؼ�'�Uk����܆��Y���z��2� �P��l�(L��Gl�i$0q��W����Ş�C�5n#�~�䅍��'����s.�X���
��J��t��/KxK3�Mu������A��̄S W��P#���__p��C��z�[x�%����b.�
[A�}�ag���1+㕈�+樮c����_���ȼ*t��i������'����d��2S:���ȵj�I�`m߮�~� ��=�i
�aN9�����McZMZ�x��^��a�񧦀��Cd��4��a��H�|�Zȭ�窼���	���g1���k��V�x�CR�z�) �d c��~ar=�BI�N/ ֱC��f��`��7Υ5��vi����8E=	���֔L4����K�p�3:���0/�c�v����Q��|<�"m��9�gABr>��e��T=z[QS�/3Ja3K�8H�=M��AgO;S)�MO`��dM6�F�� G����2��%.W ���X _f����X�����@a��$�$�苈ܖ���5�Zd��KI�I���\���s���.NR�X� VY��GK�]�����{�AփU�O߳�V� n�~\J� �������!���c=!����+����#�g�򛱎�|4%���_v=�s����(ꛎ(�{��1*o���g�^dQC�O�r#�Z"������D�2�rƦ�
E elUA��*��O��j{m?)��p{��d�\�b��s�4#�!Z�9O�����"4�0}$��f�- �% �O�G�{��_����@��i��J��:��[#�K@,�X�}C�vm�p��w��i���Wi�Ev��T��X�2�ST����Y���3�ӿ;��7�=�A� ,k�nС��6Yw���VU���a���4�8Q���na=sN�p~*:�r7;��eu����9z�N-f��6{9ܽx^<��{�f�ޮHE��A�N�rZX�(޾ɐ26����D��	�M�p}��1�Mǹp�D�KPS۳���o��n��������U�2\�m��#��a8�����6D��
t�5iqz!�$�W4�.�"Op��`E��y]s�yLb�z$�3H7V0L��~��'�-A�<Y_=�ёϫ�$ʴ&'W�����u��X�s�a� �>���OC��p�Q`�%+0a��"_��B�R�ެ��6J�FvZ)��|AסV�#�P�Dp�!�J�7;����W��*p	`��SL��6k�T���N~Z?��\��j���	�m���̀��bC�is9¼$v��VtA�.�ƛc�]�>�r�p�)���/�L�
0�gip���al]K8���/	�T�d�����n��IV0��O-����.C���m)�n�"/�Mt�k�f���sf��/��a���)!Y*�;������FyE�����ld_�PMvp%a����1���6N���۲˸�)��W�i�EEG�J~�^ ~��]j,/ch �T_/o9��y�f[���g�.�W�_���_����j�ײ�r�*y�cq����VAt��Av�B-Ђq��/�P������-`V�eb�%4��V��4��մ��lM8ƈ,�%���&��6��§��z�]6��c���^N���q����q�G�V��1�����˱Q�i#��b܂ˆ˅�IV��̤�gn�4FЃd<t�j�i( Zj�P��G�L��$=D���9��~)#�n�L�bY�,���q�I���Q5����G~k� ��+ϩŇ&�BRBS��>j���g� ��ݜ�p�d�h?)fJ�<JvA�k<D�zuHAa�I��2y� �NOOjE���^2S!�-�CN�>{ìz�=
L���h��.}�R?t�+�!�A�u����d�]QL;̍D�T�f�y#����i�:�� 	31&�"7�u���Ar��"��b :]�_�%k^	ⰞE�Y�"(M�+*�fr;�`K���Mn����ؙ%[�������(������8w���<o��N�tS�`Z$:]>y���t,d�p:�*����AQ���j���� ����R�V�5���7I]�n�"w9����Jae���d��Lp�$�m$���04��9�yr�XՍ�JZ1Fs���q��oul�^%���H��rG����p_�0�#pv��#}[��FZ1�̂F����0��A��9�ߊ��y�c[�0S�ZJ���k3H��
��ڍ8���&O6����6�y	�m�+��K=r`�|��b�SG���0\��^c�_P#�y ,8<���S����[(f/9�A�Ĩ6�߸zQ-$İe̲{� 0��c�}A(ں�s��\%)�o0D]
�>V'�n(8u�P�p��Q����G�P��z0�0�c��Y�����S�Fൔ�x�����$��U�9�6fN;����OM؅,��Z�N�>!����?/�_����^^�)�ump6ƫWO�`l��pu��h�H?��gN�}4�R�Iv�%m���B�2�6��&��7!?v�*E��g��z��/�~wJ��� �q��Y��w�!�jq��������s�!�$���|�\ ��A~s�[�!Rd��1$�"�;H��89*;Q5\��U*���/����?Ę8ECs�D����M#.,T7i�Nh�r������f��VS�g������3K��9֫�_]�^���P�ȵ�k2�n��,�
4.fS0�ƽ�Q�t���a��!���Q�W����P�Jg��lS�"%'T�)�*�&��l8�"�'�Wě���An�2�7~Y��������Y؀)�W�Qkê'��0F+[_`V9#�W�YLɯ�!u��$������1�oǟ��+��w�v{�JP������K1E�_�j3�6;��O���&,��i� �*\s��A��s�e�h�ho��&[�LB���,��_�m(v����	g.i�s��no������[~<�V�`��}{�IAﮃw�U[���䟇8O]d�X�rb_G��E����1�VŦ#'&��0��K�܉l�T�P�ם���(Ȅ*�����:���\��{�F>Z1���Z�v,����}};I�G�ϹIn�N��X�ͺ"�Λ�={�	��yVL>S�W�����R~��ւ��z�t��m��,���U=#�^j�|�7�f�EB_˚/ol���Z	I��;"b+�q��o�I���`�=�\L��ţN��=����ۤ!N��>�s�I(��P3W�
������V?������ ��\�U����^J̊ v����SW�;}!*�WbN���d�����.�RlԒ��Gđ|S�[��%�,*$�d��z�U�����t"��6':��-%s#���S�i:��y챑�<�|֔ۗ��7(�]��n�z������^:��Ǭ�tf-bpf̩�����O��9��� ��8о~Y��ȅ\]��*����n��@������9^�Јƈ�6��N/h;�˙a{�ɻ�Ӭ�Z`���<I� �� ���І̥[�	3�^��t�p^�Q�Yi��j.ԏf�ꕎ��S��Y7��ȷT"�2�������~d��J�L	U(�I-u�	�ǇC���a�1�2(羴�ܬ��TFּ�")򥐙%ٝ��UT4k���JY29�"\fܧ������L��e�������y6]��Y�Ck� M����G �,r�,�����SvK>t�,:�t�_���c�3d9�ǐ$(cv�*!^��G�P�S�)*�ҩ�+r��R|mx�l[�2��풽N��MĹ����Fd�M_a��W��{v����t�/]���ҟ���K
%2\��w5�/2��[���Q�[���4.�;04,�M?��	�ꊱ(uxU���[n��?��[�B�K�'��2��,OJlo:q�8��MR%3 �f��h��[fJ�d�ո��U��p!/��%������� 3ʮ���Q �p`�̚5J���w�����'g�n�ve�o�".e(�D�����]����u7De�Q~yY���1�'���JYu�|aյ�����%�������v؞4h�V4G���PR�v^/_�b��4�!]7P���G����K�p	a�*�9�ƪ�/�+;U'3����F�Ϭ	�8�3S�5�m6�3?��� D�ǟ}R��D���Y�xe?�0)A;��\�]�ܺv�c��ZWW����\��Z��tyX6s�p�;������oҐ�Q�~BC�h�{�F���5,Ça)�!P������C��3凰\�	��OƂ�'��
@>�#O��K+�[��L��OA	�=�+���[!Nݮ;}���䩈u�j����꼄��w�e�]@3�mFn�u%��oHlk�/�R6�p�S�,!��F�dL0ld�'�ѻ�FV��.�#v�쫴�\���_�HI��Y�Y~�7*�n� )��2��/��֩��z(�6e��@w�Ns��o���M^U����I�\r����I�=�F��d�KTgV�za�k�ڭE�ҵ�
�Ɵ��G5�yGC��Ѣ�(���r��������
��U�����P��j��m�yW��~+'0�ٟ2�A6o;� *scv�r�ݛv���$��T:�%όz���oL�
�շ��.w��p1�?��vr�1�ܙ��+u����w���z/;�Q�`lm�m4�u/�,��з���
��:�8!�+�f{��y�c�U��-��G��H [$gq��k�ӄsl��BR�A�>6 ҂���.t[!�ݪ͛2O6�����`�ǿCO ����f/��E2(�\}U!0�Z�c���؂�Tw��u|-@�6H���o2�0a�Tl��j�#�|�52�Rc��";�M����Y&�I�Qه0�W�4{$��,ԙ|�p:�+"�g���`�E�����:�Hxu�s} |s?g���Ddl�B����� ��{�Hĕ����ǆ:7o\��4}c��g��M έ�`�^E$���<�����:CكJą�����
��/r���������Lx��8ʷ���.��?��J%���ymf#�gȾ�:Om�b6��`�A��=��P!�it��|�]�+�;�jSk��S[J��Gac�7�sT�m��VzX�q�<���p���:l`�����{������X�u���J5�_��Q�`��R$[ȉׁ��'�9���\�̯Z�c��e�M����yS��{���?�RŌ�N,)���.����?�AM񪏩�h5�G����+Ϩ�Z���C*b�,ù~��t8q����E.�$p�S����\ɗ�@ʩ6�H�v��-}�ky�=�2QFE�r�&���s���Moٱr��y� ~Kl���ޔ9���˘�M8�J(N���'
�ᖛ�A��O&K�8>Y�o�m.J��GCi���\�B�?9���D�UF0"ۍR�ǹڳ��nx>jmcE2����[���k}vP��b�i�G�ruldŐBʮ�|��z=�@��>��O!��r9�T"e%N�珜�����Y8]V��j8L*vD|친J	��>�Y�������'Lft��ڔ}�e��_\:e2Ī+��i(iC.)T,�=���NIO��h�*q A�!�^4�g��Z����eG�a0� �]��^�{8�8�_��<|�q�0����{��,�Q/�U�5��n�Zf�T�6!��Ӭ�I�k��P*UEʯMd���1Y�Q�)5l��̈́�i/��~M<��ӽ��ذ�1�#Ў�����	Ј���@�FС셍#P$�q}f��LȈa�Ɍ)��&�3]�a��Ѫm��<�Zy�*�:
/.���' ��w�Io>�l�e�Kp-=� ��I�AT��J�B�x�}�����|U�@t�-6�k��Q�$ż�����,,NK�%���K���'1"nG X�����K:2�o-��:1�r��z ��ɼ]M�غe�e�{�G�#_oE&�+���?M�\���I�V�@��[��n~;�++~|�)�����y����tP��m:G���fd�N4�����p�98�H�i���J]©�U�.�FD3 ���Ϙɵ���n��+�58'�����=����T�٤�u�Y/���D�`�^�2f
�#cS��1�Rbw�����Ș`���i������a��H���
bc���a|���v4�|��ɽD�2C��u:�u��ܑ�k,p���@�aOL�I�O��S�Ҭ���p{]�?γ�=5�H
]���8�I>��8�.<e�=�f�i��)���C��)����#��&�P����uL�S!��9E�-���a��"�9[.}(�H� �m��ۿMߖE��e�B��%�$�Ef���}��L��c_ȡ��kZ�N���#,ȭ�ȡ�G�ºвu�m|j���L��\�p��Mİ�N�� { Ӫ��]���̭X~Ō�7�;°pf~GSs�,�ċ��E�^?X�{��b�mM��
`Jv �&��	�z�~#ŉ@�e��+�&�Ffb)���Le�vs���
��������,MXƌƎ��.я� �=I�9"�.�M^�
���iNm.�T:���bi�1�p&��	�+���c�c�є(	����t�6{�Va�0�����ĉelۆ1�3/�����eL�!���{���*=�|�&�&�H�ݠ҂�|s9���绹����R�&���fk�Xt���ˣ�Y��`�xx���ݰ���~F�8T�wOX����Ja-��XYM	�>f�̊��c�g�RȔ6_&(�A���BB�44kL�o�����Ȓtz5O��/�Ҩ��f��v%)�f�(xc��Z�S�ܥ[�*hv4�N��r�[��{�ƍ��^o�F/�wL��ڐ�sh�iO����~1�IcϩQ�)v4:���K�sx]��� <F]��lh���;� vLm�����%0x[ҡ��� ���<U��!L���m}�{?IdA��=�����"��!�#4���p��b­�<R3�z�`���ߺ��9�_yhb�S�����i	��W�'�<-6�㯢�/�oo���W�(Sʭ�[��c״�Ygٔ�v_���ƃ�g��Ğ�x?X!��PɂJy̲6XQ(R�y��sVT��x�vj�N'�%6��I��N�S7xaRv��NHFt�$�{r��Iw��p�N?~��ω�n'�eK�f�;�!ޯν�Eu���~�%�%�_�"� � �k5�<�>�}w��_�P���3�����#	��$��(���k��e<�Q��]S>�[�E����>���r���([A�=n5�;��S��h�h�m��N�?T�О_�<��9���2V�F�k��-!��p��G,����^���H&)y�y��d��땢�u�
��Z2��Um�f���+�^�%��j)2�@~�F�I��V$9�:���#.�q��������շZ�M�-��Fw�nB�(�$B0Ԩ��=���UD��6����1cDz���d�A7�N$l�?����)D���؇�IO�z��Ն��$�Z��Tf7R,���l�(M�a�V �����;���g~܌��P٘-���擖t a��4����rՁ+g,�(��N�(._�`3ƕ�/���[�$��k��jn�O��� �֊�C �[��^�&�V�J�w'�I�2v�Y84���rĺ��}էUR߹"��&�\��-*uD��>�ǒ��ͭ�Y�KzɵQ�j�e+�OA��cxhκ���T�	�(��o������N}����({�a�FS]�cjک�cxݘe�h�(�a�Y�Hb�_sOcoU���Tq ���$X^�PmP���=�^\sF0p��eI��-FP��Ä5�2X�.t04ߵ{V�g��uڅYck������� �?AK	{���� 7�:�!���#�q(���5?8�kNF�t�/@���2�
L@2J�W�V^#����Ͱ �n� �!�R_`𸚮�� ~r��*)*�?6���m�˂�z�����Q�+����ù��#���'O��M�=�2����D���=�>�#�=��^L��)-�e�ϣyC��A���򯠦NR���Ñ���u?�iH�$�Ѓ�L+O0�5C�l�n�:6�B�*�+��i���C+�g�$�܉e�f�vg_"�A =)��[�^=O����'<�����w٘�����-�	�'c]��"/�礌���b�����F���1K���V�-�?�M�<�4������o�T
j��b$�X����p9?̧^�}��) ��X"H�y��O#:��o~&�2�#~�z����(/�i�*&�R��
pN��;E�H�>yK���⍨i�,@�Ǚ�X���4j���E�M����<�����i
�n�e�����ư�����o��
:�+����!p;ra^��X�!m)���B6�F���ձӧ�	�w(���o��N���Vc��wfΟ�M�t���P=��ec�#�A��~Sr"s���Nmc�x�m�S�|���H,.��@.���F�}��l�zA[0_]�w��eV�k)���}��� ���n�|{�e��m�"�����r�VN�p�,�����R��x��}6ɀkCj��;��ׅ��O�j ���9�c��姜_��b�K�~U&i��R�����V��3�w�����w���� M�i�����;����3��Zۤ�6�Jһ@O5��G�O�R��S9|lf��1 �vH������,J6���[�����R�֌�+�k�:�>pv���[ �|��5�W�A�i0u�fvW�<j�C��;�w�3"�������X������h�9\)�D=Fp����G��]5p)lr$�W��my�DGȋ֥�0�$��l�{�T�8���]i��9p^y�ť�!��vs�ُx{a��� ��D)Ϟ�jM
��>�~����������Z�E��SI��"4Պx�3�i�I%�Kv
V���V�U^��sɉ�ʒ�e��7�a����$���G���n��yu `K�Ó�J*�c�"����O���Ж���:l���O�����ߡE6R#ew$��H_�G�6^���];�7����E�B�%�/�̹�6��N�E��y���]���7�(�r^�8����2|��i�[�z��������G�6���'�y[�@ߝ�������f2�r#����`���S�2��E}�T��q���tI��f
.� 7�}ﳫl��y��l��Ii���Y�6""����C I��]�Rܬ�G����jy��B� d�G���;q�᳤C�����2ú�hA������h������j_߼6����V���9}�_�7�e����Z]{^�mg�+�Av\�'�Y��T�Yj)�
��z�m��H���u��g��?Id�؄��: V�@�p��@[cC�b�v�	ڥ�榃_�(��Ok����c-�t��� �;����ȡk�J�,��Җy����k�x��P����L����t�Q�&�gE�6`��$�����$i,�!�o�P��>�R�dbuQv��Э�"��M�������㐙R���g���<|��K�h�@�s�i���'�D��n�|��r�gh���'���~��/��=���9��W��� :����᥋Ze�Fx}�0��w}�N@�_��?ܻ�l��(*ij�Н�6xT�>��H�]ҠkJ�%��>2���@�c��U��BȬF%8��	�Y�1�D]�ȎD��>����sYw����pBM!	tƗD�1�Z3�uy'V!sUd���ͼ��'e�pn�~�QmNi�V=�^hP�l��/z�Dd�{k㞣�;::��B<F$���>d�����U�x��lf	@�ˠHG-��Ģ��
TɌ:�ʅ��[�TMM,�0 SbRTW�ud�g:�[%Kt��h��S�G{;�m�=	�#a^���Vߛ�ӞT-ҵ�� LX��养�iɅ�3�����(ǩ�Wzvl�+��Q���ԁ?��q�N��������Ʋ���u�+B����N���P�jNX��p��F�3��;ؽ޷��`�J�g�sXX'����o��R%��$`%�������=��R\f���y%}m=<���Һ��^����9GTz�I�N��3=���wS8Ր�_.����3N�/+�z��8&�iy�_�d���]����pAR�9�č��9�nϼ�"vnٓ�{�S��� ��������W�����Q�!*�yءM�z�f-[HTP�a�S?J�3myRk��$���Y�xo~B���\����rh����Gg��(�@ͪ�{������cx�\�{*�M��N{��1fgBm3]K��n31�ln޾���z<B���r2 ^��^	����L�� ��	��g�ۼԕ�@24���t���.��:p���&�Z+ƃJ&�_�G?>�5'�[U���SQ$���1x�s�I�q�íL�� ��cI���KC#<uD�\�K�����(�%�>y&���.ɒ�@Λҡ��gZ~S(��9P7?��݋��p|\	�9���tj��6����4�p�8�X]���%�a���\�I,[��g�zc����]��$�78Ȩ�sG����Ʃk�������c�p����s#{�M���g�K��Hp�����Gr��}�݊1���ٺ��
��C�a��1+�7l%�Y$W�69��w��n؏L����GC&�7���v����,����}(m*(o���˄ �c����	�y�s`6;�ܔ?P���l+��.`&m��~ѹX�� �)�m7���V�|�G�#D-G��P���O�.���d�ͯc�4뾮�۔ ���5x�o�/�
7@n�r�v�H@S�g��,���2���S����������������Zj|�ii0,M �]R3�r%H�!�Vf��|�د}޽��ЌvRP���vB��Z'j�>M���w=2�9O�$���P���o�h�'���ãsS��y�R$�62
�d��D�� �W2���`��Zٸz:i�s�ie)�5��_\\>��W��p;��-�d�䟗.A����;a�I�ʈ!�[c?��S#p̐H���Lf������-�pr�a!�pz�M�+p.͇���!O�4_P]�����&����dP`������Wc�iN��ݫ�2w�'Θ�nY��U x/j%�+|�Go����Tf����Tpĭ�E�co4�A�>2KuL~{96#W	����Gڃ���9/'�~�b���`3�AT�'���Z�?/R�=%�x=��"�F��[Zz�-� ��h�O�Ω�͔	��H��n��u��:V4��o�Q�s�s��� *��3r����D�rdx�Ẏx�*�)�l+�W>�u�Ԧ��.���#�����[������'�_�w�im����pZ����i۩��9�o�C}=��.b���v[rRzAd�c>�.�~/2]�ܬ� zm+�q��M!��oâ��Fi�j��:Dޢ���ŀo�M[���4�q��XL�~$&muNɎl(�Z����1�3�˙`'ED�L]D*wc���]0�GB� �.[�S��LÁƄ>�Cn�H%�oM������~�0ɚ�q�ٛb{n���gm��[���d�g�%��}m�d�Ⱦ�,��M��c��#C �������R�m�+09aC)$��|N곴{`�ض�wǳC1�?:��/[� �k3��RE� �5�F>s��Pm�sN�U�FpN�
q�o��5��rE��@��HIx��~3��P�ep���z�:�b��a�_�̡~j����+#��HW)�o/�<�ӞK�g`�VL{�	����^>:?�\Gw��I��顿7i/:T%s���Ӕ��WtZ�����E,m�Hpj����Qu���)e��f����>��{��)<��`����&+�u�� x�{��w�NM��X�zs��8#	���j���*�_��eq}����(6���d@{�}I�ٰy��u�#;�	�r��z��V��#@/V�i�\���������l�D��!�ʴ�Ѩ5%i�զ}H3e�ǋWg"�ֵ2|?g#�<1�pඦ�� ��1_���8r?y�C�h���Zq����B�����a����;p�9�t9�w�Po��
%�hӫ��n3
�+Q4���EJ#ȅ�+
���1+��lYrYL��cP�<�f�|��4K�p�I�� �(Z	�z2�a���+�c>�80q{��9 #��}Sw�;��8U���חm^�=KpC �g�nY�{�(�dh\R��F�{����+�ЀD�K*I��Lo#nUi��^�=:g$$i@RWݦ�ꇄ�yG=��wvg߫�ɡ3�O7�!��fe�вo� �n*�F��40�`�g��f��vj�$|K̐~���X>V���Z/_�`����[�����rkfD������8s��?��������|�h�7�7gځ!��\�4}��s|�>��y�pyu"�a8�����x�xG�]�%�0�ws��\QO���F�KJ;��P'7ѯ�+~[�� ���%���W�~�ܺt�i�N2*����g���H��)�徼��Pk�@�����B�:���Rl�M#�\Q����/kE��7�b�$:�S\������yҷ���:��rՐo[6��Ε��9T��ud�h��a�5�X��yK����D��`���_�Ǭ�����2��7`������oب���_�pn=jx�� �ksA9��>�~lE�g��&�0���l���Qc�E��v�z��.Ȑ}	aj��3��2؊׋kt`��i]����5���K�C���^?WʾG�hTȕ��	ל%_��v���+{��4	��W�9&�lO����Ԅ��G�7ƺ}~	��]�Ћ���ф@KI%�[�L~�+"S��f�'k�����f?˽s%2"����#ax�����<�p��t+�mkv�w�vS�׺,&����=��wY=��OC닛o|�� ةL�7XJ�	.,���)�#[�5�Zq榊aL�u=G{J1��?�`Y�1��&�<�2	S��W�RwG�O�>�o��|驲E$<z��rW��
3���n^"0�o�Ƃ�>}�c��9�I�\�  ���"�IJ'ش�}�U��Z����"Z!�R�	^K�3��>�a�{�<��I'����#���E����;�}X�����w��T��;�U�H˓:�Ue�s_���	���ц���'��T})~�3�)�q��ׅ���/cX}�g
BA��8�u�bs(�V<p�)�F�G/�j�����e�әVBJ�Ź��!�nE��r�X��� ly�10�A�`+T	�	-�6x�̹%jl�)��7 ���Y�E�� 2�#�/�-mܸ(U������=I��`�͟���%���*�^����&zpka����|�ԇ���AVV�Y���U<R[�R&�G�bc�J�-�z��|�=J�0l��ʵw&_��|�p����)���ҕ{,L#��˽o����BS��s ���jd?KVi���b�zj���~�^q�q���^�y4�56_���+ٴ,��Zh"fQoe�n�]z�B�Z�JV�L�?��f�-!��2/x� P��/��7��4��g�]���:'����aP&� ф���/;��kZ]|'�k�F����
����+� �l�t���)^wN#�,��D 	�໹ݡߺ�X �3o��Ru�1W��=1^~Mk>Vf��Wt��7CЉ�����|J'|��6���O��I��/�w�a��vnM� [�-�hO?�,Z���]�6R)M� �%!�Ew-�΂�c�W��A�[N/O ���R&�VK��+F�7������%�	9C�I���9�	J,���!�q�[�AcI��uS ���7��q��;���U]�D�Wb˻-��N2��v����z#�d<�E*��#lR��o��8<uZ#͗�r��h���J�����r�}5G��F����)���h�q�X�kko���T�U�Ƥ����[��O��s�7��t(m<��m6~?hۢ��x��>�S:W0�����+aZ��~�i0�7��CΥ�/K���<͟"Qut���^G��PL�:rǊ�)�������&F����T[�� ��� I����RZiQ��� �_�F?����4�����0�!Xn�L�|t-�i���.Q2
+�eYf�z3NYXH�����A�S���Y�������dEMp_��|����BO�v��� �{l^�%Dk�	?3�$�ѥ����v��T�b��I��}���#7w��k.q��z(Ѝ^m�#nkOND1��$EZ��-9���+I0�v��u��e��k��}�v{�� =?&d<z�{��/}E�k�\6�YQ�M���g�JՄ�����+�� N���i �Ɍ�#6�}�+�������GV��X���F4��軥�g��L��]�2��!��r}=�����v�o�7�He����R��B�t�g 
+,���q��+ ����F��(~�+R�ATΪRx_\��E�u9r+�~���]i�ߜ�bp�/���.'��y����FxЪʪ ��xs�,�!Q�l5Qq� #k|���M9_�l���%dꘛ��YE��LL09�H�\���k���'�0V��1�H��$ƅ���iH�]{e�'�V���p�c&-���H�!	��M�]������o�	���� s��������e ��ҩG��D���2�i��\���n��xl|mć)�{:]��� � ti� ���땄���Uc�l��K�xo\��.���B~�8�l��UC����vb�yA-��~�6�����n�c/Ô�+����g�L�M;�;��I _����qc��]�����r(��%,� ��ɵ���|��]���У^$c�J�������LJ^݈2g�>�	���]�0Sv�N��ʰx�8ꔇp�V���T>�VԳ��]w��'���@'����D}2�0��MZ�\�mҙ(��1Ex|��.�R ��`��G���1��I�}��2%۴�#�[��.�w��}	GL�͌���7*t�s:��&�6�T�Qޮ}�������T�����_�\��*�W�p�yAZ\��3�?^6�M'���E�u}'�����f�/��j�l�NV~����sr`�D0���_��,^���y�2�*4E�lD��5�s�E��JX@v���m�0]���t�Q���Hlo����?2"w���?: ;q聯��O���'�3�nt?��u/��zN�~�Z��J6}ǂ������W��nXmp���8�s�zy� ����������%��2��8X��ܺ+�r�w��3n�kk$`Ew���? �q�:<��}Mp�:8�/-��p]`�!�*u@�f�H+`.hH��>!M��XT�_g�n�3�ۤsI&G�+�)�p�ΣͶUk|6�&CH��5=��r
��ɵ�
?�)[��Oѵ���������<)B�'�O�W3\�V�!��Cj8N'k1X�"J:<���tS� Xh�y<���Ty��}/G����Ssn{mf�[�n}[�B���#tkπ7�t��;���j�X)��̸0gw��œkh�U"e)���I`����B���2c�N}����/Ȱ�� 䠺�^�O�^ҽk|�˱3M�WV3�%ʯMt�?�d �f8�W�g�D��(��>v�����!{/b��a3���D��0�9��K��dX�Yq��nEuZR�͸��J������%�
S������?FI#�cl�]B�.7�Cpz룑	ۺH�ݳ�ߊIl�-�yPX%�(ۛ��Fi}�`�d0ӨNB�H}I�FL~�\E�2Ő�]q�Г�|�
�( ��nǂ��U0��2��]7T=��q2�gE��[�6[��O���w����8B�Xu�ܕ�ǳ"�.뇠k��v��t��Z�a_ϴW�l�f��Kt8[��'�D���K�%�.�u�G�֫2��%�;�ʍۄMb�0ؚ!��O�0�g���W_�7C��= ���������#g[L\�����,#b���PB&`���(:�gh����'9Ŵ���_ԝ�ф��&8VU#2H� ���]fMxf�]v3e�>�h5���5�^J `zm�'W�$	T��
x�=m�u�E�>!5��9�����<�I���ѹk�T5����,���(7'���T��$m8G�L�S�5|�/����C�<뛏EHnV�6����_0)�}�b-�m'����qx�)#��5A�	j8Q�`K�{��|g*��ۨ�>s��L�l���%��o��������'7������KqKl�s%mQ.g%���C��"�����_룃�2~�4	����L��Z�q�I-Z0J���:��r��jɾ��^m���ź�����ʕ�Ձ<���U�k6�Eh����� ����%Df�^�(�g���Iʒ���?g�
7�Y'�A2��y��5���[wjK7�&|ϝ9�p��%8��(�����~갑���͢���Q3��E|guNmD$�H��^C���Et����˛�M;x�~۟ف#|�C�[7SA�^�S��#�-�d~cG�ö�>�r�F6a�i�G(I�#X����oJ�v�T����%��w1�<wd�-ݒ��uhvS�
q�15�Sj$F��7gJ��)�g��$���M�?Muc���O��.�
���6̷oҩ�H�@y�*Y<�Yb	�z�����TE�C�����4k!�9�ED��>l���z�@�������0Lqpk���R�Z��eE��riɉ6K�:t��᢭�[�ڜ��=c�$�g��ٙ�iʸ���ïh���J_�����[�s��Q��'���FJX"������ek�xL�!��]�c`�V�@��E�.����hJJZ+�7��p�~,?�+���������c��lg�N�
�V����TO�$��H��0��ş;�l���d
8��m0�cG�~>��풟�����@�q	L�M�/�}��VZ���*���E�1�kr("��qS���K�y�.U��a��_�,�^:e��>��5� � �a׼ץ���Ja0ȸUS���*���We{X��ۋ�	���7	V2֦:d�&���������2J`n��I�<m?�m=�4"��/����'�U\~�U�v��5CA���������i��U��3�PT�$�@Ǭqff�yCOvjR�:�UdBo������uQ��b�6q���`?N&G	�.y<Ez5k�)'0�����\�q�T
}�x�Sa����X'T/b�J��jt���V��p�|��6y�`��H�^Y���9VfY���A^}�����I��V8���޹����6D(�a��&� Aิ�BY��/�F	[E�a���a�����[ۨ��h���kB1߶�z�j�O��I�7����r`��Ѭ���R�&��Nuh���*Ş
��\	R[Kp�nV����_�Ӫ���n^��}��@���PuA�ǖ)t�Q�Zh�مH(���yɏ�Ƃkrz����֗� D2z*���F~�P�O�?X7��&N�<�ԏ�����ךv��-k����cFD�jV����yQ�P��p�W���}H^��_z�:ei�pO����X���K5`�������N ��p��n7��N۝�{��"Sc�5�o���6��̚���r=V�_` 0p�V�lv��}��(F��$f`���]���xbOB����Kql�b:����Aя�Dà�������Q�k�Qp�u���R���ZW-o��������qX~)��i(���3�A�Y�2\������x���fnDi��T웤���59�b��f��=ܭ�l��}U����LBa�t�62�C��wByG9���	�%¦R+Ҥ����N����!\X|K)�A�TބdY@g�[ݢo�쿊�ۉ��&�*v���z�@�N8��Ɖ���q�F<l?�wk!UW���^�4 ��bG�2yj���r#ZB�C�'��}�Y:3�#�UѤ'��+(9B���� ,����;������*q4���oF��(�e��>�ɤ�������Tjךh=���,=!݅��'G���pX�_���p��������7�L���#���,�988�����7*G7͆h��L���ikut��F��c�2��ҵ���:o#&K�/O���VX��I�h�a&����KmZ�����`ԯ�i��G��l�!L�W���tWn�Fs	hk��^V��g��ȅ?��
�F�l��g����>��@]��}�8�0�z��&���;ŘT�\ɵ���P����y)�<�W�o�s�O���b�ç����(�"�}�&ڥ�?�љ���ۈg�a-@������w�M�✅�b�j���P 8]5�*_6�ai�m稬&��y#�˧�)���|�PA������|�ą��KbU��F=�1����������[�b�p����Fe��;\d�c�!�	��MEk�[B�U6�^�nD��l�:��K�֭�6�?�d)(��<���W$シ�rpeh}�jr�D��|;*����"��G |H3ȥ+}]��1izև>�ep���,KF�7��&�*��d)"��*�]9�N�l���D��w]�靕�6�b����-ۓ�~1>t.��2PW�r���Rݚ��]d�Z�Q�������	�К٠�����p,
kmK���.����ѩ$�n�=����ew�t�ݤ�e �(��/uȰ���f�jxG�p�>Kt��}5��\�o�7�{*�/Z�3/[��)�B�"Z��Kj�K��A�B��ϣ:{��x���O���B�ܓwȽ#�y'��jo:���27g��r֞}ڎ��E�|K���~�}�����!8��3�!`�vD�+�W��;:�'���
�!>�07֩��?_��p��)�V
���jOceT�YE<�p�O?=��9:Sn_����s�����E�e���`��m���d�ũ��>�X���-#�m������q��۲L���ـ��H�]��ȧ�C�B%]�Ew;�]����(���UZ'iU^v�)�$SNӎ�v�N\���b�-=��vՄ����Ž���ވx2żp[hV:�X�t�ҷ<�TG���2�*��|�CY�=Z���/�qa���u�|A���]Y�wb" �b��۹���/�J����G���aǶ�a-�t%z���5a(�   �o�-Ӣ�� ���������g�    YZ