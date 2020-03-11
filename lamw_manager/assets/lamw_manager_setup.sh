#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="174917226"
MD5="64acfe7bb2cb18a06d612723f85f69c3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20820"
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
	echo Date of packaging: Wed Mar 11 14:05:29 -03 2020
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
�7zXZ  �ִF !   �X���Q] �}��JF���.���_j������ܫ�έ����ҹ*��G�X�8���ش�Н�f*ĝ7wgb��Z�}Nk~�ѾLN�!�'�!24��M���@y�%�K�S���oP@�x��k���a���|��p-�h
�O�*�q���E��/b�WG�i^�'��a���ѕpQ�Ad�%cWF]3������Q#֖��/!U�n���ʖ5�e"Ҿ��M���3�6d=	 n�:Kt~���AC$+�7
`
�v��d�n�uH���?\s>hoR��l2�4q�Qēi�$[0lx��A2��(���Λ��]���āF�-��kp��߼�-pp��܆M��k��-����M$�1����oh;�ڛv������̢p\�]�7o?��Y�DqC� L�FnK�S&�y�J@Ĳ`�_�k�j�IT:�
��9�I��p�P�ΒI��xա����� �IF#~f�����-��	HL�5h�$��"���Q�%�?�k�Ȯb�K�3�T@1��[�������2�H<;�z�)�۩�C�{(�+P�f�&�U�8����\�h����Qo����.O�X���+�3��,��O�,��y��� Q�-U�H��gZo��L%Ȏ�����ٸYgz`]�s���1�a�X1�v4M�97����*�]حd���h�}� ]�f�?��~ �?#A4_^6O�m%sN��9�y�国/3�`��߈\.Z��5��E���+�8�-�ċ����<t�[w���4�@��N�����nl�.��%DtV�L���V�v���2�]�>.�1�ܺ�	�����YCW1���d��0n��5�N����u�^OR���{�uvp�X�=�z+}�
���Ɓ�����pn�x|��bGy"���i%O�Ԟ����KLo{���Cs���w3�K#�)v�-jtJ��������J�w��M�.�{4č2u�� 8'K��
����S���Ȋ��+���,5�_�/~B1��F-7hO�[v�7�I):z��s�B`�L����=�6q2ݏ_Ĭ�k��{�X�@��+��b��������_��0�ۀ�>h�r��
B8;��xUA�!~�+��R�ɨ�0&��a"/��mz���6}���a�Q�W�1�o+����E���O&.���s~L����iN�oUV���xx$�7c8�=� 2��x�0���p:��%X(q<q6�@�(ދ�n����VAǢ�=(\^��JɃ��o�&���v�━���0���I�:���4TZv,��;�`�DgJ��1��-��L��(Sקa�P/��>B��͆˺�)����3KX�KhA��3��B� ��E��<�.r+�0n܃���ԉ�r?v��z�A �S>�Ѫ�X4x~o�Z6�,=L(X*ezsr��&16/.��&�h��D}�=�<R�����U>�M4ꚪ�sh�Rp�wT�#�{ߞP�Mi�����3l��Z��QvY�-���x���ݻߵq�	��G8�!��4��P���=�>�7� ��  V�u"u�5�M�4[F;횰��ޞ�II���6�S"X����/R㔑
͙�4���#�̖�S���n54��y7	��+�}C~|}uo	�^�o)����81ʍf�>Z�w�	D(�6�W!���}�}"Z��H<_Γ�&��yo h~���	-[�v�9	�\A��s+i��?2.����fp����3}���Jz�����
��G�1���jI��2�_wR5ҽ"������	�x����T/�A�r���[~Pj����G��k����tMou�z;�9w0"S����R�c�~����
��f@�������X)[K��9|�A�o{'`���E�N���'��h���t�f��� N��� {|���i� &��,�f�5pp�jn��W�����.c�=	��A�Bn��w%��I��|�e/�XUdK�Zr�A�<h���m"�SՏeQ�����&8v\Z �W���}1G��mD�|J� b*Z5�Z03ߚ~�`�l���"߿8��}��=�Ρ3WuNe��E2���P�W��0m�}Q�D9'�t����U~\�L?)Q{h�<�P9�����E��qe/)Ό�� nx�u��_��/w�=��PHNB)L�m�y�|R����YO��Z�Q<օ��Ux]Z����m02��[} ^o����� �a!9L��cF3~#�swP��)��2̼�d�I;:#�������ʀu�o����}�� Nj�;�<ti�IT�Ӎ�`��(HP�:)"e�d�~��ʘݮX����+�u�)���3\7_�3R]��vӟ�r
��8#Vɮ��q�_�p-�x/_~�틪VC�E�`k0u�.1M��+ٺ��DT�Ut��_S�N4��0�mٰT�Nw����Py�U�5�X�h���A�L�H<(}�((������g)�w�G��50_ A
�L��RT8=�~
��bF�:�^�(�=b"`�S�ܬ�
0��E�奏�3t�?�W>���p(�:�@���C��a���w������1Xen�jC���xq:?���ɪ�w���������&h2�nCm�9%o:�ҷ��:o��\���RV(�L�@�Z�-�~��TŶ�D��*����i_��c�GI����]��n6��U��>�s\w�=#;/�Z�!�2����2x��|�Y����z�7o�G�&�����K�":�'W�W�p Ƶ��s��}�/눉N�0�n�uzmo )L�S5v�7�<f7���ž�L��^�%�'�Eb�n��, ��	@}f߫�N��z�b��E�(�(�E�>r,���f�"N�O\8��0"���Ac�/�7!;ۊ�,A�6o��@x�A4�ݧY��fLhY,��Uƛn��#z�����H�2���C���x���z.`z����}(�I�7������j��=L�.6��v�O�]�M�)9sw���]���H�@&��40�>u�-�`z����r��˴!Jza�dc�,�̛�S7�P��:W
(5�=�e�GKV�um%��g�CwZ��iHv�_�hO��X���Lq&�0oYG�"���~"�q��3���k5 ��4��o����W�1����5�2��B��xL��H�%�L	 �6aOWG��ޙ)d�3�` }��J��Y��dC?Jj�~tr_�JV�f��01���Ӹ����I2��P�J� :������^�p�2Y���K�ŗpCk$�@�s�o�����W܄��Vs/V�\��QfyPe�,�#/���g@\�B���b��/���� 5sZ����q2i�RGOq�rJg��@]���D���Τ��6W%3�����SDPf��%+����8�d�U�rI{ϙ� !/Km�ϵ�"	�
I�p����%��`ƪ����  y-=�u;���  GX��K�3Oչ(�б���Pvƨ�����ag�J��e47Ɓ>��Z�S�������ӝ��*v�L"P��L��e�4Ha	��3t�cV���UJ��W���������"��m�C/���a^�r~p�zc�>�A�\@H�K��a�a�)��!T��SyO���d㏬�5�齬�!7EI�%t� �0���m���gu��0I��`�.uc�s��\�]3�IW���RF٥OQ���;P�D�m>��Q(=�vd�S�Sd�)��/_@�v���`�$7���h�c0���¼q2,6d��A�f����F��lIyj��cܡ�2�����]	��5�`�5���5,֟q �G���5i^���amt�׺Ģ�)���Z�7Ŗt�:�_��ʼI�Gԃz?�M)3���F�yu�0~=���~O`���uo�[��r��ݱ�k������,_�ǜo7��|ъhG��dB���xH�D��NI�(��P)�L���	9���sE��,����YQw8� �ud��o^���4�f��{ͻv��~n��7@���RGPe�1R.�6�7|�tIo/�Sz�,����h��>�5Ԇ�\�0E+�:d�N����1x#�������B��2)hP�b~O�NW ���eW��*��7Ȓq}c�l*J�)l�R��-�*I]����g���:j���^*��0}���Ll99��j�AN ����ad�(�;6QfD���n����І��n���h��v��(�C�g^(���h���`*M���X��H�N�����d,��H1�	����_��j�{>�V&�
�gۣu��P�dԁ�h�J�{E���� �zBj�e�s�~���7�tƴ?L���ݹ�Pf��5�>����i�z��S�����I�����GB#%�ob�Kv�^x���̑��L�eȡ=�|�5d�DM��q��?��ꠟ�E�up�R�*�\�=l�"��$f�r���%��L��lع�.���h]��.��MC�{
�.�ߡȟ�^dĶ�d��5���W��̬�l|cY˼Xc�	�+K-����b��H",o0"+9�s�N���-Ic#ے�bZ�
����c���[H�H�W�xZlY���>Z������<��P���/$�<;�P�4] ������b7J��M-�QӨI�p+�]�Z�9����T��}�\^㔬���{�Z�fL_��#w�dXo4�vF�Q1�,����W]\�:{��o4���Q�2{�Eo����%�/h>�XGltt�rXK	>�z,8�+��h�W�F�����H�8E��h��uɒ�Ճ���l�obО��8�}�k�ܰߞ�nA�t�/���ߤ8��5��Q4��������.jy�
��P���v4���7#}+a3�v��
��t�|���mS�,��9C��S6�Э4�}I��Hg��KcM��qo�3��F�[�X8zl@ʢ�bQ�~e�loX�g�t����FX�����~E�X�Bq��!�k6��Fo�X���:D�Q%H�P���T��(�J���:La���p�D5Uҹ�s�W��	������K��=e���׻�����gߛ�,�V{z�̦��,�LH҂��p�����\����ĖZ/:[� B.C�ŨY��#Kl{��)愜�|ރ3��s����trK�MZI��L���@c��_�;�����l 3��Y�l;��ɇQO�$YI)Á�dz�Zj·mz�����x�+�����V�[H�vM��KI7�a�_������#L��߸��z�Ȧ*����@�7؍��{�5`s�N?K��0���a毡����٬p�H!����T����S���A`9���lf�������'-����D'+������"g��mGш	��}J�3f]D.A� *I�mj��9��px����R��{	�$[�*E��j;�H� L��I�`bh��G�I��JQm��W*����O�V�#`{=��{�� �9�'KZ~(/�u�����5�u�Ճ)���=�2�1��1�����@�% V����B̳����3-3�(�Ç�G��Ӽx���>�	����玸�lo�w>,�	gLy	C,IrN���*>�V�{k@�������	�v��̪��o2�y,��k��E�nꄜ����ҕg�?!\�s�.x,;�U����O�0�<?��9*V�;�#&�=��v�E�;'!ӐN�P��pr?�/�u�_"�zw];U���*��04�f_/�p�{B��W�$"�d̮U�5r~�zܰfw���!�@_yd�y����8U��lHG�P�PuYy+�A.��2�aG����¯Ϗ3~A��]��v��� �+����?b�0�c;����l��d�J
oQ0|P�	ёraK�ً�d�!f������')b]]�]=�\���P������4bp|�㈳��;��2x6f������%�����h��RQ�[y�����`�Q��J����)F���D�Qp.�j�;W"s�n�p"��z�1 ]����2�ǭs:�$؈�ye�
�$�Pa�	}����E!��dL�u����ÙO^�RL��E�`��~>l��K�AD�]��R�*�����=b�jn��3���������R Z"���Vo[4*�r�@��»,�R�����i�:R�y���;gTIL?�2򴯘��'J�e�B��^��@����8�ɐTc�0���}�c���r_����Q / �d�����;8�dF�!�w�j�G�fP8Sg��9{�8�[h�l�����
bĠ#��{��n��h~T�ۢ�]�}���o�{�3D6kfn�����r�dU����D}����Iakܩ�������V�5%{S�I�� B q�8�+Ed^a8/�숼�PU���e�u��^78��9!;i�9��qS09��ir��i�]�O��a2�'�44��\^2pݖ�%��8������X@��s��o���P1P-Vi��*6"v���Ic%wE�zAM��y���Z�>��R=��9���e�[3?|�Q��.�o�$�]��~����������aT>&Ji��9��;�Pܜ�܉a���'uu{7�')&k�������F�܏���5��JȞ#��}�W�
�����ׇY���� �~k��WTq�G�J���YY�J㻉0���J�Ͷ�$_����Q����T�E���Z44q�J�8+#��sI�\Y��0%T�O��(�1XKZ0��	����`>R�������"^ۣW������*ߞ�
�����U'�l�5�F� �0nZ
<���r��6��������M�Q����_rG���DU���%�ϼ`�x<9�F/�/}ihz���Y���S�A�~���Fb���&a�0E�?[3��A�2%R
$��5���l~��z��44��c�f�n��$�Q� yz<�	�ْ;:6Y=
�L�L�-a�#x���k)��gΒ8�U9���'eR�*��O�^�9TV)^3�܂��d(���'�E�#'�&����"k��'�Q ��l/N�`~V�x5i��Ay�Ta]�3��qޣ�!��Zd���{�B�P`2��h�_Ą�3<^G���ևg5��k����LpR4~�N�1x��W/](k�� 3�R⾑����+���5�g��v��_�d/7l����ѣ����R=�
�� ��O�="4��!�y-o�(l�[���K.���[�T�MTo��q}���QJ�-/7�Oґ�H	��r��l�������@��ųuŨ~M8y=�q=1�DV�f�7y�B;��e{.rV��k!c{���rg���3o�����}�ʑ>J��OM�~��l�oC���z�iw&c��5N�/��0g�4�K�D��>�Jޒl�+�=%M����8=�I����$R��7��>�{I��慮�J����}����:B�FUF�o�T�̨i����egy��]�():�h ��F3l�_�px��c�6]�`Lg�V�ȏ�{�v����6�[�/1�>���'c�gŝ���`��ذyf�,#RI���Ֆ�L~� ����x���e����P�+�L�q�	��=�����d�d#�N�,�g���23z���A8�k���ک4�Uؘ9�ΟN��[B�vMK��^�\s�������4`Bc̚}��
��#��������_�T<q���P�K+���{�&&8%�����J���ٛ���d�B�=�;�Dw�"�]'�	j�Y~�܍�iI��*�(3����$n E6�6#����_0�����鵉X�g�=�2�˗�ɛ�p��"s�1r�cR�3Ѯ���E�d�X�w�qzrk��5j��k������km|����{�.z�k$"��M y3�Xj�����W��0F�jB4v���FO����nZ���`<��I�C�o�a�a���c@n��@���tÒo@�i%�	�Q'�ZBc)��q��-t��Ⱥ�������:������� /�@����J���&�<�&(���P,�cDjpι�U�N���+ϑ���� R����tǋdD�p��]�$$�N��������^�(~TTc�\�kh�ڒ�ֺ��5$�w��l��>A��7���N[X��@�y��r���g:+���I�;�YbU�1����B��{&�q:^�
�x����񴑂����d���YT ���_~�t[�E��$�F�4�OZ�&�eh�|뚃����]���6�X�jM���v��ؽ�1 `�c����dz�3�M�����.p�<�oJ�rw�좩��=[���k�-jŝ�c��g�Ҭ����/���x�n�N���ST�e�����۽�Y�V���݃�qA����2K��m�BI��)$��H�rN��2jT6��=�[�i)�*���� A�c��f4��"*n��ĳT.�F����sr� �Q�$b'�D+�O�e1k@d]��Z�E$زqĽ�<_�S�^a8m�z�<���X��<,0��)` ��Q1L>6Z`>҈�YX>RN#$�쁿13�@ �I�(�Um�F�D�C0���gQ�!�kRb��������o^iɡ6���W@u�b�j�[<�ikU�ʌ����02dI%sC_���U���b ��(�
��E���$�a����A���nK ���$��Ӡ���/G�eh�X��[!ʼd���:�8���]$KķB�����q�)����e9�߳+��@@nO���}J��$��Ӻc%�,u�Q����(���x��+I�H�H; &���/G���<�ֵ���_jH	��PMA�+�n����-�,������~f��'���p��'gzq{c�
��'�꡹27�O���W�N/��&�w�]V,@�r�^�j�5J�9_�����+��M�M6Mk z��N������kXvr���g~�jG�Mk(T��$��{�S!ҫ���Y� l_�R��]l�<�Uv.�ٛ����A�a�]ӟ>**��� ����x5�ӭ$@{���7�I�����#�N씥�v'67������o,H����ߕ�#oӞ�W��!�ی}K����o�8d�J�<�4:0㭘�D�ai:s�b?d���p��S=�%d�Ֆ����hu�8�8f� <U~���c���^f��I���� ���(�����_�^��1�"��]D���G�/@�u�("��+~�o�6��s0���$jǀ�ߐf�(�0o_�s�pM���	<xa�.�)�" '1�29��v����t%�Y]�-��}'��5�8�r���`ù��B����K��g���te�G��C��h�L���%��_��8T&Ռ��m>!�o4��S,҄����
G���֍�<���\����R� jBl*]�R�ޫc�[�Pg�^�@d�x�>*��7��I�3������+M���~Q�����B�B[��$��8}+4!b(�Bs���
�`:�DUG0�W���f��o2�W�<mL�#�	C'(�"y|�q0��jCZN1!�+��;DJ_��
�b��f�6�֨j
zi��Ԗp4!�
��qW�]y�;x46Mp���C���X�R�q%�&��b�F�D7I�k��c}YȺ�&
��(!R6[Q}�gQ�4��I�>b�gNXd�F��.na[�Dn�WVO�=�ZS�ԁ�:���b�@���<��X5�N�NY�����:`��j����jA.~0(D���%�,��:���T�s<�h���i`}�# ôxc��@ ��/�^{p�)��%2�R�E~��pJ�Ṫ��r����}4������Y��wk�.1�������VJ�а�RC������5��@���`�X��3���e1�����Z��=h��7{�ʗʷ51B��W�����?�3�!��u���x��'Nk�#kB��ݤ���Ӣ����JԽ~ބjKl��I�+كk�o��o&�83��2D��q����.Ӣ������|������>�����O��霬�%�b*�"|p�:#�J �;�qca�璠yF�}�x�H��ψ��;kW:"�)����C���@�Q���ns��t�$����u��BT���^��ӆ3H	�κ�5��1������LhPH(a>�&3�Y���k+\�h^U�$X� �<JƘ�.}!вKŻ��>�L���Ե�μ���?�.V�4*�����{,����?A� �񹣣��/�S�HeJ�)���r�]���Hg�S�/��T �������3�Dv��-���:}n��� �"L{��K��V���Sw�Q���xo�M�ϝ��KZ�t�)��C�c:��L����+�6�*�)+<�(�~�F�ܜ��Zj����O�nM�����Y�FG�%,'61_3@���LFʉ���3&6"��ա�'/eGS��������@ګ�N�\a<�_�Av��x�g2xՁ��שl]"܃C0VÛ6"�L�I
1b:!���}㰃X=����ԝ .����Ϩ�~-%������zW0�^"�8�I���*-C!�c�����_O_E0���1�ۑ)[ۢ�i ���!���7��N0�x:T�Z�����Ti���T����0j��H�����:|��Bx�3O�ٯ�_ml�Qɩ��0���@��<��}R�����f����	F�)&�>e�\�*���4�r��wG�C&О�
���L�Y�S!{I�dh�}�D-�"6iV��V�'�a���\�+�6�-�n��b3;6:�N����.��S9�Ì����y/�^��U�B��/44|Ҧ�t�hF��� ڮ���j�cQ>�=����w�M��dj��:���%��V�'�`A8�Ԃ�$��Um�l���&�������,p���Mj)����ܙ��<�j�����`����%�w͠i������X�t�%������ԇ@[�ұ��ė'Jk i@i:�f>n�Љ�w�H�~/,$��ZV:i
��<�N�B�X��Q��}Gmv�-T�7�y�+�$B�r'K(��n���/f��xbJ��k��_̇�9��f��}�NM�2�_�J��Pj`���-Tc��$�ҩ���d���*��jV�3�m=ɶA��.�I^}�컉�� o��?�bV�Z٥֟��Ϲ.�M��D��������,|�A��7x)ֺ��4	|�(��U20��T'%W�� �=��������0�����
��OHm	&��y,�����Ͱ)�l�T�����W��"��u��Q���3<%2&���cJ��k��M�9Av�K�d6.�Z��/����r!�} D�UT*"�e�Ϙ�/�$^��� 4����)S�rջ�5�^Jz+a&W��Z�X��b<j�{�-;R�jEi������'/9~�����E��y#b���|�e���L���gi4��+���4���'�����[����#��אq�#���(��ְ�V℔�����د=���R��h��-�.���MZ,��
���Q�zW��mq�茇��:��;p�����?� ڑ"El*ô�d2K^	���䉹F]�'s0�a??vKt�������0��W��HϮnh
�k�7>��
�G��Ta`�{��
�3��"Ɉ�LȦM�`�K��Bp�vo��x���~Fg�V x�g�������͖Y@�&k��hE��{ǩd�o�N���/�~���S���1�H���85��"y�{f:P��#�YP;1�m�%,�]��FK�#��"l��{���M慚XE|C�@E)s��Ivj!�/sc#!�)��M�!:�o���p�G�p�ȋ0uc�̮.Sw|�\�ӻ��e�v�%�D �A���w�q��D�z���MX���	'IS��X~�&��#�7�P��;�]�7��������3�3I����9y�kaܰ������hR�]y/U[�I��m7��Ϸ6�K��F�A;�s'�Kԯ'��0;��Ar��bds��l�)��S���E:Z[3�㛞l٦��H�5�aӮ�4�%?J��;x^+��#��f����[���X�Ӭ��zΨ���(�6;�d�����i�l#fi�V�O9�/&7��%kR)�]�B�Y4���Rcӣn<C]����f���}��R�O�X�:>��^-ήw�WAn ) �E��������G��wt��_)��y���C��j��}0 R(�d>q�ɴ�&��BEn�"���~��A��c9�W��c���m!LG�0��,���u��xv������P�#��tv#�W�1���/*�D��Y����m�((����}���]�Rj��|�E*��$��{�{�.�[f��!�V���z-D�f�c*���"jq�>�+ؗ#�Axj<Y���|�����Ex�d���8�(���PPk����NE$�zE�y�M?5��*0��?�,")�5$RN"<$��##:�7Y����)�2
�-N�C�ԓ	>�ڸv4#b2O&�'JHo��N�}�J���.� ��~wU
}��J�Ք`X$1�Wޠ�l��.��3!,Ot����<����y�BW�M�����'�d�9
�Yl�>�dI�5�(��γ���+��
�F�y��&���:s���R�
N}4rĆ��>��q�A��qhT �͢���tu��iJ����ҍ���M���&�!�4�!|bÜB�[�_#�Nb�t��X; Q�Eku��:���DnPp)#���G���,��
��k(,���H`EԦ�+9�8�-��V��!�O?�+Vl�.�,�G���y��|q�<�aU�#s2��`��b+lF��9�W��@G��d�3-[U}R��Mz�E6;�4S}4���z�����ֿ,��LCCx�[[��T�����`q���� (���,Qj�kS�}=��ۅ�{v�A*��WTW_�-�u�9$G	$vڞ�(h�E��i��=�D��ALr�6|�B���l�p�g�hc�5	Ͼlgz<uYߎ��YF�n����կ^t�*�7-!�IK�F��"?���x���俏D#��^Y\-S�;�0R��(���O��fS%f�p"�Q7(�XhEK���n�l�ϫ6����XBe�ޝw����{�ڍ+���!W� a�{u�%��1,��&��UV#�Τ�W��:~La�8j�F&N�g�n,���G�R�v�;�X2<������`��*e���t�u��gxO�)c�!��L{��x��Z>B�-%��D�����n�i_ܬ9�X2��j���`3WNg�T?������J�`�{�E�^��XpТ��9[�$\R
�O�}ʎ;�L���,�I�*��2Ȣ��I�������px�S?��7P̭�^0��{��?A@���z��M���F���L祹|ؤ��3ҟ���m1�#n��-2Q{�?R��*�͡=Λ�BJ�g�ǋ����������R(����l��C�v˫��"�tn�*L�s8��	b��\�� +��m����)ه�j���X�]�%i�.����Qu\�WVq�����F��[�_��3=M�K~^�[H%��^6?�!�G^�o_���:�=�a�lLd~�R�lq�mȩ0��6��/��mX��	w�|�qi>I�Z���o]E9G�` ���A�����D���J܇o�E����=<��� ĵј��Qz~}�6��9@��`��vw a��=)"�G=���'�ǝئ]�%d����;='~���C�z��$�E³����h� ){@��$o� ����5V'�*���'��
ks%��,
&�AAJ��n�T��@�h�'(�a+�!��ϢX�s7���&���P�#���ϠQ�j�ؠ��c�T���=ϕoO�|��
��O��$a�ǒ�p=�G;�jɒ�����?�O� `2�2���-�1�4�t����/V����&�f\``��C<�Uh��H�9\���6E��q���$����aҥ�0�WZ�6	�;,g7.�H��-��y��rÙw6���+�B�A���� /z.sɶ��u���Y��E���!V��N"������֟�/,s���5<�q�F�G>ם�����,�PyF>�=����ޢ�F�"�r��6��Z��2�Y���ajܕ�����IJM=�h�3��[A�$KrԜ�ە�Ǝ����IH]o�kbݫ��`o��Zm�(���.�Vn/e#�c�g��(6�'k0�W�������S�tX�՗Y�Іb��5/���cΗnP���j�_X�/ԛa�E�A,z
�h�B�������>�ʫ�Q��ӎ\�&��4Z��)@�Y�G�1�r�.#�1�DZNN0�R-!���G!�pҡi�f�eL�����?�X֫GG�~x�t��Q�Jr� ��>�V}��t�g$�y����1��R2�΅fT���'��4���p���
�<;l��{��'*�A@/uL����o�,����F�;"� �m��C����_��g��*�f�V�SP<�>W0˲`̐�O��� +;�&j��9�Z-�g��F�/?�s�J�Zl�>�4�6�s��j����D��	��3X���t�22"u��������C����0N˯EH�]4̽1���g�/XK�}G���1�U���Aru�҆��I������b5M�	�w�v��aI���/�����	$�/}�w����_p�k�*�&cz������1z]���G�M�䒁Pt�Z.-w���6f 3���E�M3�	���f��"xg����r��ԛ��������r���C9�	�������*݌��B��q.c!��Y������&a�*+�	)��4"a3Zq�ZP���]fL8m�1���B/��/"a��>Mo��`��7ӓ�ݖO�b�xK��v����'fo��E����NM�$���Yז�"%�����\��� ���?��?��<d~�IO���gq�kl3��"�R.��-�k}�[��/Ը_h�pi�:�yۻ\����ÊB�X��g���B��xэ<k�&�oi�zlE���t�#&�L�hS���f�{Q�!laﾩnր����!�3O��ㇽ���yU��tz[3f��!�70��4N�"��XVd�ִ��鬬���:Y%�V.Vȋ6��D�揹N�L�6�dQ�_���������DZ�(ӥ�\6a0�.Ug� ��h���_e�Jb��ǈ�{�	����[q�V4KבHЏcN=w��I����NsW�X�ڴ,e�8�^[Iڐ��}�������WͿ�ت�� �8_�"��Gr2����);�T���1�ӽ�-5��#�s�̇[ϣ�{��0�2R&J&"�V��y�,�v`]�Sy��}�@����X<o.�Ù�KZӮ�@ߏ��Z�����l���I�E�L?E�����N�~ۚ��e�������%����6��72Q6��~��YLۉ�N��	�8i𫹛���HO���a��df�c���Z��P�8���"��+^s����@�<)�_��5��2��`[q���L@m�"�[�ۥ��A
Ux�Gh�A�ʉ)0}�5Wǃ`w=�id+k�,��m80�B�����8BX_^o�H����A-���Q� �ˍ.Lt�>? �X�ep
=2�F����'��:�z��&HV�Dg1���e�R�tgoO��VZp��It߰K�b�����X�]~�i�t�q��&��K6?+a+����#t������v�o闊��D���c�܋)L�I'���v�ֶ���~�R�B��*8���%ǘ�
m_l�����>��ޤ�N+��aZLM;KS>z!�����ǖW�>�,�yUƌ��ӭ���p����?� `1}�pr��?���S ����W�o���,y��ޣ٠�kr��)t[&F]�̨M����%J� q�	�x�'�Y�*'h-�v�G�����q���4�,������1*hH!9�G���������d�B�=x;�WסT���NZ�{���f��T����2~�Ȅ��f�4�b\�¨�������4�b�+�1�J�I���S	�O��,�iv)/0n�{�����<!C�$��l�5m9g�Hf>[S���ؤ������N����-�vm�,[B��ZA/�%2���>�#;�]xp�G纲IM���M�yk���4Z���%þ��"�{�{>�tQp^�o��J���\��!����?qVؖ�7h��1Rq��w��z&��ڗ�ߪ:�b�A��Ԃ��������b��D%�v���?���3�V@��H�M����ֲ
�v�}z���}s�֎�.ޗ�5�\���9	�X�䫈��N�!/,5s>�.��l��A�'4h���2R�0qW3ǥ�vSB����H�[�ZF��_�LFL���A���Kzl�z1&[df6=�POV��C[�j쪆���c�'��"���_�}�f�i�oIr=�Q��G�i�.��%�:CR0t��uѱ��P���yʓ5~@�_��?%�2#��5�P������I���@�`N���Bc��17�F�B�t��.�!����QR�#Pzxs�tĸ�$��j+�}U\;u��㼅_؛��}�vZ��ӡ�W:[�Y���3���1l%;��P/��H �,�g���K��u��صa@-[����~��'�$��ѻa�*r��xtV��9���B'
vEDA��'/��|nW�V����Y�C��N���3{#��V�<߻jl<t��*&.��g�~
�$��ì�R|e�d�Q��^⯅����|�e%� 4@kA�rR�z��ˢ�[��LD�K�^?���^��)�.m�-)��H�:����@1H�t���Q�V������ �a��qO��5c����jїz�ͳ�x����%[ӗ�{�RO�P���Wt�]����@�?�ן���"B&ۆ�eZ
D�Ċ3�>xZ��X�==�,?#����ȯR��h<(ͱ���3�x#+[J���\ ��U�6��9���K䒳R{Ņ���4�����֍�[���U���$X����VdK�\�%��H��ݽM��ڊ����k�c�Lb��NؼV�D�ѐ�5�$+�l[8Ϗ���o��4
�3�� ��$���敡��-�Y9\U㻿�:n��R��IAkڞ��S$Ł,�U��>��>�p-m= ��*� ��qt3���NF��d���"�2��F��gl��(R��t�X3ږi>�c�)��M�����t��s���Ej�RI�P����*�z��eL����W��D�8T��<\���P��F�����M���k�#�[B����/2��:+���>ܾon���5�x�v����;�Y^����1������,�(!�앋B��iV��^»nu���04wP������A�_���ig���mC}y����}q�z`���	�-nNaxm!3,�Q~�7S��Fd�T��|��O��w,��$4XOF'��تf5�����>�>dd�J��fDrhjFG4<����}�J��'>��R�g�1����ճ���v�o���/n�4!\4eV2{^~ĀY�|J��5l�6,�y��-Л���0�հ?#bs�@��D@���-�S8^�!&r��KW�B��<y�s���5�o*��r��N�V4���J�d�D%�?GF�ug�,���/�4+fzJ���UH����XJ������I�w��B�*�Cz˾��Iͷ�&��R,��5�eS@'��a��!��=9:�i�� �5 l�5�ڝY^�����f�v�罞4WP��'C٪���$G"[Ț���_4}2��c"�u��@�%�n1�z�a@�f���(a��������)�/2e�A��U�O�jߥ3��?���㖜9ʋr�"�(�7�]`;�x�����񒉵�B�Ҳ�����i�R�1a+S�8�5y'$���\yf*y�k3`��:K��S��VW�W_����&&�U�B�2��:a���R"5ߦ �ƒ��Gn�<���X_�g�BsR����ڏI)�oÏ:���tF\��exJO�9*jT�,#�n�e��[��N�I"616�-p����L�%��:��6���g�ͱd�
S�h%ȵ��W�v).�dI�ݖ tZ�}��;���@�6+~���fC�̏4��:1�a1�0K��F�id>v0Y��E��B��ǩ�YL�����J8��G?3\�Y�-��PDcԌ��ͼV�`-�3	u�'qP��?%�^��,�����l:���nq�`9D�ƪu�c�@��vQOy�2U�0�c�����4��>:������6�,����9=���U=NI����R�}��~���&��f'���z�37K?G�']�W
��קl���XX�!%��@�����ê�>Q�G��A�{�K2� u��A��H���|����&l��˭��r�c�������"�)|8-@�m�rU�M�T��H���
L����٠칒��)���#;��>��a��B_���JDX�/��:�w�ld�D���%M2�^��)�C��q��&��ؤ���K[�;�!F)2&�>���#ú�ߵl}FϺr���Ryj�+<�-ǫ�<S���FiK
m9)��)�`��/ʆ6
�O�:�Y!=�N���=RL��Y�{��'rc�f�&���0r�Y>MkB6&��Y.`r1����9��;L�m���7�Uv�wɮ�����a��Ldc�;�Z��b
�����dh�3(l�M��: �n�1/yG8S��f�beV��r��v�|d����_��^�����%.qS�s�y7^����bI�҇��	�)��U]H�E-"�t����;��I����k3�>G���$�����1���g�9}1���e��[�_��iX\12\�^{wI�t���4/��}򡲩ͺ�{��|ޥ�UG��Z	e�ց���b�ٗ�"@�n
�B3!�(�{��*2�zU�A��ID�Ix?��]�]dSU�!�܅������~]�8�0rj������]D3��ɔR*����{���N��9(�A4OM;����~X�Ll���ކ�Q������ʞN�3�"�eLI�B�H�-�h�#%��D%�HL�Z��q��7�f��<��^�'����qcG�\}V5������eP(���ᑯC�n`�C�{2������J���~�Lop��8����pg9��6O�>�˚�o'���6�,��I9N\����L�0^ �]�|k:�?Z0�+}�
�����tJpO-��Z�A�n�ǝΌw�^.#�)a����]k��*��=B,��)�Hꑖ��뭽M�����k|��\��� ����V'����ki��3�baj�"�J� {��r#x <jn�e�q�������XՀW�=���BN!a�G
�qQu`.A� Ն`#x�_��/ZF :�����ja	cL��i�xl���Xr����]'�Ii�O��?X��"���ͽ \3�X�I�R2��=0C�ЫaeY �}r�g΃�=~��vc�e}}V�V�����|�O:9��E�d�;��-��ظ�4Wo>���E�x�x3nR3��c��Jt��*R�Πo�P]�V�7�\�#��4�>���xRtƐ(��(Ύ���C��B��U�+�~�@�)��r�
�.�jH�UȪ��i�9ا��[<����4<���Y���Z�<$��zt.�VһJ�6h�ӃĽ~���9.�O��������#$sT�ERZ�J�j_�έG����e����C���&�aM�u�+)~M]�$�m*n�T'u�a]�%'t�<:�#�f1�C�Hh�YO�i((����dI����R�Y=q�����>�5��Fe��jX��>�E�'���N��s�簟��8f������'���\�T��j�n"6<{`=Z�H�?˥ل���&7��b$�Jݴv��J9ty{X}m�B�c�:�����E3����1
�Oqu�Zwg�$ ��'��C���A���Ы��Q�K�ǻ���P{5�u�-���m��k�ڭ�@nd�=c�l ��Q���|��醶B�U-n���{�[���jRR鈶wR(jo[:=qM�B �B��H`8�x��m��q'��ľ��n4��s�L��tՓ9�&��.?3,�rN��S���_���ɭ=+	��(ؚ�'�7���x\ԦGh��aj8m�S��<���}S�X�W�t[��l$�"���e���D� jԲ�d�ܗ�9.>�CH��h:V�P�Gyĳx�H�:Y����Z�t��3��JC��:y���3Jz�nPIfƨ}-���ݍp�-ًN8�P��)�Q��ۑP�aQ�{��R(G�uK���G���ӼHl�2��Z��g2�]���e�Vט(j�3J�0<2��(W@@G*��d:/_�o��G��C��     ,���ч ����"�r��g�    YZ