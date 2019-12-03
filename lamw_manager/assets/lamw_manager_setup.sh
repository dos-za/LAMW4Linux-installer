#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4124485585"
MD5="0577e61c0bd66b33ce9011d6b6b0543c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="16940"
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
	echo Uncompressed size: 100 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec  3 14:38:32 -03 2019
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
	echo OLDUSIZE=100
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
	MS_Printf "About to extract 100 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 100; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (100 KB)" >&2
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
�7zXZ  �ִF !   �X��?�A�] �}��JF���.���_jg\/�x�ny��C@�b1�mw�c;��Xζ,?g?�%����#24V-X6��c��݂RC	���T,��X��W܌���¾2?1>�/nz��HzKc��R����*h��U�I7��i3���%�(��@��p��C��bSd�����&�TH�BN+�ȴ!%��95.�'ߡf�l8D�� ^(�8�Nϙ|�&�d|X{�Y�yv^)�^����d����Y�R�������*�v6���OT҄�!�f��O�x8�ߔ|Zȩ#G�84��6�9M1��?U���+6�B��1�>��˞��4Ҟߋ���~���-�	 D����EP#1�|�k�@�sO���y";�r��q�������w����bౌ!�!��
��#�������Zg@L����3��#=5�����џ׹�����3�D��>���������`�0Wӌ?��%�G��`h�Ҕ����;�|�E9F��h�����h��	��%ߔݧ�sU�L5Z��B�֗�oj!�5=2�s�>ĥ@��E�1����G��X�m3��&�Eg���Z�G��⨿g��e�#_n宜�s��f�b��Fk�QJA���3��@�&|b��* ���� �6�/ǻF�s7����T�*HW�}��Al�����#4p�I_8�/�<?�ܒ�M[�K���(�٩�6Ǥc��j�[��i@a����ku��9���N�L<'����5?�K�YF#R�רΧ{^m��5��詝��X`j��{gY��:��o�$��I�Q�Jv��$�����,	?��*�b�Y��T���T�ai�)�=γT�
(�w.��[4E��;��8������������#$�DV�H<��"����B�	G��H��t�}�}4>��ހ6��#9�#(��6�P���r���y��\,�+��h�om�������\LS��N�v
�ʥ�,v��%��
�w�Q| r������f���)k��*8�^d��N��$����L:�`{��YaE��$2��WY��w�{�� ���fw{Y���;#�,-mB�����葆I���s��t�|���Q��m_���%B��0�;���3vk���$�'n��r��yf8'Z/0W`c�3��d�[����-ˣ��<O������6�*�j�fC��]�G���V��pi��."S�+93��ߩJ�:�(�����g�Qr�JL�#i�*U[�}O�g~^)�e)k$P�`�~�����e2;�ʧ� �7g���À���'x}U�-9ܙlw)1��w)M��04*���	�~����.�ۙ3)���=��r���Q�� 6�St�Q�WK`��A)�~�J-�YP��HKҶӚ���X�O�-��V)��f�;�뇝�oO�����6�v�l�O�C���r@G��
�|�5 ����R��>��ORY��Y�7m���g�7?��fk�hN�a���"[�������_6��Y�
���2͌a�W�ȏ������t�lJ��^�x��/Vc�g��p�U���V��ǉ��೒*͙m?'��v`ǂ0n���)�/R�to����5Z���h�{ؾu��#�-ҥ��e�D�kH#7$k��i�t�b�����I�j�lpC� �ыzƝ�O����� �#�D	`!��s;�'�諯o/Lr�u����U�u�[ ��V׀�Ӻ��N���kH��>E�7Oe<�8��|�<_8�B�\��� ����E qn���ry���R�RN�ےp�O��t�nS:�1�n�鰛gg��߻�u����4!�O.1�yq¨2��]dn�'V�)ޙ�l9i��<��<���I��C"��{z��t˜gI^�t�՛#:�y5�RKֹ�EC��g�ؙ�R�����rݢ��sm�2�xm�I``�������U��ʘ���z �e��8:�MQ>���a���O�N�Q!�?�э���Am���?�q�Ţ�Q�gV"x��,x�7>[����&}~����ZN��'Wj�Q<�6�N	�saǿ��A0��pn��R��7ꚿ{���xH���M伫�NמB�Sf�g�\$�����j~��H�<�)�G5���>�����R��=��,��wG��W@��N�Ң֙�FX��s	$���I�Vg:�.�T�/ed�=����e�o�c5f̕��7vN���d�N9 �vQ�79���^�&"s�0%;���B�R��y���f��&��i)ذ6q4�i���r9�a�@��b���WsL��ȗ��m�Fx�(������V��
��V�i\�3����ZWn����z܊:��tH3��G��/�H�N!�Ř����1�_��5mA_��ہ��ؚMc�����"�'
�k����@���)\��Y�ͨ �������1�I
:�OՃ;:��_���`��ͳ%��m�e*���	�[�7D�N��͇b��h"S�ް�=��,��7\4�?��೸"Fz���L�o7�.��䶛�H�<g�,�`W�
��	G��8��xK��07�'��O��>�$�T���y���D��2�γbAq�m�ӳm-���|A��&�۹L�H\���X�b�r���g��0�L,��Ԩ8[����v3v�cƵ��OՀiO��'#|�SeT�2<�2l�.�[ڣ������EĦ�nK���O�6q�M��K�271C���ۆO0E�^��jz��.�0\���p3G��8�B�c�	m/�~>��]$�N��/E�P�F٭w��ؤd'Q��>"��R�<��G,#D����8`�X�.�{{�W��]�֗�^@�)��;�, ����5gD�
����L�r�쉶BZ禍"�U��:u�Z~��o��Ju�N]Ǒ�(�����\sކS�~��^���U'�!i�c.s�Hπ�L�-)��8_�Q�|s�:^�Zh�oHK�ж1kf(`et���{�`�s�zFųy���3�N�kB�S1
���VaN�5v�&�JoUp�o���������N�%��R��g(��k�]߾�E�������Q���[<p����Àޘq/)��p�j[�b2�B�/�x�a����!3e�۽�ǂ��'� *��q}o;�w9�8Bg�R����.�9r�d`;S��!�#����݇�\i��ƅ[���� V�;���(Py,5�v�<\:�˥�ܳ9��fp7s��/���kӰa����ZD,��f��i����y"�PqҠ͙��P�����W�?�<z�m�@w��W<��>�ϭ|ܸ/�:��A(����,'V,�����D�7zb�~�N� �'�љL-Ր+��	~���p�ϧWH������`��5�F��q�G���߽�v��ZgG�֥J�#���$4��Y����\�ue�R`�Gˊ)��GK���'��\ ����N�/A
;��R���5ۣ�DW�����o��^�L��핉����#�2�_x����a�΁6�*�O���Lh�}+��8�7j"�/��N+j#��A�]0��9��+2�]wxu�0���\��yR�]`�����ׇ�=j�u|p�%��G&Fsf(O��U�������gѯ��H�;wÉ������Z�1'�^\��s���e>a� �=J'���C�9��"`���Ģ�r���wfנ��AfT9^���6:o�$�SŶ��Y�[�it��&�}q7�n~������/@�Aϊ4��1�
�dG�Y#T$S�J�����$&jh:�@}��"}Ww3Q��%��̇�Ώ@UI�6E�e �ݬs�xKק\i �P�w�V��6 ���3��+q��y(Ǒ}�W���;��Yo|< �����K$Z�]����DN��fu��8Ų`u�$4�N�nQ��"ww^a������r�6�:X�8d���"~d_��2��]F��3U���H��j�[>�F�o�2K��8���N�cO�-G�g�OiD- �P*��)"+�&����7,���zV��U�|�Ǭ�ś0d�'p��0�$��E�V���%�!����-/eWӿ��EY���Y;V�#�<��vF�K��U'<�ž#K�,����|%�Ŧ��{���<���1G��8K��ޑ�z|4c���?��4�ò=ҮZ?bފ�넾g�����I�ɡ�Y�<���6�d��~�W��C3��~���9�0Ǳ�&2D�vh�Q�^A�2�0p]�cuj���9\͔E��5[Z���y��k�����b^q���mV�N#l�o4;U���6N�Ǥ���T�1�B�������,1��SpB
�.��Y;u�*@f.����V��0��*�u�7N-$T�D�jI��@�]�X<U��{�ɯ��Ȑ�ڪ�P�V�@���4����Fq\�%^lB�ʳ���!?3Bs�A
:�Lw�Y�F��H�����#���?�nN2�d��s�᳉g*���w�}㢗\�,�c�t�����̵i㕔#l�UV�`��0�D����������Z:�R�RMC cݴn�X[[��2��������zW���kX��&�-��z��D�TAk�����+�W�hK<�u�ĳ��%K����}�O���߹h�>g�y*9u���M�`�)a;�,�����o�i�o"�E��iMl�٠�Uv�;�w&�[�
v���<G�Q�M2A��E�;"V}s(����'�O�+���3���I��M��8GT���hm���j�Le�Ul_����L�5��G�����k�;�%���������/vT�w���޳�W�*�L���-��N��W����m���1�Q�u0��΄t�=6�㖫��З ��x�(7���u����J��&b�ҬV��R�,��#鲬/ǁf��C��WZ��ˌD�� 3l(9u�n�����_�����j�o{�J(W�!��$�u���v��}�\�>+d{��Z�7��V��6�l��Ĉd��ΰЕ��"���h�p6�#����;�k��j��w��A��� ^b��젰�&}>�w+)Uz���EB��o�k�T	s�� �!�i��5ߵ����T�Z��GW�p(#���a2X�Y@��\ I�\|ۅts�l�qrRE��$�� �s]�a���je������Ĵ�k��Wk��'XhL]$Oa�\M����ˡ�H�W�M��]�)���Vی=��[򬞀����q�i��W

��CΕ���k�L縑Q��� �wZ.�/�@��\@=����z��t�l���KK�Hy3���ؒ���ͥ3�oI=����\�øS���ȏګR1��p�@��Y�!jk��� �:G�
�!I5ORt"04᭍��K��]\�VS���^��<}+�)\�|5��|Ŏ�Ix�m��C�Mւ���M��9�Ը�y����f>F�:��Z:�F�3��[)mA�,�0���ОZ�>x �×��mt�K1`�RI�q�&$3Q�l����߳�Q���S�6�������u@��<H29����1��ޑǩgbP�}#"+��PPD: ���;��a��9�A���,𿒓%����c& �U�OlTr��id�ȏc36� �4�ߕ.�;�.��>�lE/�?Z���qpN��a�%l��!^����#���:��yvi)���KI�W4�+�k7�U�@�a g��Y��~��`Nú?Vw 4�s�A�%6����Ŕ	���� �Yhn�����B��e��vb�"#�I��J�5�YI^
Y_��'�KF+0�跔Y�����J##�'�����J�yWO"�$m�e�<�B��5�z���J����Bl���`�IO����g8�Bj�*�39���!�k�U��b8�l�u�+y��ً��I6��y �XFlc�o,�8|K�f�\��}/T��Lyi.���(��&�1�{�X����Ѣ����Ӵ\���o�:�Ʃ��f�"�u/9+�69,���:#��=� �dxV�H������h���sr*̥a�T}A�Kŝ�[IU���Ž�5Ր�&�K���FXOG8yp���q���fO<66�Z~��
(o��i>|��WBE����J1ϧ��r�(�\��w���aN�p}��R�S�GpJI�i��];��%���E���Wo�i�����@�۰�N��$P7&4/�+���Y����t͵�2�RR��y'���B�R�>��tc+#w",��߽���M�o�E�7�A�d����g*�	��8]SQ�����D��)=Xs�
ryUr�Ո9��E�Zb��"2��69v��X{�"��U�;}�N#�3���L.79�KM����M\�|O��k,Q=s�%|����Ë��m0�p���&��^�e��j���'�FS ��"uì�P=���9'�W5:���vq5*k���:��i�S"#�H.�]L�Z��x�D;�N��PG�+*��+6p�bRz�B��l-�Ŀw���*��l�؜�S�(�
.�^��D1C��~��IڔП�1�E����b��!�8�$�`��p9S�ܰb5Z�M�w+Ɨ[���YN�j����
�qFoj�L�p ӬbjW[#_C��u~l=d/�fs���6K����j g#3l��#$,�C�C�\�j�*�VQ=t?%����r^Py9��> ��N��g'ʎҰ��[�;��S�C��N����=Gs��Y�uN�N ;M�>�U��������WU��!Ɣ
�P9���UM��p̀�������T6����!/|��B�ObEW�G��h��挭GU�'vXq�-���I��0���F0H\�)
3�#��l�/奠-.$]%#�\A���'請�	9{)��q8�i�K���5��I.�7;�#{���nUF�o�5�SF	���yar=�&Z3���#?�4AU>���Va#Ge��#ϲZk�f���k�D.�z����t��	�i g ��+��I�]&2^��e+�Mv�4�^_������S��_���2��M�m�<��b���l_�+�� ��噺�f
l�|6J���Hy���a<��e�'ϸMG������鏇� ��
����E�F��ס��E���m�n��'	��"�C��@��2�y�z���u�`S o$�v�rՆĝ�tD� �(cд�J�nvO�f�����3��+Q&x���!C-��f�|�m�M>+��(�����i�?�΋�5 ���ᛮD�Q@�N�^%�K���A�U�����&�v�.�P�VCi�8��+`J�����|��NbC�cd�^Ӽ@��mj��s:=�-��Gqi"�]�㻟�Pz7B:�:#�Da>
���1�p�%NM�x���lF`'��I�^y(Q�>��f��τR���BI
�����u㧨/�.]X��%������
5���פ�lA�x��hH�H7$�
�d�3�^P�X������~��w��d���^G�;�^��EdA-�@���/�ZA�!��d�^�)�㨭k�Tzh�b�h����RE<���B��wc1����ő�SF�l�C"���xV�5|g1{o#��`�����f6���,$)hσ�O�xVI��í;��&0P ���;@8
G.�6���sph�f�3�r�.ߓ`U4P�{u%��o�	�����].EY#<���yv4��j�����g���s�<]I�q!�� L�������K�3дw�h���i��"j�ܣ��º��Q�H��Ev��!�~�"H�_X�tӎ{�FV�(��.箌�_2������jk}�h�OM�r�7�QL��'����:a12��c�=x��{�^��]�~U�+�z�O�H]o܉��X��Y���b�RZ��1�릫��;xȜ0��L��#r�Q�vB,4.��Ӫ��A}=�l~ %u���: i@���,g-���E�r��:Z]>���"����l8o�!��[���U�{W�.u��X����HsJEI�Z��,_��-�P
��� Q�C���\
*����.)�:L�C��W��H��bݣ���Ѡ��n��������k_��u�r! �N�~����|�� w����S���[�܉��h��2��q�i�)_V�,D9��O��4�v����4�τ�qt��Qgs�+Ko��Q ���$||��=�z��Ih}\e�����E8�v&F������?&�y����q��zK��5�;*>�=��}�mL I.�%�85�ڦzrG��47��Z��1N3�l�{߮�P>CN���D�r?�*!�))@��v1���?8徾�f���r����� � v}L�!r8�t�<�t��&�&^��<� ��j7� ;u��>�I(�*֘XH�AM*�|��J��D%`�珚xW
���.%{*���Yw_>=�E=Ld;z�?�
_<�}Zc"�\d*q�!�]��#ʰ�E/-��[��R3���I�Bԍ'tM;�Bӌ�A�e�1�w���Տ�Z?!gW;&��0�H�A�(�bE
��'uF"���~'H4Ůbw' �~&�_���Q�	��ظR�v�^��K�?�H����w���x�Y������yY��M�h��?]-����	S�z�Dֈ~�������=nT��<��Z��۠D�uj�gnO�jy�,*0�3��O�5����6:�����8�4|BD��~r�����&Iz��~��n�MZ�G�����m��8��g		��[E����{Z�
�x�J���g�):(�������O/�Wy�>$��6�}I@~�x��H��bw_�3�Ee5R$vޘO_��Dc⇳�V��Rg5%*T\|��"<�i�-�b?T�_ǅ6�=�u ��VF�Ek�/L�Eh2���*��T�Pw7��������mΠo�y��S$��؈f��hfmȸ"hre�wf� �÷���f���uV����HsMu �|�0���!q��o�[��wZ��-/���*K�4�^hR`쎜���>v�t5[� �=ޮ8|���&K�%M�T4�5Zq��c��p{DP� �����"���!����p�Q�4�Sf�=d^C�X�Kk"E�;Y�ƿ�8i�[�cf�s���ݬ�G�4yq��B]hm�h M)p��N�C�9�_4���������,4j�_�y[�1�[7֧ɚ��玭�V��M\�8EjBd6���Ynx5m�0���5V9�i���E��+�\[k�:�a*�8j8S�2�hDsGP�d�%�m0g��>��⾃����NHѩ�������h���k-[
x�>H'Nۚy۸��d.��Q����k�k���I��1��I�%�xPkڱ~{[�2���` ˍ�(�(۷�Mђ�[�6�3��`i�ٳ�
X� ��H�%1~�5�{���#.&�g�:u��g����b������+��*�.�4b��Z ��לa��8�F��?-�Dl����@�������(U_aĬ#UG�i�vPVE���"�(��")�ic�Մ�0�OZ���������ix�'����-�I��`m#�-����q|�p9M�Z��:$��L1��2?Tg��mO��:��A�e�w)�{I�9��ͮ�ץ�,Q/woƌ���5]����0�;��i���ښqZ1�^�O����� ����U�a���v͌������l :�	7��V!]9��=�|�p}�)`�a��!��篚���?�_p���|��MH�*�,�����Ԛ���=��󐞂�\�C?�ܹȊ5d�0:_� D����S6PoV{�����`��J�Z�1�i�9� ��(qDF�4g�O�E�s���rYC�%�s�D��c������+��m����Cȥ���_q������Ş�UA�\���s��
�*L/hF�����f�B��Ugđ*A�� o[��D6>�P��ul��u��#�򳕃)��ź�X�ؾ��j�=X��w�~ѝfu.�T�.��6�o�P����Ӥ>%O'x����T��`[����Ҹ�Z���3�D��F8����H<Z2��'�3�.K�z�@L����]��c���b�f�P�Z�2�i��7_Q���"�_5
�v��(��գM/��oU�D<���%�6!�T�L~a�)U�-�$���v�KP}�^�
��E s�d�Oa��
��_�)O�a��|�<U���L��w��B�)|jG
榏����Zސ^��@�1������H_�`1􀄳�=d"3��1�\���1H������*"lBR}�����s��\d��J���\#�a���Ԯ��ȧޥD��pB6i[�e,W����`p�V�������.JT��$���b�;�~dlO��#��A*�Q�P�p.:iF?��&�r�Kz�=M��O�b�1�8��	,8bG�tYM����1lJg��V��a�6��e�(���7�1ڼ=�Y������!�H�`X+�����=����f�f�w�v���
Sg0�,ؽ��J)ܫl�e�lR���S�ɒչ$���_]�O����*�lZ��,��o�S��O�n�h=0��7��x+�1�UY#��ؑ|���'&N=m]��`��[Zx�̴�Ł�^��~O�L4��M��u�7�y�ͣ�Yts9n
\4M<�R>�h����;����G6��zY�̴ �,w��b�җa�J��ê~;x�ۊ���zN+(�{e,���m Y�5n�9���[��s2�'�A�c�rODYA�?��OQ�Q��{l E��>V\�VO�ޝ�6��-�h}�P� #���b����A@�tp8M�w ��0a���i�h\�DY��(4cC�������\����W�U�mՇ���.�s7&/��=?	�'�j�Ɇ�S�Ƚ�Q�����]ü�>���O�t	�W�J�dL�9CG���F4�Mb���;�l<e��`�B�_[���r8#L�N�ؽ��pU�7����_���M4W����\W��Y�� G���t�|�"�>]��A^ߛ�����d��Ѻ����8�(B ��|T׹��L3F��ZVe�g�3Pȅ=$���XL�u�i�%���l{o�N�ӱ�y��y���SuA��=��ae̿�����7Li#i2T>����4h|oX%�aϋ�Z{�/���#�y(���r{劋`"���A!�1*�B*)������Z�0\�Qr�8�E�yVM��C���FK�}e��#�<RCB�b�Ql6���Ț���uÿP�����ë(�Q�s7U�n��<c{���R�Z5f}�9��4���㟍E�Q�m�c�g`�5��[���Ĉ;P|���k���!bD0GԆ&�P�^4��p�=攼��Z4�k$X��:��(y/�'�P�4ý�e}�z����\A�N!�q�8̍?���pJ���X�P�X �_L�Gяo����RZ�)I�Eu�2X��\�y��f0�o��n#��2�̈�� �EG��;��hf�(�𦏟���t��A���V�N�s�����HH��t�<=ɰ3ٟY�&���I#����p�c�1Xh��u��UB��l\�YCfO��T�钮	Z�#��rz�Q��3���H�`}���X��y��O�B2P�N5ie��IM$t*>M1+y0�_ۂ=�9� D�XkCr<�kO�_n��э��ߜ|/�A
/�ξB�U�t�ė�߇K��{�ZVp��B �m��x�s���)����f8 �E|7p5�|]n��u�$�V�J����7n��_�?��AK"�|�j:����I�on!+�Y�5�}�<����f!a���������2Z�)�cb���c��#�͋�WYae�=4W�!��2�����yF��j�0)+	O8��޶��Ė�	�o��U(�3v�4�Q��Y$�G��7���ȣdq�!�x,�ۡ�)��^S��t��I��޳�/Q>�2q��h�Ƽ}!�喐]�3K��HeX������.��+�.�c7�{�������i����Py�j�\��K��Ĉ9
؝������B��/���{�;w�h�@B� �02w�Z�x��T~���^���0�v�a"M����8#�6uműr��{�!J,�
mT��a�K��&X5PyY���!{Z�ǔ��p���>3#��v��ӆ�Eb��}9��WӁ�y�A�d\��}lm�{�Y��P������o�x�6�N��%�� �U���;����o8\�X;d�ڳ�,Ń�Z�}U�Z�Y��^��I�e$��c�Ed��|��;�Lxl�b܇��*��V_�"z<m�p�~��
���')�����ĸ�Ee�qis��5���!r?�i�:��e�۾E��K0��/�XH�E9�r�Lk��"��vZ��u�g)������'��J#jz��+m�/ͻ�M�'ҭ�d5�4���$x�o\[�C$w��X�GIu��S4�	����L�IC�<,��Ǉ�E'��h����.{����5��ݢ>'_,�k�I*�}z�o�ql`�r�1���;!|b��P4`�S��P�Q�i$��`ngd1[��H�,�>���ñ*����׆���J�X���7g��7b�cQ*}�����)t3�Zźi�R��E�'���;��;9���ˏ$p1ϗ�5\�6�����|�y
��ޚgH���5Y��ve�#���E��xc��< ���<U�q�B�����6ې�XX�յ0 M��sL�!�dwe�a�����,]&�������o��޳#���E԰G~�#f�d e��9�_������~������Y��� G���I2�S�����w��.T�I:��������¯~=��F���L)(z~#:^���%��|MYF�8ꨁ1���}D�����g=,} �l'Ҳ�Ab�-97���> ���@���;�<�j�*�\�۞�Qg�|<���aD�X|H�	r����sm��������j
��������y���&B�̼�2%�^A����1��"b��U��V9�Z%ₗH�rqR29#T�ݭ\��6g,�0�[S��
X������V�+�(�b��PU��+U�I���݁f��Ϣe�M�zW�����~<��\�Ru&�'�-eR����_�*J�G�~	\}Pϝ���}��RބU(s2���.m���T05����:�[;����6YȾUm����)#bf��}�|M�W����
��H�Y�QU�b��,�audTq�9��n/�#�>c��%
]=ٝ5�d$�#���_���,B���O%��Z�ŴY����%:��Cp�4) ���q�=S�������UI���Ol�H!�Y�\�k�K4sn.��:�.��������D߄c�Y[_q�J�i{��Ց�Z�7ړl��X�$�����2�5��G_Y��|��V��2��\�4�U�����4�q��o��&"�M@B('V�Z`#�s-��锉�����Y}+��b.�bй���my
(	�R-�������d�.XBHPY\��G
����ρ��ꛧ�o���Q��/�N��[DF2��۬�]�ql����U�Q)��`d9�!0^�7�O0�z�g~&��Q��V(7��^֭���u 5��f�X`;g��Dc����֖)�=�&t��NV�ʈ(�hC����,R7
�ӗ�י��}��'^���uN&�~ e��-R�����
��J��P@L(���:��Ku`#��P,�_W￠^�ŧ�/���Da���P{;'fDI����\sG��)�us�����ѯ0�ӈN6�V��Ui�腢�=�
6�>ǈ���
��{X��4����Tk��TF"U�m�Rq �WoT�S)�C�9����9�D�6�>0D�����ǧ�]��S���Ƹ:8s��,�N5��r7: �GU H���5x�n�m>���ҡ�T���~u�P�Ϥ;��w�qHU��S�^9v!�ȡ_B�-͋��O���g�0��P�ī�_֐���<*�a��Q%V�m�р��~��1َ���3aQ�ܰޏ�>M!^΂����䓰ޑ[z)MT�yl����^�BS��M����I��"������T��䘤�#���By Bt��gvH��k��~a"Օ��	K?�&����Jd�g$���j*[&"��'�*�7�o$%U���z)��hPic��bЏ���������Ϭ{���|֘d�T��7�U�_yn�p����)�� �+Fd�q-�at+��k�J��gp{���m�x)�Y>Z� ��tQ�n���R�%�F��b����.ыR�f����Sᒴ~Q�񰙠X��E�D� ӹ�>8����0cI&��rg�5�a�H��M���.�)���v�U[f�=��)�p	������lG�G�4zJ=�ȣθ��`�I�@[��Co{i����.o,�iT�=��ѿ�;,᱘:ו�┊��3!��3�P/�͹��� �� 㣗&�&db ���Z�:u�l+E�"��f7m�-�
�e�R���{�� ��OPPZچv�j�l��J��d�=�+�b�3��{�R2�!�]9nK��q/�m�Cs��k~�$�)H�l8��S2F�m0t�� F�(p #��4�Q	�N������#��e�0T�(���i�b�f�U9�Tň�hD2�ϓ�,a�9y�/��s;�V�'n�&�iY �n$����
���\nq,�Ŝ��C�$�����^RS0��:���%2�.��p��$@q2E(��uxAf�+��/����>��76(���g�]Lݙ��N��át��?v>T���	��5a��.�T0����~�8�w���L4*��_����2j�����	[_��c��!��Ii��Y��*������S��6��whJk�g�`k�PI���z�sZ�/�g�<���GJ�8���剴l�4&K��H�r��ȳ�{s�g�1��B�&��y6�9u���[�}���m��Qʤ�����S�P���~u|A������^���d��L[K�:����Jf�s>�|� s�Y��j�ַR�� +@��O��ƻ�U�&�b:B��gqIh��dqTL���Έ����I���S[�u5�J�(�Jzj�;������lh�-�C%��h���ٚ�O�ѷ���1�kUō$�� ԉ.��\\��˜.c��w�����`�B��o�nI�C�.�V�	�����-?&1��Y���.v�s�5LC��A!�N.d�@Z^�d�py��o���L���J\�C���=Ժ/�;s� �����2���~�IF��8	�}5v��8�~U�ZD��Φ��`A���ss9��
��!���0�p^Ծ+J}5fE��x���U�Y�n��B���nГ��]� ?�k�5*����M��qG@U�eΚ���D��)�~�@�e~���)��m����Q�bpe�k;�g�ԙ/!M�b�v�D 99�p�E�s� lF�h�� R����d$�N�\�����b�81}� -;��3������S�p����h�!�0����ғ��&�Fk`6�ш`(&=���V	�����oc؂���WՕ(��հ?1��eS��v��� xo:��(nQ쏢n����s�Y��=\�W�݀>t���-�{�9"(��K {�� +e�y�?���f��7 �Qd�w%o��T�h�1�
g�O���m��Lr9V����,A�������e���ǟU�<s"(mO�0�r�1#�DT�ځ���^���E�0�̪�9�������o�.�:��S�0B^�O��HúO���WE6Rc�Y>����
���eԷ�~�Ŕ=�gy��_�Y�e����8��-�]V�5�<���������"�6f�M���?��~�����`F? Se������Pۚ(Ç�!BR�z�?��^
K��@�/ӫ/��;ə���5cZ�t7�T��2�a�KV��4o�>%��ӗ���]�6�0"���!r��-��A.Ǽ�/�f��'��;��{PB�+���,o�@c峁Ԡ�e�Y&�O��侽�?��ֆA��

�Po=
���(���n��{�6M����:�I������r|7Be_E��v�xk�b7j�"=�7=�:H��3�]/q��9����v�+Ri7�?��Ɏ0�%�ה��`A�i-��#ه�?Sc��V3B4G�@� ��U�c=�/��1tͥ6�{~溉�h�k��0:Kљ��o�_�Z׃�n��Qc����}�B�\t�T�'d�P'��{��-�X������$�F�f�%�TI��B��s�C�<�Wgn^���������p��s�6!}zLq{�����t��z����Ǟ�
S�}ޕ��ba?�hbe�^d%\FR	�h�E��J~�Cԏ�J���ɰ7(*�O���!Z���n�z9Vx@����������K��n_��jN$+�:��:j�<O��Xl�3������{���gt"HL6=�mi	Z�TTR��}A�{���f�q�
���ʍ�����Hۆ[O]����:����rc�d����D�ہ[�}��X��GQ�{k��f�V�m=yq�$pϷ�:r�p����D;|�i��"%t(�<�[�ȑ��@��8k'�c���ն-�ׄ�l���&� 0H!,4������5RN�����A    
�� �ъ �����W.۱�g�    YZ