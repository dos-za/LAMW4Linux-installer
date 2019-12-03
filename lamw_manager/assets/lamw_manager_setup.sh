#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3049676573"
MD5="dbe69b8e64fe171441d9108965c5a85f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19848"
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
	echo Compression: xz
	echo Date of packaging: Mon Dec  2 22:30:50 -03 2019
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
�7zXZ  �ִF !   �X���MF] �}��JF���.���_jgq��i�:���*).��]l/�M��	 �Acr��n>\��UE��7 ��ҙ-�H��_��y�~3]�ʛG��2d��9B忧3ɰ%�5��X�8T����gg��X�۪���T�<Y�����&[�{#f/Ԁ�&ʣ����a�#���쇼��{����X��TwqpB�$������W�v.'4��Ivе*�JA���{_�(x�i����Ϝ�l71xH<6���<�8��8��FSd
�2�T�,>bg�9�VC�:'%����D��^��P��sKk��b��N�P��ô9��R�zP��g^�ze;��up7�A�?�3� ���j��a��L΃����YK	G!��w3E4^�U���)�3��Vuc��
e���*&?�4��v��
S��%.dp��WP�T� Gr�>�<9�R�&t�>�o{�B��C�!��Z��3p_
��ھ������^�#�����-[ze}Fd=; M���;���:������$�фg"�#7%����X�WxO�_�	�\�^5J7;Z��Ь�sԃYx�NWDЮ{}h��ė��::"�����p��'c_>�P�O���� �㚐���~�Ƨ��LE��k���@���U9yjU� _B_@��ua%_�1���Fk?�fW���]�?-�-�5#���l�Y�Lu�̬'�jD��(�#�C�%x�HK&�1g�'�����ż�J��K���'��C��au�Kc��{NR[фl�0j�3Mfk��o�[�m~}h=����+�ּ�&�i��Թ������~�ޱ�x-��(굊����^���$���4���V��l����A�0�lV)U��=V��prF�˟Tl����� ���K]���plZ�L�~\�T�$��mM~MM$57��[�yW�T�w���|���1�r+�`�8����r�߷E��?�����w�'�z6�v�{P0a�q�Ͽ�i��!��spQ��
9ĽS���~tn��mw�{�*s.�lI�Ԡ��Ҭ�w�����4�ґT�	�B� ���}�B�Nwg���/'�_Vr�:@]}����xp�t�fDhe�CLG�byh�4u��=~���E�%C5G����7�ն";2���ذ�����uZ��o�\�p}���Q
=�hF�w��x͢���|I����a��~�V�u8��).�nc��2ǐb����T6B�@���r�ש�g��ޞ�,А�5�.ns֘
���%�ȗ����p�>����<�U�H�K̏M��y����	�Qq���6%W{H� ���O8���X�JLc���+�SX'Eh���m��T�},k�m����0.��S�H�mڝ��3��c���zx��������&3��j���S͵y)�>�S�K���/إf�S^HX�N���Ld��H�r��i�	�I�\�F��O�P�j�\����^�Li82P�_��-��}t�_�2\��uz؉�Q�X���\4�\�����]��6�?�)?�|��er���eB�T����H�����kǧt~����X
 ���,B���:�t� 2��6�Y�+����P
i]cn�9�{�9`ϵm��e��{��&1�M�j�4��͉F����r�[��!T��R��4��A�Y���C����~$\�wv �	p"B����7��g����,L-�;���˳~��י=�~�"���ʹȒK;O��	��,�������v-����5���IS�������U�lwd		�|ȶ�D ��*N�%�H���43�9GQl�˜g���5A�&gf���c;�m7xbӆ�g�ާ
�cq���cn�����٢<��/�Ce�p6v4ungN�5C�8ol��y�?��Im�~x�B+���g�����Ht��k�@[^���Y�>{��b֚��n��	@�Z�H���J��yc������w:2/��Q�yA�4d:�3�솾O�X5����`qT f�N����B�e��GӖIEN��b���P��B��̒$�Xy�}޺����Jv'x��8Z�'J�7+w�qGj�rё�m�	eX2��2���:�ߏ&8~�=��N����#�w<�,q�a(�ڢGx.��3�%�
mH?��MaE\�z]��4X�����u��S,��^[��I�D̶�r4�q�XJ�@��ݗ'�)��vu��K{���\����Ǚ���gE�׋�<١��i &9K�st�;��ww�@a�q�'-���(������[����t�I<�	K�r�C��SF�<2~�ύMm�H���~E�=�]��6џ�0Q'uS�9�j��ms��>6���Eq7:�lY8	��?+�.bKsx����"���^�}lid�ɬ�L�g�OΆK�ꬸ7�����2>���%BX��G<�.�j�G�N�U�zܘ&�����MI�j��"$��?��s��S�	����>��QH���]��q�k���.+w���:��:s��<���2�~�� �9��[���#~��R��qvEi�َ����`mT�=`fW�2�Q�dۭ��@w�̃��J�BՋν�w�9Ҡ�\y}�{QTf�+wQ��
����� Q�׋H�%�!�ɯeQ8^}Nq4�.�!N�M�`q?����P�MI�eC6^[&蟘>@0y�S�b�����p!�'SlkJ`{;T�--�7�F��0@ĺ�P�<���>�k��,~�����P����b���[`�ޠ¤*�m�
���d>1q�\S�f0j�\��@	WD��7ц @;�����y��4��T�3SAN9JH=yH�E	�����F1]�R�ۙ`����y�$�+��f�xWM��$��e�V�����.�l�d��Fכ�p�.GhΈ�w�)I�Q�&�ѮmL%�z�;s/"4����B����H�� ~Q\����7I,��&Zbi��-T� ��ĸ�eXA���H��ԣ�;���[�p�0�dA�eQ���=+sQ%��!�w2;8�+�F݁��$B��3H�_�������1yB��y���O}N?���361J9��MfEc{���~��_�d��s�2�{H�;�$�^|�؟FCX���F�ZO���tv�LL�R�-d� ���^�v�Ƶ���`�����)wf2 T��a�i�
'��;]��1X�hh����xH�H���ߴE��7C�<�HO�A̤D��蟍�Ĳ�t�;�!�Hq(���s'X+�(����K��4�������~cr�Cm�T.�N+ğ�-h��N/���xWP�����-�{�%yg�)׶D�WCſ�k*;�tK*�:��@�R+5wik�.��	|��#w���5H�1�g���z�߿�݂(���2F봃��:���3
0��:�5?z��u��b��?[��޵��!�N��W����e,!��,�z6�\7�Z�e�~92��YQ؆���,z:�<irM�v�)�|�A��&�����h��`�_z5�C�2¾�p��628�Ė���*�;"O��:2�FUn��ˑ��(Vכn3��?P��/�k�^7fu q�h�kq������e�o��¢����*8��Syt2��R�Z���T�*j��Bj^��42�N�ƺB爉�(A_���k��#)�Ϣ�����@5�=a赁�VK4���3MD`�F��~����8�j�5�?����4��e��ǆ��HYSOM$`{+$.�����{ӂҒ���o�B�3��E�ňDO�E�oź�
5W�<�r�ʓ[o���i�M�E�vR���{@e&b�bN��4�@��|��p��0.�*6�^��V��B7�B���/�0P�nv���T���/y�]w��2�?�b��P���f���l�N
��>��%�q��^�����hZb7 I�k��6�6���X��ZڌY������Rױ��Ho|&pjr�W�>
~�yW ��9އ#��pߞ��3
�Օ�Lp�����D���M�pp@S�>���H��=�����Hqn��0�k�T���V���Fȫ�_��8��̧�#b��<��ۥ���'43?��Yb)��'m#���*~T�y�6T\>��y0�������,>�^=|��FXn�tg�)��>Kt�3B�}��1R�%�Ȭ
Y�	|� �d�~�Y&m�c��_�,&�̌ݬj����gA�ż��2?ֵK� �\S�@�X��8e���������>�H���w�{���/QUs	D�2l"1�_Έ^$a�>��\�>�6��{�x��o�O�"�.�� ��s���a�*�W���d��ܻi��_CH�'q�[<E@Q��Hu�	���6�AS���5���.y���	�4.`*�{�]�_%�yLN�+N��F��bb�g�mxg��]�	��G{_"6��5�c��o�"��R���{%�4Y��;��:z�=�T�b1D��)�y�@ݦ�V�C��iTe�2ި�qF�.���-mƥ��+ÿ�S�������P!�>���$���l|��B�a��I�-`,�ݥ2���ì��bHy��$�^�߾sK ��[�Pop�)u�F\��Td^7����z��GT��1"����)���ֹs��y�k��&�
r<Ĩ�|��N�J�{��e�2f�b�m#�
W���W:�HɆF��4Y �y_��~R�'-����<�Ӎ݉$f�zN��?��Q�LJ[%�h�`����J1��K.��\)�p���i9X{hQ�~�f�ޘ�+���k� �y(�2a���ʷӇ�~o{�Ѥ��[<�-�ڳ���6nbX�����w��}�_�o�7��M�J��(�A�ժ��ҟ���`֨�)�� ���W�c��>��'�6���6dm�����3{r�a�Ik�X&�;<6O��h�v��ҵ�*�ܩ,����N��
�(�%��5�7�&�9�~篟q�e޽N�F�Y���J��s�����b�#�YC"~��L(I����t���k0r?��v���c^E)C>�ڎ����#��J��)��唝'X����w��]�)�eA�J�}K�/��)~���R` �̳�wKC����Q R3�$������jYX��:V��
@|� ��&�aUjpõ�1s�a�v�π�^](���(Zn�	<���/ڰ�F&��>��{�AT�d��c�� �}�{\N���V����%�D��Ϳ��0H�0n�J���f$��d��g�G�f�)���=p�������W�������_�G���̓�.˥_�Cmվ�P�c�K���Jս�,�s��g����Q��\q�v�B�30��\rO6��aOF��H��w�oZ��ru�#�hu����ʥ�U)���{$�Q˘镴-y���
���&⡪R�"�9I��Аa���2�=
�Ɯ�w�ԣE1]�E��2D�B\0��_�akJ!�)蔴:�׷��-�f��^1��9��>�,2R������1�����`�m�φ�|���~L�X�x�V���$�'z�25�����ь�u����:�p�=��e_!���!��<)� &��b�{j�/<���c_�'�4���v ��6���j�+1윦�o�޲M�j��Ϡ @P�o���a~�х�P�!�k�똑�C_�d���<J���'�t�ַ�Q}�V��u�(�lpT�� ڝ��z)�߻��{ i���\8�v&��B�oB$/Ö��I�/C�O����Hr�L/.F�L��`Pe;�`l�;�qCrN�*,9��/��Dr�K"�F�t��1QԼ�E'�Y�:vjJ�9H���+!�_��+Xr,6��:����T��eZ\'��+'ʄ���(2i�h�TBk���u���:(O������h��P��e�S=�1{��Rx���w��$Wfi�Ltu�+[����������R룄׎�?����b>���������6�q���C��r�����e�I&L�Q^������mܸP�$�4{u =(�6��
�x��0�,��!�)��.U��k�.�V�.�>Ǥ��#�axv���k3+xds���&=@�A_9���D�+�/S-�%��4����οv-�M���sa�^�C�竾��C��C�'R�ӎ��^}�$8A59�է�14���o���OѢ�+8W�6�D�'��cvTw���s�e�.Ո����������x�V�"�qВW�F�Gl���+�i$!��Q՜7���M��n��A��ީ�U_�r��g3�u�����uEԛݹ�t��)y�е7���X \Y �e�3!o�Y3O.#{|sD4�������>klW��G�)�]�-Qbd�
$8��9W��'�:�#}�r��5�G��G���a�m�Q��|��W�y{9FA/����UE�W�W��-�3&�ٺ�Tor���S��k�ˋ֝���-�Ӣ|�w.;_�M5��@�X�Di5e� ��&�\��G�CF��b[��n��D�E�O��D��t�cT�D�?�m�(��V��q�/.J6��?��R- �k��kb�Ws�s !�ۗ��NeHB�p�F����*S���'ے~<ݍ?b<�Y)�5;�Z���|�WV���دK���7���ǡczA��S���O�TP{lJntW��d��P}���m���1�oo�O�n����B�Q
<���9r#���e�nj\�6�ׄ3fΓ8��Q�'�p��"���w�����s�2;��*��>� �l�y�kH����ر�&o$�+�E�i��bL5l��̈́����y�uC��m���\�vcTQ�~e�ڮٴ1D�]J���7�41D�h�Q����DU�s�,8�44�du|�}��;�&��eq@(Z�!��$��~:A�۟��}���t5�+d�֢�x�_�0w�	:7���p�xJ��7���X`��G1�sR[�UOq�ʟ>�����y�"8*Ҽ��;�C�E�E�<��E���rpzC��E.��:����¢ 4�����B4�a�G��DX�� :>6�cڈ��E*�6��i���|�a,��li��a���E�L�i�-9�kS��������[�ۡ8��h�L�2R��0x�s�l���L��D�3lČ��~����0��{����/��}`��Aep$ZB�Bu�FYU/����Tں���
�ӭ5 xm'��Է��F��q�C#wJ@�
g����Z���f"��C;(���I���Ր0����E�S,����%�tr_ �I4�s��X�g ��A&#��l� �i(��X��rAe�16&�?!:\%y�I�/�<������_��;:^�8��s�3��*ē��l��r�(-�W���J�`zlb3���¸�Uz�[7mg��M�mm�.���p�NH��	�{�*��K~d�W7�Uz�B�������A�Dz`)��]2�飩�*���fs1b��-'�5
��ew/��~|�O�Ć���f�9NФ�uMi����b�hI��!S��@�ٖ��ܤj(��%�9Q���n��1/��ͫͲ?�U�T��No��8r�⤟��s$�g���R	S�{�\��t��O�.�(=�Ej��1B���������[`S%*�� �F�����=N��W=����9W�Nk��~>&Ө;"0Bw�^������'��_��o�n����mF�9��8��d��}��!�ay|d$\�����ّ�0H��my*�~Q�d�l�y�����B�C��¬p�X�Z|�D�����
MׂM��>}>�~�Y�h���o��RW�ɲ�`ǳ�t�{]ϙ1�w*͕$T��hp���5��y��(��H+zugg{�y�s�b[��LQ�od2D���=�|5�\�5:�̬���ݵ4%��	1�����w��<y���a�|S���jh�E{������*/�\_��jhm�5|���fez�ۗ2���5��?�̅.{Z{�����|;��`�����@Y'P¤T>�\0U�)��r>�X\ c8N��=p�^�����L��p��O)j,7�'f��e=����!��z\�?�:̃����1"yO�P�N:�܂$Lh�CѲi�r���#2��k�Gb���Y�;;��L���_��cF��=����D�ӈ���Щn�>�����6���^Җ8p-�|�(<�e����� �y3h�Cu"�i��T�]`tA���b��W�6h�6�߁i�o��r��:��^���Qg1S��� ��g�1�}�� n�?Tq�qC�a9],~R����+�Ӟ`r.ލ��Y��n�):��+A�#O6�]��s�WG�|c�!����s��U��Zd;�y�O�`�b~���}iEz3��m
L�9���	
��~����ǘ��1��Hw�'�%�kR"i�n#i5�X�3��%����)/m:<�^������e��d�W�W�[��eu夭��v&CvY��G+z9/;~hq0��I�j�t�y�J4*~2$��(��V#L<�4Gr��
��]�Uh����'��1��q����Z��;؆�!e��vJ��KcH�������AMv�wnL��	�!�C乫��Ôuq��_Q��K��(������<pM�}͐����3�O%���b�c��b6��
�5=�Z��sk�� ƤW��-�M�İ�r�U��kB��|����7c���ʏPBhKC�#� ���ǘ%���w��A;��~߲/#�L��G3����DTC0�|��r��/
��
���jzW3C�)=�6��%U��>:��I\u�k��ԯ\�G�Ж���Aa<��^R�UG�& [���<��8��l�&.~��.�
��-$a��0��Pf�Dص�[��<͕�f"|���U�H �1T+���\=�LT�p�Ǫùe�~����1��d`)���c� 	�{���p4lB���{���%���ΟFw�Z�?���H7�f�^^.G�9,h^t����Z�]�Y<�^;ּa�o���I!���]1{�2B���k����0��o9�b�TtB�j��o9�$��ΡPQb��t�3�.�"��R�T�l�0�
�\�d._Ha��HɅ/,t���!��Ї����`���b�(��T��L�
J'�1����<�0��]���·��;ۘidq��lfv�7]**���CL?������Ǽ����{�2c�@^�	V4��3��(R�`����'[�kgI��τ o��-5ΡQ0	���װe���LF�A���f{[��1�9~ƭf�ԇA��|a��+e��=S�iI�='���le��8�^�/b��F	?e���c	��<�mm�i��_��r?�[�N�9���r_<��
��b`_���fdȋ�<�����wl0g�s�^�(=/C�-�C��,z.놶�S�����=�H�Pњ s���挾a"mCt���8b[�?�i߂-&��"HqM�F�1�'�:�1�D�Rq���<;��˹�e�z��6�b�����L~/�?7�д���Z,PL�?$�3#��m��}����Ŵ��rNu����T��1��Z�G��g�nJ�G F6�a�.�I�x���55 PPn���k��W��F�����Sp
Z��s���Xl���o�Q�*�U����1��s[�`�p%"=~/��:��@m]o��X� $�9����+�1��D�+@���xc���B�j�qWa��#��߾^}_�l���κI+軕4��UB�>��s���m�)dʩHr�Ն��������q�J�gW�����/��$��42}�����1��~��R���|�����1I�¶`�btVp�YD��_g�S�K5ӸT��U,\Cq?�g���"S�s��L�{:w���u���q<����,!� 0��-.�T2�zAX51���� 
�2����<����0�-P�
sD'ԛe*8�������>��HI��rp,3�4#�����Xŉ���b��,=�~�V�!��[VX���	��',���r{U\b����C�Y��#*nq�4�cgY��}�CӖV��?]>qԜ©KѶ�1l�o	a�e��q��r�4��>m'�[��`jP�_�4#�Ǔ|a"�m/26�p �3#<��k��Q�vN���vK11`��ڲVx%3P�����S9DK�S�<�o����l3f��ۡ*%95��`��ٳ��F3�B��v�?�ܟ����`7�������l6�!�&M�G+&�݅}|r���XU-}�v�+,3&�Oԉ�	-bH̞���8iv�l�.�"N"Ø;�7���� 1�s�ST�0���a��8�l���DT��m�2�'����Ioo2i葖|?�|l�M��Q���s�79f�vD�Ɇf�Y+���lN�;z��f�f��q5��2q�-�?9��!�L~|��dXT��x����+��yLt���IE�!�k�g��J�}�(��?vP�h
��r����*R��`d3	؄h���}��x�\�|�0��s������^����6iWZ.k;�eQ��}S1�����=����*~�p)���-$O�;����I�E�Q�Q9��;�����d�R�d����5E�z��V��.\O���E�fͻ5�D�v���i�����4����}#o鋾G��zT?�F��j-�{Bv�{BvA�k�X����~���RWd�n0]3Շ��~�r�u�!"ee�a���M|��'kbF(Ʉ�]D�qLC���u2�Ӆ� �򅶱L�'�T2��m�YF��n�OHp�	�'�A��� k����i������7�YLq�0G�۵{N���EmL3Tg���cI����!-<���=�7�A�+�����d�;�0Kf`��=��cz ~�	�=�m��S����&��V�`Af��MJ��������)�GI�He!~��6^ܮf�;�@^�~���w	�
��f��:��Bǘ<�VP��	Wr�!�N��Oh�_�n2���F��$�Ke�e��}s\r�Dk�im;�N�Bajތ�`�I�rÈM���D3)�e��ܯ�4����8�Cd��,��h�P:D�I\��� �{3�
�.,�Z����Z�?1�u/E�����X5�Z���lCp��ͫt�����C���Nʌ�<k��㶄}���.���v��H�~BF�.6A�}%���>��S�9���;ZҎ��y?dj;�I�偫׮���Dt\� y�i��h��P#ДW�G�(,���nK�����~�[l�F���6���Dm��V�Mp�+D.2�sȀ�Z�kJ��:Ւ=g���`�ƓX������RЙ��%�~�A@`��L�Ԕ�e��>��T^6��Ha�Q	�:%��� );��M�l���fy��^{����Z���r��C�A	�7�f��$)H��P�	��q��ͺ��v���?v���G4Y�ㅐ*�s49���%�rw��Q3�<~���Z�7h$�[x��C�Z�g�� 6'~���/�LF�[��Ƙ�ov>yGZ���-�:�;\��s��B�
����i)T��Fj�����oў�̧�����R�$/���~�1�TgM�����.\+��B�a%�w)��8�N�P����7 ��H��r3�^-wSx�BK3�����v[
wZ?Ni|���$s��b|����@0���8��X���'����p��Ү*R����H�&�4�}�&�D��+�/-�V�R$3L��`��a�>�|�O � g��e��m+R��Q�W�<��o&�0�'�E%R-�\8��\�v�X�xl����>�]�އ a�j�d��?��=��]D�Bw0��l˔�a��=h�5jx��� ��[�  ���A��m��F��\��a2�Sϓ F]�;E�-�D���y��5|)M�ŕ��݃D��RSܲ�I1�n����l�`pR�����M|�������G�Jp,A������6���U#�˳����V� ��b�]����y$?ƃ�\�n�r������V~(g�u<	s�&�:3O��qs�~ M�C��ܘ(��J�e%G홰���6(-�L�88*g;�ိ�%;�?���E�
.s��4�I�)l�a��,>T���"�!|��<�OR�ujm� 5Az�l��ɿ~���IR��bժ�y,��AxyW��|��ǾP��F�?`�#�΃��L��+#L�~���1	{�}3��HT"�:�4�2���BA����u��6�o:��g��,��
�߷��HK"ˎG�����ÿ�El�a�}�b�!�h�Ʋ;P��Bj2!��J��"=�	���{.�a`�������0�C-�r�6ul�ر ���X�qT;e�"�������8N��U�SQp^@a1Ji�xc�ڎAk��M����x�8uK.���<��h��E�xܞM�{�]_-��y_�[�Q�oc�o�U�}�7����g���S�A�t��Z����J�"A���i��  84��f�L��Ee��u� \8�0�<��ٷ��JGO�}!�j�(��X������ϴWI�21��ӄ�aL���=��P-�ˠ�f==Q\@��,S=8�-�.���������
��Lr��GH�)��ds-��8 ������n�����Z��ct�H����U��ݽ�e��3��2��k_��� k��S'$��C�j�=):­�a�W�H��8_�=�+@�
�^2����-.7��zt|�>X�x#�%��?T�p�k�,S"�0*���[1��L~%�n�k����%�T��Y�<l��kc&ݍ�Ҏd7�v*�� �����"�n�@G��
P�b6�s^b��Re�>	�m� �����ŉG�B�*(��>��rQ'�=7�ɉQ[�8���
Z4�����r�Y�*�=��.d 6�*�*[������h�����Q�M�"���	�⧚u�]	G����g��X;���ku=9��L/&��l�x͝�����^��Q��Ix�X'�vo0ޡ�� b�m$�(�D�0>c�	w�Kf�Q����+F���]	��3�*T�(�M"l���m��|(s�W����g_�$���1�%:D�2/�γ�;��ڗb�D�:���VBZb������6��o����X��}�����J��Ly�-xfiyS`f0UeL#��ʌ��w��<Q��������܋S��W��ؖg�����ݣS�u�X�ݜ찱�tS�f)��)���x�͹p�6&�9%e�S��o� �ɖJ��l�npJ�,gJ��C. &���0��z�͛����m*/"��+H�=cRK�7YS����������J���*h� �S4dS�A��T�����/��]���6~�*\&�)O[�rȘ|����bU5�q;�������D6%������]ao���e6�͛W80ŀ�5��JnV�4�z�aMx�5���Ҷ�g�U��u�~��P����3��������C��U� ��)����9$�"����/ �!�3�>����]�������1�à���3��
�*)T<œv����{(WZ(
���|aPo:�d[�N�4�������ঃ�`)�4iK��"v|�����2�����Z���+a�����妿��Lz��P������lA�B�F���ҡ��֡�j�������=��"^�Hj�
�s��wvuX�������$~�PG�3C�����٣�̈́��;f�
�(�����A�_�Ż
4�y�贐�a�wr�Íq�gӟ��Q�J��!>9��/[]��GQ�îy��oG6�K��K��C����e\5���f��'_A%q�����{�[�
0Jc^�Q��ȧS"���-�p�l�������~�қw0�,j�%2)�<��#��Eu���>o�ݠ����cFw�F`Z�4��/��0�K�Fͳ�ҷ�N��-���E����n�1og0�2�lo����t^�X���G���Nr ��و����(Zu#�����9�� �Q>�폆�Ź*pH���r�NW�9��˿gEo]wހ����}	?zqр�3��?���:�k5��BS/��y������4���_΄ܻ�Lٲ@�Md�i��n#� %�~�$��a���m=�n�3�x	�^����v&=y?yG���`:�r��.��l�>��a�v�`/�-���d	���.�و7$�rE!p���^2-87�[ka,Y-��`ׯ#��d���P(��i�f'��"1���1��x�ݝA	�m��dU�%�cw�
S���Q�̔��Ǖ���\���.�5fƗ1�諿I�<:r����MN+��YW��B���e������v��G�g�Ԃw��->�DTUL�ڈ��LV��r�NY�P�ږT��<#�j-Z�r��ǭ�nS�Δ���k�wn担��V�z�\`@Uh�h߿Cd)��NuN�9Ub��Ѷ�eN<j���H󑀳c1q=X?��^�*��i��w$t�� Þ7w�@&E�%t���Ђ��m�뮠�m�l	�A�e�q�q�����a��*V� �C
s�"
�h��7¡BAOڴ?�(�k(�=���3�q򍻌��H>eZ�W�3u�9��fx�/ �p�‚l�+`��D��8ȩ��Q�%PҀ�S��-��̼���"���8� ����p �@ �&���_��"��
(��%H7]b���e��n����곝��:����|�0ND�ok�r#�[�}�8��6ޞ����m�0Ze��|��{�[�wX��N��v���G�����E8D��(U�ڹkvq݋Za��klE����� �]ݺD .|W�ӕ�w��)P���Fs\�G4?I���x#��a�S��ՎH�
]p\���y��蘙�5S�ϩ��	Ro�^|_������S��B*6䙼쪇���yE�(��g�<���H�Lv������˘D�6��b�@H2�	l���+<��׹�M����'��R��i4�@5'|��i�Q�-�����Ւ3��p*)]�ʇ� LRm�(P�ꥪ=�������C���kXN��Xz�j�6�F�l@���燱������R���P(��s o�|��K$��P�*�<���v�A�[.N�/�G��!0^?ey��o�R-��}]�Q�e�fɎ/�8�~@�>+lj���Ph���.H���x�B�Dӆx-q0Wq����Z���st]K�����E�W��9_��Y��rT_�͋w�'�͸B�u��{L�c5�f����ɷ�}���l�֢l$���4q�}� @9⮅��u�8����ݬ�0����&f��3�U��|���_q,��zl�б��Z�K�eh&�u��Dd��
��[�'��x6��G��tn�<��k^O�(a�Wݱ�F����.WNYL��k�3, ��*b=�@�*��g~���+��C$+ܪ��(;�}�HK��f��� ��Į��{H?<�J��8gT�]`u���_���w�ԩ����Y�F��S��׭��u�2��\8ĉC����B������]�L��Q�����{��%���崏���^��a�<y =JǴ�m6���s�[�����ˣg�In�Ԃ��命��	"G����̴j8�+���/�"\��ܑ��vR��x�T���9� `����4��lv���|��#���)�.|�
�|16n�2���H�D��>�Ɓ$��P��f�W��4'��-`;�J�OA�^O����#l/��L��'v����>�дU�?��%�s@���p���mLO\�h�������d��	��� ��F�Y�	]plV6@�N���+EQ��,�ֱp vl#�Ұ�f	�
G)5�<(�d��H8kUgI�M�����%���{���/��E�t��%��eq���fc]�\��C��5@��*IBZ"�K>�&���1���/,2�PJؙd��+GB��4�(�,�� �p�]N&VkR�1A�ُ�챁'a��ZN\_Q�a���B�vd9OC������xvܐ��h~�0@օ��1����%J�^�F�(�TVװ�e���[�Č1'�}o�f�;ox(��£�K|�����踵����̺��LE���$��`��k�W�{�
�>�L�Td�>���*�_`��D]o�K?������t�%B\7A��ծ���d��1��P�Y��b
��C4��|sF	Ѹ%1w�[Z�(F�L c4��S�pm?Wa�F��p����50Щ�z=����_��>�h��g���-߳���tc�#��^�\ı5ʫ���
1���MՐ���l}�J�|���z6j2-C��b�4��`;7(O_ ��S>�)�'���8HT�U����'���(�6Jf8#K	r����Ďh���r�IT2wX����*锬	ހ�J�d��.��T�O�%n�Us�H�gbN$���}���(Ē�f�\J�%Lg��ǔԜ=�S"�3��`��g�������S�@pK5xAy:TNIqs�=�rd�\�"O��HW�;�U���S�������>�*�'��)������y'Jl}��-c�:�N-����>�t��x1��*�p��#���9�(E�M� y r���E�G����๫�x*l���?|lݳ�H�����nYu q���=`�Ĥ�}Y�5��	_L׷m��-E�|;�_X_�Ły�_Oh�ʵ�o��!$.�|�e߼�o����B��$��frk�+�����ax�h ��uj�䫆db���5S�k�g��ѓH>IQ�35`����nK��D8ұ������Y����b�OF-��R�;�ľ[��PE�4�lg;�vFeYV�������0�xz:/'�_P� Ϭs��E����`��s�_��j�]cN N`~�q�M8`3y'w��
��}�a��Z�����ur�q����L�Z��
�����}��n��h��=�5��=b �"8M©d̀2�5H'=<$͢r�?ȃ@&�$Aӟ�Aq�X. ��:�It��@s�{�~����;SaaW��sa'P{X�^M|ѕF�7%�>�]��P2�����O2A��9�����yÍh4g��b�(51��d	�W`󈳋Ny2���J�nE�F9�8Af�b��t�t��]����f*V��o� 4�Ϋ{��d &��(��+��fE�zomH/�@Me�C"��,�=�v(��%)3m0ô.L%�<����ݐ$�J�=�V�����RL*�T�zR^j ۹ �OUn����z=�v��\|��1-k&H�A��U�D����oŰe�#�E&`W����#��z;A�[(8ԅ��U9`���U\K�*BR��k2��X�[ű��4rS��-m�&�Ew��F�s�rQ~XYk:�%�&���^!�ix}$|տ�H�M���P�3�� �$/Wf�ϡ�t��~�i[�j囋��x؛���53��L�E���ˎ���c��`̐�Tעm�)ĐU2����i�n�l������k7������x] %a[�U9�Tt��4Q���|T4O*�ץ�x��o������Cp�ꅯ�@~��VR���+-X�UD-ԯ%7eR O����Er�M!�؁�����s(0b����ΐ5�Z^d�N��+�ܻ�}�1D��L��D�~�����Ev3m �y�r��g$&�A��b��LJȅꫣ���7��݁5I�t<��M�~���2G��Y�w�L��˴�)�������	D�W=�:&)"Ey��5Z�{1x�	�7�iW;R/�!D-KA_�E>6�4���,�w�� ���E�}b.$o��\�J��"K�0aNN1$ar�\��vqn�� |���?�t)=�T����n�$�J��cn�,�a���Z�]�u�>������U;`�GM�31{���Ip��6GO�?�4�n5[/�J��j��g`���1:�_ex���-=�̻����^�=��WJ��lh�7�W="�C+�*�^ȡ�[U����+�w:-��Ɨz���l���_ a?�[O��ܱ�ޗ�c"���0����^aw���������P�Eh{=���D�������
"���њ�](�rwH�2 �Ӆ����?�c�&���W�5ѿL�S�b��z. Z��?U���m%xD\�Cz�C�~��\X�=�+N��k"1,�\��bW�b	�#fN�ձ�	?@,FTZ�*�^�:� A�탣b��$������K߫����
/ʤ��`��[�?_^�ٰ ��Ht�ަ~u0t,G�������->��G?�����Y/�{��#rU� ��(�[�<���}���Zf��LR���'��R�*�m#}q:ہÅ����D�,�3��l-N�I@$D/0�L. �.(�v�X��[x�?@��]2�/� �Ȅ{���V�P�-�#!�Ъ��ķ�;���S��N_�h�d��K���(�/<T��4����J��j�}�n-k��	��Ӕ�c�e��I��؄3䢭$y���}�3C�l��'8q��k�l�i��U�q�5��M�1ϵ*M���0�,ag�ʶh_�֧�қ0]�8�&2��nqa��c�WC������=�1�05��}�2���1�vJ��5�H�;�4�;Ԃ^#��\\�]�{����k�{n3K�!A�(� Յ�H�m&HO@x��l����?�y��Zx��=�k���AJ4J+��?7�Ǧ1`���,aX��@bzDa�wו�Men�u�oE*��������ta�Np�s��(�6����\>F���C�@��x)��=��y
D��@��������+hp#Y&<�����P��Ra�����b�C`��"����"���h�R��l��Z�2���Am�vmE�/�t�"��������� �n?���eL?/.uRh�H��t�ٛ��F��^�!� Y*�u�KxU6��=���o�NY���pN���r/�-�ߋ�ag�'����YUp�����h�?Qgh~/�$;#������5�#�Iu�,(������y2�����6Hs��N�g�1k��m���`bܒ������"4�|K�{�dx�LwP�glG�?"9�$/0XSX��TO��/��؂ �� R��_�Ȯ�xa�蚆�N�|D�����r���DV�P\/O0<}�Sx��c�����d=����g��V��#a�ӑ��#T����a�zw��Re<���i�v@�d&����F�Fso���L���g6!��5��T�D9M�ft�5�_���h����W_��V�J���GvN&���&\Y�Y�����b�����s�� ����F8���R:r������R�QW�'Y�r��I�)@�!˱	�J���$v��αWH����|s�{Hw�4�_��r���y�%����9�QS�o�5��A�(r�[(�~���G&�T�(ٵD�S�k�����S2���y�\,p��M�m�������Zc%K7�q!hʠ|;�c*ׇ����,pn   h������ ����4���g�    YZ