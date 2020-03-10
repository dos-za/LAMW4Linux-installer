#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1640877099"
MD5="388c2d0facf9d094343ca4b240f9e5ff"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20796"
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
	echo Date of packaging: Tue Mar 10 00:21:21 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j���^s�^���&�\^�Qi����C�����D��[]�'v���QL�k��D}ʂ*��ݱ�3�/��A]���y�찕����?= ?v���͊9�T��D!������u��To�S��+�mIt���0�)�����5�N�y���a��ut��l�MA���p�C0!����"q���dh�2�8(x���:�Aޢq��8V�7�8W0�w�-^ψ�4�	L�zKO���i��(M&�{��tTk������阣��K�yՅ{	tf;8�/�=�A �l?s�7x�Sr�?%2/)V�5ſ�N<IgknW;�-M�[�EA3i�ͽ���hహ#VW3P�4�>܅c�V��<.]�F[�'Í�Aa�%�V��آdPAD1RT&2�)9,�;6kp��uB���#�moz�f��.,��^��K�џ��L�����@��.KĘ2���c�Î�����������㫪�?�Ժב�e���Axa�7��ɛUk�ߌe	��nVo��E�
���c9G r�����*E9Dy�i��Ɂ����.&�����9��P�������ɷu�^���~����|;P����^�`�z��KqH�E��z.�Cix�ބ�XXSu�����kEE;f�I����p��� ��Hy�r�
+3�S��P{�5#��V)�jp���bݙ��M�ea�G�w��dk���/		��:9\�zA�-�������o�c-x{��-!!��rL��%�o�b2u���e4�	<����B�X͆\��㠊&BY���T���$�{OK��W��	*g�E��9@TB�38ܸ�:Tp[�Ғ��o"��N	�rsy�ڡCd�ֱ���]*]�([�����h'bCn��{>��!+��Ѧ����=z�X�-�
����(�� �*�^�4�b�'VS+d
����-�r��� ��f�>k�t����@�<N�r&'�pm��%�� �+U���g6������<}�������N����j��#�'��Ps�s�`��^1^�$��}
��༒������Y��WK	wg��λg&v7i��|��^�1 �
��06z㬣���j1�:lr�e�l��͝E)�|%�q�Lq͝N�U�4f��n�Lc���%s��.l�2��`�.
|:>���Ci��N�UՖgS>����dg���s4��� :n�Q�C�(N
53�Ot��)�"������h����I����Q,�ͼf��DrTO���U��Cu��P�}DF���]��>����,!N�>�F �0U''ƺ=��g��Cd��.G��U��'��f������t�`ۉ9覟�Eui�{�p&r=��g�)�n��S�P���}"�/�̰V5#p�N�:d��-3kY�G��^XnH|u�b��w��,�*���Q0��k��w�Sw��Mt?���^fw-�Q
l1ީox ?���FY=�t��p���a�2�]5���%L��ބc��b��R�q���g�1X��`��+V��̀��v�e�(��픓�cC�"n��'�B��1��UU��'u^��>�&?g�nfu$C���T򉻊7��������Q��,*��{ˢ1�5�
��&~�"��9�{x(�ݻ�+����h�c~F����1���7��&n��,,�8w�|:c�bb@F�Ǘ����Y&m߀��Џ��d��qn�-圴r��d���"�w�Z�፛���#~� W�.�j��1�}p*��{��,�*�Z�,է�h��'p��ܞ�~*��ZT�X�~8.7��1�m#,���zH�N[ӎv�3���9|	�X�4��E+J/��� ���W�������������:��ڈU�9�+O�[�C_���=��en\�/Ff�� R7��]f�s�hT2C�n�t=��s��>U�%��'����Pb� F<�ʩWf���зGzYL2�L.���������$�(i-r�;s�Β~�����|�QN�쀂|��D5���u6t�dRɲ�R�<ǻ<���Q�`y�׎�'�^,�G�ٵ��1�p�_b��C��
��L���vk�o)�"r����vf'6n�-�t�!1;��?�fM�\����� ot
�k�=�Q&<�UO��?|��j����5ъ�u�;���TU�@�tx-� ����f�"���V�B���h3���@��->el��=}cխ��1W7*��s�[��^��;%GcF4Uf��i��~p�����T,�W㷫F�a%�q�k(z�q�����"����4vIy�L�1�,�Ppǧ�CC���U�#���s+����VM���kI�0Vp
�'�E�6Ho��_7�v�%��#~��;����[��.{�P�鐐�f;;�:��F۠����[��󩆣w�fb��pY�A6��_'8g��v�T���'$���Zܱ�bb��kX����W�H+.@'HF[lOf���&�~f֓%�S��i�s�b&O0�>f5�7��?-1�i�d#+c [����ˇ���&B�P�V�T�қ�	gF��Kv��F�	�QC��@�
`+�;�,�v�"��M c�����������TK��]?ܛ�{��k}!�q��C�#!ʼ@���I�n�����Xz�Y��ey��K~S�=���CX��:}�u�&�s��
�!��Z����{),�tZ�3�V��B��],��1@O�<z���@���UtF��(P"�ξ�Rn�?A����4�q\G�����*m-Zf�*����<0�4�ɀ��/ir
e��4ә�;V�1dXSŽI�y)�ΐ������S��!�7j��3�\�̬��A�n�GTc��2u3Z{܊���07Ɔk���@o[dc�����]��	�ȵUݘ�m�3�.�s]C��2�jK�d�^����$5:�1&K�%��`�} &{�m�zN��]����P
�ʯS'3�/:��1������i=���*^/Ed�(K��D�����P]ӧW��0�ܪA��O렛���L7 r������K�/cL��inKHW�z�v���<#�����>��wA��9�4��6�N��m,O ˬ�8�F]t�L�E��1��Gݘa>R��-J2I6M�W�1u8{oϋ�A��q��iL����75�u�YT
��T�r�����7[��F<Bq�8�(�D��h�H`^ﯡ?R�ф��m�n��R#�m�tx����PmM`I���T�l�7��2�R*�M�t"`��A��^��F�QT$us*�iy*ߪ�3�h��6`M�9��?	ʠ1]���C�=c���zDxr3�W��Y<�h�Ķ!p��z�~qݥX�R����a�7�T�ü5�g_���>1�p�5 C��~k���b	�Ӄ�xw?��/k�`�N�^hOX�e��|�[��u�N�C��%#`v�tͫ�������}z�v�V��4d����xf��U��D]����c쉧��@��]��r�ªvI���[�E��$��t�|�oI���YFĬ�H2��(@�� �5��[?����}(�Dj�8Y0�N�^q���N��&�e�,��N�����RRΛ��_���lF��U>�ql�3k�� {`\�<W�۔H��v1�c%h� �������SpE9��"�v�*rb��![����^<<�pk�1��'�?j�X���ŕ��|��F'D~	yg9�R�^�*f|���鄧�=
x�b��I!u)�S�V�r$� @����]�n�:"_B>��2FXv����ON	%����J�?u)��5�N��Y �M��ݷ�����~���D-���2(�N�~'���t��[)�d[)!a������$��)����ו�}p��.^ɕ���$�]	��lT��"	F�ɿ�t�$g�8f#t@:ÖF������d|�n��fv@���۳W���&0��L��ӣ�$Ru˛z��?����q�Z�5<�]��u�v��|/�D�zیQIos!���P<�\Ͷ�4ci��v���#�.���/l!�k!��ڬӇ�cY��md�C��5�~$1Ohpg��`_i����-��(��h�z��ґ4�#�	�J�,˂*鴺L~O�^r�5�:���*i�H�M%%�7~D��q>ʉ���Y'��n���� U�>��[�O�9����:ӵFMѕG���eEP�L�< ��7�r��xJْJ��X�
`J�w�p5��dAs���x�;ȼt&�!=��	=���x��X���D��Z\��S�i�
Yӣ�
3�����d��g"�N�t�ͤ��7��a�7��.UU��S��u�R��2�z[''��p�::���ux����k4b�~���<�GR�T���F�R��]�2=6�n�Gb���##��f��.�sR�^��(�"�q߰�w�� ������䣗�#WL�5L������z�!I��d(���?�l�oBP��7G$�ü��\�(�۷5C���=[U��W�$*NVƙ�I������)�d�a�}�R�����[�-Ր���C����c�$(��2�P5]���؉J��VO���[����l�.�?��o䙣��u�����3d-S"U�G��~ /ͮ���K�Ē��H=��AY�'�˗��[IR�G9?�5<½��搪� C<��9h�>�ii#-g-[�T}���؁�&��	���t*=�A��E���C�6��'���rŚ�y��b\
bp[:V�mM�?Pt�>D	�dgLo]��1)i�c�ȃa�1ه��Tu W���I �wb+@��Z.e��=���	I��_Cc+�3r.,0l�̜#D��k�b��țʨI������u���,�^�a�$�P�v�Z�b�3�z-�QFC4�:J-˝`��)ß �6�zFPy����qD�yw`b]2[Hy;�7O�2��VW2Q����4*7�����B�������i�xc���76�X��9�I�yP�r�-�!���{#l��
e�ų>�V�D_'�w�rpA�$k�$�Tfw�߀[�B���w>��@^�&j��d5� ݝ�5 F#�E����s�[��%����S��Fn+��C�!z}�f_B>���6�WD{�C�}w\B(���?�6�_�V�.�.�GZ�ߟq����O��0^`���Z�^75��LoъB���� \Z�&-y��E$E����x�Sn��fe���d��R�c�G�%/_��`��*����p����$Ù�-Ն�o�b'�U��I�2��%yx7�����nfz}A���j�E4W�Pv	͚�u/�բ�-L�����7YT
ܣe�֐؍�KB��q1��l�To�sqCC�Qz��TIKA~��O�ci���!Z]�<�l>�,>T%�Hvym�F��l!�5Pt�9lJ�Ǆq���@�<�j�Pv֊�l��9LVy!:�9*�ΒQγ�L��``�:L��-c��s�jt�v��0���6x����f�ѲI25UU���>DB}�Ŋ�G�#*����a��=��S:/KF6ϸ�ʛ��C7�������N�SP[O��:��`OOs��qٲӉEfJ2��̏q����^�#��;S�.s�3�ҍ�������B7~���pB~2�H����m��GF�蹂�ʹ�\��u4����d�/%���P��{�d��1�k��=� /�i:H�Mm\���8��ą�뢃�Sɲ�f^���ɿi�(kXH�����
7��cAGY�,xy�5�#�W�}r �oV�t�(����I�2��O4�k\��P�ij��T��}4�loM�)�[A=-�p����\��(i�3ͨK��>{�[��H��ݾF�o�J���P�*�9�:�~���l_�g��e�13p4-j�D��s�Fb%�6H��`L��0z0�c�:�؍WcH���28U��\��*q�5Й;J-Ɩ�'�_�^~ȶ��;*R�Z�jx"\n�P�d��_�oї��j[ ��]��W������îx�+-c�F�qԁl���µO�ra��h%�J�z��z��U�އT��9�QF��B:w�jM��X%�Z�|a�Q�e�Q �rpxo[�b�,NP��:�rp���������Z���i1o��;��</�y��� 1���ƬN������u��s���_Nx���9��]�=#��0���� ��Ѝ��)]�(���d̢��d����W5�}lQ�����1q�J��X
l!�B��yӴ.!W���~#��9�H���-O���O�w�����n��.1� �{�P��{���C�����q�bc���� �I�&�?�D�l�u;�O!;7DH"K.7�m����(K�7JY�8i���]:�mM
������*����g}V�Ia/ZY1�X|�?"\�u�eo�����8�������'q�"����hT�r�~�,&�i��i�u�%f�
�u�>ߞJ�x��5T��{�m�U��b�M#���C��:C�#9�(<C��K��,s�K��.U�z�O�Gs�#ӕ�{�(����fa$��^����|��>iޤ]G�m��hlpb{i�o-hN�-��!�aA*��h�0w���њ���V����1&�b;���dq.���������>�K�R]r;���<�pO�)�6��S��c��
���F��W��}2�_�Y�s�U\�� u�$� �7սO.	�dl��=�V1.@��OKCN�-�6OBb�}����%*���Q'upw�
�^� �)��<��B/<w�%v���rU1���[G�W�c,]}�ayPc�4�Z��b}��UPNG� ۟�BS����<W��`:�7r��X&�5RU �P�x�*d�옗X;��3���UnF�V$hU^	���2��*��j�����ajN�g�el��	����)8��K�z�'�ё�(��h�
�o����/��H�*��'���< �Q�0j�x�?�����jc���<?�._��W$�C���㫛�ꗍ=k�4�.�ʣda�l���(:a0`�r�b��u�%�Yd�wXA�H�]���r�-?m�(��a�[F��U�8�\��q�t�4��ly�>A�r3�c)E��8u��*�����Y���W/�]iTYT��l
�����x�n���"�*
	'�����g @�[~��6������ꐶr�')���y:����M��MB���T��%������Z�<���M�3���\Ӂ�2�,q��*t�ӣ:���FY�r����ɗ �>�%�Q ?�Z�E���2:0 MV�,��3h�
