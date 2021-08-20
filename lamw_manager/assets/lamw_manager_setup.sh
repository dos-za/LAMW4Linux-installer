#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3177462217"
MD5="a6556a064b078ce3a22e24f7c36aed6a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23560"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Fri Aug 20 04:02:26 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�aq���M��l�����!�n�0s�<4� ؚkߧ/5��P����}c޿�cɴY��c��v��$���76��I�ž$�0�K6��,2<���]��j�K4,�ߪ�EG���G���Y;S���Q�O�9h[�peoG~�>NJgmdhbnM��M0�Iu������r��*����i��(�L���X�P������*2z��*EZLZ�89
��
�l� �Փ���o��(��V��zo�6��67+��2����N���b���FnSq�)[��1]�Q�8�;��?1'_=�A��3��g�K��./	4��sW�W��i!�xcQ-Pt"�d|��-�����h�脴�4��soWv�x �>��;&���yۧ��8��gƤp��f1�6��Q0���y%1�$q�(WP�5[��̔tϮ�Ȟ�n��3ۛ󎱮����Q�����΂L�H����Fqk6K8�Rm�@^R��'Ն��
�$�GTi��Q��!=��oi3jN�V�),x`QJ�<Vެ��6Ho�a�~P*��ˈ�8�W	��69���O���$��ޅ8���Q}5��[��������|�'�e�(I�M@�"]k���B枊��&�yH��Ij�~�문st�vA����w�����I�	�y�7Iʀ�2�F��l�7 ����k*ʝ~�Z���J�.����pѸ��
t��|ʷ�G_K��[,��{ߋ\f~I�]O����/�?
��*�� �;wm\XV��J-R�W���Sr��#�l��@TiI�]�9!�3�9m�v����w�h�d�s(�����x"����ۋ��jjf��_}��t{�|ez���X>!g)�FR[�f�-�@D.�6���Q����(c;�:�+����;`;7��o���<��P��:A�'�W�{5)�l)�Z���v��X�r�n;z��a��v�Q�%���զ��.:CG�3��js#�^N)f�+:3�z�����;�Զ���p��Za���}ǕM��ώ�#�}�]��45��u"c&���ñ<2�lB��z��`#���cMK�#����y��=�Z�F�Hڍ��E�������$�nu�b�:���3�)0,�؋��o�����z���¤��d�mW�B�C/]�&E�OӺ���j�]߭�2��zLe&	����;�Y&GGh������J�����ƈ�ƭ�f�Xg��������J9ykk�3KZt���@o�ʊ�pTe���t�E�%����ezc����6"W��l�	��㴏�C�yʐ�OƉf.�FpW��K5q�M�⪳7&��6�2z�%]#O
�����n*x��B���0k�<���Oݼ�CI1�+&�`���{[]����J8�W:�=�>���lk�Y��;f�'�8I�&��R}6@RC���:^��Iwv�g�wxE���Ѹ��0��l��$�y�Xt�(y����������G]<���s����ư�W�G��;8�Lܾ�IE���9U�_�#�M�N���7~̸D�0�e��O��lVa��M;$�7a�����D�i���u^������J��K�#�&z���cf��lt���Y�,Cv�bN'��>�ŁX�kt�5$�/w7��)�E�V��o;၈�l�(c�D-֘�z��M���B�>=B4H�ك8*Ӳ�oL�ڵ��x�K�C8��\�R�\q�7���XVY�" �s�A�ǥ���s}��|'�Ik e[l�+�?���/����q�,My�A��1.ʰ�;v$����m43ճ*I6m��a�W|�ù������+Lf�}�q�p! �Kw�B|e�z�&�?5�NV�b��v�x���Q��$?�9���Ew����\d��璣�O��4����������J�~����d0����QX�XO�[�с�̾���~���a]d@T�(U�?��pz#�Ҹ�r�hİ��B�mĒ��eP��^m}-4]/�װK�#a&��v^����\ؑ��!��7�<"1WQ0�=�����%��8�y��2@�r��ƿp�x�3X��o�f��$�k�J���ͦ�C��k���=�%��fx��d�o����@�)ߓ:�{7smJу���|�J�#��&i��jPg�Q�b��ʧ�Ej5��Y���J{�a��p_�L���10]�W6-pH�s�*�^����i�Y2��?�CT\^��S��S���rc��2�� ��d�TQ�������OӜ��&���c\=����&�zoa���YCw�||��D�7��3��1oZ�n?uT�+��F&�?�ج�
̑�]�0�d��C[a��4�B/�MP9�^�'�O!Y ��f����C����]����5��S�E8�ݦ��)7Y����Τ��r �8�v	�$L���!�ېI����ʼ�2�k��={�3%�h��x;�8��nQ�4kCoZ|�����Mb�1=+����Rmќ&ޯ�@���OQ��B[��!���\W\�hPl��)
��PM(���8�v�V�b��)@�U�<t�y�\G5�|�*4R�Kc�I��+�(WG���|��G���5K'�Z�f�	=l���a+]z�!?�<�-�2M0��@�C���"h�EqZ�E��#��pu�?8�_Rb�svʯ�uk��x������́^��b���Y�|#��d�hB>�샚}�C�����L�+��2�"8�8O;>@u%y�M��J��܋��_���=�����r�!�z��BBo@�v^)�)H�.�7��6�L�<B��Pf�S���V�]bR��i������u���<�8���w��!%�����4�y�O���--��O��XW��$��)h�Q�az�E�! 0�]Ʉ�rh�]\�]����N��`�%�(s��PKt��2Z���}F�@>��`��c�~O��0KFo�n�����ȯL�d�s��4f�����˚�t ��.�5���[����_T�R|g�`���N�f��`�1-A�>$Q4�7S7o-��
�oȩ<z�T���w>��<��;ϗ��CU���?�-}L�2D���Kc=��H+���������D�\ݳI��|��o{�&��u����-O/6�|�a���LTy3YE�@��~J��!�u-Kr�]w����H?W}P� ZF������M���z�R�7˭�+H?\M�������@d���S�Vh��]U�5��$�s�҆5pt"�>��zk�~��ޕ�@@�.�+�{��A���,zD��+�6�՜MU�-��RV�E��G��#=1���eH�Ns�M�z�x|;
JJ������愹����zi�#�U��c���c��D�o�	�yP��$O�h˱�܈
��"���1E�˚��@��W4$Ȋ~4F�?$�iuqi��:9&�Y�A�U����ݱ�J!�?w�)���C�����
�3�G��Mn�T`�oF8?%-������E��ć$O`��S�T�Q�{�'s�EЍ���zτ�-L��4��~�PN,hnF̳�y,TÐ�v̯"�,���)�l��{0{hxP̴�f�����{��v�k@�׿��uϽ�;%?�d��A�؏?�e8��D��'���)���G��j[8�@�]�0ZJہ�~��j<��<��.tK�ޝS@�wo�wR�����q�[u�ָD�P���B�m����Ojz+J��x�ʂ�6J�`k`R���3v�ED���Bh���0�?˱�=���d]���Nb�RӬ�{����=���a�ѯ����D�n�CդAH�b���(ۆW��YF.��K����KT��J�#r�؇4��6�����!E�2�����U�KtW��	��*�?���x$��s�m��a�N_)��& �ȸ�H,X�59?5��/l��h	�F	/������X��f��C�%��# �v�ߞ Iy�q��d�)���S	t�:�I�.�[H)V�:W^z:~e��O|�h}�p�CMQG�7�m&�+�Y���T����,��34>yl��\z��BX���5�Tv�8���[d�?^�����HV�Hl��Z`�	��4����]R�7�	�dz:麜�3���7�;�tj��:���Ü���UGZ% u�1Hּ��U��Ѿ�L4E^�M�m�"�IKk���S��@���_
� �f\vބ�f�5¿�UF��7��>u��Gk:���a.mCf��g�`뜜��.�Ư1􍡴�HY�E������O�u��"	^�/��I�'��	�j����,�L.$'`N���P�j�H���%*�un��NY9A��o�(�׸$F��E�oh�� �/�t8C��������> ��1���Sb=K��a�(�J����,����-���VŸ�����l���{&�j�p��~4�7��lsz�;��B!齞����N�vS/��5��b&��+T8J|�P��`h�
���. �^p�ex����mC���N�Z�wk;;t�K�Yw�?�aUڨ�
��d^�k��������L�̀Ԛ#c֕��b׋�B��.�	�V 1o�2��ȫ@���)oB��Fu�.`���`��v�s����퍙���a��<d؏���-��y�����:�nj7d�^��DDd�@��Ӽ]`Y�<�c{���T��x���G¾�˷��{��=�r�}%�o8�Z�xB6�fo�9��O�f���>+��Y/���"����%`AV��91L,(�R|y�_�'�Ȧ��ќ�:�:	hOzZDR�#�O/S9��%Q#טs���5 /Y@"n����f��E�������u���P�U�[vwV$�ao���F��/�\�]v��OQ�O�E b����/��TU���~f�Q��ס���J~���!|V?����e�D&]W��#�)�}��ͷ�~f�`��zGi��Os"ʁ��.)D�ϪU[�~��+:@B:4���5���d�ڞU<�:蛥�FRMŖd�4�C��>|=�&�%�&"Dk��;�H
��kmn����20�hQcx)r
��,'>��sҺ�6l�Mz�wR��%�:ap��7�}�' �1f���VDOD QѡJ��w!��oj5���rR�����?�������t��� ��i/��M�	Cb;��Et+}��$?��7�&��\��	����O�/�p���VhX��o��X^�D���풚h�qPn�["<�l>�u���B�&����U��?Xt�w��x��@��m#OW���L	Dʧ�?�(�)��"y�1��=�;�_��m���w2��٩-F���*�k�|��jAƑĆ,0`&}�$��n��j3�JbUbU�mK�t�X�^�]E�u�w	^�@@c٤�6�j�����[�����]�������3-]Z��=�k��@��x\u���m�ż�<'@c��K�"����n�	�6*:��7x��D%� ���^[tzc���杳�Gu�U�1�:��K�jں�Mڎ�_R�>��5�/P40��7erm1¯��}$h>$�`��D�9O�g����`T��v����mz�7/opW:�F�F�������ش�\I��b��E�,���̶X����zZ��S�ڤH��;R��Ρ���T�*�A���
���0��0��3��Y5�?!�����|��BG�e�3��Ax�0�_��B�uo�z�B�7PY�_�iZ|ޟ�qN,���Y@���n�16Cq�7r�݅�Ɉ��[��v� w��ԚX&#��^q��3�$`;���S��ȉ_$��;
��TɳC��Ȗ+�6�� ���RZE��)c)������*�.�sg��(J�)Fn�_����{)�},zT�.�++�� 4\�Nmw�J���)��� -φ�NhG8�n{t��!�ԵBA�bX g�4P4yv �s��X�hA��mL�Gi�a�~�}��n9�y�䤻2o�Py<&�7�l��D�܌��o ��l=�𕙋ת��[�^d�K��J�N$u�i���p��Z[`�o�PӜN)�i}�7��4t���!��L����R����"�*h�]( �a7Yb
Q
}��W<��� �R0�Ҹ[�0�����8�0�7_E�"��^7��u:�l'��Q�7��$����k���b��9��<Emq�G��m��1K,e��4-l������![�J�!�3��&>N�fp���c���fO+n:ut����J�M�Ӿq}�z3�1C��	�������k���Hu�,��V�� �t ��Dc�aM��?vo��.�h]�9gB���3$�*�,	Č��/�$�6xf�Sv��*��l��.����w���;,�v\W�ɴ  �0-���,�Uj��a�3#nr �DG�`��/*sW��z.�_�P�.>+�z��#���ӣ"f���vS�mRbw����B��(�(�����B�>��<�VԿ���tO��J�i2a�0� Ce��
�`�߳��s����������Ͻ'�nDYT?_���F'B�����7���k���m�]^�{�����0uM�φ�E0!E{:�V�>C�;�2$?�A~~����1'̠���[f�U��l��dS�u M �{6�K&�
�v/����Mn/��a��WUz��if#�8�[��EZv�-�SK�������_@$�]s��[��s�x��鯁�i�,y�	;s�ǡ!i~��q
XX�{]�Y8���$1d�=J���n!7Tc���x�G9:�i3��[�V�|�8�	����&���ɐ���X�yo��C��g�a^� >`&�H���2�o<</`0zwxu��~�TC�cH�gO����� ��a�w�Y�X?�]X��j��f&�uzݷg��v��^y�< ��MP�h�X������/J,t�b�gޘS��[=�)�ʔrCd�Gn��#R��dKl�L�Zy<��-y>�^/��G1t��J����3�M"|�˜�&��:�[�f=�jrjڐ(/�*�/%m+�HO��ֽ�Fr�c�Z�|�6j�7��W1��8�w�y��?g��U��U0����� p4--a@�gD��i�`ήɼP�&���q��r��R��������UVʺ�Ch�,Fw�
�-f�l3lus�8ס�}]/�oXa�z���(���JȤD�4tզ�p��A[���?�g:��l���t���}�J��߹	�p�v���a�<#�ʋͽ�RWc�T�j<����A���Nӄ��4����(���e
7������/�@�i5G�֋��:y D)������3�X����ebk�lr�����=H�-v�;��P�4��f�ߊ�+��z[��ao-)O�`l2U���BJO�i2�U�ZX�rc�d�i`%YE^R�HTw��������\W�~vވ洦�a�߇�5�7N0Ϡ:(�cZ|����(F�U��4O*zO�ۊxR���F�/����%�3n|�ID~�������&X��{�8zf�Q�����F�:�\HzM�R.��w&�E�3����*�2M6`k� �}�H�ŹS&��A;�e��"
$�\�~K�K04����V�Y���Un(IB�Hy�;��j@��:�:�����!O*��[ q�,�H�������A��6���}�f��LWJ��IB��q���� U[s�<s�8��W�U�k�O�[6.�jp�v`O���6����U�@�')�nn ж��/��D��[$�W�-�s�*�>/���%�|�JX����z����%M9��^�����r!6%�`���`�=�"�|,O2'���N�	��&C�ɁP�k�_�OC�S�!r��F}!�q�Շ���/&�I��y�@K���.v����p�]A]��ba� .���#��5"b�^}9������㥡�6�������}\�^)�Ώ;F�*�����e���-wp}y+��
i_�F���,|�׍�>�i�=1�1IQDx�ç>X�=�Ri�>D��j��%���5�$�6�3I��mL�h���¨k�)6�y��^�J�+#S-WGk�X��h��~y��+���]n,��c"�2Z�E��?��. �M��d�:��>�E�S�8���DͲ��/%�|,�5o�p��M�P��|�9�ȑ;���S�~�d칬 �6G�J�؈�d��e������ <ŗ����lS/������������V��s{L���/��������l
M���L��:
]�N��M�^l�#�=C���#����`|��R�f�8���x(�3j��Eg�����X:���v�ʇ�8lr���$�V��2:�Yt�\�G|���0��:�Xq��#֖nI<����ܕ]��V�;3�o+	����q/(�4 �-�}	Gl�ͭm��Fe�4g0��d�T�[~�dn���M5p��bǸ�{95,�u��	���2ԑ�]����h���s�]ٓ��e筈�� Ƿ5�Eg!�Oo�L��i�]�N�J�W}+���.<�4������,������c�!I�8#�}�u���K&�&�'h�/j"��M�,�����ۯ��hx0�b�>��;�`P~zT���g�ԌT}�&�:�<� L���GM.�ϷjQ�9%l+�ʴ�D� C!�a�t�3�Y�.��er�(� ̟q��1�\�4t��qg-E�wy�V��E�����I�K#21	��M��85:�ޛ��ʰcQ���ьʃ�ƊD�(����T�j�'�tz�s{(�37?���q��U���K\����N���Dm�C�i]c�ֆV��k@75U��GZ"�o���1�\vd���C?f�z4 {a��=�#
���齵���7+�����j����"eJr���OޑY�������l<ٓX���mcA"�qk�Xl��{��Y9��Z u�4�ǎ��S9�Cg]�Y�@����
�k�T?��/�nE�*�K��Y�����r�y~�K8R���"�ّ�K���l��ؚ��~|1J�ˁ&pm�T:M�[��H4���>'�&M�P��B��^�m��@Ήe���x���M�Ȕ&���*���G::�Q�����I@�G�4r6��w<�,�P�ӌ�9�I��,P�1�����1Jf��F�9�n#��~��S��� .��0��Ìj�u�������COդ:�w�=��-Ŏ��{~��������J��(]~�4$s����]�m�u�̅cc5K�\mD/bC�5�ژ��L��WG蚚������u-�����%��ק�������M7Q
����yԕ���<%����y�ۧH{�}]4b��� �[	��4����Y��YJ�97'�q�G����\�x\~���F����3���[�jPెd� bفPU#$�hz��G�\�9M����^J����619�i����P?sE-c�X�u+����i[��@�9ó�,͇�3 #��		2�O3��Vى(���}3[�$�u�'S�sC�R�o�]F��X��
Aw�ޛ`w]�m�ݸw���H}J�W���MNHT/ui����Uԋ2Y���-�32so��	�3>��
�N+1�7X�Tv�1@��Ql��7 �7ܺ+�@�a�+�8���F���7�&]	m}%��g=�^�iz�Y*�|�`��+���GôP�M���(J�5��͟y�-#NtI*;��_ V^�MR���9E[ܲ7��=���6������~`�t.���.[0�0�Z[Bo�0�^fv�0 P�L99�D��}KX �:�HqA��N�V�#����Y���'ӑ�7�R�C��|���	���[B�Ҙ�ǔ���^�"W�+��o�K	DXNz��CW4i�rR���*�݋��xꘙ��f�;��w�I,UW.
/Y*E]��[�iŀa~��Ӱ`��8|c��hj�7ϔ��g�I��(d߇@����d+��,�����k������xZ]B��b[��}���Yb�*on����&-��{�
G��s?�>H��v������
#���p�Nș3�П��V3��<H5�̤�!���-Z��ȃ��Zh3��?�_`�-A�lFe��/zpR^�
����:Ik9ND�Ɵ�6��J�-��q�jr��+��)u�f�6��"²���E$��3�}s�Y`gNoNh��D������0�Zr�\hA ;�k֪�{6N},#1�ek�F�_0_l��#�[��jL�4���$��6�=z'
oq.��	>�|+�IZ�y�>;�4��䬄�O]���q�HѨ7xubu���=�QDG(iB�{� &�$�|�7�Hvȹ^�k��0�@~�y��L��ϣա���>���-���W�����Ԥ���<�)�V@s�-�F���O6�X�(��J%��i�vѐ��H�6UX���A��o̻��b���zaF���lRdc>��ea�"2`GR��l��~�a��������u}��>(�|��|�@��A҃Me�K[�G�q�:���O:WP��#���SսE%:k��l+ĈK�d��������cIbH����z�_�5�oC=l$��o`������66w��ȴ���Mƃ�jyZ�6ݜn���MW׹h*$�%�[{L��p\{VU���b��}�V�6+T�U��5lN ,Hu����+�Q8;������؊��Z/!!=��?��݂ו�m������#;̓|wU44�Pm=�D[#δp&�5wjd�@R:��-��^V�a&�Q}j�3�Q�/��,.����r/�d���r�_w� ��5���ᗚ2�q[=�C'dwĪ?�f�Ոf�$�*5��W鰯8�>���������J'1�W��\D�PR��q|�&�PXQ�ʬjx��z�(
�q���'g��L���]mr�F�{���v��5��&9/W�o���
E��J�����6�e�����gF@�5^D4H���Iz�KV��q7ֳ4A\���(>~�N�N�0J�>��Sk�6��\*���Hx��sV��,&7�o0�c��Ņ<5�֪��^x���vb�K+�<��K@%+��?������m�ߓ5c�	��[kΟ��K���
��ɓ�o{߃�2v߰��#w���4��L�Of=�%��հl�M&<�,�X�/��/�m�����9��\��*9SSJ!%��}%��p�dpG0 f�����w���<G*�bd���eH�*B	$��/	�� ��K��΁�w�z�L���E�
�`�l����y�R��؀��(���i��{�J�̾ځ�t�S��z�2K6��l����=H5=X�k��E^P��Ui�W�Z���t�6�q*2�Y5�-�򇻨�Q��@���"�Y�\�3n
S(��G��]�֨:��o��j�d8!Ū���'@�rHo[z[د�AFB�r�HL��Vo�^�&kC����.�;�\c�<�E����5�ۅf��#᫲�]�Ȕ�)I�e�1��d�/�_W�/��{�+�fI�1�cJSU�M�%b9��y�|�
`��"����5)�j~���]�## Uu|+�i"���e �/����if���+��� �z�Lh�^����Ǟ"�gC���O�x��<��n~���=4z���Â�K�+ ĔU]�g����x)#��=��4*nW��ǈ(6���<D�$� *��
�0���vO����3�T��mx�07��E$�� ��E����f	�
�<���vxW�\��L�*h�_����{��5�b�cJU�CJ��2Os2�ɗ[E�F��C��Ŷ�N�=�?rF�����.�V㾇��]��l:4ӯGدG�nyv�&�?��*%�z�y�Y��nW�����nqx�E�T֕|�q�;v)à�RRR4sax����0���H{h��Z�p1���$?���[m����8��kʡ�O�-�g[��u�]�`Gs�p��F�J��\�K�p
z���.6��'A���Fn>�|�Lz_%�l�24�!{�W�"/�#�|��ݚlm8f�m��hL�v���o+pm�旟1N��d��Y��~gM��
��Q��2���Ϩ8h�1�㼇�iվ��
_;�\O�8�O�NrXv��~�߶�lۅ!�9C�&3.�<<W䎢�HLފ�u{�I�����ej�BqL���rr���m�A�.��ڞd�����2�<���)t����2^�$��B"�&D���u�̰oo�vK�����
�ې�}M�g#�A���^�����\��H[�J%�l�C�#�0�o&���d�۔��3_W�ݡʉ�.H����V��f�Y���zgc�2�F��zM�v�OѼ�= ���i�Fe N֛��1:��v G ���Mvp�<��WD��y��p���K��jLe�s�O��FE֕vl��z}�iY�����)U�d�^>Yn:��G�g*����&.*��5DR fr~������e��#IIZ�M=�UVr� #]�Ҩ� ]�41�0Q�c�ǯ��87K�y'z��^�{�Q����
�lG��u���yG�nP��R��k����� |��.,�Q4W�B���W��;r%Skc�'�@����+�FOu�,�UA�K'�'K߃:�+O����QK��:��|��|75mçԂ|��+�z�ז�\Վg��±K�7���r��X��=ײ#Y��6=8�B��=86�nd�u��;M"�ɝΪ;MA��i8�� g���CGZ�%5�dR�E�����v��`����m������-��"X��(��,`E��6���[I2����Ii� �͸@�������_��%�4rNlmi ��A������jYk-��6Vj��:����t�R�Z�n���P�6��(cٛ�Go|SE$os)w����}7�Ao?0�w�'�V�]Z�}$w�T�KRL��R
C}x��]���c�\�Jc��x�[|�H���T���כӧ��e��������WYL�2FzY&?5��6�+b�ζ&� �j@��L�nI����<$X�S�~���odn3��6L�{	k5z��~>ƛ��wv�s�Z����q�&�it��D�?ъ�&��?L��k"!�Ök���V��Fù�t���,�y��j�����8T]��?X��!��`cZ�۵~Z��f��MlfŭᅰQD�ܹ��6��������L4].�::r�x��vb��_|§f8!a86"�$7?碘�l}��m��bW<����)u�|�*�u��\h�=<�* %� �>���{\�r�ٺx��9&f���U�{}�������1-x�8�F��R��^�3-)޸��d3+���Y$Q&i|(`�e�
���`9�~�;E���Z��|j�on4�6M�$��lI���VG���&�5���N턤��<��d�g��.oIQ��w���9�D2�?-=���w ��:Z���7o�FWO<��8�ص5�0pM}wI1�1��M�$��\�������YaZ9t��.���r;����ZG|KY�	Sh�2�^6J��F�v�_)#�K0����y�Rڥj�iI������A��.w|��C���Q��
]mA�ż�[�ޡ�>#��f@�*�3oc�a���}Z�A'�r~@����zkj��Myk���r��!��.��pt������B v�T���Qq����k�ȍ~=Dq-S�T�I��R��� �v�96��Y�z_�O�e��ʛH'��R�n�v���f�=�S�.Z��9h����`�L'U��9Ҵ2�r�O�I���(�񎞁	�F���3ߕ�MZ�\S��To�>z�ϝ'~su�i�w� ��%'�
�B�m2 S;5,�X���'ܸ^޴G��ǀ�gw�P���h+����E8T����Rꅻ@���p�vW8�z���(��N�n���7�N4�j�)'b7��!F;Z�H��S�*�U�@�c2���z�޹�z3�����l�N�o���q��'��6�{��Ұṅ�(2n���s��s
�i��f�쒧�Z͟���z�� ��?����+b�B�Px��)���ꌣ��7��S�����JV�Eo���}T�S9���yO�<���̀�Q0M�(�#� #gEg�»��*�k�[�j@!d��Aq��u4��|~�g���K\%3�1늑s�MH^�w��6�̇��󮈨^�~���%>jwU�9#���H�_G鄡e+�{mk�����ܯ�\.G"23����*p�h7���Ǧ=n�~1
�t�|DH�c�=7��� �J�l7����v� bC��u@Q-
���#i�x�v�&�G��>Y�W��}�ı��r�8�B_@��x��7�TV����S}#SY��&`�Q��x�iM���hHan 85`�+*H������W��G�8������ˮP�D��X�ӣN�J�2�K�����_T�^$��j;RC޺�|�ƃ��skA�D�<���� X�R��r�N׬���e��J� vl����<����w��/�TWA}Ʒ��c����Y��i �m:/�֗`7�иG�;3��zЩφ�-��P���ް��O���9\��٦���ѯ�Z�^��r��m��5��C�\��j�)J��A��hJ�Jc��o��j����t�����g*plD���q����p
ԡ�����+���q~�*(��7�&-ːX&�9��(�Z���)�1��sϽPx�Qc�X�|�B���x�s*��d0��s� ���5��yi��A��MN\�S���Nv�+J��e7�,���-,�3�~Z�L-ș�K��<�e4X����U3zc@�JߕkFNH#��GYк�K�-B�伹�;Q�4]�Ⱦ��A��|}�����&9�O�)--bR]������� {�W�YYy�p��s���0�q����}tP�<R���˩�f��0���o.��M���Sʮiox�_M���%X�VM�c=w�p��#�h��y����%����냈
����?b��h> �$X�f�~��?0p�Xx����zћe�nd�Ў��\-�wF�m�p�*_�w��S��%��s�ccӦ��o�Ƴ�v�����s��m^*I�,�=��Q��.���K4���A���lE����E��G�����
�b���E2R�7�%�S���E����kT�x�=���5
	���N��%��'$o@������+o��k�;�|u	��]���o�>c<H�a{΃b�`�h�S��bv�4@q���nL�}����ɋu�5���|�����GEqk�j �G��_�onҍ7����ۀɱH��Uc��|Vyx��t���������~��dX�N���Q:�z���&ޘ�Fz>[���*�8B�ʻ쩯��$�A�%br��(y檸�y��^���E�G�(�����d]��pѩ�!;s�
�B��Sn��j�TQ��T�P�����|s��I���R��~cQ�2^V���V 8/�q�o�PC;�OWW�,��r7����ǳ�&��>zz�הo�J��΀K>���#MwJ��UC[tc�]��+�xz����g�K�Q���$�Ѹ��]�cW��I?H�9���Y�5>ڪn�;4����4;�P��E.Z���2�Bg��U�+��iN���7$�ǥ�|&0{.:�bI�e��v�Dբ6ƗD�4A\��ge3�V�;���8B��*C����b�0��QD[ΪS����]���ȋ�&i�(����2�>p����|D�����*Y���m19���ϜH�AG�V�4��q�w�����5�VVJ�|���L�)U*���K�C�<����>�y�mf�ˉ��t.�+�f
�eߌP��v��b�dR��+�����񻕙���6�Knd<���'��<[6
�j�%O�������s��"s�ԛ5 ��F+0�f�ɩ��d6Y#�J,C3$S0����g!��R��&�[�����u.~����	_��슄�����F��7�c7f�� ������t3&��#K�Z�2�9��06��
��'��DR��uQ;��C"��
-̝�n�8̾��ǧ�ĥ#�Э���N�� ���UT�Ok9�t���ޞD\ ~�Hr��$�6�A���T`��z��	�� �S��'I�jK8ɆH�%s��dK��a&��q�M<��1n��k��E��b�-��y�e�\z��>��'_y�y��n�[4�Dn���|m�5�뎌&mOv:�%�ʩ��*$��ꆴqD�E'�c���!�Qt#��c���`{�����'��{DԚ>�l�Aӂ�B;����㼵XG��ϝ�v��-�L0�L��$�a�	�5�MS*B?�@�6C��zAӽY��]���le���o�ߕ����dl��uK�<���d��v.%�RX W��"�s@"�;N�}a�����++�1U�Ïq���0B����G�&�B=����ұ���+,N�6V��b��ӷǊ`���1M&���iGfX�p����hю���
 ��:�1����pQ[��<C"��a�٬��c��y�>M�o� ��m/�pG�w���6�u|M�[��v_�D��:/I&����o�S �a>;��Z��U�S5:�>q��E61��I�I�LP	a��͸�X���O�T��z�@��$[$E�=\�b���G�.�?wK5o�P����`M-�b��<#hr����q��.��+'�o�NF���9~�N�w�z�����i\���+C7Oh�����A**�[�{�d��2o$2=�K*�i���g���?�?
�LyA2���F@qPc8�̅��R�{Ē�6�o�6NaJI&���k)Ӯ�:d�%�^tb�F���K�Y{��^���6R��uD��"�0����j��:��{1BÅ�+���{�OwH��`�ܳ���Z��#�ڦ��a3st{�!�骼|��wP+3��zk����DݺY�;*S�t� ��.����e�{Yw�����,�N���;qi䟐<�����&I\�"	'�p��k��..L��`��5L��1��酧�y�8�l2?���]�
���.,�1�Jl�Q�+˴�����n�/��+���(�mn��I�7��W'k�:��q�ҩ����Ŷ�@��6�*�G����L����;�)ed��:G�f��۪.��@��M���u�J��'=��|$�����6jΗ�oK,sLsc��Z��a�Z���J���P�&H���!��&��B9��߲(o�k��I��fS��Z |g?9
ڡ��8�T�t�����4���m��c�� �w��5E<>e}��g%�Zs4!c��v�3z�����lĻ����
���_ț�:����V���ȓ "�[����HyHDvt�lcۿ�\v�,r�und����
d�hZ�U0P��q�d��+�Q������X#"���z
��^���h��#�E�u+0��f�#�O�UYF�8���9���3�����1x��%3�EB}|Xfj��h����a���	Nc%���`�<���P������ʪ�kE�?�el�+���*�劥/`p�ԭd������x���m�H!�-�^�ȋ$������n��z4���ejz�܄@2��Y�aD#E$	�ٕ���β���V��qWg��[�����ӗ5�E�v�=7�-�c¾RJ{Ȅg 1r��9��7�N�F?I�SB�xƭO&�'&�C�b��� Ht@i��j��Y#���Շ:Zx_���_j>�-��zߖ�6xxY%�s_)���=b<;R�w&`	���}�`ZQ�vo����i =����zɕE�O��m�{Z;3m�7%��]��l�����}F����w)���oC���N��&�q=�VJ�ɆM��$��4SR�x-�£�Is<%���_�E2_u���o�$$X^[R�ti����Rf2I��+>�<����E�=��w��Q2ҳ�I�V�t�h��p��)بc��ω�%ã*���&Ll)3 �-�(�;D�YAd\tG�s&�-@c7�[����TW;�VA�{J�f�s��y SY����AYM���t���G�����}�#��n�&ϞeV�;���9�	\�(6Z�=��פ�ݠ<X����#΅���2uD��-�@���F�����|��Oo�z���
2�쎿�a�b~�C��ގ�7��\��y�I�a-fk5�O�?'�@����=%�`�f���������@�}�n�`��t@�k1%(��4��RF(��'ѲD#p�(w�`�O���Q*: s��t�F9)�^<[��{c�"_1p�O�ZO�쉷]TC���C���d*��k���5^�T�̤�b?��U�11t�������b��C�R�u��ޭ�C/�G�� Z�C�b��V��SY�w4�jٚ+�{R������Kw1fZ_6Ӷ��k�(!��������)^��hg߳�h�s�^�=Z"\"�d�q#��nb3��9 �
���A{�!i���V����q�m��ª7�X6���$S�fT�e+��kduE�?� �F���D��.����i4%����A�Le���>��?qaG�.����%Z�11��&������{���(��e�/�%h���~:,�PC�"��j��Jz��M�0\'�F�8o�g��6׀�;�l#��FHhU躼�P~������)��	1 �,UQ��-�Hu6:�I����_���HP�j�C_���N#y��/3�ߎ���*��^b��_�Ԯ'�������9'��/��X^���h��f������7�c�y�X�|��=1�z;}Sp��%� o����D�d�����n_YE��]���L��JT˷����������k�=�h�y ϵӅ$�	��E5�Y��W�&rq��D<�'��ˇ����zˌǈp�g�aZ��92Y16��AC���k!@z���[��8!�Ksnk[ɤ�R���?�5L�4ٕ�%s�N���]�*�T�(��Nۊ�"4�J�Ap��`�2�_D\=���Ω �ȼ;��OT/�껢8���Q'p�R��B�Ǥ�a�2�}r�Z_2��`ј�$\�ͩA'�F�����dd5ӭ~ЛSvo���R���)8�%$>%�X!�q��j1� ��?O��x����Pq#���|�[��ڜ?n6�e�6�zp��|�i�~r��^$9:��-4�v��4��@���	C���͔ڿg�z��n_7�y0����
){lX�T!�$o�e��tʴ����P%�TWsQf��)��FZ��z�3��ҍ��H���FGE�q��������V󴘟�0^v�����IM�/9L�z�x�n2N��%�7\,��f^�g�Z3W��Y��5�BC�"��ܱ���.��� �V8s1(���-�Kʐ��$h)����A�nQ�警�2���?Y~tm�������*ǢY^TF��)>}X����U�v���0>�o�8�f��rN�n!���Ÿ󇦭�+%�7Zb[����8l{x
�����w��J&�ظ~-5n�Y�x��h�fZ�43l�׾�W�v��ğ�2��h�����j�(��["�:Z�'��r7�5��R�}���_PV�����` �;7���?'��Ƶ%��2 B5G�R�I��V{������9	��O��w�g-�1MT<�y�v�B�!�ot/ZX�-*���H�������$`�Cc0�hM��C���B]����j�=h�q���_���s2�
�Z�O��wk蚐���c�Aq�mu�?���/O�c �5茺���ܘT"���4�Vl2=��$������$�n>�Pd��N3ڭ��P�E{AeR2eƄڧ��v�ѹ��wʙ�1���>�v�� ��,��2���5�.]�ΨFQ���+�(����}oe���z� l��
Z�F�W��5,�Ii�V���t3�,G�ůyO���Ɗ
x^�VLw��Svp��.��X���k����״���i�;����[m.�֡��~տ&�;k�m?[ ߰�����*�Cˤ��=2�>r%���Y��m�?#��+�P]%����S���e�?~�5��Ҋ2�*/c~8��y�c�f�4t��HS�s:������*�=�zs����飧-fj�Z��:B,NF���a2�b���՘�`4:hg��f+��9�~U���!Y#��E,X�uj��"	&�R1�\2U����?������t�M������lv�[P
�AM��)��f��{�1E��@�.g���L�F�����NY�$��S!{z��
��s��
H�#z\`=�ɥ:����⡔sbl���D倬���ѹ-5l��f��U�f��H��s|�r���Y�!� �1���K��R4ǌ�?��#e�K���`�*�A��;��ZL�6c!���V}M|f��j$߂��|wk��nT��G �A���3l�",�ֻ@D6�rP=�{cÝ{��Wn2LG�\
�5�!��W�PzA��M�������&��.y¯k� ��c���,7���5��+�ި���8I��K~��ʌ�;�2�����&��@M����g#<�EA8b�Fw�!��yt��3���Y=�X�Q����!'����_:�Ө0��T=��F0���!�n�s��7MRK��;���>+\���o+���%)JZ7%��Ԫm��t�eE;1n�BW��9v��g\�o�Ƹ�(pӰ3�$]�c�ze�(N�[�s��"ėH��d7S�=m� �ȡp.X+�w]M]���G��N[èON�4<)Y4�׏�F���(ퟨ���C+Y!*e�O�.��������}T^�8�����JW�gy�x����}0�}�H+� ��)\�չ�5t*	W!{�%ׄ��.�tWx�.D×fCU$ҫ�g(�_�U;���:�!�@1�"�t�Zl���̐N^A{%td��i$�|7*�(�I�6!�
�h��c�{�#�N��dE�mq��Us���$?��r�=��~���e�-M�c��Y};.�W)�΍��6���<[6#�N��}��<��T�>�C_T���K�Z���;#�jg2�ػ�OFk�����F�?��.D�[޸���䵃C�/��ņlHn5t�pOŜ�@�[Y^���f�_�3Pz�wQ�0/��a����}	x���e?�6�M�C�/��5NP� ��W�tu�p�x���!s�i,�qe�젿L�)"��FN���# J`����Lb�AP^J�)WA>i7��ݛ����h"]�v2��S�MA�蠏��-�#��b̎")���&��6�b�K� �ʬ(I/�J�b��x���gc�*�
��/i���iL,D#�^�j��>��N�wMޫa����nԜ�*oR�c()����<F���F�'Z[� �����9Z��N��	`ʥ�"��nH�����1���YC�s��h�d �*]�h-$���x�{BrskM�9n�!6'�t^�9����vq�Qrl�Q+��=[�ᄰ|��,� )APGp��E�>z���8�q�#��<���˅��G'�M�q�m��T`�`U�+���G\�z��5�)ct�v��r�^�8��[h�V�AXd�Ex��`�b�ŗ��gD�APӏ����r���H��8�1^�� �7a��G67� ���2�-x/qS;�f�9x�H��U!��k�e}�����5ãd9�d�P��n�q(�wMf�����+��6^��LKNO�Ғ���bd���_c澏��R�.[��@ \|VQߐ��2�s��]�L-`�#�5���������19��e��.�`u�>�٩3X�8��}���+��Y�Y\:�Z�ow^�{KrH��ch���'���Կm`*�"��M]�N1�����ɜ�-�����hl
!���YV�������^i�g*u���P���z��~��C�Ki"��*
bDz����IJ^�%k�[��쎥=e�`�����:@�KG�k6z�����V�G_���f��0�~d��m@P���Fݚ>�����Y����	ߓT'�{/J��3��߼��/R��sl�/U1 ��aF�����n��='1�Iۊ��_T�֒Ǆ�d����j��\ũUゥ{?\M�N3?m+lo����FBWA�t�a����+]E�h���?+4����f��0 `�+2v�1T_2=��	��.uȺ�t ���@�	�W���ՅNS��J�es�%3�ю�E�Ā?�_�~	�J�%΂-���;���Ci��A��Q��ͻ�ҴX�V���� <d@&&q��J�L'� �֒�~Ҩ�6�B�z�Hԝ��P3�ۨ���wPʪ��1������S����;�M9lm�s��R����*�tP�}@��h���5f��L��Qk�o
E��۠0�ZHt4����~1��A��A3i�#*�6T�����1��I�_ѥ�����%�\t���������]���5f!��?U�m�k4T8�����a�wGסUdĦ��v^��n��Z�V��Ǳ𒶺[W��#V�� 捶�ؗ<Nnt�ŋC �S���f�Ѷ��ö5*
�r�U��Į�=�-����)�÷>!���l#�ۖ�W�xҶɳ�GZ7	�&��Q����2 @&�1���e?�d�t��VB��@�X,8��c���)� �Hi��Y�E�����&�Пi�m8E)�HP1�W T)���W�����R?ox\�m'��X�b��:>��{��o9���i	��x��Z�W��� �h�����5bnm�o�dQ�_T��b�}�$�BfǄL?���Q��
��x3���`KC��움B����P눏)f���~AP
ia��uJI8t6�t�o@�n��38�h�@s�a]S�`�?�S��+4gr�3x��Sh��w-�i�?N䤗��L�fu��bk=j��RY����X����s;�p�G�X�����8GWi�U�Q-�;![�dAL �vvy��e=���&1k���w�p�᮹.��O!�����kۋ�:EA[��ɠ�ԇ��w�7Lև��ă�J�t�����3���alA��&�(%nU��#��UKh�:��UM���h}�4��9LX&����<�h���!Ҩ��&GC�6g���%�|��E�d+�`��={Z::1x�Y: �7J�{�'��x9Cv�!mO�e~��.�8?c�,��8V����  �~����A ����Wu���g�    YZ