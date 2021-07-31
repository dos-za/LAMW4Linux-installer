#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3202333516"
MD5="9bfede7d835f857e106580f9594a3cbf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23396"
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
	echo Date of packaging: Sat Jul 31 15:40:39 -03 2021
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
�7zXZ  �ִF !   �X����["] �}��1Dd]����P�t�D�`�*�T��7%�/(Z|�@G����+�u� �lt�g�<��*�8KYmA��Q5�:L%0����n�0M��Uq�<k=t v�P�mLc����_�8�>���
[�� ��PF�"5v��@���N~p�����qiG��������6Z�FO �@�+�i���I�l^vGs��v�1�/�@�q����
��ϡ���P&������ڈ�`�[vx��X��I��a��j���"��"G�����2�7$�Hb�q·�s�X5�C/"���o��.�1��~2.hk΀E�p�6��'P�]��L�XM"��#Ʃlx�����Z�C�=#]��unS�#�8��2�ҕ�T���K��k�Y�.ܠ����u�!i�ٺ�=z��`F{M����n2-U��s2L��dٕ��N=�`��!�˘�:� 2TI�8m��(0J���,ߝY�iB8�mP���Z����1m�!����|�=��%@�����>�LZ�8�x	#�*����I����Mhm����[��F�-%2��zRk�U��54N��Gt��N� M�6U��'��KP9&wm�JF
Z�� dj�x��8X���!�LWβ0��5l����F����^{�[�B�g�g�֡E�G���!�`�j4�	�pm@`�lUU�6%����堣��������/�t�2����@�Q8��������t������v]�f<zS��i�ǿ�����wE�h�0��<�;�1^|f�J��>q�t���R�'�m:��N�G ��D����N�@b(2S�ĉfo�����r	�Ʃ*J��Lct���Q�Bak�K1я��)�Q�G���,��yƉo��_�'����o�Ƒ�d���v�F�������_P.�<���� ����BJ^�!�,�їT�������at�a�j� {RAAG�'0�s~��nK�";B>�Har{��$3E�$��^�uP~����xQS*�����g5�'��Wu-�:s`XGd䥓��@�����a���3��,8�����~���ê��KJq�@W��.-�m���
�H�
�ʗy���Lo�!u�|	hqA��]%G[�@M��n�����E�w��rA�T�.���0k�������}�,1���K�M@�΋DqBM*��o�
����ST�B�*,hc��1����d��e-_�v�(x��tU/� *�����rN,��:g>�h�[H�A�� �~��由z9
����Aj��U"ij>��F����Or���-�\��{~Af���KS~"���!��)����ymT7�l��ޭ�F�ʍ5zH�����a�pmj����#ݐ���EdTjB�[���*�E���o�1�J�m;��>ꁍ��[�`!����.I�I�����Vy����o
z��A�jY���A���P�
�tq�<�����wǝ���'k���Br�.SP\�*`��mib�ݯ��6� ��cFޡ�%!�ǆ�) C���G��-D�+���I&�l�/����d$ub����*-�@LL�#�QO�
�ֻ4c������0pU�r������kfG�3۷���X ȴ�W��9y7ɋ�&'���Wg��WCZB�FPa��y��R!Z˙�h�͔�
�c��p�c���o�o�����`����IAˎ<�V�O5�m�Q`��ۙ�.��;8r����*0C_�t�s����	 j�A�iۿjq������ �u��>8���BI.�E�,��\劬����~.�eY-�#��hq,�6���č]�z1�1)&Q�t����F��D3k֦�Piw�$�U/����M
:��!��ŽF�l�Z+�r̠@�M�/Iy�}�nDyt��q�ަ�P�	���,�5gX���j$������8yo+�� �:Gb?��Wx@iX�}�_@���`n�����R=?
Ղ��C	��J3I�)�1�W�O����f��qz��iP�R�}��"ܥQ*hň?/Y�T�u�Sw���K�Ԥ�FS�ub|<�T���8��>�X�iҥ}���ߕO���	P��n0��$�i�[6��/Z2�r`�-��Α-�W�)��6b"gj$}������D��+�?
 8�k���K4�}!���$�13��X"�,t�O���g^�p�WL�5�x��9��ڸ��~P�~2�ԏQd2�zX/~5��.ݙ�[_�|D ���}}�������1�ר�D+������ZH�nD�(;� ^�׵��f�	-	�Z<o�1��_bo+ӻ� ��χҠO��	ν�@�,�棚�1��1裕��������.��K�A�����V'�O��
