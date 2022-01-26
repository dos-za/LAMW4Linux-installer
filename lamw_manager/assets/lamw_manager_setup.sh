#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2080498477"
MD5="06698b276188ee8960f994c6bc1cb76f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26028"
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
	echo Date of packaging: Wed Jan 26 17:11:26 -03 2022
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
�7zXZ  �ִF !   �X���ej] �}��1Dd]����P�t�F�����1L,��{Y�c�e8�7DuwT�i�Ti@��0��M�o�����a��S���o���$�1Y��7�2P���x�ͳDmP�&��A�f��B���ޑ��4���̽>k���߻��kw���k%���d��l�o�����,�;9���t�Cx��r<r�O����"d�l��=`5b���
��iQ�g���I8s1�-�B2�A�n����8%�X��;]I�{T�|!�$ɴ�=�,��]�FI��7Q����_P|��Mō�>��fh��g!�]R0��z=��30�9[����5%/�ٌ�q��p<�1V��
�h�vҋ�B�k`U!G��|F�C����㚎L���߷<gnӃ"O �0 �M�&��-Z�<������g(�<�|� wC��F0���%�Kp���|��R�jö��ŝèG�5	��w�^�>�_��5����'o������j�#����]����M���@\�_�w��!\(�K>y��RV�2>�Rg�>E�&}f�����3��G[�p'��N�.��l��I��qn��G��.��v�U�s=n���>��]����~������|��Ws7�.��D1�*�ȄD/Ɠ
k�2��JqD�?Ϻ��p��9���jM��N}(z�"f\��>9V@��An���"��ᑣ��E;�Z �1�$���#+$��c,0
~�^U>|wʀ�FNJ�������,�XH��,A���:1�B11ێ^�KQ'��/x�1㺂���z-�W��0�18�
�_e�I�S[�c[r����D�c��A�^Ä^�uԐ���^����e@A����Bʥ6G��񗳡�]E�M��/i�-��<��Jpٿ8C���Q��J�?+a��H]���	L�"��7c7��[K�Fmd�G�2��?����n��`䍷[+��G+�-��J!O�g�^�<��K��	���2�l�YB�4�����~Ҍ�!�8�.�|�җ�BfVn�����Pu�L[9�Y��'���O%P�P,���2��?�h���G�L�O��P�`N`��Mm��)l�<�kL:F���&����kE�SV!b���apWf��%-n�����i�!�;�6�k�,`X�����h�a��nR1��pK��e�
U������P�:��g��ZD�N�ja��Q�E�u|�wT�	��u,�=��Tp���B_d3��xsĆ"�DT^w����m9�T�m�#�|H��DЊ�G�� �>�h�;p���$�h[���R���}L�h!1^C�rm�!�Ò�ا����Q5Tغ�S�cw�n��)�
v�=�.�,�̠>�+�Gd�.D�^�2ݴ�7���̉�_P�U`f��p����U�a
����Ǚ�Z��-�ӌ���ʴOGE�9Ƶ�r�S��I���in)R'���.|Da�e9�p1 z��,G�k�o�.�쟼��d��dS�:�Җ���� �ܐw�Q�gU!��k�FO���@�9]������(-p_L�(F1�B���ъ���6�"RC��$s�^y-k�)P�8��%Z�՗��ke�,
s'�]�|C�]�A全N\���ÆN��_&��a�T��,F�d��Ol8�,Y�Jx4HF�����>��x���O�	g����֋�pa��-����(�2���
�M���:�#�;b������Sǚ��0-��;2���~��LG�n��>|���rΡ�l�,����F��2�=B��p��;Gv2uJ�����d����ZRԶgQa�Q�UG9b/MT}�|KQ��*�N�"l�,��S��v�NM&�r^	h_�76�7{�;�w$f�5���P�ΛM<�|�����Z���Kl&կ�;)<|��P^��d}N蜡�HKi��}�-y}#��ңIܸ��+y=Ճ�gS���z�����N}
���3w���_����S��3�}MT�N���ߣ>ϲN�j~4!<R�k�%��K�ǁ�3�9"�7HQ��e�W�'��r�L=h[�{���j�%
`�*<���>���1gK�	�U1�v��B<��؝K��]J�-�{UPi2��Z����ߙT[�o��S�_\�~I��)���lh/�:��ã+���1W�P������nd��q��q��r�Cpr�}2y����we�>S��&B��(����ON7aȅ�@��Y!�p�C��Gb~0�C��$o#�Q^!sfiQ����'rHf�3銣7��ѥ34N����Z�c���]�q-���N5D�t'�
���|V#4�1Y�bF��8�j����	N�EC��,��T��2(�^�u��R4���FA���� �HK���N���pMv����>1!��T䜪�C�m��Gp�����b�8���T�}<�(�ch:�ђ3C*�Þ�}�}�A�������s#�di���y@� ,������5���(��ߴ �ML�"�p�^t�#c`�Sk`�6�N'%���@R#P\׌���?(���K�HQ����+{�I��!��g��6r(/�[��G��㳗�Gz*��Nhδ�h@
��{���=���/bQ
A���臟�3퇴�R�5�{D�,�#a��bD��(��t�H���(����#	�]��$���i��>-���o�Gf�}�l�,�Z+I	ї�a����t��t���ؽ��?'+_����ăFj��:(�/��Q����z��n��U��:�>_��	o۸�3��v�)#GG����޸�1i�zW^��;>���Wsb�����/]G6��p�j޳�#>J��܅�}����Ǆ6�j�3P�cOt\q����Y������#_�2����B��zd���k�:���|)|eb�l��æ����G
N��ˤ&J�KВ���jK8����[S�^H�2�gK�����X��(&<DG���F��餔�̨��TKMs9���"i��|R����
H�b�)Y�#+G4��D}�Pp5HLs:�z���R���2�Z�M1�Ww#�}��r�r%�����Sa�A ��!2C's8��?k�Ǜ�a3��	!Fd~"{@GC^��ٍ��Q�A��0�ax�ܨؚNty +�?�C��3��%��Z/���^���5�8�jVn�O�)�?I)$�njֵ�L⑄8�u�c�2W����ty�n��Di�ƶ\6Ϩ�����4�	:��@�Ew���qTO��qr6HY�Ų����wZ97�QE���}��hiI`e��'���,�%$������ep���ĩ�	R6`�Mqr?Q�<k��QM0��s�+�~K
h?�Ն��h6��k7R.K���Nt��}V)���=��e�������&k��mղ�hC�I*���Hd��_��jp����;�;Ĝ5�;0� �m�
!�o@��^ދw�҅����rB�'B\�߼ �14
�2�$A��~[$}�C�t����O쇂���ï��rC�Z n�؋�Q5�1�졶x��$�qSٛ �ˁ-��%�-�� ��3�����6��
��^�˥Q��I���SgV��'N�x��D0��I#�4pwj[s�\�Lx��Y]<Ucc@�����Ѿ�i8�#�~�jH�u�I�D�zz\m+F�Ul�B^x�U��H�l�|���X?~?1R�^��x@^���J���ʲg^����q�d�BTsځI�G�3 A�{0�4��@��;�7�ޤ?IҰ�����O͠Yc���,�ޔzu|���4|�a3�0��$��t��EZG�b�bmBA��)'~���_�G�qE�2�3���
<�@ ��r�:��Yu���
{�n�=�h���i�G}����s�{�2�H��q
����u�����N��� dP��J�Tf^�5P��!�`er�c����{{�:�±_0 ,��쬘z�e:j쿞�r��>uL? \/C/�N���5��JM�C|���UB�@ǋj*[-�x��0� �he����H�UER@%����y���k>%I^͚��+ ��tf^=�A��/�#Ș��Ggka��DI�Ҕb�zE�q��o����b�Z���^H��H�����]?��`��8�A,�$���!?ŗk���c�ֹd�lu��ש�~
�G�,d�EY��ª�\�;�䰞l����u+Hoc�ᎉ�!Z�B���1�#�v���z��^F��'���uF/��炐�W���Y)�!��G�}5��탍u]�y�3߽9 >��J�>݁B��n�B��qmy��H�n�R�L�z�b3|�(7QP�z@w��!6II9�ߌ;�q9]����+���Z躕0���bF^�Z_<<�Ģ��
3?��թ��WȸŁ�s��7��烱Pi��	e���g�0rjӒ�[�& �d�s�	ĥ��0^6-�qe�M���	�b��$>������mT�	Ň��S�U�J1=�|R�"�u�j�0�c|��S=Q�����&�Ϲ �z���&8��p���0]��Cj֠��!��A6c{2�N��	�������-bv�p-��������@E��A���楹N��7���w�9�?m鞲a�=��B�����2�qY�N���3օ����,�Q?8%��^�u���������a=�k0�!��A���F5E�j�?�	1��BN������m��=��H�����L%��7�Q����1�|���Qúy�DnN'�ӻ�ZM���#o�<��Cq;]����>�$hP����E�r]��:gbO�1'��kC���Y_)ڄ�x�~�_ �����嬊f�=l�t����؍�@�ճ6$Wo��2�PK'��^a����<ށ[fq�Ҡ<�B�ȱd��8�+�l3cFZK @�I�+�P�{�g̦�<�u$�!j�
����i��g�J-���:���Y ��:�9�e��t�O^����_�O�]u�Nr��m��S�l�~*h�����-��)�KxCH�Ɯ�\XX!��N�}��+a�fG��)'{ܩ(�U3��{+�����1~�h���Ғ�s>�#j�aw�7�{T�0	`օ�X��3n���kcn/$�jYUN���3�Պ{i8�������N��ò4�x�pm.��� �V>�����Zڞ@&�|W������m�Y�������H���Z���K���:��x	�ħ�����Mt(�k��������I̋��ޱO����o�����܏�:�9_�lX�@P=RK�T�cT�I���F
�uv�J�7��0mBU����R�<�*p��y�)��͑�_���2e�?��(퇫�f�p��sv7L���q3���l,i���>�_�k��Ѧ^.�JO�9����-�
(�ܢ�,�z��ޭ�8�''�O?㭫�#�/�渐�zJX���	`�\�=�CL��(����{n�>!���x�|�:m�߬h<s�i�;����n�H��<�k�/�bqJ���[�.��^�?o�ź@�@By��KO�g����R���ɞm�'H"2��ֱ2�S���C�1�$�v�A[�R�fzp�(K����;d��
V��M,JC��0q��e�n9N�羶���س$�		�Ec�F�iҊҧG;�[�܆�:�֙}Iku��Ѱ�M#�3�V�3�9~�L�jr,�oח"mj�B��@@��q2
�LKv)�髯w��GS=�!�ߤh$���cy�>X����ԾQ�Y[Iw|W�Hh��Np;�'�7J7w3�0	SL*�NNv�^���BM�2K�B(��iwjw52�k��^*�^�Ÿv���ixgT��d�l� ��$��SN/����`�!���^y�T��z�q	����,��`6X���i]�l�g�ޞ>ة�$��1T��xߔ���������]��Dljf��0�QЋ�
��nD:c���A3�'+�6�AȄ����]��9Y�_���4}�K�ë����"N��=�k+j� Gwm�il 2OQa�yʭ"]��v�^�7EC����]1�i�N�u�Xwjp����ߠ�Z�$8M����+&�C�[�j ��Z2����9ܢ!���< %�l��z�l-��o�J֣��</�)��;2��j����e�}����x�vkrD�}i�3a!.��0R3ҧ.�e>�Ov�V>���,����}�<�-wV�K��j�3�Vk��猊t�7[�XN΅���g΍LU/Y9_J��̮�	#5���DEC��j���]�rfq*��km�T�*;r!av�P�}`��0��R"��B"7�A���)�8��[ytbݭ୦�M���z��*;��/���$�� sL��6�e"����;+�E�m���f`�W�'�e��<�ꄨ�,����Fk�A����)�%��������u$R׺�r��T/�4g��u����]>���u����G��c�Ls���u,�v-t�0�P�P��B]���1J����1���/�
cI�uϑ�H:��kk%�^�8��hv����ycO�i��u_�H ��M��
�έ���rŉ�kŤ/:�R���T�������C~��خ�t���Z'����TSeO��h.c��E���B�e�������_\cw)��E�J�@����5k�/2�3A�t+	��0t����!9s2p�1����FD^}l������)W3��WP�I{�EU�]!`Ʊo�[�1֞�{^��|F��{F&E{Y�GT3,1��t1i���wu�ɗ�%� �^dW���2S���81	���)��s��QC�>�._�eC�p�7\-��^�AވSԭ���J��Q�v,��`�)�!�v��F�����fg'-��[_"���њ,[�N��@5	w�{��v�^,�e�
,_�{��ý�6�!�Y�rKI).�h02���Jt��6V,V{@Ȧ��/��R�C||m;J��1a3�q��9�z?� �eS%�#ed'�B^��ų`���lP2�R�?��ʓ�6�׺Gk��9/�K5�_�+KxiNW�r�?�ځ��S��:�2����uB-M8yoy`y?�F�p�ƴ.ڎ���m*��*���P�=Q�@��F��(!���p�6��U%b��5���/F*�!����C�@~g��#��!Z�jӵ��a`V�攍���_ �Ҫ^���8mL.����'_nv8�d̏G�A��e������
�.F��Z�y�D���"l�q�R��
���Ct�x���e�����	`+�z:Yi�M���P:fNSV��}��D���\[�L��Gv�瘋�������)E�0�^������B�p��ktEH��+rw!��q� �,����ĩ���Ŗ/��܄9�VzK���4ƨ(��x
Rz����`�`����L�Ĝ��������X�B��G��&Gʗ����oA�����#��W�o=�v���Xj�Sw���Y� �A��F�C7S_�&0u��9v)�=�H����Jb����1[Y��v��bzK.i���z����~;N�^z8'�ZX��8�iG݂��������<N�����0X�FuPG����#C`GT�԰�G�m2�W��9C�Q�=�x�Y��KB�W���&a��]��-�=*-����g�F5uZ��t��#N�
ZCsзݘ�Nxf�� A*�#xt5�hF0x�yl,�/��<0/*��V}t�'V��VI{�L㣘w�J:2����Thx���cџ0��
J����U]���^d��_�7��p���B��"k|��睾�M۽�DW`�j�P�r_E��,riE��+�9� �
;��7���Xa�y�2l���VWU���,F�a�%w���>�r1ԄH�Ɔ�}%�&��K�Ƚ�� �������x���ь"��ȭ�2W/߾6����P��ʑ�Wm��Q��e�	L�sYJ/A��Y7�$�ױ��O����.Tw���6�c�c'�*D�9F�cm��+'�E@� o�����k�	li�
"R��	Ā��܌ �p��kh��r&�Cp�_lw,����F���x��MJ�[�儎];o�]�<�V�U���:Cgq������[qnH��_n>��n�[�R�đ�v��G�m�?�S���7+~�<�RBM����N�j��C��3ʺbЩzs���%	0������ԣ���Ԏ��HP̔�6qm�e�̅���L�)y<v��3�+�~j��R4���V�r�F��}&�IY7��z�?����eIlV\h$�+�"&9�O��io��Fؑs�Z$�~{�yu���[�8�t+�-L��6�l�;v�������[�6w2���U5
��r�)I^�b	[�'��@�@f�a��K����8�6t�N2�����Tgcx�z>a�k��HK����P?a̂�b��h�<�us������&T��TPv�cX.NbuL]�N3�e���b�jYB��"u !���!SGS��#j�Y��,i���L���V�Nm��U��lSH{�/t,���v��˂h���Z�y:䩸���g�N��~����a;�rd�I�S8;�"ť����&;B5yN��`�S�@a��w?'�d1F�s��ޚ��P�͖���r��o�O�����{�$!���Q�&;$�A ;p͇��8G�Ű-����!���ɇ�����!����?���# ����F��"6<�����U2�M~L?�����p���x o$�(/»�%
�SL{�c��1�C\�D��K��w0�ʶxW�U�o�β��=��b[��ƭ��	
���d������_�����h�Sn�(XG�!�i�����n4�uk�h�9�}��e�/8z6 &)�ʻ�Ρ���LkE+��r��aӿPZ^�;h�����/�ʀ���=~��C�J�O�GD�o1U1�K.x��C�ʗ�H��տ����ލ/H�5_~~�)�!���� 6ds�8�Q��B.��xC:�p�4�#���M�t��C@���F$);>X�0����8���C�=r*h��FW֙R���I:r�,���y�<7��Z��EЯ*�s�G�Oc(I�C2�9��b�x NL�@4�k��6�#�� 	�����=�d@eq^ђ�@y�l��0$�� �����C������SYa����sQ�b+L��f錹��Un}jS��9���t�v�:*(w�]S^�FU�f
7�O���B�(�B�����Uk�^jO�kotee�j��,A�W��V����L~b�]�/������t�>c���-�>@ׯ�+ʖ�wJ�~ ��' T��R�cO��?�/��3�@�S̾�3�4���?�,�;�T���op�vqzr�k�F&S4�l���PV ��ߒDC�#�>��$4���A�nr1�y�t�e�5h����'�#��Qx�I�d\!�ns�a�<C�aխ�2զ�+�榅��Qb�y����k�5���O>U�@��D��q���x#8���ڒg׏�p��^zđ��v���n���&UQ�ǘ��&��������t���C'�s����>��"�6Dl��^��!ҧ������Ԅ�O)����]eK�!�k�V`����'�$Ɓ�1��q����ɼ�Cx��4G��[��mw��c�LE\��b�̪X[q�s�P�����2�jdN�t�}��5i�E7���W����o���Q�T��+���k4�C���ɮ�g��5�o��}��ʢ`ni^��"�W!B]ȆɊ�9iz���-�yf��e_���?w��;�蚔�X]�:.Ƌ�"�׉LT����x�O쉬��Y��77,H��s7�Uu�@ͱ{m� _T�*��	`�.���@�p�\)V���T޻�������d�+��(�YXH0u�#���Q	>�C$SI���>${:`"����\� v�e�_3��� m�AD�qG��J4�]!ڌ�|\��{>����+�r���l3�Zտ��,���iYT%����Kp(��M��SS���ؒ&ı�-�+K��^a�epYUBGH��Dpn���,T�6a�"}�p������\3�
З���j8=8�T��t�8����j����}�qvу�A�3�,��U59�[����+��AO�b��U'Ԙe�3 Z}��+�r��lVY�v��d%����	��TM�v[�O|�	�R���z߫�XWO9p�dןrFnE���&h~`R,l��&9X�{UT:�ZcBO`�Du������ooH��;���yH���ol�$�:��{�ߨ� �۩QJ�I���?�!�)w��`qZ��i���(�c������%���0��v�˭�8 ��v4�p�BD��V_@��-�ԫ�2�=Kr�'6A��nUuk�3e�����d6�5�;��ʍZ�ͤ4��A\�$�H
���?/�����gV�!�*RE���K���J!�V��}2>gn�
^E?&�|p~Q�صP�FZ���H��O*�v�8û�����(���PȩF������˶YFO�������I�����A�:ݹ(�O���5�>J�^:�Ut{�=�"���%o�Z\�=
lsx)5�χ��)��	�d4�b��Tw�>�6m��:�ou;�(3�,��+4�s�޵��V{eT��9R[%��7�u��=˫]��,�Ǔ���$�m2�l[���Q�D&���eA�JM��͐�ܴ�ūSo��J�`F@��)�e�4�+'�#sY���G���(����
ĿUģ�I�}�nt�ӌ~��߰ZG"�X��T�U�:a5�W;g䧑$�}8,�%����&�+��4`-��wЉ��"0�Ł��'dgy@?�l�ױ����	�5�H��g%�|���T�Y��F���@��I�_���1�,��u|�|"|����[�ٙ>���!`�>m��7�|m�+lC����vvH�߶s�ψk#���<�c���0B���M1���@��ߔI@j��T���4�Ax�j��JH���d�� |�˜�\T��,~U����'!�Q��e��aH��%�(aa� ��[���Om�JD	Cw:t�X'�["���Ժ�
���ϩN*x#��&����@�O}甫�f65�o���6޿T3��J���D'}�;\����NNh�
���J�~�U,ַ��&��X������X��B��&Teh-��7�	�~�k�"��Yͪ/M�iU�;\HCg�X*�vJqA{�3�8�k/�y]��VL4��$)<�]	���v5�w(�n��n�z��f��X�������KuD��@��7rKv��E�|�����"�z'�̏T,��� ~駶�p�]��2 vMMA[7�b8�PE�Y�d���~�Y�E�s��Zg� ��^Ѽ�U�,��,�&"q�o q�޼G��ȲR�er��D��g�ʞTNR�B��s��J�A�栻|ڟ"��Ia�6���D�t^	�8zH��hτq<=�f���02�q���_Q�޼�ll|�����8��}#͙������z���ڍbpm\��ih�-�}�dn�_��)=��M!St��җ�X�*g'���L^����0 �d1£�>NS���0I���i��Jf�<�"H��p.���mm�}����5�^2�䑰�ggA����j\/�"� cY��H��H��'���/��
Lذx�0�5Қ!h��M.ѽ�/5A)IuЫ!X�p�F�:@�'x#��r�J����^nÔi"ĘȮ�f2�c�B�7������,)�����C�JF�����}��`��|Y�w��d�$p�R��Hp>�(U��C��[<�����W���;%o��#6�����.�XjG+`�����W�MJFA)i��P�擝f���Xs��y� B,S!$����b�����aNv�BxoM���r�.�]kM8֚)P�?7��J���g�|75���0��QJl^D51���o}��5��P����T�U�H
��SJ���P��M�3)7����ZnDV8dT)����:��W�ǇӜ�t�!�kO�l���B3V&�h����fo ��=z�TԠ��3�Ҳ�@�!�}2��Dge9񮍚�#LX��8Li���A�SJ����Kq���gɐ�
a��k��tSڙh���� �X��ю�@j�q�Po��A-K�7�z4��y;�6g���V��q1ۭ0Y�Ơ���F+�U��H{�!b];X8b�oe����?���(�˞�<Ͳ�%X��X� �d�#)%�F�+��I���krʙT�l�&WI�		9�3��z�n���^����ڐ5Bw�8�3�6���!�D��A�EGb=-٣� +�=��{G(�X~{)8�"��5$0��rM�������"N˒)R��Wk�.`͜:�%���K��C<�W+>�ܞ��S����v�p �v�����q�Q��MQ�	�ͧ=Ц;�E�zI�?>k�N����X��*�>M�E�;�<k��DV2��c4���!*�4y�H*��ڬ�~&��ai`���+�83V�T����D�g�A0s��,<pa�Ɗ}Y=��*ևBӣ��M#��&�LY��2y�y�V#�rش�X@�Uue��x�_��M�%>��!��ӛ�F���8��7�,F��
��0(53^q�R�וa�Ƭ�w��Y©!������	?��S���(3�9y�cŁ����I�Z�W�zi�y]U��MoL/���l�]�r%$��(�_2gVxLt���pT�b�+4��{a?����	�Z�{��z�8(�4�HdCB�]WAG����������Q�
���1����Lm�6�5��}�V~�k�0��*K.K�].%�
���s�1IFϡ��^�<T~�(��qߪ�����ط�hN�Gm~T+s
�� �a��̹p��z$X\|Y�P[�t�B�Q�$Ά@��
�h���1��7��e���A����̛,W�:(����s��/��7�N��R�%I7d�i�:y�ϲ�*�oN��i)�RIG�Ub{"e��1ѯ�v~:pkS�dzAr��y*�jJ�w|�/9�0�կ�M��oϤa��S&J��ӯ`Ʌ3��b��uI[��A���'@�bE���a�Or�՚�owȩ�%���뙲��
��������
!!����ew�l�Ռ�Mz��mώ���N"�b��c]�W�x�ՙO� �gT���A�)�=�P�6�H^6!ϥtR����./&?�����P�}�����\�_2@BC
��5�$�
����?�^s `�*��}��m~S���.Ȟ��Ċ����XCxc~<��t,\��Z��h�>^�O���*��t2g8���[���f�1���B������4&%{ ܑBx8����M!XV�
��r��I��\j+ɟ�v���t��$Ug,�yΧ�gx�8Z�'B��0�����s�n��g	
*�'T�FE�@�La��f��Ŕ���Iv�hD5ѓu^;�u�t�����jH�m\�X�^K�)�'-yç-W�9�l�S�zս:�\�R`:ZT� �Z��r��i�ɞ��#��Quj,r$�^>Xs�^Xrn�(���ŀ�����|LѴ�;���� !�Y���F3)�{�IJ����
�6�Mݲ�N�ݑ��6�5�Wz?'ƒ�� ��(D��r�:� !&��<9�v�1�|^����<�w�����]SU}��Uթ����,ix'�!��\��{�"o�EO�j�~�p6y2 �W����&�w��$�Ī��bo^,4�ṕ��B����7(���5b�] #�;|��� �ٍ"��ĩ�0C�����U�<e���U��Isr��y���� Zf�q��+����<c7E�������`f=�c(15��F_�[�K_"$N��}�1�h�n�z�Y{֮8OI�_��F0�����:�8y����f2U|�b������)�;'/�@El���[���������`�;9�3��j]��n�]p�
�|�;��� ���2����= s���{�"0�d��`k�E&@6(@OR��l�7�t*-\��O�To��)�t��b��(Y@��q&2��6  ئ/c�@��NTș���ُv��x�H�$�O�0���:
Lyګ�L�����9��,O��.f}YE,l?k!ѧ���'9D�*Q`BD&�L&\� �C��Zk��f��8�C���L��<�I7�?��<>����e?
~z>kf�Ǭ#�~"�Z�@6�')AɊ���'�!M��\;v���55�������#�r:���;�L����M �
ݞ
�Ǥ��3����k��x� Y�"�:I�&1�A��j�S���l�1��W��Țnܵ>��j��h��D w�o��,���f[-��7�W�j-�G��!G��{$�C���_����,�34!�AU�%�S~��>��߇ܻS7}�|����J����;1-�,h�45���Dc���\���E��U �^*��"~H�b��@^�4X�V�,�^͏�����Q�5��\�cI��&M L�7v B����n��g%�%�3[ÆX���|���Jj���!qX�}=Μ`�4♬���?Pէҗ�T�]��e+�x���J�[��ٔ0� ��@7$�>@�W��.�/Մ�^�W�����8����R-�PJ�%+���%�C���ѫn5U����r�����p�~���>��qd���[��U��ɜFP?�t��'gC�H���\v�i�݇fU����Ԙ�\��Y��o��f�<�6/�U���w���U֍�D\z�y�����X�n�yƶ�D)�4|F@�áVjf�u�ذ
�al��@�L��|�ؽ >2�V���w!�t]�����B&Y�h�Ͷ�	�Z`1x��o��c�
�d�Ⱥh@{7MFޡRt�J���Z[b+�P����1�"*�}|(��=�I�v�Z���P|�?S�
TR,�]������:��W\]I��9Z  ����c��;���1�!2��?l
�A�	�N��c�P�����+S��i�󄀱ɟ.�*s����d��=����_p��DH�d���v�� t�BN_C�ԕ�=v���̃��T4����vU]�O�� i[���M(P��L|)���@�g���4n�CuG��Sr4·�jhgM7φ�{���9j�lɝD�~zf�h݃+��w���D4����x�rh�a*I��q���N�O�<;�f�f|��O�-��XB�qT(KĂf�v�P�'gT����^���Ơ7M�/�Y�$�Rijɖ-sC}S�&Uz1]�^Vh�Q����@��f�,�4{qVOQ�J������!�YE?��,DF"�+��r6P�g�S��̲?�2j�t��e3��A��EǮ�.�(�a�v72�2��0��ॻsCC^���)�gPn��a��;� �`r�\��;w�|j(Dߑ&&h�|$+l;���^�ێ�y���x[��e(�<K4V1_�����]�m4��(w����U�� �;��Go�zڴ��$��DLk�2Ҿ,��=�� ���	�rق�Te�J�yi������{�i"�`ǹ���T!l}I2h��.<�%9Gh�e��#����ڱ#���H/c!}��6h��PZ��I���Bb�s=)�
��Ҍ�f��X�'�{��l�sΞ�䩶�������
��T�e���� �Xjr ��cB�Jr�O�BF9�b����4�'f,1,��h]���[�uţX�����Ȟ2+υ�_�����¢�$��a���b������V���������M�e�	J�4>�u�pĵ���u,i�ؖ����0䐥L�9!xV���z�x�����X	���-���a�p]K��Ac��*R�����i#����V��G8��a>����4��[p;~��uX��B���ܢEtً29�~���l�'%�iL� �6�2��ɺbA��.ݝ�g����hG���?�J
68}�KK.�=��Q���٨W�z�*�����~�H�~ȟ����6�$�d�\�E�h�AL&�
���+j��h_�>s�����.�1귲��/,����b�0|R1�n���(S�On�<�`�2fے��9�h����@�e�1
�d`ۗ:u@ߟ�7�t�B�k��m�A��u#/�$?[y��,UUȃ� df�gP��cI9ː�ئ�^o���}r5���I|A�5�D�ล��t!b?.�7�����MV���]��z|���}��/�G�u7v�ڂ|e�;Ϩʊ��f�@U��`��-Rwz�uH<��KA��=��'.,C���2����2�Лَ�Oj��K�`��&EZ���'�w$iމnq�g�HdRm��J?"�p�VD�p.8M�9��;�aנ|�������W��rp)��\x��W;��lO�m!�'Kw�p�$���/&���,&�T��p鴼�qL3ɧ�ο�f�#���e�^}��ѩ�v(�k��E��T��2�]Cu' fm�P^d�E��z�O_��
�%ֻ��dc�?�%Z�-{`�B���yU�wɰ�����������z��}�?ؑ�[>3}F�>�H�MN=�J�6j����P+Ҏ��֍�N�6+� 5="|��i��>cO���f2�<�j���1�#��<A(um���4ս��	���[��!��e�R�!ٙ���Z� Xa9N5��	�zD=Y<ke'�b,��N��J!,��G����e�1�m�75C�nW���7c�6:n�Cƥ��r�#[$���;Y��^FK����&�R�^�<�ò����cO���Nr�pO(��}m�4t��s ľ�+������H�/���̶�ԌT.,�m�����) M���\����zWlա�������r`�I��"�Zk�$?ij�7���
e�F���YO�;��#�[�/���7�3�H��~�r���t3c����&�ҵ�;A��z<�r#��e��ݬ9������mˮ�N�'��P>�n� ze��?�Ǘu�y.�ⴛ���:����>"?���!���˳�h�7!�P�&�6,$�T1s���!.�`�cˠ�U�)���+��~�>)�&���b�{��*a��:@.&�
�ah$�Xn�ڄ�b��n�3���I���Uk)��8<ӿc�,�Ҙ#��kI���� ��D�mю�
 Wq��:
I�\��0���e݃�W3_V�	)#�$��kެ��ށM	��Q��Ö�2�;���y�k�"@c����`)y�#��W���H�H[����N*Cx�X�`
V���JL�"�l�b;��� ���BbN"�b���f�R�����m�s�i;�*��Ȯ�����+�8f�2ܘ;�@O��dc������ZiZ^�^�[��Á���dH�J��%/�"��t:����1�^Ԧ�Y��h�2=���KU���ɀ"��jܕhwB'k��ʚ��ߔ���fsm�D·ܕ��g2�o�n���z�8"z<*\|}��{�ĦOq��i%봷��9W�0<L��6u���DK8Z������񯔹�=
'D t����꛾��Rm�iڛR^��2o��mҤ�3RL�	:8����S��M�-��Z�g��حo���:�ޥF�fS0�7=$�^X[F<��Z1I������g$G��E[]�%��b!{g�- ���-h�}��ʴ�X�{���N�$����G\�p�ʢ�!�(������h���J�h�����y� G/�M�&������}l��K�JF����T���Χ��5��_��td�CѨ��q���ф���8a$ �Z�o ����2�C(��KB��Œ��}����ݏ�l� [S޶�lؐ
e1)|�-s�gpI-/8��{3������ΕW��[�B�	-�8�%6�L-�⩾�}C�Ʉ)J?�T#�� ���t���-�C�_�/�1�.VP)�@�D.T�2U{s�.igA�@�����>��bjg��8~iLL>>��	I�ڥ{�$h_�~��&�f)d�'���1�ʴ�l�q��5_5.Օ!����ߢ�j�_��ԥ��:5�!	�Y[9ml����F�D=�a@�U�N����t+�(c�X1�t}��<)A|�"����^�ycB���*��×�ہb@	#�	J�]O��u�z�W�$�n�F�fS���X��eL�6H#	h'
sA�����]�8�ĵ���{�E�G;�^����<����:~+ g�� ��J	W�9�x{nmْ���������U�fKK��w�@�U���n%�El_-n(��j�����GqC���=Cԧ�z�a(������� ��������q����h�_�`���`VG9Ϭ:����_1¿:�_��e���y���bn e�r�{����4]����9�5�k/ȟniq�I ��4�A*����� �b�\�G�Æj��QG��
y@��o��&2�.�n��W�d<6�����3��z4#bfGz{YX�������\<_؆|��y�M�rL��Ӵ��:�g3񷘢���5g�&�� |������PV�*��RK���3��î� ,(˩[_L�Z� U,`!3.!k@�d��Y��{�,�^�@��1���|3��Hqd���gi��P�?��E9�	�m$�r°�����Sk��Y3sb���&�5TE�&P��Y���� +=[�k�Lz�zV(��>~7GHɷ�L'�\�\ {�ܛS��2�q��'��i��*����tZX��n�5Q<��dɒ���_�k^$��5��\M���+� ��ǌ+�=k_�	�ԗ�5ݜaG�v.s�� �&��?
�x :}�L!�.+�k��2����R�����j��@tj��c� Wgx{����ZKX�β ��<�\L=��u#Bk��a��#4|���7���,�V���`-~�
P����#�m1)��������ULb��b�o���ݫ�)�LQ�hi��;�t�M�����3&�y=���<9�l�f�4��?���l;�9���� WO`�ZtP
��+A[N�N0\▨8�0R >9�"�ȷc��Z?D�kX�2�n��`���8��!�̰���j*��j|A������D��E���d�`6���������}���-�or��3������!��-�W�aZ�X�{Djh����N[��}�O�Gqyy���8{�j�yg�,���
� ߃�@t��֪��;�ص�BլW��dʿN�6Pjh����گnG*Ďj����������e/\�=�Z�L�j���UG�#�t:�G ��i�k�
�#j�ΎT� ğVW��T[�لWf�f;6��6_7u�c��f�ǡ����/�u��keMh�%����y�?�|���빻҃�J��������a����e�8�1��� ��b��%> �~�6�xU��6�g�<�1��BN_k+��w����1Ș��)=a�0���o�زgq1����g���@DG96ϱ2{^�!������m�i��ob4�J��s�n
��H��.E���Vh�+ů�cx�ܔ >���Xfx�[���
f^0s�.�U#ƨ��b��X�~��@��t�Cg
 ]�
yM̓���Y��m�}蠳��с�ս��L����!��3����I+�Q	���XXt�+��8��Z[���uadI|
���HS�B��㽘]��U���*��B�
�A&��?`F�nQ<m=4�+����dex��+�Vґ�Zj�
HU�76�"�l_#C2n��kmm�Dj(X�LY
��Bې��U�Bw�l�����*ԥA�p4"?��?���� ɸ���_ &���r�z�S#}ϟס�F{RCMO���`o�;^��W�:����*�v�+՚�a�
��L_�m,	P�2dC�v��W|p	*�t/�Oۗ��\"F^���g����L�CuƩo��x�SҀNhw�I�2�C�X�*W����Ju��<�n-�R�Y���$Q,p��s�E�����6�ݮCXU|
v��	�X�W�\ �;�Yp�8����#�M|y�.�V�O�43������4�Ƭ0�t�%!d��j�������:-�� Y�Ba4%�r 7V�T܅�娦p%����Pu�KЄI��D�A,fGE��5��/��~8�p�cM�W�<8[P��V,љ��00��9���+���kF�-��3��Nk�A���E�wD�J^�P�uK� �W#u%�L����]Hp;7�*B#%��A�3- �O��1ÇI�(�RV��	c�1�aBd�Z%��-,���[А���u_I����y(JQȌo"7i	��TA�Y�!n��!Z�"���B.r�ü
BP�J�A��!���>�o��ٓJ��!�^!��[�tG� �8�d�J�)�*�|����"�a+�����-����9��1H���G��)���b�g�1��X���c翜�?��	�$"?�|ʒOu�3��c���M+�$�R�'��>f^Z�/u<���&���M1(y_�>��b�[�}ɯ������ԝ��=4}њ�T����X&i��=�{i_�=�X���R�S��k-|R��J_>�q�ɛ�&)��6�i}x��FU�"����,|�o���j��B��g�����eϞ��$��:�т�r�E�����Y �u���h(�|e;Ej!:y���I�{y|��,�T�VUO��ln�"H�$�,��c�/>UF���U�����<�{
V�s�AD���]c5C��Wl@�"����Zt��n$xn���a�7���o��\cf����ʇp~!%���\an&Ð�9Ƈ���
�ɲb9�HZ	���4a^��;��Ԍ,9H�#~��8,�ͩ���gg�5CB��JC�y��g[������=oQ4��K�@��/�F"�^��&�M��1��?6���8)�^��{�d�4�YO���D����bQv�,��P� ��i\wtUk��wܱh���r�/�J���Bb�'t:Ȫm�M�Ze��;w�^Z�i}"�mG7,��p���d��}�X�1�Wh��ÇY��0�J�d2���gV.L+Es%���i�|�[����7������pY�o�n���N�Dl��u���}��qe�]�Rm�2t3�]>�@?Omۙ���Ⱥ�5���ru	�+�>Ɓ(���q{� �h$�p���έ��'��"x�ג#�jީ��_�B���f!9k�E��MV�[ޯ��0t0Y�;�����YnJ��@Ŕ�	��}5+ș�X��7� ��>�p� �	m^���w��Xe���Q���˱:��y��ӝ��i���41��*�T��(��'-e�܈��>B�
�����L)����tc�H��~�H$�7W��M]�}\��_":��̰�i�����@����WA]c?���O��3V*mg��Q��&;AJ��.�9���*��}�?��hD��=r�|T�N;�����ݜ�h�$���E�`����9LX>E�9�U�8�(Ed��L�^��bi��"���3�v�P2\m�|�T��K�ߵ��c0@���]NZ��!�k�y�:��J1/7M-�3�j�CHn�QKk1�`��s�7��<eTU��^���8zѺ2�
��iFt�����v`p䭚`~�?}I�h"����nw*�[p���\��2�]��6O��Ͳ�]�qR�G�@�ƫ9a�U ��%�ɡh9z�Fo�ǄͣBp;s�W8{���\q�9V)�3'��o��(X��V��Ԯ� ��n���X�Ig����[��������t���bJp�+�b��H_���&��o�7�?��֧ZMfbj�!���g������V��eٛ�⹳-lj������q��
[r�K��u��l;��燲R�#�|�n��z}�U��$��8�_�oV^9�	�uy�����+�Ӛ{��U��K?�`���?��N��ߧR�A�>9��o�{�L�B��|!��/:#�87��Ӫ��"���������X�'Be0Y�ucN�\}��ўGR�%��+W9�!��0�J��y&ؽ����x�)����~X{KC &�:�������_��M��7�1�Г�$F�����F�<���/3��0M`i-'D4�~F]�o_.��l_H�7�:��B�m'.�&t�
�
et�	��&�����8��v�/.�+� ��GK+$%�����}�_�B}���t����i�֛���f�Ֆ�ψ+�W����X�lۘ�q<�}�N��ë*�v���A�F���B��b0f��F�ِ�;R�fWX�.�.�f�vz��h?�`�Zg50	����Vi?�#A�F��]��_ �J��%���%��B@�\2ËxM<���%�G�8�������[`���K**��{ZQg��~�n��|AP�a�����<)Zf�9��]��E���m�@>�؍��.�b����m�!1����R���L�ғڴ�vP���Y�,
�mH�Z�ۻ�wR���S���D���Ӹ��<��v�Wf:�"�j�`�&��@��|d'�X��>�1�r��8Q#)�i-�>t@��;����}A<��3����b95��a�-�� �O�-��y��D��S%2�qqu_��f�������wc��C~��F�|�5��ԥE�"^O���Y������o)tk؁������~��/�F�` �ּˡq��SW����#��p��f����Nd/�[���"}���w:
e7lX0��D��/��\7w�`hzA��]���!��Ӕ�g�Hl��y��Z�7&��l|'�k�rU�XBF��V�.�,�0���q��
�exx^�A6���k��#���6Ya�������KxgM S���s��:v-`	��Lz���������h��'���ԁ��J�ZJMY`Q�gk8
��^}b����y)W2A��N�g���B�M8$aV���A��;��q�3!��p����c$�a6!�/�;��? 9��ϦGx8T����7lR���`-�V�m�}µ��XI�[���&lzD��^�B����ftBPėH��2�c豴�!��i ���=3�]v/Ƕ�L'�3��9u���߫s��g�T���n�0;J���Ś���>����4ee�&U���R +���mQ}c����6�x=�7�q�����EI�U�-! ���됍�qճ��zx�$Bn7$l"ɋ�k�
yH��e�_��T&�lܪ��sEfv@�̓1u��. ����o�p5����E��щ�WD\�I>��1���6l��rf�E�?a��P$����d'����UN���G���U��\D��
$L�����8y��+���<S\���Ҋ��:��  G��.uϲPp��/����|	U�po�vGsv�u[Q�L��1�R�q�{G_���S���Ma+���k�渌=�,Oxg�kYL�q-�6!�t��&��#C�09W���©��I���*�W[���
�,~	�20�-N �jK�Ͱ~�~�p4�H[���$C��Ȩc�['���,3�N�m���@a����7v��n҃��w��T�1�;�05�bXqӉ���,[��N4�T�z6���9�5ô@�cL�My^�<����I0sV�"��L�n ˲M�<��P�Pc��,�z��%K!��;6D��-pi5U<
��۩��h9������)�6���\�ͭ����8V�9�~0Wҹ۬ӵ�R��&T���`�����B�X���^f��=5BL�/c�f�H�*��'�G�I��>�9:95Ҷ%!W%cF��n+���s�������PSR]�nD��Xg$`=�8�mʃ���d�C�%�l�te(�G{8�"JP'1�^����!��vb://ԏ�SqepL�9���~�|tшPIĲ�u"`|�ԃhKЅ-�VR�a��4`Ů�_�J���'dBW̏��2¸I-V"J�'+�A�AJ�w�{<��g��fgݿ�`E�՝���Ә�����t$>�%�O��
V��3�}�� &j��yo��i~}���^��=���X0��Z���<���C�C 7�dD�K���S8AR�Y�M�D�eG�W;�͙	�bL�>���r$ݼ�K˔�����BFP��]5��U Q���+z�j�m~C�5�����M����Um�]u\�=1ܚ�e�L�֎ߣ����j�����5"����(
�5�m�)�x5;����������"���o%�s)$��{�x�Me��r�Ce.��&6FD�UN��90A�^����A����W�8�ŋ�3毜�
�>�=���9H:�s��Z7�XH�2�c�o�iX+x"	�����[ $f����~�J4c�ؚÓ��]�0��A�"SGWn��l���Ӟ��1mZ��>�������6��:�Ukly����]q=��N�=���S�7��-�؛��֔�3���h��_`�VW�-o\�� �:�t@�lif	������, 4J�ޠ$�+|���������s~E�t�̾��ev�a�&����S ���/ s��&p�;�Į�Z�0�쎳02�z��;�X���\���5z	g|�g���d<v���fu΁��td�y��+�1q�h�7���,	cu?����z o�Q{�|3�U�Tlֱ�z{L W��7�{��T�s����f(F?YU�j�p1 �x�O�Dd^2�1����~k��_,�9N� �f��f��jP>�	�c+d���Ah�m-�[fY&�T���&8�T��5��}x{�JG�@�n��Z��]�G;?/d��lֹ��RX�#"��9y_!�2Zb�Q1;��)�|Bg.c}dA�Y�:N�c<@{�2H��_-e;]���Pu�w_�2ƞ������~A�Q�/������o���om�Q"\0%r�S����Sn;�I�U'�yIu��z��l��I��[6pwڞ���C�YaQo����V~���� 8��?d�l.����'s�A�)cu������T.�5x�ybc�����i�8H6~��2m�����x�/��ցrok���?nT����5��3��y����9/Y���.1�<L@�}�����]�z�G	����F�
��`g�Կ�6{�W��.�H&I3�-�9�n�6�B�o���hH���P}ĝgE.�;�8�<��g��}��z|4ظ>F��J��E�v�d��r.�ty�@�!2�=q&[����J�Y~����4��	3\�r��aV?��j�i^۸��s�0�����4��>ȍh��VƲ�I ��x�݋� )VݶZ\~U}��
���G��%[]�̩Y�*]�r�C�0��}��=��5饎�>��-5|���ln�ׯUA�v���?z;Z�\�'S�n�2C�O��H�p��|>�V���ܟ..���ծ�uW[�*Н�"����0,��4�2M����ID~I�R"��d �$�������__����#��/�\=Q��>ŕ#0�7zvɷ�{ 
���
Fƞ�7Kn��o�4ϼ�=0Ԙ�`�H��`Wx��Jv��Mȑ���ӱ���X�H�OA��:�ɛ��c9z`��c�)ˍ=�y�a�	�T��o�?���_�7�A��X��ҰB�T���+'��՚��6V8b�q�    |�#��� �����j���g�    YZ