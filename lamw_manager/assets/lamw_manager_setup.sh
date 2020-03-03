#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1284224153"
MD5="123ec13ea22e715c4b9eb89c4d360935"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20676"
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
	echo Date of packaging: Tue Mar  3 16:56:04 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j��2X^����\�
]M�:G��o|�Q�GNM!^�Z�R�}�"Õ��\���iE�+�N�^�6�ۯ�F����K$y�jр���rp^�uu+�1G��=a�"���	��k�[&�u�y8!vu"r�������C�a��)-�T)Q�21wi?�U[ۖ��W��9K�Wx�~PNQ�el�gV���� ��EfŦ��$�]�c{�$��^�柌��<`����-&o}h��a^��s���>�K�t���֐Ւ"{
���x�-ղ�
�S�Ŭz	YlɆ�R/�"'Et�k�t{=��i���AFQ�
G��'�'z�%���r�pROD3�G�_�,o>92��<[-3���/L6����3]U�4�=l����k���Lſ��a��{V0��n��nǜ�wz�`'G]S�~3����k �&�$̠�M>��V��&� ټ�qZ�\WO�����^z��N%�M�Ӎ>=beJ�p�Q���k�E�6`?f�0	җ��fx��خ�"�c�E������i�늑�1_��g*��6I�O����#.�F�[����_���1��YЭF�� �����d}�1�)\�cGg�m޷�PM'�R��5c2	���c����$��y���7L�d��j�R��y�t��D ���f�uA��1 �s)hN�u`�Gȣ 9vkkKk��|n�T?�����#]�zn�Є���:Me����s���,@��?������WR#�R`���P H�`���o�*p�PJk���'��܁j�u�c�k�X����	�pg,u{���6�,&|�,)��X�/s�x��hxS���2����f���5�U՟�� �	[l����tI5	9_o�����?z4�.uORz�ŉ� #��Ew�Y�±vB��D�����-�ŷqT��8��@���wC�eF"/
=����d:��1���@X8�� g1]����QI/��+@-���s�m�%ᇢ,�y�/�j��2-��������'6H�Y����u[qwB�;�Ulf�3R�e"�fiů(lW���1�<b���}Y�8��#R�	�,;���6� S_*��k�ֈ���V�v2P���Jdi�-n�������䖸yf}X��U���B�r���2B�h���ڿ���	Rc�K۹�3��F�g��P��`����h���+?���{��e6[.��E��d?���jG����)$=A�9����)�&x�N�����b��k�d˄��2+y������j�Gw3k|B�PT0����7:�K ��B!f�Bκs�0DDRc�l:R�oq?|i��]��)�U���о��aR�l�������������y��&��в���F���(�t�W�6O��A�K]���>���3���2�:�z���n2�ûr�~29f�>���,8�g�7X��l�ֻ�E�;���h/8������NGE�l9.y�Wf������/�.�W���Q�6(k���.�JA�\�����T�ǳ��H;`*u��Hh��e(Ն�g�)�����w�M��NmD�cE���fݤE#�˒c~,�[�z �'� 3u8qp~(�X�����lJ�.]�р��:�O{��z����)�g�9a5�6�H8��GeiVH��AlӛƜ�:��4���MD��o�a��r��/��@�R�v,���<[1�$�*��c����R�J���#�W�߲' lM�����c�؛�(�a��Ȼ��0��]�j�]o��9��jD}�J؀0&��B�$�\-�s�r�d�HT�ƜH��E�{7����H�잗�,��^pR�Ƹmf��}���7����n	L��r���項�6g�V�T�A7�en6�⿻�(e����q��^�uLg��	�>չ�����SN���am����5�m7",����yr����Z{�o�z<+BG,���a>���+�X\>MH�A'�j(���VS�O�rT����z-H� �n�/e��?LFm8~�;��d�� ÷n�]u8}��4A��'Hk[R��#Pk��,�*YIL���
5ŋQـױ
���U�!��l�0����]C�a?�(��'�K���Q��#F�_ ��H���1#w-s���z����c����M!��4m\m���&I�GFQ�̺�j��!4Ak�k:U��R���R3b������@�hJ,�R�Ԫu$�l��F�GE�`�Q��ns/`����+�?΂#M�0�Uѝs�2;��7}�\^7ioV��s�H�:��?����sS���`��OPӖ�"oX�aE�4W
C�H'�Ԋ\7�B� X��C���)@�x�ǳr1�#��ޞp���|�	-J��Y���q&%�]����J�&�LT~��M��>Q=���&��nC��'愰��� ݧw��Xl �������ڝj�䛌�TU�����4����ehvZ|��@���sM[��]j���M�K�jğ� )c{z�s������I��/u&�
=U�S$Y�B�I�C��w8᮷��ۏCc�f�Y��	;�ί������}���j�\B`Չ�@�B�����ht�@�<�gف����f��0�^�5ʜA/_E�����T%w�YP�]��gY@?��
m��TP����bׄ�N��+E�A�J�UQxda�\Z�� ��C@
�rɒV����Z�d��ÿ#��\����@YƯ����D`�k4��]�[5����ƻ��wxMaj2j�:l��QQ��U#~ʻY�K�Y��
�L���p�᧽�����t.(�Lj�NޓO]��ڗ'C0Fi��f�����WG9P��*e��L�KQ��>��"�;�Bb�ʢ$#�IC5
<�l!��!�o�׸#��ؔ���fj��X9��/{��C\��(1#$-�׍�(�\{��(vs�}K��L��Ӭf�j	�y��ۢ{-�=�͉�AM0攂�4k��A��2�^�V-���<x���:���W����dV_�P'-W�)�q)oS�!�5����F������֗2ˁP[Ɗ"�;��C�U����i�#Ӊ�{L>3�>�^�5��k%��1���Uǘ��3���M�Z�Ʃ�b-d�ט���� �-~�b;k�q\�5J���ˑp	�U	��y���ɡ�\�vuǸXM��wes�ײ(�y�Ajq�qG7إ�ەx-r]^<R�Y������x4����U�"�r��(8�
��y�5�[Ιc?I�����!-����x*j�ĹC��mJ*����Sn�6m�H�x�9m߼6�p��7!%aY�U���iA���W��i�N֐��� ��͌<bڎ�b�m�5�$3^�k���r�4�z���\a뮱0}]�A����DE���j��_v�f���[�{0��ֆ�FZ�h��>�wnOE�������[Ӆ׭��b�n����7�#���PA��+�	��G���(��	0�0��7����
�j���?Zγ����dvbfC�B��H��� �hA������k�S�8ŧc�#%�?v��~�D�L�S8;�zh�r'�g^�C�@]_y����g �ml���z�Y��:$���0%ĹRz���rT@�V�Dt?�� |O�gT����c
��.���@�3V��a���z_�&��0��-�Ӿ<C+j���Mj@jA��\��z9Y�R+s�H���reT9*V�[q���Q]s��lf�²�zpB��M� ��w�@ Xr�`O��pT[ ���g�|��h���vH����2[u���cG��
��I��/+4��ڢ�,���H`��rէ��7(c�k�U�t<�C�dk������࣋Q������K�Ո7ymlS�4��NN�g`a��HeV�n�`k*�J��!��l��f�P��cA����6D�h'�z5��`o-e���-�ݼ`- z���Q��[D�[/"��9��Z��M�vJ��P~�d�ɳ+^�U�_ ��Ő���?M��>RC4��{x�L�b��`�t�`um30��j8ܶ
v�MJ&�p�1��8�i��o2�".~H��|��d�/S ��_d���WF���2�$���Qk��=��{q�*(yꁖ��htx��\>)��׮��Z���s����ۋuqS<�j��no�vu��/�E���_9�So��H/����sҩ+ O�t�������`�Ui�w�=-W�L����=��I��1��LJ��騼Y���Д�s\Y>K�?TֹJ,5�$2YY-A�ӟ�U[��b���	3��6Z��;1�q���
����I���!��H$�#Jd���S����Z�h-'�#�e�w�	�����#D^e�]�9'�rȶ��2z���7���5�]��*,R�]2m�lA��ͳ�Д�Fq���y��Z|�=[���e���U�<����܇uG�oK��� �_�W��[�bb�c����^.�2Ti�9�5fP�6�8��-��à�g�	|�S��}u�*�3�[�3�+3\x7�	[�CI�Y�L��F��!8�0�\a?C�@�5W����ǒ�M�"=6� "�>R���W�K�����ё�tr�������8�Cs�G�;��ٿ7�|^ ��E���^�$e�}�)(Dd���ψۯh �#�>XҬ��O��R��k��a#I���I�J~�dwt`E�c�N
�3B����� ߸H|��TU��jV�v#�����>��Kׄ��9�.��fM���ރw���P�N��f���w��{p�ɧU�3��p�G�J~%ơ�	܌��
�����߈�����%|:�#N�q+�	(,)�Ba�∋��wx���,�-k�}.\��JP �o=-9�L%����f�}��0�֍+�1��p�����Ӥ�j�DN��S-��VY���.:�l$�s��2��Q�&���*;Y���8p8���]T�����H[]�x���ނ繌+1G�G%_pa�X��oґFB��R	���P���$�᥌F�j���+>D�K4<��q��l���kʩ2����T�)��>"~��A�ΥiM`���ſ>K��@�E���s���_�hv-(�'#�fI횾�a4l��\ܩA�*��&JeJ�=d%x�9�7r���Y��ɓ#� �M�4��qGC���"5�ܻ�7����_��$�Z�<���t�xd�L�A��a���(�g�ד��82���2����К�-���'˯>��Ju��m�i�)�� ���J���:����[��>�uTk��3T�J�.N$^���ס�+�V�,Vv��w������F.��v����*)�>yΠ�@-y�)��̑�^�7G�Kz�1)��C��?D�D�ڟ��,�������ϳ.3�G�Pj@�o�R;����!�P/����E��)x����:j�s�quG9ie`�D>�%�{�d�G�1�)����v�OIe�#�B	�U$h����,���^�ن�u���+kdc����4c[�M���OY�����v���dM�;�����ʒ��3������ o�D�C~�~_��ߣ�3�c�y��V��Zy����)AN؊�����ь<��iJ!���A	��l���:�Q���7���)]$ŝOn��E��}�"��ċ����#�8^]���%O�>�0�����|�Z.���6��M>+V��`������j���%g}�6�'���Om�<6"�X��)�i��Z=i�"y�-���x�FI2���\0��ڶ���y�h�Ҵ�8p̳0v���aic��!Ms�E����l3�b�����*r���KL��m�z5s�䛂��3jtv�9"3�i���ۃi_�1������aé����|�,�D'���^���vPGg�׌�2h|��{�[�۬����)]������I"��g�6�ܷ[B�#F�R:��6�C��o~P�t�����m�������,���@��=������ m��JY<�p��q�4y� �t��
�������Ѣ���/��"�N4tԜKA��~Z�O�hDD�g�"���S������0/j��;r�<�с/֬'G(���BŰ�4�h�<:��c�/�e�t��?�]X��cH�J~+\��GxM��!f|������L+�� �9c�'�f=N����(��h?��S�ڬxP��o Sg�����@V�������u�?�#T	];��dkx)����� s��^q��=���1X^�C�5�<0@�gBx�f�k���!�VS��M3=1�*Pt�*x��*;j?Z���]*���&�%�t��h��
}b�>I���4�l9�D9�0�D�d�@E�(���E]�2_g��H�����H&N�/Ap�i��x�y���_P��l�b��9$c��)��M�w)4���`r�w2��.�L� ����#���h`Cfgfiu����n4Y�&bf ��9[�<��q��9��<��1�-�0�����<@ ��Y�2���F1N[���!&�1v����dX� +�kO�o����m�;^h>}��r_���}�.n�n��S1�k�n�vWL��t�[3i,Q�9ƨ��>�����6C5���{�?�+E-ju �1��QQ���Ͻ��^�����WF�����<:q/�=�<�;����^��Y�"2\u��1�������pt_f_��&f�IP�������x0"*�e�d��Z�W��w�+Nr�>��풘��S>rE�� ���^��v��BJ��9~�7)@��f���q?��x���+����f6l\��bF=���ئ8�%�HKb��TFu��p��Co��_���nW�Lv�:�I,Q۬B�\���� �F�m��1�5�ɡ������@:\1��-6�/�S�ڿ��GH������gNK%�����`��|���\4����9J���}g
�y4�=�ßc����+_�	�Z+�ށq��Q����-��z��J��me�d�k�A�L���S���/��Z�V�*`����x�Kp�����B�Ӭ���E����?NI��I�}7��i;�s1�K�©*�@+Bs�,�o�!����憔�E�>�1L�ɥ��Y���g(x���vȺ�sh��j!i�p�&s�;.��!2G[�oQک��{ ���}�&����I�evF�iĒ#V	/�z#�����W��'.sd =H��u��rj��dG�n����j��S�+�k�ɮF��y�d�>�+M�S-��Ǘ�&Z乧�N�r���t��ާJ���L����uc�9����>Qۄ7hNZS���Is'E�/8]��~LX>Q���g�ǶK�,}�6�H�v@bI#��W��PT=�ڀm���]�ks���9t
���NG�  '��:�`���M���IK�%��i9�w��2�'j.�vbS�~��Qb���M1���1Ƚ>k�V�]0��ke+3u����̨�^>��d���4�e���Fx.Mq�8�r
5v#�L�3�������b>rK���Y���y��I��D��|{Ő������&��sȯ䖂�q��)=�=H����E�%d�xI��e>��
t�<X��$f�iG߫��A����=Z��)� �.�o�+����w�B�Z��b%�8����~��ǔ|o�*3�2"�y��{�A6�v90��(�&�O��[�r}��iU.@�dq	�y����R��uN0]7rY~|�ӐU�"�e�!��}�v�R�� (�����=���J�üWHž1����	yK�&�gV;kW8���t�+)�k.ʠ:�4f�8����r��L&�+;6�ف)��?���(S��) "	�$���pX���񍳗�x���)ilc.f�_U-!DO��i��p�8D�� k�(���4�R0#�ƪ_$�ԉ�Gv|{hE��7������HD����)3q��[��/Ҽ�~A��{��yG~�S-��P|��tE�^E����+$P�]_?����޸�����v�����d8��RoU�̶�<P������8���n^����Z}~u8����)�/�@�VE�_'e�]K�HTq�v�N/��x����j��st����1�L8�#S;3|�9Vz>e�1L��Q`��a�G�G��sx��7�p8�W(T$7�e��WTƍ��y�j�}�*h�.o4,3����Q�w^�V���s��4w$����,*�L)\��;�m�֢]�v�b6@^�D���c;@M�^��W��=[��Ơ[i�\�C]�Ujf'x�&k�dF;��]�;t*����q�W�"��sX�8�OY�8�����g`ɻ��(�����GVT8"tt �)`#��,�	\��埿(РcSm���[�����0~���0�8�G��w��x�0s̠����YkL�U�"}�&y�3'c7���`;��kI��gۯ�a.-�X.�^�硄ֿAP
����TLzV���Gr�� �TP���.��E�&X��/,O�++>��{�]%Ͱr�!�b�G\�e��+����r#�
x"�t��3�^�]=�
�Zr��f��[��<��[�[��jmO����^���qC�{>@��bd� ��՜,:90�Wh`��� Q�	\���*�g@������b~0���wN���ux���֝i��A�4����8�ϑ�
�Z��4��f�`VOU��y�f��4	�5PMx�*\װ���f�K]���%z*�i��c���$k �dѺÿ7$p�n���
8Y�����i) ؙ�崸�a28"����l�A�41��Ć���Zy���C��+p�G�Pc�@} �P�D���sa$�E''�ae�O�Q�(�a5��� MKiv?��^Fn�a������)�&P���`$G}E���U9�������dHX�-ް*�EL���\FZ u���>O0�ۤ�����Zx�v������H���I�~h4n���}5��l,�M�\0�J;i9���M40$;�t��Y���Z�8��n8��\�tی��>?�����}?�J-�h+� t����F_�x�bu�×1�2��i���घc������R��t�l��xa��Z˙.w-�sx��[?�����8�ٳ���;��G���1f�d�kB洔��akZ׏U�[���ҘhKB#n��'h�t�a]��`��Y�$��+�`v^h�N�(�T�j��9v`3��nf���=����bi~%(�ϾI0ķ�!/<�bО���2t}�u?4@��E��)P��/�?��k}[ �����/�5��^8����f<B�B��O�, EԺ�"�D�<�_oŵ����U��<
�|D�r��4^�̥�\�)~����������%�]��͇T�ʟ���z���V(�A�V	ۀ#���6?�� !Y�lAl� 2&~�j2
RB����"Ov����J����Y"�ؒ�����ٝ�.�)���e<4 `C�#��4r��%�uǆT��9���1Π�7@*�8i�?�3b5�P#ݤ�d�H�Ɲ�YF�Q<�N���V
j�fȱy�r�o�[�K�P�I[��>��C^O�k8	�f�>��_=��l�+}п%�x�.������
��C������d�t�u��)�tږ�=�vƯ�^ƗFT[�JS��brƫ��I/?���d�]d��@�9�Y��y`��p�6B�M��]5���AE�ngNq��Ut�5Q�!nv�� �A�-��ǫI���o�����0��� ��Bc9pD�h����$�v��~�"z�*��g�A�`��a鈲�H3�v��#�L�=��g��E���:x唑��«1�V~	�a: �w�16wl���޸�U���#��t��ʼ�^@�G��^f�Ԩ$m���b�?���\���v;��щ�	z>���'�(G���\�q�ڹ�����{�c"�<��t���Bc�#_*��̡�_�����n�!*�
�%�j�X'b�İ.ʳd-���i],��g�l�{��-k�U����H��e�I�5,��(X�`@��y�L0(�����H�C�̓�vd7���z�� ��\Y#��zE�|,1'�7�������s��.��MIMU�[��H�D��{UH�ӐBf�`�5$� 9)c��Ո~
��b�~:�9��M��ͧ�3�����%�c~|	^��T����C����5�Ӭbl@�N2��7���.V-�lZI���n:�E��0|޲=�u��;��|���oR���M�EE �B�Dw$~��5qK�Á����KrB%�&�=G��.��}��h��ҷ[ ��	KG������q$��<�~R�jg�)Fd��.^���s�X��+�S�ŪP� �/��Ru	��;8.�RU�3����Fsv�}-���N>��i������qn�J�B��l���4S�ώ�=ux)��Vu4}�c��8;`�ŉ��.-CB�=Uc�c�5��s�"��Q�����ף��(�ȎZ�(=mo�q+ �e�m�}OC��L���~�j��߇u��۷t|���\3�qz�ܴ�Wj�Y|q_�i֞��[ �$/i����_[[��Q�����,yU�z�TF��[������(�1Ѕ�%O��U;���2��?�M6����PY��4��Q��Ч�-؉=���ۮAud<�����Ax4�d�%�������jʬM;d̲IL����w�0��
A�	�u�"w9�~�O�퀙L����f��o�(T��ؽ!�W��s5�퉬V	�'ͦ�>=y4�
$�}7��I*�d�bxm��?S�x1N����7�$�sS��u{��e����J���8t�_��1..b]�������L��L�����>���)J�R��#v�]:�F���a�����F��O�~SV��,�t��z ��d9�H�p2�yy�2�k
BĮ�X��Ut	���㡱�j��-v��}��9ő.���K����Ia�dW�;�_��B�K�s1_�'�Z�����o�!2&��-G�c�l�&�c�?@��D/c�0#�0������kFfz�EnS�:�o\ȵ]��c�-�0.�۩9K�9�ŧ� (&Ǵ<R��{Q�2�(F��y�|��u51Z��7",$��O�+��$����n��m���N+���{��Jy��2Sf,1|}?�@8�=�QI���z�����-$%�q��*tr�a$
�� J��C�����JΓ�Y~�׊�i�?V��u�w�G�&��m�]ȪxC�2H"��aVQ�S�;?����GliC�([:�P��C�7E��ZH���B��-�+m��Ŕ����i�x�`�p.�~��v|��	N[�� 42����l����l"��, �G\�D�ݦv����"�b�?�J!��x3�R�84�0⌉WG�p�7�x�c[��u���}�~D��1�Trw�>@M��Ƥ$��zQX�>P�)�!�u��թ�.�c�_|��S�D+,|������Rah/X.�/�z����E�e6.��M�2�~�s�-T�L8���4Fշ�[Kf���f^�|t(~*Wf0����;q;�]�H�Y
��@Z��s��n��9�]X�=��3���/�+גO����?q�#��������oAײ'�x�K�E���M�Ŷ��G.u��a�m�TA7>�s�^�%��F%�tm�5�b��B#�ˮλ�������WeL���L'�уϡ55�6�Y}�]�B�>$��K��7#��W)�U�Ov�t)�$����F��k�����x�N��P4���s��>���'cE�5��M�e�Fx�阪T1���Φ;���H��"���R,��Ͻ�$�+�lm����lJc��LU�q������x��5ьV\�Q?��}BVB2|SЏ����b���mȿX��ϐ�"�9�<m�F0������Ì�A�q�ɼ��b`5���|}�bmn��M�;��C�_/A6�3%Ĵ�f�u��fY&Ej���#��o�ͧQu.)��:�Q@XK��X�˔���=QF�Ù�4�G
 ^v/#���3�N�#H,A)�KW���'������'cN����l��o�PrH����yGz}���~���c'�	�lp���`�HO����󨵲�=_"�V����Y�{&ݖ�$�{��P]�;s:� �ڎ\z'���ۡ�V2��Ѝ���j�$0�i�L�I��tt)����
