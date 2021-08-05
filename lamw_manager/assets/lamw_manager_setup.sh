#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1756486782"
MD5="d383cdbf09371df3e1058e502fa61d64"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23744"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Thu Aug  5 14:39:20 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����\] �}��1Dd]����P�t�D�辄F婨���Z��d�S����I0'>�8��'���c�w����!g���*�H��o��P�RԎ;)�oOcz�*�8ħ��q��&ʣ�j�3B����Ÿ{$�:��쾰�������� �Ԑ�w���xr�̝��Z;��������TM��9+?.HȤ��F]�B0���R����"ZOPHd���y�E#���1�Zy
�&r��.-��Q�m~���z�,�q�]�{Y�����<�ˋx!;���sul��M�4��x^W:TCQ���*��Ψ��`		9�}ڸ�֌}�X4��I��
^�F��u������=ɋ�m��<��+�V���`rt�a�Ȓ�Le3�k�쵌Ћ�7���#���^Ӿ�J䨗	S�&��lD���F9�d����Wʧ�`O,����څc����c�7�)�`;�3[4�(9��)��+��N�D�^�IAk�u�zE-HRq���� �ʸQ������ژ[�N��#��N���L���i�b�I�u�3�U��»,l�C�>�s�GHb;*ޕ��۟|J�P�k8���4w���V���u2c��Gr��0|b9�Bߚ��5��,M.�Ve�	��P�41D�w���z�i�m�\�7þ͑R�[E^��3+��]���i��z�,,���t�jx)�5	G�d�6�IA��p^RK���d{2��s���0�Qq��EĪ>^t��)d��� J���0˽��J[��h,���BS�CF�p��X��Gki���R���f�E#_�?B�ѵy�1ꛩN-���T�\@`o7,��4G�j�% �*o'8�D��y���cMr��0�E��~�9o�c~�~!�O�p*hG �ޢ���g��O�$�_����ʺ�J 7��Y�P��F�'(U�,J�"0&�q���F���>+���oB	�n�j������-���S@(�u~��>LWLD�Zf g 	
��a�:�Ð�F���'\�1�����	s��5��|�1�"A�oO��=�a��\�Ů�V� ]�O��/Cؑq���xb�߸�9z��tx�W?�RE��-���$���jB����i-d��.�a+P���N��'��]��Ƞ�Ucؚ�@>��)���>3)����/W��wZ#jkDk�D��"�o���P��?;�)�rZ[��f��R�{�W̖�r#�nہ��	y[��ǁ��Ϋ��7�%������c-��-V^�C/3�@�AL�qM2˝��n�A�a-V��a3lj����C4(�5�Nx���]���J�-J"1�+�A���^���!0QV|�r}�`E�QOO�n����[����{�� �6��w�+f�q@�cbGLt�	�Ɗ�
f���w�Iz_+�?�ׁ�R�o S�:&I3��5��r��)��)j)�����^e\��F]|ľ���7�.�@�� ���J�\"��d�n��Oʢ�";���T̆y��a������G���/ s)]d��$���Ô�#B�-a% ܥ�K�r@US����
�"Qe�؂�Us��d�:2f�Ta��j�%��ښ`��Fh��O�'�e����zp*Կ��y%�w�SH��ˑ�ݱ�2�}�Ů����l��Gx!bN45��q���"�µW�D��A� p�5a��)TE򭅙�,�wb	k���v�����)v9N��r"��g���!ܨ��pC_��Y�����^r�\k�1�#���l��\�,��Q�עhP�'<��;xP�O��H�Y��֑��;M��f��J<��Ǯ�	�L�]��I����I�Ec,z;!t��N��K�M!���DU��lے �1Z����Uo�}o�pq��]�ڳr��8���3�x�����y��AR^K�fP��%~�+�ked���x���&٪�ӀT$�<7��-������峾�D�f�Z�%�Q�8HL�~���dc�$�ڣ8���`G��f��Ԭ�`c�x���4jsr�g�z���a�e�P$<!շ��	�E�U����YS�줞7P|�{���g�[<����{뫞w����~'��x�_�펁��m��;Z�UP�@&YH����D���Q7z4xS��0��u
�;�>?�_��~�uY��Ћ��PN��j Oл@W�lᑄzި��+o�y��O������iB�}�i��3|ּn��kt���0�e�-*��*�~���[=�;�S��7��i�@@f?�m� Z�-�NI�%P��)�TC �ǫR�t;�@��?�]MA!����.nk�?���o�1��:�Y����n��z���X�H�~37��O�U��;S�[���đ�|0�l:O�5�d��`8�vy���>��;�c�O>}�|�F��p��o��9���,૷�����䀄�j�})��ǉI0=������l�ׇ�42{�
����P�^g�Y���V��,�L�f=��.�q�EA�%�+�᫮�c�kn5�Eot2Z҄�5A\|[�;G��)ݸN潉رy�s�t�T�)�|�t6$��X�|7���������hia�Z�'G�c���v%�8�L�==�̨g�e�~�gc�Ipd�g⤺�}�j�].�G��
=H�#EjTJ�R��u$����������tG���2�9l��~�x��(Q� �IO�X���Q��V%�'���Y3�償l��\�q�R�E��^I�$�`e���K�[��I�aSsW78"�~�tytv�ѝ�uL�)���خ��W`Pc/�t��]������,X�=+z�\o����]���uq���UҨ��DF0U��R��n-��|ED���L0���*������
e]��a��ؗ��� 4B�Nwj�=���d௣�ޢ�#�.���A84_��
���N(6���O+��^�l ���<8;��n�Tw�qyb�t�}�e�@�k��GB�����W�~���MJ��ʚ�n[�x�%�F�M����O�YR���#1�:+��We2Xh�Ý���7ʌ��d(�k ']H�n� -@}���ii;���H��
�8B��,���}���4�Y������\��P̿:������f4�T7s"��b���3JZ�#�Z*(&�ӳ�U7ʛ����6E�����=����赃_k;��������c����4��bϻ���5+���[+�)ܒa��I��ȭ�A+_��j<B/m�{\�l����)��.Z7�#�������Ze�W`ƀP�����dj��bp�i
��Ǯ�|d����72g���dY!��0��)�:_j����ڀ"����|c��n�6����erF�>v���&�� U.x�̓���!E�� W�[X3�q����ႈ��,�
�t��d
9;��Y��.�T��A 1�b��DF�_O�B5�N�TB�{�[�D�n�B�u��$���5ʋ���s17c3푑i��A?���7_vȿ�lDz5L���ԓ�L�ɓ��e'��e=2->J~:��L��{���dŌ�����uA���һx�B(GY��я����.��z��K���H@��Ljě���ԘP�>�Ý����#��Of]��Ҷ�A ]�F^o[�"=4*J���'�x<�0��"4�Cn�l�_#��&v�	�C+x<�6�tׇ�is9��a�.����Q䉸��,8%!Nd�@�|��綾@������d�!��x�ؖJf���<V0I�V���	v�)>�^�=�XT{�2�e�KQ�������^� $�+��<�msi?�C������i6�;yo����}�B���[6j�?v��;����JJ����>���4����ޕ̈́;[�X|�٦{;�.��qO�IR	-�{�~W�}�Z�,�u�TDO�ʊ�Q�X��:Z���Q�y� AU�7
"}^�u�M�`��\�D��ߒ��u�	��ߩKz\IY.��r�ˡ.9U�r<SMQ0( 8���ĕn{H�a� O��
�'��5]�N)���-�`�,Bѫ���%��%V揗����X�x�&����	덼����T���]�|2@-��f=ʈ���$�MI��(Fj'���WC���=8�a�Ȯƕj�T�&��oQw����K)w1�5h�֡��B��)�o�ݜ
k����E۱n�T]�d[\�a��&�~�%�XV�����u1n��zk�#$O�
��(︌t�V3?ٓ�c�Ƃ��Qti�_��7� ��ۿ�5�y�e��r��C���[��~02p--#�8�'��N��B,T�! �O���H�6W�M��Ɛ��&�X�Җ�#.aR_!B�K]f��D�L��� 􃦋�A�kʚF}���0����`��y����$�&�Ya�S�^Ψbru[�F�nIM��ˀX�(NkEk8�.<he;89���z���O�*����&1��6��ŏa�r��/B-�J���3��hP �Dq�?�̥ۣ9r\'�� I���ҚkZ�.���̀�����?S�RT|�3I�S֜��Wr���ʲ��H���,�ZyJ�]�U�/���r�CVbJ��
�T2�t��y��*�-��r��Z��� ��у�mҡ�8��U�u9W�������V珥6#ZJ4��E��U��v��=я)����E:sb�%��(�p���l-4�7��U=�]�$���uBc�U��Up��iI�DJ`X�V^z�E����.��I����%��j�dR'����4`��`�Ll���#q���S�|�I�.	Q�*�B��v
�F�CN�ݨD��ZE
0�6�� �NP �v��X�ϵIQ����d�A~��8�t�������r�N�;�r��s��������I�lJ�+b��<
+Y�_�	�wit�N�d$��0�0��/ޯJI��1jL��u��h���j'vel��nI[[>щ��;O�o�b�:_��gbD@��Y��cq�,΍!(i+X�f�a�M���	�N��r�`ge�h�}�4ݏ���G����m>a�@5��a�����u}�,$�6U5iڟ�(k���M�JD�y�� 9�/  #rF��c��������jn��Ah@Rڪ�p5�e�7����� /�jvV�Գx����q�x�\$���������ia�:t2��.���=7Ԧ��|J�l��Sf�La���
4��2�]���n%q���[��r���g����1f\�|�
η�R^a��sf�󿧅�7�v��<��bmm|:u���O��فBmz�QZf>x��u��'#�.FDynوwԜ�������&	��HV�R�fݼ*�l��LP٨�cB�Z�����]�c�Z�9J�.�����|����mp o*��eV=��fl1Q���������nh�����o
O��l9�j�`���{���k�H4/���"���
�+�ᢖ�@"��J�0�a�IB������?���b{H�����-M�����[ZO�üfބ����ap ��RL&�>(B-,}d,pļ�C��ޓ�{9�NC�fU��NN�B��I
��xxP�˯�'a�b�u����$m�=?j�ܶj�F<)�&r �vM*����6�첌d��m>�sz�6Ϻ�`b����Rpq��V�a��r����Ĭ���O�O~Ԏ��4x�8��$ �N�o��x���c�F��$�G@��X�vJ���?�&"mly��<���6O�sG9�a��u�PNL��K�oB7��A>!��{�(������l����~���Ȗr8�����wF���[����r�����0K�DרD��^�F��e�iP6�'q�T,qL���p#4NQ}���3�mܨ'P�{:dF�:S����IƐ�X�*)a��1���i�t?�'[3����VwO=��+yt�PENj#�&���z�ke����h:����2EP�4��/IJ�����V�Ce���m�o�N6���U͒5��k0���sq����+gB�M�Ę��C��/]�lW��B,(mGH���a�Q����I�YX�}��������ɫ�6��#^?1.�A��U���2z@	wW�`H�%;V�s�e��#�v�ē����J�T����:p��~�)�u���R[*:��1T��b�gb�Ӓ��3�i��C	J�F�x��Bbŵn�r0�SSN�#���Q!����	��I ��]�	��J�вet,�A6��I9A�kpT>�E%��tn���MZ�%�A%�v���P1{��>B2��:-֚'4!�pg6���d�4HvC��+�R�N��W�#�n�e�#�ͯ�` �ǅ���Vw��_����"���qi_�\OD$ĖO��'���S>�B �t��SWAK}�������q�m�$�"��Ghn�G���$��`��E& ����Z�N��}��f7��F-�
E�?�k78�} ��0��-K���ŏ)����\>�@��M�K�����n��/�!���m���b�� Z|�[5�P�Gr��ck�X6�W�_b4���%�I��	7��h��1q���O%ܴ�ħd���.,��ø~lz3�8ş����yo#��:���#	9���J�-kKG�5���t����yD!J��<R�	���&b�\���$�_n"���yh�8q�D���<ngY�w$������PG�pt���ܸi�Q�+|�F�7(L�a�&䶉�6 ƸB��X̢l�-�&#er�"��V_Η
��&UHP�R�M���5��u�{��bjT�L�UA�b�R�F�p6�KMS#R�����rÔ����~�z�be�x`���֋s�:��s��X�T7"�A��Ǚ�t25��F��0U��yx���H�����/�]��:���� G�C��)s��}f	��ǆ��7&p���rYC,���K��x6a�K�^�-3k��]^�(�HC(:�O��[T����u}�ߊc��&��Uj�X���f�vU�˚LA�� ��`ܼ{[e��ez�zs�]zf�/{���c$�3����л�4�)\sPGX ����=s��& ���n��l4���J��4M�u�%�����Ew$l���X��ߚt���.K�I����?�+�2�@�<:u���:)O�QO0'�?v��+�,]&����Kn!�X���\e�~9b<舱^��xa�2�Wp�
zf8U��p�Fxh{��	0@x�3�e�g����֩y���h�cP�F�2W�9ѢB��<X���"���3��i�ǑO�����q��GUz[���(�~�h9˸!�ŕ�j�c��Ux�=T�����"���7�nh�dIh�~E±7!=Ct���tHn�� 7[�疽 �zP����J+��Q;4e���u� �6/��"� i��V��Hח%^�
��M0��}{�3��ߧ����U�	W4�p�]P�
�\=�����f&_�*�6<�u��|�+w���p�u5sN���Ợ ��@W��W�b*`�#$KW� ��~��
*p�e�y5&�B�*���h.c8[+�������ם��[.Kr�odYBٛ@9���f��~^m���d��Ĭ&�0���P_s��m��� ��M��݂^�1��
B^���갑��NI7�����/��ʤȉ��Z�q�"��,�VE�s�C���$�0���	
�G��r�M����.r"����s���J��+�#��?s��O|�KF�H���g���XJc�Y:�t� z�!�u���&+N��e�UoNZ����b��Fx�t�N�sЬY����\�<Qq-q���˱-r�sɏ��6L0�1��+ưaW�GU�y�*ˆ<#?~��9E������Hz�8V�Ԑ�|�A>�[��M��Y��_�TH�5����0�?������F��2?	�-��Y߃�\���۷ܔ�|�Щ�hˈi����&��������M��mݔ�Gcte1py:��yf�ώ�6�7�U�P��E2��>�5�~K"i*t��:�������h����n��|C�{]��h;�B��Ա�Ӻ�9|��/ 3�X#�$�ڕ�5�(��V��gz%+����X�d��}�2mfŴ83B�������|e�+���[���=��q ��OT(�zܛ��mo�a~�$
3R{U :�?^B`"5��a�y��xD$��v �p~��[L8���|sV�Gb�|
I�APg��!��Ź��sdf�Ḣl2#�
���}S�h��sk�
�Y���T���N����*E�%��D�B��Vb��+��I�cP�!^���"7�E�8���@/%����?�:�R�\��sw��-W�Ԯ/��#>�u��6<�=��;9�5mNS�\��g�[��f(m��������x��&�W
�c��i;Er���Qz���6�����&�W�R���G�P?
4<���ÅO̞�,W
���/qN��w�o����2�z�k���\�7�pcufEv>0�m �zب*��}�u,ݐ~;�~�z�	N#9�y~�ß6���7�'{�b'A1�/�N�27���6k�y�����&z���n�M�+�t�ѐ��e �øGe���=�ҏϻ1�,*��f�
����_�:י3�y	�BZ�7X1U6U��xgMO�V��h�~Թe/�K,��;d����VŪ+,`�X	s��k<i�t'�s�a�u~LPt{h�5</ۂ~SG�WE��*����Emn%a�������ڨf�6���*�&�K{�����^*sN���'1�����|�����p�����T��ѱ����v_���yS��I�����b�K�f&_cnM�T���K���"+L���E s1R�L4J�B����0����)��!/�ܝ�I�A񢾹�X��b���D�9����H�~BD�k��f�7}ܼ���ԗEܨ��s7�8A`�����ث*����y��&u����(�L���P��Mco�N�
gʧ��u�%2��Xx�3�4@���o��daI�d�ڪ=�wu�9_�]�r�iYZ�˼q-D���Ƀ�4���r~�	��]G�Z�W@ �6=ԽhJ-��"���&�h��� x��NfI�
�g��F(�b)�"< �1�'~���Y����_�������EgZ�)����Q� l�����g�[a��"�B���}��h���Jze��G��p�ؓ4��yòZ�c��j�y��,ğII?���8��W���,��G:�z��K�(!z�Yg�O��o��h�?�b�s=��\���W$�޿Y:��$A]$S@����G��yz*�&�a\�C�S��-"��O�!�[\�@������,v��g��)k ɻ��'��h<��RO����� *�?V&5*�I�U���(+���t�Y�1b�T�%��EHy��&�/�гI8�u�f��-�5��J�WW�;e��ة��_�����L�����zWͮv�	� j�Q���4�
�������͖��(���ҡ'J �[_"����A�D*�5'7bf�/��R��o��;r�ұ�l-pݤES���r���#zj|�s�!�ᓤ���]��S���w� ���u�A����$�c��λ���܌��~�ΨН`]��o��2<���[���~~
Lɸ��]�XŸha�x3x����F����Y���%�{�-~ѩL��";���W��ޏ��j�3�a�Ȕ�.P2bs��I�SGe�A�F���t�>{��������=��������-�Ѽ�A�r��{)��G(���R��$)�3����d`�0�)�-8��|�bG�)I�#1,Z��^9XUDE{4��M��NХz���bC�L|P_���^�Cr�ytr�-h���+e���w��Y���U+^������=Z�კg�X��:ݣ�$U$��*�2��5U�B �CZ9�?R��-�W��mcAm�Ae�i�7vɇ����kP�O�us�`c�S�m.o��n�D)zۯoi�XP� o��D#sM�6�=5�@Z�˺�-����k,����)u����~��/�����0�E�g���ü-+��C�d;C���S�h��{}h`�#��������%���Bi�����ƼjwS9��D�mE���a-V�9����x�*�J����d~���*�N�[�}��P�7�\�LB6��au�4����F����ӹ*�?;��"��S톓Dqݰ�P���r_����'jGC���j[�����C\>�o;�B�Я���abG�8H�����-���D��	U0���a$01GX-f�~|7���\�k��@��G��*9��#OЈ�t*���	�u�ohu;�^�!_h�G�Z;�R�zf$��LA��kXn�<��C���/ >���d���)G7�N����%#����ٮcNK~����[;O\�*�S(�g�O���産v�]Xl�ۗ�)��P�'w(�#�����CG#]���)�n{ǆ��z���-�l��w���i��oK3>M����yO3,p"�[��_�:��$]Z��L����e�j��_�#�#GМ�TQ���=sbG�+�3�>x"_?#��Tl>N�2Ҍ�������3h�y��5ҁZGޫh���A����yQ4�^��<���-���xc��BH�ڶ�
>�."�/4I��T8U5��'{��Y��>�g!J��Y{kvYG��"��%�F<�뚤>oh�L&��8�x��.u:����#���rS��1GC�X�?j
B�y�-U$�*��{J�p�Z�<H�t����0�p�K1_%e�3\ozy� PL��A���@�V)`f=�̒37:���J7q7�.�� hxJ��D\S�p�O�s] �nJ�1���&�~�[G��)��)��m��]T�Ѯ|晊<O�n�:�Ղ�(u��[�B\��n_�Vӵ�gqP$g!��J�?"�ܸ�@�6"�֫8��a]�j�J%���P2��*���̳5%s�H�}�'_��k�a_KH%)���E_]yB���~oKj������b����J�I�Y��J|��,kn���}Ǯm�S�������L6ɻ�SEچrxާ��6�q�����L��M� ����p�II����pUf��[l����B���%�Lz�9�q��1Z_L�����(6q�m�Ch��"��s�|~mAw3m75��;�����[�f28&5�6Te{2.e&G4����/ׅ*�!W�뚿�_-A�k��`�]OZ63-�2k��M���~��[��ۉe��@�}�٬ְ�$�h���汢��x���$�3g�X���K�����ޝzU3������ۭ�d�"��mv�F�qLo;	��$���J'.�cL�u�w{�� h������+l��a���]�ONW�H\�UЩ�.���
�������5/�;?�"�f�>������kd�01nEľ��6l4ޤ~q�����{��cD2?Ƃ?�[\�pN���d����Y�2e��),B'�{C�FD,�V/+�CD>��K�bx�i��6��5��9��(4��u���Ujk���Z�H��T���ާ�!$���,��o��0�k�ErJw�����1}費+l�{8��nr���
�"�K�g�f�r�he�Q�M+-(�CՁ2DY�>��]I�MEC��.���k������&8*�/�A�tv#���t�+/��Q�kwE���g\�~�&��d5�#�
PA���b"F��V%�"}��>���(��T�N��4'��Y�����/^�N ����]�Ho��	Vu���\;�oL���N�H"?�㊨�
�>�)�|�m�D�O�p��8f���^=�ҾZ�HR�(9���+`�_���,�,RP>Dn^�. �h Xi��#O&���� �����6'�ZR���	�y��2���K"�m�#�������f�t�/:t���4��_d�p�p�D{�|}����-=�z��a'� ����:򇼖����!�ZA��Ć��Vd��/~)��!�Wn�~�$�8�]��1T�t��MzHU5�K�ζ�5�b���_R��1�H���'��R(�P}Z^Z�a��k���ѺJ�*(���m#DBlݥ��`�64�7�\��d)�)�+D���~ik��S,)rwJ}���	�x:�X��_sg� t�� ������/���Z��9 ~��qQ��2�EO�-����Ӹ� �hz����6�B/!�c�Hɤ��$�6�|�K�mڏ�:b'HQ�������OF����PD�3O��/�K�O�ƭO�����k��<�b�Tj�v�M�%`.�f�s'�n�4�������Y+�K�ŭ}KՃ��aL�+sS�G�"s��B�O�����p3d�ww׻�x������������(!EI7�
����J2��R����LX�*:O�$���K0R��ڻ�����C�������j�'�a(�밎�������	@�ș�0Tہ�҈�B �ܷ�w�B��ǣ����OqRQ��y�g�Qȧ��]
�4����>`xf��2 }
�W�ׅ�V�U�t��͟wKE!%Ʉ�-g�t�!��8�M�z��F܄�I�h�@����!Y��G/N�����]uC�'�˛���������y:��k�6`Då,�K��ʢ���`�2�6�O��%�6t��_?vu�k�r��y8S筹��� H�]�u�6�8}�d���O���)u��(�����$��@'�+�
�0 xp�:�jd�(ew<��BMT����ʡ"&�s�ᙰL�d=xxyF���Y�����2ٻ��{�m�d��k9�e�ls�M�
��r|��C7�i����G���jND��E�kѰh�w,L�ߒS�#�����p@;ե�f<
��c�I#&ʿ�X�9�
���b.#�R �HLƧ�Xg8��{�P̨m<n5_5~�J"1�ؖ8�|(��5�t�wx���x���v$���j�X�A����`N@c!���yaM�����#n���_�;��M��h�h�;�Ǩ�#b����uЛM�Pt򪅎s�K,�6?���*7�r(imL{�_�P�U�d��E!m�;@1�#{�s��i�ĸ�N۵�&�r.}��{�ꋑ����e���Q��c~�5q�����Nq4�F�}�pl��4���Ld:����g.�4 iv�3�*�RQ��m! H��&�K�b�+��`�P,�'Vo*�(�	�E!��dX����>�<&*p_�B�P�{m����X��BKj����P{��p731Vy~����Tm"�6��Ac�B|�Y�%3*�)x�du}����B�D��"z�����yQe��S��r��	(�X�u�/�PcFT�(�Oׄ`�X|um2/�,g{��Y�ඔ1!�'Î�](�3�lBMu���� �5Ɲ�/�ӡ�j�l�9B�t2&�}}=9~���0�0|�L��L>�� �-��c6f�ɹ�+�-<u�ྂ	��́��<~x�8d~
"w���O&�]3fc�(I��<y�C�D�$�w�� �W�u+w�� ��z�b�nFZ�.�$�Lx胯v�>$ץ���u�$��{@)�r�x,��l�׶K�����"�uJw������!��b�DZZ��P�Ow��o4RV�qu.����(T�9�v[��\~���Z+����@5�?����v��ݸ}����ͮ@m���%�W/	U�K/ﺖ��fI�3tF$/�cLĝs����k�4ǅ��Έ���^6 ݶ4�>F�9���46_����M�t~|�~lc.pQ�0t������ H�2,�G�mĆ����q���H�=�)-���9+mzMs.����")���0��P���ƕ�����R���/oe-�'�}�|�MDU��}��mL����|t>9�K����`�ue�>�hg3����rG�:2=��R��ڢKa�+����8�%Q�!cOS�~��Q�#��BA�D�S���������&� �Y@={<Fg�y}��f�5�Z�r3�V�?^_E�z�Q��xG��5^�"x�nN� �c0n
�.EJ����.*6Y|��(@;�-UË��*�X\�� ���G�~����D�vPp?|W�@�Q|{�	�bK�T�<�l��qG��:�ѹ)ޘ�A��@URά����9�};��i���"��k��Fy�f����� 9��"�h3Yn�c����t���G��2���3?���<W����7���a�u<���TN��R����-۵�T�Ŝx�(p�Y�­�����p4�(��v���Pۿ�xs�m^���M���!z-!�5m���3:I� ��"sKQ�_�$Q�~G�o��y�A��<�������� �!�%��Y��$v���:!@D�x[}��j�iń4��sI7=�9����T���e=F���uyn�AT��R�j���p�J�'�4r���O�!�x��o�hBI�b�M����#���"��=9r!�a��b2=���'��x�sj|���#<㇦p���u��n����U�I{,_x#/�x��;'�N�����)|KmȆ�o�~��J���:����r�I�Hv)	T�?�}^��5�h�ig�d�p�tA���_�Lgp��_�!���@��bP���&xP���V�>jX�(�4���/�]���Z��-�[�o�y�?�g({I��z��[�i��^��-�y�[��(���wRb����ƜmLo��̜�	���7���Ѻ�%��Hg�C��)��r��Y�L��ގ�IZ��UQv�|5��)�J��.��-�D���$4�,0כ
��k���kj�{O8X�aW���+�����'��H���Z��x�5���4�(l�������;{��"Am)��$�oN#��	Dra�Zb[d]d�|	��'�|1�rM����=�!�����b��c��h�F����muh���#m��Zi��&�e�E�5�N��"��H�ҡZI�v�JX�������u���D�������|M3�7f���]��nj�"�~��)�z�̔y����\^/���R��T�^���s�ȉ��yB�F�A�H��!�Rm���L�ܢ@��И��i�e���F�ӑX����{�&���N���@؍*�����l��'ʞ���[(��C��� ��mn)x�|�O�,�a�=�l�o�[�u\i��_��Ad���t<��q�C>Ru��+������&c;�Ow#��˸]�>R�f�s�|�י�;��.˧d 9�K����� !�+�VhV��%xR�H�	zl��&�*�����b�-؂��[U�O�W�3ҽZ��MAЙk��'��������э/�|�YkvRnʣ�֋=���<�� �����k>��?�������z��*t���&Է3r� �_�N��H���L��9��]��J�Ս��Уs� �G���qd�>ט{1	Z@���[��C<����D���岑���-�;����g��4q��\�$nE0��Z��q�և���]�������M%M_q�����Z��=�%�ӿ�ٜ9�Wg�5��U��Y�C�␠�)�:w�����ڑ D���w�ʐTj��^m�!iLMC�Ɣ�pga)��L�SK5��&�mBU*��s&��?��K�������"Жs���3#?&���c�c��._�ft
�e��wgn\�\[�f��{O�##�ȁt��A�װ�O�d�x_^4���!�<H���u�Q�i)�zHAg@�Z�)������ga�G�/
�k�,�^�q��8�Ų�.F�r�dU��a,|� �n�Cڿ�"�P��bJ�lŇX���ts��Wc�G���͎5N��'O�쪕#�1��A�����P��
�E�^�_ݡ�&�������B:W�b��'&�%��\��Qh�x,C���:�1�|r���KG��ʩ�9����ANe�Vg��}�X�
�0/Ȯ2�.�O����vio��HH�a�U8�	�����J��ſ�vC�xdl�$�����.%��V�'C��E�C����I�:aF�$�"�:�/�)AT������O��t削��bd����ul�O�7kj���~C�,��\��E�ѶrRwa����\x���T�n8X��0����sG�A��Qu��PI�Z�t[������E�Y��Ɠ�.�-3yD��vZ�kC��R�j�����U����$�_�
��jb���;��X�t�/x�D���쏄(JeS�� |p�`N�:Lw^EM���b�*Q����w/����{5Lx�Ѭkb�&c8���7ʌ�HF���J���&G��O���0��̍���r��\M�9�ҟ�&�ۑ&�Y�ƿ� �"�r����]�An� ��5X%�N���]�*�X��{��^�|6���=O+6�%XC���;�����{�1r�ڌ��*A2��::�H�E����pa�ߤ--�x������*ycI^�H/��~�(@amc��q#���A���cׇ�/��o����e�-z������;��ȕ�
7՟��B1�F������ h3t�;��`z"$�o�kg%�mr�K��>t�5��+�k��BN�T��4 ������tâ*׾-^w��%�-D��e�Y�v���Ũ�m�O��Ʒb^I��u����/�g�S]đ�������w��C��ml0	f���75|�E{j��H���a2�A�==P9a�����ڛ�
ݵ(��<}y��@Q�"�t&Zt=�m��XaE�wS�'�kPԈ�P�%��Oɡ��L,�q	%x���q\��uf�ͼ���|�C�.�F;�e�"E7�tK�[���U����m��!ڔ��ʪ�w�gw�y��ҁ(�9	���LS���ܴ�� DpK���#�fE��	=3F�[��?�I���O�:�"�y�J�k�>)��]Τ�@B8pS�W(�6h8%��:�'��L^�'�9�Ur�&�?�B4 �K:�Ԫ,n��r��`�����T�9����&�	r���U��\;X��F��k��_ӉIl�P*L����ߪ�Թ�7bSz��I0Ǭ�T�;[�x?�B�3��t�!�*w�U�y'��x8o�����)an�wp.�E�e����!Tʗƕ)f���4��B@�.,ō1��?������=��SBG� �2�Ϥa��}�����s�������r*��"F�h	4.���� �Qn��&�Y����<�:�p%����Hr]g2ZW����S$��@��+m�v������X��G�.p:nkq�GT��1���X�5u&�b#�.�~��%����}a�(��! �)x}%��l�;�%��d@tc�M�9ظ�I� �ߍ2޾Q�8BǦzsm!X�����n_�e�]���L j��L����\SW��M��[����{�R��L��SйC'�Y��`I5$�������)D�gwS::.l�dA�<?]���0��"U��r+���&���?s��[�E��/XyC�A:O�*9�+���x��b���Om����ڜ��Mbm��hY�����h>�lp�,��r]i[7\͆��H�=��Tx<A�����!loS��ߜ�"�>� zc�'B�1���4�<�5�(8�}�3�뼨��7�
�=�:�5 <�ؾ��b�$`u�y��vH��T�ܼ>��}���K-r��^R�k�����ȡ&�TV�Y���X�����ڣp�&�(6�N"r��AWgö#}#{U4N���4>���Gr3%��`V�w���M���X��K=�1^�n��~(�����p��t���ūRR��FR���6@�|9>6G.���vb"���>	\}�L6��yΤ�Ɍ]��A�D(01c���G�������[�t��Uԕ�O�����Ni��9�茧d��x�����^�2B�6s�~fi ������޾B���`~(#UA���Y��v�%�������V办 �n1p�p�#U(����f�h�H#�2��>&�C*U �Y8��< u��_HVx�[s|�YC��ʩ��0�WC��1<C�VfL.�k��x��D�|1�a*�8��������׾��I)�Y��O��ǝ���	�~�A����r���&�8��_+~��k&U �7�fwN�-bG	#�&k���+�1� Z`z�:O4�5C�Ҟ��U0~�����\o6-I�=��oHz����=�9VGT&�����MƊ�3�_ɟ�;��v�����+�`��[���n�a�<!��^ُ�� g*=�񫩅s������m�y��D���asg��j����t��>�T��/ziè'W��צ}x�E1@FߧZ�ސ��y����-N�b��Zu}�azny������^�@^�S�j�ۙI�5�jV�y�r�ڭ	��J�޷P����x��c�NM�n��Y\����0������au��q�aLo(�LB)E)�$���z����Ǿ�3�_�ۤ"j '�_�D�Afo�Uf�]$7g5C�����Y��8V��Ei�&��)J=�R��ZS&����\�A;���T��$�u��k yk�%�pAs�<_�9�lߡg�!�� Yb^aVs��rY�[[��^�y����ҋ֪|g@z�����:��,��M�'4���~�x�^�A[���6p����3��W2�z�/�C_:�G��ɺ���٘�&@8Q��Li溩o�q��"�ϊ��p��$���I����s�?�&�Ƙ�~pUlB�'L�W��u&UU�-9I�>z�q�%#�	~�:�-�t�Y��"�[n���ϜM�A�t�x�9j�7(��S}׼� �N��mHά�*�q�ff3=�K�d2�c��t�Y.A]l	�ְu�x��!nͱ�_'�����;�MN�M��g���;74X�[�.��@0�,5lT�_�"o����9�2 ���F
HR2�-d�zC�N�o���Q.���̥�8��c���&��m��t�6�O�yt���%��'X�T�G�+�u.,����qe�0A*�0a���rWHe��t����H��_�\��4�����&R�D������,$I߱Y���%�қ�����f@�Q�����fz�������]}0�(r^ȝOv��.�#�(+犲�X���L��Q�E�㑍hzƩ�)���V5�J��s:�nvױ�	�����R��1v7r30�"����W�/�)�iB��&e��1��.��)(X�O�O�1�Ԯd��i�fa��;PO���|.��q��/��2z[ɗl�rQ��&�_�T�}B�Z�h�H^�چ�����(!���f�4���TD)����ڗ�_�7�)X��0�ɓ5i�6)��u
W�<�溷*��\����_���Ӈ�=���G��j.ߛ�|6(ԨGs3��O]]J�2Z�;J�iA�@��Ӵ�$���2�z�Q_P���)�s�dj�
��q5?=���p$�(�#6y��)��r8�n�-V*@/#b�|J�M^{�>倖$R��$>1�o�s��!g
��������P\c���=Y�dO��M���r���؇Ԇ��=���^����U�T��������]c=�#L����=��?��)]u�k.��m� �C����Ox�0-�
c�;�qo���3�FH,q#��$m; D���kI�C��9�eR�� �k�E0� 5���u��r��00vsH��&�*�yZ0m��C����9� ҭ�yZ�{|foЈt1MO�����G� 83��Ц��IM'�Gnf��=?�/lQ��]muM�k�h
	�k�\�y�
6;
d�Y�5,a��>U��v���{K��)�g�w�r������m��z�\�G��x�������΢{j��ی�5�V�aw��r�t�O	�z��E�b6��a�w�M���2�Y��T�Ů1��{��J���+k�{+?(U��FG�OA�A%�S���>�oY���S�L����_pbc爧!��a���&y�G���	�[-�m�~���27��Y�wWy�*�dª��o�2Y0{���p�o��mSÐ&���gJ�_[�W�y�U�*�Ol,BSn��vLl�գկ�*o6��u�o�+ܷ_���7U�c��#��V7J�D�B���>��ĕF70���#�C~%��N��M�n$#����Q	����Zm���G�Zq@A� ��+"٬�%&@�RDl�R�v��2��3��_U�6P�Ŭ�<�n�͝j�k�%v�^�L���إ	��y}|��$����0�����7Gi139�/��:F�L�IOkA>�Nj���zP[y��1��ɨ޹\߆�&�ة�c�`�9\WP�t�f�D�Gb��$�Ki���4���#i�ՙ	�ՑM�+��j2�O�8!ВQZ����L�K�'�K�V�uM��X��UX��ǘj˧�`�p�-'�%,n�l,R�C�PL6��=�~*��Fx����C���#�$��n�	��*ƌnh���Uu�I�w)Nv$V�Y��p� ����ҭ��|U�s
��TbtE�`pDU��թ?�b`�E���~ �*�\��8^NM�Y���x/-!7��6c�~;���B1K��
��������_����o��y�U�+��R�+�L��L��A�58�e�-�xIݘݭc��^%�S`T	��g���|�w�Шc�A�y�i�3��Q;^[tEKqb�U� �U�Ua�qN��c���}��1 �ך�6��`�k�Y�_^�V��*�O��^��ڡu.��{�WQ,pX�AFƗ��Nq3*�@��颵�K4Y��s�DM���1>+���K�T%F@�d�K�5�bc郷�r���C�3�&τQqz�+W?��ř��R���	+"���@z� Cr�(Ꮘ�zK��J���ڗB^#%��b�'���������t��'�G�Z����i��$�eyط'ak-1��z�V�r�0�T%��\¨K��S����FJ=�G*�kS���	1Ml�j���j�*��C��1 �����0���J�KZH*#Ѡ�~��<"&|��y;-#��6k�� ���2�m�U@S����7d7�6[A*�jh��n �P&дJo��~`���;6W��N��bR�%� M؆�M~�fSt��A���� o���ĭ�������q4��,���2i���=wF%��Ȱ�E^.g��^b/�k��V<��㪝T(�Z�It.�R�/z`����7)�B5��t��R�Z�o$-� 3��*@�gdBG�Ϋv1���}�vv��2nu�!}�Ƨ]_oθ���&�&�d$[p=8���P=�>#������E���]���m����D��G���Ւ��
��1�ȡjQ���SGY^Hx�
I�Ѿ�m��%[����(��`�@A��ڢ^��*�y�-Z~��r%Dp+uPn��8/ЅαU���o�[�n���\�l�KK�T��%T\#Ic��)�F|$�,����ǅ� &�'�4��P��!�v �w��F�B�7`�^����j��)!�*L��H�.��6G�S�T���efXVOd�	1���NBc���4'|�9<)�y���/��}��̓�_r��rUgqjUR*K�şHh����{�&�ܚX�3
%>,�K�V8��#�[�����Z�Ц��?$�*>�&�1Y8��������I=��O��������z��v{��T��j���3�!8f�+��/U�	D2� ����>4�9��g�za+��-����'T6��).����O��v
zo���=�]�ው���3h�?�v��O�D��Z�T �s�V�UL�r�����M��q19�4l@�٪���Q� �o��W����$Z�&M�n�8H�˨�	"�<���1��,�e�SDF"}�y����4N�\���ܧ��$R4^� �-7B�Q_M-���O"U{2�]E_�$!�^�c���������)��g�[�Nm���եn/+��Ƭ�Zc.� Ĝ�A����y��=�dBA�]v��@w��k���sz,ႌHt���CkV �gdm+ɘ�c#��.G�e_o!:]���Y�K�����K"r,���K[�}5���%��ٚ��u�if��#�xeH��u\��Q�@�j��bO���g�O9�pQ8~��n�ŷ���oF�ېQ@�K�%s�r�'����5���e-iwJ��V6I;$�	�s�����)\��-6�@ʓC|퇙�p�y��W�R2FItǰ�#�������,a�y�<E�k	�f<�H�3ͧ�P+��@$���Yܕ�(��h$#`��Kͫ)i��7�GR(��_.�7lī��KW�g41���X�-�2��Z��s������r�p/b{캧��Gg�(H4}P=\�cGٿX�O�U������`����+]��^]�6_��j&��Y������_�`��`�4fߐ`L�N��nM�ժ2�w'Q�_
�@B�i�� ���+��6�)���I�SU�w��aC�|[���2�`�QHЗ%�y�m{��7�
c��eD��x���vu��٨y5��}�m��ȇr�F�
��1Ee��tH���ҧFG��fNj�U��CbXܛ.�`g�iki�{��U���n����(�x�Ƒ�]$�ҍ���:�

ٌz��x���tEI�@V�*d�UYN
��ǐ�Nzڽ����u۷OWh8�[�:�V�W�K'.iwɳ�O5�b6�7bN�)B�y7�������oU�d-y�KH98	�l���t=����Z/$CS�؅��W��.D��v�1��H�XǨ��ЂA������6�1��;C�d�CjG1)%�M�WB��9������z5s�3W�1&�d��Q�V����L]7� ���\CӲ��zߢ]k�Ba5�ޱ�[ftW-�nz������mt\4�������+�eS��7���ޯD�;�Ҍ��(}�Q��)$�w��'���OY�鴕+g���d��ۯ?�C�RI�cf?�
~���&�+�1}��zȸO�1|��@��]�h�6�4��b����uR%7�{���uDl�k����@�$�=�E~��q�_�Z���ُj�˫�[�/H�5� i�Ͳ�WlUu�0��ϚRck˓�P3k+~ҷMg��)������J�� �~*~�n3o�{L�ƖJ5�q~1I���i_��^��൹��s~�����v��i�QZ�R��w��Q�a���x5�;y>�Y�^ ;�]��Y���|5�;����E;���6��r�Έ���a���ܲX*O呌��+�Q��扼!	�]��G�fh��Á�8�J[HB�~��f���@�ɽf�f2�5��n�xF�9������D�گ�Ƙ�~#KD�������?[In�n�   ��U�<�� ����0f4���g�    YZ