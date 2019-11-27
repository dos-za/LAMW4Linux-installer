#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1031008222"
MD5="dce73a9ee52df183678bf86c87b93d1a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21134"
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
	echo Date of packaging: Tue Nov 26 22:00:14 -03 2019
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
� ���]�<�v�8�y�M���tS�/q��f�*��}�V���$9:�Ɍ)�C���Ͽ�ه������V��e;�Nfv6z�D�P(��u��g�4����S��x��!'�G[Ow�mm?���y��hln=}D�>����f@�#�t��;����?���9��Mל��_"�m{A��;�[�H��?����>�]}l�s��}�OU�����̶L��)�h`:~���G�1�<n:s[h��T[^0�K��JZ�܏�K��DD��K����R݇�d��o<�7?Be���C��S��ڮ��B�MI�/����y�
��@u2<0���20}�d�D�1܆4�Ur��\�"�T������g�F#yl��Z{�&����a�9����ɂ�"x��oj�~6h�zG���V6W�t��Q�ug�5�`��������^�(j4� �T)Potz�u�� �*���!ȭ�{��׊kQɻ=���T���a0���
�ZcU�M��ۜ�|rK����fq-7��p��V�2 �h&�|�;�\4
��C��<����(S�iH����P�x��(��Wz8��<t}�S����� {��[��uN'0�@�}��,�<2��1G� g�6�v�@�L̐�4����|�W2�/�ſ���nх�F�S]��� �D���ʲ�m(A���1g�O���^��NGSh�o� 
?l�2j� �ɹ:���&���D-����t�����\��t=E�ߒ*�ρ�$�,xȈ������0�te�yAT�|���h�̩u�ϗ-�p��,��l���7Ѯ�t�~��m���zlѩ9� �L¼S���O-1�ړԨd���i�=ϱ���P��v���/���.�~g�;n�j���u�l�����-�M>�>�UR�y�"{�2�e��@�%��I�^W�jZ)�_%�"r'���~\1_i��h#\%W�R�4!Q��L
�J��殰���7���M�M)U����ah�}��S�d�+�+t�O�NM�9���3���(H9ᆬTd���r�(j�`ɣ����?D��vgd ypH�zx~��g{{��os�Y!��z���k��%>/�K�I�9���T6Hׇ�����d�W���#q�ȇ~��.�k��J~k)D�9:��:I�K�����:@8��ܿg�����]����W�����W�d��3 ��6�o�ں'�a3�_I�{z�9<����:�%�H/"s��H������<��'cx6]�IB���g�S�$��0>nL�㱰�/,��}3`"���bIx�׃�U��8�'�&F[Ա�6���&�׹yAu��f��4���@�5���Nw�y�lWדau�ӿLQA�����V��+G�_���xF{n&L`��2�L"�ӡ��:y����{��uM�{�8��ꕿ���%���������������8��uv����R��|�5���b�C��ZU�/*�� rI��sC�>�#�lķȿ2�.x�AHQl�"4�'�gD'�f��bg[#M�
<��B�]�Z4��Є%��<byd�O�m�i���H�E��hbYn���m.lʋ��|lc�K�	�A��u�Rq�	��f�h
0j��J��XD�.ױ<̰����ya��z6��0"?��' �V0��9r��(� #'d�캷Ǉ�ntEN �"?>|$e�DI����ت7�<����j�IF�n}P�� �q�^0�&�����u( m���*a,����Q�9|a�z�ݱ�8�CU%���a�<��V�LgE���q�9h��l���/�Ad�5i��qQl��\�~В��\�bwz�,�ꇝX������hi]i����4��6s�E˰��)�W�sS T�~Hp1��m�{�{f��	�;��.��! ќ �����:���sW��hAn����8.��݋_��z�ԐK����b�0U�6�W�]	���K�u���=9Gn�/�T4�z\)Wk�A*1��.���c.rT[5���z�2�_�*���	<�qU��.�����2� �
Y�n�?;="�#�(,��XˁdC۬7�1�5-��n�ھ}�=�͡��bb�?wz���q�����E����������X �!a�<6o�s,��.˪�X�����.U���S��Y^�m	6<ڈ���Z@DU���n�)Orj�+@B���^PY=
��Z��x�2�	OW�����<���)���hvn��P!-R)yw���2��W<�4XN�?��2i��F�f��=4L�����P5q��c�ti�ȨH��`���ϚDkM_�^n�$Q�^�}�ym�d*�U�ܘ�(�qܒ�H%�� �c���j�J^���!z�����$!~���%j�'t%���O�vx�,;O�F.ހb�^toL�E�A��� �2I��l>���n��y|��lH�b�T���W�c�Z����Z`��~�ZLWBU��e�_���+�/��rn�z �
6�t4*I�e[h���R{x�#+�$�؁��/���u�8X��2��R���3�OE���x����b)�Z�P�e���	˥�ǉI�Gt��ɉ�͋���F�Ä�C"D4��"l��a�[<��p�ύ-�@��B�=��T����&]u98n���4����ng�Q�΃�S8�$e�͖��DZx�j����?��\��%7BR�rі�V��#	��z�n\�(�IϜ\�3*"�~��yv<�o���Q�a�]�^�K/IHj70xS�}�n?z���2���*��}��_3b�&ӨeC(����w��w���Ow_��?��α�������$� ���%��zp�2�s�=v(��r�xЛ�ب��$��e%��V�n�8~;���9�I(ո�e�tA����(8���G؟�o0�%!a�$'��L4?�c���3�ң�Z�I>�E�i%`����UPz@}���m�G9�e� !����Ǖ�!*��`8��	j��zg]pn��N���������}bj�����9�ol�%u-/���^�O�����碌�6����<��g=C��hxշ�!���RQ����s��Y��-��Λ�F�^�E@�2fO��X�[�Ҧ�%�Zp���!�=��,%%we%UY��ʈ���W߈f�r�7�scu�R��Q��IEؒX$2�	�|d��q�x��G`i�c�I�v`�$�Un��Ԣ)ݢ$��>E<�������zd,Mj�m-�>pj���u������3=��j`���u��$h���ԙ���������~G/'j�����P��nQe��b�ʚv�E���� �[@-g4\����O�Κ�]�@-�^W��^PE�BR����D��*�m��v���E�ܜIJ���o���S��m&=��=���Ȏ(�Ą+,��~h�`����ٱ%���p-$�q�jJB�JT�:���XW���
��c��<~܅���%>6,znLJ��"/6�V̌Fh��3֒(������a����A�ր_|^9�_"��1��D�΀DJ<����x��H�@Y��Z�Y�J��R�wY
K�Җd������>?y[%��H�Q�� ��L�J9��H�4d�r$��(��L:-u(k���(�;�p'_�$��2�Ja��B�(��L�5�V_�����)��H��d��Q�����]$f �{���+.F�v#�4�ͤ?b��U�д�&^D���1�cX�YWD%�{�Ҡ�8i�'�F=׹��ok�!Ѿj�+&�#̥>Q���������8d�=ҒK�73���Xmg?f0<���?�KϏ��'���T�S�8s�L�����zS;/�ײ��)*��<*������1���	��8a#�d�xw�K(ا<~l�=���MUbΛ'�n���[r��4H�d0�ݭ�`�FI	w��D�/��+���Z�������]��#�co��R��xkC��>�T��(w��AL�M(M9�P\�v��.�ye���D�Soe��r-�A���m�O.�������}�� ngpq=�@����.ČI�i���[���Cs����]�Q+4��O�ي��cL���S�a�{<Ƞ��8��tF*=�N�2HMj�C�#$��N#�(V����������
Ir���%����:t`F�
U8HS�ba>��5���Xk���U8�;���n���!|���u��/љ)�%e���]�[Y��
����ϋԇ�;�߳���W�S���޺��[��<7��d���䜺���C���wmŒ��D7}�I�{H�����
r�G�7���A�rN����c�ر���K9�X�R<��T�E}���]<Z̛��e���;s�o�E3i��#���E=5���D���ޞ�Qm_�I���P��44xnך�Qi|cR����,��5\ƶ�ԙ`����D�z݆.Ƴ� b#/����|ܐs�5cj����k��Ln1Z�)3�;Rpf�[���sy���h����g��=��qM���嘌�}��d��*ԯ4q�p�?��z�A�5�O��l+�� 6�[Z�H�Ti#�7.�=Ϣ0�c^�U�k�53Dmy�'ց:(�!`�	����v�>�4�ww_kG�m�������n�e���A�)oxi:5��4��Zwk5|����=|M�Hl��V��akt�>=u��d�_jS��=���|wE��A�_��`��J<�o���?O- ���6E�>�����s������)�[jZ��:�f!�k�A�E�E�zƎ�Z�)E� ϵ6���p���Ѥ�e�$|v*\�P��;����~�X~$�(ҡ1������!z0mx����, ���(e���7�`��eM��O��@��m�c�8���tϱF�pk���du)be��E0�����ɑ�̢�,!*�jy�e� V�,a�{sa&�+3g�b�/�:vj��n�}�d�q��Vᾷ.4snANJ>n���Î����(UM�Bsn�F1Gڛ��=`z�'tL��`�{��
��$�M7(�� ��T�����:�z��m*����_?��R؟��uR%��x����?��ds�6���<��l��@��\��W�%�� �sr��(�^p��)�����˞Vc�t�J-f�O ����p���qo%)���G�Ih�1�kK�/��K9$uƹ�)��R�e�A�`���j�H]"�6���=q~`u��A�ښ��vx�i��F����p��-�p@Cc3�H��!��RGʛ�^|�b4����	�~���h��W���j��$��NI�P�Xt��im��Pu��)�=P<C!�L�wM�7��#�+ǵBgJ-�\<��ԙ��w�W��:6���[�LR-�~V��D-a�*�r7��%�\�jD��x�Q���˄I�M�r�RV"���*��M)f��(��յ�Q�S��l�j�~n�0����:����o�n�HҜW֯H0&� �.M
�DJf��C�vw�>8E�H��0(�����}����}�a����6.�Y�UY HӲw8G"P������Ȉ/.�%�C�Ws'E�m�W�A���;���OI��Ǩ�����?�_������7fĔZ��o�`���	G ��%��?�u�S�=JJ��\ΗzT
�Qb�	b���F��%��`M��,n��{T�S�n��+���z����Ϩ:����^��, g1ptr:W��h���J�_���3Ux�핍9;�%�����G��M��/�]�`ڻ�W8�<�����k9�`�Z�/�+gJ��iY]ݨT&t���2#��u{��S��T΍�[��%ݍ����X����r.Ѭ��gNm9�o7����6��M�e3�jS�Q::&,	匪ɂzԧ��V�?�A������NF*�zu�Z��l��=�њ�dK�b$ˑf2C�T^��e>�%7����E-Fr�g�N{�*"���_�k5��~��������0K���W��K�ލ./�_������F4��WX��V��`�����`��}?���(��Q�Ӂ�8�:J~�Gh/��K��5M��������:I7檇��QG��\{0a���1�@S�c\��;I@�C����G�w�eѱ0�>�����pX>�=㫬��!x�e�+���+��]�
*?�����ۏ$��7�r2�_d��^��V���~v�!��t'}�����"~B�a��?�C�G{t���>1r�(��}�~�I�C�b@R�ډ����O�W�%%�Mxu{DDrc�&��㹩���M?3a�$&�I�}�R���f����=�&#+�A|Y��>�����%��_lC��k�HP�Y9�k3#�����6G�%��tQ:����ݩݫ�+:�U6��s��wG^��j���/ݥ��Gaz���ȴB>gMz%�T��*i/u�c�Hw�TGW�/��6�pv��Y��öO���H���)a����|F��%�i���6��ڍT�/�6��̑F��6�uד3P)6������Br�5+y5|-mJU*��r�Q������1Ѿ�~��Z�IS�gH�f
��%�<����O�Ը�X '�y��	7���8i� =��v�i�e6S�������)����/-��������0�$l��@w��@hhB�H<~/Z��>>6��}���DsڱB�<ϧ.K���g|��J�,�>�h
����x]ɓ�����b2貵�膑YL���K������+��Hsٜ?X���:��M��o�//�0��2�q͑����97�{`?&�6]��F�(,a��`e�\27��{��4\`o)<AqbZ���4�����*vZ1K�I4:��u�V�������VqJ�˹X��/h/��?���j�w��L+R��iC�`���-�S��>[ξ(��I�V�C��jWx�-��|�-w�丿�ۑ����t��9�]�,�#�p4���a܍��F�{"��u>���Y�A���>B��+}��_�?J�eаI5G�u��#m�>V�:�l��N��� ��!�~]5MR��*v?O1��؃{��� Fs� 3S�)�˛v��,۫�O�hg�G'g��v�(�ܫ�^w�:H^�?�+V~if�n��S~��ljl�C�s���D����ܯ�l1�5h���>j��H�g�h@^#�e%��������쀗���iN��Ul�Q�j��1 �lU�ՆY�}^������%���{�ms

�R���Sy6I%j�����:!]��>?�>�KZ�ں6��[��DQ�z]}��l�K �+�ǫ˙�ȗ PT̲��(��$�Q��d�C���v<��K�|����2��t`�o�)�ucα��q?�ẗdp�DY�_U��\��:�ҩ_[[�"*�םY�IJ�K�o�*;2�KY!�������6C�Pnc�,3M��3�b�6F��7�����*k�ppm���/����GͯW�|8t�.,2M���m���W�˗<������u4�h�D�'	�����>ז�ձ���_{����Ԥq�R��_!�+_�%U�D�A�uYEkV��e��Fz��&�bZ�ei$�F��W�s��z�øx>�b�i`�]�#K����YU`�d؃��Z^Q��-��K`�0�g\�	Jw� a�Y��ɂ</���|�V��UA�,�����|U3�k�+�����]�zq�5!-`�-p���XX�)��p�1��Ta#����I������g�S�'��9��`�a�̙x�����5� QZ���_�b�T��ɟ�n#��b���Z�o�(���PE٪3�엌�W_ol�s�����Y�o�)��Z�n�9�߬0_��g���=6�G�� f���3_/�^:�O�����|�7��n������v�d��[\훸���SE��v�dg�Y^>��o�7��:d�������Z�w����k؈���������S���&W@��ǻ�U&%۰n��l_��>g�Y�Lx�}|��?z�ME'�v��Fw��
��^K�C�/&��~�	:�Cz�G`�$�UX���Ϡ�{�^��K����z����
�J�\�`�'�R�K|�9s�h�Od�mr`���=��QX�������@�р!ޠ�2�ө�8E5�M�-�xk�xt��֑X��J���8L�G���e#.��Pi�)WHs��r�D�U�x����u���&U&����Ӂ�Yi6QY"o�4����KG��x2�x$��O/�$E�F�(x�\><:�]v��&�_n����`����n0;�D��YiN�X�|;� ��F���P���+�k)�8���}	^
FW�`R]�o�$E"9@�4c(oٴ�%V��Jy�����e���c�
�._��$��P������\Yu1�W_e�h SQY�{���]GROU���Lh]i�|���k5�yՄ��)�O��Y��5K%���XJ�����+]��a�UI��0-��U�Q�!��I�x4��J;�ZW�>BT�H'�m̝ph�w&Yl��M�x��tw��}r��,U�e��J'�8���P��ؖ�L��N�:���#ơO��asx֛�L&m��+�!��[dRŉ��U
@��)��3:eЦ�~�n�%�R#g�N�2J��E-Ef���]�'�T��I����I�A����-z��9J�I)0Ж��M)��z:z��	�j��[����0�ҧ�1�o���S�3���4a-.��q������X��x
lY)c^y�)d6!3�Z��C�h�G��IW�8�DvG����Q"&�$b�{.�I���7��B�v�n^�7���3����T/U��86fJV��9I~���:[3�oL�ɯ\~$2�)Pο^�rY�H_�
U��v�i�r�l�y ����t�|p��&@�/=�-��RJG���N�RUo��?$�l���YW�Ɩ�u�/m�$4-,��9%ݍ��R�EU"�Dj�*���E��������	Sz��)�e�o����ۖZt7�Z�V��$�Ǌ@8�>b��~�J���س�D���� �f��
������8���a/f�N�LFV�'���d��.�VM������s]Ð_���`�[0���*�Ы�@.���L�
u��#�`&�s'�n�u��Yp�
������a*���nB��.φzᫌH���;�R��q__C�|+�:T���r%-�`#�9�H;h7�PCv�O�����V J���8��r���w���H�	ʚ�� &Av8���::Gq'L�8y"h�E�$�
���Y?���Z�`t�!���0��*�z��f֩��@�I�ǖer�'A����ح|���z�O�(|�Y��@0�4�����h���.J���'���m��:�P:�!Q��=���#�H��� S��r�=���U�-*Qt�@��5�gt`g�{�E �V��	��1�̹R����Me2&آ1�"���l�6L�P��>V��r��6\�V;>i&z����1�^��5Z8�<��d`���r�(?����,ry�#/�k挞����=������L<�$r I¨����"x���#y��c������F6����Ƴ���"����?u���M.�3����
�.��F����Ev/G!(�>�n�!��I$+ّ;ǭl�A�a̈́�nL��o5�G�ң�#[���g�<ru�w?Gq��
i�$�A�5��*�K�9�)hh�!exh��$߬=r�+r'A岝M˱�	�>�I��Jb)OBIv�d\G�+�ȇ�&vY�niU9[�>j��#7WJ$,W�EL��,��_�#~i��� ��k�`,�ȡ�R���T7�����b��WB���s�P�}M5�4{v����H�űI�l2�l~sW�}x:�^L3�R�"�sQD��8O���{8]��:ަ��B��O�Zt3��ɤ�i�,4~=}ux�~w��3^�Q��-uҴ�aV���yJ�d���`�~
x�!5�������Y��#T�������aȥ�IU<I��"�+x�-*p���Us���)s��� Y�8�1�eN�VAЪ)U���@���>u���P`�6kڊ*b&`J"d��7�[i㖬h�0V,E\˼�	�oj3@2ꊖ��yv>�Zꃭ�ƙ.�湚�6���?�=9�>��vW�Eӫ3��"����9��#�l��fa���[C�/���M�X�)U8��w,m%�/���h���}|C�������Zu�&��A���ݝ��1�n��35�i���	/� ��V;��?�|#dg�^>}a�`J����}Q�����v3}��Ϭ�K��F��_m��Us_(름[v��IB�=������@�l6Tp��쟶����M�vNrWCC�RO�hm��&~by��}�~�`z-4)��3kg�.ʑ�XO�����6uYۍG'�N55&���iR7��v�׼�_�]|�W�P�����c z2�x�E�^{�=�}��9�kc\'�|�
�ft!� ]�X����k��6���P�Z���k�׻�o��I�V�"ΨRNFW���<�ME�NX�?��GN�$��d�� =�e0�=|�x$;��QB����8Jx������D��U��$3���+)*6앺4B�V�@�&�.MQf�J���DhOC�0>T�K�-��D� ~��ԒZ��u�5�&?���p�ˌ4��{
i�v�J+^t����6�t��4��] Af(���%0��Ԧ&�u)�MՖ!5&5Z��$�n8L<�c'ĻCT3$��S�j�6�k�?Nk<��f�J��\�������)���l0EŚav���,�B��2��	N����D��I��"�#��0v~��e���d�	ȳ�W��1��-yIJ�M�S����Cu3J�
g�(�-�<���[�*p���|�x"F�d�r�e����vR3�~�Zz%�
/�e4�;{蜭/$�,���$����w<u���^����P{߱�q*	9b��[XNը;a7F��~8�	y��O�3h����e�V��m�ֵ���t��m�0h*oKR����+��Y�N�����Y��j�{>�K�Tݖ��fF�����v[@���]��V���N8Hh��m��B(�@�&�R?�yi�*�M�9��`�p���I����Q��0�ڄ��_��[ԗ�*���M-�!yj�#�~/�Mke
~���Qqi٤�r��&��2�7Sm�u�xϢ�pl*Q�ݐx����LP�L����WBD�����ehf�V���C��_qY9����n�֪O��B���k�5uWPl~PP��%X�Nq�R�:-Hgw7MDP@U���:S�Y��v��4:N-�A�m()�?J��7���\ ���n�#��2s��z?�"����H�*��6;�S��M��Wj�b����1M壙S՘g�!(��&�u��7z	��/���Q���kO���LA<�2P��<S*��=�"�<���)���E�C����[�8/\E�^4W�N�G_�}A�i�d�Ey�d՛A/ь��aZx��¬`2�o�9�g�s4��9�5ϝ��g�Q�+����-�v���5�����a�/����,���������%��x�����\�ȼ �E�4��Iyn;IU<K�ר��J�Xb��i�=���+��<s��=��UIdLG�T�MC,�q7�]�����} F�dM��:w���j�Z�2���#��`L�-�z*���&	�B^z��0�0b4�L&(�2(�y�0e����
��@u������=�I���{�;�n���@��p�GR���#������Q��>����i�Ѷd����IV~`N�O�����N�N �}�������b�g�Oa��8�!lr�5��`,C&��mӈ��٠�)�\T!4�1݂v��������GW���+����h4�W5e���w,�\c�>��Ě&3�3tt�fR�|3Gg4�n������
dc^�j�gݾ�*TW���\R���O��7�qs���!��[sfɕ�y:ژ˕
��)(��ك)x)�����r��7�W���"Z{��Oa�b%-���w ƻ�"��<!�}��WW�`����Ym��Y:eϳ���)��Fe�c��+��H������������ڨ>�]��Z��v{ի8��U��i81NH�w��,��	�0�Β��M�8�_�4L�b��G�ʝ�͖V�]I���iuA�/�g�Hb,5�H��{����J��.�-����o�� �}��n�B�����%�D����( ���\�q/DI�&��O�i���}٭��"�6uE���*.�ѥ3d(�>F�'X�0��r��}jNo	#u��2F+5q�����7�ǿǾf\]`>����n���m��6~��2��9�`��k�������(v@�O�w�eM�x}��/f?��x���P�m�ԁ����̥v�~#�fUa�����$0���?�	�-�fPK��{�&���Юs�-In���Q8֋�2&�q�`�������"7�G�y�؆�=���t�=�ӴhYն�K%���oK�$s -rN� dt^=��fJ�T�m�E����OJ�3���$�G��bf禧��$u�=m���4qZ﷐ZK�ZL���hI]�K�{�hlFf�/�����U�����X&���3n1��_��I��^j�'m��vϸ8�[n���н_Yo�]�8�u4�ݒǊ4i�<	g��Py�P��F��9�G�h���^�z`̪ϙi�Eɐ%z=��1맳b6��*��~�s30�>7ӯ�rR�͙�
B����<���vi2�c�b>�QLD��̲�s�'�#�y��җs�4�b���+R��U�u���eݯmyV��aU$?�C9ߋ��Q���0&xvA��Jn6���'�\��ΰ����u���UQ2
y˗_�=����VA1L���tx��)�*_�PƲ��/o���6p�lV �K.!��f�fM���35r4���f� U��u�	���"Maǿ!�#IQ̽"sA/�)�,��-�i�3cҠX;?�R��^.�f�?6X�C ��B_o!������}�P��$Ș}B�@�j��ϰ]��13�4"��o�_�P���6�V��A�"}���?�?FdC��~0�9�0{�Ģ� D��&�e�,x�'c7P^��=�$��($]@{���^˸p�]�3�(As�ư$���֖�L[�ؘu>յ�O���sF�Ӳ�m�G���g���ځ��B�_�X����������N/�h�ѡX���%�}?+���:_|fX9#IQnI��z���΄�m�&��Ll�q�o	5�3(�e
ڡ��4ٝ��&]Zz��5��V] �ȻU�@ڻ���GQ@e#���z�u�k�.�8���4dM�}�n�Dte�[�Gf��j�ڍ�(ڝ�%Hڱ��`J,u��,vi�B�܍	'5��:q�`������ J�,�lcu�� f�2lgڊ����_B��
[�7(/�=�te�S�Y�;/E�M�ݳ����nm�Xl������\J��-%���@N|�5#��7թ�0�'E�z25-rl5S��=���k�v>���~G3ג�}�k�$�ė�&���uR�q��أg���u/��y��wj֧͟m�`xz䲛��)�i�������m�}2u=��3�l*�qp���fﴽ���h�����$�g>\�-5V�8Y�2��W���qxS7�3j\�FBQ�/BX��/�p}����aFV2�R%G����k-���[?���v�ݐl��G�%#/��v:6���lD"Yf#��uw�?a�%,�2A�vQ��DPF0�4v�`h��anN�-˱gͮ����w�¼��vb�dKU锍,��y��s��m����Ir'�72,anq�!���V%�$ԧ��_%���O����F>����m��vW���x?'���X���] ��z �\n*3�����ut�lO٫�Z�����pm���eǃ
�7��A����1��J۳�*���3A��Z �'�}G�'����H�UT������N�{������9ST�CW�>C�]7�o*p(E�^����@�)���.����)#m�*�#�2����E�)*�����!��4�Y��^�b��P���M��nT\I�PTފ"�
���9*w�Q�ݽΣ꙲�S�C�����6��7���?a�X���������.����!eM9}NP�Nb��(�t�|��o�.��Hh��('I�!U!(ot=�P��꜆���:".�Q2~$l�(iu������[�R?�� �Z�9����m��W=�~hr����)� ��k�'�Y�j�Ӓ�TG���S:�����9���vOwy�<u��
Y=�g��Yܯ4�*�ݟw޵w�O�����4��n�x�A�,�x�{NŀOS$����7H���1�>ۜ��(�<Q�������&���N0�8��L�F:%�PJo�����u|Lu��Kص?P2|pFPQ�����!�O[�/�/�N� �^:�R��Er	�����p��_aU����x` �i�ZO�e���z�\3��`�����p���s�~˗�β��G�@��iY�"�\�A�b1����������
e�
b�ǫ�����h�m�y� W;��:��AtN��'�����b�i`x9�Mf\J'��
�l���$������x�n%J��L���څ~��j��/.�\wk�����Q�gٸ�/���m��F�1�ͬ}��B���Y�^��^�Mg*M[&1/|ͪyc�&�L�e�0���"(�����ˍ�l�{2�e�+D�1@wV��EK��1ݚf�/<���i~�5�0ss&��:��O�YU�oe���:��٧v�A���0�s�Y��>Tx�T�~:�jG��V�_f�
d��M!����W������C=LEV e��oq%�+���T5��3�MQ�N����U��@£�4^R��>T����������U��ʝ���Q�c���HI��+*��a�	�>��� ���r�{x��;�=�һ�Z0Ļ*2NH��� �~ǰ~ɡ�K�F�N���\^>6����g8T[��"->,�����O�����=���ݲg����%� W�!FFF�⏢K?��&5~	�h\AC�l�+��
���ǟ|��5���Ys��U��0JLnF�21}�dw{�J�k�YOu=]��&O	��Y���(��0S�1�)�t/r�C�͉�V���I7O�Ϟe_7}V�Oo�휵�y���,J�~�=��K��q�ព��t�~"��y�/0���p�cԫ����sc�T�T/Ga8 O��
�j���qp�Բͅ�Fp9H����%=�!y&��iJ���	h�S4nH#K�A�|Po������Hb�8�T~���Uʹ�y�mH��ʓ�V��}r�����L��آ/�鋺�o�ϔ���GZ�R�D$�W�t�89����1��J ����<��:=����sϳ˫^�h�w6n�1��\�+hН���hV����T����ʐ��gc�(I�}1��W�r�/��?icQ��� F 3�V�f��p����m�ִ�5���,������k���HE�~���x��i0���� 8�Nv���Y|�}���G��;i[b��O,u<*�ɍ��iMT!����q�1p_ak�.>��nx�����,V�<��ǋɥ�D���~�����ۏ�d���ƛ�����	����d��~�羗��6�~8� B�H&׬@��C(xxA�ƀ�AO (C3L�`$ԑ�%��{!��E��8�Ū���e�$�]h�]�z�ᩐJ��&�� {1��4� k�A<�`}YX=;�@X�����+�ar[�h��+�J����tX��=8�{.x��Xk�� v;�ּl�t?�4���y�z}��R!�;.��F���(DA��TK�2q�jX([���1���z�y�zm�,�~]����.�Rӌ={�n�J:C����o�����/4iL�95J�ku-Dәb+"n_���W`ݏ>��R_�0�җ���%n��5����R�,�����U~�Ϸ=,d��r��>�|���z�.����Fuu���rs�Mm���$��6=S����)�"� ���	��p��J}� <��4������ߠ�}�aU7�����7�6Ʀ٨�۔�a�"��֠�8����fW��o�	��A�Ki;����<b��`|��+���|ÿ��������R�z������}<̼�
��g�Y��TWHi�޴����O�j��U��Q���?U-�>q�M���su�LR �1�u�?�>�:������X�8I�ڴ���T�b�p��>! ���� ��=9f luvk�4h:��5��`�5�5j��������R2T8J��*�LT��i݀N�tL�͕٭�i4�[�
�a�����L22G<W63s%���y��so����Q��H-����ó�׻'�ɚh�S3ג9��`�X�֟U�2�k��Ҿ�c�C��]���׷t�[�;����O�"��OD$�J�Dh|x:f܎!=.
O����?�.�.1���歙�&!�m`��t'�n�3�g��Z�_������y��w����Z�Ͱ��������c��D��8�?��1Y}{_���7�p�>ۧ�h<�M{���ݿfW�ǟ=��V�[��fْ��d@��xPIІGd�<V(�y[����;��]�ԝ7/`Y�'+�Jm��Jq�Ǟgb�f����hشAG��N�Q�>Q��\d?��:m&�@�$�(�	���KK�:=��9A҆���(��S��v#�wϞ�3if�����r�>'T,�6�;�Y[��~��wD�n�6�]�:O{�}���/�Y���E�ZvZ��+*�k���-J��b"7��1�S��czzIw��U�\)c�=5_��JN�(-�Y�<U�\�^Ƽ��F��E��yǩ`�&6��.PB�Q����x6Q7S����`E��TZ�c�	h�t]�e.�N�,*d������_�|�41TQ�k�a��3	�bC�sJJ�j�aۀ�>�r��D%��{�f��Q"�e$�Aa�S�_��ъ�����n6Ŵ�`�pe�������t-�*J��I�
�o�+)��)���<ȱcB?m����L�Y�T���Q���֚�x�qU�!8�y�瓟�`���2DSa��̮���v�c}�m֓;��@Ǹ���ONB|�OQ^�����K�o�;��Gʺv�5�*G��UDZ�̈�-Y�"gŁ���%.O�Bbح�D����;�a��[�(�_[(xh��x�A�d�������Q���W_54�����,*�����O�8��v�G�8���E��E���.�U��뜺�3|�O�7���vq\e�xg!�%l�M*ҩ��s����G�$T�7�$�AҀ��ꨍ �'|_�����C�&�q�t��Bi�o������g;(f�0�ME�x��E������H�l����[���;�&*�K�%-�n|��.�_��y��7Aui���e1Q~�t.y��A�����}�����<���*�ѫ�n0�E���g�&�\�V䍱4tX5Pf��k�cso~G_!/ݶ���𷿩_��J����*�2�\�e"V�YR�L�T��L��(rV�XQn��(?ˆ+��؉�+�S�N0��x�vW%��`D*��I�t ������BHB�уp=�dD�:���0P(��J�bO�܀�K��Ff��a���f�I��H�b*�y#��]p][���LA���S��K���޿H�����OC�LTr�T�p��f�b�v�`�d�R�bZ��:�S�f׷PF��"��� ��l3ۦxe�N��]�X3!�+�Fd3/,�:�J�vB�G�W���0ݟfw�j����4�/j�K�	��^Z�#��Z��:-�$ԴiSd�ѥ�x�Q��H�z��
!���,��hʀj��x�9%)�|�\i�W�g$�)�B�_�5/�i��������hXQX�#CV̕��B��r�$�x���֍;I�W�c�~2�?�����"�.����[ �^M��~���?�5�,����g���/s�g�p�=��𕷄�e/��+o$�_��]K8O�.+���!�0R͞X��Y�~����C�\�'�й/�~^��u���
�Q�R?^ւWU!��:�p8ND"PBjw<�d3q�'�b2f$��	yW�*��5�Ub�eA�꽬y�ݏd��%Z���Q����z�5�M �(|%��XD�L�6�%�����I ���լ2�m�*Y8LC!]�K�^��'�yY�*��*���T*KHl��@��d[-#"U�mL���%�oYD��jp�����l��	]'m��!PSH�؜��T�hڀ�R��K� kwV��P�K)W�����ѐ��X���"�$�mƚZ����������I��������0���x�����B����o._r�����Y������ˌ���{���PYia�UO����G�*�=��� T���M[����*��j�kq�}��٦��:�8�S�����qk��٭�y
f����5��_��@?��?[�s/��J�L��R�L�:{׬fպUݪ��9��'�������PGZ�ɺ�����m�9٣�z�hO���{р�?�E`C>>}�c�ȕ}�ɳ֭O���X��0mzWNuV�����R|G��PI_/C/!�yBJ,7�XR�ːR�%�Zd����8����t�n3�$���Ș�����2L[`�o���<W
��������i�o/2E_"_�+��*)������L��PMR2)�Gu�dS|�6��9���T�jSפ��k�:,�+�XhK��)'��8h�|�m��& �n�����]� (*�M'��"H�*o�[5po��M�\W�V[�)���|�1x������m�&�56J���u��ծ@_�'"Ap�[����@��<A��vv��щ��f[�҃vܮ���x܇SBˬzQ��+����W:����s��6�Y��������ox胞�>a�~�J,��O6aU�,�IN�����0Bgy�<-'4��y�(\��t� �{���E�r�>݊�*�R�d-] +� \!�&���pq^���fЋ�.j
YZ!O~D��aT`��St/ai!7	�>D	���/, {�Dcҽ�sj���Ӎ4G�p������A�,�4gxY�QQZ�ĭ�d[�d�z�l���%�����������Tf��ߕjr�~/t����X� h�����3����������b����N�z�&�-? <�T\�tev#.�`L�p8�/&W��"��wM�y P석�����C �dT��p��֦�#LPF�]L��C����+78~GX0�ǂQ͗�H0���B)'�|��Ʈ�I�n1�gz�3.C�f��UCH�dҍEЅ��Ng������"��T5F�7M�fV	�]_��n߈�2 +8�7i�GI�O;��뫏�|P#
+������N� R<-�J>�v�й�
G�HЋ%�F���0=�E�[w&�+S�2ZOK$uj����%�j w���V8��E\6��+���T�U�=��-���{p3���R�kE�a1���R���|"v΢ML0Ա��/$F�PA��\Ga�Lq��H�`�%(5���)�l�egD�D���&[܁�2����t-�bbuT���}@r}/�� 	9K���֍���B1+ԊU�}<"o50�DI�DV�g�L�@A�**�����������L�k�/X��fO`ݫ0ɮo� ƪU��dR'��މ��,��;K ����@�ƙR������E��ח�y��5����S��f�3�.�6�w�ԗ�Ӡf�+�w�˂�6��'��`�����g���H��o��s]a$b���Z�8=���������ן?�����B��e>�5�H�[����R_�¸��<���s���'�������=~�����b��c�hd_�L�fVe�Y�w�Ǐ����2�؊^�}�VXѽ�^�H��k������O�9�����֬�/��Ԧ�9s�`��K���|�2�e�u�#&?y��� '��\��>����W<rBX7��e�$�d���o�)�l�ZP�S�AU+,��<�Yz7_T��5�[��}QI.�4S��D�#�Q��»|�Z�����]W+�60����F�f4��,�@�i���+��i��MD��t%?�~��@uQfLI���n�k1��(;����BQO��.쿲hps+�80��n� -���,[��U�w�Je��1���`#����p<�
*y����������Ƴ���e��Gc�}4��+��$Q��D������Ē�����~�C���q�ߠJa�E�4}����v6�=_))�����#VH�����(A�6�b:pы/��@�dw{�`����9~��'�-�^F���M��-������f����:��L@�a���jB��_	�����U������7/Ķy�|$[�z%e��B
]����PyQ��5؃U$��Y��b��9˾vt���O�Ͽ[Ş��I�W�I��x��%<���������r;In!a��Qi� �G�&ѓ("^��hskKO��Z$C9p��&�!����H��E����l�M�@�����?-�c��7`����iި�Ych{5C����Q�@-�n"b�hN}di��BNI�Z��[(�W��\|��g�Y|��g�Y|��g�Y|��g�Y|��g�Y|��g�Y|��g�Y|��g�Y|��g�Y|�����@� � 