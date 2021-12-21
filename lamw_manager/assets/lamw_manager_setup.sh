#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="10269062"
MD5="96883f5d1fec291209d93ab8b2177e74"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23972"
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
	echo Date of packaging: Tue Dec 21 13:08:51 -03 2021
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
�7zXZ  �ִF !   �X����]b] �}��1Dd]����P�t�D�#���I��Y�
�B�i���6B+�;&����Gu"����8pe��VZ�(7J�� A��n�;�f)��/���-1{����=ݸQ���N9�J��W�6�����eLAK���-`�8E�q��;}��.�mT8���o��|�E���V��#ͣ,;��������y���"^��1l��߼9:�����]k��3%����9`j��U|�b�^d8ӳ�	Ļ�+���7ƣgl�WK���,iZ�^���E��G��%%&�� ��"�@����"���;�,�vZ�� b���(�C�xW�o%s�ïoe:�@���wæQJwf'`��F���X�{��`��e$<�:�Z������7N¯L��%�1:���ߐ�a8Ɨ��?j�N��X�;D��|_���pufa��T�0���
��3n53�M�pH���9��|S@�Ŕl��z:�S䭎���*�X;�W�U���&�H�Ad��`v0-Η �Ibl�%J�jz�����0��k��`��B̑���C�)�k���#�q�\-��t��<ࠂFA�C����	��5�+�~��zA���z��B�F�Q� ������H�`F:���^�Ndh�'�Ĥ[B�R@v�������r��$���)�g`}����@,�#d�$]�������I�:��xC%pq�8ؗ��Y������O�Ym�*
����dY��i0W�L�$d2�8��0:,�lf�L�ץ��ǨP|�ố�LJ]����DK�=��um)ު��n��n¹���8Q�?g���&�^-��ds7Q�b(톒Oݱz�.����l����?�f��l0����*)_(�o���FKI���%��@n�&OB#lE�(�&L����YN�'Cٲ�w�E��݋�{=+�[#�EjsNoM�|ݽR���|YCv����:��
��_B� ��Sl���Qv�zry�q�x�.=�Loۏ��9]��(�Q��B�3�Zs'��6`簹�J�<CJ\ڰ8X> ��)��J{��7k�\(Gn�V�0��H�W�����b�\�p
�	��ˊc}�%݂��0�llN�C�6�b2&�r���BqF#"V{��VB-4����+6� @%�-�m�Ǉ��.c;r�Ww@����n�p���WDo)�4o0ak�a��D�9Z�3,�����h�:_"�Bm��Ҫ�	PCSl"�>|�"z�O*���(���o.�rYG�=�H+�v�*��[����|&Yf�*������D�g��iPlRa��kZS�;%}gxK���$�{7i8ٴ�)��W�{��@o�������̑K[�����F]��;�^��*�p"���By��jb%(��	���'q/{MŦy���'�s�B�o���!�t�*�*k(j#�7�ȱ�$5P{Z�,�ů�l�Uê�z�P׎"|!�ߩ����Иm�N������	��˴~W������NH�1FX�����4�
���(MeQ���q����H�+aq�-	H��8�]KB���=4�_�μ��ٚ_�V�G�^�b�hB!�a��^rU)����<O���LW�Ā�)@����$6� �Z�		dݝ�*eŹ�/��X&XaYV�-��y*���偪����G 7#�*��fa��N/�j紛R���$�ӈ"�Y}^�k�f�Қ�:���b
����]�X��=�[�>YnZ�Q���K5�����jdU�~GM�W�:?��L:�*�l���#za���E�Y[oj"`����"F�ט�Va��S�IEe��R�m+��k:�x�{�[d�N�c
���� 
ER�K��;��%�aU҄�89D�$�-���蟓Oc�3�5�(t��}@y$���V�*����N$�4_&���$dpu�j_t��q$�(I�Y"���&�d����{f��]xnm��ӓ];@X<����*�����ᑟJJi|�d6� M�:b���T�lʼ�W�k���3����s6u������cz.��J52�EJvkŉ#�"�fN#QntA�hw��B]sQ�I�x�
��m�=���76�qp*@4ʪq3|�2$hP�ӣ��j�9���8�Ӎ�aO�p����+�̴;Q�mA���+�K��T ��Y<��f|�5��j��/\�Pa�twa��LSG���_"�<V���	��U��c������`?Ch�@��ӑ�&�T<�����jB��eu����a=%_N���.�#7%�Ѡ�sv�T�a�d��^tB�M�p�s0�hP �H�{ޟME��v�a�)�BAw���^	L=eM-�֔$�NR��o$�������s~�h�k�6gJ�I\�����>KZ|j����w�v~�q?@������ ;-���]�ĝ���? �]��߫$���m� B99ђ��W
<��$�.�������
�A�J�
�AI�aanA|��28y~�]��[�=����[�1�Q�?W�1����_��TP���-φ�}÷F�{��xb]����w�Qr5V�X�Bߡo�4J�F`��(�ۚ�Nnb)T�ύ�R�V
{�~*eG9t^&(��Z����R����g�(l'�|�a%�8Av|i7�B(�L��X�ʈq��}�U8k��%e��i�6+�݁SLU���/�I�D�8�ˍy��C��u`��.z�G���<N
�EI���5Ťt�='���Ӫ�<n��{nw��k��,r�9	�}m�S+�.?�t���^�Y�#6O%���z�V:��{�¹W+���Ir7��u7��x�ބ������AA��Ʉ� ��i�z���?��u9�5��KK���7�0P�������(F���+g%jAA/�M������%�#S+h��2��lCQ�S	�n�b9��6d<h��st2�,��򂵡\5QE�J�â_H}pV)7�P�`�W��M�������y�z�f�ԩ����ﰡ���\ �tL>��cZ����J�<��FYʮq_�{郁D *�����&fe)$�e@��;��hb��0�)��=�:1Q1E���Z��э�� z�,vj���*A��䉡=m����������n�D}��Yf�X7(��T���Zw:'��\/�c�)�{�P0Z>�qv*�.�-��@�V��nx']OCav�(l����y�`��2J��S�|�l�T��(^��n�.=	]eS=4�&�,�D 18��GMi1����ԕCx��3��ƍ�6�,����L�щW~���\� �N�e�U�3����&e��Y����,Ke��?t�T!9�hN+��m�;֑o7@�Oí��B���!���*�I�ib��r9���$$~'�T�_'�-!�Ec�`�q��q��" �VU�G��|֝��zw�D�-��� ������g���=��g퐅,�j�#��x���d4-(O��!4��Q�;ʽ�R��fA��J��9��5� \�^������c�G%�he�X��q�9��MF3�8�/�v���j��~�6fp2޺#-��}�_c���	 �il���}��s] T�Q�7�A��c�����o�p�����(ش,Pc������AiE�4��,%W�p�#$P�g��&3���	c :�W>Z� DG�H\:�������aWə�{$��[���?8�<̐��E�L����mܖ��I i�����T����':�Ɓ�G(�Z�+�eZ~UR%��#˕�����q�b/J�J�_�%�9~Ƿ���Q�4|1��7�f�yץ=.h������-7��t�/$gW�!�)���3h�.�$T#Υ��:���x1u;�D�OH����7��c��K����Z/F˪�ȥ=�=����rt�8��zS�c�a�9?�)Ƭ'��q�O����L�d^έ���� "��F��ݳ��;�m�Zb��k��~�|�e�}�6���wU�|E�d#��|��rV��&�`��1^��	�W����T��H�oЭkS���J2m~�6��~Ǆ2"�/S;g�%5l8dwN�Q}� �%B��G]�3�f]��x�!��]����}z�ӌΜ�^\.XD�168���3us���%����=�ś J��"v��V
A[}̦کi�7K�s�T��qC��(f7�w#�;�����_ץU|����Ljo�u��,�a5��h��2���s�B淠��
(�],J�_@}c�M��I�Oľ�'������B?LP�G0��K^7[R>�t�g�}���r!~��	�B���
U�9<6�@% =��k�F�%+V%3��mt��*h�V���1����<��5Z�O&�k�1��_��5�qby�\�)���O��:�Εӽkwz2~���U� u�J�z�n+u�Qp�'o�&� pL׆��!����>\�\=N�9����uW� ����)�Y�7	>*ޘ~��w���J��A�F"X�9p���V�>�,�����JqN��2�.�}�RaUx�(��z���}�sJb�Y�'����>&J��ůH�)=���e��#�50�pz J3FAKB�?�	�@���U��������	�ce�<t1�aۆl��(�6D�8N�U�P��1�.l�},=�S�F �,�G&���-2*�s��V�zJ�t�GZ-W���)�a�C�Y�ZP �J&Y�'m��Џ���H���V��)͉b���K��7T�F�� M����b�^�P�-b��B���nD�s��zt�KV�~��QG���Kt��Z�ۙv��ϝ�f$��jkB��.����}������רE���N�J�V�~�t Y�1͟i8Ob���#Dņ	�g5�\����6�.J2mP���&�i���syG�[��� ��jZZ�M��>}�О�6�kJ��_���՞�[��8txJd��n����&Ew�tu�TS�_G����s%r�N�^�A>�Ub�3SF3_���E��u����8�J��MK~��S���Te4���X/�� (�u�Y+��C�=-ӆ���BI^C5�-꼠���v��G��-���tUs����~�E�����U^���3�4Ȱ��[�ƿ�$7P�J&�&��WB#[�XQ_�rd��1���c6�l|��,2f�@��J�2�U�s�h@\��[��c<��}�ޞ���:A��BT�3�Vڐ�Y��=�O(Ű����Y W,0�������z���/A�M��&-	
~o�c�n@`��Y�n~�|hR^	t�H�]$�F�����49�����&�v[����+DYX���{w����I��^����#7��9W�̣���4�j�R`���+��<P���o�+�<��S��}32^>_�I�^��C˞9:qVY����Gni�#��b�X��<�r���a�A-�H�`�O����;�źXq��ϴ�h)�n����xm*�OS�
��;)�����
��h��G��L���y�x�	)���s���<g7̟���֎D�:���-���H,��g���ĥ�u��ƽ'��~�bw^wX?�Բ��n�i�=�������g!3r���N>��;�sE���;[a�	�������<�:7�,x�g�`�^�d�O���@��v�EoVYto��N��!�+���i
��W�׺���)z�o^յ .w:1��*&�3��kx��e�@����*a�(0Q��a���3�V P�O㫆�ؠ1�ur9���]0�]���6@?y���8}��x�ᕈ��W.DǞ�.�.>b�Ebb�e�e�S�]�1�S?M��x�h8��j|��W�H�sY���hoN���g��3Tr�G���1+�C���.�іR!7���h�^���gѼ�,O0�r�
����ÎdoF��/
�XE}�HM��T��,����+ThE@|�'�+����v�]'m�n�I-���k��X��?J�*Y��W[>�gZ��-�_v!{o�>̾n".�J#w~L�z��6<��B0���HuT�~h?��R,�~�ە��DN�3ܻ� �I�'��^�Rv<h��T��q��Ʊ?�A
!�����"kQNHR�l6f%A\���%}2�h�S�0�������:�bN����{�H�(�_]�!n�_~zݧb{��ӣ����|2ܭ��-���Փ�1���O@�b��/������l�|���72�%�1'@��fԪof��4bTU�]Ռ�(|i��~�uc������� V���Ft:!I>/HU�����ɏx�б�&�e	YW��X�Rf��s8+K�G�˖���Ef;d8�U�|���ѾL�����;m7�2����4�3��UbR���A�~�v��U�
{K�������i��Ǎ��)��2��ɟ���ڶ@׿ɰN����=�����(q��B��Ƀ�R�B�����'{C�p���W�>�w��&e~�*�Vپfߵֱ, %_��c�V����ID�K-�D|��.�$�+�"U5��,�<f�2 ���EG���p���4$���>U˦�J*�bs���tZ8�Q�#�)�ѷ�j� '����/�S��.�
�ג��՜|� !�������\�Z��7!�X�$ƤbY~�:�EfN���\�ӱK3X�^-JO�=��3F��� X#�ٝĽ�'�o�/(��8����C[#�4�e�ږ�d�͉J���!�!���V/�J���q�	�t���>��ҋ��N}h��O�((}C�#g�
�k_�#�����Xn��*�y��%��p<2�=&�}F�G'y�h�m3\8c�e �r�� �o�����KS��|�z%�q�������l3)1 �u��M��9�ji�c�h4ox���-0�<�1d?!�y?S�O�
&�@ٲP���� �2T�E�]������ON�@܊B�*Ā�c}�������R�c�)�g�y��WE8_��C��.�J޲�{���]k�%�h�=a����'/����0��A=��Sڰ����F�2rQ0�'&7�g�`�P��v\7�ٓO*�)qTX�v�< n�Ô�6�M�f@cMқ_����C�h!�����v�|�tT���뎱9��V�!A��#9X�d;�n��v�����@�C���]k���"��r�VH���[>�����GbȔ�C�@�?n3m2�O)����>��	�*�����T�:��T�K�Ԭ����}�Ő�i"�Dv��%���y!���@ى�.���?eߝx�k��'�jj��
��v[F�/Ifmt�&���tYf�,TMB�v<��E�~����f�Q�p�?���.���>��[��yL��t�U��t��]G*��TU�FkU� ���
}��������E���Q툩k;գ*�	�����n\d�"���ǉ�U���ȁ�Mp� �͊�ͧe�����SN+�]2S���c�>�'���ꓢ��<F�h���"��K����.	���N���p5v�q�J��-��7e����}Z��@*���򏅶9���y��oR��I�+Ӊ����=�h˫�?�/RDk������1�r�Uх�C38-VB�W���|�=�2�l��F��=��Mm�(����Bv@�ua�e��EMP8��}��j:)Y3'�)�ޖEL,���IuT\Ԃ~AO�6���X�R�3^�oX�u2sc�����ցiM�(�"U�:Q�E��D��6?#n-��:�CY��cD�L�E�Ff���QJ/u����<�g���Q�?��,V��~� ��lo��-�f��b�]U��^ZfT���&D0z��dkK5"���;^�����㘤��B2$�`��1�f�H��t���_���6�yF=I���G��J��c撖�9Ɋ9�D}�ɿ��,a]���X��e6W���W'�z�T�^�H\.�q�9S�l��V^`���>���b!,D&!� =Z�ex�8�%'�ES/���Q���&���R��"�l=��k�gU5��2���<
�� �4 ��{��~��:��K)���͒K�.(�O��	{��c�'���+�D9�r#n��(�A8�Ҏ
K�b"!Ҿ�~ތ7���l��r�%۬GuP��yo���S�8�
?��v��D�^�>aXޱ�d�M<]��k����6P��E\�mS��H�����C(�8�ww�W��&ʂ�?�Y�O�d'}��nw(6��tr}�o��=B�&,�,��y�j���u����o�n��sq��g���3��s�Iّ7�U��:���_�6K�'?$\�%��x,�QJ�P�ƚ��K��3���zʭ=%Ѷ��9J�����c����a����x��Eaاl�D��6h0���"X2	S�U;���v�n��kl��u7���n�j�� �$�*�l���JK��_x�j|�]_�4��1���Y�ě��F'Q7��ޖ����q~�{�-y�Hu�W�7@ɋ�d��~7)�:.�gSQ|��h��4n�+Z}U�X�-B�`�&Mp���_��wY�bȏ:(V4$HG	#X#�o�v�;9	ZJh8�b��䀮��ܥL�Bo�W�q!Q��LyRX��t^�k�1Pe/�9{��v��{B����P�e,N�i#��Q�����b
�����'&Rݻ�i��p���uR�K��S4����*+B�؂q��i�O��~�O��]��	�J����ؐN�o3����R�򏢳���梿��A�A�$�;_Z�����*�Ѵ��i��Z����ρ*	o�[�O�,�j�g�� L"����~h� K�����I��f�>&f�v�s��ʞ�<2��P���w��W7���s�u&CK"O,�!�����{Cg��+�I62���ۦu��� t�ɬ >[ٙ� �`�\�n�ma��U�jw�����ff����=�P]b+�n�Ɓ�ƓVC�9���'�5�ʑ�H���Є��.����y$��	�(&�9OQHI>7J�!N؉��p쨍�G�~�h�	�Ջ6p� ��u��Dƙ0�Ɲ��w��zFϗap��-��5���Vwr�ӫ��M)��P��$��fJ�BZ��[?�e$"�$B�{_i�	p�1Ϗ������3�,0������c�B]����>����iz�V�LH�g��L�M�'� 5���R��Q�UB��|��w�{���D���g��D����毩���	:\�.U����oR���؈��Գy�S��W<�:� v��oT����y�{�>�fE�@��g��ҿ�M8�]��Ml\�- ��Q+b��&����ԡo�0C�9�9��`�񓝨|$?\Z/�ݝ'g�p;�jU�yA�e!���.̷�kYL}�>�N�F�����q}Ͽq�h�"%M
�'���8YƊ-�����������λ�� N0�V�p�G>mcEӡ�Ӎ�W.#��(>wq]��a>���Å[k ��gL��Ch�\d�V���2� �⇑��>F�x��	��NƹJ:�:�4XH�'�@�h�jOnsJ�9Rŗ���D�%�L��P��en$��ߞ��?+J	%;u���q�Cٝ4��f����_�=:t`;7^�Rq�+n�ܢX@��NC��xc�jW�]��:��]D_~�6�UN�rw�K��}�?�8�P�d>�"�4��m/��4UT_����~�����Ξ���cL+�����Q�Zt*�n\s�=TB���>��R>c��"�@ߝ�{k���b�Ͻx�nX��m�7L��ޕ�.Y�1	�;ҏH���g�.&92;��8�����Go]�I\�%[���+�������*�c�t�L�_�	\d�0K#�XI9)_F�߁T���u(�,%\ޫ�R�e�
Vx:��&ѧb����!z$�[)��%�s���C���Z��󃵌�7�cѹ>ߚ��ۍ���䋴�e.H�O%:8�VS ��Iʆ�0م���`�VP��|�'N�AG&Ⱥ
�v�"ޮ"�x��OS�^��
$]h�(���燚X�g<���)�i<��4��_�~�`�Q]��~��<���UNm��~()E��jc�_��b�hn�5����ޱ�Ğn.σA�mcHG�-g�w���z��F�E.O��_ɖ�j��U�c��+���t�ZW���\u_	�Y>'��6"�-X������+M;�+�p��8!pYl4O�y��D���x�]��y���I����+�/�51�6���6h�x�~��:���V���������98��JM�|�pqP�]����ۡ(9{��DK7��6y>/��D�ݮۑj-��� ����S��ΖZ"��vkja2�u+��pBx뿙�_⌝|��u��zݔ%�x��{����hi�ՏPZ!��
t��[��1�������T��F4�R����0�&�,xMJ��6qqқ���5�$*d4J��sj�2^h�����5����[L���f�"��P����
��:�K�ʙb�������k>&��z���؇�֩�ށԸN��f�v Qq��Y�j�*H�c��,NF���]�x ��>w�c����Bl緙�P���&^�������~r4�vV�|G� �$	ޏ�Nm�~S�L�:w�i��>H���]�N�T������x�㚥�[\�|
�y�h�k�R?0����y�����y�.��6'�	<C�2ɴ�J^���Np9z�"[po���nyISl�����=a9�Z�g����н���Gp<����Zk�`�1��z��H�si�.S�<�2&��b��xu��ܖBQ��hZ��B�}�JA������V�,V�Z�9�jh��4�T�ڃ�b1㩇��^#�N'[��`a�
-"6�� �&�0��rz�F7�A�N���=h?v�s@(6'm���̌԰�����;�5�H�t�}�t�4�{����@ѐ�E��r9� ���������]F:�_���ٴ1�Z����mS�~UG�3c���tl�ɕ����?�+d̷�7�3��sϲ�U�MgSؠ: В}Cek���Xk\���c8]�b#cg
�u�x8��/��j�Q�H���������A������=YBb�lT's9ÑU�틸/��o���Ȟ_�?�5MXr�g���;�����F4��� 	��dC�b�����|�3���├0��(���Z�`>�"��s
;U�;���nx�CH�=��L؜�_a�pO�c�|���b��&���m��[�}7h��d�8v����f�y��+z�%	ݱ�/%m���7�m>Oa�9�>?�В�uJ!s�6Z�X5�c�;��!��Jǩ���j8��	��	he_�}]n��e6��ȇ�Q�-�����jy�c���k��~rCo���rX|*�WT���v)4�Re�����3?O��m�<gԵ�
U���I�w�2�܂і���������v�Bn��3�	�:���}�VF�8qYU�o�a��u�~������4��U��z���L)�Qy���t#�",7� 4S���W�0E];R%���E<\�d<��v!Fx�B{�Ͼ��&MHc�-Պ�3s>��Ru��l��}�h]���cP�؂�ϒ�LyA$>/�#`͑��rL�]��Ӿ��-1;j8�����D�C�l��ĞaE�[t���)U�}&`���х��
Ց�f�Y�H`W��"É������|��Q��U����T�G�8G�6Ko��V^� ����D褹|:���-	������7�A<�i;��;C��r�uz;(U��tB��Q�W�r�c�k��,�I`��i��`8g�.ߥS�OD�r6P?�������'r�IL�ew���a^�<2�۞���8�*��QQ�qn�.A�,�KZ���p"	�X*�K�h�boha) ��KO�'��`Q���7{�H�%�%��m7�h v�_-[�J�.\�8csny�x�K��֏��)�a�΍�5��+Lf�1O�����!h�iؐ���S�	(0cZ���ׂS0��o�ё~����I��{	�^1��#�N�� ���4�f�ۏq�s4T��n�(���p�a"��#�e�/��������
����o������$�lS!�Oo�=n�p���R�{(�Ʉ�Й�;a��)6L�q�	�8[�Я��*	�ҟ� ղq�U�z�nv�3L������rc���̐�z��7�.WIf�9��S��pJ4�~{���{5�"<-J�q����t�N���;�;MF�&��N�]�dSw�8
�ǳt��֯e7�W����Np�G����^���=.u��/��J�X0�-�Y�@j��y����� v�zQ�3��}�����H�/9h��@���!cW*
F������ ��Lt���9�U���\����
����~�{�d��5EZ�h���Q<�kGһ�d���jj�-V	�H�K�zѐ3�"l��Y"�eK�b�25a�q�e�<{��U��.��S�i��-wP�Q��=�ć�J)�z<Ð����Z���S�L�)������h����y|��m���.��ڏ�t7���E�`���F��:T4m�&`�~�* =�����3��bZ��d�A���qK z<oޫ::�OŦ>��a��	��	��C�\5��� D	AY
ҭUi��f�6һ��B�CNq�5X��#A�1�vG�/�{�&Q�/h?��j��!�k�K��8�,��9^Eg�kj�Lrc-:"���\��Op�H��`�9Pv�W�AC�n�3��i/��brIo��1y>F�E��t(x��5�R�E{�16��w@�̇wr"D)$�W:��x�\Հ,�U���IIrf�	X[[��5ϙ�'���m�[���b��b����*�L���%�s!i��f̝Pʮ�
�t���(F�.� "HC�n�������sVJ �z�h(a��:M�v.;����g1O6�n����O�w N��i�m�/�#��1�Y_�l�d�FR�ꮁ���[��aJ�4���s#�@\5�\;�+���B9�~��(�ze�����O	4�7� g,#����
��v �Gf���y>%�����RH?JkK�x���^��m�dN������umm���2� Ni���>�gwI��9��8��A�{���.�vP����-%ѳ+r����hވ�z��P�Q������d ����ƴ�-�
��e���k� ETxS��Ô[��E�����P����k!�����S�[3cN٨�b��L9� �Ջ	m �@?s��Z�
#����x/����ҍYr~�y��\�c����?��r��Չ�Q��0W�:�������Uc��R�&�����W�r�N@ގ0�u��85��9�m�!!���0�:�KA����D�{�YC�e�W�k~�|�:��
�}6G�ۛeWw������fٛhWf����BJ*�Y�.A��4�onf��D���Lso��;��#:����N��A
�YAv�d�%�f�0 ��e�פ��X&8X�}{���-�]hP�˖G�y~�1B9��S#��i:��n̒n&�-�N��\E���o>�C��"V���ɦ@�_^ܾ����{���a$�xW���\���D�Ynwf��΂���uk��$P͇3tq#����I䖗V<J���c�n�av��N�܂��IA�3m��$���7n�_vd}��36��z(U���x~��=0)�b-d��	A������TemE��Vn�b�,Rc�줟��(a1&��"n���̿�_�g�N�f�ݩƅ�S,�F�U�}���GXsvDGX�[�V{D-��|).|���S�oP�2��e���{|r}K�|�+g���Vu\Ռ5Ӱ� �'��R���w�y�UL��{�DiZ[D������T��c���F��4�ׄ+L�0�RE���U��ѯ��1����=�W�d����S0�a#V�T� sc��m�j��p����L\cJf_� �Aq�:L�$4���#"/b Un�� ��\?���Wm
W�G-.U��߅��n8u*�G�=5S.�sp]�aG
��i�F:^����,��#�z�V%6��{�H��?��׿`��=fXC�@-ظ
;3��	��I�=����&KN�>�U�J��\�8I�}��1u�$�x�eN�Eic@[��W���U�� �~>�~%}�4�)H�I��1�!n;a���Uh����.��{��� �+r�d��@��)�y�z�}6���\"D]·؂�MS���&�ܬ�m�M��UK�|�z����r���\�`3��v�3w�2*��Ү�k%G7��D��d�~nb������4�q�]D��6�a���sv)/5j�0քrY�1��eq�2����+Je.^)
�U��ĝPmq�7�Hh�du	�:=d N�\g�r6X�p�Kl�<�U�C�x��f�#�rG����,(����gc�0����$U�&1��tS-���D6ٝ�qM���1�Ȳ����c~붗�W�V������)K���P����|1����o6���P/掦Ѭ�3� �
���+����D1)�-���Z[�����`���r�cF`_���� �%Ç�� ә<_W&Uew�n˅��uXF͒�T��Ӓ�L'0�����̘�֝P>�N�tH���=��\����y/}����%�e�t� �p�>�m�,�$���҂�������$��Ӯ	
��U��]���Cn�����b���,Z������yЅ@�h�����a� �ũ��k�-ߗ����J����#��|���A�2x���SR���r��v�i�im_�X���������8�R�+l�w��9�n���j�T�ٯ`�g�@i�奄���F��,N�;9Q��Hq_��������^Z>]Z���L�2un&0�����o7)��^�b�]���'a%{�J:���r�
W�!��5x�ȅ(�Z86��~Y�J�d�q��R�-���'��hSĥu��2�f�~�;J��<�܊Pe�h�¦���
�
�nk�w�R�o��q<�\xs����|��y�%�%L���Z? ��nB.��,L��n���%à�Gj���D+������P��	0�������i�s�X 1�ů,o�i��&�@�-�G���H���'9Q���$(���H+����e���Q�=l|x�]���~C3�3�oA�&6��4������2�W����h��]"����W�7���g�d�T�,�V\g�[�QQx�:�zXt�5eU`2������!��Hp�����0�� LZ��R��
��އ1�u~ �ҋ,Ό����U��Ī7�*��,���*B���O4:2fIagŞ���Ͻ�Bl�.-��$\�D}v2��^D�����?�'�ڡAn">3}-N7�bj'���p�	���@;I��O��-(Ka�Lv�3s�k~ ��-[�e�u�.c��ǷN(0Cd��1o��o�H�9�E��(���c�Srx���{lO`�^�� �?��ÿ�9�������FɣmY����I���`��S�5k���t'lE.{��@<ظ��w�Ƈqw�	��Φ��#0�_SUncjD�uAU���a�k�Z���2#�o�h���������c����	Gx�L���h�##u��e����<9MY���6�5|�2� � w�7w����&!ZB�&��Q`�S>%%�t���Z�0U<���t�K�S����qF�p_�]���'�����GC��^���m�᪦���U@ri�2�v�H�:�-�4@����U��x�r_�����#��%o��� ǴE(�� �mZ0��H\���JEa��x��R*a��N����y�Z&|F�k�͎��)�skeiV�GS�KNm���A��V�Bz�/�d����j�����Cm��sH�82�����{� &��1�\`����x�#���}�O�����B6���#�yP��W��jА����2�S�f��p��ٺ�8)��=x�?��2���i.�T�
��:���ָ �c���e��k������[���j�;_�aK�Lŕ6������3lF`��TO�D��>L{�'u���/J�W���ߕH��4�Fo[@uv�?|Z�f�I�����ƑΟ:Fby��%��q���ذW~1}[�fQ7Х �z�Q�=��c=RK|���A,	";� [��Q�M,��=�W��*�ƳG���!sxyE�찧#�{7�ʱ״�}w(>��G��ZK��[B�M�xK{Q4��h�7��Mg���j�QUY�c��q9��( vL��������w��V�i�|Iǳ�q������P��C皤[>�J���������`^kE���zy����!!]-����m�d�sA��K��35_�dV=S4C9�i�3>�$�2��r)���n��E��UN�y�4!MV���ս�;�x�%usԚ�Ѳ����H�'=�V�MV���EɃM�l�ɻ���?j�u���;�o���}�0�b�)2��ӱeS�7r���]���ZqR�Z�`U���H�/�����a�#xt�NgJ����;c���^���$�ͽ�����V��%���Y�.��k���Lӕ@�M�q�Nh���IIxݷt��"��]��,M��C��O�D�KkH=ⱇL�մ�̗�v�?\A�4j�tn�ʳ�����?Й5<���i�gK���w�����h�3j�y����a�ܰ{����![A�I�R�Y�����wt��T@5̖V�Z�<Fx���W�1�AN�͛�	4X�T��M:n���#�2qo=��<��0s'��2�v<\��VWl��h�6�ڄ[�,St�ݾՔ��t�,�2��v)�R��*�;v�������j|��v"�e�ܥ�ri�y�g�<����Ԃ��pBW�?��@P�D��ei�n<{�.D]z��T��+��E)@��I�0�"-Qh���68���S��!_�0x-)%u���=��BiD����*��>�,�>�xov>�0��к�Z�1�tON��6��A������D̒�A��Ęp�����Ϣ{�(1�:?4��_^����,��}A◽��~!�1��@��Ҍ>�e2����K�f��,e?w��e�M�(䮒i^��z!�$��;'�d,�ѫ0�WT?q՚��.�:3Z�ՆwY��%I�������u����ھc�t���O-��EO{`~�����q�i���Rcd�ћd2��*Hc���Q͵L�G�mT|�@�S�$��;x�������yƐ��IT>lBTN��UXƱl�e�Y�2���V�k{���qe걊͕�a��p
�N��q��z�&:�XE�� 4�~����#�9F�-i���ĝ�<�WS��%L����#\`x
�}�k0���뼝���*�E�T;��Չ�Tnֵ�y�>s�s�!=��>9Q����$gC0�������_�Z��aD�$�'>�f�BC����l�4������&�B��!ͬGJg�D|�`�۔�9��Z^g(|�؟�,�&��`���h&DdO0�Y�oG����)Z@ y�C��F������O�ѕ�6_�(.8����Ǐ2��H�yJDp��8��g�`֝��e�c7D���>Sqյ7�D	��$﮷�m �k"���,IO� ���A)I�?W)�z7��UX����IZ´�a����!����iu}}[?�ȫ����D
�<s��ꬒ�nA�J�<§O�ߧ+��;Z�_ɟqW�*$��Ȧ����/�^�_���V@=n��}1�O^@$�����L���aN�V�?���xt��غ^�\�2�=��)J��@���$�����e���~�Y�ykN�n�-��i�f���8W�S善9��WI�h�
�j*bo_����=��PIJ���^l�6�Ph�E�:ԉC�xQ��@�^�5��ne3�V��B[�MGUr��J(F�X����ۨkON^���Y#���\����-��Fz
�S�bB:[���,�=ᵺ��0"-T�mff!�9x��X1����M^��z���6W��SS!�q:���$._gY@,�50{r1����]�,��{�:�a�L�rGd�t��E�������?�-�HP�w���x*
��t4��0�U
+|I�Ǔ���p��qK�3p�v�y�������4Ixэ�]�5)��(qի�2쒅k��Y6&)J��_?� ���;��+��u���~�Y��6�N߲����=Zv"�x}�VT�jV�K�}K$�"F��A2w���\��5G_�eS���G!W9-��pG�1����*[�s~jQ�0��#�����&���+�3T�/�Z/Vy�ڛ��%֨�nm>��[�C�NQ�>����%�B�C��q[���ʍD�:v��uc$����9덜[`�%��駓|ۥ�2�ܟ:�"�� ,���}���L�Up����1��R���:B���޴����̉ ��T�����
;�Hm�T��" ����H�l��1B|�_(Y�f�g1g�O�C�}����7@Q%Ƭ\s5��<�z=:.�?��Ζ�;M�	��MPQs���8h���5��7��F=�l�M5�9`uI��L>�X�{3�]��
���z�K߀��2U9z�����F���*�tج,4$�
�ccjO��rާ6n�tX�\�c3���F���B��sPUO�u}.���Dl���HKt�O�o��[s��A+��B�M����&a��0��0g����*��@hz��c��ie&�ӆ׃5�օ��ڸrz�7;)�>��˞s~U�O��&0��9x�&���7��C;
��0��h@*Ӝ$C�ʆ6��}dx]��tYU�����U�ؼ{����˾���-D��.��^���p��#� �+!
�VL��ԉ(����z:�J�����8��<�z/e������3�l>L��G@5�,?�⢆�%��>�$u�\W��?"�7)��-k�vw���r���D��+#%���<�{~�Ϟm�LS�}�y�h��ѓ���ˤ/��Xb�ǻ4;��]��� Bk�_`ͣ�[V�JY�1}ߙ��u�,�ͯ�(%>�� ��>�cРpG�U�*+$���P�yz9Ѣu攅�x\0K0L����!d���ǌ���Y��htO�N�t�h�E�8}+S0��3�U�K~Ϝ"��(GҺ�_z�4�`PkKz�gs�= )�i����r������OʫXE��$���y����pT�~�m��V�7u&NA �Cw���2�@4	�aM���t��
��
W܆y��0#��z���˥�S�P���Ւn:`��	�j��b q?s�����!$�_(��o��� ���N�����������<���^�E��^��B	.b�	;bQ5r�9���}��ݾ,��gt5z=�0-L�����ͺDygҬ�cLf6�E�ڨ7\�s�砲�̑?��>-�&�7x��h����P�1�X�[M�ȃ
�]�9�n�3��>�5�A��/�zQ;񺷟�!���0L"qӮ3�j?�P߿���1ߺ���q��㸿[�T��R2���@�˛!��^�vE�܏t5��*�FC<&�KYCS��g�}S$�z�vl�Fz�I:� �U#X��$�{��;���������C����T�����8gNr�5n�����S�]�@$i"t���vXfv=�C����`JH�3���+�8O�Sw����>��M���ʯ��e�{�8̒5rq�q�=p�N6�D}k!�M�?�j�^�� �2�C�����C��!���o����ݿ�!�y�ۻ�D,��^8%M�s+A�����!�M����%��⽇��p�����b[����I�W�vs�˽�)iO��{�'2aF�nw�Tv�s��Y�\)A��`ʠa@i��L�R�f�U�vh�1�S�W,�TCD�Z�E�U���Z8y���1�*��*Mw�G4�_��9����P�׮�sd3q��S?[���RS?���f�?6)�|�|�|d
�$�E�Dvj���{!��r4��g=]�>�r�A	�9!~_�ݤ�ј�+
~�㠁���q9m
&]J�T�.�f1��1���(������멛>�=I�p=@Y��h�6D�YpfM�T41��I��S]L_vң�Q�$Bbs�-j�s�z��c��jݫP�5�m���u��i��o�������#4�����C��9�l�ź�q���,���pbF�S_�eP����
��WߝF� X�eFM�s�D�� ո��HN�C+��x��[뒬ܼ#A�株�C�Ǯ┏%r��h�z;Og���� G��L�����+?����?Ik�rf��G�(̴�y�/��;�df�e���5��7�}��-�쥘Yh��3�	b�#�ߡ�w�^O��lvM[�b������L��䖽�X��yڛ�&i�c���>�y7頟�Wi�c����H�E�W�Z�,T��0V|(��l�h��b��G�e���<�`��@�����wQ^�O{�JHk���}��}�k�=7�.��J��u����?H!|����oUw7g��>,�C�kPZ�_&h�O�G:�);_��"F"\��T��f�ׅ+�^���1 �ƣq�/k���q:�) -�Zo�K#����� ۞S+�ݯ���=�ߌ�f.H��֒�Ը��To		����/=����r" n8�ZG�L����n�l`5h9U�y�!G�ۗ0c��m�h�޻ˑ��/js�5o��!��H��5��
��<N�4~@�b���˛	�����'2���fMvK^��y�����[�A����=�B�rz��S�ō�����{�\aQ~��2��䲷��S�&�<(Z�ܣX�h�[��a��Ր@�.9�B'���:U�LI�G�{O��aL4�Mg(�d�š)�h�S��nnͿ�A��3�g!�<�&�N������4��U�y�$=%��k�ǹȎ<S�>7�D��{��1����6�Kᝡ�߻��.YKQ�£�X
��Gp
�4ע4{��:<:T���yY�Q�*ݙ͉��Hi�*���I1�M-�ELT���5����\[�Uo�l���4�2�A\��z�e����57�z|ƽ�g�|�����:�9]��R)Q��K�t'7�$����v�6EyFoP�������=]��߷��0�xzX���7T�4@�
�SY�a��x�h/���	���8ӽ�*K��G���8'۳e�ڰ����q��	�<��%� ��,���A��!�q2�4�~X�-[C�϶�L^�@~��V�k �#K"�3����j$�+�~��m!���2f�:�(�&L�>7�9ɼ�m�o�AewIEO<�}����x�e�wh����������DP[�L�`���i�$�7�&�P\AyA"!�B֐���q]�w���n�+��xDEg)o�m����VHx/#��
���P�21Ri9f��F�'�Ed��U���+�5Q^Yo)_��$x&�,@T�m�(<=W��u	���\������ ������@����'X��]'M����d���bV+�l�O۝��\�x��b@�l���������f�*����F����༏:�^�k؃�(��-��� �ܼ�TsMܷc��F�n%�k��C�`N+6>�r_WO d���	��$Z�LC�k:��W�%4��>�Z�e"Z�F����f�rU0se�g���wC!�|<��b��-d�	���\�{b����1���;w%��90��Mڋ	'�4G"Ɓ=���n5<]���_���'o&)�w>y�5П�]��9��e�'^M|*:��ޔ�� �VG��Iz�$zF����I��zs8o{6?�.\>�v���n�I-o-`lq� ����z9\N nh����K1D�?x)� �7�Ř[�-Vg�}{P�}��
2x
��@i(Z���-(q����S���=!�	��V?a ��2��H���v!���BMry�y�S�9`�]ü��ܲ�b�ܪ�S����M�#M�z�����ϸ������W����q�_���P@Uq����1�� ��X��u�ݾ}�y�ݪ�&S�+���w�
��\a4� �]��0t+�n=[��a��׋�u�����u{w^J���Kϒ6f B�M��6�*tW�\��n2�;a�D�#�2�gP�+�s���Z�E�]U�L��2�f"q�2d�B��߇��z��D7����z}�����<���m�F���86�c��.���]�=go�y~x�[�"8�P�� �|��K �ev����H�9|���>�٧��&H��nX�6F���������HU��Mg�����MA�EA�e���:]F��ʞ�<��Aް�z��괴 ��l�&�.�Ut��6�k�Nh��%�Nq��#�ſ߼���D�b�:��C0+>Z_��SBJa�u	aI\�/&�A���P���,���O��شL��M��`X�u���g��`M�#�K\�����W�#:R�X��.���yGo:��/g����na�-�St��W��c���/���ᚑ@�:$UӤx�%jb�S���e���!�G-�K7mN���\5�}�w��^.��2�z2�n��W���E���p�nu��ӴW�4��*V/,'߂�b.�|��@;nW�����1b��~ �WU9�at�M�h6K/�ֽ��B-����ˈhg'b�����;��b')��~����6\��v�B{#;L���;�È��Ka���i(��EǑ�	<G�
Q���P�t�y~,��\�@k�Vg'GPy
�G9D0�����U��d�]�"]��K�	$�Eu	����B����
���nt�Q�E�S��XI��;���;�'���8����$/J��	/L�%:x�����sh��͟��Z���<r�zjp�qn��6�F	�BE�=�����4y��
Hb�e�ISo�=Гs���Jq����@�[}]4�P��{��9��*@���o�}�'�k��
�xW�͒+q)]��x���o%B�egi�����1�h�V�*t�<Aj�l�l��e�*�'�]屼���3�\�����7$����T���6�^���;����󸀁���h����,�����վs�}�ɳ�,u�v�g%��@w�)�r�s8}���+1������~D��h�l<C��Se����I��-���ln�pj��C �3)��X��>�w�S)�.~��?Q
=�M��C7�2��fG���S<0b���ʅ.dJI�K���}���H�6΂,^{w��X�]dz�5�&�9Q����Xwv-�Y���\�2AeAP�!,D�4��r�g������/�x�����h&p��隋׍�2iخlj���,�F@��!�y�� 	!�WH����u��%36��[�:ݐ���?w��R�A�xj��&�	߄g���ĕPIЪ4��QM���V���ƃUk�9�X�ז�S��Խ��
�E��eD�W]^I�ZR�/&>��#j��[�J���ኗ����#?�Gv�D�~M�V���0�f�   %%'H�I�+ ����	�����g�    YZ