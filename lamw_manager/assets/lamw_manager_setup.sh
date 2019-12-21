#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="899767966"
MD5="cd8573ac15f517a0e79042c2d676055e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20372"
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
	echo Date of packaging: Sat Dec 21 14:48:01 -03 2019
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
�7zXZ  �ִF !   �X���OT] �}��JF���.���_jg*�8�ΰ��O�tϔ�RD< \[R��σɒb1@7u�[Ԭ��uKZ(("�'F��/o\&	�~V�cC(�H�f�r��P��� xz�p����b�_�u�-@�u{іb�H��K�)L$�$�����ߔ����^F���U�Vi_��Wb��p�T��(��b�d��A��z_!S̞�WJ6�\�"#��@�h�F�-��n��er��1:U��g�yp7�LAu�雥[��]!����E�3��y���i��6�ʔ3P?��� Kq�$8r ����Qm��4ћZȊ�}Fz�E@m��2��˛Ǔ�-���&A�d��*�����ubdJMɏ�Kr�����C�-4��-i��z\A��wٻ�{�g��h�$��q�6�%��X�%!7�xo�l��%�Qܾ���Y S�a��D��%9Wq����p��b�=���M��q�a�8�!�N��ٴ��FY>�B�����͊�w��\�ˣ�#���44I.q¼�˓�H�D��`x�)WcjŵY�D;�#�J(s��:BI�Iu����@���Vb�R������'�(�py�7��r#y\�co��rHie�z(/ᔔ4
n4���� �5�{�hբ'�4�H��|9�Q�G�ܪTwP�������&(��?v(�°aff���fS'6�����Ge�[�l�3$��l� o����`���i�4����U6�!Q�^%Mۮ!����/(���%F_�$�@:��[(a�T�ܩņnRCjo��Fӣ��U���{=>�?4�����n*��r��.8�G�����'R����7n�X�Y��7I,�s+E-p�DH�E]��[�b���������]S��8�/�W[�2���7a�d���-�m7��%�M���c8P�@d&�H|������-�@F�!�u�N�/ǭH^A˫p#fk��s��'?���_�[ö0��Bo��-U�%��s%o�=v���Ņ�;�|�>��f�1�4V��FJ��i&)�����:������e})Sg��rs͗��} ����-D}��~6�����@���K
��оc���n:��0��,~J�p>���K�W���<m��Mø����c�l=����oq�ȏ�d�.�"��3N�>�i.���۞
�¤�d�"��|�����`^A]b��	W��wT���=0>��<P�[���]"���k��5��q����E�A*�p��������2��Q��O�?�ڃ)���E�c��z0�S�A������9�g�Za��Po;��'@�0��Eں���)�%[��*f��Ɲ�� ڗlŠ+Ab�������k�D2_��~�Y ɖdm��_b����쩣e`�w�]�"򫳵h_�MP�U��6�A�;�I޴<~}�~f�د����K�۸��a��)-�)]��XEc.����):�-����|¢��'~�~|k��c�>^40�g��q��fO!�\XRۉ�p�l�S�<�C_"/�w^l��D�R�@�.��F��-,�{��H\�+\Y���8z)�nb�Vw��@�ͣ��y�Ew, 7<�V�X^��U�?SK:!*�t�%>��C��S<@ɆZe���1le
�O����'����c�D��@�����,�6{�@/e�@ѳ[� �Ã�t���-���H�	lsh�_�V�WO&G�MV�p�f����M3WL<;�ᩲr�i������ր����Ґ{�Q��0�B����d~��O�҉��5Y{�kB�0���7�>��X'���7+;�ZK��1o#`e�a�6�ֱL�u>%*�K�Y�0��%�l�m�<e��̈�:�1�Ֆ�eYg�$�*5A�ȸ��n3�B����x��Jfh�O�0�4���5\�5�����A�$���K���hR yn������	�ɗ��+q�)���?�8C-�{���B�X�-��n:���Ǵ�tc����b��TH:�7A����o{�O��Ťk&8�^>j�6��o�!sm�L��XOk���ߓU�E���|6,�u�,�XHAV�jg���׹f�b?m� ��A��(ռv��i8�l���%8F!͈\��4Z�]�٨[\�FA0����⯔�k j#&�#�M�����?wa�7(9�dy�������P�(��d�K��z����h:2�	gcôu30�_~���ƪG�w`��d�{���L�_�f PS��Y�ؕ���ڳ~O�5~��.SZ�T0m��������
;��L�;{_2��o�L���r�L��^3����[��'�[!8��fZ�ȍ^o��˥�KL�U=Cx��� F���ധ��x;� G MȆ@�a1�]~�����O�v78L#w��r�/�Q��܂Tb^؋եR2G���	k)��N:�����`�1�_�o�:||PH_��W�L��P��� �����["c~R��ͧ��^$��! ��A	�������)q�]��ݺ��獌i�"w��	%-m�ׇ���g����9���.A9f���|K�8��&gAi[0&��A�!T���k29�����	z!ᚆ�=����P����K�C�K:���/��⫯خ�(]Pt��!rU4��Y2zjt�A"�Q#!�5 �X��x�e�{Qu��l��6���tҊ��Q;~$$����%U�s���,�)��9ޡ���x�ͣ�l���vkP�%q8�bN�i$�ΣW�3s,��>�Qx"��˱ޖ�d	�$cs���(���9�z.�����<�L~���!u��y��{�������A�ǋ�#vu����A��[F�Lt`�"�F@?�TU߷s)��"ɝh��~X���aG���5xë�g�"�r�����P*T�����p����=aI�������`&/p.���1/�q��[�5f��F��5�zL(j5t#�ʈ^��W켭�Z��^�{8r�:U�[��3�돉 ���Me��;��S�i}�>�^�~��A�j��w�_;Il���}�>�z4��F���K��p�!�����U zJ��=
�R掑�y�� ��Ԉ�E4G�i���9�ɋ�"p�V|��r�P�_����I�J����G�B�!���:A��^[R�� q�G����s�}ʈamu�k�����y�J�u�9��bJjZ�ԍ1�$Ǉ�Rm����[:���%vW3�Z"��'b�I�3�s�s."���'�R4�w~>�-a�?*���)�Z���r����-�:X�Զ���:�|ӎ�ރB����3���������Y�cQP��A�������K7Q��!-�`s�U�F�Qޑ?Gd��uy����IBd�bl���Lkr'I\Տ;[)�R��(���̜=�4����7{ml]qtj/�OO�t�i��\W.3�u�&t�N~�z�4��l��,Y�����A`^��l�޿v�K�a�e�\��F�B>�(�z�dX�d��M�/W,N�bǪ��jK���{wd0&T��Cq�Y=S��F��KV�1#fua���X���i�e�;�K��,po�Yʳ�(��>`����		���S�7���j��y�t�g���z�,G�S=\���*��II�A]v�I ��/��f	m.в97�z ٙ�� D��1�& ��Ų�L ���%�u�b@]t��Z{�,&�|�!/E���Y���O���Y�N�%�Կ��f�"��S�Y8'�H~4��,x�����m�T�Z���эxh6��~���o=���ؤ�nrޛ���w	��������t���Ѵ��� /x
�w�a;:r�\M!r��`[�[� �T�i+6��eBH�w�'Tvuk��"O�'��+�M�f��^	x������5���r=/m[U�WuZ3�.����`fy$�e���=;ܾ� /D�@���o�}d��*�q1󦗰F�>���8��A��bp��[�I,��""T$�)L#�@��33�OJ\eln�lc�����<�\t~b�G[^J��$�v�;Ż��:͉ڞ���BU�^�E�A�p�Sݿ�%�u��w�XK6��~\�{k	&�bkm3-T��B5]�,HQ��Y����Bd2M�ES+̈́��YF|����_6��ޤL�nP�h�/qCaMv��ؘ��O
�Z�v�1�$N��|��ꤰ&"9��q�X�O�~L��Tp��-�DL�v�ⓟ�ӽ�=Af�)�؈n�� g������]�������u^��]�M�aym[ �D��A,����3oWk5쪝5����Ǥ$A��5��D��H��(�D����BF��m� �������.bp�@��u���ZG�E�b��'Yr�D�?Ѧ���A���?0W�n	 �8�)��lrA��k;Z�d����'��<Y?+�G�jB�9cŏs��?��O��?�D�iZp�<(^T��C$C�tmSC��Ѯ@7̼��j#�5� a�*[KD����+~�Ox�N�ʗ�-�h�zTT�nA���斘�;��2�?oA
�Bs���f��fa�Y%l�d�Q�����G�0qÐz�cޙ�f����KO�I�6�����`8=n�����]e<��*���38�	s��T��o��)8��Zg�K��6N
X��,�pp�5$k<97Kp���O���b�s'�q��ІeKZ��,�`zV���ߧl�0���~�m$[��H�mR�@���0�b�JW�MfJ#�w�!�.j��A�5���K`�	��)�I�߇��g����n��q�e1=�� 8,����~#�+��[a���a����q7���,�7�gwU���Ǻi�z�� l����p�����k�S��H�l����E��I���c�Mt�y'B����qZ�J��lE���9_>u���_��^��޶�I
�Jf�eS�!.O�ݲ���"�L�}��a�h���|W4����:�.k��p��q�	�+��z"�����Mt�l*�0��{�*#�1��u��� hEo���̼�dZ��u�v���n�s�!^>�q�(Be�c�0={>��ȶ3�K�;8�q�z`x�[0+�����'z`Li�ί�?�B�[/;|�K��f��~}�\�,���	��,���kv��t��v߻2��#Yl��x�m胾ݴ��,�pddQ�2�5���7�<ш���.}xz�N�ּ}�8d��5z b���ep���ZP>C���`��n�)$8��&k�5�6��dD�f6��@F���E'	ߘ}�' �K�{��P0j)�/���S~3�8+���H�~���
��c��Q��o��Hڊ6y� �����E����[��L`=@��x��GNj��t���G����x���T<�-��{����~~i%�M�h��+[^����@S@���cCRU�ٛu�3}dE�����v zov�(��m�)^]�K���8u�������W���rX�]�m��C�[,��8'zEx���|�q�w(��R�I��F�c8p�SQ8����%�
fB|�}�Ķ~K,f~������іE}4�ҩ~枖�6�l'X��5�8b�ސn�{��a6��l�F�c띰����'������%9R��͡5����*��8�2�9�a#Ћ��;w~�n`U��_|���HaQATk}�(�� d����J���˦g*@'N�m�K;<U�{�^PS-3#PJ��)i;vh%n�m������8���XU����|����{�<�i�]�Hhm���n;�-,����[~������F�3s�{L"�'B�����vl����[��/+S����^t~s�J@��#��)�r�I ��cPS"��'�o��a���1^3�]�:�6��_�4��Ɇ+i�2��B�����ץ9?�0HU��`b�x�=*������$�� ۲���C�I�Sr�n��N��?�14��Kc�X��X�Xۖ����Wj��*+o�*���������ҩ��w��m5�VŬ��;ť[�UM�����w����`�cUM�U�u?N̳_.��l�pBB���4�·� 3���#n�������R+�δ晰«��ޕ��I����N�b���D����j�j�F�̓Jd[��աf^	k����"��7Ь���Zǎ~|A�5�?���,�7Nd��18ނ͐Y��ڑ��j���f�������tz}���:[�y��!���<([f|�L"u-��@C���x��t���6ļ�d�(�i�̋�)-߸U��a�z�4t���F�uK�b�;�BH���b��\��������قPq��fa���gk%.���&x>ol�C7.v�NG�܈����#ɰ�,��f������V����{t�v7JkG��(3ff�iLe���x��w����:��,xpހS]4�T�1��Y���]�����{�B3�Ec��Gk����Eh�h��e*����NE�e>:��m���NU�1ۍc�6ϵ>�SB��'d�G�T�&���s�
�����f�Sq�mv/I@���#B��o4G޹�@��q�n����eg�8�$�k�%���3Xw<�c�)���:|��䨪�!G������)L�� W8qG���7�#���T�����(.
�{���,��o��B4�K�����4}Ҭ�'G_R�ׇ��e�*���L�1�5�M}8�	����N���O�e��D��ѐ���+���6�ޫ�<Jk�|������L��-o�rҭ���^$�Z�L@�����LDs��
Կh�r3�rҚ}5�I��I�a�mo@!���!8� O��Q�Z��7̾؄�M�h=u���h�)s�G��*da�2ܟ�s��`s*��P׍����kՠ��D���C�D|�0�El\Y:�A&D9���h�z��A��U�w��)�\��\���M�N�K�|D�:J� ��l#$��;�{��%[Nf;HYa\�NՄ�Ds��g~�������xO+8�C@�zEiv�>��N��I4{�I�"{rr��Bx������Y����%�7l��B,_�����c��)Ӑ�~�֒71�v��>SX�$sZ�vY�PR�(F�t�#��-���)�ю������ߵ���q<҃r�R�W�R����؊L���}�*U�8+x�����g2��yO�wl�H��|���+�W� ��;a(x��s.����5�H�,�gy�iX�Z!�~��@����~���[ܵޙ�����_/�O/pѨ/�/{8X9{�qۧYJ%�O�A?$-��|���7m�4L�O+�Ɲ���!Ļ�$��3���������������5��r�pK�*�
[��;nH#�40-/�b�J�Nd�_'���[�I�����!{��fQ��-$eL)���Z7�i�Չw*I|�����N�6�0���`����s���{f��Կ�f��8X�aLZ��^�!0"D2a���ߔ�x�d�͘��G�\�v]�s^C����Ů�~��`q��}Lr
 2��A�O�:7�}jչ�����\�r������q�C��e2���k�I���նH-����-]w���h(֟VGμ8$���W!�m��k�kT���5���[�*ǹa�]]���r�1k��y(T���[����d-������[ T�h)����jK����FɃ#n�䎴QE�SY-GH�mk*������~��E��F\y���{G��P�����4!hȢ�5G��F�Ak��R?�	'��9�|K�c��D�)ඤ�{���%��5���iE(8�H0T���N`L�O�~Cf�;����ݍ2m�1���n �3���N�7wnTWْ�璿��ޒ��B�J��əI7/�`�[�C�t���
�W��	��\o�B�����L�|=ꍡfX>/��n1�,vK7�p���B��$����5D�@wT��>ݖ�zSԯ;*�ڴw�5���F92���v��v���K�Sd��5����yly��h�Y��s����Q�L�������LI��m��f��}[G��I�����V6�Í2X��xs���_��#Ȩ��%�:��˷��V�G�N=��%;Eͯy��xLd%n��$����,3֍�%p�N��V�+��;|A��qM6����v��xH���'�����+��jt�#$��I��4@p`�n�j�&y�Q����a�$[V3�ר2�����nة�-����;C[�^��30j��;�Af�,��PO�| l�sq���Q���ǴX��Q��@�$�V��4�#�{��W*��䗀�W��4�D<D��Q��p1jEi�r���IQ��ۃD[�d�cʞ�/��dDIP�*��HL9��fU�8����R0�g<Z�PM��_&�L|@���L�=_H�&��V�&0�j���C�sL������E;��"�+�!�P��p�n�^�~%$D��J�'O��c�;S�U�?I?���X��.���s�#�GY��,b�Y�0K(ic1�=�#
DHت����RX�cH[��&阿�P{��j<��k�3�D=���^�J�N��+�tس��&��̽BB�d�
�-�$�})���N��"Gnr�eޣD,4��F��?��mN����⿡V����4P~��IN�P�ڎ|i�u��um7��=ȇ��g~|!��q�4�P=��s�io;��Ұ|&�PE���L���F/��º��"�ƺ���i%çH�Xz�j��Ї��Zw{AN4Y��<�7��y�׋2 62�Ҷ�I���ʎ�JO0����J�6�liD �?1b��U!��Sr�?�y���=��&E��,�BJDzd���&{fZ63�":(@/#NeV�d�;?�A;�5'yZ�k��f�/ ��QL��]8p8�����m0f$+�u��;Pc����8Wg��$0 ��m�����y�a�r�u�)�i*{b.kl+��l���}��F����>U�P�7*�嘧$�SFa*I���	mB�wa}PV��\$�+��f���D|��c��#s�t�	�p����(���E鷌��}
�*�ۊ(n�b�"�L̋�W�WP���c8-_�4�~�DA�P*ӂ<:���"����nD�;R�� ��Z��o�)W\ʓv�D��h^y��#�i�X`54�$�W�j_���"�W�Dn��Um'x`+�!!X���/�����qrQ�}�A,-#�k8GYهUTܳͷ��?ٱ	�m��ZFSp���m���`�m�B�'B�N�ԃ31������`�5��>�a�(B'J�[�g���?L�n������g~�]J��H��������;5g,>�����r�A��ǀ��@G~�^�	�o+�;��/�6��9�ѷUu�?�OqQ�y$	 
�~�����o�ged���5
�Ճ�����oBmP�4�K������
d�1Y��AK�&<�~�%BEp�믵�$g��L��N5���g!�+ �� �F-���/����;��Ip�:@��ж�����}^�1�-�jd&K�˼�����>���w��m�b�S�e+��6'/�Лa5��B���	$�|��Ms�Op�}��Q��:H�����㼞�
z�q��y�Z�JB}�>mH:㚶qۢt!���w���o�<qF�|�°/k����%�jBGq�'WW�i�nD����<%��O�@l���
u�v S�5J�\�jZ��c/�Y�X��&Zdj��LD��� ��-eO��s���A�\�o%�Z�3_*��`��`����L�o ^�����Wm�g@�ې�S4�tZP���f� ���Sh��c��}O畃Rƶ�v�i����K�X�8���g@��D\o�'�^Sf�q�u^@���G$¨��b�A��^x�D��ż%�?��0�;sE���iv)����^/#�s��3`����_ >��*�#�e�"��W�3bM�1`^v�r�2��lH�*	b/,�<_�Pi�*��÷�e��uN��A��{L.�/!y9�:P
�G0�����cy��5M��;�J �P@�T%Y�m�i����Dئ;��=����6�@�����?01�0`x�Q�BF�UV���8�2sY?�Ŕ��� �LjO�Q&��g>x۸��}����H�>(�{I0���}�"ػ�ei��=Ob��<�g�~�Q+�-�(G��ڻ"�8���Q��ў9;�"8ڢ���*���isf���$}�Lp=*ѭ����>�� ,~Y��ǥ51j%f���ӽ�	}a,�r��
��0j�A'���^�4SXh�ivY�2���#���p��ɺ�CI\�T�N�,մ�8��$�Jh���//c�J7�d�D.�1����d�[�S���3Q��k��p�&�s�QP���L�,��y�������p��3c�ױV��H�3?G;)m%��C~0�_n �!.! 2o�"�C�P��A�o�@���z�6�[]�	��o�h��~Q�&Mr�2�g���_���t�Z��������!��� %����X��GG4߀���߱v�Lۮ���k��>�"�|g���?��Y�v�G�b�\o��(#Nd�2e�2�2��t��t+ml8,435�26�\���S;\�r�Mv)��&[O�Mbs�������48(�)G�#�H��hO�`��z��]�/B)��GJ^��aN���Hx�����YFB+(>��'��
(�2�T��5�w��	�Vl�{Phu,Z�_�ᑜX
�s�H#�;^"܃��1+j�JH�y�kv;:G�}x*�㟾eNTu"]��}��2���\+���3�6UoVd�3!2��PI{�7e����F2��y"���I�e,�7ʧ^�؈�W�M}�� �Jݿ;���ӵy��K��k���#�"��!i���y�"�Bx��"3R��ϨC8�|[��/h1�jX�f�v�9+��.�h僴.W5�Z%�QڠJ	����p����=$u6Rn�7�E_B�����Y
i~b��B9�`�tPw���F���	�A�JF��ci�rV�0Z�,�XV���w9�3���h�˓�3ȴ�d�D�.�O5�A8����V�m�%80�N���a�J��!$�q��k@�)��ƈ�	�mw�ؼln6rxg�C
�90����"
S�u�@��(R��oEvQwR��� f��A����x�-גuI#YN�֏���L�l	�����P!`!��0QO�]
LIW�j�j�F|�G���c��l#7ڙ���JtZ��CR|����>�n�����ɿ�p��v�B؊	�����+.��[@�x^ @���0�����{#�1�����KY����Le�dɤ�Er�1�����`���B"++��)j��I9=
N9�ǔM�����e��.?Ν2�`�[h��j�߂�2{�h�o:����ЗlH-(�р���8}���VO3��Au�1��qNE�a5&�Z�;]��a�ao�i�5Ԍ
���rmh�导K�[�Rw�G��V�S��R��9�wS���P�A�����$�)W	��Kx@���9��*���X��n-ꏑ�-0�����*��fpJ=�@�4Յ�{�/����/;��J�&=��� ��;��gF���,���T�>�/��}�$y�(éQD"�P�U�a�Q9p�<΂(�H�#;J����<��ǫ�$�5��+G�)�3��2&&���>�R�����N4L�wU��K��l!�!
f��& �$\�99mք0$�'���8�Q�xA��aX��/�-�
h��;D�N��ri!�\*|S���KT7��s�DG�(��E�B�M�����G-9q�ۆ]=���0��_�A��b��ʛm�9�{qkeϾ$B;�R�n]є�V��+�
��߱�Gf��~e�ݵ<Ą��?m�������e1d��1�-�g���zE�a;o���Dk��e
������ף~m�Ŗ ��A]14
�um��Yc���,�I1�p�4��~20 �!#ݝ��҃d�1���D��n�/_��z��4���K�@�7� F�L�|�J�I��M��ڐ�$��*����Q*�[h�KN��1\�3�f���8Om��P�O�q�p�Ǯ��jMV��1�B�����Q�<dH�[�"�G 2Q��3���3��1�s^^A�:��B�������G����y٣�:�)�R>����vǓ5�ɘM>���%���
�C���r��꽪��M�X�t�&��Ţ�g?N����[˯���}��i򺈇�y���#�2��4E�޻m�w��A֦G&A͊u�T��i��m�T,D���?�5�������EaS�s�yZm	k�QK�m���&��� ��
��Y~	�H�����Z�հ�����K��Dd�pu,��g�:���ٲ�r�]���\��
�Qd]j��x/�Dؗ/�7��Cc�g�慦���#nDEya�˶�wن���Ƴ�D��ռͳ��(��r�EHYu�|b���t���ḒKx�]W�g�( bS�t�W*]���aj5-T���_A~pb�&{'�G�s�I���.��?s���ϔ�k1���۟n��r��(��ƤV�
��^�W�$�90�&��:Г�Ҧ�-q0ֽf�#�����D� C~.:��j�{$�����2���,/�tF	P�Z���1����׵DI���.�Q�����L���>nՃ@�.L�cͽo"19V({�N��S|G�X�>�h"�������R$���!]���2�K��H8��ûKJ|�&�eѾ�ǬE�s(L  a!^=41�\��ArP�zR��*v螜�ɫ�	e)Q��nV�ˢH�+h�#��2WM�LEKb��֡�t��q�T�p`[�@	�z|�ɐ��J{�AL8(����$
�X �@e<#��@���*[g(T�/�"9�=�7���������>sk�D'���|�6�f����|��4b�1�V�:\̑x�@ڔŦ�9PM�!+z��/��>���8�����fFS�b�|��@Cm(�ΰ\���5 $#��ެk�������E��`�\W�;`��N1CR�!��pV��׀%mq0[K����5\k�^�RܮO�O���Ua$���w�Q+W�	~%�|a=c�8������/n����"��[��@��9�c�]m�Z�����)ߪ����r��_v%<4�0֮�C�`n�7s!��F����O��3�;'b5�>3��V�o��
�Sn>VDf�Mz�J�qK	�CdY��h�}��_
)(��qDS�t��ա�U��OFh�z�/?}�68�T�0A�*K��%xW<Q�W!2�a ��f�^�Z>*�$��2C/3yw-��W��p�2�!t%0��FZ�a�׃��+`R�-?ʙ1�'G~��C;��j_\l���y��7b&J,i�)���Q2G�d�V��:��[�IR�	ѱ��E�����5�Z��ʯ�>B��)k�|��D�g| �w^�CS����0��O��W��a�l�X�3g��-?/�_wp�N�- ����}��y$���Ƃ���ѷJ47t*�חB�
����|��w4y	�.ޱ�D�*����ɲ��c0�tgr�[Z|��C�Q��DK��!����V��D�����
#yQpU9C�g�"�س{H�0']�/\n]/+����4���k���-z�|+�����-�Ƈ��o�^��b�N��&]�^�ᒇx-���@Ѕ}��7F&�rBK
כ�M�R���$p�� ��-�F���ޓe�H/s�_e>��B6%F�����[[������oN-��RLn�� 0V�3�ogF2�쐲.�<�B��E��P �j:�T�1�&��������,HH��>�*���Q,Q�9D5��i�*g�6�^��tW�}�Sb������lD�ϟۂ�y��|iF��ꉀ���A���(�v�>���ժ����r�جc������T�Yj�=�=hk�r����}��5��#|v󄆁�5��-i�ޢ|�'��?�$�#8�w��?K�|�k��o�X��tw���k6Ry�~��w[*�H��L�7,�'v^�L�k8³��e��d�!�*�l��p:EA�����]��{�c�Dc����Ч�"���V�v<��%����8�}vx��#�����x�쌺��oeG3�@T,+����5\���T=�����/�P�&�BP�Y���8��1#t�yp��~�vH��bG$��=t]�~Ö����޽��_Lv��o)9�ب�����G�r��Tx�*Q�=�Tg�D,�'%7xV����𮦇���9��c�L����D�5� �ʒ"�(1c%�	R���|��A˅)9��J[�h��?�� H��2�8�#iG=����"��5�\�Z$���>�TR>��.�����\2a�H�+R-�S��K�7z2�c|h�qy�݈@ͷ���H�5�yp�m�ꮧV�V2ݥ��c ��<�(%&/FT��d����Ӗ��ߴ�6u�_X` /����-˥
ءx�%��~�mGx�M黅ѷ��,^�x��&�a�a�Y=�:e$������+���Pټ��p�\f���R��6J��ώ�<�0�%�M���[쾷�"!v$J'(���+�n�/o�s��?2�M,0�{��?t�A�/��dn�*�v�v7���R&���Sq��aҵV&ۆa�j�M�a���y����<���ƌ'ۡ/R�JTҳƓq�Ţ<G�6�տ��qt��A���W�JF� ��1�d�(zKw�-ϩk��ո=�[�@�3�]�Ah�����O0�wI&���X����_땜��� /r�`��ht��l;���M��/L��wp,e*�O/��X�I*+W�(��@����7��!���8р��̌F��ǖg�V�(�O��r%Ҭ�p���e-*����0�{�[

4"���27I�ҪA� JX>7S���}#��J����6�}*�A�*�Aq�ì�y���N�h+%o�cu]� Q�*��*���w��D�t��.S���l��]�@���@F[eN�A�3�H�>Ǯ4�r��ʙ���UE��2���� Y���k�QW=|���`�*K�&�\KY-�� \�!��L'YA� �����ǌ	��V�`�2'U�"=al�F��_`k����^�*���o����ȴ!��.^]�k�[�+�R�A��yo��N�z�SIM2�������]���1��S:�3)T���%DK#\��=�c3HY���4�oy9R���@�N�c6�:�?�1�t�g8~;kHH�%gG��c�mN�}����`/l��Gul��hET*|�"�5-���}9��3�8+O!�����1�|�37R���{~�?�XS���M��g����$�n���IQ�~��.��H̪�����,a��+Q��� ���I���m��Ď?����mՍ��y-X��P(��8�����(M[X�� �5J�X_?o��CoÆ�^ع_���Z��+xx�д1��������|kǼ���B�:E������2�����N�s�`�.K�A��M� �&�����㣷�6̍x����\�VQ67dl�?�F�&�ŌG�\v���JT�����:���X8�L>�D�6�/�L����������h�>�ΰBT�(��zG�	Ŀ�<��5���",� �{e&���i#�G�G})E�2>r��VG���u ���S�C�O\�56	�xm�'�����w3j��tr�'8!,������U-N��@av�2����P��*�?�PTm�-go2ڡ98���0r�q<�rn���y�mၲc����+��ڛ)�˾���'j��·!��3Ø�s���k�-��F�}�\n�p�4Os�WB��#���y��eQ��n��\��� ���`91}�%y�i̠��6�-�cg9�������G��a�رG�ߪr�?���#���ň�Tݽ�N���ץk��q
SЌ�8J~-���z�#��)4���P��HudF>	�h8w7�v;0���q��v�{}2dA�4���W��<P{��IJ�΄�Gы�Pe���B.���� 㡿�v/�W�f�F
�fM	`I��vi1��u۩�^D0�O��h1V�K��e�+�"������T��˭�*@%6�gW(��M�)N�N{KWî�sΓ᝛�p`ܕ_C�Ӫ)F9B�W�h�E�J��s��$�?�\Xc��Iv#����GS�4V�W��m�)���?�)ǈ�SeIE���Ld�J2�D�v"�h/|�}�_��9��$qy�擌�09���3z/���	G�ݪ�W<��7�s�ɟ ��T�N6�S���Xۺ�$���.7)s�2|��ޘ�L���Wmnr0�t�H,��`�B�͞�o'����"�ӝW�M�<W	+kŚ���?
�QuO�T2Ν���U�/���DM�b>�0!����êٞ2zY:�/�#� ���a������NbOv��2�f�ZD�R��qArW�?�ϑϞ�<���铴1�Ix�#�\˒';���V��KȫȄ<�^�u�#e�|���8��� ��I����;
E��k{#u��^�K���Î�[Fێ���׈�^8Q;������c�w����B}	�\2 tR�ٙ���2%�k*��3^[�B�]��`�",*|��_?����saw�=�R�/(��;�S���{�����olϊ/Qkr�� ������e�L1�����&]z�4�4	b��a�!�÷�K+��Φ�o?�XF-����m�� �x��L��G�qz��U�A��� YQ�/��"�z��a_9�f�,�,�.�Χ�M�e�� ��N�B�˷䝒|N�u��hG�,������8�,�T=���ܖc���Y�G$my��x���16���g�J�a<+�m��������b30em�_��<@��&��,�[��������\��N�"�.�ػ�:�~�r���T�EF��/�-��44|A���?���0���2`�/�|�F��7�����V�7�J�5����K�=��F���(6�6�e]}'�d�N>fng���R7�,\<����E�<ĕ� �M}�X6t�U&��I அ����Z�+�i��HR������8�3�V��\9l_-b���h"�"���f_C?��J�E4����NRW[�� Orj�xJe�����-�M%�e-"�4aƝ�����|\ӵc�*�C��TǶV���89������o?~�58��$�ۑۀ������&�rD;3F�c/�\��9<�mz�Oi��f����~��YW�}P�rZ5�}�Ys����Gƌ	�6�?�`1U�3�Ro������i�,��^�2�~ډ��'d*)<L݈�����I��qLY��X������K���e��	��t��O�Ɨ�?��zeJ�&�21S����Y�m��8�-6=�.�LR�+��LOsG�>�T�z�=�!�,&'��<M�[���ۿ4=/|?=�sZ��oj��_���:8ڄ}RX�d:�;���cK41֌����ޔ)�9w+�r���(�R8U�� ԗ�Ut�tX�Ə��-?LA`�����)DK��9�WS:��%e [H�P.vdc�G�xW�+I�I��Z�;��Z� 1Z�%_���/��8+)�+�y�f� ��xR���f�~�@���'��A�ɱ(K���_����CT�^�Ѿ��ipx��NO�Ү7r�"�&��]�?}�S��YY\��#tPF�Z�}��o��$�Y9طAǂ>�}��у���ђ�^K�¿抜��0�hZK�C7&=N-Vs����z�T��VC�6ބ�.l�v@C��������/���܏g���;�'���ff|;�Y�#f9O�MF�6q�q0��Px4-orE�����}�ejGkd(������a9;qn�RդV4�n����=�V�C|�M2
�9Ԅ��a�G*�r����X�HP�G�9����-�i�jYNr��GV���.���d
����.��3��&� ���Nm��["zY�x㣴i�|��P ��4��tM�ddX�I������P�F���B�Y��Q�*%0���_K�;��U�Sy�N[��9y`˾�l"��ܻ��OB[R�L'j{�g���b��Ɂ�k���
H})��̸W��4�n_�J�;0}��S��qe)n�H�n��w9���S�7������2�|�Q����-X�
�����c:�S��Z��R����t{�6M�_��j���Wx[J]n�Sߨf�B�y'�"�w�<ʿ�^�so��@f�غB�e��k�R(j5^�T��J�-`E��%��7INM�3���vo[-�d��a��V�h����~"=�TF�5��{����Te�!&���+,�n�4lD�0���Lq�lO,_?SY]7l�'�;}R�z���􈱞̑�{e������M?�_�s��8d}���r�e�*U�(2�U�>�'���t�u=�۽i���
49�@�q���������ڌƩ�o�YY����L��Pg�C�+��^��B����׶�Z��׽OpUN���Ibl�7��<�(}�H��/D�Gn
A�����H�Q���j'�+w�I8��fϛE�7�2��&��.		d@絗��Ko���n���&P�9M]���\x0'Ĥ�ĥ@z㝼��=(:2����N	d��v����R�/���c$~��V}L��x����}<]�k@P?���;z�
��P^�ҕG�kH#_e�Mr�!��5�di�aM3�gW���x�z�,�P(L����>�O�@t���
_��30��A�G�S�<E�l�6�Z�l;w�!96H;�@l���=�-�1�.6����d�Jj�3�A��4a��ճ�e�(GZK�6I��#a�u$V�����P��$���i�eܦ�mi��1((��C4�F�h���Ě�:��B�σ��� �f2�~Ba�p����H�Z�o�l���-ίg;��i��&I��3֋��@1��)|!�ίZ���~���Z��W)���,���|�R�xW�\�����iFY�R��L�NFU\e�J|��\��2�*�xp�_�4��X���v`�d�Hki'��ȍ�$����R�R��t���$**���Zm��@�������V�^23������οSu��Q!���`2���1�����o'�"Y��|�W"E2�a����E9��b�!Z���`��D7=�0P$�c2,�����c�"�;����ή��.�Ă�u�ڵ�:j�d�^�F5z���w`�bO'��hǴc�X������4�*l��ʛwd��?s&���:&|�J����" *�/�&HԦGI˚�3{_�yy���]b\ �4�#��x�7l�|j�<�)�T��-q� v��ϸYJS@>Ų'���n��})�Ao$ч����[�i�(0M).%+d�T_>���sM�}�4e@�?xEz�TRȯ�lƖ-&��y gr9/�ݾ�sZ/*�v�~,:��9�q:���}�M߂Yx���ho^Η9�����XMf qL��� Ȗ� �Nu�To� �.�09=](7�,��1ނh��G����g3�	O�Z	b̔��Lb\&��̘���6��:�J���tEyУ��t�F!Q.�d	��z��%yc x~~2���Ω�����J���pI����;�·= ^'��� �է%�}`��vsMd��wP0\]Y/E��Z;+�%P��`h��4`=C��:j{�o�!���&�S���t9�Uw�3nM���|�G4/b@n�)��H���:�peA��AʽX�;���N+V�\t��}MZ��ݣɾ�jRИ���]����! l�YN&����U�rZ:~�v ��%�����⭢���+����h}�^&W��3 :�!ioU:EPA���-�U�A����m��%�2Y��ܦ��A�T:W5��;	]�[E���
O���  ���A?� ����1���g�    YZ