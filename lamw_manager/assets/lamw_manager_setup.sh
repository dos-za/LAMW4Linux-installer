#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3069260278"
MD5="30a4f18d59cf498a53e847c524e8ab28"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26356"
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
	echo Date of packaging: Thu Feb 10 18:34:18 -03 2022
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
�7zXZ  �ִF !   �X���f�] �}��1Dd]����P�t�D��f0��XP��7�:	`"p�V^@x��f��Mw9��W9�Uw�g�{��y!�Y�n����vH�7����VU��i��[%J�R�ݨ�6/��R�:6��6G׿���A���pD�!y���o����#'��N����ݾ+2fsj���?��'��ZPv�	�T�w~�s���?���)L�G�K/w��PW6�Rl���O#�V�@Ԯ�ĺ{M�$�C>��`香d.�C3��X��o`�X�g����Ō����x�w�z�Ic�D ��`2�n=6��7O�.��� ,�p��# ؿ�	%Ih��ޜ���9s&d���M��9s���!+��i(9G��k�yEg�m��B+w�1�-$�ṦSr�ZI*_�ǁy;�7Y� +]k}̳�c����?3�N��>�%o��Ã&�pz(7��۴ʔgE�m�;F�Y�n���T��YК�$�s�h�:�+�yѧ��S
H!u_��⑅�r'�|�yъ��h�V�B������(���sÈ���T]��d���-���Vz�F�H��U��۫d/6�C��������1�~>!���Fd��ދ{b1�&�����t�E��@'s�+�3�Ͼ�$�>3��8��+CX[<��.e�W����?�?̯&ٹ,'��+�4�a�|5��נ7����U�:a]�Bb����`~�=QN���T]�|GP�����\;ª�g�)v!-B:Cc����h*��~��a��q*���Տ^}��(q~�����"Z�M�l�_
'<�_�A�T��E�wS��Q��f*d��2=�O�
�}j����M��x�K������X����İ�>�,yd6���m��׊B��T�X�������Ar���5؍��?-TӍ'�}����L{o�Gr�$#x��g���?��ibMۓ$/���I6j���A[{�އ��meq�`'��]��pmb�i��v8朐�Wp����?jo>�H�ɵ�Wp~V=�O�w=�^��)Þ�þ�á
�kG�C�N�eu�!��`	� �� <2���#0��uP��}��Ρ�=Qζ�r��4����dg�c6�Q��/��&�;��gY���@��L���z·��>�V&�v[iIfe�df��K@.���˥4��s�5����^댎]o��~x�  31�����rD	���?=e�Z�%�Р�����^��H�M��(��?�ϳk�>�<֗��H�h0��D��������#�(��7O�����C��,S�7s��d�+?#���|W���Od�(kK�����Zγar����+��z�9�	�I�C݇G�ɘߜ�[���[�0�D��k�9��ؖ�b`�N��B������KJ%���ga��?2L����"���'~�P���5 ���][(�B_@8���}����(Y�mm�����!)����O��d�bI.�5��Xk�Ն!�d6�޻���꿿�'��4D�8Q~��p]7R���i��@r!�n*UL{��G�M�=m�Y��0���f@6_{�;�uQw�;AN���I�VA�M��7(d��z�2��k�FX*�a�����N�gO�Z�7���sU;x'*�,2��1��uLbAw�:]J@O[*t��f�#�
1P���wN)�5߯c��0�6rH��"LcC�6�N�u�[���jAUh�k�>�2y<��S��pL��о��+��U�H܁/�3W���j-Zt���5S���{2�F[�q_��:�TU�^<j���fbѕ�T �*s�JV�ݮ��ഒ��]��^[��Aߨ�Ypqa���U�g̷�s2�m��)(0ܰu��E����HhB�J߃r�:���s/j����D�gֺ1ghF䚵_�U�(���H1�s��=�A6��^��:��=�Kr#F)�����d��fC�L��p�5W��.5BHw����y?�PP9�9�^r�m��%}���Q�9heoĐ@�G���ϱ��p]wn~H�/7n�{MOa�N�a#�ص_,!#�"s^�s�M�v�ɽ	)��f���a��,�m�W�f���Գ/�+`IZTrL[(d���"�JŘ�q�e��j��$���m6�R��t�Gy31�X���%��r�hlk 
�I��r$��g���]qrXR11��:#m��L���/3Oj�e���'NT+��&��~�m%�&���0� ?�;��=��b�B;	u��Ҫw��w�P[gj������ �؞�����Υ��w��9��s��*t�g��� ��"q���xړD��z!c :�x�0P�W�*��n��Z��`H9��G22���C�5֎|	�m�\�x� ���e�Ҥc)�RufÅ��Eg�:���F���v-N�Z���[��;F��1*6�Oa��JX�7��F"�Q ��<��Y��(�Li/~�� R��(�7�]`l�<n�5wW�-=<�n��a������?�m#��ɓ�ɖ��n�h�(�`��E��Z����)w��L���l�xP��٧Fw:ky�R�u;��w{�i���Y����kA+��2x��� ~��\��
����?� �,�?���z�K���j�ϯ�g ��2��c�d��P�Ț��[�5��xE�oOg�GT}}�s�>�h���C�3���eHg����y�H,҅/��(���Y�Ha�#d�{���i����{�*�|��(�l�3V�ׁk���fC��?�1�}�������������/���� dV=5��VLK���� t��b�{]�M�빍R�C����UçV�5��_V`p��B&镜�(����~�6?o��ў����eFvA��άu���ekX��qú��Ps7Nh��c��`�#ؼb_8��o��5&�:B��i.KG&XL���O��o�t�=���˅	�fF��7q�j����"���Bw��W9��s~�W��'2`Q2�1�ɳ���oO��#�{��B���YtF�uص��B�sZ��pY�P��cr����X�����h@�6fp ��k��aVnDkÔ�b�2M�+��K`w�5u ���O$�ڝMs�ʢ*<:�� Iv��ܮ+��-{�G��L�"���՟��x�_6~�8{L0UGr��~�(��|���ΧF�ƛN���������:��C2�z�(y18����gVs��]�&��<n���<�N$�ݾ�\������sfr^�>�Z��aT@�7��!�!y�����ܤ�V/�S���M��a�&� ��D����ET�`":���Q��m�9j�0hz(�jw����%��e�F#CTwf�R��VHA��F��y~�,�a-����:����-�QHB�+-W��� �#ߴ
�t�<]�Q�n�Z`B�QX���虇kwMD�:��U2o�:����H��u����^8���~m;��U+�Z���2�n���BoJ��R*����&�X�����*bd�P����_Y�����\��IE���94�u�Ɍ��~Ci�-�:M�8I=�ck�=�]�����k,
��!wz"�歄�����0;:a� �l~�C?1��E�>�K!�ښ�'���� i�|��a��ި�����̓4Sz��ӿV��.n�����b
���c[��;��P�6J���?�����'+8��>�Q�� {Cߴz�]Ș=ٓG�Q�61~�$r,��e�'��}ǵ���~�h"�L�z��E�r�2pY��j8���XG2�g�oϠ�pև�RA(Y	�Syd���Q��SB[���E��g(y^�~�Qr�p�V��>��}�\�!��B�Y�C���+ܭ��{�xs�����6�pI�g���4U�Ǆ���R��V��|�2�MRP�?�Ŏ�M8ٓ`Ld'є1�Wȳ����aD'������E�B_vP0���I++�h�z�sʨqC��~��c��wK�=)�/
�G�Qo��&j���C�϶n�<s^!�ޏ���i��&�Nz�c~�CT���qA�ȩ�~�[��ҡ�W����Ą��X�E桎f�WM�ݞ1�Z=*7q��3�´��!W-���6������7�O�3��lI��@����KW�+�4�ہQ��$�?X��Q?��M�� �p�xdw{A<��y����l��-�Н»�>t(qn&Z�ɂ6:2�G�*}�c6-��P�LU>��Y7��x3��-�iFb����Z%����ǈ���䇽z� �F�'yd\�/C{ݪ,���͂��HX�n�[㙴)�|t�3�p�XMKҲ��I{�q���YgL�Gsg._� Q���<4��:�`�s��P1�Nꢳ�͚����W��*�/���ie8���/t	�JK(�D!V�������X��6�,�wxg_�?�]���{N:�9��Q�%%c�Z�ݶ��~"��^��D�~�fޅD�1b�����K��ԕ�S�S�������:ZٴC�q�gjCƕ_�G��K^�����R-?`C�?����! �Nmڢ��gw�JZ	7L/��Q��RQ��2�U+mIa;����:����g�>ȁ����G�>�/Y`_���<��`��G<7X� wJ�����$��T�9^-:��`*`���L���.M�̬0��j��U�]y�H��;�ة4#�.r�N�&�o19�������ཀ[ƛ#OT7��J�5<�+_�e��p�9GZ��̴�i7,��N�)�7�~4ޤ��(��~���h��X�p҆��B�6�����Yx��Um�}�,�@���^�	���P`'Q*�h�!j��
���TQ�w?��ߞ�g۫
\����[��29��=��i��S+��dp��;x�	��#ƫM�]7.��'CZc�n��Ҙ9i�fGJ�D��kfi{���x��D4������K#}5!dU����p#$��|m	��9���	i	���+�=��2in}"�|��1R���Z'kǮ�a�O������lr�5�'>�{Qp$Ⱥ4��u��s�@��縭q�,C������Ap<��]���?��G�ї���-����:�D���{��qY���@��n�<�t�璻�:�0��X�W�8��r�cf���T-�Ix�E������L����Ӏ��g՟�}���lq��f1�<"CQd�,D��:���.��1(�i�:��?i�E�I$R�M4��
�n	PJ�S�eC����[
�'���G~�}�v��	���{eYӁ_X�j)�^U�k�=
u�Nګͯ��^����h}/<^9��i"����/�w [���=�;s

�DԮ��<.�r ���4H�!�q��NT(v�*��f���z�t�MA�5&w�y>��grkގ�)�_ȶ�:E' ?��Y0�Ey�S�_q0�a�R��Fc�l)�a�z�����;��Q�.�������)�J�Z��ώdI�����oVj�Zz�<������A=ށ�,�mk�� "Sc]5�;i��X[�0vv�����$�t8`	mh�dqyr�ހ8� ���4}�]����I����֑H{C#e����0����|7������$1 ��Fnt��_I��JN�s4��B��<O���P�����ֿtt�k���`_��Y�}��8�E(�}%�X���͏�P�J��'�o������j���oe����3"���	������M��k[���w�줶	�0�)G^�ƹՅ�q7ȑy����"�|LO�����Ԧ*n	(lAA�-�$@�W�R�:��Rpf<4����� ϓk����o>�� `b?�(�zh���M���]˕I�|��C�N��~��	3�Q�8i��F�J4�6�~ʁ�??քhMbc��0�1�
eF��OU�;�|�yn���jnM9�s��J��9�W��d����g�F�XC�i��pY�p�@N������[��B������bnɾ���W�h����ϐ��G����)�p�Y��*v�BX3�Iq��N�$Eç��BO���ٛYIC[H��G�s�>�e���W�z9�hb�}8�PjF����iq���c�0�h��C�)���-������[�v�wV�i�b̛�����
�>3�E�\���Nξi�A�����&��Ŝ����g�Z��C�X"�ڑW=�����.�?��4��B���������wiag,&O^r�d�n@oF5vuQ�b`��l���b#�w+=&������{Pȑ�Fn��.��QA��<��nN�4 Oг��!p�?�e��9��7g�����+�E�*Y:�6���Qc��_��Z۩�q��<���io�v�h�~7�u����h�*;@''�x\��G[twL��~⦐YAV�'��H'+��E�C9��l�ޓ<Wl_�93����栍4*�K��-doP�����M��Y��T��Ui���hn�th�A(�m0��i?o���P���	IJ�}��|r�D��Pl���F $ۗ�ti9��yh�*�-b��qcCul�n���6��;.��iY�2!3Ѭ��Y@~�	^僟�m�M�e���߈+��$*0�B:z(KP6o�ѥё]�36[t�bg�l���D{ze��`*�z����w�i3���	'j��Q-ػ�w��p���Z�"r,E��н�\����<�|�D�
ԎD�q���hG���q|Ɗ{��g�y�ngX�l}ɇ�ls
��/�
��][F�ܬ@����ՅuۑE�&�V� �i�b�'��52o�e?��ki�Ӯ�n�Zq4?q� ^�p/tu�lν�ê"䐊����e�^Ғ��l _���O*X�k�m�1��[�N�f�:�h�Z�`B�Hb�r�Z'5�֔�]>:ɒ���({��(�+8#��A���Ԇ�'�^�1����yJ����`W	bh�?|���*��yC�v�H����i��9�VB�^�&ȦN	�y���0X��7q��a^�/�����S�t&	!ȋ�-��-U�L+��MB�BDe�=��ǹ��m.�T��� S]S@ѕ;�zxg�A+\&��z
N�D+ SU)/O6K�EǡN��9�2�Q������/��⋧Z�_L�X��D���'��A��|�J��Z�J��ت���7z����*g���X?uݑP�SӀ�}���7�� ��S!#*�]]�н6�B0��u��`�?S�,ۓ�aMq��0jI��˻���oN�(�к�^�/w>>B������I�>��Od�Rf%�F�j����R=hBc�*qI��%��ޔ��0��L�b����ZA�T$2��̝�7v��Q�9��M���@gi�^N���kQ�F�T
�+咻l��Ì[�y���&��&.�~�\��E�����H�s�v�6�	��i�ë���Y?��-^KK�[���H�Zbd�У�5"�?�漟��P�dJO�\��':�	'G
�Z\][��)Ҥ�M�(����j)R�f�%`rG0����w[�o�s�!8���a����m��5X�T`�1~�0f�ڔ�S[����F_�}�f�A�u����񗍙Aӫ���֕zr�Oԥ��\A�e���!��C/�	Pa�>��x/��Q�w��{����({�Y,�o�5b��I��nO�����8����i��#*�jolǵ��LpY���<�)��Xz�.�O�mw�K�\P>��;� -�����/{w8y���·�ϋ]\��:/�j�&$�I��r҅�یP��
\F���<�~��^ϭ�?�m�$.�R�4�t�Nw��4;�:����	���E�$���@�f����V+�~����=�#/��@���N���z��'��J��*�M�����=&��>�k�0K�v�u�_����k�"����T�Qh�6�3dTLլ��r\$Z���܍��K�Sѷ��dm �A�I�S����l� y�֙�^r��M�$D;�y�efC�>�"%*)�\��Qڊ;3i�x]�����/Ӹ b)\���c�]*�9,f:��6�
; *�f���S�~��YI�i�l��Jak���3���$��w��y����1^�2����`�����Ø��e�ÐJ~
Tt�0�e�л�>V��b)[�+�E�R����=����")��r�m��������I����s���B�_	Uz������}����RA�r�}�<m	 ��@AϤ������~��M�9�H�%�V�:a&�s}.�US���K,�!{?�eI��8}=�z�'?z�Min�~����!V���:$=~-����WY.{���,߈��1��ٮZ/]�P*F�51��Y	�xsã!��XAd3bgr�Gݹ>甑�p֫o���_Jm������g7%�V,r�V�E�;��E.���,]�A;�˖Q�H�2m�t�L��!<�<�Q�T��@����i�����NC�,�Yw��Aɥ��[_��AR�O_yWQ��2��$����򊻖�&P�����9��3q�oHo�^;�]C��|=ӈrtJ�KpX
�����-�-�Kޯ��7į���5%�t>�(H����bc��2hPABj��������7refE��_�m�7W�J	��O�kTw�wċ��&�Ŏ1@0�/u��$���F���+E�M��E�L�En��[�����o=" ae)�k��Y����ɢ�����u�mM����y�b��G���������%e�|�O�lBG�1ؐb�8Y���\�Q�-w8���Y�&�45�Qߢ�;/:�	�;�u���i�|�CmF�-:HQ�ʼ�rE�0.��?�:�Z��!�0���7�2U�#�G|YX��;&��#p#)�>��@�cz�=��bc��ܡ���BL�lo��f�i�+Swp-���<�$���A�wp�4497�B[|[�>�B&����U�:.h�Y"l���W0ب8�v���<�G`.�0kh��U�*�4���kP�?4�K?'w��zS�ḻ6Ō={�-;Z ���V�௜��7q��Wb���ԣ��E�k.q����F��<�S�~�d�b��3T$�ğh�{�Z���W���9�iv0�X��-����~�
䮏q�
L_� 
�������������
Y����#�`EG5��-�;�#�PŰ��ԉn��S�%}��mEB��T��%{��<��y����Bӕ"�|ʲ;Mo�[=���m��q�i�����rT�b���G�r�/$��67��t�l'@�XF�M|J��{��_I'���൩�D���u'{��
e�<B:F���y'�Nu�7�Eg����O��s!�>l��@r�Z���-�2��/m,�+0�g=eZ3�3L���ύaN�hb��U?p�ي�*�Q��s�К�Z�tT�w��g��t8?����8���Ӑ.�a�����h�$)˚e��w$�w�z�q	��4k�,����~����x%�1 ��f_�a�O\C�KT���zh���w��#����<�v�@d���;]�gL����?BiJ�V��y�RQ�O���|��U1|]8Yә��foG�?� O����酸:Y��ظE� "�ǠMu�]�ߵ9
F�b��P���D��_&��p� \,�<ŀI(s�#D��w������g��:�;�K<�I�򓨖�풰�V�A|��p=VG&�����T��m��x�.�Xv@<y��h�7�ܞ^�����RT��i#ѓ��HL&�O��҉�E��C�n���@>a4mi|>_��y����L�#%�Nϧ�[�E6����}�K�t<���������9ؔ��T�7��-�rR�5�+��-U�yl�{}Zq`i1�@HX6�`�$/[���:�;n_	� ø��a�����PR�����h�0��Gie����(�[�Gs1�ć{M�D�ymtu���G���T�8��h�����q�Z���,�����r\^	�p�@���K���R/��X�򍈣����V�L�X���	�$�MD+%,�J�wL��z���vI5�0�Z�Sq�������M"y?�ϛ��}@&�^ՍoJ+ dG���=-\{��5"�ƍj0$o*{_���4�6D�.�������uy��4I<+Q�%��L@f��C}�.�����Դ 
��a��Dj��S��ǖ��+H��СO��(A�HN4��N���Н��l{]c��u�L��|@AE���X'���6E@��_+R��'��w4����H� ޑG��_{⋯�� �������rO�z'v�%�q�}Z�W�8y�C��	�20>C+�n(%���^\��Z&�,�ǧ��w(�uQ|p��Y}�:*Eߐ�pJ\����v�O�� ��nP.�	�@(����{�VQ�ZH�8��R�m7��f�ǝ$��4��DS�
���Yb{\n�_&��i��X�7_��g��ew���]i�C���,��ܵ�LjI��]6{�[}H�s8pl�0�*����ഗo�v(�vMw�]���f�},v\�&y�X���vS�Y��t	E���%C17lD�Bs]'�1K�@�X��Dኣ~�a�G���p��ї���MyS��V���?�ŭ�#�C�X�;"��ܪ�JG��o2ʥ�VSZ�t���y�M mԍ\$�s�,�}�n}J�/q��q� ��B+�ց�a2^�ƞ6)�>�N�����L�V-��H��Qr�W�t��-L�\x�������D!=��l]0�`�0.|S�6�k�!i�W����Hi�E���倘&����D�}�6Aԫ�Օ�CJ�Ԏ	��Y�i2��M�K8�ܡ�������i�����?�9ߥ�Os}��M�����T��Y�'�y}�H���,����u'��n��#���L�p!z�ʄ��eH.���9I��r.���nV���:٣���Y�)�c�Nm�ep���J�wm'���1�$����mk%ݴr�hV�?<��7~,ܺ�Cq�>�B�`�NU�0ׇ5H,�����/C��ԍCTV~���T僵Rx�I9ǰ��뗵��f��J�uf���;�Fp���7�`< ��91.#ٛ5�����5!��s�t$�������ky��䙱+_���P_T�[��є�9[�V�P��\,G�6��X�D-(H���*m��Z��"�"�N�2�i�iV<�����T�?d���-G�vE�I-_%h��hI�bd����R��N���3�$�̈)nr�p�B�3�<��o��pb����
�Ӵ_U?�:�m�
�HV'._4��/&>{F"%�.�TF��,~��'��.V6W�-O�<�d��λ�Mѣ#D��i�?hyB���1���������v)#�k�_T+I��tY��V������Z�H��jZ4X(7S<�N�3��h��w�*<����#����9��4��:8q2����"w�0B��o��;�UsH3kЀ��ۯnUJ��r�@�q��2��05¹��B`-��
N|m���s��,}�^�*ہ���~��V�*��bڗΠK�X�4n�ø1�z_8�F�A��x�AC� ϻʖ@���وw輱�D�Lê|pj]<Z}nl���(3����58��mC�<dw.�
����]�}�=��Rcz����R��B�J�h�)��^���vt5�Wt�ڥqad��$��R>�8��S����$�7�掸N��݉�nuM�\9�P/^Wۤ�β�/_���^]A������ϴ�(�������'��gp7SI��H�s�9��$~S�W��C�ʈ;z{`��TSu@��>Ƈw�9(��F���"�B��Ae��H�p:�ÛԟV(��=��突����Y;���Q�2��X\Y?��Ksw@g�F���Z��C�Ȥ#�NGѲ����5y��s9�u�ͪ`� !Z_DB��԰�\�?� {{2@p������i�1Ҷ(I�;���@������a컥��5Q�_���"��x4� ۼ�_z���� �C�t `o��C�ۡ��8�T{yŎ ���t�-E��!5v<킎�6�F� i����\�(/�A�O��=��U���H�3P��%XUC3['��(�Z�u�y̱��:��+���!܆x�ƭ�p:�N��k��Wx��!ZT+���&����m�^�������J�A?��Zp��FͲ��C�7)P�D3ٕ����t�
w� �F�h;�,�Փ"r����D́i,��SwB��t�[�3�D�$g�9�ȓ��:9��n0&&�Pv��H)
��U��Fk�,v�D7h���G�O%�>���}kd���
\���0j��P��Fk�P@%�	���CO>*�x���r�lҳ�� Q�T^M���� EcrX:Tֳ
K1y�Pח�V@��6q3�v��Y��mÝ/��-�џ�� �`A�3��8.j���1��S��΅��"��4�ڔ�U#�r����.��͈*�7']7��w�>��+�/�z+*�\�2��u��('eE��q'��6���4�cg�	���i�������<���������$�@�nV�X��Z�@_=8�>[����Ufi���q����P�@�!��3���Ho����Rr�@��>��%��Ps�,�1�}`�d�K�s6�	���rT��y ����7k�tú�#`��j��#��K x��	��k�=�m�mxA@A���֕����a^�)�Ɋ��;�ថ	A���s�0��a`���E�◢A�;��qA!P�����l;�0C��j�I��:�\��n�%"3��¡� ��ǼB�.01E�qd�ǹ�#���������x)�0��D5Y,$��+ ���X�[y�[��b��h� z:n��3�Ajo -�u��j)E����w�qű����3e><M�t	(��?�C���U��?w�2˥t䉖�3wv��`(�Y�I�.v+����,�`d�e��F����Ɗ���F�p��k�Q��JE�3e|K E�"�Ct>A��k��i[h��u�G,�e�I\�����K���p�>'T�9�ꁢ]r�[5���B8���dPu�=J�d�&�ox�>��b��yq�bhKd�/�f=��n���F!�]�M���8�ڢvo��<3�Rb�80�����p���A���� /�V˽a�
��
�����9͠NQ����U���`q�ک$T%"���O���.�2�"yG�/|hBJ�r�U PU��̔w�	РJjM�)����!�������z���ȧ��9"�-��@tpK��j͵�%����!���(���6�<H+bkHH9���U��U�Co�
��u_7k@��I��~��s2ܕ@�/�zG9�p}^#Lhl��7�
�`��G���7�W�����:'��u��Dxr�?y���#�AO!��9��"ݢI��7<m�o�Uٶ�l�݌�i�Y<�z�ޖ@�ƕ4Y�����b�~�D/���F#�W뿧6�R�5�9���<m*ߒ����4B�ʹrJ�`3��{�ȡL+!�\L����jJ�U�Ƴ2{w2��;Z�d�����w�����{hYmL���4���*�q�]�'��
8�쒔���[ �4C��X�]���>���v�2s�U&�����Z"�YN�(f���\��O'$u�Y��C�	�����o1�*��}�D�*��m7�Fʽ�k6�֜��_v��Fhu��e�m
^<o3v�g�+��L֖c����o»�kUAdeܼhϡ�� "Ak_��`��0k��1d�PGQ8��,�?qu�����O�"��d�u�UA>�04�����<㮬��3��7A
Jm�Q��/t�ꪧ��<z;E��ɬ*�GI�G�����i����O��x�I0�pD��y$�
�1?���G+ր�w���Ñ�DX�EZ���F_�[�U��9�o������}:�#$6L�4�N��������qΘޜ>��F���PU
k��G���M*=պE���񸑿l^��BunjO��;�A|c��ħtĜ?�IN��5:�`�������������ķmk=Mf֌�<�!��DZ����l�<�4:(7H�������u���,[{�NxO���,֥�Q�Z�G��t���=2isʄ�I�Í����$SYRų�9��ܕA�L#}n�S!�'��i��ԌƅMC�S񞎾��M(f�J�\DĪ�f2�ĭ^�F?����a6�ɵ�� �$�Ġ4l�����rM��/���k�+��ɪ�!$��]9��h�'&rW�n+���2�����=������{��~e�颫[��[�t���T�A)�ѐ	�j;}���]g<��3|�ف�ـ��W�&����6J&��r1�6�q>��4M�a9��!/�n�.LXӢ7'H�B����)���]�Kj�; d� 8?�"�r�(��r�6���
��Ɨ�Pvɵ��8����t���C�J#~! ��N�<��Ϡ7QbY���{�7n���"�fr7�>r}ɺ 0�X�$�gե%T���LW���žAׄ��Lh�L�����];/?]�4RV�_(�T>����'�(�%�OѮ��D�d��j�3�Y4@+������bI�j+?��ã(�\��m�����������Mz�D�f��Z���-�=�.~��]=�\����d'2��W� yL�6����O���jr��UM�z�30�c+Z���J��b��X�(+��v-�a�j�aj~
S��)KH�'���.�/K{�l2�ܾ�I��/���w��!#��!�n(��
�E�����S����c7��"3�J���Ł��>���6�ƚ�>���aBʒ9}ŻY�S�T&��
��/E)�c�E3���_2LK�����Z���u�����=2�3'�ASbV�!	J�*uJY�s]a�J���6�Ts0����Rh<C�7{�Xg��.ޛJ�c�[k�L��5������s�]�](����x�/�4���ב:���Zm �0�*p%�Q>s�a/��Q�#4��:��)��j�@� �GÁj��/���Y��·�.am� �9�$�vT@�0�����Z�� �
(�ғ��}�����1��Ӂ�����Ĭb�:����Q�˙&���3w3�5��ă��мH�;��#N�3���c���n�L���u�)�M��/ap�~)������L�/�|��1��&-�(l��*�(������؅��7�l~r����e�g
=r�d$��94�QCa��-�l	�9ň1���g�+���6��vz�p�OS��ǉD���5�b΂TV���\d��|…y�_�|���Qן;$��)�~k����\c��(p>Sƫ�ov�JU0gQ{��up���5e�3LS;�tZ�hTC��w���@�İ~�}obϏ�;[XԠ�.����~�C6^"d��S����F�Y}@J�j��DCgs_&k�U0P�!_v��ظ�Yc�i�m��w��4A%3%�]��CS�D�����S�N��G�#�������% C	5��	���UZ�Ƣf����^��,a�i �{�!Hi��b�%N�?CUKf������y�*��^e?����$�!Z�S�?o*�#ꟇBE��8�p�����k�5
}A�	p��D7.�)�]d�GQ|	|X�V\�u�ᆩ�Lkh!������u��U��J���ë����>���p3rގ��<B�?�g����3�.�f�=ƶU[����(ۧxD����]��oK�zUv-�;�rJ�=[f,/��%�f��B�ǯA���)Q�Û-H��p_�O��^2�|��LIB�VÊ�C��h�Ɖ4�������4�e�$'#~~iG,����f'���bx]�H�`�)y���n�57I��cm�h��:���Ug4w���p-�[e����=Vjx���/l�pd��']���M��:�� d�<��p9��U%�@<�9�����du���D{J��� d�����{��W΁8�.�'�ԝr,"�SWPCq�Ix��d�3Y��b�c�(i\�b��{�ՠ@/L1k��|���8��7o	[�a�'m�X��RT(D���.�k�tc���)^Ć��1O����f�5'�Q�D�<��^uH�y	�gL��7f������jw��cFR�1mu ����ڵ�l�Dk9���¡��v�(&�O9�s�I��(�xh@aYQ4���z��@�0���n�݌���7ƘY�/�B`�$I��t/k�FX��(��n��&���K��?3/��r]%~3�뤹��E2qL�C!k��s�N�ch��]h#����n�SRN��[q�D�ۊC�x�Gv��
]v/�U���I$��6�E�y���	K�H� 5�ў��O��3����U��d*�����:�4~.;L���X���@=
fݘK�ez.Z�zD|N��[y��狃˷%L]ύ�n�9��שa��M�n`IP?,L���)Ŵ<�oݳ��vhX��iG�]Y�P�������N�^�m�/�i6O\N0A4 ���t3�~l�����IN�����r:�yT�1�߉��F���ņ8Zz����4���&�?�Đ���N3�'ٔ�􏅶��gQ��Ja߇�_��Q��Z�䶦��v�<��,TW�q�;����*Z��DƵ�#��B�3#�����߷��c�Bx�^�±�#:�P��"Y�;$��z&l=f^r���8q��X��v�.�/��,u4�8�	�S�4���ZO��s	UV��/�jh~������?�%J7�u>`�i)�sZlX��4������Co3"%��-�B��Ʉ7~�[ΤDv��E@r�f�|<� $��9h��ޔ����>��{�U�+(��!n"��$�+
ϗ���&�B(]rHCq�\ঊ�F��Z8�Z��\&閥���\�(������4ɜ������:�ή��0�.H|/B�N�Ȑ��Ņ����:��B�03��3)��5�&���o@� T��L:�;�u4�1$����x�M�iĀ�\ZW��r���n;PKR$��8y��dH50=�C[d��ޑ���
(�Hs��d�̏��YɳH�2��.�N��7q�� �}ݸ�i�ɮY;*�M��4�Õ-��1��c������m��|�[<����?�H�8a~T;�e�����>^A~U�3-�}��3,Ƶ%WȨ
��@����Ǡ��&�&��Ov�Ei��MHda��v�o�[�,��;)���]`;������֚3��l�/���e��ٲ��"�Ǡoƅ(6Jל���$�mȃ]��.���<�~0��;�w+kՋ���6�	]�S�&�:x�%�t��Mg���Nr�m@�d�k����lkA5޶����@^R����&h@0_�����x3���>�>Q�W�1`Fޝ�)��=z��!Q�ab�M󂠪H5n��?�6|��͂ �a3�:��	��,J�t�\��D���R��5T0��Z�ꙓ�7J.�޿O��ot�a_D#�g��6)������AHh��J��m�����Q�ý�b0��`A�;�L���Z+-~�+'�÷�Ԓ\��l|�6�F�\��G�o�Mɤy��������VX� kpւc3��%�?���DSl�^�p���D^.�5Le}�������"X�h��"��5:�\����#�x���v3؄\�2~�y��h_ t����r}3�T<�z��E�vE}�����J�ÑK��X������0�:�/����6C�x'�`MP�
M�ouc�_r���{ގ�Ĺ^=��Ɋ��F"�EH���S���z�������a��aǇ���6_G"*"��|5��q諔�# }�v�����7>F�p���̦�,��:�ǂJ_����cuk�C�%����%�V���R������A�Z�lp�pO�O���W���p�m80����s�M%`/m|$��5;�1<KN�I
1��2��4gY�E�;"��$�轎ؘʽ5��oD$��R��ƍ$���R*������5ban3�x.p�kڌ�wY�M�aAe{���C�Ԙ,6�����soV��Pl���O�2I{�d�Y%�Z��q��1u�.�xד��_�K��m֡�7$s��/�)}��*� �#��Dt���d�ַ�/���p��$��4�ǡ�y���A4��~Hj����o/�j7x�:<s�-������Fc����XN�~]t�5�S9"�X&e��5s��5�(��{~�D��ϑ�7��҇��8l�H�3�� Dv�	�Ly��2,�(S��@�<�O�o�_�'	�O�?xTau�EQw���ŧ��;�=*�<Tf�nm�{֌B�����8#�@B���]�*�4W(��!�k�lR�TX/![�����\�d3���~�B�$���fP�-`N)?��M��ma�U������cl��H`H��"p��Q^CMM�h3��.��q��6�jj��x��@~N��'����1��mП$�@��G4��|�|g��ߐK�=�y�1a�l�w~G�7������E��zq��lY�r7�[�J_�c�U�w=����˸���clG=I�KB�2�����w�hL��7&��@������`V�53��D�Q�7#d�S�������v��;z-�_aq̝���S�ܧXf<���Kk�p�%��&���(�Ρ��2 �9#S�w���C�К�����ly��3�Y֙�>b���b�L<`�Ey�����oW/�fΟ��&f�M�=aK��?V�U���X_*$\���W�ץ���y֝n�l՘p=N;R(�zS�A�K)�OfH Q�N�hX�!���&۴
'�\�*��y97�1�Я�_z����]B�Hr���W�rk�`�V`�Q�$܌T4X�+ڌ����n�>H�1"O�"�?yn�YN;�H�",kS�͍Dgïbee��q<�:}�?T����Uô�O�e�o���(,�)��bVk*�t�W���u�(�4L  �}�B�HF�by��o^��%��X�jo�ł�B�iҡ���>%����q�/g����%�������΁�%�h�%��K���&�&9���Ù�Bކ�Q�~�L�e&�.�M\ٜ�L�x�-X��Q�xn%q��;:&h���m��2	��0�F�`P��m��+v� �|E0/"(>�aE6SwVߟ��u.�-����Iv��+����X{T}�
t��u[�ԋ�g6�[��ߒ � �����x?��_�fcȺY��&�%���{Ϋ�8�mBR��}ID~C�l �j��h�����eo�2���K�vp��?�����9��ݲG����Ʒ�|��q�̇����+�ㄉ���-3 b�K���
�Q�<À��z[�$�'��I+ɚ����������&��p^��wң����OJex_T����9�m{�?B�Zb/�:�6p(������&G��<�26�!��������0�f��W"��Z���K8����/�=%���LX?og˪ai��tr&�_DΒ]�����?���.L��<~����b��(���Z�<��\K��N�#i@��J��J�4�;�M�aN���y5 ��tXW
�0��<[�h@�Wqy9U��]�p���IuF�sO�����q��f�	3���=��S��0�(�f&�6��_��D��ǳ�,�CWM���D���D�{6^�S����a�I��X:�GFR����Ĝ�2œF��U�/iZ
�����O�Vm�ۙ����˒E�Z|��Pe��<�K�7t���Q�r[v�nKpJ&^�ծb�&5(��v?�D��<ķ��k�;�1�����GPq�S;��M�m��jH�,�d�	=_�/���]��L��(T'�Z>͚�8z�c���&��􆽡�T�}��Ϫe)����Ś�D���FuESm��� �;s�2�ۇ�e�����9�p]0�]�n��b^�s(Sn(�v�~�2���j����z��XF�����n��Ѧ�R���C�%{j¯._鐑r�W�B��뚸YІ���:<(VRAz�����%��I�T;-�Pf�g�m�r�AK�w$B�p[�� ����M�/�;Q��1@���}�R�K�J���ܚ����K����&���7t%�p�,ϸ��?�A�;f,�]�z'��e��u�.�������St�[��*>�߯�G[�6y�"�e��Z�4��[)6s:E�6��Ӝ|�7�Q��������0�站k����?KV�Ф74}b ��a����'�Tѷ��Q�2�^���H�~�$y��نv5\��N%wl�Z��
��	c=m^>C^��P��O����z|E��zQ�-[�D��QA"���WM�<�f�|��䪙[D�2\�#\בƜLJ(�y<�c2`��W͗#�x����&!D���hЌ�W���2�9�yn���X��3�5�@;F;ʾTQLk�{�X��k,�Fv���!l��RZq�OA�����c�$�o��=�(_C����������Moi	G7���Q�>*꩕DHW��q#���i� rҙb�>;HĦ$��]�(r �Zj��)o�̃ңI<s"d��������Sfo�CDP�O8A��-2���I�t�N\B�1��X������N���d���F�u�1�<�他����ނ��V$Q��9���蠘�V�#C2}M8�y˥�Q�G���{�~	~���]hg�bN��C�ܜ�g�s�6$]9X�w�(�p�UB�'�H�	 3����F [�I������I�z����c�����a��K8јԜ�M.|?��Ν�+/m���,7,���IF�I��D��3�d����J���x9����X�u��r��F���{J�'��J}��(]
+�p]��B�A��8���?Jd�&N#��5�{ag���Ι�6��0�|�������z{GP��D[+���h2~��xk�Q(��5=Ǌ�]�?f4����_�A8���L ����b�dH���:�	��x+� PoQ�W��W���#��}���x���O��+.c1|�>���AF���5��	c��P��XA2�����c����E����2hL�����Q32�<��c�I����Yp�K/��q�f�S��V�j�����pR��Z��J���D��Wvfp�_�N���W/���>F̝���F̣y+G�r�x�N]o����s�#�b�����PYˠ>C�4@�1ѩз�*o����������|֥�֗3%���P� !g�C��G[���)�;Jwg�Y���鴲Yd
N�sZD���]��"-d]�2z?�,������X@j�InI�_�U�P��8s���#¿4����)���(E�lL��Q�6llW�'w�C��m4Ow8oeu��#�q�%�Z�	M)�v|���IےN�]�6���e�G��˝؏�cп�$�㝋�[�k�n?F��L����b��W�$�f �'ɝX���ɝ��bn�;��],�����IPDT�_�3Z0鞴�ti2͍hhB�?�O}�L&)�r%4^�����o}�|��_�ݟ$�`J�H�h ��5\�ۮ�4(@:�K�S��cM�+��¿��_��6���z��i�0R~=�*N��}��ʋv���˥���u��Dt���A��*��I��M���9Ƈ6�L��aʵm��L!$�=�4��M0�W\ѝ{�=z���O�첀���?�M3�R&�l�gp�{�d�7�6�w���e�Ri-�I��#�kF���m��c���/�!�q���ǚ��:�G�vBU��bX(�6]��r'�Cn�\�a�t9�ɬ�������D��S����$��
'A���Rȗ��Q���~NA�.Q��l�nzg��݆��o� bV��UQG#�R�ޘ��1��>T|y�=�χ��ḿB�;�桒�tO��*��w~R���l$�֠nٚ0��D����ͩ,��3�O ���)�����I��[�^�كI�.��~h"��}�H��<w�?�It�>m	�i>�e8������G��D��ژ�X����|�t�EwT��#7��2b�{��̗>ɓ���OWo)��ӕ)��؏Z��[G��ޟ����G�]�,$�E,��u͋��6�H� �ˮ�?��{�~�p��l�7�վ#������=�~�� ��6�3N��,�Q9�B�~q�/8�c-iU~������M	���Vq��蚍�4�"�3L��!����:Gk��$��2s�Ũ���/��A�Ȗ�\9F�!�|"��6S���2OA��[>�'��=tqG`:��u���yS���<N�5d���H7���5�N
q�S�F��b�/�L3���+	Nɤ�^S�T��o�i�>,x �18>�5�T�n�CY��/?@���%�������yl����*����嶄f�0��W��P4� ]`�c]9��A�{/SN%A%�\���=;�4�BM^  �N�}�c�q��0�����H<z09w�+l�	t��|H��\�%~>�܅�	ŝ"k�ʮ��78FV��W���� ���ByB��t�}>�ȅWE�G����nQ��MG1�o�9��35*c�!��U��-:�T߳��V�
\��x�o�ҝW�A&H�6P���j�s[�­��[�����Hn?������?�
WeUS<Q{��A�Ns*�vf��>ɻa��yx�Q�n
y����FI�Ŝa!�V��~�|����p([��p�����`/^�S��/����KD_���>�sp��A�f�g�X���h)����A���<M�~MuD=V�ԕ�>7+N"��Lo��e�-��Ð���qP%�XCM���i�]�+F������?9����ZG�:е�.���m%���UX��~~��i��FGD"߱�2�kw���J2�'���y��ڝR?Zz��Lf惁,�z��m����R�7}`�VDH}`�/UP��mB^Ap�gDO����Pcc��d��QBVOb�+��`c��:t������Á0�.�U��j��!9^ښaW	�����r�A�3�i�j�v�`"��oP+h�DX�#��K���ԡZ���J׈�}��n����ἱJ�w� T�wI��DP�{N���O�6�ѝ\h��V����d;�nB6&H�b�<��IZ�A����]ۇ �f@S�F��@�.���1,����@���u�2��4�R�VW��΃l���KDQF��F�c�zq�s��`�1L�|�U�=<'��n(7��d�̕���x��}/�8𶙑`ڸ5���{�J����B"1��ޒU�����%����rga._�ǝd�bx�.�h~�)'Un����)]��se� �Y�	G�`���B=
�?�@�S�d�R@v�ό�h�̬zw�k��+�bU�*�(Hι�ˌ�3<N@���ð������7�ac�ae�D��M�"ڇ��K��ұSX�6]�EWf�4���A x���bp�^����Ӗܚ��V����W���a31����)j���.�kη�M���ep7H�j2�O��mQCd���w[wL(������bL���/u�
w�=#�f����� �|ll�Y���_��P�Iohо"�j���%C�Z�v<<V{!Hw�e��8j�gmx�8@��X}D�:7��Z�-G3�	eL���'#���A*�N����|��m�}
L���+��%zR��1���G�O�!u��,��0�_y���2�nw��WD��j�:�+]�L~s5����2r�����:ѿ��/⦝��ƄRU$=(���n\;<��'o���(�t-V��m��%�(W`vC���6 �;�P|����|�qG�� ���ފw��K�;�\z����
��9:�����[[����ό�m�|v�p��U1���#�I�,v����	煬$�k��wmT��I�=m��G<l}���=�F���K� H�kH80aQd�mP�htY���0@��8^~�Jcr)�S���b���qCۏ���V�i���<��k5qy'1[7�Ra#�����Kg�y߬��3�	Id�:VN����']�8��UY�F2��T&���W������:� ^���h�[���@�@��C2W;�@,��������.�� �W�yg���ot�q��� gܸ�z{=�ԑ'���n!_�3Vsߦf0�%�Kf�E�W��d���|��򼼰jz���V�?h�a��}�H�PG~��^޸#�V/Z-&w�xs>��/�[�u��G��5L�=�+��1���1����W(��&�����,���/#�4XF��^�L-�m�<����	�`��$9e5t>�V
`BZ���}�t���F�#��U6\�y�%�tHG�N�=x�哃�O���Jw�F��]�6��t�D	XEiw.��Kt�r���qø�)�@��lN_2 �����{��󍤚�xqxB�(�Y�j2�$�>�`;o@)�}��GKz�g���7'-�}�[�e-�e0v��.�Z�Z� 	W�4MR��,�4���5�Y���|;�$XT����ߖR�9�PE�P{�.�h�fG�ͅӵeb@^��6�tv�|��/�����z�f>}\
�C\�4�aV��Q�T��f�pE�������T�8����3P�g��~�*J�$A<]|�p�6�v
Y���K�x��jV���~&�0L�Φ��-����"���H��à���k�QK�}����`ƞ4�rZ0����F`�\�N�p!S��yQ���mҩ`���1��>@(~u�*� ��p�d��1e*��X��c�I(�+Y�:�y^�iT��Rٙ����D}�E��?'���|�7u�'%��)�=p��
���a��CZ1OkH��.B�3 :�}r҂ǵ���Q��U�y,�s�De�L�x�=.m5�#�~Q|�$��|Ňm��+z�'�����͵uQ5��'�5�����z`�� �w�R��b.<�~��鱦S��0]��UT����K��hz6hg�fZM�ţ/$:����3۹ڜ	�ZX�zg:�(��hr�o��Tm M��貇�����@���}*�%�w���_(��y�r��͍*���\�N�,OcS.$Q �|m6��a��^G.w*�Y�B�1, 7�u���5��j^#Ā�G��2��UR�Ou�g@ 8�m�&�_��U����srN�
�i�FLW�Um���Pdh�;������h�TG2w~��B����`77d)^�I꨺O��i�R����� 9�>�%?f�i��7�k���փ�$�Lt��$����OP	\�a�E���^횤5j�.(����ڜ�"T�(FYą���y��zճb����9
Q{�J|�� �h��-����!������BOk�'��KE��ì�A���.GG��e���������9&'w�1\�TZ��G@�S���ڟ�r�I&W	X�va8�[�a;�;�V�6�J��Y�������H��� �r0�-$�@>�N�L���kEx�^���5o���b	��U��}��P�
p�,��	Bu�v�!e��D�
4���S?u�
 �x˦E�%��K�GE-	�E�s10�}�%��r$�9��ʕsh�`�P!��5�����ɂ-!�QɏQ�FL��O#�%G:P<�'N��F�3G���,̻��')�F܍k9��Z�/�������a6�G���ƛQ4ƲH�p|{�r�'+��B����S��l�`�6'I�j��r6�Ά�Ȑ�ҝ+�\������S�"��U�&I/��/��KT~����֒��އ� �%�u�瞵8�8v�p���FJ�j��ᢦU���ڭ���x���q��d�3���Uu[��xb�:R!�^�=4sx
	�L<+R�$=xG�1$�RK�q˔����F��Q��eE!&Q[����)˪�dW4ɏ 8g�V�mf�᝹.�"���  h<���K<+ ����*}��g�    YZ