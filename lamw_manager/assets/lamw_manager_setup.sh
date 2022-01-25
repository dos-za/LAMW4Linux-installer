#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="951473558"
MD5="9d6ece49378d18a177d130a6a266e2d1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25976"
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
	echo Date of packaging: Tue Jan 25 19:53:17 -03 2022
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
�7zXZ  �ִF !   �X���e6] �}��1Dd]����P�t�F��*�SA����\}\�"����XQ��g�E"�=�p���0J�/�jd/^���ߗ���l���<��z�<�(O!G����L�j ��p�7���F�^�^��J���j��|��%ȨvI�NI
��G�2���5i������5[I�)*�"�Ӿ9ђ��$S�ۯZc9.t*'V�Z�K�'��R���7��nC}1�zƛ����&���v�>htj��0�k&�]��,�[<$��J�%V� �s��NtuA ���>�菬���)������n�P��j��*k~a^�ߡ�2�F����RLu񮛃ߝ�iU��.m�3"Z��˂��U�|r٭�:[��h�m�%�$A� �#�X��֐��b�*�؃�Z�f��0g�b^i_�6� ���<KL�1�%n��`t�a�7K"�uGE����>���Tę$�Y`l�Os\�L�����V������yx�\8�py<�O��j�.x%�R���T���u}�*�(8� �����j���k(�J�=��uzǂ��a�>ie@�����R�ЎN�x�L:�u���6�����QĮ)!��=·\�c�a���GR)jbR~۩���h���m�?.�,٢]kV���^���V��WGW�<*����7���(�Z�J���ډ9E����opd��ך��7-U�1&k�r�
;��N8��Q����+�W'ȳ,�W*B�!��P��(и�,�k1��nI��**H0�E����;2�rle����k*�=KX]�:z��w�P�;񘋓T�:"�:�Ox�x{�	{�9�?����&~4��4wX��Ou���e�4�{z�8j�.�O��`�k�;������-���+B��g>�?i�G���p���f�´i.�f�[��iG����Hs�u����3�@:��bo�R�(����UyM��؍��O�9N���ٙȟF��K��'��[���6
3�hH�$�D���S��T��O�H!��G�-
�0���(YYH8]!�|�Z���ן^.���/
�٩��3���P�:Q��ŧ�Rn��HK�6���	�c�yW�8���	+<���E�^�\G��A�?���}�q��o;o�w�-�-J�&i�无��}�����4(�|�~�&�����ٓ�I%�fY��TX�>h�aEb�$ΒCr�@���~�3�w��
/uh��b%M��,�U�Kb�Z� ��<���J4�S���my�*�)���K0Pp%.��`h�y1m���?��B�?| a����"4�=�-x"�Hl��0�w&�%�� z��ը�q�NB9�m	�s�J����a�3"�ց�������ߕ���Z���KM��R���L�ͽ�7p�e_�b�8_ӑWg�,�B�� Q<2���v�^�$!�Aj��\ט��d��=7��|Ɲ�Q�u�||�,�����gz.��T����F��������Wz�����WS�-�X�>Ȑ9_܈^�3�j�{xy����Ho�q��&0OS�{mV�"��P��Z3�юD�[�l��:q?�`����&�&?ӌ�Z���7�!�JD�����(Ӵ������������V�k��D����+����J�ѳ8��]Y��oG��k�>��t��26Зj��n��׷�l6K��76�ڌ_���1w3�0��F��(h{O뺼�h��K��U�-�yö��~�Ꮘ�_��J�e���0�	� �o�W�u]s��s����F�M���२�^S��l����M�2<qæ����%��Ϟ��~�p���@|��|w�'@4����2��'�	��r�j�_��rY�G��a1�֬h����?wj��l����#e���,ыd�/u�ԦW��u����B��ԃ!��O$�Sˎ+r��0˞g VCl���tc�]�m~���r��爢C�q�B����A��<�EdE�r���]��zBt<��f�T�@����F�����{62����>+���|=SL��Y�ǜ�`��q{����oOpyTG
�!�0*;+�Ց�'���b�*!u��#����H�6{��e��?� G"���"�j��=]��>��\ @�F8^�t���8*��8]��v/��E��7�W����Њ�h����w�h������u��� ���/-'Q5adEW�����1�7�\>Hm�� �z�U�\�R5�U/�@�ğ��V�� �(���V��<���*�B��椁��o>[����T0��}{��w>2����-0
rM3j�+��i�>p@$����ড়�TF�8nC������\4�L�d�$��3M���⨋��k�aR(�$�LOӍ���y�d��FHYU�*S8p�Nuce�7��k0�u�9�}�U�`��L�Q����kե+V�
�bs�izӂ�F�/�H&���Zg�p�8ʸ�&\�fw�b��3�Q�y2�^��a����1�R�/?V"�7H���» ݙ�	�`9�:�m��ւU��=�nɹJ]L��be�\�Z�U�,�(��׾�1(���D����؍� �k���E��pV��UR#J�8�ԅ�o�t�d���u)��������+��$����B`C|�"�#��@~��H`��yK��l,:g�8�9�K
��u~`}%.��t��-�e��?�n ,�Ų(l4��U�P���o9f i�W~^3�]H����U�.�G�5H���u6� ���6�^�ٕm��W�-P��RG��-?�F�w� ����𽲊�Ƙ�˺c�������+�O����EF��G�v�̤+�������Y� mks~.�2�A<@�{?V�S+�;����/�ݨq���?~�����+Ո��C��5S�#A�K ���KGoV�
�r��N1r�.��hw�����1de"t��uYd�D��.� ��a�K�B�%zkev� � /�
|�GK7;����`Ui��-h�4�/^>�繏�=)�V�����z��&S�>�O��o���ʣ<��E��8�IZ'���De'�3�}ZK#[��\XשW�5;�d;��o�bn����F\�}�81L��t�� m�aL*F�5�ܓ��7���M�f^��ָ0��Qeh�3(���ә�&���:o9�+/�\��U�/,h{�Y;��;�>V .�S�"���n�'}{ҠJ�[78�����a[#�.#�s����X�/�ڍ-�����\�Һr(��W� �f��-��_Z�3�%�[����Ϩ���Jˊ;r7?n}$�bH����.��B�y6TᴵwJ�ܶ�#)���>��6����M7i!��:��<���Dkd�v��X-Ӆ\?���o�W������X���i[�d��>!���)1E���:���@�0�j&�t�u�]��ՠj�\/��jV�[��IB$�O�������\�O��k� q�وq�G2������@$���MK�Ht���2�q�-.Yx�1�Z<�L�	0�"&^��-;�K2�g�Z����[*�LE>?��;5@���/F�6�<N�����oE��{�z����+�*B�a�p��ǆ3����ZܐA�����cL{fI�V�em�r"XjI��c�\"�=ƛ�FL�HJXn�Q��2㵦�a����V��Aݍ;k8��[bpW?��7d9/T�
(ُV�Ȁ��ϭH�I��Ӆ�u�(��H�U�Uv15U-�/SU�--H��� %�j�M0�48�yAk�wJ�a�=�x���7��z��R�&<݇���
a��G3Z��|:O��NX >7��4��p�G*rĝF��k���T� Zł����OԾ�Yk<"���Z��ܐh���Z��k'%_ߧ�3Yw���$�������A���ۋ�Z�dr�/��jރ��`�W�xM�?�e6*����)�a�� w�Ŋ:=�`#J����d���˶�e�Ln�0��i��q��v�&r8��B��Я�I|y�C��f���xűQ�D�u�$^�������J�~��.�U_b��]���R�$��Z������O���+)���C=&�7KWu�j�z�SMp�A<ө`��N��<�!�N�����mw>[_��=I�L`�F���aڤ���ʛ���o�J+E���b�WC��}�
I�Mp��)�p^�?�y�����4r��@B-L5�0P��l�����̹��fzP����ITzyb.��
7"
�EI�;�-����@��*��4K���׬���/^a��-�'� (���g���x��>~kv*;��&h%)QǪ	i81������� �[S�k�ӆ���_�m(�SB����7[��9��"���%ж��(�ɮ!$�A`>> O9���7a�����n�>ͨn}z��LCo�.6�r:ܰـٓ�����Dȣ���OY?9I�11m=�ѓ�h*q�%|w�+Ʊٙ�̯��/���� �5[Z�g[�M+b�A��~ܹE�/��K�dMo�Tx��7�R���R�����k��	����[�W#�Z��6F�J)3\~+'�>UV��t��
�g��7{<H�Q�mMu��K鈞<x>�m��ޝ+�׌��ơˢ.[mC�vF=9j�?�1cj�kV-f�u{���6Ȝ�����}(Ք��d�,�ؤ����c�]l(Y1/�Bo;���Xl�%D!��b?٬�`�g��c{������Ѧ���������*;�%��@���+��`��_���4�a7��c
DÕ��q�,�=`nX#^�5�H�w�X���(v$'�"q�u&R��μ$*H�M���M/�9��~E��n��_�7�ˤ=<���9���h~r��tTh�r�ή���
��R���5�S�)�S3
5�yh�l��}ϛN��N���h6HXCr��F�o���l�|3�r�'��g�؃]��V�m�m1�9��s����8�Jo���a��SݟT����/����̕����q��-��]����RJP����RC���p�R��+�qߖS��(�w~-�(xV/���� �ez���:;1˩�Ш؝_�'�
o�g)��h܌��C	J������ �ۺ�蝭��œ�}̈�Ǳ	9�K8x/A藠�vse�v=�\�������[����af���ʃ�ʽ]u�ֿC�S�>��R�wVu��<E��FQ���S��&b�T6q2��;��~��tM���Yp��Ar3�������Y��􊮷�!+��D/���#��#�@%�E��ɵR���L
k�ԋ(	뚖����cB���{��L�E���U���������ĵ����N�W�5�.32vC��u���#Ȃ+�7pl{��6:C�jm>���Qs�ܧ"�Q*?�F~�()*d8%�O T�"{�HFglr+0,�[ո�0,:*֦K� ��R|�碚g͖œ�\k�^��ਦʘna�>��5�:/����h��aF<���jdTr���,)�k��Vn}E�J[�ƿ-�U��15��D"���#�9� �)�3_��ͻ�.I�RH����,jj�IBƪ<x�OY���y��c�!ś�g��1q� �>-(��-[��U��E��2b��A��+'�菒h���¨�y���L'��p��4m�Of�n�;��V�.(gs0�n���#�,�ϰ��ql�h1Ѩ �����D���mќ�l����������<9B(���9�z'���'��Q�5b_�HF�̯[����'�4D�}a�
Z�W;��v16�\΍1�*GI�֥����5����-�d��s=�m/����T\c�n�wT��K�@R,0�k��Jo�ާDiǍPH�][��V��,���-��Q�y���m�H_�
>������l������m%��3_ײ�^~Q	��yY&�|�K�&�ћe1NI�^.�����
D<ǹ�"�jf��`4`n��+��Sp-Q@3h���wj��x�,H]���2��0�]���Ú�h|c]����Q,Q��� � ���!fߗ��9�2�k������Zh�t��5�#�	���t��a%ay(��{̡8�P��^)�
��~H����p�'�r����ժG����Nm�ϺizP�ga�U�i<�ї}t�E��j��k�3����ӧ��`��q?�L��e�ڧ�i��UPx��d�,�gb媳@�ypd�F�'4R�-��}�!�4Ǌ�������_)#П�xu�Wq��������v���p�;��g�$�6�oՠ�z�(ۄM�%���/�,Hm�Fu�	��PacΝ&�䎼͂1v4��m�Z�FKMl�.�'�ӽ�ֵQ�[�r�{��]��Z�O������m���q�~��I:2)�!�Bi'�DN#�
Sr3�F,�-����?X��jf85�l��H%T�퉟�`]7��,_��A�ll��5�y����N��R=TM�b�	*v�%� ��8u�S���7ђl ���
��6���{^@4F҃l*T�+L��M��k��;��C%8��l��{�T>4���XD�}#28��E˔,
Eb�mࢎ����4Z�o� �6�O7�΢]N��t=�l�;��IϘ�)%�G����]Sir�w8�L>�;C�ݽͤ�DH��k[�V��GM�FM�fI$��૖H�>�IW�;w���Bw}�ś�R������2,R�j� u{Qb�?�f�q9�C.�6xh!E��}�P�.��s�'Ac�^�W�wRǮ���5 z}ymRB<�`��B�&�٫U�'GG~��q�-Vv�L�S�5�R)<ip��,������>_�Up�\��nu�T���e���/�[P������:����-B��f�I
Ǘ�+k�"ó��{�M�ٛ��?_ i*]
IZ .޴��+��͙��۲s�^�JҀ�{ �IY��*�(y��o��m��"(�f��ȼ��L6t�i���/y%��l��o5��Ŋb?Sp;��t�l�gm��凉f�H�t�V�����aS˯R��L6?` �Ymy[�RcW��2#ŏ�|$m�����o-L�;}D��1��F�:8���'�k�T˸Á�C�y=��H655�H+����j�1Ǖa�Q�ˣ�����(3�����[�
�Eh�׼�Ʌ3Gκ��W �"��e*.4��s[���
��u~j���:*r�-��������Ԭ�L�i&\$C���X͓�l#͢�^e��`:O$��|�6"d�S�*� �q�,Ҷ���d��F���x����Ս����6T���0���S��2.�c� ��Ɯ���p6"�
�C���`�v|�����O���
�k-����(��z�Ip�#�FE~�(���	��aU��q�C+K���"X�6OT�D�cJ#p�gs���$��������+_����D�O��%}\hA��G�DM�4�A�3�Cl�&B��������*}� ^��rU)�t���y�V�{�s,S�߈�0ע�����hT�̮b
2&؉
��a�C���g�F��@�.�U�޳��}��0�y�����J�fG)��E�+*�q�/��lPό�����e��u��(�y*2�3�$32ۭ�ƕT���Qg��҈���f-C��2�������}���P�pdR�AoVaaX���Pi��@�'��v�-J�9{��NJ��>�H �@���B޹��t����֖=k�z�)߾�m�Mҿ7����r:��9 e���F��K@$�䔀S5�#g���?1���gHk�=��0��'�q��0��UohRqtu{�Y��k	�ԇ�kӅb1�": ���$��BO�E�E5����I��!���~|�3\�O��.u�fEJvH(���ઽ�*�y@�o�2�w"�HVi�ܖ�OY�=�>P+��k?bM�e�i��I�M<�s�=�ns�Rv�1Z/�5�h,6�Q�@�V�h?�//�{����7�����*�jf��Udm�W���Y��KM�<|����P�I�HS�� �^�e
PkѶ��X�����~>�e�1��w c1~�_���G�C�܈/p{����g���� �~c|Ns��(��d��k�q���?���+MB�s9 gI�k"G��M���]��p�@jUk�vrYk�Z�T*<�8on�����z5��- NP�P��$"����7�Ͽ�y��oᬃa>��KK�='cչD��c�*��zj��_�,vK��W�Ԏ����>(��DQ~�>y9��O�nr�<D�x�����6�J�tU���r�Ri^Ll/� �5U�������$��v�,&��הVB0�\�j����
H�2R�P������-�/��랰��w�����U^�Pa��
p��,Dh-`%77RHe�a�F~�$��b���	��;;��c1A=�ww���+/�-E9]|=[]�'��y���%�Dw6/}��x���qo�94� ������s�Ҏk�[m���;��e�lN$ɳu5m���]ȯ��7��X߲x���nJl��E�6�Q�z���0�h2h�������n�����`$�iǩ�d��cP����7��lG�`\ưNlZ�|��y_+/���R�K������Pi��ɋ�x;���
���]f�Ge-��?I��p���{��i�ʂ|Û`�v.E��d�X�5h��r2pN߫9��S�Ҋ���Q]��Kガ�%���nSc�����Z��_��S�a%`_3���[��0��6�Y�']dx��m�v���۪$��ŧKwU�=E�%�\�3-�`�X�#�s������ ���y�L�;��ПV,w�H�xp;2�Ս���޳�]J�o��V�xv�E�����[��, QQمKAk������[�_xܭj��~'W��&r��T�ê�f��2v�9�pvY|�����ξ*���l�w'�yH��3�D,B��B��up�R7qy��^��Ŗ����ܭ|�+têD�|��x@B�^m@�d�ۛ�Prj	��zi�	a+��H��m�/�S[�b� !s�#d�C)vIW�f2�\�iACj1'?�TP���6�0+M�d�Q�p�`�HOm3�ZV@�/!�$f��H8]�U��sMޙ�*�$G��C�,]����(�$"M�`üjѨ��d�N�h��Ǿn�BϧU>ÞZ�7���q�j=����A�l�o��[������WkP��߰�w����g@vZ�T��`EKi���'|V�-U��PɿԗB��cޑ-�Yz�ľ��6�������.�v��h����6�<@gKml\%������1�>�*�98U�R�� ��瞗�?��aG��&0�:=�݌�:��f����N{ۈq6jt���9�E�b\K46w�9�/�ǠS�<�98�I"YzmW&)_����X�Ao�`������f��2��L�8T̋����dH�|V�:����w�\	pε@�@��(R��ʁ�A���Js.��Q�4�)�!���kh"����M,8��$�� �]jv����ޔ�XMֺ�\U�]Rf���&		���ȡ��a�_�K��k|�G���#l�����8�q�~9/B�^��-@�/��=�_��#�x�O�5XR��η�������s\���4ŖI��-*�53��1ut��&��7o.d[�g�q�WTR|Ŋzr`>c���O�٢S*�u]!f
�͝��^�����9�u9 O��d�D!D�#s����L�(OSVe����G�ގ"v��V��.�P�n�z�b�bX%P7[�}���8<% q��"�Z54����&!}�0��pOgf)�s�x_�u1����S{�:7^�7�6�5��Y�� ������/YR1f�Y�1dE�!���
�[���#z1�����o�K�Z�ps��o�:8$�3I���m$:�P�is!���p��a�U<��m0�O;�Ļ��+�H���,� �K��ib�h`��0Y�6v�,��X3�j7a��ф�^�$o�h��/�4�F��Y�g_�'��'�?�� +���,P�߯9�;u����eTH��ߒR�僕ƅV���_5�%�O�b� .�e��d��,����wn���?�OJ38Q���13G�|ѡ�-��� {y�~��N ��#2ρ>~u=c@7�dP��RD��}��Nh9��ty�R�.��FΛ�������E�b��8�YqJ�"�ˊ|�urV�H��kr�+6�K�e��N"����	ؾ,F5�@Ex��΅���B��]%z@!L��x���Gg�5�K�4�����Gz�߳3O1��{:���-�N��b�Y5s�o�KQB�h4���p�+u��󾾨_<[A@�ȣ�����GhU�S,w��z�wq�%�AkкW�0|{c�����+�<��.ڷ�ro�Is�[�g>���J��՝��Nt{9����w~&'���p���}�Y����<i�^�_aZэ1#"w�9�X�3�9�c����Ud>B��wI2�Z��a��»x�ɢW��@���Y�S`#J�m��s�fW.;=�w�(Ӌ́e����vcx�ַ�R(q�Ra���=Lh�� Y�[%"5�>X֡yޚ�"�z��?���m��ڑ��ή����)=�P��Q"3���!p6IA;9�T�Q�޸Es�����ߞ���������V�G���|h�y��T�G�&1V#V=���H�E�3<T ��S+c0�`�9�)@� %�u���o��p	�|c|W �V��2��e=g�70O�
f8jt����x
����jYT�U��m�s��wnR�Zg��v�;G�����_J1'2~q��%��~� ��q��y���b�>�l�4�t�T9���M�Y�Ͽ��)7d�B
KJi�z��Υ?���	�XjwmtE��@��"ײ'�LX8Ն�\��$yf��U��3���#�a��E������""�Bo$P&,���|�L���.����_�*�ih�Pllp%f�d��s@�;�	�a�_��4�0���a<�P����;��]#��Dή_�y(�a�k���^�c��t��)������ND�b��I!����S�e�/1��nPd��g�~q�Hu�@3@����O�h�>I.4߹D3���uc�m�W��w�������P�ŕ�_d�gvkd��坪]>g�|q�^�!9��Ay�Ӂ�r]*9�]*���6���;����Vl���R=*���k�x<s�ߗ%�I���3 ��^�f����y���r�V1�u���d�e�f�mO0=�܋�C@_��K��[�i�'呌
��>E���=�z���"����<Ĉ��������%����'����ϔ3��_��p���2ދ�?,8��-/�lEH� iޖ�i��m����l*&�
G��o��p,o�U����a�,���<�����6�0����@������m�v�5��F w����U�|a��3�����(� ���ww�%�>�%^Av��+s�&׵4ٺ|�u�nr���;)3c�ɥo��b�� P�\�<�	�:� W�ֱVۄJ��)Y��TG)���dƓ�O�Lve���^YXC#��Ӌ;6����Sr�(�p��*ƥ:��5v����J��s��~���Ū2���\�Sz��]}B��uq�6��$�r�,�n�)B�tc3�ka
薼����a���lFNi����+���郟�Kp���lɵ��ON$L~�����-��),�L����#c���!��-�9=�5[�8�ߝ[g��N͖���"���Ke�M�[��k,y�u�XJ*��/ȸ7$��U�f;3�.�v��C���tF��k���$��݃)��'�Ї�#�s�9>X����)`��ғ?�&�\5�IoC�a��\L:땻�"�����;1�ܙd�	�Y/���6U�t�qeApy1���^�����~�[�$�R�c0��m�;%Sq��)�T2�d9�$�05c�tЩyCFO��4��f�hEW��]/`�;?6�6$�5ګ��)��K�*Y�V�p��[<=��/y_����3�(��ΓU\y��wh�W������B�]�!4}��r0�'GGEnζ���<\MT��@���v�A(����x[��F�����.�����X��	6��}�Nk�B��sg)(è|�OD�u���<�⬒����Q.�hK��{�#����
y���~!��5�=^�{�Y bVo�eq>�z&��tZk2�4�2U�{V]�)$��Q+�X�[x��4�Hc�J0�͐>ې?����!�б���X�$�B�ŝX�Rٓ�:��E���V�P�	6B~�p_Q@8���~߄�˓�p(��*�p�1Ɏk�e͢����E�(T5Ƶ2����I@�S��h�	3��Ù�2���+_�DO&Zy����~%kq|�!Ä��S9um��[o&�U��ys6/ ���_$�m8u�&=[ۛ��Y����"��м0���|@t"�%�\{Z�"}0�����8i=����S�Ap��fҵ$��m+�2���S���o��)u���uxQ �T�/�1����:m�ؼb���Й}�~}���ThP����1�� IZ;�ǵ�^��|����Õٟ�I���,v��sF2�1�e�|���(���-�9�^�mb��U�jT9������-�[�"rR������y@��^��lR���~�i�շ7������C[76�J`7���ɽ�S(R&���P�5�K�\��
��7�5Sj�x(���0eg7�
��\ɄN�\��7�<\�p��n(WYB3�P�u�?����f�}�}��X�VBP�Ķf%���X@ה�sH�]��6�Y��UX�B�|�2���uۅ���Ȑ�ip���!��&M�_�������#�wp8���wSO��@�G�3.�H8M%����]��q ��Z�E��_�P��3b�^�<d�$��[k	���,F7̬���Q`Z,�X�������Tj���,D�X��u�m��aZ��L����d���b����p�P��хw�?;"yPx�}1���zy�1B���3+VƥEj�"z��f]��w$�{�|���=!�)��P0Fף�)R��#�i#��:/�y���N�N6���q��O�'�[��cU!�(R�����<wËH� �lb��1f��^����K\��ܻ-����/p�2�8���^��/�L=9*f:C�I�S����q�U(|z��F �(�B_E�$VG��������>� ��X',7{�l������;'}]�Hx���*��ˊ����U�'5~��e��Ŕeg����0�^o���=ޖ�!�Q����ywn�L�YF7mAS�5e�+�\��fڒ\���;��%���̔:/�x�@�4/�(��5/%R��A�ڭ�#m�h�\q�˞��E���B�r�݇�߽ﻞ�ZAU6v'b�q��U�5�����&i�/$/�O�V�1�	z��Q;�8h��﬑�ڈ����?����$���3�瑁
�5����!����Gq���7b�w������f��3ڑ@�~C��<���6j���7�~�j*�p��Mě1*$��
���aK�h_�$���V�����![hlז=�� w�$p!�G�t��U�	�J�Bf���
��Xh��:C�+;�hnl��R��f��5q����~۱W�Tz�1aH7-Ə��5�Rsi��y���_���g]�Z4;�;�ڼ�$��<�ϱ�$��t����=��<� ų�͇�wL�_t^��K�2HqeAw�tg�r)*X?� �f���Eu���:Ujs�	e|c�C���S$Jy˨��p�����	��q���xB%)����в/����Dc�K���jt���4Kğh�5�������z'lB��`fR TEO6���'���f߰�V�ѷv0U���On�>���%w�S�?,�/�'��������G���z�z�]�D�,9�G�Ko6���'���Ua���f1W�w@���2����mc{��g�\)��Dt�s<�K�����U"Y+w�!���d3���v��Mݼ����z�N�r���m͢�S8���Ɂ;�o�����*#�EN�֖�!��ү�O�Ș��mc��<ڱ+ӇB���훡0k�{=��P�����ʅ��s��W�G<��W?jX��Vy����zUZ���K����K��9բH?j'*���
έ���C!6�y��=�?Ÿ4|�ƍ�um4����y��L���v�Y��#�h��U�	�Q����R%(�ǀ��۫ �֯r�����(�¸O\�sl���-�6��$qɪf+�6�"ѕ_��'M{y����ś]�?��Kox�r8ػ@w>Jb�IpX�m�#�p����^P��@kκ��uE�����nֳ�Yd�hX�_:u
~ζ�h�Nhw�/Ma3���w_��cYw'\������6�&����0m\���g�{�$��aT`��Gh.[A��u�z�J�릜�,�ɢ�΁dx8��38�׌r�S�Zvw՛t�����C{l�פ/2�s���0�1��o�Y�<f��s��ĵ��pd�"�q���q#�"�=�?��vq�}|�ʾ������s.D�u�Q��j9�8��O�Q}93���AB8���F��Wxd_xc�,�0�C���/�	ТQ��q-3l�e�ѣ��=�$>1��>�оrI���D�ƭ��m�t� �;�
M~�����b��X�>�'{*���I�˷:�,�0>&�W�՞�y'���ЪZ{��d��:�������\������
�&|̅�*�ȅ��&������W�l@����?E��L��e6�}�7uG~iN����:���w���q�`�z#��_/ٰ~�so���O����D��m�
U���A�ϙ�T�T�a���hw�����Mom�ԅ�D�@�%3"�؁'�`�!C�Pi���$:�K��3>_n�D,t�1����!���;�+�2(q�Mg�g���5]|��äΧ@�"���)�|����"�M�̗��}^��^��v�X��G�\ =��]ڕ����/nb���Öxja��Bciek���>�P�qv���J6�}9�"���}H�dk�ܑ���k"��[>��͞�	���b?��S���"��a�ݛ�ck��d���N=@������G��8�I]'��p;Ii�!�f�	��Ǩ�o�i�m��'* Ī�ic�kqQ�^(B�m��������Zm���<{���'^(�;(F>��.��y]M&d��0�/�P��ܡ��i�*���q{1�w+|B/��!�>��Z؆��^�G�םI�U��	˽�W�Ƴئ'G�\�4xIal�"�R�L��b��� ����!=N��ph�M�z6j)�3�b���p�i������H�")�C���٫
�i	B�X����J���n��(o�V�������*��]����3(*'�����h��a������ú��
s��?��TRrn;�?���Tm=g�C�e���rSK�5���w�0�>f&3
�J�y�qC��?��� ��D�ҽ��%���b��e;sE�qJ��]��6`lK���K+%��{/��c`$�t^����3Rx}t���;#	tVuNR��N����_#�!�"���P��R�a��Yl��B��;쏀�1��(�5���ȋ��"�FU`Y�͍���������pi?0�����[����#.@H���������n���,~ʴ�5<��2�w?�"�� ��O�'�+�/#�E ,W&�Z�W�5�O15�^�9����F�R낂��^3V��WNy�-Dٛ��G�
#�Y<�����S2�:�^Q�z�u�U�o\��*�$���X�z����-M������ҋ�����c���P��a`J~-��ۻ˒?���l�>�mR/{\^�n��pϩU�*��S���	���F���w�XsMYh�� -z���K���N��	���ҵ!(�g��5G�L=ϻ��Po^�!���K�n.�t8P�lgG�ȳ`H���X({(gP�Z��
��&3���ѳbJ���R]���#��-�=�s�{�Zb6���sn�,�?g�Y�4��Ck2"�H���6�j&*���CP=>G��<��	��+�.�(��*�m4 5O����h��[k	����*��_����m+�NFs��_��+�4�r�H�z���@��S�ƹm���xx�e��8���Z�$]4��EADڬ��xW��T�`�XgJ#0��d���C�*���K������/�z�N�i�B��b��l���4�K�!G:�#�ݑVR0O��#��~0��jF��Bx�{����T�9O���l)�����Z��V��o~[��\!m!�k��'�B��R8l�bh_��2���c|w
�kѢ��_I�6��M3�m�M������Q�a�6��뽷q��7q���O�}��֐�@��m�6gӘ�}W��Oӧ����X>WUz+!c7�� ����J��-i������(�+��u���_\�j�:��t��!�zcF�[ߒ �������{]oϝYXs�6A�o�9K�·�H	&#\�q8���p�3%�;#S �b���$��y=���!����@w\�<�P�����Jq���x�#="v>Ty�PpO��gZ䚪�8��Y[5���Ǉ�W���eL�)8�_��.JK}*����/E��%B$�x%lw'��$բ��3���d���;RO{mn��7�Z��H���٫(�э�^ȚA�o&f�#V��8��?:�@��*�^�~g9XY�W(9p[p�wq�l����;�
|*����Z�-�hL8�c�`I��8y�K�^t:5��8Z����j7�&��>sY��r �����N�xg-o`s�����v}}�s��&�b���Jqk� ��D�V��&s1��<B�6�@�pe������B���� �ְK׋��)�_ߡ]�`����,c��ߘ1w�7/yL?#D�1��G��"����)\�6(�Lo�-��b����58�Q�Z�������->,���c4�_���˾6�� hi��^z�*x#��Y�GH�w�R\\��:)�b��Bwqw⬌.���A�+	\MR��]����H}r�I��P���p�r8���m3��	����d �{�~��!!�id� ������ŐTit�A\��\�e�f�Ԛ$�|��4�p���fX�	%6y�H*	�<1q�������-��_,�T����<�
koM��	*�dL��a?w5 >�Ϭ{��۶ӊ��E#>���K��[yDtċ�x%u���h��������Nw��At0�w�H)�����rλDܙ�5�`N2J������sY����=z�T_3$fD��Ϝ`V�6MHa���Ђx��1�ͅ	*�_��A��2��%2��JB�*�e���/+��Wn΃ x�:�Y��9�ei���o�)�����џ&qw��d�?�LuaU�?}��^�؞@�y��V��R7^��mzVX�Cd�1��g�N��Dd���"dhU=ox�N�d-X���Z�7�C!4e%�yz�Ё|Aw��<^Z3H{�%/蘔/.w\�b�N	1c��_�p�v[�C1��G{aOFF�����D���<�%K�z�NR��85��ζ>��}���1�f�%i�+��*��SDǿ�\E�n�� �n�E��y&by�q����s_5�RA�Bvw�{�Ww/�C�������cZv�l�F�����8[Zźd�a�g`�U�� �6���Π�
���F�e����eV�j����v˹�x |�e "|qe&W�3�5��y�$�l��T�Ҥm$�g��IgNyfFн�	[^Y�l�4������]��ʆ��� ;wsvæ���K~$��9X�*\���f���
�O���9�:���^��1�>��C�w{��ƫ���q��*S9
YR��C80%A�?�}�H2�"�4FMU�<�A/��O'}:���j%6�=�jP|��Rf�k����26�")���f����ڢ�V�h�~�۰��⤩7�lPw��2�o�b#|f��s��/�3��)t�Ѯ�����3�h�|8�
BP�Q`r�F!-�WU�B��(�ƵX���3-c��"6Ym�GȺ�G쥮�����~�H�Kʉ�������\y�:u7)]�*�D�c?���y�=��/���
 �����yJ�A��MB�h�M��_jX �7����n�U�;�����*�����m������&U�64ek!���O�G��8�u�DЖ�}��������ww
4/Ԓ(��V�������:�2A��xL�oa�+��,[��v�+��u��0��'n�T��>���.g�1#���ѽ�t���=Y�fjҕ�+?֩�Ij0�l"25^�+Y}�\??&��"�q�%��=TL�T�)EVO��3��E]0��/�])B<;��ۮ����b��f�r]j�D�:�Nx9~KKYg�֌+�Y�4���eLD�d�Rvכ��:��~ޢ��(�\d���l��yz?i�xM�E~�]~�N�o�Rp����Bd�U�B�P:Z��5�'�h�p�ƍ�_��[��i�)�/) �@��{7}A��jgK����|�P�.�W|�vLڄ�ق�PR�-w	��yw�M-[���I8�G��_����v�2Z��S�
���R�+�`�D}������Hޭ|���j1*���Fjh���%;�DBpn�ӂ��޾��MdF�ok,��
e�$�b 	�V�_/���x}������4������u*hYy�d��Y�j>����<�=����'W��Qe���\�D�w�0d�IS]��Њ�v���,���jļ��Ŀ����	;5�S'�^��i^���\�����g�����	&nR�]j�E޵��R��/��-����	&b��X���&��N3kZ޸��e�n�+���K��6����{KO:�jq��%y�����w�W�뀫�	�W砿	�_r_#J�!aS�m�=P�͂�oَ�{���]��"ҡ:8K���2����*��2@]�f�p�"
�l�e����scC�����%6�{�Z:[� ǣ���}��S�n�1���p�^T��� g� �Fi;	�� �`nÃ^tX�y7~�Hbt��-� ��Pu\�ۋ8��e^�Y9S��˗��mQ�ꔪBO����ȳ ��'����O*�������g~ݧ��x����S��rҖ���XOՇU����Hi��t𶑒��� �k��ϧe�k�EX�	MEl�
�^�w2f!ʴ�Li(mz�2�7
���3�e�ma�v��L9 3��L��j�6� ���`bNo�*L��ڡ�5��Z���ٚ��'�$^�}8��..�+P��c8��7��"b.u���chC�Yx{��#���Џ[z�\�d��hᶊ��ꆃ}p5y��5�wx����v�,�M�p�8c1�`a��\r��X�5�Ǽ%\��t���`�=;ĺi����b\�h	����r�Ќ*]N�"��-���b���ֳ�)���g��d'8cH
p�NI������(�AC�#=����m�W��:,�V����+?�Qa�!��)�|�A�x���2(}$M\_��)�q�b�)�m�%���R�[ѵ�_V�����:���T#���Z�l{���4��<A�-�������e4p��T4�jY<7|2f4l���K��̅l�8V1���w�S;��V�ϟT4G.�%��6�z�n�q����]ؑD�c?+|��[&BC�����W����h�ı�r]uRҒ&��<q���1�cW�wf�^w�#֎�ˀ�k �S	���'�ϊJ�U9//h�ZQ_O���U�]O��l�k^]=�D��M��J���w��.q���(SY"�.q�~�ʹM죿|���U���+�"���zS�rr�`2i]��r�s���Vn^�]Eኔ�o�}��/'�y�[^�0��J�[ϭܾ�o��u�F��;e���p:o��=狺�8ȳ_��G�^L�t�h+=w�-?�+��.s_�)�iF<|j�K����f��qt�{��~(�N�Mb���ԾV�Z�zq����j��K���C��@|_?B.c�)�jfUD�:�Y*�yQ�:�i	����0c�@W�O�j�:�]�����n?�/�z��}�`ʳ��k��ü8�K�"+~^��(yR��O�h��w12�I���UlNc�T�-O�d�W��2�6�B�����p���J��`��0������������/����li��fS��1;�-`V�-pG?�ý/�1ȹ=J%�ꎴ�"��"_��"�x�ў����fr�\}F|*ʎ�n����h�Q�Wa��`����2��%��`雄d�M�)���Y�b���
��/�#��TF�0\���9A�Z���qT!l�)? �BD�M}���L�A¥�/��w�f'���GA�r�B��/�Ց�r���� !a�v���Ju5e�e��ȓ󅢭��NF���[eE,ш�y]n���8o˪��`�}v�����Xɕ���0I��h�[�m%�u��\��iRS�F�j�:N�A3��L��� ���?e�c��I�D�>��h�o�1��� 6���|-Z
�.]K��/�>"uFӘ9�CE���'�?��j_�|���O	w/�?}'���~��U뼋Lq�'Ca{�F����<ɥ�{ќ���N��lI׻ ��3����z�l��߈�A]�Ƚ�����^}����~Nk�g�u"�[o�HD�xU���1�"�lu����\�c���S׀6 �r�X,�c���l�1"����笢���t'J�?��������u;���i����� �B�q��nkW�	��zf��qw�����)e��k����>o��q�����Β����,HSt�bZ%�s��r�Q�=�MR�<T�:��u�>d�C^4&���t�wT�S��r
�q�@ա�z��"\��e�i)��2���xL�����]�.���[\G�j�UJ�"Թ�m5�E�#��-�b�h�ynZg�B���4�K��#��L��F9vk�e�����h����*���Z�暭�j��sŬ�ĩ��n��<����~�\*���;y�qw\��>�S����z*m�m'xg7��Yfb���0������x�@�l��G���T�8�m	�Z����m�ﲀqe�C@��Ǧ�AR�@g�KY�sa�d_h�"�9K�8��T�G��ۼs�%�a��E�Z�.��Ϝι���"�2!��A'*��`}�����Sԭ��O!,o�z�,���.����� �5a�]��)��iq�Вح,T��j�[+�Oo,��5���SH/QY/��Ͷ��9���[^z}+1�e�E��u�K%H��v��1!��y(��@"��1�>ea�>eXE�p���7'z4������#����/<��N.�?�,�4.y؉��"�[DV}�̌��>5�����~�̦�V���t�zmb�`A��Gep��0�P�5�8F�B7���)�s;���s&$g=?�>
�4.^8	�v�F
w,dJYj`��+.gm�VS�U�n7�b>�T�C��(�^���{Ԝi+�5-�^M�S�
�ZEQ����Y�j
e�i[����*��N�S>�X�P8�r��+YS��P�v���?p3��F�'��ʈ7l�d�;ؚp���� AOx�Gz4�������a��vmsp��խ{�U��)	�2��i[(�	Hȝ���ZL�%:��~.Lu��E&<@١r�0�~�g���[E�Ҕ��x�����dI��EAD3�[v**'��'b]�=�Bѓ�Yq~��6��N���U �S�Qͨ<DX�aN�`���j�Aq�g���o���wL�J�FSP�L�T��g�yB�X�����΅KG�@K��X�z�G����0��]�a�������}��Y>�����+�3�2*��,���3XTf;P�JuI�Y�	��f��p.pU��+?>�PJ�bB��1,��>5����w8���Rc9v��.|�,l��Px��BVh|��3B��ϵ^�ɻ��;����G��^0t�F�o+��Y�0[��2һ�G����U�H2=��j f?g�j����1����1�EKvX�c_��5[F���2T��D���J_�=�_�e�Q�\��{Z50���*��p�R�������v�z�:R��bj�y���j�53�W�>9��6�923/��5��QӈT�����Xwm�7��J���k�:�w]�̕��S�5U ��X���щ�,�Z�!�ؗ�7k>�b��;3N	\Y���c��=�}~�z�7�M+��Ȭi[�$U���B�"v�6�=�v��dc�m��d&׊� �Z\����z�<����,�NEK��c�%�j"�����5N"�/M)�פw颾�_�b�Ո�鈹��� �U��ay�	�r@���D��9@i�Kқ�|��07?Ӂ���o�p�����`4�4�$�m����<���������0wE!h�ha��W��P;���8�UꉛY��k�򭗜�����G��e#?+G�5Yq�3�u �Ը��\n�,3�ؚ1o�z�̅
�>Ò��\���ѹ����-�T��d���(+C�KR�T޳�ϵך��pi)*�ױh��1����7.�KO��-�h��Ӹ}���ǹ�ޱJ8�;�ÁB	�̗������݆MVg�zТTߐ��/KF�QG�Y��#��[R�N���ϔ.�KJ�D�S�D^�g0��M�U���s�A�Y�I��w���-�5�䌻�r��pY�B�58��gaC�c�p��t�i$�Lnl,��6"�!狛�)7���׃-�I�]v�]�mnNz9|��2�{��73��]/��wa{R��N���zXlǬc*���7&�3�eyoܓ#��j���<�mU�1 �r�H??$��c�J;6���F/���2��,�HmmP2��g�����f�jGV
�u>*��H�jC���+zV
hU>~��Tk ވN_�`�]��kS��H0TW�W�oK@������(�e@|ڲ.6��]�!@���d@��+�K�1F-�#oQA�.�s�AU@�(�D�St� ���OK	��P�u���O��=��'*�(ȅ<��՘u���b8ŘUP��_�^��w�&�8V�(�/Q�$協��z�0W�j&�y���o�}N�p�[u�\3�'�T6�Y��'�
�ح
��f29R P\�)�`��Uϳ�终hK:��VF}�̾��r��$�ܪ
&�ͺ��d�TK)�+����Q��I�*ún�D�HH�A���
�=@�&���k3t��D�@$*���s:�ܱ��Qw��N���Si�VGڤ�b�I-�B��1=�;F"џp�܈Ԫ�G�v6|[�6��� �O��]��s*H�XvӀ���^춖�ǩ@Wg��1!��_�Q̰`v[����+O6�z��߼��V0\b�:�9���aص��%�����^����/0�T_�O�%\lQd�c�aD+U��t���g���U����ǆ|��H��@�i�3�d���]:s�|�l~[��F[��Q����с1/>I4F�U=��h� �	��NE��ڀC$��(���B���.}f.O�C����\�Oo ~'n4T���� ����sᵔ!���F_�R�~����#gA�̂��S����Q�w�C}�;���� HQa�'0J�]M���xO��QB2d�a˲7�-/^��'���Ǚ�^6e:�>�IC�]��T�?�H{ �O�A6��Ę��7+�"��F���W"kF��4���{H�f
0M�8�{v�KӅ��Ѵ�7��.����`:'�؟?�v�9�/������^y֗3�������M�C��8��CDn�VyȈ���v��k}3�w��F.�~���#D����#����g�!jUj��J�޴؊m���T�kz���Q�Y�
S�nO{�^�P�@�L��wWX�h7ʍUG��gj��:��^~����)��T��3Q��N����$j�����2���\6���j���'80������+1��g�MG|�I�|E�x ���\N��Rĝ�N�q����!�b�7�k0�zs��@a?�vsD�829�|S��E4�Rv��G�u��[���EH�樂��5V� ���@E��a���,C��ǰ�X@�}r���\�F՟T�B���5�e��,0�Ń��a!wN>�]	Ҝ/�L	�
��n^�S��Ґވ�so:�1?�	���=��b���?w�<�G�E�*C���+G-���:��'i���y:JG����C�ʫ�L)4I��@�X��q��e�1HG^VvM M�#u�"~�����j9��G�8|x�~�a^����T�-��zR���y��+4ќ�}W|���k�k�S)�/�3��g�<WjP���r�"��ޔJ]��9��}��L|d%�Kb����e"�~���.IӲ�;,��0������^���м����ZJ3Ș8�y�X
?�\-A�J��,:��Gm�5��zF'�_Ĭ߹�*\A���g�:����9��ݸh%@c�1���g�i1��(��V*��V� �͔9nܘ�*�/���B�F�Q�C�Y�4�������+��E=o]����i�+��ᨃ�	���E�K����ҴC��cu2S�G�/�l�Vq�{a�f�y�ȶa��I���J���_��m���X����~�;�޵�,��OowH$�`�e�ƹ��D��+C��AC���]Q�jr#�&�HA����ig��7+��>��-I��r�+ `u�����OV0m7��h��j��VriG������c_4������2v0���B��7d��.�q���F��`��/�`�$�+!<h�|r�3�h�`N�b���<8�Ӭ������NY%��w���N/Y���& =�x������׽F~|��Er"��\[�+L1�
����y�e1Y�p�GM�	���c�y�f�����I�
E��,b�a��̼�g��'�C�6�tr���"�G�O�7k��T��%Z䜌<�ݨ���m���2g�S��Anl'3X��������ć1_�vH�o2�H����U��v�߃�Ȫ�D�g����U� ��/�+�b�m@&YY��k��$�*	O(�St�ũ=?����g�\�K�A�T�{>��r�m旝�p�����o���W�
�رԈP�"��$1�6�x�Re�+c��p�":Mf�)�AJCb���Z'��ָ
�ש�Mle�=6����!��W62��9h�l�x�CFt's	���#�UST��Jv�T����`�����U}���t��ߧ`����gY�t`(ژ�+�ͬ�uE���%��B:Y2��OXi�]�L,�K$��Oi�C E���m]�2�|�^�#�Z��~؋Mxe u����S���)�lr�g�v"�>ϡx��>�   4�Jc�<i� ����N���g�    YZ