#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1033050163"
MD5="6e231816e42fa41473e0151db2f71375"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20972"
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
	echo Date of packaging: Fri Feb  5 20:04:34 -03 2021
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
�7zXZ  �ִF !   �X���Q�] �}��1Dd]����P�t�F��n�����jw��Q#�q�@�e��V֞�Hul���t�-<<�k:�	��q����R/5��^�ҩ��)ŷ�hh��*�C��G�n���'���W3z~ӂ�1;ԴG� d�:�.O���>�پ2x�V�1���`�����߄�m�@E�h�2��I��Ǥ+��UgMV�4���B���m8WfS4���ȕN�[���'1<5�(�0��;��ʑ"-�>��}�᷀�7��f%�U�5'Z��c��o�)�K,TMD�S1}`�\3�.i3��Fp/1o�c/�J�	q7�M�4��7m�&@-����ֺ���-�kV�����~�R��ĭ�3��Y��6�S��#V<�tCGQM��� �.ms����n��H�b=]K�+)�IEO�Z�2�B�=�*6i2�Y�!��M�C�_����q+����}��ٶp�� �H��qv�j�4ؠP4��Gqaz���8�r��!s���8*�8��Ԝ�����c�Q���^ �����'Q���y~"#,�>�WB�^����O��A��j�!u'mU'�����+i��u1�rO�VR�p�+5�X3Q�;] �E^�' ��Ⱦ\��B_��0�Ջ__�� �;�|�	%�,!a�FlN��/��K��?�;���obk��z������7�^1[�;p|drhMТ�,�a4�P�AfHn���0���a=
S�~�s��G�yZ������{���� ���υ�-��w�s�P{E���E�Y���;���F�@��h�t2e#�Z��a^Ԥ~|M赜���b�;i����L��I�޿�\���<jn-w�6{��!�ݜk����zBr���b"8�j4�wj�^���UL����+�r��S���ڄs2Z�vp�\��������K{�[S�d�������Ea�h߂밿։���m)Ѿ0T<��Y�����z!7v�[��>%��&����iL�*���(��7E�Fa������ ��)��Od�3l�E�ڀ$����4�Z!m�J#��R���Dl�D���}\U)���0J��%��|,��Ē�н,��V���O��L_N��v���RU��#���2����]GP��g
͹���F�H�h���� �j31�J�;8'k
�nZ��&��&�&�3߭q����v�jȕ[W�;k�@�*���V�}�FAA��W���G�{۬>��N�E�d9vpK���D�R��������q9q�;�X���2I;��:��i�24�Z�Z��|�m난���
�Po��l�_d����"�U[�P�[�D���q�L���H!��T)H�p��]w�?�4���*x��d���
�9�XB-��O�!��S����Ft��;�~�i�k�f6�9~̹��u4.�-L����� /xv,�WbZh@A�OK�	Ɖ�>��X֗���39(����.	f�.t[Q�[��PZ�`�r�|�y(�{j_+��q�����?_I���QQ��w�����ه;+)���}�yn����jP���kkF��wl��9��F:�̖UP��I=߈ʴ�A���鸋I�$�I��`��o�#Y�t�������c�_h��sM^.C�v����&��|���W�,���/#��Xv��H?��;��I�ʒ�pՐ�4lgj5��k�& �Ev�d�w���7F���@���-(c7���e>W�ϳ���d�<:j�RKa9�&�W�L`L3���,2��7��)o�j�N�XW���Y�'L���v����U� 宸J.e8�b�bua�q���X6I���a�X��U���A��-��<C .[���˓�:5h��0�.
/95 �ݭ�\p��:wO;�:E��p���V�DMz��&X���d���dk���(>k͗cM��=�޹�Wxs�O�u�\,X)+�w�8V�8O�X^��Tx�_|�ii�.����Z��1�f�������un|�U]�b�#��"�j��r����3�+K����.���O�.����2P�=c}�P��̴bE�����
a%Q14 s����'*슡��2�5o��൫��Q�|�	ԅ�6�������RU�a���$6Uo�T���fj��9����cj��3dԈ�уR�UJ\xF��b���A�|�|�+<�S�Y���?�N�N��Óf'��̯�jW3��*�߆�h���.a,�� ��dq��[Rf%oy�j}�|jfoQ�p:WBw�6:�6iс�B4��m���9|V�-�[SX�;J<��x�����a��ˤś$�c>c�
v�aua��}�
��g�8�f�c�F!�#�o9p�t��hl�>y��uX�܄	Uq�ȇ&�A>֛^/�Q~p|$Hun"�[:J�do���D�a��)-R�B��+N!�����;��ޅ�%�8apҘ��g�f#�z)�<�bP&D�ƩeZ�c�HeY��p$c���%�>��VR32��س�G#��NR�ǧ��N�����f��0ˠ=��j�R|ޘ-D͍������pm3�z��G�߱)�kVJ��驶i9:����F��yG����$(�����������x,�P�c�x�D�Sa//+;�eb������T�t�8�s}g`M���y�°����G.[X0Q9nl�3�W'��Mpy2�9ih��6��V�Fcl�`�7JSo����,851Xx�����_���w������I�\5>����q�>YZ
���II��@]�Ő�ܰ�(l��Z0����d�SC������Z�j�i��ޒK�'@�s�B% ��G6��';���ҁR�L�B-H����[��h������?J�Fx���5\�9��-w��Q�r�s0�%D��\�!��><�dq$R+�%��#�93��#. Zq=�f�x��Y^�S\�!�Ьǭ���\Z4Lm��}��˞c��k��:��V�mP�l�Щ"dB�Z.���v�ĸl��-h�.��	�C�@����xKl��=͟>t�=�ܞ�Ҷ=��X)_؞�����D���p�a�3>���R�-�ge��Ib%<8�V�A����HHl��"g�8��N�S��5K�+�'r׹�#Q4H69��c-�h���>����H�����]c<7oɟH�yg ��8�t��x�fLvMz�خ7T=/=�d'�X�.�6�$�pr�xѿ��"�^���1�ߡ�C�=W%��s��͸��T�����A�}����3�Si��6�wd���}�/���e=�,�CJ�&�{xWB�t[g
:�t�׳a�1y���I��Y�HYر(pA8���M�v����%�0-�ݤ�%v"4p��,�)���8�M �8'g�m��=!l�s(�`���t���:�����֊�I0�O��_P61v�w�o�B�#��W:��fŰ�ۑiM|`:7�$�(��x���k5���F"�����:k�@9Ͷ��A��-�R=��R�0�b�Y�H,�BcZ��&\/�,9��(F��<#@1��q�^���T�zD�7�c����*^����^F��%�>_w��/��J���垩�&�Fy�c�	>�{����2�������If+�������l�r�	���`���ߘ�������R�4�!��M��ϑ�	��d����p�I�\�VCchX��>*� T�e= ��OŎ�q~V5a<�q�~�oX_2�$��y����̃�m��c�Y	#}���}����'���3��'Q�AE��衞Y�wr�P�׊qõ���!��TUVi6�)'~�e�M�:Z��̚��X���}��ޝ`��r�|��ŷ�� �˼�W�:���,�ӏ#:�\��}f�@�TH�� �Fk�y�kr�"��Wʂ%?
0y)Z���:lz�0�ܴ +��z�	f~'�՘���{��{k���Du�cM	] t���������q�|�Qb�
r�C�w��]�L,w�2��j'4<����\�^�C+�M��"ss0ɓ�F�K&Lj��Rğ���nӂ����ixd*k������+�I����Lc�#*CaY�\�� �^��r`Ҥ��A��<�9|��B��P�DMl���oӕ'37PL��H�з��FY�����Tl���K*��l��g㲕�mK�+ ��7�~"TG��2PX�U,��`ӕ�U���qS����%՝z���l�ɗ�z����M]^��~ƄLW�/��=1�P`�͠f2�M"g08������;2���F��?��O�����kfϫu��m��IO�ht!c/1h��T�k/a���)(I�$�J���bִߟ�de���n�T:�ռ��CZ��^�����n=��U�3��58a}(�B��mj���`�w7��&�sRz/`Y\�Q�\�Wua���N�_`}E0�PA������i� ^R����p��v��P�E��s������(ٱui�v������Ҹ���K_��ڕ���f.5����&�u�!�y̠��w�CpDg�����F�1��߿N~Z�v��{�'� 3?� tKѣR9�r�4�R϶��)���p�<^�!��f��)��9졝�d�Q%���:QVza�[��$w�2�yvG_*!�y8h����Z*�Lg
L�㰓[�f�v�]�y4��J퇃���rq�����:�_i������ZQ��n�?�E�4\4�#p?+�e�8��=���q^�29 �sO�cW�=�"���'"Nn�&�y/��:%]�)����Fc6���᭕���>��M5G$�fv��5��E�ߑ�����pI�ޛ�m-�"$����CL�+���K��܊��J�4*�[�&�^�Y�}Y�P��f$Ue��&m���q�חq�*� h�#`C�@|�P�� (�Lq>	f��nY�W�5צ��'0��_	+�M���@
��E���Yŝy�?�1�޵a���|
-�����5�|U���J��y?����7!_�@���̗İ��C���
q�&�B�҈��ڍ��2\���k7{����.pnҫ�K	᫞�3 w� 
Z�����u�w-{���yduT�ՇR�9����F�Oߟ�3"c$�.>��"���І��{'��`�b��~�j/���F=��B�۾�2����3�ߠ�'/���b'�n��������m���S�r��Ǵ�6��̂�\0j�E�WG4-���T������[�^�JpE�ƍcZ�Q���Ӭ���x���,�)1;"�M�E;�웢�&�����g�Ȩ�;-�뜶u�tX��DR����vV���O=��M�$��\����g����A+�D���w�R�V*�D�|�?�uz���6_�� ^p�żJW��9��d�9�a�BP?c7���؛�����/�z@"�H�q?z�LF/lH�ܷq~0��oeP�Ơ�����.����'ZY	�O�=m��*c@3e�+KM�:�!�#����v����o1�V��L�cu'���/6W��q�Q �r4c�=�E�dIf��f���Ml�p���'���O�ۆ/�Y z�{{ȓ���88N�`�Y��7�4�v�D�%�E�7#Mx��ɼ��hʷ|���YH�ă��Lv�ąk�-d��^7�Ӵ��M��(O�~1�^ގZ��>Ou�(t<(�ǡG}@.zֳ�_� ��j�X��RF>Ɯ�h�!`���)�P:95³:=�QIֻc1�+�A,�c/Y<�M����<��dޯ��kq�R'?9=|g�"v��)_,o���ٟ|�I�$�u�j�<��#�Ʀ�D�����>O�U��r ��gg�&��#_ea�>N���QN��|�B�����@Cc@��*�r�|L�����b���ٯ��6�a�9�n����;�?�A.�U_qt��5��]�y�W��Ka��v��瑚8���~���Y3j��Q@`���	�2�*���/�B�C��xL�)���A���~| ���t|��XN�֒�P�^8����A!�6� !�O�I$�����|�:δ�����mK�ф�mBq�t����Z45���v����5�D�)u��$-X�;d��ʷb�3�[�롽w�MJ�[���^���1����3� �jn����n8%#'�`���N��f(����n�r���E@:��k�JN��o�ir����ח�m�#�>>�6�д�v2"�"4�ZB�8��v��t4��K��Ur+���������UQ�l���b
��Л��l�^|+O�۞"V&m�T�}Nm�^ܫߋ[�(�C�$���ũ8uK�!t.M��_b�C�>n���)�A�io��������܍�m�7�`1���$ ��	h
cʿ��0���vT*�G-�D�)+B_$���~?N櫹L�G�d�c#.\��\�+G"���g��9��L�C��W�\IOT�w���ټ�˗Jq��6Q��&�&�ix(�p��L��4��63�\`��zo�ވ��6��=0�����;�K������	�k��9�h�V̈́r&�ʝ���;�`���S�h
�V�Oߓ��a;����߻��;^��f���x�|���]i�@مe�3��s��%�?�z3���3�$�YO�_�/���[�x,ۄ 2?|�⻰lm�[� `�:-�'��>*Ag��;w<��P۩j�>���+�D�>�>�2Y1NnRt䜝䏐\0��k�/m�T
����8q[�[�P=6�����[�e�W�9�`ʂ�u+g/��d��x i��͘�;`U����#n"��,�����n1?8���*YB>�5T[6�쑻8��5j�f��O5�;�� �F�h�K-� ��jS1��x�3�q�$��m�wΚ��1vx���'x}�/�jlN�I��)|l+T�Is�ay?=�lO��G́)�u~?�{V�>��1V�û�/[I���T��i*-. �3�Rr�"F=X,����W	��E>���oL�{���2����/��]��J)�#Ê �6��ѹL��zB��v ���UX 䮋N�Uޗ�����"�;�fp�#2i K����j���T�g��F6�$U���B׺�u^(I����K��4R}���>;��!�>)¬i�sřb�V�M�}\[j������+r��&�W|�J�c-Ԓ3��C13|P'�.�t��1�Ԫ8��G�%߆�s;��,�@ć�D����3|�f����ބbc��)CB�l��$٫��Hp�\�*��I��QG��?�In{z�je�M^�R�-����c:[�����(�m�i�I%�^�p?�]3Պ&��@���u�E�G*��{�ğ�/nA�\ͩ�CL��S�b�9#)��N�������"c�>qPz�6��Q�no<�ؿ(H��!r���Y�����o�A&4K�38c��{�>�"VU���{)o�:Y���.���C��5��w~��{�N���gٌ�	7��I?ѻ�ޡ/�d󘄕�Zx�{V�8���JM)��m=��qׅSE0�(�-<sA�vX��q��DəM�l��lio�$&�����ƕ*ܫ�C'�Qx���E�߫j�Wz�bc��\?R���Z��.P�� `km	�~m���ɂ���:�	-�~��I'%�����ٰZ E�{�-�,�K�5��/�W��&p���/���1x*g�=I>~嶇F;T�9���!�`�/��0�WR�R��M ���oO��g���w(�����~�A��w�%�j�}ȍ.=;^���/I6|JFWN>�ejں��]5��`���k����oi��$t
	����R�^��1j2�� �v<�1�}�%���;W�Y����\9ߐ��}��4Xe>��
��T��_�^+��we_�����I�󋰅��F؇U9@�ң>rқ�05֮�����C�n��k��%D�6��M��n �Z"D���Bډ1MN�E���q����L~w�
�
�%4����81D6(��f�`�	#�L��%��į[�f�Ā�%{��jt��7�]*Z�þb�0]&\_���x��"���y��;�{_ɇ<�ngW���a �N�2�k1������O�۸�Z^��.â��A���|Q��T�)q0l���;�37G�t� \��^�؛��]�M�ݣ�1�r6���D�����`5�+��]�m}��Xj�����[R�=�(%D�؀Dć�N� �=��:����%+ME��4ڤ,���xa���1#��V��N+���uE�� Ȝ��إ��C)햨ܜ��O��a� Ė����C���m�Ͱ�Ut ��з51����:L�����g�B
J��3�D�, �w�؊)��s��2���-(��LK��WW�R��ěFz���v-s���kKq��mNK%c������� A(�Z���!���;���xom`ȥ߽#L�%�i{*�]�w3���z�L7UbzKB+���**(;m�>��HW��}?�ly�����҄�]��m'����bR�H3�H�M�<={3�0}-d�@��y��g4�'{vr���!M�@����|7���%�q���Y��F����Wj�Y&CA��<?^�v�f�4�A��I��ՃYBw��ٗ]u]�"g�\����$u9~k�V���dr?�Z�(t?���۶�&�Ґ��Hb@U}�V/`�6a��Ϟ��G��`���9�jIT�R��+oO�C�2����A�ػ��_�wl/n-]wK�Wf���iT�cٮ���n�?:h#��_��*)O�y`~|��!�ҕ���)�_�)�����H%�X��!�|:@�c4w�G��u[���hF���T&"n�Qw>�V�+Z`>���<���(��Ŧx/ E_Flm]��^�#���T�I1�%����sۂ-]���b�����k��f2���߃
�ʱʒ��hxy�֌��Ey�'_��E��	�w�`�x�{�_��M|wC��Xׄ*�$��R2�:3�AnΣ?�޳�*O�����&�F}Y}hf��s~68�K8U�Q�뷖Q��ᵺ"�qo�@��8��J�,�u�uøR��3
�"�~�I��B��(�l�d���W�Q8�j�v�xרPyT{�3P�~m/�h�q��z�82�i�{���4��'%.�YB_���C�L#��:vڦޕ6��#��z���&�6��I,�y��ߨ�axY\�����d���ћ1����̼t�6�o�^h	�8��9R�D�(�>����� y)J�ݦ�n�ϝYV����8f�Ez��#�7����/4i3�� �D��t�����$�M+e��%L�O>��g~���smB�oޭ�lչ��\���m����� ���T1��0�S&�E�Z�1�MCw'�������8cSS�yG�e9�Ei��H<��+r��(l2��目--ZyUFu@3ʉp_����FzK������lX�tݤ�hcZ�=(�|���meOj}N�L(S�g7i����/��������f[�H��Y��Tt�����I�$ԧD"R�����[F�����bU>W���Ƥ�Kw�Q���n�V&�6�*����h
��\mz�*��?D���P�6A������; ����,�TS�*���pr�6� j������g,I��#h���?u��`h#�g�a�F�Ľ�L~e|�ft�n3�RH�z����h�F4U���i�ѫeН����'��
��	Mh4G��!'qKL��"I�]��3�%#V�C=��p��,�[��	�:��z�j:<m��8�+-pa3X`��z��Z	�pWE�����%u��ҳ(�;�@����)�ܜX���H�.��y���t@�۞��m�k��8K��<F�9��C�%���*ؠ~�������>�6P�� }nᶜ$�H�Nϖ/���#Fs�����1���^k^����P;�ҫ/��d-]�Q�a#�R��l�!�	u=��f��<�>���]��[�o5'�"z.�.Xw��1ڭ|n���O	oá���fԘ�t|�Z��b���[�T ����8D����9k�7\��\�b
�A27�:�upYP��b[�v�ی+��[�{b
�)��}���7F�?2p�s��m9��>	�@Mؚ��%	�X�p�;e��6^�"��˶�1s`���H���H�v�(s|�cP�*v�'˧���4گ����Ş]�M��E�iK�����l�	$�ٚ��W�������+*�FՔE��yK�5E:W���g��ڢ��&�,{��X�KW��쎘M��bo�y�HL��]�N�V"դ���x��M�{����>�;���~�_gP�h���H���b㝴"���u{w6��yu����!�;ۘ���&���fH�6�Z��{���jW/�-�Ǥ������W���~m�|���/�"y��pG�@w���%�����C>cx��r����B�I6�����r�����0��F\�67%U���'\���~*<�O�o�e#$gW�آL!IN���7F]��B8��d�
h��k�a =˛ǭ�ǝB^�/����X�|� M;.?�}��>�h"���@�$1����yry`��{�It����JS�
>|k�޺�&��1��D��LȠ��H��9���H����^�UOb�7:f����=j�fκlD��<�@�h3Xו��/)����4)���Vzev�g��K���7,�3���e��QG��"���Y����6p�_P"�r�>Z��Z��ߧ��o��Q�̐<� �ʧ�{���V�OS�������b����$�v4R����������E�o�&?��� �_�b`�pWK����i(��c�A�u����&�߹@'v�V���R2�#rj���t�X<l!�����Q���J�Z#���XMx��%�x"�r.��_:M��Φ�S�P%Bv�j3��y�q����f�A�OqmH��L��zg�U�%j�4!(H{>%�����2�fk�ujTr�!�p��Y�h!P2ߠ��y9
��"�cPZ��:
��P�xOǇ��gڀ���ŨI7>�����n(��$���E�,��MjVZ��������Q������!b`s�gֶb����t��hp~�OG�<�]��mB�Ϙ�	��\,�h ��5e�x��jCP�gPęX2cv�+��H�p�{�ؔכ��M(���A��I�Ej��6�D�]�Z�����ޅ��U�"B����ж�����x�#�J�zЇaƍ���\�	�Ē����r%�79`��U��HFi5�Q̓��À�>��rr>W�RёTdt�ڞΦ\����Ј�H?��)9���Z�� �����K��|s��e�NH0/�S� v�e��]�c%�Lw���@��%&u�M�֪h���.m�pY���akQם����`}�#���������X᧞P�W!���9AB+�'��s/�v���;_
L-�F�g�m7L�N�u����(�^mx^ZN�M�]�A#=#;Ǿ{V;pY�������	�÷��Z�V�~pY4o�*zv�27��b$�(
��a��Y��C'~���?Yk/R^�����{��1`|�HP�^�_� �ay�B�l�jC0P��;ei�-;��jf��"����ܞ0~�N�)�%ʢ�,���O��1�����q<^��3��H�'��uϰ(c5���Jx��p��K�it�Aw0&�Ek?Su���w��:�ܮ��Ͳ{���y>�|��T�My�~��^��@$R��eS B�.�(�X�5�;���h��%��PH�,�ޝ�Il��ݐD[,��g�q���pP$�4��@RiN��_�$��������U��FO�1�"4F;وǬ(��cڢ���Z��rˁ:)U�&��+�����{�v�xs΃�]g����:p��n�5�:h+��z���*��͛�:?ҒЄl���U]��e;�����I�n \�� �h')�+�y#��p�&I:�vR�FP$W�R�� �yN�\�C�ڋ���7Ta��=V��f�u"+>~���SR"�Ͷ 
���)��U��-XB�&�Sp\���u�-\�\�[��B�Gd,[�9Ej��_�vSM,�'�ޞ��l~�\�g��iV�cKe����@-�u��{���.�=b��bw�v1��ʂ!�x3�������6O=��l�����P�q�9�Wq��2e��߅4��Z�1�蟔�	��[_�"숩��M��('Alϛ6T��.u�%����A�QS���Ҕ}�Ħk ��i�E��U�s`�U�f��X�u!Cj��������$���g��>�u֧�&��=��Z12*=*����in�I���Q��g��V�N���5#�)������G�%̟S���4�q\�)��	-~נ��
�d���#�b��뒬�p�A���Q���;g��5�T�d1�n�7�#J���2��#1��1|�dD8'�V ���v��֘"Gt'� >sD�_M\Ư�6���\fQv���.�Ӎ1)u����_��nk~m��/V��"�Zx��ڂ�oI���\�5F��W������n�����䢶�?� ��tFJ@�@�P}��4T��PN���:'���r[n{��U�n0�te�B�~��~�����������O�U׈ۣG����q���#�0u.���خ({Gw���9b�d[w������w�)(�1-�_� ����541�� =2=�AzI���S�W���B�^���3�����e���� ��]ᕈ@���0�%�6JP)|�����t��n�1�Zm�7
������FE�8� i���L�ES,J+ͲS*ㄲ����5�T���^v,�V�ۡg#UL��i���+l�y;��e�0����햼cŎĥ�����H��̷���n9�Ŷ*�ø2�]�ϕ[?��j�ţ����4��3W"9+0���[z��;ED�<���){=��u�/�B�6�&q�_���a�*����D��Z��b�>�1�w���������_X��׵�鎨苍�:_�,��c�uQh���:iϗ")�?.�m�PL�W����/z%U�Qr�w����f��eg�h���s({`S�A�LTȝ�\~x_���`��e,�{��v2���z:7�`7�z׬��Ι^�"��Н+�4�q(��I0ؠ�����y!�(+S�g��<p��te�S�@�ٕk������BLGrVy���C��п�. �f��;?�	}��i�Q��ƙ��i+p���X6:�t$�aXuϺr�,e��
��?="�ٱ��-�+ؐJ��֋�j�A-X�=0����kN�Ԃ%mD�T
:�pw����d��'r!?�0�� �W�f�_�6>q����m`�miU���)��N�u��W	&�'×�̡o?/��`�֧��fcY�c�MY�C�hb��>���+#���l@x?H�(|��|�U�gP_q�v�Ĥ��ԓ����c�xֻ��4`���s���q/�7퀩&H/�ɣ˃�#�xU��)���N��`�kO��VwA=�ݜȜ�Q@jP�)em�ˢw!��nw}�?��T�s��
j�R��<�_y��yd'���Xڰb�X�JWL�Tkz]p�?@�Vj����>�v4߷ˋ�VB�|��|��1K^ڞ_(rR����V�~0�yЦH8�k�]#o�64�=/M*zK">T��`�V��Ҫ�f����0���1a��-D]Q��_5�k������dr���1t�-v֤�+�76��[�zp�_�aS�g(��8��P�O�����W�tt��T[�vĿ;V��0J�~��Q�J�H�,u�V{��M앓����uMTqEbv(�֥�H��- S���x�uA1Ơ���$%���>b:��O�NK�F�%3�a��s>z��%uX�-�=[�XB��e��C��4� �qّ�1��B�B}���D�S-��,,6�gy���D#������C�r�<�]�>$�v(���C��A���iR�L�bY����,�=�>g�DW�(
e��Lb}]�#�sb�C���T��T`D�=̍O�m��2oU���ڥ��=�����~׸1�ޘ�Yty����^'J�Hz�%(�]Ί���i�S?����X���7�7���/��E�*�������Лd]"_�9d�qC#x�p�������&ע��˘��nO;v�)��P�g�)��	-h1���������{�#P�E�}ݽ�r�"��#od�Es5�OEsӇ�0�G�-�̔{��5�����K'�(5�*n`5����f.�R�޽���O=�k�k��ȗTS4\.>苏���Y��eV54Ŀ�+�4|.�nU��_ �/�����*�h!�I��^�)2x��R�!X#0A��,�^�x��K�9{�S�{�;�W�N�m��.�1*J"��bs�ї�C8��~��_;=W�]��'��)�pw��T�I__ޥ�C�����n��x�˜[O-�M��s���v�y_I�o�7اh\�Ȳ����*��VL���.1��E��S����N�|>���3�YC!c�eu��Y���Xw�j�k��|����c"�;��̟_E�?�s3��e�Q'�����������(�ژ���n���<�XBl~濚v|�;q��pȔ�)=�l��WR�t����	��ã&��To��Jq{��pǨ~2��Q���(��;�g��-���m5k��}8�3uu����lK��8^H~.�<��U���.��rSFR#b#��M^!��#�b�Waɨ9-Z�5N�AF6R�&�TX�w�|L��HHC5���0`^U?ϐ��a�M=�53���C&�{�1�>��s�7H	s��0s	e��t-A�Ś�VVa�l������,��#GG�Z��
-��2B=��YI�ӓ��O!/�q�;��9��m�CЃ@��t��hF.~���叵B0kh8������dM�6�C����Q�vQ�FN�*Wl�ۃ^3�����v�f�TW,B`�%�^l5�1]A�J:\Ԓ0ӈG�:���,KW�A�ϿsÇ�+��P7�������`��:�=M�]��+/��{|?R��m�;���5�������6���O.ZẺm���f����\�|�]1��8`r@��(8HY)�D�'S�U�c�z��r�RU��J̀����>��E�]5��[�7�+�o����j�1^����[��{�"@�ZZUg��50��]9�,�E�ؖ��jR9cϗ>����=4�2�-�W��H����צ?��n���G���2}���ɖ�ԝi�4�8c���}6�����Qo�	� о�sa�>e��� �����򑌓b��Ր��(.(�.^��C�d�شY��Ք2�pB�m�$��Wv~m@�d@�d$�zAH���ul@�Mp,if�nа�2ȵZ�Y�r�A��Z�e�JB���G�V�
�NMBv+��xb�_�wM��[��I02��BGV��Ժ���)���)Q�^JD��Ӊk�;-�9!�*����Z�*���J����鞄&]LfkAai�˥ٻe�zt�)j�L�����������2e�.j&���	=g�i.	�c٦�+C�k�ٽa�ucΜ�§Nt%TܲM�.����8R���]��F�o����|E�r���"���E��M7�-���A���qek�]@X�����r�΋��F{[Mw�ܞ��w��h�^#����d�Eg!p�-1gr��z�)?���.��G� 0�l�N`n��r�ʈqQ��)L:T�g9���6�F�����:�!��]�)*�R�����Nj�Ǿb|�����)`I�!�����s��d��l�IZ������sq���,y{5�����ٖ�ؚ��9^Q�B�C�p}�����	�u��2�R�F�w[��|KG��$~���
���`r5}��F��މa<�z����^�);�m�4�A��b�+����Z�:��磪���;�UIP�Ó�l��Y^��K� X��ӷ`NQ,���S���x��>�Gj�����2�;����:TIt��ew�}B{:���Dw��	�?s�js�M�Z�>�=�����أe٥� f��	4e��欢�8��]YAy��<�?_�ZX���($��C�1K�[�P�0�܇ ��Ǽ�(�;��49g"h:��',���l��o�SP6�*��͘N�+���>&T�V5�zu��}t
4���ki,'I�ȍ+s�x�E�=Ρ��ߗ�-�im�t��N�~�T�k�o���E��.�.Y�������uٕp8�K{~����o�6��f��E�n��{���*�<��?�����|f��;q������y�ا�r�	OOUC��-�Ub���7vǰO7�ϵ�0���4��N4ە��_���Na����O�\���Rh"q3U�J+@�W�I�F+P)������1PIx��Qvt�M"Y�V��X��[r�qY�p�܈˶��W#\Sa���z��?&O����Pʶ.��EK9 *��h����I��BM̞M�Rx��>P�K*�!���|��ޒ+�[So��c�qm���>�@�֪l�$�9g��6�ѐ,_$�OC�!�G�g:x����������Z���]$-��J����K�8��$��\����ǂ����9��X:&�4,�d�0{�k:BI����+G�%�Yt�JR��<l&��h���`bk4�?= ߃_("�)��Z_�'n,�vf�1UE����AŦ>��I�_\dٔ��9���V5PE,�`��>�*�ZG[w�'����q�<�Uf��M������3tĎ;C@^���H���a11�u<�u�4��$��6��?I�m89��O.�����v�)�J��M^Ĳ�uAUc9�?���Z�>L���ئ�<�QDmOn<G-2���'z �����\}�;�:����i�4o֙1`c8O�c����cY�M���+J�3�dW/��Hq�I�k���47�3���b��Po8h�B�Fb���$tdH��y�}��9�y�C7.m-���uT�3*O�g.�������ֺL0���~�fn���'�/�@_����1ѻ#(��b97��IA�3m�U�XACy��/����3�w�9�|��S�o��腸�Ш��ot �n��@�ڀ��Oų�Nȉ�'$8�;OL$E�:g��緒�H|��֢�$�-�\��]5JP�bV�d*~�=kR�K����J	�v8�exH�Q�MՋ���Jq���3,�M��D):�d���2��>4�{�[�ѭ�3n�X��eu�f@Ys��m��u�d�+� [4���I��Z����]77F������ia����x��!sO*D����0z`?i��<|~F�ZV�p�;7��s�%GPۅ�[��w�x�4+�@���'����6!�w����̗���F���'�E�kZ%6���\�Q\Sav�o���d5�Ж��@�=ξ.+�94GB�:~�{e�0�����&w0@n���Z$c����n��G�K:��	�k\iG/����C��x63]a�u-MlҚ��`��Y��,��������"֣�����f(��2D�fs<6OmfS|��j)mL�3��p3
MC侳��ŶR�g�<bM����rL��B�Ac��,�R��_o�L�����B�o�$-޼�9T�C�
����}O���xX鴘|�'+�@eb�t�IKMr$��K�.=���ok�E�9s�z�ِ��U�Ϭ��x�3����2E��iU��^^�n<�)��Cǻ�r�u�B��3g)K�؇(��u�-E��e'Js�1۱��i�"����/�Z�<��m���qo�-M�yl�����%���DL�a��� N�R��\J��Gu}�4��V]����F�l���Z�([�Ϩ����G��}Y�/�>7Aad`�1[����d�7�i�d"��R$`�֨z�pr�kC�J�o�Ȧ�r�ih�Ŭ�A d��`�$���[�p��ȵ��/����$�#u�cw<��f���U���i��gu��K�ǹ� �Ķ��\c�]��^a�����{�@����޹8�ծ�U���^%�,F�׏^A����ħ���gv4��Ĭj���c/9�F��|gjJ�:A���#u��9��[n+����s�V��)v���&���-��j��^��i{�������!Ax�\c��͔H`��Ռ4<���ր ��+>���p�ѳLe�ej�G���:39Y��a
�NAY����J����N��@A�~0/�_�;OI���Bp��")�YE�=Ak��K��Q�-�;8�g�.����gd�N����ӭ�EǮx�e���1�#|��r�@O��ad<�[� s�(2�u�ueye`�)J;]g@;.Y�ݶ��p�'��� ��l�~C�{�Q��~������c0��s�tMb�>�lgF��H��w�Yu�te��'ZB�	T��N!ͮ�e�U�c{�E8
�r��7��[YS^~��+�4e��c�Ѝ f|1q��1���KrwVg��3�(!~�ɜ���7�8�;�r7��0�0Ӟ4E�<r�yr%~�����yY�l��?	��4��0K������5����7�c�ɸ��H�4v}vjȺEφY&�0fV�$��l;��o���`�l���'ɞL(�;o ���y����}�e B�z�(A�x|�̄�"�L�����?��n�B��-��# 	+�69X3^MiS���~�(X(�~�\�u�ri�sm�'.�Ҫtg*et��͔�Y�w>|�f�b�AP	!M��(��(p��8��{ǒ�� �gЇ�Ӳ��_�6��I4U�^a{�.�����+B�yJ;k?*��jȇ�����R��u/ZZ�o��	������V��%�I�$pүA�;��{(�Zв0>���&�I(�ʒa�L��Tr��$��~���Z�F���
�:.-2�
�����J�<�`,G#j����:��
7�܀C�@Q�`t�e��(�z�7S�m�^d��K��t��j�t>�D�	��ug�%��-t�r�bT��T�Q~��=E�cS�� N�V��*�]���B���R����n�4}W�&t6�b@D���!���y��}%g�~�3��p���MŔ1|
;���?��`F+���7��{h@o��,��+�)�J$��^�8庶(jN+u)χj�W�����X�I��I� ����C�2�a:U�qs8�����ȩ��skaI��u!�S�lZ+�V+�o���Ǎ����h�mn_o��S0�?�(>��8c�	/oV/6
k�_1s+��L�4�<��6�&��D��9�;Z��Y�O����)�6-�� ��v�ސ��(;޻�CSGYz�a0�+�.	�ݤ� ��������9	� �� ~~B�b�C��X���ir�{l su����y}�-�ۜ,�^~���`�m[jA����C2�f�Fē)�f�/m���;����b�xo��4��J�Q~�L��YF�m�T.��d�\"�-`��h��i�r�����l-,�V�1�T�o��Lٲ����!\�/��� ����0�����1�GF?�e�S�b�}��1���rr�W+(��$��-Hck�<��,���#��� ��:"��06����%�!	�N�1�Ќ"�
К�>��MB�����5�X��t#��Sf(�hG�V�j֦T���qXZ�'�*���Yga:��I��w9��%s��[EG�ā0G~�v�ϷBuw	��B���C�%)���*�
�g����#�B5�<3�HP8�p�2x��|���UF\�^%r�#����6>�2_8Dr�F�#�n�%��$�?"��<�Q/qn\?�Lf2��]w�� \%�i���� ��zB��V�{�QM����l�c�� �i,��	��h��Y��J!t$�d~�G�*.��I��+�B���Db��!\/bJ�~o ��5�����<	�W��sV5�%�&P� �~�۰�m
����$��KY�6\���ڬ���c=x�t��L?'1�}R[��_�	Y&2��t�0�q�u
n���F!��-��6TKt�����%��`W'��L�q�՗��|ٳ"ƪn�?I�퍨��(l��/�B�R��ʈ�᧩��}�T�q�ph�.B�(���U�g-Y���׳�h�{e����UeIBcQn¢���8���F���S2�����"���(9�c�{�f1�|������u�y:C�^��z��B��!�y����R�E���}����t*}ڃ�5����џ�:�u���������U�͗4���ul��>���vA�2��|�"��q�?��]�Jy���2�{n��CI�p7��0N@���)J����h�O�@Ο}*-Fb9F��~9@��gu��1�Tr�,��� U����Us�wǿSu������W�7BJb},�s�p�K�g�L��aV���ct"Ac߉&71�ד]\P�ԮxVY��!Tk#a:>�V�������P ,]I~E� ȣ��/�?���g�    YZ