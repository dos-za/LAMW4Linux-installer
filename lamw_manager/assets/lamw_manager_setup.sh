#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4054059475"
MD5="b011dac8287cf72f6db20c624384a4d3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26024"
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
	echo Date of packaging: Thu Jan 27 03:31:12 -03 2022
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
�7zXZ  �ִF !   �X���eg] �}��1Dd]����P�t�F� �\0kr���c�e��������Ws��2Ӕl]�
�˺�M����.�|��ŝ�3���J2I�u.9��/:"d���lo��!vxq����z��������u�*��[k�%��֋Cp;ϭ���b��N������B������@�.�����DPZ�7��R0�r衇6p����=���=c��{{RsV	}��W���ESO9��������BI�{�9(9|���*EnhH;���B��qED�H�oI�2s'�z�_�G�|D�%�[t	Z�����j�0��+(�ͱ���i࣭q�4ԡbY/�bI�h�=.���ހ|��q1�QAY��F�aᆛ�����'r�U-
���:�$
֙J��ԎU�N� &0�5��x��X�߇&�T�y�kkb}�G�S�ڿ�^�d�;�݀
y�.�0-����J��6���Rr�4 �fG0;mzP�YT��f/٤ ӡ�N
�����Dw\#.��#<\��z	�������h�ݾp������?
��4?m�3����i��Ig�m۰G�`�	�i�W�r!2[�ڵ:P$l�U�_�l~g�m�((�"1ob�`�;qq�3�g0QV|�憽�7�t\���.�^�\8,��?���r�����t&FĠ#��Ā���'/�m���\�=������
)j���V����Tg���<���_'�����sn�w"Y�R����'���_^�n}��$f��F�M��֌2M�})G��sNN����jih�Y#�8H���<9\y�����#5�I��,ֽ��ߵ�/���� ��
�H���Q2����۠��Ĉ	Z� �5Ǆ�n��7��Q�Y��"ğ��ں }	́����Sk%\E~�1㰣^�(��v
y�J�P�"(��2c���Q����}x&H7k�	DӲ��U�03a|kL�EIL�
�z2?�-�����S����a�gb��=}��'��Ӗ��tKc�d�>�,��-�it/F.9��fC�'%X2{�H48m>�Y�Q`���,ݾv�y��YXv���/XDa������C^�����p�i��8˵�L~��~��pЭ��V�<��JAAO%*���ӇVƵ����� ���>J��!-==X�r��-4�M��=����WA���K�`��ɢ�kg��� A��fSǔ�EW���FL��>���/
Ll�d��뇏�w-��������=z{����$�ʔ������n��.W(�����|'=�� �i!�,�ok37'*�������ee�[ ���|պg�-�����DN��3/:q�j��Ge�4$|��/TM�����kx�0v��\� ��=T+w���W��o'�{�����,��`��{��EF�f�{0����3X�C�3�J���c�bp�쨮��<��r�<[&*Gv�\�O�~}O�"��I�usG:n������ºYB��������$�Ea�+���F��%@5~п�+lt[qጰC�<wI9����{��c����cS8,���Ɲ�F��y{��^�U�S3U�{D0Ȝ�uVr{��?�	�U�h���((
%.;_��(���N�e�$�Z�k���|����A�w��O0؝$�N"�Ko�e�a x!�='��U �7��V�^9�/����?��E�f�c��*|ۅs�U��#��>��{�k��s6�䜟��(_~.��S���>�al��9x$4C��Hk�1���t��Y��1���t��%rɦ�O�/f>JS�Nv���O����g6�C���N����sI�NYʰ+���+��51rf9~�fIr�V��}	��o;C�G�v
�t��^ !�9�"�2��x͘�0�0 ��C�+=EdϢ�])�7��d`<�p�3+a�{� !F���g�M��I6�~t �5�A7{�[΋2�V�(���u�k+7�x.7�+��'B�s2���.�-���$������-τ�
�ao�O xtG|��:��by܊�A�.�i1֥aO��h#߆�8�� ��P���@)Z�^IM��Ҟ�@H6|��2�A󴑲:=�����s_^"�٤�\�����'��'C�J�Q3k�!�f6-5���n����(�]S�p���SDp]����ΰ���t��N�*%��X�);�q���`�f�F�������45�U)�W�`�"9bi�Pw#0R�k�#rN>t����g���ײ�oB�
�fb�Xm���I�f>��L`?m�8&{`����N>Qq�Z%�9���g�)� ��N���S�,��"[03�5��N�����8�&
�Hn��+�|�o�o�qw)�X�OS��mEze������W�Ȟ�M&�^u#t`��h�ά���!4 #��[�}�#j���SĠ@�~��r�C�@$�g��˂�{����"}�sdNxpo�\�b�"c�#n9,|����F2{���Y��:���������*�	���]w�+�)>�s�R��w��A�;oo!I(E���K{2F�=�)j��Iæ���p�
`�F1pKpb����m�1�M�E�����iC�"���'^H�Ѕ�5d'%�|��:9χ-b�jM���)E��"h~{L���@$��3��{����ȷ��D���]~���QaĎ��o'�"�3L3�=�=�(J��~o����|�{��y��ؖ�9	\f�kF�f��i�ɎS��@S�:e�����-/��W��Ƽ�<����z���枔6�mB�<�b)U\�8>�1�>H�H��Fj��Nr�κ��ߤ�S�;N����j�z0��4T�͸�(�'�������QJ��`E")�E\*���x��QЁi��p��R7�gA0�G��2���?�lx�x��L�v��h�Uң��UWLS+3��l*�c��9��p��+Uᗊ����"ٮ��'�Aَma�?q��S���@�nh�\��B�m��m��EHm_���um��:�2j��r�xxj�1<����R/'�X����"�5w�Ņ���8�-����#�񮷫����g�OUSAH( =�!p��'C,׾���L�D�/���z��(���]b�)*� ��1��k�e���p��O��*�������v�)��1�4��מY���7�2Pt�)F��,��(4xZ	����~�� �8m#��Ow�>��g��N2�;��m�Q$���]FS�S'
�'���˶ȟzs�������4�V���g:N�kק:�U
�as�X���g1s��tz
�����T\�{�Ӥ�r�
ml�$ǧ��	���\�/�iް#��<x�#g�/�����	o�wS��A��&v-K�����AN�x��]��怉�Ad|֌�j�yn���eB�h^#�ۤ)��!���T�j]���4����8���0�����d�Oc;c@���v�.)��������HZ3��3��POE�.뫴n����L�8��H�R+����^����C�4�
_*e(V�"@��Fq�3�˵���iz7K�š�x�7���&��*!OS�<�Z�ȝk�3Y#vozSA�y
�q�uJ�h5�g�Jv9�U�h��S����N�q	�)M!� <�%`xErtX����m8�~���x�sy���O��X�����-�k4��9�*�h�=Y�z3F�e*�+r��qG�������O�#�7+��ǔ	�׸ӌ<:��9�T&�3���;Z#�"����ªv�,VfIJޛ�f���uw{�~�{lO����΃,��+�\�w� �A��/�i�6JŶ�rx��	tU�F�*��Q�T0�ە�ӆ7̮A��������'�j�r�ް�Uŵ�ދ��zj&�DKf~L>*=�Ղ�k�ҝO:�Y�L�'x�s�V�at<��z͝xͮ����zG���b��s��i�=>�q4I��#�7�RAx�6�q�/�S�K�=�8@x"�g�$�QV�6}���#�<�9u��Aō	"�[�6�ғ&N�~*�q�Swx�_�1����,�p1����of1�������+R���P�ZP�� 艌�\Y�
����1��!�e����K �tsٵ�ِ@pb��b&{E��b���{�Cܸ�?mc��e����|H@N]���|�C@k��Y�.5�U��7$�ufˣ�$o��`�����=��8R;�DKt<��͍=R]���U��i5����φ~�5՜�g�SȀuzTV�y��&*%�~дP�P������{`2���7c+Τ��"��)���N"F�'��@bÐ\�j�����ܮ��Բ��I�J_O:칝�
{�mPJ2оduu@P��_E��j�6�<Ũ��]�E�[���/O��q :8��Py�,Jb�A��'�Ĥ�n�j��M�����O�$:�a����R���׍,Že�,,��[�^U<?܅T��u���'��6Ƹ@��L��$__����
S���z�V�6��̇k��0�F�i���h�V��'8�c�\�H�E�R�H`����w}���P�g�]�
]"������LB�l�'�v�e�s�m�Ĕ�}��&���#��#���?�=s�4�*Y���7�S�+.���u��s�?��cP��G��)M��v���Et��Kv���p�����x/��K�OVp�<4�A�/�O����l�����Dzl�\L��mh�o�dJQ�d��������J��/C�Eľ�Z�P�,Z�I�>�S��)z�b�=��'pLŜx���d��:��@ܩ��[6���0�"�Hd&$��i#܌�/��:�������ʯ�QE:D�A&�V���L.�(9���[����U�<e�5!�B8M��ni�ӟ?|��DU��t{//NnQG�9B�$Ix�Jx�DtT�9�X�xod�������` �b5�C��I�Q�[|íT�Cfm��k�uC���Z0��g��z,�E&�������z_l��)�V�k�fu�]!��!K���հ�j�`X�W�ۭ��ĜAZԀL�og��v��f�.�uD�ߩ�i�����R[�a�`�5�Pg���ȣ��~$�K��bD�"Y�r+����7C;�i��A٫�4�%_?m�ͅ��C�6d��~ޕe����d�������AyZ�W��ǧmQ�;&]�,�� ��F����ϒ�7�Хe�c=�R���-�u0uK1�i�G�.t�� �i�6�Hb"�ݫPBw	<lBbf�Pl* �o1	2<��߉f�"G�]E�F0�UͿ�Z��FU<e/(K��Ԥ­�B1M�sPV�L������Nʤ�X*�p�\p��u�xCl�5�ڌA���������m�c�����>�T����oNG�4�"�rq�F�U�W`d0z�s�X�k�n($���^Q�g��r9�O��Fi�	�U+��v���H�]�\Ga�3$_|����w���EkY��|�֓ZV#����cqq^9ct���׫K����K' R��u���m[^d6�f�o.q��d2�2G�W��g�d�\[��nt�x|nˣf1k�]��#�j�D������ȹ��=,��A����	�~���|Χ�fD� AIޤ��K�K�5�Q���,�$y�"ț�9����5P�	��zȲϦ�/���n�k1��D���k�
�[L�D6��Y�e�����s �J�*j�l?7����Y�ɽ}�o������٧�џ�%V�3e�<J¬��0�Q`�lQP���0��>�G3��Ǜ�V���R�� ������7�\$
��b���rq3�b#��ycq)"�C�B&��]+4BI�UF�{A�0#^�NmA�RYwSP	�#&�?�!�i�jb�� X>u����#��v�/v������C����Fl}��Ǘ��2��9#b�CH������Hق=f �V���
,l�ݗ���m ��&g�АըA���L�ПO`!���-�6]!UjY�ht�����_���Ck�JsÛ�}�b��]�z�w��IG<UZ=d�#}��.��kyI08t=4sJ����.�?!L $qPx�tC�:{;��ς}�k��Ʋ�h�
��˒\Sv=cI�rf���F��C�'�f��k�Q{;kʡRf�4���@&��ެ�¡LcN|�5���s���>L|��T)je�'�f�.������t����]!��M�Q��r�����#�����3���9��Ҡ]��$�Id��.�|W���b�h��#�����L%
��T &��:C۩��$@�k�e,�U�<�J�P��n��$�[�zm� �елg^���s'z[,9��=�f�h�~N�^W�c7x�D#�;��_�a�ZA�t4�"�������Xw��<�a��4����M!ɝ�F*����Q�,w�\HI��f<�49Ru��`3�`B6��h���%7������ߝw�s�@�ќ�G��M"?��٬����$	�{i��w����;�_���[K]��5	��s;k�����{[��c/ܳ�aBr�Gt������u��2�Ix>P{�[w�?��1~].N1V���ꓝǮ{S�T���0{Ka��-a*;o��EK�W��9�i������%�'�V"��ޞ�OI�����DdyZ��$�L�+�������L_�"���&w!�pm�T�i�Fqp��l� �/�wn_���u�����]qs@�^�i;���gD� u����f����8$	X����W��Dm���XE���w�Q���8�m�o4k����:�򽕥c$޹���_˃~� �[��y#�l������P��uQ<exеJg#�-�G�M�iΙ� w�G��j�}�*l:'��iz*\���EH�y��O��t���3_�$;1��� u���Rk:�����1o
1��`G�$�2)%?��ӥf��Ƿ��#��AK[|�����K�v˕iH�����!���mg���`ֹ�N��l!�>�r�|��ɟP��|�� �P)c+�`Y�+@!o�,@M�}�K\�+��F���R�2���1��F-�ϐ�pK�y���i�L�@lϩ���L|d�L1������E�^���]ة&skD��� "��M��)�2 [~���/�-��x��T��z�f~v�K߲�$vZN��f�����`���2C�9;�f6@#��ݲ0L��'}�Y37��������!Z'��3gc䴥�4����[���"�f�<�����"� .YT���Ӽ�= gO4�"�0V�`��@�I���)b6��>P���w�����To{�ڶ�E���7���6��*���ѕ���B\Ԗ��|5r�F�Tvf -��F�۶�c!��-*e>W���F�a�Mf�VFg~�����_��3�����昮~��e$��#�T�kT4TT��*/���X��/6�E�N��P |� M���Hj����,��\�&d�r�h�[���\���e5\����t@����t`����;E��9_ߤ5Z�8.�o��U��Ll�.7�+�!AK��o��*�p�lG�j����Cb�g�]�[�q	�E����m��&h7�)2v��[~@Fm{Tth�\ڬ�Ш�ZL�]��y�pgB5=p4�z	�.�T��νk�46�?�6�U3
�y����C$pA�Y�?���Gq/������L^�,[��/�f�q희ޥ^-���,�����<ӑ����%,c��i��8���_�Z�e��cC�N	Y���`�G]ZK��`"l��4�ض�ݝ�q*�f@�P�v%�����S%3�
ڸj���=(�>\�A��jJ�?:�>㒱sȱػ?�󡏔�vZ��74�2�;:����y .-Y;c��҄2��_n1w��й�fo �7?N�ؽr`�`3_�uR��Q1�R��dS��¢C�N%�X��� �X�N�P�]��e�{�8��'��11�����,������w5h�D̒���7T�X��Rk�d�J t`�w�2(�J@1���"n5�����o��!��-��Md(4�iyZ�z�Oݰ0�?-�K����%�1V<|�[��q��Ϋ+��]�F� ��am���7z�R_#@�~�=��9���/}�M��C�I���QB)pP(E)��zu?��B檎�y�/|�q���T�#�E� r��ak�E���n$��Ø�q�]��d�^�>��qa)DcA4%��P�,�\uZM��:������ן�@��Bᝈ-WS�Mc�ɟ�����qA��i#�f�/z@Cp(�p M�Y4�'��~Ia��o^��Ŝ�Aͱ����\�S�-�?���t%� ���9U�0���,+�(}�5�,5�g��V�����y�_e*���7�lml��
�2[`P�Pd��(j	���vS��,��bm�z���0N2���e�<y�����+-ւ��o�Nm �]C��\vmģ���BR(�wޠb�j��q`��%S�c���a����	��+�b��9��G�e��YW~c��>�*6�)5	�;�g���f�ʒ�;���̄�����IҞ�]����TI�BgC����T#�����{�g���$��³8_��׻$0p	��5؜��EI���WoY�Y�<dC끣i���Vgisކ-����h����G�!rd���zb�'�B?$a!Q�$�K^��� �+�;�*�pzdw�\�
Ǳ��%�1�20B�C�>%IȬ��گ�_�v~ΘB�n� ��sM�+/�(,�([ ��JG{�ؠ�$pV��m�m6y���F`Fa�w½�{��ۉgu
��H�n�= ��*��YV:����R���C�^zo�+�Vfkے�ίI���<^�&�^Պ�
Rm�G�:��h�dΠl@#/ZHMA�����yF���?��]8�2GΜ��V�� ��x�1�w�ʘ����y��c5�-���Jo�0t�l���Y�RBH��߂�I��d�̫���޾g �r<o�S=p�@L|���4"|7�`G
m#j_#��0y��p4�V,n+��X������Rg|5_U",�Z(Ś^�m8��,����F�b�%o
FK��ږ�[��2:�1��(����Wc�X�^����\8�o�.�(o���3��j1a�@��-b<�Ik/p�#����d`�-�h�\Vմ�"�YD�u��i�&�J�vʴ�������db�{z�F8�[���ǁG��-�I�����u�m��z
af ��Z9�}{��te��G�Xj*�� ,�$�w(�5�P�g�L�iw�B���͚�ZS�6�#�&�h&�%Ӳ�CL;qM�����,�������\Z|o�%䐞����g7���	.��1����\O�8�}*#�a��k����e@�T��WT����u|e�ƀ˝�}�|�mY���͊Pģ����������\c��b�y��cy'_���# ��nH�3i�"�O�ʫ\�}�~#�m,1��a�B=F�A�uP�E�AL�����dr۪�����J�^����>��>��f�0B+)@��!z�-�Ͼ�1 *1�Z�}� [�A=WO���e=�㣠�.7{|\6��h��B6�-��O�ػ�偯5ę����&L��+�!�
�+�^���7E�{�W�޽���"�?�R�|2>�ſ��T�i3�
�$%j6�"Kr���F�_�\�{�N��73����7=9`��	[6���>�����U���1��\��.��^{L���@?�(M����]���&,��ڭ�ӹ�3����w^�!2,�ڠ�8�V�h|�塧]=jD;Aٞ5���j��p��/y� jh%�t��?�z�l��&�S=Lw�"�ڽm���V����.���i�\U�84R��T�UgA��1�9�>���]u�U�X�K~"t������8�f������3�q��^g˩�Ĺ�����} m�ʞc�e)W~<|
��|
V������� %�8 ������{��/�Hk�����V��T�	H�7�k��!a2�$�u����w`L�?"���J�g��TV
�Ȁ�r�0S$��'��zPj�X�����yh��4&��b�{IBA1����f�������3�l���r�P?�NޞJ�̚�f�5�v�5�������a5��=�w���ސ��o~�p7���
������\�u}pd5A*��Եl��E�t�C=Ͳ5Cj&�3Ri�7��Aʚ65�< �Hӱ�t\�ɰj5k5d�^�����,!e�8��C%@I\+nO�Ѯ��Sa�%���S����TrXY�B2�6f܈����z��i����|l�"Ӂ��4���քd��>��y�Xۦ������D8Z������]��N�)��@��z��hUe�S�� �sX��\�����X�v��۲�:i����4������׹~�n�8�$+W���IS�}!�8��;T�V)�^%틄����jP5�\�24!�E���@n���-�a�$}����5�b)k����I�-�KA-��f	lx�m-	Ӓ8�ig���4��&3��,ʕ���@F�ӻ�.��91�������;e�������Ԥ�A{��@u=�ć��;�]IIS���5�S6c*��W��` p�|ۏ����L����+8�N7Tl�zsU��:1�+�},ʬ[����1����X�*]��)DH�+��������&��5E��]���V#|�w�o�F������b�瘋��t��;�jy U��M4��Aʑ��u�6��'���ʦW�)���?�fty5p�����@�r -������C;�Y��M�D:�����4��+��/�EM�G@4��J��Gh�Obw,�˦d�+.j�(���YKo�t2*�#$H{�J�W�j�P;�I�
erk�U�4��J�&��+z����P�%�}�����w�89RR�i퐏4�6 �J������j D����Y��f tF��a|;��0��4D���C��ԩ�m=�DE�gd����K2�H�b�BL�V���y�G���%n˅���E5wK�����6R��������b�E�p��Z�l��F��z��5��wU+�� 'W�gq��X���qpy�^���[�{�~�*�=����s�h�P��c�+@�����PPWF3:�*ɐ���k�,l��?���� �lX��w��wo��arO$���G<R�&X.��)R�^m:�a&Aw��Z���o�����������/�0�f&b;���U���F紝�
���]u5u�/g������F�dި�$��u�,�1�Gf��� d����^����ݣ-��� !�I��&���ld_��,F]^���2�}r#|��z�jF���^��Y����2��\MC�:mP���+��9�i�S`����]XEM�	CM+v��U}�MGu|c�E,�>����-���h�h��3"��\�v/`�o)��*������m1�f�W�'n��kh6��L��޲�f��9�;����ޘv%�'�|���d�/�w��
�N`�T]�x�� �Їf��H�݇T��:�A���F�{R1A_l�R �,k��U�p��\+���;���-��)v�V� �_S%X����ٜ@;����,��{�Ff���Vg�r���u���9)���"p;��T��A'��]z�z<���grҍ<Ο9^��O[�n� �v�ej&��!���u�[�;�@{M�
��ʕZ����{�����>��i�S��+�f8��C	$�o�V�9���D��J �`��G ��Ĕ�S09y�l�/F�#y�[���~l�Z�~���Z���6�� �Z�4@׍�m~m/���}�x����Y3�3���ɩ*���L9-']�2�����A%L\� ���V,��C ��?��J^��:���#�{'<~����&)���V[��v&L��4n��^�L�'��)6uc�7��Q�u��7'or�[�Ѥ��> {�,	�C����az:�M ���i,+�א|���(�yw���+�,ي��ϊQnZ����6�xv�vuڧڱa��9'zU߃�@#/�%`����2�s����'���������1�B�4��~c�&&����,N�]��=C�s�v��%I�ȴ:t��3ZD6�D)ސN+W��ɴC?a��f���[��$z�(]I�|��u�>���q�U��3��l#��k�!���f(�F㖗[�)(�	�"���R�-0��*���t��{e�%�(�I��#a�X}e��9'�3ߦ뱾��$=��_VT��WbuO���6�~��ʻ�@�!UT�`^�S_��}1p�������������r�:�9��x䉈�O�>�x���"�f?,w5K*��@Mm�$`���P"��0�uY���E�����$qn���b�fR���`�ህ�{0D�q� �ʻ}A�%�fV_6�ӶtB�:�A�� 6U-��0@-��1�w(��HvH��!ʲ{�>LBT�p4�7�@	�O$'��?l�̎��Ł~��_���U��B�c�lMp�a�d�L�D��鹚�!�P���v���B�ԆO��g!_�aC�Q��p�{U�]��O�.��X|M�m���~�j���@0�)�����;��8�"BĔ�*�����Q#��X;��i�8&!(m+�+z(iS�-- ���Ϫ[�{�s�  |��T��T~��׃�[o2���yOW���+&2c�7�eꩉ�����8t"��y��y�"-�����D��6TeQ7�8�0���L��}�J)��F�����`�W�Wk�bσ�ц�x�ys�D}��KO���B����Ec��3�1FmB^2)����=�_	F*��h"��#������_���<�L��ͪ�% �'��M2���Jhd�d.K�:w�����;��;�f���K�đ'����W���n�5��h�]����$]��j���
�=�,/y����(W�U%;ʖke.1S퍉���t�OD��
荑�QH!�oQ^'l

������S��M�����5��t	����
��������/��/����AmI��@|/���|�B������bhM�َ��-�
G��+P�L�W:V�u��g����qdﻍM����g|��X��Om�"㲕���_��@�,�s��9���p��|O+sT�;��n�`��Y=CP����;��B�!E����;��;����3�?����|Z�3Z[
c����N*J�[�A!� 67�6�l?������
͵7�c�����p��&!�&G[7�-����r�f�q���@/��$�|ʉ&^#�1b��V�Z7�%+{]h���?D�U���LёӠ�
���qR�eZob�u7nJ�D�(���ۑ�]YU�3�ot�˸Ns��Y:�(p9#��ڢ<;��םj{�xn_#E{��>)~������Gy+6��0OE��1+o�q	K��O=,�u����	~�A�E���cH$���%�ku�@�N?�,�"���ĠX/�x�c��d�
J-x|�Np�����F�"�YE�v���Ys���H��|1U%1��@n���2A�c¦UX�(�Ez)+t���\F�q7���᭼Y�8L�17����4�g��%�1a��_Q�-*Q4�(�_aq]�Я�1���5۔d#p �ë�C�槻�-��LZ�禼�'u�� '2^�YN5��L�Z��߫��܆�3<�{�Ns��3H�KT0f D��,1��|熵��w���kz�cy͓����_V!]���mB�q6ƛB��z� �؟�ʜ����?6|[�b�k�O��P]��"��������`5+��g��d�����j������SAEI��(S^��ŀa3j��/o³�($0r�0;Y^��K����Ĭ#|Q1~`=�Z� :#�;A�
;숦P�(�	p�[rBX����^+N�g�� �S����t؂QU@���C��r<:&��G��ŭ\5E�1��A;yZ"Ş�͡�?�i!}Ӈ�\ݝ�P��M*�F62����^ơ�5�d�㾆1�3��5-�g;��Ρ������zB#&�<A�}~���^|���:�qM��h��zX������������6�F^� ���>�c��⩖�q��vT�j����
�7���d�z��k���'2�fC���}��H�m��|�}|�m�?7�����@���Fx*�_�o��]R�@TW���:٧���&(d+�}X<�����N\��P�������i)�2̶�b��!G��n䆆�ks����
i����6��P�T)<V��D,7�],J�%$uw[�%�GXE�����+�'yl
�#b�R��t⯛Ou���.n�N�ixp�w���K�wR�+`K�_K�����$��q��k���7V��ю�̳t��mF��%J䖖ثќ��u0U��
�1�y�i�;X9��Z�]����j���Gh�tƦ-8�g�Y��-桊x�`m��^aT�Tܒ�����e\
�(�oV	^�N�@�qcr7����p�����4��9�W ;]�	�Y�7{+)Ti�Q�̰�R�^�����\�Y�$�T����k��R�!~Kƙ�|[&�64�9-j��̃�d�a���{F�/L.!�#[�D�� ɮu�6*��Y��}ݭ�?_W p�H�{����4EW��ޔP�ZkU��������B^��Me7?�o�>~{���V6P���!JU�T��頫����́�8έ��S�F�^1��E-	���CAt����r&�ke��D%��"�4����bT�y��pi�d��;����O�y�2�L���r��Yf����ŮTb���q��G��wq]���E��5�ςY%�F����a�|Ap��i\��~�ت�7"Rg�M���Bn�GP;���7�ݾ\�Ӛ���<��ŵ�@׾dX|H��,@���j=֛P��ˉ3�e����S�.���\�S?^p�BÎlp�[8]Y�-v�O����G��r� ���Dm%�\eVf�rH�~�:�f��Y��X�ȾQ��z�&�/��h���/������(#N)��'�d6������J#_��Dv撉$|���%���A*2��|�\M�2���?Kf��no/*�`���)���g�Wx;���9�Э:��&�ѩd��E�'�ε�*A��/w.��|(���o���(32��v�� "V�\?}k�ue�~EćQ� O���r��p��
⪖��߬]DDPx�G\���̱e
?c@����|��VVEAS�Wۡ��m�����:Y(��~U�N��F�C���u�Mcu��-���V���L�_=j��S���)�\:�u�"xSȍ�%�sn��oef�����ՕKT7w��or�Ϝ��96}�YT=��Z ������b.�*OT�4�-�n\.���r����?�\w2�OO����YjG�9����d��՗: ���o��9�ɰ�*�%�k�1�E𷯷|����:d6��!�_��`F%Yޥ�FKS0���_�ċ��\^��������N1T�6["�v���=G�� PXڟ����o4{�|R9���e���~L.�D�)��LY~� bh���j���j�+��Q����и��)%=U�S/��B��1"liݖɱ֌�}D��,�/~֓ԚhT�H��DB�=Y��ƙ�l�D��:*��Зg�bΗ5R�M����؇���7P���?s�-r��1D��P������.@7��\e�XiBG��y���� �Mo��_X�E5j%Z�[���̽�kA�ٌMs�78Vi��T"B�?��*J!,�JS�N��ϭB��+22�Z�n�YЀR��-Ky9��z���)M��P�-!|�>8�ŧ �YƑ(��`���L�$�X�2	�w�=3�@�
��r���0VbS��|*�U..�r�~G�g�������=�^�����O�ɴk�՛�~�clٷ�ͨ�̬��k�7N��Y���8��^o��s7/;4��C���*4VD`c�����=4̱�;.֭% ],N�(�G[j�f��(6_<S�ǘ��0�(s�Ű�c���9�������$j�"j�Vmb�����n�{���8Z� *ܙ���j@;�0��ī}�w�I7�i�[[�n���橃F�e�[�G�25��D�����e�ѳ�&?it�����b���/�,�����9��A+�EG:qO��������f� Ƥ����	�3[�&�w�� 踯k�l*
>g[�
����DO��q�̚�u����BF_���g���@�C&�;�Q�Z㥄ّළ� jՆ�^B������!}���3un�̶���k�ܸ֝+�a��=Ĳ���� ���ۡ�	by�ՂX��j�7��aN�rm�JS1��6����Ǜ�NH��?�����"�M��gF8ײ�H��s��A¨�9��$w(��SoC���� ���L������~�,�)�/5�� ^��T�zd�u�+xi����i��nu*s�]�����H��ߪ��d�N�X��(d~��1��/���}\Q��0�'w�yOStլ����ArӘe�����ٖ�rF�+WMys�0`�r����W��h�����,~�ב�ץ�QGkC���3��&����̓J��~=@K�KO�� ��+�G�G\�� 2�n�Kd��*�U�.�E����'X������xEB� �M>Qv������i�^)b����Y#K|��0��܉kt0�~���|��L����0.>cQͦtˈұ�/��b~(�q�� (>����X��%Q��`�֑yq5:����1yJ��Pb�.J��5Rtfw@7Q�R6�~�~p�h��:�%�q"k����I*S��<�䡈�;:}*���>�u�A�֫��C"�T�^���aS���Za�n��Pm�
j)V�oƓ�'eh� KP��΅�u=��x=�ݼiYX��|�A���eWJgg�y-?�y+&ާ4�=�֜ӵ��#����A̐�Φw�P掚�`ι\6-7r"=3��|bS���[A},ˬ���+��G�03�T��Rh7�'�%�G�h��g���oݳ&��%Z�����υ|Q�BB��JjА�74�8p`�!y���ӯ��������ԉ�\h}���J�w�+K��4���e�P�GF[�ޞ��:��l(s�C+��_'k@M��*u$�jƢ��|7#w>Z��8�b{H/�|IS�����$��4zz�t��`ř�H�4�}���F*�7�½O�:�I��3�0�ģ{�HE̦��&\�p&UV�]��J�ZC�2+�HF�� �]6��0=S�ܓ����vL}�O��Bs�,w1BZC�bl�Ҡ's�����1d��#�#��d�4�7���^��[�����6ub��z)��Z��Yo����� K{(
�����i_�˹2�B^:]��Q�|}�0�,\�l�p�9u��>R~��K��x�6%��YZFE��4�rn\r�K͓�0�xУ�#(6&�[��b�,rk��rM��+�h��'���@�XM
��\�g�a,ڶ�$�jT2�Eӭ������73x��e�� d��Ih*4�6YG�ײiw��F8�u��\����В�XX·@Ϗ^�?�}��<��h�w�{m�=.�#hm�p�-���ssoA��;q_�>�2(1���AE�C�|�� e�D�2oۭ�&ؒx��\�!Q�9	4�ـ2���ޕh�����v���&�6�O�5�,6�3���f<\��\�o|=��p�¡{�D�awƔnHV\��CA��#ml��t3�
�a|.*A@)�7��w�D�j:�LY�r��[�=nA������� ��Z:E?�9�;3�6�@��
sE;�M�|�͚��\=�v�Sy����,}ȥ>D��>�^��[k����W
W�&G�t(f*���)LEt�	^,X ��p�Ѷ�c�����b>e�k}#�nR�Z�8�%�S�J�_��r��Lvd�zl!g�sD����@�$y�j�����l5�b�k�'K�&�,'b-��V��L8�*M{��*������ND���L?߅�+2aOy.��R Y|��ߜkJ��jK�IRS,Vw�����k��M�ϸ�?p�k��a�{`[N�87;�d��[;H<�E�&���]\�I5P������PB��
��Wf��9UN���x�"��'�U�c�Hg��.�%=vn�@��52�i�wW����mv�j�ѿ��p�^�$��;��ؠZ�B�z&���-_J7�ۣ{�Z&D��4{L44Գ�V�ъ��Uo��$�'������LĊy\�^-3�p>�|�y�x5ZHd���U���β�4T��Mw�ܔν���F	ض^Wv��ov�Y\�P�7�KC2k��/���t��\j��3$�/<T���К�%TK�Qh�r�A�G6BEp��T7���~ddÅٓ����P[�*?�@�@�V7��7�,��a�c�s�l���N�erBst�����0��yb�l�&Z���{ hT�_����f�!4!�T"KQ	u&�&�6�j�ް/gz����~����q24Bτq�*�p�]��ew�J4��N�[:�z�e�����������"��f?.=�ǅ�+-83�?dAQ��?�H�
L-�#�L��n\��1��-a�z+�R���#Iu��[��Ős0]0���ށ@�M�j�!a�Q<~덁T,��BH�)<�.V�
����RGiSShIƜUN��{��Bt�7���%�$ /ְ�tu���C��ƮL�T�r���@%:�x�B�����C�	�)qWYM�Ͽ�XY�	Q��jC����"��E�#�5����+C�m��@�isY��%\|i���E�� R)������ߑ���D�Ä!$�'t\��X��z{�o�� �cMy=3J�֖�FN����J�R�����D�����1|�8��)
�r�s���=�(c��Iu]�D�C��pC0�E���{Ϫ���Zn����?�+ڱ�v�ɦ=<��P�r>;i�vG��`�'D�؅��]8��RB�/Eס��w�n���u���챙�]f~�ێ�5@���v��(��J�)�B���(�D0ᙛ��	ss閅3��#O_L(L�{�O�56+���8ү�q��e!\�:טp\d�[�na}��{F�����y�W��@t�o����	�܊#dEj��c�����ȓs�&�2pf/���ݓ�U�PRvʢ��oq8�p��@u��c/���V��4�����6�?��4� ��x CM����ߍ���̊���c�	}t;����ھ�(\��j�/�-�X$���ڝ�/��ft2>�̆W�G��h��Bl�����U:`'Cg��[d�m�Y������,dx[���+���tX�Q}g�" .�p<(A�e%ꁎ�&$�1�_��I3	�͞|P�g"����,�&j��N1���0
�o�ny�Lɲ��	��s�^����+��\�W�i:.D��A&cR��`�_e�v1.���_=���`$��l���.�֩�{-�W�0��rY0�Z��� ��yڿ4b#�`a��ɉ�@�0j!�#CH 
�|��^>
��>Ԏ�?�������(���
mEE	��6�� ��(���%dfR�����_P�$Sj���p�2�Nrds6��;l�Q-=����;Y�k#2����}��C��'V%)�ͤ��C�xZ���u���_�}���]\��&'Ihg	ժ_c�Vk�ʭ*\Q�?�o��'Vy�Oy���*S��ƒa�w|ؼ�wn�8��X��>Q��7S��k�N��^�QN���U�(?,(Hy�k:rqN}����<���Q���&��HЖ��.��2Y��>��=�<U�]�cH��_�$n�����%Wt���5ut��g��_�K�KJӥ����Ճn�ͨ������>`L9�hN:��b�WW� �Y;T՚�\t�sݔ�GN���Ut��'�:=��HfkjA�Or�`ޞ�7�c�u�~��( �|,�u��S��ZV�'�Vj*��r�1�	�-��6�j�MO����<��t��MS�QL�W�뷱�ǆ|l�?��8�U� �%��m���$��m(�]KL_���Y�w�����`���Y) �ܪ�	Q����F��4=G�PHxv%%������ܙ-�:�`��Y�5vo����QQ���7�����≁Ϥ�e�1�XC�I]>���VN��!2r�bk�!B���_߶�F���w��PU�́����˼T�6��~��
����N�V-���n���h��S�3�X,2���5�IR�����jD��q���( ���!!P;�&��~�.�t<������VI��Q�����:Bg�a�%G�7㣃��?��$*N��*g��	���K�A����s��H�������e�<������?<bF}���Y_>V?��.�5񫒀��IR27#��	� ���-j�p��v���ߛ���� Y[KtTVO�#L<J{��Fy~�fU� �Z��r���K��D�Ċ�-�hh�9d"&N�>T�x�����kC�f�����(ب d�_�n��>І[qh�n��[�C��t-9�\�z|��7z�<����!5$�0���ҋ���tE:~߻t!C�A;!
wx�lh���g)	CM0��v��*�zA<5���mı�D�{�'��S�g�O�ь�Ao~s(N��]U��Q�����n��|�$ʋ����jq�]´����)�!��mB.	���}�[�%�)
>l2��F����R"':e��$p̍1�/��ƣH�@����1|�řU]�,�q�.(�r�-� ����G}^�E�B�4�}�¬he��Ұ�9�G�MxΏW�լ�?V֦�e
y~�dd�DL_������Ҫ���ĊKQ�����Fc~j�!���k�Ľ�q�|^���!���t���'~ѪV��o��d��H"��.QN��;���hW3}�4������Z4{tJ�����������U�A(���q��e�	�)"52�<��X�4�L_�z�l�Z�;|��Q�߰s�9^u�?���z��^��6=��~�͈���݋0�������^���҇@�˧2
,�P+b�؎9�e"�?�d�I�ο�>ϯd�Ki�15%�H�^���A{����i/���2/1�G{�?%�'��$�yxf���> �m�sF!OQ+l�����&;���̤#��t��?�9�T%����:��Rb����ں�U�'��g$-��c�Hڃ�-( |�V���Y�f��,�D�k��+��;>�x��C3�S�C��lĻoD|����~x1����O�Kct��C��>&T2���`�."���)[��{Q>CCn�r����k7�]D��t�3���6pp1�2j0U.>�ѕ��I	=��J �5ژN�`��k˳Z�?��ϰ�!��k���<�"e!*����R���5q.�K	Ғ��|����`죜���\��a��&���|Odf����7Bf�1Ngp�rC�[,,��\��s��t�2J�����(����5�O�ьp���p8�؍.HP��k�J����6b��kG�֜mx���f�/ٓ���mV���qow`��W�O`��L�\�eEBm�uB�*g,&S«�8��y���S<��1��>$�\��� |�Ql��tD4�vx���彴��m6�ZbЈ���ͫ���6�VI���զ�����*����Ta�'P�Z-խĐH�2�G=#�O�lt]b�v'�g�~��sZ���c������?���"������ 9#�|���ӛpO�q �Jq��;D�a'��D /�S*ΩKKe6r���d0P�f�ڄ�{�ݙ����I�c�*s`���s!6W3��
/5̢���OR5��Hz:P�g�w �s���'�4K���]��VH�����a�Fџ2_|�q�����?�$E@MЩ
��K���J����u'���1ȑ�'n֛-.M��'ܠ�j�'��!}��},s�?�
�����k�.�˗�9�f�b,D�IL�6���%��W?w.�����pό�f9�)&�C]f"�F eǐ����� ���}�jx4S���v������ʳ�e�����97?�i����x&+J�M�)�\~[�+p2%i73"�[a0�[�׀�Z�������ⵑ��´l1Ӈ�������f��5��r	�����[	�f��������m�J���ёZc���>ߠ��t:��ů��r`�|�E�E��Z��&�Hl���,L�>�ݧH�(ej�;�l�&]	�RPox������T�4CW�S�a���O�U�*�5���VȂ:��3kq���lQ>bw??O���cO�)�(iHr�Q徨�s'!������e����V7�)��m��&�;S�����*�F}6mG7d�1���sy<Hq��G��Fl�����_�F}Ô|%	m���TZ��C���`_����J���T��}��q����~�r�q�V��"�	t4J���g���q�+�"�#�,NC}�̗��2$�c����Se�F��/ռq\*�Ͼ�_䨔���2�؁ZF�%���Ӽ��]-×\V��C�ã�s���3�RtZ<оj�j�����7T��[H[0/-��S����g�5������1tCd�k(H�*�]�N��)�I���j�IA�d�bsG�<7l�*<��_|��$�G���@*���5����~���p��ftQ������DK]=���p'�N�ɷ�J1A�u6K���3u�/��T솚TTRU��Ͳ��ґ�q/��w2ɤ����,��D/�Gȟ�o������E�/8& :�/]�>�/YR�+��qJ��i�z#l��vM���0�Ԍ�F����>���Y�#���l��=���$kC�� �h���	�`E�߁j��20b�L~�` M~f ���t�b��?O!�46Np��OJ?�����ywu�a.y�iKJ���<V�S	i�!�1�YF@P�����-���̛܈T�0'�$��"��cÚ����?	]7�|�AX90���*���Ɓ������Dz�
�sR�Z����ZD�y��d ����0y3zgx�o��h�O�)ל�s�K�ލft@�N7"���r"�o֚O�"�6�4A�u^~"tY 0�+|����^��c�8kn�H�VNޛ5��"�4�Ħ8<��Iʮ�A\�v��hޜP��Q�pJf��0��	_�ֺq}8�ϝȈZ�/nG4�p�<{���<X}����	 �_��o38Ǆ��T<0U�x����cS��|z��{VO����o����#�V��'��[�?\v�y����5�a�Z�ĕ����+���[�IC�Dn^�X3xN������g������N]�׹�d���!_�$�IJ�vT�:O�}�R�� �ˁ涘	�VAO�k�uwLI�d�'��[	H�D�M�qtr�F��mr�^���8���9� ��ҝXKX!X>��%�7�!%�z'�<�"�R���q8z6շ���6� )�	���kx1խ�ƚo���̉r�P�ؗI3�f{�ÿ#�c����;���t��.Q%�Y颹�Lӟ���w�0�W{ԧ|?_�b=!��*���؏I1ތ��YM��#���᪯�Ģa���`�Äp�У��;�J��C�;�X��X��' �W)���~3; ��V/:aͼ'���凄�<�w;�=��kw(��������mO9PL���<� ����t4W�i}X3m�%E.�u�/�p'<�{,NP�l��iB} <�D��8�H�:~.�L����ї�½%�����w�ׁ.^�S���.f���U5�u����σ�IoI�V��QqNќ�gbq1�-��{��Q;��x=4^9�
�T"�)�u���j1$��T�ޢN~�i�,W��zv���߫VR
	zK�$6��9Ǉg�vC���bL�,[^�Rgu1�cw�R+2;T��2ŎD6^�A�W�$Ӵ��T���AON��m�2#&�W��p�ȼ	?�b-�B���Sln� �H��:~c:��Rg%��X�sTV�_bx궙��e\��)N[�z߇]s*��7�je����#)_ߛ��,ρm����bIv��qq�ix�#3c�n5�Pi�P�$��ִ����	�W$Ip$)e��ȸ��ҚH���^Sv�q�5%��(�UG��{�����K0?�%�:w�
�L�����
1z���S��n���v�(�wىý���G�"G9�Fڝ(/���0���"��TȎ�Dh`�� ]��%�N�Җ��0�9f�)�0��u$�u��0&*�L䩕yG#0.3�>�8�T������+Ŷ�n���g�p0��#�Pc�1������=�{����@�����g��Y��f|�C�ި�eϤ	i�v��w~�4b��N(CLK��t�WB"c&�t�_��^�BҔ;�,r'F�q|qd�a/�98���o�D
����]�1��\:�>��D2F����O����D���������|W����;��M�D[����ѣA��1ef�4aJ�QT�lYNR�㮽
%�Ȉt�°����2`a"Rp�;;{,9d�f�ǝ�&T@O�[*R&��R�y��]����M�|���L�݊��$6�`�L=c@�Z�ߡj�2b|'¬�d��bAe�^���z������	���Mˁ0�+�S�e�c���A�5�w�	@�ޒ�B�OS�9u��� ��i�#��TsM����o��aq��[����.�٣٢j�ѵY�<�G�Ec�+P�ǞFL��?Sl��g��!�	�]�����?ހ�+�l�������&og�KK�e�少�x2��_��o�ћ��WRٚ[h!!4��'��4�F8�҄��8�i�'s�~�&�eS\Y��.H��'��ZQ9J_ᖊ�!���}q��,�ɥk�jj��
����VI#�k����ƥh��4NU=zw�q�-����'����k��7#|�$��-�ژ�s��)���|��S�ǂǢ>ٚ=�� MJ!���ob�����5�)�=Q�Q�Nܧ�b,���^����:I��cy�	٩V��+~ē���9wj�S3R�w9s��X֪&Gگ�Gֿ9�d��c�>�a�*z[�\�3��+�ڀ�f�Z� �Df^6͕g��������dx�Q�$�|��$K�w[�]7Mo�
z��o�4��E��E���`��o�v���������d�E�O�+[�EYX��n#�Ԝ�U�J�G��a!�|q �6��W"}������������UD����k��S�%-���i�tbU�f]��3��g�ƇT����(E�\s���7�cP�KQս=�ְ	�"Y�gw�?���j*�
d�&��(�䊚e�R� �]�$ҋ/�e;�i��"(�z?�c��� D3�Ω���ٷ��b�31'P  �v��ۏ� ��������g�    YZ