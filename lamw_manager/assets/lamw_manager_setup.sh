#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1913663088"
MD5="2f15bc21ea8cacb1909469b5a71b912e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22284"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Mon Jun 14 22:32:10 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X���V�] �}��1Dd]����P�t�D�rIL� �L"�T�Z���M��6��6���6 u|�-�{����\d�2X�o�~���B����ǟ"����1�۲�(�=�۶<X�>��f�t���}؝yt�"H&�`Ǘk�)T��9��ݪ�v������	4�#TON0 �#��A�Ø���[��U�1��"5^<VC�\�-&�x!�@�[�|�3ٚ�.�7ގ�5�K����˫*�%r�������b�C2c���db].��z;̠��j�p`��������h�R���<%W�ܔ�휄U�,�r��r7�נ#���Qx��nL'U�m8g�h�����A�cP��(^�ħ,>��͜Q�Q�O�F>�B���K^���7{,��6��ò!��E�z�I���Y==l"-2"�����M�����P?�xz�#�hR���dH{B�~b#�� �׍�a��u0łms�͡�K<��yؼ�k��/>P�!=V��C��4��0��˴�����ڙ���kX�W�e���F�#�{�җ�=_�q�A�?i�mp����x�b@`1�|��*3�ª3�����yGD���*����D����[�����4����?w��]���6i�-�[��e�G��
��G3���s��N�1�	�
͢��=�ckFF�.L����ґ�Q99�U��c�so���}2Ȩ習V
W�=�dD�2�����x�$�!�G�{���&�AĢ���\�l�J��O����Xs�Ɣk)��Rn�'ԚK����Z����ma�i���q��D&�v�B��V�@�,�G�]���c�M�D}�UX����h	��]Y�G�|/+�d�٭��Sp����v��mMroB1gG �Aد�e�ɅDk�)tE.��;��h��g�����qe��5��׏�{8��6�Vn���^��-�pa�T*u'H83�v����w�_t�T�6P�F���¥�Z*��c/���k��^as�n��Al�XQ���S��;�b%X�����
�VC�gx�*V�G"���|Y�8�a��ֵ��`T)S�'O<��v��:�����U�s���H<�z�qH4y������ ��{�\�j
6� }��6��J�%1GU7A-�C1�Ǻl�~���t���>s����T��B���$$��(	PZ} W�bA�������`yIJ��/E���Ĵ��nl=�h�����@l��f?P.��t�kv9�X�۱��-䙞��R-�T=\~�֐`$*��rz�;z|�ܿ	��BW�&*:�È�����	�X��t�xQ��|�z�9�m T^�Ǻk��yk�� ����
cQ1I�#��SPh�iY�������j���G�����Ur�q����J�-٠��,կ�����T��+6>z�H���ղ���U�TH�/���U���{�����Ϸ�g�-��T�ĒD,H8!ݣ_�2'�Z�~^�8a�*���T�� ������^�qx�����%�Ǎ�ӱS��g{�p�ߛ�u>�g��d0��ժ�U�|��m�up��k��5��w�p�:,B�R�A��_{�Xa���Fp bgYq9+��E�i,�T i �����_����<(����­w���d�wx`��FI�A�:��=[X{�!�sZZ�����A�y����m�$oR
������'�7�r� ��Z�\�\$��̥����7ǿ�{ޭ�i- v�S+�5J{����� Ҩ;�~4(g�K}i%L�3r��ݘem@X���ʹϤ�:�������ؿxA��:ڞ�b9�4���^�m��驺S"N��#@%�tY-ơ�8��
����)�PrC#�DD5~���(�G*W�Ov ��@�7�C�gY,��l�c�"Ay���5a�)�i����ΐ+-ڰ���0I�#R�e�%����oi=�l��-y�.?-�~���{�Z�����m��U�s� �����ir~����>6�A�(�P�|�%"$vtÏ$���n�"�"���|�yxK���Z'ɗ��ՕC�=���^�1f-��hkB��ءaYYg0cᓏɵ�ZE'�� |hR�|��K��+�~��h��!Xjo:�BO;��N���˪K�R��Vw��%���Ya��t-	Kw`񳩍;IX;����B$���U��obn.#':�g=]��]�MH�u	�|���a�7i���VH�f3�r6��P��m\�%���@KbX��<�4�\������H�� ����x�tA4���ňnX��wn+1�����e�
�ݝp^�]S:�z��Ô�ˊ��Zj@*�:��@�Sa�O����h��L,����T�LrA��QC��kcx�ۖ��+Jʛ�ϧ)=��H�ɝ�y�0y��]�0���x;�	������Q��-� #6a�^m��M@��y甙��Q%�[�`�q��'��bî����S�Qs�?��r�d�aO�������M[-��d�뎚Zm��7+�VK�� �$�f��~nK�z��i��Hq�*Q�G����[�e� ��?���ɍs��D6j�6E'q���X��Ԅ$|��U`�:��}qu�Q��<�H�X~K�`@���a!q�	v�h���f��7��]�j_vfY7�uYձ�̈Ta�DAs�]F�f�s������\6����)JP=C�����e:6z�Zv�l5�,���pP��^��x�;�*Ā��^[m s�?�刪<|�!�0s1�I��/Ϥ;���g�)��-}��-U��Vs�˧����C�氟��T1��ؽ\e���b"�m<�qOm�h}�D�[m�v�TU���h5�h>|�~����X�
�0A�ط�����d7#���G�j��!��Y���#cC���rN+�Sla�xPZ��!��tQ�!�5�)��[��ܛ�z�V��Q��n�z|jFQ6yK�-��B�?�ui���B��g�;�Su7����ܘ��]�]c�]7 3 �#i�k�"@P�N�g�!�y5*)I���H!�ߦ]Or�K6����B�)lO��p�*
\��B�@�zm)W����8�K��$�����튗�P�t=%��M�!���8S��l�ތ�m
PfFHU{�2a�C8=�S��D�ZvC��E�CS�ז ��\��F땉bY�Q�xWԓ����!hB^ ����9�nhؤ�����f�=M�7��X�uVb�`lPӝ�M��qY��[�Ao��A]f�H���d��h�!��$dƦ��lq�ݩ�R� **p+�B��n���gՍ1�?H-�@�������Κ��{I��,p��3Do��`�JN�o'�f����^���H��K������|�O2B���� nj�;�݄t�2���ܣz6+Hy+��؟!�@�l�c��T�n�[
p�Z����>�r��c�^�f���D����Q�r�~��݀�5gAۜ�m�-�;��
�n����u
���f��m�*�r��ݠ���Pȴ�N�s9���M�Sr��)�F�1��b��G��3��#'y�`��d������tL���+N�I��������)�+��Z���u`����.4����3�!�i� 0� �"�J/�Ó�#�m5��髒��b�����X���ծ���r��e������C#pq>��y�A)�Ϗku��+���y�w�h�S-��y��ܮ�����CZ����t B
X�U!���O�|�)�H	��!x�*�0$N����aܲBhi�N��5v����둫^Y��ޱꅌ����}����H@�pӕr�ώ \A_�b�W�Eg��;K�o�W��LC�6э{&�X�-`]�!2��ۏg��Bt�t��-�ȁ�3#Q�^joΒ-�k�~�	q��6�\`Ȥ栛��vI��X�����|׷���x��s�0mNC���É����7Z �`<9f!��%�`[r�-ETz��A�5�T#����Kn=���*hvq�#����-~�n��?:��x�\�5���&�F��4--�j�0�,�(d�i�h7
a]:~ĵ^��v�װm�$(A�H�-Q|S�ʬ�b���]6�飯�8חϳ�?���=�z��s��b�����N��|���L�t&V��묍3�,���V�{���%\ԆkŷR��1V�n��� d�Y���I����+�,���ɩ�5*�~jہ��5��u�6���%Z���ޘ����oT����)]��_��~%�:�˄AG�5w�:��v���:%\�ф���,*���K�&����a9�K_k��S٠/��\K���qRY��t{;�u��Y��l��Y���a m35�L���(K�h�h����YU�U���
�*{>*n\� �|�w镄��J�EB{Jee7oKŷ�����`[MlL]=������Pw�;h�b����q5�^F��g�M�������u��=���J��d�;0p��?�t�A���۱N��!o�g��tBa�k��nsi���B&�l�7GE"�><WZ�W�ՠ7ɝLu�sk7�-%�E�j:��[៙�,J��s�e��+5I��0O!����������r�5�fRH/��ӽ�ŵx7��a����b���9��ᩗ�N�s� w���o�G�~.T�-=�߷���xd��F}Y:�ќu�љ��ɡ�j���c�"&��7��韎��jX���ld�q��j�i-��_�b��G�A<l��"���j0�o3�)a!�ɂ.�80v��W����& p�PT=�eI؟�R|��=��Kiy�������7��[I=l�ǸM�#����A�B�j�k�f�X�"�}d�EB�LZ�z>9H�	�J����ȍ��<�2�G��LIQ��$�w��%�ć���;������5ޜ~��;�RTL��BPI
�Iϗ��:S��_ްk;�X� <��q1FO�C�G�;X�
j޺Z]��Ԍ�|��g�����C�5U`\69��^UA��4��o�L�o�,�v:H�
��N��}��YîJ��dG��<�dv���L֩ޅy�Dj�J�#9��3!|��#�\���i�1	�0��T��BR�8(����\��0� �-��w�D�Y�X�{�Mq=v�}�j�u/3|Z�m�ig��Fvd\�^�5���,�Z$��O���S$q���=�Q;x��%��X�w�8�I���]����x�=ʾ4�ip�x�-M�8ۄ���>8lRf�*\U�
�X�i�ji>=AR�h���P/�8���(P��>90{s}�I
��[�~��q�Gn�Twu��{B�o**�%dg�+d�	�y��v 3	����#��YCh����:���h�v�P�W�[��g��s2��.6�"��b��X!�	�w�J�n�G?���d�P� �?�*���zޫc�Ƭ���4AKsP9F?��n���W���5�̣84R�_��u�+�O�n�����n�/q=�R����n,ȄG����W�a1��:�wL�NZ�㘗�|�~�^�l�l���ձ������-?����֯�p8�}��,��Q����+J$��]��1Sϙj��`9�`�G��0.m�A�DBv`r���~�".`����gz#�(��s/�.]����	@tq�D�����a{3S��%��9�:�B�(��XM��O=���a�+Ü��f^j�\i�{�k;�3�0`J}<��E�����+�RO�Y�%t��hKU�E�uVZ6CQUKy8,qXF�4��4�0{Uڅ�^��j�{����\U�N ��*����D�1*��p��8rİe��� %��H�֝bl�Kᬕp+Z�{ns�o��u3�
AM��}�����dS<��ɹ��|#���3�'�|`*Γ��Q�
��a8��\F[��������){�$���&S�.)����3 e�W�M��� �$&�,!��u�	�s�v+�,�l&3 C���T �Q��FmK��eƵ����#9���P�/l�x(B�{�%�嵎��Y��l���G�0Y]j�\�1J��r����x�lυgo�غ'�#9l��D�<9u� =GR����Y���|,1�c��\Fl1�&}]ɦ~B_p�K�&6���=�Qo��qs������o���a^׻��3Z�Asz�<��@~�%� �
��]�8��G������*��8�ҧk+{�N<O������@(���,�F�:)X���n�;�71k̩e�>_�B�3JX�!���2d�/1ު�Kj2:7!��jF��z�1�%�)�Lz���[�v/x"S����虩/¡f|�5����*��D�[6��̤n��́)7{�ȚǸ�Zi��f
���ǆ�`nq�k5TZ:��e5�Z�l�cW��B���C!9K�L��ͻ [���e�]�[����V�e@�I�H���4"���1�:&}��JJ��N/!��ޣ/L�����e��56��8�k��}/��]pFÀ�!k����Y<�ۓ'K4��˪6h���l8��4�Xdu��3#��13A7�4����MH��x��y�}1ce,�H��:IDT���4�+,`5�6� �+#MU��:r$�/��R`h�����[�aV����C���1K�΁2��ᎊլ��v���� _�B�L0"W[d}h��Rf��.y�������KBml�b*(Q��w*�K�2�ݻ-I� �J�� ����`��JD���������z;D:����K��2+df�t��h#=�"_�"q���Yë�n�N��쑕�V�� <��}��P��	q9O���_T�Z̗�M��l�,�,;M�V���ٵ�o�_�tk���$=
�*�zdR0�')�'GA� [�}��J���
d�X �T�<y��Lj�,L��3��oC�P�� Fk[Sb�+�΀���&��!��$ў)��s�[�+�O���� ¢��=,9�����Ď�qEt��gg��[���88�e���������mk�l{,^Ѩ}��Ǫ�B�������1���TN�7�je��j
(�o�DRr�����A~�ϡ��,�꫙��m~xJ%~r}�PQҚ~p�斧d�	m�I\<�Y�hP�D�:�� �|��Q�o�osVN�|���B�?ġ�-��}����}�2�n�Ɋ�)̌� � ������ �tHF��N�WPI�.f�����Uj�1
�ذ�d�	i����k���}�\����ƾ/��;�7#�%�f�<S��gVi턫��G����iU�"�;��-�e��A��A�%^�V;�U_�X�n8QJMŖ�̪&4w������
�����4$\��_ıs����fk��;��ȟ!��+���S�?'a��( (kZ���^���8�/Y��%C�a�-ͳF����hy0URJ�<:&�H���=�$)n>��D��͸�9l��iLK|2��d��B�7���	��(�%(�������g{�~�$����2�Ϩfq���s9"b�#ڮ�`c�� ��
y�l�[���b5F�!���`�br�����Ľ֚�+��gADI��Έ��d��+>'1i�2�t##H9Y6��$�3u�@��1��J�G���G`lqvX��3��΋����yU �þ���گ�b�\�)�g8�ԝl�.&w��5�Yc��qL@�����TbU�����GD��4�uy�[�q,����h��e�-_фp�V���N��ڢ8*x;鄛�֯)�1�9y|Q���-��a��D�Q�mTqyl���[�2%��3.�+j��Nm��8��{��U8�ws��ElL����;�QЋ7c�µz������E��F�n��3y�n����y�q�.�s����4Q76	��k�Z�;ԃ�����)��_ǫv@�������"�xY�|�k�=�����l�ǆ�h��G2V|WDt�(7a�E�`�Ey����O��1`�*S�~:���Rca=ذ�,��踍�m�^�-�I,DT�9Z.�b�^���id��q�
*ČE���s*����-pY�v��=43��t���+�c��1�cv���^���r��k�Hh|-�������ll��{Gߞ>h�9 p0�J�!��I��]Ɖq���|e��)�!���y�����>/sE��` �3.N��_�:��d<�k9��z��ˠ�oH�kT`�߯�p�+� ��ӠꞀD�^	�k�!..<�Y��8���5�SI&�\���.#yQ=��͂�byNu�?�X�1�]7�VGK�Ű�o9u��A����*;�=A���{��q�m�<>�BC��O�4���W7�`�fq�C�	бf5 �n
�,
��*����$�ӄR��mRډ�h�P�`O�rS��{湻A�,]v�=ǹ�&����O$�>8I��n�E�L¤�� ��t�~�`(ّ�I����)�?iL�f�����A������k����hW��5Р�z�\6.�*� }ӭ�äҋG�����/|>���T
.B�\��zeb�Wt��$Vx�81�B�&:�Q#=kt�w�������>�<�Z��(�Sɐ#{�K�ԣ�f�[u��v�{�������!�M��x�^<RT��u�����$�9^�Y�����q�B+a�:
1�*B�f�_��Y��?���Z��os&��t���R���B�0T����9"L�~u��e<��,��E�*S{FO.�FL�
#�2�88�bVQ�@���0��F��cۭ��2/Á�Ӄ�+�k�7��icѦ~c�?��=4p�1��'��N}F(�	�{2F�� -��r�B>w/��l�5�
�=�[s�jw���Q܅�*�n���7y�Xz�����'P�Ӌp��gD�и���V��dp���M�*�u�����f���0h�-�#G�Z���Eo��~��V���+u���<�#������|��R�{�� `��Uz1W�F�B�_)ٞl���Z���Pc��Q�K�����. ��z�0*��~��C ��'�WT $ǈ���hc-��]]`�_����%����NB�t5��p\��8J)<���Rқu�i��.�����Q������"8bY����ٔ�P��Å.�R�GL�)[��w���e c��Ge0�[���h�Z�y.;1Tx�(ev��U����p���j �4��YJg�Q�G��K�˜���b���@ 86m�Vj��wM;67OH �����%��z
��������Yhբ$./ttX�ā�r�>��:e�sg�U��^�u~�{@���aкD��\�����aG�Y��rsV�X ����7$~&T	��+�v��S�}� �Y���}�R���������٦��������=�&0I6E�Mw�Be�d�h5�>�7������X���C=��Y��	rHw��t�$��_9��3��M�2_~od�M�"����Lˢ䯥�|z3,�QT���f�JW����X��M7F{ɟ2E�ş�wJP//�H?Q}�g� ��4�Ԭ�@?�.0x[s	�'����C�S��T�2�=:�2/�i��_FĺL���{�f��:�,�!pn����Ul2�ƥ�1w@��ϛ���<�m�B�빾��>s:����u;~�&����T���9�tS*�L���emT��lG�������8P�]U�i�����p��J\M5�to,kC�>�,�L��
_�\�na�]fF�e�o� �Y)�ZZ�,r�e��W����p�Du��6� ��y/����g��{V�~�EQ�;��U9hr>iĜ�3�9*8`����@0�6W�w��o��o���-Ӊ�*896��:��|�}���5j�Z��խ.?h�|1ڄ�\�$�#�F��xGs@��q�~:�^��bg"�HbX�b)�X-���$G�~_�Ӄ��"��$���Cw�Q!Z��@�}�]��0�٧�i��z�Q.�m�$p��|�J��'�P':<6��0X6�]��@���Į��q���6\��d$��,O��%�����ğ�}�`���S>�_É�m���Yᬩ���&��#_� @Ez;�D$z.�@�DO�k�p��,��u5��֯�e-�-�n��ZM�ٌL4+'l��dKWrT��B~Ő)Tbp� !�􏪰�_I$������GM_��s�
�z�,?G��/KD0��+��J�_������Ng���de���[�B`b�&�%��62��0dx�n�!���0���^�l�	\��bׁ%�u �Y��z�t�&��Q��ch�E���UD��~��N�x�#���}�i4��J5���P&�90�K�{�6�7�<��Š�&@\=��� ���p��
�U�����6Q�vN��M��:���O�{*�p�R�ÅFr�[��j�/|I�)�5��T	L�2Ρ꥚W�i6?<L*�����"��!?z�	���n~���=��şD��F�3���*}3�vk'�vT�4}��}����d��zV�X	B2�+z@_�L+�5j��j���d�����S���a�V d'�2�r���S&T�M�բ�d�羄���Γ%X*-�7y�si�_Zj*�w��u[,�e$$�֫0{Ɔv��bH�.B7tk������%?��ƾσI�C�n�	��"!�$���o?D�jC��F��b����ȣ�\���D� �q�d]V,5�ĭ���-=hA���!TIP �������L����N�mS]�ɃQه�{�]���W��%�0���A��N��l4)�>�ق���S*��1d�A��~�ސ��4�;Q��"lW">^�H]���b��ψR�	U� ?N�����g�x�T�D#�	X��y8	��-I���̓�f=���²���,H�r�l��3Yr�9�����E���US�j2�ӧX_oKw\����kQL7t����ux}l�*drDu2���r�OX�R�ZQe�oq�f�������tt��"mR'�Br��͋���[�W�4�L���-�N�p����4��[��hz�z�?~�Xq5�TR4��={�Uj�1�����1�tr�cX|���3�!���]���3�4�-L�����ހ~/λ����7hs�%C��x-0E� �A!Q*�ow�Rg���q#_���Q)~Y������EYd
��G���@`�Nx�1�椻�65o�ʘ�gt��$�J�2��-q�VY����I�!���Ȗ-�EWM4�a5��SNG���1V���Yz|�~�����\��,F�w4[P^B-�7ƞsw#���[4t*������S��=�7vq�'����?Z;~8 �t�t�J��fg����qg��G���&F<��n����2 ��AM[UXm�������fW4ie޷i}c��7�y��,���	Tu��6ַ-�t0��4��1�G����W��DM�����f����IB�L��D��ad>�F��FD�["8�����:d�{VH�7���ӡ�{��@6J�.?X;dB��?+#ۓ�4ѷj[pG��Xw���7�6f�Q�tQh�U�7��/�[���KfN	���
@�_��D�Q�(�����Z������BQP��[S�_KQ����ՒqX�g$����B9)l8��gi\�.+]��,kǎc\��us���O��i�tw'/Cݦ傱z�_.�~�:�=��<ˠ�sQN$��%�����~�2�u,�J>� �|�f��K!;wM� �΂�� ��`�\n
-����h߭j]kf]�*�GI��o$��B��^�cϮ����l�ذ���9*�A���Xe�0�#�YD�'�rgS��X*=��F�OS8�����PA`%�ZLޠI����%YT�+T�*�m�U#Â���d��*"6���F"�����x��`�Jp�Ɖo��nO\z�
��޲�y�`����U~I7�&��?�p��}3�~�]�{u+���qy�ۍ��(l��uy�68dbK���XQu��`N�>ˇ�(�&85�Z_g3E�˳�X5F���R%C��K��-Mڞm&�2Pu����3i-��e��YҌ�Z�/�DTc`�ԟ�쨗�L���b@n��$������Z�7r��������w��Yz��~Q::#����yb8k�J�|n�$K�W�;�|��֟V	�*)����;�[�1�+k�V_¡���S�|l��"\�ȧ� �g���ǉ�l2�V�C�e���d�
dH]�8��S1�	��<��~�����6��c��)��~S���z����ܷs�G�`W��P� �hD�u@^��B�7`%�$��P5��iwW�	P�Me�}�i�Q�!g������ȣ����z�|�1r�ĥy`s�o�S+Μ'I�Xi?59쭉��L�{��Jg��dj�DD����d����0�n#�n9b��e����v)�eYp���]bW:���^�|5"�{G�H I)]o�,���l7�#橩�d� "T1D���+l^�I�*�D�:Y ?�g�T��dű��.�@̓,{h�LI�1B��~��{:�/��AZ���O?�t3�V4Ͻj�_�j:[�j���bȼ���,�Bi����O?�� -��m�-:�N��8	?�]t{�l�c�K�8 ��2;o��8�J��ި|�D��N9-�Q���`��d�p���ؘX]u�O�Cy�z\�T��kG%��b�G70�D?qr��9��p��"oA#gf�Q�O8�ɔx�Y�{�g����#k)�ekC�s��W�t�����	aѹ]��{���X*�R\o���X&�K2`С��SeRG9Z�X�pe�����JT�,r�7��"��F�|O���&�{����NE� o�Nq����0/�;�A˗-ď�K'�h(�B�#�%��aDm��9̗��۾ G d��ͼ$M��н�MV�S�SX9����M]{��Yf�4̐z��:�%�k&��^(4�^#J����AN����\O�B�k�nR-�B��u��e�dcl�b�3��� c��?�ϢV�T��#����(����I �#��<�1&q_�d�T��4!NϺ��rx�B%�td�`*�s��cm��H,�y}5��K��TdC�@h+{k~�m�_�=��s��&�;?G�{�xz�Z����e)�1���R#�̅��h[��Q�U�stl��.��5 �]�ų(��N ��P��P��k��1�GTw�s#�O��۪/���C�VH��6[�;�O�R#}O�6�ʧ�M���߷uS�}g��WBl1R���+�{ڴڭ�D�](�⦏�o�,����#l:�Z�
5K��pX7�8�M��#߲�1�;�&[lCr�H��/p�J��P42�C��i������d�ӽ���:eň����u�΄j��ե�T�+�n��N�/��pߐ��D��v�֦��	�䪕�y8H �}���+UC�
��&E���`���SS&1,�'Ť��~�fe�H���!���Uh<淳�k���p4�$�W'�y���L@yG��l��RT�G�����+�&y;�%��7��*���H�S[ �����Қ��j��6�����r,9���UZ�r+�l oYus֢�\Pk�t�ܾ-��f�P����	�qa�G�%r��W�x�뉟�]O��p�Wt$���
�qRO�X�<�N��"J�&X��l��_������+,���nc�����fe�:'�9����p&�%&��@@�2� Q�m�h<�S 9'�!���!=���V��잚��sI��)�-��㦌�z��`-�D#����,ӽ䋤�/⩁>B����؁�w����|kq.���t�i��Թ\I�q��\����e�o�F�n3��ǻdD�T4�:��:�$���ė���(U���-c�/^����Դ甲�[����
X/���us�hOZ�֜ӄ؈PDsL�O�Cu�[�l�e�.&���2�M2~� @%v%\n6m�+��HW��	�W�?��Q�G*��âY �u(k�č�	L��gH*��5��~U5��s���k5�{��p�cAj�6�0En�Q.�	��U�L#}ͱ����U؄h�� J�
����`��CL�M���s��c}�1:��J0�ędl�v����f.o+�~�fF�jY�i�r�k�;Gg҅+���?$�u+���IǾ���E9�B��{3�`��	I�]���[B��m>v^W�ɝ�Vqhn�eJ��0���q�DW�9��o9u�S�O�r��<�H��K�N���d�[�FC�~���T}���?YcW�4�_�N� �o�Kgf��8����-N\D�/+�B���������x����h�~(��ڵ�;��@�P���o�Û��H�W�3�v������y�wi���	�(z�4��R��G�\�#1��v�U��!L����e��� ���n;'�&g���#�YhV���.�P���kb7r�}���h��D����g��6�;S��|,Ko��O���R/�u�/�{3�Sy[�.ʢ�P��K��y!U�Y�ޱd��_�C�
��9��	>{Nѳ�߇�v�}�oPf���������$�ꆜ�_M��78Nu�׊�K����!B����{M�W#ԩ�f�4Zء�(A;�m޴|U}4=�2a����?�����D[���=��ͼ�єG��%���b	&#9�%�HI���u��έ��� ��jBw�
�[z�/���x�~����EP/����J��tuO7g~m���O�8�+�f�V�Gc��M|�h۸�	�K �\����uy6���T��pȱiW^>��/���n)����><��9Β"aB`���7i&�8f�W�_��M�9�����'�S�Y�̆��"����c�d�L�n��S��_dl��Ѩ����uW�e��{B�&�h��������P��p��-�D�g*f�@�aw����u����s�MPRd�^a��t5���i0	�/sHLZ��L��msS��M�2����W�_H	�^��k���3�av�17���Ö=�c%�,贉U�VR�/X�$N��-�Y+)�k�U��׎
������̸�85�1��^UVsk�d����J��!���W;'\~��WkoU�5��V|��tȗ����Xl͒5�i��h-G�.��Egr��v7�JB�+e�È�.ܨ��
�NO�J�)l�"G���\��
&��U�n��˔O��c��MLj\I���I��''�^[	�R���T��c�v ��'k�@��@�p!#/��/��3ȯf�d�G#id�c`�[�m�O��_�u�1��,/��T[�u���[�[��/�Sv��x�r/4O �D��FtT3I�E�R��m�~���՝ܬ�>��z� {�����$��gC��65��^��e��k�(HF$J*�E�-�D0XTy���mw�H!֓Y����B���;-<�Z%�q���2�O�-j�֛���i::&�3/0MZ������>!�o� �mX�qJ4|�'ݡ�Y��3Ʀ|�����ҏ2��q2�+�2f�Ev2���k����a��P~��}��}2pVzo��I�&[a�m
U�᥾=��{[ʕ�xD������7���֞SET�Z���W=T�8������>q:�l���6��z$rMJ���uW�u���S�����:&^P4��@>B��1g|p%2I�-�x>�u��u�l��XCf�b�O�!0Rd��7Q���� >�����0$DZ�O~/�&:�^��f� 1_1?��2J��-����}�u����X�
S�&eH�;��zc��;R�$����!�C�#����6�ǩ6��Jo���鹉���0&�%��N�|��g`��m��k�ҝ�z[��h%;�z�+�z�~~}B�D��妫-�3��H��G+����@I˄+/o?zu-�f�@"�И���t�!o�Y���p��I�ٸ��@3�&1�+�v��!�u��E�D�F��<!��:@������<�I3�X�&7�b�|o��r[�ݏ<?6�dW�� ^��:Z����\4T���e{RN�\���DS1w��=Ȫ�u��ѿ��x�Xue�3+�)Z��&h�ZG2s�:��=Er�şˆլ9q��>:nwK�"~8�Co�x�?���j��uv*9�q�TC�Z`�(�Q���^��'��ˍ,GJ߅�����A_��L���6��~���b���gPT���ߪ9`��,.����Ren��g�_��زh%��D<��d}7��csH�'u�5���m����m����4n9����Q�T>��!�}qN�7c��o��(H5d��N�#���DO̨J�<#��]j¢,<{Hd:H��x�~����E�Z��1^6�[-�׍�T��i��������"���$��/L�7g��P���zbT!x LL�3����&\�I05\:�+Ig���!3<�Vj��ݣ��'���F�˞F���A��7RV=>��'��t3���K��Op���I ��udƖ"��e��8F���8���d������V��}�b�1#����/����65�$I|%Z$b�AϨp���S���s|���7exD��+a�1��<u�NkWFaG#��j7��H)	�E����[=A������pGCS�7��q7��>uM��>�T ��N�[�y�z|���'����ީ-���+A��� &�N�k�X��6l��U���]��u��U�����{��(��R�B^�Y�앰[��n%����Gǌa���u�/���g`�t���J��6�`�N��V��k$��V��"9[�@���d�%����\2���s§PY�TxNe����p�5�����(��τ��-���nN	+�XJ<t�,��&!�`��n�`����=��5�k.�GuTA�%H�1�]ܿ!�(�`�i-�.�������3���1�� �&P)�~F�+?��
=�ŃM娈���-Y�s�Y.�R.��8�K��hA� w�I����U��$e�*�P'zy�C�Y��fő�	Y�*JD���+��q�������X@Sb k���Sb]r��Z���H�s����3��2_�^��������W��|�&úv���aǞh^ɱ(6/��:��͵#�{��;�uF}"�ڑ@r5�_� �o���V�8=y�FF�^S�N��������8�p���q~�h��7��v��Zx(���j�$J{+����M.]��mU����f��Hs���d	-Lu�d>��� TtE�	ԙ=#EXR�B���y�˯ m����&����IZ�����e��k�IbS�3;�sl���?�i���O#>�Wi����/��C����EΣU#��$��vc8G���y1:���7��M^.I�H�m � �j)�a`������KN�_�B��"���Vx�}A��a�je����$BWϽWf��">���Ux�c�ڰ�����$㨫
_Aoz�6M�����/x@]/V_�)L B�P��41
��w!�鈜��&��-)��0���d�R�5m��������ԉ2�9�����j���[����({��A$�*$�|W�l�>���������N��'�\�Eq/t��\Rh��XE�,�<\$���*�\�s`2��=[x���đ�4�d�o�OmƋN�:����\9����P�x%�$���+Yt8S�XG4X��Z�1�ݝmBJ<�r�7�qݹ�;�w4O,�+B��R�A_���L�'����T�F��f<�h=d)%��F�[���Oo}-�Ng��v�r�	��B1N��Q3[2i��~�	�"�\#�K.xY���J�An/���;;Wu#��WJ"hR7�\ޑb��\yܑ�q��D9Ǳ�t�d���`�w����� �t�*MdN`�l��yr/ jR�?9��)���O�ԁ��M���գ���/���@��ͨG\��Ȩ��N�e�+�m˒n�d{S��3qF %���5��N03\��	}u�S,�p��+!B�-k��q��.sb���	��^�2���
2��Zj��hm[��q��D�2M���k�cjY��C����'3��~6��-H��@�˜�t�6h��(s���>�^+�|m����l��e�D�-ȑ�(	�%
���E����*>?U�Sk3|����+dՕ���Z�>�#]�Ğ>0"��J���m���L�����-���s[OB�R�*��:�����6����/�	f�Dw��e�\����Rr�̟}�و��A�(e�i${�/i��;(���$��=�K
���)7��vF�2Tq*á��8Z�@�op�9�ij7�ȃ��KocV?@��_EL]F����#�/ÿ����p��:���e[�QY*��lZ=ƹc\ߞ�7:犙�-W�[X�ט�����j�qz��G-O����2�B8���b���xK�k|�x�[�%h�$�EA�m*�|`�j)��c^����NH���޸$����6��f�M ���F�m�Y��̜P{�&0�5H����X�HR��n�[E`F�m&��f�a��� T�B2=n�#�Y��}>�!�����"xy��g�tT.g�~�����/0 @s� �k��/��I-�� �D9��F����ɔh�R{�%�L���0v�<���/�z�w�B3ME\9ΏOr���&r��\T|�����O�}N�|B��`����I���p�+>�(��L�ã��-��#߷Y�p$��Rث�
UL��+�l��+u@4ٽ>�T�Ok>)3�WW�"�dt�b���) �W�z������9�������l�m9��=9��Y|	��/2�]2�[ �R�f¡������������o�������I�d�Po��� �����I�a�E��RVJD��H'j��o/)sW�8p�rz�g�V:+��U�CK ]��һ���3Ђ� 6��,zB��7;Ya�` �,#����|�{� ~�+ϡ㷬���+K
�k��,�7���C���32�"i��!\U��[�P�$������ Ճ�t�����n�Qڽ[�����s%�3�!̀��X�r!#0�w����=�a y�Y�1��4N�� Bz���i��~#�A(�m��\һ;D�L2����)�;ӽ��9��>��윁�{N�����	c!���
��A�T1o���%������r����t��<W�q����\|��M��pޤ;x7�G�DR5�a;�0K���$q��c��W���d�Q�v�1�/����^���c>�_s�8qA��&l�|�>��X��~@�!���86�XK���ٯc�ۢ"@$�5rf��IqMɸ�"�>cK���k����b�z���&��O�(�����Ҧؽ_S�x&�3S���5S��R��e�q�W�$��/�\1z�?{��W`ѷב�G���h�����E	[2�`����<TT��)���H��\�O�T�A�[s�@�_N�����ѪĂ<͹1t<���,���\�za��2��� ��(��	��u�����h~�E���7�X&��ܟuǃO�*a�ILG|���e0�[�NM7rȉ<hK3�|L�D��#�a,z��8�2}&���n�!��5ڍv�1�(�kAf��
�|X�48h6&�؉�+T��b2z����삜
����f
F�(ul�@c�q,2A�p��5cҨP�I� "[��>0�c���^ZH ��d��#�����bja$m6_Wa�͐X]�]oy+B�u�/�4��ᠻ���Ű0������a���b�)��yx0����l�0�߇���C����m��t�/���K9A�)"�fpooˀn }
]B�Ӈ�T�X l��g�El�=K/�,��"�A�s�V�0�=�ta�Jʳ��%�c������6}i�Pw� )}q�XI/%�o�������O�u)��+ԅ���!�N�_�[���>�� Gz��PLc����Z�|w��O�T��t'�*	�,�I�S�,�.fQd(�Rc�m
��z��=�W�<���z��Sm�(��JR�e�}W�[0&`�
	����	M��'p��&H�7Xt�	��=:�䉏�C7��~!zI,���-�Zw�onBU��%��ϧHŭ ��x�la�����MFEؚ#��f�țN� �?6`��(�{����Ӻl�ô�)��A�:��UXgI�߫t2e�0�=��C�a5���i�.v�6��B�L���B�w<5r���Iz'�7t���������9�df$�,��q[?�ѻQ�G�֯'�W��6W{+8;r�r��â�}�c�u�Ja��'���al��s����,?
��dH��J��2,�h�E�2g�h����� ���0�+A8g�T75�)�T,�� �B�t($D	`q�?i��ar�Ʌ���pQϞ�RŁ�˛����+�:����V�T�~��h/�p7�/"EU�A,z�ߕj�M �'W:�{��B���,Q�pn�wC��J�2������>
����bߟG����-�Zg`=��Uz�|���7t��]sx����tJ��aR;s�#��ژ�<�m��b6���#�U�a)@fǡ��N�e~�xT�?1�Xn�Ѫ&\�.��<��+3�P͇N5� +�)^n���M�k�}�����`��'td����@H��f�u}}��x:�i8ކr��^��|��������AO�ma�M�����YG
~u���>R$Ic��LJ�_yk�`/�{�O��\��aJlU]�a��:��]T�Ǧ������ #R��' �Ubi��9I;�}���Y���γ��Ő6̶2]K��cx�{ڙ��I/Z�^��̪���2�"��yH Ƀ�7rX����Z΃���	�XZ}Ũ��S�$=!��N�P~Vd^M������=���j)$xn�1m�r�FW��%�n5��(7Nr+Ĥ[���t��3������{�C>ُ�N�FL��!EQ"MC٤�҉��/ ��ʣ�=@T��Gly�(���֞��{�:bS3�_l��e�%�1h��߲T�:Ԯ&A糴��<aj�s���l��2?Qe+�r�Y6��=��%_����l�,�zO�c��_[��Ý:7 #��>�'H��
K8X-"@��#�p�kʴ$~��Ta��|���w�Gg�`�g����TBwY`�����xᆘ�ˣ����~V�>@X�o���M6ne�dЙ�߄��d�z�.*��������h�Y5����O�a���aE��J^���zR�j8��wyfU�s4����f 4�ZW�8�����q\���E�q5OB��Q��ErDʿ���P���*ey������Vf��zi�Ё*��2������
�[`1L.�%q�Y�1:嬡�0�th�gv6-��W�����W{�h�u��I��7H�\��ї�<��	'iDL�K�wϕhE�5ߗ9~�o�a�F��ZK��$���S4c/��Hs&Ό�h��)�M��U�Tf�Q4F~TUa�Vq���kGaY��ctT�=u�;��Ǖg�?��C&�=�7��#%F,�Z�?�1��[�Kx]s0�i/��uOmc�J��ϭJ�W=�yu���پ�F�߃��˧�K~�@��؇��!�5S�������n�^�o�3�2j�%��p�;O�p ߬P��4K��� �ʧ��S�eerk6�Ӓ�x���cX�dI�	�^��]a%	qe$t��O���*�w/���Dn�c��E���7+Hގq��A�}�J�W��8т� q'�]��,3	`�x��}�"��Ṥl�$��(��i����F�6��AMd�8&9>���ӱgB�������?����� +����Ŗ��N�q$�q�+�X$�[�8��=v�0��/i>��4NC��FxL�`{�����/;z�|���+@z���    o��9��i ����==���g�    YZ