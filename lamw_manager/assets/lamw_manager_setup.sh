#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4189614374"
MD5="ae65b54725eaea9ddc8bcbedd3f8e5e0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23880"
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
	echo Date of packaging: Sun Aug  8 01:41:35 -03 2021
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
�7zXZ  �ִF !   �X����]] �}��1Dd]����P�t�D���pr�p���e�٧L��"��BПU?@��6H[�9����'s�W�>��`)���$�I(�������v��y��n���\&��<��Zʐ��@/Æ6Nv�}�gL9�9q>��?���M�/�6,��Ӕ��_C�ܣ��v">��! `)�j+\�,6�%�f��|�ӥ#�ݟ �[��^�E�rx�v�*��Upw�L#�j���������3VT%�(*n>#�a��Z;ơr'��4��٘]CGC'a��	@̤�8�y�}�+��wV��ANU]
.AY�R)�n{�li��E�FZ��<�V^�6���W;M7|zx�Iש�E�ƇxM�6�x�� Y]A�ZhQ�n�"6�:rܖ�6��P�9QEm"^�����w�{ųG��<�NF){4�Y�-��,֞m�|�s_��,^먈��>6����DL�$'�h{�ոx�F�����;v�ƱvzN������ɘxw�{M���FI�sui��Z����@x����� O!A}3�-��l*�)p�rx��^E�pm0��`>�Xg�߁C�Y�t�.�<�'gc��F��&6����MF,_N���Wu�}2��'�����t��K1Y�U��s9��˱ň$�饏sz]bh�W�<�rԎ��;�݅�>�U�)G>؞+�r ��op����iF������8��E+����y�Հ�	a�6��3X����b��7n�!� �D�k�t�k���p-AF���M �����{�1����7�&�0o��vf�_�TF'��|�ed,���j{�#��
�w��<���0,�a���u��t��R�J�J�!�2��_��W�t��H�/��+��팭�3���bXn��y���рQ�x�@YƂ���;e-�u��W�Aʹ`��̔H���y񦹍�8�⣀RK��V,��1��h.�-������ ���1�7g>��D����a���F/���Jj߁LԖ���^X��)�2oV� ��?��.�EpB�j��n�"8��ɿ(��{�9�|t�*�J�n������|���*��zM�~@I��G��G���"G�\�:��3Ϛ{+t������c��u*��-�.�Su��^�\�c�Rp'�#�ob���F�*s��]&j;l-�D� �RN��!s�����u��i�d�4��'�-�0�R"H�E��h��?�!0�u��$��6J�z�ŏ�l�	q��+����bǓ�	��(>��N�Wd���jmĜr؊�����b�xP�M�:���	ΐ^��TS�1��r��-dz�o��7��^5ڜ�G���g�<k�7��<��K���ya��ه\�s��?�d�G�&��v�7���h+�kݷ���j�X�7F�u@"�3�%�XТ�C�-V��v4�a���z�#��&���� ��N��p0Q��3�T)l-���Q�B庖�1椨�y/@�,	�rH�E����fB�ʨ�ORp#�+:+�66���4i���7��l�W�OE�@7C���N��ܘ<���y�o(D5��=�F�m���_�]�֝�&ݚ�%T��}�YU��V$���I��>J��H����gU�ߖh6WT����m��<SSv�Ȇ[����h��U����ڎ�J�;O�mD�Y1k��o����刓��C����y�H�G%��y�cW�Ú�o�A�u^y�KWcZC�:�\�5{��GGz�D!����G�*���3�R����4:�X�����}���`!=�9�hD���QĪn<����uF�g�uf� ��G~�NLdކ��n�0�+���F�#�?�Y!���,.Jt� ��7?�4=�-�h��P�S�!S��cK��e�;f��)����fPG{�{9\7d4�^6 K��xL�}G�1��`��w�`�b4���;��}�%� �c�P��cϙ�mFTܤ��9?7�e�o�]9� )"���g'w[F��q�_b��R+'�z�Q�� ࿜Q+�W`RlPޥD�w����YU(�"�ޣ��w�6P�u�8 JP���W��ZFs���\�f�ח�V�'3/��k�Qԗ�$5���e� ��r�D������Xx���gp�n��+��P��� �=�@��1�U��U1%}uf+p�Y�es�zğ�@L�z��`�ĭ٦`�k�(�Ȋ9)$������Kp�O��x'������u�!x�Z&������Z�C�"����]c��e@b�A���(asr��k&}�� ͪk=��ǘ����(�#@wW>,P-7�����Fvф��NAdؘ��c2�Oҵ�B�It��vU�S�L�(�U�z�nb�B@�b��	���,�����uX&�R��|w�VAU����x-���a{���)��*�9.P/��cg�<����&}OW!Svp�	�X;�ܵ�Xye�,�{����Ó�E4 �m`�<��Lc�i\g���ȇfϹ������w����ވ<��o�;e�'��>1��m��/�J��/�s����}V`X�h�)��Q[)�����kD2�RF~�"�<i.���R�B3NRz� �ϒ'v@�����[;mGN{H׳dϒ�EĄ����&ι2E���N�n)Y����V䠋����8&��@��F�����5�N�,���=�qW�]�?(ϒ�·o����9M�����A�O�*�ȃگM=��J��d��Q���2`���8k��N����ǡ��&_A�#�$͢m0Q0������*���Vr�I3Ih�x9F&�:�J�{]Pz�	��|X��_���х	&�Y1�(��`��LHBB���筈x<�b��LC���p��quҼ4�O!3H ��ʭ�Ne�Q\��$�smF��e{���,�y�-�H�"��G����h�0Z&�IQ�|@��� i;J)5�T3z�dW�5�6[�)*�X�d�h"��)e?:���vM7�88A�?���5�^AvJ߸��%zN^�c3-[.����A?-���[��l�< ��%�������L��˲�'����������fe���~	מ)���+7_rI��J���d�ǃ��E:�i���;�d�u�	�}�����,w�,��6Ų�0��](����s-�֨�.���5&�t	޹An�Փg���E>�����I����6�:B���ʱ��_��"$HK��2�P�.�ݩ�����'ۍ���
c�x���/�[؏ׯ��gyH�0o}�Տ��6�Dr+���F	�/U�����	T���+D+�7��o�:u�Vs
aj��8���D|zg�)>��_��>q�x�c��v5�[;*V	�e;�槗�|��U�0��Y�0�e��'dF�J���D����Oĳ�gn=��%R�9��{���V�1�����D���jk)��'A����p��5���9(�1B"�&Z2��Y�-��Qb]��8V��E ���9|�fD.�s�~��]��g]��\r"�q�}����=������X����9��:J��f`�a�	�=~��@��e�j�,jHZ_Ƙ�݃&��&��~�����L��OE
$Z �<�W�ܾ��Zп^�6J�DG*ϹV������d=/�b�zO7,����AD@c�Z�2 Og��Q+M��_�g3xzB47�1�����/UL7P�k
��ȎQ����>pG�V�@���~y�]���X�G��JgOg��T�	��}�l���f��5���!e]|��~���-��cg��e�7W��
6!�^�m?���ݧ3��j�E�4�њ�ط��$����Fj����k�$����x�7M�'r��C��jbTdN+B��ӏ�R��@��m�De��܉��b\�D�a� x�Sw� �i1��Yl���ai�eָ�z�)��-_�T�d�S���]#
��r�S�s47�_D���(јѯK�aWNgx ��;�p ��?���AEh�����9P8+���PϺ	 Y��d<f� J
b�P#�<	��"����t3�H�)�Һ�zs��b>'���!�v�Y��1Ě=Ԙs�^�&�T:X�)���4,���H�:�a��vR�R���� �h�f2�n!�=9K�$�(*`{� �u��� �i� x��H����"W_p�	��:���Ұ/���z@j� >�AU� �� ;o=�N�-02�K�]��4��|Ӈ�A3�-�E�"j"�~���g�-"FI�{��`��s�Zz���z�i]��2z�e^�[����z�{�����{����y��	j�qr��
O����h��� Ƿ�jT9pUb���^�w�tST�<j}��nL0!��.����A��]�����8"���>ܛ����^Ƙ"����a���f� <��%�@ ��;��́Cy���@x����ݰ'X]t ֣�ѹ8�$�E�A\߽z�������v�������_��
||r���}]�&v�;4Ⱥuȁ�N��Y�&�� �M��#�r�9I]1�%�[���p��Ԯ=���U/��a�+��f ���]V�6*'q���p��-����	�1zE�������V��se�.�D�EM�Vyg�`]`w6Ȭf��Ǹƒ1��Ǻ�F>�;�J�U�P2��N�~W����K�Vgp��/>Y�È�LhW�n��k%�栜`����I��� ��MҘ� u6�����8Y�����R�T���G���tX�� o��W&p
�b��<3O�8�D�{��۳��r'�Tj���l�qZ�Պ.������چ����ʭ�2�X�	�-��K?i��T�U��~6�ŷ2�/�ōk����].��؇�d~�l�r��Y�4�6��h��D��	j��CU�Lg�u����*��v9��1���F�v?S�r�Q�AZs��O`��k��q5T�v9D���h�l�l��Ь�f1G�E�[Xݴ�*��hq�qGA\�N<u\O�]J �7H-�	��'���W�?؍��y#�5`��,�Pб�3z���0���0�{|}��ݞh��:����Wy����r����%:�8���=޳��T?�@�=��W(<^����$�z��?�(�Šm;��S �..o��w�����D�]�L��]vZ��V*��ga��օ.��[_�r'21����g8�A�ѿXH���D�u���~_G,������{~>n�o�l%1��9yB��1|:1�A�<UӼ���q>���,�
/dߒϵ�x�C����0��s:�Ft�r����5����t>J���U{�I�
�4J^f}I٫^n,ݱ+�@�^*�kgi;{�!.�¬;Sq+&'(b�a�@�@��4>�U��ȃS/.FR�m�Mecv�C��w�Db��*����y��m���6ӛ��[�iN�$\��O?�ʁ��q�c�����j�K��S8���g�΄4�LF�Q�W����5Dj ����Բ
5p#��=D�(��sv�Gs:��jV��m5eӑd��eT�ە��+�(OY2�;8�/�@��C�]�v�DN��M��ms����+�)�OL��g�_ ��c�#8��$T:�H�?��^'�`v�/�|d�����F~��G������o���̀P)��;�@ѭ�p����ZDZ�4(�qD!���-��%���� �DgQעG����Y��0usl�Z�'�5C�9oL�8	��M��/���X�C�B��F��<�ƬDI���:��:ӣi+���;�i�(��;?�@נ�/��������0K[�0�{$D��V��$L+�z��Y>S�*kYOxL�>�B���V�L��G�Q��/��l�Pg�(� BH��(�۶4�5�z���Y�J�?H<i|r���v_���ЙF��c��j;E��Vwٱ�LG~��ҧW9O�J5�^r��(,�6A�)�		�te�=�Q�6�Zֱtg���J��D3�M�8��C����sk��F�F|AX
��/#)FئYk��ㇺ7I���7�6  /Tu����R��C'`���VZOnB��u?/��TW�,�X[a; �Y��Vy���X,j�j���q�����30#o����0���pH�2���������[��{^H�q�a�.���S��h/����l��L��=-�#���3�5
�Y�Y��6[��6~��h�&�X�Z�GZ50XDZ���"��Go�Đ�4-"�S���5�OQ	2�J����KF�`LK��(7NI�Wg��_���?����%��΄X�&��t������-
g�t'�g� $5�$p�dA��������P�zYෛ;@��@�Ԧ��xc�z�G�
�[�����w39������IR\�ݙ���H��ꙜS��[�86����W�kpfQ\� �M!����M˄��#(�*0������*++&1�,*���D+;�$���\#�<��v��!3���IMn����RV\	��W��@��^�-NL�����'▊�_�/:g�M�dM�L��
�ayM8�D*���*\}�J�`��'��_@��a��NO����{�]x������KƅҤ��wR$&w�qr*�u�ܘ��t�� '�4f��=|J:��ޱ^PhBJ%of�E0k(�"8�<��>�n�~"�9"PN#��hNw��A*�<�%�ܖB� �B3"�QnwRY�i�
_.��L�:9�/K��}X�a��ě��N_B���r{�}�-@8sV��l&쮭���}�^'�BY8�C���ՠcQ�;��(��-\�)hg�]0<S���Y�w�>o��E��}K%���Y���	1q�\wV8��� ��>,��aօ,~#�	�Ԧ*��$ ��/�<0� �\�υ=g�`ye9�D��X��X.��m]������wy�F����2�h��C���?���%#��٨����J�??�#˓�-u%�3n�����U��vW�]�1=m䋭B�P;�֜��Jn��KK
>���2Q�A��y7�?	�l?���8�z�a�X'@�n'�,�7�b�[�Kg�<�_���7�'6�re���HEd�^Q�VCص%��������)M m�V�=�"�\�&͹�m��ф��!��P��R�c���s�P��D��l��H�[�Jqğ���r%�1�LM��vĒc=�	�E�o��&�n����"/�H�nZ�E�.�O͝i�ň9q�ڂz!�ە̔����Cm��XO��>l+m�HO��?:hkx� �ǒ���}#���K��ۻ������{ӆ�_͖l(|��u|͞-��Id�_��j�(�F��/�i��]��NZ� �w�3�����0���OU���?-D�z��,f�^2�Ы�^��Lj	L�K3��$�$%&EN�4ϲ�'�)Tk�Fa�R�Jj��־�D�Ӳ�'�hH�'y���-����A���ҍ�1I�;;���J�[�y�w]��INzi���6�L��Yd ��ڪ`m&^�5]�@n��b?�7i�����)h��W��#K�����2\��0��s�S���7�[K�_�#��4����#���m�ǂn,9�r�b�{�v��U��5���>*��ړ������۱�)'ѬݓŤ0	�/-r�����e����z�LLv!��Fg|����G�yd�@$
��=�]%����X`lw��L��.���6��m�X�3\�XӖ�q�)J�X ǤI�h�0l�{�}}\�d)��:��[��n��6�+�c��+�	.����_J��/&�̰���=s��&|9g�{�End���nfex/�U'�$���"���|{s���%������(�JG�CZ�?�(��#�$���d&�������U�ܨL�I�)c_����p��ia��%-�&S:���sH����
[7c��{5%�$7䋂�7�[/���Ag)���b&B�w���������t�ɀ�9Փv�e����TY r���O# ���<��/N���TBݝ�m���:Cc�<]7b���d
�\�r��ŧ��U:!?'&��I�?a�i�h�܃U��E�Cä�����}(4J�E�f�5�bx:7�Lq��VL�4a5����f�~-����v���▖��v9w�8���jM��T�"F0���39�ӟ*��q���#k���O&���yղ��	~^)f��,��Yi�`��h��doU��5Ӌ�x+�F�1+Z;���ǨPܘ�j�6���c78��y=�r@&�.4��,h~�B!�;{#KA���3�h���1�cd<�G'>β��r���$�f5x|�1=jҍ��A�{@VǸg/%��<-�>�[KYe�ӭ��#��Z�y�G2�.I{�g�0�B�D�q ȝu���dBC:�'3z�u�v�ᆬ���OY]�B�z+��&�p������6���2����6Ȱ�����㈷� ��ps��d�}�������w�<NZ��6o12IA4��cش�nflYN��[�)o��;���1�Q�}�gH�3���)��n2�Oz�1�4t0��_`�7Þ�Y����OA<�����>�"���>�|Swb	iFK�=�Ne2���1�x5e_��d�oxhJM�di?����<_�▏�61>�lg��ZT���K���[�Fl��c�܁\)� �+D���^u<v:�][;{X�?z�]�0<�9�O ��*���@�E�İ�;r��2Q$��R"ɖ01� �I"*�I�߀S�oIz��LW7�v��5���RvK;�� :��4LK8W�F��J؍0�q#�{��!��e�J&)c������0�k�t;����E��wf4\�T͆�鯂��Jl�w�H�\X���܎�{�I��Q
���W�l�1.�Ws>��\1�7�-tN�.��8���_���ᐮ��&o׿$�ʋ&��-Z�	�!P��P����A(�9$���oiT_�=Z](	R]���6!0ωIޫP>J����Y/�M-(��T��j�&��r�B�2���_���^?�j�(@���@��� ৙G����7�x�i��>�P��F��}J��������2+��;�'&��@[Mp�N�ظ�o�0�U��ˮ�:'IWpD$���6g�,[�0�,c�V�]OA�2&y�$���P����פ�e�Y�۽��Lh�nUz�E�8,;f..*a��K'�`&?B��N��w+�	�񑴈x${�K�sDn�ե�[Ja#U��j\�����Ӿ�w�h���:��N��<�l/�iU�f�c�A��2�����	�������c���M� "���ȱ������#l%�3�4�����x�n8~�a%���r#3��te֖�K�t�`�<���p�К����lV&����'�x��O$�������������?��/�YnL;��F��2���P����f�4�����2�lX̻�N��UO-��e�vu�Nw�f17F<������Ր4:)�d�{���Ȱ3K�ih���c�6r�rY6�d$���f%�y�g$�OB~���� �h7��H\�_3�x��E���o������GC
���O��u��e`z*����C��/�/{z�zk͏����ls�C��S�B�U���yp+Q}���@/H����nL����3@�����q#Lad�ȩ T��m�`�="�P���t�~��t���8ح3N;��:��/IM�)���c��?�?�ĕ|&X�_z��'�-�d��]�$e¶4�Bk���GBJ+�ӗ��ן�I�S��rm����~V��|���';�s��uSA6�PM2~�d��3_�w��-b�tţ�w���'碌�M�7g��i�	[��|0:�Scm<ѝ㵫]��,e	#�tL��Y:ڴ9�:g��SKD^p��g����T�eK H=�G Z{z�%g�8���ʐ��#��Fn�*W���ܐ'�1��\4�<H�6��'uH{d}ܓ��w�f�>�i�=��a���z?-�uIXw��-�'ƪ��>�Gޫ��P7��L#���l���#bOq�R���?�E�Bfwڟ�l��v
����<o����H�ŝ�]�.Yf��� ١4S���\*�֍�rs�6;r�sU���,W�q���t�8�s�R�+�ř�ώ8����`A'k��q�q,r`�~�f�������NL�U�����[q�7�����bD�����#�J_���yk�x����T_�v�-ڬ1�':iӶL\��[�lUk6�K���Ɖ��oJ¯J2�oF���ei(GU�u�P�K�˧�DT�� s��>eʙ%�L�+W�	+G��N˼$����Z׹^�r�?�}�^6��A���+�:�|��n��,�l�a�,�s����_pI/$���R�S�.qj4p��eD��9�.�i�3�	�╮y�[5S)w�#s�2�Yg��X	��
eV.���FH�=a��9��o���*��5�QA:���Jn0�6u@p�b������ ���{_���p]L�/����	��ڒ^�t�+St�_Z�}��w�]���G�RIz�JSO�.�]��� D��Ǳ�	����D
���'#@�CIi?h(��p&Щ �������ڀ����{H����0�� �
	�<�D��ܒ���y�
�2��a�ݳ���޹#���<ޕ(�J2z#�l 3�4�&� �K�#��s����:/��&u<g��xgI���\�z6{Z±k�Ԃ`[t�G�F5�� ���tm��;C���WsB����W�`�����8pe}�N\�����v�}	��v�>�p�����������(��P�yQ�̄��B����τ���8�� uhf6�G�8���'�����9��� �&���&	���d����A��?�?��9� �79$8K�[uhϚ�
\�$y�y��O�6�\�@���-.�׍�m�&�T����e'Kˬؗ�B]ޭ,�|;�|�h������#�0�m�8�M7���>j���E�;�VHޔ�w�q�8Z70z���1�@7���D&$Ǧ���Y!�K�Ž�p�dR��w-�W�ea��w��ap"���>�#v��{����G[��Doq�����=U��B��{�l]]s�
-
�!��4���c��4��XՌ�gh�]���%p�؟:	`9H��,$h�[<@��൸���Z���BX�Rl���>�_hL@ؓ�^���	�3@��9Z����E+6P��,��+<�Lh�^?�GL�'��;�zI�$��(�ß葂�3���HX�Zß{�y��g��mCC�P�oc�� bK;�c�o��57',�!p	�]LR�=������9y�
��#	�&��.���? 0�$�x3�0���Yr���*#N�XW�3� 1KL+<�0Ę�K�W��V�����[Z�:��hw?�rs�Q/����F()g�a��j5�+���h�xN��Ia����Ezv��/�ŌhF)@u7��3;�{qU�cK�+�!е�ao��͠5�(n�i۾����L}������U�oI.�".��F3�ڶ�K�V�%("��gY�*ϣ{��.�D�X���.���������k�dH��Qf3�?O�ϩ�9 �!�R�����(�0��B��O����U����4�6=�m"�b�{�^ͮ�1�S�"�K�^���Fm�b��=�O�+��쀅'��}y	�E���yZ/[��9L����}���S�g�*s<�G|7�Kb��ל�j�^4R#��]2�����Rd��-�ϟ�T�D�]��+D�M]�l���l�>7���#�勻�9���A��s�w�r��D2�X��'�/C��!E�o�Ɵ�Q�-�&;�������
r�T�s�]}��4�`K՞������ ��7�����;/��.ׄm����Y�׽5i}��Rvx�m_ȩu�b?�R��fԥ&x�us� �$MVA�a;�v3F�M>�S����(Fm�L������#=�!nu�Krh���`He�h�<D�BY��t��e�`p���k�ط�i��l�<�)+��*,�0�	3�y�Uޗ3�]Ûd���������j�l�nx<X���y���DpY?$��Nh;��X_�C)�#�N�	� ����ʺ�\a�vjjLZ/�N���*�!�i}?e�����U#�WjV�5Ad�8m���s�A7�#
R� �ۿB5�G%b�
��F.v��X��R�ǝl���9����"%�9�7h��g�"�_���4T��'�%|�;4e�Q�;C�N��Ih0��lU�����Ǉ� 3�%�WΊ��e{�B�O����_����-q�&�gj��O�l<�o|��[g�#߃��{����Wr��Ò�{�0T���Mv-^��,��,ܧԻ�Ǯ��)8ت�OR`J��9���.~����C&F)z�pz�+$���,����d�1A$(;�����%�E��2	�����H�Uh��E�6��f�+�Ý�n�A@.#�-���~X������4����j�_CB3�'�J�A�~Р؂��.8h�dP3){:�]|0Ji u����K�������]�d��h)�w��&S<�NB]���/^spY���U�"`نt���1I��.o�����ɨ=�tl���[�����\��?���l�I̼�����U���8o:e?#d�:D�]
?�M�!lv��+ǯ\�g,Ua��ڀq6D
A�((���R�x�bi�ţ�x�$��c((lk�y��Z�cu/��s���� S�����#gu˘�*��JV	i��>X'�m�P��)h��n��J/�S�3&���3�jA�r���+:|ӪzñK�l�pb�3X�����K�rC&8X��!����lA=<M'��7�&q2x3G�'-R�3*���5���X�7���m~>!�}�`Y�MXG��;��U�#?7.�=�m> 4 �8�hl�������|���y���c�mUb���+�$�_N4{Z�~�H�WAYU+�u*��-��B")�.�[�-�͘6T #rw/'s�S;��B��N������?K�nIQ��b^f���/C�x)�� ��5j�AGRf2Z)�� uBBPb�z[
��T�O`o��/�ƺ$F��I�]O@�^�l�ґfN�JTB˕"�����,E�G���h�?z[c����q�R��,�S�O������+Y�(��J��q�1����A�M�x�;�0�\�
-m�_7�,~�ޓù���>��"A�<FH�D��	/�����O��q
T���ZR7�9������=H�j.e�hm���/�׋1�*B\�`!I�^y�R�]�`��QW��W�{:<J�Q����tϗ�s�r���3�5�� �h?E�m��dږ�v��uasL�>��̦ԫ�.��;1W����5���p�~{A:.���@_]ttK@���������^r<?�(�D4L�*��А��Q����(8��`N_>����+�Ԋ��i �r�*W�-//�P�$u#�4N|8�џf���D\�L퀃��Q��[P�g+<�m�oؠx����t�9�U:G�����ZԨu�O��QH��W���@r��p8H�y�mWx<˚�7�����c�f��sx�� �fJ�@u.��ܕ"����!�m[��l��(q��@=6�2v��u�Vwh�����'�\���m�R>7F��#'��8H���o�K�H	�vQ�3ҙ����w���:��ܑ[�/H򟾧�Y+��j����f=x�R��
�&5�%Q��_��t�!��9���[���W?�,��ny����+�?� ���drs%�E������-��ǐ����g��Ox$;ɕ��t5Aa��ÊQ��%a��!8�&�v�rZ�eK�����~8���9�D�N�z]W�y&�#�D�$�a(�xB��!����47F�)��#�r�*)����Y�2oҞ' %�H�=:?P����/���_�b47���LP�_ioh�0WD�]b&��x�
+��ng	M�����P��l΅�2>ݷp�c�$S��J���߭���%:�6Lp�Z��p�b���UP~�y�$�CHY
����Ea��13E���B�]�a�h�P<؄���:�d{x���!�a��^+J&��zx�غ�Vs����:�+\m�ECÙ��Ξ�<՗r��0-��s�6vF�?����͠�#�>\(��c���R���k[j��\7�6�u����fp�|ߜ�����D\������� H��j�#�Q�:7��)�g�����6��gB?÷1V@��KW`	��
b"���l��2��]��:c�����x�S~|�7 4�n�K�K���m��Q��QhW�9���R܌s�`Ó��
��q�4^_������Ԛc��Y7ه��⭎ws�^L��+��u�&H��`����fd"v���=!?*�'P�ćlr����F�7E	�s֎�W9Lh����>�����0z:)q���Y�s�l��v-Ya���s���ĈF4�@�����c���Eb���Й`��V�|0�,���E���C���Qź��;���T��4t�N\妐T�\5�ۏ���7�9��[������o��PB���K���~I��2�2F�y+�Bj�T����83r%xK�q��$`m�d�:�n�E`�3�����w��)A�͏_'�e&�8ڸ�������P$|�\� ������1��n�9HR����E<w�`�fY�m)We�8�� �!L����­�ݠZt��N�?�FXa�d�(:w���&���W�jG���nJ邳�I��r�]���gup����18��O#k�F�f��>j�x�p�T��ua I~y5{�ҭ�7������/�s�y��]��˳ʉR�1o�{8�5���ՅM)U�68I���׽���C�k��ΈOE�@��G���"��O���;��	�������>,:#�;g���$O�e��.|�m�� �
��a�/Q5��"�!�F�Ҥ��)ɿE+0�mR(���P��n��p	٩�RC�Y�EZ��5W�M�<���E�v��9�N�C-�f^b�H�L�K�9�g��.Tx���2CZ�S�Xu��n��>��M��Ky�I��%V%��42�w~:/	=iK���N�8x|sRL�˱�|7�v#�t�����[5�j���s�;�JS�1+}'`���.��¢�XBn����.b���6'�v.����� �xd�$]Wr��Cz�J�O��Q�y[Oc�O܎�2�����d��ٌ5��ԥ�)@Et�Uy+}��t���ˍx}[/�'Ge�Z�����m����?��~��,5>�6�S�a�#J����5��4V���RTa�V�lu��rsY���u<܊�����������٪�5��$���c��ʑM�3,��t�
�krk�*�?#g�P�:5��)��}~h�3�7�)���p��f�C�)��k#���73���p&���8W6Q��e�=�?P��T�6KSY��R�Ӵ%�~�������q"{aj
G�H@2�#/�*�7̑��2�\%����6Y������x>���
�5�*�q_V��o�'`�1�w�[i��RQ�0���I5��Lh$��3�f� �m�
!"�h��n'���ס�B��
 ~]HV�B��m��ؑ���!t(Fo6hU⭐��5����g֌Ie�!��D�l����x�D�D�RE!��=�A�:�������̏�@8��K�j�����Md#`��itf�%j3?�$#���BV�taY��j�a��UH!�,�O�+�[�A�f�1n����|���{�A�2�p�|�����wt���&h��@�-]��y�����h��imO�j�{�h
o��|�B�s�]�ɨ\�C�t��Y}e1��������Z��n��csx�t��+.�4,Y߭�2Hp�F���RX�	3���ָ�kj�����CX�ߍ0����cd��cQ���D��Bl~����-j�W+���㙵�RE^q�bM��n��A��2��^Z�!�v꘲W8��vcJ~�~�]��w���H�uU��̪��D�'U�ܸ�[����Is���N��ӷ�Cj��������f ~߀f�}���~*��EJ>L���YgF����e�#6���s[�v���4�P���K
����H��1��������*���Sg�T>�ď�(_��C��)}Tp�2��$��6�Q��V�y��Z3���w*����!I�l��(�W	/��M�g%��n�b s�;�t�%[�c?y}@By�M�~��Z�$%��oTRg�[g^�ֿl
�@Srj���S��%������.�
,WZQ�{��yŃ��iH�D� �݉p��������Y�+�g԰0��������)��Y����<xXT1��)�yl��6�.^�դ�7�S �R��1�j@7�Ŭ_ّR���4���'�?�k\�9�D�߽��˝��3OQc �qt���i������p��KO���m��-����h�	P:=W��{ n���q.NP�Mb.��o/�K�NX9J	۬;������0�(Ty�C<bVc��@ct��z��1'k֡z���؁�SK$�jm=�4Kg�J�-/;.$�w������b�uv��JT��v�.d�ŇF�uėz���L���-"TZ�v:t�؞�\�^·���f�6n�o��6`2y���ܥ��o���ȅTtx�&���l�{6>�� ͛6��P����f�_/#��/�_�k8���:�mf�«��J�	�JݗJ���#�w�_k���k��%0��V��^q�ؼu�Nc �a�aԨ�B	��ﺈ<�1`��g��C㭡���:���֒U��
~�(�>�8��=���E�p�}�O|��������k�tD?r�\KPN.5ei������	�"*$���)	=%mQ���Jy�0�`>8����Զ�YgGqkIS�&����݅c��j
�,�mP�2bHDKr��9��ƃ	�ioC��8h�C�v��Q��)�ClM�j��|����|�����2�	 �Ur5���9D���:LK�����:=h�r6�*��3O��ѵ8<	��zes���`�T(f6�R0ᘪ�R�ܦȖ��p��k#M艳��o~ٕ�C��j�U�d�s�]إ�'Q�JlԠ]��^����t~��I�f��M�2���`Ĳ�E<��u�U���k_�<HW1Pb^�ir+0x=��w>�6����F��ȿ���LŁSR�8k��dōGA\��'����[@R�m!}Ds�ˤ�0�����I���3���
辏�t
��/ro?��
�q��zT�ͯ�Z����T�}ݲEt0�t�P�J�fL\[	��,���Ov�]�5�6��=Z�2;M;��+��e�^N������-��cr`��f�:Hi;��B|4��(�����{�O"uu�4$�|���B�w���3��n/w�dS,��5�8����.+ֵ+�B�4�d�t{�,ѧݭ�����l|(]=6��f&�9R:�<����58}�/�M�����h����S8w�g��j�,����_77�a��\��S�r�:u�%S'�Q�֌���=�p� �%�7��WyZ4�P�3���Y� p}��4ü/S
���R*���A��#.�l�v,$\�%n/�\��<a���u뚵��7���V�C�\����դyJZ�9�)9|��e�v�Z]�Q���BQ�4��W�,6Bf�q.��I�t�+
�V��/��Ewfv
��&�s�뒞���1���:l��0��/]9��z=����!(^�iGe<@ �Կ����52��/�B�ѾO�I�o}�U/מ���P��K�I/~,�����'N"?e�ݷ�Z�"��JB6�5�L�2��ꔖR�����u�d��pB����3��ͣ1m�Й�*�?c��F�j�e���Sf:��5�ܤZE�^��A�_ Cw�ƗΚ��w�.�$=~8�~�'W����M΁d�t$��=�тc�-����*�ߙj�ͤ�A���J�k�!<}t��?��'��♴�c|��-J���լ��jR��q�<�J�K�4g㮏�5�g��zY�K�9�^���iZ���W��X�6�W7--��fs���\�_���I<���U� �Cuzf*+��;$�}G6 ¾<۹7 L��J�� �'���Xf����)�7�H�~�.7wZi�Ӷ��+�&�},���KԣSB��Y�M#��#�ǫ�!���;��3�Ҧ���o$�=���Q��"�:�c�d�Ldc��rv�wF�D��҇�G�W����K�p�� £����]��0s��oR�Cb��Օ6���U���׮2Y���R[{X�C/�pNx�w����
��4jJ^LUU�I�ѷH��r�k���5�f�P��g�(�Ůac�X9ʅ���a���3�� >:ܾ�P��&�f����xh�7�L.�&N7���qs'w�J�Ώ��eC˒c�gZ	Rk�|k�F��?�8�,�"bU�'��K+E#�1����I׷8
�M�`��#�r@l�H��f�ť]e�~���e�4q��л���dK+�~�W; S[n��$�p���������w8����8�B4�'`V�E��J���J7l�P1A �X��z@�y�t��أb�Ѐr^
�z���I�[�C��(�#���Ln�(3�#���p���c��yw�`�7p��w��LG��	m�D/�h`�Z�c�x^����87�S۠�bj����AKɞ�3VR���,wY��IQ��m��3�e�{]��P��ⓔ.�jĎ�^Z��30b~�?��m�%��;|�,��3�5�S*���_��b�7A4*}&b~d�8��:��a��)t|�jT�Q$}�u������t�J��i��?m��Pɦr��"�3�yVKp6������ Z�}tO�7l�p'�o�ё�u�-N�iq�W��l6�����dr2��+��NX�s��>�z425龒��}=X<U�6�b��W���P�[u�����c�C6���3�?{)V�������Z�em]�	E_&�n�l�.L����^)�s�qd��K�nLm[bABpS�I�5*)�1��M��8ŉXYfe��׿ ��cK`�@\��c���Jx�+_`��o�-<m�\���!"���Co�Tٱ���V�K綼6�"$;�<�|A��r�CJ_�EiϖMRa�"�xn�d0�C�VA��1Z��C @TA}v�}�|�e��{$*��W�4}��9%�W���mגn����d ᪯�~��
��}�m��|7���18P�:/۴�^���0q�(�oދ��2��В_�;]����f�5�j���3zCμ��j�Z������S:��o!,�J��2|!��M��9����9���c��Y��@��=�0
���f���C�QE�ۢ�����h�N-]�a��5�,-iY""3�����[���R�;�a�޳�R���C��bP�U3��л7�C��`���K��{�]ѶIi�W2�^1	�rUfi5�H��FƼn�Q �����L*[A+��H�#ɱ��X���1aQj�����?�<����1�Y������]�|CH���`�={���ijU�K,.��8@���PՅ��~>pG=��~�L���e[�~�%<1�����ٴٝ|�B
V�0������E\���O���f<b�[Y�iVy���/C����QP!�
��A���f'��v��8�)`Š��>Q����?cGĴ�N���c��j���'niͭ�puQ����j~���r��_��OdM�DG�$ij�&�������%y�m5�����}��:ɡ�f�zt�M�:�dx;�j����i��sk���2)���{ҖvF���h�M��R-�Y�x��ۿ#ِ��FG��x��,�ӵPS $�#���7ʪ��� ~RR�ޢ���%L�����M#Q�PE@��c�F?�eW��
�V}�N���NzHz�b�w��K��hQ�c��V��$�+���p7 ��;����/{A�µ-{Y\9�r?^�!�E��+#�~�5���S�~�ͮ�=�R���MLBPL����b(z�{��@m����#��}�]P� �q�@o��ա���~\��R\kn��"NQLʶh6G�8i�0]�^�܌.���苅ж�dTf���� i�6Fg�]���gqJ���X�~���/��<K��.P�M��e�`�Okp�(�ն����C���{�yxV��0Y�]S�c�� m]#4a�
�u���2��wH�aڛ��U��-� ���,e��4���J=�*Q*�N*Q��$ h��mo`����S3����(K)A_�b��T'�gO�qxp�ݻ#&?8l����WtT�=jm�*���4H�J��a]�p�FO'P��B�p�X�V`}���ߵX����pk�{�T�|܋`b��r�]~��	nC���,�'8z|=����]��ʪ�N]a��
��I��S�ތb���D����u�7��CE_����:�c7�aم32�h�jy���C�̧� �R��%�=d��E��Yչ��H3d` k�0����ԗ�VY����!�m8��V�kq��*���A��0��`8���CL�}��.Dss��L3�Ei�هt	y1��&��n�ޛ�5h�a�C�� {�T�m��o�' ��v�M���s��pv%�<�0�ܦ��x����A�=-���ȕ ��_3����_���94��p���ܙ���d��v��w��X��,ή�PΡ5��z�Si|),��|�������)���Jt�d[�;>�o�x�kTF��?� �4L��~��8W:3a�K�:���a����E�{�W�օqq,�8����Y}G>00j�=�G����o�z8�}|�����:�T��+�48�A�|y�Y�QKu���<
g�������d��Ģ$ć��?UD�Qze[� ;l�Z��;^e��`y	8��8�h��V��u�V�{�g0;d�M�Դ���� ����≢�s\q=!�86ʡrQ���E}�Q���1�`����?.��
���?r�K��*`�hF;O�Sٕ�D�,��y��y�
s��J�R���K�n|5*/R��4��7tU�C��wcP#��(��+� �v2��FUƶѺig=<�ra}�]8z�|Y�$�`80.<�)���(�Gr_�;W,��\�a~,�o�������>ʑ�R��޻W
���Hb� I7�K?>��hF�ӆ�����a���8�)J��fK����y����8�I>����α��9���z�[Nh��#"}�?��#����bK������x33�T���s��3p l���	?�!6b��m�]��z2۝/(�H:�q-B���(	��W���n���(�֮���H��c�6�~|�م��掎�V�����z��x����)Oa�� �K��cC��Hk�<�!�����1׋J�Nsn�L/k�dˀN����"K��{����N3*}�+� ��>��r}�6Mxr;��L�t}�]�n�lg�֍���ru��������O[������I獙2*�IE,!
�[�ݴ�^�Rbkw
��t�-��y-�I�/��e!� ��lF���n��<舨�E�x���>_6�?�I�oe���h�r��*E�M�/����~��N�w�(c�E�U�	?��#f��ߨ؊V�k~2�%J��)x�-E�F8"ݵ&�z^�u��#bc�=灷�L�����&�A!����5�E��H;��Ho��B�zP�:�Bɒ�]h��Q[�淎�#=&�^]Ń �r>������n�Z# �ڻ����Pԩ�A�{n��=2���_?4\�z�_�A�Dha�JZ ��W`H���Aժ	�J:��VE��� ��F�Ĉ�����H�\��校w��ӠqG��Ru�.�T�G{�*�鏩��ܿ2Dw��&[0P˨pa� s�/��*`L�*UJ�B���X�i�( YϨ4�R����DF�`%�;�kj���G'���Iv��R���U�v�nP��2�J�"�ƪRO䬥;ʟ$r��[���*��f����tW���:�YÑ
��P%c'�SdYV��>V`W{ٺ��\����c5�ýhP�>�j#'�2�jƴj><�,R��In�:eu�/w�T�Fb�P�k�}*{m�\�X��>g��Y-������C�rAs扑���qf1E��
�*:�?y`E)�ic�8�bK�����8�C ۙegv�l�_�5z�m4Lo��#;x�n�t��TR��9�	�'�;
�l�$��"������� :5fD��d�f���h�9X��P���[]�)��.��9�֣��_��	؛'z�Ƣgt�v$�Xr�a� �>ʗ�d�X%������a[�	�����t��L&�`��"N)\�5��e�k9 ,�y�����E�x���n���6��C�<��	ٱ�YqT��=�i�0S�:_��x�+�N�Cw���v�3����XH��q}ߊ;��健$7$%n�-	�`�_xA
1����L�D�����!��A�~�(M��ϊw=&��J�+�Y�-\�����%uI,�(Ӡ���9� {>A�>��T�q�o��7c��HA��Ł��z>$�H�|�t�����V�G��c�G7�ß�	��M�B͊�3�+����M/e�r�9E���)�/�:ܷqE���?vp��hM�M����QaF=?��(mc}-��8�W��x0�ʡnƻ�l�W0��s�,�#��)<�1[��j^���Q�Ë���!x�Uo�	�hl�e�G��#>�����`L?G�x���,hп������n�I��< �Y�~y��p7�Q��'F!� ]4�mX��K#�Mg�7b�2E��Y�x�J/J�N�\6
��CV����3P4݂�"�ׯ�=94��>��0Z11<��3(�H��$m��-� 	�<$��)��؏�3s��tЉ�����˱��NCʥ'��E>6G���ٟ��i���xljD����}MV�4K��V"���C��/D��(�mA-�C�6�OG�M�L�v�n�z���?W5�4�Y4���;�cڮu�RU��7q��OjlAUN?**�G�o��Y͸Q��7)��g��	�Pg_1�8�����_T�ۯ9���Ӳݣ�h��G(UH�n��-sac��0m�ԯ�Ģbo�/����D��b�l�j�3'9w��
��NL�vۤP��<F�҄��@,�||�d���d8��<����bBT��l^� �:N�k�#&Qd���#y�&#'S�����r�6Y��>N'��8E�xZ�F������!ڃ/IJ�\�Yۇs+\p�O=}��Փ��x���}w�c1nF�V� �S^�
R�Lo@��u��1�=-x?u�V5��M4w:�[6D���M��=^s�'HM��h�b����nt��;ϥ������yM�mA�V쀲t$� ��EQK?,NG`C<�d{EiP����o�������l���v~��m@�|� �W�>]�ɼ��o1__�+�����-a���S�)OE_B�l
��j%:��zl��NI5+q�t��   ^��;ځ@� �����J����g�    YZ