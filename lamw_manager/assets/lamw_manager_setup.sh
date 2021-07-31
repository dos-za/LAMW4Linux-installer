#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3465215804"
MD5="34f3bb1870df97ea4ddcbb2e7c75dc2b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23320"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sat Jul 31 17:00:25 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D�`�'��	E�y�����a��yA�W����
�$U�I�A�C.�����dY:�Ȉ��P�������p{Ǝ\����-7� �Xہ�
��(�f�-o�	��(��׳��2���1��m����n�:�U0)�U�s:ws4�����pb�PY����? gT1��'�C#��e�������^r��/��h��@���МP��{����iۖ�|V��9c����d�C�l��:=��T�\���F߾_�M_���>�� e�p��P�<�C�K�a;���E���4G��X�1M 徵᥁3�	�dV��vp�pp������#P�V/8_�	�	�@����
R�מ�� 6��ov��h����^��&N�?��E3�����ز,�i��|�;Y��/���&��E�R���VF��	��FS=�����Z�$UH,��D���J���̑�;(r���+���X�}�ÚX�	{Ms���O -�(�1�c(�7{� ���^�+�U:-TqL_�!�'��7T�/t:��~�,�k�k~>�<���3������@�����0���b�S��D�r.p)1ԝb��ת
�r�����=P�עV�gm��g�U;�zP.z7xt	vǘ"�寧�VЇ��Rl6w���K
JP���5щ���Фj�96�i��W��o}J"_����W�n���Q� �k�6[K}�
^����v��_��Y�VFė͇�+Pk���wC�&��c�#��ZʳN�M)�ֱ9�-H34�#�ʌ��^� �[�
y��ExU�=Q1�8Q�h`JMp]��B�� �N'�]�Fu7�j��E��^b�}�H����	�Qz���ԗ�ڎ�� �+�m!s҆*Pv�DT��~�XdH���/�8���%k�� [HK���%hFޢ��3�ByI�U�}�k�t���O]6<��I/ �q�y�O}���Q� ���α���k9d����>m�m�*o�~� (���r�s��-�xxJ�ޟN�[&L)�§�&n�cӞ���`:�Iُd��6�`nL+ݴ�>��Bt�|aU��(���yT\��2,�^� �+ա���Āt}� ��8o?7�_v\s�I%|L;N�4��Zn?���NW�����/�%�^�|h���Qa@���/�|$Mg�`�E�U�fN���0��43�s%C�l�.}[O�`t^��[>�З��ʼ��Nx���V[
�Y7e�1[�4������gٖp�F�ɒq׽�{"���tEx	&��3(La"��ݿbw�����������o?p�� "r��s����kVMm�i�땄L�w���	�^Q�����7�y����sjP1�,i!�C?�j&z���b�vsլ<�]��e��z�a���"����=#%�5Vlo���'Ybw;�*� y�Lu&r�*�'y�C���S� S��7���YJ҉�D̼��� ~���p�m/�J��QD8��<�6��S�Lw�I��'Y{xq��ɶ���#[^�f�{�OQ;A'��cS��E0�_QD{rbn��i�eBrv���RT�����gͪ�vn�X�3(��F����݈Y�tiۆ߱��ܨ���0)���7bM����٪�!+U���!o+Մ�W��$��h06��{�q\x9j3�ie����[��ھ������'��2f+����o�b(k]��V�D��㜑�8���d��q�M�vR,��ȯ�0	t�V�H@`�{���GJ��|��AE%��C�O��*!nOڐ-�� S.��+��,�HW �d�D�<�h7M3N|Ң��L/���z�+��v�����7q��N��-� �u���c�A�����xZ�T�T͐�(~�dȐ��U�@��[���A���Ƌ��9��^�/�ʴv� ;����%�lG?p��Z�	��������Nj�C	ܑ�p�9Z��ZK�.8�4��M�be��J
^^�Ɣ��#����`bdy�' ���a�jɓ0� �w4�V�T�e]�A�+H�(�y���-�2�\ˣ��b(�If!ͫ��I+}���v��|��/�rgV�Y�v�[��WʣF\���gK*މ��16HH�ߌ���:���SB����R����]E�ө����f�֋J��pY(�p7����@Ҹ*9mgb�x�x�*�;����\)��Wi����;ѻ)ۇ�\N<��U�w�m9h9GI�|c�M�r��-ı�b��O����a�+�e�h3��	u�i׎��I�A:�1��-�B+��"�(�t�S0ܼCW@�Km<!��خfۤ��`<�>̦- ��f�6_����I�c�S?��c��ǖ�0�{�X��z���՝�;J�0z�N0R]�cl-
�J<�T
5 %��)�H�_�Y�{����G{5�[dsf�&�E�##��;uZ�� �! p7s�L>!Q�	�Y;(r�c?ſ�+QI�i��#+���ɳR��`kd�?���q��.la��LQ�=!rW�O��U|"R�9�Z/�%��)���YS�C̈́pb��������G�t� �o�g�S�#|���mӞﺠ��5����K9��CQ=�S���,���tS�vf���Nm��H3�c�,��5?^�|'� -�2�\�'/����Х��s�Ӓ��љ�V��M��{[�� �������|j�Ճ���F�c ��ϧ�����?���>!��R�����9)u����l!��{�ec/��{�I*2*&�nK��:�No�X������dԸ�y�.�&�ψRC��"�H �'&@�u@���|P�Z\����X��_(j�Q�V�n�IK
"F���v�n'�DK����w�c"��K��Ý��r򉾣��@T������7ge�Ok@!~,��� С����r�����uT%�����a6N/�]�?��s���rqw��0+�3��џ�h1��1cۏ��.SF!�3?��.��}-#�q���m����^�V��W��4����؝�ȝt^U2(ش��GX�~˼�{S@�v��aA�0|;��I��S1ɝSa�!�CV��T>���[�1>:�����%���p�󴞖���u`+���?@��`�2Q�6������O	��c�$�i�uk�ƠB�{�	:L"�_!�2^�5 C���O��D�.D|YW�X��Kx�a�������u�"J���ڐlP��w� ��X�(�UWBi�����X�t�37>�B�s�1I����7|rn�ܐ���,"W���絫���_�����y�� ƕ�����I�#O�(4YNm` ��#�uN.�p-�B:�H?��x��x��[�+&��yf��O2�++¸t�4�*�p��'�_��{�c{�� y*��G}[.�x�K���9H�:��P=�ݯ�?xݫu�ڤqZJ*K�`�R�'�T�� �U�=_ĬO������}s�����'̍�֦����@?��܌�ƩR���m��m�y<)Jr<��_���^:�R��DfC1�V8�k�L�8��_x�so)�{�%�=!n��%m�.�	��w�6,�|����ۈI9���AJ6�0�ac0�	��UӪU�Eβ�����(��v6�.�:�P�1�<N),b	�t�L����Jr ��dڍ��iKP.�<�ǁ9L����w����;w�22�^5�����)n��T�D���N�7	�M��дN;�+�@c��ݥ�ҟc�ǠZJ��+�q�I=�-!�rHX�v$ybĢ�A��� [ny��� U�����4vj2F%'i��ۣ�B�dH<�}ѯk� �|��ϩXt|��>�]
�X���������J�iFŊ��R=W��,��nWn�@��L]R��@����-}sb?:��T� �uO��iz�C[�5�  ��Wl<�(���2�����!Ɩe���,�(J�\�kIkl�|�xp<Q\̯�hE��@��������o�@?��;Enڦ뺋sA�f5����|���k���t���.��M��ْ����b�xξ?�QrygW'��N�TL��/b�F���8	<����)�'�`��Y�Uj��-.L���Ug�4�Oǹ�-NV'��P��P=&�ԑE�lcm��-�&�ۺoj;{�z������?�W��� ����hM_I����D�ώ~H�R�� {HkZu�1�FM%Ba4�6��g�N1Ӫ�i"L���!�;�V�eȚ�_��������v� 'zÎ�f8�ٌ���\�{��������r��tKek�\z$��~𥁹�A�����+�FK����T���g�%��1��׬�537v)�Gl�UU��8J궹h�=0��IR�C@��V"�W��7m0
DH�K���cH�f��m���e�g�z!c(DN�Euљ\0���'�)��7B!k�#��F��K^��"���8&����!�&k?����qG�	y���>�.;$��Pw7��Q̚ÝC��c
�����S�������������꿏�8�1^'TgA��z��"�a�$|���M$`��_�f�ueM^[���d��;^�~�6H��Ej\D8qI[��j�`)�Y��,�?�����4'�¹�J=(�Dy��y�eR�-�8W��u&�?�a�
��.j�OP�I|��+<��H� 9\9�;�ߑV��?�Tӿcݸ�+��� L�vUXٽV7�iL���f錃V���r���4�����.�V�',��[茫�iΏ��Ob@}T�Idf7�P���YF8O�,�g�`
t�zԱ�6v"�Z�@��W?�חHV%�K�-eEAKFw��:ؘ���Cޚ,����ʜ����]�P�V���3�U���v�����������Rih��En 3��G�S�F�a(��T!ν yhmQ?���	�+2F�B�gt8�L࿐\Ȋg9��}�S�E���Kݸ�<S��I�뱹��@�%�c	t��~�8��/=�R��� �M�������v���#�P�)~2��s�UJ�g��a������&���=ݻ�s�.�4�6dė��pŘl��{_=�]���E�ߐl l�+�Q�H(�k9A���\f^%�e��Ɏ(Q_��x�o��Tf$�P}؃�)�˙�����)�6W7r�x����G���X��g6�~a���|	@��dJ��K~@��pO�jb�y���^đ0�8/��Ѯ2���#�K�tdL@!"ifd�/�Бa����rO����y&���j+�܋�`f��7l���k$f�{pe����ȑ�D�aZE�+�4�F��\`���䲇����qz�'Z��h��ԑjO9js�.������5�^/{����i��a�8K��S��ID��Ap���� ����_����A+=��1�X�ޫbE �`���I8����m(�N�.*��=(���\�G����e٘�
�2���L�W���a}���3������	Y
~S��C�om�m����>5T������*��APb�в�M�n��Do�A���"��\� xA��]c�b��I���_����e���oMr�4�(3�D��%��>�O����>�X|�С:�!���||7?�+�EMn|�^�	�:x��d���Ha��t��n&��HR_Q�E'e��n��<3���8;�1�j��͕�p`�v���Ӂx��{[��l_U�?D^�4Z��յ7q���E�����&�g�G��h�AX�����,3࿦��I>i��v�m!/,��8~���I��]��5�(�nl}��� �N5�Y*�zb|HX�B��B�W<��8��:M�,��.׬�$)�oj�a<n?ʦx����@�K���|
��m�@�e��!BP�fWJ U$ ��;�=|�׊�Qţʆ��- 6�c�M��J��w�h�H�M?G&��A�J��A@�3WM���
����,^�۝}��x���C�����<Ȁ=&,�m�ҧ6P�S�4�է4�)�Aut`y	��E����XchM		(ψ��}���dD��X�N�S�AR)C���; ��´Spu�������o�n´�=�k�5�����/_:��Ō'ɤɪ�L�;i{����c&��SK-T�@���	;z���zۚ*���V֟�����{�s�
��4|��w�j�Ws;%1��|ٻ;����M��a�P�S֐�[�_i���'�X���m��kQ]{�
2��<�E�B�:���T����F6��@B��d���+��;���1��پQ�Le��Y���ݰ�V��� l<Ɛe+�ȹ������]JN���0~\���qY6b]�܏�m�e�4p��9!��3ǹH�\j��!�ǉ��R��0
�ȓ#�
�Yi6�j�ë ����آ�f�^�� ��9�����ɓ���%�~�����E��[P9��_xrBLa�y�1o��"q�4�)�����k��V�m�5����׼�V��;u��(m�!�h�a����y�S����p%�kI��8(ao��c�Rfmj|�3M���
�^$���`1(��M��T����z)��BmB�S@g�eǶ�W�E 
u*�SޖJ
s�G�hS/�^%"�}m���x���t��E2�9��y[����06/��*Єs�2�^1�̰z:
{iI[�G�{g�V4ǒ�+��u���w�,�bj���ѭ��j�_��ŏ0yP�[�0�p��=n�*BB�J%Tޏ&��x�����@�#��hͣ8��_o�+�����+f{I���zJ]�<0��C�?s�;�?�(2�l��2�A�y9��L� [�0�]g���O�/斣�8�L�(�i7,�ƫ�(XI:�_���3�>�E�Pʫp}�h�Fk���f�������ض���/%���e�T��`P�n�(u����-	Ì�m$��}����|���M��j��՟sD�U����&�Yl!�O�#V���I�\3��ioh��<d�mk:�4���sSKp<�FL�?IT@(0�0�"w��O�H�_b�I��<?p��4�X	=hخm�=;����I[�afqIp4S�ש�St�y��EC���,�G"�'�"MxZ44�������m���?��+��El��h�ʐ}Ep���W_m�"|� L����"�c�f���M��`}u[�o.�~�D@3V��l1�1��@���O�f���d�[h�DuQ� �Ã~J�^��u�6D��5��&��k.�!\~Y�\�Ya��&�:�[�a�䭻��ƃ:uY41�+�V��9M'� �H�_G!e�������Ven�l�b4�?-��Z-L'��<�;D"��&���t���ni�^,�*�لI{�ڿ8���)��!�]C�tMr��W�җ=F�$�ՠ��2��DX�Gk�R��t-Ж��B�����pUY%O�C�G"�ܲ�=�s9�ӗ�Һ֙Y͋�������������}�0��)O�}B>S�VDV�������pq��m�Y��Qꌕ}�X���
#}��k?�.��E������(�	��?4|����¦��L-�q���@~w��AcxB����Yc��2�D��"qu����vQB
S���`U	_X�FC��AC2��E�"x�� �&!_[rO֝^��>Xl��ۑ�|V�_5�V=D�����]>����d�i���	R�1�qWjt3;�s�dl4��b�$8F�F�)2���L�.�\�r17�+Y�OM��!���3��0�`�N��TO�qN��Lb����ͣ.O<����4#@�H���!�	PJL���X��1`�7���\��{�u��t@޶�vgw pY���WnnA9��|ZU�r�hJ��;'"+��qa�7׊��)���6�#R�B�D�Ч=�����/϶��1�.�N�(��}���������L������*�NC:E0�k)G�`ݸ� �uS����k�ר���0�@���2��0?�_cz�w�F8;0�����w�j��v�s�Z�n�Y�$��`�WxBk��3��5$�����k�$
b��o�pM�jэoBKI;�6O��cv�ד*��9c����*�m�.��ߢ��+��Lj3V�^������6qj��b}�>-�a<�=��:��F*���g�X?����2��3%LT��nW� ��1��p8v����������*��1�K-S����up���U�'����a惒�49�M!����jpT����,2h�{ȯ9�]a	�}#bJ��i����Y�GzWnR��gyK#�S ��2�Q���F�܃�j���׈�Ȅ���Z�JAi�6!��1�	�w�_���^#�w���iDt��ÐL�X��r�?�dMLPF�t��<�+��Ai:�7L�^�DL�+���l.�΄T�8�L��F�Ց�CX���*����Z���{����t��N�J3L�Q:5i6�Xs�2�(s: ��®���L��;�֌ǍK��lJ�M`ݑیc�� w��6i���/k)0������ى������6�ץ
B�2�n�@߳�D�_�+ٔ���� �y�4?�~:>�義�� ]�'>�@�b��#V���+d���������bqp����JMl(~В\����n�܋��?�[.�[A�mN�Ӏ^�gUF�ڰg���v,�;�Jy�Yn�l-�F�P�8I�p�����Ö=r�aDh:ˌ�2n��9H9��NGݚ�_�8Z��V��T�3�����H����+[���X������=ŷ-.7h��}l#��W���qf��U�]c��3��'r������0��.٪��C6�#�\q�>���.�ܥt�h�kk9�����#����g?����fs�w(y��4�h���+�i0
��p	���U��݂�H�*d㈊����3yPvݳ-�rǊؿ�������M5��j0��C�8����nH���Ќ�KU�ݵ�5����f �� �Y�eoR����iZ�K/������6�!������+Ue�)�\�-���!V�))>���SA�"T%_���M���$�OW���^�������<�)�4�w��+5���]o/<�,����H��]S�?b�B�#�'��\ � �()���8��Dy���["�*���ȶn;.	r?����)��L"t\/9��T	�g�p��-RLN���s�u�
�Xs�i!�g�uo8��lW{�'��H�(���9G��u��TG{�r��xa`{&k�h�y�k���`�k������9�&r��D〧`�jQGD��p9�d&��b/a &�.HϠ[�y��`��p�Z�5���ʩ��P���<�����-�Y-��X�@��d�H?xg�:��tn MkIˑ���q����q��Ɏ.p:����|��b��,�-�qmу%	 O�3C���Ϻ��%6���6�J�K���6ʼ.�5!�����@2+!�T�>I�?P���zT��xsc�%��t aՎW�s��Y��=D¤m�1'x���.D����`-��3��6��ӚŏEb��F��.���+F:��S}F�ġ�[7�s�����Kb��tJ���#��x��AK{�m)�?� �N�}��m�k>*E��xPA���.�i��`b�Ț��8��L�$�~pӼ^r��ٽ$8��!5�7�_:���%�[����1���5 k�L��]=���ȡD��;�����e���\�a|�z�OrV����-J۴hZ�s,"�W8���ԦqPhw!�ԩ�W?��o��"2���,�,���f�*�A��ệ����(�=���mt�G�~eW���	� �TD��X	qUu��5�h��Β/(�3j�y��Tc�S��h�� `s��D��:�:ε
]]������qj�������X?�:���2��$��+��#QƁ7����ρf�ܛNMt�;N�h7l?LeOa��HaRz�����ݩm����3qB+��Kݥ�ΝO��.Q$N��Ot��?(k1�2��h�>�~�C�7�Z���6\. �(E]����p3��` Z�(&�������Rb>�����"�v:��������P#v�f~�������&�O)2&%���3�1�������w�*��s��j���@��{��Yc
;a��LDg\O6.�Ε�X��%,��(	S�d���:���ԬD�Leܒ�����|����a��`?�XP$����;5gF;�Th�M�-B�p�? }���^ Z!� �f3`�)��%��!�U��(� �S$\���k����J�k���=�c�b&#��I�� ��e����i��pF�]
��@��l��tE��8����6r�KM���߈0�zS��� ~��a��%z=�ӉH@�6k��ޕ%�>ی��L��>C�H{I���t*�O�%��H�r=���A ׄ{�ˉ����Lk��G�r�w�9���I�SԫR���D#[�c��'[��u�����?=_����p~�՟T��"��18����ڃ2V��zԳ�3̃�E@���`�'m�/N�"��L�T�Lwe���^�C���*������ܣ��h�ѩ�r���!u m�q~"�U����
O�����FK[�M��nb�πF�����w2�)�s}*���l�n\�3�+�NF�>�s�¢9���t��L	坜��ɸ'�l-9%F큠��,���	{��[�M�g�Wm�H9�?'����Xچ!��A�,vT.��ה@��{T���Q Z��0�փ�3����ix���pnz�gC�H���-W�x//ƫz1/Y:2Qs+q�F��utٵ[����s��w��?���Q|15g`c�U����w�K����!D��<\�Fd�	��!ܮ-lp�PD���8n��ׄ6��kK���i���t�om��Q��dc�	ʴ����s� ��M�i�t�'m�"��O�E�53�n�	B��<�ώ�usar�v�M��*�ج�,��"�%tU�a�+a^z�=M*�=OQ�}$��_�s$�'q'E4e��������a�(Mg�҃/���W��ᝇ?�[L*=���s{��I�n������{φp�,���z�itBs��k��YM巪#��`�[p�zt��A�j�l�m��xؼ��K��;Q�C�tO��i.b~�
lQX��74��ġ�ͼ���~�N8QYO�-�ԐA��a-u������j-/�٪��F7a_���V���4��$�b:�i�y`3��g�'O{���ro�e��T.O�pg�f��a�Ŀy�H~1߀��C�VuR@�5Q�X�]��f�
��:��:٦KϢ-�<��5��$eTS�JX�.���5u���>85��&D�A�Ŧ��jxRJ�-}"D��c�8C�Q�ξc�̆�ʟ;�Z/`���U "i!�T��ϻ>YJ���;h4�+���_����xZBG��[J<`>��n�~�+�������j�.�Ø6�e ix(�r虖7>5��J���#�Db
tf�M��-�	��㶲�nY>L�AD�<���DcS�ɞNq����tJMmi��\�����%bO�����W��J���=b��6o�O�Su�o��!ݥ(���^���:sp����srC����eg[^�mj�a���\�XH=P- �!^�O���2�[ε�nz�+p�d@U$�f��U,?X���\�q־Jy�*�2;��Ly����}�Ԙ�vM�^���y��^�n
�;	�>P#:Qp2��4Iu�t(|OH5A��z"e���mF��+�O�0p��~��OW�~?�)I��?� �@`@��珤�r�S�a<�N0QT	����>��fVs��b��4���9��$�Ŀ��PYDOl����,�s�Q��+�(��w�{0	���.�\��BFyZ�Rl�=��'��f�L�J�r��~����h�hQ��UTT���4�+�/:(v�@���ӭC����,!���!���ʦN1n�O�5��b���l]J}��'���_n�+or ���1���a���':)v��>nb�� {s��xIS�}��4���Jd�T�s0�z�y�mYWL$��,�� v�[Q�"��}�	������-���hN�b����P��UR�[-k�/�O����6��T���S|����a���Y6�������`�^o��G-^Wh'�Ti�*�kK
�P'q/�^ۃ�c('C���?�1;=�~�g�*�A��!���A�� �-M$*3�����ֹ�eYg��a;�j��w3[A�;�C��b��RD�	��`z)۷� X�.�ej��L�m;��.����(
s8GkpĚ�ѳ:�X�$kg)f�;F�W#��C���)��W� �|�hj�����~V�]A����Pe����{�-ؾ�'���9>�NT��3�I?��2��bn�M�� �!��@6�z�����M���e��*��t�)fsm�`�������5V,�F��ɟ�����L�V��7�]��w�h><au��j��=��h҄�/ͷ�ز�~[�nu�vh�5�� ;�v��VD,	��r2�o8��o��b�L�:f�q��#�u7�;��g��1�ܕ�'o��y�lތ�p�+V�HA>���!۫;�2SBMκa^i��P�bYd�R7@�H� �Ң8)�~'Mc����Ʊ,H�z�f	�[ �g�$^g�4��dOS� ��)Z���"�{��"�%�k�����(AK�f7G�d �U����Bj��k������24�$wW��##+@�y_m�ᯠ��t�/�F�r������z�Q!܍R<}����L�h/G�����w�(�������d,��3�U(�YWX��eCp+,�k�T�u�6��G̍�yK KL�N�F���0&2�,�$�%�1�Y��\D�{�*���=��D���Y��)��*�k�K6
)�t�c:�A#90\[��I� ��*4\:ܪ )Qo����R�Sj�|��������H�@��@�J�����ltI��g�O���e��%��L��".([_MB��������tR���z[��wBC~9�B@�9�����/�[cN-?�y���	^\\2��5�=��t=�K R�"�dÙ5y9�y�JkM4I ��$ew��L|��C���HR!v�"n �`J�,{T�u���V����Qg1b���S~�8�a&R�%�`W����ۑ�(�\����Ob�$,�[;޽�-_����&5,=ޫ\q1��!4
�=�ӀP��i�9�����E�v�`2����L�*����]z��/R�ɘS{���A�fB�-�̻�i�o��ӊ��KN�,���o�h��5�$(O�,W�_�$E�̱� H0p\? ��ь�r���G�GƲq��m��vܳ�2�CUgp��0�@iOyfx���:����2���e6��;,u	q0mx��pڴZn��}�zٶ�BZ�/c�=tvm�������s>���]k�U�>�K% u�����z�M�zt�2p�[�1PN�Bf�<V!�۠�r��fw��`�����9���E�/ ��/����U#���>*�m�l�������@�*E���"�RA���7N�le��td���Y�tb�l��גc�KݳZ�,��� YY>lb_���b�њ:s]�T��.�4y�&�"kʞU{�>>w9N�� 0|� uOi��QY��dw��bG�͈���@Z��Փ6�@1�KW���6EC�O��?^�?�)��[�0}�j�K�MQw%q:�"���dJ��c߭�&J9�*��w�������N}������S ��f�>���爽��u/!\��$t��O�Y��0؇³��P�nB�p��ǌ�m��?���s&���-:!��KC�Zp|	�x1�m��b����N?qgԭW���N�Q;��v��J�]�Z��
X6�g���h3To���o��y�@d8��E���������y����К��)(��	2�g<��q팾QO��:�R����s�ԤT���Z��Jhv���'.@������U	Е���K��bqo��u�,Rgh�ѕ�"��m
��"TJ0�4�����)��������2��y���0</�Z�s x��Z��z����icf����A�CR�����I��<8Z�z�0���������]lJ�.��9@*����ט�%Ҙ�S��Fa�E$�<x�I�e/>p04��K����e�r?S�]Ƣۘ��w@$�0Y�)簼��������E��K���3��w{�)MeE9��v��G�F�O��I�=k��1���S���s�f����z#�����;9d�˫�_��k�d]��#�?����5٬�}�(�^W$���R�o�{�g����F�9�#e�!��}���|��{Z��v��09�I�pg˴���6L�%t��H~	'O<S��>��<�y�09������N�������1�Ҏ ����̭�/)M�/#@��m�~��`Gf���I�R�%�`�N��T�ߝ�5_�d�4���z���}������$Xs�-d]��w��H�5�i��|#K/��@VG��4���~	�M�GS�j����ѯ>�``�o�Sj�y+S�,�1��d}�`�M����'{�^u�4]��TD{{�Y�y%de��eh�|��F,V����"A������贶�mg��ue��Z�xܡs���5?�;���V������9e��9�y߹����.-�BV� �0�D!�����h]�AYY�U`Y�������}���L��y$��%���@�7�ig�ÇmٞsG����$nKϧ�Bd9g�{���b�"�T&���>��\׶Y�ʡ
�p::��L��9+tM!�󿛩�?�\��9�P 1~��·�S���!�z����B����av�����y-}�M���
�U�ôW�c�
~i��-T}�|3)�7�Zvر��|2_��:G�.TC�BC���F�rR5S4l�O��[y��C�H6[^��J�hgǰ��]�.%/3�'$�YP�u\��f��q��y��5b��G�~�=���	� �*�vK�j�Y��E�g}���/l loN-�4��4��#(O����+~���%�4�����6�x�R�:򗊽Qލ~~"�b����f��{D8�	�ӔӪ�ֿ�����4�'$��%�%�:e/�p�?�T@�L�\5�,30e����5��?�7� a�C�ZB	#&���v�n;�O�'��!�j7��6������ت��Ft&��͸#9������m�G�V�Hx�l	GNC��S��ρ%^���V���%�t9=-'��"^���P_���l�x�1���bJ��7�&p��\��-�MC7�_��
�۔�{(a!=��7��y�3 ⧌���R���S���&�H�缁�f�����A�%��7���#�Ui¥3";�x@�^��i<5;�76m̵�g����F!!�Oe6JB��נm�a�N]��h�>�D��� �"�����]���-�4�'|�;q��?��H���;��d+��*����V�v����1��ԡ.��B����������j��!PfI��l�Č<��3��(���9����U�<̢k$]#�+�2��#�&���vhu<s_n|��g�)��-�t�������֟ʂG_e��U[y���e��*�
��E��L�`��߂�F���r�\\޾�RܠI2��DwlS�$:�=}�-����pYK�G��������<���r�/D����?7�V���v���v@���U$¤��	�I[�Z|jWd���)M����aиT�'�Z|L��uT&�G������/���bw�/�c���ˎ"H�T���&9(��^j�&ʮȭ������V�0W~���*"�����e�S�H���K���]����b]�ĉQ���"�2+��3�=����Q�?|=ex8'��6�+#���[lp8�e�~yeq��K���n��\�
S:�e�# �� h��;��E��Y����_�p���w������M�F�,�%�L�i���>�'H]�W��M|�7�Q�����4i��1�!�;DP-Z?��F����m+�Y���G�d�9g0��ks��4CM,Wh�ᝣ�,��ʡ�+����@���Ӭ})���ޛ��N���D���X4rN�K���Z����ر�&ֿ�ޒDn:,j������}'ގ�'Y"�,8G�g�ęfp�]D���cN['}z$/�d�imrE�OY���q�i! �r���>�w�l�G�s�y�9qفj0I�bm���,�\3�+Br=MS��Z(����gTn�nf`r̶q��-ٶQa5u8�K�!7�> 7$T��>�N��F8�Q�Z)(�|�Cn��c(�&��鴪���l~�o��պ(��q�ɒ�K�$�Z���M�&�����'���=�쓷��r�1���e�N���1Ӱ7��hm�Q&0�A�qQrn�,��h	��.�iBfmPay�cË0��T>^��w�|����-��m�Y���/���>���S����ؘ+���j�:��7�2�֧��.������x�1��r���5�T���H)�l*���� @<������(���FAb���ց	?~\�|h��y�1��VVD2߯�H4�rj����p{I�x�\|�b|��J�fbx��dc�j�HN#g�o����Td���g�,n���5�s�J*��p*�
��H��y�:Rk��tJ�!��S�h�[BY$ˆ7-��
ظ�Rt��QM
A��Q�S#�}4�(�H�].��L&x�Nסl�͔ ���((��<�otb�
}�q��F�ok��ԓS��F�{d�t��eK�XƳ�U��v|�<e���@?�u�Ѱ���̅�f}d�Q
`fѮ�{ޚa�pb
�xn�o0��N��J���Q*�˦�#���*
j�	j���h��b���x�d��E.Aݲ�u�hu���ht��j�U�q[Io���
AT&j�ϐc�u�B�
��������`����ؐ�⩞1�&�]t��	Cs��l�*ҋ�#j���#|5n��yD�k!���:����;�{Ϸ����O}�X����s�G.�D�쁮ed�E���&w+��&�l�_�lG	�lnuP]֝E0kMD�� Ϳ��a�2[���8����&�('.� ,�z�,6Ut+�{k�$'������<)1q��vpU���W�P���l�*�*KgC�F�Z�70� s�zJ{��.��ā����Si��˫>���ո��/�±�R��G���gTX�	�O�vB�b���>}����Mĭ%�4�{N���n���c֞	����(%J
(��sl�1��Ԉ}���N��z:6���_�b�c�!GW �<�	Q��D�^�?H�.~'�dŵQ���%Y��P�*,���I�q�?��m1zҫ-����3�:�>��{HO΋��cɦ��H��ay�+@��Ǥn���藅�&��jkM�\�'LZ2�`�r�ۀ8+��X�h����֪�y4d�-o4�W�]�(�X���r�	�N`�U]����y��E���$��	S0���x��yt��is,5��$u����[��|V�D��_>˵	"�R������"�����1|�E��:"� B#*��e)<�ɿ�xh	�Ȏ�0۴� �ie�D��Ƨs}q)���LBN&SŽ����dx�%m�/],l*�u���E~J���O��M⡰������!0���ߜ:��a��ׇ�4A��wD�R���c!�	��T߹��60��+�r�Пc%�_(�I��f;����2k���3�ݍC{cC]5������D�\ԩ����D5J����	j�gS�n[b\&�.G����[+�A<{a:̜0�t�q
/�3�b�,��g��K�@�Ttn�Q�A�ct�����
��˛%�`63���jdޠ�j:2-�5��b�mO�5����
VL`��H給[��T,�Ӈf��Nۭ��#�����k���ڇ:�I_l��pX}ad��w#��!�o^nZt����^֋ˇ�C���ٴ��6HaŒ��d�#S6�dΓ�,\�~�����H����ژm������Jsfq�KA*��A�Pu�I�Ȟ�V|�������Ŵ46t�<�C:�Z|��2�*;��*����޲�%!��ó�ˈҲ�b�wm�H��d�O��>d�K���	���ٕ��[]�v��Bp2 F@L���gsfr=+l���:�>0�M�!R�.�d�:n�O(y$���m?X��`Z�"~wq<�o�>�I�9�كx����G&��Yq���j ʇx��p��3���(������_]i8G��l3h�(�x�y^j!U�kU�[Q#�S��˸�2۸���^��АD�zP�QDłȐ�@����u�W9���ϊ�ja�f�=#O3,��$d��S!�ᧈK �Q8O�X~R`��?���v�ۤ4!�%Qo��t�r~���<^Oy���?I<���[�Rd�����P����.�!�]�A���IP'o�F@aT�T`We��.��ri���Q^A�`5�\5�V/��HS9����	DEҾ��|?�����u����D�ȕ\��64�6#E���\>�U�F�)�����I�'B�+�A�p�L�/e�'<�����U(�n�K�O�lR�P�(��;U2i��R�q�h��<y��%���C�Z�ń�-d��$�����&����)�z+�I>�ID�{j�>�n(}��	~��m� ��M'0
����w��t/�:?��Z��/��Ȩ�Q��g������e���tt�wc��I��o:�%���X�T���o�&(I��2�?�;M��x[R��Ԫ{�@u�`�?[V?�[̡�RNtn�\�6=�H�����R���秔~ �W����럖z.�i�]�z�p�r�1�31 ��7���J���D��7�Z1�:e�|4�H�p���xG��un���y�t.։3{��W�v_}�G����9(Ny�B3��M٥@\�a�=��l���MA��*`��}���T1Z�k~xX�N�`0ߣ�ui���`�7��Ot�a;�?*�)�,w�J
��'��l3�I���΍AN�٣%>��$������@�6yG��Ns.C;�/C��UӒ[ҀZ:�}�xp��aT�'��:-����K�����¯��m�):Q�,�}�]ˊ���+���JE�l`�[���{�/I��pF��']ݏ�W�F����z՞�������M��^��T�ٝkl�!��t�����ڷ�ݧ�,Zs�u���ܱt�J����5/Ȃ�dS֋��wO?�Ǝ��D"GI�_t� E�e{��E�^��u�������c�s������\������"vK�~^��E���P�g!��� ���Ӈ�$��Q�������eA%]����q�M��=��8����.����M�WȲ���1d�F�I8va&m��bm|��e�SM�kl��|1�X�D�fE4�N�Ƅ{ttSN�!Sh�VL����2u �^ӏ��c
�y�\��I)	09$�M+R���V$,���v<�yj����<�&I:v���Nc��G��g�~$Qf:m/E��~����ΑZ�@ �nT)����nYw��x�%mo�t��s�b2��S�^u�C�;Q�^��C�]U��P�贤jsg�ܘ%^c��Q�;�����G�
���2�3�K�B�^%?if���@���ᛦST��K�	14��Rox{I���^��[U^ ��Gb�+���/.N�vh>0��\w�:�b���@�XbZK��;
��;�xio��
k�h�w*��z�{s��,���-
���`��O��3�ן�U,k�U��p�@ʘ�i?�r��Z�չ�C���޵�?|*S	ڮI3#L_��A⵵�D���I_��)C�{�I��(�@�,��j�^_�bu?��6tWH̜Z՝���?w?�,�C�$֜�����f����/у��ݱ��������=8�yל�*E��Ý�<9�sW���(���M�'Y��Euf��3h���L���K{=5�;\BtA.+l�'��ZQ�ً�+�4$|d>m�דs�0����ѡ��*؝�,8?|�7*�s$���͑Ci9]`���|�s-�`B�:�N���e��q��Н+0���)�~r't[R�n��G�-W

Q���5�:���+�k%�vϏ�t0��j3zM춢��hg�ˬ�x�]q�F�)}�<\t���x��p�lGX���L?��;��Eɕ�ϐ0"�x�&�(N̢��(��c;H�s�l�|��Bܩ�2��s����������R�DQy�4#�	�Zi�}Ty� �!ts�l�{~A����Rs��?��˅�}$̉4WaQNz�.k4���*�j0��e������=:1��)s��ؒ�����L\������"�4%�S�A�Ɏ�6�e��;{A9).T�q]^~)6U�+,��kn�d�����V���Y{��-�1S�ER!�{�'R�0R����V�%�=��b�0�(���]$d�x��>�tq ś�u���l���B�l�O�dLS��n�a��/�,�d��O�IkNS��<`N
r�8[�=����(cw��92goK�����i"kr�*-Im��?0d�C��tW�����3��ߚO[�~(GmG vsG�Q3hE����r/�����z���sƱD@�J|��AT$��SP�z��%_:�>k2s�p��֘�O�\�����7���W�����ng��#�c�39�)�����c����Ђ �ޣ���R�&��w1�Ft5��f����[�Vz���8�������[�Q$4����*�5D���G�QZ|������w-��k�v�?�H<"��r�`, �Ԭ� ^�s����i�S�W�0̾h�`�����zW�oӍey�Za�&���lGEC��otO7���&��q���_
MS]�v�a0Zr]�' A�����mhL�ǡ�2)^a�S�2�M��O\��v�Sp���O�����/ON��M��������\�Xu1�Ɠ���<K�x|�F���y�cJ� �?Z��v�r0�ѱL8%P������ݤ4�IƷ�Y� �$#���;�#Q<��Ua���� �R�W�le:����� 6�S	8����_�ٳ�6�B���<����������z�گ
�˟eM{)^>����T����-&]�8���A� ?K>�$r�� ����_���K�jKǋl��Y���F�ɠO��&�\/2�AkTd2�s�S�ԍb2u�\���������e���8*r��!����E2�^�VM��[]^�a�tX�	u~P1�be�����U�>`�L�B�"�I����c�b 7�e�&\��}�-�_NIv������"�K���\K1�Q�\	�y�i�&ӿ��$��m7�L1���!ö����5�D��\舝���Z ����������Nҙ�8u6���Q	����
w�)�@�]6�1V�e"�fօ@�LcD-M���U��ݟ�iѕ�p%V�w��7�W�ꀃ��6fϜ<*�r�i��"@R'�ga�M[K�+��SõZ?ִ�zWh�Ja��.5�����R���Z*�����MG�ǃ�G,�����]Y�d�uu�u��o�[*��,��g?�S�,��#X�ϔ�7�8*9?p��2��FX���o���[��l>Y���Km���Fj�F�|rk�さ�rD��8"���$�p�������Ҩ���d�3uAhh (L�:|����̱O�C�%4g#R�o�ȏ���W��X`��$�Ѧ�P�p�x���iE�ehR`���%���ӀN|L������b)�%~�jQ]%�y���D����ď�]��%���4����\_i�J��LU�4$�(ߔD"���˳,Y�O���숄���@���>��g[�ћ�G��B����f��N-Y\VaZ�fx4�0i���B�Y 	
K�+~O����d��q��eN+�uq��5��l\��D�|xB�3���yd���D��?���p��:�2vw�7�kݱ�Z\�c�i�d<��	�s4�2��Ͳ�[1�v���?��4�'?('[o��S�����,��\��si(�E�n��1ZI��rV�۞�����(��+�#�	�'�fi���ha-G�;x֞�r2fr��M:6 W�Hs qM�鏏��ADBl(�:��]zF���C�'3�.Adfs��d�� x5k�j��gy�|D�l'���˱�ܕ�r��	ôG��6��S^}ߓ�L�)��ہ��\>���?4ɑ�����Zg��F!�X� |��4[��]bNgT�bw1��a�Ho
N m�S�-�n�c�h�����i���&�QN� ��!��\��]��KXc	 ��%`��-b�y����=�g�����Vğ���S�5��Rz�D.�G�:�_�d>�����A��+*��%ϔd�h�ms����X �P�z�wMW�sl�k�N����Yq��@8ƅ͆Dx��VP&Z��i���e�@�m|,�^d(�
໲=�e�=�]����l�5l ��04�K���
�ȳ�e�q:~ŉ���˧/A�m�um�@,l՘b�"7&�2?��
�A ���?�jN>���p�����}ؽ�qb��߮��P��?����� ��g��x
3���� '�;*�}`H��谕�*J��QM�9GTڡ�Q�ࡼ��s���/�����׹�b���g$� �fMjy���=p�")���t�:�2�Ϟ>c	�,��mK[���qe�^�͗�V.�/tX?M��.;j\��-�r�t����&*!�BԱd��ޞ{�	�0}�`k/A�V�?yv�     k���5e �����ɱ�g�    YZ