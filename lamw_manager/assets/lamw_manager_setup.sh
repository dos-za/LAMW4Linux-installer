#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4130555228"
MD5="b3509c6c92226f01886870938fe7d3c9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22532"
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
	echo Date of packaging: Thu Jul 29 19:02:18 -03 2021
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
�7zXZ  �ִF !   �X���W�] �}��1Dd]����P�t�D��k�g�r)z#��Ձn��ٶ�	�����*������Z��t$np�G<Ok� �i�����|�//͊]02J؟���8��.��j�"R4] ;Dqw�ƣ�%r@���@)�s��,����Ѕ|]Vr��<��q@�(���n�����QYI�^	6Ŋ�į�E76i�Ý� ˾�濈�S1�l<��{��y��Ro�/z9�n�R-�X��j�e%�,���Ԑ�ur�(��Y�|dD�����ݛ#>��m!��lo!Z�4��19ΕZYNDAd��v�mg��D��C;`;�[���V�9I�!��Ʊ�ߋ$�\���(�i}���wC�*{JMw(�ƿ	>��ɫ,>
*}A�9�rn�����\r��Q���;o���D�}2�/����Cm�\-���$GM�R��Xf~͵Jې�Ԇ٦k?oؘ���z��|�����;4T��q�6A&�*@�O�3��y"��+�~ƸpQ����bv*�5v�Ϙ�O��L|�������^�Fq��`�Ҡ/z-h]�H�٢����J��(����n2|���� �������B�vO�dJ̹a��P�\�/�� ��ޞ�-Q�$[c�RƏq�J��<}"h}�	��8��O�_�(���G��2?;���)����2[o����o򅴣�����h���KD<ה?��A�~����
P��e�ұ�d(��@+'�.'!���>E���>�L�ER0�F�c�eQ���$��V���D���z��
8f
���rNw�!E� ���	C�33*+͐-�;�Qs��:`����`��H�_�a��0Q��G-Z�,Uf��f���s�%,e<���V�hMQ<ok�f�^�ʉ�	l����V^�k���zn1�a�ٱ!��}n�1ߍ̺�� #�b����"w��v�u��̸�=�����̀�е��+�1%8E��p2�Rw��˕���F����6�N`��kd�!$��q����yAG�ǟ�\v�0������_&�f�j���?`��Whǀ���|�+C�d�%��a���$_�Q�m�x:"���p��p	�Zq��A��_Т	�V{��Y��{�f��h��2Y�VU@�Qbm�����y�o D���eP	i��!�D_���Y�K�'^1��.��Ψ�lz~{�h��,
���U����!@rN�4����
m��=���(2�ًR�(��y�.�&�f-��]�
��R���z�)��=jN�T�~m,62|D#&"�@__	��k}f�4�<L�0������"^���`��檡$�\� KC##�0����8k���:,�����?W#�%S,Z�����\`y��[���;�
=m��I�'�t��zXӬ̫҇<�}pGj���:s͙KU��U��1RoJ#���<k��d���wZ�b�LקJ#Yp�f�"��҄ɧ]������-v����e	��Yj�~$�\�A��U.;�@@��'����6鮸�k���#߼9S����E��WU7�x��|�O�.h�I�N���u��\U�:O`����f��~��d���5����b�"�	�TtZ^w�,���-�QJ>�����O��ߴ9��d��j;��ƺR$5�·��8�����F�z�S������<�tg��i��W${�D��.y�4h�+g��[��x]���?l]�{?4�i�[?�`�S�	��8����,�LSZ��*e�`p|�k`����C����|��Bm�Q�/ɒ��fYy���4h�C��.Q�PU�l}�6*^K�J��щ��-�3W�ܕ{�@�ƛ*Ѯ�J(m��w�{
A�{�~�Q4�Q;�f��<��M�����.���B�����~��m��G��[�u�,�ph�S'�v����A/P{p��?��f�5���Վ?��I;7�-�EN��:6�㤙2���G���3�w-[��p׎�������L��V_��h�AP2s0�	��a��6氭��q�y�D�ƾ}���:��D�|�P������k���}�؂ej���#�v���fy�Z�E�Md�4�]������D�K����{ȝ��}F��,<��{��HN�4p�yc��_�r�j�Cs	�7���=�����u V���x��^_�c
mSg;��X���E�Y	�W/O��36tҤA/�ሇ��7z!m��Pq׋������1mxD�k�m�:�Jm:QC�����z�e�zC�_���W�r����������)8�ğYo;�F/D���p
:��I˱�n�,7��5ۀJ&���/RD��n8t˖�����:�n}�&��Klɉ�'-��!hmwt&��a_#t�OA�@F�����>�}���<1-pe�5�q���ҳ*�}n��{�i����H���[��xyo���"=��
�&�~3�ө�_%���Q���P�֋��RQ���w+��n�A/�7*��n�o����tLV���x ���~�i�S�B	U�~UjDD�n�� O��T�>�Q|S��{�|\��r�ME�CA� GQ�cJ�8z�Ӆ��qX5�z�lg�� ~�}�\��,��(�S�*���_.�М"�e��qb���} �+}�?�G�P��ٰ�&��}e��6�?��O�5?��~�x��?���Re ���
���������i��-�̰Ǉk�|`��\�J͒d��4��9��:P��xb�-B�N;H�"׳���p��/��f�p�'5*�h'��f�������4oz��+��3p�q]��/�|����K�:'H�~��Bh�Y�ȍg��߱���N�r|З���O_���Ũ�]@Z����0�=6�ъYh��ƹӾ56�*(v��G��]��+t��6OU�Z��6����!mu"��6R�è*��0�Z3�v�%���'�P�*�C���Vʆ�aӇ����X��d8	ng���ɤ�N���Đ2�p���A���K�{�)n<�fR2�B�EI��c���C7�H�]�P�ga�vr�.yh`C�S�d��Y����C6�ǏGD��_����[+�����{VӪo�4c�5���eQ$෈���w(
�/N��;�K�9?�k��3�uҷ�N����Fѣ����Z.7?C���:I�O& loC�Ou
��\~��Ҧ~�vn�6�;٢���� t��Z�m<f�Z�#o�ØV�����m�@l~N��S�mm�2�LՉ!�e��g����O��P��4b;V���n���A�%��O1�F�9��"b�ө��'ZQ'��OujD��!�?���>M	"����oSЇ,7��"Y%��!($��O�۵��8��!��1�0�(3;�G��(5΂8鯉x�Xim ��ey��_�L�x��r��}rm��#=��dEo��.33~�v(�ɴN5h���O��ɔ�AA�EPE���&W������I۵x�������09$�o�c�l�W���e��`tT-�����X5q��꘱� Ó"/��Z�Gfg�S�]��d��"H�Q@�_y&m����X(#����+�&n��H>�c?|+!J�1+	��d\b<�W�$G��;
LȽ���r����e���(��^��^����5D>�Vs>�o�܇����Ip�ӁN��h����ͬ-�{���*����Z���R�w$�����6��|�J�@�Fg�߿$�[��� �U{|n�} ����[`?���Û�j����yW@�T_�*įy�vH�y�N�:�V1�V���3Bd��r�f	��x�`j�K�%s�Ҙ~�-����@Jg��~���gqE������q� �^��g�T�3��ÿ��fU����"�i'%(��j��{߸��7�!��{y �������ϸ����1��!�|:)��aQZ0��ɕx���2�Z㛛�JD��V�J���<����Y�B�T-@0�����!!~CLG)|F�t����Ն�u�l�Þ���ŜX�<���v`y�R��.�"һ������Bύ�$�Gu�.������Up�a�i\uy�q��[�ٚ�֢A˫�wn�����h�b�.�Ok1����*�b��?ǌ���`l�1-�`�j��򗩸��ҝ��T;6$t��3F�]$�� �R}k��>��L=ס�r�W��5+���扱�6��{]���E��v�ų����S-=��ө����ϸ�IFĆ��ݺ�E��D�$��
���7&g����3�d3a�F=w9'�(o�u ���`OA�,��S��H��JCp�'�)����í�]UD�iq#4�Ke�-�CQO���� 0_�&���4����se|<��$R�<�6i�`��|^v�����;|����CH�V�Y��C�d����<6�r(���C��B{�/D8ZhA$P�n<*��!���C�鈅��ra���C���պ2�������Հ���C��΃E>�+2.���M?���l�zl�4�C�7<�3ȉ��w��������{O�h6�:�Hp��MvN7iK�^��y+���@��g�%�����!d��V�h$�V������g0�=:W�x`�>|Xw'#$�;,�􈘞��Ռpn�Ȟ�gP���eٙ��9������\кz��r�D0�n�������8X�j[Nqo�N�r?�[�u��J�~�?�H�����؅_�,[x��s���]d
�~� ?�KL��C���:��*#=�������;Y��J��
��e����p����qlP%���ɯ�`s!Bެ2�Xutⵋw&��F��W��#��|\�,���E���]��i Pnx:��)t��#��5��
���N(�c��{�*��k#wlb:�%�\x9[�I�e/�)E�,Ù(�ƃ|-z�?@2_��ʎ�H�va��ig�i
���x��n��u�Ϝ��)��Y}c�r�J�i7L�Q)>�Hl;�h�䮬U|�5:��Y1┏�S�;����	�Р�0R�3�Q�(
p���$�ۆ�lmCR��="U#��Q"�h�O�d�dj"�*����c�ں����-
�ҫ�Όm��t����d�y��J�g����M���o��%x=R3��3���@��-�l�w��j߷,����ِąXd�;�k�G�ۖ����f-_׹L�<��[�h��!N�ߟ���&1xqQ�.�*�d@�!��m�B��a.?=_���O5�V�C�6lnφ�9za�F��A�Ecjh>��>s�5/Sh'iO5=�p�%a�y�~�Sc����AD�H�+Ҽ|��>`Z ���&/�}u�Bvk�q��7���SZJ�JS�,*�6Ns52"�y��={EBAx�Ȩ�G)�7��8"0��~PP�?�|�fg�}̿J��>���=�e�1��5 �u��Z��+?x�'`f7T�d�Wjn�ѱ9�~ЧhH*�����ݣ{���:�2�����3��.-4J�b�8�ݜRofJ~�0��Uzo��4��O�r��Lǭo�|$�_M�����aLfp�.�Jױ؋�ui����k�QT�.H
wR�A�X��ߋ8��*��pH���NKɋ#�CV.>��?�[�4b����u����t�l�G�@ ��ڛ:,LvǌJE����W���Ġ����L��K�b�tzEڈ4�9�ٮt �#N���Ϡ3�ԧ�4FvH����G���C�MhM=��bP'㛔&�CYb�����F��BP�1�YC��N�Ƌt_$:�`�u��m)�^��}�_�3.����#�P8a����l�t�����Y�X�'�:NF��7C��B�yuv��9�)�su5�'%�"(�wRBF����� ��@�A����,#���!+�7�cM�d��;�7ׯ��q�V�6;k��+FX�5��4\�k<��?��a�N�!���U¬�z�L�Z��)5E8�X��J�l�Ou3�O�W�&h1�/`X6���ERL�<�2�<�k-E�/�n
�+�����]�NUM�T{в�:vp���WGn4��q�DM�_|�3�f��qq�t,���/�a?��ɥ�'D�2��zS�����ә����e��k l/�����/��(&��5��V�*����s�����j�u�Nw�2�*T,���aQ]=�W��c_	]!*(���]Vؘ2�S��.�m7�� 5M��#�ii��/������h���S"9�d��$9�e�ɓ�V���єQJd�v$F�b����- ������?lBOFQ�E-)w�,�V����	LG/Rq�����Q�Iw�E��U���cUV@���/
��w=P�q�!0�v�;�I��H����7{���tM����=��C���P�iR�A}eї����,�W��zJd �[�b���� ޭ�;�y��Ҧڵ���w��09ԕ⒎3�"��s��.�aL��-�w�sW�ݨF��N�/`�xZ��۟m�d�z���a�W�-��6�H��?��+��<��^Z�0�	/Ӈ�CMM��J(Mh�Qs�D~�I|aTO��-�C��47�v��]�L�#+ |���~Ʀ4Ѩ�䵓A�!����[�"՟�8Iٍ���	��Y l���؜�Ƞ�G���rƭ-��ݿx7�d2)��(�&�ԫ�X�QzjI]�=���>?�ؤ�Q1S�~���ߏL��ۜ�fw^	�U�Sg��- 4�DQ��;��ϼ��w^�� G���>𑾴��V��pM�т5"�y[���Q���� ����]�6\���<l*��m^H���)������<���T>��Dt&XsM���A��)��kIH Q�T/�u�9rrx�<����B�yJ���u5�N�B�<�l��#�8��		���}���ee���P��@[ɲw�^�]R;�ye62�����IHߺ�s�j�`ϝ�p��T��*#��Oz+�� %N��Ø�G�+o�X�_�)�`"C���l�i�裇����c*�תmƝâ�������˰�X�t�ȃB]ۖf]��;
A0'�&.+ر,��F����ܺ�	=-�� �DSf�'`NՆo^(И^�ME�۽�G����yΆ+���77�B䉺���:�3�I���G�L�G�$y��LJe�F�D�[��2Ѐ]�Ϯ��O��~Z��C��ˋ��)lK�j��(礆!X�ړ���B�m1H_�M㶒��x6 ��-��"��07�K�;�x���^6�1��4[���0�@|����k���hp	.�p!6���h������]˔A@���ify�`0�.�h�Š�4�(#���"ܑ4�f�]��u�n8���?��!w�\b�����O���ݨ�
��lrx��p%J����� ���9��Ef$_7�YV*_�����/-c��j��E~I��Me �a�B���E)�\�Ș-���T�/Y#���9��^6�q�>!Ul+Cd�!tDyUoK��"���S`���̫+f5%{���U	َ�7O��<Y��.&�2w���M:m�� Z�� �,�~T ����@��> 

9�LP>Q�ޚ2,l�G�߁�p��.#ry&��˳�i�/k�]����B�,���6������(^����퓧�9׃�o# L#@�o��u"EBT�'N�l�9���O���v��#h�{��؄���w��Q�0���⠟�A�+�ހr�A���j'���Y9Ut�{��O�&!��Ϻ�P�@E/yS=6Qn8z�䩷�bp8	�t �Ӹ��z\ݠ�F��j�`��E1����'�Y6��kt�m� �Ȝ_�����eS��j8}��g񚖍O0�E��4*��Y�gWc�����v�Njr_���^�N�
R��e�hV��ހ����8c/����/E��h�pRs�U�����=S�ϖ��X��R�4��>�h��k�m��Q M��7�#�h�P��Q����x�L�Z��g�\���" �	�ПI���4EB �ܨ*��~�M�)�?�u��Gϳ�A�?,�#~ę,zA;��a
w��K �$[�/Q>I�:oJ�y�K0U�j���^9N\i��N�E��dMDk���01��̯�P=B�'��Jkq��;(Z�6tJe��sU�c�l��W���Hi($l.�O������%)7*֒8%� i��5��UB�X�>��(���߯�*�<��cj�b�%׀d�6,��:�oJ�7C�r��}7�A����U :ź� �Ik$��<�&`n��P:��Eg�q���\)��]s�A��A�7`���_ˋ�t)���0��Ӡz���'�s��7�0�����P4�HUS��-��Z�QYk}�'���6�j�P��c��/uӦ��dX���ݚM��	ԠZP!r.��1C��f���ôX�m���
	 R2G���Me&�sf&`�F����#V�J[l�z�"1����=�M��� ~ޑ�>�CU{i�A�y�URJQb��A�~42�U@M\�x-:B�>�[�Q����g6ab���M��_��G��^��A�~HB����-��H��(�2�ְ�"׸5V�ts���	�Wh+b���w|�g&�wH�21tF�ڢ^AכI-GJ��@=A�~�������=��P��
S����[���93�5g��T/\J�����6���SmM���e��5J�B�k�����!��$�<�DP0;��;f����GiQ��_� �7鑖�AZ���Á:���q9�T$��,Nq�ŏ���$�����?�^P���I�97��zU��N#�I�U��9᝷H˚��&j�H�����x\�Ȋ�£�H�Lw�����/�n�+EYV��b�uY��濃�xɂ6,W�
�|�p�bS
� �R�g��K���p#�X�*)�)��YM��L�arRV��~��ֆzu>aO�x����c����V�o<�ɠ��w:��zwAW�`��j��z�{��|."����O	Z�?��:����|9a�_8~�J��Q���ĵ]����}Ȥ{�>���K�݁9��#��|V{(L�����r�
�j�'�DZ����v�@X�Z�����#����AQ��9�Q����%�K�%Z@̤���Bf���r�L�/\�����Hw5f��V�1ʕ�6��z�ڇR<���d(2)�	��ȁ�P������D�՘��;�MD.�T��8��F/P�S]��SR��4�	ݾوRLF���S%D%���`��A�N��7���kvPp���y�%U�D=�����?K8*?@��/w��V�F/��]����~�^Ѣk���C��`F�l� ��'q٠z�y8!p�-T��p�{��Q�T�}&�Z�'�ê?r}FBl5���}���akr+N!5�N)�3��]uT��S�o���~ G���x�*�$�wC��4s�Q���6�df��G�h�.���O�1�=�Ѩ{�v�jޒ�u@㢩IW~ޏjp&�\���c��>�9��ϴ���� h���T���=��6�"J���q�͆�V����z�F�������5nx��-���~u!A��T�ű-�F[B���
��8��ݛ�=����6�3�z�m�b.�D����Bk�s�D���7���O�m1왔jI��T/�D�����l_]\�;a�.&w)����"�uj��>�^����H5�Fjk'ii!G�d�F�c�;dβ��*�Kz3��8Kc=�v�q�� �f�}\j>@���>���qH����q�q�j%t��J�k�Ř@yp�`q[��5��6��KN�j%pk�kF����� {ݞ>�ޘQ}[a��st���O$��1Zy��?C��}��L�M]��u������PS~Y4Q��QҰ�4$�����(�4B;f^�hT�QqL.�y\^�i&���z\X��&L��\̂Sʸ��n�҉�#@�kCp���Q`
	�,���E{��ud�rQ�	y����6���/��%~w%�df��90�x���'S�����;j����c���92D�P¸��h�x��~����v�~�v��Uxﲯ�}=����1T��vR�qI��o��rHF�B��h�3�����0��`nѥ?Z�\*��*�n&�`0��p?����Wߞ"�8��l�����KYY_1U)�$XQ�gĤF�
W��F�G��bVR�۝�bԞ+���b;}�>f�wj_x��d�I���\���;��| ���5��������mc{��Oݯ���ǔ��+�)�pR��|P|�2��:��H&%�i;��0��-�YJ�9NA��|@���B)F�v�h*�B�#̕b�}� _}qs{[��� �L_2��?�-`9�[�Լ���^��w�J,�0"�S�h�8�?R{��T��Y,�V�}t*���������^��4s%I�N���Q�zP%�LPl�M�H�N�!:?$:�:ݩ����8x���d	���=����o^��a�8/�dC��K~��~��&af�Td `}Fz�G��}��.�G:�x�R�T�n�7q��%�Uґ`�V�THףּu���� �]hX_��.j�Xk4Vz��n�Ə�d:炏�[wu��/����V�;{�J�e����ͣ�)D(B�t��צ�?�g+����� eT!��ȡ�T�z!���%P� [�V�[����
��\ˌ�D��`#:�p��.�PZ���[��d;�ȤX�%z�)���frX\aP�7���+r:,�}qIQVOxG[T$x��D���(�xEϸ�W��p�{����!���Z�ҽm��چ����~	7�������G�m��0>BZ8�ޭ� ��l�IfH?Nٝ���
׬�O=tcA5��3@������c^o[ �0���QU��?��Z���?���^�Cr��x�����|΋��<c��
�A��tO�}3/��d�)�ԞBzoz�����g�dMM�(��>@���=ċ+/�v�vY�1�,��h�硳Ү�O-a����E��d,�٢��\쀃����zZ����*t�C�x��r9�AS�ML)D�W(<�mVʕ���^x߶}�$�!�nM�������l1�ԡm��2�fM���t>�1A9ͻ:>Rw����-�@K�E�;��J��!؋�a�<�&/vʲN�A�1ٕϒ� �Hۼt��~(
/~�ӭ@?�����cS}�?\ڤo���r
���,趻D��w��k�|�p�S�ɴ.���n"IF���ه5�d���JF84�ڃ��G�ձ���i���$Qcϑ&�N���芗���h,�?ƭ��&���~ϸ�اÑ�����N����w�)������k�����>c�T/aҎ���{�c�]R������z�>�AB�q����7����g�
"�c�y�,N��<���)���|��Ķ}��C��F������W�j@������ӻ|�szV��Q����(����v����s�f=8v��K����QN��Ҁ��8C�t�jc&���W^�P��j0��s�(�9��612�_H�[���œ]��Y���2Z��f�VݥV�OA���?�u��Ç�j2�5�ۘ����](+N�@�v~��:�v/�%qS�㼈î�#m퉐�偗P}�Q�Ѻ"�ֺ�zBs���(?�x���2������s��"e���8(;��~����Qa`�j4��y`ne�u�	�z����>e���7�-��I5���pn �R	�ǃ.�2b��y���'�*U���>�h�p`w�B��|��A��{٠&����|yAZ܍r���{f�q&*I��Pb��dF =��	J���l�������z�{*O��+���w���ym[��U��Х�(��i�*�5�gF�������E(�;t�0�4w#�k'��MW�������=;>֏���z�S�O���էd&-�h��T�X���(�7Ys�P@5��Z�����ş����<U�H�Ç�87{�^ s���?�!cd��|�Q7�E�rT�f�ʾ���j�/_d��`5#��*lK��m�z���ۈg	�� zx��ůՑ'd�I�Nl��c�ֳV$q�
V�BM�˂k�3w��ɚ��J�P����GO��ʪ�r�{/H����ל�O�e`њB�?������?�]�}�B�]=n�fc;-��-�̢��?d^��	V0C/:��%��~7i�֗����l�Ԍ���R�� ?���X)�#_�`�>��~^.S�)�֎#�i�q��X-�k�)� �'6���,Y�`h�
���*<&�zė�䒂��M/) �_N� v��_, =�E��]�~����Ö��F6� �Ť7�^�?21�&��k�n\�7Ք������9C]�~�p��h�]s�ܥ�fC��ŀjo��<�&6�t�!�f�~��Og���SZiq�8��bG.vTG���v�o��#�M�u��,��6�4�S
g*�5)k��?@�,׶�wI"������w���Ӊ�j5��,�D`����X��b��Ȓ�6�U%�kg5������i\�r:�����Z>�>P+{�23���8� ;�8�穨n��(�%ƳK?j�*�hD�J܆���5vڶ*zޜ�Ct,��(�s���n������ �Z{c)$���R9r�U͟����ՋDxt�8��P9�܀ZH5x}�>���b�|TpsiL��*�ڑSr/�GX�rq)�:�Mp��vؿ8s^��g&&���xwi�s/Q(�kw�DwP�KQ=���u���>w����(�BP�Pr�{���6V�1R�@;�����&2 �ܳ��}���[,�q^�E�0��jL>���+8Q�2P �9	�-�d�b�X�\5㱭 S���I*�.�0�]
��\����K����ʴ�����IR��ۏ)^=�O������^�f��⼼��,��8���v]�޽���/�d�!�׽c��$Y(bBȤ;E��;�,�F��%��#L@`�G��	���i�8nцam�	�
|T:_*xcSç��{�d����g���{��-�T��۬K͓j�G��ǦR�y,�Ay�0��~6~�yɃڟ��ٕ-1��3j6�U��,�Q����O(mBP�}� l��������J]��C�����)���Mr@�{ ���c�_��E]�\G�P�@*��G�S�(b�X1��y�ì�������gnWD����35�<�?��9��2[�q��ݜ�o���jِ���K`�7#����۸��o���:t��#�/>nc�@�N?�Q(�Vxc%�M���;�6B1���,E��ӐS��l-�����x�� m��5�o�ؑ�FS(H��D���-v�1�İ��+:8�_����D��!'�9eb��QUUm���<{���܇�(��ϒ���L6���{1m�-[|F���k�!�7�W���~������RK/k��� m��I�����x���5�ٰ�{����/oWJ�$�Âc�����.s�˓�zF�����m��	U(�氕-G�N\�U=�ѐ��ϫN,S��yg�VN�)385n`Z+�0�m�f�?4!���/��X�� w�j1�w�T��c�C;�:�Z�"窎�It/Ɵ%�ёU�W��c�B���g�gZ1Z��*7����$��C��`�!�uPxE>�Me�K��Au�0^��@��v8�� &�/y�7 �����:y&'��*V��LX�����
��<�Ň	�i�p{&�kz�a���7Q��>��8h����fr>�N���%��Jnwݽq�0#��i罒��B�Ξ���NJI&f�,@�����s�����V�.Ց:/�-�z�����t�e���Y0��7��;�a2��)��E��}��(�ܾ��ژ�"`]��
���C�K��~���8뼚�H/�yzZ��,������>��#g^P��i�ʕ�c��'?a��K2�c,��z ?.�}"�>��S��N� 'z;Z������*�e���,������Aپ�`/@�m���i����;��^�0�sO��g���!Ӽ���� -υ��T'/2���c#p=J��M3�4��8�)̸|bΥ�� ��Cԉ�b4��C�h��U���3`C'�V
��{`3����T<�N���@<LL<��X���k}�D�[�G�j%�d9.�?��g�`�}�xF?���0�0
R �����8�3쇒�	A�B3�N((o+,fQ{��NƘ��	�g#%�򯚤嚂��ť�������-���̏jx��e�@���^{�ԫ��w�@� �D#�����˒���jj��\���Wd&��+�U;������|�ycn�a���%���A��e1{@!�𭾗gR�MF�"�d� ��6�j�4g�P�6|i;$�h�C��=�;q�L�v�<�i �r��Y$&��ɗe�>���������|^S~����aB<�ML���,~k5Pd�C_��D���T�B�=�z�����3B�-2�#�b��4`4���䋨����m�X���ot�\2�9xm֕���St-���;LUra���Gآ����94)M2��gYX���oK�'�,�5o�ć�3����V������4��@���H4�}|vW�ao�͍���>��D��L���/��8}�
�.4���S8ˏ5$��3I�8��I�`0��5�4���c��*�"A+�e����>ݵ�5ݧ��~���V����E�՘UM��=C_p��~87;(~� 0�Q��I�h�a�V�c����u�.���6`ٕы
����n��K��C�`jc��3OJA �qo��m�m}-��
#ǠJ�_4��f35<���8�i[�#��}}A���7?�U_��S:=9MC� D��a��_!�:�]�46��%6�38	9%VO�p0���Ǐ�����O�?�4��Y�=G��\�I�����2�2��x���v�J��W^�z*��Q&�4�6�̘�\��J���f}�J�T���	'��ԏ����tI���i�e��,��Y�"�7�ڸb:(1˥����n���º{� iW}���}_�\�~d�䦬�r>�R��ѝ5�q�W�2�(�0Q�JkhOv݃�i=K�O���t��\,V:��^�z��m8
�P����e.���<�?Ú.��Ɠz/�a��'���yЋ�f{�V��TU����5 ]�� ���!ް�ƨRK�5�^��B���.q�UL��������Q� $P����ܥ���y0��n4�:ʌL��ս��z�;��� E|�c�ڭ���aK�\ ��{�"B��Ody;/��C��s:�HI)8#����Bp��GJ�����גF/���6�V�3ҏg%i� 	������7�[�ԇ<�-I����s�3�M�a|YH�!1\� �J����g��Y�mI�;z��]��󓔪�L�]�I��9�~pf������8QP�� H���{	T���D3qBw���=D+�*eu�yDֳ-�P�A�f8�+ҍ�_�Y'��HL�>�n(ٖ��Z6��Mu1���}��j����[����H�V_�V�Q�6�H��z>�
~���S~?�('>(�(6B[�WzF��D��$R�ا��/Ί�y��х�M:�JUܺqߚ�E�J)�~��z�ϙ �j�ۚ���J�1��@Lpw�Cm܍�Ѥ��SqZ�
׀C�����6�Hϝ: �
�У��bEF,�ӟ�t�kũ�]��$���;V�CX��y�Zޣ�D�|�BTH�.�"�-f��*�2,~���.��������V:R>��k��L�.�a%���x���?�`V|mjL��U���%A:'��p���v��B���p�#��6�$��cׅ�7�U	׊���8Ъ%4����JC~��̣�Z�]�>��XF���Z�C�)*�898�J$��E��rY�7�tOwI@��#	(�Bi���Vj>C��UB~C ��_���:A	]��Le�[+ۚ&��ʢs�D�s�GG�4��?�� _�A�sQr��V �EF�D�Y��:�8�vf���n �>&���+PE_m�)��kB��u{pO���ZQ��Q�wrP��$l����۷�>'��C/���2	�{����ŵ�3�A@Q�0�������]0�ޙTʁ�6ӝ
sg�B���ş"���z��E6�Y��B���v]��ƣ�½��O�h&nk��y��&wn�ASH�E#At��-k+��[|S���,��*1���Z�:Y���!J�:�UM�����Ә�u���zQ�1�׋�!"��Qy�����5C9�}�ҔD�)�����n!�W3/�9�.��5:z'97��ߓ:�ʼ�_�:��Y_2C?]:�;����[d���n$�މ��X�܇��q4K�"��KxB��%s�h�3�2���(�I��$�Y�U*-	~���"�6��J�V���pp5�%�QkGG�vTuǦ�O��j�;d�xa�����M��}b�R�6e���\%/�=n�슷�Ɨ�#���b	��/8�=����%�|�� ~�s	gP��%��M���3ɐ��nDku ��@j��|9�F6���R,���Q��=82��X��}���2˹;n����Õ��4q�������f*���_=�p\*�K|#�H���g(�>a��?
��E,���[bm9M�Q]�
;�z��C��F�U��Łz�J2��2�P��k	ޛ�ӆk�9s�LS"I��ܫ2O�����lc�7�ݵ�y�"�	�A0��~G�.��_����X9���P�"�e���e;d�;>��[�Ela*ya2�s.�(��3�3;�m�1'����|��5fHI2�܊����{˅��_��z3��O"k�&୳3f��<��Xp��2�Ԋ@�4оE�w߁�p�	W�\>i��p�L
��X��\�� �lc�K\T9w���u��_.��!��(���o��0�{k��G�9�����qڣ�ȳx��qD��4��SQ�w����r�O�^�~[Р��q�Ϣ;ƶ�H]��q��A��!Dv��Ȇ�FƈJ�'´BX�]S��
�2!Y��ᗑ����eSqm�}�Fs���Ù���,��S�$@*������4i�l�U)8y��8�/�u����Ʈse6Q�W�,�}u��T��pH�XM(�I5�tP9G`�| ,E�U|��̽�h�"28�B\΢~�bЛ|�Cu�[PjNB��V�uQa�w����Q�LxAة������ �!I����ycw5�ӺUe�vp�����:���.nGA�;w!X��7�aj�#S��

���J�M% qڿz�VD��O�N�o�?R˞xiuVD��v4���Ը��E=q6�k�ʵx��,59g�'���Hq���3�Q��X8��;��=g�s; �i�j��op4�
E3nR�D"�JQ�eg.5����}�v<�?bQlh֋���z q/�Ѡ�Ј	g`CIb�MF'�)�iJ��BӼ�����)����z�K�g���8y�_���|��������pчS�cc>��< ��)E�V�Ɵ&���+B7�1�t��'9������H �<H,��`Ԏq=����΁�%6����7��">S�+p��G#� �A&���	���W�п.�#��!Q�wX���Vt���[w���U{]u��{]F{����E�a���r�3m�S �]�Cg��bS*��gD*_i5W�L���$��>k*����g]�p�M���G@yS�|�+�ڥe�+�jL߶a����e���@${Y� �	>IC��h��2� ���L�J�2�t!�߻�^^��k��,����m7o����x�����<B����Y
�$T�%�$+xo��S^�������t�Ը��L�n�ۡ+?Lv_���hH�M�{�]�Ԛ�`�E.b�h��@��%F�f#>C��$�V��:�]�:�j�k�#��O��Ԭ��|�vڔVDM~�t�P8�hw��畲Ǌ���U� v5�o���a\'Q훨I�k+�fN�=gǴ8#(�_ |9`t�'�rL�K���T��x��&w�t���b��$�Y��P��{�m0�	��*��d���q�69�fykl�H���q9f�&��0��V�r��B.)�c<��,gc�MuD��k���X��Î{:iQٺ���>E�9�JѓzD��4i��u��Z���E�G������iy&6O�|~�"�rw+�U�E�0�t�k��f�zh�A�y�y>|Ym�D�f���fT�`�Q�|�LQ�N����Qɏ����x�F��>�=C~+���8��$�⃿b��:�0;�O�!8�pb�D�K��;���j-5���!I��TzʙO�l̲����E�:�������Y|譌\f��E��g�%K�E�0��Rn�AA��4���[�Аte�be_o�f�	��:b�=/no	6D��G�șY+{ĺ*mB ���9��Dx�jjZ8 2��P�+
�m�^/߂����x��>5|�;��T�����Q篫�z7��|(� �����iu���37v:.�t������D{�����ʊ�.?�ѹ���%����il7;	q��V��W���.#Z:�����!M(2 �Zk�oI�#}5�c��(���p��e���>��A.�x���Vje��l�2��ǆVS/C�D0?��C��(�ʅLk�c`�G�@��j����gY����n�)Ce:#o��Hs�+V|9�5�1�As�Ț��C_J�����(hMӦ�h�Ȧ�~���	��Jf�봯9(0�>�-�l{��Z>��{�Z�G�	��s��MU�/�84�ZVh�7�vH�;�B�G5�b"�4�_�I�@(��#���L���hm��[H���)h���Q��v��7x��$��']{Cn4o��ʙO��������x-��s�����JPd��҅��9#*P�M�2�#|Jrσ3����~�����7�/���`1���(?ͯh����J�.�_����X���I oE�����iة��65��	�nX�Z�d�Ѓ�+�n�"� V5Ij��[�ʓ�	>�87<����w�@��7�����B+����g ���1�eᥙ�����q(�!�?��<�f���y���19�hH;���S������R��E~Q�n� V+�4$�H��Ȝ0�`p� Qߡg�tc�&�r�dYI�r�o]���@F0P�rAEye��T8�-U]��nu|�Ģɀ��.�&��4$4���[�X���J�����H�3]Tlo���(��3^��`�D6�kV�)���'�&���Y��������xo��҃�� G�0爴�L6�I���c��!Qa	+���'xjtt�x�明L����ج��oR��6��Գ��8��u+j����,Td4;sl�8�Ø,�Zʜ"<�����ݕ�wofg�$��$ ��SQ`|b��`C��Ĝl���r�?��v*��:��bV7�{#&`��tzХ\z_�'��n��OݷT����j��UϘ��+�JqQ\���Kn���)�qe}�n�H�]6q��&�
�x�E2�I ��S��v�E<B���˃�]�>]z���W[ƪ�<���H3�|�xV�;���Zk�f=�S�?o��`�%C�؇�R��|�����5���`�g�Ȝ����ƺ�!�n|R|�!?�(��@���ܶ��/�X�[�~m�rN�yԳ����H����5&�	��ؖ\CJ2�i���	H0�k�>瞓 䀍ի:�'��2FCd�(�8m�_q����/�M���Hkջ7�m��g�.N���`}N�]�xh|��g�C�8U�P_�}�[<�#�"H�75a�y#��o�<�P����}*�wEM����UQ�V�¹1�V4h<Ml�X��s6`I���źsÔ��A��6g��(�]��N�:0v���r��y�&<����9�#�)x��#��z�\������dӫD)������-Y���&&}ā�"��������R�F�Iͻt�f�[b�����0�V/A��PsI�ge�sQ`ۆt�C=�@�����<B>u!��IorDYV�C�|�}�� M0�ֺiݯ����A�r9.�����\Fu�E�� l�`�EM2-�gD� >Iι��a&8]_Ō��_���^MH�9�}�"��Q[��x�8֤�m.�e�:8w)ߓ�=�C�Yc��(<��" %�q#3K4��������GF1S棑��\ �!k+`C���Lۖ�=�E���{�jV���z^-�@4��2�ߑ�ǭ]Z�C�I���jw�s5�E
2��������vM�;o�f����y��HB��̹�����i��M��,����CO��f�ŵ����@0��b�:�a��V�����6� iՃ�#["����!�Eq��όaɉ�UO/�n3`_U�˶��͎�uk�&!�4/���u��v�h�o�LR��~alP��V�r��\�[�Y4�	'�S4�p����I
u�CQ�+K�U3��������*\*�5�f��,!�����43�4.I��{��ꡩ'�n��(P�{�Bj���"P&�NZ�[�������df��`�x�W]�x�i��K����i?&oJH�3`n!���ynr�+��7@���Z��pnE<!�	�{�ˣE!l9U-��e*��9A���_p�	�;koFL,��)cMk%&�d����*$aL�&������VX�O��H���9e*�#�Ϧ��TS�J�s���h�S��"4�6��C@bI^�9�t����E���KgV�5�dH�_�����a�v�F�,�wĒ���g_V����wڭ=-���u�Dݰ��ܧ	LD�ޤ����r�;��L.b!�>�"��U+h!%օ�L�_9� .������G��i̾rD�Ϣb[�ٺRao^.oj��Q�m�bl��N[籓&l3M�
�W��S�~�����>�.��e$����n[_j���k �=��߾�X�����Qn����,_g�_Cm�<��gj�͡��x�M�n��6Rs�i�W���	l����T
j/ܯ�'�bP?)��Sn���2ن70)⭻�T�C�X��4����C ��5����{y��o'�� z-��Dl}ع�ۈ��CnNϵ���U���Zl҄t��d������R.�ݾ���P�V������և�z����TS ���VX���JU��'WH�=���wE�'��`��=.��G?tH.gF�mɬ���,���	�~�Μ���3V|	"���s2�'1b�J��<C63	z���jt0�T[�Y�3x��oS5Ɵ^L����9���s��H)���Iȶ�5`��w��8'���H���*�0�!�w��wWVk?��9,`�ܴ�wo��#����c�R����t��"�kٴ�e{��	9b]4��2�p'�hCX��!y�S��=G�Z�B���Z��Sc�.�dm��)���*�Z[��49��p1^�8�go�������$�¬c�n�)h�]vh��k���D�ĒnX@��鑈���-W?A�G���9/�-����ns}�zi�:�d����S��~E[��G��B�`�M~�8p�[b�WvFƞ�N�0�+��g!J�Ա�-_:�^WZyDn������ĎE�� 7�����Q�L�[��Clߐ�$�/�9��?Cv���s�~\�����o �Îz��/��,4��afp��Y+v��o\�DV�O�9i.6��(2Z"��&��U�b"��c�&bn�-��4	��$�`�~��A�QY=��9�q�o|�R��5���"�L5W�[D�0�_��ި����ݾ5a��=�^�F{�J��#h�1-d�n��|�hq��*�|c�^�cP`�^�~�7H���Y�o
2�����H��*�P�LHK�9�Z
�n��Y�sJP^���XE�cŔ�q����,jY��+_��o��ՂS�8�!���D[K��ۭ�U�{II"��P�����&S(k!xYLy�\%B0����@v7$sM����AY((�l�B�ibos����)�v����r���#�]�h~�Y�ƶ�j�|��D��E?k����ȍ��$�24�Fg"j��{�U"�6Gg���砫�����o}��[�D=�\\���T��rR"d)O�B�, #Ɓ�7z�`�>�?{۩�E   ���V�� ߯��Jv��g�    YZ