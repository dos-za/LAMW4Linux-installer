#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3723809534"
MD5="d438ffbe49f6b11b2a93880074b032dd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21409"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Wed Nov 27 23:36:42 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� �2�]�<�v�6��+>J�'qZ���8�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ��'O���IC�N>�[Ov��l57�n>h4�[[ȓ_���y`��{u�]��G?u�1��s�K�{k�Ia�7w6�H����O�}b���dgJU�ܟ�R=u�%�m�%3j��t�<6C�cy�r&��`C���(`t��6u�����A�R}��<w�4�[�-��#vI��7�蛍��B�4���Fg������f�7��x3B��(�>j���9P��� L��&�Lߧ�yQq�!�vA��:;S�'z�{@�~����H[�á���I.f||8wO���ё�B�����:����;�����N;��s2�ƣ޸�;ʚ�0��Yk��PQ�R5F�C V����:���w��*���!�[��j_�ע�w{�s�R)'����k j�u׹�osv��Qf���ŵ���R�\ �[3�����[��;�o���e
4���?��m\���J����O=w�BV�`�dVu����� ���@�=�,�,�b��p�SF�.B;P�T�fHtN�y�E>�+�������D��Rw#ǉ����|c�F����ʪ�5�����}��sƧu�E?H@g�4�*���۵��&����B�PZ�Z��STNP:M3k�:W��/]O��7�
�`1	=�2��`�l�VO(o���＃ *d>MQ�4|��>���d
8�43M���a-�M�K5�m�y���v=��̌�pC�V�üS���O-Q���T�d���i�}ϱA^ء�������K:%�]�����ը�?�����yo�A[��|:}�����lE�ra��P�v��K;$�z]��i�~���ȝ�B���q�|�����p�\��J%��D25)+qS,���J���1&va�nJ��O��.C=x^Xp�J%��X`�X��}uj��y�<�U���dvFA�	Wd�"�@X '�÷�&m,y���>�/��!�U/����lo���67�����;O���_��ܻ@�1��I�J�Iz>x>��y�&+��TF��G>�{n�0v1]�W���� ��8/����_L�� ��3r�������]���f���g���*=��A��C����qk�ň�W��tO�}2��GI0ҋ�¼�6/�E!�96�����M2I�}��,{fCN���&�8����j~�Q��c�#�D�R���>�41ڢ���1,d0�ܹ.�sʨ3#f0��xFf�� 
�����D�t�K���g����۞�e�
JV?�����[�"V�,��M����L��xef6g:�x�C�3u�V#8������,����q`��*I��K�f��fs�k��K����$��uv������������Z����S��ZW�/
�=� rA��sCRA4�����S�<� �(�~�
Z���S��Vk�~�����k�m}!ǮT-�ihB��;��<byd�O�4δL�z��&Xo4�,�����6�6��Js1���� ��ƺsE�8���f�x0j��J��XD�.7�<̰����ya��z:��0"���c L+�X���bq��2^v���Îl7�$�C���I�9URr�[�F���s:8�B5���ҭ�
�D1N��ؤ�М3=���qc�P%L�e|�}6�F�U�X�;�r���>8L��� �q���ټ�r�9괆C�u◝���;1�%ދ,�&�T3�#��?�K��Z���K�^�NO@�e\��3MsPP����+-�W�8���f���Vz<����pn
�ʰ`�.����}O�I`����?A�0(�蒧�>'�^L>�ӱ���B��Fr�x���_�q��n_��������\��u�������J��_��t^w��\���3���TE��mĕr��������I9�"G�uS�o��-���E�^��7=O����*仴BB�OϕU8<A�#p�8�hpz򂤆|���؟c-�m���&��l�
W�^i�����&�:>�������G��Gݓ�����vfBt
�cH��y��d�:��Ʊdƛ��Wu����7�du� �N�����BoJ���F,ץ� �"�⠧�u+My�3�P[]{�xH�����Q ��
�ŋ�	�PLx��<æ6�9�`!Ny�LwN�s�����"%��uW*X� S���}�N��d�#�-�v�t<j;#���U���9RIo��������P �}�z��E����A��J��:���LEp�ʗ3�+�2�[R�dw$q���QIËX3D���� ��o���D�����{�����#��ӹ���� X��罛p�Nx�.9 �L�MV���Iop�:�Q��Z6\�U*Yb���i�T�U-�ij�].gk�*��2���g���up9�Z=�hD���.�����v�>�ǐ�l�������_"�y�x~�"�e��&Pk�g�C��&%�x����`)�X��Ɍ�m>�KՏ�>$����E�HN�\мܾ��m�?l�cH6d��a�0�-�y^8��ʖ\�dx���GB*q{[j�����=4����A��?��p�A�)�x��fKT_�5<qv	5�K��BN΃��!)}9oKb
��呄X�]�,W*C�b�7���
���9h������"I�mע���K��5��x߻��^k.�L8����o_��׌��	�4j�����2�����������������,�j��0���/I/�k�yc��߳<���\fO�k�!��.6��1�:qY	����_��%���m<s�hJ5�d���%]R���A�7
�z�1�gN��k�K���9`&���>��N����x�QD-�$ʼ���0d���:(=���p�m�G9�g� !����Ǖ�!*���;��	b��z�]rn���������Q��0ԈM��Ik4\��K�Z^p�?����?C�qo�c����x8�N���;��o݇��B6JE1>�;�A��g�O�ZLi�7!�K����$�e�(��*���M3�Kd/=��T�?�C�{�3&Y	Jn�J���ɕ9��W߈f�r�7�3c}�R��Q��IE�X${�X��U�t5�0������&��=���X#T��ES��$�q�"�^[���q=2�MjNl-�>pj���u�����Z0=��j����u�&0&�I��o˩3�7č�ܡ�9�C����]�Q��F(�E��2�e�J�v��,���#0A���X�i��G�?aL:�.��u���E���Q$�-$U�,�!F$9��Ra\7�l��.^d.���L�7�w<�J�O��nԙ��&�`��̎(��+46��PcA��{3�cK<� �p-$�q�jJB�JT�:���XW�[���c��<t~܄���%>6,ZnJ��"/6�ŽFH��3&5P^�ſ���Ak��#���=~u]�y!�$��3�t�q'�w$R�	����� ^@���n�5����.%~���t���^�zū+���'o����4j�x��	Y�y47���8�vG&��������߷��F�I��e4��&�ՅxQ���k��&��1���S<Ǟ�
��	����� 8��0�1�W\�R�E`iޛI�"3�=�
�i�M���/5�G�ǰ2���Jf�¥A�q�HO�z�s_��C"}�B VVrǰ1n��Duj,�S�.4"J<v��b���,K.��� �vb����������t�/y<;�c�R�R�N��Y3i�R�/�M���3^˚^N���w�0�s^�@�W�&�%qB"�D�xw�K(�S=��ƞ�S�*1���w7{�w�m ��O�^2���F�x�$���O�V��w{�e����F�Kd�.���ӑ7�F�e�����!Gn]�ZA�;xSb� &�*����z(.��LO҃��V~z�vݙ��{��r-�A���m�O.�������}��B8����z,G+�+f�����|?����!xy��,��;�KY�Q+4��OFي��cL���C�Q�w4̠V�8�ɾtF*=�N�2HM�Ԙ��FH#��XL���~�7���*v�˦�&q���6�#�W(�A2�w�A���źX�����Io�=�u<�pS� ��p��A�#D�{�|��L��.)���z����)W0g�p�n^�6<Έ�rr�R\5O���{��o�f�� �c�-��u#�Q36�'�ڊ%�[\�n������F��)?���z��o0����(�����.D�����K9��X8�{R��T�E}���]�=Z̛��e���;3�o�E3���#�D�jd[���ޞ�Q�\�i���P�n��0�+MdTOL�}<�<C�E9����vR��StYy8�V����xDl��ա���`a��c�L�0�t�S���[̆6Hʜ��T܃��V!��Bq8z�wx�^�s�➰����u�vLƊ�>���d��2�/5q�p�?��z�A�5�O��l+�� 6�[Z�H�Ti#�7��=SϢ0�c^�U��W`k,f���^_�9tP?������3�d�>d�W����������ː��n�e����C>���t"jԁi��&��j��/P��{������9��4a�����sr:�:�I�_�S��A�N��$e��/�i��p!�w�/F�>?O)  ��6E�>�����3�����-(�[jZ �:�b!]h�A�G�EQ{&��Z��]� @^h$���p���Ф�e�$lv����~�p>����~�X~$�(ҡ1���a���{0�mx�RQq����I�'J�i<���D%eaY��� l :P�dJ��X(N�(�s�q����.Y]�EC�����@L��#�Urd/�,(�ʽZf��ԁ� K��\�I�ʌGٵ��˅��Z�����o\<���@��s�\X���do���n���JU���\�(�H{�_�V��qJ'�xf�g�࿤`�H2�tC��'iU���_'?����c������"�|�� K!?%�J����D�$�*���%���<��6[u	 L@K����o	�7@��q�!�$�|��M�@N�E_8+a̱L:�^��6��� ���/�cf�YDIJ����AhZ����R���})���86>��\h�
3�ðL�|Q-�K���J^��Vo��А�D� ���mi�W���0r���<�Ks�@X�!��8��C*���[('��� �h$#���c���S'�<�W�'�j���Ľ�Ν�:Q�蒋�Ç]�H��+eL���
�g*��{x<���r\+4p���������[|Wym�]�ֱ�z�2��jy��6'j	kT����.	��u#����\'_%L2o⅐���YvGV��&�Upu��_�W�?D-aN㳕����,�a­����m�ۚ�F�5�+�+� �%yMR���X�gd�vkZ���=3V" m��@�j����Ӊ}ؗ3�g���ff]PHJ-{<�d�-�{eUe���dz&�p�����I�۩��^8d��=�㟪L5�P�<�o�g�=�_�;OW[+����(�7P2��/_�o��]z?��ɐSBp���w�Rң��x౩*ċ��i�RJ4�)�%�dv�����u#W\���w�cXtGE�����$���k��������_��d���at{Z�4�o�h����RE��׾=�?�Z���V��Y1\�ÅG80n�08��黥}���Fe{VV[7����o�Q���躹J��D*�F�-�wNEuc�y��>����ˉ��T��/Q�y �V_r38Թ�l�@U*���c�9��Q5YP�#: Jm5���=^���@S��,t3�7��8'� �� Zk2=���H�G��4.Rz���b"�o�
Ӛ��.Z��g�A?M� �����{5���Ͽ�;�c�X�?�p��ߗ� j��9����ٯ�D|��e;�+�ܨ���\�B~���������7JqpMs?q�������i_�4�8XZI�}UI��W=y�K��e<��d�1I�4�?b�9H<��n��>ʿ,������$����>j_E���ޣ͐F��|������W`P�S(�4+��DL}�/���"��<�'�s]m����&�w�OG�Q	��0,�.���4��?��ko�]�GDH)q���2�&��m�`H�h'���EzҾ�,��_g�?�A$7Fc�4^Xz��qs���dYCa�.}^�_��,=�bt��b�Bb`_*���gpFn�6k���������&�u^Ε�ÈSy785�p�.+�UO�"*aw���d��F�fj�������zQ~�&,<��-Gf�)o�+Ч��/�	T�d���Й���\"2 A�����b�'����fJ8�=q}ן`ynpz��s�b�v-U򻸍�*C�R�c��TʍDr�-v�=�Ԇ�*�JQ�̚��h��ED��=�1�h�d>�{-����3$E3�܈9�"��������x� O�EӋ���$M:.p�nv�kVA5�M�.�E�d�#r
�2\��P���VUh&���U�N�M�������x���5����6љu�0ϋ��2{�b�9|���!��3M��>��ᅸ��Q:MΦc�[�!`��02�)y<{�Y8�ؐ����i!��;+B�|��g����v�-��e�3_�R�y��Az�	����f04���b�%�e̩̙K�������c �'(OL;<9\�$�����A��*��	�FG3��������t����m�������p���EgG�"%��>��S[v�RL�J�l-����w��i�V��i6/��[&Ŭ[��q�{#�#�ב���sd�G��h���ݸ彍��T������tW���.'��e^�+�|&�(�v��@�&U�)��w��e�\�괵=�;��G ��!�}]�MRn�*v;O1��؝{�-� FkC3����M��j����O�h�G+e��v�ȥܪ���h�/ݾ�+��sJ7���xR~�%6�"ƹmv�
t"qa�o�W7���K�
4�߷�J򂐕�g�h@N	G��s$g��'��f����YN��Un�Q�j��c r|�5	W���޵0^?&��z@�����(x���'�<%��nTbC�˄T�{;��h��oY���zZ��b5U�j5��rsE��@�Wk��Vr/(��+ ���co/ �	r���=��xX̗���y�>���Ð�ɾe�J�G<GE��~T	��6�	����&Wlc�)T������dET�w�&F�^}C|Pёq@_j�����?~Z����Bq��L7y.ψ��^qy\�VVZ��K�m_y�'�8�>jn����`���tܓ�W�'S/���T�uǗa�����Oz��=^[�W�-�O��h4	�)�Ӥ�W�
	���,!B��{�@�U�ge��5-m�WϚ�/��[~���h5�
��#^0=/`\��m�I40��֑�|abݼ�*�M2Bq>�P��J����8'���}��]#�_�t�gg2`Ok�0/��[YcTN�ښ]�a��ʚ!_�4_	�%���6�(94�	Y�7m�?��ª��02�hc�O6r���O���]<崾��q��8��8i����q ;�g�ě��$�i� �G�/�=�,�E�.����Vp��=�D��k��_��o|��GV�a9�%���6ڛ�B���2���m��e����h��o�7#�ט�h�yl�{l��������؃�F����7x/ރ/���
�|�7��z�����~�h��{�ڗ�0���SF���{����VN������hE��}��;����F��w��o�w���z��}}�{,����HVUcy�7ʤd�F���6��iV4o��^~�C��m^z�rß���#�k�So���$M�Wo�.��x�L�YU���ƾ�9�;�.�S,4��C�3%�e<*ug�C��XnNՁOt�19s�h�D�mr`�����(�p0x�jg���0�#�dNy:���&�)�a� o���*��n���:u���~�e�<k����/M9�*I�O0�
e�w�������$�D7x�����Yi5QY�h��N�1���Q�<��}Ŭ���t
������;+���˘�C����7�q>x��N!QhV�2�B׌���ˋ���s��"�J�Z�'N?/����z�E��P¸��4��0��ߣC�h�K��`7��V{�= �\�	��8�k@����D�!�*����=:�k6��� j�TT�=�Z�خ�ɧ2L�K>Ъ��G��l�6��Ӛu/R�m�/
`S�k*U�
��Xp�o�����������㚉���0-��E��y�	�����l�[�u@���}�4(�I�N���páiޙd�EV6�ý����N��h�oX���F�MN~sе�P�Tlr�Jz�Y�Z�0�Ч��psx.7��L�4	W���5��D���5
@c�R����66��;�FV�� 9sZ�L�Q�-,j)�eF����R�*&��l(�&�x	n�g���P�L(�%�@[�6e�[��	�'��Skm��jÊʞ�	�}���������e@���I-+�^�H�e,��/�-#e�wN"̐�D���!4��G��K�rx��~S��q,&�$b<{��M���7�F�C�q�n^�7���3'�+1�N&�`�qn�:̔�Fnsb�y|�3%���n]"蕗����3Wl+X �k��hR����4+S!�i9C�K���Ο�o�}[��P�JO$��8�Q)ie���@�އk��qF2��(aֵ��e���}3�왘c��Μ�nFkr�ͳ�2��#5�ʺ:��F@k���������
Sz��Φ�o��W�mK-��s�6V�	�Q�r�p�]�y�p��%46ǹ�&�h������*�&�Φ��M�a��:5,3YEܬ�����Z%����#�s��8��)���q�[������o�0\�?ݙh�#�`&tr'�`�ft��/�T[�B <"9L�y�'ĺ����P/\�qI�9����0q��눕�oYM��
��PU���lD;'iM��AJ 5d�t}���Q2�{���J����MG�"͇:(k��L� �p;��u�<��A�$Q���4� n�w��<��~��F�B������i��]��4���S녉ȒΘ�-��o���v*ܭ�]�Q�%t�z��s��H��S��tΏ��}�b�`��S�E氠8�P�	�J{�,b�GP�O�^�R��Z�{(T*ت֖	�(��'����3�p2�G#��"��?�AC�`Lq�֯�8�utU���)�(EW��_�'��ҁ���C}b,�e�U2OY�p�� �A�&*�/mR��J��S�T�aw��~K'��}�1�X�El��뺾����~b�y�+�7O5�@��0+�i<���4q�������q;�g�a{s��Y��u�����?�N��y)c���EA*������O�Pd��$�@�	ts�O Y���8n��94���h&Աcg~�Y>�K�Kn��:�q�(�e�*r~�8�`�3a��$A�5���񹄊���$44��rxh�B�Y��(t���R� ��w6+�Th}Г��"�JqŰ�s��@�u�v��!��Y�������^���[(%V(Ă"&�� k���o���u��y�̆�K�9�Q
U��ɦ���C[L\S%�F�$|�
]��#�=���gd�%���d@6�D&�٫��?�[/��]�HQ��+�a/��i�9l��6��ηn�,�����i�<��0,ː��oe����Ov��o��zK�4�`X�(|U�<U�d��G/y?c���������*M���#(Gfnu�2d��d"���Ye�U�j�:\ZklM��2������ �#��#�P�V��hu��Q�N��q�OUm	!�2��:����	��2��7�[J�*F� Y�+�!��^��4�9 ����8�/���]�A}p4�<�⾭߫��$��o�w����w�視hj���T�
+��Y��4#�|��Ni��k�[G�/���M'X��UX�֔w,k%/_D1)�^��w����m4���`�9������Oqw����ieA��l'8=��z�`�����e����}f��I��'u�?�N:o�foW��wI9�^���S-t�l�iݔ��6M��)Z�{*j3$P;�	ܩ�{�=9F���3�2 ��䮆�4K=i��M�M��)����~� ���Ф�-�̬�4|�#�g��b�C���ڤ��K'�I�x5:�n���g�$?8k�D��k��_�>�C�(��.+�_���C��"Z�9��|���'c���kc\'�t��f��c�2�"V��^$�&G��5��)T�:7�5D������4��ъSD���i|�����}8T�����}:}ĂN��/G�'�����t�:��≗��'_h$D�:/}��YB�7����-"֔�̘2Ln~Y�P��T�*��� jW!pY�窄Y�U��4d�B��0�Q��UHb�'�M���Z�Q�b��q/�&�f���S{��+�VX��M�/��os�.��%S���P�s	�=
���5U�fS��q͚I��)K��&�#~��;D1C��9�cY��Ig�	���{f����{�?��<e�R]�f�Xs�U�g��9���Lsk�'PSjt"�$�H��	_3?��e�ڒ��	ȳ�w��љ�-�$%m?)�T��!��9�y�g�	��<���Z��p�������5k�V������N���}����v�<��F󧳃��J!��f�S9��y(�,���X������'�G�����g��%&n�%q��Rp�����4��;�?��)�6��a�V��}��5u�bC:�u�6�4����̍ԛ+��YN��:
�����c��]4W���,�o�R[";�Z��}Dl��}���u{0zG�o��x��^��`�Ю9��G�P�a:�K���ի64]��7��ۯ�G��ov���/i.�;nIc��]lY_�dL�3�趠�U�X�{�۴�g�w	,WW��[�|��SN�E�|�X�s��u��B��(7$��
{b.(i.JQ\R�-!��p�A�4�O�U���Jد��u��۽n�A��h��N��F[S{��%�ܑY�1��R6�VGGˀ��3��%"(U%��;S���s��Y�8��;�5�PR�P%Pn|aR9Á����Q�%�����"�]���C�Y�0�����^�te
m��K/��2��.Um�	����F���pd�ߕ�%�|�C�"��ү�=`)T#��h"#�\�xfT>�z�Eޕy���1���B�C��ÓW2&�v_�1��謺�!p���!���x��g�J�U���X3��e�h��y�d���s����<fFk^85�O�3"�W���8.�@}�&��g��XX~�z����)oq����Bd1��Q��?f��˒1�`��º��e���֡*_��k�MZ%n�wq\�����qxa��s�����B"m9j�nb��9���eyBۋ�����HM��J��(�֨Um�9/>[�S:la�g��~�$��	�	C	c/B��d�-%ӕ
3v�� �
T�+g�l��E�d�������kg�U�\1^IY��;�^iF�M������8��j��̈́�4���&h[G×��}�?���G�E/T�"g'��>\���bjt�ts�'3ޚ��Jc6y�5;��mC����fZ�U{d��M�B�KI��w��^��a����Gq<��kjE���{(��Bc�>�N��j0�A̽ύ�-7�����蜤�B�f�u3��"�n&A6�m��jq�M�T��Rn��~����x"�콮�-L�#+����sl-���-��l�1L�-��)(��م%�)��u��r���ʗ����z��w��a��BZ�7<��5E\���$�A$�c�]ņ)�+�3Nj�0�V���aV��
���W��M{7\�F"��
����O��ݸ���n<tm��X�����E]�pP��	�%�w�O��(��6`>�%��w��D���A�N*F8}��܅��Tditؖ�aF�F�����$�V�9�w���|"�J�p�N�����l��� �w3b�zꛗT&n�f�4��! �cz���r�W^�>P�1Tu���[%Ņ�#l��<K���LrD���!GD� l,�1z7Ų�n�V`�oSs�%��ԭ�J���či�o7k���}͹��z>�������}��>~��"����-`��k��^w���l; )�����eS�xq��'fK>�ƙ4�/�����>Ʃ�9q	ߚK��vv̫�H��%���A��
Xԋf�&������HsFK��ov���CB��Q\<hprs�w�٘��̺�������]h��jO�Ԩ_)�b�V�Xޖ�@�#?�*��Ue�\�r�|�V&�i�uِ!G�U�\�hfd�X��kDL`����Ɇ����ƭ>�����۹�)�&I*�gmQ_Mg��v�����T�=+Rq�A�Q0��6��T�`I��7W����/m��ֺ�q�q����ҞT��e�{��m5E���Jmx����z+�㼬���<V�I�Ix��˅��0
=,p<"D�4F�{E�聶�>�/J�,Q�Y���Y?��i��V�����L��XS}>;��Qi7��+	�&c�r��m��i1��1�ƨ&"^)������	㊡��CV�b���S��/��1�"�Y�H�/Fc�u���X雗U����|��F9�G"��y*K�Y#j��s!K;��J� @8x���XU( �,_T|��
a�0YƦ˳�LU���2�:����j2h�Ҁ��`}�� ਣ9�GI�yS��b�F�F�7X$�պ�0�t�e�)��74�8�(��0s�0��$&�i�sc X9h?H)cv�^���6��y B_ m!�����9F"�pI�0G����o%�Jq�f��x`*�ʨ�I�Ho��eL�
��ٰ�GD��|���o�(��h���G^
k
G@��c��4��(ν�a�;<�!������%0��d���z=�uu�ܬ
���9a�Pt��l��r��l����]�~&�w��Ӫ����m�?2܇������	�:�:�Z,�Ht~L<l~vjGÍ�������ȍ�'9�������	�X�ĄH�$kz��4|{kB�6J0��t:�P��[L��J���4Cii�'	�+MZ��@��^lK�.�S�nU%�.�;d�QF��n�H�?�t���4�Y܋.�!kf�{p5b`ѥ�ou��0�����ʢݱy��ˮbS�\W��l��Vl��ݘpRs{x��B_����D���m�U�^0ǔa;�V�n��%X�<�UrZ�9���s*�J\�RT?��=+9��U�M��ң�.6��y��]����B)����LȊ���Xuf:՗fwk`ZOf�E��fft�;8q>��a��=�.�74s����f߀��@|�c�dq��A�8���]z^�r�_��Ax��}����&��G!�.���?Y���.P7S��:����2����=�o�<�2�ov�p�z�G{	��_�őZ ��ܬp��+vKI��IM��g!�Fg�����cܟ#Dg!q��Ղ�P)��)�}�����6�±A�݆�4$��C������?'7���܈D<2�F��>��%~�Y��$�6�"��A^zh�N����-^�~8ُ,�F�7����v�9����I
Q錃,w�9%����,���Er%�K��p��ΐO��kL�ӆ�g�������7��Y����h�����)�[Y���ō�{�P��)��u6`lΟJ3�����ex�Eܞ�7��w�f���ymu��eG�:�7���A^��P�8�Tie�Y]cJD0�"�mp�����7�G�ý�Q$x�"*|����h��������)c��u�! ��0>�]��o�p)E�^��y��@�)���.��Ǘ���W�x����O��a���G͎T��i�1� ^��*d�ep]��EvM��nd\1p��beC�����(G�y�ZxYό��
x����/���n=�|T��|���������?7l����ʚQ���֓�81.���,�2!�2YA���QN�^�K�D�,P^y�z*���=���}���q��c&V�����q��x�z���`�_%�Gix~]G��5G�:<LVY{��t���%ʓ�.��31���(NY��5���S=���;�9`�o^�v���|�y��X�:�=O�#$���4�2��_w^�w����������>������X.-����{/q,0|L3���ɤl�D����{�����U���7�!;�Jc���(����pQG���>M�ص?R2|pBPQ��������{�O�/�N��;��>�ҡ	r�@ث� ����{1F�U�Z���&@C�S#j<�:�����gQ��)��w(��uf>/����O+z
����5E�"h-0r��A��w���.?�Ȕ�u� ��(����:��%��q�6S�1=��:gI5�`�8���� �S nQì�K�d��A�=���qw�������?>�n%R��L�����z���ĭ'gz���E�u�	NG+��h܇'���6m#ߘ�fV>Q�� ���	���j�\'�3sL{�`����T������ˢa:�X�MP$�[ewVڏ1�
��8�5�uG�Y�Um���tk��>s,������,�|��3�̱�~r�UY�V��ެ�̜}f7����	�;W��9�C�/����@%�����(b�˼�@I����٣C�#d{�E��������h��g���
$L�-*2N�=��蘈
f���NW��	�Ө���'B�04/���OF�Z+w�K����`���HU��+
���7�>��)�����=�1�����7A]'$ZQ`iߧ�_bj���h��c>���
��h���_��[k~�xѧ[U���UM�݊���g�%� 7�	FFF�&⏢K?��$M�QZGC�|�ꐲ��Ƈ�]G�5���Y1�5��1�	���u���{T����zq�Ua<(�����H��ٔŜ���I��">tќ���iu���������Q�uǕa�Ln�l6O��'V����\�L��{Zi��"���Eg��~�adS�ኗbԫ ��z�Աc�h�z9n��A0� ϐ5ES��w�4�ͅ�G�L9p������=� y.��iʢ�	輓c�F�ƃ�����)�,%���q2�$�B%�O���8�mp��ʣ�^��}�F]t�c�B-q�jT����g/O$�������D���}�j�����1��J �z<�|�L����v�����ʚS՚�魍[�m@k����Ɲ�9֬^�'6�S���������c�HN������D<�O�XTc8yO �!��u�٭s�\����tA6p	�ǚ{WM?�T����9ۋ�]����B���6�������L`�G��ݿ�﷏vq��9�G}��p�!�Ge1�1�9�2�z18�=�+-�هV�����]��a�R���1	?�Mϵ�/����k�"jeo?�I*�{�{��ŻA]ք���p�nd���d0�w����ƒ��% ���>`|z��ƀ�ސ!(�f��c/f���9w�?c���UB<�Śc��m��8�;Sл����S&�&�{S�/@�b��1I���`�h\�����:zv�Q��I�}����0�-]���\%��n�s�$���.��<JY,��LH ��lk��K��4y8ޡ\�ߑF��������csH"�՟II�'.3i+�;9D2`�v��G�;���o�E~V�ݜ�E�k�sf�|�C[rgȒ����5�Ш���4fԜ�����\���bo������o �W(�.���J���%\n_��Ռ�;��R�.+����U~�-�=,d��J���|���{�S�+
W���&�����8�Z���M�!z�`]b�SN5EdAvS4�A
�΅�nAx�Ma����:i�7�m�_�յ�ew&������i6�>��m���Jk�F�����fw��?�
��D��v�K_`��K�ǩ��)W�f�i���2��[���3�zR|�t?��&�W��,�	FmVo�JR���7�b�G"�Zݲ}i�ɯ�%k)��7[7�)��P��t� �S��~����i�7e�G�i�*�^��\Zd�U�	C}:B6@:�fy�^8D=9f lm~k�4h�HCk���W�Ԩ��Ge����А��Q�/�W!�f*.��tB����tu~�q�!�F��t4>���s�����_+Osk%�VXy�³o����A�XK-������7/�G�Śxh�K�В���Xo�5Z�2�5���O�Y_���Pu���_�ŵ�@���Ԯ<�J�ϧ	Y�LTt�,F%a�><M9nG��g�ǿ'G���d��
C��	�Z�N��6�R}��q���s��/k���x��h������Z�ͱ����F귳�����&c�*�"��\�%4�p�>�#u4^��g��X���]��'��|��-�e3lI�E2 lz4�'hC�3�H#����ah������,��
�j߸��2\��qt���G&�9�tL�Q��_v��O��?/r�]��>�* @�UיzJ��J�ڢ'9�$m��9�3c�zj��n�����Cz&�L��#�[Y���Ǆ����zG1k�-ݏS�NÅ��h���y���BL�&��g�DĦ7@�F��i�/�Ǘ�[�,"���ܴ^E@O����%��㋤�ZØ{&j�( XU-��&QZ�f��qr�{���Z|-v_�'���ؔw�b⎊�{'��D�̈�}�'�Ut��Si9���'� xӵu�osEq�ӲB��$���~�v;:f�,�Ss2|x$@TL��~A�C��48lPݔ���1�'�Eo�\�f���ds!�$6)�|�K��YZ���0������0l�a/�f�v�t-�lȑ�G���!�hW��[ 
q{s�QE��q�ރW|eJϺJ��v2D��t��.��:���U!��4�-�O~��t��!�	{�`v�<� �q�J�m֓;��@Ÿ����ON@|{�ߢ����'�H���lj�_)[ʱV*mPN va�3'f� ������3Wyy,����0�����=vHဏɭ7����fZ�� UP&�!�'�6ܻ�`�3��7m���E��1����;�(�[%.$z�\���.�(`dl���g¦�:g�������_t�7�],�|�<$���͎I9t�"�.Y{����	U�&����	c��g������e��q*�m2WM�J;�r�vl@[��y��l~��T�aI���]4z��~�N��̖h��-տl�t�t�8���ٍ�r�s[��8|�FP�T��^9/�j����%wsC7�l~l^x���Zg����$�Ku�x���K'�@�ε*4���aMC�E0_��N��}}����~��/��_��
Ƶm	�ʶr�\7D".�3�>��H�;�*���qcY��j���(��w�L�]a�D���I����Z�^L"���d �1ބSoL!�!��A�9""w��v�4P(��J��.
�嗦��Ȱ�̂���T�B= �Ⱦ�dN]#��mp][��Ą�@7��-K�Q[���޾Hb�+�Q�&Q�Q��T�p����b�v�����R�fZ��Z�S�g��,PF��"��Ⲡa��f�M9�ʼ�0�3R�+!w*��$^�bU�7��"�	YG�-l����	�a���ݘ�r�]�s��̾ș�r�H�����
]��6׃_�AhY=���Z"q��K'��ڟ��1���B]zC�(a��^�t�{r����-|��^ՙQ�T�D���Ɗ{,*�i�d�����w��h�Q$X�=�W,���m�X��7p����G���Y똃�������z��o��R���� ���j:i��/���������C����}��	d�éw�g��N�eς�sm$�5����'��ur}�v�d��*�,��_#a>0?�e��g{�e��F���gM�y�1gN�� ��	K�JH쎗�|&��;��	�YW����z�YS|E�X�g�7l8Ϛ0<N��"`��|�<�F쾵U��N��ϙs�p�i�S�"��YV�O����畩l�d��h�á
�r����?�ϳ&Tq�VI;ˈVp��M�#za��ܦ�QV	�����s�]Q��G��@�<Y����ZI,�Ӆ� ����`t�TJEށ��P�.ԂJ�f�/�)@��ؗS}�1�H�'1X���a������o��"�?L���o��=�x�������k�K����F+o���Z�}��?u�̟�
+����&����hVŶ����e�*Ԇ�t4�T#�_���}����t�T�T%M���0e����v{�ٚ���P�0����\Stz~�#��K7���o���p�-�5/��� n���N�4����V��O�)W|�EC��)2k�H�9Y�RW`�v���G��X�`�W�l�0�����{8>��\ r�y�u�e�ƙ\,C�g�6ӕS�u�A���d?�;$5T���/&�yL�W�X���J�**9�H7��ɱ�3���6�z^1���"cjғ�c=�1e���_����TN(��K��^�og1��Pgpi��:^�I�b��嗷"��L6I2���5b0��ٖϑ����T��&�m��b�]_�B[�5_r�$��ϰքD�(x�kF�-Bߛ[��<��q3���y����C�7P�S�Z��F[�)�֊|�1x�sv���j�M�k,Κ�� ���II��З�K\��u�PX��p/O�B�j;9�����C������[~�#�+!�̚�d�����Che��}�N������z�u����K�����^��������
��>ل5��'>Qa�z,�!Fgy8<'4y�9/<(��tB �ܩ�X�$.�6�$���l>9��t�f0\���)��k>�Х�Y�4� HԀ��.(7A��lf{o=�-G�翳 �Ura��b�]����3��;h��m��\� �=��������Oj|�J�����._=��x^O}0	�HBA<�H�\ℲIHn�BdGY�5�B�*����5߂����%���됣.��[
Hs�W%]��_��S��2(0�Ar��������FA���^�������������)� g�̮�y���+�l
�:�E4��؏.����~�k' �~���S}��*V@�>>�����6�A��H64N$B�`[Q!�����E{W: E&uN����}��,�g�i썓����ה���c'���|8�躖���+sb0��$�N���&��g��0�gd���č����P��j�5/��#2�P�q�	�y��zZ�k��^� I����8>�t��.{�����Gp|�{�@�$ ��WS:w�Q�m�$�ҢZ�zV9F�+Ɇ(��\��@�x��?�3YrD�2ɫݿvwJ�0�i���6N20����~��'�\h�U��NZ��0��g���4iX�g%��?��"�&Z�mX�G-��LR�0����Y���ў>`�궧x���x���
�4�˖�A��XOB
��["��F�)���z��aк1,��U�;�L����,O��0�,�R#+VW1Y�"C�H�I��z��P%mžA]0�XE��d�W�Ԁ/��xg����'�Y�V����3�J�)AM��	8�=>832P$����	��qS����Am�|:��\�ro���}�"H�'��	ry4A$��X�#�r}s��Ѧq�'�6���w�i��D��haf�w�Z�%,L
'�$��1�)Z�_6 z ���!?��S��-]�7*��`��/�O���'/ގBD4���̈́r��Zhp����w��/��o<~������K���ܿ���,�l�����jk�?d����7�W�^$#�����ܿ�jd�����U���42�33�̲~����R�<��\4����oS,;��Ԗ�c�F��W3k�u>��T*W�9�k%��^�����Se-A��K@�j�[���t�按�]�s
p:��
\�A(c�S\��1fh�ȍ� ��k�O���D�>���,��VZ�AE��L7_V��4%�[�ƾ�$�43��L���Hk�.���P��޿�n��& zפLU�6�9)�0(��暢����n`�Fzkf"��R��?it �(2fCp��v���1*�yCh�,��dv���K�;����:Ka�0�ց׈�*�;@��E֘tli� ��#��|&u�~A�����a�Qk����AJ���N��1�NXU^�.qI�J-��w� ���<�+��PZ(JS�h���I�qw]�	F�K�y1#�[%NC!�A�$|��Di~6�΄��y���y��w���?�����&t��pBי��!�~Y��
�u�ʨFƣ���.�h2 �@��ֹ�#Q�uʳm]i{ Z�"iM�J�In�俯?����C3QR����ҶZFb�~�r�Z���-ؐ��@����_�a{B"�$Ff!�ϣ��'n=�|<nbo 5A"#�8{��B?~�D�I
I�>C"�0�Ĥ���$���DC��H&0b���P�H*~=�y%M����Dc�����D�TB��OO��PWT�S�,EH-��h�NK]�&��0Er�g�QE��xF;�	7�B���/+䘄�e�u��9�"?��)�����IS,��z&x>"=9�X�5�n���Nf7m�H'Q U�$Lc�S=v�����<hǐ_��kB�&̱ {O�{5�&���WN�:��Ul��5Z�.d�G�V���� r�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~����_��.�, � 