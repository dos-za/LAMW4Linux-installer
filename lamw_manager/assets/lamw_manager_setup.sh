#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="172053781"
MD5="606c97f6657f8968721594407ad67272"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20220"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec  6 18:04:31 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���N�] �}��JF���.���_jg\`�U^&k͐�sK�9��#�GS�C5�51�d{m,0GW��Z(�2��y���i%)��h�ſi�*t� ��~���C�Oi�M&䠆��/�W=3�x0����׊>������T{lc4T���jBo�y�]� G����bA"m�ݚ"q�x���bX�A�g��B�(k�ҝ��<��[�0���<��/9Q�龨>,)<�����{�.�%ʐ�� ��c���ċ��(���v�@�7H��\���LV�����戶�5'f��t��a���#���&<}�m�k���Is�3���Fq
/ X��ڌ.�N;�b(��T�q}�N��G��ff|8�p�"~�wE��B��M�����78^hp�l!!�΃�g[Η�8���������W������庈^{%@f�ډil�_�M�ʃ�ȪR�t�o����wj�`�_�Ŏ���Е�cZ�K*��K�2�vל\��nQ��"�[�nĚQ5���#�E^ufG�A��ݪ�s
��j?l��'�Nb��2o��������Z��l�S3���;Q8lD]U�����	��5W�S ~^>Bj�]�Q�8Z+��<�@er�ާ��3/mv��DX<V.��a���T�|QE*(U/�D�~Pt��}7t�����/Ĭh��^=.=d3�*x�DD,=����_X
d�))vS�g�r�q����yZ�{�\�6^dH��m����t��얶�gptWB�Y��Qq"*"����Y�1���0�m����h�ҭ9��]�ϋ t���M�SOc"�5�N�#QP/j�D�lf��*7p�S��;�d���a��Ԅ�[cPq:�Ͳ9�S�@����O˚;�De��;#D����5�v�S���ӝ���^Hdo�J�^DcP��ѐf�&�!���^8#P�J����֜2�B�lw�� �z����0�N\@\�T�⃿���RR���u���ޗ��#l��ތ��e����<�3<L���z���j�FjC�ۥ�O���>��R���7i^�
����v@�!�^���d��x�̈́D/̎D�<!�j��<po�H�"����)�=�!q��\����C��.�)=�lQ��r	��gB-�G��8�0����
��H�`)]�t��AoE�D
7�X �����C��)�٥H�0q�I����	�nD����|���o�oy8�B���������ӓa�N�F�l�0�,�u9���n��V�:�h�[�0ԩ�я�T�t�Wv�D�������]Bc��p(�^���8�O���K�w����[���W~(�Xw�
ěN��nz'��k;��>�cNӠ�����')�R�E���\��s�8�9W0.����}��`��<i���k��-�oWk����@��8�B{
�01.%h;@�7⤜�B��/�}�����FvB>�d�����N����S����7j�	�)�����8GYU��.܄��O�ޝ.%W/���ݥ��r�4r�����!&��_��
--S8�׍�������R�p,��G��������1y)��ܽzM�I�@*m��|�'K�T�x���&4��NxR(ă�����J�AfEpKs��m0|ˀ���gxX6x�98���"a�4j��Ֆ>NQ��I���53���r�A���) y#(������˞�q^>o���kl�S�U�W�8Gq�[���z7f~�R�Tй�>����v�s$O*`��,G�Q�����\L�ޕ��z	�=6Bs���������L��U��g"�3�1��k�R �����|`V��%� G�߶k�H9)$(k;6�7�8C��J]��S.�8K-�y썐Ň�6
Z�񛑴I����W{d���^�Ӈ[�/5R�J�	��㭻���c��8��恄Ww�ٱ\]���">����ڼ���H2l�B�����W�&�+ZC����[���F�'J�I�)�|������-��'�F}�o^��Ƭ����2�(�8��}��ɤ�����>�|Z�����J�����h�%�ھ�v���f.*���ob{���$�Vl�fv�ɳѮ6�NN��%�҉�`�i(AxԦK�ݿ��V�a�^T�鍁D���Υ��j(^6�U �0D�8o�>�l; T��������iD�!:5��X]��S�O:�����Op��B�CJ�*�;2ʽ��Ӎ2����]�rhW	|N{w� ��/�Ԍ�/��Y*O3J��7�E�w�j����⏬^�����+�BEې�nQ����g3<��Y=��z�lZP���53 �rbn.l�ڞ��lN��|E�����5�&�M�ڨ�X0�Cg�FVv3+u��#d��
e�p`�����=q�DHY^���[�M)�N��h�lC)�e��ȼG�� �/̤�	�A�+�:�h�Cc�p���[N��Y��!�Nw-��1AƊ:|�~���ֲ���N�@��1�*#�P�KL"�(El��܄�u�k����~c^�<�ł�#��T�ҟ����F1,a%3k ��1���T�׷L��S��&�:s_���F|��Zg�,��X��]���S$Izz+O�_��fў���:뿇6��z�g��rM�`�|?����������Ӓ|��{o�}�$yk�r��z�\<����׎�ګ�1Q�?vX��`�p��v�b��V@��~B���+A��:(ԝ�8A���a�j��6�lA�#�|B��n���c�*����#.v*<-7m�n:re~�"���'[=Bl�2^��w�� h�rbԨ�&���qe�i�+`.�x���t(BR�h��9�pq�وλL�ҹ�Z}�o�bS-3��;"�d�4�Aղ����<�,4/z��R�:�9� �z_꜏�����"��)�LSqx��$F��G���9㾄��}'�ta�s#���l�����2�||3�g��2+4�ڻ[�A�a�S���/�W�֒v^���°6��Kf��o���<�a.��x�s��c!�Jn��_u/��.M�ܥ)���{}zhzՔ��Mܪ�0�`n$+��֮���7ͅ讯g�Zd��+�1a7�^"rX�;���&�z���J>��^�%��n�E���-H�R��*�_�����Z��(Vi�G'a��u$z��7a�TW.#����!�<�Ć @����8��^>T�f����#�ֈ��0�)�5Ve$v�]���NNe�Kp^��˂(~o�r�%;�.!���i�$i����H'ɨ:r[%[����#��V"8�.�>],[6e�~K{��V��U%9��mf!P��y\�[*���vhB�9U�n~a���l)��W��o�ؓ�x��{�8F��Qru���H� ퟤ��P��S���_#)���L<��h^Q�����ƭm'ˑd���`Ghv�Lp��"�X�ԅ���4݊��p"u�v(��5X��$������7f�ś��y�f5I�#��.�W�Z���}�n ���$֠V�^�G!���ػ��͋�_���P%�u{�>䌆��ڣ�o�G�(�-yB���ȴ�DM�0��6���������{i�?i���	>�O��C�:��?��eg�u4��+ǖA�t��\yGא����`�Z��Ϗ�:���Hjr��K/-�%(9��G��5ݘ�����@��{����xI���M 0�bӐ<K+��o��
�G�L6��Jz���b����F����u/����>j[�/֫��}�o��v;�x��� @u�8�7,��>��s@�*�3�Pll`�ޓ?�6��?.�(�tŎ�H�
���	SA����a�O9�ރuD���sK���d��{�ԀG辘�X1遥"��ɝ7�����kL��dU��Q���!-A�
_�$O��y �k���i1MËu�d�mW��JD�0x;��B��*H"�a<���}�I���ճ�t۠;�`)R%]x�� �t�
,�wyQ��P���+L^�PP�^ *>�}jY��Nb��*p7a5ӊ/₮�����G�/�W�N�=͒<���A��#��$���e��S��w�5}e�����"r]q��m����=���ϊͷ:Zf�R�}���C�0��<�P��.��#�`:J�"��v�P�聋�߁���� 	 �� l���}E�����}����F��O�5O9Y3s�>~MB�-_��>2���P���xULy����($�ԩ}g��Cr���/e���xY�#��	(��,�\p�̓�+�F�*�F��
iZ�e��,M9�P����\N?��pV��/�XY6*p�$��T%Ⱦq�ݮ�a%`��
��c|�0�>�H��柢!�4�p�3�L7��	γ�#`�6��i�نY�<۱B�:��u������F9�%��65۴��(�6&6K��8o��e��9�6)AzPF�s���'M}��kW�_빗�ތs���;�*ű���̸�vT���K~���ۀ�e������_Vo��t��W�G�������h$=X��A7����a��V�;⚢�y.��G�ŭ}�U2߈r�aL���$k�����V�l�|��� �~b�1)Re�}i����jՖӀ�c�#%$K�{.p�1>b���Dv?+�H;E����8�N���Z_޳��k�쪾��T�I<���p;�W�=L����`�%�����&�>�t����/�B|��ۚ�r�!�X�:�`�y}�9� T�A��0Ԫ�,�h�X@�����dh��K�oh�,YuW�]$�qS��H���U:�4��ӳ ~�'g01�!��4��/)G��أ�g�����n���@}+�Fo��{,��b�?�
i�c~��6I�a��	�stl*tYDb���wh۟���	�1�P~8�� �Q2H�����F\�Oͪ�<U}/��]�#�`ł�vh�|8�D��'	���ͣ~�O��Օ�uN����%�$EE�:~~·^UN��Z#/�|x����,�F�<����i�X�����Jo�4r.����|n�ZZ�F<5 :T�n�-U�>p:4RJ�����Ȩ��<��>��?]���s4�	��JC ���&&�H��49n�;�,�b�^kE��t�r�ft�Wb�N�Qe4_ 0"�L󅰝�m�$� �3����٪ܗ�{�N� 	��_�jQ��I�Tێ������X^����ې%w�Q�h@S\�eR9��\���f)V�S|J-�X�v��FA�܈���� Z�k���gKS)��ʺ�L�g�Y�\�\]aB���V�x��)KP�����G_��h�^z�!��k�Ñ�t|��vd�.e�z'4�GO������fm3]���Ό-!��z�I���XOjzG�p�J�g��)�22�Z���y^Ĵ�n3� q~��=�p�^ZρC�2��<A
�|���w8qYm��f����Y�	�pJD
�Z
���,ss��[��Cw1��v�ڐ3��m�<��2u&@�t���,>.�z���_�� �� ɬB1�ֹ�E�+mz����j��Uu,�/hi��%(��{)1�݂TݱlxF\��z�b��D7 N��vF�@݂����f�<��Z�4P�sS[�� ?+��*��rvW*)&�g�����2�?�w����3[��g�.�� ��ٲH�͚,�FmF�BI���S��ȷ�m������c�
<�^�IL��ړ�U�3#ӊ�����)�8�i g�����h�b�-/؂`E��p�0&�ER|����zuț{_����s����$�h�?��P?�ː��8s�s�7�A�"�4V�ymO�M21K,�;�T�[<�uK��G�7��V�W`xQZq1�/-����pܪG�Y:�i9�s���@a�Ozd��Tyh"j�u��9���͌����������P>H*
E��Z��0�-3�=�h�Rԟwmʰ�;�&��b��̳$���m;?Z��/P�P�勦a�,����|x�Z���l���o�������(0�IRr������3W ��9��l���>˳���� )�}��V�[�=,��ც
�%��`u���+l�/��e�p\�f`���'N�~�xG͵�(�v�28b��Z��1��ѻ!e:��VĿ��/�&*���:&Ա�O��RJ��CD�L@̊�̘��;{':Ţ��>����W�v#O����)X~ֈ��ܚ�,vC���C>DӺ���V5|R����r�왲B�����sh�Hc[��ß�؉Dn� ��3Sl��1��\0��Ό� ��/�&U�r&e��Uo����C�x��|��KO2k\!Ra����4�cV���*���p���#���,-�jg�`���C��Ҧ+����*�X�v�#L�H�)���^ej<,��A�#8g��$zP��~��"�}�"��E|[i-�Tڔ3��͈��1�Q�)�ZGs�%�W�n��	vg�*uq �$�sh���`J�We�('2#-fy��'|a�G- �ub�
��d��rΑz�=.��xS��HR�p~�)% �xUn�\ h�3�*�`l����3��	������|HM'�h(`�`e����/v�~k�G��Ch3���Q	�����0�%6h�PV�����44��n���i)���nS�z/��v�y���bd(��w���A��hn+뽨�Å�,�I��(�=v��N�rH+�݌~F��$��XƇ��<���� �?O��gT��3Ȱ�u~"�	U$��n�X?oצ��\��	�وχ4K���q+x�P{�p'G�@&}��nf���-�1��j��O�GY;e��`d'q��&��O��=��,5e8V���	�&1�˥��iY�{v�o�է�M����`K�˩^�h=o�ӥ%�Q����|MЫ��J��s�WoH�T�ŵ~��'�������U����C=���M��5�Q6D�;��\�&��~�As�t�4(7��8�������9��<�]&)�,��!fO�dℕ����!�-&	�(6�^\ÐN橜?äO�E��d��7���.�k��;��KN��isIuS�sw�ro����PW�E�+!��[D� �K��-��s�bc�`Dׯ�̝(s2#|�v���<jcD���}�Pz��jwx��x*G��c#�QF8��Ptp�׆Ԝ�tsP�KN�d|17�q�m�(ͽ¢�� o��d���jB����,;�ab��jDf<�t3w�^�]��I�-�=�>A�D����d8^�Eg�%���6h]������s���� 4Z�eÝQ�R��̲����Q�����
��>&�Z���G&Ոn1�+n�?߻Ŏ� ��(�mѦC�qwQ��,ZTC�UD�J*�g�ݛq6S��iۋD�㿻0	��:l�`�/�E&� ]��n-��
���'`yU�@k��ԮW3�\��:J��t���w`Ѝ��R������t�)��Rب�9���ƣ�@�Q��z
d�砅�M��z=S�}?�����|3�k����3}/D����o-[[Op�'k~�Vj=�]z-cP�Us�?i<�0�B��:�����4�ҭy�En��u;>h���M�:�?�����0=%}8��۝C9��?��P폱H��*k<���QJ��n7"��w�$q$GX2�������{��xh�2�!���)�<WH�$]y~��&Uδ��	Zd*_�Of[�����m]C���9���ʎ#@�B��Rr}��$u��C@܉�?�5AQ�f�(�1�@L������*�C6T��+���a�Ax�����%�)[�t ���h�I�]e��f%9~v0���3h����}� @�S���,�_tcT�[�N��۸?x��eW��u��JRb����Ut��4X��G8��j�g�"���jS�.��ҦS���sމ����2,,��<�,3'�Ûqsl��>�=� F53��h��ߔ��,�-��=ln�������(����P�U�1� �m��\�8�����}�R��u�;T�4:ѥǜ/�(�Pl���Z��K��}�ġ������1��@�X��6�c$�V�6w3Q�z���TG2]�(ʜd��;�W�l�zZ(�0($���1X ���V�a�d�C񪽬�uJV��|jcL��@��!�þZ@Ć@��Qݒ"�%=�
�0u��(����m�ܢ)����o�����a��ں��h�<d�)Y)�|�H��{L���x�i.�ŧ[�$��:FO$k��y�i'��C2��GJ���AIYH��!Ä�]�1A恟IOV�p�Lok!����RWW!������g�{f�Ӌ/�-9�W\���Yis~�Q!R�n�pG-L4��VY���?���ed��Ɔ�/�PV�f�<�Q�Ǡ-�Ǟ�-������IѪ@G�}�|��k�'[A!��Ç�8;�T��m�r�:����¹�^���Ժ�o�V��SW��!S�b?��FM%��Z��R��i�׳j��C8Ȱ�8��f&�#D�G>8�����Q��ҏ����X5jDNf8���]roR������	?%����V�p4�I�zb�t��IFtM~㥣=�I0Δ�/ ���fJW�C�l���:�f�JCfQ�Yz7P��8,	���<﮷vƌ㪶g-��$�O����4�Y-���8�����V����S����|�W����e ��W�U�>K
�=k����s4�'�����6Гԓ�C�z����N�#�c�ڔ�bM �¬"����'�է� s��!�ea�/�E�֚��i!Ξ3�gQ8������N5:u[K�>��h��[�.�O���i�"ҡ����qJ�<}^�R��I�+�4�#)Pm dT)�g�x�Dn�󦍺�Q[�YǠ^04��%��B��d�����
�~W�Ϲw[��ң:�l'I3��uʯ�v�����DK�1b�q�~�9 ��V�$:���9�7���e�����_}f�}r�B�P�cɷ�N!��I�ֆ_�H��QyS�ڤ\�V��c$��!%G2x�V���O�}���n�o�>h�O�^�0�T���u�G�iTJ�s�[��]���R����V���R6�n��JcH�,G�F�l�WT�}��1b� GVsn2���~�y�	Ϟ��'��_"S�ΞYc�	��)]������n�>䶗�6ƣf�I�]ZN	����%�U�O��J�y�w���QR|�ZN�%z�^�-W`7���!Ύ�~�+11����� ��A�˙��cJ���5�`L�����:�~���<��O8Q	c7�Z��ƙ~���㹣�q�YP�*7V�E���p���k�8��R�уK�'�~'�Cd�GCGPe�l�)܇��(���Z�.��?�`3��Y.`�`ײ�D�;n�[;{��w����L��Ev*���#�_��G����B�S���Nj��G��e�J�c>c��Y�W2ɻ� ����]����J��-ou�l*��c�ct�T�*��(���C�R6%&2����ob����x�%��F�^�S��v��EG$��)����ti ;��o�;�D�4[�������YijgsZ!�&�~�92F�\��QB`�pW�������*��O�3��L��1U$������#G���!Pv�~�䎼0b(�4��3\
yJq�}�AVxj/J�b�o���ENM����f4	V,Ri�!b���˛Z5V~>�R��c�P��p��o�Ϗ�l�S���P��,��9"r�u�x��\S����@Ƴx�u>=$}�ƑH_G�֞A��{����4��L)o��QE�J=�A��M�"���u�;ͰflѢ���w�����I�;�w �8�g�(����4{�gz��O�M��K�!�[ܠI�9����,�����1q��#@���c6ԟ�Ɨ��VR-25��B��cO��t�fu�d���u_ˇ���D�w� �>=��ȟ��q�L��%pY�#�� O��s�দ���t4��7*AX1Ҡ�+̹c�ާptTm�2]e!����à�Tj2=����N�Mi��w�_�eR,��L�L!5[���0$�N��]Zj��k�zO���+i����P����S����c��wWj��v6��Q#��.�YB�=��Y�~�sv��߁����#��1!��:](!��MɱY��\*<��;��Ű�w��
��ǜ�v�ds{~L��4�o���6^$�5�=Ҏ��Vk�_qN��"�����\ja�0�3�E��b�����5�{�}e�֝�y�!�&��:F��@�J�n�i�:�=!���G��cxt�U�hQ3�7��پ���V6{,c������]8M�t��rZ{��[{Jd}"���Ϭ��|��u���:�	�=�R��SV	}�������S21��9�,��q��>�Ct��D���C�C��2J����4jہ�E��y�J5�щ�H���[�g&�+K�7��鸽(w���ƔU�pm��/X.Q;e_��<w���K�:��`f��/�B���Zܸʬ��ug�En��MU[��E�
b���]�U�f~�x���l��A�J�>&��ykvmK�{D
�0�~��yQ��I,I(�X�d%��
v��չ�Se�y�*��G��'��5�q�=h���Ys���f�&��%���ji
2C�T�6��x_�| ;h�r�<�F���wء�"v���ne�c$BZ�����ͱ��Kdp�)��q�o���W:��_2�4�g(�G�yJ��/q���@����E�����,�5���۳�U�?��޹��!!�܌��m)�X�T�sCYyP���wco"�>���|k�4��hZ��LCU%����T�-�>�b峙z�1�X�֘&�9������,����}��UK�U�ҁ>��IO�ݜt'>�fN8�Z.�8!v�L��C�N0B��_�avA��1~�� C�y�&9h4��тfF3���s@1��Ԃ� s(`a�YP?�&�bxY/��:SJ(Oר�֨�a!�c��q��d6�ȡϡƚϰ��غ��c~�P��1�?rɉ�S��>����U2��4~:ne���m8eԏ�c_�
���%����mr��q���E��M�}���`ء`����1ż��ŻM�s��@{i7%�^�y�`�V%��.0�}���t�U��Z�LʾlF��X_8�TME�U���s��)f��deD]C/.��:������-�/��d�8�p�x��
1] �Se�ч��������MÐ�6�3�S����U��Z�����ID@��P���G*�]�J���)���u��1C�A����n;��f��T#~c��D6c�F{��rs���a�*��}�Rb�Ē��e��x)m�����ԯ�'N��ʴ���H*�o���ۏʂ��� 肼ve����0g�7�'|�4S�&��H��x���"���v�Dn>�f�׊9i��|����O��s��,�c�������l����L`i���u_]����Ħ(7YqA5�S\�rz�@�#���9�g"~�n��ڍ�X�bu	�\��������w^Ot�*��s�M(��p�#�����X[�ʉP�G����U���aDOw��GFʕ�R&�A)���y��p�wT�v0��!-$�vU��CM�X|L��1�{��}�yg��J�y���������u�5ǭ�-���Sl�2�}��Y�e`�Ì�.��N(��6#P���~�Ϗ�U��=�
�B~XF�xɤ�g�%5f�v�=*^iK8�4��S�z�s�\`�+���d5�Ys�� ��#8�FK����=��T�7�.SJVc(�orN�l����B�n(V���:ňV�E6�X� �&;1� ��&�am��T@�V	T��zd�As��^�~9!M%��N�V�/�D�ޕ�՝/�����kd�)�j\a���fg��C�����y�<����GP��=pj�L
0қ���h)
�����|/Z��e>3�Z����R\2 ޗc��V�B���ѥg[2�ڼq� K�euF
ԡq?i+����5���ܵs�^��8Ƕ!�Ɛ+��IBgvྀcp�G���r*:)<m��<�&����ï-�[��ս�;�����7R_O���㯺�F��������J����>X����-��������v�<>�{�Xx՜����|AD��%r���&D�2���.IƄЇ }��2>�wBP�1	ja eqa4���
=��V���{!�Ƿg7	�t 1�X!b����NK2P�u��P ��6�/��̶KX$'l|>���[c{���Z�؆�S〒�c�z�l�K�{�6P���Uhqu�Gng񰭪�����+����`�3�3*{�H{3̋��A����`�j�P�f`݅cw5�H�%AY&����@�WL+�,/��Q"�v^ҼS3�<ad�9�4�q��&T��ɰ����B�Ҁ���H�(\j ��b�U����Z�E����`�G���	��)A��06kq.��&/??oA�Ԝ�ʷ5=���ٞN��JG@���R� &+��!�n�#�V��Z�~H��?�o��q���'�D�^ܳm�y~pwIsc{�h%B_�Đ28lpH�^PD��6��/P��xsDW��0��GG�Eշ��AV�j��*�J4�]rt��Č��k�0��%��@P�I�Lg�4����Ev�畯c���C�z�y��/ \uBzÎ��3�0�a�f٦����8b���f��
�FC����Eb���XK��B뚷3�IpV�2y��U�*?���p�u��y+��i��{����<\���|���S����E��=Q0��d:y���uLB��g�-���t�F�����,���m����\��%�4>Z�&�K1G,t�D�9�/��� H546i-��@HW�DD���z��~* ���H���9>(��Qp�+�׾���6P�?Rr�e[��W�I����� Œ���*�3}꡵����K�h�~�%CޏB5��/͕�y�0ey�ûtbۓh7���cj�¤V
) ��n�]tR�ڜ���Ѓ#�O�94��
��.����1�1��LS�;	��������a�s�:�uvGO"�t�L<���>��ԭ� D+�e��k-���[>ޱ�"@>�j�+c9���O~*��?p\W��.�h�u��	"7 �ѩ��%���y�� $�V����Q�d��7?]m��ǈ���/7�m��*AP+ۺ�������\�pg6��9,t[��h�~�EZS� �@޻"���ћ�t����L�#��n��h����.o�8o����+v�pX��^8����ue�#���
<z�n�
�j\�wPo|�c[d^ۖ���5����'�e�)`���{�
�3��5�D���n�XK�|�EX�/�]V��'�{w�����n~�0P��Y|v�tnM97���;��T�z��`��L�#�ڕJ�q�7VY�:���^���_�]��*��(��^f1�jIa�� ƃĖ���M���2�w)��͚�\��&`��?���e��&b�)�O�&������ ��G<���o�-�&m_E���|ʣn"�.��;���+�9���o�,܀I{+��q���zo�ڀb���L�R�=���޷L��pwo]�����@e&���E���.�Vw�����_ux9�3dc��g���d���'��:cl�4c��O�7J�CjI	^�7��~�C��v
����#��!~v-��]/�Q �W�tt�?�^ЀG��&�����_�E8�Ȁ��SA��EYF\�Y�-�D<���n����U����%�X�~�)/H�^��x!h5�Y�l�ڟ�>��޹��<1�p[�<޽:�#���\�l��zm<���(3��i�ZiEϝ�����K�P��m*[�5�%gS�Tt{_��>�4�de��<�����l�#K�A���b��T��:\��<ĸ��rB=yDW���#�Ɉ�iC�>�~��z��	�l(�*10:iǧ�AL5�;R�se=Gk��_�0��j��g�\��5|X��w��5�c�S�t��4Z�6/G�S9�������> �b�k�|������Q�&�j��i���~��Rp�>�����cv�|�hB��[�`LW���Z0j�0I�̈́���XJ"m�ؤ�_��@!.�3�SH��<��}�R���<�����B$�+af�-����:�]�ǎ�˃�*.�;{bf�НZ�J�ŎJ��[;�*gv��i��y�N���RP�pt �&���F���[:=���A(]���*�`N�H��ۊ�szP�	�A�-[ݯ�-d�8��d��a�a��^�0����	~1�<<�����`�$��&��UKU�9%����Pl^��l��!�<��e�z�����K�1	���HO�u��h�~K�>�W�v���[���h��=ɠ��q
f�y���ȡ<4>�	f؞I�.m��'��Q�HNy�Ս�JLn=�.�����(%ʘ�u���k����>6�ۍ�^h8���@9�gouJ��^�q&�h;mz+E?�O};��`��t�lr���z�����Ӝ�����]���;,f>�dQ��u\�8S`=.cwM�S�@�=������z0n�.�Od�o����^),.��y�ڔ�ϪQ�F���ҥx�G��`�ɺi�_ā���m�,���"�w~����f�[X~���p]â��V�	&cM�I��؈n[ӟ��z��A$Ѡs|[�\w̧;1^�O�f�$�rx�*��J	�D(r� �m�TS�('��/'�_zDmQo��$���)Ȟ���XYa�2A���4a�##�7�9�K�9�*�Ѱ!�@��{~x$�\����[�p�Tq��1�Q<�sq�r�%=d�
�.��f:���?]p�E�xmbę����R�)�ü�G��Q��υ�mW��pw`s��Y��;ʮ�1ėH
5�=�ts������rɨv
�� VP�v��P�ZA>@=�!M�o?��We7�M����z�x�oz�N�k��!��W����fb
�vB��B%W�V�cN�	�Ol#�Cf�'s!/_0�a8�QT|D��ɨ� >#���B_
�6&��PA/ق�����r'�N�E|�q}��xt����t�=�|�}��q���!qk^ȟ�߳�?�O%���mC���3�taP�cP��(��qě����e8G��w����fOkqH���1k��ZX+v�A������/���X��9w��QDjx�˄�g|��2���Yޖ���u����@��5t�����׉�Ƅ.����.H������rf���LT�_�_������Suo24v�ԛj7ͯX�3f�_/Is��+/���w�uq�,�5u����nR���5�o����`ɂYd����d� �SN�lω�XΙ�堎:>���8xH�Oq��>{���S�:����I�u�)��$�U|Pk}�O��.�.��D�G��G��B��0L�����0mqJ�FK����S�~g4�j�US����%�TF�YnRZ�R�ʀy ���t��%�^�=�I���+��j-�u��#����7Nh.�l�T��s˞b"C}AF����$P����7�׫Jb����=Y��i�ZtY��N]W��"crm��#V��$pm1^�s��׽٩nu�{�h��̀����an���;[;6T�6#��vj�!)�HA�n�b����@ʋ.�5\V����-���o�';�Vʿ���O�=F�,�.���}e���h��H�84�d�f*�nn�s�~�Z?����G�ў;��-�fC����5�U������>Á�vR�8싵Ix\�F��f�8g�4(��S�����{���n������/�`�</ԔN���C��.g�:�����ڳO��~ih'�1�e����l�����#Slu��#2���fg2�D���(9^�~8��%ڞϛ�)NJr(\���iW>���-wJ����v��|��oPl|܌�7h���:&'z��*�6�`j$Ў�I�����*�8�1�R�僡��9
��0����Fb��܇V6C�ȃ8���`F҇��@Ae�[@�����א3h�����H߈2{�Ը�Z�s|c�#OaUu.R���Ŧi�����N�<�Ljs���F瓲�)��29Q�Dx����J7͓�_�r̢l�[���0��Yiw/����
*ZL�Xć��q�[
�T�3F*�7��Y˦
��A1U<A�c7�>{=P���<�ŃF<���yD"��N���%�TE�)�wU5�ȈV�?�.&d�l�H5�	
v�D_��$��U"��Y��X��2:�QWC��}�7>У"{�v���Y���Nz������	c��yMat=Kl�y��	�s���F>�s4���t��8,�y�����|g�	�o:��H�v�J���t;)�}�0;K�_(
����H�,Q��m6�Z��MsQBW/��Ä�%�S��}�%gK���i���3�2n{�Q�4�"jBM(� a	�RI���,��m7��<��ǘ˚���>�Z����"�g3j��lC���|ǵ/�z��DW۴����?����Tyl��N��_�TP��N����C�ѢY�
1���c+P�M���d�f�2X(=
��q��<Q��� ��I�Z�:��� q��A�����_������޿y�:X���T��;m� �q}�b��6�u���U�R8�������&��Aĭ�|�me��S�}\X7q�I!'�O�}P*6{�7�rf+<L�%9z�gX�������(���'u狧� m`�I6$Z��o��q�����D�O�.xF�k�y��s͗�z��2���V��a.8��f�a��w��j�z�
E¯�֣���o ���{ĭ�RY��VҶ�!��K �]N;�k���f>�.A�>N2��u�w�Ɗw����C�w�bjX�C���������>��G�E��(����]�Eמ�9��_�����S����|���r��WI;yR�!� �v�C���Rk��_��(�q_�:A�ki-[]�C)�������	�~;�h�ļ$ؐ>ᖟ�[�9�u�=|�Tl�8�c�-H��G��mx̿�1�����cL�vl�rȦx�)GQ�J��+i�O���;�
�0)�B�����fuX
:�u��9�)�r�`���H	з��QLB~��|?\��>�~Yz9J��øy��.+/`�'%%1�|6|��߲
5���	1�R�d5� 셅%4�$4ۣ���+1 ?��a纩.5����F49r</�G�G�����R�lY���&�օZ}1=�K����2*�V:��c�D}Bu@镑�G�kђ��R�͌�n�& h#(]�:]@��R���H!��*cJ�[e��c�ul%�߾�[�a����Ƿ쯱u3?��Ls�<r��V��T���t�xkA�����2usY(�V/:W�4k����&��ɮ�*A64�0��@����Յ��0/��b-��Mg����T��]��k�X�9V8�s���l��RN�v+F�(�W� 3�z�����d.>������YOي����\vX��)��$JC-܆+�IH��e� ��N�VW7��'hXhDuT���ո��Y�B��w؉�q���+w��$���)R�!z���c���\���XP��;���p��ހ5A7�H�*>�J���G�M}Ca-<�oS�4v��;�t���]���?�`LO��N���To�ae��ͧ��WuAw��Q�8Of/���8��� �w�Dy�;�S����}7����f�s=ڜÁ꾍�"���Hr!Ur��ߕG�Wy۝֋(�
��lnT猫q���c�!�������<o�LQj�'�D�r��h(؜�w6y�bk���ƌ�%�2��S0�Ń����P�sbn�����_I{�)[��/1sX`��%���8 FA�MԎ�`��o��s�o9���SO�7:��DI�|�uI�����4��a�S7�8��@��Tʤ#�bA��; I�A\���5����g�NU�xj��C�^a;��g\�4w��K��+d�*��hv��%Kǀ;f���K�c��%�)9�#5����fk.C�a����l=����S^ ��`A�s�y�6[R���=��<�b$ʟ��^ܑ< 3W=������7a�w�.�d��դ�֒����{zؒN�7l�J΂rL-|^\o:�$��T7m��t8�mҟ�����+f��`!06��z��H��4I`H���$l��%�gx��AӺ�EX�K툇�����.u��̶\1���`�f!,��\�k5.F�_m��ch �V{H#�V�|e��e�-��ni�*���Z[
8>[���6t{,�D���z��n��qO.7j��!gJ�#��>�,��X�Go@ֻ�W�~Z�/���5��ۉdBd��l$(�0*-���C��6�4H�vgP1���2�u�7��$�'���~o\>+�S(���I}+�e�>7�c>���:ە �O��%���x�R�%rn[��%4p<�VU�9Ş՗E��B٦��c�$����7}*	HSё,�Z�g�x�"�!-�~�c�O��B���:�����^xV�����St�2S;r 5s�+Y�}4'G�݂�ځ�r�E\��C���������D�|�õ�\�d���?�L��))-�:>���*� r�7/�U�L~J;o�X���X�{����	O��x��4֢�L�qt��m%퀍�]�q򂄔*{�V�T;r0	��r)�֑�~م��f�j�_|@���X��	-��4	L��3�7_A�`�k�z�����o<��;[�>u��v2RpL��s��P���r���/|�r�i�0[dx�"�+^5�e����U��@��[E(*T�.'�+Uل���=�[Ǥ�AxQ֏v�ZJ?�l����93�¢�/lq��Bݯ�;�c�3����RB)Ӹږ���m}|_�B�78�1v�4Ǘ��7Cg�`O�gs9��:�����ɧ�ߐ���W���K6��"��Xa�1yS��S�]�v9� ��ܭ�A��nT����M�3�K���K�c��F�|�4@V��Oo8���A����3�DZ��0
�5$�D����_Os��P5U�0M��2�?b����".ߛ8|�&:�,��L-�N#�$���P�WrQ�S6���a��O8��)�g<��w�rNy�a��ߤ���=��>�[Oyhn�k�o!$�`0�Z�S/���)�*zn��񩻫W�����l8�b��=���(����Msjfu���[I���̝�-L�ѤtP�r��b��6k�&�wi:���qX���𼏛�l�9֝���D���ˊJ���.� �/��ڰa��*�����/��� �.�肝Ә��Q����
Q,u��׵e���
�P�-�~�*�8U����|&2�뾫@<Z��Fm��Ђ~dJ�i�� ��i�Q�w�c�,��]���+�����ے�����bD;��A���ݔ���'n�c�e, �����s+%��n�U�S��ve4��ef�D/ŝ��mLe<S��LH��v�Rzk\U�s=��IE!��dW�ifm�6�M�:������j���Y�1��O�޳	��T3���6�*�&pE���BT-��;�����2
��m�{���&�h���)([���
�7���΀o�c�m�*?� � ��CWk��� �~z����y���lA�X6ńe��������>!�NLi&L�ef� ��ܑ4���=(.� ��u�ߗ=�  C�h�8�{� ם���~���g�    YZ