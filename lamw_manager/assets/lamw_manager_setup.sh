#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1304148244"
MD5="4b75ab8e46d44eba0874ca670d87cf77"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23912"
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
	echo Date of packaging: Mon Dec 13 17:12:22 -03 2021
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
�7zXZ  �ִF !   �X����](] �}��1Dd]����P�t�D�"ێ���RH�*r��,v�4W�0�_@Yt׼4i�������a0>��[�u�7���f��߸�e4Ε|�!�<].^����GT���ӥ|DbL��y����K5bs��e8ɧ���ą돵���o�v
���WQA�H-2L�Ett���7jM �A��Z�&��q=�l�w�O�A9yD� ��^�X��:^���4�lCvkF&�����ɥ/A�ǁ��*�w	���)P��(kՂ���G3�b�É��I� ^��F�^�s��C�չc������O�r�Q'�nH�ݟ�U��t�a��<���B(��T��� ��/:�D���I� �d�I��G,��|7i�U�֩������ƒMpٚ���+ *y��8���i�Oݺ�%������TG�GJ��@9Q`�}��^�CEE�i�=�_��ȩ�[Q@#����I�q�0RrZ����ͫQOu%Ts&��� =5����<��x�N���4)�u3>��ᯭ �K�k�v���1�wh���f����>J�����]�_���_C�K���u?��#$�:��'��
��wbb5����E0����ɾ����^��|�[�9aѹS<�,���Z�CR�	���_I��N�lު�a''ߜ�o�w�Gf�+���o@qH�Z�\|�0+����+�n�ðD섘;|;��Gz�F�y��^p��U�uj�����z��ϛ�R��JP��`I�������6��7k,Ҵ �����.�g��]��[4/EǍ��z<Ϻi��N�;�B-Ro's�k������l�]J+u�F��^�0��|�?�ht���yJ��Ze��5��`��cö<>[����㎒m��F:8[�q��.�뎾iW�bs�3����C��y��y��W'*�cx�����;
���Y����eo� �7���	��@�C$A�S�|�I>/�j�%4�����)e���B_���֒��jEg��c�~�oV�4�B4W��x(�4)3�)ߞ�����rѲ}J�B��"��2��"ssyTw�Z��S�I1hG}x�r�z�(w�|����>�*�7^�s��7W�@��5a�H��Y���^�����aeg��W<3�����$�rK�y��� D˔߷X?�jA��(�����2J���8�r�.�
�X|(��u<���FL����������ji��;|�o�����t�P��X�lz��f\�tB�����2��O���!�$�1L� A1J���3�F�^P*���nxO���g����iHF���j�b0Ĵ�\�9*A�A!Ho�R����S�H�? ��6>ͬ��p��;^Y�Oɵ~}��fx1u�Cf;�x�+�
��H��-�T�m#��vѢ���9>lWm�zЪ��c�b�!G_jE���6&8���ryo\�m�&Ϣ�ƒ���\��+��[��e��dն��Q�%�
�����R|�3�@�����t�Y���U�XH�A8ܯ��[��Bd��Cj�v��׷�@�R�<�^��a݉G,�*��m@g`541;�RQ�֘��^�U�G����E`���qfZh�/t��%�>7��<�P�N�P��=���LUEWk�"Rd�ONX�e�zp`CG���Y�}�4m<gW�a�	��"�k=��s/��u��'��B~������q��+�s8L�72�43�������BC��j�$k ��TJoNE=d��z�3���"W'��� ��_��0R�+��z*�e��Tc�e�D�ֿ��o�p Q�w.�}*����#R�do�4	8�$RR~t�b�w� �v��@g�ܭZz9)Ң{-(W����!��ڹ� *'4C��+��1�RU�
o����"A^����'T��?)as@�%�&�Xx��(���K2�^�~��q����Fx1�g�^"��3r�oe-A�)5�����0�b5�=���Q])��@3����Uy��E7?*��|?��N)nº[�h����T��l*��Wh��~i�xWm�N6wO��<n$gH��)����~�N�(~b{��+�:�#�W�Ռ]
���!�!Z�[�l����'�ȿ]�_�~14V���#,�7Go������cHs����J{�h�;�t�Md��5)	���ͫ#1�u�OX		�� �x�*�XzO _{ q�:A���K���n�Cu�[P;""oP�@��X�9m���ϓ6��I�ʈ!��͛2+<�+̠���j�zZ<O�����g�6=gY,qy@��l���{�6L��Y�A�z�~MI U��u�fp���́D����%v��j�NəM�b�A�b)M�wQ�]��x���D!�Pޅʘ�9�o�o�c������K5��k���zu5ϼ���wM��	B�f�� .��	?�$8~v�>I �\��@K �������5r/�<�r�^���y�D�
��m�13��L0|#�O�۶*J,�4�mJ�Q�����G��}&J�fH��-m���Z��L��7G|b�=&Ú�38�"���ˍ�w������'QeľP�QS��9F�)��8�͉���(�?h�m�!˨�>e��F�Z�A�8��#E���c��r�
mJ��@D�P��	2�&[F�ݿ6�j,�g��
*!T�Wl�y����ҒC�PX����H��xx�r������ WaF��/W.������N�o����S`� UTܭۺyk�R�v�"i����NRA�o��
��`�BpeB&wm��0�����T�D;%#C���A���x��i�%u*d�L3@C��1���kɹ˿�Ŕ�Y�%T������E�	__��'������8zE�w�4<�l��n{&PR����u�mq�	?H�dA5�O<�l��Eo��ެ�V`�����6U9�+�]��0I��1���14��
[p��!���9s}�t�1ܨ_��P��U^~~�A�2�\�L���T�20�W�w%�̀Uh�K�2�jc�)�86u�5g��2�JO����"�Y�W�遵��0�&w��Os+v#a�!c2(92��}��a]�T:������>��	Ts`��C�	�MD�;�Z�x t����Hn��q�k�A*hW-��b}�pz5%���\���s|��<"՚����M�����?�����`����������ءV��cI-n����
��B�Q衼
��U8k֦P4I�>���'�%�	�����9�]��jTfR�S�m��7��l5���3����\r���Y��?��Y,p���X��E�,-�s�[u�mJ��$�	�r����@�ɬ矏l����+f@'�Q4�-�E2ɷ ���;���hY�~�;��FP��S?j�*B�+�f@��NZ#�XJN)'�6 ��o�dב�g�$�p'�P5��ġ�8���1V,ɵ�<ȵӍM�&i��l�R���~��y�v�'S�:ܦ(J�������v�;>�LGd�1�z-{�l� ���u���$��wu�t�ߜ����^KC�}����(�/��Tۋ���/'� ���|�y�qOb0�������<�{
��IúM8}5��6i&�ҝ��q��Eϙ����>��� �J�����Cc��K[�n�_KF�'T�<� �K�+"k��2�Î� k�o��_F7�P�m��F�2����sJBE�ub��-�d���Jn6q���+n���9t8��(J�����=q�CK�_Q��_���[}�=Ɂ-�%l~
�jj�/c�k1I����aIEe���ѐ���h1��o���~���Ng%�1���(L��;rڳ��K=� ��b^��]�q�`��-���o7z:X���JP���t�BAS���m�0�P��{�*I�m�ɰ��K8x�?�_"�v�OO�Y��<�����Aǟ��s�r�Ұ9�_����C2�D?�w��_�Ѿֲ!l:�E�l��)��Kl�^i�7��,�s�<��z5�X��wP�{OPo�I0�A8��5�}p���	����6��D��հ�9����:��x�npS��i�T�rC�s=V���Ϸ
P/\0u|���ß4A�z:qX�+G�OrN�J�r� ��y3Q���� ��'������$'�0�	U����^�*C>�	�-��@�X�f{��� -����xQ�Dq�_5�b\����(L�2��y�-���#⭅�����JCd.u�_���B"ս����&�p��~Jg'���^��� ���(,rEl���e#U���2K�*��m3'��fۡz�Ҋ����ѣ�#A���fJ���[��M�D.�cZJAR����߭��lPv6�L~�؀�R�����]�Z�ݔp*�c�>�������GLh�i��0�n���_��p t�/cUk�����$����F�?	��)gt���S��@��b����0�t}�>޸�e��I�H�遳���Q�G.������� _�}�Y{��CA	8H�"��T�ߩ]s���:e~�{��x�W�?E�y�p���=#|%�?��^k���$�?1�h/�Y3x���Ę���Tԕ�_6�V���/)��F���\YPV��kH�@E\�[�g*/���'bMj��A��k	�NW�=���S�x�pg�ϙ�s�t����M�C�p�O����u����}K�?p�O�Y���)��&�&���k���w��.l7 ӗ����π�k��ku�T��T�)� NY�="[\Sd��m����z�|�J'��Jޠ�^���\,Ty`�A����g;��F%M#C?˛�����΋�܀�����8���d�\��=��v�~(�}��p�_���Ŧ��~ʨ��"R�~#�ZDO�Z'#a��V�v<�K�!ڲ��N:uk�P�mUP;

S�T��t �^�ڧ��2�������߿2��t��X9#�]1S3X�G�NU���=*B0�����z`��ǉ��+�vg+�89�M�|����D��0�4��ׅ�ڞ�z�K�h���l^_�%n�ާ����;M]�B��O�=#���og�(vH&fy�$�ċ��:���F9���G;��1y�}F�T��Ѝ�u�E�����;�N2y�Z��鋣�\io��#��D%jrCe/���\�M׶��]TLW
_N�#����O|����z���J����ת�6�*���US��iv�{3[�&OG��4���Q��@z�`�f��=�g���#Mp=��21���j0h�bg�1��wȜG���H�g���]�CC��n�	�'�M�	�[���rCS��#/5i���������N2�������ҫ��	���|f.rSWm�+�Z*�r����ތi��us�k������^�-�s������g�i��̲cˍP&e%<B�sԱ<�Mፐ4�Z��!mJeg�a������|���sTB���c�a���`�ǴR�
��-���S[�I�r}�h���y�\�3G���S����OK̚/-�ѵ����Ձ�\�.��o�˺{��
�n��*�,��p΂F�o����Z�_��>���\�-4���.�TZ�JR8�)�熕@��Px�|]U�uH�7;y�u���n�`��MpL��Ǟ�;NJ�������#�G�9��p�lO�'m)�����Ǚ��HRb͵%���F��M��>:���� ���vއ$�}��-p4���Q?��P�7b����l�ͪߌ�i)��O(�J�-h��9Q��n���ǾA.�4��2�84Y:��VO�{ו���k�ύ\4w�~D�p>�Y�l��ar���BN�e�E���2�����g�ލ�Vy��@��ꨵ�@�y����
l\�� ����/�J��[s�
� ���7��Qh7���kdg�_@A`��g�������IG���o�d�
�,:2�>�3o/R#�6H�-6��4���Έo���D*ͯ��U���$x.�����b2�
d��C�sCg���ĭe���ݰT"ZTc�a$p����d�W��N�3I2��_�GB��Z�+\�U��9��ɚ
8(��F�H�@�ו|�J2An~�r��ב ���`C�J�.�W��mV�u�ܽhхr�ъ�H(\d#��=⑜�R�)6�1����X믖ʻ.H�mr���"�<�xb՟��l]�XI��x�"m �)�MN�́_����e�m+EO@�W,U��༵�,\���*jI��V�)w����;p�Grϱ�E�2�X��g�9q��m�Z�
�p���g�Hӹ��w��4�TCz�����[�����/���q5�r��BC��'3���yI�>�<y:���ؐ���{U�-�G�e:}4�r�&Hs�+mP��w)��Cx���qE�\T���{�ѺV�������:)V8�����8���S�c6.���d�)F�6ץ����E��;�s�j�Lt1�D���&��AC��.��h�=8:&��p�k��,������(������Շuug̥�e2�%>%�o͋�w$��IIs<|͗�c��g��vv���&�>,��T�J�m� J����<��vX�	�.%y�X�k�˚�Uf9t���)Fhբ�C�_E87ah�d�rE�Ma�ԭܜ��	������̐��%ɼ�i�Ze���O�A�^~�#�6 V)��%ސ�O֊˜��b}M��������y,A��tkw��4r����;��#l�K1�R�P�=zޟ�̏7x���;�"w��%��r�Z�e*r�����yq��ܡj�3j�_^�QG�nx�L�=��k><z`V�!wъGq��4yS3Ի%�~�õ���W4�)1�ڪ�(Uq`V��2Pj��㇆��N+�p�:����H�<�,[��&EW�I�J6W�3IՆ�iȤ�W�e��i���6[��%��m-�q�j��C���4I��2�,D�����D���
��aɹ/i��	��c�A]D�;�R��Q&��o8jr� ���7���B��M�hA�V6�X�tG�Y�+�p���J��Z�a��:�햌O@�P�hY]��9�PF.����qT-��>9k\�oE��` �� р[%lz��n����)"��P{Bd��F�{�H-���{�8yӏ(&}4@j9�7/7�2���s��%
t6�u�c~��E٧i{��OjP�A��?��|�JD��;�E����ӏsu+6N����3JT����@/*���Ts>�ǁ'��j:w��V)�����-i�F�y�$��+n��)>"�A��ۋ�%�����������:(6k�a���Y���!�B_� hfo����uQ1Y'T4\�z�}�e�a���/�/;��NP8;��r6^�5�1qd|�	��?�8��_~��i|U��Ɩ-/��-@&<�ug�d(;,H�ّ�ޯ��� �{�k#���������xkzdo<��Oht���P����ie�t�$���Qi�nMu,:@s��p�6�)�)�2I_BDF`�k��V��[AMaǖvR\r����F�g�A$)�"؄���$ᖇ�5�GK�Ә�(�^�tg�0��CG7TJ)<���-� C4�v��HQ�����m��C�������bq��'�*�Aϱa9{�>r��~��}K�.e��A��~���} ��RP������"�r�B��-��_UGЂ�5������,<���߭�h�x�R�S��J�<�}��K{�Ѳ����\"a���(�k$�䎡�\>�A�A�Mp����[21����(�p��n4�hA߷#ph�s��*�,SVŊK�����	�~;�<�l�8�
�:ޜ|b�P���)���;iX�V�Z�7m!
rAy�KI��o(�N��qs�?�uAή�2�{�θ
��~'�#�ùI�"ɩ-���cT��8�ob�^��`N�Xؔ5ٚn/j��p7��Y�M����,,-ٯ���gdqr��He����!\�T+��m��O�w0F�e��v�j�rte��LY��	E�#Vʺ�7*�B�i�e��O2r�9����Iˏ��	���'ɠ	a�����P���BP�-S��Et�J�V���ءA*����+CPr�-_��zn���FL��ϚM�m�
��w�\�����a�\`&��]��-��-7�y���*��Pyc������[Ѻ+e��(�'q9�5#%l�|y4��Z%�O�pU���(�	X8G��D�%Z(a�͢���N���'�jĿ����l���\����q�Q�>�V�Y�>_�-a��d`��Y��&X圵�9H��o�ʦS���1��5·:Tx�0���h1:�c:�C6잩T� <C���,���+J ������b��1^�x��������XPL�%g�X�቙��~�����.����>�#�]<������E�m/�C���)5��~������J��죿�t�f%9����ƍy^j�5v�՚�+��i���e�;ֿ>�wk޾w ��/��G�X��AqW�%��.?/hc�2���]��  �Qfr��Wҋ��\�`{��p^JdN�SS e@���ܾ�p2��l^�oyW�*c�q�+�J���+,;X�Å�i%M�̓U)����Hޏ�+P������sgTe/��?�l���X������cw�=˘�T|#�<o�'�V/�5xL�`��(CŌ��]Ycb+gbKR
�e�+`�yx���� ��7�k:�m�K���D,E!�8�yp�Rè҃��;��[Z������1���FPW�H�h�x�"�T���)?eMH��]�ѳ�x*�]0����1���/��������Q��Q���U���W��Z��rJ�x��4+��DԎu��O%ŵm�96��4�û9��m��"7Pg4���<M�v�#k^ZY����A$����3����;��>��gI׹=v"_��O�Eȟ���	������Ӥ��m�;5��I�8A7�3��^������OW�R���<��k�h#�h��G��������&�xw�J[�~6���i~��̀<3���c�]@g���ό�Q7��ݟ�#��5�:����Y��[��_{�J���_��U��,mݹF��y^���^(J�Bʦz��.�?�(�$���~�oʉ�*p�mvp�� k�y����O���X=���Jhy?e[��#��$yl�Q�`���mŨ��SS½@hN��'kh�R�([6�-���;L��E�nt��%B��T���nx�8_�feζ�aX���M��5��p�o����)}�ޖV�����UᖟK��ߌ{��;�s<j<�/ׅ�v�ٙi�=�H0U�Aq8%����m�Ҡ��(���m�x���"U�[ﷆo���zE�YZ�p�	�o\��u\��Y�{�p���}ԥ�6�c|��۫o!v��{��k�`O�L��r"�3׿�������c�{d]�xm5
��������!n�87ɻ�����Gk�v�o<FZ8,z�I݀���;�@��C�����D���&j<?܅�з  �.���\B)�=]M�lС�c��w��gw���Y,���d��6a%ũ�����thg�;�ĥ�#_���h�x]��>��Kn�UyG5O$�m[��Y������X�'O�[fs�>�]�;�D��oX�:~�7ߏ�\
B����Y���,w��K�6e�R��\[�3�Oc\�`����(�#�2a_r��� &O"F�*�ҽ���%��ǭ"�aK�,?g~�1R�Fn��Л�ER/�Q&m�ѩ�.����?�*@��������+�A��f�t=�<���G��PiWC�L��+c��P
D�^'"�S�w(����:�'�T&�c=4�WТ�G2�D���+W�r����]�[�1��H�ṅ]y��	��C[(��p�|/_�z����R�J���(t���".��Un�i�i{aڙxGY�7�
�*W�_N]&UP��M��PԽ�0s�{벶2K3�N
[>�Yc\�-}�U+>�7���^��f��5r�����[CZ���T��1�Ezm&(�C�]����}�A����|۟q܎��f��.�����p��LW��;�9����H�miIR��֟�O���{M��ѳ��u���]�jd^+��`��"'xB�HM�>O5����������Kܑt�_Wop����_\J8ĎF��9HJ��>�AZO%yIT��o4li/�;�L�^f6)5-��|�����C<�`{<������n5��>m�/��.'Gv7Gȏ�[uj�����������I��D���M�o\�w�H)�*�B6�=���o-u�+��x�S�f)��}���/zu)l�bҬ
Za*�p�
��!i�!e9AX�����V
������.�%��Mݰ�(���R�*�����;�-��A8�4ӒO���f�2b̕r���ah����ȕ��oG�H��J �[�_R�bW��"X<7�����wJsyw:$, �.lR�¾��Yn��2�e#�%r�7KD8��:�
�Wf�R�%%�O�4�6�L���(�7y?+��� ��_�m����W��u>��'Z:�OX����q�蒔�K��N���W$�@wE��;��0���|���h[PQ(�=.E`�N,��)3�Z1���{4�::9+؞��k��q�[/<�tT(~.�\h����ht��ϗ5���\�kr ��dpuj���'
��8-CKc� ��S��`_j6��0���d�'�(�g��@��oլìFQ��xjf8�v�~�Un������ܢ��|+��YBc�z���(ܖ��ŝ��D��9��=w�(>H�Ô!]�żs0){lL�@�lfdp͕)Н���-Һ���[�ڀ��fp"�W?`D�Ψ����}pxN�+��`d�|�u���a��@�������5�"n�T�����U�>����V,��;�����g���Ɨ+���RϿ« #���J:}]��`�� e4�S������}�x�_��n����x�)&�gV ��fúr(�VԄ�4�28�
�zo6Uv��0�NX��w�)�҅���C����"������A���k��GK��Y�v��P'Q�YÙڔ^#�}�!|"�C1�9���,�c��1&�*iܰ��"6�F���$�2{��[�Շ)��ִ #V�@U���_�_\�4��w6`�h��&�M
�}O�]��p���#zS��e�k���}파T�lĝ�1g��3.(leu��o$�&��X:Eĳ
�?EH��H��^��#���P�� qA�o떼y��j���N�9�� �����$�n��{�b�R��� ��D��/���%S\]��e�#YR�r�}ox��2�O�~�u�?Mr`)	�$[����|�|U�6�0r:7�u�ڠk�,�+����(��&ߥ猦�u���j���pM����j��%t�a�U6(=W�g��Wg�º�cjWB���H"o2N�&#�ʧl����R;��g�5�D��/`���G��p���zy�%��@���q����$���٫�[�jϞ�K��"[�zl.�k���s���R�-8����tH�H�s���?�c& 9�����t�CV�O�����q�5�� �
a.�dY������6ևH����g+����T�G1�?����G'C_��<�щKq<[M�$ZiS n�CJ��MK��}�O��v��۹�)jz[A��er��ڞ�G���/�v�8��y�����{oG�����pfMV��1D1.=�����q�y�:�xO�Gz��ȍV9�AG���jgK-�k&[C-�KŬ*I�� ��=��*��,GY)�ے�)+ץ�9���	O(�[SRa���?�}蟌n�R�<�#g�6���(l9mm�Ð�����S��`Z���7�fZO�bJ����k�0�䦆�,ƭ�</#RD�۩n�ؾ���a�`材R�kv����1�ھ���O�E�ոٜ!8�}����5VGK��Q��p�9A����+Bp7�x�J�g��U���`���n��F?,_n�?+���"O��>�"��g�@- |��bwЄGY���i�9�MB���e�piC[0pQ*�h�fG^@� �Ș\�bu0<R.���:�o�H��<U�RN���z�	�_��i��]�Jİwq�৪8�����<JP�WFtv)nܾ8����_��,</��0P��7��:�P)�2(Ե�o���K��!r26#:B�4�r&���Sڀ[ ��I2k�����?�>�Jl� 6e75� ���p��ʆ���g���͝ڱ�l��:����pTs�<̌|�5FJ�x��A��Q���a8�p.��P4���gxG�ы���l_
�eU����_r�y�������"�pa�����1� .��xB���6��b\G �)�tF�> �|z��`}���}����3	d���o(���B�R�i��,����4�;��n9��G�i\̙"���T�aNv��<�To,7��L��E��5L%�8$?6���%��߿gB��.�D1�F��1�׏HZ��fI�`�"�U׭��ޱ���W��0�)~�R}Cr�B�љf��IC�/1�<Uʙ�j������ڿ�vn���ԏD�ۧ��˦��di�5�Ȓ7]�L�� ��@��M��M_�{����U��7;�E�cM���'Y��[�ϒ#�x2.��-�sS���E����B.��Km���c}+\�WO�@��ܘ��f�]�����<"���/J�w;]��
�s��1��:Ě�歜�]�n�lɭ:W�ǣ�#OK�\����'8=Z]���c���/	�Ӫ���^��+b/���2���'������������؎8x�$I]���M��v�e�,>�i�W��Eu��W�56c6b+�����*��,��[��t�h�\�g�[���ZV�.C�K�p�f�E�Mg�-�����y�T�i��ȶ1qV4��6νk���Ǆ�~�DAD ho�-K��8�|���Uǳ1�y��g�A��~�V��Zʥ�UWѓ��+��7�~9�m���垷9?T�w}�ݼg˶_�9-�����^:��%��� �(r_�V�H���B�X�+}N��DMe�v!�S�c�N,Y�r��/v����;	���Y�R�"��a*��F�;��9@d����m��U|u��z^�������v�2���7�S��2������O��;��}=��h�҆�8%����s�֜�5�/�Y��}��4�7:Ñ�,��v1����>*t[��S�H����rKQ�%�?T�ڪ`_{'Tڵ&���YΛ��
�4�<q0��sOd����'/a�ΐ���I����֗.� ��_ϙ�+��׼��'
21�gj�v��D�+����r0�>�0���ى�Z��1�j	�& ��;�!�O���4�l�6�f���2H̄��h�-�.�V����p� ]e�����xE�ސqTB����J�����Ntǣs
gJ�p�PAn������LG(�|E`�rWP;p��$�ی�?a� �{�d���1���%�U��髱 ��n3��}��:}�/`NL��* iE��:X�tZ- pT���5���ȶC� ��%�E�9��4g��Ң�ά��6u�Qu��_K4/t����;���I_�%'iGH�`?e���\h���?����**�kj��NJj7�C��a뢈.�P^��Ջ�J���{�utP�!)�]#5��ӯ��dX�ry;̑�,�@fӱ�~�so`Ȩ+�h ��ƈ�=R4�C�)��`VT���[�y�2c�L2��H�m��I� U:s���aY?��	18���=X_>E�/>l��8s�B����l�_��;�����h��U�ޙ���A�lU���@�>�inX��#�����+�ڽ�$��3��A���4ﭑ_*O�Kf�pFT$5P�L�:S b�yn@g#1�_1��:�I�������P����`m'�4���:96��%!E�ܕE˯=�\�;��av���q!���F�)ɾ�'��NBU����L���$�����$;�m���z���lP�-�T��UAK����o�����#"��4uQ����eLJ�OE�@jkdC4��~��@0�qu�a��ڎ��]v��К%V�@�� W@���!����A�~A\��#5�n�zY�%!��4)�壦U4Ռ���̯pmN���z����`�$��>7JM#�'?��Z�G\�5�R�+�46��չ(�����k��	fa$⮏�����H��ѭ�:���F�z�&�Q�3���T���=5�-6�5�c%Cm��CJ1��+�A>�lRqď���~�0?����0�J��r7\�^��0�Yr�T3�i���$���+����خ�>h�b|yl����Μ���jZ�^]�e�5B�a�ߓgb"�z3O}��7y�ɪu��3�T�;w�*��]��׎��ʇ���5��@Q��K���V��&�Ɋ+����չ}_rn�U�K�n���|ubk��ߓo+e(Y����X�
l�A1���l6���B4���m@�����,#��P=�KD�A`16������u���-�&c�H��P �[=�ٷ��ul����J��@r@��
-�kW��8� ��-/��}k�)�Ti�!��}2�f�
�����QxRZG��at�V�G,��(�Q�[@+Ig�"��D*�ڠx�ކ�e]��	�-WV���+\�X���",5�b+��QS#%k���'���ub�z�����d�cq��������<35/l���L���ם�/�O�}D�Zr�6W��j�8�~�d¿��:���&����1Y��H�;ܐ>,�}���<������ N�W]�;��?;��;_	f9�F�"b��*�[:��_�?�H����T��ٍ:R �6Z�qm�d�iPYtF�˒����&�;O�� ��@��5=���+��\@�:E�mqxi;p���ۮ��t��@�zzC���}��������d��o��H% ���:@�u��1�Bt}���~4��ňG�LĬWѤA��!x�d��Y�@�l%����*#�>���w.��]�JӨx���K��T�ώ����ծ�4����/x��n��!f����ћ= ���g�c�	��z[���k����6�&lC̼�o�`韄�+����,���3Y�J�!h5�F��M��-���������{�"0�jJY�F��d�e^�"���� �d�Դ�3_�[s��%��tc6�ʮ^1��ks��]��t�
4�����g�q��R�g��f'9�|�Ϲ�	��
��#����u
�P�c>�$yZv`kZK�d-w���k���ÛMɘC�n1)wx���o�(��.l$�
A�?Iɝ�0g?��Ӕ�8n�v��O�Q\?�� k��C���)���{P	�Y�\���!�.}g
��J��s23�ό_#�_�C���CG��;O�v�<L�LsV&���]��m'��V�HO7���cu�K@oT��K�x�Z����Tu�՝\'�Hъ"&.mr� ��##i���q
��1�.ݞ�"@�v��#�����K��}���n0����!z���j��O\YM�q>Qj�u����oE�h��BC8�v�G����@�꛳r&�b*a�Q�����s�d�~DB�D[���������6��MH����� ��wb��v�m٣��S?���~A��J�L@��h�������YX���׍��>��4M�-�8���b��w$73���?���`�}J�wY��!�eE�FOɡ~>�> B�^���w�*~vg��a�棦{�Q4�% �0RĤ���v1�"=����7瓶<dv�$*���32���œ�XTgvk�Kn���s�S�>�.u4 �*Ʉ���>��*/]�����<�	�Я%؂}�(�Vz�X����rK�&zS "���Z=�|8�T�!��
�^A���q����	�9Ͻ����z-�K�W�I���ϐ
�	�>�}$�ʳ5�Ƅ�I3.t����C�W��ސ���� �Z����
q��g��6 ��B	��'e��+u1D�Xy��R�R;"#���Ux"������\�P����$�����������˳9�P���m���L��ŦV̅{�t\%?9Ҏ�aC�-�4,����*�^c���E홸����~���)�#�r�9v���L��#a5�g�:�f�|��T�<�����'��oMt2�8���'���m�i�:6����	�wu���"�@�*jq��AWq�ps�LT۽T��|K����5���D� �X�x?�N�a
�<��E#C#�۲l�MN��^����wy�v�Q 0-vo����C1(,;M��:�P�*+�gX��7j�a������H�&�#�T�_=j�ݖӘ��	�س������qkI6(��5��-�N�[z	/˖�b�N!��+��L|j�<�q��M�1�s�f�:?tS=~Dغḁ짶d�����#�YƟwς�_��b��g?���RF4�T,���bhk���%7��eM����Aj��l:�yL�(���ByslV�$T�J4��B�SX���T�?���?ݷ`
:�G��%����i.��%�3����G�:�,6�����_PƑ��yr"Ԭ��iBQ�Q�$��XF��&����w�B���&-0;�+��m�t��^h&�(�C���+����؋�d0)[đ_t�v���+0]��HG�
�?6]�� �K�~D���|n�7���?��o&`���w�j>�G����M� �:n|$\(u�_+P�nն����<k �9�kȈ
�!�vq��$�|����8�rs�$<��j ,�	��[g����X�����]Q�,(�Ya�Q�z�XR�R��0���j$d#H����D�Y�%P���<9l�,m&�!r���l�Qk9����@1�*u	~�r��b�����~,���a�6Z�ON'�+�px�Ǹ �vՄx����̡q���d��x��{ӑ��Q�/Ek�(��j꿺�D���G��� 	��ɲ���*���ƀA����IK人�*���吁p�AB���ED�����`:�k��j�c��NF����'e���e�"\.P�i�`�6Gܕe��&\��؃/䈐Y>�B<s�r�a�l�nqf�п�`�`�C�f#���xL2�d�� &&�?�< S]�{u��rb�[&������`9N����҃�sE�/r�5���-x�Y R�	��L`i\ن���8�5�
��i�O[#s���|���<��
��<$�QԞl���&�P���Զ!�i� ��l4$�j��Q��~�E��|�q���I�p�}(��.�a�O��O#G�=�����}Y�̐$�t|��SN�u�� �c��	��yЖ�S,�D��z�X�-��a��;|�(xd�m�%��E�vK�!�g�oٷ�N@	d�鯀�촼�,��C9�U�*����5���fPe����uf˧)�٦j�`B��>�iH<
�=�Э�rdАC�4&4�tG6�`�%�'	�S]��p�m�2��6�%�*X�5��)*�cgʿ�_��9�uc�]�����;�Ȅ�vjrz���$����%{��'.�NW�-i©�sJ资�wGN�>|)��:K\\��� �P�o���
.r���D<1�޻ۭ�#g��Ԝ�KGF�d���3�O�ߘԽ��7�����Lͪ�����ۮ�k5RC	
���W+l*�m����Sž�f�ܣ�H����	�Y=�?y'AͰ�!V�\��b�D��a�Oc^�ʡZ��9�('�V�<H}�і�y"������f�!:Vxa�6x1'7�����%�*���XhO�,���*�0���� �bCٔ^B3*��Z��;���0i��ho���N��A/��h\�R��%e�D�X#���Ta��rI�qdx��������M�P�e/��^�Gh}�aT���D��� �O�J�&������	;Q0�-��I���t�l-�#�����ى��}�p���� ������U$���]q��b�f;{m����.������[0υ_�Q���}�G��b��� ҕ>F��ࡩ%��۾vQ�xF9�ǫ�N��yw�O����?�@v~4���a.w�ۃ�SXy].8��G�s�?���rR_���tg�z9��������n�&SG���9��=l`N��17ߛ�aXc~kT�����/�?�B8|����J
�+b-n�
�Y�.��6:+��)�{�٨�9U�'5����G����K��������)�-�,� �����v6�T�O}�sa&㱳�\0n����ǫUgN^��W�Y��n�JK�3I�e|�Rm��X��QZu�.f�iV���%�q��':*އbh�k�g�5w3�E�̧���1�;����{]u�@��;R�-Hd��U���2���d7�c�MHtJޣR�K|�^@Ͳ��%�@��j,�M�^���:�a�]��%�H���s�?�}M�4
ZЅ]�0�+���ҁ��9�R��wo��iR�g&ҕ����.iˌ ����=ڕ���!�H���\�[&�>��ml����lD"V�p�/�s1}<� ��g�9���c�ݦ��
���_��|�G�8Ȼ&��~�����6�=͔�v������a��P@X�d�t�!�����!���� P�Y�,;mQ �g�w֭��#���o6u�����)��.DHFt|�=�!_�c^)ծ۵xޜ�e~Q��_�F"��O�qI1�vֺ���0P���$.V��,��{�P�8��5�~�I)���e܍u��qA��{r�U��I� ��	X4z��Θ��<֣ms����?4A=!]�UV�EȀTh��n�+�:��'yLu�����t��e����s�����`]/�O�c��S����Uoү�=#l���@tl-��nn�(b\Ȫ�F�Hu���M�](��J�0���6��F�ہ.���Ȗ>�`�>ȝ!��c~�#Y�x8�'���y�A	v�XJ��!.����� �@�/�bB�f�չ� ���;Y��5�t�!e#�w����>n����y�rW�����e��mޅI5�_��JMI]JjB4�#��~�I*C$ֶ��6��12!j�M�����R��G��L��m�8�lZ�6����+�k�?L���{`��/�O]�If��IXd���a�G��Q����s�1�lf5�w�5Z�WP�����ڌ���2쀏�$�[�7�D�����?��6��bZƔo9��&(t�:����W��;�Q���m��"�rMħA�nq��wD�{U�ߞ"����-�s�"�/�tk�l:45�Ѯ�Ճi���i�
8a���4;O��д�(��;(-V��1��h�[������l����g�8�Ey�`��Oj�X0�KJ9F�`&±'5<�]�!��.�!�Ċ�`�~��K�I�qs��*54~�t@�v؟���S�d{���	Se�G[�nAވ%��3qW��d�%�zk8q�j��J���p4����.�+�[0J�·�)�S��P�Se��]5��2m����HV54`ʛg7�RZ:.�8��R%eO��h3K��h5�^�EasI�Ѷ#�#I%���G\[@��'���e��V�[N��	��=�]R	}s��՛���DS&b-VY䩮�Lo�q_{@[Ԓ_���������O�<��|c@��v�heԚ��+� |&r=_�F���* ��t^ >qN��tn.g�A�;�g�ц�7=S��\<�[��{��`$�}�,\t)gZ��L>P��B�w\,02�����
LIkV�?��{f2��)��^�&���+�$��>:A��ޟNTd�>�������Q^�衲���jy��0@�,`iͨ0��jD�]T��V4�F��~?���X��C�R�;����u��1����C�4f���
������I ��9�~���G_n!��d��z��4����( {�{DBZ?e_
3]L��¦��5^�`|<�/y�_��d�FC�kM�cK?p/�#��bbSE�&t�>�������9��DV$�ݽdu?��(���a+};!��q~*"�3��&����9:���h����H�.�������h��J~T%�
�/���&},|'�9U�����v�vR��	�;Ԇ�|���8;���:b�@n��Ր$]Q�V��yqa[^��zd��v0���Iy�^z.Z3�|ͭ$Ωe������9
j���u����@!�[dDD�^X"( �ο�/\{����*�f��,�H�H�8@�Y�S�~��I�J���	�+���lm�l�PEdӠ�}�	���$��:��K�5�&BH:K�����y�D�� ��A��P����@��F�X�D`�ߛD�W��V�#R���Mэ<utyc���y߭�R�Jft����5�����!9#t�^ɾљ)Be�Hw,>kQ6���q�e�ϕj%��q�.��d#��.uY�(FF��N�������'�y�����8 �5ud����9�]�Y��c������p,������t����fU}�4����d�!u}]�����D�g����'$~aãn�"k���Wx%�r�mj����S���u��<KtC�<x��Uy�d��J#`��ʜ'�m����'\,5��2�m5�I�t�.:\�"���^v��#��F�1��8������>R����7V8�' �_���4~T�P�B�w	�6#�~l�������!ȝ�6׺����㮇/���F#dkm�V)��/�0���C�w�q��ʤV�O��Q-u%V;�8�1�"ٶU��%&��H)� �6�!��~�?Y�;�B�G�k9��0�$�6���<6�DJ5|�X��܏l����?$M�]J���a{'���`�b��0MOf�c2��>�*�E�.�Q�5Se�m���Vw^��*��[T�n��?�	�5\LOR�g�Ȓ�M�<8��u�vȡ��7���$�Z�^{N_\�r�l`�3l��m�I֌���WJ��K|z�fd���`�flld?�s��z���V�����@�mO�)x��E��93�Z@�a\=ל�����g���l�T8ɏ�ev����#��OqNI�n�[�c��D�����^�����$**���6.TEg��~�8��VP��W�dN��͟�5���W��V������������M%�02�ݥ2�2%��M�Z��Z�ߎ�2�w�>p&�N��n�*�H���x��°V��`�����?��2"o�������dCz�%̍--�%緍%B�m�.u&I<��A�[ɲ�+��Mc6�.�p�q�ܮ�x��|��6e�!L���voV�➍�*�j�����^���Q`��F�D��M8'$�D��_ﹺb;��J�l���>���%q��jZc�!������UgO��K����!��\�EM^�T��([��4ȇ3z�m�2 �w�rM��O���uz
[je`M͏wC�J�����Ig�c�փ�6w?fgĕ��!з�����1W���`��sPN@�H����煊>�,{��y� t�Y�ƏsMd����x�
�a�����t��9͇��pR@�Ϟ1�v���<�#�O#9|ʧj��+�V�#S��eԠ�9nݾszr��=��B� ���">E�ID�kAO�?��8��ӂ.�+�I�;�@C��ڲH�������J"�	�(�QG�oj\S�TZhW���ʣ�) >4܋f�^g�9򘄙���[���w_؀�~-$�V����OU����/�鯽	�^>��/�,43dx$��`����g�M��=��7�y�c�ϋ�Neٰ�ǭ|~J��`��>d�#���~��̦R����>�6���#�2�����g0�f���NxJ�_�����I�C����&ui���L@�J&�=>6��	�r�R7o��V�nH�Y]�5���]cc����� ��l��X�	b��D�Z���v�������p��9�F�^���TZ6$Mt?V�=�ē�<1h�����`��.�f�i��ܕ�*I�0��r�}8�R�&��þ��{l��'!=�����~�4�y֯����zo���# �Z|��b$�c��u6�̋r���0_x"RH�����1�a�;k#��j,mw+�'���416��_�q�Y P&+��v��.H�����nҒ�b���G!.>gGT�٘)4���j�tɀ����S�O��iQ�=��_>�(�'c� f<��Ez��ؗ��PS�G�`�i���'ߴF�
K���5Z�J7�oA��c��L2�hCI<2��5�@0��~��/ŭ���x�=��f�x�@,קP��*�d�%\J?viMD1�5�\"t�Fd��/:������K;�v7�6k���Ƈm��:��ɏ��`��Gp�S�O��-T|�� Q�/<��1�/�yL��
~�����n7z�w:T�j3�M�2�0{���!&��N��u�:g���W̞�Vq9�8��
r�Ær_�;ݝw���#����ޙ�ˬw�ġiT�"��;�K
9��Q���6���SOW�*�{�zz�@�L)�J:z@G�̩�&XP�p�
���*"}������o�1�W���g>�;���*�7�O�o��R��^�l�� ;'�����d�Y�h'^ �O[T��B�<��}K�Kdf��s[��&�.A�p�'�1"q�]{���K���+o��x�;���awS���+5p�����&rW��	��r�_i,��;�X
;M��!��Lk�ƹ+dޓ^D��ʟa�+�D��m����W���{�\�gt�kN|`N�ۗ� �ѭ�N_m��a�����+��[n���N� ���������a�����e���C�hvWv���J?�5�A���ي�Q�����S�u-cu$c����G�:y-���@�\d� �񁡊;;�%t`�Dcy �;3�YN:�,L��MV_~˯�b�� ��l��5�T!�ZX��tr�[�M"Sr���/�5�tQ�������7�~��.A�N(l��Y�^�V0$�����[|��Os~�$�$Z�ׯ$�ˑ��WU�$8��Lv����H�8d]���1�ݫ<+SGF]���f,,XGt�k�$!'���YXI��|5���H���eB���-*��-�Q���,y��0���Id�$E��� -����dq�< �>]D��늎(���Y�mNH<�&��V���Œ��٧��H��0��H���5���km#�i)T3�?-�:�6�y�M�������,�S��d�V֗�!�·�ۍ׸Y�L�M�Ry�f�K�ǿ��WOz܀�Y�zΣ��q�[��	���Udk'��b$n��#Y��^'��� ��AW���z8�"�1��`�PȚ�-�B  ���zYD� ĺ��¦L��g�    YZ