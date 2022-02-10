#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2472300436"
MD5="5b63097bff7d345d89973ca3b8fe8985"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26360"
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
	echo Date of packaging: Thu Feb 10 18:32:23 -03 2022
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
�7zXZ  �ִF !   �X���f�] �}��1Dd]����P�t�D��f0��3�_(ە�H#����vK��K�R���s���DF��FP\l�_;s�B؃��;%ʍr��湦m~%��;�!:N"C��|�v����®��,�d��6	�Z3�.���Cs]$�❮s�ᩣ�D��Q�H��Ѷp'��i�������0�w[�˵|GF�g?8㡗��o���*�vv4���ɑ��Z����5J����7����⚿�;�-�/b�r�:���ݳMH�R�V �)��M��g�>�'��A0�f子��W��0ַ�OZE⫝̸0��g��8E<:�3�tw	GR�!�=qQ�sg�Ķ�Q퍺n
��X~3��X���2�n�/0p���g��b�a�&z�=k�yP����}BL��D���C�����͑��pr7��j�}���1@�.k�an˄�H�;��]hh[q��2C)��I{T�k�؋��À<���e%����+�F�
�y�z�>���Fbƪ/M���c��K��,�a�]�߄2�k�x���#g�t�4b�g�pctr�:�����P�j��-���y��P �c
Kr[��9��C���9�J�zJ	R���p2��?Ȅqv�P֒����IY���_���
�_мԢ�q�9�\��MN7`�tS"�7I�W�����2�������͑���%(���0=�����l���j�g�<JTT�O�%� ��H���f���BWF�о`� Ɨ���iܑ���'-������p2w��z��%vuG7*U@<1ѷ�"��b��_yؒv�<`)s�|�!�@1 0���!��x\kZ�^y�#*���Hv���A�@V�#P<*29�?0�>�Y��F��%v���H6/�����d+A,�Z�ǻ���g���%�}6E|��^,;�yy{����C1I���!@�T�?<�L���'�7��޺�9�[g2ʥ�n�5�xFr�tX���
�zVc��"d�cT�Z(~���C�5r�F+fX�(\?lO}ń��Y:� )8�L�
YDIC��f��	 �fVǿ��_:���(���Y��=�E����u��cA!�s�9�Es+�[��%�4]��"7���ѿ�w����0Um���ʞ�)Y�8�m�8��Ԣ F��k���ϒ�a�J�����������` y��VD�	-��uB�5��Xt�xr��I$���r�uBJB]���cN+�G�+6e�b��3o~t��O��0�������E�Ό¶AO�Ʀ^�Q��]'; ~�e_�#K����e�o"�R����MY�v!���CE^,v1��G�^�&�Y_-������t"��f�#��z��I�U�n<���D�-�b���ϭR�;?�/_�s�*2nЎ-�γM*W`��x���φtKE���W�B9!sɉ��b\����eC{?6H��:l���]�0��0ۭ����Y`�;Ai���K\&��}�'گ��cì��=�L����r�&�^�]�;+GČ]���*AQp�{���?�u���>y�F7ǝ�X��	O<۳'�2�����⮭����A�Z��PX"mF����y'<S����1r^��F�42
l>o�LyR�IJ$����ʿK��B���! v����*���_��dx�l�*
�+Gj.C�?=KƿrH�t�P"b���6��SO��Τ.��Isg�c�z��p�A��ae�q�<���/��ʛ �;����jU)�)��d��
�{�����3_	��j$�+q��$����n�WEt����R˘�˕�}ky����G��$�<:��m����L�Lr�c�fo��'X�qq^�42?-H�����b�(,n�f�Bň�Y�Y[�z	���{�����}Z�Q+���ҿX���
�r���_��`�()��a�o�:�C<�g�9�B>F���E�{�����_��^�3z)C$��͇�5q_��Bi�4�	����]�a�af��?^T�z�)���j� s�^��ѫ{�]�Z�U٩�CD�����֬h/K��:U�w��M�O���R�|�g��Z���$n�L*$���(<8�0�g��s�k)nI�0�R��-?�1�d�ZhK.u/��vS�0��Ɓ.������:ʠ�0t�¯BM�I.����yu`g������x�}���EG/.��և6�#�8�.��*�"�yC��*Ɏ?UnZ��w���������r�X���˹����V!L
ܐ��w�)�!��S�ge�y����l7+�2�����(I���ݞ�gY�F��~��C�<���_��	(0-�h�=�y�����nUn�=��X����@B�0;��;E���#"����O���3�+�j���p5�p|�=WAX�����;X ���L��;����SKW��)&n`o�xq�l:~�;U�a�,�S��Z���%�!>of��-Z ���<��6��	�~�A�ܖO?>l4��MQR�Ux�*�ܿ��1�R{��TY��|
�H����R���R���A'V��; �:Ŏ��`���r|\�E�i��T*؆I�^��Ȥn���,a�v=�מ��u�����Z�3$ ���&��E�j�<m��p�X���*^(r`X���Vm��Z8]i2����!���fT8�RD]N2����A1Ab�["O铛0��h�5��z+�K�)����Һ�S���73�*I�I��#���w�?���@�܀?���b˪2�?�k�i�|!�I�9\�&�g��D_<0�ت�~��T.��U]�h�t�Ϸ��1�����IX$��{YjVxH�Gq�*���a�k_Y�����\�S� ~�lJE�zMLqd�J�3仹$Z	���4�w@�5��`�4��=��KW������Xza}�x����Χ�n�c���5����s=�zO������pQq�pBC.�kbWm��/�{
_�K��в%�W��r��3����r"��@�-��,,U�H��x6� �1���ˍ�B/{񆱣���X��zP� H��c��6A,�MO����ħR�&�l�X��ܪi�J�L~�u�nbĲ[~�����~��5�pX�f1>7єL�ҕ��5�t�H��B��Gd�:ֲw�6�����e¬a�o�
d��.@�W��kVуf {O�WF��t��`(G]���I���r~�ʤʺ�����B>m'�̧�≢J���}��Ĵ�Y�`Jpٰ�dN"��8{T�]M.[���q��H  k�1��%�<1]jU���}�֗�\[a������#�&@X�0[�<�ܩ��:��@��i�4Y?B4�����Q��5o�uGZtu���Gr_
p Ҽ!N���t�B8��?p>![URXM�>:�q1����5�6�Zwl�5kK]����"�M���e��jd`_�\V{�-�T�V�f%�2�mvx��+���<H��CU�uY��t����H�����ł�s�6��6���-֤��=#�+�6������e��oy#
�v7x��K�鏲w�r�O�Ȋ}~
Qu���Ɨ,^�ﮗe��/?���Z9�?:��nX�2鹎��!����r�V�6��V��γxI�ч<[�d�W���Y��ͦ�M����JSɣ1F6ΰ�W*��]V������0�6`_֡|�ZW���;�J�tJ�z]�I`�4z ��!��r2��$�eQ����-ʹ�S�������g,xB�qmH��^�C�������P�W��f{�'m��xSA&����d !�Z�� ���	&�OųW����-t2���/�ǆg�5��^O�o�jV�1d�~�������i#+-!B��Y��®��H2�zO���,�Y�B1u|F]���^�(�z.	�NYK���]��،񞁜]�v�rf�h��mr��r=�'�F��{6K0��"�|�'�k��{���
d�a�
��Ì�����m�y(�8�pQ��-Lz�f��b�K'LF��t���ë;������f��Mh�Ś5{g�֋f��\�#�x'��ֵO~؃;���m@��I�%��8�R�Y�?[�x���)�b������oл_P=Ƒ5�>�ɪ�ѻ�?��X�8e�ȒLӳ�R'=�8��(g�Tg�/���7��c�I�C��V>]6���P-U��4����8����A�DK������T!K*�!(E�TE.���M�Z*���>U�����1���_���ʊ�V�n�,^��� 1PA�NA{cط[,�-��4{�~�\6E�.����]�-����x��4�'9�|����}ٲ�s��� ��̭<��^���\l1��<8D��z�I*h��y��8.�Y�^��R* O-])�M��IR�&�#��rt7wu�"�|l 	��ɐ�}7V�:	��t �kp����D:�DbY7i�z��a��c����/���s�̏��(ijO�E�5�����kF����{�H�w�u�ӯ��O�EFc�x,3L��C�aǄ���,	�����뾤�t����ߗ�H�z����q�f"�ř�a,T@I	��S2_�s�M�yw��1����mn��Q>�!�_�;�]9y�i��҄��	.�+�Mu`\�ۭ���U�r����Ϥd��h~�����|}	��8֮|o�/<QR2�c����|iu�?��@&_\	O����q��A)*⋭_����?��0�?�x�(C}�8��%I�;'�CI�|U��z���r��:�puJ�W����F
���f�J�S��j���zd��<V��}�V)�t�BB����=�ѱdx
H�>p0܋`c�Z�jN�$����A�s�iX}�cYN'rv��� �ay�
�?1Z�3�'ZfuW���5ւs j��Gѧ������5d�D�n�(�\�ql��8��o� 0�M�ept���\�Q8�aPA5Vp��6A�fHB~���T%�Ε���֬�W\1���>@ʋ +��rX��F���3�?���[�Sq\!�wտ;��Xj�����+cь���V�D�B�8Zw�OpE�4���?5�"�0u�:��7[�խ�?��ʢGw�ۥ}���+M��#b'%7��J�-�)���U�<s`ޟ�O^iML��J:���*���\O��g��7˪��ޤT�l!A7kUVWɆ�&�8��(����MPL��/�)N}�w!I��=��8Q]��=�*Փ�K�^�XJ���}�i��di�l.�L��j��D`��X�"#4��R�͙H_ ��N�xW%�ߔ�e�&�neCgBJ��{Tm�Ǖ�D�S��$/T����-�1S1_Tǘj�b����{ �m0��Pd�ԣ�oy����3u`��ǳ�<��X�)��j�L�L�*VMq����?<�"�#C5 �ꋩ�I���G�W\�I�tR`9Qm�2*���J��/\ Z�7 eʵo��X�-]��p����ݢ�ϲ�d��E�uuC�M4��#��ے�kR�)�1>�l�R�Ee��[����T���0|��&I)��Y�tl*��� :dm�_8=zp*(k2#%%$R:��_���������ܱ�B�ϵC��%�`�_"�q�w�r-��	!�D�sTejT.�l)�&bӬ��g� M#�㒂�EmZ3�i"��U?3��5ΰ�W��)�k�߰��I�0�#��0�[<2��}�ޟ��a��J����^h,I"2<m�\�{{���Nm���BߒB	�R2t�۷�J5���4�F���H�ߠ́�A����P���!�� �������0�w��L�L�9A!�6\�CmY���H����!i��8+�Gn�H���_DbK<�rY����K�
Bs��X���x�X�NE�k��������#	R�̭MhO�.�RXY�şf����f\��s������+ty�Dt����YB4boy��Á�jY����
�� ş,��)��b��@�5+#�3��	st�|h���
?2S��-'7ޑ�:�I���A'�hs��%i����'�� �`�BГf3�@w�5�ڧ^33�ƶ~��Q�����3�e��q��|g���	��K�)�h�(��5��c�X�ӱ���9C�m{5��Ǿ�o5��*���כa��=�	/׵�R8S��E�)i���W��hl(�%|JNۯ63ȟ{�t��)�)�6nt���lƂ�R��d���?XT���Y� �zR�Ce ��8���*��BVV��D%�ݴ� 7�
`V} .�}s���8ï��+�����. ����c�!Y��Ն��NX�XR(���:�����ѿ�5�I5Ȓ��q��iC6^j;@�y�U|�21�	rYWfOM�#S�M��s�ĶX��5��r\�]1��}ΉWv�X?��noȐ����>��[6X^Y�����F@g���$�yݛH��W��X���>�0x�W��ַ���8 ��f�#q=�ݑ
 ���0�;��v|Z*soX\dA*���$��	a|��l��^�Ss_�\�«��E����vO����<p��X��sD�>�,K�}���(����Ǟ@�E��<@sC!�(W��T�� 20Zw��W�v���rS␌rnӇSf;ğbw�Ū�5Z�����8��C���t���"<�4�Į2A�W)T� �-�W�s;����p�T	�Ba�D�p+g�ט�Ԑ�8�����&]S��V ;���\=&f�p�� 8�K��Tɾ�`�Z�A���� k^�aw&]�}�g���򟤩����=0A�T�Ř���9��S�I��������(I�q&#�f�!čh�UȒ���&_�x��&怩|�]"<��%%+�>[��nb�`{Ⱥ��i�H-�ܠQ��>��ۼ@�y�ȣA�g��Nď���E��%�6��?Y�jQw��]|��l�M�ʀ�[ME`����y�,/�	n?�:�ۈ��'w��;ab�8�������;�zH�gʻe֟Cd^0=d��Y��3֎{�4fo��'ʕ§����B�K��*.�ƕo��4a�e�7�
K�u#�[�[=�3-��ȣ{��:�d�ҝ�J�� eA_Q�-p���-�TF�<-@b\3xx���I_cf�:�S)�S�,��c{Y��^�GR'�s�9�d͠lw�����zLM� �?������Q1�Ui�S�6Ӳ�尙4�X�4ûGU���1�-�ʜ�T{���� �.��T��h�G��"�p��)��>#� �2h�y�''M�7K���MN��c�e"�b�ș�8�V}�jI9V���m�-�UӸ��$&���>�_�++����ha,x�*&]�Œ��Z7Ηq;�e�6OY�v���x�tw}|������u�����F�1��~��X��n�f�v3�!?-L��I���ʶ��U�&���9<���61�Q~���j��}Ϣ���ey9Y����l�=ae����X@
u��4���S���4#�̨�@-<��M}��ND�%u�tq�9�Ij�j�zn�܄dN�=a��T������ފc+����:��-��
z�Uj��G��QA��&����+d�H`�u��6U_vW ���Ap�����e�ɒ��Ń��˾�����®��Մ�0��Y�ݴ	Jb���0���6�#�G(��rDҫH��28���Lڴ�f��Ԗ�	QؙW����+�b7���J���z��؉���G���5���У����?5u/fϑ��x�GؑxЗ��dJ�Ȉ��(�ީ┨i=i���f{�h�N���x����%���cY����䚇@e�CY	��{vQ@	�o��HO�2�o� ]�Z߯1���V5�`���3�g:Dd�ږ�Ü��/!͔5��i�.��q�IB�*$�"'��씨�ȈGx���U�a7�_�X��Y�Ȑ���Qg������Q^w�Z���ɣ(aN�{�����%������*�T$N�����������F�M�u�8��� 'H�ܷ�\W}P�f�2_c+�8�/�:��UDz�UEL`���v�ZY� ��g���W��1�\FO�ް1$c"d�	MM��$�Ѫ�,Nz�+�d���ވ�Pj;��<�:�w�L.�p�Z�����)�*������\\��'+8�w�k%��9�W��yJ��Y�����
�ulu�s����C�w�\��b���E鉍v̴2|)�[!�T>�g��No��U_�B���
LfYиL�%3\�y1p�k虉�гs�s�bh諢h��؎Z�ds��=�}�{z���p�e]!��+Q��H.M5I�\�ѝЦ�	x����'ڀ�$q��xp��� ��-a�1�;P���}���Gq$�sڲX*�i��m�ǂ�V�Zӂ[C57Ӗ��Kn_�8JJȿp���o��7�! �3j)[�L����͟L��l𴪾G�&��i^V�&���tPa�ظ@�h��t�V��k�u�TxD3��6N�(�1��>�=���s�^*���<2�9o��'Kp3���'gA�����6S-��Pҙ���(�l�LI���8��~jq��$��3��_��'pkO;�i�B�e%N�і�h?���]I��I%6BD�1��m��3�NU�����SL9�ys��ՙ'�W���e���x�(��?�%׼��f�O�ɥC��#A*h$x��y�Y�^OMW�)'�N��k����V�ŀ�@'��U/p���#a�g v-�d��n;0p�S�1�d�0͞+>����qxD.��s�E�a�RQ�f���5T���@�������cku���p��G���	����=�f0AFYCZ����e�/x���~�T�������A����-kX��.�|��I3�^��5,׵h�V������]���U��~>]�S&�T̙h�'4��d��V7^W1�]xaf�u���h_jfM$EeN����>���v��� ,Ei���"�$��Vy^IF�bl�o�=�5(�X��FDXj�B�E`���:Dz��=U�6�����Ĥb���a�r;k�c?����n������/AB���% �����P���L��9�5�y٬0QV�«��
��z�r��tǗo	S�o�C(�v?�?��a����a��SVց]s���u��Z8�����a�#\���� ߴ��m`$�V�f=����>�����:xOs(:��:,j�ҢR�y�zP��L�pCi�m�s�s�qNr�cKw��)�4(,{������JyP�N�sD=�f'5n�x�����0�w`1j"���\8�ɴj�D�df��D�Sz�l�]^��㧶O*�I�&ѣ���������1F�a`��}5]����Z�Y�^����koid'�k��2�c[}���P Z�O���͂,�S�-�9ô��?����r���� ��^�����w>���F;�}|�D��\$.��yKd7WV�i����Z>dfU�0�ꚅz���[qP��?�����ܕ�������*��y���� �
���fhw;�p��`5p�z4�Bʯ�u@�N�3���F�f���8{	��HD+U2�l��z��-X���_T���B������w��r�z���Z}*�(�j �B�1`���WB.�>�l���n�%�k
#��%��/����^�pa��%"绘*9���k���I� C�Ta�Y %r���ry�I3>n>��:T]��+�J��i�F��G��p�v=�ݧ����`z��&�׍�Jc��&�]��U�����y���!8#Z���ӄUHm)�ݘ�y��m�=t�� 9�\��)G�+)�̭�*�7�e�TVo���EB�5-�M2�F i�{I�o��5�(�i�(a����g)�T��ұq<�k�I1�G[�{U��)?���V9���k�7XX�X��*�$b5v�j+/�S���ڍLPZ�yÍ>i^|4�k"���ds��B�C��e%������_��}�6��i���i�`�r��[�g��~n����IՏHL	ɛ�[���<l��ߑ��F��迺N���]G���N�~�G�=i"�)��Z�u��z�w]4#�82!x��]�ɝ��,&�(ᄏ��e�Q��=g��)/V`ڸ���W�T��N���M�M7/YB�� �k�d��$�ae�s�`w�{e0v��t�^����ʃ�jJ�����o��~6�&����Y�l{C��
�uo]Ki������O�E�rݚ��v;(�_��]ֽ�f���g�|�~u�iV;͊[������d�{ׯ����hq���-��=v�WL��80�?�}u�)�B��������4V�p��i��(�-%�ܙJ�l��U��6�c��i��>��O[���s���&Ħ\���}&ֱ��J�'w�Ka�|�=y��S�T8-h8}kE	���]�{PfD�{�$�����3��4䔭�6�fFJ�H'����4�ߴ����,��v:e"���(ܲ��×���X�{h��U��1Z%��	�����r�\ޓb�ү&�����뙨X4*6=�p#�,��ږ��ڳ��b����H@c���Y��e@��m0��_޹9[�'e)�Ol����A���OK\dE�1�{�&�ϙ�g���ɉ�_c�ӌ�"�b=�`
��f��]H^�o̲�	�߀>Zd�M�i�����&Q�C���yr�؜���Dz�����,M|q��,C9̏&��	�:|Zw8�D�0a���P:s�EHr����ƒ��{]�=������|~���i~mʯTd3`Ql�RJT����OJP�k�־o"����E����D�(���Aݯ�	8Yw�� �`�2��c��i�b�w��|A��!%�$�a(.�2�p�Ab`�qoO`aNU�'�=5���R��Ol5���7^MREDH�H[G�L�&�+21)i��fW a��(���13ڏ�_H�E�_ő�^937��;��P��h'���+��$Y��]E�>ɠ���b��,��B���(����=�}q���L� LA^���j_�w��8��`r���/1:�[@O]�A��ZL��k�'n{پ�_�_y��q*!�	��X�M�J�< �B�UЖ�J���s�����m�b��eYn�s�
I<tL�f(CD��6�m�4R�g� �N��Nj�z���u�r褵;D!hts��6%P��i���u[���}992<y���ͣ|LW�`ua)��xsM�ٟ0L��!*6�	���ގ��i�s��h����SY~Bm�	��/Y2zJ�����a	�Ck Q�YEQ~��W�˂l�p�d��`b�X��r��<I��lb_�b��v�3�c�����w�:�^za�\��^�8\(v��嵚*0<��������X@���,��io���s��N��6c��NQ�(�kX�V��u>!~,-�s�#<�� ���U=�=�m��]�@���Lj���F�М�fż!�[��YBe�p�A�R�K%�6�1Zokm쭖�Pz2+�/�i���X�z�^n�����
ُ���1#�iyO�7�������a/,¯��O�'y���x��LI��K:6S��P��CYZ9�n�*��@�/��9�L�l��d�j�r�w2�K��c�,Eڹ64�dt��uVyoi��zz��y�>\ ��&Yư�PѨ��\�kT4���b��ټ���ow v6�����<~7�xߞ���{S���H�ZQ��ioܒ�9�蟀G����1�ݛ�,��
ɵ�@[��%8�9=6�I�.�����3�L�)&��. ռ��,�{9Bs޵����_p����o����1�w�g�E�������o�sR
�l� �T���%����}�>ض�*�t��F�H�gY��Q�������Q"��F��'IH,*��؈� AR2ŗ�����_um���X���8��nX��0DJ��e�N�� 7��T�ǣ�Zo�g5J��X�^����ظ�U�Ob�����g��:ҕ<����m���d�Л�����R~䡫ơj����*��2�'�q'� ��$��b甫N���{��w��s�qsc'��#��D$U-�$�O�Ɵ8X��+�{>:7����`��;{�Z�74�� �e(i^H�~#"Q���燫��9�f�F�>���z�����@Ԧ?�p��%���
b�(��6u<�ȢT�tu�� 4M�:��b�"3����f���%�s?�P�ʝ�8c|��b��uܧ�pRy��y�I���Qnۃ୶t��<T!�����:h��-�9a�#>
�fu�z��:��T���ib���~y�����!�䔁��r�����7��>��k�#��%����u'�o/���\g'ӗ:��L�����z�0�&Y�}ø��� ��ª�s*��6����D���S����|At-j���W�շ�b��J3!��ϿU�9��o%�Q�@�(uic)zD[�t�7����5(�pO�J��7�yS�<a5H4�Mu���1�~�Јո���x�3"\3���Im���2F���<�����	�N�����0�O-%����"Ѭ���e��l�*�a:��Y��i�#�����������O�_X�A2�L\90�^[�7�H��xYZ}e��BB�n�h�aS*.'���S̮���sU�'E:��s:��e��kdb���F>�zjy��=o�K��^���x Q�"1ߟ��"�֯,uR4nw�"�H/SJ!z���4}K�~�,�d����'�>K�)gτ����7�@G[|5j�O�tu=�z���d����c���j>X|�]���jm�STI���~�j��vGm�$hMW)z%�n�kp��8�d�?�E����\����,O��x���/��E᭨d��w�A�qA� (�)����������Lqӂ��	��/��{߃�"���o%a��/�]�t��Npu�p�?~����
b8P"��f%�h��������hK���-�w$+9����o��X���%a"��l�Y!K��\�I)QZ �zk�
~�=WK�w��
�h�EKo
V*esi�����z����B9�	��-��O�X6[���[4���d�� %-�z�Ƚ拘��{��z34ڪ�h����{:�1�͹@��ޕ-�Q2p{H=S�/���*��7Ά��f[<�V��ֲ��93th�����
xjy�&�O���|��Q��*����e��E�y/Σ��R�j>�I�������@�������[*��Ӽ^O{'�Dz�Z�)%{�P:���x�Ss�W6bt�ʋ���T��=W�s�K���pȍS�C������-/�Kh��oQ�L�l7���	��%E�u
�d�v
����^O��3� �x=nt�76�J��uT��JO��]]x3��Zu�H�U�:��m�h	Bjr ��@��6���F��^j��Ak6ޖ��� C�xt��� W�"Z��+z���Gɕ�h>t�N�閕Eڇ�=�ή�/�!�3�<{����Ɋ nW � �.��3���ҕ�z���PX�X-���#uoI
4o��\Q
��8]�6j>��N(J�46ZG�*�#�j�%�	3��:-�@�~�,R_ң�~͋;�~��5A�^��5�9��ЗOO���7ϖ���	#ɩ?�%Ճ�"x�Б�����2���Y�x�ݠ����iW�[Un<��_�o�3bv��c-ĳ���zג���|?�C;��v3���Ȓ��������#a�������W�w�_��UT�Z1^�-	`�]�X0��o(,�2�w�U�����`^h�A�E�2���ތ?�Z[�5uT�Tv"@�鎃�-c�!�6�[l.�A:�U�`@V�m7���KRD
ZO�L�A��y�텲+�%@\����\3���Ή��K�f2'�{���S<�g>�B�q\x�W���v�ܷyΙ|��؝*|E\�!���y
Hm�Wę�=�CԊ&�l\��G-�O��S-�wT�ɯ��9w+P�q-�K�"��:��i�S'6��@xQRI}ȋ;�
���	W��������ѫ�V&xU�N��UH|��}/��.]�0Hj���d���:!L�����骴������\#�S����͌�r��K��ȿ@#K��@������i@���x�s�K�ӷ`w���G�B�� *�����a�~�4�h��	3��$�袳�ۑ[>P�/K�ء<��o#=�=��]l�����+�Bj��!e��l��s�f�z����,Sl�[ʅ&�I�~t�������ec�ܺ�!���s5���|�id@�pf��%�Sɵ���:ȅl<s7̟��a�^��\��h��|���2�{7ɹ8�[eR�*X��ce|�j8^t�J�]1�P�Kf�0N RLhr�I�������G�_q+����f��'^"�y|b<�m�������(d������z�NT�k��0T\�}�SX�yԨl�-�M��{g�ÐU��fqx~Ή���m�,�y��e�%�|��d�����.F>Z����4��?�/�5�X�c�B��3�"oa$�����.�(;!�������%�t�;@�7@ʲl*�1,�+"�~�Q1���}�P�-�i=���z���@�}2�KR*T�D��j���tG3'�5��6���>Z}�T��¨o���0"���ʾ�>:�5�:�CX�r1����~3f~$�ס]г�����00&l?���c�XB"۷K�/u�ᎡR��K�O�k�燐C&X*ZF|A���v����S�py	:�˟>P�J��Z�R� �f;)��E8M ���ٿy�
W>���ܪ�	�e���ڷR�ѹ�˅נ��s^!�cm�d�����b	G�ӱ����� %�ċ�Q�����(��%$򠡵�@> �jR
��ͨ��#�3�{-��cc`���I�C������)HFn��Ϲ��� �C<;M�.��b/Q�����Q}�Fb!w��"���!`@�~0{�L������H.h�,l�u�ڝ����{}��s�V�</%�%�� ��C�*qkW�t#4���g������M9��Z	{:�an�״NU��ә��҄1�J� >Xl[�p��ݞ�jr����KN�Y?I|>��^_��� r��)�=m�x.�SI�§f4������1N�f��u�.���.�*������T%��*�؀�g����h���r	{�(v����Fm�l�����=���L5�6-��307�m���Ԅ6u�o�������zJ�,b�HPc��������1�%�$O�_���=�E�GH0�}�}��=뉅z14��K�{�oPw�-���C$o���5چ�B8>FV�R$*�f�D�H�ILp�Kp��F�"��+�v�����B7�x�/,<��Av��tX����B���#���\�K�<r-5�Zݩc=�J�P�%����T���\�b�S�����>2����>w��-U_V^ʸ����Α
!B�����,�;����]�D��O�$�NSHN������S�v���o"��sJd(�6�۪�"�@�%����_7���%�v�X��SyW7D�d>�}��U٩�h�>,�~r�D��y��*I��sʜ��A�oiE�������.��R[5H���if��J���#� �trT�7B�[D�lrD��^ 1V�� r�yl��'�[H�W�Q8q�򙦘E2�r�j9�·T_�)j��Cp�r�x���t���봎�&T�8�|�.���&��d���p0����F'�����6B�P�`�����ǈHs�[�F|^A8"v����Ç $�BA=e���=ԕ����a@���;��Њ�z�(�9IU�[A9��==? ���Ў�!94����P�,��X�� �QC�yę��}�~��%�YAX����`����B��\�� �L]Puˏ(>��F�;�^���l��s���YK�����[�qy�	%���I�LuLCF��
m=|1�8gF��~*��7,�10�e�ډB��R[Ƭ��Zݮ�V0�:�_;$W�6NMvd��33чB��0/\�(%I�PDح#(�?qq5Ȝ=]]ǲq��y�Pfg�Q.CX�}M^��?W�kC��D�e�^ԗ�"���X����YdI�m7M� .��v��Z��2������e����4$g&*�9u)`߳X�9n��a=��}�z�QU��k��<�m��1�a����
��X�'��1������~�M���@�f@)��k�#��2si�� �E����j@ME��H��hنO�MU��B��aM�k�D����ڵ�*SF��C����9�w'��ئ
'p=�����f8��2ӽSa6>�?D���d�♼�4sksG�T�k|G*!�m1�C|vc�g1�~��v+A+���e��jI)�M�����5<:�B*��z��:���?��a%z̏��?B�AN�_FD�٠KU)]>�s���M�6�\Tj5�p��Cda�s�����^xm���@�ݼg���fe�*�Ş*.�9�
U!{�chͼ����v���pM�ep��!&q�Ρ�]�lo��L�r(�|����V��C��Vvq��,A9�!��=�J��y	xb��7��|�Uo&�Ҏ��}M�S!�%��a��%Ϩ=�Y�/�Ĩ��y��e�A͠?c���Z49 ��-�rQ��gE�߾y��>p�)�T/�I����� �nxj�.���-�1�k@�����DƝ�RdD����ek(>�E��| y��*N6˥}J[���֩�&��L˵�=o���,d�zF'��G1߈+m��G1[:��B�X���GTę|�V��
ny�~���ofO���/�螬�%��i7�͌�� C��`|c3+�f�������	Y-kY���$<��P"F/|%���&"fR�J+�#"�H)��Tb��[���!�W]�����KQ���bů�4�c��m�4Kۂ=�	FB�6�b<l	н��{��j�y�7�!76-��Y����i���W�������W0��H_cٔ+�S6g9�|If5�f�Y$lL��~'>Њ��|{��P��MW��������E�pХ'���;P�!8�S�M?H|W���o�.��":��i7`Pd�:����A�NO4N"������,Mю ��C�{�b�F��V�tf�o��[ʙ���"�d�ܚ�̂�`uFZ��L�yD�̗W����3B$�Z�{6��d���k�]d�z�W��aal|=�o�����%>I�'�mx��\�b��ͼx��;;(��Ċ8�A���}�S�l���tũ�
C�=T���zdOj�C��䄳�����^�\�o;D��d��Oҽ���l�������D�<���2����%GS~��C���M��By�F!2�H�	�kq�2Ss!��D+L�OXd��H쬥��7��=Mo��D�B@?�ۖ��7��}	�HTPL/��#4����^-i 
��������uO5�*����i4��:�>Ep����C�_g�������g�	)W�-m����;̓�_w�
���C��C�k�(�M����Ȉ�y���N����𤛤����aa�C��0�ڹ7��I'�-�7vR]2��e�𮥊1W^�Ta��"��G	ͫ�v�Zk}}\��)��F�U�A�1���*Lg�Xf�e]�n�ȓV�h7/ �#R�xfɶ5�e��%*S^<��g�1ʐ2l�8q�V�jy�%$�*L�u���׍_�g����3��,7Rˤgס2����`�z�u1�����I ֗sj���|`F|��^W�tpŘl�:�I�
M#��wB���ns-��	�"R�Cx������i$G(ZQ}~9J��Rf���<?5����w<���\�3�Xk��pY��(7��A]�%�JEF)0��a�g�DOt���`!�EP�ń�S\lQ+5�����F\]-k���ڈq�}C�C��(��IS޹��T�"V� 
�9� O�#�/�@Car08�3F�T�?�Gd�[�$X�����,m���fc�`j������׼��.j�읡���~��ӎ991YD�V�����v~��Ŏ�-'�Ľq�sH��	a˷Wc�(7�~G�ʸh�}����\��ch7Y��]rf,b��K��X���y%a��0n /�n'��;���u��q�l���R�U�� ��v�p'�yPi��oڳ���r���%�5K|"]�3u$m����,΅9���]�H�,L��Ŕ����Tzi�Ԇ�S�_��9i*-Ћ�FFA��v�3
����&8�V*G�1��a�|On��H�-,�Z"�����X?����*C�-]��>di�L�SS������:�2Iu�'�]k]�����~EIp�`p%�gU"��<�~ݠ�U<R�[�~K�H�2�*/wp��6 �"o�/&���1x�dW�g�-]�G����h�O��Xj*�4�HNa��_>1-�`�2����W޻��r�{��x��>�4]_��'6���.�nG�^����v���UV�����kw�D���D�A�Ѵ/�FL=1l��a&�,ZL��fr��i̚*s��x߃pRDL���F���WN�y6�Wx��$���}�m�3u��!)�ㄳ��L��ƻ<s���6L�д?d0��I)��8�&�(	o��cN�R �������B�(̬��d��1�����>�,/��*z��x�]�UDBo%��6��[t��uh*�
�#�Kr&�jC��^��P}�8��/� ��7�����h�=�I���n�_W���� �+�x, Oݖ�l��C�V9|D�ωlڀ'{Vu^�G�,L�㋅F>t�f 1� ^��5�̃�����QGݚ�&hxɰ}"v�,yL��SH����M^P�ŉ����!0��1�?׍?8F�Ը�C��. �����*�!�����0]I_C�I8����+�׳���t���#|cҟ�� }"DZ�	-��'.E�1�fM?��-�a��QF|NP��sH^�6Iz� �mr�%���M��a��4(+��D�ږ�z�^���e���N�����^%���Ng�>�P����|Ȓ֞Z�z�UF�3E!&�T��$��+� y5�Fx����6��Z|sD���ϾRDw<�6�ړ-����(v��D�{��K����n/���J�x��/�ӝ&)��w� &�¸��)�����7��+0閶T\ـ�8(�t��W�T���:ɪ-�Tݙ�D�2)o(ZXE����?�8�l.���x!�d������B�5ѐI�$|=��U 2�j ��C���i�fO�,���^g_�̺{���^t@vS�\ݐ��J��u��B�fk2`^�! N���q}F*5�!'�A�	�U�����˚;��[�������O�{��o�OȮ
������)�K�Y�ǌ	t�2b�����L��}�:��=͆�:m� @l�ś��B����Н�ؾS���N�I��2��'+�=�l7j"}���Kr@kq����<<��׵��>��ih��I��cA���(�-̰
��0]Qg�2�"?ȹFuq^���I�<S�JX�̑�H�SJ�_f�8�	�-�2׸	L����H�"�_�m
�/H�t����w��C%UQNe\3{����'<���z����k@$|�;����e�t:0�{�G�@���+���-,t��(�Ϋ���w.�E�B��}��*��yΈ��Y=c(�_5u��\�]ƿU�G�^"��������"xr���$�ߜ�Ir���ǌ�!{-h&�}O���*r^����p�M�19�7���YIb�NF(lg����n���lEҞ�"i�H� �>�p3�>p���?�N�\�>�D5g)7fC���7�����>�h�lA�1� E��ڿ���I�T�MȯQ�{]�ݞyܢ�NJ�a<�� @o�P�nƫ�� �w�/��lT�������_�8[�&C��4�S�d���U��OcLi���� �N��ͦW@$��%���f���ji�����	�!��6Ҕ�pT6�C OCk���xoaT����� ��~F�h~G� �j�|g��Z����9�,������T-��[��dp��^"�G�#m+U�j��؛�F�i�}J�,��)`��՞>��+�Њp	���^��	���n�k�N'��_��Ζɯ���oZ7O���H8�w,�{ T����D2�G�����l}�x���
�����I$i��`ي(>�62��ig�*��������xd�x56�ꀮ�����|B�j%�xm��7��t���`�TP������[)f��?j�@\Ǉ��K�
Q�H)\��o+����A-]k�SsrXSI:И�İ�ԃ��,�iE�KK�l�p�������T�VR &|[��ȀC��@IDX�rIg��A�N��6w�c��N.v���u��bhq���9�>@��&��]64Snt��<^�����˩�AC׏?���z���p��B*�u4�D�
]��D������#���q#_��i�z�ѿ��La��4$0��X*u%�c��{Ge h�J�n�7@˞[ɇd	Yuw���Cϰ����CL���	�*�{u�����W��0����u���1���"�u[�c:�	��|A�9���le��Wá��CS��;���.��j�DO��Y��'�l&uc/�%��1��1贫��dd�(���q���l�O.ﰈ�!�]��۾<T���
i���rT��F���+��5�$Bj�U����VI.��YV;�o@���5D9�U̜�vzݚ�?�~��<��>iP<J�2!���Yh�6��Y�B�G�|Y�䝤v!W��B+�!��	�B��*�t	�y%�.�G�O��3�5�\5�6pR��;�Z�<���s�*)v��d�ae�)�RN�\�2�]J�]4� �k9�i�a����pe�u��� t�Q>��שk�֞t>� K�, ���Ut*�М!�#�d"��M�2��D�W{&L��HZ._ps���GbsIO8����0��O�~.��M�n~@�e����T���Njצ�[�쐦�
l|�+0�g�U�����ѦU7>ǞEK�]@�ʽW����!/�MoцHrBAɔ�;��n:I�J3"�+�����v~;@,\ʟ���0x����-KZ(4/�(�t�%���4��|�{�i��l�3�U�8U8U��� 䑟R��m�.�Z���
VO�;1[(��L�hHd6�g	�	�*���z��sA�'h ������l���S��	4j��c�7�����ua���Ϙ���liI�$�ʒV���	|0���GA�>��v��ln6�h�H�S�;TT(zp(�2���~�:5�]�7��Mf�J;^/!�,�����Wx��ֳ>�SzF{t��0O�=�����j�Q�zF���+wz=CG����Y=�^��{P�pֲ$i�svc|��M�Jr�m���^,������V),6۩�sՀ���!�ݞ���(�4=&���*��#��w�h��������Ǵ��9^���� �^��zJb��6o�k��v�U� ��ω��^��h�e.��x��YOo���}�fq�{Ꚍ_i�l��x�x���8|\pgN�x�%v-չC9?=f��`�D,F��Gy�wi�[D��Ҹ�Z���sE�z��l=�b�/M}Ļ�/0}�1�H�1�R��,��;$���<��������g^3\�#��	�pߵ?��!��忝����Y��@���̼㔙��3���E@�����D�ґ���6���׍�ڍ��DMm%Mԣ�!\��r*��fN��0'w�3D������Y��[�@���{���}#���EI�Ƀ��5�d���@��{`lKnO+��!�9�;)���B����#1�X�Wp�ޮ�BR�7Lu��Ky�dsB1�n{���n <�J�C�:e5��.���_���&�`� H0�U|�ў��ƙ6�"	���Q�悮�戦��'�!���{�A��;��2�@'��Ai9���	5hܠ�+���x-�|ǙS��PD�ݴ$V!+A�,��-��n���8����h�T�+W�NJL�3jl�M�����\�x�i�"Oӧ�-�_�V�8�B��,�T��{����X�j,�3�`P�S��I|� IWGESav��h��\�9p�7��8��ϴD�<G}Uֆd`U�M�)8�<�Q��U�4��z�yͯ���I���g�$��?�z�qq4��?1R��nY�J}$+���c��N#4b��7q��EGɢ�+�`3t=��L�n���vl(���'�@Q��>5K��ꙅ��m1C�[�L��8ɏF3nG�u*�F!8B(����&|H��s�A�l�wdS^OoC�Ç(��u��wc�6�[�h1���=/#r�w�U�O��pi�4(5�Я�vEb��Ϻ�J$d�e�!:��!���5����H�,	�-�:��	��u3'��ZP��寄�Ts�j�绥��'e�a����
�lަ���|̦gI��w���Do�����^?/�Sx,��m�lC~[%~8I���L@��*҂��S�v�N	r1Xj�cIEI|a�����v&�F����m:���͟�v	�UQ��.�훜@%iX�e��T=�L�,��>Y,lpڮ���Tn���`��:�{�[hn��ّ��E�
�鲳��*r�Ⲅgn*Jo
`l��iN6�á$M������E�=O��>}��AY�T���ʡ(1���%�����Vmǘ����(��$hU�c`�dYS�) �_�v�+;�`�=C���n?˸�����e'%ݡ����>�6ff�dw�����4$@�r�b���qԵ/��c�A.���E^�?@Fg�L��G�.�&m;n4������:��Ч�q��u���D: q[˛,/M�A��A!���=�����^l��1L��ha����X�\��	�96���M�s�~N�y����k�q�������
�`c�v�G�d�m�O5��� e���XA֬@]\ 
�~��-y�x�\�s��}_�0���>8I�T3��l�E���?�p$�`�I#��>Inf������+X ��'�{"�p9��0~�s-��.r�@�<�EvD�2�|w�I_ŋ�/�u-=��;�_�T��K���Fe7X�{H��\��?<h���3�y%��V۔#._+!0H���"�'K��}�����wȯ.m׼�D������������īO��|���P-K��I�CD�A�w���:�
��t�T7j�'\�x6���a�&�6[��p�/��}�Pp���o��+CZFD���JeⅸW�Dq�PG�y�!���rFPJ"��,l_D_���l���� ���i_����*�
��gP~����-�����Th���������Dٿ��D��)�	ol��G�g�Ŋ�xJ>6y��j�v�$�٧Bד���J�wr��o	<����b"�9��{�m�+w���.%�e|L�?����@�Bgl�y��d��
}���#��d�V8۾�D�aAOW�_g�����$s��1.{��+6�+/�	�5gc$���J��SCt��PN�H�;T�5��T�_��x�;����@�]� J ;���A�M�$)�!uM�w�Cܙv��=8��]{A�<�C���whL]�W&԰Pe^!t�VZb�%�Pb�bZ��@MsT5�Y�Vӡ�BQ�l{*(�4�
� ��^�6�SE	:X̹L���Q��Muw����+�5�u�������wɹ*Vy,��k:^�~u�Z��A��|EH��,v��o._Aqٹ�(�v_Ђ��U�3@�o�07T}ﭻ,}��ž�z<�!���:�����qӊdR��s�/�>A����,2�~�w C�������)�2�c�9�A)̓�ئ�tf9%1wb���5;���%D����/�'�����2Dyq�#&<U��}Z�8ل�)!d�ˏp��o��!6�M�M9��ʌP�{��'�YS�.�K�]°b)<�� %�i�K�D���U GX��-H�>�	K�k�oX�{Sf�$�@w����I�p�-2b���V�����=��ɘ�5]N�.*W7��M�"�ǈB�� /��[{S����O�{�Mz��� �_�9l�g�4�g@�`+͜�8o�+2����_([d������n0��E7�ɇ�<����\��wDLL7-6�LQ<;�!��]�,hw��%�J��ovI:�琥gl�
�Ad��U�& �o���
����T ��K� ��n+���X�]��������.B䬐^#v6��h?�[���,�Ȧ��/��ǩo*��a�"�0������~��<]��"�h墾P�$n@���0TC��L�V7�*-��ց���i��o-��Y"Ǵp�x6{ږJi`Z�}��0���	nl<q�/<�k�p�T|=�l�(A���_���i�u�O�Id�L��NЖ QゟQY���.x�9�R߾��Rگ��0��܄ӥ0!����aN+�:ZO�8���2G�������p��5���P;+*��9��sPfj·��8�����D%���+e�,�=���%��]���6��e�|y�?�Xɖ���ܨ��G3���Z��w��O�1_2Z����b�<��`�G�z_��T����&`�U	C���}!BB�:��M+^b�Q�4(�����1t�J&�:q!|�0i#	���v�1h�W��}vs�S�C<����������^�"*�E�H��v�9�����X�S�t �@�y��D5<��~n �'x�%R����&p�G�^�8�KrU���_T���g6 ��͛S>��mZ��u�7ɡ��$b���
IY�iH:��J�ᯥ�Iƻ���\����"�I�?]�qᢢ��^�Xl;�'w=w6����,+&i ǟ�J�^o��o�^9W�x����!na=>03ߋ�Ȇ/�N#hxӵ����$u�h<iMFT;���L�dP�G2;P��r(��M�5�E��7��yƦ8��,��2��S��sAp��҆d�B�S�S�����.G�.4Yr<�m�{�Fxz��Sj�w)�i�~r&�[A���q�z�%s?�?�u["H�K������/"�P4K���
4T�	F�A���HI���
�-�ȔL�7�R����<��Q��">6���ر�����P�9`���I� N��&ej1�ϧo��Y�R��`�O�~M����:_"s��El�q@��^�"�A��?4W�4ݞ��������`4g���6���DW��;�R�?�D��n�⁍�o�������WE�4��}��T�I�5堺�lVU3n�d���:�6%O:�*�M�ٞ�=��`{R�X��5ӣ/)�kU�����L�s;1����/RX��a������o|I��,�D"iY�B��K����� ����b���y�v���Ka>�n+��y���F�4F�s�'^,����׋T����z�j�6����E�<d���)g$�\��h.��&A�w\,�]7[Sp���-ȕ��]x��KQc��H�y�\�Z���؊��ק���e`wD�w�u�S�-� &���@޻��������Ġ�c���#*=��^��B�i��J��S2�����Yп�W,MYm?o��<��{��"�����1�8�1Tشˇ����7�j�����n?�T������n��1W��J�J�f��|3��D�0��0I�^��T�fz#�����XPu,��^��q�t�w���8��gI$�Ӈ�¯��oz�+�}��WD���F��dt����mc�Q U�˕t\K��ˑN�����
���&ש'������^���.A�k�4���N7��<� �O��i��2�P��@Ư�x�2�Ҧ7    �/'��y ����^;5���g�    YZ