#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3864065741"
MD5="bfbedae76787328fbede681e805902a1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23748"
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
	echo Date of packaging: Thu Sep 16 15:46:32 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D�?9X�4�YN ���q���<E�Rs���H���J{�$��e.2���Q�G#�D�v�Q��z�b���]���_Ů���?�+[t��Y�(_l�g"�8����a��Id��S&1�Oޏ�'�S�ro���?>^j�ډ��W�`2�m�����WP�Q�YZ@3j%�x�4#vQm�j2Od^�f~�;��í�Ѧ�[)�xѠ���"��iZ��{ː�O��ߓD��Pk�?�G�K}̏��?@�e�loR�KT�%����c{�((0Pa%ݣ�N��K)HE3�����K,ɸ#��9ѵچļ�{�`����&tr��9р�a��6ތ�����6o�� �<��+."�!�������5
g��L�އ�O2@q{���II���<���=1�e���Hk�^�`����� �'�Ȥ�!���XGhM�N��/Ū����5o�,T�wj������.�W��F\����"�5�%/��h蚝�[@�e��rӓT��u.��ߏ�4�8��YKO<��!��vK�םp�O�,E�Ӏ���-?c5�nG�\͢�ga��|���a���ۋ7g�J.}:X�a�4��h9��0�v�e��L�CA8"	*�ao.^�KT2�~k��ڸ�nUZ��Ї��>�Z�����,�'�8��l��9�鄜qY/����e�A�4��:p�D�7���/�߫�q�����Q�T3���M3�mgq�p�GV�/d_p�*B6��Ԏ�	�����F>��}�8��CO6�*���kÇo�����.=�)�^|�����K�fY��d@� �l�s5W'�J�A�}��V�,v�wՆ��^z�5 ��Ǻf��/ �<9�7/{�C�#������/����|�$jQ�o�4��U;Pq{Y�r�S*�C��V�s#��#
����s�����O���[��l9�ζg�4�������j�bk�0m�1��K��?�xs�Ud\Y�ɫ� ��=bl3�K�b��Y��/�U7��:f:r�`7Oz����*I#O���z!
�κ��o�
񳗠�F# � �!�~�u���4]��v)�.�$�����*����&���Σb�8b�s������FW,�K
8��`�Z��0�[��>�뗘5�%#�~��ҀD�	Ū���]��`R�s1�n`�^�U:��5'�]�(&��d?�կ��#t"m��m�������$�>=Ub%|%�-��rMc� jϸ�J��U�ѷ�Hh��B�} y�WO�����>��Q	�E�Eo�~���h ���#k�Y3�eK��Ldv��8� �Z�#�화1�|��ScK�m]@���`�U��iLP�q�-�!aIP'em��F��B���S�/���������&�U^���Gm�d����l[��
4��bo@�~�2G�hef�O��0G���JK��%J�޹��	���4�!���XSp������H(M�`Z��-)��7:e��>Zl2C�P�E[0��O��e8RȦ�S�ұ��q���Ձ�rq��R-�@�Z��dqB���T�+����c+��d�b?i�w�e�~\����kݑy�TR�������FP�n�G?ߕ����S�7b��G����	��x�نE���`��(\���F�����3�^'��ƈi-I�3ym0��QmE�;�1��ǲ�7r����p��sf�S��l�<�]�gGM��0�D??����C&��/B��M}���`00�M�Mi�]�I�i��Q��]�$��S�q�:��Q�#��Jʱ�7�|�Z0��l��m���'�l�՘V߫��O�b������S%��5��T��wxʢ�ҭ�}1b�����6�|;Z1bΊ��h��`R)��0�f���{Ջ��8��dwL�H��$Q���P���XJ!`ʙH�M���r�L�v��T��R���0��ir��Ā=6)��cIUS)'�I�k�1�yQO��s�@"���Ky��E���`��AeC��ߪ�߃��X._�M6�b���J�tT��S���C*B�-hŕ�p���\�l���Oix����4)9I�,I�O_6�uv�
Z�g�\���'�%0���:J�$y x�, ۗ7s'@��R���m:a^����@��տ5͘0�uZ��ցYkpJÜ�2'<���+8�%T'E\�!��6p���6�nرR3d0[(������i��#OL�&2U@��y�#՝W˓��測�E�:��^�VT��C��1�a]i�D$,�c�Vd��/����� ��f�JH��rW[��_���K1��U���Ai`K,�	�#��	��/K�PZ���s^gq���k���高��:�y���7G�(h�%��r�as���:�Pq�\���w�r
��&Ǒ%�3��jR!̔G޲�ʿ��`��,�X���d�Mj-_O|ͯZ��棲x5m���'p=�h� SӘ��޹�@��@-Eq\}w���<���aU �F�}t�&�I�)��63�־)���Gw�-DѺ }DPMy�%�O���.�QUeQ���$���D�bd�>����1�t�z��?��>�-ΪB!D��Y��b|��D7d��	�C�JY1f�B]Xj8���]G�6�R��iiC�����d�Z-��4&Hr�G�S"ɳ+��"";�2/v�@�*�4�6U�4oM��,�Wy��i��[�{A�^n�s�Z��w��^�*�O�@���QAr����bmr��ޡy����~r�$�5�9�	K�H�D7Z)�8��U��I��,������ۊY����vq��D���>�=�Ǉ�-���>Ze���\�;L�NU�(�ўc� �vY%Om)��ky;��|ay���v��3��g�����u��Mv��p]�<�ܳb�3B���ܧ-~���N!PX�3������.�R�����D�H"Xrhn����<vS���S����t>���H�|F��^	έ��/;{�[m���Ū0V�߇%ț�l4i���E�O��ݒ壍/N�չ�%`����i�լ���.�9'-�3m���R������
�.>��! R�ue0��M��?G��MG5�hɀ�1 ��>z~~��P}� �Xf�Q,�j�} ���Uq�#������*�G5}��Fʾ',�?���Fd���h�P{���oD����:�d�cd-�MK~>˺Q��d�ߐ2ɚ��ጀ��T6�r�%ob�a�W�?-�(~"�d�����Q,�ƭ˭E
��݋đ�l{�_��y�^M���GGJ�p�4�@���%���3�K�ۼ�k�0�x
�O���=��s�'?���Ey =�*T���)�&+(��[6��~��?-�X14{�q|�,=����*ޘB%ږ3l���������B���^��&\i��]�'�=}*^rj��u�(�-~���ޤ:�Hy�K�x�"�v�O<{1a�+,Wq�0�����l�Qc$���R�����o�]���#��[LDX��ma�T)���$��<moK��H�$𣏕	��.#p+��(�՜�B�Ϙ�4���$�n���q^Z>��0�>�)��M-u`�>��8g�R ~�����-�;�sz�{᧑��
O��d���?U����ƭ%I���Ǡ��ט�g�c��W�4 �\�k��>5�{�6�_���ײ��Q����P�F`�<}P�u�?�I�x����{"2\nF���q��D�R�w 7}3��{�{��\�Y������Ⱥ[�o�6�u=UoS?�␭����46vH	����ۡ��=����<!���P��Z���ka/�������d�S�K����C4RL���<� �[���`ګ��U���;��X�˅�i�7j#)-���������=���4�h���3�VN9�~�7�i,ƨY9=^B�i�*�~�n.,<*���F��@���n��J�;{��d��� �T�$�Ky�jO�*s&�ۓ;NDٳ�J�}�Ag���S:����Z��YnG�9R�X	�_���v��ʺ;V[�
���ە��<�vC����C5��V������h��p¯�1VxD6#�L�ŕ��p�����Nml��y��Pe�Ϫbq�#"�[y` ^�i˞hM�]W��)7�q��La�KڍC� ��c#/':�q��-%���+��1�!�;6[]�s|WW�b�5�䨙�;�����V�C��3��q:�,VL(J"t�V��@q.�Ǯ��'m�x��8j^����!$�"��=��Z5X�9?I.�2���O+���~�X�.�����s�6!���ܫA��1�Kd�� �^��U�{Y�5�v7�s_7���ٯ,݂����ju��N��wb��e<c���$����%�T�p�0*rl׹#�v�6�XI.��0�=႐~��5W��gm�jNɫ��nV�J���vց0΢|ׁ7�R�ݢK���3�<k�c��мu��)*P�[h5�P���:T�O�Qg��?�tQ՗+O�p�ͭM[2��>N�D_Q����8���ݺ'k�a�o�Wz���VuwAy�6x��hŠ�=({l[C�����A@�����r�{��3�����Ԉ�o�|W	���E�\Ԟ�{ANt��Vċ{}�=KF|����."��qќxbi�޼�Wu��+kC�pp����T�G�ס�e�=r%��D!Y�M�؝ ,&��w�0�����I��X8��gG��]�R�W��4����]&$_+��	�L����/�V��]�K:т8�ө�I��]��a#��gtK�܃|��k
�7��k~��rt$v��դ���<�4�B�z����/o��J�@�s���Ә��z�&|�d��ۓ4����@�>�qv��I�e�ˌ�W"/X�R�4q)�72�ҒTl��,7��hX�'�|��_�������o�Z�Z�e���[�,�?�����|;iXk��)=*���V�|��~҈%����,s��zyG! ��s����@%M܀�wذ�xĘ�Z] ��4�|n����'d�byH���k/��Xh�iL�\��� ��@{y�v����zvl��X�灉�
T���N(�E�h�@�y��	�[;zW���`2��Ƕ�m��H�6f��4Ci�`�kd��H�H�$�U@�1��=������:�&"q�KM7`���!��Υ��A;��ILI#�q���i���ld���UG�U:9_���Bo�l�Pr�Ԋp�����v��h/7h!HKV!9�=�K`I7�f� ���b�il���P?�F絽(�+9��x�?�B{4������S���� l��Vj�_��~����@N�lh�v0�Pe��J�Ef����H��ͽ��d��	B��iz_+�:3�%7��'qv���f:1�F,ޞ쥙��ΫH"�V:\�+�}�x��v��E.P�\��-�JX����ȝ�/h��~��$	��h:���h�uZ-o�D�����1� �ZE�[=a[6ν�,������/'�w�[c,��y�'޷�`�m���gt��9���a�����e���|�ޭ��AF����<��N"�(	�Ϫ�O�rH��J�<�bԴS���]Һ�JA��//i}�O��[�'TG�Ux7�l_��M��2� evP�U�@��dۉ���s����LV&$�Ao<4v�'%Y&Y#Uq��FP�)�t����ԨE>|�d���^]���?q�xν*V����-,[�z̓+�(��nB�3��k3`p�gt�'^�@����/�����˾�C�$�/m���9�2�Ǔ���y3���8 ޟ�削!���L���<��+o�a��i����"S��.���#æq�Z���d���L�q�9�
_M��ٗ���y:�h��㞥w��h�[���I��� �f��[�Է^���0B,C^'
TF���~Fi�9D�s����3$ڴ4qGm���yN�������$T1{�3=M�b�-���A�C�%`58derU�2���+��Q�z��`�ny��WFk��iFއ;a(ꈠ��-���ˮ���>Y�4���8�i@�����⣘E�.~�~~���T����7[$	�ĥ����C����.Z`p[)�S�������O�.r�`�\��ӈ��t��R���E$(\�jqG��gC}7�����(�N!*��n D9!����	���d�D���b��͌�؋P��󪠕'D$p���]���
��ų�q���2V��\�I������N�*	�])���l���,���D[(�������C�y�q�4�=���a�(O����;T-o>�sS"������)b�j��h�7\>ݗߨ:�B���^u55��T��2%'ճ�:�j�V�R�Te ةa����f��<}vseTu�D�dKB8�6�N�y>*��v�|�^�_�	54k4;,S ���Ijp��,�G�_L���1z�L��K�:^��uL%���F��UhH��@�[����܁zG�Q�.�p����TI?�K��|��N�C�/S��ʁ��$�lH�=�gcLF����Hf+ {���f���]���.o�\���W��@��u�8�L��+`�K]�L��߃�H�QC��`���Wc�|I�i??,]��΍�.;F7�P�u
�l�.|�~%���(ϲ���Z��ê�'}������/��;�7z�O����mv[#5U Y�):)��+ڶ�lw'�9�|�"�(��nl.s<�x���.����2Wo�xd�w�n7� �Mİ����j{�*��K��3���bk�����,����}"���G �"�xV�__v(��uhK���V�',o��1q�t�$�$a*��KlZ~�G��`my%J�)ׂD��nH��2��,X	�#����'`�j��pZ�m_#HW�QN��G8)эc��0�׺�F�<ZUK_	{�0�HĜg�p呯�1Y1�s��<P}��a�B�p�9��~g���{�Iy�5�����;N6��4�l���B��ZL�87hB)���1t�婙\�&;�b�S�Zv��zX@bO^5���˘Ȋw{��?�΀���<�N��c��;�E��pV�W����QT�\ʐQ�P���`�"�v��9d�\�欍)"r�vr����E�+u#<�-� �:�ұ+aNYʁ��غj#�-e�:�6�G���:@���Zͻ$����HE`�J%R9�s�Kw�2�	�k������#�[ .�6j�s@���:"��$�,�
[�iE��a0��`��� �>��x���5(\gq�pR�Jf�;�cVr]�G�ο��^�l�Cg�� �F�E�hV��f\@�����(s� �"�k�$zrLuC<�I	Z	a�/5�?r+�8���[�V�@��ц��q���������bD�I����U���ˎ��C<�)⪁�'�暧w�S�����1�!Gs�:ŝ�'�p�����b�g�&��y(�5�4�?F�?�ȋ�qj�m[w%%�ր�ul�� �ۣ(.����[�� >1�~��G��B� �p��r����4: E[kq`�?P�W���0�d���/8)����������.�*�Z����*�wE'! !�JqW��M��Kx�\Ȑz�`���d���f�)��_�\����Vh�E�1G8�K
{Qe��>˴ @��b�fnߌ`j��t�S�sڨ���+���3�>t����/��0@����1�� eb�ww�� @Nj�h�������^L��]7Ճ�|�� �C�֯N��uC6��;�2�֖6�.Cu�JX��T�]�6��8�Y9=|7���1��i����i�_f�$m���ha�Xʮ�M��.!t�a�)�e�P�x>���-0�MC��)0n�@+G�]1��d� �ma �{�z��]Q1}��y���D���{d��Q����:R�_�x͛��!<l)�w���`����2ά�o">�� 8ȹ-�˧t,�������_���ʫ!Zg��%��}%dْ ��I���
�����#��־�ޘ���<�EI�Ѹ�๎��t�[��^-��^�1|�ι�Vo��S#�Me`����4��2p[-�(������%\2<�C�3?@I�Zׅ�����R!��0�����*�MD�R[��@~�dkS�����;���V��e�6� �������_fR��Ѷ�.=��a;��������+�ς��aQ{[�X�l���p��VV*���>GG�x�H�=�HI\X)h|�n4�aa0]6m߃�#ZT*��o(���pOR)wn�칻�Yj�zkV�^.�aA����N�l�����OQ�4R�)HnJ͞l�����TN����M#uFeϰ�إ)>64~��	o?e�)�߁32i��i�!���?`mT2X)5LB_@���B����#���1���'��l�$_�0�I������G�BkHF�1~�p���Ɲ,: }�|X�r�5D$4����A�h1�Tg��%�CK�Tұ�/O�"����ߦ�Ȍ%��N0�!V���)%�p���;�1Z��F��4�~^�Ea��^��
�<�Ϗ��'���κx.�v�`$��|p^6Ǆ�%���mT����C=�A�t'�#"�J^�Q���N��9��YAh����>���O���7���Q����m�>��^�����H)paPFQ�q�*�܁Q�*�Q��Z�[��_3��cq���!����nS����c�ݨ�a3(���>�<�o�&Bn�I.V�b<:�c�x~�a�ܐ&m]���]Z��mY%���)�R�~��c@_��Z������9Z�xzOJ@�c���b���K/�H���
V��7,�L�be, ���>�[gr;~^3����;���C+Q�+�r��7�}��?bė-O�O_ð0֑�T_% Y��'F�Pcl�1Ӽt'�-��#���&�4%6;7��Yfr��fg��ڠ� =Q�+LΦV�WM~�(�MT�ƴ���vHܡ?�1�f�3?������ );%���|4���J|-��.��
�y�֯Z����j�Y��^���+[o����y���!���@�"'��0�c�gw+��G WDj����Ǎȧ��G�n���G��ؑj:�0 g�{����H<�-�aXo
��zt���.��$�kv$D&�Olp�8W����%�eL����f�%D��s���Hc+y��WF7o��~\'�=��$�Xg-��=���©�.�X,� lr�}��f�!�
�~(�V��]qJ!��Cr�r��a���
_7����o�T�=�X����� ��C1(Н��sM=GT��4�3ݽaS�:��N=^�󟥎DнL�]��)����>�H̉ӽ�>r�"�&j!_��$���S>.H���4�����E\���gg���k��X9����� ��`�6�[��]��;�([�����WY
� 9���m����8&�h��)���4'��Y-�q:���gZTy�t�Ͷ�O�h\��L��Si�`��(,���E��i���~˘G��K��;z��"�BK��㭒��D��ɯ9��ȹC����1���DQ��=���w�3�����ĝ+U@��SQ��t�ئc0:����טS��eW�C�����������y����I�E����~=r�A.�+�c�v�爼�O(]�CW�R^��^�\<��NE��23��]���sM<���p�Ρe� B�z��Ҹ_d�g�"_��+a���g~<]T��l���ń�ރ��zm���p���f��f���VF�������JJ��P��7�?�o�Fn�%�Eޑ,���c��b;"6�Y�$я��[����������ϐ�u����o#��'Ļ�t$>I�Y6wLW�,�7Ρ-눜��h���([
���ל��[�srL�7�H�NV��~/[g|?�|��*�o&��G��ӂo�o��XE���3�/�Ǝ	��,i����+���p�2ȜR/��o����)l�v����:�+�c+\]'g�ݧ]d�4O3}|�̬�/�H�Oo#�����n�o�%�sN�|F#Kc�9�FkGuqBH��w|Tǡag�g������wf�>f�܅�.˖�d������zm�6|��KN����H�뗄��*6����n��7��D����#J|M�Fvr~����;�h���]���]Hl��f��7������ }�=�<�5A�,�Ǘ%��P6�x M��	[w�ak�j��xP�L�c6���M���;@�PWt�Ԝ����[��L#�M�u��'h�;��;�]���Z�s4����
���w��r,�_��_�n�q��}r_�Z}�Z0)��/i�R��R�@�;�}o�����{�w��6b*ǘr�g�YĖ�y�4��B\2��y�Μ�}�|Y��f�\hH��{��L�Q6=����<�,���X����RG�����ۣ	������}���(^z�X#O����v����e��p������k�T���u��ؼG`.� i� �l��a퍐2���	���w :1�TYp��S��'�+�	�v�k� �^%��>2�����>OLG�u�S��J,
��S��5ߒ��y��ն�ܗר�s|V��  ț��N<o}���#��՗��ڮ�/�~�q��z{�y߫*��S�l����w��=��"�T�<��v�ޤ�iڍ�v{�Á'6�˳mqr��#[;J��p�+U	j ����"Lt�_���E��sݾ��.���v�d?����9(	&�E!F��AY�|`����5V5��d\�P���m�*B���dyβ�/����Y�<��y��;�����7�OA�����"%#�ϣ�C��=��]qB��M^�/o���v���{L�B��<�L6����½���,2��n�
�`c>����a�U�4F�lf}l���x��Ǣh*��(�Q�(GO	<�Z�y��A#P��r&lF��P\t�O5s�h	nM�fmL���4V��7[H%����߾1=�h�5�&]��e�^aA�h������J�܊Nҡ�w�Y)�c���:�U��y�[��H�����S�8�8��E_UZ=T������H�AJ�D�V��՗	���W�>8u��~&�7�� <�N�{�vZ�߿�������:'�j����>����(�Ч:L �H�����̲��C_A,IѪ��e����$�� 3��#�����q�F�j�Z"ݪ�$� ~�͠���{ ����ќn���>;�N�,mD<:�KZ�t[[��8m��"wø+\�Կ����8�����t��U?� N<��_]��r{���k�.!}<NTq�a"
��LIS��Y���!����B��#�钏�[�3l
�ԟ�BVo?\H��g�v9n>сl�f���)e�h�����%�R5������[�z'���Ċ����g�����e6Z�}N��-A�x�:��;�,a�3�4�:���(����^驩��IH[�T�����!���/�-�Szf�P<ѻv�̈w�D���6�^ͦ��D��W%��,����K�V�����p�����"�������xkFN�B?�hc<X2�6y�QMT�c���q���p��/A�l�\���ڒe�Ŭ'�G$4�*[�l���ܯ`M?�p�C�vJA����+�}_���0l>�a8P��3&lD��i�e%��Ls3}�cI!�F�r�jR���:�Od�aQ"�,�d�7XlC%l~�-�q��򮪻��*x7�B;�?���H���,;-m�-qF��UҗGȂ�kL��r@�%{T����ñpN*��TA����Ɖ��F@�nBoH�G����h�#ύ<�	;t4^�Er��;���nZ�I$ѮWDA���9��'K[B�(Xi�̉`���k4�+}�M`��X�E��`�|�:�A��z2^q������g������)�">�Z�xIH�^��S���0;k�I���M�"��sR�K-�Rܒ� !#�ɝ�+Ib���\0?�j���"���5-��#�>y��~���}7p��&Rj�D�50<��ϔ����k���)qG�(8T,P���g/�L?꼥���l��� K���}�r����_ty7��S�.�'!K�	c:����N;��͑F�{��Е �0�D:��F�!��w��T�P����o���y�8���kdrUO�N�Z�ۡ-Ջ��׏{t`�<��=s�\��r���|�W��7�=�2��M^��%0��p6�K��K�4�S�\ K��x|��u�O��;��n��P����R��T�J����B�gW<��Zz����GO"r��K�~PBfT��S�����{� 4tM��
��4j�R��ppY���%�-�~7�� �����lqϤ�H?���m�
��Yb��h��@���:t2�����_�v\�/�%F��.`�m�M��F��Q1ٴ�'��&>���iT�Gų\�Q]��S���k�CL��R�oC���3�B� �t�A��U�hE�
�t�Qj.�sj��ZA�R2
�o���;�'���>�rbQ�l��q665���}���ۤ��d�%�D��WWڠ_����vJzs�P��x�-� ^�s����d�p�����_"�ߨ�B�[��/0fZ����|���l��O���Å�D�w>�Ƴ�C������j1L0�aRw3]5�` ϫ�At]���v����ϟ���P���9�4�e*|��C�v^>[�06ы�2��m7[�tlyX(R>[k��(Yu��l:Y%4�=���6ƙ�g��3�����`��-�hN��SE	�����P����v��\�V�1_�~�9�ʕet�1�w-pDʩtJ��WM��,-<1�'_��2���h�<�c"JC��=��QIrqF��֕�@� <��~�# 1� <�v@�,��/9U��yKw��ϻ�aE������
#c�]�\�9Zh�1s�/É����h�0�3�Z���e�&�����&"��OR��
9�NT,��]��r8\g�Lp��4�<�wb�8�ö_}
��NՔ�\Q����
������M[�΁0k��63:�ě�^��bY���/�?'��S�+.^⫢u���ɺ_�bC[�U<��.�%G���%ed��c��>�I�6f��{ � O`0H$h��-]�x��+jӫThO��z��q�x�~�l��a^���{���*�5ٶѥ��٦��By��腖� �O.6��Q��5\e�|�&�7O]���G$���K�O>2��'��dG�c���I��(��V����#a{`���o��	���%�@_�:S�b�L����S��Y�5��Jl?�ѓ''f7cҥgu}�T��j#+�#���%J��E�VUa���O#U;	�Zk��n��	��9����T/�Xl���-����6 �p�"�Fδd9���6^k��#מ:���>G��<-�PE�w�Bz�<?^z�Y4f�'lq�4A�j+�{�t6x7�H ��H����� �-���/{��G'n&�X'������&o�J���9ֹԢ?�A�j4בS��`~�4,eX6^X�$�ALtM
 �[H���S���K[�$��}��M��Z4��8��F��� ��k����qNi:Q�Zo�6�[�)Yl+����d��?���aߣ��UG}�[J m�wOY=�qܬ��"����<�a�N������JL�R�	r�)}����0���Н�3I�II���������H��ɷ�z�>CJ'Dp��L��6B�,�{6,<V���1�ׁ����뿮�!�66����ڈPv:�F�#�k/�\�A9y*Y#4d��8u���ω��5���%��&\���m�c�UH9��z�߻�$%~J�L�7��hz�Ybf�2�vaL����٣Kv�Z�L��	z�5�
<����;YoX)?S�1nw�b������L�p5�
��{��&�s��K!*�gj�L��Gk����+��x����w���E�oe{Bn�-�p6���-� }+�u~@zP�[�2�}�z�����h(?�k5w)��2�mw��u�5p0��ʭZf�?��&挅�o� ۰�H ��7Ix.j���T�	�ؑo}�C���2m�8�����a9p��~��v�6��.\=\�J��O����
�B�l&z(��_�.N��+%���3�i�MC����sfǭ14� �/hV���(����h�7ķ7�#`n_T���䃃�̵yW�
�:�վ5���Ҹl6Wٌ�"ċ,��Mt�}�=`\�݌Â�<z`�ȫ�[p��i1#A�<��0Z}��f_�nG�.���ә=19��Д��[�e{c�����5�eU���8f������%���-Zg�L����Å����yu.ERǑw���	s�78 $ѻ�R��TJ�P�gw�Z�����Y������T��ө�I�Yb�Ɏ2�Qx�;	� o���qE�4�*��w�^Λ���#�n��^��?@���2b\���!K�cmJݷ���3O�kh�3})�Ӳăެh��5��q>�.+֕��O�\_)��4��A�(���^�� 9��M���1�T�p�q�M�c\�Vr���E�ѩ��r�k��:�!��o\ɼXdW�&z:���
p��~�ڵ��g��Qޅ��$���NR>��,F0�Y
}���veMm���ښ8��^��XғBS�n��o���/f�D���ܖ&H����&�����&����}�FX�ܻ�(u�c���I0N�W勌ϡ��7F.ޕ��V��e����/Oj����'�;ҭl?�G��I'�tx(TO�Ճ3�����/kru��4X����y�u���K�H�EXN���c�C��?T~`ƗjV���d��I�x:��WD[�ti؅�@�T;@��.���)�g�D/�k�g�W����m���Kw�'�+h&�V&K,z���FE�5�T�F����lp�eRD�F����h��a�j+3jN�����+R��2�,j�S�Y`��jN�9���y!6�B1�(�..5����&�����	�=���ks
)|��}���ˤMB�0�)��	z�j�t�X���;CA�C�|<��͠vL�)U S�,�mg��t�/H.���Qj�I��
���|Ip~�lO�o���;J��:���眄�Շ�f'�.8`W�	�1����w�>"�w|���:髵��r����@?T�I������Y����<	��Xr=`����8e����3�}���t����9͸���O�j�,�>P�n�j/�	�q����A�ՖfN*��d=^���H;�N�Z�2a�%C"��}wc�N��jTK��r��~��u�����
/�����W�Gy+U��ɐjkI�~�L�Q�P���q���z5�}6i�Έ&�ޙL`��˒ʒM揨��^��f�k��Vd�?8!�W�L��V�`�V�ki���oW�(d�鶬��6���i���eϵ0��>�พoLog�7�� ����רܜ��|����n��K4 ڕ���9A�R���Ay�kЯ��݆��� ������=UNy�q�d��jʘ� �c�EoZM�sߋiI�A7�M���/��{���w7��p�T�a�4�[����+T�tÑ"r�楆�N���S���z>��buޜ�O24��E���ԛg�Sd����ɏ��ޝ?Z�v��,���)���Z�D�ª=#���KW�"?��7��}{�!+��������1KB�8,��[�4���u�M[W���PI�������q���К~��[4�[���V$����d~��[��@��{�ʼ
I�3���pL'A�Ҳ7�(c����y����?;�DN5s@^?�r�kT�X鸢^O\%�ÿ�h�Ã�.�.u�xRS}�L`ur������p�IJ��57�q�P"<����{_�'P{�C׎�H��Z/���<��wS��d��X�� �ҹ��
	1ݫ�vE�_��i��;�{�xtT��U��1uk�,����AU�Sk�ep�%D�k+ךF!��^5���4˔zc:[��l(D`�p�Z[�J��
���`�6��̊��@Y�3ⷪ$O*f&����m���*@�?�W����]r=Ŗ����V[I����`wZ(�-Sdyd�Xșf�
�ƅ~�*E!t"Uu�]����*����n�.
I�?��7Nu+7�rW k��n5_���[�|�YwHoD5-���+��.�F�����&7�$:�}w��_�(Q��C+�{x������Wk�M�%w�7���#g#�V9lzH` �r��1���F�y�3�嬺�V�nN�8���TH߼��۪�G%˃1�?�)~�<7���[���`���h�<uai��n;SN{[}x�<��n�j_ه�3.:���7 +�)k��s<<spM۾��_��������Wu�M����$�,h�z\���Ң���8Ar����5I�����h䞘V߼p��6�fS��þ#�O
^���I�PSk-B"kG��7�����}�>���fé��a�w�_��a���늷��g�_�V�{�v��}��$΅9	��Ȫt�ԫ�a��4���ӔbMS�
�Bi���=(��!�"�%-��j�����3����U���O-��W�R�jpP�@�����Fǿ�{"�B[�'�Wz��j {r�)��I�P�<,Q�m_�_�7��Ύ�t�M���}���Ưs1*N�6��X��S,"��������eJ���.ٖ�Ĉ�����̓�E(T�g���4H�&�A�zߘo��Œ�������kk�e(B`P�����w!��%�[r�qQ��G���iN�/fs��~�%5Z�����e����ڗ��PGݕ�-yn��gr����2�8��ī�wS�^�AY+j�083�3����0���8��c{�$w��o��̊�̡rJ���$���5��ݤ��Ù}]���EOU
���q0�z�2�(�-Eƣ4Eș,>�G˘E�e>k��l\{��e4����F��F����e�Kd0�r�6+Q��O���&&��ô,%��gV��&s�V+�I�4����+1N?˷d�^X�TB`fm�=-6P���.i)zO�q��^:�B.3�����N��;٩�D
		�hX������|Y~��Fz*U#-�4l�Wlܥ�G��8�~p9`�Sw�$k)�(��7������|E�`�SQ�"�8�>��)��&��A�ɐ�,��]%t
&�SZ�J���)U���o3�L�G��𳠘�~a��#���G�)�@
��9�d�`E�[�5+G!U}���Q��`�X�xK�@�K��>��!�nd"�שŻ� �t�3(�߄��ڙӿ����焓aC����W
��Y7�����wJ4�k�m�z�*'_����рF�4@�^o�����f��/�]ȓEÞi~5LP��ZDL�N�[mٻ�Q��2��[1B�����m�M-\kY$(�U�E����p�%�Y�^���j ��&شI�?8+p��JH�*ƂJ .s���tqG�a�ZDH���s�R碋�t1Bg���+X�8P��u���>ut�(�ߵj�(N�Wή-�&w��m��J���R$��s
&�}��wp�K�Q=;9c���l��^��T��4�lO�U0��1c˓k$h3N.J�j�T�Q=R��6nIN�	���VhO�-��p(��#+�ʺ%���p�g69u��]c�ו��������a�c)ۖuZ�V�n�~~����́d����1�W��J.iOD}H��Pu��$�fzq@cR/2��S� �WxZh��p�̯x�C�F�*�Dip��	7��7���b��u�ޮ?�5��B���.=�w紡'���2��H��Ƅws9�+�'eՎi�{�[MV�g%уf�$��t�	�����q ��f�Ƥ�,���u�V�ٙ�O&A��ĥ��׋Ɩtsa-���YIf{����j�~�{d�Y��n�Ĉ-o�_pVj��M��b�>�aC��[d,V�J�#X8Wd7d�_�>n3�YH-�Y�,��7�=4�*Q�FK�)D
�Y�#��+�/�JJ�gg$D�Wjh�j6t��嫧����~+�1y}^��$�+�mL������Z�i��`�J}�6/�] �x�@�iQ�l#ڻ���k����ϵk	�xDE0|�Ce��!�Vo;%&�-����y��/涞ݴI�+���ﵚX3�B�K�Qov$�y�ü(����
����C�Q�P�(K,�L@+>�L����}E�<A~������������μ���I��Ln���&�W�����|�f�i��7o�E��77ϯ{Ϙm���U��"��/��#�Z/}k-5�0=��R֗� �B��ȭCJ�Щ9M����]7˸5Ӱ���d5 �]$���C�k�F���x����V��KK҃1�ɮ�b�7�&P�e�A�s|!5�2��~V�vz�$�~��?�kc˕5��O�S�&!�'Qn���F\rS�� �+����64-,@�����s#��5ﶈ��-)��R�q\X��r��a;�s�cl�����*x���d�Ew��-Gf�)fk(��N ��99���5����/I�5\|%�Q[UIasmlm�U���h(8=-*�+�R
٦�J���k�d,�G���2O�u�:�n������,�I�f����;��n�� |\0��� �S�/�$ҙ�%�j1�x
�$��w/��.�pw*�R�� (�B���df����[u�N���K�cv�('��8�6#�=�$��gdm`��?����b�mrr�#��3i�s�n=�}��3��&�G�>�q)EA�˺��M�l����u
M�C�8�,|ږ<�� ����������?���N��Z1����8>H��
�,_ŗi��j��-M��s�K��Ҷ����lK�2��S�+��i����l����훲���,���U���R�ǌ����>�Q.�u�������:��z{-N\��!��V���Þ�$��d8cw
��s�K�T!��K�d�\@Mn�/��ꆠ��u=Kt�8�w�#�?��ˍ�F��ǔS�@�o�\��(�`K+E��{u����K1�0n/5ʂ��di�^&�]
����3��u��!�21	��gو���lDHv���N�Nq�!��/��ؼ(<\����M�O���-iSmV�?sά�(�r��#��P�;�;��.W �Fz�a����Ԡ�^�N4*v���M�򕘔��O��lwp@V��,��<�zJ�7�Ek�� ���T�G�ԍej��р�dhPr��鶪�z	0���r��$�cg:�<��S@�����"�� )"Ym��vf������wXao�ÍBF9���E��u�&�.-�m���m�w��&jq�g�'���{&�9��{X#�۫��+*���
9�e�34��]�<~b�x/�]�_������Wl���l��E�~���~�w>��a7�P��s�̟R�K�E�.);$��j�:ʖ�$�3֙1�h>�'��`��ҹq��p;ᷣEq^��@ύG��Ie��/
����%8��5����G'O�J�+x~�J$�ڒ+��kܵ'��)\�-��Z��T�r����h���h��_���o�e*R4����Z8��t��Y�t�����C�{8����(vPq��@�/��0�~�����΅��~IIQ�D��Ss+�+̅��{`'�m	��i���¤RE��p$B�~��3M��r7����PRo����]�B��瞩�H�@m6B�^�����)��"cɹB�~�N^DmFp��/�4�I�,��D��i ����OW�e���L�U��\_��(�'\�>�M�\ޘ0�`d�� ���kL��r�w�� F{��#-�A�}���5f�\cO�ߏ��� ����"-�<�E��pH��^ �-�x^�c����8�� a1�\�z�!��:*]�Oy�H���:��Q��Ǎ(��.@K�&#o�Vj�[��Si6U���Xؒ�[ݒ�yg0��L���v�u�C��^�=����-ԥ��_F̿�ٽ�ӽ6ډJG*�4�V�.�����5zQ��ǧ���u�Ӯ_C�_7������<y��$Z2{�Z�.����
[�����TP��4%~?��R��_>m��a˨����H�s��I�R��P�L�B�-ۜZ���U�unO���V+�u�<�掝Ү'�"	��5���Z�q8�qo`�#�Y!J��(��|���*)ٝ>���G�x+8�kVBp��y��H/��w�%�r
��[�Yo����f|Ipn~�g�ň�(�A-�X����(=�(>P����Ė���$�����j
؆W�|"Ԙ	 [X3���%�s� ���{B�Ib�E �^)᩶AD�6&a�1���}�����?�e��B�$���Y���$�<�B�U�Ʀ�� ���^�+�|�o��\A>b�D��t�[�n�y�`k���mi-snF�sg�Vo�Ρ\Le8�蕮 +� 8�ϓ�'���!�Ẅ́���l�k3�����:?����ވJ�
�T0�s.��.����ٽg�)�1�\�����g��o���7�*�d;!��`�f�ј$��3�A:���#�=���b�6���|�CQ��	�d�|�t��1[%8�b�,��N�U����N�˃5�(��k�ne���a�~��_���%JS�G�wn�z�ju�8��b3�ơ�ȣU�{�t��ȑ����ѧj-�
�U��Ҙ����D�=���e="��,���f$��a��)e� B�*���盆ָ$��gGuIF� ӂ�������eFW��_9�qL��Q�oyh��'��i��,/Em;C0P��-���u7����!���Pt�BZb?u�I��T���ɸ�
ܓۿ#���\��5n?�i�8џP$Y������ph`���5�g�/�'V]"*�
~���� w2*�Cs���x��v6e�8*aM!,Wh����.�k�.����/�ٜ/�Fc⯳�6���/��%a�.�������-@|��Ht7r�=����;�ݥc� ��*�/��	.p���l�(�f��fm[�H�
oŖu3�G�=��Mp�7u�,�NV��lKE0��%|���Cr��D���3���ß��x�����?��2�2{��}�`lؒK������&��{ˀп3���j���C�C���~�[�\��f��J�g�d��A02���|��&G(�*���'Y�L=q94���Y�����K|ǵg�E�+�\�7��I��X��R�)��*m{_E�h�F������-��T�a��ml�ű�=S��k[�S�׶6���2��ʄ�7C�/jW��K�D��_4��6�@�U]�]^�Rk�4�`К-�@f�s�s?\�h����a8���qTe����h�[}��GP����n�����B7�j�R��Q� L�UӅ��533<���ބ.b���e�-g�;��f�����"���Gq�q�&�o�Z��9��_{! i̓J��ٰ
�o.U%Q���}@�g�y�f]E�M�&�Ã�Эt�I�I����U�B�O9���򗰮��gn�z���+�4�n,�z?��w��"��L`	�ԋ`GO\��]M6��9ɟe��NP�>J1�h
Şfk��ֺ��?ܧ
SO�{�%��\xx�pT���QR@�S��c��嘤ђ��̦��B�e-]�VN��E-OY�����N���/���'^�Y�LjU	9�2	;C�(㘗!�P��c�J�4���}�����u���Vl���HO|(8v�u��1k�VG3�^�������/���B
1�ؤ�j���Z�o�����@qC?���?��g��)"<�ҼI>�o~Hk���΃��ͻ2J[�0�n� q���fF�yj�/]lD? �Q�DRS��&�/S �1�c'�2�8��h���!aq��	,`PW}i:��۫��5��Qv>V�D��>�s��+����j�ez.�@r,��$eo�[�Vx�qY�u���;3�}'`�`�y^�k!�ve�M�lm�� oW���������j& M��VBbd7ؘLa�)Q�{M��qaiԕ?��1ǽq���T�|�h5B6� F��B��,���,ב ��ϴeI�P+ ��2��+q�������B+J5���*�O�/����
ύ�����2��f^!��?��M,{�!��&�cZ�`�a���1�����<Q@���YǱ_�*,�4�����[���z^����}��	+J�_Ƭ}�����^��o�R ~"A��fn�(���$�I�sB�mmX�4��{�e�,Zt5,*,����b���|E�_0q�P�.���0s[SMx�Jf�M������^Az;��X1���q�	�u���|f>�8@��9.�iA��vRo2�*����lhH�!-�Q�����
�Q+��}zi��DEk��6̠��[�$:��@>M��<|�C��%OF�1��I�2e0{Z��v[n���[�a�[Ј�X:#~�u�����
�'�Λ��,O-��y�ΰX2ؾN�{�w��r�Q^�CgBy\�r�D����L#�߮�Nn�)L���؜Q���/�	PU��^aԒ��|��2?��]W����+a�|�x&aӘ8�-d��w�d���xB��  tX�_С5K\�h~saT�����Ď��������j��\P���Aٓ���o1��YyBȤOe�S���
w°r�(�����T����68T>M`˒���MU�5[#A?&�����\�M��lȄ���V�/�P:�C�5��0@���G+C�:�nGu��GR^b:&�y`&/���4�B]|������B#A&-�l!��|N��A1v�� cR�:�pa��i�gi���`5���S����>�����1��t}>_E�K-�ۦ�?z��3XZۖ�d����F�)�ٴ^Ey7��ԕL�V�h'�����6��$���$��a�H� A2�y���jS�F�����A�/,H#E��</�Q�?Lg������bW�_rt�໩�܍�TV�-�|�}]}�D��!�o<g;��WO<��c¡�� ��.q���-�iS?`�{����G*�εd7S�1��4[?��oc0D�d��~o�d��1�*�u��[kR׺���Κ� o�qr:YK� ����^��˱�g�    YZ