JZR=��GGl
ʀ���/�Bў����dUv�	�NЋN~���9����z�a�LW�Y&���=�'q���_�,|V�m����:3���f�W����LcNg��)���G��t�~�#�h������-���r���8����|�U��%΄|���4ɑH
�������?�m��yK�@Y	�ϪG<�j^��Fy�����ͣ�Bȗw���^VJ�M���^K�<�.�Q���vo�yQݜ�[�(S���f�Es�\q�`��ͨ�"��R��^�@�ufO� ^����h؆_h��8����,в�!��i�1�����G�=p�����Q��lg����.'�t��90��l �"afd�S[p̫�8!y�9�ƮzȔi1f�����D�3��Gy��r�~c\R:�(r�o��z0k�������ѹ���p���^��Ъ4GkTP],�Z��8f6q�{�R��=L�O����Ȇy|��m�Iu���83T�T��q0�[u�����"p��� ��M o���#���	Zm'.���z{)'EZ��"ϒ�(�XQmՐoti�M6��en�qw��<pX�	pC��Hf_��K�X��>��\8rŉ��p�R���ʔ����|.d��:���d�=1���ax����#��6EPڂi7VX�dj�;Go��¨�g��z9$���H �Y?	�g�U��G�56Y���Nl������^�`�x��2cj��1�٤5ō�;g�������b���6�g57�Ll�y_Y�м�gC��nE}"xFR /f���] ���h��%n)d��)5x��Aͪ\�h����%�|�	����??n�:%Zc�{�ν}7�7|&�4��c+vMRi�bk
�~T���٪ɜ�����r��_4"���PY[k���$��,(�j�X��$:^��<��.�Kaǚ�i�&�*"�1�߫�2eʔ�&R:ґK�hO䑡ԝ}�����nܔt��*�B��j�K_��܋0k�T>'h�s�΅�qr�0�I�?�؀���uL�chJ" ,DI�p6�/0#�������~0%#��������j�U�R�"OcyT���E,.yڌ�i�;F����ccE.�I���.t�2�&6xMHUWg[�.z$��L��D�x����X�j�"�%Fh�S�)m`̋��.�FH6�1u" \�+,��&�XhЇ�F�|��&�2�H;�T$���@�`4'0��|�r1o�٬�Usأ��Y4��!�������=-�� ����Ա"��v;��M�.��.Ld��߁��K{��I������L�����2�����]�Z�.��.�̷�4��$�S�FY��	���a��8���o>��i?�kV��2O8��t����5�d��U�[��C���5 �H:z��#k힭wז�)묗$W��C��J����p�{%�{.��,�e�'��O�B8\�Q�}� 8�E5m:�4�9<��ԋ1e���F�����C*x��9�O�]"0�ϒ#���w��}'E�)�^�+�� ��4DF���#s��k�C^:��}��Ha�'�M��tU�{,B�!��f�:�K�;�Im"$�Cz�H�*��Ҧ�I+���j��˶�k�>�����@-���K�h�h�U�cS�-�=��1r8����wl�"d~B]��y����?���d�Ĉ%v��������\5$�c3S�t���B�������6d�t��H��U�=�m�9�NĪڪg���������lۨT�f�
���|>��CW�h)��p�ǁ��^��M��%���[�]w{�-�Y�j��c����W;��RG�>�[���N���π��ź��b&33yK݄*:�k��5Pl7A+4.�5Ev=;؎F�R{�Qy�B�~t�;�[V]��� )5s�{0�[��&��8ڦ����= 7�LƲ�κ��C�}��2�(�K��p�wA�1<�Z8wEnW�i���D�����"'i�A��}�LtwƾVE��n�i�9a#���p[�w N�үj;3Fͽ،�K�\%g\���9�/������� �̶��O,��Y1�1X~C�%��S�%�T�����(y:5�SY���#Ɨ���Сٴ�9�O��
(�@bE��Y ������O�g�)҃+?��dtXc��~<�U�\����L�6�ɽrdս����v|�;l��JY�G��:-&lo�fx�Ѡ��T�p29��GЉX�"f��NiR��#��ot	l�E7& ��Jᝳ��;V!e�5��V2�4�E7"
�L�/��J�<��8V�_�۾�-o
�^��0a��\Y���M�ls� 2m�V=�ӫD}s,8<�Ύ:��@H;z��Q&��`1�o#b�Q�[>'�pS��_p�뫹ٰ�e��{ �6Bw��w����	��-'����~����	5YP`3�h%��Ƶ{�"CM�./�V=��k,���kk��;�I��?�A�n�4��I�W>��`�@�U!�"�\�~S���M�Vv���	w�R}�0�?%L6CQ�%5���v߄�#nl @ćZCan�ci;���&�8����z���4���<z0�/�t���c�9hZ�>�*mGTq<����&X�zz�w����y�TһM���c�S�1)�+8JV3|M���q��>lT��z�������d�r,�.�;�%";'��n$��YO}�}8s�R�;��E+���Z\(��h��GM
2�����t�Tv��q�Og�b ����C�
�Z�����vh�IA������UY�t�3���z��}��,�XC�V���*�Ms	��LJ���v#���g��&���;���/�{ � �A��)�t��H_�Q?�<�nF� (��6k��ByJX��[hQ!��^�g�i!�lЬ��
#��nV��j1<�'�큥���A���*�����|	l�_&�8]�U��w�������e���Vp�d_���y��5�'�  ,�c���A���/$�⹪�WKpV��g��n��� �����������6v�����@�W�9�R3��ˆ���P ��h
�i����~��A���$y�:�U[i0#��3WEc��g�������B����R��y�x�S��2�Iֳ�!2��ʻĠ�������=�Rxۄ�!G��~���ƴ�.I>��Kj�K�@��n��͛@��y��!�a���zA��7C���>(�!�X��(���C¯麟�Bj�.b��E%(�of1���X� �q�lF��p�z��	���%��
.pv�����VE�$4��W��I�*t��ԍ���,9�k/�0�7���D�e��,1J�iYP�L��1��<��3�|�ߕ��A'�g�������dm���繭?iP���E�AT2����\��VM��2�Y�JC�G�$7+X��
�5�g��6�,9YξG�8�K��Bo��B��t�8O��r3װ��wb�K|�3R.��b����Z(;��cfδaEi%zC���&�/�5;�H���O{�<��J_y|U?���*;�br��xI�<N�������=����"3؞���GgЩ�t�!$�)��um��m�*փ��v��ǅ5L��g�T�'Jlo��̃�|�C]U�:���}�{ٖ���}Ǳx���˂UT��@,�0���KO��t�D
�Α�9����/����V���0���J�J���QfF��m���$�2�t����v�iB���rZ��Z\�-]l}*�&(�{ԥ`a�i�h���W>����˔y��i�E䅨'�8V��I�Lm�9@wK�����xwA�E�-]8ES-A�Ԙ�f@b#hc�ܐ�ד@WE�h�Mـ�5�%�2ab;�L����3ޕ���!���3��ɪ�M�}Rui��.���[��~5�:�L��Y��&O#��-4�8�7a�f��HF�\������p<�KO��OS���0���#P�g��m���\	��wȾ%J2o:i��04*]���é;U�e�a���+�@�C忬A��û�&+jC�S��S(晇�_�n�<7���f�#����&=UP�$��A������D�EV���r��o$�Z<'v`?�-�&��h� ��\��5����Q,���[x`"�x����������ְ�����W"����S�@>�d��6�RB�O�&��v��}�R����;$��XBB�Gtv Kzr�rv��J���Q�##�*���7��x��/�؛L6_�ـ�A5tX���9o�����(�J��-�j��潙���_�6I�����^Q��,��=��N�1"�u�	����<I�a�lNI�W�����O��Zz�:ʴ�f9u9�N�sta�Kr须ǐr�х�.�f�s�	��q�f�NJS�:�u:�<��2�rM���f��w��Ք�Ijy<b��(N_�=(/S���#<:���3��t�!�k�������Y��552�?�a��NWx��f�R���3/� ��6��{+˶�xP�y0���L�6yS�������:�A˜�"\wy8���\y���͋�щ#:#r�R�i�I�@aj��	r��ώZ��%����O�l	 r�'�!6 ���^(0���%��lM�[v�UlҐZJ��~u�F*�ȵ�xBǋ�V8�9�)EXځ��+� Р����=׽~fP�+��ʉ��2AEMj�{<��)4	��/%B�bp2��A��_KJ���5��E啉e1/ɸ��$��L�"w��L���g$�Y�}l:;)�&8��ueg&�u?�L�I�������~�q(��9BjP�Yl�N��t�uCyIk��>��b����5'=`R�/u`W���c��5�l���e����L�ɰ�3yJ��O7u!�X2�YLI��,����'�&eLm|/(�FK=�U;�F��J4�]>V��ݼ���mͺ����j���857���p(�3L�ed�j�ْWl������!��ߤU������d�zL��E@�C�b�ّ��Ia���3~cfW�ѹ���aߎ�M��1���x�ۙ#g4Z\n]?�0J�Ӵj�-���7���)�"wm�oX>�fL]gVdh�ؚ��?�גy%D^�r���"���iԡrUDRϵy������ ����*qӼz쮿r{�K1��ڊ������`�+@�!E��rB8z���[�>P��Tj���a��=`�(xhN��4��*L}����[��Vj��y5���O����c��4�����2̌����c��N�	E��|oDn���Ì�v��)ץ���Y�����Q@+#�e56.���[�T��}!������e��[��CVV��c�EE��`��+Y�;�NN����gptG�j��D��Z��n2Ar�,�'-�P��YL�ځ����D�����>�V���@�KM�M�h��u RR�l4 �^�&�OS��q����Bb߅�
�p<�J���k�W��rk���'��v�^R w̟u'��H~L0�\����f�e1;M)U���qw1��*	�D[.���h�K3��X�������N��ȓ�<��f��>��2��+ɭ�e��Y����_F��R��0u�)s�6��^_S�5�v)+���Hgr�8[qպm�����]�X3�5�2C�A���m*F���`�������D윬 �.ųz�C3���9~�q�dC~������c=i�WKs�e�q����
��Mv���.�Ýw�qXM�Ȝ�u<�-z�Y �yu�QX<�Ԑ�	y�y;6�� �Y��s/�����ò >6�
�ka}���)ok���9�տK�4c�h�(ǥ�i�k���i�r�U���2��ΒL�s��M�4��OH7���V��"�U�ᶸ[�Yw�Z<s9��YC^������y�J���^+���C����TsrRڌ��CPHJ�X� R�{|�Đ���^�f�� ���ܓ$r-BkG�͙-,�/1:��+���ȗ�E�z�GO^8>
Ϊ��Hk,����I����������iM��]�g3
�.�;g!���%�2�d���^E����xQ�)F���r��GrX�M1�r�EzEʾ�9%��G���yQ�w�I,R0<*�K�&��/b�<U��{(�ߊ�r^q� �c.��(6�u��/:�LW��(L����Gx��Q�ڈ�G˖^$g�!ȷ-e£�e^'�d�(�\i�)��s�ܾ��k�����0 I��2���F��Շ)켪�9�ڪP\J��h'�J]�g��t�:��"���)5U�}����ޜY���%���R�8i^鼢8�?��fx�6˝J]�iB
uA	�E�Ǳ)�`0���7�m�5��JqH�T��C�Mz(Ҧ�>T0����;���\����{�+���	�Aqd��B:�����d�j����5�7�t�xg��Es��?L��/�=�l����-˖A.��3|c��|�O�������*�>]� ��-��H�EӐ�u҈�e1G��J����!�/3��� �z�z���Q�M��M�t�&H�8��Nʎ?�!�Q���2��.�g~�
�Xi;[D���G��?[����/�В@�� ݠ7�o^�gb-fc)�Xo�=v=;˧G������r�
{�Aʁ��zS�.G�*upP�7��Ԁ�����G�@�k�ᇅ�[�r�����z�R�	���@��a�A�� u(�V��P8F!��X���:�=�g�u�[�A�7=gk���ʔ��������𳈔S�,N1I�UlCѧ(�&܉i���w\��j�U̍h�CI��S���B Z��q���jtd�kjZ+	Rx����e��J�aL�.�v8>��x1���"��f w�5�b
G��̚�\L�1�:��3�轅�����zܾ+d�.*X�%no����.��v@��\Ⴢ��ʵW�sle.�-A23P����!q��xr��{����VD���u����C@X���5����b<$8'%�������=�гd ��&T�%���솂�ڔpҋ��X�U���MǔҺX�`^�����#~叆-SmŽ�5?�>*3s���͌q��5+��X7�Z;��t�q �j�W��@���\�j��6�+>b�܃�2��-�K�yE�J��,J����\�	�]���q
�D0��t�>�z�K\b�i�z�}�^E\9;?�Vf��?9��9L�b��E�3hUx�V[*l�w�8ln�#N8+S�THWG(�T�����`	{K�CN��r�]D�q��$��xu̟��'6<�#��>�N���WPR�,�K�+���;`=<U�;��U ��.���+)K6��DO�g�p���h�zG�� .��� qȧ�������¯"��g@�͇?%E�L�A� �Vҕy����[)»���ٳ�7��/�~�b],��E ���(�����w(��o�<���w�ч��T���ֵ��Z?��J�;�"�zo)�@
+��{诱�/��8�fT_"���,�;ƝQ���L����]	���v�o[��"��R�*��Lr�*�G Z9�9��f ?|��B��2J�S������4�E�sj̀����Md������8�+�MG�o|�;α����X6�*�0��bܞ���24U��C	aMsYXE��J�����l%��i��h�ӌ�hӌ#ä�hA$�*Q;����/�^K��xK8���.j�+!0�.����ӇT�Frq��Y��{ݴ����W�ml�^�+�ŪN���ww�n�xu���x��Im�-�b)�_lm��[ݬ[�ڂHb���m~�7w"`�4�0j�ae��	l/�TY�٦3��l��1=��E��b���zʺ���Y�(N|�b>���
GX�>��a�����pJ2�>�4�M�=�F��6ΑWF�}�`��5�U�����f-0KS�^n������<�Pu�$�ҫ�6�U���;M]��w��/��$gQ!���X�wdE�2J}����M�C)v��B���z�c���[�4�޿���lY�l.�^���7����V �3�ڣ^�Y�w��3�}����'$�I��9�.|��������������s���37��Ҋʳ�p/ǻŕD'S*"T�f�:06��6�%B��=K��Gh�|[�L+a#�D?�`�nB�3̕ʡo9ƈj���f˴_eܧ�11�����u �r�ӼȨ,L���F/��A<Eֱ����A#��+��еy����.a>��ϖ��ܘw_C���2�nM�6���d��F���g^ȩv:��	�<qq��L�'l�+�ZH=�G��I� T5�4;����E-]�Zհޙf'pB���R�ή�Y8�J�h?An'�����"�?T#ö(���V���crA~�����_�g�s�QC�D& Q��6��YLA־�4;�Gu�=�R��{;}H�A�26�	�`:b���@L:ؠ�=c�7��Ƒ˨2���S�g �F���T�33G9�� �COQ��������ߚ�ٲ��B��>���Ǻʹ A����g�������a!J�cJ�3[���P�k�<ѳctX_Y��퍞���|c�%O`_."����Up����<G@�9��W���"�>�o5�]����@v��8&����&K���rl��T�֬n��Ϫ
�m��� o�[��A)$�7ʏ���g�X/����o��I��ԘL���� H,'��'iu���+#��?����C��I};�r��\-�|٭:�+�����7��abU9���ȇ�����*n�w
UL%t #��
I�: �'1ۙ��h78M��r+�־�Έ|Pw��4��i�vJɈ`�/3�D���a�
�����2�3�.�$��CS����dC�K 5�`�R�Q�R�^\p�A��:�F�t�^��Ñ�3(��p����V�|��9t^����K����%b.�v��yp��9�l�T�t���M<��ɪ�751CZs<FKTĖh��`�B}��PyV*x9�Ze'������kmc��>oz\�&x�qMI��.�z��8cfT�X�����/\�؟��֊�8ߧS��qe�[�
�6Ӥ ~���]��]a��^k,K�1YH/�Ǿ��h�%M<'�%H��䒁V����a�-�4��^L�|IG��b��Fm���ٔ�����{��]�!0�
�gy>_�<;QG��j��р�{���� �ft��q*�[��">�!1��܀2��J�z�pI��;�{�MNN̶xR#u�n)c/K��Ze�uR���ę�ō&��&�)װ��������qNu<G�=P�f��@r���W��$�d:���^[ R����HX����ƆI>��o`K��;]���J�⥵ �JX�v���2�.b��[�fª`��S_O���=v���+�8�¼�0��b���5l_8L�p����rDAf��!q��HM]��e�����ō��sn�ܽj 0ʶ�ß����NV�=�?x����<]Ӌ�<�-�~��6օ'����Fc��_��,��6�诔�Uð��ΦA��ކi� ���H��J�kzJ���ғU��'�F`��$sp7P��+���x?~�y?�<j��� ����膾wX���!�k��TӤ��`hI�aK�X|��PX|� Z6�m�P'�/�{R�M[]}��z��%�$����*+|��
�H>3䡾Td�ߗlB��a�jA�+):�E��w�H_�&�(�n�&P���i2/ӌ3J1� ӑ���o��J��ץ���ƻS�#Z�/���3M����b���n��y;��9�DY/sE��"+����_t��Qe!������7�T֦c��]98�*kr�S<���!�9݆{�^6�a��W��L:^��O,KY
0���Ry�Ր��~(�gC���G�9��y��Mi��jG�2���A�0������j?~��H�M�)��_=��rlAv��5J��	�4z6���=���"����Kg�r,5�D���-�]��D������T�Ɵ�`m��S���R�{������M��5�k�����$����XW��&|yRC�0@�A!����
�f�S��8k���Qu��q_���"��4���r�Jux�����,S�\u]�/~�N��B���*��I��j�<���p��D5F^Rd�4QQ����˟o<]����r����$r�X
��c����o�j�mu���x��H�����X�[�nV�T�S7�����PԴ)K�N����eʒp�.i����5�B)*�'P���F�'M�L��h擛�{��,ȩ��Ԗ=���_����Xn ���^Bg��i�& @�BH�oY)RЇW��\ny��;c;`"��lO��C�6��)a�����t�:�,z[Q��J�N���!�΂��2�r��h��0�Xq��O�h�&��DwwΆ��ҮMnӫZ��vf�`7�	��4�|�t@u7g���=D4fDF}�\�ݱ��#�h�|`�18x�?�F�����Y:���P� �W�_�E3�a��:���d��`]�G'��D�y��\�xP�[�I��{�dQ�($�A�=f��A��*���:��$��s���
�l���G����S M`,�;Z��L��]��Ps/�c���Bm���nJ��g��������x�\lmŮ�L�0�E�� ������'������k����~|���7�����m�Ca��kT��"���cRc���;ߙ�?~hΓ�TY���f��`�;�u�l1u�DiP�,�N�P�Z��e�v��g��2�H�mHv�7~kʙDs����0�o0f�؀y��=�P@@�����G,�hFvc�j�q�_{��u�����ip?P'�(*B1^�Wޔ8���l��HMP.��
�-y3=��)7�������5#�ҩ2OKڷ�V�k	�.ϏEu�V0�R6��1��}��3J���l(1�ǲ��&�2<�vٶ k�$5���Gry���p����1�R�D�����!�Ⱦ^��tU��L���*��-���*��Q�@�`�U�?�kE�~
2k���J��/B���㻪m���>),;N3"�v�|A���@JE�R����W�(�3L~t�2�K<5?T��˛�Q�������6�`V�?@n����`J��M��2(��	�j(�}�r��\� �/!�3���wm�2wzP��⸧��sb�@�}k=���ϊ,}m�?(��	[�<41�������ZDYU��ȉM#��d{��lh�M���V�K�9�D�N��;ڽX�_8F���N��,D�kD���Xr�^�&g��hV�݆/U���L�h������DP�_�����hC�ٓi���;�DF���12��HR�etC��
�D�8M�#��!�������a�2��I����IIq��$1}#���o�A�f�x�����,��`�k~��(����f��Y2v:_&�7��^!j�����"wy�~u-�0�r�QH&ج��wu����Kպh.�	�vO	�@L9�����RHnT���p9H���kQ��k�Ph��c���|�[kf���hG&�ͱ�gk�W��{1u��8��t�&c��0������.l��_�C��M����P��e "�ŋT*�ˀ6�?v�^���2+[�̙�����ti����3�ΰ���ww[;s�erF�1��X[m�/b�������v�"�u�J�TU����n�&ƀ�D �$���E�1���F�kw��H��B�J���Q��rg2]Q��M�O�4���Oz� ��Zf6N�ȿ�#��ӳ�Tmݣ�1�r���;���}aF���Q`� �.S�J����q]O�X[��F49)rA'Xkx��99�5��/�����V7:rK�N��.����|�� G�H_�s�zYqf��VYAcoY�.ȷ�Ͳ*i��=�s*����*t&�)���F�j�~X/$��諜p�7��x*�&|,ka��8��Q���(DĺޖoD��5R��釃�����X��T�rr~��t��D��!�A��w�(]	q�c�*#ډb��l����8B|�	 � 
c+Wi_�dN8:@���v?��]{E���]MޚF��V��<�,mp9�48x�]FuX��x;D��j��o����ﯚ���׆�0>8��~2���m�p`4@��A�>���׿7-�%b6�Q�~�}V��f�"��W�$x����oE�6����A�t��#� &s�~S�
���r��#,\�O����ڄ$���o�~Oc�����.��;�Ow��:��kK�A��zC������j0�:���5h.:�U�.㵙���}����f�@��7�c#:��4�#�e�I��N��=�^�&?E���&m�/� ��%�iKQ�hr�-�&(�SN���J\�o/>��
[�|H����AT-{����%k�
���h�u�� @���GN%������-���.0���WĒg�b��*��_S��'b/�_�H�_�Z������~�;K�R�o����)+U��PlX��`� $_q�"�:JGڨ�M߶�L�^��P��Y
N-0j�O3$u Lx��>���t�C9�d���mg���O�K�gP�	@����;�%��E�j�����Q�4<B�W����,B�Z�Ћ:"�ʼ)�`j@�J2d~�&Y���ﱍ��MG��S��G�>�⠷!�L4}
 g=dv�;\�����F�tP��D0t6!��.o�R4*EJ�c���O�M8�8:MV�*>�9�gSY��R���8ѡ�:��{$=��O�֟&Ni�Z%q��n\����p��#�!\Fp���89뾖m�E�N*�O�;S�o��%5����� Iy��H.P=���ċZWI|#L\ړ��@q�m�j�eZT��ō�`�h�p)�v�2�t�~ �E@����b�08��-4��h1�Q|��<�O�S�fp����#�$v�uOW(u.��B@�p��13��i��Q������@�֏I(��' paI[0�n�(8�n;�7�W�of?yM-X��� N��W����T��\ �B�W�˫|u�,��t���p�!$���O�T�ߴ���1�#P�l�?1��币$K�F�<��)��o��J�)4������6�N��   6�6�!<�� �����[<ױ�g�    YZ