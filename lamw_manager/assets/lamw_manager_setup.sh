#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2650569714"
MD5="8bc24ac315f3854fbc632de17fef2991"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24352"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Wed May 25 22:04:30 -03 2022
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 140; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
�7zXZ  �ִF !   �X����^�] �}��1Dd]����P�t�D����oB��^�}�F��� 6�ajhGu*�{�3ԕS�#�J���܇Ӷ�׃�C����]}@cdt:�J'sJ"�2�����Za�ñ7������S ���.w����+�,σ;���;c3�Y���=��y+����?��Uط�q��	f�{~���w!,�m�� N�0����ɧ��O���o,D'�<��0�)��|�r�*27�0#Z),�X?��->�.72r4'4��������u{�!OE����L�jWM�<R�/	e�#MG,.�]�7!t�UgҠ��'n�V'�$��Ce�|�������0�C2���ӈF�ğ@º��,��v�*N�H>�TLgVe�E0�"���Lj�sׅ5z�n_9D��Z�C�/�g��G������Q;�J��t6����)�s�]}����5[oO��*�H��h5�c�p�Ȃtl�����y����)��P� ��,�'{Z��y�D������:��b�ɫ/�/y�A�ʑ���w<ѬAv���(A�����8�촞�w^���⸀(�����D(ċ9�#�Z򾥢�~�s��p����C��W����PBT)Q[�Ä�+ ؘA�z}Ж?���ρa�[�$C���;X�6o���Y�c�&���L��M/�_��)�"�o}^1�
;���p=�E���?��#Z�b���$�wbꮸ˥��V�F$�A�/���$�8x�[��l��=�`��H*���8h?���/��7/}@♝$څ����U��z��2x��Ӱqw6��_��\ʇ�zeئ�^m���8Y��u�Ui�2�[G�Q��������&����n��SR�DAƢ�w S��vڜƻ��d{4Gt���&@�]b~��E�-����~��3��*���ӼE\�g��/��<C	0ʔy�?��TA
�~�U�T_��h>���F��6�"
d�u����[��:F��jXh�z��N�Iqoe�^���b��H(��߼������O!�	����^7P��<Td�sհ�m���=���%wy�ү�U콙�X��������4����9��EGL��� j��x>w��y�J��t�Q_,�$�U��A�S�)�4v�2���|e��BjT�E���Վ-�΃/C*Eug���/���#�3h
�~MXy6���:��No��8�lv��沠���LU
�����ն�L��&���� 8 ���o
�A&�s�\AG�T)���F
n���3���N�4{��u����%p��Az?���WZ�Q4I	N(��v���jW����i���P&Ľ�$b��PI`��G�
��K�"�hf����o�ד>��� Ęٙ�~$0�ݗ�lҮ��l��?vL�֗v��s3����w����֬9���;_�{֧
ĥ���8��G�qn��x�n� ?�gi�q1�ٮC��������,hF�7�\z�^�����q��gE�&S��E�kOX��LY�o�4�"���s�W�1I� X����d�	n{nW`<���R����ǥn�66HX�{�q+�%JN(��e��Z�|�����Ɠ�-@T�vh��m,��۟up��/2�>�A�!���M��/�}N�h�8V�	�B��s����� ���LAq5.VE�����������M��d�>��Z�g��|���?�����.&�XP@�U�׹{�7ٿ�	��/z iW������A�_A���O��t��{Zj�Uw��x��~Be��eE>��eno=����m��!
�*�5Pܗ����tA�?V�:>�M&-skd��##�*ꊶ��-��j7�e:�TI4I*@�Tᨋ���(x�G�1&=�^
�	_(���[�Y
G�SI�����)Z�>u�0ޜ�� Ɓ`�̓���L[� I�VOF_J�Bת�{'ԟ&�j?����Ɨ �������Lhf�*�7�-��o�J��X� n��WC�mFvf�����II������ȗ��n�����T���5���sڵj���(�7'N+yWM��������nS�E��P1~�k���QJ3����/�D�yk��YE�B�&_�z&�0�O�>�t��7��B�r���ǅy��:��`�%��
>�`>�~���,ǭh����#�e,
C�m��o��|����@[��a��.҇ϔh�i/P���β�zX�Z�����ND>*Fb��+=����c�I�l> ��|��Ǥ�c�L8Y�FaL�H��!c��ĥ��s�<&�t�)Eylt��2�Dai�eJ*б{���:0��ؗ�TEt\��(�q��w�*�~�XP~��V�=��r��8giR�nAVe�S��a,�k���m��@v��5n�o�HV�A��}�R-�5q�1v�����ef��-a$Ʃ�������r}~�5w�d�.m�ֲ�1��������2�E(2H\7��]�M6���������nu� usЯ��~Ķք�3	L������u����jp��K��uN:��b����M,O �~��H�00��m�y���?e����Ӈ�+��aadƥǸ�LId�R�B��[߬��'r�z�H����Ҹ�E]R�-B��J��y��L��t�c/際��*�C��d08��}��!)wE:)0��Єğ����ό���XFѩ Kb�j�
$�:�����8;ǈ��q��H�f:(�Y���Ad.\T�ruC��ye:�J��'�[���8G�x䮸�w�?��7����k[�����_v������7�_�~�eQ��b�єd+����lcź��U齒@ތΧ���0�0By,CA�N&y��TNdNHJS�$/�/",IR"��,���0l+���6���+?1h (`�˃�V��#����]M|�C�	۷Pn�$��lPq1�0aIE��|�4ɿ��hB�n+?��+Q\�?�uS�mP��T�y��8KF���=���=�;5�0�PoV *�>տ�v��;YX�6�k������|F�|��:�x@P��p�(�@q���"&��CF�@��Tjҹ)�F:YK���fz�l�s��5���~=�|�Ч7��>;��)4~�b���<�l�Ms�.�i�8��e�� ���8��_N����ZK����p���Mr�DF��Z�(I���V�{�f%��>�24_���q�8�Z�0�bA:�EQ��B11�"Nx�8�ك�;��d��+��Ы�a�S��n��j�-,�Bߗ.v~���)���͇l�o�¢�ʲ���n)�}�o].�dN�Q�����+b��|�. j�V-�6@�8�K������"֦w,�I����v����n(��7�ѓܝf>ư��@���q*���8��k�]�LF�օ��)�@j�_��-�=`J鿁�=�B�,���K�R�����m�}\A��ԍ��%b���xZC 7�6�P����벸�WT����S]'Uږ7Ay·�`_��Q�YE4�U�nO����l)",/~I0�5i�44��+^�<	�eM�F�`=h�0Zz����nv�[i1��fu�.�~bo�����6v�w�P��E���c�F2�uUqE�]����䨚Ѥ>�ؖ/p �Tx���g��Shmf��L�$�$��&+C����6U����c
�}�#­��xe'Wɣ��֗T֞	�c����<n����f����^�FO"�o�Uu-�m<�n�0����&��D���ӻ�nr�l�S7�R��/�w���$GE��[�<wW��4�NkV��s�:�6�r���o
I�m�$(����IS�ȹ/Ee�x�c�`
�sa���F]q3����U��/=WY��<M���r�&�ɺ ���P��~��ܳu:"Q��F㘡������-[������ܰUh��	�	t�����lM\�N�2B���4xۤ�T��PM��CVĤ��v�����6��� ��F�A:���%�{�}����A����l"�� �~)Y��I�{�����Cs�h������e.5�}�I�	�4���(���Ga��Z��M�w���Υ�� .sqyl��qSO�㙪��"h�p}S����7�֍�B'�M�/���4�I���[���60��tu�����
��
-�l�"�����z�zd9�,�C�6q#	آ;&�-T�ՄӮs�w]L�;�nU��X�ʰa�Y]%��e�RAOTwc���,�؎�<�ާ�j�i��;����?aX���Զ;G�A�BsR0��U$�y4O~j��/�ė�6g%�;�A�w��1�YtV*y.�yp<WI+�W�V_y�U)ڜ�_lafk��(��'�������׾K��9!6�Fg���U�����!=<~���t�u�;~��#���k�p���t����X.y>k�*�!ut.�����z����w�U��@:�Q#B�y�C�Ny���Q����v� x��qy�{~��?[9!L�g�l�U�-}޵���Jt+�Y����B&����-��|?I�S�t�i��`�"�~`�v�-��}0���|>�@��k��>f�}��x�-�rg]S�w�,��xo�ȹY�;)��5��u����˼@x���䣔�y>�.R��U "���������A��dT�c��F�h亀�I���E�㦐6�����;��O<�M蔕ߎT�h|��eqL7�f6����Ěu�/{�뻥�jB#J�p"�~�ѐ�O��uJ�'l�݌Y��^o�2�7I�8P�+���ƌ�Cw�@0	4��nF2͐������>��(����F��\�Q��d�`8�s��x�U3�T�q�à[K4�1�=�4W�ْ����
≈�aK ��%K�l%$�;i�Ohٛ�^��~u2.
�3���=�xQp�.��oLMR �v��(yվ��A�?�
h�Z_�Դ9�#LEz=rHQ1]Ԏ�mz���6������**��e�bp�H��IM1����O7�v~>�lC�f:��p��tQ���KM"�hd4�D��j뤂��B4��
��2�C?�_]j�����i"§�R��}�/�=mJ�\C����Y$�ak9g���ڴ�;����Y>i�H3 ۻ?3-/�:A��>�$	������q�gbs�}�!�-{g��U�ި�3�VQ�F>���֑R�$%A�-U7朗J��wr�����TVx�Kp�'��v��LN~�zG�������j=���4\o�t���KV��x�U1le1�:�T�q�I��U���_Y e��v܏\k���tv���Svj��Ҟ����A��Ӣ9���H���i�)�J��{���b\ت��f����:�
�?���9�R��f�̝F����ʢE}��As�uQH�Φ�|٪�h����r���|�<ٸ��^v�s:�ĦAX�޺@>����J�s�9���DE:g:�6ڪ�L��s�[�*F��.��'�9k��ʕ�W��^������S�[���`���l%b�?�O�R��O���{���CL�����i@]�H��ؗx;�>��f�9 �cy������>2�ÿ;����B]�!��5V���L�U�\Wʠ�#��W&X�U����rh�^�~�)���I��l�xs:��y�,k4��!W������KW�Ѣ{�={��#o65�=��q?|�-�=��[�SBZ����~UT�4�'+�j���h�����_zW��aߓ3L�E�xT���E� ���,G�Au�R�q���N>��Ȣ�||
@dR�	��.Ni"�ޛ�Mr�`(���塢�Ϥ��E����5�������C�B� ;
��F���nˇ�����c��5��q
�-��Xr�$�?��S�S��F�v&�&�#d�ݺ��f؇��U3/II�Zp�������yW�n2m����ѱa�Ii�����v�:��H�!%@��p27`�l74�1r"7�,���x���w����jK`C� e:`���sj���8ٽ�V+���(�h��5�CgT���#��jEK�Ī_Gf��@�	]6e�cbc��[C�1��6ո����\QF���o�H���G�jTî�l���M�7熕O
�o	1f�d���������S�n�~v��+[�����T���t[l��]����u4G�l˖���ɹď�U�f}�7�D�Ji��8}�W��K��R AƲ��6��͞T��M���x[���cE�~����[��k&��\G	��.���T��?���'�`�U?3(�S��'q�Z���ҭ�۲ׇo�^���C_6��2[��6�"D.�~����i[\(9{)�oM����L� �ȴ�b��
#�L}�4� �x����X$�t�|�!�U���"'�r����N��t倐o?��ڱY�"[j�K�/��@�lO)n�QU}%
�������Em_%��@�w�|���d��hrؑ��v:$5��W>��c�[��S�V��r�v�rr4&v)7Wp��Ǝo����@�J�-��8yc��2�P����;��(c~�R;��xïЭ`:�Q�5�s.�^z��G�#�Q�l�_�sD;��:�B9�I�+���z(��+��s�s��Ŵ>�ůT;��J�jX����~fq��r�޸�nY�_�z�>�E�*~����e9l�&��j���p&� XtI�ro�;����I�8�S��-� 	Q͏*V2߬)��j\����}����yɆ�ہ�����T���-�s �4D�i?F�#���q
vF���:���Q���6�I��d�|���L[�I��#)�Ȍv/�z�EU1#+f�>��׬��Ab�D�nc��fa�z�Ms9o׸�D`����.���i�9z�՝Ͱ�v�DǠL�<!���T/ˊɅx�Ӣ����J��[��|/���$��±�(�8B#� r>Z�+�<�%�!y2� �|�HP}�ݰ��F������R;oH�~ocD���/?���fB-7E�o��p�r��$��E{BM^��ˊ����"�_C ]	����W(hP�<Pŝ��c����k���Ԟy�3���v��A�<B]h�Ǣ�DoFI/!9A�j~3���j����|�i�E�NAfJ��y�m����X`�n�M[�e�ma˵�<����� ��!3��P�'8Y�z;���d�fn���������L�~k�'@�DbX/{�����f�>C�t��.�x�����!1�[�Uv&~�uZ�V��sqO�H�����G�z��?���,��ؕ�������������.�B��'N�1�@�;֦oy�c ���'�e_��Y�x���<77c70��Q��S�A���`B{�$����W��bzy��B}!	,�G)@�2�$�R�h�������ê��ā�P%=��c��dI�3�m��.����a"�c��iIB��5�[˜O�z>��9�6P<7ˇR�.�,�"����Bz�?'1�<X�a�����hxi�+2�-~��6�ݷ�Y�V�I� ?ac?ZX�m��"����7���K��I��vx^耣��x37�d�4�Yo��(%<�r�dBO�=c�:`�ꁷ8�U�	�YDS~�ȍ']��y�FX��K��-�����2�,�?��X���?�c7���^x߀���[g	��簵���=�K�P�z6�BRGj���N�<$	,Ё)7�7��&���!�|B[�?���G&(�:���3�a(���-e�Y�\\��R5A�懽-��B/d�aUFCbۜtt\�I���(Z��t�c߳�d5������DFC}���s�!��6�"=�#�iq�T�T�^[6����)����{w���z	����#g�l�;t�~<�3���ˑ�l<F�Ed�����NQW =�	�S��:�Mn8���2�������hXu��Z����x�G�� ��\��JW�����W��-)Z[S��g]-*�L7h�U@Ҝ�MI��"	�ca�@��A!Q����Bl�x�/��U��ٳW�!�BsS�S�Y�>��J��7�놣)L	Kf~��c^މ���֋L�FP��<g�UL�z�U^���b#\��8�z�!�+�SL��ʒ_�q��?r�O�hZ9�;6Zp��~��ZNiĤ燞Ik���u����E�'�D�&nj�!����Vņ��=��3�0vƘ���!!ǉ��^��W��`�Ai.�~+~���^��(/D1ѓ~�/�^��	�sIR��a�$8x9�ڄ�(�� 3K��cHx|��bg��S�ﰐ������Aڸ����aЕ� @0d�irt˻�٨=H)B�D����hp�:�h.�kjS�<��
�o��]^��j�/پ$�ޣ��� ���voS�b)N̞���M ��s�\����4n��b��/���J[��T��yx@���qд�J~y��:5�	?L�G��{��r
qD����m������]{���ei2K� ��*�vV!K��BQQ�?��:P.�3��������n��p��4�
O8]1O������ 7���OW��i��U�"��
bHp�.&�]����u�Py��8Gb�=G��50��at���"=�C�r@:ga[y[%^���_v)0�s2�.�
f�7�J�ӭ�.m�΀>���:C[xu��
�=WE����[�!�E�1�7sK�A�?G�'��N^��)aB���z�_��謌�A#%x`~�?�ʟ��6ݢ�$h�֏U���*��}i��]J_��G��k��9�s���6��H�dL��ۼ��ڟ�B��a����֮�la1(~�1QG�]�hxfw��_��]��'rE����7^�Ҽ#(f��%&%��Ֆ�����<�q`Ƥ��A�A�J�V6HJ���s�3��Q���v�w���9U�5Y�/zu�f)-wƓ��e���P5!ٙ��e��?V��6��@��c��K�q�����P�M��ㆲh����0"~�ulHdF���0��
-�ُ@�7��I:`!��2Բ3��YiȵX(�5��qd�89n���0}��"�4��T���@�5�EA�%�AaE{T�2ط�3Br����G��v�L��FI��q٥���mv�dh������G�l��E��)��m�,�`�-�A��?�w2���5~�{��)c�-��B���6��H�&р�.NgU�\[Z,2`-R捉k���Y{�w�MB����m������z�_c5�Jtg��,��bU��O_�I�TWu�@S��YA���sT���z����6��a��ƭO^� >�G �̍b���� �GS;)܏�>0�e)`y���=�7~7����^9��Nƈ8�l�]t$*J��z�ADTݏ�	���j��f�fc�7R-Z�Ev{���Zc超�L$��s�-,�l�r�yY'��|X[ٝ!�C�.δ�Y�H_Vo㪒�J�b 2WC��ݣ����0_���m�g?��8&�,	�g���� ?G��BQ�E��%�?ϣj%�?�g�G0�}�S�D������]u}�<�zpq������u��˓=].��	���\�-�9���i�YA�НQ|�&M���&���NbjE�M����n<x��(B�O�W�3+�uM�dC5�£?3���`'�5��M�sY��R�u� �'��6�8�ߚ��5yO�J}���m*�a/��J�WZ�ͧ�\�I�~8����7\�l��XH)�pv�]4� �T7�EkgV�c�ANkPj3L:E*)}��ǒ]��?��KM)ɫ{��suA��t>��ɷ^q6R|��nWf�Ohx�,We��0�~�JF&�%��U��zd+0yXf�J��&�.%Z_��v�=�}��v�\��t�MΖ����J��y���E{�nf�YB�b#c}�[��d��w�<%M�E�Hv�Lk_�<���>�M�dy{)�Җ&���ł#�5�BR{���6'%����	����.f�Vhq��UaS\#�dψ�r�9����m6�j.�1qK�d�
������^#�Ib�!����Ɨ����Cf現�kx)� ;d�p�x�9�*`jߐ��)Z�.�$\��?���_�A���@1r�Ls_�L�w��*a���Q��w�"�G�vt.D�O-�`�^}���JS��n�$g
�b��,)z-_���S�j�T�x��k��0Q<�G{v-q��T/����Q ����H=�Y��r�i,hQ�\�O?v|J��Kk\��=7鰱�N�{YG0ߍ�p��;@���-����ǅ�v�ʞioj��-�8��Yep���F��\l�!��;ތ��6|�]�F����))w������������?m^H5P��D��希`��V%Z�ڴ ���9�����Mn�9�<GK"�h�b����l�Xi ���a�ꁉ�1j���C��̿�		����pwu�3!NV����럛cXҗ?�N�T37�!�����n���%,�ʪLغ�8̯���8龃�)N��Ť� �/${��w/^����4UY��Xp.����zE=�$Ϧ��cU��f!�m���t/b8V��.�6��w�BDx�2VIx�c�2�'��?Q��kL�BHç�[�pk�W���W7�z�[cJxQ�:(1��d����R�x"���1*q��Xyq�Ν`Q�3:R�`�㷘���#􅎐*���A��2�KRX$D�_ ��W��#'�Gj
$(���\�tQ�=�蠅�������-/�_-{�g4�@)ϩC����y T�Ɔ��)��8������?9�;Uq����o�gah�E�n�ss�~�E����y��?�B�uJw�`���z�|Y��<I�|�M�9�?�0ȣH3�db|�j��}�{��UI��������N�K�MUĄe0J�.W�;��0Dp!�h��Z�� t��e�c�
�[j�:��le57�Jr�X&o���M�W���=�j9��Vh;��3�U'�Po-3���G.���R¹W��WPez'޶~���/��߷�=Zf���|�E��z��*v�Kv,[��t?��5�$�F>�9�r��G��0>�z I���cWi|�����Vv\S��e�����o�>��P�mGP�>M3��y�
�%ʱ��8���K.��>"tF��@4�/n�kFz��񌘩^����[4%��T�����K.���Ȱ Di��yDm�ڏ�7��z��CɷsI�'�5h!u^���Cs
�J�g<x���l���M�2ˀ/^j�X�C��~>�I��?�"���>����Td�	-_�����#7-�F�zU��(W>7��8h��Ӈ}�'�3'�>W�La�ׄ/ 7�u|\�'w��a���a(0�,����f~ĥ��#�x��O*�l� {��*�X?��J�K��H���6U��+����6_v�۸�(��ѐ��[=�3���g�&n����<\I�!b��V�J��|�E1�(7�i@����H�7�&eI�3B���6�f�n�3i	�j���Ac�НRO�N۝Y^tia��U� �D�C���$U��_[�#|0�VđǇv��]���~�kC���B�h�۷/},��I�F.^/\e��c��_�,V&U3��F)K7�ZBkS���*�=g�����`aL���f�4)�m���~�b!GH�h ���Gmuy�q ������#��m�h�����#���6�l@�3�g��s!M�܄�";I%�I��v&��_���zLU���	��$�����6W���N&l�Hjj-<�{���z�ԡm���
S�n㢋�#\��A1ĭ��=���>T* B���a�^���zTv@o�%��b�q���:|��p�[����������:�wU��?��-���^*\hӊw � �z�mk-���$�yl��Z����N5��`wAMS�0E�P�[	@�D����!	e'��6p@���C��A罁	�#���@Kf�;���O ��H`����p�;P����2!e��՚����t�:�e�����^N�{ju��=�(8�2�+'��T0\t����z�Κ.�Q������I_
;����U��\,���0CL� ��1Sr"6P�w2���\�}y�~�Vz�:�?�
��g��?��UVc	��xBRn �4I�������l1RҰ)�P�f�}�tIkPC#�6���uB��%s��� ixd.�0���16���E��������}�[SWtǮ���ܓ��YY� �rJnt��}K�@<� �{{�0|	�hWT�s�VM�鱁�A܄�v1M��jS����ݣ�f}�xh��׫�g�}���'�~R3:��MS1�Y"���^t7��J��5�b���us���Ud�����F����2g�:d k�	#됼y?��^�lvYb<�8��V�>=%��P����lA�d�[������im��х��^���S�����Vhg �I�ٰ${�K9F�(���"�,�q}Hg~F����|[]�wP��[?�Xq�
4貄ѱ��g�}��)C�W�t�&�qyDD2Rt��u�}n�!MAb������?U(gZz+N��@[ĕ�t,EO<LT���%�_"֓�6uqΩFcn 1=_ܲ#�w��}%g-O�\% �����n�21-�Z���
$�81ZhbY4�0��J�!8�,�c�~��j-ƹ�9�¶1�K�G/�#���a�`&;N�A�	��%m��ҡ��I���Ģ��&��LYqq��*���B�bn��yl�'qo�$_�~�u똱��L�8}�$���!F`�`��$~��I���k��s~p����4iNG��#���g�h����~	VA���8�ᯔ�u�-q8���T�&��%����+:�`�|ai$�j}��ȋ���L��Zr���Jnx+�ep�i�g��c�SDX�AN�+���{<�si^�L@S����;B��R*E05��Z�C��u����m;�q"���5�>�Z�I[�Z�TWW��PT���O3}b;�	���uD9�Y;~4�Fp���)�gouo�ċ)�u�ٱ����'X�#s�70�ɸ�M���@zVچ�jw&S�����%j���V]w�X�u��&����/lk?Q��m�r��� ��s} 30@�i��Ez��A�%�	����׼�]��Gl�j V8�8����k.���,|�j>$���������cg\s4�!q?,�Mxq|����^��� �|��S�-����91j�*�O6����4l\����Ʊ��jw,H�P�}1��X�z�a�j�`)X0����;����U�["��X�� ��h�����qk1���'m��I0����D�~ȓKak����8a��T�����Ay�@�րK[P��L������o�`���׆�N���aJ&��c̽�"D\%*;�p�fd/��Њ�ͅ�|S��
ϰ���F�F�i���T'V�-t���O��� �V�p�P"~yg�0E�=9��'6�S��>�R��aKǡuK�ze��o؎<DZ7�[1Jj_i�aS���x��L��0s�?�$��-�����&h�>	a�L���ʭŊ���|:�&��_|Յ�Kо)����Q!����:���ƭ�z�٢y��V��� ɧŬ��W�:�x�|2�(��ηi��
�[��G^@׋l��"H�
Yc �q�Hρ�(�hՓ�An�O\����C4�g��aeF�X��h�� �� ^W�di�(4&O�����|�iv#��z�9u+�� 3�����>�N��×*'�m2+����$��ÕY��������"�Oն�J��F�%XT@
�P#O��v�:N�=����ɍ�P�)Fz/˷����k�֚wJ��98vt0��#g����"z���p�%QZ�8D4Ms}~Nf�X��rOPk���I�W��8����խ��V�$`�K��Lќ��N�BI:7���nH��BS͐�7���a�"�QZ��a���H�4gބ�\��`���0��̘�:
��o&��O�Rb��i$U��H��ݱ���"AW��Řy-��i [m�5ԥ��]�>������f2��Q:�ﾥ���2��}�$�7���Q�#��+��i�ȸSy^�S���&cY�͓A��]MD��5�q3ߩnbg��6n-SU�%��� =����z���02c��;m��bʑ5��{Jk���y��1$4+��K�ٔz��x��� �n�/�d��׳?�~�8$\1ENw��"3A�����ʢU�-0�A�2�Z���p�t@��ov�l6���b��3�]ɺ����	@c��u#S�S*����'3����]tiU�Vp"o6v����j~��%$BF���S�^��bgׂ�n���|i��K@�Hx���iF��a��p�쓉�TQ�qt��.)�H29��g���vo��md��t��b���ɕ;X��Am]����X-c<^rm�m���0Z[��<�.0H�ɍy���2q���0 <���۷�- �/���:��ŷON+:YU|jz[�wt	�M�rw�$�;~��4v�+7�tW�Uϫ�.?���퉌�Y���*e=K37�:�Y����r ��:�+�@�}r�$�!��"{�đ3̕��4 \����ծ8X����m���)�5=�!��0��wh�b��JAE�c�c��ޘ�G��Q�2~�(]i�5b�Т��GS���w2��{����@��.7��+׹c��9:���F��'���ڂ3�*���V1n(,lMv�����$Q!��<{�xvk4�n�����܍l&v!��ڝf�6��Kg�*�?�����d�U��fy��m������it�m\+<&���:b�&T5%˃�(��������C�r��U�W�1ހ�R��p��'�#FZ|zI��!$��:S�e�M��#J�Zإ��֐CCŲ�bp���j�P[�JX��ð�V����
е?C��E��u��'��kW�B]&�a���i�	6
��1,�Q"�e��+&�!�`Es��X ��v� ���Sq*��:�צGv:jXD<�����6De���^��ٷě�Z-��;FG4�)�l6fg?�(����ߖζ��|�B!*)O����k�qi�L�m�eW"�ӎ���� ���-��wb]w=�2�`�]'�PV��D��7w-��.*��9�r�OP����}��f��jו�w��<�]�~I2�!֭�s�/��U�D_3U��w�3����+���_z�`�S�Q6mtx+<4�ǒ��2�P���,7F}�ϗ��-W�����K��~c�R��OȓZYS}h$�1�B+M1.g�ٱ��&������U�X<�GV޳ɘk7�Ku	�ޚ��Qmf&���.�G��y=F4<�q��a�V	���X�(p�F�e�땳��9I���q������;���C����ZY$��wUܣ��턿�=d ��#{�u)XQt��3>�`���L�`�*F�%BA��jT�� _��x=��P���?Sv��D��7�:�6@$��}JV�ۧ�KL-&r�-�J)�H�	*s��k��X���!�d*��{��ɼn�֭�px#�e��l ��4��w�lq�K����\H^] ���K`���#	<}�JC ��g���ŷ�etO�K���F�NJ��X^��}]!����/nG��:���au��k����Lq��Zp�'28����A�2�t}�c�l�D�{�ׅ�֦rs�.E�>6��H#���.C��Fb�+��̨i����d�-�0B���t��֟��o�ϼ�[�@�_�@V�L@$o�k��#��J�L���"��J;�S��O)����`r��P���+�q�`������WT8�K|t�`���Zd�9��_�EV�@�		����MP9]$0�tc���
x�uG�5R����u�)�F1v�8ŉ�'JX�at�yM���j�@tX�oT�Jc��y.���$�m���=O�k��Ċ)�Y����5���?$sQ����}T#�8���+"D�
��S���w�r(�ܘS�C�^Ӽ��驂*K
[��a�F?���%8C�$Ef%Әvx;�-tK�_5�pвT��*:���{���<θ4ɛ�*]?�12e4~�����`B[e�v�"���4�k�>c�4�����8�uY�g�3BE��9�f�
2�����rv��x�����+<�-�V^�m�c�p�bVO,׎�T�E�&�i�����������NEO��<� �p��!�擀 �]�hn:����bI�]>|O�g���dn��C��h�Ř���<�$@U��TvR�إN:2بc	��[�%�4��1�A�µ��|���4?Y6(r��t��*��ˡ?���z�i�7Fg��5���C���ȃr�l�?p��RFo׃�2�!����e����V���9Ezp�0[D�nY����`6�7��:p�|��DSH��A�c?8�`9����k��2������n�ȁ[D�b�%��������H�A�Pp�Nbi��=,H� ��/�,;����4���8K���@ď�.ډ^���5#{�@5)�B���')��ڽ@�cz��f��m{�w>d�\�1�Ţ���e�殻�LMkh���z�yX!�M��B��=�;L�ϖ��������������Z����^4����O0fws�X��;ٵ�(��r4	��I�n���[��t���a��Aoz��B��ܢ�vo �l����?R[a��z�W1�ucd�8t���I:
�~�gǈW�i�p�� ~7�8.Q)��uQ2�
��ɟYVr���H�Ђ�w�,�B�r��F*Hy�����x��Q9�֝�jut� A�ȺԚ;i��`�FC�*(�5�o̚ =��9րp[MD����v(M%\��|�U����qGD����U�N���b�&��Am"?C��^B�(�"��Ʀ�oiM�B�h��5</��ް�L_�y���Mq��n��N�L �� '��w��W�"�5�=�X�O�kS�j������dǉx-�ٵ�w�Ŋ-W��V���X����2MP���<�Ƭ&�TI���pg���hr��=��l,���
~>��=��o|���ʛ�OPI@I��z�`) �@��f�ԁ]���]�u	�~p���l�8�sεB�Ы����?x��)�ԗ��&
~Z��O��z�.~��Dݏ+��z���R
����w�-�U'a-$5�� T�ǔ���R�,4�o�2��9$�a�0���K9�k6�h!P�?e�\Q���}lVf�S�D7�u������ �L�.��^�q>Ȟ�!�%hg�H�� ��8�0ag���"�T�*&\��D �ȉ�&��,qCu�Zw�n��%*��P��"W���<�oϖ��Q6L�5ោ�3.�c�L�_��3��v"�8���O}f�E@�겄;����q��,�44���q����	�mh�x�}����#�.u:�g�_��f��ߺ0!T|h�E;c��Ĭ��#�3=}��1="*�5ƍ�0ত�J�J��:N�Ᏸ��
Z�����Sl�Z5�VD����/�v�]�5��g���Ҟ�*�t����u�>[�"��B�h�H�����s�,�ݥB+n��Bk������|\������DWq���ש�x݈�ZU�:l	�|d���#�UD2�z}?��Svn5�O��~����2�}�kwhե|S]��u��o ���1��)���שdn�u;l����O����[�tf���r$�R�f�R�x9N��p�&M(�nxT.�"s�����ۡD��=hJ�1|BN����2i�^�="�L�\�'�A��kg��4o|��Ϊ�+%:�f�:��i�9�r�[R�H�a���HJa��<����F�-�U��YяO����Pdp�ָS���ι����݃������ǹ:�/��2�JN�CmW�F�z�7�f����]���0:�Y����E�`��'4�[~jȋ���e�op"<���k7
0 ���6vn���3�C����[�3b[q��V2��2�>��(�;�q"��R`�O�^�0G��С~�ʰ��#`Ud�m�V��₸�I"naHG�ZH6j%�U3��AĄ�"{�<�ךZ�o�N�$A�/�0��_�uݼ�
,�>)����@�h�MAS�dCUUjO���hϘ���NYdjt� �b���yO(1�l'W��{��B�}�L Y{�Ya@2�d� �g��>P��/�b��1�y�e�n��6$]�GNG@��ι��A���� Գ-� ��C��:�Cȇe�	�]š�Jp�5k]�������`�0��z1��g�焮ޤ!"c�V/�YaE9�(7u��S��C썯!��T ��置/6�Vg�x@��[�6��Vv�G���w��sC�υ��Ƃ�*TV�}"x9���T��X8�U(�c�o�7/p{?�E�h�^G6�(�A̖������{��h��*L����.��ؠ����"�T5[5���t�l��>� �P�:v�%,n��x)_�n���*,���]���3u����wD�l!�|���*%������H�4�;�x��A��T$��,_oU�9+�:a�>�m��	�������0����R|�p|h��sZ3�r�=N�P��]��+���ªv@���*����$,C�pz�q��S�.�P�l���
-�����})�\�h��2I ^�'ʲռw��l�E�BM>�|���&ڨ�|!f���8�uQ�M%Y�S������4� k}*���y������Z���E9����TO��P�^,j���)�<P���U���[�th}ڀ�^4�����2�K?�����C���B9��l�"�E�J�A*��y������2��(�\pE.��ʚxoXǋ�f�(�j�%�c�S����&��H�{�֘�i�b�;�I��8z�ĵ�%��ㅟ_�r��e�{Ad�>�S�ᓡ�����}���b��0y�X'v����hb$r�*�i�*�-�oSY�NE���.$|
�Yd0��%��9�XH�j�|�)��8��ye|f�o��o�z5�?���S��9X*�L�s���Z�)��]�`�=\b�m����E���6��/D�����*�o �?s�^
w_�Nމ����PS_՘Cm�Z�0��9�J
�,��=Cn��SR&�c\
0h<�Dc����,y�oIX����<��H��(j^,���o��f_�V��A`B׍���}2#d� ���T��\�'~m�
Η��ԣy�|�<?ζ���<k�ߏK1Jb)���BOZ�N��L�]����T���m��O��]q}x+g>��KyNQI����E���$�s�pc������FVYo9[e��M��bn�?��g�b}~��
3[�O��1�ݣѥ� ؊�q;,���Ȉp�W��ѿ���D"w�~ҲC��}&�M�z�׬v�mP�P4��%��V�L��u��=������J�ȸ������f�I���Q��Yn�+�@�I1�r��(Pm^�˼�+%�5��GK�C��a���	�^ɽO��Yx+�xb�"�8�ŵ<�Ce:��ܚ�,��������n�b��#�liϨ�,�o����Xq�^���ME]��� �;�1m9�ۿ�]S ��>|I'���!W_ɾS���=�E���&[1`q�)�����z���Lы+`?�D����6�F�K��+m�����XAJZ�������3*�Q��n�d��&��;���g�S^9_�M<���ʛF��C�.뼚�̍�O�̎��	6�T�}N,���]�:%/��[B:�ٔ+�#�s�58۟E6gg驀9M�U�0�'~Tw?\�d�~�(��Y`��G��H��D�rj�L@UR��V�g+Y���;	4_V.�c�xgW=:5��R�i�G}�9E9�Sv���b���ۿ8aO�M#%`WqTն��yҾ�nhc\%(��T1�H �=�}���E�ޗ�X��w:*G����Ń5�s�!D�97�+e���`ҳkB�����ҿS�<�2��޺ڪ3ǻF+3^3�k&�.�U��lC��Ć�%�}x�	$������W��'��4O;�gş ��Op �IJ1������@D�ҋ�0�P�k.S��� ���ݖ�r�v�s�0}��?�X{]��!^֮����u7��ᅌ+κ	C ȣ��wd5 �T�\,YKڍk���|B̸a�6 ���E�q�z�����d�Q�!�uE3���3���#�e�C{6��z�5 =CPZ��"�\���F�N�_ZS�o[��ʁO4��E�?�a�L@�A����O��bg-��qv����|�P���)�G7<�bي6bzE��9�y���j�z/({��R0���f���@�r��=Pww���L�d�L��7�I˨�(�ʏ4��e�,{�J�k���	��^N�Cs��X�_F7vE�?�������\��`Λ-짠��0�T?L��ו�=$�{�2�#���r��<q1S��,YKE�"�P8KV���-l�1��}3�6��k�_2�;�Y�O�̕LC�#�e�$K�R�������qlg�r=wd�EeCmxvsP�L#b%�C a�8�6�#�R$�q�oi�O�Y׀
�S�A��K�$+!)ٞ��ե�T����#ASx�����l/i<&��[���x��(2Jӛ�����x���<'�x*�-Te��b�<�\}w7�֕<��c��f[��h�۪�w�͑���W�Wt�8�bf��}���Mޤ{XQ���������^���rⲡ�K��ș	l9?H�	�9�	)�樬:��t�[b�����-�h��CS�lr>��5��nݯ�����J��͂k?���,�M�r`��^�ق@�z!��q�Y��D�����C����{R�=SK�j�s�"�!�D�#QY��y9�Z/D7�L�pVy5�O���c���ß˪#��@	(YNbl)5��3��g�տ������h���ᛏ�"�W+QͶHX#�'���8_�;�����4'��G1/�Q�P�FԖ�!�~�fk�U��o��5�Vv4n�0{�4��m���P�Rs�7�QC�o�=I�@m�EJ���_)��g,�s	�`��F�{" oO��Ͼ�n��O�;i��n�h�N5�l�Ft�4�h���~9'iق�b'b��e!�H�H<t��rm�d�Gxapo�19�� ���c��HI�[��:�,�O��ʴ�����&��{��4 B�F$�h,)|�mx[�e!�!�G)�d�O�1����R�Ɉq��Q��S���7 �3{^ƿ�|�߉Bpb�&�d�=��i[������`�S��lu��R�=}����#! OA�}pTa>�$L�NP.��?��mQκ=�Mx��5]�ܨI��'7Wg��	��[�
d͍�y	�ì��V	aK��@�o n|�^f_�+(�̐L�����䭈��m.,����46��jFL/(��|O�yq�뚈�g�r��AǤ��Kxw��
�>�����b�b����M����7�| �z�����Hv��r�p[�oJ8l����5�_��9���T���L�O[&����7�Ɂ��۽�V�Ea��s��nl�]��f��֕�R�@�TTS����El�VU)"��j�н,�E�ղg4�"�S�J֪��1]h;�z�I?}Ө��V����B�o+�:rt��9��{�~����ٕ��,sD��u$U"�к��`0������'3�m�;R�[ߜ̀����ѝ�2��J�p�>�G�FDC�̺@?bE� ��]��Ux@A#��;�����v勋�ͧQ<:���!\��U��<Դ� zfȁ>\e�m'Lw�<J�zƂ���s�'<��jЙ�p<�1�QcZ���*f��e�û���] ��CA��;į_�0j��g�����5���)_P�,�\��1������-l���w)-�`(3?�z�g�d)���^��q+r���.�U'���A{��[2��a��pπv~D+�*Q���z�Lj�}�J�Y+ؾ��� ��ҪվxN�H���v<�o~��@�HSdK��7��|���i�\�ݰCW�TW(����R�����U'>�2��x�������s5!��'�#+�w�'�-ѱ0�	�S`����3�6�����bً�K�_H#�}������X����r���������J3�g�Md���Q��$�1�S��l-�Wiɕ�>^���с����2��K����=�-�V�5f��$B�쓯8�o~ܸ��c�UK�6�\�+gbE��V?�&���q�v��qG�Zf�aTdͥ���[�e���s���/6�<��&�j�~vZM��R~U�b��L�H��R�Ey0�����Ў���U��� �E��adO�{�i��Y�b�����v��9�V��疓L`9�V5��r1�0��O�*�&�߶/�@�N	B|4�"n�H�������-��������Gj������t�e)�f�j�hǌ+����\LІ�dv��9�\���2��TK�I;�t	�?�HI�4�#��bCY%tp�ɓ�5����%�����V�
�iW�L���(�)ǃ���"�KfuS������l�k;�d�����3%�ס�y�G�Dg�z�߹��;JJ�����V��,�CȜ���ڻg���8*ť�,��Շ���A�hY��!R��Ң��2���|��j����d}�q��E$���-�`�!˨B]��ʂ�g"��R ������.o/I�c��\V���}�=Ӏ����L=,��6ʾ�s{.D:�ݨ���yW]h��I�+%���n����1�`>���>��hp�&���Ę��������9%�&z��k�d�+�4���N�����Y-����[��ij@�(O9�l��0`J&�
#���|�(�شo��L��]��i�ө�\���ε�ɏ�G����Uw0Vg;��{��=�������$�4^J�r�>a}_�%1�I(�aD۠���~I�ܸ�r'��;���� `�>y�\��	Ld�!-��%H���P ���zڒP�%�j���-d=�6�e�Q!��
��7�5�ImdSe9<:�� �耔;�8�C�/��-� �*x�A�!`ke)���1�~;wy���6i��F�U;%������S�cS�b����EI������J�/«�=����ݤ�Z�`���$0��÷'n+k5�	�u?�#Q*�T+h�}�̊ή�F�Q��(�@���0"15��!)V\%��x9ߵ�@�o�6I��E`:��*Hyd�3����f��j����?�O�������.{��*;��I����. v���
͹5�]=� ų���f������"\y.���s)&R��-��]��A;�5�������s��sO�ZB�pŋ��OS�����l�]F���+�SsJ���F��T���F )��*!Y#�e���_{@C_õ}bٔm���Z(�ِO#�HѪ�{���<ڍb����+��/��^��T��m�u-�.�����@wZx�Pl�D������Y��*J�g��O�LrD�QU��D�=f���o{����ܥv@fw�a{�Ӄ7yQ-���9��τF�z�Z�g�J���Gú~��J LxFwc(0{O�u4?��7P��ηN/�����c�����\�=� ���{�����m0�BM0�|���$Ͽ1n&�@R���%m�E�Ĭ�^Eq����܄6vr�W��j6�����S���zI���k�T�
!\�H(�ۗp8�����~�0������w R�9�,�׫.wT0������b�]��_����)Z4�'�l�W������(�\ ��^G���� H����Q �����EE��g�    YZ