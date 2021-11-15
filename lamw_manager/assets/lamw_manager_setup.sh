#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="113294718"
MD5="ad1eccaa47584cff0031db8914afa7d8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24736"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 23:37:38 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
�7zXZ  �ִF !   �X����`^] �}��1Dd]����P�t�F�U}�T���^�6_���ۅ���)'��hQuBG�5�{�yZ��V�7��|XqĨ�u�����S�A������4i  `��-hJ�-�5����k���h�f���<fm��v�9.��g�� +��D\ń�11��hZ��$���킢Ŵ����=Ćh�:~z������g�Ѧ����|�ML�K��73K�K��Kӭ�c�)���.Ǉ���w7 ]H�b��-�3
E��8���i"@�n)�_��4���g�r��v���Zh����%/5�Z�9p���8�;Z�"]�#s�:���!��>e�OM�0��x������Ե\W�h�qI%�3�[�j��D�6�Sj�_v��v�܀	揝��­�.�혐��]f�����RdA_�fb�_LŤ"��I��_+#�QD #q VÎz���$��ܼ��p1"�C�lĬ ��༣ ]^�.VЧ)�Y�<���s\���.�w � X6����w�L#����=�h8�������>��p���@SUN�<�}��U���C�p`�(@���4��5;W����
p�"�J2��E;r� ,�L�	@y�F���A��s�ŏ3M�)+Sv(j�鞘;L
/U`� �|��fF�.z#)�e��<���C"hS?O\a�T�C�1lk`1[��T���h��r��U��4���e� ���K����x��`�
��<�^X"o�/n�9E�֧�m�`���u�:��K�� ����{&��8�t�Y.��@w��2*xyt)ԆEU&��%��\ܦ�����.Q�v��Z�կVΐ,̥#FĜMl)�t�nذlx;Q��*!^}��EW'nxdi#׺fi���]_�N�t��6��1 ���^p�F︍�濟���7ڪ���ٴfb��Ҫ�f#��E�^UH�Ĉ܏k�$O��@r���*z����I�(*C���p˵Oɒ�Ǩ���?��_��qgX�lL����a�����'U����!�cqa��*����e�{�˱4�Q �3'g4? �	 ��
U�E�XU~�((���i3G�IyZ]CB��eW@�bˎ�h�;�=���#5p.���_��	M��-�L�|�����K��W���nH(#n¥��*��!z��CV�u�^���/.ͻ!���DՏ|R��H�/�DZm�ʹ
|�B�f�[�!����PC��h�È�/�;�`ٓ)q�Ũ���$<#�+�H��m5�B�̒G�͸K4����)
���s(Ӝ�3�������������lUY�<~Ҳ�rЮ�����ͼT�$��MQ��B!I�cA+�8*� YB� �\�m3�F�\J�Lu����m���K~�N."���W��(���:�b�����î4(㫢q*�F�/��{P�w)q{?7xz�@����ش��Ą�~5�ZۢWΪ
�S^�[�~��Ǡ蘗$�'��*�"K$FE��������$G��ԿsJP�_���g���W:4P��7PZ��Xu�*�|���e����G��2��# J������
j������<��?�i� �d�|��*�/.rp8�$|o����+Үʐ!9�A,z����������tfd�7Y�����w��@�c�ۚ�ǊX�ս{��tě�k�!��/4� ,GC����I+��U�/�O���EU������ן�6����>���A�,�S����K��1O��4l0�>o�<o�n��E��߬���_1�=U�u��}]�b_]+K��^�P����#���e��t�m�j�� �m��W�ܼ?00~F�>�F��@0'gd�<��k��AN�p��a�tM�'�y�*�N#�	w_Ddy	�}�+d�ٜw�����"�v���j1�	>J�PR\ps���L�}^+Ŵ$��C�,=�e���F�kF�}(F���亢N�(E4�Zr��ahp2iCϞxCM攠��E[>sn$���[4��ٽ�P?݋���1VZ~�a�RR� WY�w��^A�!��i��V���+��A������G��ù�F�b�4�7�e�����h$�>�M�+�x=@7=�1��r]7J�c�y�"6._�$�p
�__�JW���������ϼ��uj�R��T�c�,G�K!Q��0����FE�)g���j�DQ�J��V�U���D��0p���o��a������&0�Y\B������>��8��>%�B>���s2�.�s9%�"��f������XHz���6_��}:y���M�4�(
N�=���˼�)?���үN��P��H=�q�f���o��-�{��c��:e��ka�DHw�J������EX�x��8q�B7��VոG��!�9pT�x��,��W���*�(�!��Sw���6����YB��߃�`���D�m���(3�*��z��d\�cH�<��; Ћ���Y���{��{�U�r�B]�&�WC�s����@���q�T���=-Z7�ܼ�}V䧶�^e3��U� `7��h���~雃������a�Y����j"x<���!�R��W���X`94P+0�yE��p�Z��p��l��@���S��!z@�{v�z41����G�?�|�4�t��E^��	�g���먖B��]��pre)ǙKn � ��YfAHh,�����E!u�tlI�/5�2Q�9��ޤ�a�@7|�3_�x��FHF���d��;4�6G���V-��m/(O���c��S�` ���{��B��}�J�]�j�R:�֥ �|�aJ�Y�r�����.?��I��C�<P:rP8� ��&��S�YL�鶹�{�H�
D�́"SM��ɢa��p��n�٨�uݿ�z���p��oA�Yl3d���mۮ�H�9�UP�u�U�2n��(<�QAS��"H�,@����^{�X?��"P2�d4Ȉޫ2�0y����l�n��z�0$����t�Gw�noC�����6cB&*{`��\����K'.�6g���zxҸG;�.}�
��;����?�-��r����:ڷ���d�Iq�?��$�k�`�-��G��^'�k�2p�5SQ�씪���l�F3��]��J<�gz��J��^�.�6)?zn�YJ)�[Z��n|ǝ��RE�׳�ux3�G�)x5�3����y���9��p�~0��)k�	���<�*���N?�y�!� - �������/q*a.7Ǳ�ګ ���<Ϝ,�6ڠ��W�P��%Ũ~�Q����R����b?��PѯC����qNF�5L砅T�M0�&��tǏl���f�Zv7����o�w �>A�b8"��X�CՂɮ8d^�#���%��c����wn\����#?�������5T:��g���"�nrB%��7(yiK�.7�=\l�RTy^w�F�<Q�o��뱣n�>Тr��sZa%�똿LPn72I�
r1���ܠ���K��m�}�:b��+��߇���i���w���������:��s���ɿS��qz��HL+��䴉��(
V�����6����K�vg8mI>�aU.����ͤ��N�%\]�MĹ������9ˢ�v�ve�;N�Rq5�TC���h�#�^�������U�^��x��K��q#������G���O�Y����f�&�����z��d����B*Q�l��q�/JY}�5��V�fZ:�J��N�9��]��Cp% �LK(��/�U�?�M���$ͧ��jJT(wT����koD@����,"+*�j�s-��|���K�8mZ�D�'*��IUgWt;���Q�+�g�z�Ϥ`����ëiGlk�*9���a��<,����G< ���'i���� �h���r%�������ZC�m��}�j7�����R$ɒd�)Sk�|����cbk�~��b˄��M�'%֊�Q�׈�qW��F;���z�k/���U)d����7�C�Z]E�8#}c�^ǋ�5��(Բ�
C�	�2)qC/�]�'��8�
Б�4��K�_m�\�z���Q��w�ߺH��}�2X� [��RY	�7�z+4�4mՈ��ȕ��C�7�vM�-��)�NКH?3�LA?�N�e��CJP7�=wܩ� xlՀ2}��u�%�@Y�Uz/�9a%wQ�?I�4��炴�+O�̀N��y�n�크�ӫÅ�s�cQ�V{��X5�B���C��������,��$C �!��Z��H��8x�
=��Nw���d�C���_��	b���I(���`pv�u���.½��B)� _�X��J��L�J�޵��7���M��fF� �@k�QX��{�y�z����>��&^�_=��7
���ؗp��e�]�v-��3��=5�"�x<M������*�Ξl�9���Re�ס�kĥ�ʪ��g(r��OD��f���a��D����o3�F���ziFEvE��p����>����B�&qc)�@]���à6�U��'�r���?�'���r^44��ސ5��u-d��u��\��]DZ@B�h�5�5tv3�x2 k��HOuڃ,'�t6���
�VA�
bQl=��7���
���3����@�H'��T�^�F�Yb����K���|�r �vY���\�f���.N|!����s5�i�N��iq��0V�f>=>�,&?s�".AJ�aJ�$L v|�w��Y"4��~͍ʨ��rSJLSw
�(�߸M*��R�2���7��:m�x�q�ϱ���=��Ny�1v����n���:|�=I������D��v`!O���T�Z:LA~a��]#��KQp��|=牷;�T*@�73��Q�� (�\����v�5-����h�z!��_{4p����Td$oڌR�I����V��R6-�+T��t�H�Y�j�!O����B䷡�䂴�{�΂�2�ƈ�֙��є�9�B���]��5+�^��>�ԏ/ҿ���^i��J�N�R�M}��3��Ӛ��H �e�|�9x��r؉�#�Hb�1���H�
a)�.؜�2�(�}��w[�� ����4ߐ%�$�f��n���q����v�>�YmN���`n�L���S�+�g��
�L�t�����զ��p,M��tlP[��1���j�_��#ּ��̢�O:�(�ݫ.��w ���C��s����B�4$j�+����q<>�z���%
Q�<�����C{��V� kMD� R��a��N:f��r�k6�r�})�v��*��;����a�:�)��� t��"i�����:�������[S�g�5�XdID%Cc85��Chq�_+ȶ����Ă�f�F34נ$�~F�R�^�"z���x3@�;I��b���>��{����b�_Z�/7E�1���<�NK�)i[|)k+P����b8���i���d�J�n���\�a�A��S�.� ��Ţ���~L�$l�]�	�������a���_�)��4�9��2כ�dI�ģ�O�d���dZR��*Wk|�8HN�S�^s��xH�pP ����(����q Y���&j싀���q�>�]b�|d�k�e�\h�r��Q�f�Rx�=��|i!���� ë3�p�~`}�o���qb5�K9�����L��`���Ɏ��Dv�&��szß�����a,J�C�J���'�Ђ3b��k���J:�� �����Z�n��C�����gώo�+�?t�S��b��O�g������|J	��h����n�4o�+%Ƹsl},�x[�_�3�,$��/ʟ`}t?mRʑ���l�$���zg���GV&��!�)Љ�mfd��ѣ!�/ߺ��Kz{��ֱhHA
bǀ�{���]��~{cyK��=��o�(�{ ��-kP��t�l!`�K�hx�! 1N�8����'�$ym:�6�Q��#!F�E�r���#�aN�1��yC�M���ޥ6�A��ΰΐé�����+&,S,��luv������5n�h6�?Z�;�uy��x����輔����	5No�&;^�־���0�uêF�_�~�������9	�Ud~��'
ӟ�wJ:M	����l/�q2�gC���d�8�u	��r��fM���J�O���%��0+ڔ3��^G��x��|���4Sh�l%4	��
W�>�����g�n��B#_7���LC��J��@�IN'��޹�0�m%Մ#A��W�J�Ӻu���=�V%
1�]&�JO>�'���>F;$�#o� ��^ �i/ёv�%Mb@�$�vڰ�G[�9�mi�fO��P��ڬ�^C]��W.mM:}țF">�#����A�D�/o�>m�)�]�w��I�z�p4���7�n��Tg�ϨeZ"=��+X��Tm�>�^�>�P����ٌ� 2�SA/+��!�0��`[�-M=뫈9�I.��090��e��Ou�m���$�[�0U�(И7��V&1[�E"Dn�k��rݾ#�8�����{[$X�I�5�.OƩ��n4X�cn�X���ޫ ����]��V�/P���3���`�jjz@������v6������f���@K�]@R7!������2��A9|*�i�'�(�7���;��g�{�����0&���3�\�H����l�\�9 ��]�A";<���Fon���d_B�^�����ʄ�X,�Q���7׿��o7X+�T���q��jU���lo�劢ٴ�Y[���%p0��C������o�Z��Ź���ɝ�g� �Z�E�+k�'��N��G��iۙT�op8^�F�û�I6d�mg\���->�f0?+iW��Rښ��>T���Ԁ�h�P�B���wU�+T����0��K:�J��H�U��������X��H=/�5,���yl���kn&���3��Z��;�Q;1wK�d�v�|�&��c�D�n�{�����5��N���=͠����E�=��i�ܙS�ౠ\���g���'Lߧ���Y���ڛ�����C-֒k�b�^�xɈ�����,�3���M�8��2�A�4O-���{CTʩ&�����Nl�!:фg��NG�����~V-��7��v{�Pd̔�Ae{�'�/��4-gt�bp>�|1T����L�0�&��1��s���ð�'���(�9�4�L������H����5B�`���Β��ve�Ov.({��kC���Z�(��pI#AEc��$��Đ�ޯ�u�[��~�[�69�$���V��[i��b������u��	�?s�zA}`��q���O��*;��D���w/~Lx�7�jD���7i_��C����7�)nM���l�s:'B�e�,����f��^#�F����_V�\B���Φ�����K���PB�{�,��%oNR��LoW+c�M3�����oa!��#j��a�Fɧ���DL��nM\�:��>�Rch��&5��<-H�s(��a�u����&d'�vJ�;���ym�c��(�4�J
���)����HFhl�ǔ���ݻ
��,��C�����.�d!�]������}6�)�rh�~ж$g6��5a��_C�cw�w��<���Lw�.��\.�Z�fNBT��0j�̔���7T����W9�Z7�&'Z耀�k}���K5�nƃU�u|�f��e �A���v:�9�`Cx�i�&��*\��_Ȏi��컀�9N�̙�0ݖ��d�lR���s�߯�uU���P�*=W��قtD��RI���E�Iq���Irf2cf��pG�:U��~�SY����#/��,!�D�_I�^�h�_���:�Tؐ���嚆���T�kWZ���W���I]�E�T_�N��]�8.���D�+��P,���J	�㲇��T�~|+�/�Y:8G���1i�T�[EsLꍥ_���#Ua���W�Bbj}#���m`f�7|�]�+�Q�@y��H٣�(��Ǜ̽ה�8.~��m��bRȸpy�˘�S��+o��Ũ�@���`-��[W|�P�>��(6k�%�
�����{_D��A�����B*�_�R������B"��{��f�`u)rU;�h����� �!��
��\.��~R���-VhB�wu
���v�`s�ՂY$|go�Վt�����/(3�����M�Z^\h���jU���9 �{�l
A����%����ɃI?�4�G�У����/��4py�|��P[B)f��'
����U�����U,xϕ^��t��n�l�V�Q�i���-��}OA������F�W��'�����X���1~�0O�E��"�d�lg�CZh��%���R̔��bx��pp}���ϼt��7��2v�޳SG�S�<,�����H&��&g��>�%��=6��ďh� �J�+�m8�P������n;��y��+�c����y��I���qF���*�svG�����)Z��S���=�Z��뷵pV�����\Ƴ}֩v�cp���s9O�e��s;Vkt@Z�L���n�
M��nF��|:�z�.�<��� Syeu�����u�^�� �����[w���(8�����O;mA�";�On�IF�BA&P�&rdt�CL�B�j	M|� BF�kĴ�"��6��g�شFo?n0�V�%�[��-*EIo���:��m��P���䒞�@y鷵�K,l3������j�(Ǻ_�u��X��:-�1SDj1)�ȷ;X]W\qMc�d)A����e��b����M�ӟzp���#d=����,O�ݧ���	�q�6��:T
h�P�����%=�4X���3�������B20��P�]2?�^�{��y�CgM?�;���M�?Kٜ���0L���2�;b�݄�7#��\�9���8���M��k.����m�eeU�"�QĔ�"bԏ����)�y_���N���Y`S"�4L,@��|���Fb[ۘot���a�u�W�#��L
��b���sM��{��I�mtpx3��������j�۩�2�ht�	�s)X9�3��d!�t����-�����bPU��@��6���R�8v?��l<ם�8�D���_�����p�w��@R����S&X�##ɋ}�P�r*��u���@��͚X��we��� ��:v��?���FMsk��aIG��Hz�9a����~L$�ҼoH�C��EkO�O;�ޱ���nT��b��L� I�BW
��J���4�j�9rR,�yɿ�.����C����L����5��`|BcF��>�I�h����r���)��%�5:��~��݄f�����J4au�g)#��w��>֫�s�q��WWK.�[�c���&�*_��n�R��_8���k�+}�b &œ�_e�-?҃��3"1_�ϯ܉&E&U#�<ó�k\&�al8�0ʒ�s'f���6����f��;C'�l�0���l��ۛ4��[��z����3�,RG��Qm]���H�>���1�򏑤���!Va�rbI���o�d|�\�&_҉T�qPFʠ	Ý���`gl����Ċ<�:F�3T�U�2��� #I� Ys�|\7�6x�_��!�*�vVe�D�Mؖ*i+q�oH����ȝ!E��_!Ќ����a���M?ұ�����I>{�p��N�2_E���q�M���,)�L	â2���/Ů��|�I��3Gm.ԽC	�9�2���|A���� Ŵ�E�<��X~ZM"��;���'��@����-1�tr/�)���'
O�"�)���t�|��VNз����d��Bt�y�IK�g��<����@��\�jb1on��~�7'�=?�� 9��I�0D�����\#�]
r��e,%41�̟���k�����t������a�s;>jқ�~.M�s/�NTa���k����?�{�ta�LИV7�~dU$τG�ړ���55s*ϥB������&#��t]χU^q�K��ݥʒ ��u vۤ��֜��#���9��b��#��&��g4�d��w9i�+�{8����K'����d9{�آ���Q���s}3Jl[�����[���s��^b��BC��}��%�=�썰��K8�&�����~�?Biִ������y�x�I�J�f�$�!����[_D8P�`kvZ��`&���^��b�� :�l+!�;8����[n
v����B�I�;����v��8 �<^,q��F,xJ�>�V�xP�����M�q�dN�g�=7:R23�����^��`��R����vBT�ì����U���p��6'QR�)�-�鰢���H}�1O��m������u%��U ���Pk�{h�u�	z���]=!�&��RZ�* ��S'`H��+�k�!XQFM�������H�{a�0.��'�M��ו�N�ݾ�v��T����V�� 6�r2�����;-���m�wPs�ځ��Ͽ���4�!r�*+� �g�o&������*E�����OS �<��Le�	��&S�DANW��m#C3nΗ�o��ݥl���u����&�^��x��q����*�?}&v�p���Ɨ�O7�=���(-٣�6���H]�i[�t � �`�N%�L�Pܞ������q u n?j Ǫ�9��2�}j>7L_Z��"�q���� %p��7Z��{5M��6�T��W�j~v[O!Q8L��q�N�`��{sW�0��e�63��"<��ulH/RWl�4���:@C3I$K�$y%�u.)���0z�k!�G�j�p2��:�ƫW�9<dKg��B�|�����IN�zEvǙ���|�x|4�8�����j87����́|[�] \��˚qN ��ba-[�!X�~�פ���,O6/Gg�����~���B]���tIFU;�*P�@��Cƛ�� ���[��C��r�~����.��Z.��OLk��ط��bRr^�h�Pq�Ky�O�K
Knq�&�h|�*0��~����-8+�>�j���Y*��1�\�׳���{_@@n���ډ�ysǡd��h�B&рp���£��s00��ېx�=�[��h�Y��YFg:�%��*���s�B�/.jC�ٹ��nzy��;=A7�&#w�f��0�F�3 . 3�����^�+�Kl/Z�.i�#����Kb�g�}��U
r�g0r���YFQ������J+�<p�>��2�׎��b��Z�S����.�V��K���v�Ւ���<|سl�Nu�c2H�k7~�ܩX�B��8�yf0*?:��L��1�8%�J�k�o�dY<��٩Sy��MC}����p�ǎ�Y�B���&y�~���Fž��ݶY�٧�Jߚ"ޞi���#Tu�y��.2�Ӌ�e"��}��N�v͵�/%O�ǒ�'kF�!����ʧ�!mD������S������ .Z���Fѵ��jC�e��{�ם�/lp�m ��>�^�bV���"�� 1���!�J���Az�)�J����=tq��bd��-�E5kVMjV�^���gI�5N�YW/C�g�:͢�$LP~���)]3(�ng'��/��"�ߋ�(��=0�Q�٢ �J(K�n�І�Ǒ ��,�I=t���"O�l[�]�h�*l����� �C>�=m��"$u�ա{���X;�ݹ�s	A�J����?d 9��ЙRx�S���r��o���R{7ʣ�A�y�2�ԗ��뒜��R��������m���<�9��V�qS� x�|m�s�&����BI׃��>F/���C��>Ul�2u䖦ԟϜ/مRy�����@�ޝ豏����1��q�&�*Q� :���$ys��En`���z�ו���p�N�F�Y�$W���6Ti_Rl4}�"�Ŧ�ۦ���?0�X���
um:��g�B�\�y��5�N���Â�
�2Y�){Q*^E������V��U0�����{��U5��(-�?����q�E��Sn�1-�_f�iJ��w��4˛A�]��Pe_�I�
�$�`������󢯸�ū�Q1�� ��bG��`�:�3g� v��I+.D�}��vD������A<V���:Ml3����`3����%��	x�9Ӷ_���e���x�f�B	A$a�:�D��e)�ē����C�ޠG��>b�+�K'�TS!gt2x�����lPf� w	�3�����#HQ�k,�m{�����_r�[6�����8A��Y9�hGl�U�i�.fx��P��z��@`J�17�o3��|G_�s�.g�0=J��;o��ަ���O�)�ehue�Vh�6Ⲡ����%�7lA;����؇�Q��w˥�������M����)Hm͎�X��S��%݆���n��s���|��fslK�{���}��pa[`���
�C��+Ϳ1��m珨w�@��TYEo`b�z��)UN1.��)��vc9+1q�D�%_��|b�]�q�i9a0�� �V��b��D�v�S�G�ǖ;xh��Ҡeuv4}9�����RL ����j5���hPp⫥0@�L�Pg=�C��6��MY:��������i6����ו�Ц\�M�wLg[�k<���U6Ny-�2<�j����-p�c�FKRf(mܟR��<��f���5�����,����p�8V���<��Q^��6,;<�+lW���0��j���#4�eٮ0�;����=&��.Kl�Az���5�۷�Q/}�?����f���d����ù�T���L�%����)ǥ�+��E>��}��i�v�5PL�2.�L�I��ꑪ�GnP�n�2�3g��.�r-�7W�ݭ�p��!X�z�F+'Ǡ���Ib�Y��m��׵�o|�1��c�u�A?�r�'?Y�7�Zv1�72�@�!]�,Q���E����u�6U�2�E�,LC	�I���'��<|-�s�/���n���׫��Xڿ �"[�����u.���v�,�?��r��s�W�	�dػ�c�@9\/�3��S�L��]�|Ԝ�5u-' �nc��'ڥy���
����H�Y�
����A����'ޯ�X���		1�v���Y}�_��G�����ۙr�A+ ��Uebp���Ul��������C���w6,\t'�x�B+>���:�}gz�C�Ϝ�n#?u�4�CN�
�Ə[_x��BX��A]y1�`u��qy)R�~�����Kܿ��ͬJ��V�"rF��o�kK�q�:LL_�й�����J�;/��]��0�x]�s�nd`���`R����4V9x0�öD3�Ϳ��g:b�[i�<Y��y-��`�hyf�=v��J�:'6�=q���v����wqd��/�M?}���^�� ��>�t�I�倱��mlx�(tqA����T���oM���R���'�����v8���O����h�je�l�D���J�̝��Q���pa�B�h5(��Q�ȣ? ��~�/�Z��Ƨ����i{��{Q�<�UG����	�R��8�u"T.e��^��$^i<;Բ):�a�"����p�4�N�[Cyx�Zh�
⠤��w,�4�	��+jL%���������K�wx#�[cS��NׯC5y��A���O�����`�p�[�Յ*ͼ\�f70;�|q��qKͳ[�.rȨQ����T�qQQ5C������5�g�Xe��/Q�S�b݇��*v��!p�ݺ�j����cr��S�|w�.�
m���UuQO!Bmbg<#�e��[wڊ����po���5�=g�j@�vf?�blE}���@�O�9��F�WҐ)���������g�����ҍ������O�`o�TaM����h�=ɵD�E΢+���G��?�J����؝p[��z��qIn�Z�]����$�����g�	;ݡ����6�\Y��4������Z�&;���0�+#!3O�X�Q��bN~<
���Gt�cN�v����j~�,k�M]��p�4���g�%�������H��}ݥh'$��z��n�x_BE���Q��2dD���.��6�)�?O@HB�!�\��^�kΑ?|MW?����v���_9�F�0hZ�s�߯8l�"��-]��hm݀���跱O�T�:��\�|) n�z���9�O��]{�B����Dc�=DH�"zl+	���N\�cWg��"&��Yz�� ��"���;gK;C��\���D9��6&!3�%eX��fU9C��e��A,N9�T4�������`|�8��]��D�R��&�!IH����9� Z���@�kvq+֪C\�5Zv�'�����[�0����@֋�Hh�$��Abz��hNs�O��W8�rG��B�*�6o����鯺 �����`��Ӿ�]f�<�y'��`�fݢ/��f��R�	���~��d8T?�J�sV8e��
����$����&G�MC�"�q����k�[T�]�)�_DQ��QŹ�D�U����BhFSC�8�x�L�$�
�\����^J�?���$�P�J�~vtD}�����C��.����!�f[BבnT��a�2p����B}�����L�R(X��vh�1�,��=�ַ�Wd�T9��J����3{��Y��Sg�4�7$P�%�C�X�v0Sp��zah���D}���I��ML��:�$`X6A�r����ɱ�yҶg�0�m��:��`N��`C�b�S��b�/�#ύ��<�'~?M���Ώ��1p���TA���<Q@��@�ll�ܡ�'��C춙4� ���GV�ЯB��9�����g_����"�iI��[�,�??ɡ,�A9�9a�N�	�����\�����{����v��Fv�:���R��r�
2���
�5�7.hqP��	2p��AT/�TL���!z��Q��/��ޘ#zo�
Yz�(oB6��V��KR4�����}GHkm(���BB�������A�)�8K�^�c��W����׬r{l
�eJ�&Q�+�g]���jq?5�޻�m��L~c7�oV#�̺���Ύ�Q�j ,jq�Orؾu��JU����T�^#]MZ�	,�*��ۼ�/����%�p�!Nf�X��L��-�L�����"���F*���7b�Z���~�MR��G��xsv�
��H|�#4�����<f����̠���u"���׋�/�ł��K�(�0 �6��Z�*
�<�!��>���cᶽ��X��u�yw��ǃ$��g$�����|��GÏ�e4�`T��>�a�A�$�=��U$�a	�ͺo�����E�r��I띌4�c��1��2��1���C�_Ք[@�~�� ��,=�k�L5ŉ������9a�
G&��� 6	���N�|����i�R�v�"x�d���+XGG����:�`��}�Z�J�dP6��Y�����zw�s|ȱɀz�n��ڒ��AzO�}ͷ���R�e�I�R�[7�=Iˠ��c'RpG1b�8O�\}�X����Ĥ���k9�$u�\
�����6��QM�͟m[����K�'�I���bq_��I?�Ϣ�7���O˯#��jYTM�_�|���˯��v�Q1j�'����߆���QU��7��N�0dԈ�u5�K�%Q(4&�=�H�RLPB��7����9y�\;��[����+=��OJ@�D�͵�i������U��k���\Gho��h�&�8�`s��D���U\��^w~_y9�t+R9B�i�羦BS��8_���Y�{����\�E�'2�D��G�bz[��\((0�.?��M�o�� �U�rn���G5�\�.���k4rg���+,9�0�X��2r����_�c/?�u�nF3�B��~_Z���S��cژ:i�w�h╙4-���Ր*`x\��'���i�M}�˯&Tá�H�MN���M'uIc��N�Y@�
a����O�LW ,!wPV,LW�i{�Ꟗ�9�`�vR��2&� �?�z98.�B��A��0 Of�5ӯţr��k}K�K�:�d�����@�_ƃ�x|��x�v�������Q���)Z�ؙy����a����"��B�0ׁ;��y�F�$E��/�-�3` z�Z�V�N�n�
zy� �"�0����}j3����C�1§�C����@�rDS����F���u!�
i�sf	O��S7P�ϻ�%��t'�Y�d{a� �&�A��T�ǟ�Ŭ;����社:��l�6�U�n�t�u�f��I�(�k��آ�k�\ݚ:7K��;;��)ٿR�IEnu\Y���V|?� x��HL�X�`r��tw��ԛt�[ܵ�2�'�$�P���-o%����Yƃپ���R���q�C:�k�p�2wBĉ9ٲ��:	�PnyWæ&���*�*-��-l��1�趱�p�9-��=2Xf���1�=0L��.9@K�9u�:�ȑl:�&���,�$�,.�������9��E���Ղ�[Q%�s��k[�)�l�Lu!���׏w��p���/T�����*�31A�/�w��g��T�T�"�UY� Ax3��⤕�Lx)�"NQE_J�����\4#��k��?D��O��}^����j�R�%���e�/d��O�V�ȿ	��u�3�F���L&b�	���k]�1�:���F��T?��O�Ԫ�z�G%��0���=�r��0��c�d�*.����F��ʄM83^���ӷ+��8B�ط���:�+�D�SE���.Z��Z�W)3H���>_�z�6����^A �*\��E%,&i��?���fX��+��EU2{���|��E�y���J?�d[�aƜt���E���aHl�5�r-G����.�E�f\</���z&��\m�;�ƞ�d�d0�7�vI�*G�
�}ǟ��%
�;|$�z���38�і���ڛ:u�_2@�8ܼ�ŵ�1�;�����['��\��J�CC�"O:=�͂~�\ɚ��M����d띧`*����A8�-�0���?"�&��R 7z��UYHN�J�Lc��h���_�����t����iޚ"Hn%�������x��I�k����6+��|w�I�������,w��?��I�X����@m��O@�Y��o�W�%���j�0�e�1�E��V&����D:i)��lS~E�,V\Me���kƇ��|b�!!�T��Aۙ�}}���q�-*xG�#���q�+�~��0%��|D���3���4/:�C�ŝ�Q-O"5�I"�&��8�.KU��m�q_0�/1�~�.���;����R�&>�ܴŜ�爒�A�i<���O��`����pgb�*u֞�t&lZE��65,��8�8�pq�;�rY!�Q�˅�r�1���&.��<���dM�D��[8��cs� �3�W��+������C;�#�`ƚ ��7�^�_c�D�`���,�+�D��\�3����]ZL��6�J� ���Vޜn�f�M<U��O�dc���j���<����x��۷2G�	#	�Oo��^&T����z᧖GFQ0_��D^����]v�u��l��(,�cH��s�/�.|�7کl��=���/m ��Ct�*0��t*�I�hjWϦ�(F�-i��Qc��Ƒ�Ո�{���r���e@�vǖ�%��(!�eGV��4GPW�p��.c/��S��ZR�N\&+�;�������D�������fv�$e�[�M��o3�i'%1t5| u��"쥛IQ�b���Ԏ�1�x��)q���k�G��>o7�޴�"?�)�������sL���vD4#(��40K4h��&�/7�r{<ZP^t���P��{��AQ�	^X�)6�]7A���^ᯫ��>'4x;�E��|��2���蒇���[pf���wg�I��R��H�.�������h.�U/Ɓ�۔�:��Mfd��u�X��tF�JT�*j	Y��4UI�`%�'��˳Co��I$�����%�@���de�!-��~�;bAAu'����y�9�0-D��V���9�̈́��\m�B-�P�D�am9\,�ӂ�O0�����,5�ЃR����O!/�8��������ƌ�huyvB���h|!�q�����>�ݵE;�0��7@~_��pU܂tESPS����r~��8��kU�n��*>+w��p)��+M]S{r�)��C3S��4��޹ioc�[ީ��طŧ��$�����E�� L���Q#D��? ���>�!_U�i#1�uH�5�b���Vj�5�7����؎3 s7����b���4�b����y�D޸˼�w��B�f�ċ����q�d�%���T��2p�{�ԍ��`�t�s��N"���+71����vE˽G�U�1�+]t�A��3 q~�l��V����C4�?�?�v%9���������2�3@��`����E(7?�	�=ą��R�Q�E�6��9��3��A/�`	�ه��c��&�Z_���?L��n02�<hIOޟ�P�z�c�/Bf��үl0:�Z-A�4?������lJ�����1|=t��jΎ�޴�{5m��R�(�Lbe�#�V����y��J|�P�u�AI�}J�lu��4)�{{�P�D}5�c���x�<�#�P��y������I
&�p�9v��V%gT�xe�~�-k1�`��M���`�t
�*0g�Vn]_X��P���=�4A�t�X�uI��_�� ;�?��H���x��~�ʨ���+���ٲ��F!�0��H���P�)�L��a������PF4ws�#h?����h�ꃨ�uA9l��ƅ��Y���}>�Z�"SV(ۗ��FT���O�?�O^�ػ�mk��st����m��'|z��Ʉ��>���nQ뒸�"�RU�ʤ��@P��ҧe��C�TDכoW��P=��t��6z^y��٤�wJ�;T�eB��q#W�ul���xf�"�!�(:��a^�m�ª��q�X���աg#";�Q�b��{�h �����G��kG�&��gx�t��秄�]��V�d��ч.�B.�7"�I�`
�I��|���o\�c���P�>�|��ǽ؄�'\�]�g�0F�h�ц���O�:(9��t���M�~;͹�3���ؠ7̫z��|���t��Sd�	,�`�����[�]~�Й�Rm�d����q.:����p3�JCT��Dط�_du���#�op<���P�*s�����KR������%z�&�$��Mͮ#Y�3���J���it����#>�;x�;�m��Es
������~ؚ��S8�j>������OC��qAi��Y�id���ʬ�uTW:8��OA�I{}:|4"��)�y0�Z՗�Wf�e
2�����v�72Z���r�;���cl�j֘rA1���E@�Y�L���������~�@x�*m�o��ҍ��r���:g���B��k >�Z����יq,=8�}x�,�޽�Cl�����y�c��9a�L>M��z?�6�ו߷�H�}'k�ޚT2B獸t|d�ŷ�oC�} ˃���D�,wj��m@qc"�ERzطV��a"���&�^���} ��%;��n��R�STޤ�?9�Ib:z` �������)�ɫ���TkѤ�����l���>�
��~��3�;#>45D��
��P����`��n�و��lb|�u��e��ƻȨ-�'2����g�h?�e	��hj7�lD��Ho%�Vl)֟9R��.=3B���}�ˊ0,�����-���m��/���N�L"[�R,0t�=G\�i�76M�.6���.��SL�kb$O�|:rʵ,H��4���Z�=
)ݗ$�80M���a�)%��'�����l�P��f�B!x�}���54���10���y8A�Yn�4��������b��jl�p/#1�C�h˪�{d��P6@�O/)kq���!R%_��ܚ��v�-&K���"uA�9EAl<Ȓ{�ӽ�؟Ջ��2+���'��o1ڵ�3��D��z��,����q�F{�K+7��p��`0ºT�D�i�O1�t�~p�-���Y���
��R��K<���y��6���
��*r������%������<S��!P�W؃6���!���N���Y��.��	��{�Љ��z9~��f�'���q�}�wſB�;�1�=U9`|F�H�"]���]k���څ�ل�?��ʗ0�ezGe�������5³��˳���RԹ��Sb�]�/Z4�ɲ0ی �Hx��k��> ��pW+��h��B5ޕ�.�/�w���=A���یO��҅��:W�E����@3���&N�A]��81@�Uc
o��s]D.3*U5Z�?���f��{�U�9����o��>�&�:U�"��Z�� �L+Ɯ���z� �<����aW:QP�.r�U�qG[)|����X����e^/U( �7�<V#�B4�k~4����I��?8�>��8�x��B،:����`i&L��>�&�p�Ql �����tmih�$n����X�t��~�;�U���o���3*<Bu3� }B[	�l�Z&eh�
=��H�g���jo��
Oظ�\�>c���ĕ�sC8�;ZN:�x1���3�pj \x��j�7��U�P��*�5�R�Ķ/q�{���4�b��u�!/N�=-�d:�		̙;���@���=��O���C*��ϧ��'��u�2���	H��l���![�|:G.���{i��*af��А�3�Y�>��``$�!��.�T0���T����0fzޡe�2��c�Q�d�ŝ�^�L���r�I!T��컁�f�����O=H)��d��]��	X�r,UBQV����-#�Ѿ*�x�f�ʭ��a�O�_�nP!�O��9	c�C�8��U�-qt�2�c��oѓ�bƱ'�0��'O4##"\���@}3@�q�����kw��oS��h�E���l��p��ٱ��'L�u�������W�x�h����Wi�B��П��		@,.���v7�z�f�EtU�ŉ� 2�o"-����R���^Ϸ5s�'�Aa�y�qm�x�B��]޲T����\V�[���?��ws����8:��*'=�lǂ��<��e'"��\���`gY��%TSvn2{��V�t;P�[������?����	.�ō
��Y��dJ"�qQ��������))/"@�% +8�-��8^.�����y= \GO۾��/����p��\uڨol�2!jtp����3�*x�A*��K��� �&��T�����~��G��E�F�+����[ 5���S=������Ԙ��a�UņҖX�g�M�l̺Cv2F+��m���5�((-]�71TSS a��+�;,]��OM���KW}�{���Gၜ�H-V�)Z}�왲
����?a��q��=?	��'zԭ|�^9!U��m�=��'�_ �W�p���5�F� �X=f	�M��ҌK�:>���׃�j^fC�hf��+�f��Q�8���Ъ�P+Q��Y��=*�V#�!H��ON|�r�Wzu(��r_N��K(|�f��V�u",MU*:>�؍�{WI��|�I�"9�ot��D�������6h��js�W��S���;i�����ɉ�����y�$��*1$��R=���PL�F�-�XK����U�@X�P��/��~0Y՘r��U�uJ��(r�o�v�6���-��3a,�� �u�n�C�G���s�}��{�0�:(/��C�P%�׭�Ҷ��$��/{��P��!��j.Q��i��c@k�Mg�r�����jD�	�?*����~45�q�X��N�da����|�:��梘�z����B�i?I	Axh��/�:!aH�`.�7s�ㆋ�.@�q��+ė_I	�`?����	����'\(�b�A���\���ďI٣���r����,��T�ŸU��]Pc"X�>̌Q��@��k
�2w�R�����%�R�.;҉���ꚞ8xwZ�T��1Ļ~7b�=�ؙ��������46,���z�z<����B�&�O���	{v+,DC��S�b�𮱣�5�~��A�����-��[I[��(e�	Xpl��f�r��7y�_�9h&�,�0�*O.�>Ɠ�n����:���r��=�n4arh�J#����p�o���(�P���A�ۛ8(_ǯ_����D	^(ԃ�u׶�>�'���p�� 2"mAh�WJ���rEj�٪.0>�3ǐ�TW�jU[�VqTV�'�Hyq]	o}y: �+��ƙ�r���/��I�=C�g�ܲ s~,�i�*��:�R�=�P�Z<�~#!Dk�J�i;�!�Pp��.���=�M+/o�W����p �F#6��	Ab�.��u�h(^�)O�p�d$���i��`�o+�o�F�r�n<~��	,ez�dHI-Uށ�Jc�]����{��=��Urˈh�.!�4�OF۲�ee�>,q�R~_�,]E��Āt߱�s��(��5�`�*l�d�h2e������Kҧ�`L���"�Z�/ M�^�XP3��j*�Au�o����Az1{j)j������4'���vpyӄ���x�U+��zl4=c������0���
��nWL1s��Ꚇ9��ư�I,�/��鱗!� ���һ=���h0���u�9S>��!�Rm�	����JtO}��N-���fn)W�B����&�+�l�d���#����B���%��:;�<]���~ܴ��z*gKc��N��1
&#+PAV120��$���8T.��ɺ1L���6������7��#�	���2��c�9[��z�mD�˙[A%�Y�	B�]֝��x��>̿4s��y-���/�0��Fͪ�9]B!�
#�(C�-/��*�m8���y�/�c�N�:9n�%Xfr�P?�����U��4�*� �D�W��\Q]��f( FQ�O
�}r\� ���
��ui������Z�(�O��xZ7P�#��ݍg?2OZ�(.i�ў��k�I�IH4�X_�����vN��pR���8[��	3��5�:B��2���*�e���ƨ�⯜G���Y4=Ƀ6)6W�l��n�S������s�K�*F���Zvi���������°�!�PYY�D�����Ya��Xu��Ӂ�6Qy)�KP�e1�RI�<î��՝�VF[�U��K�U)�}-僪	��q#J�,;D�M���ú���~�i�T2�g�4Q}<!ޫ��$m�3��{���ma=�qp{~8/4��ώ�!��QiMxƺ�J�w���K��w�J|�~�������@E�SSn��x�?�ޔ�?Aq:o�˼�p��UD*8F%�5�_�2%�T/��xb2��)(��2����L�SU���z���l�P�/���jCÍ7Y���j���CeO������+�1(5��9���2ϝ�L|��B{�?���Z���)ϐ�E8����3�+�ڃ�����`��1D���ܧ�8J�Q*��]u�RM�ͺXwy΁��uȔ�ӟ?[��+o4�/��Tq�����X�hсAp}�Jۭ��B�����*Y�(Z�~�H_>�o�}VG��&<	�r`;�V=E����\	��3cq�	=��b}2ʾ�Օ��V���`�̌5��w��R'L��+6�H#��y�wJ.=D/O��!�A��{��,��K�A^&�V����m�渨&�4b0I&�C�C��7��?y�5Ѕ��������l��w�f���0q����Ʋ{9����.�^�Q��g�����y��S��n�)ƽ5��<^�1���x�>+-.	�}��5�79+��)Έ�k������s�Q�4jA��yG#�%�C���N�M�b�v�h�VJXeb�7�i>J/���=Ϥ�m����H��z�#u�'����=�.�;�a�t�d�����=�����H�ëy}~=Se�B�.��I��_H� �U;�3i���[@zO�#�� �ś�+'�z�w�,�%�ƺ�^�T�
U��'-ҍ��XX��������׍���[٨�SsODV�9�����<X����D�F�:e��YQ�fRЫү���q:�UP�zL�ʰE����W�"����{6�nL��M��uuz	<��7��<�'��(����?���f5����D$�]��&B�l�S��JҸ�#h@������)��M!݋�ͷ�o��1�v�@�YDL�!��m��^��:g[>|ɽzs�M��`m�b�U���;(�p)����,vd�@Ϯ�&�QK����	sD�1Q`���"��/ˉ���"ީ�'V!ۤ��{)�L�2�j��K��Pk��Oo١�~��6�Z����6���    XV����� ����q8^���g�    YZ