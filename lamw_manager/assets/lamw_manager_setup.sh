#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="771474376"
MD5="b9cb29f5ba94e005bfc7044f4bbc8338"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23716"
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
	echo Date of packaging: Sun Sep 12 17:18:27 -03 2021
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
�7zXZ  �ִF !   �X����\a] �}��1Dd]����P�t�D�G�-@���J�(�kd�a�����)R^M��.���v'뗕��jC�p;U]�~�>�|o8!@�#�/��D��Yd�eO��3��I��[�J�W����΍���Ch��a䞝7Y�3LU��&��%I}3(1N2���0$��V0���ȴJѭ��a'��=ڼLb4H�:��gks��Ѭ���J6�D��!�\�Er"����G�D�/Vo�|��-S�8��JBqt�^��M��#��`�ь��������*6]M�(���m[f�
��k��R{��{�.�.��yu� ~w�.�;-<�DX��᎘z�NsF�
 ����\<�o-)�dfj��;�,���4�����(�I޷�'�8��/y��>�F����%JK�_�0j�Mj��*_���I҂�
�t���J���Π�s9X־k?߹A�4��'W�d=ʙ�#�G [�(�aJ�O@���_#>ϫ}�h/!�u��jE a;���δ*[Vs����1A%��^�I��n����~���;��u�1ɷ��+�n�J�F{�sߥQ�}{~���e���v�\)K�?O�����FaYPn�� {��WS��m�fI�����?"C��7/)��p��n�{##�������M@�W9�����9�3�:x$���<�̾�d7!p1U.}�@��e9��O����^V���~�� ������T�jƺf%��%Ѥ�
�(#�y���}4��������b�3]�=��8����G>�a5�׃"�����Ia�LZv��'�Tk�њ�(Y��⩖5�q���j�ɍ$q�R<�T������@�K(���C?u�׆��5]o���J�^mz�b�����������M������!���9��o���8���ʝ/7���A\�d����f�~�����*��I�mz���[u9ͫ��-{����ek�V�]f���+x��YX�e�<�Q��=!2�.�qđWo�XY�>r"���$�݇.M=�@;����w5�%9����(El6/�z����[վwҰ�x��3���z�R.��{��h�&�8��j?" '܄��T�d+�0��)�'�y'�նRJ3HT������z��P$�` ��ެ�����L$�0"��ʜ�]�t�;A�)M^|� ��㹇JԊ�P����V+��<U�w<Q"���:5�M�n0�^�C�sŗt�SEZ4�H�:b���l���Ҥ���A��Ic��A�>[�=��h?�nw��M�Q��<��2D�UpE/n�'����h+W�s�(��5�?C���85�� ~�zyX�ǋ+���WZ
�n�C0d�J�.o���)���Y����t7(�%�yq�U�b2(�T�56����䏳?p0H��c�l�z�);�`�t�gi�@a�y����1]�A��T�2����\'�#)��͛�>��H���#k�b;1�ǌ�@�	?�7�$�8m��1?>��V�g:N�R�)�����R'1z�M���-fD��	�?m��2�%�t,+��"����K���,%��m3���D�f>��hM��������[�ԟDp`���6,Q!��r��ao�Tqd�l1v�'y�r-��(��B�`���Gc�>��fJ�����)	�\R�1�DK��z8�L��fq�T�e���T?Ϡ��Į�i$~CT��\j���4]H����(�m�HnK��Q�pX����-D\d/g�,]s���fI�� #�SAu���5vp��׏�2�]�;�P�5K$&�Xb�o�L=��,��"��hq2B��4���Y^��zaSЙ�:O��Q����<�=MG���9*������DNy����R�q�Bt�0��`��}$���9H�Y����^p�D��aK�-ﲎ�'���U;���-���5�l:Yu��w�}3��$]?�	�Gq��3��7�.$����8��!u�#y�r�$� �t���������s� ��`��ip��+E���=��G��MC��w?9����RW4�o��F8�7�l�{���.C���f���ך̴aF�@Q�^AzU�,��!���^����Wv��k��vt�h��4��,��]��@Q��ŵX7�(����ء�(�y�7=7{��+8����Q_�Sg�r}8��~�#mi׾͂�����񜿦�C�#E^�[��F�!nh�EH�1-|�mզ����:��K�S�)��	�^{�^��%S�Z�"�{�"�|>d�r�%�E5t"�rSѨ��P�"�+�����%��6R뱭l��L�X��"V�{0��Q�F�ԇ�Ъ��R��0�e�rKIE�)T̅b-�Ό���8�2�Hk|[P�RO����9Gt=E�?��C�A�IE�h��5��_�F����bY'����6���$�Y�����qC�$������ ��|�Wm/��l#��0��\����I��M���ee�d��uփ�^èxU�'mLI4��=��{J�N�|w!cpDV�5\#�̉J�ƶ �U�����dySD��+	z1�N�I�QԖz���zZ	LNYJ߄&`�ňW���:�5�4�}Ii,�F�M[��x,�Ƀ�����5h4o����6/	��I#�\�T=���q�T�������ף�m{aá:���εR1�����7K��jQc.�C����L��-�xy���pI���Vg�6'��V�WQ�r��k,OD��%��IVwA�k��Q0-_�a�I���H识���c�X[��G�L:2h���.��Iאվ6|�C���h�7[��nzm�G/�`�9�w������|%��7��5AZ��m�^�j<Y�����d�,}$����//���M��M�N��>�D�����b=l�z�k?��wWj�2rR�-7�ݐ���gtk�e�O2��ofh�}�l�y�wQ��
�>/�P�� j߈���Mp�W���N.˴��i�Q�Ҁ4��>XY�;J��T�5 -׈���0�k��)=Ŋ�.;f3�#���<o-�4��ݏ ��?�g����K��ϣ��:�����M��6w_J��	�%���S�9�C.��;�F�^�~�,J{d3����2���vXN�=�va^�P�9�p��WV�9w@��L)�k����cZs��>���cFl3x����3B9�{���Q�z�6(5&I�<v�E�zx��xC�ȾG�C�|�����2��Ԁ=�*�:^�/t�x=Xv���L��MEY/���/���R
�8J���!���mzH���L2��`���\��%����%?乜���-�&�Ov"O���	7+Ӄش�j)C�D�b����+[ډ�k1�Vκ�<?Vm�+O.�\�ru�/A(ݝ�ff�'�B��<�{���c���a~��qx
?�_�v*
1�j�x����#�f�������
�PBc�솜���z�db�	�Z��;�b�v���qb<O@1b��r-j")n�M�^�$�l�ۂCk�������DZ/��i6ا��q�<-�BS�~��nUG(��t@��{��j
�Í�)P.�]V��{ˡ���]�Z�Ü���B��rej��4�`�z8����R�dɭ��w��q��-�wz���]P��3v���@��B��(sk��s5[v~���"bY�"j̛���!�;;�퉳�Ғ/��}��i�g�A��A�,�KYJ���g:dU�È�y�1��	������]�
g�R�@��c+���a�; �ñ��g)V4`��v�1Qs�*�����r@zFG~:���,P6�H�!��lbf��pPͅ \�pîՌ�O�h]A�=�A�J�<�����+촮8~"h��q�����yr{�
����M��KsԗW�j[g�ս���-��e�>P;ʃo��Ĺ�c�w�Ց��uԝxC��֒���WIRV�`���3��O�8�.��[�^=�Y�H7�Z�����.�w���<.3�P'i�%�{M�'6�^:񣰉XP�k��L�\>!��إ밪��E�8zD���� 9��Ծ���{�#.7�����)�����-s���a��mJ��\t�ge��x�>�}ii�F���A1��y�ʇ���7�C���� �ǹ���>SI�����o�/������5���t�B�ӫ�(c����psp7Rx��9�<E���@�t:�B6�鿁�����SPո��`�����?��K����"��s!��? ��x]�I'��E��@OW��;T���?�'�հJ(���KH= *��y��CTA�t[>����NYРg
M�e��O��rF��j���hg��/cｃ�}��'|��<�ƲdJ�g�W�*[T(�f'ls�3�b�c���t�a��?��(&� �LR^���p<���5ETV����r�֚^e��簆)J��}��_�C���}���ψ��j]�?m�;��>�8�����.�|Ψ�P'Y:��������xS��ׇ��n(B�i��a�셛�g��Ō��N9^�fď&���3JlY$K���5��b�I�\�/�Y(�+ɰ}�(���e�����/�.|(��7i��,;i��������7�����ԛ�ŋԏ�*��o �m?����PB>U�1v
�����% �~պ6�kgd!6�|�O�hEׂ��rȘ)h=�4i�̈́�':>̢X��tσ�=�����]<yٶY9%�p�M�����䁖��pn�QDr A�};�n���F�=y�B��_�Oӛ�A�J������?�5�ﴨ����5t��J��(���Yɰ0(�H�#����P5��R�H�H�1އ?0��zC��˻�~3W8�ՙe�V���|�E6�v,���������\,g��N(�Z���cf�i�F+�~7'(|��j�|ɏK����� �6&��v�n�Եr����WC��뀌sC�QɈJ/;����g;t�?�aň<�������d?�2R��k9�7�Y�j���淹=�H��5ܿ�xN���h��x��!��`c�~I�4�mX���d#f�(,�]^�W5#� �I�A��E���ɞ?���=L?��(�&R4� B��n��W3�/'`�:��|�|��5�v�����-^�
��9��=���!	��ʍ�۰�������-��CH��&E�$�5t31�Њ�����4cj��ܵKVD6�ʯC_s&L3Sn�bO+��'�,|t�"�٦',�8�����j[Ş=�W28�Z�� q�W�{Z�D�S��\s����Hx2���.(Ձ�Rb�馛���28�۞P�N2�SMրN����V绔���`����q��c��J��;R���HX�{����H8rh�����P�4�:��z<�;���O'Q��KJ�� $ٸ����խn{s6j�ӝQ�B
T�c)�����,��b������w2��v��o5�Ŭ��jG�$��|�����AbA%]V��P.��=^d$���������#.ؿN�h/'J��:˗9C�����V�
Cd�̪�~@u�i,��;���I-j��Vc�;`�SP2:��8��_�o�f�fzx9�����\ո��{fA�*Rum����W����ݘS���ȇ1p�N�Z>g��#s��٢�SP���^e[.�ƚ���=E������BT�m;�� O�Ej$��uω�W}U�1�?��I[.h}�)�LL+��J�'���B���L_�k�h�
��~c�4����
vPka�h�
@u<uH�|�8v�=CV�����������6������k����i�T����L���U�q 9Ծ�k?��YP\3kk&'���0ϭz��	����`#���3����nv7�]3��=R��]�e�D:_����%y{10��,@���:�FA�q4���Me�ؑ�^�R2�#*����o���6Ud�qC#GЗynL��r�Z ��^w�b8���	j&ZM*��X�)	���[5�v}⤄Fn�7�_�n�䬎//�pH�֤�48��:B�[�����L��F�	ٌ]���e�,���R���o� (e�����v�4�9���ft����b��ݓ�|W{&3����u.����#�Ь��`�1r������F����=�x T:ߙR'���ކ2_�ܮ�󩝗?0���@H/4O�|�p��U�'��*O�k̃�:�b-]��X�8c�-��
~������&���D���t*�����{�������E�,i�M�NG�-8Ćtg�8ZCcl?���-Mź`)Z�,��}�G���K>����Ճy���\7�A���8���<a�&,Y���P�3��Ǘ�@{|���_�|�٦c���XRޏ-熷mBr��3����H��*����F8�&��?�=�]�	�<�A,|����5+6.ǝ���bʛR������{��b�{�_��L-��P�]�����!�/��ѕ�j�2��MڹY�ő���p�Z	��#g��q�~@�֣A��`i��DӹQҟVP	H�Դ�ř�`���h8+'E��v�fw���t�
BS���ZfD���������ƅ[�K!\��j�D��(��t�K�5�*�>/&^�ڮ�� �����7~;�*�3�)�u��+��mCĘ����@�o[B�ۈ�<v��l~Y-�/��Үuʞw�I��6��N�;-�!ɜ^�� ~��-1�o� 
�}�_��������0��39�qZ�X�~�6���ڨa@6�3T<��}� 5�m���F�`�a�	�V]�������v:\Ch҂u�K|���}��M����A�xP6��Zm���㵀Pv �ߩDu;9�B��Rи_��*�Y�.R=E��Iy_)u�8���nRW)����q�ʂ�&ߏzEN(��N�jz����1Z��4b��p�n��{I����-��G�V�N�:UH)T���b�wT�Y��6��$�����>�Z9j��B��
�r�ϑ]٧�����v��v���N�σk�}��HsFV�U��]�m�/�*4��p�⏱�ٻ�����<p���kT1xby��㮙�2/�^]��
��A�)ʖ[}�[c)@ꥅI�[���
�|��x�&8�;��]"x�w�Q�S�l��K!�n�W\��.�s�_��vV\�7����վq��:��!� �ʯ�Cu��u9�����ϒ�I�rN�}�^s[�`*�6mqT�񆘰�Ds���.6�-��B�͍B��N������ۚ�����cYa��b������&��\��x�@!��T����$>f���V���>7t)�{1��4�Ӵ��ELwىr|�P��[k��2���sQ�����8S._�C�J��ۺ���:u��C��F�aX:�����.���x>�~$g���GAY�̀�	�FmUZ�Z�ϳ|�"��U𚽘�����j=m��V�tred��2�ӛ��}�L)�#&���C�?3��յS�M&�9do癈<���.�@��|�p��7r��G̳(�tn�Q�#��#k�Z�l��N���h5x43�`Ӵ�|��<��Ya�qfѕ�mz��J�8bХ��oL���1�?/̲=�:��EKp�<� �g0dS���>y~j��~.���)��ގգ��mWn����7�V�!�A��Gځ7�D�-��1��6�.��s�g
g���z�}A��¼(�I�j�� v�������[R���ݣ��ls��dx���G�h��B�t�7�Gs�G���,�K�b���W��"�Y�����X\�х���g�PW��F��ݰ� eLK��C���b�e��׭��4�a��9D[�dv�ƀ�)[�r=�0#�PJ�#~�I��jv8���>���F��_/ܮ�0^`m<�9,�S���M���'Xζr%�DG��Icv��r�q����0�zX����c�8I3/�A�c�Y?�_ ���c�7p�z��*�DB�0z�I���h	w��)W�K��~%��t,2�M]@�e�������lw��$��([m^;��d6�x�DBʻ�{B�����E���I�Ew�ǀɶ��7��B0o(�s\�~������?�~f(�����
�߰'K�2���ޢj�-���;�L�l�̥Pa��/�+��1�lbA�l4���������L->��������`a-��n����ǡ(�X��ߴ�W[x���h���&9�:�h�X���������51V�����ꠗ8"��f;q�/�,~EL�nn�w�_����%"�ګ,%�D�#�z�_������ ��6�w� �ժw�E�������_@VE�J=G�v�yۥ��9=ą�M5�y�	�3��P�!��p�#i-�QO[�ɦǍr���D�p?[�bh�s�. 8�+m�E����K���~������5�3�6��D�l{)�lN��s��V���P��Z��}��Rb�w�u��%���'AeU̞	>z��M�>o��(-Pk�#��0����]6�X�t�����}�+����t�>�CѽDΧ��m����DW6@z�%<��z@�p��9�����`��Fz�d�<��Bi��p���!z@T3a���7D6?~�a��Ǧ �E�aB��Lt�X�y?�A	/:Ҩ�V	�CT��F����Eݐx?Q��!7�`Ŵ��N�T{��� /�]*aK��A��qu�[��ގ=P(��;�UQP9�j��ȃxK 0�1��L�O�b�;"/�{%�ȣ�:�:If���6�z;(���{1h��(#{�Cgf��Dֹ<ڈ`����Ah�n�'�����C�ǫ����q�S�4��bc����
��t�#)E�+���B(W����_��D��啚_?���u	�";�����A�#n'�R��L%^�t=�:#�����z�rW�R����j����:k�S����DS�̦��S�n�-X�1<E���B=�Z��@���	#������3y*=�)a�֮�g�v�.Λ1��(�\mTߊw�_n�6�-�Dnk��e����ai�>��Q�75����s�TłJ��;C�G�1H�����mW��W`��x���R�[F��w2�aX�
�_AX�f����u�����iW�!�v�3�~,�iF=C�e�W� dx��.�FAͪr������u+){���,�T�����)�'`�>\��J�ok�熜J�5ܨ�(�F���$���X25��|y������X�#�}94���$|�8����$x�S�cl,r�\�^�C3��^�j���3*�i{�������D'����Y���{���\VL�������"9y��e���w���i���5���~�@�\�V����Z^~�=kA�n��D��Fug��xQ�^�Nx;�_tc:Q��_��J��ٰ���zj����}͵?y@ν�,r�^F��y�a�}"��*�԰���������B���I��҆&uO�\z\�E��_�o}!¼�҂�8����i�@�<���ŋ������ԓ�i�u�Hy�K�Q'�JN�'6h�!&J�U���V˩�9?�W�K�/x�['>kw)�I��\<w���G0<7��Rn�6�Q���_�P۴{މ�p������O�7��!�^>�&
J���qT(��8S�ݕ��F�p�.�¬�E��4��P�{1���%�&6)����柰w�{�}_�7�^��U���*�����T"�s����u�+u�Q��a�ގ�6�g���"�&�7x��R0K��� �2�-�3���KU.�1[j�O�@���6�	�駓N$����}>�SI��,��6!K2,��������4�����S&S[�th5�>m x��A"m�b���@�rw�V�-����fK��ݢ�m��ї5G�7�G����zk�
�X�E���L%��X��1�UQvtN|72���ǖ$�|� ���Y�h|�����Vm��;h���Q��c�{V����9P1r��7�/*���to��= � �)o,�ܝչܩI�n~�ʋY�0�#�B��2e=%�ྲ�i���s�Ӑ�Q�K�D��z���u�#xJ�p���o�?P�)���#i�K7������E"4I����$?�(Q�q�^��b�����EP���eC�f�d��*�+eY������E��!�J�t�>����< �a��8Φ�zڏv�X�zS3���J�R�z��o��V��(����Q�>�G�0�W!)�t���Tm��$7��s��֎��w��O�8,����x�yYC�������	�X1����5�����?"wq<j�-s��j98�M^�h~���r�GH��hA_y��Ӻ��*�Rk�G��3���	��0La�'�o��QĖ�fjhMM�T��;g��E!J0]@(�-}�?,z�+\�LXE��&%�6 H^b���_��d��"9(t�N��3����"�u`^�?��cB#m�3a�*ί����Fb�4Q�-�G$m���H�Җ5[�2��]e� �@Np�yx鵫��E���>oǦVZ��s`Wy���#�1�~�s�<�3�NVulU���^�^�L~�/����� ��Q"�p�OA��~g�g�!^k�*Ã������������Sw^� #']S�Ԧjγ��w�T=Pu��[��au¸3����x����+�ۅ�7_S�e�@�FQ�\F���z,�yُZ�Pu���<(�D�E��\�� <��x��>����,��ڤ��Sܘ+g�o�q�<0�e~� ��*�c��N����B,�Jn?���*̓�Fq/MQl�FX�q����`r�d�61V'=V幣E7�C�`��4yX`��G�	�'��������>+E�8WD�؀7���ڳK�4��u��,ؓ�~�����w�]���j'���~Μ�w�(��)�����'���J�VY@�#���g���� �W��)�H 5����L�s3��������\KEe�	($wu=Rnx-�3�1(H�;NE�g���Z~!ȉՐ>�![嫒�˨|R�.�|�=O�,[�!w*��UB�T��#�2@V���g���i���_�'���x�燺�+���f��"�A5m��n��������u��G^z�i �;{�C�Մ���hN7Q�Kxa�lΩ�pl����@�̿yi��}���jc��Ҭ�R�@2�Q+I�[�Y�>���]e���~�Z��XJ�\�V�&9�(`�*n8��[i��r�F	�fˉ40R֭^C
���Q��bF�jg��n
�9e�gC݌l��f
�l��U�-�t߰��Ow�Ζ��-fZ&��b�z��[� H>lU|��{��(��e�s�#y��V_�?|8zg�4	W��C���&m��۔v���;?��B�iR(qV�Í�G�;��al񺛤�y4�q��O�wX�sl�4�鑧�_�6f1^��y
0�hTa����Ԑ^b~S� ��Q�Xm|$m*f}$2���7�>|Ԓ+�\���I@�==��]�	�h�o��ḁGt
��_���5~ri57�(��#M�nۇΜ�1�8<b�����%20���r��;��RXֆ����ϰ� {`�E�\p�FT�=�t�w؁k�5�{e�����:rS�IjP�"ːYi(:����;Ӕi��(]��~��K�Zz��� �S��5}NO%-��|B'��	5�H���M0�'�*�i�P��Z����u�4�MpV�Ń���i������m��ME^ߙ@���(c ��f��!�/�m�����@�T,���g�7�s�_MN咠j��yU�����%w���d�������T�V4*�s{C�1F���S��cӛ�"?�T�q������>����C���!Uσ;����4�>}/_�Џ�96b�p��q��Y��Ƃ�����D�I�r8�{l~���r��r�8j�{_�$p�T ����>ZG:��%�vd���P�΢����-0�fqPRwի�r# Lg�=��_7���6׌�?�>@F�	ZL��G��.#��]�Z�6h��dN�KT|S`�y�x�LI�i���Jx�\�����A ~<��L��;
#�>�74�Y�v+��i �B�k(��g_̎j;����5�@�G����^�_ju#c��|�5_|�r�-!Cg�|n�P�ܢZ� �a���:r��uG�A��Tr�{Z�HF�^��	�W��� o������O�h�q����E���I�/.O�7�DV�u�0�B��F�xOX�8�P��m���������s��9ԛS����#Mʅ��)��ju��&�|������C�7P� ԏ��.F���\L^a9�(���$ ����%Չ���=��W��o$�1�6�a�%p$�(��o��Vh<a��M	*}F;����MoC��J����4���/![�t�*_eɽ6guD������̨�e��n/	�M!gyX��x5fc�$�_6�����XzS�H b��Ũ9��q��ȯV�g�e��4�I��))T����k�W�xy뀻s��W��	�D 5���R�-m��$�g��8�-v�\rKZ�B=�i�ْ*�N��w�a��|��8���U�H��S�n��'�fP{������0�'a��!��6�
J�2�1@V�*`�D�����I�7�!pւ!�Ǿ��2~ŧC��*���O\LN=�R/9��3�����KᡤL��J�  _����2&%�a p��z�?Z�)��9�e�o��3��V\Cl���Z��0�G���!�n�q�u�\t �V+���D�_L�cЮ�")]_��I���*�/��ǫ�oZ�y�\���',�H,�2o�"SW���6�-��;u��4���+�#�'�&��!�ő���]������0�m"�P2�Q�����"Y����f�ǅ������8�9".�B(V�ktJ�G��$)��Sۍ&��{��3�#��PͼI��� �;��? �Y����(q	0���>���%��/�nGf��b��?	-dZIB�ir1\@��?iTiROͤ������P9�i,��]��3�� ��΄�:�	3U�����'n5���^����P{B(�8�}ܓ��d}x�x���@}&�<x̙�O�ґ��Nb�:lh!����i�.����'��x_+�n���?UZ�c�%T��d�M��R��j�u۞j�*z����(���;����V�=?�T�g%�$۝ȴ�#�GV4ҥ��K����%z!����uP���s.w��xԼ�͘�uY��-�!ۛXOi�����I�ۼ]aS�z�ܕ�$>�S��Ou�ۄ��\��t��O����><ap�abtF�W���wh�6e!�= ����o��ެb��V
/I8�x�y!gR�I�eoϞ�ˮ!�[�����/Uq�#�m�	Mk"�~����x��*�t�A�����WbQ�����h�DO�x�#q�G�EC�H��T����w����O��n�٠E�鷏�&Q����-���LA�UvT�U4}1P0e4k����3�iͷZGy�5����$#$k.o!@�1��Ciz�eN�)����^r}E|�K�#&�w���[]-�v����'/��&�vC�@W�r����*��
�@*+��H���:��T(!���5��C�`Ζ�jZ5!��pL�\M%"��`Q�9���ĴG����x��"�����#�Y�˰�U��T)�ܝT�M,_��,�|ɸ�m������8'�x	�pq/i�b���P����C2�6��WBl5K6&���Vç�� ��@�Q�����r��jiռ�-�4����o��)/Zhu?2�G=Vz�΋�Cii]�l�|F�N��{񢗑s�
�}����1il�>��E,�ƊO�O�%ݱ9X��$r\�K-6zE&[�8�Ho�Ɏ��k �$��K#4���YM�A��'�&;Ze*���؝q(�)��X�6����t^�U��Xj5)���d��/��bjH8
���gbr��rT������{��'B���Bt���T� J�����o�S�i C���#���Q�)5
6��"�S� �k�Z1f�D㎮��:q"��?6�DŲ�u 0*:�p��5�Df(�?E�'<��l��Ll�Ak`!���:3��B�'�n�:�_���*_��5�>I����h�ytY��I)iQ3�'U<�.f��"Y�f��[��1~�Ps�m0���r��|�>��=R��u#g�"�L��I<�\5o��
�_����z^��s��.��'��cZu�a@09�U�'���v~m�~ё�*��MV��J6����_�r�릴�⡞����~�̜	����l���M��j&!�B/�
�5��h���j	4��O�]PE�_�q�Q�)�U�U<QM:�Q"�.<+�jsh�,%��Ӣt�C���	FZm�kifoY���K���B�[,�c�G�\��XyXƣi��`:aeLA:�O�Tcd\�!nh��;ǿo\�r5Ev���P�1M(�
%�5Ż�sc��D^V\�������_&�j���SQ� 0U�RQ"8��Y�e����Cd�w��k�Ve�i���#$	�:��ܞ��KZ���.:�\�d��A/ �ϲt����\\�/�O�daG��y��� ����Gf���b�_=�_h�tJu�O �v
�|��a1�3܆�����7M����S�ķkg�ԫ�?�"mpF�/
��3�}�E���!��/��h�� ?�#�]�f"=�p;�d�S엇t�_�(�����$�a���2?v4P�:D|�F�2΄=��R��*{�o^lCB�>:68<a����7^�-
�󷣗��=��??���&��&�%Ե���b2��0u\�~O�.�+d�h��7z��O��9������C��#{�\��(�#6^�x@��46 t^�~��;'sO���p�#X�tߏ�?����_��*��9�.���}>�AD_��\@פ�W2�9�˅���h� �:�4mI�!0G���GM��@m�VS:�no�����ֵ�d�c̡�7oYW�L���qMP��;0����	k���Ǽ�Gq���,��%�Z���Wj�����68�o���i�=��>��G�� �xG��:��b�7�4�K��
zs���q�o������tգn��v��x�Y��E��%��`�m<KB����
0V��	)�=o�C),�	K@n����-_�a��ʅY����t��I�Y�Z.N���f>d��")b�xK�T:f�Kô���F�"�z�k18�=�=j�݂�o�E��E���U��A���#g8�C�W��Օt�O:5�s�H|�	�~�I�y�K�i�'�z��T�S�|�������T��]���ܴY��,ҪW�N�p8��`y��H��
�аf@S��j-�
f>��Jʇ�A�B]	H�o�Z��;�X�s�3é�X
��]�6���LN��n����k0C��2���dt�,n�@�9龪�]�0��H%j��ͨsƩEI�ʏs�L	d)����
ҁ�pL1���IȀ��n�M�0�Xq)f�T6m�-j������!=c�OFy@� �'�֎�?|'Q��&_�o�f1�sRJ�Q5�ҷ�����;��X��莾±�fq}CϔHůÂ��7�.�k��cw������d�����*=�z��-�$7��:#?Ϛ�TL0��q.�Ş����&�x�f�o᫼����b��/�;:Uw���㡡g;OYoʘF�=��ge؟u�}4�!(*Z����ր^��-6�#��}�^�ܙ8l����c���<>Έ1.Zd��1��x�K��A5��y�����v!j�/�O-����sɼR�)>㾒cE$��HB�`%�LrP�L�X� #��n��a%J�U3�6���)<Оl=[����|���A ^�s߀�F�w��S�$�&fpl}ò��O0��.(b��f/I���un��=3*�d'�b����x�}�����txܕ(�b!��.°����+~疟�<�M[H����Q�c9��<p{�����R~��C�Ϲ.��M�;��<ʭ�H@��3�`����\��:��p!䥛lm�H��I�&N���Ĕ�)�DP_�!�Q���%��%�Ÿ��处x�pN��9�����0�ֱ(@8�p�&�H]��P=,!. �&��O%��ܚd6R����\��S5 $�'q|}�PK�
��ފ���V�"3��4���NJh���&�X߯f�� m�	d:��b
�_*S�?c�]���v������}'M�׌fM� L�Ap=���m��`�q9),�:�=(j�x������Mf&�{��x�^���F�Bp@�q�6�֊v�. �D�(�������y�/��[�� �>�v9�&7�o�X
�G{��/J �EL�0�����vE1��1�}otC�����|>F/B���!��6S��ĭ-G4L[1�]C�e2�.�Єoܞ�}��W�[�f�U�߂y��:��.�(��[�����B�����^���z�lx��yNLOoy[u��Iq�g	B،�6�Dڪ��0�Y]e���@��^0��@H	� �z��p�lL���\7�I]�~�ŇI}�А����R�g�,R�����?Qg?��7��Y�>�k'=�����e`N�8濒-j�]�.���m����i+P	�H�����f�۹)��R�[IH�p�Y��
� ��e�/V^���"c��ͤ����K��LB;��z�[jB�	�k�&�!�������x!g�q�u�P5�:`���w6&�����\E���q���X)��?I�������/�u�۞Gj���r<jr�u�qH����H>���1���w3����å��6���H�F�}�
�&���� �i:�O�T�Ѓ�"-�&�0�gq9�2�N\�˚u�4gr������wl8���0�-�*!^Ĳ��Vt���Y�5zwf��n��S;�-�@ѦyR��"��Np����7��\m��$��.K�S(_'�
���gR���۲ Ze��c_@{�-�!��}ghL$JvM����<rڽ��-�_ϠS��=�/C2��;������ *�k�G��J�ϋ�+ƌ�G�o��J�
�\)��GU;�1%a�l,�l�o�У���Jߚx�O����̙z�q(7��7���a�s.̹������� 't��F\�L��r&���	i�s X�"z�E��$t5��>B�ݮ�ފ�\ePS���F�>e�L�F����|-��p�B��3
G?e g�?����1�o�d�'3a��<P^g�6��֛��<���i@�^�J��eZP}�;���X�(h�e��GOI��t���J�vU�i$/µ�K���L�]	�`�51�E����U'��WN�<�w-�u�JI0�7e�Or]���/0�c]XN���OݐC���b��ǎv�ه��S~�b$��a�� �y�K�Jإ�}�o~[�������a{P�у�7�{n?BE��܅[x����9N�T�WU_�m+K'�Z2MM��f8�_.��6�/�U��Jp�wX=��������{h�7��R����WO@A4W�î��7}aBPn�m�|U-'�����ƍ���
B(<�����X|;'��֑]�^.�$V���C�a&2��pA���L��>SC�y�E��ъ�cn��S'�����(�If)����)�����S��۔��@e�l����%��D�1��t�c���� b�CAQf�N��0�$�I���Jෲ�8ڣ�-��w��ZV�)$��f�'r�����
���uP]k�X0@ܱL���~�Z�����Z�r+4ᇕȍl�)f��6Р�Vy���쾷��>G|���O�i�Rxf��m�\><�~����)+��p��3������L������E�ۛ�Kq0�G�����=_�DY�fǐR\��t�13�\�!��a8�-E�(�D���2})��6h�%�倉n��|T0D�!�Ð�l��У3�����?�ш���h�g����-�[)�s�	�]� �(g�2�6�������)��
}o#�4f��`�P�eZ+��>:�(�
����>
�'4�~D�>�g�����@�� p,��J�����i7��
~ �I�^7� �����LPz<u�]|Qb��Q��;e���7]��`�	�!\#�5s��5^��[�J�]����W,�%��	0`�/� I�Do��rN�8w��:h�j��¹�>��S<#�@5������f�N�SL�ٱN�4��MH\�m�;LQ&���xG��p�+ ��:�`�*�`��;�o�f�,%n�q�rQ$���'�q-�Ȟ��Ln�q�.�Tѭ�zE<k/Pj��L��6T�4��<=�T��;��T�Ap����u�%���{'�k�����Y^"�W�,4u��@�6�l1C[ܻ��� ���3�y��;��Ӻ�0-p�<���(~=�r�f /c���VV�y�l�br�of.A�h�Ve��E���{��l�##��)s�2���&]�o0z�mb��������x4f�I���YV� QI�W��$��qe~�pY�5ȭ��Zt���V���>��D��~��A�ݦ����H�0߈�&'LhUY:��������J��E�_�F�����;�&ݷ��eM�g�\��1�wy����7{�`\��������c���ş����=�]
��k�З:��<��i��
�Me����l[��n�S���R�)�n�x�5��'��g ���b�:<�2n���b�vգ��W]J�A�����H�=�zW홽�{����ٸ9:ԮbHH��p�xzڼar��D4)��5�/��DHTPHċ��A_Y=o�Qr�@���a�D��~G�f�X�ȗ|ÒCd��n�A���c���R��C�e�k<�R�F.-��VT�L�u'n��6:	������B�J��v�^)�[�CC��fF�(����a���8R:^��lأ��YQ��o�np��{�Ex�T	�.��N-$��P�)�ά���dڎo+�l�OԂY��ef[�.4{��7y�B�;���i^\Ag�b��.�����H�CЉ�輳��p\�'>4�� �l�����~Ƴ������Bg�ʡ�H0�5k'kxI�v���;e5*��k<��������@������4�z��E�s��»���F]I����s����x��sbWk���)��aP[��y�N���o�^� #��Fz#<5���6>]G�̀w���CK��t-���h�[}�O<�:������_Y���:Ø(��e�*���U�Z�ěm�2/����68{"R�O�8-}�ſO�En2�I�X¡���V�\��F��Psb��qS����^��V�~i�FPW��c˃�nͦ1]�]fQ���K�~?h��'R�&Ek�!@�]ɭkI��]7���-=C�~:�c|��Eg��E�(���%�p��L\���FE���"��oILk�M+>ڣI6����T�(E�.O�pi4o�¯��˾�*`F$�ծ��ؾ�ھ��qw�x:�̮���C ;��%��!e4n/�Aɒ���	�� �]6İ�o>��<P��g}�Q�%�����GAG'j���at�$cHߊ�.6���v�ӄB�-ɴ~V/vW a�����Ѭ~�_�xC���S\�]�䏦bƸ���s����X�؃�6�\�;�B{x�"�|]�φb����+
X�z�7u`z���丈�p�v��5�w�΋�ML�����)�˂a7�m�Q`����-
�Ϲ���q8�b�	���e�
���ng���4�����Y�,�����<D�ý���2��?���*�O�����)c����y�m��'��� �6�Y��(��x�y��$�����P�o���i�;o���LՕ��Uh��b�$-r���Ds=�66cӪQ�jų��@�6+vt3��Y�������ģDMv��U
a�%�ۋ'3K�2m%���˥0kil5g;A�w/�yvQH27���4���(Zb�vo��p?N*�,ۂ^�0���(��o�f�<�]�Q�~���k���\mN�c"�����p�DjNʨ_V"嚍�<�����WԮ��A�	�
l~�%�
���Ե���f�d�Qs�)s!��⌍�	��%�Gq¬1�J ���2L�;"�B�R54ǘ%�; ����t�v,#�
R�rZ��e�Qi�e���N���~߈x
�
v���)!���|����]�5ƞH��E&���<"�'o��)_|�}/ϖ l�$�
�A���������Io���q_s�:�0�x��M��!+j
I8@��lM�WD'!�g�&@�c�9�*�,�Y��m�G�I���ӌX)���z�5s�m�x�9��|�iw�U��7�u�29JC_2ާ��'��{�������G5�0�_947~�U��)��+�\̻��^�J ���l������D"P
�=���)�p���D�����+B0�-}+��M�i�-�@$�r^7;�]_{%ZS�Z̻A���|s���;݇�da��lG�"�����##0h�e���f�U[$��������U�P.��F�fZ��m"4W�ž��{��{WPYY7�����D��&��=��bL���T_�ns����+������r e/dUcl*�B�� �{�񼕹�kv�i��Z�<"�6	��b@.h�� g�X|@2�^v	B�I>�
)���F�Ħ�������8`x��4%�=&!���� ��	�Fsz��=�&��ED&]�7��H
`?�A��m��׸Խ�Aڳ	��]	7j|I*p����̲CS0Ą�P�5�'�E*�� }�L�m �?̭/�^]�������0a�h����V��0>�R�?�BꝢ:{ɇ�UQ�����0�N�_罕����4D񟲆�����<cNӨ�`)u�i���sD����=�
��L8X�K6�*ȅ�J�⨒<�Ĳz	�H|o�EԿr_0�a�\:�XmvH*T���Ϝ�xm|��Z]R	�AF4����� ���9zr�5B��MH�%L�􈁴��]��� �I��I�) k���cxD��{L$*,[O�
v��� T�e�]j��=��5Q� �R�xٮJ	�H�`Ip���)��Z�Q���(9>ݳ��@���WBd�L\ݱ�a�!hn����'��{wU�u�$^H�S������yE�����T�\~��i6�(��O����ڧ%xnƘ����y��2zV��B�+���ϩLq@X6���-�:�)즠|��������b��8�VA����{y�<��t��5E��P��U�\�uΤG1Dy"P��c<쩆)��~czr�['
��b�hħ����l�������1��MhI6��|~J)��Ș���q��Mt6�����|��7x�1�pխxU�i�?���@���c��GU?���atܨ��y)*�E�/ļE,��6uޘ�/�{�1�<�y^�ݐh����*�q�F
*gOQ�9��t���B�� -�D��>z_��2��q9��s$�U�!�u0�)��e{���!L&�b0�0Q��p*�n�� ~N��4
�$�F9M[7���͍�� �c��snU���GF�O&��IR�{ȴ1��g�7����R��Ȓ_�B+{��'��o��WAҚcѻb'�����׬sN9�C�7��QB��)q�Lڍ<d��I���I��ZI���3�d*xn0�pm��R��q�.]�K��"	֗#`���ߗ���0f��r���Wx�)2���};z����!�t'd�^V{�V�`���\5?p�6Ѝ6f��KA~}X�W�<�C�\�7zI*^&���X�m��JS�Dj�?9%2^�0��۶�δ.������b�l��|g16�\U����E5��s�/`P�� ��E8�j[&��Y���Wh��%w��Z�(��9�[_�켣�Hdϐ]�g�ģ��7C�;/�L�恱
��u^%1�ZER�v�}k�H����Li�PL��d��ɗ�%sS��}�Ih^��}�Om#/�:��/e�۴�P��?����e7��܇g�P5\�
�xa.���3��iJ���"���kM���G�(uߙ�����P���X���j�
h`b��Z֘@�����+.y�����;h��u���[Q���^���wi�� u�o��7�M��E>ʾ���`nt-2�z�*��9��v&,j܋G^4��#�����yݞ^��O���#b�������X��p�T"W���2��S5���j��3�$��=�����k_H�C}� ��
�^�PQ�ɵg'�u8Pi�~�#tm@S|>�b��Q#:��C1�(I=e�Z˼�M+r:����C�d�(������x0��p��O�C�,Q&��I9�s���j�}=eƳ����i4T�O; �f��Q�¸En���/�+K�m�6�T�U��\$�]� �y3�`����b,�%.�gn�=������E���h�!%��F�R*(���EQ���F̧���a�*^0�d��|��x�?����r�XG �L�)�Q���-'��TU��b+S�^^���ۀE���0Z"���R{�nI:���f~[v��O�4X��f�鍿��D��)2��B�Rr��������l�jY<S����&|9�������H���h���>�q��ļ?� �]ٲ!U����RdM��� @K=~w�2Ym4B����F��0V�+*g�p��+G��g9�6���#���j���C���9y��?�N�Sa�'�YNZ\�Pg{���H�.�Y�K�2(@���EF+>s���h��K��Y�ܓ�q�����DU4B�7�(�C�Ӕ�\��e�6t˙��Az�z��� 6��� 7&�>���w��O$�M���_J�x,���M媧�����;.'��nV�qd�W��YR.P�Q���*ۙR�KҊ��Bz�TS�5�(a�#g6�8��l��e�J!�*�פ�L�U��5	CgG)��:�U���3�d@]�ؗ�.�Y�{DPm+�[G��=)�6�����yɯ�;�p昉\ls���՟nTSf��]�nj#V��2��U�~��x*��p�m��>
�=�%�}�Lm#=e��1b�8�7�F��!҆�M�aks�|B��.I���^z��9і?洁L���%<Ó�p�$s����� ����HPa\�e��]cd�H��o9�[�.O�h���X�|�5ؐ��
�*��2_c[�v�hY�f�.Y����     ����
�9 ����ǣ�F��g�    YZ