P`��H6���� qF��"6g���)�O�9��XU/4禷�d�a��7`��=�AD�D�2#���[� �a�ۆ���rCu�.mJdI����Y�����V���,6<
û:�,�V�z�6w�nΌnSU6�0�b��.@�|lV/6&-�3_թ��
gt��$v����7��}pvW��}XPX=���|,x�S���P&̀�l�/�QB?Y�E�����8w2H�E�4Ũ�ͬ��7h�5ͭ��������I���*q8��*�q+�4���L�$���j�r8l"���e��_���Af��8��pҍ��q�,s��C>9#]���տ�
���G�&�l?E�j��4uں�A*�<>˨�#���2gphx�A��X�rs-�[������蓺�{��<ڀq���Q#����0���g�R~;tA�J����\��nJ�P�V&��?U�,��,�' p��E��_��Z��l�r)dBe�F%�Kqf%w|e�,��!���4��	�f���4�1���T���L�İn�DZ���د�l�:��m;�N��e��$��Y��EK�^�O���^��t�_�m���v����'Q�W��e'�g�6������B^#�TD<��ܑU2}r7tM����9�;�I��䎿��'i�t �{��H�M8�pJ8l��_w�+��� .���R*��D�����	P���V\���E����|��k3��l��t"5��RfJM��R{�rL�X����i�ȑx@�nxT�>Bǚ/R�!�����>͖|�;�R�5EX$���G���ӈ�&~�b�5��m58'7(p'7�yf��eu��-ڝ�����;�	|�7�(�d5�|P��ԵL���`u�oOV��uc��P��W1ǾZ��c��DŸثu+Zj�$L�$�ː�ߚ� {}�Z�o�&���Y��W�7?�G[��'�!DpntI|�q`L�0c��g�>��e������'�\&����	�}Kf7��)�n��AvG����U�?+�ˊ�:�(KJ�(߲��[��Ǉ
�������� F�Y��X5�mEw��(m-��nd z?�������hv;���#���`t��tI�n�>L��xOW��	��!l���a�����;�� &��J@6h�)�/���>�%�)u���9{o�-��l��Z%��ǶO���nW�@)�۾5��<��n��0�Ē)Ou]Ti��:=n�jxăC'<Ҥ�Ȩ���N��ִ�#����SJ5��@�axh����e|���Y���|����N5�}����Q03�h�P���J�����(�fɀ�3[ju��1OO��h��v���Ѻ��b��ޥ�kp��G�Sq�ݩ��u^�D�愂I9\:�p42D�%N�+���|���?�F��|�͗�M�\�%T&�;P~�[�@ǴÃ8�:��y�2��d@/�����јB߇�=DHp��@����+��|��͞�j�7��Jbn��>>�p�0+;�jmS(���+ ��Dlwc*��'�d7?\D�T�E��h,M>o��ā��5�BqPk����ŗ����~�{��6/1{!�!�ɵ(jO�Qo�l��=�H*^��Ӱ6X�&��]��4r�*���I�yF�J�ͻ��nl~|�z&G��.�-;4�p�l�[6r:��ߧsڐ�r��\o'�	|/�q:�O�D�z���J%ƛ�H,�2S-���|/�3o�U\�g�l�F9V��^RD>O�����_��;c�7Y�x��	d�w�}	K\�7	�YJ&:Q�z�q{]��� �ґ�_�Ϫ�H�W� 1��0\�g���������/�i���pc ŏiU��Ͷ���b�Q���F��x�X��9_��yJJF�=��o�5�!a><���t�hD��׆���ܛݍaA���'�,�O0��'}��b&l��
2���b�m��L[�:* r�>c�D3.�C�[�ӰϷC�h����sԳɽ�ȖO-(Q� ��R�bU���wB���Q�G��㩊j��o#���J��߱7��S�e]]�ԏp�[�qLO���U;��E�6Q�PT�X��-����D�k>��4a�B��(,�pNh�Q��>�s�0��X�W�]ݟm���k/��M+���γ��ꟁ�Q�$ٖ)������fd�@�xv��.���S�S���V�O�]�<��<�$��(6���B�Qn��Iv�^�z�F\'+�/���ɴ��H�c��9=�E�W�xӪ_y�UT��"@�Ɠf�O�rX��F�MQ{w�kׁ΋���Da��xS6��{�7�8{%��
m
8ڊ]j	4M��b��<�B��̗w*��O��WoAf':.�W��W��FdW{��<�qn7"3Q�C�X��\��
���v9�m��'�1�k�d|Hģs��3��:#@T G�{6X�mcRI��}d%�ſ}b�GTntk��Y���B�Ɠ��dl�
��!>��W���Z���ierԌ}��C�J��B�2�a�e,��2�5�*c�աi�1 �؇�$/Fv���Y���\�~�a�5m���jT�È������u��Um#�4�좞Z��	� j��1�� /����a"���(�_�(�GJ�^G��OdC�Dm�*Gr���DnVR�뱜�S��d%��@v �T�j��ܹ9��:��%��iik�����'�O��XSE�6c����;�򰧓ޯGX�J ������*3="��o���7��
�V�}s(�ܺ�09S5GR���g:�֕�s��Fޗ��Iu�h�ɴD<X2�צx�!��\�A��%���4�,��=f��p$o�p9d����mmjF��(v����ͨ� ����e�:�K�4v�T5f��C�e;�C��-�N��a���<3f�V���?����u��5F�1F� �3g̻N�Q�ܐ7��f�i	�|;�OC�e�cV��CٔP&�Z��GAdHs���=| _��B�E����A��/�=�����͡�O���{*ќ���d��v�r�il���g��h�y&P�f���:;�,�e)J�iZ޵Q���2�\�˷����7^a,�y��<�Sm����T�&���[�@�Gp��Y^z�A�P�v0<<r�&!����:�6���l�H�r}�`t;�I\͟*�' ��!��L���S�r;-�@��?)lO|Ӏf8]0YB��l��H9��C7K$��d��
��Z���%u�ۅ|g�9����u�q)��Kn�Cz�R^xKǠ2��� #��RZ�F��\xU�����3|�,�D�f����ܐ��O���b��υ�丨�?A#,�Z��������3�����E�(��6�i�F��c��
���6L=us�
�0Ȏ�Sa+�3��6j�تercg���<=���=s�[�5�F�i�>d.}S賖�r������P��ɢ`�1�S. �l�� J��G�=���җ����r��ln��Fwꅄ�.����VU�7O6�<����{��M:ȹ�+���v�� \��
���n�8��GDE*�.��S/�sɂ��R߽��Y-��%HLvV��-	S�%�e}k+/C||ӋO��!����� m���X7�9q�"ǬE��j٩�u�i��G/cIt���3o4��$�x.��\�"�%� �9.��s�Q<t!K,�Y���w���Ѷ�U�.�]�c��	��ꔖ5f�MMf���M
�eF���s�kP*��G8i��%�	U;��3�H�O���m��˖3.W��Dk�2��a�#�7Wf����ִb̋��>B٩6�qĴ&E�_�-��p=�Lxu<m���*��ņR�q����A��ץS^���Rit����>��I仇�ʤR�?J(�;ʎ��Q"�gK�f�&�js'���!�s	��H�T�b)1)�1��%'D����bC`dY��,��l �ĉwa��0Jy�[8H�}� �����`��������L�D��=�E�I�%�K���#��'������ ���xHk�;��w9�a��<��k��(y���C��t*�p��8�P;�FZ�J�t%X��|�y=��JB��	��vĢ\M���5Q�HB
�I����&����8�����/�qy�R�Iwԕ���0���)pOk�|�'�	w��t%�û��_C�y
*a��1�B�����]7��~�fඅ-�1<*R��Dȗt�j�
w!Q:'�tW��5;���hkg��[�Vw�����.�e^�����"˙���#���R��N	������:}0�଻�FPJ��j�M��l�}�ދ�gz܌��i	e��Fr�G|�s�%��^	l��w�R��k�G1����
X#1V��-q���aǉ
�:����Rm}��}���<�V\'�2Nf.j��c��� ���n�*�M?W���+�qt�S2�y�(E��h�~���@8���^��'C��61orM�8��Nf�<N�zѳ�Rqa�0�{E���������QL�7�5�¥c Ǳ:�yl�8w�N�g�"�y!B^�E�����SZ���F�hDѷ��i����hݷ]iL��ЮH��d�~��]|!��;)�+4j����	���O8�����տ��hy�5˲��x������n,V��0+�Z�ޣ�B�w;XJ#��Q��s�<8���i��L�P��z�>s^\�tJ�_�9_$�T�#�H��0k��(Hσ	b_�Ҟ�����y �4~���$`��K�/?��e���x%���c�0�(]\&o��bw��i��}��R�j��\��-�KJc�}�!�B8:�ײOҭ#����le��/�� S#��Z�U���ن�a�۱@^Ț����f$�}p_�	h|	�k��M��e$tKH*�'�1Ǯٷ,�Kx�l;w'���?|
/�w��89IW?t#�ýh_�R:dr�dSO� q��CP�^�dgDj�S'��Y��BӶN`(Ĺ��~�̸�yO�G�C�v>~d����,J*;�(.P�:]V�.�eGr��xsd0#x� g�S{��5I�ͫ:n� ��ۄ�Cq�:��r���@6�5���<�d[I�d�:��[D�G`�u��(�ѷ����q��[ӛ�TV���$��`ArkX�l/�ȁ5�X2^f� p)Q�ٔ�:Vԕ�Y��j~�x9��?�yj����"��D+����^�)k�0���M�
��� ��<P��(�˄❂J��������M{W w�=�[��e-T��/�q�G�x��Xy�>��1U�K��x��0���]���{�2U��PN����J`�����3-l>��3�j��jH��E"X�,�-�I�����r�����L!|P�:E�6WN�Jz�xs��"d& ��ʢyǒ٘3.��Փ�&/���Z<j�ݐ���BI�7�x����a�e���)'��������U~����c��������w��-ݞ3�a�;�Y�B��	O�F���s��!���K�CdE�:@�!�����>Q[��4�{n��4q.��h^�O<�����wP�	U�@WܻX �uv=�l�U+�_����x{������攻&?�w�=�����)|-�t �"Nr��	"��aѦ�*9&��֩2�����c��Jo7�����:�����)}���~(Ć��������ҥ\ُ�]�S�I<��5%���q��v��dZ���{^�)�UƏL�Q{
iE+�y������R?�l4�k�����j�����P�>K3����[␿{�@�W��ms���p��حѐ ӆR�=����1�X�J�����١6ն&C�Yn�.��D�����|�?JC�|��E矙S��/U���s����P�ʍ�;;���!�S=pM��ƴ2����@�$�؏M�D�-�{����i�p��ֶ�r|K����W�y����}&J�c�-�d��U�G���P��z�aI�=R����lZ�P%��H_MA�.��aY�|`@��������GM0��Q��?�@|�b���K�O
M���<۰��6�
(w�B%'�y��L�@5L�\�\en�7�<w�k;wr�ϴ�h�j�p<�hyW�4��3�e��A=�UG��T����So٨}"�>�0�ܐ{S��3׳�yڙ�����Ƙ��f�Y��٣~�;t��3#��_��Ƶ=B�J:�����I�=�<pv`���H��+d̠��vk1�*ұ��>��Sqt���.o|O3�u����&G�D�����V�	�L����R��8��k
�Tc��s���h[��跇h�V�\�s��p��[�v�҄MdY�bT��"�3��ވ�Z���4J	�v���/ok^쓺��/��2W/�L��_�@�Ix��ASB�Rd"�t�A�-t�z��'h4T2�ӹ�n��'7��Ǵ��\�eD4 {�M$�A����)��A�����D�K�$��=&�a�5hn��UQX}���6��	�~|Y��{����m��?_��O�iR�τ���8���غ�}�s6Z�9vop�O �k1�]:n�%�h`�C�{�s$�U��7#a�����CX-+}�J�?�9����$c���w#�~��ʊ��DM���C�jR��A�G�жz^l��"Z�Ro5���u�}g���*�:�\*o�?:�h�֤ei�=�Y�|qoҜ����Y�� �O��]	�3�R=G9�!E�����U�C�xcо����Ѕ�#���� M�]o��d_�a��Pqx�X����v��"ܸeO�'@�m��j��T���
{��(��L߃�t����r�������\xx)V�;�DW���#���\���01{)��T���{�b��K�B�߄>]M��r�Vۻ{�j�)��ZT&�}@8��eFl���j��v�,/��n���;�b�9#;���q(~��=F�E�V���΃@��EXIn�H%�f��\��A:�Ш�+�wm�n�S�;��%����D�s��m��h�(�aT�ɪXD��J�x��DC:"�$ヮY�{�+8�Z��MC������M	�;!a�n/��²�3q�t���5�����L�l�Qdl��&?�5Gg������9�JyҬ���#U�|KE���p�8�|�~F� ��b���[�s[��� �|9�t �<!�l�=��b���0Y�f�f�|Ɛ��[�xH�f�M4�:�Fj/���-�gSk�,�/	X�#�� ACp������T[�FL��\���X�D�	���� �1��C�~T���T�'2l��Zk���\(�?�#urz�,O8�S��_�|�6���ǚG0�	x]�H�k�Ӫ�A�w�"��[؆��N��Rty'§����0��Ws��hNسU �kP�ȐR����@����\\2��,�&O3\썅׶Y��̬��p<�F���jr�I��P��W5�ߜH������g������l
�
���{o~[�R�y~��3L�b�`p.|St�>Ӱ��&z� �DT��n��'�FL�<�'L�#$OH�X2�  }sڧxyr`A�B����{dm�"�/)Pv@�B[*�ZԽW�!f��ǰ\t��0�ط�/1�(���L1��s�i��)]�{Q�ܥ����̓$��x����7��G��(<x���[�~���r���F�̻��Me2�%
c"K�)gFz����,����e�;H(�;�^D���2>�>�&�!��Y�_�ʮ��E@��Ǿ)М�;�kv�&�
����#,	��IK�Led,sbn��TPx9�Ɇ,k\��ş��j�x'����*6�FOqVu���s#��EEY'�痸"�L>	=m��}[[�D�{") ���ȸ���V,���g3j�虵)��4\f�_�-*a^U�F<�l���f�mSE��,�5&�~�\�l�����������{�r��.�V�V�p�R2�p��̬��?�
+�����ǒ܏�� ��twV�H�����p�!;�`���$f]�V�-<vk�`��b�(I�#�;'	`����D� �R����,���Ze"Я��(���`*Ξr��x)��6�����!����|�`������G�����ҳE�O[3�ۺ~�-�5N��Qf���UI�qdO|�(ō�{���y��N���ڛ��    	�" ��> ����T��|��g�    YZ