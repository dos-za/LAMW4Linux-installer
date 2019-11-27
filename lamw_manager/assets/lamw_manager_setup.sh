#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="342817303"
MD5="457361ad60aa37b8a24dd27a372b2080"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21279"
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
	echo Date of packaging: Tue Nov 26 22:43:31 -03 2019
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
� ���]�<�v�8�y�M�O�tS�|K�=�YE�ulK+�Iz�J�d��!H�n��_���|�|B~l� ^@���twfv6z�D�P(��u���i����~7��4���󨹵��lkgs�����lln�>";���'b���2]�������~�c..��5�4�������Na�7w�ۏH������7��v���Ε��G�J�̵�4`�eZ�̨E�!���=rx�y�I�Y��B�������=2��ԝR��~]J�"��=Ҩoշ����#͆���7����i`�!B��)QeiW�͈o!�f$�ީP�}�:y�s�:��@�Lr��O2����C��(9uv�~N*��������#��<�GCC�=U�\���h0�G��cc�dAs��t5m?v����7�v6W�t��G�q�Mw�5�a��������\�(j4�Ά �T�(Potz�u���U�yK4طZ���^+�E%��q�\�RN>��F�@��:nr������[��le=�k��%�+��� ȷf�-���sʷFA1v�0t'�-�hхh;�=ٸ!J%�.|=]�z�x��"�b=�>��&l����5���{YY��6G� g�]6�v�@�L͐�4�����|�72�/�ſ���nѥ�F�S]�3�� �d7a1�U�k*A���1�O���~����3h�7U ����k�M���2���&���D-����t�f��u�v�_����oI��bz�	<dă������P�te�yAT�|���i�ԩ}r��-�pif�PYU�Z��hWj:� r�:D��zbљ9� �l�y�f	�Z�����R�:_���Y��c�6��C1#<_�!�ӿ�WtJ��$�a����Q��7��ыޠ;���7�|�WI-gي�����1�
�.�WvH����P�J9�:q�;E'������Jc)E�"�FI�J&	�djR V�X67��t[ycL�´ݔR�8Y]�z>��>�J������@��$��D��y~��1��쌂���JE6�� N>,�oEM�X���g}�^8��9BR�^�@�����6���|V�����6���_��»D�1��I{J�Iz>x>��y�&+��TF��G>�{n�0v1]�W���� ��$/����_L�� ����=�sss������W������U2z����q��7Dm��֨��/��;=��:dr���`���y�m^ċBsl��ߓ	<�.d��d�Y�̆����M(q<��e����7&�:Y)��G~=�\�*�#|�ib�E{acX�(`2�s]��QgF�`!��o ]Ӊ�1���l������t=V�=����~ g5�w�3D�Y~�.��0��*��l�t�L�g��Fp��M��Y4%o����U������������������)^�Id;��������+���W��������������_��䂄��&�>�#�hķȿ2�.x�AQl�"�'�gD'�֠�bw[#-�
<��B�]�Z4��Єw���x���̟�i�i���H�M��hbYn���\ڔ+���Ƃ����~����xS�C���p��=I+�6c��4���0�B~
��է��$rÈ4��O0�`b�s���q��N�x�u�;��芜@E�?>|$e�TI�ifdl��F���x5�$"cK�>(Dv�8u/�c�\�Cs��:��ƍqC�0��q�����0T=b���ȡ�X��(C��I�Og�"�A��v�Ή_u�n�Ԉ�� ���4R͸�(�G.m?hI�w.	z�;=I�q���4�AA��n�����_�� CP���fX��⏫ù)*Â?��R�:�=�&�=7Ï� ����âK�2$Z ��0{1��Ǟz|�
��-��=3��%�{�?]�r	�ױW,�3�����J�+a:y���y��synOϑۋPMƶW��Zn�J���g'嘋��M����D��Ez��3��<�{2.����
	!?�PV��	�P���t����K����b��HV��zC��kPS��*\�f���w�����(&�K��nwO�ތ_�N:\0ع	�),� ���Q��ǒo��^�A��_Ւե�X:}*�7��-��G�\��P�����֭4�I�CmuHh�!�!}�*�G4+�/& B1�����紂�8�=7�9���W*v��@J�]�`m�L�£�8������L����58�,`�?2T�B\@b�X%�a�/"*��C���ճ�ڳW��W[*I��?�v��3��*_n� ��$nIU���I�ıw6hwG%/r`��Vl4~����~�������O�v��,;O�F.ހ`�^�nM�E:A�{��2i�5Y}j7���I��V%�j�p�V�d�%���Ǧ�R�W1�@���z�����$��ؿ
$��W@^����j�P:�l�:HT�˺�
��ۥ��CV���n?@L>�����ኴ�Qw�@���� y*��$��c�f��db��r/3�h��\�~��!��l."Gr������h�o#�n��C��� k��3�il����a�>W�� ��<
R���R�t���u4>��l�z݃q,G�;2Naē�57[��5�ታK�I\o�rr�W�I��y[SX�/�$�J��gٸRR��9�0�Tx܃�a��x�(��I�n���^�0��n`������~�Zse��U���/�f��M�Q�W������n���wv�}��������үf:�w������7�H����|�e�ġ����Ao�b�.����Z��e�]R,``����3�0���T�J���Z�%u<�����A�7c���@������K9�X\ f��9 ���t8����E�RO�̫Lk�@oM����{w��{��yF	�)�{~\I�������C� 6���wf�%�&!~`��<�=�2uNC��D���F���m��������W�Ӄ��'�;�t����G��Y�P}'�^������A�F�(�Gx�9�P�,}��Ŕ�y��h��k�H^���i1�r�X�4��F��CN������c���䮨�*��\�3�|��h+G}3<7�,5/�U��T�.�E��<��πlQ5NWc��1h��iR��CX;�5B�� A��Z4�)J��)�鍕���o�#�ݤ�����C��*��Z��!���ch�:�,^�m� c�1���:�xC�xP�z��0�;z9Q��u?�h�B]t�*C\�Tk�Q~k��Ry=�x�圆�?y���3���X�(]�P-��P��^E�BR���`D�a*�u��v���E�L�$!z�x��D��+�F�I�@jrf}�숂LMp�BsAqa���5�~03=���C��B�7��$��D��S	I��q��eY `}�9z��C��M�X�/Z�câ�Ơ$�*�b����h�T�>�qR�]��W;��;9��c�W��BL�׈>wL�w"yg@"%�@}�A<�E$`���Z�Y�J��R�wY
K�-�u�W��B�y~�J썑N�&?�������G#qӐYˑ܃�lwdBРh�Ay����}'n�K��\FS)laB^]���	��@�j��@#�!]�8�s�I��0�q������|�3z��(�^�惙�G,2�# �����ԋH�R#y2|+3��d�.]�'���Ѩ�:���m1$�W-T be� ws�ƎOT�Ƣ<��B#"���c��5vς�����bo'V�=��iΆ�����0�I!e-�T1Μ5��)����T��:㵬��D�ʰz/�
�!<�����hq�nB^�'$"IT�w7�$��<���h����T%�}��v���` 7��C��K����o��p/�I���ظ�bO��u�!�ȝs�L�%Px;b:��]�(��7��6���KU+�roJlĤ\e��4�S��%����Bz�W��OOԮ;��pOUQ��8h�X�M�ɥ\0ߜҘ��{��C�;\\�%�hesŬ1c���s��=/�М��8{�c)k3j�1��([���;c�i���`�9�����J<=��H��)_�I��P�icd��C��xx���#�QR�Nr���$�՞��t`D�E8HC�ba>��5���XK���U8퍺����n���!|���s�/љ	�#e���]/[Y��
����ϋԆ��oYN�^���)�?cq�\��-�l@tL�ea6��nD0j������@[��r�+�M�w���(�:�2���\���00r����{|�؅(2�|)���@���꾨�Һ˃G�ysvۢ�"�|ag��h&|y��]�SsA�lK�����b�#��+:�����M�@�fp���J�I���g��(��`p�NJPw�.+��u������� �:4�q#,l�t��	&��}j��}���I�������0��*�4�C�#�F/��κ�k{\�v���Oڎ�X��'�����^���&���xa�X�Ȱ&��By��b�C����|K@K	�*m���E�g�Y&u�k�ʗ�l��Q[��u �J�GpX��;�y&��lهL�zo��򠣝�R��sR����l��sb��^�ND�:0�?����Z��j�_�6�����&l���tN���Q�$I�Ku
��s��wW�lt��0�.��������� �Ûڦ��t��uN�>w��wKM�Zg�,��?h�ȶ(j��B�U�K�-�$�~.�:���L���N71ԯ�'Y�8[��/ˏ�< E:4fs6��o2;xƽ�_B**�Rw�=��D);�'����$ �,,k�}�DJ�Li�ŉ��{�5λ[C��%�+�h(S�?(�ɵ}D�J��e�� eQ�W�ì��:�d	�>�K3�\��$��a�бS�����ӟ!������u��bR�i��vՍ���A�j���io�r�*�>N��L����,Iƛn(P�� ��T�����:�z
��4��X�ڇ�?��R�O����c���=Q� ���J@��s	l�&O}!��V]� В�}9q�[��� ��2���<E�"�Sz��Js,���שƬ����@0�����Q���8~d��V�s��p��y_�!�3��O�?���0� >_TK�@�!����������24�3:�kk�y[��5�%"?�'f3���-�pHCc3N������g���Iv?>@1�~e�|?��I4O�UcGZ�Y���߸S�U'
]qqz�����Pu��)�=P<C!�L���to �G�5W�k�ΔZ<�x���3y��*�ͺ�:6�A�Z�TR-�~���D-a�*�r7��%�\�nDbո�Q��䫄I�M�r�R�"���*�դ�
�n���Z���%̩a|��O�P>�1L��_z�����6�,�ye��Tc�Z H�Ҥ�nJ�d�y����t �@�*@aP )ڭ�/�4��2�0�h��=�̬̪, �)�w��T�����|'�\(%��y��m�W�A���;���OI���(������|B�������3��Z��5wp�@Ʉ#�:�lI��Oq��'CN	������rA�JA7���@Lt!A�W�h�V�)O�����&�@e?5�F��Bo+�ǰ�N���2��o	Iꕻ1�pCG'�s忊Ɗi�T�z��h1S��^٘��}Q���}/}�:ݢZX��*�ޭV���¯刃�j]��O��)Uv�euu�R���Ƣʌ�V��UOe.��rm����|�-�n,�οǪ��u�s�f�Ć8sj��7��<�F�o�u6����C�4�tuL��U���OD��<�������nF*�Fu�Z�����hM��)�|����"��Aet�Od�iaF�p�E����l�i��CE$ҭ�?�^�E���/����#F,�<<%��u҉���%�F����P~���z4��WعQ��]g�i��j0HX����8
�o��t�:������Z��o��f|M���`i%c�Nҍ���.aԑ-�W�,���p�?ДC���N��Pu�=�Q�bYt����?&�@� �a��*+��mFD���5�
�n����O��u���ۏĄ�7�r2�_d��^��v���u�6�C�;�N�����0,��u��p�U�m��.��4)p��\���7�t<4($ţ�����UfI	^D�����g����KY܆�Y0l�f��Q���)EN��`[ЙJ������,y^j�����]��q�/�!��5M$(묜˵���npn�#�]T�(��DT����U�]�*���9�����#������T0�(L/Դ�Vȧ�I�D��{]�M�R'�f��Net�r�� �a�<���@� 9l���y�����N�@^��g�8�[\��6��m����H��&n���it�lc\����J��HƸ�-��r�a�Z����ҦT� �(wxN|��o��Gn�e�4u{��h���X�����B���#58�ɻb��r����x8N>p�~z�kZAe���.�E�l`"rJ�2\��P���VU&��ͪ	t'@��&D���7�%���cC� �{m�&Ӯ�y>qYjϝ/>�oT�d���@S(��nǣ�J�|,�(�&�A�����@7��b
O�z�N/7��]�ED������0�� ��`'m����V��"ө/��){��� �� ��a�l3����m���f��Pf�%s�}f�C�5�c �'(NL;<9\�$�2���A�N+f�	�FGS�����j����k������}�������Oq�q��ygϴ"%��6�Ʈ��R>�
�����w�ܽ���k�<TL�v���R/�g�v�H�����;����NGy�#����8RG�����(�m�'�oP�S�_��t���#tϼ�W��L�Q��(3��M�9R�+�o)h�����ig{fw���	�Yb��U�$�ήb��s��=����b�603�ЛܼԴ�Yͼ�:���v�yt�,�Η��{����[�K���t��o�������?)?����7;f�y�pa�o�Ww���95h߷�>J��H�g�h@^#�e9�����Ci�Uv��I��4���*��(a�	����o���j�,�>�]s��c�oDk~ۘ���T�}�T�-��F%.�>�LH����OvN������r��)QT�^W+7��z	��xu9�� ��Y���� L99ݨ�y��%��b;���[����ui�X20շ�C��1�XR�?�t͈d��D^�_U��\��:�ҩ_�۪"*���Y�IJ�K�o�*;2�KY!����O�N���U(�1k��&��q�@#��7,����*k�ppm���/����GͯW�|�t�.l2���m���W�˗�������:�4�?"�����r�kK���b�ܯ���a�`nj�8M�ͯ��/˒"D"� 臺��=+����h#�zY�}1-ݲ4�[���+L��`=�a\<�m�=i`�]�#K����YU�6ɰ�u�C���<[��K��0�g��	Jw� a�Y��ɂ</���|�V��UA�,�����|U3�[/�W�qI������
jBZ��][�������S�F�b���F.N�sl'i�y�/p�4N�)Nj�k�gcr ;�g�ě��$�S�n�E�/�=�.�N�Ν���V0��o&9M��E����7>呕�:C�~������z.�W}�c��6��:�[��m�7���k�0�,��#��a�"�(�s��a�j�PWp���K����rYZA��/�����������S{��}���|�(��6Ov����y�}}{c���C��4������Hߵ�^�A���.��ԏ��N�Ne�z�\��j��V��l�J��}]�f���fe3����i{���7-d���u����+<P��>�(_LƉ��tއ�� 05�|V]`�r��?���z�{�.�S,�n;�EpgJ<�+8*uc�vz���
ܜJ�.ͻ@șSE�|"l�c���vGa���T;wE��=B�A�e��Sq�jb��[6�����
���#;�t����/�q����|������C��-�\!������V��1�
X��:v�D��&֙��J���y���d4�s]:�_ƓAW�#Q��~z�v y(r7�F������as�A3�d~y=��ԃ�G���E�f�9!c9��H:�����.؞C�K��$��x����}$x)]%�I	tU����0� �Ќ�Ds˦%la��6V�+-��.� �u�U���[H���*����=+��	��W"�TT�=�Z�خ���*L�K&����3|���k5�iՄ��)�O��Y��5K%��B{,����O;���U���ê���\���*�(���ए� <��V�P�+n!�vR��6�n84�;�,��ʦu��wz��m��K�#C�h����n��JV�m9����iZG��{�8���9l�rәɤM�t�>�Qp��T�D�΅U
@��)��3:eЦ�~�n�%�R#g�NU��¢��d���]�'�T��I����I�A����-z��9J�E)0Ж��M)��F:z��	�j�����^���ҧ|0�o�7�S�3��\�`-.��q������X��x	l[)c�yxR�l0Bf���p����G&]��4���b`G����,��칔79:w��0��	�	�y��46���N�WrP�Td���ج�0S���I�s��ْY~cZ�����G"�����/�,�䵯P4)[`�n��)�˶�Қ��K����+�l�X�ӂ,0.%wT8��E]J����0�qF*��(a�ջM�T��FF�3	M��3GN�Bw�kj�Ͳ�*��#��ʦ:��(`��~4��|��Dp��`�i�[z����͹֠Ur�:��"����������8�l"��!�(�+�!o��l2��a؋���2��U���1>ٯ�K�UF�9�bds�E�0�War>h�u�w�Z�)��u �Ow&څ�R�S0:��q7�:��,��_�ccu�s��h�a*8��nB��.φzaU�$U��Q����x�o�!V�e�*�BU��F���b�4��c�!;�����G�tt+%c��w�[i;�֘w���H�	ʚ�� &Av����::Gq'L�8y"h�9� nIp�iz�������Њ�C�&�R�'�mf�Z�D�t�pl[&�x$յ��n�������~BW��8u.	sJ������_�E)���t�M�!Jg2$�T�g�"{	��}Dc��P��������mC�"�n�0�������u��`��?6AC51�rr�Tnar����2l�]��j6q�d�\F+�c9]i��qJ���4
=PIv���m/��%Z8�<��b`���r�(?����,r{�#o�k択����=������,<�$r I¨����"x���#����~�#�������?O����E��{���㛳|�@?oT�w+��,H���r�/ٽ4�h���9��'��dG��N�9D�/�m4j�1�S��4�GG�J�=Ϻy��u?Gq��
i�$A�5��*�K���)hh�!exh��$k։�Εv'A岝M˱�F�$�S$��'�$�?�vG2�#�X�CD�,M������Y��ᑛ+%�+ā"&�� k��������� �-5X0s�PF)T�r*��sHF]1qm���xA�\+�����R�=���gdc$��ؤ@6�D�|sW�sx:�^L3�R�"/sVX��8O��{8���:ަ��B��O�Z����d4C���:<j�;��/�(����iZ��+P|U�<%F���c0�?����������*M��GP��K���2��"���X��j�
\�b���2�cn�I�p�#��#�P�V��h��R�9}�S0ҧ��`"�*�����&LJ"d��7�[I㖬h�0V,E\˼��5� ����8�oއ�M�A}p4�8��~ݼW3]���;��͓Ýӽo�:.��mx�o)2/������0��\kVi�}�{k���C3��K6�
GК⎥���e���b���ohb)jh�o��V]��!fP���m����ē�QO��G�nx�����0�y�!;+�����SZ-��
��'��[��e�xf�]J��]0�c�j�ݬ��BY7%�°�DL:�9E��HGm��zg���e�`���h��g�h�x�tr���0�zREk�T��3ϐ�{;���0L��&�~� 0cf��E>�r�)����wզ���(qtB�T�Wc����qz�0M��.M@�5o��vߡjjx���~�DOo���k����!���@?gm��$p^��i3��I�.E���߃X�Mfj��6&�9C�na"p��!�w'F�,�<E$�Q�2���B�<�Py�����^L��\�I8��I� 9�e0�=|�x$���QB����8J������"F᪖B�S��͗��J]�r+�l	�v���(3W%�jn"��!s*��Q���n"�|��Ԓځ�up5�&?���p�ی4�b=��wJ�i�o:��v�}��r�L�.� 3@�m�{jS˺æj����-SVK7&������I&�ǲ��������et��R�e�W��|w�)y��:�L�f&;T�X�)�L�)2ͬ	N����D��I��"�#��0v~��e���d�	ȳ�7��1��m�$%m�i*u��W݌м�Y2�s�<O�.薭
\"|� �?^�Q&Y�m5;{�������_3���I��Kf͞�:gk�B��N�d��ܲ\����F����-u?"��w��rB������K5��I؍���GqB^u�����m�R_[fo��&h][�/7��V�M`�l���-He6�oR�d4��f9;�oh����2��U�h���]o�J[�:�[�}Dl��{�<l5[@����&0�x�TzQ'$�k�6�Q!�u�B��<��~�Æ���z�s��y�~s�kT�=���6�2���4������Jv�d{S�^�sj�#�~/�Mke
~���Qqi٤�r��&�!>���HQ��׉�=���±) D�vC�E��3AI3AP���"\	]���H���mڭ
�%�~�m夹��i5kU��Gc�vb�5ښ�+(6?((��,j�8K)E��������&�	P@U-��:S�Y��v��4:N-�At�6��%T	�_ٳ\ ��י�~G@	e����~�Ep(5B�p�*��;�S��M��Wj�b���X���̥j�39!(��&�u��7r	��/���Q���kO������D:�2u��3��'_�C��k����-2��HOު�X�}�*6��wz�=�*��z0L�%K'��S����z1�fd��34��� l���̟����r$��<wjj�gD�� 6��$�Y:��@s���^G�y,,���~o��dg��Ӟ�㹦��;F�!'�?.*'�42`�h�\F�2)�m'��W��u�V��C��w��Qte��3�����B"c9�nb��3����℮Հ��0J�5���ܵV��j��hƋ���1�@�46�$���B#a(a�hx�L��eP2S�0e����
��@u�r�`���$;�����_k�$��"�TĨ���ad\���_�1�b��&�d35�a`�C�-Ž7B�}��؀ӝɢ窮���~�/es15�X���SXom�ze0�v��+ېI13B�4���R�lP�|.�ޘ��ݨ�>�0��� 譋���p4�ǫ���I�;�|C�1xM�~��VbM����:�r3)w��oFg$Ŏ�j�]��ͣ�
dc^�j�g��M�+�Fm�)No	��7���{�!�B�9��̒+��t�1�+��)(��݃%x)��}��r��7�W���"Z{��Oa�b!-���w�ƻ�"�޼ �}��)�r�T��O�A46V�<�aV��
���W�+�{7\�F"��
����O�������z���J��bη۫^��U/��Hk0���n�Ti����
��,����3��ˑ� �9;���Q�s��oSOK�î�OӹiuA�/�g)Kbl5�HN�Ν?�/"�^)]�[�����E��l7���X����%������ ���\�q/DN�&��O�mU]��VAq�H��"�BR�I����	�������,K��i9v�>5�ZB�H�k���JM܄��v��M��ﱯWX�G�n��bh{[6���)B��+`�q�����w�S�0�H��)�.�������%�la��G�8�o��Oj�mc�:������i�_OσYUXiŬ���C8n������6!��%�jI6�`��$X�u�b�������fc�#
��z^�d:N
v�yiZ[8)�F�J9���t�嶼c ]t��yZ	��j[�c�㷥^����v.� dt^���fJ���m�E����OJ�3#�[e	�#C�1�s�S�&I)��mQ��&Nk��6Rk+U���{-)Ž��'�0�F��fx��Kb=�\�~꛿�m�X�>��~���ʞT�饦{�O��E���rmx����z+�bǹ��A�<V�I�I8���˅�d0r=�q<2D�d���z�7�ƪ��YV\�Y���l!�~�+f�XA��g��;007C���~���n��W*MŔe���n�K�y�o�:`"�u�2˺8�-����.*;8d�/טi>��a�=�W$@#<�.��a0Bc�u���uX�ۗU����|/B�F9c@"��y*+�٘�<��B�v����@������	P@�X���:�)$�
a� Ʀ˳�L�U�"�2�%mxyc5���4`�X_r+u4c���`��hi>S#G#�l�R�]G��9�.��v��9����'B 3���9�T��\ �`Lk��)e����k�#�a�uI�10D@ �9x ���-!�q�� ��/JW�'f��2����Z%�3l�r��������W�T� ���|Df�<��F����|o�ِf{?ÚB
�=bQq"HC��2�	6�Ó�	(���[C{�,���^k�e\�ҮΙ[��9ic�VEwk�f�-wl̦���ڍ��yg�9��iي�6���}ثʎ�l���r�ӯS����D�W����g��q4��P,N��ԜD������Y�/>�	�\�Ą(�$gz��|{gB�6J2��t&��8�Z���2�PCF��I���C�.-�F��^�(�.�S�nU'��.{�d�QF�����g��ڣ	�C���J��־G7�p,���-�óYF5L�FW�N�b$�XvKv0%��wf���r#T�Ƅ������gL������ r/�lsu���f�2lgڊ����_���2[�7(ω=,we�S�U�;�����Y���VIw�����ج�i�wi�.�t�zSY '�`՛�T_�ݓ��m=��9�����������O������̵$O��~N/��Ǧ�*��G��q5{�,�����?����N������MO�\vS0>6 2S�\�o���stF�M�2����읶wޜB탣�&\�K��A"�x�˵<Rs`���n#�z%na)�7���Q��4�R|�N�H|Aw��s��,$3�:���(9rHdG�_ka����A4�f�m��:ɦ�}4�3��`�c�:��F$�e6B�QvW*��\�B)#tIE	He�(@cw
v�F��oq���>�q���*�ygl�;]l'�H���N9�2ǘWpj9�ܱ1ͼ.]$�q2~#��N����oU�IByZ/�,��?}Z����7s�������]�ߊ��t�(n<���M�)^g���rK�����T��� f{2�^�պp���0�O�k�|�,;T��qEG
F_��ϔJ+m�ʪ�"��l�k������4���J�<�%���a���������~'Ns��0��� }��n��T�R���o%���JSb+g]��]SF:^UDG�e~��~���<?v�F�0N��
x��w��Ŗ�u�R���H�ݨ��p���E$���sTZ�{-�G�3e��އ�&G���\�?�|����G������sÅ�y�>Ġ��L��y�X'�5r���%_&�[*"(Z�*�IRŋAzIUH��� ]O%����!������h��	+JZ���xxt����w1ȯ�h�qty[A��UO�&���FJ� C����t����_�4�,�ц}���Nv��&v�������i��S�8����3�y�!��}��U��������s������w���rf!�K�s
|Z"���5�� -0|3���d�l�D��%�||>>�o�y���(쉣��h�S�O��V=n�:Z��T�����]�%�g%�Ϫk�b���{�"��u�0���)�MP$� aoO�`��6��"�����5�����T*댧Ыƚ�E�����oPt���~���[�v��.�=J�O˚y�"h-0r�����oN��a]~�^!S6� �|�J���O��Y�&>���q�3	����X�4�z�Q_�9�S��, /ܢ�l�K�d��A�=�M�؝��������حDI|R�)tY��o2U�Q�Ņ��nmQv���1��$��ų���\��7澙�OԴ"�)wz=�֫u�˸�L�i�$��_Oռ1{�L�e�0���&(�������1�2�d�˪W��c��N+��@mc�=�f_x�S��t{�a>��L�-ul��l��j�Θ��u��O��:�s�G���Ufu��P�Sq��D��~ZEL��(H���{4��&2@�7\E����~�1�L0Y����ŝU@yƩj·g�Q�N���m�TS ��c����Ã�D�b�����i��d�h�r7�&>�x�v��6R��"��dtB�ph*�A����4��{��+��ϪC�U�qBbU���8��K���6�u�}��R��X��˞�PmQ������:��Ƌ>ݺ�:���z�k�w˞�k��/�122�]���0��KXD�
Rg��T��U�WW?��{��9w͚#Ĭ4��crO�*��N�;�T����z��0��¤7yJ(��Ȳ4�F�ń'Ō���I��">tޜ���a�q[�9��	�ٳ�놯�
��6��Y��Wk�O�����\�L�c��\]&EX���/��9���Ȧ"�o�Q�B�`Rύ�cP�zP���0�<="*<�ɦ���UR�6F<e�1���V;�W�|��Ҧ)�j��'��N�x]YZ����L��(I�$���I%�*�^}Q��K�g�V 'L�<9j��;'��`r�j�-�QO_�V^�9>S�ZXinJ9�_��U����>ƌG+X�������x|�|����g�W���4L�l��mc ���W��;�֬R�Ω�Ku��!��gc�(N�}1��W�s�/��?icQ��� F�3�VX�[a�\����t9m�ְ�5���,������9ۋ�]����B�~Wm����0�����8�N����������N�[��K��brc,s�U��|4p<{�W8Z����z�^�wq5� ����a��bri<��(^W�`�\�����q2V߃�����NEՄ��Uo2�H��s�Kah~?L�M$��k �~�!<��Qc@��'���&�Q0����{нW���UB�b�s��6R�.4�.y=��TH!��^��s���p@�h�5� T���,���T l������0�-]���\%��m�s�S컝=��{.x��Xk�� N;��<o�t?�4���y�r}��R!�;.��f���(�)�X���y�ѰP�r��c���&4�� �bY����g���Y]4��g��<�w�,Y��*;I��_hҘ���(=/յMg����}1
p_�}?�;�r}���B_~W '�p�}S��0�o8#Kɻ����@V�?��l�����W���������+rW���&�W���4�ڸ��M�)z�`]a�SN=DdAv	CV��:�݂��k�H�_��Hs �~��&��]�x[tg"�<���f�RoS~܆��X���mĹ5�ik�qw��3>���9H|)mGY�k�G,����[�±���1��>KuW��-���zד�s����x�y����0j�~��THi�޴����Oj5t��*��(L~�OUK�O�l�d���\'���@cL����?fWg���w�'�X��R���"S�N����)6+����10�`��[C�A�)��;���Qs�ϦGE�����	А��Q�/W�f�D\���N���Z��z\F3�a�Pa:��`�E@F����Vf�d�"r+�Xxn�-��>j���Q�~}xv�y�]�I��M�4s-��nΊ�j�Y��*C]����|���0c�n��/�)^�j���r��A�&��4�|���PG�x""iT%B�s��1�v��q�Px�����w��0}�0o���n+5�;w����8����7������������������{�S�~6`lڟHg�g21&��/b��
,�y�[��>���Z�6��υ��5�+<��y̷*�rW6˖ԟ'¦ǃJ�6�8"��By��*���I%�Rw޼t�e��+����Q+ŵ{�����bdҟ�a���9aG9�Dy�s���*��T�Т�&�S�.-���$�s����s�s��AO��C��,�<{JϤ�	�~�k�x��P�t��\�(fm�n�qJ�i���!�<w��<����Bl�&�lfuDĦ70-�ժ��J^Q]�olQ��\g(&r�z�|J}xLO/�N?�J+e��g����U�a�	l�e 6+������˘W��(����"�8��Ħ��J�;*jgu3���6y �h����J�atL<- ���������)[E�l����~����&f�*�Sm8�||&ATl��vN�C�V8lPݖ�[����$�yo�L�a�!Jds��$6)�|
�K��B8Z������ͦ�<1\�a/�fp;8�DK�腊�hR�3ě�J|yD!#nr��P�OD�=x�+Sy�-�hk'CƸ�;Dz���)�t�
1��n�~�Lҙ\�h*�����4؎�x��6`=���	t����A�� ��$�w ��e]P?�L@���f��P|��k�Z�r�A9��E�uό��r
U��8P�����QH�N� #���n@�c8�G��;
f��
Z��� uP&�!�'�6<z�`�3��W�����cz�[wzQַJ\H�N�У�\FQ�"��E��A�*�M�uN=�>\��˛?��o�8�A�0�YHn����t�"���X{����	��&����w!���V�X���eq￑q:�m�WM�J;�v��\@۩�y��bv��T�a)���]�z��~�N���Vh9��mݿ3l�r���P����g�B�uJ�'�|�T���q�����pK璇���D:>./<���P�7O���VM�K5�Q/BO�K'�@�ε"5���a�@�E����y<{��8�
y��·��]�z�6P2�� �b;�uC&b�����Oe
��t	�"gō�uQ��g�pE�;1vEx
���	�a����d�Hx9�`2���8P� )C�1z�G���]�ܾ
6ׄҩ��E#7���������Y𵴙jҨ�����ij$0��k{6\��)H�иc�{z˴7��I��u�iH��J��j���,^��NW��^��LwS�v*�����H�[��\\Ds�L��)^�u��3�JȜ�|ٓ�X�� �Y;!�uG���Bw�5L��ٝg^�ˁ{n�4�/j�K,	��^Z�+��Z��:-�$ԴiKd�ѥ������1��B]=�(aӔ�^��$�{rJRR���X���(H�S�B�_�=�дO
9������h�QX�#�W̕��B��r�$�x���֍;I��1�?�O���ٿ���ϗ@��ɰ��~����������t���e�6�A���^_yK�-{�_9�F��eސZZ�}�wY!׷� h��J�Ċv�R��U�s�B���Qx�Z֡+�F��J�xY^U��f4/�t��8	�@	���r���i���ɘ�^&p�\��T^��W�Ex��������K�����/;[��k4@�Q�Jx�����myK�!����I ���լ2�m�*Y`8LC!]�K`�^��'�yY�*��*���8���7oD}O6޲*R�m뢴,i~S#�gV�t����z�wB�I����J�L��n�*�R�_���P)K��kSC�P��6#[i����W�/���4�(�'I,c���`�kV��/�ϝ����ރ�{�Q_�_x��E�%�������X[�_f��}<��Ɔ�Jc�z��͸�>�U��ɕ����
��_:�U�>I��B߫���;M�6�<�I�q�x������[{-�n���3P�0��痯YSt~y���K7�l�o�!�p�+�3�Ki2Y7��]�^�U�Vu��+�|�埰h�z�rG�cCi='�^�
�n��zs�G��,֞xu�f��G7~ҋ>�9z|���+�ȓg�[�h�7fr�ŧa�TWNuV�A���)�#wHj��������<!��J,��eH)ĒN-2��ip�tdi�M��WWPUdLMzr|l&���X��yx<�ՀB�?���v�ۋLN���xE6{�J�����/� T����Q]#N�Ͷz�L%=����5i��Z���<�rZ�g	�8h�|�m��& �n�H}of��p�Oc$Z��ʭ��7P��s�+S�-Δvke>�<ly{lzj������De@@�ä�����D$.{l;?��#��'8Cx���~}t�e��V�����z��piBh�Uo�A���wz̕�6�}8����<�������e�ox胞>>��~�B,��O6aU�,��O����0Bgy8<-'4u�y�(\��t, �{(P�E�r�>݊�*�S�d-� +� \!�&���pq^���fЋ�.J
�[!O~D��aT`:�St/aI!��>D	���o, {�Dcҽ�sb���Ӎ4G�p������;�,�4gxY�Q�.�dS�d�b�l��<�eAKl���CF9WS�)|�0)�+9�\�^H��W�@����=�g���k9��͍�����O����<�����h��Rp���F\�����pY_L��ET=���;a�"=䗇( �dT����]k�<&�#�)���!,Q�ԕ�#,X�c����K�{$X�|����g��Cc��CZL�>���e��,À�j��L���p��,1ӿ�Ё�g��#��ƈ�@zӤjf����5���h)@���y������M���H�5����۽�4w���i�T�������T8�E�^�(�6�4T��Q/ߺ3Q_��zZ"��S���
�f�:̮�:��
�c�c�E�,��Kc*���T�U�3��3���{�f	�T׊&�5�,	�B�x���s�b����T��k8Ab�
�*3v��d9O�
�X�R�4�<�fn4H��՜w�x�E�U���bbuT�������^Ё r����#z��bV��f�xD�j` ���
����ę����UT�������59�w��9�o�|�B�7�{� c�^�Iv380�2��4 qr��hVϚ�w�Hm��9Юq��'l�.��G����e�����Ap۩1�
gl]Lm�"/��w3�A�
W�%�ܗm��O�1�b�A/����-��#��H��5�[�qr�����������7�g���ן-��_����W��d�m�o��+�U~(ů����o�+�Jx��"S��Ǟ��1���n�J@�t��V�LQ3�2���'���J�<��L4����o�+һ�}���Tå���v�|"ͩU�Fs��Z���̾S�~�7���Y��	t����|�2�e������g������T�Ξq�#'��1�.C%9I�!;�f�e�Ԃ23eT���y�:Ku�E8���y+����Üf�_Ht<�2J \���3�R��u�n �kJ lt� aF$,�
����hk�������ۀ@�D��A*���SF��2cJ��?pO�Ө���Hh�,�dz���+��lE&�����4u�e��5�J�P�l�3&�X\l$�!1��gRA!����%����Y�X��_H�4��GC��M��NDII>Xq��$G�_ϻ~�z��{��E
#(-��i�c���a���|%�8B�K
+��X!NC#�B�%۰7<���E/��v�����A���Jms�(U(�-�^F���M��-������V���[:��L@�a���jB��_	����]�U����y��b��0�V�\I�=��@%�?v?T^T���!�z�_�3��^�[����-���!�Î.�����*���T�I��7��G�.q�a����ht�&Hde�gOr	���K'
Ro=�"�xQma��rb��I�C�d�'G9=%�����WW����`�����B��3�Ɩ3�OK
$QW����z"���AL;��S�ңE��#K��
���)�+0ڣ.�f�mFd�v�
9%�mQj�<�5��Y����S�;<�i�W*�?!�>�X�5�n��ʾE�Qm#�����ȑ�������gԘ-
���A��-�婝�05�S�y#�*��n�"}5	��Ḃ!J��m뙽�+��̣��c��.>����,>����,>����,>����,>����,>����,>����,>����,>����|���PS�I � 