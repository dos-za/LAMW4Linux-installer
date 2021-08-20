#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1450613071"
MD5="b53777396b2796c8a985c19ff756dfdb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23564"
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
	echo Date of packaging: Fri Aug 20 12:37:06 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�o�~��������Z&wE�5tLq�
�l��{��vg�Wͅ,��Q�Z��{D�ߎv�3wq?�_�?����p�=���'�u��H�M�˲��*k����O�H��:�ev���и7e�8�׶B���Ǭ��^��l�Vv=�PO������!,Di��
.�bE�V�P���a·!;>���TI7=�$��z*� Ab{����T�v�Xy�2�'��Q�j���*��\LB�Kie��g����^됊����D��	������E�������f�K�)�v�r%��9�a�N��*��|S������1�Q�$P(V;$5�~��Q�(9=ZV�`xO�Z阴�w�ʨh:։�j�Y��3�ΜA�i�"��zx)��F�;"T4���w��[Z��ufv?�)+.� �?�i6`�情
��T��l�g_�Qf�^�}є�c�A���W�S46��a�Ng�� r��(�B`�u3A=s[>�U��RrY}(oᔞ��imH���lǖ�B��ê����zx<[��[ ���yT�Y��$��0M��&�U}���OxΓ��s�܁Ų�/7�t}�=+����#c��At��U<��.
Ղ�E:�&.�}�V���,�T��Ņ!~�R��x��zu"��]Ҏ�Rt�+�K���O�`�`���\z��3�����k*BR<�8O:�ڞS��M\����-��˗;�)5�.�������S��8!6�e �ϕ�Fz���y&��d���D�lkw�^1֔���l7S}*
-*p%�ѥ�//09
CiM�W�5$�U;h�Y�1��7�.�4���܇%���82�l�4�������ā0ZҘ��ڦ.�r�dR���f��K)����x�v�;ֱлb�]�����P@�z�#"��0��sЋY�L�ۏ�8����L2�D�v��Ƀ%
&9/np�,o��8R$���z)�?��Pʮ/`�8�;R���J��LS�1G��b�F{i�ɬm�/���9����b��{�!�@'CVE��v"�� `��Y�Ӂ���#�[k��Oj���
i��[)`z���2g����8� ��[�8�/��4Q}0�v��O�O?��G;;��Qd�L�QI�dp|����y:/J�6,Ky�v���"�3��'e����a��W�|���(S�����fA��/�1U�[���=/�$Iku�k�Ĩ�L�T�T$<$,�!J�J��Bllr�8Q�D,��e2���T�_Df�0��R���]�v%xdd�w�7Ջ�F����a%�@2�B���^�R��~�k�a�5���i�a����5��hKv�5�z�Sl�<6��!}0(��&�=��Q���Yƌ��۸�A"�8n�tW�=S)I3��'-�խ�y �CI��e�&��Ҡ�`�U�.��ԑ{�^14��蝧�K)�N�a� ��C�kE���ٺ������[�������x�|�N�W��.�'@}1:�j�+�i)��m/���x�j�p՗��a�B�ΰ��W7pwWD�Cs�n�\`u�7D#���8�r��t��oˀ�kwH��r��U�g���G?v��O��ov��g���X��lv�}v�*n�!Ӳ�7t��jS����m��LƺJ���X��Kr2?�]t��\�D���i�#���`�V�!����>��Y��O�tN�W*��h7�}s�K.�F�B��|� 60O��>aH���`脏��"�k4�!%И�zI#�u
�ӯȤ7z���<��a����z�h;b�6�w]��N�,m��={�3�"�n��� �	�'� '	�%@"GUד��SR���7e�;<��Ɲ!�rv�{Jv\�	��#rs	B�,�x�m+��4�ve���i�7�ɳ%ez:2����Q�_�Q�.Fkߺ��H��Jk��i���V���m����,[�Q��XCnb9G�D�2�[n��A;���f�m��>ʖi%�9�|�m ���~54���w��ϯ����Ě`�"	tHJ+�~٘ԪP��J�XGW�^U�h���$91�U��Ƅ2:�9�!s����W~w�a�=dH�;'+_\w���+D�u��N���<jd�ɶ+�� ײp�a!���C2־l�Eؘ��d9:ۊ�+Ҏ3&8�u��8�,՜�]�k�A�jY4�m{A,��� ��0��C���~�Mٻa�'����5d�����Yz��"}�ԺY�&��N�����[�IQT4��<Zox��R��k&�!-(b�3��*A�_�	s����%:�$vFO�P{śg�����͕�b�ԤW�쒼�J��K��A)k?�~��F>g	͔�e�M�Kwn��Mv:˺Y@e��u1��耡�`x���ٌ�wihEi*?���oi%l��fhb�Qb�R�; 9FGi}��mm�;���.,�}���j�?r�,s����#]�C���
����N|��'fU0*��!��ٿ��U���Zו<��<�y\���G�ӟ\7K�ut[g���'�D�����Q�|g/�H�4��� �	�]��-��jZ/��q�x����GX�bػU���_֢��g��)�XO9PS�F�a5X�-��%qf�٭��$�
M⥼ڝ�vJ}�#,����0i`��\+�������1U��Vwc(l��6lɒ�-?��n?��LZ��'=��mJB���>����H��(Pi "��Zڇ��V�G�`엍:�U�ABd��LCOu�������H��$j�2�Ƹ��(/['Zʛ�F��ȷNQ��OС�w[��I��P$�\r��p��J�$�h�{����{�*/O �(x���"0�!9
�4�m�_���E�`�|��_�K{�#���G1Ü�N���F�%6-r�7t�O˼r1�%��?G]���g�����Z���=��3S��	D�bֵX5#ơ^������0q�_�yAz[��&ް�Cv�8i 	_�����%���킌��QE�M��e�e�8���R-�.�� zg����w�~v�2b�1lB*dD�zToW�;z
Wy���66�]?#��Ș׍\e'��%��u���vրZ�LN�`_(�ؿgB�-0a����,m�Y�p��_-Q� ��8Uxr�<J�Kҷ?៕<�����V-���&�����ؑ٣��/fpc��w�zI�����lDm�[�մ[���Z��Zv9���ϣ�{?�;i�����f:��e���/,]%���ړ'�Աgꧩu��� `�pr)���#��6)Ƹ�FE��(�*褘8��R��\�F��,���?d�d!a�Q�ۈ�&R��}%í:�����K�
R�����1�����Sr��PM{55M�\��ӛR����tR"�z%�a�c�E,����f]7"���R8����Ra�Ǻ50Q���z^=��"3m`Sw�jzs�o�_�p=�����"X�V�ߌ�N^4:��ZZy�A�l�
=^���P���f�rN�af�8�Zc����UT(��U�\0��n���`4��40��Y��c.�����Q�!�_C����`�:m��M�A$Ϫ�l*G�����)�F#q��_Re���bT�`[4S��S�מ������QQ�*��0t����V~�m��:�0��H��Z�8��*�]�����0|�ۖ�6x���P7+��!㎔m���3����:�W�-4]����J��a��W����ß�W^q��:�/�e��X'�Vي."Ӭg�Uv�S�֨\ �7�W:i�R�[2�d�Brُ�6�PlM�Z|"�3��MD�%q���@Ё��k]��0"ĉXH�C=�7mR;..�M5�i12����^�3)ɪ�����k��u��86�ճj�i��i�h�,����-*���WЉu�A�#�Ȣ{ӽ\���:���1[kC���ɍ��`�쐛˻B��	
���Fȼ��G�)�+��6����п���1ѦS��gކK��G�3�覅�ɴ���7P��Q!�nچ�@��ٜM/��:l��y��ڀ����m˗�26�~xi�㖡�����1��g�E�td�m�8&���Y��f5���aq��h��1�%���iX�ƸA�7Fqj�� j��0�Nw�[�'1����p�\w�1|�[w��Y�zD�i֤F�9������Eð剺���ʜt�@cA'�T1䖃�0�U (ؗ3���EXg�ם�ϡu�l�X��%"�Z.I��Kҁ�����w }�y|�_���O�z���j�|�"v���� �����e�!4F�F��/XqI,z� �濥�LO�Es����)��H�\LA+�~
�E��-HG=;��F\��r=�ߥI!!:����A��ep�Ȇ���	2GW������G>�;��̡����A�<'@�U8P�8=�ҵg"4�`Dz��,>�-��y	}#��5��nHA=�m.��� ��`Qy�/M��5��U�X���	VI@�h�֠n�)
�B�V\w w�$�)�>�B�x(�"O�30�I9mrY���m�u�Nx	���#�)�ˍ�&<�FM�ve(� �GK����Г�^	���M�e@|2X��*��;�U�޵��$�g۾��6��HX�����5�GM;�����wq��r�Jpd�|i���غ�h�:���(�9	9>ܒ���>Q/?�$~��\^y� &�@ r��W���^�>����w����$�L�׺y�i���p��uL�/X��=4ΥHzpG=�w&*�f"��i28�KL����O*AXM�˝>O��Q�Cs���#���zM`�b�2�x!��h������.F��8de��N�9���I��kk\p Z��l��,j-�*T�;{ �;�s����"V�c�1�a�QZ0��Z)G��h��ed#%���*sBh>I���	�b;��^;FR��Q��[�T����\V����r�/f�?}K/´[J7�'./�p�Ɉew#$5�!]���V��_�ݥ5'�?c86@vax]��pԅ?����ŷ�P�<9#����䦷�K�:�?���Gb��nDW������zc��8�;��w����m_��O�^��>D'��v�&�U}p� W��]�B$�vH<Q�mLƩ	��0��h;����}40گ`:�cH���╔K���)M��Q��5�Q�Н�^�c�f�����+��%swH����?��j�&�{a"���/,�ƪy7U()��Z�B�*Z
I+#��U�(>���Ȧ���������?��<��㳋�E�n�ZSF�<Ъ ���?2�>�����#th��ǭm�E��Rʶ~m��,^�Q�J�^�F$��:t8�t׏�=��7d}�"x����ZȺ|�V�tpe�K!Z�𯽫�!��q�ʌ����W��ÃD��%��G� f�su.��}M����QK��ۀ�� ����4�R�j����E���m��=�Ь���\�6?|v�i^�T�sk�QBLCZM\M�ri�OC�����d��.[��� ���5P�؍֚�t}��t�\$�5���� %�#��	���� ���LO9�36+��Ғ]�-�z ��z�A�\L�H�g�@&D`�����&b��v�䳛T�.J�r���R/h�/�C:��-�B��-&k��,�q�/�S���)�W(M�a�|9dЋ�TB��(��S���������Nu�ވ�t����2C1<�բTzhCƌ��f,a�}f8K�1� �/�>p�Ԑ�2P�d������h�M�-�>,b�I�h3����w�q����g�9qo����k1����V��:+ʂ�|뮖j��N�CR�����J�7�W	���S'@�Ѷ�P�4�����"�a�)�����L{&�A��Q���Osl����^�	�qr�V,D?�H΁L�_�4�$Pi�@gW�k��v�MCF��Zsߋ�.Sw�E+�)�u���Ʋȷ�0�U���4������}���S�Z��k�b �����-�Uyr��`�?=�+�M�i�h����}�
��
W`��,������9�4�x���-�.Q����7恓+������\b�z���%}4��'�B��Z��~1ܥ�I��ed�īɜ`a��F>l͸�?8���@��p�f<�� {�{<��Gea���5㙞��-�'�@yvy����ڰ��	o}:�\Qޛ����1�X i�=/'F|eW���9i���v��,���W�L:[$7��{	y�������/~[���36�V��G��4k��7E�S���e-%!��gSg$�7{Q�����{�1�N�fꝉ�RC�=�$q��2��a�$+^?���A���}��5hS�g���iY'��E�X)*�71�4C%�xk��|�e���r7�#�@�<|�xF�i�z���LE�GzqU��L�����4Mc�([����=S��#~�Z�s��.�z���_/�A��q�tŽ|���N��y���.3� 8�]"K4y�ǲm+y�D/c�$n_r<�Y�M&��m~�9P6��*��<�����B�h&U��Y�Lp����r5�� ��ˤ��{I���M��o!UH�����w�D\E�l����U'�4W��k^9<C5�L\�l�HK���E>��h-Jr3�� �dp{�4���RU���Q� 0����%�Ϋ��a�:��B:��)d�BN��?\���54"��/dP�XV�tk��c	�'a��������أ�:;��(�A��Ά��k�3?��f<�����ir+O��� 7W���b����:�B0�f�Z#O]��se��"P�΁D�_�M���Y!?����Y�n� L�Cb��+�틌�*���OZ%��]����e�F���f�%3H�/kV�=�@�3hh�����΍��l>�؃V�4�ۀ=A�K**�&��>�'(�7���Ʌ�e�m�軬9&i	��8ݎ%�ր����2x�e_����A8�譮�,���T�K��^�ؠL�RJ3Ý�����wH�v-5�N�r��_Ą��d�6�%�x��54�~u�����^W�ͽ55\Rj �e5�kw�A��/��믆^q���5�2$����I�ӵi!���/������4ʼ�ʎ[q���=���n�v-��إ�bFύ)����,s�=Å��E�a1�t�����Q�M�3S ���!�ZD!�Z.S���]�:�Z
����m��_���=��)�o�S褘fj��ݰ���M�/Q���\�p��%���"[�`4:�Q�=�1ElWY����F�/���TrL�sΖ���^q̗�[D�y	TY��?�	Wu��,�]	ڱ�EHk��΁�xe��j(j�mi?��W%O6�y_k�h`ѫ�ִ+��j�7�r��|��i2Gj`�����vle�� ��T�Gf�{"dq���v�&��̕S}i���!�6���("*��.��қ���!\0Wz�	�O<Q^SC2��϶5�K�!�rB۞�_ki�v���G҃w�,�Sņ20A�Tq�T�,^ս$d'z��鐢�RG�S�L��$�V]);��6��R�������q׻p���h�@K��`<B��;���r�R)���1��F͵Eo�Q�BXfP�PJE��zA�2��=�>�h=o�*�$,�Iz���+	�w���m��+��̌K����q�޺@�Ɵ�ר��`��.�ي^'���lҏj�u��6�4��V���b�q],�@�iUt�v+4m�fAΤ���l�i��[$����Hh[ӎg��)����\���C�T��| z���_�H}^%��p	�Ve��q��F�M���9�S��{�
�y4	Ȅ�����K��VDv�@�|@����M��]�xZ�8�:��!\ww� �$b|@v��S�yⓌD�zM"��ZD��	CE�̯)�qȓƿ)�� ~�˗�D�y�ò����SOl|���5 ~u�b��v�-?#�������dLޱ�HJ�[<��#S7���B�����E�(0i@���&�X�"Z���L�����K�OOG;�k= ��2�ֆ�n1y�*�O�i����?8Kp#[s����bb���uR���u��Q�ɖXCfk�S��,�jF��Ǽr^�R���CvM!q�1VJ"A���wX?
��HsB���5*5���I��,�\b_�!���4]@���,(�q�gf�'��z%.�e�'k��(S���W{5!Q9h��کH��͞���)�Ya)��WKz��B��hY&�X��1P�)\�QÃO�h�����H�\H�#L-�.��'F�M�d��E����j��N�U�_��E�1�_��tfEb�iӲ�C��7��6�X���k�Mʔ�9V�|d�ɒ���Xz}���2��ҾA����X��%�Mn�m?Q#*�4���1E&�Y�}��1z��W�2�t��A	�qĆ���B�4�s�n�"+�<}H�5�ї/'�<hY�;�Sb#TgHd)��XJH��o��>Ъ����{K��J"L�*n���B
�R�S��?Q���3�$� Q��v��YɁ�t9a���j��[�R��<�@�*���e@�G�ILy?�o����F9#����2�	�b��NڿR	s
|��HV���B&���f䈡�a	���$x6m�\�щrݪ�(�8P�_��+'x�%�ފ%�5�
���K )�u��gԒfi�<�����52��>'L8	2�&�i7�㧡�恶�`AӊH���I�ݓ Z��v^I�x!��7��mc�Jۥ�@��f��Ԝ&ٰ�������'�R��H֝���+_(|(�0Ҟ�<�wGp��X_��8-�O��7�Do%�{�f�`�ũ�������S���"y$���k���YQ��~�(�y�>��1��Z<�,�Lr�p�&��uM�uu�\%;2���4�f��q�t_��:��{$bJC��W�G`_b��!���؜�*h�hS�q\���i~?���	����+��tI0B�q�����F#L"Y!"���Zb���Bf'�aT�$PϪ���m.k#ϯ~B�ɕb'�m	Wœ�iu��Nj��ϥEf��؈#/B�IS�Ջ��S:p��?ύ��m�8���#����-��=E/�n�7!�Q�Ok{O�BB���9�Y�Kt?��b�e	Q{И�#r�*�#�_.3�c����<b�F���nN��m�J{7�,��d�`M��C�����$�,���~;]�:�C/O���}�3��k	��N�����"}'w�v�I��vz޲�1�>:"� v���=G��NX�h��ݐzɳ��¥�Cѭ5.Ȳ���I�[,������D\�|�3Ni�W�yΕl,FG�
�ϳ�3��&�ֲU��Y��!����+�7�Nn��]eZ��������D��*Ly�t$2r5����"���G��e
�C@�Ju�\�Byf�=���n:�=�ii�0&8[s2@��?�Zגbb���]�Q)ZɅ6k�JU˭�x�����K�}Ȥ;T�tE���?ɨW�jۢ�"����5��":���S��Q[��bz��t]��ڬ���Y/��gQd&bL�SG2������lN����\Bʂ5"C&N�᷈���|r�1F}����sx� ��@Q�$��F��
���$��~�Ь-͗-R$Ǎ!��K�2d��E��{�����e-T�\������<���$�\���G��z�j!,���"ȽXv�*��2�'�EK+8��W�#�'.+l@(^�m�O_o�r�k4t��]��9�C��2G\.v�N���җ+��DZo(��3;Xߋ�u�ۋ&�;��w;'QRW��۫���u���oM���Q�<�����9�2�w��Bs��m�/``�/u_"�5v���sR��8�Lý�=݃������P>�FVZ��ˆ��i��r��i���ܴL�%�|��Yh�7]X��i�4hW���œ�M���Bݟ�5ȢNj�S䨋I�G.H zIV���uZ�S�F�d=��jRx�H%�W�ӵ$9Q�_}��8Q��K���&�:�ʱ�'B�,�Y�}2zx�
zl随Uh��5��5�^3f���'��:^�3{d�T%z�zh����3�m�����N�"�q����W,���_C�X��o�6`2U���7�Mݒo�CA q��̹���!4C�f�\�IZΟP�ؔ���=/���J{���,7�=7��4u�hS����<��ωG$��h�K�_B��a��S*��Y���g��'�O0�� ��$��J�Bb�_�r�(&�d���7yn�f�ڎy�
��.~��h��ʋlb�7`�u�)� �m=t/�p܅D1eK��/i�OZٺ0���|S_�o	��`�|��7n�A�.hdP�E
�����X����:�F�[��� X%��N"���?T�I��Cg��|=�6��>fq��ߍ���x�~�x�Ж�B��R(�9Ja6S�$������%�Q�r��w#Z�Wq�iZQ�͹��^�9g�83��^��ԽBw=S5�T�\���������"�D�	�P�z,Yi���m�^٠�#~@v�%9�䜝����{{d�r�h`jH�����݅H�>�o���&ܗ7�C�h���d����!�&1@�5D;_4�~��<���^��zEC��e!��v\�>���׏��CU�G��>D��wn�|ްl�y�<�:&�����y=qV�D�s�R��9�� �_�,�.x�`!;TQ�O&2 j
]m����+�1�T��y�H�2���<��+`��q����YId�u���e�SOBYb����^��~�4�y�=%�.O~wWm���T�nS��{��](̂ˡ�$R��]�Ј��isݒ�3��4.@�����aX�4E�_P��'a�GS�JQ�\��Yk���r������,ؖP$�8�I��K=Y�ﰶ����Q���6[�պ*}��QL���{5��5�~��x7'$y��ax��>�Ͳ���?�b2P/A{|Մj��u��X���H"���/a���wo����
��~�Y�/e�����T��g���Pb�[.���t�P;;��G��x�7b�����@'$��}�lIf6����I�3��|�q�K#y��!_W��I��NR��i��� cKz��}.���j��OT%�\P��3�hn-�xcMj�nk촴�\�l)�������n�Wy�~�������`L$Zdh=$ D�;����h���oИ/l��=� y�.����'L�S�y/6_�? �'��e�G*��z��.I=�)֦<�C[�R�N;�Ţ�p�&0��|>�_p�v܇[�B����r��{0����Z�G�}���z��S�i��ԣ�?fJ�<)�L]��@pøu��W���Z�A��� cwS���-Q<�9�����a�!��û� ��f�
�����pɬZ����:1ƈ��J���E�d��Qa�z�ۿ������~t�0��������)V�� mH5�L��;_����M��VJS�w��5(XK1����NMi�Q�M@�7:���#�X��z1N+�	G���ZN��:��-��g(�źz�І֦��ە�H-��2Na�d�Hu����a��9���i���-Y�-��/quo�4eB,%�&�:5Q�t�Z���/2�2w������-G々U�0�H=Q1"��zd^:�g�Ω{�xqR_�APǭ�l&��!+�����W�Q�ǡ.�ءމ��+�.�J�ee"K<�k^�SL�peB�a�r~��Uj4���\�+V�@QPĀ�̽�f�$1B�����@�@�a�����o  m��qĢ=g�z;d�����5�_:����!��Xs���Zo�+{i���lY������3/P-Ɛ�k�m���s��직��1��.o�(��<��2 +�\�t��6Uu^݊a+�qG��4�&ٖ吗G��W�x$��*�z�V����t�閿���:�[#
߱�������FAp���b�Vg�/_�����*n�Y���Y�*޷?]i��=�$X]�9W��O�~�=|��0u�V18c�t1�c�F�FH�e�J�o�9Lߘ�3��{3q�e��z��B��q��}J'57��p��q�8��~�T�z�Ye~�uل!���7������v*��Z��)��V���Zm�+���(m�Bp8�����d��ܫϚw�:�r:�YU����ܟU�7�54������/:|~���F�@,��s�R�(.Q�����PDw��B��`��t�����\���OpA<�J<D�ǓOt�5�̙��&��7ה��>>����V,��U���6�6a��%j׻�	LT^�`�|���V{U o�#��?�7-t��}�R��T���8I�Oh�n䗗�ZeL����p^�\qa���͘��^3��a=�k��W�[N5����R�������nnݧS� xk�y#ƕ�H��mަ�zC˳�]6�cFL��~Y#}:S����1f,N6��֕ ��,5�pNиς6�)-�5���n�jj�3���χ�PB��K*�+�K�_-�Yi�@D�A{�rM$��+�0;B�'E�GB<�vUUR�A�f��χ{K���1!Q}WL=���dȳ�>���i7łV��@%��WB�������x��>>�ri��>0H R���)�6�T���I߂��u�9���(2vT-���t�l��囝��E|��3F|lFߐ@��������������6:�1`�~[�dܰ?kqgN%5���D�>BA�wwY?�R�7Ro�WfS�\���I��
�1��Ě�p��Q�Nq= ��w}}xM"��}6ctn�-~!ocV89 �	�;_�3�yUp6o��q$�]hᾧ�1.&)\V�����V�ԁ����;��W�&j׹[��FE�t�U7!:�)�3�J���.����LK;����W�ÚMݧ���"��?�6DV��K������������]����!QY���a�Q�z�f����x%��NUj ��*�<�����u˰�d�܊�� ���sך5mP:�ᓔC~h��%"����h�A4E����A�?ZXJ�ў�*Cqe@dU���'���A�R30j��D�jPU�q�V2u�m�d�-{�+ ��������~Z�* ��]����䏧	k�=[&���l�C�z�� Y�<Lt/��Y�����=�(1[IgK�d*]����Mɩa6���qm.3���\&/0���">���u@l��
���Kw�J�|1��1_�(��u��|�i^j4���и���P�U�^��[n�+e��|�-��F"����pt�iޡ�9JH��+D�\n2)������V⤄jҭ�9�o%�Gzf �;L4��/5 �9<E ���"�.͒i�5VLUer5���.(���)��K���������!&��>QA Gw�+j�;d�̘�QЃ7G������c�?��c���㉍���>�`.�xxO�r�'A۔�o�*�[���c��ѣq%�A�l8^+PH��LQ���RL��kp6�D�����Ė��	��M$yK��zîz�U�&E��ҩ�\���s�Y?�}�<oC
�&���2���T�7����D��Q5�a�>Y9�|��l�%L �f�33jxB\�"o�Z������H\���2����%1P"|��p�N'}~��.��u�}��Ղ\2��Q�n�o���V���b��j�ji��;|g����� �ޣ1	�6��O��D�T���2R0����>_Q0�� %6�U�J�Ѣ$��a��/j�}�V���̖J<�#��J���Eu���x����#�Ot��2k�`S��zU��3T�Z�P�b.ڿ����n~�x�T�Nmu��%d�"��I�7��[�'��u �ү��z.���ɥh�5y���0%̍�ړEfQs��򓩯I�a���u[7Q�q�:W��#k��H��#��U,�
��;-�!X;!�	�n���Y�ѝ�^OƎh�����T;��� ��ʶ�EF���1:Z�=y�B�G5�ng�H}΀P���}.v����!��Цо%�6T�^A���~I�}����3�Ѵ�@,@I��~��P�X	T�=	���}U�k�0�#ݏe:��O�2q�2�)2[�ì1�g���Ag*\���ckQ�bM�eN���)��Y
D�V����M�G��i���W�~�v����ps:e��J}/��(���mJ"_l_��iL���D�ť�k/�9+V%W�~.@<~hf���G�,�T�^��\�q��ŷ�Um��G��l�:b��Zp��D�E@��֔��exң�M,��kZȑk�B�N���S5k�=��B�?���	BY�s�0%�V>�?�xMKHp?�K�'RB&�s*�)t�&=��V�7���O��8-
�����r�=�"�)�e��pW{�M4���G\�jb�O�Jj��c�Az��P
h?�*p��W�tA�
��]ԧ(]�����.lg?���^��pB�	*�+��ӳ���s�@�Ht}��u\!lteC�,��u,�V���}Pd,��&���O��4�ԛ�K����,<�,�3�zޗҎ��N�b�@�>&���$*�ŃȅL��e�0����&HY0�}��	����$F2�lg�coP)cq�a�Z۹T�0/Q�1���o�n��?�%CMİ<��Bt*e�v����D1�4µ�5&Ƨy�;!7����\��<�h����7�P����d��b۷b��b��1h|tX�0�C[2W�����M���B�;(A��G��&ro'���+8��7m1gjv����Ƥ�7C鶺?����)�ᗕ1_����i���~~��|�%����Qڝ��qr5s��Bz+s�mH�̜�T@������7��њ�Z�D��j'��0�hN�K�
�\���g�(�rt�G5a��F�V�<+�J��l�;��!��u���C;J�A]�h��c�����{'R���յBW���-Ն�x3��,&���1��,fT���!�ɛ�$�x+JS^ځ�U�ɜ���EQ����XZ�RLs��5S�� ]�Kz�bf���a/��o�
"�h��|Ś����}
�#���̅š���恵 ��>��z"�c��͹K��nM�������	��,BY�*l��R��p����cR!J��ֵ��[`��� q`�$�j�t�4*�}�&G���q��^Ji:����2$C����4�RX�������.�� g}�ń�}b���mY= ����0��y���Zv�E�&Aƭ�I8���Г}�ľ �>�<�����v�lnUQ���Uٚ�#.8Iv��V��4� wX�g��V�KZxz��uT����M�~&�+=0�R!��	�,�<�z�B�X�t"�/4�Em ȆE��d!�N�U$|��Iu�F��0_W��F�h  %�߁E�`x���s-a�,�7�p�`��{�Z�$F��=S7��C�;��.�F�a:�I�k
0%�q���@�ُ0{������t_�)��U��T�0��צ��6R�t?���8�I�C�<sǧ�~rp�fX��u��On������H:�y�����"}�i�P���CC<�c��bd#�r
�j].`[։U��xw��:���c��e�t��[��c�ԶV��Q� ��Q�к3�}��^���+z��y�����%���Ϋd�yx�&��������x�ʣ�cYLB�IwgR�ow�?>�
�~�xI_<]����<�F���>I��3�$M��J]�bJ��)ru$rA{�[�j�,�p#�GH�`!F����w��*�	A�T��]58���=3,�gg2����l������>��1@��D�u�k5���T���^���W����?YX��	��p�K��`����7��/�m,�����z��c;=��p�Ag
O����*��n���,wK�t��J!��m�����9C5���Kb� 'A	z|ϙ�P�]�[��Y:�E�82`�����g�7<��P~���k6��Q~��~�0u�+-]v��'КD��|�}���#���iK����kV�)6�Uy��c��W/8��V��~��N��#FI�C��35kn�$�@e��me����	g���&�z��9F�8��K��zo!~U�a��(�٤�r�Y��/Zg���2�͚lS7}�i�>���8�R,��x�Ȱ�Sy���߉���E׿�^�d2�CEǁ�Wm3�4��DE�v�<�T��sV�[	��F������ ,>W@�w��V��/�2�T%�$�O\Y���}`[�]W��C�%5� I�n��/���u�st)����h纽^�'�Mk˺	Ҹ��Y�ĕc)z��u!����R�\�Y+�|����a\����GI�9��<�vZ��l�]PB�m&8�v$���O�8�}����t���g3H$��y��B�/�l����ja��yd[�������~����q���^{��^�a���b�=0Ŋ���15c�/B�y:?Ȣ�ߌc/Cl�ð.t�e���_q�<le�q|ڇ����+�z���zC���1��� ��ρ������߀	&_�-n���gf� ���K����\ف�s l��[��F��,�n��W!cm�þ����k���v�ٹ)�TcM��ރ���P=�Z�d�W|g]��a��[�z-(������Z hj�Jce+`�v���i;|�r�׸��aM��EH9`8Ï�g�r�2�(c	q����RPp*������S���S4������/֠>�-<4s�1���:-����G(��u����m���m$�i���E�O!��jٍ?���ް�ߡˇ2�R�o}>�h8�	R1�����ڋ�t�EI�׭��U{#�f�x�]V�%:X�b���MV�5�mw��{��^�z 86/�,W�[���	h�Dw�]Yaj���Q'�Q7���HAOK�bgH�]�x?�4>���[N[�k�A�7XK��[����&M����g�!�Ʉ�.|��nX9��А�r��{�4C�z�,���!+%xRv;r�[�S��'��"+t��uX�/�[�]�+�*� ����i�؛�x����YG&r��0�&:1��7��lE���tV�J`��{�T�06�l�t�q�[�;C��!i�v�ϜV���Ӏ�Qضhw�^SoG��>,�C�B��31�'Ŧ�_���r�#ڋi�!�	j�����d7́]�7Y�9#���B��I�|�J�u���&]�n�t�gY/0w��"&��h�㤎0���p����Q�6�),N���IS
u�HS,s��_�Ч��p���S��-�"'��IR��?����:*��	(� �#��1�R�d?o.J"*1�É����)�T�8q	�E������)��Գ<r�M�h�¾�ƕ7x%�O�R=�"�9��#��^a�ō�RD�Y dk�y�N4b��?���D�Ǌ����R�d"Pi�C^:¾w=<��5�y�u�	�ˎN��vl�cy\+=]��,�2-�z�<��]�ٳvYM!��3����]�Cv��(�����J�l���_!B��i�]�RM�pW�i¾ц���(��1���M��.SK�<������j��l�����z-o٦(�e�	�^�n�E��}
��p�,7<9����q�f�ı���p4�f�9�!�"j�FqO˥�$����#�#�l���z��o6�R��w�	���[4gW��u�fk����*k,[��V���h�P@ɮ�;���\5�EY��k�d:��E�i��wA�xsm�Uo��Բ9��p���?�ɅJYl���jp��uo��t���8����1��_�]̍kJW���ؓ�F��]d
��Pޤ���t{^ON��+x�ED,��6��8���W�hx��9�cV���Z�Fe�S�+���������8�W#NO�(�J��Mg���$�������*tel�;G�B��'�(�䛴��?����f���=�� ��Y׳6�Yo6�-K��N��d���%[��$� �a�����,Gk 
K��կ�lq����xɽ�����#߳����Y9Ou3�%��[��[frh֗�u�ŗ�K�ڠtp	����\4v	�]����T�yݼ٤[Ya�oѰJ"^0�s�z�:�ٻe�Q�9`�(wL�,?6��'��6����_�X�ݟ���-�^܋��`,Ku:��K��u�oa�ĕ`4>D�dט2����>	�ׯ��W��\��z���kL�ky
r�<Q��G���LR����4x	������F��M�����ם�C�i�HUzrT&r[z^�xKq�z�q|C�W���C�������aO�;@|��1��b���j?������κ�"�16�h���b��[��VĮ�iK�B�|��YG���߁9�϶,!(�w��tP��F���Ӆ���e_��G��|�0�^��8"������� ��X�+��c���P�Җ[�����h�I���>�3��<�x��JC����lw֐����e�@�����̂���<e��T\�
����^7��݈QAm�����c�]H��Cڏ.�F�p�I�����\��c��/7���~����y�ݍ��l?�0ڙ�����~�~������E`�cl+�^wnP��Wh�B-�~�C~�р���*�x���A/�.&K.��������NG���`�EA��h�1���Z%�L�Oy��SO�Ѫ�����N��;��-EdE����C!�^�2�����y�.Q.<�x�NhJ\2�"|_靓��o����&=����+��ٕ�O�ر��_���ꋘ�Dzx�?ӧ�<�E��d��A_'���w����=Z�ئZ8)��s�^b��h���9X<P���'���I���W�i�����T�K��=b�Q/�㐪kH����6��\�u�i*T�l`�{t��c�>�J�g!��7�
�ˉ��;~�3*��_��j����2<k�$t./u<�.�#|Ad�l�𸲷dj������ʓ�^#���D�3�S[����	b�!L��k�D���{dÀ1�Nc$����c6�Υ)kTh'����y3�����r3�`�I|9ܝOq`������R�"����,��D����E6D���7`T���!�@7����Tm�\�?�|�" ���j�AH�@;gb����2��߫����V�D�QC���<VH�=;ד��Nz��U澗��vZ�)f�wD}�$B���}�Kߕ�zҨ��Xk�p߃�T���o�e��A��4���e�����6DVO��%�z]�i�
(B�8�����hr�J���a)'��30^.��Z?Q+�Z��(By�d/:�T]��_o�H��0
~?a���IW�c������ n�1i�P;��PM6��ɗ6P�Q��/!y�;6ۋ���un��臝 ��M�6qR�nN��8����^ԃl��6#j��1ǟB������b~���̲HuS��q���h=�4�<=2z���U����a��%�l3}cQ�J��e͹g����i뿀�G��c>w�5I�4N�G�԰���tV:�lj�n�1$�	���i�<�>�+�{����h�
���,�<�9u|K?
�ձ�z97k��^{����V��}��֓1�F� 8�rKaKbHՌ��j����y� �њ�^?���9x\5��WC��ǫ� <=h6�����λ03_l��5�=�e��M�]h�3�?����M�Ϧ?�Y���<ѱ��q�I�B7�kl��P-9Y�|�vgˠ :i�u��4 ۙ��6%��
�8Sѫ���۞�s��.��g���c�����:�������6*�B�3����ɓ�7�؅�������CADju��!+�dy��;��|'ɃL��K�@��V����/ _�
�Bs���Պ
w>WER4u��n03�%�o��Hv���e:,��8�7���`��`s]I�;�uMѹ��@.zk��:5�
��Y%���u^�����@榵<��0_+co�\-���d����r�ߴ|G�ּ���82U6˛=g��7��2٠J��޶nAi	ѠtH6G��+�0u賥���l;�yS�+.�3��Tb8�*�����sӑγ/�y�$�4���z��7��k��iaQ��o�pb٢������2� E5�Is���V�-�"�ˍX�_�d`�����L� �?d��M�i=�^�ꊱ�N�B� 𭝊L2���3�.Pl��b��"~W���ȯqa�&�Yں����N���=�rt��Y�Zk���6d�Pp|߳�Ǯ�6�J�c�e���I���; x9���aD7���G�����e/%	FO8�Ȏ�햙-����`��� ߠ�s�qN�����D]1�*�R�����惱�UR��V��ۈJ��Se�*ç���"�7��!����m��?�!c�~��ώ?D[ $ȍ�D�$Bh��2��lT� �Ɯ�No��l�@�Խ���I~!
�_-�y� �0��-�C�7v%)�A�=����R�F!����t��\A#�P�M)���o��̲&�}!�8|�Ez� ���p��;UIF⌁ttY���)��e�K!�e�}�,a~�}DyJ�֟'���d/����L�y?Z�V!ǅ7D;�D$�G��,u�r�$�xx4��bJ���d�`+7҆2�0��m���I��{��R�ea �:X���i^t�K]ى(��$"՟�HN�iZ��iZ��.+���V�XB3�2s����go�7[��c���)���h�ݦ����?�e%�>�5��mk��wp������X�Y�T�u͈��KS�<�D��D�ś���-]���P�o�=���9��+4@�i��ze7�a��T��b1B�2��&�z�/����7�TP�zr�G��,=���>3�EB�昿#��Y1we���G�#`�AQh"�������Dg�]��	*B�Se���R���i��dȝ̫��+�۟�b��}��p�U�X�u��Sn��N���؊ �B��\"�q�m��?�%ȡ�%CgA�o�.�qnQ����~�� ���$f��[�<��7�^*�)��1�w�(k�2���w�'qcvBkE_�g�jtm��RN^�@2?��[q�m�J=V��9�7�h��s�:��
�WXUE����>q�.�To�S�ƺ���Q囻Y2��@����%D=��o����
�cG��8������� �q�׻!+�Q�,8�֟mu}�IO�a���F�&u��3F��������x�+m}�|ؾ�����;@�E��z^�956g�V<��P�����pP��,a�#�6o	&Qt; ߂��cϪC���j�/�G������P|�%�����)Y��v2|
b��47M���yձ}�%��G��ۑF�����8�Ho��Nj����"�W@y�.8`����0z⟓(�E��SzMh�t�s5�cEw/6�׭����V�4,L'�b8k���Z⦉�%ݮ�@�`H��ԑ���
��A?�	� a�aubDQ2)=%��84�}�`�^=��z|��y��{�@�����M�{� ;j�"*'��TJ@�8�h] ),	�fT��x�R��	#״���4[�� �nd?`�9*�Q���m�vsE3�f�a�����Z�a��ۺoSjlYP�������g��
���9.�����^�ͤ��&���{�z4]��#c�����Q���B"N�	��ZX��2��,�#�,�ڶ?Z�¹�q�^Ӵ����j�,��4���\��ԷZv �Qa�l1��r6�B���4�*�龻���ކ� �w�`���Bp��pE]��������a[ʁ����e�T�^P	CU��D�eQ��c
�ro�C�J�"�F/���2>�'C65-���e�r�H���rӱ�b�mD�z�O�J!�65���oč#h��&�D�G��m������ӫ���4�Xw�P��>ֺ�>�4��t4�\W�4d��&ry��}I�7r�G��E�䌡ky事n�&1H�:�Aw���_�~�ߺ�\�[���/Q0D&��c���N��;�8w��A�=-gƐ�m�)H��M�y����N�b��Z�9�í�B���'���M�%��F�E��L�����k�������xy��U��`m;�e����J.�>y.�D��d4�*�J�;�(�s�H�Y�n�Pd�5���y|�4�<j#Ú4k�ҳj��7&�P��2��h�ہ���ӏ�UFd�#��-{�y���s��\�3�|�s�Qs���s(��]��G�l�//�<h�9�ӽ�eY���4@���T]Eܴ�h�PY�p�hM\�eFo�г�N�<�M�5�*�7��
~�i�W,�[�Q뱽2����S�lѶhz�ךr7$z�����3��W�#K�n�ޡ�5Yg�%,T4.a�r)4�;9NJ��q�]�{+?WUR����lɽ���τ����s�&�2ڡހ�U.�nY���0��@�c�n��}8*/��_�0l{0��D1�4�L�����'V-I���kH��K�R��hhHe�6��N,4��(S2t/m�twk���PX��#��D>>��0���;'�*lP�s
̀���j�bN�{7��
�O�kY��w�W��f�7_F3$P���C2�8�?r����	R���5�6W���S���ˣ���g_B�{�3U�O���J�����b/ �@�B�z�u94j��Y8��+�X�'�c�p��0R*[�B��G�����7�4%�f2���K��*h�&G�
����� ��|��Dg+��[}yj�K�NY��)<h�+f���) ��D7|1�m��1��Ej^���WCTZ��E"_��a�vO*��ٚ�+�y(����������X����(���LH)x�X�V�V�31cN�?�j���� �qD��-�;�5!E.S�٫���]�4l^L19�?��O�R��r�@�i�h   �a5r�nT[ �����f��g�    YZ