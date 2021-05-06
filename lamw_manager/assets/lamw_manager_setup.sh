#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2705274015"
MD5="ecffd5d39b296465620768c55468a476"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21196"
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
	echo Date of packaging: Thu May  6 20:59:23 -03 2021
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
�7zXZ  �ִF !   �X���R�] �}��1Dd]����P�t�D�l;�&T�&3�����m��N�!᧨�?����8����0Asq�֊��GO�����4�QϢ�b�E�e��"���Im+��\y��|�B�y�l�K�gA�0���s��Π�E��'�6 ��K3%%���EW�K�8�>	4��[&©��0���28�O���+�v��*��tv��� �$GO
-���<���Z@.�{,��VQ{D1�)��p@��{{����1ݍ�\�N�$��G[K��Pp�QLR;��b�����C�z����~��4��c��F�A&�0\#�~(��tu������{.%�>QL�F��W'�s�3��6� i�u r#�x�Ъ����u�Ӣ��_` 媿�.{�;V�|���ơ�_N���-;����7q�sQN�[&��ѹ���������RH<���b ����ڥ������%�,p��e)/�@�+��� S(o��z�8�j���tK8��m(�Qj!{n��/���8����[%Cǳ���4����mR�s_*iGY�l� Jf����px��OPI�Ցo�zt�1�/�7��ڑ;��Kew��V�Z��8�A���0�T+�ڜM�[fx�{#��(M���s����)3R[�eª~�=eXH�	�N���2�opq"=�h����&�|��}��]C�j����T"4����P��~F4���ш]`�|��E��e��9�D���D�e�*De|��!t)��K{%VusV<-|;��B�`��kz"N���N�Dˢ^���ω��(k�߸ק�'��x��T_���j���;���?nHg7a ��X���z`j���#�R�c�u��g�7���q�?r�k���Bo6G����納�|��A�:��#�B�Uw"V��yR�-D7j�>����TsWć[���|}�0US����;]54K��5��X[۞�=Ӟ'�1���w��S���&�"a]Tr���G��y-�[C�s���t2�ͅ�L�"���R�U�),ٶ"Х�y�-�v�E���)ɽ�'΂vu;�����t9�����&����	6Z�_���b8*��<�3c�W�̖8��K��q
��2}SP���@�	�˩ku�y�S�U�ui�\&720I�dbh�V.�D�j�
����"%�� ��$��0�?�y��=&���dתA��8{�Q��{����hL����:��Q�4n\�$tt�x⋋(.��=G�w�i�G'"��Vh�jނ���O���-3J.t���>řҵ<�a
~�U������8���ZNl�_�:2�G�֠��	
VsR)��{��^�������cN�ȁ�tC��P�y��ᶰ�pa�����=U=��^4.5��׊�J`Jf\6c�w�ᒶ$�Q�M�P�r1���&&ǯ\!���w�V([[Zgm���К�c�e}�	b*�\iE./���A]=B���'S_e��!�8��CD%P��6Kp�����゗��Q����k/�i��Ny���S�J��J�< �I�ʵ�ɵO�~���2۳$%3,4��	��JF�bKE-=���FK�����3��v�C�nD�X�3��V�<5�0~�}q����n�GL;�M�K��1����k;�s���qP���%5a&��=���@�CN����&��:n;ǭ�_1c@�H[/���Y�f�|���A��|�r��r��C��6���C��qw��nK�4%��S4V���9��v��
���5E�(��ٶ��aʟ�}1�Y�F��N�KZ|[�H�����j	E?V�6�&T��b���q �d��Ȕ���)(��&1 O$�����n�?r�� R=_��=��bV�e4��!7�S$�k;'����-��e��n�
��8�`qL����i�6�k�����',K����J0voM����f��#�׺�p]=��z���i�?����S��I�4��&�f��^����p����Wǆ�q�&T+8�?Ҽ�զ�V󢒦k��]8~)F�߾�����9Z:��Y�������?��Nkt��v�� ���y?hn�2���QyL"�q��E�.`q�1�hsAP�*-�0�9-��)��W�Y�j�������Vb��GJoI�D�#�yh�;u� ��6�~�a��"���C=��ЬJX��Ad�!�G�z�3�8v|g���C?r]|G#�E<�)�_LO�%� ��b��N�d���Ǌ�QI%�8?Aύ��O���Ɠ&4-�l)����ݮ���e�^L�]�%`�c ;ud��fם1�=5���<����6 x#T��4z�������E����q�Y7;�J�p��
��S{L��K��dl����dT]c��K?�fO�^BnT�y���k�m�~���~��A�KT�FyMƴa�-���!�/�Mu���:3�}}sx�p���u�6J��ק��n~U�:D_������g}�(�Bb�_c��K������ F��- �"p,�_B"*�ˣ�M�E�Z,�|A�4�E��4����ͯ�ʴS�F�Tv�=aO���tN���7#�p��ro�V!fuF.PGVx���^�MR!������k9ߵ����t�2�h����]<�WԳ��Oݶ��rZ$Q��8���3�Xk蝒4N�pn�L��3����5�1�b�3si`CGO��F�w�IJ��2�@5��'ϻ�
��1��]9��|]�)����V�@%m��Is4��0��ɡ	�JIL?���8j7t~�.���q5���s5{ml�:�H����z�j�A_`�5�o6}~k!�l�k��4�~��ƹ���2��<�mRh�����E�(�%���H��k�X.�Va$���XC�hP��D/i�D�9��be&���e2�����q���s_p6�mN�B�(o,�ق#��Cr�t�	��A�y��i~:/]0�����K�p(J���B�j���	�7��_J�������!6sr��VB�r�ɽx��)ux��'?'X �"�����S�7�<�G�/�;�����bX����'��g5z�d�� V.V�K9C�uW��:�WB�&�Z�U��?rќ>�b���5ya���x�T0ϰlKr*:+�p}A��z˯�Z������X�1����e������'
�����-�̼���K����^7!�t�@t�sDq�q7�\��&F�)�c����a.-�W@.Fl�:���XZm*���)r����z��٣g�|�"* +eٌZ�N�ߙ��3j�6?����y>!���.�K�S@��]��1����n��ѦR����*�;QO��
����"���F�Sf}���ɼ�)eȳ��yG+/�{#a��ɂI����Z�-Rԫ���a����uK>?�R���γcv@���d4�˝���╇���Ra�*�=��Ā�,��	L���_����W�nG�Pj&C�����Lj"� ���� ���]=]�}�8�j�3�,�*�CJ�����WB������=Sxs�tx3JR�Q�U���KV�L�b����@�׊��CV$z}@G�vލ�c��4ee�����:,A�4��@�w�j�SkaF���	�e~T}h���l�Q��4��u�)���k3[	�{e�z-1r�� ����9K�
��!�L>�L]g�3}�P� a�Φ���/8%(V@�R�/,�������z�N��;����Ŵ���ҹ� ����'4�n��*�i�`�NZ�w-ܯq��+K(ik��5O͔d+j��p� 6���huQ�M5�841ڍ})^ ��1)�d���c�� H�.҇�Z�Z:S�o�lK��ӵ9G9�Wg�:��t��!4"b��2@5��P�/�n���2?.^�8�ޢ7�eON��р�=�
@�]���5���� o�M�9�A;��
]�ۡ`��n�d�Q�C]j��kȒڮd8�f�1�=��Tmq�q'J�8X��5ND�	M�^���(�OyS�/W~O�r�b�X�]ƿ����(/���*4�
�F��9_�(Ӛ��� 3�b l~��w�!KfYk�$ޜQZ:P,=�h��r3Z�Yh���Ig�j�Nn��p	6�x�NDw�t� ����	*=V5f�A�D�~^���v��?����6�4��%b�%R�ݬ���k���o�#_��N^zD�6W�ta��O����'6�{^#�;��1��g�X#�@�"��
 6EZ��Ę�����{,m�nF�Ӑ�Zi+��$r����O�r�Δ�Ui�|V��Z���s x�X*=_�]>��|�g��R&"�
������&�{`�Q�V����DS"J�ζ��X[:������-���0�|���!���{#�	��� �
	`�?�+W_��(�r�Qr��0��?PD������Q�U��e<�����\ʬ\.��0�h�ߝ��� bS��Q��.�	��LO��2��Qn������$۷(�V�4��1��D�Z^��k�п�%� d�U!1!ypta���݆NU�K�C�������!�ɗ�&qx>p-���9�q.x���ZS�Y�(V�����RS�\��
�eʗ&���;�zh��~D*���X��&έ'Aw�@x1,���_m�?'����G����_H{C"q/K��h5+E�&��|��� nt$�
Bh0��c�Gz���7��6���Ql�o��� 7��0�qH��`3� #򌱴��w�w�%�֢f��4Bt�.Ϝ�qo���� ���E�^I,����~'|��P4�V2�~�k˚�4C5C����z��T�yS�@�V|!Nڃz�,6��]�Vy�+wĲ��mV�O�I�z�]���"kROuR�Vj� n'�H]`���`��]k;������S��}^ܘ������|�*��V7`V"J������=i��D�}��T�f��2[H!{\���O"�7s_`�|�8�����"s��U���e�Ek�1Dٹ�j(��F��;wv��M�e_q���4�~�)��0H|nP3���Ca����FK��BA����h��zy��#�&E�m�(��L[�G���(n��LREg�ѽ��R�����?X�\U������<@��F���i`�S��[�;��yRQ�KR��b�⫰���l��=�d�d��(�P�
���ð��a'����q_�YnN`:��>f���ps����z��С�J��j�1�E�/ ����#�5��,�[� ة&�!����ˬ{cڱb�Hc�&����,��e^K
fÛjL�"�qN�=_�5�[��׬Դ��ӾeĹD�b=�ߖ-����pq�.��
��3��UU�����Q�3�iV��N�M&|���<�Z�g�4��Uڧ&.'�
O�j��4C�l�FWLQ 7�i}����S��߷p"�����H����3`���# @ͧHO��t
[ g��F�u�P�N(�pS�=յ�O)L�,)\'��U�����O�-_�'�p�x��Q�a��4�A�/|& �È=�ր�����JR$[��ʲ^+l�E!c.��=�Mzw]IO�0��/�re����7���՟��`%��n>qMCE�Wߥn5C�{�1��� I���Ao:n�:�s��*˫!�O�a2�:�*��gW9WN��sy�P"����n��##��:2�I:����=�Ac6���<�2e��{}{>�`�Ɵ:�	x�Ց�H �>U�)�y��k36� �o2Q:׫t����Z�j0[��)S��6�C���b t풢	?_�`2/��o��A���sp�&��&/�y����K�ғGc�@B�����r����1.�`�{�!%�����<�4��?��x��:��X���n����a�Ŗ�d�X�$"��)���-�q�1����cC�S�.�|������RGY�p���?u�oD�Lj�����	>.A��ِW�r�Jؔ�H�9�-�/� �іN�>��=Fp��tM�Q5�2��Ckce�,c؜�&��:�]�1s`��#'na$��oq-ڢ�%~��
џ+�_�{;�SHذ�X�͞�}ĳ��=L�8F��Y��:_pJ��093B4?��"%Z.,T[��3�ٜ,'	hTlF�)Ir#k-ھ0;*�~!M�_�T���vw�e^u��u��1�eG-c�u�l<��`�������o���0��/ ޅ8޻���ಐI��6ם��,|�B�a�4��}��0�vK/O����p�ő�m2�8�7� _̇N�}LG��E�X�@��:/VQ�c��X,���p�)ΐ3?10ǎU�_��E�U�����b��L ��Jg4��:�dV]9�,�����4�MI ��ֽ���Ŷ�~�Dę�3�l��²�ں<���dz��;�"��j�E.M��q��V S��=�8����b��]�a��.L�s������YBK �Q�'��F��`ꡤ�^ʵT���( ǫJϥ��פW곭7�ܾ���g��$�zcQhZΡn�y��C/]�11r�b���c�+��pd���%OF�Z�^PL�A �sIq�5�x&��a�JVCD�$&�^����68��DW1�n�����Vʬ��7>�������f���;���O��Y��F�s�ؚҎ�����t4F"�*'�z]�����e����'� ���^�y��^A����JV��#��#�#�
_H�����9<	ݐ�5ëQc��f�;b�	#4-��L�<gU�*%��2�&@�q_���ح�i6,.;��3,QJc�hZ����{��V/y=:���s��ԇ�"]��� �k����n��S����z�@`Ho*�_.���S����g� e�Z+����y��f��.wbb#<PٛfZ��N%'�e�EVw��i�`����kD�'�X4e�F��Ô�Y[�J�+�qf�{����0"����@�V���H�/��OT`��*�� Ӂ��6� S���1�-mDT����Z�����3��{�An������j�d�hG`Y�"�@	P8�?���GgHN�M8���p��ğ��XU�����\�@#�Y�u1� Kj�[Ԃ|˒�b3<�7�%II��i	�����+�I4Jjps�
7X�'�s�Yɷ�6U��S��]�)��u�#OIE ���.vڕX��+H�$��t�cR�SK��|����*�$��%R����M��	�kLG�L��m� <�Mc��}����Jy�$��૲���4t��_�����tz�@8t��یT��W�Be
��E(b��x���N��/��>#T�忌�R�O�J� u[�6\���X�hp"h��a�h�%d !tZ�|�x9�����\3s�������4�^��l)�5d3_ˡ��NF�	������>�����-�a��%pJ�"N��R5���)]C�/�S
bJLs⽆��8=E��M��h����8�cm+|]�\�{�+�������>��\�N�����6� ���BQ���5@D��x����$��"���N+/�〢�ZĬ�slM�2dDO�X����i\>�,�� �b���q�V:d%v�h]����\�띹�Cg�ˢ�D;M��n�I��먴���s���A�Q=?�j�a)�����&t^��O�
��L� /�'[Rh�������&
�H�4u;����[�{�8s�n�|�(�~�(,x��[�w	�}�����B��Xg|�$p��w�����|�g~e�M!EOpA~�>����'�w��T����D�E�u� "� �zw��@��"�4Y3;��/�r��S�mY�U���z�Ӛi Mͨ_5���^l�Jk�h�&�.����H����ɦ{��Bڤ�gI~��
Á�'��=�5�po"�.�wj��o'_�&�`�����|]��&���Y�Iܛi�X��C�<«���ەċ�-d�d��l�t�s���2���ho�b��Z`#�W�7�4���I�]��+�<���M?+�X�|)�����o]s ��c���"A�O�Z�π*��5ek���L��{*�t ���>�v0�o��-����T��^�KX ���h��:�kn��&�O&�>"`$;%��7H��]%�ڠ%X=����| Ք��Is'f�����r��W���*��M<څɰ�d�Y!)��"Mffω5���+s�옓��5��'lÛF�0y���!#�HX�D͞�(2uR�I*<W�`�W�D�V�fS������b��%+�^�HAq^S񅯌�,Nz����T�%�*����^�o�|�tt��tZ�ߟ^��|&]��L<Qa��t�w��{�cuJI��'��d�3W�p78��_~{�R��Z�چ����\�d37Ms�Ay�t���q���0����_=�>4�kӧN��M2���~�9��`� c=�������QcҜ�Vz/�����w�Ƚ�?�q��v�"�׆��O�[  	��LxK��[I�����o���bKnz9�� ��D�7B��ԣ8�Ŋw�����ٔ��!g��%�ٷKZEi�>�
>D���h�J'�s5WG��θN�&f�8?E���`�C?0�i4���|�����ҪT� �;��
S;�����3�������v�0s�����J�-�ݕ��N�sݥ�-��Ix��mW��=��i�u�b�d��C�Y�V�`L��4;y��h�Xk�Wv��<SЁ�.�,<�FX�I��Ҁ�c�������^�L�]�43�fX����F0�?�MH�%e�HEce����as�7�`���,�^[٪�Y`U�>�{�<f�)*!k�����sO������o���W�QS��Q<΍�n��G���%�qf[��?���)������'_b^OGKz���:��Sڄg��}Fkǂ"�̊�lb�#�m7����[%�@�r���s�kG��6�	/^ή�@	�g��D��D�3\I-ⱂ���IX?��PT�3����e�����yu��E�ݫ�k�L��7&�\��9=��1��]r�\y�" ��՚�q�ɒR'/	~]g\W�?ܦ�)��/�[��U�2{�k�z�Joԉ��#MV=���S(��7��K; ���\��|4?g��é��e{���ڰ'ҁ��kq{7�v�[Ë��\�"(��xB��u���J~v�m+Q������be��H��S�O4	K���ri��3G�耞T ���ºo�U�H�����@��{����oXS�Q�O�蔵FՖ�(1f��m���Y�� rs�
�#�-<㟯X<� ��a�Kl�~�+L]���e`�)$W�*�d��Oj�� X�q���:��a�$jM��ɇ�*��8ܲ6{k\.�<�ogD�&��/ d�A@Q�$��ݴ>#YSixL�$"�;�l���]���g�0�>��t�x�;�%Ω�7�G�̠�m�Ӡ+ѝ�-$_VU�x���m���?RB��ex�{ZH�ї�/�_��G�1O7���E�5-��ò� ��s��LܐL�
j���n����g�S��[�� U��[��
-�7,��;
�?r�G����e`��edĬM#����E
M%v�<hD� 5��jŃ:��o�Ш�Q�ІkoH<3�(�%���m�ePEk[��P���l��I"c[-W<�a��j�]RpA��w��M�M��Q�F��;V�	�k{�����6E�ٸ��nu9R�͍�r�
�#8���-��Ic��!]�Ms��8Z���-����I0����3B���,h��qpT�~i;���"I�7���Ya�)���ʧ��\���[�����N�B_�r����@X@ŭ'+����UZ;��>�2�1:�O��=e��[���üJ|rĥ��Dtv��z�vN@c���!��*�=z1�o���:�.��Fi�w�DC������Ni��w#t���ŭDzqqd�H�:y�����ԩ�Z0�y�?9�{�uR�8�C�Ģz���b�F��c>�K�}=O�9d���2d��[F3n0�!�+f����n��O�W���Ͼ�L�Mȡ�,Y���?u}-�jp���'H�Kzd��3*a$�x� �ɞ�2����7��1 -Ņ�3���rQó���o.rM����s��pB@@8��?ut���~��:�&P�ɧ#�`^|�Z��MSsӁS}��T~{�����z���Q�\�j�x��K�tvP�-���=����w��������ߘjށUP�|"��vT�� T�?�"�M����;oAt �@�!-lٴ!ч���u|Ʒj���.�&���ͫe���X-���y�]e����U�'��)�\T�2N��AJ����j�x�_��*!?��<����� e�!�x=3w�����F%(B����m$^Bz�`�U�?�2I낥Q�ho5�	�:E����p�[~�p) E[���� ��Ȫ�=���j�	��!d�dvX��<���&���3AL��K�
ݒ�i�af1	`�.�^!pѯao	5#j�jp#�ы���y�Q����)w
˦v�e7#Q��m�2�Ǉ/��kln�nw`E�V���Ո4�=�m�Hs� 7&h���"�(͜����z���;}��M��"4L�Y ?���_ I)��e�O�O����=̃>!�Q���LHw�b��/��B�	B��^�7�5 Xg����,����;\�����S��u5E�i���0���Oh/[`�O�����>>��� �Q賰.S$��tf"��$�g�A��:�}�Cг��F���.�t�Ԉ"�ta�ߍ&���D���oQ6�/�C����/Z�VȮ߰�|r�n��Q�v<� B�\�V<M���y�:i}%Q�J��ֆ��u"��oK�|��G�˰h����}!DC;�Q��GXV�E,Y��X�jkZ���S���42���P1ާ��l��F�5W�X|��8��f���g�Y
%lf6-8m��<%�|��-��J�t;���/�)/��?��+Xl����~+��	?M��W��si���.N4q�T=v�%���=_���7��$ ��@[�[�x�����ϧcp���c�3?��(�u�珬dO�����8���6.�I?��&C؅���$�'�<�b=+�]f�Ȇ�����|�W�P-o}��T�{Xo 5�
=ϱ)�(8ne(����H�V]1��T42�o���=�����j�-��. X�'�)�I���lq�%�[�Ӟҩ\�2�.�-y'��.�V�v�hR�E��6���z/m��͘�n�nZ�'3KcI�>ab�=�d��*u;�U�>X�z.e�Y��ærx��[㏴-(m�'`�*)F]�h3j��~��LNs);=�K���Fܰ��M1���T�!@�X�}��7��F�4�����0����)�A[�-�f��z��Nm�$/��х���;�=��LpW�j֚�����
A��Tq��Ӭh7���E�NȨ�L4H�"@�LT�\��.Î~HZ���uU7�KP���@/����5�ƾ��#(we @�EP�Cu>6�����]*�.{r��TLYƕ�B)�KK�Wk
��zح����<,��r�߶����@�������PX��Z�e~��3I����`����p�:�i���L��l+&�8y`��/���c�k��rm+o�o�tb�K�lg��e� /	<�=Q��������C�/pc,.�i;ǹ��������.�&����ڪhԼWl_����?%�0j�au.#c�n��2�V������rtr��>''�-Gp�/ܢyg3�*�����o/�8�FK���4ޔx�Y|J�^#��ְvG�t��1`k=QVD@�کK*�:�]i���Xb�0|�����-�xÍ��4��@u�>x,���a���۫/�iRjy9�p�?��SS��R�>|��S����h�Y%&��������Yv4��\���ܺ�6oB/��(n�|�K4*���X�D%8}z0	&��SE:Ѕ#]
^���&�"N[�C�W��z��jU-/~�|Z����]mTő5ZCc����~����&/|���]A��'�{d��[�$��B=���B�t5>!?J۝��
=�͆�]u^y �v��9@�f�8�Pk��c�٤�[}%�8aR��xݨ<,�4�m���8m��PX��&
�����p"͝�!k�k�Y�>WK@��L7��au�"�ox�_& ������8�NU�Ց�u5IH6&�����FճC��ц����Pp�ʣ�̘*%�ْ��Q��MpN��t������-�2¬��+�n{��[#֚7�k3a����q[i�g��B.��o���jHղ���^h&�����@'W���Ǜ;��L��,���Q�C����Ch�flJ%2���*�y$|���$N�>�=�O�Ob�;	�K�~�v�d���HJ�nݛѽ7���P���]�_kbp�)�g5�� �*�_�5�^)�<#|3��x7�I��h,Tc�����tm8�=xHC�yS'�n�ԟq�r,Z@�G� (�C��W�a��Q���D9}�0,�)v�t�6{�T�㥁ws9���ĕc�k`�qڹ��p�g�2±���y$�����5s2� ���X�q62BPf�����՜�>q�W�F�ɬ:4�x^��e�ɏ5T�:6�ז~���Y�v[�3�c���K��`�G�!�����ʴW�d�y��w3�w�&�2ul��&��G���C{]EbC2�֛&���w~�C����Z�ڸ�OAnV5�~�s,��7_4=��s|";��P�Q�	U��òf�Vr~�D8����q-��'�K��a�N�E���j��5�#'�owT�wΎ=��:�d�$��Q*	1w@�w,wW�܀,�S�,�5�X"*�"�o�WyWK.����e}$'���{(�d�д���@����A��\|E�:�	p��z����)����)JX96�l͠>kRf�x�]�l��	Qo��2��m�tv~�R/T	W�t�F�c��@��M&�CR��U@M����x+a��26���_I����-ͷ�9��8U�������Y�Iz��t����$� ?@U.4AJ�d�:�o��Y�""�0���ĤDx����ډr,B�g��˽.8X�[�d����S�.ACp+J��^$�l���½M���[6^&������K&z�;�j��bi&�/�<�)5{5�C�tW0��������$��5�Z
E
�
�{듐�a�����
�&SX;�Ώ`����Kc�dJB.PI��t ���j�)�,̣0*���b~�1Aq�kZ���_�C-θ��5�+&��~�G�Cdn�Y1?�)�p��K��~o��JJ��I�-��>���#���2����'J����qr�LS�;b�[�r�}���u���U*�4_��Ջ1U�N�f%y��\��UY�Eh��y7������y L�w��Ю���g_>pZF�Q�����S�d��+hO )�N���J�	�s��K�7򲬔�܃%Ž/j�h�̘u��Z$�DIzs��@vںZ��G<���3Ļ�"��Mʼ6�qS��,A�xQ��Fx�Md�p�ۡ�
1���u�UQkÊIKX2�o6n�Ml�%��c� 2q; ~�:JPRu#��e�+����CNB\��������v�%�_H#�f_���n~��m�U�ޮx�)��k��������<�7տۓ��S^��Ie��~��#բ2��DM��Q|'�p�ۆđ?H�X�cZj��j��3�Z�I��D�0n5q��B|L!���|��BE�	�u��,:��˹`��a*�r�R8�p�ǶD�T��ow��T�e�FwZ_��o�]��]��&?W�x<�JnR�Z�B��<�S���Rw���(NH���W�2{�$�G�H:��c_5�L)~�:Z:Z1HT	>�u���Vg�1D��[bsp�|�$��:���[�w&�3.����ۛB����fֳ��( 3���O�D���ܭ1��|�@y�>���+2�3W�P�4~F���c��Xh������[�Jg Q"h�\:a*������(���)(@2^��y�H��O�m��m:'? Q��.�'��˺�
u�B7ӛ{[��h���w��|�^Jp�	65�I�AF+� �r䷹�v,�Rd�G�6�)�p����	�$��L���vHM��A޳�T�q�n'� f`F���˾GrD=eV�k�4�g�;�/��rg~�5��'qE�IĶR�s��ܦVp�ZZ�����]�#����Ȫ�C���V1��,_��F�ѐ$'�Ӹp�)�D07A�SF�L�7���Y��xi�NM8��ZP��h�麇��n�����0s~΀s!��c�J�=�P�����"��wND8�w�I��u�X�}���+z�PU5yS�En�!q-Y��}q'����ӯM�����M�TR����j�`)-�<$�9
���al	�O_�� ��JB�%&-v��hH���C"���t��b330h�3� �dh�,�����IDGƸH�.�f���n�%�*Gi5���%߁W���u*@�r���,���F qS���B��`��տ��i@��g�ڪꕘK�{VT(e�-4{8�6���Fz)�xc�SL�?/Tk{/����Ρ�Ɠ��Z�5��$ذX/Ǚ�_�
��6C�[&&����Ě��j4�& 'd}�����EM0����½� T+�X�\����qaز��x�ˋ�&����+_�9�|ê'�=�$�H�:9c�4x���E��*)M��()^�n�_�����s��PQ�lb��iOÛu�ܾʕ�.ߑ:o���D����Lr?�F����	 ��P�v�g�=���T{������L:�Gs��,��H$�,j-کq�fsڼ�I�H&�'n���Y�8��Eu�9r���1g��/��[�����0+�	s�湵s6��9��ȣ(=�QU�g�+�0�}&�ߜ��X��CV��~`���lT�GH��ͣ2.XۑY���G�����Z���N�9�lt�.>)�g�S��"\K��
B��6��ܨ�2�=��'��'�?z������B�;̯`��ּlO�Sv�=�S���wh��Wv��m���8?�5O���8�ۆ��Ͱ�+��Qcɖ��WĘ������|���[I��B�?��%I�:���W^��E��tm ��'d���A�c��7���d�-*�4�j|)7IE$(�� *��<�]�x��XtO䆨$1N8x���*LU�F%� ���r�-���s�P�"�6ب��;|�����x�o������m�sV�:��Ḧ���OJ$m��	����6ӕ���v�sRw!�ԛO�ŬaKy4k�_c�������Z�Q��
)F�
����K*c��<	�u�P5{��k��܆s�퓽�c{'y���h���~Dwv�(u+`�V��;�
{���<^X���S��!
����r1����X�5�������K
�EWX�E�!^�G�i�`2�ɧBi����c�i�zZ�F�$1%�XUX�70�2��AT��Y\��{
7�hއ٫ٻ����J1r�ś"���aP%˾��x�4$%� �
�!E�n��oa��z���U^�7��gi��Sԋ��|DL�0Em|bm8��>�Q͋e��ʚ>�`9,��w��z�!g�����V�8<)ŵ��ߚT����r��1�Ny�bn��ϐ7�5����|M��sMG�񆬹���:�l�0�o'߷-��)(J5
B��V'u��I�7��=�m��zWo�p�l�冗98AI�ݐ��W�f�}窪9�BOwS.��IZ��aֽN?,b�Y5*~��qz���jLV�F���M�GcuP��#?�&^;r��h��h���cv�9�׏�
�#�/�T��5��ҙHD��TD`�H�:w��94̒�����F-U_ʺ�V�uJ\m����n�?��th��Y@Ŭ�ʛWI���[��ɵ���>N]�y]
zm߳��M�5��>�(�QQ�`�(,JԠB���N���}F��GaA-n��4t�[���:������x��~�ϧw�FYˮ���NқF��]����M�>�w U�с�Dq����XA7��?��������sIͤ����L�W���ʔ�����6�lr,y9l��د��N�V��M��{	q����@Xr�c�x�[r�Vc�����-Im���aC��q
n�����A�RB�*ҙ�6aH���F��	oKTKV���h�AZ��[���2i��M����q���kT��-k�`]�T��}�`0	�A�4T{t'h�]"e�,�aa�Q䋖Z��,%P�b(�T���*z<{9�4羮[�)�}��@ C��0���V"=�C�#L$n�"���Sh�A����7�Ѱ� ��h�x�qY�(R�1��}�'�R��x�ʼ��k|��9�s�r2b'�w�|�-3��D�з�a�i��Mh�^D�Tb��LrE���Z��޶M=��3��S�RG��alR�U,�	o��|W��N�����*��F��K�eng)`�e�gwΗч����P��HA�J�#�E%q�7��ArD2�+�����	��� L,�-'�� ��e�-�%I��B>�Ƴ��S�F��ff��`Ҿ�k�1h�O��2ǃ���A%@�~ː�������4�)"'���x���fs�*���SV�EC�D_h����uv��c�,��!�eq�� �l�[l#S�� ��1���1���lhK����KN����fP�5���1����(h�KD%��Iu4Y��e��ՖL<�ݴ�G�)X\��j'��y�}��<a����rr���TW�Ƞƣ�szӻ��`�pV����E�zӶ~掤5XA9̄��7��?��X?��Q]k+���rȼ��۫��^��I{�����c��B�%f�������t�����{��I�@�U~;C~2p��e�K��%փ�Y!���M�51C߀'=�ؑ�T��������y%�Qgz5�,�F)U��^=&l$m��9�����;
ye��4#D��k�����"Kv;<zu�ӑi�A�j�����̌�;D�N8�"M��%#��;̈��:���=]�,Ac(ZK�F��s��ST��=��B���F�)1+��P����"]{3���P���*�f{<��bV��]/�0�Iz��v0��Z�8��h�P��^�O�̃q�g�����	��ll7��h"����f!!���s��">#A����g�~؎����Gj���^�-���<BD�I9�����s���9.2��h�YK�ѶΨ����ǿ���5�\�Вqp]oP? $5�D�3����G�/:�F��A��^Y�`�/T��J����_��v��+�9'��-?`o����O3p_ji��E�߬NZ� ۂ����1=�n��#�����8���""��|x>%<c����쁹��b"��i��gR�sF�WOs1����]�#��P@:�G�x��X����x�ҵ-2$���J��6)e�.������?��)dO�Hs���l 'j����°�_��� ��S�c�F_�C��{P�u��tpU)��˴�Ke
/�/K�_������+�(�_�u@)�Q�Q<�搊����bW�ZMK�Ȧ��Ov�EZ7J��(����� �i�V��� �bnE;�������ֆUNX�l^�� !1P9�	lD밾�(�Rh�<�-b1�w����_;�9Vψ���W�D��p��� �ܐ4O?ֿ��e��yX�_ȇ����ޜ�@�d�w�����4�'9��v0G��;}�V�����}��4�%�@j�Ґ���բ�����W�U'ȳ%a������nA�ʈw���6�قX�,x�Mu;K6'�C����YV߲§r����R����xG�M��>�k3�rt�EQ�!l��=�,K�<�� �H��a�g�aG�z>$J7<b�v?�����>���m1�jE!�ʈ��pRҭx��/5��/�n���5i�ƽE"� �?_4�:�	1cv���ņ7���j��+���6��#�,��쩯�fo�b'�	h w��9~�E�&��&���b�����P���#��S�����c|�Y��f� ��S_Z�bTGçWs?�
�1���]l���@����MƬ��T�M�/� �n�:��̗���qd���y $=)��۔��G^�\���o�(<bD*Wu�����w�z�e�?J�{q�e���a�}�Z�(rU���3����^��AAb�O:X�h�$Q��8g�U'����ŸE*-�Ik����8q��4y0���Sk%��h��� �R�I�L����E�������S}�G�a�p
h<0�e�`㨾FЏ6dU�\>�wVa��h7��
�#����}�Db�����NQR<dfo�bh	z��Z��)� v0��\\OT�e)�Ջ����g�M�E�c�Ro�y 1�PĉZk�Vi<�a���Z	p����оƧ@d�v_Nc��r�K57l��h��"��3l<v����fBE4�.;�LmVέy�6��k��*�K�A\{,�nQP��p����*- r��kɕ�[V���`*���Q��9����ܘ�a��+O�f�:��jvS���tʋ�����L@?u�ڜ���lc�������B��>)-gk�iMAT����y(��09t�i�}Ŧ�]���7k*>��m��@]�PL�=	��䬸w�w����u�YB���&&�VI$?״��C�4����ӞoG����8|4w^r���O5��6_T��v`��Lp�TnTp��.ˬ&N ��ײ�������u������Y�_z��`n�	E�Yb�A�2���P/hf��Q��l��ާx@+L�2����`���1u���0g�K�}�>2�� �K���m��w�шzEx6����c� ��$Y�ki�X������.����a�i�0�8��$��(��K�$Jh���*��Ŕ�8��y���j��	�׊���T<bo	��D��N�� J�i�B�P��p�?�N8�n(�)��{btK~f�yM
HCמ�H���u�M�-�����^�Hp�G"z��n�1<�l�H���.�ȥE��b���*5Q	[7j��%"Z,�C	����Owx/��_���ϕ��A�+��n�~mD�=��G-G�ȌL^L�C����hΏ(�B3%#���y�x�����p6{_����nXr�4�6��x�yGi�҃��,&�������>��3'�4c�[�&�1�����\}.���s-hX�2ou�j�����P� �(7#+�duP���'�� 5�"8�v���������7M��/Ŭ�At���o��\Y9|/�B LHu	�@���L��P���0��;���_HR�4�TxQÞ�/�R��˫�E�;�ptn(n�t�*Ǫ�9Gw�V���(�d�w5�P����)��J����~J9�X�E6���N�D^�����u6��on葏�sy�=���O�r�:"����������rjRS��ݵa��=�,Q̬x�����@?;����Zk��}q*ffӿ��9�K�ZM©�� Ke�"���&3��LA���Ȥ�J$F6,�d6���Ȝ
������*�kpɈN����#�j0�I�Y�K�	'}��YO7��.B}M��[f]Ku.i�xp����^N�ӫ̪�O��?��79\����3PҤ�@Lΰ���	Dxr��A��m�A� �����t�k����9`����п�K`�2[����JA�,�����c��/Lr�;�w;�@Z���a�=z�J*$G/u�����C`|��`,m�C�8��{�ƺ1A�Y\SQ�c����ҀCa5z���A��̩H���(|���2)RH#���n<CE~��K ��qK<� ��� ����@^��+�[�4��!�.5�J���<��K�b|���2��>7�bcL��R�lj~��Ǌ�6B{眰��[��V�ɼ�C
lV'�ԫYjػ
��=�`-��{��h�N����ݚ\�R�����Ge�2�s���I���=�v������mfXȤܣw�@P�x���p�x�K4~�g�3Nr���汚E=�l��$X��/��?��iƔ<��/�����J���)A*�xˉ�>CJҦ�E��׼f)3�	e%ɝL�5��/�[��{�ȩe�i�w�\5s;�l��XE|ĝe��~y\C�U��ɱ~I�#e�vA��zΏӁ�sp?�(�} .� ט�n���Ĝ�)��.�z)�V�&���j��,��ol8�]!�܋>*$7�#u|a(i���3��3����+j�V���Ā����ScB���Ԏ Sa�#ZC�Jwdg�`��~�+��~�.㞳`~���󪨎>|��F����Ih��A�-1��''Z��P*�BoP��ha"����V�����26���s+-M�� �sI�X�r�������{З��� ]7܊� =2�Xc|ǜ�p׶l�Ӳ}^��x^[��)�a����h.�%�>��%K��� -uUS��f�`
N�V\N���~��˕�>z�?3Ŗ�����7l���{��-W��&�HΞ���65Ҹ>�cÈiD m��j�LE�B��uvs�� �/�ڄ*8<Q��,g���Ma��.d��޼���J�|�,�j!}��ǇTw�����D     R	8`�K�� ����|���g�    YZ