#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3599864335"
MD5="24cf4ee885248ea7c9e1f61e45d13e69"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23580"
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
	echo Date of packaging: Sat Aug 21 15:34:46 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�E������߾U:N�y� {�� ��\�9��"��wX�CY몤�������ΪR��t`�M�)l����૧�vK �q&
�ͫ�KҢ��m��h���� ����D�#�G��`V<�����~d�Sa��b!�F�j��Xj�n�[q�d[!�����tvϛG���\J�t)A���>UJ����F7�q�e�G_R��D`��s���EˏTڟ~�J����D�k�ii��aA�l��w��&�Q��2�6>�n�D�����t�HR���?������ɮ� ���5$��ѫ�?�wm�^jTʺd�2���c����Ww|��!�[�?�M������k1#T��0	��=6�8Ў���N�_�*���Gr���?�1�����-��-�gW�6;�uԌ�2��y�u;jN���V漝��w�\�4���]Ґ�&k'�Q߰�}E��G5~s/�,�vt�*$��=� �1Bf�-��#KF��I���<8C̈́�Y��a�
��D�f~�4 �װZ���|�O��1���5�#y���	��V ��4�e�R�,�y��q���w�Rʦ�C�-Z��K��'Z������Pf� ����A7T(0T�Y�~`�^wd�:�#q���a7� �rP�A��@	�s�e�}��<��᲍��%3N)D�~#e�V���7��Z�{:���i1=��#�5��������4����68r1���vR���U���n�#���t�1�b�u54�O8��l�C��a�s���	�zd�Ԩ�*qB���Kf�M��Y���og���p�u��WLF)[<2��*gx�dC��ÃǮd�y®+��L���F[�O|�$�o(��7�S̞��V�z�6������;�8$c��A\`��e':�BX\�o�����_aT�l�r�_u${��ya�F�j}���XܷJ7%�bW�<I?�p:��Z|�#���vTS"H��p�b<(�>ZD��\ؖ�c/���C�c���0�C��yN����H�r�U PW�,$�=�5���j�e^�,sLG4�Q�˒�&r��P��W�0M9��X����N�bt� y�7W 0����XpK z.�m�V���!��6O0���Qk�k�T$E���M��/�������3������kXR;��<��L
75���qAd�Q�J{��L�T�_9@����Q�M�1�i�c�i18��Z�DB7҅����_]-z	:z��<���R7o ^kz��9б��T-�K��no���#4�|�(w<���EӦ2���F�]~��.�Z1")�7�|_A�d�}���s2�Ig%Z��L�+�ɲ�>��!�=$=.�뾳�ܺu��CT9��|Pb�cp ��;<�t��2�|ޣ�$�Y6���|n���}��A��_���*ӹ�S�M3�C��)�6�ӄ#+`��AE��,u� �f���)�� �:�}C�ǵ���-#��ízV��W��i�K�n�[��%&�*�s�6��d�����R��ޓwIF;6ty�7Bw�EF9k\�Y'�]��0_���ly0Ƃc�,�2/xk�q��uH��ܢf�]�l	M-0���5�e���
�x�]wy��u	��ƾ>��~dHj(Ф4sظ�O��tIH��/Ku,І�ǆ����b�KI?�B��`:�����������3%�8�n�
3Jw#��V-I�/�'^~=��UF�/�g�ą�����~M9m�<XD	�Ĵ���0�l�a�nѩX�5^Ej�K��ԩ�	?5\'0}nſ��Q��IA��W,D'C5�����[�L|� �6$?{���S�_!q��FKH���t�hGh�5?ه��� ������.�d=b�&בs����6��p��v�1�2�9����Gca�-���7A�k�i8e��TӢf濵�M[���ƨ�v�B��V��v#m�ր�j̼��}�0O�)*��%k�Ä}��,Q;����(�X�@�ב��И��)'wuS�����rk�CO��Y�v��c�U����%����T)�)E�,z,>�/D�c
e��3=�0�����p�����ǀ����`T�({�z�1�v
�J�^P�����r	�7�YAc��_�v�ܭ^��V��/c�bP�O�wdY��Oy�Ca���	&�^�j�Glh����AU��y�����v�ї?�Boi��	�)����|:�>���r�����O��?�
�\�6 �F��P!��>�*[sE��ٻt$���a;+�Y�z�j���0w�]����7 k���D���"����첡�Jz�ظB㎩��;�g`YD���0^��|�AIT޳s���. �(i^r�$�6���qs�]C�iEg����|Y&�yo��܆�>N��\���lJ�ƌ���1�C��)�|i�~�
ꞐR�`S���X�\�hGn�G�=����"Qb���`!HF��_���S'�l.i<��4#34Ӷ�I��X>��7���Av�o��W5�Q�� ��z�Kr�f�.��r�rp�+����(��?q�%Q2�'8 _y2��,ų�������t����|[�V���'�9����=��ϳp�c@ сY�ЍJ0"ޱ�P��u:cc(�E�Y5�},98>����G�*�Cr`��X'�T A枞�RO6\��%��p�sX�~|[�(ϰ��en����Ta<(�wU��I۽uY��_ ݮ�8��T]
'���5'�}�	{@_�%�뚮�t���A��q�y��L�w���2�(2��ᱻ�*F��~A�����H�#���s����ou�o���Ҝ6�B�!&��dU��8�8Qs�����d���IRmް)Ԟ��]��4�ZYR�� � n8��5]�Fhp��Y0Oe�]���\8L[n��w��L��B8}t  ��(T|���Wݧ9l,쯲OĚ\�@�V�� ���9~��|���ĩv�d�8��X�ךZQ��J���I��T#�89�1�'0�i�=l�ԭ���U��/WMڣޔ���oϿ�_ʄ��rt��	j��OQ`b�Ě�v�tq:���_��'�qi��n��`��c(�E��&W�f�2 ��vFܭ_z!C�,��c(�:Е+.�ʳ�G�̀�
U�s���V���F��:�N����7B��F�\g���A��.B����~�fֳ� b2�b֓�Þ���4�"��B��gS0;�g�ݚ74Z��eB�*��h1�+=8�����,ب����Ok�4�r���O����,v��f�l�"n����o,{��4{�A��Q�ߕc�`e-����Č��͜�	+�
=>5í��;Q�$� u�zd�	��zѳʷ�U���Uu�1�F�'�緇"^oP&iq��d�tx���9.	����Ò�v+u|��4�ߊ�O�W!�V\#lC��.dȨ`�#e������s�F6{�x�1�Є�n������wH��M��<��ݼQ�!H}n�y�P�.i����#��x����&b\(eP6&�nՑφ~����j��KxLl��G���`c��_�~�rYq"vx�̂�!��bz�!��M�g��ċ_�Xp]�6�S��^�[�Mt5�v�c8ꊀ.�j��j��)�t����@
.vv��K:�x���خõ��3��=����B<���{�T��L��ER�0�ն9j�Z��t�>迎Х�����=�Lj�d���c��(T�giǐ�5$�j�:j��F&0M�&)�)�Ҙ�D��YQG_�_�V��h@ln�����ay���s�D������h[AX̥La���+��M�z���#qEr�a��s�����O<��^��Y�.��d�vY��jy>0�.D߰�H�ҥ�c�Sd�Дd���	S�V(�;�f�����ۀ@�({�SD����H����W��]8���8'!x��]�ԣ��M3T�V��V�����a�0�@M�������b|�V~c�������D/R�\n?-�Xe
�N�z�N��v�E&���}UOn�y]��D*�
�����6M�,\�M.[�;X�s�o��̷b D�(�V�q�"��3nI�b *�J~�QbG�:���ʞ��gw=��5�T���y�z-�EP�@8�r��x�yˊ�lDh�J^����}�g'{��<2�W��2'/�h�O9�w�_Ib!%ĻO��t���܍ұ?]�\�
3 }����Bk�~���~��d��@^K�K��^�%$��t�7uU*�c+��b�����|�N���I��>�g�>��"qxv�"�ƨє�síf,O��:��Q�l�Ľ�)|@S��Ի��~.a�%�$A�`���ю{Z�ۊ��،{���#�xGe��~4�c�Eoe��nዃ�3q�~3�Mϳ�T�nkAl��)�4��bӎ�>���d����8}i�e����|�,TNut`+qj�;)��52�d�����5Ɩ�@��r��-�X��<%_xvUPc� ����s����@>Y�<��6Ă����d�d4b ���eE{U"�p�d:;*�T4��u�Z7E����q���V�<N�'�����Ij�3���8D��G��!���.�xsY|*�P�Z�{��7��!L�6w���]�4�Pl1HFB�jʆ����z=ìI�{���c�g��
W�C�cRv��#��hvI����v>�l�ݮ�G�q��k���aIkps��;Z~�I�!t�0Y��Vj�f�@�/蓝��D���bA�_Cˢ��Y��"~|��G�>�Vi�J~������=�w��#�J9��ڙ�_��>��6Olm7a�V�8'�z�n��b�8��'�ٔ����aR��t�n#=n%K���!F`�n��H0�B$1
9g������@tM�+��^����$�����H����0e�SQ�Epk�gAn4�!����L�eno?�L>W�|1U�E p�1�����5l�Л(u�v���"L�(��բ���:�%�Ҍ�k����H�c��:ߗ�P��~���|�st���F�S���Y-�z�mG�����ƔB�;@�8L��?�o��7müx�,]�����D�����m>��4�a�%L�Q�FmwJ,YOc[}��h�6`�-*;W������+���x>^>�W�E6mǅ����t�ŮZ��uB�7cS����#� ;���/���S|�o]5���˨���43;+���;ƫ$e���ΰƕ���jW4�%S�%b�A�`��l1փG�_`�ը_�ﱲi��_�V��
�9���J�����ؠ�(�M˺m#�p�{�J�C֠�{�{�Z� E݈5�6p.`(�<��Q�A����m���W�1�#@�!������B�S����n(T(>Ǹ:[�}?bZ�K}���ҫ��qZ/�Lr�)֕�ZΪ\Z�}����%'Pœd����5�FS�a��Ʒ`�3i�- M����"R+�]p��L�EW��j=�Sk�]��BEc7���v��z������7������xG�ѫ�m�:��0�̃�]�������|�u���%�;t�zx�^��Y��s��]�<� �FRxOϭ����e�
�+M1��}I^�����i#��0���--�=�EBF�M;��6��� Hc ��ޜ�X�9u���?r|��Q,ĵ#�慉DsU�5�U2�)�0?L�P���4B�2�A˼�!6�����8�YiMU��%'��%���k&-]�W�t'C4��^4 �lx�ڤ?BZn?�L/��, IWD�a���k����%���i�����j`�O���t��P4\�	l��0M���_�+���
'��U��S�K�j��UH��nW��h��,��x�n��q��/���'��~PAͱ��e��t@���W����DtO�T�r
�MX+�<$#���̫�:�r��21Fݙ���Q�G[��)W
����VT�hF ��Z�/7 ��(!��́��<�r+Ec�F��-W-�w�LfR�6��>H��(��*���TBJ^L�פ��v>�a��^�-�����y;��/�Ei�'�b{���TO%c5J��羄�I~L�_In/�+�LZ��E&�Uu�W}:6�A�ǕfJ�Ǐ�ĩ٦Ә����ݔ�[�p�DQ�:a)���Z6�i Kd{�:�֯���T[U�G_��G?��;�x�Hw�[v��h�1WXU��|F�u����3
�~�?$�����7�|���{�5Pf�F�, ����Ű�\�/f�&kk��r�v�]ʊ%�2)���KP�ƒ
7���A	PbmE��=f�>����{m�̰���D��B���]��)����'Q�E���5�~��bYpb��\��:)�6>��n<���Dyn�b��J�vj��܌p0�^۴:���?�R���h� !ɦ�&=��[!Ba��w-�<v�5N1��e�>��\)���⬓���M�p�'IO�ʑ_�78-�N8a|�ש0������3�.7�C5l\����޳�d;��yz�e�k}��1��n$v��yq��-݉�"#����7��5�}�;i���}�kCzCBHɫj4���J�_��R����8*Ҧ�Ė�����XZ-����KĮ�����Q����������0d~K���lt0~w˴�E*�\��4�����C�>��o��5_���3V��m9!��̢-�TAC�q�k�o)�)p�^��DԄF�I	�'�#u�)6��i�)��ZxL�c���K�.�&J����m��+�1��.N��\{���y�1��]<�*�z�N˖�4��J��7�u�X��r76rT�
� v����m�F�4�iyL:֨���(����2t�2l����|��N��ݭ���^���m�������y���$FMGyܒ�r�D��=ź�rk�o(�eb����EE�bߤ7(���K�~y|�5o�F/�C��v�#	ɟ�"��h>zV#ї�Wc*��V�Sx��s�(9BYʋ5�ߪd���#�.B�$�1����=�5��'Z��`zع���`	�(%hp'�2oy�)	3'4Nwwt�� I^���gB�¤���I5�
�0�N��[\+�dG��+8A�R"��������Tf#�	�h��qA�# �P�K_t�9��	���L�V���DP�
�I���8K�z���H(��F%�m��P��p��W1o����	�O�h�W�{K��7�P�5��c��'/�B`�w��Q�W��ZT�̧�jc}W�8
��� �ʓ~�H�<|�Ƒ��mI"��s
i��9�vB�^v�������པ�Pi�o�D����Xc�3�`L��²����(}�HL�P(+�>�zX��@��Z�{&�\D�~�5Li�+/ջ?���_8*������Z�_�"�Q�7"72�"e�a�����H�!ʿ	�*C���\iVD�}fa��{t�9f���X�Wd$	7%�v���XlR��Hܯ;{3d��|ፔkv�;�����=�bj0�)V��0vo���T'xK	�"?�d`��>X�sl!�\�Cק��\�Klc�M-A�-�����֡c��Үe�
���Lߝ~�ʹ(����y�/��:��5.o�Ջ��C���&�]�6�R�C��˴k֊с9	�&��
91xr�(KB�I�H����_`��1�OLZa�YU{}S�������/x�j�RH!����v�-��`fZ�ƹ�#z��	e��6k��9�A�y$cUt\¾Yf+�_�;Iz��]�)G�cq�S�d�|+������0��b����z�����_סƽVK�fJ�[`��p�S��&�G�@#��2�� �-����ac���BD:9�]�UΫ��6�;�eDD4g�x�+����F��l�yUU��?�EDv �R�e�J�B�|�H�@�M_?k����Ib�0]���(����!x1k�S'��a�ڷ����M�ѴϞ���*�2���"���e�f�p�N�?���9�W��m��������*����Zɕ�i$P6���iC4l��~�H����l��>��S4�$^�:B�X���a�z<�W��\�B�"�c:�<j{�xȤF�?��~�v����u='�a�fv�� �I�I@<�g$��Gנ�i[�S�+KEH��~W�]���X53B`����N�m����D�_�Rqw���i�� &��]��
ܦ�e��׻�&��&��i*(]7b�8��1��[+bAA9�E7%�0�`�nQ��=�퇣VY�����A&������'8�����n���[��l�*������=���ǵ8wZ����<�B�F�U��A�Wp�x	�\�
����髺�x)��P[�d�����C�_Np��WSB�u�1 �bq��N�UW5j��{��Sh/�e�ޫX�Dp��]�VhG��7���i&}aS�����]GPHpw�jr�p��zB��I��p�ᗋH�0���_��KH]���ax��2)�$>�o���aj����)Ԫ,�BHSP�pg�g�|v�T͑�&L=9E���v��zQ��DG�b,�.	`�vz���K52���`�،>$��S(䆩'X�(�M�����OC�v��EA� x��jCJG2X8����sy�*�%�|M�-ӳľ6�:C%|�ީ��[4/"Tt�n�ni��N/G�@���2���?��D�+�f�������vS?T�rqTw��E�^ī�}����m�k"^VJ����w�h�#?����3`�ur>����6�Ӽ��b��$�IWzc�r�M{=��y�����?�q��C&-}�cÅ2,Z3E��l>�����M>��Yȟ/�sg�H�&OsF8�툫I�B������!��7�����G�3�;[�����e-�̬��	E��ҷ��2�C��t��G�|:Wm|Y^nM�0�Li�%�.���9�'p��,X����θӅ�`�a,��k��RJ-�\gl�B�&M�E\�وY0���z:��;\����9��Q勒�[Oe� �>�<%������ &@�0�;U��L�~B2�)�|�t%�c��/ޡ:t�E%v����5"�h�X�AԕPy�<=���~��-q�L���˳n2�Tc��8CF;up~51�Bq�DG��q����q>&�)G�ч��ԯ���b�* ������z�h)[4�sWh�����u;�g)"m�d(�^�{	���I^/tt���$�fӘYt���"8;#i�<��)��/�2t|Shv�Hk�A7_!�U�(A��H�'qIo� H�o��T|d�|?l�(n�̭�%�_�C����ty$Sű��ˑu ���� o�t�J_��V�]9uK>5�}���@*-(�P��Ҷr�jA춉�^�[7�n
y���|�"�%C6�՗0V8��h��Z��M1HM�#��Y�+�Z'B⚁Z���
���"�)o3cĘrDx��w��|�R�5S�Bvg�߭�6��n�*wp�TF'F�̂�m�;�K�m�z���<���E�$M
�&��"���������W��?a���������B�b�j�0�j�z����Q��å����:�_ջ���c��@4��T�"CP����a�|qB.du=�Xbᚙ�QS�S����p��4���К*��JA�����~ts*]��Q�mvw���w\?rMA�_�z�*@�8��o�6źn<|��xp����A���¹��;�ܙF��2���;:Q�1�0K�-��Z�ϰ��+�0W��v:�=������ S��P��P�s_0�Q`�k$�}_��Tun��(V�_&�|z�x����=v���5��=򙇷BL�v˚�#�2�	�9���S}�V�S��>�*��)5���>�ݕ}����[(��g����S�`���*��V����ؕ5��A��[̞��"�р] y�׭��H�,e�-XdiΆտ��hi;ꦱ���n�U�WSj�cv3�>0�}Lh���V���u��a�T2`̑��V��F�.4h�/��Tr�CL��@B�2��Z�?�!�TH��9V{�\>�j�#�j� ��vջ�4���*a��٥���_�ĺ�: g���`�r?)�*a� �N7��T��%�-Pu�dt�=q�2k	,�	�����	�5�u��y�b�,�R���F��WO�_͔��^L��:���'&/}@��e�������ᗸ��(B��'OV��8�������۞��"h��8j�~��y�e��_|���R3�O�����,���t��խ���i�e�귬C��ʒC��aͰ�I�~*��y�sT��a��w{��D�Z�d�C�Wc�<��������:��k�ٓ��}�[�+�9D6^������!=������Ν���Z��"Q��ﱽb~e��%{Ӳ�RGe���ĽT��A�zU�^sSÕFCv�S�T�!�tb�uO)fo��������=���L`�9���m� *��?vp�+�~E+ʶv�EjL�^��k��즐 �Z��N��D�fc�c_��'��D6O�]�����ߝ��%7	�Gaa���*3�������ww~��7���4�EfU��n8_�%��n��J٘���	9X,�N��k36��D��Ѧ�.��*��Q� �ٶOEk,�3�yg:V�<1��`ܔu�u�j*�� cr�!�Fj#u0���4)�\�]s�$�S�#GG(S=�
�^=o����bӞ[�����w!k���@�"�gEk�?M�Vԋg���0��|��@���s�o��]HB� ��T۬��%��yPj��_ݚ.P�S�r\�~P�	����0Z	�_�\}�;�k�w'���E��"��0����yN(ǙX���s��F�,齫�.�-�p ���x����I��rN��O�Q���/�&|Y���!
�An1�ίhj�܈��ꞛ�?���'�	?���WӜ�O#��ʨ -?u��d�B!$��  d2���(�Q[��a�_���������M������K/�ׄZ?����ol��'� "5�Ҍ$�����.�L����D�p������a�oq��f�V�X�t(���K��G'vxH2����`��p�Jkl擃bgZv� }�Z`����пz~�7�|�&����!7j��314��Ct�M�~TR�.?���_�5{��_�H.}R豍l������؊5�0;,ߜ��ez%�Y�\�_Q��>+�T�@d���D�_�]��'ѯ�g.S�B�C�{|�L�1EF׊�\�d4׳r�;���07Z��xux�&I��e%����h&��&s���7j]w�"��n�76�d�fs�2�E�"�-���m�o����ߕc����23�?1�]���%'� N�F�����.2�c�N��T�2�|���uv8iH.��R�q�$�S��o�ڛ�V�b�i���ah
+�p��}�Ǧ�����j6i�{���aW��f8C��XzO㒁�ɔ�(Z�K��|b��܌�� ��9�b�d<' �|3��K�*����n���_i��"�h�D�$����8N�8�y\�z�٠�Ldb��wS�Td�Q�#�]ցL��Q�i�)�`��&��X^D�_�u��,�k�!P�x��6�a���j}��"f,#^�n��@�MHᴛ����t?�#!�&��\g:1b��N�,g�PfA��梨�^��m����Aw�z������W�J����".%pQ�w�����
����l�	��F��=�.p���q���x���D���$�w��YdS&�]	8�Wx�o$�T�D���
NTRB�O��H\�B�$:�qON!:��.&�|2\b%$��	ن@-�zC��S�u�5���~��ޖ���y��F��5�x�<���V�P[Rc�+��߷���l�\��Y�/N��S�ڻas9,�][�U=�5A�7R����#u��x2O�9�(;�L�4����W"o���yg��>��:Я'����t�Q�J��со6 H}_�a���Kb������9I���BԾ�L{,��~7�ts�g,�(�TM�j���D��W�F+C�2N~�.y��9�Pq3�:����G5:���R�g8�E�fY\x�B�y$U�^�E��Q�f �>9W�|jt���fM7r���-���S�^���$ޫ����U��.�2�g��Ī`$D���4
s��2�e�f����n��q�Ǯ�r(봤�TD�@�d>Z�����4UU}��Tu��y�E�G����l\iN4(����龆q'g���,D۫�U���HlC���$'�S��d��D�)��N��+`B:T�[�[-�:�3���5b�pd���N���;�]����eyz. ��i��I�`Њ�%x��XP���ֆA2WOE����)s{x[k�b�2��~ʎ,�� �TfRQ~��$ל�hܓ軚EN*��^N��]4���x,0��" �ڴ ��!|ue�=
^�<��+�? ����)$c�zJE���U���%�������L��S.F�8w� Gp��aܹş��5~y����rq�̝$��5�p*%��[{���Z�V��W��[;.W��˘�����%�e��.Wa#�p?@9iQ�Z��I6bU��>.!�dH� e/P|�c��)B� \iP��a$��� צ'4u�t���Eh6�6��3��%S~�I38��H�iA����S
��@?lN���F@��Fq�����9��u"�Ĳ)�soN>��4����ub��~T�E��t�4^w�	������w�$��t��g�ʚB�yTsbq��o@OJ��3PM��᜿҂������D���w�T7.,�;��Rru��UI�8��������y�W��En��Tq����=�@؞19uK}ңC�bT�p����2�i�-?��ܭ��%@ٿ���[n��{�!+>cw=ƀ�?���L���>ԇ� ��r�����ޫ�����3j	�ɥ�k�R6}�͔����$�������p��-�]g0�8CǓP@��vW�zX#�����j�R%�_��wr �g
{����>�~ț�@�)?ˢu��^u���/Y]?����c��{�k��^��>�*=�c*���XW4֦Y���wm+[�	�ƌV�q�m'lX�ط�}?���e��qH�gTLOh�e��$n43����ZF��d�ºV	tPj��ı�\�B��m�&H�dCȗj���n�Ɯu���d���7�;:��e�Z�tw}��e���;�d������tfc�#/�J�U�3F�K]�t��$X���v)>~W��o,�OA�U�6,@��B5^��Ҧ��J�	���v�!�-��T�����AA�|��1_��7%H��3	��� ��KE���A'�{������d��&V�ue�U)��f�K�i,OAU��ma�O�)��: �v�Ǧ�C�k\u��i�AABTaI5Щ<? t��"Qpt<�D���ȁyO�n���{���/��U/����$��>�l���y;�]-�?�'�֌�xF=^� �a� �1�o�]��A�fN=���0��ھ!���[��E,ށ�'�X5���y}&ۂ���[�	�zmr���oŷ������N-$~&^m���$�	 Ws����x�3F����{���[�M�Y��E�x����A�Ƞu��}��h�E-���
���b��I5���5�Cܮ"��q�9(���gi�ZzH��b��އ1]r+����s2'󎌾:�"���ƐJhR؋�ة0��q�\�&�#�b�o����u�����ƬX�� �
�b`��9�[Y�E�('�+������&��؟�����f�����,c��qn�J-��G8x1�Vؿ�溛X��MHt/��������E��)Wx��..{w(-� MeO��X\j�W��K-�u�{w�6���C�v��
;,��vS쩼ɸ6�ܯKn�g�Ng�ͧU�p��k��Іkc��Ze-����?�^���d��Y����(,h����f�KC
6��7잺9��Hu��_��M!����̊f�^T��K�+xu���r�H�<A$袯�2׵�C�[�6�Ѡ�W7 M�\w(�7�>�-�� �Ф��N�LyG�-'j;��p"t�駷Y����<����MIG�}�|��ỏ�Etm��+Ho�#�@���K-]:.���CY K�vln��o)�cY���(Ϗ��}�(�͙0AN�w��[7�k8/:O��+�����ltR��M}���Em=�4=g�m�ӏA@x�vV}���tk���e���VF�/V�!fI�%\��~�2�1)��"��^�8@�>X���V)�Lkd�ҹ���]�*TxV�#��x'��p�S�Fp( ���"#����No_!W�8��fk�̽%D�X��K��$e0�O�t����������1�]�4�#>�n���rm�Ϸ\���� =�J�>Z#	�	��І�V�0�:���0�;4�p��:\�i��ש+j�s�[YZL�x�����6x�7X豩j��_⤘�b]\N�"����?�p��Ͻ,%K�p�]ş�&�j���}��d�
�@0�,r���r�!��,�X�2��'�_�T�- S�5�`\,��nƷ=��Q�n��g�Ld�/���lD��6�x��wVM���bp��J�Ixle�1�d�&�N�<e�E�Y��ŀ7�*!�+OJFK�rγ���_;�Ij`���ͨ���s�b(ξ퐘��2�!Lu�q�)���񥼩:Hm��B�~�8��?�P��Vy���8k�(aE������E��ἄ*�C�r
��!׼��D�TR���� nrD��<��D�\~��m��V��-�	�z�Ȼ~�ٱ9��쇨��J�$^���^�,D3�]E'ɜ�o�7�8r-��"�V�n��V`��nB�?X�Z��~.�A䄓o�`݋��Xf�?m�ܳ�1��l#�[xX�^�!3c����lF*�U��56����~�YgK� �ȫ��G���O��)Tn$��i���׷�ꔋ#o�-d���8���ŭ��DZ�4d��g:V)s��K�3������a)��u��J�c��R�l�����P�o�jB[Y��VS�A&�B7����c��h�37h����Z����w��+'u+X`K��u�b�Ŧ"�IQ;����?��4F<`LNHJ������#b�����������9H|8����o榣5M���k�]����*�m�n�Ґ
w3=��0�,���I�`�M,R�*���Q0�D��ZH���"Ӱc���_6�`P%�+�1@��Lo�v���~S����۴i�تn�4�N!�w̮�+�1U: ����9��f�Z��[���Q��BwRXi{t�aoH�ŀL��K	�漖*��.;m؃� V���΃h��u���U0�)��{��Y+pу���B���|.b�����m�~}�}���-7��r��|�'�Y��D�bfd�v�k����P�ϓ�/1� �{5{�f��C�]m,~��^a��R��]�s<�x����bM�\6����k��n�:L�N1���/Ì�
���N��ޅ�f�JH�>q<#�g9���yW"'�~p���M�E!V��M�9��ѿqYu�k�+j$���m�c�j ��g�C�p�BӋ��`�@�?X,��!�xр<�/Љي����/ǔ��?Ez������%��U�Z�����8ć&�4	���9���C���y���A3�z��);�F��%*n����|Sv�T���l�ۥ��A�0oMF��X���WϛD�\�s��Fl��"HA3H~��9�e�̑�p]"qR��4%�p[eX���Y�@��� �X�����28`@��kKl�RB����W����iB���Ҵu�9U7��WYw//���T�ɛuӱX���̿���u4���q�ώ��Kk��E��%��%��^1��ϻx�]�t�*�9��&�}'m`����v�'N<+�NS�����Iv����F\P mE�7��B^8-ybcn#П����KZyxk�F3.(7�-�\�q�B[�׺�!��
�|��B�$��Y�YL�����-�.CK������{�� �94�%c�H��>Dڡ�Ջ2�y�}�r-
�x\���@��c��	H��M���u�捝�O÷��&|p�w�o&��0�O�V��
��s�Z�a�NYW'+j
���O=Ȯzx@���L�``�l�t��1kp��pS>���Q���W?����Y2ym�lǲ�����P���`�bX�	)��>Ŗ�|cP݃��Q��)�1O����ѣ�m*"@T$�������[Q�n�e�y��3MA���z��-^٦��%k̹����GQ!>�Lv�"~���K��`DOz?���/ES$��.
I���c
H�3E+&5o}��
7�a}��9ҷ��Ú{f��S'��,�>L�AA^<��`y�r�܅&m.����Z�h��@�V}fy�b�'Q�V�@~'A�>O���B��B[~�Nӱ�4��(ۿI�"�f�%�O�sl1Dݻ�u��,�Ѕ�	p)fS>3Lʺh�xI'd/x����5j�����l`qň��/�����qn`{�ܦ��1��Y�u�M{� t�ۘ��/{��T��I��6s������o�-����Ha�i�5ݵ>7}�Lp�@leB�F<7����*1����*�KGZ4�` ��d�0V{��X�G��@Vpf}�;�6�����ã ��\,,���#ŀ�{ޔFZ�Q7��*F-k��[Q>����2����S��t�1�i�����CL@|gh�[��}�3�,˗|�7�n�	]1Ͱf8���^�N� 8H�}�4v�i^y'�Cm�0���1d��=�Q�²�%$��*�Z[���̚$f����{��_����Q�P898"(�}���Oٴc�� ��V�g�?��W.F����� ����'D"&,�- /xA�+Vq�]�����_eQ��"���%W�0g�{@��V�)�$�^��e�����yK�3�K��
���E��zm�3DJL�Ş��0țA�8��>Zzy�͠��-�<���`L�ѫ���c��yE�K�Υ�P����Q���P����S\H�R>k���OQc4a��XӢ�Z�|�����A��ѐ�Ō������� �z��Q�^<ı�-���P�X�YE��i+?.�
a�h�n���̛�� Ġ]>>�V�U!m�ȇ�9|R��eSI�� ��e�Xm�HCS���	�TU���ѵ~��|X�{;<e>��fp���2�E�񨱤�mB)N琻J�K��N���hTme_ɑ�����M��܅P�N��6�(d��!Jv�k(���7��L��g� ê�(v�i)pB��8���8u2E@�a Ys/ty�"DRQ�2ݩ��h�)�����|"bN3�=2N�V�m���а�N7�#�������DA�{/�VB?�G7� �(�!�t�j�Tu����PqAgG�#�c�v�#�D�%k�VWS�썳����I�{�IsO[�Fq�sV��x
V�Ԕ��Z�9��'?�v2���d~x��O��w�ba�����<R��f!���v��}
�T֙�O�,�t�ٺ����~�n�B�	\��j=��:��N��_)B��ߘz�a<�>D���� @ϒ��3�u��ab�W^��`h���4�>i^�k��c�f�>��q>�);����%�c߬ �Po�\�_J��`��z�9���"^B�!4z�)�FjlK)XZ�����"?(�g7a+��12�W����q7Q,��AżS�?:��>gL�Z��� ������0k�FU��γ�g*�������-N�c�a{���ͼ�Q�����(���8�.���u��.���>wܥ��24��0mD��7ʭy��ca�0����F0�"��4�fp$w�f�d�� ?L���^�] �kl�ʼ�΋p�����\h��<U]v/d�Q���L�9���f�ysR\\�8n��@Le����2jCc~	�g^��[
���同��Ӡ;Ǫ�:$F�g"��h�VOk�y�T:���]G��(p�;���ќ �X�@��(���.i�n���^��m��y@�Y��C@g!w$m<:)���<�q����NIe�����FHȐ��T�z^���a���^��He����d'�1h}c˰�R���ޘŐ��<���v��H�Wl*4|�x{qCb{��G�2����:=������C�gLɪ#"P�A�^���J{Voa��p�~�g��^*�����Z�H"��ϕ�7�����~�'=�o?�u5�ƒkW]z� ��:���,[	�Ž����Pg����C��xX;�sIDf�H���k�O����?CRB���fBe�2k�;D�(b
��4[��*�n�G���M�0Q�j{q��.��;k�t������Ͻ���/ݏ	�۰n�a�UcJ�ȭ
�H�,��_�-X�qg�K0�{��4<֌�QP��MVP'o�;���Y�t�5��]�s�����j�D(R�UyKT��"!Y/a i���ɕ������#�^g�*� I5�`L�p�kRl�C�,1F�#M���Ш14��߄Ef�М9^e�������"-��V1Q��B����>U�F��3{$�1v	0����3T5mx�;"㒹��</y�2trhh窎�:b{�ԮIS�^��TQ"zc�̆��A�Hi�{҇+���J�����]�i}b��KTo�lI�+]X�ֈ-a@���r�
��<�����Dt��V��&u��˅���8�԰���ar�a�ũ��]i�THZ*47��7�Ul���xԳs���qZL���k�<�%?�%�M��ۗ{Sk���,�����ѐp�-?���'QV}���1νɑpCv}/;ӱp:p�����=�҆���uB����׈|w^�ZV}ӌ�κ˶��{[^#���;v*a�#�GFv��	��w(�|<�B�̤�N35�ś�g~x��c(�6��@��(
aA��mf,�C�Vy��>ePs�!�k��"1d���O:���l	���l��E+O�fȴ<4}ɸɱp,
�����62O��~!]q�������Y�u�>B�^���f�'^_��o�L��oaْ��,��t�[bҒ�؎)|�2�⋗��]A4O����Kv�-2�ܽJ��)�d�"vҨl��*�'Gj~h,����2/(��oOK�|����)���r;���I��w�}C���8Nf"�'��
�MKì���a>�w\r�*�a�4��(.�Ï��|N�Q�����n�]R2�U�=�V��5�B*�4�o��e�]���j#ݔ������H�K���dP�;J���?��b<��i�+q	����\3�j���e�����<I$��E���#/�
��f�iVl�N���+�Wc�<DƜ�:��v�m�E�\\��OE���*�s~�Vp����Ҡhhq��SΒ��D�A�ai�fB�X��R��W1��%�����j��S�ѽ	�m��լ�^��uh�<���8��Ӫ�����U|���H��W0���{r�Y/�c�͝2hY"�yVb�T��Iv~x�T�B#=E�e�}����#�ȬBPBPR4�P�Dg�8��(�������[��Xձy����>H1��W�����a,��u���~�e��0�,��E��"�G�D`7�BL|"H��v!|7���m{��W���x���y_]4j3I��23�߁��)u� �*�T�T��ޛ���?��x�Gn��U~|�)�ϺﳌIL�����@����ɟ)+ww��.<�br���.z�#�Є;�W��w����)��"H��K���b�>��N.h�I������[w��¯_4c�E]�PA*6�Ta���R��=m�w�6���y��a��0�K%TF�lOn���5��LW��9�W4��у�G��,_ �7�rH�7r	Td� 7a���9�r�qU���ب���z��#�Q'��~F��������v������"��nR�@���Ƽ�Kv�V�é�U�^�M��4U7���?/ h�n^'_2����eQš�I�چ�R�Xx��XY�5rf%�@�P�E�<o ��8��ݖxܿ�K��p�OQ�MR���49���"��Vx3��a'���a%IM�J��{����Na�cl"(�V��T_��+V�U�S�?�U��Os�;#��������(�$��8Jm(;�f{��#D���)c��
oM�~���Z�����B���� V����2p�����&�Y��J���y� Ԩ!	���&>��xU���m�ϏѴ�҉���噠8E X�n�Ū@��q�'zd,
j�W+�&NI��=$�-Ϩ�x�`�H���+\ձ�E!�̞�
Wb8����J�%����v�I*�wN�:�^�
�b*3o��I��X�학����Nn�c����ц�$�e|=?Ư�p�a�d6B	&C8m�l!��'��{_�Qz�=j��i��5�������.e�?���³2(:^L�S�5||�1����ݝ���%��[�h���scO�)Tw1�l��)�2��؇���)Q�߯�mB��7H�dX����o���HF<��iUxD-]K�dkka5x�5ݞUQ�7G5��ȿ8�3��S*�o�k��[�Jc�y��2^n�:������yĨ0�4�~6jN:��њ�YLm�-���an�i�W�{;����E�9ak�&�:�g�Xs
�G�]�_?EʩY1��D?m]��͑0��V�p���ϊIR� 刮�UԜ�g.!�Av�����愐D⸖R�����z$�}���U@[o�gVE�l��Tu9�!~��]8B='�8j2��&��zֳ�	B�F6�x\��a/�{�Y(�����a�T�>�4����9��0DmDW�RB��$�DxDF[7�	����_"*�w�VK��nj�)���p�0�Z�1M�zHR	�q'�U��K��!��ʮ0���Ӓ����rXf��A���78�=�]I�ܨ��^D������	j�0?j����6�y�ܖ\H]�\s�y?�/#��g�����w�����,�~�4�hT�p�a���MGe�*f���'�����S�y���9ZbΨ*7��fVä�_x~A����J�E~X� ��4�d�Y��t��R>j�!o+�{���	�N·��.t�2�5Ao{xP��+9�[v�FL�����#�������ԟ�	*�lu�j��s�Wt��փ4�i䖈_�r ���N�W�ı����L������2���M˜N��N�g>��՛��p�_�~�C��Osq��Z���IؙLb@O�>�:���l	&<5�;!:���O2�M	]��)�X*g�� �-I?�~D�����Q��3C�u��t��j��''�{l��;�e��\ЀT��z�j(oK����}^'�Jԏ������vz���Ej�Q?����T�v�<�{ny�|��S����E�-x?3�hh�+�!�ɾ��K����e0�:ΖD�vqG�,]P	��Vif�3���q�� )];f:dAUr[�%.�o5���Zo��g]��4V%��A�WX�+���T��"���8.:���DD� �G�v�bջ~��
����<G��$eYe���C�U��>�7�,zhM��q�b�sD��p��`C ����a,��[-u�E��f�Q�G�.�b{�5&�e.҅�[�;�Ei�|:L����z�����>Z� �e/��<���X��I5�@���?��ʎ?�ؼd�̡WdI���t�Z^\��n�r{����;��J�k ]���(�e�举vͽI}z�8���S��1�Q�υ^����=��3<.�i~-�.糚X��Κ~�����qJ����X\;��`z(�>ʲsaIf$���l�is��ᚔ�8S�Z��������(EǂQ%e#Ơ�bK��	���G��*�#�o%-��3D)/Ѭɢĭ%jT��H{���L����;V�/�^�8~�2�:A�݁�ߴ<��L��Ӈ�;�+��}YL{��<L����6R��_Ln���w�G8$-wC�`�)"jт�u��q��k�^o�.m���5���/�f'M!����A������_��/�49��v)��7�,w'��b���z��Y0����7x4����4h�Jg�jHm�_��z���"y�ڥ̮�X�+���)/(��"	����ݜ�B*��1!3��M�h3���ͪ��M�$jQ-��Uz�b[cn#;p��@�"^Gj��xl`:�t�wxE ����pf���bk\�p���?�,O�3�dե��x�Az�ĺ1I�heuMM}�c]��p�*~�G��|�~���?����mM#�>Pɛ�����
U�bq۬��RH�t
'l�ҶG��ک�ek�]��n�g����Dl鶪^��E[5��\<C�RS��4u<1�vpinsV�f�������U� ��y!r}�++֏#��.�zTئ};>�Ƕ�B��lD�ˠ�= �` ـ���O�i��3���ʤ+���t�B��c��?k�������Q�obw��IԪ�����5dbچ���K��9�>o��q�
�^Ɋ��ҡa�{(sk��dd߳��JH�=�.N?&޺��P	�K�Te�Y4m��w��bM���*����A�R��5!>�	Cu��5S����[v����p2t�A�K�� �1q��9�LV�яq�Ta2�]�4�Fl?fB�.�$�>�;�U�cc�$��0����Y*v��u��Yw @����nY��o���ts~z3t�;#�W�}騟9
6�ŕ���˴�s&�)o���\HG+��O�rޜ�Dk��.��E;��PS�:W�[���w$R�E��N�k�|X��Ք�p؇#L���	o�u�)px;Ȣq�Z�E���QL����ak�x�OBe)4,��pL��Ǧ!#��b�,�j8�`Ű��5�J��޶���&̸RuͣT
�(���z�h�֟�a�:M�Us�뢷D\�7���������S�"�G�u Z6�,2B�9������=EN5&KC�Q3�s�7�z H  ��Q���� ����p2e��g�    YZ