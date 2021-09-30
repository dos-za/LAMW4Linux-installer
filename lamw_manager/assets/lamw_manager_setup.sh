#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2489963154"
MD5="5b26d4aa0606af535ae88b6d2e530ebf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23904"
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
	echo Date of packaging: Thu Sep 30 18:28:22 -03 2021
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
�7zXZ  �ִF !   �X����]] �}��1Dd]����P�t�D�}�r��gP��"|D��7ɉ=���t�͛�V/��wأP�<��:��q��;���'Z��tV���[yI���*�%[]����(A7��?�̴vU�����uLIPU6z����c�X��;�������P�����E�~�q��ȡ�]�s�G�(= �L�7�b� D�ǧ����)@)%9�����P��!�/��"�-8.�qD��҂��d|� ^E`j6J1*�+y�q�xT�U��ZڠӺua��J3�����u)�L��z1r��M����{P��@v��	9[IZ��%�(¨�[C����&܉y���+FK��eĈj�$�0�}�����c�(��^������,夎�����wo	����	<�%�Ȏ�WW���E��ܴM/qg/�C�yΧd3�'5ƣ�8���B��|���~y���;�n�漏?�]��}VP����2�$Y%i�)�$O�1w����≚<),xJ�F0xg~� &��Q����;p���'��ǽ�xmF�8��Ⱦ�H��jnӠZ�Ϭ][*jw՞L3k֚Ϙ�q��p;�Ϊ��!��c�k/�HP5)�3ѭ�.$F�Ї}6~#�{�5�� ��ʼ�q�@���u���綝m�Hq_�u��f�����R�j2�r�JD�Y.n��;�4*Π"�./���C�ܑ'r���1�(`�E�#���R�ˮ�����t�����52��f[�[��6	���~4] F��A�f�Mm�H�����	��e*�i]Jqx�Xf�=���㺫�� �M�9��s��>v�����Ҝ����e�MW���DH��6��H���Ϭ<a½7\ԣ �5I�<�ԫ�qQ1�����@
/��ԯ]�-<�?Q�h®�қ���ށ� [��a���zlt?r�t��Ի����V	8���LX/|w��ˏ������x���U����OXx�@҉'���ڮ����F�SX���ްG�{�kDtcUt&��1���ah�B�j���ߤv"�U���d^d�u�ɚ���&��"����S �)QgyY������*|f	���Hy�=b�C/��瑟ڕ���{e}fNQ
�"l�Q#[9��/�8��-5����T\(��ژ/=H��swooO����~]�ɔ�uu7���䴎��ؾ�P>�[�Mn�\�a����ʫ�`=F}�i���ƺ�x�ķ��j�`�j��k{�D�C�kQ��m��HG$i
nj2�X�؋��a�i�gBЩ� �櫡Dz��d�!ƭ�G��n����et��fa��Ng�+?�f�&��9&�v�;�����Op���zƯ��\�<V֬yL�
��b��ҨP�MM�1�ڿe��#������P"�}ۨ볢�qL[6��"30TH�s�;>�6���7V�z��z���^�;oM5[?5.Gv�X�� 8f3� �)d'#ILp�}��F�)h)�$On7Ϳ�%4-E��ί�b���л;-7�������zrd��{�k�ɧ����cg~<0{ȕ����>�E���rn�v��O�1)P���^*e\�u<��ͣG*ocЙfNL�&bP�ĺ��»3;��Rj�Ď�c��=L��;�;�F{;�lT��)y��Q��77<P�,�A���qrPQ�49f,�H9����"���&u�(ZO*�H&v�t��6�qo!s����-�.�_����ٷ&$�cQ�1��Yu)�	�D,7�y ���a��g��T�I�Ƚ}k�!]�wJnلX;E�I0��)H^�6��h�U`+�g��5T
b�ؠ,X���`V��)���pU���'�㈪ d��)�J!A���:L�`�$�Kj �~�)YR']�l�j��+��5]��4��^�Z>�B��2br&������"T�]��p�mḚ��3Tu�-�8�2�k RI:���;<��`.?�o&�u��}�2���*��Vջ�o��m{����ht�����p��X�"�䰜�`�*P�G&mJF��S~r>Y�p����OI��4i	��2g�<v���p��<�,C�M��f|sS�tNqȋ@Otb�D�ڿ�����R�#����(ǚ��hz=*޽�62���,�N��L�Tu�6�*{�έ��=f˥Wa8�D/,p0?��[��,~l����Ynvk*�Z�o��$]� 2�Bw�0�(��g�n�o/ͩ�g���M|�r��bX��=N�;�Ʉ}� &b��9*&q�S 4�y���������q���UnU��Y�&5}��WC>u\sW�ђ{u�G�됕l]/�q���F ucG��3�f׃�B(8��{}�O�����O�UM'��s ���N|�~�����Gc�T�-����=�$��G����j�����}����`���[{�����o�֐�Y0��p}sՌ6�p6n��)�/��T[�f�z��.]t�� L�����O�f{�E!�*�{������O)�kigȴ+�-���?U�ʒd��{�E�(��I�HCǲ/)�x��;��x�A��@�J�@E�4����d��fq�tt�P���^9LDO���c�ץ8�jNI���hWZ���U�*w�GN\ܾr��&2�*%(���!����c����4tՏ?�x9pz�A�l&@�=L0��j�e����jS�Ԩ��n���$LvL%պ��x߲Z�`ǆ�A���)�c��Wg\e��|}xM� D����-�n�|�ը��T��w���� q^�pu1��Ys�!7�-��V���= 9W���#���+����ݮ�ۂdE�W��'o��_l��)##2њcNrp��*����IS�WJ��`m��s��o�uzb#NU��1I`d${���(���e֊7�_��._��=1�r.�� ���� X�/��~�	��Z�������c�C[�Bf'����1����K5[�s"̐I��W�����Z\]v*V>p�$������:S���-���\���qU�Z�w�UsX�{�cu���~���C&��̔o��~���o<��E*t-x���Z�P׼`�q�Qn
Y#s.�	 ��`ϷP��b���	�S�?t �W�۴G�3���Ҫ�����nT�3��-hw��M�`�Ib�o�~�����G�.�9�f-�/�Ձ�~c���J��;�'i DSD���Mk��K�������`\	��pA�0���oc�H�`�t~�rk�9���Wg2�,�=��mD� �&+�b��h��kA/F��֋E�%��U�-}WWyRn���.���ctTH�>j����ܠ�ǥ�� HM�3���Z�U��Mzy {����ES�'�Uš�����ga:��%����
���ߖ�-<,�A�#���*�3Wv%�-ֶr5�D{>�=;�5{]�b�*vY�Hݰ����Mtm~��i��A��� yW��at^b1�U�lY��ΦrZ��Aq��u�X�Т�3�λ
��)u/� ��9�׭v�0����5?m�ey�Շ&�;�񌩥H�ķ�9��G嫐�U�,��z��B�P�9l��-o�A��B�
��F��0C�p�y%�rv�[��I�ߗ�\q��nhb͊�V��=�����eƲ2	l�� �J��P��{�@��J���E�}'ok2H1���>�H�a̓�CE��4�y V�vi�b���&&� ~RZ�4��Ѕ����rL~b�0��PMT���tb�}V��~�I�_���o�7`�8�Ά-�n�����e�Y&6��P�%�x�ӓI��jK�7��Z7�W�(�BџknBo9�LɼyYEF�'&��@�7���-��s�DtM>bw�锣��%�+Յ�W3�H�3x���u3���bt�<���e��6��X.��z�~���G��k��hr|��%���ܙ�_h��E��LS�e}Y<�kD�*���zgl���������^������'�9s��L��*�	�o"_{Z�̬�x�F�
�fn�8W�,��&i��2�~�f��h#��=��L�q#�z��/���(	�����n�R�A�B'��a��3W�|,@���+q������X��3���B�=U:�q&�LS��Keu��H�Ӵ:�V�&�mv����K�6nF�_�K�
�x0�X\`���ɷ�2��w�L�q�w�-5�C�:2ӧ���H�/��~M�[�""An T��m%� �R��v�k�	�&��v��9��S,���g��uDVmC��I��]q�#æJJ1=��{d3��
w$����P0�ȥ���έm&��ű��f��i�FGV7N�II
����ܕD�3�m�䊼P�E��Tzg�wb?����<�}�7�zNo��tr�xZ�B׍i���R�I�1�{&l�1>��K����ܗ�d�@�
��d=�i9��	zM@4':2bl���Psm`�	Ӏ<�YJ��i	Ć:J^�ïac��#��qh�ߊ@�\簎ˍU��=`v��d��7�����s*o|���l���X��c����춝%�'i&�i��G���ƌV+Al��⤚\W�U�%�.[zh��~�����I~d���	�=�TuG���8������c��;�h�^b���R>��X��Fc���]j%~�����'�X�;r�9��PM���^��}�~LR��М�$	E-St��)@~�*���̀�s�ɘ��q��C(�U��s��;W/�H��6ά��߳�A�d� [!�p:=.����_��YH���gJ�ΨCM�yq"��J�&��ɅbHO���y��r��F����8y:L��&ۂˣ!ɐ}
o%�l��:���2G��ޚ%J���֚��t��!	��.I���������~��w��R��/_I�,�]ے���8#��"�|�x�03���(��%�<͚F�~Yׄ O��A�_́�~��)�䰒���P9�0s$l��U>K��/=P��o���_�18�Ew�0@��Bl-�>�Z����H�zl���?�hj@��c��5��~���|)�,	��&kh%����./��p�QTwڗ���"�f��W��d$PAP���k��I�gj����Q8[�)e@��4��N4 ��� }=:�w�w�Y^�/2	�Ϡ(�$��Bm-������g���,8�*���0��'�w	C���~��j���������NR{ڗC=��r�gi�e���\.�/�z�s�g��cF&�i�9W��k�����T�n�V��и��h_2��}4��(Il.���r��A��N����*͘�	����J��L��I
�_�DH�>�*��Wy~�&"����������sr��4_�	�-���^��&�ۭ��@E�񮊷�G��͝�QŨWLnDQi155ϓ?�Z�I�w���k�,���XE�NI�ץ�NM��� ��vMR�g�lg�L���QǄ���¦� ���o ���%4ꅾ?=��x�]Tkǆm�J��ښ�5墯�/�y�]W�qE�<��X����@��y~+�q �D�N�>hy��V»OD�~+����&�b��}b�4B֙M�B�Fzh?�� �g�#f���kVP���3��(:&E����p��.�m�_�g%�.�B� i\'�T{��b��zR�I�� f�:��B�o�%)ү�BH�nÌ����@�+��ڙ���� �}>y4g�j,��zs�9���p�Yx
�Ƴv�muATH��n����&7�aS>xia���$7OE^�/$6��-u44���V���|�|/�DD�'�=�B���x�4�LS����ك���&��S�;"N=o��\4��p2ik�btv_�qaꑪ���>jD���r�[��`�Rw�����CpPv��)KAU�f7�癅o��\� �+�C����ب�՟H;���!�{(���qh�0!Nӂ�t������r|�3÷��"l��Y#�F���E2jk��3�D:��&qo^������b�/�$�ٵ�ՙ��~�CoKj���RrB���d��I���YV��Xk��&H�x��.�L���D�-�wք���ޖ��Իs�����X!6׆�"������uFΟے��.���%��#�2}��'咖�>+��u���x�4����9����i!�QW�I�G�b�̢~�cp9ֺ�q�%)O�B |u�������t�ΰ�- �?���WCs���+5�Ȕ��"���u��![�Y��m#~���%�L_�N6b�y8�:��<���P 30TS(�i��b���$�)���!�ybY������d��
ڥ��ߗ�Z��P��$(��=r>��˩��֫��,0s�eڪڬ�86���~��z�XA��=�Ż��c�xTE@:���b9~�j�B���6�Q�~�P/�>��`"h;�?O�xM�ף4��Qq&�Jd�A�*A��A[,'��^	�.��߹����$x��̓�B�0��������I*|xb=o��U�ו.J ^�5�8�ъ�!�W�^5̆|�:硣�N�OO���m�ĳ»���h��g�7\�Ή_���q��%a�ݲ��8�"�Ɉ�
n��JmO"�������Yq!5ºݹ�j0pXA $"�	:�3qٴSt�f�d�^wX: 6����2K�����������������]��؀�A����D�� ɫ!� Z�Alg���y�$65Q�>�`�R��]�@q���R�і:ž70������X��Ey�_\r
g%��)s���@s�|�!|�!�cytl�^8t��̪%i� ��W)�&п�,��#���<�}�4�X��'G�H2��M�NA��,�S� � ��5��iOJ,��������� �N������� ܺ�HY o	����	���g�'}�:E(Ǉ�x/L����j�ᇣe��� �5�DҼ���*D�yrL��R`;�f3�ji����%��2k���U�R�*z� �hz#����^qp�٥�Y�E2�o���<���+eUyQ"��4}1T$ӽ���O��T�)����k&��vϮ�B�6cD����b�><}�.�9�����p��� Yܨab@�)���9`�"���J�P���0�x�51~������S��q�ySKw������"t'���x1m�����Y��]ӑ��X�KR��Ϗ9Ҷ�Sx3�`��Hk̑i73�c�1i]�ֈxBƃ=i�r�A8_�x��X�Qc�⹗-p��L<�������>�O�)=͉s>� 5͹O���NI��r*otgr�}hk�뙻H����j6v�i1�T�)� �dC)ew���ch@��젬H�z��oiK3 �eXU� �z����h��V��
�ez�Dޥ�*K4h�K�G��h�����.v�� n�}�[z��V.�w�{F��,�8e��2����?��k��H����sݶhϺ�E���6[��v�	���[� �zB����]:�0���(2?}�΍�	F�3�u7Zn[��H�U�p!�Vo�J$��p�Wy��E4p*���	��$�Н�^8eNCp��A��,/l�]\�W�����~���݌��,�
�Yȴ���dD��źJ��4���r�Sk��`����y���^ XDy���	�7�L�%��4����>����$�y��kQ J=i���z\��W����:�>,"�~w�	�a��
_Jvd����u �>��@�� [0�
����p[�!H��[�έm�%��c�/���߭����ė���A�[>� ���Ǜ$$�����W$i��4;�����[A���+�`���JW��2�߽]����(��<��4@E�.\�r�O,�Is�1W�����%��/t+���[�u�p'�j!	���e�_VD+lō�����2��V={��z���GC�j��M<���(4�>H>�[���`��w����8�������Ȏ���wN"��;�R����ΐ�i��#�#�T'#͓D��Y��\~e@��lX�h�o�2�r9!���?�LrJϕt�޾�2=:N��SL�Ovc鞬� ���6^/��HZ-��0�&��a�u�G�_�iɀ������6+�'�M����iAW�zdi2V��� �6�T������gtE������熄��<�nxO�2��n�r[�tl�b�Lg��^��Xvn�1C�6�$}�Ē��rJ/�H�i���9,��z⦾j返D(�G�d6�M�j)�(z_�� �0�.Y���;|�R�7��6\+P Myf!K���'3cǂ�d[.�{>��
h���aV�v%6bؿ2����\L&�)�uu|"}kFo�Fvi߹0��JP�œ���с��Y�3���W��4}�~�T?�u�+.��=���XyIi�I��[��I���W�g56C�tIQ��4V�i�RSr�ͥ=�x�$�#Btd�� ���\D�94�|\Q%%����=V�_������i��|EH���7?�&��>� 9wצ�xK�N԰��[{8��abg�+���M�����8s�܋L��]�1��t��,\%�Rp.� �*I��jec��J��B��%���1 o�z��D���:���$��
��4�|�'�ϗVɇ���h�dN���~�"�tQ�[��i��F͘¦L�8���ߖ�ъc�!�oE��V�?�8:�3���m�d����QA�Pх�l�Xw������3�� �/u�=��2�}��4-�`�
��)���ă;]S\��v�n�lH�a� ��
�z����*3e�R���m�be���P:<���X1��	�|�����6C¤V�ε��q7+-~��@���E�?��V|����"v�(�x`Rt���E�����H�O���9�?n�̏�y����B���HH+W~4������V�Aن�,Z�m�vΐ�TFx�h:�z���;|����d$c%�P���ޮqמ�Rg@Jꋡ�O�����1�H�*��k{0\H�kf�hOX�Y$l�I,���gR�<���/v��[�}C�1��?n��w��nX�$��K�7����!�k�;
�+�X�(8/t�B݆U@"!G�ԙ��.�tݰV9��__�l-�]Ԯ_J�R}������e��B�{k�	�z��Xߋ�*�dOkm�}.B�fV�NG,�O]X?y2B,��m �����ٯ��[��i�U�I��(�5��t��ro�K��&�ɏzU����k��W�����7�Y��it'4΢E68��^v�I�T�5�*�X�9�돾�M�����d옵����I%�(��D藕�F�U\���"��W�n�1�s����4х8P�, I��	(�-�,� Jv��6�44���=��RL�������Bc���l,�Z��$����!��#�i'2�J<=ǃ�_?mA�6v���Z��8�� %[�o6�� �>nEu��ߜ�,�ء{�H'{�ӮDx�'F�$�664o*@�W w���(����/H"p���p�E��"��"WO�g�n_T�@Z2m��'%���������]�.��g=;�,$c�&�v�$��[x}����@���^�$BӤP�\��͑c=6
'����Ѻ�Y�
f�}���'~�����_c`�"�t.�1�ke� ���ʱ�En����OJ�h�=�g:����9����EL�}�Y2�P"�GC)��..�u��l�[�N��uKFT5���(�Z�^�t����]�qK�)@��_:�n�}R�NO��Ğ'�U���� 6f&t�,�/Dx�d;!a>KM$bK̪��X�P�'��S��Q�$�k����_�����0�O�P���Z�D�C^���R7�C"�����>}3[�|=S��h��`�r���l�&�h�x���ㅵ����>�t�I	�"��e���̬��g��ݤoՖt��t@���Q:�ک�'ATʛ�$���ծH��\Lm9y�,��'#�	"�?���Z������[l֗�^��7� �-�QzN�EQ#����w~]/&o������ρ��/;C[i3������01l`N�J#k�~Ԃg�c"�:o���>�5�(i,`yK��$2D\~�N�B5��>
��z�#���D�E�>f�ᢽ�O;7�G��79�O2I�#��ߢ�tOڱ�����6y'���[����/c��[4�-�r��X���&��V/*Aj�T�>��3������)��Z�j��=�T��Z0�C�ۙA�C:��rB��jR�\e`Q��;??�уƹ7�Vp	DϚ���%���Ԗ
��b[r��1�tbg��C�ms�~ٲ(��c�h&�!P+B�psj�EW���Yj� zq�~��>�8,�B���AT�F�O�J�x��`����{�R{��T;��Z�ya���M>�"s뎈�|�t��d3�����2�t�&�i�u�+�2���!\z�p��7G�C�R#�hX:�#��0�3BW:�hZؐ/��X�\�:�x
�啩���<{�l�3�l���h�!�j����o���>D��{�H�k�F	l��1�߭w��	;a��	-Z̞߉ݒ���b�9�,�d��x��ᢨ��d�����(�ͺn[����Oa;m��1��M�I��M�����@���Rj���^�\461�.�}q�C㩿�Hy���#�|�����k=� ���n�4�yu����x�`7�F➠���_� �I��=
��6����e��S�i�Q���2�{����K<��.ِ�z�3|�f�g　&*5�β��l���8Hu��!-,��s��(�e㙷[٩����snBP�m��$<�cޞ}u1AwJI��'��kP�-����'x�ؠQF%a�C�5ڑC ��x=zu'�p������D��p�&GP����te�9�	Q�d��{�ZKpx���u
����U!i����@�`y����Eiy�$�@���`;���G������sp[�_J8�G"h�i;�˺����zD{E�Y='� ���zS>?����zAs�d�W����C���(�>]c���YM-�N���U�0��6g��۾�W�S�T��)��!�N�
�f�9EA<%�*n@����@��D�6+5���a��W�!�?����;�C�!R�q�V�j�.�B���e��%3���{h�}"X^e���\jk�aB�9��)�at�����ˋ��Hds	ƿ�Yxê��_S���5��!&�$U���_�;�ty~��*�)�ly�#���#r�E^��$���ٗ��%�M])�`�9p�gZ-��d̦.^����JB��%��Z�÷��l�#^Q�����	��0�:�_n���V�	���t�մ¼�4k��zb�L��{L��+�}}hE����k8�o��
�)�����׋S]�-�(���1CO�}���Z3w�Oo���"��sl"Ok&Mx$��R��X:����ZT��=bV`�c����~�k�!_�{��H!�9���C�"��J��vEcR�������Er�|r�5�y��%ϫ���mA�v��W���2юp�~���	D���6�3oJ��2���Q
�!�p�		�p�������o2�|��ĝ`6�o�ॱ�&Г��h�7��yz�A4���24��k�BDcR0΢|�,ҫ�8-N@(���c�e�.N�$����D�I���yt��y��N;2J��>Ls�QMג���C[(�&����xà���K�W�b10ēG[�/����o��?v!�T�\
<a�����?|<S����s+�=d �u.�����������),�Di@8^
�e��9�߂��B�ܷ�+}��&�T���G2���b#�$����'{�6��3�u�o4�E͇���aNI���'
!\ٹ\���%��܈	�֫��jv��b�j��ulj���Xx����?��o�S����@����E���nB>���t�ݵ��~�Wk��m��d:~�Ov�s������'+���(�s� �E�����v
��"�H�A;u�kB���k8��eC Z����,�u�#���N�.v2Xq��^�d���E�∀E�^�Ԑc�S����7;k�����D��+4�S����p��������U����@��lD�^����?(�U��N�%��%Y��s9�N (
0���&�$*w\���!�<u��R�����m���\-��g0��:d�~iT����0Ed�
�֭��f�:�����~G��3Ё�-�>�8�:tWE��x����i�5YFϸ��ZZ�#:�:QHx�ǜ�9��ugƑ��JA���$�Q��_ịm@����>яtF颏�0�Ь���m�FܒD�����o�S��΍W��30�_�	9�#��/^7��5bAV1���՚VM�ؖ=M��tu���>y�K��f�k��SU8:��9TmQ�W	k04�d�j�`2r��B�z�0+b��W�_��`���8� 4/;�ʣ��d�Kޜ���3x��sAp��ӵ!?s��W)���1u��0���m���E�J�ZԀ���~��i��'T��/�k�X��K�Ul�i���o�q��sR�m+�����X�%�<ƓvE�����Ya|h+�WcD�m�ܸ����^�hr��3�hY��t!�D{UKg�M"��O.���KQ�TΊ�ŖgZ��c�-D�������1�LtT'��s/�]G�d&��)g��4i�Vjx Zt�4�6�pJ+�R�@��t�="z��ՁtI�>*wՀ7����﬩}�z�u���J��R��!���C�[�f\�)��Uf�$;	������)ZVձ���������\�- �@� S6s)-}�qɿ�hP�=�� �8��1P�>V�JQ�i[-�/̰JK�Ş�=�u�a8�c�r�@c��q��9���~���4��� ji�^������z'r�Q�HF��8���y��dGXZ�'_���O��́%����H�x��$t����uU1��*�����D����QGU���'v�ܛ���_Se&�M�YU}�̠��#a,�L�8�$pG�QY���(O �E��J
ى�/����8��\�o�5����!�jL�)� �#�4���O�L9�̶ݎz��n�i��Mf�*1�;du ���u#1)[Y#��@tNi�1�����#d�[_����3E�W;�<7�Ib�����	�н�v�#���It� Q,��eÜ���9�r�0a��Y�a��-�툟b��~
�2#���3XRI�E9Sw��_*_{�^Qt���И'�f�2*Y"K�_����궳�7[Ԭ�����N��56]�d�QC�D?�lA�� �o��8"���,G�x�:u�BV ���lAW!;��D"�sM��`��4�*�ds"���� �(�'�Z2E3�R��}*�^΅:�����)<\�̩�����J6�#%�&( ~8�ps]�� ��#��h��Cr��aZ^M�D5&U���x����&�@߶��#�y�DU������ʧ��.�V�}����&����&2P��G�5V��`��גs�d� ��t��jF,�Y29�S^�t�Y̳�(��	��g B����Tƅ��N�_��u�e��xrB��Q�5��Y)��&+ka�YN��6E'�P!��w��=Gu���]����3�Ē� ��"��2��ܭ�˕N-u��qvT��va��@����Uo�7huZ
�W�ɦ��\!'^� �3�̓�F��%�d&���zj� K,[k�mmj�ǵB\i/h���T"ͮ��?��c\j�N঺�\-��q�����6?�����ai
����U�L�_���81J��y�R����,9/HڝT�&d�ww/U�Ic�Fsu��R���#ҥj�zQTs�����\q	�ig�tn�y���_E�K��I-�:4��ơY(	}�ډ<#c)2r�>����lxC+j����|e)�E	��GjN�pA���֛�/}�c�}� ��[
�]�0A�"�7�������!/卐ň���؛qQ:{>Df�8h��z|��`d7��
�4��M	3��	��*M�~�hn��J��J�^Q�M#M1k5���GW��ų�6g:3
��5�%����m�}�j=FO�C�	�[�
R�[�m�|�u�5�?����5�4��(���b� PI�-u�ֿ�}1���^@ar�i�ԥ6ԋ��Mo�4<*��_�'R��k��G*�Z�B�!Z��`���d�V����*��vk|��i	,܎�Y��Mit�Z�[�<�G���R��%:-�8�Y�����%!,4�,�؀[U��F�����CU�柳�C�+a�����P�7�:�+����f���-+�Vu�K�'z�$:#�E��1Z<��v���F0�1l�Y���@��\���έ�U-Z�Ծ�nnw�V�gt�z�cQl}�`��e*��� �]��B&k ��C87����E�������}�M)����h�x��p�e@�����H��WM��]P#�z�pl���S�q�[���Mq�'���ˌ��p:�١i�$n��Q$���xp~ٜ�l��J��Aā�R�(l���v�@b��8<��ڀR�v.�6b��]��?�y!s������g��'I��)���́�Ǫ��H��_ݔ�1?%���($(N��������#�<���8�$�#�W�n��p�Ik�m�ڼ�%Ѕ��u�o|D���.$-�4s&H[�u�3���7��$���p(!8D��y�w ��o���D�������w�>��ez�ޠ��v�l�?(��e�Ӷ]Ev�tW��н��c��S�3 �~�ܓ���R��d�E���`E�[�@h�Zc�f���q�	���7� �4bµ{Hb�}!9���5 _�6�"^dmô@/��NR�����}7��d�2�7�hIB�;2��>��\6\c��3iy��U����ĀJ�xiEK[q"^}b��S�B������1��#�Ah�7L�_�R�q�4)t�'�%���~����;�I��u]��=HSZ?y����X�:?�
����LL��x�r7��P]�z��r�n�<���N���g��Q�������W��� ���8ÂD1��a��ЯC�uuf�{R�������BDcb)wA��w�ٞ�Yu�������頢h�5�B��� ־�O�{3Q���%�W��	ٿ��������&��'�	^a%�R+aTSA#��5p������&�H*��g�^,tH5���8�e�Ϡah����Ȁ���tA6&��/�Y�ŇF;8���B�]̦�DR�P`�d��J�/3�ӌ�^�ҽ�z�/��M��]�	�qlԜ;�4�c[������Vb��zs]b�&"���^Ь�
)�l4`�nř��*�XI�CC�o��E���zϣU烈�ӞF�܎��;�<>&sW�5��K�;�aJ�.=�v�_�~�E`)��m!!�^p��(X�(f���Z_�n`�ӵ�jܐ(ŧ*�~��LiGz�l8�u�D�;�.���q�
�+��I83�PLP4j4������R+�ƥ�j���m��[���
��
e�C6��\58N�Z`#���[H*)䪳/�� �X~���ٖ�v@�#��xV�d�Ry��ľ4�tG�Sq*��;�1S)p�ؕ-Y�-<��@9'�`H��6���i��E�e1�{/�b+ 2P�o��i�V��c����b�K<����.��VʷJ{dމNp[3��i���7�~#h��U���Y8�h\OH����
�V����Qa��ˣI|2X��r�bw���3IA��z��_��uQ��� 
U�O����t���&�V��i��*Ty�Dd���ɒ�O5Qi�3�!pg�>���G���TC�徫`����$`ߧ� v�K�F��Dn	��Г��(�T����#���`"F>dE����R�!�_M3�.��IS׷y*��{Ll4 p���k���Jd�>^���34��Q@�m�vV�O��n�������;gW���������3A��ׅ����\��7��g�u�D�e�m����3�P&��q	�.+�^�}d�7=��1�������`��k9	�������:C�6:kg��S�xz���i�?i�.��}�>�P��@
h;��ț�����BsJXYs��r�'�Y)���-`���/]���3K&Z�iU-�4-M�U��X�^h�?t�c��bX�Q�4�"�^�*W>�;|'� ��a��J�j*������c��X9>	
 ��($�z�F��2��7�d��������Y�t/��4�P�ݜ
�=D�`?�c��� �.MZ�X��*xm��&jm�ϨէE���kM�>WE�{&��0fQc�9����Yrn���zw�w��Y"���?5��W}H�ʡ$�!!�޲�5`d�j������]�z��|�=�1����$���L)]܈m���ߑZ���%ö��TL�N������?%ɟ��p�]���t��=�&_���P���;~��^���#9/��eS-JN� ����i-���B�"Rnc������B`_�&!/���±�m0���VB��G{�B�Zp��­n�Q|� ����K���%���A����[�α�4�%@U�t�m`�I��8�����e�Ϻ���'��t���ɞ3���ڑ��l�UQ!i�4�+(��>�@���]}�ǜp���aح6o�#0����jo����=d_	R��;wg9_���.#���%�C6�Ds��R[l@#�W0�W�n��c<����lS%��:
փ	�B��q5]Wm���n�x,+59�+���eE���7���4�������NK(��X��UT�c�9B6�Y�V'��}�+������0#̘�=]���S{,�"��Fa��/HƟ�b�0)zm��j@K�#���-\�G��XRmTd��y(7��Vè��g���l�4���!�!�@�S'6�58��z��b[_�ҭkZ����� ڻ�����z2KS]���E�$]vh���񍽤3�ú00h�s� �wM9�T�~��U�+��0�/((c�@���U�����H����"�hM�oa�.�.ÿd]|�9�w����P�*&�ن?��.��5&9Zp��Nuc~u�O]�b�ݳ^ZIw��^s�v����FJ�BB3l�@]Kv��~B���D\������C�Z-�o���`A6�$v&Os�)�Y��r�@%�1갤�Z��Vd�7d��d
0��7�	qr�>F쫑!`�N_�R�-C=ql]de�� ,�"�z3u�,�ϸv>�>#�uz��:
,��}~�����`ش� 
�����&�@�^�2��]�n@[������Y�ᢂ�64�xL�%�UK�ҭy�d�ӻ��,2bb:��L�5Cw�ĝm���Yy&�(J���!�*��ٸ���1/1�,8z�|��5LJ���#E�E��pOrp)Z5�_��	#ֲ��X�D���2!��H��"�1�B�LyC��(߸�+��Zp>�Ϥ��C��p� ��X(��g�4M����=C���N�<X_��9����Ϋ�i���"�l,4�/R���m0S5������jv�p����:����/&��n�{�i5�"W>	Π��d���Q�aڨg�o�;U�k^ Aw���i��hTM-�?�{C�,r�uC��A^}A�څХ"�ϳSPA�nYֹAx�+�)K_Kk���3X��O=_-��$��sbƻu�:�̊8��,���z;9JD��N;+)��ώ���~_@na���0��Q�,���F��;����Q9X$�v�.�7nmu]��q���\u��ux�c�#��Ի��AQj�x�|Α;yOA� �C�I��R�wL�f''h� @Xt���{_9���4r�� 0S%�յڃ�`�S&;��t�(R��~5p�ؼ�J��[�AƆAzr7��ܷ�O�`�ҩ=�kQͩ�@�'M>'�I�F­��K'a��ܸ	�c'�&]�84��[�T�������F��@��ò+�\#�J�G�O�G�,V��u]{���[�ٰ�H�9cG�x4ql�K���Ա�ئgI����d�:=���4Jy��ɞyB! !��k��ț�������2�78�y���9yio��ZK���r���7P���å�G�t��0�n��鰜XUώ��������x�RK�� �0��Ǩ�랇V3���Q�95U?��:��^ꉋط�Z?�f�ا����<ѩ�؃7b7�ǡӡ4���CPt��æ(�`����o�8'O�mv�^c�T�#
Z���I�aMa�S�'0���p��oJ�;�x�8
P��ld,6가�|[��{�"
=E4�E��2Y^��l����Mf쇽�eD���I�K���b�M�6����S��4)j{��sG�B��hW�Y�?e.�7{Xd��JNv*�r�X��aD���_J�fo��H���sg����P���W��q��N�4h�v��s��m0[���㷿N�%�Ʊ���>��܆E��#��|�>�<د,k��oo���8��DU��;b%�C���NNd_�G3d��K������!^����On�r��Óp������ǭq/��6Θ�{�,)��<E�O\-?��s�sʦ����]�+�{�7���p�F��5�@��D�F7�b:i���w���R��!:�6&+�j�9X�<7/5�3Y`�bު�%��癒��L���-1|��?k֙�����v!�J���5(=��� 5~�m�-���l�S��ql5�Z^��NR�"�l52N�rr,YyQu�+�~�|�ޠ��X��$N���R�ê���_�9�&zލ$i��@|��dP��1@W*�r��/z��hcYy�m�C��< T��|�*�8z%t�s��E����q$� ?JJ���̷,�ɈW+�8 �̽�\���.��<�X��jEP�r��-�.vE3�H���+r�Rt�^q�W�f��&��m�zQ/����?�z��'�������Vi":�]�&�
�fs�J��W?'�'n�1SŀL���P\ ���ib&L�.� �F����v��JCԥ��$��&�zɏ��k)/co�±~L�o(��Q��yE���<��g��aj�!��Z�fa$1![y��7��&�iw}NQ`����5��X�1�ώ�<�h�ę<X��KP#5��q-���15����h_Eu�&��dS�Vm�.b6|�Oǳ��4p2�u��Ʃm���/X���m�ȃ�#$
����������w��� 06US��j�Z���1~P��DR�����c���&���2�/�D����ũ�sG*�6`\�-?��6�s)-�A�{��/�)����f5J�T`弯��r��F7�0fY	�E�b���F�0b�T5O�H6�f��3��x��"�<q��	u?X�iw���0��
���A	i�r�˽�k� ԎP�f�?1G���3�C�ߍ��źm:`�(i����|nX=�^��3ם���3/��A6��IR'mL��-��z��� ex_��7ש~���^8��/)�n�j,�)Q?���T�sI�\p	��k�FĺvF籹�d�Q���J�V!���!v}B�걎�Itد�{v�ۼy���܇�4po�m����a����-��c����E��'?5���seח6��gC?Xq����ca��Me۩Nui4���$���,Նὖ��>3��\*J��u!�Ĵ^��X����ץ�ys���2���6�k�Q`{ ���Ҭ&���+��'�=jOͤ�����x����x1��#-�"� ���n"�!,$-	.��U{G$��b~����8v/m�����$����p��6�H��)�$DC�����������  ;�l����`���el���当��u�R��cGS9��[�̰ZM����X�a���f `3��f�G�TO����7"�"G<?���r�����?������]�_Cd ���ZQ�v0��7c�7�u���V�>U^Tt��� ��#���8�������k�� rl��U{߁����,���H��:W.��5��M^/ c������7�X��g� σ��t<>|�[k"�E]�@ޤO��7��;u �#���ΤK)n��L]g&�lm�s��O\�=nu����� �;��}�{��G����>?���k�w�O�ht䟶��2,0�{�$9x�VF�R�)\��m��YV�։s�|F�E[W�B���ʂ@���"�^o�x �/w��7"���9<��"1�8�3"�f&H���|ˊ�F,�����.Z6I�{l _4���{�2)~��kjp���s�	�A��"�`-Q^��54B��N��/��luN��*@�}��0G�RI%�	� x�§yB�t#��Q�S
������jl���n9X)JWtB�Oq�����sJH�)=Ql`���a�;ҕ����@.N��8��3��m�ej	ں(�lg:�Y�	3\�K���%-�s�ްK�kf0���'���'�"v�-ɻ��Q�>r�z��{<>MP���5��D�vP����h8L�Q1m����@4B���m�����~9V���;`����QtM�J��K�A4��Q�����e�E��%:*�11�n�9�ofd�G}�,�Iy�%^F�!��2��6�)�ˬ>w���@�O-q!�4q�0kG�� C#DGô��Cef4\�$�V�jJ&g�ݜ�̒��jV�M�I�!�͒'�kZg��@>��k1�݅0��u�t�Y_�A�W���B��l+�ec�B�D��Vr{Z�߹W
���K�z����V ԁ��4��|���pc�ߦsJǍ<�-z�6�����d���.�6i9�¥���P�=��I}����yG���C���p�Hr3-	u���9z�W��3������d��N���0��E�}f�K9^��
���G�e�����K��~L�u�uoA�j3�Ө�S&.|�n�����,9W�v��r*?c�S�9s�@��}.�w���b�����I��J�J��|S���y[�ь�k�Tl�U���$^�����L��ݨ�^�������j�ddף��e�K��3N����F*f/��?�CC����)�gA���f�4���1�Ƙ9{�j��XU*z�M�q�ѡ�*!��P�����Gn�@W_�G�z��K:)�(��!i���NmgY�#����b=Ĭ�Gݿ
����<|S����ܢ�Yz�	A��0���^	,֝@1��hu��!�QC���'}$[���ۤ�q..;����};q����!��C�:i�\��
�-m�"���;���9�t1X7G�qdet�ln�t�`'@��[�~���[3ֻKX2��(�b�A%�su[��&���-�_�'�P�0�J���wS���d�E�^�?<�JWl�+���b,
|���w?C�^):����� ���M�O�V��I�*��f�5A�9~ ��
ͯU�!(��uM�܋�2k�0�(y�>���c����v�ŀ�����`3Q ��5J���v&Z�C����U�l��>Sy<�� Au��l�̔wa�w��J��юTd<|J�����f��0wX�u㿨^w5�q���V8���ַ�WTO����
��r$����6�1��+F,�ؘF~�r�RV[t��Xo��*Ǐ�����wF��u��'h���:ǘp�|W�7�v�֗4�QP��L�yxL8��s�)F�+�1g
���c���榕S4����L0�(����h�����n�＾&i�	����Q�(��~&4� 5mO������▊<v�NB�m���UθLN���4qb���7��Zgct-��Ui���a��p"�J���f���V�8t�%�q�_�B�mX0�ҡ"��Z�;����f�N��U5�0K@&;�@���1��Ve<Gb)Ů����[{�p�Xg-h�r�q5� ����l�Y�/^E�rկ��T��l���K�"�����������W����F���K�L<c����������*��|}�x��p�e��������0���Y3k�\�s�X 5�.�=���aK܈�QĒ�B�D���⚳���%v�BS;f(XF�=@|Ȳ.�A��x���<�]X����Q�P�?�+��2�wj�!��W;l|�:�.cS���H�<!"\d���Ev�F8����Q:~�yy��܌MObR�+� ��f���p��R�aW�s$b�[� ��Kl���R��I�u�\c�]X�4�A-��������)��:ř�q-��fS�HU�,q8o�a&[2uK9��%v�q�W�U5	#��\O����{�v:�����Ԁf�f4c��\L�n������Wd;YB���I�Ը>����ZZ����b��"=��!q��3l���λ�����c�C��ck[֪R��J����^�P497�2ղ4!�fmo z�ȉEc�/�&hj���M�&�X�:�L� (�p~h8)~�����ɕ��#�Ӟ��Xg^��Z�������x�|�I-�"ҭ�}(|,��n��יG��p�&�td4/)�b���<7�L�`�#�:�!�V�fqGl�C~��_�t�^ϏQ���m.ݛl�}\.3h�8�� C{���s�o�7����N�r�l
�I��%-�J�jg���T�`���l��g���c���{��۴lĐ^�OS~��#ph�\&��O�f�t�M�3/)k�͎hq�8:�|��\��8�p)�\)sB
��%�!߹�%Nr�R���o��s�I�g���i�>�U�Z��R;�f)��SlHp�A��(�.�MS����+G>�j|�Z��X3��������G�S�x��)���������#Rrr��'\Y~�|�{镖���B�R�y��"!�%��A��?6)���O��h/sɬ3.��)��J�{fwG��JœS�4vl��b_�y3�*䐎c�3���r��8׮�l����"�z�q��m6���v���
��{�L���jd74�Ok ��K��-�������ZiGhj����JR$i�%:�6>@ �����[+LW��@q_�s۠Mu9��r�sb� '�I���o�}��)i�G"/����@h5�
��y5�M�sޞG��UXK(<x���ȣ��]��跫���%��%^�.�C��v���3j���&�x�\I�&�i�E.3�'��C�e����9hĆ�9�)�����=uđ4�p��xɓg�≘��k��O��ٗ�Wg����!#S�Un���^�0|BWH�0��.qjS���쓆�`��������ԌL�5Oj�+&[���Q y�Xf��6���)���lIvƉ=�^��B[@d���.xou����\�,���vK#�����5a�z.�*��k�D~n�~�I�O����?9�x^���^�Ζ�f�`}��1�zl3�H��R�;��$t)p��X-՞48�    ��r+Ҽ� ����ݸ��g�    YZ