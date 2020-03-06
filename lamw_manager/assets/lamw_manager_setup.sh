#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="142018717"
MD5="50f4d97904c9ef142c48688df15452c7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20744"
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
	echo Date of packaging: Fri Mar  6 04:52:28 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j�\./SS*�-�Ұ�*n��z5g�}I��N[�Nj���p�_��y"��s�����o6V�4iw�1tO�1@	���]�ڨ��D~�����l&R��>	m����i����od8�k��V�� e��,g$?��{�Ӛ8�M�M�r���Wz-�_�ݒi@=2��{{�a�� ����8\'aѬW��?J@|�z�J�㋜賠bi�j���Ŵ����-�\
nV�9e|�uvU��nJ��x-��,5�@��B�ڸГ���*��	�<T�{�u�\� :7�k��O�_����܉�R��ɻ��L�u&{���k4�M�������6�B�zM~�/*D
���3 �Kiq*�`!7��jȬ��-���}k-8�D�����cF����f�[b\�Z�?CQdA��u�,��	�)��ho���d�$eVkH,�|�>X�쌱�1�0^+�d������DJh�p��/Z ���3Z��oW�*m��W\��V�s:+��)1�R�L�1�*���wk�������":s��.y$�Z;�}R�6�R\D�QX�F��=U�Cϟ@e��i����E����k�����%s��|�ڭ%+���g�<?�S�}�B�G�Qf�D��?[��NЈpi��5��k��Gl4���3�{��D��%�1S�E��Y��Yů���\H�Z���������W��i�B���du���lEֲ
J�PB�c/rs��
�lJ���N��?��V�bGX-�۫�յb��
��UL���?@�y	�P���B�X��ƣ�Po����JJ�U۳�Ӭ׃�ՀWON�̎I<.��D�4e�T���-߿��a6��kʋr�²$�f�b5��S5���3��d,N~YL�BU�s���59�h�'m ?���,<e�%���$�uj������~y�3����:/����G��Z����W��C���l���m�E��T�f)���|(�g&��_�_:Q�[\�s��K�֞�+3���f��}�%��K��p�P����f������	�������P��T�%�̱3�ez���b�Nr9:�M����"�?@�e�H6�����?�1$���z*�W�0�9����X��KtM����{����G|��ߪf����htgA ��IޙiR� 9��T(� �x{�ǏA��hC�KO����3�;�C�����'��:����YO�+�c��֎�-��I�.$�G�"��ǺE]�.���|���
yu5�t�aSJ@�-����pzƘ;�x�7������k(-ΰ��Y�c
�6%�?k�����Ȁ���n�Kz�	٤����!b,�u�#�ǈ��=P�K�N&��ŧ��Zk���~n�E�&j6��|
�[�@�I��$0 6I�i����\��nXM�n�-��e��ϡ��0U@!���t���őP�	�_Y�R_G(�뜈h�$S�YQg���^�TK�RfL�$���^��g*lm>�F rb���Es�$7V��/��K����A�J����`s�8b*'xUƐwl.�޼&������֞1�i�������&qDil.���qF���^l�dx���^�2��2�l,��8ݸ�^����_ضb��<��Hj����0�R֨����x:LZ�X��Nh�Z��'*�M�X�
���M�\�/��x:� �q��%��v�d�kqyU��l�8���'�<�f����c._��c!�L3ĕ��ڱ�I먟qF�E�ԝ�Rc�x��0�*����fpI=�:����[�C*ft����#9�Ll�N�_� �Zp�C`��覅�zʾQ^����H�ߡx�J �*����H��9�'�ɇ�;�A;@��5zߌՂ����<����փm�x��6{�kb��T��{�<J�=[��>�r��� ٹũVւ'��_�&B�y����/�����$������� ��1i�j�&���!V���d���U�+�����n4��Tu�z���v~b��Z/�E�),�}��kF2�3N3rG�|$� ���<[P<)����M��9p>�l�`͐I&>=��ϫ@���gðbO5[��4�)�	� EbF���$��i���M ���n1�X�I7���������1\QD=�@SK�3����L��-���o���5,28�L|��žW3�	'�U����e��ZV��wNe���-𷷰j0���%��Grs�K.:E��ڷ���D#Q��b���8�K7c�L2�w�߄����N�{,˗=#�{��2`/�*�������,�|N1T�a~�*�O��p��҃��2���n(���;1���%�o{pH�UYMU�ȯ�A�"ꑹ��.Y߼Yb������-����'φr}Ʈ�t�"�s���@�o,�$&J��pwα,��6^���pr�
_-����m%�oМ��Zx������2��P�!��1w�8X�[d+�Vs3���!��$R]3QQ�bN�v�s�Y�N��m��Y�eI��gA�#]�u��wkL��/�Ә��;��+��~���SY�@�rȟj[��
P���?�xy�������";y�5,%]�D�5΢;�O�]�Ε�E��"���%���^֏D�L9k��`��'_<���6.�����m|�v���U�:��+ l�� �E�t�s|����ӻu'6$�R؍|�ϙ��vma��>3�e�(7��Ws�H��]��N�6ɨXɣaf��>!h֗�Ao���xR1dL蘇,>&�e�k1�����W'��M�-��6W* ,�V����>����|u���,�<H� }+���E��sƵ�ߠͤ��y��R3�糵��'���Wu�5韊�&UqV��D y�ۄ�H3&U����҄�ca�%Jw�nj�����(�%�)9�>�o6k�Cz�R�4H�j�%J��*E���U�\\��lr֘�73Y�E�Mg��-���TB r]&�JO���Uu�[��E8m���H=�Te�,��������Z(g���C��W�$����طO-`̚#�0rI�ݶ����Td���SI=p�ZU8�2b+Hc���9�����k@�y}�_Ck>/�*2'��=���/� '�JKP��Mߠk�T
�`E�^��@�$������Fp��.zr&5�{���r����>�B��huc�3v(1����-n]���k��ܔ�>Y��F�9�԰qyv����� țsu<O��ܢ���i�o����8c+�h�k`\#Pa`�}d�<���b���8�p�6�v����u��a�p���1�݃�Ӷ50�d���	�6�W�Y�g}M���3��R�-FK�Kі��'���-R��Qe2.��!�X�;��2�.���(B������W�~)�@n�щ�z� �ٹ�S��k�����Z���*�k���P�>�����w�UnI�Tt\:���9�ճ ��S`n��rY��gP���&�)mӥ�P��S
�]l/����=�`�lc���Z�ȷ�~"�Ĝ"̤���f��;�o�7a �×"����W�G�s�����8�58�|i)�\��
:<iIsb-����s�����	SF��~{S��#V��U�T����m�B�M���8q4�������k�ج^XOe�����A�~	u�.S�垒UB^���4�DhF��,�?[IW�2�8�s��b�CՃ�\�.y���[��УW)?��gW�u�"_�đ١�����TEw��/�e�uk(���u$$8h�cd��y���7��`�hl�n�n@���ty����u��W�>Z��z�"^�r�3�ٖ	g<��U�ۙ���?ϜR���p�RZl��%L����*��u�/�nKo�w���s�W�'��%aIm��*]�KP�ѧ��~��{��r���9o��}$x��:э�0m9HE7��0W�=�v���^_��8I�&F���t���
7�kR~6�:�~�����+���P�~#�~>`�y������{/�]��H�s��Eo�� �d�����(��i�'`:6��
D��Pԑ_" �x�&5�0�*%',*6��D%&aUh�bZ��H�	L�EJ	�H�m8��%��ДvM�1)O��*?�Q�㒿��)���e=���+�tO�e�����*��|T9!�l�_&��G�τM��Ovh`�0r�ɢ�(����f��5�~wA?=k*ݟIJ�r��gY�� Al��>������r(��V�߁�h]{U�B��i����P��c]N�� �y��uxD� �ʓ�]��_l����%���ͮ�*��K�BM7s}Wf�,�� 0�Md�7����A]B���p��0sG�����Ds8�aTTG;B���|�_V�߅��l��9xo	l��m	��3'�Ӑ|�g�{��-ߣ����8�OI5��˘��8��WP8.U��}��٢�����"�Q�%Î���$Os�xV1�����I�ҁ}t(t1����I�dp��@����@�?4v����o�oD-�8�V�^�t��8�0�Ax�l��򢦿�3�!q\l%F<�3st�h��6�a��EO��
�S_�M�d����i{�[^�Z�y�Y+X�B+C��"�ݤg�z���DpJ�N�Ǖ:Y�}�}y]	���t	��%�A��Sd�E�K��SC���Z�v���{l��&�ְ��F���F�iG�������G�	Bvg�m��# N�kIk��p|c7���J�S��� ?w���e��f�G���9b�\���PW�|A�{>p���'��q���(�c���I�!+>��@+qO+k�U7���[�q$�����s���ar� ?�43:�r�a��
+;F&f��p/��p�T���Uq�)6�oC(�a��~��ϐ������[�yK{�}䃥5J��>��?������n/������$��+`fL��� :u���/��9t���m� ��-2�L?�N	:�?n6\mr�Sfp�& �1����V���(8���]e�"�)�7Lu�2�{��=l�{y��no3�rn���2V�����s����#N���D'�Y��_t�����ZHpI��
���aRjT(�6��/��K���c��8]�n��f��,}Y	,���]j��l�������ː����`��$�q�J��1J�=�"����t�����הx�D��!L'H,�v�r�ם��4�tLe���ƺ�;!o��]��J:��r�~aq��҉@u20V�L*�º�D�k�{�|&�G{?���q�%��1�`_b�l�G�U� �4�/��H�����]�	rI��΍(�\z~!�����b�Ў!�̰�D���Z"H���U%�b�bq$����(N  v"�<��?���w	JʓTi����j�ґ,��q*�� ��8\Ұ����i�ґyH!��E%S���=�²��D�H�]��6Go8B���[�Ԛ����ټ?�rJn��~SI�[) ��`6#C��I�LA¶�B\㹎$��n���Q���'ܸ��s�����o�[?��ř��|�~�4:��y�n�����̷���a�qP](��x���'$%[��� ^?SsÕQ�]R� '����������\��MJ8q~��y~c� �!��λ}��G2����u�:MZ�b���}�Q��S�f��@��H*�2>��;�Ʀ�䳒�@�������q�C?_�""�s�h˱h��Ѻg�1��1�(g���ke�`,�x���D3����)������!�<�a�~�}�˽�
�r!K��5��������,jQ��R�U4rVC�B^H�pQyzt���Sx&%�/������I���SQ�i}"U��܉V�Y{P�
N��Dh	�u1�3�vXZ#�%��]7��a�q9��m�_��qK������U�`��^�1R��.HV0.�Jj̿�Q#��a�r�2����"�Ƚ�3��gƫ7;��b �l���/,m�8P��_�dϔz%�3��T%S=9R��Y��#"0��a��c����Q n&���Β��X5@�y_��|��G{9�z�l4-���0�Y\�f~�n��#��4(ԁ���k5sP��jq���0�r��*@�`ە��$Q�PPDn�k���({����!���pX���F,��<�(b��^*���n�U��*�^�1k������:�j�9�	�X�~���x�6�)G!��Ѣ�S�{��@,}Tf�����P֌�X�#}�*֒�Up�>����-%��Ȕp��>'l�Mh,f�� ��׉���Ƿ�j����K�g�a�\��Z�L�K�;� �+�Ź\�ۑ��k)�;m����>QP�\���͈@�7k<�K;�R���?�J����B.�Q�'z�+���p�m~�gF�.�����Kщ�r�H��[}�l��8��(TO���GXU+�2끂xX�EW�Y[����?�%��[\\�D����'<�э��ʤ�]N����榉v��u᱔Wk��q���D�y���c6�u����X�C �U\�/y�v䢺(�T/q�����/�٦��>���AP���{s[�L��a��hn��-i����H)�$�7 &���|����1J���]��؜�m|4�(6��U���:�մ(ط�ܪbu5˘��cs��O���`�{\�����C�b�}��В��9ӎ� �č�V&�J�V�oqّJf�vk?X���#j(Lbٜ8�ܵ��E��6���5��x�.��Dm�MeKT�6���^3o��TD��h�����Y?t�-e��2Wv�o�@uE��%W^=P�~�O5���cbX�։�I�GT
�p��!�'�}�bB�s<K'�(
X3�T�EZi��j����$~Բ�sʝ�j�L����$e�@$��n�nv�ڇ=��LP�'z�b=���c�M����p�c����rR�`,n�Y`e(���'(�4*}�Q��HEX����t.�wJ�v�0�m��b1�`L^-�r�Ѧ�#ǵp����;Y���,�o]�6ާ����]6��D�I<יxמ=���鋼_�b�F��z�2��#bĄB�%���P��Dq�Y㌷ϥ$�K�������%vgeUm]�LeLH��kp5�F�?��M5h��������S�d���!�/�Y��!�ج$�VC:��"Lw�P�*�@�b~�j<��߲����tٟZ	c8/&��+�Cv	X�o�o>�F�!\�i���Hו�1X�[� G�,o5�?�.�F������F[%��;y&?;њ4~'����5u^�\n��8��a��f�<I!�k~Îy��/�o�8*�MB`�)����ȘU���	l�_�le2�>k�Ǔ���		����40�;�=O+��a,����b����q�qK�D�gЁ�g�x͋�i��'_����D�Yi#T(%�����m7ԥCG$��s-�/եc��xOU�V#� ��k0*x�~��1���Ti�����ќ��Քe�0o�]5:�A��%Z�˖������S���݅��Q��أ�i�O�E;m�iȊ�z��J�ĺD
Y���&4�n�2���+S�~�I�;�5��l,�ν����E�����	8ˁd�4����OwU���wS���@�gN�6O�s�#w[o�P�S;�Tr���0��1cℹ��u}��.ʈOnuM��ހ�/n�D�#�?�v���,�d��[?2Wr���F֑-c�h��q�iSex+6�]_xnFX�Js��'0pa��QzƞU&P|����GB2�.�z�Ϣ�t��@��/e?��>������p����y���o}�#�x�|���b�`�r���[�oUq\#�9��`DL΂7�#�»��#N��h&��K���&�Fu��p//���L a���<���1Z�d�{��P��N��ҜV�mb?�6q���+��Z�(R`���z��/Y���w=1{}1���R�ND��e>n����������O�2p�K�?��4�k�ʁM�u��Y5h�[�#v��V����јJ��Z�[@?�P~�]�aDCR��`�-�M��Ʀ%|-�Gm2-h���n�t;X�եOӕS���(Qú����K\��z֧�r�q_�����?i2S��4��Ε�(^*3Q�G#�-�4%��喓�m'V�E
w�@a�p�psC�Y��A�o�R�����dm����EiPx�%7w$�� ����3���i�,�Z�!�D�@�P��;�`�Z��J;}�U#Ȝt��_�+.���:'���p���~H��qj�p� t0��$�/q�{va|?M�;g����iyp��#o#������Q<� �ҥ�:��Vj>%��������/h�E+��HW�24��L�j.�^��0"ȳ�7�A7������Ij�=z���_F������YJj0;��2��K6��[�6:������W8�?�w����Lڤ�f*@�SWGdQ�N?�Ւ�۪Ϝ���IX�#��Gu؇ ��B6�������Ɨ?[I�uɮ�<���S�R��s���74�^����75���*oV,��,�?���
5�x�@�I��C�~>���U[��R�NB�<�U�ۛ�:����6a��֩����ˁ2�m� }�IQ���Z(>ebm���|��.��+;��[?^��W"��$@g����~�B�b{W-56�P24}XX"�,~�x��o`r��,�V�-H0̮�jAH�ɩ�c��=��%��8�+�#A�I�^��ѫ?d��io��4�{�}7�񁌂�v4�rv�ȕh]h��c_�,��Ժ7���md|ʩ�ޥ�U��OOZ��LC�K�icU͝*_��(�_� ��p��҂=��%3Z]"o��֊/Fq����)�n���ޑt��z[���0FɴGA���ɯ��.%p���0XX���|Ի��v��v=�'�s�&L���G����jY��?�&r����I��
�Y���R��`$Bl���9�8�a��@�F�����5��(-/����B�� e-����K�[�t�F�B��kK����0�/�q���le:���k�N3�*���sg�_U�+�?e��8�[u�bɍ2���sVʌ	��Z���	�~_9sf0D�s���xu�Դ������?|0�~_��(s;`���O@����}7A��{��+���U@௧�e���A�K�o����:w`B	4Fr.�g�u>�\���$l}va�:���"ץ�.�.@���r�o��Nq vⅿf�<���H�TL�p��J�ƅq���%�~K�������l¬��D;x�Dv:v�Y��,Qd��\�pyZ�{Ct�C;1N�k���2<5�#Z�(K�~��q1�ߊ.ugig�*��4h��0�W�m)����"�I�cs��97��tW�����eU�ϸ7Y�����7̫��,�����y�n1�h�U�+L���@\%�O��� 9����/X�M�.�+<��m��!��K"�٢d���3c�����r(zE�sӿ<���;�MkV);�C�@F�nOҟF
En��Zɰ6���GvMǟ!6BX�c|?���J��,O=�:Z@B>cFh�ǧ�������N�8-�(��6<}�l?�B��S��U|>��ޔ*��Ai���?�O(Z�{�g�ێD+]��JP� q�c(�1L<�w���T�)7��`T�?Ht��C�R�P�~⡰p�L�L��g�Gu�?
�%ᵼ���SY<����L�,�������k~�&N 5R�6���CdU��;�����I�ݿ )���9f�6Q٪�{{�˷m�ǈ��Q?z�3��|�|4��#i��u�i���I%A3E7�<2�Mξ����a����h�X��q[�k 2P�_������d��7�:�_YUǏN��$3���t|AR�n��a�^E�����v8;[a��l���Ż2ͼ%���bt~CR�����u�OZ��2b�
�^�g�tn���,O���3X�f�޺���Ź�<d�b	��*(�B!NH�E�] 9@7铈�z�*ߥ��2@�0Ӳl���C�qo���H����X"�c��kT$����;g�v�RZ� �������ݒW��8Ј��M�� �Z�e�[*^�|"�a�-K�\aX���$?\e_���4�Fw�a^E��M���8R����M`+_�3��1�������X!����a���np��@9�,d_@z�$E<�vT*`�͋��7OW����"<{Z�o��˅y
�.�ļjj���!�g8����N�6ےn�i����d�5>�X��*8b����j.ոI85�����X nXO��~f����
L�͋.�GD�}�H��f4�׏#wǪ[(�%+���]��< Ikd#�ح(o\F��Q1H5�]���\x�Ns�Ga�D�m�-a�$w2\b@\�A��k��0|�6a�FS&����-��``F��u��08(�Z��W&���z�x����|7�Xq�3�LW���.nC94?��s�1�$I7k�[�wM&Q�A�űvJΏ�v��u��[�6���@�j�����6vr���l��ȐO������7��t��^�e�'\�Ht(E�9Y��Cb�󅦂�Zj;ڐ�eu�_�}S��"-�G����������y�b��#�YLH�����,mj�/lA��������N�m�����A����58x�cJ�n{

۝#9�	��
l&.��<��qlfį �G�]���Lc�h�����a�X~�E-�0O�mB�˞�WwΧ[x� M5�՝l��5�ɯYY?�>�rBz�
L����x~G���>��n��~u�d���ܘ'�y���b�V�J����!*qhz���>N��CC��|	 ��o,����BYY*�� �gUQ�|l��G!�A��c^:%�S�xS�'w��-����4l�ZY��{y��6���V^�N&�$w*	R�y�Id���k��`�dB��]�Wx��1v���1�ፄB�V������<�yz<p@��I�$�ra�/LL
�)ʭ,E0e�0�CM/Ǐ�M�f�GG�;�P�0��>b�$ܮ� �?��3�\!���xn��W��籿�G�������GڰN��|����z��@�����k���L�/D-&�HI�����y�$�A{^t^��<Y�eل#�u���i�D�	`=��VKҿ�{@�_�D�d��� p�t��J�w�9�i�U�X_���������~�z�q�
����`��cğSf�; ���4��R��wW�90�&<���MH���[����VsZIc3Ћ��S3����9.e��[��N��u)��Q�p�e��g��겿�K z1w�3F��ƨ0n2�E��1��5�R/Ӓ�	��� sӥR) �X��*%��@�aF��s�}@;U���-��(�;`� �MMgC��Ha/���ۡ�"�M�	!oa��>;O�'cBb� Q�jD���*�`KN,�2J}��lئ�?�]ϴ�J�|.v��B�=NQw����7���u�h�[�'�4�֦������a	a����a�\��{#�Ϩj���I�2�t�6�`Gn�JJ��6��cǇ]Ύ
'��� �J	 �3bM{�����AAtPk��J�|�V�01���H|��s�/�'�u��4��O�4+�����޻�N��ɉ�)E]�+����K�v[+ʭ�S���֠��`��2��9��镍���<'V�!C��9�����;�*ALh�#S�Go����svg�/��yI)�}��۽�������cŮ���2:��_rj}�a�l�1Z�r>A��8�oI)�.�c���x;ko�4Y9��)YE�����a~qs���>Q��۞u�ݧ[�QU|��b���^Ѱ��2�t��]�jq���Z�A�<��*֍�X��}!�La�
�yϬ�蔦�t#>#Z���s|����{��+\Gu�� X�����z��Z�õ���pZ�m~�n��P/�����t�6a��9��R�l6�H�q��L�:)�G�Pܴ]g���ϊ+&��+ΰ<^����M���T���<* =���C0���܉N���0�]h:BY�_��ԮL�N�a=6�|D�F��D?J�@��w�}�gfC_����f$�#�扇�*�gxksE����(�G9�'c!������CD�0�C� �R�vc�$k����48[���C�qZ���]��er�IDI�1�;IV��%f�ʟ�Y4�t�-�&7��'��
��є�=6}5�ϕ_a�`�c��u0Q�֢d_�
$pm=��*�[��zѰʬt�r3"p玓9����dm׊"~s����/��V�'!���d���	�8�ߞ�F�E�Z�S��ӏ��a�L�����eCD��J+��p��DM��(�!� X�4}Gy�7���!�G�Ķ9~W1��rR������6Ͼ~f�#�2B�I@�o���-l��M����c�����6G����,WQ�\�p�:�h�5�;G�X��T���	��w����*}s�Z�)u����RG:a�Rb����C�Df+�۪�27���?1��� YB�����H/T�y%��&�:)�����"C��1�����6�tH��ʺ y��|��N��Yt�mlqT���
yH�t���G��_��~u.3������.7ZЃ�CQd�x����ZBf`*��t�6�Р顮#x�_�-�)���w߿��QeHQ�pm>I~�+o t���}��c5e[�`�ك��)�f������'TyL��<��,L{�T�I>kV4�_��kl�a
3Ͽ9s�B"�"����&o�������{�G*BШ��D؞��o@��fϝ�������~Xq�?Z��c��Km�����Ky[(�Y�0�iB��Z��f���[�Z���Gl�h��u�˥I� �e�S��v�~y����{�ʝz3n}���ƄQ(=Rv���Τ�;bQ�T�A*�fs}� X�f_�|���|��ꦎH�U4G���z2��)�ě�$��Ͱ]�>Dg)-R5�\���t�D��r���>bdK��?S��5��j�0�Qڣ�&�\���e�+�`1CL�m����}��A�`Q�v�e0G�w����,�Ϛ�s����F�3§;r迏�`���\n�E�#�%�Q{O"K#`��K��8���?q>���W�L�Wlj��E�k)���O��{[W���s���^�)u���F���Q�!��HR��7l��*��7��˜�z�1�cW&��\��+��4Mn2K_��gK�]~x0a���������s��a�k�]��	�2�6�Rp��]D&I�f~������C���Di��yC:
���?X+��C*�/�O��N�Ɨ�h�&SK�0������7���h�.F�#�0`zw}�
���%BI�)�l��+�v�+;4����Y�=,��q���YGt>uz�q�p�v�'�y���z��$�,���p�I�y���d�X͍����7���������'�Lr���(�v0\�qYN=K�<`�,��q8�4m(/Ml����|r�|���n��Q�7���u,>�C�//Mrɹ<,8ٰו���1�lPӡxe���ƨ�F�Ɯ�RO7XZ`�T>���tFm�7�e�$^���)<6�_~����Ƅ1�Z�v��� 8�_����崻��V�GkԘ�	�{�� �+�̡�[_�!�����Vv���(�'���SS����xr���l�������:^N�y-4�9C�x6x�T�d�6vw�%v@<�Bm�����k��eR �e�u�-F&
�f.���ySd��C8�р����H���:bm�m��^�d�ۋj����գb{�N��RDeuΔPU{����_XG�Գ�7�BY�'r�5�����X��s
|3ť�W_��HF�����Tn�7�̵�ԗ��(^�K��v�Za�QJ}���i.d��e�r�Ǯ�-� �X�_��'H�g8�����H�%R5?��ԫm��/�P#��.2�d1=�Y3/L%ϲ�}~)�$^ C�bu-�qs4��H�Y�G�z��A���~ d��x5�S*^,�0S(5���i�K�ȍ�fE,>�0zll�K|�+w/�m>rq`�6�~�)�M�<�-1�1�IEz�\}��xB�U��Xӌ؝���d�Ry�p���-ˬ

f���*H}�����(�%�2Q�p6Q�ݿ^��v�vɯ�@G'w-�H��N�ư:��ϨT���!�Uo�^@���P�쟺�������u�+���N+�ǐY6�k�Q��Z'���UB9����v��U��fU��u��[���VO�uӐLb���.�l����~)��D�e��PY��i��'�e��}��g>�;�Q��o�K��j�펥7<�rcn�բ�dSANx�Sy�-?	`�o�u�}��JK��JxO{JU\U_Ț���!1dᕹ�Ȕڷaw={�����0O��P��1���)���d��f=�Qk�g�_��]�; �7m*F&�=8;��y\@P���� �:�>s�;R˔�DĿ��N�\�,���)yJ��.�g)��uI` P:�܏_d��ڏ���"{��+dc�#�2Xvwk4�?z�Ge���#E�&��8��*k�Vʡ�p>���t����̠�U�����K>F��)�8����f$��ơ����N�h�C�Kv�����I�� �x+	�����33�B�>}��|Y�����gx��}��J�x2�K��Lݿm��lp�=K���& ���CW�4h�=0��qM�=��K�(��6ण�����"�cV^,oE���Z�C������e��n3T%�n��{�cnv�_�Eh8G�ԯ��I���-�-Z�ie��ܷ�*j5Oa%���M�@d�r�^n�r��d�W�y;E=������M��r3����Tc���E�4�f[M��qG�����# w.�?UL�Ge_�K7��z)AJ�]+aޛ�k&�:/;Oß_i���[b���;c�=H�@jb�2׃/W�_��9ֽ�\�X��P.� t���5� �T@x��a7�E(ā�4����������k¯I��`Ƌ����W,Z+ZHN�
N+�.!������v�'6�+n��.���hN��:���W�
�d�m�k��D]�\���)�[�y=��U��F#p��ƈ�%����t�cV|(�#�����+S�մ�R�ar�b>e���p0{ᣡ�����U��ї뷐l������<Zx� �!�WV�_� B�#!���d�Mn��g�3d����&�J����xM�]x��I���z���jm�/M����ϳ��z��|��W�~��e�w�� �8�
�f�?@ 2�� #�4ȟ��'�LS���V;X��&��̌[��ﭷ�86��Ւs}�9�x2�Ǉ��gw�靧�ޞ�2��z4�^O�x�?Cf�`����_�̔�����ᒓ���G��n���
]1�����S��#����Eq�q^	�LR��"Ҷ�D���՞m�"/��e`�>6�4߃�B�/VV��_Z��Y��C�g�YU���m��W8���lZ�}�q�O:l�QN��mg����.c����\��F��)��-C~6�D�!/]�y��8�d�F�1T���!v�g�^�r|��k$lV�3��ѴY���2�$���Sd���� T�"c���b�aa=�~�Ya�C�h®�7z���7�m�n�'�)N���8~n�ը&�l�s�hP7i�IMcMHl\$J$��p�"Pa�`���.�Xt�Z���#O��MTӧ�Y/��XC���{G�%�D�Q8�"�j�۪��j�7��`S��>�!ŕ�h/���u�h��'�6� ϓ9^�.�c�t�]�'HAĉ�Y���Q�\m`���	��<췲�.���Ad�0�&G�SJe0�e�=���������("7Mtۘugb��@�
y�B�r���� �b��!:���D�C�s�aF��'mz�������T��Y=|������`�Y֜4�+�C+��8� ���ɑ�:UmVׁG/��a����o�C��ŵ�G�2��oy �4e��]$��� ��VZ����
��I�"��m��Wwdu��{:��8���%�c\ND�CM2��-�J�XoHAoW�e@].�B!y{�
�W�W�𐩟8��� �d#>ԕYl��YWB:�쨡7b3���΄qs��L}WoY��(���#�h�<0s����eo�>�`|S�,4�� Ԧ6h����h61�Q/L�o�M,��� �\��ĕ��*�9~:%�6"��,P�-(/H���i�cS{� 1&�U���>&�"��QW���]Ƣ!gU�s�_�;H"�X��A�`��m�s��Q� ���)����$�4J�0a��Y�e���Z|0�xF�~������`�/W%���=LI�����{݆�4	���O�+�[!U�tQt�����}a�|��p���v���f .�pj蛹��l}p����9Ep ��aU�t�T��#�T��$��y�������+��9J�0
]���luW@F�=������;�xJ�t�l�]4��1ޘ��ܡv�-��F�/��`'3l���=���9�[PC����n.O3_e�]�P��Y)bl���S�ٟ a�E�e]5�� ޼�t.J���ϋMB�w�»�J�7vDb� s�����z�iS@�?M[�m=W({n�;E�-��.ĩ�����y�ޚE]���܅�,X�l��½Y�B�D��U�,���b��*yW��)���߲Z�iX��ԷDQ߯Z�����_̶��v�l�7Wҟ5U\uQn%��H��+�(�AW �X{a��F�/X f��'��p���J�P�W:낡dt.��m;�πE�o�O���j}\�j*"��A�����/�4����1W\����g�%�M0Y��U�+�q�_�I��F����?3L��`cntR��)K]��!̷��A���w�������b�O..cyA/��U:s̿�����sƘ���f?T����|b(��D�E?����M�4���a1D1�'7�G#��R�@�����(�MP��?���3lwhz^#� �y�14����xz�+r��aBo	7��*$�I��ѯ����.�����ks�:J\I8˳4[t�j��I�,B}[1paZm���|�pF�Wy��Lv?�:���J �vh!��q{�^�\ve�
#$]]��x&���/�W˅�a��e�z�lX��t�Q>��Q�\@����t�8��ٰ?Y�cw1v�������A.�+��R�zM�;�E~����*�Lg<�P��Ig����4P�Æ�<ηs�峷��-*�¨ke3t>��XJE4�`7��� ��Eb�*�p횗2�Zv�I���[��_�_�\R���l�H�.�a��$Ԭ�����ܩ��>u�va?�jfwl��5 �h���YN���1al6W$��K�y;:�[���w���Qm��Ѡ2�#Ou<��>K��r�"��ɬ730-�~�G�����q�o����3g{1�EKM������N��}���f?y+��}\���G�`)]f
�Aw�G��`@^��g�鑚�uȨ�3��fb���wx�G� ۘI%�yH���u�3�v�-/�(�P��:��p*�aw�3ƒz������7��*}�dh���d�ws���2~���Wg����]�n��j4C�g����"��$l|��}�|[.#�!_��l �;r�/
�Ӽ7��89x%����ڿO� ��?�[X�t$~�\��sG�X>�� �+�a�{��$lqX��!�DZ�3M��k����F���_I���X�|�R¨-�*�O�/a���/��hD�-s1�u�a�x��k�.<k�J��~6 w����
�ᢔ�?��g��iDj�Bϝj�5�E��Xζ��(ǣ�?�$m�8����S�?��o�Qe�rcGai_�� ���"j�Y���y�m "R��4�]�^2;�ir��3�_Z�_�)�L	�݋�Ֆ�,�-Ӄ'T_V7=v�P\Rs�����:���.�|#Tf&�3��8W]=���k0@�<R��k	Rڦ��Ӌ����D́[Lm�3am�V�OVi�?����<����&n��:�J���PCroځ�� Y:,��ծ�^�Hzh唪D�r�"����h�;��V0�M�����N�KO��d���s���m�E���G0..L�u*��-�MM%z�����93ŜϬ�u��1�������()H%���s7wՐ�zk������Б#ؕ�(�т^�?�+SR*,���.��N�Anb�Ԫn�≌\��;s�Q�f�[F"~�=6�� M
[��7��z��j����1,د��x�T��(���i�[YV�x�] �@���]��)���"�j�%�{h� >�ae_�J�)!�2H�?��bb������8��6�>;:���ޘ	��yey��}��|��� �H�"[�B4�i��\3F��f<����g��A��Lۚǒ��1�x�����o�{TV��f$LAO�-$ :����:�a�&U�{�?���뢆��ޝ�\��N*9�2�>m��K���1Zĕd�→ײŚ��[smX���X��F�ƛo䋿��� ^�^i�Webn_����)��D��Z�k1<n�e@ӄ#<<�!:���'w�aFGBp珊D}յX��_+���D�J8��tU��k���^���x@��+�ˀGf6�l�ɹ���ߧ�o����4��2�M!�Yʻ�����[�لJ�6�w��4�eID(�><�+��{8�tQz��5��~��~���@S�"JAh1tdŧߪdo�c'LDA�s`o���&ث<J.x]�Bk�2��פ��'�}�L�%��ti�|��� � ض;k�����L���� �>��~���x�ML�wM�	ߤ(���c{%����l\�����x��^��p��Ѱ|a��W9YL������}*���e��̺t웘��WL-Q�]�|;Y�<�P��~~V�.�W��gE?��S~`�� �͊��	�����JPnj=��^ӳ#�J��������m�r���fq� �p�)���`�9��� j+�.���]�0E�q.����l���,B 0^�
�_VnÙ_�2�HR���	�Y�&�=CJ1(�{d�y���`]��#ldg:ӫ���h�y-����N�X���t�Y�
���xʣ���3���!����眔c�Jx��]�ߗ�}\� ��T�JHCiA]�{���y��نڽ駧e]\ޟ�[36�%�h��3�����ǒ� ���G�����*aT�@V6�ˏd��#$8Z��G~	u��B�E�*�!�R��~�5��Z�1�$���1tJj�R��޹g�p�]>�֠����k����P5K��5�a�g�jQ]���u�e)�暽���o a���4�E8<N^=mܡ"�y0t���W�Q�	(�2���i!ꇲC� �|���l��1;g�s:���rW��V�2�8��|@9��Q�W-�^t��C���uSe�����eBX�s�ܦ`�8>	OR%�I`pڠ�ˊ2�P�4��(~��o�������2�Csi.c�lR�7q��G�X�2�f3��i=��__��^���fYV��B���8u�Z��ԩ��������e��edXK��h��������y"�R��^�3H�Q�h�9W���D���av:hzO�!CzW�V�Ǉ4�kO-̡L�
݇�N��m�$����a�g���:|!���q)�����s�H[E��D��a#�-��б�c(���M�����j�G0��X*b�� 	��q=���Wҟ&�1!`۴i��X�]����/l�UǙh^��	7&� ����=f�k�p�����Q�gP��r�&Y�.M��^�F�;��gI[CǺs��Q�ǘ7�CN��.���6LT��mɝ�R�I�^����hX�:�
�|F��Gb�"��"� �i
�w�?c]C���&h�3g�dr� �^?���EV�Y����վ�$�f@tl�-����0��/�zv��{�ܬ�:�q7:QeH���˦tn�8���'51���ȱ�OK�c�>���G��#, ��?9c-t��ewT��Jf�SZщ����O��R���k���p��4	@Y���JtO�E�[�ɾ�q�b���A��؛�a`_C?,�y8��.,�I�1�ccY�q�6�~�Lh�� �)�8�4�FsP� W�Έ��
� ��Y�<� ���V^*��g�    YZ