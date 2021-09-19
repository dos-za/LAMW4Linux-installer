#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="935404052"
MD5="5b80b7bc75975282c8272c4d0ec4d54b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23816"
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
	echo Date of packaging: Sun Sep 19 00:26:57 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D���4��0y��t|�?
~��Q��p�E��R�N=с��'��W��������1���gB���������(=�x~+lɞPꘗ��jN���@}gm���>�u�ėO�P2̌aC�Hp>��c��_���b�Y�Q�d��q
�����C9J������M�+�*���e����[��q��h�_��[H@�^�G��3���#X[�w|)$���A({��+'��=@���z?6��`'�e���M��Z�꾁�5��P����N�8��M�r����𣱅o��իjA���V*��X��ߚ}���/���Vz}c��avy͒�>$��Dg�����l\��o-m�P\Ð�7����6��E�e����7��0�����G#%�'qb|4Ȏ�ʰa��-���-.pbχ��|(�D"�h�z:�VQbQAS��J�{f������O����o����2�i����\��Aӽ���ϳku ����2�t�v�����I��0~���\����&��H١HÝ^������{B�!3�R�Iz�TW���mMaQ�(f(���j��a��upo�	�n�f�77���Y���3�tr�����u!�=��h����<�|��YɜF?G�j^S����`y()�)2��O\���2z'��s3>[��k8EPp��rD~_��Hد�qi*�7�ݽ��[��c��8&���5}��)CY�%�|5@��􏵞�0W�P|�c������?�Z�r��!�n��+ �
L��:������n�0y��+}p�r���!�����K#KBl����"��Mq2v��u(}�e��Tw���C�}@{5��~$x�P�1fg؜�L�+��j��.@q�4��4t}(�keMn��V�t��0@`dM��Q�j.��A
y����B�n�,Ō�����x]��9L�N3�����ɉ���W�8��%I0B-�_۽8>�OF���ax��*������ZY˘�`1Pp������o��ZԮ�c	r�������A�ǟe�$#�EC�U��OE�2.�?I�4�߅9�*�}M���]B����i��	g�E���|�Q�]��K���
*t���_<Z�"ӭ��op
�HXS�*h�J}��aӤV�˿����qx�0��o��0���k��%��	M���s,O?��jp���� �?e�E� R9^M�RA~D<��5^L��zhQ'���#$[=��Ǧb����S���8D�m�����R"Њ���N��++'�>�6Ȗ�y�6 Q5g(y�n����'�{��H�{֐BIg���LE����D��IpCY��6�b ����ޠ�,N	�tx�K�%��H���
J���p�vɕ�Q�(��Ύ�)I>@|?��^y�l���A�L0Z�n0J@l7A0����FIrO��B���SH�Ѡ+O6�
 �Q��_ОP�ȅZCN�Vp�����s��l`�X�Ab�7U�l�h�	�6F�Y�2� Cv���`�U'=���#Qo:^Xg� ��<H8���;{H���-H��ڻ"�h܌/�.���-"�<ŝb��jl�����J��|���2R�9b��I�PB�-�!�XEk)�n9V����9�\uo��ۮ�CY�941�+���Pu��qĜ�����N��t1����4Q0�Y�V���.�R�6m�ږ�E�<t���X�����$�yuzv �
�0d��=U�T�i����6��c|��n����:�螝Wt��M�,c�ܯ��$��a[N E
"�׌��2Yɿ_m[Gܓ�]DG�$���'������ ,T�b��0,FJ�Zگ�k�G:�c6 Ħ�J�E*�`Z�����e�l�z�eD|���
�`��PX��H|���շ@�*�����?诠�`[s�j�Y�cD`�D��,�!����[��𺌙w��)v�$w�w��De�%.2�q`���&���)� ��`d�"%��ޙ��mb�d�\|>0{.9r���rm(:K�F�&��P�f��I��_c�l��Ǆ���	�CN�[�O�~ojv#����Cz��3��	~�ê��)�==ݝ!pl�����0Z�Sǔ|�0�  ��/A�H��3���k3��@Y(0�"�N�j�I�5O/��-����&b�i�}�x6���f�	��לu�%L�]��"�+<T)��kqůӿơh[LN�ȱ-�z��X�4z�-����|ˡ��������.��?3��j���9[UGk�p���@�ɱ�"_z55Ax�=3	<0$5b�۟���cc&�)�G���j*��N�j��<��f��vb6tmQ��C��� ҳc�����~��$*Iͩ�h_�M �Ya�^�NWO������4�Y<����'ȖN�����B��I�T����J�:ш�ӭҝ����<����x7Y!MB($����q?#�|h�I{֠��S�s�@�	x�M����3�5�#�L���;?9A�a%KR`�ga`o0")�NOdsQ	r�.뤗�m"�es�G˸V�����`+��M�[.�C���#q��(�\�Xx�'& ϭ��G�CP~�\&�[�h�rD�X�d��1���m~o9U;?
�C��MV��;��
�]B��)G:�-�&� p�4-�K�#/Q�3Կ����������<���aP����>ˤ$E\�<��e���Н�]"�QH;Wr�}r#�\j�0�"�	�s�A�� �Q9��l'c�iL.����zYC.\!}uB�N�K�E�� �ɮ
7��.;S�e��Â�>�D1�P����'�?����XKA�R?��X�X��w�)^ !+�ԡ��|@�������;w��*�h�"O]>���M*��r
�!?�Qj Ȯ�u�P�='0@��#����+1�8~�!�"���9�����M�Ҧ �1<v��+��t�۝�E���� �<��VDO4����T���z�m�p��х	������A�7 s�`'�RI$uEn��7�Q��y��@��[�� ��ÆFנ\ K�Rm�v��Ã�t�����N�F@��W��1����l-CUf��rAo��f�ѻ���X�BR����>�>��h�\���J�߽=mFyg��v{��l�To�1t'��oGx�Z�؍^�l����Tb;P6�KxT�K�(�|�Evm���C��ʝ���yevxf+k��2`1�d�I���?*~���TD�
i�,׊�H$��6�h�^�Ռl�mx�	?E-f���ĺuJ/υ���pXq���~љy��t�<s?��/�+�_a����u�l.jW�߄A}�uYwQd�����*��U\ck�/T�Iۚ�Ez֩�MVO�������q8bIg��[<*�*��t���,���8ic��	�4��@��� ͳ�$�˙w�Ԥ�P5�b�A��|4�Z�o�a�~?��:�i~������	�2����]���<2��%���:ؿa_;���L��-�Yd]וR΢xV-¯}a������++�H��rc��TȾ@�r��LY�s��1+��h|���#H%>2Q��W�xd��.��|�{Wx��k�f��U��;=EA���ት[��e5�cX�y@����7hpǆ�պ��6�ܐ��FH��O$����]o�B�A���g�͂�~�)�����8;&�JhX��K�iz/2۱��see��f�Q�Y�6��bf�>�ц�HփƮm�-����J���$dh�`�3���Y!дoL���W~v�e��ց��o�{��z8`�£�&�ao��MM3X�[���a�n��^�Ю�O����z���ƿf��9��؀6��ͥ;V.�eoqm���/T#7�3�Ӡst��.� wm�?��=�7T/`�KldN�^ �sZ��;��@��-�W���{�7�7K����Ҙ����OpD��a�]P�{�X	�0�]W��/�gׂY��}����'�wކ#&�pca��ëU$9O�\��Q�Cwwz�V�?��f�Z�ӈ7��|=��=ƈr����=C�S�D�st\����!	!^����d�"�����K<-쓑j	U����'�U|h&���zq��e腖��o�Q5<'�  �.�^B�&�ꌥ���9]���ϗ`��a@#̼�e�+H�<먊��(��P��*��]�t(#����Vp��)"��):|�Ί�[&��7�=p��m��%��Pa$�e�����V���3C��+`?9�l񋡱��S? m
Ȝ��\t�J
1n"���!�m؊�&O:.��sZ�1&�3|s�������I)#��Q���~���ɼ��S�����(��i����2g�N��mHXF�����}��ќ������y��?1��K����!�;�̿�@��^.Ge`��5*�Ξv����g-+��W�%/n��Ȱ�󗢋���^�ΩP��"k�:��:/Ǿ�D����!0H(/7b��t��j��D#���p�+k���f�E	>�P8�W/Z�C��E����\�/�$��K� ���I���-�u��M�sD_��������]m1���4CB�t��Ix�7�L6�]Ku�_���j6`B^`"y�\ls�Έl2^n��.1y_���������^YKof=�ߙ����2K����h���˓�|��HQ~w�#��0��	$؜2g���A1��f�?<�/y�[�!���;�UϹM/Y]�*.��1r��q��Ʌ�n�_&_tt={&�Ip�y��l"B�y%#���Y�L�/��RS�iFeS*�k4?Ҳ�J�7v_��n���ԕ
@�\��h�`��l���
�8l��1�x�[O�%�Q~���Go�G�h:ln�Hi��Q����k��{_��h�~>.df?$�e=! t��J�+��tG�����֒;���}�)���;��(0/k���C���s@��܏l&���A�Ơ�eܘX��~�h�g:6�ǂs����6�;9-P�lj炁_�W:���W+_ˆ�O�;�YM�+��l� ��f�n;#���~���\o'U��F-^
���=�.���w�oJ"�]r�ͷ��ِ�����7SWw��\OM���F���I��5�?�]T�-��g��3����&<: �ƿ�ZQ����Ô�
�����>�r^��?2$<���PF!FB�q�?��|���TO~���0��1q�s,Η�-���./�n2b�����u��r�o�#e������T�+T��v�pX�ÐHg��*�wB%C0����Ք}��ⴓ�CLm1 ��h�	����F������?[�b��6#BL�lB�r�vf�iQ!M��?�5wL咳Qmr�N��,��7�TFH5��Q+:G��:󿎃�-Uء�0[	f"u&�i}��O����FCi�Տ+�	��!,lj�F���K�$�=��1���,���MY��0sN�",��"�N�9��<c��m����0Ew�q�I�}�� ��I�:0������fg_�2�(ꩯ1b;�YZ�# ^yቱ�Ɔu#?���*�s�y^*W+�e��.;�`P���i�q�K��cH{\Y��3�
[�O��!�P�Թ�q&���r�!�6�j�ĩ\�y��;3`�Z��_j��^���Q��5�O�g��z��'����x�ф�Un��f�9�MƌMJs;�U��F&v˹��#C�egdD"�l`j�sʡ����g� [B����h��}�xU��¥����މ������G�g��"��q�o$뗟�DlkE.���;P�ifƣ�*9-�q��s�Gq���KY��d��ق��<��|JѪ�UsQ%@X1�$����#_+��#���5�ٺ�<��wu_�n���{*�"�u�G���C�QNn��;pF+�F�6�>���=y������ Ea+iR�ijqCK�Y�_uQ��5zS�|��lŏy�AH$�D�s�-~�4�}�^�nWs\\�=$�R{��Sm��Y�Way}���4@Ԍq��R��
+ĖGҞ��'4�]����j\��(^1�i���KD^3���թ����O��a;�ѷegD�\��-�w�lR6��O���G��]��JtY�����r��`*��9oVs���ǩ��X!퀆�8��`��p����ֹ(�O��
�t��w�&&O`���k����y��7�W�IΝ��Ag�xy�Ġ�O��#X�v>�`�d��/����po+�h&;f�kXI8��S��p:�mYxi9����2���I��Ev/^TSY�����Bs�b���F|鄃'������������؍����쫦2�F�M	�H��j�����]}ܿ�/�ts �@�7��'/z��4���� �T�H��%��D(��e�*��]��	�G�v"${�H�c04�e�k��u�:g��T$bLd�<0.���dp����A~Fr��2MyfD�u݈��i|�:q�*�R�G���D�~P�f�����#��8,C���|��y�sN啚<%�8��iH�L����d��%�z���9��\�%��uTp)�28m�:Wx��bŔ��p8��
A@���z�Wڴ��2GE�<7f]�����:rkt�G�4��gݒ����v"��+��,Em�kqE��c����uݛ�]Ń���V�<z�F�+�D���`+g$3��sx9/Hl�ry�i'��n+� Eoo'�Es�Z�&��ͱ�:fp<��ŀ?e�V0���5aXxy�=*9��-z|Y�d[�������O2Z���×�"��(�5�Aذm��3k<�E�' �����Վ���;-�0���Zi �6HD��ȅ�T�J/z���F�sdh�XRb��B�o����J��� z�jJqlz͠�B�~,N���s�����nk���s~�.ݡ3��@��J����������N��!�>?�	��-+\�	�3g�m����M���2:NZ������n�v�Ȱ\�AA��b��Ѧ�U&�$:Zېs9h� ���!E�(�u ���M����Ä]])�rOV���^��7��SF/<�3X��7Hש%,�x4�K�p(��44��|[i>N���J�VE�XS��Ҹ�*1��@
"xeH|g�1��m?�r�|a��+�}�yY��f�Nb�ډ��T��,�,�22��#��lh٣�29N���t:����J>�_��+1?��w:���A���0�w�^ȅ0�� 2��l�����1�ꪣ2E�z�h9Oj����L��^e�o��L��g��>�I�)�ؼ���cL�J�-� �/��m�^^j���h���wZ�d��
�����N���GMoˑg#8��p\L|���q:��-���J7��&�6'��������w����]�4������8�鯉���9�	�`�	�M��}&�\�62I$�� �>��'�ސ�è1��(��}�:��������h8Kg�MM敧�yI�)��G��,�⇏��Ҏ�B�`���Wr�9H,u׶Ͻ�N�䳟�Y� �e�{~ �%m}H1"�[���__t��Ծ�C��$����ր|D<������Ǻ�^#e��;��� Õ-=�ݨ2�mI��Їi�����b��U�zZ�?Jϙ����A�:�I�:Z�B2�d�V�sgI��*�i��p�f��۾����w.��=���J�-~�R����;O�ۼ:����h۲��C���t�M�%֒
Y��sT�wOHE��c�g�=7Ȱ4��S�(��;G�n{V�����8�qڙ^ue����4�\VUEĖ^l��ela�����K(��O�e}w��^��!:��+e˾v�}�Il£����	��#�HCCU9Q�zRa��Z�K���W�k�5��wd	���F_�DP���d�M}�˨_����ж�J+f���b�e�i��qQ��&�S�x�k_g�e�Շ���]��q��d'T��NQa�b8�XC�y��j��k��]3��Go~&K;ƴd%x�HCpG�&eE�>�\cmJ/�8��ə��<��4�!���y ���#�d*��xoI�M�Lc߫��yO��ő�rʳ;R�Z�<���V#���%�|��([|�CY|�!�қ�SSE����żl�`T\������M�I<.5tG�W5��c�1�ѻU�V�D3�nW��+^c�U9c@z��q�?���lr(�3�]����P1[�-��+̫6�8���bU��e�����D2̪�_�'��8K?�������
?�ʄY��@(���Y�Hk�?^�[������#��9z37�\�s�L ��FDڌ�`K�QW�t��H�ɮ1V�[g�x�js~�:�Д�&+Uzl�oX��(E���Ւ���P�I_�.�	M�࢐oMb��#�u����|4C~��6�l.Hf�Q]4#͈pJG���4�m;"�55`���U�7�d��Ks��弚O��xю��k+��z��gb�X#J~N�!��LUv�$�|�J�\W��ruHdyN�s�5��,��u�h�Z�N#�-���g�c�+�/�����~��_����	��+)�l�
��v�￞�G�:���KWW�x��I8���d��@S��H���3�H@���n��,�`���������G�Y�9���Sу��'�\�-��ᶽ��g8 Y�M�m���s��Ŝ]^��}>XQ}��%D
�)o���UjM�h�u]���k;�d��v����~q����<J��@�#�/���b�2��I�I�sZJm�M��8O�l"�p�F�s��a�;b�zc���!s?
����n eS)�$	{F8�z�+�S(��=�bbؒ��d���J/W4?=�F�0�+���d�@���HH�ep�6$9���ڥ�K���6;
Yv�۶E��uRJ���8��n=����$�c�!����mysn�@X�*��yT �Sޱ�:���6m8�����F'=I ���AKVh<�/��s�V{7�)�^��/�R���L��4d�KÏ�ع��%=ll��Bz�} ����ӱ���(��0X^j���%^��`3h���2�j��A�{E���5��@�\K��q�c�(i��(o%�S>��Z����<'MdW	��,����I��yP?{�z ���ݫP�:P5Z'}��p�s���C��E�c��2�����ݞ�p:�Lsj=�i9c8��W�K��0���I!&I�*D�����+��[w�!�W�QR���\[{�l�.8�O�u��vx��"H��se��s+EW�X�C���_$�ݑ�9�b,ޚ��mn��P�\�aKb~��p1)�ƕ*5�HE4���w���R�5԰#�f��y��S���ŗTR�,��|�3��f�&�A�(BG�P���	h�V�Y������u������Hn[G��~'����Iq�墘�|�GΪ���8��7��ʊ�Dj��
!�\9xE�X���1_���b�h��!]���$l|���є��va�Ρ����m��c�6�C�J.bxx���>jv}*#?������ؖE�^��s���*'�arn:4/@����;_�:���H�I����<<J���QK��N��{M
�Ar"P��c��ӡ��|������.��y�"���b�1M�6�U4�N �����8�i�����0�{[I��8Žza��(���-R_��Ā�d�P>�-�ci<B�,���s�Xm�F����dJ�-2�tc7�	�*7��7�>d�g�@Dl!7�K�o� �`W�}i��zh�^�m6Ù�t3ӷ͒�c��(7v���}�#T8`�`�2�.���Gݦf����\�w� ��Vb��0�Q}�ta�mF|�g<�o>���YI��<�)6بu`�7'ƺ����7t{��y��xW��;���<���k��I�NRE��X/~G1�52���ᱠ��!%�|�}�$��a$!N19�m�d:����>�v\s 	Gi\w��`6@���8�2pv,]��+��R�Ҟ�\H�6���b?{�~�W��|ġ��g]��{�;5_��cͪ@T\zA���vʼ�����GI���{hw%g{�T��5n������D�%�qX���~���P��h����:g1������:Á���*�9L�WoS��7ܒss���Y�0f� {����
�G���w�^��8/�<D���(-�+��¸a �2,��c'��ұF�c�ėXF�`i��,�|�]r�j���Ǽ��pkQ[v���� ��/��9�{�r�6��@J���J����y���7&�#�:������8/0�ߞ�{��:��D���l�ugr숋m��(� �+�N٬�ߖk#&�  d<$�j�ݎ���o��8��m��p>K���@26R��97����;�Y�80ѧ0s��lF0��^1��������a�!�S�,!ί9��x���o\��qPи���������y��O ���D*9F���(u������ߐY6m�@�n���+�P��AMZnS�'҆r��G�����
���-�=	.{�7X�N�^�G�K'���O��g�gvທƂ���������a�w%`Ϟ�!d2����pU�76O�uo²��L'<���&,k��5k��S�����,{Mӎ�7n�^�Y'�{uWS:7�5~���e�Ꭿ��S�x�(x��![֕>��5����g��/�8Q�4Q��j�GjE�r���Y%��;��-�/���:�h?�(��jarZ���®�P_7����q�6�.i�t�O=��F]���M�. �r�@�;ϾT��..��6�>r�yn�k���h1��.����d��{��RV�Kn=,z4�z�F��!U���3��g�^��o�h+Q��j�3dȆM#i�b��~]�����}��k&*�&��*sbd�p�bʮ� y���[�9ɕ� !��6?���HS�%i��#}
���Ry*P�@�x�[��
e� jO� ��+v�iA�a:���YHM�����!W*��'nԓ�s_5E�m5J_����r��	X�uk;���R����גI�JUK_�\�#3�"� Ék�T����	Uw�ϙ�bd#��
��)gH�ļ&6_��Y�Sm��O�s���m�fy��g��W~EI�K�"�|-�|��6�5�z��j�}\Z�P<�3s<}��)8�9��Ǘ(���c���h��V;���yO@�ߪ�Ǐ)�O$Z��a��R�a�I�B�l8��1_%�75����/x���u�����,��d�����U�<��Sx��(�}���m�rNG�'�y�$�>S�D�U���V%:A�+]9�d`)��	��W�2&e�X9�+�mC'�ȁ4	\�v�軚�ra�<�6��~|���ܟ"�賆�,�DG�uS�i���;0\Dׅ��=��=�f�x�X�&��I�O�9�8cG)U���%nz��.]:n+(B�f]�����'�g�NPn1���������璔��-O�Z����|=θ�i$N�)O�j"�W:鞆�>(k:L�w�s�O�K��;o�;�o���3�Ѯ�8�� L^��㤁咲ϫg�M�,Y��L\䬄&�%�;>f�~�ۈA�&9�w��C�k7��@K��EY���'�f첽��TJ�7�ϟE���rȆ��uh:v�׀�����{��X��ꍴ�+ z$����H��ڒ{�2�9�拍�=w��_}���f{�����b�M)rlm�UEW'#�5�����s٦1�퓠�*ҧ��p�5�þ,3]m�}�|�0B���ܪq6*�fS~�F�24U9+�S���?��r�X:�"�]U�
y�U�9����H�����eqWH(}��>7��Ė24��ii�1��y����nl�0�ʻ��mXj�|b�����Bg=�>����p-�ظ�
��'�b�Ƞ����������Yb��7�����Z$��:k�A�X�^/����y��m�8�ʀg��d;�g��!�B���ȟ�����3�� �8اO��P�XK.C�%�}c:$�D�a�)7�K��KzZ�咐0Eo�bh?��_s$��僖��*ǬR����T�:zO�ݸH�H�a��(�� L$|�f��Ȼ)~�^�a�k ��!ñ}Y��#"V�K��1��&���9Ј�%�N����S뀐�tm�[�)f�J���3�S,����Dѯ�	����G��ХxV0L�+r��{H��j������3�n�]4���� ���N��� ���0��0֓,��%�nF��L{jn�f�l8_bp>�/����2�'��ȶ������ݲک"I*}@s�`�I��c?EI��_��	Fʪ%��	N	X؄��5�=��%�'a�m���`��.� ���P���8N�"���� nɜW������>�J���y:�tL/z;j[��#�[(��e�{�r��3�i�+V?q��c\��Bt���bݵ��L��#���5���7qnd1�)��E71�#-�DɢS��G��ͷ�=[��Qw�-�6E�S� {밙D;����%V���x����&�������_�^u����ż�+�s4�Fm�]�D����s�9��)�gl�U�=E�v��D,���f[����=vkL�i��)k�Y5���t�B�5C�yf�D�k�cb�E@9��Z>�@sI�VHs��I��ac�k�\�!�Ѡ��OU��zV�Ą��qQܩ��`yv�h�>Ws9�� �$NW/�,L�݂��sH�Dj ��j�m`�%�ӧ7�`���Cs��d\Ka�T��嬋�j�X�Ռ�^B�1�^Ij*[�9)��	4(�:�$#H��U��l 	�@��fX*%�8�c��Z���@�m��ݢ��S��;�Z�l���bo�TC�:�%#���hb�y =�(���-u�C!Й�����#
��4�Z�"�n[�͒f�֜�^���MsL݃;��*�]+�U��zI��}��^q�4��F�ղ�D�м��9��p�P���:-J�F�K�����oI��'�nʋؖ��q�>퍧fI#��9��:?�.��b�Ev�K�^;�C=ej@?�A��$i�P!�ābyTc�|��(�9B6	����ʎ_
'�m��vU��&=-~�.�K�9'�{_��R�e�n��K��S���-l"=��u�	Fb#B�v�J�>k�v�g�P��e���P��X��?##dB �"
���_��c�&g����U쉣९���1,E���G]�����@������L���IͮI��mB潇7���L!^�;�	h���ѣ����.|�-߳>�]-�5�� ���߳x�-�Z���>j]x�$>�i���M�*4����&�~:ֹ뺮xRJ8Z�T-��Vb��zr�t����Fƶ��H֚1����������׻1���(��� c�!s��z���9=O�-��l��RIse���R� �&��N@	%oLYm�F�,W��r	�s}��U�8��u�rQ��G�8���-���Sj�܆�w$95��/Qg����¤���lT�V�/�Js�1�ۤq�����ND⊧���π�<��O̪��s�������TvC��ijC��ŅE�r�_`!�Q�⇊�n����~_��ګ��cE�$�c0���d(����o�)�{8�5�o�I1]��������	�;�s�2<
���Y�^��Xh ]1�<\O��2�F	�9������)��B���M����[�K����n_H{
�$��F����)'"E�
���G��7������ _6�'E@�/�0�g7�h����d����n�Ӏ����q�&)�����cu7�uIR��\e���|�б�0u=����{җ��K�"�2k�����w�,tX����%tuU��;��w$�ߨw`~N&>sX��GD׾���) �C��'0Q�T�8=�<a���ĵ�_|�&;\p���e-��R;����vD�ҽwaz `5IL��|,�]����e�	+b' ��%6��� ��"r��Ø��Cy2��^��R�z|����N
'���F5/�)�v��s��}����\����|�X1w6��QbY���I��@h�'��(-�mwi5�w�J�t@* F��
ч!�����s�t��H�/u7�X��=�����>��W�����z�ul�:����ńv�[���n���Vm��pn���.՚�Pln2
z OzN�� t��o������ơ��N�x@¼о�P��ML�L�eJǝ0߂оn��r���:�ɣ<�h��D��=��x*@���������ָS<�!w#۲��t�t��d��^s�fG�fԷ����֎Ǟ�@i�f����	�f1��KL.Þ~�־K2����}��=�2>�ֳ�.4x�Ş��2���zQݶ�jݫ����	 r>�95���{��|:���"x�`'����� ��)��݀9�	aJ�[�܈)5�&w'�v��4��]��Z��V ���U��x2��r�"����=Y�Ur>:��>�R��[.�v*�U���jc�f�鸡|d�f�Xͪ�� !|���a�7zI��Vc���R#>�2o�<h�LT�D#�o��������<xKʈ�ல��o`��"6��1^�)���v�s��rЂR��}�����߉�Q�Z7���5,F�?o<
���PJ�����*iy✠k%V�p-��dB��t
h�7�h�m��~�*���ҩ�3�`/�5/3�;s'�s拄C�s�p��8̐�W͡矂}Ha����"�����D���idW�Ȁ#���e�Z�E[��mׄQkf�8�P�&e{s8�]�ϯ�Un�i[���9"%�܇@���Y�_��u6��Y%@艅̰0l�8h���!U�Bh\�� ��K<��nV1Ñ^|�Ni<�}z�%}��L�!��Ä8*�I8���<�>:X�֝T:y��@6t>9Q��l���<:��șq�Z�6���y�8E�TK���� 
�"�a���`=���@����rc?����2+@$�)B:�z6�D+&�J���ǡ`H��_�a�N����u95	ƹ�����k��z@�+�\g/�lbs�-���<J����2�.x�Y��Ϧ�5�K#����_�D2�)57vx�-r��$u4ߊ9O��AҮH��6�-�ȣ�Z� ��LXI���'�YM��������L¿���θ��V�z���(�1 �MK����������S;w�E1�]ѤW�K��cͭ�q����L����S�xgIPB+�h�"�9����6	�
w\����]0O�������]�Z�4n��Cg��q�$ӫ>Ur�&�`���3��{�RL��X����A�C�"�N��vB0���zvyU�$��d/wo:��gz����5
�T�rUԚ��z��BXv��E��9�ʑ��sW��L��������.uzA_7�gA�ūpP�6h���Ҋ� �})��u��MLـ��Lu��������:e�t�[��� ;� �eV����H�:,�S��M�*=A8��w��MUYW,�:�G� ���2-F��{�B"�%:�X�d6�S!���΋d}��cI����E
(r	F��FmQ���Hߔu5�jN
��,fꝌ"UL+���z���6D����8��o �g0��0�x�/K�"»��2��o�2/�sH����ẽ_U�S{\��d ?�ʇٽ��:�7_T�|ҷ�Awf����bw���xǌ(����1Yֽ¿b�]�I�Y�z�J����{y�dU�ͥ����f	��#a׵brh�
���
���`"�_�p5bI�kW��Fy 8��8�g��6S�`|�%<@�!��nn��� �%#�g�N>�e+����:�ν��������Gb�gK���b�!ҫ��>$�G��M�V6�P�\��i�S�a��]wV�����B�Y��+�:kZ����RQD��p�%K���x
L=��;%���.����K�I�BY�!�d�\�)��DƫDJ�IZ��#��;�oY�Gsa��{�d1����GN�թ@|GWDzo��墽랞��摔M��O7ʑ��Cq�3=�A#����R)��¤�kxZ¯� ��;z^��v.�� F:m2O���۠�[}�u�\���M����֛��SJ)��9%�H]�� d����k~�GDT\�XLҺ������Q, of\�"� ̫N>� �������Yg��.e��>k��v�[��btZ��;ߌ֜n	԰�>Ý���)!5�lU�Y�����W��$ԏ��޸���-UK�4r�d8���jQ`��"�/�a��	C5���2*1����a�9q��qw㖐��;g��	�P��CQQ��8$��z��ݴ�k�}*S,Θ!p,�&6A4�x'8X?7[-�����et4x��bJ�b���x-R��'9�O����E�aV�r�v]^�ӧA�4�w���Q0Sh`���@�jɈ�z���:��s�4:�, ���eڜm�m1��(zJ������c��n�Њ�`e�C�Q���p�{^�,K����R��Y^�k��3VF�:Nm���2"|��-k�|��Cߧ�H�ǩ��1��`��^����Y���,H�6*��[����ÏJ�)xcs����љ|�I��2�U>BɊ��fgDȦ�ߦ���X�g��K��$���2��?��m�D�S��%˛��)�� 
����C����=tS�#7х��}�5i�o��
��J���$��m)��󭊂�}S�HS7�����̭��ʼճ�^�E^!he��D|]_ti�c�z��,X^'Q&��N5V� �]���N<?�?)}v)� c���P -�c�tZ��\���)���	��Yg"�������FMCs�[���]�Pt[;;X�ԝ#�:��+�����
��o��_E"=�vo�[�u���S�,����q��2A�l/t-�Z�����|�Ҿ��Ҟر)=�*�N��(1�مʬ.�=6����B�?��hW~S���g�ɪTD0?P(���%�K68��س[Ǣ$�Âv�x�ӫw)u?��9y3��3[sĠ��m�]�4����u�N)��%Z9i{FWc�H=�p�����q�.�7�@#q��	��QA;/��o�v`���7�j(��X[��UgxЙǺN�$A�[;<�����1��T�zA<NY͞23����>EL�P�(yH�zO�B/O%�U>y���f�6���#�vZ��A,�9sT��?K������wЍB������T��+�r�ÛQ�2����D��� ������3�9dV���X����4M����ַ�mbHc��	�e/����è�P,��	�-�{s?��p��j�i���E~n����#i)ݑ���QS=VD�?��z�(��������'����a�JٮZd���������[�{�!Y�0��5P9���r��]�?i+"o�+/��@�)ʐW�>�����yG�s"]�_�,���a�6iTa����ڕ�^\�ɜ��B��r�F�=�eM]�KQ
:�l�I�Gq{U�OY����s��la#�k�`,��&�|T���\=#�B5�KҀ*u+*�',ƞ�@�]*"H� ЏΦ�ߎd�>�/X}<+�uܚ�K�;��V]s������i~�*i�����_��2�i�m>�S/o����/�b��ğPF��8ハZ<Y�_6EGOq��k>������Kau
����$Qt��{h����5�.s�w����G"p��۶ɶ
p�[�h8 �]І6ͤ4c�(}c����y]a���K2���,�Rr��,���[� ��-O:We���y*7���D7�j5%��=����ZJ���U�t��0ʀ˅O$��K��]a�9e� ���z��VGn6���1��b� a�ah�-:w�5�軖4yz��KI��4d�_0jm�Fj	�B0S��i�icZ�I���\�"�������P�MJ*�
�`g�@��Ll�@�����W�%>�/��nnQ<�hT�ׄ
������A�݊>bY�C޲�����w�t<lM��<�C��T[����d�^@��O�Q?
US���K/o}��ַ)�#��-�*�V�������7`d���K�gy;����	Pȉ�uT���*kp|C�Wn�������<6�D'����]2�2{�����n]E�Qx4ՙ�0�t��%Ď/j՚	�xň7��2Q�y�8_n�p:��r�-=-��#{0L�F��������Q����jL��9��&(��R�[��q��Q�"Na-���+����*�5��L9��7�P��Pv��Ɠ��&�"z遝:�,��0KkCG�B~����Q	�6����p��y����'�?CU�g�T��4=��M`�.�7�����F�H_}彧�`O�ȰY B���4:9qJ
pSu�H��r9�#e�;�����`j�Z�µc4�&�����'�=8D�\8Z�; d)��X�����68k�Yc.�£��(�\K��
?�]G{[I��th�A�BA��oh����JC���[�tBS�ّ��s�g�#d����8{���� ĐjvC8���}$%N*�2�Ep�s��\�w&�!1㪽,�?�0�.hۤ�B��d�`�F�&N7L�9]�_R��e�"H(i�k�N�E1�,���� ��;������&�7��?Q��?�%���g���HxP��Ѳ�\�x�݀�):�S�)���Х*u�6�� ��c=D)kXS�E��A��V�bπ�z��j�p�^�3g����{�;��lE;=��Jr1tw@�)�ռ�!���q ��^ޝ�5ū�
i�L��`SU��+9�	�U��O}��� �?-ר�hٻY���D���!'ᐖ�y�-�%�PKZ:C��bV���&�I
�!u4���;����#�mٝ��2�c�5�ｈ�y%O�$��g`ӑ�7��|�����^3��n8����+:枑����C�aA+:8��i©���Hi��E�k�����v���[�89tDN�ȑ��_�O�wC��gv���0���1�cs`�X��Q�����'E�I�
��'���[r"q@?�N�}�o� j?vj�@�"�������1��Sc��l�s#?�'F=SU<L�̩�޸�=�S� �L��#$�����C�}�߷, B�6��n2 ��U�Sw ���h�0���T�3��OJۊ�w��A�f���`ϸ���G8D+2�O���qs<_�Ah���@6b��m�RÅ�><�۔!�lM%����Շ�Ǒ}���qL��c�,� uc�����ȨI��m�*�A[�̄sF5�3�����1$k;-��߀7��B8} ��GH�r֨���"łNć�]h%����OL,�.�XY�10���؂Q��#��Y�0����7��@�A��A'0�GlY=�		�!�\�꒙�n��ۤ�c ԤÝ9W$��M�A���.%!�.�
�~��|��de,52�����3��� ���B�)O�	���B�/�?[����`t�X2D��:E�c������(E�?����� +�2��z��oG�h�]�d#M�a�NBT���A'���[�bx� ~jN�
�G���Q���&�_>Ӽ�N��g�����]��V��x�AuE��v�e�*MU�%� �BRRo��{@5L���xƸ
�+7�d.�6;W���(úA���<)i�	�k��O�,�O�B�M�� ��9�2�r������ҿ�Ex��������Ң���*��wS�1&�9q�^F�-��� J�s5�̄��a���N�$5�}��[�jA��H���+�92Oж�P��8����d�S���5������[�'	�h���x�����i̽���,�s�����X*���\
�����N��.Ȁ�d]K�cP{��� �Q{�-0X�M˒b�d�V�"H���'�����B[DdKx���8�U41`p_Ϸ�L�ۣ��S�7����:���������]$"#i�f/����q.#З7��^�3`Ϛ%��A�˒;=zj�����@\7�e��4��F�byI`��-K��P���{v�?�P��b���x���3�m��"rT�e�cُ�S�b��E1������A�1�誶�
�I�s�kcCGpyԇB�g
�e���:z][�>J+̛l�@tC�^}��M��E��#��
TP��M*ߖ�����-�����n ��dd�j�g�Sp��JKD�v%9D���^~��X]���;�z��Htf��wPį�2�@sIVke���L���/�%E�Z��I� r*�:T��卥��z?@f���z����?%7Vͯ��A�Ϭ޾ƀ���~��t�h��U�`�ɣ>�1��(�ề^e}L�V�2ʴO����K��q�f��(�:۪�/]�|�)��{�E q\L�}�F�X�ڴZ{`�jG%{��ſ�rl�?�i��w�UC#$ϐA��L#��NH��GE 4r6��V"l���r�2���-�M�N���`���|��r=�����fM����2z�{�j�+�S���8�Ko0��S>������S����;�k
P����D�`��x�>�5K]v����.��`�$�BPv�2����(
�7N�%d��'��������nQD�)w�{�h`�e8���p�*�C~�/�t�m�Q�~�1|
�̀/��N$?�:��x�$�U���4y�|b���"Ur"P�ؔN~�z�	�7B�?q�>��f�e�=�o��P�I����Y1'JL��gʓ�9C5�F�H��	;c����}��WuS�.ʜe���L�9�sP9d%�ke-4�ù���p�A��/y2b	ñ�'�T�
�n�(���I��l�z&;��r��E�oS~E��\ws����,p������j�	K����fB������X�|p��M�D��g�aT�A��D�bީE�u˕bn=��'MԼ�j1�u~�p§H���S��߅��,�(�U���A�n�]ƸWv�ב��K�#���|Ob�'O|{��E�7i\n��;�r��,y]˕���ٍ�הiZPe������{�7���%�-�nvX�7h�c�dr�^���˘�Qʯq��B=*���`��V~p�%/���{����<�i|]$��%7���dW��2U&2�i�O��*�:�=U���g�}�C�r)���\���[�����Z�\cU���Bݰi�P�d$1�u�t� ���ڄ?�Ū�9!�+��+5F�۵��s��2 �`0�:���(���j˭sHE����p�S�܇K/@@�׊rh�$���-i��'��r����䔭��-%rY�s�'I����uv%V�V��/����}}�!("��#hY�U>S"9�Bxe���P�\��)&�����+`{.���U�v쏓`�+cS���������Ą�p}���"����=��a��Ѓ�|*ty��l�.��v

�6� ����R���s�cV:��t�J�E��Q�ǅė��J��8�NN)3��3Mm<GvG��S��_�x��߉8K5M���R@���բ�< �)J�?���n6ZGoo�Q�IfwѤ�\� ď�m��� F����dK�2b����)��k��ﯯDZ��������F�4�#MCb�V�������������N�!pH�T�x%:�Q���~�P@-��]�h��s���$��Z�?j3����f�\���h5�������ѳ�Q,L�_�����P�h��1���?�B�.�SK��?��䇍�Q �{�9��yJJ��cE���M�C[����SZ+ߊ����]��1�-ﾧ�~j�q�Q�1�$�"�`��ݽ"�f�:i�c#�>����EQ�t��?Po0�/�G�l���z_�lI1ul>?ֲ+p����d!8C@[�GZ����8>#�8�P28���y��#��'�a���Ể�&��g�W?�\`
�p���Cy���:�Ѭ��"e�R1YT�J�L�qUL�≓�p}&ȧ��5:��7O��� G�9�Z�&�7�} ����Fr������ 2%�gXf3aJ.���~��N�j�H�ߛa&����nA�G֓���GT5M&�ގ�� ���9fS���n���|4h�)�)�������ٷ�E� MR���{"&'���R���iHψ���c�*D��& 2����r[:Ϥ��ɖg*k����T�<t��#c$��<�+l��4 �I���X@s+i)�g�5��b���XN���'�~��l��Z��h'����.F�����Ĳ;��Fi��Q�Y�*�8W�F��9��kD�`t����Zk�3C7���l�����W�f�57���cў
��ϙ��!OS(V���j�~����|�؊��$Y�,.n0`���*�[��\�!�ΰ��р�u1"����T����JY�Fkˬ������96s1�m���e������+]��M]9���zl:@$��}�Yn�\O`h(+b �@�a��ve�麂x4$��lc,�st��,�y�b��ߛ�E߱���0C�Zҕ����3g�U��%R�T%<4V-$0�m�����!7��]d٬�2�NmC����}<F�1G��W�ұ�;�y�C�ڧ��M�;b7��4</�����I�h1�e�<5Tu޼ ��`���	��Bf*Q46|�Z2`�����p2�bhY� 7��r���i���5kp�l��ag��$sV�%�����_��*�6�ݢ�Z=Po�Ѵ��DUq��y\���Q�i�xD�6i ��T��!����Be�Q��iv)1�D�#���(���B��^� 	�X��/���W���8�sU���u�ĕ��"be:�'���ox���'���@�hM��1e6��pQ>�+4�J;��p �/��(5A1�����{4 2�Y[}�9d�@�:vu�:��~�l���R�!�0��1,:׈�asE�݋	��u��-��&��Ցz �d���֨s�jA����?�y�������dr_�Y�ig��.�q:Us^�g��L���7�ZG�l������<�)�䤧���%H������&4b��N��*[��8"R��f8�X�L��E%zO 7�͋��W�.����o���i�񏀐��:6�{Y1����߀��K�՘vg���|Z����8����
fɷ0���Ċ�*�a����|�C���f����$�C�R˓)����G��tEql#j`��mg[B9-�h�[e�t3�J�8>�x{�K�ޭ#Q���|�8E�c�(K2�  �h���� �����EB��g�    YZ