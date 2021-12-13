#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3421236707"
MD5="036ca14e447b9e19222cc68ed8496956"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25556"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 15:01:53 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���c�] �}��1Dd]����P�t�D�"ێ:��c��3XCH�÷���36��xM)����ͤ�SJ�����x*�.�u[dp�$`����c neV��"��X@������;knf�V��գ=I`��D�̟�C�5^dٱ����R��(�)uS���a����"s���!JK#���� ��!v�T1(N_�v4(ڐ���H�gz���J��� ~���1���Q;|T쪎��BN�>Um+i���#P��uqi�e���ڏ�UN�b� ����%���� ��m��'�A�WF�� �CL��)m��&ǘ"��*'�m�)�}�R�8���\�E\�\� ^*�b9��G��1�����B$�W��YȲl�G�!����Q�m��e]|�>p�ćP��,�5�Izs�@~W��"?�����A��'�b���b|�3��\�oB�+}���Yb{t�_�:A�%�:�5��9������у��� �nN~c�>e� *K�ɑ��U	AG���v���$��k��S����Ѷ�_�$v&�p�����z��~/0��w��#T]�( ��������в���}�<߄��m����a_�fס��1?�F�gl�.ss�oVt�����p���8^�E�^I
�o�t�G�9A�eT��F�%t�2�n)xi�%�f x��S@�"/A��mj��I�I���𣂍U�Alc����3|���ω�Ԗρ�_��О3>�לY|Ý҈���$����S�t�'�n~$��P���6Ne�ޮ�Y���ȿS�������ΟNnr} ��	V�C�p�.d3I�<h6��q-��d�ą�v+z^m����c�Y����sL��\��nG-�ң+xvU؀�lP�D�yS����[$�F@�������|Q��O���Fë�nr&ޏI^6\����eC����H���\@"�͗�/��ƪ����C��]�{�<o���5��(|'$��	�t 3=���k�	m<�Պ}�y.�q�-"՞캰j�zI�:�<[+�P�pe��B�B��ŗdD��3���Hvo��T��)�_N�M*}�˯��稖�\�f76�Y�So�^�2^�f�n3�=����zW<�+�g�
)3�C�f��}Q<}̮\��h��`�
!�ƻ�t�5�����۽�U�$���?<������j<a�+1G���S/���|�F��T�.�B��1�1�d)�!o2�+q`e.�Dr<ԯ��8��xV�sT\%�g��/Ktz�K�[ä93���1d\��
o��d�,@@	Pބ�7�'5y�~�Pܦ��+�5�X9�|�~��_���ٰ!�aUl+s���a���;��=���-��?���m�Cg���q�[Rs�(����f:@��@!/���%���w�3Z(�G7�!��o�L����Nr���bo{��o�����.����Y�\3CH�T�y�)4j�E��7�i�"������n��F��+��UEOvO����U*���`�
�c�0��]{�H'�X{뿰7�=���N<�'�4~�OYxI������~��Y�'I�����Z�y������h4�a���.��i����^����b]�A�/I����)��ʴ ��|,�`8�u�,�D��k��+�Ϥ��Z'x�kF�Z���U>��.IP�4����x�.-���ۻ��R����{���<��?�i9&��"�4�.�w;��R�nT+~����������d}=Ym�}7�U�ZA��];�� ��>����9�+�t��Q<�F^g >��ȣXMW�Q:����񂪀ɳ�����2y�:KW�����@����S�D���&P[�*�@�ڿ�j�5B�G����Ix6��7�f9��<�x���+x��a�\�ڱ��RU�R�%b�ܡ����t��U2�Jj�-�V�n9�gQҙ[z���Eq-���b�l�)s�q�`Dk�����)���;͸�y*��J�> ���S��>>|I˒��X�R�F�i&��#���|�e{�[&X�U��7��=P��*�]���ibzXUˡ�K4�����^oUY�$+��R���?��Mn'�{��-e6 ���n:��(`�xv6na�O�>{+KfD�/5�s�^nT.>Ҭ�ž���Ih�y@A(��Q��᪳�m$A0g_�F�!�9?,t(��p���씆-�s�m�<�(G��B{)|"��r��'ɞ(��� ]��~��H(޾�U� /;΍mH�8�f�������`{�@�%?+�[� @���ëۤ^����g���bPRV��,��㫖B�oﶘ�8�0��ur*1
kBC!��;^T��^��m|ϗ4+(��@�6M�K����4�l���rC1��|�	�d��	"M���+%�ۢ����{�����q��K��SB|�����X4W���p���D�8�zGK��~~�b'��./��b�1𞁠A�RϚYYH8t����^ٌZ{-�e�������+Yt#�lʯ(�U(�)�\��k'�rֻ�o��ځ�}]�y;���$Gy�Om1�Ռ�� t��+Þ�~1��,�Q0�
�N�����=�ځ�7g����V�/OV:W�Usk7����?8����=��tF*�&h�?4�,����z�<N0z|��o�P@����Iώ�Ɣ�	�Ɓ?	�	ٜrYxk��㭛bn�@��[?��<�tg���>v�{���a�-I7�y\j�􀸩T0���PCQp�/��z�#�����I����}�|�G{�S�7p \N��7WT���3�p��Z(��w�`}Mr�ؘ��
�w3�l�4���
|���}�����U'���k���q�6���O��eJ���+-5�o����,�L��*v���]L��o���R��� k&DUY������s�~0��+�e����Nf���/C0垪������{><da�%1G�` iI��ݭ%bMg0{U񗎰-���� ���K0��h�W�ķꕁ�d��Q� ��[�b���*�KJ��]�U����v�<�E}˺f���G�A�I%sP�v�������T��oxm5t����2�b�=��h�π4V�*Iq��9�?�;'�.R�;��S��R*��y2M;�����L���d��h�ۯ�ys�?�I�gCiǶv2���һ�����|�3|z?:W��FM��x<O��tؤ���.	��y��	��L��ϒ�6��-�4G�����q�P��<��3��t%}mI��K���x�Q��h=�U&*1�ҴFw�AOD�A�Ra?䘝uQ�~/���m�2mq'�s>O���y7��'3��IN�lM����S�F�	�7,��G�ϐ�����Hk��r��������N*�X<�!�kwl�֕0��Tx��(��qvd����ˊz��ҏ��?|��Ǐ4C͊�	 $:K�:�N�X���?&,�B�dC��L�8U�`U�2��5�4U��#.�@&Xz�"�Ԋ#ϒ��� ��J���>\�`O�|�?f� Lm�����PeM��9�nw=�0�v+�(���R�Ȩ�V|<�Fk����p���vh�ﴡ��B��+,��Ym�sH%�	��%W �z{����Q� Dtm��~��Ĝ�@��a����-6�x|�}�U�wަ���Z��x���li�6g�}�xv��̒�OS�1<�����T&*�M�N�U�h�楄������36�m�0M�f��<<�p����u{P��5���`���՜���&bu+k��q܆q0�����i�J�Ԩ�:��)m�Ba���85`��qJj�i;��4�	'Nƥ1
^�PN0�_�R�yw%ϲ�s�s���ɣ2�O���Q3�D��;���^�ju�>�A��p1>]����i]Ȭ����"G	���D*W(��u3a~u��(ջ�����ѿ��VcO�J�,hyW��:�\��4�5���O5_kU���������Ȱ�Ze�w�x�}m��0��s���(w���v�@�;�I+�4k�(��w?-�����a��O�s!d��S޶dtؾd��(�,��0��`-�u�&��I����!���x9(9>�ӈ�������X�]y����FH�S#��op�1>T���
!���Ɉ���^#�Zϐ��19:�/(; V��� o%l����c���1�p�O�?"ex?�8��]�u33I#p=E��gv8�O�8�����Ke�2�=?��t	ߙ�f��Ԙ >~�`�S��;�{!��8	����M�ki;�d,��H�(��AU�2D�KTZx� ����}�)���[$���)-䆥E
+������&7�&B���F�}2��u��������'R����|5^g��Y� ��Zo�L�Tf�#ig|��O�G�&*�́�N
�
T�b�Ĵ�;��h������� �q*�#Z#v1s�]9 �xS�8c�O
[���%��.m�oY��?�{ED��B�w��푳�-^����o�3=��q-Gˑ�������JwZ��Ɵ�_�v�Of�� vZY�X���������	F	_�e�\r꧸f%�����!?�Ym���	^L���CE*D]�͗9W߷�0��rR�Y���� o�rdǁ��)�h����#c᪏��d
~v��EtA�q!���t2��~
�e�ͼ��R����/)!Η�W^y!~�8	V���X��k��P�t�2V<j���&w�j�i���v ��_9y�#�}��7ʜHT�9,,�� -�S��$���4O�;�s$ �p
� n�E5є���=��XPn{{�'n��~�b���9�Y��rYc�z�x���W�UA��ȕ�&�4�Z𷂱H���"�uأۘ�%C�cH��SA����X/�0+����,:x#�Һ���x���X֔�X��d�N����J��%��i����4WQ"=�M�u�N�>�\������4 �Gc�X3���x
����Dݾ�j9[��gɐ��ly����@��پ�(I�In������=����a��؛7+��GU���D���N�����d�	<z�H��x�X���!�IB1P���2K�`��v�y����/	�f��4���:��(����f��R���ץ����l8�'��٤]���ғC�(����b��0,V�x������Z��x�v��C�"k��ry��̩�O}�q�6�k��@�f�������nx?ғ�β�o�M���z�l�/���Qh�zwެ�4�
�$���,=���J�˭k���!�,�o���S�0����R���4���T�S-�S�uA�} ��ʨ��r�4�M�qL �*OA�TxjSǃ5&zO-gQۚfa�eA������ �t��_T�0�_�����fۏ�y�/�b85�E���!�6��g��
,��Љ����%�h��\g��C�J�<_��Ǹ�x�����j%�'I`Y �?a�[��e9T(߱�Nqs����T��h�ҜƬ��֔(p�8�j�ɹ.!�Ioۈ��5K���#1�����n# ˅ހ�P3�m��Z��v�q"
���B	�&)��(���������$�����?W���l�`�?����z���]����4��M_�g�ji�T&{ܭ�,��҆<cX��f�۷m*CXN��eǜ���ů�1f(ܟw�	�x(�e�ƃ;�oo7.=���6�_��[q���ْ���U�}ϑ�� ��_��CK��x���*kTu�*�(��^	��;>��������M�m�� �[�5�&4�וXi�O���f�L>���L�nC7�G)�d��#�P^=���\_aS�*Zќ��a߂�M��$,L�bM<�h�q�l<�0-�
����V	zM
����a��B�nӥ4��'�80�[�@j�\W�~��?�r��;^�F\�C�u��j-r�=ݽ�4����=݄I�?ʓ"57�6�tQ.1�UG|Z�>��:��c�FI{6ʄރ��F���>�Q�7�H�e�Ar�c������E��}��?y;��;^(�������� ���|oa��F�LǊK-�5��*����}�Hξ9�N�iu�Ṳ�e�ixL���n>���V�t��Ɵ�RD_&;G���ʊ������pG0�~��O^�|�M���O/X>���=3MN������������5�O�e-�uZq�Ta���$��e��'
�^���I� w�a��:�v��o�-�3�ܝ�j]JC�v�wd�o��^J6�+W�t�c9ă��F��l@�dE3Z�P;�G��^��r}��81�K��A k9c^��d���W�n*�����'5Qv(~PF20�@��|O8�YT��t�?�@r�ZoFv�EA-�9~ k5�|rp���f =H<n�%�z���sT�זD'�� ���2��O�eǵK*=So���_�V"ǐd�����i�X�*�ZO����Rۭ/��w��_ܷI��=��ϑ���j�� �L�ug�!g���b%d��h�x�m��~�h7��
!��A�/>��Gx�.�G�9�?;�<��b�B�0ҭw@���������d»���*z��G�Y�)�
!o��<�9��&�|NG�����,�eq�[irҎ~6�r( �}&��5���� ��^y�D];|�L�]���pn�d ����}ǑTRK�ǚn<�K� �������M���a~ 콽����z����m��s�D�3ep"sZ��a ?�WI���ԧպ9�(1ܷ��C��ѱ?��t���}'햽2z�;�#f%g�����s&L����p���ø\GǏBM]�e@����"Y>4��
 `��J��'��<�=���'��N d�Ĥ,h؁_�;Rj9��F��d����5�D�E瞺�勎�j�	�Ѝ _�?�	)�)������4jc���27*79��fz�2�Ѱ�@�ܣ�ݐs��)Fjwu���&?��=���.��٤y*V+꒦m�ۣq���#W�1�ܩ	�q����C��f�jP��8�شҪE���=�T��H��R�wS"�x�\U��x��~$^@$O�y���R�Z�86�f�`Tq���
`f�"s-9�,N��q�
�}�BÆ�����أ�|�='���#_Mk�V����"��z�{�����E���J�v�k,�;Ƌ\�n�� ɠnd��Ir��*����o���>f���1��}IȮ�ڊ��h��D�!�;���\]>�n�*� [,�9��f�3&�D�����]R�DfE;#-�AQ��ȫ�c���,�#f�0�{$#����jA8�<�z I�C�s�+׈A!J�Վ݆���}]?��u�C6a�p�4�NlB))�g�)��QF�k_,��0f� #�^��]����!�"ۜ���o8�[F�J�~��0&����]2I�3?�� ��>t���I5U���Wy�C/c��DURn��� �%��|JS��u.6�X���`��D���Z#k�E�2�9\Z
FY	�7/�g����L�97Q���艍����P&@\�w�������ߜ�Gϟ��a�Ջ���\P�'�e)"0т�uhQ�
�w>+e���05���'�P<���5ԋ��<�L��Cr�Ct���g��4X7ɡڪ\����h��/1�:f�;i��>V�U�Ùra�g�K�<��u|Yr��0
�C������fM�ab��4��w�f�����tv�F>Α��������WvR�~���d�w�ߓ�__h��r{WW�/��v���
�=�WTJܾ)	{3$��x6ё7������qB7�)q�Eg1���RK6/����pd4�Q�f~�X�Hk^�#�wXf����|{U�l(�l�N��΢Ѯa_�I�ˊA�I�tS�����dTW<C'�����br�~���~6�m,7T���o��o��dU�Mb������e'F��h<�=�#�v@,�E�����(�����<}��u�Ix�������Sn�I^�ͧ���m�@#�99�EEQ]S����x	k>���FG�����5e�xl��nP.�I!&S���*���| �Hׇ�'�P4N2љ��Fi�ў�Ǒ�j��(wߠD�\����f��igqx�K��������8�~����7��پ"��@�0~X�ň´OJ1�:�i��K����hבY�/���WM���Q>|�-l�i>���~{�[�<6�<��Ml�7����=�����v�K���(�H�$���e���:��{FO����?��H9-+C�^b�`�����Y��l��5�WD���c�[ɱI���O�^����hP��k��n�Ȇ2��p LS�i'�z����p���0�YT@Q�X@c�Y�]�K`��@� ���UΟ_�S�v;�u5�O���ʛ���/��h�s��R��=9�Zu> P[��$=Zj�����%3��w�B�!�~W��8H5�8}Rd0@�������'*2��ȏh�D�KN{�ɴa���u�`cr���m�;���1%���ڭ���[U�����P�~�����i��|�[����Xë�ky�� �y�~bW�	#nh6Q>��X#�[�J���"���L��W�|n�v`Q�s�G��G�a1n�:��l�-����e"|�2�n�S<�:P��6�
�~�a�tKpH���H�|ੇF�s�y"6��M s
��;��!��8��������#��c5z����0�����A(gnoO:���t�P��Ъ�fE�t=��2O�ޗ8���H��\����j�����g�NK�y��Y}�����%R�M�m���m��M~���0�V฾����b��Y�*������L޶�ݱ�կ1
�%���	�}P	28�|a���Ŏ��?�"ޥz�&��0�&3�I��
�~��!��ߧ�$�<������I���Q�E��G��ZE^Л���d�,َ���׮)�u<V櫍�z��zط���?UG�K�������+np�ew�
F���f�[�-�������k��2�Yk�z��.���+v�g��:T2�aՓkD�у����l�ޡc��;�ya4�KW�Er��Ƌ�;:uz�w�=%����2�2$A���V���?=�]  ��"&��T�0"[�k�5ڴ����}�WHj,zfL���6���K�"t�� t�k��{�Q���|���n�A]���*��ʱ�r󍹡dw�t����WHA4"ϴ��?� _��E�Zy�Z��F6�j̥���o����r2��9z#���L1W��ŧ���~/S��o^��r2�`;�/�7.��L;� ���7~?{ ԯ���W)!>�K{�+�e�C1�aD�S(9��j�����8)�,so�����f��a�n��*���mQ��L/����ʓ�s�ђ�D�h�e�
5�#~�|2�&q��ġ?Q�פ��AyQ'ln��]��x�-A�1z�~�kФB:!�l��5�g�J��ݔ&P4�W7���p��2'`������1M�#(@v����
�7Q��6��r_&��C4\���31�a�c�u�v�f~f�������r�����4����q[H��֓��� �e��2|L�T��Gw����f�Q>p�\�j^�?�014��2���Бe�m�1xd����f꺾X��9���NӰ��rd�f��d4`T7��	J#��U$�|��7ޫ���=jB�W�)�/e�m�m�m�͞}P�V�C�ױ���-���&wK��잍��x #&�,�g�ʵWl�80�z?(�E}��*]]!�k�4�ˡ5��{�tTrE��R	 '
ųYr���RJxt��B��BŮdS�����n�s�"�^�s;2�}c2�T�������WUQ-�f8���w!��P�E��|B��7���t�(;!�s�A��@U��g)~��S��i��Y]�+���+��=��

��x��:�h�zqp@�F��gJ�mt��� ���s9PK��\#�٦3m~����X=XЧ*�=O݊��Hu�� d&c[�{���_�Rf�Rl����3�д��&��ȓV�P=�b̽f@����M��
`���_�����r�H(Ժ��N�/����.wlsӸ�=X
�H��ZL ��Y��z`c]CH��7(�X�3�Cd��|���������i�WIP{u���AfF޳����5Ð8U�~���X�Q�v�L�E/}�q>��	OY�ː�n�,���Cxr�H�ɺ��n�w+K-�4-��z}�6 ������;���sQ�l�Gxb�&��/�=��K�߬�g�ئ���<�ɀ��8+UM����L��U Ҁ�P���MC=��m^���0\�Y8����{L}l�*�T�c�]yc�^L�]%JM�.���)�'�i ��GVF�z�
�u�P9����Smw1LSe�DA�5>M8g�N� ��}�c���M��L7�lk]����|�c�`+�nl3`)��!^�����p�uA�5��FxQL����>6n��M"�e�l��Q�9�E���,	���r�~(]���,�md�?��J�.(Ǳ��L��������,!�����`H��m�}��e�usEwxo��z��j/�-�!F�y�j��6�9g��O�#�؛�FS7�5lǵ�4r��ax�������y�j�0qc���^U��T�s�����ŞD!�V��j�@^ A#a���v��6t�B��(3Z�Z[�fz�Twq�).<Y��Ev�F��d��s�ܜר��	Az�X:~J*y����'L�ſ�sF�8��^6l�g�MI��K��d�5���2�v�V� w���������H4����rYx����������+7�����l�*�>�={�ԱH�@����8�����|=�����C�&k8<;pc��2Q�v��X[M4��7b����\�p"�H�\yߧP�*�݈i�F�n-�H&b�`K|��X�qdNg��o�MiDb'��v=Ř���
�N�մ�R����r�J���r;�<L�_�G��f��.��}G�?��acn�y�_nyŀ�����;E_dz�z��P[����ۄF�Ka�1�vj�@�	� ��^��t���[�v��zyv��:�t�s俋�!����>A�Դs�o/	��Ѩ�,��yJ�l
�5��s�X�<1:5�O|������guj�m�k�+'��/�Ul����������F8e����5������Wk�\�x#��K���lB8���e�2.5����[OT0�k�8�O?�֜��:�e��W;IM�3\��>�H]؇S9Q�T���~�G⢼s"�A�:�ZO��D[��&`Ý)d��Y�9˷�m7�=�.}�+^��H*<�\���g�i�a�d�\���	8���P�����iZ��H7�Up*`#4)�^�iQc%�z��2�������L�O��������<�+��g�,>OX�Dj��cŶ�P�B`!��3]]�@pB{�S=L!�H��Ih Ѳ~K�G_���V��(��t~��u��H�p��	؝��`?\�2P5�U��!��������I,�S��^��)E��/�&Se?� ]�WP��F���q��E���Q��O��+���Ռ�� �������w
3i��Č����`��R� ��Y��� ���n��[�T�cbU(�gǝSV��A����6�
��(¶i�~��X�ߋ-# ���iP�����e��/M?"�e�~&�p���1p�uLf7���sѯ�1��K�bٽk���ۓ	�����؛����H�A7\.	M�M��ʯ�gg������½��+ak�q��LO���2y/H�:�^Q�cߡ
�p􀢺m@��Q���z�v�A���!��<�-�(U5+���eviv
��%ճ�H7I�ס���PԳ�����\����J~pC�V�H-m(M&E���ԺѶ�#Xne�OM���\�7y���K�Ϊ�Y��۸M�f��s�k.Y,�̓dr�HoրNJ�˚p�n�Dr�h�Bފ9'7o�����j�D�r�]�n�ԣ��\Wndx�������;N^8���2����|�X�X�SJ�K����9���1+ ��&d�����u;�9ͅ���)�B+��W?u�M�-LJēK��K!�!�3c(��	`�]2Ik`ܵ� �=�%�-p��~��ȯc51�߲��Fd���7Ӝ��zOI����h�5*1���M�]�Rဈ; o � N��-��y�C}.��Ae'�թ
|OF�zA�IxmDI�؋\��CJ�3�v�ґt����=L�a�d�|Yq]�#�.H�G�����`h����U�poB*Cs�
fΨ9�dܤ�z��}��H��,vA݌h�eݮ��]Bk#T��7���Lv�↌\ÖD ��%V���I�RB}Kz���i�LU��Jܕ�����+k�������h b���3Bk��ֲ^O�grf��Q�v'�
������q��&��Rh�����	־|ٚI�x�GTu$�r��?��k�<ac���&�8]��n`��1!�R/��Y���N�9�f�^!��WJE�6�g�~� �����쾖��v��|)O�m�*�Z���7���Z�B�07����e�L�R�S��"���)�����4�m�?$"5;G��b k/nL�'��"D�*k(�o�xPRx��%��򊖸Cw`���i����au�Q��]��D�-"Q6�J��n۰Y¸�ө
{��#������vl"ghQ.Yd�K�8;�H���a`�m%��V{SN6�ط�gx���z�8h��̬�ʂ�w���VPͪ�=�����2�fe����o�YVV%�ڴy�N5�lsqfL x���7�u�����ϋ�|��7����_@�� ��#C���~�Pބ�.�+������Jn6@[H�v�/8P�����B���Dl�ĵ�2$��o��9 �2��$����.�$w��4_�� <��B��G�	ߥ%��̟,���|����g���TN��f��5�J�����ڐ�L��c 89�M/�|�c�Bw|j;�1RzS�r`,�)9��ï9K��lKBGP�v�W�3�|X��֫��H�lP�`ʁ������sxTl�2����Βb��9j?O� �!��o.<�����Z/g@A��9���C;`��q���r�	�_N�>����4������xkc���nB���	Os�K���k˾�LB��)�L�e��A���# �]w�O����Q�I7z#��VKEz�X�A\�AT8��L]���5���9QL�gb�8/�7#�U!)?�4����BC(`��0�5�����2�;wO�p��L�E#ݏ���!EظA��S���ʶO����ʈN-śӿ�aP������rз2��)\f���4�k�J��&����n�r�P���:��n�~+��S%]d�^Pf�܃=^&�����m�=�f"B�͵�D�^^��#'���<6Z�3$���gD�C�L�WP�+�3�#d�.WN���UB�/dt�,�\4��|�ܔ�|�)u�l��qi����� j�O��_�`7�t��7��A�9��ۓ�m?���hi? �+v�wl���%���A�-�}g�mص�o�Y��A��D�����ꦷQ��{�۱=|��;�Kb�̄v��?7����@j��^6���y����Ӯ��[Ik��eޕ��C�7�䕣!���YS�`a�j�3����2F��e�l=a�G��S��������9�u'w5F�t:2 3���S&�:@7�:x�;�9��K��#�;��r�#�2d�����-�>�Vi� �~�T��M�]%��[��3�K�6P#@%�9 O���c0��Q3ؑ���� �hƻ|7��]Ku��*�.)[�������/��`B����K|�1��(�Y^-�AGnU�6HE���Ŭ[�m efv���]�j۪&j���~h������D`f��(z�&�8Z�(G9x~����(�ӧ�bz犜q��J[Mvo��/����u���TH+(7,k����I�u���p�35l"]��;�n��P�z�)$�⊧Z��U'Ze������R#��bV�Vqk�-Tr&Ư�*9mI�GR_�z-����!��b�d�3�p�`D���_��Yi��<�Eġ/������-2�^�.ƺ;1m\<@|��t�}�lt
~~�����Pe�����/��x�b�w�Q�y��20�n3�P9w���'���|b�%��su�N����A��3Mz9�ե]0(ýB0�ve;6Z���-�46�X��w�-�j��ԷN��Gs���KÄT"T�,F�d"v~��"�X��%���1��dK��Jy��t.<�`Z"��҂�o8�ӻ��d����M)��"��G��;DKwO[��_��p(�@G蠫�^� ���>W�l�����?�
0��c\+���Ȇ3i�-r0��uɥ�ƶ�\0���V��VάH�M����ꚋ[o'��?b�,���_9��Y��/pQÜ�]����$�*���v�;��]UpS=\�_�w�0��y�-�c��{st(*��L��n�c{/���o��[��,t� d���]�����B�;LUuO&�y���hΝ-����s���ܨ�&��Q�s���dS4\�mѫr�����i�7�2��I��<���OR:�u����g�c~3p�V�Ї9+��"u-"pڊ�BX�	v��bH�O�d�Q�rV��NE.� ��������s�_����H�g��.�
�z�+��D�y��|n�~��8���
��_$�d'���%L�1���r���H�:�8�q��4SQ�R�/�� S�S&�b2%7G^i��띤��T>��n��������=:ya;�`���!5�%}j*�*JփZ�o"�b�D}e����l&MY��j�֖@��.?�D�j#��~[����4{�1ឡ��sUr�D�Ԫ����ݔ��"My�"wH~*D����D��_�y�$m� 'f�B�5!0ϯҞ�c����gI|�I�r����d{��5O��r�ꒆI�\C r��kć ��p��h��ҧ��lƯU:RQU����y���Q+~q����]���e��(\اX�qW#��'�v�|���,@�">r����,�"v����/�b�)�a#�ɥ���������>�Ո�(i�1�|h��������G��xq��T\��b�۱dE�3���.DuO L*��	��/K����}�0Y��g�ï�� (�/%��C�N`�F+0l���N�Ms$-f��H��n!�� P�K�
^���DāS׋X�x4rT����W����*��k5/�����o��Lx�n�N�3�ő%{Ks����6��pv�Wי j���<�����3T5=O�-�y)/2����?h�*&c�n�c*Ig��C=/�?�f�≉�zT��O7� f^㽬k�<�/�~�qӍG������d6�D�"`��n[��h��	/�4i�!��L�N��CԐ�W�2^r��лz�z�c6#���������bY�B��O�k�>>UZ�+	�y�2�%��T)4�=�z�SH��E�c�;w��(�S�-Vu�+�k�ct�X���kht��k�)�%%�|��� iZf�	w��e-��vV�l�4�����S�5��\O��$�4��-��!=���F��
L����2�iߺ�*n	;M�RQ)�8�!b�m��G��8��	�B'�1?�AHω82�<f`Fv�p�����Z۠s���Αm�� N�L]�v����*p��qy�-"p���92�U���<79B�:PҒ8��S᳻��7A�R.�n�����U��!��D��b�(���|�^�W����U;ךh�������qvU�Jy$N�Ժj8Tj�Te�`��MH�o��q�sM0�}`-[Q���n�ͣ��A��3�<��Bj�f�h�mS'�'���ŮhM���h�u��%@8ܦy��i&�� ���Nl�d��F��d��Y?�t_��,wS�H��,�2}�'�.$��"����\�:�>f��a��������0W4���@$H+N
���s�;.�������Q>z�[,G�g��ڹKG�����f�\���v*T)f��T���&1oD���
�,s���&�Ԝ��ߥa�>u���T�<1��[�(��:LY��p�1�4m5�Y4IԢ��jXG/8�����r������Wn�*�/�����!Ļ�\f{��%����-]˸H�,j����<>�ޡ�������>�Z3�j�ǳf�w(D{k�Z�[ľ��O?������mI(��4^��1�rA��PMZ2S���I�d BZ˭q,���̅���Ϧ�?Y}'�g&��r��u�Et�_�q���9K��c��JlbgX*Ś���0%������"2�����A�(<�CܕR�*�	����~�g�Ca!�\ΨV�������4���kJTV���ߔ��>'^���p�=-�y��s����,0+��}�c���� 4UI��D�׊Or/�6�[ۚc},���U�Pr k�-S�.�=��A�\xPq&	6pNa&@W��)m�{�`5�\�d�aJ���q���b�@���W����� uR�D1��g�B�PQ4pj�@+�}(�9�Q�^K���5Zߝ��#���I�;��)�dIM�̸�(�m�;����B"�\�����#��2�b��x�4`��Vg�@�,ه�9��a�;+
�U�v4t��lE�뽡^�wAP�U��h��Uhs1٨p��b��b(�;���VM���Zo��ZUk~����zDY�Ox�D;M��,	�m������;�whw�iE
�_r����\�)���.��%$��$S�6L�)7�Ӗx)��J��]����G�	�?��QV��H�&zU9a��G�\ǈ���[��eCB�G�.ܴ�R�q5}h������2l��
JO��ԍ����6�_ܗ��(�����mC̍ f�/�^Λ����{�G
�ѥ��h�5Ծ&���c�6��櫪_���$S�C
(�`��p�;�Q�D��1�uW̌��(��\��d�Y�Ǉo�>�}2���ji]zo#ob�OH�������BVv�&l��Y�V�)�(�çɕ��U��@Վ����A!LVn������u��%��re���8�+�&v��o����}C蕆���O�/OQ���s�����I#[ҫKI��,H�<�q;�z�H�<X��c� ��ׯT�ZO��FEH)��|+M�U�u"b�%�q�����ŝ$��k�+e�?���d�-����mdZ��W|f��˨��x���W��l�nʻ��v�}i^8�#�i^�m_���2Y�	�8�Uq�)�{�S�
��
tp[��(��%`�`�^��c�A����!�}^�W�Q!*
��%���y�^A �2F�-ߡU�16������?�ud#x�Y��.��Z�K`'���oQ�k���ڪ�������}�s)t��C��+��rR�H�_.���L���5ʅ:]n!��^z|�7�]٧ ?�ѶO �(���$�6;N�~���J�0v�/ݫ�d0�����ю�RP�
T�)����AG��,��;�O;GH�+r2$|P�������I�>Tj�}J�="��h����2�W ~��`C=������c��2��q�\�B�q-N�m4�j�ӆ�-W���7+Z%�mI.�K=�PX��0�:b�#�������"�.V�'da�)��/;�}���n�vI�a��᛾�X6�Us+\�6��?���rBU؄,}���#��5�J<���⫃����ɂY,
-F:��Ph���-o�6Q/r����*�~�"1�l1,�ʄ1���6)[w���M5w�#����o�2��{�	!��4�W��#/M��y��՗Uא*��.������F<��L�܂�i����.�2�b���e�$�{|
,��[�`������wr)��p	��bBϝJ1!}�s�����y�`~��ݠ�b:K$�T����F4b�I����VXzc��P8�Q������N.�����q�����0
޷�qg۪a��.3+\`�h��\�aļ�[�G�Lq�1������Y�*Ól�(�I���l%@�,`�Z߻��qٞQ�
�X}8W���T��a�tqqS3z��-G�~� T$�Y|��W!�D����������F�u�_�`��h�yh�T>�ܿ$�Y�J��i��Ť����qeh��� w3+T,,���2>殟�,��f��FN��Y���d�?+�N�%;�����=�eߌ���Hl�tR·`�S�)+�c���}�Q3@N��H�~8$}��W��� {�+Y��-T��wL�%��ߟ�O�9M:�	XY��?2E�j8�+��?ڰ�r�$j�|A��\XF?��>�?����a+��ژx��ؿ㱉ГE;�Lno��f�`�roW�d�T��Sxr���<�*��C�r72��T!�?��84pJԡ��h\����]�������x�Q�{�a��b��.�+���kX�;�n��Ƈ���I��<z���Q������0%<�|�-�����i��(?zC|ڝ^>lY�+�P����tY׿gx�#���%�����O'���5�n2�J��r�]9�W�o��F���bl�P?[��B[u{dT
��CHG�a�J�"X�����T�JHt���'�g�Q����e�!Qw<kK�� EL컀��uW���U���ȓ�W�:6dp�ӵ�{f�M�JDzJ�Ax��M\�1���=�aq}��bu'�;ӕY�e%b���~�KqT��Z�lߥ���d��j� D�:[�#�� $�\�,R�lK��C2Rn˼=��~��5{�8���ϓ{o���3|h�U+ظ�4d`�����}�"y^�;��Bޣ���jbo	Atpc���Z�<ͨl�g��Ԃ�p�	t_�":g��S*a���|�0�֘Mֳi�Xʏ����ix�4��Ne�\��su����[/����,ᆗ(
'���ƙ����pR�������Ib��� �GJ�}�֘ҧk m���'�#��d��e���'�Y#+Gk�K9 M�藣A�}�X�S�� ���uG�%!�]M4-S��vRw�>Z�.�Ѡ�H�m@�)�&xז���l�,�W{B����*�̑8���nl�$�
Rl����J�e��H<c��K�{�rN��h����s� �i]������b�����C���D�CiUm�E�vn�\����a�%i��BVd� �(�f[.�"�@�����L|�!s�`k\ۥ<�ŋ���\_}����e�r~K�(/n�� ����*��-��_U2G|�����A��a��\����ד����k��y������
W�L��Ȱ�f��AO���J�=�W*xX�� Y�L�L\�ʜ��{�Q�:v+��y���Qy��a��������s^����D�V���Ӷ���8/�}��?���R[{��]wXE�#&΢�#��ߘn0��O�lP��l�[�Q�'�s�u]���C����\�X����n<�X�� ��fnadW���vʾtLBE�?���
�r�I�n�U�ӕ�N9�t9��9�;����C�l]�z��yAua�t�&�Q�te%�%���J\Xn�Ă�Vz��Qy+"{�����&���e�����=�]I�Fq�V��aKG��MЦ�V i+}.I���~nxt7D�N��3%�)�8/X9�'Q��}oдIK
y�֕�+���E߉w:x:�ݑ�D�ýI�'����[�+�f�q��0�����:��,_|G�hM�3ctS%��<}�y]��b�[U�18z�@�U߭gJ�F����&,�yn������ko�l��[����dv�ؽ��z����L$a����SrzV64~��/�-�����!O��
�|+��>�M�����)��t���1L*��&�Dl2�S�\�@�ƭ���i�|�v� �(0D�I��lX��kI�-t�*CE5�bJ��Mc�܁���9ނ���?˛=���3B����a�xI<N��~�s1�IRM��� �TZ��:�vj�ݧ��[B�ӏ��*.�۫�XH��A��|nC�g����I�Ҫ�w}k9�e��*��J���D
�Ƣߛ�Z�Zwc�Mo^�]���ois�ҽ!��`�N��s��S�3��w�ӮrDLQϖ���|��� ��*�rM�"�|<UNt�S���^����3�������5�[�����A��k�@�:�B��!�iJ�7yp���ކ:��	���V�CV�,���YZ��[�Tʄ|݈�2b��y+�v+.i�]���7R��gܰ8�J��X�zym�r�\D��d��q6z,�b�4�C��^�E��0j�g��Q������O:#U)�d�x�!�Ʈ��u�]6b��f�S�A�?�Dv�gq�o��M	�1���"���e�)ˏ�E.�F�F�WV����s�<���?g6�nb�oJ.G��iu��Ϻ�f�U/fܦc�&�aL��w��^��ޒb=�N��Z9��%}r��Mt���NdA�f�$:#Ǘ�$�!B��H=}{�/����9�#���z�5y�������N�s����� {�rNihlq��������g��G���X<���=�AHUIxӵ��
қ���&�aV��*<�i�+M�=�+u��\6�25��e҇��:�����Ԟ�$���b�����8���y����i�1�A�/���G5?)"H���x���6$�(xTnq-���=�'{Z��q]i���-@DW��$�=���!��j� �8��C��|ґ��e:;^G�6�T�1���G������Un��t�$P}�&��?Lv�A0Pr�(Gb�;�#\}Y� ����[Sꀿ#�(�O��{(p��lH3o��J9 ���a�¼o��N�����V�LY: +?���f�n�E:닁���[��ܝ���i03���ғ%P?��>UO�,��I���O�Ma����V��|��\�����?�֢M9Mdx�Ǯ4i��'���>��C2bn���!H#�`~�	�q�Y��U�9A<��y���^�f
u�$!�%�܆�`���A_�]3�cTQ�(4��)O�	�5���.P~+�y2DcBE
cRq�,�h�^�#5��j:�y�|)d�h�������#�����˷�&i��r�=t�}]�n����E����}L YA	�ў��V�%��B/�^o����[`����8&v)��3Tz��x>.�����q!���'�W�Bv�X�I=~r����᭯P4W8�~ɜ�H�������8��E#�p4�������ye �G�u�iC_L�@�_�D��K�#C�&5�(`�6�P>��_�P��Uz����M#�(�o�H��y�Z���R�R�c��p�����t09�ci�u1�0���+�r�V��a��c8�$<��� ��s���O�]I*)iXbb�sY�����Ȓ���S�J^�����x�j�`q�pC��� �g�`qzq0��&��d�G�<�!f`�w(�Z"�(�BGW�%� 	ɓ��:º���U⾿���v���b�I�uZS��0t�4N5&�	�Ā_��V*���m��4�O5���#�K�!����Z/Ͷ��ꤒ3�	�V�n���z���fDd�2�	T��E��h��ϐB9/��cۑiVU݋cR���Um�I�/E컒��ڐ8\F4u�'' �Y��LO��ON��So˙�����L~.\/P�2-�E�;��fs-��;*N��m�;�ߥ5ɚ���	Y�&K�zO��D�?�s����{S���'%k�HJ����z��-�MX�R����ڍ�V���y��w�"����
վ	��kPE�IOh�%�d3�;7^uttV�&�P#JQ� �n���O֝��k֭G֣��{@bi_<%ˬ�R�OW��3X&�dܾ�ݙϹ5���.L��>��0��c���^4�P����t��8��|���h9ts����9߼I1N�߭<��=��	�=�)X�H����>�����{�2��O�c���}(n���#%[/'���L�LR{���V�(V�VY@��Z��Vu��m~�sߔ�f��'pO�o��'p*���AyV�R	i�6+�BZ�v��Vn��J�d�4�]���ؾ:�������l�"�5k�'C��yĄ'o��ˠ�Uѵu^���qsM���|;=����/ �s�����$��n�|�߽�;�B>�|������-������Pg�b;G*�Y0 G��[F_ƿ�\�Q�ą��F:�t�?�R�c~�ێ�Px��?�*�p;�����@�ֿ˱���c�]����V}g��9`=��p��k,ӻ7JO*T����d_��N�U*�k�m�z��'m~�E}�)M��l�EZ��N)f�8c��r��\��Av��X-N��~O���EIY{]fk�l"-[	�u0^�b� ;Ӯ�EO'b=�W��u�^
�,�
G�9�0��}d؉E�����1x�p���2��l�ԯ�F�oQ_�(=S���]�fp�ψ�J2��0m(t�G��y���H[j�:�`<ٍ�Kw}��2��Pg��?,	P�m45�dA�G�[�e�돶��ɞ!sl�n"�0����U�)��]��NojQ����7��I">7`'Ԡ]��W��vPo�6k7'+V�ЉW�^�Q��C�����a� ���u�R4h�6V�,��H��(<�Nm��.�T��4���S�2��&�"�0���*����䏨���6��=���[�.�*O���gY�<���;�b4�Ә���ó�'��ާ��\�q��M7K�G0 45'+�ᵎ���z!=T����ʧ��Hg��<��Y����b������ݧ��I?���=�s ���a�����ejYwͽɷ��N�bz\�3#o)�	��X~��Zs2A't5��
1�:l�{9��$,�.���x�i�w�7�����H�X���vT�-����+���.�.���sȻۥ2B~��"�Ô|��e�W[�H�Zdҫ���.!��1O�ls}b%���w�N���:-��S�L�06���S�T��#�y�����@�����9�ܕ�8���%�����m-0���O����-~��@E���v���(p�qFJC��޳$#��;?�*:���]1�ĥjG��A�TI��ޝ��u�4�����Sg
��z�un�ɻ���`�u�>�ਪ�n�gp�jo���T Iz�~IK
���:58J{
�����	ݮ����F\&(!T�l��qW�斾f.���� CdP�dw�iTo��*���b�=씸I�١�%�֕��o^Z�^*�Ķۜ�N(�����ޙ�/�_�($�w&��#�6Rh7F�f��,��nf9�6�&h�ݼ�N�R�O�lF��[CA͒lਗ਼��ATѲ�����ԥ�826��QA������;8Dw`I��/�}����į��R�U���,��S�@��1SJ�`�����F���$�$6|��_���_��E (��~���aɢ2��4L:n��MNd�7O���MnI3P�c��{#���\���Ìmـc.^��
�[1��dݝv.qz��(�g�����t��7L��l}�h2���Qh�I�	{����(� w�i|�;���6Z�������y���m;/��/(��pe {8�maM$<C���d��Ke���sPW�:�d�W{�"Jli_��R]G˵;X
}�B��I�ِx3����~������$Z9B�p�0L����B��R �	�H(C&�a�"(o��AIl'k��RͥK�c��҄`m�J8$�����B�g��dg���Ӆ
na��nE����L�����=���4l_�T�'�
��~tQ�&����<I&P��Ej�J2k!�y�l�x��
��:�+7|�[� �t�`
_�EIK	��=M��em����~^���!:���n�*VM�9�G��6���$�{!6M�`A�{�#X�G B��2w�I
�4��D^�u��g�y�!�Qn\1S}�ؽ�9���&cu��O��%~��My;��He�?���������F��@��ݏ�kNk)�
��U�u�V :���f�w�p=�>��c���`��L��nIs����մ�g`NV��a$�=�?!��N���ã�0�x2����� +9!If1�?ڛ8��(Ν�^�{�����-짊\��z��-7��e*��ie}�J;ud�[H�.}��:�S��}^�����[Ț�|3�� ��WZG�����b⯌mۃK�~~��p���2���5R� �=N�\�|�f��T��{���ߴ7��gmvJ�4	|	y��αP9�q D�?���Gu|�������-����!>�j� K�����a�lW7���1�:��;· ܧ^q*�N׫�!�P�/I5U�Q|��X�w׼8B�f,�`�#����F��(P�1����4�,	��A��0�����~��%�M�ְ�G���T�rU�Z�P��߰����� �t��c�G`ěΦEu��ЮRlK���t�����	7?�T�;�-��I<�5%,�Z��'1W'�=䟅nk�̕���G�����Ŭ���vm�	�g��@˃
@&��	�.���v��9�p�Ź�Eb�V�3��Z3bK%f���A��S���n3�:yI��@���O��M�f:�������8~ݷ��/Q"�A0�p]�S[!QR:ᖦ����ic�g��}�h�'%eF/��0���n�0���#�ٍ07$�91��T��Y����F��
j0$��gF�BAi�vZG����lV��")!�fd� 
� ny�ݽI��v��@Ѧ鞵my�k���$��q9���s̐����`���d��j`�3H�jh�#x(��0)�z����U�9V�V�X����O��ಠ�R�C�_� /T��#�o ����������g�    YZ