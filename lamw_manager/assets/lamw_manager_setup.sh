#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3626998301"
MD5="1203f0e7b8235e8207b4850a2216a54c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25540"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Sun Dec 12 10:54:48 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���c�] �}��1Dd]����P�t�D�"��=���� �V�K��tñ��n�~E�d��8��胈��3�ì�&TTu�������^&�~&�,b(� 90�[��n$��7�~�������l�Yyg���a_l�a��	PN�t�<��/������v{�E23�x`��R�ý61�z�aO���4���$w�z�)v�EXڴWh�mX��J8D��D�r'���t�:Đ\Y!���u{�ڍ�{��������-&�5: �ZeH��"��%�5�g�*ќg�1�r�-_D��$搹w�܎�9ETb�L�Ԋ�w���� ��u�ΕB��ߵ� ;���I8�����>�X;�On��`V?>ӹL-��>�*�7�,��E�Q�,����j����J:�rc@2^�=6�H]Qqtc[7�f��W��H��qF�I}k׃}��l�;v�G\��%hT�&a&��&$L�׃�9�צ�R�7�GV�N�EM�<<t�����>#���=�_iv��/�vl��~��.�^wO ��9��8ݜ�њ2�M�Ƭ��� 6�T���ݾ6�j%ֺ�E�_�M5�%8�s��5?�m/��I#�w�bdF/B�I��;>�>�<�mÖ����:�u��������nڜ�ފ���%���|1��Abd���K���� �N��]U��Y��P+�$�X�U�АKa��\��_�#<+����;��e�D�B��/��qӻj���e�M���m�3�|��ÃR��?��4)*�]m��(]�1���ɬTY</ڻQ���Z= ^2�� e%�n��W�eiXF���k��Wx5LN�:���K(�VW������({J���@�E��'�zm�*z�ѯ�
~����}�'�z͐3�C����U.�,���c���C���;�JJ�B�"�|��m���rju�����:'�='^���
���!5x�E����V0�!s"�>,��u�4(�w��*bټ�i�3&@C#��x���vr<���������ы�%>n���� 9�[�[�����^��?H��TwK|�?` �5��m~�W��|��"Aֈ�ni E�=O�|F5:�����5���=�v�NT �"M��W;�^/Y�T̆(��6��uۄSFC���]F-�
�Z��9��7g���l������K������ ��ZHś�m��_@oNs��Z_`("����wE�L�]`K���4NmO6���U��3,�C�ģ�F�q�fab�}�p NjR����0��O�S*5<�_G^�����08ú�ͪ�}��.P�&0q�ߒ�]�
��D �eys�y��杶iN�$b��&"ѕ�1����h����WK������ߖQ���<�§y�ؘ��JV�l2�/� �|W͛j�t��5\��^|q�Ex�ꑵ��8��Ě���j�ɚ��.g�?f�h�~9�Mǚs��/�@+��:�l��S������|�ZdL�̓f"i*�q]	y�?��~��{����L����5��pzm��MN�'
�17�U����:��ލCu�����t��ea�G6�0�1��E�ۧǂ+.��
]�ub]2,fZ��e��������M�;f�� k6駐f�'Z�5ĥ�W������P�2�'�K�5-|4�|�#7��9� ��֬��U3��3W�L'�5£��"*2Qǥ:]�2K��*?G}�V��m�Kg���2�/4�8pS���̡��EK��^�X���F����R`=��1CA�C�Y����1�M?0M�]��"G�S
�1��T� s�l%G}��G�$K�#��!o�1�]P��g�:Ef�P��G�dRj^]%�(�
	�v�+$�M�˽T*�r?���#uʀPѬ�m�S[K ��8�����`�U��V8�eJ�ܒ��W+�:�[�H=V3��Z����z���V!��ւAX��O��r�	��\��~�afAUBt{Fd��;�b��U�舿i'SIsG�e����r�KS@��Kr"��P��z"c���GD�G�Ώ��#%x�d���]g�d�&��������Qz��t�|@c�aօ�� �,���<��HFA�?��JD� ���Ût��Q�P0N�~o�_T)�Ч9��_��\kHv5��F���ǥCl�X�'���]b����͹�tٗ��)�%?_�P��4� ���)rO2U:�e�!6O?*�BRE(Rą��\Nu��pVI�>/�ĭ�2�7���MTI�1�����40���EC$���|I�u�;Bۮ�2j ���cQ�M�M-�--P����k��M�k�)�"���� ��6�cݰ�C��:��Ũ�Y���R�=�oP����Pt�6�,�����B����g��*A�,���2�[9:���k�I~����xR;��`cE��V���w��C�P�OZ����ٱ��1)�TnKК��,G��x~���2/��T�/�|[��6+��j��R�p��(������C�C��1����"�KcV�{���L"Chj�g��DP�)���Y��g�։OP�Np��N�]�_��Y�H.̀� �M<�*�A]��.E鸩Ί�DDW4DA<SM��a�YFc�	oW	[�^0�B����*=^��?I���7���A I��k�!�b�?��޵�bD���0��y7�C��v�!�S$�"9>�N�l�J�d2��Q��ϔ�k��d��7��:�=} ���B��5�>9t(U�w�z1r�]�9�p��ɏ �)Q�}�ݕ=�2*B)�% �uO���x�S�~�M~��W�f���8c 6�޵��A"�˂s�m��Q����es�]h�3��6�vT@�����b{�5����Ψ�u
