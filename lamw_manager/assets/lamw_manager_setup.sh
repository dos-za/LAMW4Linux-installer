#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="988266399"
MD5="9a1ab16698096fbb43f4944540d5bbcc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23688"
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
	echo Date of packaging: Wed Sep 15 14:11:47 -03 2021
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
�7zXZ  �ִF !   �X����\H] �}��1Dd]����P�t�D�����a��S������UT'r�:���V�E �o�6�AW8��zr2�M����֟уm�`�1Jv����y��:�X1�1�XZ'-5�"�8V��+�2NDH)X:d/tdFnk=����F���(��:�=��Ux�/f�Dc5_�!��ڢ���J��I?�I/�ͭ����"�E�
����5�͠ҩ�
�,�@�92c��NJn�oV1 ԆN� u?sT�t4ė� T��Zl���|qmQA����O�`��01�E>3�\�7eOY�*J<�*� R
1��r+9������D�b��X�nP������zعEl�k�̮�𧃽<I:��NnE�ߩ�N�(s���(fw�8�W��_|[ &��� �g�fj�-�w�!W��p��|U��U�F��
��`���*�ax�����$Nf����{f��n8��8�BLmn���#3�Z> ;И�g��Q�r��P+�������7�]�Pu[�2�c�}ª�,c5����8���t���fD	"����c�[��`�CA�3�&K V^a*Ut_�Jy�6?��g{�����*�f�7"��3	=�`>��k(n�+{�����m[Hs���8>�7��Ǭ��ǿM�(xt�*�Ƿ�'�z�Z�fMji��`d�j��9O���h�v�$E����+��/���?�=��S�;�q��*�J��p�� ��?�d��{w"�_i0M$��
�e8iFa�b'��ҫ�n�c!��4Dy�ZhVg49�-WDQ�g�߫_�p�$O���"�5��\�B�gV����Ԇ�ҽR�QYp���:푆Tg��+Z��(oJ�>+���6���Ơ�;�����m�G����3��"�$�9J����!�"	P'9���\�j'`w�4@,�Y�� ����#����|�SN���Yy��~,)�0����D+��Z���(귇�|�=��F@�����2�f�D~��^u01�0d�Do]c�N�8��G� \����f!�Ҙ,XCY�"���2CCo������\3�Tx�	�1Y;��U������g��
2��%���̱�떱��8"��Nꮚ|�����Z��{j��}�8$�v�(����T���a��uA4�Q��m���s�YSO�=o�&���%�I�?�oU�?�t�.�C�ΰ���GC����3�.5!��SLn���q.ʉ�ى�u�-�<2�O�l�x"i��	P��6�?`��J�ڳ9�H�8�=�|I���D�I]~G��H��jk�lSv?��<4���N��p�̇{���B޴�cj����5�u:�����.�(?���ɉ��2%(�bˇ�@���R��$Ƃ����D�%�*���	��Q��n�A�%���9���;߅��c�ql�2|��7J[s��<����9�&Ρ\�d�R���$f�:���=7��p#>S☁�2��F�S蒣��>a���\w`�&mrz�>_>����X2��_�g���x�8A�R��!(�EB�hJ�a$k�j5٭��R��6$��ʻ��sޠ{�����{�� �$iK3H?��-�O3��,�JY֘.�lN��f|=�B�P����j���&U�^<ׅ�d�	m�lߘ�w�:5�<��0Ah�R>iL���x� �-&I3�Q�฼b0��u��@��m�v��$�	ǵm�~�#�^�['��\�
���#TR;U�?�=de�JKM�ݗ_���lv��/�]�y�u�\�����Q��9����^+�6e���U�sN�I.áN� M�$CuO���L6k��s�Y�MbYOS	!� �^�&�do1��1xɚ�tt�͈�ל���K(�%�{��/6�M�����,�:�T~J�P\73���� �2����j7`�pێ� �\�b�DC�0����'�e%`����2KYϫ���u$	āvQq7p�oڒ~í�8!��.��xp�@T$��lc���C��ED��6� <u�35�=���plz#c���7���pkmBkJL@	"�s���
B��T<ʬ���g�u�(�.�/U�����
���O\v�zڑb6Y�m�J�;Mh�X�%8��TC�"����?�B##�W��1=F�o�D���7�&�nk�h��L�R�ɇQ;vG?P�r	��T%���9���q8P�85��g%��q�CU�!��,}t��4��L�x�����ɄZ�גdf͓�l��y��.���<��ǫ��<\��/�e&:?]�//�#_S���l��X+\�߼.�/����'��$dN�F��6��mE��~�q��1 V�cj�0�-lN����\���z�XP^c�Xv�k���PQ��g�QxgE�.\��gI#T0h�Z����C,��t�#jR��iހl����L~ʔڡ,�90��}�O�Л}���U��{��JEX����s-}�yI���C̴�6��C��3��!^����L�x�3�u�B�+��O��p83�J񪿷>�R��9iZ��W���(Ay�v{2�qA9�ƶGS����a�qQ1k�OjE��׎����%��eRi.X�Xh�4ab�d�\�&=�����	�d;��F��?A��{2+�S��L��"Mr��/z�|h�� t;�u�΢yK���_�u��M�'�����9��&���1nie7NA׃̒v�|���3�l�T��c�4���"�ًpg�Ȟ���K!�0�7G	d��wq�W�/��y>��2��x��>2�6xf�F�:aҋH{wT��6:� {>�X��w�o8�8.W��Z��d�b�,[��2v��[�?"!�*m�)�I=�r�&�� K��y%EǕ�V���?���^���̕��pfv�������i�6��dpO�d��	��hj0������I�u�_=$O4�t��d���y�.@�����/[�D�{$w�'����\)Ȱ���L�
�75�I�v�Ǘ�D��]���v�)��' r����S`����:�������P�OsP� l�)\_2sҵ��,�ν��?�|C���Y��h���E4��cS�����\	�2c����[�%{°�Y�x���aK��*���P���0O�տ�#�iT�oĻ�����ݟ��+/g1<���w�ċh������bo@rl>&S #{��5Q���+]�Íc%��hA>�xc��b��|�5����X��3�3�p�ؑ��	R�!`Xa�u��5О��e$T�wP��WvT�5��ާ�*������IV	�Yޠ[w���_u��5ʿ�L\/��*Ւ�䩋���oSj`�p7��
��
�PR�����I2J1�򗒕�2P����b�T�4]��Vu�LUN��ȇ��)�VdI�՗�Y���Ϸ��`<G[�I!�t'�'�'��-��1����#�������af'A�Nis� �F~�ù@��X�S{QXՈ��r�Ѽ��Z��:�������ʡ���s���Xe}\�q�;���Y�>p4vT��l0=Nu^�^7����n�����pU٘�ia�1�Yk�Ԥ@J`ͦ�R{�<���18m��Ic�ؽ�m������~��w=As-�,6<��O-j)����vܬ^���Z�Q/�����}�K�ˑ�,N�."���n���+�zT���9��Ң*#G*n�&g���j�j�ʝ�#\�H�g��􌤻[�1^S�Ե[T����|F��(������\I�ԵE�O�L���äP�4��۔�7
>�P �;;:	�kf+���M�ǟ�|R�=D�@�?�U`�=i�TW�{Vky�0�I�&�xF#�q�C��Z�C�3բ�J��ܪ�#ջ��>݉���d;�c�Å|F(�QX�� �@���|��s�*י#��{���J��"�j#�|�
\gHE=T�+�Q"o;�(\�N���5�������i�Lb�W���($"zJH#�}�c@������
��=Dl"cʺzF�Nּ�;-0E�M���=���~�!5)c��tHg s�5�<A�8'ڛ�Bt��,^�ޘ3���6��#0��}p6�Բ>�Jb�J��I��&$傕0ru�����q��ΖIU��?��3�Ab~�R�i�<�a��dy!���i�C7���Mrl� �c��q=[��n�,憶<��`���S����ˁɂַ�ߑ]�b2͌��GF N&��	Wl�v�,��҃�e���!%K8��Wf��D�t;3U�Mʐ��6��{�#�U�c�HAm�(�ܬ���f��
}:���]�Δ��,�{&y�*��V*��{�K�V	�#M�L�Y/�*��%�-�<D�;�]a�O����ý����0##���1S��������i�s�, A<�G��m��Ɲ�e��n��\��+�yMoP��oKV3�^��|�c��W���w�!�`�+�F#�6ѻ@�Xt���$�̐e��j�H�AQ���F��+��
��vX+��a�������Y<rH��`��,�H�"J�BU*6j�2x
Y4v��p�D=ћ�R�������� ��FN��7�x��	{��XX.�QJ�#���|��(9j� G8��J]"�A�DN;OD'=��m��o������f��Em���3�v��H?�#�۸���_��'v�T�q��g�p�7(7�TA�l����Co��1���,h �$G���?&�f2�o�d�����e����{A"�@�"ή�<����? �9dēXF�!7\i���8I�H���uL�˯�fSf����Hp�bK����Y��ʹ�ڻ+t�	�>e��^�&�����B��,&nV1������0�K������?��W���#*:�U#�r4>ʒ���Kt�|�q����c���녘͑��[èLL)���-"�ee��[�0��(2�����;^M$?���Fi��f�/�y�����6?r3$�?K~]��_x�b_ESU������K��/��J"��`%_�n���'�XG�$]��e�S����.��s񈂘ӫ���:�����w�D���޻[� �[�P<W�xLE��z�� ٷS��T� �#�j�I&�d6�nx�Xi+)�.��d�3QKF�,q��[Й�D���w�E�:W�`���pJ �b�6]��`��F�Q������.�gQ��f�/��os)�ǥe�i��ƚ����fmm���e���x��G]��Ԅ��5 d�ȧ���0����^.����_���+$9&k��yY�j�p��n#r�[�ѽ�ܥ��2h&� �Y�;}<m�&�zU��0��~�Nwd1y(o���5��b+| �)�L���٧U>� ��޶�b��k��`�ü˜!/��.2�-l�Mq�����?��]3�(Z+���f�{Ĵ����oN	�����i#<0=��Y�����_�q�	�#��!-��4N�j�K$��\=��Q�f�7R�JvL�b9�l&�< ��ϡ
ƴ��(�G�I��b��7�8���� ���%��?,���H�I:[U58����&��s�J�Ȥ�`�/'�f������u�>�ceM=�<`�p ��l38��y�!F�H`�n��JTΔQ�jh���?T�KW��1jR�&�_b�Et	�HVf�W扈�����
�O�e�xмm�D,�>��{�ҽ���NI(֢��B��r��p���Ksf�_��ԏ��t���Z;{�1�>�c�d��R��}��k���Ħz�1|��0EC=��\��C�I��I�SRO�(�zne����P���f����z3�� ���tt�]�.a���{�����̩�	s�j$ �}�	�_ �[#�L�-OwLĭ,>���8mi�m�b$jj΃D	 ���� ������֕%v'en{n�g�nV�]�H�,���CC*g���7�.=�x���s%|��1�W�]�`�F��߉I��*����8��ف���V��!�������3N���f4tJ`������,No.� �dF��&aJ �þ�1�����q� *������3|�4,PnA�c�ڝݴ�l����6h�ץoK�x�.�~��H���)�&:6�Z�4U(yZ�J�SOu�%�'��'�;��,�{Vt�v���'~�KI��`@��Y|�Ρ"�g�c�^/��"�E���,�*NI9�A˽�ʕD�-;";{�g��ߣxQU~�t/LCDLc'r���1{ʔ�P���k&��Z��"Wtȥ��\����Igx���Ol�\p�d����J�	6�<ץgƖVH��0��ҁ�ѷ�g���wb�s����ގ�n�8�c9'���r���t6d�{R9���qd��2��\ܭhe��
/X�H5?��t�ν���Ӟ��]O��S�P�����C�=���$�?)(�Ha�UY�ơ	�+��%�n˚`ƞ�h�&�3\?�4��d�^�Չ/��m�)M��v�1r؃��2C%�~�U�U���<�v餒w��Mz|\�$z|���t(��x^�&|7����a�&�rF�S������l޿V�w�yO�jfM��9��P�?����e��%��ΩRum�R6���jo� �b�v�K��n-�X����d��I��	g��[�*ޓ(Z����p�v^�F�������4�A�$&�o�!5�C�l�����<��B#�zi;Y��$)M'x3f�XQ4��KӦ�^����Q�*����G�������p;�� xjE!)��}���k�yO�^��~6�p� |A
��/e��vē{@dk1�e8sF�yQ�\�;Oh�-5��B;�tt9��4�wؖ�(�(�S�1�zVU.��_L�y >F��+���4i�%�Y�7����߅S�m�89��*�	$�z�١�~�+X<�5!�GOt((��ŉ�=p��2�D���{BU�Md\��|�w�}�����
��Y:���ΖSg��}���(��m0��t�H��^�S�-2���,3��Q�����l����}�h�z�n%Q�vލ�v�X2q9�~�O�6覠I�E���7��}a���h���`�Զ]�E��<��-���r@GӲ�s ���ĭ�y�r�� 
Ws�������/iJv<
�
yh�]�9�x�>y�X����f�i�lP�"�6�|�i&�Q�QDЃf钊�"� qcL$wp��,#Q�t(z���)A�o�s�*��M�{��+�F���[;X.�y<N�.="V�WY%��E����$c�>��Lց]B�|�7Ʒ�B�o	����Qa^/Os�L	n!J��;�V�9�y�wӷ�����Z��}Z�v�RϠ�v?rc�#:�;V���a��(�� ��C�̳Af��
bN�[���G`��L��� ��5�֔ٓWW�{
��D�����L��R,Ů�L�«��,?�p�U�e�i��3�Yuơ�`�$��mh;Ҹ9��y|��z�D�ZΤ���֢I�lvK�V��z����Sӆ�_��!���,��<�����݌|�WXi"��5u�(�a����mp��I|1��ɹ�q����[%iK�l�N���w�U�E8��"��ț�6a�d7�TԞ�Z���N�5��u[���bi���� ��5�Fi0a�*1O��c▕��9S�X�Q�՚/!���o��ੑrG�-1����`��[�o�xQ���%?���g/G`ށ�Eص�Ki�C$�?�m�>�{[�D/ak�.k�BW�:=��L�\�a��-r2��'Q�ũ����M��#
���4S7שS����.��O��Wp�� �F����<0b�ST�,F��,k��:A}��t���뎍'�K4�Lz\�W+�I����f��D���1�#n=w�$h�ػV�7��6=���k݀���Uy� ���>��Ga�J�Cw�@)!.�0ɝuT�ܺ�ћ�m������0��3:c���-��</��6��A�M��}���D�m�L�!��2*��\���3=t⌴j?e�G�Y�>w�,6P�	?f�ߪ[��� �'c��������HI�ISH�iË�gEg�Uk�&�r*�瞁�ϧ�'M��_uk�8�:���A}1�.�R���d�L�_WeYץ�v�ؾDWG���}��}��|d�O�\�r&0�@�5�H��"?e_D�p����2X8X�F�)�JP��Ӎ�+�����ۜB����p2�v�]��%��ZN��t�u���3���a2��n-�3�H�H�N��B��5|���8������'g�����bA�����~_������8���0�����8gWo��5@]�Bh�_�z�/���Py��������~�����i�R�B��]c���t�{^f���q(7�TJ齵"�B^�IAt�H��=��q�+��v�=�Zҫ�2x�G8�w��ٻ9G:��d�"��X�l����(J�)�����@U`�r�Ӹ�z!�K;W|Z�D_�/��D��'p�* ~q �I	�p�RW[�_ΌWV�[���> m�/^4�,�{�s�͍��~Ф�'r����:m=�,>Ӥ����6��������H�������2�.4/�7�H�u�<[:�7��yF*��,^!4�ɓ�B[�#��]��%(�ȉ�<�Ȟ|PsT��;o7������	w^�PV�h^$=�����|� ���a1m{h������_�%�K��i�؆E�m*�ºQt��8ݗ����q��~�+����V�v��#d���am�OU�N"%���^�I���L*5��~����f��8����v�.��"'-�T��N�u�E��Wߥ�����pa]�%h���'fFO�i�2Qg��!��_U���j��%����d=�A� �߅�X
�q�=H�1*��#-v��ő�{[=q/MyCZ�3�kUM��5QI|�(�f5��~�Ɓzq���|�g>;H����YzE��|kf����И�7�qN�y���; B�����b31Y�,'��Wx\�c�٢a��m\�[��(����s�����nV,�#Q���U2wsr�r_�C�l�����n���{w=�QR� ���c�!#���nN3ć�ԛ��)}�1�Ւ�z��*,�2�O���]�\|A9`,�]�(v-ˬHJ �� ��Z ̒�.��)��d3-]��N���;@����6�%�v��"Y����v����Hg��ʗ��l�@M�ĉ]Ʉ�
2�_*��u��IL�}N�*�s�i��4ê�G^˫�l�;*Z�ܺr��̨g�[��3��a��~H�K��A8(�V٧.b��9�ӛ ]R�^P�����4;��r�qW�n�I�]�J�6^�"�����=?��KiX;�� 1�r�P�f�lp�$W�E�s����� �fn�6�#�b�g��,����E�U�c��0+`^�{v8&fp�HC���6bQ�y8`E�����_ь�Fұ
Xr�� ���)���e~�d^�w������,��7'M�aՂ5�,��S�eǐ Z�
b����M�#����N*@D~u�h�+pm*"�]����a��� ���1�^63�M-��V��A�s'�V+ �e qp�s�4d����
��|23�re�R����N�U���sX��j����8ę~����Y�g<`X�|�䀙q�9�i9�P�c��2�
\1d]��y�����"��'@���ta��g��~:��C��X����K�%}J�Y�RR� �-�h�i*���8er���=�L
^V{�6��Ld	W�Ňi�P�E�$cK��5�B�9DF:��Tdb�(�=�a�ѰO!k��*TgGp��l�~%_��z�њ)���M�ϋ��H�����f,�|-����R��_�*5�v��Tn�T[}�[��'�Hq%5����8�zW8w�qK��>�p2��Ӫ�I��4�d���g�C��n)*	��f[l�ó���Ӿ���������6tC�]q��Z��5y+ ��D��f�������@%���t;ڷ|�y��/�)�^��{f�]s��1�+�_��d-�X_�eǽ��+/x�7>Sǌ�~&[g�U�i!Nu��m���,R
̦3�ReAKe6ɛ�
��˔��^H�y&�_��0��|PB���e�\\��]���
+�����m�� �f�JPgpX�"0�֞�W�Xm��G8,��Z.=Ų��{�9�3�J$J��N;/@Ҝ��p�sZ�j�DT���Ht�W_�'u��#?E�YkwxS���qB;����A�şPs�}�~�7'�d4�x&�� �Rd��ǩ�`*���RO�W�i�D��7�� c�HhVɀ��<fw����Λ9L.����ب�������&������E�P�J�x���tLں�̋��K%%XQ�H٫3�ˣ���j�^��N�Q%�o�#�[ņ;QF}g�I~�/O�!]g����5�+G�V�$�����ݦ��>�r~�m���q���Ρ�X�ő`DDP(l
�Y��η�<�2>S{X���S����S���VU��p6��I��#
h��-@o�Rް��5`��NK}�P�y���K��(9ڏU���Y�iN���,�&ĩ��b9�܉��x�Ǘ��	}ͯ�.=��3a�nMx%m���nZ_� 4E$�}�����<�"K�K��xu �Ýc@(�4����~B#���[� �L{�ő���`\Ћ�#3D'�:�g����;�C��R���s��h&{SE1���P7�D��s�X�]��w�6Z拁����WqƎ��{�`^p?� 펀"![���%m9u�:�1��f5-E�<�Eof9�w֦�$������C9��(1�8��D_����%R�u�S�;���܆\�*� �!ֶ��?�0�֨=�&ܭw�>�����<Ģ��j�6����R(�"
!��r�#jS�0��,��3!�G�܌&i8����@"ϕ��e?�����w&@*͢�1��[�^���C��bN��s�:�p私bd�.@5��WaQl�}� ܽ|�7�y�AɶY�����9�\�7�~��Mzz-Uk��#Q�Y]&���oײ����>(��L��p�u�j�� �LL7�xE�?>�kL<��뻱���ű}y�5��֖��6�K��&:�8w}�G���n<I��T�f�Mr>䤁U�������ᣋm�`�~	i}u��G�{�Y5�j�����q?�3I,a�r��K˝�8�t�(g �0��~�:��'��#[��rLYe^Y�)7� ���>�9�s&�_N� P�����z���� �.^��B����%�gg}y�.Ŷ ɩ�MhU� �R�2���H�Rρ��ҁ�U�~P����Xi	�l�x�5�k]�Q� ;l[��h�����t���Ji��L
`���ptt�LdB��6y��؃\!&�ױ����4��*`]}a�����s)H�O���ߺ��R��t�
��d�`0��]~yq��\��H^�vy���쾫Yv�;�w��N�L��G�rq
1(<�����9������'x,���Ty���f���ֶi�Mj� 4��N.�o|���,�!�=XY/�z��^��C5�˃Y�{���=B
�o�|�Hv��i/���������ȗ@���Jh�(�v�@�.v�'�X}��D,,E�@~����J��0m�%ա+F�K�x�3�VV����j ~�X��*�ﱊ ���m^��i	'h�PpbK)O@*�u?:s����>>�B:dzC�@`��fcoї�+�����4r�c&�Ca߻��|�&���e��۫ԎӀz$+&1R��ųW�1��I�wJ��f־�T���������w���ϙ{OpFnSq���fh�}1Mp ����m|-�r:���N����:)����a
�R�3p3.�v�3]�Fu��-"��q� �B)��AGXjXmd&���m��TG��'bER���:���ј�t��xq ���?��Ҍ�5)M�����[�p����t�]$�qK�t�6�M*�=~7~���=�ٳ'�]���8���'�k�NP�vT 8��LkF�t��C�ZK�Rm��B�0X �SD��ҕ�
^u�Ce2a�F�X�?ڤ���R2���V~3x�V�J	���{��"�x޾�2����qƩYR���le�[y�~��%���v���-t ��"rm�E�RW�+"EtɐP�Qn��KkJ�x4��lV���6��d���9��`����鎔��j�b2�F���C��I��x�	و�����1�	�E��ۏ��� ��IǍ����O���Tv�[���lv��*XTa*!�u�z�sx�Cg����T����B%O��ϤR�1D;��V]O������}�`k64�ES��K�w+�`�ʋ�|���_��f��K�+Ғ�������)7�w9i}P|Ҥy�����)������¶�<O&��R�������p�x�o2|Yx��縹�q������L�
ԝ�(���cn��1�2ӢB�G��k��0��Ĩ��)¦4<�ʇ�͒#�S��G.���w�X�ݧ7��[t�8�?����,2�1�i�9QzkaN8�ӗn<��׷����+2�5�vb5�5Bۯs�ϛzW
�bPc��� ���ZxJ�!��z��ɝ�9ʹ�O8��B�/7Z8��˴+�g��T�=p�c�&����S��8L���xχ��k�&�� ���3�TQ�L�#w�2.l�"�
C_:����Kl��͊"0���a����Ҷ�EjzJ��ℤ���������'��Lb�Jg�	*Q��X6�8�-X��g��	��h��:PG�k�\��n2_FQKo��>BB ��8	��u��w���>W�{vt�);��Z�j�QI��'P�˷�T�e��]|�09$ެ����[��9h��𹁡�.-�׍щ�ۃ��":�7�%_�;������/}L�EK��kG�y��/��_�f��r��o} L�o��m����/s�:
v����<T9���r����Du5��yڞ'�����I��^�M���K�>9�����z+�6L�{����^jsNK'/����.Cl�D��4�E��VZ���C[�ѯy"ZMDw��I��'��?P'vU=�-xDn�̃@gD��-7;z��H�h�`U��$>^��[X,7�j��y�1v=�{΍����e/l�%�u�8/��G|i�2c��]vc�(���;������q���v#�,��kk��B}�k�ք�.߮kuF���B4�%��]����i�E��E1�U[�;����g�qT�=�W�q�4�XHA��e��p��0ph�4,lb����H�l�g�ʚ�!���+3I��>���t߳���%޽&�K��O%�W��>E��?��yf$�n�nX�EqIA�S����zk�'��V������Ԩ�ϯ~4�*bq.�����>=�s9��A�W�[�e~![0i���a|,��=w��Qy)͜��śb��Z�b�Q��`��V�á(L�q�"H���3P�h�����A\���a޽� � 3�[�Yw��w�FQ��gJ���++��<��P�t>d�~��
�^JX�����"�jt���(d�&%$��}HVo�i���I�T��Z��rSЁ�;�WI����l�M*v�:[��M��@w|��Y,ςY_��lh��=�n��>�����&���p�7�y�߽�K�,R�D����!h�jjwKdW��+}
~EGV�c^�U�88t�;�@*���L���5���1��ôIL^��`���GC,Q��0��6�L�$k(qἺT���Gm5�~(�e�j�֊xi�E* =K�Rl��K��[=~�S^�r։�Nv!�gј�#����s!��(v�Bt?[ҵ���,js�H���p1�����QG����d:�3#��C���*$����%�:��,�[u�Q@�]>���q��������&�����ǱI�M�;��Bķ���aL�^�_t���8B����^��I������}I���e�u��*�Q�]��x^',�z��#��1�?۫�v�1`l��۔l-��D�"�:0��н��*�������J��P�n����G��~�$)�XSOl�/�(�\�/q�G��~Uuk��$��}'��P��Ԥ��u�{��oTO��k�?،��\,(k[�C#)�s�b�	v9��S������ �ގ�v�~է�������f�P��/
uʃ$Y��F�����6�9;\���A0ͺ� >x0U��Td�#e7	�C{�xQ$ώ��[��)0�s��A�b�(3R4�#�Վ��5`O��VB]��#K�??9���� BS�ZWN�:���cRF��;X�&.�����<����H���b�z�����e]*�i����J/ϹZr.�U����~��Z\Wu��ܔ6=s`{vlJ��-j���%" !�"`_?��n~~�#]��ϵDЋ��W�����G(�ƺX��a�2=I��U�W��Wϐ�	�w�a�Y�(�cG��4�S�n��H��'����0�(����=���8C��8/
��b"GAZ��K1�p|NU���J㵤���M��?���p��V`���\`$|}E;���65��P���I�~ԑ2����� M��o�,|ۆt�~�iY�l�#z;�kR����|a�I��׭����%)<j��Q�9�XR����ҹS	?\'_m5韦��O!��N��2K�,�Ņw�!C34�6�y�y��F|��q
���� -P����C_��-7#nx���㳔����)/Ŀ��O;��&��>� Y\f�G�q���Ns����Q;V�m��a�<l�w:�gx:��f��[���Y��(��X�ƈ�����ăG��uݐ���q�]�i�.Hsp&"ׁ���]��c��?���3��r��x��8�4�(�	�3�쬞��7���6!~Z��x������-d�͡]�M�1QG㈉��!FχL� �����UZ�n\���T��E|9�gƭ���\�.��׹�'(~/1�������@d�Qg`KPe��YZ���0�����eu7�Ɔ0#j��xS
�j�ZZ�L��#>I�����h�{&d�d� �~,sH���R�t�<[�.Օ1�NS��<���ԁ�>Mp���'-�#���W�?�W`��������V'�Cb�3��Q��9�_tO�R�K�(�}m/�
j�1��*Q��_dބ�����a8&��1P��(x�h$n�F��O�U
f�n��dU�W��/�P�@��$k���"��<�@W�hz�ǘF��|�<�·��F.E����ḑ}t�\��{{��ء�٦v �.�T�q5>���2J��ԗ�G���
�\���R�hI�q�6_OD����k�a�=��řv�@���L;�Q�g���P���n&�6������v:)��yh������e�Q>wt%F=֠���'<�fl�F���Լ̚����;ؗ>7�|K�y��tK J���nԯ����8g)#n�RK2�}�x�ߛ���C�Y�O�>�������g�-���f��nj�O��|��"���Ա'7Yf�PbMb�?K�
6�d�6y�Z�dn�r�?[�ԉhB�!fR�������z�67�,����(Ր{�|��a��]UA	I�/{�P/�����^gV��X!Whb�3� �c�M�PU~_]/W�[K<%N]t�_/K+�����|x��[g�3�H��v���M��YL��>!����9�(m+c<��C9O���#^��cN��v41��^���9i��هjt�`x-�-��:�T�G�=����E������I�W���g ��;䭅�P�qcN�H�+��FT�#�v�&Iⲁ��3��B/l5�TO�!���涟�(U�Y�J�[�H{�M��F%T3��0[ry�"��hve8����`���`�7��,L��'�|I��^B&g�m��k,}i}]0��C��G�L0���#rB)��h�ΐ~�^��W�S���}JJ����n��^�0�u���%�b0[1�����@8��� ��c�,K����q!��G�Sm$�-TX$�g�%�z�ao�� �]���?w�/�%i�	ȇ疱|. }�����W���=�TP���[ح]g��PoX?DaF�q�0�7�b+Hl��*{	}BFrTT\Wc�Q���߼�<�w�v��NG;�f�q;k����mLn^�Բk����4Q(�t���<F~M�`"V,�``&|�iTzJ�����L���ܤ�כ�E����B��8�b��/I���<�1f[�͋�����|)�t��)���M���M��5�1�C���r1��>�����z)"d�����u$��J��pD������X*6t���*���J�J<g#��Pp� x/>�<3I$-����R�^�z�i7kK3G�ޥ��w0��'ԧo[��(.�Y�:xM]-�I"g:hp� c|�Z���eg�jt�e
�iD�s;Q]�����I",�Vk��Bp|�M�2o���� ����.�*��]�@ە;X�6@5�7��+($Gk*ĥ��f\�),ZXt����l5����(�����b3T>ڰZ�C�ͧ�g��#-�� ���thk��A��~���?%�0���C����Fu�\K�Q�c10�c'�6��2�D[:m~�1����BK�E��\wp��{��X1�!V���?�^VF��+�?I��2(f.8B�!��y@䷗l`�1�z�}C�>J!g���L�ǉJ~��W��<��1�� /|��_��Y��u�F!F�3E?wr�s�.��Dq�Q2u��;�e&�o�V��o׳],gb��.Z�ʐ�S��H�*��:�-LG�� k�8:�#Pn|}��Ϸ� f(���ϭcS�L��`�@#�4@�dr"�1'
�W��w���̌O�v.�x6�\#��[@���aCDsP�}�ə��{>�8u�b��B�/�ZQ�W�ۇ��mW��TK�uld���Xٵ�iJ�.csI	0��XZGP�
8r>��s`��K�%�φTp��E{���M�&�Ь�r�	���V��ip*jT���B��'*���C��G�fPxF�4�ю�[�&t"�-NR8w�d���ӭ��g�a�I`r�2e�`��UC�=D��֦|�`�����+�t�
y����!^���q���	����eq�3���������S��/��������M� dL*՚����r��E�s��p#����޸��V��ƪ�;���炥q�E�g���T����$�H������#w��~?��1�M�����/x�ߙ~���1�b����0|$:��n���Ki1��@�;�-.XrN��ٓ�`���B�	W�	-��I����p��ꍎ3ڥ夛�쨇��
>	��r����kv������/���<A4
Ofc��V� �f\O�2�w���
A���қe�5�g�ȏ8�8�N%�***�XO���Q"B�U?֬z�7S��t�� �k�1���~���;��� .x���0�֩�?G��ޟ�'�V&�#��H�D�k�a���Fݽ!�͍O�����t���W�XCg�e�)	g��T�ۆ���g��qfj7���2�_����Z}�q�ܹ�o�2"!�1��U��_`�������5F^zc^�1|��� &(���y�b`#.��?�m���Y#��&��x�����r]5ꯉ-J<)�])0&�?�d�Eص�l�O|J�����!G'�64
6�P)%c	鴨b�e*.�?���k���ϋ˫��w 0�^��̻6gS��]�|m�
ߨ2Re1����m�j��e���l��e�60�<�g7��O����/ۂъ ӻmN�����0��?�0u>��#(�%�-C_bfr���J�����e����t	�n��l	Y�
�F*�A�P�GV�HCE��ѧj����pl�TB���`���9�K���j���Cô��Ξ���<�u�KZ��&�d�6Ru�	Of��
�]���Ѿ�G�	��n�G��]Ŷ��9�oY4w!p��0������e&:~0�����y*�vC~�'���w�H�0/����I�C{CH(&�Y�YPN�T��Mۿ�&Lg�=[rO��얅�ލ���$\�>��Q��Cy���[���eH���*�X�e��ׇ��"{%���£��Md�� .=h�N�����G*)]@�t�� VL��FuL@�pM�FԗM����6A��¹�{�=NgLD��g�B���+��]�J�^閵��5�"x?�ԢH�D����L["C4��yhEB��Et�����k���-٭=����i�<ZbQy�"F�Ic�<�B�NU=���d�ZSYH���s�������_��2,����x�[=�|�~ۏa�*����*����	]��-!�-o.#aTα�?����w4;O9��.߽'���r�b^n�6O:#n8�R��imK)�{�+h�������$`��C�	'��N�p6P{�%��� �śfJ�W&�,���'o=�zՙ��KPg���З�W���1�
<w���\��|;xqF�����w8�ݥ�Q��O���� U"{��nuYO2�MV`S�M��g��
���=��Q�5�먪! #�L���?�#Wh;0��a���WR�xn�kV5��z�,�,2P�z�Q>�2�ȏ���/�׺_F|��h��SYm���!�N����p�S�Ne��?�$e��?h�`�c�rj��Ϋj�3�eyu��cJ�_�+�G_ƹ�|@�|ʸ�y�z���yx3�1'bO���J����d���@�Bwq�6h��/\y�ը�-���}%{P�E��p�8������̂OA޼�y�y$0�&N*���A�"e�1��oiK�KF?��8�����{,n�щ:�!�[�����ǹw �9E�O�x����Y�)5u����_�Em���n�w��q������7j��A�$(��#�B3� I���7�D�Y��V��",~��O�i ����5��T��� ��G��rW�4\:�s3����ي�.�k�TU$)F�sY��Uc�W�vg�3t�3�\m6M
H�\S�K���Sr wT�?7��?�7߳�f���2� ���=Fe
�\�7V�K�>�;o����^���Z��[���`	�x"�IяUl��YeT��>3ʫ�{��6�p���Zj�ˁ���V�z������Q/�9}�8zj��]������ʘ�m*�2?Z;����MQ���8)yt�[yPY�j#u�-��=Z�7�:_�l��>�"LpE�V�}���w2�g͊<N��p��3��x�lA=hc�_�c �~6���@�Hrs�O��юs�K��\���`�ظ��+3��R�d>�Ic�������bF7Ђ���o�^V��;�E�0]x���ѳQ컲�Q]R�C��>0����c���{��	d��d�U�V�ǚ�S⃰h���x�D_������5_#xWdg��2�C����|����'��0���nl`N�i�W�g����/�?�� i�&{�`Ss�B~{}��f$����"�?	R��=b�('�cR�-'����GQ��&�5l%���;��M� Qƃ����{�6!�ۼ< e71����H2�;>i4c���b�?�5�Ns1W�Lդ~��܊D����"��ԃI�Lo�{M҆�{�|�C���Zn&<��I͔��(x?$߇@
T�M�����'p���N��jB������]�Cq/�	OVf:H�`�4�w�E��?�Y�Z�~!�V\Nm:�8}jE`� U�Q���K���r�I�n��Q�Å���`V��,�,�NE�7���Hh��n�# R�o�6 ����,kn����R�3Hʳzn��yᫎ���&�G�y�.T����5􍳺^u���#9����2��e�GWS5�����Wͅ�xCK,k�To���D��y��tj���C�Y�{z}�R����M���0
]p/F��ZsC�CG)��Q]��2����̪ă���ux�<��#]>�:֕���Ij���0d�c)b.5O0&.V_鵰�'���X�j��S�1߁aۤ��=�?vϜ7ҝuڿ@�a)�����L V�\�Tݛ�j���wѥN7ϯ�J��4��;�������Q�b$��PO�[#�&^̂A%�RKQ��6�'ܪ�V� d�%��N�h�ͅDQ�CE�3�5E#��z����.�x\#��*��Z<gO�#�����M����T�2�C2uN���9����c35�y>uN�Ν�ħ�z��6�o�EU>�@ 72�J� 6��+�=�qi:3��]�;��7�&����fcIlY�
O�1��8)g�����	�A�1_�ǘ\�����T3q���O��t��0ްbaU{h� �h���!Z��zyU����.�w�r��&g�Sȉ-�P��䇿���-E�ج聘yUxVQ�/��
Ԃ�_~4w[E�
#`�J�6�:�!&�p�Ǒ輜@~���u�C�UkD.W�(�{v����elSl\�|�=\��|N���S ~��ʿ��?8TG�Q�x�$�[�����K��{��ۃ����A/}��s�W��uOb�a1��aಃ�,2hS`����w>H�b�FQ�qN"Ԫ�1w�o&Re�5�����ݴ'��,К�-�.Pҋ3K�:^� ��'��=Ἱ�P��a���Ft���|�a�j�������=ޝ�BG痁-U�B��L��p ��a ��j3!)t�k�Պ�N�|5V̡� �2b���$�l���.XU��,ic�5�s��n�A�-pP(�G:)�`l?܇	�ͬ�ACb;�j@�JL��"9���]j�Ia�V�Q��w�������l  ��h�R�uK�;j�*���o��g������ M��α�3����b��-l�]*v�9��w�p�j#��{<}�Gɒ/լ���$��ggZ�86����Е�aM������o,���y������_šuW�β
����Hs �� �2f���!"�mX��qsaR�(����4n{�]>@)Aر���k2n"n>����;�vټ����:��Ű�;!�E�R���#Q~��!<JV�*�W������B�0۽��7�9T�����jO�Ԉ�6w��p��3�H�%�+IG��}��,%�����C�ҽ^���9cT/�`C�(2t9/x��&U��x�LK�i��9<-��C��2Y/�6�.턩���rי�l3�}Ĝ����?H�756��[==itbpE2X�ǈ�_�Dt�=|�uqL!-�Y���������F*�RFDI�8~��Oν�L��Z�=�H��Ƭ#�\L�' �η���Eh�іjZ�i���6���Y�a?������NW�UJ�� ��O�MI�.=��<d���	0sR��U��ޜ���Z����vi p
�{���N̵�ō5��ab���jDGjWK���nHu�Eu�}ŧ��Bd���B/��r��'!�Ѐ��A�"��Ad����ʊ��bN�8���\�,��'�wF���Rq_R8�|�ΐ�@@��HA��1*�e����6�~���"t(0��:n�q�mBCG�<A��p��d��#�����I��?�J�wG�@�����E�3�xY�tq��~8�Õ���s4��!SZ>���&�1(݈����ČRU�����Xe��7��Dg��s���m���`F>H��T�w�S�I�f#�h씭n3zT/����m -3KfXWшE�-u��0��-����f�'� B%s	�s�#ߊ�6<��mq�1#$Xf^b���yi�����t��'��u��U Sf��͋�I��W�iu��&��i.e3���V�.`�M,&��,E�@��@�Wqq���s(��;����]?/!�ُ�g��uR?��T�V��
N?O9�Zv��@�R�"3j_�E`�m����Xk�u�T(/.�,��䆺5)�ŀ��5F��9ݿ���@9Ŭ�Ĥ�L�\Q�G��.fH[TX�o���	{�Z	4� ���Z�X�f#H�D�nT�U��n�T����u�`��?����E,
;���x��Z�%Y�<z0Q�hg��\��e�O�%��j�QL"�[��W �]��@b܊BȵϿ��'������W����=_�wnXp4QZ�? by�z�"��az.+9����ޣ"��<����ʤ�f�S#c9f;/�q����c��-�PR3>m�����ԳۄQ�F��B�afo"(�b6z�jH�c�	+~���}p'�v>N�.��o���,wvCNdɊl9GZ>�a���i�
L�ߘr�b](���գ����T��I<�	��yo{�����@�e��W�������!T]��V�R��KKZ��Y�
����f֖��3�>�'�6���Ṃ�p���X������M��C����S�%�q>�љ�-�������8@�g�j�=�r�����^�NE;����70�!۳Ɓ�4{zR���V�d���Je$�9a����:E�ħ3�R�d��5ɬDQ�d����s�����K-���2�p����u2���x	�<�!�<?}����((�.�$ˆ���v�����	v]F�Z����S��Yʛ����ε�Db]���uQoD�����^x���l���UpT=��i`��\�?Is-	\���EM�a@�gDA'�@܅�� ��$��t��p�P"| �����R�?	���(��4 V��({0���i�(��TL�� 9nV�(b\g�`�%����
&�nNE=�BtL+~�q�Ve����-qz�D�G�p3�i���F�6��c�a�����y�(��	o T8�@.���YrIw�����E���Mo�'��
FM%U8�-�C9k������.x�`χX.P��p6� _��֠1�����Jx��n���:�qB��r;���I���U�4jݫU�6"�(�w�C?���B���U� D5k���B���A�+�裤��d��t��;�����a�P�Y�/�}�L2�w�X���S��O�!!���R�2�ZD��2gmX�ܽE2d��RW(o�S��g	4�y��w�@'������je�_"_'t�$�!�j������������Q�#�f�X(�9I#[�ʩv����qSIOM�  ��~�\Ѝy ����� b��g�    YZ