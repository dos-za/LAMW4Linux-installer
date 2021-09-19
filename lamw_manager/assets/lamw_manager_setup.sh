#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1777291718"
MD5="05758bec955022ccaaecfa3657b3f9ca"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23812"
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
	echo Date of packaging: Sun Sep 19 00:17:40 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D���4�9,�n>lD=eV�A
TF�|����8(�K��_{��r$yě��"�����&\��CCX�(2��-�G#�l�$�q��'�wk�$���eҎY����~�Rb�n� �	'�nc��"�,Ox{�!d�2�T|ݷ��v�6�����p�+�H��I���u��O�x�y�y����I����r���_CTv$B���z�+P�
C�jȧ��:xM�M�����Ax���
l!�/�\o�����7�sԡ`�|x��r������y���b3����ǙV�Z	Oɛٙ9�rH���}ټ�p���#O^��E��_gGq�HM���|=�(A���|R�T좯����p��_�=�|�;4�9��2�FbR�?�����p�~��߾�d0��@���~�O���.�5Y��%�İvV��LA^y�-���zJ�)��h���߉"|vFӮ�AL��޵źfv�ll�5V݁���:��N�=��!����D	-T.ۊ} :��R^�Q-l6�K.�kj�_�؞�����Qi��-'uy����M�

�bU�+
>���_��e0 d�A.����>:��DgĮD����nl�C�b�)y^�PC����dpaeׯ�Ne����y��/�x���cWM�L�c�d�ta�����'Q�����^�_�=��7��r�/"��"�O�jS��A����\ y�-��]{A¨��'����@�\���]akմ�I;Ķ��j�_G��J�����&�DM����L�Զm�Za�C3}�����6D��rD`��Eu	"O'���(Crl['��MuC.Ҍ[:�I������Ho먅 ��O�ʴsyG��3̈TfjY�C�-��v�14�7�\ԒE!�(7=Ei#
�<���uŊ�)����������9�柷V�����D�G��ZWW)q;x������/3�0H{�7J�R�k�Z����1!�Li�P%*��b���q.Ҧs>d�����x�R
q��"�eu��2�h< .�h���%&��1Ifg�d`�
���/ |��ҵ�bt�Fz펮v��E�b���J]�a�ur��A��ĔjpX �����þ�&�T6�f�͸y!6Bt�9i �~�E*G�.����!�c��3c����V끔0#�#x�J��v[�hK͌�����W
������l�����4x�fJܮ���]��*�%q@��(d%�[@ҐC������/C�"��e<)��ɴ�|Q펚�#}�W5�z��il�
��h��Z��F�a�̢�O�[�$�v�o8���o�N'6X
�B151��&1����#W=���!\����57P��n9��6Shi�]����!+_��<VF黝���� �~���4C
��'ى�F�t�0%g�9��a�E�EP��{����B.�C��� b�R����-����Q�OE	:������3��.�6޴���=r�4KC(ܴ2�h*��A��`^��p��}�P�Y���{�G%�׉t�T���N�`�&V9��@i�MF�pX�k��m�!����7�{�v���H��C(�ĦH�B�%e�@T��Z$��~��g!��<[►�,�b��<4������v�ޫH^�O��q����gże"t
�9.��0�<|��{��.��t���6���������.��!R��!?i^��9J Pq��0e��kl�������-��ߏ0�=���W�0i4��6�"�|��j� V�
3�[�29⹏�o�p[lX�E�Oً��Ѯ��)"K�+Se^*���7����F�m& )���b�M�'�����F4&W�a���.\�q���9ޚ�mPL���u�C��#+<��!c�p�Y���}���F�����C�	�S����
ضχ���"oC�m�n���ֳ��k�EGҩ{1ў�Mw�|4&]�0M8Ȣg��'݆�Y�S�Vң������7gY_�� ��J=v�����3�3�Pv�����*�{n�fDKj�w������P�ɮ�2�\���`<��j�T�w�4
!�!J����`}�4{�h��?H1MmˈXK���]�ޟe�>���FN��]��q�HE�I#q^K����!���w縠��샴eB��B$(4Z I@#�L�!bM۲4g�L�?Z�B4�4V,ax���M��{z��9�LX��t��(ss6�ЬDɅX�lSwI�,>_��6��]����B�,���VV�yte|��"
��r%4�D�3� r�j�}��7��	 �2n n�pi�KZ~�s�ب�1��Ɉt����'�g�ˏ��ғ\�L� � J��O A����-�XOd'dvW+�)S��D�mjۨ�ߡX4lЬQ�SP��4���E�����I"�aā$rw�-�B��Θ��\�t2�x�������w����R9��O�yo�F�/�g��KOJ?��He�ɉSH��;���y�♳�XE���� <(j�l���$�y�@�z�F�䬓�%P�篘+��- u��w�,�E��1���#G.ɛ�6��^yr�͊��t��@�UTs�K�e��&���Bx��7K$=",�r@�D�>�TiS;��@(��њ� )�D�pF��сy=�_��XN^ϢH�A��گ�1�*+��|,P��o>,�>E+��&A�5	�ME����)�*����1�Q+jI�! ���׋���M�Z+���@T�rd��WRxll�V�˲����b�9]�<���ߩ�ѐ���&w ����% �o�PJ�X�����{�iT��v��:�	C7=�t"&X?w;��Σ���-Q����?+W��� ���=�q?u�$��sf�;%\� �{h��	]#mY9{1eP�r6|���ɹ�Y$�N��B|h�9!�LO*��W,4uZ��l�����w��1k�(jg�E*0�o˅�7�E`�Mφ9��$,o�:��<Q#�EpJ�@8��3�Km���]~T����s�����}�
���9��yx^�^Tt��	�;�W�lÞ�e?�U�����������;�F%� ё$�G��i�4	hm�8�u��Ǆ�t���ǉ���I쒵ʔ��LM������[����l��@�p����~:��D�ō�oQϭ0���G"�pi�<n�<B��g-�!���:��WM��H�s��l���_�U��֜a�rv|�}��t��*3q��d�sb&W�Y<�K�W�\�8�������>-�}h(�d�J�!�a�4�� ��,k�p���J�O�"HL@9E�-�%c�Ԓ�W��݉��.E�j�����_s���ᗰ7�K?J~o,������Y%d�W�w�d}��m����K����9�w*a��Ha�UtFT$��p��)uk���! &������ �.�0E�~>�M�>�D,&H6���T�|q���I��kMv�;���w<�B��=��e���k������-���J��7>�0�*7lpk�&�������_��~l��o�9%#\���3�)јQr�R$uvC���[0	����.Nǿ#C�^���_~���P]4�m���h��*N��;-�z���f��b,��Q"�rU���q[�8Yʼ������EDSPV��F��sgЯf|��}1�-�l��C��;�@8k�+TE)�����2�s� ʕ��!��q�5���O*2��s�yZ�����R�����1�}�O�r+���.f)�T���(ݦY��F7�=�X9�%�)�>�lH��(R�6h7r��W��D�/ ��4i�NG�k�s�3�4�UDDkz�L�2�֦*}A)0������\h�Pk�ի��~�g�N��d�Z�G߲�;�!i�E�L�9t�h�N�����(_��.�:ZyF<�n1�Z��e���hц��W�5��v���[��.	�;����I����[t`I�h����� �����1����=�9��?�[�-<�E�#��{ �N�(7�T�a�Y)-MJ��kH�Rf�3=�y1��]>�YZ�\!�2�f$\i���!�f�9a��f<�t�#b#�d��9��a���N���kB��Y�{�ue���9�JlJ(�{@���T*�i��9����מ*���l?�ƴLka#TWb���1����M���,UVoS-������Lx8[�e�ot����/�`ƣu�Id�'��B�`�"�<"��߲BT�}�!f���� ��(��u�$�5�CѬWpg���w�lj�s累H�NzFB�?����mA�m��2s>q\>��C�I�/x�^A$��Z����%�G΂q�y���٨�Ƚ���A�����*�9di�ҡu�W�1�o���=l�MyVX,U���W�z��:Z��DeQ�%.ݧ�>v���i�&����܁��k���RDL��`�fS��nǆF�Hj"_��v	�ex������ /(���|�p4^���;�4�������p7�1p�7!l�0{
����`�0c*��:��`q}��]^Q���j�MQ|�Vo��D7�'=ee�����p���>�����O˫e��CSPI[%��X�Ei���Đ�:B^��qI�o�d�v>�l��>�V�'��ػ�����He;��O#�8{>��A[ ���w������	C�
�P}�,�d��6%�5����N2�6"�/�l@��:p�t`�RT�u�=@�݃�͑��l���H�*a��p��FK��:L�L���M��Q����.���́v12�pĦF�tE(�>�b0��V��`"��Y����f<	RU�5b2z�� Hv�;N�$<k	ߨe8o^Μ��X�V^��W�H=����Xt�3T�p#�5|� �2
�m� ��w�*�}�;�����Ϟtb<�+l�7L%��4�@l�',�I��NL
kF3O��_�DK�w.�Ec�)v��[�o��=�g�×4��o������5���y�o���%�qO= �*^il�rp�ii#�:��m�.ˇMX>`��fa'�1b���R�]����8j>�~ R]���#-��2/ĝì�1�F jvI[���t6�@7��ɮ�ʇ�C��u� Tt��r��P�!���O��n�3��b��x�����p=5����v���� ��&=�AҰo�`i��ȓ����Tּ���H�� dy�Խ��i@�3QY�U 7p�_Z��d����2���9�DK>n�[klϲvQ��	ū���1���,�h=�.�2�-j��E��E��CGo�]�P)�U���Yp�@Lv��7$ɖ�p<d�/
\�7\���4�V���4б�J��(��B�o��6v��Ay����.*]�0�ǒwc�J�������oqrI����F����J���g���R^f��6�
u����{�S���q'�	 ��7 *�'a臤��|M�).,�!���Kˏ鷓v���Ǳ�#4i}��\��#���J��B��� ���9�����o���"��M*k�E{F��/|yi� z�����Ιⰵ>�Sjw���|�v7�ѥ�u:V�<�����wԚVY˸}�~�WA	T���f� ��͸W�� �j��C�N�Kx��}jA����R�I t�b�O+vBq����:0ڥRܴ�n�uwG��Dd+�q7���DK�K����\2�A��ۆ�rw���/C���0N�Ӷ;�o��M���-C�@��P��4��$
�����ke���ڬ�L����m�d�"qsR�qK_�4^��ܓ5r�����M#�J��-d�o�z��r�{��"�������F��p�!Sa�P��^1,��p6���zy⼤;��JM����fsCq�x�Y�.���pKq�[$ie��#Jx 9��/|Ǖ�^�UG#�R�]*b��=G���:�PATY9(C��S�����G�H��px��L�#i�J���j��9&����)鸧�����k~����.�<�=�f�|��<�R����V�`S�6Ǉ�q����(9��bvP��Ƒ��ޗ-���6��}XY4"���+e��U�KUq	c��y����l��n�����׈�&�"��*�.�O�8 N�rI������Q��hUc"a.́;O2�~�o�D��v��S%D���G�{ě�q��kZ���|���/� �g ��ቌ7S\��Lм^h\U~��{��aajf��ף^A����v2i�D>�0�N�Ѻ���� '�M���E�F"a0ذR,GP8���9F�����(�W���dF��WG���r��͊^�2+�C,�,�	-m��{3�z[bF;!i%`�Ŋ�[x����e���u_�\i�G��Du,ýR(�������x�;��������=����
{H��@<��9�\�8�V�	��d�;�����-_Ò��a3p���k�P/00��;�s��ǎ�`@��<i[���U��,P��y���|��" �4;�o�F@�S�˱�$�nO�tC�<����n:����!r��yV�t&����_5:�3�M�ڍ��s.h`N��Ua���!�*DĽ�Z[ܫ^�څ����"�lL�ev�.
�s=��
g��?T��Zh;yQ���ÍH��x�_m!ㄋY�f���>��tf��H�lx껹�5*6�	?��[$o��H�t-�<��mNمXPN�S� 3�s��١	��lPw�s�0��x�|���N5�4�@�dV��\hU���-���5[9ow��R2Ҍ��Ӳz��&x�Ж�����yՕFc���D"��ek:��!-ݭ���Q���N�3�X�t=���Ne����	�'�����DW����\�r�7K��*A./L�����q���bp�.$��3��ZJe�mN �ʱ��x"!�nF��<�g"e_a+�6sO��������M�=�?_��D�q#�����~�%\~�>s	�,��*��÷K�����^h�QG�/d�z����o3�r���/���/��i [��ΤA $���Fdpƙ\���4����E>cЮsa��IZ�V�`�M��u�!�y�g�zf���j%�T����F`�rPɎ-��	���'�ˣ.�fk����M��>�p-��Z��h3(a ����?���*Ʃ{|�x1��X�y��4�����X�eW��KvD����
E���T̅�^6D�6���Z�^��\��D��E�Ϫ�}�f��`�{��E�r�+��>V��j�
�����|�XaNV4#�L��
$�m���*�:lV5 t��~d��[�$���sW�Pó�?X��yZr�w�o/c�j�1�:j\{�{�j�"[�dt��;l���c��b��Zk�a�7��mZ,�*����[#� -d`���lrM���L���dݸ�	ք"����i���vbLg	7��܍<L��r5~/{BU��O������/�:����I�-��"�dE�[��,�c� ��,E�B����ݹ��::���Z(E|�)�,j��$�d��#sE�Iʄ��-���ɂ������ž��s0�����mbU�j��	+u=�����4`� �h`��<��IP��3��h��yk�b��]�q�f:��!s�fQ�#�k��Q��LJM�����Yw��P���}2Ta門~cֈ�%E����'�bzGl�!s!$�<ީ�ʼ���/1��֨W�������f�usѕ��������qeo&�g�Ԋ�b+k���"ŝ(��fO�؆h�"0�(��!�tP�;��Hf��x��:�r�a�!�\}UX��kPqe�j�͔��k�<5����0).��6�3l��*�"���|���������RMS3�����"RM)��|ݚ6)]|ebG3Sҏ1fq�*Ԅ���Gh{�&�IkM��q����T�]�J5Ͷ��%�#A���ܒ�Gt���Xu�	׾�[�@m���������a2��M_��Ҽ�Q�Olٰ3��/�!K��.����(�ģA4fh���l
�r��Љ-k���(i�Vw֮���PZE���r�C���`S�a�+�1�'������R~U��{�L���s��!��@"���'�`�K��j�u�Wl�!�� �6�#��������b�p�}�]
��
IH�@������X�oOl�;�j��Y܎K:�I� =|۽]����E�WN������É~Y��>��3�u�S+kRZ��vJhp�Z���VQ�c}]��A`��;`Lul̼يaP=�'�`v���N��n_B-R���g:�H�Ҷ � 1T�}�ls>��̪tU�B�>�U��6�˗	��(��9�ہR����Q�=��/�Uٷ�d��AB쥯�el��>��xs�4T�NUm��e�ŤKҾۄ��J��2ñ_� /G���d(�Y	&]Ze�>c0�X�l�_Mb��
�t�?�!f����b%���=����|�/f_��|%l
�> {JD$2kW�hO�[܊�%�%��aWL-7��H�vb��v���������P�Ln,���TJɜ!HR;�����˵]7� ����4��K,�JJ��f�W�N���@�&e��#�\	Θf;��g���ȗ� �j���=u�m[�۵iD�jc�MJR#cЗ��$��m�$*�M���!M�kU��9d2ϮurcN���2' �f��m���W�5
�If���?��[x��̐9�p��7��5���ڤ��_'��?�CЪ��5X�jgM��g����� ��t4Hm#�E���J
��j�:���X:� SnZSC�Y�d�ท�; �<i�/v�S��O�]������f��8�9��Ř3���6�O����XS;�R�S�L�Lժh��|80P����O�՛�����mh�x�Ib�;�=�WN:K�7 �]��p�M}�)�r�}�5�'��"��� ���@X/}��$/	����zI� P`c-��l��.8m2����Wȭ�kFk�G�y֏/~b�S�]�VG��#��d��b�bƤ����ƺgP���Y$@^2�I�nu�&�4��ّ�����1�V,vv�@^�D�fӧu��ٝ��f[H�]����hqj���.�_�1?.�X�o�fG`�Z*�05�y�Om� ��> ���dA��Q��蒚E߷)�-�b�̉ ��E����|�-�9��z��*Q��h��ؖ©�E���Dt������n��5?f7�%X��C�Z��C}
_��k�.�i�ZZ��M�s��h�J٧5�D)�g��"LL���)�+Ñ��(���O�@SU�e�����I��R������[ǒݳ�t\k��h�4�rr���%���C-��יӴk@��JY�����rMY��LXݞ	@�D���3��ch�����:HHQ��f%�.F�L͍�х���T-�.Z[��탅D���%Y#�n��^ nj ��)>�rq�w�O��y��mcߕ3�y�4�Z�҉TN����ߒ�'n�u� A� ��T�K�z���~�M�|T}���J�s�j��_5&���̀ ����uk�갿GQ|x�b����GC�mT����K���/f���ΗE0m��Ɨ���&���Vt�4��âĜT�7π�m@mYd�M�Q��f�|�"j� P>n����~��7A��moQ�2Ҧ~��+m*m����H¯�6�&�@O��e~��o+�3;:I����^qq/7�XBC6�=�����#���~�]�5����_8�1�aR��I�EFbkh�5L�2�~�χG�R�p#t����I�~ 9���Hy~u���@�� ����g�?�s����s	zbS�B�^n"�)�:��M�r�F�d�k��8�wG�Yd�O7����8h�i���e�I�`�{�H�OH�;a���x�pZU����B�5�����j=4����if��:d�7���@$�� �+K�cWA�(J���fz$-A1��j¢�u��EOC���K�����T��8.e�h3�:�v�r�P���-��	^=�1��҇):���T����I�Ņ�\&K��D1.����f8@������D�m��$z8�E�=�����>�ٜ�Є��ܖP�ᮃu軭�aV�{�C+�g��V)3ON՟m`�ο�u�ı�vۊr���H�3��b�D=DUO)'78"V�i$��������eY�`�E��Y���������k�{ƫ��s�����AA�_c��L��aT��5��a����O������X��#�*�/U\mD�m �KǗX�y;>E~XXV��%�H��{��5<D���K�q��0�}����B8��GrM��8o�QN=�'DR�<$�h֢����M-���rP�2�+��9���6$����'���x�oӢ��1����� y ( 
��8ն��(\�*�/r츨�v��_�mg�nLpd*ᰰ=�1���Z)Gq��5&���6���Wp(G�ˑ��3��2�r<�N,�NQ�?�Ͻ�&K�0��{�9�����.𵸸�lΣV];	BI��h�((EoqE��h�M�(��l�E��m��aC�fo����=��Ϫ
Ȼ�-��T��!�YwC�����p�Z�bFP̏{M_��3�(���;�"�~a����L�=�tR���ċ�Mj�꼦dX�H�L��%�,�YT�8�?c՗.�ms����k:�~�;lQ�P�a�s�k�ٔ����ǌf���uG�.��9�����+C9��u�t�O��C�J5���g��>�l���+)�ū�\
��K�,TP�rx�gp�GL��ꃎ�2�bn�FͰE
��!��5��#X������]�τpv~+��uA.�]���(D�L(�J�}�cK����\�7�ƒ��n�q~�Xb"%ǔ�)1��喆8|�V�axj�"#>8���������ʒc����ޯ$����ޣ	�����|� B�U ���Lw"R$��8�~�{�;7�L����XKb�eJ�8*h*ӂ�<]���),EG,Vg���9�я=�'�Qby��hx@E�^��n��eJ���u�߅���Y���ڔ�Oa��ׇ	X���I��L� A)�L�O�^��Tq�ŉ���G)׍U�d%�?bGʄ�>e�FK�I� ��W�G�@~�@T���[�0�.(���ݗ�_�sw�-�%Κ�fL�t�SF���o��D���J�&)��k�ьs��WP�l��!�2FR�`A��v\��� M�h���l�U���T�ɗVȟ=c�%�:�
��x��o.��@���?�*��/�$+���� ��وNV5Y�(�ǹ���!!_P*�~^=��=��~���Y�֠��s�,PG�r���*���ã�S,髌�8�8�VW0j���I籑]����k�(�a�R����a>�6#�����ٙ~Yґ	��S�2'������Wg�LR���":�KFĂvAYY8r��m&�t�`��ֱ�g�]�'[� �3z���������L����0��ؠ�
T�������w@r���<����7��M�>&x`��9�-2�����Y��xf�-������;��h4vz��\�d�=��(�ϻr`7YOn�;#N|O����\z�&N
�Gj���%�����՛̶��a6�4��I�c�� wI���g�Ve[�5���e��ʘjZj�F'��B����ܼ�߭�c����Ok�8��(K瑳-aD�8�i[�ڢ,��Т�ԝ�!�Zo+-���.0篥�4����i]e�����U�׿���X�A�6�Uhó#5"����S?M��\�>�=n=Q����ߒJWVL���
��8'����b�4t��/WZ���"���@�_��Br�/{�ZN����Ǖj*/��˻[��C�Tx�[���Bl���Y+	�>B{�_U�>�Qw/�`��"S�r� Y��|�'�]��j���{���m��Y�S�ьMl|˞���Gt0{.�œ��o�H����#�mz�k��I��R�m�ZM.'� P�%dJ�t�VqH�$�d�s]j�=�!�vN���/��<E}��d,�����e~%9��-�I-=�u�u�ǰ��Tw�SE�?���m���ts:���� �O�8/6N�ꧠ(�O !bQ��y&y��!b���iۡ�k#j������_�f�mFg�C��J[��y�lzY�d9�s�ߤ?	�� {���h �s"ǒ�m̓��V0X�~'Z���j�\}%����'��[<c:c�`4�E����J^���b���qG�򢗭,fXw�B�4%���Z��WLL�Q���0�{V(u�'ҍ��X!	�^�$b5������EW�ը�U2��h��w��+��J�An�������`��+�#�,�Z�⼬9y��Nha�4�a�L��Ӑw�X���q�+�oJW��B!b�)R}� �����[qװ#B��PH!�q_����?���t��;�������.LI A e�BR�T��q�;&���
��
B�i�G0��Y7��[έW�"���c6s� 9J��T6h:j�uG�_��26�0��ʻ9��f\6�� |]�f��M n8%v37q���ꞕ� �T�H.�Ǌ(YV�D��:�V~�!���Mt��_��@kܥePF�*0=▊Yy :��I�Ѝ�)��[�#��Y���ُ�P���5$���z8/�+%�{�Ǽ�~��<�;��\�↑@D	�骁�v�v��`�] i/����&����dL.�v�0��΋��*�_6�����%"��|�==V�n�k��K��#ŠL�k�B|o��Hf��f{k ��8����P�W��C�t��#�}����hC�I[3�.����sy�����fD�y'��?�3��M5<T�؉+>�-p��f�,zr�s��O��	D�d���ZG�,�ډ��)��b4"�7�����Ө��J�JޜҎ�u�zG��ȮZ�~k�D�0�S?�[>�����8�ԯ�X?���ő�?
��hٗ��(�����f<׮n00uRk�}����xP7\�g�@�Рd�4�i���s�
��A������Mʺ����WV������]v��?w�V����F�%��C��m��խ� t���0�$Q�Q���r�a{	�~]��ͥ��2�A�p��_�LG�"\5n���A�"k��כ{>�/*M֝�rΊy<qF��-���m*���@��W*�Z�\��D��̈́�������c"�d�%0��������.��a�r�_ҝ�fA\hZ��|å�p8?���C�I��U��]�k����f�i�U�����	VX�Ŗ�^�K���胵�d�|R��Z���4';ԭ�MC.�����3c�*�#������rrm�%F��"���"��rն����P�e�/�x�#MI�E���Oo݉J�[�Ʃ@����lr\�k�τSbƍ�a�:�G�n����H,J8Vq|�� �$f�k$y���H���ME��2�V�\���i�_A� m�(S2����a��ƴ##wƕ�)���RM�|b
א�������Y�1����Ta��0���/Q� �:�æ>�hS�û��n��?7�Dm�����|����H�F���^=21)��V?�{�u��0��r/���F{=�"����Η �<��u����k��c���z�AӾ�}��ª/�\�^�Ob���M��͹r�^�W��e�s6����r;�g����t��9=���:�O�&�n`�al�~��#�g6E81�(vBd�x*�1)Ϋ���
����?�d[��V����d������ooI%*Ȓܤj`#д� �3��K5p����=����p3��yج~�*�Gpϡq0������0��[h��1oYeW�|@�>��߳��0����"�|���uR�H:��i�f��������w���%*�S]�@�՚���Qcو��ǚ����04!�d��O��SE~�&nR
�g�{�|;B�����ף��B�,Ô)T	C�}��#�&���S�u�ۣ��K��~����WܑɎij��9�r� R�Y����K�%h�Q�".���F��Lw���7HcvC*Rfx��E�c�L��}y�у�{��DܕD:��gv���3���J�5n%`-��W��}�ڹITU�(�.��e!`����n��a )i"���`�;j��v�Tjp���h1P������Y2��gLd��������;*=�Q��1T�1�H��]�#�p'���q$�����0��n7����Z�J鮼�k3�#�����9vB�8��f��Ewo����x���<�`���G�5�u��V�DY�Z<J2���(w��M�m���]�d�s! �ЋdF�](CC@2On;��'L]�/Lp&��waI�W{y�S9�p�ڧ}�\Pe���q^��T+A8�� 1X��C��i��>�{��DF!�A3u��t�V^D����m��J��_��P��f�v^��#��$�
KNFvO�U��l��rų��['�Ю6?�V��#@�]8����:�|�,݌(�3�oA���΃��I �/��kt؀o��s����4��q���	�o�1�� �7G��7�W.�w�* ��{��+/􍩮b��1u�8$��+^[O=�M͊)x����]��jov�S����nV[�XZ�����Rz�߶��h� ��3r�d��>�������TI����J�"A����A��xL�)f$��a����C�et�O��i��*�+���Zf��b�o��(�/��X+�[�� �FHmM" <5�/�'���-4�N(}��k�D`@W\ �dE<j�)�˙&²/wB�W �ү�[�O1S�U��-Y|?���0��Q�+ҙ���$��\�YL]bbh�B�*'>V�ۼ�c6�?������u.P��t�)�m�����߅yF��a����!�%@f}�C/DN��x��L~6�]ϱ��
�
ԺM��R����a� ���r��vW�Y ���&fRh���2��s�=7����;>z	�>���D��BS�����.V�9�v��yO�MpOR��&#���,	R�4,��9ܦ��[\�\�m�9�������prX�v��B"�m���!l�+*]r�W�}�#{O�o��ԲK�f�4=�0��$�k*�-~N���Y9���}QM?�F�-�74��o�!i�"�^�XcP��{&µrY0)��/Q_��
Hn~���s^���ͫ�����6J�^�*�;���^��~�:��Ή�z{G����V
lC�~�Ԍ[m�3�k1V�e��ŊSico����EΥ��N�1�`�Ti�˯�V�n��'FZ����)�E�G�io���� ����8'�l��:�#c4�����35�03_O�/���U��ϳJ�ycSd-��	���2�0K�@#>��海�`��3�/{$Y�ƚ!�J<���U��c����	��>��5���I���Ozo 7�ԓ0�����%Q1�6�;oJP�i,����8N�U�ԡ�t����������A�5Y׮?K�g��O�$�������R"�O]z���X��'y1e3�W�*�&�bÁ#����q��o�G���(w^:0��v|��HY��6&������d���֡U|"u���4�6O`�z�Œ4p���'��gX��7�l�,�mb_�Z���e\�#�AC��M��}����;�php;4�,e9�j���M�'�gO�v�����Sz�=�H	�5��'�\sh�	��Ɍ��,��sW���|�P��
�)�,{�D�dЫ�[���Kd�H��D�l܆3�
� L�Z��̓�a�%�6q�r|�`*���7��Rxd����?qѬ����5�Q�/ִ{䬰��q���Wg��Yo�M�\(}?�p���@׫��WB�y�����xA����nG��=��W���;å*Z�������=�b8�gn(�4��!*	�� _\�oqW�Zl��~��K�}2��IM=��#"-��'ye�Kv�
}-�5����-f�_ƀ�@��?�x@�^�TҞ�J;�݃%���f>��|F�QB�a�T�p�E9��5'@�i�
����la���!#� ����˖��+�(ݠ��w0�3���K�\e��U_Y:؊JͿlx�C�C��j1�	�K��m� ]�'��]q+R<iTs	SU[�h}�r {�� ��u��b�tُ���Y�|dJA7zĭ�Z
mo9�R?��H����=m+U���v�D�)#v1%�'{��sX��'��ǎEp���_��,��8���jB����!�<�i	�\W΍	B�^��Y	�]���TZQ[r���qđ�J�۷Xj@[,'+>�{��������fcɗ�F�Fw���}��6�b�6��b��j��tV}�S�D% Pm"E�?H�΃��ZG|�>���PGLʌ(@��v���=��U�}rU3�{�mo�������t���`��`~��,e7C�
����d�S'�<�:� @'}E~��ک��\�TK��q�hW��i�:R2��A�5@�f+?�����"� L�������P�s\z�e������h'��-�V(M�����^�?��k̟�2r�[�C��Z;�����脕f��طkTEq\��j�ؙP����8 ��c����ZK=��	A�r�2o�zG�#��!lx3�2�������ǐn�i�w=���=��,*� 5�;��Z%��k5����j��wk�>}�VϾvlK��r��k*RI��
���[��5��{)�2�C=�1Fk{C3{;f�c9���Eƀ�_=�[
�L�rd&�w > k�p��a����=��)H�UC*?ėN�t���6tޞ�B�9��{r�2��'�{��Qn��g����$�_�ȟ�� R��e4�~l�?a���9��8��Bh�GG�ꅿ�7�ag0���HĻo��e�#!W�ZWH�4����G`�Nߎuׯb�� ��^��dύaɘ~�aς���IA��?����}k�z�GG������^���k{��l��?'���c�����\q����æd��9f7(7bj*i�ˑj-+������֞ �Bu����{n5���T��>���h��������j��|шl�цD�j$�wS�ZOa��Ku/U�o�'�"c,�:V<E��Z�����|����ׅfMPz0�����Ȕ՟iE�F����u�#����%���kz������w�����!�~=E��̷��)���%�rKP�\%9{!�h	.Qʞ5K_+�Wo�fq9q�3�YŊJ�����z�~#���x�b���؞�r������/��qA��a���k���Ε8�\���o��k0 |�au�2�)ɷDI�(���=+��)�Q�ր$�*�^��wc#��>%����6�bc��n����Ď����k�܍"��?�O����.�m~���}\�!��)ċghT��}.b��_#F�0����1F�;$g�L��))1
l�=	e*]�E����[.����l��7\��u�F��"���i �E�P˿D���Z�t�����6�Z����:���ES����w� 8�%�?sJI��9��O$�:��h�Oɠ��ڇzsNF;+i�&�z[��L���CJ�{����} �V���/�W�YW8jHU믷m ���|�f}��ߵٝ�JQ��dy�E���-�R�/��08��C`P�9.�ƻZ&�<iR��!�xL9�@\��=35�Ou(�e�����|G�C�%�d��Z<�$2�кΐ>�m������4h� ���}2$d�3�_�ޅL(K/��;{�puno���|����})�n;g(hl?>�[qͮ�������A��0O�ͷ�S�\�X��&�nm�f3���daH�(c��`
�>�'0��?}�l��C�9����$��0WO!����S:�wњ�j�/a\ss�ž����*�;"�i�-�Aݼ+�oF(d�z�SN��������y:Ш-�Z��+����h��M�k��g��fiRJ��7�����q��J���(���lg��(�{�E��\�"��h��*1�^�\wLkv��\
�[u�b�h������ q=+�*��P��`�m�@3������1�� �>�����aP��'�B�Y�yиn�!�«��j��
��r��L�aA���l־t3���]�������Ć�����������A��S$kZ���	��27���6(ca_e��cF�l�M�o �]E�b�G���*CwG���aF:34֧LJ
�H�и��)��H���㛉�^��5|�%4|�C+d�k���iV˹{�4!rG�<��mUrs����|�la�s��7��P�?oV9��a	�;K�"0�w��?�� �X��g KZ.�J�#�`��Ì@!I`��S3�h���*+���tc�6S��H�`���P�J{o�Vf��J=��-�'h��Z<ّ��Ĵ���	��)Md��c��cI���}{끲�ᘺ��2)=TQԌ���M�Q�(����h@BY@g/���i�by�	�e�`x��׷=�Ә݆w�R{�)yC6���hOɀ(4���j�_��P�#\�§:wdpQ�w�n;x��X�`����z5��@\yZ`%���T�
���>?J9Y���>I��
�u�������dl.e�W�y�M���y��B;L?��y�!���Ka9K4y�W��{;b��Nd���vu�{���M+�Ӊ �8��nX���bn�1�u�S�۬1ez�M6�e�$Wu��L(tK"�\��9��Q��Xj4ן����L�GIT�&�E)�_��e<�uج+�J
�0*��D�\�L9>���`f��~����`�U�i�R��	�͡8�q�$�?kSPW�(��Y���83�~���t9��h̺�&��2���ſ=d{U�YW�XsNuJ��8іV�AZð,n��y�}Q*f�"�uy�P'D����,��%*8518P^̚�>(��<�7�ļB��L#o�$�#!S�R�n������8��"��y�nqA-&��)����O?�����ܟ���RŃ�6An�$d��˪��0t��Z�Ӗxe�9�@�6� ͋qNCm�c ��
i�.�깉�A~IF�/�G�UE@��n�l�=v}��.�z�6���͘BC��f<�8�:'��gpMY۫U9m!�7�-���ƴ����t0�<�'�Fv{�:i���)� ;g��y�`:���(na�ú��
:<賙Џ�r�s%�&E�F+�%��K�G�?�����K�A�6B��6O�+�����OF�L���vm�*9[[K�t�Q����f��˥Bo�˷���F(&���帅��Q��q%O����؞�㋻�Et��z�	't'��@?�'���q�� _�3:����1:-`Sm���w��9-�����8��߻�>�i&">f��������$��Q_�g�_����Y��7�O�Rs�0�ͼ���`�3kQ�@���bӯg�a�h�"i�D����V�Flm]��v��盐���#�O&��j6HVn$.@�AJ�̅��}	u	��@�=��ס ��^U[�J4��nI�M�7 \�-b�U���;�nz#�6�V�`|CI���h�7�x�#w����1��y��z�d_$���u_
����[�!�f����d��Z�%�[�%�Ą[��!�=�B��ftgN8Ŵ�ae���ʒ^�Y��_��[q��b�h��7��:�
��_�3��|��@��[�ZUq������1�vɁ�at�5F��RH�! �b[)�cCt#s.�s_�1D�w��r�ہY.�8�¥>9+��~)H	��*�ō����0L��c���P�uzhW}H��yd����`(`0b���%Rb�O-�-gG�&v�Q������ �6u˫x4�F�������Ȩ�P�1����Lj�Q5�V�M:}}�(�G<>�st�u�w^��l��}��lx�}U|E��F�ճ�bFѐiJy�M�:f�I�0k y{����gQ�$3,{'_c� �0f�m�8]Ut�5j��7	�^%�PIiV*<���V$xo#͞�ܟ G֞>��R�E���f'�'�ns�0I�-⢟��A�n�X� ���c�y��~g��Y�,������>2���#��3�t-�M�X�@�h�*(�A��zoP���/3t�I��PP�sc�i������ �CuhQ�#�\dwj4�B�a??�Fm�G2�àv���F1�T����m0g`�r-I�ǈ�M@�Z~�{3�r�uoC1 W;��c�U�o��J�Z4_l�v	�Y6��տܛ|<:_�Ө�,���^M�n�c���A�׆4ߘ0��z��;f+G�P;f�n>�Bc;���,��D�����^R��x� Ⱥ���g�$�M�/*2p��[R�埼)�Mێ�~������0��in�g��*C͞�]D_9�د��`g�Tb��4���D��'7-�7y��Fgc�(݉wQ���I������9H�#�8��h�m��>oR�]NZ�R[��&�8��s�b�@�����ϵ�6�T
�[!������CD&��ܶ�jo#����IA�՛.zP�X����%_>�?	���)��9@F������A�M�\�2G,%Y�u6�l�߁΍��BI��Å�X����a�N�O�@$<rBJ�kS�n@�f�A����

~WΨI�GR�D�����7`�uU���>�&4�w<A�o�����6���`E���!�.g��3/A�3W�T/�W�6�
0G����DP�)�Lķ�81Gs�l�(wK�ʖR�7F�h�xvQ%�<��5�׹ͼ�`�_(���t,���ъ�⧽o��ǖSE��*���{t��zcs��O�(6�gd��v�P�P �d7�I���E���f���ۻeٷA�R�M��G$��/ ����?��j�m�n�A&����bc�|�C��QR�e�vՀN�K=����x�o-�}Ӗ�;f���b_���{�c]pk�%��GK�-�h�<s�k#��������dp��R���j�m�^<yV;~�|nB��m.K�u�-����q>����6��p`p�?�Eūb��^?hl��~ͽ�y����8�'6
4�i�+�V�T����[Ѽk[j�>�0�J�Ԯf.�?��^=�&�o�DV�)�LR��^���E��G��{�j���]�|�Nr�4���Ŝߊ��iϪ��3�.�*V8Am��5R�S$��.B(�3�0\�5���%PX�w#�

v���N%9ov��JѸ��8SH����Nєbf�tU��G�	6����$3ޏ9+�{�:1ΰt ��{����pe�h��#�qh���:QkN>}W���O�'U+Lm�ld���XpWTOq��)�7M$��*�yo�ឈ�6��Ead8�ۨ�U�Yѵh���^�+�_Ɵ��ſZ5���m�`�x1yh�МC��~oޜ��V����rEgѸZ�ᥰ��^=�c*/~���Eb�4���[iu����ƚ�u��5�D��:��< �����]�
�$V����Z�LՄ2ѫ�1�of��aF��r��Hy��bh*' �$�X�vٿ1]1F]}�O�uS����ibk�'\\��u���lŇG1ENڳ�o�E�/��5���T�����2�m���jQ	wV��"?@���P+�s��vv=�Y���@��&��e6��G�%��Y���RhUkJ��dg��JQ�59�>���N��}Nv��]�&&][D����$<�/P/t�ÈY;�	��
��ڞ6[���<�1Am`��3D��O9�c�Z��,� l<�^�;tX�UN~v˄E
��؉��wT$ ����9�����>��j@�2�9��束F�K��J��r��s����D��P��W���Q�n���,"�ߋ�5-r�/s6��g��u��<���鏷V�
k�ד,C:Z����j%��>�1����r�i�\��'1���t��=����t9�0���I����l6��ѝ�?tT��̯]��ɥ
U8��L���՜�;.s����̰��{,�y���W��[�n��m��s�	Źhkݏ�چ{�k�0-�9H� !��H�Nh�;sj���#^�LZO���2n���sSnPO��"`����K��E�O�ON���U��[�"Ԅ��D�\�<D���4�gfU���zX�#��);$̙�GG��Vx�񫤧�|�N U��K��*v0�NFx|w%�L`�?��O�����R n�Aʂ0=֬���sr��08�ƶ�m��/t#���#t�`)x��.褖����P�5i2���%B���Eb�kY� �+������L*"]�T�zxњv2I4�idD7���P�Uẞw.���R������IE��}|�"�M(eŀ���ߏt�������h�t��K�t1�L�7�EԎ���١��gP]4��x0*^�R�A��>�Ù��g���&�#�{�=�t�dl���'�`�#����VhC4�;$0�C��YϪf n
�b/��@N�K\��.�2f+�}�7(��e_U�@_DuܶLM��_��P0̆���4�-Ӓ���-n�5&�N�"�������Ņٿ��t��-�<�+�����h��)X�6*5�A�6�Ü�'T�$��IGyW1��l�]�lX��k�}͑�ݻr~�n0�/��p�'��Ʊ�eﵧ�o��x��0�/\�U��E�Ť �����3X�ý�%�\wg��K�ϗ��j���_�:����ipHSLE�S6����D�1��t-���MGK��������b���h����[�(��f�Y�a���}E�,�=�Hr���Cq�����NE�|�8f��ZD�I7�Pō����c�y]4�%��SY}8������<��2�������s�s�f�!�F`�,-B@�֨I <Vz������<K��6����Б�	*RN���ִw���<�:�^�y�u�[q؜@d�8�:��#e��v�����'���`���'�]6�=�zAȪ�2���|�mQ��O�C_�f�{á�W��5n��/�W�!l�x�F���;���� ߇�%ۡehx�����������<���Q"��"��Խ�����s�a��ᇵ*ϱ\z*]z<�?7���FШg�Tb�|7նf�Z-E� 3��)P�w6[ ܸ4v*�ϼ�%{��'"�!i���K"}�����Y��t-�_��['�p�~�;��.�U����]��w9&0�pUc00�u�_{Íl��NB�&	k4�
W0cm���L���=�J���{ğ$�D�bPr�GA5l=���W$a��zڏVÃtZ< �$�H²��yH�s���1<4��Q    N0�h,�& ޹��������g�    YZ