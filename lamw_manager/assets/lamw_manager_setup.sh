#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="482780007"
MD5="ef7e38948a454bfc70baeb214aca1164"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26008"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:51:24 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
�7zXZ  �ִF !   �X���eX] �}��1Dd]����P�t�D�#��M��gd�1V-�'�)��P����K�ެ*��
um$�č��Tĥ�Fi���uX���k*�V�'���Lm5���Y�g�#�e�e`�H��z��N�B*�į�����%(}���1�Q��{���n^xG�J������s[En�0WS�m�Rڠ7G����%"ĭ/�QοH��ӹG�7��"d�G�FI�z�Icb�C,l�L��!��1��g��vMJ���B0>�/���gp��c�}����G��:����<1�&�F�bpD4TЦ }�_>=�����7r=:2���Ѭ}wK,A�8n�`@�". e®����(iBF�@��4wN�g�����f���-+~tc�Uj��N�-�-�C�a6=������8OC��`p�@�74G�G?�*�t\{%��K���<ʭH�z6�a�i�)H���]a���^Jk�T���a�")�3�)͈��^O�3E�fxS7(����Ƥ�z�]�EP��B:!v���l�\P4ɋz�'w�o)󤧽gݡ?�~���9���  I�j�鯓/v_�f䵊�*v!d�Yv�B�ZPXMJ����Uo�/M��. ӗ���0}$O�w���&������;޽B��$�Nm���9G�O`�O;��ɀ�ʘMvvU���[�?䩯�>�`��L:����N#-��V]0�p��cN���qb�A<����u�A��f�9�Jh���w �`�w��H���3X�M���}�!V�I<D
��҆u��S�7y�RW�W��M���\_,���{��"��w����2ѺL�����QR@��"8֋)D�� ��#j��M�c-�&`�fn��;7�8CWSh�{�9#��^ŎxQZ�h�9�Z�*C��ms�覐/L�r��:���6��_�C\��D�ܘj#\9�ݎ٨*�H �Vr��a�aՁzI{��I~�`d2�q�J@�YT��3�u_;qè> �D�q���ɘ��=��d�d��t҈�C9�����Bۈ������Erޯ@�����:\�n��Y�L!ŵ�0���q���^X�w-~�G��2��LH}~ 3���>��k��'��_ύ˝�O6�Zwؓ ������# ��é��g�:gBh���/��1�2�Z�P���j� "+�8��1��d=���vS�[�-&��p����9-�:�������pMw($�N����S�݆[s�R9��kOX ��o�
D?������׳�c�^�04�6kwX�-�?��������\��)'>�WC1t��X��@K,�h/r����=$�����_~��v�� Z����&!�����w=޶�l�-�ڵ�r��b^���ՌWq����"�dw����{?�|�;�x����K�"�_j'��G�ݣm�Jgۼ�����8��;���^$���@����m>͑f�0��l��5Z� ,�Y���tr�y�u>R,EA��.MG�t� S�q����>jM�ਢ�zfa��)0� �9�X%G�*Zԯ�*�4�b_=��^� ���)��:�����+�V���o�G�=��<C9��{�]k'��(4�|�A��
1���Ge*�`��-��U�O�!�-7�������bi�0cR��E���_	Q�k;�M����0u\�����;&ty���5UO3�Ⱦt���o�s�G��K��W�38�.R�A0F�r�e��<��� ��k���m?,�|B�0O��<�+!��~����6��r��A밁9��z�*��X��-S!n���|����6V׫d��?��t�3�4�(|�Y�<$�g�a�B���2�O�#J�z�m<1�D��s-u��VM\iH��*��5���+X=��;�����m��Ĵ��W��_A�'���`6-F�/�y;���۹*�^�`�@�1C5.=@H��3�WG�K�H�Ф�BY��5d ��b��k
(}1U�u�����=@�x����uu�ړR�����&�a��1�_�A���T"�8�=qOӂ�8��h����;��LRE=�!d��5�/�4pOՆ��������9����ۢ�v9cb$:�*�����3��v��<G�R�p{��_$>"���|b�x⵳�F2�r!I�f��8׿�K�L ��+����=�Kbt(�E�g�na0r6K�h���[�꽨�]�I�f�-���.L^��+��?@�������	��m�o�o�E3(�NΤ�:j���������M����覂��nu��a�67�Z��ͭI��;����$Ȅ����l���L^m�CpbӠ��;�Ig���C*s�{�ce?���?:���@��P��DPYcH�d1���?LHε]_�d��9�J�J�u�)����Ƴ�з��Ukl)�S���ї�� �FiZ���(���7�a���)�K���;��K0��/�%��x�0n}i��A�c��vv'�w�Z>m�Nt�"~sl�Uq� ���T���k$b�=? �  ���"}��Y��d���Jeʆ��g����d��M��n�7�~�l$2�?Ԑf8�O+�o��h�(\�AYw^��4�1"D��g�55�(~���t����a��ݫ���G��$	�K�������&{5I�������W���ps�XH�Ph+ќ��m
���<��`��GA�C�w4�p~�V=��4��N��b��oE�O� �R,��=y���FW�^&7k�*� �1��"U8	�MƔ���bS�}�^a�f8u]�Rp���e<갥 �m��zn���zZ���%#!X>+�I2�[�����~�Q�f?*`�F����K��0ǣ�x���T��>W�I����,�*B7m"�Qֹ �$Up<�ރ�,��,P�?�jF���0q�D�E=ܦ���D�*\M#����⌈A���m	��]Mu�ux����<>+�]M���y?"/�C߇�Y�ɐ�{'#���W]�l��p�b�<���m���_?�8C�P,0�
���5����c�AԀ�l2�>�+����$�"[0$�࠭���z�����$`i@���S:|9���~��,օ}�3���8���b�T�������Ď���ݖ�N~ �7j� �66�
���sm�����+�]�9%W�uw�� ��Lrɒ��'N��V �g������<�0 X��\��'�M��R���T�'��'7������㴣���@{�?T�^=�A;��� ���c���u*T�O�A6���忾A�Fb���OaY���giMCa��l��ޱ��[�FD�gm��+��楽���mR�%d�G�!b����������?0���:�����z���k_������� ����1�ty�����#�TE'}�6�jyw��dtD���8�7�<���	iq%��PgD����63���*H��Qd��BUy�-4c�����`�>�}��A�k��P�>FQ\���IK��U�xo���7u�n���N�ɏ�YC�?���+4�����>/2R�t7L4�� u��@���ɇ�ykx�/G�]Q�)"�%���J��/J��\x�5�X2�+v�ڴ�T����Z����ɟ����߉X(��Yڣр���Ɲt��K"�q��-�;�/ԵM�R�nI<gg�z
��R���L�ߣ��r�zW 0>�%u؅繟!e���D�&��?%`[���Iu�4�M=�'�s�Cf��]�.�Qm���o^v��1Nk�#�h�V���З�%!��X=F����㭠�F$�)�f��%��B����*��l.�0S��5�zKhO�`���� yBuWF67�}��^���)`$m���W��M���@��Am@Œ��{�c�����YZK$�]ǐ�\7vQ��L��.�ms�b���|�Se����p�g��LSU�>���~|�B B��\aTC���p}pn�+K{�ČC����v^� *h3{�-��eLbp�`sՈU+k%c)�!<	�)����ټ��{���
>+��C_n����v%M&N���l��7gN?���(	=:��5��[QXQ�6�c�
�8�<V
�/h2q-,J�~���K }�������}R��|*�qt�왱fJ�}�ʔ�p���e"�u@�%M�����$�)����`�=�}H�W/WuOs���SEg���"������G3�`�<ٔ����/�(*����A�����AA���mF�,��XGL9���Z ?���9���Q\��Y_H��e�P!�,aO[@nGlT!��tE���g̮����k��fz���U�FT�V'��K4c��缂���W���#[7��g���^E$���덼Ì�xޣ
�|��Iݿ����J�ٳ��ل(���5����(;G������n�����#k��d��r���S�rً�I���`2Zt��`Te�1���/�2{.�,���	oj5ЬPG�T?����>���Ƥ���M�EVH������}�h�*�ͅe]h���4@� z}���Gyg�-��D#�?7w�61��e���c3�glk�ڄ���o�{�KA��ӱ�E�3ù��ὃ���8�U
�3�� ��c�p�/��=U�0�*�1>p_`l��-%�J74yu�f�����o��ds׎��{�b?#4gS\�.Í��M�UU�E�:���V��	�h�v#VCsJ��#�!a�?��Ő�Y�3
�UY.ש�1݈��C�쮗�^4��ރ�S�ʰߴb���x��s����3�l*�8f(˨�}.�����Gw�\Mh�@�~,��Ӟ�_<��>���h�@ ��l��{[�V���r���hD�W�;^��5�wd^Z3u?h�*f~�<�b�&4K>�F�7*,1�Y+�#{����l��@}�-u4l��ƾ+9$�UzUK�	���?�'�1�_y�9�R����O�5`YĴ׆�Nr��۩/[�zC�6�WLk']�2�eJ������q�e(k_�A��Yz�_��%~�g#�0Mj+&�:�86�ly�Xz�,ʾe!�y��������ȱf	�t�0!9nƞ�-JXٷ7�bYk�퉆\Y�� ��um퐤x�=Pm�� �No�[�(�d�$�=�6#�ho<���b8Y��I}��|���%���'?���I7@�M���%��Eʙ2`lwڤK��RV9�����I�!4�>E�M]ߟ<���W*Ě��Ha�sN����Ɠ���d��Yݞ_hnut�Gt�T��T��O�x�7h!�Em�{����cJ{�Z�,T�d������)�4��)�u�ܓ���0�3'�BI�z����1P�%��K�q좏�~� <e'՛�蔔������)e��Zu�|�[�'rifj�f���ogݹp�Nt�Y~U֐���azS{x��5�W�����K;�PfƬ�u��=C��D��)�?)Ł3P#���f� �<j�ju���N��/�MjR2ǃ[Į���1�y!�5�9�4�!z��=<U��
��ω��,7we����LwX��!ޖ]�UA�Z(�k&\u�17���[H[�I�2��|V�lP�]��r&5���F
�� X����ھf��H��!�*a���K�7R�����l+�X���kۍ�B���C�=�a9���]�x#��=�s�mBc�-o!Q8�i����QC����r�.Գ�`J��#Wl�O�m��H(W�-	L�gX��쫐���Ӛ4�>�k���W|��/*3M�L;h������W�����j��]N��j=D�7��؂ȇ޶/p-���7sk�:t��o �RX*�.^��o"T+ad�.��\
%�]�@�R�4m�T����g��r�C4��g b���M&��i.��`k��f7e��lP��tx1���e�7�"w���(�tk�U�}O83����U��,�^���ʊ+i.
)v�]w�ۙ����� F���(£�!�U6���R�'�OK�_ӡ\��L5ے��̸FYҗ6�	p������}���qq�L�ȩ{�\��aZ B�)I���FYf�|��*���ӳl���S�[�+j�jd?�ě[SL��I������e� 
�F����r�n��w�R��y��P�W�:�|*.i�`����F�Z_j.H	Iz���F�	�b5��s�_YW`��z6(.}�����CL�\G�jw����˾���{�?�G���٬a���\F�E7�E+��vtX�9HY"��wy�=нُ�-3�_�`l,<_,Tm�a-@�|&U.(�0C3��n"Â�#�tC2�����'BT+�& �kXQY�C<n#��պ���R��h�7��5i(�\Q
,l�r�9ZȊ!���3�!'&(�r�E��kn�ؼ�1rh�`)J��<,ioGzo\?Za�H��OXMd����1-|����P���b�78����N���ݵ7�s@|��77&�"��0���gRI=�s��ƫ�*ߙ�H�?zQ���U�Ӱ������f�X�(�h�6^��܈�!on��p������A�7sͶл��B�[� ��"��Gҫ|��4��
�� os�Z�����xH,-,
��}-)�^�d3�P[j�a[<���UA�Y����'���_S�=�g��:H	�1��8�)���q{�v��_�J�$���0_�G�M��\t�~�Mp����&Dܘ��M����J�Z�:��KeH:Bx��1�$���B	�ԣԄ�t(�ɶ��������5
Uؙ솓���r����$v+�ugX�r0[&!4+C%�T��������$�{`C�Wl��#���-��P��p%oa�=W�t
x��S�]t���e"��g�=Q��I_$_�������������\���L�����o�P?Zy4O1�H��-KK�Gg��(��*�@��!��O�L���U�"4�Ton�܆� {����b&Jz��1���~'ؑ�7�E-��:�=%��g�4`��y������`.��H���;v;P�n]@6��:�*cj>��#�"}Yh�k̸E��%��W��W�q%��J���U����VwP��k��jCf�հ(k�8���Px�X��*��_x�7$`�E�}}X�g�6p�&pO7�IZ�	[�⸸qd좖��C(��Ĭ���a��c���#�y������M|�^Bݻo��zM*WW�33��-���`�7�M����J�.�z���qU?�=��:G�Ƚv�����*�B1�ۢ'q����̱&��=�B��o��v�&��u{c��-@��N ��ٮ�|F�,�?��0�� �(�"��5�S��"������\��o�����0Z�ǢdpD5��Жz�;�$�9B�P���J��7#����3#�r��K4h2�9xpcn�^��[� ��\��`T�b�l�Q�W���1���w�K�w�+wH�KVN&��ud˶�)��P+�Q����r�騰��Pl{�o *�=,=���S�ؚ(�zJS+�p-Z�+����$v�pC�l����L��^C,7��֛�������C˫ C�Gg�+��T �7-%m��`ŠN��>(�{���R��w?S�����J<L%]GQ0�&B|�Q�*��otHfcG�r�$��m��]��&>K��H84u�y��D3�PrSf�a�(�� 230$]��<����wGm�0G�NF���\�:�D'�r�G����M��D�� 8u �~�8fZo[���˲�ÃM����r��{洐�*Ep^�2����� u.��'F�_�\��N+�	��խL�'����V�<%3��-V����7�ɹ���M���D������K�SZ�i�������"�b%X�����J�]�å���-��@��v-V�Pn"-;R4ݔ\��pN�ŕ��э�%:�	�CJ*c�K�DZ�W�FejQǏ˥�;Kx#"�_+]�jf��
�j�NP4���E{-F5]xPc��:f
���y��Oش�c �:!���ϝi��I#�����>%�s��x3�f�eI�~V֏<Y��,�m�ӻQkS����"l��+c��������\H;9���w7G���zd�?��{�;�Sqg��F�Ցh�B��3`�� V�=���z -?��ݦle�m��?����-����p{l�:�|~��>�>�Ih�0������V�P�j�A�aH��d�� �}��G 82���G��!���҅ާ+6�⣋�G�b�x��� ����ܤ�q7P�̰\n��Eڄ0�J��SV0SMw�u/C��q�h+d����>�0
���^`SӢ�b�9�g���+�3�	gGʔ����հ�����s&�,8N��)>4��Yl>1��-�� ������%D|��c����ɡw���}
��o�d���W�h*����٩s�a���ƶՓAr��s���_�.K�>F���9 )!�M���;C������B���ɺ�ȧ�o��=�li+�N��s�j��v�kV�\^�����;#]�!۴{֕��[J�#*	�R-NyN�S�2,wET�C��<I �U2HH�Q2��u���	l}�Okp�����:>#��Ϝ���=

�&VE*��P����G����$�TtU	s�}Kr�RW��M-W�s�з�1�,����s�-�^v������"���}�U�m��LP�ys�]fA��� �ք��81�+�&��.uB�&��g���4����1�n���n@tQ�����B�D/�
�^4�lw��"�/�x�d�1�5����<��I`�H��ٝ����V���Ep^��Y÷m�8����^��k o �tc�w��������7Ĉ1��DYH�&O$pB	]p����&��U���4�s��*P�&<�]KW�9��
=���bs�S4W%K:�c��T��E6�m����Q�4{o�� �@��[K�"5׏ӹ�n�U��d�G����`��ܱ��-LRc��{@hA7=N����?Q���m���u���֌��/��e ?A\J�7�bnh� �����t[��6���3���f`�F�pb����3��Y�[����f��;��������ex�A><���x���H&�7�ԛJn�.��r�A���z��Q��T�x�y�Abw�90���>��-�}y���ё�fxuS!	^-��Kݛ�Tΰ����%1��T3:-���ܐVJML^	��W��r�;_j��Bݝ���QN=|֜D��D�9�N���^)nl�W����.�ְ��%�HkVߐ�,oNٰ
�w�^؝��RE���Zu����[�쎍X��gv#��oG:3�9f1:jC�"��O��Hf5ŋQ�-��j&*Rh;DEt��
���I2ڡ�"�V>�����[C�=Vņ���;��3}�>W�����}e��5�w��W�����
M7�M���s�B,q�Y�7���a�t�$��e���.�G�7ؚ��}+~%�pλ2W��n���54���H�xi�e�����K:*��:�(&�I�ēW�d��9��������2����瞙���l=Y�<�nc�72��a΄"h�	��r��B�6�ς�7��zf��'c��V�9�jq.|D��\1���B�w����CQ��X<��n�������4a��/7��GGWQ�\�bŪ��e��@�y�S�ldJ�K�W�N���:�f�hG�w̻I�e�9M����{:N�#-�z��f��*����b�Ƀ�F��Vӓ���_t/�:H4���8�ƹ*`I�
�V+��N�8�z{U?m"����8���{' ��q������!�Kv�f�)#U�g�؟6+�^�7��)��-�Y	���b��y0!���M ��g������!>_t��$3���Y)��XK���T�`�D3bĠ�^n�9A�T[H�[
�
;�a�:q`b�L`��/70�$X�d�:���Si4�t%��0��H��:�a�[V�������qaa���o�r㺅m5@����K����[3k���z�3�}k��� �LP��84讒� �=��2"\�G�N�M�t��z%{߮p<���a�ֵa��}t��v�b��:L���A���������H���,��:�ז}Hl��8��$��~4H��1�m��M���(-�uxF��Ŋ���S������VM�x�PVD �n�UNU��N¶���\5^�]h�8�H��{��N$���j�{�+�T���@]����<�#���ԯN6I�yM53^��E^�jPwX���IE!=1�g7X��Z 3&�@��6dk���i7%8�\��[I����� ��1[H��w�Y��[o62�=��RV��k�´!�������?�8�li�{�ۓ�ڵ3X_�射X�}���թ�R(�N�T��#���A�w��+R���վ�������<�V#JK���V���y�В��d*�G�P�Q�	D�P�Ѯ��X1�n&{RO�5Ӳ�L�:F�69-��C�!��/)1"�y|���(�Jٺ����N(�z��Э1�8X��[e.��m��7�<�ݜ3���̲Q�Ie�\A���l]�	��d�i;A�dӅ�c��+s<��t�s�����dȹY������c�����,�o��r�(��`��T���{�B����-E��sSC�{�޺�y���;����+�*V�A�c8����B�1eqtt����	�������e\ �\�A�T�\������e�%,�.����n&�֧_!c�|���`x$l�T6J)5�+Ц���3բ�!��@7/.9���D�����W��7��Yߞ��Ïf�Lk��ww�&�ng�V��[:���;v6x�2���k�{%Z�%L]��-�ö�7Kfur�m�9��'�pm�y���ϳ�S�vUN����G)`C��{ˋ��uq��2�G��3�V��,���fǇ��>�T����o8�c�YI}\���'{1^���g�?8�6��LЗ���X{a���:������{0ɯ��б�M�R��)�Q;B
u�\,�
����s��fM�U0��u�q�9��Szɇ�籥�	�@�#.�k>�$�!�E�%��D���?j�]S)g=�=<V+bU͉e]��g�}A�f�t�Y�D�aF��pL71�4T�)�M�z���ga����pI�D!j���<K��
�H��땪�o����%{�wU��f�B|X���>�C�g��W�	��QH�;ٗ��+d���l�M�j����%:�@s9�U���Z�Zg���G{y����p���+�³E��-X�����c��iw�R��ob��B�U�X�
�r�'W`���S��)�G��Z������ѕ�=�j"�I�{#?x]��%lc~���]\�׫%�(=3��s��f��D>+� B�a�Co\�8]y�X�A��C<�[獫�n��$=Uh�����89��BBd58�WHݩ�N�!V�VN�xҸ�����o����顇�����U���~:�����>,ЎG���ew��;�K�,Wyg�~�2O��\�����%�k\)a�j�^��ȳ��c{��}ފk8B���S*H(����[)33� 2G]:�ϑ�/ROݿ���t�/D5��1C|��X�'O�p�Ϲ:�f�kI�a�"g#c3�djv���4�b0TU�\8h�lc��y�++9#*��.�$�NU�!�P=��Ht����Sʿ*�K�Չ�a�>�A��Z��&$2��tۣ��䨗9�},FP�0'#�$`�V��"?>b�Wb���mw�vw.���I�P!j�����X� z�%�_��6B�(�F�tUs���l�B�pD����)W�`d��^��"�#��z��vS� �'`�`��Ճ�m�)��F��1<�/ըEy?��Fɉ'e �}��,����\f�),Ϛ���;2uV廐����Q�bfG��M�UbC�kw�@�=+�����*��O%�ۺA���T��f&�5{g�/R�R�
���.R���z�#��!�a���u�v���/\�E�$���h0�F4����QFUЛ��oQ%��e�I�$:U�uu��E�{����SoІD�{��{�t�L��K�O:S�{W�����=����ƽ��-�Q��pIXj��G]���SV��f@����UO2Zy�4Х��L��}d�[bҍ���/B��D�/���Hs+>�=:�t��������������Ny/������/�1R�vyK�]��$h#�EUp���uMҙz��A/�K��_�q��+��]N�_�v��f�a�I��~� �+�6y�O���
���!�2���0I(|o�W=����/�ܹM*�-N��&ǨF����*�)I9w��4�zy��n����Q	�#H�%��;��,>d*�;�h�(�X����͝.��p�y���f�ߒ�O��y�'�x�`��>~�v\�`TdM������	��i+�>�8�F�=;�'lXQ?��L�bL�-�6t*��n���"��T��cjC�7�dJV��"Ta[}FF��:���|ȯ�����$;���Y*��	�O�=x2`�1(�]\�5h���
9x��B��s��C*v*�Ҕ�������=�$������׎��)[��e�#ٓJ�?~���aYb�L����=A{kqΤSc��J_����\n��g�Mj���Q���{�L�_oP�A>�m�#�+��Hv��k�݆*;�c�A��(��o���L�h��RLT:�|�kh"� 6�}+��̀��3�����n�
q�h��S�R2r���c7Y6�7��+a%��X�xs8,�тh�Q��Iyׄ�+%���P�ᵶr��G\�u�\� ��QE�P��������k�,�(�5?t����RY�`D�s<��R\r�+���ߚ2E?�5n�s�dK]��Rj�8Bo���i�j(�v�2����ӈP�$��g������wGW!���T�6�R~����M��:Gƌ�<��@����7����q߭d�5d8fy��T�������Z�i���`b�g���c� rB�s�_����6<p�:����e'�wp�!sj�&�ғ}�f���ĺ�\\�$� ����,,~Y�x�G!�o:O�d~ȜX�*e�ߗ��A�b�- ���;�r�b)�"�"��F:h� r��H��J	{\���e7L� 8˗�M����_���9V���"��5���vC�u�^�x��}Z�et�b���r7�{-���;��9���ܲ¿�+����ޱ#r��B��h�/�A Ը4��������I��D�L`�{���^��z�1�9��G����v�����b���%�64ꢡ��ͳ.殏*&�;�4� O���T�����*3yJu�͢_>�R�]�F���88��e.�M�I*���0]dʊF^BH��9�L��q-�b+�=S��E~����%k�^��s]�D�#�ɮ��pھ�a��M�ol�l`���R �בҿzKu� #�}�w+:mt��nN�qn6��0��P��oI���@�J����&^��L��y��KJ�;�����-7�326ZT�P-'L雁5U�㿂M8��@��2�ϕ���WÒ+�,%���d�{�dY,�=R�@��iHh����~d���m��t�u+�ZH���XǖJ�c�~��(K`�#��o�M)憻����06l����N�C;����aQ�TT�>M뉂�M� ��
����٘u�[��u
�E�<�Y1E �S7�@ָ�X5�8��q鏾GK�1�*o�fΤ\��@p��}nzӽz"B��f��#2$�� 5�1�F�X����	���cDbjDv
�RH���f{�ٺ�O�pw��{[�7�X�0(��w��v"j��;��D�V����������Z���1ׄ& �C:��ˢ���BĠ��Slב��0(���[zH.~?[Q�+�m��N�X�:7 �֢P�Ǒ�m���i�������m�� �XY�(�ۏ��,�+��X.<��`)�k�OZZ�j��,z��� |UP�.�Qe9XS0y͍�>*�y�
4������L@@�0[��LwULF:�+�w�#L��,jK����'G�&,�=�ha٣��|V|@���h��im?~V}[p���:;U"�������6W�2}�� jR\f?zTi��٣��4��`�^���W�����c���B������X֌\���޸�q���I̾��3~3C� =耏�H�,�Bf��[���Z��Y�nt����s��i<L)uB$�I�7Q���T�eB�4�fS}֥h�q�+psi�~Y���~2wѲm���I����u[2
��s,.�8�hxR�d���j���8fa��NN&\
�'��ձ <x�d��+WNX���	<	Ԫ�W�i�|9�$5
Й�1���H椗��j�Z�{�?�RT��,!�R�޸0�����+x]2t$N�i �o0���C-.˟���?�KY$�J�k�l��7c��ɦ� [te���bM+��MOz�3x"�&�|�m{qr�״x����~Du�{`��0B��x�fӼ���w 
�ջ���<��0�<c[T��Ғ]Ǝ� 08�҆�;�E��qX&���:-�ju
���;b�c��Ѣ�j�A���a�9�V�A��v.v�H�i# wD���=��*��wo\�K�Qф�+[��e��
?�{���O�IDe�W�`��0���=F��rBl���tri�W�tb�u�-��rZ�߇�xb;
�?>kH�'6M]q7O��GT�}] �#L�z J�'ē=S�	Լۨ���f" �$��6h��� GQ��d� ��l
bfp�+�A*�!��(��\�R��y��N/nm�{�_���%K��9�Vjps���̼�m�t��ts��ON�`�Q(6���\�f��sU��w�{u�1����`�K�ƪ���.9�hfa}��I3|s�Q��e!�z�E�.Uj�ԧ���s4������O�IxqҳR;KW�Ӷ^T����W7]̞�����k�J��k�[���E:���]Y� 9*�������9]���4�WQ-� �y^�j��My$n�JL=����q8w�p��o+��Y^Nj�Ww�)���&e�_�\m�W�,��E�~��Rv���q�����F����l�$$�G+Z�=V��ԕ�� m]��v݅�f��4@G�M��rav�U��@<��ՅG��G�#��@Ǔ$��q���o"X6}�8
���S��@\�BGW�g�YDD��/���,q�fƂN��S��7�6�N�/�BzLl`�b�P%��Y��7����K�U�Jt�tp3g�t\f:�@a����2�us��I�`��K���Ng����-��fvO����9�_.����i%�64f_n��h�{5J�	J�:�yd�����@vg�!�V�Ǔ��t�f Q֕R��0��ٔ�,soh,�D=	��~3(c�e�������>�8"��X���+��,�?�|�)��t��ad"�^&���$����j�)9���%��q:�#{�1/�� �ז�#��q�Q��S/��1����p�l�5'�'��Z6"kݖ# �I�,���և�l֛�v�r�����4���ᩇ�}%�������,4qNK�
ge$θT�4[ue�Ζ�����躕���R��qm�ΫL�q�����iX�2�j�\E�����f�M[;"���G�]Z0@�(?1���~��.�c��d��g��+��^�����V�����[��IV��7��Q�3�z�E��0��bp��v}�,�矢����_q�JA�������m�i1�B�72�i��L���z�B�s49u���s�A>��OA'�kn=���y��F���SZh�V|']|g�̟�g2��c�ۄb��F�bw��x�^��ǨGO���������g�s睶F�<IL(�J��������H�M�6Cm�g��x�ҭ�N��pS�����.rVM��#���W/ҙ����2�L�ş�eh��S6�h��7q,VF�:[;O�d���S�6�X�]�.eH���c���.r��U ��欱�G��#�z�� �nP���L���|�^�^V��w$S�4GY�a�d��PDȋ����e�5G;�3}�+o~UL�R��%�`U�� �ep�s��Y���1�K�pO�7�He�:\��$�X���=$��o�X^5��R� �g��W��[�y��Ũ�Wa��j�� �vQ��a��*�:��/]�fB��C����z��C�y+�����aeX~,ۉÜ9�̼(�s�ߕ�]�P�6�����l	�$��~.'�W��2�����=���f��\n�P��Cv�J��qĿ� ��+�F���PI����cTM�� ��7����G�	3P�ʒ�{��a�d<r���P}���:ɇ�rz�֗�Ζ�Z�ŠAhr?Z۳�p� �,��S��#km桼����j��Ϗ1*����`���`@����j>/nL��v�d�4^�ƃS�ri�jx��{eNZ��W�c���(�n7EG��
8�"k9�a�2WI�3f���\�F�W5�`�:�0H�;w+6Sz�a�@,��c*�?P�B�� 5>�\�~�#��J�Oo4~��iN �3dEz��d��U?�TDoV��ܙ�b�]ɀ�$Hŋ���	�!�{�Z��n��kIn{���0����^�Il�}n��$v,�;�2�v^���\^�_*��p�+a�7�<.�?a`�5�9�b���t�X�Y	�z��PG�a�1q��0�i\/��(��A��L^4;V�sF�M���d��V`X�l��4�H�p����N��Cr'���qO<�!�}�&�.&%�n����a&i� �79���警Ǵ�H(�*���E�#g�N{��%�R�����E���˳B�M֛��9B�w�OF�^tq��_��2����/���G����LTo�;�-ת�D�ndE�#�?s\A��޾���~�$ؑ>Z�6!_\��/S(��u�4.��T �������么��8!$RW}��s;����0w:���}OuX'(��n�oP�u^���ǲЕ���B�t��������ƭԬ@VJ�{�Nڪ 0$p}�Ru��G���55N�s�?���Q�?c��[�ޢ&�Z��d@
�Hֹp6MV+�Ee���yq�饽p�riVҡj/�
�YS�G��bp�6���L.���LX��Q�6a :�����ԉP�p^����Ul�\0pc���(kT�h��qE�]z`z�T<����6���q"�?��ĕ���r���G$姡b�U����o\�G��%o|�;���'�Fe��$���}x�[Џu}�Zq��I���}b�uh���̭�lpu���M���L���,5��s�h3�.&^l�P�>��k�ф?_0�؈oЮ-S���l���aި��{֢�*�l�l+�o+���x��~�u^5���P,UАɯX�?WONT$/AX�bc2��\�pFe� 7�7�����+N�P;>P��x����4�R���_'�+��<Ϣ,�������=�y�LeRB}�Ux��asv��b�K�,�=��>^��j��w��w�KS��/ĺax����ai=�����W��DjI��e:���i9^�3���Ғ�����
/��) vfu��RDb]����ޓuq���x�lų����
���p�w>��-]w�,�L�{)%��>���Z����㞔���īP��?�(Flxpv��y��f"�S�x�JK3�WO)�ZM�
r=��zс-
VAC��xK?þ[��Y��1�%�u̓��0d�15O%L
��0f��z�k`6�Y�Hg�.��C���F;w����ÚI�S��c�q1d��Ƴ�6\�4����n��{�.���:U-�{q�vR����Lb��iļ��%e�&  3Ѫ�6��:<pq�재��f�m���i:�o��1�K�3�]�(��=U���m�x I�O�'u���'ɶD�Q���§�\�g�����w�E�#T�f}�h��4]�!o���} �T���8��e�a�&�C�} nZ,M�`�Cv`��o|�޳X<ܐ鷁�{�^�=� V?��ye��̋����	��O�+�
��QqԢ>)�~�� }W/@E�������ʒ#c;Ǯ�C�2����V�=�	�f�΂B]b��ːD$�Z�ΰ����cT�)x24�A�ה;yLn��ޟSw�?���Wݛ�o����8p��\��7������FZz�,�͵�(��FM���Db�L�k#B������LԻ�,���ɺc��?	��Cȅ9�����|y	�S�#�|6�;�˙��A�;f{��;���l��h�zs��@U#,��mB ���.������>Sv�%�TD��(wQ��0�O�mm&@��I�I�8^���(�$#�˓���z�X9V~�,���۩��i�wzݫ�����}��_�ذ�E�������� ��8��^/2!��t��͟ZA�Ԧ���x7>�0���jm6c�5�n�/�ž�g�Ŀ��J�O&tF�ϻ�6�o��͟?/���D���}.�����Dn��V�,bo�1����� �h\lvι5��$�����
)� �=o�Z�>ۡB�M~��[1����j�`��%�� j�'�p�Ձ~���ˎg���ߒ���(&+���T�*sw�X���E�;8��w�����U)֑�hc�94g�����y�SJJ�o*m�ʶ�{��L˽T�#*�m4���d����N�t-����ߊ��Y���~s�LU}y<؄���.�<�enxϧ���m�������	�.�5ϵ�6j;;���,{;�D�0��F���c�=/"��y���ԓ>m� I"7M�J^����&5��}8Dw֝P�V��ڀ.?�V�]�WQ:Ş �� �pȡ.�A�1GY"���1��'��J9���W�hCf��2m>���ԜI�^U;X���8���E6�fG�x�-�j�n"�ih��Av*mW+�#N�9�v�$&t�W���:�d������*9�㥴��뼉�n���}��P(�z&��,y��y�u�\�P�#N�6�NvV4��ӓ�̨����P,fj�����L�_9�O �7}A-���vg�KBwF)�X,J%p*�A�`R�8��������m1��#a��i����v��I��w]�G�Ŝ��]�i�g,�T����<8�h�z�~%�"?����4׎�̃����3�nk��؎����FՊ����\e�� 6)c�|������W\y��k�8F�(�1�(a;��_̰Dñ�1;�(�)����z�.��i$��撑��du�f�����1�G@K6ߍ�g4PN���unف�پ@;�K�H��zy(��2�owP�ٿ�{+ �T�k�)/r��;��R̫b�M�H���8D<�o�@s�5�#"��X{�����H���O����	V��`c��)����]�ŵ�s&,�d]��H&8��DwFDDz�����'b,Ҧ#iR��r996����Ѩ#1��]<Z��򤥀Y�=��NQ��gԬ�bky� ����++Ed��"Z��>oޙ���p����6���j�a�|懹!|��	nL�=��J��!.��P�j��ez���z��w{ԞC&�;S�#P2Oڐ0�`�Z-��kW<�3�t#���
}�-$���`�E�_�\����0��t��n[�|F��y�ao�0�{� �|7�h(��G�t>An���� ��7�6&�2 ����.@�Sj2;Y�%�hӭ��4���Ř���n~�|���P��8lw������H>s}B�٨����M�oG�^�+g��D�5��n�>���T�R>a�u�Y\��~��\n��|�h��>2�EOq�����yt<�͋#�_C�S�v}����׽�m'#�m6J)�Wa����sq��ƅ�����)��{w7�@b���ʌ�G���0�\si_+�]��$P�䱾���Bf��uB�Va�!:��xMA��-�%^��>�����~e�z��� ���%�0��H莯K�\J#����LC��_�r��q D�`q�d�\̹�]$|e�a�;���-˻R|�eP=B��`�_��Wo4+��e�ܾZ������9�J��,�!\#���IϚ��5Afܾi��Z�q�[3�q-ת|ȇ��0��uU�;��i>"6$Nn�ڬ���4���=��j�d���}7vԌ�`�`Ӄ4��n��Ea�A�[���,f@1JB;;Ŧ�0#��f)�i{`%��n�pɟ��`_��
��qY/�ya`o��^-����B3���À�_�B��({��<w-�O�]���p'ԕ��x��A��>$�]�t�x�L�/�ؔ|��j��.q�+
?��*�8?O�uB���b�C,�L�%�D���W�/�5N����$�����24*L�dUMgb^�|���Yctc\�����*��>����9�?0��]4BIk�JU�� �[�f=�,�7ZZ(�Ƚ���%}�{F������gVI��jgȀx�C��]��4/$���X�z̗�9AD!XH4�~"��.|)���L���X�{�d$�N�q5�0�n�Kl$��s����+a���Bρ�X�$d�<�i"�
HH!��@I=��l�K� f���Z����ki��^:���~���h��z�Ż'i�4��m��©>3���Ҿ��܀"��:2�!/�=�d�Z�f��� /u89�##��wGJ^��fP)�`�L@��M?8E�H�=���RQ&Y��۶Zg>��-������ȼ�J�6 ���b.Pg�*�u����'�:��p�y2i�������+rD�VR|_3�B��_	���@P4���!��Ӏ�����Z�83�sF�z`5��]	�i?�b�~_k�$	'���0�;�RvD����:c��=LY����k["�{�b����'���EA�ּȪkO;=�L���l�B��-.<���>Rwg�w��
?��Ks��2D��a�.���6�}��J�z�t��#�:�R4Q\,"�u�W�b�=�����Q�_b]�����k�"�)�q�&d��˲)��}ҹ�ݽ�su�s�����1��bT�M1�ƢB�L���*�-^�,�K���a�a���.�$T���,�C6��=�jL�rZ/��:���S�2e��N6���DJQ��������c���s�CLlG�AY��+=ݏ�a6K�"�����)H'��c<�^#��[��b�B��%��@@Qy;/ŗS���ǹ�v���[�hre��"��+j}���Sw�ѓ1����
J4�k��-l�8��s=�Ơ�I�:*"��<���l�Tn��ML�b�{W��by a5i���՘����uy�\��E/}����X�@�)�a�[G*�k�T��V�z�}n&�ca�{+��w��%� �e�UX��)/ꊏ���-�c�̳"��s��e������V�t��'/G?���~}&ޘG<�-kD���}��'䢹�Ȁel=�L�P��6�/ai�(8�/���?���>�b;��`�Y= ���S�mt�j�=�}��`��d�0�^o�|@���� .tT ���<��4LLM�;�9U[��x�u=�w�E|�ʻ�[�'`U�}�w���i�0TG*KB.bR�u���9k�Ħ"ʍ�ilA���)��>4�Dio��n��ӴGB^�tIâ���S�}J��$o�$����d�������a���W�ʱ*�Ίk�0	xN Y#N���F���Z��Ѫ�j������.��D17���nR��jޗ8BDdW�Gy2ȸS���N�*;05�k��>���>�DD`Y�I6�S��i��B5�H�9�����ޒ�v�N�\J̾�u�ptU,$ΐ@���p����ʎ�O@�K�5<;b��G#���Q�'�Y�xI$����3o�됲@�q�w�j�E�j3�HΎ5�w	�;ܠ�C��K����Q�/^7��b����7��]S�f@�IR;	��gE�*��MS��X���奆�r5m>����N0D�����б���t�y#Mֽ!��G�[�����4�G��ȯ0ɰ�����.���m�e��jJ"v��1	=��f�IϺx��lG�&B������v(b��s��A�.�p��:3ک�$�c[Y��eo:t�{f� �x1�c��O���7���SռTh�jQ��r�s���2���KS�y/E����9�\p���s#]Gȍ�ធ��af苆����RU��)���N��4
VK���Z�X-Y#
ڼ~һ=�%-c9u�pҘ���C� ���!�����UvAy��v;wn��2������g �c���w_BŇ5ު�h���I[@y��uB�u>3̩&�C O�q��9����$�l�O���$�f���Ji��d�gp��+<}�8�4���Jx<_F]����N?zE"����~�t<x����;�/��9q�U��o��~�_�E�gی_��X�	�xߏ8���M�C @$�6WY�^d��a���F���Q��}ɘ9o�U�ICZ	����3�{F�a�U��4žoF_�����{<y*�
>�,|���N޺̥�����u(���|�[Z�$�?b3�_��0���5vzw�ٙ��U�4l��~��Y�~�)�ꋑ�(����KΫ��@�1���N���#\Q7�M��j���\מ����C7���M-�,;���F��us�9v���<����~������Q�9p�nf{��qwG���a�?�h ��Q�[�^A�Z/��YU�>��Y@f�����H?bQ+��y�o�6N$)4��2���-�L`���p��xM�ʺB���DJU�m
:��߁r�JW�9�}���`̳ɧ����w�G./е���<�7�f%�
hќ|+`�A��E�ћ�FU�ҵ��6���@=����u ��� 8UE<C�IG2���f8�n�w� ���V�@�O�1�@@��~u�$U;�Vej��<��u�Je��o�7��,����\�]��h�@�Y �oz�R�;!��J��
�Q�q1 �h�i��C0�-���$�0��($��"��޺���'��z0��8�Im��2R���q���0/SA���4뾳Q)Ú?�*��Nj���[[��Ub.��	�n\JZF��!um����V{�}��ӕ����T>�?��˥� 5���^�A�=�No��9� ��}$�EYK�:�ĵ�S�#�2u[���n�U�[]��@ڑ�c��.�C.� �U�BZx���ߵ�@t����H�D:Zsّ�Ui��b��Tm�;�_�=p���boG]��m�usX��k@+�n�P&V���$7IUe+F�C)8䘕��aj��ωI���FT#1p��9�P����fv�Փcp�o�O�	A,
t�������T���ʩ���ע�P�&H�喋� {�Y��e���,\�`o�ș�j!��=U�O�s�w�9ˣ�J1_���L�O��)&�B�����n��Zn#P�����Pm�YU��Q��S��}
�r1�](`)Q�)O�e�ï�/V�Zxh�\�vĕ�l`c��7R��q�V���D�e�z�0�o��M��׏/݉ڃ��jP ���oPX�����j`��Vѿ�	%�͓�v��!�qO�{�}ͤ��N�ٰ���؏I��w�Rh?�Y���G���@�����PI_����c�|]|@̃QI�����`)���
n��H��r��v�_�V1���tcJ�꾤ߝM#A�P����ڭ@F�CԆ�����$>p��g@h��)4K4�3�nvIi~�-��Z �<i�x��N�h�R` W"�ށ�1�iĝGTֹ��}�UAb����ױ^��(�i�d�J)�TI�Po�!ˤۗ��A��M���L]�U�w��UfD��a����Vo0F���������-�m�,��s�t�gb«�{W�Τ�(zOE�s��e�&A	|r�K��s�u�D�`c:%c�c�R)u@Yzz����.��6+��Ur&�!ciX]��5�Ĭ��9�:��+��4ôN�W�;:���\ �lV��G��.~g:�y=3I_{!��D}��������� f��UX�J(J��i��q8�o�S>�bF"��o�@p#��i��}���c�_U�	P��\WV��in�ϕ���v�+����ͺ���r�aUP���b�H�d��\h��l����~==�@J�ʠn�N���WC��O�[�����k5|C	F-Tn]Қ��T&�Z��ZQ���S{	��`�� �PE����N��$�D�7�.�d;jn��+�����H;
y�G���;��{���T�x��:�r�/���F�-��N�E�����&[P@$Z���V�C-�����>�*Gb׊S���E��z������1!���t�D�O�RY0�Vy��"^ڧ��Y�5����r��F`G7Hi�J�Q�5Z��O���R�TSv��,�H�h��yF��$h�±����|g��>�U4�)�M�iÜ<�Հ�uԽ�<��l��,Ҏ��z�A����2�nK���n�|���G�-��Uڕ�<X�	�Ml�0��{�ce\�f�~�	�l����uz��:��^� {Ɩd�.���S�e�&ͯ�yG�wZ�F/U���M�7���uX_�Ro�^R��fJx����#;��!o�&���[�y�j�ڿ��>�X����
��3����ǈT�6N%�����x�r��'���:0�Y���'�fzCՕw��ƿЌ�� �<�=�[u�fX��r���ò��i�߷qL9XeYg\��~�7�&B$�*��	��֬�W��!<�R�hFp�*��xNr>�x�����¯�&y�	y�h��׆oEs���\G$Ïm¨h�C�G����}��o]�.WԚ%oiϿ�}:.r�N��s5�Ǡ����>	Ųo�.�yM���N4�׷�@����U��G萦`r3C�q���=�p��M���������1��Eæ3Þ����SX��bOW�2�kE�q7�$��5�g��T���ڊݰK|�8��:��]e�����u���;���s=� ��^�ܛ���^���3�CE|�Կg'E�J�qȺV��~��Wn/�^������)9�:�Řw�%XE�{������^z�"��%�N�ƽ�z�D��erP<��2��,�z�r(��������l��]���\B݁zv���}YQӝ;�|�P�\�#�ajo�\S,��v4Kc
���H}�cQ�`�{�6�������Eť�̤ʌY/�t��: =c�ifN �y\�=-,7��S�RE!�?�^��ڕ�܏&k�Q�>����:��!�%`.�W����`���ig~�
>�'�%�p������[h�i�H��[��O6�h��Z#�d  +���W�� ����e�ȱ�g�    YZ