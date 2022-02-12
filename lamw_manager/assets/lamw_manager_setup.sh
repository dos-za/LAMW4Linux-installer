#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2540381825"
MD5="3268690a76abb77b4c3847b2fe6a0b1b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26556"
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
	echo Date of packaging: Sat Feb 12 02:50:28 -03 2022
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
�7zXZ  �ִF !   �X���gy] �}��1Dd]����P�t�D��fD���ӹJ%�a^�|��!b�y��%)����TPL��wK�{az�?�ps�?��7����[��a�ϰU	��B\�j$����I�$G^��B=���C�[�����(J7��	�����^���s	�:�+1-�^Ȱ'1�0W�E�(���b�іb�?@�ḍ?�;�}��I-&�)+�v��Nj��鉧��j�ċ�ؼs�{Q��&�H	a~�J��������ja���O�ɪ� ��d>a=έ9>'�񕆛?O��r-hM���{}/m"�u]?�g��o����ԻA�+��m}��d_���M�=)<S��egw;�\�h��"x(^��S�w��覒5?W�_�nn�%Ww��
@q��%�Mإ�ݩ�E_��eӂMG��Q��I�����0������8k䫥�!�hh'�2#]�R��:�5;��z��K�;�A��Liz���j�~�{ó^��?y�Ņ��co�{��i�CM˲^F�<� h��^��i�&��H����X"Ɲ���N*��>ﮥ*K�d�,����"������q@|+	V��~�0�����=�ht�Rc���:ZBN�}3*��ہi2i���(t4��#ń_ǔ������?C���ʅ��D��d���{���6�l�ę�N�l��������Q�x�~w������w$��L�S#���A�s��e��&9�o,/�
�lP�Z��`���Sk{�<w,���\��1�����ئ�a����#�䅬�y��7�?��	� [0b�e7P���4pMqf�@#��~#ι ��D�n�'_j���YK�_&�=�g���_�#:dݦa�������@󳉀�����^H1A ��o�neS��c�v���*.4�L�!�gS�Bz+ɮ��n���/��U]u�&��j�L^�e���;�0����e����aK�ػH��c~)8o�p����P�@&����9�V���
<�I�9s8K�]O�AW|��v6 �v2j�~��۷�S�K�	Z~-�ݏ``"a�$W;�P���	J��:�o;E�����.�JЩy�<��5�6�A>%,)��L�:+2l�9qS�`��UY��
� ,ܟ>t�ƀ�h	M[����,��|�t�Y�g����nyi��1���*�i�1\�u��C�p��h�!5ĘVV����>��k�v�u��_j�D�;-�Zr���C����~�A���G�K���-A��������d��k����K(��bڧ���8��GǄ�MrT������޼�ʅ"�%ꯌf):�RZ�~W�6ī�m��LnFk��FhQeP!A�_k�Ȏi5+�T��Lb2�����c�j;�B悒�Bՠ�	��y��S	.��Q���Ӝ�ƃ�P1���R�Y)��5�;伍<7M�d6mY�GB(�|m=�!B�8�9&�0#Zؖ�oaS����y��	�|��v��<$�Q�+4��I�d�6Pը9�(y"�(��@�\ɭ���BrpH�����i�uRM�+��4���?O��t����C
mB�ynXB�Y]�V�Le���h��eCt}�Vf��������������̝B�ƈ���ީ\|H����P �[VF��t�����@��&U�F�P�T�p�O����5f��g�N�a���
G�bG����Y�c���P��'�aư��h��߿�כ��6���!��x�G$� 	��:[��# Wp>m�ʎRc�n4��,�~�VQ-����p�WsH�k�|=�G��a���o�)l{�H�����[i[Uy���s] E^Iܟ�Iq��
����$�.8w{Vm�).~�Z���:H@r/�;�A��M:`��֝z��b�,��q[Ȁ�b"��:�G:)�REY��\�2CW?���4���#�q����8�,:f��(;ʀ7�1��5���g�Ю�(����]��u�L<B�u�+�Ӻ��D�w�;X�%+�Ah������c�Ns���&P�j� ���a�vL�cܙ��rN=8W���0���Dٖ���l,Q����la�)��M�߁Z��f�Z�.Ȥ��� ��#���T(������C3h�u)�'f�Ly��ytl`�j��p�L�U*�D��?�d�@��)L�׸p@�2ljW"8����Ѯ&9�h������(�'��fb��5C��{�Ҵu����k8o���U@���S��B�>:E� �����������F���:��H�-�Ҝ��TW3>�s�g�s��lH�oA>���e�j8��W�u˃~x��,L֖Z#�<X�(��y�D�\ y@aI3�0���3�-~����f�9ϞD�Ik�aox~=�\�KG�#����.��O!�����J��ـ\����M��`w.tN�Ě_rB�F�	�F��ޜ���VZ���tT�@d\�jPk�ZP��Ͳ�ص��q�T��]�
�A����V\6��mE���"�E�2���&�,'�������d�5tr�Tw��zc�}�'v����������MJ%�?_�B�<��ފᚮ��Eǿ=>��ȉ_�23�J���_�?+`���u�(yڂf�ZG�1ֻ�������5���6�lo��ZH����x�tcˑ�V��L�>>���׼������FڣV=��eZڅv�^_��3��t����:�s�BW�(�{�.��&�~�vD��Wo&����<)ObU�,N�t�"&rF8>�^w�#\�n�O�V8R��̋����.�h�i6��b'e����7L	wK��a�2����L��زuy�;����r?��/��B�:1�XT�On2����)��4�X��?��t�s˸��Y+?�pW�)�}�����B�|G��i؛�U[/cR%=n�,L�x[�ڊ�9��֥ɫN- �QZW^Z"�0udW)ke#�Boh�&�x�b�����3C�� ��Qܧ�~�O��.�WiΤ����J���ހ�u|���`�sm&��1c�)|<_��stms��)������G�h�AǮ���cTTY
@b��l�]��.���s��6���\Z�Q2�Y�f���9�>�.�)�C{r���}<M,-�S�aC�����[�`��֝��y͊cږ}uP�3�@�`�d���9��XZ9��ڳ��}UH+�]iH�V�Q���R�9��x��~�ä���L�Az�x!���P8\w��G���I{����m�^(ra4��|ص#F���a�k�J���ݹ�w��)��(�fcN��/2j�7S��-�a�/{���j� ��;���70�(��~ �)�#<��\������t�3JMg��tՓB)����?�z��%;��4:c�A#Ψ�g�q����he��~���ʖ��'���]_����Kכ�j�����b��}|�⌶�y�x��1��!�V�S3����Hv	;l��Z�Θ��|u�m�ssV�I��8�l��r�|���&�0�kns^[?B����]����(?w�I���+r�-^HA����VH�DB���%�?�T�p���+RxJ�2n�zvrm��8G3AU�`��Ϫ���1=*v�E����c�
�4�t�ѕ�Y��sS��%���pS�E����,(������F�B��W[J�Xc.U�1�;��:���	�ށ���[�:mb�6RCh�;����f�a�l�y�u�������O� �Ռs�@q˳��&�f�1�h`�B�-: ΅wR:y،a�q�Ap��X�gGUl㩒.�� ��������k��0\�6�f�P& �p��̀Y�b��{�N|)��8�:���z-6�J1�͘�Z����&#H-%_%�٩-��$�{�NZ�����K���_�I/ܿL��O��_P-"��XCcc���|��S����7��-*��i�s���$C�r0�� �6��Zmu�ӁZ��/d�T�|��Ey`��CF�Yky
���.��.5|@-|�9�,�]�3�{%I�Np5/0�б��NJ��?����K�Isr��H{g:kiԵw2��>1��y�笰��g��o�E�凾K�n�X4������>�-��9\��V�}�RY_c'e���@5%Z�Q��L��Ή���)����$�!,Q���r����$Ѕ����O��V6謈������w�*<ޠ�}rۏي	�MF���~� �-E`�4�y3�T�k����I��(M�,{
lƿ��+�{tk��L����`u{r�b}х`"ޓ�>az���t���|���N��d-Y���4`�f��bc\��[ԅ�"��αڄtn�(VU�>�(�l�y��eV�N� 
ֿ�w3캍 ���6<�<�;����q��b���7������O`�;���m#0��;M�ژ3j`I"ȋo�F
��`�Q��gh�`�Wc�%ՠ��$~�����;�U��� cn��chYUl�����s.�$��5"���
3`��h����?rI�n��l��ףʋ�F]��wm�b�l�a}����,4ó�o��?��"��t(����AQ�#ͥw�¹�a$��n�Rt��La��ds�=W�x;k,]j5O���[ҫh��[�$OmxL�LCܖ�0]=CC�#����8�w����>�ʷZ �o�b��~��)�',�ڑ]�ȔC@}�K���NY���{s[�?ϒ�[Em�9��m򸓾�Q��ͨ��{(�� �����s�&���.�2̨8}RZ1�н�WDץ�у���#\OQM�� L3W��?��[�kic�i���j�!/tT�.�)O��b�)����B}����|��$�h.5ϼ�$��n�����ʶ��5��C�g@o���n]l|���7����+#H��o�2޾~�c�����T��`բ]�� ���_�k�%���2�-�@=;pw e	�� "s�r�z���YD����L#�����
�?$7j����cDo
x�s��P��=��>_��}@7�$ceS���q���ı��.��(�9]�6}��VL|� z��ͅ:S 3y�f��%�6���%Z�4RSF�Q	=�_:ۘD4������ֈ�e���)���5�VkkZL�G~�:�7���N�#iP��vD���M��߬��	�2������͌�&E�1�/h/�1d�$��Zv�;t��ޮ��n[鯷�����/{t�ݗa�6{���
�������Sg@/��\�$������5������/m��jL �K��l^s�WV�6��1`c��30�k�o%c6>@�.;��5�b邂4"&h�&��Y��h嘥��P��֩�il�E���H[ǐ�� �mr����I���Sjお�t�	9IvePk,*��-I�j��? ��Pk�
��j�&�����c�0P�O�ӂ)"�꺷�Qy�*'i��֤��������]b��y��n�%�X��y3�՗�N�`v�.���W�qOL?��o�G��s���C�SH����r6�t��  P�9�� �n"�w�P!b�g�;B��b&k �a!e�r�|�n��G��3��}^g����2����4Ź��u���'\NO�܌xX,%ԋX��I���4\.7�F�U�vܩ�>xߥVxJ��c����LeZ��Dȶ+��� �-�AYp���:3�3�� B<��'�O��R�����a9v(��=B'�(ͳH�pֳ�w��=�:m��٠h��u�+6�}���}on�������n��ĳ����cߠ$���*�*M��n�y�� ~���5�(��ɑS� K���H���_}P-�Ó��jp�q�l8�5�u�*��<9��%ߓ��̷Aw�	���Rr�����;%4�<o������y�4�NX!O�����I(�K~���*��8�h�{/О�0��ʉ��~��?��G�ߑ����n!W�֥���lW�p�����ˀ��i�J�V��&c�x����*�z��m�n�A_ȼ�	V�I��)�YOQ�Zd���΀5��U`����ӥ��n÷�g�ѵ�ZAV|�+��h@k��bG�H��+Ca�0����[���x��_� �n*���@L]p�ݺ�0��Hr�P)4�[t��Q\�É/��A��|�J!�D�M ʦ���u���؅��s��+m�`L�m_ j���}*e-�H��G:����@�0=J� ^��'FW��Ŷ?�c�ШC���r-@6�'(�w�;���
���7^(��c�:��7�9�t�ޤc���5o�zh5����:��ٚ�^X�!YS�`
����x�G|t?�3M�P�¬y6(֭�q�№g�el��o�Kt��l�<�� \I� ��'�E=M��a��a �*��w��Ȋ�����t�qq�\�_lM�s	�󂔟p�����������KQ�O��Y|����I�v	��aՎ�Ƅ��Ea�>s�CKߚi��idj�{�gε��j6J��fW�4�=S����h>c}����J���W��D�L�y�����i��Q����3S�ϭ,�
l����\S�t+���_���=h�/0{��>8R�#������� *f<<�d�J�%mu�ȗW�2�[�Fˌ�������Dk�~����f8��k7Ӡ�~o��*��Z�/�6z���D�#*ʙ��[����
��]�Q�s&e�rD�Eb{EB�\�f��%���}d5�����ʤN�@q9��h5�X���E⎊�*�d�������Q��3����i΃�(��$h��ڸ�V.G_�c��i�#�K>�^��a�{<��	Q~��CL?]_6��0C�Z5��)��~�-����-0f|p1����L�m�I[�,�T�4*����o�#h��Uy�������a��[��D�b
�%q�e�vZ?y�$j �w��IJ�s��-�Kп�\z�V���T�,Q	˲s0kmE.A�@��r�Ø��/�m���&Oxz�����rqP^�L5�q�f�T>M���E��,�' M&���f�I-��3����u��o�=Ucx/����9m��ޫ�9��b���7�����V����v��'H�J���*��'�`~�{݋vCIM�zAa̲S�כH�)�<�Kأȡg�����X��8�����R ��Zt�j�42`U��gm[S�����Ak0�Si�W`T����C�:4Kq��8�,C�ԓ'�Q�ۑٳ�w�rֿa|��l�Zq1�
L�:�%�6c�oQ�ɬa�@6:*�]8+��T�]���X�~�)î��xΈI�#_3V��P٫	�S��0n*�������{�KB��`ܭ���n�ׅbh��[2��e_���(ǯ׍�;�����l�KW�?�.���ʍ��T��ID#Q�pګ9��"��t�m�0��Y�po�֑z����xG�چ��\6lxXfaW��i�����X[���"�nr��qH�%f�1�&c���r�K5�b<3a����W�
n���<N$�'"=僺��2�8������n��R�T+��B�0l�i2(e�ȅK��D/������"5W��;��0*� �5㻼=���>E���*o)����4N�Ow�~�#�)�̛�/�|��k�*�!7{Kϥ�=�X?ߎ��)(o(.����)�e���4���<5ߥ�?g4�%ت��W�z@?e����?�տ��7�TygL|i�a��x|ee$�R6A �vz�<��[]������٠_/� et'���T��r9�y���#�aB|����A/r�.�������p��~z͙:|p?Q�\�|��Kn��R���_��b\V�mc��H��FR��1*��՛n�)J:G?IrDI��~6�����h3K����5��[F�n=L��QmKQbo�O�ۆ��s�[�|��p�|%Y:�6%���y��T�1�\(0��aVr���.$:Rs��I�4U�0�˗wU���3缂ZIQ\1R���a�C}�$�uKpu���m�ϋu�ؓ'�q(��v|���Ή@�f_��`�p%�&�����3��Z��X��~[����:cd%�?3H����z*W2����Tm��/Jc�SKcX��E{�φ\��'2��b���+6�Vl�Q��D�Z(�h�Xo�[J�STكBI�r������o�EVc��C�2�<�,S3ܡ��W<�B���8T�5~���
�G��&d�>Y�1��c��$����	��Lq�-Z���%Q���Ĥ�S�Ȑ��������O�,���el���"�;�x��Du���:EsOpB#U��Id��؋��j瞱���z�����5�+��W[ɡ�##!@�����ه����{'����v�k-+E�L6�j�(�����L'�AǢ��_lZ���q�<�u)|��{���9_�����ȇ��"��B��Q��V�'x �l�H=��o�
�m�Ӏ�/�އ.z��-{/&�D�k6��!8
�?m�E��H�B��YP�vݖ����{+�z�Ҩ�b��|ZE���~*.������eZ�x@�v;zܶ�Y�i�}�x���q�� C~�6[�Ǿ���V�$��Ȧ�+���-��7�Q_v�61���+�j�:�8�� ��Wؔ��46��|[����Lʜ@�Z.�OYѥ:�A�O*&�����/����n�#� ���c�@�a	���ś�8CO)�v:�;Y�x/��s%r����t����/�ݗ�㘻ߜ�e�9l�Lg[V�੸�)�N)�j���z'T�������8�,�*��-�j	C`�E,,�(�4�nP	.F�Y$�Z�:=��k���#	A���"�*�)�5�7��L&�M>��������)�O ����rft#��z��ɹY/����-������F�tQ��\�"��E���m���|T�	�3Ĺ7gʠ+�FM���/o��>�����	'��U�@���tg��\J`UY�o�X���ŭHت����l�wܮ�2��a�#�i�� -~Y�m�p��7����}�y=�#�>XVqީ��ۄ��i�t7��b_�"�� j�co�Vj�"E&���u�����]'�|�P�g���[5cZ,Z!v֢�X!�R��^>���#��t�
�@����R���8�{!_����\`��VY.�A�@�A���rD�Ј]�_�;��C�����u����|�Ƀs�+O���>���0�k���@�b~�xy~O� ��;�[�q�}��V���sd)��M�ίe��RN���<�rr���zӶa�5ۯ���É5�Gʎ,���
czk���,��Y){��*�
����G��2*��ѐQ���t�
kHr�)�È*u!����(2Wm�/�����S�g<%Ս�����Y~�ӻ�����k-�H$�������eT]sXsI��V��g�`AY�:ћ��"0�S�` R̰;	���bИ���̊�aK�F��"wO��%����R��^�S�����"�o6No/�Ϗ��ؠ��-IL�-{�]m�����<���
�B�p�-�RN��w���\������ilU��N���,�̜�{3�Xq���hC�����Q�b��=J��0!o/_�Ji����z�ߛL3ဖkArCG�����U�)�d��`�@�[�l���|\�<�d|���^^�!H{�M7Ĉ�`?d�:�zp��~�4�x_s�Vc}(�)�Jx����.Ԗ�}�ޠ�P積>��.��<2��B��z'�ѩ��~؇��ԓ��<͏Q�~6�W���o5�]������� ]�z%*��Avq�g�7�;��a�Yc������I9#s�+*��3(ŎL�{�ٔJlx� *�XV��E�8�,�+'e! [�j:'�ֽ��� : ��>����}���R�v�&��4t�
�z�شR$��D�K�$�{ye���}��j�te'�]�[���mfjF#+_��G"΍�Ø�]\�,"�+�Ta��@^�s�aY�f��G˷���l�7w���+�����l�)a�?�~�ˢaW�2e�9BT�+���a}�������2�l�Ø�s$P�82Z�%������8�fY=���$��A��b�&��f�VmP(�.�I��R�	<�u�A��;�5�����:���T����bS��GCb���[���_��M�8�.N�S�=az�s�B�Pwvޤ�w
l��9�ɷ~2�E��	�
����,Q�cA##���$�y�v(�]� |r'��B�T�sr�,��7�h��:��j�i�����c�29M{\q�.�9h��߼�K��,�0�E�����6�s�rdv��nw�� 4��
��ݙa^|P�d���,�Nd��,�fN�jx>��l�3� ����]�l����y#�(�E$J��C��j�h���9p�:VҺ���4G"����&	Y�S�S:U�/-�����r�[T�E��T��v��A-0��!1���^����C�15�����ۼ���0;i5���9�6#���y��Sc�^���z����u\������\lX4����fG1���V�h�X �R#�(aWs���#\��SX5�aC)�U�ȽhCr��Z�m�MA�<8pF,��㹵 ����k�õ,oB�����t^�Xa�H�)��~��h	T���Bę8�v����/v�`L��E�'��*�o��n�n�2��9L�.�����1a�=�~U��>�G��Q&���GveG&>1s����2�	�iN��'c(����_��c�)D�F�Nd�]}3AmR��[��Jc�+�Ǖ�8��]���l�n�B(�M��瘈�Z
_I=~-j�o�TSv̓t�<�ˇ�����?�%ā�5j)K~�=�7������#޳(02�݇k�]������gG�\�l�IF'�&^9��K��c�Yf�An=�y�&��O�[�x� 5A`�B����p�ʽ_H�i{x8�9�3�@���]_(�1��ȉ���6@�N�r"շ�/ ����N���k��b�x�N�p��{JsT۶Q#O���P���h�F��`��]z��#�++��p|+�B�x�	L|+IG��eh���F�����|r�FmK����E����5��X�W7ab�`��1CD���s{9�bKv��l��A��qkPo��<B��f�	=���<�(]���؛��4y����<�-r��Q��))ñg	�l�����'`�ؽQɒ��]��}����+!o���5���MbH9%�j���վ�{�I�S�q,���ߗ5�p��JؿN�"����~@We�.����i[�]�6$��>�j��(��Ç�@�b�*��������}%��E*g���H=��г�r�<����)�%r ;dJ�0�j�{�#Ͱ���tV�'�!@��k�z���I�$���-#�T��3�i�B̼����ZxH63��5�u����'���"��!��T�E��R��ZS�Ȃi)�� SY�P����/i�<���<1e��{�|�UVEM.�a�����P�gϻ��3�&���Y��9T��`�� ���J��yҊ(�:x#*&?��~?��ݗ������XE��Ґ�l}w&�`��2-�h���?����3n�2U��|�x�8�@�KD���kE�8��B{�]QpV���ܛ�}m�9�M6y����|������mK7��*�U���+.��*�M��A�si��F��7_�+�^�F�����M���؞��sզ�T�pz�'��@���_1�vp!�����Ό�֑���U�✾YҒs��o������wW�Yc�o�05Ow��_�����J۞��fw������IH��?#NԖ=��������XV~V+z��~�׽�s^:$�b������[^�f�XP�D���xk�;��ZX��,j�W���vuA�B�!���1ŝ�X�kgP�L��D�P����UH/���X�I��q��|8�����|>�x,~У^�������h������h2�h���>iPv�e�o���ո&9o�\��`�Z�pY�Ǳ����	!�'�������2��mz���]���n����>;a�,��x�,<`U�q(�E6i�x_�#�8�\���۶±�ٮ�(Z��"!Ò�����Ⱦεz���5Q�U��$d.����! �uE�w62��d�c�M􎯍�Lp�_��fs&!Nq�5��r[�Z�[
�@$@XZr�
Ӕft�M��s煖�te ��
�˹�3\&JG.�V�9C�y�dV��zp��ꑁ0v�b�F��_�p�7X�(��:� ����V3~�Ё �SR�OMKr|�x�8����������%)c߫!N�K�&=c�>p��t4ON�K��ȳ^���ǹ%w|CwT=���% ^l�:��Ñ2U�.��d=K&�(
٬�����V��8*�\�)N�����O�������>-����#��W�Z:�)�r}VdP�Vfo��0:��x�����U�z�'�~ZwEu`s�]�ϻq�f�=��#�z���~���-�|�&�`=#jn��������O������h�?Z�m�}���1�V�����e"/�C���}@Jd�!�7S��)�,��K�	��������3��>'E*���'�O�g^�|K>���ke�`P��$�#�%�~�!X�Cθ`��7�I�`�4
y������ՠƍ9!��_ؒ �i����F��11�M;Y-�W�5l�g�+��Fv<���t��.GM�̆�ۻ"�����{<ip�ٓQ�=G"u�҈|r��ޑ�ߛXQ�Lx���m���Ϙ�M4f�2FҧHa~R[��C|;K-���E�{V��%|���u�ǻM{��]Vo�t[%��J��&���j۬�P�u�^�=
�Hz)�6WM��;����xm�m�-s'n)`ב�2|���#�?�&��ua:�X���3:峮�(x���Y����b;���s��΅֌.���L{LR�:����%��.�[��p��4�>���]�eu�FX���?�{^7Љ-,��?C���P�tS-����
~��`4��<�ji|�4Ĩ��n�D���0�� Рb?-� &^���fuZ�⁥�B�MN�^s'���]��g�����,����h��P9�Ŗ>�
P0�jwwz5������
�-u�n��[�3���"���v|
&���3\��a���$�)�.nW)��`_C��G���"���YSC��>����j��E�\��E��S�z�1��Ū<`�D�}��'�/��U$��cxש�e��0i�H�BP���6m��B ��Xgl2��e'�X|Z��R�ޗ�V-3)�ކY��u9��@��$���R�J�	���*Z�>�f�����֫�ac�	���X�ʯ>�h%I����x��X��DGf��.0B���s�j��c�yZ_R�"0$:I�4R���LX���Z��)���ͭ���M���G�M��Se�_nY4���'�I7��D7��<�Q����%f�#���K֡-��(b�@�_ſ�대k���g���)����� q!�bE�;sJ̽8O�iJ|kw�|4������`bxUz0���}�8q�)X���S8��d�Ll�F�8����m�|�;�i�̞����lz�ᇯ0�\�z��z>�ċ���j�sy���D�jU�1������-�F"��{�<%�Ŗ�xÙ�w�6j;f��>�@��� �ݏ&�1ǅs�y-2�k�~� pF��z�m\qo�k��}�! X0>KrHdA���@����<,h���K�US�4L! ���	4"$��M�I��r�n���JN߿r�bA,%ظ;&��`��(����K��:VZ����p	M��=�gnb����e�	/c��%�s�%� �I�禎��7�o	yV���_������ �3��Q��U�-l����9ۜ����2l��``��V���{0^�\jia(�Ƶ!D4��P��Q���?1��$%5���t��_;�F��^F�J�e� ^��Qcz��p���t���9��E59�}�\�L�(�?[W&��%ڎ�o<S��LV��i��$���ك8v��@t�0p��m���!�mp��'ư� �����ھ��Õ���%�(8@5F#�����6�p��M�4�/�
,k�+ǅ �D�BkQ��t0�����ڼ�U��g��$������B;R�#,�f��-uk.Z<C���DcP6�yݽm�q
�d`���$9�/�L/_�O,�(�VA Кj�BY�=$,���l2���F�3��p�Nd�X�f9�TR�iD���K;�'O�_5y1�L� ;B[T��F������G�bRu��=`�����-�a����̨�_?ab�3��I���͡�dA�\0dZ�-�H�'�ś�.e��ǩ�O#�|gY��M��A��״�p�����Op�&���8!�Ď���}�c�3Z�W�����*�[jJݵ%�z`��RC��������=SO>cV�m��J:�G�WݪY��UV����."P�T#!��^�β��]k��̕V֎������:/�r��[�N�VJ3�Jl6`imF�Z�N%=�ݔ����i��!�����Zu�j�%���w�H�U�*���i�TzwhJW��R|�kӝ��Iݱ� Q���-B��0Qp2�	�(W���d
W��O�8�^���].�lbܘ�-�670</�j ����}�,�)�����!RN61>����i��/��"��[�[�޴�{��p&���6������E�`Ba̤�\i{F��&'Y��N!i����wSԳ���"��-��/�k�����t+G�^lVf��#��� <W0�E_4^JwҦQ����%�¥PK���J&�EU������	�z��A�����K��0�|��D)��g�5�"�a�?K��Y�诜8�B�C��r�������3�׷?����U�뿘BM<?� � i�?�FPܲ�_�tɐ�h�&^ �F�
C���)���:�ǯ�v���F:��W
��0�ߋX�㠖��j(2�)�Z������y� `J��-�=\���2HC�c�`��W�݈�����{�B�&km,ƌ�gꂍ����c��g�EW�|x�˪��-���%�{���6~ylb������Ǟ���n�4%���[1_����eFŗ�[LA�-�F�/Cq*v��,�.�Xw[�@"M�~�Z{6��I�'���ۗ�_�"�-EJ׭)b��1g����@[�~lI&Z~vn%�/�?S���*G�
�Of�}��LVI�(N�;���<�u��t�/��Ş��#X�$������%ի�{�7��w��6
���B���X}���@u�:G�9�[�x��y[,\����њ�ǪĐ��@v)��1�H�J֚�B�>2B���;��rrb�T/�b�2~����V�m���"Z�^���J{�w�Dc]�-/`FvN2����P�*"Ӎv��,w�f�������P�������k�}٣�MрBa/P�M��Nǩ�L���sZ	U�:�M�d�?e�S7o�|�{�	R��.�p�Ȗ��&�~���A��/P����Q�N ���-G>48 ���F�ݲ��PJ'=��K{k�a��S�6��X�G�>�H���%\ba��B�v�N\��� �~�ޥ���Ɲ�'u�[K;R>Ut �S��L�@]�W�l�Z��"�l�w�s�n���("�.t��hҹ0��6�����R|�4��[U)�e[��n*߉�&#yy������Z3\`�HJ
��S��^�b������2�ޯ�wY�pg5v�y�.�'�cN��%V��pߔ��+��R=�J?�:[;�[]�՗n�@9����S��_-|���%��4"#��P���W��De���[`�D{Iuh�o�,L�@^�֬`�X�W+�[f s��A��=�S��k���n]I��!6�%2s�2����"_�&����L�۾�9:��
�"6>yp0�ì��P\�~e�����8�]}~���?�`_Yi<����s7�_��ܶ͑���x`�
G�yץO�q��6���ӧOpm����$�����DN�A�1�)M3��J]��
y�hQ�.Si��@��2����V��#p�mI���ԙ�hP����-\jﵝ-�H_��V������|$j�����01]9��#,�iFbv�3��v�gC"l@���0H
�;ӡ�^_���o�s2�E�U��N_q�
9I_�:�r�!M1f3!��c����l�ީD������v���{s*0��`k��Câl�v�~*B�9޻5����r���A�\\sna�� bS�'��U���
�N�r�Q앧��8�+v�Z&"��qcL�(�΋���
vd�ɽ1��7o�\(,���C�]=�\#�/�/8��n�mG1���/V༑̹��47k�	�L��ȏ�\H�W��l��Z��S7��E�ɇ3�f�:"���Q���|z�C�x�����b�Am�]uD:�x�G�P���eZm"kD���R?���8.�ũ��gQ����/�����<��h����k��;�tYC����mc����r�I֭�C������!:��U�Ծt��r��.��)�5=sP��c>[U3N����^s=�Jd9T��9]K��_[ \����� ��ee�S0����@Y��i�C��92���w�� y�_ �0�x��\�Ks)�$W��@��X�3�5���0�ӯ[�y3�0���h	���ۢ��;h�g�V)������q���N�����7����2�:/�v�h]0Z	��7��6��)�ȫY
v�a�-JBq���\?�O�E؈�e��U�/��.���>x,~�|R�s��H�o�)=R܀��Z�\2��������=�Mg��:�3Ղ����t��^��r�}����e���n�j�hC$O𷱄a�h����ŰY�.�觗'�`�U���k�H�je<^H��Yz��c5�|{�#\������xٱ�K��s�_��γ���������y"�Mݮ���症�O%����M�1�<�b\wZ2���K�}�t�\��-Q�qa�R�����o�,�y�ju������Co	7W�~�]��ߤ܂V8�:]yν@��%�~&�GȖ��:���)v[��݈ c��k����֧
^�OM���X�կy%��%aC�P~��G���x_ɳ=-�E5 p�c����c��k~��T��2�/"��S �����m���D�FV:)&fl���Tfd��ZSJB�t��̺i�e�%����ZpXg|ڱC�}��{t���8=Q�2Cr�F�(�>�1i��i>�ԞQP
�l��2h$�x��9��g7p�AJ�[G��s+�w<�i�l�����]�K��\6j��I��8��x�-��9ì<�*��<��^��P7��# ���p>V�9�«�\G5����<�h~,��z�z[��u:�4�%�����$-×,�+{�&f�M�߆=����eN� �gQ������L��R��ƁЋ\fA�Y�,q�Wa:�^�E.�q���gjZ�D5��b���2���{O)z׉Կ���`Gz�?��Z�GnJJB����3þ����q�{�Z?g~ #�a=rF����ud�8*��i(J�����W�bg�@D��R���"��YK� Op�|�/aZ#�*��	O�i}/�P+�-�����L�d����5�\�~��#(5����xF����� ى��J�5�E��l�i6��_���g��w!Č@����-�M������e��uU�|�T���ݗ��:lm�v��1z�-J�,8^G�}";ŢWGA��o� ���=���x���.�A��I�%���	O�Qt�8:G��8c~ư�i˨��3,�ua�m�,�Dɲ��52!�g�� ���Ӷ����b��N��_~r[�R��3������R��gpB��H��4%�m��ؠ>!�ڲ�����gz�i�^q����7ek`�������%����!���*K��-VpV�9ʾ�-�^�=%b,���ҒzX�=���R
}A�x�e����-8O�W�^���ǼWC_�0�: �ͷ�X�',����x�薠B��&�~���0p��3Ô��m�2P�!�O����:�a��`��ƙ�:I�kl*BA�Ƴ("7���3-r	�0�PM��#���r��Ybl�&�aP
�kb�)�<u��ȱ�Ѽ�)_u�O���e[8β[D3g�ގ����i���{jɎ(ۖ����tsX�%5�s.��u~k��k�#;��0�����>�;�^�=��#�oX�<��%]3J���z�h;df���FP���N!ͩ��2����̿[�ӸfZ�;�p<�38#=�����e�o��n�H4ɡ�&��5u�J��Z�G��e:2�I׌�E�3����c/��fS����#�9���bۄ�^��6vx��̆�;�P)�
It�P={"�����ne�*md��Q��� |E�M����ЁJ�L����ݮڟ��"Q����:JP�`���jR|�8m����[�$d��'���{����<xQ�H	&2LД��r�#�v5�Yr<Z���4{|��j	Y��G�$�u�6q���{�L�M�
����V�{KE�ᖂ+���D����73�,�`ް�q(�	'��bW��MW���Q��T�?�A�Q��:<�T,v�,0/�<z���7���.|B�g�M67a'�C����Nq*�fߡt{��4^�Jr���_{?mB��v����^����ȧ
: �:�ty>�����rF��D�^���^%�JN����u�_� �*�ͷ R.
�Q,�&�.���8����u	�����׻q6�6 '?o�ɴ�?�p>k�ӕ����gKj�9��/5=�9bo�Q���l���9+0y ���J䇧��ْ�(�d������6��5ځ䵭���d*N& (�㋙�`��`���Ѕ4��r�@��]s�w.�$�7\��aR�ߙ)ut���;M=�� _$Dl�.5���q���$�(J���SLY9�-��C���f�y��p�dwt���w����vx�@�NR* �SC`c5�"���� 8Buߺov�Lf�J�(�����[�s�����ޢȬuQ�o���1���	T<q�rߐ<���� K��ԋ!�T"�w���]�a�V�%Q+����Ծ���cQ!��67�(p��7�Z�P�FxTa8ө�Ju L%x����]S�}j0���ѩ�rw(�j��/�Y^��;gp9�L@^�YJ/X� �"n���%qk9�Pv�A���P~{����
�k-���V�O�mQ�)�1s�>�[*Pf~�ο;�:M��1U�|�S'p��}�.��¶|�5��4j�����>���y�������Qёێ�Q��$\��J��h�B�RΧ��2^dE%:���Fju����>�E�������q��?R}�V<�{1Ӫ\m.�a�z��l�ż�(�h=�q�4�["lZʙ��ޘ��k8x
.� �-��ΙIh
Bֺ��B��{I�g*&b�����g����E%Rw���3r:�W���nVV�z�&�:�አ��=Y�����6�v�Sn��S5-�>�%E����i��� ��#�9���!��'��$�u1�A6�Z����U�YK��>~�0�hͅB�9Jȍ4��%�w�F+7.�ԗḏ	{9:l��Cx@�^0SCx���(oq� 
�!zV1-������̉�T�/���X�XՆf���Ћ������oa4#!��N3UR$mؗ >v%4�tluE���+�.��� D;Ej:
�ᖜ�J��Q�f��h
���;�Dd�Bl����ۺ�"#�-(@|
ij�Y;��#���m�u� @9�9�
�����o����i�b�2��_ұz��`S:h'�tU*�TD�$�j�ɕ9��(��~&���離�����E�&#D'�K�����UX��I2���!e������/��,"�^W�
w��n��������E�3�C/Xl�W��_ ���.� vӍ�IBL�3�I;���q�D��{e�hsҶ�o��#����M�؟`���$����r�]h��P=��26�&�`'�R���n2+�8R}P����"fO�'�x�!�@|Jh[�<�KN<d�a5��eW����`	�%���"\A� �j��S�`�8JM����yF��>3ӂ-�l�)�>tώ���4�
\�ٍF���KZ����OYyO��yk�<���Byq5zPʀ���%�q?2�D���m
���(LG�� :RR���� CM�>F�n3�����7���1zH0�U�h������.��iPe�*ob)Q�c�|\�hƺ�π`W���#��c�e�yNc6{H���2���!;�$~Z�G�5�b��{�د�y�L,�k����!o`Q~i�Ky�:tDgp�U/yz%�~L�D3,	�L>-rQn6����R��"�b<r��?̺��#k�%�%�F@�xD��?Vh;H�&J��A�swQ���T^��A���@�W����:���1�y�#�!o�x)�Gx��
��&�S�Q}���И+6�95��"�H��r�6<x�2�b��#�1zـ�c5>[)���,:�j�(| ��Q��-������)�;pֱ�W�mu�S+�� ÷�t{�n�8C|��Z���������jaE`1�Y&�,<	�X'�֫(�*�T��� 2b.5�A�̎O-�ا�ZgϜ�pGw;���_:�YEq�눼I�_�,���JtM[G/:C��~��} �
�`�`>Ԅtp��+�z�'@�jkcxS��p7gA�~�0�56@`��jE|ܒ+rs1���
�T���8�w�/pfUE��T#�������#�[�(T���-����xZU�T�=�>�2];�'���y�H"��1���:҆)�۔�!V�I�0�H �&��:Q�pbeh��M�cSXy��O�����U�1�� �J0М[����쐱F���8+�k�e���� ��3���%t�H�V�B��`��;��vJ�Xwo?͟��$�z��дW�85l��U�eؿ֪���l�q���=�����O�H����2�?Ev!^�����׈I��a�Np���J�c�ALF}`��i��\���[�A��7!s����$J���r`ɷ�IT��@��ͨ�4��.�.6��JP��+��/��尽����}rf�iU�o���N1�XLm��5l�ׄǍ�2��6�R��w��ڽĕ8�w"˖I���X��`#���2��E�,ee�@�|1}��Ud�s�V)��D-�b_�G�����5����bm�X6B�2{�kۀtxs-W G����?`�&�z��{��Ґ`UL�xaT	�j��6��)2*V0��u�sힰ�������)v@���������eB��"+ !F�����QJ<�4��v3p.L�G�lc�):R��aΡ�sZ|1T�[Ar&��h�hAP�=��d���Z�;�ꁖX�$2�`$�e3D�<K�3R'��E�i&�AE��n�g���(��T<�ϳ[B��25{��|�-I��.�n��R��SdASt��x��F�QT��d���3J#���OEI'I��A�[cĉJ��7M�V���^1��Kd��t��Me���F��,��ۙ���\�� V�K6�s�POwƟ jB�X�}WH-x7S4����wԂU�}2L�<��p.滧�W�e�1�f�.��-3�ȹ�M}��}���p�]�ݔ���ڞ�����������`�|��m��fU�϶�b�0�$d�۟G�"u3�h�D�y)չuO��~K��Ӷ���!�i����b��KL�ha�ƁL�C�����!��	��g��^�� =*�*J
�w��Қ�H��6d&��Ē��*��T�aK+����������fI�eEvS�������N��|��l��V���bi�_gqwn1�R��=��2~7���K֡Ӄ���/�0`fc����qHb�y��fk�F�H�$��9,���bU#�0o�š�tt��<�:A�\��ܶ�����3ڂ�өM���(~��7
��7�Mx�E#�p�R2h�]��F��	�X�^�6�>����/��V��b�.�;~~K����ܖ"���E %���]�}s0��J�q\��k Ởvy��C�A�Xj�'8�9��Zy`֪�9V٩^`j��J������Heܟ�"��4'JtH��Za0#���S�iG^)�c���o����^h���@�Z_����ݤA(���PUƅ6�C L5z#&�8��XDY�˱�z�(N�X��0j��l����ʣ���G��&Q��V�>�]h5�[�WH�]i�t�S�jls���|�W�t:�K��I`���p)�C�p�C4�*�`�L���������C#�iU�1��m�'"���2��r�vƚ�aU��t�M����\�/���~A<0�Ϫ ��b����Q�6)z��{��G����ё��]Ko#���ȩe&�L}�?��� A@�ֈw�8��]�#��O���8_^��Z;>k|w�v ��PU@ҟҊ@c�:��2�5�a>��.!O��n�_����k,�-)���.�
��fr\�ൗ�4������e�K�*���b�mU���]���X�==��?�@r��4QuH�d�$J�[���`��414�G0)�.�Wp9��(a��㓊߻��B��낚S�|�|^�Έxe�³��	��I
�I�������b��6$��$9�?�dݷ�����N	kd�k�O���Gޯ���b�k�>$�䐬�7�g�. 4�h������(�NlzD�
��ݦx�X�R4f� 2�H"�@�Y�׭�x����2��[�@r!T��k�{�x��q�6֬�J������d	j�����C*��Cw�;�%*�tp[k�7-s?,�z��s{�A]�B'3F�uϒ3�}���ମgӼ��A����q���-B����k��X���OS���=�n�����Q���[���P]���$��+�q�-7.=�H�8_tO'|;�F0�090�g�?I�I!��cJo����s�h�q:Ȇ�6�d�"�+��w�A��)N�4;�����`��X^�u�6�mӜ��s���Q=0�ZQb�z��mV�w�K0܏�fU���3�ؚ��<�0��v��I+�W"���+ �#���¬�r���ԓ��%��V/b�&Y�
��i��b��R�\1@�R��,�2�Z]��~�A��5��u]�T�T~Tz*�*_֥��C��!��,e��&U\ʓ��֯#�Ŕ�`����[X��.�Uk���I!������鳆������Yc^B͎�)�ԙ3��$��̉IL�<�Q����)���6���2E�S�8�Ǖit��3�b�.Õt��N��A�� �ͭ�Z�XU�������R�;�����A3�1�(??|��P�+�f�{8F*�����9W_�?eIz��,����ߡo�zl��ձ�yQ��q~�=���3�利U͉�����±F0��m�(A�ʩ�2z6���N ���O�7�6���a�{�;к�h8��]����Y7d{ɡ�/�_���Ƌ��,]a�g
��p���s��V�����j����i7_/��}G�\0��炍��R 4�&���Y��u��=L����\�	ץ�)�/�B�v�eR�.��=d��@��p}o�c� ��R ����[�[��t����,T���	/P�h����d��3�	E1T�b)9
9�s۟��]]�]��&�s��$�s< �ӁYB6қR������@^FdDL�t�m%x�wȧ\�R>;�t )�*0\�W0��z��X�'��?Ȁk��l��6o�d�qXw7s �#�Ep��U�ɳ���M�� !��>�Y�O�� '+�,�/��.9=O8x��a���@Oĕ��
�b���s�2�kA��OYQ{-to�����Rq�����5?��vB�� ��$���Bd���z�TM�#4����l���ϡz�L6o�-xr���&���jF����|._��ݭ�]�V�1���(�E
�KKdK�a�^�_K���֬�`~r�yse�)�;� zޮ[1[����w�):n��/Rcav߼<ִ�̦����X�,�b����DsWx	��dO��h�����\]�m�MՏ8g��� ��$"�F/yX#�%i��p*��(>�h2��iOY>]_�o!�B�嗽��Z�i?C�44:Գ�(:@�e@	�fQ�1���?W�m*7����a��3���f�;xƤ�I�����o�F\�9�=�H�ܞwD])�f �cA���u�k0l���8`��T��xҍ��irn@o͒.s>Д�{ǬNnb��JU9�����UGQ��n*�-%���٨��U]�e1����r��6�r�6�
��g��.>�޸I�q�x�TO�#��D��QD��e�U���HQ~Z�E�?�G;`�\h��0U֡V�?������ؤj�"���6�"�m�9<\�;7ay#�M&2�^n?A&\w&q�>Ŷ]�e�N���Z�^e���J���X98	�܆�/X��Pe��A��m�J���s��Z�SL��"Q�+61LS��*��� ��E.��@s�Rkf�j�x;����O��h�NeΑ )���Н����_ ԇO��!��%v�Y�t6%��V� 
�Po����o2��T���o��"��J³vb��]�`�v_�DZO
��՘b-A��v^ƅԚ�^1����d��)RY�I�Xÿb1�$~k�������8OK�JF�4&��{�<z�TD�����/$���q����p�Yĥ3��8ESY�i~���'X�������Y���e�\f�>�	�_p�YlS�^��|�>���ԕ41oDC7�{8����HO�a+�y≪07Y�i�k�$�<�VB�l��DPZ���JX��^h�����?���I�Q�/)��7�?�B�6:�X"[��!-� <�=�dR痡'� ���hQ�����Ur$�Q�]�Z�0���a��D8
�p��UF̗��L6?{z$�f�e ����e�9U�ؐ��Zn����{�������on��"@�j�k�7�Ѓq�q����'��t��=T�f%aj+U���DO>����?�}(X}͹�ɛ���a'���Z�'�q�t��*���m\y�oAL+�!]�Mf�V�o�P�{>z s2��3�뢵ѩ���� ��YY�����~-��(����7x,��D�'�V\�kޗ8���y�F�X����-��!��6ɱo��s�=�b9�f��2����IQ)`>��x˧F3�o^�x�S�B�@�����3�`O�G�5�9�'z�����pH�=bx�0I2�����/OF!&??j;��]SB(��S!U�tV4!ee�y��S�M�v���&Ge��2{�Q�Ͷw|xj} ޹���W�e��N����v6��L�j;$�50�r�A�>��ٍ��[B����?����K\;f�qS =�p�}�4�a6)�~r��6�1O�懨�O���6�)��</R���.���k~,_��rv��e�}�
H��35�#�q��%�'?_N�Sڝ�E*/���2�4��(�4�B�h����)C!��R~sws	�bR��ע��Y���;$��V�d��>'^8�c!5R<e��������L�%र{�#����g��Do�A����N�1T�qV41����2�@ڏ�hW�~� ���(�pE��PH� �6.^�tqD���e��V��<x;�[E���O�n���Ԍ��M�n*��׽0��xj(n�ϛ��Oz6��V��%�+|d��t�K���ϭ\2��f���T)an�?J�^��GՎ��F�Z�v��ܽj1�hnIV�Ct5���g.�j�
&��}�xNo}-��~k�ӷ
?�F[�⚍>�=?Q�/�  ��CN�j��r��!M�� �^��[�L	몱;E7L$�0%�5ڀٺ��3+Alh|�W3�śT�r�ht��
euXI�    q�+,f�H� �����R�ñ�g�    YZ