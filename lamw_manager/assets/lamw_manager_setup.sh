#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4281140487"
MD5="a68eca65bdda7135ae40d9122f9eb881"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21275"
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
	echo Date of packaging: Tue Nov 26 22:40:35 -03 2019
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
� ��]�<�v�6��+>J�'qZ��gZ��^E�5��+�I�I�%B2c���l��}�=��>�>B^�� � )�v�&�w�����`0�o��돾���g�����l�!'�G��;�6�7��덍��Gd��W�D,4BY��^�wW���O]w���hn���������.������#�x��/��~��mW��L�j_�SU������-ӢdJ-����f���c�#O�����)Ֆ���Ħ�7�#�R�����F}���T�a�.Yo����Fc�Gh�l�~�P�3JTY�Ub3�AH�)	�w�5�_���N�g &�� �\��ӀL���8��f� JN���_��
��=�}�����h$�����PkOդ3:>�:'�a���X"Y�\ou�mCM�O�Q�e�M����>���aw�~�f�-�e��9xa�(W)
��� +�C
����^pU�;ls@{J����{��׊kQ��=�9W�����`~���ƪ����9;��(S[Y��Znp	�
�a. �x��j��QP��7��	l�2��t��eO֮�RIx��s_�C�'�;^!�H0_����	[gtrN c��/ĞE�G�t>��Q8�)�A��(P*3$:'�,�"�����a�o��g�[t�����T��D�1H#�MXLeY�֕����}��3Ƨu�E/H@��)4��U ���k���ə2���&���D-����t�����\��t=E�ߐ*�ρ�$�,xȈ;���7X=����2������4E���9�S�x�/[�)���iBeYk�o�]��l����ŷ�E�f�k
�4�杚M$|j�R֞�J%�|�O+g�y����Ō�|n�|N��^�	���w���F-�A�4O�/���ڲ����\%��e+���Pƀ*pD���^�!����^@M+����UD���׏+�+��u���
%U*�$$b��I�X��b��V�m�1�s�vSJ|�du�y���T*�&����Se�C�����&�3
RN�"+��8���5icɣ�����ph�32�88�V=��@�����2���xV��7�m?{�����w�6)b4g�v��:����x�6�����Rz$����a���t-_ɧ�b@�[������A1����Q���������VA�����?3��V��Eg@:Gm��u���Fl��V��sx�o��U>J��^D���1x/
!̱y\}O��l��IB���g�Srf7���XXϗ��{����d�A�� r��<$������u칍a!�����un�SF�)1�Y��32�9P tM'F� :��]r�>���dX����STP����ռ��i���rd��o��G�gf�ƫ(S;`�9�I�3
���w�a��7}^gє�Տ���5�?/9�����׷��_s�'Xx�Ƒ�X4������fo-������P�����������_�{�䂄��&�>�#�hķȿ2�.x�AQl�"4�ǋgD'�f��bgK#M�
<��J�]�Z4��Єw���x���ԟ�i�i���H�E��hbYn���m.lʋ��|lc�K��A��u�Rq�	����8`Ԟ��`����]�ay�a!?�����S�t�aD���O0�`b�s�ҋQ�FN�x�uo�;���CE���H�̉������Yo�y<���,�P���-��4��A�Խ`�M:pQ���P@<�5FU�XFG��^s��P���c�q ��J`���y '�>�Ί(��vs�6�['~��:�#^���k�H5�:�����u�%mݺ$����$Y��;#�4E���Һ���HAi�ʋ�a��S�?��@���K�������?�4
3��.x��hN��s�����?{��+On� 7��Lm�E�h���/�t9Hj�%�^�^��Ϙ*^�+鮄��%�K�M��ř=9Cn��AU4�Z\)Wk�A*1��.���c.rT[5����2�_�*�x���ɸ�B�K+$���\Y��$<B'����'/Ijȇ8
��9�r Y�6�m�AM�F�p�륶o�iOor�㣘�ϝ^|d�u�99}3z�=ns�`g&D��<�tH��N���nKf���{U}��~SKV�
b���\^//��m�r]�B- �*zJX�Ԕ'9s�� ������p/���\�@^�X� ń�+�slja������tg4;�_Z��-R)Yw���2��W<�4XN�?��2i�NG�f��=4L�����P5q��#�ti���H��`��WϚDkM_�^m�$�^�}�yc��T�|�1�R(�%U�Jv'A��i���4�ȁC�ZQ���IB>�f�	K�^O�J���?���>��<��q�x�L{ѽ90i��@ˤ��d��]�t��ͣ��eC�[��%�����J�_�������b����/c�2�|f_yY�3���V�A�� QI�.�B3���l���}Y�vK�}=0��%��׎K�^F�m��~�=�hR��G�9�	���nʝ���6�S�T���C���:\D��d�͋�{��F��6�;�dQAVnaf���煃00}�l�:@��Y ����6���Q�pt�E��<��w;��X�
wd�'!kn�D�%jP�g�P����9��<</��җ�$��*_I����˲q�2�(&=srnΨ�������Qj[/���v-z�/�$a �]#��m�������ʄ�U���/�f��M�Q�W����o��n�,�����=���\��c�W3����Iz\��K$����>e��2{�P^���7w�Q��׉�Jx]�^�:�.)00�vh�sD�P�q%��w-�:��ڿQpH����?s��` ^K\�`��\��3�� �	|t:����K�"j�'�P�U���i ��&WA��=��l�=��,�	��>?�$Q��|�|�!uM�����;��s�?��pJN�~�ǆ�Fl�~O��a�ڶ^Q��h��U�d�������mCm�����a�{�3T߉f�W}�>&��Q*���q"?K�^�bJ�	i`4X�5\$/c�@��U��P,m��_"{��b��r��1�RPr[TR��O���o��F4����������G��\N*B��"��C��g@������l�4�x�4��������m� @H-��%y�����J~@�7���nRslkq��SK�Vw�s�w��՜�1�V�L��6i�1aO��~[N�y�!n�/�=ρ\��������P4B�.�E�!.�U*���(�5�g!���	b��rF�ǟ<B�c��y,v	��s�~�)JV/�"�m!��f�q0"ɉ���
�qd��v�"s&g��m��V"^x�w�Τg 5����숂LLp�BsAqa���5�~03=���C��B�7��$��D��S	I��q��iY `=�9z��C��M�X�/Z�câ�Ơ$�(�b����h�T�>�qR�]��[;�7���9��c�W��BL�>wL�w"yg@"%�@��A<�E$`�,�Z�Y�J��R�wY
K�-�u�W��B�y~�J썑N�&?�������G#qӐYˑ܁�lwdBРh�Ay����}+n�K��\FS)laB^]h���	��@�j��@#�!]�8�s�I��0�q������|�3z��(�n�惙�G,2�# ����ċH�R#y2|+3k��dv/\4'���Ѩ�:W��m1$�W-T be� ws�ƎOT�F�<��B#"���c��-vsς�����bo'V�ُ�n�O����0�I!e%�T1Μ5��)����T��:㵬��D�ʰz'�
�!<���5��hq�nB^�'$"IT�w7�$��<���h��?ծ�s�>}�g��0��ġA�%���o� �7JB���$Zyl\q��Xֺ�o�θD��(�1y��h�\���Yr��ɥ�%D��7%�bR�2@iȩ�⒏���t!=�+k�'jǝz����(�b�[,ݦ���ΙoNh���������.��p���bֹ�1�?���9{���wh�rq�ݣ�����B���d��Xz��1ƴ?��A0�v�G�j����Kg���/�ԤM�y(l��1���!��d48�����q�(�b'�ljhwkO�k:0"|�"�!S�0�{��J�_��%LM�*�t���_G7��o
W�>B�޹�ȗ�̄��2�z箖���rsvw��Ej����,'g/�U��_��w.�l6� :&ٲ0��S7"5cs��w򎡭Xr�ŕ��;�{iX��|AA���C9�R�h�=��B�Y��s߉�S�'�s{Nu_�Xi��ޣż9�mQvz>��3�v_4�6�<�^�.�9�F�%jj��I�����%���@E�i �s3��DF��Ĥ����3TY��k0��-'%�3A�����`��]�GQA�F^�]��!�k:��MW>5�پ�lh���x�`Hu�=�moB�!��×{���=.�	��k����-�d���c�NNVH/C�Rw��S�0`��dX�D���v��!��`s�%����H�6by�<�3�,
�:�X�Kz��b��-���:�C��#8�=���<��B��C�y���F{���N`)ھ)��}��=1���L'�F���h�n��o��ھ��I�N���Jc��m���'��ΰ}�$��:�y����KR6����}��~{�r����t���MlST�:Mߋ:��_��ޜ򻥦r��+ҹ��Yd[�g����*إ�A_?�NMJ[�N�f����s�,Q�-��ᗉ�GB�"�9�	�7���ކ�/!g�;�tx����~�HT�Q�5y�>��%J��=����^��=��ݭ����%�Q4��?˟
���>�Z&G�2�R����ܫ�a�ILX	��a̅�D��x�]�����ةծ����/�������:�̹1)��A��;�Zn~�T5i͹�b����9`z@'tL��`�{��
��$�M7(yr�VE*Y�u��[~=�I�Jl,b���O8��S��F�����O�8�@����l�\[��S_�`�U� "���|ON\� �����L"x��OѤ�^��ˤC�u�1+3>�����=fƝE���?��&��.-ܿ`ޗrH�c��υ��0�<+�����!��D�m,�=q~`u��A��ښ`�vx�a��#ǉ��C�4w�%��؈�0>���Y긅r�݋P�F2�_�9�>u͒|�ؖV3@V'��w�wՉ�E�\�?���G2T]*c��P?S�},���uŕ�Z��3�O.~g�L���+�����u�C��9�Tˣ��q8QKX�J>�܎ wI88��X5�x��:�2a�y/�ܽ��Ȳ;�Je9)Ũ������!jsj�-�S-����&���^������m#[s^�_Qّ�1I��/-��-�Q��"�$�VDB2b��@Ɋ��/�t�<�K���3����w]PHJ��9gȵl�@]w�v�˷��T¡��')N�Ve5�!�6�����e�Q��m�q~�����ռ�t��ҘѤT�����J&��eK���+���#=rJ��R��V
zT�Axl�
�B�FZ��Mz
pI��̮��*��Q7r�Uz[}=�E�9�eB��Iꅽ1�pCG����_�d���ax{Z���o�h�ig���"`�+_uO�����ioWW�p���[�3�na�l9S����j�F�:��A�9i������\0I��(�����)�n����b�g?�+�D�rbC�9���+�n	��W�un(�1P��
iD��sN(gTM�ш�B[x0z�5�7�T-"݌dƍ�F�!�	8�5=�֚T��R6��z2���^��"����´�ᦋ#9�٤�KFI$�5��`��Ӣ?�/��G,�|����Wq?�%��}\\�������`�ǯ�s�V��r���5os}?�����Q�Ӈh��Y���#���ХM���Q��Ҋ�J2yՓ����/Z�\N��`.k���@S�#��{W�أ���;��;����?Nx�ñHA8,����UT:z�=��2��k�+���
*
e5aΊo?B���i����'C�	�\�M�6��;LG���aX�.���$��?����]�F4)p�D1����H�L4�I�h�������}YR�_���`HD$7Fc�s<��R��f7�I��(F]����"�Yz���L��ȅ����'������m�q�/�!���M$(뼜+�9�g�npf�#�]T:+��	DT����T�%]ɪ��������#�����m*Xxf�[��*�S֤W�O�Á�&P��^3XzB�2��sy��p ��?Џgu=.H�>!n^ �p`�����w�q ��W���>�� fk�Rſ��(�2G�*���'g�Rl$�1n���酘mX��������)5!���]D�����D�&��kY%Mݞ!)�)d(������ ƭ|����` y�[4�XpѨN����覷>8�fT�t�R\�N�:"�P+��_X 1��jU�f"I �\5������Є�;������X�;��a�o�Y�
󼘸,�������*)�}<#�
�{a\���!���|:pk3,?P#���ǳ���Ӌ�W~��9��"���=�}�:�q��nn������t�����@���<�<H�8��`?��f1�A,����,�9�s�����а� �H�	��O$ɽ�%�vP���)�C�����3��u�''{�o��)'�b}���x2��3\z,�qޙ�ѭH	*�5��Ė�)�S��9[ɾ`�0��ݸ~V��b��K����q>붽Dr�߆������udq:���.G�Ǒt8��ot?�FYo#�=�}�:����<ߠ���>Bw�+|�����܎2�٤�#e���Α����Y���g~���M ��K���&)�v�����E��=�w�����I�^�慦]�j����O�hg�G��"��b9�K�S���u�t�~�����)�l���I�I��0���1+��S|�����U���@c�};�$�X~�����pĽ,Gr��z"̱*x9��T^\�e�6�Z9 �7[�p�~p��]��c�Dk~ך��W*�>{2��Du�Z�]&�����睝��҂�ѵUI�b5e�j5(��V/��V��d^P#W @Q1+��^ �)'��H�$�YL��|��~+���V�C&���b(� �9J��JH׌@�OH��5��d��P	ȖN��ޖQI|ߙW����4�����#c��TdL��_��b�*X��3V�n�\�7�1�Ix��q9[Yi��}��_��X����ں7�~8�M�垞��>s��z��/D����=�
�p�&�G~�8����R�:n1~��߅#�N07ua�&ſ�WH��e	"�o�|UVў�f~^���^=����nY���j����`.z^��x1�bs����ZG��u��0m���p�ʪ�,좺.�sB;�q�'(�5��Mg}v&v�
�����5F�ʍ�f
���5�`\��p�*`����C����y�X�c],����#s�1��a#W
'�����g|��hp�4N�)���k�69���ų`�MJ�F��i� ��%����`۠bN�x~+8���&9M��E���������֬!g�d���Fs�����X_��X����J���k�͂�f��s�$������0`c�����y��(����>��{��rYZA��/��������g��t�Щ�˫}�]>e���ڝ�v��r�mlo4G+*d��N���_�û��]��%�_����M������w"�4��HVUcy�3ʤd�F���6��iV4�����^}�E�ɭ_y�rc0y�G��ҧ��q���^��O/�
S3�gUV/"t�\g͉�w����b�z�0�;S��_ƣR�V~<��ͩ�м�ؘ�9e��G"�690�Q}OnwV��?B���0�#�dNy:���&�)�a� o��1�Ud.݀c�q�A�ǚ?��}����v(�4唫$9xx1y��*�=D�A���n�(�d�A�Ӂ���j��X��)�Fc8ׅ��E8X��G��ɵ�C��6
�V��+��$s+��R8<�f��(4+�	+�kF�P��EV�u��9�]}%y-���Wx�#��^t3NJ���M��H�>P���4�LZ��ik���E���
PE�1\��.^qIt��B��7x��Gku�6��*CD����sO��"��hA���ZUZ�_���z�}Zӡ�E
���ElJ<rM���C���n�W�y����ꟷ\3�������8\��7������f�Uid��GH����Ks7�I[de�=��;9i��v:���a�bd(T:8��A�vC�R�-�3U�=I�hUr���>6���s���d¦I�r@�(�np�ʙ�{�sa�B-TJ��9��hSI��n�%��#��NU��¢��d���x�ǨT��I�+��I'^����z��9J�E�0Ж��M)��F:z��	�jU��Z���ҧ�`�uߪl���g@S�h�>\2��b��KQ	��%�%�m����'��#�'�{�z����Ȥk8<�@vG����( �~�1�=�&G���{#�!�8A7/���������T'i��86MfJT#�9A~^��L�,�[�����X�?��ӹ+�,��/P4)Z`�n��)�˴����?J���w�-�|����Y`\�pj���C�އ���d6�Q¬k����:�����gb��玜�n7��V�eEe"Gjh�uu�}Q@k��hp�����`�)��Ag�2޷���mK-��s�F����	�D���@l�7
ֈ[Bcs{n"�&>�(�J�!o��l�xP����S�2�U���1>�_��B�D�19�bds�W0�~|6n�u�w�V�)��&���;�B!�)�	��q2�N3:���~���F.M9L�?��u�˳�^�*��Js�>�Va�|<�7�+߲�J:E��lI#؈vN0��ƍ�� j��< ���;�n�dD\˽����y71�4蠬q�01�����C��	�y�}?������(���ޥ?��3���k�<@+�9AXF�x�K���7�}j=7i�ñm���M�T�N��ヷ�?��������p�\ "0�60��c��_5X����t�I�!J:!�԰g�"{1��}�	�O�4��B���jl�P���{2L�>>�'#p�Q8b,B��4Tc"&�j�&'���ӱ7�%��ֲ�{�t C�"�P��R�p�SZ=��@�ȏ�@�م�*���QI�p�<��b�.�o��Qy�#&˳���/|s]�W����O�9/�de��g�&�H�F%�>-�}��?bN�����<~�����x�x���,��9��c[�W���y%c���EA*��@����|����I䣁2����8�@��u�:��!2h~��Pˎi�����H/�-9�U��8��#W�����9����	�&&�򬱕U�.$TL��&��ч��C[�:A�f���\壥8*��lZ��&���'�=�E�<	��9�;q�]�A>D41�RtK������Q�-��R� a�B,(b"(�f1-�^y�KS����l����-�C�P�+�l*�!i=���5UB���s�P�j��jHi��]$?# -Y�&��$2盽�Ó��b�ٕ�y����v/�Ɯ�&��tc��x����?9�fNɓI��Yh�F�����t��x�F����M���Y���WU�S�H�xy�����?ƫ��~������8<�P<�r�a�V�/C6	O*�HZ�UVYE�6��5������^(Sx̭��; Nq��b$��*����U3�ҧ/�d�SU[0�\
��f-SPE�	&%2��7�[J�JF� Y�+�"�e^��4� ����8Ư����m�A}p4�8�⾩߫9]b�Ϳw�OڝÝ����*.��m��ߒd^a9x=���fD���*�Ҙ�Z���;�fh�	��s�:�5�K[��QLr4q�.���%�����zm�$�C��v{�wz��[O�V#|`��y�A���G���Lt��ދ��t�h5�p�Ϫ�:�t�n�oW��wI9��^����Y6���n�y��#6���)�*j3$P;�	ܪ��']I#�z�M�NNrWCC�����&�&~�3����a�%L ��I�[(̘Y[+������~�}�]��j���A[:!O�ū�����xzf1M��M@�5���C�(��.-��P�����"Z�9��|����c���kc\'���L��7����(b�o��rl2SW�69�*v����zwJ`��ag�h�)"�����4�����s�!*l~�F�!�>bA�~�M������)�y�.�(!�yɻ�������o�����dƔbr��J��g�*�P�%D� P���KST8W%�j���!s*u�Q��֮�|2�Բ܁�up�*&?w�p2�mFmq=��wJ�i��t���n��t��4��] @f(����a�Q�MM��R4��m�k�Lj�LYr,;�Ǯ��C3ę�S<�U2��V��?.k���a�M��^�������)���o0CĚ��P�C��<g�t�ifM�jH�Nd�Ā)R8"�c����C[��=� yv��5:��-���m�'E�J�?�U7#4��,��a�'QT��.~� �?��L�z%��j��Xy���9�~�0Zj'�2/�m4{:;蜭i�;E��͞�b˲�;�mkuT��^v���P{�p����$��� .�X�AN�A���#?����O�3
�C}m��U1�G��uM]�ؐN���sM�m�A*s� �&�JF��l���~K7�*<���E3Ş����*�%������GĆ��W��n��������+X�:��8�]s�(�
��Z�K����ի64]�փ�Ý7�N����V�[X�m�e�c�-h����-��}�l��vf�sj�G V�^�6����FK���v+�/�������V��m��-�9k��Ot!�`�_t�=1�4%/.(�������D�٣ݪ��P&�W�V:���N�]�<=C0�k����^A��AA9�d�`P;�YJ)jut�� ���4M��*Ae֙����5Ktg�qf���k6��(�(�J���Ҝ�	�=�����f��>
����R��������+Sh�\��x��Ж�x4w�j�LL
,l���v�#;��@.�x��/b�8�~-�K�1)hN�(S��<3*�;{�EޗyЛ�	���F�C����kK�/\�^�V���GW�}A�Y�d��Yy�x���0֌��aY8�fa^0��7��ų�9_Dl�h�����qFd�
b�`zC����bԇh2qD8���W>���YMv�->��y�д�}�(sȉ�O��j窀F�l-��h^&�m%U�*�[�n�*qc������89��KS}�Q�d���i�Q+�p��-������^�<n�	#5Y3+�-\k��Z�V��f��Hl1N�RϤ�~����	�	C	c/D��x�-%ӕ
3v�� �
T�+gv��!O�s��;�m��Zge�&~�WR���W��qc�&��3
B��&�d35�a`�y�-���+��>Ʌ؀���`�sU7��	x�W���],���Ɍ�&g�ҘMv��+hېN1=B�,�5Y�K6��|!�^BZ�A0|��0����6�*|�{�E�I��h(����c�7�������`b$V�Љ�y���-7'���茤�2[͸�f��E��L�l,j�@��⬛��Bq�ܨ�� ��͝�4����77`O�3��Ԙcka͔l������`�l�P�N�@1��,�CHɌ�L���V�<G��U��{�wx����1|l��)���$��9��Ul�2�"=�Sm$�*���9��t[�T�j���c��+�H$��@�s�)��5ך�Ǯ-��a8���v��C��D ��Lcһ�JO���	k0�֒��-�8Ϳi4"賓�N�;wn�6մ4:lK�8��F���}��$�V��t������<@�ҥ����\}a5�q�A`�fĊ�Է/�H�p/̜i�7C ����}���� y�nc��:sE�
��G��y0���LrD���!GD� l,�1z7Ų�n��c��Rs�%��ԝ�J��či�o�k�����qu��|4�ۻ&V���D�{��"t�����9k���{�>q�Q�8����u����޾@�-,�� g\�[��Ӄ�nz�8��%8|k.y���y0�
#-��؋��I�+H`Q/������Z"͡�`�u�e!�m�(.48��ۻ�lL{Df�X����L�I�.4�f��'�٨_)�b�V�Xޖ7@�#?�*��Ue�\*s�|�Vƙi�uِ!G�U�\�hfdHY��DL`��J����~f�q�N�~dh���vnv
�I���Y[�����x����J�f��^%��g� ��O� �6�3�7X���U��K�&���r�b�/8~��'Uvz�鞰�c;CMp���F�{�����q^��xxC+¤	��<�|��BY2��8�u!ཚ�-聶�>e�/J�,Q�Y���Y?��i��Vٳ����뱦��J��j���s��J�1e9���`0�Ŝ�L�|��
��x��2.��'�+����Y�5��Oq�?Ћ�	��j��u�Eh�c��W��+}�����)���(g�HD<;#Oe�7k���'�\��N���[�����5V�
y�_�C)���FA1Lā���,,SDU.ˡ�eIG^�XMm�Q�Y�/��u4c�(�`�Ԩ���������z��#L�]gih
3��I��`��G�3���=1�d��\ w�`L+��)e����k�#q��bb`0� �=r�@��K�[B(�(!A0 �H$� 1N�!e��[A�Rܧ�.0�ʲ2*�"қo�_)S���6�F��A�,}���?�?ZdC��#/�5��{�Ƞ��G�� Ņ�3lx�'c7�^��=��v�,���[�g\�Ү.����9ic8',�nז�L[n٘My?U�k�����0sZ����m�G��0W���8���B�^�X���ί�����Nm�h�ѧX��Rq�~�v�g����M`Ŋ$&D�%Yӫ%���[�Q����ӱ����frMgP
��)h���dO�W��Tz��5�ؑ]��ݪJ �]�v��( �����}����ʡ	$>��~x)YSkߣ��.�|ˋ�l�Q��r�+�v��1�f,��L�s]�[�]ZZ�Jwc�I���N�s&����yN��|��V�#���ۙ�bv3x�/�Jf���ӂ7(ω�/we�S�U�Z����d�Y��ĭ�n��m��Yγ����\J��-%uf�@V|�u-��3ө�0�#X�z25-�53���É�9N3��vq���kY�>�5��^
���&����S�q�|�ѳ�@�s����;5�ӿ��7y�<=r�u��؀4���M�`�&p���ڞ.��7��qp���j路������
^�`��b�3�\�#5V�7�Y�6"�W���vy���95��"!+��>����D�?���B�0-����G�C":r�Z+��m�cc��v�Ӑl��G�sFN�̝tܨ��r#��0�g�(�+�	;6f���ڤ��$�2�(��؝���;�[��p�Y��8kvE�s6��C�Ix,D�3��1��Z�2wl�2�K�q'�DX��)b;C>���F0I(O��%���Ǐ����f>����m��v[���x?}+���Bq�@��Ys���ؒfj��׵����=d��G��%�]�S�U	�R����ް��y�B���gR���gu�)A���C�O����;����Q$x�"*|������}K__�w�1ga�*����U��}�5��*\JѼW��z�$@?Pa�@l��K���e��UFt^�#��k�X�!�Q�#�:�qZ����T�G�,��ժ�Ρ�؍�� ��kVDR�?_<G�V9j������zf��T�;�da��f���������������a��<y�cP�t�/�j=I��
�\���/�-�	�q�$��� ��J��嵇����F��{^�G�E��fbE	���N�^����.�U�q�7UDJ_s�����d�WKI`H�_�<���#c�k�┅8Z���.=��������9x��><i��r�-�W`����<ݏ���>����v?������A��������9���X.-��������>�����d�l�D��e�,9K��k?"�]o�Cv4��D:%��QJg��-ࢎ��1�}�<�k�d�����X�Im}��ts/�e_p��Lwxi}J�C$�@���L��ݖ{9F�U�Z���&@C�S5�
e���z�Z׳�`����-��p���s�~+�����G����yE�"�\�F�[�b������1���Kdʢ*b��k����Dk�m�y��Oj��W�^�`�Ӥ��F��̱@���m N�E�Y�R���{ 7���$�͍���~��J��'��B���s�&�QՊ���\�k�����V�'ѸϞ��l��F�1wͬ|�fL���I�Qk�N�Mg&M�:1��\5U���-�3��y�t,�����Hj��n�4�b�ޓ9p.kN!���6�,�����,�}�X�Ou���Y����g�o�c��6���팹�YG�9��n6���=fw�:�sԇ*_:U���J$ۑ�Q��Y���Y?�G3H�#�{�e��������h��g���
$L�-�3N5�=��h��
f���n[��	�Ө����B�04/��.�OF�Z+w�+�ӎ��'����HY��+
�����>��)���r�><�흴��v>��MPWE�	�VTX��I��Z��m����υ��_�8�C�A�K���vk�/�t��X�S㡪��[q4_�t~�0�5o���������ҏ7E���q���E�Tѐ:[ŧ*�������g��}���m�!敠(��}"�81]���٧R�ޯ�S�|o�
��)��"�R����)�sF�zJ']Ƌ��Es"�'���Il 礇'�gO��[�+��p3g�~V��>�2߿Pυ��g2	1��Jm�a�G,<��g��#��`W��^�,�ä��G��ոv��ă<C"*<�����2�g�#��2`r�xk��K�{�E�LaӔF5���y'i�F�ƃ����{�)�,%���q0�$�B%4j�j���8�mp����Q�������}�P�%nQ��x�"���������HqSҙ���ꀮ���_�3�`�G���������~��C�+kNYk��6n�q ���W��;?�3�Y��Ol8�Z�/5T'\m<�Fr��(\�Ι\L�#���EՆ��� �pS��*�˵��(H�.a-�Xs���g��?�S�?g{1��pQ�^������������r�����n����G�q������'�8���X�'���h�x�h��p������~��2y����I��|z�=�{A6�/X#�a#}�!���K�ko.����&<7.��d#�F�]'��m�#<E�6Oϯ� ����>��5�A84�ty�Wι{�sv	�(Z%���]�96�y�Fʌù3�K^�.<eB�a¿�E�d/�>�$x6�U�+
��g�=��۷?:N����E�_l�U2/�F?'{0ž�ك��c�G)�尞
	ഓm��v��MC��w(��w$�b�}�<�n��\�D>N��O�$��������4`_�����H�E�w�"?+�n���5�9�W��-�3d�*��V�J��B��t6�F�y���h:�mE�����}��������
�}��91	��W�o5c��5����J+�|d��r�m�Yy��}�;_�a���
���v���2�5s�9ɦ��t�}L��.X���SY�]�������\�Bu� <��0��Ss�4���l�_�յ�Ew&������i6����m���Ik�F�����fw���
����v�K_`���oƉ�a��pL���$��g���G؂�w=)>w۟ކ��+^A���6��[R��&0�M�������VC��4���������ě���֘��3+H4��_�1�:��������4�e�K�^H�L�J8a�OG�H'�,����'������o�ͦ4��8�q@�Z�|nzTTK���t���}��
9k�2��n@'T:Nϭ����e4gv1
�à���Ydd̎�Z�ʬ�l[Xn�i�n�����G�-�0�R�O^�;��{h�K3ג���X�5���2�5�����i_��Pu��������-Ƌ;�]{��Oc�"����X �J��)|x�p܎!=�%
�������`{�
C��	�F�N��6�R}��q���s��/k���x�4o���\�-����� L��w������&c�*�"��\�%4�p�>�'u4^��g��X��O�]��'��|��-�e3lI�E2 lz8��hC�#�H#����ah�W�*u�KX.�:�q�?ꦸ։���|)�L�s0i�����?'�d�Ho^�Ȼ�=&U@�$4+�3��䃥R�AO2:'H�ԟs<g����h9���������L����'귲��O	K����b�V���Qo��� ��Ӟ��b7�=�%"6��iQ�՘�V8�jte�ѰE�"�ɡ��M�u�)���=��;}t�V+s�D��9��ł�$Jˁ،X�2N�|/b^]`�\����d�[���.PL�QQs�d<�����|���`U.�TZ���	(�tm��\^��UT�VE�+h�'�`����cȢ>�'���'Dń
��<�jM��6�My��9�j|����=af�L6�Hb��ȧ��;Θ��	ï]o�nQ�'�-;�%���N�%�}I	{4)Y��̀v%�����1v�P�O�=x�W���+�ik'C�qMw��Bk�S�iQbNc����g^0Igr����fW�S`�a��&`=�Û	T����G�o��ķ��-�ɺ�j~♀t���N�6����k�����b�=sbf�)T���@�z�2/�E>M8�=�D����;$p�G��ys�k3	-PCs �*(��ۅ�q<H0��⫦B�������E�֝^�խ�S.����Q��il��l܆�
aSU�3π;�W�i���;���.uP6�w�[���Ǥ$��ȼ�K��}���AB����>����1�̳UEm�?���p��Ɉ�� �6����J�J9};6�����<�A6��il*ڰ$���.=Tm�s'YzfK��������)6Q�^��P����gJ�'�x�TK%�W̋��C`��s�����"���C�g��Y$�p�C+��ڥ�^4�ӃߥcZ b�Zca谦�̢	�@��>{��8�
9��·_~�����k���mg"�n�D\�gp}"�c�w0UG�3�ƲJ�U6Y�I6\������{?�&�]��"��D��!� �c�	'ޘBB�уp?rDD���a�P`M(��{�(��_��6"��60��6SM
��X"��9u�f��umχ�2i� �,yGm���z�"�.QG���D��d�b�l=��Ř�5@�Q���ʹp7�n�b�nl[����Er��eAdѧ�l�b��y'a:�H9c��̩�"s���� 7�`'dѴD�q?k/T'����4���ˠvYpϵ�f�E�t�F|��m/�芅��.��B˪15m���]:i�>����Co�_"�Е7��6MP��+G �W � %�o�+���Ό��*%*��5��cQ	M�$��+.o��E�E<�x�\Y�ݖ��P�{}� ���a?��:���'��i4 9{���|��7 $`��Nj�����o>͌���K��/��3��8��|��)���?za���uxCji���E�\��ă�F*�c��=K���H������d:����E�EjY�r<������y�{Qc̙�<���'I�b`�b���&���}�Χ	GBxÕw|��Z}^_Q$�Y�k��:��i [,ѐ/\D�=����j������9'!f�m9%��β�~�$��<z1�Le$K�F�PH����	�ס��J�%>B��������VE2�i]�V�%-njD���A��3��^Q��]��x�.Iy��8���� ��V��o�TJI^}Mj(jA)m3���������E6T��f� 	�$��M3�;l^pm��r���s������w���n�/��/<�����㿱����m�/��/3�g.��tcCa��1W;��dܞ1ͪ����5���P����h�jD�K�ujݯ���A�1M5�T�$�S�����qw�똭9���=�x�5Eg��'\��gc�d��l��ix��&�q�Nߴ�Y�lU��zƏ��.2��ܑ�XG�ɺ����mw_u�������.��a0�э��p��<±@����Y��G��3�X���0m�+�:�J� O��dߓ;$5T���Ћ	y��5%�w2�d���C�t3x+��)Ͷ���
�2����IO���dƐa�|=�39��뛜U����t������:^�͜���?���[��G&�$9Ll��q����l���T�Sa�M]ڶ�j�Ю.b�-�5_r�4�3!�a(�	�D*x�F�-BߛY��<��q���y����C�7P��u�KS�-֔fkE>�<�:{��Tm5���5��De�G�ä��e�����.{l;(,�#���8C�j;=����d��V���}&#�4!�̚�������C�J_�ޟ�o��f��{�ds��}��+>��P�p|�F!���'���C��'*T�%�0D�,���&�;�������!
�����OC��[�ܩC��n�Ue .����O�8/�nx=�� %��[!O~D�bT`:�St/fH!��'��&׋�Y ��y��I�&̉U/B�O��M�1��0&�L�P�<��:��l�&7����(��V��]�Ĕ��1d�5������3.����M?���������G����/��u�<`�ێ�`��Bp���]�^B�p��ϧ���"j�sE�y�P��}t�G���!
 )�r?l��ҏ�)�t��%zK1u�����qTC�%�{�8���B
'O��Ʈ�i����3u��9�P�Y�=J�R'�B��$��Y��=���ڎL�-��M㚞U g7�q��׬+ �*��-����f��Fc���DaI��{?�w���iǔ��Ť?z��T8�E�^�(�:� 4����0Hn왨���zZ"��S�KBK��	��Ӏ���$�9ƞͲY�Ԧ�ig_�R����%�!�?�a6c�K(��^4!7��dH�$:.�35��;g�)�8Ա��o'H�\��P��A?��A��KM,A�q�*�R17�w�A$ID
��O�[L��"�*cv1�:
*ͧ�;����ׇ r���mh#z��bV�kz����V�@P%eYi�gF
*V���w:WO�b�o�j���'^S��������н�����q`\���/���SV��X=cF�~J ����@�ƙRw��:��E���7�y`��0B�l��LXx*�r�bjc�qg]~�d���1�F��,qw�̸�&��b,����t�N1Q q���(@p�K�DL�]�Ȩ����������7׿8���4k��l>Y�����ï���d[�_gAWk�!��,�'��q��*�E2�L�:�Ç�F�o�K ��M@#S=3C�,���}~<|(��+�Dc+zI�6%�"��ڧL�5\�jfmw��ҜJ�5G{�D+���;y��{c�ά%h�@{	�_�w+3\���1�O�wFN\��Q��>e��W<r���3T�d�����)P��,(3SAU+,Иy��T7_T�ejJ���}QI�9���P�3��GSF
�u�l�`�����V�n�wM
���i$̈��Y@�8�e-`>�v�6�;0��,�?H%?�~��@vQdLIp���)��4*��<&E=�����Ң�>[�Ɓ�����A�:̳u�5�J�P�h�5&[^l�!1��g\E!����%����in,��/$�?Jh���é�oS?�@�1+K�W�!.��Q��7��n��|=^��ax�"�JDiJ�Yr3�[�+�GI�BfD�a��i(d�5H�d��{18���n��i���aڻ/�6��
e�% t���@7���!���w�
�urKeT��2\��EFu&��/��Ϸ�]�Y������3��k��D�Q�$�VI����Ϫ�
�F�����Ȥm4��F�(�<�r�.�[�!��*���_�i{Jr*�$F��ϣ����u��q{y}�	����@~�҉B�������&^[�{/Y���?���O`��(�g���T�z��J������hL��6y]��j�Թ���I���,�*�H��h�NK唦��0E�����e5g}��
�v4 �L���R�AQ!'$�-J��%�p�|��|jV�&5�ToO�J�J�;��'+��э�Ӽ�ٷ�>�m��#�t��h�8b�?�`l�2zF��E�3^�S9���¨���:�ü �qw�ڠk�����IR�%��m㙹�7���h�
��[
U���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~������h� � 