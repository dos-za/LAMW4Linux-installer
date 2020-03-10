#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2321118850"
MD5="49728e1ed45caccee100b8278642c4d0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20736"
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
	echo Date of packaging: Mon Mar  9 21:10:08 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j��*˼�h�+F�
VE|67R��!F�œ�ׄ2���k��r�5Z�g���'	N��O�P&P��rz�����!@Vl�f���̬y�6��d��	@�g��1 �� aΐ`9kmX�$� 倫��[�w=��G��C����Xs_���+�}q���L|AzY�{��//G��E�:-�q�cŠԴ9Z����DD��{���*G��­��_#KOi�1�`h�K�$
��u�(.�'�Ɏͭ��N6]v�#���ګ�Vu����6�n2b�� ���K�Da���]_8DI���8��%�ŉ�
�|?E�u~M���t�eQ?��n$�-�ʇ�<'����aY149�l��ȱ���p^�m8Br�$�L4��[�!�5��^�Po����.���Ft�vyКUylbi�ɑ"�~�KP�m�X /�K�j@ahM��XS�.ഠ{� |�޹��h�pu���	H�G� ��@�]��5�R�F������w������Yϱ<C� "�jK7Nf��r��n��~Ŀv���}�_��2��>��t>�S-��בl��l�f�$;^Mfo2�)aZo�LjoQɬ( xǞ�D�\��,���x�bB���~A������}����G�q`��Hw"Jߩ<�;P|��r�ΣױE���J�Q�7j)�ч��kD_�p�rӭ&0��Gcxp�x�5�~R��CQ��#L�C>������S�`�o�ָ?�7梹`��<�+k��_0<�'�	�z'���{�W�_Z��1]a&�h�$:��I�͵;��4s�:�����|�P"��A�Ӡƙ�5�`�Ǭ�w����E�+���_2��?�>6\��m	������E[ǑSh�ֹB�\���&͝*R��p���L��wd�ETP��W��'�Q�c���Q�|Њr�|g��-��Le㾳X��Q\29��Ad��������_JK:=�aiv+�)����0�}p�t�6�ѝ	�mxt Z�d�߭g� dr�����P�h&�.�s�UO�G�b{�C�(�(Sh^=$0��</szg�ar+	���g���0d㫗IY���?�b���,���l'<*<���dG����&��`��#?�[�:�ЯT�疁7�%�%�ܬ�#�d	��R���ﻇ�����3�U��� �'#�>�O�k_�條����g�>Fg�� �1�/�v|��W ��Q�a[3Cz�}���
��Rļ0�̏�x��
�>�A���Tw�)`�BI�#��s/����:�*�ca<C��w���D(����GI�|�[�TV>	�:��v�_?6�R��K�Wcθ����c��O�ϋL�z�0?@T*%VƲ��������%V_l~������|%�)���*-	p��>I��D�
J�)mO�:�ޯ�wd:r�7wFS~�샋�RH,b��^��\!V���q�ĥ{�-�Mߖ��LX�rx��A���qy*P��=�g��6;�\]�M4��[q��ϭl��N)�rbx/Y�*f��"�C�n���3� ��b�n9�^��HtϟS��������5�LbyMȟ#J�6#~�jN��$^����|�pMc�h��k�A��<�w�&��e�T�2s� 
��8ǲ�oP��6�z�MZ���E�.$B�����`3��󔶕�k���H�Q�)x�v�p9�bB@�1"AtSq��?I�KZW��/]��T���QT���we�5��o��l�>W�x���0����
���GY{�Nݟօ��c�ZƎ�,�F]��J�j�����fV�"�9��/�FN��L��U.��yqum���Ff��1��a���|�?�pK�twA_: O�Ě��̀!�� maW���x�2����n֞��{�@V�I���������ي��o����g>Y(�8�_'/��n���JY]x�����N+F�ދq�������rJ���匓u(|n��͌��W\�_�;�ρb�j�1�u����%%���x-g�È����qD�' ˕�ϱ^iF�3�u "���$�kf�k�E�*ߟ.�kH�gC�ɣ���hƒ��f�k�GR��e��z�e�����sRo5VG&��� �e/�������2�S?�\R�h���J\J��;�M-N~��z�,L���)�p#<z�u˷�}��LwO�)����_ 1��_���vvP���o�#���>��`Tui�6戹hW���f{-����y�|=�K����I7���{PZ�hP�1���dlօ��0e�ב6|�y��܀&;Z�8�lsI?'W��}��Pî�h*��g�����k�ZA�z-B��t'i���@
Mc���G�r��s��Eْ�!�N���:�����y���O_��7�s�1[�V���Y~���k��7���R\ӓ�~� Z֗ө���)� O�� v؀�	qp���#X����՟� Ytjߚ��Wr&�a�jj�Kک4s.�9T(%!=CL�S�%�]V��{*
�z�c���F�?M�23�}o��t���T�� ���8�Y��"���5�2��c�1I��Ҹ@�m�G�PF�ֶ����̤��N��ؽF���,���rC	�E�D�D�~�jp�+��ހ9\<��	:�: ����h~w�O��Yy���,��"�]��:�T�m3^}aiȏsR���FO?�!�-��!7
��s��l��z�?L�'���vd�&2�ǿ;H��|�-g<�[hi������NW���k!R����^���´�N�B�.u�9��1D*�7��ZJ�_<�� 81׊N{{���>��ЀʆwRQ~�j��lܒy&1N5;T�� �T/-�r]�<���u�f���gDw�n�dYp~k�ic���}���P����j�ڐC5K<�3P�w�p�ZB�K����.o��PU#i��<�r���ˆ�\3�k�+����$�����F�:�̽Y���=�.�l����A����4���4XQy*z�ݯ��l#	^H�zp��^��[��ڝxtB���p�t&�;$�$�!]j�k'��{�=[|�0[�7fzH$��V�5t�8�^�n�������q�@֣<A��7��f �fD�E�:�|<�%��̓� 4*e�5�k���B��T�&O� O�b�d�8e�޿�ѻ�-^�,��oq��G6]���Ji�=�3���'�Ԛ֨Om�?Q�X�d�+v�p7�X׸#����x�rvȏ���k��ҩA"<R�d�zߏ���yy�E��KL��z/+ꂆ�#Q���V ����	��_���*Տ���!�}uV�~Kj4����S��k���˥��-W1������S���y�|"+a�����*������,~|zy��ֿ�� ��]$�T!�,�uۈ4��xB���W0����f7{H.���Db��A��8��4����	�Z�㉁ȣ��S-��H�YS*��R8�\�t:���%����i9��%P(Ē7+�$��g��o�d�]�@��jܛ[�+�d�TxXi�fN����ʇ~A�2-q��D>Z�pq����A��� d�����\�����֦�_}~��/,/��7�s^4�L#,��v�)8�<��H�H(n�P��M��?�xUu�f�v�ub���sj�iI9B+�cJ�������"����x������1�K�߱Cx�@�d�{���D"_r��M�a��P*���u���{�v��}�8G�#W�:k���ǰ)Gy�z7��^;�*�j�q��ӊ=�z�.�����_���ɳ7�0�G���F0���[��I ����Y?����2�����.H�.O2�h&��E%��od(�
�ݟB ͼAݞ9��#�,@n��+���Y�?e��H�x3������N��<��3z̐�1T�����%V�qצ��13I��&O�&�����^a�,܎^��s�:����K�m��>l�/�O�ҋ>E����
��nR��NQ�W��_��R��}�ch�4���F�2�Խ�颞��5�Gz�y̼[�>�"5���0��tSx�-�"i���O��ܯ �Y�0�,b\�~�7�+�He�+���	��b��a�y�?L7���i�O��tm�q����rCV�x΄�å��˭0�g�Ku�вS�B���L� �˹���U,;񫑇4N��B��P����YMy�~:�o�N�j����069� +g�I�z_����nZ2��S��`��Mt����M<��R����~����Dj�S5#�.:��=U԰�������v��[�������Z��m�l�����V�i#���w��9~���t�wC�|�]Ȏ�g[�kغ�o�La�'���������<�\���"EL�u^^�P��"�k���5�@�EZ*�qp�mJ��4�A�8�k�N*B��;$%׾�Wi�J<;���B��c�ȥK�Kd\�"�rWp�SD���@H�ʣ��O\��3k��ܻ�6(�-����v*���]Kb�����*��`�	m��pg��PN��]?@�����S�s$�9�W�@[��q�3he����}�6�-0yTY�сw=���Bk�ܦtP�Jz�ٛ���#x)P4ެ�kLA(��_{�zgI�ܯq_���:���|�r����Ag��	"��V����0|OdX��Btl�1]�����ܧY6����](`z	
��"ri����[��zѭ��頗�v�χm,�)��G;a�_R�^�&{Th���;��`ݎ%�^nւ'���v�}��ЊϤ�4�]��łfz�}R��*�i@qj(p�=P��U�6z�q�u���uY��J�x���-��)��g+�M�Г� ��P6���>�������l~�`'Qş/�Ѡ�'%v3P����>MX��N�iht�/���(Bp̴�n�Y����"�����D{>��RI��vLO��;K��ݴf==2�4��Љq�����Qƴ;Fv��� �)�*�ý�-~|f��ƹz�t��K�VM�Zx�b��f~�RMg �w�ZJH����`�ub^Jz�a9��rj	��+2��֮�����xU���yZܴ�ǽ�;i<�������u�X�Θ������"_�8B��Pv�¥���<�~/�:�����㑗��Q�Z������^��>�P�<��
�Jk�l6ʎԉqt]�� l����?�Μ��Ғ��Ya����=�qBcB,�h�I�Xǌ���ڼ���vPT#Q`.�T��Ƨ�&��h�Q7�.WB����;n��~~*wa�ѧ*¡��[O,҉�M)y���^M�N��5z�!�,��?!]5�j��\��S��+���p�����N$�H"5u�ډH�lZ�r7Vu���E���M���J\0���T�DF*2���ċi��~�k��"H�w�"*ɚs���h	4L�d���T쉈�Y�Y�Ͷ�A
P�q�5o��+{����S'ԗ���%"p���x�)�)Z���w&OݏA����8ש��`�!O�-�\�h�eP��_�EK����n��������#�;$�3
"����H(G1�Ʌ*N��Y�Y	4�&��(�'Ohɒ�����*�����,C�q3��ε���ф�|y�[�����Ω�#Q�[�_�g��/��^NjF2���9���}';x]���U28?4��.D*䛩L��Q�{�Z�V���bK��^C����ƨ�n��l�Ȳ'���'�(�;��^��6�����:	oO���re��/H݄��u�{<AJ���-�m�کF����Ō�Sn{z�QU��VT�������	���F�J.H�;��,���9��;��6�Q�ig���)g�eM��<�#�P:n��i�l��wh0���u�:�A�NXL�)�������ĪX��M�d����<��� {�F5����A�;���t�
[���5_�������Q��@'�eiιk�MUp�̒(P�d��4�=����:P��p�-WX�[�2�4����9�{^+Bt[`�c=��)U0Q�rXП��!Үe���Yؔ}�f:��g�÷C���_���i�����7���}����I?�I��z��͈#�/��w\	I�Q:I�N$��9�1�%4�d�9:v�E������e�|�˻qfS���ۿuQ'.+��TJz·�W̬�-dJ�`��Dݹ$f�TȞ|N�Hߚ�h?� �s`Zp!d
6MGR��f�ä�CuE�/�NK\�Z#�����M��HK���h]�t	[���r��
��#�{���B^�jA�=���B�@Vpq��ם����i����{�s�,ϯ[��4�ʯ=�̩�V ��~�6�;:�>�.��R�'zG���9��S1��5��s���Æ3"�mi��Î���d��`�q
�F�C�F�@C]Z,o=j�������owAk&�}f�]k0�sS����|��)9��*� ��ᐐ�¥#�Q%�#��k��������!3�g��Ϗ�X�i5g�{Ur�������Fܦ�YǞR�-WEۣ4Bjq62!��>��Tg%�BU��$jA)�I�p��[oM�$�f>���fj��� �x�#��yW/vI�i��gԘ6`���U��o9��O@��$�!K��7k? ����C@b031c_�u���� �o�80�&��q����x�%5:��A�����'���p��_x#�۽��}@�Tn〷r���߼^�7���tJ��3[r"10?��@c[P����^k��U��K����f��P�t�op��5�LY�����䚮9�
����;]�����կE��g5�`�������(��f���8ax5�+9e׿��������H���̭�P�!�c7�r���*0�Q�Y�Ra�j����%i�N��?g<ޯV�Ծfi�K�g؁�yi9�����V=�<���s�NNηv��#�XU�k[l��Ϣ'@���0�D�<c*��?j^��w�+s=����h,�ck�J��2Z����)�L ���v_
�)�/���*J�w#��@)���h��J�_����dm�0C�T�ߴ�Ϡ��3�ab��O��B�h����	g:�u�ڞ}Z�<�np_��Hݹa��\�,���:��0јRg�\�R��-:݅�;����%��2��d5���r��X�(�s;�/��
�����uu+t]�(��KH��:?ṗj��)��]��u�#��*N<	V�W&�;�AZ`=۴p�6��m)^�_E �g�����&��e�8��Z�	�`y��>"]���L��#�Y���B$�U*����otEt� ȟ@s����X�s�U�?�`���3�d��v��^dQ��m�հ�G���
�J��Ϥ0��w�-�v��ds��up|uU4@W0x��B��_E��wLx�Ί+Euf� 7T����
z�n��VSr�(���w�g��C���g���l�6S��U���	(�d��;HL���3��E/!�ԁQs��`��[hg��L�$zc��@M�6a'\ K8�2Ӣ������#���P�L[��Me�����k~3<�Tn�ID��ZP�!�Y�T�0xܟ�����A�t=$�Uj:D�O�{;)�ޫ"V,��Y���Q�D"�1��O��V\�MH���T�O59�4���FɅ��ھQ�9��Q^���ɾ�Z�fMq�����0�(�r��Nȗ��=�c_A��9W�z��M���ִϫ�"G��e�k��^�3����Ҿ���!��:Kx�2�M�o$:?%�'�pY����J�j�H#�Rה<�Z�q���)l�"{"8��W����5;�Q���}؏��-�*Ne�h;$2�P�J��h�v�-��7��S��)Ђ[����V,�����L�@�6�w� j�s]��w��Z�X�����n�8�ۤ����R��C޷v��1��������k��)�T�4md?v4u�<���Ӆ��G.��6'�0^gv���R2'�>^�R�iڦ[*�I2�0�$}�ZBe�"�O���0�,�����Z�_���Y� P���UM縈܌���G�9�X��w0G���O6Ў��a�9��?�E�*�o��� k'k���`k��K!Ըu��(]I��3IA�WU~bK�����'�ˉ��Fw!B�f�Oy���'t�rb��u�v�����shOˋ%q'�4���*��E��@��\��V� �zs[��=Е2�D3	���6F��bT��^͂T��-u��[	�GG���~T�_�|�l�����r	,W_��FD Bx��Cwt1DdH�giWk�����̔�H5�\N�61(��Q�m�~�A��>����N��8���Ʈ��}�ĿW�]o~.��Y��\P��R[���ᶮ�#9����:�gEQ!pN�����B�q��Q\��ˉ��C�����B\���X㐳�aN�rA4>�\��C��c���������	ǝ|ʟ��=琐��R�������������&����3y{F
��D���;��O�z3Q[ö�h���+}��n����	������9��@
���Q�3.̪"�o�}/Lނ����m���A�ַ(RI�m�V��j3���
��`p�u��ZNmП7�V���Q҆{c5��'��'�D��<uB�h��j�]BS;A\��H�L�҉̵$�i8�d"nyD����0�N����K�,u1��{z�]��3ā"I
ԉ�6�����?G�j+���;\֗�榊�XI��dUk:v�.����b�Q}�2(�p���y��s���$|�3��(O֐ƤV�0N�u@1�
k����l�X�`_�� ��/��c(_3�ߤ�~"d6X�Y��:�����J2V�Rv�"gdx(��͟�H�4��-��\�j�8FH���
F�R�4��%����뗑\�--g[s���?ආ>� ���+r��;/���I�J�3�K���_��Cr!Q� *��U[��(�p,[F��[6�xe3�X����V�ځD�w?7�WXH����7�t9!Q�@LW���?1��R���m�F�gev*�}�qʄ;��݄Ub%� �5�JLh����l� �L������������[֚��� �D*��%1�;�Brb1����s���WoW��z$�K��e�s;�\|�\y��<��̖�����d3����s�c4�~���!�q�t�9��S�M;���>�����g���-��OU�<&c��a��r��9�����X<��E�%�5��1��_HTUvJ���a{(+Ǌ`x�$ �y�P���*xX���s>��F6�l0􉺜�>I;�~�.ݾ+dÎ�e����yo��kTW� �M��`-�"t`47B�����a�O���N�E���A北�q�Y����^�_�cG�Oҹ�����Ȝ�m���k��(.Ge�oZ?P�P���[�˅��K����Z�U���Ɩ엀a`��H����1Ej�����V3�Y�W�l����I�� �r�Di����j��V>
��]�ąQɴ���q�㚖v6!
�̅��cY�d����哗 ^7�����8���4�.[]st*j�ːf3r3�@���b��a��~m��'��q|֒�� q�,�f:/�wpǢ+�22\��vG��(���j�z�<�g����3t=�6i �z�!�衒�&��W@6)y�P�z�а$�Q�X�"�n(Da���V�3v�
^�
����]�y������� @�}�b�²��DqM+l���d���õm8��^��j֞k�㋻mȚ!�Ǐ#5<��r�d^V�$�@�	��p���#N�ȼlA/�Mi?�8�twƼ��X��$��)�[/ޓ	2�XY4����D��Dg����m_A�Pv���m6�<�rL�Ϗ�C��{W�
���+�d3eJk?���<�~�WZUv��_Jp�L�'B�V���PX3��(����R�=A�u��ݨ���/(�b_pP���eg��˝�2�U�G�Be$e��zJC�H_�Xٺ�$H�h`
�2?��/O:Lj�Nʐ�(i�H{�"�bw؞�"A�QU�jrM;�4-�O�9�dzN��n`/�݅�0���3r����������{����c��u�G�6Z��|#L�r�y$���0���Q�D$��,T~�o�yi�B3T���9�z����(�/f����L���s��Q�fD��:�ap��'�M���>V�P��x�p�_1��ͲL:�}3��rZ��*j@�ˊ��ys7�#F�UЪ{ ����-ki3ZpvI��2
-G|"WH�w�3%z4E��[Vp5�Y�e����׏ɡ/#(T|S�S�-�\��Y%꭬̑X���K#�	ڑ� '����οn���ZI8gI��9��|�lN>�-B�m�wHԟS[t䳱�_��+�f�0Lud�1bN��K�7ۨQ�hS���9�f6%�r��17Y�1����L��>�
�;:�"�d�RqJ����U�9wG�|��i��_� 3Y��6�%���w7��'�.�<'��a$2jԐn��u�bċ���Ȕ���O�,#6s��FT�a�v���pJu?���J�p�V�'�Pj9�R�����s6�I����Ȃ#����
W��	� ��"X��l�Q�a�YJ�/�r��nup�%�B �ʗ��~q�����,w��l�d���ok{w&Z�6{7&�K)���Kf��CIc�KHTj��P<S�.V�������O$'�t�}�(��p�m0�JkR���ć�V�6�.N���H�_�DsL �8�b��M!*�VS!�~z����T���P=���}���*G������q7*�V1.��#�M� /f�`mI�V8���j�����l1U�b׻rK&^wBS>t���J1Q�$(�-����z}�/��-�C�M�Po�i�:�_��~-��8h�>��{)BP�=�	��/����(�L�.�
}��
<�1��H�]�T��]�T�d�����2P�O!�)�Qֈ�Dv�i�2P���k�]�g*B��OH��������/el��:?9�XdV�G)̦��w���;�'nN\���k~�(w��4�Ѣ,ģ1�$�u��/N hΣ��Wb��OS�n�2t�o�5 ��Tl�#��*�4k��o����l�vUL�y��P_D�#��n�9��.�Sr���ɥ�YY^�5[�Ѳ�)�\�9x�F̑��9��4*
�ޯBA�G��WL-����UA��M�c�3!s:��Va��տx_�$fU��8/��d�'c�=je5�y��]Dw^��_T&���o6�!s�m=T���So�2�Ga0����_ ��)T����ヹ=J��"x� �[r��A5����Z�gq���a'�hP9Vx�h5Q��_��h^EAv�a);W����燖�d7w >睘Z-��GX�������u���CP��AW�+3�` R>F^[x<�s�O��'. p^:����Gt���h	~z~>zo���u�g}?�x�a�bi�D����rf�)u-�wl6�~%�T���@�T6�0$��W����?49�q�HWЦ9u�C���f����e,o{n��0�O|��S}���Ͳ 0$�h��
�&���2W�e�?-��ࡥtP��r�L�}�� ����q50̲��k�j��������p���VȇC�6`_���/��>��89G�0��1cd�m�3���[�p.Q"��D٥2x�J�J�[ʶ�}X�;�.��g9A�q9�)\a������n ��-ǆ�`o��M[�ȼ�*��N4<��'(v̀�ӏgҵ��<��U2�����P�)4<��yy
��m����Z�3��8�	H171��N�[�䝼��Ice$�=nE<#��R)�+q�d��Q# =��|]��K@|R4�(K���ɩ��]�v�bؔ�>'2#�y�=�����"��IU�[(��u'����+J��N�m�M{9I�p�R�gX��z��"�|��"nj�ݞȫ�i�o@R['{�Od�,��炷�V	�mJ4A�o|��K{��2zWaBW���J�ޣ�aѭ�aƉ�=o�����Ĺ&���	�SK�QA�UP�q�����C6�޿�����kq���r�\���������U��7�� _�<�p��@+��i<U<v)\��X���~�C�oѧ��9o���bmT��a܄
d�r=�3겇�SC���/�q��){���~5�������hN�B����/V��t~6æ:��'Բ����qC#̡������������$����x��'��d$���q�lbŕ�y�'&�A���d�<w�q"$�`���Rz�7!��}j�A�z�������d~7�Ar�ŉM 8��""�[!�yತ�i*�D"(d��7[�&�$��=�GE,o�]��HK
1kÔ�~K�-���m����)i���ٔ����$�A��(�jTHhg�m^�{�f��̪Jx�,��vE�9ћ��=*�Pg���y����e��_�"�=�f��iŜOdU��n&�p��$�4
#XK`�����;�ҎT��y�1��:k�@��[p=�o����I)礐�H���&8W�{��/���".��EJv�0�'����� }������ش����,*�2��Ө��b="���Ů�F�w�u�EDL^��<���'��	���Pf��s���,�a]E�;�W��ɳ���k��Z��Ӵ�z|c^��Cj쨑9��%81x��Nm���D!V����ɍ��4u��M��"
>o����t(DHn6��0��d�$��l�zu=#"uQ�::���s`D�Odī��+�t��nKE�+����ޥ�k���V�nUɍ�fV\[�#(
�7��ZcA���̀T�s�jZ�i��3ܧ@\��%��9.:iN��1Z�r�W����:O �\,��2�h��T���AL3>�t	��<�<>ܳ`�
cW8�n�������̓��*����+|��׈R�YdC�D(^� ��~s	l��9ce�8�A��*k�a�	ĮR�qq?�<ڣ�+�7��S
��~��Z�Z����=$�d��,t��閈��!g����U'�ϔ�-�����k���!��Qcr㞀�R��1��*�b�A�l�c�1ٳ,�\�c���rF�X'��W�GA�1y�c~W�d8��ImDp��~��F��[��ţe[���%�2m������D�ý��_�o�oHл���;�_��z->�>�7� ��1J�vF�[u���є� ���l�0�3-�i�J��W�4.��Ǌb�T�2"�ˉ�Y�ػ`د�ż\��ǻ��V���TA�lڡL�Lsl�
z���^�Ղ�˕g��B�ܻ�YCm#}�[]e�G���D�9���
�+���'�q�̄�� ��¥7��]�:�m�v��@�ŷ���1�zM����{���w��� '@3�m�P����S-V4�vzlڣ,'ő��O���:n�OP�h?A>���{U��@�I��T}�� ��覬,�������$�8�%�n�C)��) �� nF�Ѓ	~��\07yos��D�K�ɭ�����B��Ʊ��}.�w�D�XuOE���r�D?q��]��P]�p?K��ӳI����:��-���rsRC�cZ-@���-��ѩ��U�}���g����?��	g)x�d����kg�T�%�$~�#U�%ɱH���c���]ऻ`�4@��a�4-��biH���gEh��j�)��)�fvO ��/��$2�/��/�c��o3>�S���R
B��L��я�7�փC�/CL��O����U���?1Xts�$�E���%�4�ut�P^�$o��5 L���TΟg��'}��h`�0���C`�V���#\E�\nU�aU�^���N�LȞ'_�p4�u~�_�u-�]��<)�,'��3k��Qր��N����CW;��,�(���B�^�Û�t:���g��w4rtx%aƁBw7q&�j�c/�ݎb���SnY"*o����l5"���a><�mXi$r�u��ؒ+�t�w�f��>��	M��z��.��$yh�Et]���؀,��n��� $�#�׺f�I�J���+�AM'�jѼK'31�Wّ�N$\c��7���)���t�Q�Kb��
eU�^�����g��368��wRZ����H�޲RnY�H��"�pS�"J5*L�i翁{�k��0^�T�+4��"�|s$�6���Y�G�`	�n��z��?�H��_�?��,�L˖7�b�@^�3��I��G14�r��=��Ǖ�`7����%��1cA)���A����1�</�a�k+�> ���}�d�F�y�ȕ�Bp�&���3#jP�8f_��o��5�[��l�N6��2� ^*ر�SRL	�6� �}lꮦ��]�{����U�[ Eh��sa�0Y�N�]��A��E�.�A4�4����ÿJG�ή��@x�[;�6Y���4�&�#�f^�5���^�a��&/q��c�����xq��k�>�V��1��	r��2�$@�4Jb�C�#״�|/���B6�sX���No�
�ib�"�Ĭk1�<�W�d����|,�b�c� e�i�5xihp:�@�1"j_SA�aj ��y*-���Y��G#���t�E� 7�m\�����r.a}�uǮC	dl�B�0�؊("B&!p5r�L3��T�;j�r����T�T�5��.�j��я�`�r�i�R�ba���S&	�ǜ4q�Q�f�Kg�����	�{�h�r�J���ލC�A�0��V�5�r�c^q�Q��_��]�1�'R�����+{m�oT�H���v�s��(�>��^t����*r-2!៞���},��紦4�ͼ�����{���$q����|)��NB��:YC߅+'����,dD6��z[��c7��:�=ߍ�_�D\1t���Jp���BtF�4��/�*ǻPJ[���k�s׆������+R��邓6G�� �W'j���\n_:)h�c�s��Ў�2��m����I�4��µ� \��:��h)LF���dą��� �<}�3,Z֐ʞ.�Gz�ϱ����&�����w����"�4�/R?�Ze=\9��׍#T7Z�?J�*�]�x��'Ϳ
� L�s��<�������`LV�K�5=��ˠ@�vT(?h�Dk��T�=�yO����Z�}H�T���i�W�)	�}4Jg/��O!f;��� ���:LV����\����ZS���şe�?z����m��m,�}2�M��E�|E�_�+�+0m�On�x��jM6Џ�s&jb���p�0X��hʂXڊXE7�Қ=n1�ޛ��*�Ǵ��V��A�A�e5g�
�v��
l�7��ަ�󠒰�NH�Y�+D6��|��v�-SЈ�}���O�׾~3�{�e
z��t�!��9�$WF�^n#����ix�<�����,>���'����c0h�*o%�"?�\x7{��D��y��Ȃ�� H�Q�<G�hb�D%��������ITG���F���7Ȓ���FQ�����e��ބ2Q���J��1�5��B!F-� �ȥ���^��ևT��{/5�Ue1Y1�#��#�k����5e#%���S�l,�K��9	SK���њjj�m�ڸ���i�ƛ�7���P�m)�m��jr�1��v���P��y~n��ƿH��
"|�BH'Q�4<�VnŚ����w��( ��tܘx�J� )06�#Q�4�$� ���*�e�\��]�ɿѩ�D���5�rd�b��3���ŀ�� �cR$��Ӓ��e�46��k�#_���	Q�=�1�q#ؠ�w�_�[���z�����Q��NK/D~�^�)~����5�<��dA%��� aEN�l���O��7!�|��e0��5��޷,T!�v�s\6��e�M�6��Dd��s��-��kx�u�\�nHW)�����h���Ε#.�1>6l>�v���u�:�ABVH�=�Ed�۶�J�M�H[�6�u�|��񤢦���= "WZp *��b�M���3����^S�� $@��?^���0z������c����7��E�W&cq�������)��� 6���{)��9A����*��^��� ~%��@����{CO��������9c�@>:޾���
S���J���Q@b��DK��_�G��O�Q_�Kzh���Ƃ%����|�AE�QCg�!ٺ/�?	Aww��ϻrU}��Ļ�B�$c�,u]�g����7�2��3C1�*V����)�q���͏J���,�J�Ru+v��}�|�n�H�0r��p�',av����'��@#ν�3���:�=�ӈ�
�;d��Y�ܦ��:R����d!8/����&�{\�aC�\��x�V'#p���ZKi�IJ��d��'�X2&�G��S�S��:���
���W��ږ����a��9˖;Q�B8F�?p�U٠���u0̟���&wY�Iua��Bo���(�����@'resx���%x\1�E|�k��t���s�*�?���+�c���)-ONݧOXo-~b�Gf�����x\�W���ތ�KMlK��2�7όR팖��~��G��V�|���9M��۠0�X���3�\��R���{��dH��ndJ��4��C��3S�gmE yo�z	�Su6�����?/�پ�N2�?�nK�Gf갷�᪘<c8���H�$2���|UC����zd%��e|:��b�����c`�B�ŹԝI7�.�O�� 
�,MN�6��Nr]�?>���ʥ��
(���Z4O(�b9�ɯS�������u0J9�ǰR`���7v)��0�1�1n9��.jc)���{	T�F����F�FYI��K9�4x��,����&���<e��X�FX��q�<�狡��	̇i�ٴZz�%{�GN���
H~P�ڱ��D�]q��bߓuߐq��̈́@�QP���j7��&$��qB��#(u���_R&��~��[�O�x��p�\���,��Z��x�g_�GuZ�E��}���� �K*���p�^�Y��?�-
��+�G����MM�{J*s��-v0.����(�����?�*lV��̅Q[`��aq���Q阝-��$�I���=q����2��n�,p�@��n��I�m�� ��s��Y�=��W �Jҟ��TA� /f�5�S���P���9I����w�g��/�{v=.n�[�J���ӵ)f���(s_!w(��/Ըփ����/W�B���� 
W���?�c���r��<��K |^��|�Q���u8�Q�y뢊����{"Z�Q�����ٻ?4�����f��ƪI5�zF���2���"1S-H}<W-���V��q��MMqPɕ#Oi'i�NZF$���LվP�1����|�]���-禋Stw����_�_��ϮD8Hb���+5�T����٨��ڷ�L�6c���
6H�!弹�\�|�֒b�vp�����������3��6���H����b�ϗ0��Z]<5�p;�G�Q/����R�%�� ��4X>x<k��E���wu5~��NL�^��\U������	�RB墍���� �g�򦒙�/��>���.�5���_{R<&�;����%��j9����9LYF��,�{Ӽ�6�?c�_��Ѧ��b������U�(�+�֬g;�$�e\�������U����7T�$jKu*�j���[s��%e��k?��/�C������FK�獆��=���U+��KK�$~m*�+dJ���A �P�E"1 2����֍x����iA\�{���,Y�:���A[�(����2�6�h�%��y�	��
��_c��q��z��|�z�fJ��=ӹ�T�Z2��e�JcL��K^W��kx�d�CF�,��<��n�(#��͎�WE�ZDJ_�`�fE�s،fYR�oҝD�MޅK�e0�x৐�կ|h��c)%�d7Tg��+������$��b�����_c@���}���6�m�g�ޅ�N?����le�����S�C�ڶ|3հV�pj���L&TȾ�6��fs0��%u����e�-{�/u\�s�3�G�'#���}[�z�>d�h���<�����B�3�;g����)�e�6���Y7C����>2m�D����c�Q�˾�?x3W�
�#��	��2}� �U���4�X
�öx �Д��F��������/^l*� ������`�̽vR�D���ۓH���t����U�5���<��x��\�;�$�}�Փ��n�=�M0$ @�j�\�>�K��Hi.*���Zr�դ�V���.Elf~<2։t�Mt���
R7��	���1��N�gaN6�;.��+��^|��8�S��h���#�̛O����S�����t�4ȴ������/y>�5@�G�c�@( ���o�H&|��;��.$�B�u)j�d�";qI�_lѶ�ek:2yكtH��Ivf�R�r�n5`�'��[*�|%&b�ݞ}zA�t���� ��s�B�!�	d\*$����s#$YY�o����.��V��a��e-���,�$4Gď�&o�)������f�k5}!1x)l/�\<E�3�����e�s>��q�χ>]�1v�n��a}��1.�5��[��ǔ�#d15I�ؗ�rSm���r�����O��S{�ГS����^�N��{ڡ�!@��3`�����~�N-=�Հ�������x��Wq�Vq��h6R���]4��W|��o�(�[� P]��rk��_��f�+�,��³��G���,���[��d�+��ȄƯ�0���d)���x�Y�Χ�^;x���?�8�P\��D���["����x���:��5�2b�}[���U����I^w{�IQt�H�N��z��4st�3ӏ�����H�w�{a(,��n�]hɡ���3?<N��� �TIf�%{Ժ��u�[�N-/d�8~��*Ԫ�N"�§y���t t��9��	�YL� �(��C��Q)�|�y�,E��_v�U�wp5G�l|� �����I8��t��lk�;�Q�����O�d"e,��r�Km��a���4��(�����0[���_|n H�^�S(%�3Z�P�G����'�;��G����)/;�[��(��On�`����/�K����<�13��r���J5�f^3�^�}�E�{�By�TăzR���T�p����q��(������B�?L�k��_le���ebv��X�'�A��QRH3���S��``T�fpz"����0�V���h��LM��+�����~b$\_���Aq���õj�t�5�����VEm�o������A�Ғ��&�=�Cq1#PNr��a#S��i�ٚL�O��l��[yT�4����'�W��wf���0�O�=�0���}s�wa�rꢯ��!�9I�+K:�
��B��6�x�>n5�}������:��b�P���Kv���5>�~;�=�Q�_�B����~{���׏��V�]���3f,f�����C�� ����)��Y�/i�e��=)oP����(�8�ɪ2�v�g�!���1"�
�#/Do�A��{�)6�q��'4����|��"Q�d������b�n����5�,���+`�f4x�&��L�����f}�(ƲJ��+�W�'�����Tt���=yW��8[�Q�Cp�}��	 ���z���M;�q\|��,�x�_��Q�rYd��RR��Bh��Z4D_����/�K[o���Ր���ZC��1:�s-QZR�|q�6�,�C{�b(���u����[�_�{��;S�W�K�T+<{��>o��u�HHE��X��'�S.�� �ޜ:Y!?��	�m�W��R�i�� p����3\�kk�Z.�slj�vr�
^%�)��"fw�7����ȧ�6v���3\a�T��Bg�Ƀ�Fě�خ���)���eqƺ*m��}��î>7J�i���+��Ucu�?�]��H(�PW���������ՏHl����B�I��u����hҾ��u�����Ȋ~ٚ�uT� <=5F�]�|� %���M�����-�c V�'dlѳaHr�e���H���6k�X���J���w�Lp�VeG� +N��G����,����ץ���k�c�c���tْ�n�����;��fxf�#��L��{�	��H��j+H�;���;����ʐ�:3�g�W�Ѵ��9�`  �t, @��e ۡ��.���g�    YZ