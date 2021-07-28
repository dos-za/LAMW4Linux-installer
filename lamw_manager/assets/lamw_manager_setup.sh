#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1215046420"
MD5="d38831e253be4aee5b80a0f9c7bc9e7a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23332"
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
	echo Date of packaging: Wed Jul 28 14:04:55 -03 2021
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D�����R9���6bq��	k辉�s%bdA�$6�Y[���Y?�����["�{�A�#�V��Q�9�4�d�p���]]aУ��ʱ�A��_i���}����T)����C�#2��D��m	4/u����`H/���`����]��x��\ !�;�|� *�f������ҽMY�`)��5sR8Ui�@�B+bi��Xo�*&��f���Wm#{�(~���|Y��4�����E�uu�M�v�{�F��%�V�7�bQbd�gM�wZ��sX�y��w�}8Ik<��QkeS�WՖ/�3���':֔pa�����e�*�� 0���Ö�%ѝ^P��~�Z��0�C�!�Ub0�ʵGiO:����A�� ��g�Xt���E��x'���6c@����(
�ᝣ�L�M��M����T���m�&&�\���ch�-y?�2l�����3 Rv+�4���|F�s���hz$[�l�_E��TH�%�]fZ%��������S�Fhnc�v�����YȾk�)��ߕ@�j!�SeVD��h����"�+�wK彗1Z�	_�ڎ�U�>�
��D�L�����3Y��H�ig�o�7霒���~}/�r��h!%wp�����8��d%O��ts���[Xp�*1|"��jX}�_n�5HB���@+�|v4��A6 �������'�W��%#��Q�ɋ'̴B���H=���'��A&^`Va����`b���T �^c����Z�F9p.X��粮J۵������Pesoc�L��x�F��N��pwl|�b��%�ṛ M�ж袲��|l�睸��`w~@�\pL�Ad K�z������1t�<�fn}_� �~Ӥ�d�<���>wk�~t�<м�����U��M;�N�t�k}B���7#��+��G�g�[ܾQH<R5%� �����2O�:����]�Eh�@ao��+�ҍI�2��5QkN{��퐦<�G2���I���y�'ʃV��� �p�����k���&��밸���r���>a���8\�꜏��Qڎc̙��vQ�5�7ܮZ"�?��=�Y�db{%@���
�5��ՙ�۴g�Ł6��q�3"�?\HX#7�1j���؅�l$ގb*d��˱��G� uN[��|Cw���?��� p�A^Us6ƤX͓s|��%%A�T����7I0���!V%��t�kHU�>F����� ';��%SDE�4��Uv�����sf�J�h8���d��;T���L����	��m��nK�&#�o��6�yG�b�&���*�g�O@zl2�Pv6k΂�~�sk�sh9i�x^Ci8��Q�P~�Ț9�!?�o��	sT�T|�t΄��/P��$S����8��!�a���؂.K��j�����@�����Pxx�������@���#ʆD��zo7|a
���h.BR�TgױV����[���a_b��>�!�.�C�.��r�\��Q���aj�:;.n���F@�,�������u�VGŷ�64=��$Z��ׅmB���0�S�x}V9f��3/})pd��b'�jG��C�KhsФ��6q�XU:@.]ek��΄�a3���# Z���U����sK��J����3���^��� B��m�2?)#ް��4!uþT~}_��@S�G�
�#v~�^}��[+�a�f�>+5[t��e5��&��=�_�a�t�z��cE���p�C^}�t�/h�'��F�#kb#<-�uq�VSIv��F`ۧ{Ԫ�FWV`����?w�r�Q	0u��p\]z�&��s�)�f�Gy�KG]�����Ix���K�><C\sƵuM�0c���yd8�:jz�@>�����Ķ�l��bQm��
ҏ��a�Pi��h�T�A��uچC.<��F������"��D��Y��1�<�]�y`�W�1b*��uNzA��jX�E��h��[�
��OH�.��a�y+[KY�JY]D.P(d�Q�R���.q�7�6����gH�ڧa��l�_�����{���4$[_Ӟ�����r9�S�9�t.�9<F�V�p�&���Ã�C�i���R�Ԃ�;��D�����=��_nz�8'Y�Y�4�\��cr�,��>k���d|�]�������+�%&�P��m!2M!�d��_ű�pq"��#�����ay���a�b���X}_��/�����)~���Bm$����DC�l!�3�X ��;v]G`f���ۖ9����Z
�$K˼g�'?��a��\q������z�þ�`���7�!��K4t��騛~�eq6���0�$%vRFP
2�-���N��z�|20�]���"�kpV��d[�H�~�\Zͽ"s�B�!K�Bu� ���ҵT�U2��:)c;F]�V�P���
�}wDYY�m
*�1�|`����C5Wf����R'g��4�l���;�GH��R؊_�����#�]E"�_�|O5�6��H�#Cј����,��Q�o���:��O;���U��5H/ei��Rjɾ��fn�]lЗ����*I�+�'�0����	�SјA�}�/�����g��#���}��Wek�T���r&<Di��_G���`��G,eq���󗃿�V&�~�����{���;g#r���-�f�Y����gױYi��k�����IV�miC6҈ҁ�����g<:�^(ͻ�|�۾����V3"�iv:�}��b�ڏ8�o�;�ղ����x��k���'�8�E��([�#��r#�(���	Z�W��	'j��)�<�z���|t��ZO�����7�S�4�Y��A*#��
��h��:n�Nc*�s�ļy��gl�p�ը-����`�^Tڂ�^�C l�.�"w@u�*�5�*d�4O��aP�L�ӣ}���GN����sM�l г��o	ⴊ<��̫�Z�
.r�rr�C1����z�[ta ���%��ӂ-a}Ux\�..��ș��Dm��tTN�K�K�0)�]oGI�)��+��)ZW���&��k��\�6����N�9d���R�o�©��'c�%�)�b��*6$��kg(�$�f�μ�*5,�&
Q��Haݿ���m���Cp��V�`cn��P�����5�E\y+��~?ʉ�Y�nz��iޯ��0�Pp9�'�僾�OV�c��]��VHK��j���BuM���bʅ�[" �J"\�B.`
�rAZ�'eM�T� �>u�H`�蛘;��{}�խ��Ւ����=�uV0�0���c�����bJ8�F|o�@-�|�����0����򐅵�����(���y���ɲt� `���97h�a�p�['�ĮJϔÄ�C�i�C^;���!�T�-�8r(�=�t4K[6Y�n��e�>�T��}`G/�e��R�p��&{Cž\�QOm�bl�B�4�m�̍�z0?�Ts�O�����I<�%�m�.X*V�ñ��s���5D&�uX,����%UQ�]��m^���Ĥ��ߗ@�>[.��8ת�؟���ѾK�bT�D��쒜꒭O���[��ڋ�\&������#�2�i�"yp\�B�W<�?�3� �i�䖼��f���]B�ۚ�OL#c�l?뻦��=��}T�x���!�>##���9�$��𡜛���@!�°D��.��2
d?S�^n���
�s�'C!�ۖϢ�us�T���X���|Ɠ��
���Bŝ|��y3;&��Em��c�n'��2}���(�$'�jdx�N� H�R��M��/���I���OWi�g&�f5�K�����RK��c���>+kR҄S�L1���˩cC�5��.�P�v9���&��iKh8��f雩N����"�D�z�*W����Y����摈�B�;�D!v��%~Z�R��]�?4[����.���������'�7F� �� 8�廣~�㻽Q7�'��i,�%G�s;���*h��ʬm��H	��h�����yD[�c4I��h����x%g^)2��
w!�<�MX�S�r��B�P�t^�4��|�vb�3��ת�X�p��Ê����ܞ�{:RA�T�޿1-�Q~>۔0b-N^��0�:D�ޣ)�P˫��e�Z%�U�ձ:�Ѱ��Ϙ���f'N0�wqj�;TBt�w��Bpg��U�ơ���F�%��X��N#ڇ��H��Y�t�$�����Ӓ�|Ϛ�M��a<�Ni�l�����.j8^��b\�;~�f�)Sh"����!k�r�[b�H���O�{�5s��-�>Eo�A�յW53��)��&�c���h-A�.��a�K	b܃���=�XT��G�a������ߝgK������	ͥ�%�>H�* ���^�0o�&�JJ
9p����{�� Ԣ�Ď#�l�+^�o}���k���a�>�Tz]qn|�L007<�2m'[�$Qn�IYg,��s�y�#��&ں�q�|�{�h��lz� 2��m����0��;1�q7`�b�LYl��� �~_�ޏ[���ٶbq8>�������it�q�����Eiɯ�^$�,gG�ѭ%`Վ��!�Ҫ�v|�@�a�d~qK�HdSW�R�G�gC��e�^�_�;��gX��ߙ�fh���.�0�G��h�EF�a�¯�罬��_B`�Pw��G���B&���>;��u���Ȼ~1���������0�T	)��:��-)���G��&��)��ŷ��G���pDmڬ��I���$|���%$ $����}D��1`��,R���4�����W��"<@6c9�f�W�#e��Lصȶ}��qf��Ð�55����ǯ�3pt�%�mO����%�0
�����x`�L �2~����%�
ǫ��ϣ�O�dژ��L�?�q���4Aϰ��?��c������"�W�/O{��`�� �*<ƳR���?���?~	�n�����*s%��z���<�q�YP�&���u�0*c��N9��]͙~\��ׯ���,����R;�(�o�}QdqT���c��7���^F��������nՉ��4n���]��>��GAb�P���΂�(��_rwDLl6	�e���©���Aidݨ>�������͔Ki�`{��	j��eD�aXرe�R�#:P
���NZr�_\Cl��e2s��f�Lq�l	/�=�MC�|��� �74%��G�&�!�K�/>�YE\T�{v$�RE�R����r�c0������@c�
:��9wϢB|ԙ�9�pL�T0��J�l&����@��X���{�-�����;S6F�ysx^�8��
:������?R�Dŕ��o�b�+d=�0(�-`O�	y�uͩÙ)(����C��d����Κ���mH��V�`p�P�zzh5C�\����-3�Y���Q��7( ��S�����&.]vA���{�}J<�2� l��\��r)N��%�H�m��4��?r ĕ��+5�E=UJoR����[f�2��@��!��)#���i�(9���'���B�s�u�L�[4\�R=�c�2�М���M�$R�4�9��m�b����F���,�xl�iJ�Z�*J�p�q�x�]�(�+0 7�3kJ���0���
Zw������_ �	��H
���r������>Υ1��HD��vd�u���i���?ι��LG-nx]�7ΧT�)^��d�4�i=x7���N{e�H׶��n����j�'�������5~�5q��߉�^ �(��(c���a�E�mk�؀x�,HD�:�)�y��w=��7�M��E?����W8�2��n��y���fB�JׂT��	�m+���2��UW˟��.�,g!V9>�*v�Ţ `���K�즛H&�:P�]"@�ASհ=(�>��T	��oI��D���y���{�Q+�~�G�x| �U��Ӈa�h	�w��������u��Sz���\��^�I8R�2#v@�B�4)�8 @,�xoyS-2�F�1�v���;]]��n�l{c��iY���� ̱{2�֟-A��Oꨭ��Y3�er��}�/n�{���Q&u���,K�$�5- T:s$��:���}	�^�� ��9�Iws�����<�����K���;����^��
��χ��~�峸��Lx���<5�
9�_f�j��~��*c�@�n;?�c��9﬐�>�7��>Ek}����X\��Z��˒�{gF���P:�XS��뽰8����<��{\��r�95����Wn��9�7Oy9�ݢ� 6��k�F�CƟ3�H�`��{nq(yoG��n�}�Ѿ�Pw���K>�L��(���C���}zߡ�Vi�UM,Ps%@�g����:�D�$�hD7+0�Y�}�¨����2+�W��U{������F����C8ɮ�\�<��9�:��}}�.���^�l�nF��d;�48[��;1�pJ��D}���*�H,��A��"՘�S��3��yN����kg�2�ET�*�ĺ�!}H;́q���e����Ľ�ԣ��li�z��}�2W�;�8�F�g�@|tm����IC�����R���	ț����C��b��Ȉ<WJ�dś��"��-�L�0��?�6�:4�+����Ș�����'ڀF�uɀ<��
o�0�?pv��U�0�Q���H�����w^0�-nO��cȒ��h9��~I��(�-��)п+Z.f�.o�;��[������Ck�L��]�E��(u�Y����F�����=(�ҋ��Y���k�-E��I�	�9�8��DKO�(D��ß����<j<?�W�W%�\Mh��Y��~M�4�<����,�>��w�N,���A���i��r$�w;U�@�\v�6CFp�Y�9v�JE#�r�9Q69��(�ur%l�
h���2���|�殭z}��כ"��j[�?֛�M�?��6��r�Ԅ�2�.�C�]=/]�O�����h�k@�y5µ/�$ρĊ_��-B�V�Ө���,0���pjs��6�َKcC�HU!8�%���g���Ek["Q.��W���i��#[�|s����8%�/
z�*u��:��8������@{�,}�U*�'��V�quR�����u�����e���y�X�t|�$�tX��x��D�2�ň&IZ�R�Ku��\�o<;�r+��\n���7°�H���h$�İ\V��.8m�q�#V���H�p�L$�����3PB�����c]j���i��EF,�
AH/N�&Jbb�7����Y��ի���1��<�����X�Z&��lzSF��TB�!�bSF�ЋE���O˃��F���R�n��n���~��Z H:�рf�ѵ��\��l�0�`�v��_�~��0�h��m�6*���w���+�(����^�^!-��EMO���r,}]��Uzѵ4hU|�ڂ������G��'ϊ}�"2ׂ�
��w��FI����>����*8O�.���Z|Θ"3g-�sd��L�`y� ˧�W7i�0�.����H�cH���$�k����[�ggK�?D�yoD1�'��1?^_QM�A�I�U~+���hVL:�r����X��������ݚ򏨠��U"�i�"�g���Dt�0��	���D�U��=p��5�q���%N�C_�v
��:��f���)L?ӆ��T�A�_�zt����g2���頟��g`��6\�W]�Z �B�?+t��?O}���2�������F�ŖAtQ��ۓ���'�<5v�2S��ր����{����c������H��i����������32i���� ��֓��-~
���1n�'"�5�y�m�-�A[�3 p�c�㜄�F|Ш[x@�aZ�>G�p�Pِ�����!L��߬X�O�Y,�U}@8�4[V��
�Ap�e�fB C�!wQ�,tQ����!7
v�2&�r�h{��4ᶱ0ђ�:�n-�1G`���y�<�P��>軝]��	�CeC���Yr£�[yok�}N����u�pt����D�A�g  %�q�ЫN]�`���1~�;O^�J�o��������n�BO@p��;Nz�l�xlY���a��:��ܥQB)?颳�ZJ�� ��\�~� ]������ �hE9�����nR�Ϩ
߷���z�"=�o���[�u�$p��t���[O�6 +��[�@����JzO��Լ4�i�8_����y�Ƒ�m�٧G܇�mK5�>D�|�#� �������}�i��e��t�0��5tNG��1�ͼ{���|�m�~"9��R3Vr���Pц�ԛ0D$���S:L�ɳtݬ��zQb0�C۹]W�i)�*\�����'2�0 � �������˟��iZn"��~3P���h��;"0�A��Є�ٸw���kBQ���g61�����(y7���+K�Ff36�¬��u�ǯ��}�CAR�E�Ql$U-��d��%�|�V-މ[�5'(�G�k�&m[_�/<m��I��Q�R�Mi8��(J�� �2��葜Ul�j	��
	5��Z�B��	Dio��=ŐBPv$�	��ʀ['�'��6��颺%�GT��7[e�Qژ������j~�l����z ��Ij;��i��g�c#D�+u�Y�K��'O0P2�ӑ�js"��Å���_G�m#w�%�>�m�1���%G����Mu4x`��P�c��'�A�d"X��r���{*�kD�O|�����P6v��ݞ�-��$����d��: ������a�o�>�nƱ[��Q����H}P�1W�\/�.W��8�j��s%�v
