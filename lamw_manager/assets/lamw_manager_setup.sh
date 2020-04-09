#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3640564938"
MD5="b53abda1fa4975393273036fed35e105"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20808"
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
	echo Date of packaging: Thu Apr  9 12:23:55 -03 2020
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
�7zXZ  �ִF !   �X���Q] �}��JF���.���_j�M�1�o�ׯ�.n�9�����=J|�9\(�,���o�D�d`�Z�Ek���{���t*g	�ws@2�<��1=� ���A�숴�P�0��w5���￫�7�I��LT���� N(�RT�6p,l��v:N�(��_�9��2�BI�ʨF��� m��Euu�%����\0�lR_f����6��l�́�4�n��@&��J�>��#�75\"}�34^6��?��{�K�����=�P}*j�b�"!�Ut=��H��!a}"�����G�"%hp��C���5�[�h`e��e�����_پ��~"��O$KSs9ZL�/�h�^��6���|P;�s����f�)��.���(�M�Ќ"��((T��.U*(;�.�p���k��F>uc���4�R	�uq��:nD�F������D��:���c-Hyu��'��lbs�䛯@��(�G�$T�)�[��7 D}��MA@,��!J�[}//��c�˙l��u"�P�Z5��1��#d�b��bU� e57^�<�,`,�^���g$��kZ1>,���A/to��"z�0A(�!�bN�?�����+XL��ׇ���4���ކ�Y$o2lx�Q�������������o?���p9^/^?�Z`��de�VD?���v�b������i���6�Q��ֵ�?N�Y��W�Klu��.�8��Y���7�L� ��c(K��9Ƴ�ك���E�$ޏ%��L��P�I5�I7;K�����T�����%�:�FN��g����`��k��K������6?zLQ'Ս��'`0�0���W��Q:ķG0�����M��?!�I[���ܒ���\"3�V�k!�C_1��?�J�==����ئh���Ǯ�f�VjjI�?������G8d�������n���^Y��ț�b�}�5Lᴳ��P�(�q=(ww� dV,�3]�4Sh��)SY�����CC�:��Q�n��i!&���L��Q�͊<_i���c@�ov����w���7!;�5fW/n�Q*m�5�q	�.G�]�G>6�4������zV�7r2Z���>��A�|�1}�$$wR��.՗���}�纰� ���<"J����k"�]O�A��!�m^}��0%М�1��C{�y�u�ʷ5h�5ES�&�U��Ɋ��?���o��?�T�6X}�.�n�����\�y����tn��V�|�=���C�מy<<�i&�~�����Cg����{��4A��� /?C�	w>)�T����P��OR�RO�T5y�J�P:ԍ���GN�b�f�u���|Ȇ�#�/<F��X@9 �3��Ώ�G�ף!t��q�V���@�p��k���rl�.�gU0�m��;^V�1dE�p�ih�pG�1 <�=~<�Uev�[��4~�ոC�[Ր�W���K�G2.��
;h6�tS�ug����=4����4�mv�ㄨ�h|�Qz���(%����/M��\�k."��c;�,d��0z��m���L�n�΀G��z�(7�{�c�8��w�*[���)�⳻�1�5?c�D
��ݖ"�lfؔ^C!�|s��#((�5��ةW�}B�W�l���j���LU=�)/����D)�T]�����[a>r��;:�����V���6�0��hPJeZ�Ԩ� C� �k(%T#7g`���� ���R}OW�
a���;�')�3�ܸ�q�hEV�ݩ4���(�s 7;E�d�|�P��}{I
��_�MѝxF`��'���}��9����-���80��\���� ��Ȓ��A)39p)�`�h9լ>{� Iw%���	��[<r `�s����".~#_<(k"��Ԁ����Oi��
c;�HD��y
Ŧ'���:��~+/��G�)CnxgK������{�5�#�[��1�k׫NI���5<�EǼ�4S`ũ��ȍ���Go���n�&�-ĸ��06�����6��XX�f��F�����わ%�6z�Љ���O��:ܤ�!e������]uh1���������^�q��"xw�� �鷘$���r�D2���r�1z(���>�t�oH�����>9�!���*%�I����Q>��I�ٖPx���q��H̢�9m.��ߒ�D�;=ϳ�e��O��|��~�kG���Ty6�;���0�@�DF�s�^�$�a`ȷ�|����a�J������p�5��XRR\�mܙ����k�!:��B�(�M�w����J]	�{B�W<5r���gw�jQ����'�˰�7�t��y�sLkv�_������h��n]�hș����s���`4	W�
�i喝6����Dp�I�gz� �~���4v.�~�3��w�b�(�y ܀���P���ky��ǧ�-���_��7�_�e��n�	���	w�� �L!����[���J� ]P�Yn!��ԉM�=�`��Ձ�ѹ�'h�b�~���RA%������eM�O=�4w6���%�z���y-���E�V@H�w�p�[�z �H�h�������y�G�Q�ܬ34@C-����|J����MOx��cD?��*~�p��Q.�'�(�ʬ4&Nr5`�E�?"z��]�B�O?]����ޮ�r���^s�58|�	
`L���s��}>2�TA(��\��&T���KJ���)�a�'����vR/'�&�C�4m����l�'p"�q����m)nҜ��U�u�׸^����h���e�8�f�ue��oیMgW��8Q��0|�=��?���� �ta���4�.Th9;�Z�T�f�,~v��Z��F�$gQ�
��Q�>$]Nl����~�z,��ch���Lpڱ��IT��<�ߔ�<KD����������?	.��{�#���k$�8��6P0�v�yi�1w�h��
�G���!�t��]D�D�U����2sy�R8F�d��t�K��O2�Z{�,��KQ�<aҾ���h�O5ڰq������ۀ��0v]��T&V��g����Wˆw���ّ�>���	{��0�1[֒d������anjճ:=V0�\҄�l�4�G�W�\��Bc �4&��t�Q�gJ��NX>�@�wϛ[���Ο�<]�]��Z�ji���0L�פU��ڒ�leU���!�I��?�~��gl$��hr%�G�.C�"--��;�Gxq[�򠆄�_��Q����6�%}�sƧ���^^�tX�KI�P��8G�ڨ$j'�z�2����)�"�ݓ��W}.T���?��Hr����mg��>|J�_�mzӬ"8Q��X���@}�s�?^��� cp0�E���=���Yn_l�[!������x���Ԑ��oSW����<�����,W��[��D��/�n�t��u�l������֍Of=-�2X	�C��}a�a��%�'H�Ht�\ˊ؄^K�!������<��� p�;�8PG��������GSWD���8*��,�����W~zm<l�P��@_b�E}ţѿ1:�2��q�0�6
�^T�]��������.Q���*D�E�Y����i@�Ҹ�rgIy�=[۠@�z���]a�%w�]0`�%�+��KF�*��=��b�q�ǜQ`���}<�*�'�ug:��f�l�7�aʈ*a?L��w�/�;�)d���-������1�S��f��ʋ��
X��L�5[�s��
�K��MfS�p��ƘF�]���;�q��Tt�qB�I�ߌ��*$��ΩöTg{k�1Q
]�Te�B�=&�[��EC���@'MX�e��
��c-���RЯ�/��"�:��C��N��
P���C�KU;#[��c���H����)��|E��73�!`tٓ�1Hc��O&Ķ���<m�<7"�tR���&(�3�}�W�@�V���g���`o�E���z��=\f/������R}�.-��(n:<�x��v�xE�>p����H3Y7�j���6x�:`!�G�7qz���s�G�Q����Cb���^�eD��ϴj ~l������� я�$ދj�6�%�H)H�z��L�4���xQ�]\C�,�4��6^̖A�^=�p[�Ӵ���G.]I�k�����?�Z���֢�)�Z#�*%�������|�.F�S+Z7RX�I��.�'�؂���S� HUq��ʟ>�rMن�t�b3zT;�]���DZJt�
����V3�5�%Ml�ў_l5k����[�g*���L�܀r�]G1C�Bn{�}>��'� ��O/�,Ɵ��}���9*}�v�z�*����sKH�k���(K���3'9߃�Ր�
���F�o�&���lH�ʪ��.�q�=۴�ʶ���\n@�րl���e��ߍ��O��˲��(�,�L��"][U��?c�F��'xP}d��[�V���b'9�.�zNH^-��ޘR�_�"Fn�4-p��4��R��=ǐ��_�C��������6u�-�ۘ��yq�_'1
���E�s�G�/�}�1%�Շk��S� %��LPE�:̴h� �)����#��j:��<Һ��_2��<� Y6��fQ[�^�2����A�;�3�A�X�JD���6��e�M��u��w���ytâ�&|�?���nY�T�Iհ2�y��ހT�>��j�R瑇Q�Ԙk����W�vax���U��3�m�I��Ԡ���K��L�<�C6������I�8��jIE�A�l:��L��.w.�+&K�:Gܺ`6"���:~�Ԋ�T�jM��hD"G�o�x×D���"ʆ�B����ya����3�8�U{�)��-������!�{y7���W�A�G�ܰ�dD�h�$�ꪌ�Uj^��B�f�V
)�H���H<��:moo.C���jM�Y>E�ߗ��b�I���*a+���N�ℤ�=:��*��c�G�u���'s� �д�/8��4�0^4�i�+�ѓJ��u&�oP]��!_�>�����a��/W��욠�־��U^�7�s��$$�M=gl�?�8�|�aȳ���Rx���������rG\\�K�Ql\��TX������{k��,��<�����c� #�u4�:�߁���0}S%lm��P��?��'A��!��ٹg�4w����X�L����Ӵ�(*u�oSG�d���*�95�z��8��~���賕e#�V��j�s�B]��)i��W��~Z� 3G��Iw�p��s�W�ۦ�뉡���L�E�G��l0|�0���_u���!;��v�GJ�D@dNu�'4b��F�k�Rf5>_���Q̓�pC���lg����ò)s����|�������<��+�%���/j¨�X�&꫰����PփU$�Z��5Qk0pH����m5o֏G�;���*JP�@XZ��yC'���v��N��K`����}�FG��]�sA8��������#��u{M`��\0�� ����~w�.�����D����U~�t!�)��>�7%��
����2S�?�h���$@��Ta6��������$�*�"��_����������&XO}U�H�w��O��)i6	��5r ��U��Z��f����}b�a��HP�N/�
���"(�B-����,G:����i8�{���Y?jQ�g5�:��b��}�<6U�A�����j�*�5��L}����9ie�F�����e���/f�/<��UV��ˮAޤ�����'�Y;a����T�
���ۛ�YK�N�$ǧ�'�GW��&��g|���k��C�
�w-4��g*;)k�|g�	�Y�4(Ԗ�����t��|u��)�CYB� �:�&�2��;�$�ڒ\;�ǜ�[�d�d�ho0�V_~�?��N��[4��3 �MD���0��aRop��[�=���Z�X&��"b�Y�1�ƽN~){,��E6Y���A���M,G����-��ԓ������`*P-v�,1jԁ�T�CXM5K�-c?"b��&[Hv"�Q=
Ԅ+�Oo��ډ�.H���i�=Q�`r˂-ئ�%�%���O(.{� W@
��~� 6�jvp����끘�������9�`4�0p#��v�d!�ZDDd�6��=��Hڒ��+�	�LTtF��~�;oA���̊����)�?�t�F;�(|NN��]���p�y+~Ľ��wcGȏL>6���1�
�_��;�����@��fq(�	�jopU-�cVӣ�ߖ�m(̶-�zC�r
�^�>@�`@,�e��K��^�J�\��_�P��6l̰�Y�����4D:ZQ$�&�������,��xg�	�zƦ�"L~�[0�b ���z����l�Y�o�L�Ӈ�-3�hJ���)YA������c?�J�ݍÞ�y����w��P?C\� E�Ǭ\t�@T3�~/��)�:��FG�'�R(Y��<��Sm�[�����D>��O��Z��OD�B�@���C8�᫝Yg1��ͮ�4.�/����{�,�kXG'��z�N��������p�Z�ϓ!�@��u%J3���3�w�Qr�>'+g�\m��"8�`.�{2��8�z�(����=6.L�[L(����7��kc� ��H��G�aq�d�����tiIca�=f����r�֬0MJ.I-�l����܆������b��+}��\@�"eڨ��{�іi1����F�y����T,`��>�e]0)iB�O��d��G>2��s�i��޴��5h2L�	m�rj�П"{�h�:{Kwx'<��<L�Mn�T�iB3�r����|��u�tݤ�I(�$��FŊv�A�������Pa3q�:gl����,̹�P� � _��5����c��7��p��(�Ɖ2�ӥ�$�:I��K<6n�����򠆼�*�!؎ᨁ��ܳ��,�a�I�П�V	�`�����qZ9�.�(�Y-���HɋF��W���{d����M��ǌ����.|�w&����P����"��¬=�JY�||["��_���O��57$��6Pm2��)e(1)�:x:���*~	N^��4�M�%�YpR�}�z���F[��x)����[��̇�M���YH�� �E�p��&�'�T�68;�4x���\7������lI�C�MM�� �O���4^�,�nXeJ�0��@�;�^Vۖ&r�}��+�ǓT�������Q(�X�U
 õ�X�C�^���#����S��F�xa���N��H?MqJŪpm�擅��Z�%�k���&���Ի���4�xW���]��GO��-�Hc�ӫ�t�Qr�g9ݕ,8���m�χ:K`��N�tE��0�ߥ��ʔO�^ �w6�r��k�V��ddŏTXLrk�a�*q<�#�z�jsū���0���uslY�\����{1Ƈ���u�{Ͻ��v���oTEw.�b�L�����wj��cG��Ƣ��H����#�'�
V��P�x���Rǈ﫵ă�KVy/�z=�ƿ��w�3_�*�c�ԩ��х߳����+74�ʫ{�|�#W��ܖ��aHf�_^�?CO���	?��a"��|�f�F�����Kn�X��嘡x|�ۦ����<���\��K\X}x��^N��g�(�58�i��H��U>���W����
T�r7�n�����z�4	}��#��8�+oI摩�m���:�;#Gp8���[������H�}ז���|��=o0�S.�?��Z��{�w/��W�Z�)��@���燳^�K�.ڌͰ�_��j�c�b��Dɧ�6 �`s�W�"v�;=�E���'s$�Ͳ�M�Q0R�D\0X�����s�Ol`Y �d�m/X�J�J?O����/���g"��oG�U��~���j]����S�B���"������VvM�y��kL�C�ӆ��$�|#*��6
�����*���Lt���=��Y�7��o4��L��ʼ��)���2������1ٞMM��$��i�҆�<sC����wO����ѦHmҽ����F<M�y�q�[<�7���X�?�=]{i�IR��+�s���3B�t�o�@S=@��5^�dp�\��� (׹�$�����$����?r��{M���zH,��WD�.�c0�[��a� �[������F���,O$"g���H�\!��qA3�=�>� �5�0�kZ�E���)B���ƩGr>�:�'g��hܻ�j�gH�a9X���r+���W�g@Bx�(=;�=>�� ��@���&��Q��O��_�5FJ���U[�HX_`���OU���^5�D�@�93��߸ë��~��}!t����uǑ&J���9rjD�O����m� ���h���{vg����2S�jVA,%����$��������>S,��r{R�I�����\�o�Ȥ��U�&O�Ԁ�#u�o
�'��SC8�O�V���9 FQN&��������IW���Ƣ�5PF=��a��1�h��%�8߿�tp�m�<<䫊�ɮ�Ft�ZT��1'���dmV.���m��u-|��	��@6|n{�%0�(�-�R��frэ��Z�;K�����1���H�v@�N�H�y��j��yQv/u���X���&1�׈��/�v{N��,6q�O��w����R;m*5���I�_��O~����3�+����?���~�����fN\Kv�=~��0E���x�d�)q�t�B�T�����R�<G�b���#��i҂g��2-��,}LD~oB^M���J^bV�j⑐���!���b}D��R���0zq�p�rg*�a=��_�?�P��Z�A�!�Uf*|g��ț�9b���	3�L![�m"��]�ΎH�j��1Ėd�f�I��Ǌ��Ԙ�.�kʷQ��J��_}�8�#u�t��!��R�1�e��)�^ɋ1Y�=��;p-�b٪�36[n����̭G=������Z߭Tƞ�CM���ii���J����*�Q��"����W�~�O�w��Bs�o<ծ��+Y`?�"P_�C���
[�w�ģ���2��-9	>��l���	�= BE������i�@��U�	�8`�Sp��� 2�gX���\ ��9��D�<��M^6<avQr[p����m)�g�/�c��DO�ԩ6@wt�N�����QL|�<jT��bI����͑Jd��عo�n^��6]U���� �Q�\o�������kh�Vʍ9��ĝdv��Q�2�f�<b�e:��zz8��;�R8�~�9�}{���+��K�v�_�aB�o���sC��zE�)��,��}�Mљ����,N>�}c�$��X�"�l\�g��$���'G� C3���ً��H]�'F������G�iQ�ۿ�0����Y��辎+v~�Y>��v��E��R}��0#s�p-&2dr��a>�ߺuSp�����ʹn�D�0:e��V#��n����D��^��]2P�J�]7$oɮ:r{���:]V�Y8$p�W��ނ�� #G��Jz^d����E���&��<�A-�����<;�KI�F-8��+��!�O���w�#��@LH@����&�r�v5�=�%��m�9m,}[㿴�%x�4n�Q@��Y�V&2:
/�����`����+Lot�˫?Ȣ
���_�Ք��7.Ј*]�þ��D�%����_r`�TQ����F�y�Sn��,���}W5>��yt����97Ji7��OY�b�:e�k�.p����=gYx_ϳ;�����w��j�g���m�@�PB�}V�o��-ӥ5hr�@���3\�rŮ	����Q��q�p�y�De�����A��Іa.%z����(`Ye��*b�/���hkB��0P[��%������A<����/�/�)��G������Mؑ�l?���D��` I� r�xC2z�E�F؜���c�[�a�d�ŚV�K K�z��C����o�V����d�@�6��r��ds�'Ĳ@�-R�d��X���p2O=�F;�~ǁ6-M(�����].IL�Һ��u��Ј��zj�{篨n���q���4LŀL��O�e���(fu0N��_F�[�	�<�<�߻��jT���CfM�G����_sb��Kuz����X��aG»�}��e�����j�b�*be�b �ĤP��ǅ9���wt��W���X�;sx�g�E�'�������<#V94�Z�@G���s	H�͇��U�\�fO.ݯ��| m�0Y�7�������JC9�}+�ԚǺ �8L�� �=�;��LQ7OP?@]�ڵ�Z����+S����p�^���MsO �D�R(�P	��m�9D��ñ4���B�Ӫm���w��sv0���"(�&����q?0���_��Z��5F4�nX��i��O��M��5Ho�`e��e:`$�C�SA<���ib���n���.�8��x���`Uhs��T��ApLh��"��Z��_�r!��h�/a�&��[:��:��h"%�d�H-B��7G^f$��hQ�YN
��ނ���^W�}��������2�#���ql^b����>��2d��p��ȷEOغw����x̉.��y<��I�up{BlNF���̏���q)L!����M&N'�~?�pE�D�{��d�lzoh��ɽL����Bõ���8M�nx���.�2	�N�<al����k����a����bS�n2���#b�>2o���,�t�5o.0��#��[*H
�p����w��e=&'[r��xP���O��T����̈|c��ؔ�m�����=��0���U៧�T�U9о�a��ǳ:ȵ���Y�^֚�]bn��=�d���^j�a��k���rY�v�f����4�'�@=]p(�������!�㖫���!�BE��aō�,%9Ȋ9~�[4�&��"�ed����X�\k�U^���C�:�yogc��K4"b����hV���|8��xDs.z���z�P[I�3�&�;�iOf�Yx�JV�d"�L�\\ A���dtiZ+W�U��ȷ���M��Y
#=�^:�\����җ���zfΣ���/ClLnP�S"j��PѰ��-^�!W�օ���!�i����R<mߒ,w��c{t"ڲD!�Tx����q�NX��H}��B�l����h������`](F�5v�	�e/�h���"dEo�g�f@R�I���?� ����oV�0��v���/�|��#����GÊ?�Wf�����{?��/޶7ۛd�3�,]�Ħȓ��k�`]�"R�5A 9N_�g��-n����b�^ 0cG�>w��d`Q��h��%[e!�3��M� ��1Q�	�)Q}����}l��Aa'��m'�$��?��/��]X�Ǥ��~1�zk�Q�?�|ryΌ]T��4&WJϡ�+��C�Eߠw�<��Y�����"��G���N��@ N޾KgH0��ɤ���(߈���i�8��4\D�@:Y$����j����V�S,��ͭ��y��8����Ӻ1��g��N����fהdM!Q]�I��e��(vM<�;��!DD̗�FIi�������\X������-GX'�����^�ax�ے��$�:�`���>;��i�鉶{B���>�V\!YR�+�:��jq��~_���W3"?x�`/*���Ǧ�oqJJ��K���W���gi%o��>+�����b;�j!!˼����M��X?��ßP�M��oj��3Zb�o2$2�Gǟ���^��	�-� 'ǆ5�"���^��F���~#=������G%�~����m���'Z���,��N.?�B!,�v�	h�ͳR��Ȥ�[��@W��f7���5THU>e�r��B���;��7�vg|f�v��Ft�(����C�O�>�G?�/˫�s�����<�t " %����B^��`�w��D���.+��h�^�c��b���|�Xs�`��Z�o\�*ɽ̵����":�=�)�Y�,�=�|��;Y}��֥�M!	��?�D����W����P�xUtQ�a?���Pb?��cD/} �e�x�eb>G�{�ƆavRVo�1�|N�<�S�(��wk�qz�|��:s'�q�"ca��Wa�"�Sf8��EY�v��!���^W�m[X{ ���zF�bTz�@t��,���o��yٻ(����0��jf)��QY��F�~�Б�6����K�q�ɬ���NS�7L]�_�s�m5t�Ӷ׊M�'��}!Ř�.8[������BH�|Q��G�I��J�/w;"%��}?�"K����z��l�*VJ���F3i�2��PxX&�x�(�5x�\<҅Je���`9T�%�^��ҍl���|������D�w�}ҡY��,.��d?�_ʞ`СXE��)pF��h��DP�J��2�{��
 ��/���/��E���)�%�O��6��'G55���ǟ"�d=Lnx>�;��PS�� 4>_��WKQ�،؈�O��x����>��,3�ag�O�i��d���j������P����_|�=��#�7+�ü�(`�V`��J]b��T�A��f{�<I�k-�C+h��z��Eg�t]�ۤ�>�K\�/���l+_��紟���~�S��]B�A���:՗ETVF��1#���:D.�#2�*�2~��e���0�&�3v�O�>�\��v�ɿO5aށ^�'�����ֲ|\ϳ] )PZ�����u����G���'>X�h�Ĳ���z;����]b���9.�	N�P���Jn<F�Qj�G59�JS�d'��D�Y���D��R���&��±�n8_!����ͲfG!�����j�ŘyoѢp8�P��T��)!�͜W 5��1\e�ە��z<>�����6��w�/v�H�=�"T�C`="��I��a���]�=� ʒ"خ�?��(����j�V�ߡ�V=j�WW{�2���)x�H�i�"�i(�5޶t���c�F�l�Ө�`�㵛+�����Š���Џ�Ê���V��^�GW�f�咚� �Q�`�xj�l������Kz��7�tvW&�;`�{���N����z8������FG��-�?'�_6�nSp�Yߕ�y9���T�Q�Q4���T��J�_�Ne��e�v�<�H�x��Vo�ֈk��~(e�J����b�G��a����"��`,PYcP�Y�O��Q~K�+K[����fJ$b�.�p[��0q�Q�*��8�.=aB[�̴�˽GM�aV�	Gc���`���ݦ���s���meD�-ưDߏ���#a���-�䁓���!��ѡuԮ�i�NJ@�`d=d�P��#?�X`�qu��F'�w�(�XJ >�Ry��X���}�A�#���Qw'n;���6��[��kP�i��(�/f�|��Ͻ4�5�)�_Z��-U<�mSTm�����m]���V�h0�0I�$��X~L���
��縒�Nv�6���} A=��%�z�V٧[|O>9���m����0���;���}��,�Z��{�v�������x���)�n��ԗR&V�ٓ
ýg���s�{�u3�:Y^�y���³t����r"��a�����YK�؃Wq��!��􋇓���tH½�ޢZ��p?'��c�Y��	9�Ԇ�|��r!MZZ��dJ�E:K.JR/����/%a#X��آlأ��ش��Ԋ@q<�m��O���O7�,Z��IX�x��'j�'��i��R�2��5?(UFn��'9�gI��bL5�eZ��ɮ	��o��:)!2�����պ*�U�����	m���,"/<4�迪r����懬D`��s����nN$)��)�Dt�e.w�#jP+}:b�#�.��[-T8l/^�V���"��U���kn��N�v&Wp�"V��P�� n�w�/V��ze�8|!uQ�Y�8j]�w���I�;S�ͅ��Ŗ�s?�B�̄
vc��A	���o��4L�E��`���Т�ڼ2k)�W����艹q7�����N�����#2�ArV:�g�g���r���93`�9�u���g$G���vb�%��sE�A7��/����pݤ������|�;�>�Cw����� Eyu�6������t�R��А����K}Yo��7��#MR��?H�YG�)�(g���9o�ϝ��L��K fNۥ/�j�{RI�j;�x�i3w�'�%�N�n�%���s�ϭA��ӟ���2�o\��`�i���5�|��U.�Ju|�L>\E��y	Æ��H�������E�����
��b�93Y���Ț�(�����;���tmu���_:f'�x�;��Z��J��苮���S���6���4���H*&H+���~�'%�֘�>@�R�ɹMl;9�D��6���pKjovB����9$ Wipn���6��z�.(G��.�i��f�1-|���1jI�i���y)s��7�KA���T�L���!c�
�8b<a�c�*Ϙ��'���e%�?�T���ǁR4�e�:�=g˹��Ǩ�q�mȽ���Hi
��2�@Bp�wgB���gjM&m"l�^�K���y�Q�O�^��D�v2���u����~1��ɭc���tRS�-�ƴ �{N�8'�m�ኖd�[�a$h�>C����n�S�4K�Ha�p��9�X�L�����e�rۈBn������"
��!�� �rX���XZ���1�����EGPa���CrJ�~���w���lc��޽ﳻ$�Q��S�*�j/��!�ʉ��m�I[?�a��� �1�K��l���4��wD'O��r)����dK���鑤��0�Pm�#S�!:��Ho^�m�v{p9ǹ)��FlÌ8|ҫ��ɰ��o���9c�� �K�j����A��\
�'/єzE��>(¦6'G	o�?۵w9+���?jqR�ưQ�ľ�U����Q�_�l���嵓���U�r��2� E1����A�ŝ�J��̼���@�u�
�xF<�=o�F�p��}º�1���WD�Gg���؎�"F��s�ef����s��J�< ���u}=�
��do�&*až�qU���E�OD�ЉZ=Me3O=?���$kf�> ��]�?)�gm�ǐ:�ʴ�S�^�d]$��/�Lߚ	c�1��m� ���MAׂ|�GL��tG��hA'����F�*���zK+���G�Ͼ��_D��`��[[�7�sE���-�G\�)O.1�)},����I�]��>.x��s�FNj�#�֦�����]y�Z��A�\���y@!�=�,Q
��ڼ*�|�'Ưi�Z)�an`�ҫD�
?|�lgV��=���A�r���C����!��&�`�o��*ч���؀�4���7� �
-|��J����`���Yf�s
�0�x�Ҍu�=!��4��{Pu6����3c�_��1Uha�Ch�20�U9�lI4t��d����'�I��s��+?����E�LT�\jL0I���y���o��4� ��~�y�#�pX��pR���k��'�,��r�%�I<�t��K���Q��Z���3� R�op�T��l:ѡ�b�4q5��X}���ϧ��ʗ�#�U��$"0�%z>R����C�5�0Q�j����>{a5[����W[{�lq}@�ɳ��.����9:o�9G�ޭB�i)�'�hڡQ,������-` u�r�-I�Gu�$�ץ�/EݸFo���yURu�᱋O9�c�O�{��%g�=N[, \���Hy,��_$=����}o��D
5M�Bh|
��2w�=�������}I��""Μ���,}TDa���y�~�D`�`/^��a�%`���/I0���_��ׇy�&>D����>��S��J���i>��{7�\)y��t�I�M�B�lݷ�6ӠNRŧ�}{��n{�Y���9������q��������}~���ʍ{�d���"J7�8�6�Q"V2�w�S2���#�C 9�%��I�&9YZiq��z�W��)�/ά1p=s����-̳���H�qV%̢z樘Ӹ�n(�jB��ʩ�.M'�9�������W��Y��i��c!� �'��fZD�h'Q�.�sx9e3���ұ��L�[N������Xs�����1	usC�C^N,v�� �֍*g�%�����5_�lӲ���v�\�n�+��������,��Rt�M�a����4�M�]����W���¥�2�)��v�Go�Ѭ1V�h��"�A�x��L�3X��G��0s�1�h���.<-��@U���N{>��1<8���zE),���췗�Z+0�Ϊ��J����xD�{@)����F��8�S���"��r�ظ��ձ��v �Lk�;PiS`7,vGL@z�!��W�E�}�Z���{�Ȥ���=��u]<T��T zr~e�De�Y8D0\"t:��Tΐ/9��7��U���D�����B§;ɟ�B2~��z'��4g����<T=�G�Ҁ(��@���6;X�76�����n^�ԟ�$+����[�7��
�\hݎ���Ãh�+���������7A�}�9Į6�L�+��$a�iIO�M>�4~��ZN�J��B&-!�%ނ���"�k�[c�c) pIǘ�J��[z�����d�u� ��MC4e�ȱ�R�FHYVl"��m��*E�F՜����F!w�u�4�O^@��L�$C���{��G�m�<ќh�xe�K^���n b�-��`��A����o#���	Bt�6>~�����)��V��#UI�aFS��@Y����ʁ��J�� [_�v!�$tB 䓺���(2�yA{ ��R���k��U+)3���d�`�as��rx��q��Ϩ��f������K����UW�e��2�Cn�&"D\b�����>��lۄ(�M�fM�7j���n�G��)l�߉u����#���g��L�~�"���	!��-9�(�� �
�;�M,��N�G���B������ �RL,e���l��I ���.�6��{QhPGt;}��>���V#��z�$����֢Ͽ�k�>�t�հ��}Y�O�q�W9��N4�\�c�o�=�|.��q�I;���;g6�U33ߐ�oa
�Q��� ๡��� ��`���C64j(��R������J�sʟ��}����<s�qm��B;��C�u��]�k�1�V��W��h~.#���ӓn�I��4SwF�����y����K��
�b.����Uy���0b�?��i�
�@������fO_9�SB����=)�85�@j�G�e�u�a�V,*KӰ���`��^ʐCG��T�"�b�F������b�m
"�T�L��Hp��"��d�j�q�}A/��6R����h���Í�᭖��<�l��9�Uo���>!4;�Onp���Ρ�^����I��u6Z������1��!�V��EU��	��}S�ֽr�e�L5�Y]�*$��+;E�dܾG�R8#�N����"���e�j$P�vU>o�q[��e�$Ȅ���c:���h| ��;�&�ÿ��|��S���6� A�e���X�*���&���R/n�8��b�$�-~<ۯd�
x�����p".���G��0l4Ŗ��JB���A����B�D9�	
&�Y檗�3
:J�S@��ge��B�$l�zZ8�9�/:D{|��`my
�V�h_ղ31�������S֖� ^�\���ǟ����4�ǉ��&� j��<�a�	�aL��aJ�gaٍ�����&��+ײ�ў�����o5C�̧CT�����&���d_Q�w5j�j
E}����P^.Z̗|���r��8�X7���A8&/��u���=L�K��ѱ	�i-Z��]\�a��%��$�:{�i�\	3rD�'Y�����w��@$F�u��ݦ���(.��W.z��W����6�r�``WȽ�(�'����M��q����Zkl��?�Dି�nS���VPl�'�Ŏ�?��P�\/���'���9DC\t����(��5������%�a�dP��t:yfYx��Z_��Ek�֍Cw�aaU�(���0� ������9���#�3�%���jt?f���1�ӡ����:� gY�;�E�����9D]h@I�uaSK��E*�$<�ձ9x�>y��fԡ�+�Y'��'ZVq��u�Z8��ac�8�F3��+ߜrZ<���"*�-~PB���j]Y>#��S�[��`��	�)3䔱�O�'�G���~V�P?,aFo�h�N&����+E��P]�&t-�:9�+�+�~p*��?oh ������Wx�ĸ�R$SX5*��P����e�д}�6[w�w�]O
Q�Zl� �g�y5�!���.n��E��pK��y�~W�+�@��V8b���'�ፏ�s�7x/�U:S�Ec��]�"��9�_�h;����X���@���U4)�	K�di1�8y��AE�����z���K$�	$�ZeJ}%�n�!~�L��rĐG������6&GY�]�?ã0cO��>�"͹�Q���@��f�ۓҍ��V��(&���F�j0F��y�)Q:�"E����ö0Ro�������|���ArgS>������й���_8v;n�ɼ�9�Fg�dc�0`wP��Q6�j�p�ZA��{�_�N�c}"��y�m�Bu�B��V����~���텖�Bp���iH'_�	
���Ԑ�"q���{�,�k���>af�O�*�����P�J��C�����a�e����O�V�K]�W��Z.���dk�r�����|�1RD�R�&+��]������o�3>�	�3��ӗ+�FΈ��q�K�0�֠"�gV �f���,~�����al �nTƲ����q�Nϥ�.h�A�����-i���3�X�E�Wy�<� R_3���y���-*����Y-^v*��7�Y��=��f�濪5$�۶��ay7���ح�⇙�%jt�50+wE�s�<���F����ٿ��⽙��I���LK/�/��hICT�4���to���V���?�f����CI��Al�Y0ԯ� Nb�;��no2�O�]��M���D����_��>nHٿ*BtZ�a#T�h����HS��#ᵉ����_i:��R	�
�16T�0�&���1>v�#;y��ý@�\u�v� ��υ�T�_�C�~�O�kEi�N��L���@(%�0kޗ���!7�Ëb�S6�(~B��՟�j&���D!Xf���N�3�Eܿ`��-���pϻK��:���(����]X(w��i�q����%�<�Cs���f�=% VP�Cs���JϤ�6_J�I�2gkX�K/��?��t_���y���� ��P���[4�9mL�-���<�U���λ#_��Ru毌�q*"��>,����x `߭�:�P�S%N���[a���Ŀ���%i�Evr1ؙ~j��N��&�c�&,;c�дL	N�d�ID������d*3�*z�'�s����(����;_����t�|^�[T���h�Z��HZ�u�'�� �
w<*���TP�d�������=��܍`}�/P�urQ$T�3,�JL{��:E:��¡H��w=Ǵ�\ܹ�ޟ!_{��ڼC�ߑ��
܅D��)���M�)ŗϿ�L�IJi���
�qE��fW|W��Ԛ���J��fon�+z�o逑 _UfY�.����o��\�$+2��P��B�(ҙ=s��U�iM�[��};��-�p��c>A6����J������G�������+�*v��g
�2oФ�J4�emm�'�V�)VHBq݇h�d�.�n__���Uj�S���O2�K���f$x��` �L�Po��b�l%��x�$OG��16tR��ǌ�
��ޑx�v[�N/�M]ЀZ�Na��E���3�D�f^ɮ���T�8��h�Xŵz�#`���jVY��h�i��ݧ2*�)FIe�	����r�B�*�Q�����E����p���DR�0y������Y���t�J/̠j�j�T��5��g��(>ĕ�R!������WX���7"�aرrs�_I_��&2 ���5)&��
�y�eL�g��a��MCډ|G9;B�ķM(ZEG2�?�-��1ֈw�5]��q�T~�����)�Gݓ�-��@$��C�;RQ4�fy�[���,��ȁy؛S��kV��Ad5]�mt��������N��Vf��d��?�/>P�)Y"C݁�jy��rN	�7C#r���n���R0EJ��k�ڱ�N��.����إ��%`<94dL{�M����o� ��zg�ځF�����:��{��D��;�+q��c�D���xY�O&��-�j
,K����#��]�l�Vf`)��H��&N{x]���Q�O�K��nF/��5+#/c	��)�ngiӏ������>=f6  |�k�Z0� �����.�U��g�    YZ