#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1235800735"
MD5="b97af7cf6fcf2e2dcba71e59d03d3f63"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25220"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Sat Dec 11 00:19:23 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
�7zXZ  �ִF !   �X����bC] �}��1Dd]����P�t�D�"�w���az���2��^�[M�E�w2�M<��>�Ĭ��鐭,	�*�$�ؘS 9�w��F�f�� ��gpƟ�a<بuG�Йb&-$>�h����F��Ԅ����N����V"��NӤ�3M0�G4�F���1���(k��"��I:#g����N� !h!����t7���Q�S]b����G?U�=��w���4����%f���[=~�f�[Ķ���t�����P������zW����=�=i��^PQ��@@׈i2r���a��� ��V��K�ȼ�u�\F�����wQϕ����K&_�%Cɿv�����t�C��I�H�L�KH�u3H
��D�nQ8ɱ�J�l7"O�P/��=���W������t����C����y���m ��ռ�R?F�������J��z�qcq����=*8<�O^�֑s���/:1���w�=���,f�ʬ[���e���1�,U�nUz`��_�Ǯ�4���/n^��h8
c`f���?_QX�t�?��Uгޞ�<���쐥�g�\w����x��
lA$�_�߷H�$��n�0�S�Zqŋ�t3�L���h�>�y.#|�aS}��ۘ�
H8u�x��V��ʦ=}p�}M��c��ؖ���1��w:P��M��;����|.|��:��@N�E+�9dLh�G�E⺁Ǜ����#kV�:D���S��$[k��d}�P���NS��u�~T�E2xv���h����8�.i>���n��&<3�%4)�e�*E*/&)|�9+,f�NW<ȄR��S��?q�m��"ƸU2�3O+���pU���(�p��pVnIV�iŔ�������P4l��~ٽ{��>��_&�F�S�^�2��H�]Q�"�'an^�Kl�:��c��p�ɝX�Ύ$��QG�8l)�y)"nM��9�J��|��_\�-��� 3 ��/���=%Ax��'h9���R��,H�Z75#'�{Z�a�t��\�2�owE����m�%��rh+���A���<�d�\�J���vY��?�2�C~��Z�g��
A�m2�_ϒ!V�������?�Z�'��ˏ��0��"� �+��,�lm-I��?�ɀ��⯟��V�*�3�������߫D*�_+���d��Ո�F�+���h8>�N�d	q4�e�����A���N�@�	��<OQ�\m(E�ܴ[,����z�^Uh	��Ɉ�N݋5�(�n�B�*�A��c�OP�EI�sI.k{	.Ղƺ�����%n��,��uKiw�][`ֱ�WK��9�*���"S�Z�Pn��U�T�-��C������tEr[�[�V��92��EI�2a7�l�A=��6RD9s�L������)8iR����e��UM� ���ܻ"p�D����d=o����sv�a4Z�^�g��(�ۃ��e.��#����0��'�|ț������øߐ�;��%��6Eg���׃�f0[������قv��Ch��H�,���^�`�4��h���ΐ����i�0�8^E�Q�qw�L����\ j�`��;%�$�����{��m!��\�[T�0��Q�*�f�h�r>�LƔ�w��`�U��(��a߱?^�[�٬N����j��h����@��S8~��%�=�����2x�ܺ���f�5����&�����֧H<��@꬛��¾\*��׎�qXt��<{�$�ӥ���MN*��I/}1�� �Ԁ'�K4����b�E��v1
(�TߺuX	���T���>Q�#GXrTpnu��
���7��sz����Wb'4��S��wż��#$��Dǣ���7�g�x�3�1 
"�8��r�^Z��F���pB.$1E�N��97F� �S�� �Yȇ�G���j�[�Gǹŝ��Z7<=c5��c#�"�E�@��U6l��hP ��v�}���1�
��M1]���˳Ŀo��HG�[(Q�L� �3X��8!%�	�D���<��wҎ`�7�f1�b�\�V�,T\�(�P�3�T��h�,Jo�;X9�YQ�~���\�jc�]+��ΟǱ�Gh(�z���i�]�үw���4�r_I,������v?D���(��n���i�ݗ�v	?�� �>��CR�����20������*ź�\�[F�Ù�n����(�{E���i��]����ajqD� -t�d<�̱������<���"�k�WS/�d�o�=eշ��
�;7_��Q�S>:���+f*<�G���[}�P�9c�������c�^�(� ��bF�N��s�׺��xzj�J�t�[o����o��S��΁���}A9�Yն�h�����lՑ���-��!֏P���"�P��1R�d���:@�=ߛ�G	k��"��� @�1���o8�]"<�;��Ddi���@d\ a_�.f�+��W'�Y������wI�8E3�	gb�(��b��3���, �z��Q�!n�l@
ݨ	�SGt�1�1���Q��
NO���㬸�rg� �!��sG�����߀Ў�����4�}�X-���){�@1�;�7[=��É��(b�ٶ��՚-M��uM��\��X���������
!�5�x=� �?��й�����
_�� =�yU3CٍN:�xzo�4t�3V�x�1�l���*���E,�����^~K
�3KbQJ����_`�G��\��&��5��p�
���G�<�N����Bg]���4��L�@鬧��?���S���w�\zˈ�m��%��1<�|R�E4����.f:O<!xD4G�ݎ[�?�� z����uh/j˳�ё�s�z~Jp�L��&C?��u��4>{��﬉�Wxros���m�L���>o^r8_�����eB�z5�Ђ?{_�cQ�Q3��85Z��
w�tL��f*=�hy���*�p�뤌{�������K�"��jC���� lΝX}R��U�*��y�}8SV��E; Q�����+w�媵���� &Lv+y�;��e��Յ��G4���~������������oe�]���X"�ӯ5��R9�ؽ7x�r���g��t�������ti�F��"ܥ��!uzq^�Z;��#�
���B����K��9�j��Ew��uϢ=\h;s��;Ϲ��T3�͍%���7E��L-��J�j��z�>;{0^q� �����gY�h3�?J�/��E� $�ӉrL�J~����A���Q�d���������[�}{�"��n�fH��Ȃ�T��%9�	Ȍz�/��=�ohm��"x��r�\�kdZ�Bv�u��ϧB�n�{n'���֊�'p�Qx�Jo���� J�Wu��Y�/	x���U��$�B��+~���5S�lvA0U�yV$��L���H����xlMꬴ��b_��w��x��7��8iXK�C*�vN:u�-���b ��9�h�%�I���*�D�n�GyY�q �'�xB���d0tp���Duɧ��P ��ǸL�QA��<ʪO��\� o�ܙ
�1->P�(AD� ��E\'�%��BEa_^~&�U��Qz^l^>G�&�`��$�; �t1knfq���D�P�4��ZJ��l(�hh��4Nh��h�N�h��Z$��K�r\�/0���_����	-k�N��-�S���^G��v"����&��g)��F� �h�!���Gx؝�،2旄BN����C�����A�p���Ά��H���R�@u��A �)(�Gg[R\Tceܵ��p/�E�1l�a��r� �����r����߸�@�w^lU�V(�
�!<Z�j۬��w�J�x�z���19,J�YV5a��LT�o�)g��k����q-�'i��+jp������]/6��򪬘^ RX:���BW��%t8�m��u�>ޚ�P��Du�R�7o���n=;-_������'D�ӎA�+p9�܅_����+i��#4R�4e-�be=U�`pL8�rȂ-�8(�A9��yaS�Tn��:��y��jnmk5�3����:<jA����k���<���\F0�EC�S5���4��^����PF��,�E�*Z�_!Y��I" ~zA�e@� ^\wyjH�|�7'��1[Q:y�u~�=��F=�(�6t.���Jխ�X/t (_����ate�'D��t�Q��؊��X~���[����� �Z9��* ��_ʮz��J�0��К�J\�hSZI(|�!�(c�K��g�n��G���P��;�[��^t�h�����m��l��/�.�֔��^(GNE�؊�v��*�r��2���r��ѥ]����ɍ?�r��S�� D����B�/�V�	X���� �7
�s��_�!b�
�Pv=���&xmS�t�eT9դەL����x�Y��8]�ڹ�Vf��5-�Q��/�U��8G-�z���N�Vu����0���7l;�nG�)��3��
ɒ9���z�x�'���k���2�/sg���_2���'ޘ��kh'N�e����3@o��	��$S��·�/�NRt8u!|R�.����<��m��tbP�T�Fl�̨/?��qˆe�5�sALu��4U��>:�UP�gt�3˗��(��}��e��i4�_��Y��-O���#�x��g QIKKE����Ǵr5\S+_s8�~�K�-�b�Ce@�і������ʚi=o0t�яD_�jE�
sB>b��_%��б�LN���};��W��� �S�SP�����	!�d��.��,��:��^�mݸ'�ٹ��L?�����x�O�7Hl�*}��x��N�ׯ�ꀝ�X>Zpow�h-%��őrrN0�[�բ�2FD�'��s�&.N�d�J�_0���٪����|ؓ��D�����Ǚ�[�(��k����3?ۖ12P�'�$g��_q�᪖�?:	�4n�d�-�~u5'o߿�lnR�_��Y@�,A��"ⴅ\�qE��������/y;(҉b�:M�=N������2Q�S3!A�q+�I�Ú{sQ%��.�����g�+���sƢ��Y�*}���9K��IgT��5����`(�Œ�y0�,�P�����Ze��Vj[h�$��C%Rf�T�b��+Zy��L���`Q>j�(��>�C	dV�Pioe��Q��zY�y/�!%�$�V8vj݋�͍t���f�TI���	��?9�S�=f�e�g�j�鏏؂�S\i�z�J�z*S�L	gѾ!�����xC��p��olg��o�n�}g���#�,.����������t�C��+`k�d�p�+B�aG��4-`磥R��5�.N�Mg�S���Q��<�2	�V���-�͂�*��������C�!��������!r2���e�ʲL�wu���رu2��Ɋ��K���}�x��dd�a��*}�ȞͿ/0�t�o!t�!�� j��VvM�E�لHG�ġ�`�;���C+�B.A��M2�<2�Q��o6��:��UD���x=�&F�'��'}�J�%"/�
�T�/�5Nؓ6q�t*��w$6O�����3ܧ�3���6�����`~�����v�~��%��E=D�4q��e�����Э�7��fwy��g���k�KP=�wD@��Q��:�"7t�M�G�%/�v^�^��&�
� ��=N�����J���-�'Ż�+0~:���IJ�v��|
�u����tjcC�c��h�C��6zw�J�����:���:[�n�|�R(<�`��y�Ѱ?����	��Kưh���J�i&x�+4�23\m�������Ͳ8p�N�/=��%�����)U�o��b6�^)rm*)����6nQ���)H�!n�7�2|5K~�i)wQ�-}am��uAO�S
���KL�V'�7�a�Z>���h�挞� |�E5y��<�U�o����GCv{}�� �0�Q(I���Q�Bk�6�Xˆ&��;��o\��)����Q����xm�Wb<�e�������a;yMo�$�E:T���cЇ���%�����W�*��}_�p	��i��}i�����G@6o���S�*���u��2i���&؟$�^*����}iO�������ٱ�M`F�$	�3W:�w��b@a&Pk sM򔒐����rb�K|Lb����us��� ]�ь$��eah	�d߆xS���DsE�w�'��� �8�2 K�D�ș�@6���<#�d�6�N+I_h����g��r��]DG�1�@�-�0q���l���q�V��-�E�P���h��[����f��ԇ�nLmma��y9^��M��*l������YRؐl�R�u��h�_ʳ�1�_����+u�*�,e�٤U��_�L��:j�em[*i{��j��*���� &b^c���Ѝ���8@;lbt+�{"�(<ϗ� \Λ��)�pP=:
�Sc�,����z�ɡ��A�}d�{��hH	["X�Ч_�Kcz�3�L.����7��*�'	���y�h��ʲ��GN��ɏ�:���smm:;:{ֽ���԰�Zt�)4��� ��@4���=7];A��_M���PV�1K7}i� �f�ۉ�2�3^��W��R]a��I�C)�H��$� 
�ْ���Bf�]C�mF��Y��,�Ҥ�:�G�'`-nUU�ɶ�l�Q ���m��Vk7i2FG��3\�7�v��M&R�kE��80	O(�o=1�n�$0��;\fXC�UWB-�͍]}�|�Нw�N���Paf�~D�8�X����&]{�Uѝ����:��'�'^����M��W��s�.f�2����]0pP�z�#b�F5�>kR�g��?��>=w4H�@��ڙ�D����o�Ib�?O����HJ.z�=�ӉQ����;\̿B�e�R}\/����	��_��u,'x_C�X�y[i��#�qQD��9h��C��j>��[~�~,ݺ�KC�S�&�!z��Ż�h=U�P� S�(��(S����-��(��[��Ӊ_�V
���k+��A˦+���ݓ��L�0x��ƛ"!Z硙����;��$�r9u_PlG�]���-���5y�Ew�?���D�P�&B��X�ۥ�qy��� 	�'�D	=�#{���߇�>�SrȻn��]A:�d�8�m@BAdh�hR\��p��j�!r%��#^㛴�˒��e���)6���'�5�AZ3}Ik��Q[Wڄ�N��0S��Զ]Ď<{�&f6I�2���4��c*��|�����kw�Z�7�ߠ��{>� �y��x8RT���������	�W�~��(4�gJ��I�E�!��&@/븅�_?��v����"-r��F�J�ڊf���Hq4�{�S� ,Y�?c�50G����m��&�c��?e��sX#�N�<����U3lw�ҫ�f���Ru�����h�+��̼��W�0S�E�x��	[�����z��k[u�q_�R5��qqB�Q��!�d�0]<�
v.~�^N��(Ih�K�8Ci:7��x�ˣ|�"�a%'9/ �g6*�~	����W���V{b���ˊ���RTiH�0�=8��R�#=�M�u>�v��1=�2��UB�;!��hzX��bh�iH	��c��P���]���e{�����3u���)� l��V7�;/_W��k�A[C}��c�����eO�L���k|�_���lK���q��d�E7�f�J�#U��V��"�Ug>�"�i�N��<�A�3>��|�w��q�v:)l(U?�T�-|/1�֫{-��G�2`v��\t�0G�H >��O�e(T��o�_�t�n�D�œ ��H�B:�|�.��W9 �$�'�ZW-,Vr�Q�YL&N+&A��t���?�J����k�ӽ�?9r�DN=�̤�ޟr�T����ɡ�����{��({���i})w6�I�I��딱ꑾ�D�Dܒ�e�"�{oGߩ�d�~I$� �KP��(�f���%S�DեE�p�b﹫@-MxN"����(���Ցq�8�HUO{�vR�uj)q_p����6V��u|S�A�$o������7��g�=��_��	���=9Z;e�qÍ����F�E�[DYt
���%�3�kx��?hxe����I�B���_I�:�o��ö�;� X�O�D��jU�E��YN�/ω���=�ǫH����H)˱�z�	���^ ��V��5E��<	?��ԟ_2��V�#B��O�����BE�4�ApW���h%"�^Z���Or�U���;�4PΎ~���[�>����A������=�E����wG���0x&���Ȱ �އҝA3�sL����`��U*�yu��
#AH.~�%����S��'u����sӎs���S�ok� V�uķ �a��!mn-̞�������w���՘�5GV ��ƞ>�3}�*������u�p��q6�B3�J�&>�9}�@��� 6���)4���Q����?�h��ޣ�%Ů7�.�����chs����l<���،�,��?�9�ջ��h��w�j�a\���EZ�_�?�T��B�r�e��1sީ�YH�d��h�I��i��opI�{z }o-��b#K�v��t8��]M��rO��hm9N�̑z��%���yH�}�@$���E���=^�]��*	6K"���2�1�2�����'@��92c����5������
���YG71�׭�"�5�����jr]��+�$JcJXD�5��{4��o�%~�z�IiK�������uQ��l(.b 5O٢�!��odgyG��J�λ����L���o7�t��MhrgՖ5ZZ�L[����������l���.6�k��8��~�{�+O-���r[YX��Χh���]yŉ�Mf@�U!�J�-��xق��`�҃�� 5���� ��"V�4����9! '�F=��4T���:uC��ɼ��.G~:�]l�gF�P��XT*H�W��E�z+g��xh�N{�s�^$�o6d(�-�r�[���a��� {��Q%���E2�R`�c�lm%ew�V@���&dCDl��?-$X�-�B&� ����k�^0�@���;��k��Ag�1�9�����l&���Ck�kYIA]�2hk�<f�\�[�=w;2���db,xY#u�h[�+��o꘏��O<%u��ꯆ Y�5�8G:�h'�~L'_=���KF���7g$�j`���r�%5_tj#��6���x�)_6F>%F]rTn���}n����� C�oX8����=m�]���KhT��)�r�ձ�t���9�aG��%KVS ��_�z](1����Q)�r��c�j�KFT��ux:�5�^�	�W�P����R�(��� |Hg}��E����24�
�e�I�H�P��_xz[�"�s�˟��nZ�l�z��,��4��Q_=�d F'��E�ߠ�8����k������c��-��8�o�	K��v�E&aU���4p�ve�-�����&�7-�e^й3��B�� �`S�t/���+���+1%�b<�N�j5�fQ����|�"��P����\���&vt2�g����Hc�$��U���+]Jy�2B��h��р<炜!a���͝|C=K9��z K2�s��pG�!�-P�� �6#�t9�q5%���KJ�8vI��]S�O�?K����=)W��f����3&������1�
@s��s�;�Bf�`zԣ��V�c�t�ʞQ�����*���&�;u����B��o	�{d30��	r]� �w�v���[�׮�����l�7PL�f[['�XM1ձs9檚��a[F�3Ceʑ#��hU�d|�L�1\�����|�B!0��'�lX�$Zc�1�qo���[08��
���,��?�{l?4׏i�u`�O<��#+�v1K����ӏ�{��JC&'��P��tJN�5+�+�E�)~f�JЫZ0�lRG� �������[���vXa��L�aM524T"'�����Q��|b���l!s��p��"��"�7�E�ZF�L�f���H�c��N���@��a���K��V�&=�"Y��$rCIW�D�n��z��/�k@���E����a�m�1�!��, ���u�-`A���#��Nsr�p;�����.��� y����4M3��B˹!↤��LmA�2 cs���N�	�T�bݍM�Q�43��@Y�7��\��jcJ6W�O3�	���I6c{_��]��<�=�:��rN����-�}\&o8(�_n�D�R�}� �M<�O����>��%�ô�D��I0�Z ���������$�p�<�>of���ҿ��m�=Xvx���� z4�j�%����^��R-d9?��g�����]8g�"�a�<B�5G�?���
�G��I�i�����\�u䢢�N)҂���&�k��7��<��in���0�W/� X]�'��������25wĺ�]߄ڟ�7��������p�&ܢ��]S\h��lņTE�v���
�?ICe�r�+�|�FR6#������/������Z"
����m2�!J�6���:���l��f�*��n�}�O����	���Tn�	����H��㖤7��aKM�q(���]@���홁�J�,)��3�>�!0;�P�ꚧc*S�j�Ii�R�u��d=T4oU%v\�D\MM�|p���،[qm]uM։Z_�1+w��T��L�c���^��%��N�G�0���_�X�9h(��MX��Hg��&�J��ƚ���������}����ؓ����s���B��hH�f���G����aOrX��//jЛ��2#�Bg'���
�$�[�Uc�"��\a���{�"��F�Z��o��k��8��|��34{��!_׊{���H�7\c�p�;[V�^<վ*X��>^-�#�nϯ/{��+�	�.Q�0Y��:@�u��l*�7��`��=�s�v^�U��\�>�����җ���H���"�_C�����S{������~�؞PSR�!�
L;�缤r�*!mF��������$�[V �9r#�sqA�$�!��V��e�̾;h��-��T/��Ws3Q鬠�	�t��/� ��ئ�����af�;�{e��t��������G�DDbl����&؆��`D��$�d��s�o�y�\��l�a4b��M�D�g	��紮ؙ�������Lį���v)W�m��Ʀt�%Fq�ng>���о�?q�L�WKy�G8�$F�p��}-)��V����������;��4ȸ�����7�O߬rB���k�fݑ�9�u���� �t�3���!����czg�I�
8���5����j!�D埙%��җ��M���0����q��ः6�']��]mTo;+���O�/�g���v��+q��UF�b�~������5
 ��"�ˡ��
�y�O��pz0����}1�
ܟP��0���`Oƹ��E�˦�6V�^[�u�g*��_yf���F��7��
���LPH�v�8�{��B���&&I��8�85��I'����$$DU��/�&�<>-$uBۢ�w�������]��\�!5����A�2Y�4/�ǰ�{�]}����T�B����9�ՠzBo�D�P��g�z,�_e�9P�~ ��d�]�%"^��I&4��-E��6���G�<å��М�[�@���I#�N�Zɤ����uU�=�'ݯݸ�^aql];8��`��ѯ˒��LXo��Wo,+U�˲t�TfwJ�`�M�������.��S"�tmP嚂��X���+��򽦣	!T`�r��
p��1Z޾��,�n�K-�"@#8��i�u���9J���}�@���6�Ca�F��������g�[(��_�s���d;d���`��Ѱ~� �L���������9xQoڈs�U��A����J�Gi����I�Gz	��J�D7���@F�:K�`�4���v���x�-v���2p�}~<�ZW)[Ey�,�2xq���c1JQ)��,/f���2�,��Ѽ�!�z�u�h�f�9>����ԠROĶ�2�޵D�P���������e�k�����Ƞ��k��ǞrnA-'��[ޯ)��Ƙ��$�����my�8�Q˃��T�V��:��h�hY�% �.0�߁���� S����r=&�n�4[M�LB�v��b0�������{��Ow�w�^8��4	�Gr�?�E��RbX��d�ؠ�n_b��_v��IU�8�@����dg�xbA��oA���{�΃\�7�������z�By�у� �8�����P��]hdR9/���o}��D�Ɍ,�M��?
����xկ*�q#��/��a��f�I~�Ն��c�C.�LvQ�q�kz�v2�Z�n@�l��el�9���G2�z���>M�G��� e�����ij8��MO�=wG۶׆S��x�Q�Y`��r[�3�x&��Iε���pK�{������m3��g�.*�4�T��Nle\�ō�,�#4�MR���)4ߑ����-��"k��G���MT#�+\Ş	�
����h�گH%��r�E�4va�D��UtZ��f�eo�����N�Ѭqմ�f[T[��b��$����!hV�~����r����B-%���X�H�Իv; =��I{��!�&��
8ۈ�~�j���$��Q�{i�Py�d-�5"V�`�_�d�_}�z���1@�fO� �(<��~[>��򏅚�3�wRB�����.�w)�@�'��$W���\]F���Fc�,q�f�Y�W"J�G���O���'"�2�= �C�a��XR2��,�q�o�����y1��9�k���隄J��Tg$�W���7l'욛㊚Sc�v���J�"�r,~:�V��P�V���h��aVVQ�K�t���az35`H��a�Zi�@�'I���{�ă��D�9��BS
&�E6�űD��w�W�ͫ�VNG���$.���|3y�i����L`��BM��'��L��� 3T��G$2��A�F����V'�z��vq��*hFIø�^(�͑ d?+�b1�Kҡ��~�=��c�H�<��r| �ZTy'��!�;����⤩6y_��d�m�L�PUץ��M����k��
���������J�em�b�Z��%�@����
�Oo���z�`�4r��g�q�8#�%l�-��C�IO�Z����2-Y�*��a��$ ���b޹5�P&�44�,k����x��Z�q<�`Y;�:�$/��?|��tp��]s>�5���R^�{�f�]�3,�x�c
��}��� �Μa�hA)��l�3ؽ�%��)J��`h�E~q�	�c�TS���qîc�F�u��3���S"��p�y�.^D��a��\�|�?)sb��&Igu�g�M�H��[���>��J���:E$�NJQu_��^�H]�j����QKN�Էm*#W0�0ct��425c9SA�K����:��;w�2�(�̍�3p�`o�U.���RB��[�d�#6�D�
�M���h����'�u��UI�+�����M���_�xTuKx��3_�,�� ����������lG�ȍ���v�ĕ�B�'����C�w��\E�Ze�LǛW�(θ+��R�����!t��X�R���9Ÿ��Ϧ��@�ں[�G��YD(7��]<H*�.���L �oc).�{ҎL`Q���$�{�0
�r�y��;���l�j-]8�/~�y�����_v��<qn1U�)x��:x}��<d�Vq���0��Swyw���6A� e$`'
���&�ĒB5�������zkc	to9V�k4u�94m���ՙ��'��:�p̩4,�"\z}�<��t�������gu�Q�QE��"�@r����~M>q�Бͭt��,�X��r
��O�'�u������5��=;�1)�oh�g$Pæz񐚤�'��S����Lr m+�s]l��G��g��`��ɝ3h�@��(�	�P�)�l����^��2���#D������q����+w��h��1���O�H�pl�Cm�����u�,@Lq]ix���*8A�Q�4=b"�}I����i�:��w����V�_�Ҷb�A�)�m���rd<ڪݐ��+{^���q�/����d����6���n^��Dc�'C|�j|����\=�}酢E+"O����A�ֱ���9߃���Ht�b�+�^�˒����m}_���m�
�Q%/����I�j��T�W�@�v��p���+�0 ۢd�0�&�Tw �����RU%ZU�#%C������z��.��Y���Bgߡ$Ɉ�[1 k�Jq#S�(h���9*��wVCa�cR��,��xh-�OWi�U~�q$���#{�Mn�mZq��e��`�M�_j���<l��P4�8��������|K����`�����/�T��j�2yE��qȰM�t�7<-���N���hCR�/��� �-/+��b�O+U�q�K�����*��Jn�i��1����B�
�X�_gB>V>@�;�1�X�9$�Ō��k����]���E���d��G�ri��˻tÿ&M�z����n�H����`V�Q��@b�[^���o� ��lcW3m�~���������.p���Lؚ�5'LJ�}fT�YiseQ�@�۰��$��K��Ci��Kꙍooe����P�v-���W�)����8_�}���f�%t3�@)z��hP�8Epl�Db���_]1�zנ#?�f�,(0�s�{0�
�<��E���ʅ2��;�����B�٦��5ШH!��X�ZoE�$I&kz*p��P>�rϠ?=���I
ye=��	xrnk_�b�1c�c������8��TLY[��z!��Zp~���p��1���+���<h7�f���s{��4s۹ti���yhMƳ?ϕ�.��R��`�Q.U���9���N&�G�!��,�u���ɦx����E$��e:�Ff{�ήC�ȭ���&I�IPL��Ϙ[�)V�/I[�����ܩ����R��k�)�SNū�PV��&�^�������ӱ���嬝܇��m/��¤1h���:��-j]��'�T�%���.Gf�-\�����(9.z��&��v��
>�#n*̂���0���U^��-OC�s��Hv�q"RG��YE92�.�&;?���-�K"���8�L����@��ٔD�{��A��-Adzs/B�{.��㹏4!�]��x	_WwW y��$<�9��п%�,�����h�5��q�0�0s񭯰v��H�gZ��z�v� ������
־��P��J&���
_ua�7�����B�#��K��6"bq4��f����O�����M�|dr[��s(&����qg����A��0?�x���_�����LZ�l��B�t�)��3�RL�:�x)<�
5�B:��ZV�^J���ȈJ��5���-�	��O�u�����'��P��Խ�LZrd�[�Yz�(z��I���]�r�嚸z}!�z��;���;���y��>6Pv�&����g.|� 'D ���饓���vՑ�
�T�=��]EG�QR?�����]��CBas�Qf�v\VbɆ:���,��vY��{���Y�E����q7{���\-:� ���~�¼Z�**=7
'��_U̙�X��1g-�6�7���;�/ ��i/<XU:�j��KAk��ͳJ�W��۟e�eΖ�gJS�Liɪ��:Y�P%y�0��>�H�lj$����B�H�]d��>5]q�LP��g@�Lp3��;�h���
"M2�W������q����b+^��w%]��#�7����͑��\��Ckm��2�3/CY<���GÙY(���6DH*ڀ�aTڭ���h�d����8H|��]4�E�r���[�im�{r�� g;����;�m�Hm�\�����["$��2���=}�dX�E9�
���z�;��6!����7�t��SEA�x1�:�LRm�6�g�n������F�݄b�I���L��ǿi�*�lyC������kg'�nU��6��@�f�̚F�d��-ӏ��M�u�252��HT.@	B�q�����l'��"�e}��W%;�a��˅\g��[������fg��z]�ttg��[jM�mq�!�P��
Go���,;����0�*���k6��2�S(SR��|d�g��i���k1mj��&K�V� �%�j�I�|T�b��!`�z����X�����AS����՝�?���������Uj�IhNOՉe�s\aY~��\����h7���jE`��{�/�zw�
��k��&:��|��b�N��p��6"|��
�@J&��7⁾��uBcnf�6����z�?0����&�3ezh)�h�Q�m[:�fi�|�N+u:H~3I� ���ى�)���S��o�Y?�l����3.X�q+?��N�Ļ���.5}� �cº3�����.>�l��xv���Uu�cdO
ح��('	[�5�
c�7	����Ȧ�b�;c~xN�1���f�?Ux�% �6��>��l��TF��Gi_����D���-��ִrE��$ZH9Y�~�O-ބ{���O�+m�)ۜ���qV5s�Ц��EU��Q�sk5w�/�6*E����@Ͼ.�	���9��k�d�Ӵ!��p3�
��/pS˜�f���A���	�|�r��V�.�m�D�9'|�NI�9uny���m��SP�����̺~��TR�>���2��
��g�֗v��-�Y�'�8�9��d=�-�@�+6�|x،���aN�5�>�~��l�+���y�C���"��k�@��^	ս=�L���	�,�bn���!�!�( ��g1�R	X#�D��h�kd�pDF5�F��u�ss��_�0uQ�����+��1BUr�v��V<c>�y�e�%��t'Y��RP+y�9d����2�9{�Z:(���%��@7�3�;Xt���T��A(KO���m ��1�M��ޛp��=�)>�%z�Ia��*|�m[��60���)|� m;��N�JoyM�¨��3�`���yn72"D����gw�#�*�wQ$��ϥG[�8��R-�l>n��	���Q��n�'�`���#E�mRV�G[y��<���B���2��}�$� kn�ՋH(߃�(7U�ah���O�cM_��VIf_��a�W�B���
�@
��o�cZ>� �w�#��IN��;������(��"^nn��/ ���b��mz�Aΐ�CY��4떹��tz���p^�^�O��0Q�d�mg��o!	����L�M���\�zo�-�������C�q����7���z�9e��û�����F���K�M�҇���ny�m��`�>=�ϴ�4��a�����a�q_�w�E��ż�a�\�}p\f�'\�
���Lu�T��v#��5JC�9�0�v���i��7.&)��L�R�z���5o�>��իh�*��P#���!M��ݕ��
�|��Rn3<h!��t�o���qR=��U����p���[2�T��m�]p�ע ���z�6<��_�4���i�?}O�%Jsq��$G��z�`{I�]\3$	�'Y��%�V�'�����OfH�j�έ�]E�G��J�q3ô����@	$i��]�}xh��-��?>͝�(zN�>2t�qY~���S�%�DɂG��V.�
�}9��W�(K�@��a�i�U�a}�Tq���elV �mɅ��O_>�c��¨M���Iף{��=�<��&���E
�D�'�o�RnI�Hc��-�!�A�����Xk���l�dW��"��f7��*`Ҿ��D	���~B��dv�|q���<A�.46�4���,r�ֈW���������Q����B$�^���g�LGK��D�x��"bʂ�s��h��X�����Qr�%gr�Mϒ!��e\7M	e��O��,c;�;��Di�{�bQ�H�������R���b�:$�%�3��H�Z���y�ə��Ҽ�`ah�C��g5�)x
���/t/�d��@�/�0�����V�l#y��w�������	ѧU"z��k�@V�~�x���/���Ň�B�D��8�b���yF�,�7퍂�����J�I�������@1��{��嵎���;�mŚ.
R�*N'�����y�l�]���gG%f+��0���rr�;wx�;�0p}z,Of�.���sׂ�
\�G#ކY�Ϟ�M=�6'��F�5|���E��<����B%�{L�d
E
%p�nc����z������������L����g��h�t��ڲgͪ؍W���g�{@�;(�������Q��5��G��v�(5�� �	� J���l��s]�j��CT@����_=����;2�Y}H?7=���#�zh��c��wA��>�/�$�b�z���pq�^���AU��Q���µV��IA�2�hX�QY���C�˽�X���.Q��"+�[��1H�q���%�V�ɾ+{ʅT�C���ב�����r�H�Xj}�(��M��qIt���A�U�^dm�hk�aDB�,i���P!�Ϫ(ֺ��N��*+�ۣ�T����+*��S�,�@U�a�nǐ)�$]r�q��tʡ�(�)�L�@?��٧d��|:����Q������u�Dݠ�+1*S��"j���0Q�y�a���� p^2N�\Εh�����/�F+��+ƹ�4�apԚ�w�%-r���ge�Z;7�v��,��ǩT­���0k��o�7�3���GQm�9¯1�&�t���V��,�)���b=?>���Uv����2La�a����>���ܡ_�f=��'�쩇؈dk��/�2���-ܷ��=Nhm����.0	f�86�]�I����}�(���<�/�Uo�}�aQ}f�󞆤�V�rޱ�<Ϋ�B�H����#�[c�����Xf,�J�F�E��p��&�`!��hg!����r�����U��y����	9��XT�z-��J
�MHi�sZ�T{l�=e� ��́��'ܕ7^J�j.˻��Νu2�� �����w�	����s٧�[��N
�}��<��ʹ�oQ�x�>��)?c@Ɲ[�p�m�+�w�ex䪖r9.�d�>\��gHU���s�dS�� ������]�m�j-4A�0��^#�����uly[�Q!<�x��=1�6=vlA��1�qs6z��Oo������1� �)�^l�>�@�Ӧ�+�ޜ���']02[�X�ۛ��E[*}~�������߲:��
F�1�qG`1��7g��F�,X�T|�gC$i}�^zu��)��}�8���P�ae��C��\t_T�l��=Y@�!��p�u��w&Έ�\[����Xf0�z�ޛ�7�;��>�O�aD��A�n���$�
��VR���`-�ȍ��|�đ��0���f�����T�ߣ��jr����������r�&Y2�i��n����i�w��{��3[�(u���v�
#��)i,Iel���#[��<d,4 v�� I9!�QH�cXD�@�:QU���N�䰭�,���Bk+wZ����R^�0���*p[|���jm(H������+<Z�B.�R�<�o��P{��
vy��
<7�5���c*�Ӣg��o��r�=9�.ҡ��M ��4n�7i/EE���qԔlPeb9TA���`N�)z] Q�u4|��8������;"E��$��=�3Ǖ�P��pe�,��z/��k	i�u/��qQF�1��$̚�*�"k{�^��$�t8��Yao~�c)U��ù��hID�����l��io�J��[l�h�0��)G$��������u�"�yx��99�E�kԕԍ^;�n�3 �&M������p��MO����p>�n�P9��_������h���Z�g�T6�q|H�.����nhy߾��g��K�2 �i6�+����G0�J{�q9����/���hd��V���~SA�h����t�1�Y!�'�g�k惟�˥�{�o1�~�1�K��ྍ�^c���UP��g=��ix5w��u�8��xRg|�<D^�� 
[��8༔�L�Dk��3 E����T���b�NJI�.9�.N��	g�M���E�� k�t��zXR��:����/���}Q�he3�׾e��}�	�����C/�I�K|"� t:�:�:!1�"�tȏ_�jA%D7$���u�02���Z���';��~~��P�;��
�U���Cdxg�{Ԓ��N�*����iMi��`c���
�X*&�c_8�@��C<r&��P��{��S�.)��8'~�.�豯�<���T��C�V[�7��-n1
�:H�`s"����(n�9�l��2������5��j����ø��Ѐ�����`pt,��d��r�$�j�5{h���;���c���u<l�*��vI4���y����y�	�g��1]����b��D��,6vN�
$���&s�|F�����`�o��x��aKb�W~���W�̈́#�.Y���cmE"�g��O�Ն�X�G��s6��Z�⟪��4m�iJU����FA�<���~H%�B��d>S��cCPr�7��D�A��b^r��t���Mk��"�7��!m^P���&M�j5�\*� Gh�O
X(��H�[W#�7�N�ae�S�3��u;��њ��]�IWd*T�hl�E�E���+����L�S�/���5�X��
搗��;M�KչלGxZ��� BS$��j��k�x(����nb1�#Gz��Hd�%놄�݂!���tQ��w5~��g�N8u�l���v�x��.f���21�̫��_C0�ʁ�1@�e�A���n��f��m��\�ŨE셜-��Dދ�3i�Ts+Bۄ��w��"�0��)n�ߏ��	q�@��p�b�-��VxvKZhdb����V� ���bBt�f�Ѳ����w�6�5��B@�����*Bp4P�{�����]O`����E:CK߫HQ� d|�a�K�l&U6��X�h���#�|�W�d�����N�_�D��9�2� ��m�K�x�<�Z�N�CĘ�<��rW��
N*ڦ�"��t��HO��(����:�{�s��&����k��}�xu�p`!ߋ� h��ww����q��7��a�ԋp�L����ж���[�ڗ҄�(*��zɥ�XY��+�VNɠɩ��nA��6�����>��[چ���gc�(΃z`��Up�iE��A5X(����ij��HnNJg�)koo]�0�$u�AZ��}%"[��w!�^q}w@|�����%����J$TWzdl*e�êf�?�t���_R��sZN[S�K^��`ϣ��8���u]ɀ#^��Ve��0�����mH��,�-�Ȟ���s�JP#���#��AGഺi�8�\��L���	����7��R�q����"T9�A���z�"k@�����5�W��B"m�2��0a01��Y@QǀR�TlF�k�'⧨���z�;5,�����L{cI�.Ş�U�`�Q;wݓ<8!�� ��C����^�
���}�k����%��� �~u�`t��ۺ��&��v�*l����*�F�iL[������I�冩®�	�S�L|�f���٦����W)	<��I�i�b���o��8P��
�^��=�/�8�dk��gND@��P�>��=0����ì������JϽ���!
��Ģ���*P�x�;ɠ��d֟v�H<��`��4[k���&�MAr��D��I����s�pm� ���(9 ?%�QNQd�v�⹝�'Pd��WpW�=CfCy��y>�ZqVR�u ����gC@�	�Ѩ��1o�B���V���?��|-���Z���ii��+&6�i�j��"˭\�����12�1n�К����&I��E��D8���c�F5�ٕ�G�M`���nr̬�U� 
���t��9��nZ�q̪I�8�U�j��(������.֥Z��zLRmط�Nz�mQ����0r��=[��G����x�H[DU�9���f��ƭx�FӬ�Ο�9{�-k.'9Oʢk�ٴ�u��ܢk_�ߴ2@�[�gb�R��I4R�
|;* L�Շ����M���cȔ�ʠ�*�t��G(1$�v����<��4��I!��_��S��>�A�NY�ST3p8`��3��K$uz��J���}/�*~����V2�Cw�}lۘ��:X�S�sO�y�{A�W(g�9�����\�`p�#�ޛ�;�R{f��4GU>eË��c`}c���&}�֤5�#L�+Y�	��������'��Aӭ�y;��o�܆A[6te6����Ŵ� o���[��':�N����Q��QL��FN1g/���e��2<���7��:'Lm�>x�KFC
���:i�;B�[���E
b`��1�����k�[u�����RD�ۖOg
<J����к3���R`�	��A��ؠ�4���!��T���w0!�XY�����O�H�Yq`�z(��q�B��eG�HP�\b����{�!�P����غo�|`i�����m��tA6*F5��c���C��њ�#N�ɻ���{� �;�����UqY�3�b�!!M�`_�� f����� *��d�Ȫ���eH�����l�����B�季	7���RCE���T�3R���`�G��]�H��3�� 6fc��Tr�S�|��ڙL��+;8 ���1aMB])���.�w��$��cI�,�!H� A�T���4��XͿ1U$��ę�G�!H�������g|A��R�~N�]�M�mM�:(#u6��CL[�To�}���o�9�%��
pK������4M�#׍�r��zR���l����w�+��sXy G�"�[äk�v�a2Qe����_8�Ҏ
�VY�	B��@�f^��ykn��NY��nP�;'P���j�ˇ���7O�"5"���PO |�*�5!�t|�����7,!��!�i�_;��D������;��:�|��Co�'k��.~���fV�X�A�6~-��C��	��*��i�s{���Mh
�_�ޔ����7l.�#��^M��T��|��U�1=��%<���g����&����d�',�vw��k�6=�ÄL �Fb�%W���#��J��=I�{����K���<�����
Y#��rD*���{�� �*wG��p̭+'؅$o�S��1�c���h��^ ��)��m��cHd����d��}爝������y��툦;YT5r�d�����/eET�NK����,�N�j���5J)�a�c`n�̥�Ѩ����9�)+'|IHҵq����|��uF%�@��j����x֪1S8>����9���r ���
.���q>����i�=���巉ǚ5�Yk~[Y���  �oI>��/c��2�>��1���)����%h���4*_�N���Ƙ1�T��$yV�ED�u�a�n���\�̥2<�g��R�P�ae숴Mji�P�v��Mŭ+��.��Q8[�ÚZ�8�"2�?ځ8El2u^(��ȟt*_UC���x]�7�;�߳e.xmL@ )�l�ͻ�T(=��=���u�~�z Nj��=�v�?CW1<�� �Jie(=+33�9���*K��Zp!Ba�Η��3�\Ies9M�J�ƃ$��#�T�X輯9�kä�Z0�.=����= ���z����H����K ����Q,�G�V�s�eHO��b�M��y&��C��!��ύGl�~j@e|��M23Z,��B�c���%�Q>�I�Z��'.�1��_�Z@?B���Z�� &��	o���Y8���[��R�-�6@l��:亭:?�-gi����QH�D+��l���8w�{þ�j�����v��_gPA��z�L���� �G;f���"W�[�\,R�I�6g@�1��ː�W�N+7�x��&�Ԥ����~"�d�G-,�p�V�)T�t�w��ifg)����%᭏�GVm��v�8�ܜ7���/*�EA��G�z� �(`CbH���i��x.�;Z�&�l�N&L���2��x����U[�l��@�p���3~�HG��`��X.�/��21h	ڥ�?ykl,(�6C�#	�*���8��
M ��Q%�)�t��'~��_�n�� e|��F�W��u�
~����k�zL�2�_o�j�l��CU��&��6��5^�uãsu���LX�����e�w���K��8��1b�/��X�x��FR�G&�d���a���ю�IG�Y�Jx�-���$mG����#G 	p�7�>���ͬ���Xr�Ӊ����т�s���&��T�]t�s���aF kK'��h��z�����$X�ś5B�M��)�hׄ���u�Y���{���@,(:�@����k>��\>�8�4�=��/Ɲg^�X�t��yZp3�����ڣ��P��S�>�$��5����<�GH�j�ڐ�Ib�RA晟�>�~�#���P6�F��s�w��؂~������r*��ᶲ#饶:#�[�ɘp)��.m�p[A>��F�����LK��xǜm�?�Y�p��wz�$L��=-�6�Λ��'��,�T@��K$��]0:H7Zr몌�*�-�O�Ь]����H:}�߯]KK��s��o�/��b�tŗ��,K;П� ���c)3��tBT���6�̡��n��4�r   ����*�4 ����4
�0��g�    YZ