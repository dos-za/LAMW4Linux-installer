#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3450679936"
MD5="4c82dd7dac50491a63f8fb9ef0ef7116"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23568"
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
	echo Date of packaging: Fri Aug 20 04:00:30 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�aq�����Xާq?+�ڕ�<ӽkϼ���|#|0D���\��螗����$k��8�|1��ϕS����H�a&� ���bA��[^��!��\7��4��dJS���GFJ
#�^A�b�b7�`�3�)���Q+��0�Jr���VN5��ZR�7�ǶR�lY�I\/�5/�NzL��o}߾���G��x]	�P��6� a��y9�ﳨ���*uZ�]����f���0rd�\�8H�� ���eW�K6C�]�ݿp�L'�|}־���rOq�7)g����d�^�����1"�,�s�>觸�t�B�[���?gx�z�]v�E����@K�~C��:T1a�z��	3��������UW���n�=d�q�o�(	��_���e��yb��=1��G�Yy�@�N�p`�����9�IE�C$s�����+'ޞHWt1q���᳸n�	B�=���2cJ�UԶ���Sf�Æ8��˄~�c�2	,���v��\�T��ϫ�9M�y���S��3����0���TǪG�Y�n�}
�1d�9�sks��$�2`q?�9�D����9J��(?����^���s)p���~�p�4��u��T����.��%\1J��SAiapм$�8g��!���܌��n�q@�"ki��G\��1��E5si�	���U��<��u���k��H9����Ƽ�d��SiP�����@{�i; t�r}A|{�E'9�W�oF�-�?��K�褍޸^�k^������C-H�=Zs���p��p"��������R���\kr����l��a�"��%n;𛁡�.�D�\To�6�0���>�(ѻ7�ޜg��ݹ��������k9C^ԑ����+��}P���B�GP�W���s�Q��4�g���E ?�3�%P��M��^>YWo�x�+@���щttW<8+��,Ǭt���]��Y��Gv�'�����F�ƭ���}87�@���ܹ��)QdT��������azY$����)�%�v���`���	�y���j�l,�=���շ��O�jk�imܴ��s�}a{]�:�<�@�{���J�??��ǖ3K���J�*Yr�Tp��2@,�a>˞���#!l�̷����p�s�r�Zq]a!9Gc@InK�~5B�P3R��N�:֭z�Z_�V߽�J��R�#ޟZ��L�9qY����mykd5�9s<��y��A��#��j�*�����>�HOW8e����'+W���۰B&  ��s���2�*G{�}F��ZMId��6�=s�]  ��r`�����NLd�C�I��.�ҿ��c��	�i���c��?�"X�#H���	�7џoq!�س^}Ɓs}�#:ܨw0���ʼ|� �h0x��rr�)�p�]yh�"��gb0e0�U"<���$�&��{�!�i��U�UD �F�H�n)��;�M
��h�Bh=�AK�Ư�ia����V:�Nr�ѽ�.d�q�'��j�E.�����wv
UW)p�j��)�6���a�e�l���ɕd�My�^����i:���.�٦y1}��q޽���gSB>>Z3^��	�X�/<����Љ����,��R���K\�R�I:��U1�xg�Q�X�?��]���t���p��\�\/��M����Fg W�n#�Hޯk�st7�tR&�W
BxI`�'�1�t�P��6E������jI��i�9K�O���V⊞�W[m�>��c�ti�����9�F"3��$tb�T ڎo���hou�P�oso.�w|�D�ͼr\p�eêl帝�4�P�W�dGl�~������Yï�vJ&K헆x1�љ�5S?��e�kƏ���YՍ4b*#��fR,�i9;���Ѡ���8>Pc�*�Q�:�v',sĕ��t�������o�=c#&�Qf�6����j��ʆ�p��q�2K�	��7��E�<�}D�e+��ߋC�RCA��П0%��������lݞs�@��N�	pz���������h��0��9(��wK�l!�^q��*��<��7F�Co+qZ�浇;s�HK-R��Ityߵ榶
R�_*/�,@hA�}rSx�q��������D�E*�wMR8�Ԕ�Ճ��A� 0Ɗ�Q�Ϡ��=�Z�<���L���abf��3��X����7�n
��-g$�����{�$	=��� }�Q+��ga:B��,����Ky���m�v�_��;���(�I^�o-�30c�˛�G�rD�nw�SÆ6�1W,U����z��c�L�J�A�8��U��S�VQz��}�ۚJ0H���jw�F��
W�����M��"ho}Y�
�v�$�&���5� ��'��W�n��G����#߶י�s��/Tn�����&mFMu0�6e��~�r蛭̧�C+p�8�#ERΞ�*�{���5f��F����H'j�(oP�����F`���-��o/2�$���@r�w�J�ɂJ��g�����1��������hc��b������AN��?�}������xhU+Ҡ�ˍ����H�ߛO�h27ㆆ��P�oq�k��%4���k4Sv��N�?������[����O(ǻc��ow���r�P�֛3ƿ2Dgr�4y��y/#���7�|3���-���Ƴ�H�1V��"�0L�a˨ȻR�*S�N�iS��W�V��C[�1W� ���g�O������ћA�r�^(`eR,��\;� �ז-:�J�ʁ��U�F5K<Y�@��n6f���._F�5���/��+s��^�J��n����Ʃ�3�v�����Xj�5�s��DĨ}��7�O�	�>kd~��� ���ɹO�<�Y��x����r�1 �p�ۅ{KΤ��gR�GE.&���Ç��z�"]t����6�dLQ�����F�ph[�g��A���ri�8
�m��qY��>�05��(1���Š�����Y�:�r�A:��9Y�L��.��Fi��)��B��	��lz=)C����?�@@RDG���i��AKY�/��)���� �W�^�^�e�4�w�\�����HL\�Y԰�ChI�������eT�
�I���hwԈ��:Z�-C5@g#
G�x��XZ?�Ec�k�F�t�o,��!;�/�Τ�b�gm��ς9�G���xc:��P]�=�Ze	[��sBm*C�1�~��^h�u���7��ΈfL�Us,���i�K�����L��1!�7�����(��$n�q2�п�S��@	й$ d�\��\���ţ\�S}f�M`�$A5QY�!퉪=1��J4��0<��u�T:]���i67����M���0x*.a��� �Ԫ�(����1Ρ(�Oav0�+���������Z��+�ҽ��W���"K�vtf�m��dsİC�9�.��Q�9�fK��u�� ӊ�������q���mH� �q
"����@Sœ�<H�cqv�?y��u�~��;G��@g'�Z�e���S�2��;�Q�J��r�Adi�UFe�;3�!Kߓ����?�r�̀�to�MH	|�����9����^,�+׋W�88�8;t�cN�G]GMP�jrY�5���	j�x>n�p[�~"g�Q>�̎ �D�M���1]�ON�q�j֯�R�<�`�D��5��'O�VD��TDZ�}��̜fw�!���պ�h�l|��Łi�x���g,� �GS�SnA�K�Q0+��)z�1�,��'L�r��G2V����as��N;�ą��T�s���]��Ǖ�����z(��%;�ҏ���^!�1绠��{p3��6��
���^u�*$+炚x"���n�L/F���,ƾ�Ky	�t�'�?��b�h�_�V���Z����}�D�Ԑg��8y���i�&U����Y�̨ ���>+ĨX�@�3�fYn��|�l@|��i�����MN�13J?� ��g׃��U�A+�����	�(ب)�)NH�o�{3�c��Y��R�E���cU��XG��߱ʓ�&l�{,_��*/����s LK  3��#	[��Z��U����'��)�ṓEA�-��fs@�L]���D��(C���	x��DS��e�͠�>�8ʖ�2��{����+��"V֮C�̓z;��S%E,��[Kֻ"�,�<,	?u����`�_�=Bc�)k�i?�Fӥ=s����@Ekrz���tʝ�xQD6�~�s�� �sk�g�3�R��hiD���yfc���.+��Ti��ێ~���CQ��w�ir!2��ts:�į�w)�橲%\Լ r�4�	i�$<�B �Ґ�:����l�cU�X�
4�K�MI�?V�~+��� �wA4.�t�?P]���v�RC� ��ν��>\mv$05����)J�"��������
F����K(p�!��/6�T+�����n	u��d��]"`5�'ٚ�tbNѳ��C�u+����ZbU[�B���6�e�����sP�e�􄀤�{r���Y����#ƾdh��0�o��0T�h��ҿF`VS?/�r��{�L;|d�.Q�����h�//�m �q�3��)"h��O��>��dMk�e-��_ЯWnӑ�1��w.�"�0�5�Y�ãj1�;�ĬDoռw	j�X_���Ye��W����T}F����
l�M�d��4�����a=MS�')�w��:d�ov��i=�ŮO>;n���[h�L�����%����f�`t��|��s���Y%�$��=U{��i1x�P2�{�ڞ���{�E�ւ��I�BgN?��0�/�j~	��p/\��8	.�K{!�..Tn����#3jr~�ޣnM���A0�y��Vʹ�w�ax����o(�4��X��䜔�syy~�w�5����/0q��gKE�����GvS�;[����ͤVb_�v��O�C'5�A���e8_�� z�����Ɉv��[{��fa�ĭD:��S�a����4�K��\l9���v0�?��l}�=9�J�d�C��5�)q�Y�P�`G���E��	��g�-�F˯�Vxۂ�I�yB�fF2ڜ��q�.
�ZG�W��a��w�A���q��M�I��)/�/Ni[O�YI`Ar�W61�$�{�p�B4dU`��o0���|���S��K�ש�J_V��q�5v-������-�v+9g�$�)��Ak����J�]s[I��zE�Te�J�6��&I�h$=;�?�b�O#W��'���ZWD��Zϲ��(9Eؑ'�a�"G�NgZs��x%`���]	VD��M�5,#��	Udc�����
� ����#/�!G����`alR=qE� h �AN��7՛J�=vXv���P��)���Ѥ�4̞wu�8�k��xm�t'�?҅ ��?�Y+I�h�\4�߀�[k#�YM��E��
�6ε���ۀ��8GM"v�n�A����O0�����6lb�䤮��+dw�Xh����@�?>���6>^E�z���5m�ئT$�н(" M�<_��=�-��H�_��{�5/����|Ц4�^Fmb>>�ڢ�sI���������2a;��$�4h��r9i�.X�ɬB���+��k�i���a+����f?�����kN��"�Г,��Ȗ:��d���oWP .��ȗ�� �B64�:���P�G���U.7�T�5pw��h�����c�npQ�j0Gp�����7(Z����WuS�S�I*"�����kpT(��Tj�ے�b�0ƄS��T�bJ>3��o�Z��8�[(s��
e�fX��I$�bd�S����4-w�O�UW}lsb��pE A������w펜��p��ֶ;o�3�ҥ}���oG�e[o�{�T'+��5P���ld��l9v��8`BYߑ0����Ĺ��o�����"Ϯ.ֵ�3l�c8�#�KČN�2s�!Q���+7Ƶj�[�y�f��M������sKw������=v�vR��eMvX����;�Q7�hv�����1�ֈ�/4�(�>�e~G[��7+!(ڢ��F�3B�|��T��{�����@r=��&yD��p񤲌Gy�>N[�2�8�����v|�~Z�n^Y�'_^�N�p��3d�vaq���r7`�N�
:�-p_�|�T���8�ΆZe�WY>}W�����]�(R��3��1��#��G�K���0�6�nZ�ߴ��*��!��J��ћr�/������������(D��eD%�aǃ����\�3u���ⓕH'jMy�	�2���+e=6&���<��-Ub�9��0�	�/KydM7
7��b���R #y�#�|BK򳠪���Y�2A5V~d����#9�n�8Qv��#c�9��v� ���ҥ���o��D��NB� ���4���Y;{��#�l��Cങ}�^� ���.�隸�H�����ыbR{��5$팔��T��*p����H�^��E�j��L�&�mF~��]It������q���p��7Ki�%S�H��K��m�_B(�������?�e����F�9�r�P2K-&�@��a�F�ɪ&m��m�YB!�ɢ.���H"�t�E�E�k�"l�2�g���P(�����j�-}p1�,�b3�4�ܶ:M�R�35MEWtp@��F���q�^�z(}�p(�T�e�����I��L	0��H�Ә�)��v#�,6N���������> �6Z�G4l-1I�I8r�
3g&H�hƂƅ,Wt�h���F�t��f�Q�k�v梤��!#^�.dn�/?����ǉiM5Z��S[���{��v5<L{E���`�`���ن��+����'�;�q��6�a8��6�I�4�ӹ�f�&�e�G���U�������o~0�]u_zb� � ��C�jo�TP2�Z��J��O�:���X��o��$���r���÷J�X���=�[�Q�.\*K�S���K^_N�CK�M��~o�H)�_׊ur�U�_��c��C�|0��4���er4���'*��-����J�\���r6-����`�t�:����u��b�G�&`OkD�5�PI�����"Y�?ݱ^�;c/�����`���ID��N*�I�oF���|J�4�AT�,��)�2��z��h`�<\��`V�q΀	N�?6]��%Ŧ`30q6�����Ϊ[Ԫ`L|g^�a	8r�&�@��=vq[����S�o����B�$9�{�&O�ާr��{�-�Z� ��O����F"^H_,�o��XU'6��_U�-�4K���(z��K�93C4>���<���	:Q]�ѩ^���w�1�{x]XkQ2@��
�tm`����"�-~H]��#lD��*����>UUo�&�	���0pT�+��PJn��2l�X[�Zڜ�ߌL>�|�.�e�
����Ln��hs��2X|.g E�Hg����I�h��4=����*`��`��	i����ai�`�2����e%�)�n�����%�1+H�o���d���pܥ�$x��(Ou8qpt�k..-�.�S! o� ?�B������@����_�3%�� �0�_�	����O�ձ�n�昊M���~o�z��aZ�~�L����o�s,/ά�Y����Fܸ�jɟ&$��i�]�^e�-=����|�ί�(u�Pm7~l}=�!u��^|{�b�P	\�FMg���_U���Jw҆1< ��M3ʭ	���!Pο綩�Ux������S�K�uÙҪ
�nyb� �3������!�}g�k�ђ�8�qU	=5Р׶gh�<��<ٿ* %�5���-��%�����w����c!����� S;b�61�@�r�}�!�2^5�3�<OXRR�Xz����DIu���{л� 5pbtɧ�Bk�U����ƀ�De���$K%�O�żHݠ4N۱�m�X?����[�=��vJ'��V�k/�� Wýe��Y04��je��H�|�W:�S�T����(#6C�W�as ��ch�r��z������Q!8�ʂ*���4��dݚq!:iI��U��T���/B�m@��7b���7W��gV+�_��KIx�14�D�Q�Z��\�!U��E�⎮v���8T�`������좁"o�J�~���l�����5�a#ge��+A�L�Y#1�l{��f:�M��נ"������d�7���m=@J娤C8����3�V"";���V�G�(ANZ;�9��,���~���Q_��0��$����[bkL���ft��x��1?�t#�O1����ŤN'�_�ݏ���3ơtY��!���܀�-v�Ω�Mω� �,��^�XE���D�*�G�P��i�p0؛Wk|�N�W�mu�D- 
oH�Ҟ�I[���@�$4�����n�7�D�e/_���� �{z�&A��;3y:��&�MV��y�|[<AT�,bT,�H�))�l��UF����$�,u0].q�3�i�exm��Iw[4��Q5�ώ<?S�άoy��Ƙ��:1Z�l�X��r�k*g�������,}!Џq�m=����Pck�Kc�̶���XY��3�5me���V3C]K��X�p�3ni�9�Vc�'3��⍠�y��d���ϐ1�nz�Z�� S�X@��)	�2��3K��r�� �1 -�:_��p���eT��.(9 ������Cw��,~��8�V1��VR���d��Ϯ����y9�y�mk�}�*�����f�rVS���_#򟧬�����)���$��l �M�ل:���}uˈ})Д�˝G�F-� ���#�q��f��b�E�p���V4hܢ��>!�E���xd��6u��6�W|���	�����0�"ǻ��9������{��u"�Qa�s�*����~v�:��ల���=ʦ���[D6���c�P+��� Yb������Ӫs�3��e�9���\ �P�̹���8��DX�ҡTU�Q���j?2c�7�,����7zOʒ�v�<L�=	bg@	`�{zq��8P���B��/gln`�������m@m	re]؛s�Ca�<?�zcN�P��Z�Vy}�����Ӝ�m��sgať��+��-�yF�?�
Oh<%I����n#r��� ޚ�\g��~)h�9����8�f��`�ϙ�09T_\ް�^����2N�Jm��r���鐖�q_��3�t�Ŗ������]�/O���$�X�.���r#�NX2�*�>�KF��1*�{�2����l-:e������=�5�G�ķJ����`j��(������4'H�2Oz��̟C��O�Q��U�i���ϵ`�^�y?��ݵd��F�1U��+S
CkX
�x��5k�\OyW)���cp�ک(|�������7 ��N�@�)��ori����^r1��}����]KL΃lCm£Q����������Z,!����
���,������G��ӆC�//����:l&겝l�щkg��
� C��0�ʡ�e����=W����c�L�a��.�H�C��T����7U�-ةChqWP?Vb��8���{W �CO��)�6[�{�7��te���}���������L5����J��]��~�@����]��J>�⟑\2�.�d<v�P�U�<�_s���(�3in����i2���Oc�����{F������^֣L�?�4�*~2mFj���<:Df�?Bx���Ȇ*��'0<�>�\~=�T,���P\:I~%�I"/�4�\�����܎��ʦ�=�>�^��������x0dJ�\�q3s�|�d�X?��_��������=�����%>פ1o�rlB��TFbj�Ƚ�6ή=�	h�:��X��>��aB�P��Me�/��C�Y�[���v�V	���lM������� x�f[{�݁��	h�Ǐ*�{��2�쇤~"���_4&.��en�4�U��y�V�h���7��U#�3j� mg��4Rɹ!������kM]�x���A0̂��Usk r�0w���+˜ ����%��)\x�O�������D���n9���@���R| ?�H����n��Z�۱�&��┚����9�`z�\��=}'AG�m�q�NOV����P��!�Ɍ��*�k�'�[�{3�<�s��`1��xχh|Â�&ĳ�q���T��ZH��?ޛ5�Ș�	}>��ޖ6U^���L~��ov7eA����@A�M����Ĝ�8K%TU��bl���c�_�M�<?��ڱ;������?��VxS����z��}#]����/H�v��fK
Q�w��%�T�}�ö{:�I
�������W��e����8a����;��x&�E�f�H��o����3�.^�ݑF_�
y"�5�D1N(F\.���%��E�� #��"�0j�=@+I��bƣ')��t,����װT�OV���4�|��m��CU��l�=���K��c҂�_�͡�N�GIL���|8'5H7Bψwm*�G�ˉ̷X7�mZq���E(�U�2��*�Psy]��&n8y�Z��/8J>�DBB}8h���
�&j&Cf��8ž�=m#T�慝 ��A*+`���֣�1�t�"�I���)�)��At̙$�«f�hW���/B��X�f�ÁN�e�Q_8�Y�	� FӀ��eX�3>?���d��?�u�.�3��S�#\r�&�X��}��/CJYW]�O�x�  :R��3ǃ�7�R��i��D��osEHUc&�雃�h��G�Mr�9q���`3,1.I)jH;(���I�O�҆6`��j�?�hLR��p����TIP+���6"�>�gaqK3���`��;j�m�Ue�{5���[�L�#��ꦃQ��t�t�D�̽�|����[�"�E����ъ���J��Pˁm����לܯ�b�����V�`�ôT�>oN<U$j~�w��}���yY\����.�"�j�u:#8o����&��a3!�?��<�(ے[9m�c�r�������P�C�d�?~��Z��G���D��/T[����őA#�=�����Vˁ�-u[�(��(�����]�p�_��b��U]�F��l/K����/�c�φ,:�*Sg+2C�&\B�R��R	�K�l�t���cލ��$(�un��L��N�( e���[��Y4���b����#��~ �e�0��7ф�KMO %/�V���(QOƈQԞ�<J,���{gc���H�^�{�E���0�Ɂ>p�NiU�9�໦/)Ӈ�J�u�V��M˃�i51�CpD�����^t��p���$��T�&!��;e�+��rOx�
v�~/l��K(�sĭ�8��X;��E|��3�i�<O����%�lP��@{m�zB��Ω�+���ƣ�gJf���^!�"�p]�����@D�M욯�J�ӝ{'{q%���9D~D75Ba����TOݓ@~�K��i;<(ao2�D�CN��ޥ�v�XR3�1v��\}K.|��ܲǺ�0d�)t$x�~&}�S��:�����8Ŗ��K"�9!ch��� s���=�s�:�[:$&���WC�"�����)<C!Z���t�^p���BD�_}�
:�e��$����uZ�d�,��yW�`�RG���Z��Zi}�=مq]�&���~}��VN�-����$�� �}���%i�p�Y��_����w�Mz�mE�x� ���Ur~~���U�Y��]_`�2�p�$�ӹ���X�,������4�}p_��g�Ϟ���/���=����Y� ��!���iߦ�
4q��NaH*��z)�Ú�_q,` �N)�'�d�D�� <�Y�R�m�I$�(��̲?���נ�
Gk �+��zW��oV(bO�>��$���u�B����	�5)4�I_�cHsJ�Mw�ۍR��� ����c�Lt�*�����p�� &b�Q��d���-D7k��_E'yfA���r�eK��]����@d���!�Ǻ.��Ц���6V:a�d���f��[i��w�gb�ia�Ttb�FS�R�a��59׈Ƽ\iy�ZB���`���LАb�m��G]����@�1�F�t���F�t�'�ŀ��t}�OW[d:_�����.�5�w]���	?����n�q��qd���m�-�M���ô��PU�XEGʺ�n�9:�#L2U�"����%�9�m�m�';�c��Z�)�B����|�)J���kF �)��ޘDnkc��1����~��5m	?i�+��j��� a����>T�1���J���{��-ܻR���~�UL��V58/�)x^�>�`Änֆ��r�SoB����Pt�7��]��R�B�7`N�Fr�_�K�^��׮�6ꜘ��3t\6�ĺv�󯩲��ݜk�)�����Ht�đ��l&�T�I��/��\��Q ��r��5�(���aYƤN<�Vf4d��4�2�
_�(����:d��Lg>����h�2����ߙ��M5���<���S���N �9�)L�s[=���:���~՛"@tNo�_\�| j�G�o�X�}<���ÄZ��օHgHRF�E���3K[��Ԇ(���h���>kБ*��o�	��밉��yd;���!���r���ND�
ڔV`ƻ����� 惶25?�2�@��Zfe#u�=N�s�qNO-lڏ���s��ʌaB�G������K����?%�/ʆ@{g��<�z�O&�џ�[V���Ra�`���b���\I�깫c�	�������w�"g�����i����
ٯ�#x�	z��+ѨPf�Hᰖ���]h���:S�x!�3�� :"�
���-��Ó�|��g�S z @ڔn��<�>z�jץ�U�ycIҸ h���9�5ػ��W��R:'[>a��&����C|�V�p��ֳ��çV��U��~C�q���u��c#(��!J���̖�U�N�<����Wu�#��"�.G��^-
 �Ч����I���O����p�},M�L=o�=@����_D{�7��F;�L��6��@� ��^��SI���+�5ng��^���@4�#w6��ջЈ�D��?�s�'���c_�dE�h����)|��'���d���-#eP�Dy�t^q���Ph��p��(������ġNT��CۨNu���+�pNk���p��S��ӝ|��=�K�S���UD}�4p��Sw/���l&�
n� |AC���	�O���ve �%z����*Yc3"�`�.��*�x�&X�K�� 1@�	����L�����e�$!
$��`���	���^�Ȁ�؉�����AK���2�XA�AD�)�(��Ǫ�P�M�_6���W���/�"+W6P�ͣ2�#�|E���g���c�_$�U#~gT����Y~�1��B�u7��RI&d�t*xp��R�|��s4M��u��\���]�UpFp�o3���o��9�M�/1?���Π����F���P��i���.�-��}w\#\d�Lɀؼ���q�����O?6���'<xXJ�ณ~0"��o)4���_\س'6�@9V�[��v�8�n.S�92��f�dbx���i��* H�{��O�w��Y�	�9��5_�}2N�7��Tq��� �ɝ��j�]��a`r��2y!I�U�M�oE% ��[hO��)�ܱ��h;*������U�K�spOT�;�j��ncӊE[�qc�0�p��\KiU���p�W	۷�T=��B �g��4V���3ˈ��oq��wKf�@���bCF�T�aĝXeNx}Sh"�����}�D�2�IA�x.�}'�h��q9|�l_<⦔;Q�8����.�'�f�����_�A?�?B[�s�(�b���d��M[k�0T�u�n�-���Zӭ�_��F�r�SZY��#�+�竉~�
�Y��w��b!hFe�P�$���.�M0j �.��}�5����8�j�(����.�{T��,sA�͍lc�@� �.�7��m:wF
�v��K�8A�ݬnM�y`��oU^�b��u�Q*w]n8�v�]/dԲ#N�,�	$Թ�h����*'�R� ,-��x���7�� PMG"di�>�*��2��o2&�;���V�I�*�f7|�)� ǌ�^EKDG��u��	h�1��CѦ�����|�5M���Gx�;���Q���ϸQ�+�jB8}�w�cxw���(�?�u>���(�W��t���W� �t~�>"Hs�H
��G��+j7aA���!]) ;W�S��-4�l,�f\N�1�R϶�[���i�( a���-�0V�WZ��9'4.�
�"?d�!�5qu�ɞ�d�!]u���p��-��h��vfc�N�Q�	�ZꜲ>A���貞�$�d���aH±)��S&��8�������-S�}�=B�� �4���H �䚷h�b���@h(U����=��g_��<�铰b?W�%���d�dlʴ�=���2cd��d⊄�X�Ċ�̾Ƭ�3��X��L��u�j�g21t�>ItvԫD26)�^`D�\��Ĝߕ�Z��=�ō Uڿ�gF8�cι�pcrI���Ԇ7������m���O��c�<���3 ���B�2�-�n?�+�o]��הFs�D�A���g�JJ�0�֯ x����B�Υ'�p]�eo��)k����Q�q�5��w�����ڰi���ס� �?U��P_�߿�!����>ę��W`{^�p���~�s]ﴵ��r�X� M�>�u�����t������]��h#�o�mF��Y��pH6�|R^�����~�A7@ª@a^2�>a��T1Vs+\:�f��]5nF؟�՜?�&��\,�q�'_�!�n��Na�ԁ�/�YF�+����B��{�P��E�0ﬔ;���)�X��1��4m�=�C���_�r��0�,'�t&9��������IRuB�y�82�BC<d�DAL, ��2�ۦHp��wz�BX�a��$�]4��%��v��Qn5�"��;<�LL,9���Y�IfITT��"3Bo�s�eHS�	���J.8������3�?T���-�W� �D���*ýY2� �Ƕ�Fxo�"u�ĹzM`�^&�&%G'd5�@����C`��K��;�)O��?V�M�d�|j�8=>��ʷ��	=G.��X ��;����~�J�{b���IBr����1�<���K�݋k��先�P�/X~�_3P�;8�c�G��di|\�+~d��7��LJA����ו�F�@��?�!��u2	�h��T���`����q1�u{�
���[z�eL��6�"��'N0D/.��p?�Ը�nm�L�u�V���A;�YM���j���0%RHٲ�E� 9�K��:6Tf/CV �=/��r捙 4-�Y����Y�i�	��b`�2����������A6����b �a8PS7��|5�.񅛃�l�j�\l�(' ����7�P��j�2/Yh��%�n�<�^B�p���qi����Mp��s�sU���#�xC�z��M�ϓk5�h���i�i�&��t��n1;eAߟ�X�a~(1�eR�Z��$#j\)Fr)ĥ��mk��p�����no�zP#��G�||*;X�d�2�\�6d�y
���6U����V��,/s�8y+�4Jv3��AZ�x8�fU��5��bVGJ���fq����W��1�҈9�e����-��6���%���^�L�*����`�a!�0N�9 �^rԔ5]�L����e+��9��Y0܋1��ME+�ьW�`�Z���.��6"&��)�]�1.hl��߉tMC_m�E��ޗZ�~�h�"�N��?�����E��EcA�>����x�#��8+Fr��q����.���l���몜�	�t�̗�R2�8��%}Kc�u�b�"䥃�̈́߯��5g}�99��n����&f z��Ѯi�pٔ��~�C�I���e޲\��F����-+���}L�&��%�4���瑢�Y����:����-��?�� e�t�e���X����=�9��HjoҌo����Ky����C��<�n��*b�驁�T�/H�4�+�1`��yǔ��Q�*��T`���G��������6�x-��v7"���hO�|�u{�F��%+,�����:�M����h3��!B�� }�L"e�=i��Џ�t4�1%��8rA� ��Z�2L�?��*�G@�N���)�č��!H1�^P���T^r/�∐������b��0.����F!S���#�0]yLSQ�f�����\Q��*3h)���3�D@e'�fdU�~]fc�;���f�ȃ�B�/r�)�J��L�U`�ꇮ���eά���"#q*� �/a%�de����V��)Q#R��|�JqWmʧ+ovr��Wv\6Hg�x�U���X8��D���X���hN�*!m��	�����O\�X����+K�
g	T��V���s�@��'d��Ѽs��tJ�8��"X��ۻ�S�XD�bs U<jwA\B0�k�9�g'�qF�sz�d���#'|���hOS>�Y�xS�*ں������Vg>e��#�6
�)G�nj����L��pLD��5׼)���6�^�]SY���&�2\?���i�re�Z��6U��a̢􈨑�e(�0B�'-��F�8̢�\�l�`R��(���2����*(��Lu[�̿��e�r!N�҆���({����]���<�A�͸g`�+v��J=�:=��#È)�xK���C�Ҙ�� �sN���mpt���%z�8*rV��C3O���6��J���ϼ��Ԓ��m��R�Y�\���N?��v�F�dG��!���ѣ�T�%��:ۖ��5!<�SdV	���:+�)��}�tm²�0W*Y��!#�=C��>�<`��F
�W|d��V���uY�@��T�8�QA�1���bʗXV)bF|�y���������#tu.2���VTQ�"����6^=�hّ�:�?�ɴеQ;-����j��?���D-�  ��"=��o� ���������8S��뛵�=6s�=f����怐t0]�y�����pQ�Y����OY&�@c�o���43���ɉHl"!p����e�ۯ�$E �sb��1�p��E+��\ǎ�y���ΰ�k�^������":5˄f�i&�X�h(-8���a���q�($��O����+�	�͐�b@�s�ᢦ^���݈J_@�������#�2�F^Ђ.��Ie��C`���=d���a��43���#(���6kR�$V�@m|��y��z��a�+�#p���RHq+�X���ut2������$i�*p`tR{2/��?H��~��e�nPD?�&��"�Y��;�dN(�7J���[NG��4�-��������/�ɳ��7c�n��U�'�#a]&w��f݅�?�Y.@��=��7�!%����)Ԃ^����� �W����t�#s�ʦ{�TO(��e2��5�Q�%5TW��o��וZ��mZ�/f�� T����s7��L�%�̳LL�\�H��"�k�L��B��\� �l#� �F������\ܪZ�Mу�s�:(X�器V�p��q�V�s�)�jkE#(�K#	>u��e\�o�ߞe�N��w�ʴ���s�� �����И�3=K�;%r*~k��1�4��f1	#yae��L(cwXT���튰�T)��KPS�R�����3�{)'�^�.���).���+�ޞ}I������#�p?T�4�p�ϝΩ���<��d��3�LWפ�� �-xK*Ή�n@��ZQ �iS�E��}/g��o�/�M/��u�*7��p�X�����Z'5��e�^ݴ4&�{�����o$E�sh\�����wʎ��7y�5q�K��B�!�F�Ɵ����}k�(�Y��v�{�_�V⛔��Y�c
߹���ZngM�l�����J�W�|'�U�s����y�-��!o��S;p�
}���G�۫���R�ʇ�s�����������Mg��FЂ�B���0���Զצ�;7��M.z~[/Ԯ	���. �@���t~��Mx�q�R��~ySP��_��˒��^P�x��T���;Y��	U�I@��-�F�`p��]8����A��2el�WW!Y�gd�tn�����i&�i���P��þ�S��b���7=O�("�H4@���Ő�۱�j��A���e���ґ�d���=
�~����r�`Ad=�s� /.2��o)�%*R}M��?�Rd̬7t�rȄGn�Y��v�Mz�����o�6�1��&�4�56����J��i8�Br蒔�S�9/����i�fn��]�V}�q�
�H����$�oA(f� e���@Q�)�G?����wH��_��.�W'g�u@�e��3F��4��nτ��U�I���n��U�N�!Fc�iP��B$��eTM{d2bg�y��w���6ΘJ9x���k�Aj�)�u�K��
IUt�i��JF(�Vo����yB��o�)��� |��Q8'u���4�����4m�Ll��,t8���߸�V��#��2uA���v�^�I6Nyn�ȯP�^D��3��[	��O�z8�B����{W�-tC>,�/v\~d������\�|A�뤌��cK3{=��$Ak?�w	B����+h��>nsp4���G�9߭��8�-�Q� �ʉ@?z�&Q\�=��9�|��M���9�B<~f��K2A��3PS�88��E�i������N�X"+��`S��:�K����j���-=�ܞw�=�+�_��5�D/��$� �2�jO��A�HБG�D��f�VG�xp]#0��d�P�O�!��8phں���+��x��'�>E�&O�+9���>�$���V���?y�`����m�������ޥn������ڎ�#�UM�ngya0&����i�i�ڒw���u���#-��Qf�)s��4
p,r�d���=(������LPL2eݝ��i�ř���@�l���	��
��0�jG@Ƙ� �#`�͗��\	�#�91_{0!̺6��̢h[��*���o����쥅�Kߗ(�¸�$r� �yӧ"��Q��R�)�'�B�k��������R{��pI^]&���!�5?f�*�W'�F��o�-�1��@�{E%]\���v�zo>k~Y��U��ؽ@f��O�t?d�+�y;��ߖ`��yW�8�{�6n�Q	�L��ͱ�]�"P������t�H�ř :�  ����qX$aQ�:b��,x50G�/�h�"�����f�s���s@0������A��a�H'�N�^&i@"����ޢ�WvU�����Q�f��u�I��rY}�oR�JD�.M�u���[�7mm���h�0#>��ZA��\�4�8����4xc�޺9��v6�d�0�WШٿ�IE��UR3�+ƨ��ِ�X��jH�n�>}�(vp�r���4�^�z�kvD�̣��}��+���̝�Z�Q.ӖBZ�"�����ɳQ�C8�g�L�|��4�N��[C��G֞q��HR ����(G��ol�U�rJ�j.p�M`��T�W�E�8Z�o�y9�`��e5�k��lôb��|��X+��r��=r�)��FΞHx�Z�����kW,��&���'���?A�y�Ґuc0�=J�F
D?ʳ�b2Q9��Ȋ��w%	�2�U�_�/fێ_f�5�%/���rE.F��(xj�������OMo���ȡ��5�̠�vҤJ���SG��ܯ��#�dˆ�)�k�U�$�Ϊ��@�4Ϟ�M�dj��y:0o~;@�m� r5A �o�o�M��v�$�@�ɮ{��;��R�6���)nZ�r�Ns��v��EH&����E�@fJ�\������t��B�D�d�=���r�U�������l�2%����:���}�o�/�^�������R8x���1��;�>��v�l�����D��]�v���4�T���(������I�T>��9����ڐ�^uHG�[St�Jl9�A��,�����&$@��*3��k�ʨbZ �}�p7��b5��Fh񴶴!�Y��MBԘ��?p[���Vs@2�l�>9T*$�WX�NYl�����o�*�o&�zč���o��)�K��p �����J�S�w�׃g�����d+bAJ�RR���%��Hގ��V6oH;�ҏ���S/iOa�:d�%�m�T��i"a^��&�pE�t"�0�ܧ:�rʋ��u;����YeMmǵ�O9_��ac�ԅ���)9VU�6t�?�C�u�L]ǁ�vu䈬���t��B~.5�Y�I
=�<�6�@�Vb��g��X̴�ϫ9(����j�N�[���C[3���1�O��ï��C�=l
i|O�p��*{w�MT��rx���mN7T���~-����v����s2i�`3�+��sCC�љfX��^@u[�9�L�HRT�+ ��{xv�a�朚�}�R|`D�u&n]�Q�T�a}*��W.��P�
�� �:��o�|�G����{�(a��R�#�D�mf�t�0F�U�D =�~3�zr����1Y�>���_t�M���P���հ�὿�C�]���}D���%`tc�l�2�-��8~q$�ݺj���ss<���9�E�P�YC���[�̻��]05�"���R�M�"�i�}B-�T�n6Z�Y�屺%L�qs��5�^�?���Rd-�2���ԗ���E�j�(���M�hR����;��I�l���YUv<�������RD��uع��W�釨�f��7ʿQAG��I��g�D���Gu|��pL��7�¢8��U�[���rc�6��~c�ք������K�Q0Jө
.lgr�.�/K����������R�/x�Vqѵ��8\Q`p��;ɺ��9 ���5�6��̣��U �;`�pw����8!Ka\k��d	V�]���Z��^vh����� �	�ϙ��l��y�7e=��J�R�p�h�'����LY��%ˡ4�E�M>�mgD����ӕ�i"���3�S r�(UߢY���I2Ԗ�|��)�F4�)oIp�Ge"�;'��r)�
:UU�5�8Ͽۣ���n�נ� 4&g����	1BfEy�ن5LR�r�+�ޒ,$��CCzN$��`~�j2���6|ā�}"	��'�"��,�mpjJ�x�n,�5�v&�6!)�^��m��"��Z�M-���̏�"� k/�FB�A�|�L9�'�A>UČ^�U^��Lʮ��~�����!����sE�3�6D�m���j&-�$��}��m�=
6CA��2�]�;r;�;9��]6��^�wRfS��<�&S�[��Ⱦ��S7��'h��Füe��5b�%��^�'�}�{r���dRԠs������Pj��P.�8+ަi��D�<���N_�[JS���Ò|Y�0(n$��Dc���%��!�����359%��N��>e��X��d�b�3�B���VG,u9���'�ࠐ�@�-i	+dD�ؚő��;�` `i4&�X?�H]f�փ{�O�k�3����q� ,����pd���6�D�����2�
��>f��/5%�s����������\Z����p"!���`ŀt�����h��
�7�����)g�1��}�sO�q��ܑ<���C�̞q}$7���p���U�ᨥ�g�ѺĈ��ڱ����ȣ���2j������8���V�7�zxJ>�	�K�뇦��~�����j��)\�ҷy��f)X�Y�2�1�~ ���)c�8��vRX\�L��lP3�"+q����8�䞖Y�L�F:���K?Oigݝ_�?�^e4pJx~e`�کE�%���I��H+֒s�O�f��H0�(3s"܃
Ex_5�r��Wʑ�5(b��R"�ث���T-�ssn���1�M��@��W��R���g��$�kۚ}؞�H��z׸��_V�W˵K�dU�T�Ӄ�%�"���;8����놅i�ݔ#J��%pU=7/�"EcqϞ�6#��q[|�H6�")���[A/���X�F.ĨCmљ�W[�~���j"{������~eN:��N��<DG������k�V����
�������4�����;<�d'�����ꅼ{�蹚�v߹R ���j�!��g�]�z��t���=	.:�'}�j�ӂ���?-3Į��A&*TՍ/���:�8���{BT2�%�*��啐l�����ʬ�ٰTW�^Kzy�.��-6��w{�VĕnՓy'���O�/t���
կ����\�s݌� ���i@1��à�iq�*�XZl��l�&�%��z�mO1�:^\���^ݭ��|���e��Y��1ka�1�S�e��C�L�h4����H�$��ϭ��w�a��n����3��e}��D3T�:@��sz��#�����.�HS�;:���/a���I���{l������60GC8��5�F G F�}f>m����+ߨ�,��X�^h�Ai@9�Ů�-�`S̿g����}�a;np�@F�Ȱ�����H��
ki�g��d��t�@k�R4w�#��nSO�W6ax�\D`�|,�٫f	)��	~_���-�?v���M#=�M]�炦�����R�q��Q9���ş�J����s���Ľ�I��L���mt�J���xN��><�]gAb8�bo ����đ;!�9n.���{ke��6�v@8e�
ETp�E�SqM��=���鄐��Ca�d��\�����r%a�E��w[{j�+]eMa��,V�ۥO`��@<	G��`ߊ|]H�7o�7�(F�z�=�p/^Ծp60�����5��	z�"j�Z�jV�k%r�![� �_%��0q,툶�=����pB���$��G��5jV�z��s௫���{'6/��Q��ǻc;��!�(���Wj^��rC�D3�!�@�2	�_����feQ�cc���2�[���LJM�BLw��6{� �$j�����vǁ[�Y�L���a,��-1ዝwC����L\�a�y�Sh~|[,��C���0�l�^�xb����u�ݧtݼ  E,_���� �����&��g�    YZ