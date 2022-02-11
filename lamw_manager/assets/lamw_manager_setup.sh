#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1088877909"
MD5="67bdf55c621580edb1cb5bed705785b9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26484"
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
	echo Date of packaging: Fri Feb 11 03:52:42 -03 2022
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
�7zXZ  �ִF !   �X���g4] �}��1Dd]����P�t�D���,��-ǹ�C�ԜS,�ɨ?�jwX8���U�i$Fkt�]�h0�l`�������H7/��q�+����?y�-z���h���2'_�⍵ �"�u�d�<�fBB�i���1V�PJ�x�Ώ�1<5������0��tf)��F�P�M�*޷�}N{-�}��\��T��A)I+����.D�*X�c`sD�~��⹄��.�����A��Fg:��ݒ��I��Wp���T��Kp6�&6<yIo
G�Y��7�
m;Ũb���9�J�F�  �~���h��x@� D�����W� �1`�fV�j��U3e������݂g°\6(��gVwN��R�u'y���m�ӴB���l]��ٙ�H��1+���	||6�	Vmak��)�-�C]wP �AA��;���ͽ�%*��	����?ǗG}�҇3q�0�ՔDT�� ��}��u.Η�}�
�a� ��e��ڒ����D�����N���D���ҷ���;�x��g.JpOP��'�JA�;�&�1kl>h>�������,��͒]
�Զ��0�c�(,
%}�:�#<����0Y@��O�X��H�R�5F7r�\_g��c���S�$�z6@X��%��L�_TM��\p�ԉ�d�<��Q�8�q�ZmH]{ܲc6A��ʓ��7�8��x=m �CÞ�-[�n�cz�e��f3���OݮGbg&s7�`ե[m�iQ�ʧ,>��s�U*,! :�Z�B�Z��q�8Ο��F�B	��ф=�s�~�H(�t��)z��?��B�j*���ƅ-���g�pH-��r��.�6iUa��3������s�+&!T�
cD���~Ɨ�q<��}J3g��f���#*�Չ�XU�NB-���췖-FIQ3,Ϻ��o�\������aW�kc�$�M���pidEh������3?v)�S'(�<������C�A��h^"ި�ԸbЏW�����+Ŵ�\�^��0��2��As�%��sU��}��p�X3�MGn��6F�d��ɀS ~tTa�F�}r��R�9�Ɓ���۱'�#�D�A��a���	0o)[B�[f��7�$�l����2[e���w�[���xJ��Q[��O�O
���;4�Ib�<I��O�`CE7q���-�4�05&����4L�y�������o&�`�����`@qz9�1�	�
���j���=w�Fk.������h-���1՚)`���R�Z��V}>��e�����E{�v�b9/SӇЂZ�-$��q���n�o�).p���r!g �/=ve`$|������s��2�oQϻ��+�/i��нu<w�D�X�D���n�M��o��cm54�O����lX�� mH���R�#}Q�MLn+��r�CJ`��P>�ғAˠ1Vj�\X,$���Qf��eoI�鮼{�C���d�S���^��UZ<[�|��wPj+�,�3���������I��������N�@֩a�/b,����F-������{O~х�5~Ae褪����W�:5�N�)��R��3�'���|�)�.�pCzو��C:>�"�\ ����5���V詰�$�C�_Z��b��@5���Vi|�NFY�`�����U+����c kBH̞��71P9�羊��>ͬM���%%�iΗ��y$�4_'�p���^��a��52T�7�wQ���K�X
H�*������ǣ��U������jv���(�"���) �a&'��R-�p��Z���{mv�N���wNr�s��圬)r#�h���L���i�zo�8ȁ��X�Klʖ���ϛ��G�82)�d��^�[E�tM�V���2RD�Ev��_��K��>g��ެO�~����M\�d��K��Jxߕ[�o�yԝ���|]욍��y����~l��#�o ��~�n��N�Z���N$)�u��|�|'j�~u;.��/����UU���n¾4�ՠޫ���:�@�����[���������L����h^A-i���_� �kr��S��0ϻ��b l�`�_�������س'ls4�FߺnIvLa�:�&��NZhZ���}G�+4��)�v�U3�\x�H6��'*���o���#�N��Gj��d<�n��⭑3��MY�[����PD䊓9�K���y�[#�5�C zc�zZT�r��(E�۹�ֻ�_YRE�<u��s��&�(���ѹҢ�X�7Wsh�Ż1������=]� u?�E�*fɐ�aB���YXJ���u�&��s���%a��!�@!"Yt%�%�^�6�([m���$m�P�O�B2g�1|ɿDt(	 ��Z �=4��S�)&C#c{�db����b?p=��G���*�~�6�/Щ]{x�$�b��,{�P��r�؃��P�7�q� ��-��.���M�P�>��a�3�5U1��N�M�4���%tahB\�=��n �ZϭM��p�T�GwC"flEgj�)�_;K�-�:��̯֪��o�l���3�B�;Ć=��D��=hw�� G��ߍ�J�֓�<�
�z K�dيSQ�ވ�G�o���}I�a��_GO�:(0Ӿ�Obm��7)A4j<I�(¿��XR��Ӓ��p6��_`A��%�6S����X��)�� ���(��ks�Cma�M��k�9�2H�oKU^RI�'��$rqFh`��C �-�\>�1��M�n~�F�V�bR#,+�<�'�l��0�\o0��v:����	���H"�e�,P�'PWA� �xB+��Y��1�P�p�����f�=�P���>̪G�}�3�i��@m &����������U�-4��o򎎘�	�P���7��>&�i"�re�
T���'���G�,�u������G���F���/h+M��V��F $\�m��ľ=pNq) s}�}���g|�b�ԧ�(��osb���/4�F�#�)���&���m����&�"7Š��h���(*`����ӟ���Ѩ8&��������r���3dU縀��"<WY��q�	���ra�At�/__��C4W�g��4]|+�
�
���h&����XВb-�gr��@$��w�6��z݇���o�R�?vf�|��3�����F8+��|Fb<}�^��c�TD>%�0�}�=tu��0���!u�����i�J+0a;3Vv�?�g���^3��6���(D�=�7�@U�7�~b�����lp!���9#�`��@-&�e�wt)L*��F#X��_�\j�'�ȓ�"��^[Ĺ�3w��^�#�*��8���%@��������:۾$�R�D̡q}���v�;�Б�3��)�0W�?��X�/���B�Hy��|���V��i����s;���ϫ���S�_L.�	�rΛ>V-�c��$f	AIk-`ՃYP��Sn\�ٗ��r��2�'����4��������%�#Ҭ"����FCu��w�*�X�*��UJƸ!�9�"�5'��ĭ���6���cX��d�\*�:<Pz����E���tЄ�=0ɹXAG��ú��p��%4&�`�$�i�6?�:����C&�G�ܝ����U�{iE^Y��r�Ӌe8�s�%��f��͝�ٴ�e.���_&!s
_�����R����i�$08����I��RU	,��Ҕ-�[S�{*�
�]�&�r�A�����,����~��{���gD��ӡa�x^�?��H��!�g?bcJI�
>������>����%����SZp+`4R����&'��P�F�g�𕃊�I'CD��?�2
���k^�	.8viq���F���AsТ��b<�@�'J`��?u�W��-�I8�H��b� Пӧ���^���J���ng\��=q]k�kk��ܗ��0O�U��D*�s��S���ʄt��k�3;�9��L^�3���|~h�5���6�{���D���BL��k#;@��M�����5��",Sx���1�Z	ō�K����~�r0�d'���eNr��/��9�iR�h�z�'�
����Q�uAcTy��
�ǩ�օ a���TgwO�J8�C��}@A�7��e�vMǢ� �q��d�L������9����D�Y��QHP �S��ɓ��r,��f��MGq&����;������+�~��ok���y?���E�v>���L�O����?�0�$�	D}�~������/[�:,s�A����*� )8�� �������~��!�����:�@ؙ@�s��v%O^���F���-�v>|�L�.1�n
���˖�<�2�iڜ�8筋�@p.*G�=8�mŜ�17�r��=	g´7_Y�<��I��m����8oxLޠ���I�}��ݖœ���SOk������W�{���H��Ț";e,P����&dd�^6	7u�B��14�8���ʦ�N���k�e�̹ơ1$|��	��v5�3����}��쾖�t"%�UO��n6TYG��oq1W�8rY��\��V@�u+ e��7���0�A��¯���X���:V��E�񦥂Q�Cۋ��h�U� syy�j�,i����Oo(H�.E���q�	n��m�>�Z�A2@퐱K�z�{��t7e��h۞ͅ��"&�p|�Y�a�ݡ����Ĩ�o/8�Ϩv_���Z�e�E�#kv��n#��K�.C�gC#���i${^�Ҙ�� 
V��0[ ��ύq�Iv{���楃A�N	r��p�yK�;O�ׁ��[�5�L$��.�m؜����a�6�ӑ�M%�ڇ�ЪD���e�sY��Ez�O��C��C+�ލ��c����6� �v�V��ɖs�+B�jw��W����Ƌv%?��������'ٔ@�qMGߌ�\>Tmb�V�a��8�O,]Bj�,���V�2�#%5����(�T~>Hlf��T ���;��2�L�s�O���=�	��gp�LT��/�49��:���H�"��)M�+W��b_�OE���%�4�L�#�T��5Q�Y²�Z�����J>�J�B����9��х��k�J�ҫG��?.B񮋮��΀�i�7��E��X��Z�+,&:�ǭ�$rB]�)]~4����$ć��Șs(���|M�΢���Fw�lU�p4ϯT[�Iđ��;�\�Nݾ�A�mC��T�@9��O��8X��|�S	WKM@���A�����Op0���RgDs%�y\� c��1Bz�]�3o)�0�N�0��(u`PF �@-��;4�E�J*IH�sHI�����z=�|��׈�	nq�@)k�1�U����jX�
�y�Xk|�[-���X��ߍ��(���ٴj���V�"*BR�O�v�`13(�r�'حY�ͽԴ��h��g�ln��	G;!SOH�t6�;Q�ߢƚ��#M`
AY�����\k�R�y������r�u���-c�ۊ�\����y5����}a��0ELucP'���!�����҈�?���`�q*$����%�qn��o��$W���������{PK�
Ϗi��>K����6EAPq��	�FY:�\Q����gÃ��7��y���@��s��2ǰ^�m��˸b@%��CVi,�d!�%����7s�6����il��Fr�봹n)Mb��J���^��k���O���x�Y�������6J���ܟ�"��k)�2PZ�#�J�h�I�0���E�2�2����k�
���{���fl���V����'x��� D:�t���|���~g\+o�77��j�����m��w��+%�V�YD��~��(
������ M6}0J`�y�b���]v��Q�,2�����>��0қ�4 ��	���z��C���C=ѳ�;U�_f]�����V�@����EFF�B�;������FZ�WHЖ� ����u[[MY�%X��{��ü���u�P!F��=�)M����q���N���8�+��]#��v�$O�dx�"U�/<���:)N|>�ސ3Ď_EW�3W[��!�k����*��^qyU;p�g������j���ADp�}j�"��|�2�n~�s����ԓ3���T�D�E��@�1�aD�l�/��D�ɳH1tj���#���Gu	���*�C3��6��7�'��%N^U�>�c:�)�FP9
#�i����C���c���E>]녰ͭ+K��S��X�j�2>�iޠ�A��ʞ����(wu�x�K8�ޱ�PkBH?��X��Ҟ�z�l*]Gd�V����u�-',i��+���e+V*1%���xeuz�Z ���o�y��� �f:��:*)Q���sDsۡ`~@	!^S�����
�y�|s��L��8QQ#$�*�[^�<�F��!��|�<���\=x�8�#�u
z�t�2�-�%㻝����5�02T@�AF��0��0�����Ȍ��mL��@n�]�0��Q�æ@�|U��詫Aa�[�M��D���T ��V�*>2��+�����<�\C$�}�����jl����k��D`s�"�M6�C�����0$��c�lŵ7N;羖�E?����:I�,.����|�qbw��`�[��Խ�*��"B>e���$����ݗ�q'J�
F�8[*���MG�R[˃"+��Ɣ!{�sqE�ق^���w���X�}]�?%��C��o�ĵ/	���T��a���&kB��O�ǈwĆ�ոj�}Z������ѣc�G���-/��FJ5̣5E�	P8��������ku�{�3�K(ő!�����ෑ���=�b1,�%pt}��
��'\�c8EC��7�#���:<�98	'sW�Y��N�%/�
,zG��)�AF"S6+[��%�q�?w��铒[��[#V�xVB1�����9<��ט�����+M���C¡�Lbߺ4�	9Չ���̜qԚ>�l�X���S��&��d	�T�l	���>�D�?e�0�Q������܅��9��z�HjQl&��kl�u>��蒫�����R��d5�ّ���R� ������	C5Q�d? Sa��C�qw�OJҀ�;�8/��"8 �ʮ��2�&�6�v)��9,�.�y�@��-G7�,u}��GM���^T���n���qM��0$�YK���LJ�>C��b�<>-6�{A��G�1$Y˨�>-�����Ɉ�k򝕗��Wi��������VCy�(xL�k�����Pſn������ݽa����eQPY��C�Z4��x0���Y�s�r���u,�	������{i�kҀ=c��s=}y�3����,�9J��	׹�.�2|�m��"a���(���8u.�f�ʶ�])�l=�&�M�����Zv8{��&�����#�$���{��?��.����am����Lx#��c�~ ��ɷU��l�*�l#����X<���O-��+�f1�Q�����^�¶<dY�^��
�ܧ)�@���p��8�~'��޺��^�}#��A���=V��^�M���pX�gZ��o7��Z[�ꯑ��4N>);lg��C��t��7G;����bWձ�_�I��?��(�cl�`w��&{�#0ح��ш=��܍?���J%:0�����w���1�٭���OOȿ� 9� ���6������'���y����IԨ8�f+Jti3q@�aAᚘ���z"��*�DG95�R�!��[U���KV.n"mN��֨[��9�P�[,�P�~+��j�BE��H���Ɓ��z��c�c<qK�m5������J�v��5���'�	�8p!�68_j����U���5�8YÆ}}�Bw2f����=kX�Gۍ��U���a���Ǟi�ӡgt���g�N�`�Ϋ�9O�s1et���>�����H�z{��@���T|"��>m��Ab����)<3�.�v�A�֤}�Lt�E�4�0qi��ʪ�_\s\	����v�s[�2+�ct��g3����Rةwu�Ĝ�3�a�]g��$���(%c߀�O�~k+�}j�4�����͇�\�v�O���'x��6/�]|�
��wz�9��ly�J�N@޺��9(��i�T�ΙD|c T�� �#�\iu��4���-D�lû\�9��K<�Ghh��(��p{ �~xG�'��i�?�S,P��b;�_Q�=;7��� <K��7��#�h�<{��.�\���������Jg�C���+�߁���)��т�ʻ귣~�X��r�~�am���a��.n���ӂ5�:ڊI���yV�0$^e�[ʕ����k�~�ZMG��R7rs|1�wD��a�	Or�Ux#�OS�����io�O쎃��Z�S��T֧��SU߈�'�?-�so7���ɟ��T����~�5������ ���(���2j�ׄ�X�P�K	s*I��������x�A/�����E�����-���w��0Ny��}�r�3 e�5�d����z�߃͍2�K��@���z2�f���'��Ѧ�T�g/@��X��];(�7�5�����[�֙K�;`~4v:�ة�A��U�ʩ��+�m�	�
�S�H�_rq�q=�n�<�U��A��lɲ�����r��mbޭ���s�%o�iaYy�XN#y}�x3��!�������2uF��?�-Ph�*�������PC��^iEd��LV��{��ѽ�m)6��{�8� |67x�8��p=���7�'���ʴ��l����LZ����T�������N��?!ß���Z ���{�W1��x���'�L:ݰm�`��������(B1j��%�l��1�7	�3L#q3C'�:ԅfisJΣ��ɒ��$%$A���{Gux���m|���m=yE���k����Vx�Ú�܃淍 �ˊ��^�6�l�4�XѰ�'^����-ۀ��Ԭ������(f����X�9@Mv�b'��Y�ˇwυ�����ܱ��x(���
�:�lY߹g&p�}��J��kOK��3}):�P|';���Wz9ʁ��1|b�t=�\�׾ӫ>�^���D� ���T* �E�����[ML����R��"��s'���3����7?�ov��ʥ�ܴT�RC<p��g��7�!��8��H_Q���L��^�o�<��K�w͠�C+�:ވ 5 Ѕk�ՠŐl�z�"a8�S2���s�j�v�r^���z*�'�Ry7�`�Z�a��>WǦ�w�����΢#?�S��gZ�&'[�᯽Ϥ��&���N��K�%Y,q��{�1�ܜ�+O��%��y�ˍgG_��|��R�f*�|���3�^'�r����>��ƶB��9V�L�(�<�.�y�-���.�Ο��������w4�+nS����.�e�$��5N�ީA�R8�^�[p��O�dҤ�B�0�T�T �i(D��� �p�Z<f��$'�E�|[���74��%�Q�g �f���k,V����@��`6I����P:if��gX�� �d��o��B��~�/2r�->��f��H36�u1L�n�)�,�Lz�- jZr(I��:5��	�7��Ի1��N�r������e0�W�Ы����BhsO�ت����]y�}@/ǆ9ଝ-���sNyH�r.�q`OY��6�B(����a.�� ���JM��[�K6���IqZ^&��Fm`a#g&��AB� *���K{�, �� ��߲��J�O?&��A���������{^�����6��@�&�_��[�i�C����d	y��}Ļ�_��gg9�-D,˹�S���(X�6D�f��a���Ϗc.!f`((Q��w�w"+W��&��[����<����<^$?6�#�XhU��:���&�={�����'�:>Io��(���ׇ���foB�8ӛ�#E���=��f�=,��P&�ݯ��s�����P녿Ȫ�������M����|X�@0�ze=�hA�q�|b�=σ�ܤք1��j���}���S�U=w-Z���P����Bc�j�����Uz|�Wo���R�Q�?���T;C�a����{�1��5���"E[u��Flm�/�q!��={H9��86�$J��'l���,7;ȯ1�v����	��a�#2���1]g�����Ne���h胻č.����&g #ƨJ =�Z���m�-lFC��&���k�rkӵF\�^����l�z)���)�f"���q�W�߷y��^���r	�P�II]��Qsx���(ScId��Z�@�{4����)��~�e�\gM��KPvu	�0�3�.�$GO�G�[�q��qzf��B���@c�\��i������.�QlM4��s�]#���~�S�<�π%q�!7ę�������Ѯ�juY<F�x7Э{p�L��'��%�*k�l)\#�d<�bԽ�8�������z�:-vCFF�S�8&C-�>1t!/����w�����ʣߡ�GA����A=_|lc���FU'v�b!�[ )�fs�IЫ���>׽��1����M�}���{��4L*o�=k9��*�wJLq�n��ZNEE��`"H� ���Lҝy�O��z��/�E�(�YL�QqJ�z���/w{z�}Lt]�~}�be��Ʋi5M���w�"�{��fYd�8ok��'q���(�ī�z����K��m�u�@]9:P��!���)�ʔ����f�@����M��L��%� X�@�(�l~2���H��Y58�E"U� �	��g�j$\f_�4Z+P@��r��`e���,�����Q��@��D�M�����抨�_��?�"�Uy�%/;ZF��B��`�D#p7�F�@r�j���{�j���%��@{����?�l�r��⯂��MW�5F��w�¦�*��?�W��g�_U��՛�-r�|u�w���Qe��݉H~���>�d��ΙI�̾*�^o�*L��K�d���	�C�A1j�Շ��[!��"µaʂن����%�2�[Fm���-�%�A�w��y�;ܗ稒Y�{�����N�$��.�zި�t)M�;O����Պ�ё���jD��С��>30��XT���ڵ���˙R&P*}��:oS3*��OH1���H���[�Ѓ�E��l�
�2�~��x:!�ҍ����~#�-�!@,���<�\��v��t8�Vf�ë��#H���4hvz��������hn,A|���e�C��J��;�É�7�6�սѭ'�2�V�ƢbB�Ǒ^���x���~-��5��ˁ���h�������G���R����b73�aU��u�z�6�m��a}��Df��ӆ��J�^��� ۘ������}
a@���5�$��_h�~��y��x^�]U�_��r��᭒�iNi�u��]�1Z���L��5.`{���
l�B<s��MA)�/�j  d�z@�de�o�k���T���٢n!�z���w4��)�t����R�J���q�X>��Q/U�DTS�w�����چv|p$"��혰�2��i�򅁧����QqAX�MO��	�&T*a�ɭ�b��$A0��b��K�� F��'E�uA���%8���g� �Z��0�����a��5L��[�m� BC�Q3>��F��_3} ����]��Rt\��u ����`e��J%\�Bm;p�{�,,�tWH)�¢��t��p�&�Dq��N�G�>�`|�:��>����a�VB%���������K�����˯��� ���������G�υ�0�l-��4Lc�F�ʱ��*�6_)#nY�rT��a�Xp��k� �'��}�>/=đ�q��h��AX�܋�8�#�v�k�#b��KS2@NE<�0��D%����%��iJ��k��M���R�r�~�Nu��t�n
����g��c�Tܢ��JiL���h�_˨(�5��ڳ��]^��o��,%,��j��.��O-<��� �2�o������(��o�'CJ�t�2�8���"��v�Q�m�l��4@��M���8� Q<�梋�Y��_������X���)ڴ(�E�	Q��h�'ĥ�N�.5I�&L}�⧁u�
=Ζmc�c ���s�8^]<�bqO�DHD�\�@� e���Lת�]��D���e
r��
׺^e[�Y_θ |b�Blc�oČ.�m�@}��_=$�������,��D�@g�`J�@�nذSI����(_�ޓ���ZI&�Hl#�xK}C�����x�� ��CG�\����ǔV��-�6����A��q������B�g��VS�ǃ;?m�&F��<ɸ�>�k
$��
��'����V���axY٤����HOdA�,�=�D��yP�ǋ>{�VZ�����)����B�R
��j���|���`SG�TKqx	'H΋F�=�8G����z��?�A�0����tC;��c�F���%D��t����T��p�9�P�[�e��&��Jm ����_�Z[<�&3D/�F?)&��OŘ	e�i#T�r@�-FSʋ��uK9����K^}��o�����NS�(�+x�ڷ-�Mv��Z�b����q�9g������=fcЎ;��j�HW�� �E>p	���u.�;|Vr�:�+�L#�H���8�C�Gf��,���o�I;3飀7�:;R���{\����
h!��c��`�nz�A����nY�4��j�[�I����)�t�[�hv㽲�s�W��z��aO1��2֏�Y�-M�32�$LKE���Q��o��ó��<�f�̏t�R��g���=7̱�����	M��Aq�-B�,�aζM�m�(nW���龦{��Z�r�eŚ9���s%��7F�����_��O0Ԓ�*S�L���^�k��M	��6��auM��K��KK��s&鮚E����(^��G ���m�S�zd����K�ZD!��`�'�K*m^k��ߐ�+t̗3Ȣh���-��z��0���-p��I�tCH+k�f�8�O-� �.���B ���<}|� p�.~��
�3N��L+�9On�H�f9؆�3��?+���?L�5ڄU�CY��3�}�\2���o�V��S>�q�q�>�p�ݙE���f����8��@=������#ǳ_۱��Q�m�Lt�����È��j7�T�Du���&�N��
{���^�W�u��Q5���N0�L� ����5
t��1fd�᱄��"s$�s$c
x�U�����h6�*�-��P.�Zg�o�Ot�ǫ���!�p�}��ڋ���(���*G��Z����Geq=����V�_/X/5[�� V��[zSA�ן���v�^)yw-�Pv�@�\��� $Yc�!��̞� <2�K#��Y}���k�$�b;cI
pu��C�șЁ�p��M��7Լ24g.��m��ES�̣6�,b��3V�
��/��*�\��5��/����ȑK~�]��%����^��-\��</��0�w0� ����rf9G|4�w�G��m�I�#��
�7 r��"�ٿ�UB>L����|�вy�I5ȯ��d����2���o~�[����	�/�\\���ֆ�s�S��l���F���P��;����e}��8�����<.���O~b`�CH��P�X\����o/OI�`�U������2d�e�kT�/����E�o̰){��˴���~�Ze���:��=Xa�O­y�%{9%���(��L��G�fy�ls¢�܍�LM���z����Dt��,7/��O�LԆ��M�[�r���C�yh�<��'�a�US@���)�BKnk"�]28-���pռ<��`�|=��2�$�d}C�D��W@�POO?�l����-�k����BT�����`�O��h �ix�a�t�\�
D��_d]]\���[$'��|�M�TD=:9i3�9��s��n��G�y<��0��5�m�B?����Rp1���u���B�k1�H!0_6�<�o�@*�?Y��S'�Ύ�OA?d���7��Jk�kp�ߝG�W�L ��A��b��9�������^Į�Ȃ�.���,"���6e����T�"o�ruvfQsߘ�~�a�����rg<Ֆ��A�[�%{��c�d1���ân���G��tŔ��C�
����,ϖv=��U���);��F���f�B $&H�N�u��O��á�x���M�Y�҉u�����Ќ"n�ľ�ʘ��<��X�#�X2}U�ƞ�F������P=�#i�%� W�|��3��i $X�W�ۢI!'��YX�S.�=j�zZ�+�	+NJ
i�"gzn�(5cW����'Η���e6V�5W1oSվ�ot�`��G�E�8���&�
�J!�)��(�7慶��@��`�42�e�BN�բ��{��A�?����q�v�o�vtj)�]7�Y��v�)Fk�9F�6�d�|�)eL��=�@w�Z�s��l,�G��@s�V��ه����y��Qd4�Q�e�ϟ��M9APm��l�� �%BA�˻pТ���O��=/*$��E	I1Jǲu�h�(�q5����/����[��Gq�dU�L�k�����ǐ�_ItŰs�����	�g}��I����X��0���"8dt�J����n��D(aw��:��'a�C��P��j��+7c$�&��\�J�1*�T��s�S�G
V�MeYN���"��t*y�ʪ��_4j?,e�g�*��!��9Z�kdŌl*��O���3���!���=OL �6��uxv��x�_���V|��\�_@I:Î4-�*�#Z��3;�	�?5��rݪ	�ܱ�rvM����nb�R��(�-��=K�)��-�Cm�7(4K��y���l���)��?�Lt���3b����:<5
�#F�"4�Q{��vH��1}�h��1ى�Thsj��@��ٕ�^/��]&9��"�bR��J��ō����NM�m��mȺI��E�4i	�W�>&�=��\��J+�Zj(�Y��*��|0>��3-ɏ�"��$j̞�����yA�ڂ	��-E�OA�fN��t1�N'$D��	��HV������\�g��$�Y���jG�@~��O?��R��V�p �~��~�f0&.�}�q�o?�)�q�2\f4,��T�gf6�۝/s3�~��a�=�Z�O w1�Cd;�9�Wq!�nh�����c�0ϳ@2���1[%��1�6�e|�O�AD\S�Z�r�v��r�@�]�����O5����7	�z?�iH�B/�"ZC�O�Q��V/�9�b���
ʁ�b[��L u�[�~�1��T��x4��"!X�{m�-(�Kb�(�����k
Mp��yeYY��+��� �Tn����eߵ��"�B릷�a�n�в���c8�Tq3�>@�^�q;H������x�#�@���6�d��=	�=6�|nh��p�g�U��+�������:ы��:���_`�R��Q#�G�9�Ƒq���������ٌ痷MҦ��F6�[g@����w�
��q���y	Okgݦl����8f�j�@n��y$��[�i������S�){� �9m�(�a�2�+:v�^�3\Ä��zR���9CI?��iV�9't�ʒ�՘�']�?;񲎛�qsb/�
٥`
/`�#�@.��uF��p�vĵu0�ۼs˨�j���F�ߒ�,2��V[6&dI�@��Kp��	5�V�ww��(,�f�p�$��18�������<�0�'��%�[����?Ď��+� S��@6x��Xvz&��N䢌N 7�"~Fш�N��n�D7�6λ��9�ą���p2�'�C�1z�����~Y.�~�%B*�aI�j�!sC�厡H�0�Ug߿S��J�!?�	k�f�!|�uak���)��8/�@d�1TkV��.[��F\�r�>7늸��b���#)n�c��S]=���ȧ9���r��Ųb�;t��H����1rwgݒ-$w�Ze��Zo��v{P�Qr��|�Ր0���G'+�KN��(�H��TR��DLpP�uD~6��{P�r���QF�\��1�L�M����!/;q�O��bW��g
�Tb�XI4��ol�����$a���'Z�ܚ�O�/Yn@~F>�Br=��ː��:c,2��n5L�+��5r�0�+���:=�B���[o��m�EGl���}�	�a��8�.b(7l�:�R�ѿ����g_C\�@p�V�@�G�z���fM�D���9��nTŕA*	�������铺"����eK�
�+/���Lȼ�48�za�_��\�^<  0���$H'r�m�[Lk��X2�O/>���TʚWF�$'.׽�T��
H���@�r���R�)�{�~S�����+��wߺB\�+c
�gn@�g���g�/\�nmՉ��e���*�V�ʦ=J�ۺ�f��]ק=Iy��m��Q��$��O:ڱ�b����\T?N�GSd�%LrWQ�����=��A��MMG��ϛ��i���J	&�N�F.�W���G��Ïp6ǐ`f��p�wE�$~$G�����H�*;#�|�3T�㦝�(s�tői��1GO>��H{.Ar����� 	�>�<Q�;I�$�0���uS��uOo����Uf+T�2�zEf������Ҧ� ��O�8��!Mfp��X��P�Ƀ�3�᫣�NP�4�E1��ϩܣ���8)��Z�«7bU�<|��4{�X*�St�ңf��I�AVTd��Jh�0���d��TX�bF��VJ�uGqy�#���ъ�tf*�����b�۲h�x��"������	�W�z��l	��7�q�@cs��V/�.��L�g�1�I���i�۞��$�CC�Q۬���M=cN��v�?����P�I�n���?7Ϩ�����JEp�D=j����.T�O7J��㠖0�=��]�r����0��Қ��àʌ��$���(�p&9��F��a��/�}��H xb������sn�W��&AtV��|�ԭ�c+��WvZJ0���N9��^��Pz-s�3R�}�s �dyA���֩��<�O�T��.K��/?�Xe�U���f^z43���S�d��JFek��h=����ɚ��6�r���;?����j_��R(�N��+����(C�"J�N��e���hEJ���hc�5�� �ơl�dh=��K%���G����RFz�iфa#'ٲS��
�R<'����[��
r�i��v�Md�=�H~���l�g�e&���;".~�~�L�䢪h� o@x���t��p���~u��eGaG�!��n��-��@VH�Xs�
�I��E,e���8%�sUʟ�yW�Q�-y�cxҲ�2�xeэ�m�[䵍�V�oX.��^*z�R��l��{�{|���
����f�xz���A~3��Q�q0~?��H86�)>k��
H���.�e ���d�^�6�6ZA�[.3N�16&t+�6�-e��$�,�v,�)>�N@H���ʪ�`,-ߨ��Y�M�	=�wE.YLx�$�4�bGj��%��Y ��Z�& ��)��[O�c�U�ձO�sW��͚�p֊=����:`��z�4H�<�礹�ҽ������ώ��DF��i�Ql��rD4�un���.�L�P�41zN0;����&� j/�$\���\��P_x���q���(��%��r���4�1���08CB�
��g�
s�l��f29�n��_A�����2��r�J��;� ?�PI\��vot3=d����=����Bٝ?������X:��5�)�� �N4����'��`S���?�+�&��$'�n���?�����n�245����_��.�ܖ���u��@��U�fQ�E(9%�fB�le�9���P=�ݹ�q������cG'��I�!���d��8�e]��P�����m ��s���S�Ǽ�ު��UPjt0�
���&Y�=/���<�[��#1�oph״�3�Z!{=��j�߮ͩ �y����u�H�ՃmP�7�h�vq6�bm�3�7!R�!E�2$�s��09��}��m� �gd�f�T��t$�.���)*�`��S��p� =�j��㕭]e;��5�(��80빕v�\۳��A�%'}5\;��:�/-!p��"��&@g{t|�SB�B�$Bw;��r��&�\��j���þ�&� )��UD�"�r�!��|�/} �%EDC��:I3~u�ȉy�L{��[J{�6o���(��1&
������mˣ�뻽����������eݯuK\)���PɄ/&��0Z:���E���-I-�k
�)"Csݡ��S���'�.>�����O���L�9��'�-��O�;k_����x^�	�^�o�F�]h;��`��������}��鼐�Dz{ȃ�
5��.���}�1����2�B'ZH�$�*�Tw�X_C��g���w��?�ʨ��(<K5�,c�\۸�x����g�8��J�>qC������YaH���*<���.��pEe��!�@0�<�B]*�[0�A��v�tKh�VPw�\>˩���{�Ҵ�Q������֭��&3���HF�dAks�Ԛ	��RL�������0�bfi� �u=���!x�?+G��r�a>�1+�lˆ�:u���k��n�}*���J`=���ϼj�31DőEl��&�G&ek�#:X��%�si5P\�����!U���|�Z���*�v���Miь�O`��6[��D��/�~�}�'���`"Ҷ.z�0<���A&�V�|�L��P
z�H�B�`����,Ͽ�,U�ߢ=�Np����������ԩ��4q7Җ����+�%8��{���Ǯ�O3ɓg0U��>@��|C@"
�Z���W�����B	�X]j�lM
�p���HЁxw9��������w�ggh�|����~2�3��.4�i_{zL�sz��8��q#[�N��ɷ��;��t��'&ų���_��u�N�Ͽ�^P���,,x�>��42��E+-)6
�#?�_w������D��g���K6w��,��Z�x>�U
۬�͖7bH�eh;�ՕTN�uE ���}Vw�,Q�������}ɫ�˕��h��e���9�X̍���W6�0'�r�hY��K�Z1=fP+����6�M�#�Ay}�h!pP��Q���-��?�Iz��v�t��qNIU�䃛܈t3�����7�����p�a9ѽ��oh#g�2���b�Y^��j]&5\���l���E:�u�@��ҵ{Ճ46��ѩ���2�Gp�Z��(l�U�]ޘ���߶J��[��}��݇��*�ZК�<l�A7i1�{:y˚��V-��3�U�����^���\x������������� ���Sx:����FG�_5�}���^5��I��� �LZ'�љ�j%:	�gv��`Y�I~N�Rܟ�X���������B�&�㷛�_GM�5?CQ���S��2dz�}���ԨJ	�>r�� ��}�AX@rl��!g�??T�j/t+��,ŝv�e�+�9��.��֥ƬCLr:�������~�m'���x[�n���u�� ^�.:FIď6��߈}�]r�5����X�lQ)/�ߕ����8	Y�T������1����E<*��u��I��sZ�4Buh=��O����!9�j�-�04]�'jGT����eo����dH�+�f3I��;�5Rj*�P}E�a�:׿K�N�%��}�����c��dX����f��;����U�o�Y�T�)nl��>����g�j�]:VX�3s#�T��0ȨoԞ귀i[�!Hu�AH�9v����]#6��Љ?^ZR`�'y���͉ ��l%�랢c��*k��O���"�ʹq��[M���0|�s��1�|6_	6'�\.��,Z@6\$������*9���Íx� /�Z����[�O���+�qn;g� ޶��!^�R}�Ė��ݛ��Ď �#*L��>�B�����&#�B�O���L��\2hpم4e�n��{C�����`�x\��NV�Mw��VKi�*�!N^M[˕�p^;D[�T�oЫ�M�LH��6�P�A�/��]�I�f'��	�H�[�.�&?|��.k@N��no,T(W�%�?L�D�� ts�|u� �)�V�~D���}+ �';l��?4���T��ె��yw)}.���*�B�ۅu�>�����ߘ��
���B�4���6��wxz}��OZ�݉�����o��DM;�	~�.�H�h��U�W�C�B��孵,d��o�����L�����o���`ɾ)`�b��^�f�v������1��X�[�@n���s[y���@#y���eqq$��-�%�B����&Rd�[ ��zuZ#�,�a����G��K+�M�ǿ�3��*U����'
l�P%��)oe�p.�&A�41+=v��)I����T
2`+���o����+ۑzf��$�>���`�ô0��t���xfvL�}�	�#U��A��>���e�������
�ßл�NX��<��}��Տ���WAD ��Ĩ3�m���U��vܤNi�F��
U����^� H��74Z�Ȋ#��Ӽ�q��6�(�M��2���H�
�iK��G� ρ5�2q�ޱV���X�K�xU�r���F��b��~�V3J�B� j����d���A��lp;�{�B��*u*ª��z�4-]���p$��A,�s3�/�%��3[n�R��~��]��8I�huB�(�7�¯^c�@���r[;��k�pjH���rJr�B{S���c�|!:i��4�I��4�i�3�;���|�.�G���Y���۵U����;#'���B;�B�`�ڔg̅qW(���ʦI�G{} �����C�s��MBl�{nԓg���ˍ�����ର�[��B����3��}�*k�v���Wŵd��3�Z:E�1"@x}�}bf=� )�h�`�TR	e�*E��F*�~��yR�#�_�1r]��70d�B��?ڮ(���Rx4b�X������X�kh��D�����M��c|G��6�ω�<>!�'��W��o��UAH"D�c�
�>�^J�6R�B�!�l��	I��2��}�d�r�#�_#������e�Z��ma� �~��ݫ�Hc����HGc[n���322b�����1-��_<&��.�{�{���_���I�B��W��蘊�w�k.`6��ʱ��{���?��K,i�ԍQ_۲���F���]�W���C|��6�i���їJ�!~!JJ� J�����8柊#i�K��
�v�:d����9��=r�Ҋ�O�@���p��1 �]���!n�Ny����kN��J3e��ȼ�V�P�>R�y�ѡS����ֽ�l�����3��Qgw���*`X��HW������ȋ<mI���W6H1��<ёW*g�UX��k3�҈>:���=U�7���y��v��K�e@@lV�z�9ϛ���}�߇8�i!��W
�e�@�mK71&r=�C���1����s:���x$�h[5�۴wL��d\ϫ���Zl#IC�?X�F�|���z�P�c���N�}���G�W"�6���%߼���H:��2��*q�J�8a���Zi�8��e}��j<�Ø�u�9��[Ì �'r 4�IpG�<���s�%�Pv&��<�隠�}���Fp֝�֐l��K'�JA��a^����[mNo�8u'���I,�U�(��	���/�=�0f�FGs���ce�����s�gɡ�G�ۄ�gBL�ʜ�1�ޛR���I���w����K�z��6��]�����/��\��uY���@�MG�|
a+_���w)�!�+P3��!h4�o�/��-��)?{�,�0r�^)>�^��sn��udّ��g*�eJ���ˠݐ�7�	'dj"Z��1��Х�*�ܛj�>Z2�|λ{�?.��Q{�U4�NG���QFՆ}���$�cww��>2`.q�=��5�<.V\ukgۙ����}W1L��\̨	B01K�[Fj���#PV�<^��CzP��锂^�Ī�r� O��f&B_Uu���\��wbJ;�ozю����:^����8�l���+�O�����::Y�7Tֹu�79o�l!�)�����N�9�c����W<�t�bmEu➳�q}Y=�6�Ǽ眶�<����F&KQ`/�6속�fQh��:J�{
��"�0�	vI��������e([�G�<ғO,��l��6q�:p��a����@l�������m�	-��o��������~}Q��s�u]Q$�8�W�v�MԒO�-�$� �n��t�v��p<x�""k(�?gH&�"��z�pȕ�ނ��Cڏ��o���X�����K<�O��`��r�>����-b ���7p�������y�������6��%�Ű��7^W6���ۀ'��*�M�'��&]?��B��ﷂ5 ^�9��M���Y�\WJS����:c�t�5���~)a�cq��)`\�/�ۛ~�1����4�����4ቱ�(�0�7F��P>����K����؉�]��DՁ��54�̊��XN�V�+�_X��^��Z7Q�$�qZ�;3`f��mGS͘��˾)���r��b�����;���r�����X�Ц*�p;3S8J�Xu���*���
sE�e�@�x����
�aȞ��w��b���l.�Ǹq��r���F,�5�۶Ob&���ms�j��kU8�|��6>��)d�X����B��Zi�+f���QI�sO@8I������#6�&��g�2Y�Lz��g~�\h�DaV���
:PV�I�QQ��R����J�@��Pun��+i���(��"���Vr����e*�g�	5*,��\D��*�>ź�\uT��D��#0�K���qEZ��i�.�N*X�n�x�9�5,����,�M���۹;�:P������YooK�}]�X3�Me)�D�x�n����������T|��h�ǒ`�iR����-"Xkaq_#A��$�d"��k����*H�
M����nn3�Es�G�$�ZfF!.I�A�
3H�~�(�An2��2X^!ߝ��{�}��D�<(G=�A,��ZC�=U��՚怇ur��Z��5,D�NE��~��ͭm(��������<�@�{6�Vr��ל@W��hX�}��J����uU�pG�jDҨܺ���V���k5Su|�?Gk+$���Im�Z2�Xw���j3�y��&�=�˓�"h���(Wjc�jR�tn���fܨur�uZc�����Z�����0z1�p�E�8"�c�ңcA�C`Q����8�e^�����%B��cKE�X���
_��%��l��n�)R�2 �d-�.8ò�B1=� ��Ԃʞp����HF�6��d�ۛ�K��`��}nc��@�6wg}�I���}Ђի͆��|oZ�x�P���kqn���k���r�g�P���l?
�
bu�� rG��H̢Q�+#!Z��~�Gk�����>���H��C4��:֥���r98��|��1��{ת
��D �:7#���~�뿩�|�=�ZQ�U�XH��������C�ٸ�>��DY�cg����4�/H��p9�k�1y�A�2��G�@�O�&����r�(#����oG̈M�7��Y��|��Iy�i%�8�Ml�?��A�w�r��"��o�i^�ϰ���{��)9�P��,�ܗJTI�ڏ�*����j9k�>��Z�GM�Rj+�c���ǉWEw���]2Q��Ƞ�s��[Ъ�M]ج�AK��廬�N�?�A߱d9(���-@��l:T�8ՀՖ�A��̯�Y'�!'ۆP�����oз�C@+�(%�8u�U�����he��Ӫ�"�R\ +��x�	 �l�S	3�7r1��7�
U���]RwD>/������{�����ͩ$��y���������Q���G����gQ����	��bz^XRm]�i��N/�:2�[o��x��躧���ɷy�{�7J3�y֯v�ӡ��j>#(�� ����K<~S(�=�6��ӭ���z�ơ�6}�1m<�nH�x��t�Ld|HM�돏L3U�,n^��/��x;fS� �j���zJr���?)����)t�Ǚ���n�<�%Å���7׽�����'���W�daR}�
X��h꺜�v�J̟��]Hi�vY�A��h��ۊ%L먍Ų1�w�jʧ�Wq�d�C?��N��������V�J+�Zn۳-�~O�(�$~z
�@��n����u(���Y����M��_~����S�C�ef��%�7�-V�g�$>a%ë�. �r�A&�*Ìe(�����YeJ �n2z	&-��Y��֛E;Yˌ��e13C&��6� ��L%.W=|�[�g��I��W�}�T����|َ;�ףa/3O[MQ�H�W�!��8��(K䜳����=z���5/����S.�(��Fꆬ�H�ȣ<[`�GX�HMI���n85i[	�Í։+τ�jDz��'���۬��_Ō��D�L��T[,L͔1I֯��(�I��w�x�$خ73��l�]x��.�,"]��e6
�	��I��-+ȗ��hP�,�E����j@w���2�Yf�`�<d�IY��-p�]�+�@�t�O6&�,_����!�Fq�� �P\Ou��:�[��.��=��Q	�.�e������%u?���!v���Uo����#4΀qBg�?< ���	��I�<
�e*�-_��G\���=�.#,
3 �,Ӻ�����7V3��TX�6��b!���/�j��*��)H�Rjf{��=ԸiI_�(�;7%8�?����9��K�8��GF���9���6M��M$��+�g�rQ�0N�28�W�r��J�ڝT�b��v��N�����S�N�&�ncK7�@���Y��
�q��J$�]�c�h�/��!���ض5�� �[���>Ҡ������ٴ|��sX�ǚk}�80*�
`�#V��'�o��P@;��w�@����8 2�1�F�a�.rC���B������5d8�ס��c��ۤ�i��NU[A��Ś^d�`;�<nL��M�~O�y�ҞT�M���_�@��B���$̓\�5�}	����J ̧%3c��y�,�ث(�b���� �B�+V*]�@�}�4J�,��kK�c�"�O9����?�՘��d�zjU�u��8�&��6�ĉ#u���V)�� :��@n%u{�[�N �0>G7�#�<B{�T������y�<����o\}�P�I�IoŮ�Qb�_��ԞkL��Ll#�[����z����x�����'3K#UE��%�>��(�)�z23Ɵa(�]fA^8a6Fi1Btzᒆ_Sx�	���� V�S�r������H�l�#P��vT���1��Ȏ�H�	�/Ж��J���Z2����k�g�6�;���'���7I��^�\�O�Z_<�'UW��	t}�fS�f>\uE��.�&�y�O*�F]���s+ju�Q�_>$D��;���2ZF �?O�����~6p�հ���� T��
�H�1"ie�GE��p&hZ&��H��vNR��g�5o���ƺ|C\9j�_�s7h�&�˚l�3s�$"�d�օWQ���[���� �H�&[*������J��0������J�w͚�(eD��Ւe��Z�ck5�]J�t��HGX�i	�qh?+�v���n��WfO��6��K�&�����?��n>�)��Ϙ�����2�+����v�8���[��,S�7�;�VF%�U)bX�g����g��y�?�"�Y��|(�,{5X�I S����ŝ���|?�ڮ�3^v���ٞ�s(4P�)�T5�J����L�8u��e���JY���4�
h��(��(b�� ���2�O ������]���g�    YZ