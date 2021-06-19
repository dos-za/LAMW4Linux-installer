#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2166914595"
MD5="98d837a59afb95032716bbee7396892d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22852"
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
	echo Date of packaging: Sat Jun 19 18:21:32 -03 2021
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
�7zXZ  �ִF !   �X���Y] �}��1Dd]����P�t�D�r��p�.��ߌZ���&�*
~��?��_�i&��4�4�o�}	�s�J]����,W��u��Y��T_63��e��u�L>����>�hO0:�9^I��0�)�ه�P���a\�H�yF����'�`Z�gY?��N	��Bd�ǯ��0����Vb1hnP�J�\�54������Xk��%':�+�5�u�ÛI?WB���()?r�	̆�A&�J�c�O�)8�"Bu�G��s4[*��gz w�̳�H� t���pNt7
�޴9\���R������˺�`x$�,�t��ge]i%�pL)ZߪIȹb�G�z�e��K�G�+���b��<�)?�ఔ���Qae��]LZ��OM�����V���-G��`�!�!���(�4�m�2��|�����B�uSP5�)�q(�<L�.�Ҵ��dVLI�O��[�]H�7� У��Gvh��\\b�#����'�Ǎp����!2�����6 ���9�&r�$�aW�՟����4�ɤ�&Cߝۚeuj�7�l�_8�ǿ7���^j3J��kR�	#���}���(p���ڴ*��q���dպ�#+T�Kܘ�(�����ᢶd���%�0�Q��<��I(�}J�=�S��(��G�OT�����u����i%�g��`1���dr��g������!$���N�3���+�4B�b�r� ���-�����t�,���ꋡ޷i+/3?��G�S�ag�X���Nű��K���nk��G�+vy7�����b;��J�lQ��Jp���i�|���ݢ�̢5��:�A��߽U�:x������ɫ���.M��_o�a�@���\h�D�1�RＡ�K=t�� c��Q�����p��1�n�@~s�����3�#J��+��uZ�&9�,ϣ@b]���Jp	�9R�ظ��U�`(tF
�=m���� I�&�%G�2N0c�xT�'Y�eEjc��z<�	��+���)�W'(]p���TkT}�i�a�ط�O+/R�X�f��|��UTɟGk~���#��-Ҁ�7�`�V��q�k�o�
 ��7���~)�4h ���ܨ������k6���d��4�;2;��!�7O�10rGDHӫG��K