�u����E�;���]�[��8��RJb�l1�����p�����$cP�]����4f=��|)O���	�]J����Q���]��N� k��97��ZJ�:�^��R_�>�Ec�1/!�Wg@'�j��N���5���9�]���6�Q��k�dU��D�U���W���R8�� ��T2ު���;��+5�:t	��D����*ÈDy��������F�r����1����>��~}-N�P�A/�����C���s9l�����s� ��FM��u�w��n����)-�v:`E�Zˏ$!�'���c�Y�N`�&�|C�\GG?�h��4i�i��G�ytT��^j����LԿ��E̵�*<NǺ	�X�+�D�-Y2Dg���+��P8��C����(�R?[�\��(����[yΆV��^�o7�7�#��{��$55���l���pˊ�=�Ou�4"�Rf��R4�hׯ� v�Z����DjA���
!l4n�9��\c�"&B�P����2��Û&�vN��� �^��l�E+C�����>V��l�f�	&d�9T��H`^���2WJ]Ӯ.�����Ż~[G|�ay7���d�o~y�S?�HL{�,�6�4x��Or�EG<�L��8RVr�:����V����<�<w�sMI�K�$A�7z�Hq.���$
Uo�y�NguI��ӻ�{����8�^4S�Ȋ�D4�J7odC7#0��j�V��6�X�@�f����^��H4v�{����@4v�f��N.����w�o�Dn�H`���&g�1���)�}��
to5ƚO���5ycCe�jI���N��N:���Ԁgt�Z�c�HWq@��!/��>��q}�v1v�o�;���c�;	�3;;�*D�K���v���"��B�G�Ll^ �.�w��I��Q���J<Ԑi:�7��tC$q!� ���� ;�TD���˳9�����bH~:p
���
iS(~0 ɧ�����٭�sǭ����(��s�4!�8έ$�Y�љ��k���$,����8��������^̨�
y�..�Ȯ�Z:�>�Q�I�6^C�w�����tyց<��������:˹�@�X���ͪ°~?<�Ľ�0~D<�8&�̍�.���CJ!�7 �c\E�qQ'��=��R�+]��I=���$}T(���Y˒f,fC�ϑ���[����e��	����-����wdO=9��	<�:�XD�}��^ve�Ơ]��+}BcN�K�������j�}�:b'��{x�_�1�1�I]�d��N}!��/Hی��Q�α�)aD��-�۝)��Rz�<H�3^�!4 ���;�0�Bޏ��h��37��@�<*<��f��<���+�@.D­�<t�g
e�I2w��<l]��+��V��RLIU�"��K�!G>ր"�����N�ւ[x�t��	���Ss�Ѹ�+]�	
O'-���7�	�z���S��Rj���A`��E� �Yؗ��d�(��Kzg�<5$�/��a#[�Ӏm�y'QZ"av<��]�/��y�	�u>iC��c��%��.���z>��/��:�]�A]FE�0p�`!B~�}����X�5i7`�[��}Xb���������FF��}�@�!���Q����o~����X*�S��eԥǶ�	6���e�TH�E�5�Ƕ�%�X,�P�.B�7�<�@��5��N��m���@k䀊�ݼ�C",O�e�]"Px��H�s�G�P�4Y��@ [OXYU�g���#<>�t����c�e�@k�dU�e�����; ��7P��Ɯ��L�� �=eP����M>G7�d�ʒZcP����bP�d,LH���U�X�ݣ4s����3
S��Bg�i���t�k��[��L�o�x�z�?oZ�0?��/�T&�O��&��d��8qFo�9�����3@:=e�M9S�h/�Ɵ��$1Ϯ"z,)�2��{n�XTg@���n�uʾa��~� I�T�"�	��A����ˮ���mK�g�ݹ��h ۍbme��hOפug��N�z:}�$;��l���=��X����SZ �"X��at���%Fʱao%âdfr�������آ�堕DA�ʲ��,~�ϧ�RZ9���8��͖D��4
FW9�@&�||0�sr�J�l�É��N5�w���a{%����b��Z�:~���7zM��Gf��Z�Y�t���M�dϏ��e\�&�i��=��巘�3�Z��h���'��M�n��ۖ=/�����Ps���T,8���H>hL�4��r"�0��3:W�Y�IUX���%�@I�g`�ܽN$x�Ѓc".����=�SG�U�X� �L�8�'G Z�&EQ�}�	�V���m"l����h�s-� �$:U/���>:n�B�0�@������X<�k[�|H�����"����X�dMc�;�h+׍/d͡� ��QH]&�|^�O#�p"YJ��ē���s�z��E�:�tV����a�P�m4ʮ꒷VӗH�<r�������N�3��{���y��6v�e��Kw����p1�E��؏�����B��(�~�ON� ��(y����Qk���	Ԛz�Ր�F���q��s��ҳ��昜�"+���!� ���oH�\s8��Jc�*,�j����?��mg�$�
�=�Fk]�'�w�.�Dkq�l�PP��f���FL��4�~%��*[�z\�?4�#S6*r�{RS�Vw�$��%���1��0a�r�>b�4{���⪼3Mk�d���!^�?D����.����gF�|� �E%�2r31�N�F�^J؆��?f 0v����#�(u�Q���C߳v6L�F6M������2z	�^�f5�T$����g���3��+��]XP�*� ���ۮu�0�x)s���
�iR'���ͭ��������C.m��f<`+<�}�H�"����M����oXd���۬�cޜ�N�1 �����]d^�뼶�"ǁ$Tc����� �FQ7��f��؍���i�lD/��)1h%�����%�;! ��Վ���[�d�gv�r� ��X`M�+ܶ�P!ԕ�:�
��X%��/CB8����d��]���ڥ͠�Ŷ]�β�ҕ�ջ*��/��~f��n�%k�4��� Qw�?lA֍
�⤵�˺]K?������L��Y���:����b����X����be�����3n�2L��YMV���|�K�K��m��a�edVf<��J��,õ;Wo�`�VQ�߀;ğ��T
(HN���[�)�r�Va@V@���LFw�m	�gG==�,d�l�4R�O��j\ڑ��/�Y�2��@�@���}�. �x6�(j�Mr���{�쁝EQx`������1b>/�.�®)K���g��+��ꈾ�����	�%ڥ�~���o�Q����	PMԙ�ݚ��C������
p72;3L�ҋ�����T��s4��&��;�bN��&y����X�IPi��x��H[Ǥ���Kr��.DH���e	���[+d;�gv&�s�싩E��x���g\�'�mҍ(i �c���t����{4�Z����֝C?E��B�Z���������y����Hu��muΤ0O��g$�H����<��6K�Sn�J�v�=ʴ���
�r[E�JVr=�c���T���CwK�,C�E��j�t�|{1!d���r�r��K�1�D���0Be�1`�Ѧ�qJ1���3�s�\k�u���CC�AȎ�%(���Nzav�-36E{�����o�̺,����?!>�j�'\����0z<�+�{��P�
�.��
k�ͣ�<�]�(�R�Ν�[��7zA"6A;���b��f
t[&{��X�[<���|���T���L^A
���^+�O�*��b�,=��w<v��h���A��O�qwW@�Z!���ׯEM��S�U�k���P�j��'��s%Ӵ�E��q)�C ��[�zp�=�J�l�����
�����D�ݯ�\��(��R���,��d;ϥ��H]j����K�ρ!s���\�t����(�fn�ğ'6~;�֊0u�,[ZM�No�&ev��MҔW$��:9B8� @"7�{e�MaJƎOq�,�	G_W�,��G\��|/ƺD�D��&8�mM��0�sXf�<ID��A��`��g�2����NsE��{`h ����w}�nS�;��E�A��+��������a�%B��
�|��'�)aӄ�8��L4恀��0�Ǎ��O�H�}T��(��aIA���r�Z7[���z��Vk}&�:R��j���� >��p�yVZ���M"��. ��è��r�=<ӊIB�/.�1�,���q�
;AS`L�Ƚ�]8���y��-��ݳ��D��Sxui��߷�:gS�u��_��뗍*&���4]��{�VY��4����!��>��B�\%̸j��f��&�L
M*1ʦ��/:����SKY�Ģn=U'��{a�ɏ׶/yN�:��?��� hR����ؼrj����V\�r��Z�Cm��;v[J��>T�}Ȃ�.�27�y� ���Z(]�Z�?p�l%h�g�Ԑ>�*�y�vs+�UPǋW8��y�XNϯY&�^D�L�k��0�i��CĢbH�� A҄�]��*��[i��b���b�
s�fDtԆb�1U?�Q4�;g%��c��zTw:�;�e���ܮ�:��q�6�+��(���k,z8��1�T������I�W��B�!�u�B���S��f�>�<5��1�OD���h�u����e���p�8���~��]�������yFC�ozH�@�b�n,޻�:��*f���(6z�c�{����ŠB��t$?A#.���YXjo�
E�>�pς��y	���XI}�ȣ+m�����������G�ڇ�5t�$�� >��M^��/Fm����/���G;����RW�y�n����9�ǅ��SkB[n�G���P���:�ռ	�=Փ���1� g��c^�)��)�R���W��B>A���[�S+ث�Ǒ�y~�<t/9���U�ʔ��:w���pW2�FҝJ��4ק���Oo��l�6�MG�Mր���,.(�3h�W�m�3X1f���q��ԝ�}+���Mw��0,�����������X�"��cm#�$F���xĎ�<Y�ܵ�r�3�H�lB���U��|�h��+�"�
��� �܏M�|�nrLN|f��6C3�_Ep-�å�fU��+��IܚL�@�3zoc�?�(���y>W͋�,Խ_8$9�ޮg_���=�ĥ����9��3|l��h�����t�u��r׋ʨ�
	k�oN� ���x���2�Qa��[�o7�$��P�g'�<$��:g͚y<��\���������G4�i%v�w[K��X/��,��Q�	�jĸ��3N,�i�<�6��ߡ1V�����L{�}�a��V�D`?��>��,���E.s����U �EYES`���?G��� '��Y�Ct<���R�ժ��Ӊl�J��&ݩ�xH�Rb�]�'$w��{�՛��sk�^
��|�_���5�������o��R���G�F�O�UK��N�Aw�`,˸HOi��\���*�,>���<-�D/�ɦR,��������w�[�� ����y�C��Mb��9���U���eԱt��>����c�%y�8��1�_W�<
�ך�B�:�;�Vӻ,���f��<��0�tzl~�\_r��G3��I�0k���p�~���)ް?����Ԃe��2<�-���~���1K���9��P��]�mҿǃwo+�>;"磫$�Iݩ��|]�
&����p��{�l�X� C�)$P�a�'���<%u�L!���P,�n�_�/�kH�#"��/6��W)ߚ�����,T�:5�g�@����#��]6A��b"�����4�Z��=F#���������?��uBB0�Puj��a�ƛ�-�J���I��qY�'��)H����w��`�D�Je7ӕ����7׎����P�A7U�n7�,��k#�N_�f��]��ÉX���xf�\P_=�ۼ��k��5?�����y7������D���-1J�l�Y�/�,Xjs��3	N�8۷eO4Ș ����D�����\	�h�N���?���C����&y�)I��\���N�!��9Uσ�pFj��F���E���ɶ�������.�|LCtne����u�"��{��n
ǳ��y\���N��h�)�D�O΄��'d�3�e���!��NZ��Gn!� ߙ�<�,��G^FIP�����2�����̻i�8~���t6V�I���ݯ��˓UZiO<�R������vZ+��"�6��-
����S�yZ'e��������A�'~쵗��-���H(qR?��76V�0y3Y{ �g�&&�V�Č�/.4`p�����3���*�'�h�q�ȅY�K՝�����`��� �1��U�#�Z�qF��� #��,VyhT����B$��S�;N�2�QY��~��
�c�F�O����~F����>�ۦ���*�)�^�~�D�qp k������V�Fy���	�u4�By������7�!�N������M+G�[/���sm��6��B�Ӿ�0�I� ��&t�_�A�>��Vǐ�����T��:�L��$�D.�*e�q˗��v
,��\�<ZQ��ϙ���]�ν[9<Q�7��va Le��?�qk��,����'��_{dCR��-�����\ԟy�8��۶~9�h�7'�A4�¢�)h�O��U�d�Z�s;l|����#����_�)���Pݖe���/K��WѪ�B�%����&ﹿ��k<7'��:ap��8�"Ai���0�O�����b�6ڲ�;Om�D�����?P�=�:�S�U���#�b�ƞ/>k�V��<cՊ�Ds�/�&6`j%�h�U��l��{�)Z���#	*����dt�[��CCպ�M�	t��"�@q?��[�B ��&S��D���Ee��Y@2,giP�$Z��gypQd�lt��~V搲�ռ;p2���qL�T0���[��l0I��eA:������݉����O���Cgv"/6�M��Aŕ�fM�T�t ��1t�1�ߨ�Nt-�İA62��2���T��8eڝB�{�Zj��@���Er8�zѷ]Ҏ�tl6�GP݁Qs3�c�����%c��	ꧾ1�8~^�\��L����pH )Ԕ ��}7O�M�كh��HK[��1��5NU��A�
N�|dX���2%c�*[j���y�*Els�Ɲ#����]A���ya��M���]�2g�.6���q�� ��Y1���"Nd>�H��� X}�LR����(`a4�#p�"y¡+����1.bL�O;4kj���qYt���R�0T�eI>:��8!o��fVP@0����s䠛���;�z�ܑ�HR~�"yI<-%�j���oM���yV�%����&�����D&W峏����-|,RY�UM
/M�O��>����Tm���7h�YZo��/�e�]���C&�����}�8
��-�E���n���H�odM��Ż�A������Ŗ�t-�O���{1��S�|����y�V�X��A�e�xb��'jۤ$���:�Y@�U��@�D�dm�T�*�^�Zk�ej����7��Y�-s�ڨ�ڳ9�kް.(Q ��b��v<$�K�#o�����w:��O��� k	j���6��C]����8�F�Pv����광�ŒM?����ݝ�I<������q�F
�=�7�b��k^W�?W��<[��h�O��=ɔ���_f �����=蛛���)�̩�����z_�Rr��\��WU���,�JS���2廗����Q`�k������I0��,!� ���U�p�3���$���S��z�=Jܛ*��I���p?�|�$�\�q�&V�����+C��=���/p�{y-9+{��: �.{7l�V3���g�,m�Q@yo1At�ʟCc6�L����1��ա؇�zE`�&J���뀾����Sa�
�>�<_]�0��=آ������ �I�<t�sQ��Bܽ;.7A�.���N�L!��z���������=�Q#Qɜ�Ja@�L���zH,ـ�56.r�1���b�O]�NbC:1,9}ʫ�t/����2=si�"��E�% ����	xŪI�f����B"y��Y�5�TX�}�+�"�޾p��;e�M����.������=��O�׽u�n+��9J�j��	��U��Jl��8M�IR�g~@��6������k���suV��g�$u�7��D}�T�Gz�8��?��Y�>�J �I��D��5Y#�s�$�ˌ�^�y���2����*�?L�DT�;���ۋv�Y�W��AE9;!�A�&��XG�l�l�]������,���-���6��_�������hQ�ڹOӢ+�Dj�%��Ā����}�^j8x�l��q{����i��>����]��&��v����i�j��5ٶ��K诪���N�)�����2��	|ЭP��V��a���	#�j�9☧��?��c�����7;�
�A����0�3���OZ!(E� G��S7�-�H�B.;ަ�HM���ii�a�����,ê$�z��t&ğ�\Ro��"��&@n��釣��8�@�t�����K�e�ܹ�k�v9 :�X���·�0k�xkH�Cf�L�� D�+��� ���3�ޘ����O�pif��?�uB��.vx�_Mg�G´C�iD�*9i�wGҼ��պ�B��<�ϿkE�7��T�7�#���m�����i�O��+�M�v��[s�e+y�5d���і5@A_Mw1�9Ũ<&נ9�������)}i�4@��$9��A-`��g��ZMf��B-ZY��<Y�[� ��~h��r�AQ�g�P�p�䣤�l���^AF��P�C ���~2�ק��z���Z!/*Ƹ�Zȴ�D�F��\Md
������1�e�������PI��h�-�q����t�|7i��U�U���m��h ������w'_��a!��m*�(�|n�(B���8��E4�,�������ߵZ�����g��܌�Z������N"��%],蝲��e|k��U�ڙ�3L�� �M�qá=�p��!_y+���eP z��o;[�lt��]l�԰�U���`;m\���b4}�6�8�?������Y2b����x�0�z��������$x=��Z�|,�������!ܔ�SX�#(��֦�H�����с&B�'v��ˀ37�p����f9rj����o���ܥ�a6�_ܬ���e���G���H�gD<�?��:�R���h��w#Ƹ6`ɭ�r��Q�S��b��Nn������gy���=�>U��J��*��N}Ex�s�J�D<�
��[�=� �\y��ʴ��fU>.qŜ�-�4�����O����&a���3�����/e~��Qps�5s�pU�L�:5�`8��gws2�Z��k`��6Q.���[ĖM�s�H�q�GE�6�+��QM,�ѹs�0�3"���雥�����2�f��-{����6{ۓvG3��\�i�J�A��\2���j�|q��)���`����!)��\��"�~˯�����ا׶jFH��{�CB�%��D�PV��[JR���4��������[g�D�*&��r҆�3�8A |���>�=�P�=pM��f,n/�_�2�ʇ�s⺍ʵ�U�|����(�F��"�'kg419�i��[_�?:��<�3Y�k�'�� ��������<as�]D�V�1+$&l�,ة$:࿗��*������2/_�m<�NU4j;�ƴ��?)`�/s��/X4T���V��8��i�ƙk�|.Pu˲)�Az/��A���m=��Fǅ�5+�$�[ÿ��p�b�C��n��,����E�o4h�$)܀)�����(���������m� �5��HoƎ�\�Ҋ�����_>�b��&�������[�&�.,����u���sc$��I�	@=:7�a9�־�{��	���6WtD��Qdy�n	/L\�$k.gCm�(Jk��-W�<'c��\�*q����Sp��BS!&7����`��p+5��R��z�g��ח�S���|�q�u(��G(u���w����Z�ەag��/�OS�rOx��")��ʈ�ۈQd�a)_�p��{��
����G�f"�Gx*W�l����pP�F��4��<6�!�;r�.�^���˛���l}w%f�cb��[w�7S�'ݽTՙ�Y�S����P1��I��{*ak��$7�V�趴kH��S
Zx��!�Rr� u�U�H��0ў��S���Y��hz�~�xv����!�M:8I2����}��Q���y_b�ۄ/�O��"�L��y�&���DLC$����뼎��!��t�:��kǞ\S��̘�4�5H���Hw�T�;��>��KJ�_s-|;8w��$��d�lC,M��l�y:�fП�fe|=`H
@�)�G��_�D!�OL��&�B���+zz�^?��h�E�
��8�7\<,�O(z�R#>�����{X��}x���R��G �hC��}�T- ���@L�I�U�0��a�s��#1��dGu�j}|�yb���h6q���P��\녭O�{H�&�lw��=��!��8%�6ΆIkD�oQS�w5��"o;m�$���j�7��b ��@Ņ ����a��&G�?:�:�%'$���10X]P��<({xr�B�s�dob�k��4_��5���!�L��a!�n3H�ռ4
$�,���/��|���;O�:w�%�C|��v,|���x��Y��cL*�����ע���'!�>���d&�\�B�8�.9vQ,�o��[`����Y�{��r�$��J�<���d;x�-;��sg�K�����rt���t�˪�8l��8!$�1�!!�1_"�ٍZ�N�E](�lGGw�'�f��h�����GS���D��R����abd��r�i�߫,��D}�j�J}g�� @�_#�S?�}������N���fdkC,w�EƉ�c׀�^ ���}4�n�k�)�Q�!�mɮ���ò��1V@b�� ը��":^���ʔ���k\F�����(�0�8+�� y)L&E���`��S����wI��p=Dj��gV-_ΝM:�u3<z�ί��v?�MS}L$�˕��g��?ǯ ?sjh���,�#ZlFۜ�d������a��@���IJ�b�#yb�o��yD1���)$����o��@�[6'Ac
���D�s��f���;`30��"����`˖Y��j��:u�»��8�ul���-��j���-3f�3ۊ<M����sK�=���G<ht���G%��BK-[��o�W�Đ�*H+-��M��U���� �¹���j;�h���R|�-�IHi%~ר�<��GGM���(n�a�hby�8��(�x�#�e� ��d�(=S�v)}��SwE���7U>��;���V�Xup�U�[��g�M��L�R-F���:�e�Q�NUB�myN3�����CP����"��0LD 7�ϞXox�r��`���/�װ�C�� ���5��Kx�.%�Y�8�4�C�G���9��k����1)��NVAT��#�^��G+��#���q盗�����+ʺ2FY#������S?N�	M�2�� ��Ѿ��ʰ��4q~*ŕ����C/�I�\����(#�M��FB��_���K⵭���jm(_RU� ���_F�f3��J�q���}W���~b-ˋ��� [*q������%���]Q���m���M��z�&�X��`����E,9��wv���d���r�p�w��Q|#�N�� ,�,�sߒ��e���6�6�ԋ��7 ��*}��R:�F0���7���e$�	���l�2�(�����6���ܙ��E_�����9ψbvz��u����������丳TǛFPݦ���������?�!T}�Ĩ���ѩ��!��������$�/���vg%L9�N)�L�1@I��N�B���˹�g+��gD#VQ��Z��0r��
������\!��͎O�,�>I���*)>�l�V���� ���P�3�� ���)v� �K�ر�{��&Uۡ;4�:q���t��n�>w���y ��ӑzs�H�1�w�+�r�e�1?Ҿ�E��ث��F�$�Z$�e���L.�����R�������8�-��4뙩�����G4��X����XJ���qC�TbN���R�^w�\�����z�gIyj�
�\N}�#���s	ܻ�84�3��͏ժXF�U�5��𦗑���:.�8�1�0����E*4��$����6C��A~.eiw|Q�'��}�����]ӣR]O�t:�{��&�W�ㅫ)��k �ҧ������`�[�A28�����t��`��ߠIg��`.��W�?{*���6�آ�Q��ܞg܃�6Q�,��QhOo�(�wI&�Ƨ�`W$�E�j V��ҙ�-6L�"�U��+�a�d�B� �k�$	���_��l|9h�+N~�=�67�ɥ�!�b#X�Os�7[E5�|͐H��N������Ԫ��|�X)2^�@W@O}��9���3l��9��%�����B�B�����|�U�� ���t<��{��T������n���~��R��/����2H���}��d��,Q_�hCbo7�"'�K��U$�h3v7=@U-��l5{��$� ��

$k��_f�~�ޏ��(1�fqk$���-���x�h*�	Ծ]�~�]V��V�y������:��-r5�����f�d�w��Ȉ-�G���A�_=��m3������,H�@�T�b�Y+������]�p%�>.[b�[��T�i,E�9��*Y�P�"z�q���*�Ƭ�y7�O�~�I�v�L2d��� K�^�͑�M��2U�WD���dm=�m��a�3���e�$�ٗ p��.�(��\!>%�8v(>4�vob�@��9v{x�|�b��؄.%0��P�(�cL��4�����7�tglԤ�;�$gz/a��l���G"�#!9}�ڬfY��v�3�z�Βs�[���	g�r��N8�a�춁K��y���h��e`Nsq[P�R��Sb	u?5��~�~-f��f���6���v��C��_�,Ɍ�s/\j�M|Q^+���9Q�A�h�L&�e�WAZ����6��*5�2@�s�Д�5�9���m1ji�%�J��;|�=�h���Q���I&l�I����I�
�M)�.z���2`K)
�8�{�4��μeg����d���泰y 'F��q�$W�,��7z8���{3�T�=EM~��pk�:�U�f #���Af�<r{��|����zQ��RJ,nӀ��O�qks�C�D�<cX윓\0��~X�d-V��[�>7u�p�Á݅�Ԏ6D�_J��]����m Ys�θ�֛po����gx`��lY��$i�=ݥ�L @�az@(L��Tf�T6�=��w���)�� n�O�R�ꢻ_��g.Է<rS�qЭ�a�z~�����.Q٥�a�,� ��x!"
8N�օ@C�Y�Gb/�I�S�5��<Z᳞!�����ٽ��$7�h��yw(͵��а�Uv�f����-�/��<�D��Y]^�^,M��X&�:QL�*�7����g�7���Hwq�T�����a	�|s��Z,.�����M�s���9˼�9�ҡ���m��_f�4�̧�NT�^�X\�X\׭�l9����Ec���_�=	��P����|7YV���й�Ū���#Ro���bNJ�#0�苆�I~�Y��z�~��YH��5
�7U�����7���l�aAB�W���pj�M�Ur#�d�S�ժh�M:��E�6�h���FjrX��t���u6W\e��dx<�B�`���h�����    Ul��2�Ar ������8��g�    YZ