��kw�Z��N��,g������E�)��42�&��=�O�y�øpr�_�tAqL���(=�7���R�&�$�s)FS�e û6��<��K��r	z�ާ���M`�m.06�w��I*�,�>0M��)�7��<�T�	��Ǯ��3��<�GU����h����7��1TV��0�xs��@E'�5v[��%�u���#'6�}����ņ��<^�%�oN���Y����v�\T�_$ˡ|�>}�ڃ�X�
�u��l<��_�1B�w��/W{"���O
'ēG#w�㔇Z]5��Zj���ª���sQ�vPoh�1��]���Y�C��O�E��Kzv���z�شA�?m�#��~RZo���N?��*�z��w�
�y������#�(�s���r�AL��`����-�ʭXH�d�����\ɪ��5��l��Թ{ẐH2�y���l����a��v٥s���8�d��P1����o+����Ɲ"�Ty��7}A��ͭ��6@ ���(f�FY#�D����8]R�$e
�|�Ӳ �#����|��\G��Nf���s�7R�q�8H*q�d_NyRv��j�V-�0����V!zկm0�Z��F,��[j�W��58�����ǖF08~�}z��&>����9��i)a�*�5�%��80�J�fl��{z\�m+�CI<�|RW�أs�@�zԤꄬ���#��/��4y���B%�:z��'<�
&�!��fR��f��/}<N�If�Gxk������ �]k��z����&f&�`�!wߍS�G��1(ʩ#�/�~I$�Pf��p��=3��H躵t��O��(������ȩ��U�p�q{����*�:֟C5��7xV����s�h�/��!���/����N���y2e�x��a=���$�����s�r=?�Ci�@a�$���kte�֟?G��*=�0/����^&MѤ�� 9��� �A��������ƅ�%_��������ߵ�)ך���N੘�ϊQl�����qs���y����}yP�Kp�K#���J^�V�*�6���5�qTy$,4	w4oF��� �V�b5��ߪ���p�6�7�͠6���T�hAl�������u$D��Z"�`T)p�b��b��2�s b��\���IX��ɡ���1�������*!��V-b:΄��-=}yPL
Qd�0G�4̤�S
t)l�`C���YnN��9�a?�]_?���Q>��)}Q����`��Z���G�b)�����QO�����w����)<A��� 2�R��Ɂ�r�Ԛ�A���~8 5��_���DYY*��@E�d��mbN�C5��܍����<m��%��ӷtV�%cy�9耸�-Z�{0*�-���uZ�_
�
l��b1��������k��
�ti�Hg��΁��A;��yz��:L�[�nZ~�W�x�����
���]tT�u��kD&pT�wT�p�NG5�HO ��$���m�D����kl����AiW/2�y�~K=��h+o���d��cpX�5�lt7��h�����C����K�4�%��n��x[��xvϝ��ۤ����. {'�7J��Qi��8�����8h�s@��P�RЃ]]�r�#��؛'IE��>�k�&�~>�ޓ�� ���L鎁ƅ2B�2E|�=>)4�64�>���p�A'�[^<҇$Q�#|Į{�s{��� �L�݄�?���*�"�7�#��a����1<"k�h���+�0_?V O��t���w�O���ݧ����p�p�r(֢�qmզ|;.c����d�.�F&���'&}�C]������l,;�I"@}3���o���n�Z&ԉ�:S�D� g�P�gsp���ރ���/w�4P3��w)x�4����W���?���/�5�C$��5�՜��"p���?�2���v4�(�fD|�� e��0���!
����)��1�[��z"���2"�4��#���-4�����YD�h��> �ol���0q^�����E����C�ŅbS|�"Ī�<5�7��� 9��-M0�K�~�.��om�EoOWNB�鼢�s� �U�|v��gk5}]�����3/r)��u�sز(O6�����ܚ�S���/x�k�o�x�����]�B �A��0}I?�e�5+]��(Owәz�{M�QW(��t���h����Y⵰�[J�DUC�^�9y���=p�lR���|�����0���YV"h��L~VX�X��r8��Z���1�@IU�ݙ��\�<�T���`s��W����<�N#$UR�q�9O)�7�e�߯tM���w���1��"�1�S�F�6��S��<�:jWA,�[3�b9N�W���r��������BU���r�o�^��^i��[}و��g�X$w�I���VC��o��YM��@,��¿D��sV��E�:]R���i6�F��'����G�!���]��W��P��}�Ĩ��ʨ�!�j��L2���-l��o{U�B�����j� 1^�(\��~\L�^S�}�X�O��cS���uLa��N+�BD�����Z��й=8j�lZdQ~d�'!G��� �:��QQ}�9�;��ټ����T�Բ����XP:1M$���Dl�&h���.cv{���۵[�ѯ1w�����F�-V��_�#�{�@�ok���!�%}dJ�N�z���u���a��0���_��[���g��ҟ��5B��3'9Gt8�|��&ـ"�g[��y�^���D��og2�+24`�{��\n��~�ܚ��?Ӑ����dȈ�1� �X���k}��}�$f�o?�%X�����.��GaIMc5�t,����U�ʴ�"" V� |�4�m��d]�� s �88� �]�	���>��H��z.� >�q�A��	9�b$���{�)�rٟT&D�?;��L@��.���r�[4���
X���cN�7���
 `�K�R����+ݍ" �LD~����^����]�LJo�JtYm�(��_����n����ֆ%�!�*č��:���-$��&��~VPT��U���ن׉��`ȖP�v����uHQ�I!e����5��CT���-��K&t��)y#қ����r �c<�=D��P���KxU(��r)���'�#l���A��x@'4)�@�_c� A�x�bJߒ@z� o^~��T �yX�h&��n�Lȟ���۱2(�@]b--;��_f�m�u�k\
