#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="569304672"
MD5="747e4860a583fe0d1d05bc9c6a7cb383"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23224"
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
	echo Date of packaging: Tue Jul 27 16:23:31 -03 2021
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
�7zXZ  �ִF !   �X����Zw] �}��1Dd]����P�t�D��~5�kv�;�����y[�y{��F	N_e*��6���f�J��D�"�W���s�y�l�2����_�TH�,r���C����(AmR��]�a^_L���
��oM�}�]�i�#��TM�V1�=�8bM}#^ ���5@
�O
N×3�:��HQ2��M���K����.Y�������E��`��+��}dn4!�GL���y1���Z�XYq��o6W���3�9������wV�����[Z�J_*�0x�U7��y��!�c!��ЧG|@Q��m��m]�݁�"5��psJh@��L w[����Կ)�8��� �}�/4�T��C#�ƫ=�.��'�Ln���ڥA�7�R��K�*W�jK(�}�N$�5��[��T��B��#듬-\�l�1'�� ��5:	'�5m�z�+p�u����-�A-�01S\��;���Μ���؅��#�슶W�C�/�
���[�k?��Z��\�O�7��-�ڂ��\e
>�zF}�0h��
<kL˃m[�����Z���r���Η0r��]&�>���Ra�`=F+��q��탥��$���b��X?����=��#�佀l?!��IG)�4�)��K���)m�Y��`0�����[���`K��e'Lњ��_3���bL�@a���-W���m�DbcR���hD.�t��i�5�QB!򕐆��'`t��m�	
��-���:��C����u���=w�� �pD���P�̴Cj�\uz=���H]�Q{���Z:���=p2�ڏ8�W�$��8�C[�HxB�4��x���՜���OBZ}���K'�]��5X;�$��E�p3w4��^D��!c�1��	(T�Sz��;^�O%�G!�ߠ6��1^o�2؁�f���b6\Hn�޼ �if?�Ԇ�D���.�1?@�R%�ԫ/7�u��:��V��&1�`i̯��=�G�&��L�0Y�����k�"u��I}�On��3E箠S4%P ����	Y�߂o/B���9��鮡�<�ϼ=5҄�L�}Vj_P�	{P@r�j�,�����Bw�����-K7��C����O��.!�A��{8�O��;tCS��!=��eǿ��ѥv�c9��g[���W�{�H�d>S��`�����T4A��p��y���]��Ձ� ���qE6����s'3<��z����%��D�Ey��I��N ��B���S� J��P�m[JOM�E�hû�)v���Ja����a9R_��w
o��i@���Ҵ_X�z��鮃Y�	�Lû[������sj3\�֤:Ku���Y�D�ϧ@�B���Ol7�$k*+P�@i
�)���&{��HϗZ�ը����L�Yv��zevlWM�u��y �F�N�o
'�6�,F���D�p82oF�5�|��u�uf��¤#�E;5ꟹ0╹�����=��կ�T�/Hr����<�[,3��0���Ś�.��vge/Or�p˵�|��|�&~b�L�_3���{e-���44�:־�Y�|hכ�blQ7��k�6��)��-˂�4�'/����huj��XX�v�Aoi ��/+X1h��֔h$�ܸ�ݾqOѿe����:�v>�U���4g�u����}A�b�s���H>�6�4o��MkoP��k�T���a��z)�
���rk�i�W����Sr��D��h���[�p�4�{1бvy�ёٙ����G�T�'������W���2!�<H3xk<EB	Xi4��k+���� 1�.�64uW3w�_|�O���	g����5�G�ҕh� 
 �R� Or��Zø��ƕP���	<�s��q�9��@o#M�&SY�%�8�ї�t�i^G� Y|;�Ա`����0|k-8�Xg[��,9��`s!�"	���R{e��G�D��V9�.��������j��[gKc��Љ9�D�:�VX.҆P���ǵ�cn��1^�EӤ_�B�|џ;��B3��]����dtP�����E��w#�O���ls�Ɛt�!� M�l�A�+"i(s�[�+uKz|g���@�����Qub�b�A"�a)� ۈ�֓�-�?^'�����#����f���ni�ֵ˧�g�a�����(���a��wI�&�~���rs���:�<s�g>��$kh��;1_+7t��v����@h���4�n����W��o>�o�|�3z�pZ%q�m�TN�֒����8��z�_�z��K�z(��G����=>�W�B2�̺�L #�b���$t��!��XOjV�k��8\1�11RT�˖4�Թ��#K��y�j�#�=�9�[���=��$��ɧܸ�)Wd�F���x4�D�Q�MI��[C�ջ�,?�}
��=P:��0ĉ�p�v�A֝qX5����B���V�)\_c=y�[>S�|����ۀ�c�&̀��zfb*`�V�[����,�7�պ���x"%Ur�V�u�����i� %X�`)�gqox[�_�:a��ݮ��-P?ۤa�А�Ij$�Y��P�#˫���Kћ���0�׿�4��w�\�v��w/����'��S���n���pz�C��V�5��43`�̻$z���9^־.��ɴ���n~�ϝq�)0��(�8i!ӵ$5�� �4#�o��OJP���Ws.h/��陃��F���);��Ѿ�$S���j�6�1W�! 6���e�r���6��|n�avE9����Gt����굩��G[�@��k��g-��-��R�q��/a��tX���/e���$M���!��t{Fp��Q��y�IFF���`�B3�~�]��+lCr�2�N2���o��A���xxgz¡�PN��ld6��cWC5 �0�~���6t�]�
*�,9�`�>�[J���ޡ�K��.F�I���K������)�?���p�s����nlʯ z٥{v-ow�hi��9�Y�o�r��2���܇i�d�j�������^����e�\Rԣ�-�9�z������^�6	����ޜm����LQ��Y+Q3��M���-��gO��*�+�o4��Kp�rt6=|�Ldgk�1�ޭ>x�Ir�R���߅������ea���76Jrn��b�ʧش�ӱ�m��;в��V��B�4Q��%�,�ڎ��ؑ4��#&?������Q�)CD@H�˳U${f��Ƭ�d���3�BE'Yԅ%i��+צ��}�g�)P����'��4���#KAc��KC���ă�z����?4�IU2� V�B8�U���h�G�7���Y�VW������`�1nK� ;#�.�
��N[ؼ$��������0�(���w	�&��	�`U�!V���s��Ϗ��p��i�4W�D6s���a���L�|�Ii�6�`�	�'��cC�P�a�~�E�u��Eq6�Bke6����$f�s�)ҙ�U���f��Zޑ�z=<��C���x�>3{IG��W8"��t�ʔ��աQeQ�?����x8���g<�ѽ��5�B��~v:&�[J����5��s�`{��+�JKcq?Ps�p 1A~5=��b����EB������|g�~�	.�i��C�x���FY�Z�n���y�[l��Z��Q@���[��R�0����-���x��\���6� � ]��%|��3��RRHF�Z�*���5h{��h��(? aT�����
h�R >�ƕ���wa��h���y���S����]��{^6ډǮ�Od�L��L�aH3uA��K݃I*)�$�ݒ�M�ܕ�l&���ϒ���pOv���
��1�si6�u�F~�W~�,J�D�5�]#�O�����g~/��kb�ǵ����21��ݠ�׌qO�j�D��Iq��}��V���q�p�䔞k2f2eل�3r���"�z��}B�<gc�v�®�ϲ8B��ݎ��H�B�� sb ���� ~ R�M���W�+s��
�#�[�mL���Q�芧5���X�
Sa�TjK2v<���n�*Ԯ:*�=q��v!4J�V���I���O��g'�\(��s�I���_jE,��i�SX�;bx��I	�?p2��8t�k���a����m�k������^�[���Z�ˤ�v@z�B͊��(_��d��L�?RHA�j���)܋7%z�A=�C��W��:������uo��<(���D���R��Y}�ꟑ�@�r�@��q���nmȿ��O�):͢LL��c(����t�v�3�_�sMbj(�}d���� <NӨ�eM��Bc?�x�u�z�2�/H]q���/��i��B�Iܨ�4I,��b�6��$�2r���|���l����Edh���4X�%���2H]L=�@�C�L?.��z<=NY��Oȶ����e ��ez�Cy��o2"\ݣ��F��5Óޖ���'\��F������!c�mD���
 &"6���IJV�G��}�*��5i6��0��rqO�?q!�j}������{LN����y�08�e���ZY�VՉ��b�L���0C�5p�m$L��Y�+���NeZ��א�ً�1���U�E`�P�_�$���}7:�>�
�X
��&��R���~��f��ͧ=��ܿ���3+Mu�D�ޞa3C
�J���Ƕ�;aWv��N&���zA5޿w�i�J��#A]\�Rf��7���v�����n-�YQ!!K+V:���J}��J<!ٶ�w�\����y{q;e+>ٖ��ƈ�~�cݸ�W"�� ����^��W%$R�2�,U�j*��A}��ݭ����\D�˿J_/����Ej�)o7)_��)��<�y����S;�O������7��k���n�&�:�u���F�_�q%�6����#2�/�ؙ��J��I��8�˒��{q��o+79f�r�����@s6j������Ƞ�}w�F�le��?P!�gţ�6c�[�ҿH��Ţ�i
6��@w3���%֖�+��!��ý�[�v��L �?����2�!�F���F1�j���DO]զ��ةs��":��a�' F�yK @�zh2��d���{EcX���1�M��E��ڥ����W}��Z��(��ÿ��7�Y\���A <�ob�9N����]x��`�t��d
o�`�6��'9<[�|ՂH���#\8�Q"�:y��vF Yl
"&X�a�9\����=�O�]s��+�$���<).Pv�h�)殱����U�0ҢE����$�d�.��-�h�}6�5����s��v�����t�6L�����ᡧE��Š��� ��vʠ9){�/�e{C�_s2pɬ1 �`QD�q�gV�Is�����u'�U���,b	�� h	'�F�FJ)	�?2"մrw��R��΁�1<��|P���=QCV��w��-�,�ÿ{��vő�9M�|��kn�P�^�U��j��F_�ӌX�4�
��A�T��6���8��~%7K�E�d+����f��آ�.dhX�%��8c�=nss)��a�5���+��7��<��@iE�Y��M_$h�͘��+q�D?��%z�s���:�!�FzUhj������s��b/;�5q�����k�|����<Tĺ���f8il��s�tlP
��jO(��o�SM荰�0�8��(�Wk2�N��g`*����PA�u�ɈU� #�e:	��5蒺���>b�h(�D�~�s@��
��F��O�;��[��2�oI[8]i�m�0t�B#����h���c68�w�.6��_����*�3�x��n��[��`H��7�O&H��\���f���0F��FN�G��r���A۬�e��w���B�}"x��8#ޜ�ȍ��A��?㐫g?��~H�e��#�4�yb*!�t�O��c����|飢'>�;�ym�/�'��|H>��G��[���4���Ez��}�Ont�7���[�$([��y�>?u�M��J2T"M���y]�EPBv����7:N�������Ǯ3���f{�+�׬��Np��Gb,&��30��
5>�V$0�4��N>�+��T��1cy����]n9����#i~p��gS�A�̇�1&�N��--��7���O�͖^�e	�<���^'C�z�U13�c'��`�,�#��s�ރ�ͪ��T�=��$��1����'~�|E�/m��D7���K�h�,(C�Q!S��tZ�X��n5�Ұ����c�-XXɑ)eZSg�9�n�����Uԏ�a+=ڂ�ask�x���1ʘ�\��\�{7��}K?W_��+ǹ��m����ރ^�{=�(�S��\�\���k=���Ɇ�2�DCP�Է���(�ډ`m�Ϳ����B�}.�ex�P�i#v���־n'le�g�����$���� ��%��!0������`�����6�2����c�~ �Sh�N+Uя�I-s�������Q�(����"m��_S&J�8�
�v��A���,�
#Q+d<e�D㹛��5��+�������q렒&�-�!�C>��{��F;�O���uX0�k�5�i6@J�~)I壇�e�V_j������<�Ё���[)��E���*?b���]k��ڇ�m�,�����0/�4�y��M����1�}�����'
�yŬZoSoٌ�D�r�V��d�O�w��Ͳ�6��OD4x�$���.�kk����e,��f���C]���d_+�.V~�i�W��V�
�PRe���W�DV�m �<<8�_{�F5BgO�����?*ʥ,���񆥏��S�>��j��@��L∩�Նb˂��,o��K9�'��L*%�����vdӨ\7�4L���[Ȟ���m4*��\���{^�����i;f{9FW��x�Z0��0-��;�D�"��F��_�� ��xZs�a���3Q\h�I�����4�q� J�����t�g �}�I�[F6j��C�u�2x�;r�1����be_���͜ى禇��=�~i�#�.?L�B)�7w}�:z͊��l���#��?����z���A�V���&Q�ha��4����aB郤�k�3L�y�T\{��J!7?�u�B�]�H�4v��/+��2�h>[m"�k֝�g�`Qd��/\�䨱��L��3�y[\����wg�\`��B�J�SS��EI��?��+�\xa\�9����V�����������!vm�	�0pۮ�H#�5�)5PJr}�
(f ��i�� `�N9VK/�=xG2�e�?FA2 wT�eX.t�φM�2@K	��?mL	$>�T�]��"m9��D��m����֤��0�蓠$>4��>��n9��<��{��������V����&3:(�QST��t_C���c�
/��9;3��t��5�#S�C�v!�[%��x�B���Ͱ��K�����+1��9�lT�J�H�܋M�"K��G��E�`���7���c+��|Y�s�7Z���
{�S�#Uʅ�v�L}>� ��]G�d�-������/b7_a��Ξ�s�P��?r�pn��1Od�k�[>q�o�M|$����%�cW�;���Nrm`Z_�FZ����wi8�p	\M�T��`ۢ���S��k5G��})d���(T���v��ع�<Z�¬.������1�,�%FwJ��7_�����N:s<�F�')�[LR+9b �6�Jm�wϟ������CI��ĚK(��ɇ��O�׀m����`�X�`Y�E[���D��S�񓌇�K�37�M��3�j:I<=Ï�I�Ղ,�2v�~�)�#�b3ۤ|�%Ϻ��^I��l���1(��qkΗ��ع"D5 ���y�w�jyk�q�,�"hT7g��>!�R��6z��I�q�\�P�%􁧅7ԥ���t#9`h!)�?�4���T.p�7��R5�ʤ z�$ǛJ����ج�q������aw�)Z+�q��n�T&3��:G�U�1O�pF7=/��^1#�Xan:D���ϋCS=[P�u�Bhp�vo�Vj��7���DQ<�V��+�� �xo��ΒW���,�WNwjG'ƪ߸�.�����2�@{m���Х��+5bCEk���󞲳�B�qp'���/�DOmMv��t�3S|EM��Nx��T�k�o���<��+�IF�I�Gʗ�Ӆ+�0�݁���S��픮��>����&���D�\��ʱȣ*.JbA-�3�@n��w��["[�B5��,��jz��o��fz�o�5�����3z�����1l�5�dlnG������׳��Jo��<Nk��V��h��V��s���V�LSd�	�CZX��=m�Ƃ�bvچg��	.��������O-���T{{��ܬ�P�05��=�c�ޥ��,��/���X6�i�a^���G�h��4=�PǺ�����^����-�}�H��=��_�E�11��P��v��Y*+�C�s�$h�׊�ǣ���	�����3�mt�AHE�ɕ�H����&���g�v4���E�
7�H zkE-�?"E��t|SA#Oˇ`��Jt���%���A��{�Pa���Қ?V&���/9R�%֙���Oy"rPvqn<��{��Q88i?�_�0�P���w�N�<�Z\�m�����z�HS]���v�"��+W<^�90�B$���d����5�i*��DR�;S�L���5䐣Q諅�X7cȩ��`3c�7���hl����s�w%�'|�Q!8���{��K��ct���/�懫&)�o�K�!��*�H�V�T���K}���j��'����[��ca�?}J`4���/��oA
�/�bh÷r���vnT'!8��o�8ݏIR*��P�Ru�Ѥf��.��;�L��i#�D! �/���4�r_uq�?#�!>�^N�F�_M��������8���6�>n~�pAAR�x�Zf��b�s���?���^e�{6��XZ ��w1����v+飯�qf���%o�A!��*�NH�\�IT�)��Q�I.3�W74�n�#��<�ȯ�y46��;�2�O0~�鍉���� �A��w��d�"0����r�1��|v���KxHJ��~��b!�H�G3q?��\��0����8}7���D�R���Y"+�Q�&�D6��K���ʳ�&®�&'.��"#�������	p�ŕ͈M�	��4��xg�s�� U���ya�P_󴮹$'�
O�p?L+��M
"x����֑�t@E�4y�I &[�@�$�E�޽;!����)Y�� ^T�;
(�� D��縊��Q��z>�r]�ͅk�����x<��dh8 Cp2+C�k�%VڴL!�a�p�'��"�:q���J���a�8�A��6=I��KQ=�<��Qu�If�>�h�[Fʐ�2G�O�J{S+t�kM�S�;JX�[�.���3�W�(:M����`j֤��T��`�āP� c�if��4�RPLy'��
��z'#����ܞȝ>�%i�QwWWZ��ڸ�.���}h���� M>��Wbq{�!Z\�������F��V�hC�Pн���I�3���o�rTaϽ/��O,IB�{�]�$JN8\3 �3V���Е7��@\oC�!������@�����6��Mq֣��qq#���(�W�m�ܰ��v�`���R�o/�p���TN& /L��o�l�f7�^�bb'�mر֗��+��&�	t�3�ӭ��N6Cʍ�4� BH'|��j_fO��>�9_�����.���	�B�f���r��p���8,����D�oR�[0 ꧕�;�Zt��U���ԋ}��m8o�bx���[���h���0m)�kۭ�R����4Kv9{X ɡcܐ��k��mc��eb�{���j�����������-޴��o�I�+�T7U���P��EpƧh��Y�������Iß�B<�(e�KL��U��w�
x���L���	sq�y٨�5,E�S��l͑�=�;mתQ�<�F�����؋�*��e�)�jK���#6iG�~�y���?
����_�b��N�Ǌ���#mh��1��!H��6�`O��♅=Ot��pȿ����%�����5e0�bX��ϛ͋{�Q�����.����m����Oy���Ι�\��7�E��e+�*�J���I�Y���۷��[l^��.�Ʒ���2���,7�q,T"U:s_[8V��$M@X�a`UX�ܕ�=�D�~b>�,����W;��Q�	����4��t����%�N]�t�}�����d{��D���Ʉ8�
h��^+��ы1,e���m2_|K�HB\Ks_Ro����8VH ���d��6P�۴��,�Ũ2{�a��iŶ����S�F�󐘭l�S8
x�Վ�чʈ�i�a ��Aq��c�mK7a��Z?bn.��\���ο���Э��"��h�"�1c�;�c���k�o�p�:UPI�j�&�	����j�~(���ep+T09H����E�w��/�
�b�3���`pW�r��JW妊�>�j:���l�צ���4�	�͆��1��E��̃SZ����h�;�H�M�1���,fF���c~'�e��OQ�.���?�i��$(�׿�	��PLTkl�t��>k�:�NݧU叒u�ɨ-A��m&��4#��3�ɿP�
Y�u �1e���g�w��%3��[�
Qoϙ�eH��h�:�-Bѵ��$���,V�yv��0L8 ���&q�&"h�'���p��"���7�>��	:V��>����5Aun����__Y�%!��XH��K�v����$�5�N6`�v��n��M��##�d���a����j5�n�(KA�o�2;�Rf�v�;���1��L���ia�E�����	�4CB~��Bm&]���ܜ���g�>�w�dWji�g!�L:c2���ډ�>)z���O#=���o59�r9��?�"��,Dq��,+���W��N3����t1;���7��4d0�����2���J�D�c?�\�y� ���M^FA����J��ss7�*e�����(����=�Y�M*��j�"\\��_f��iqS��IX^A�ͦ)!���Ȓ��gNo=ȇL���{��#sL�܊L�i��)��V>�b�y���s�~���Ry�-p��xn���	m�N����޲zo�U߈,K�;_���ZT9%�,I��#<�ؘz�*�� �I�����j����o�&�Pt��Ȇ�{t8�!����V)��� ���'�Ch�K��� �c&�Q;�f>����FԪ>�Na��:j��;�4h���5�ĩ���z�q��>xyMӬW����e�s�O4��%r=2�����9����d6��C�h���X0�!1j�G�hCQ$WV���ѧ��>����TJJG���ǻzR�/������~��7F�V��W=�Z+a�����9wn+��֞�M�A���O`QIG�+�߮=�*��`[_�
wi��e�����_�+M�n0'���j��r�e'�<iJh8Hؓ�{q�R>w��]��/�R>�ͺUi��l���ȓ��t'�|�a���66oc?�qR�H���[�m�W��y$�F�>���(3`e��y\y�eˎ�1�^zj�]Y`� w�B�$��	�7�4�BQ��[��1�ewCx|L��0���8��$�7n��^C�V���A�*_�ȏ�zͳs��!���@��ZV7��-�<�E�� PU"��<�12o�|eW�NA�`��{�N��W,�2�+㬂��AyLP���ٳ�D�I,T�W�����ɻ�A~��6��@k��z������ >+��W�3����KM�R
�?xo�ά^� U>��Ʒ5��=saf����G��cw/O��$�4�^_�6>�,O>�И�l�&���&�l6��s�j*?�x)��c�]&nAk�y���uj�URb��Y��;w�(�dƱ�Ƕ+>�_��P���i��8L�Ps�-@{5k�f�he��ζ�*�n��	�-���9R發��K�(���"F���ey�It��7w4���<�tw
���_����_\R���A��g��E�@���3V?v@� ���|�s���>M���g�xʑO#v|:�YzN˝���E�OCjP#r��Mx���m���¯$�����e��g��:�AJ|�n�����ʃ�5tj~�a&o5k(���P�
*J��*���M�N'�M{15�|&[�,Z_�{�7,�_���kW!��'��k���ǬT��dي��
tpk��̚D#E��Ѷ��o�KkxC���q��{Qc�����|&O(>�\ZA��w��.��Tg�R����c��`F!�	�~ڀ;���~�(���wx���M0Qz���b����768�������x�C�lL�T��o���"׊='���j�I��J�v�y^9��>'��T�T��"5���١6�⑃W(�v�4$�4֨J��90�S��?�G����Ƀ2�㮿U���P�+ ��U��,M5�HE[�֡a�>}*�H��5��"t�6�D��g(y!
.?<���[lҫ<3#EI8!�@�3V'��+]��?A����]�k�n�GI���{F�)Y�q"�t�pD�^������2�wP 1D�[T�J$,��n�p�[|����*M�u�����2���c��,-���H�Z����P9ք�.��.ﮦ�Fc}6pfx囊<$*�XL-si�	�������@�#6�'�����nA=Do�=�?I��6jg�}��7�9jU���?�[�1V���y��0L�A{4x�/eNd�q����b��M.�P�*�����e���)�����&g	t�Ћ�xfW��_|!��wJ<+S�[��J�!�_	���.�֯PR$߇m53�ӗ�y��L�rl�I뮢{d�x)H`S�x09���͸�[�4S���"/��v�31Vŀ����̂M0jziw��
��o���S�!~�I��'�������>���_h5午�Q��4�����*[1��[��$ฦ@�󚗻�e��#.�LB lEH��Ԍ��RJ�P
�mi�t#vp�k�T�_�w 8$(_�䝀�(���2��ݻzd�f
D�.>w����=�������k��*�/�*�dxnB�ZNגt�;�/��XnW�.��zh���b����7�&��`����?IH����H��۽6y�{��u�H	Q�d銣D]�u��/49�Y�T�/9W.���+5*~��]�'	�B ƭ~��b���x�j��#��(���AjTݯ��)�P��7�X���`2J�c��:|''/ۓp���`5!s���9|:v�Xp��7U�]
;>*�j!ᝮ<�3y
�=H)���e��鹙9�Ǖw9���p��^��V��}<���n)vcH-}r D��^q�~�0tڈ��i2��!��֫ζ�4��H*�>���1��r��k]b���`t�s�
0���փrr���v����`�j�9W�;2G��0q�Ѽ;�#}�jԍa���"j�lV�x��%Z2��i3Ⱥ�ҫ2]�9l�]�~T�3�n�o��QH�m����� j�0�Gܕ������ >D�g��hm�^v$���]�2$����v]� �q���w1 jP���	��I.�Gg�������tV�U�e�H��Sa��8�$���s'њ��*��ۮ�&kZG..�6���W��!Ψ�,\�w[K�v[��Ѧ.�|%ׁ�6��G�H��2Ԁ��͋@�^�r�,���d���.�6L�.��l@���?��l�̽K���QCVA�1�A)���Jo �Q�����˔���Qƶ�N�&�M�ٙ��)�T�ך�������A�eY�qQ�#J	�s�;�(P�RU�d6A}+y5�r�X0���lqy
6s�&����S-�q]�g<��D��I�y���`����PV~�!-�?�?r�ۊ�HoY;�Z���<�l��	]�l#r��ᔣ��,��q�s`�wVX�"��eRw�t�C���evQe��h �{��'(9Za�����'�g�[L�zT�ڸ^����*��u��>�%밧(p��pR�p�4Vv2:�0~��gb������&���s��F\�|�po���b�M�=a��)��j��H��W!p#�#�a�C���l6]�:J����)���Sm�J�3�1|���������ZlƇ���\��,��^�ܯ����^���ص�)�=��3�j�}���<�)'�
��N�hC$m�U}��Z��G�K��R�jRr����"�Sq�z�kj�[�8�3}��1p�D�4��`�BJ=� ��ӳ<�jV>��łɼ��$� ruE`��ƕ�����d�.n�-�τ��NjP?�rj������]�6�#�13bg��S�o���E�<q���%�i�ݎ$��Ǭ"z<X`4@\�T�� ���a��J�9bX�7��g��m(��ԝn�v�S|�Of��[��kΩ����	��@yRE�^]����%hL��]���Ѷ�
#�i�$3v`�2]V���J�϶�x�:�w�b�y���E�uC4����[���gMG6t���҂�m�����q�xKui5L�_+���n|sƷ�M18�B� �Wl��D�f^l��9n����TĄ��<6�l��?J��ڀ5�2@߷�`��vq��]_��K��n�ߗ��J,��>@���o���a�Il<��Jkn�Ho��gZ݆�ു�Yf��d8�{ir"�R��~#�S�S�[���GhkJ�^��b�?��hYz7����\/�Y�� �Wh���Зv�D����2۠���h��k�,Q�����"�k� �� WA�.�I[5��(�rf0-`�Z���^�%�8�s���)u��Pk�86�W�׀C����&�0ë�nH<��kz�MC|��&����!e��d�/���4d��%�*!�h���M����8�M
�~�\2y������ݚ7�ָltG���e�R37��e������<�8�Ft�j�z3|����2��F=��]�"�l�����	E}�h���ʛ��"B�@���iM�ڎf $S+�Dg�K^�pĠA���/��ڿB��覡a�U��r�Hm�V�l�4�DY�<�}ffyW7�\�A�l��$�%>x��"�X�o,�ҫB�$�|��ˇD�K�=��NG<Ҝ�=��?Pe4pE�+�Ŧ���P4O#������Ir��b� �'�|��sֈ�R�rx�������D@���I���]���@)-{��l���a�N���Z4���U�z�V7�YY�T%�?w�E�=Ie�Ƿ�-����O>Ë�N��Ɣ/��޵"�9��B&]Y��t��5Ap�����ҐrY�f]�b�>{=JĮ�+��V5�-Ubw��C^!~ ����&���9�鿖��ўsX\W��gv=�}Ed�Z�g����B�"�٥&��`sUwqz(���>eT��1{�آ�[y�絩�v^ˬ��:�9� "Qo'�Ѩj�1�w��V����Dn�"k:W4x��$;+��x/�!�.��j�R1�0�B�ۏ���%�2L�%����A�L����T]�Poi� �8�,u$T��gR'U��9u��S�89=���E�ݱ��k%���sL��t���!��F$��)[:�#�������M,۔O@����1ѓ)Ɍ��]�S���MoQ��c� �H��$ 8�'�@�p�;����Bg�ͯ��]Suђ��I��!��U9�2����Ӛf���g�B��]$�����ޥ�eV�1�.[�5��r�%��&,o"ڐ�I��-IfP��|����#���)(Ss��N�����=�=����C0�������l��؋��� �y��B�A���sD)	ԭp��is}�[r���hVِ�_���fͽ��Fı��Oj�f��	���\�/;j,�h�9�4
�l*Xpu�$_Q��(��vm'$'��|e��+�^!�(+��'�C��?�=�qA�Pџ'���B>1$�����9�7�w�������!�˶MXK��>�FW�8���A�Hh|���<	�f۹��֞������݆cv
�����7�}gKX�~c�M+-h�8���_
�k��i���c�@���x�L]Ҭ�sJV�ۡ2�Q^c�4�>}���r:���E�0���Z�Ȼ��)]`�-��,�\ ��jM�/�w���?����^݊���TR�MCa���"�����,MJ��<���q	��¿��+/��ҝ)m�Ą�z%Dc7NH���>e4$�<��`nT?Ӫ#e��7�>
X��s\ٛ#�i��[<FR�Q�n�ڱ����
[�#�A{hŔ)�Gn?L7���:_|��u�dWQL.P �_��.���$���X�>�U&��j#f kR ��H^�4a_�h9D{buH�a�G�

Ik�j�ȸ[��p=I��'���[�M��n�Qk�����JT���@) ���Y&:��(cѰ��qn��H-�6�I���љ_���#��k�Y[�=`�!�#VE��x�#v�]|,sl�������ٗ6���>ɉ��=-_�W'��[��Ŕ���q�s��q0��*U	��\v	��.�"6a\>X�m���4�W�L�S�s��=�|�B�A�� �`�	����7��:=G�n�_��8��:rN6�r�sx�}I�&�~YX}UmneT����oCgg��%�~o_�O�Q4�y���L4U2���8	���SB���8�)��7�m��B~q�׏�5��6��i;���Fc8�^��2���ӗy7�]qpn��7�E���$!n歃ESA����1B6�ĝ��Bs
����Κ��'^K�Nd`�����,��@̸t�2��tb��7��ɽ�sŦ)&������F���C�g�����c�F�پ�#��)�=�dr�٠�e}�Kr�����Mm~��B�>�`i�]�8`�h�� /�r�S���%4?q��wsy�ǆk�_��zwӌk>��@��o��n�����fx����_�t=6���ZF#G��t*R�\ �d�5�a���aB �c	��`����4�ț�7D�[����r�D���."�U濤޶H������`X����&^��>g���gW7�"�vnXWZ/m���u��m�"y��g(,���Ұ,�W�G��C�1�]b(��<��D�J�j/��z%�����5�o[[��lN�_�����Hd>�y��n��V�9����[d�BP^����m�3��2��(d�i)�Ѕ�b�cy/��mz����B�I�;��U��*��7��C����]wϤ8��/5K�*-m�;�G��n�ĵȧ�=I�B0U�I)v�ynqjL����>�mT;�X�3ќx`,՞9���:�G~|���$j,�Aҭ�𴩺�Y�[�r���N�G�l���F�;��OV�E���D�>k�Oj��,'�*Vǆ�[U:�ׯh 9���⢰S���x��c~a�tu��ØDMN_�����y^/�����z�1G�@a��5R�X�5g�@�u[P�#V� ����W*����k�NS*����{�u���=���1z���h��0n���R|0q��9�!��:�v�"G�C�_6b"d[^��K��y�2o<;��}��6�H6�&�S��dH���G�ԙ��I�L�H5BM�&}���|�z*`��Q��֍���b魖iOQ���'���»,�>k���U�D@�k��#V�\)�}˽ig�g�HY��$�,+����{1W��B_�Y�[�=mr�i�N|��B�j�)��L�d�s��DPf�jO�͖b��"B�N��UR�*���g��˵�����v�-������� ��ۀ̘�:�*{Q��ũ=
�hYq�F <�a��Y�:�^��n:H�X�S9�R�t�?���w��P�~�� 6;C�P�i�䯺���?
�9�Ѐ�5��ƘS�/�Pd��/P"w��}�`�A�-�0�A����)H�	���^��"	�Y�� l�ŻlS���|!'DtU�!_ ̹{�P��X>�A����0�檣���Ou����S��䊶M����I�=���W�l)L��h%cJNA���ә�A�H�W,��䖖�����������B-�sJ6���Wz{����N�
�'S�g�P^"��I�� Y�ژ{��Q9Y�fF��W�dF1�'k7����/����(@^�]53,�,w�g�7�c�G�4��VE�b'o)�({����@	��N�䒲�K�PK�'~]��[� ������6��2%���lF�Z�;��x4<��#H�؜+w�c�T���!�Akq���ú�T,C�����P�Y���m�0��Z۳d
�Ȥ�N-/�[��\�MN��:��#��%�Zp�DI8}ݕ�$"�j�6�����@7S�s��I�o�{}*�+E��
�&���qO���G=8������D�=�G�;!1mY�m�����bw.&X���03��ϴ�H��Y��<2�Q��ZvO&a�⣲w��H�64��c�댱S&UA��N��@���2B�����=��Ǔm�.�%rhd1�?׬�1U\r*�VdqT��P�G�
5�i�ٷf���+�b���B�uz��F���?�/��ފF��@o����R�B��8�;0F���P�o���ު����(�����Nw�z�&j��~�w�G�WCn~��J����fJa�:��#�BPv���:���$�a��P���c�j:�_ޝ�� �k�Ȱ�m9]�ʟ>���d��r��7���~^��K.�[Y���2n������\}� I�x+d�GPljЯY�����C{�a�UJ��f�N#C�ES���썰�rB�%���zh\a@+Z�����=��g���X�H{��q�[5`U��˓v~��m:=k(��wk��H���Uҿ��?�� �5R
3�rF]���SUG ���We򓹂�[�t3����{�ªz��5V�F� �n㈋t��3A��hN�0���ւ�]��h���Z�a���b�������U9T�5ݏ��������U7��z���:�8z��(�K'��H!�TU�j#Z��y�lC��`%@�@/����#�p�L�B��2 �+Y?��e��i�ɲ
����~ɯ��ސ�{�
����(��WXZ�@�����oK��9?KJ[y�Hn�'�N>��~��@6�QZ�E��Ø���da��,~���>���Ae3��t\K"#���O�b+[�9��� ����#�_k�U#̋�Q��33S�`�� �ͫ�z#6D������\�"|vȏ$oŸ��6p�R�L�,A�Kx��9�[���)*�Mߪےa��ws ��De�s;:>�s����r�`�2�t4�ؿ!�l!g�p P�mB�N���7���׼<�?8U�/]���$t؉/�iK�%�j�����LC7�<Jl!�H��!ߥ����d	ظ�K� *������<"��/,�Ks"V�cD�Ψ���u���N��i�w�R����Д�H�1�G?�z�A�4��'>YQ����.�8�>Ѧ�n�Z@0��m;�X�4[v'���K��G
�޿#���G2�:g���g�߿�#ط�U�xɄf���iDz�"<B�&��D���R	���J�U]��P+o��k5⊠���q��)s�����o�)�B�Jɤ�{P�"�;���~C�����]���^<�0Os���bs�^���C�N#���q��k=�����^E���O{xw��EqU�&������W�Q#�o����-�_yh�}������������=|n�W��I����j�wd�N�-�.ֶY<>���C:�!*������.�CJ�\�S��``ҿS�k�O��"��f��|�=�I�{S�����p��j]���D��V�X~���9��ج���&1�n�Zdo4^k���D<�m���[��2���nvزP)Q܈8d���f��X	�s�����ư<�����:��f���Fc�>+�J��{͇���oD����S{^�o'�#̃���c��P���	�y�^���`���L��H�4���G$	i/L��'��dN���w&���,!��7mK!���
dV*rN��Kvh�Md{��Q����EZ_�o�Ϛ��`e�%鄡:Y`2֪�Kw��>�I� >Vp�0#���h����֥nq��7p�Zm���̳��Vš{�(�87l��#��ht	^�A�:.dͬ5�nDp������|��0�T����IP��=�[�3���]Зҁ=ù��Ʊ�-�÷9PAA ��"��[W���v+���*�R��V˷���Oo SG�;)��Qb�0&.r@Dz60�ܴ ��F$׺J�z�nH�Ĵ�=��~�` �n����l}�/�$]EY�!��y]Y?4�qv���ל>}����݀ނ������_���P=�1��3�;�&d�Z"C�9��C	�VV&�ӒMW��øX�T<DXe'�C1iw�S����.p��用]>]I�>ãө'}�	�r1��)x�,�W�t,hn������˓��;>K�F����c��1k;gh���h;g�5���:u�^0"�z�珀��NA��Jb�Z�[�w�`���$"���}:W��L�:��׳�yf�V�C��������	�uX��d��2�T�̨	�]|�."�U�K<�~���	q�_�"a��)h�]B�1����~����$�+RuP� ܍����+��َ�s��tF����d�,\o~������1DԦNe�n��x��z+�o��7rT0�Xr���
����y�;� ��1�29U�6:�(`}�������B|���`���z�����s�h.��%qMOq7x}	��E E+]���͸}�X,���t߇�"�v1�z���rî���m�Ϙ t?���̹'D(���q��)�ޛ�A�'CA�M�T��-,���%W�/^����$�o�Ϋ����p���#�!�s������%�P�b7m,��2b`ap>;;*�K��� ���4i<�j5���
�e�]>�����	dl�8v=Kz�}�l�c����N����������ޗp�{�ӄ���XRP�R���L��=�M\כ�ҁ���0���@J�G.W�n��+�Sm�"q݋��m�K�&_f{��Nf��@ �h�Mڣ�yk8�ښ��b�䵈Y���敧LK���SEJG@�
����3*��/�Q�b����u�C�Sx�Q7aL�JUZ^ ��#��"�z�-S�34���Z�V!�IZp#A���A3�ҳy�I�)~���;��^��V��\��㽇��t�``�֥����rW��z�2��q�����/,����m뉹�9@v>�	m.+>!Uf^�% d4l؟k5��Z"XД*V<բ\B���hMvJb�✧�*�mpxs�<�Q:e�c%Jם�3��m��T�[�m�s�m5؆I�=���G��UVkn5��q��)�2nf��չ����~�sS1=�D����4<=�/�2Ψ�u �v�$�K��rB6݌��:����&��q��eʪ�9bߞ���h\A� 3`��,&��� �wXa��*2�.G�����8���PO2��� Y�`G�EJ\A�ge1�J
a���j�:=�l��Ȣ g6zku�}��:�����$&�B��=�['��H��8�ID�ѧw��Z��OG��F9V�&*�b)�^�����4Lp���ɰ���'���=�
C�4=m�7"��� �V�q�qV�퉽8Vww��)֫]<j�h����FF�2_h멌�9\�b�V�'���O���~�u�ԧ
>s{wL�I*��۩���]f�o
���vD�fc ���8����(l)��Ϸ u�C��vf�\��w~▾��������Ї�J�5pv�>�S����vos�4�
ܠH��
j+5긦��`���y/GC�({��.��.�̶_��^����Ć��*�?-(S����Y��5$`,�1!M���K@fp��w��=�V�[��_؁@��Y*6\�L!y��I�,���^�9�PdV�$�৔����9���ʬ�	�'ð*�A���B�B�#�d�jz�'�R�1ϒ0}���qJ��l�zA��gl
3ӏ�ǒ:b8���
\��_���,����_ʣ�l��*V4��27Vs�z��k5���-��LeCsx�1��P<K�}��u�,�9\#}׼o�hy�9&�Z�7��-��s �g����+_�G�����!M����
���,h�!��O(�ӧ�B&���h7]� $}�P�KW����{�B�"����丽��N��ն���`"��Wa�G�����9A�p^�@����r,��F��+�W�u�2���.|��Ve�zؾ��l��w����Nˣ�6&��JB-K��:��|��g��	��v|.�bVzRJ'�dt��}���E�{��3��:��8u~l�T�)��E.�⧹��p�c}:�%.0;݈���I����~�׈�e���W=q�X��xj?窇�V�f�!�;D��A�����F�)�������P@�x9�m�ߣ9��B>����������Og�ٍ�ا  kAO���] ����\	����g�    YZ