#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3859790559"
MD5="e067eb4cc67a04b23e94bbf80170aaab"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23928"
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
	echo Date of packaging: Thu Sep 30 18:36:15 -03 2021
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
�7zXZ  �ִF !   �X����]7] �}��1Dd]����P�t�D�|� �����~�s'�B�'���-�+�Q�� �e�&F*����m�d�|v�7���~4֭TN�	19���xN��?�Z��P��`0$7����킳V"�������K>���a�Ý�2�徊�0��ls��u�k�g2���hlU�;����D2�O,�;��U��L5�U���˵L��4������,b&ßÜ������Xdg�D���D�X@�m�����X�b��q�ǻc�f��,�g�(�wD��;��8��'�B(`�����59N$�0B�ۜ玟1�@ܟ�8� �����pz���yU�e0����m�/ػ�M���fͤ��[_�����юh �����Su��cɲ*��o(��3��{�՛�v�9��+�w,tdU�t�fZ�בX�b��ء�⮌jAs��:�^gAN������F�7�D��i	��A���F�?����p��dG��6#�f��Y�m�I�]qgu��3/��(-|�'�L��f�	��cRoiJF�tI��j�'�t�Y���_G��IpB�}��y?^�Xi�B2w�{=���qt�&ص�I�a�Bb&Ƨ��̭�d	�J�s�(r)�>�P��g�g��5���9���hw�B��#I���W�.!�3A�U���"�*��\Ĩ����|~%�t|7m��,�¦��(�
��e���}���́������
�ĵI	��tV�`&�T� �����1h�~y*��OV���i"���� yL�C��'��pU��W4j��׈�u�a����h�vZu�S���
�1ձg�͚ĉ�ڦ�w[�D�Ԏ������T�X�+�V��T�S�FK��X3�]d?�Cv���a+��)Ip홬>1y���Ť	�X��[�UH�ϣ�D��g�V�` �_�t���)߻fd�`)�cH ��V��Wp��:��`�L��^J����c�h*L�ç���>�2MiPZf�ɝ[���������Q6�;���Q6��f v�H�?��AB�;��l-SEM��Ec��ѭ7�?�_�#�q3xބ���Żڽ@�Y�@�c�r-E�퓟�-���"CA�LN�sA*��1�)@�c��,���B��GWLo:�6aR="�"G�O�G�_��Yj�9[*�5��+H6�	hI�H����e�m���e�	b�R<��|������ �WC���$�1��B/wv�tA��!������-�T�0j��џw[K �GL`��a?Y�x�3�oX�ޥ���_���n�y�*��~h�}L;i�y&�*�����tN�WѻUA�|-TlՄ��Xb���v88���s��խ���ȵt�B��kE�[y����oG����́$}��	��K������U�M�;ҟ�
TI-Jk���J����-q_.
s��l�rn���T��2��Ыfr�1I$��]L������|e��G7h����F�r�U;��]��b��8��
=����Hf`S�Ë��'4c�D˦XM��,I��d����P��}�4�������Ræ;���'D�h�[�L��TR�j=M��ý�N6~��{re���V2�%���Z����o��Tw�p^^fd*C�F�E:�%�z%R!�����#�M\�p�.-��@�w����1	��{�`�yO)-���ꎯ�L2肢2zd�ˉ2uv�S[�i�~�����[�u�-J��2{��'�ԛ������RD���n|3��P����3�I�q^R��sd�3��YX�Mx��U�h����ɊJ�`Dh_Y�G�#�zo�!1��a����h�/[~��s>�r���r�����#Z��_�e��M���<����H�G�DO���P�%�òb�~��`�����҅%n�h󞒫29�"�)��<i�a�.��h� $�yw��uF�j��ؕM�_TY��Aۉ���_F�I�}�m����-׈��.��QK����~��C-d�y�3�:�C��*����W
ǚ��qns#������1�y���h�-^�Z�2L��E��Pzf�֌�n��ɖ��K۞����T~+�KR̻0��ug���8��Q���L��zM%&��K�<����Tq'h��u!A�ؚꤱE�_�����bz��L��1n��X�/���X���rr����,N#\|��k�U
k��	�T�\�t�ۊ2�%��-m��M�]w+;�|��˨�;���X'����U���d\s�t�0�_Er_�^d���ă����M~��( �=����t�Ӽ���6vX����R�w��o:R��6����qP� Yޔ�B��]xO�7����tN�j�$��q]OkkA�������*��nٓ� ��ϭy�/u���{W]��* y1ɏE���*�`����~�f"��s�s��o?�R� �{yk^ �m�c����3X��5i9�r#�鋳��}H�0�vW��=q |��(����𑈀=�A���h�GJ�ۑ0#��0J��r"y|���1?�y+]q�}�N�,�����C�2V�KCF~0�CB;�!Ą�S۾$�b��R��xA�&���۞�6��ā�a?��×��@�U��}���%1+�N\z�T6%��s�T��X� ���[fR~��>�5�*}�kZ����3cil����cV����twR��uq�F�M.a��g. ʔ�|��HC�c��}���?�Er����P&�2��9�ډ�\�)Z����䠰I�t��v���n^fH(,��ny���'���4�)p�[�΢�(�n���(�.��N"�N�A�s�Cl�2��[Q~V+[�|+� )f���6tH�.�ԆdM	����{����-Q}��+�crcmg���y0����`��gXn�Ԣ��7�GH;����w�>�h�k|[����EU��� 6n�k�֙�H��Q�;Ϳf�*cum��Dg�^�wLRr�
b��^8�/����e!����" 8i]!���5��D�VZؐE�[��gfk.ͬլ��#��fҮ�L}t���[_�^Y��ؽ�`��V�C��y�B.���arTh'�4S|(��0�I�t� l]:�O������X�l����fA6 `~z<�be��1Y}Q�R��?��zq�h\��'Ȝ6�[��M�i�y�����}���go�\+�S~XC?�{C��xQlW�]��p�G�m`5y_�����0�'�]Jy\AW�����筴t���L�EJ�}E��,�uu�٩'R�aj�Xь�-��K��n��lˏ�v�y�ӊ5R�V���3	Х�~Hʐ(���bL|��3���qI���}�g-����2A�%lܐ�O�NS���ίI��q]WyGwǢl�V�C��y|G,5y�9HS:�d�m�ʂ�)�C��&;���21���2����K�<aA�ݒtR���K�Ϥ�^bD�/s랻##Ț�����G9�?��~� ���_:_�)����"F��D�<��􂂼�²Տ��N#-a�'8����> �� b�ʌ����q't�Ud/V�lcf���ҪQ�	�5�fg���E��B��w�6�Ǳ���ڴ�|�X�Ǡ�kJ��\O���Q�iP��ˉ7��(�ʨi2O�	����UY=���}��(�J�6�)pz"�D\�b���
�zb>��������K�veD��&͘�JG,�_���e�Ӄh�6Y��;�.���-C/U�N$S� �8m��|J��W�kaƙ��z?��\�� ��%�.TBee�U���a{��]J��V�\���w��# �|�b�6��8yo]�����O���C�x�h���~ڵ�o���a�4����zs"H�d�i�1c\�1���3@�7�跘�\1�����+$	x9��_�u��s~P'���Z�_���!?��� >-�K��;�����:KL�+�������bƖ���QtH]�PU�B
lN�M;,��𥂡 9��;�d�������4����0d��l�;�ζ�g��z]�7�m?��0\�F��l߀�F�7�1]52�ܜ��kz3H���X�#���㞟����pC���3'�o�,�bxn���$Dƀ7Q���4}�^���m�;��/s
��ki��]�_��4a&�(,-n��[|���\��x�
}|��W�8c� 7�$EM�ۓ�M7*�^��q7�^U{F��$Q�[���i�J	&W�^Z����ȼ����c�hي�g5GbD��K��eKU7`�5E�����^��9� ub �#"쩔7E
�m�j=HO�N���7�6��{$/����7ӽ����[q�l��,^p�������������'��?�-o�֕ς'ϚKy}P�_�=�1�e�DD�m��|�
��:D�1�H��X��R���|̷�PK��
��4!M��B���T4K�:T9���X�̡��IJ�&�P�!7z�,Vg��}�V��h��s�ZeDwdTXb���N�����]���I�g�P�l^Ϫ�o�)b<�j���)����F�lҼ����۫��{ ��O�oun��;=��Xԉ���V�^F]혤Z�J"��^�8̃=�#+L���_��5�4��g�ly �hF���U|�>�=�!}��%���N7d�9F:��P�r���#"lbۜ9�fG�%�N���>kG���i��rU2�f�&��17��^�vWJ_�]�B���1Q�u�3��D��
k���U|��g�k<`�-N��� ��	4����6�@ނ�}�G��c$ӛ7�N��Gζ:�+T�ZFX�`�vh�9���}[�D��|�R�y��,U���������X�Մԋ�� �9���Zq��LU���ݫ��Щ��������b@T��aQ�%����*�}<g(؁��P�X�'��|��ޒ�b1�x�@Ð�A�u�Έ�����F˚�_�Q�i.�FK(���6EV����!��/"����g����rUU�����7��xGP��[���h��T����r���0[�q�Y�Pw��B:�D�4Z0��
��@���c�
q���q���h�1�+�����L#��)6β����(õʜ�*�#�<�6l�CC�Q������LX�覽8���������9�Y��aiVWn�+J)��s �;N��ɔ�ڏ˅�r;���J5k_�I���u1��5o�w-��ɢ	��q����������ST[���1a�Y/���L���~c�@��r�`S7*�^��Ii��Y�������y�w��L>�r�]q�Ch��vϹ+M�N.�>"���0��z�������C<��{M�$�R�+H��hӆt �(`��6�z�k4�gr�^�7��	셸i�
o��֌ä�<~���i����E;۸�pLQ#f����.�ӱ��nK�M7��g��Y��Ux�!\||!ז���f�_���4��(.�{��9�C::����/�Ņw�0�>+��t@}�8�*�b5~4?�N�Y~v��&����ܻ��=�N���.g��#�I�a�y0.ǅ�E�H�N�͕ebsf���`���@2b^�R��e�¸��4��|J�CV�3���w*�� ʐ`K+� `����E��4��e�YSjj&������<B�~�3@�9;7s����0wB8\����" h��@����O_�F�*`&�h'l�u�x^���fD��ҔUU*��'�.^ Ts��3K�eI6��=�Iٟ�?`�t���V���5_�\��]���[g�D�u�k��Z��i�1���P�R�O(�%GO[ B�X캛>`�ԉ$pi�C�t2H����OO�Ö��"�o�`o�A(!U�0C�˕{&7E|��|Q��-̅Xvɛ!z{�+�g��#�}�����J�v�����.�N���}�:��#�u���p�Zn�~�{�jhS��ʷ]G�rNq]NC�������]�����Ĝ�u%�����] ��
L�y x�n�^�BJ�y����o��-�^�92�?��mҒ����8���� �DN���[Ê_���:E������y|�j�x�2i��i�������V���9��ʐ��/Kp>�� 6�05� |�w ��.��W���BƖ[�ڲ�9��*	�'MݗϮ�|�й|���W^
�r:����>%qD�d�%b��+�+�@��>#aP:���]�PڕY�uc�*[$G�*�&��㊬Ẅk4q>�`��w^uQ@xm@�5��
r��,��&.x{��M��&|��0��'؜�'V����f����Z�������)HX��ײ��dM����1!c�En	[$�7rjP��� ��"�W��b�GV&�x�JvEТ�l��$Ƒp�XQ7�� H�0]��?�i�x)n���{{���@���鄑\�ß��Ѳ��XͶ���X��M�S"��%K\5	�ZUU���f[��e00���&r})�3��)���\4�C��%��!N�_���L0���ͼ�7��Á�`�`��8�Q����e�a���g��!�����>��/��E��[�
�Y� ���j�ď���\x��%K~��)�:��LI9�8@�3�&׹	�Yv��<\7�4R�̼x���oT�SD���s����o���-�bp�Q���s��u�孩GX����m�Wh�����D�����kM�S]�|W`TT�Z)E"�?m��M����D��g��搁�^�TN"���b��/d\��,���Ͱ���pR-�W�X
��ƶ7/MGM��L27V�����?���킙���汆Ϊ���@��"F�Q4w�p����:���M$}�5��1�Fn��i*{>6B��偺9��c�.Gm�Ϙ��uZW�s�7��_96x諛���R��Gw����v>�ƀy,0��R��q$i+�;��@��p-F"-iM!�%56���ǉ�	9�$���٠�zH�hh���$�ԕ~[�&սs4�\�bdbg��� pq�g�����B����<�v��v�|���}[k�~x���S�5g<%�/~��w��+�8����v����o(<D����b���	�G&���,.�K�}~�2�������V�V����X&�m�S�_�Xbu��LV���x����Tr��ahi�+����~Sr-޼��9�;3�:�!�]��	[�Ǹ7Z}��z����5�Q�7*U�֍p�w�1(f�"�((E-���N`O9ʦu.؄c�y��i}PtZ��Y�8�6t�,d%-�V��W"gͽ��F��}I��2=�}�Ŏ�o1C�q��ӫG�
��*^��'��%3N
�&�?��u�O ��X��h���,0r�3�}�4Xv҈ ����W嚵��,5�g#�:ޭ�0˒.���aJ�Y﬽�B��H�qA�4����sn�\ M��΀3Ŷi�"a����}����_�ii�T��B�ZX$���b�����NCA�����l����B���C�6������C�V?�J�m�Y���i8��m��D�P���SL�����m$
s�-c)x[�mX��s�H�~uN-��AAV�
����T�- �ā�ú E,f�B�<B>�����l�F��|� 8\�Xfͯ>��
"8��
N�=v�1���CM�O���� �8A�=T�ƥ�M[�j���$������b��P��m�rq:����l<%^��D�3�,�ʭ� ;���9�Rj��+GR.�L�O~f�Q�=�t�$� x�u�a��W>&��b,��g��:%`oqS�d��ab�����+s1z6��w�K: ۭ��i�����R�M�W)Q�}5�b�nT���z��[ڽ��F:���w�NE���+�����S2ñ.�ɳ.w��(�7jr�2���S��Sq��T����~�$��á���H"��vD�;4w������|T"ɔ�z�r��urv�����"eK��(`�����q�Vu�0�AC@񛭃z�9����N�h���/�����ނ�E�҅�2�60G=d��b#�������^��WLu�M��E�X��\bX�@Ƅ������a܈<��������-G\:�Pǻ������h,��V Xp�l�-���*�w�A�"�q=OH:��Ҡo�0B�Z��Rw�(~�AN8>UD��Ao���4~�>����\�#G�U��́'`#�����d'���J����c�����d,Az��IA>��Zg���)��fk~�*����/���`��D&!��)S�-r�o�O�B6߁���M����DT�մk�E�9m�rJ8�N3��˕w�V�t�1=]�:w�X��>�}����v�+�T�9�r	���w���;e{�Fe�s �a(�.�ɺJ)v��Y�B@�&i�C]	�G
��j�%���:�Χ���"�0�i�wEj�S�ʙF�-�����:�Z����=y#�B؊Z��A�N�0���p& �B��|�m�	i�î-���tΓ}R�]��O WAY�1����RA���*B��6=5͍�!
+��-7�,������vUB6������ͳ|�֙�5���A����82�YFi_.Rr�m�rCx5� F�����0-�.�w�r߽����bpP�sbd�t-c�G�P#��`���������A�˯c)>k�\���Wk6�QO�o6>�ڑ�@�w��V[M��+��gr���&74M�`���vB���W�Kǥ�Đ�&s�g�5C�Է���.����F���-[~��Oe�����)�UZ��%��Ո���O�k+��B��Gb|���#��瀌<��c����q�3j�>��fǂ�|Q�!Ox��B�1��NN��j6��Emeķ��0��xP�5>���/�/O\EOX%���I�$qn�II~Y��EU�7(������q�S�6��ڝ�R����8�-j]�˱r�ޣ9M�"iC�Q
}m���g��X��`QWG9�d�BJ��Ԛ���Xd�ͧr���|*t5&k�O��j��l���ŵ�>&V�tEI�V�T�ܮi[�ˑ� ��Zg����¨�L�Q5��hmoL�Ad��&���쒑y��X�cc2�>>xB�2�ē�kƜ�d���Uv�\q8Э�.�[����������g}P0f��֠�|�L�)�����0.����$4�,�8mhk)qӢ��tNL��DT>?�eV8��; ��4q�1��F�~�*���=A�m��Ɩj��
~��[�U�nk⚇��B��B�l쒖"wE�K��Ԯ�'��<�9)�p�xE�1���N�n�����JR�jTɒ%5��!}�L<	0B!d �u?i#�C���e$6�'u���V����z3��A 졟`BB��(���|�܇jJ��`J[�\N,�͛ʅ���Kz��}+�2���ͬ�y���5?�{�Q�;��	�\�kPMp]��V�|��]�k���� �wמ��V�RIc�f-+Wԗ�����>�Y�G��Wmcj�d�+A�!�z�{��n5�TR� v�f!Ŕ0!r�����h
&�7[�n��$��nƵ���x
6{HJ�HH��M1�6�<�x���8�c��e�)q�![<����ģS�����~����}X�G� Q�N̨�(�SS2�WJ� ���N���ԅa�̫�"V��m�g�>MI9�$r��Pe�P�Q{k.�;bT�y`��c.��`J�LT�@�q�8ƭ���^��8��@O�x(A`dtEt&��y"m�ɷ�(��FYŌ��׍����#�����T��D&�qcRt0x��U��6-3%B��៍�� ����(.nV溎�I�5�k���gE�|r�p��<G��(�e���p��ɭ-d�A�i�U����, OQ$	����3?,t��
�-��%H�;��P��������2���-�kƉNG�oazHC�������J����$]œ����D�b�{����a��j�B޿�T@�Ĳ�%�6�-MN�"bY&<{��+=>�u�:X�%K�}Hf�{ ����]�j�����v��'��@��u�����H@����5���p���Kk��`��Z�v�,=N�' |���?�b�x�#�� �8WT���\�C�4�{d@�t
>�%�ۅSL���#��vE���E;���pkv�b�f��0���]NFM
E���/l��O��Q��U�L���~A�
��&��t�ұ��ʔ�����������Q"A��F�r����ـ�#:�.�_���%��:Q�1�{�!��V	��[��/:��6�0�=s;�ͮf^ƙQ�����Kz�ʈa�]�^�>*�R�m�2j"=$��\l�:?1�S�B����
ݛ�c]h'�\'KVv��z|}�p쇺k�+(�N\N�v�/D�����Ϳ@@$T�C
4dfЎw�j���)`�J�*�����}�y]D��? C�������R��[o�uK�-���1�#-k����k�D/�f4[��y}x��p�[sJ�Ua��U��[��� ����/_@6P�~�}�/]UBM�]^�;)#/1G��p������L�Cm}Ó:�ʟ�	o�?F�S��ӣ �3u�L7e>����|m�y�箙xE�E�T>��ad��Ǭ���x�#m̅4Ѫ+5���lݝd�r�|�k��@�s���v|�~�!���Wgv�	�I_׍��#������Ո������zS8ez��:��Ư��p�;�V"�
����T"����hf:o���[h��N��h�/q����Es���e��Ϫ���8;�>���~m�:Kǵ�zQ=���^<v �Dl�M�(��Ro�mjn�xI�v�
v<<xLOo[ü9�YG �zC#��ʁ��]8�K��*��j,��]�ML��1�ψ��؄�D��^���L�E�y�?��/P k��5\��϶�=�zH��}G�"�p.��kooGr�T*����1N�����N�(�A@��Dqކ�f���r��z�T�Fp��(�4�e�|�Scj��������}��ijFnS���\ĥÞL�ɇ��:�
oW]���6�-�o?�@n�N*x}�ۅ*��k��g�`,��ټb�t(I��ʕ"< {�n�j7Ts���Hm��E���z/g�~&�0�zD�����on���G����)�>�(M�Cv��1;=�NIǘH�q��Xw1�;��,��٧��E���P5T��e��L"����ۺE��su�c���h�m!��$��<��Mp ��%�����.� t�[2tk`�$3c%�<ؘ�Ւ�B�e��I���-�w1T��5c��-��9-����B�r+.�u�ը���U?���X�ɬu�,{]�H��;��j��e�#G���\N�i�l��W�?��[ƪzv�x��`�n�r��g�����]"�GQ@����e��I�������	D�R�i�� �҄>�풻���v��@K�w9�'�8k�^M�q��;��4ɏ(��9_�DV��᪠���{��/��7�+��j�~~�\W;G���Ç�R���7b4�pA�Z�3�h&ә�)*��Y�S�@�VqP�N��+Q���a�v�wA�\x�nЊ ���v�Y��P�Jf�Ϙ�1�X gje��Q� C���XRJa8��V���W���m���4�תm�y�\_h����9�Y[fXވ���U��<B�yk�����{���r�t����Y	��WNw�~Ȩk��E��pe)c}�����?���4R�r�����G���Z�"%H���?�5��n�Ԕ��<�mD�r�<�vSPz�½���/AY���k#�4<�FH���qB�}��&@��s�Hb���v��9sdˢ���&���j&kD��� P���
ɫ�I7�^d|�3M����挓��U�iz���r�����+�{Rd��������x���b�ʞ���DDsנ^��.�3�  �>�Z��Z��B��R�'��z�H}��yjX)��o�HD��fX(�9P��9}����ckx�qN_}�@�.eN滾>�J��}���@���6>���Q���F	�S�	�<fUh��g�A�Z�z��hz�o󃤁�m>řM��V8+����njڍ7$��5�W��;���ԄN�8t����'<��PHb����]�r\�y5�6�nW�]��;��u��K_S� �>�S,(��sՀ4D��?-�"�j�4�%\�LYd����!�[����'�o;�!y2��7�����͖���i���������}�m�lj��R�I-� � ��j���9
Dֱw��8	��E}"=s[�ċ��/������9|B���E6��]�nUBϸ/-&0��?u��N�CG�����:�15���
Ƕ�iI8Q<��<��/\�__�ˣ��[8>�(�<���F��V�:���$)O���������Ē�ԑ$�:a�I��w�^��hN���|m}y��Ϗ�V�V�ꏦ>�v���w=8��Vn�g�P܏/��(��/��e���gL[����h�-N�������G���|-#x��U�#�/��R�A�|��p�[ކ��k.����;��Ǣ�J%G��dQ��M��vFNK��>�n
S��K����᝼�z���j?�V���
� h���I?���B����u2�޵uQns�l!K,Q��]��:�~�wy�m6b���P]�H�>Ww�	���Fy	3;��P����$T�9��H�^i^S�\|�k�tY9h�Us�"�����lrNץ�u���ǭ�?qܩ��^��ZE?/���W�7���{%������@����r�,�z;�}�bj�)?��`�P�U���0����<��M�i�o��@��F��ߚ벝a-���V!	6<0�쫴Ɍ�i��gi�fh�14O�&�v����?�x;��QlL����C�L��Aߪᅀl���$�����#9ˡ����R]lV�oJ*ť�}-E}>Iffn�ݗ$�}��P�|O�`�&撉�w�EIb��N������xp���|�Vȏʉ�'Ъ���1�'ċ�E%����1��~2��j��	5�i�oǆ���\�y�kN. ,��6���c����VoDĊ!4�7v*���#� `	S�������ۮ3����[�IW9!$���@�*��7�l:S��9������� ����[���P��2<�@����:Z�?DQ�6��o]b���0��<�׾Cr�Bl�-�+UK�|ǳ��^�l**6̱:���>��:�g�&W�p�vv~��鎧u��'��UVe��C���3����s�sR�\� ���)��P�2P>HQ
9��<]h�`���>�!���v���C��v���kv�Vi̺4��kMY�%����vf������EX����L!�OH���c�7��7b�fE�.�)Z4&�� Ve�e�G��[�`���m��=������p�/S�V?���1iS�R�(;>����C�l��aɈ����)���/p;�?Pܠ����^�8����,�c��J�%�'�gNR���J���AU�D'�_: �[Ct���+��j�Z�i%��Mm*����� �@�hr[j��Q�\�vL���u� ܲ0c�H��U�D(țnȇ�f�^T�n�I����IySj�q����jS^9�0���:��MM�9���z(�j��œ([�,�(7dVװ�+o-�C�_�@wVi�N�U>����+�LC'���h� ��'���z�L�R�X��#��R��󔚐{�[�tx���1P|�,h���h�I���g5�G�������>�a�g���|R�����U��.��T��	�i֡�
y����>o���%�E.�]7ւ�����F���O�0�R�$%�W@�D��n��q�l�	��=A?�[�9*������0�ƏD�ث>�c�y�f
��Ku���!���}�>}*���߭�L)��t�_]F����<'���G�Ϥ���G�Bm��iN�'�D�	��K$w��X���;	n��G�qU��w�.�6��`���L�H��XA���gyP��]�^KR�����Tԅ����e�4��Ě�2�1Cu��c��H&ũ��3�E�6��Z�߆i�������
5�VTsJDu�0h9�I�S��]���Is�4l7�� �t���+L-"R$	���j��k��JW��B���e���M�;Ӈc<�NX��� �P���g���k��o�O�Ib���n k�ɱ���� d�hY�Ixܜ�K�!�j���� ��V��X�k���퍎?W���h
Z�rL��6Wio<#�U���5��ncW+�P$��B�]��&�u9 +j��A)0n}�T��j�c��yJu�P*�=ؚH�2D�6h!9�"����$�o��_oN7�Js�k1�$��-��&o�{_?������Z�y�%B����3�b�%�[��%��b e�ONO���J��XY�~��'��5|P}���9t�f֔rBq��g�+��l��ˠf9l��o�`�'Y�w.5�.���i:�����H�Bp6~��6��'���bcQF~L�� j��9g��Tn����l� �-}�O�=d$;j�ʆ)��-���>t �8���3�u{s��[ 9̋N����-��C���N=�x�qӤ�e��o8����8R�݅��%�W�q�n�>�����T�:���
���F�`{�?3ˎR�|�K6�_�1���'��Qq`��Qʙ��K�>���)d�|��(0�EGh�	��>��v	�@�-ʅ'`�spk���P4�[��g��
I)�0�9����P����<M9���0y�?_�O��3ֶBp��бu&��g;�伜a}n䚘��C?�",��Ɗʢ�ǰ]��v�
��� ��ܡ���W�`���f*��1��>z	�H���t1�3ϧs� &?��4�zj���|[k2m���5u�@�v��i�F�@~0U����!�]���4 �z��&���X��"͘o'2�8�z۳���3 �x�4��<g���f@ko��|nf:�k�ލR����c�REna�?='��d��%C,�Ӌ�s�0��Đ���ea��i����\�	���0�"�X�)ʮ+~N̨�V)�<`��u��c���]"'շ���1Ye�X;|�kH�����bw���>H�����g5g�f�xZV�~L�>:�h�!�Z?pT��kV�jA��a�9�(h^����=o;�6_��=�7��]J�����!�\�6;(��Y}cf�1�J[!۶�a��BŤ
�.:K��ds&"tm��R*�}�����7���]�-�����ܭy9�.G����|e���dE����ۜ��ƋKe�W� �c�����|���k����b��,���8<��#)�G������q%WU�����|65��8��0�~��iۭX#EV:0�ś����X�T������}��.bi���P
HD�[s}��rb:]^����,��!�,��nތ�kkorw*��ˇ8�yk_Q��%�ŲA��&�$'3R~��9��|�: o��@�ɡ����M� ���5O. ��J�ʲ��$�/��7�'��u���^?�
J��O�j
"`ǖW̧u�>ݕ�*��q�U ¢��N}�od�/W�0y��vV{���Λ�Z�9��O��j�ij��}7֙�`�>A?V�0S�q�j�6;����)1�yn�^?utE�@�����&&P��޺�^��g}@\�qך4	4-us�^�[Q&�	�{CV�I_�,Ek��ҼuL��_���jV���������X��l�Ƅ�OFZ����i�Ǣ�t�؛�|U����Q��@u��x��cr�W�>CD��T���sB�#�f��%m�����oi5;U�H��½�OqȐ:n��%����:!���s)�n�
u�S�I�,^�`xC����Cy�q�1�7Ӌ��e�F=o��{�޿gG��=i&��Px�+���/��(c�WՑ�]�$\�{>��/*����îvɗ�YI���Ւ�BU�Xr�ڹ�KU���oa�@�7��d�����2cl�8�] k_�� r�S�D��xj���vE�Cw+ ��e�B�|�2w"�$谷�r[$
�D�9n���̸��;1Ұ�oN	�Ƈ��M�����1����~�t7�b���ߊ�0�&\<��ɜ9�g�xf � ���b1�UՏy���&�hLvAIU�63x$Y{�\ݓ�gſ�!���^L��8�⿤���P:�j�f�-���h��m+b�س�ۏj�=��	A�`�v��u��#���?��X�.�64�]\�r�bR�5�����iؑ���c(N+�����4f�#�&���2�a���D�V{�����Ǆx�1���n�j�	)�Θ_%�c1�6 �J�X�A:ms|�1�;�t Tp�5��dꝽˋ���hQ��۹���H�sT��iX��*���N[q6�F����bbT���|��Hѩ��p�QB�H�
�"����^�����ŚxXu��t��_s��g���2X@��ܨ�� �QCoa��� ���˽�V��f��v�X�w�G�!���jG�[���Wb�V���=��N�w� �I,͏Fv�����>�1�[��O�BF&�ʫШk�!��q�9ݴ�6@L�b���6wK<�vƟ�0����ʹ��{�'v{��&o���z�^�ʡ\^���s�þk��ǎc`�B'�$�(`J{S�J�hH�,��d��b��P1��9��X��nXҀi��`�K�X?�zi��'�l[$2/�wf�_�!
��";x���z��%{,�F�U�g�w$ ��!]�I�3*i|W?~���ˀ/�yS�J�Ӈ�vE�V=�����?R/J��("'�P��snt|�銇a�W�j��^}n�O���g>�O�^S�~��ׂ��V���mSMŞ����z��j�`3��R4�f��Z�w����*��I��L_J��%��2��.�bݸ4�c�;y���7�"���M�����s��x�|��i;\"oOt�S\������c���M8R�9:�-3#�<[,�m�����Z��'D��ʪh�v��7xJ�q��H{��+��a�{ �P�e2���*J5�r�K�I�,��3z�<�6�Y���a)m��q�J�^Ā��-�r�(z^�1��p���DO���լIQw��0f�Ū�Q��2�`���>��M}���?L폍Wl\e��ड़9z�[-������J����)��_�;���f7�Э�H����<���_w���A=�Պ<�ץ�~n�@�����e �ue=T^w"�3�kQ������v�iс���X=>���.)�fe�Wc�$=��ޘ_eZ�X�U*�� oM��Q�b|d O��1o<ƽ� CQF��J. D�Lz�s����R��rÎhca�~�)�+DB�����,%+�1S��R<4HL����UB/�b�Yމ��eYWJm�")�}�$Ro2�h*�S���%J���vGLaB^��	��Ĩ��	����r0OJN#���+��˥�GM|��D�K�e��M$�Tq��Cϐ&'��+������7G��g(;�ӎdJ�Ir���H�cu�`���d���Z�m#_�k�bz�z@���I�Y��^�����F���(*!�yD��GwXJv��D��Q��<���n�'!�3/��JS6���44K�<o�E����.�'�`�Kb����&w�W��`�܌�;�,c.43'�݄��4�M4	³Z<�"���#���F��'�1(��O8�z�I����"py.d�/Z�l �8&�imi�\�NV��kf��������'F4൞�G���t�|�3���Pfwm[rMh8&���IZV�������D9�r��F{enf��>&��N?IU���n��r|�|P}������Oq)��b���m��V���z��:� �^m#���P���jT���H��j�U�� ����k��F�S�t�aS�����O������b����I��Guǖ�C�[���*�&3��8�l.��O,*,���ʲ+�/c-_	�����̜֭�4y��^��*�vj�
�Qx3J���Wst?&K�P�s�E��#�Гl��Y����'
�פj/^�����n��ep7h�CE�o쫛e��ˏܽ��Ќ�"=П��|��Xk��Ѡ𴦌4f��w\,;�������m��Y��,�d�͓x�E
Y !dJ ᛰH^�`7��WV���(_Z[��22Wcn�r�f�;����H��Z������m�<��uL���[� H�.�������u%d�F8��R���R�sF���B��'�`����/0K�{��D�j&o��1�"���hE�lE���ع��*��F~<@I�e��	��JDIP�xӹ ����f�6/w��e��,	�ݾ�,�J��l�A����+٦ٍ?0ۀ�܀�i�'�"*o[>p�2�*U����EcN��%���g?�x��Ѵb=��k�gq$Y䪚�'�Ri,�ե�N��.��D�H��In{�t�u?�ê���14�]<���[��<�ho���7��SG�v]�� J2]�䊯��ixJf�ӣ�d~�'���ݕw���1mXlI�'�����42�q"�0�⤙��9�->����3Ig�	��KJ]#�up;��kl�p$/R�Яd`����sZPp�:�`&>?q��$�&�����[51q)����qV�P��a�~�zχ�J,���$��s3Z����{�VXV�@C�['�=����l�I�,�e�x!�Zp|�}�ٚؽPJO꒏|�| ��P�+KƖ5so��ǯ���/�ߎ�}UA��ȨV�a���r���n�ix�	�uN��1@����F�����T�1�,󜸬f�M�/��FЧC3�5�y�u�bkʰ+�^1���:�S�8�b��eh�2���/��y� ,� �z=|@�Vy$~�+�N�J�Q���k8	����*�x��R��k���4K�z�$ ��&����T�f���
�P.@�ӕ�	2]�P_KE�ƫ
VK�����{��Vz�aV=��k�st��z�x�Z���-��R��-O�7�C��f���F=#�Δs�LFIH��2�y6�l���6��k)C%�c����e;*^q�J��}O{�Ε�o���}�ǥ����e���XˊS+�!@+��$+�H�-�'�����p�e_R[�Bܖ�R]��3����ˎ�<\�7g��Lgڴ�5K#N2i�y ��D4zY�zr4�����{�䐴�n)��<��4������G8��r��^�t�A�٦���j:��̲�X���F�_��� ��M�Q���CB�ti�n�RP	�^T�x��"w9�\����Rr���0n�mְI�~� �I=ᛛڢV���M��Զ�����T�@5�m(ډ�b��M������j��ȬQ�ݎ��zЁ#��c���{p1V� �M��$3^Y��	{�hy1/���#��sI���v��WZ,�ߤ����˔��˔��F�~D9ZPQ�2f��L�G.A}���`���*V}����8�S4�q5*N,���ݪ�8n����6H'��i��<l������ �o�o�ŊV%$��0�>��'��I�C���M��C�5E�;���:8q԰&�"��C�����'An�ļL��[^�1�	��D��RB���ڟ��0��,tV.�ot�4���3^�Έ0~��6r�{d&����Ft����R���@S㸅*�q$��W�o�A��{�Z s/���V����� <�Q�\S���o�H��Ԋ��#Mɲ	��@;!�N`�h\�B�(ȇ���� "���2�\�Y fO���ŷ��ū�Y,�#��!՞̯�n���{�O}���6��g�Sk|�3����3�<�jB�2>~�Xwn��):���hf�t˯7��9�p!�,�"�S�w�O�~&O�*�~���#�?=6�ٖ�	u�ԵdWS��M�����2Bq���$}U�%������HV� ��|ؚ,����Sk7�ZX��sL�@<�)@4���E�8�-�O�SAͤe��?�$�O�$7����K$�.�3E�������w��]��䜵(�3�;�N/-s���4"]`����hΏD�g]ϰ^��%4��x���͒�'ȴ�K-�ą{��
ﶜYP��d�U'�bU�K�uI�e28S�`�͇U��+7!�x��dap�(�Y��v����U�H+��J�yhS��Y�l��f�,����Z���Ԣ5��J���JB�A%�"{�/�Qee���q̒���l�].z���h��{ǂq3�=*�0zRf`ݕk�
@�p�:��|���M��4�����Ķt1:��O���M��S�����O,�a���52�ؗ�?O��1�4�u�:���W��-J�Z"	���a�(���k������"�W��TW
dur��t��r��g&g�o�j^��+�Z!�&uށ=��p5?Z���e�� �"y�
���$���%ɟ�+�Ky�+5Tܥ�\9���.��+¦s����b���ID��6�,`o���?�A�}���7��n!�n�u'����C���$=f�Y�n���7ڿ� �����]�e��NU�!�)�!� ��ؾ��?���-9�����c�]P���0��0�F��u/����S,�+�r���U����8YZ��9��L����^��=����;<�>���������9@	_
�'��E�y�c��=zģ�c��|m���>Q3����j��ji-i3T��&�U�8e��CX<�]1d	��@*����]{|83�й�H���@����m�B�a�T��5q�_r�(�QӜ��: ݙ_�%�����kOid��AΩ�i�Sϵ��3��K������~���zR�*��L�,DŹp赞��
��wP��QRI�.���^��Z�� �$vE�D	#����g0�ޟ�M��6(gg�@^�ˇ� �n�K|U��vB��NO��j �0T@�/��HMQW�i�����屣4vL�u$��ʖ�b�|%`�����Kl�P���yF��4��kמ����L�}D�1�\��A�YK�J<�<��#uO7j���ٷk˛�ɥA�coƧ?�+���:��)
�姀� C}���m��J�x�ǉĩP��K|�����M��i΅�de`v=��D�Q��t�L�"m�X"Np���t��S�h�͹y��3���dk���D0��m���Г![���*?����[����u-Uι�Z�C�D��.�w�'�8o�5���9�kvN�Xk%K�6D��]|�V�LY����`J�P��VE	��G�L�� -��%��_Jp>m���C�"���CeB��ʄ�2��`��g�s�?�L4HK�X~#zl#u�Y��?qp�k�����%������h��n�J4%�����ɧ�^�˿���J1���IТU�v��l��:H\X�bw9�maڅ�W'��_l��L��#'uj*�ƾ�� �N��4z;��r�7�������o�����
%���.;@|��m�g������K*�І��.��D|�1:OHD2��k��Է�y����$2�����-�iC���Q,"د��,I�M���Y�c�zkqY{�y�m���t�{tb	$$Y��h�~P%E�:�]V�Ӗ(؋�p$�,��\K�zE�kV���y�b��ZҬ�%�#e������m^ ��,�3}�X=*+k^��zM�A:*��h�
��_$��e���⫞���ib��g�Uj.*���A
y  eG� ,�0�ՑpdC�1�l�$���g���!�-�,�5�t��|�xBMW�#V�G�!�I�Ol�җh�%�i�w��]���e��!�\;#��̒�@�C��[o�3һ=�i�1�$�l��/�x�T��"��FB~���R@�z] 3OCsY�#_����j;x���;jc:�gx���7l�;(%]�A\3�M�w��~�� �R�r��ٛ>��W|}�Ɠ���B�h�X�'�fHc>,x�4Q(��v�q�`I��Tr�Fn)s3I<�vH1�GT�ډ�L�n}�8����t6�g����mo饊"0�s>�|�K��ԧ�\�[6���%
#	|b�cv��Uy�y �j�S����5�����&C��wG0��#4���S�~�bY�"k�-�a�_,ciU��x����_S�����p�
q�M�ʏk	����`vܳ7�d��4D�D��e�������
@����]{Ʌ�.�;-���0��{a'BAC���)�2P���?�9�TThx���8;[Z�V��"�F�i�+|� uҖ��ɠW��˩sz��SkSzUU��&�����۽p��S>B4�/<T��ܾ�[_De�wM;Ѓ���� ����c e�V�R:�@Ko��H�W
.m�b�sS���iz�o�F��9�ƭ;*V-�=Rl�	���Q2�Ba[��N�따����Z��@6�%;p��g*2��C|�J���c)��kbu��+6���rG�*N���EGĂ���/`2�cq�l��)��@�ha4�{V�{*ej)rK#]F�3���~S80<<!T����.���U�qN�F{��c���j�7����L���^7�R�N�!�՚�ʷ��s�K�(��_t�Җ��\#��Ο4�
�p��>�{��.�,Ǳ�"�8��	��X��Fn̅l؁7 ��y�X�������t�QP�����-��J�}�x5~��}�ݳ������O��/i7�f�IǗû-�2CбF�MƏXi��+7#>8}P���.�����d|�p�fj�����d
����īC&8��$�Su�ȕ��.��s��FD����X�Ӏ�|m}�p��m8�X5�5�� ��RI�����5���a��W�R�y�_���;@,��&�(?��dFI���Xg������qЅ1�O�+��j�\&��L� ����7^7�ˬdV�Yl����6.~���IK�;�h�K������a��w<5�RO݆���̿���y�,��&��(�o����%�K�}d]��~p�H�G����bve`��Ƕ\��f�?
�?�`XR,�)�ޕ&�?uLe�0��UA�08H%]�_ gC>��^tS�^�2�fGV��6�1�{Q�=�Qp;N#���V����H�F~��Yd��ڞ�Ҥ�?��ެZ��˦��< G��y��p�+�͢�8���z����bӿ �[,Y*���N��#����W8��~�n2l�Y "#�6�ᓣ.k��\�uy������LU�#�����}���2�O��-;�%�Z7{ޏm�%�)u[������_�gk5�%x�D#Z���曠���P�[Ä�YT�2��#�sn��I�� �U<_�@5��w�8�@h��e4���[p5CxdwL��� ��54T�J�V3Ō�b��   ���CC� Ӻ��ᔟ��g�    YZ