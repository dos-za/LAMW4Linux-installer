#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1994003912"
MD5="279c6bade574ac9f0564a1c116f304df"
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
	echo Date of packaging: Thu Jul 29 19:20:28 -03 2021
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
�7zXZ  �ִF !   �X���W�] �}��1Dd]����P�t�D��k�J��S�J���1�j,+ ����怜�A?D�^���<��M���d��';�j���˓�f����0*M	����≊��\��sT���&DXM_�Z�H�1 3+w��m��h�v����@ ����:`+������a��d�������@2�Ш9@�Bt� �o�h]�JN:/ۛ�`ʖ4M�,}�c��G+��l3��wE.)�+�z�x6P���vr�3-BH�	�Brϸ�(dy���ٹ@����_�#�������|Z}��V(��ږ"���и6M�r�����Z��ʔ�L�?2&�(G��y6����@�8�(��jI�<?�߳0"�
4uhu�g$g]�����:����6��y��±��=y?*GތL���2�B�i~��;�Rm��TЌo��W4jj�Z�2{c'G:��D� �}l��]�'�W�Ԉ6�F�o�h�W����س� m��8��v�����xa�������>X�좿�ܚ��?KA\ 4�3B�W�&LH,��;?:��w�Ҫ����"����|��!8�{o5�����Y�T�2��6o�����l��2%ym�!�>��,���UaO�92�߃���g��Ʒ�B�F��Zd����#����e[,洭�������7
D��C��	�]=T��ֹI���/t��L�"a�g�d��@��I�͚m��<��[��HA�臹�� ����u#�ui�����6��>b�p��i
�_Mg��k�-��C��͸�;�`��≎WRP��z���7�`쒵���g?f��U�Cy�H/{G�QV`T�\p�0b��r~&XgKU�u�fp|u��v]���1F��=�u�9�ڪ����⣧���X� =siUY��v��3��s�avvP�MǻT�!�F���Uo�ƛu�����΂[z|�������h�,�Q�&~i1���"�����#�� u&\��.<�"6�-�¥ݣֆ���$�&9�s������Q�D{���)���x��>H$	��hE`���m��k�H�@�~Y�QFEiD%�s�N��P�U�A����ђ�If��$�bbsK|��pź�TK;��g/�q`|�"v��&,v���0�p���`���x�$��#؅���0y[P��?��Y IrvO�8/��ý�2�[W�c�G�����)Hp졥�3����K]lO\!nh�؟��V��>�gl�p�Xfm/n�/Y\X��[*O_�5(߇�qy�F���nKOEa6q�t�e=m���f�)��;���"��b|5�C�f���;��J\ͷ��M���%�&�u�<i�GP���1�i0�eW�sxU�I�3
�W{�|C�
Xs���h�̛�sF��;y�y�+wm������_+�������聾ML%��邴aT1�����m�Φ�N;|�!����O�H��*���>5z�$��Qb��_�{������6b�{�[����H��0�i��4�ߋ�"���k�oX�С GU+a�~*����w��:�H���2�E���T��kf�w�g���W["Z�_o¸��ޣ�jW�Lx��3���Y�_�V ��`^�]	|[a�u��VJhi�^R
�g�F�v4��f	��)�G���bT�x�i`�m��q�.n��B��'f=�G2�5����ɤi���b�e�2���ZW�<s�kAXL�R8��&�h}��_Z�9�<�h�!Gؖc@��z�==�}]&��e3$�YZ��T*�c�"��X4�4�Mw)���F�wU��O�Q )>e��,�)鏘��G���!̇�K	_��i
��v�j���l�a3DFN1�*�]��I$�}_�n:m,'2^��02r�ǥF��4�Y����N䩂�,Ytܳ�hf�m��d�7*vҤ�q���xhU��������l�b&�T�����ǦXkђ���dB�t���]��n=�J������᝹�B���몉��\�Ik31��"���~�<ĝ��a�?����U�w�ܤk�8%���˔Tve�)%�����:�{���\�4.�����S�� �6�l?&�Qm����As~sE�eIʾ�P�A���ʈ�.���,8�R�D$����7��+�@,��ZB�d�b�V�H��y0�\P�G����z��?0�P���:�vh�s+>�`Z܇�Qq�0=�O����bTL�2~b�zt��~��n%}�p@�V��͉~�Uwi&�3�v��������g:��`��*��P�>�C�٫8!�1��z]�s}��W�ɮ�g�厵&���ZMܲ�_�_�1>�v�s>�lA,�&�+�^qn�u��M�.�Di�e�ʋ6��'{i[!�Z�G.����^>�N�?��0}��¿�@�]4�YBo[5���bp�st�m�2B�� 2#�|��r-��I6X,��xx�ò�_>�H�Rs��KX�R����������%��0�}�%����8���G�~������w}�:5���=�c&����$�%6�1�9f�����B��c���,�nX�X��k0U�68,���j�9�%co�~�Jw�P�?p"�<�$i�h\7�X��$@��#b�oE���Y�e��A>�r�OZbR,dY��^����_f������&~���.�T����sJ��A��f%G��e�ߟ+�s�-ֽ��Y�%VlU��t��w�p�|F�h?Ǜ�5�bȉ���θ�RH�q�ǆ,���1&�S�:���F6�PP�B����fXO=�μg
�5����Jj�S_0_D��� ��U�>Ը�n����`➻��;��������f׀i�=ܵQ_�B���k*���_a^ѽ�36+�
h/�O~��u�.�U4�ᆻ	�^�T�J	�9�k�;�����G�]�{��rT�'�~:�ku�a��&Mg���'+����MB�c�0b�]�V�)�+aB6L�u4�&�p�]����#�9P�Z�����Cݦ`�D��&�(&b��n���oR �0�����1@�
����x^m{������.����E��7�H#2L~�WN���>�����TUl�>�/6/a �[�����,�}����O�8����*e��h<�z0J/{����^��dߛ�������6�{F���,�F�.%��e��5�)��Z.~u��N��˛ud%�D2������SC=�dpoP	�}�"<F�1���MĤh[�X�]�zڗM�hb߲i�K��Me�Ld/����V�a����讕����5dpi�kbN��(���[k�.<r�V%�f��#1�Z�/�U���ï]��X\ɍ�cZ0�dQ�����ɈnI��A:����;vĲ\�+�	��\��kx��v�=�� @z�Y'��ݤ��� � ���9��3ß4@�|��!Q��$����Q����dD�d�' �P]�z��2}{O�I��z]W�S�:�V�������i�q����k������f{67����jh:5��E��I]�=ƻ�,���<��[v'���sw��0�-�f���{�i�5�A��>xO���Ш�N�y~�"�'�r��^�W�,is��j���;L+X2F�;����:j��Q-�*3J�P��A8��q!�Zf<�q��#���RXMc S���2��Ҕ���Fގ�7.����"{�1�ER�x4�]�S�;�Bk�#�� Ո�cۊ�����hF�*~90��2�^)���V45���cʠ&�����ׯ������a�W�&�Ă�kF^s�UP����t�۝'�f�E�����5���#lO˺ox~jw-���{���(��	,��w(o�o�<��'��aI�Y�����ŪK�e� #;��Ru��!{���d<��1�,�5"S0�"�T���Q{'��Wj�L�B�B}cp5X
E���p��z�
���6�W�ŊXf�hf���I�m��SNu��l�|WmƟ��c�ې�@�䘮Sa,��W@E��aR��Y�D�c�)��o���<YlN\�VJ ����Ƕ����y݈[�3����An�x����s�A��������
��;���ֺ`!�]KA��dȁ�_��p�N"�炍����k+[U�m:�V �Rmx ��n�LB�8෽��w�M�<�P`oh0ӣ����{h���ܺ);
�9s��
s���aZ2��L�J�����X���6�=���@�ujFˁ�]��Q��u�x5��v��t��͊k�G�83_�c��܉���:��v�j+�<ӱ�t�5�Sn���4\�O�#�w���KE/������h����,��^а����|4ݿ�2��?n�9A��q�d����=i��)z'����#۷��q�Iu�k-a�db�k=��@��oOھ��}B��(=�85��}������9�ܹD?���}��QU�߯K5!�G@��.�i�7>��.D��e�| ��i�&lF�/�VTDP~��{�`jq��C+ u���.�NP�\^NE��v���NԔE�ލ5���:�Wʌ�Y&+%�'粒�*_5@�R��(��Vj(�RL(�\�w�иt�2�?�ע����ӯ���� ,r.783F�S���U�W��<*Nz����IA��I�#^(��	�T�����@�帚� oIw1�NN�9(�*�~���S��_���ĕFwHm^8��X�7uMhE��g;sm( &��t�x����Zဍ6oe�`���D�r��D���:�2� RUT ����$�/hm΃3|��nK�A���W�m�=#�LI��K@E`�^�e�3���o��+�X�q����M��.,�4��H���&*�Z�b��9u�L�l׫��i�� ��{�9�+��R��&�P�,,��.�vI�m�$�=湰x�E�V���`�"�9a:vހh�au�>-��SHl
�:���p����*۴�H�s�t� �Z@�'>|BD =����;�ZAR���i_�i�~Ȗg9r���V��Q�����{��ۦ�<��@7���.�Ź=g3�5Uo \[�IN�p*a��
]�~l����?ve�@O���	�k���O���Z����r�yٍ1�����,VQPb\����T	��6%���>����({�s���aNTMz���&�U�ɍk{ɲ��ןca�S�鴩�tSƖI_�0�g:Q��b!hp�r����v�����4���]��ɣ�0�Ȧ�p7L��O
W���j��l��#ǊXz2xA���n/�*��sHj���O�Zq�̥���E����G��m��	����=|����101����1�⇵���9�)f~$V�g�x2G7s�L���b�:��Ϩ��z�Z�g�o��^�G'9�l��D�������~�A"2��s���>O2(H8I�$�� H�*��cTspiu<�r��v%��xZ}�#��x� _�!�mE�3�z�S���+��̔�Qz��Y�~(5�H�/���U��A�2��m�3T��Ht�0�L2��.�����I&�JG��x3eHeIO�ƅ��{90>N� O~��<�\-j���N����s���l�5�^Z�T:�	$���X`�
ש���q�?�ev�g1.8AQ t���j�u��U�����P#W��J�GA|�c�)���ކ�����Re6O�<D�0�n/��2��5�z������'^�$%?<�]��ckET(��N�$W����9��CZi����3U����ǁ����� -5����� Q�+�99��I�]���C?��UG�(��Z�[��A�L�x��K;�� $��� &�p���x��a��)尽a��רO�f�"vPx�^��a�]�fU&��ѽ �����X�,��G�4ʾ�=C/"V&Pɾ�����	SVΐ�,Չg���q�w�.����f��t_q����bm� 4� ]�;Y+#�p�Y��0��An�%�����_9��]���RT����_3����;��B�wN*�r�A���D���w�6��Hc��C����B��L3T�� :oC����D��؜3����$��2���ѸN����P��J"ӫ�+e�G�*.n��X�E4$X�)��=�>Α�|�|��L�7�zdyY���
��+dqm�U8���tS����̅���!���l�D��_e"B3X6vMn���&#R���	���)�x����	�\��r�TwȏO�PT�&l1G7���?�.|>�hP��0:�r[H29<��Khx�m��h ������j?�� ����c"����_�~.d��;i깑�N��r�k
��>N��������q�L����1�# C�'� 3P���J��K_�&��u��-�@�� �㸣�_��A2�'����m��A�M������9����"�P�E�}J�YT��������;�����U�BIo�R��w��*^l�f��M�*%���D����I����<�ՂD0F�� }���}������1(��U�7Ǧ:oJ��W��{�=���:$wXWWШ)d�m�Q�aP+�s������*T׬#[nHn�����"���J�n���S��K�a�C/�>����:���Sr��4X�%V�%���pR���[�6�S�d�/�l��h�Q�7�1{��-��K�O����&/��30���M���s;��Y<'�6wN��	@q� �Bۗ��k�Y��>��r̓_���n��\4�&|�-��v1/�7�tV��{"r�R�2=��2�`��1�A���d�}�,:k�S�?䔆��
7	k��/y%ٞp��]�0��4Ɠ���'p�&�v�Ʃ���vS`�|̑`SD�/��P�/ GwӾ��F<�?n��^��
"�sr����|7�ф@��>��D�y��iZuR��*��u�ωI��t0�d׉R��:���/3����pq��,i,��b�S����HT�Ӛ���RuJ���;2���!)��B���b��Gb�.��K)1���>7;�1k遮��l<Ft<�i�	���E>߹��km~��k�	����cX��˳�e��l��4�@�~���W��[s�~o���!R���S6m�[�������|3?���9��h�0$��$<��#m`5���v�R�_���8�\'��p�?R����Qţ(�:���n�T:��K�A�0
"��EZť��Ӟ�GJ蒦t.�i�h����>�2߮ð�J��4�>mŬ��ۍ�r^�&[�E������I���|k��E������|�F����5ڝ�tx]�_��#
U>ֱS������A\�7O5@�F��Ġ��o�Y�M�SP'=���듵�
�[�ily��Q�7�A�������L�_�mg��O��U�H�yF����wP8(���s���2tӗ���k>�5��mg�g��:h������m��Z:�����%�l��� �_�\�L�~�L�Bc#}����j����ܽ��|�X�1�?_n��P n'�5�Z��
��ܮp�C�� �#\pN��Q�D�ݙ�I��2�Pf��a����$�_@�ڵ'6.ooC��R-giOż��ͦ>�):��}+��d&��D�݃��� {e�Cxa���#9���v���ڬc�&L�FY��L�^�HR�~Qaпo�C��>j�tÓu#������.����4>sM�[�����y ^�Q�3L�Ss.#z���%˃Y�J��^Yݭ�6x{a�}���-�g��2x������[m�Z����w�u���?Wa���.D�u�Ex(xTd.Q����N�5%\ۘ3Lb8�j���V=Y�E����b�Y��j���x��[:�W�f�ۦ�;5����\�\��Q���,)G�WN1
�E�%�T�]�,�*�T�{��Z� �$]e�j*����7����V*v3��Qc8��;P��3���/5�|��Z-��+C3bWK�4���ZG��%!0�=��l���V(�a68�Si�Eh��x�m���O������s	3�mN��dW���	W�%$��}�4�i�!�H�P��T,���Q]��I�VZLm���d8��Xh?��S�=�q�J��<�W/Ŵ�9��:�{�S��k�`$�����9�5.����kñ`��A���X�K�&㮷��!x��a7]����3띿v�d�jݙ�M5XZȄt*��x��&��	�e��i�x�8e�F�w0���4���#`��bW/uʆê=Q.69&oVrق'���D��S,Dn&g�X��wkKl����v�<l����Pv��`����,<��G#���6�{b4X^��4I�ƄG;eT<l�1ޥ����n�F�g}7�fy������e>��wo����ɹ8)r������B�'��T[$�qˎ��VH[������*+ŪX��d�.rn'N�uO��ǟ��,�)n]������x6'�w�j3�+ؓ��Hಭ���[�}x17o�����E���Ǹ���Cby�7cXfv�5���-!Ht���(gEh��+�K%j9G=�a��x��(� :�YTE�y��f\�ǛDI,���}��
VM�T����BP����Q��f	~]�OF�@�,: �s?��*�#��V E��^�D��Yw��I�$��-�9�g�݋ʓ���,����<��BG��������$�t��~R��H������6J���.��Nr��Ƌ��C3m��Ԙj�
���	����1�8?�:&��`0�^
��VL1*��Zk9�����F[�tp�d����1�k�3���:_/s|B?�G�BI*�R2D���SD�7� m��5mP5]�.UH�U �����|	���sbv�R�C����,$��}��#�D]�0S��ȼb�x��e�S!_A� �VMۼ��;�-w��lhC���Ad��%9K]W�c^�
�z��D"��s�)4L�*�<�
�m]�2�\�L�2����7��e��ݷ�{r�c�3W�iE�6P�*�Xwo�+�l\����6�1�,���Ã�mF����ʼ�h#`~�,w���p�l9�Wȉ�f:��ڒhq�9}jY*�����`��j��,�o�S�R�i����3遄�%SBbtW�w��.b�MbK�2��ֵ��Y���P�M��՞T���y����m1 m��ݷ�TpA��r(A($)P��N=��7����jZ�2t/ݒ�g��K�����X'�;3CNm�w�,]Z��y.�c�}���+[%������A
��K�+������e2}��73��S����෷tvgjo����/0�Fm�:�W}�2�g�Չ>����*^X��P6g�]�7���IK��9�@� c��*/����A�j�����V��Ë!i���#��_�����/ۨH�lG�E���5�RQ���w�H��!�?��Cxs��5�r�4]�F���ؠ��~�����a����G+�)�U�71meY5^�˘��úܶj?�#����^����Bo�*��@�뎺��A���rj�覵�s֡�~?���; �����ј�5�ǘ�=�D��������[�^�ک�)ó�@����7C0��em{Ot�0�p-�k+�S��C��0�ۋ`�� = ���V���G���^�V�LKp��6�嚨I^�!��4����VXZ��N��v���kǺ�h��f�R�NI^,�S��Q��Zgv+t�5�r7T��*��|�[c���p���%0��LsVoqgE�v%����g�V�[� �~{,����!PasT���y?��1��FLZƘ��V�c�K�ƽq���1�����x;H �M�_Y�3tȲ��K+I>*�@Ծ��[f毥�1�R���B"�j�5�T-��2�8��Aox\�r��yI���u�>�O�5��g�;��[L�Zx�����z��Z}�sM��Ҵ�A���Q^�nmO�܇����S��'�$�K�h�#���C��>(I��D��pasnjxQ�E 81��y�dT��4�Y*v��d|��ߊ��DN�%�B\"�/�R��s�� �d!r�;gj-��F�:�$q�X*]�X�(Y��ϑZ�c:�Hk=���f��U�gt���f<�����	Uk��Y����M�>����F�e�:/�*����P��h�&'�Q}7˘t���0�f.9+瞉3����g ���=2|������ڦi��T٥��� f1�������O�-t�d_J^��z���r�3W��8e�v����
0�MR����q'���y8��a9h��i�5�I
[�R�����SXU��1&1�^z�N�/��:Rǐ��TG���� c/sG/�q$���Y�#O�{��a���K� �bG�����͵�V��?�ܛ^�Tu�O���4X���Cb�=3�]�1�(��M��6���tiP,��0}��F��"�V�a/�أR0c�x�%�H'���)n;�a鬰��@�%5���h�RNN��oĤ%��K��砏C(�
#@O5g:�4�� ��*	�T�J�ގ
uKs�Q��8�C�|�s�� �f��@-�U,��Q����Zc�*�/5Rˀjs{|~��f��<�4��� �Q��C�rX66�V��?х��$�-Գ$��19j@�_�yNrN������n@Qm��`_
�O�Q������X����@X������ak\���������^G��>�ݽ�D�41�Mƍ�]$PX� �W|s��Z�G������!89�M���.���j��v�������S
VčD{%}`}��C�R8b4�ûu����]aV��%�4Bٍu��l7��tA�����d")p:b�F���W��O�2y�D���/"�3盼�f��`�]��u���
��G�?� 5i��ӓmB�dG�-���L����%?DӏF:���L[����Sf�T��j�}���ʭlNc�^T�"GL��cO��Jm��i�d�F Xk��r����<L�!n��fץ�F(3'��)������I�EP�f�B�T��)�O�5r�(�Zς	���ZI����
�`�z��+�8�'�5�s�������%R���*�ӕ⒜�0xQ�j�OP��ϖ��,�������<|p�Y�A���'���5x��[�=}��۫_�N'K�8y4o%>K&�k���R�x� �<�X�*h��5��^�P��غ�Fƛ���L@ksN��O���ȑf�jT:N������p$`[�ҝf���ka�o�����*�����V��G G�3Z�2�n�8u���4�����+a�b4��j�X�����`�w#d��#�آ�A�m�B퓊�8KA\�����-v�ar���&tN���r���ݓ齞�x���Y�Y5�P:��tS�Q(]y����'kѩf=`!���K�[&�?�
ԋ}�6��n"〙�F[��M��e�ȱ���8H���'�����k�Z����]���?,��l]?�K�}	G{����F%�0��,��������7A����.���Ԁj���Yi8�yy�;RwؚI����V''�� �S��ҹ/fj��}n����3�+��[5p&-��pjp��4-��C�B6=8�L��n����DL&�5<������4}+'d�ayȘ���5�����и�ko|�$��p����U�^ʨ��17�r/�&2nӪå�$?nv��՟��Y<�0�TY'IP�m�y_2 ;RT���[𛳙D�/Zғ[����4t�S���!̱��(�u];9�U�j��D�ɵ��J00_/P�s������%PJó�Wxz�h�1�0Üy�E�Qȑf�JAI��e��f�@v;{Ȫc'3
b�>�ƒk��i��j��K����_ �žG
�]���h!�PF����B��Tl5wi��?�}K��1�Q�tV�����ѷ����V� Z���t.y��֊(�����a�k3T�DC�Jg�Э7�G;��lښΰ�bg�D�����F�o�cg���/ros�r/��-q�Y*9d��H�B��5h��#�X@�%�k;�����MG����f� x��`2���-H�ݥT��6�W���b~rə�i1���ؕ� �=u��U0���@ds-��{����L6h�R�U�N�����c � x��ی�t!b���K����v6�M�����`����Wf��Oקkl-x��H?O��9[���N
�jYi��a��;����yr�_s�Z���x��;	Ҷ&'\{�b�����m�Л���e�r�D��3�i���N�D�%;�~;�����hݕ2�I>#6^�7��ʤ�<��A���4?@��x�3(V'����R%"Si�/KD�9iL����{X�z㪪�r}Z�f@��]@�KJ�^yq���i-�� ��e�1HB7��f9UL��_�;�V^V�5Ǥ����V�=��@^�R� ���	�v��ܯ�6)B�'��+�ޯE���e��S��>�"ˆ�� w���.�!�� x��M+�ܝI����|5��6>��Ȗ����]������]8��XՔ��$K�)Zj�B��)��_Z)|(��Ymuy��dH�m]����U�?��9��њ�B�B��j<&6�Q�ʃ
����ECr��8���u'fݦ_��~�v�Y�r��tTBʗX�0$E 6,��H��cC���9�S�XO�C*B��3n�j��}�>(�yȕ��Bg��߽w�����9Ǝ�%�s8�ߚ�ǯ/�P�D\���gX4}� =�뺲�:�r-���a��m��+���5kH�!yk�=
�s�����A�r�~���e��i�zK�)���S�P��rwS{�v����~a�"�ڿM��K�Y�1�n��;��z�)"WNYЃ���p��ˈ3�mT���'x�b��9o��d{c{�Ә�q@���o�u��sY���-��|��o�ؖ��O��X����� }��fn�c��h�����Y!�)P>g�����.r�΅(���yO�&�9�?��p���d�ޥ����.����u������y�]�4$@;q�q�F4/<M��N�Ϻ{Ԗl&�`�f���R��у�5awg����,�t�<$r�ٰ�og�NI�<A��˝-r�C,~���<r��,�=�1'|�Edb���� �W�p��iG�d`Ɲ�8�bX�#�t�.ܞZ ����E�T��ʘ̓[�N�.���~�%�t]2����KS:O�m�Y����%,��T5^��ES,t�x�nw�ku8��m��#�
[J��~�B��ܣ;�CIF،��Q8�"S��rQ'�q`��;#@�u� ���zӇe���惂�O( p�2��vO�����BEQ�ta;���f�(��?���l�ʟ���'J�ad�
��ej�o������E��{��U�Btg׵�T���p���
�&F�����r! q}�w�o�����7~{�渂���\`3�������!x>t���`\ɥ9�9���|7ۮ��W�9�聶}=�%��K}
e��t֡��Uuaﻓ[�0�*�-ˉV���K�s�ʤ1p�E�mĘ�G�i<��I�)nN*�NA�eR�U�|l���w�4�DD�^VH6��ݱ��e��uKɣ}3zOV���O߸��-�L}�0OLh�� �T���S�,y$t��{����3;�k�^Nc4�v��q�P`E��+���$g��a)/�B%��e�,_�	�*ۚ�Cy`q"�� ��g�nJ�;C&�^�e�s��48��PJl�\���ʻ�L{�����;޲fu�eo��ד�A����?ע=FN���Bw��%�O�8�Wv�:�.���[�z��� �w԰`��s�x�(b�s���e%𹀅+g��j�ɴ��-���8`��)+�EO��j�S��A��������T˺�Mc�N�̈́��<�,��֡��|�X)I@�/5���O<�Vq;%�Y�����>|�qqÒl�GYIȝ�����i�?�ۊ����X�*�?Īmu֋U���<�i�^�>����.'�)Bh�a�~�b��L׌)���N��+!��\����]���S�����������T"�O�K��eߔ�M�KA#7󄞔��M��'�%)�\$��T��yq����'�r�<OR ��R�u�q���p���a^��RA�`Y�x�%yt
�n������r�=���]�$�:ou%�j�ߢ��Q6�_�f�1��
��)E��_;��:?a��Ǚ-��!�X�;Pׂ�qp9R]�b�b�w���f�E6M3`���S �x���	CX(a[�{��JـŴ�=*(=���*ٙ�r�zd�t��{ �|�	�8�$�$�g������Y�ҹ�c����G��<=D�c�ǳ���+�s��cU��Bhh���kc�X?�.���bӮM,�d|*���:��
t�� �n�}s������RIo�^ӭҌ�Guֳ���O�wT��!��$gw��l� �t(A�G��H=�F�ԓ�q,�_�a���+aŅ>�[�Kk�`$$o�7u�	V�Q���  ���Jr���,�b�nh��:����p[!��:}߿��A��� �_
A��A��T��#	�\�X?@ |�jY'���T����=���C �2�F�U2jY�����0O�����Q���
_�ɍ�*��~Ih�G솂T�E�PVr[6�`���~L��f��	�u��ʉoB�߷T��>��%[[����`�5�G�W�r�8���bj��p��~|�%3�l�� �c#/�1x���Փ�:�*a+Dj�o7h�R�B�pm�A*��6�M�F���&��P��֞C�K��]2R��b�	�E8��4˄�~�7��J~�P[�Y�C�h</��"�����W�T����#H^�������Z ��)�:����T��G�����=.���*�,�S9����Lj�84Eb�����yF���Ӏ���D��LpE��qh�%4ߦ�Z�J4�S���$9��cR|�������%�GQG��eZ��_�
�[UFx�e��Yn��Λ��,bft8%&�}�x�����5m�AP�;�Ɋ�D̑c��ߖ�R�+:�o����:sݶ>��
�UQ��wЊ�q�� EjaY9ᆇ�:�!�4��A�PH�}�.�9��>�����ʾ�	bĘ\I�(��c�\={������st��y~Dd�g((�\�h���6��"7�����g�!�I	3�� �-޸���	;w��l�$ǭ�	k�`�^Y
�~"�<�A�.����ݤ���2+�̳�qt��)��:ǻ�iS�ԍ��=��ϐ��B�ʉ%�p�*%���P� y�@��{�L��1�����9ABE���G'�#V�H�">���������$�PAlH�L.��b����ίQ^�ye�[�%KP��T�-ˇq���$p]Ǚ���x�� h�9�e�cm�8����jȵ�$t��뻎�e�^�{& ��<{�+����73���d�&|�m$�o��0P��5	�m��sX�D�@���+����o�O���hB 8z2,��܃��GLI:M���Xu�h�o�^�Èl�?�"�f��uL�'�{[�=��峹�8�-j)��d���nm~(IsԱ�8p��r2�G���5��U�:����Ms��/��X%4n�؄�,�	sL)�B�u��{�42�(�h0L0�#>i��p���6�$
<�6U7E�ȁ;���Ȃ�/:����as}��2:��O�!�ex�w�N$�7qÌ�]���P�CN#v����T�@�)��'a�50�����9�e(��l�'o�覲���)DE�3��Rx����n������n[n)�#�r��8�0���)/w*Yg�}�,�!�ߣ[_܅˩��A��9ɯ��B����m�:W��kcPs-T���!�<���{�	��hE�蔍������q���s�of:w���r�\_�A������Sdӿ�^l���<+���f�}5��J�[�}mz�c��(�����	w��x��,l&V�_#�FM�^<?ѭ8��&��x
r�w/_��pC�or�ד[9eC�Of�̒��ôI;<UREoRm�E�%*�j�.��L��L�B��z�֓U�;��E�~�B���Ew ZU��Gi:t;��{���!澿����z� �g"%V\ީ�\& ����Z4�y"�������5�$���S��5��]>�	�:��|�%PW˜��Yl�r�Hu8�?�3��/�vСD�BR�X	�A�-�a����%�.���i�+���,~��_Ft�k+ɰˏD�����$9��cf���+^S)���Y�m�"�l�Pٹ����F�y��@_7���(Js�<f�8�0�@�N���~ߍ!yfES��ѷ�$����nA��97jj����daB�Ks5�
�i��Wԧ^��	���g[34`;!;+�j�*��0�B����0/%5��<_/2�jºcq�r�L��	��ŗ<���jZ�#�<�_�uXQtY:��G팝C:����?�X����+��	�U���2��h��V�+��dD���餓�i��
�c;�)ݟ�u.M�h4��Π��B�����^C�(����W1�y��{2�����/���Y`�?Љ�Zߦ-E� ~�.���$����_єݱt�
��s� �[�)�i�/���b�e�zh��#��礯�EyEG��-u���ЉL��)�ŗ�ä����-�Mr�顒�f��/�|U�>�9��o�i�9�o�V�uV� ۊ���H������	|(�%�����ю�|v�L�6��1x�~��"�o�p ����&U�[ ���^�xq4`�sX��X��2(H�&$z#��(��	\C͠@,$[�g��)��R��Ǌ���J�����)*S��E��A�a��a�'�.�I�:3����N��9�k ����B��-�d\��m?�H����#���Y��U*q�՞�W�_n��f��#Ȑ:B~�]k��7�t�{{�A'��n M��&����7?��jBJv���:o{��z8i���TSu�u�$WY!REL��q�6su����ʔ��zW�?�d�!��\�������-�q���E�����[��t��:10�=P�����X���G��E� {�a���'��Z,�+
t�����v�P�g���2������uv9�()�X�z�g�CW����s�X�x|��5���
�D�+aE
ϵ��b���7%+HBL�>���������$�,|�}9U)>�>��7����e48͈6*!�?w�8[��\���F}��ʤ��-���΋<=W�K�7.��'��?�� k����hq8�����Kes��ۥy|X@��7Ŀ��X;~~�F�s���;�u#1B������;�JL~Z��K�ׯFv-|���M3݅�i �A?%���ՃF)��j�u����9���O^x�S8��˫�x!��lK��}a����d�TV�������S���l�t�Wœ�4��G�����u	f>�1��1�7��np�2vQz�LҬ+���K/ݥ}�7����R���v6~?]Š_!yàeu<'��|�cR���œ��Gb�f�-��6�N�}ق>PA�hQSA.sSm�6�.����Ͳ��bi�:��]= }���)K,o���j{Y��YR�����*������D��{��nmޠ`n�~�Pb�U�Oz���mqZa�Y�a�����+�/YZ���y�d��f�)?7K$�U��I�#�?0�*�F����)��/�iK��e�2v�h��'��}~���e�[F�x�
*'S���
-��X���C�?�<�Je(�L����A��HM�:��r���P�0�H7T�s�Ƹ˕h.��{��fT�A�?B�J �b��{�x�	�  rf���Ă,p�\,��lvS-d.Q�0NZջh6�����Ѕ�!��<�
�K^��x�1u�el��8�}�|$�}N"~u<��>rb��tD1�B�6����FC�1��M����J�������x`K��v�m��n�_�@�j�U�-,P��;*�C��|?\K��D8֝Pi��� �#ے@�+�d�����Q�&�iGͼlJl�+���h+�㠇�Ȧ�dMX�}�9����s~��Q��0��^6��?p�UTx����|"/�Œ;�e���n�Y�fq¡��94��o�b��v�W��8g/r̦-�����5�x�Q�iZ�	Y�y�t������
AV'�#=gP�Se4h�,��@�g)�d���'*Ok\t^�IL�=�x
F^&�Sz�a|���]��4h�!ì���vg�?��U�"6''1$���⬿Z�G�/s��kr����x�$ش��  ��B�-��H���|A��)�}�8� �M��a@���°:����4fd��Vv��]%��Ŕ����Ī]ӻ��|��/� T�*A���ِ�8[��=�����G�~����LZn��I�YQ��
Wu�LAU��h��=��c�f��Q��X��������[�m��op��t��DT��`d#�����s����1��Q��Vy�v�e��j�vqkx� ���ab3d����OY�����t��&�Ģ�e" -2q�Ɏ���:g�z��D�蝱���f�6a.�� �Lϋz�����S[�y���TQ����ΗYlS`���O��4�"��d�B�I0d�������q�pcF�9��$�y�P�Ǡ9�ǟ�>�����u%!4je�R���r?.qR������mi��R�楑6�v<O�R��# ��u.�i��931�C�W���#٪���X"s1#���=�C�n��8f!m�]���*.��"����}2�~�tǿ��#B�y{6��TΎT�u2�E\��{�~�?Ńv��ԛMX�����w)�+�ml_g� mX�9E5V�5���@�' �t�hE�n��K���"�|�J'a��o3�4����}G��$B%+�[��(7��'o����&mV3[�j�c��2���z�Iv��{XQ10�_�轈Q�U�ua$)�k����;De���|%��%<^����u6�{/'����|X�c3�r�cc�Qy���n��f�XM�WݦZG�,p�_Y\̆!.j��e��[�us<������`��u���UN<ף���Ͱ�i���i��U��ų�����6�V��?W�)�X�]��!Z�����|�G�M7�L>��͌
ꞁ�jS�d��e?I5�e�&�@�#������SH!þ���Û�qe\�A�R��Ha��%	��{����z�၎���ֱ�^�/�dg|��1�{Τ=����["H��J
��y���K8��B�������o;<�������
M�Qk��	6٣`��է�:�s�͡��`P�;�J�u,	��p:Go��� �����O�N��<�t~K�7ȫuږ�.8�#�����[��U5i�h٣�:��4w7�č65[�:��Y?X��4�����f�o.����蠬�Ҳ��r���D>~�s6�È79`Q�<�D�[X���r�ج+��n��O�g�{p%�a�P=�o>(a��rjY����RA�t�pg�𘍳�B�#�:Ώ>�I5�I��T�|�<��N�����S��M]鹫���JWw�g�;��v:� 5{I�1��~<`��;D*z���bѲR��"H>*�U�@xJ�'��i�Q�hB�4Z��*Ϫ)\=�������qP�,���z�B	^�Bg�1�c�ʘ_�
�w�d�0���m�.�?j�c�9Ϩ��百��Q�u2�Ջ0�8 U�n��u����tK��i�r�O�-��ւ�w���r��D��-�����v_8�?�ڇ���t��iC|�8%S3})s�(!���<������#���5�P���䆫C�/`�Z��(Qnh~�
i���5���XeK��8������t;uPI��,c:s����Wʨ\Rf_UL���%�y^Nc2�J5ƣz?�e�G�c��m�1zys�֥�w�w̫�\� �iq*���a�i��s��&�!���P����Z�i�Dw^��.N3��{�J[2t��WQG�+�W�y�������C���`N���:���@#��(qC�*�Vlz�)$������,��q��X��`�Ě&�g��X�k��\�H�ѝ"{��y�,t��~pߟ���2]��f]�Ĭ�`M�䒷�[$��A�h�͝V��.ӈ*C}�DZR���pge"�fgc#��n!d>��7����yѫ:~�$P�W�ɞ�;�T��^Y��yf`��,�!	��S�)s�5N���6
ok���_.��N�mܕM8``c�� &��z�1�K,8���?+Ug�\�L���RC�8�8�-r��G��:]G�i���z��H��z�ei2G�曬���Y(G"���݅f��]���e-�I����y�*�P/��o�B�"�T��'Uv���|��S�Z�:�& �[8����`h>�r]�C��5�o��Ք.fj���,�=Q�z���$�Se����4�e�=�A���~���/^,r���f���1���F���l.��D����[�>}����eFF��"��5fD`Kr$Ӧ�"_(�wG�:�Jq@�,u�Pp��R�m�붵>P��z�@8����X�{��%��XX �xɌ�ա"��8��by�N�Ճ�è�)~����%��/��*�>j�Q�zc	KۥI�,c���_�*%2ѹ��E��ԆD��Ţ()M�U�rw�U��U�rq�}�dec��6�w����X���q[�8��_��pA�%ȈH"�=p.{��#ĮZ��%�kj�41�Z깕�[J�-���g��π��XI�7�C����*����r����	�#Z=��%���B�L~#\,z금�A钌�F
:����������Qb+Q�	�iN�Ȣ
84�sŦ!sL*C�B�%�E�^(��й��Q ���n�]N�	2*�}����,P�~���0S`�pχ.�<(����z#"�7��`�<�e`x�KQ�=m�Ѣ�զ87���V�N����@{�<r�@ņ�lI2"��ȼ�1�CQuW��闷�#}լ�W��-�Ѩ�E������Y�Չy�n�����>}�M��"���+Ȃ{�X^�����R��WosW�$Q���qF �N5O_��S��fCT��ig�c.?m��K��N��I>�\ٌ�&pf]��k��ù�E1{�Pg`yR����8A���B���=H2X#�lűw$;?w�F׶�c���+^K�V�^Ӂ�ˬ�dr��,�Z4��Cf��_{��	�-i��B�GK��-�D d֍k4扥r>��}P�����^}"���hFІ�5��Ftٔ�[�Yrv�i�Z1 L���q�(T���LW��^
�mm3�l��,&�w��f�-}��i�0�?��Ti��"�vgT.]�;33���/������]l�� ��vb��X"�K������&'���2VL�fD�����#�	�y�$�w�/|(�����*�|%J���r]���E��a�ϋ�c!�M��ZP�y+�A���\�h�Y#��P�d}y�d��	)��r��O��]��@ݺ[���/�r��s`�G���D����h��P�
�͵�'��Q�T�`�d��w��˃"d3��&�;��nQK�����o�����I�\:%�]���V)C<�d�T�qյ�����0Ja��}:����5��\��l����r���fe���If�V:*���U�?�]k`�G��X���Ԕ.=fS�..���"3����(�3�^�����q?,�Aۅ�2��:�}��G���e�E�%�Bd��i+���%T�+[b{`N�i��E����D��"1���d�R��ԏ�G���� �bPj3�A��GN��.x�B�03Shl�����j�B�8K�3�*7w�����Σ�r�DH3��|̲�y#�0��U�4���^����2�l���q���<O��J��x�ݒOv��`�� ��:ԓ;B������n��tiL���r��r���;�Y���S��	��|4��_���Aw|h�G�GZź���j�A    *|^�Egp ޯ����@���g�    YZ