#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="569504363"
MD5="41b32bfbb35d352f24a0ab9a10439492"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23616"
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
	echo Date of packaging: Mon Aug 23 15:07:12 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�\��wX��E\�g%9X{�,.�P���R�0�[�%�F�d��Ӊ7me��.�:&����HD�bD"�ⅰ[7��]�����#���'�A�F^W7M��U�5Ʀk�O]lNl��,9��2|(�{�k��;U4|�h\���`(�c�v^��Ό�cc�69��x� ȵ�z"������Ұ���NcD5�@��Y$��x���"���^�=�ST���	X�P�\���@�I��]��D�J��1�Rߍ `NB��]��yN�!��wgb.��j;P35Ti�b�6Z؜���	�j�}q����j�э0���b�6~��>Y��ò�@�-_��D۔͍�=ˠ�+���Sj�"����ϵ~�m���²5�����6�ƶ?�(�R�Ee2�'�ΰ�6��CJw��{c���e�X8���e%����X�Pd��~�c���Ф���4.����4����r��b�399�R�Q�FA�5�jč]��``�+=P�4u��7j��\O$�1�}�䟥m��l�����T��@c�0� 6�5�lִ5�\Z<r�aG��|�W�y�a�q�zMg�o�G*����4�x����Z8�b�Y`�^��⇑��&�X�-Ey�]\��棰�p/�߽b�����6&T��n<�
����C(H��~f|�_��h������?ьN��3<h��z��~|[��K$�_���B���p�*�5"ͥw4c�Ċ�5�D���	��e
s�j
��ɰ�ݭT��m &.�_��ϝ5c`k(���f�,���J���0����a$�m�P���6����h�*2Y[Y�����;���y75��`߲�!dz��+����$�V��`/K�ɠe2{����x5&���a}`�@�Ioh���b���s>C�swk��D��.�ta6Gλ�dBQe���5=�+���囲L&\ȇ�!}�;Xc��������p�o��2�ȓH�5;ձ|����ⴱ����WniMϧX�E���L�JH/�*C+�U�w~�uh��E���x4�{�
��h6"&�hz|/�y2��� Xè��E<��֯~��,7���~���9��Z��)�糬ch��[�,w>��Zݻ�,��cɓ�=�Р�� �,�>]���0܏��f[�{�����:�-u?�/N���]�.x�2)��.9�p�pٗ���Lt[�����U�;����~Z0j�j��/r�:�;%zs�ʚ�o-�*�tr��eU[H,����"��Z����LO;u��T$�b�s�ϗ��ت��{�����˙>S�%�&�Ѷ���X��@����V��Z�� �zE�{���Ԃ!x�sYY���v�)�Y)�<c�[&��1n���sp�˾�����%���Eo��������fcL�!�b�OXWO�uH�]K"ؗ�/�~�#�0���l�����|��(��].0���A��9�y��F�����ߺ`�|U���5�u��d�?�)3'M|>�*|�F$���K�����љd/do�#a��ě�����w�r�n�#Rv�0��N�����l'\�Ȳw_� \����&�cȺ4�m�{��6g]�eԻu���,1 b�ICdX\�8�ʶw��H>9��i�,M1�D�7,ܲת�Ot��������Щ8֙e�_��C����1����~Y��_�<gybA�s++�w���e:�oQ��z�O�FM��Lm�F�<Xo40Ϊ���?��N����Y�b�k\�U���S�I�33zN���Hu�G�Da;0�IE=���3o�v�6�M��{�Qh*����Ʊ�Z�o%�dqg�S�$ĕ�  ��x�$ۇ�_|(��ǽ��J�0˵!�^'��s����e8�
8�{�M��8�T6�e�N�?��}�q��Q�Q��ML�U8O��(��B"�e���H�9����J�F�0���#I����'���W�D2N���غ��L�}�:�`�m!�k�̈��iq�iW,�L��B�wZ���
'��q��QJ�q�#������G�Ŝ�Ĝ2Cem̌����R��4pu��j�4�4�,�9��Im�BR}�9��6-��u}V�I�U�e�8��CceVM({��ݛ"qq`L�"�M� ��R�L���.q�PY���k�"��
)���YP&ɧL���Y�-H�M�KkL��Ɇs�0�yxI��-+u�-�숱��)m����t��k�OD%����+Uz�h0�/�*�Pg��E�m����i����+r���J�M݀���ae���E����2��R�4���Hu5i
Y���8�����,��
ep�9Q+~)	�5�v�V��0���7�S-`�R��؊�<��uvC�V��6_5��hA�o�t��ͻ��H�O�P��慯�?�nۑLJ��^��r��Z��A�֙�J��
�+z�"�T~��ǩkh�n�l
���\�%�H,~Ƒ%�"U�&������6%���ءԺ���|f=/�K�eo둍�SF���)	z�����QV��y&_��~��w��ܽH�{6y��t���|���Bǜ�� ���m���V�4(*#3�6�3��s1�W'�;=`���Ki��<��f)��u.�>LJ�R�1I���۔�*X_f��VT�����/��Ao�i��|��o����cw�y�g,�X���ԑb���t�P�13�� pOY9�|�o����^r��딺]�gJ8����6۬t��`�gf;�!G������l��},��@�R�;$hc�WWk�M�b�>s�T�*�m^H�	C�T)l +?�L�Ӹ��S��oY��AN�>:Rk�}�x��Z��;�<��=wr�P�[F��\+&�.���jz��|�7����.�����Z�r��Vu�����h��r��Y�lU��k4j.,�5g�#����՛Dvy���=!t2�_����=�ۢ3�B�l�O��n%e���`4y�=��u���U317?��>�{�)�7Y�&��bm���7\�	Q�?�H��8�L��V�JFjS�79�!��t<��Sԍ�c�����|*,_�� ��>�)-1}��.�*�5���ȟ�y�I������]�2~O���5��駴	WZ��tzFR���@M]�8�p��a5�O�`'x�Z��� )>A�FɋHN��Z�a�4��xH�q~�kɭ�����=S�L&��U)�"���n}��(�8��V�;�Ǜ^��8�	U�����uQFx�S��saq��Ȋ�&�+K�apБţa5Mo�e��z�QF�֙�V;��}�l)P�}KAi�4nX 0e��B�`����V� ~�!���;<3����W{�L�dt���'ʔ�tH`�B���[��0�)��+�R�c'�boW+Z��q��Ѥ����s��d�=�LHŚ�%�H��Z��S��(!3Y��_��ä� ����z���ev'm��_�/�F8ފ_���⳦���۰@���1�H&�O�}�k�_پr-��)9�P�Z���!T�"Z�H .."!j��w�)���4�d"՚�TH~"���Ο���Zx�u��I�^�������Nr12�H��ћ�q��\�!&���6K1�xHj;W��ōj�W��~{��	T��eG��r��ku�ӕH��(W�ނ�I糋���B@�pZ��{�{�n��g�#�_����H_2����Qb�����r3�Ox���,a�6hN O:�����yB�(�P��K@�T�~m �⇋�L)���&q��G����B�/�G���[��o 0|�3{�΂�U�!��.�kpL��#��-�m���K��-�����B	�Ќ*«��
Z|�e~ �Ʀ�1$�>��*%������-����%�xYe�@�Z������X^h{i��\c`��/=�M#�^��r�P���MI��f�lu�,���P�a7R�����a�!�dy��l����,��&=�P�6���?b�MY�r8��@8�x��vXT ���q��uD"�����	2H��u�N�|�Q/���N��U̬.k\�W,�����e���Z�=�g[���X%�#[[ZΔfH�S^�rvT:� ��{nP��c�Mbtx $�ELC�ȔG�)���lq2��/���3�~�/�.A�7�`r�܊�M�a ��D�)/��QUQ% M٧�t(���0ZA��1��}��x�OKU�M���դ�y+b��~W���{+j޵���.�q�y=�bN�4��'VN�U* �C���C�gm�s������$��ĺz�.BGO����&ř��sT͡F��d���1#;�h�J�$��řn���r��1�AG3�[c���W������M�2e�V2&,^il�8����B1�h�]��l>�ƩH�D����/v�I�k%wI(��-�9����.� @��p,�xs�-E>-�h#�i8��e�|Ј����}ӲtQ��� ��9ʱ����LdTw)�ߑ��.�@�ב�FT�說��<�03⽯8y�ت�����qշjbq�~����_Ô�`tQ���t���E�i��9S�"��C-D.m�((Z4G�5�P�T(�I�RLO��[�i�f2�f�yK��tb�������Qi�Q�c���CA����U����H�%8�'��8D���B���_�e�i� =��;�LeN�9� *���â7f�sp'b��v-N�J�͎��n�\C��mQS-M�� "�g��o �.�,��ﯤ2W}��SY�-=��a��¶,�����jӤ=�`�z�6b��3�+`���cN�h�n�	M%}�[|�1��;P?z�C!g�g�A6`y�
B#i~9ef�3�A�K����tqֳ��CB�&|�+��"��w8���L�)P��u�@4P���r�����s���2�Tid�I�}/`0�dL�nD�7�{������f�9�#cXߓX��G�5HE&2��r�q�[v8r�)�G���w��kBC�[��#�'����'�����͐��#<\��\h�&�:����W�¡DO]�<0��I�;4�}��\����`	���S�9���E�^��ggE�8����~�x��R�c�p'�6֧Q*�O�|��p\t��?����rY4[�c�WC�)h�@�S(ш����2��| �Z$�wh\x�L�F�m!.�n�,�&�A�. �SsJ96��=��2�F�h�Z�������֒ԓ*l��=����������|0�����y`�BB��H.a�R���")�2��s�
zb==�=�r�1�VޠI(6�]͸�5JGx��={��SIE�&��,qj�s�ȍ3�R�q����.�wڏ���A�a͋
��ˆ�m\P$�-���F�&��<hfD�8�e��OPQ�>-��E�Ži�_�������)fqg-������Ζ׍G �'kؖ�iC�p/t��b}2���ta�
���ʇ�7��e�gj���z�!�������'! m�V*R�'���E0ZԱU̙�p�N"Ģ4�{��^�:�Q��������
?�`��kWԌ}��|��wqs8�~��vA�6�t~�j��R�� .<��OZuRo�F�-�����5-��4�I~���(;��C�D��\	��� r��c�{��j�t�= �FEFL(���W?B��E�\�/�K����D�X ?�A
4��6���ި]�O�z��h�i�ό�~F��Q�W������h5�:\UӞ�5���k0�n����f��@���Ġ�#����0������[g��D߅~�}" 4�?lʗ<��oP$��}�@���
��:0/�6�AI.��R\�H���v�d��b�M�1�-l��,\�N��5G]��:.Db�w�> r�X����Q)>��g#��i�4	
1S��v��Q!���e�cL����i����<BZ�I��N�ЫQE��l�b.ܶ�R��lr��z=i��S�p]s��.�f��emo夷G�Wά+Y����� �9�����5+��q����r�R�b<�4P���R��U(-h���Οw����P��luz��>-A��z-w&8��\m�+�?�kL.�l<����~}ݜ*�U��acy�����yAb����͐��U�7���v4P>C�M&""+;����LG�2��A���^������K��'�4�l�K<�� )h�������66+�y��O�	�~מKw8���_�Xy�wk����v5$0��Y4^v�E���2�e�wF���k�Yhc#�hw9����VW\¨S�7�.�	�v=�V~������A'��qt�W@��n7���pPu�D ������
41���Q� �
�S�
);NmO�f(��)	�ҡEX�grV�F~9�����Y��Յ�V&���~��[:c���I#s�T%M���iJ~�p�;^�ͩY��x�Yw&���ס�"�T����r��"�`f��2���<�
QG�0���EP"|��wҐ"�;Z�c1�䤛3�l�T�"s-������0D'$a���B��4�9�+���Pj��E6AN����!�*\"O�o�^�Т��%�#��6F�S�v�W4��J���u�vIVʩ
��&tL�6�L8B^��K�f��[�y	�39L�����w�~���� 0�� �S�s�?晩��4����e�@PP)z4ڿ� �Z���&@>2k~s�r>C;ǧ��2��%e��5�Ѿ�<_E��E�R�������i�"��L���v�/����e�2Mﻃl����~>l�6*�b����&�*鳣 w��x�'�v��Pl�`��-YA]y:�s���4�ːt&���2��/�7\�Cn�زu�P�CO�i��stR�����?���]�pk� �^�vS�N�"����?a�s��dY�*2gE���g�2�0�)��OZa	U�E�{��F1(��n������·[E+�C���)E���ۆ����wxU���+�5���U��3���thm]͗�<ԉu+|~-->�K���� ��d�lQ�)�����q?�yR6 y(RJ��N{:&��/��Ш+ŏL(��q�j����.�N��p�1&��m>�%�"������'6��	DY�v8���*�{_7�K�����I�Ȍ���]�k�C�,�g��:H���l�>'̩�1�`��Q4�*���DHͲ�p�0B0i�w�BT��Bz���7 u|�|@���EX�	P5�J��������=�I�K��Ax����.��Κg۱�Q��~5�����i75�fD��`M��U5a δ�Gz��n��~�!�@�j'��ٓ2W5l;r<5G��mӲk��%0�"?x�{��>8�"=�y�q�mb�����}��!���t�A#jD	쥷G �-�a�w%��n��4I�8(4u��y}����M�����:�D�]ݐr4�� �턢�m��pJ�ߩ�4�t����DN�>|z�kOY�Bc��Dh[��q�0db\a!���.V�X_1��u9|J?�Ӳ,��բK�}P�o��ڏp�L�`S��z>�\t;�u���ՙ��~���8�O ���<���5Ej���'��i��5��*ۄ����#YY%ys����������r���!��UX>��A�3�y�x�����v��ݽjU� �S�@��p%b�9&�B�ڽ�s��+So��v�~�f��J_S]e�m8|;,����jجs"�C��+R�|�K������akP`T�Y��Vo܂�ͫ9S���#Ta�����hlp��{E�L�B𩢧�עQ��\a��Oւ>������5ρ�?���N<K�'R��J;�L*Op>�bn��c�,|@։;���l�1w�4n3j�a:��(%N�bR��������U���筵�g��p��E"e��8��S���"�����>�L.Z�����bv��?p��(��>�M^]cB��Bj��x�O��h�o:'��P��ou�vL =�A�kcE�:@$�UA�ۜ8����+���g�}�0�q �8�d��d����G����N3p ����F);Gb�@'Fh����P�)'�*��"���]r���X/Jk>D��e�l�|Q��J�+Z�yg�rh���C�aY&�7ԑ�WB@JR��K�6�l�e�>�q%:̐�j�q�s����%L%���4�`i�A?��)�����)I?Ur|��wX8!&U[P0�H�C8x�*H�"�o���ɜ&'	���.L�����>-ގ�s$�M9�W�#)ey�ٿs�Mv�J���h��OZY�k5:�6�V�'ۥ{Q���q�jj]�~�1�i햤����}jJ�A��5��
N[@�Q��bfF˼""���kV����h����L���C�xfׇ�_�e9��K�&Ȍ3���L�#���vƲ��Ъ�w��m�����'3��	���ʴ2����a��͂��i��cev��*<8�]z��4A�g�[���Ńkel~q-,D�n�/���,�▪��M+�yQӅ��R�$�Z�~����yd��8��6�#���STKC�B�y͕����%S�U�S��u�7��^�0�f,H%45�6�熟���a	+:��g�80ǵ˕_�+���s���]}}4U��l�&SE�"V"s�K���XT��J�G,�*���fj	d��/k��>\u\j�JS�G�?ݏU ~�,��_��� OJ\/X�gk��> ��`5�ҝ�՗A ������ܕhu�
��^��Ny�V8�L�8U�� ��E�Ϡ/z��*&�}�����
�T��som���n�a�^�Gѣ��v^�j"U�9�9En�%xE�R�3�T�)��������/�= �z�M+_��,�%$����zٶf��1)��mb�͎�RT�� f�@>�[��b7w)�u��Y�����n���7�q֭�oL�f�"��e���Zr��HT���/��P����?y,Ɋ�'�ғe#�ޢ4�UN�?�)�Ws�F���3$=��M����c��㋀qmŸFy.n��e�B�m�w�pjC^�o)����q�Ô�Aҍn��縫y�/+}F�t��KJ���\ڣ+?��1���¿z�|��M��˗'�ή���d��10���:u�B�}����g]�T"�������;�5k�e���ȇ�t_���j2Y���Rȵ�[*
t��)�R�d}&%�
�Sx/)R3�!B�d`:=�`���.��n�]"Q������������4hL�/�V�ś��R��u��;,Z��v��fQ��p_^9���O�_?�4��E��M;%~�0��y:3wh���M���X�r��C���G�d��f�`��Ş�A��I��h��-��lT�!%�_�Ȯ��%��?����rJR`�W�<�U�'�$KܳT�e��gt��+1fd�ۖb�Y��6����\�b�ih���&���3'��
��iC�J��2e��@+��H��dc$5\h�!�@��L���,��j�g��<�R�����g蘁�j�G�=�R1a��#�m�޴xT��p�Pa�}�֚��1H+�������B��z�c]e�!i��
�]�~����Chr�}RhC`�i}'e���+Y�|���^��K�����U�HE/�[��x+�R��E��GFc��g������c`P��A��1_@��r��(��%�_��C�Mᶚ,�W��p��:�3D�j2��/�g�	x3Z+%�ư��p��uo.�
`�	a��u;$��Rg`�.�k_p�^�h�������׈dލH�/���6�[�0DAY��"�g�G� �����)�Q{=�ƥT�v��{d�@�L#�P��
_�K��@�ԟhP��r��D�9b�� ��&s�8ʠ��:wd�~TN���p 20�*�-��54%�ROUq2KD.$6.j,J�NC�*�]�5��(#�y���3�j��-����:��Z�O���м�$�?�KI�ݫ��� [����䓢�6�U�94[��v�X����5v뒎�s��m>��!;4a�h�#�>y�1E�	�¿m�����p������ӹq�;��'r%���7��U�L���X�W(i��rl���=3�<�=�NE�t� e�`?@��o�p�<*���yL�L>��@x	Gjt�h��)q)q
<٥ ;ֳ"(}�B�yo`%9L}�����S�
]�L��k����t��4�q���ӛm�n���@�smTx
�0t��b���^���8��i�]P��#nqm#.z4��݇!�ŏ��,�괝�����htB�)���"@���_a��d�X ����4�PW�s�l�O1�)uEX�}qґr��9�����]��.�?��2�,L������u�Cj�r��?�
�5UM���.<�-$���$�['ulr[[��h���L��%��9OG�ԧO͉b���Z�����:����9=�@�3�l�2�DB��4�b>\@y�p���	lͣ�)i���T��������X�n�$;�g"��OY��MG�.7� <���� =�e�=xJ�<���.Naäp8C�Fg��F[��{��e$~��Q����3,�p�"6���z�[�%�;����~�fw�Lnq�;�ݛ!���N쁴�}Z�Eї$��&��l��SMg_��u�9��4G�����jqd����N���w�����q��U���j���zE� Wh�|+��b����r�/�6�9��Й��2��>&��b��9~q���i��8�U���i����.�r'����0��c�ԥ�`V�1���N�zA킎E?ɐ�e3u���ƕ�1 �sc ^,����R&�4�4����xܷڦ����2szr�g��F`�P�
J�|� ��y��� V���XdK��UHC�X��"x�Uh��m�gE���T�N�����.Vӭ�J��#�A5�b��?a=��drYZU��O�F�;�ta@��]��n ��À��$9�9��w�0ز��"��R���3��M�D�X�f�h�_��JS%�8kk�3s�,zCTI�v�%��|+<��>��/M�^4G��#Es��xQ�f�r�m��%g����]^`0�ޝW���FQ|���Ew%nW����.R3��_���y��p}��J{&}�h�����Ө�=�
"P��5�+�	��7Rsm#�I슮hMm��/�2�x3���I`��@OJ�R�)톯d>�+��|Y@|���(A*�sˬ������Ŀ��cQ&L�f���伛�fX�w%-�OE9Y"YQ�qa�jCZ�/{���QN{ա 0Y�3��KC��q���\dO���X��@��Fv/���~*>@��-Mcc�coV�%A D��1��!iC����z���V�@5��Bt�6���>��J�À�K$V+g�,���t�&$�6hq>�#�X��ѢD� ʁ�Ձ�ㆡ%Y�W�r	�T�eўj7�"�nf�
����%`5$],�(�~i�{.$���.c��^9!�.����H{��"��e��$1' #� 7M��ܑ�긑�B����:��bJ�1���]�d�h���T'ރÌ"��1<����ѩ#�2!����4���L��]������Q�/&/j�Cb�^ �'�Py_�y�U-bn��/Yړ�嗾;K�F�$ܫ�
gc�?w�����?��!^$�Q˙�(嚜0�LtN��{6��E�'~s?���+!��5��ݩ�
.�X�Ǳ���(K�6U�.�����wJDl��s*8��oy���n�i	Z?/(��!�8�lB����D�_����b��q���Q2����{	�!�:Qa휎w����)��Gx���rV[X����Q�:2�f*��ʃ�(�u�n�)����`���>r�O^�f��\b��j���r:xQ*���_Έ�#*�:��x�ۀ�U�G~(��ώ��uxeD5@�eW��I�GPZ��b\���0��ΊgLi�cR���ַUY�5�4���	�T1�.C,��Qi4�U���q��4o���I�ȷh=�0�$����1��3ώ��r��L�o�V �:1t��k{Lv:��+V���ק.��n҈n3a�FT�9$Z4!w9�6����X�<��M���|��/�Hmva̱�1�M�&��7�
K�FƉA���j���I�@�,C|!�z���?�Nh��Ƴ�19���i�]�m�=ʡ@��!&��tL�����$�G߃�X�W�U*"�a���Kl�x��5@	($\�/�&��0 Ɨ�i�D ��O��Ɣ( <fX��<;���-j���W���mRa����We��\b+�)���,.��>�R�?S�h�b�?��va!vh%8��+'WLWt:̄P��V�N�S�s�`����6��,C��B���J�\A��iVl@���:����e]r��I�)C����l	PU�2��8X����y�f��?�D1�˲_�ּ%�u2��v��@k�ɉ�=��f��0�i����ā}')`wp��hi)�Q��L?k&���s$.�3Յ��,@]TĻzE�=�z�3�2��䗘8������y6R�]�Zy���N��Ν9n��2�Aq�8�A4�ʤ��:�煳��K�@\v�h���M����;�3(� �)��Q�']ջN7!4�T�O�������JB}�]�Ő�$�{l�3���?u�O�7������nSd�� {�9�E�����	 W����
�2s�b:n�-)�^w�d�NkAr~RF����N�<J���F�</;��ap !o���"�M٦z5Ƕb
�Q�Qr��5�y��|e�����:���?�y�Y�UU���ݩ;�i�yoA��#�c{9����O�qa��ޫL;>}���f%߽�.xt�����h�i�K�����$�v���v�.��k�B���[��K��\Co	Hk�m�_0���ПN}.�fq�d���E�>���O*�q�iM�u����*�}Aj%��t��k�:�F-�Ĉu��\�Y�FoxA=v�)ک�0Y������1.U��cx3��N�@���C�Hs�����">���ə�E$ԧ�bI�'��мztV�W����J ��Qq��jan9��]�uc�ͳ%��]~m�j�{����^�yD�:�7��/�y۽V�Պ��b[ �E����H�#��Ώ��S|�R�w抾����bM`�Q����E]֯���L���;+�l��` �xw���"²�h�G[��8#�?io�a�z��;@��l#���?b���tL1]��������a��X�0m\�W���;�A4*Vha�H��uK+��.���:#�����7�J�w��0%��w�6>�W���P���ޓ�#ÄƏ�����E?�׮��<������Q�z�ވY-�7�-n�U}���>�� ����A��<l�p��:1Nō>`v��t�"��w�\��p��+T,����(��v��2_�5~�<ȸֈ�Ą�� BK�Y3�$��R�_�q��n���읪7e�}E��8�_�0����z��R�%�}.M�'�v�Ѵ��=a_�!�G|
��.�<.�����9�ݥ4��YK��7��d��wY[��AȿBzM0���}><��J8YR)�0F�'8���g?SfĄ h�n5BV{��u���t�b��<)�j�Bv=�S�0@i�^����b+��POlcjq�x�͹YM��w�� �s�#���.�k�Z*9���}�x�}�ݲ�.�8�O�y�|C��7��b��O͐v}�*�i�{+�AI	K]0�� ҝ���V=yOm����q��K'd��Y
��-�����Y�������O���/�j�S��h��+�&p*u�.�3MlST��f6�2���K�g(L�0�� W&ciQ����ui%�Q\y��Q�]@��<�ްp�u��~׀%�0�R��*Hu�������M���lgQ+��Z8� �z�$|�Dǫw<�l: L�sD���4m�:ș�W�w/�ZHAzm��Lu4pʯ�Q�� �IU���34���5��`��C��E��i�48J��V�U�<`޼;�JNv[3O�����_�h/xv3�	m�^g���#Ԛ)b(Z(N��m�Z(j���J�XO��ł�j<�gt2�8�M�|�ͷO	6$�YI+#&RӀ��� T�qP<��È'���aՌmȫ����4i������q_;y/j��og#z%�(V��bX���]�++BsA�*8n2�H-��~���"GWB�[�Cv��G��L���s��M����Ҧ{� ��ҝ���JŚ���'�"Ru��ۇ�A�k����g��=n�����N\8h����X�Б�!�:A~�|�����e5f<n�k�:5R�_9$��#sTQ-Wv��Pm�1i@]u1�=���ʦ,��oBQ��}����.Kd��������TU��6<;i�[G�b�d�tjj?�e��76��i=���A�*��t���,k�d(��.U����A+�� ��p�N]`� �����6|��m��AӶ�o�m�ê�0��#F��h=���|4ޕٛ��V��&�c)��3���mG�Gc�;Vt~�*�n-�욱���t��͟��u��.<s��k��g��D&��Б>�L9�C�0'�������5�ϯ,[I�L&]�`��
�}��x���_�{���1|�5��<XD*� fN���jir�
����[��X�H|�ý��1�J��D���z�� Y�=-�B�+c�n���1��H�FG�JsWrâQ�vc Y����Hs��sCWVg\�n�;�`�^(9׉�m�%#�DBS�^��������xGb�@�&���j�<vl8����/Q�>�����l�< ,��а{ht���������E�i5��
ے3V����2�P�h�#���͢��W� �1����}K)������o{_�fuנ8�8���|��;���Gg��;IL�ܱ����L���w�Z4s�cv�
U��A��MW�9�J�@V��Qif��7ᔽg�&�KpE �,��x�UF�v��]��;�+���q��]�(>x.ԌX�.�7�H��,�.L�G��Dsv�����ZM�wwI�P�5���z�?�o��.� z�JF8�[���!k�e�]�L���=��ѷj=�gi�f�B�i ����6��_�/�ri���6(b�
;^��,L���or���4 PrXf�FӘ_jy�b6�f��U\K�W��V�^�)�O�������7Hl�j���ab������jM��t��,�,	3�{���,j�!��TuAJjYgܾ4�%]����e�)�G�^rI��Z�Is�{
7���gYy|12��ZR�N�`� ��p�tR�������j��2�_����#s�R�����>s�p6[
�mƣ9��),5zkaHr�o�;pU����9�p �):|�����0v��m#:o:����L�X.P;��ԣ=(�#��ub��p,��H<ΒQ��ϱ�ɟy�'��<L,�K��$�z��3W�`	�K�^U������i¬ O+i2��ۣ o	j���"����7[�$�'r4�K��=��s;sx�\�$"�^���2���IA�v��Rf�ӈkO?-�Q(m膦����@���29X���;ȘF���&Kpi^��|��V׍�w�P�pqgO��[�_]&1�H0;A���<�À�`��y 6�>���G�����fȺN��$��$�N��s gK~ڟ�+�a�� �C���!8��8�n%S;&(�p ��.�n�4��{"#�Ozp�q�Rÿ'M�����[hD�Q�ب����~d|W��^F�w7�1˷���q����X����3�F��>�=�p�h&L�q0}��+h��7�G��;��<0*|Ý�FeBى�q��j���[����
V���7�tƔ�L��q�+^k��I{3��޾p�p$��΂�����n�*�J��oQ���W˽l��çv��L�m�h�B�jf�kp���/����ԐQ�~�U�ޜL����j�[�32�`�W�0�=��^��� %@x�<$$�)r�gj����9\[#0_�E>�U��[�Ґ��4��5�w�>
1͚�KF[7�;� 4�x#a�K��O)�u��MK�!�%� �tι*��b�ex�ѳ9��Óg�b8vHN� �:Oǧk�l)�{@	��L	� �_j}�.6�ౝO�P����#K+.�����,�.^ �]����:�%7��_���Q��V��<%q&�H��%��p�a�W�X_P���Fx�ņ"�c��Sə0߷c�e!�������D�t��_or/��jg�f���7�,$�W���!�\_z��4k�#���i����R�	�%�X�ʌ���I����b���Į`���k�D�om촻!4�����g����Ԛ}8���.�@���3��W@-E����T[�4]hTT��WX�R�s9:��(pdװ�G���n�Q��:�[��?�p)iA]�[� �H)�[��F�,~Z
/f$�G�u�E���6���lˈ�R^�}�~=�r�)��>})콓�m]s�
��� rm����sw� \=F�fr9��V���}H[�Ol����M\�ui%�-�~	8�N���6,5�3�w�稯d>��}���y#
qg�o*�kǤ'La�E!I!�v�H2P�G�ʸ�*���f�^LeU`��`/d¾����3DpZo�N�t�J�o��"V��s��u�绤���� �R�^X�U5w���Z�_�:�L��+g���k�#��G�`�/�L�7��Z��vEk�j�J����<�����]0�e��;�>@��hA��Bn(�s�#�ɸ��I��kM�'r���'n�\A���Ñ�p)�E%g�V"O��%�Z+������@��iq�1F�qS[��х�$M���B���^H�q�
��-[�%/��A<g��������9>���.�k@�2�qgꅋ�b�E����7���ۑxBA	��/�3;zSL�\2�5�#U ��M�/���$�N4��<�ip�/ҝ�;�p���B��v|�1V�)q#0@�oeBl�����x�"�u�n���	��/��}�֏���H��D���dV�n�$��?¬�ٲ����z#���<CLA�7Z��2ǲU���ڟ��Ŝ<�V�<Xk���1e����od>�p�H�
�,�ZpC��>��\�u`s����_���u��$��/�q�S�u����^���A��hg9/�lIzӟ��,_0� ���&���2׻�L	���m���7D#��o��� M�ޙfpņ�=4�$���Ky6���B[��SG�J�\��-��Y�Ubw�H���ic�����ED����Or�n��L(�T�K�ʌ헿�E֪f��LF�eb��X�g��l�8�-;x�6`��5�+��,�{��4<�J��j[c��T�s�K�y!��}�W����m�ȕ���Q՛_Y9�gǀb E$�nERӴAOP^��6/FJ6���3�����l6���9*�GA���<��	H�s����ۣb�ՋԓB��W�07���@K.?�~���D���2Z�92(�zh/�����h����  ��RM�pk��<X����#}��Y\8��?�L���^YO3I5r�D5��@�`8�A�{�B�Br��T��S�����h�d&�b�(
,��ӟ6�e�[���^�iM�VU��y���R��-Z95�����P�2���v�qA��⑬�RK����9׾7|���Sީ���U�q�YD�Jff2|�(�D�Cr� �z�,Ң##���2s�z�o�4��6u���Ԯ�����=آ�Ȫ���i�[;~����^�W��X;,��wn#r��(�￴�r;�d	)��W�q*ɀ��	��8����	��b��u5%|��G��^Lɗ)%��|Gy�|����<c�1�����EƐn!�T*`����Yw�a�QB-��.^���B�!$��Q�738�@ɡ���Q̥U/�\ho�f@�z=��du<˃7��s^�[?����n}�'�y��,"&�Z���M�-=�q���Q>��Ҹ�p�s�=�3�(��Ǒi)��#�bΧ���C<L�M� �h����*U�Zݨ�ƕ��rZx9j�G��V��\z�3���䡱��,�p�_YvܐQA擰��)�ѕݗ����8�-�t�3?iƛN	�L$N�R������Ľ����Q&�NǯqV� CGbA	h��q�A�t�]l��j�J�C� ��Y��*.�
{N�ؕt��������d�cx������_�CO�Oz�e/�QBB'<��-����7�R�hC�Wr#|7㏝���#�%�|�����h^о����!��c񮆭�����l��,R��o��Z��;�/���:�	1�fϤ�ߺ�r��q؅�V!q&<}�5c�5qg�~����S�S�-�.XX����I	aD��'3���������h�����D:���$T�ӧ�"�	}� �B-I�;���@�:0��̶��(sI��m\�� �`��[
�.����?0窰�#�������V'���!�0�=Kw!������e�-'�&��H�-]����M�؝�S�p�4K�o
�\�$HikO�ZW��)�Q.
��t	���`�>=L��;���
�\Yɕ���%��}��.c�r:"#���.�c�^�)�nm�n��uM$#�P<�q�<��[)A��F;{�@�����6�(v�̝���?�o�˲,�ǅ��y%<�5��70�J�ei�@Ê��RnY�Ffİ���z׹%���������2��R�8����6�n�&Y��^�К��*%�~DB\;�:S�Z�OP�\N}u��N�wU�B?�M
q����v\��2��:�W?"��%�M�~�u�q�ŗ���SͰ�C�Gۛ���S�\)}f���5�3��&�ݞ\�_Jy�}��E�e��SO=�ڑsK��))����ݕ�HЅ
(�=g��e	°�#��o��0�w�o�~]�r�TY�"G��32R���`az`���{�Y�
?~��.��B`yǞ����q�-�����w(	|f�DQ^������f�:bl��{��7aM�J������;%t���ޢ&�Y�8"XU2o��U���gFN�/�A@_]����t���KN�`��o�)�V��0���&	xb���}Ic_�!g��4�u�%�гB2�-]���I3�E��`]Q�K�\�|0�i�\Kib�}�ݪ�x~�|���2�a����1�n[��% c�ٚH������օˑs�i<Z�"���[��ЖdM ���C,lnƵ������a\�t��R�ć�X�_#?OM1�^�n�%�p 3'~���.��J�f�bk�!5
��ۡ[�ܮ�+�7��C� 5���I����]!��6*M��k>ͬ`G]O�m0�e��
[Wz�=Z5ɪC��=iIRF��o%S�c�C�;ܝ#L��*�-�}Ў�k�ͯ�8��X@�{Tt#�?uN+�m���"�Gaڤ�jb��8D^C;�� �?��_Bӎ0=�<���T]�T
�0a.��y�����ѭ�Y���I�/v�v���}	��op
y~��C'�H�רi�Y�&�,���R�O�*8ߚ퐑����c�zl~Z�Q�V�zU�>H���"is[<)���,�D#%�B��c�,�FY�D���b�m<|Z^��9"����:�z{��.;2�8���U��FZ<i-���@�E���Qh�����h��4�g����&'��x8ƹx�1?��y�㴵]�I	�l�ЈTH�k�ց����S.��<��ﺜ�V����]��k�>�������������EGb��[!�jy�u'#�8�pk��,ׂ�3+��k�u1��q.eL�I]����sV��!;������a�e��4?�sxo�y�A����&Nw���m?J�s����Q�P�R�&YݒJD&Չ�dske�s@[�Bz�pc\\��DB�3H}�'�E�}�U�e� �y���$�(�3=���Mr�RWZG�"'�\8��tx��c���!�&Θ�*B�z]/��9;L)OlE#�:&,�A�Έ8m����bȜ��	���R�o�g�������v�����^�� h)k��ݽKgьSύTb�8{P ��.��V{�_����F,<w̺�7�D����Y�C�vtA6*T�Ĭ��9���0K�pB�V� sⷈ�j����U�@(��ٌ@���8B����焿4��L�\��hA�}B�xY����Ա���$g{�s�կ)5Cc���,�ޡ�����f�vr{1E�S���ʪ:Q�|~��Ա4��;v��d�U����R����6e�f+��4C_�����4N�n�����f̌� .iU�wy��w~>ϱ�K�ͬ��A�	A۬;\C'U�ܟjs��d�]J��rB�o�:S�NK���9>��w��J0Z��� ^��#l��´Pz��t�
Q�rr���h�>+U�5J�]�G��Q:w�k�x9��FZ����8V���/��M�Q*Ĺ�j7�~��w��9W-�
�użF��m���*8)����jr��}0�Y�+��a��e�"�r����e~�=}���(u�W~�ʎg']D�����#�ß�v�K�3��3��R5���x�J��x�Z��C�h�=R����fAɗ����\s�Bl�m���JEʵ�r�|�p56�������k� 5M��NcIE�xk�'A/¤w{�`>��O�h�����\[sz�bT��Ԋ�U��%[�Q7ӀA��Gb|����:G2}�(E�ӥ���_�6=������\˖��[Y
��4,6�湏˛'�ߑ����P����T�����|~p��C��r�?�λ:�����U+D��KuN�Щ_P(X��pPz�������+��{`	]k_S���1�L C�a<������遢$cp�q��B�j��b\E��
 �G4>�R����kpE���a�<��]奰ɟ:�2�y=���~�xы1��Mީ�H+��]o �ny|C�+�*�6���-H"!�C\�ɢ7�B0Hn�WX���4g)*A�n�������BUڸ���T/m�~.�nVC�,Ȏ�xL�(ds�W*w��ׂ�%elid ��a.���&���I$ߙ���1�$�J�5���A���A� fRF��S���1��f�!�e��6"QNfW<���l][Z�v;�D.3��7�#Z���n ���RE����a(a㑟���3��H�N�,	�?�xW3vd3����'/+��ٗ���LYY+QN��܉ѺY�08*��ːԁt�;����)|��.�����&S�g�Ě��(l[���j�>^[�)r�mu�n6If����kC�uW���D�p��*�s��h�D��C��Ɖd���R��?�F����W;�[�#�Ht��p����%�l�k��+Vnp�E�E+�;��Q3?�E���rY?1��iڜ�C�7��G譪ks��/i��g�4��{O\Q��Q���'5kS*�u�w�� ��g@��&S�27��2�l6��� �.����H1 �K͍���e����� @w�j��2ݥ*6���;`�u�d�p׷�~�����А�-�:�̜c�~�ڇY�����~���T��0^�F��"S$��vв�a��\A�\9�U۞ec��ج��OqP5����Y�J��!!9eX}!ޭ����p��2��[��kk�Nʲ�b��L�DGmaP��'��<Z�(�gw^qxu���	2��W��t7-x��D��J.���|�Չ�q9@.1(�r��o�'�Q�~/�p���b���'�����]�#�������ax"� 5�L)"u��*�۽���#��m��\0�va)[�1j͚+�'L����&��|�M#���籠x#P�Hie�\���ۋ:�[�*5�gF�%F��4�P�������UJ��Z��n��f��Ý��WZ���-@����cb64�������ۏ�s �Ӝ�?�}��[.p��;?ؖd��s%�F�bd��V�֋��Z��Uw�.�_�掹�W�m�5���ѵ�Zt?s���.�Id��"�C�4���:Ǝ ��T� ܗ���}q��є?t1p�\��Na�&}RA�A���B���Vv�y��h1��>���n������j#���'�3K���V����x
9�?�n+b;�|�i��W,k3�V���g����^>7ٚ�K�p��$�ށ���w���W�1$_��V3b.���7ٵ����*�pIǳi�E�h�ǜ8#�$��˾".+���и��������3?'��B��}+kFI/�LNO2��ŗ��u�w�;�-&ڎ,�J���6P��T�K�C�����Њ�?�5�wa�F �R	ɜ�;�١���l�ŉ����3���҉����O�
�C�@�����.џ/n[��څ�q	�#���a��9�9����4�3�N,hW����j����e��l��0�����Y>�+U'B��a�k<˥��H�dHKj�/ջ쉲vv��~FwW��fq�?&�����4pd��ڵ߅
�5�>~�|�f�e�k( ���'riQ���3�J�	�i���j!�7~��TX���Q�8�C��X&0 �\�b��_��V]FÞ�Br�6�����d+��,q�΋	c�*�.���y�s�DK���G>�Nփc�ԫ5�y�p6�m�\������20�p*�^L�y�N_+�B >6�<0�P�9T�|�D����my',�jOc����O=�g-@b�I����7f�"�<W��Ѣ�&���D&�,�-}B���G�X府��b�4�p,�K��{�V�<�aZpji� ��=�A��V�򑈆i�%�6TRw	��C95��9>�1qY
;�796���>��=���\��=�U^^�����q�'�v����6B��P	�w_��*�a�G1�R%�$,9�^A��a���I[T���?fq9�P�i�h����Oӽ�� {�r��t�����x;*���	��}4M��ͤ͊?-xO�V+�n ��J�
-�J[|{nTbw�������z�   gy� �$�G ����%�S��g�    YZ