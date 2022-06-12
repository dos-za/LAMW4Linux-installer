#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3016456309"
MD5="6053ae71560b215b2718ed225c68f8bd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24328"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Sat Jun 11 19:40:49 -03 2022
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 140; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
�7zXZ  �ִF !   �X����^�] �}��1Dd]����P�t�D��P:�.�k;��.=�m	5w��0D�_��j�������
���a5t�k��z�(����֩��S�`��
rb�9�9r��v�WW��h�.格!~�2$!��I������o��/����C�l~өܤ�wfo�pT�<ɀ?��H����B�"���9���F��7~%�i�\��4��F"F��MAkҍ�/͏ֽ��X(��<_XL�-�z�>����D\]zk2�ԝy��g%g��#F@�	zǋZ�)���}C��z�?`T�c?`��|�qY��e�/3F0��3lW���9��_�~�ܻ���G4,��zHe2T5	z�y�Ʌt�� Ĭ�Xk$v�~Tj�����Re ;�|�H&��&��O�,ܶ_�m�VW\��[d�3x#�8��>I������������	r�O"4��28ͽ�7JY���No�����O��HIo�C��⬐��.�x%{S��9g��u��KH��m�&?d
�~r��dD�������TkA��#��5��b��l�t���T�D�d=� ��C��s'juH�@h^TuO�T~kD�����WR�b1l3�X~�}��B�N��>�U6	sks5+���S�+�f��,iC�/w�[��C�7ro�%��� NĀl4}Б���cx�m����9��E��3-�$�0����ܺ��X>��"j�l����h��NЖ���y������a��*�*��.��}�d-�ct��z�!S�Z�ٚ�扤}΋f���MT��(&�rW�u�����)�PI*,$�ҮH��1���Nߑ���Jp��*Cgޕ�u"P���0���E����ܯ�5���}g ���K,�om�m�NE�"��3����7[�^�l���k-ihK�f�S������Tb7鯝: �����@�G�l���ڇz��h5��� �8׻t�����n��'���Y^�v�O6��HF��P��r�w��;���w��ł���̩���o���l���lԝ�P �X68?���]���2^�+�kZ�ޛ�$}�����)�\=&�R�Q蜻D��c������E �o#���q�F��+�5����ƞ)�?XT�kd�X"N���JRQ�<��E�/��$�γs��\ƦO{:y>�W��&�X#���������_�jNԨ&a�}�n��H��?\ھ��M\�^riχ�x���  [��3o��y��'�.'�֜iC���!R����Q�t�jJ �*S=9&�g��y���]�0��#-����y�@ZK��'���.�4��gԔ���7�W_{ku_�������]������/,q���f� R?i���ˣ�p��;^�L�:��Y���Q��.5�E֡!�S�s��y%!�\J+H�[��@yo�D~��-֑9�u^�'X��u},p��
Ò�.�z}�������g0Sl(*eHm����l�\�n� ��k�q��J��E�c&�^��X�w�hMucoK�-;���|��)@�t:P�����/K�z��ȇ�� ��T �����MV���X���ۣ�B�<����~7 ��<o�B��
�����X4����oDr�鶆���%2��2���^vq�Ɇ-�R�OѦ:�L������%-��4kv�*ݹ�&��w���[΀�o{���١�mG�3�~.�z����J�S������1��m�O0-�Hn������0�R�V�;i#9t��R�E���=�u�V��������+�&]{+l։�a�TV;��oҘ4�'qB7��ikT�"���ޖ�vtNI���\�/a7��"��ό�JW;�1Id�e+�=�u��}i��J^��+�w`���x
�t�PgB_�l"�����L�� �dP��9�BC�R�
�/������y-����K?�]����"z=��c8��Ӳ��޽	��P�v�|Ow'*�S~���K�	p�b"���b���iXv��k����tH�9�|�;��,J�·)��I���ڝ:�
$'d����{���&�4�5�GA��.FqW[�^+�C:Z�ky^��_ȧ2G��}���H �#���Txg�Gc�0�e�0�Yt�<�`������{��ri�	*������7��1$��p~8�P�ОB&�71�c�ُ���m���M����0�c�E^ˡ�:.]�@�e�%3���'��=E�\��|yq���w5�
5ubc�>�b���4Ԛ�̈́����^�{J����C?����RM��ⰎIJ� ǻ�(ý����p?�p^� ��XI��d���O9�޷6޷r�P���8U����/JK��� �[V
�.{+-�$4jN�2bl��D5E"�=��5�F	�Dl����[�xӉ&h�DU��$��fZS���i�W���
�Mͻ����I)a��ƺ���[^8��X ���̽�B�E� _C8OWIQ��_ݸ0:��Q�J��Y����}���<���w�@!�誠����Ґ>������~�`ֱ>.(�'y��+���\9���E� 09I�&�	Fڧ,+��w�-(�g8�K|ɗV���z��as�9FKub�cCS��ey�CU.����N]jFm��c^ū�&�TU@_� �5"\=�$ ���c��>
G��w����kM�j�t�!��(u��D:(�v�Ҋ!oT��dK���b��$cʑ .�6_���T�>����'`��\*����ܲ4�1����4)�Z]A4�(O�@6By�)w�`�H'_��c\�1�*'�t"�]0�ОX��00���"��[�S<���t��S�naHtt�y�*嘪�w�5Y��{4�/
���7Ц�w-R�����A��+��j&D�"�'7����B�a���.�/�S����1Ә�6W�
L/����%��:���e��`>�bY?G�_�&�6��]�.޳����x�t����Xu�X��R��	?�2����ɵ�2�:�q���6-`Tu�S�����S
V<X�i����W��juk��V��KTk�G5
�Q� �|�i� ��W��'���yl-�r2���i��LG�#�Sw7"t��ܠ�\R_+j��0]_�\����^�~]�HL�(y9��� R>$^���ɒ����bln*Z9B�Ȧ&ovKF�I���?΋ ������^�7LV)��T�~���?�-EtR�O��[@#i�:c2��+����N��*�6�����$�}d�4E��D��U�P�D	�ӹ���u�w܆����}j�����:R�]�(B]��x��;@?t����tS�Nܸn9���[�΢�?����'�֚�"�9�G���2�|e���Z�w&�$�X��pFAȤ��OVWۈ{����ʪa/B���m��&W�����F�\��ڡ����e6�����g��_�E����)���Q�����J"���VAuc�ށ�j[��g|����N����kh�+��,���7a^k;�M�ZKv�]ӱ���v���
~Y�i�K�K�H��H�&(����F6�Z�m��B��X�v��ƆW�I����۠�NFT5� ��{�;Ds�:y����q��N��M�;$W��p.bv�0y�������$���fyJ �@`���\ȵ�NpV����z_��3�Zds;nRUy�=v�ؐ$I<�u��g{A� t���a�H"Ǵ
��"bJ�f`z�K���`�CaD!PXbE��D,!�uaw�ġ�#n>�!�A3����
Y=�{8��p3��9��
��*���1�	9���	�?��q���.u(���՚ً1�Vy��y�b�
��{)ḥ������c߭��KTD����TI��EV ��257���"�ʌ����or�49䳌䈄Ri��^( ���D;�0ʝceO�X�o�*���%H`�����db{<�zF��!���J�'e0�NS;M����@z�}��s�-�e����Em����$�i
�K'�bP�d�&=�УRZ�`�J�u�ߕ$8,�{�蹍'��/m��C	����~��I�b����8��?�h��m�l#]���7��bY�5�#����ݓ��A(!s8~Y�lz�!%�05C0��ÙK�1��lO7k^�F��x�AH�p�qu����/�SZ\U�v�L�`E{�!:x�Q�������[g3��9����ї�b�����{�����S�0F���Co݈[�g�Ƚ�E62�ϒ�X�i�,ƾ݌Sz#Dr"���\��a�������8�P�x'�ӺEm
rW [��I���F6��}���E`3ٺ(�
���&����J}`��$I�UmbO��0�������ՀBiw;0�wʐ`O�Kb�c@e���%����D��#%K�X	)�*8�G3X�X<x��جU�;u�������g)ĺ �)C��D��m㹌J(
�c
X�'���<��07�E/\ˀeDU�p���}_�������oT�7Ss"ئ��.��B!v��C>:�O����`\;P���.�S�ik���M���D�ǗK��u����c���uJEe(�)P��(m嗯�q�ߘ���a��|�
��h��E�Md��Ā+�zprjd��� �20�Ŭz�{84���W��5�͙ǣTf�.�vQ��H���7 `,� �B;6"�y��yt����Q���߻�g��?�ү�ؤf�C�?���V��E��Ev�:t٩�?#�f6�V�2�K8|�
�Y<+q�����'eJ[p��Ȣ(B��7%����������}!ќ�52��ˠ�(;�{`��U�ӆV.c7��D��>��������2���B^�OST��ܴn����᷾r-(k6!�d����m`{&�Z_�h�$Tp��4�[Vfqmzq�J�_��4����8].}Y,�umj��I�ʮ^k���W�mz�U��0��g��.����V�r H�k�3�K���#�Dڶ��\�����5a��� �V�GC�| �%�`��M#�w􁊺�h�3�7�i��A������H�d����FuBE��~b���:DP	�� �D\�6���ZM"���%Q��tOYqhE���}�3[�I8��f����Q��Z?��};�N��P��R&Sٟ���b���1��8z���ֹ5��k�a�fJ��t0�|�w��]n@�����t��_6���*�M�/�Sly�T�x�P�p  z��諞,��v�7:��~�+�?:4��{&_��Z�@�wC1�M�����z�����i�q�Q�	:�~9�"o��[�m����B��{ҝ,n������ޖ/�g��Ջ{Y� ��ުt6R|��O4��/�����>�H�>�iK*Y�FnN�hl�>i(~c��U�M����+
S薦��~ĳ��t�^��0W/hY����L?�{����j�����jN�QM�EsrV-��,��߉���P�$�2��5���|�oO�� f���j���^w%ROs�8���ԔM;�$��G�/�.w,�ٔ-z{p��kg`��k�ҏ�D���gZ��0¨
5��_]B��po3槃���[�hƱ8�5�F�(-��=�V���E�Q�qT$b�e���0A͞�s1���/v���T��ԏt�Ͷ�<S�%�Q��k�pڍUʐ�Y �Jp֦����z�~|8�P�
�`GI���/4<��W`�ֹ�)��g/z���7�;��y��m�g����]��DU~1d������|�J[|
�'�\�y3��;�� ����*��շ�7e�Ǧ�^���%W/I�yۀ�����.�^`����U�a�Bi��3��P�� ���#9X��l�F�&�l�%63�b��E0�H��j1�"���t����.�&�P��?Нy���
F�8�ޅdC��dC�AK�Ж��T��<?^�-[���������/����L�]3q
?:t(?��c8-	^n�D͓�7��nӹ�R/9��}�Fހ�a]|�W�:wZ��0s��t!�uj�#�!d$�� {���*"�+oR��ؚ����j�[7�s�y�T\�]㙱E���j]SQ����9p����	���{��zݼ�ύ�%2b/o�yB}��W��Vc��+�Z�����BI��_�"JCY7�1;|Pj��S�n:w<�+���V��Qwi�Q�_	�K,��o�eP��^B�P�i�8<e���u'�OKD `[����7�� ~ڇ�$�I��<�D��FC��:9��%x��H$��&x6��ԁ�����R#N1�5'�.`/�5�V̰X��k{y�,B��3me>X���tY�����wS��q��10��xh�~�b4�"V��Bb��@5���15C`Ow$d���w@.fU^z
��H���ԑ`���}����(��
X�G������Ý��R@%o+$��,���?�35��f [/T�"��>n�%�m��d�kB�- �fN;D5��)pp�?f�}G��0@_�V1�y�F4v���+ �4L@�)L*�M�55��f��lg���*Z�� �[����iU�7R؅0�Y����־A=��P֥
�EC�H�؞��"�a�e~ܛ/$V��0<��*h�"���ʨ��a�Пێ�C��D�k����bhj=j�n�g�ll|��ޭ�w�j��PD�/K�������N�k �a��B<Y�����/b܆��H�ʓx��B/����S��W���u�	��Z����vwmm6���[��?�k��� �I<�����ꩍ�rg<��䈮�8Ff��?AS�����Hɩ�}���)��	bI#�4�F�T9i������v����_�0�l�K���J�jm��	 D�(t	�x5	��+� B&�$3���z`+��U�sx�W3���N�|$����xa����\8�>�`��� ɺ�D� FFج��Q��D�ưӻ(��RN�xQ�L&��=^l�b������n��W��kKk�fK	0�T�=�H
#��Qf�G�=��Nym��'KL'^B���r�7��|Ӌ���~)�H���[
�`���N�=��Cq�,
5td4��ɅJ"���ҳ�\�vhJ������!�;3�rD*Ă���KdEC�#
�u�� 桞�[ ��>��0��  �	�5�`^v���OxP�7�I��)%o=�Y5|�'���2���Hx�U�F
c+�._�K�t�\6O����0=pcF!�^3��$9�Q)��;�H����P�o��ǒ�͡���J#�M��Go����}�k H{�����|(l�v�������{�b��孉Q��+�n-�XE�n�'�M2�*N`��^��ɢB��x�Ux���(\�im��|�Ij[�K���QI�W���ğ�݀���.���ޤFe��B�'���V�TZ���
����~�sњ���)�D&�xqVv���b��������/��W��Y�T�di�)�7��Nuȑ��c-ka��6����e3� P��L���x���E��z��֧ɼ���2m�d8�gY�U���a�w���R��\
�4�=<�i��v>����n��2��+]2��`�=��?��~��~==7�����RNR���&��@d��"����T�h��ɤ�j�!�֎��	aک��(�L@�'Uu�(wm1�A,Y��a�e7�î|w'�2��>g��H�!�����,<U��h���H���:k�;6�,:����2��(��,+J��Δ$e���v�s�9����m'6MH���C�/�&�ӗ������{"#��֞!hBj�6�T��c~�M���GM�U7����#o0?Z2;r�bU��������{v�R��EfN��e���z,��:+ێ5�)%���Ö��z���oWg�h�=��m�{����(���ћ�1��PC�&4�T4�2�S�{Mܜ�X�̑��`��nD/�TK�څ3Ɖ����Ky�貽�%� g7b}F^	���jb����5S%�g�~b�A���i-�3����:��d��h��aS�x�%�߬�L��c�����$ʌ���8O��{ZZ��ր�� Nm�c�o��J�:4��2yX�u+__��@4:Z`9�>�
�|���3�>I�#D�3���mu�6Ѧ��
��U�	Uwma���N2��`\E����U�����Ϭk�5wi�]P���+�!)�i�rS6%Y>u�V3n�FY�>����\��^
~�m��P��3rR�&C����?X˃G��v�6̢4����)�0L�r|	.�-��! A�h~�N�� ep �ۍ�+����"�]Gl�&��p�n,�r�=�@��T�|��PWL�MU��M�)��{��#F��ʈ�K�Ч�H��nU*�}�JH8�ި9���&��?#�A���'H��.�NL�[h*�����aLʽ^��I��	r8s�r�8�+,4ҽO`D�>����r��1W L{oǁ�ꚹ����/]=j��B;���`.�qL�i��[�h��Z�-hTgm����Qxu�Y��`sۉ�Di������Hn�������'C�ש���թ���Ѽ���4)��L|Ҳ��ȱ�0����gZK��� Y`9�߹�E38\����f��ǯ���i�K��Lp$E(g��
y��k�4'�%c����_(.	���tD���o�c�	oV}F�']�&���.ZO�.��;��֕�(Ҋ�U��?4�="M�`�A`t�6~n�f��~]�����x-�Ӆ<�]�v��nT:�+���aǛ�V�,�MTV���UVf稁[]|��jC��4a_������������i�x���K��MYC�~�]x_��Q-?оpSUҨЉ�,�f�OsrfH��U�t� ꠨�iEaU�P4�4���S=�n��yz�/�ʇwƦj�4MQ�E�U�$�˼��	� ���y5����5���@�?_�%k�+kXM�`|9Gt;̫�-g�rڂa���,�~����� a�d�X@ӏ>7}�>�ώ���W��.$G�$J�T��=��� ��,�qf���
����"*9d���e��x����p���r�9]��oH�Y�TK|��lOh����ߎ��Vl��Vhd�
�,����T��s�0�c%SF����n�Ğ��U$���K�Ws��-'��*�W);��9;�뤄�T�awE|���6��?��Fg�<�e�^��W�d��a�>��dA[�FP+d|F�}�^�ҡt��Fڣ�����۪�yFP�A4��V��V5�37� [	?iqu�P3���@�Eމ�ξ��-л?OS>�\ږ�*����0���ֹ����S� �P�!O�!Ԟ��E:ʻ���7����^7,|���D��R{�S���|0����9�t`jy�
 ��dc!	e炚)@�j,���ק�x�I��Β.Ud3hTRA y�%g��)31$�L�fX,^W�('tD~�ʸP�'E�l�.����������r]_����vU��MS��i2�z(�J0�7�xfiG��T���}�T_íl] ��*e�7��L�k��_��h�"�m�8��8��/�]�Qh�F�Kz̙��XA�T�h�P����܇\f��ۉ�y��vD~����-���g��f@�W��H����l���ba�8?}��	�7��Qǃ^��7�w˽�%	�=�ܻ���iIL�/N��V"�P
2�r$X�>�`��L�\�ư�3�Bx�`������U�<z�(�ߨ��o��g�#�V�E�~F]�G���+N�츿���}5�)q����4��s)����"wQ��\|��p[��ef}�v	|Dl��lH*�q�ш�'gV(GT٦S�K�Z��c	s#���>�r���6@�%�6ح���³����*�*U���N$���?l��̔�v�nli����]�/$�Qb|�������^�5ʙ�Bf�f�}
�����0�d���uFl�g��6'+�x��5�.%���O@;�?l*s|~�euR�w܋]���SE�Ӫ4��n������jF�d��6$������xe\�E������:}�͑{f�'�� �Pŉ�D*s����W��ar\�O�uW��d6�51���J�Ɛ����k�������AP���`���-��ՙ&q��p�ۊ��!��Ă�'f�B
��Q�meQ T�K/���'F�
��`��? >O���vMQ�^T��R?�K4�����P��-��F��l�}�[b��H< �f��f�ԜH�Ą��R�C\і�����-�;{5�S~�������=�B���=��2�r���K��(E��B�5�s��4�KvZ��m~�M����bZ���Y�8�R4C-ϊq�l�g�!�D*�e��XK�,?L+��9�S�a�=�=���S*�e|~�K��W��+��e\�c�:z7�
�aN�m��"�u$}���1Sb12���y�Y�,��p��HZcɂ�kTY�t����M���Kx6�P<��%y0��ekl�\{?�}�|�&
���4�w�>���j���Y�dX��cՂ���4W�B�E fF���9��	]D��e���y���r��˪A�{��
�ܒ����C�z(,��31�0AlL���ǭz�됲8����H��و~I2=
�紈�0��*��p:ksFSH����_x�+�5"��y�̄Y�S����9�.�<~Y9C�\k��~.�]`&��(�2�xOd_������%
W��'�~��l��G�=���C F((>�Q��ʙ)ِm�*U�ԍ���%`���MȟM��I�|VMՁ`�"����V%�7�y���\�\����Um��l�
b���1��M������q6"���湥�\MD��c�\}��/��)�{f+-�����a���x��[�� �}���C¬�R�q�҇��;�������ׇɖ�av~}.<�<� ��d��/��`�&���n�����g�m�N�z��ޕ�q	I�Qx�Yj�EZv�O���K���-QB�2���q�Jↈ��\�ky���yK�T�\��MQ|nh�-:�[�p�UK��d��K��|�;z���QD-����#@�/���a�Kf�8�E�녁B����v���XL�������-f;����;���Z��ٌJh���X{N����E��߱]�T	#�`�l�*��&ԇ@�vQ���z��1G�z�����u��V�Ŵ�Wd�w �jmz�� �&�< c#x�!��5���{�@��o� Q[�f� �T��>g �Db���'�%5^��0Զ$�QxjRU������V&���Iy��v�݋�:����7~E�gF��
��GjgW|��پ��7�cp��\��B�}�j�
py q�j���7��o���\/��O�mg��\�xL&�����
�j}a��&U/�-��/�s���@�b�M�6�H$�56��b)���U���a5,(k�qӁ�٧e�eHǱJϧߟ��9�e�F��Xj�8�]�����:����Y�	lX{�*�i����wꓒ�g�D��>��V����D���K,����{�):z5��#��OZ!�������K���k���bfN�Ш���ʴ��䍨�G�54������W���l�u�J%����n�B��])�/w�&*]� x��̡�s��GxU-���:�?��I;���
� I��!�(����Z����!�Z_���RD�I2UytS�� � Qլ�p�4�E�"����fkq�H�HXCs�aR�"�����F	|#K��Ci��mX,��Ƅ���2����#��B6sJ0�T��Vɟ���GK���߄��<߂e��w�t)C�M`���J��#���j.疵^�W����p�Nc��ru��P����IvX��8���oU۫��E��@�'ɛ�r.�,R�!����"�b:�Z�,ܞ�q6z�|���� y�mQ0�R� ��O�� 툓q)2s�+�MxD����~�NQ��8�/q�+~&����̛�(��C�@�_j��B��Mޠ��Υ�%e`��S�z�$���S��d�5*���V�P.�=�M=�Ɯ�:�qG�Ђ��ڄ@����5���B��%�v7����u��n����� ���RD��7lR�4u;���P�g������_|����Nw]}���p$@*8�!|}k����#��21ҥ��\p����1�5L�Z���ɣ�qi���4�� [�QRf��=H}�/�6�w�/Lzz����+)ጳJ�T�ɨbP�x�R�ڻ�mQ�3-�<^���vjѕ�E#*��[���še��)�9x��V�J< D�E�����C��z�]p��w+%*�"��9���<�O���;]6�����T�h������>�]�Zo�{���$j�@'��/�F~�:�Y��~I�6ݷv{9�t ˤ0��{m��j��%����{��mW"��y�<�M�ܰ�K��LqR#3P�@Q��8�`^\��G��Ɋr5���-<A�L�)mA�,���9G"�,�Ut��J�'�C�Shx���A��^F�����u�H��gY^�(q��_uN��Dy�E ����@*<�JP���~0 C:.@�t
�Y���OͥL.����pب�%�Dd��dPF��:�-����o<p��`8>Zxjy�LQ�hieX44���]�"�y��,˞�Gl-�h�=�W�RO�r�5�k��%�zw;�ZN��pf6�Z�Y��[R�]�Ѵ��+_���s͹�?/~'�Fs��&��&WZ��-��rۃ9R���|�s�t�<v�-�zP@{�+S&�X��W��e���*!�]^����0|T἞W�\�6s�h���J�ZǪb��L�q�v�!t!vq��x	7����TJl1�������^H�@����Z�A�Rl�X#�0Lw~�=��*�ӳ� �7']W�vi���[e��� i�A {�X��]Y8Z����p�k��Ӧ*��}st?8�����9ĊN7ד��V��/��B�r=!�+�WXK�%�@�(�H�[H�
�E��ش�cH�x,�od@4	�Ͳ�7Px�
(^f��F@�.�Zο�=%�+|�����S��8��=���@ߗgZ
�<�i��P��&_�O�*̂����b3B�脅���BvC/Y�P܏�O飨~�DT��<ח�����X4}�����l�¦J�P�g����gG�;A��8��^�eg�e
^��\-1y�kҜ�r��jS.gQ�����C����Cu�/ġ�ꕹA� Q��M�*S�"!�=gFU.�Y�r���Dx�a0���ō�Uޏ<Ю�T_�t|��9i����S�V��9r�gp�<��[�[�b	3��v�J;O����}*�������9��P9�+�s�	<��-}'A�Q��xgK$������(F��<ִ�f��/NH9j4P�s�1i�pof�x-q8���W��>ֿ~e)4�8��{�npP�G���g�6���r�r���"�����n���5X�U��҉�6A͝I��*�ef'��c���4�[�إR��0��[D���S_�����E�DI��M/���1�i�M��{���\��2��g)0�6Dqϳx	���\Mȵl$T��=9���4�����ނσ�5(.l�.$X�Ѳ��Ԍ�l��b7���9�i����Ij��q׽�4T� �a_D�����~��4K�`�#�^�G.�r��Y�<ON�,P�需叆s�8 ��e���]�F�j�*A�0q!N�I�_���]T� ��N�����y���^�r���Oo�3����e@�}�-T� �E�iR��ʶ��\����#V۞$I��AMc�ݒ�"S�Dldrp@Q>,����x��	N��<~,����ua{��ϰ_�¬�=��Eo)�@���$�A�`�DM)��sZ�$��8ڱ��B�t?U�<�L���xK��0�+Ş?�i�k{��:�_��=�:�G`ҋBxDP��;��O��e
�`��>�o@��v{�����˛��ɕ���.�o��)�B?�z�{�<�� G�!�\	7�D�L�ܫ1I�SiK�T��������؋1F7{��Q��>հ�0��E��g���4���&��!�-�W�J	��}�������P���8c���>]�u=����펌�6��v��B*�)�����9�y�ˇ���MP�H}�5D�]�ØL��7_Cw[�
�\�����&��-ĉ�
%���f>s�rɇ�1�E��}�[���"�������۔m���� ~���u��W��f�h8�;+��i��j�^,�D�-҅x3�ď_ʇ�'�$������	O0J؈��7�c��}���5)r��1?h�-}L�$��ؖ��zVr�7�킮r�D�������#���'mr�H��zO��z+�$�fSC��p��ŭ�\(�N����Ad]( �ƕX��l9Y�C�'$'p�:�z��& ���6�X[�� ����m[���͔���9"'�<��b��������JVt��Xݦgg>�����Kì��中��h��aK�6���~p��O5��k?���2{(�њ��s�O����{\?��9Au\,O������=g&|�ᅺ ������G���������vI(Ԛ��CwX��U�(f9K�/,o�xoB�bR��w_R�}g��T��q����3����v��5�5l��V�訷���������0Ґ,����V���njc��%����"�]\w8�r/�پ��6����@5�0�k3kK�]9�55��A^��La/|�X��C�R��2%�q��\@�_B����X���Ml�4R�YC!>�C��@�)zy�	�Җ%�ɹ�(���b�����y�/��$���i��(5��1_A�Rt+�n�p*:~XD��dh���,�����4E�U��_#˽}�~�s]:���G�0�d�� ����s�|��|<�5�v�7h�� %�ɪ9��o!*�f#�?gŚ:�W*׋�3F$R�!���4��V<r�2L��Jّ����}[%&qP�r�܋R��HGl8eן��p=�2�c��r!�e�`��D�y�%p�^܁/��H�OY�o�sd���y���P�V��x}|c){�F��l젫8�����锌cC�DY�l(�W������^af� u�Ƶ�	��Q�U��Q
*[��J�	H�p��X �$�o��u2��bp��&��|�L���|j+�����I����H�͠i��'	�ց����2��^�(ZM��*"�^�ozw�����B�G� �GDR��J�X����T����I$)��Pg����] �?\F|<;c;T�T�'6qL��z{b;�ϵϠZCn��
�K,�����Mn[���!��QWZH��w����J��f���I�:��QN��|�DǗ�T.�[�s>�}y�;�@5�hID�U�H]/�*�~�ޡ+�Y�M���J�%�����F�,}h��=OwxugN���E�C|�q���G4��Z�ͩb����Ufi�T���ul�/�J9dw���=~��	�/�
�x�6��I�u�~�/���㪺�T�P���16���I����	�RT<�
�v�ZvI-y	�h��E���:�lh�.��[�%�ڑ�r'B,�qz���D����`�$���p���:/g�Ǉ8.�z�o���<%�o��O��mZ�i@`�;�Jμ��6��[EsZbK7[
gCΩ���h|�'�$c�?�%I*
;�7�v��C!=��L!0	���p<���� �2F%?��v�1�xD�K��#$�=Z�G�%4}�$�E�6�_��F�%-y'?&o`�B+�*)3��+a��GUp
[Z�~Px���-�� ���hT� ��]Q?F\�ZGo�۵s<Bz��B�,0q��p!*ܣ�qӮf���eGHۉ�r��ltu>nԇ<���޳A8Hǭ�J���Iy{?awx�+ڟ���[?4�wvQ�Ӵ�ף<PHVڞ,M�M��^���i �3�'�NM}e��Iڲl��vx�&\���F�_~?3���P�e��\r����Q�>�L���%�� ۮB�jR٠F_hQ�`��-����j7��bMn��'�~$��r��J����+L'��ct��+��@�,����u����g��>����㇜���V�\�7�(ʜJ�Uc:k�k�t/�?8" �������z���I�M0a�y�% k�֏�xLol[,͜y��������~%�F�"���f@�(�ч�4J��x�T��x�"R8�+k���{�cѤ=K4n�a�"?��"�����D@zW�-8՞ЯRO��q}R�uZ( (�t��V�[�&�q�|{B�������Rp��9�Ş���9����햷2wc�E"�38���6��I1\���[�D	Ū2������4T�:f�Ț$߆l٨�T�hӶ!����U�7��N�q�T���W��� �tE�"QuIc��ñ5J�!��@�eQ�p�ɇϸ�� j%Z��.A��nf��A*�<.ĺIdظ|y>���|�GR�}�Qm]��{3XJ���T��M!��*��[�T��L����Y�n�(�U�,�S�
g�v��)1�_�_������38ľ������>�d=��PE��-l�Ct���L���ܘ�x83���6#*!l$�! ��nXqMw`@�9��551�i���+����W�F�V��I�4nኜ0���h�fܺ4�ƛ��4HE��̻�?'�2���ў�&-y:�j�piD2�5�"SH&[�}(�a���B��<u���Z"�X��T;w�K��v���٦k0���[�ӫ���ݖ��}m���a��P�<.��[4�fP?��ݡ���ŁA����Ĝ�^C#�Ln��d�7UYC��6�/���q�"�ǝS^>��ǵ��i\�W=�P�t������^�T�h�8���=Vp�਍�'�q��S�O���)�JP��sTy����wG��}8�/��i��$�J( R��@IZ5E9��Ё\���y����� S����3�]���H��(�y�� ��Q���Xu�oK��	H�t��H�fa6r@�IZ$��΍�vS�.t���RW#���P_��8��p�*��y�+�52��@u����o�uASA���¦;�!����`(�9w�ˈߵ]7	�6;�i��֗?zb���� ͦݿ���� �����������Fژ�iw��]j?4e%1��)����s�&I󳛈�^��f��i�К�N_S��H���NB�1�o���Ɨ�e�ʐvy�*�o�R䞮t�v���3A|��Hu��E�$�����eݛ)�MI�����U��^b�z7ڗ	���5F�o��KL2%z:��G.����������ۜ���G7p*�D`W��iwOk��]�O����˳��K���>�+�Z��f1OD�V���v�E��Go�^k��`�q!�V�Va# ���Y��'��N���ZӪK�G����ɾ�6��f�@�F�̳���XNǮĞc��<g�F��R�0�^��i���w\��l��^�ƒg�?�H�y��_�d��9ʤ��CD �Mm�"�/<�"kq@�)�J_]��S=mn��k-P�ƺa��Ԑ��P�6���I�扬Pb	-3+/�«��<�P��K;��``4!�8���n�#�J1=���� �SÍ�1����U׮�Ϡ������]��Dr�{hm�I1�/���t���HB!&Hי�K��|��@��VH���	��a��m����W�D�+�Mz�|�N��Wȫj�{l8�Ú�#�[rB����|�+�)I�,(_f�("hI��E��A㾩��LK3����/ b`b*H�c�Y!b�A�A.�28"7��t���+ٱ��xG!~���v�^ ��Z���u�}6��j�a�)���(Vy��$�>a��(2-�4f\�?�Mg�u�>U��u�ZqG܀4-.9�?�kr��!�p��mK�f`�7��`�ϖp��)8)sb5�0����k�.&t��WG���BOnT6e
�����F����&�G<;����$i�藊m�@]�³�.ef?�˔�<��� �FE ��t�S���S :!���s1KB9������VBNJ[�LW(�����/C����v	�Nn/�� ��{'<Zp�i�r�h-��Fu�E|��Ǻ
�W�2���]*�4��0�Y�k��(4O��P�{PY���J��=|���A�>��{�v"N�9��"bjbX�WA	j1��t����"4�����æ��|�"o?x�T��;o��n����V�r�)DI�X!�s�x+Gh+�/�VD�WF�-��J��Z{����[d�7i{PB&Ϟ򭫈T��>�Z�3�$FJ��6��XWu��Q�0[��F?å�Q�@�;����J�!ܵ��J��H_R�HҋʘA�r�7���Ag�J�w���K˩-���b8♢�Q���M�3×��,��t�El���x�G6�*��H5+˒�$���C����ap�g ��ec6n����W�P��<���!'\�{Ǧ�bۈiN��U*w�fvl�%b�(¯Qi��h^���Z�&�O�q�3��3�Jp�,� �f6��gSy
����8,����Q$�&ԙ���`*�7SE)���Cɷ\n���]"T�4�e��OSN���t�n�~+W���*:,�fׁ����=�C
����O�*c��=�`'�(���9��9�)$�f���9�#�i�Y�`�B��S*y���2>V�I
����O�D�<��e'�Qd�4�1��zD����&���o�-,�Q
5D�(l �ĤU����҂w��K�j4)M`��(K�v�R_g�~|���X����ѭ	�{�h�8�VL���}�/SJ�6�L�<R��~��i����������뮟����n��Eu#kN���㦎���`zY֦/Y7m�-c�0�>48���k�d��{��E:In�9�S��).&D�{�¿�ɜ�hG�[��I^��4 ~ko��pq�M�FB����E�B-��|�S$�,_j��;�I@��2����oI}�x9(��؟Z�,4v�cv�p�O��Q" i�e���9�b0�M��|��Q�-�c�jm.�kY(����*9��r�% Q<z �y'C�%I�����x� �a�+u�A�ە	��DR�A�}�uI��V������%��0d�� �^;��0��VMN�d!+�n��	�Gp����&�^��K�&Y��i�7���^�-�
����m��{���%�In�B.z5�(��=9��q���j��e��::3i?P?�*�c��2	�6����p�A@K%��ڗ;Be�ҍ��8z��]�av�6L{Q�Y�	����,xr������SX�SXݡ��P��I�A��o��Lz�׆�|MuB�s�7�:9ke�՚�{flz#P����B�U��ҳ����I[U<��,$6kb��f��v���gi�mjGu@�V<�̅�D,G��=Kp=0��_���׺�p����ȗ�1���lL���i���!\E���,�-����;w��{@�ӰD�|�[�[�w�q@������咔һ�G�y���4$~sY8wq��\taS�`�UY&f��ޱY��.������ڻ�%�R���ɰ{$"�ݡ�̄8��I,��HE���RӺ�z�wz�G�-��֙�k~8�#�|7i�4,[2#̫d��N�k\�ӡς�*��k(dK�w]���m�M&���5�]��+Q+�= ��{ �S~�ٴk�2�g��;��>~R�� �u[l-��.͇�ŘWh�f��}NJ���}?3���^��3��PP�������s�1�*j]��>[��fb�|?A��
V_�͗�=s���xe����u)��-/6�j1����{0��D�w�/��`~������A�]���x�H��ޚF���q��.}��T��)و_vL���*����ONqx�ĥ�Y�ѠK��J\p�� ŉ�}q����X�{��������Α&�Ka�\�_���8�%4�(��3�������������u�_ms0��v6�b6��]�8Uc��a��Sc.*�[�#��ʪkl�_��Xm���	۰jEcD�!m���0��$q-�����&Bsɻj�U?y#ܗ�-POk:��4�(�G�m�v��D��g�z3].78�
�t�2�A'(uj4�&�sp_�1@=�T���w��]�.Z;i�U\�KAV=��<�� �T�-9���(>�2�5����z�,��*��0��t�,]�0P%��GyVZ]�ܳ�i+�<q�}�;��H���Yj,�����$g :<&4�Ԟ)?�?��鏢�hh+$O>�I\7dcc�=YB��,��J̞S��_��/��L���@�3 �� �gs��Ӽ��I�q�r�t����L��R�U��pwk�WO�>6b��E[�*Ɨ����~��nـ={���3�0鐫�m���G�|����t�y_{��i[KH��T��s�P7�Iv��g:a��L ���:��u"�/(#_$)y?���-���!�ڢd$-!S� >m�y��o��Nt((�a�����I�#�^�?{y��^��<����WNϹGb�D���A�F�PnXur��Tʡm�����#�Pܕ��0$�ؤZ#�q(ϊ-�5*][�U`�<�3�"fu�uy��H�u�>PJ�C�Dg�բo:��9MOZ9�bZ��гmi�e�B;8L/�Q���ܳ�n'b	�@C�k�O��/.�Xlz�ɰ�>��>ْn���v��\�J�&r�`�K�d>��;q�U	��YT��$h����}ף�ﴍa�~�� f��J�]�����U�e�Q���F����:��
���)W����zq��M��B'�����-�ၢ/~���=2YGo-���7�V\UF�!�\a*�@�.i|�G��KC���g��4�h҉��(��|��-CcY����@8!m`bO��]��RBR������ؠ",�&���](���n��<jd	��@2xZ��I�-ev�|g�#��J�r�}��ω���W⵴@�{�^�Pߎeǟ����ڌ���2#�0�gma��l	���@qP�����YР���+��Âա���xl�-��I���)���@���ST~2��<�W7Qvv�_���H�7�y�l�V����WW����e�֤(m����y���{b;HRq�s�ߗO$A�w�RXd,�n����3�w�ou�������+c��@�~��	���1*�����RV������-�w�p��1�P��z$4�]�Ђ��DL�g�|���;������&�W|�D`��鸭|e���n�w��"1F���9���VXL�d�'�_��~��}�q�̈o�9�����y#IJ��'/Aܩ����:�����&���@'N�ߩ?=ܜM������p��B|���xw(A�{��Q_N�s9~��[QD����p�.�)���V5�}�zU�إ����첦�=�0����M4��>���wl�f;���'�W_b�`��l�����g�c���ἴn��t�`��۝�@|�l��*�F�J�0�n���VZ`�T�h Mһ�Y�����`�m|A��KH��3�*j&�L�5^Cp�?�h��G�N.����J
�i�������wZ�#~.��#�гp�a>A��e؊��o�j�߮$g� r�*'��_�nS&P�Mڣd�knp��W�ͻ��k>�I�
5$m:dGc�i��Q8�9gP�j��]M��,�Ҕ���ʄ��z����A�[N=�(��[�(� 	�y�f�	��he��ש#��g�V旎���č���2O/�Sx�4ը+�5UX�{����c%��]�f�� ��B�o��j�3�^#
-Pq4#Mj1ϛ�q�������B�4�?�4{�
7<G�yQ!�ٕe�^о|C�з�]��K�����ES�Ǐ�G�}�]�P�q�����,��ܜ�h�oH;�b�6�p���@��;�Ctִ��|�TfV�6�+�<�0(��&�5���6�i��kf��j��i�a����g�� �l�٨�)���^��Lu=���g�;�s�>��/9�uL}�U���]�d��k��0W�?
��V�mw�����PI�~��ܣ�(��&����&@g3��u|2]b���)ɛ�/��©�Ӛ�dy�M��."�S �c�c�M���r�-�>%���4K�wm�`��!����C�	I��lN�=���o��yo8Qf #���$�{�6��-r�`+1&j=�|uq��o9����)�-�\��={(Z�.6�h��h�Lt�X�p�t�Khm�pK��������P���P�\�[��<��ai���������6��.��ΗO?Ha��-t����h<#��pHIL[����ǧU,E�^��U���@9}���|XUJ�٨��6��������@�!�?!{��!�R�KB�A�nmy�%D��b�kUV�dr�����-Rߏ����d`�Ub��ىl�Z V�$���E랊z'g̷D��!�+CL�VϦ�nKX��;�m�)Z"!v�a�3ч�D�v
�1O]s��.*����᱾�39���T�Ϊ�)����
�wn k��xg>��l�(�p.U�oZ{8|��֌�`g+�����z�lA�\ՠ�b\�%7z�~-�y���5<�h���h��<�;~p�/g^���j��9�!ȼ���n6�⨯�tB
���rxW��߻��k�*�)�nex���Ƒ��䵭d�F|�2V�IR����Į���.@��4Lu��5�(Ȕ�H!��\��C��(��?�M������q�ӛ(Ŗ�Q�>�#-�ӽi4�n�..8��m�H��?���ZIn�߹��n��ey���'NV،�64ź��/)a\i��F�Z��;�H1��L�_ó{��(��F����l2�~�=K�L�^Ԋ�'����kW�{8�#BqaD��.`����bofU���a�rƎ+��7�*�>ᦅ�~o� _f�S��\��o�61�2��&�q�����i�PΑ����{-,��ә�G�H34�p�A,F��k�����Uj=�~�<kyC ���l�u0£:n�i�=M�6�����V �>�	�VE���ȲU�yz��#"�.�Bg*�uE�	.�J'2�yP�1�y5'��[j���I�.ղ�a`^��X�t��u)�"�H^���R�T�)c�Q؜�d�uw����������a�T�gƧ%�;VY��D�z� ��$�N��o�d�"֣&>8�N��i�^� ����+��k��]g�*Ԗ����ƅ�GS�gOR=6/�	5V�q����@��C��|z��Q1�2y����` �A��c3��Zt:�^���)�^?!@!Gt�JR:1K�Ӣ��t�8�x�R�
U�K J��^�B�H_�Y�;�Qם"�L,�/o��IԪ7Y�b>��Z� ���yv���tI��L?�� kr���
~[
�]G���F=���N&�2�� F�d{���ɿĜ"�	�?P��W�	S��|Y��Hņ"8���W���l9�G$+�'�q�� n��,t�[|.���A���L0ʽ]�{i�ܹX��*�P[�ʗ&�d���=D�����i6�P�f~��X�N���9V5��[�1I�9q�H��0��㔽hokgixq��%�'�dA�p1��H�]����v�P��������]��"N�R���u+�/L��W�ZU����~�s��=�ݠ����7�f�W<�k+��`9�)�-%���wS6���:;��+7�n�	ݗ��U�����Ν3g��!x�݉A�P�HS�Z�	c��+,�O��p����5II����o7
���b�V�f+�u�  z��gN�� ��������g�    YZ