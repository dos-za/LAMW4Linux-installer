#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2110468072"
MD5="5b968731913f881a81df63f2a2542ed9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24536"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 19:18:58 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
�7zXZ  �ִF !   �X����_�] �}��1Dd]����P�t�F�U_6�Sx�Q�T�\��_���w����lW�]��@�>����眊�!WM�~���|�_�S��^�PK��B�h_��H!��4�;�3_u�Ԝ�`��n�"I����(�i��8i�w�s�|G�2��r�!�e+�����i���ݣh���rm4<U���խk�C�?�.IuU��OMU���
�"\=����=`��ozp���_�7Â�7f��u�N}Q|N��'�O�H������,���6U<��\�`�ofb�����sۖ��b�7�c��˰��O"},%�
��6�s^��$	���$wp�} {�ΨgI�{E)U��W��S*{�9�v{^~Vtt���C��L�X8��9]?H�(i� �b�;���ƨ�7��@�-2{֟�(]���l��B�x��� � iE������ͨc�ʟ�N`6��2��S�_{r \�{9,��3�v)�T�~�p��:.y��ɵ̰���V��G��n��Ab�����_��&��*	R�/D�>~B�*_��+H3EǈO��u��{Ư떒um5*�X��\�Z4�w����H����3������8�M7N�x�g�����ʢ#���b�k�L�YdWr�-*[I�Y\T�ZV�����:�����UPg��f�T��ZULV�U��/!��'�WS�:F��9���Z���^�/}��E������b�����g(d2�+P��ɢ��K��'j�=����(tFo��m֗=e${�;���ѱ��>�bL�_���B��p�(Z���YB�h�F5+�~�i��V%���k���ɖ̶�̀8ĺ�P��x l�N����N{��WsI:�o�P\��5&.�u���ٽj���G����(����(��&�00��nZ|���Se��?�c�C�|�t50I
��~�t岔�蜂2ʦi�\�I�������J��Wj��u�ye���20}��i7���1��t�ڲ~SvƳ��/\e��F�ګ���d����열^���A��*翘���꾌,LĒ3H��E}m8V�����6m{���ULUj�&���x�<�J �AW�ɃT�;� t(v31HOOm���iG� ����^�a�5 ��̻�"PREQ�9�E���X�yC%e�|�<�[r�P ��)���� ��w���o�k�ٿ�R�lN�]9�j�d�C��M���V7�6����>Nf�o�#����]�&��(��򁉧+ Ҕ@��I<z\�ω�wa'�i�l>��4���0p1ߣ3u��.�r�c�]}�3���1m�N��ih���
�AJ˧��8{�.B��g�)���F$���؁\�@�۴�5X�J��'}����4,C��D��g�"ظyJ/wp��4�9p��2y��* A_/q���'|1�A��w/�ߨ�Uئ�p���%����QW/�:Z٭�7Ȅ�.��v�������=#�nmǼjQ��F�?]���>�����D��o4��(��πd]�	C�]�����m�68��p*�B���j�=��-T��I��ۄA!n|�P�-�LR��'��Wf��d��ktհQ� ��͕�S�k�?
4H�oG+�}�V����=^n�~�V�D�&�A�#e�;3�O�%Om _z�m�צ��|m95��C�E�u�&y�uud��CL�!|w���[��Pt�+�9��M����I����|���-2�������t�M]�,9ZE�ϐ���r�����H}W�P�GQq� 
,!��%n`q�G��cl>��Η���,�
Kt 8�&ר-0�Q���4�Vy�^aG˭6bMb"\Yުw[~7��_�6�/p.�	h{2�$�;�VC�'yMǘ�.a@�h�9��v,�mo�e��?˪E�U��u*�Y�ݨ�+[��䟷���B�)	2�WY��V�����U �W�n�
R�4Q��3Ƀ�%�Lk��0~�|)g��=��J�֞Z�����k<����T<n��#�)������6�(uI���m��QgLD*+y�e���6��D>8Kh^������N�.��=qK�qI+��g7ܘ�~���h,��!#4�I�y��ժ����*S��Ń��l�b���OG���E�/�N���B���qowrDj�\< �D��~@8��ug�Vϟ%�)+�i �c���p����Yj\������8Za�Fv�@"�DEdW�M��I�`�)8��S�f%�@��2xz�6A���Gm���F��q w�#�E���<�vIPr�ʌԽ���[h����������ɇ�~�ʬ�92)x"��D��
`_�D������G��e!.EPQ�0�+9�?�J����,�ѱ��+տ��DSǺA-}.`�)�%��R��e^`��]��&�e�®l��/��_ !�p:J�
8IϡzY&G��0�%E�W󇏁��$+���t5������d��e5pz��>&��y�?�h����2߅ �(z��?���.��QCI_eʸ;!��O�+u0A?�&�	Z��|` ��8�$�zg�m��ه��Z��Q�c	����ƒBRSԛ2u��-�z.3�G�����@ɇu1�:�(�3�QBƛ�$~�ܵ��3њ�FkXw�����*�MqS��%���:� :�S��ߠ�t	� -���(q,ɋ+���9h	�0=]}��b��!	��&Ǩe�\0�߳DC��p�`��6�Ho:�w�m%��MOcʞ4��$Q*�L��y\��G�r͛iQH�=u�1�0UFӪ(Y`*ѮR_xfR�s�t
)RH��^"���㷔Cv�R��+ZX��L> ����a�69TT�3�χr�[� gN�Td�ݫ�2�<̎����/l2fF���*��h����{�
Ij⽲�q����#��fX+�����t_��ߜ�y�*��>d�[vaiM����V>�hN��hW�?��	�)� ��%�C�i��E��X�_jh둲��2����@U*�G��V�2{ָ�s�v>�"A�|�Ϥ�K����2ȯ�1�?ЙO���#~���nX�L�}d��'*0��$�wO�J�.&�\��B��x��ɕ=���9?�l�(9e��$��ͫ�?�>�\���`D�J���@������N�ی�5��&�w��V-�&�(�EK/���0dN� g�Z����܏�7E@��R6��t�s�d,��*�6�e�1Pl�4h���}��\�{1�UM��������Y$��np���\���h��hu�ynr�y�dg|j�B�y@�K����f; �2�\��@ nb�����,��w�k�C�H�й�%�o�K��B܀6�I��-*\P���������+Bc���z��iȁm{6[�"HF=U�)����O։B�.�d�������#M���]��pMO0S
���08��	r�u,���s��!7k���@�Q��+�!�l:����%1���]EE�E7�"����2�#�1���*�ѱ�c�7cn������,�S�Vň�7�3U�`+4 NM#�袜�d�PJ�˂���O��rVř�
l���)�g�Nhj�m����W3�{��F`����`z������8�2-��9\��g�ysvND�/�ʋ�+H���

�fo���xSqn�(*��*�)g���u�w8k
Y�R=�B�"ѥ���e�� ć���ܲk���B�Ym���XR(�X���BfZ�44�"|�l�\!�ȱ{ʓ�m�"�-��!+�w��ʥ-8�m樖X�z�Ð�q�y���6�z�v<殇���<l_s,���c�� �_���J�9��+��,��H��[�%���Ƶ�^Pg¾��x�R�Y������^��佢o�h*:I��͍��P�ch���5I~�����OD��9�@l溥����Ĺ�'�H��/�Z �
Ѐٍ���e	��38g2����� �#N_��Ӥ7zN�VZU��j�?�q�� �;q�(�-��a뉻�4u�XO#,��hY���3�HA��?NPc��j��s�5`�%��b
a�.FI����q��rm�蕧�[��;��L]�U����Dm��{pk]8��̲���Usun��Xڴ�pcj��VM�k?p��>���xL���0~�c�]�G��
�������
��!�d�^)�B=�gwPP�*^�ѹ�.�Յ{Gh��i�/iڟ��wSۺF��K,�&�"1�[�G�Hy��T/�'�
�i��P���8�h�E2nU��c��hNr�����u��%6bA�<`e ������V�12Ki��m}�"Y�l5tX5y�5J�t���ım_!؝�F�nS��t�TY��>(�v�_�Gm�u
��5�"\��N�&�+�o�2��+�'J���O�A�:$Q����o0H���y��]�"ǁ ��g�fi�#�c� *�|�%�ɱWC�A���:��&t/��W����@�¡��6��< ��w��5<4�|w5�o�Qnr[Lx��m�XM� ��*��V�z�$�9L&���}�{c?W\?kp1[��,&�D����l�`�����H�״�=��D^�d�yQ�R�z)�� ��>���|�������!����0"5��K��#��E����&A<�ާYn
���E�	N�b��W�M+� ~�/���H�ZF!�������_D�ozuYW�J�߾����8�?����Q��0������[̷��6���~�t�&���@�V�4�q�g��?��D@��u��J>�?�9"� #���j��_�q�o�#��f�Yb���[6�W�K�t3�Q���
G���;|#�Q�	����Z�ɪ�:{�S�R�z���%l/T�4ّ�G�Lky]�ʹk�+rf�S���	z � k�D7���8=K#�w|����Y�ta�{�qb���ޣ�{�e�ݥ�)a$��w�"��:��Zj�*L�.�Q;<E��<O��d�T��.��sg�XLU��oS�\�t�e_7WZ��?~�x'@�|SE:�#�l���}�Z�e��Y}������k"�-�Roz���O�u�ė��;���fw_�e]Y[����/��h4\��M���'�2��H%�0�㮨�g�hnL�/^��� ���6D�p�p�W��k�� ��B�+˭	{�ޏ�]rW��##��8�Y��}���=8�Д3A����CЊ�M	a6y�6�7����6��G<��%v�0&U0�;��m��O&���K���8��6�CH�{�9��c��F����k�Ì�0��@q�6'�4� "�f��T ������y10�����=����ظ�e�
b@J�c�xL�@^o���l�QJٯnQ%;|��Z�I���BA��-��x-��ϲn�׆yy`L�n����Ti���$	6�v'm�
Dw^��`	�R�9�sO�׉�on�-�43ǝ����v� �"��a t�| ���O���D��{c�Ub����z�OO��黬
��S��b|��A�4Ґ~y���NH�i���/���8�LȆ�]\��Q�\�-;Ћ� w��l�;'���׈ތ����<��+�����{,t* -h��Ȯ�ix�p��µ���g�@�Z%4������p
�����ZU���W�Znߤ����=u
��t�`1��_ӽuj 3)=#F1]����W��Ae.��ݱSv�%e,F:����d�y������c���MJ�j�;"������a�3�[.�s%V�fU�!*�����.�9���_w8�IL$�?���ǯ�3��ŚLɜ/�x�A���W�M��AJ��Ŀ#k^�<~D2�NhI���%��,�A����*�^��	�Yrv���6r�7|"�ϳ����ܡ;�c�Bt�y?�_�o�s;wR��<���̂(8yK{�-��Ud��h;�?�C!�|�D�ո�����%��d��v��Q��=�r�U��{jiF��f����L�V���h\t��0��0z�f��]�G�^'�r��O�O�&������/�3`t�}v�C�,ep��;��E�}��B����n�Bj����nƻnw�iDث�^t442�̼(�+J������P�˝")n璚IJ�@�<]~{�	߲�M�77_ĉ@Yy!o~!��{/6c�s����ٔ�	-*=X��1����`7���:�(Ss����s�6˗u�o0�:�b:ְ+,�tp��C;�ap�"�7"�ބLꊤ�~���'�uA}e��C�=(����R���aj��Y��d��9x�&���9�:�dx�Z<��@���EG��}�MY�P6F��w̾C@,���[ⲍ �
A�u^��rJV	[�͜a*�D|B\t�^
N�z�|�R�.���OWNZfR��a�~K�9����I���5�����a �4�3&��yj���tAJ%՘!uڣl� �����'����e�B2�M��3]���v �ܷ ��l�8�ǫ��bTT|E_��E��S�����=�,�S��ׇ�4�����( k܂ ��6��M���k]Σ�)�t�lYJ*������X��Y_�f��� �bGj�$韀��9#8������b�<�꿷AWD(y�EM?&�^��!N�q���^�w�z�Ȉ�U�y�ߠ-t֡�׻�� �=��!��4H����6�v�=X\�3�~3�aA�����Tw�
�ƕ�����mh|���x2҆���}G>[m��(�X-)�݄��H!c�[�mm�F�C�)ڿ��٦��<a-b_�[���� �w����D��A�~�O(ZFs�q6���k!G!󤘕3%¯��[Y,�J��(;/zyl=�*�S����2?'�\x�s������e��L�����	zNs!�ڝOQ��Z��!��)TZs@�&�b�[DN_�0�fW7����B��m7axֽ9ve^�
3#�P�#E�)!�~j�}�p���a��$���@��:0	H-���o�i��T�5�3p}2��l�����vFʔ;Ϸ��i�~DL��N3]����Qf�h?GB�	�bkV�`��W��"����WEw1*V���T��>��둏�P��<�J���ܡ#��Iu�����.�L���#Ă'��sl���2����p¹��l<�������~�`�	��dn0|�t�B��ሂ54\��&)�kKIkt�Cxٜ��;�'�˪>����l{�M+��:���;T�Z��vlS[ &s�}`�$ـ{T��Suc+��S��#��.p˩<��Tb�D�ůH�}T\ ��U?<��.m%Q��dW��_�I+ �L�#9�&�:}j��� �W�̊�`�)�K@�V��{6��V&��1G��y7��U���<U�/3��9m[@�-���2������o~��C��1T����� ;��X2�M�H��|��j3���un�zj�vdwx�y4b�#��U���|!�_o9�f������O�ݻ��|撞z�K7K�_WE����� �^��R�f* ���L`��@\{#�f��dQ��s��___w>B��Rpl��(&B��	��aj�[�T�N�4;A�@���ua��'�-�z�+��kg���Q�A�4'��v���k�0�[u��]�bZ�eH:6Ynz��VZ��]V�b7������PP�Q��n�e����MT���<�]Q�O'Y��w�\����en�U��Н��̥�QT"_X#"��V��L��߄�#"Y^VPFR��|�IDwJ�TA�w��џ�B�54�} ��A������@ϸ|z#�������y��h/	6-Iނ���7��Nߐֻ	�*��+�Ґ�ɒ�J�D��t��y��/��I+�g�R��+�<*�_/�ct��W����4ϳ��V�~fR�����R�7~�ˠ5���x��������)����W,O,v��Q�FeDP�������dŒZ(�.w@��ȉ����}l/�
y��[�b���s��B�]'�&7�"O)���40'	�_6�v�b0�g��b"RNM��Z'Q���M������Y���SͪnR�ڋ���No��n������FS�5� ��n����������ߛ\}>��c<�!Y%�w���W�p^m{��*�����<��[3H_��!����	ԑ�����EkG����W�I��x3)�����rz����~����S�:��Ş�_��a� ��
EE��C2�.ȑS1�O�"�Xjb��	;*�d����vd�	��vb�&�]%�Qy�j�څO񔝙+�Q�Y��XDx�~䩑5^��cS+uo`�}����jڝ�p���Ӊ4�����6�]E���h�"��pX�=�AG���\�����_P�[�f�I�Ԉ-��@!�G�)�މ7��W��֕镉Gi'����t��-���:�a�&7���b��Q��� |44�}mfk?K(��6�_�ЀLh/� �`�+�/x<^K��k%�V�����;��N�R.'�[��G�����R�}u�5���B���h�4#ѿ������sB����(
�y~3����ӳ��e���?�X�kJ���(��অt�;
����H){��)�/"�.I���[�͛�%_Ů��t�\hT�ڪ��p�t}�)���σ�s�D,����
hϥ����-Z�-�v�3���@��.JzdO����n2A���n�e�X G�=�s����Aу�֭/�%?�7�V�<U&�qL\\0`�fGG��/n]��8�^�ӷ��ԡz��Z_F�.6K�;�Fm���4���x�~����O���Ӳ�j=��1���)*�y�qxF����C�!����V|`ps�9�nҝ�` �����9���\�d��a�h�{���c|��`|av��E��'>��5#W��K@���u���q#[^ri�-E�_wT������M�\��=���l��<I	Ұ5��Y�2��O�>
�We�Z����-�7	�4ƪt�bC{i ��Gr��oL�4�x����K�!*X��=����4!�q6X%X��yG�tU��]��`��D��X'w�cy�au���Hrg��$b���vs{$��n��V����>
Wհ!_F�"Ve�Lf�uD��b����1�h#�պ�mZ���q�D�*zI�Z���k�i��6�#TZ�z�5-V����[�	�zZd1���i�ej�qaI�؈�����O8��Θ��	�Brx��ڨ�]���pZ̉�����U@�1.���2�5^x���$�����<�����h"8X��s7�	�r�i@.���m�^b>ć�-��N�	�6yd�t��O�v.�䱵�����h��슋=��(5Ǔ�W�gR<{$Ȏ8۾�|U0�?�Y�͋�l��3�Z�U"��pzk����_��j-�_zx���T�1e	��}����yLw5״J��T�����I�YbP�E���=��`����V��r���;�̹~�n�_��M_����Ն�c���<�}�=ms� F
�4Ϲ�GaJ�b�Ķ2*6w�"�蛪�{�4|�ː�4[T
�{0 ���V\�G���xS|���p�΀e��Mnk�G^#��Ni6l$Y3��L����U�nq��܆3M�d�:�+�q��u`/g�~�����h��O��gr7zv����hѓFs�J_�	/"~�%�ܸ��u������f����̃����b�FZ�
�۴C��Q����ϳ���LO�X�M��S

#I׭�3��S�(��I-�����t8�8D��(�/�r��_�΁3'�Ƞ�K_��f�qMV<��*5��������Y���sƦ������ͽP#��U����$iՎ��X��r9|�H�ݳѲכֿ���^�Z6�[����y�i�U��1ԱV/�'���fZy"�t*�zsi���jP&�I����6@D�dx���O��>1'�l\T�B��h�~���D,[8^���R0WkW��X�F�oЍ�
�%0H�O?��i��1�r|�`�.��[;���Q6ʺ��q�,��0*���D�$�;[�LXj	.���#����;�Ge$Au\%PUʼ��ڥ�̖5r�<]��f�B��#��ݩ&"�',�l�[J:�>�"�Jr'&W@�p^=J�7#y_��Ej3x���3Buw��%�`b�uR��-�9B�(��vp��=���z�g� ]҅��9ֶ@\X�t�PM�Ԡ����}X���m���ő���ປ���my�]�QN4QTi�cRx�DU�0ߵ�}7Fh��U�KV�kխ���K����i��rxp���DyiT$&���	�"���ＫNNz=�����,` A"�aF3�䙅<��[���@e`]�ul1r���*d�w�e���+�a�F���S+�E�}�۞#j��T�B7�����X�x�%۹@>ߢ/d��x,�;�ۙwS�D����9�"T&�+ �e5��*vgZ���{`�E�"�����-P��z;�mh8��@�*�I�&���j��.Ch�� �B���V���c�BO29�P(�
n�Y��oYi5��e���S�i�qn�ܱT�f@K~B]�/��(Xx=�U�=�0���8�En���]��x�ְ�ۢF�Iak'P���K�M�ݳIQ�#8�d�N�8���p�\ >�e$�zQ7lS�)��wf>�kl�+�=xv]�e��gkҺ鑜�O����v%�o kF}�K�ǆ?p�-��zg�O��K_P��I�����bј,��pZ��0,2�"�QoK���ƞ;Jg�\���?}�RB���h��/xS�^e?ZV�W�\�3�Gcs�p�`��+�c�0��3��Pc*��y=��L��kE�1�!`���d0�B�	_V�������m�ʾ���'LA����J�2��J���Qya��b~2��Wq��6��DT�;��7�L��o���~�V���st��_�cl����z9�h��1�	��Y��T�tYe�αE�ؿ�
�T&�s�'Q���L���|�ECˍ�j�i���V��x��@����41)4��iU�qzI�K�����K����x�M�b�V�˟Z�SQ*-�y	�w�%^Z�B÷��>�������9��3f.��� �nN��eˏLT3)����7�Q�2�0���c�:������O��j��d��N�����7���0��k�?�GK(�{�MZ��;OǦX �[�y�IpƯ��=VKH[�-r��2�I��^��R��ʃ��;�&:��u�h~{��$�ڏ��Zk���+/D�-J�����S�c��VL�ϻE�~�C{�tݺ�Z�q�g�*��CG����}���s����9�,a�o�F�_�_$��.+��1QӀ����c0��um�	z�O�*�]���^[^���TF%IU�un���aC`��O!�/u�bLn��ɖ#�O=NX�Xu�둙�j� ��A��U� %�
��o��'���L�&�J���0	�m*F��rN�l��q����|�`�5��Uh3���x?n��]f���l}���q _@e���n�rI ��M�}�a=G4�G]� �������6٪x^w�	u[��b�Ǒ^~q7��I����͂��B��X�U;!��Tj����m�t����5�*^���C������� m*�|�[�:����e��}���;O&��] �@���2��A&�_�A@��:�h]����+��ǝ)ħ��稒�F�ʾ&F�3�̝,70ˮC�&_�����|��o	s�ǜ��<��% ;�*�_ْ����{��A���JA��{K����:u���s����{B��sẗ�@��abXe�v������06D#�F�f�#�^SG!A��(}bÃ��a�!eQ ߬a�7�f�a�d�B
'�*`��;lB(C>��qY�Om.�'y5�gF���.S�<J�_���r��%�S�㑕 _�kn7��U��IA�G�o0e ��)p�`s��hDNB�	N�4 p��bw�/�&��ɒ9�?������Md��8>,�]*�2�ߩ|״h��οH�Q��ϑ��v�jx�2��)��Rs6�Ä�`�/���|r.�l�;�8��=�w�w�Ƶ�,�+N������(ti��6�ѐ:�+/�6ڵ 9˶���΂p��Ǌ렇 să��d[g�W���G��"�#:�/F�y�M�c��OtD#��#84� ���(��[II�+��B���<��)	�xI�%*G&���w:�NV���s!¾yQ s�N���k�R�:Q[^���xu����mӖ֪����lo��{�o�変�
�Ӎ���-��K⻟P�q��,	~��ݟB�LT7������E�ژ��h[�v4��K@�3�ľ�a@���U'i����m��i{���}A_4����C���K��5���N�InK���8W��BY�͍����n�H~QvHcJ���z�M�fH?�bue�.���X�IEϴT�����7�2+�(0�����Q�F*g|��̫�&?�J��_aDx>�:�.�;�⣛�+���!��'��� ��!�cʫ�ɩ�4ȩo��I�cG��Y@��]X�O���7���0T��cZLd�9b�,�-闾g���/��	��]q}����?J}��&ΰ��9P`���ʆgxA	��B��Ĥ�u� (�1΢/��|�����si��g�F��
n*)�*m�W�>����{α됻|�P�ԕI�W��}�YY�����0U�x��`JZ�J8#؅av0�#�	�v]i��Yu�.����g�A��F�J�UY�x@��������b>- �Dou�����T�M"GcӫO洡�cTV��ƴ�`�@�s.�U ൴H!I&��n!���N����A���^��¶���M�A�,���5Qǚ�/l�+���0pm4&S���%'eæ�)�b{H�!)�_���|����-�<��� �� �>��f;Ֆ�s��h��o�u�z{HTe����r[E�a�5p��;q	S������UZ�L�_b�=��fs�bTJ��]�ǫ��=&v$`�]2���{���,G�����8?(�> 6xD|�(B�n&R~��JQ�6I�j � �2��D�!X����,�(���V=7
��1=������x�0q@IH���`��`_�ul$:/� mV����L%:�m�8C�����L��|&�����;J�'�Ů&���ۤ����&�Q^x��K�#NK��r�%㚝�B^��g�dm���q�ϖ��]i�HI#���@"fӪ�U��;!���5P��6E�v�<_�+�u(�4Gҋ����C��qf�������!*��Vl�$P�)�������y���F��i���N�hm�5�����.(���РȌQ`4�Eݬt3��-8l!��%��a藁"[O��f�~����6{�?�&���;��mK^������Q�T��d
g���.s/������X>�B�	b����?��AK�{w`�0�6��I�U4��O��H�1���$����4���"!�3o���@��rƂ�c��_��$�Vaw!�6+/���rw��c�&}�Kھ�~��c���x����o���L�\P��p#������@i�s(��Bګ~������W�����,�t�}0�E'&g~���V�d���I�{л����sn@3�e�9t>{��W>��-0�_�n��	�ە8����˭�<��kя_���Ա�	����C��ʳ��Q��7:�;r XF�Q�/Y��ni����I�Ǌ�t�a���p�X�=���ojq�urA���_ �]ح�&c���V�ӱb��"=��疶`�J����$�BJh<�4M���i(���.d@ <����zpz��>4*?q�����W&k�9Ȼ�qj]\u<����^� 3�R���:���G����<�]�h�el��3"d�����rP������ٚ Z��>��( ���_�bv��sK��/�M��.���R�oL̴�%����/�`P�p4���W����4M����$C!6�Y��;�����cV����'(��΀f�h�rugUd���:�(}�rΰw|�F.�y�=�@h�-�K��(��Q�ʖ�(�а�ŕ�v��˩��X�3�w\�ܐ�T�ľ-�*lJc��7ߞ���@>{�/���^
�p�ӹ��nFJ~JJ��+��D��#(ɑ:���G���'�2�T\�tR�$�<��,��|����B�����]!����H����*1�0�ZJ`���{�T,�?�FuKx���c����-��ա�Px�X�Bs�Ϊ�۶�@/꒎}�s�����#���&�$�>��8K]���P�������ϯ�D�`{b���)���V��˽��Ɯ��$��;���uSeZ�a��꒾��v~���$��#UFÈY�+���l�3om�1��������}y�qƙmVNg�sҹL�������uY�m�o}ZYn� �O�D(��r(���}}	��u�q�i����!�*0�[�%���5��!�f�x�@:�X���k�-G.X���hH��#��`�����KA<0� �}%�$����,��3M=~hx���f%�5Gt�㘥�z��s��nZ��;�MrL��K���,���"�zcIS�Ȋ�`�K�9x$�V*[ϱ��&m��!���[���&�"gWd_�M�B�h@kJ���}���5jh��6��gQ|ə�;-[X�(���O 6�7E�]�ܣ�&{����	�@o���s��ZV�����ߠ,E1�j$W����ŧ����:d���C4�w5/�h,��^�<�ϮJ�/�m¥&l��z"�\;Ebt�'������9����n��9��E�m����m����i	Q/u�o��*ռ�8݊��wI�:�4�~�W�%�
���w�^Q�k�����Ä8>��^E�K�V��l�*���Q72ʤ!�����)��=�G�ݕ��<��7S!���;�" �lN[�z��ε���]h:P���}���vr3I��+��~;w� Ŵa�'����lU��=h7�h:����:�F@a���ʷq��aL��W`��a��[����γ���I8�Oz���`a�I�O�碨��m�AF5f�_2pW^��"$++��x���%���"D�y�+o�TN"���9	�Q�L����G��>�������$9e������F�2x��/«[)^�Ok2�kU�%��k_Ŧ [��:}�����Tb���̧��a�d���m���˼�}$g�gYb��_麜��oC���W�Gׅ���̰��|�A���J�'���������Jf� ��0�!��幈y\;$�dϠ��%�V�Z��X���%`>�$����Ti_��L1�H�p>��t'z�=��w9���::�G���xV��2�̈́A�h j{XA�e��B��~ABC<���R\�hf��@�ul6A>?>��;#�`? ��h]o���Gh4�4���!���	7�;��c���P���T`Y�4T���+D�D��( �3><CX�ƈ���v�:�s�q`� �7	�x�,N���ύ��ܱ+O�9�~�q�eQ9 �F�N�������L��S��N)�r��m��X���t��[u'O���e�S��_<C�x��L@����B.�oZO�+ /�=��ȃBo`��,���K{���z.]�hl��%���g��PQH��5��ږd^�D�
�M�'e_��&uZ�yY�p��*�$%��5ȰM+��(�nN�,�#h��X��|��P-�����S>7�u)���pmylF�d<��o��o�ê�2Ü�ꥋ��0*h�"6���+��?J�QD~����e�M�7�bܔ����';�F�yb�1AG�t����ǌ���#qP���śs����x��-���ϭ#��C]v�ZՔ��/uB��Z<���)X�R����;9�>2��1��X���w��t�m��@��~��`1el���f��-	�Ψ��pS�ا��^�$Q(H�+��%%�(t�i���;�L&x�MZ�*�4�y���j��̵��1��>n������r0�]5�lR���`(H���]�����{�ϋGw�����=�<7���h�K=��Aྌ{�h�9���=Mp؈ �n9&��m�xhQLM�"m�����?`2n?��:�$v��+8�ʜ-G���2���!�L BKaN�Y&��"���(��I�h�c�u.>�������\R��1�� �S8���#Ȕ?�/��t�]�z���Yi8���2lŞ���rFd��@� `{u���⟋��XdU�!%r���_��e �ё��\%@h5�^*­p��a�������'�z�? �NMuJ��iA�}�5Te��a�@�~��i����j��k��S�"b��[$����;���ID�2�a�������  �y��T�uQRf�������!��ј��]L#ٹb���}�{G�,_"�G5�al�(�~�$���:�,i�*�v&�2��ݤ�^���[ ��}�.N;~�]4͙��7ֱ�Wo�� i�� ���^x۳^��O�:����������rq;��n͌�[e����Ж�5�)'2I���]��uz�Ġf-B1C>ب ��`��r�y���'�|O�JY&2P���1��R�P��R�\���w{W�Ϟ��8�]�{+�V(���a�;6���cG@S�sIOG,��.���ߌ�祖�U�gD���tL�ڴm�,w���3ez�aF5�e��J�$�s����g����}��NpR7tW�Ӭ0������lo+��ϡ	����:^b!�3�C���#��R�Ar��B�J��
u����{��6qn"��ő��!O��ș���o�E�!�V\�6=��馓jF����c�#�WRڐ�* �'�Q��9���S�s�a�y1;��*�qJ'���M�����8*݂,������*�!c�G��kҌ�4Y�E	���Y;�eJj�K�qh6M{�*��mt�6�u�1&�/��g7V���"E�?�:(2���G\�g@�����R�8���3f�A�뎇#nc���7ꦧ��x^�!�e��peJ�� ��8,��t(!~)�����	�ڮ��:+�Fc!Wp�M������x��],�s�%�U�?��Y���t8�j6pULd��1{�ZK�����ך8m+8v���F`Bt����|џ�kkAl�딲x��G������!72�
fS�ك�˕n��'�(BG��_�*�ą���*{GѴ���C�pv������ܰ��wQ�S�; aq�����}D����$�2��g�Eˊ�B=!Dq���.gY�o��|(���'�̯���;���x3|n���������ǀ��h�vǀ? k�ǶCL(�a�1[�[jEE�z����Q��f��y��2��sN��^�����xM]����Ô��Oa��Sछ����w�bUm�w8���c���3
�[�5t�Yd�N�2k�/Β�ji
���n��✁L�7G����CL5���|�i>]�[R?��r����n�ߗ��U}�8kƪ������O� \��BE�y��E<a��b��/�0|�3��<>^������t���KAA�_ڵA㴓�}v�k��HnQP��(I����}\�W�73�l|i�L�@��	~����� v�;9\���G�Ƌ~��}���Q�pR�`_��!q��	�r���g��#��O@eJ�5z�ǽ��i�jƽ#��f�K���OŶ&-���v�z����D����ei�%�/x�fcO�ْ������<Vv��vz��ۊy�a���)�
�A�T�ټ�^zo>��Δ���Y\��ܒ�w��*NmÄ�����Pg!��Xq)_�F�4�tmR��d�Xx��4k�gtg0���������������C��p��im��Ndi{��6����COh� ����=g�(m<s��3����#�,�:R��{&ZE��Єa�V�q������"�%A����GD�tP}�1�#�%��v%���U��
��!��|��`���,��JC"^�
Ɗ�nӞ��)��tk�o��VR��UL ��mO��=�z��q��_��N�k��itYcE���].Q�i����5��I�+�h��ua@ꐟ	�Ph�ҏ�0X�!l�	W$Ex5Ռ ��)���)�a��ƛs�pw��*b\��D-�}/�OwШ�	��)�]ľq��[Q�}�l���{
��`G4s3�钜��QPEn�ti�� `���i��+f��":/t=8���]�>尴�"H����u�)��~sq[����u��=(˹6�W���0���]� �>lb�Iu��t�9����jmqM	\�u�?��wc���`���U3�}"f������'Y�i�
�s�nS��Z��d�Ʌ���H[�q��آ�R�X��N�Kh.��9��2�@X�1Kj���V�h�5���=���]��� 	�{����ݥb�B�C���p펎_6�T�	��>m�ȧ��:�<l�2�԰l��:@�3���8��QG��n�|Y)_p���"`��3Zq?��!׉������j�����7�m�������<��lb�����n�KL����k.���7�#��s�]`�;̈́� $��w�4'�6E�P��D����[�����N\�(�W���%����-�bO��
s��_�X�A��S�Js�����QI�`�5V��;�ͷZ7]X��D5S�.��"\,�L/�n��d$%.�����`B�� �P���l�71T�M��A�9���$JH�e��i������Vs:�~UX-�@դ�i���}�V��I�'�[p�D�?w|�!MԘ�3 i+���+o�Q�t>nƾ{�j�3b(��D�j7�>� d�s|ߣFf�P+�Qs� נ�d|�-7�TŃ�|�r���-�
��y?����iH�q�~��e�,;�5v��~��Z/;95�զ�������#d"��B4����m��ÏOM��,���,9�&j��Վ�~_Q��c<��IHUM����F�q�>���&������ߢ*�r����{_�]��4nȿW0���6���{�{Gt'���Qu@B�,��hx@�n��x_t���Xڒ'�#D.�j�5o�����wI��-��q$c�y<�t)��������y���^[�sm������� ,�EΑ�}(��w�lK1\b�w�
P4�6��_VȴG92��4�[��@-O��ڬ�X (�I_�ے��bE���NԆ�s!���+[⾧JRW��B@\G��W8r�^�?���r��;|]K8�Xv�	�"/@s�c�ᕿ�Et���x�]}�����<E�y�����y2��g|TeЖ�-��C
R=�E};^�x�򮣿���T�=	�K��/_K�b.�#��R�=t2Nv����������/�4��*��vgɤ�������#�~�q�>v��A$�1q�8zr��A�9�EB��Jw���+��.5��-u^����(U�mq?��/]��7��b��	�l��=[�E�C��Qa����?f�!9� K}v��o����rG�Lܕ��a��F,7�8�.0��K���oް��&�u�:`=־I~�o{�e�.��-H��ā�0�\U_%���aokI|�nd�l<�E7���1�S�0Y
w~��Gt�2�F��oN�.sO����c(�A��H]���b�Fm
�]� 0�R�B�^<�A\�rA'.�Qo-A�8� 1�&n�j�z5ZZK���VC*���K�{i���gAʐ)\�y�&��q��J=������Fv�b^���5��U�n{ˢ�\�S"?�X?��6�i�4a��(�%�S���zS�.��l&L~fR؉$�9����IhL
�w�W'8�XSo�3u�:O����������W܉�-��u�*���)(_��2]\J�S�����=��=Y;���zx6F�,vi�����	7O��\:��(]�v��傤WO��?�<O逞)�pA[�R%���yWKoi+>���JA	�Ӡ��L1�d)�.7�3��b����`H"��Aja.&s��NIh�!�_���󶤼�^t�T83�$�+1 ��[�q��1��4�
�W�}�eƗ$1h�	H�-5�W�kK�VSg�<���IP�t��վ�K)J�ew�1���z,��}j���]g��w��hy�cyY�U��V[�W�D� ��HP��F��:�7��e�Obn�{w�YC��s'xc�5�	��ݸ���O�)�_����W��q�fXٛ�D��R��ل<� �%����N����񫹭l�?��A8��y:7(Oq#_�P� b��Le�2j�Jl4$�e���ԁ�r"�+|t܇�Q�5��n�� ��쵷�H{}c�k�L�8�u~f��z�������e��JB3��X�w��������_��e ]�v�+�1:ڴ-�?�F��w��n�,S:*L�.���l��yƷ�H�!p��S?�f}�\��f�(�M��y(���G	T��$",h��vE�[�7�vy��5��^�-}/ c)B.3�ǈ.;!�ܫ`�/r���(զ�x��yBb�,�A9K��Q#q�Į�1�/-��hģrmQ�U���lT�k���LW4�9�>�w�~�y�[�O&6P�3���E�k��yӂ+��v�]��������CM�4<�RZ�8��\����m.��yz{i��IuN����f\Qz�\����I��K:il��˒X� ,-Bޞ<�'��A�t=FB,CD䢟�;�~��1�q�!�>�W����P��3dtƉ�x��*�v߷���I��:Ԓ�!��jl��%�]�Ey>h�L���DDВ�o������T��q�Jmtd�yu �CP#���(ܶ��E7�[��r����c��4��B���v�6ź���:T�B�jnve9DJ*�cB��1���X���5��]�|����"IQ�&,�
e}�>E���J�8��9\������+ֽz�(A'���5
�]��#K~r �4��̆Jr@���sʠ�R�3�w!�I���c�tݜ�� <����zo���}k�8PS�}��F�v�1�S��[��g���O9����.��p"�?�N����0�SgK6��"��#�����h�3�)�����(6ɞ��|�%/"nc��O˲�!�d�It�m��'?5˗�|�*;;�����[D�����p?��rR��|�/��!0G�w�\�Ƴ5d��(�� ��wv������y��ꄁ�;c��IWWA��Z�� 	�&�@$�V�~%:�{���_�E���ݛO��XӋ��d�(��r���i�'Z�;�,�z|�f��)���()lل�OS�������A�9�-�n�Q���]f��(��z]����Q�Wӭ��<��}c�G�š`��.1Jjڙ5�B����:�!u�0֓���:���_ʞ���1o��[*l}#0k0���s�tr�2��a.��yc�j�;�˥ Y�Չ���cv4�՞�,[ *�_��%�������&(h�q<T�"��oȮ fm�}��ˍ/�:_z����TP��B����z�~���]a���z���W�^Ȑ�v�뭓WZ?�Gs{:G�"���{�/
��&C<���pr#��rna�����g��aĳm��+2%��*1��,�e�W�L����!�C�-����`�͡R�2͜>yNI(�i�9�VP�	��%���-�S�;
�?0ZFj�5�M��N�H� x>��>���h���BE�k��B��9�zC6"�����r�pl�hզ�f5ӄL8�S��(!�Wezx�*��4��|w�$*c(�l
�R<Aj�Ä�z���ft��t�+6�`��΃0�d0SP��H���0fE��;S]��WTE�(�B%�`�,i��ޅ���jŪ#b=�s��+R��|^ʳ���T�K��Խd�y��6ĉ�I��%�3�ui�,5E�7��/Xx�{��B��������,�fb����
�W����ޖxҮ���$l��4*��f
�Ƣ�Z�*�'����YlJX�QB}C���X�/Y�y��º0	N���_n1�!������f7���mKt'`�y��C��f�7j}��xe:Ӄ�ڞ{ �����H5�F����L%C�@3l��!�%d�F���i�\^xޠ��ܑv���B��k���c�Ɍdc#�0�S�0$����"כ�`�(J(Gpi�1}��T@��H��Ak�i����8ʿ*�VT��q�`/)�� �\fM��Z���4a�7�.����3Q�l�6"v����t����̓MQ8)3$�(�]3VWOk�H�M}a���}"T�*����0$\L��X!�s_�����ipܩ�HCE���5�܇P/
�޼$���ܽz�F+��O�#�9v/H�$ad�W�rU_��1�~W�`Lc�!^`jߨ��h��2.{��ӹ����A� JFSi��ȼ
�@�N��])pt���$pZp��ۖNLh���e/E�2)�E�	�5��ֽ���&(ϭ���g��@+wNX�4O�$�J ���j�f'�3[����U�p��
$�C��d�}��sIz�ОB�ð5�v�����Ҍ�������WT��{^wqR������{Sk�xh-I���H���on�vYS|���f��i�/�N�d��%�Ƭ+ӟ������4�P�7�2	B��PZH�K1_�5!���v��ݐg�
��XkNu��B���8���6�Qh����q�i���k��Y��zͦ��i,B�?��d��U�����#v�!�Xm��E�y��O`�t���K,�с~1�,��Ll ���HE�+�p�zW� 9���:�}���y��7�6㽎�
#��������e1�j��&IE���.C��xj���_U�_�̥���k�&*�v����>�h&J���1
����n��?��?�$�3��|��O	:hl�օ�b��v�����K��?�(�C��
�Y�
����_L�6?|E�R�gd@mAOA|���9~P�q���4J�U����%�m!�n�-�4ԡ��s~��{�R��8��'�wV 8��ne�� ��Y|ڛ�:G\ce��^�d�Xn�p��&�cv�:�}��;��*�&kN�&�&>�d�' �̀� @�r?���Q.Do���i��4�S��Q�nju�Ū0��۵n�/y��лt���h��ȤB�t��%���~M�P+���w;oN+]D��+ޙ���Sf-E��M=S�Nq�׺\;w*��o���s	>˶ 0��l�����3P$_!L��ݕ��Ѷ-p=���z@���rq���q�P�ef��PW���q]�J�V+d�CS�d��n\C�+-~�ϸ��<�a"�~����	Ů*<g��H��G����D����e<�v�� .�uR噟���lz`UJ,H�a1��9�Ek�@/��%ro8�jg6�R\�Gj��g��@���(����g�&ȳt���k��2���G�+h�A���"�����ؓ�*y�c%����-�7,�Sɛ�1��G���k�6�ζ�WQ*��|�j6â����ѧt�ů���)�w�3���.�^t<�����}�)����T~�	&�rק-���o�;Qr��41��Z�{6�/~�mz 2�P4U��U��w�g�JׇU�݂:˔�r�^ɪ��ܝ"'1�œXq\g-�Ģ�D8���B9$����[J�'�TĽ�HOE&���|�)U�Sa~����'R�w���-������:� @9a�ٱ�;��9�w�B�ҥ�p�`%�Ѭ��v4��9z��c�Y>�t`:��mc%@�E���Z&���A�qPa���/��O�|XO�Љ�6��:�ȱ�j�D��Ȩ|��W�D�u\`u�dv�S��0�s6�����gA���=�l)کgDWa+��]]Leh��)o�ݤ�KO�&�AhP8�)�3��|qN����c�Q�O�   �߇Gd��2 ����n��
��g�    YZ