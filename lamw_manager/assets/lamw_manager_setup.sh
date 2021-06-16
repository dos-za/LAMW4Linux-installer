#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1867317896"
MD5="7d70d084235e26a187548caa29975ade"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22348"
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
	echo Date of packaging: Tue Jun 15 21:56:18 -03 2021
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
�7zXZ  �ִF !   �X���W
] �}��1Dd]����P�t�D�r�� ��z��2�"#b/�-������[�۽L�h�fܰ�q��1XjX:^�u0^�^���h��)�4��	�ʁָNMͲ�x���_ �bK,���8�\e8(�1?��Xv%z�wM��~�#�?�K�"[6��;�f�E��@�e��	����;����߶���5h[��t�>����	n9����t�<�`p�!l���&׀��]�`�̚������<�QGI�$�p�w���M���v��.�̴2�Ѵ-���S�tO/ă���c¡6�c�~*U�������H����7��,�~���L�~2T?�Z�O�R�G[Ƞ��9p�����ؑ���{�H�"�)'0���͐$�,V����հ����R�G�&�C��|�:^:f�RM�b�]��@�Y��x��2TFs�8��=%�J������O`Y�`�Ŗ]@%��7KɢO�WL�9���$dsZ��r��v=F���xI��/��<HW�B�v��!�,T�76��ɾj/�[�,��c�XI'�Wm0��������-�Ӡ̓W��G�t�:e/��o�:������E�*l>.I-/	��鱕�8����,R��P��#��I�Bj":�d�����3��r��������8!��t2�����`�y�ڬ' �4�
V6��@ML �0��?F���X����sQկ!X��y��ޝp/�dյ!A����� F����T�H_Dq8y��.e�Q>�Pr�	����m���ƎP��&��( 'Ҋ����ui;���Ŋ����4��	����'D��=kU�~�$z�qE&E�"���Kt��m1U~�^����)�ZzD���1-"ys�MJ��N2���EymY�'����Tx��c'F������{J��kn��Դ���?DsReiW���&�e^�nxy�f�S�a��7iġ�_�����(�� ���g��q�/�$�`R���h����8i�s]Ⱥ�4?Cd�X��b�/2~y�9̚��o5�)�����;�Q�������e���}hdL���f�}<^�]Ŋ�xߍP�*&:���pR<'ԍ��5mZ� KN��2�>���`��H��/|A�2,�	|�&���f��
�2�����K�uXc�2i��ѥ�)��8�ݸo���g� �oL�i3n�ĕY��[mE�ȵ@�n^{��WV^"���\2,���o@�+��/J77�j��l��n��3Ί7j�gZ��d��#� �uj�*xl�P�D�|Q��֯v����t���G���|Z���щб���W3f���K�`T�9�/0�.;^Q�T�5�Jmu+z��)�x����b�sq�8�yb�K�WV�dCܟx������o�_�����O���C���'��3���q����x�5�cD���\X�5C{�~�T�1�j�#G��؂�	�ٙ=��3`�A@L�&�xr����4e�ac[���_�"�aEℒ+J�!K1d^>��h�E'�C�7[�l+GSg ����ǫn�]ї��m�l�/�*��I`HxUپG�:���H�忙m}�@".�\�q6��\�l����`����=�`�z���6.�z;ntkg4c��!9��p��F�||Pc��}�w������v�p�/��2��|,Apz�2#6��~"�@3��6`C���˝w�����)3SN7��`���32u�2 <�lC4�o�qt���3��7�{�(6�*�Ǧ�s���jfW�J�"�G)��K]�X=
������>'��As�DR��I�آH[�g�5R�N�R<^][��a$�VB]�=S�%+��`a�{�hz���ß�iq�^�Bz�I��R$H�.��we�������ES�������@�*XW��LQb�e�/��NU,��H��c�&���:AV���̎.�B�wB��{��5��NK�C�B�g����s�WY��`�D��d�<�~Əi5D��CgV^�|�z���}0��Q��nW.J��b_0�WF��������h���F����;_���Y[��~�ͨ�u���)q�WZ�w�œ�����n�\m+�@��nw�U�}�s�3���5�2N
�n���+7y�I#�Z/��o��剫���h�GX\�)��r0����7���͕�ZV�V��TU�<�PƮ!�a�T��5��̜��2b-�q�؝`���	e,vI���ݍA��J��8��t�	4#�qp�u��e%֚9�4���;�o�n�@}�#�*�ܕZv��;쐏���M�SX!���r.O&��#.���.n�A�7�![�L7H1��4$a��b)m��2�{y������RR�Lp�.ZcZoi4+'DN����98�w������JQ��Ơ�7�Z[� �����c$���?�4�O$�����^Z��zWk�-�������5w������|}r�Ԑ=V���a]z
fyI�&ek6Z�d�VA"<v}JUK��a^)�E}�|�n�L����$�"�>�$�PS�5�n�~��w`��9���g��EԴK��)bڣ��J�8Yd[�"���R���T��g�Quf<�����mLC��`H=���L^�H�	�hh����1`�<z�3[,2r�9ϸ�'�Mh��u��]����qI�8�1*����2Y�40G���Bb"T%�d���/�mю9h
��.�u��Z�r�	OJ��l��@��uc����J�1����A:��M�d���84��&�Uw]�:���x�V뗧!R0b�5��G�������>��"�"u1�9[��^�N��"�M^�tK��'�,e�(R��y$�}b��a��O9�t�Tr�KAyZ�%�C;>�����N�Gn0� �xen����b���H/�{1\�R�H-�!�z�����ߵ�d:�[�$X����W�)FRA�V�����q�.4�~�n���>����k�c��C��W"1A�\)�dvx4�[�j�@ϝ/$�v�&���c��D�U���L�6jkqu�|_���{>��e]��\iӯ���J�N�x)� �?�>�#�ٗ�2���	������?��50�!]9D��`�w"�qlY�2�tmjn�@�U�JDE�(U5?G52�w�t����K2��	ٚά�Э�#���3;��N7|g��JP���9�,@�ןo`,qV*7����*��=Gu'��J-�Ժ}�N$�^�w̷K� ���������Ź��2�N5���z/o��Ei�� :!�]?��)⤦MS|��cL������ e(IZ>-��u{V+�����́g��	SJt�p�������b�/�3n�PRg B�5ő���J�&E��.����>[�	z������7Jj�����AIJ�햣�bSnˡ	���bAƀظ��M����L�2�3�����tFGt1C���<G-#������f!���^���${4��W_�6�䜖 ��xO�SeԌ�
��5�-w�Ҙ*�ۜ�9�R��zJ7l������,{F�4�`}H	]%��'e�5Pu���x��J����<��x_�>�RvfeJ�e��dza̮Gd a��E�K��)+��<�jD�Z|�\�9&�Xz�ݰG���w޴:��E�a'&�	�%Q}t��岪.�Sa��g�^�����y�~�4��s��Z�[�! ��qu��������L"ɑHf�q%Zţ�Ѝ�����~ǚ4+��/3�	g�Y`�@���i�Qzd7Bԛ�tsd���_���?����Db'��G�(RW�#!�P�bO�A
���ƌ��%�s1�/��đ��G�ި�V�Y�%�����]����
�X3�r��\܈��-���k��I�x�ɠ��-�I�Z�gz9����J?�{�����d�}�ط�'��L���1��*]B ��n�ˑKj�)4T�5`���jё��ccc4��L�]p� 7�$)su$�|�9���"9z��(�g��/��M�N�������w�P^��'Ԑ��$����o?�7^j��]`�M���T��J3�+�ԥJL;w���{�W�.�c���'��a���a��%�;n<�
�y�%��'. '�<��*e\Ð`e����F��-=;Y�<�{�p�F�raj1ZTl� A��8%sw]Q.����-nVv�6�
�:�o��T��j��F;�~�IqT3�?�֮���i��8���OIzgZ��	�3w�T�����c1i�p�(���A�F��RL3���%3�r��`n�p�]'�@o|
�ccKD�T��K�̹��X����Ə��1Q��2KQl��:R�������	�{J��/1���h��y����{��(�ɞ^���WM<�EZ���� �+�2K��Nr����,��j+ɧ�:��"�?]T'���0��ɝ,�H���aWڤ���Җ[y�U�&���ѳ�,�.�tP��vsF�lW��Vd��4���X�u(1g7�5(�%r�mt�ܭ8�B�����#F���
���Ԑb�%#g3D�-,JU���A�K!N16��=��*O}�=8�@nx���8�gMB|�h+�����a��%J�59F���,7|0;ɡ�6)�U��z=��b2��<����Y�.,$�	h)P�2Yg��KH�'�" W�,φ���4eC'kM�?��J�G67R�	�,g��(�&$K��-�R޲�I�sHw�����*j�<�~Ԅ�m�!)���d�3��ź핐�b�ɿ��En�,��2�3W��n�!����rs��Z���boj�Z�=�w��0��h��Ɂu�wk2��iw �̬�H&�)m�4��'�U�	��Km�������f�H�t��n]�3�����=H��_U���&)}�W�A	����3F��)]���u,Y9���^��}��Y�R4��h���܀|��=�lu��T�w"��=�ܒ7�[#_S�[V]��_�sЄLX�w�I��h�$��8�)�  �8�~/S�� \��ƲSI�4>e���|����A��#zEz���o���c�Bֿ|�I����\������v[&�����j���K��x_�(����b��-���Z�6���2��xyQU�I��q6���Vb(ս�%��b�W-����Q�=աF�|r= ۛ�E�<��r����Sa��z��8b�-Hjeh�!�U��/�N�v	Lˏ�C��ǥ\����1M��3*Pr�0F\^�(��@�?��?���9Y���+�>@A�&H��L〻�1u+'�##1��M8�捺�E�q~����4�Ժ!��:�,���R4o������5�� �GɗL���1^Q�~��	�~�ї93�L߰=fL������6�2Nr�~������rJ�Ȼ`��u��U8���'%'Jg6:c���3����ї�:G��'��-�*�=�d?�7E�9���.�Q�BRL;��׫�[�&go��7�^��+n��7�fQ��!��Li]����"���m^X!;��8�C�Wc�W�+߸~_�S�G�AH�4�yW�yDx�'ݣr���Kp�h�K�`��~������Q�X>��o'����PZݩYh�5�������\{�mr�m2��bЄj�8��x�R;-OQ(�CSg-kJ��K���d�3�5�C����%��c���dn@y�_�7!�@)ՌbA��Ee3\�ZV��:�N���A��-�
eD�/I���-�!?�@ ��M��5��O����쭨U���� ��5GؘXb�$C?�qN������JSC�.��T8͗$I�*��)����\��ٹ�KJ��7L.ں#�<�/��K��8�}��:�K */1�Z��s�Ff���8�	��%xrh�s�v�]xeQ�Gi�����_~�t&"��h��¹p�T�ipX�4��5����_��К���uAЈÛ'w���h��Uդi�;�;��a�{&|:8�N��⎏a��C�@M[|?��9E-�{�0b�����+JVd- $��1@�\��e9($����ղ�L�9K�����CX���I&u8��鸀����d�",v�R�Qt}ȣP����=7��4�\b��({i?W�R�Q�i����^��޼�>0*m�F�����73הrr�F5�ضt{ah¥�	��u�7�aDP�d�ha�Ӥ{�VD�;�p( �i~�q�r�lI@�K3hܻ3�v7����O3�*��*���h]�%HM�wu]�칓�N�<�.Y޴N���!+&f��C�Vw쨷I:�q�V�������k�Q��^����8��T����r�I�n���M�;�50O�"�� �d���@ɭ���M���}9;w�����%I��].]o�9��MM�W0cu�8�09��x��vsMv���;b+��se`�����!�)��S^6�抻d�](��dU�;N��Tt>y"�F|�ʇ��++�m����  �F��s��N��k��w��1N��r9�|�6���� jB��-D��2�3���6E�?��@ &݋����������Ƥ��C�~_���)^�t�u� `�C�ǜ����% k�[%�v���o�JSI�)����B2i�7���$�~h�J��h�2D�R����Z'6}At�����F?��Qh�2����Q�L���u�����"!c��-H�}��\
�����K<D$-t϶�UZ+�*��P��Di�8����覜�.��]p.׽68)���uE��8���.�ćm-c�l!�\�po����p�5F��MS���qAc���Ϡ�8ֶ�}U�.�T��>��/�4��+��=�.�#W�T#'5B����U��E�g�f�k+�xd>��A�5���0x�"�&+�JQ��|����tv"L����s���mr������{�Fб�V���1я�,-��!9:FY�yy4rm��r~�2s��e��8�f���_��[�l���́��1X����51�hM~���(�����0J<���v3���\<6-*��\̤$e՝�n8U{��R%� m'��擓�O�Ǜ�;H�v�,!Ϡ�Cp����6����j��c�r\����3��vә�;�V��r���+�N��uw�M�Ʊ*�gm��Ղ�\�/�m��"ӷV�Ng�5qW�~z���v�Hg���/����1���r{]鼵�F��3����h�{~�g�M���O������&	�����EY�ʢ��l�"��K{���f���O���=%��y����n����Đ�t�JX��N���0���T��9� ٺ~��Fl
ړ��@	^�b8db`j][t��@m�1ި�3-����潡ʃZ�ǲ�Kr�l�ۈ�����r����Ѽ$[�_�Z�#��{.�Q�x<+9��؎r`��0RB�)�Q1��	>�_Z��(O��2�[��OV���:5���>�h�3�_,f����LX|��>I�Q���arh}��d�W�BR��Z
��s��[��~\G�tߠ���|n�Sd�<h�Ѥ�|�tx��/�P8ٴ6�<{a��"&�]��p�E�"��"�r�%���.���T
J� D���s{��nY��;���y]&�@+ϛ��Nƛ����ee�t��ul뫄��S��A�9�X����GFmW���z0,��Q]���I3a r�D�����G�zF�V��q"Ȏ��3	0��<�ٍ��&[3�l�\�{ғ�ƥ�C�y^����IDI
%
����T%UK	��`��*�f��`��e���H-��9,�h����	����}o�'>�s�L�U0�`��[Hz4�48\�ٕ�򹧣�~�-;�B��i
#wM��t��X����j�&,Z	6|�u�Dh"�Q@4�<��Ѝ�@��G�X(k�5��}���[ڜ|�*̡��H��R��U�py��~8*⛔�����[�g3Ǧ\�+*=Q���Ʈ�F�4��T���.���(���^^#֛H���?����>('߉���c6UG2b���l�+��%�Q?����G���ҡ��݀3Ԇy���4���V���Ru�̛]����襛�R���y�?]V���?�f��MhՖ�@C�]�9Ѿ���_;�o�Jo��[���O:����۴�cdc%mW��]���`IY?p$ܽJ*���nã��Uc��{�gl�����hc���d��|
������J��ٰ{}�:�O��.�{s�Ś�o�\�����ޫ� wg�p�Jx��Ǆj}ӊ)�ھ�F���Gr����%Vh��	-7�Ռ��؅t?�؅wE�`?�r:�.E�;�>�Ʒ�DA�����ԔM�K�)0:�� ��5,��u4v�����]eLD]�GB˜���I�Ӫ�����#ۙ�8�A�����I�����g��q0�DC5���/��~^�(��j_����۱^�1��G��H���'9؞_�='o>h�".J㴌?(����}1���B�r����-�5�RWA�F��on�<e�c�Y�,�/j���O*)p��N*c7��ە�=_��~�@�r��U������v1��j�6F���yQia�ݔ�b8ߟGr�+=}:���<8ꎊ.�q%�9��j�i������3�pz`����/zZ;F�29�ݢ�XKh�I���1*����ˁF�e�X���}C���\�����u��W��J�a�}�8��=40���
7xK�H�
߶��Ј���}���&!:{�b~H��&��]A�5�@�E�G��'*�����Z�zg��:6�FgEO�eu�$�'�nK�D�k�����]E�Ol��|��O�tz=�勽C!ׯ֌�q�!�Ѷ@� ��R�uo�����%|�wqL�Ӌo��hg�Qb_s@q+7?���`b��
"�X��FH>=�ѝP��n�&��K��I�h�m�xk@�O��s���r�{��-�Dm�L+�C�񠫳� 2��p�L������P�q0a�s�d�lm�9Rg��ZLڥ��h�$܊�f�/��uMKX��P�or���P:�D��*�v���o�1f�V`Ue�����x��I�J��k�WD_�L$�oS�V���ޛwr��`��!V
�	��s���J|����P1GPi��j�ً��0S�;�~L`Q����(�+2����&�[�m�B�M�%��q�J����.�[EIf�݋aW���c����fi�a21�[8C�`��
�yd�1��|)�jr�����#�|&�p���X���M[���kCֺʣ�`�f����S�W�����֓q�>lf̦���:�/�~8a*���Ś�$�ꉃxq�� ��2t#�E��iO�cg
T�E.k�``}��t/O| �}V�Ȃ4wS|�[���D�~��EUZ�N����� ������ �3��/�) D��ȝ}��Q�Vtu:I�Ԋ}��]�΅h!���;�F�ʿ��M3ՙN�(��E���sn�� D(>��i�t���=%�@O����ʄM�ombZ���bD��ͽbs�E����d�����O
�eɎ���= !��a:э~KU`�!�̒N{��'a��fτ�<2�V���Az4'@�w�n&��R�$l��q�l{� ~�������-��V	O�5a7>!�Sc��Y��W����*@�����J|2�fJ{�p�=ɕ$q�'��m�q(J �F��o�����/
�pF�;y����n} T�'��Ҷ�\}ҎHſe���x��N裬)1�h���Ϙ_�ޝ 7g]��������>��S���f�g��pT�����v.�waG�	g���I�����X�ue;�����P��
��uiՑ�.�&���Hu�C������<�$���~N��|�����,�|��T��v����Z[�bܕ$s�r��>�8[M�
#�3To���kk��g�+o���d)�uGI<�
����,ζ�ՖZ�Vc�<��n6���(��F���)�V0/*��|n�h�0���0�:�nq�@�wC�U�(���
���$��D$�৳���~�V����7����0�5��}���Zv���5�����OH�"f˚"�4{3+��џ�$
~��~烸��=4����ճX?�2K�aV��o4��֘��]��o�(�!ga��^C�Dk��Ѐ���Ŭ� �\h�~�@�:����NPic�����f�i����ʮ���Pӳ��QD���|��~�=Qo~l�SRblj;5[�����l��۔�gc��欰L�s���`�A{*���/y�)M�:��aL�sh��LR�(&�*�6��t^,"� ��k�U�ӓ����=���/�!
`�uq �yo��?��e:ʇ�����V
��>:���tי�T�\[,�{=���~�$g~*��'BP'5��3��'�v�(X
Q�y�;$:?�[߹����RZsԬf3^�:�$�Ĥ��ꋋm|vX e����w�= @�����Cɤ�}�G���]�ޔꤝ:ɠ�~%�:��vsc��u7/��} �h`�;��IƋ:��`����6.��9+������~�2���V�I�d_���"��a��z<�k�(g�;Q�#�u���w�,��w���R�L٨9l���G�gE�nGw�!�����3*�}��r��/���x�#�Cis���3`���w�`��Xz)�g�m��u8�F���e �zkv�!l���I��%��f��B�`#�������vɆ�Xd?�/r� �t

cq�y����*.[��p7���8�
4^��Ё#��
wV�bs[FT�∝��g?�	�w�W��\��b#d)�0|�Z4!,k8�v�Z��b̎E�����ŘM)��|f��l��_6O�e����F��92�ܑ��D=�$��Q�0��/o���Q�K��}�`T`����t��`���\'�g�Rx��}K���jw(���/�/����f��p�3>��Aas�>��΄p�������L�ypS#~�󋰚�`V08M�x�|��^�T��2����[F����E+�5}�:"_W�,h����>�df�ZW8��^t�7Q�B,�|َ2���Z�����mZCVtNa&�O��Nw��k�*�b*�莞�K�Ԑ/7>�4����wK��"�@�����6�nN7K��gnB%A�`l���	���4^��#���]�	(��@YV�"b���ǙA�q;��Q�?nWPV�L2-�4���C3LU)���G���rd�*! �$;�K���y>���j�4�K�9��]�>�K��'#5���ι`�%+9�dRa�R��C1�O�t���Y{٩�廈/7T��?G�#8����}�G����G�s�\<��SnJ�'���E�H���;�?�o�Z.�$��m�o{7�G��*���s��n��4\iu0%����jd�z�}n|@�_#&ϴ8����,v���]��.��4�i�{Ã�7���d��R�D� h�N'^�M�(��Y��W;N��gM�E�R����+���|�&r"����Q7_����f6�J?D?x(�?
 �{��M^^B-��70�`*U0&P��NY�;�^#c��vC�\ �hj}�R؀gI����LH���dA�#Ą����T�ҩ�[�!���ܖ�Q1&�b�#�u{����1K�~�~�{%�R���}�'�KR�	�(t�����>8l ���K#��7�����/� ]~5O�kR|�� 4^K�<g��N�mUJ����w��>o�ܡ!A%#�Β� �wG��SUͬI�Ț���FQ����2�޾� e��;����+		�~�rK��y�U:C�4������l\pGە� C0�$�h+i�i"�U�uDgܖ��"�LϠ��ӆn�S:�2�1O@N��R464V��Q&e����E&�FD5�j%2ƭ�e�L��:Z�B���!^��(��Y!m�ICz19�_���iy{�����ﱅ�ף���
I0�[�2).�Mlv5<��|r��<f}S�/u���5.���YK·�� :Dq�t�!��`/"-nls��n6�w��@�׆p���~t��{Sim�:��wU����N2��� !�8H�t���7Ip�V�)|rV��b��#���:x��-
���Lu �!G�X�>˪		����
wa�	C��@��L|*&́2`�E������7��e��j�w�����N�$c����`��<X�5<�y1������ [6�ݸ��ͻh;UI3�'j�DB��%8��Gpĳh�����9eX.���?Cn�f%C CJ3�!�Q�'$]#�F�<�S��ǲ3�� ���*L�P�;[9:��j�܀,I���&�ma*�����AM���S���ד���;.@���, 	�
j�ȴ�A�0����DI[�|����#���b	���x�S_���.���v��u�m'#O��O@h �����v��'s'הP9]7���A�b�����X��;��/�H�����x}��7Q?��Ed�L��tH��Br�K�6^;�P�]���8������u�
�\�(" ��t�_?϶蝘~+U4��z:[��D�k�b�Ty�`���H>�ǡ"�ܩ
�|]N5zP.	ї�1�6����Y� y�J�a�i�q��._k�G��
/d`��x���r��x�
���2�����m�~�w3Gg�　P|S����UU��ص���JF�T��7�~}��&=����kM_�!G�甬dԃ�d���]d>��؍���MY���C�ׇ�*��B'�>��}�F�+��b��d�"�_|,�%���
��S��i!Ŝ�Dȷ��W�����J�%Z�8�8���@��*�ҍ>*18=�3x�0>�������>����=~��S-���-�@^5��K 1>�볟��A�X�g6\�t���V"�	����C������8�� ���P|��̩P�6�b.݆�.��q-���T{rJW{�y��|G�l���,��$��n"�:���*�D�k�8~��0 �á���{{���g�J��F��sQ��*��s��ջ�<Z i^t������,�����|7`Lx�������rT��a/F�겭pm%��h+�[�U��z�?K^*�@�Y�03m���PU�'N���Gÿq�t@57|���N�J��"E����Bb�S�����1���4�@������sR�㔻=��������VyL��f�Ǽ���O��G �Æ$\�7~��{�-�q��֫Ùl�V��CCx7��Vŷ������!X���:x���oG.pxҁ[)������d�I��4i�<�M,�k�)*
�����_�р����\6�bH�*��C#�D��;�x.�N��JY9c����E�۾��9+�B����� �	UJ]�B����3߁ҩJ��na��u��i��KM?no��0@�7�d��KHi��o���503x��<ř���6�K�ƿ=��K˧����������cA`P�
?7<�y� ����W�u߬��
\Tz���"3,�%� =�K��1Gn6�l0m.�f��!ɘq�|��ZC����D;.��^r�9򻶄n�P^�|�%�n��4{�s	]�u�Q]��K�Y�v�nYe)g��پ�)6{M��fr˪�9�l4l�6��&j��@9�f1A���f�w߶h����h9i��g6�eޅ�D�}?߀K����a/�>��8cx��yNPr�`,���M�d�AÈq����c����6�9����4��H*B��ȟv:X���=w-���sD���z2��56M��+��졡�rB�&�a�GO��eţ�"˜S�`�f�D��I���6�I(D�ޠ+Ss\ۖ���;�b�Uqm���H^Ls�b��G�Ҍ�5����x�|Jo�N��a7�W����:j����x�#5d����C^M�ے?ğ���f����_s2����'�t�nBf6k��`C˷ԊVJ��	T��Ư�o�_�+$t�[�vD�����>BĈ��J����A1����D悂2{�O��	�:�dvq�X@a����1��E��<���c͉d��k�ذ��܂Ȯ�E>�DG��>�[�7�3WC�	�4Ob$���f�� �(k2]���M^�{y�]O⢵;fK.v��1)S��g���{Bs)(;�����^S���kq�rQG'j���JIt�ܩ�dە���yM�
3~L�Zoԕ���BU�gXǐ�i
��g�o~��"�OX���z�۞����g��G�����Qt@�4z=23��
�����#$�p�o�X�83�	��MD�-}�Sma�RX{���H`~�Z�4��C�ߔ���>��aD��:;��W95���#H��9��,��Y�p��pI�*�����F���2mrv���m#lS	xҹњKr�r�	�}�l��ȅ�������x�	�>#mb�A/�|���H)�Y��'����
�Uߣ����,�t,<*��	�T{�PI���E�/m��G������ȏ�I�g�.���7����U��_��>��w�&��1kz�7`N�~���n��=�e�I��\yx,`;qЭ�$�v7�;a�_ ה�h���h�Zû�ꏴ
�O��|�I>ڒ�p%֋���ҥ�Ɔ�C�h�ՓUfpz�N����M}9)~�J�Ȗ]�Gt�vx�$�LhB��L�{(�n>�sB-e�����"I~>3?� {�o��_�?�-�u2���^��1�`-��-�r�'�j)�/��F��Iߓ�^ms�,�8Վ�@�֣9!Cy�q��XK�U��\(���q�6�x���r�_ Ņ��~Y�3�Ke��Zx+��oQo�N�=�C�סhn�w��\ {��w=S@P~��<>�)`Xd��Fp��!���h��j��yey���XE�-�>n�3��Pw����:�n�\k>�x��x�	�П-�;�%���%{���i���.�<Ӽ�-�8>,b�/\4}Rk����c�M��}ZÞ:u�c�A�*����3������"��x�x;2��3��{f���Z�'Ż�>�w(�14>��9�k�$QS-L&�D.:��O�l�ν���`��N���5T�	�&7��3}�����|�e�-i{]���&6�LN(ӱ+z��"q�@
LL��7���p�c���&��6^ئbk���W������ӧ���k�?%����wT��<�qv��%��ܺqT|r���Ȕ6���_���#�yE�㖷��5���4ZZ��b�F��Oj��t��+�p*�n||���w�\�t��FΟ)�T���&G��B5���xkf�����s��^�j< ��̔`5l8�������/=I`ʬ�y-�:�+ӣ�
n�E��@�LF8����5N[ݫ�Ƒ{�Sĵ�xs��2����I
�Y�eޣl�v��}1^�^M��3�י��]�j����w?qҳՌ[��N�7*����f��t�.��%*U��d^O�G �!2g��������I�Ĳ��g�;7!���m�Sq���2�ZM�v2[Ө2����47Ro��_�>�8ဂլC��bKTn������E���� ��������=�� s}�ߋ�R���F]g>o�K`�V�Kt��\0�̷:��jv
�M��w� �ؼ��-��I̙�! ²���MSa�vp��������;'|�������.�����`M&ٚ
��xb�V �h��f�b!Jι��������"ۦ2�F�ġ����\
��@[HZ�:��<fj]������	3S&�s�&1O��
����D*��˻�o�5�j(w�Lf@�HyƑ��ر|��|ˎ��#�ܭ��Am5�޸�!���N{b~%�pM&�]��L��v���aD�i�c`T��ۼ5:�R�r��5e�c����WlV����h��c�x�2oh�� �#�G�Q�4���<��G�����1W�(���#��\+�T%̭Q�o�^�A���f����7��Z��xI�Z[4��E���L��acf������O������������try��,�s��Z9�FQ=�f_"�ז�=߸X��'�B�������#���J<#�ǲ",����<�'6�v�"6��%�A~qj��ë��Մ���k�z���t���������KR;s"��'Zu�z_���{��\�����?o8r!���sT�J㘎B�W_��-���d���JL����0�;y�VN�]}�/�?
�a�^�f�Oo;� �k9��V��qwL�&x�kb+fZd��H+��z�lx�WlL�sؓ�J�����]a7`�m��g��L�D�'	������@p�g��=���nSѬ�k�������5��(߂���v>(��E����H#M��Y�9x\���e�B���{���qz �W�=�ĞI4^y�R�ur����:�hx\sq�k�꿼��Q���A-;ޞu��,X������5Y���O=����2�U,���U��'�)Xg���v����<��V�-�ʄ����҈/]����5�1��9�[���M#l�#��$5��l�X��&*l>1�r"K/
(t�7�M"P������@*�(�, �kVC /*�90zXIVk���u���贚�K�T��j�I`*��w?�.�}��`gZƣ�Ep���Lo��m�S[��h>�j4	��� t à�eT��a��5�h�펵�Qg'b�.�xܑ��% a����"�#�����wh8S?�W.Lm+~̬��٭Z��[4o��"i�ͩ����۫w��21��m�md��$X�o>S+tam�������P�ž 7�(�j�']�8��� ��DsC���כ���Je˥J�3챒�T��7U�Y ���o�n(�g���	T|���G+��:`��wI�  ���	�*�U�n7[�����K8�?� �毭
�=֝7@����n8�>ĉsC���ʫ.�73So�����k�D�	�R��3/������B��'i�G�쨙>D-�8L���|v�N9��1x���z;8'[��T�y~VZ?�RNFm�K8Z��*gNjT�׫�;�RԞ7�:�w�}{MK�~f��	�ydN\�C�,wb��4��"sB�-(��l���C�tJ \���Ё�S8�����c$tf3%��$���LKZ8^	o����
����%OiL��In�J�|��]��V�ޮ1L)I�q2p`�!a��!X��s��&�h�}�筝��yy����ɨ�����������k�gqgb�h�;�0���,�Ր�]���KD�(�V>�Ȓ�Ҩ#~��	ǘ?����� B����e�����x%oݥ�I�L�C�|H���k6�i��l4�N�ӯ>��W�M6������������V�9�ؚ�Z�ȱYʸ��y�Ķ���2�-�"���rų��J�:0̧�nP�[h�ͤ�Yim�L���MJ��!t�pdp���i�<]=����؉���M;�{/�j�'���c��5�z���I\S��� t���6p�2���	���1���`d�o���+�1�@�U�`����4�7%��6/�y���*��2)!Ô�ٴH�A,{P��!��'U�˛�v�=�o}��\R�ّ!�>�p҆x�B��ά�~$B/ؿ� �h�����^˯��1e�?h�������iJ�j`������3�"�%UX���[��ҟ�����$A�m�x{�s����w<�A�T9W8���O��T6��}ѝ ��o-;�By�%۰�B$/+>��;���@�QC��:���/���,�g=����Z�|l'i-��Q?o�c*,�D�����w�?7����x,����i#Ҷ&��ֳڸ៹�߾�i}�M��w��Y�*��b�e��zL��bY?*�\F�y��X�Y�^���gE$b�i�%4�y��j�̅�H��$-�OT��<�X�Dw���T���ꇨCa���_�@� dM'Ž��w�m�ADC��*�ދhkj?�m��ѥ\c�â���X$��gϻǋ���u��h[���K�i7�aȜ��@���\�t"]m�sδ|�K�꤫^���o�j�1�������3j�U(�a@[D��6��@cI�W����!���?}8s�8`��yT@`Q�]�^�L��O��GV���A�3&�b��m�Zz�9��B�a�C*%���?�����M��tב���� s  ��ln6�ݟ�\B�QӴ�O|��rFE+w���~�>��T���5����<'8_T�m��]/�崃r4��+��$��f/:*8$񢂤>t�ռ�Ң�EF�⭕��39~�|�.�w�<n`����̘�����@v�߸02���&�-CĜ�jC����Vժ��8�Ј37�]߮�hLАn��ojH���k���%M%L'�e�N����Z�m>��_��� oJZ�0��i��3T������v��[*Z$� �&��bZ����1��La�2|�1	�Cޞv�	�7�ǁյ� ��YRU�^,Q�x����e�:��[U�qT���x�u���zq��,.H�×�xѠ{m���Ў�W�04���	���C=3ꏐ�4fd��]�G&4D�{".(��A� ���1S�Y����>���h��k�ɀ�8�*���y9�z�(��r����j���݂����8�Ns��C��dƘ08_��1����8 �O��	��c���L"��s�F� 4�����|�d�UOB�RFDw|)=^�������VS�ۯ����5no��b��&�p}����p��{
Z�duХ�koA*L�X��5ǯy���������t>��Nݫ�gB�M&+�U�܃Apq�B{�H��OBs5�^^�&,�	�j\���U�LZ���q)j�ɋ�Q'փ1��7M@8.d�A9�J������xD� PL��P�g���rG�(vW �z���L�^�ĥ3fkܱ�7�7���P#�2�����p�Q�}�%�(�m�࿄����?�G]�kB�l
a��6`�m�a�{)���X�3�c,��F�yqC˲S�R9�E���G{l�ITt����s~�zYG1:��q���L�.���t�ԡ�gr.�$��W���%TA�_+� rR�<Y���9�&���#�P���O���17���h/����
 ?ݭcMc������hzgM��k�5h&�,��ҜM����b�V��� w�d�1� �����>N�ϼ���$��8���ۊ"*f�[s H��5Ƌ�!��Ќ����m;��'���[��n�.���=~�#L:�}��>�����#�A�/u��U�ۄ��{|���e���u�$��z��$Q�'�%Ώ]?h�ۣ	��#��,�P_^�IVZ0�)�&Lbx��Mg2ZA�a�� ��sN�d9ᒐ�+�f�i�X@��q���aB�'�ҜZ��m��N�m&`�/h��w�j;Qw7VF��9�c��On�!�-��Z�GX�B��)b~���<'1_��?4H<,�[y?�H}�U)�=s �Mx��Cr�]�����h��B����5
�d �2U�f��@S��ȗ�/�x-_�{�?4h�x��4���u��q�E|����9�Y�M�v�	��8V"嘢d�O�i�jޝ��"��L��㗎��P<�jj�奼;�QY��fm@:g���"�3%�\1��	h�ӛ��(��\b�0_|��p�g
�v��vb�Հu_u�{7�r��:YĹ�R��=�n�����T6�B����ޕ�-�xq3Q�vUs��A�J\>�G+�~�5����Ǆ����DTJ�8�+���TK�n�)X��]��Z�AϹ�w��2�BB��I:b��Zf?��<y�<�cP�q?6��,�2I,�����������fg�%r�˘;ʹ�`�$��n���c��3u�bg�e7�kM�ħ˒�u:���%����t�{���5xg%u�?������5��O�5��RlaC·M�2w�m�^n� п��������yF�J}4ż�??_�)�}������FV?���8��Dm��"�h���T�x���,�W'ލ�-�[ǼGHQ⚗�,�bp.t���S����s�t}�%���_7TۄA[b���^lZ����,WT*^t�*<�i��(�̃W�\�]'�MuE���a�<tr^w'h��#�.(� 1@�L^."��o;��+�����L{�
��~5T��Ǹ�Hɣc�7l�;S6�����9��(Z��Pk������'�����7?�j7�]f�=�����Pz�>���^*2=���E�:�5:�}�)�+{:���߂ժ��W�v�g��0)�!shn`��_kw���L|��^M�$��A<�ɡW4������fL�� ;?t'�Q��lV���r�<I����N3� �g߂���B����g�C5�vYu�E`J�#/��s(g']�ԕ#��`�;u����o��c�����MM0���~�Ar�`Iԩց��{g�^��p�ne�Dh\'��I
�s�ۨ��Y��@?!��􇱵}}$;<�wi��Ŋ�91���q� D����Ƅ ���yb���<6e�&ᓅ~%o"BΩ�(����%��u�S���¨Ek8�:�CC�ds�,5D��
����98���i#� Q��M��ﬦ$G>x|vɧX��0a֔��= ��`��8��6��+�wւ�����̢�?��n��o��WuH�BB�;|�^�������G*�kp�H�5�m@�^�����Dm��@�����#k�����y�(6�	g�q�����6o,���&5;1���X��}D~{��C�:�M���g�!�`���o��	����;j\�o���wm�$*ȗ� �ޓ=g��U�M�>�UUw����A1~#%��C��onh�qp�;'�6�q�c8�
(��Y5�'�6��<ҟ8�85��Zź��`��!�}�8��Ѧ����JU��~�F(����齼Q}��(p@�����tx�ˮ�f�A\�+�Q�3��$T��y�+11q�n+iT]�Ӊ�S�Q{
o_1}�C�(�Gջ������up�nՁs��`@@�FY�գ�,1D�+�����?	&�N��}�" ��t����j��@��j"�ԋ��������&�$�OY�6�/ +:+�q=BE���ݮ�?�m�/��΂�]w?���J�D�l����SH�H�ֈ�E��ʞف���C��?E�]i��Y����� }�{~��� t(QgŅ�)����a�?��M�x1E}\�����B�1I�_�H�AN�Lz�_C2�Hį��D�M��MY��E�  �U���V�������~�|����B�b�p1*U�0����'.�H���{6��@���'s0���'��o3؟��)j)Awm�b�;�H�K�,�g�����U ��g.�ڤ���̓MZL˽���bڶ�[��D�OUO8��Gg��8�􀕻Y��TvG�A�I��`�����
�\���/���!n�O���>X^0�`�:E�@#D����AԳ������y�ۏ H�5�E"�.����T#��zZ>��[�x�t��]����y��=�r�Z��Y'Q	]MsDG��	�fI�[Y��'��;���D�3\
	'�P������������P�UY��<������F.�]�PD���rA3p���~��Ш[�qŞB�$�l-�V�
7�K�<A�'I��L��V�3a`'6���h��!����-��k��L������b��,�9Q�#sZ�;��o��E-!��l���L$9�P<c�D�3$�����֘l�����e��i��J�u�ұ�[�� 59ސе���+H��.J�4�n�t��A}��:�'��,(�Y�4$��o�/���qG�����B��,(�u�����kN��o    ֻ�\�ޑ �����?Qg��g�    YZ