7u8�mcū�U�ӏ vY<���H�ƭ"�R`�^����X}��$���gt,#�d����w��պB9�U���7kM�9�tR߮*���B�Ɏ���x�v
n`l�͑mS�r�����A�^\=i1�\,��35�V�n�|Ӊv|��NVQi&�V���y���y%=��Z7� �ϳc�4bN�W��Ք)+��8�m�u�Yf�������x�퀩��%��)��-Ѕ����;E��y������f�F�d�gט����z�J�	I���H{�N?��A�M��Vn����Mn��ByCy"*Ո��\Ǯz��5�����-T3��ȯ��;B�LA��,��`9� ����/>]��[r��@=���4c$��a�c{Vlͮ1568�4G]�[d�i��DIn���� �RM��%p�� T�<uM5X�n*F���n�}�\��t���rEO�o�_����C��ý���������=��>	y�M�v��n���?1���[ŧp ����~�,�)���{��f�|�>kN4��	�����@|�H4߆�ٮ��"H�J]��CJ�B[_m��1.8q[f2�rLTJR�k�j�K��g{ē�i-sn/V;ý�+���������񂤒��֟ }z0;6~y��E���R��y�_ը��Y��.��y�7�Ǫ,��^eeh��yL(��,<�D�g�Xe�e����T)s�5L�S�V���<�hԀ{1�~���1�2ɀ9�?L,jRg���E'_ν����Q� �I��[����E�:��S`��MA���Zj��;��w�;Ӡ��ݜiqr�)�Z�X�g�*u�Y��^���E�<H��& �Mr�fJ��;��n��VN�8��ʜ$P��W�,�b�� |���_����Ϟ9���Ͳl��4�W?�F�9`�ƞKUȪ 1��-�vEIG�G�����(�>�f�Fl+j<5���3ýmui'k�	�͗��T�)��T�̈������<�AH�n�9��Z���/�:�h���ǝ禦��Ƃ����J�����^���b�����x��.��Dni��K�A-J�g}g����4�񹞴��]��*f���E_M�_�4y�˪H�>��ر�{�d��d�	��V�Z��Z�����h�T����F�^ȄD�İ����a;ضR��g�����ᷯ�˯)���8? cy]T,|h4���A2K^���0�*�J���*G%kq�~��B39{��cd�f,Nό��2ϱ�L[z�����x�����`t�"�@˚�w��o�t�n�7�bS&Df��
 �}��cm3Q�J���.����n��� /ބ8"?�H<P�L4��<��a�&ȿ1�H~�s��$�L
��3��kֈ�H��o&����;̣cQ؁��m=W���Oeπ������3 �E�&)�N�!�b�(�l�����İ,�̗��; ��e��6�h>_��D�e7�e}�	��uT�I?���%�`�O����a���#:?_���,F�	��~����[u�7
�	�ʤnJׇ�'_�k�/5wr��I��j��b�%����d�s���\@�Y������v)��d�T�{���	_d�M������DX�p��1w�?]�ty4��������Y�O�L$d�����Zy~23u8��G��V�j�-��P�>	���x��:I�
t�ú���d����+��/g��ǣp�{���1z�Ce,�tZ�QA�nC���:&D����+��@̵	��r��N?]qn���P����kc�4���@��_(�^*� �m-�> 4�I�������bH&EHt�.�����Z����UҨ��R��z�������3AeQr��
�om����Cy�a�����΢�<���6ݿ�3�^�I}���9�<j[�dO��%����i~�]Ω,���,��ib���q�.�s7�Th��c��d>�3���σ�ZeۜI�g��\��@$Ph���j
J'�ڂ�]N4vx�;��#������	0C3�*�Ch��ز���P�
5~)1W�
v)��8�߻�lͳN,uRo�v6���2�W�9�|@
Z�1&��pÍYTI�:΀�@�����i$��ܵ��RG�>�������f�~��A_*Q�-@y����������hK�����9��9y��v�SE��*��1nm�M�7�����+>�|�Z��TӬ�IJ����J��_�b���fHl��d5� Rp(�Tӕ)%ps]K(χ��-���\��lhBU��n [9�3�G�й`�[S�%��q�<7���p��νpnOp�Fc�E9����4���d�wc��k�<��.��"��2�]� r�-�7��&<;"f�{B��Gc|�j<D�P:U(43D(m�q����-5�[~89��S�+<H�ƿmvzё|�	Њ$� I�B��O�[�}��>{?�I�g�.(����M�� �����3�9=Iښ�q��(���F��Y���4,A��= �����)� ^�Р�z=C��ԑ�D"���NKS6�m��($p�|���<�����&s��pk�+��RN�)��8�A����r(� 
��U�:��#w]:+LH]�"�O�gMy�I�ޣ��n�k�7���h��Z�(����oZPSM�����6�n
��D���ČW����j葭H��.���"Z�[(��`�J���ϗ����]|��ݙǧ���U�	ˑ� ��${E�?��|�P�SM/��9�����鹞:����<lAp�FW���k����X��x&Q��7��.��[#�Đ���`���c=V��NrmU"% �9����âӝ4SX)Xv�{�V��r��H:y\{��z)gxٮ	-��\D��Yu�Z�@�`�*M�f�q�5D�asd�_Xtc��|N�~�蟰O���/w��LC�y��<Ԃ@k�EG�f��n=�|h�Iko�/��B��DPd!yp<��e�G[�}�q[1�Α��5�(G�ֵ@ź��IB�mo�rE>��{�m��5ed_�[�m��	�r�)��~�\$n7kAW%p�����)����c6(]�)�"�@�ӽܢ�]�7��|Hc��qtHS��\&#h�I_�D���t�[�L魁B�+��� �dݷ�^�s�J�h*��3P����a"6h�P�NT����QY�,\|��7����ڂ�_U��T�{�e�4�ZY%k:9�_�����#���ׅ��^��T D�%��ԑ�@��>���22O{����{DTY��oS��"A�������%b *�K�s�9r��%����_n]���bc�#M$��H��$W��.�5I�AѪ]��J�#���dh:Ќ����dGL�e�%n�g�0��>s9��2u��55z�P�����R �|aN!�Q�P2^s#H�����Вl�!���L_��\�n�E��g� �9�@�&d��ᭉXsRWn[s�ʰ�B��&��30�C�w�S�-g,�-�K,�����9;_��oB��f�"̚�5Q�r��m��ۓݔ��ݵ�tȧ��Cd�+��u�(N���a�ƭVޏ�$ƆpLG����Xr���)3y~���}����`�^�Z�؃]儉�wǩ�l}s�*J��V����֪,���{�J�q����옯<�2kļ�|B�]�G���}��"�20^�#T����>�4Tะ^�q�?4=U'�aA�r���	��Y>�?�u<0~�
Irr"���3���-���J �x���k�*�V����~����̖�!�Ŀ�����ٗ�Pq��9�[lr0�=�J6�$��mϨ�9)�ԗ+���3���3�ޗ[����k�1\0���p��T�y9�����.��7�� �i���.m��Ѱ\]��6>h��$8�(0p5؅h;$���ݙ=`�$�t��Y� �J�%�'��~�a�;U��c·���b��-�:F\�>�������~c��*K݊0�L�î���	bn4���c�aAa5m����T^�
Ԭ�k����<�����ͮ��䉷���|r�޽��u�Ԡ��D�j�:�.�0�x)�&Z=ؾ/��׬*�K��nBeM�~���ܐ��z�ѧqc�����*���D��o�^c���fb�O�c������Z�s��c���$v�+�������l2�z �u~ҟ�<���G{D�r���$���`h:���
�%P�3���}'Wx�-�`̛���t`,�:�֣s�J_]UL���D�v�*�̄�*p�Пe�����(���:��hd���S�EH&q����`8�rV�a�	��!��I�Pv^�0�c
մ0a�Ql(G�*۽A����n~"hw���Wb>[�
 �N� �Nd(�(b�U�P�K� �)G���iA� %��o���Z�JjqK�Iϒ�%JjfZ�������o4�홐�"����>��eY�S�ô���gGP��	'��>%G܈?�@��n^F��`'[�&��oLI�"I%���zꖀL�I*�Ǡ����cp�*+�ަZv�'c�����N��)?bz|D��11 {;��a��--{��_�Ɨ&B��$�g{O�[�RЄo��Ϥ�x L���J�ى�-ʐ�v�.9�m�d�������'�}H�/Oy���23ғ�����+��G,:r��gY��۵�č�x6ɛ�^3#J�U�yN��]ss�~�6_����D�I�$_|z� #6���<�~�IV1:�N��}�?��jH����`й Xt�BHA[j�_�2$�.q�3��A��O'�[~���X�ةq���VZh������Y�� ���M+��ϡ�3�V�P�H��
�H��罣���Dd{q=�� M���k�A�y�R�$00��Z� �1�|?���.%�!%)}���	!�^�¨Ӫ��f�3�1��#�E��@��G���LX.�|��6_�G�d2��\�w�����p��tC�������)��ш�#�3��d���|G��-4!�a�e��j�I��;K�`��q�EH�[hB�_zE�����b�B�o �̕�rL�=�G��] t
�nݙ��� m��V�o�c�r��^N�@o?�z��D��� �����} ���a����w3A��6��7�cx��:)�!��'Mz�[.F�~>�����i\� *��6��"5mۧb�>��������#���?20���:�?�uB�ϨW�>"���4u���
�y���ë �%u�٫p�==�� ��/���hY��x~w#'��
�#R�kar��C\bĞ����2�>�(X^v��2n��3v(w,���k��^���8�k&��Ia~�"���x��`?��Uz6-�l�b�s���������Z}=:\�ů'љG��qU�HA���3�.��E�KB4�T��� �/���@ۂ/g� ��R,���e�-c`5Y^��c�{�����a�,(����Ћ�\o�t�-:G3���I��V�J�J[��H���]�=}ե�C�c�x��%q���#n�`��׮d��ݍ|��~���,��٪ ��؈�*�%F+7kS���C`X:�S`n�b���?��J�����@c&Sq����b�ۏ����x3��n�q6��M����Nd���:�|�7Q��@m�^�
Tu��w��;��8~��M�_S7�VS���_�"	]�jVn�x��R���6�z�>��D�>gx��v~����I����޳�x/��U�3�3�����;d;��c{����wG��-��j�~o"���ÌB��eYQ����	})��y�ɔr�4)��s��uj�z�@�iGU qs�G����I
�Y�l�)۩�>�[��<�����=^���lP��?=��(~�綟�h�+& �@l}P7�Q&.��Z��H qy�����1%@�ybz��M>Nqӓޅ����pa_��0�W�b�˪�@D���IϢB��H}�)�� ���K��x=4-u�cŚ�M�OT��D�l����_"5��?���C�Wс�Q���#V.9��@��3܋&�����<�ќ��N�_���ݤ��7~��~�7�mN=�"6��jH�ז"0�W��
�����Yl��W0{,�j��G�{R�0qF����Ny����H\�zS�D�FS�*��7NF��|�ܙ4C�E��"
a<n��qa_c֏�Hd/��&p}zϳ�0~6Y�r�� [��0,��1�E�_W:��3����sE$�Iy��kG���^��U��8�ґzn#
%6�h���߆]O]�^צ�v�'=n�m�g�Zr_�NW���b�"����p�6�?3���O�S�iZ��˙���j[����.�xeKU���R�=OO�J)�j��xޢ�Յ�6����87
�Ӊ8%8���W1N�O�;�r�
���'qrΖ�AṮ�L���Y�! �p	ȣg��Y�k����}�y1����-f��07B�ȷ���/<G���>3����R0?�]�-8�ĩ\���$�b(Ǵ4�r��4%�2L�{�N�����i'�܅���w��le���4���g�������g�K֥t!���yo�y��Y��䬜tE��"�vl��(����aqkj@��A<$�[Y�w�dJD�?c�?a�S���!P��8P��ױMWm�_���?���ktTo��ص��A捙-��z����=4,\���W9[��z?=5*�]Y13J��N�8�:�k�p�B��Qe��0�"��oHG�s�����u����|���@H}~l�rS���1���� ��m��t�,�-!D�b��<@��q���^ۃ�@�v�i6��F��Z����6���Ƈ��r�ϖ�Q��a/�=��mM���mM�	�6�Þ7�ͮ�̩A#lND�".v�L�F;�>M���"�-�Ȓ�#b�� �rВ�qA�(>�����%��������Bw��F�Q����iA�'*04�v�U%��ᛳ2Iʰ��j(j<h`�(J��/��`�&צ;I���T�{f7��;R�^��.a'jlo3Oe���F����:�N�Gb6��N?n����<�w�j�(�.��cf3��ޜ�,�f����-#^��L�K�5f���#3x}{����}tD���t�����Q�z�r�JR��荋��2FӺc�1z� �9N�s����Z�V����qs�~C��	��J�!��6S���4�|+��h�p���~���	�P�X}���)��� {�<���5�L���������;t���:5p�	�6ӣ@C{'{�2;��I��`����F�9�r#JnFa���E_u6H���L�h0��U�j��N�3���S�C`=�����D<���;Ư<0ۤ��:Y;K�h�NJ��<�y'�a)/�H�}���u������k��y�|l���(�zyx/&�7zv�#>5{g<d��fa� 
���<�c�b����2�K��X䏏���V/��0諾L�R`�a#���9�jQ��~͚czm�PB��mJ��c���"���������#�j���+�EMA�5up���V<����sS�S!�-�RAcdF)7����1��S1���=,1�u;�,�-|,��P� �ȣ��Y��q+�A� 5U)�٧R��D0�x:������[���"�s���F}&p��m'�Ju�)�wWU�Ԛ��#8?�W�-�m��C�� G�b�H������W��l5��#"v�2ZG{&�wY{>"�F�kB���p?b8+������� u������J����s�w���8��F���#TP.�ikEW#'�S��&9"�c�O�v�ڥ�J�S����`����v%f�`��*�l��>���*B����;�x��/�p8xq��w&���ƙ�竁���S8�4�n����J5����;7��k�`9Ti��p{�e �k�t���wщ�%>��L_�{�1CNM���=6�Vb6H�&��w����!��!��Du�7�͙���zﵷ�x�C��*��U�=Kz��w`�s�"��' 1a�yLw<	�n@h��h�|]Fr�w��Z����6��R��x����xVpDt{g��^��s(�5.��KJ��
U�$iv�\�f#}���v������@ո�[g�|dgp[��^*��4�IoA6l:;϶����!xQ�B�a�6n�I����[ˠcڣ[P��)>I��&�ت�"4�#��sn�-/J���ߑ&wRMؕq���_#;�-캏���BϤ?���I�~���<�7Ə�l�)yU#�BNY�'�G��p }�����$�a7#ۚ�v����'�7DZ�;�F4�$�؉�;6Az�*�����M�5 ��F\ď̻d��Ҷa�g���#�j-BY�P��68x��^��T�͒��ɪ����1X�ؾ�y?L�"ɄL߮_
�T2;�:�^�}T��g?]tf.a-��UC~\�3ۭ��՟�b߻�,g#�@k�B22�{,��Ӻ��2��
�/� p��b �|��������~������&3n◍G����)�mRsP�["ˉԾr|�:F�|�2 #�DȪ�?Tn 0�ًǤ����gO�s��IIJh�)4IB�QZU��sv�$��v7@�3�f��co=�T��|�����9�Qz��r<2{=΍�o��27d<����~C?W���_m�ң�rJm4!
LŠD8u{G�*����v�|b����cu�P���/�МV0M4G�ۀ��
�X!�8C5�Nq����w�ks{a}���?x7��,��'W/څ�}�9��f_q�=*[SX�2���9i鐆�K��EBGQ�ԣ�X����x:�e�Q[��4R9r��-I&������|ɣ�nh���>��o��(�LݸEpP��R�H�?f@��R�e�կ3"� f�L��!�K�5�GH�5��cҤ����rp16�!���7�H��Ÿ�g��dV�D�B~���L�g�~u������
�+�����!w�)�D!�^�T�4�#�h�#W��U�4t�@�W�G��P<|̈Z��R9��WNuWAB�!2l������kfE�q�lx�@�{����ҙ��^�gp�N`e��`h�b���.�y$.f��jZs��5rλ"Z��)��`��N%Ė��qVx�V���!Y_k��Eeڄ��$��@;HN��bo'zD�6ZQ|��l!�<��P�_�/Stx"���ۀ�?���/eU�\q?���6=���v�\Q��_�6�V"��xG%�6/T���e�V
7��O�-����L��tT�/��G�2�,�򧟜�#+���rȝ���&�w�Z ΄��/6��/��#����"�{ݠ������줨)�6��[V���G3c��.��t��@�>]����Z�'��O�șE��MI�\_n�k>.=��^��w���[�*p�ޛ�K�H?�'��0��j�${3&Ձe�K��xWHȰ�"9Ǽ�b���*x>�33����^�z�P6�5w����4�!�*��y�Sn��1 IJ9�aT�3���t�-3�VG9n,n�����ϔ#H_Z��z�/2=��k:��,s�UB�O����y�_���_$`�/�}Ëщ�'���O6����bC�:L�a�\�(�G�~4 �1#�?�0=��048��K�|JP�%jBgud���J��L��̭RȐ�IJ���n�ˁBᆀ~�񈡠!bF�6�����׀R�_Rh ��f���Wk숧h#B�1]H��� �>���>���I��ά�QC�����y��U4�=?рf{+����E�A���b(���=򉘺�1ҋ�����AFWmnAʯ�E���Bd��g�[�ҊF�H��Ácw2�,|y2�9u���
i�-SO��t�>�K��ȅ�cnK�^@4X�S��ʍ��8�W`x
�.<I(C�y��N!�� IW�KF/|a�qtf�~WW�F�%ny<bV��Q��{7��Ne� ����$����/���dveY?���K�U:�dYm֡��c]Z�;I��Ay���"�´��柬R��ܒ��SХS��D~ucX��W.�%��Z��s�3Kz��NP��,�WI�E�UЮ@����Rvb��.�Ə1c�����Sp��.��2^�7ɡ�Ɐ4)���m!�z�Ŕ.�9G"%a/�#�G�ޱ�jK�?J�&�� ¯֮7P���[ߦ��0#>��*�<����������B�:Y|;F�]�4F���<��2P)�R0�r�<�BmI擧~!�D[m��[��.�׵�C���R��b��������mc�zdM�@�ҕ�I�8=�q���1�x���`-��	#"W!�
Qv9�Z����})˽������D:��:G͋z�ʢ��������g^���0�x@E� ,����d�(�p�;��+u�B\ >�"����j�#�O�R!���+?_�$݄����c��5;gʩ�Y>��h���sJ)�07�"�*I�P�:V:�!���J�N�=��9�B���9�P6h��W��U���L�s�M�J.5�+�یO�WҫXu�8��þ��-O���"��s���������?���7���>'��?_�t��Q+�gc.:B�`�Ɂ�dF�O�&�Ԥ(	�()�Ou�є���Q�Mf?��{8��k�K�ו퍻ۛ�ׅ �(a�[H��"-ȯ�2d]���)��>��U @����q6vnMk)��`&��B�Dh��\�'������>�ө�jx;�ȹ�se�TɱE�]�� ��m�I���a݅x��7��9�0�mH�S ��$�F�)*ӤEO=��&���,��Y�Euo�Ԣ˂��<���dr�#�b�0eм/�h�� �,��H *�\9 ʳ�Q�:��1~�Hc��O�>��p��Hʹ¾������?���j8�\І�Tk����Hr��|�e��̂P���3��Õr,+�m]��� 8a빘Ȋ����e]~��w���F����:;Xb�{w����PR0 �'7�ڶf Gt|�3�!Y! ������]��xP4�	!��];�ث_�s�Ʊx�l1G
"�͵�Oj�2�@��njԶ�'��.W05�*��C�l��=���%�_.¶�
���e�3<⧆���������zt[Hr>&�H���\�+:�l1��W��x����"��OVP��EɢV]��C��:�eZ��>�;}L�Un�0w#\�)vXt�\��-yg��f04�^�1N���MF� s��Η��}�$����R�8%|SF��B��}fe�z"�N(����F�F��y�A��>��U���e�z��}=�`�r�a�>�hK��+���Ab��B"2���^����n$�w 2�TP7mD3Xv�G}'z^������%�<,*�����J�6S\Ć���5���lq�V󠸄�0�U[+�ڧ��z8��Bs ��7!6�/C�Qt�����`<��6B�}�ǜ&U�4�M���H!�~[�� ��FE�=\-�o*~���St��H1�/�u�]A���Ԯ�Te��[���g�|�C]�zO��5���?�88Q�{j2!� �C1���[MԘ�(jpE7P6�h���!j�g.rw�LB+�^�?]x\�0C�fi��
[>_1lt�T�(�i�|�G�<I���T�/ F��μ{� ��!���PO?.`Ζ6Y"�V.j`ZQp�2,��d�VU�bjR�D�i˒۵��0�7#��|nt]mG�G�/�p��V��)����_��D���M
զ׻��
t-�ՊL�D�a�	l���>���΍��z�#9��F#�����(_�`���(�(��sδ�o��d��	�;o(���(�H]�T#�ſ�jݞ�mj��w]m&Nmt�T������=0�g/��TP (����h����/��+!�B2�t*Tga˦g�����Zg"L��#��ɉ�Q��v�OZ��g-i@E�r���X)ӷ%c_��PRcB�� ����H�($_C���F�d*���-7>�-��}Y�`��E�c�/����Q�[ۿᛶ�hfΌ_���,�[�D/���q�Y�#k�CK��(ϓ��j.����/��O�c�_׻6���M���f�^�p6�J�9BÃ�D����Ò\@������e�8'�2\	�8��*S.|7��#�0�:���1�X���[ݪ����'b�<ϓfA[}��� T(#��$0�~�%���av�eU�_3W?#����׹`%��,(��
C�ga�S�pj�tu��J�pqQt����L�(|wCc\Qfl��toRi5R���$V���W�Ŀu����识?j����q����W���X�>��ZKr_�<��J�5�_��qC��i{cO���[=7<5�W�8��@s���D�R�t�>���i��� pg�{2����8�~N���3���]���YnFJ��Gl�W�Yr�+Ibh�QRTX˵ni�^�Z {=}^�:�$9�9z�%�o��Jd��C��?�'�}�����47�L*L��$%O<訍ٽ�%�R`�\���b+4ߏ��Uf��MKcȬY�J�����������
ОN'Xh�,�J�x�7�������c���rE��E�%+�E<F��K�����h�%��̍}e���U*���]d�y�]���{����y����'�H;A�_0n���-_��I�W|�,�ѥ ���Ó����U��w4!_����s7��	lcm@.�Z�����^r��v(xzޣr*l��n�D�,4ʔX;��D^�?5u�������F'��n��m�W�L%��l<?��f_e�nsQ���z
.>I��T-p))Zml4�]�5���3�y3Et�}I��?��N2��8�C���c7Һ���IR����	��L��/�Z����{�>/�d|"�C�\���
�)��)lUK�4�kO1}�#Ր͒��RP�~o�����������4�H ���y����娴D���;���bE\x�͞�N����B�	D={O��*�8B��o$��hO�RcwT���ⴿ���cMMtp���� $��<֣H�?�x��_B���u���"+&�!�n��%���y��j���Z2�L�H="�q~��(�b������Ξ�uۓ� p%W�iИ��D}U_i.��r8��"���K�M�i�n�x��h�J�&�-�V)A6+@�ތ�Us@���ͣ{c�����lx*6_��2BB��~�����,�w̢AH�� Y�a�6#���h�����s���֥��3X���Hm��C��pt��ߎԫ��3�VL�V.$�r�U�����Q6;^�����e�u�B}-�e~��;OdZ�TХI�X����F ���܋WU�a{�?�s�������8��SO���a�4 �Ǳ���z���?;d�j=߰6����tb:0T\����)��{��z+{���+��v�GugY�%�8�ů�6��yh�(aF58����؏�$~͞t^��*V�������}��*tړ��&�2Ǳۄu���>1i��2�|;����7m �&�$����غ�W�!S/F��� �)�J+�Ho"j��P��tDʥ��܏�ۭ�����A<�`?�!�:�5�UH���|�@ٿ!ɦ�29�&�"2�h_���W�� 1NG�]vPH�!��vD�O����65_ӷA�ḩ�Ġ%w��	�p��H�͗u��ǄÁs�(��Yߗ���u�kR'չ� Vӹ�k�y׌����A��*qy��0j���W�Hޱ4�W��Y�_/k\��h́^BCL�x��s��O���O�U�.D#�C37-�$�h�������@����;�h6�ب���H]�j�nnz"@?�έ~Bo@�����ϒ�v'`��C�;�T�gF���%��Y�b���ó!�Bb'�Gd3�����y'�޺�Q��]k%~7l)� ��+]��8��Y�>�M��%7Ax.����근=�M�%�݊l�H� �Ћ�=�(���c��d	����c?2:��_�ET�c3m�=�A�k��$@�MU��'��\��p�x8��D��B�mG�4\2���?���<�i	U����x��,e���	��1��88�j�d3���;Tye��j%�Z;`���QY{3�-�V�xWRBg��{�R��c�F��6�H8Ca�* �ȱO�G� p���]z��"����7���DG�S�!\w���6C�cou�����!x����0:�72��M����D�8�]��a�bCӷ+��X�Pε>s��x���,"k�+A�BDۧj!#�g�$��f�a=g�!*����]�
�.m�J"�R+�[DMͰl��'�C��s�3+=Z�Y��K�Hf���D����>o�}�`�kl����R������N���t��m7�' ����G��˅C�U+��-$hK��O�"!���/}6)�2����/:[y2~���>I	�c>ߢ��V����W���f��[��g����R���#�,�tE!�"x��ge�)�L3Q�P�8�5�\v+/JD\���RT�BV������o"W
-0_��v}��To��T�4��vZ�1fSx��ڟ@05o*�[�*�b �.*8�MHΖ�Ԫ�����t\V|����*D�sR��Nۮ�[i7u�cb�5�\��ݿY���e�eh�2��DH��'���FKrğ��;̶�����iI��$U>��`�ivGX<8�������A���"��[b�&)g���<�j�@񾞥n�{�DȚN��1��әS�߯T�7� ����,�s R��L{��v�P�eݫ��9X"k�G��}Gr�O��끄��s����K�c&��3��-6�������4}.ߕ�?5O@1��;R���b���pٴ���H�:��H��@�"E�U!�bdK�9�
b�	���>S���T$
B�ק�a��u�Z_k�r�2��rz����ׇZY4�N�/ʉ$�}c�&񣟯�%e�Sތ�&�CD7e�!7�@p�	(���B�>�GT�Sq���&`��ů�X٣	�%��3J���ԉG5����}�?L�|غ�ȅ}T�q
r"�J��;�X>�"����]���:|U\�����g�&P>[k�PM͠����p4=5�ӽ�����.�0p�4���9�.��DZ1~���X����ح����>�,Ձ|q�˥�`dҥ�HXs0��j��e^~� .FFU/7�>֛n��:傅�"�S�5o�+d���� �&n��M��Y��V��C�9d�����"��<_��C��R�E����dY2��޶� t�M��F�[�q���\���:��0/�d�Dc��f�:M�R1E_ݧ�n��
�ֈ�x�F!c�;D0
q;E���~Ǻ��?P2���DQ�Ir�^Ǡ���?��Epm&�� �*/������O��{��Sܔ,5���O�����⬳��tE�U̴ݗ�_yl�R�BI>[�hSe�Q<I������"��6�C�22��o
jlw�B���H��:���g벚˶þ(�r�S���~��"��PH=�B{�=��7��݁�d�VE��ث�^݇%)
��_k"���"^�2���z<H�].}S�s�!z��u��c� �~�㣞G/U^j��J�#�����A�Ň�z��E���Ѫ�Y�'����8�T�l4O���A�K��P���i��I�g����<��0O޿5L8�Ѧ�F�i�c�'JM�4$<܉I�V��/U���~�C�w��X�-Ԣv�~�g��un}���J<4��(�����5�����aƧb��� ����bݯ8�[n�.��b� �+Jl��F�vsKn��nM�nq��-7a�1��D�9B����K)�^���R�sd�WZ�m_H�3����m�T�[�>��u),���w%����.�v!]ބk��P5�a���r�����/Fx��qF��Sg��m�L\O:�5}��<�#Y�v.���Y�������cհu�i�?���qe�7���n��S�zp9X���{^�k&�^WA/})�=�ARG�V��7���;��GE��gd�V�Bm7�H$S2���~�W+ej� ��2�:9�9Aa��̑�H�%xi@��	%|@��� d~����[�+ӥ��g�ŵd����X`brW�W�l�h���[��Ǝ^=�]!X\t�K�}C5�~)]�]�}�Xg���T
�A�-����,?�7Ө��s#�{���o�?×%����Jt�Xs+�����$���^@�w$|O��{��h���QEf���}��,GD�.�p�K�,K<�YD/B�݀Q�h}�_�ayG��A�}z$�)�&ƵI��CH$c��y&V���˭���}�˚VLо�3���0ͼ^�K��3�����7�]�=t��X�G�T��&/uI&�K��7�L(�y�Z�I]Sw� �'�"MD�w�x e��,��������E�(���q=���{�->�C#�z���;7K��2�)a�?��ܿ?�n�9W�Q�40]���A��vc[_
�Σm̥)�꛹��Ӽd��<�݌�^|�6��:��7��ۃ$t�ei4��V�+��(O�����Qg�*�s뷂8���t��/B�cr��/x9^sC<�A`��RU����ec(4�V�mD�sـ?T����C+O�
�
+�{�>.RcM?l�
�?��ی}��jJk5��7���A=0hv!;��⺌�'��Hs)e�ol-bWPp�Qǌ���x�N�N���ľH/?�'O���,>}��_WR�y)�2��� י����Xw�B�Ү&b�ŏt�sI���3Q�����Č��5�6	��A�gj赓~�ؒ������c�*����{�_<ƒ7� (llT�0�]��r�
Z�5�U�i��u!�ɪ����9����|�j�i�u�'$;lfť��AF#%����.�dt9��/'�F���k�=�'�W�I�OӮ�>l�M,,}rt�k�B����LBh�o�Z�*��4��qz嫞lN�XX{�K)}���Kt�M�p�y>��|ޚ���n��ك� �I�6�ŧ�k{�����4>����Nk�&������S^�B���}��㦬� g�V�
N����P� 3gz� V��F3� 7��2��j��U�e�T�T�*��?��Wj efQc��pV�Q%���]]:��x8�j��#B�H��<x�T�'�u���Q�)"�m?�I�6܂���(���++����Ȼ��l��za$��j�&5ӧ�yog����o{��o}����;Ho�������A 3΃�U��J��x�՟�&��[�]X�h   J���#� ����dep��g�    YZ