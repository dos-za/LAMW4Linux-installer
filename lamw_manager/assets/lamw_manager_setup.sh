#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2227613176"
MD5="98dd27f604a5927ddb6696799f1061d3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23928"
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
	echo Date of packaging: Fri Oct  1 17:43:28 -03 2021
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
�7zXZ  �ִF !   �X����]7] �}��1Dd]����P�t�D��`��ל!>w#c����$��z�n;��Xb����j��b���5��*�Y��Sd+�_���d)��C�����1�$O�M��ڟ�\�w[K?L��K%7��2�U���\��Nt��6A�Y�K��ㅬ8������_y��BS߀�R��Ѩw���r`l���4`Oas���	�V͠�X,Z���'�D� 	6�+芗��>h��yC��cr��yR��tT�K�%�R~��FTi���/�(Ӽ��,a�����ԥ��lȔ����j�d��́k<��D/0��@w�{&=Df��q����&j����V�'��FWpW��"{���$�f㚅&KKI�>��c< #��%����9�+؄S��10��Zr8=]E1C�-��p�C�(��Ezͤ��~"�)� �`a�:j��a��<��-�o9�|=U�4��cX�*R8d<��j�z+�Ch۝����Re�Wh��j��X���W�c��x�.C�=~5��5F[�e�;&��\�4ɼ~�w&�Aؽ��b�m0�lFx�-7*`jD��1~�\�e½���%zu�L��	�����1Uw�ų���p�23��8{����6���:��*����0����ai�P������dn'%t����rlY�r#�EU����ԛ�L��|�wb�j��V&et�2,��D��V|cD*A=�iZ ީX.[߰&�Jo�P�^쿼~I�^��1'�}1=���ƾ�*�WmG��k�� ���=�p���������H3�gC�(bFb�T���=�I����C96���֮7��P8U���Ox�p���w�2@2����NbڮG�m3�Ֆ%
���u��}��*��a<�eEP\6�?�?�z�C�P&b�s�h�c�]��ߜc8 1l��M�|#
�A�}L���c��7�����v��/�$�G��.�e�=�����"���[	6$�y�	�<o_N��-���Z �^��Lg9�HX�o ���"V�
��.�8��>3sn�e�	���y�#�̩Kp�[��_n咍�Qz�=3��g�ކ�.�<�g�m�@ �)�};<�H�#W�d���}�(Ke\|M��5]�������xL@���v�nl��D�D��b�?rx��}�"�T����YP#�`�����=pӴ��++�_~(B�u�J�y��2���n���+(q�PK��}֡������V�UY=��i�c���櫾�pg( eh�8랟NsQ;��V���EقB2�}�f���0䉞P���(�����X.>%��mH�������Xw�?RU�!���M�J�x�� s0�Q�HkZ�}��CO=�˛�����41W�T#Z@���
�������,8�,KJ#��KN!4h��F����a񸸃� i��xWm�)�4v�[�Iw-)|�,-��f�������igȅ����j�0[+N�U��݂o��tN����"�����I�����^49��o�v�I�Ek���ZQzR~s�h��=�Qe�d� %��.5�R�F��^i�6��,`_�n<A��U-֕��\;�?;��CCB�.n�o��
�fY ��]Z��%���n�$���ë��ԣWVbcx�|��(�(8�䖉)/��NtYɇx�mȈ��|j��h�Vfb-��Y3cmZD�S�+T��p���8��j�-�݈�yJ��,	����h!��Q�hΘ�\|� ��P��OPT��Qk�L�AOTv�ݥ�}A���UDF��r��ةi�R��~}�ҙ૔T��D�K����Ϫ�m�E��r_?{e�/��f@&�]& �C3A�(�PG��QD�'���eRN�2�'��d I-$B޽�lUs&�.���F"p��)�O\�-�VӦTq��w��֢�<ٕ,�]g�<�c�d4��+��#�4��7#��)��������@�&,����@�(�����t�F�*ni�{%��?a��%��Hl�ys���dA�^�	ػ���15-���t��
�X\�����_�~���L��Pʊ�=��?>o/�E�'ڡ�f�E<::q�0��rQ��<�*x��_����WT���~�����H�8R�D>6�[�u�ꪽ� {2P!��4R$�#:�ѯaJJ��̄z�c���@�_���-zH�7��@R�5���ԺG���Q�������eg����G%^c��-�Lq�'7O�w<�������kW�{a�4	G�E:ԭ���a7��>��w�ehf�r`�����Qߣ�1��6(J�)�l���ia^��x0��n�!��ڷ�FX�J�bj63p>�_H�(�����#vF	5���<GO�x�}��`�ӢD�3,y��V=7=H٣[i�Nzkx��2�/���;�	����u|�h�$W~T6w��C�ˍ:"�����������eF�N�l�{�\��/��s��>u�XH*�xU6amğ�b�w��t�_�w�R��^]�ƌ�z�fy������C��}����w��K��$39zO��Df��n!CS���S��Ŕֶ���P��qi~����pƾ�-��<?5/�2�WAb#��yJ��n2[�����	0m?��D��(+L!pœ�O�r���B�r���αQ8C>����@��e�V�gL������&`7�1w]��_�t[&�oʒ?�����a��B�;ʡ�h��&4�Ԍ�YV30EG��5��'"Db�F��n��
�@��nzrK���F�k~��\	���F����ށ'Kï�1k0������k�P`�r��Q�/�� B�iJ������K��4��Ƀk¢G��I���7��A�������R�ެ��z��k��hZv��?'�*�<�q&����C��;�����R�*����_�ش�I��?��N�%J�$$}�ɶ�5-B���7�ᗭ��8�J�1gq'�H��8TW����N�u��N��{р�ߌ|�·2r���I��_j_�����}�e��Z�K u,�䒡���$�G.�8_�� �R]{.��- ��;����ǯ����șDTs�2��r���h�	�)Hn���\�	>���lq��f0C����ֆPn��j�[[��r�̱�KmZ��N��}b�g0�"{3�Y�y�N�^.hx-��i��G߂��A�72k�]]2�����~7��=(J�(�ʭJ�{w!�%���K�k�%���G@�߹RKf�@���6�ǜ_�{�!���)X�<�����E
�cԲ�y��A�mBCY��<��N;��i0>�H����!����,,�f)�S�f �@%�l����g�)�!���;�� �l����׭���p긵9�����5'�拶�#����|�5q��\�u��f��e�)tS����#毙;ũt!�I|�:�Pd���%O��F97fV�~ ��4D��X�&���*\ʪqy�w?�q"�Y5h������n��?4z_H2�g�ݢ>"�Fi�Wi��D�0�-6:��Wf�8C��%��^��y]��>/v�c�Y�.��|�oJ��Z(~ќb)&�������r��(�
l��#�PaX�/��9u��FSe��o�a�?^҆ipGYҺ���`��:t�����"�QX�ϑ/�w�����p���ʾ&$���_���^�x�Vu<O}T�Z(�"@0`�L����u$�Rc,��tG��&���[�}�>���I�0���9�*��6����ؖ"m�w0�w�BQu���d+�a6zV�bH�})rGA)�*׿�����rN�\��GQJBR�C��2���"��)�,����{1�@�!�L8�*Q!0�V07?M��7UM�c���i��)������o��,����XJN{��BI�d���R��ڰG�=W����L,l��E����ڟ26�&��d�$&	��I�.~��p�a��/$ۿ�z��V[��Bͯ����K��#Cj_�˅7�D&�_Ȥ;QF����{gC��N)��܎�����mX��C��"'˃�'*���]��l�(��=��i]8�2�[W�z��$o+����>��������P��dhJF?��R��������6���)�G�jJ��Ӄ���dRR��
9s<ƜF9��h�^;.�h��q��D�3�\v��fxdy�*�Lo����/D�RF� ���� �.oB��,�nK�q&�/tt�&d5�Ȫ��#It{�ˁD�ȸ���LIUz	-%BȊ��ϯ}9��TP�Z�|��E<�V�B:�:���8�23�ܑ���hX��9&[�W4U�����\��aO+ve�\�o9��~~>|b�b{�j׌�>��ٌX+Lڊ�����ջ���*x�B�j��Ƒ9wYVB^%-� ����u|�3�]��Mb13
s7sH�T���d��������3��3%ű +L�p���gㆄ��9 �\fCh���>��R	��gM�I(�ߕhr��c¦ιB�(7�· �Hf�o���ep��U+�f��
E ru^*u����Q�d %eԋ�[-�Y9��Ag��3�*���Cr�0� �ri�����>CD�!�le[m�4�-@��p򄆅m�� ��w�CʁL+�J�e17������lFx�1��ʡ�W����.{�8��wr�{�/��|s3K������b�+K!�,��>��lL��9��Yu}�'���C�r!����(��ȚC�Qn	"9��
���;��za��� ���;1dY�?HtH]!P�x	sGN�.��6��&�	�2���ahR#d��ڭ���p����]�Ž��A�oI�*�"�� e��Y<���Nw^�j\|���8�lVE4n����YX�)A��&��m������:z��1j��K˞��/�>0�丱��`\�s�p(ϮO� l��6
�1�yoC[�n�~/z�p�W"0�g����,[�7��Sv�T�ɺ�,e"Z����OYW�
�]�]N�zOń��%�����xK�V(q\��8ř��U#�{J`����2!�%G�Hl�*F��;jT��+�䵽�����_ga�|jyxf,����ow���ִ�]k_�����t����X�N��k��p��S���sb#���g�>�h�ʙK����L@�Q�du#�y��N7�5%���f�<�S?����t��N�h~^��j� 6���Y��Wk���l�\C1�����3��O��3�w�
�=8i0��xsl�S� ��
��Pi��m��fIS鉶�h����8�_A��`��=���t=�G��Om]�*�[���7�����x;C�ƣ��4�\ݗJ��&�h�YP��#��J=M�js�xd��_�V
�'��i���w�=B�y=#�Ͳ��`�^ w�&�Ʒ�L�:��?64Ǭ;d�")t�Jkd�c��ܟ������z��3_�-M�c�4�yg|(O���!R>L�A��L�O�'Ӭ5��y:_be!-Wi��KX�j^�u�t��Ѵ{�uĞ�D�\��Hɧ ����{+q5;hf�{����>�O���&�x�%
6 ��.�`���C sE򘗋���.ug.������3G��3��݂&�Y���F�)j\�:�2\�c���:j+M�i��
u�A2�~7h��pN=q���TȪ��킫�Y�h�_��g�D�
v�5ء�����"��+10�CC_��%���ÝJ>���z�
4��d3������]B;��|��C��u�&�	�	����Q|��y�cf�4��&5+�e5�W�rJXoB��s3��N�+'��Fl1iA ^���]r��WN���N��9"�:a��U�'�z{۬��`��k7O
8E���^�%�(>y>��Z:��ci�,�@�h�g�N[4Bj�l3�l���i���
NnwZ�/�*��7J3�ɼQE��(���5K��V�a��V�278.Z���(V�S%y�����/�7�.��)�-o0�F�Aa��?�8G<�Te\EM^�St���$�1�Ntuq��rM�������u��B\�m�f��V��$���^�m	���۶��2�[�=�����P݆8x�d6)���x-T��k~Ff�.�N~��ڒ�v���Tg?�F?:ي��\~�.D���a]��_��v��)��X�G69�?~'G�Z[^���0z��#m~��ZSm�xu��HJ��.d�9˚�i��b�����'	���|p"�a��4v�ۜ-���][�@j�S�I��fj?��{g��!�H&À_f�C��O��z z�g�i�y��?]@�꼤���S���K���Ť��ɁJ7��kSܘBp������qdAz�G�&�����(2NU�Y[�K�y���~*�.,7��x��Ln��H�D �����npi�	���s0
�K�>������\0�dx�F�B����M�RS��H�Y���ĂTwH�]s�4ل�<���
 xnJ� ��NAX�\x�!ď<씨�5�L�Kz�SCJe��;{~��	��� �`(����8bg�������v?��T��������J7	�b�B;U���󁪄0�,� o01�Շf�=*M�w��o��l1S9T�Y4^J�cP�8�QlD�*�x�w1�o}�	���5696����ǔ��ֻ@û��1I�$��{�R�<+d�
�WE�2��פb�rt�Q�a�(��c��2t͓6�ߝz�c��d�F���.��o~�\���N�Z1H��^���n�s�2�?���kLzM��Vs���9�����7aS7���IM����M�&ml�w�dh{�!�`�!c_����[p F7x�;W����oݳ��L2�/��̑uU����H"win2<���u�̛$��N̺��#<����3}�k���g�M�qw �;�ָ��0�VS �I��f�������.�Q��KJ�kJ�ܻ�}�q�\��\�$ӢZ��j[���ƙ��(Bc�����,�]O��:����l��!��)�'�d ��Q�މ�T�� E~�mwd�%&����oH:.=T�h"��OV�{7� �I�Z�k�6�⽌�*BۄZ������a��O��d�8����7#恗�㊧#�f���[���_�ܖn�T�F�����<;��ݛ���ql���8�m�A��u�-�J��0;e������-�P�1�4Pv�@�A?�ɑtK�$����lTL�߶�?bS��\J�7�~��0�3L'�G�7�B�p��i��Ԭ9\�|2km��O����Mo})4�4P�jw�!m�2R<[�О��W�%/�����[�QR�7���]	���.�,�<(�����+uX-�ߵt�JWz���0�Rm�x>s+4����1҆����$��n�V[H�_�}�[���a�3����E?�UIľ���f7 �ͨL��X��/]�ǡˉ�O�r���,Í��\i��T��vC�;.݉o��)�����$���O�`��q�`Q
Ԥœ��-������n�����0F�\��������0!B�V�[���R�MsB�ڏ��,h��9@�h��Bb�oʻT�;��h��>lD�}^ĸ�kI����ȩ���EJp�E�h;V�[(� l��?yÆ���Q���8��~�P��P�uHS�.f*��4v���F J���VΊZ��ӾN�C4<U��~�ZM����o�W9F�����c��+(deC����ӿ!��P��n!������xp����%���-�O:]F~�{��h����[z��΂(�w�ŀ����^��9�gq�ҾYq*�ց��J�cA=����� ��n2#EMݍ^�&���7����RCO�����e��Ǽ��/���Q ����.���̿y�q�	�����7ֽ� �XYRc�a�JI7��N+���"�2�3{o1�)}w��b����@���m*5�9IS�~|�3Ln��aa0�Xs��QKV9g�G�4\UXc�`PC'�62���|��=�|�u��;r�T~��j��i�\"N{�ങ$W�,��w���"U��)8� ֺ���6E���,�Q�Q�y�N��L,��`��2���{l �91��=v��T�Q���ɹK�scG,.�}�[����J�'�W�Crը��_W(P�h��k	���-�#�9"�9+���p�,�y!g{f�a�v��36.b\Ո�M�vm�C�>Z�O��k&�8|v=琎�	lM���M�#;�C�;���C�-ן� d&@��X�M�d�?���*�����^��SuB�x�����~2��F�@zG"�v�nlZ�L��� 57�B�b�u������:/oU�fy�93v��?�'ڧ&e`F'���ߨ���ci����3f�p���g��]�q���_5'YSp���a��;�����c�ep�"ve��EuyK����*������Hś�MXn�s4+R���Yn�ɐ��pj[��9�[I���T��I�^��.Ѿ4〈I�g�@�`��J�Y*���46��"�E�r�C��޳>���XN��{ޠz���r8����t��d�4�U�H8N�������Ӎ�,���xa�*�R�
ԐTh���S3]���M�ۮ��󏬧U���F���*6}m��lA��$>Y�ܡ�����Tɡ{i��狰q%"SBV44�38�ѣrT�X!���1����D�v�D��/�#�+�-m�UJ�ͺ�ѼBB��m�x���y��M9�&?���yזx�}�\�b�?a s��<&i��n�IUJI~�lpb��CH����¹�=$!�X$P@�X�-��'����1i�c����256�&c�8VM� ���Q$4]��qN?��ԝC�p50ŇNh�W��C���X�+mo�#y�k��=�=p�Hu�
E��:r/X��8NL����!u
����O�o-�]���"�.�aGa�GziM�S�o ���#(���-�#�)��(����x�!����m	R��z^~$���<!����G��#_�0%⠰���
<��te�ӈژ'� $���Z�Û��8�p�Gv<�DJ���o(���Q��d�=*��El�DcM��|�2|���i��^xRm5�vc��ڋ�ЯsF�T_H8�!�M���8xC��� �~-�Ge+�'H��q��u�rܰ\��Bys���h5'��l<��{6F�`bZ�bp�V�^�@���T��=M���@ˡ3w�e�����I�9�Au��;;�U$<����&
�6j�c��.�&/�i����"��J{��M�� �V:o��^Aq��f�rn�jhA�H]rޤ�8zu�$Ith�j�9@L�J�H�LB-�2}�J���B�l����SL�X���E�cw,=�34ɽh2CY�����]�'d��d��¥�N�p�l��R,������q��o^�ُ���<�����d�3k��1�:y��c����A�K�l�B$Ԡ=;!{.IFJZ���ϒbP�5����s8#C��h�[���A�!��Rǭ���Ԫ���+Đ����ŏ/V������ǽEЂ3�W�7]H[��6��z����Ru���>���#:�B�F{��W2�|���D�w%�ĕ�þ�7�M�:T�r8�=(�:��2�vkl��lȟ⯲e��t��2�b�3>�ǀEn�������ak%9�K?���X��$������M�yy�?���\i��p����-Żg6��4����x�����"�-V�է��S�!�&��7�4'sru>�=V��=rϧY�����jw��ܠ�eE�|F�Y/S��3a�2�p���	��|�;w]w�a8��a���X�IO��L�У���~��u;����
\��i�)�#,+1��0?��5%�j��kz�^��%Κ�/�I��5�w��#@R"�Y��]H�g��{q�L��8Io9y���x�*�k�#(I�'m`�9�Eܛ([j�4	�8�c���_,{ՌlR����W��Eb(HAS������n�!9�r@�ӍS�#-<����1	�c�>�u�混xZ��d�r�
=�)�^K��oϛ�ʩJ�L1o�ϑ���#p�|��X9-��^�,Y�R攮A�H-I�5/�zϹg��{
��#'r2Yp��<���p΃���duY!��	���{����)+����-������Kj5�H6"l��F�?O9�U�H7d[�0���I[��~�~I�O#�AP�I
o!*�p���
��_ج�W1s����sd�b��G��)x�GV�܎��t^��=.{���#dI��:�zO}˜y�B�޸,|Ӑ�;�Rybe簶�����\��.��E�)���4`F�n�64�X��=8�ԀB�k	�������	5�_�w����Ew���p��_Q�0ӛ���"d��T'��,rv��S/�Y,kD�9�펦._\SB�����:�R�Q�qm���'S!������,�1u�LkV:�"�S���Sָ������,��	,�]����l$����S�m�a�!A8��Ԥ��B�,��xW�7�Cƺ��_�%�?����<GG̅PX�� ����2%����\߃�.�05��1��p�'M��@Hpm�
m���Ną���JMǆ�v�2{��d�3ŷVH�����8��t���(=�39zg�T�f4�S�[��Z�q;�B�ִz<��nLz�����7��[T�ل<ݫ:yO��9�́����ϝﷳ�"��m��z�Syiq�i�]�Ӈ���0rJ���k8��5��O��ȯ∃-[L=l���m��l��3��M��"��ݦ�F\1a�D�c�	�}Ԫ�jm�р`�Z�4�dSV*�U�/���c��K���s��K��T���;�5��q^TT��"����s����*�椨�V�/�=��a�9���9���'���VE�E�;����Z���fI�������\���sG ���Z�G�&��r6��Ը��ڎ��(�, 8����-l �]�jU�-<Z�A�ӡ&(�%� ��H9J���gsئ�o'�r��j�n!�����*o	[i���� ��b�P�ϣu訜�ܻ8w�Rgxy��.y���K��^�H�>E��wh��ⵈ�<�e2eh�����A b��&T=$�bJ��^i�'��R�0&s}�F��Ԝx��&g��M�y��=$p���J���|h�r��~��*��v�c�C�]�X���r� �������j�u�28�%�$6T�y5"՜ L9��jP��O��h��|o��'�H��C֓�L�q9MISx��8�����я6w��M�F"��j�"rP��ܶЁ���C׋�Ijg\:���trv�Y#�4�D3>����#b����$��U��e�e,P�R{Ś��6G����.Ef������w*�\��i%��i�I�<�NVDM�!����g+a��\�K�3�4k�<̐��Wl8�!�z��n؏�.��zy�-�B���X�J�Ԩ�H�pe���N�����vѬ���9�
=%� 1�`��"��1F/�b=��n���h��^�!l�D����ا���:�IfS��H�h�y�X��k[��1w�`j;iAG�NE�۩?3(��w&��GH�ׯ����7Xw�BYM{�/A���|��}��G���˚��x����������d�ۡr7�%�P���a���<��-k���#��Î0��F�#*��M$p3N�[5�d�7n �\կ�62ŰU./��l��b���ti�`���v�Rl��h4HbLI�
��1q ��/V�j�E=H�=bC<Yd�Ix=T��U�ⷴ�(}s��Ŭi�P4 �r�7�Hu� ��$�>�O�6�@��(���m��T2)�@(�{2ÊP��Z$�h̵�Y����L��?�3�R��YV�u)���@^BgM �F�c��Պ0�� �o`���K��%��L��Hj��D)�]�{c������t�A�a� �"?| w��&g����o�>ǷT[=�s��EҜk��`��n�MU�����I�m����X}~����������p���#��N8���n���� /bF1|������ �K�g?��:kbR��b�qC��QݡP~�J� ��Z*9Țyt ;��>��FbXgi�}�og8���Ѩ��RB^3���P٠�st��0�榝��?��y�wD��)��G㧡��VP| ���`��X׃�3X�S6��P���/
饽n͒~K�W�)��~���P�lAk�&*q��[r���w�����S1����) �_�h�d��X�)L2g$����}�%{p�W���8����wPN-X��jﯳ�B����i���t�ٯ��<��N���S&�)�WcK�]`T&��K��̥�t��ѻ��v����j2�J�"��Ђ�j[G�6�b���L��������L��9������h�<����?m%��ё�-��U�:���Γ#U]�^�4C�$Xx�������AN���-���_o��02��k
����9�H]�1;eT�B&:']����,.����' ٍ�X"�"ew���c�`�FW�Eձr<�Ѿs1��$��V�4]&�4�IQæ�+�b�/��K`���젓n�z�  �rR:���d+d����}�D� ���ت�d�܃��>�l!��Q(�Q[Cv�!+��o����|V?D��w�rq�&�3�I:g<��7N����3��42�o��ܹN���`G.��b���#7N��'�=��T�e:{%'785u@�얡���
v -�GcmV�H�ɤ���p�͓��߃�lp	��Ö ��o�k˚�Qp.�w/���Z��L��Lh��G��:Y*�Ð��g.��|ґM��X��f�њމ��W�yK�\�{ؽ�}������*�'��Z.���	*�&�8�Q!�r�z%a�=��ɛ�ykÞWv�r��w�/e �â�m]�F�8	Ӎ�̓��[���pr7��S��)�xf���mh(g.�}��YyQ�� JXw��O;N[s]�% }��Z�3DHJFX,� ^�1��/�W����B&~���i�u�#hJhB�A�П�"1�ͷ ~���Ŷ��+N�ϼ`�D���B�i�9�byC��i��L�M��WE���w�wSC�V7���e��^��r?XӐ�U��+u?�N#�_��ӻ�h�ێ���۱m�<^]�^�����|P�W�Ӵ��������"y��إ�Wb��<k!j2L�c���%"!��y/�����P�k�S�_e��oP���D�� `�e4IV1�̐W�G2��Z���F|=\ې��9ƭ��]�5�� �J6P��JF�@Y;43�3F��كI��	�i����?�����f���w#�NU`�lYz��1>�q��Ah��m�}�y��B,�Q5��`c�o�0I
�ez&|�[�L	�D(X�߽����C�5���KK0��l�T�X%0���H9��P�$���×R�^/Ň�����W�lD �(�����W�vk�����%]�{��UZA�D�+�d�2Q�6>z2r͛���haY�Tb��z6����-��a��DA���wF�~>�^n���ʇTӮ��O�4���lyA��NV�"� s��e3�S(���I���i���~�V�����,'q�%�f;V�+%o�� ��tS�Ɂ˪@�|<�C7ٌp�Y̇5I�\%@�w�:��J�Kj���}�=�����M��� ��+�2$�vs}�:f�v�d��C�(�o�*��D�5��鿑^Up����E�J�~��ߨf��sf] ��/P5��8�I�ޘ�/c���v���n�T��*�y�#r_Cv'��n�$g:�o����@��5��.�4>j���
����k�1B*U��l�W��l�&��e(3X�6/F�v���w���T�"��cK��Yw�����,@�[��ZcL���l�R߼8C`-W��kG�\�<�~��7�ݔ�r[J��	z�"�]0Z��9��L�2h2�|�­�|t�O�a�����а�����!nm�ڒ��K��{�0��Ƀ��!os��i�RV)<��ZZ{��6������)>�6g�O�Xc���f�Gߴ�}�,<�8�eg
��A��I�*�	r��:�^	8t��'2������tq-E>�|[R�#���]�b��O�y��©s&U��ƵL,Hg)Cfm=��?42df.�L4׸��Ż���ႍ]G'����@��<70��\O!4N��kK
}�	pÐ�k>$t�P�=�!YT��4��1����)F�.����Bz��30ڿ�d�?	Lw�r��Z��}�X:�`憎�͹յk�WPJ4�r}��5Q���N���� ��l��
���'�`+f*��N���'�]Z�u�e<�8cR\��jhR8���&����|Y(>�Hٜ˽���m{���C�/|z��Ӽ��폆f��+�;�ݸ����4�K�z6�R+/�㎈��l�R�"B[���F ϑ[�Z��9u91��wn�'��������H%�^3���� ��yGd����K%�!l�$�7�����s�����%��n;��h�#p����cS�tfJ`mʴ��@|B`.�X:|�8�z��d��$5ژ0�%�EmG���l\��C���M�>�B�3��_��~��oO%�0�����	��|�5:���ɪ��Qhf�݈	�KS����N��W�D�O�`?���%}O��j��#QįPC��)��ǥF�%9ݽ'fKRs����$���vTXr�����lB=�9��$��m.d/�s->G'_�����?�ͱ���(��pG�o��Z�o�=f�Fg�K�8Z����w�F{�4���4����9Nos�5�ԝ��BT��V�Ӡ�'�u�VVT��;���`�k2��j�:�X�
���M�;�O�V1G��|����y{�.���ڦY�lt�ʔ�p��G;���vr�Bk�~�nq9�]¥�%9r�V�༸-[��$4������ņ:���3ƈ�x�x���L��j*Ң�GT�)f8���'�����!�jz����ԝ[����u�لֳ�u��B�Ώ��UO
e�M�˫G�͟�$T
&��9O�v�W�id��u}���j�@e�#)]��C�0z��ͯ-0�1I���� �o�]��QN,�Ij�΅���pqla�#��[J����F9��/V�_G�+eH�����8��p�����{�^���t\1��2��1�$劏<��1d��q:!ٌk���U���W�\�eN�E7*��y�(��2���:����J�N��/���{���?0*�0����EB���>
#��I!"TҸk,rj�\�D�m]��my�z��t�J;��*��� ����ط�� D��Vj�\� ;d��^��\��>i�ߨ!��h�ў��+MO��U5��u��8�v�u�Av��B�� ��?X�ұE���7��	��� ��E���V�"0��ž���RZ��O$���s�f7�`���v̱�hx|8�,//�C����u�ۿ�W�Au�����ebL�5A�!�G� �'����5����Tm��4fO�$�˻�#�Ƭ|Ӏ�t9]y�D5p�2���U'u��w�����@�	/rT�ε��C�H3��:��eE��V8x37���㫆rP� _�S"�I����S�[�o�cQM\�>��R�Z��iO8�����[�����}yGQ��=qh
ۇkev��u�r	�~�>`��U�wB�u�K���9*�?��u��
p1R��b1�s�dJ&C���kS'����§N�jݝɣCƭ��7���I�2ʍ�Oർ�� �ⱀ�A���dk�&��߱I?U����&6��{u�wɓ� 9��p��  Y�m�I�i���C�3�~6̽~��G63�x��qWj#���6��G�"���ӎ����b��GQ�hu��ƩTa�Ɯp*�P��F�GW+�4��Uq���ۋ����|��t�L��dO�S�8��3�o�s�B�G�{*���?!2�FX�vկ�P�C�}���(�R��/PQuv�e�!`����RI`�)��+��"y��]�C����~ �wܷ�&ƌ2�+~ț�#w��!~Ҭ��@�|�2ק�u �H�Ud����CxP�D���M�iN�w�d��8��'���f7ٿ� �U��6V^i��OZ��ݡ^B��ܡ��(|�X/d~�%Z�����f�7G���G4)�?�DY�Z��.�.ы���b�����g��x{[\!;������yǕ+����Y�B3�t�L�"���F{h n��"�0a�m��A����FHv��%�N*R��n��IO�Nõ�
����k�ByE t�GPB���$�5��c9ﻑE~�155g~��ٵ��CP&�^K+�����(�c�0�-MZ��_�-�)A��+zh�&ˣ%��C����eW>)�B��ÂM�i�~/���3�6�����~��hsJ�,j�~�ʭP�Pi�!@*���u�����7C>\�����=.
9��\�@���%�S��*繁Է�D	����:��B��jj���Q�L�0p�}�}����N���+Ej��E�����<t�|(G)��}'HoW�OiuL
�aT�X�d�,)3j����M�!�J
�@�W��6jo�j�Z���D8��c9\}B�2L�Ϝ�9mDh�{��*��.5�B�&�_E���V��N�k;�
k��|�nT��Uk�f���z�W�m���B㈭cs��{��1����%�����'�e��l�!%�ĳ�'0_9B���������0����&"�����Q�D��Z��M1�bY��z�]|&:4@�#���o�d$�/�@���M�U�۞ͤ�?�JgaE�=�y�5�'ӞJ�����fq^]z+�m���,���σ,�o�h:�M3�Vߡ�	S����a�F�L�"r�ERׇ�o�w��49��
��e����{=�&�a$5�f�?t0(<vs�ް/��ɺ��z�d	I��1)�:�E�T�-]b�.(�{�+ñ�_k�^��Ѻ�3�ZC*�A�,yE	ٝx�M\�9C�߬d�3۽ �;+�����䀅�dt+�����Ò�#"�(̥���􄝛CyY�W/� ��]�9��i�����A��������D;�Kd%q�A�`Ax��ҡ�ٙ���<�Zٙpz �&$*�+�C�l���/�g��F:��%;���� ����e�{���{[/)Rr����/�>OON)����p�r���߾ʁ���2�4�kAaC��1�֝��%���/���9&�� ��Wi�����EJVh�Rߙ燨h��l�l����@�ۯ%�G�^�ꎜ������C�����n�{�;�V�=jv~�x�v�FOih�����f�}=�,�2q���7a�Fz6�+>8}㔦⹪v/)n͊����m��� ���g��U��_������WCO4��3���?��Y�]�{�Ct��"{��ӻ�&�I3GwZ�����o#�l�� K�=�c*��n�E4���Ԉ��7�fy�R��A�1�?���=ǁ1�[��gg~����*��*�� �f"�n���h�Y¢������=hW� ��^:�!Q��A��Z��r�����L��e��0�{���Z����é�����K���,��2��T��~j�3 ?ϩ�=�
V��o|��<���B${��<$�&�|��WuLk]h')��Z�z�9�*����苗�m7UbuPS�����"�9��_Ձ�%D㟀.I|��s��/��
	�X?`���RM��uC���SY�/���&=d� ��8��$��[�L�j���U%7@�'�� ?��j{�֦֖4��[-~�!*'3�t�G�{�fD��6��v]hG�
:�s�������+�ވi�4�+���;?Ehl�8�qS̥����ٛ�U|`%�<���7���|�p"='��G����2�w��]�6w#����
ѹ[I�T=CAxLѩ�*7�A��RIŹ��jf�D���,�#�}s�n��e�]��6a�K��=^�1�����ԋ{�W�M_݉A����}�n��
�M�h~Ketp?����oqO�	��z>h���&�ߌAٵg��0��5���Q�$�q*)���Դ��w���Q9���dV�2�?6�{;�z�m~m��aT���ת�}�kدګE��.$���1�Jƛo�}��6��|FfAFyԀ�����j��S}�a��0�V����#�"w�z��$�&W;	��W4��7w�?�v-�Ddq?n�#�Yc7C"����S6����[�o6����硱�/��_fڅ	a�֦��ɽ�eM0M�U���3�C�Uܤ��ף���tm�D�f�O�ңbƕn*<�M(˞� V��9Ӯ�;96���������J'Cu¹=t�ٝn�t���E�{�q��%pp�@��zoY|���g�v��N#�:�-������Vh�W���{�#�]~rE��"'+߈�|0���*#-!�{]�������"�����x�&M����� �sV��R��f�)��^G"�BE��j���E���m$�o�wL�0b��4ʿ��F���$Q�! �ki�**U�hP U�ji�e!�-��'�+�0�:=*�4��^�kQ9��h�K\�iɋ�^yU�Ge%)��$��צ�%��?�>U����z��qĲ� ��������X	��?� ����o^#���`Yh� ��
7FF�`��3m�췳.7�?ɭ5 �h����Rr��Gdgi�ÞF��H"��yЙ�~N�c�����+�7}�Sl�	F������=�?PP�"]/����<�; p_�������{H�ֲ��ٸj��m��=7�$��&�
;F��S���FB{'�;ly�X�ί����]f�|���[?���-�s�Ȯ�,Q�[r/����֌zߺ��OP��[���@|����Lz��8��	 45���5-R��6�����.O�ڠ#��'�WW��������1ݻ(MU8���R62�����k�� <k��������2�v��ǐ/�����^��n��~z�lY�
xq}��畆�1��hX��J�6t3D�hG�ԫh��W�N�63��
O��M��D��6�cL�G�"戩� �7�=Ù%Ȝ0p��0�����x�]�c�:@�i���wy ����O&���i̓=,�?�n�R�v59��j�f����j����A�~_1��2^/�um����Lo�[-��� ����좳�[.9���ͅ��ƶmk����e�A���󾴢U}���׭B��DP�CyB|w��p����/�E�c��e��P��qE6�L�e�:��.�`��ψ��O |��*�;V��KĠ�.�,�� ���n��jH�T��೫[�}���5�څ��r#�}Z�+��{ Aﷲ�'�ﭱ�ɑ�V"����Q��AwgP��w�֐ K��X)�t�G����n�o/V%2�3�y1�')�Όz�*�������s�b�.Y!];չ��7�+!�'�N��rm�zoU��{<�z��h�w�l+��ɵ�5��k{C}�ٻ)4Uۛ��0�.�DH�#YBBZ�x���D�b���*n�rTl��\cLEZ������yz�.���?<:h��b{�L�@��= ��V?�tT������ ��Ȧ��a���-^,`�Ѯ���_\�>�Qsp>f/�u�KXqТ_KѺ�@��aZ���î%A~�I*�����X�0Ht�_�����S�<4#����P)�`���+��P���keĘT���)e�G��0'�	�?Q$���B\��+�ͳ�ڞLX�Ml6w8~"/?��5U5ғlU3>�����+�����(h�E)��?��;�8�X�/&�.*d^���G���}ϗ�M��5@���%�?�Q�:���D���K��6�Ӎ�cl��(uS:�8�C�E�҇�|m���*m2���s~��"_��Oop6皭�Jy��J�n�Y�]'� ß'��	�k�=W]�7Y_�"���
jn�`�^X��f7���A����� �u��~���W�� ���)�s�������}3��˥配����7�@6�6�*��R0��{�mU}�7/]CnZ�h���~&�O�������a~�H;K�ȯ'Xk����v�׶���J�!�c�'���<��-�h|y�:�_V8cJ�MT�.�
�4&mh����3컸�iP_`�qY��+j�h))������N!_�lW�������/�f����?3z���g�Bq�-!�(z����w��3R(��,���I�3_��t;�v��(�7��^����Ц;�i�L�n�S�|
C�1�ՅS�Ȥi�&�݅����C��,��$���P:���J@�20���[$�\�l\���y=ny��)�7&z�����p�}�2��ó'��	87E5�����{� �/A�5�'�\���Sl@�{(���J�\8��&H��ϸ��A�����9bgro@�uR�@���������+T�l)?n�`Ky)^�l����F��?�vd����>2�l��|9�^����d0�bax��WZ��}�{��JPQ�(]/ۮ=�I�֋A��v�J�x�8C��I?�W���o5���k�ӵ���FW������(���q"�Q�_�MA"��v�A�(�*� ����5�XG���r_�,�U�~[����nA��G�=���v��S"�}V�c���r�{�2�3(��ɞ�A��Q �QW��1�\��m������Ӻ��G��k�	�m����8tb�Qz�tL=
�~)�y[��;O+�Ҝ��]�n"5�L�L�V�^P�ꐰ�7M��ݲn����P���X������W:753XP>�x# ��������#:���,G�WiaѠ���j4W��_��78���Di��.�ݽSx�n��4�V���s��]�r���,#m%�lǭ]�;W����q�Rp�Gh����Qi��v?6)�4��2��L�߻��}��sJ\ӥ���/p#T1�H�������H�G�A Z�C 7�i��䛚%�O��w�?4��n�*��Jxu��9��+5�ۭ��~i�bק��Z��aL���ѡ7h�G8z�KI�p=
�dũm�Y�_�X��*��#�z����Rt�E&ɞ�����d#�*c�3nn�PQ�� PpIpQ���էϹ����:�@E��u�����|�������6��<�XD�'̟7�c�%Ơ<�uñU��yew��d��1AM��/$q�aǮ�� o�D��lg[7���@���by״�ʭ���E���]�5����s؅��2ك�U��	$�%�8m$��KM�L;��4�<GSC�u" 2`��㚕wQUsz��}b����<�qU�}����e�!�߭,D����$��ja���1�b]E��k0�i�3��	J��v�M�h� �9�x�-K>=%�9�� 
UN�NbX�N �.(
6\{`����y{�9Z"up���Ъ�޻��kk�P�������A�b��D6A�2g/k/����g��a�`ÀM��.20���*a��ܟ9TԠ����������6ܹY8t��H�/9Y���q��ʆh�,)cՌ�s~��7�8|�&q�GAR��v%$��Y�Ԯ {��T�A��6'm����k5�&������	�����C�h�h����㧾]��w�wTz�|ձ�H��m�z�8��U��	�gn/H���A�x�}2�A�LXje���9KB�6�{-k�9-k�G�٠��H>Θ)c@�ɂ�4��H�|O�#�&���+�xZ換X�WQ�	zF�m�c��eJ�[i�z����,d�-u)��[)��	��.����2+l�T�p�nZ���bp����k�̘7�;pvS�k�7��f����)�� ��~;��y9���v��5�3�F�g�s�Y=�m)�0�)��(��y��'5PI���g�;�'��S.�@T�!�Ȧqc�[0a��P��8�y�&5g��[Oԧ�.~��xY����=/��|m�w���G��U���{��}��T/���_n!�U��Y�q��#�y�F�Q��r���Ӳ�JI������ʓ����Bqx����f5$��9���
���=vj����Y�����	��|_HYr�l��&Ͼ5�{�t��������<�uzD~jH��Wq��ȋ���U���/9`Ɩ�K�2%o��:e������R��2ƿ��2�~�L��B�� \����`�{�P�s��D�{=�g��n��Y&b��z�SZNl�|��n��*S�8��g��[�9VWiAyɱI�]뷖bųW��-��rf�܍��I� d~��C�q����'�N��FpO��b�:3��+�f��8���+�٤�g~X�6�0F��Cv J��H��9n-4A_l�˙�+��-J�@�0-�-s���9�~.Ķ�@��e��1�؝���}�k�� ��2+Y�)$�n�N���<���Tٲ�V�'�"�@��2I�Y���6E$�QjL��R]����J�|�S՜�����%��U։xg�kEvG�o�p_�[Ys�����ᰂB��vk{+E� u��%�� '����t�]yZ_��g>/@h'�c�s9ˇ �S[di���H0.Dȼ�XĲ�zK^���Z9>a˶hϬ�W�R���e�����l�$nA��vO���z���.���y��.o�Wުۅ7d�����W�U��lDQkP%�3� B�:��΁v�Q��B&��y|ߜ��T�]%��{9M�)�G�&zZ-� ��=�ߚ��Pk��!�5�����e[F9ԁ�(��Zz��<@qgâX���%>��t˳��Q2�Ęj�c�Â�����O�|�P�%���e.�exF<�S�?.�&����O��e>�
��m�o�b�d�Tx��b�l�ށ ��ڻ��!�Q���� ���'J�O!��)��:+�����iy��B�C���C�wVg�������t����;�$X�O^ �9����s�<���4P����²z�0!y�.��R;>�\\C�6�-���!�_��7o%v����P��?�?�h bI��s{'�܏��nuZq'L��4�����8���(�}�ʚ����+�P��+���¤��7��ٍ'���
`�.�����|��C��/�ھ}�A	�an�(e����ǹ�bw�?`um�1'۴7��Z��+H͝��XKb��El����fM����0�<@Q���8�ǡ$�3�7�hq�+H%�
���W���������M(Fa�ߣ1�I2֦cЪ�EO%F�5<t��E�������6A�*�$_�yW ��pg�F�ǋ�U�|� ���H��Ƅ  ����&o Ӻ��ᔟ��g�    YZ