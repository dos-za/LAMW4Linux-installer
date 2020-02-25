#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="233045781"
MD5="ca1ac37cce5621d656df011600252637"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20372"
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
	echo Date of packaging: Mon Feb 24 23:59:52 -03 2020
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
�7zXZ  �ִF !   �X���OQ] �}��JF���.���_j��`�V���/}0�ś�W�J�|���i�����v�oM�`��� ��1�����gV������WY���~J@���?QiŹ�̠�TN�;�\S i?>�p;>�f>��2�i��P ��U�+l����P��B� �����Z'��.Ke��YU��Fh���+�T7��,A,'?���L�g�#��+.#]7�{Xخ
I��愞w��ª9(�Ƚ5��ʫ�b�l�Y��2{"�8&QvDql��0�z?�B��"���O�����q]*5z�n�(w���
B�G�e�ꙹ�K���W��OpΪ�����'O����y�-3f'��99����6/,9��s#�"*5�lCc�p�$"�$:�l/f%��	�GG�.�ծwB�@Y��U��M�Q����)6���� $ח������R<Z�cT�)Je�_���X&%C��m��e�5���oF�7�0�W؂V>��K���Q����=��/��� �$��^����+G_�  �ã4�ٞ�rn&�_��X%G��Eƒl��N%�@�9�
��o�����'�*4��~@j"m2}0]�`�So$�M������d�>̄����dCI_��+?̑�+����Q�x�S%5��,w���X#>�H�>�E�tPg{(�|M��ꘃ����}�%6'!4mz)I�3ZEO��&�	=����[�3:�L��jW��1���[�iǚ��;A�C���U_�ʨƹ�bZ$w�(e����S�W�ߟ��pa���rY��,h�2�.|���#e�C$EA�8�$A��`�?��Ĥ��NW-|<1��޿ 9���nc~d�M����_(d;z�]�\"���Q%��qѽ([�
�� ��m�D�C�@2߬�z�/,��AE!�������4�8���b���$'\D�7�)O}ca-��k�����$�b�w#�.K�C��kF�^�C�i[���GLE'y~��R8��ɛ}���KM��qka��'y�V��3�h3�}Ѡ��G�D������3�8 dr����;A���0�|�|���~��?܉�P2x½�M� �۶�ٲQrj�?��4����G@���*amj`X4�� <c���BsHPB���������'�x�.x)���:\�,���x@�
����m�&ّ��l�F��̧�Qe�bN%RV� �
�ڍY����ȾJF��O�%y��݇�8E	�����_u��P+a<M�������F��~eK��}�C9DY�;�ص�8f୑,�oi$�.<2�e�5#{�N�v���'�J�5Oa��{�6�Y6���/�ӥF�\�X�P}f[y�B[;L�P+�ZXRm}�.��2�:k�΄�Y4�K.T���@pb(9ma͚�d""�;���0��r�%~�/�0� �k���~��R�#5i��X���N�ԁtJĆ�� *%���E^�n�!4��rƿÄ�jH��;��Y�E2Y?M��C��n�*�gp�{�h�q�=g�az�[�{߻�^�	O�j�C���m�K���Fj�'�59طЬ̪d�jY�X$�ALM�w��a7����`s��^蘸�t��6��؂h����Gurlԓߥ�6�t�M/�s63`�q=Q�%�U\ ��_>M.���2H?Ɖ��묷�����m�3��Z�����f�ӹd���<��h:����7Ol�3Ц�Ct�W��$����F�	Nc7#��o��LuO}�Eu�'?'!pf�a���L�C�İw���Xaю6c���>N�J05#̛se��0���("�=U�l����6S̊2���C���g끤F2J�ou�:���|1�ΑTt���i���~[�Iɒ��鵐�+O��jP�����|�,���t.�.���RXx��c݋���$塜�1�<�л�����r}í#<⁩`qN��1��:1`��
��h	�[v0���HN�n9T�r�4Gw���*=(�*���Sbz4i��w�Զ5B������!��"â=��$A�r=���ĥ-�������Ie9n�D����%���r/�G����*N�[NC�M��Bl����]����'6Ah�>g�u10F.�S@A?즁sjZ:�ߏ���
����5{��Z�C�@U�B�����������
�� �*�P�o�g04�;�핈�P�X���:RQs獥�$J���b��J,�'@���3F�"7~bn�IG�z�w3��!�ӳ!O�ۆ��M']��&�Z<�O���ی6�fh����(�ՌJ�hy�������c���l��T&���*����0H�\ɫ��!�Uh^�_Ϧ�p!j����鑞���v�"�9�"�+e������s���P�`�T�.�ڪ������"N#y��D�a�DnL�U��R�f���'�p�+�!.�j��,Ԍa��M���^�Tcn�Vu��#5���[��z��P�a�U��]���M�%t�u��Oy��2lU��ޫX	w�W���:�n�Y}=�	�q��hۃ�)O�H���勈	1�P��u݇D�4 a��\�M��JAOx�����8�W�3�8��"�7�|������K�6��V!g����'�L��K�Yޭ-���5{����B�A�>&��&�`?.>����q��x��3^c���B�r�P���i�"و��ՂC��Oc���Um{it�+=$�Uo#�2h�%2��Eʢ(�\y�y�-~�xW�K�7�h��6�"G��6�:�`cx�j��E�
������r��v���N)��n�C[&���F�t�G��g�q����᳆*�XE&��qp��s�+�![*�~=WL2>J~TF�m��Yp�!Vy̒Op7�m~l�y�>���;چ0��R�/YᒜE��'�zOG�p�{p��ܦt�mu��S�RX��U�~�b>��p�*`�a�e�kIo�Üxf/�FpA�B0#���;�λw�V֛�W�ST�m{��숔���jj~����E�ކghK|m���ZQ�ɮǿ��S��eR�.�Ѓ�Jr
c!A�e#e���.�%2��0^��E~��5|���B�(��uI��U�c#�+��KᚙМy�'��d��Hؗ�9��f8��619�Y�jk��M�`�^�9��EH��,Ӎ��5�K#hӬ��D�	�녪?Q��C�mg&���/��|*��1�a
���q�w�;������������!��%�~yZ �� �Li�H��:>��jGu�3uNv�q2�q�&/�p������%7d{�ʲ���G]�T�L�����ZY?n��}���w�~Y
XoN@T�9Ͽ�6ϻ*�0)XR>#�t�iPa"�%֍���G���6�-��UYCQ�׷dX>����w�Q%�Y�9v"����o�,b�<�F}*�Z���ѷ�5��L3�Ia�]�u���Ғ��h�xϜ�5[>�.?+��QTԩ������tc
"��/	�\����lO�����o�!�1�Bz$��R���3-O�D�-��
���t���aЮ�\�VXJ�)��޺�!��_�)�����;#T��~������uӇ|��z�/J	H7��)��.��l��0J��|ZC��כ;�~]�Ȏ�f*��B�]	��a<�a|�l�G�&��wX�qq	�'�����}��+�v����x?�6/�,>�J�B\%qd{ cI#�?�=�����cmC;��ۼd��7����3Gv�؈�n���h�P���ȇ��_�0^���42�m,��_4��f|�j�{�=G�28v��lg32~��0� �F靮K�G��2Q���Gk�koÉ����<�6�G�P_�@:��i�5�J�M�u�����gR�?w���o%����>*x9��2��棋��3+t�'��a9DY\��6��F�c،�H�_5NT�L
9��;�7z�'2�^�X1�����ŖP!������!���V�0��?/ct]@�,&�fÄ��1"@���d��%����v�&S6e锇�D�#������7X�m~�gas�s\�|��^�]_�#��}6�?�~�hm �Ae���A0�YC�K��w��{�߆��9�0F�� �*B F�}b6$lT6^�q�A���֗	�z�A;�$~c�k��5��Z�vJ�"[!�q~��u3Y�#��Y�؍N�Npe-Lt_;��Q�k��A~Y�h�����k�]�d!�v�����k<]g�O�ֻ���j��a�ⵝ>���9(�Wt�����6�9�R|#�w��׳�jC�q��eXq���-
ł/�u&�-#�$�]X�Y���*L�<�8��+�O�m��.��jN�R��r�u�c3s��L������D�g����Zp��̛�;o�9��,k@���8b������յ9J��<�d������T�����blz�Y�����L%�i-��y���Zw��GM�<�p�����r��5�562�x���a�_��^�	L��ޛ=ln���X�B�M.!����
����M�%̌|���-�i	�T%����ZG�:����ڴP���y��%˲��m�v���S�����n;���)�w��V�W��3$�4$(��<	C��c�h1�f��JG��k�<-�C�8J��0��B+�c�p-p�%#1=P��0n�Nv������eHN�j���w�	�ܷ�)9�?56�����i���Z��MF��IU���F��"{�b5�l�/�`$h�L� �+�Ja�!�부����q���
O[�Ic8ݼ[0$V۵nǐ�n��4����A��*bɩ%l>=�7Ҁ�pF��.�M�ň���zy`���<>ySͱܫ�A�}��ZAfNB�?^�ִ/�e����W��̹C;r���.���%ƴ<��IX����3�ϻ����2=ėt�$dH?���Z��o��<��ݜU�r�'$�d��4�x���+�m��4x�굓)��?eJ]�o�1�u� $�2U��C�09�8�rw��2��ʰ��y�(��7(�vr]�ѷ!�n~�	B�(rb������$� S�N����k.���p�R	���������z�3�"� �Jֱ��r�"Kl�{�x��R?!�*����xge��[#a�k���}�N)Ms�����GPF�7}3� 
�M���]*��>�ê��(tK��Y����̄�
%���F.kU,���Cw������-J�9�7�[\��xs;Ǆ�Dg+Hj�x�eo*Yy���%���PG)*^�Z�9Ő���q�X��R�~s�Ŋ/�p��s�n���]�=}>�2�̎O�̍�d	���N�T��G�ݤ0���&�%��/��=8�Q�y��F�w�MAqݘQR.��I�����Q��e�
�)HZ����INӪ�ɔ�:��y�2H��D]F#�KN���	��vP����bQ�'g�����U
�|�C�(>���9�����@�Z�G&� �O���h���5ǂ'����)CwUx���?�5yn��e8��P��Q�h H�&RL4���cu�G�y��~��a����Hx���ϰD �z���q]�yh@��]]�-ʄ�� \_O��C=�X����~�(S�;�Em/:�h��(��f����]7%���#{�7bO�S�����P������]�s�[gE�b�#7S��ه���5֯��|;K�uS���x�1��p݋�@<�*`ÉY��J.����q��*�(Bp(��J�/��d}�.\��G3+��+q��,V*��d�Cvs����?\�\!�Jᕒ��\$�d'���ѩK�׊?�>e�E�٬"P|�����F�7c&���Eׅ�A65*ꄏ�6�L^��˘?�j溧��'���Ӑw�X)�˴�7ff��sL����h3$t����ɱ%^]�����w�%*���@z����^E�^�4Ἤ�����e�g�<�H�[������]�K�C�t��0�a�u�Jy��Վ4ې��jO�y�E�BE]��;�G��3?� �b,<��������?L�~�w�����'-�h��YcG�IF4V�{�gճ�,����?!x�[7��
v==�V�n�_4HY��t,G ki8~���ҕ�*q�tr�8g_/�1��d	T�(�F�W����)�ه�a�w���4Y�`��*�m�̽<I85����Z̼�`7�C�S2T������S��e�|]��v[p���?\G��㏳-F��/2�r��7\=I1��V�m�4_�Q���z/�����mk9\����{q/�����|Q2�,�yR��(��)�w�?��k �.�'��Iq�޸��)z7	�:���N�1֢���~�������
�J"&��eG�G�8�a�W�L��k�}]IІV#e��������64ᨽ�vVY��}�"͢����y�ޠ��c���ܹ4�g�~Uy�!#���4V�'U�_�?}���g$G�����y��"뽪��w#ʬ��k��+R��0!8�9_2��Ү��`x#~��d�h))�.�j�Q�qo�7�tNӆXf1�O��)�)�8TKru N.H�3(���{x^�j�$r&�g��5it����7�Hp�#P����B�}���NZH���@�uN��:�6쎋	̢��V����b��;&�X���kn!����,�X��ߙ�b�Z
#)��]�-z�6Rי�ԙ�F��n6�H���˟%�b+[}�뇮���/:�X��BEP,�%s�͗�S�;,4/���@+j�]�	�p0��4t�/Y)Ց�=�О@�U��s�Y��͡c|�$�����i��m��MοXRXmG�u�gh�L�!��eD�m�Z��&~o�G2B�u)�=����g}�U�cE�DRf�oR��]�
M�\�ǿ�r�m|�9�Mj\>������7z��# ��_XW��=�>"�C+�4��W��d�؛"+!�e ַF�%i���t"�z�6�����f��E��q���T����n��_ŵ�\z��J�k��DEޓL8:��)dO�8f�u��> �p�qX�34��
gk�m�ȟ�t�.p��¹@It=�5�р]�����XןpJ3�o���Dm
���F};��`�Z�*�?/�؆��Ts�gLZIiлDT\��{G�Lr���q���)�퐑X �n'��=$�z�Π�����ŧ�T��e�����]xt@1��?�q�̛A}��(�w�L���h�{�����i{>�-	��@��C���tSD1>
�s�����`�LI޹;4�m�K9L��.𠂶 �њ2̞�(��L�		�)����/��_������Q����6{}�E�?�:9�Rje`�@��m�[��ُl�����7��x�ۍȑ�/D�����U��e��S�f��̝G���;0箺�hb�ӝ�΄#��4`W��GC���~��^��B�8:Em�U4��ٕ��/������+��-Io�Tt���B�Yzk�,܌��L�!��v�cف)	�OX���%D�/�FK!%o��^��4R��#IB[���&_�V���-G���F���Wűf우wv�kn�)y����҈��ajH�������>�.�-����_������k��ն��Te4kn�-؈L.�A��B�p�t�4�K(���]�k�����D2T�&��g�D�5�F3�#g~�rv&��������x��4Y�Ft��|F�ed�"&cS�1sRl�<V�x#��Z���	��R���G?�fu3���F���]m�����TؓW�E�К�l����c 71���s+3�p��'n���)�d������~��IbJ$�k�"y���ګGBǍ���Ӑ�����P���+S{YJ���-AC�46���
���!UP�.wH�o��ڂ�9�ٱh4����)�-e:طl/i�诗ztOk���#8���O�Q̊M��4h�O�.�c�trB��N������̯F��*(%�f���]�[w13��D����l��e�d9�� �h��jH�o�5��t�WpL`�m�'�J�=�'��@#���(Iu�x*�ឈ��_2�M��i���d������v7�8�ç\�򙗲*qO��TY��U��x��y��,<�ݬ��^�w׈���"D��6�p�����+
�Qߠ����-�r��F�{�@s0�l�Z~"����=��a�WN*Uz{$g��悷\�5�}E���Kb�lm�:킲7�r�}b�|��4�4!����m��{5	�M�3����J"��F�����ޢ�����_������u]�ۀe>��fd�%�g\pY��X{�	ZU��Ckkb
zj��W��D��w�	�h?�x�Kfa3�9����E���ࢁ��m��bY.
<��	�3�O�o�����/��=r��
�mc�u�Z_�U��5�|J�,5�Η{�����#�RC����G�!���NRG��5}I��7��c"N�5nhs��NS)ެ"S���V�l��-�Ƶ���'��G+�֨����W��H�,\������h_�Qn��k���I�HI���gV�vw����bH
m4M>��Ћ7�sĥ��r����sZU��#����$AJ!<�cX��$t~=˯>�&=7����%��3�"J�.�3a�qk����=zb��A=�u�q���aB=	%<[�h��L<?"3W��z�8i��n�ݺEl�s�B�| ���9��_(,EB��Nn����0b�V�;���Ƭ���������b1[�ZK��X��3��P�[[0P]��-ti�fK����Z�Q�!Py����r�S�ƴ#�h%�ז|ڕ-�BO�!�㜖���Z��T�L^�N�G<�2�,�}�LE��mU�ѫί࿄N�Mcs1:*u���@�����tdс�+��?�,R-`>ӽVSZw!�YW]��&(�4�dp���\n��3����SXXbJe+�6>W=W�?ޖ�e��.�����ٜ>ct�|�dӂ���=��;��k��}�Tw\��"�l�J�P��vNV�$�IvB�'ut*�c(��x˺�aˑ�^T8��w�Xn{9	4�Z�D)"�%B�y-@�Xޅ�H�dtȪx7�`�>"��ެ���{��}�8��@@�c��t�:�l]����o�-
�A�v��3��Y���d�f�͕������,���s��[��3�k,�_ON����2}ʛ��?�{W�,��4�v������.q�}$���v�\%/�B����Ғ�ֻ%v�=��?��p�!��#�v��?����+rŎ
�:�
VNTj*a�{�A�'��;$���Rkb����V�;��H�UU���c�.7*��FL덠�E߉��Ț�2&�D�(��ka�Z>^"��&�^�#H���^i����WU��D��bo�@��-�4UЗ�(uG�> 'hHd ��w�R����X+�2�%���ӗ�E�p�DZ��Uz�]������TyGe�̟�(��o;3��hy�n�Pgឹ�_����V��&��Þ���]��c�*���D��f�g�!Ly|�����~�̤C7>'�|;^^H�T����o�v-%|{ΏQ#�i�WhENj 7j^��\��y�?>���}psZ�/�F���Ţ=5��=�P ��k��Y�F�J�-佂ݶ,��]��I��H���{ņR-_���T8u�vk�9�2�VRT��8o$��H�&9�'g�n�:�6�{W
�S�#e��|��U�W��p晴�ɓ����g�'�7l8z��?��Fc:\�Ao[k��{�h|G�Jk�m.�s�t
�b�`�֗&���+`N�?# �ɛ�s�R$�����7�=� ����?��e��2FܯP���Q�ᚙqXF;�q��F���p�� ����a0h�<�g�Hd���9=��ޓ�-ZD�&$`ż�w��TI.�ïq�X�d�Xc�dו�X�I��,�H��Jv�E.y9;p[�Z�,S���;���(bQK߬����ǂ>�Ĝ�ҤIT�JR��l�y��o�`x��E�]\>a�/$�+u�=�����T�0�G�>�!i����wu�)�d�y܍���b�|K<���P*G��|br�A�0[/k��:7��O��Ħ%�լ�+j�+#��8��O�[5�e0]r�t�|)Uw/�Z���	�5��ǔR���Rldt�#��_�����`�����8���'����)ˑ �1E
����-���gu���s"*��*۹�6E�;��Y����}a��8ُ��t?���p��d7�U�8|T��O
$(%� �8���0�
�2{����,J��#�/���L���90�>�|�֤(��^��*����]��C��7�m�A��2>�$���K�8��d�V�H�z�G�n��4���P�b�^���W�"G��3�淾��,ӥ�����>�(����U�x�$��Ƣ��`5E���.�O��t��0��4'E�t�D�H�ͭN�|�8�ܜu�OyCI���W�h0z
�����0�E)Sx�9����[���:�IO_�Mc=����~�g͔F��.��*7�7��S��@e�o��<jj��(�E��Wq�k<�9}��R������(��
rGo��ƈ�j� ��O5e�=��"�u�I�k�؟�?/���r��5^0��=VsaR��c6B6�D���KA������Q��M޸e�[����֙�ǦX�]Et�;�;ݵce(���|c����Ә�FH����Ӓa��_Y��Á�8�ŴS����ޠ�,����+����ˣ0��jKh�f�����F`6�vSI����8Ni�:%���3o�!$�ַ�g|�RR���&����£�� 2<y\�#�|Z�]��A;�JF����ݽo(�Sگ���a�灤-(p⚣/]����[�S���c��ʞo1�pH�W[ɚPH��~�/��,�I2�/k��
c��y�[Vt����a&���fD���O���g���MY�G\�qs3��m+���I���n��&����:Q�[r������wU\��>��2{2��I˅�����S�n�W�9�|��b׃��˿A�:�9tȚ#ך|ج�+��ܼ7ѓ
.:�?��]��.P���g�@Y�z������`�rU:k+���6}���稧K��I���w��^;֢P�U�Å���Ūl�gAxԗ[{/�&��D,i�7IA��Ք�}�C�)�4)Fd��"P�S�jÑp��F�Q���="�ŉ�^*xvb�F�&=Ʀ�}��z���	M):�as�����\��zH�p��5� ���L^F��%A��V����Wv?j��c���p̹>1,}ʘ&a�}j�X\*|ǫ'˔�#X��_�Ym�	/u.�KnH�k�u�Z������`Ç��s���3
�$�\	#�P{S#.��9�&���Fó$���v�Gn'�xQ<~-t�D����/���-��i�a�;�>xJ|�y�hB��z��i���<��F�B�{"g��Ӻ���M���R6mرHsEDDˋ3&A������c�+��=�g|��fS��C�4.�O�Ԟ|�=S���G�0���^�p�j�+�`(�O����NM��x�ens��c�\�h:ݫs�x��/�4�-�� G-׆��"�v���lU�R�ϯ��N��y���#��b���K�s%��OH�9�1_�9Ҁ[^᭼m�������3�ż�Σ�����鎧˛e�S�꼸��.����(�CB�JAk�� d�0�P ~�!��O����-״ndk��D����<@��4f̲^���͸3�A���M�"���F���tt��i��&����(6���«ϡ)u�[meNW&�s?�]��[�d{z�>� �.�v�v+�.c�S�u�?�����-�W�qTK���j���(�mb`�Ⱦ��&=�k{#xkRI$������:ߐ�c��ɹ�'��E�����o��r_���&G��@�g�)	/��#���`�D-���B/|�I����z]��ӓ�Zt��R��.}����f'�C�?�%�G�pхW���H`��l�߰�Q��c�Gc'U����ρ���z]~��K���w�������l�f\�����#$�X�<T��^�ڹ���4�sr��=��$	��%
��Ɍ�ۃ'-dyZ܌���Ά���<��w�T�MJ�5t�Fq���������4�WR���	'V�ŵ�BF�Mn��Bj�󖭮��b6%�D��&);��ٴ�-��8�������cN$�Z"�.iI��8�I��_�΢wsg1�';T�=��{���o��@\�}�k�T^�ErrEy�E����k\ut�i���i�4G����4p�c;Ś���JKa��R������2_�%v�j[f��+��RE�:��"d�0�|DF%5d{���?�3k������dG�Ϣ��D���R�/���$5�b' ���h��;30?�yO���p�`��+��0}&�i�P)kT�k����UF�4��hJ�� Lլ�<"�� $KO��F�]���Fd|r���?�=w�k�%��%� �G�!^��#y����hI�F�f��]��U��5$�ɩ7��檨0w���w�Bzܻ<� �x�GK�	G�f��A]�Q�L8� �B���[|H/�}��6aS�����h8�e�"o�V�W>cK&���~}=�W�����Y_^��:�6W�T�wz�u+L�_${.4��OmmS�4�#fM%��hjB�s��NL0�t��R9&=��ᮧ��'�FM)�� ��b�%G��c��
c
+�8C&� S����K:aa�m���J�;Az���-�39?�E8\����Lc�jA~���Ϙ��){WU�ul�����rl�0��(l���s�HlYDX3g�6�J�4%�m�T+�y㰺��F���*�j�;��:˫������L�.�X�v�<��H(.��n��M&ζ���g݋�'��o���K�U�r�K[5�̆j�~���a��o���t�$�?J Y0�5v׿�f�f.TIj�l-��b\���?��:���e`7��l���`�}=��q�#���k⋓z#[��3�jge��L ?dIsW��>�H_���md�kL/ ��t���b��K�����y�РZwf�NK��B!��mә���;`SXR�K��w����5q\���./UUӢ�����{����?����6E.���T�M��5�u�A+�2�Jw����ֆ���c�f�fiM���tC��=���	z�*k�K�mu	QXt��] �����КnJ�0�&��n�r��/�lIZ�i�,y"خ�[p�w�K�~_� K���\e��^��zl}�o'9E�B���iXbPC��Ny�/jw���U�s���z�K�k�S���rlG�cm���.�n5��9��o�3FV��	�E:lC>���/�L!�x�T��Tq8�K�A�=M;=��]*�v߇��T����0�s�i���۟�	c�Ĵ�y�0W����	vղn.I~�*�+mg��^D��G<:��#A8��|�����غ�5��$�z��0���r1��m�M� *Q)�S���]e��@������k�)7�Fǲ�{�73�D1M��XŔ$#�lzb����=�o�@�Yj·�Q�IX�Ж�4�c���}r˄�I�X>�R=��`���	�.+r�q'5����a��']�ǂ���y{o���)�u����rn^(h�<=��K��PG�E����y��v9�9>��gJZkq2�H�d	|�����6���4�L�M����iנ��Bpdl̾��
X�)n}k�#5��8O&�������y�G��U��&�N
��H�����__��]�W��-j8R�?z�7O�sB�+��;�1I��_r~�Ca�M�l��A���-LC�F�'�&��
����U� �8zwӂ1��x��Pf�"z���R#��׻0y"�p,� �sЧ�t�zI��E1N�v�5F���H�~�tޫr��ޘBa�����{��4Yܥ�<��h�Q�?\J�!�> �
�z��%8�K�7B���, ��j��^yڷ'cl��8@_A'���[1��B'O�h���!�CSFB��]H�Q�^w�����97�` �$����~�{�4�݃��4��E�h~�0X��.7�${y0�s���1x��	Rb��)��	H�G��:����ڗ�ܧ����i+�9������;W���6Y�LuH���Ft��8M���K�9��<KΑ��0��x1�ж�٨�}�67%��_�U-?�u:/�mɁ������x�n &�0��h��r��M�<��jy��
�I��oA����=F�m<���h���F����}�B���l`/���Lƅ�t�smEd����m��F�o{�*��t��|�����a�2<-#`��h���C�c�|R�S�N54|sv�@�Wa`M��8��]|.�R�\"Y��Z�0���gϱ���,U�x�W�͓(��b� 
)���4�j폼i[E�҂Kqǟ��sjC��z���}����|��zUga��j�|�־�Va4�;>��.LVv�=��>�|9�u��2�K��M��F�-��3[ŋ0�)��z��u�����v����8A�OqM���ŝN��j�$��,��F,zI�Uz@��^<F5�6Cµ�����z�*�Ԯ�[)�9Ip��6���J����+
�m��s$O\�?��ߤl8%��]���yYO4;���,}*�ja}�6O��C��cF��{#m�> ����6���z��w����泬��Z�d�|�SP�#^���`v���b�%�(/��/�>6-#����4�]>X^0�ؤ!pn�_����
�yH�Wу��w����%�+�Ϝh,�,�`�LI���5N�~kn�Fb �w��Z�m��lB$&�ݘ+w��*���)|M�%�C�m�$g����&�r���'�$d���5=��@�h �d�i/�T;5��E��4-n0��E�����e�X��a.�
3~^6Bȁ�>�ha&��V�� ��F�W�wB�VKF��ϲ����������˖j�u�FSb��2�X\� �d�SJ��Q�V&�w�7�̬�&���#��I/x[�����d\A-V0b/Yy�S���de����=&$!nWʉȆs�8�� �4���a;��g}Ml��K���x��� +L��: ��Ě��:��|��&�f8�������~B�LA�Qa����\� ����-K!����-����)�,e�^]<Ε�#-:&��x�9r�n��}[�:n���p�P�2�E~���n*����!�#[�G�b/Ͽ����,��X��B��ZQ�K��v��2���@{J�G~&��������*2��Ќ��+���	'�ӽѷ�<Z1X�4��Ƿ[y�^��f,Yf��ߘ�"��2ύ�\�L�u���^�N6UC��w3�l��AO�uiM,4	�~x���\�z"��e;��c"��2�$x*���$^��Q>�O�������p�G���=���X�89���k����Ɋ��&?i(��헥u��d�kw1;��	0�h/�g�3���a0cpwF�[�֖�z�tz�,�|�4�N<��%4�
��.(U?�N��#7uW-� ����pR���P�bc�~�#��&MHȫ���@q�+\��-���p��G'��>�p�Đ���9���+a�in�e�2h|��d0�r(7Е|q!�B���n������t����ߥIˆ_��]1f+�����yH�&�'�v�#"�$��7
�U!{>j�z�����|#���=׼G�H��m!��ϴO��i�~����F���;���;����.r��hr���A�z�����:a��ފ�d�%��9�+C�m<�CW�OnN�TbKm8.YN�j"?*k#�\���~�eV&�1�.�ܚP����`�Z���RC�|}�f2��p�dy��lM�U�ta���hq*E��� T7�q)�_-��ݍJ�������F.���xle�A��h��pp�� M��Dg ��ɚ0q��}nh4��R���hs&cON`y|�?.w>���2���݁�K����N�-#j��n�E�B%����.i� ���0�%�:�JE(���u�r��@aB�!P~9��s���q'����Ha�F�-U�o|�����Hӈ6��9��C�o%�dEݓ��ґ�<�;L� [���W�.����d�m�����Fʩ�8����il�����D�\�[����à��wu��yl�h��9(ǳ��+d_D���CY��]�D���. �z8F��bu-��u�5�BA�����	e����EXeNo1�)W�^1|4j�p����~
q�ֲ�`�fH	�t*-po1*�3�q� ��,p��ev �J�??�T���qZPl�3�#�-��@�G�;��O�Z�o:�/�}���qM��,�I��+e�uɋ�;�b�Ҥ���E���_m������z�3?�0�Ŝ�U��M��1o�~�%;����D+�e+X�ӫ�m���Z��>�}G�P$���a��{��%�5��bT!�[#%-B��� ·�'��L�2�%xJ�[���x�86�����\a�44	_,ne���@���c/d��C�iZy	�3=����9��F���1gᖌ0�أ��o�>H�$nv࿐��q��*42���a�������
9! W�u��}��4��O��d�fK��ޕʄ6�h�� �����\az����UGhLp�a�v�Aѵ(�Bp�D�V�<),���^�9�	����펙,@1��9�n�@��<{����P�Z��0-7�������� hB��ZVҫ,���{��g��S㆜M��R���.0ˉ�|�(�]|�zR�3��Kfv�SJ�&�U��GWc�B�޿ӱ�6���P>=�^�W~���u����B��fw!OyG�x\.���
Ro�u���"��z]LA# �di�ug.��Ji16�`�!�6f�E�`�B�W)��L^Y7�20^t�w[!�QF��n�:B���}�E��e�gh
����~�͓���l	�/s��]���)���ƨ-�N�}?8Q5�e��穒n=���R
�KR�p�ב�(��,�%�������V	ot!�I(����>?XH��?�٣��&#��$��u���Ns�V�?{�$Զt���O0��EE=�=�k<Y����э��,�����?��ho"�$>?H�v�b0=��p�3 :�<L㷍-l(ߝ�z!�#,��6���l`��A ��o�m*� x�`�AY�9�!��C[g teGRˮ�m��Pa��J��dE\���Av������l��\X�s������Ǡ�N�zR��aZ�3W�:<I��r ����g8 5��Ͽ��|�yΰ-@f;:�;�H�O�ބ�T�Z���YͲ�c��+��ҵ�8����X�=�g�U����g/�~���8|I�˲d�G%i�D�G�L�Qdꗠ���j�FE�s��
H'�)R��l4�,��̔abL��Ǣ��D3�S�Z�t���]s��F6�޶J
NQͫ>CN���|�Ӱ���Ģ}������lB��'V��:� z�x��^�?����WQ����@��g�e�s��ޗ���3�;}VY;��䯮%���3f#֞X���)8s^�Ɓ�;��A���gq7��Q Z�P��>d�l[ŠL[�4�9#�|u�6�; S-�9I��1>�ç���zȢ~���l#�����)9�^���bf��a��)[��p/��n=�6�z�-َ��I�-��z(�?��AT�h�qw$��$3��s}��2��26m=&;k��x,#n�^��m�E1���GJ-�� we�������`�݊&���&%YTV$�4�D�o���"��IDoy9u�j��-) ����� �ҟ�s#���L����B�1�� �П!Jn�\�H-.˨�&��F��E���'�"aN��qx"�
�T�d�S�Z��Hڥ����Fʉy��t�f�	�k!�%��;f�=�
�?o�K�#q����Z^��e�4��۰��$ӆ��(1t���8�p�G��������48<l�xKJ߽+�$��+�@�f�в�ݪ� >}��
�.�8��:f<7u��Ռ��;�R7������-%]c�FJ���?��^�c�qQA](��龲4�0��onSC�~y���n'�o����~�b$�"����n��u���,�p؋ϸc1�4��zFuh
��4-�$��z�+������ͱ+�i�f��cT4�b��a��]vk#���V<��T�����lN�[���	�2���7F���§��˸F��E	���&}�=��{�PrƋ��O��������o \�hR���:8�1�� �8��{n|�0����[5��!r'�W-^WE�(��%�y�	������(&nL��iI�t�U�TK���>77��bI������qi�O&*D,Q��j����_."�{~�:jAs�Q�y�ODzJH�/V#^� ����QłO�>�,RE]^��aԇ�5�Z�0�/J{o����Ԛ����	���%�J�ތ_a{:�焲Tl�Qb'A�(K�V	�K�����ړu�u[¢��.퐖:�������Юi͂��(�\��Z���{a�kH�h��?nr�ш�㣓3R��?�L�`D��(�R��;��ɚe��������Zu��`\�Me�̝���uCr���$-�0���Pت5\�m�m�f�l��-�i�̜ҏ3�ՙy�+��1��O�@�`��su��;��w=��=5څ�@	O�˼^^� M��z������@���O�����,F_Qΰ�&��*�-����e�Qt��旸q�n�ĝ�,���7�<�t���X~���'�ȿa�!�4�i�W|���'�ة��A�=�_E6^P��\�v���3����Nh��!�Hxpx���I�c2TEP���^p�0��=Y��N���+»AxE�^p�H�|�h���^PjGA���o�D�S9�f���Ҝ�)iӲ*?�����
��\
��F$#�.AY&���a����� �E�7@���Ld2T�
POJ2��9���ck�B����Ak�,��O͜o���<�+CE�`ں���00�I��"�G�v�Ff԰Һ�ї��G�OչH���KK��>���������<�יִdg����X���� �.��JNE4Y�ΰ�T��D���c�:>���1E�-EY�k|�Ӝ�t�������ڻ؂�'o����%v��Ȃͣq򿣯�]����UȠ�G�W�𲑩���y�C<⸳mF���:���Q���	��=f9V��]Q(��2#��`��Pa�����[��qB�ru�,F����镠��i-x2�Y4�rp;���1�Z5�~eC�qD2L��I�aT��>��[5�O���B�����г��eN�R�u
�V���BW�uwF��T�g���2-ˌZ���cn�1[A�?:F4�?�{�����f8���۔0��UKn����D��;�_.��sc)�#�#�7ފ�����ag�&���z�hZgq��>Z&/��������;ď1�"ȍ�O_֌�[`�����i[���`d���RI~H�iڊ�h ��,l����k��\����ѿ���*p�µ�N|�I4g�mu�����-���̗�C
�`�nK\ N���PSe,ܝ��ΈMe��}��U�S}����X&�B�q��Լ7�����h�m�(
��c�����$�	`J�}�=��
����"iW��N�d�=䘢�K�Mj!�^�7�
TI7�=�x�oA~�)ɋrB\�B�<i�D��N�7.�A��i��w|T�{���	&�
]�*���s�ֆױ��h�@��s��8���T�$��     E_��]�x ���� T��g�    YZ