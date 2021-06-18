#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="939394180"
MD5="4080a2dc1e16d929f9f2f127f0814a12"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22828"
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
	echo Date of packaging: Fri Jun 18 13:23:55 -03 2021
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
�7zXZ  �ִF !   �X���X�] �}��1Dd]����P�t�D�r�jZC`r���UPX&ɪ�N׼/܉	]y��v���u��ϳm��߇���w�z�^C�@���.7�ݤcP�9���Խz�t�j	[��O�������t�㋭Ҽ�f��fMx��(�$��2i��k�J��ׅ߫����	��K;���5���\��Nm�{������Y����~�ȰNR���ƶ�J��N���y���4&�ĉ���#Kf���sԐ�sq�|!T���������=6��2+jG�����,8��E�z�X˔=	��l"�Y����C�\�ݗػM"����j,Y��5U�l7��K����'��#5}c�p�A ց��0U}W����u��V-%�^��e�
�0�q�/I����c��	����Zi�sq7}D�u81Au�G�Y���:�\��5ƼB�*���0;�z�le)�=܍u�$Pq�ÿC[�3�]��N6"�g�U�m!o����������#w��(1�C���bV��bE�D�@�U���r��H<LI4���&�:5�g*���b<P�R���������]1@c=6Q�S1��	Z�v|�q6_z�JS��&�!�]b>��Q�>�O���ňT��qaL��Tt�h?� ���?����
���ď*��6|���j|b�Y�"�P\uރ`?R����K`�o��T;�ҷA�R$��w�?]����lx&v�HkHU��ѹ���l^����fV���cP�^8�bk��;��u�^���(���V���-��_y�SZH����C�0��y����NXsU�kZ����f.<u.�Rgn=;w�7��zj���'�&޸/��Xtc���vA����ÔY�
kY��6�����l�-L	�6�V7�"b�{�\���LG#���3��NS��c!�l�}3�m�%K>+Zt�xL�}.v������L�Z�,|fm¨d��V���Aײ܇|��#�k ��a ,2�^������(�x�Bd���Ň�$��e�p��E# �2n4��ꁬ��#߆IV=�"[
��T�*�|�蹦]U���5�ҥ�u����S�1b9p_p$.����	n�O���Ԩnb6b���Wf<!g,g��e�Y�l���j�4�}�B���1�Ct��M'W�3���b1H�̿r��W@��9�a�no���������n�.�d��穯��n��6��@s���0kVD�Θ. zѣz-nўwV��� #k`m�B�=	3ݩ5�<$��SB�pYV�!dL+BW�����`_�( ������zX���yQ��m��]���=(~���V	"l�@�#k�k�˦�r'!��|
~�F�� J����l��S�\ �rF�E�	-�+�7��%�2�U�^��2u�ӱ��y��8(<��߳٬FfM(��N��[�m͉�k�lg�����QH�|U�B�F�[����x;҈�Y}��[F5|�8ޞ1ߖ�f�Cã֐f����eſ�fLie���D��utG#�V|�6�!�|�4�� ��IGn��D>�+v:b!�r�z���O���%�E��n3d��]A7s���O����Z�H���Ȏ;���3`!wq=��B}k�:.Fp�g0@<)�rN.��5fܭ����	�����<ݞ ����6#��>�@���RU���`��øc���[�����+G�2�ݫ��(��(͢Q�¿���q�|���U�]�pt��]��"�29K���y�G�4X���<����p�������C1'���ڶ�^��T�����h�7&<�f�%;�x�ir�v� �d�FB|���
at�(aE<�cVvZz���Y��͌L!S�!�2$�"TR���Dx$������㾘j�h�4R��ܤ������J�L%I��{��^� �nk�w��������gD���nɦ�a����&y$G˝S���]@C�un�۾&���1fZ��OR(�5^U*���y�X[� ��d���ͣ^x���� �"	xެP}���(s(�)�z ZJo3�$��ԅܹ�~l����^9_i���7�*��/��$�jA�rw{�z"��Lֽ�n���Ú�3v�V�eg+L���X�ډ;t��oe�ٸ���ގ�9��⪄�^�:���O/H��G�~�h4�m\��$v�Q��>�����X�(?vze��&�N*�,?4��4� ��9�=yKT1�]�U����_�fX�����	���֍����:	����]����e��\�v�jl�M��ލ����b���G���m�����T/"2O����fr�o'�.lwc�ߡ�����_�vZd�3���g��1�;��8K�)�.�XqZЖ��=�s/oNR���׃YL抆 �t���D��� ´��동�����y�"���R�M��v��'
��8��t���B+D��!�]P?�)Gps�S�I������$��p/,
�?oI�(X��	G o�lVg�����5ۊij���x�񫆻6"):�D��j���"ն��1-�a��Ua,["����0E��U���dڰ}��	�%0����E���O�Ry��I��Bfy&+nɠ�[�\V�F��c(OdXL�4 �kGU���%��p,���a�7���>�G�0���f�,��5�54t=��&(b�v�	a76��Et��g�K�zvV��m�ߍ�D ˣ�o�Y��{��d���v1Y��,E&]�Z�[a7��sD�<-��=�ؗ�ߜ�6��k>j@$�H�֟,b�@~�e-��\�'1Ҳ(	׸H����UVww[ t�=5:o0t�2+�Nq۴Lضnf���*�����^¿ z�4�h�����QL�sєnH�c�����;��{�6�Q�X ��&�+�9��ܷ�@��f�J�"1<F!��k0b<��pSZ��l\�HO���;��˟&�|g3���41��#N ��֑f���9#D�d��$��U����#��y��_��:���b���g�^ffߔ8�A�.5tmP�����>�є#	����P�w��I���E����%�4�24�}�aS�(�{4��hX7>�L��1{=��U�����K�uD��o2�f���X�o�3"~#9��]�L�Z�F�<�k�� K`���d�o�pZ��N�ڽ�nw��UݥM��5�7r��f\��z�	ﰳ�i�G�Q0���H�G��Q��%��ƛ@<%ZJ�1{�Eq�j��N�R.�U�N��\�W��|K��Y1��L����"���@K�⇶�����Ⳍ`�3��V2ؾ�h���gF0iqx5��H��,`f���Ф6��ݵX-�{D�0?,��u���Y�&�(={c���t�\Zr�y��"�����7�R�<�]�
��	���ܺ=�{XZ7#1����=G�RC�(�"�~�U�ݦf4k��_O��Q]{���1Mcőc*B�C��X��5g+%��`� ѳ4L�	M��w�%��ɼP�g��.�yo�c,*�� y�P��Wͣ']������9g���؏�b�@�] +��!Z6�0clSߐtx���6-B.�=�n^��>�ӯ�I�@u�i���b��t��'3�]΁��9k���߿w����o��S��o�w	���?�í��B��-��
c��!p�)�u�p��(���T��[-}��.�(�hv�5�B
�b�)����Kd�ŴO��_Y�%����qj����v����9�K֠��Yׅ�����bg��-���Ih/��+J�Ry�5P1,8e%{y0��N/��P̽��O��Se.f�i�0{�����>�ۣ���ijX� �D\�<<����R���b�k�#���(�gPa��#C��[���%6��Z��{���z]u1OIR��i�B�	�
�Ҍk�����ŏ��U.��B��IS�o��L���*�����/'vl�<�8�i�I밓�3'��y��c�`�ͣ��x����:?�oc�w �z��� |c�w14�+��.v����6��֧��%���FL���ᩳ@�R�K"���ɲo�-�>z�&�o�'�VK���Sɾ8
C
 y���W8Z�����}慜Q�� m��1Ӊw"�yv�;�p�c:=����39�uѻldi����g1\�th�R1^�6\�C�<����Ӏ�[��.�5=k�����(�E�_V�\�Y�e����i�#�(h���>�Z�0�������������gq6ҘC�V�y3p΃}iU�z��=VR�T������`Lp[���Nˇv�X��!5Sv���<BA�0U��q"#=���;m�]x|t>Oǖr�K�3q7�{��P���V�U��$'"�N>���\�,,����tf^.Iz���%Q�����L)޿%�~��)��#[��q�&�E��޳7��-�č�R���AH|�Ĵ��rΠ[�����������9Mǟۘ���t9���#�cbG�
�̵�~
�n+��!p�xHŀ�����Y��˴f�c�~ⅱA�Z�*�1]�������B�Z���e��8Ϟ�8��6&u���B}u .h��ӱd@�@�3N��M��1m���O�ٞ��"s?�Ge��A�0�����{�x�'d��J�;���k(���orf�#1�L���'���݄,T<ؚ�4^��F��d��R�Laڤ/�ج]2j�5�J�2��@�VO��ʐ'F�	͆����s�|�E�����M���*R�P���6b�}��mX��˥<��@կa.��^��p�K���y��MӬ(�	��२g�֏��[�j�.�x+	�i�����|{��o~�ߏ�����Q��y� ʈnY�R�nThD�a8��n;xV�갆����S;�;Xgm� )�7�R��@�/���Kl4jf���͐���"H@���HA�}t3�1�-I���T�(����ɴ�����nL���izrn��4=`F�ȭ�%F�&�a)U,��6|�b��ó�g�(�D����qޓ�,b*��\j/|���?O��?=�{��5nҔ�=�K��Q��օ�
6ҟ��;V��6��Z7$�+�������|��i�ڣtPx��1M�N �;�av��>�=ֳ"�(�L��4p���W�d��)�\D�s�����ݠމ��Iw��[����_��p��ŴW�$YS���r~��̮��&��:D[\so(m��ʢV񑍹�*w����X�R9��]|�g/�?�����Y(�5 &p����c+���@o޻JЍV��%�k�[�McJĻ�a]�qU}5��\��8�W�â��l��^~%��_Ly�#�̚�!>?e�o!!�,���s3��N��J��
�C������<G]���6�$eI�F#����@��w�M���	`�k���|%ߪ+�������:���1.]��c{ͅ�]s>���N�+�Ozpv��8�{P�$|"<~��AC�C�+�r�.0�K�*�x�Ey�%��5��z��+Hy�Ã�{m࣍y��\ԣ�ī��;���� ��3�X�[
��7��"����?���/�b\�rđ}Y��?�z	�7q�~@��*��B�Cx�cw��#�CUS�YP\�@�Ze9i��Hõ{���� ���3��a^*Y����O�*kT" ����ղR;@��<�Bѯ�o�ſ'PB\R�%%m�g�XF��X����r�5��"W颧���������=r�{�<�I�H`a��ḧ5��ˠ@���8B�"�b_�=)�O'5�&��/)�y'L�h��ݘ�U�m#�y3/�dJO�z�wa����1�yV�;S403�������������ZԞ�!t,��<:m蟟gc��9=�' S&^ ����OB\�X��}����6�*��z4*;Ƈ_W/�J�0O@?BɦjX#�}ǲZHM2���E�b�ݻ�5.[ß��"CпÙ�z�yVm�|[�;��K&/M���:��l�(B-�<&�	�0�#� ���e-&
�|\`۝	z!��Ol��/]k'-C�tC)Ϫqz��S�{Q�Aw�#�6�K�3>8�-}�ף�Re����8��]K1�S�!�����e]>B(�!�:`K�B�2�+�$v�T+e���������[W����'>j,���
8�|,�#\j���VuRleq�mW�1�uN4�m(�q�;���n���2����{���:u`�ڜT�e��]Z�����uT��|��Yu����*Ė -��_�%���oe��"��~J����lt��ؙɦ�o&�H|.N�.5�I_�u#̻XWq1z����s��
!f���!M�f�����M��en`|�v�K���(]{���}	��b�r2��%���w����c�.�M~W��'�|G�g磺�k�?���0H�Se��M֟�+��#�I;�'��ц@���Wd�� G��0��ZK�S����y��&:�j� �=
&�(l���Ơ�O�!�2�a���*n���J�޲e�\�wFMD�V�5) q�sz�s������B��>
ȹ����F����ܼ����^����7���.�׈�{N�*yG.B��p_�a ��,�(��ɶll����&,H��T�ɨ�4!�'Z��r���EmG��-L �	�ɥ�97� �ό%!���7F<P���~����Y}01/Nd	��	O$��jc
U9s�ϸ�G��������>nrt1��]<�\���.D��>���8���#����g��%�pyR�Ca(�%��P-�R(�?���`�u,ӝ1�(�ޖq�C@Yd�s����ܚA%�+V���Jx�����!#C��(&���YI�y�9� �A�A�ȑ���Hg��y�6�V6R$��%-��-Xsy"#�Z�;T�6�99Dr�!������]	)��°�y"�#��,�Gw��-�pm��Gވ�:���*�P�%�,����	h4�(V�m�K�;�G�|��眍b1jT����g�k��Gv�D�{�XV^�o��ڵW�J���A�Ý�<�d���R'AR(X�`s9�[��0�QI
�ҕ� ��Ha�U��rr��ۑ���]�(!XUb��W	����]umRh���"=�U���^wD�g�A<�^�Ѱ̚�݊ Aw.=ϋ��Sīk�� �M��􄚚@y�dD�ͽ՟l�s��P�S� |��Vy��0괋$�ݡ�Q�'K��1M���d�Z
nX��g-�
�4��T�#8�6t~$�X�����/�sp,K}F=�!��%�g�b2{>�7�)��9��v�l��%7L/�f���ո�˓.X[M��e�d$w �>B�ݎ�p��h�"���礼�������"]�Zu��b-t˔�W%��� �u���r����ԩOc+���/n!Ycii�!y�-}�\!���d�@�(U9��F��DJ�T�'���_�̶%�c���돈J�  �dt9��A��F���2�!�U�l�I�gzU�*ړս(�xh �6庀 =p�h9�����U�a&�a
X	�`7..�0����fN?ι�5��Z�~��LH�ZxÚ�*��2��B�M<��j��2rxW��B��jl�_>��h�+�ھPL�c�âlm,T�滥ɶZ�f#�e�:SB({)�8D�V�,����w#�e�$��]���l�����Y�+���壉]���=;�Ge�W�Q
��jsv����4��;]�P#�!� bHF�-��7��$.vFPf��8#�$��~����b)��j\�7���|Ϙ��Ekd���J��8d�i�GI�`�ﻬ��/!�Z'�3�iz4���>���-�����I�w��©c�T�S8�hZ1�q56$�#�����?���k�*��B�W�>�5Qcz��2_��I]�T�}>tئI.�ӊ2�K�T��V�����T�B4?��f)=�jΏ�����:�d47=��o2z�	�ܘ�ɜ��:���^���㜡(U!��:�|�b<.ߨ���Я�����{��u��L���� r7+�.�/崚M������A��1
?:֎���Ck_Kk(�|�g6��,��w[���\��,:b���#�e㦻ǉ�<˪k�@�x�f���m�K�Zw�m�.d� 0�F�-�JY�_���=n0M�`/��j�+T�%��Kg��̕q:gw�~,D��(�0⻛b\���=��$��&HjiӲk�~� ����Ax��r[|��A��e����ޔ?��s�+�����۪@��e`��술�Or�Er:6�`b�K�s!s]w��P�gDD���%�]T�l(�M�7>�8�)�T�ocdr� ��,i ��2q|�*W'q�������;ڇKE]���U��� �n=�	J��𾏊f�7�rS�-Z��q$$�I��%.x���&�s�ˋ�k�ḡ EV-k��~0[C,B���aPN��*�}�;,�p!��͖C,��<���_���K����kh���5����bT�Tô��dA�T\'s[8ĭ���s��A�gz��YT�C�0�%�\��1��c�#�QtY��a}��a7���i��V�^��`�U�d����@��D϶���U��5
M�z9	��,��k@����}�Y�c�5���\;�؝�L����`�}>���l'��@�O�
��B�(�l �m��a0^ׇ)~i��,_)��([�}��#������`�=����/ٴS5c�[p�;���̓����Ru�qM��*�hk�+����~��gͭ[u�y�?M��$�DG ޳o����wFO��q6}�����Q���M�~�`n���W�͉@����dS�s�k/�K�Gs�MrL0��L,��L���쨫�Ιo��uuS�ϵ��E���W���/a�\A3�֞R�OR��`2����ل�[���E`����?�;��yB��툪��,�;�5��Ja2_���M\$@1��{Y���1/�AQF��'��6�3�҄K�ݡ��b�� �3�@��<�T�<�%���_ɿ��0���o][0��s�E?q��B��d~�RA�VA�T���������<5��hx!-�sє��C�Ua���i��9%N�<��~e?�҆'׼T�'��G���h(qQ#��&即��R����d�J�c�LL�e|���I�e�Wʋ�5[_�H&w��vz�K%"O7=�:�F�'_D���@=�#ǻ%�ȵ��p*�J�����C�Pm�\��$"�5�+��Nk�'3��ِ�@D~��56�,��-�����. �c1�X��M0i?��\��>��}n(tͱ ��昷�q*�r۵�1�mN�ߵ穡���i(�V�՞��@���렐���d��sq`��Q��pf��m`�H���d%�2Fwu�sEň��$~�H}��(`�	_��QW&B?��/iv�75c���>�m�{��������{= �>+E�|r��w�1ёo�ӂgL16>j�Ě���?"������A��1U�^��6Qf��p��
�3
���z�v��N���� �֍Z1e���ݣ���%ć����U�<��rܖ]���>�s|��z��F��� l���O��[�=:���3ݣ�$%���v)&�9��l3�����{�� �`�Z7"�A�� ���"�K�Ǎ�b��h貵o��lP��&�����j� z�J�EM�a<���a�w!e��q�&�8S9lYµP_֪By��/������aZk9���D����5�if�{�Ze���D�I�Y
���{In?�ښ"�%4�
�j�T& l�۫�B�-�ٜ�4�p�zx� M�r�������\�cw�ΊwvG�9ex��?2V�\]�S��B!�"�xŪd�/��1u���)DwEG��re5���M�"���M6Ј��
�r���^zb�bQ�RMV_�p��+2@Tp�"�����yh�ٗ}�$~���O����\��S`b!�&��U�*��E��_NL4���z�pi� ݗ0���Q��7��`���%:0�V���V�S9�3'����T:���e)�(����W�JQf�����~L�7x��!b ��꛼����֩�I饑Țm�F�����k�)"�{;(��ݛO������߬�4���=�j��6�����b���{��x#��3F=X�׹��Az������}��+��o�vXŐC�������ϰ�
N�(0����E��y0������ݮw�#�&�u-E�_D��|B!�U�3�5�k�%4�\�ϠN�i��4��ƴ�1���!]�)���B�2S+��V�%4Շ�;�c���e�`oU�ܶ�c��G�$�i�gLA�?y����Zn�^���<J����7:�#�W���ȗb︽z�4�VPП���˳L�]���8��n�B 3;�T������X�l�BY��B�1�t�J��I���r�\ׯQ	q�ݜ��7�XE��p������.�ݨ�Q	��q�,ﺨ8�E����t��?�Y.���$���v2ť��.�cW�܋��������)��R
��8���#��s��՘!Yɲe+QN�h���? �u�Q�79~���4�����d���Xp���PbA�VE���օ����?���1�^���-Ml��x�˳���N�lT�*HiПz��ڌME�EZ�������څ��#��\�kP����PU���N��f._ v�P���Q ��h�j��3��JI�꾷�qQϸ�!~3�;o#�j�6+H���NH�6y�_J��y�H�8����(�E���B�'�/�����ʣ.ZKr�x����g8+;�Y�ڏ!��C
u���rԡ�f�č_���=3�i����ط 6^I:?��_��3f)�����|T�v��,˧r�����k��^>u����¸d4���j�ێ�-K⻋alQ	�(�"K<��q�Pk��yMJ`S���j�n�%�R��V7|���,(8�6f"�Z�G/20YhW`̡_�$#�v��M1.Т�:�K�1)�X��˦�b�;!��&�c�w.Ϭ,�/�3p�m��D: ���-4��g�Ot����f�x{ުJ����f��@a�Bwy�6D|�^�'�=��u[)}Wy�wڻC��Rj���H���D2b�V�T�k��\f�@6��|�\  �	m����٤]S��2�%Yy�[�"�R�vj����N~�{��d�x1��268xj���Q
�Z�6�U����N(~�����ݗ�I�"���|ڔ��[��(r��z�G���B5�UW�a���Xުi���f�+��8��<��#��	FNP����2?[|l�r�bK�c:��i��B���� ݃ $���}�P̴ַy?�(�8�%�(`��,�Ղ.�C���q^!��P~:�b�*[N�&�t�.`��K*M6�6p���EB��e��Y�Ju%뭌oF�{�<Zs���������Ra]� ��m�ɉ����ԕ�R�qޓ�(#��V��ƨ�ޗ�� ����)N���z��~��!a¸�v^�e�8���^^9O�\�,bb�\΃히h����*&����ұ�����vポ���#gAk�s�T�S	���mp��0ݺ7����y` JE6���V������F�	��p>v��A�}J�4��Y9ߛ�J�#_��U�b��ל{^��y�Y����k�/��|O��e+�
��,[���ċ��&�hӤnC���n���;N�fT��y��{����A_ P�z��ۜW��Р������UOKT�ޖ7��T�� �$�~���ԼAN�A:������ )��q�>�ʪG� �F��AҥB{y���/bre0���d�r�*�q��J�vm˻�G�N�:��ީ@�CiZ`@����K�X��Jk_:t	z�'��K��{3�3���i�O��Q�ܣ��ү �2�I_�[:]Bط� A�ka|/?C��;���e��==ވ�n�~���'U����դX�f�h����&���W��ЇT>@�,zŎ�$�������a@�-�����mAa�k�}�p��S,	���)n�.�Rl�&{7V���p���A8KoĈ@.�p��N���=�x� ̲��v�CL�^捛����9{��F4��=�4;G�C̄�wx�>��rʻ.�0�{z.oO��s-{i2�x>.� ��nX��y�5���]Ycɺrяj�*W�X�d=����鷁�����1�<nx�]�qҰ���s_r�Fe�#���;�r��j�-�^���O��U�hs���֠1���5r~>���o"6��2	��&Sf��V�Cr<��j��� ��Ц�xD����"C�����A���lc|�+��C�h�񏧿�@��4ʈ�q��WQ�u��M$�����)m�]��]�n�bn��L�Tpa�T����c�Zub�����,�7�nِ������Zò�jFK�TLǧ�{��n�;�8a�撶�sj��Zڕ�o�Bj��n��l2�/�P�����}��=�$#��ٯO}2����BA����B[�BgӁ��NbL�ׇ=�m:��� b�;O��Dg}�.�*�X�DԚX4��A��������^��Ί߯�#� ��i����|so�Jk��}'���ٛ����@��?T�0�f���0o�zE0��ۇQ�'�=l+���O�i�x����p�mܑ��K5�x�Šy�K.�i�Ah��-@��+8`��}d'��F;�ի�G�&����U�ꫥ���3�{,�+���)q��̇�zN�x�i���X�m�GU�:f �!�iɧ���Bw�yW�o����I���4�����������`��?mF��7�"��{z�y(���Cf����7S!�p��4�.���4��P��钞�)EvgZ�t8ı%���?�o�z���^3��].����%55�i����:I������*��3�b�o@���ؤ"ݾ���%��Lџ��/xL� �k�0r��`N��\�j����4��Y83�(U��O+��*�̎����x��%�����<g�v&[��:�U�����a�}������$�m8g������ħ�wqO���0��5_���=ڻ�_���vic$�Q��mD�����<�tS�]�V{n�km7�<�4χ�
a*��>���?�n#߬�!qxz�$ݛ��ϧ)��L�̚+᳻ ���T����`+U��a٣�v�ow�h�3�����9�#�Q� E���+c4=�쯈�b�Uܮ����FDZ��̝��4r�(3D���L�}to�7��؅��(���kF������G����z@��������4[��.W�:���#�ͣƌ����Ř���c�'H�vO�ܣ�����F����MkliE���,Y{����>7>A��m�wf��eC���������K|���ʆ�}�!.���N��&	����R��o��[�^:aCp��E�N�H�z��t���COdYoJ%mlTrl��NT i�;�ž_�T �&F\Of�0Y�%�� �<z4Ł��UÐ��"��(2�q��7	���b��үxFX�ǝP����פ�T9�v���2qQ1���8Fs(HW��0 "=�җ�|��[x�� -�&�a�V��jrTV�r�����v�ݩ�_QNDP?� -A9zm��\�s���~����T4��>�==�\����-7�{���~�Q�(�|zM*N�˃���vChԙ�#̞k�f/'\���q����S]�K~H��A����?����w�tڐ,T�.oo��"�R���i��xAz�7�-H~Y7l�J��3`������ ��Y9� NX��0Z����̂�g�j&��˹��|S�����m���Jf̶r�\!�0���� )�2���"]�:�P���ynE��]qYlʕ//�;m6`�����0L�ް�ۓ��)�1���a��%)dF#��3p{�F�ip�Bc��I�E��'H��� ,.���Ԙ�	-�LhB0���p.Ǝ�?;�l���`8�/�6�L=SJ��_]`s��8�bе2��v�d$��]n�¾ڋ�� M[DjE�9�Q���4QO��\�f�6�Mm�fW`f0�<�XX�c��*MB@xd�F��Lٔ��n@Yot�	���,�U��v9Uf�EM.�i �ڐ8��΀�b������C�Oy_ۤ���=�v)0Ѥy�T?1n���.
5�'o�w��쑩�-W����d��W����R�/�vչ+�Az�5��(��d�X*��ܴ�4G����0;_&�d<.�j�3I��Hw�[6�BA&���c��9��f,Dƚ�_�MG)�X$����qbڎ��R_���򗽈� Q�) �3v�v�*��NWOc�^��&+C54�st�Tz�$�9�	����^ QuH 1���6O�!<I�G0����I~�6����tV2_:������+Ƚy�#�@��8yI����_�6�-ih���g6u�]��1HQ���j�[�d�ƹ�E+
7J����T��������͠�*�D�#�@�[:Q�ִK�X��cl�/�Nyc�f�i���!��a�`�	�?9��OQ�Flņ�;�Y uۙI*j]/A	��9�U�4�$�Φ�K���՞��(��O�r1��k����a�n�.IAż��Y���U���!!��)r����};�e�V��
`:U\.�pe�&:L�D�?G=ѿG�`�ZF���3�ϗhEá��!�)�Q�#�so�C�8^�GB���41w�q�ѡ9zԷ�)���4NA��K"�G��K�I\]�Ldh���Ma�{/�#ћu-�+@��[B���*�l�(�c��r>�+�ifc~������S!xS�+���7�	���U�J��R�y�,_�U���F���[������Ma���l�ŔL[>�΢���i��q�w�ݹy��knU:n������͜O�wD�6����P���(����!ʯ��N/�a��Yl���[t-�]������I=^W�(�w��}j"��q�����*Cޫ���J�7���E�%�o�E�uM��|ܷ��"<b<zA�h�D
ޜQ:׭��� �!���A��U��H�>
A�+�3���)�U����Ah[l�����G��p��2l䫃T1ۖ ���4��$�txM�?�(�����.�}�G�� 섘��D������e
g��K�@����h�o���®,(c����̖vX�3��Yh�/�7:�E����ڋKRTk��F�vl�-Y�&5(G�k�"��&%Fj�d�!�i��5%�%�;)be_5��X��i�>��;K�0�Љk���~� ��eu���v3�Ѿ@�H��0Hd�����X�Kn|��D�F�(����I��0W�����SR�ɚf�g}��?��iY��Ρ��疙;���-5e��m��G����L�DK
���
�<�F���:�8��U6�v�BaI��Ҳ-J�~�OO,xs��4l�B#���v�ř�j(@�Q4���w���z�_��ͨ�Ntۄ;w:N�&�#���2m<��Ϝ$�f�ltd�`N�9��6����v ^��W���Ԯ�ms���RѾ�6a3�?/$��<z�G�e�Z����J�M�>?R��-u�}�&9� ���vN�%b�]v��^�m?��ZW�@����� �#I���J���BZ���xjG�GO%ǚ��7��c��+i�JS�s>�
�{�ڙ�.4���ֺ���s�[}�2�y�j����q*v,�C$%�s4[���� ��؟>���iH�[M��y��6b�w��-�%픱��QC���
��_��c�C��Xf��P���?̼�[�����^ď ��C�ۢ �zDJ^/1�6PD���_�zA��?� >Y��Xԥ�^��۰85�|�C��:^.�P�˯�~(� �%ռ�hw�q&��o�;1�D�Y��߀r#��8hf�gjnҲ�������E?AGtp��|��:)�.~����,��v�a�%����"m ��K]JB�M�SB_m��lWΨ��H ��g)_�pBGpPLX�$���/ɟQ�sq����'|�y��R�"^��?��������҉,QAj$c�K�PbV#�A~�ʱ �;S.u�&�l���$W/��?߳�(����B��=ڱm�v2"-6`k���9_Ÿ`�M��ήf�tT�i3�Q�1?fI�Q��*RF������r�Hg�7QF�/ϻk�l�#'�`G`�O�3���T����@��&�P��Σs�2�CI�"�fF�~����h��r�j(M�!���Ĝ��w�G�v}H΁����_CqE�_`��uP���.�������C"�5��!C~����� �h?��^Tigu	��p3Eb�E�UV9�L���~{t�~��� �֐��Z��b,�����
u�8�Fxӭ�q�G⊭��4(�K-z��i������8��=������𙲭o�����%�
��k�W���/ŽR�Q�\ف<���4�z^�Ԅe��k�.�M��j.l^;[�i[������l�a~(l!zޓ�E�L���7-�m	s�o��Ǐ��v�;��?��\���b����Ծ��&W#�z����̞͗*Vt�����<��I�t1�D.��ӓ����b�u�&q�>c+vP�������t>=ƴY��	 ����j��.T��F��p����bu��GpΑ�k]aP��{(J]��.
�,������P;@9B�_��R�������4�-�.}�~�w�[�?:�,]JI�h+|۽�Uz桁�h������"����C�l	�l����S�������;9ׅe	V�4+8���DR�2HF�9�k�c�+\�)�6�[��<��׍���0:��y�wz��^�ה�-���_x�rc�U
[W~�=s���t��^�ӓ�oJ�_x�&t������Atٓ_�����C4g�8�kn{s�_���,�7I������Һ�ͿL��c��A2B7:�.���,�W�󍐎wK�씳̹5m���[�=��t_�M�2�j�ak��˾�h�΄I����8�7�I}{���K�'sl���4 �P��������E���W�::]%�]WS��1#i&����-
�-ˏ­�p�L����~W�3H/��r�k/gA��Z}����[��j�{S�@�c�5� �]F��i���'����G�F1T���:_��8���V<�W���oj�K�U)�)�����?���f��r�a����ET|��� �[�������h�_�R�V��M*˦5c�M��S).��e���i��"K�2f�zN�ۗ�:�LN�q<��������l�Ȝ�ܼڙ�������>k��1	���,OKu�:��!�{e�s���a���8��J~�wc�ٴ�z~|[#~DP�+v�<j́E%Zn�(-�g~ .��m�!��'���`Q�J$�N��>�R��t̫b���D��eG��e��h(��݊(����*�SK�h���	���#�!-E?�,	X��'[~���Y�tVK�ΆYX�u+�<3ڳ�\�N.�c��ȗ�b�w�:�|T\�':��Q��۰U��$)Ǐ j��j�]��t^��_ T� ���sn�R,�?�mJ��%Z��Z��H�[��2��Z��u;�Ÿ~$�����\ϥk�Vpa�Y�C�>J���߱*F��N�����<�Sɶ�M׷,]�bdcH"*����A�M���0�ݒ)�����
zB0��\u�����s�l�����t�1�?N02����#j28o�7��hc?[LpI	��l����D��؏�4���@��ϜK7�p=w5@N�$=�"鐀���G��ł�SK)��I�kʼ�@tGl�9�2Y�<��R�Ƿ��߱��\h#�@�j?ڽ��4F `s
'S���z��@�*�H�(h	�������S�N%�����췋p�(�3��|=��;�0->�|u�D��y%�����?_��TN�E�_�}{Hq��4F��An�$É���-�X�fxx�3[&Tt8bK��e�G�v���aW��_����/���F̍�&���x��<�@3���[�y\�9�Xs/H�s))�#��;J^�N���k�pG��2bS�O�gt��Ǎ����C;W��i%v��>�_�,������Z�)�:�����$%�>2�ƥ������(��B�o�JD:�o�a˃�g��I�5��!�h^��{y�� 3C7���3>�$GPjFJݓ�D�<Y��)��ɮU{Ǖ9b�p+a�8�`l�%v0v�U��u;
��^.iH	�	2(9�Z6����'����n�Y(��=�=��O(��g��=f�G�M'��si��LV���#�B_��6{Q�WrCZ�CC�\�Z�I�>e�?���As�I���7���|�Y��b jC	���$7���$mF]��:ʕ;Z���Z���B����wMGk� �O��Y��B����hq�lw��+��'�����m����\�<T�s7<hO�MZ� h�#P f?�:��v���IVʳu�k1�"�`�(��Vt�)X6"�J��u��`5��*�+5歾\{ɟ���Y+v��۽x����K\���$,�:�f��bP��F��Ub�b�fl��=7�(9E�q;s�e"d�q��\�d���i�_W�M�wJIy�d�,l�m��j�{G�hChg�Eq���2S����E0�}��~A�;�$@$��j��&�*�3����-�U|�q#F_1��3��)ή�dx�����G�<[Hs�r!Y`��9�q��u��&����Z����fTpw�;e��p�Ƈ�.�,�UfMwA��(�m(�G�U�#�AR���)2=5��t���惍E��ly.�w��EK ���}2M�~�`},�����֟��f���!%�"��T��N�ߌT�!UKK�@b��ǿҥ=NpӢ���"�y���<�¾��:Lu,�#+�l�%/`�i{��%��Z�ТD�i\YH��H�Y��J�ǧ��e�"=1ބ�g�W<{<��*q@>CE��UY=
d��0B��o�<�%�	�VT7��C ���Hh�r5Rd�S{}wӣ�����`�r��l�����[�x".����o< ���P� '��N?���@���$��X-*A��cET@�e�M"�9Fs`V��=x��m�қ�:����{j��hvD���眓6םm��h�q�J��(�$ہ/��[���i@��<��C̚���#[@�d�WT����
u'=9�R��m�I�����|y^�M�<uÆ��V���fT
@Z�C��)��H�`⺿c(�U�)^_q&Y�	�֌��ɓgq̍����"S��"�Tz�qq�4�bs��#=�M�+%DI|���s�j!:�!�Oěx�?KH����|[r%���n�{~�����T	)����N��@�a����m�X���e��̠��ɹ�G�]�q]ީ!(g
Z��n�s����4���c>�!3�G��%Fv����J�"���0���8����P�3��UO�6���T�I�MC8����N��$�i�]�¥�kLO!�:����c���Hh��C���'�>s�ެ-�	�O�u���b��l���T-�Ur�J�_8aP��'�.q]s�T=�C��+�ì)���b������{��CE�z��t�J[ 9I� n���"�P�K_IIz�ڜj�|�r�G�+ҷ�O���ƊΚ����f�׾){������� ��X�.�n������sB��z�U�<��
�	%ONR�@�T�5J��M���tj�5&�O�K�ݨ��hv�S� '�R��]H����I�����t���ey���C`�$�_�������	;_?j����ղ��U��'��y��^~$_�"�R����wݍ>θ+T`AW��ǻ�\U�CAB7�c�?@��)*ƾ �E������
k�~���w.��9(G��%���Ws7܌��X� @��	Z@�'�릏4t����Q����:�7��<P�ŝ����٣F��� DK�dnyS�͜q��R��t�N�g�m��x�v�����+�D�ע	aY��cl.�+R�N���`a��|����V=S�m�c�#CvsR��2��'k�o�0?�Ү��o���,���q}I�y��>�����q�ub�hL�R]od�`�m L��k��p�GWH�6m(&-��U�@�7f�%8W��}��. 
�qo������[��i��B��V3�H��)ѩ���2"�����$�)�Vf>�����B)��aXz�=N ƕ�/�Y�VY�ʺw���w&?���O�6�CN��M���T�7�	
k��͌SgO�?��Zo��[�	�/ ='D���xj��׶9��}�h�P�ȉ�0��q�'�C��9j_&�v��(�4:�\�(!�h����y�G�Y��`ΡZX�j�NG�Q�3�@=$��b"�˰���O�Y��05ɩv���:��,����D~A'�U�1�'m��f��3Y��to�`���u���5��.q������:���>��
�xTڝn����`�_�R�\�����,gJ�j�:`��Ğ�����p)���rKi�F�
	/Q�"k�U*f��c;4�݅
mՑ=��d�z�8Aސ�Eeݵ�����~6[.~�{Z�Z�cH�U<�.�S��֔c!윲�l���M��P����Pf�����{�x��I���%��X���ֆ��8��2����ߪ+���y%�F(�u�=�w�5�*x
D���s�d����A��ӻ�B 2��o=�w��P��CD���ha��ο������H:�0A�&,_;� ]��!����bZ~�d�}�'K���LV���A,k������[)���]���!\Ζ4�xR�J�d�#�O�i�t� ���H�B����QJ�QA\b��)�L��:B��C����;���W��p8	�r����a�*a!�>3i)��=�#x���%y���G�fIS���ۺ����n��eK,<톆�6��4�{M\�{8MT}q�+���='�SWֿ��秵�5c��'�_���"{�V��-z&i&Չ�����#F�-��RVB�I�H*�-
��.
��"z�	�`�P3'�n��}��h&�N�+�X���q���-e�"ibZV���Q�1�P7��e�9'�gǱ��K��^��-U��_��=��������1���'�C�w����ss=�V�;���A���QۣOb8�巄x��%}#+�M:�s�M�k���N�}�J�w˔����a�}!bR����yl�,��BWJ�-&zu���x��b���p��<�Ҟ�욈Ը]1k�.�-���	�WX�r�1�V1A�����ؖ���X��\�4�:��Q�M��A�{zT���А�c�p�;��gx�[�=������Z`멖^�c`��Ũ�x)3{��=%��`�8�Q	�û=��D�p��Ni�r�>v���D��X���>j�;���b?�Q�hv��º
���|�r���~�4�6��~o�,,*�]jq�pN��EA�dt��VJ���QV#����'���~�ƃ�� ��hY����5|�b6H庾��;���=r�0�d:�:j^�8F�9&�%�~�+>a��V?۬T�<�չ,֫�bv��� �t�3S#N�.nx�Cwc�+�	/%{H���="��A�mJYo�bҪ!b��W��%���K���T��]�bIO`-�~a��IFc�`��~�ȉ��A���!�vI����Z�0B��C; �������D�n������hz��x� �V� �8*�L��l?�k�,Y�wjׅS��yp������0���� hU�*_s�PN�
�o����q�Ck7��0v��!��GU�.�C��%���ҙb5>KG5&�Q��T�@���Ш5���]�jrL������b0@�b�Ï�p.}���,��&�_L�.���t��.x0��si�0������ņ3�9B}9�3խã��)Ng�Tʝ~a�I.jЂ�Օ�d�c�,0}-;��<
�t!+�6�43�E:b�5�}�"���4��4Ğn��XI��ا�1��$�����:�'KQف%��$ӗ�$|�v�1$���[lR����+6|*�~:@�4m�@��T�'=d&ɋ-�9�/�������εu+D���c�%�΋�L�Ǐ��G-�فW�&�%�~T�aTQ����; ��,� ���#g��(=�5��L���..����th:�(]�ӽp�!�����o�Vq&^� f�    �?�����> �����2yC��g�    YZ