#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3346947948"
MD5="afa88f205f8ae7a9ebfc5629c062235f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23172"
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
	echo Date of packaging: Tue Jul 27 16:01:40 -03 2021
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
�7zXZ  �ִF !   �X����ZD] �}��1Dd]����P�t�D��~0A>��O[�j];\,�i��=���q��16��X����|
�3���i B'A�	���O�V��h4����w�
8�e��<:N�<r�,���*SC�_��y)��y��#��r�w��^0�)6ML��e��J&O-�L��E@�R��QŎ��-+�0G�U2�.�݆B��� ul���Q���7���8��l��g��x,�G�ӪX�Q%��nӢ$���}�asp~��D�0�&Z胁�g�_A0�B�]l��L�J�ԋ�j�Y��:���$\�Lr�Ց.[���}^��C���W� ���i�����/<�u�R|�z[0��������A?��DW�^:�:�3�x)�0 �����#���XtG��ʮ��W�W[}������}�DH25>|��6�=]x)�^; �U�����<�揨�����ѤǄ��&
ʨK��"eE�"i����h������,E-@ݗ�Lx�dôv�#��S�X������Ww�<k�<�g������d(�b�Y�'��Zg��+b�x��{�
��x����d�O��5�HJ=���"3�d�A�V\��~�cN�z�������)��/����W,����Y��wXJ`�J�֓F�.��h�À�	�k�<7'h^d��.xpn�Kz�����5�̍.��
�n4�J�ŘqyxX�������55��E�6�_�k�j��ҋ=��Bp�$���nlP��)�R͛�fS���S�.zl�+`�U�pj��z.�ǆ���+j�l�3FY;��^v�4�������ȮT�+�t J��̛���E����ܟ<+��eE:�[3��'እMV? c�9e*�DC,��3|u��7� e��"���Uܝ�+��7şC>L���([���K�/Տ����6[�I�v�齳�v��8��'��zX[��sd71+g���D�+X�h�c�:'�x�����8��:��t�l:���Ik�I�� mA�봏�Q��Yy����ǩ��<F@�����L�U4w�Z'�=�E;{��٥�Q�3��лi�}g�Yj�u���yPŘhij%݊����)w�V�=�>C�Xp��2=�3�B;ux����?��X�f@�/>@�D�8R�$Ю������>�}7�L?�+W�Zf��\�Ρ^�#�q�0p|vU�C ���N �f�.���<fr��W&$D����Xb��"w*p�š��c�To�Η�!�Q���q>|L���h�*�_�lI����ّ��G�ShэL`������ZO"2H���\r»4פ1� y��� ��ϝ{�Nd�XX�V�_�9Yv��]HI�5c/ƍ0��"��e���7��^�W����Ih� ��3�Yj�qm1����stV����g��
���E�3i��0��VBt�k�t�:*����>m;�I�Τ�u��sx�L}��_�I�b�?'D�Rȭ/��/������'���S��?��j~�3N}�w��:�ѭ�<��(�9�ɇ�:�N�%en�iɢU�&���	�Q�M|�-?��0�  ;��?��s��C��!�*忝LA�h�;��u��X�骮���ȩ0]�[�u��Q,� K�y�w���	h��jUH�,�}�T��fw��2�A���S0,�ź�б�VAš��m�������@�Ĉ�sTjZ!:滇w�u��p����˽>ٱ�ѧ���;���l�;k$�-m�s
e�4�l�MtW)���?`WF�Eq7g�ܜB�x{r��c̨�mh����~ܗR,���9����Z�B�#ԓ�;n:=z��fx��I��ĺ�
X<r�!�1v�v�p�FR�-��7�}d��۪���T��s	)�t��0�̽Ɉ�=8:#� ���ӏJ��&��|Nq�d���9Z�Q�8�{N�OÉ`vN��ȧ:+1Բ�WH0A+���=���EL�`�y��#^�OC�2d����%r�Y�W��g�c�6B�:��Z��O�-h�r\|�@Z ��SB`6�c�y��f���T��N2�g�w�/���T�}!)0S�m+5uG&��ˢ{"ڎ��rՄ���p�5l:$�SE����~0j���������̦���%z�	�����[r��V`�)��&ߌ���VqK��?����L<W��k�N�A�o�n��Ɨ��Pr9��a���K��E�3���F�]�̖ͦb �6U�`�Ӕ�\��(���_j~b����X]���T8]UQ�m�*��|��n�磐��4nh���,������L�Lk[�0,&��f��h�p.P�|{b	Æ��ٓK�����m��rS�1+\�n�@E�+aD�x�b�5�T��'���d�t��P~DX*Ӝ����^��ZޣÐ���D+��+���@�y@��I�u�9|��H��������OC�`v+o&�	=y�	���Y��>a��7�Y�5&ؙr��fO���<%����d`�)��1ǳ�b����ջ~��:�ĳ�vd� ���q�|��1�p��0�C���;�����tEj���nK�t���T��wڐ�ø�w-B�(�	�a�H��w'_���iʌ����@�V���u�]K��߉%���49��l!-��Y�5�8� ��xD��Q��s%UR+|���2�1m,�?���2�=�`]� ��L�f6�8$��h�^�m/�6
�Fq)�𺐈lf�{����VY-�z�`Z�yr+ *���g�. W��(d�Y�n�xo�>�yp�Y�o<��⎝YczP �L��3@K$���zJ�ܣ*Wb��fI��wȷ�l��	�1ک����4�[��^�nT�P6o���s,����}�m�B/�H&�X���8*�1�4����q���POP�F�??��iz�]g�����v��v�a��[FÛ��l�0��k~P^��p���J3�f�O���n����:}w�1f:6�ZHb�S�n�0L�+x�t�]爕�����Ȟ���+�n#"�m��x����_��d�@`/?DVQO�䙆��!�u��.**dY�3��M4H0.5�)f}#K~F�ʄ�?0������"��$��`�����3�^�b	a��� avx�C���B�E�cZ��|����"^JE/��#b��F;�OO;i"U�rv�G�j�Xd>���Sв5F~�OK@���	��ok�V�Q����b��K��m�-|K����:ݼ�di��˫�1G#pх6VVh=�,O�*�#�W"�yw����^�p�� X��퀗��0���.�$���C-���Jf�=��xkQ	ڮ���Y�5�S������3��C,��>3 "���I�Rp�����4E�*�q�mK��U�9�Ч�?��WE���֝���̡����F�r�@6S���&��(k/U��H��U��	����K��F�@���Xb0Y�@����Y�N�}�Y���TN!�S�
J��BU�{�
7�?��o߱��=nH^�Z0�yV����&s=��ѹt�}��DSVB��4x� �N6�|�F��I��d)S��A�%2V\žv��H���3@=S�!��m�,5�9yeP�����h����%s�����A	�f�5L{���϶�
��u_:~�{����њ����~'ı�6�;�3�бaV1C���?a6~`��<3�8&���G�_��`[�����$��;��6�ⅺ����`c�,B7M��s�|�{7���}A*���hC:ɋS?�z��B���ȧ����ϴb��!���B���Ox�̈́'~�_]���D��?ϙm���>]g������k�O�{�9V�u�`�SAYG�Ԅ �6���u\�`*�
!�6~Mol!�60�?Y��g��(�UԶ�"Z��ڵ�_M���صe�����S�&4r��?v�5�p������M���-�L�,���S���`�����%�o���+ڏ1���J��7v�б�?�C@��>�)ɼOvj��<�'��rՖ�G0i��1�M��vn85x�%�S@g+��+J��e=-��I��:,u�W[�b��;6	`߯r���	Gn;��Çk��{��eO�)pk=��[��(��e�Q�EC���t�(�SO��R����i؅T�-&��P ZHZ���C�/����u��9�c:����D��wHv���g��:�&�^�?�xW�l�W�)婝�e/Z{i��8�����K�8#N��l��*��Oq�ͭC��m�?�������C�����8��~a���\�Uhї�=�����&m%+BV����ι&��)]�!��˂�i1��@��A��a�ّ�}n~�w���2RG�C���Ŀ�����|��Z#���:4.�y���7Q�	��^��#ί%=��f���a�)�]$���<8MCS�i�n�����]$B`�7.:�l��J�R�܌w
��+��B`��Y�a�ғ����[�����[^�;;��Gd�c��(�}���f=�(�����X�QsG=�	�E��.G��$�|�Z1��W�!��`/m��0|?�FUE�S�x�=fx�y̷[�d��g����ދ��+�P\0�		�NBn��>¤*�|�cT	Oב�$��hx���rO(�R��i��n�Ё�ֳk���L��Gs��'��nJ�����uP��2p��k�e��&?�ݠ�	�qD�ijl�I(~����i�<e�Zq�a�j���=�qD=�f_�*G��	��������ZH�jt��/>�WP���%M�&"#��~9�M}���<���#���
�Y��bY+��k_^OϤ�Z��QH����	�:��+L�
�V�aio:J2��۔�\���\M��:�5��}�2�U��c͡+@+s����c��b���ԛ����c���-� QS�H"�c2`x���~$��-����@�x�$�_j�����~�b�T[���A��^*.�����Nq�c�@�n�]N1��~4��N	��)�:���� x5˚g(E&�X���i��I�ӮB �s�$�L�up�%3/���D�K;�?�j�wXǭ/&��9f*���\�o5����J�_�Zv�����B�z�P�ڿ����?Q�����ں�Sj����	��W���Ⱥ�\c-��w|7�H3��7̧�� ��"�ִ�+��4�@y���8E�����k���`�U)��}\aT�w���ɷM�jD���=K�,�J7W���8�I* �0D�P���uT�����A$p�«A��U�N�)@����C\�C����R(�ڞ�a�C�������D7g�Ǵ���.�KjP��J�U�W>3iXұ����I��>����c.��1D03Q�%����F�"���UU��n�fcM�Ƀ.�"8�&#O��ӹ.�{Y^$J�?�	h�6�����)@���	͹�;��w�8�dT`@&�R��`c��eV�����Q�7�1TO�7V�a��R]y�c��zƊ�����8�	χ��_��H�a�N�p�4Ӻ��\�$�4p�c(�j�l��J] u��^0<y|�gw|�hހG�*f%<-b~j���D9-�Ɂ�qW��pWzu��s;�4�Ïq��y�AI����TçB�:V<��(�\G�OXh}̭�m�J��0��}�*��;�4e55���b�m�l��3����釶yi j�R�2z�1��^(G��2:; �����I}�Vȸ�6��M�2�.��	�o��(ۊ��LL&7��8~u�A�<������;����W{~���&5����\�u$G�8�P��[[���O�M�<��|6� �g��zr>Z�6�����*�+�C�伹@n��:u��o�Wc1�B���ӂ�u�-H�}�[ywkL�^��;&��Jy�&.N�ҚGln,�!�gX�� I��K��6�j%���7�	��B�ʶ��ϙ���!����N���(���!<�e�3
����j)���(���Y/�s���=�~�Xpvv��J�-2378;R
�����ln'ʱ��h?2�}&Z?YC�d�����7�<V�k<���b\�8w���ۗlѯf��
ׁ��y\�8+�R0��e6(�����z��?����扞�5�_� w�Y�otvjs�,��t@$S���	3�F���C/�
��S�ߔ��b�+�;��u
n�<w��x��I�z~�AՌ��v#%^Q��=_�2)��-@�Y��������Y����O���)���4V�����%�fri7,���˲��S*O;9���D-Fٚp��_��5-F���%d��zM�a �XnEL������1����/)����Jm�`��h��*_Pq��R˱��$b�U�8�[� �m9ɋ�G�8E0��u�Nw�{�z��5++��(���=�7���ٳ��3��=("5f�����G�ʎ�	3#B�z0j�C�������뮅q��q�f$�?<_6.j�H�����w ŊO�d�iŋ0Y� ��S�'�=�m.�Ò>��:o���W��0̲��m V4L��3{ݑ� 1h��(�rҙbAb|��[���4�7��Ǻ��3�J�o�Z𹮪�O4��b�v۬
B*ے`X2W9�5�ą/�<�]��/@h�5�3��V��`L�`֘���,݂f4�@���UD�r����o~
V�;�K��{�Mqr�P���԰r�A�GEX�k��CԊ!#�%�Ao��;MΠZ�iq�N�|L����ծ�s^�RZc�>C��z��`Į�R�_d�*����9��8�;����#81B�,�F�T�>L#��o��bfF��u�Z���G��c��OM~L�q7�m@R�����6>;���.?���ZP�F\�k��
Q�1o�-�L�H�	�uں���㰽:��m�O��Q'�?D�4g��k��6MA@��l�jl"�wk]_�.2RvD���1�D-�i���_���� e����U�"n/3^ͣ)��W�[�A6���S@�.A������iM�lnpw���a���Gv{$Ұ��6�l����_<�N���b�p7�+G��S�.��Ӟ��LZ�p�\���>��A}�"#\:�+ O~�B ��b/�����-D~�͙�&�\åg��lyb,�n{�h��(���6}����r�K����T8����^�f�������#Yzqx�X6\�g�â�!���:�����&pCP����8�_xT�k��գm��k4�s�?'�/�_&�l�ۑR��]Gq�s�����l	����` �+��l0�Baudgv2�sP9b*U��3fJ��d�+Q#�U�S�ǛӔk;m�eV�k�^��8�^u��Ź����)b�EImE��,=J`�N��m�xo%֋"�v�Cʳ��#h�9|�?�??r�C�㿭4:3��|J��؋�i�>�v��G�O�V�C��4���t�)�	;�{5ЃT�SJ��Z�p�N2�6jz$�Js�Jg^�Ƅk��:W)����=�^��!�r�=E�0��&��/�t#mIă�Ѿ�K���(���Q'�@�0��S�΅���ƛp�� \xw}�<!���<D]@9�����F���Id��5��?��&��N���D�z&���e���x5߱%J(�?g��z��Q�9.���ʋqkȫ��)��T���q#�y�%0*
4�K�����>�W��h��#���Y9ЁȁL��|"{�� ��Zoi���&���UB3�(��4�
�`T"{�15[8�G��OIq�7.C��I�`@�7E[MLI�5m�x7%����*7ac��^D\�(�6Vv)�F^¸^Nc�lS-��7-��
_ܱ���eD�C��L��L�6�)3A?�Rن���t	^��EK"7~�oAS�/�,����\��è�j��;�f�>�{��Qr��!A��E��������D�=����鮍�h	���B΍�T ���,��\����k�W1;2�G�@�����<�̜�_����\����6�ܪ�c�s�q��RMN���`I]M��V/u֣ǰX�.=J<�8����k���ՍU8)�͒;���r��~v4Q�m���q���W iȣj�M�x�[�%[���%}�uS2B� �����2������߻����X6�45��ûJ	�~AR<�}��tR�-�iP�[D~���Z7�@#�!"^硇���������%ul)��מ��Ba1����N��(�Q��s�D(���yh?�{d�3hijH?X"ٶ���+,"��2�I���ҔסB�(-��'#�Im�7�P� � i�R�9��.� Ԥ63?Y��x�����s,	�"J�cM�f�!����ZRL�V7Dj4~n�:[j��I7�k>2��t���`���n*!�;���,���P.nu�ר�W�!OB��%^*z{қ7�H�&�V\'���!TB򳕭�\S�ZmGɍ8�zD���8�Ki��M`g�`��Ju�r*�7Z0o�H�0�Y���`(�aϞ!c� �$�k@f:�P� ����z�$i�ER��{F'�I��B���;����Ҥ�m��XS6��T�_�B_f��p�8�iz���؆]r�/m<���u����jU\Ga�߅��g@:�6Em�����XI���ӻTy"�a�iz� )�v��]�2I�H�	c�����-Zp>{�EDl"��@��ɿ�Y�z�Nws�=;�S�_���4B;q�3.g�>jՍVa}��Ս�}�2�8׉�)G>O^ 363v��@�-c[C�MA���P�.�~�w��$�ZD���/�	��Ġ�XX�~�\�v�����,YP"�a0�'6����|�=��:�0B��\��Dh��6�2@C	���z;�S�2��H	��OI�;(�|�Gu�a�$����o7�LbU�$�5��6�^��%�P#�.X�'/�<˹�G9� �H��'YP���.G�����/�eLě�e��͘�W��Ul�R#)O䆭���-1+:��*x�/[�N<��F�MNR3�3�c�!#D�8�ߓ��/^�pӊV�Ke��-�D֪�nT,�@�`V��ޙ!]�.T7.��^t��tw����� (��Y��_�W�����E�1/������1����U�n|�:7S6� gP�B���Kf�ÛM����d�@��������|�nU>�~=-t��� Lpvۡ7�=ϊ��jaU	���+ɕ:�
$��*B�PfG�ءL@����3����2E�/�E1�ʸSr�FW��ݼC�o�<@��y&Z��m8��
����Ɖ' =�CO~-�r�߆W�(R/x!��&�˗L�=�U�3Y!���Jm�*�y��ChL��
E,����a@y����l��1��Dۇ%9e0�k������;��21X���Z�Q���f�!3��M��(M��I=%Θ^�7���=U�g0$Y�\�?�j(n3�hW�WϦ��n���M������P>Ӫ^_���"�4��uj��/�x�k;m��u�hf7���o:��yDz�7��]_�<�N��1'�l�qm��D��wY_Qw2�
���_OX�1����QЙM����͚���	��MKJ&�v��gO���8w�;o')�g� �mK����;B́#JF��-ŗw�trS���e�?^�V��6)���ma#�H]�!�d�R��M��U��u�����.�ՒU��'c���ތ߳��qR�j��t�=V��:�L%0(%�b1e���#�l��bhf9�I�EIf
��(Șs�s��+�4�m�̒?.{|f}�n��)槐M��y�kB���;/���e���m����!��t��P�Yj���J;��B>Ԙas溼z b:ɖ��S�W��3�e4��i���v�.~�.ܧ��>[�@x^0%=���j�6UK�K鴄ǽ}�:����׸������^v�I���ݔ��i��r�i��V�lP�!QY����!�%�<�8��P���ُ��&9p��:�@]���c	X�Ě��1��2v��>�'���1���N��W���K�<7@� ���z mZȈao����[�3
y9�C��g㩙�lz�q�x\��j�0^y�m��U�˟�����<�Yw*�/m:4Jh5Q�&$|?	���e��y�9�*d���4_ޡ/�Y����<b�dFL�D��.�Ek޵�M6�~�D��d�&���͟��³�{JTf=rRCIV�5�#$=;�x�s��w"���ʎr��.R�\^�o;��l�n!*��6�㮢�b
tlĞ����h������Yr(tq��/~��&����m(k+��_������MdC
J2Xu�Z�D�m��A��B���'}������_�n��!cS.B�	|�pV���?)�P�0'G����g5��ݰp�]����s���:����-Z?����+��8&�J�7��J�_��IA�����Q�{�U��V�w�1�I��MZ�"SOgP�<&p��ơ��6�$\4���g�S�ق�lQI+�Am��U��Z�0�YUoÒ"K	�O�Yy�]p�,-�=�[bP�)�fA���r�ws ��I���t�i�,�>�2�8C7(������>ϓ��"�8� �1Ű���'�?�H h�B�lOy�%v3{��� ��^��w�=7�k���$������gk���P�6'�R�h�$�p�UE�遟 	��c�P�d��5�ya�>t�ĩ��q}��з)�]x�N�oPZf�ω@hA|���N�>;����ܾ�`QS�"m�N���<��Zit��7)w�m��y�A�k���wF����q%gqfN�.��mo��ߦ5�>���%~C
;ހ�������|�U�3ʦ{�l�bf,�_:���
0z�e-��6�[���J��K���V�u�v��ow���D�zn��N��:{�q���;�Ȧv�}Ǽc��T5' �e>aq�ٷ-pM搫�LT��ܚ_��:��(m�˗�{�؎圴��3t�v��+������Ф<�O ,ܥiO*�~����̾R������"���AYUN�H��[�x��Ee�˻��K-N��q�\�6�SxUѰ!~4�,�+G���&��5$�C�<�ReF�R֫�`ޯ�bf�z���D֍��jYx����ˍL�&3�7b�[��R{��i[���ީ����=���(�xGC��.m@d/m�8k��+�K*2��փ��ӧg�����Y#��;YQ��6�H�˂����(���(i�z"�|4msLF�u�Z�>N�Y���FD�F�K@�>�J�%����,�������	�d���y�p�v��_�)�oE��м@�JW�-�K�"�<�#�����]��1a��V�v�'���;��tHȢ	셱罺u����g�%�>�E��O��<�����Eԕ���qe{�9l˾������#A�'	U��g(R���a�P����l�Q�4fʻ1�V��ڣ��Ey/$;'�gjw{K��G������s�^@�-$G�׈�K���l�8�+)�n�7��O�$�Z�p	�p^F�dQ��!xn5�E?�ߍ�*ʼw�*qU�=��{:��L���������f �Ig+]��[S���Wypv�;my�t4���`5z�}Z�/�W�B���o�lxLm7!�����|��t�i�Q0��A���v{�K?6#j(����_�?��(��H;�p�E8k��c$�ǎ�cj��n.���e4Ⱥ.rҺ�Cn���՟/���B����6��w��ܩBQw�}&���E'm�R�a�7�h���b���z|����G�X�F�|r7�ع�r��@��<PĊ�;�:��X\��7Ad��D6���)�V�S�O�0�";��[ox��r��JH�N�)E7zq���N�NG���KX��x)F5~#/>�Z�\���G���T����������c+��sB���K�ER:���@�X���?J�Kw�@hԺ7�L�&i&�W��Q*;~�RMW��E���*LL}[ǰW��cֱ�<��/��rZo��^�_DH��[P�
��&O@DɩN�]x��z�o!?���Fu9�Q��
���E�#1�y����R7N�t�6��R`7���r����+�9ăw<z�<�6�1>c@6�|ۛŀ2�y�7��0G�ϭ�����<c���~�b�h���Y�����1����Ѩ{�:��8??��]Q�k������[t1�	���=�
�"�h��۪(Л�ڝ�c�#��	z%-�᣾B
�C!�+�����ǍG��m��g����|�i~�����`��1~P���[3����nu)G��ȹ��Uf�z]����5���F����%H_:ݼ��A0=l0OE����ƽ��Z�����8�!	Ӆ֡�󥮰m`o�1L��m����Z" ���w��4��+]�cK_<3H0���v8���`C�}2|�x�q�g8�E�'���WB"��f���	��#�y���/�nn����%��
P� �y{�1��_w|��|�(�6ꖩ�1+s��q��LW)��4Co2d����b��?�����{8���u)��պ`��SzG��j��1.P��^j)V}H4~��a�)ƭѸ8�{"Z��m�O�h�>�9s�W��N�N����C�x�5�\aȋ�+�iE��V�����9
�!�ӷ?�7��A��]
(�=DF�3�H�����nET����7!>�6�_l���Xs�V9��*)�n�m3(o$(��]�:�̴@y,�{@�v�U�&X�����@���)5ӑ����$�I 7'��]�-���d��y��?FWJ�F��몿��Exx9R�+�wVڰg=3;��G�~���p	q-�D��|Ѥ8��2[�1��nS�1�Eg��5~�Z�=.l��eM����}`sTxE�Z ���n��h�dE��*��y|����[ߣy7Hc�C���ю��mSl�T!}Τ�����6X��M��ye�u�B�w	F�=�SѸ$׼�� ?ta }���!'����C�Ы�����(���ӈ|9���XX�`���C�R�&����k�}��u�i� [΋7�hKc���7�����Pm�&Wq�ޣ��Y�~m k$}��~�(9��֚Pz���$�g�����H����Ɍ2R`fy���*t �܆�8�w�2�Q���A-G�(�0�"Ϸ�D�RN�k��Jy���*���I��:��ZB'�gh ���S��~AB��A��iIt���	?����G��Zm���%�˗o�C���x����~<c�ӈd��<��2������W���v|�h���ۑaR]M�6�8�"m���tf��7�Lg������0���rw�E���$+���.�`\�bW��-<O����4I$�WRhl�-��L��f�ѭ�Oo*�C:�kf���o2��ĝ�m�(n�)>�H�nBn�L/A����^:�Z�)�Z��"��ʢ��sx~+���	�
>�.�>v�y�����ފ�uL�����صCr��o�;iېgD�)��#�5�.!���[���T�������7�<�P����!��7F)��ء~�\�q��x���BfYq*+� ��dD@��U�`[��jw�Gq�I]yO�k�5j'�E	����2�`��ԓ��/����d�)��d��S13����?�N�QqmV7�~��7�p�<�w���7� * ^���N�!ff&J�~B/�ة��Xa���$\B���ڪ=�)e���9`^�y�F�
��6���(y���Qh�v<��>��Cq@�Is���ɽJd��\7��R��㶜��hG?~5���i4��l�|�g߬8�|�x����+:�^�����2&��[�һ�w����!~Ρ�K�8©�/"d÷��'�r�CqF)������ �ʸ�m7��7z�3E.s����WD�[*��cr4eXz��'�o�53���&gկ?��XE��͍����-�nzg� �u�H2��=�(��.>	g����Ռ|��=�=?�y*�'���e5B��ˁ3�����d�79	�WMC8� �dy#=�+;�qg�A���8p�����Mj�?�&S��
1��n<X���5��2UIh&D�*Gb.���b�2��{��&i�O�1uA���z�XC��,aI0�������[~��J8�F
����~�%Y���4�YJïE���4� ����G�
��n4^t����HbRxS����@���a�6���GT\�\���V���#�e��d��ȿe>M���@��O���Zթ�4���ų]`�P��m 5�a�5&���~:���9�-w?;%�V�E.hef�������x�[V���K���8[.��O�x���&��K1DA���<��i$�m���Z�%=������88�o���0~���B�p��t�\�"��D���7$��ͳo;W��<H�y�y�8���P+��T��:�_8U���tO�%�(�?F�9�L��ї���d��Vl�6�B��|�����m}������땠� ʤ�	��p�1�MV���4B>�,j+�{�,�CLⲍZp��ҟ���u�أ���9�8s�/՝�u������X-��o���S^�xM�_v^���Û\uM��2�^`��l����;����N8�A�v;Xٻ}�L��e����mV�;�j
���4����!Av>ؠCd����\�*��@ p��G�����1�G�����}�����wėg��������N_�כi�����-s��a9�*�pƹT�i^ݟ��b��\�Y�j��Fx!p!(��c�+o�E����q�v�l��w�6�鹍����t��[~Gw�q{Ö�(	L��M$f"J�_V�k������b�gc=�u�"�+�l�,\���*��<���JW����.6�C�ju=E0������=�g� )��D7Gh���^-��`(r-�;�0�������k,E� ��f�0�	�*�U1%/x�=��k�������e�#����G�sp�u@��Ww�H�ښ��m-!F����޿L(�ܺ$X�>R߳� �����w���a) ���/G�4�S8g���U��ݻ���!� ���|�n'������v=r;�@��p��37�A����sH�A69��xoV�e�͞=��ԕ��3��9i���wW
��`O�ٙم��]&8/��է�]����������SW�� �J����̎:p����/7���̍6B�\7��6w�c�l�!֪��q�����B��sŬ����1�g݄>n�8M�ή@���GON���SM7��_�д�c���:�<z$�� �b��^H��[+�A�ueTM�[�O�-cBN�}+9U�n��J��F	z�ճ�	�Ѭ����C}��G5���z�Uh�cBB�QB+`o�pE���zAJm�oHf�6��^0�t����CHq�I�
��U���՞����%�Ź�����a��$o&�+ê�jU��Mmu��1����XLD8�?Vd��)a4~6qNx�Θ۵�9� ����ޞ%���_g���;�{}$~&\�Zvj��(� p6AH�RF���;��v����+��\��fwL�ߓ���������U]+���ܪLi27q�}���������^Ⱥ����CrK�<� ���dХ��K���!�;��5��o��e`�1�^����`5����b�/Z���Y�� ̎"Y�ٙ�
�#�7).Yr�Pyp��$�/���^�`8��|�D�fF W	bb�dR2�>��-�˩�'�x
����1����ɥG"���y��l�@��T����vǙxaKzz�W�Q��p�Zt�}��ב�)�ԾӅ���D�拵�[�$��!-�L��<@�ء��k"�U�:�K�?�������_ (]�e�~��
D�#�"������`s��+��'P�)G-ޟ�����'0�%p�*�&H��<I m���������28sP:҇�B�*�b���M��gn]K;?�6��)A=@�\�V�Å�:'"�|���~��m���d@�2�E�-���MW�B�x���E��F(}�r!�R�c�2L��M	k���K���wTMm��)2)eF��	Aw�ƪ���5�_&�XBێ�7�;��D�S��׶�3����p�9#�N: o�>�Ig�����'N~�$�t�/�6�7�iK����E�q���t��&'p�ދ����NEY�%�Z���l^���o�1�"�M���Y3[l)�Q�0+4�z3m�Z��@"�o��ϥ�Ny�S���N��J�\f�J$.�s�3���y�pv���	>�8ԭ��W�#���)�
���M�^���PF�.�d����H�1���-��g0W$O�j1o�;]}�Mz�S%*O�.�
p0��t����B��z����$�֬�kS�:�<K�X�Fb��7��8�^^,����2��=��7Mq8������ž��]�e��G7��,t�І�vu%�}�;�ћڃsF�n�Cܝ��g��̅]�����5��#��
%�f��vV�(0��(���|a���KK�	����u(8�V5{bjs2��P��ٽ�Tq��@4�J�8������  �?�z�퓶C�~��o�Nj/�G'a͐�aI��ٛ�̂�/�>����+����ƺWU� 8?~a�v�r��ns?��Ę��e��ty�X�wI�[)aZr�g�
7 #|cI���&�H�Ƅ���V���r���d��r�K3o^w&�
�ŨEwl�9�u|[7.�q��6�4�t ]�휖�.���|��t�o+V�a��:Q�zU�&�f�ġ�� �',|���cl�#��DR�GS}m�:VTv�<$+�c�_�3�4�o�K���7�"=w�q�=���9ܒ��BZ�,����޳�^B�M��ZM3p����k~|x���K�X���D�\V��Zd���^r�N�C�{}�
^�i���F���Hݔ� ���7�%js.��'��{�X�<~���������.��G%���I�`H;�=���gWs���٭"�eUR�L&�L���jab�����	������J}Pd������`Zө[�������or��'�&�e�|�[A���ۚN/*Rp
��v*믊W�>����{
�?�h�X��Pˢ��8���X��V�k"��'.q+VT�nu�s��	����>q�G�e�(w���iҘ�!�_v���E���I��SJ�9�)�$�,uׅ���>����^�/:Rn�x��{�ai��Y��~��Z:�p��H�Tb(�3Ccp��HM�����A��� ��+�!eԞ���b�(`0����jљ�9ݢ�����҈�����f1���A�:��Y��rL����=��P2�HL�94��7�S%x-��	eS����$.Ǿp|`�d�]��x���Z���+����nu�`y1Qtā�k�<T���	R_���k��uU#�Ml֯Y^I��f@�������'#��yЮ�ɏ�mbG�Fb�l�:Y�n�7Iz���.h- @sS
V{��ifP���!RG9b
I�:N��/(��,����"�&߼1��������)6;fEfAΜu�|0�<���F�ZQ�<A[nu�S0���hb�ˤ�@��W��).N���TF@2�;�}>����v������a�F�3�b�.,�G�r�g�[��nNr
��}��R"���0�o�蹨#88}��_@�]Oܓ#�B�ݳҹ&g���fl��DT���TnL�E��u������U�1r;�̩O���+cJs͟�p��R^�䩝����_ƥx0j�+U�(��1H��6�/ROV*�y�d�l��d����z�0�X-s2� �[^6	Uee_���v�^��b͆�S����������"�?��Q�ñu"hƾq���ߴ�{�?.k���5�Ȟ߻0�$��koz�����@ĔO��*��Ǖ��G��ffhp�#�VC�t��ǯ��do.����۪����JOf��ΚK�w}�W�`��y�Ǧ��Q=P�k��Ǔ:{��#��Q�e\dR�щ�\J
N5n�`m�羚�E��qC���<� ���|%Rd�L�0��SƮpW_b�In���&�yv�&4u���Z�������!�*_�fq�����i����Ųv��A�'���z_�hn&`�G|eqQ�����8{`4K�nu�gf�߇��y�����W��a-��0��}Ul��vUw�.T�{5�`��NZ*�gwW��A�/��9M%^���f^W[�a����� )�Z�l9�=`0�[oԌ��6���/��*����2S�8,IĎ�>�)�IhHr(`ܠtҒT�a/	���RkImg/����YI˽�³�ӛ�d��K��|l��I���?����g&!~.gď�/� �n�/��9�]�J�	�o��ŵ� �����ў�ƽs��]����|2�W[��ũ����ޫ��\V�ڴ騀?��.��D~&ӣ�2��A�5��gI�|P�ez4�FkC����������F��.�,�!;P;�]9V��A�a��Ɔ_�E[!��IAb�φ�/dn%�r����aU�-`�B`#oK$м�ߥ���B�A���IY�P<kv��z��T�!q_�g�?p��Gyf�X%e3���υSL�DX�Q�]�| ��"�����J6���:�3�3��Zz��/����o�+���to`(֭7�}�wF�@����И!�d<1����D@u�l��'��I�EIp��y�z��T;e�����K� ���"!s�_n|4���#����CJ>�VY#[�M˟�y� h���+��eAz#g1���9�o�P�*&FG��	��'B�5wm������`��(-]�,�B^i\�l����?��� H�LpF���AG�9�f�p�5��[�d���df�B�Sa2Y�m�A��]���I�;20��H�:l-%����|��9�ZXvZ�
c�����/�$�ߕ��N#�V����G���c!ӫ�<�]!��vIif�0G��u-h�g��y���2�}A3rK��Ƽ�+^���*wg�:9��p��o�;m"i����Y���n��d;�`��˾��uS{H� ��׶�nG�^U�tj���� _�ҟ�/PF���S�,�:�v�(�ȳ/B��|͕җ��NV2!����O��\r�40Q&u���ί���!�e*���Qv0�3�Ҍ8�����U���P"nҘw�?}�1�W����+`�I �����M�#�qb�}��=ʣ�;.����of���@ڹUěL��/��z�<S�[W�}.��%V��B��?UYi�Ǎ]\�r}f��i-�������,j֢Q���Yx�8����i֪h�M���7�
O���74�y������lGm_D�POe��J�SX��ñ��}� l,�}�������� 9.΋_.hMc�b��UY�������SM�r��Zw6Ű��u����-/�GB(y��{Z��'��ȱ ���X<��#8�3>���,}β���Q"� ��ɢ�2;�I�/M�9u"���>^���&�3���S0�m����^0��d:�0s��S9d]V�����rP���+����Jn��$ޗ�c�7��L�Eٓ���ʟӱ#e�?G��!T/-DW�P��PD v��(`�$�̥�4�&#&����g}!����
2�CV,��$' @����{���h�vmq�v�15�{r��ʁ-Q��Z���M�F�`�W�7��
��݊J�k�������[N.����U��<1�Z�����sN/z
N�v㮎*[���H����M�=|Pe�ʩ��ߴ]?��� �����m�*�;wf�[��#N�&�7����c��c��
�L�Y��3���B�u��j�t�>O��]�;�<�L�m����O(��4'����5�̢�^�uQA�������/�a S����vy��߀_VA	u��Q�`q��m�a�d�������JS��u���ѕ���{�i?��*9V���-�8���hג����M��a��*/�1+Q���CxG'K6� V��x咨<}��4)��j��x�(�&��y�\��į*�X���`������	��嫇bt�<1���%��}e�I��a�o���k��+�Q ֎`iY�QB�i���ԅS�܏���G�Ar`�W���Fwn�\A�M���_�s�'!�7"��;���v.�B��4�%��}o&���K�h��1����${p�yH�$G`!k��3��^��w�s냰ܰh�^p���Fb���7V��{2V�S~��#?g�@S��1��H�����sn@���\ ���
����>W��Nʼ�����`Ƒ�λ��)�ǖrpB�+���{ !NCfU�%H�?�K�u�k�<&$Cю��r��`|$�l9K���0�R|!���rGF�Y��d��2,�u���E/�)J<|_�����W�X	�B�S��`�%�F}��Na�7��+	�OtjjnZ�a9��g%vVg�`��OM{V��d�2g��=�sS�}�т̴q��>Z��:�*�=h@5�G�L7&���N���ܞ� %_OG��R��gM�p��/?���5�����pO�f����z\'�U�9���=NGż����`���3Q��gS����e�����^�����?g�[S��3^=�p}<[�����d�h�Q�xJ�<�V ��_YN�x���c� �:�ښ�[2��ؓ���`�K�tt'�Xo��m�c��e�]	� �b�������=U'��!*`��d��`�F��+�� ��n���lC�u(��(�4b	����o뙢>��@C�	>�?�?�ԣ�i)�_�˞����&�3�CT�F=�c�F��!����7 !��T�%g(����AH~ �j�T�n�Yb�A�U<F����V�:?W��&�:ܹҒ�?`[^l�΅y��<���-]�f;�I�	��T��+>��JS�g��p��S�
|�i��E&ʏG4�Mx��{;���=�=�_�A�X/)o���S���^�3�{�G��W��8S���
Zg,zwx�4�j��`�A��VQ�B��W��H}/��'��&/&[/eT:X��p�w=�^�-hi@[ݛ���qZ�r�=�Ǒ��s���֘-S	���庞F%8��q��m����ݙ��"\��#�??w_���KAl��<���(.��pT��D��99pas��\�j.9$�*RA� �]�x�a(�o���B:xF�-9������6��HG��Ç����Q�jg��?��
y<4fR�u��iU*}M�����f�b��Φ�1������k�w��`=��E�+�3�))n��r����u�ux~�Р�"Wb7W�4�nP�|�����1�^����'��g/���ݱc=R��*�e��3�׉���D�H`�c*ƀ8w��ړ���D�g���ekr���H�S/C �6zĶ�~���D}�;L]IE۝@��qa���+��m=<
�_~�7�@�\�GS�*u�����4�4E�e�'#|i�:d���r�5�j|������.>��q�)�.�.)?x������x ����50F5#!>�W3	�	�}��(���KK^�u��<쓼�HH��L�cqN�Py�I(���%�C1G��n�C�4�+�Ɣ�YH~��_��&"���k6;A��k�"�;6��ҋ��Mc��2%�ј@���q����d\(�`���]�S�)��k�@��i�c�M�v�(���(%>�]��QP�������@ ~��DCIyz�Ǯ�W���d���s�<�!�sW�,P���ު���ްt�����~Q1G�贅���s��K�QpѓD2�YDJ�͚�����Q�:ڧ��[���T�oΩUh!���c#O��Y2կ��Q/lA��uS����0�\��QԢ](W�\ٟ[]�e,X�I�7��>�m�����Y��/I��)Z�ݎ��5�q.�w�Ǚ�����KA��hq����dh�S��Lƽjj�`%�/�>�K;�o�1��HM#��/���;����C;����� 2��Y��\��bO0M�Y�(��x�D&x�5�B<�FX=��z�<e�]1ɓ��"T�2��ĳ�h{NP�iC����D�	@A
_�W"��������B ��
#K����eKWu�x��o��`�h��bWltʋ)���B� Z����w���V��}�(�!W�%��a�2�hDrV�Yz�̠�6���;�Х����~m[\�b7Mu��ik�3�z�I�^A��}r�S�6�bFK�/S^�|�R�\n�b+�j���+4C��1���A�Pd����	���,�����^�j%���sN��Jr���X����h&x;�Wz�5�:�UE��<�`��V���38]��t5v��dV�[D<�l:y>�]Z������ƨ��b��d\���c�s�0�������pRR��N��Y�S���񾬶����۪�-Ic3+��%�;���A�uF����0�EY�m��pP8ӯO��UB���<W��¨�[���楻���&�\��Q!s�F�A��Z��5��ԣ�j,_����K��`0!=d��#��G[�s��  xZ ��| ����_A<��g�    YZ