R9�g_�a��o�}n⸞�������(�Jq=ԕ� �ʾj�!L+���Qj���feX�l��MF9���x�V�n��\���=�?C^�:�l��s��wd�nad���
�&���S}���]~<�螂�$ÖVN�G�6W[������T��W�]�
���^L�g���}��j��h�i�������̗�!�6?��O�Լ8z�wK�ڀ1�����6� ��ͮxL���bH��Ulp�dE�/���}�u��kc�I\�*ɿ,���,�'��*�f�0>��W;���"����7�����f��Ym��oP #�Zl�ǡ�1;uy<=>\�p�)4�L�b/��K�kw'f�XW_i��.�I��w��>�BǃP�lYS̲���$dB�+��&�*V�~7��)���$�ms��L�!�&�\����9b��ي}������G���CA1��[|u�p�T���?q�8�%� OC��pxD��o�*��=�(��N8�j�]/ADo	���$-���:Y	d�{`�S���Ӥ��§;��n�_;P9��p���i��4|��R�d��td9��1S�����Y�NxF�$�`�U�Og]������X�����:e��QcԢy�3�Had��L�
פ���_�t[�����f��m���"Y���I	N�q�m&H�Dw�{��'���Q���Pl@�q
��!e}��c1�c$�EF��|�E^M���*Bf�f�Jٌ�S!����_Ca`�Z)C�Z����}�-#�ei�2��Qc���X���q�����=����w�6 Ź$!�T�2�*3bH�ę����Q�LT)N���l��5��uD�Y��J��.���F���u��Z7�� ��尚xsj���,��n�,���	(�@)���$�����b�r�����$琋����-���Ś\���S�E���¥ɜa�o�e�~w��fLG�B���_h�O�J��Vp+
L�4�RA��C�eB��n� ��oR�����J��P%�޺�>#�B9�rȳ��mq*{�����ơB%�I�V@��AI���f��� ��j[���r2�` l�N5�ZE��Fb	�<���P�|�P��B-o����δU&'�f/��o�\�4m�e�ܫᠹ�8��U���l�S�I��J̦�3��ub�]��kMIr�#>#�".��� �
۴��M�WI��@�jT!1J�ڈZ��`��	��P�"{��Ahi�=�M���?X\��n����i�d�"�1Y3U�C�M�w�>�~�s��4eӧH5w��ˆjM�.��g���$�n���5n͇���"w[����ZA]i�&疐Gݜ�"��;��"��%��#��5�E����r��͘���T[���,yp���ps0��_��&T��[3ce��_P�
t�7�S_���P(�)-�㦿 �n�W���ȝ{������������5����PF_${�"����,�R�H%v��y��a�#{��J��W��	�y�%A�=PW�(�^�\d��H�5��DF���`��$e�r8�6:(w�z���D�pz�!9��\�̇�+!�/�_��	���޶;L�ea�^t�Gf��\����������ax��eY���M��p����i����Ƥa�i���h��
 iRQ<�ˌ�%#���^�V�k�_u��q6ro���DI��4��&%A�.���Y>�Q��բfO�,E�?�����3�c�|+^+	hs-9�l:}E�YQ��_R��	��n�}�O�W�0[MFz�sMC��0騥2,�ek�����aH��.���+3N�E��s�:�K���
�Ht�x�4��p_���9[�|���9��mw�S H�=�ښ�ߣL&Ry`˃���[jB���Z>_�����C���O؄�I�'N�{���7�C=>��0�n�����?	��[b��7-rX�B�`26=<�~��*>İ´[�ꟙ���<�:^pC�ۺ�8��p<2��|�����L���wU�祫���߬�薦o��<�H<븵���P7v��c����y�_�aZy�fs:�jbҎ������-\���z-���5���J7�W��ް��;�A�]ח+�F*a�۠�%�I㾷��8�3g�������+4YkP����z�7@�ed����0�d�T^��ҥ�4�����Xk�P�7�p��D{�9~�P�L����%�) !����B��5�F�R|u��N���Fs�p�2���]Z|�Zb*=%��D�PGڂ2$SA�[����?I�^�m�����P�ӯy+:6]�Õ�L��틯s��F;��>B>)����pE�N?n $JP���X2�k�|��Ql�XED�߇�e�X�q�h��1U����4MdL̈́I"e۸�p^�겺�l�y�u�!�K2nt�M�U	y��HIl�l��H�a�N8���{Z���ҩ."ĸ�;�UD��޾�{��?�B��'H��N�+V<�����n�%��d�.:����ڢ�%�k?fNr��4>����#/��MD�7�&o�}bsb0�>o1�gq�oҙ��b��"i��T�M(`e��w�{ ��$ߨV�N����]i���/W��^5��~C�F:���W�"[�q�WXxԟ�誋ӹ�ww��\K	��������R�f5@F/$4�n��`���u�Q>dT�/�|���$��72��������� ��w.�V����k����2���� ����i��.�����aP&��z���pC	�(��6����|���8�1��s��9�bgr����㒺*�F���<h㎏u\]׬Rޔ^k_��hB�!g_S��V�HQ
8� �xi�7~z���aү=�cT(�29"��=���n���~���ό�k���.,��!�j3�Ř)l)���x����,��]v�d�UC6��?�����e��~g�ˮ��y���^�f��T�"�qd�W�C	�k�;N�M�2DK����Wa�d4��h	���3�c�k��]�Ξ�k���L�5�8��9W%����N�ɬ��\�٭N�%��M�^�\6���<�a�y��������MM�Y�Ĵ��T���y�����h�њ���3ǎ�]��H��������
8�ۅ�@q���	�����c�Ň��D%��}�Bf�G�)N�*���T��df~wDYZ@º��ї���Qs�X��q'[?��f��ZIs��*�6�P�h�}�*٭e�!�'w�_��J �ȱN;j�SE��Ai��G/^5�Xr�}�"����܀w�fb0<��%��h�{�����g���׍cZ�S��MT�vQ�ysWM>��aQ?�.���u\8��YA0p�pe�2�O�)>���:���ը��F���BX#5��uIEz���%��<�R����PBpYO2NB���z�(�d�Į����Ћ��"�~�8TZh�B#�T�L�M�c��~Z��������]1�6$t �@p�?���Xx�#twi��W�
�� ��-�҆@N�~M�'�e��R��4L�W��l����hY�P�V4�<��7f�rv�����U7�C�4M�nې0'�5�Q��1S����ٸ�X�e4E�C�`��ֱȚ�V����I�ݻ��Ү^u��A]|nc*ޑp��n������a�S����_�Ưu�;�r[���[�%��bt�W��N��}�Z�\I�F�[oT�m�#��6 �>.1�L=���]��ߧҜ����c؇93��X����u���T⮓KWK���δ5��R=��el�|̀�}Ʊ�i�Űz�a�}��� .���W�#���}5��h��'R�m��Z��f�r+�ɤ���Vb	W�t28�L��_���u>/=g�9T�N����SV����Z���;Ǧ^m���Z��r���ǠQ]FK���ϰ��9w;�@L��D�b�䖐��h#/i�ͭS�`�?����Y�͹ae.��IC�"ke3E��|�
d�N�_�WU����^���H�z�d���>G��ݏ$x�bO�D����ae�'���em�H�n�n�Ul�N�	(���E<N۳�=�K��*1���Ӽ�u����~ۑ�F<�I��L��E^������G���Q,X!#�2 �{�3�!'3�S�������<�8B���3�,{BL��I�3�& �$#� GYl ����48��J�����^�u�����A�;K��5����G&fV�>;.'y�=�7TO1�`V�qc3���m��T�4KH(
O�\�I/�:����?��($�JoI]��2��!1`Oğ������N�ݭO���dV_>IH��d�S�r�S�+�^�L�$H����m~�+Q��}��F�G��~�ׯѧa<��;�C^���<��h�KF�il�G#�|��K''P<��͕��T}�z���'���.3���H�>�e���Q�j)q��';�����r�lx�!�VYu�t����[EW����~�����sj�rrU^��2��H����	,P�#ZmFi�1�C`���\IQ�a{72kP�B1"C�D�&��l�����Wm{�Z{���*Za�j�
��1!���Ad��x�2#P�z�[����ʻ�[d0
+:���se�ߟ��zq�8����_�e��4�����f�V�b���3L0*g�s^u�V�뛉�Dv�v(-Ҕ��e�ߊ��L���n5 "8�� ���a�>��R�'�N���¶Tő�d\�,H�x!i�6�!������'���%;Ԧ�*O�T��@��\�N�yQ:����P��mQR�������1H�����4�,a�:B K:O6?�˟���5��Ò ��_f�*�E��ִ�R��"�)�6kXG�0�(j�.���u�& Z�aNw��2Y,�D�}�,���n�
崙��"{&�NG�5<a̥q�iG��%��'m�����<`�����+MY�J���U�:qCj�	����/.5 ��	�X��2��2��`��Q�N4� ���şa���q;e	p�����'�`��L���[A����:�LD(�W���QA6B��:O`@ �Vn�h#������ޤ�(���(�v�oN�����yg��]JbRpz��J��@$C=T_?RT6�;��2��ɮ�Z�0�aa�7�\��QP��V>�g� �Tm 
�u��a�����.f�Ȏ���2��!L�zv2��375�ydb4d��Kmp�*����g��,�^(}/�)_5��3�1B_ -jߣA�E�d�![�{P�+�f�K��[�0m�,�>�[oDYk[��Ba����e4Ī�n@�f =\��Ll���_iq�C^�K,D"H��+^(S'y>��'��c'a������6�{>�5t��,kp]�A���d)���?2���#\�_�h�%�"�w3mE5��XT9�8�WkP��#�q��� �Z��_��W��?�}�Nv�ǋt�
IB���܊�dT�lt�H0�"�U_G�ͽL��$�g���oW�I�Rz����=w�$90u�d�s79����^��6m��Q?���R���f0��m��#�z|'�B>C��������ʨ�_=w���~mC/ ����JHk^�ľ�"h������S~~���V侅�9C��"�u�G�ԇ����~`�ʄ/��>j8L�G�?�b\!""�6�1�W� 7`gl��A��� ��j��h��,^�o�����Y�?��=P�}Ro9�b�I^A�w�(����
 �ŝ���4����q��*`�5_�}#�֌x��@:j�a~6i����*#4Y:�o�لˆ	�3�����8����B���(�B�g#�A฻ۿL|��Opϼ��FL�r��AD��"~÷c�bOcؕ|QH����D{IB���Lv6+n�i Gы]ta;G	�7�l7=�}��0��9���pMԉ:��b��?$W|�Sm&	��3P����eh�{�w��X���Mׇ�7�v��8()=-����f��\'���
'��2�{�nC��Z1��ӀY��r^�+�����O|�\ mH:�x0!E֯��Q��˞c9�̌p.�Y����h�6|'���=ב���u�eU���M8f��8�K��~���|��bl�j����B:��hn��Wb��,au�J�^�ˁ�Coc���R7�j����B�O^�L��~�0H��pd�ѫw��{&N-k�ǥfhю�=;Y�$�+v'J.�	���?��x^��{-MPuvO]���o�&1M�M����_w�@�Sz�������p���������JH���'C��î�`؄��boo.U���ʘc�Fm�U=�,;l6�l"6��5��B��|v*E�4$אA/Um
 �1�}^�\�����َ$��M�U�8�L�)��/6-(��*�C1)$�cY>G����ۈ�P��Ci� Lɱ�kLJՐ������P�Kp�����^c��WJ�`��m�45��z��s����7���f@/�� �{��<~��;����չ�b��E��C�uA(�O�4��a���ě�HJɆq�,��ί�s�C�1?{�Y"�[�"�,�E�(jp��B�F�Bp��?�Y<u�T���r�M��u!w�m��ϓ?8\��LoN�GR�J�V�j%���ƨ#����ܩ�-��t�Θ`)i�2i�1V���I@�=�"VDdoBc�Q�x�T� w-z��95���b�<���t�Kܐ�'�#��;_��%Qz�*YU��Fy����o�/k�����F�*&�ө(�	�*����s���UF$���;@;QE}���,��&v�7�և��dᣉ�ݧ�G��&�t��*����)`һ�h��W���\zn���������7������	r����?�qJ�F��dJ��f�3�~�do%U���D������E�O�{k��(����o@�+Y:_��bXR>�Tf�?@�Q{�05��h9�5�;���azWb��'������"8m~��ù:@=�,R��� 	L�S��$�Q1}(�� ('��Ɣ&�����H4��E�O�h��0�e�-��˧��I����ζ��8�[��8D-���'�����UY�&�'�%��pA�c6"կ�C�lF��.��(M=� ����CR�pH��/vuf�_:Tl����]G�w�R����\;��J�,����"<���ʀ��nˡB`OD�Eu���䀜$V�:�t^���q΁ґlJ��R7ş��"Q�ǎ��m+Ϟ�A�	n`�L66�'�[�I8B$G�N���	���$Mۖ(���]ˬ@~�! ���?�/��#!�&��"�����*�����n/������@��˙eK�g�m�2�Wwy�ժB����M�W�1q��r�C�X'�n\,���#��GD'����Z�ݧQb�=���Ni �~ܴJ��,�1�wt�T
�$�B-�قVc_ۑ�Kt?s���K"_���l\��Q��ᗧ��A��t)7�C4]����Uՠ'�F�?���O7�]*B�Eͷ���=��L�I�$��D0"i1�`-Z3���o���w�2
����˛��he��<R�颕8¸�k���vz�����߈1�b�j&�V\�$�e���A��%�S��?�������>���M�K�0�~l�M5�G�U�����R�	�s�{~�O�[��Sg,�a\c��̟����~S�V=r�D#G���^��ۦ cdf�m4��*�G�?h�B���1�V+ǀ�v1Q��t	|ķ�W-�x]6�vQt��F���$���q�S���;b�$�@��\�'z&������L>A��&�G����b���Tn�ݭ�7:s�(q����� �(pp�m��M3	R����Y��.��w���7�E_e���Ǖ>N{/[�6��쪣ü��QA�P�0��y t�}��3�D�8�J9�)*�t�n��h ߁��:'[�E��fV�0#Jܱ�U��?��y9h��!:|�9F�M67k�$>�|B!���kȄ4 ?��R#�H�4 3�ߢ�Z!7���>A��<�x�����؃��T�fY~���m�x:�Y&3�$��M��;�����ۭ�v�:U��� Л��'N���N�-v�]�ms��kh'z>�m�������#d^�ǌ��,����w#:��n�0|ǎD��51�1��5���m��&��X�VM�wC��#�2"�N�a
���V�ӷ���L�H��tUZ��>�-��������'O��gu�	�s�,��=�H�d��`���	]g��1r��mטp��Y�.��F>=�p�>ow��Pd�;��H�v�kU!��]�Z)����X�/<a��^��k�$�%]�rpa����Or,@�K�V#���B9�+� �2�<A�G�A�ָ��3�|��N�!ݠ�>?�#�.J���i���0�ps�u���b�M�t�`� ��L��Ţ�т-��б53�UΊb6�%',��X5���$��:p�>t�T��0R��֖_w�� ��Pm`6��,�O��%6=li"Q�� 6@�]��޳Y���� �QE@��1�i��~.����QXW���S�B�	"�)�V+�[V)�J���7\�ʞ廡&�8YR2����	��k��(�
_�\���*�tʺ�7��x|�UI�vQ��{e*��44�� O`�3�aJ4c8`>^1���iY��h#�h��}�I��?��C�Qҥ�.��	͘w�	}Ï��燿����=��p'*�w)k�;�gsq0���#[���z8��L���]��Q%.�߳�(3�w���?����� z�v�zr�H�����u�k���!g��u�=�:�QҮ�	���9�:�&"}AU���a�����&_F�yX�G="�TI�j�lǑ��?�j�3�+
�����ho^�G�cz���ʆM�ZZ)�;&��i|�l�f`
�/�s6{�}����}��$ڼ51�>O��lG�@<m�np����v���C����N���i	xυ�FIt��]F�F%��٨[�E�����x��?84�h�/�|W�[t�q�b���Qߙ���D`�q"X�������Ì'�BG���S{�Ec�D��⧞��j�W���8�^�����z���҇�v٦ϦM���stu�U�̹��}�l�Vl�$oY�;��}���|Ȏ�\�~�s�P��z�607k�;DR��{I0��1�J�5����֝�Q�ӫ�u�Y+�������l
�M�\�a�H��g�`ҩ?�#+���[s>.i��.֊��7�,�j$\��嘀��:	���ث�x���*N��ǆ�(����C�K����.0�����E���)���@�'9L����:�L(w��1a*��A��H�m)�	r<�o�'°��i��Sь�3��L�'�u���;�r٦G������5m��w*?�$��Z9������p<�x��n-}B
���T��;�|�����%8 W�S�� �
8DV���0�G�)��
%�acR9&�\{H�B�k��c�4�a�BZ�˵{3#������Ԃ+?i���V���S��\���5Ӭp�7m�t�c?�Z�?=aFg�ݡwAT�l%_Ԩ<�&���O��d&��[�r���Ɲ��Y9�Y���W;���dwO�2�.���V��{�.t�����z:���N���]��E��������E�>���T����Tj^�dK�{C��g�/uD�1ڳ��X����HW�!ڷG�遃��i�9�)��Wnp��^��
�H>���by�]E5 8e���{��f1,,P-wM�xLb�:ֽ�:[)ĈfS���&�����������R�=9ݛ�7�����ֆ<���(�����zҸ��e������@4?���?�y�u+�ĝ����K�a�G=�p�l� l�g���b%��[��Ì�N6)�F�t��1����ۂK�)�eM���?�;�Q�.�6+�p�S�� ����%�>�����!5�#t	ͿK��c����&�.,��/$v6I�H��\�Uϲ)�_{�(��I�����'�<ǃY4H'�ݎ*o�
BE��aELy6 �f�R`�XHD-���ie��3՚4-����{X��UNPk�Ў�n3�=8PL	@N�ԭ�S�,�SCтN�+ �Ҝz%s��Iȝl��
W�lT5��D�5�jS���i&����O��M�n�wߣ�Ԋ�	����X�9���w�����@0V����\��&s iƮ��DV��<y�s�c�GҦ�ʏp}-��]#�r��o4�49��~�ƴ,:���O�o�;b�R����c�z�A�11�86���-�zZ�_�^P��JAQ�YV#�FM�����ִH6I���@�ug�9�5v��	��Y.�L~^@����Ob�|�/a�d'y&����"��2�%VA� ����Ů]¤e�̩���X��ߵrJ��b�Sgb;��� c���i;��l�3\�;�"T�V`#X�S(�;H����'J��`7�W�&J0I� m!vH�3��O�~mn$OT
j��1:U{�ˤ˷� ӄֶy
�%�D��ݏ?�fn�}��Y���7�7�3acn������\���=�*��&A�ʭ�je�Bf��L����Ub�Y�5���z��h-
�PmtU�����3�'$ׄ�2I�@�0�R�=��^��c2���~_�Ս�F!�%�N�?k�4��,�$�8��CZ*��Ԛ1��gݛ0�Q1m����Ǐ���Q���݌Id=��(
vp������Z�9���Q7�,�9�Y,���� R�7$��-��q
��B?�VA\	��;�7�i����p,��2��y��:��E�o��b�!���ȇ����fL�W4�gCq�k���[��y��Y���`�~�u:��-8���h�+Ey��Kg��V"�Ϙ�KǕn�Q��Pw�I=#��~��M�l��5i3��~X��(��� �{k��)>Hg�}B��~�0 +���J�O^\f׊}#y��|Ge غR�캑:2�NgS�	0�Йev��s{'QTӄ"X?䃰���Hd���ve��U�Z�X�ju�r��EP�Y5crPO�0��*�0��4m����q#��5\��p�<���[y�Φ�;��x2�xQ �^��[�H��Y`��E,(�	)D�b�Ad�&T��7����w��3���W�(c����� Z�����G=�-�YJ�Ϛ�d���r�~��`�ً�D�9���_`�n�F�W ��w��[y���ʿ��*�m���q��'��
�`�W�#�9i|�a:�t�n� n������~�_ռ� �C#R��go6(4����6r7���鶭Ϙ �mw�N]��X\:H�y��� �J(G7l f���ꟃ9#�Wh��ow���HS��b�`�:�Swrf^�b��ޡ��
�,���{>Ӹ�t�I`�}a���Km$�mc��~�ح9���Nb'�t�[���klbR�fo�;p�,f�ۿx�3��M�m�)��q�eD[�A��=˴�'��M�݌�B�@���ɮU~�a��E����"þ������Zv�R��ۖ{�`Ihz��'���@�x{��>G%�w�R����/U�ͣ��e�$/5���+J#]"Q���>Q�Z��y-���}��K�����p�ց�.	Wд�Iq�00�qI6 ��l
���vi�᭍������Yt	��S���F4DK,u�E��� ���Z*�C�@:WHG����*�ߠ�{]�H�٩O��<oR�h�8�)Pp9Gm�*/�{}��)��gC�Β��,I{�W;ģ��K1m�\.�� ��k�}@���	��tx)e��4N���x������Ƒ�'=�ɿ�$8���\�q���1��Y��ߞ@�8���>��(1|�6}�[5���eF��ղl0P������Z|��L��9�k&@��'*�u9�u���a�&q����-2�A�Y��
j��(�f�~�W�������.���%h�,ґ�����������$���,ꢖJ� #c�vຝ��d�C?r0 ��:��C�^�����Q�q%���
���g3�\-�)��{��I��0������t����>8P�{�FC��OZ�
�z)=*i�����90�W�&{t�Uh��}�u5;;�|d�.e�y�ޙ�޹�{�wd��#R�c��%	��xO�R}�%l��ф�l���Ba�X*ȓ�[�P�D7�hD��80S4:�Q����UOf$EC��i�0]�7./����U�Ʊ0�K-I�F���\�[�����f0k�od86���˻c=/�ŎV��|N0B8�[5�s��g2_ȗ�X�R�!�\��x@��㼿u�.�bFQ���d/КC�0�ԾC�]�~"<�Vp�����U�t畴Z�����E@�:m(�`���vSx��$��G�m���Ũ�x~U������CC������� @�"˹�
3a�ͥ�+����3����=h���K�W	|��R�����Eϥ��z-PR<0���Nӌ�u?�.���ӄcs�,(w�YKY��/~�:���Ǻ�t�����40ɱ�a�J���b~�#�Uo���ЉD�{��C���5n�\O�8f�D�5�}���\���MrGh^3�fP�����&]��,�(��w���$.�C6L�X�����N���TG�k��VjuE����'E�=
8�j]�k1��Z�ل);���m��s���Q�9��уo���Wg��i���p��aZk����~��?q>�L臐�@}2{y^}N���~�d�	Oa�Q��]���c��mg7ĮA��Ya�g�{Ů�^��ū)(C����f2�eJ���1������?�E�?�k������7f_���.�������i�Mq+|`���DKsv1#p��2m�����4���� f�O+�Y��RC�R�i���qϲM�� UŪb�~w�O�At��z$��(�KY&2j_���3�`Ah��b�V%Y��E	W��R��D*�3B�հ�7���Rȉ}�5&ƕL�[i����U%rE�@��;���{AP�7E��>��ys���Y�d�	ܦб�M/��x�,�i$q2��9��D�(0�9��m3�i���m�l�|(�ņ�X�5�H+Ѧ<I�n�����JD��0�U��y23Iy�'н�ԯ�/�j����Y�v�X^b���=��0�Z9��y��1�a��T�f*��0�u�dX{�� �YI^l]��������U�*:R�l�1a�ZI�HnU��������hΡ�7�����y=]�7'�נM.�v�p��B5�#�S���8�ȊAh�{jD���!� 1;L�F��wF�ر��h�lA�itp����J�M��#����-[����2�ׇ�YN}�wR�|�kdx�Xz����Iv	�۬�¯8{i�濲�`��Ҿaw/�CV��`Bh�Ii	�ih�y�te%�V���i8O��}Iܣ��O�X�a�x���`�$��'s�nn��I�W$ĉ(@��t��ϯ�޹����%x���#{�ƍ�㭳���#���������I���������t�O&���g�w`z@�n�gf��H�͎��K�X�`G��&����#uW��J<��0��9��֑u;���N�,-�B��j�v��������%�_�\)"nzWG�3ρޡ�ʥ��Sc\̴\����GG�W�f���ݣyd� �3�"���Gs�wQ1�`2�*ˌ��g��M8o�d�U#����8�6|�����E�̻<1�9�f5�F�0����{��e����v��c���9��x�^ŕ�������E�Me�Eu78����xD��umV��B�$h}ݕ{U_���y^s�^E���2DL0m܇�`�Ȗ�}	�v�D���^���с���i�vH�C�?�� }�	a��:��F��To�
\R2�>p7��\Z�s(m����2gJ�fj���? �.e�xn�,'�P\���cE��Z1�`~U?�\X�/cg}�ʇA]$�e�D��:��R�1�I�7�b�LO]sa3���1#��I�e�ު��Ӽ:fe���]!ә�}����=��B�q{����͵e ��p�֘�uӮZĢZ#���ɽ��i��c� س!,�Z��[	�-�B��ه�C} �o�ɯV;G��}�
���㹌|�ǟ'��������ME�B�QX+R3�e���x$�Ts��l+��Quw�[Q:��,H��a�N��҈OC�$���(�%0�������}R S����� ��%]E}�o:̋��n��D0��P}� �Ѧ�4���0X��~�8\[	��3e��μXq���D�=��_C�A�+�2�G�.��kL��K����;�C;l) QTH��:5.J��w��yo��U�E�5fSsH��
辪,O��OO"0��37:n%��y4ؚ�������U�C�N�.&�suۦQSzT�}�I���*C����*v,q�y��R�Њ;��Mi�	�S8=N+�,tVFH�@�tŽ�;?��ƽ��;�{��$�xY����d(*�m�2j�1V��5���57���%��ry�[p�G��$�~�o��2�6&�H�ږ���'x�����7�h��y-s� �v�縶it�!k|�
/�N|��Ua"���m	{�|'P���|1�rp�ɥՉ�̈́Za#]������-Py܍qm�P�5<��6,�:��O�*��e��Q��dFϛ����Ӕ17�Bf��|�Ԑ���N�8�����Nſ�J��qSV�u�(;~6���L|��2*E�i�Iy5E������:X�=��]v�8=���j����jjۮNz��m]k�� U}|oǕl�Þ{�8'�5~�d5�r���@c偘�><׈���Ad��h�[1�8U��3�l=W�Y�ѣ�(�σ  ��t�%D:`B겸�I?x��$TZ����� �5��G\�x���ѡ������~H�h̅	u�Zl5+^�����x��6+�	A��|�*=EAS�Zn�p?�q��m0�*+!G�����t�Kh����:S�v$��g|~�M9 "��r���d�'��},�>ԃa��S٧��� ����a�M��C���q&FbL��"�	M���C���I�I�t� T|�.
�cʒ��ƶ�}s���fv���e��6����,P�SO/��$��:��)����%+NVt/ȷ7� � wܜǄ^Ȫ]/�o%Va�� rM�:�r��"�Y~j�&��Hb�D�m��CG�S��}݊#�m�1S4x�Љ�|�Nr���xȪ��� �uL[��`l���9�}���e�7�F����@���,CJȃ���%�y�Ȗwq�J�Z�	ڣ+��c#+�yHV��L� D�e�
�N�F�����*NM*�qMhh�׮�n�L��%��ԙR�k���5�k��-�`��!=D"�!R�HQ�>��#�K�q)Nu��pv>��WA��x0J��#ɿZw�mD�~睞��$�n뷻��qkIk�����@1��Ep���pf�v�9�tݢ[��F<�{��ɑJO�YK��\#�v$��+
J���%��{�i��;����q���� ��f��>��.W*qt�����	%�^R����B�}��2*�� v(���s��OH�Id��	촞7%�FO�RZI; ����#t���f���ol��.�a�HW��q �
[�B�T�*��%��C�OM��,�$R/�ɻ������s0����Q��1�O8zOB���L�z{s�&[��<Z�m�DJ��O���R��ӓZ?8�Rg����+o~Еof��DN�wʹ n��[���z[�g�[����n/E",#�K�j-�K��;��T�50��B�C��@X:R�*/WN��О����W@0݀�kz<�;=YO�dO���0�(��.��xj�ߺ�yWP�Z�I"J�b���<K}�6]��� )&�����I���؞�NF6$Y?�Vѓ{Kt�]���߯K�*�Ρ/��o�
�w����NF�&]?��~G�����/��s�8�=�<m��0�p� \:7��t��lIWC�;����u����jh��#�(}���c��(�F�0w�*��7�WuY*R�5Ժ��GNdx��3�Ld���3�~R��@�'�Ū!U������h�s�C�<�T���.Y����x���Uc0eezIKR{�%�.�«/�:+Qb�\��{�D��%@?��3b��R+Զ������H��kf����;r!�C ���Y���ɧ�H�{Q��RP5�@��y[)BuZ-���_�D?�gy��(q�D�e�a�GJ�I����,�Y
B��ʯ.�B�T~e���F���F��e�ˤ��:C�&!��P˗,�v��2�<���2��aX������Rz�W�Z�I���-R5��r��b~�l'��.ɭ�L��A�'o��9�%=��4��#��U?(Ƙ6F��`��,�C�vR2
k������b$�s�<"��3������[P��n\�q_�����'�:cv�4�?��D��J��<� ����o튒3��2��>�.���*�npMڛ�f�$2X⣹s��U2W�p�UV;�K���Ze�6=�5�u-�]y+p�
du��|Y}PK�G���<	:�2�7Ʌ+@P8K�%A|������}���B�q'�ȱ�R�St�:2��=A�[�8kY�_P��aӣtgj��H%ގWOT��d2֠���$\Ba����B �{��������Q7�Xj8�w��WW/\0�Kv�'��^�{fۗ�į��r���^���8/@대7�)S�j'P7j'-���m(�h�ہ��9D����s0�PܘƣLz�JwH8�Zҷ�.�3B��R����Fo��?7L����>����iU�]�q�T��bs�Tf �g�P>�O�}���=2���2�m���DMr��#1�;���w�G�].�r�k^�9�������N'n�qOh���q`�Q�{�̬����"Md֋��=�쯦�@ʧ���-�,/����������K��q��#���J�Pn��J��yv�rg�jVG��n>Z,ORDm�O�I&ӹ9V��G�W�Z�D���QKT������\�����v��&��.�W=���<��rW�	m�A�ǅ^�GM0��Q E.d�Ƣ���A�t i��K�
�����c���~�r���T��
��NX8жo�y�`�.F�������������Y��AUn]\ӊdc�P��ùbvS�h2"�H��X�����5f��-c�8��?����J����� ���7���$8�1d��^.�(	���K�2�b�
1W\� �wg�^N900���zr�8C8uBlnT\�cك^��G�b�7\������6�Y*&��j�R9ubU;<&{@?�ZF�d]"��� �.~�+�Wfm4kF�)}e?e�0�ul=ϙ�cv) �Q�J\K�A�cj�EҨd��Z_�p�����&$�s|;[�Iz��e���6w� �N?R����<ye�Zs���(��UMx�XS�t�46�,�̖�zӣ���|��!��[3G�whޅ���.`�4?�v:O: ��}c3�Cܟ.^���EdC�;W<VY0rz�Z,�����U&6%R�Q>�Y��L�2����VQV��?����f�I��[�b7�H� �#�X�լ�=�|Oք�T^O ��(i,$m��+��J��H����r�z+�m{���1x�$�K���K2�{@'��]S�Nߛ��~!��g��nh�"�X��������Ŕ�GAl�׉=ֈ���EƵv�v>o�����J?��D�_e	��9�l#��s�ƾ)�����k�Z'�  �!9I|�o�j�b��#�0�-�ґ��wS�K}]�
m��R($3���`�l]������bn�pG#�6u�Q4ۖ��RҊ�_1.�~�~P~��'�:���M�诞SU�~vrV�A���w9�\b2��c�HL��і����S$V�&���V��n];��{0ĊH��
y�[���}���RcJ��F�� (�l�t`��=�֯ò(����%Sf?F'\K�ft�8��z"6�E6���uT�QZ8���Tդ�hdi�MzH[��n��1H���'�`�m�N�Ni��w�ʨo�TuV}!B������-�3pI5;��7���!��*����:˗24ͤ�����C"D.'P[
?`���ۆ}N(5wgE�dJ�u��jS��"����b� ;IIa��D2�ݓ� Q"�74q�p��Ĥp��\Z��M��ר��A�v�Q�H�3��������WW�t�&R-xۅ�i��M�[i��PUQ1�atFHTQT��wW�V�����o���\��:.$�O� n�1q�\��d�_���!Â93�����uJ�ɇ���N8w��a�*��p��,��X�qf��J��@V�����%[�&*a��
�sw�׮�mRrVё�`�X�ߥ����Xpq �w�he���t���-���Ō�t	^C�9��fG�e��A���m.+���]���2)5jO'�zoZ�9�*�S�U��0 ��6�������I����*�U��`۠
�_�'N��U�0��D�$~���`b����U���8����L�7v����'ہ`\H�	�8ަ�X|;uFꐁ�߆�{B����1�W�zI�Z� :j�����ګ�?A��B�����Ê���e�7�2��ڢm��a���;��l�S+��8>�;��)�#�m�M�6�	�>�+C�f��`������U�@��o�6n� ���wyX��GL����>Q��9a��q��5t����G�0����i�E�V��R���G��Y�)M"��;?n�X����LQ`fX����v�~JD�q�C�S�<�d8.˚�����Ȇs˥K�����D5��L�ސxu�UK3P�h��|��!?b��I�:��`�Ӓ�˯R�/�2h�V]���v����h\D�ث}a=�,��w��S��"��|���k�("a͊U��A�`R.�u��L�r�ma�`���>e�e�T��Ŷ;F�E��в�n����8��N)�x^�jz������m�1�C��3��%#V�����@�v�iAʷp��x�ۼ�F&�;Gw�HB7׼���a��h�!Y�K��i��YR	��/֩<qk�߁qr�x��F_r����c��n�!n���E�Y<Z��wW�H��B~s(���~���&��}u�3>�-Q����>����H�'n�?b��y��V��>!�І ]6jW�Y_��h�GDC�����]�f�'��ygT�g[QKA�U�=9�m��)v�G��wp���?�
�ݰT��K��`ǒ4T�؞����%$�[�K�_����x;�����'��[�7���o�Ŀ�Yh�r�{��T<,h����tJ�	Q�$��u·(Ƃ�8�\�h�#bU��?��!Ϋ�{/w �y9Ç	t�'�e�����P��?|W1OEI6�J0��U ����N��Q>��x�Ri�����a$�����������w�����,���K5;��$�;�����iF�A�H)��W�����h�܊�L��n7z)��П�����:�9�z����Z�3i��԰bu�71?�lx2'}��E!����Lz�G�=��㬾��+�17�]�63��Iy����NO'=�T�\���ӎue���]��t���2#u�"�����`S*g�Ȯ��T���s����[2
��V��1⢓a�ǖqw��\�T�l�(ԇ\�֟wm?�I5We�DxNa�y���l.GE�Qٳ�[����`'�~�tRn�:>�a#6{��|Vr۹k��k����#tJ|ea�{h��)p��7<����9[cIR�bG���I/i�����sxa6�zK3�$�y���t~LF&Wx��N� ��7Z��`ƶ��ݽ�Q*�ח����@	�CK�#���t�Z��N��D�n_��^z>x�2[_���mo�	Q� ��k�,r"�ϑ��%c���`����;��U++����!���X���X�8�V��QFC����9u�mʏ��;�ْ�_!�J4\�F���/ъ\�(!`��7g�1��z��-�� d�U�<�G-��9�������$��]�d�6-]�|�Ã�v�;+��lk���w(<���,�R��I��%@Ia���,T��l@`��Pk����UԻh��-5G�=T�	X��_�-&FPG}�����e�,* A-qi*�����%9_7�<`�؅�~;~|�L��l�8���.$���w�5[��0"�f�ɜ�ra�"퇯 )y�7΢�U>���T�Uto�\(RS>����]	�H�V�D؏
��K?�	�b9\L���h�����}ɋ��wW�Z���K��1;����'?5pC�*1��Ӌ��#��W�3����ܤ!c!`N�m*t���M��1g{$Z~;�����J�1?.��RMxj�*7_���H!YY��j��c0e��$�T?ok �]�f,e03��ӯo��\-�qَ�~�g9�|l���د�)��1�J΄��farkŉY�hm�D(*}Ljm��fǋc��Y#���om���b�rGjC9�1X�#,���6`\���]��$D>�Kz�5S6�䚗,�_U��c0\�8Xq��04� +����z ����|9q���NC��M[�%0H�ƿ�d��g�ɉhІqؠ�<�yx�d�������`�N���HJSOB�`��B�>a��ݦ6=EoV$�-�MHb�����P�&&����^`tT������d��r>@2O+�G�>��,�n:��iC���j��@�K`a�`XpGǳk,2��3�b��I�`}��?���~�y��vf�kY+DVH�F��!��/� ���ES�8���� ��W
ZR���FK���k{4��g�Th�Z:�#�vפp�3V��ɥ��^�A^�bCf@)�8ޜ���W��.DN����8�u(Oхj�Y5�a�ٳ�����4�6nl�ZmXyZ=L���⅄_&?f.�����ƿmE�$T�B�%�3l�|�Ϝ���������L=[��c$I�<�D;:�j6�ӀU�,n�E�YM� ��s�AR��4a�   4�SE�>u ����R4��g�    YZ