���R�w5��\�Fמ��YP��w�	�a�S�d1��m��r��ř�_��<��d��a-��Q��ou����&� ��mj�����0���#���h���I�ji�d\���n_�'�EGMp:5��c�ք.0��;MV���W���
��JSO�׈Ă��TǸ0���^��{�i<wI�:O�{殨�g��4���\(��(aM�kN�1����UDf6$�(��ۆ���;ASo�N��('���j��:�ᩛq�:�U0�_�%)Հē^�2Qs�X.ǟqwu�+�T`��Ǫ l�C�d��L"P/-���2��9|���8��?��Ќ��������~�k;g����<M�.�.�/W[���Gt�����Q�v�����h�8�紕 
K�,\n ކ�Z��F|���1qg�z �3j)��^�un1�hb_%�6[����Z��5$&Xtqԡ��ҚĒ'�Ƈ��+�e�3�ÿa�S�ܕ���E��B�S��ǟQ.�hN�U��I����������gW3&����٤	}x���J?��[���̧؜�E&n��x���E7s�W��r�n���qQ���{���?���{��U�T�B�>ndkG��v��i:��9g�"��L��E3��'Ma�H;	�K��<	:Ӣ�p�0�� ����HyZ��!��U��96	I{\�{�K_F���2�g�H�ަ��̿�|X�T�r>b�v!��Y�Gߏ��äE�n�O��E��Н֫��0��t���OF\�� �+~$p����$��fR��+O�g΍䰭~gU���F~-!3��QC{|#j7�k���	B]�\�i��Z2x��7F���ϨD�=w��@?ԧVl�g��U��i,�W����:�%e⏚:qPkd�?��;�бV��)����dnm�ݽ4t�r�>�?�ئ�	5�������f�H�b\�ʗ��c��؟P$�1��v������[ �&��A�w�TZg�H��33�jjl��?`�Q.�� �q��D�lå�i�LCo�r0b4@�Pb�Z�FG�y�,)��w�В�q�%4d㎃�$��1g���S�գNFC��8�Y̎y_�u�~ؒ�E�*O��gx��9v�w��Gt`�Y-.L=����)P%f,�[^�Q��X�" @b	�����bX��4�Ś�洰v�i�S���0ʼ�[������4O�X[9Tůd���~-�s����A��Vݷye����6_���5MdR4IU��2�]6�u�����m���H���|9��'��A�P��k-2��������֒OUNl���>.��m2Kt�#]-�/����m}mC�!����*?�;q�7@�-�'o��4Ea)5�3��<�1K��&{XxF��[� 9���5m�םH_�!��$�����~ǭd�@�JMD[���5}^��D/�S?>����Ǎ7�?S��`�&So�m���`v,�d:�)a��0#]T�8�$��̘��L�'�����7zax�1�I�\޻C�|�mWuym�|�t��K�j���-�rU��� 8Oép4l�h^h��(�;(Nu[��X ���[�s���3�>��"M�'�J��F���9�|��^�� ��Kb@�����V����ﴹ�r"��Pg��k��!_���[��&��C�Ml}Q�r�-�(ҳ4�"~��q��.�����N��j�qb�t^�HF���$d����]q���ػ|�K�jO-�����PMo�nLA�AO ��Z�
��f���-�R#o�4�R�٪PɯtƀL+�j�u��oz���wR��n��MC	�0Y*�-�1�o\B����d�Q�#��L^�#�W@�i��b�qe�5e㣋��O�!C\i�=;ﴍ�Alܠ9��;�w�f��yK���6nJ���=}��=�-�����Pi&���#�h�LC����&Rc~�'D
;2�eF������f�8������	&=���s�Z�.&ϧ�a�-s8�H11)���2�v�7�m�E�j�D����Ӕ{��/���A5�|/��[���!"T
�__	�+��l
7�)��C�b�L�0n۸�r�y$��(��%ZfX��^MbN|s�W�Vk+$�Y����o��b�r�ԑ��>ڮtr�h� 5<��i�bi�79/�G��Oܘg�Sz��X�Ǯ��O��wӦ�~����M���Ƅ-X��G��Rt�cZ|y���Q���aO6i�p��QU?1�<+�+pG�zhn���< T�\�p^�
g�Ńw�%LR����O!�4骆/���|�
�S!C[�/<�~����8������k|�m�ίxQ�X�IЊ��cc����G�Vt�aeX� E �*����Q���S��Zc�A�ר�����M��r!�8<�(��,�a���'���R�Qk��I�C3���,�NYj�������!�^���P>�O�Ęl��׵�4ys���'k�o{��S�ȩ�s�p�'��M��W�[�:�1�b+}��b���5[;7\�f�X�_Em���r�}�it��k!>�jdf�=�����bAA��_�F�)rFo���*b��эF1Ş��1oZ#3������V�$�2�sroFȉs���n�����l��)�@2kv�ԛ,<Յ(��8�4�(x�vw�9���H�X�&��:�5�a�d&[f��n�Ȑ��j<q�WM@�t��ڴ7�q��u0M�Q��ܐ��(�ÎKZ���v������3%J�����	�����ɽ�Mͬ�
�b�l����"�����x�m��n��y^��*N�S��x��5��-��hΰ#�Hoe�O�m����Y5��))��zk݈΂���Ӱ���V/�-J��
$
G�7�0GU���gX����Z��# 5#t�S}
rUu��j���t�����Qgnbq`u��4�ɫ#��R��7i�#�����|�'+C���e��7�h(;���
����e�A�3ϗћ�c��3�׹�U�_�>�*�n�Q��@�O�	4I��uz��r�i�M��8�}���x�K�İ�H2ހ��T�w"<�7�K����a3�d�N�--���?�y\C�lY��,ɵ����8[W4�&�#2������Ue�3�_�Շ��A�1����kV��2Q��x�C�ܙn[� ���Y*��$�iJ�A&#N�l�r��}����p�ݡaS?��A����Z9S[�`Lr���������9��]-�U������X�:�ܲ����;%�\@b�ګ�����"%V��~	��v��Wyd��Os0��ټBS��(��S�3b���F��BoZ���M�ɬ-7�E�o>�8u�e�B����?oF�?�k^���v��Pɯ4� �c�r���S79���ti�P��z v�eY��]}��d,�r=M����%6l|��>��|��d��7$tB�:�q��╛���}��q5�::e;��R0v#������V���SQs;\
��^�^I�О�ZįVM�������!d7��5��T�髰�\)0-H��!-3�BӰ��k�7�X4(b��q�v�<P�66�~x�t?�nϋ�+�L�?��N��X���|��Z1ս����!���ӚM�Zn��{���2�T��� ��N��(�	�Τ�F����r��i1��W*�l��_$ՠ��)Y��K�dM,<a��������X{�2WN�'�t�ҏ�a]���Jk~��b.����.@P�?�Eyb�G��Գݿ9.)&	\ˁ�v#'�����L�o�(��ݹ�����uO���y_��T�`�7�	f/ȪU���f�裌-��N�e�0�1���=�w�^�4у�k/��]�,�8��љ�M���t��(\n+J�����x��t!r wq"B�	�j�V!�ܦ�X�R�g���1����埸� �m��'K�0ckC�G�J�r
pg�\=}#$\�yտ$��A<J4�<�`���G�����1��,��������A�����i�-��q����>��И�P9	��R@�"*��Rc:>���&�����`��7P�N�I���FA�b�d�4}*^�Y�Ld��43o����_�A*����8��������	��q@���`h
�?�/.��$�ib�s�j��od�eE����4���G}�v
��*�VBֹ�*׃��O�TM#z�f�ܛ�`q0���E�F��šf�G�*�n��iE^����/�� 2j�٧)��.�H�_�����f��($VI�A^��%di�cg����翏B��+�Iε�A#�J�V��&�v�'ϭ*ӣhҌ �zff?Г��S��]�HD�T'������/4��rTE��0�����+�e.<�.��nv��H���ym�8�@W\V �̸T����jX����\�<�葒�������C�[���ja��gG�w�/~�'�P����0�*c�i�4��t:�~�[{^M�7�'ʨ9�9��@�5X�8��ѽ����^����3��.��qdb��ԣ�Y��8��>X�>@��1��4������{�F��C���4��}�a4+�Q!B�df[�����-_�eG�ZS��SHP-��`K�����64���j+�+H�pᎃ��Eۻ/�))O-�������U
x���G�7��d�6�!�U�=?SDǲ�1�KR��������7��_�*�K�w>�$g�v�.b�$4'�O�Y��m;0�K�W�����?��N���K�
��I�QT�3)"@��F=�����Y㽏~��[��S�aA۹8l`��c�Kwꩀ����2_Vh�ŭ��/Z$����U�a���J�V4Y⇂��V��	W�l^йU�V�5����? #��_^��Z!��%��� �s�y;��B#� ����Fv�&C���+���y-���-;Y ���A�K�b��Y���&ˋ���R�!0Ruٙ%���y[�
1���2wP�1w�f������A��cu�[�+����cu�e@��G���?���,XKt�Dw
�e��*7�o�ti5sm�$��9w��2�� T���1�6���裙Q�p��ӁYɨVwr�|��Irf>��0��P��.�ŋm7��/��n��� x��'13ܨ�|����}3\~cOK���C���c���<̐��aW{PĠs���w �"\#Ɣ��Ɵ�e<m�T\�q���x���cy}I���En��O�G6�׬��~���v���<���%]�^>]X�
p42��j���A(;���E�.b!и�z�!�)~S�꫶�7�\�|�M���a�zU_�ZMTg�q��-'H�E3�8���L�%�5�<'�/�#�1��ڥ;�$�=�۸4��?`����:�@���� T����b�V�f\>��_9�^�0���l)h�1i����Ot32%^�k']] �=r]r�F��H���׿�OAÓE"�Ŷ�|�O�{t�S���Ֆ�F�k��sh4$��i�?�/x��c�	�Z;�8+�6���BJ?���j�w��1��������5Z�yS����|+Y� �?�(y՗����ʏ/K�u�a�����Bx[|��A>�(���%�r���t�^�1�=��oq��B.�%�Ǿ7x꒙��nbڭ��%׺�"���wy�~���(j��_�b��,���ްr����2m�;&��x��q�`Y q5K����^�Z\�H+8���A�Q�����)� ;��靖��&���rb.G:�k?Y�	wD��\KI���x�.
������q\��yG���Z�g��v�'�z<HU��ݖ�v�I��~E��]+⟊=*q�u^�w�{���;y���pV�T�0$(c����7���^�]4����ɱ��*�mR��6t4*�m���@ֽ��|�7�8hm�I#��C�BQ��>)v૗��H8�ԫ��ÔiW�:��4���]��R�]�f|���D �&>����%�2���sj���K�S(k��,_X�6Ǽ��l�E�������z���A��;����)w;̙�`)a�i~�"�D���ë�p#�un��S6o2�t�e�Ks��v܂�IIJ�eY氁cqY'���;*�޷Y��b��]6�e��lvs� [H\�cAc4��Cj6 Z�蘒ǆB;0`������ѻ���z���JS���0'P�d���Q�
�{�}e!^ ���
mbG!X��#��/�͕/���R��C�ÊW��/P��?�K��ݘ�Zs偘��\�8Q�L�\��ea�7�.OoHe�z�q���D �::`��p��w�e�YZ�?#OpJx'4�ܬ�1��6�b����3�z�J���ڶ��P�	��&���m��ĵf'����G���%Åy�-���Z7�ds�k���rOyWqI�4@̢_�8D�*/gYs_		�x �0$8.[Ǚ3
�qB8J���r0��QO�h^G���6��P@�0��b��8�OC7���GK&��a�c)7]:\�J�}��������w��S�z��H��?�����;&?�>T	��|��@�`^|h䩥�Ʋ�W��q���?�|�x�FNn�5�A@�X�Y�_�kXg���?��dt�"�9�f����1N�/A%Ƈ��P*�K� S:aW�PR���~�</aCh��x@`/��$W�6�m����˾`�4an"1�೼ؼ�m���.X�o]��& A2 hͯt@q^vOr�wˤW����q���z�U2�w0�J�O]�`���)'�H%���F�9�x�D��e6KO>:�H�w�'f+��4[���.Ut�
l�s6�u�u8�&��
u�0jB+�g������:M��*���d;N]����s��%�"��(xH%��}H�RW�� L�,���NN�K��Zu?���P�5R	¥*�N�#����=�5K���B7��S�����D5u�h�>��N:ǣ��V������������[�bI��d�i��0�}y��-f�:	nbE��{-�Qv�O����43 �krH^�ރmg���0�\ ����*��a]sh�Q�j��O��4P܌T�"�&�x��u��49|�s����e�z�������[jP��}�n2�ذ���]�V����|ΐz��=�}��R�w9�}��Z7"�s��^U&l�B��T �Q �ߏ�8�	�ɨ}��e�m�[1����)@��O\zC{�%��u��a��u���4��>�}�j)�=�V2h���������z�e�2k~���v��{\"!��Q��}� �?k`�����%s��kVqDJ�Sk�tK��!2�YS�RJњx�n�Rgo"q�I��2Q����uh�ӧ{���H��2R��p! p�s������(D��)�E�$����N�;�EހA�Q��`n�Kթ�v~FD�4�ڬ�R�`�e��}�DL�p�o�Ep���T��'�������� N�	�53��%x�]s��)�a`���S��Aoa~N9����P����V-aVv=�x�~E=��|K��A�u�M
�&u}�S��� F�g{'���8s7��=�/�b�~�sL`R����C\��8h�VѢ/Ȏ�Y��>��tU9�m_�{cD@'���S)0��S�!�᩺[k��v�C!��zʘ]��昘��W�rO<�בp;ȶ�vŊRq���ϭ�iJ��ϒ�[�I%l����󃛔G���L��h�D�A�)��)�#2v`�_��g�X�N6�/���l@1y�����ZB�ИoI@����,�x\bѫ��t,�J�>8����RY��
�4���L
�%m״��Kp��$���a3��v��[�2�))	�\�ڞ�����k@�;��U-������O?�@���&��Mʻ�<�)�Q�W�l�Bc��q��7��[�th�Kw�83,�Gt6��W��dfr��B�8� 
H�h�ΔW����wz��~�T�������&Y�HíU�#�xv��'&��`g��Bϝ�ڄ�D�'tw�<fH�A8�o�3ZB��O\���a�hO�τԽQdY;���y6���Z�`�+U+�Ψ""U�r%��'.;++sJ�����J�f�Cq^�2Ln�V<4��Ux�z�b�$�]�+@�Bhmy�,P;�R/�� �h�x�|1G9",�c�Z�тzw*94^/�z�F�
:��cN���Lp1c��1|��ANK3D�S���\����ł}�(�,��M/��nȯE����-%0���K׌O�'�'�X�i@��1$��S��C�}�t�]ܱ���G�Š³9$LS��.҉��3��k������v?๝���2�+~�
�S���sx1�/�$�B�PX���'Yʨ���s[��{�(<��u��O�!yHȃ������Tq3����):�Do��M��6���J�2���ҹk�� �~��I��^ڥ4�K	�|�]'�g�F���-�d���cTs�r���N7�r��PX��xcF@.�%8�,s�{ .'�a���p,@"[F:��:Ⱌ��f��Ѽx���
Ǻ�'mY������|VP�O�u<ZpaVݡ�=oJ~8)���~�^*��k���Wq<����WC��ڥ5�����f"lu��e��'�;�ZoJ��?C"T�\%����0YL�n����FS���	��q��}.��3&���,�s�=e@�$���I�Z^:�%K$M���,ԇ��������㨐�@e�,@�S���qR����|��j1���{���L��*@^<�̨�D=u�>��x��F�>.���$��|p�� u��Z;M�ue��J�N
r���(�Rw����<L,)Z��2B���]��D�)A�Q��/P�e�5�wg��$צŭ���GK��V����E3�`��qB�?��������p�q�J�g¨�`��DT�zn�E�3m6|{#Aj���X;���ik�G��F->��nhr=�v
${Ȅ����֙��f{{[c�w�-PNE�Cز���Y��L�28�nFSD�䕦H[{Z��d���9���M8p�P�?�d��R�X����yz>�.$s8�#oT���ň�J���lH���6��s�g�l,}x��o��-���S����z����MW�zl=��E�)iw/V�
�����t�j�a���a�i��$���P��LI"4z,r���,��52[o|se��8��n�j��G����[2x1�n�y�Y0vQ�	�,�W�ϟ�Κ,�ܗ��e4!�x�\�9픶��[��p��Q� �����VR��J��bA����|�d�UwlT U�'!�o'6�E0�b[}�\'���v�y���Y�+�
�`HL:�����ϼcFVu��]ӎ��Z�L�v� ^=j]s��o��;Ai�Ka�T<B7x����M���c�S˨�6��m�w����TLr8Nj����g^C�W+����&��ኳ���g���^�^J�Q�8s �Տ.5�>Rן��A:�T/}ah��3l1n��/��I%'^�L���x��ܻ�8����e�^�Im�#�b/�P"5�GzN{�+����8���q�&��}�.|�06���7�¢�/���$@��l�C(�AIv�nȊ8�V.�C�h�S�":y�����t0eC~���O �18ۇH��p�������J
�L#����,+� ��Nv��59|��)U�v�N����
Ŝ���&���U���-ztq9��"C�d�M�������!�nQ�@�#�8�?��U ~�-�Rܔ[P�*��D��|�tq�+G�3{��o[<\�kԔs��m����+B���q�l�����%�Yv�_it��8�H3��m�����+��������(.��2�i߶�^IL� �=�mm���"M+n&�b�3�^kco�܍_ݝ�v���ײ��՛)^��֕��ǕPi�BE��
�HQ�-�����<x{V���ܽ�m E�p"��颗&�Πʤ��P&��7�����umf?�W�m�[�^�)^؄�X5��\�V���4���ȈҎ��1(��}di��eP�p��m����.#��}U� �a�܅r��B�pm�IDz��5�=4��o�lO���&�|L vp	��!�lmN���}W�l�y�a�+u���ч�ָ&�&(��Z�Cn������?�SE��������7=���F�f�{�� ���

�ư�IN�]�ѡ°�����A=�ZK��Kf���<���X������je�з�7��<X)��Bh3#~��E��%5��xՕ��#�J�g�02�%c�ƚC��G�,p�DCZ��o{(@$+3wKٲ�����qV��ޡ��Iؒ��{�܋w�ET5ZK���6�=��^[װ�c;6=q ���޷��4��)�û�<��6�V@0�:`�hq权�f���.Q��&jF�pw��-n3�(���P��X�ꄘV���_��m���	@r��c9��utj^��☎}�$��`��0²�?����˄�ȕ�A�91�7Ƿ�X�Q�{����7��q�C�F��g�kP���{����ۣ�{��x�g~�ә��d遞FuOA.�b��-T:�H�~�g��]�\�Zv٫�m��r֣�֪��P�*�����1���*Ф�����}�\R1�>�ZX3��� ���l릾wy�5rjJJ��)˥L�ݼA��k�a�)��!pn�W�6���sT�t�kW����-[�	���P�CAC���O_��ټ�E9{��Ɍ�xEؕ���� ��9�4�Al�.nhN��/rt��ٹ}h����j+�����{$����;�w��?�<yU�Į��.M�d6�h��}.�0���w+��$%�>_y�OͶTAu�nlo}Xk�"�L�g�m ��?����R��W<��rt�KE�� �;��� ���t>yU���-"�	����:Sa�	��u���N�'�yX�ס/�O���5�vV�PnTXÖ@qu�hBH���\��Y�Y�9���|�p$́&N	�J6��_$E�v�X�0J�����%瞮S��e2��R\.I�i��xΕ3A]W��1=��`2�U�&���j��r!����� h��j�&=k�{16!}o���X�W��vƦ��n���>L��2��x�`
&���5�]�^3���rl�?Ԯ@L[�>��n�Am(r?�3k����ֵ�	���ں��Pb�GY\r0����~olZ��c�\n4�
�X�k�Y��*������:��UL;��l�H�يJ����O�3O��L�R��%����R�ٰd(x<�wFLTv.v�jJ�M�ۢ�
���d[�V�7�m�w4�Ⴝ�#�2�ܾ���I�a��*|�V��x��%�#:��M���E[:c<Гb��������51��������G��<�����}��/Ov�jD�r땙��@T�>����i��~�7
(�~9<EF�T�8!�4@��:����U�^Im�a����4������&��f$�����h���HXX4O��GγCpr��ˤ�Iz�b�ѷ��""ń�%L{zU�\����s6�D��v �,]A��U|����~���aZY&��Lϕ�́�Z����5ih����,l��VQ's�p
�&����bشڦO�J�)϶��`��o+��n���&+�G������٫I�t'4p���}T�h�F~��L@��cj���P��4eɝ�>�,ge"���C��v��O�l:<ܖ	���`���a�A�����Rw�v�	ҰD���C ��6k���p���2��c��I��H�I�m���^ܱ}����t��:��1��KV���KU���ǃ1%����q�#�35>�|r9�IɆ�y�_�� ���c��[��E0��]
���Z��Z\OQ�y��P�`�kx��#l)E��~�R�3�u���u}v�M�c�7�F�����6�MJ�ᐡ4C7������̛��7X���qz�0���ѹ>�|̛ȳ��p�x�!<tZ���h1O$3��t��F�pB�@�SE{`!�>�vh��>�`"��b��̋�H�O�P�]���(t[@���S�n�������_k��ŭ�>�k�z19�]o���L��ډ�%x�*.m�J���H�7H`s�bɁmFEjz���J��3#�J��4 �qR�5_ ְAY�#��*�l�M&���r�����2��J
3��@�%3�`�AБC)��|�"�5g$��8����C�_u�Q��>�.䛽�P���tqd����\~�g�K�f �vlԪ_0�x��:�h�N�����*X��$"���"%!lvj�uy7�/��`Z[��l�U;E%A���39�`ܟ ��y,|�6�A4��;��@d�IT?����-f�t�g���GP�\z!zQ���.�bL�U�O^�ơ��Y�p��T���0g���_�=fz#+d|�'�>~
�j���Z���DbcI�ss�'-�W<aVPd;���y��$�lQ�\`e��� �RE��8Τ����3�v�[�$��9�0xgz�%�Q^M��k ?�۝��F��F���<����O�P�%Kr@&����b��sK�}2^��#�r!F���^Y!��H[���Z�+�E<Q�e����fp��� +���$�"�\Xբ�@��<�#7G\�Q`4z0,f����Z�~<�x��G:� P˚a�W=R3o"�+�'> ��~�0w|�-4��u�ͷ��岡���x�<���K�gS4��(;*_�*W'�Y���խ�)
����ȵ򞗈 ���tVjYe�K�Q�M������Xt���S�!x�i��G�y�4���*b��'.�N�"#�B����^��
��]���B�w^�V��#p��e}�����׽܄�Y+��~�	��,�n�=�v�?}��������
�,�&�g�g8|җ���:�v4K˳E���7���f�t�������A!I�V���^[�5di/j{3�91B���Ԙg �4���F��"P��i��½���u��Ѵő�xV�0x�P������P`�Y��7B�X$rcQ�fgPZ��jU���#&�<�"8@'Kn����;t�3�|�� .��SY֊�?�_����޽���z�'�����ʌ�	}��y�;{�fkvL0�b�&�)$Jq��3.�s{����%ӡoC,����Ax�uη��:񬠨���ó�� �g�����.�·Ժ���T�n~+���������%�qӛ���~��2q(�z��u����m4c2G�	̴���l�P�$A1fK�X�0-b͈�:�kl��(�A����!㒍D�X�H�����0@C"�\ʞ��<R^����S���������������x��#�5� �ʸ+�̔Y�(�+�<g>�����e�n�]	�-�E�����,Ab0�?�	�Ó�g���88(S�-i2�@kZ��͞�C�t�G����@�śrGu�~	�Z�ص��U�F�̑�BM'|R'r�?�a�3��G�����
=+�����o��7���7���f��@ �Ti+�}��q���uK6���M��	�8Ĕ��V���DD���ne���!��{����ȼ���W�&�o�U�lL��f:�z&���RC����Fzxq������_���s�#��|Y��1�z�K9�lz��4�Q��jY�nY����nP��t�|����
��n/e�R>��x���%\���CpHv{$���;�O�~���"�6��L���X�R�1�j�6��t��Q�%�����)+
	� r�����J)&��	OŚ	�%F��~���xT-.Wp��}٨�~[Nf��]�(:[�Om�{��`���%Y�2�7,�F&ꝓ�{W]Q���O��\4Y�O5��`�@Z�{�NP�i:^����J>�=�v�$I�WʽKiqp¾��bK��a�&�Lr���o�d�"Yx�cz�\��_��ܤK��S�h�x��u�hx���2y�<����|Vg�&^V&4�_��^B�oI)y�^���/`
=�EV9!]�㑽��p�aO'F
�qh�m��� ~�P����S�E���j�+�b���W9%S��Y�����,v��������9'��\��-*��MUc���U�E�����z^ytR\����+�;H����m��s������� trN�RV:��J�'^�M�E���	�9�zJR/�}ihd���u?��|��9{#
���;���Ũ��l;��m��2$#P�P�	�M��6�v �JW`�3� ��~�ZN�@Ӂi��w�G�:�(R��Ӷ)yهx	 ��v�	e%�ت���z�x!E�_{��p���䯫��?����Y�@�d�/��:��]��(��g���\�`+��u��?k.&��H~�0��OdU'�=�{��	�+�u�ρ}�F[[��!��Yx �dgf/��dW��@��i�Ǳ�n��u�]����O�T�k����.�����s��}W�PU�zk1��w��KpaÔ<�m>S�:���γd]ǚ���f�
 �&��|l�$/��ݛ=΅�K�]�<���V����\ywQ2�-�nEy��ѯ�H��sH@Xe�����R�.0���j���.��q�T���z^�S�� �,�򋭍�X��I&�Q�~�5�5�S�"k�T+P��gD}��(?�@v���z��C��E���3[��A�̈́�~�ZU�{�u�@��E!ڂI��"r#XX���������4�����e�ʎj4_� ��[᥶��4�)|�n�Į�SWH�v��rD�+5-8�S��'�O�Lfm%��\^�Z�UF:x�ɛ�0+��\�1�V@Dm�����P��Q�c�5�]{e�I��}2o�`�]�}3H�m�l^Mo�KԄ���cq�53��M:C!�I� �W�q��1#��~R��W��c>������U��/KFCZ�����&�.�OlVmZI�������9�x�55F��"V�dt��H����,������5Ǡ7q������*������#i�V�=v�_6�ƶ���D�_z�F�#� �v`k��Q	C��T�Iˢ\;��8��5�9�ݕx�#{��w��cP�I/�Q>�-`��̘�}:z61JjGq#@SH/^�XT�#�ν˕�A|C�s��
�!��W�[LY�ۦ�����m�/*j�i�۽2��. �(���Æԫ��dMe������f����3j�08J	0����'����+M�H��!�h<ʸF���v����|�TE�RE_ !H��N\\��H�Ā���<���&�}��]�?pR;�s�&KF���_V�8���T�>������}}�/n5���BL�* ��^%�E��Nu���zcY�����NU������/��IYD��~�,/�2�.�k���׍�Xj7y}��Zin��`㈿�V�Y"�>�M����HK!x�ǈ��]3j(&�ç��g���H�#w�%�V-W��V���0g��:IL�Z#���Y�Ҕy?����s���7�*��9��4�Vi�)#��X�Oo�[<T�]gEKZys$�<O�����;����\�i�d��D�����)�*�M�9i�%>>L���J>̦�c��f�j L���w�8#f�H���.��Y���	|5!/�g;��������^��9�TCzr�����$}�v�(ֱ{(��1���bEM�M�`O��ɫz�s�<ױD�W?�\�ȥ�`��Y�4C����uQ�����~+p�L�1Z\�-��eH�׬�dw�C8v��K�M���V�Mt�Tf�B�������z{�;9]uƇ
n��F�M�!r���Y$���u4�l�8JT� (7���N��\���{��,A�����,��m�4X��M5Y�f*��f�J���k�1��f�q	���t@�Ԍ�l#�|�}U2���԰\��Zap��we����w��C��h� 4��-t�|1~��H'5�]�A蚡O��ޞ�3I�'4�Ǒ�C9� ?��y�
���&T;nF�MX�s}��.1�C@X_w㭏���{�A�����`��jR�Ul�3h����N�B� �1?B�ՙ�z�������TM켷'�%���Խ�
��x钊9�\��+!/a\�l��	d������:�҈%��������I���hs5���ϛ��񯽋U�`�M��t���_���9I�y��~�s�XC^��ֶx`%/��s��IcsRs=	".4*c�Df�e>x�N�t�"��qn@'�Ϳ�d�ګ��4?kF�Hr�D�7�Y�6�W���&7	U%:Z7�zh�(�mֵX�}L-��q!�X�X� k"Ko��@��t���Vz���G�XO��|�����f��F[^�6p�	sIf��Rf��B�72�^���%��g5b�H�F{\�dF�[
5����\K�3��=L��]��}]
-���m��%Dt�I ������vn����f>-g�'DHZ{rՁ5�lg\�L_�y�7F�YY������z��i�<B�%¨{y�]'#jEJ���X�?[7���YY�����OV`�?����#�g{�tb4S4M�nCe����@��d�f�W���݌=�Z�5��)�C[}����k�6�<_�+9>~��,��vRچa��.+����j/n�i��8��A���&L��0M���H<�'�(�\�S7;T;ԈZ�n� ��[wJ�$�uڧo'��E[�oz8�*I�ל(�Af4��5)e
��]�l��??�Z,����iK��-���]���jN��#zQ���M;����jź�M�u�us0���Ev����3��8{��r�QS�M��A�2J}fK���斈T��c4aE��΀)��K'� ,��d["��[�-�Z�`v�r{����[e0 OC���Gb����v��:lM���5&T�e�ꞕ{hea#���
�u�b{K�l�� X�P��2����2�1��p�<�3քU
�"��#l�y~̲W!o�4�up#���ق!6h8U�*7��
$��t Dp�r�LK��]u��s��N�O%���K�'J��S�{	9��6��+� e��"��Y��\�p4>��A��ĩt������;t��}������	�ܰԞ���%Dܘ)�^<�y[���$�}�MH�zq-u�@���;=Yƨ%H��	0�b[�>��r4�W"�s���H�S�<��)�|���'������v��o��{7�����W! q���zn�a���X����x[w���E��^Tg�j���rU<�,T,<�u{�#>V�N���u��dX�
 �Gճ����x,���ĥ��C�I�@���Uel'i��U;dg�]�y�1Y�'6�9"׻=����.WbJ;� O%�3��KB>
0�U��.���
&�ss9)?��TX>1�k����F��o-�����p��l�g�Y��ߔo�H$-�߇b����t`��&��΀YmXhђ!��X�o!% �W ���&5nΐ��y�/j_cgeW�ݳ�P������t4��U��b S?6��Y��SꝨ� r�-j郉Ma�}�%:j��s�ًY̆�7����`N������!��G�
�1��������8���!Z-��}�����0*,��h8���5�]_���j«끔�{�g1���hvt�9\��^.����,+< �ȮU����.a��H���h�9�s�:� �g	��'�Ld�)��4U(�#'
����'�6l��&�бUnW�Q��ӟr�aǸ�׵��Y`����0{�ȗ�I��V��c_��;���q%;��#'-?��rE�)D��[�}n���s��܉��O�$�;�z��ZW?[�k��� ~���Ԟ��m��A����aֽ� ���sIY��2�<��3㶔���i(if�i�Ә�.�ϼ|��]G�XÕh;����w�m�Qx9���vO�X�Asx���C_�АE9>��>�|�Ð%���w"���G���f���"�a����.~.8�K�kA��cQM���Pܥ�pL���k��9V{G_2�2J0L�A<����;�R��5�X�
��e~��hY{a 
e���G��cb��q����������{K�����~d�u��8I���np
Y��q��t�4fE~kF7t��\(�(^Л�`�?o_�ҵU[�8��'5[q)M�H!�M�-Kg{�RlSk�t��L7fS�J6��i��"�G�8"N[��P�%k���ۃ��M�C�3gW��9�{�?�j]b���g`b^�A�k9ǡhS/���˰�zƅ%�$?osH3��-
)����2�M�r�jk/��XQ�k6�"ͪ
�N�$>㉒�&V�z �|Y s���գ�I��Q7��)�#N�MI�Ox��b���Y�<=�U��:��7���
<z���S)�&'�������$.�m�B�U�ٜQ�Uky%x�b��c�.7~O^�~���U���",�꟫�
+}��Y�`�*���Fg�
�7��P۬��"�~�<��/c�@��.@�M�f�G��2��{z��,k67d�t2v�6\
F�|�!iX�SVz�%�Df���Sc���1��6w�l�Ý�c�:ݳ�	/�����t�Dju�N���ͪ5a_(�:���}����.M`f-�Sh��:Yo�,~c����C�L����ㄏ*��r�����f��>��S���zN�i���-hc��!���M�|*�A��h�}
���޺��5G#��B�k
8�Ͳ9�^C"<���׵���m����.�����x�}`P�|��Pgآ3�L 	��i�x�@a���=˜#T�u	�	H�'k<Q���Zh-���AtU�xO��z2�v�η�W v�Ж�\p;ֆk��݉RqK�S�喂pQ4Z�����sx��Ҹ��s����w�<��Ps�9ޟ����4�=mkn�G୬�[/M:��ՙd:�Wn�&��@j���Q�#�.��)p� L�Nqq��͸ar�[w�]�z�LTK�0ykl���F5"\���sڕ<�d��``8_�^�:��+�#׺����(1����F ���F��o� ��p�$��F�2/琠�]�߰1�5�F���"���-@By��78��ޗ
][�����ȏ]e���T��S��?E�0�t�n����$;DA���"fG��>R��J�qzy����	���P�*)!�=˕b�������h�
Cs��ݧ��g��B����-��N�,�RD��96g��޵�E}qW� ����)Y��+qI�R�]^���դU�A9Ȧ������k���¥׶�z)��
�	��9�kR��Mr��k�^���O,���N� ��ҹt:r�Fe�Fa�Pa�9��)��K*������[���]O"��䬺�D��?�hԲ,eS� ���KĪ�����������3��PD�q�4$�E^�:�5C��r�\�ZG;��A��cӂߚ�Z[A�iw�׭ӮtN����e*օn�N!���<�ܡ��<*�:K4�V�]�֭�5$�8�����Vf���&؉�A�����1\u�SU\3�:K5}�B.�~[^�E�u`�@��i7>BdL���h����u��Fk�uT�B�G�2I�pE/N��԰<�q�L�Ӡ@���&kA�C����mc7C40��w9<��uX[y~Jv��{IO����)�		�~�X�-B,�Cc� v�>B��p�ђ�a��}���y�^���%���l�m?���v{�� 6��I#f��u��)�G�9�4ANJ�/8��[v�8�?T�	Z��D�Z���ی�tK�$g{5�5����{����9����'��E����>[�9��k���Y>���r	�xs�{��Aν��#,Q_uFӂ�{]�46Z0��.�'��do/�+IX�%ik��U�U��?��1��xP/�APx��u+�p�I�9����4]	��vlZ��P)t�-k!�u�~6�Vv�fB�]��]y7����\�+mE��f/�11e3����.���%��,�]���ph�`�n�s������T*K˫z3����Mμ|�Mh�Y
?9��8#t��䅞�I�����ø�)��x�O�OF$K%N����:oG2�Z�W5�½ܭ�H�Du�A��ߺ��|���t�����h%�a��(��Y�d��\8�[�p��Ϗ��k�zS�����u+��zv�lCs���0##�n���Z�*_u3�Q}��t8}X>[�g
�5��3�Oaw����où����xӅed�m��(f���I�Ô_/rT�>O��Y�Y-��	�W��d�>\5h��������� [uo�fn�m�����5���\"�-c.j�u���k;����wa�cn�y�/E��I?���ȩ��vnͭ8��Y�c�/�k��r\w贇Q� =�H��3�ML��v2����$}���['c��0����ގU�	���۞֋���Ӎ�0��ud8*z�����"�C�#\����0�q%#�ru$VI>J����[=�&�R�2$)�l�Y����R��쫌��+���K�?��|QPƓ]��{������:��9�j��l��J��_�Nu̮J�-���@���I`���e"�!��#bR^������`u�7u$>csH jjߛxI3���.Wq�;�%xS=��������������2��mM��W��u�z��z�{J�{����P�e�9%P�	̂6��:Ԣ����`�\��6tX-ٕ��	e�ʃT�B�C}��yq/Cu�M �W���qs�n	^Vud�c����9���h��7_cZ�2����M�w�h~��{е�(RT0P�����4;�A �e��[:Q�1�\�����A�3�GK��ԗ۫yZ����ށF`�}��֤��4���0��yH�R|�P��/vB/�;�m��ނ�� �P�Ԝ�V�6/��	*^r���O��Mb�\�"������V���/mf����>�
Ǩii�I�f�Y	�)?���V9�j�N� h�n;˳?E���S<�.���|.�H�Y�:�ͭL:����!U�z�.�uIt�%�uX��k�c=�1��jU$J���_���	��#Y���88�|���cY�J�(���V�J��4�Ak�db����kU�۷�����qڪ�y�������cX�\�λ쿗��n���P��/����	��v�K,��3 �p
��1��&�q�uD<���s��r��A�����͗&!;�˭*�A�@�瞙���_�ǉ����M#�"�7=��k+��}3*	��Y���&�T������Ǌ\�����v���>���=C
��I�|]��e�sS�-Shn1BaXW&��>���դ/٘ћ*�1{�J�w��.w��|��Z(���K��tE�����b5D����uB��oHvG�?�� b�����������P��]%�)��[Fƒo�_��ӕ��S���M󁀽ã8bQn�؁am��o��W�9��{���	Ԗ�\��mͤ�J�]�Y8 Zs����턉�K�t��8�F�&qGk�R�q$&Rc�M�2�"O�-ג��a#����R�J�����>Jڝ'���>�);5�rR~MO�;��V���&���6
P��|�v�FОD�Z�39����tn�ȿ�Զ� ��s�.�����!�E��ƞ��	��?eML����L���J���/˷S'�dE�,�������c��@t���KI�$s,����җ�r�v��k�ќ(�S$�1��٪P�"Fۉ�	�[H��i�%��=daWhٟ0,ό⚷����lk�la�Pfh��肞��q{��*x�C�K�U//��L\���ׂC$����3E��<�#�x�ʃ�D��T:o��B�}"ND���W��!B�7�N��0f����2+U�/�yf��М��ʨ�p��!��*�2��tژ��LV���#��iA���~0i�
�6��4b�>�k�ͧ�����6u�Y������(��T�߱�E���.#6s����7�b��?�Y�maO��`��B�"O��1ve�@> �J=��8��ί��~(1�1Ծ�_��X�T{�ڮ��J=ɩ!i>��{�(�����%�N~����C��x%������:�N�d   �֥�3 ���������g�    YZ