#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="955346651"
MD5="1ba4aa4808be8e6efdaf537cb57d112d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23336"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Wed Jul 28 16:15:45 -03 2021
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D���&�5�W����g�C`��E���u v�&��_Y�H��skDDb�FF#��d�/$��S�|���|w{36Ч�a�o�;i�c,t7t^:-��
�B@ذ�w	���1���b�I�C�s�X�DR#�8���E���〿��&;��7W=	�ų#�q�����3�VG�4Tk[�~Y��&,KNPs=�pMG\���$�L�E�����*� {�E�O�c�����Ë�G��7�s�=��B1�g6�����7�검��G���k{gf��6��l`��(�.6G
Eb�.J��9���[���bP����̅8���6A�Ç��V���*����S���tyQg�[���)����m�D�����۾��WAM�*�F!v��O�� fpo����=�<Z��'�.���<�L@{�Ju��P)�uf�e�=���X$�Rf��Ei0`Џ�ۛb�($ܠ�e�:�Wl�tz%�h��AzUj�"�@���Ee� ���i��ԥ��h�X	�+5��� �;�*;�H����8���ٲ��Mti?+�"�0��0O_����a���()qde�R�g6�{��
�"�t��!t(�i�s5/�&���e�Ya)O�B��m*mm��"R9 ���AF5O�=��w$�1�݄�W3/�j��X�5�*X�2�Fɾl�S=�55~ߜR�)�Ki�p�;�U[v��l!�1'�l*HC���_�h��y���o����DYv�C�V�x��H��O�}�:��%�<����R�Zӿ���tgs��wq�4C�LX��������@d5�Y�;�"�S4%_�����x8�A�h]�'��,s����pPUFL�Y�(��ϕ�FZG��J�e��+a2_�cl����mF�E$���9�hQd�Yf������+ʫ�LE�3�P��2���
�m��T��۩��<�j+��{�}��7�^F����+]��N��nH�Z:jL�/L�!6d��%�mX�R�2����A�~nu7U�/��.{�ES3�+l�2鉀 �=��Ȼ�����[ ���S�]��X�E�FJ��4:��c�W
㿰��.=BX����(:O攴q�8C�9hԶ�`�z���,�[Izyu��+��W\@6tؗ��/�ma}HU$օ5���I
���: ,��W�� �dJa8k�K1֦�&,�.�)OT�܁l�g��X���=	�_�o�V#r��Z]C"f4�����yw�c��Y�����N��c]f��v��AXw�WM��V5Jk�d���	���F��8!.&1�R'���p���;��؋R,���&�8���0�x��0�X %yp|J>4�I���c�ԁhdqB��w�^.1{�}_8�"���{���y���{z2�>y��3�)\Aaӧ�Hg��o�lB�t4ރ/I�=���כ��|Ү'F�4��cE�a�1%��.�kά�jnS�0���,	T�vNP�5ឹ<;z������|�t\"sg�a��Ӹ)^Ԫ	pЁ񯄡��g��ۺ둏�#s2����-܊��[t���2Jh�I@Xյ��7
�Za�Q����w9r:������*� ��� }j�����!�*;�5�!%��4"-.�ES��I���#�ƧR�MS���U�˹�-�X$�{-2����������2bz1.��p����5��M��H��q���rj4$�cCy���d�ܞ����y/��\l�]�{�A��o�������x<�M���S�T��ɮ)��է��j�mt�%�E3��xI�H0+ꈈ�9\���M��lL�V+{m~�����ٓh'1�.����.��"�C��$s�G�by��̿z��#�		������ըH0�Ep�h�)
i���,'�N�{�=`��iٶ{���mD�$	Ѳ����BR$Y�i|�&�t�����[�H
�����g�����k1ҭA������
N��MZzQ[NH�dʤ;j�@�biHO ^�"�I8B(c�(�(&�{FR�/\I2?�O2���fO��X�����m�$I1j���2�����{���ؙ���FK��q�d����8����v�R���0�RJr+C��7x��6�Z��!?q���G��c��F�c����	.��9ͳ�w�&��PA5+4�
zK �{���vl� ��Y�r�X�U6iƖ~O1��w=�� щ��"z�L�l��c|{�b�ߋo�H��P���E�� h�#3�Iݖ	����J��;��O�O�ZF�QӞ��H���2�W�luR8�F�����O���k�wǷ�
��@x��i�M���;�2ˇ�{c݄gWZ�[=z�ⅵk"X@�̻JYH�9L�Rȅ�u��aX1s4gn@�֤��������?���U����͹��M��k1�S�U
��|�]�jfE��t�y�U�0|lK�͏s
���{���9�r]�z�����J��btn +�+0l�q{��,���A7T���m�+n�Τ��`0O���]�Uf�����!b����=�p�Җ�(`��`GcrƢ?0i�V��X^��sM�̬��I�3ډ�.�z�5�%�H.h.�ʒ���;$��J�`����fK�>����^	�����~le�����ۯ:X�~��.<����5�JT!?w�%d�ǐ:��,�|�,B�64�߱i���!�Ό��O+[���7K���$�RNR�T��bCį }vU�5<��N$2��+,~.��:ܵ�J��|6V��i��M���Ju��T��C�C����6XS �"�|�ј��[�f+⌟���u�ͥ/V�`d�! a��m��)"��b�_�5���%����ا�w툗�_9�Czv�u�YK��Q0pB%+n�V%�jD�x�*�kL'��ۮ�CR>��,x�P�<��r
���~2�@G ۺh{D�u�;�Z���s���E{����V�=��/ڵ<���o��p/]��f�i9��'�}_)��&oT��;/✸��H�Ә�����9^O�j|�X?^�r7j�&?��t��}%Vn�ҟ�I<fn#�X�M]�6ʬ8���{߼+�.3��
e��L�;iU���W�2V�������	���ϕ�rI��}�Z�X��f�g�{]Ơ���0
X\������{D��6�4�5��J̱�n��x��4Û2.9Kÿ(��j�8#fo���Y�ͦ#�/G�/Fj'��-��W�b��;��}����CuI�J��nL���1z;���:\��W�
��&�ʉ��Bư[�R��PD����:�Q�O�Әy����N󻁌NS��aZ��2�P�B��O���Ԋ7M-XPL}r��r�t��b�[e�"r��8Ŷ���8�(�IPO�r�mz�C��̀z	�u(w]\�; �����y |"��%����!OsN�r��$��K:��'�ֳkL�(u=,�?`;@ah�@YKoY�[�us��x�Rnr���$���ե�ޛ%��C�ƲV��o�V}7m��F�7�t=�b����%6�iư>��f���	ۮ>0���|��n��sn��Y<��f"bυ��EѿT"�X�,�������va�3�Z���m�
Z�T�������?�T63�$e�,��aC�Ъ�Jt�9�����	pI/u\�F
����'.qL�ʟ��j�|��>?�l(_�����jt�
ry��&�#K����/`�s�&�������!+�I�)zz>�5	��ĕ[�s�_�n_��9f*�� �p��d���ŶF�@�,)�+ �7]m%h'��L8'(M�F:�7�aCz�c�>T���³l���9�}1:� r����!K���;x�=ǉ��L����q!���vJSTẍ��g�FK�3�y�5u&��10��-�n8���.��d;�i�L���V�ըzõ-���,m�>�D�JXx�V,����W��~�P�H�F��IY,���*&�W�{Y�����0��-A���D`ل�XM���Q��> BH�@srȚ;��֪�:�(��$JR�[��%\�&��������	7d&�/3ǻt���ͧ�܉U0��r��du@��u�pW��~綵wA�l�y�`��Yl�%���lp�bc��	"���*&?�9B`����\<�� Ú�������}�f�� �<���%ރ:@�3;;���جf��r���]΍L���]��^~/y*����RX��[�i0hHb�V�����x�w��(
&Vvw�Sv%�96��������om�F���js_��ɶ�q%
�۸�)�1x��� ��^G],3Q_��F,~H`Vo�r{1���#����{��_��8��d�5	];���K��e�����y��q�0�p�v��N�����JF��c�J������t&��G|����g�����y�ܸ��J�kЪ�b�'��zf*�v��5�BP'Q��~t��L�|� ޚp��!W��>]�KQو�,��WEPl�VO�z>F*�����ĕ��s�z��K��GB�]�WG^~pJ��*!l�m��J������@t=���(B�2l�`��;Q�MR{,\
��5%z'����_W��c�\M��U����D�������8�Rw^�E�U�[��x���rr��Y<��1%�CDi�8ͪ��|�e=m	?kq���,3���az�i�b�d��~��c*B�v�{j��U���5tĆ���!6��a��X�x��B���t�UΞ�ƭƿ%�z�;bt���W��Q�_��-:��T�¦�r�AH� F�g���[{ʅX����X�Z]��ˁ�GA(�bg�7p�k�K)�(�47\؋ �>�b���_2
�.�ǅ6[���,�,f�=�?��AQ��^�}A�=8n�"��} ����%��%nI(Mr�"��wO����eڂe��9�}Tދ�8i-���^��Ltj����T�{��fM�U�C׊��":�V��IU�N֞�p�'[����7��g����/��0��S�M����{�=���X"_ �����!�0�~h�k٤ҡZ��K��������W�,6.u��"�ϋ��Tf������5vW��m���w'�������a�}*q�8�����9x��ޘq)��:��Fb�ݳ�nq!31�S����#2���.�eP�a��WZ�??�-h�l���@*�Аw�q,-�VI��Vj�P	_D�"�s��>g��O*�Eh(n�K��Ux��Y�2Y]n ���/��WH�>3�/3�l�s>~l�����޷�ZRs�D����	�����kN/}&��ɂS�'r�^�C�8��Í<����e���<��)°�����T�F%�H�Z!m"U6iH��vZ��Z�Oo\�g�5��-J|2��R%��(fB0����|���,y[���N'�DY	�! 6�qe��fq%nb�o�DP�MKg	hђ�o0(�Ap9S?��S"�ɠ{տ����x@���o��U/
hT��>�Q��hW8Gk�~.	�#���5�/z��G������69�Ap��c�uV���D	?�~n�Tan���UHgI z�cO>�nz�|��0K���g|�-��R��E�bJ��$��؍)p>��fY����T4�\ච��m�R���.U	��,�sY5���t�!�����j��O��J��Ӡ�l�!����͘�g=� _"Q�z,��,,�L���0EռM�6Y��zT�tX4��A�~�6�W�~� �[�`8�
��D*n��P�aˢZ�����1Tyo�����W�{���du����ƈ>�����.;o���g��`��$|��<�w�ƍ&��um�6i"u��36��fL�_�i�ؗ��w�jh���'�ʿ�˦�w�Ɓ�L���N���{���S��9E��M�b�6�uanfY��o:O�5�����U֛ۖ���g��*����>��bP�QX&_�]�ZW/T�cCg���ZJ�I,4�U �"��.�`��f
W��2�s��|d���H찯��i���m��X�"A����X�C|v���G8����O����9t�����c=��5���m kn���4�F��)TS��G�;���K������x��+�-|_q_����A�O��+��2�����7+9B��|X�_s�4B�Ә�aǎ����%�[ٗ�MH��4>��fE��ViIxǓ�FcR5@�T��:�m��5�^��y�e��)�`�0D��c�	���wMv.�n8�N儠[�L4JI�f��W?�<�� �{��S�f|�����s��>���blX�>���uN�W_J��pHX]��e���1�=��i�h�ʩ�	r{��{�O:��XT�yM)��d�/.z�M\����$je��S����˱om�X�<
K��/˥jG�#��>;��Wh���C�Y�+2~�
��j0|0��:��q���F:n��[�vbҸ�I�Ǡ�g�m�ʀ�I��`�c�QG�0���'��v<��K)��cwJ�C(��ogޤ�3���5����~�R=���'BK���:@�F�"� �G�X�6�z�*�p!M��iX��R�ou
����������tY�^̙a4�����6��Y�ב�i�>��'V��&=��Y���%.�@>�Z�C����4��#x����X���<�1�5��h��"�ڋ���4��^���:U�� ���_ב�i�a8)�KU6צ,\����v0h�!}/MVh<i7� �XE�9��m���c$#$9��������d8_�b#���{Pym���t�"�Ŕ@���z�ꌉF}Tʧ��K��ٹ߮���C5z���J?�� �A6���m�J��[�Of�f/H�r��c�5:���������q��W��R<
3��/v�a���*ʹBͬ��U�zFs'9ha�Ai���ǹ6H���M�@<J����5�9���p�x#qZL�2�M�4!�b>�٬ o0�\[8ϩ��j�[���[),����� ��q�p�г�����r�t�廃ާ\�9+7&c���̎�����t��(����2��VT���Q:f�_����~4�Vh<`E��\D�񸡐n��h���Wf{���[��Yy:�M���H#%*6��c�R� �Ns��㾝b��#T�Y��h<���L����/r�Μ^(��yƦ������&�X'_��F3�F���!����k���B�I_2'�9���{�hq h#��_%�E�CΗWP&gv�m�����ssi pJ͞-�#�(�~�Ii=��a��U�N[��2�L�ʽ�%��7N��@7����3�����׭Z�sW�H�nj��­"]��U`#������Z��K�:\��z���X�n��C�|\��-�y=�|�$	� B�Si<�򦗦�ds�����c\��|o6̈�KN�1��P�7�ه�dz��MH�F��<���Eʂzh��2sg�=�^��z�9��(�T���Q��d��*pR3��o�Q-�DZ�9�E\�]J�����a�{��3t�f�MǢ�Uǧ�hJ��j�"��M%wH���z/�2���At��#��:<z�pGN��1���fK����=��=]O��iL�i���Y�$4���7���r��0E��`K�sJ���{
N��x���~
��8X>�p��(���:��?���h�#Z�s&���Y���ĕ����D�Sw~Hh ��!YN9��L��_jP��k��,a�{��R��T{�u��20f{���		$(9� 쑐��2�"�}Y�qF� s�� }5�ʯ�[,��	�D����E�&V1��$ �C�Iy�g�h)��o��>%F"�����)�0N�QJ�]�GJ2�����͟���m���QO)����Y�cn��*^��&���A���V�7٫��	_��ԇ��PR7"�,��OT���I���^��aY
-������<�B���r���ˋܑ�� V�Z� ����ǭZ`��<P �X�_��t"�a�1�붃=�t~0�A8v���e�����=9�I��m���b�ܔ6r�����-�)��0O���>z�II ҁ�^�Q䔟�끸IF�[1	$��I��2�����a��@K �U[b���	d��Ln �0��8�H8��*�W<�s�뿞Y�)�>��l���Ch�j��d,���V���k�\�'�ń��}��F=;㮊�2����S�9��w�e4K*��Bn��hc�XT}��.�<i����m
�6{,�s�Q0�pf�ȃ���>���گ4
�󼀚�����Vx2��j �ѷS0�d*��T�m�C�6,GB��|�.!F�?�x��~5�X�Zo˺���g%$���ke�%���I"���H��>M�]��F��@\h�e6p���>�a�!��O��6G��!S��^��U,�W�Z��4Vڑ_K�`}^����)-�S=(�z�
��'��υi�7Wd��%�6�c��ɧY��k0��e=�7��߯�q6�/�Z����HϺes^� �W�P	� ����ha��L��k��B�7���
ʲ1R(���4�^�a���K��_K�VzU:�i�ߧ����gI�u�2$)����#�8�#��*����m���	�y٨��l7�þN%�p�:����=����NL�r1����C�ƲR�s�;jQ��X�c���H��`�;�v%����,� (�-茳�~�Y�c��>��&RuZ�)�oQ�D��ڈh/�H����P�}���Fϭs$6�LOe�K}نM�W����bڥ�ӥ�Aq���0��0��;��Ĺ�r�
��wI�N���Z��Yy���!�g"��b3gD����r�񴃠��5�����<�$T�b�����,@'�B�0�v�w��}��~)2i�̣�ߕ�I44�f�e�RP	�b���T�w@E[U�q�3���RG���hj}�C>3��)z+9�0���w{!�s4��ꨦ�Z�%{X���,]�j_*FeyŚ��z
ߵ����Y����{({;�!����ba��!iy�M�Բ����%�Gs�V�ۘl{�u�����>H�Ğv�|�/�!�i0?^�
��h{�[d��^p�nІ�͓[3ĺ�7�Ӥ��s�p�A,j֊��?Y�������Y~N1ۣ��-�D�¸��L	A%ãKh����@L����Ǭ��r5�9U��,꒑b�V�(�k���zWf ,��=1埦��s�q6x\̏�A����rZ��+�L���E8k<��%��#"x��w��/e�5.��?��}E���A��EX��a��5�Z<�{�b��*��I<E/��=u�ۍ�`��Ӫ�aOЯz�q|�j�JI�2�?t�T���������H��C�*ĽW"��}�;�dAUd�%�I��jC����M�,����;������0ݖ`;���XjvF�'�J#E����e;`lp$a)�X*�3�C�)��h��~5fa�����E�_o\y�<��D�b����xp�;�EżB0(8_R�J���zvE����m��,���ϵ�Tz1'�c�:CTA�/��o�mB��ʑ�?f�aU���k�-f�'^
G�T����d�>U���3���u�A�]�D�-C����M�#P�DFak���w�+,8�E����I�E4��'�\�(��UC&й����#�����շ�}<���#����3��˻�����H�~�5��ߠ�HZ)�\�$w[?��,otl��7{hY ��~�������U0y�$B_���Ti�_�Μ��j�mko�A9
�}�y�vBnh��V8�٤#�v
�(m�D&S��mdL�#�x�����hl�_u�����~���*+�%��Sۆ���uK�&�IBNs:ޓ���ѝ	�ɓga(}�v':!cD51!��\p�d��Ķo��U�<H	 g�#�k��N �y��L�1�3�r�w����h]rBV����.��
�X��� j���=�x>��:��z$�\�B��y��ۨ��gX�;r����h��-����{tu����L�����E5��*�o�4��{K��D������V���n��ǭ�MN�9W��͗�i���b�-�3���Vz�vDź��0���#�՜�`JuN��p�5^��@!@�~+U�c� 0ʦ÷
�(�h�����\֮d�Q�o���؆��JE��/&\��w���|���C/�'�*�������H��'�R!,�3�K�	)'��\�����B�t7��#��"���\�b>�M�uzBD>��&��k޾��f�A����E�Z$��ˋ� �W��A��#+�0E�>t�iu��֚��m<'��oJ0���d��gp��1go�(c�"��u2�=��$�̮���x�P�S�|�t���|����>��7��}�`UMl�]�*�tK�ԧ�E�%ɿ��Ђ���@���}�&�х���Uk�����J�fH~�.�5�d�����T�����1��Y����|3�P�nj�,� 9��Qc"�����s����gD"٤��1'����&@�.q�Bŝ]�ej��89��AH��ȅl�s���ael��į��Y�358�g�E��5��(.����+�DU��2�/�Y��x��2��݋��̈H���TS-Nn���Z��{� 6��� q����;6����퓼�pٝQq3����M$f�Y�O�ZN���>%�-*g�)�wi�6�j3?O���J�����b�ⷒr]�r���J�m2�&TWb�w������Ш�"^v�DM��)���Y�z��k|Eu�%Ǭ �ZNQX-�ư���7+6\\�,�@�Ryd�G���M�Tե>�>��o�B�x��f�0�ZŢ5�-���x�P˼����q��-�fn2j�<)L9�g_a��3���g��@O�US<}u���C��l��ʝ���a�F8�D�����},�^�iǟB�B�G��f��	5��Y8�`v�4忻߀������N��&Q)��0af~f����AB��x�7���9��!Hў��ڣw�7��w@֣F�vK�ޫ����f�+*�5LS������ ��u�‹� 6R��UX>{�x�L)]e�RM��7<SĄ[`c���	凥J7�\ہ���O�&,�kI�.��7��N�d'��G�X���7�L�j��/]����W��Pn�j�����gH1W*L��b����LL+������
	~�w���|��<�}J����-�����������+�@F�Qy���?/<�i��	����FǟI�x�a��u�)ۤ��ZkI�}3��%1}ƻ?�Vtg$�l�8%6��e�Y&	��e� ��koO,��W� AJ	�XYPp�tn�-*ԉ��#]�ѶD(:�_���Y�Jzz�pL*~���Oq�P[H����s���j.?R@,*0䞎��w�R�f£��_	7�\��lYG�)��p�,\�y���L���	��\E)m�?��Wp���&!>`�o�w*:q�=�H(��`����$�x��� ���Z�!�?��A����بlJ�Ҍ&���P[�ҽ���}I$E]��v�D�󢠮K�Ԟ�*.1����`J�Wvֶ���Q�b�j����Y��e�{�bҕzP�`�g+�ke>'u�~��������'��IM�f6�j�a��=ūMG����zE�����[�YqK�s�B�"����4���PhJ�=yl����jb�����_�Q~�s��SǶ����->�k�v���g��C8]1
b���:i����E�npx�!#�����MØ�V��7]hŝLm�J���H���VB���+�cB�Tp*�0�N`�@a���6��0�l��mGT�{z�C(b����� ��'�/=c2{��If�M��A�Ʈ�Z�m�*w�j3����t�5kҨ.F�_Ӷ;�&9��K��Ʌ\�Y-�� {��0���?�$Kȼ��h�>KЪ�;�X�<�?>����	��9m-땣����+OiHo�;ʦ���o�G>R��r灍��K3�-&4/ڧ�Y��\���e���2m3剳���q����a�Mڣ����/"2J 1t�������ŝp{{�Ǔ$��F|���$�������o,;��K{g;I|���V�L��Rk�?�HXs�6W��
i\��?v�1���SN�u�W���|�V��k�H.R��.����~D[�ᴱ����р�K�-4�"N������á�H�%����K@$��K�X�*#��CE���͆��������{����D��;�D����M������B�� ��ES�9��ژ/����6��O�	�2��`"Ճ�;ݥ��㓊w�_��PI��?"MTO�v*��l�o.��]4ic��Dm������	.&*���Z��b��DJ��};e�P�qA�t��jJ�����x����GGW�z�I�tبg�̍A7�xT�;��p��/�Cj�������JOkd��u�3��h`q�k#��e��sR&n�I�q�Zi���Nfv>��`��������Ks�##����U���K�������%�
�ϸz��Td��x�oPA���P�,�����z��b���9n�D9W����sƸ�Ch�������H�D��	�h��92����0G
�'��hc��9��;���˯HG������*�#6<��S3��̨��b���0/p6Id�~Lqu�ś{(G�vf�Q����CJhX�c�e>�[Y(���o"E90���� p��<	�o�ֺn��eiU�����ͻ�ٶa�z�Z5w���X,B���[\֡��U�� ��E�WO��,
u�x@�>�����W�B�9+t�
��w^��8@���Jkpjt�gO���G�F&�A7:wJ�o����?�B�-�.j6��^��V?
ҕMo���1#{�9w� 3T��/,zZ��}}77��"��	���O�Aҹ����x�@�x���}����3e��9!��-�4��n���y�'s��-� -C�

pj����j����9� 6w�m�z�W��`%E��6n�*�:x��'l�O�M#ZU�iF��G��g)���$�L����2��?r-�� }@Ė����z�78�B��R�6}}�t}�\����m/S�t3��$� r�xYX���I����0���_��Fh��{�Ϫp}��FCh�Dg����/u.X��H�F�C,wi��n�Š�I5�r�����"��ss��% ���0@3��映� Q���� �/]qomq��2s�<r`�d�V�J>] �����1Q�&�ڑ<�[p�p�
��!)\��n�A����p�N-%i��vKU!�_[�IKnE7_���٥5.�����j�����(O#X�Ȝ$��x/�#to˴o�d��Gx�-�(l�Hr�2��#��'�I��Q����T�T����[���Xvh,�vp܈4`����v�#�mv�~qC�V�6!�rB������������ ���эE��5��	��{�ܳ[��T�|K�����3��ڪ!��������JTє��a��Ά,��}G8�c:�#��Lp�酑=D���K�����eL���p�r|`�����A��&�(���͌�a�@� �F�
 ;_F���q��N�r�a�ǪIn��k�K`��iK�lL�3B`�02�8"����1�g�6�c][V!�����p����,��בJ���S)?��OD53�eiBL7��
Y�})$�d����;ބCϞ;�!���� \q?�	�4��Nq�c��S���_ZuCk��5˺���a<+��'X��˪�4�a�<���pv�����wuP�,[�_Z3r:qJ��=U��Q߱�yY?�)��r�t�q"�����_T��J�#N-��y1"�&�e�R,)��g���{�1� >�*�9*.�Q�m�����J�H���]^w��vP`򖐧�0~��p�F;K������>��&�+o����'ݱ@k��o2�v*��%1/���=�얁��c����WR��	!�"J'����EU���LJ�\���ILA���M��6j�g3���bu�Wd��#�Ih�|�xg�"ǰ�`sL������jX�K�������G*\��D�V
?��WL�Nzx���'͋'k���x�r��X��R��F"��B}���E��xN�1��a�9V,��T��J����ZRK�� Y��@�oՉP2E",(��8�H����Q��<vM,Nf�@ç7�Ɏ�sa*���8���9I,l%/�%k���b�)���;y�Tf.�ډb������v�� �D�d����w�}@F:���ff.�(�J*�e�AA&��䦼��$ä��Q���w-�Y����t�*q˫
�Y��I�v��|d�W&�Ƅ_9�,�0��i}j]0��z���k��S��� 2Ȁ0���-C.�� ��f$��Y��y�p��n�wDV�E>�%Ҍ-�:� id�	S7t�af	�f��ԲUq yp����8�͞|�e�A��Lu$}S�v�">��/�>��
���lc�B��W���a����#JA�Id�:n{���#Ç�z`���N:�έ�B���A&�ȏu�>���g�)u �n�of��~��Ӣ.;-�"5��x�A��V�� ʠ��.�߸���7m�*qY�S=G'
,aS��d�z�Y�n9��T��x��V�(���bU����d$�qmyC�jg�j����E��Ϧv����ZN�rw���e�=/m��]��/�5��j����h��?�l�\��
��d��A�w�=b�}���%��b#�k�e�aDA��4��`����xQ.��H���V�r�0^cv�CO�_e�i���L��$��*���uTb�������E�q�a5�<~Mj����k����ɟW?��f����27]̽e1jM��swY�svP��"2��]���ae�4ع�[V,�֪��M�V�dZ���\j��a����H�6�N�V�1�Z�N�U%������#A~�~z>e������w|]�q��t�b/��t>5\k�br�:��}�l\�Q��:���GwFw�o�i�!�]������bu���紾����'��m�݅�S�:�w�]���:%���{�=�7��r�G��LgR�b({��<| 5��kj��2� ��
c�{���[w~N�z��L<�� �0Ԅ{Pݡ��g�v3�y����&�&5��t��_�v~�Tj��{z�/Rn �d[��qw��(X�x�@�
��f����n_�E�>@��D�`�����f�`��Sh+���޸H,�������;����j�񣉀]uv8f��gU�I���a�m8bz�Q��Щ?�W#���7�3;m�_4'�9��m�ӡ5���6��f	|h "�s�����ey�����/��`���3(to	�X|C7����ߕV ;	mv��̒e"�f��_)U�T�K��عzG,EW|�oH���$@�|�9��x�u��$}��-<-?��[�i����X/C���l&��Q�cG2��X�q��h�fT��e�n$qӾ�잊���2>����;\V$��t���k���*�1��֡�W���v&�\oUs�wO����1�!�#P��H][�B!��
��1H�[�U��FP#��(i�
���Qّ�2���/�l��K�L~��ևJ�.r�����w��^�B�������Ϋs�K�,!ʤ~Hig(�y3��M��uj�9'�(�Y1�6&�Y�����d���{b����"i�𿧒>tՅ=7��}�z����4��ߥ��O����7 ��~���X�ǟ���sdM0��ȧl��J�<Geu�h���!o�_y��Y���B9��iW=�'%;�px���F�1#*�_K��a�U)aM[n�rs�D�$��V:I`,�����-׉����d7�Q��!d���A5l%A��etd�=]��F��rS��j�瑄���Q�A'{���`n�,0��!�@�׳4�	��@�P8:PlKO:e"�����':�?�)��'��q�`S�a��)��=�'��"�TM���@/�z�X(�ܝ�����`v`����e&u�YQǸ���5J���#=>D�Ԓ�M�'��$����ʮm����
�E�U��P4,ɛG�xx�`�Z+Z1�����p�e�WZ��+��N�m�޹ƶ���F��U%�NF�5��UK�cL��d�f��ѓ�@�:�'�	^�Mq�mkĎ��J#��x�
x�l��`	�C�0���i(ꭱ'�;���8V	���'�Fr잯_�� ��%��6T�$8q�R��A��9�n��[����t�{G����}�u�(u�Ms���� �P��s�F�ʢ@��dZ�g{;�܈���[����y�L_\�R�G	s	���qa�|�T�r����§���L�x�UTI$ESXc��I�FI�vm�Sև���{�[U��C��A	���ʃl�?�-iq�ެ�ާ%��G���'�+t�ё�[�&�7�����7:�>7������f!Ө2�;���{��1�>Ȟ�$�����nuOz�!dױo�m�L�~e�\-������3������kK9:��j�1��){7ۋ�Y�1�v���Q�$��U�ͷop��'�5��M6�o���$i(5��to���4eq���)�-�Љa�\ga��&G{Z\�����A,/�g��θa��m�3����	��1O|��@�f[����B����^�
Pu��wjf��x���A�bh �3�s�?�/֌�,��EE�3U�.r��SYm��Ն����v�:T6��w�x�p�q���-ӌ!q*��K��m���{'_�b����ۍ���̸�:��µ�&�=��j����q�&TdՏ�5N�������ϣ��ng�Lg�Ӣ�lzRK�eikJ����"����S���}>���^�dD��퀿u2Y�����f��3Bo�8t�������ͯtѪ=gL�[��3�`��d�X��X�_V�o�����	��ʎ��@��;k���B�ZU�RGY��Z��].�3*�λ#�^6���Q��'�]�eUf�F�4q���X��+��k��G�+J��_�:�t�@m}Qt��Z�o�7܅�6��zj�̺Sla���(���|�Bj�
���	3T6��|g޼h����D`��i"���Cc�Ksph������1 ��n��Z��.�U�+qA���%FGn�'T��uf�DIv_QӋ��=�c	��β&�W�uV�T��1����}I��x����\�-&��{���T~0��1�U��&�������W����]g'$��˕�w<)=�|~,�Sy���_\�2M�G�j��fZ_����Z�kn�}�����($n��G��q��<?��u���h�]��<m�.��A�������m��_��s.�I��J���v��[HP<�YX2�l0j>,�z-H��sj�=�b�\��!��w�p��(�.��ԇY{\���:�56���~��A��=�K6k2H ��5�N,(:t�S���d�[��'���@�g���,)�J�S��s�H9Dg�� Q�]�l���V����#%���W��ڢM6O0F!>��$	/9��KO���/]G�uϢ��ʹs�XnB�|Ӯ_�PCdɂV���}�������L+_����~�{�.��?��_^�^��`q;��pF �ɼؔ"x��/���f<��XN�Cʘ}�טz����&=�\�̴��|e�ɯ�|0�A~������z��[�@3敔��\D�m<�N�k�?�׭n���ef�a�g��#ܭ�ӻ��9�[���W�U���wm�pG1K%M�>���X��\K�O�9������n�B��VV�'�r�:Fr�e�^�2�����R�y{ �n��HA��y���&I�}�����%�	V�<�-�l��vU�Ą��؏�s�@�v`ۃ[}�z��'5C�Y��u%P)D��'� }�$_�|����������3֒S"[�J����:�$�!�N�V�ӑO0h�,9E.�� &�P�i���]z.1SUo�	�����sN?����b@3ٰ3;�3��)�k�/`�x�U�N��"�	�>+?3�px@�'TGI���S�L+hH��Z�^g�B����F	h��"L��=>!���#́^{!�$�&~?�0+,a;F�7��<w)��9NK���k�9��m�3>�f��%���O�c��5J����(�ۈ�SR3J�����W��_o�XG�oݷP�įv���9�� q����x����;8aX��ݻ:,Y�%�F-������/�^���J>w/�6�ȅc'�8:��R
M�p�d�0�o����J��d�pSV��dv�N�BY9�����ςc��N���o��)��^
�??tm�+�~p�=4�
d�o���4�D-ELx�(��g�Xw��	[�n.��܌AЃK���D������17l��hSM�;�Z)��|�,��0I:M���GQ^�>�
'�UȽp]��M���u|M�����0��W`v�]/��c�e�5��m�[*���Ў�c��S�5JG�����$��ҙ���A��|���k��V�diO���S���L�VC�E*�W�	�+�����O����7\^�`�fN���Z�0鬌���}p�J��0�I��y��Z,� ����b}���NwLs��E�S��vJ�
�?2��!�vrV�j6̡	�cGLeV�|��>9#�n�� \*	���x����~z�}��e��T��L�ؚ�n��~�x[�|�(�f����gh��4��_�3U��\��!���ye�z���Hs*����㶤[uKyW��X;��9a�5ڭq�zɯ���Z���.B��b��8E���VR+}f�������1A�"�@��f%\?�t��;e�(f���E�VnYO����țo�F�ᦸ�-"b�)~,mg��qM�Lt;[��[,��_��u8��0]Ƞ���({r�+�/v>.��f��m�x�Ӧ���Y��yjZ����ޝ�a;�����pt�ދ��:[�e���-��$�Q�����u	"^�uT[<�=x�Uܛ,��	/��I�:v�I���+>��r�~[�У�@����Of����� +Ҵ���q�Rn���f�/:��/ˢ��@�l�u���;N�+x-�/oC���	;��e�%E���A�$7�BZ���_���f�����f��;���(P��(nA���68����-n&�d�Q?S�x"���U�;G[�|n�J7�]w�8�G������h��V�?ް+Ħ[��&$�O� �6��lo7@7V�\q[Q�Y0�?XI��Bж�S㛁e$�l�/��V6p����>o��饩�-����O�p30	�uBv�[2�eg��B�w���3%K>PLBѢT�)����RQ��X�0O_�^g�/����|xWdW3��T�
�����Rt�ڹ��/�F�X#����s�~��Z�� �t|Xϝ��l�S�����q��إ�	+#{�0��L\"���+�}�wn�K�볞�?��g�Bzc���[ޢ-ܤd"AqP=bU,3�JZ�_��>��R:)�3N�*��� ,���/�������Ӓ3	T����M�̳
h*#��x��D��<E�<'ړ!1���NsG
�2��B�O��[�暅�����/-��1���:�|Dy��i���	��Dh�@�-��dP,�c��KSE/ _
�D_���t���/Q�H��O�\Z���:����M��w��c1WU�6���r��7C<_$CcS.�,7Qc_d�4�	aE˵�=������Gr��!��"���v���JL����,�()Ӿ�gJ3��C���pA�\t��&���Fq��NUq��/����Ѝ�YH1^�Ȃ��a�o��p��)�b�=`�
�f�d��rtp&7̿=��y轤O�T�q�&��ی|���Cv���~A�dk��#�N%��b�>����\�B�;�ϔg~-�S�`q�8?!�Lp����n� m']��l��7�·"i5
����O����$��{����=s�߀��ǟ=��!,�%�}^��Fj��)�@���C+��l%���1�P�l�w1��kd.�������-����/�����<��N��s�Hh������W"�'@ ��jcP�gXo��5�ݭ�R�:9GLn���O9�S6��������׫��u�f2(*�-
]��q�5ӵ�H6�bJ40�/��o�Ui��lEgG�B�z�=�q��s�b��J����)�o)��p���2�	��zX�:!Sr6SC���Y6�n��`]C�2^��^���(�9Zy�
5^[�44K9�4�U�P������O@8)Y�hX�N7�תO�x�E�yԂ)�is�P����h��Ng�[E{�� ��qZ�f,���/��@Ƚ|zn5b�{tL�7g����F���UD������2=a�a�d�mi�#�U��ĂMG��� EF�x�~�i����|��M���&Jۿ���+���|iKb�����.�#���[�w��m!t�%5m0�2f�2����D�I�-��Ĩ���.3���}ݳ��h���~�Sۙb�^�	0�䁺P'�l�Pc86g[���K�/�����dx�o�$���e�D��ZHMP��߃|��O��F���,�:��V�`��#�P�d��~�][�T�ȧ���8S�]J�H��x��t.P�T��F�UǏ�KӋ6�r��dᶋ�'`0{Q���P,�ÅJZ���m�����c-|��|�5D�fo�z(i��,�n�c���`;|pvV~b6�o.[j�NhV`)'���c�IS���w��_�-3Y�`
s۹J�Y���7����p(=4g7�Ԝ<�<��m�|�.�J�f�d~a��W
'�P��HC�����tWC_�`���/d���]0�.-���MW$ ֕��F6FNL�[��"(�}s�E�����TE��Hn�pY2)�qG�a`����k{#y߿>~�-�z�=;n�����\Q���`�"v͵�T���zHb2T��W��taE\�j��T�+(U��f�!��v�-_z=��W���=+f��W�wk���4Zt���Q��z9e����������ח��ZU=�xy�����:���خ���h��=����i��vj� >��V\���Y�~��b�9})���t��ܙ�l�Q�p�V֡���{�����@Cj����uy��RK6]*8���IS���fTn�{�p�������o��n�(ï{��f�_t�.辒�{�L��4�/ʹ��̾�y"A�@�2�H��{SW#�	�@ Mᦋ����<"� �۬�N{b~5���F�%���PA)b��|�$J����+~>p~j���� �o:D���vu;��I��OT�J�`u�W� zN�zt)��C�C�_n������YX��!x��l��d"JIz���W6�C$>��\.4_�HT�� N����0�j����G����ϧ�L1�c5��jc�e+����K����[��A��1G�"u8`Zj2���T6�P��3�*�_Í.�R/�0�݊r�p�T�5Pqy�捯�YŤ�*qn�H&�"�il�˙��D�f�ƶ�t�V�"O�Ο���t���n<�[�aų��f��}��
k���K��$�:�ji�}�6lY0��¬%�a^�q ��LL�,�_^�̈�|>�*8�=��֟�댟<b0���\n(6B���M`
����fc�n���š!Z�H�#s��Kګ��K�1M6�v���r����s��C�?�h���o�����Q��吡���q��=�-� ��+!ev�#7��{�fg~�N��źg[�	�A��9�`��
�k���ϩF���L5�i)���'����m�W|�Y�&颴!�Ri�$ ���zo�ӱX,x�9a���`dܬ���A��bP#�T���4wV/�]��d=��1�����#u�PcM���c��Q���6"Y���F�n,�G8U~Ji| ����(�*��	��0�ËZ}A�b[4!� ��ߙ(S_8-�u(W��3Q������z��l��H��-!�'��L2��C����Qsݰ�PK���K�W>�&j	�*���8�.�Z�+P<�.d�S=�7n6 9x//tn��#��s�4bٽ��[h����5�zN΢��d��4��u}��J{I#������;S�1��7�I��O��#:KĻu�Ǫ��u<tm8�biֽu��ʼ��f�=�kD���Ȯ�N��
Jz��`�v`?b�͍�Cz��KPW�����2x�2zExo��E��:?%N�AU�)�;!�}��[d��v ���Ho	��&2��R�e�������L�l��Z�t�Ke_�EYO��FM�ʯ�����yU�����Te��qvֱ+͆��F˱B��ˢ>0Q�4Z��<�[;(�L6n�F^�d��zA-apP��K���D�v|侰`Tio��VlyH��+������S�CSLLo;�{�>��!.[��E�[�;)I¿�z�g
�	=�_�INN*�E�x�)��៮3�?���Á;dŌ�G��ӳ�)�@r��_��B+���YX-��x�B��ϛ��97��0���]���NJ�|�ȉ�8��A�~},�O�U�"�g������R�x#ھ�3\os�4Xj�?f�xa%�'Rġ8��p`E>!�z�*�m$�X%̻͏�'q���,I3x��;Y�V��HȢ���G��X &6�i��U��՚7)c����aM��&�X
GifV	��8=�����d�-��ǐ'
��   ��E�D�l ����q�ȱ�g�    YZ