#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3317210719"
MD5="c5b15107f9c8d1799f7cac619b5082c2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21506"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Mon Dec  2 19:05:28 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� ���]�<�v�6��+>J��qZ��gZ��^E�5��+�I�I�%B2c���l��}�=��>�>B^�� � )�v�&�wo����`0�o���>����;;���t�!'�G[;O7�;�ؾ���l<";���'b���2]�������~�c�/Gs�5g4�������Na�7w��H����O�}l���d�JU�ܟ�R=s��m�%Sj��t�<1C�cy�t�&��`]���(`t�&6u'����A�R}��<w�4�[�-�z #��FC���7?Be���C��S��Ү��B�MI�/����y�
��@u2<0���20}�d�D�1\�4�Qr��\�"�T����ggGF#yl���Z{�&����Q�9����ɂ�"x��oj�~6h�z/گۭl���������0kn�,�g��sCE�JQ �h� X�Q���$��"�a���S�h�o�ޫ�V\�J���ιJ��|�;����5Vu�䞿���'�D���j�r�KWH5s�o�ě�=Wc�o��b��a�N`[�)�4�s��v({�~C�J�+=��z�>��)�
YE��j�}X�-L�:��k��}!�,�<2��1l���:l �@�R��!�i8�g���dP_�l?ݢݍ'���'�A�n�b*�b��Tu|�Cǜ1>�K/{a@:M����(�<�]˨m�O�=�!�5�E�% j9E���ldm\�j7���)Z��T|,&�g��CF<�� ̘���	�MW��wD��g�)ʌ��@�Z'|قLg��L*�jXK�JMg�Gn^�(�]�-:5#'\W ���0��l"�SK���$U*Y�kZ9k�slІv(f��;�s��Nu�3�75j��y6|��w�Ж�&�N��*��,[��\���2T�#��%��I�^W�jZ)�_%�"r'���~\1_i,��#\$W(�R�$!�LM
�J��榰�n+o������R��'��P���ܧR�41X5�|�D��(s"�o�?f0��Q�r�Y��&�ɇ��IK}�������;#��Cj�ë�3�����+��ͧ���������K|�{�h�"Fs6iO�l����h3��ʯ(��G�����6�]Lׂ�|j)D�1:��:I�K��*���:*@8��ܿ'�����.��v��W������U2|����q��7Dmݓ氃ۯ��==����d|���`���y�m^ċBsl��ߓ1<�.d��d�Y�Ԇ���Ǎ)q<��e����7&�:Y)F�G~=�\�*�#|�ib�E{ncX�(`2�s���QgJ�`!�Lo ]Ӊ�1���t������t=V�=����~ g5o���3D�Y~�.��0��*��l�d�L�g��Fp��M��Y4%o����U���������;_��_r�'Xx�Ƒ�X4���/��fo/���ݯ��k������֪�Q�x�&�������vp �Ȍ�4�a	 D�]��xT��,��4�����m�4]+�l�9v�jѐNBb܁���#S�q�e�#��z��e�Ň����)/V��/�H��֝+J��&��6GS��Q{�V�m�"Zwi���a���X��OԳq�����>�����ϑK/G9!�e��}>��v�+r1����#)3'JJ�FF�V�Qo����G�PCM"2�p�ӀBdQ�S��6��E=4gL�C�hk�5T	`w��z��sC�#�=Ɓ�*���0�!�h���d:+�췏��A�P��e�?�tO�x�"K�I#Ռ�b�������}璠���dW?�@�m�FK�J�U. 1��+/j��O!��:���2,�C��.%�c�o�33��O�(� 
8,��)C@�9�/����t���<�т�0�3��q\����<��� �!��{{�>a�xm�������.��m0;�����=� U�dl�q�\���� ��|vR���Qm�T��a�@t�~Q�W�<�M��'�
�.����eO���,N7쟝� �!�(,��XˁdE۬7�1�5-��n�ھ}�=�͡��bb�?wz���q�����y���������X �!a�<6�n�q,��.�U��>�M-Y]*��ӧry����lx��u)>����8�)a�RS���1ԖW���"��!���z@s�y�ba �(ϰ��qN3��S�sӝ���~i�b�H	�dݕ
�6�,<z_��`9��Hjˤ�;�����0�v{CC�,�$��U���"�"�~w0�-�^>m�5}y�{���D�z��a絁;S\�����J���TE*ٝI�g�V[pT��"V�kE�F�'1���',Q{=!+�����j��Ȳ�tnk���0�y���\�^�G-��_�էvs��4�oU"��Wl�J�X"�jzlZ+�~Ct��oW��J�J�����@�}�e\άV�Z���D%���`r��]�1d%�-������H~^;�.I{uw	������II2=�h&XJ&V�)�2�sۄ��R��I�g�p9��=4/�Ds|��D��MDY��-�9Lc�g������%� ^h�gQ��J�ޒڤ�.��ͣ�a�f������b9*�y�q
#�����՗�AO�]BM�x����� �dFHJ_�ے�ª|y$!VbW/�ƕʀ����Ʌ9�����g�C�F�m�Hv۵�������v� �75�����ך(������5#&n�0�Z6��?�|w�w{w�������������K�����?��K��Z|�X"���)�=��c���.G������xL�N\V��j����vI����CϜ� ��R�+Y&�kI��|~����C���p�����Z�/��b~���� �O����~&^zQK=��2�"0�L�5�
J��1�e�QNg%H����q%y�J~���#��k��4��ޙE������S�68{6�u0l�����=i���zI]�n�����Ӄn�g�;������G��Y�P}'�^���F�_!d�T�#��D(~����Ŕ�y��h��k�H^���I1�r�X�4��D��CN���?��c���䮨�*��\�3�|��h+G}3<7V,5/�U��T�.�E��<��πlQ5NW#��h��iR��CX;�5B�� A��Z4�)J��)�鵕���o�#�ݤ�����C��*��Z��!��9�ch�:�,^�m� c�1���:�xC�xP�z��0�;z9Q��u?�h�B]t�*C\�Tִ�(�5�g!���	b��rFõ��?��1A謉]�����늒���Hb[H��YxC�Hr�#,B�¸n�.�]��\��ə$Do�x����r�ݨ3�HM���o#;� \��\P\�0<�C�����L�-q�Є$õ�8Ǎ�)	}*Q%�TB�b}\�nZXt��^/���q"����ذh�1(	&���d j13E< U��XKj�����jG���q[ �[~u\�y!�$��3�t/p'�w$R�	ԇ��� ^@��n�5����.%~���t���^�zū+���'o����4j�x��	Y�y47���=8�vG&����O�X��;�p#_�$g�2�Ja��B�(��L�5�V_�A�r�)�cO��`��Q�����]f �{���+.F�v#�4�ͤ?b��Q״�&^D���1�cX�YWD%�{�Ҡ�8i�'�F=׹��ok�!��j�++�#ؘK7v|�:5�)daM%;�o�˘{�%��of{;���A�`x�s�6��<���1N
)+�H��q欙4M����z^��eE/'RT��{yT�9/���?F�+t��8!I�z����%�)��Fc���vS����ɻ�}���ց���'B/�~w+X�Q½�'���c�;�=Ų�e`�x#w�%2}�@���؛uD��2����ڐ#��.U-!��)�E�r�J�@N=�|�^���A^Y+?=Q;����=UE�㠽b�6�'�^p�|sBc���_ ngpq=������.ČI�i���[���Cs�������ͨ�ħ�l���1���g����=dPKM��@:#�x�|�&mj�Ca#����FQ,&��Y����;DI;�eSC��W{�_�Ё�+� ����ܻ� Vj�b],ajzW�;��:@�)n|S�BP� �"�ֽC�Dg&\d����[w�le}�+��{�w?/RgĿg99{)���@��Žu�˷`�yl �1ɖ��䜺���C���wmŒ��D7}�I�{H�����
r�G�7���A�rN����c��XX�򥜇N,��)��s���>�J�.-���m�����y���7�����w"wQO�95�-QSSoO�]������$w�Z(r7M	����&2*�'&�>�O��ʢ^��el;)A�	��<L��m�b<�
"6������i0�]�1�&h�h������-fC$e�cC���l���p!�8��?:� ��pq_�}\S�:i9&cEv��vr�Bz�W��C�ϟ�c�� Ú�'
�}���AV ��--E$D������gQ��1��*_�k�53Dmy�'ց:(��a������e2�뽽�ڋ��v
KY��UH�{7����A�!oxi:5��4��Zwk5|���<|M�Ht��V��nkt�>=u��$�/�)�s�!d'�]��q��v�4�s��ڃ�n�����ob��z�i�^�9u������-5-�k�]���5���"ۢ�=cGX-V�.E ϵ���y8w�hhR�2u6;�\�P��;e��l���L,?� �И��菰����=�6�~	��8H�A����4���F�� �����C�i 6(Q2��y,'�R��9�(�n�~��.y���L�Y�T�&���29��Y��D�^-�Lb��J�%{o.�$re���Z���\�N�v��O��7.��j` ��օf�-�I����~�U�s�s��I[h�Hs���/����8�cJ<3�s^�_P�t$o��@ɓ��*R��o������	`N�Tbck�~�	������uR%��x����?��ds���M��B���Ơ%�r⊷� tN�9�e���x�&E ���'��0�X&z�R�Y��	�_�`���13�-�$%�Q�� 4	���pi)���CRg�b.4^��aX&|�����%Blc)/���;�u`�g"t ����kKD~9N�f¥�[ ,ဆ�f�H��!�R�-���^|�b4����	�~��h��Ǝ���:q�s���N,��ⴶ��Տd��T��(��~�»&���uŕ�Z��3�O.~g�L���+�����u�C��9�Tˣ��q8QKX�J>�܍ wI88��X5�x��:�2a�y/�ܿ��Ȳ;�Je9)Ũ������!jsj�-�S-�ύ�&���^g������6�$�}E��tc�Z @�Ң�J�d�)�� ��}p�@�*@a�
�h[�_�i�>���ه�G��mD�2�� ��e�p�D�*�񅼄�{h���H���jDCVo�ӯ1���T�5� ������ռ�kkucFD��+���(�p��.��Ů�����PRBp��Zp�Rңj0��� `SUH��5�Z�.Ѥ� הNp��u��g0�~nԍRq����C�a��uB����wc��*��O�eRh��/��9���i��^ј��}V��@|�}u�=yF��nW1��v��+�<�ɀ����Ĺ_�'W�|T�geuu�^������9i������\@�bmT��R�UT7V�g���B�y9�!Μ�r��n
��W�6un(k��M�nD��rI�`TM�Ɉ6�R[x0��5�7ЮZD:Ɍ��FK���k� Zk�{�-���\�ԓiR��2�'�D�ܘ�5�.Z���&�^6��A�!];>�x5��р��w8H8b	��3�I_����.��Atq���N�w<^��q���[�A��]膟�k������OB��8}8�f��F�~��u���.m��<�*�V�i_U�A̫�|�%$}�2��r2�s٘d��r�Ip޻�}e��c��	�E��q���}�E
�a�����ч��fD#_Q�ƿ��`0�� ��PVhV|����&_N3�E?��AO�s]o���dN��t0�oD%�+°�78���O�x"��bo�>v1Q �$)����H�M��!ŭ�H��I�*���G�!"�1Ϡ����E܎o-n�g��Q�:��|EN��`�ўJ��+�A|�x^n����]������yu	�:/�Js�aę<���Ȣ�Jgճ&��J؝�껤#Y}��:�Y�?sw�E�o�zQ~�6,<��-Gf��6��S�p �	��ɏ,ߡs]ɾ<Dd� �,�۳:$�m�P7/�r80S�n����$ �sC*�����6�v�Z��WI�U�F����)���X�-n�=�Ԇ�*�JQ�̛��h��ET���;�1�h�d>r{-����3$E3kĊ_��K`�ڏ�Ը� O>`��.��I�v|����;֬�j"�.]����XG���p�@e���}U��H6��@w��@hhB�H=�^t��}|��;��a���άc��y^L]��s��|�J*�~�4�B��^�D���c�Fi79�����ߪ��YL��٬g��!���/��l��m�]��8';���[���,Lg�,n\����j���8�&���phs��2JK�+2�Si�K�{�����m �'(OL�.H�{QHL�bgS�C��^g��uwON��t�Sz^���.~Ax�X��3\zܸ����V��Ӄ�q���U��Vi���/�O�{?m�5kE��f�Ͽ�aZ̺�.������r;r{9���>G�ˑ�q$�f�ݏ���m��⼯�Χ��2�7�n9����
_!�7�RnG�j6��L��`�r��-��jV�����>����n�rkW��y�9\���Clq1Z���ui^ܴ�沽�����%<:)����@)�Nu��A����1[��k{0�t��?w�O�Ɔ9�8w͎Y�N$.L������Vs�Q����v4BM^���+��{�Drӵ�D�c��r64ϩ���-4�Xm��r@�o�&�jCp����1y����|ә��W��>{2�3R��F%.�>�NH���Ϗ����,��g��-VS��VÁ��\��%��ڃ��E1� �b��� �� 7*p�,pHг����|���\D��ZY�?��[~��D���Hx�UB:fD��C�,�����`
��l�䯭-Y���μ��H�K�o�*:2�KM�����w�V�6C%�Plc�*�M��3"�@# �k��+��Jk�p|e��+�����G�o5�}8��0��z�������s�������U��c4�?$�����|�ז��q��3��>�M��i
�4��տB��(K�i���(Te��<�󦣍��yS�E�t��H�F��W���y���l�M���w��,����@6�d���jmUzv�.�}B۟������Y��ɀ<��¼|&k~e�Q9�jkv���/k�|��|%��:|�
�(/�dӠ&�l޶�X�>��(��A�s>e�ȕR�?�v�������B�7�i�|����xL�I��H�M�f`P���R�	f�-*v��淂#���!'"��F�����d�Q�m8C�~�����fˎ��Z_��X��������-�́�f��s���v����0`c~���А��(����!��{��zYZA��σ��U�����g�l�S{�W�*�	�|�(�����vj+g���F{��B���>��?����F��{�6⯶w���z|���x�Ddi��%�����g�I�6���?�Wl��9Ҭh&<�>:��������߼
���`����^˟�/�Yj����!��#�fZ̪
�_$��3�ޚ��钡�=�B�ag�ԣ��G����d0V��S�? �ؘ�9e�̇"�690������(�p����6B �hL�o�y�t�#NQMLSvæ�8�cf��\��J��g�8L5�/|���v\�ۡ���S�������!C�P� q��Z�M�Lt��m>ܝ�V�ŊFO�4þ.�/��x�ℵ>��^�8<�a��qg���`w�1f���v�]F8<�f��(4+�	k�oF�P��AV�u��9�]}%}-���W���W��2e|(a\�oI�D� �Ќ�J�e�%�0ঝ��j���k8A5�ph]����6�B��7x��Ggu�E�_~i�LEeq�S����*Z�|*������*��_�ͳf�}Zӡ�E
<��El*<rM���Cq��=�滠��v����?m}�f"i��C.L�p~d�pkp:B| >�v���֕���e;)�	�6N84�;�,��ʦ{��wr����>>���*f���D�c3��J�ۂ����I^G�Vx�8���9���M�&6M�$Ip�D*)��ia�B�X����s:��M-�λ���7HΜ�:�ʨZ�Z�Ă���ǨT��I�+���I'A�L��=�C��	�Ңdh�Cצsk#�=���uuj�-�[�`XQ�S�1���6�S�3S�h�>\2��`��KQ)��%�%�e��9��D!���I$�Wa�a�>�+]��i�;�M� &&����,�q�'9�w��0���ݼ�o���gN�WbR�\����ܴu�)Q�dsb�y�ՙ�Y�F�.��ˏ�����˹/�
@����-0c7��T�eZ�����?J���w�+����KO$����Q)i勺�B�����IF2�.(aֵۑe~��fF�315��ϝ9)ݎ�$��EQ��%����u�}���ƻ��-��W���V']L��o���ۖZt;�Zm��S��8�� ���-F�IKhl�s�M$��$��5c�T �M<�M� ꛄØ�ujXf"��8Y]#�'��Ph�d:&_�l΁>��
��2L�ƻp܂��h4��^|ن�����D\h �13��;�!�iFgA~f��h��a*���AJ��]n�z�WאT���Y������X	���T��+U�JZ�F�s��v�4nfPCv��O7_���!JF��8�;�F���Q��HeM34�I�N�"�N`�'I��4N2b�@�����(���k�<B+�9AX�F <�R/��ŧ��'�1[��9���ګp�b|�n�;�~��Q��=��""�`Ni���k?��Ū��ߦ����aAub�����LY�b��"架o�(��	��P�T�U�-*Qt�@����g�ag�;�G,�E�?�AC�`Lq��o�8�u|]���)�(CW�p�f'��ҁ���c}a,�Ke�U2Oy���� %a�&*��6���ڏJ��S�U�aw��K'���1�X�E��?s溮�蹹���s^`�)����SM"��'�J�}Z�,�M�����<zҶ��l<j���?���w������ש|�@?�d�w#��(H�h�r4��ٽ:IB4P�}ݜC�HV�#��[Ǹ9�����	uܘƹ�j���#�J�=�8y�2�*,?G�v80a�ĤA�5���Ʌ���No}H9<�C��Y��(t����8*gw6/Ǽ&���'�=�U���a��ݡ����
��CD�,5nyU[�>j��#�P�V(ā"&��h���o���u��y���5X��rH��t%�M%$�����敐��F(tE����4��.ӟ����ƱɁl�D&����>8�[/��]�HQԹ�(�a7�i�%l���m�[7U�H����i�n�>��0,�`C��W��7�{|ŋ7R}�%O�F0,�
���C�*G���c����1}H��˿��`���y���#s�:~rixrE�ꬲ�*�j�:ZklM���2����Wy@G N�B�4C֩��Z5�*�|9�'�H���B�e(0R�uLE%dĵo���U�h�0V,G\�^��nj- yEK�q�_��vI-���D�L�m�\��%e��{{�d��`�d�]MqN���0������M3���uJ�4h_��:�}a��m:��u��Q���cy+y�"�Ia��`�������h(�o���X7�����ݝ��r�]ܙ:�<x����Q }_oN��_v�f����^<}���V3	������I����{>mu��#~$��_>�B7��>��M)oa8xȦ)m�<E�����L	g3��;5�`��+ǈ{��rAS������А�c�����o��ro��� ���hR�*-3kg�ʑ�s����g��6yY;�RG'�N�x5:�n���gӤAx�"�y���^�B��zd���8���z͹��;D�=���_�:1��@6�`0�PĪ_�=���X��+[#�B�����!^�N	��7�R�V�"Ψ^�L��P-�?�����'l���#tf9�}�H�~L����`(���FB���=�%����_gI����dƔcr��J��{�*�P�%D� P��`��SԸT%�j�#��!s*��Q��֮#R=bjUr j�G�Z�����,�L���-~O!��@ZaÙ�_����>]~-O�j�
��m�R�{TjSk�ͦjK��5��S�� �������!�R+��e��&��&����e��us�e:W�o�vSȔ��� �P�Z�U>`�乐��L�5��)5:a�3I 7R�pD��������$�9� y���5���%.I鶉�y*y�G]Ki^�Y,Źa�'QT��.~� �?�#+Y�mi5;{����e�9�~�-�Im��b����s���@H��.����
��w<ku���^v���P{�p��\r�$@�[X,ը;� F��Q�%qJ^uG�'H��چq}m���1�G��uͻ|��N��=����R�T���M���Uv�����,n?�����ZŞ���8��%������#b��ޫ݃�nF�x��.�x�ׇQ?��5�q���:�B��"��zU������v�`���q�����w��Kڄ����_��W[֗�*����,�-hj�G V�^�6����FG��}�Vr_6A����{'G�6_���\�|f��u0��/�O���ZAP���"\	]���$j��q���C��_�����nww���Gc&9��mM�����sOf	�h�8K��:Z���n���dT���v�������Y�8��{�k6��(�(�J���Ҥr��-mQ�-%��?�����@�^�d)�nsxjzqҕ)��J.Ql���Ж�x4w�j�L6�dv�A";��D/�x��� b�4�~-�!ˠAD9YuH�Q�\�)y_�AovO�M�k80D1<y-cbi�����Ϊ����� �/��0K��sQ��Y�z<�A4#�pX�v�0/���r��Y��_$l�h�����qFd�Jb�`zC�m��bԧh2qF�����~T�5���'{�/D��U9���V?�*#�l�X8�ѼL�s�9T��n��M�ĉ�>�X����$�.��s���>��VI�-G�T�MC,���]�'t�h�>���ɚYic�Z���*6jy��b��fC=s���&GL\z��0�0b4�L�(�rP2�Ra��
�@u�����7{(�l��vv��YgU�&a�GR���4#�&���~�G�h�B�f"j�� ��-I��+��<ɕ؀��c!��n���~�.Ds15�X��d�[S�3^i�&��46����m֠�Y�K6��|�Q!4��nA��}�����G��`�f����a�L'ٚCѤ��	���<�O�?D#�}���8�r�<��z1��4�j5㮛���fdcQ�j�gݼ�*UWJF���������{�=vRH��9����2?�g��d�R��;��4;{� %3:�v0Q��}�|��P�묻�f���W�"��1��q�����lN��
�)�+�3Nj�(�V���fV��
���W��M{��F"��
����O]��I�Q��x�)����q|9 AI�&Pb�"���Uz�<�N؀�t�����3��F�:���Qι����+飜6�.�b?�E��@"An�]ܟ�#�^)]ޫ����'�@����n�B�����%���E�3�f( mLo^��0DI�:����4�W]g��VIq���2�ҡ*/�х3dc(�>��F�Xӭ�
��]j�o	3u���f+7qc�����7��ľZ�.������kjh{O4���)B��+��q����7�'~i6���S�]���^�<������q�M��ş�v��8u 9�>��;s��`����yUiټ�A�!�z�����ɇ!��%Ҝ�b�۽}�lHh�9��In.{W�ƴGdN�z^�d:N�"@seV[xR�F�H�(�m;�cy[�p ]t��qV	�V��r�ʱ��[e�Z�ڏ�eC��W-sq���!T�o1����3���4b�G��ln�f��7I�{���4qV��HV*���{U��=3���$�`���Td�����U�S_���Im�����/����N/7�6xl{�]�tAІG��/���v��u8ސǊ0i�<)�9�Pz�P� ��Â�#B�N�W�߁h�ꓵ�xQ"d��gv!�Y?��4FP+{/��v&�z�]}>˿��qi7��+	�&c�r����`@�9�����'F0�:�2�88.��0��]�=9d�/֘n>����A/�W�@#<���$H��eݯlyV��a����C:߳��Q���0&xvF��Rnֈ��'�\��N���;�����5V�
y�_�C����FA1Lā���,,SDU>+���CG�h�&�6�(ج ֗`!G��%	ڦF��L��(o�.H֫ua��:�CS��oh�qHQ�{��1�a�C HL�[-���*ƄA�r�~Х�ٽBx�r$n�`RL x@�}	�� �"�����$E�R���T+�}��ど+��g-"��F��U*�on�j�L���#�_�Q�-��"���������(�Ci�`Q\? �3<�!������%0���t���zo�r�ʻ�`nV���ᒰD(�][6��ܲ1��|�jת���m	sZ�����m�G��0W���؁��B�^�X�E�D�W����g��8n�)'��T��5��� ��:_|�&�bE�"ݒ��Ւ���	u�(!L����BY�o1��-����#h����;	�+MZ��D�^lK�.�S�ݪJ �]�v��, �����y�ŧ���#���gq?��������8L@D�V��Ed6è���r�+�v��	�f,��L�K]�[�]ZZ���1�Z<�ԉ{�/���/	��aȂ�7�*Y�ʰ�y+f7�����-l���AEI�~�+ÜJ��y)�oJlH�*�6��tk�f]�9���չ\J��-%�f�@N|�u-��7ө�4�'D�z27-rl53���Î�[�f>���~K3ת�}�k�$�ė?�MVG?���x�G�"��N����;�Tۧݟo�yz����y��ś*��M�u2u=]�3Lo*/����ޫ�����(���pg��� xt�2؞��Zl��ʿ��
و<^�XJ��M��Ωq}��j|'�H|� A�#:�ô�d�J%GL����k-��/�Q�
7�6\�!������<{,�tܨ��r#��0�g�����	{.a�ji]�EV�!�2�$
�؝���;�[�}sroYFl�]CQe�wc�`;1�@��GBU:c#��1�d�rn��mc�y]�H��4{%�v����o�IB}�0�M��<y����o��֟l,�ߖ�o��+���w��qr����r�Ά���3i�v}}ݸ����ۓA��y��Y��Ű?u^[��+E����*jP�|&T8�|&������1�"�O�6�b��	����������(��D>�}{x��}G__�w��1gi�:����u�	��k�7u8��y��[�I�~����
�Y����+�H۫���̏��O��a��;͎T��i�1�Y��-^�b��P����H��ȸb�BV�ʆ����Q�U�F����<����
xL�ό��n=�|\���\_��%��3�����}�AYsJ_Թ�;�J� ���'�[�"(Z�2�I���A~H�H��� ]O��<�!���G�E����ĊV7�O�^�����U�q�E7uDJ_�����d��WKI`H^�>�Β�#Wc�k����:Z���.=�����C��������.�,O��x���~����,�7�Y��;oz;�'��{��h�{�i�x���Y��������������W8>�����dR�S�`�D�?�β��:L�Cu'G�a�GI�N�?��[�x���{tDu�e�ڟ(>8%�(�z�X�d�'���~'��^:�R��9� ���!��Nǿ#ª|-���&@C�S#j<�u�S�Ug]Ϣ��/R�ۯQu���|^��[���W�.�=J�+j,��E�Z�&��ݯO�`]~\�P���@<^�X��G'Z�h����a��O���b���'�@O6Z�:E/����[�0k�R*�]}P�p?�NR����x��ܭDj|r�)tY?Wo,��N�zz��][�]���t�r?��}|���x��6�kf�5�ʝ�@��F��,7��c�����W�Z4f� �X/���XHc��H���`�ޓ9p.k^)���6�,b���tk��>�������,�|��3�ܱ�~r�UY��eno�Qf�>��m��l��ٝ�����ΗN��g��v��4�����(I`�	�=�1�:2@�.��������	��	f"+�2Q��	�
�(85t�v�2�c"*��z{;�2�Hx���KJ�����z*T�� C��p����d���r'�"9�(�����TU�(��B8��P�l�`�hq�/owN{{'�o��n9�L𮊌R��������Z��6-�>�sq��Y�W<͡��K���u�Ƌ>ݪ����x�j��V<��<�/�L0226]���0m򗰈�:R�U|�C����=�����f-ļ����&�L�;��ާR���i$a0T�	o�|�$Oe��J��)'�93F=����"9tќ(��i�����|������˰~~n�l6���'V����\�Lf1�{Zi��EX�!�����>�Ȧ,�/èW!K0�����F�jܸH�p@�!*<j��6��2m�ͅ��8�$�F��Ґ�o��
A l��E{��������?h��b�5GIj&�D�L*	�P	����x�i[�0������m�U�]�X�PKܢ/�鋼�g��N���ևJ���D$��t�8~��kcƣ� ��dt�$�<=���kϳ+k^Uk�w6n�q ���W�w�[�Y��wlا:�/5�'��x>&���{�I4�Ι]L�#���E5�����pS�7�u��ڿQ�.�as[����g��?�S���bp�(B�Я?T/�CE����&����7�e�l�!��z޷�=C����Ge1�1�9�Db�������c�U�W �_f�Y�_p�Dϧ��~%q[��5r���4�߃����}�.k�}�r8�6�o���rڎ?
�SDhc����+��(�2>� Qc@�`���C3L�I�0yd��{08g����UB<�Ś��'6ReΝ)�]�z��)J��)� {1��4� k�q<�c}QX=;�@`���}�y�6LnK�qW�^��~N��ľ�ރ���G)�尞+	`��m-�v���MC������w$�b���<�o6�Ԝ$!�b��Z��KT�L��uO���W�����h�E�w�"�+�n��.5�ٳW>�-�3�j����shT�KMsj΍ҋZ]�t�؊���I0��
���#p���
�����]�������򷚱}�YJ�e�� ����Ŷ��BV��د���Z���p(m7��#\3�͉�Z;��I�mz�b]b�SN5EdAvS6�a�Ε�lAx�Ma��/�u�9���h�x�W�ޖ����7�Ʀ٬�z��0H+�Kk�F�����f�{�����B� ���X�|�қq||ƯpL���,������]@؂�w�w=]|��~zO�W��<�)FmVo��+�<�Yo^�̏DƧk5t�H��(L�OYK�O�ٺ�Li��:��c)�Ƙ�:����_�f~SV�I̾���2�j/�E&[%�0�OG�H'Ŭ�*��xO��@[��2�=����`��5j���QY-�d��4��p��UH��ʀ����P��x>[��z\FsȰ�Q�0��?X���Ș���Z+v[Xa�i�m����W��-�0�R�N߾�=�k�m,�BK���b��z�h���Qtl|6��rgX���w���d/o����/�vPT|>MɊd��S<d�0*�R��9�i�q;b��8�(<�/�h��l�Sa(�!:a���i��V�/w2�=��q����o�y���`��j?Z�-����� L#��ـq��T��8�?��1Y}{_~�%n^�}�O��x,Z�����w�bs��<�˭�ܕ��(�񸞢I4�"y��E2������wZx��h^:�r���Ы����a7ǵ�<O���82�Ѥc��
����f?�����Qp�{L�� 5HhV]g�)�+�j��XwN���?�xΌU7��rH�i����G�L�����귲��OK�-�b��[���Qo��� ��󞿳1�������� Y4f����\�o4lQ��ls(&r�z=�><���p�O.��jcy���`UuXp��Di9��S�ɕ�E̫l���]t�}�w�v�cSz���3*��{�gu3'�a�< V���N��0::��R��I��A���ge�<�I|����ut�Yԧ�d���X���PA����R�ip�&����74�cVO/�ޢV�f���ds!�$6)�|�K��9Za�O~�zSt�
N���K��<�@K8�r$�Ѥdz�7ڕ���JFdb�8
���6��{�L�YW�k'C�qMg��@k�S��*��ƺ����`��2D3a�̮���6��L]`����o&P1n(:CA�ē��(�vA��ĭ�t���v�6����k��������91�	Յ�<P�����cIH��u���_��  `�6���z�`N|m&�jh�Qeb;�s n�_��a�}�e[!�`Qxz�Ϣ�u�eu�ąD�=z��a,���1:��^����Ι{�Ç��ty���M`�u��ۆ�8��6)�NVd�ӥh��>��� �꾉�!����1�̽UEm�?��e��I*�m:WM�JJ9}{.������� ���<61,	�:��FU���I����෾��w�M�����4<��%]0�EI��'�`�J�;��b�� n�\r?'0t�����e����T�-y8ǡ�����n�#���g���\���X:�i(�h6���ǩ����W�˷�ǰ?�����$o�\ێ �lˊ�!qŞ!���D
�`��"gče�6�m��c;\��<�����0�f	�]U�"��T��!� �c<�f��BB�у�y""w����4P(��J��.
������Ȱ����T�B= �Ƚ�dN�F3�ຶ��u�	��4n �;���X��\�^$���(�S�(�(�z�D8WOm����h8*6/u2�Rn�d��g��PF��"�rqYа�d3ۦxe�N��]�+���Fd/�X��-J�vB�mG�7���a���ݚ�,�.�Fif_�LW�b$�����j��Xx���/� ���R�f-�$�Х�h��ڟ��1���%B]C`��4E@���<�^��b(�|�\��W�g�$U)�B�_cE����'� �&#VR��E�E|�Ɋ����-��0��A��h�~��M똃�����Ղ?�����sͿ �j:i���a}�ۚ�GO������2���{������e���m��7�]K38O/����'�0r�[U�Y�~����O�\�y��'�EnL��;,��������f���7�EA�N��� ���i�󌝉�}�Χ?x��)w|��^�_Q����&�������DC�p��#��٪^��*+9�Y4�(�j�$�
^ϲ�^c���.X15t!U�s�^���t�@;�E�c +8����F���2+�[ǌf�8�B(+k�ۦ�4,hqC'����; O&����TtPI$zv������NT�q�#etC��Q�5i�q�0'Z'�驸�Edp�=�N�@ٯ����-?�?B�J��� w����7���g���}���X߰��͍�%����3%�	�1����l�|e
�O��ful{z�ZO}F�Rm�K;�L5�����ݯ����]�4�=SI����)Kw������֜'�����ߝ]��7�g�����#���ߘ�yp�+�3/��XY7��M�U�U��U���g\�,>�A�y.*�5u�񜬻�+0v;��W�{�X�8��Ym�P�Fc���0� 2���C�D.�̶n~����ː��ͅ1���n����aٷ�K��Y�ń>�	��������d���C�t7��8�<V�mӯ��˨*2�';	|�'3�Ӗx`�y�|��	�\)H�J}?K�F�0K��1䰙*F���~z'|�d�����]#qp�}�ETz*L��k�@ߵX��E,�Y�%�NSNq���@am(@(�B0�a��#���%�ʃ��G�x:�X�*U�o=��{<s�u�`k�ř�l��G��]o��k�͆�����xP�0)]�3�e~�R��C3(<�b̳x�W���W�Ǟͷ:�������q6�sB�y���)��?�V���������l���G�7�������M��x�D��lx��@��½XBB� 	�a��r��^@K�D�#()@e|oҗr����Wy�e��0z�j�!�i�͡׸�G�.�0%�iP)�8}�õ-U����Y��|�I��n=w(@ش�� �Vs=�1&l'��`����C[%Z��R�������=��Ba4x��7a�Ĕ������=&�ԇ�p�4&#�ʵ��13f��<5��(�y)f���1E�������vS|{Vݦ?�k��U�{��g��>u�3��Hq��r�Q��{(�غ�J�3]���\�w�����"7����d,`8h���Js��G�_{y��{��s:`���Ŀh��B	t���5����aqK9����x1ϻ"�\V����9��~���k.�[���]��N�2�K� ��j��w��``uf���	!�0������)��4�ڻ�}2d��)�=�ca4k0`�Y��I��RA���1��� f� � :��z��ڜ���!������I}ar�:�����%q�.�!�@�A����<aD�>�t�X]H�_`�[-����`�Ӕ�� H�T�w��A�cv= 	��l�����K�z0�#饼��6�w.m+"��Ն��г�1�|i>Dy��<a�a?��*R��w.}I�N�(������N	�RL�0������C��KŴ#��8�y}���<�0�nܙh08M�>y��A=����d��q�놓�/̧e�rV���wz��X����%?�a�#�B)���%�iЭ�֕���ԕ�{��~�8>���o�r�1�s�ĝ懋�hä$�<O��p�.�R#�S���䡖&��w9��N��A��X���.L���'#�`��|9��]�і6�w�P(f�Z������k��5QR&�������@�낥!�Փ�������t�k�/�Mī�=���e��;���>���&?����Aѷ'	mg}�]�o8�Ns�=���E�0Co��Z�(aaR8�.�Ƙ!Lٺ���`��4�/��nO!�t'���c���a�����վ/
���x;���÷�a22j��9����-�/,�?Z�xd��m����?����/���dK�_�V[k�!�l�a�d�<���U�,��Y�?x�y�|C�"��0���3YW)pf���4<�_��q�K�����Uq���7�66u�r]nu�j��򕾒��J���]g���5���|����j�HU���}ZLX&����	�	q}ou�E��s����Z�%(j�j(�=M���̂,�Z���@�@���UGY��%�e%�����a �������%���f"l�d��#�e��m]��z����*'%�a�)��=��4�,�L<ɻ��Ģ��C�r�D6"�G]Z�ȚEƼ��X����8�N��{�q�64e=��������M�ht� �l�����i���P�D�aU�f����Euz�e�8��=Kq�0��_��B�@0"�3b'[� ������"1�'.���J�����i��<jo����s�s�7����ߦa�誡*�8�	�>#.�!+.6B�e����"�kԎ$PZ$J�� ���[��L��+��?&�Ōjl��E�L���, ����a|.l]�ǻ�;ow��}u�i�h
C�Q?�"nr���UQuO+���g*���F�kǸ���D��A
��;��V�,D������E�QE&-�VI7�����O���'L��j���V�V�Hlԏ*�#�R�r�r1����?�bOI�&���D�A����+(�&Aj�DFv����+����h����QD�E��U������x�H��O�r.zau�Ju�P�k
�D;*im��
�>�(�6q��+t�xWT�U�LEH-��h�N˻H���K�D��UA�W4R�o8.%�MF���(5�rBJ�Ժ��1�+<��&���A�}sp����_<���ҡ�΅��Nf7�����J,X�)��fV��$c'5��4r�O���5!}fZ��H���&��J���-v� _L�권g檭�M󴂒�q��-���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g������/^ � 