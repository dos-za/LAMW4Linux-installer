#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1462775252"
MD5="1a2e671df0dce51f81d1b94af39fbb23"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22648"
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
	echo Date of packaging: Thu Jul 29 11:18:17 -03 2021
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
�7zXZ  �ִF !   �X���X6] �}��1Dd]����P�t�D���>
u쌊(�x�@!~�!�����J�II�p�w�ӎ]����|D�B'2���s���0'����ԍ
��Y����%���1��+���mU�Ia=����+8q5�i�e.�wP�K�[[��	�gfC�>�����(���lH�xRBD��Uep`-��z6��B���sdy��^ɟ+��kpB��3�ե �2�l���=��{n4�S"�BU?O��Ua��,�*2����{�Ȯ����J�_��h�s0K1[���B�CI���]⻭��5_3]>�G��4q�!�ʻ���X�867�F@�m���]��Pv�"�#t���K���������]̜��v"�!v��$DIKmic I5�����ᑩ���z=�2�Zr���]y�++�g��k��m�V���t���wk�2+�D7M���}�Pւ<Z�Ji�����i��m{��C���i�	7���0'���Ő۞�L���	
4[���?L�R��� "��A��!�ܗ����EJ�:c3��.��ơ���0�	1���*��b�4V����ڨ�o�TMމ�gp=n-�XX.� �V`_+��4S-�f�D�$U�����R}�7�;�f�sI���A]�3 �-��b�@C�^�����N�	��
d�rN��x��/�3q��{U��Y���D�(lZu��RI��Ky�34�$t1��,�
]Qr7�t�(���{�?H�m)vޢ)��_��f0yI����I�Mʔ��^��ld����P�J��6E�x��V	���݂/ah!�%�gpJ� �dX����9�:^���(+/�a�����'%�'��?�"���2�?�0�XV�B���m �B�
�0�"^G��k�z���3���*r���2� �.�9=D��n���#z�ʊ���ɑR�mӟ�i�U`��S�H���wc�F�fq�����X�ދ���T���~q�{O�De�O�Ԙ�Z����%���_E�����f:�@�pɂ��0;����ɣ��w�كԏF��B�p�d\�u�M����ؽ�~W?ē���+i����W\����	��߆��dC�s)\�׍��[yg����˽-��Дs��Y>�D�4�C��^ҘS��>�
�@MN�-ܡ��=; R�.ΐ�:�� s[xX�X`�X��U�yD����Ե��%��������+�$@S-y�����E\��:�\���lf%�X����H
J.�;�nHs�	�,1���t�Zu�A˪/�� T� ֝Q���e?���\�^�y���Je�ETk7$nL��?o�Bȡm�J��C�og����v��g�R���n�W>�|�{�\ţ~V��לjC����)�(6��[�C���A�6���|�`F3�x�[��k��܋r��_Q^���+\?��������n*��$s���p�N� a���z �v��������[����O'�@F�-3��@aL���T�a~JD�_R�]�5��ֳ��(�D�iGa� #���.P�x�����h��֌qG���y��E-�7u�ڨӄ>��K���VL�Fu2�8�E�z��F��0�RޖyT5$�C�f%���y���+�䂹$��.���:;dXm�=��<�@c'��W�	�A�J��"ꤤ;m�|!d|�F�
ꣻ�qN~�Bt�XB�s�n��������rQo��K=x����g`ʨ����fOc��47�QN��W4���P�<7 �~,9�Wna�\k(Dn���Vw��8�sk ��go�	�� �z�B��a z~�o*R5el�Mr�N��E�}Ī��,̅�kx¹�4�`���3D[Ú $6������M�ٌ>,�e�2�eFgkg��A���1�����6z�q�`9?!]h�T�QgK������+�Y�fU�O%�"����0�,��b�"��V0P���i�����h|w K����d���FN���HL>A;�#ǟ��|�Ӽ�j���J\/�\.�����(>y��i�l-.B�Œ��<w�;~ �����>� ��̙.��i��^�����L���5���Ln	�A��u�S��}��z�-����Mkҩ�Pɕס� T���K�u�:}��楂klX��dV4�y������Kd���Vzng��^E�����gW�A+����?d��Ӯ.�����j/6j�������XH�!��E�8���xM6s����NN,��hiJ,!G�8�9Oa��f����\Td��\����ls��P�6�+4O�o� �S~U�6NJϮ|
ns�w�ܬD����#f���m^�z���
��.��0@�:p
}���������o�KjA�	��j|��"���Z�$]�;�sa���?��cd�䅑��ۆQ���	��[��X�S�{GR{����	�2sc7����ZNR�x�Z��h"���][����h�'�f�5��ŤPH�FD�W��b�mb�>}��3�h�.�?�I��MU	�HY&z���'��c��}�9� gZ2�]��v�u��{�����\�$���q �af*�w1*5M
W�v�{�F�<�49�^�ހL�3��}�`0�@cX�PY�O�.�$�� �ڊ��<~҉bzB��T)4����ֻ��d�Vʺ7k7�@��;T��V�3�zN��M5�o��#�m��]����RbOp������h�y���z�T����ҺnG��u`Uk���9�L�Mh� �1y����AY|�/<K����z���?��cvJ �Gy����M���H���P���j�p�(u�T۾��@>�Z�ٙ�	2�8#�*��(7�a=�|1������<�8��^���԰D8�G¥ޫ�t�ѵ����Tg H7j�u��+�D7�Vd��I{�e����a%�+&[�`�1r�RU��N�w�ǿaıv\�!s~���A��Ц���(��&��晢Y��=q�S���z�(|�2�����,�zx/�o��%Ϛ�O�O ROP/��.&���/�����y���_����q��I#/���[��=k"�-9�]B	�4j�̞F'GL?� <��~Ţ*�\d�$���n��3���7�fF�i�G�Q���,n�3{	,��_jz��"oD�3�62o\�1MvPY�%��x��}�M�12P��J�j�	a#��A`��FV�=�O�2��f�PD�gbn�����m�L*���d4P'�#Q�g������v���	�3@��c��{K������(���l�u����s�W��&���\$�LD����9V�ԍ�`R�q�١R�D��Ap{�, A��Ct����6��P�?&���~���f)x���4��볾��5��]�nZ���턖���'M>�ͷ�}������W4��q`��)�����x����͉e��@�P[���`�n��e�'k�(��q�㺈G��n@:8�d��SG �b���U+�jSH�$�i�+���{[�e�z��(IEl�5��67����0=�� T�������?h�Ч��x�{�F�X��{��R�ޢq);�J�42û_?J��T'g'�`�F�Cc3y�0�A���5�Α�)Kpd�%��My-��H\|䙟�������	�8T��%"�P���z.S q�p�|�sY�Y�Wlk$1��Q|��r�jۯ�~� g	#����fy�X-�����E��Z�������	�U�}�B�2�QP<S��O��M�2z�$Iq$ȼ��i��i!�t�E�ũ�ܔ�zV��N��z]��N?x>�4����&h��~V�B��f�̉����N�pY��78�Z3s�B�aۖ��p��y��ٱ��
�e3ߙ�D��ŏ�u� Ǩ4h��ﷃ�Ox.�M	����T��y�3����vweosh�D�CR����Jj5.rg�d�� ;.|$L��8! �-H2��p}�ߟ��W�d
q|}�}zٍ�@�^A`���}�!F��8w)"B�z��S�NaR�}�Z^z�AKnb㯣�)�tK-v��nq�3C֥½��-�}�n[��Ӄ&������I�y��
4u�a������Ty��!oW��2���{ ҍ�^��%D�6$��_�@�(��=�p�>:w��q(.�mv�k{��G��?�@6}�����c��iZ��&|>�x�,�a�@��Ԩ<2ɛ��65>$`'���JQ]���lZA��R=��&ʓ
6�ԟ<�8��W�� �WA-sf��1ӭ��s�vIS3`�t�ݭ��L��^���`��s�~h53ɼk
&��:z'��n��������gA�<�%�g�Q}�
!��wf�)6���v�Z��9ny+��0��w#��M�Dor�A�	;�su8�(���s�f⫃����@Wsn���bCl$3��d+��%m������h7��4ȥ���c��t_�W���lȉ�e�nl�vI@j�"����?�8,c�~��dʉ���3�kC�{.@U�+�U������$i�W��l>�<G��10P>�#F�1���Y%7�S�ޥ�%�+����YY�kb��3#;�5`Vt�ʋ�89�|C��m���Z����狶;��тO���UI���[���&{Km�d1���:�W�+��~Êr֍�k��Qw5�eD�@sM_ד�Nc���*����a:%�NJpp����	����c"�A�%똳؞J�ʴ*�E���\e��T�#���'�|�i��t-[���BX$ߴ�q,ۗ��W��,?C76}+�u��`�t����p3�D�vr���4<UNMHvC�^{[~�¶g!o��pc�I~�	�ݼ�<&Gcq�$.�o^$���:��)d��������� ���i��f5��&�,S�
�K�!7���:��;~ǐk�#b���dW���@0���60���{f�TX|���=��.�J0��lW��X^'����C������&��J�?���o�-�B�Hd���W��V���R��������<�	� U����vipAA�+P�~����]��Ւ\�K�Q����bu!x�.�Hۺ�n
,�t2������c`����ۏ��.a�u}���ޡr\&���ph�$T" ����
�R�_�ĺ���t��4�\�.-�r�X���SIG6�j}7z��)�k��z�'�u�Jm7��"[�6oT!<T|}��>�;��(?�:���<b��'N^��S��
���2�`�&T�����z�ۛ��FQ|\�I��]{��mҴN�v-xD�2�/�.	����<D~��T���!��J��)XD��d�	Z�߬��)9d�1����ȝ�S1GE����?���
41���*c���Z�A�N�f���l�0In��Nc�����k�C�jư��㰧�hfr?��2R�2���i 	����	JS�f���3�X�.�'�PZ�d��J	��2�Ea$T̪!�!��҆<�<?��>]8��K�#�8(�]lC���'K����� ����s�e|���t�0��J���_���^OyC�ۓes�1�7cluRiߙ�n)_�6f���ay���+���� �ig�[��Sǵ��Gߟ	O&&o+��XM��I*��y�b��!E�lJ���	�����1�g�6����{ǜ �}��D�w�\V�'%'�od>TD� �1�~�ph�?���*�ϗq~f�'���C�Lĕٞ6���e���.��IP�����UV��\�Ct}G���K%��e�f� �5>�G��@�i#^���������h��CP\C�l�`N�gS���h�_؍j6���{0}N�u`��q/���b���v�O2&r�� �%�&q�m1p_�M�XA\=���������X��Q0YG-L7����T/�ם\Y�i��l:'��+P�\�yf����}��L�	lϝJ��l5�w�pͮz��ɓ�-�J��c� �sBNO��S@*��_���Q.�A+){׺������x��3f��H�k�|_ g�R�U�Ά�n/�p�&@*���@�Fԇ��]L�?�/�ٔޫ��!K��'���5��(+ #��yߤ��jd���V6����R݋��xj��.���ͫ�>1�G����>�d��_��q��)Zks�##Q�������;t+����F�ճ9}̆�`C_��2���B߈�:���̥�����55W$�г7&s�م������y?����㸓k͒�k��q� �W݆�|�]�v���0,}k����?V�mM.����nA�_=�аL�$��DZpGp/�lw�S���ڪ�Ne�$���F$(�,��#΁3?П�i��u�ƭ���TN��H��;�������:�B4�WL[�7����9��gb��`��*������O�Ӂ���שaY0M&��E+���!� 3kQ�*���r�XV���4��S��|�O�l�ƕ�j����%C��/ct}��bPF�	��������㏶������a�f�|kAi/���)�"{[٣�q/g ��G}$����
=�jQ�40����F���5n�U�.t��7j� �h�/#V���f[��/Eם�d~���k.�O���Nlo�E o����4+(�TpP�����
c����F򕿔�F�1�!�
�Eʇ����Re�
���m8�Ȼ�<3�~��۬Q���5�>0��&D�)�Xe��t<m�m?~�ʜ�a�p9����ѻ�d�B�)P�aXe�~W+�w���T6��g� �����8���(R>�2~���*�������e�7H���F����+��h�t9���S���,Xǻ�}���j�J��O?Ww��aj|:\ڞ]$B'Ry7V��"��ҿ*uo|��87�]Gj��3_w=�s`����J	�<��ڹ�Z� �ë�J���;���w�4^̎p��M����6w�[��L��ѕ�-�.�lF7xߝf3f˪e�CP�̜|�4�^ؖm�E�!�U�Y[�	��k�4����V��l8qO��\��E0���>RVy(�l���ک�\gT�~#�Ѵ@�n��_��HW��U��!��_f0�u����GЁV���8��֭�,�f�a&��iK�=C%�:�tn~��@�>v��r۾�����j�W^w_̟��`3�F%Fb����&m2��!�ϕXS�-Y��<�����K?���k�te�=����J�e�W�«f�7h�M�I��Y�����>�)1���BY�"܆�؄�0���n2���pF]��(�o�H���!;�SW���Hr�t7pn���s2w"�������tc���h�d9�1a �N@�N.bs�?�ITZ����{�f��g}�аH�3O�ij�3N�����H��X�S�Li{2
M�" �X'*Pj�*Բb/`�3���ay����'�>�8X������1�n)���׉�sxw�}�*�R4�����N��Գ|L�&��k����ܵ��d^%0"�0ʇ��'�s 撅��v���ʩ��ѵz�u� ����k��]�T�k?$�B��±�I�hk����|]=�i\��N�����gg�;�+����+GkNj"߂_]��)����%ܾ�@Yv���]�L�N� ޺,>�������Gܺ0�H{9RT2y��YF��WR�x;�N���4��^C+D;N/7�%Pj��T_	��q�[�_��[-Q]�c��E��cU�Pٗ�(�%쥪P�BR��%���@{��3�n��'�4���G�8gH���&0��cC���e�廓NcѨ[���q����81m�x�"��t�W(S+��44���d\N�X"����2V���G�T�ЁT�Ǖ�J��5��$��xnRB�{�5aӎ;�'��{r,߭=^��%��y@`��x����'��3V5(��B�F�-&h�r�_�EJu'3E^ĴE�lٗ[����U]:�r� ú#�ެ�T���+�mxr�E�L�E��C�&P:F�|;תG�F@I��b��-4)��-idjA4�yN`�g�x�TiU���R�EQ�<�Je@\k�4M���x1E����(2�B2AZ찰�SXҰ�)���2'��1���2aԲ�ъ�u���������ڨ|Ց���������V��i(M��[!8���)�u~�"����MY�P�D$�"�	�ڵ�6:�/ȃ�Y����)�/�a. 3z��z<��3���^�Y��IbkV*k1�T���5�┐�NT��YuQ�\$�^\���B����n��u�D�I#�:>�pj����+1�
�6jP���a�|���XՔ�U��ew����q��$���̱�"���?\�
Jf����s�DF�d�ε�Ŏ����ܾR�24g��*/��j����x�N����+�Bþ	�G��.Gr�K��L�e��Z�q��!���-|�G��w��J�V,�:�3��J��8�B@�	܆�z�5J[��J�u��RG@ApC;ɁH�e�V�Yػy����zK�xoc�Z�7�%�<Rq3��L)�k�z���M3�_u�yf�屲�+�D��O�L��p�mo�Հ�0B���R�>��H��-��QL�@��^� ���������5i��I�!c��/?��w�g���%�X�����,��Ed̨b�K���`�m���NY����9*�)��C��[���.��ݜr�-�K����x %SY�[̎-d#��.�&]��n�� ���fV��Q�m�X"�].W�( 0<t�b������t|W�e�Eg��_�}�������c��(�_�ac+K�A���Mc�BQ?W*b�N?o�ycY�P2_ʮ�!��C��9�G\�7�7l]�ٜjwe	�c99�A8���ߚ>�AQj�}�DK=��J<36~&H�B�O�%kb�R�~/�J�l��/
��MrO] �?����mxM��b]��T�"��ᄒ슳��f����u��~�0u!��j�7Ն~ᘆ5��k�,�~�Z%�bf�#u0��'c�8�3�s�>Y|��^w�Ƭ.ҿj{��`&꧋��A�E�����9n)�t�I�������gF�ʰ^3NP`>�Sg @jAC�Z�6�Ȗ�U-y��v��2ac�	�(�%g���گ�1��NaW��Ϩ�T����i�!9_}��+��:���Ʈ���A�@�~~�%�����D��L;�jr]��u
��S��p=���!���Yo�Pb�_�mKr��#8�)�ʶ� )yl�KN�Q� w��3_�j���#}[���������a��	(z(xR6�2�M���|(�2F�G�tY�LX�k'w�l�9�����;7^��D�@q�Hu���u���{�8]8W��S���x��$7�f/�S��spW&~['5�fA����� ?cr��D������@�T�o�W�;��I5BH4���V��<�M��!� K����Iy�n�r~�J\A¼>��Q��e ���K)#9�p�	�@���s��s=�h|j-ϳ��bt�1�qۿ��0W��<	H�,����n�/�hO:��و�5$?>Ok*�p>�ë��d��-h�so�h��?�J�R%3nP7Up|��ӭ���gC�d��������,�4�����s�z���G���;��
�֖N�BR�3��JiF4O��;R��N�`l8Zd���E���0����ס�L�,㌀r<(d~����,�n��?�)��7u��x<�Oty�d%��
��B�r�ޟ�8��F]�kb����v�,!�vRE�%����r��U��W=qfh��ȋ��ޟI��
_�&
x�$��d��O�|�Y"+�dK��S��G�&.���g�R��A��Ù���;��HiT��HT߂��K;x��8��y��7q]r��)o�S�G��?��mI�	V�b�����6��i��J���4i����ML<T��0�%�h������т�X3����D��.u_���<��`2���ewB��pn��.՞�`��ΦYMw>��i=�&O���_V��lݫ��O߻�I�T��J��s��ʸ��	�YnP۷��݃r�ް+ �Uf����ݬI&���6��dC͟�!��1�S�J3��ЗR̔���_y���`8��ɥ��ߏ��ۜ��!%��P6����E��!�B2w}�@#mϚ�I��mKGl���EP�?�įO	�\ޜN�'�$�=�O*θ�~x�[�i�ʞ��t(��ϔ熆GI�������o�����jE�k��=D?ʹ��I��9�+�\:�	��]��,���+��M��m�s�4�eVT�P*d,,�v��_��f_�_ٕ�0��d�,���ř��8�*����
�=|i�k{\�o5�ɩnfJ��G�Eo�P]��U2�0���&!�g���~@ �3u�i\~���,:��e�3n�:�A��ѸZ���M���U�zy *�=���;��N��`��kc�b�)jd��0q{A�j�D�&�H�P\���	����p؀n5�W]	�>m����Jw���$�m��{g�Ry�HfQ9���
^Pѳ'��@_
�6�֯��M]���~��Sf1����j���4T����j��51)Mq�?��2�Ie �X��':����1BeE5+em�3��o�
٧L���a�
_3��DD��&J��8��х���W�
�n)Cʫ�f�����a|�{�Q�pz*�����&�؃'��	���h�Ao�3�|Z�c�]��On�Di�*�}a�����a�MH�	�����B�����!�C�j)I�h�J6X�����V�2��+K���� } QFd���ˡT�w("p��qJ��06D�
��ay���X'-,�G�,��� 7j��"9����M(�z{k{mŌ�2 ?%�l�2��|��ꀢ�s͗S��jK�+4$&,����y��_1��,���<o�>Ņ���0��|�'�bvYL�+3j��S� ��P�h��t7{'�-:A�(���I±�]�s�+*��탠�k��1ؘ�6��Y�SX�{_|dc��=!��4oU@�}u�0�A����D��B���u���=?cј�JQ�0�|Y��(���Yg�Z�tmC�\O����r=�n������8��E	|�C���.��D�lc�:��ؒf�RȐ��7E>B�k/p`��a[�ע� 8�2�` $�}m;^:�&�9z٠�"����Z(���p���kT�
؞*�E�����%�W+�Py
�#����D�F�:�>?5�U�W ��Dj*.����+�WS�L�!k��j��FQe��2�CeI?mqh�c����c)���U�W5m��^\-���q�O����F�G�8���GQ�k�B��BS6�pl��f6��)��*���[`���!�9�WܡB�6���+3���*}1-m��9t��ٻ=���
�
�-�nH^7ۈ7t��	@�HG�}��%��#��/�EN��h����٥��-0|�����PoU9s�T����:�P1ɡH�����A2�43kߪ�8��5g��vQ�ҥ�g��qt�ʁ?|*�L� V�x���E�\8���]]��ޣGW�{P�P��3Af�Ц�n��y�3G,z=�ʄ�z��2��?��%s�g+�R��&1LҺ�S�
��o�}I�C�D��eA ���¤Ue�x,�g�&˺�`'��$�`P'{F1y<�4��'���4�,t&Y�}"�ܲk0׷66<F�{Sr8���Rmbi�r�J�:[�V���A�c�U*�#/�vXo��:��~>G��=C«�i�f9-`th�ᜤ�6#��|��no�jw?o�.���d���4s�ؿ{j)p�v���엦��3kȖ�O/�Q�sg��A��r)$J����K/�R	ykr�m�v}V	3%I�˺<�W<.W����+��'nl�O#����B~��l���ݼc�(�F�����D� �t���Vz%8�3|>1$�3\)%�����J�8^[٭�O_�i�<?n����o���q��U��+&[�Ͱ|����`S1�Ɓ`H�L������ŗ�����4�槏�� ��:�J�o>'��9�stG��_��,ƑU��!��Y+�Hzv��0�#�L��o��|� �DG>�4e[l���.�t�^�l��7.P��"�q�a�r�M�"��d�&�x%�����^d��:󡬗��a��ddfu&��1�2d�
���1�d����-������Nc��4[���Ձ����Êo`E��Uā=�z�9��f�U����4�����8y,�Z@*j���2}����l��;��Z7�$j��ֽg��O[��lt�}Sh��4jV�`v"�ba����� ACih���>��O+�Mk�Y$��	�&6�1	L��>d��]��Y!��QYL7Wy��1cP��'�Y	Y|�q��#o5�����焊4�M	`���
��{�ISΣ��t�Tۢ�����������|� �~r����إT�T!ԙX\}u�X X�_=�d��k���ӽ2�>�WX������!���XK����jn`O�ذ���K�6���wnC\�5��>'h� ��#������u����Z�Q7�O�$S(i�Zbђ��k~��5HU����y�q�� ��m�g���͓�	"x�#.�UQ�ҌR�ӡ���Mq���]p�C����|Aս�@a	�=�fA��;	M>�z�w�'�@�ʵwꫮv��\ 	)�,�92013F���B��q���i4 ��7�B>&��($n�XN�� J��D�#~^t)
"���rM�u���.�@/*����א;�B��dL���l�aD﬘:d�f7*@��Zo�˳�S���;ѓ���f|�'o�P3�z�b�> e��@
@D	�;��@���k����\"G?̗��<
[O�^[���Lv��i���������@�ڌ=�^���˵�HUcE���j���O'o]��	O��m#M�R�Y
 zq�[\Ő���W�9n�(0�zZ�R;0���$�#���R:�����0����dN�/>k{C��U�2G׷�EK`�	A�
x]G/c�kz��Ԙ��X&�)���ڏ۳ŮV'�d�Y'���b*yIm)K���xJ%��';<�I�ӽ __�y�Ta��P"=�!�-�H��E�ہ���J��D�F���\�/�"T �0$q0�����:IHY߮)|	Vߘ�3+mc!�6��>��')l|�_�լ,�5�tJn��D��>Db`���O�]�%�G����mHU�U�yy�t�g�ӊ��ЙՈ���k�b55�8ۻaH:A(i�[t��e�༰\w��ь�$��z��5��5��=��"���r!:'ۮN�4I��LIW)�]�y m����:���w�[��������x����o�[_��}ݕ:%匁2����~����8'�cq�x�6mvF�aqӼOFC��a�t|����R��Y���B�ms����e�a��E�B�sneF5&L�7q��q]�=��c��p%R:��(�68EB�˵=sc�&��.A��iCfq�L�TC�p	�2�	4ob�RUp�XR��PJ��	FA�x[HAג�)X����x0�0n�a�K�%�o��A�k��?�����V�A+�A�Du�Mm�*͇�Vɡ��%��4�\aB������� ݛ��z�	=�v��|�}��M ���82xqc<�.#��p�������u+,��
�{	F흸&���Rm���R="�&0Nh	�F��㜎Bi�����j|=���$#�d���@�_v����4�@��qP���%pP��e�>]q4��({�<��Nd���ha��YГ�z�\����)V�4eK� �b7V0� ��Y�Y�������j���8��1
�$��צ��#��ჴAFa�R�i_�ea&��4�;�\[ς�b>٣i�5J��9�r�\�3���ĸ]j���?_��T��~��;��m��Q:���gp�n�u����f(/����J����%��i�0��	����WfJ{j�#��ZG���J�"p��?���/-0�]M�Dv��.�y2�wA��f��%�H"o�i�s�ER6�E��tpGNB{փ� �f�S3K
��2��ë�.��l���G��"�4�%k�<⢱���:8uol
8ň"$_j�+>6 As�N�#O�/������uXr=1{�]��Jt��sw�2U���FZ|2[�͜M��&�#aW$��tel��{�ԁ�9}�D��I�j�	����X�Xb�����Z<�����h�ם�1�آ>'؀P�T�+�`.�;�/c �q0�߯�_����oQ��B�ʝ�ǽք��68yb�EՖ��?����r�-pY$~S�<�O����CA��P	D�~\����`#�r�oi?,
i#ְ�vX뙱��tb��v��P�!�<��Ŷ�2�X��i36��;q@�ϫ�Wv ����8[�m�o�����6U�~X�V��Z�<�S�W2.`/M��͆�/SD����}����y�	�n���@%�Jx��f�ɺv����Cq��I���+���x�B��f���[�L�{î�=�%��a�L����]�/�\G�멠@0��q�L�Y��>��.��qD�g")3j��2� m v@�8��w�9�_\JQ�B�fm��@�(��B68!������C1��S���X����[.��]��x������~L!��<3��l��G��+;So���0v	�P�U��Ң��Ʒ���8x��~ʣ� b΂�@����?��Tl76\N5r��)aa;;����
�!�e��Yfd�+#���cG ��p�as�/�4������e<�vL�8�pk|�6I��
%��uB�b.Eu�� �9�����9�wj�	��W�P?���
�6�m3R⚑_�4Y�Xy���y��g]	�TP�VF��r(ζ�<��3_X}Ag*��#t*��5}���Q�OA����~�Z�fg��Cž0!u߿��7ʟ|���u�*x�@�ЩP�N��2t���*d0IeEZ-��ty�x��e�U�N�?�&$4�b7���w-��6C)(D��;W&�Q���g�0uW�eC����\  ��.�s�����L���>��S}��S=1"���p� wF�<<u?5���t�D.�ܪ�^{7.=�S֛		�;�o8Ow`@���ͣ��V0n�����z�F��y� n
���-�W�ԷT�~����,�?~if�Y��g"���2�+�c|�j\� D3�/Ծ�5�1��/�GF�W�fO��8��rm�v��#���6�ϕU�I��q��q��j�6'�5#�o��Ք{?����7 �: ����c'<P���5�Z�Aci���mn���@3ݻWloL?tQ�U���FD+���|R�5v��M�Y�1��l�z?�V�aT鳁���2Z���(ۛc`f�����w,w�0�ф�Q�����s0�����C�Kk���2�P��C~S=u��k�-vOMV���2Tp�ZXL�:TE�^{�)v�ןl2��8�a��O'��������r����6"n��><zM��9��
tWhvl�IXG
�Jj:,������07`�:��_�\(�9ß������ۿj��b��~�:�;1ӝ}�lZ�L9⒕m.d�7K�+y(�L��(8���[��ϸ�3��XU^X�����Փxy<(,��9K�@hǅ��ש ���U�>�f���ǭo���^��/���0����<�x��N¾��~������:d��#
�.�Y`k��L���]>"5�F��y��m(���X�r�F#z��!B銭m?3@�BJ��@�.6(�]5���yR�|~��8ڹ82|
q�U�E��6�Q�f�2fu����0��Z����߸��.�C_�8�X�|�r�<0�BƆ��%+�4�����!�]�5���dT�'^�r��b��u��� Q�$�S��pX2Z#�"��W۪���b���\e�!�hriݝGOd0'��n꘹12���tv��.D��Ŝ�R��c�\�D�5ʖޭ���و��D�[���~.Nu�}�^��j��ի���&�����Es���#����`-�J��%)�+�bJ3g7��}T�b����˟��B��!AR�I�I����D(0s&�XR���R�6�ⷺ�U%Sl�c���}A4����� ����ɞT�Q9��$}9s�S^4����~�T�;��t'���mJU���8���U$~��`�=��,j�ӌYh-3U��������XV�j�� IӸ��-m��V�ȍ�@�(�^>�n8&U���
��F(�[��9�R:S��0���:�n�Q炽r������1���M*�:����>{��vp��h��*tq�Π���I�M��ڭ��K�H--ӄ��F�T���cQL���p�y���,\��d��z��W���,Z�Y�l���c0�,�ͻ����w��vmQ�H�&;�7�#��l���E��3���A&În_���{)�*j�ˌ		2k��q�s22��¦N]Y7�6�2�=�j�raD`U�ǤR�K�3~Қ����<��NkL�@/�'����􍞈S@1�C�p*�Ck������Y��4�-dd'}n�E����R<�p�h/���yc��Fr�=���T�5�l`P����u��z��%0�a+Ǵr�?��L͆�i�����a�AĪ����8�(7�@�J���c���JO?І��Wht>w�/-FT�0��'�.�\]QtT,U��[�r��Z���t��D:���A��
K���ύR*a��Ca�"Vd�n/���5���^���Vߏ��Ûe� �jL�Q�8
���Yr ��W%�\�D|t�^�]�'����o��梕I�M�`:"�X��B#��9xK�9U�V��Ii�A�ӌ$$�^mH�FoaAD<��:�p�Ѣ]��>:)4�?V���/�,{�ߚ��l��x7�M���|���cG�
�|�J�F�=����x�
uX$T6�t=��s`;{q=�C:$��KޚCb��	+�ŇP9~�zǨ�0���4T�^qn�ڷ�
�ʈ��=�ml��2�A7�՜�aT���̹+2�;��Ye v<b=�����w*VM�KF'���4K�1b��+�r�E�R��u����N@� ¯�)6���@�;�����`{��aK.���M�&B���3�q�t_ �l�^��i����'Q	��즜�k�-M�͇/	��5���H��o�P�T�q#�	l�o�	�7��d)��{z�:MU��b �{8�2��yqJkI:��b�>a�B��i��db���|i<$Na�����:�y��c�Ų'�+t6p��\���:=4�LV�����R�6؆������4	��}���5�X_a��Y�G��zBL>�hl�^K�q�n�Zw��H���@PdBm�ִ�q��Qܳ���o���w?�	�ﰐ!B�C��6��p8���w訇�Hq:�\�E��D�@��&�_��=�7��y�������z��9����
%�#·/M�wo��#��k+�rM���a��dЂ���["mA��r3�ӇJ�#���y�~���h��a�ҁ�s:��F�D�I��&��ƕIhHo�؁dE�!Mz9@&)�<�����T�C2:�'so��s��1��hL���i��T"j@ѩiS���Pa�F�0_�����	_�z�k,��,�qj��A��3<&&��}����so���b��\<�B#j����`Q�L�..���L
";E1N�a~����N�}8�6��G-y�
�[��*���_��6q�{8g���6)�@��죻���rB��Am����/4�ɷX���>�Z2Ċ*´�`訨D� ��B��߸����x�7�������..�Mat���7(6����^��	�?7͕P�F���we�
�����1�������ok�Tx�s�I��y���8�ۑ"��#O ����G^E,�G�i����mHF���	H`�;��N�%�5�,Ko�f>��[h:���EV\�/pu3U�4�E�|քkT�oU\�c�kA�����Lf�R}}U?��T|g:�)!�Kev1Cryɒ¼����Ȗ�� ,���{g�(V!\�
�������ٲ6���ͮ�n���3��on�͵���%ٍN��//�=��z���:	m�q���!�[!%g*���җ۰��HP?֖���hT8.�՛BQ��/�"9%�LC� ��p�a+w�5��&,�X�(�%��ȋ��o��M�S���uJ�mx���+C	垰��1m�&��꿺�;�2�A�VE��)�#-�Z/پីR�R>#��<R�Z`?��݅A�D�I�[<"��|A�sL����e�X
_�,w�J��OJ�$*�r`��SF���Hc����@����4�kj"��@�e�!�Tbպc7]ob��RO�)G����	������?�%T�v�	@w���Gj�dVq0Z�C<~V&���[M���Є=��R��	�[+Ȑ���t҃ioK�:#�?���=����`�)�/o㟁��z��
ɬ�їT��p��{/�}��-�d�7��Z�]� �2�����Q�����u_۷N��.l!2�����;Uð��E+�)N�xli	c2p��o>�։u.���I���4�x�w��\�������9�6C��}D ���+Ѭ�J�s���,:���H��[B��B?�#m�[SGb	ĝ�>5rN�cب}fv<ނ�x��8啨=��Ђ����=�\�^.(� ��/��D�&6'L�K�^CO]�В&n$�\)��!����K+��0�%�_�F�ݱF�'�r��*t��Je�^چ$~������+�+SbLE���,c%�W���nޣF=��Ak~ԕ���T�TRk�y��7�𱆶��kf�A��s`x>��0mڥw������������q�v�eS��ut��0�ȭ3d����{L�jİo���Zh�Y2�Exܬ\�}�K�Cxږ�SZP =���z�rK�E;��b�����م,��UҊ*O֮����D��lp��o���:� S$f@Qd��0�,�8� `,_�d��f��	��>��'L!��/{J�����<����<*o�V�
aD�,掊�)dW:du������&Ŭew��LG}�&2ŋz��2e~�� ��#��o%n#���pt��֖9�{��N2�U��BR�Rů(R�SVN���B�ZB��9�&����v*��0�҂���M1^�Mz5섡��~�䲡�ǌ���U�\����%��~��{G�Ͽ��,��n�壎f.��00���=S�����j�L\�5F�9�l1��ΚS�.�Cj�u���A츚Z���>Cנ�N �j�+�S�&[^�8�f f}El�%x�2D���?RPǣ��XO+�2�1��!�<��Fj�8�?���h�hƩb����#zbJ�,�j8�֎�* �+]lC��ύ���eX቗	T�����_k['�|J�b}�a,�٩%�@~�2&�k����{��{�J�q���(�W3� ��9ɗ�C��Ѻ�E�춾}���~��|h�q���KI�M���%q6gEu�lM�$+�Ye�oq�&^X_u/�)��O7�V���@��T����1����[q � �\JN��V���<�$�A��J�T��[g�UW�T~|k��U�k�:����ă0��%Z.���8+z���+��Ue��"O����!�zP9:��jsb�O	�5����]ld�Z��s���𝶑,����^����q!�{s����_!� ���rXR�,����v�6]
E���d2o�z!��#����5D&�
ia�^��]����I�b�g��O1��e.V�s�/x� ���7%�fX�(.)�/.��ӿӫ��A��h��g��O-M�ޡ�P:��M dmXk�"��vCs롫�l�d� ��?,出1:�4�A�o�j����5�p��֬�����Vp� ��	�E^>B?al�v2	ѿW�h��2L�`�VF��)�1v��Pw��)]�>;�Oh^��^;�l d���o@�,ʷ�i8hW�sH���/�DL ��mA.i��ix�>�1����2[ScMQ��i��+��慀�"&�D�4���F�pG
��z )���<�cF�u*.���[��b�A�9ǵ�Pi\���w�~���L�Ve�jh�
��ٜp#,��R��eV%�'%k!��o�}6 ���bZ�q�8E��KYQ$Kf+�ʛ� �۝Qa��d�ߘ��?�P�c�lh��ӕ*8���I���PL.[j��� dhF=;�ɇ�	x�Gf�7y�(�϶�9�u3xNAN�̀��M!������{�+9�'����4��ď�;9�'CDWH���Bwe,�ϟ����ZI��j����L�pb]���_sr)B�fK�,!x|&����mr�ֳ~��Dj�^.ޓF���}��܀#~�ȤU��RW��]�{����6~�Q�}�~��g�S�\��v1;�k��bXYH��K-]K��$]�2���=b9��Ok�b2U��M=�(dT��$�<��S
gb�M���µ�Q���4>|�w<"�{�!K"�q�B�L�N�iQ��Hl+���`������ �V��}�X�]� =�K����ؐX9k�x(�{����*�\3���v�n�C���d&҇��s�l��+(bS��A�&:�*�p�Z���Ϧ��*fhӄ�Ҹ8�c�}��a�[�B���f����rV��>8�8瘋C�|A�\~�MC��"�K��3���(�zdqE�٧����S3��]�A�����aUO"����ƅy�h�D)In_�#pe\M���7PĠ��def�_�% &��)���D�c�?�[�#Z��Hp�����5�9N�)@ح���;Q<F럜L�%����!�g���Uu���,s��#x�cL��l@�V�#�q����M��]
rnx�W��1`񲗔3��K�����W���;�	��Q��9�F�f��U�3���"BI&l�:�o�0�`�s�nWO�O~ �����(f��D���~�2��@���*W}�KT�0��k�t�V{#�],����5B��w����[B?�^�Fs����r��9Im��j88Ő��m:�������"�`}��wd*6E��&�A�ؕ�[9�f��j�8��Ŷ�2��@�gA3]�=�~)|��N�~�R\X3��D�&�+�}��ˢ��+&QA�{��7��ә�C����ur���࿪�c�>+\�_�wy�-��
ٶ8�?Uh35��#q�qQS���)�R^�ܱ�2��%rmxu�t���y��8Ԯ��Ue��+���fT"�G���1�:�)h�޶	�1y }Xu������L���H�/F/�d�|V�.*w�T��OvBeR��D�l#�J�n0�&Q�1P.��U�#!�lCy���(�^�\�'�W�j��Z.��?�b9rUb[�H����H|:�q'�;!��#���0�j���{��S�W/���)�x���|H�y:�����w��U>����|��ٵ�R�-�e ���p�����̿��~� Dq~T�HO+MН� �Z��}�b��.�_��N1�䦿�Yo��4���`đ�ۢW�㴻 ���?&�Ȩ�^�G�P�].�Lw�/�@��=��p���g�qbrݤ��d7�ɧ��/�+���M������'(�䪅�9������%��� O�q��Cma\�����n���yaԮ"�vV	a%��Y1`�P,�,$�������7w�ƥ�Y��S��s>N���LAU#L����J$�H��q����-�*�¡ػ��wd�c�!F�L������x�;;����9>ĸ�M>�� g�c�s��w|�8 5���S����C)�4�u��I�+��E�אQ�Q�d��"�%g��u�3��C�`rz +�\
���d�7����.���>�E&��o.�D��pJ*-��ҥV_�u5M���ذ=���HH�>ȉC�(�P��V��%P�/�C��ڕ6��OQ~���c�>~�~$�A�=.仝9�~OP��-9�Y�,ȝ�6`b�+��m[tg���lD��]Y��S����:��G ���9L,�i��[Eɉs��H�4�
�E    1���|�� Ұ���Y2(��g�    YZ