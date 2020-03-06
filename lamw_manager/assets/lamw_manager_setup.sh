#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3691404558"
MD5="57eb9bfae441e5da121133c8304b92ad"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20732"
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
	echo Date of packaging: Fri Mar  6 04:45:32 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j�[�R��Z&�~��=��"F��'�Y~�ݜ�h`��>��L�O���L�6�<)m	n��ozǁA���������kE�c�`��RBT�s�#i���߼Epl��~�1�*��V���+�	��5�I�2�YɽR����䕍�У*N�&�zb'�!���_3���ّh�
c�#�3��5�z4J&����:k���s�!�!ܵ0�+0�:HI�Y\^;����k���m��e'|����C�!6�.�E����o>�%���f�Ad�&�%���*a̦~�3'3l��h
5�"^��w�SK$2r5��``��Xf��ԔcG;J�)��v�BSN[� ����V9�1���4� ;��%)�t��g̹��͙S,Fӛ/E6c�����
�~����T��CS���h5��������,,��~��;'2 ���i/��`qP�f��'!�p0�a�a )�G	ҿZ%+6al��	��aţ�U����'t*�{�G�b���b~�@�
�� �#�rPYL��'Ɓ�ë�3.�]4�qI�&��%b{W��*Z5hС�g��	ȼ�K���+��́V`�xnϠ%Cwn�s`>�c�B�v���@z�������4Uڝ���q�1I��~�8%���DiyZ�(�%H>R����٘�u�D�\��V�����3���p7nK_��`>��^B�Q�&")��̷+5�o��+��O����� C��H:�M�&
����M,��� ������ʱ�{�2���Y$�5h� >������_ʞ3̗+����x1�M��i���H��h�^a�5\�w�����E:�b�1�D�Χ����c�F�4�:;��s*�G�X�FS�����s�R��`�.�,=��I-��Mq��<�af�� ֱ��̿��#�p��ږ��Ø�w���"�5v`ʏ;�┇bWZ�2n$��6K��l��e����"�6��<:��H�j�Q�Di�N���$��pF�)��|�dZ4D\�őggS9�Jf�pp��7��ڍ���e`m��J�@1�%h�=�7��5 H֛&�ܰo�mQ�@@���ذҧ�c��t�����re���I^��/��y	-c)`^���lGU�Q@��L�9}��]S�u�6�ً%�E|�3�MG�C��<�k�&�9zP��S��W�b"�� C��D�q�r(��ux� 	>�&�:O�~}~w��0��~]cf����A�ʵX�:z����N�������J ��[t	��J{��EP2v�G�neaZ<X�0S��	�6�T��ez#ܱ���"���������,A�ɀ$V���^&����������N��:�+I�/m�;]ii;(lX�i���<$�BT*~���O��Z��pg��K�ؖl����^z�s1i�f����i���c陗��6
P~W�����ЊT��\9�K�?��Md��iO��0��՛VXd 	g�e��gWWt��7$�}e�P����˃��_j�(��{�-B�M�Ẅe�
�i��-L�LV?*AS�q�`�������'%#[&����]���U|�����h�ٵ*` c;�����`B�v��%��l9�?b�<���@�h�F�t��t�{�(���my�}#^F^��l�"�I�y^�{�R�(���TC
�Q�k�Q�h;Z(-�O(�[�=���) ��҂��q�@�D���G��L�h��Y��!����[D�F��K�zչ��&�z��u�myG:M��C���KW��r��]�>
G�,dk�ЯJ�e���hds�h����V9}x�;<N��1�IR�삞�x}�0a�2|�QǑ�l'B��ҡ�1�No�c�cu���3�vu)'ƅkG�dD&� �~1��wC�.]��'IB�	\#�]������������q�����`۲X���a�^<f<�r����M��n 8[��+���uj+V�)�a/APW,g�o#�j�R�ztN�No�|��J��ٹ��؛˭m��t���/�~��ou1/.��	 �%V���<��ѯ��jo�{��;d���H�3z�Tq�M=Y����o9ͅ�E��|V��������)�6�k�jj$�D�S��"���#>XKzY��KV̥�Z<���Li.ʰ�ڴ���g��?�Q�懄�X�
�'*)�jD3� T/U�`�Ĥ�|��w~7��ҽ)���1�5A�� �e�]���d'��*턥��L�v�Y{�s��A�Ek ���P�����Z]k�b~٩��n��p�	2x�k���1����k{��4�eb�eV���=���|.a�-P��H�ga�ܠ�z_SK�{���!���0Z ����7=BW�����-ۍ.����f�(�Ht	!l���W'K�V"�['�k�5pS��{���"�U��7�TIة
��p������-�D�G֦E��$ ���o_�N`ܷ�G��`[��W���|%{m�pf��>��,װ�>Upd���%	I��!��:�#�k�E���#)��u�6b2i��o)B1Uv����K2֓y�)ŵ^g0-��y8��S���̅ir�0�1��R����h18[�Hg���\��4��-��l�4fh�}l�o,Y��,tT�m]P�e�����):��b��dj<�1X,G�J���|�jYP��LŬ��s`�>�#�E���!�i4F�R?��r��*��-ܯS�+�� U�tEe=��ƣ��H��X�6L�jD	[W:&�g$*��� ��]!\n`�#���J����sm	�lP�y�Z�����w�?���AYHD�Z��� ���������$�*m4�C�ϒ�Ӗ������3���	�����������:[_rL,L�c�!∔�T�4�o���w��U�q�,�ŷ9-*�d=
w5�Ixr��jY]N����l�g�Ε���%����T��¶�;wNb�l�e� ���e�{p������X�x$r�|9=�]��8dh��na��5n���@l��;B�$�����d^������v�^��w2S���qRм�!(5������|�w���U3�x8n�Eg��hfz�'��	"�y��w�l��`�xy*��4s8cѷ+�@|�,��Z A�+���3�u7@�a��j�X`�I�	���B�E��c���o����C�	�'��5n+����c}����	�O�:���>�D��:�J��E�Χ/6k�IU\�;̽�Yb,�)��2��lH�3�v4$A��|�͕�?�Zk@z)�s(u�M?a(�i,���Q�@q���}�;aM���>��-���I�H�V�T�'�A#�lQ!hL����H�p�(cF���eF��m���ϥX;���\����j����2ա_�X�
M9��鵋��c��jb:�����E}��������X4��VU�r"���Y"���5f�?6������Nz�U"��we���+�E�ػk$q��5��*��`T���4����X'T-��ژ�T��=
�{oc :_H����o!��~OI6ʶ�5eb��8;n�t�05�A�J*��?�mS�J,>=f�9r�1'�+"'�j��;YK��A�ɉF���PX=��f�c�1���>�b�)��|�F���YZ����!�x4�45t�i����{�SQ��Ɩ{�b��M`�d�~FڵԳg`���f�U����NU����@)�s�nB\�E�NNq�Rrq�C"�_$��\;rl�t��u�<���m(C���]�.I�sgmX�AB0(��9�X���cɚ� ���,U�R��h5�=� �b<ɽXݲ��=�[���R(�N�B>�WZ�5w�\^L+O���wZ>�0w�.���D^qt�Q�&c�>|�r>)p^:X�/��GP	�auj�$&;va����E�e�I���!�@��
�	<�$­2c�q`�(�ԙh"�	8)�.��1	7�����ᶦq��&'���� ����J��~Qt�j۳
��ks�Κ�� �|+2x[��_Ff��m������?)NEe&��r*�	\a��]L��Rsz����e���5�%����D��GJ��?�Bf-]�t"�3�2��)��{p���k�7m'�f\ tm+Q�os~,2��=������%�xH\Mkr�������`1*�  5R��2�NDIyϷX_G hv�F���o�A���8w�L"(���}w�<��%�`cNnjƚ5��g��>��٪C�
���"E7,�bl��܅�v�������~u��zҹ���21��|w��(p���L�<�E�L"��lI�n�:P��2��Xgd�KW>�l�/}�ũ������g�Z$�JdǦ9Ņ$�L�3:Miw�	G�`��QM�����z�HR��D��,I%Jτ��(�{;a�s�?_�}���TL�Y���-����_������6#6��`KP7ԅ�!��|���t�5v�C7.v�Sg4�SXoIE2`�I�p�� �*�J�lL��W1���*E�8�Q:E�'��2��2^�I�"m���,�`�Zal���\�%_X&�v۟��=@����+�E�B`Fp��[kc)ɻ̮Z��l����<�h�q���x��V�U10P��q,�nM�w��\� ��p\���O\�n1�B��ZoC�����Z-��ɉ�R���5��֮s�H�˨�M��&��*���h�0g�+=�R
�!�G�T\�o��.���x78A����#���ڃg]#��ڪ:���M��}��ծ�w#_O����
����<��м_�=8Z��bU%�hX�.,�7FO��!'��Cχ�b� aPRh�U�Cl"Y�r��!����_���������H�0�r�^�E�7S��3�xD����Tm���|���O��9S1`����K�BOQ��-""�m"�s��C����|��I�Yi��V����q���}o �d� ��d~AFK`,m�I��d�ѥ�C��n�;g�9IE�)KN�1�
��ѱ�{��W���-��~_�0���P^�LO��F�r~ gj�RbD�*�J�c�D=v*)���pc��4Mq��# =���tnV%�H�*D
�O���ڕ��&���	�����`hS��@7���҅P�"ˎWuLH�~��/3v�Ľ_�;~������I"���"��6oGS��8[L�%��J
�\U
d&;�#q�%�z|��>���-����Ws�k��i�ٵ��M�]�|1�S+��-V�b�\_�W/����SoW�������J1=i|���UY���H%�|��0�\��u�(�U�T֙.�d��<��B�I�.-ž��{�C3- %����/���>��].2�c�7Z�̔�S��Uj�%۲���l�ʁ�Y��N�xg���G9}���uҏ'�]�n���J��8��\8b{7T?�%�7I�,�Civ���eˠ"v��ϨQ����@m�r�m}����3Cs����<��F�V��C�/��9���-�@!PBV�&ր���||+�D�.-u�����6���	�]����WeA��|��_qz���׍
o��
�[�k�%�N�cZ�N�`Q�i�6SD̶�O��&u
�~��O�л���:?j�b&����x��$���Qt��=���s�lSoWK�1��%���Yi6ޣi��
wx��o��-�a;�<n�9ʹX9C��=�圦P���H��T��Ϲ�	`��J�̼��4 .vQ账�8z�����Ԙ�[$�	p�p�bH1�5AC�M=����VC h�3l�~��:��*E�6��s�,/�^�v�T��;� ݶ.xУh�&��5�Q͏i�3:1`e.��~b�������8Ӥ��GJ��(�l%ĉ]��I8_���ػDy�i���q��R�/�s��/��U���&����؁���O�E���A���"%1�g@�Cg5����]��{Ð��=�R�S���)���2������j@�mg��+J��TH��/@�@��g@��Z'�R�GmK_�<�w�<��+U�3;'��哳ɔމ^�v>�W���P��s�k����4���c��.�uui��D�Q`��M'�"١�o���x�����*rg�~YN]c�#��e9���Rks{������`�Z���Tg��Ɔ�KO�eLR��*�b���:C����
i����=G>�Üv����g��\6ؖ��f\��f�O���,�=Ǝ��b5��W�[Y�Q����,=����h�CVo�υCR5��.�0��\���n�u����B�Go��P��u��M��賩I7T��]����'�'V�y)P6�oP�8�ң�c!CUP9�/�:�
��	��ZJ�X���vgv�r����5x!w���2����[�y[�ʅ��
��hb\ϔ'{�-��wކ ��m��3�"R(�:���Z�ӡ�?�j� 06�I��㦛��+�(��	)� ��.�v��E���0u��$O�����hP�/&���!Y��8���ᱩ���9O�ć�X�j��8C��C��[?�HO����1>f?�4u���@4{Ӎ�G3��;���Gb������W��^�^�~�>���a�Tq��m�	�vP+�|NV*�V �����?�c����|�d�k�����p�'�7O����}v�IjJ:��� &�:���s}\]�?�O6�{�d�K��>��	7/ю�%�^ �����y����M��1�b��qA��.%�T6B=��#$��+7�@��\���C��[ĨH���q~�DX}����!qK������f�ͩ�I���S� ����r^N&��UIN����+�u�m�R�.�@~Xx��C8�Ī�iRK���ʮ�D��&�47�Wk��e�΁�b�1t�D {�z ��q�Dِn��?�uYR�8��\"�5�5Q&�5��*\5�1*`��Ug�:6H�Yz���Ή����4�')��*�;4����sIt[�7-O��M�_��}�==
xPC��y,�ضp�FjelXi��(���qo<��E&+���Q��^��+�n����(2So
���w�8_��<2vE5��z�K�Hr�=:C���1(% F�0	�e$FY�CT9`�3R=��h�B�s5����q��mX�D������I�lŌ��%�$1�o�k���' 	�^'����Jl���/� ��3FeW&�m	kڔNf�.�����wZ,��+�P�������'؊Д�>��Kåu	��h�W l��h��j}�uh�y���'�t�(��R*BՔFM!����8:Y�At`��o����F�����a�+�Mo$�&���|�ճAD����HLV\kY{�,A� �q�/�v	��X�������G�XTJ*���V���s�=��싪�b��	�Su2s8e�{�Y۾���j�d�O�:z�̫c�����wR��9ҿ.!jb�t�V)����n�Wx2��F�hg�����ۧ���B�e@ME�L����*'����W����(6�b3�:S�Y����e6��
Y#��,"	;M0�I�7��4څ*�8���fn�n$��:s0���8G�ߤh(�z���	ּ~�.�����1�x"�h�ȸ�T({j�g��~)<F���χ}4�)�Mz����Ea }!=ԣ��̉xg�C� ��>X�$�lJ^]�!���{�mv���x�	���d��U���ש�jmľQ��ޱw	��I����"�� �G��<m<ziݟavqgY�7�K?���:�h/���3��O�T
� ���OU7u�c�!���z��-�I�����.iz�Ӌd�����cqd�9A ��\T+�=[�J%�%Ŝ����o鄟(3���9�hʨ�ޟ�E���1���+z�G/T]L8َ+���!�+� �k93��~��
ms�B4m�	h.@���sDC�8�W����Y�4��9�U��k���,�b�����/���䞍�ڞ����6Ұ�����ٶ�5�q�c'1Br��}�J�BU!�	D%�x���4�Tz&���nѧ`P)��@�M���*{�@�2�EFW�0؟�ʏ2��ꟕg�;�ѢQ|~l�};Ǚհ�K\�(���֬��O7���m�\l='g/����c"�9� sF��4��M���:c�j�7�ʹ�Fܺ��+O��+�W@���v�_Q�����%�}��H�g���/T�ڲw��}ť�(,�O���9(E��cL�?d�1�|��|��n���I��ĳ��эXm�N�����=���>���Kҹ}��_|���2]U��+��q�ش�LZ-���d�?O�+�Y��NH���;>�����T�f�U>/���V]��j'4'��,̀
J�N]pO���]FA�&Z{~�R�&?p~Mi���-�J]���k�͎.fZo�_mx��K�����|q,���|�AJ[^�ע�{䟏������1+RA(��R*�;��_i"��p��;���Ҟ��K'9�8��Y�$�w��sb��?��tp�yU(K��X/׃��y�S���Gv�f��hW�'���wR��� �߹�/Q}<�ї��I��\�?��o�e�a�YV�y�b [�4}���l4�y����z�X�Z�1���|QF����,����Gwż�$�����������9��F|n��M� �}.I\�-���}Ñk��ݗNʔ�EZ��H�]7�w�QN�P1���k�,�(L��G"�7�Y`LʧUx�),�ړy1���2�5,+�����T�Y��R�+�����;q��C���W�'�h�$���O&��Y5I�5�&�-��v�K��
�shR=r�CS7X���Qpħ�u�ZR�(ʾ�� 郷q)���&$�����-�GhW*2Խ�	}?����w���d��&���YZ�c2��3C�ŋ-�l��i(r�B��&>�-(���}2x�D"��zU*Ό��sC1��P>�j��F���������ԏ�Q_��?�'S&PH~!͵�ʂ��&���B�4��ԗQ]Lh"ʚd��Cy�zv���NPs 7�4�^%��OZ_U0����'�6Ί����u�JQx�JTw���PY3�\��$*/J�G�sL�su�P���=!�q_�(Aĭ2�#,��'}2VD�1���5�I���m�DLܿV*���6��?zӮ�zrzV��y�b;_���umP���?��@�=�����#���1��B���F �wr�KL��Mi�%�m�F4h`���d������Ϟ@����s=�/f� �U���������DM)�z�9���W�,\�L�Xr�F2��;;�Dm.�B�LNNO���m5{�5��U�gyd�>5h�y��zj���&U��c4�~.�L��,B��m��Z�O���dy�?�F�?�j��5*��� �^�=�LH���0^/�.<@�:'l�E9
�2)O;�.���8�J�����0�>66���f��6Mz�}���Y}�am�B1#��"x+2^ٔ��]D8�|$�)�3-�.03��"�����g��u�A�+��9w��F�f��#�f�:��òPO�*�����Æ�d߳��AyF�.,�y� %4���8����k4a�Ծ�V�<�rkO �?��yؗ����,���QJ���H�Rw���x��		���!5�d�����D�vް�Ql@oR�Q5)]D�4�s�iOO8� SFT(��u�������ʤ9���瞢@���¹_@�1���wQ-�)���Cөj~���k�}�CD��[4����'���>5@[���\&��Z"�Bd)&���.J��G��f��6x�"L�<�~?t��IЅ|1��˲!������G��w�I��p��u������>�����f�P>w�ӥL���aO��$0ڐ�ʟ�<*@;��U�iҎ�-gXjegt��Ê7��]6f�P����Y�D�I��u��d;��>� !s�\�+�mR2����[ܥID��^��X�g(��~��Ad�<�4Aу��r�׀�G'\�S��{86o����Ș�.�7��^�e�����`O��o>�W�KCܨ�CG��&W^o��In�s�-ߵ G�1¹3��͵o�:m�
�@j����b�춛���"�b��E�찺m��ŶX��K�Pibp�"��v`��( ��q5����b�VAsB`��&�ڐ`좸U�R����g�����2����2zx[�;6є��Ub��ZE5�����z�m��Hvk�v�	�#���
��^���l�N��� �!F���yh+��ߢ����c�u�=6v�S�oҬ6MKH<jఙMҦ�Hl� �� _��[��RUby��D�n��g�6ڮ��ӳ�`Vl�_��v��!�l��v^��\�j;vG��F����=����q`��u�P~-;�(ˎ@��C���b��,�H��<,Tu�b�'�Q���w��b˴��xG��6��	��c��Xz>��"i�/��|8t)��t�v�w��nD���t ДsDȇ:�qT�:���+l�ݸt^�+����Z	Q�hE(2��Ġ��%r��9P��vU+i����l\i	�mw���{j�PC��lU�:i�����h�J�2�S,Q��&�d��0eA�^�z�l�sq~V�ɩ�a���>{h��`]G�����>����p�Μm.��&S0F�R�~c��zZ2E�ߴ�|����Wjy*'�S�$Y}RR��j����[���babd��lt��"B����oy
@����(0�� v�F��c����*!�=� d���s��I��Q����c�>[S�dz��c�����m��M��y�SI��]y+��N�HeC�O����4	��F/�$e�~\\
��F��y`�M�L���ݬ��IHh\] �6�ۉ]?8B�q�y�,Twp���G�ꄗ���^(Xc�TZ��%�쉲Iw���7�aNz(���5��z�x�@��"�$8C�d���0n*���"t���z�����4RsT	{�>��������%)���}=,o8�=`��L´�>���~�5����ت4�8�HQ9��<畹,�ɋj��Z� �=zi��9vBD �%7�C!���#g�y��ٸl;?�o|9�&T�5I�a�Q�߇�����-U~�e��4��b�f!�������pR�'-x�j^��ք�����)��ߛ���Z�u�#a��D�E�+ԏ��rv����2u!�]��9��o�Ȍv�����e��=qRw�P��e4eH��jڭ�``k[�fI�L�G�$q��Zi2����-K���v�Q�Q�;�o���PA��ħn�����ɵ�TLQ�QA��XxpaX��5���}͕��dnk��`�0�:�V�ӣ`����6�Ԃ�n�&߶9E�>*+��ߪ�]a�!�0*f�"��܁����d�W-r�d)蕂�S�a$�s�?�!�K�>ý��J�=�(�?�̱%���:� Rۚ�>R�N�{���f.jMtO�o���ׇ�L!���&}�(~��D2��?F�U	qv�<H��{T竅N9�eԄ��㲰����!�j�[Y�/#�n��!a�H�O�`��~��#�78ymR��C="�|j�*�L�S��@Y�DL�u���`.�揾R�
���p/���w��D��`��p�ĉ*�*r����'��G�q&x?�DB���Xj�����_�把V�q^������ܐQ�M��\`��1���=|�f	l�3�C��%VB��cECI|����!�Ϻ�A��õ�zF���k��VQ7��/���i"w��2�Ĺ�?}F��{�N"��7��0��q
}"f=mW��~�ua[֟C{P��v�%:�]��Ӛ��5�Tߡx	`�m�x�R*�v���;2�"K8[���� )Bf-暹;�n�5�Ү�E��PM1:�F��z�^�����Iy"�'�f!�+"r�H^� ����@GB���{��|ݼ��rKE��*�ֹw�`��c��am�P��Fy6J���r��|��?h��ο�SO ��==^��֡�/�#�����R,���2�5�ϓ~H�cb�;,Y�Yn�q�<��]^�^Ț��x��m��*��^�2�<÷Ō6\��nV6�k\�Z�����/�Pu��T��=45"�.��?̩�]������a3����5"Si|;�^�R/W�{�::LH�a���d+ty�n@s'|��(�^���e�ΣE�������T��ad�^���L��,g���Ν1=�N�nG<��:��а�wF`�'��"�4]��q&��/9Mr�G�u�p\�������@"��7`����aQ�k7�'�6�yf�1P���d@nX;K���.�T9�&�����c���z���A��	��[i3^#u�>��D�Gn���u�M7W��J$�7������Ƣ!���HA\3w}p��Ӱr8��p�����WF�h��? ���c���EL�W�y��&�����J�(�&D�1#�}!	Jx�H����>�3w,̈́�h��P9�;��h�BP�d7��OībZÑ�~�⨥�rϔ�� �7X�^5�,ǀ���҂�?sC�s�J��r�K�V�� :CiB&��`�A�|U�s��篝��L���4YDZ�������Q"߈C�R���ˀ�+p��@o�x��"Nww�̵e�ɏk�Ƹ���k׶������]��K���j�^�l�<�����z1�� +��E�\b(1�p��9=RƌI�rw[༲S��ON�7�˟��|�aҕ����[aF:�W\Bs�1�o���ު$*���5<R$�c˫m�h^BDY��/����B���ԙ�0�y�$D^��X���u���y�W�J.�^�@��������u�L��cKoh�s���Z.����d�f��}`�c�ЙJUV��֘n�/�7g:�L-���j�(�ju-��0��`���Lq�e{��](��Id��m�Yq$F�#�Rm6�Gi�vtG��H96kܣr{�̹B�<m'I�.�/�3���T_v��G��T.=�G�?]�P��i"P]��ێ�W�,K�D�=b3����$�����b j�[$��� .��� ����uUH[�1J൹y����&�%�t��"�<���ұh����H�)���`�A��,�������ln�P����6"Q:�
�#@�c�����7δ�:+�譯`�����v��ch<�~�<�"z����I��%G�Y���ٔ�J'��^��6,����$ػN� x�)�/~T1�(`��.������Öd����z�v�(O7�2��N�_ٓW�I�G��h�N�J���7���(���"�_�Q0�Q�*������L@��F��$�3M�IQ��Ț����] a��}���
��X���t*5$m�|  ��K��2��d���muP$���Յs�Mp�����5���A�D��@`�KTt�6�㣁AP�dIޮt��c.�F����î�b��ei�Z���]�&�*�:�G�1f!�͟9� �sP�fQ�5��f��/�@/�@���6��P��"�� pE����(#*�?ܩߥ�1��Sv���:��J�~fr����*|4�NZ]��B����;�>�x֞���R��=��T�Ї;�0u��Yuؑ���W ���Ǳ��D�E�a�|�V��oth>�[�z��-��4��&	[�NK|(��iwvɉ��;�KԪ�ke�g���7P@!��Ш���Ȩ���L�7���~�ߊ���W�ok*~k�|�vӮ���f9H�'
J�oߩ�ӟ�G�gHL�5D���Z���4�`�^)b�5�/��͐p�X�P;�9��R�s�Z�]���r���/h|Ơ$�	�Aq����̈́g���Ё�3��E7�nS�g�Vœ���d'מ�A�]..��~��\+�*�)t*�^-+"L��v쒁(f��o��`�$S�ì��z�)M�W+�FC$�x�قb������7З}�[k�Fn���'b�^�Jۖ.��mi:ʴ^�H1�Y	AW��5�ѧ�oS� a���ԕ���#���j"��9"���8�%���Z���h�� ��A��4�Hʹ;3]����r�z�@�w
;sCH�=5����ޏ#��'W��fYS6�|�����IY�[�����D<�0����������p����o FT\KOi����;��R;;��Jf�;Q���]@q,@��#g����9.�M��C�;>x���o?�7��^^��P*��r'�e�!�1�:���� ��ą��y�&	u#t�`�N,p�[�ȲH��<A4����%9���{V�}�S�K�fZ}�&\�S�-��h*j�e�ɤ�����te٣!��Т҉Vf�o��\\�H�'m�?�텮B�3������S�����I|�,�w��b�dnu���S:���YT������F�L���|B��DR(������t+�����*(n-�0c�P0�=?��kL! ��"3p�i������@]��|l��<���*5,�-)��Ϝ�a��a�\�鴤�be�9h�G(\�1�Z��D��!��O�H\R�V�L����;bHIO�Ou6����l�ޯ)_����8�;�-��T:i���	9�^��rm���QzKܢ~����)7��n��O�,G�w�Fᧇ�����7��^�7��:�J��2���E*Ar:=3zS���b�G����+�C�UJt���P�5e�+�:��=�0�4}���?�!S�d��Ϣ(���4Иq�L� ���7�R�~�:�,�
m6i�sc��Ӂ�Y��ԣ�;k۷9V��;(:�-�|�}d����y|���\�C\����*_�e��}!�=ܷ@,���\ъX2�����(R�6t/���S�n�s�"X��'���E,
�o��5�]�&�$s�+0&������#�pP���T(����7IƏ�Z]j���%��~�:�>Z'�fjI����Ea�&���@)3u�~Q�߲uxώv$�l�W���}D ��%$���z������|�Ǚ���7@2F��AM�����dZ�<_D���"��4�@��r�@�V�� G��d���b�a�ٮ�	��=E_���^l�I�e������F���@}z}���=H�|Vn�_�	�h���5�B��w?�MM����/��؅�'�ct��&E��n�����BPZ��Rŷs������7	7�XC,�-o�b5E�;�ʫ��!�^����,Dyk��uM�xM�O����M�&ˬ�/&+���f��B�*Qn��u�S��U⥷�o���#��܇Q�|��������Dpq��<"�gZA�>/�o�A�*�DJ��"��z�ܓV���W5��`qe��RO�xBn������p`i�O�|�g�w�nf���p�ꓫ�����إG�`�tco��cNr��!To£�i6.DT+��xWϰ$!��撷�mk/���������Q!_��5ɞ�`��u��#�IZʽ�4�x�`_5a����W��ŢdY�I�;`y~J(e�p⟥o�
 v�������(׉� �+����~�]�c�s[��Mt�9�9�f$�v��Τ��N;q�L�����R�������Ue����OX���E6cE*��/((cp��	���OA
8?�m��-����f�U�����g��� 1��(�|�����1K�UU`v�5I9[U�>:uyx�p+��XS?K^K�.�Y� C$uş'��AHڽ	���;��{���A��2\6��*���}��#�p�&����H�e�0~N�%��R�l8��p�_���Ԭ���m�*6#�B{?�$#�<h�{��`�#Wҩ�f���1�e޳)Y�:5��Ǧ�j���"�7���J.�l�9�Y6 F;࿥'ѻWG/�l�	��{Bvl�U���Жr�a�:8m��Zh�фdg� �ڠ}�����IL�\C݈��Ч����c�Sj�Q
��/�H��ߝ��&��@�Cm=�	�#�9����l��=��֛`��7
���[�|.��qLJ�(LG[���lA=o:Y�0�Fx����_�d@���d{�2��5���X(q���!�����e�Ib�~��JW�q�zl�D���d�{��S�(V���~��+�BD�5v�-
=b�:FS���_m	3ƫ7$ 
f�� ��p�и���Nq�1��抈��D�1���ⅈ�K0�/8� ���H׽/�&U�Y�X��H��W(τb�8
n*�4>�	���7���ǉ.fo�Uj�4���k$`-ٴ����l�������n=�y"�`�Wx��ҡX�H!쒮����N�x��(E��Ӵ�s���#%�Ӿ�Ȍ��I���P�����w��0g���c��lc[C�������،�8�ϖ� �÷hP��T�Ǹ��d�6���c�;��Ù=
v9=�k�1���+Rq���AG��@J�2w�*	X�΢�b�1�Ɠ��Ҋ���n�BFEihW;+ό��/�0Jpu-�G��|�.F X��-�(��oEV|m/�!���2KQ}
#�ޖ��*�c*S6[[�r�,җӭpp�}2���R��wa��F�`=�:�wAHr`Fn�Y�gS�R*s�R�x�|A����>J�P��S�z�����wG�����m�/q�䈠���f�1���<+ΏCt#�	^�-w���?�z1�+�~�i��
X�@��$�O��J�@�d�뚣�s��`��og�8?q�I�:����Q��Ɓ��y���o�"����xzJ*2#�����ɟbk���6���*^�˼�V΀=6g�9���� �[���e�~�_b��������cfn��|?�d��qv!󊌴Z � x�Ô���t1���MÌY�I'X��(������إEK���9�
����ۑ\����ʎ_&!dyK���c�e]*E獺]�g����Z��_�=�V5���`�'��;G�r�}�7T��um�j�	�+��<ytg�V���օ,qSc�*��̊�w.��C��nWn�:t��J�[����َ���3�N.�K �I�)�j/��VD�nGV�r�u��L��Q3)]�Z⊃�{H��3s�8�x���?���,�^��'��z�⏑�x{%����9mQ�Y�D�-~�����!r���dA�pf����co`΀����S���a�e����S��<��\Zcy﷥l���p��C�X���?G�["#��+H`�;N�$��/"�����&���&;�V��W�M����9���d���K�O�p-��L����o`��P���lR[4v�(t��Y����R���o+P�S �;�<��Y�����;,��C���41����PGݻD��k��Sڿ��#��^�ܪud�쇷3�[���2�
��8{�E�@9ُ��~�h�A����q+���Ph��#?�&�k�������^���A�Dhi�6�!<�<��{=$��+E��%[�F9�M��<�'�b2;j,����8U��v��j�^ 2 ���/&����ن��-�>_Y�YN��_�"�.�P��q���d����.-��ɧi���'���L~�6bG�h8t�f�����NWKY�/�Q��B��2��D_��hdI'���%7����^�!���U���"���+�;�����)�T0&6���Nʿ������T> � � Gh��C������3���A!;�j�Y�6�7ɼ��ؓs����Eԧ�'�l"�3��z
�*�K�<\�)������W��������0�\<�c=O�84�T�8$k�ɴ`yj�Sw'��Z���r�P�B�t���4����D����4�Z�����n�M]�_a�"���'�[�hʧ�e��*����<��]���p.�=��_��WUR(�&��dM���+:��;���L�N9JO�zw��åR�����{6(�ߗ����������׽'0:���ș��\���)mN�m��t�}�&ok�N��/�g�|��]�]�,�E�)2G��?�t��*o�")��=�?鯦�u���(���:(g���]�h��؞k�"��"�T��%Gқy����"���>��!쀊�99D�������,��.�	����K�3d*|�+�o��6�I:�����!pH������k?��0T$��{t�R}DN^��<֭Ÿ2���N 2C��-[����*�6�m���F���p/�A�:���~����d��i��6�*�łAʻ��SP*���zi�=�V7ѓ�7.	�{k��Mac��؁n�n���7l�Pƨ��U�g�E\
�� 
���£�T�ƈ���F;$jL���1p6���D�#{qV	���Pjk-���O��c1{+�w(x��0n�:��g������j���|U�9�S�Q9$6���	w�����+�	]�bŕb�ԩ�~*�x���ɑ^�փ��0���O�_���Om�'��Ɵ��b� z������V4�Q�S+����
����!=����&�dZ�S�h�/;dh_I#1�,0��Mm�#�U�W�\šz��vkHF��:��z/��t���33�ƻ�W!��3��.����T� �8Ca����T�޵����I�l_E�-O�S��J=Џ
Z�7��W=+�۝�#�B�졄YH�[��D4S��6%�8d���p��|o�Ԙ��g�n��o-tu�:b �κ�2|�|9��ﴋ�f�� �+I�А���~`��y�v�e?�;�fO k c		L�10*q�h�����F	H]A�J� Ĩ��Bx��=W͜u�b,��A���|�C��؍%�P1&�n��'�-қb��5FE;�s@RNлf�%�U��C��bK2
)� ��*4�w��'Q�}3L����S���{z�<��5@�S�<]
\��n+�F��G�V��"_B��]�`�*�F/�o�+�����TK�#�5� s`?�_�Ȉ�]���mH�U���ro�~?:��N�ة�����B����O}�#8Zӛ&�05�����`3�Y�����춙XzMt%������� �SW���7�:�唍��5���A;t��|?8�Jk,1�TY����&��Ri:T#o�waV~��L��W�2����<�e��8]%�K�'4db�ƔM�/NR��Tڶp�8���-O��đ�y������l �!G&��Ṡ]W cΊ�8l�u��x>	��ϽU,����ٿ�`�8�$�����*��d Q��97d"�hF�䧑����߰��� Md�ef��G���f�2�`��d�]X�ЏE���R�R��ȕN%Kv��] j�����X��y\cR>���_�$�1v�"Y�!����5�:���$J�ዓW���h=G���(�u��.mS�q���Wt8���x�_ouY+`
�T��o^���X�z����|g�\��������c��'�:xx��^@��ȝS��-K�{z�̏�h�d42�Wz�A����i�*�d��eՙ���������^%�ǲ5XT�������5��/�N�)���*�*ܣ�8D��Zc()y��}�� c�L����&�~$h4�2�#�������u�w�8xȰ8з��*���v�}��G��¯	K( �ֈ�ƽ�zfI1�X��0�mU���V��q��i�W���6�Qs6>�� �"C+GG#�~#��|���w�J�rd�6�)�K	�����="����b�,v�Ie�7�:��J�{�:-�I�s�ϐ�J��J�(�zV6?�j��������[���(�`XR��!b3�:�0e�y.�6mFS�VB,T	���'<�[E_d�tez߽1����zK�Y(me�?Ɉ޻�$�x\�>�gq���T�@L��(UL+
�`�N�R�	��^MJ���-�x���X�/$;�~��ހ4[���'���q�1΅n�E ə�&-X'���E �My�]��w�
j��>䭉�{E&��nY�C!p{�q*�P��Z��h8
;U��#�f�<�at��ǿW΢]�MB%j���ř<_B���^wnE�ɺ��VC���rQ�uK|!�[��y�hrx�)����kQ;9o���.�S�N���e�jt���ڹ{�� �:��^��e�e'�%x���Z�w��r��/�~�J<*�p�D\���K�C�9�a*T�y��C�%)�27�gt�5������'x,Pe�6c�,�`^�7�~����jC���X�t�����(F�[��DrV+�	�dN8�=p`�T    *˚�n ա��^�ұ�g�    YZ