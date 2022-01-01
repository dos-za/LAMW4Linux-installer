#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3422579574"
MD5="cd8090136c0c74426b0b3df451b15040"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26012"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:23:58 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
�7zXZ  �ִF !   �X���eY] �}��1Dd]����P�t�D�#��I����
=�3��y��o�����W���R3<����3Sg<;�/������H��VaH�t1G〢�N	��o��W��B��M=^�2w�j�sS��A͑�a����
K� m���կm�>?��/�&iƚ��Z)�� ���`�EG=�g9�h�7�g�����I��a���VcN�g	<k^^�s��{�G��j0#`b毫m%�<���1���J0�NQ�B$�l2P��S��F�5�|���\+ꓬɘ>ץ�>$��rk���ExdV���`�!��BI�?������ y*#�
�,���~��Œtf3x�ڄ{�;.�n���C�j]wH�2�xL�A#��A��Q�~Л����~t�F�Fo���߂����ؒ��a��.~+NŹe��sb�2	(?'���I���xCB�cN���n&w�@�dz���)�
��N��r�݂��>�߹Ј�.P��j�4���H�QV�L����8|��[gK3d5g���7���"��K���xU�ʟ��?l5:]���w�-#@P#�C���9g�xF�eK.^r�T��^��b�u?춃GJ�m�F�U�b^�x�M��	{�׈���ߖ�L�O��	��▄�|c�}˼{l�(�b�O"�,7ည�h� HsY�NC�JЬ�;�h<^�Z+�ħN^�|W-�O���瓦Djs�~S�_Jp��'%2i�X4Ġ3�g���љ�����H4�#Π-�:�� �U
B���,��x��z~�|��rZb5��о�e�~t5�fJ��hNI�����L�利�5���'�e�[�X-�5�d����#�R�<DG�ѤJ=~.ě�8�h����t&v�+�٥�4�|�`�\����2�*�p^�B�o�J�v1���|O�^M�}�zY�|�Q���X�(87�XRx{��k��T<�ҏN�'���O��!�����"I6��$i)�~Z�9�BD�RU}DBRg��s�Z��(�)65�|6}��v���6w1�R�_t	L���z�C�,�����1xf.}L�%���'����/.����̷��� �E��l�j�
[�XI)�9�~:ʯC/�m@�e�i��+Ḗ*��Sy`�����$���
a%���y�b9�.��\��8y�����U�[�����SLG'�����g�Gg�S�ʵ�Ci������xO}[lTo� l����Iz������jXt�4�;x�B��a�u��l��f7
�Vn`��9��c�7���x����򟝁u�x�.8�}� �/2
����6ˍ_��	<��G�z��N�����,;l�'g����`Bn�Q��ɑF9t���j��*� �J{ P����38�0�B*X#���'�k�I�<ps����=��Y�[9~�/r0Mzǫ>����o�0�j��Xi)<�s��̦�%��|	�����Qzp�m��j�W;�R�7+&OHv��%�5@����wЁ�9����� 3ym��t�_�20[�Ƞ�����Fǲ�d�����~�s�X�ӆ��;�WF~�����Iu���w'����
0W��s^6И|3��weZV�uǐ�YE������O6�������\
��k@�,T�Y�^8���h#V�c��WI[����篷!�@`"H �<V��ܝH�ߝ����ra!����c?ޱ}T����r>ژ�?gG�c��p�c�¥<Ӽ�����{�N֓g�_�8!�"���i�TB�)���_M����d�ՍJ��{�wI�U��(h���P�R�������d���q����o�ژW}����f�b��$˿���3�c뱬{i�
�U��m�=�w��b |��I=�'�&�Df2p�-iCa�.c�^LYrR`��BH���A]����'�t�A] �Ű�������N�),�9t�L��9�/%�����곧���|��N#Ӟ���e����4�Vj���h������U�aze3?'h���+Q�	�%��7�-qg��`�k=���&�O�Hk��~GJ�֐]�&�_���ϹdE�P �i�2�����+��_V�E���O��ZF����	=���3E�o+1�G�]N��f��M#rs�K�4v.�_���m��+�u>x�1uk���Lm�
f9�����^T�?P�먬��K�v�������LՉ���y^��6b1�&~t6�|��>�I��l�0s�a`�T; A���.�v���\�a>N,�b�9������Rx�6a�Y�\����AŇ�� bTq!��
极t��"��@��c'��:�dLa��؋lE��s4+f��
1A&&r25�Kb���.W���s��9!�*�U.$�_n��Ӷj�Җ��5�y�BpvT��h����U,8�Znǂ�M�1r��=�y��b�� ���^Y�q��ΒjY��
�����.V��������k��+W�K��Q'F+S���|�#7�o�7�$+B�L�����	���L}ܝ�⿚�ȉ�A!�����4cQ��-w%���$���?��j&t.>���Nѕ�=��7�3k޺+;�	?�n�Iq�yz�|�͊�u�@/���t���Zw٫��쀚#���	2H��h(�x^Ѽ,�ct�M��=����YsI�Wc���ac}��;�h��\/-�RʬCuo<+mxZ\�?�*ͯR��莚���rK��������.Ƣ���(�ڟ"<�.��_<�U��h4O������B!Q��2fe�wZXO��c�İ+?7E��UA��(4����0l�(��3����otLk�)xL��;�ظ�>hg��F�	q=�8�>j$/ V f#��_^�npF4���t6��91�,؝"�Rk{0G_����xwl\�!�Y-*���Q[h\3�Byכ��Ϡ	]WK��=�P4>%q���l����)Q�	�h��祎�[�������-�nw8���_�&�{����O��
ܡ	^,�a{�=MI���<�	ja�(��r� �\�ӘL��Ga9��Z_��m�k�O�X�1I}��c����m����������?�ݸ=UP�,i-�U9h��-�U�ϩzv��S
���&u��N�c�Hv�ɝ�*@��pG/m�Tn�^(�� ���bZ[�����+c�گ8q�ԓ��<M? z���k6�O�t.TJՍ�c�a4p��z)��QBd� RK�{�`oxH�RZg^L�N�b���摡��W�M�*���ܮ���b�❀�mv�wK,�2XG=�e�b4,�%�x�I�.��%���ؖD��[qc��d9F4��,�2߮9M9�iߤ���q7�r����Y`���˖��%w��q��2�y[�q^�*�U�l�� l̲�^$�k1,b�s��9Q@��k��:k��}2�"N����
���/����f �t��;m��Uc���0�n9M�%o
^�%�"�I�>�}�޶�)��.K��k*�%p��F���h��QU��`@����)���Vj�����8˫����2'�f�sѲ�W+չ�N�H�%X� {��ͺ�1OL�۟Ͻ�߃�T�,Zs�8����@	Gw�`Fe�g��Gj��рXGK��j��n���*��E�����P��q7�w#�sJ��`7p��OJ^MI���sr���tt��q�c�����	�?U�
߅���"��R2�7v��,��O0�f����?Z"|G͓Sڂ�]ذ��e�����<�XG ��ޝР<�9�¬�����p�*�X�G�2UK�x#|c�"�3kx,(k�!��7�=����bM#�p��M�e"4�/�T�%�)SkQ:���y��]E�Rc�Jn���m�[�	�gl�p}`˭�{޳�9��W���Ln�gW^x��6�t�B���'l��/�{U�&TgNf �6��������z�����kq�l����>�l��źv�T�NN ��G��3,·5w���T-�3�tn=��'�]���{��FW	�.�~֦�\�]�+����[j䛇�@3G]ģ�KL��l-6L���1OL��;������xǱ�?[;������ׇ5�8�ΦY�\�=F���`�o!�F⡆� ��FR��KXl�7�Ac��
4}D Ҏ�F����@Y���t��v��n�߹|"3/B($$�����r�	�@�Ŧ㥌'���ˠe��x��l�h�P��B�]iȨ�;�����B���i9�����B�V��O���iƗJ���T����!}�Eo��:(���;��Z#
��J?-�6cN��V�0ohL�'W����DWBÛ'��s�m���n��:ݠ <��"�;�
DL�jͲX҅~����y���,��:�)}.�y��5F��u;�-u�K�4ۘ�v���e�=�,Mc��&S�+F0�K�ш�F��&E��f��.;�i�^�ɔ��#h{�4��$y�!�6�A�Fm�R~�wg�:�u#9�r BG�g��#돔�H���He�� �~�]����������s�`�A[��GY������IA��]:)�"<�FDJ�?<�M|z�p���ӻ�دA<�|������id+b4��f��{0,<Fk`����+��0��~[�1/]�w��3��EӐ|4�#ef��m�d����BBm�[�.��jb���m/���'��O`���x�?�-���x�ˡ%�<��/rx���7�U��ͅ쿳�k�&�V-�}: ����E5�p�O��n���k�����//�P��x5�G���8G빣�6k�`5z�;k/a/��dɫm�F|��J5�*�U"A��'l�,������ ۨ����$a|�S�RNW��jVN��V��YZ���h/k�õ6�6B��vFl͗�>�/�Z�ƺ����чE$Ɨ��  �S��nHKS�ge�wߝ��?X��Ц
�q,
=�c�<{^�;E��TA:�6	��:��%�l�&��5�w�����)[w-u\!�����|ʱ�`9����3K���\�����S>b����).�&M��]j�nB��ﲝn�|ff� ��d� E�P�{�����J"�O��챚��5[���O�w�υʗ(I�D���4�@�G� v����5i +�2k7¤_k^~+#5r6��g��}Cۋb�,
-6
;�nU�敾�-�A���/�g���Y�]�J��/�caQ-�-���8��]��A�[�)}�L-v�پ\���#t���iP>��d��o;2U�6�c9YU(,^�g�r��]����H�K�L�ťN����&��U�UT&͋,j�L0!p�[������ɾѳ�F�G�g2=�i��a|=p635�h?��4Wo�,�m�a���FY���H}<��������!'�����̗��;
v�WB����%샖N%,&oIG�\��x�K��[�}�-I�;�n�+�Z��Ǘa�Qs���LY��7(GM��_����M��LvA�ڊ?MgR]͊6���6�����t}�`��D
�<k��,(K�ƚ�˓�.|���,�
����>��i���ل*bz5d���+t��)�Pbf{��X��^�>�_�l�PKI檑���w�V��R�2	o|���9񸀢}�z��5BakӪԏ[�z�=:Η�o*f��v3�I����/�왑@��J�U/�D�-6��,L��Sژ��R�i�,B(I_�qp�ګ��'Y��#��H*���ҵE�?��f
4y��ę����Z�
Sl��)6�ڃw�|����P��z�C�X��x�Р:Xʼ	U�Z��B�m�����P��{��ւ�P�T!�e���(Bң- ���7���������:�ֻ>�o[���f`^����cb��/8T�xbɞK/��	f��KL�K<�a͡c��+m)*P04�̴�c�J*2b��JQ�m���M��F�HrpnWâd�t�^��.)@T��.��q��@Zf(��K 9J��i����F�s��iBg	hbd�B�?��ә���i���e�Nq+L$�v#)c��D�����4'j��^俌L�d$?s�����:��	iu���hԦA>�!�4���/���^I���ݧY���%��K�,��Nm������uE/BH�R�p�����|�E_���w��ڧ�D��X�*�kS�����ʖ�1��:�%5/)\�C�{��ܥm4I�`!��-?���� X�(�U6�к����Aó����]�=�Jì����I�����h/����R�)��Jy��� ��|-��'�p��|�In���C�}d(�
J"
1��R3�G����\��]n$q~ =~�2�!)�P���`�Fm�W˶oc�J�&��#��s��x��é�P��a�/U1O1K[�p��߫��;l����'ux����
��9��m��"��w�M��a��nJ��1TO���YRM���`M�|U��������[چ�D6�����!ɓ��,}Ղ{��Ѹ����Ǣ��Q��`s��:̗ks�$/_�f�����@$��I�&�H����e�z;P}���aK�z	;>���P���?X3�K��.4Ր '�'��B�?�ra�&?�3=�����".~��b��G�������
Z>������慏�WV�Q�~��<R������'�T�����bI��Y#�F ���\�L���,N_cD�b��H�-����B<���Z��V>�c�W�+ZX-xu���~���B�[8b�^,^M��kc�T�Ca����nyV��P�����Fr��?�'�l�	;�e�	EpfX�o�Ӥm �m��2'w�Y?���>I���+�@���G96A�U�y������"�h�H#RR��������bƊ"YIE0UhIn�#��A� ��^WH�̴��`�G� ��54^^���C~�Z�Z�?[SZ�&2iΝt���[�nA(��7�ߛ*�a̰f���:V�Qi����)F r�.�[0Q�?�r�|�LI)�-L"���ېR��3�y��P�f(�[�\2
�1`�^�����n�B�?�_���@�1��-%�ȟ�����r�qp��$tc�­h�c�zn"�������n]���y����\�QqS��)B����h��B�fjC"	��T�Bz6�3=6��u��m;M=�s�>_�h�kRJ����Pj.֬����J����W����<h�4��re�����Xb[�^;���2��v5�.�*GY�8�U��՟ݽ�����S�e�Zׁi���]�ZfBm��5�AX���F%tj���b#:z�ic-(*����a�_���9;fML�EsR:�������=�M�7#5:J�d�!�^���� u�(ͣ�2t��`���B�V� }���-��B�.���	A"���!Z��aqm��~0��� ߿d� qX;f�B��? �2�iMѣ�Q�h�^Ƙ�	����j��φ��+��m��5��ܯdO��2$oc��*W7&��N������{�l^I�O�������B.?Z.�&�;��~Jܟ}��x&�Ԭ�X9��Ia����Ss6����Cr�8q�^!���G�軖�գz�fs���?�{p{�k����#_eZ���X2�Vt�#���P�L�^��t��������SV�b������B<3���\��s�W���'��b'�K|c���B�y� �_ݙ�La7҃rd����_�V.0d�i���#����\?`X�<����w��x�t��h�EA@X�X������(x���jaN��b��X�x�M�-i�G�o�oX�,����VK��*UqbE�#Nb&x��l���y�,�^�W��Rh������������np�k�&ԛ�¼�uXrS���3�uF�Ę�DO�[Y/�)�8�b��9���v�B
+[Z*uB�nبN�\	��h���������Cmo�>�J�x.O��n&qװQ`�Z�Ip��������[N�	�L�C�۾W{�vP�������J^�
��Ih4�v��L i>���q	��"0bW�����+�J��������à=���/��)�8 �WO��;;����U�i�~H�v�&��~�6�V�R|��l�2O�`������QP:�o;����%�\xn���VV-m��E�b����}'A�ntpb^�H��������&�����C]O�GLYUC����9����5�8:*��V���ϫ3*�e���$Q�6��W:Q�2����{;����Z��X�`$<vw&�q`<�\�M�D�]�q���^X���Z�W1��B��@�m���� kZ\��r`@�}����r�ke$�����%�H.Y�����y�����7M�`����gŚ�����:��8�����v僦)�[͔k^�a��FV52�6i�t��Z�*w�|�(T?�g�V�|�durB��6	�OdEo�d�Z"Ho��8+O�o�9�>��@9�� g��d!/o&~ �<�����5,>���������L��-3�9��jĖ.(g���/�l�a�ļ��RK����?�K(hMȼڪl �����D���h��{#���<̻(_Ֆ;q��u��W��(.�_li�Z���TY��I���� �GC�w���}O�3W�ߊLa���ũ"V�zwf�S7�f���������1�޳��:���Ȗ����$&Eq1�ա���8ޯQ�1��Sk�+��(|��r�1��>G��
��&�wE��8�#�q1p�x㥳a�����rZ��\9�?����h�����[ QA����x�1�2nx���v&�E\��������ﴷy6NH_y���b5�u�f�`Ǽ��*��T�A
w������-��ɦ�/{�_��LvO��{U���P���h�[>�	�7HC�%Zh}:�td��z� D�k���`��tt����L��{�i�����F��jѽ��*Q��g�"�}�ilY�h�蔅��&R�=���n�i]8���W����F:Φi᜴���Z_^��i�P�P:]�"�������/�#V���?�2�׵á'U��g���z�n��Yt�y�IbL�3d�g�y� �m���g�	1�9I��@��:UbΒ` "�/T|ɴ'n�կ��������a?F����pդ�%ೡ-#�KrA��d!�^�Þ���uj��� ��)�qtiv��f�����ђ`����;2� IX\8p0��u\���2�W�8V�&�TXn�2�_Z��+QcsQ�yiA��˝�O��K��BFE>Gk]�2Z��� �ˋ��M2�L�a�I��Q���ۂ���D,�Q��5u'UK��l��:�B�1>�{C]�n�%�� zJ�%v΢S0��Y�8!M���c��9�F[v��GP�s3M,�w9a%�>�Jd��R:'4��G��li�Y1�������E�=o?���ʕ������I�33��N"�>ZC��Z����ú�}�.� �h�C��(oW��lRYg���3�G@>�8�}Pk
$ i��jv0����ȱSq�vi�Y��j�F�KK����x�	m����x���d�Pmm��0p� �+�Il���x�M^����(���f�E��o<�u'9��#f֊���0cW4إ��l�Bw;9Ie�}ٶ�����3�i+�t�9���i_N�L�;�ͱ��s�g���ς+?M��G�\��a�!"v��O�ha{��j�f<�E�]R�-f+�������5-{/ �Ѿ�)����`�m�f�i��y`lG�w� {�J+�	�4C����q�ᴽgCY�<��K���3����@s�m!@��u�g�aWT�=���Po�"���e�R	������A�>�����s��SW��P�����%R��@��-�Q��1�)i�{2���@bs��&��*����#/��e��v������:����d��VL����E�e3N�5�D�6� 18`	N~���t���k�V�*b�Q��y�<����+SU]����T`o�����$��,�O�M���cY��\џk�#Ȟ�A��57P���|��<�H_��07������r�nA���}��ܭsT�o��u��1x@��b�U%Ʋba�	/+K�Ȟ��ȅ�F���y�qmŠ�4��Il�J��X��fX�������[e� aFeM��?�k��4f>hJ3��MkȜ�׏H���kB��-�[�����c�P��fb|�2���P��?)�&J?tpD�b�mr��/�娦��&��k�Vqjn�Q��Gyb��-X��@�&;��®]��d9�cr����P,���N�
q�Q.�Tg~�t4�Pv�+i�\�թ�/�m�F����5��޺�,��<V���!�ܧ�l����"];z�s�v �}bZ�Z'�L�.H�cΊ�!��p�]h��-�&9�;��T%a���u�'oy'�$��:�{�:�&%�b7�����~�T�l,�f�g�z��j�G�&nw�Xx� TA/J���	��%�<U�N�g��+O	�I����AX±�����$�j����P-�t�L�m ���{}�j���W���*|�,v��VF�&2�#�x���s�y��:��H)��0�Z5,�2�u��b�09�5�g9)8�_k�%��:��D��~��tX+p�Rj�P������y͋丐1����P�s�=��Z�NP�0�YN蛸H�^�]B�8߸�3��^�@�x�;�[�T�rv��=�n_"�{�^�OGȚ�Rm?N�fb��>�}L����.�c��
fW m}�]�|���g�!����x��j�7�{ک��t�ax���-�!�?	Ot�v��Y,�M�Hz���M�̆�&m[
��#%μbY���p�n�;���.Q�5U��S}����3�9:�����w� �� A�Ӂ�U�G(����1��\����p	_�sQ<<�'��D�__H>��?Kθ�]2ֵ���h��5�*��[� �����n�?_�9�p0�1o@�L��ˍR���4#8�潷�"�4C�p"~��3��j�����bNR�H!�ybt�\U1�[�b��LWp
�/ts����E��C��5Ӗ�+
1�u�{V1,��T���c����*�Nn�R�6��"����ö��\f����*�#Ґ�5o~����(2&��Ҟ��u8���"���O��&^��h���!|_ 8Ex�Y$�r�7�Rz����H�W���K���LD�v�I�V�(�f�~M\�ig�6�)����O�x��!���+f*��_�ٴ��q��jh_��@�`E�$9;�i���T�!�e�2���`�u ����Tc@�z��qE`�Ұ�(α?��A8��;�J��aF<s���}o��3z۸�k�Z+ ��`QH@�l���nմnGE(w��sZ�c5B�%)�H�c�|�� l���YM�����A����
*qr��P����������~c�e�0U�9Ѷס:Ry^9�̲
��+�k�P`DU\?�?_��l������$.���+~����Ro�4�	�/!������#rYMAs+�����Z�}R���:H0�7�����/�8�1}ӇaR��]�����0|�e#�Pя,��������id4������3�b���N`�\��L��s��+l����bN��%bB���[�B,������⬴Ĺ�2�J���ՠ��/ �SBi+g��q�f�I%�|.��qI���s{we�j@�B��wI��X��C/�[���7�L��m�¯ ���et�w U<����%<�]�T]�]I���h�V�w3S��R&���hV{'�	3Lj��q��L$�7`�6��Țu~2׳�^p�c�6�MQ�Xs����H���������B_�X�^��xl���=c;�.����y��3��ݕ���S��] �R+д�bOI~P���nr!���f���I>�!(Ǎ$�FT��G��A�]KB����Lc��9�֕�(4;���gj2��{%sMn����(���pO����9N]Ѡ���bצ:��#X��S��
���TLvJL	�`*�L�љ�f>�� ���f7���Ŕj��b]
�w�+����4���J�DE���I�V�"��N�;��]�h#��<������%2Z�ً��nQХ�u$��kM)!��˵o}[�[�Q�9g�������t�c5!*B�L����!8r��S'�6�����?��(��IA����}< X(�M�П/��5J�T�f��p샌R�>z$�3���{n����P[���:�]�B��uU����"�MR��S�N ��ves��-Q��'p�=����d A��M�!huw�3l���=��p�l{�����A7������0�ut:�!�x�6�����*�
Cſ�ā��V�RW��c����K���+Ӗ�b�]~�ޭ"?�$�~�7N04N/{w�rZ|�T[vȼ/!ƴN���t��շ�����U�Qz~�x��]p���hC5���穷=���>�����E��(�Y�fp��������;H���MPI�O���>F�M�b��{�OVG|�� !	b
Ԍ>	䟥q5*���h�M0�#�t�+��-��������.(�P�=o���=�%��F�+	�)�i��o��ȵ\ҙ�c4�Z}`u�D=}�e�}?t@�GZz%��9#���&I��.���!�q�1_�	���#�hw�4�<�ϯMޝ{��}{�$G���dZl+W6^���/�_����/;��:���{�Rh��h���G��,�W�b�� ������eY��GsR��%"�[L�Li�̀��dG`{3�J���`���x�[��̴�.�IM���(��C�v��i��9�J��7��W�������|�k�j7k��,{haS��hO��>0��^>x�w%�E�ٶj��_������NL�(��7�d$�)m+�]6��g���V������]����t`k��u�ûs?�E�T�Ȓ�����S}@�z"NpIHq�b���/P?�a��c�*	�^ �WT��FP}1��X׳j��睶�A�-k!�Ah�Ř�5��J�?EBq�t�VvB0��_K��w��p�-�%G���!�;}2c�UkhxS��I��=m%���\���/�#��x��Y��h�|z�Vp�gk�����7�KÇR͉�Vۚ]��Ec��J}*ܲyaO�U���{߸C��\�����{�ϡ` ��`����`q��d*���񦾷��'���}|�_=��١k+b��<��qi_k�����|�wC���i�L��[��%��q�yE�J�:fq,gb�P`+�;4�,~�@iIv_b?h�Щ>��/�@��V�,~m>�|��|d�9=oR�Wf<�)+�c�1<)�N�@��>^�ֽd�ʖ��,!��W�M\�D�dgb�0%��<�6*��Y������v�)�m1��D�$p[���)B��wC��R:�ӽ;�L��t�PI2q@�:P���(8im���Qi�����D���NN�	�!��4�����Afg&l����8��0��'��)�^�ky[�F����BZ7Ψ�`�4�n��&��R,eA�B��W��Z+����d�}�A� _����(�mt��^l���"v4pQ�8���n{�0=-���>[��.\�0,�ۨl�
>:r���{�m#�}@/�l�D�$d�[�W��
f��+l�hn'2\�"��,zǓ�d_ �C�R ��RZ,B"Օ��L��-Ueˉ̦����R��~�܏�T�K&�'�x��r�a�u#�f�nPz�b��Ca=�1�ɲ9�FU�"����N��ݻ�e-Քs�����3b���A���O�p�����rϞ%��v�����6c��%�wn���Y���_�	�v^<��Ƶ@Ѕ}�ܺ�ɔ ʜ����O�3�*����`;�� �
%�7��1�t"����6��=iR��@Vh�Ϳ	�l`O�j��S��zj.*�y�����q���T��tc>,�d9�7�����M/�*\s@���F�J����~;���c�J!��E�̌H��	`艢�ր6�m����'�����r'�TޣC��$�s�՜Hl��*���05��v��sCs�=w�t��Y���n��H��/ZQO�fy�����0�ɸ���Q�a��N���~1F�-:��& ��ݻ�������G��ݧ4�ff���u�דG����l�_jƓ�d���	�#܈/��E1l(OE|�{{F�u���/wU�Ch�¯�;E��F&�<~��؃9J�;���Y���$�5���T���v��& ���rz@���N�����
��#Sp7)~�u�o~h�M��}�9/>BZ�Je��x\��]��m۬XV�>��e��3!\^��&�\�NU�9�2��g�N�0��v��&�U\ǣ�Y�I0�`ذ��\$�_�2�Y~Lu�y���V,����;� �5�kz�2�ƀ����X�r����Ɖ[സu(����@�74{���);r#X���c�<䎴�1�--/��Ve�}�Ҿ��B����銩H"K��!m�莏����e����X�����2Ӏ���a��,���Qռ�5����P������Z�$)_~ �g4V����&�X_�Xd��In7;�?�7e)-�:�Q$�S���~��r���ޑ|+���GT�$G�M��͠��1��`��Vj�/T ,��}ʁ�`J�_�=T��3��Y�(5�M�Z=�
�vŰ���¡_�<�l���K�V=Kb,��pV�ݯ1����^0�\'c
F�n.����9�y�ZMD�����)���b�j�iD���F���Y��c$/d"��k]�l�!��c�Q.(&�Ftͭi����xtſ���H�0����D*��V�6���{���x��Xч�+�;7��8 t��Ħ�];��(�Uj�3���0 ���Ua���z%ӕTY�˗���������M���g����S�k*��B��C��y���O���V|�:W�u��P�;Z�C��S�_+��/��d���i�����@���k�}��k���|���8��L1�
�&5������N��LT���5,�!x2e�$c9��h�:E8պ��F�T��q�9"�K�u���xJ�rP�Ż*�JО�`�~:��SՉ�;E����.Zs��67� �)G{I��)k2K�K�%�#Z`8���9���1����qg5c˃C�0�?��t����}|O����������Gt�Wd�M�O6vΔ&r0������*](������j�y�~[ʖ�O��b]�w���ͩ;���B|����~Pi�7{�jT�oU@.��7q%�Mg�"Q.N������h@��3Zs-�����S~��IK�i�'j�=��,�{�s�e��;:�%���[]��7�5�
��e���Ϟ. ዶ[��h��T��o�޳�Og���ZI�E�n�ܗ�_��=#7���#1�ă���Ml��/Bn�p����� .@��+6r�4�wgT�+�O| ag���o��k�y�k��J�����X���
��̓	������(�$8�yJ������"� ����%���-Y�)��rڅ�A���YӠ��4�ە���c����)�>�������]Y�)^�u�J�U�2��\��i�IG ����EA��[F���ŕ�����H��p ;�ҳ��Vq�zLsY4����D�ŷ���\�_P�T|�] \E�t�fc�'�^Fb���D��Ayn�0&R�pQ`�3�1ǡQM�[�i\1P�?w�]֖,4T=���|�)7L$��o8��������IfҎ���A>s��E3��;5�ֳ��2ǌ�PC��Ka� ����l��LrX���t~��5���׬�&��(V�j��&�R�(JQ�<�E�o�B�����yi�O�X�Q�����9f�B�i�KJ�9�r7ac&�b�Ёɸ*#_&�ݖ0nTju�i%�v�;4�M�1�p������0�{(����^w����xe��@�0n�Wm�yQ�QY�*�p���HS�ܞ'��`"�n�~�nn��$3��qL�h���"f�E�����ٷʇr�Y�Y^����brQ�s���u6
�P?��_��T9�"'���.�v�/!?�;����d�_����߄�A��A������&�$��h� %n ()�ٱ�9��#PcM��R�?}&=	�5��!��TXaƄ�1f�n��d�Ũ(z�2}$���@�|s��"^'%����R�����.Oۘo2M��q�F0�o�6׊}���ӳ�d_��E�L{,D5W�I���4(?�!�t���
�C�5�n��s��Yb��,�
N�Ã�`[�BĀ�O���QW(Ms�G=�����x�.�d�'uKDU�>J�]�����
�,�|x�ԕ��clP)���U�����gP3�_�(j"a��d���~�0WZT�Į��aM��1IA�"�A_˺o]<#D��>u�h��+�3������1�[nc.B�u��wZ�Ň�A@`�܌��Y6#�ڗ/������$�������a��P�<L�]iCy�G/�WN�*D%�8
���U<,JI�#��*j�_ �+���iv9��S3`�(3D�#�iPHQ���#I�Y���jϾ
.�i�ޏ��j�Ga�ļ�J�����Dʑ���=Ԏ,�����iK�D瓝7|+�����,��������<_�ƚ���YWT�����l��S���F��Ń�c�`{R�	;�*	ʉL��f-�꟢\ڂ�� �S:>F�o7O`|���G�S-�����@W�L�d�[h"�n���V{��j���elKo��v��g=�T]Pb��H2N����Fo��a���7V�S����.�؏z2�[\��9	�N.�N�MÒ����`×����M#��L��*S��rq*��w��u�1 ��6x
5��v#b_G�>�F3߅y�p4�j���J�0�J�e��e%bұB�5���)~r�n>(�=�c�iS�2��v�jE�  @
�f$�ݚ�?R�55�<��i����aZG=�3��+Y�~�e �r�V�fz�]��/R�!"'��*2#�v4>}�j�%�
JK֨��7�Bޠ�t�2�����s[q�����(����!�q�6���'+4��~�;� �'i6;�Yks~4G互�ϵ3����.�+� �jx�	���\�a��;�(6I���gK�[��.B��BB�	����I�4���71�S3��[���ǥ'����`�X��k/�9恣�(����M�-�\5Vͷ�m&�bs�&�V8�Yc���V���cɼS�����.2�+��Nf-���(�&�xp����/(s�9���6p��!�sN�MV2��Z=0z��yK�г�J	m܈��'f*2��h�7eU�1
O�����?�RE�a�
���|�U�0p�o�����gȮ'�"�o�qеkJ/�!��ZҶ$mH��B� ��l�E����ލ��/T�����>��{���<90�L��m#�a ^;vM�_�(����{�����y�O�M��5�|�{�H��[|9���<k�?�M��6-n��d%�ᩲl2{��qCf��8�'1C��J�d��6
��X���|�=�x�/HVܺ��xÃz�	0�����Z��l����׃�P����$�xӔ��	x�>oAr{�B�[=I���'�Z�OF�`��_�m	��I����S%��9�K3'��>dy��tX�-G�*�A��֝?��0Ƞ˟�&j�.��*�`gY�s\[�0��I��p���l'��u�C���-�asԚO�a9���p�/	U���՝W���3r��v5_��]V����}������ׂp���E`�̙�$�|=.�D�rW�F���{\�M�������V[�s�d��Dkl�h�-Զ�]�6�[_6Â�k����f+/�@x�]j��X�ݬx���{�F��  �&y��(����H#��4"$p��"(Ӿ�u;^�6��<��+C�)�������OR����Ư�)dw�I�Ew�}4��*���k�z�Mϰ�Z�j#�7
º�#!��G�X:�٘a鏨>	�ҀG.��0�d��zJ綁_�P�v�IPӭm��|a.������^c�b��w��/�N�@D��Y��YG(b~1z/�X���9��j�N`wM�pr_<M~������⅙$s�� ��'�	��l�gCi�������&��>���i(��E?1�T�׮�6勾��Ou���o�eA�l�/[���� ŝa%�گL�rbse�a�%�B�2�b��#��a�$FpLg�1%��Ch�T	�<�yU(CU��D� 4޾��pG-�k��p��+��T�� 54q��(��>Y X�������8�Se�~;���o��V7w���*�wL��h�ʃĽ���p2�77s�pg�n�AIC�gM>^�����懿[�
���ְ�+Q�tܔ�Bv#�A�4Y������M�1d���)cWU�+�5��@p�$^��`ā�Pũ��4ꩮV�QiH�M��5�����7uf�T�ԼB�_��^!���3���5lT'j{N��+>���2F�ެv�Ƥ%��C[�CB�D�(��W���+�xȳWHδ�^���Y�h�zq;��Ώ�V2��źxvF\��̼Դ}�ML[Zrt��(f��5�%��w���4�����-ڭd�"4l����uD�+2�A�6"�U��L/2y�׮�33Q�Qd�[�k>��郩'}$t�;gm"3Z��1�����&}E��f�8�V �\51��(?g�U�E���z���ֻ�c���rPa�8�^�Q�,�H��i&�le	���#�x�o�(L���>��p������@A0Т�Y���J:��:>���N ��Q�Q����³հ�g��9Gf|)�@�.ve]�V!t�i��9CC�mZr`y��
���2z���a�(��h���n@:\���	c�1a$��
�#u�	�W(S�-���FZ��zjŨ�]�+gjy���*�t�e�����<B�`��$�R��Q�Ψ��!��S�*���י��W]3��SF�T< Fa�;骐�b˪�^ʥ���-�g��o�tfi�f���XP��@�WGX��E�s?R��"����(,92Ib�i������r����^3���wg����F*�j{k�� �Rr��:��1(���ʞ��_a+}�1�5�Cq�G�t�[�$�����|�SnG�w*tp�z4��\a� �B�æ6xŸ�;e�ng�'�1F���fs��1�@�Pl��q�(wa���gf_��1�Bm�J�\����kLV�� ʃ�গ<�N�L��-���w����b��@��!���F�������lD�J �A��ujgPhЋ��#!��Pj���b�������*�(v�P��0х5� ;��!O3�D�p3�"+/j�a3:A��c�x?œ�?�E�/��;ni��e�&9�Y���|8�PA��=,��v�JGFYu�r)E���&:�Y~���'-���u�����G�շVh���h��Z����"h'�-ԹH���l�x%�C�Ӡ[і}�7�3FWX����ާ�v��ڻ�* �#����ع�]Y�'U +��C}AE
�R���˓4��ac�3���t��\�r+��j��#Ε�)j�zE�������!��)�A���U,�蹇�RQ�K��f���%g������0�0����J�J��[��?�j$��`H�8�	9>��6�Š����F�rY���=��̵��I���3a46!�=����G�\¢���"ଷ��T��w�{	����_q����>�/�|�d��p���/V=�kp F�����Qx��o�i���v��Au35�q�iiZ�8�Nm�0�9���\�:�`]��@[�պ�j̲�'��}90��'�������t�F�	�4�3��G+X�nr��Þ�/�Z	��Ӽ|ٿ���C�����ƍ�2���̽�Ⱦ��pW��D�nA��a��.���np����d8#ɖ�q�c
x}���<��'�J��ϩ�o  ����G�aP��5�w��D"�̈��+)'D2�83��L&P���Cre�>L�Ƌ�C��^�+eeb�����/��D�L�V����T8��c�>�~���x��K�G����m{o���~-:���0 p}x�i�_�qj�퓋�ȡ�rj|���/WH�<���S}��
��G�/�=��$�;��Ģ�~�p�r���?��9R�;�x:��@�Q����$���I���<xWg�ӶJ1>[>	�!�GK�Ő��AS�!��V>����ߊ��D�aMD\�w���g����(��n�P�B���u�]ݴM�8g�R[���$|����?����#��w'��d�Q9垰S8"���-�������;�v/u����ϐīׄO���[���:��5�3o֢֏�r�d/��������w������,���>�.����Ц*�����O�(�.�!�/��Tb�[N&����)���M�	x��c|S�pΧ{�su�YB���4Sao���W���5�۞G�SRxj��s8mE�Hv��T8�(���hd����U�U%�pJ��N�t���R�&����|��h����fUۜ"��z[����,��y_�[N���q��;��d�2��ʢm/��PD3A� M����H�g�$���Dp���cǉ�1�U��w)G�<�ݫ�xR��4r�M�q3�1c��R�ԍ=��������na��6�'���xR�@����Gm�>�/-L�"���y:rp@6��E~�m�li�Y�K���`��R/�-2E�VK�'�C~�D;k��O�[�#�Cj�Q^��f�]B�\�㛞/��"}+��%�=��`2��:�k~�4�[:�GVy��a��-��1_U�sg|J]O�Ǣ�.�]�:���M變;.���osB�4ꊈ�`��6�d�;X��֐�v?2z^`R�E)u�S���0!B:R�)E>��T7vޫ�}�������8��S���2��I��q/|ғnD���5�Į�D�?\�g��q�����z�J�>�u��q�����̊'�J������n���f��Y��H�ș6���?}і�!�P�gy_���TiA)��s�I�'9PA+I좑�N_��03�yʓ/�
��ަĳԹ���Q#z-g�����7$~����;�Ov�Z��(�w��g�l��ˆ�����E&A��6�V����Di��jd����@ŅDy�E����u�:����G��4�Ghi����z�M����|W��<�R�o��g	����b�%e�n�/�[�?���TjQ�O�<S��1*9��}�9�wpe T�u_%=���d��,/��x��4�;�#o���֝��^N��k�}�9K'��t�O�;m��gG��&�vd�=�𢽘�\E��&8c�	?��)~��wff
���Ph�(��g������ K��p�\�^�
P�:�����:���'hȇ��]$�4ݾm�Q�g��;�3i�!r���D�ƪT�W�w�� `&�B1���nW\9��1 o�׆��x��G���}�Q��Tt����Y�Ψ�r$?����5|ti��A%��Alғ}.F�C��~��=�V�WI,}/A]B�L�VU�T\�wKd�dO�%�����j��
�*��ߺc䯖��
�=�P]QM|�f3�|�Ij�+��SF|,8+;_�QIRpUuEH4���A���5j�.�3��B���A����>u�Όz����l�i`����r�����\3�Zbp��`�YPW�u$_g���SPq�Z�`�׌�_�ه}�Gj�(Yx�t��p�����qb�)�Z�����Zִ�¢1��G�E�xA��G��X�uj /�NH���SH�	��e���@��L+mNM~_�mp�m�z���q#=���v5)L,�����lB�b�V�����r%ޛ���ŀ�XEZ�n�� �����a�����\A��*�/𒾙��1)G�D��	�+�W�l�6��{H誮WJ��E���r�D�ߖ� >^��F���׳Α�b�6h���K���%�G�=*��@u��A/��l��0�>�=^�+�{���m�VR�;�)anu��a�v���)�_Z�b�您����ȲJ�E�ժ$�u�+����o�5r1~ބ�/l�99!��&%z�\��f�Q$���c2�da;�������8��ߗ�-�R6�6�ZA�?����0#���8b��(@:��uɭ��CN�@F��@H�]A�1�~A�;�0�t��ź4��\�\�/>-�°i�Y�u�RV2d�#1�����,U�q6� ?m����2� ��܋��8���dD�2j?�X@S��.��
�Zrq�| �~���AE�(e��O[t�����`H�\�f9�`���H:�u��O�v>|��޼z�Qr��>��������T%�+���~��7ܙ�i�+>�0�>q����*�����w�]E�k0��I���K�#Vi��x�]}�ow�p���F��|�X_���7��z������`�����^{z?�$6��.H�j$.�J�Q_̾��
��g	T�W�FRX�Q?��Q�˷̘��pE��T\�kvm����~�&x��Tk�BW�Ԧ���}s>2��s:|��U�Y&$��v �!i��3iW��z�se���zggMP����2A��):�����5I�w6;�Z�D��v�r�٥��7>�B_��7!��5j�p�n�yQ@m(8�R��O:���o��_��m0.Y�r�d݊�ф4K�6��]W��ݯ�_��fژ(g.`���f[�'$l5Pzy�7�'�G_��^��n�0���l\6]�½h�"N��C鮵�T�KӁ��&ڡ�[{�6|�o�I��"p%b4/\F��X�ˣԐ'��!3�;J��>D�6ϯ'3�����>"�!A���a��z��w�����,��KC��H{J�L9<��+����N,P���ãq?��k�1	(d7�ت��>�q��Ӈ��5ة���_:_O�C�k�8ǂ�x��LrlqhU�w�>�G�o��.�壡s����g{ iϨ�� T�R�Ùv��֛�P4�8���%٫���á�Y6��`f�Bh���儈�і	v�p�fu�'� Qy.&��h��Ҍ9&/[Ɍ.�)��weKH�}$6�����|���:5MK��6F5z5�;-���s��`6��q�����.H'����1����+�D�6�]�nwb$OE�&c�-_����}�{t7��#P�`��d�W�b�3�1�G�x��Z�h�zMJq�~�*�yZ�E�#D�
��?i��[��H�X�@���t*}�e�p�Ji�s��ψ����ܻ9�!O�H��q)+��N z|�����$��9�<�f'���іcN^E0�J`���_�H�2��"�K��,�,c1�Ӷ��_(=B�H��j�xO��7�mе���qb)D�֨�.��AV��Cj�W���\�;F-���z�@�2P��[�R�I}D8KVc`��m��2�-��b��CvO+������z�'�('������	Dۤ2�e��#Lta"�����_�[��$aVMܧS�fZi�F�}�2q���G�/�)�X�P�Q����֞e;`r&���i��۩o�6���OR�Ò�Xy�%�(� &��}�k6]H�A��fya�>h�RX.��s f�#	�1����/Rڴ�q_����ߌt�S�im��E" �������k)�5?�|��ԏ]~�(��mS��<�F��3^��ʨz��ǣâ�Z�í��I�K�����+�Q�.�!�����z���NE�DI���&r;�g��&A�5�0��ˮ���/[DaȲVb��Y#�*�$H4����"d����#[�꣔)��C"g.X���cw�`���$²� +.J�v)�0��q�B�K��׋菨WS�'���A���wI3��E����SȘ��SC�0�D���=�W�J0�Y�C��$�h�ϟ�,x��{�)XQ�Z����~���6�)g�:$Sg�@FϪ�:<KwR���\9�E&�6c�u�nQ���m�T��JN2,�7�K�9@�g9&��/aZ˩K���3Q]|(W/|�������I�����#E>�B��L�n:mL$�١��v`��K�vф�=q{4��E�jO�>�s�[���)Wm6�y=���� ��t�'��bWA�_�_nĜb��J�B�E2�$�v*����ZD�L���Xfޖ���ե�(Xl����8h���� 7�����`yC�r��ڽ\[u��ia�-
G��v�a
��"�u���"�J��k��sͪ��U!�8s<�<��-�E[	s���ATp��<g�C�s��b2�B�q��5�J5�{L���|�v��)t*yڿV��R\e��>AN�)��r^�_Ipu�8��&�o�!w
�Ф$��.>&_��F� ˏ�,&�w�
�,�m��￴W�D[��[�7
2)8�%�doa�#��o�p�ڂ�7r�V@C�/�a�܆W��O?g��1�o��@>2`�X�e�ٮtK9��y7K�e�*�<UX��� _3_uv��x#Œ��&��*�u���C����>%���
�g�K^M\��VX�$9p҇�T�z��߯���_-l��Sx5�bO�mg��;�����u}�[C���OY��zǂ<,���TX�J+8�m焏���ʷ75&iF[*�H�	�CQ"�
jw�c�ނ�i�aZ߉LF]�O<��{.�Q@ֆ��#C �a��[iɐ��C%����^�-"D^���O��y��&=|Я6�	�[���ѩ�d���˿�F�za3�N�&(���x�)z+8��+�9J�~<�7�'�iP�:#4y:Si��HbT��=ϯ;�E�:���q*�pbQ�{�a��E �B��bm�I���%�[ �V���SY��A7��IȫZVe�ck;���^0A��s]b��*��H�K~ԡd;�9`���4�溼���.Ys/�0e@���U��@��|tk�>��:�-��[��廹��g%��l(A�c}]�� ���Dx���Kj�=n9�9<^&H��|~h1 �u�� �K�N@��'�v��fీX��I�O8��y&*���C�rh0��[5�%q<�?����F��5v��@��JӼ�%����$=�E}��]��n���1\�1��+�1�ʯ/�%)n�Pb��G��������f�ʭ��n����o������q���9տ���g��+M�t׋�+�@E��1Ԅ��w��dl'�r�#�>.�>��Z�ɤZ��"���LHƁ�2s��2�Ǜ��9vE]�6?�b�>�=�r
�Z!fr��K����:�ޖ�o���Yd�����P���c`8�i$�,����۔wan�&V�fَl��H�Q��6@����	������=��N�v ���*S�Y��"߂g~*�iv��F���Dv	�A��X�="����e�2r�ɯ��d(	 .sm���cD��    k��KzR* �����Ҽ��g�    YZ