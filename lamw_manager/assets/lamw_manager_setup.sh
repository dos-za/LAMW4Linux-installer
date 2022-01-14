#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3958768710"
MD5="414fa1c031a6ccc64e46c81f2c74a473"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25848"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Jan 14 17:21:18 -03 2022
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
�7zXZ  �ִF !   �X���d�] �}��1Dd]����P�t�F����7fM��/ب�L��u� ���z���0�>��ϭf�I�	O2B�g��L�.�"|�|����^�O�Q�A'�|n�ɐ��c� ���T����q�"HCՌ6�M�#�U�r�`�ͅ@�v>�Uh��Rr�$�4��K����}ϨJ��<�䙇����^��W�z=.�򳚀C��r�:!��l'��D�� �? ��4��O�`��Y˄�X�m��am&9�0f��|��>)%�VY�<����y%>��]5wF�Z�
}��F�~�͘��A�q=���ƴ��I=���e�7<B����{�r.��iEשW�qB$T��?�]Y-d�]$kh��Q��s���/ #�zd��3�Ϊ�fEŊ��9;:
`P�E��w"\ڌ��'R}J�3?�����0j�������:GVH��9������!#��ug�<�i�9��ͬQoM�&�L�c�j
��C�l�31�}��Ы��7��>�Z��@�c����L�w���n��|la;��L�p���])3^h �*2�jf X��k���U�C,yޅ:��խ�j\'�ilڡֳV:q��޹	�f6��
�0��!׊*�L�����x��"]`#�<],�4������zS@��@'����ըq:B��e��<%��M�����&C���¢	<��-��!2Bŋ4e�(]�n>�Dl��<��/[�xwY.�#G ��n�8#S�#�@�K�dv�R�2n�gZ�m+`{�ݩ�]�h`�1��1�k;�7p��Q[�95�}���>�4��}�`�Yͩ�ų7�;o�48���r.�}�� ����Z4\�b��������Z����6��f	�y{/�9Em�!��Q�\�R̚��v��GVc�����,-�D�
m-��B����8�A_��d���K�� �OЌ����������[�"��\�쳁.�\���-鼷�d��g���$;���ajx��d���Im��)-��hK|)�v3�/`&Ӣ��y��3��۴ ���(��B]��iw�~dB<B�� [�R��1�g��w����͋�� -�~�vD���11�y����Z^E����y�
S{G]�(c�_0��J��Ї�*�,��#΋M8��G࠷��d��Q׵�V��
g4O׿r[���8���|�y{���a����{�q��;u(*�,��e��B���/����:�PI� �p�~(�����ρ������Ȏ+�;<^.�,��� �:�t'S)9��^'��fQ^:@��/�'�4�����f�ݟ���E��\#�7��4��Nw4�Bt�<�)J�1�kX�Y"/���H;@�:Y��v�[5z��@}Ā&4	/�Fh ���{6�U����0&ߴ2�l&7�^��LzDȩ��y��oX�ibC�7�v8�A��5�7��Q�3�.�ށ��Ɠ}��f�+��M�/m�"Cƈ�kx�=A�=���NL�B��/:\#��c�.��t�s�]��4ڹܥ��z����/��5?�Q���̾2��=a<\�l�¸u�J9iG��]>�6�:��频���(���a�©�����d�_g{&q�}-���kEh�-P=���$��ӹm�2��6��#�K��n{����G��[��x�E�eē*tn9�Z��T�2D��s��.�C����#@�I���w{��HA�d�u��/0a����A��R���;Dte����z����J��%��qN�E�Β�s�B��� �ξSt%�a������yԌ�
�,7~�I�Ӕ���Ց���ˎm�0Lt�^�r�[d�S�XΆ�x���z.�t��!�ąʀmæ_戬�.�F���`�?Х�	-	�~�I�RU��_0i���[�Y�J�\sP�u�-}�P�a����)݈�D�8�]�wN�g��k�>QHG��$O-^��\���Sr� �=���A�J��?�1�u�q�a���	������(
ӽ���ҭ��e�$����yA�4�၎�<�	�}M*�e��֮��%.�v>��Lì<I8H��� �/�s���L9.qu�k]�����m{� EM��T�	�>>�/�O����>�唈V뙌�P��o{.G8�HHV)G���Y��j�J)�Xa|�Mզj�@���v�	��?L������&Mr�~+l��	A��a/�� �*������A*w����6�+Zׁ�@>�m�YCP�V�����No�'��d��%�u�\��(I������l�[���:�2Ϥ�(������B�X�XִZ�So⊂��ʹi<�����\c��ӑx�=���%	��:����at�ըj��j͍�t����"���䍢b>U�`u&W������ʅ���.�L�h�0�/����)��2��h��ȳf���l��E �?4��{�h��l�ZKtIOt-��I /�"(P�I��G�s�@UF⫗U�4���w4���w���/K��癭F�n%�0k�$�m�O  ��RC`b!�S�T�ޚ�{"�����|3�-^a��ЮP(���fL[!�u�7`�#������u(/�L�d�&k���
(�$}g�T��:l���<���f�Um&���T�ͣ���G���5l�p��-d�<E:����{��/V�̈Y��/��RȅB�/��7!���/�5�+h��A�p�@���s4.��$�1mPb��eþ���mAm���R��X�Bn���(0i�s��jA�j�a2�붶*NLLJhw�JvY���a�����^/��Wd�$��c��N7?]���?���<����ק�e�t���y��kwgnoK��*��U��M �foa<Y�N�:ɯ�\5�Oߩ�a��'�X�����D����G��P�/:A+�H����E�	��? rJ��K�J�M�1� H��2�c8�H��;Mx ���?"9�A?��t�ZEx��(����RxY1�x��4f�i�ꀣ0�1=P�J��xk�S��.m�3���m$��������^���h!�����J9�."�(����g��>�[AE�i��mL0 ��<�	v�E=�4(�O��1�>�������,�*Yl�t(7Pz��$p�Ө�H�p)����g��a�'Ģ�P�S�(�k�\A)�4��x&��H[����8��v"��V�o>[\���<S���z����teRڰ�2u�yW�Ӥ�uu�)��@0ڂ[~\����'1���(-R� �e5q��%f���@�0��26&W�5BIۤ�Ә �TΤ���j���$�<��8 97�
t��1ة����� �F���q�!�htc�2�h��z���-�J�'L������b�|���zO=c_$_���A9QEE@T�.0T�0;3�G�<S�vj�#���c��B��2�8Ι2&��VG�y���ň<Qb���έ���Z���눊��Zsa��(���W�������_�ױj5��);���'"�0t&�����ti�6�wo �#?UE�ýG��Ȼ�/�+o������4'�"���yY��?l^����eӟ�^w]���j�3�3����Cf*Gk�%+.�U���M۰��Co��ǵ��������x�A���t �[���"�* �.ϸ'B�q[}R�P
���x���P{��ѱv������B�]�	�,��&z�a�3'�Ra?P9����T0�ʀ�10���
&�߯.�|�� d����6<,�ԶX�vmz�o�/�]��#|Ч�M�����c!���h��o"ҙ��Q��k�cXe'ޒ^��0e_%��|�<�������
�v���:�
������%e��F?;�_��G��+{E=�R��-�����D�Ym�B���n(�k�	(\,v��H��.+!��.1���H�|��
gFY���(�J".ЪB�����:O�VO������y��SC�C�^C������?���P�'|��m�GX�qi����<�|�:����0�cW�7���X�Bo�cMI��V�H��qN�oѧ�(IQ_s�=�lϝp�6�~mj4��F�����)�N_G�Y�d�`a�N�����K�9��m�8"�vïv�N�F�[X�[~١{�(��������EL��=\�%cE�   ̸���y�L����f�-������"Y���F'�H�c\�;�'3j�c��T���qW��q;�ϋ�@��U�^hoNʽY�-�1�}=]>��Dj�FD������x�_q-Y��Aj�G� �r���1K%!u^�4��c���p*�����]ù��D��]� ��&��zLp�H����=o����%�C&	(پ*:+h� �V�)����m��;˭�Ʊ��OE���x4a`�QS��US5(� ��N~Y"I�
>v �@I]%��$z���I��(%���	Z'Sǧs�V@��H����'���-I	"�!�D��o���ҾvS��DA�aU��Q6�0��Q�}^�����&T��(,K�A�X�OȞ �9W�,q���h�W|"*��W�������DZ����3Y�drH��B�a�q�����V�,� i�yG�}�{k
�c�rk��2����Y22D�8B�[�s��L�7`�&�u!�qE��[�l��9�_���DAc5?�R��l�T�p���UE7<ޜi�1���J��~aZlZ�	���i
Ş]�i�<��� L�'-����= 6���N����X0:���ޝ��M�ا����헄� ��;)q��-�rmB*�K�㷖0����f�d�K�!��?���Kt�宿+��>�X6pfx�R}Q��4����2�K�k���H!,�d��^��,�BU���M)������
C/>@��0g���=�P���@���5��*��NE��`5ӗ����ca��$Z��T���TdM�^����F�K�*/:�?e�~Y���y�d�͖5��$���T�Գ�'���u�;�������wi]�_Sn�p0���%��÷���r��Ug,޸S4�X��x��e������sd�ŧ=��%qb��c;G�3mk�"����X�e*?��{<��>��%�R���$-a4W 5���C���r?�A�wrǒ���w/Cv~:��Y�����v�r/�����+�ۧ}�D�.�A8ew�O�S�`�^�Y�"fy�#���Ѣ l~����- �6���K3�T� �}�H����K��R1�]���� �5@����q��fe0��~w4��D#�:gՋ�jq6�J	h�e�m�SXC囈^={�{���#��@J�~$�w���l0QO�<�h�"�b[���hQs�m����awwv�.�F��@ &�/^��z�6��!�����fW@6)�͔y@9�N������%�l"8�r�s|�@p �.�C P�g:�mpG�8p���vl�2�'���.ʘ������j)�*�B<@eCe���,ؔ�,Ѹ|H��)_�$���R�	U?�O�4t-l�Pk�'E��h"�u�e77��b�4a����Q��2&4��r��v�/ f뚇=��}��6LR��|�%9���^|�Ϟ(�T���9��ɛ��H�]-�(-l9ĕǾ����m���#�����-y~$�͉@ͫ��� �d*Q�F��۲��MF��(J�˺L�T�>(�����-�m� q� �
O>�����`n��&���u=o�!�tc��e�%�����ɩ�v��C�
S4 F�_�P���������N�{���c� ��k'��эlMX(�4�r�%��^Z�^r�풪�)EJכ����k�A��~�(H��N�����{�~��GT}p�|f�I����
���T.�Ëq�6p�SިaC���Fv'�Ɵ�5�NCt�ťϵ*��NIԟ�L&oC���s�#�!�qb�,ӡQ,�ySl�����$/��v��̹ޭ5�2z���ߍjmQn	�����0t��(�~�z�g5��p��X��܉���K���n��)�W?�DA�1g0��k�3f-=V3�iE�������Va�x���M3x�����]w��*<@e�+���r����kvGt��q0饗�IڬA�����~�#��X�l���^��u�W�Y@�ǜ۞�b�EM���Y��Z�^��ɗ.d�y�F^&J�m�y�Jմ�5��lT
�R�릙<��u���f�g�+f�%�;Qy��״~x�V.3k��w�ʹ6y�B]�
�'R���~�9�a>��EW���H�X�=�u�H(����L�熛�����]�N�v+�E2vؙ�]���}�?}/�]4e�p����K��C��]A>"L�J�`�@��ǭoN�5�8��W1�%!-�:��o�O�Z�kG�i5�[l�|)P*ꏳ�]��b�+���l@zشJ,�4��ܰD���ޟĵF��U�Ʊg�=Uw�����ǫ�n7�[��Z�Ѱ���XU-�%�.s?v��	d�󴷂�I��	
 \��9I6�~⡷�Ss�Z����#1[7�&ꐦ��
I&���=��tP���&�����I�NS($j�qz�a$��9���c�䉊�l�U����.�D[=:���
��?o㙦O�@w:�A�SH�o�8Oo�af���"X�Ua[j!/\{[Ǻ@���u��� �Zy�X��Ο+9q�!�k���6���aR>yi�U_�%V��;g�����&P��<���V��A~�7���Qa�%�V���!|{��*2�G�,I�x�4�A�"������T�+E��116�7�k:�@�V�����N�Oa��((!;�ؤA�5���a���`5�r�[�x:6���;�զP��b-��`�
=J�1����.�~W�{��c&2(2��	�������f"	|��/"��}��ϕ��0�w�n
�l-l���/�>v�J�0�b�&'����c'��X�E@��������\TN�@2@�m�����%f��9��C�Uv��K��M��#d�wCm�iC-���LYN����.LLF�r;�&܅Di�W�$�J*�,�;I7q*��8^��6���2���gw|��L$������x_��ePw#��Ė<���{�C��-�G/�]�-NT+��~ rW��*{ֲQ��j�Z`�� �a��h:฿���D���@ZɨC��(�J�p͚��W���.�Xv��=p%N"h�����i	�T�Hc�=��1��o��"�o<\��M���R�A�cfݞ��u��A��L��yݺ��.��Xfk��l4�f�q��/��~8d7n�z��w�2�D�C�7<S[�R�($�B2�v�I��;p�3�>)k ߊ�H��e��� x���_�*IS�S�R��7;7�,zv:k��%�% ~j�Osu�!Ci�"g���b8] \I�����G�u!'1q�B �͝��O=%�)ݹ`��V#Cf1b��H��ДR�M�+-G-�2ˎ���R����]�4���f|����%��´A�`n�Z2��������ZH7L��0��ٿ�ԓ�� g���A��vZ`�Y[�,��x<;+����L�m�ۘHQ�tSc�wL�K�:���M�Y7�	�B�c�Y�#aW+��s�F���>���3M� ��0�_*��xy��*�e'�ys��"̃�]f�bpƵ~i�Ct�;��l���i).��a�"��=���9-�R��Y��.�d��F0[�����z�s������g�聿�dV������b	����H���d3�jz���׳-�ll��쌍��j�7���R��m>g�{X���,��;BFṉ6����&��Ð��C:;���gZ���3�ITv��['��B����b����*�!�p}j���g�:v��9M_y��e]�P�����?�����㡰bk�H]-7�@�c�uЫ��<��<�!�/��PЁ4Ҿ\_5��e����T>T}������D����}�{S����O��������V�o����@+4�uw�J1:أA9g�
��MȲ��wBml�^�	�����2Q�WP� �j!���V���##{pr��Cs��&f�q���2,4U���E����V�������������t�c?"�=�f�}WcS�s�l�Lg�ѽ�ܗ�HjH��xK?!?gE	s�����;�caU��10LAw<��'�f{qȊ��Ě�8	pEE����h�|���Ը5��S�)��6'�mJ�d�Xb�ۿ\x(2��g@�N�)�$�P�+�Y4��z�	W�b������	74�WO����J-SLmƮ�BWpy�Y��W�ر;���o��L�s@U�W�՗2�,(���/=I�&f�T0��R�a5<py���W��|�."�S��i{�
�ɑՕh�J��l��j`ם� �1�Wuu��+tO��t�^�h������N��F���;1�q��k0:}9� �M�a��6�x/N. �Y��;ek�Q��J� ߁V���,�ōx�_�F��~��p�ΎOm	��X2~�ӣ ,!��� .#���	;ǻW���2���NԃW���K�	*�B�w��!��"�B!@sĄ$D�"��~Ң�{BԌ#��Ɍs¦��ࣦ������$%�G�h�r�;t;	�w
��BE�2������{�`�A=ERt�A��-����O)��+9��{���֋>>/��%.
'�Re~=I�g�<?�e���+GKw�Tp����eA�<MNY��b�+�$�S�Z\vj˩s/��"w�V$M�ɳ���ΰ2�%�9No>*���n�8L��Ly(#y��F�d��N�I9 �.W���\N��^��ܯޛǸyj�^o�����G�&0�LE6U!�8�\���?^Q���ܣ�(�8c��k-,	sn8����)*���Xj���Q�h_Pv4
�ŵ�,*2)p�59�{�u� ��B2#z�h��E����2�d�<o��"���c�s����e��o�Ji�͘ـof�$X�dwI$P�V���pZ���`�U�F���ϣ�6N�zq�U�{Pב֊�š�'Kc=|� �dC�+����<�������$��7SM�r����n[H�M��F�0�1*�A��:�͞B ��E��M��4G��F�83a\k�0)'�vP4��[�E9�73>�~Q+�X0��Ʋ7�]2��D:{&t6��令f�
E�tt7�捝���Z#�I��"���������ǒ5䲋C
%P@��i��D�ޥ����� ���!�]��c$����r��iN7~��9�A.f�W��y�'!*H�y�|��tķB�O��b�l���k�	`Q9k������� ���,[�'��7��.���F)�)�.#P{��.�GؕT��
{�����L���0��=��^�Jȑ�c���{$
:�^����;����ifI�$�=���j3�����(�޸k���d�i~M���H�mlIBP�Xy���t�K��qm�FtԸ�@T,��BY#�nOܾ��]��u���hvl:��C�W�e�]dW�k��.C�OK&��F2la<�J�,��ʱ��K�ĝ�L5L��+!�*4��z���x���.�9Tc�6�迶{��C��",��߉\�RZ��b�>�:'P5P�)ms,[C��遖k+<��:;z������?t���������޳w�8�h�ˊ -�vb�����y9�y�*�#%�B�:f)�.��:$�=��ډ�ϛe�4��K�z|x�ۓ*�2�M?ju8�4�)�c��>xr�*�aP���6o�ÔL��fYzFߛhyQ]��]^�������D�ڦ|�`�ցB)���&�'�+&�H��#�G���-��Y�������FN]ҏ�ڏ���V�R̱���&4�7¹�Z�Yq"�X�`����ь �K����U��R��*½����[�7g�rENۺ�^Ku�rM�|F�$��2�S�Q��.v[1
�ɹbՄ�c��Caw�S�+zkz��F���_�9'4�^@�<R�ٟ�j�R����[Lo��]�!'8dGq�,�\.��Yo�O��x��������^�.���6A���������l�py�0��?��ҳmه�ٟ��{b��/��U,�A�yo��Vt����OWS��,����r.e�Z����e%���
xO�W2����i�_��k�'u�������eu���E�����������I*�k������C�t���)\��Y���)�݋���!+��U̃�zq(�S<3����Z"u�	K�l/���-���|Xc�*	F:0�"꿳��~��b����;	�f<�y��d.�h�F�X��o�$ѽ���M����1��g�ֺ��`\�<���U_�cdX
��@����5�VR�C�lM�F��#=�O��K6�AF��kUa�Ւ���hp^z]íf8��4m:��e\�5ِ;��������03�o��\�������/j5�P�<�	n�\�ݻ����ya���T�yCV�Y�6���4BK���&y���"ew�m]ֻ��<�3�7���P8I
E t�ow{�'KG�ˑ�/E��,���&�7�g2� s�*�R��%�� ;nv�X]������*/)R|���<�غ�K�ܰ�}F�>�xH�%RHU�د-����sh���PF�(i����@�_*,_��40C|�5�֊�?�ߴB��ĭre�m�<�}���*�J�3,����]t��ظ1�F��43�%(?>��.�	��H'����t���iBvF	�%�;1�8������Y]�ZŢ�W��D�$����?�t(������;8��	��31�ncR����)�W!�,�3�Ҋx�s�ed/la�_�+jWߖ�����ҳ���xaj斾�6��"�J?�� C�7Ӧ��6���{������V�48 F�OfX���LID�l��O"��Dk�ʰx/�����Տk������j&K��q&gTs�p��X|��Ko�W��%�&S��c�[�Sw��4�c���t]؆5�c��׀t�y�����fW���p֦��@���A/4�"����T��>�C. ��1�.�9TER=0B:�2;��""*2��'�������RoBߜ��
/�K��vcH�By<Ǥ	�	����46�]�T��O�a ����x�͋'Α�d��*x�V���Fp�x���nq �/�Z���:�݅�r���S�����ch��[�U�
��-h���Å�H�(���K�)���e�6Kooe/���yN��P}���K�e�s� ���A>��!3���&���/i2WM��ӟ ��{�A>g��.�ߞA-���	��t|x��D;) �Q��~訄$ɽ�I�i����4�ƨ��]}��'��V}`y	�+�P`�wy�_L��v��oa:�����;����t=�}r��[�n���M7��{	3���/� y���v���Yem�Z>�S0yt�JR�z�-Y��M��ՏXW�G���z��aF��\����F�6�yJ�a�a�:�� [��F uKǨ��������e����?�4�7s�쾝^3n(������	��Gy��u]Fcpr��!HZW�Ѹ����(L[� ����w���Yv�3Q����L��Xh�q�Wރ)�Jys���:���0����$ݻ��9��Myj���>0P!I�|Hױ��c���?��l�U�j+�'Co
�'��@�aۺG.L��L�P���Y�!:�;���)����?<J�h!���������aC�W��Jy�;��y%b��ڣ�w�".�����22p��-E]�m'&=)-NiuWBE�R nPe�iˎ�H��2Ѵܳjh����P	��x�!ؽ��f�� C^�a9�/ͩΙ�}��C����y��އȜ�44V�4.���f]�./?���*E0�m3`�y�.��(h�7����=��F����T6�x�k&�.i��l�d�c`&h���pr����_̶+A�]�y%�}����t͹��Ĭ�[Qh��m��6*#h�7c��7B]�]q�6!��؆�
f@��z?B~(��2:8w_b��Rv�: �I��^��j��gzm�A����Ԣ�ҝ ���E�Ԏ�u����pΖ$����|���{�NQ��M!t� ˥��w�ͲH��[قz�(��#��s�;�9$���n���BC:��e��LA���e����"ۓ��,o1��kqӍ����}��8N2c�co�	�(nË��������0�-��V������2���p�ˁ,ӹ��)Yi�y��~�iP)���UZL���\�l%����z�K�
[eU�(�)$���Y2l3v^/����ΒF��z�<6��|�x�t���[�Z���5��!�+��a絀�ϑ�¾��/�<Tp�P<0�݌���.�-��G2��A����J��	F�qU��T5k�,۱!���r.����D��x���}g ��{U� c�����n��ഃ1x��#/J)�������2�����utfuy���cAK1+�yͷ�]���!UU��{�����m0j@+�������g~e�#z��]�_B��a�͐KE������΂����
�o�Ы�tY A%R��i���^1�WY�ϵ�w2-�$D���I�+��k�wJ��A��u�s��kKh��E�z�e�Zv�i��^��ذ"L�q']lI�Y��%)���U�:��5����s��<�Y���&~L��#���q �"�J���(������6��H��s�5o�k�c!�j��C�"jk��̮�T���C��9��*zR^�����bF{] �`��ò��kS�%����Е�T����w��ьG��=/�Ɇ$Rө;��cú/TSsZe�^�OX����~�a)����o,XD�N��XZD4�E���}�
w��E��Ӎ(�Fa��1'�i���!��B���A(�"����VS�*ɻ=��aw+��M)]!��$]l,>t0��g#j~�ĥ'�@��Yﾡ<�cmɂFvn����h��
��U?KߑY1��8�� m����?�ᇃ�Klx��ea�����|h%S�qYֻwv;�bȎ�w	΀e�"�u�j���0���.T�M�J?&nC�^L�<#�Z�Q S�w2
�`&f7�Ǻ��h�R`��E.9�����u*�i#G�mm�ؚx8Qw��u�+��E	�L���9�)n�:d9��Zk�j��q:@�X�cQ�w��5�u1׭�	�(�kA{��G)�N�^���k��d�T��%"��/�#�}Kop�I�8R"2��>��?���̑���C�c��/UkXu D�H1��;�����"� ��?�T��/+ ����>�Y�d�>����ߓh`�:��+�:�S���Je`_Gh!M-hZ]��PD9gw�)avC���]OǬl�q ��a�i�~��>��D��Ӽ�F��D-~��JKY�$�45<��KY���9u+J=q�P�Q�FM�����c���2⚧Uڈt`/~��oz�I)���"�L�\o�=�O���)�]3�D�������{/�R�1m��TS�X�UG��v����A�?�Sm���9�5<����X)�{�=��ث|;�<_�mF�Y}[���Q��X�7��F7q��&��D��"���=L��'LF��o$��}x|�M���aӊE�ACf-�Ĝ��p]��1�?y�q%D�"+�\M�.��;�	S�͟�F�|�����5r:����B�����6`��{������s�l�a�Y�F��M��R5F�v�IVf�[
:�a�$�]"�t����R�R>�&��%WC���t(�t4U>.��h���2�L������ѹ��Y��S�a����R��U�7C5HP$3��Y�B܋����)z���<�jU���{�����f!��C���BR12Qg���lHP
Ϭ[f��l�Wc��F���n)��e�!o*NI�E1���Q�5f����h��v�(
@o/�Ǜ�rT����(�p�,�ڏ��jZ�:���N������œ��V��*�0��O7>�����fdJ_�v�����ԑ65�f�z-;��e�3!����w�X
p��%�K�Џ�g��ݳ�՚�1^�e�/n3ʄ�A�>K|����iށ�0]*��aFh�,m+ۑ��t9BE�Qe�w�,A�+7�����i8��C몕!�����ǭޤ8됴n���q�G��v3� ,�=")��}����Z�Oa� �Y��Wտ�>����c�Ny������6�î���{5�R�(�K<7�."�D2��)�CZ�{^�a�|X�Z�خ��#l�@�(�����"�u���:)GĄ�(����濁�~�G���b�!��U-��%�BS��o�4.aj]8ĺ8��>3Fdl��0.���"�4.4|���zQ��e1�I��������Q�g�?��rm��K��GG["z���z�9����jE�[����#a!��� �;V~h���U��n#�ޚe��ҹ7�������6S�����	QF���){�Fb��e;U����q��n�Qx)&������sHt,���k;�T	Z$�P�3����̻�R���>&.��ZD���t��^��̩��*JY[V��R�Y&i)�>��� h�-��k]/ /	=@�*�Q�<�}��O;[k�JG%d���Wɿe�}A�����rCaM��> �1�b̴;�$p9P��5�.�>J^�E���WOI�`z�}w�UP�����<UF�I*�N�IHj=�fZ����q��7��rj�6_%�p��}�{������b�^!P��j�52�@Ĝ[lm��-:��R&�q즤9CϜ7
zV� x��@@�0@깺����s4�9:[�%�܋7O$�8\��e����~wu~���uﻍ"��	A�+��gd�ߋVu�i��(�PRa��d|%t��Lx*�H��sVS��l��Q��P�<"VX� �uD�\�D�U��\��ΟGg���y��m�fQ�.e:Y�o�S�߯_���*=���b���s��?Ҙ����
t�R6���I�p�r5P�� ��xl��D?D�Tt��H��Β��)�i;E�f�Я����,��BʸU��3��`=nRfhQ�N(��p<�>����9�.a-#�	���ɫ ��Wj\�kq1�uV���}��p0�/�vϽ��/��;�����s��<�Y:��b�?����b����b���"m^��V�o@ F�#�E�~�.N�}��� ��ؿ�37P������,)-�G�i�Jj�� ��w�'?�:��cś�E����*K+�`i���d�ԏ@CKy��3��vy�<CBѷ�"�V1��V�	�#��T�"Zb� ����L���^���|�ߴ��{Kz��/����w���8���l��+\��X))s��'���K�f�z�N�����Hr���Cf�h�*�.�v[ka~M*W��j�֞�I����2�j����az��o�/9l>| �Z�)��}�����;ÒUYh�?nb�j�@m��#gn�@������ƲKx�
�V~�-�b�P���OJ^����sr-�o$��=L/8��'����Bl�鷱%��P5��CI.��'+^��mr�ǵJ^�C�.�����B\�>���^�l�6�����9A�ѣx7���Db��r���1&��6���*��?-KU* �]#O��p��׿Av��7��E�c�S[�:�F{J2u��U���t��duj�0]��]��v1�~�[;e�3��C�y���1��Z�Ѕ�k����h�H�rK����&L*��/A���M�j	���{ݪ��!� f���:5�8\�"�e���5����G��$^�'�6���&m#˗�>z��9Y~���A �ٌүWm.?{�F����9:�j����.���U<!��<��VN�P�.
o,h+} {Ӻ�S�U��:��X����� ��p?�ʅ&\h�C�ҡ�ޞ���ikC�%���wͩ6��mD3b�����0�JZ5�Em0�+�M��̦���`Z2��t�a	vF��Ms���k����]��-;Y�@�e�S�(�RJ�1���?�/P�����9X��Q�ى��B����M����	�3�T��]�_G����̤�C���VQ���o�F��	@���X/�6�`f��lV�w8*uvJ���S���{�uJ �f�e����f�,��hf���qqѠw&�Юaw�b�U����'C-P��ؚ'�����cɐ�1�	��u�K��f�V6v�.�_q��� �<��+S�>KY�#��Vο��/��
���!�l���~:����^(2v�ċ�/|w�Ŝ����L�4��T��u�VG[�F���~qk�˵�N+#`���/0��������k�K�%C����62�X)�R�UD������Ȅ�{Y>���WR����h⬻潢(�T]���|<��G_aGl�Es�^$e�5��	Y^E�Θ�.��3��2��ف��˿�?��e@��趱�EfP��C�6�4��7�_���Vc3p�˲���rU�s�j�*Q�F6�(��ۧ����6���Lv.�!���&�L�"�y�\p������q�����<���I��`�k�HF-6���i�4�R�Eb8ق���b�2�:�YY�t��uc��Q�-E5?de6��!a4$꟢���"�\+;�C�hO6��LɅ=���XD��V���	)ܼx�]��P��єr�9��Ybp��<M��m��ׂ$����o����=U����l��$.L���`�t���& �K�q�@.�[�K���(&(>�I����q_���O)�8��6h�ힶ�W�"�o�_�M%��C����ѡ�C�NR�qIO{M5��́�o��=��j�s��+��YtY[{Ze���v���I���#� I0���M6!�.�����u��؊G/�$��m��\�bo�o�V�a�@v<�����1����Dn9ܒ𶅔�3��<��̫�a�q�&���ʋ�"а�����=)�n� ��������j(*Q(޽̸$iK�*� e�^ء�pDs n��̿l<?&�	r46�W�j%`EA����)B
����o%n(�Q�M��ʖ�&~<i�t�:5��,�j��N"��{����B��%׷`X#��X��Ζ����R�o��p�ξw����8;ۀ���6%�A~���wd;v��K�dR@���E�܀�q�I�ة�)p� ���*HӐ���| �(�SJ�k/�rTX�u����9���7 n��h�0-�����)
raބ �+�qm/���Զ�݋5Xg��^fW�7]���-���ܫcV�5=�1��_�x/�H�V�Ȱ��]�c�T�K�����	����̿eX&Q��1�=��Y}���kj�
g���*}�e��o���;Z�$�GA�r��Su���0��z�_�a���ʑ�j����eQ�����o4�4d� !W?kղ	Y�l?&yG��υ�6I�Y�~�=�=����PI��I\u�����~�y��uL#$R�ty:H��2hooA�_�7���N$׵��i���e�7/�F|�cV�T�����(�7�3��7�E�������h�>Fӱ\I}E��Z�K�lR �����t��?3$��w�I&����H�f�\,��T�����j�eh���v��5��)m���)��ŀ3B��(u<B��̪��4�e&��f��O�yVz[��N4� @r�����cń���u}��U�B�\�Iñ���1B��И⾏� #d/�ipo8���|��g�f�1S�Y8��[�s��R�r�'G�~�#VZ/�٬�;kI7�����!�!t*?�?��Į�y��h�-�[�:���B9�oF�����p��%\�
�����fTEΘ&��k��PMŀ��k>$��I<x��xk`F��_�V��㔻8B���ր�_�ָ �M�@���w�r��	��q��NwvX6��xY��'�E�?�i���e/�L����&�[���� ����͐��w�Q �ˈ��^����'������+{{*,�����ᑡiR0�ctr���^���k���M&����C[�{a]%�q�p	��.:e�c����.qN��snB��� ���_�� 
�N�!U4�H�cqC��&+�����W~����J���啒� ط�L�ڞ.	iW��G��!}F�ۄ6����3L��V�ؖ��*V�Kf�h�̛+�p�dRmJI�.C��q�+���h�l���7PFT�p��N��TCx�!����([@*[͠rXfs��J�]�;6��*Ak�qO��S��ֻ�W��Sy7�ȏ8���v�D��<�\y/�����	ea$7���%  ����.�kmTj35!��]���z0�@0�ʕ�����$���d1�ލ$�����й�ϕ���I�!�/�(�3�9�Xg ܒ܊��z&�":H��+V���Kj�$�_ �M}G\/��f�J�)�g�.涮3-ɐ���fɵ%���z�+!�vQ��g\/z�����U�Ym��+�s��"�X�| 5gJHs�	���Z�`�*���[�f�9���,7:�km��wH	�Ъt�|(}�� P�6�ݗ��ϋ�<��~E�˄��	>��uuظ��˼��TzĨ����r�Q��_�{���O��׍�~���8�UVnHf�|7�O7U�5�W��!A�'s^�G�5�=�u�1.gO�vx�H���a�� m��~+�0d�ʈVq#�a�9��	.!�茐�Y��2�B������06:�nZ�.�Vf �ŝ�HW�$�;?�D���<8{���4�Ɠ�kfy��T37RX��Q�D�lX;/�,��&��6� �LHɉ���D�FK���-X�y"��*������&r��~�68�|�S�
Zّ���U��î¡�<�hnVK6Z�ǹA�5��M����4�eF"��L;�Z2�X:6���F�,& �3@�'�wW4�_��Fx�%c�n�lm6�m��'���
#��=q�(i�
d��|�b�bʨ�A�X!2�[sSAB~�odd�NG�0k6�1.��O3Ss:�_mc�E�/�r�θF��<M����-p"L�thX�xf�C�ڶ޶����ܟ��ɸ+B!��g s*��=J�_��=��L�[T��ګ�W������������I�6�"�2CM_�9����hͮ(�cx�r�'�6~�^�*���_J��A��}>#�j8[����pq��zCѫg�A�j�<�O��i��f���:R��g[9���LY�U�������2
+�𴶲	꒤���0�٢Q5��{A�&���"�?��P}T�u���0��<�xc�PR1jI�����|!%�� Z7U-�������!u��;:)�G-\�]8Ȱ�g�m���6IY�%���G��o)��i�5w��5� fY)��/C�,�I�A����8��S��k��gb�>7W=����騐�x��/��J}���!t�"E��S���9]��D��� ���xF�P"@w�O�Y�:Ơ�B��d5σ`���䒢����!�D���c���c��"�%ܳ��Im�Qz\�5��3�k2!�Qa�G����;�.�8y�uT�D�C������;Z�:}�D�ݴd�_����V��S!#�v��Oϡp�W�6p�7���NO�ӝlfH1mym2��B�y�̼Y9�̆����l�%Fn�ʠ"r"EW� ��Q��gH:�B��!([T���G��(ѩo�[��Q%%��NT?�tr�� 2��Sֽ9��n��Q�Duv;�jR�z���ɻ�G��|���y�xr�0B�:.1Q!Ȩ�O�y�p+�T��J��QbĽD��\'&.P�-�'߅�҄�)^?3�':��xF�l.ypF��)Gl��j�N�8�(ڂd�C����kݢ߇��p�v ,5������c8ግkqB����X�5MJ���t�*C��Ԯ�
�0�Zp�z>=;���e��T���i�!�^ł��XE>,A���L.��	��ѷ��e%������ ��0Sd�u�=��M;Y��V g+2��Nj��2��K��ZzmVթ� �w���g"�^|r��y�A����LS�_����WU�ML�Od�6�݃!9:T2�}��QƉ~m��O��@��&u��#�&嫵ZOR��H�ӺP�B���Q�+I5�\�>� CO���`C��'5<���~�JϦN�V"$l�q������h�?x�����Ԕ�8���Bz[7��9mf"��ّ�GmQ�iW�Ě{Kbp�#~?�����n�ݿ��3��"6���[}ۓνg)����'d�/	��hH-�:���� 9]v����5�cxl���kag(�j���)22�G6'�N���H���0*[��c���u"�	�	ۋ��Zo]T,�+/�Kiu/M�jC)�<f�%�����q4�Z��C.�L���8��?��ݠǄlv�)��g��J����S������h�^�m�pzi|m�w��Czt񢜫|٢$�ۜ�W�h��fi��r���d3����:�����MQ{�)�^���#m�7�Z�!��bKEp#H�����_�v?)+j_�/4&��Q٬����{��4v����h�o�{�E*�B.���G5�
�dŖj�Gπ˫�!��F��U�O6��N�"u��֜�eYry��!��8P�s����8��b�i��Щ����U%. %G�"�@�f�uf�=�E�(�c�|7Х[���`�閎O�BI#�O.�V��qv��7��>!�o�*j�
����!"���t��������P1�0+�42���]�vDW�m���C���-�Y��� ��'����oM��p���EB�G-x��\JP���9�3�������mK3�*%>�;�̯D��\�����_�6���J�kGA0��LT�+�t��8��g���n�%T#�j���@�|��us@5��I�cM�ϴ����6�'꩑�ҋ�:�q�=��-�Ʃ^�O�D���ݖ�@rH��<7�be4g�5�{��R!�0��Ygv����(k�yBs����W[2%!a*'��݅��~�
N�#'@�G	��?���)����(��,�זfv�v�Wx�4�Ֆ�2��+���ٺ�n�{�ےMO`��ֆ\�t�����V�<%�����#�)$k�A�����t���a$Y^ZB���xK�E��=�nQ�l�J�Q ���,&�1�d8Y�[^���;E?C#���e�"2(���r-���L �@A���v%+�f��찞1�����4J�]��C�t<d+���4[���Pu#��p�y�w�74(�g�n�{�\.l��]�5����hv�1�+���k�+�=}���jߛ}Q�:w6I�ژ_B}�[��1j)��~�9�+TK�aêjW�U���5I�^�e�A��]uRjÊ�� ���
�ӆѝ��0��48����Ӎ��)���&�=���`��I]~��G����J�R���:�����!����5�#��<�f� ���mn���mJx}E�B$��!�6tnTLb�p�������dB�}&��hP�)�F�|� ^��[�d�J3��{>�����kt~��,/���]B��$��M��p9� F "�ᢁi�����z��)��D�|�gK�I_����|B���j�F$�lg3�2<N��C�n_&��JW3ȥU��U�Q�9���ȟ�P$���R$��;S�Xy4r������i2>c/h~!^��?�bե�b��r��
���O���ֈ�������e�m�7�G]B���<��$� i]@4��b����f�����켛d�x�c�_	�"_��?$<5p���O|� U�����&�$��D'U���I��~�����F9^�
�+�On�|�8s�>���L�LLh�؇;���7cVnge��ٸ0hg���xW<����>��O�OC�S`���3�U�uˬ�@\�D�N��e��P�j��\˶ُv�G����_�ٔ�k4歀#�l�]v6\�H,S)�t�1
�������<��[��IH""C�V6�)�Pt�6c9W� }��b<V�S�h�ӄ����,$x�Y�;�
L~�
����t�"y}�7g�rd�X��w���������Q��Eˋ�b@�Pc�0���i]�T3���m{�ۧ�0�u�����K���.|�T W�:�J�]�{ʭ!|a��F"�]`���X��TP�B��S�� N6UX�-]�C'Gˢ��,�I�����CQӝ 6�����������؏K��/-i�v�$_P�L�
�ǔWsZ� �]O�1/���؇�(W���2-������e�x�=w�W4��W�B%d�-������L�a�%���"uD:�A�*6{t{ a�W_A�rv}�3Rr�K�ؖ�k�&߶Hw�Sh(ToZ9����7֍N��|�.P�C��eᨩ�eK��=�<B�U�O�\�t�P�4�	9[ߥ��{�:���͸jz$�s���Ã�Ϸ�GJ�jH籵�I;(O�}��؄=[��L%M]�J�{>����|�;����
A�p�(�w9;��7omu�w���Fl�����Z��g(�g���(-s�1Н~|�^8�M+��c���(��K�ۺ��.tP�.�a)�����Ԫ���3$~k���(�q��g� X����#.ؑ�kY���~o�V�|5ƍ�~�]~ԟ�kj��e��7�
�Ę]������:�Dex�������ljҊ��/ Di,�?�u��(?�U�^�S��O�|C�La����������9�Lt�X�r������PT!iu�*f�C�.��ۋ^t3�qK��=��^�1s6%*4U��D����(�D�h}���Y>�{�I�߃"޲�F[�.:�U!XH�������d[�[�n4�� �@-��
��N>�����ѝ�{�p�鐺)�1ˢ���3��F��I�f���=�?�����O�[�#ϯ��Z����"��}��o�hQw�9ٙ�=xk}�X���,�)�6��(ib�dN�[U	���4�щ�<���8$(�I��h 	l4P�s�;�v�Z�\H��r:(AE�M����y�nX���U�
Ɗ-��B�O�t ��x8�2��ű9��c���5�ƨX����v�[͎�y3��dо�@� �I6����8ޔ�-w�0��n�q5�y�]n2q�egh~���W����pf����V�{�nA�Z���-;;K��`W?�.���%�
B'x��/̖�<��A^e�Aظ�R�\Ik�#.��LN�Ե������	��V�	̮c�[x��dr(��ӡ��|�/�X����%K_��95�G�`F�\� �Ӑ9a۞Pm)��7 t���s}M�<��~J�Ft9�N�ۓHg >���T���,}��ʐ}�] g�>�;�G��P�����������|Ӽ��D_��%4=(����`�6 ����~��*��@>�Bӓ����6���o5��Zd`u�6';A�������.��Xښ��%wK�C���c�)��p��RȒX����=u����dN����_��\Z�j�����-��$���	})͈a=���>��^i��h��k����ZQ�[|��+�}G���.�ۖM1��"w��a�����!�4�7k�,R�z=¾����!gmB�1�x u��ؒ|��}},V�+��WNO����G�e��$��Ɲ.o�<E\����acBpF�H��gmك���܅���%���3��� ؿ�C�P��Ũ��'�'ى��/�I���m\	�Z�įA��h�0��|�U#C�d�&Ȟ/K ����=w����,���v�}�,ꪎ�9��������k����T�A-��MB1-L�LT0n}������CrzTW�V�I��j<�}pzD�;�i���
L�da(������e$%����_F�~���D��O�E�T����V�>w���t��a:ba6���9�Oz�>�٩��xI��	��C��1��$[����Y�[�R��0�'�[��z�PB�^',K �����w�zY[��#�e���i��3Z�ڮ���vIȣۍPF�5j��ڔ��)��0@��J*�jttmO*,M��KK$*[*E��L��k�<YN��I�G�%S�h���=���b8�;5T�ZahN��P�����1zWVm����%,t9G�|��ĿN)˛
g�X�f�yυZ�φZ��3��\�8)E�M���-�p��#$�&��]��u!�ѹ}�s�d�F�|��f�Y�9��)���Q���M��p��K��	5�aE�UMe�^W�8~�m��F~YOͬ����XG�4��c�L��_�M3���p�W�Q�J��un:] �Z:�EQ�c�a��gv���(�F��uHZ���)�vyĒ����������i��Oܸ���?Jc����EþB�[>�$n,j瑏�%�u!;�X߮�R�u��Le���i����ڿ��&0-��)Z��J����Y �Q!^^�M�L�A�%�d�e�bLB"�o��̯/���H�9/	L�8ϣ8���O/��y�Cg{jU�meK��E�|o��ZY��C����9|MX��N�g�a���+��?����!�N�lkVo^�ƣ�f�mަ�fO �����&���k.ʴ!R9IO㻍F��Ѩ 5W0r����������aV�e������zdSYq���&N���Ł8Uj���k8h�:f��L����F_�`$㽚.����,��GN9�Y�4�GW�F|i+7��3����rB�ހg����\�I������Ձ*ه'���Z��cOtx��֙,�[��� ��\����į'X������?�A�@��ޒ�����M!`�����4���cWYk[�Z�Z$��8���!ꤟ25͆�2�rP��3�v�'t2\����|�P`��v��RD�m\��D�j��}LU �z;��W� Y�uÛ����tJ�P���� .Z ����0���fZ^#SA�I�ټX�N֋v,_��!W���eP�F*�Vi���Wbv�Tɩ5��{!3J{?����z� n	C���}�|8��)R}G'f>%��S��=��.q�n���#��2�;K)Ы��; �w�bu��6ɥ��[��3���d���7g
eb��,�#у�)0l��'x�#.��_J��H)��Tu�Ҭ  ���Y���� ����;N镱�g�    YZ