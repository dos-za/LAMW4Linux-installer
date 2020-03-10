#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1258974013"
MD5="17408997d4cf7e0bc276b4aad336b9c7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20752"
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
	echo Date of packaging: Mon Mar  9 21:40:19 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j���6y���*�+@�F%5E��t�O�X��?�����2����)��w"��<}��3vf �X7w<u����j^r�`�gdm���*�˹��tϳM�~�LW��I%�ߧz&��k2q
C�s ������'=�g�d{l� 1�X�i>� h��k�F|�2�bwE4�l�|�)���16�#.w��Ws�^�S�PS:�ϋ�G�Z.���a���P�q�Iܻ���y:�����n�Z��@,#Cl�jv~U��P�#�z�Qj�1���☣i�(ODN�vN,c��4��0�OBq?�F��[Y���Os��rK@����z�߃r?^E��aY�U�-�L�q�l@˫ p��}�z�f��N����Ew�P�I�2��� 2>2��7�x�������ѣ�4��?	Úчb�?g$��V%�1����*�ʟ4��������8�Է�<�VP.Ӆ,�������2�i5z2��K��b��t�%`�#��0�0y�81��E��������c1Q$��3���p���ʩ���44��Gcl���@Bq�5 ���	�2t�y\f�$��04�F�=�C��
�E���;���݌6�Su"ւ��ޗ�=	�Ȩ�t�e�x���{�`4_�6Y$�O��B7�U��t��p�B<G�Qg����)i��o�Y� ������	��j�z *"�t�P���H�8�L 5D��s�o+��zD���RINӪͰ[��%��'�e�!n��H���a�5<�z�������u�Y�T�(�,��.��?Q�#J7�aX�{�fU�,�]��\���3*5��L`��S�8��F0�|�3~�,�p�r^Z�]Qe�]����{X��E��z�y.y4�Gp>E8!�Ó�����ɍ�y�A��,
#K6���Z���W׀��hc���H��z� ~�A?ٙZEAZ�rm��z�ֹ�ͨ>j��Gk�ξé��R������͸�7<����I5/�Y=�7s��QM�U-� �����Oi��)�MK[P�M}��WI����3��!�?FI2/�8&%,l$	� JĘ|��PRE,�7��� H�"�|ݞ=UWP@�(�v����P()�i�Kf^u0/��C�H�	"�M��P�HW�
��"l��)χӒ�v��^:���.�~z�C�Um$��إЁ��6��!�G	�u����[�QQH�@��j���(�,�u^o���,PG(iIβ7b��԰�9����)��R۾��JKy�HO3��R��Q��d|��Vt藰�y-�H������Q�A��k�6bT2j�:�SR��d��-ҽ���Q�GJ�g6�Z���_5Cz�q�d (�*No���hrH�"���Q��#"�}�
[}49u�nԎ���arh_�����$UhI.nc@�71��ąRz_��l9Jb�q�?=�Yu�#d�|c���dV͐˵3�	j�CG)Y��
`��c	d�eP�c.�
�W�t�)����:wkĘ,����b]kPjR�P=�/�s�#D����(�q�Ș�b#{d�&�^�|��/o"�X��C���/�Z�����;�0�W��]R�ѯ�������_j��myc�@՗����ŋ�G�L��@Z�gN�N練��wOw`$�5F�A����}�P�"��0�U��bǋ���-���ݫ�f���+��":�6R��4I���n�lPA�A{��LTdìI��uA�M�����&(q��Z̦��F;��~�8K�Kn�Rl�L�e�i�%Q����%�0��3���� z���i"�M�=(n�#~�8���$Q�d~���]��ղRǻ���k)��M ��֠>p�H*,ޢ��;魗�6J�����D��3|��W�;�&�V���L��B���$�
a ����6Y{����q�|�|x2qю�x�,�~֊Q�4�
RH\MѓD�<���ڧh����Vߪ�KN�m�Κ/�W��o�⛆�M�Db7������鄟R��ڮx��bLq F��OuO�a6�����i�96N������x�9���Q��	�?�-Gc���x>Zꠞ�ܨhV�-���N���ɸ��L��8`ǌGv��q��Q�b���'��@�V��ʠZ.��G
;If~���?�`$��C�)��=�H�Z�'���o��O͗V�t`���oӍ8@����eiʁ4m̞t�t>F?�L;/�����	��?ڈ%��l�k��&A3�K0�쇫��Y�Aڏ�=p�ckR�p5��E"��$�=�FL=��Wz,k4Xwו��FL�-��aO::^�=��Ќ�s3c�[]�1������)�jْw-j��N�mkJ`�_A���ij&���.D&L\o�ϽJ�jjE^�3JT"�L�2�[D���QODM��'��˥����"��{�o�#-x�=�T��;�h��
��x~}F`eXa��pf���1F��߰uQ�r�aU$�tQ�\��آ���%�_�R�_�^�D6�3�~�9�ߎ�zS��fBL���iL�\���Ƶ�,���Q_��t��Gh,��=���_����=g��m��� ��?��A��	D���e��zU�g4#������?<�1k|P�A�}�2����"_
�C�R6w�WjϹl��m�$`������!RY���� �]��f�c��C��E���@��N�.Z2���8���
����-p䜧�(�J��m�q.�UJ���@�p��K��������	�f���>w ��+��i
�^��J���{4V��B�z�t�E6XR��{���V��fmz�D���U�p܅�6�s�eRDГR@�`���N���O���4)�J=��/ǯ�p,DkP%$֏.��,���������2�yy�^������}�l����!����3�H��(Gк�E3~���C%��g���C�Y��y�"�Tzf��ɲq�b6�O	He�a0�:9��[)�Yvû�1T���C6y�4D Y��K��� �u|b�l���)3nL�b/����Z��piMH1���x�8,�M�{���3����c�4>K(�z�QϚ?C�Z����~�8��}����n��wUɀ�λ�I. S��;�"��o�-p+�zI�� hvM�2�����A1f9 '�(��5��g7��~���"{��pWaP}!c�|Ң������`���'m`s�����MґL��L�"F �ܰ�l,�ᲷY���`��	���C[<�����ES�x���+~J�s �A���x�qRn�nB/)kX�˂o���߹�����L�4c�yQ�v�A>������i]�-���1�����_�H��z��̚�Z#�;��
��%O�mi��c(���8p���F:�R�j��3b�o�~�1��M��bRLJ�H%q/�����˒�HK6Wa���O�;�=�Q��H;��w�6j�>���ǾBmy��v��	U���Nv}�ǫp0%2\]�B�|n��a-{��:����B/^���I��Y�і�H��N�<�T~��@ձ�g���mz�}�*�rn�m51��ȉ������;������V��z���5߭�y=��u�'u"3;ѴO���А��)�,s/G��6��R8b�Oz9�vld;3�w�9��ɷ)5%�����U[�������*]��`
�C���f}	�_w W���Z��4l��R��	�ZQT�a�V���'j,�&y%�!��R}��<H�O�G�*�V9��yt�ߜ=5cD�V{�R	�\ȳ(�\\Fɝ�q}����8�#��ctN[�=�N��?�tu �S�OY�H5#���\R�͔-���F����b��������WX��;<����z��j�@� ẙ�(`�����2���n�^B���F�kq�9슧�5�Z.j�E�]�3���v��H���9V�?��,�}�����t��a�,��(�U�"!�Bo!!WM��c�N7<���PA+�$]`���郳`�{R&���8����GphL?x�n���`���y�&:�-Q������P'<6�s$dܕ�x�`�H���'���sKr����^��/���������T��k�1�Y�4�f|���O�~���������� ���%K��sҐ��f�&�hwʶ�
^�-�/2y��^T������N 1�\�[�s���-Kt�N*�n�j�m��W˚�Ҥ?h�sj�$Hچ��ݗ"��qL�'u0���R�����0��U�S��Y����pK����C�áز���W(��
�~�#��_�_OBC���9�x8!�gѝ��1�_�h5t\��Z7|g(������Ȑ�mn���4*V����l=ReI�C�i	� I�<�u���ǞCQ�~��KpuQ=S��z��cv��a�(w�f�'('l�fvzծj{�1�	��

����qJ~\Fڷ����+7���[3۟�s��|���4�09���[;�0p�Ϡ��J�y4���]�^	�f����3�:�������4���E�ͱ���ƕ�F�<�,x6ҧ1ײu�����(
O@�1lE:Y\������T�P�r^F��HR��/�3�n�$�������ZR��Xc�y;ڝ�c�ǘ8�O��)*�i?鉇h �\;�ӹ
�bh�>
v�fP�v��~xuy�U� �*a8�W'�4.���@���l��n��FqԿ��O�����@ęz���dxifq`ɯ�sK�M��Oi�v*z���T9[����P�+�����aMr�t�O��E]���>����O6ٚw9U��k��+��]=��G�n��܀�쬹MX�$
�Ip�p/��羪��N���*a�P2��aR?T_�ۗ�<���[6��v?'��C���u�d�~	�C�W+���H�UZm��X�0��%��+�PzpG�~�ߟ�v� OW�Gv�2�O��E�ð�<�U�q͢S�J9��o=R9ʮ����ݣ���W��/�g[��mh����Dw����}?�o�t����������<c��_�Bh4"����攢^�X_$�>� ����Q�b	coE��x��R�#�{�hu��jf�~A{�-C���[HCW�Δa+���!TS��B�* �>�?	p6+�S��q�PE�R��"��͈ <���,��.t�k�1e4������N��dc|���Y�����aR*���+�+�M�c�`M�����ǎhݕ�Z�Hf�΍�Lvܑ�����%��*0�fr
MJL�X���6S�R�c��:�M�T+��}c�$��[��-�y���3����I�Z۳z��E��k8c� ��\;/5��%�ݴI��_~�U�4�vo��"���;�!t���>E�JMq���������1��A2�9i��J��庰vP�3���kQ(a�ga�t0�M�>N-��䎜O��G�H�;����z�-�F�_n'�0��e�[g���������@! �x�B$�:���'�8C�9�~j��|MB}R����1#�O\�z���1�:�;��G�A���7��eXXrg�ܰ�@y���w�Om ہ�a�Ȁ�$��HӚ�j��7j�ȹ�(}gx�n'V!�aJe��e��=_��$Ձ�\���RA1x�4A]^@�3݅
�H́��$h�W�E 5-��f��@��ʾ�����!��A���y�D�� g5Q�	I�^I��n��
�fiޖ�dc�8�*�#���J¿�qg��Ȗ��k����c�k��������꾄�����4�G͖�Z�̎���j���-�]���Z-a g��t��R6�EcU@y�}�P���Z���BN�r�O��~�*��"/�����R?ki��`���/��6�>L��K4L�K5! �Y>�/�+�j�;Z���[���h�Y���=ȑ�ŉ��J�7\yݖ�\Ź�^�ڹ�h�B�vg;8�svSC��ު�LZ��Ժ�/��H�
 ~�m��Z��V�p-*q�N�5`z4�e6nxk&��d��h��G ϿdـwD��YA($Ô= 3 ��Y�'uNXj�B2���)4{E8�˱��~����V([��H��[�-v]����yf�FH/���Cf�)�hB���V[i2[L��oX��>3����y���/���!�
u���V�Gѫ�Ƶ���{g�i�o!�ń�p��ߗH�\|�r�U���������lC| ӽ�Mˏ���n;�hc߆���8`D����V��{zL���3���X��xZ�F���2FvN��LF7�v����~'��I�F��vN��0�V_R�F6��g�d?FL����t,׎��"D���ڊkH��n����B�|"Se��ǡerZ�a�A������?��+�g��l��-���֖1E|�SH����X� �k
㑿�.��nB�UK�b�k�SX�Ԍ�:��5*7{��P&7`u�s���Dv#X��pſ �ci)3�D��%�lc��S~�k؎K�k�~��*�* ����Xp�BM48؁���P�
�Н����wx�5�R� #�7���Ri_����\k@�Ьg��zwil�Ym:
��5KY�m�,J,t訳K�����ܢ���T#�A�vhf���������.���W��g��r��LG�\�ɮ���"C����M8B�@��P�լ�:�m���g�j0�\���A8�n˦������r?� ���-E�]�h�6Y�`� {��~����57��Qm��T4Qʨ�/�J"M�}�l���>�E�Mv_��1QK\/��u�@;͐�B���\��ud��d\E���'��qp�M7'U���P���>Rp�+cPX����8�.���� �8**ۗ�G��X �#6���.�q�D�y?�)�L�gR���	��/	Wn�s-��c����s�֌݇�Q(� ��r���F^7��H"�E!�'�j������(Yu���a�Xc�6�5;�� ���� q`�>걀��[�������wBx��7�e-����	���
��mCq����{εi%�5�0ꈖ�,��T��[�a7��8F+����=�~�s$p`�4԰r�ۚ����-%�@��V�B[u�iܕO��0���c&eO4]�#g�:����Q�Q�s��4+�PQMN��͐gˌ���ޑI1�*��*�W)\=#԰ge��_ʾ��͎���s��1�w�Z�![�'2P(��qX�(�+V���]�=�n��:�Zue�5-�� ��k�W-m3qm���IlMl譋+]͏���z�p��y���M��yN�/o��8���,z�R=�&9� E�cp�P���Pm��@1H�i���ŝ�>XOK"��$�>�+�]6��H�>�������md�R:m_?g)^\���?�g�D�z�9���OD��$�+����d��?jL8S��Nt��u~G�ߦ塀�J�jIߙ��ǜ������U7��'_�p�*��\.�]�r�C��/�	nz~�i�4�}D�џ�U�Ӭ��6����ʸ襴=FZ��X�|s*?z��˭�����덂a�yϚ��|�٠z�A+�ҍ�%�BtG�4 ���P5�R?�ˋ�?�u��\]�n��8"�J���d�Tؔy��1�zdI�vX희6a�!�$V0�	6_Ϥ�p�%���mf�i�QY$%�W�(��ؑ�=\	��-��ͼ,nc�@�[v�<](�阃��kP��Q����s��}3s��)/	��%N ��¸tld5��.�`��_���Oє7��S���~����S�4��� ���:Đ0>g���������h�h�W�`�0�4�;�L�5�)q�X�(�	��|'V>�6��}�9Q�IDY�;(�#��k�F� �M"���,0b�z �I�a������-� �v�	�ѧ��f�k0�HQf٣����������R��	o�����/�=���ޝa=����2��mj�,dJjt�M��*"J~nl)�ގ�7A�5R0��49�2�����C�(]O�Y�o�X{�Y+��F7x�n����A���J��4HÍ�)񋕗E~S�Λ{SD]�d"�� }<p��zMV�(}�����Lh�|�9�VF�R�4���KW���C\�d~v�n��APLN�F��,:\�'���q��J�@�n��熡_H�nը�S/"U>W|�tA�.9�XPBG��f�12{~4�]{<z���O��g���t[�Iv���]Bd[h�a���7�ַVC���V~8���@<��'Ǫ���0�us�*�^Ԋ�0�_�}�T�
�T�_�)�w�<O��f(�`�8�C	zn��0�q7�E�ԥ��:�E���#��
&o��8E7�������;��[��f�.�ذw�2f�Rg?��������>�Y5��g�	��'7�qŻ�>w��g������E{_��yC$P���,�9?[�Ӻ�.�%�r�3vCϹ����5f�
�g�cif�0�K1��/�2�������|N�@d�%@s�x�梥G!+�z���F�3+��7 ܍��׉͐�{P�����rPnμ�.;@�h��e����X<+T��:z���Xk�5��ջN�^�^
[a���ߙj J��`�R3͝�A�w�z䫆�^�_<��)�Ҍ|�}�.oѳ����Fc�X?���#�w)�,=����*1$�w��>���T���Z[E��_[;��	�b�L�bPb��V������e�΄�X@�%u>[9�n��V
p_\�+]��x�r�Q!������BB�N����8�Fč�XJڦ�j�3�>z/�Z�Ud���{H�_R*�gP�MP���H���֡>S_@bj�%]�l[�|�o̥ˣ_Q������<Ki���O�uxTy�Ji��^0lYZ��M��W��@o 02���4F�{�w�ˮx"t��y��ޙ���HzaA���.m���'!vEs��ܝ��3�u����<��(�6I5Q�d�ʪ�T!PV��0>������W�\�('�*^�c�H~���R�L���h;z�3j��v�@=ٰD���{!�I���Z1��H7IQ���N�.W�m`���g�,/��<���K fQ��W�Z]���'�RكM�����%H�����zy�F�P�#��[�>�²��G���/�#zB=S�KF;@����>v6�.,7��������x�M� �y���I1��@��zI `dHh֚O��qi8��f�IIʘ/��V��#0$Q'r(�:�V�X.b���An(�u�R�%/%�r<p��%�bd�gb�Os�` ���¹+�uD��mB�h����<1�S���?j�(����.:)yVYNO-�����Ys~��B39~9�b �o58�Q(���<�6�(Z��B*�!����	Z��,5�nr���� �?�}��VA<V�V*�9K�/���.7�9 �̅aY&c�R�)S8n��[� ���L"���oc]��]��9 9��|�Ps?ŋ8�Cj3��E�]���]*�;�F׋�Fs,�V��o��]b��a�ga�XQ�[h<�4�~m&r���C�3m��p�fӶA1g��\
��4��5��G�3#L���o�����*���^���.��n�Q���_:ژE�ݟ%a�_�7Z8����+G���u��vW�#�q����B��ǌ�F���%?�6$��͡Lk\������| Br�hD$��QLg��fP?�i�ȱ�?�}?�U��	���}`���z���*��[����u�klr��k�D*%+���2rX��.G��Y���iP��TyB�m��{�Ƨҗ0v�7v��W�lB�+z��7����I�Ka����+��xi���v����M��*�ݧ�%��v���5�ٳLZF8��a,1�G�!EGK�y�B�0P��Y�⅄�Uy��pw��
��	�x�h��%��O�vE��=�7���2�q	R��ٞd��E�Š��1(���u%6�Je*��_��[w$e�|H������z�?-'�h�^������﷚���M������ �����!�w�l���A���u.�K�$�U(f��k+�zALus�G�6���!���ZՁ3?z��CH��`M�$~�v���[���\���cep���U�]��$��	蟃�sJ��g�Mr����u�ٮ�M�ؓ5kϤ�n��	�)� ��"�˓�i��إ�+צ��	Ͼ���>4�b��8zV\��G��᪮����@�*��«��d�p�
�I�${�h�
H�c��.���]����]�5)1}x��v�x��XKIY�^�f�D�N�QO;	�٠�E�K��=UЊ�I?8������$G,. J)�������6�KRcH 4���I�X�}-Y�1�6��nI_��-�A�_��֠\i������>���FbB}g`���D� � ��g�2&��wr�-�Aa���S�yUd��R���u���*��ih8~�MUƌ;�����:cپ�⨶m��-�{��c/�U�Z�ݓ��j��U�42#���<�[��C��_�z�@����fO�>���[�6��s�偳�;��>'��Ԫs@5Ⱥ�7�f�Hj�S�	qF��$�4;�k$��}���Z˒q#�Z:Ϟ���4 �_�ۗ/���f��%�Ƥ6z\�sI94�p,�&����#?�qWN���<��<�\d�ޜ>��!���'t:�0D� �Z��㱦kۣ���Ń�Nz�`,T����=iHD�[yi@f�UKj�ۡ(ޘB�,[�y�����3�i�.o��j�RC�<9��E6Y�w�y)w:��u�+H+���Up����������%<�	GkH'��b3��<�
�!?�4_�X������;���E���x��T�Iw<NC�RG�a4 �[d*W������3١i�-d3��#�W�T߫c;<.����뇭��O��F�jW�IM�Pm����o��L�8{��T������8��T-07���"�X�fnx�7���j�!BD�n��
��w���6��G���⽧��	��]5��ɽ�-��Ӊ�:yIUk��Ao6�a�` �����-�%�.�ӥ
���a�iN���Pp�]<�����'�t�l�[��F���B��ӂ|��̴߰h�J���a����$�݆�E�mY�
؀�آrHwi���Dhǣ�]kW�S��W�oB�*D��iĊ� u�e?�"E��k 
T,�KL9��&�be��V����A;��z
6�1�Q[��e��xO�8��F3�ߏ�X�u&��@��r94��fnG9�ڝ�91�3�e�Xn�����~�yE
�-;�З�!���(ہ��⊚��>+{�]A�^Yx؈�s��V���_4�� .D��x�����'�!1m�1�% 6�4�},Y�lĵ}Ky�F�;�y�6���VQ�_(x���l��ы�r�`�H��<��A�e�m�"'��1� �M�����5:O�`U+��ǲ��#76���ț�/
�y'J�Ɛ��,�4����X<=e�8={��-N
����#�P���A�],�K�MD�Tl�Fln5�(׾N�4Ŷ�7��{��1�S~S�u��� h�y��5W��Կ�*��!E���B�r
�=��(�nr`���{��H�ԉ�X>�.Ez���:���*ݯ|ǟ81A���U�d���c������vIHb�*Z�ݫP4����]�g�A�h�n*n`��4��?�W��?o )����3�M��{5�6�{�����s$�\ҟ�iz���cp.=� ��r�f��*v���6+�Q,M�=�ArF1(q��#s��%���Q��p[h<塒��x����O�&wF:��΋���y#�u�]�،`�ӧ&��E����*d�����{���h�����r�U���9����,�U�K�۾un^�b)��Qr���?=��	cg�x}'tb}ъn�q�d�g���%�� }8E����:2��0�r��y]�&몍ٲ���]WIV�t�%Q���qlܚ�_*ǈ1*��Ǉ�e�`A���F7V������lʅj(���R�(�(��z�`�f*���۞D�Dʙ�m�j�Ӗr4�>Ңc�{�=R��X�E��(������9�c���������Է/��Vd;P�l��$�c����B{`�xP�;�ቷ�~��8�UdxX��=vu��aL�����hW��4'p�
���.Y�N�~`��7F/r������^zQ?�)y�<���|1�L�%����^Ј:�ՀV'U�QF��ϓ"�F�d�{� Cn`�UNF���K�o<��Jˡ/a���a�)�&=Z��x��A.�<�<�Ş_K$�
[�'{����2��q� �1�*��㷽8�6���v�Y�)DU�<G�<H_Cɕ� \.�j���g eE���X�d�P�5l״q:�M�o-ZϔGPa��[�Ӷ I�1��2���%kۑ���#�ͥ<����H�Wۿ�A��pW�8�I4s�f͹��Љ�s�l[�)I.K�X�0�4����@L�o�g4ywk��Pw<[-3��7V�D�C/ߟ/��?已��ؤ���џC˥0V�}K��0Y��_��0�1ˬ��K�;֨��~9"�3)$��4�J��0V�:Q������������ �`�xd��Ff����dH�ݛ�b�i=�&&�j*�r�	�X�%�* �Be���,'G��"��\��?�r[7)��Y��lm����]v�t���$�`MQ�v���� ��MI65r�E���>|��Ȣ�Tc��C�q}�'����+�/�,����O�����r���~Cc�
k�Bw$ Lʈb'�H6"�� `1�_��K(b=�=���KJό˕��נC��1���F�@l�XL����| �&Wv�:�������\il�		RR�|�LQ2)Z�\�J�uT�U�\��ŉ�Q�ౘ�� �������v0�G8�L���n�w
xݱ8��<S-�&OuY�<�KM���C���O��¹I�"8�2�V~��K�_PD+���б�{�~j[�[�ޖ��Qce�7�1w�|Effw��;�Sy~��9��(
��L*"IBL��K?�z��˃*��l��'�0j�ȫ���D8�d`�y4R~��XΕ�)�PN�I�u��~�'#X�o���i�xI9R��D�`��b |ш����E����NY�'y�:$^��
���T�d=(?�"��`���eQ
��2�r@T�F�V�uf�w�O�ޙpiLf���QRgˬ�/�/�C�/�jl6�g�P�i�,����P�Z�;<w��H��i�p��/��Ni�Oԙ:���j���F�ّ�L6I��'���%���)|T1 �X\��o��֚N�g.���M�Lz[�|�qi�mi*3=p�P��{lx&�����([�%�6�}\����"�ӎ��d��r[U�
a$KD�P;-�eT9�1��� ���~�L9^t�4��F���⧮B!�S��q��1Q�j5l�F��#�+�d��9PE�?��b/�a�7��u�5?��Oa�O���΁)[tv#^|+�\�xΘ�g�T�x��A�O<kh���=F+���?f����[��"��`���Oн���<#���)n�:_���7�<�Co
B����F��ݘ�Տԑg.���ő0y!�4���Y͏Y�T��ç$;i,��"Y=d�0�����:���� �8&%D�!�^�����upC"Gluj-f����Y-[p�U����C��y&BDr�&c
3�h'31��p�E+wQ�?oE�.`1c[l��a��6�6�&��zR�y�rN�_�ts����4@�	���3�}4y�W#rB;�`U� �%G�ֆGv�y@��&�B�]��8Dt�H���P�L��:���&�~��I���]���UEb�?$�_��~vW>�7	Tl�ݮ�b��y��q~f��xU�RXDB�y,��K�D:-��"L��=a�m`�n �a�L�=�4[4t4��[�x��>Nde��`���3�a��й}�$�D�9<�H	Z� �%�>-&Kg*�qn[5�X�E��"�ORGX�JA�ߖ[]> �MR�qKǱ�'4{RO����OUT�mW� � � ��������u	IE*��aVPM A�Vӎ�p�C��Y�&$���B�� 馜�t�����)�zEF5,���v�*On�R�:��M�pα�����l5�;A�z���i�Vg�C���=-����V� �d7�R�n��Q����<�J�I�)��de ������ȏnK(��G(Es��ݾ#�he���4eN_�2<|X� �4Wȫ���\z2���������a*��^c�qO=GF��ޓ��0�;��St���Z�qaV���l |PD(@�[�+K�?��BDy���؀6NᎴxza\��`�GN�_	�3�9�,�θaӂ���i���2cf����L3�	7���{i��H(��tt���(�@�\��}4��dV��v�k�q��p��S��=V��_�%���~���}�Yz���	s�@���B��y�}���\ֳ�V��/�,[c�0�����~-���udM@�{����g�������0����-;U5�E#��@=��qRw�0�ȗ��l�>n�9��n�hŖ.�h0٬-ٔ��D�ЋY��P%�`���l��Ɯ��6>�?J�n�km��,�	y)�i�e��>saT�\�y��@�Y5���m�~,)Q�ߊ�؀#@2rK����`�n-��U)�:�7U"����y���v��#���["��YN�V�H?�h���hciå4!d:���,��9"6RY��L�F��_2!�SW87ȱl��8��`LZ�>�3l:d� �j�\x>��<�Ăf�q�B"�Bz���
0O����pm�r�G��F�K����G�:��0����1��{�%�5J��=F2�YF�ڝ�O�j� ��Qx7�528�/W��÷k���9z��p�հd�D�ΟD�����mY�)�J�_�鴡��ܦ$�v߼�E���Šz�u|��8���3�4�F��M7�M�B?`z�Z�_L����#�h$�E��5�fe$��Cè�H����>s�w	����e؏����d�y���&H����>@�FBG���SV�K����U���󨕲���!�b���hLC�]�Sy�P��sm�Od>�{��r4?��pT���O�<����ĵ�k�U�`��Z
�5�b£Z�X�����B35,K���3��H/��,�e����l�XʘW�"�j�֢SE-?��f�A0�5y��ԋ=�2�m�41g��b�F���z���/�ǖ̘,@����5;�Y�1ʙ~f�RW��������>ؓ.�-*-�I��I��Ök��@��0x
ށ�*��F��dT�x�"�r Q��t٬$u��J�˗�d`���� &6m$��6�B�}|/�CrZ9�X|�b�Y��<":���a��U��Ӹ|�O̷����f��N�.���w��d<<��gJ�7%�xr�U�9��҅��_o��hO�,ݐK������X͏FM]D�J,ּ�N��C�?���x�a]o��dp�0�jrTg	����f���Ў�s L;��ķ�K��I�]I��LU���P ���?�m��a��$lh�(�hS�����E��*G�}m6n�2;#�-��4�]�;�� ���uK���KFnU�	����=�鋈��X^���#?���J(<{AP�	k�|�H`��FB�Fr+��b�0U����%�G9�n�K!�)�%$*S��`J+y%z���ۖ�Ib4W'�9�YWPy���Ub�r6���Z4��E�P���0C��0�s��+���-���5j����D8�ȁƌ��_`\6���#��^I����[C�O6�%��p�m��a����L��=�ח����**���Tۮ�0�m=>�B>�>Q������Q"���ϭ\���-��4w>ւ���>�������|����_OD��m�Q�(:��e[�Xj��EbN&�פ0�F��+b؊�p���{o^�r���y)�äu���` ދ���t^��2��g�\�8��ӭ�|^�\Ň��䋀9�@�/OyK��.��w�t3eQ�"�]��p�.�J��C�U�T�D�>+Vs��O"��tɤO��:���C;H�����Z�訬��5Xd﷩H����%7�B���X���(:O;~�i�2gں��I��S�2����Z�Ov��ws�ٲ�!B�^g*s��a����:~2C3�T�p9���;�����
��5�*dy����NfWP�a�
BD��h��%�W�����ph�/voC���2!��>i����"4�C����G�G|ք��7�K���=�#��`H�-s��G_��\K�#�������	�Әl��s�(l��x�r-+�y���fP"9y�
7|w|�~��'�=� �G|%�6����C�>��=��e��p�]�Օ����i l30�o�}v�Q	�b'?�u]G 8���i'�'��BVOCIg�g�Ξ�1���em��� o5M��o��m8�������ɋ1�B��J��lԹ�LTtZ	�\$-���()�(��d���#]����B;'�\�s~��8�|Ѐ���x��8�D\�s;��}˷�Brg��r|�[�~���W�`T9�CAXs�V�P6�"Y��_�V�}oو����,|J��A�π�6ﶟ%�Z�؄Y�W��Y�o��1�B��V���r)!�Y�@b:L�}pG',LgD�J��\�,��B��'�_�tX���ZM��)!&:{H�^����t��#�&à�S��VE�4�8�)���Fl̠�@�q*(�)'�fWE�u��1V	EHWM��5'�|��q�G-KEO�dF�cz{jR�� �B�����M'ʲg�Y�,8n�pӇ��e�O�$�L�w+K�X�o5��m�A��D�b�䍴��(�P�݇=]N��-u��*�8msL���z��S_�@�ia^20���q�˨�����>>=,<��Q�P�w '
<7>~��q���Q�\,�D>��	��c(u����I��6,v�N=�7���4�1�͉z�����7G��?�}gj˛�Lgm*�>"�Iċ��W��|�Ai���A�k�$)
�V*���#(�ח�.Qy��ofWH��Lٙ��_�h�w�0�\�L���I�!8˄���L��m
����ݳ��ک���`Ӳ������fQg6f]m}�ѭGĉ��A9a�o�6s�{����(���d���[���^���u?{L��#G�|�z!�/N�x�j6�vXȽϝ��rr��҉�}��C�J����BH%Gf�H����p>�ď��o� �-a1����܍(�$%�zǞ�d5�'fک�B�;/dS�O�@&ߖ��jV�D�"�p�Y�v߾��*�O4P�r��Ȑx�)�d�|Z�=����I։z��CfC��	i����k�ɳ�T�i�v��ޫ`���:C��Ñ!�pŋ��!�B>u��~r7��)v�LN�yZ��^�C��7ꍳlh1t`kO��E����i������Y�m*���l���� j���U�{A�+L'���
�ޣ�w���B@+2�j�%�cab�SA@� X���~Ip�\�P#}�nAA��%��#愄4m!�"�e�&�	c>�y��v�	��=��qFQ=����{���Ϝ`��
�6���U��v�:�Ih�R��ZM���:+�oS�G���2[lW���+E�n��!��V���Z�[%����`ɡ_K��яI#1�.�HA�e�F����؎U��"@��)"ڧc�q?�|�.	�I�i��w%�	U���3���C<v�o�=Q����uX��"��d���|)e�M�wD-�/K����zu[p��ha�~>�� _�����ݦF�r)�3���X��[NAtn���9*��g��3�}I-��������A�\wY�e|��A�ץ.W5[�����<v��3����3���X�٥��s��Q��:�0���c�����<���6� |�����-H�;���|�&�(�-ٝ��@��F�qF�����}��I|�W� ڰQ_���h2����|����4o<u���٥?Y_]��������o�IA���3��'���~zWл���#H�I`�G�¨3�h�8۫�3���JⲩW�T�����,u��ca�����{8����=�U�}=q~�ۍ��	��e���-M3�R�~07!�ov	����c�~(� '6?.��BSR�	
m���a��U��sJ���c�9)ҩ�]K�X[A`6%��ػ�3r���}tȃ��~i�:��rYN��G��E��L�f`Ƀ��#K1�w8Z�JLU����o�D�%�u8��]���W��2�l�[5#[B�'����=�N�އ��8�3ǘ��f�^���6Ė���YMeFB������L�V$d#"r@W;��Yp�M�)=�_h"R����8�ۮ3��9J�KC��מΉ�*��?p�Ǯ�f���r�3e�ɵC�f%Nz�;*}�ٝ��wN2v�W��Ή��V�t�J�?�%�>wu|���Ȕ���Bqʈ/�,�.I�,�r�`�J$�8b�$�)�d� 7O�����`���J�������)���	8=����=��b�p�z�6���@' |߃IQ;�8�גwM��0�Φ�S�)��d�aW�>���Nd�`��w6��Ff#����/�`g6������f{i?����.Vx� ������(a�)��Tg{�����v*�wf��J���U���e�[w?%�B�-n�>���7�q�
�+>���|�n;���p�qâD�ʃ		���`I '���!.O��{1������D\
�z�z[B���Wv>����K��,��Äj-I{䗹0a�1�Pe�~ө�%�t×�eH~6���N�)�OV�l{���$$�M�2%C'Os;%\`�,���~'9����rx�=�!���vǬ��SG��������K LŻ�7�<�g���\��3�k�����H�����g�"�̵a��B����xAnb֖H���_R���GR�X�
d~�-M��O�N���B�D,���q&�Qv����4���S?��Pxv�s8o�{��2x���Ǔ�<,r_+A�[�W����'+xb^ݽ�WP[q�x��%�3�s�o�DS��� O����� ѱ����bY��w%Q�3'	��.�W ��ִؓ�Qj�bt��� �0A`s��O�}����s�����Ņ�R�+�+ܲ��C����njr�c���yqbذ��;j��!!�h So)n?���#�����@���V��|1O��
,��\�PS�h|����c��\X��!��!�0�KH$���$���l�<��q�,E���Ӈ��`���>:+�H�8�[���'R@���3��g��"������w��T�-����+��%��/{��������\#�0��.�ӕ���������u9 ���Qlʚ,IX�3c��z}b�U�������ց��xi��g;Z�9z�����Eܴ�nV��v,i��-��H[�����H�x^h���b�Uɤ3��ʭo�����J���Q+���H��ʖyΙ��T>۹����!�̳�Hi����z�ѹ'�m�z���qw��I�B�2�ZBV?/�g��T9�)��`��kF�`%�R�ίn�N��g���Bd�Uv�pS�>���2�[%����1�K���*v�&�h�>s��?�XS�F}���H�>��)�șNx��B�c�w����
�P��G�R� E#�lS:��[�;I*hW���K���>{8݈�jf+�AOU�m���0g���2�M��il'��2�wU���n�_VI�P���\�Ƽ�us� �Gݾaçۅ]����q�!-6�;��������������,�\�]�ҫ�)-y�f��~�.�">t%��U�;�K�Ur�Jl�.�iL�!�˔c���Ϯ��9	�C�tg��d]��`1v0h������?*�<�{+�Q�jd`��w�ͥ?_����5>M�q$�:��mjC��x�N1�%A;\�h-�Z2���
Û��g����n�g�1���M��|�����\���o���������Gp�]Y�����0�����N��}�E��ߥf��67"׭4Ru<�!�]�a��m/c.�ڠQ9�W�S��rh�x�
��e�e�[0�锘l��y Rkݙ#�'����5G DZ�x���=&:�՛�I$��zC    �.�m
lm ���&? '��g�    YZ