#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2665104784"
MD5="3463f1ddc9b40287c94bb00e596a267d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24976"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Tue Nov 23 01:27:23 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
�7zXZ  �ִF !   �X����aM] �}��1Dd]����P�t�F�&�hÇ>&x ����$�c*��Zj�-T_O_n����b8n��Zl���c?�G_]T}ԏ�s��������L��5[���M'r����J� >Zt�1�/g/ON簭P/���E'�6:zR�G�&���� m�zϞfq>���:�2ģ�u�}氵�M,0�)����gh>^3���5�@�ʣ�U�&B,{��g�����2�:��A.X���1��iȥ"����P�R����~����kD90`��0�wn��3vw��Nx�g���:g�Y������a��3�M�r��1UptX={��N9׳��`�>��H�cJ��1l��ȍ�8� ~M��|A���2*�x� �����鱴C��1��F{��I��� ��e5���!��|��(׶��j��Qıi��L�U��ɟ��!0���*ŭڦ��v�	�p�	�\O��km�@��z�wXS¸���[8e��}�ǯ:pj�Ŧ> ],�G�BT)�SZ���r�!x�\�Yw����ަ&�	��lG�ȡ�T�׳�*0Y���r��#�x�l�\'���M�C��K�����D\qs�0D�U27�]�T��E�9e�1�O�m�_[���Cr��|n+���r�y�T��}�I��`o��8tHG[ű�5@83�ڴP��XXa���A���ԘgFt =�
v2���U��ŝX-l�(��st������G[x��ޝ�۵oy�"���7�~�$w�`d�pQ��@Ol7g������Z�R�V���!)��*'�S�P�Q08�2G2T���lr��f��������0����{��%���V>��-}�M[���?w/�O�*�h����L6G/`d�AxX�h�mũ b�1'7��h(�| �H~wK�W�.u��_T��A�<��I��(K�D�a 8�ɂx+7_;�y�M��i�sf��Ҟ��ԣ[����fQ�I`�VmW��7�5��-��aZm�ވ���#�bG�Bu�ճS��/6W����澋��;�������PWF�g۠�� Ƃ��=�<�?�e.7�޴5�'�&�Z>k�x���²�Ew<�nJɻ@��w�b�V*D��JVnx�M�Ϭ�cHR���%EPp��I|� Ңqd�Kݺ��<��0����<����H.ԭ��L(4J�˥W��X�G��Bhw`xxd��V0�?{�qj%MDPj����۠�p����T.�E���4�q�+q�pR�84܏ڋ1kӁ2��E����p�=F�tA�y^3���P+��ː$���QA^��Z���M��v�YKB#���o��ۑA]���)j�����������um���֙��k%�i��'Yz�z��ꐡ�~V9�ɪ�[���O�����V�@���J	��_w�Bˠ����T-*b��af�AH��V�昐�<7�}������Bo��XC }��x����+�B��@\b�����E�RCl��W����^r�y1�Ԙ0_��S�x�z��MY�ʼ�;)B�K�#%F��e�<�0��F�����qIw�'|�y��9��T�@��sU`�����@���_������RЦ�BY�.�U(��&6ȡ��6]���W1_���Uť�Nܾ��Q/I;��
e�p�(c�����U��Ξ����u]\���o�&���痴Y�u�!*6 ��xC3M��
_�pU�f��sl��*��}���v��S�s2ʝ^$�2�r�7�!��EW
m��D^&pX霧�`��2`"�Ʀ���ۉHL�4A�_n�bkl:�(�D�L�C�]ܨ�EVݣ�n�J�u��ş����j��:NSmE�jS���ia�[u����ӓ�@�s��%Σ��J/�5����Se�ҝe�[��[#������]����2م__(�/V.��.��Lݟ�
�чɜo�T�j���W��߮�
��FTDP�x�9��D���1՞D���¡�Y�-�Ew�X殒8������E=_x>Oۅ�1L��I/~������DjBء`�)kʹ��_`s�C�f?U��x�0��K�OD�o��͟ ��d���ªtOu�U�� Z&G(�r#�_Dh�>��O�f����Sю>�X��*Xo��y�em��vG��/��	���o2���܄p���E���5���}���T�RX��r�	tכ��٣����5�Q�N���Ew��n|Wr��x?�@����pʲE��,(�#a�Z蘄�S��9���˟�t�P�CN,�,"�Aq���v�D������Ԥ1?G~�^Y�Rj]�H���-�I�Oi���_BUQ��+
Dv1%�[G� �)Q��+�'��
w2nO��al��~�Q�U#N�V��oRx0�گ�C�֍v-v͡�,��.��9A
���u��t4�v��C�R��~r|dx�mk'��T�EL��J9v��qYX?�{:���<���O�@���S9Y��1�U]Yl��`ೌVJ_z����7l����pK�SF�j���ܫI~�.����uM�Sy9?:v7�*%��w@����9�9�׉��O������E�hMP՛"����*d��(Bg���ʹ��,�f���4a����|����+�������6Q<�o0���;�.$BasUK�˗�_�k;�T�}�
@N��P��ak*RN
�c������I��5��K{h��-����<��bA�,m.�R�a*6!��.��BC!Iqt0�W�uu~�_����T���X0�̱��=�Z/�NMhz��ϖ�i�o���	�Ł����&"�Gۆ��\SB�̉����l��K`� =�f�E�:W�o�4��d��g�\p�F\�@�]Y�wCv����oO�lŤgo��ˁ���!S����I'3 ��ʵiEC��E��8�$�t�J����U�|æt�Ĭ�'��^����e�f
KP����_fvמ��R�1]묢ˈY@�o���������R��7ՙR������f#_�í3|�d<�O��:h	\De�ե+~!� �����1�o��,�����ƙL�샽!�sCStosY�N�G�%	S`��g�	S���:&��g�YϞͯT|�l��R�}��#R^���O�g�1�,�GVi�U�ց���R��j��47�9���l��nl�؈�m��?7R������z?�jb��ݽ`��ߑ���U(��w���
�r+i��@�u�#�OP�ʄ(�� �U{(�G�?,ZJF�(��}�ˌߎ�Δ�Ȱ�_W��%+l����(yLx\N��lN�hJ�yː�7����h2 �l�h��!�Þ>�,�SP�0��D��>��,��2Օ@��4�q�����5۲E[�HP��a��=��3���.�ðZ;ۗZ��M�o�t�Q� �!Ə75K{JZ�go���B�A�hjC���v�=������ۺڑ�z�h(�K�1���>�:�$|Z�����U��l��듢���I`�i o��:sla��_�D����ˈ��nˊv��цm�Pp�7>�(j�M �����$u��:&rJ
�F]nr���Kk��:h��j���@���j}Ô�J�w��~�(���Z��	����.�[J�l�� �ģ2!��*'&�x�K��BԶJ�����e;6��!�qgZ��m��g;ڗR�E����o��T��=���%�i\����e?�T����YA����j#�ދ�J�$��_\�_�Q7�9b�5��Sk_�ϥ,��F �^A���tD9�Ϥhr3�ђR�V�z��2� ���lo����|�I	�k��5/������:��G�z��s:0�)���T�t��}��;)-w�ZmeK7��/��a/W<�8��6��hP��ް��NoIlw��B�D�齔5fJ�Ҕ�9�*�)�q~� ��a&f申�����h�!K�N�ղڪ�����Rf�C��N��z��O�(i�feN�z��;��9�)h��i��pV�qzM=�ڸ���fF^j硂���y������y� j��|^#��eA[x��k�x)i�"�%�}����Um-6�	(+<|��zGϲA�� �w@�Γ�D���e5Z�#BZ�1�x�ԛ�Y�Ir�]��QX2?.y�?�wmT'�;k���=4��V��3�C���/�U! K����g7s$�mf��*!��AՖ�9�������>��D<������٪�#�� ��X#e�0R�˝�E������s��E����9nB�4�p�֤��OFw*K7�������Uk&U��ܢ��Ýv�>f���f�\�8�;t~��L2�#���C�g�k�t�7Nw>�F\���vN2��a`�@Ok�K@vG��O�����64 �5��v���4}g�c{q��}%>��<��0�]�n��vPE�,�Zݔ�3S��m����?.�LFa��p��+���y�iׇ�Ƞ����X�LA뇲5�"n�,�'7��5��TQƘ�9X��F �
؂�au�k�$�#��T�s�F`.l~$���h��gS?��3�7��P��J,��I4U��eL�m1��;,@��GQ����[���3x]�n]D�6�!O��SY/�hL�C�1���S#������k��}v2�.f���\���BN��'��~���O�����FY>(6>S&J�To|���Jl��p��JX85'���ء.�
��[��I8���T�,�3#��C5������T��͡Kpky�Ą2ÓH�=���{An;h7�ވ������Y٘�&14*�P�3��3��"~Z�'9졲�%TS2ܟ.���|��l����0,M�
�g%c����~al%�G�#!���%�����l�*�9�|�-�!���x���i}���,#FDT�A�O����� �.��A���d:�!�#*�KPL�������^��~�|��c����K���r��"�Ot���F��7.Fq����%PTC����FU]0�x��j�?f7d#mv�!;}���=�S�#6�=�c����؈dpK����J���=��T_�D�B��	����s4�v5�M�⨳��D95���pQ�R�s'�)���y�P�&�C�u�ֵe��QW�2�z�Q�� �{&t����2��i���WW�,(��w���A`����x���?�y� b6�l4�h����vI�w�v&�z�����;��:���G%䣩Ƚ���;<_�Pt���?���0w�!�KВ/�E~�Rv�ԟ��2�Ŗ��{X�I��P�@�qU��6�}��.�4�}����B��
��� LQC�����b4��d�� &����椹���քx*PF��b��05�ᠢ�h^ ��}��-"I𭲲z�z6x�*�$+䀐� t��j�j�QAa���j��Y�e�#Ԛ[�'
V���su��ܙ+�����& �RİP��^M��hl~��aT�f���+?��ި��u���-A�~�qԌ�,]MF@+��ʧ�@��V`�o��ի6��1�[�����ws��^�-w�,.7�W	)����,�w¸9�+>��6K��T�3�^+��l��4���zS�����U����������c#l�N��O��jp��}�x?�_���S��z��%��q�c%WX{�4�9>L�~%҉�8���/�enz۹���E�
�K�c���m�*c���Ȱ�nw�|A��I��F.��{�����ʛ8�&�e�}�y�����S&~��w���6�<Vǹ�U����$�b��/�Εb�r�[-ȭ��+-����,��!�Hp� jY"�%��0�WD��#�!yg�w	�,+�R�JU���م�#��ޣt�ps�I�����ix8�"ek�R�!�*�(��3��6�Jp1��zx��a	�����J#I*΍�Q�2�B�e����z0o�D�A �G����e���1�Kf�b�2z�'y[�(�3P&�T�n�q���윌]�CD1z��u��2ΰ��y�+b6�����N<��#�;O�K0db�B\G�j{�b�o�i�ռ%�w��<V���!c�x��W���n�C�Y��5�s%�	�t[���1�Q��C#�kt�&X�!�$��+��Ȅ�bt}TG��g�����v�ʌ���q,�疳PF�`>su"'R�$�D�� �nW�kd4	�s����*��ɞ��a��vϘ{�8{f9���MHq����?��7Ś�"�O �����Ε�0K����A����m~-�]�c� |���K1}�pS1�����I.a�$��D_e&JE3�M����د��ir�ݩ/�0����0���
���վ�����|�4�$:>��0hyŅ�0i#xXy�ݿ�l���b��e{@�R��s�	ŏ��.�����C�
�����>С�,Cԭp�����#�{��씘G��R�������yÆC������s@G�pr��O#x@G	]6� ��`>bE^Ҧ��c__�3Ȃ��%Y�!"��I��q pE�P�c[)�=:L�ܢ�NA��6r��S��C�'�/`,�e��Q�KWT�`�5 �Jp9��koq�ڞ Q0�"a��eӥi��|i?)�!��@�m�#�}�Z%�Ua��}R�v���J�{�~$�+�-��\y�nދ��Nhq�����c^�M�?{�5�^=��@���ͽ4�������^= (2x�q�O,I(}�L�
��  0C��z����	.c��<��f���k�U�Ŧ'h�������i�ʅv����_.3
���V�[��{{
�v�B2!;B7B�6��hQtF*:�Rw+KI�ٵ�''nc�N�	Ë�|=������k%�18�S ������ޓ������(p�m�V��������භ<r�z������&O}Q���֛7�� ��s��ȣ�!AG:��O������V]�_K�F��R��n�,�F��Pn^�9?���C��K����_&+d�h��a.e�yU�_�?������b�_��@��o攞v1�8HF���J�,&BKqVc�s��lު�E?sr8A���C���`�PѬ���ܚ	<ln�y^�T��1���/�:�/��f<�e#t�\����1c^��W���6�mq��������_�(�b���=����֜�nkٶ���B6��[�2��*i����U�j ��A�m�Z���$v:��m{���C^ �1�����4�҅�����G֜�,bp*Q�I�yE�U �M�0�ah�����x�4��#�y6���0����� �r�x�2�^4�#r䋲L�K��!���Mv��R�gw��|%�*igv�$Dҁ.�r4b�����6.�By&�,(�˟�Jz|y���S�·}�N�ݰ�5⻰�E�%��EJ{�����M�qՏE�ԅ:x��j_<��j�,6�-^]Θ+��Î��҆��J!��jE�X^���t�u_����B�2�>_u^����W�X�r&L��M�U���V@�8Ě�W)�V���=_|�VmM$9��K�E[5�]R"��'�nz����> P���\�����oX
�ӧRq�S�]���z0�	Xl��	�蛧,H���#y�`����W�nf�`�&�����J;���䦽�qxE���EkCQ��k�/�K\�V����1�M�Yn��?9�˲$F��GN��E�&F@,!3w����l��"��`ht���S�@O�L<�1(���Y�b1�Ee����G˛�6h2�`����J�ݷ��˖�Ev�S��z�����k���Q�R~���%@���'t�;���7"�Xxo���F�aV�VPM���Z�z��T���(�V���inպ���x\`C��N
,��#���x�B&�L�h�{pyU��+�'$Bꏆ�,H��aSp��J�(Rih���sCm����4�L�u�fs�,�g�,����$�"�ϭ!��������^:�t������p7fe����d
3S��O� ��+�1�u���L��yDN��7����/������E�������f�JT�����,�`!� R�F}f�c�����;wg���ieB�܃�zB�"c�Re�6<���l������K�V��w�C��P�Ϭo�>Q>*���?�=��۸t�%xq8XD��f/�}��wqD�j�gx٩��NZ��D�؄Q-ZMY��Ħ���^�A��;�C������~W�M;�i�d_r��oP��g^ԍ�	��LKw�|3�ļ��%T����|��O�8�l�M$���A��W�C]��$T����4��ْQ	���A�7+p�LW\�͊+��
^>_�F(d4E�:����l���/W\�e�`L7H[�rq������YT�&����� ���D�FV��NO<�(ݿ�G�����<����A%F5雌���]�)o����f�)������+��dK�˂�l�$#��la��@�2Mt�x�z���;h�7s��&�B {$�֠>�Β
��=�lk��P��$�%8��u�E:��@LR�Y����~43�b��Bh�Hmaסq�q$}��?�PgMDx6��h����wz�BF����ZC�6�&�])�����ts����T.��g�>V��n
�{��8M��/���n ����8�-u1.�T�u�ׂ���"��H-��!$+5��NWFe�'Mi�O�L�Eh��V�N7�@q|�sc�'u��e�;pU�̀�	��ϣ�	�.�_.�?8�gC�|[~��+���{E���[�Bt�}�iH}�5.���b���_%��S2E�K��o�7�/��$J(r4��q��nNGf�u�`�x�����.�T`Ex�/��,��dر#<ψ���fhcJI��7e�%�����p�0#�����,\o/��AJp�m�\�����k������^�����8�hO��A��Y�L6��c�e��M����0���5v��P0.O������՜�]�Z��H�>s��:i���(;���BY�Q��?@��2��:.�k��|\���DtaU�7���g�gg�YM��;����1��m�?Ť�`��oq�OE�o>d����93�"+H�'5��>�;��`My���>a�b�m���9�%��o��YƲ�;����Թ2�b���@5����zBi&�j�m��!!i0��E���6�V Ğ�Z����^�9�X9ًﮓ��v��&+}�&U*��	H�g2Q�����)X���E�&��_�W:�փ�Э����s;�� #<�ʫ6�>��\�E��|V��14���U6�YK�=��]:��qT���z�)6��l�;�mf<6 ��k�%s�x����۩�P,��EA�m$�'2Y���3����x�nhYn|�I�`�>E��]�K�g��O���q룥cI����C��u��3��˲�ܶ�@��P'�|�l�?�u͕�M��K�E}^&XO��o�/|��;���*�����0�%��,��WI�����Ҙ���Vs���fp�׷��Wu���R�Ҧ�dRŇ�c;�Dq(��GpV/[��hȴ'|C
�6�P��[�|� �p�1��9����ޣ�e� o^�p�\��[��J���'���r%��nA�=�C�bZ��*�ׂ+D�QW�7�I��/
b �k)B����m/;O��51�nd-;��b2����w��c�� ��9�ҾI2�Us9��3T����3�B����m�]�����8g�ty�d ^�c�r���c� �$-�X�v.d��e�ݸ�+��Ya�wM1+�Z�A���.�~�T�oݝ�?Nb�WW��z��0�&R'<PW��2���5�����)>�Rh�d��U8�i���X��`M���o�A�e/]kiV�@��M�x>��8D�u�������c�N�Y��v=�Zq'^��x�����Ȉ�jY0zx'�wPǴ�^Ɩj����w�=����
)���%d�ꄸ�a�*�'d�vM�Y�2	uJ�G�Q�|B^c'�O���WܹK��{�p6��˸��b��OD� �n^/p��.K7��Q�e48*;�T�΀��%���VL�{�\�O8O
D����Saй��d,�r�q���m[� ���P�鞦�9]�w0�\��p�2ԅu�
z��,�;�TN�J���qg2"޹�Q�� �+�U�7�D�4Y�f��@�����*�ӣH�q�r��ڟ��;�W^C^7)\���5�2�8A��M��ߟ�A��o��Y�=����Р:-����	/N�%���m���5�E7�3
Qh���<+-���RC'	T��!DC��0��o�o!���+�r��J��8!�L#�*������讠� 1��n�Z����N�S:a���n_b�e����؟i7�-K�ᯧ��?�� n^ĖK/L��.$Cg�>o�!�a���X���]%����eȲ��M�{��,��3,�+�����F20~M{a�?~'��Az�ʤ��GI0h�A{u]���mQ�������,I����Yu-�pa����U�^UE)�%�~�,>�f�t2�U���2T�^�Ъ�YY(K㒋�.����n�X�m�m�_!m�*��;�CZQZ��NH�7a��ߎ�ĬR&�]*���ᄠxJ|U�`��L��?���	��v�/�T`�btn0�fmDW���m@��%0�����F�w
^Ы�j���ʺέ�ND���sZ����V�%*������1ӻ�CV#�$�J�d3��G�x]�����S=,�@���,�*)͟�z�xOA��HΛ��Yj� H|�"c���SU'����ZQz�~E[0I]���XVѷ7�gr����M����)IXt,ex�6|��2Q��C�����@���(-����ܮE�G9]�YRF8L�R�N���������j�;��쥥�m���5e�����G��ĆG��B��q(��A]=�4�B
�;�
X�d�>��) `in��:�jn*���
?�ʺ�>{3��m�Y�Z�ԆԐ<�2��{�zD>��-��=z2�o�Ϣ�:�L��i{���}ؒ�U�qNs<*T��
E懼ܟY�J2ǡ�A2t��H�p�j��,!̧�h�����l��L1 �%BáJw��D������M�,�3�m�ވ,����Q�D_��P�Y��[��Q���y�5`Ah�kb��.d��?.ʪ"8>�l�7�a�G.��p��v�R��I@���zJH��Ҕ �"K��R ������"�N��0zF�<!��G�I����������(��O��������#MxP�*�f?�Ռs�Fy�y���B�x�o���=�S��#K,3����:��d4ᒋ\��+1���K�0�}�GH�'�����Ae o���Uݒqқ�KU�S �C���xk ����Ȗ�K�nr�j���}���� ��Z
F��������4��Tu�վMHd���#l�E5L���4	��ץ�i���ɺ:�o��g7z�{T,9����9{t3��*���<Ğ'��CK��U��Q,�<;��Y�z��Α�'m��(�>8}�lȋ�B}g��~��0K�����	�Y�7�,x��M�+�:�;C �R���o����R9/H����S��w��Sj^��~M�T�!�\z���k��D+�kJ�w _x<��� ����O���t7�w�) �Y͍��?*���"�R�(��}n���!������P.S�	�ܙ�w���9H������*�}gk�aj�:w�l/�"��=|F�#2�|�/�C����Lq�}U�yr='�*nJ{����~���}�I?CACh70��q�HO���$d��S�G�����Y���pF\�ˏ�1���B��	���R/�q��2qrz���4%�D�򫜡 7�@���J��S������nM�s0�K1O��8S���!�2,����n�
�=K���\K��60Rj��ڇK`]09�_8�91�����]t����#A����yy�P��y��@���#�j��#����}`r
��a�٧�mI�)sڝ���},��D����ŧ�=bq5�.o4�R�|�n��oŃ:�L�\5��o^1?��kϔ{GEixN��>'؃��$����25?}B���t�8�p��ciص3��q9�0KM{��ϴI�g�K-�P;�
1y~��ĞF^��g�����}U�i�лKkKŹ�&ҀW!d�g3h*�ܠ �C�4tF�``��u�Ḱ��u���͛� � [���4���_�|��\>z�rX�Q�h����m�0MC����_胗eQ�cP���}�D��D�nrP�?�b�5c�S#S��3��<��|�Yro`S( L��q`K�dU�f"H�KA<JR�,�FY�u��d�]�#,��鮾������ߑ&���3s����0�f~m�C�G���09%l9=���S ���l��У�(i`YBa?� 3�o�R����Ա��ۏ2A��}��_S��w��4�7䩩�B�_Ϸ�O4�39���C0��k�\T�6~���,�
N�v�w�,�=�0��[��S#d�>��2fD���n�#�u[��~�]���������twɊ-b�̗o�$��(��i �k�=��ի��"<!X��%%/2{�a�� 
�Sj����G�=��;؝|Fl�%Ͽ`��[Y����n�'l%i�<o���!\XQ'�G�N ���]j��)d0jE���ru	��M
�נ������ �=�fy��_+Xر�
�%%T�ֳ�2n�6|x#�9�u�o�Y9���7��1]	I��[(A�	�&2����A�=���W�kh8��J�	q�ud�7�"�����=�P'��A+��U�T�1_.�F�P�o��6A���N}�Ci��ќ���)���xx�#W��|�Y<+�Q�ڰ�m7*D��]�Ь�,���u�%�9^�Ӌ��J�1g��k7ܗ�(��o�sc��������'9$ZH��ao�	��X�2���ЎN�h�vu�ko�(51�.�;6�u��7�U<�\���3C�O��,��bR�g۶0[-��=7�&;z�H�mD�H�����T���D�3aI�J�y�m��爂���� �;�
�x���H��8>�q�--n��k�,�*��b�����K��	�.uU~F-�WJ�pTY��1�s�=��d��e����Ե�K��Y����M��՞0�������5��y���V����{9JH""�W,���Z+�Ad�b�?�n3rYq
/�'s΋[�	����;�/b��:1tjH�֏�9a��g���x��܁���h�%�ހ����
�\`�y������D����+.Ͻ�U���?��+��6�hAU���8���a�����VV�g���, x�c��_P(:���wo#V/�M=/02�s��?��f�Q˗2U^k���L�մ��U�{��al፧V��|?�{  �؍�=�F�k.��f��Kf +�t������D�L|�~�p�Y�'�PI:��i/���r܆��n�(bo���_���n�if���L-?��<��'(=&��֐�أ>�0� "8����i7�������K72z�s��E���A�Q=�QA3]�H���,$���M�r�7@�����x�q�+�Z�wփK����A�m�$�"�m��-�	 짤ta!�k�+�!��k"<���l\Z�:4�#*��og�R��V[��wn=��$�p^��tn��2!A9�d����+q��5�;�6���j������#Ӭ�rZ�O��z,[���=�["�˱M|g�1��<�;�\H�4'w�TS�LM��Ly�X�}��r��53��͒�w��3�9AA8G?���2g����sQ�ĺ����fԒa/������1]V���A�&�x�t�Z�����t�p�m^��w$�8�6�!.V�֏&TVy"�*(�c����T4��^L�h�L����z8�X��i�^��U��D�"_��(�}	�1#sڳkTD�o������t̤>���kt��t[�L�j��a&9�c�&����!.����EL��2)\m���>>��o*2�e�2v����f����*��Ɔq���	��s�$2 /*��45�9�{G�v�4�j�(���Pn����S
�Qc*���8�c�~!�=ՙ��W��Жu��J
qu��C_۰����{Ȟ&F��S  L����I}�aÛ���yr&>0����v��9}��i��7�|`����Y�)����� +hQ
]WK�c\��R3:����ܫ��p�
�
���)�o Ӛ�z}O�9+��oJ�m`v� v��F��ц`R�q��|ۡ�EIz�$��v�����4�}������'�#W�<;D쪂�n�������/��nU��B��mQ��o�%��u��s�b@��1��-�2���ZEN9�޳��|�hTU�������?�,:����<�p�lѡ�Y��b�*�+.i���!}�}��4�9�,�A�n����̛��`JޙZ0���˃�dm]�P�����q{�p��ga5�XA�[�Zn0fG�Q'������7b�l&�2�߇H4��Rij���Z|^(���(�ss�?@�>'.�.����J#�/*��Qvl����T��Ug�{[Q+�����a����a�7��
W� ����,�D�������Dw���4�*'�Z��F��t|�ڏ��$)S�ym����W�mxl��W�.:�څ�����|�E��T��?2��Vް���O�E��wZ���������e��9tH�y\��G���u�k�K�t�422nDJ�G������_J�!��B2Y'�tugS�a�*+�����62���-9�Ӎ�lG���A�E����'�]���l�����-P��O��d�Q�?eS�Jn�G�+<��Df��Hq\�ܼ1���.�u�I��S�����t���n�R���HD��Vi�@�<؁�d�=3uTw4+�$|I��"��YF|�*a��}���է A��Oe_'��"1u��]6�5��~��˙T}ޗ�__�2� �W ��8� l�L�H['�OUQ�<�*�S��a���b�?%5n�L�����%C%N)���Z\�{s���u�/��#��m�92��:ў����{�j�"�3�L*Dn��ق��5�"��)�φ�sB�K �ɅA�
>a��6m��v�h�����C��7�r(~�S$�aqLĐ��蠒��~g����a׫�3���ZtZ�"��/���g9�m�.`:CmW?�T�tR�.����ћ������L�����/P���<Y��N�/�:�����Y�,�r)�=����9��ӡ<�R���
����CW8��7WW���F��]~T]p9���]�ѝ�0���W�"+q��F6������Y�u�y�4�-3�G^���M��K�-`t׸�8Z���
ǹ�+�byF���k�ϬR|�@{��@*[O�a-�#��5���m�gYG��.T�QAHR��nk�[�I��d�M�!%0
��4bգ��t������r�eu���7K��>�9��N#���FD��Xw�u��K��9+�XQ��pԏ�U) �'�7��fm�N���|'#�	���Y'�Ptu�/� 4��~]ˎ���O�z![׳ l�.Y
(u!�%�M,�����v�j�OR��/��/\�F����ۂ����`�w�^�uO�^��W�/����!��\V��K_=�����w�.�I�۞��~���Mu�!�4TIUu�#UA/��pUH���3�e�M�.�Q�{��-g�d�T6;�����.'K�#pE�qhy@
�����b�f�J�ˑ!�px��X����h���\�A�M�aB�������c�@�̿Mۂ}3�歈�n���`YMlKJc��b���v�f1Ndl1�k]�r��.:�yPt�Z'C#w��=��,��f��U���8d����ӨcT�H� e "�w��.*��ˎU��&)%�ji��hUF�P���JV�U,L���'7����=b���3���
�]0AM�Y2r��7� �;��+#��_7�ꋎ�_����T��Et���i&��mSo(Y����Kkǚ��y��8'�t��ӵ�W����=�CL�m��3n�l�p�q��UX��@A��������'���p�V)&GipR��03�q��9�ŜC}�k%w��:�����J�VJp�.n,�ŌI��:�h�in�(����A�̍�����'��<{�^0��p���ZH�IX����l��Y�0aqi�� s>�BNĲ��,r��:6��i/aH��r(�l��s2�$�&i�����E�*����B� c�Q+��&��3���$��]U�s��If��B�l�c��EƼ�s�U�\�,�Ȓ��,�8��v-��O�%�d�^�<jll�8��j1�X��j����&g�o�rˀ�+&�Oq�m�-�|��M��E6S�W�ҫ_��坲
3���fS�� �s:��t�D_c�R����+�O�������.2����'$������^H�ln��i��oFɮ�m�u�M$���¥���ђ�Ph�P���a9y=<�3�!�Ia̶A���` #>��?vM�`�҃i|����꣩#Plȕ����{�yB�«>���Zj{d�*�_��;����	��R�j���C���SkJ����]Z=��A���h�h�:��jGPh�dkr�{�DK��r��o�9ò!�Df��3�6[I#� ��:�<g��7������3d[�Șp������#P����y��N����xR�#�H�eЎ�ǳ�d����;e�4���8�:�H7�?̻�g���N��� rǰH�d�̅��a	��z�
���G����a��؇e扫'���l��޿C�	���A�~M�{��B�4�ì\�qJLt�q�&�=�=�o0���f"ۑ��}�˩��TO����
6/��p��Р������,��Fa�A��^�� �e��g���~�a�+��/{Ncs�����.�S^���Y�Q�Z��t����5���@���l�C��d�d�i�k�S;�f�ٳ+��y{��V�|+ +3�nSB,u�,�:�)e������)Q����q��^�Q�5��x���V��3���n�'��b�'Rn�Z�:���uZF3�-�I١2�����6>�=�ţ��]	��mC�Yu���w�OS4f�=�Ӝ|;�4�����F��O�5����kM��
�(�����B�s��H���FG�"Y�n�qdI���:@�H,��$�hJ�'T.͜)PB�WEɆy��1GѰ����O�{&;j�wC��]]�����1y4O(��dц�%�Q"_ԋ߰)���l�"����<�B4��W���>��ۺ��f 	�v�����oU� �>�Po�{䅺\��ŸF%�櫗^����aJ�O'��CMnh�}�qc;���QuJ�������b�"N�sOd>�[�2�)E�r�\G2�V`�`'L�sĀE�r�'�&�D��\�!���?��-x\��:l��}��B�?\4�����dyÞ�
�d���x[J�rVc�N}FA����j�lo)0�`�@ފ��G����p8( ��˝����0����
��Pk4^n$�:OP�@���}%D1+�H��)�5xq�Yb���ͪ.���04�9@�ݯ"܂�m�v�y7�E�ZnE����I�U�J
��r��Vf	δ�;r���o�:�$��?�Br$b~"�D���O1�x�5��ݑ=���򄵻��E�"�����J?��Β�ڼ�D��N��K] 20�=@"q�:b�3W�b���ѭ<��wǰX�;�k��w�az�1a�\�+���.��g�C��P�ږ�tU��1�B��w-s�+MK��d�|���"L7w��(�lTw4k�[�m�_O����������:��V|ʠmS�Ƨ
�@�
m��$������U�s�9%����ˉ���cۤ�h���Ƭ�b�� ��=iC�l9��scle(�q�	�+�Ї��ȋuAb*r�޿��Ŗ*J�!�ѩ�z�[�}����-�����	G�i��v\0����r�
rd�c��y=Y$��l
�k���:o�˹��1ά�<�n���ϑ;&������,� ��� 
n�U�9��]D`y�C�n[uFS�o1g��xd�b<�T�����G��\���X<��fB=w�d�kQz��Z�C��$q�?��l�	��y��{ud�.X��N�Y>E��b>�c������v}��5��Y�%b˖�<1e�oOq�s���G(?��c�ZɬT�݊^. t�R˖AW�]��>.�����Q�N���pkR+��<���_X'_�S�{� ��T����6rT
�#9�$|�z1=u~�u��c��Ξ�V����{�/�-����r�x�/�P���4e��-\i��ܭ���@����Ѫ!,�h]3�rb6"�͹rNb��tߩ=�U:�g�
�^H�$+��{���C�\1D÷ NeY�蟬�L���[RynCw{�p�7\�.9�;�k��C	/�K�wL��N؞n�f+Fl���[Id*��hK�P�R���}���ݘ����j:S��`i{ �]���Գ����"J<z2rQ�]�T
A�HKK c~i��2��W�	ю;:So4B/�$�����]�(3#,�-�k8�8rT��m���Y8����*���K�m?�>������͚N�:t���Sk�v����yI+��$fT�J?�B��K��n�-����H�:ð�{n�����떄�uKVN%�k9�����V��4I~J�N��}�g2��̢Qw�a�����S��g�cii�D��Z�}���N�*I�9���e���tu�l���4�d��2��dK�@��}a�c����GRȐ٤᪚����ݡ�}�Ns*��ޘ8�Ԇ,�~m]���k��^`6���
�-�h�,������e@6eg1���g��v�BG0������X;4�B���+���I_ز�a-R7���C�wiuA�� I�dx	��;kcp�Y�7�{�`Y�ه���SW���}67�s����C�'��C(h�N���C�)c�¶ْ���6(�W8(?M&ι��8���oSBL�(�����J� �s�k�+oL�������N��h_�z����SQ���s���=e ��E�z��@��{�H}���˰?ʽ�P+msz�mJ��k�Y�ŉ�6݈�!����Jb#�@xA�Ƃe��"����fW?˵�v�+ψ�Lm����d_~$�]R�޳2ۍ�6%FW�i��o�����7m��5��3f��'�l�uk����J.�浌�v�K]w���
���[g�KFG;����PF5�qnr�%�WTQrv��ߺ��ԳS�[�|z�+��y�դǈ�Az�u+�y=���-�����Oz�}�;���ӱ2"I��j˷�7T�A��jT��V������$(�V#ۧ�ߓc�������ʌS�SD5dׄx
�d�͜P"���(����F��K埯mK�Ow�n-�%�@�c��ލ x� �����i ��\H�TU 9��z���s�J�^�@�
k���TK-3<��ȥ�No����:�!��Jbz0�0��N�Y@�W�7NPx5�������yn��ʬst��p�+�vKب�c���\b"�Ii;̦1�(a�(�I��^H>��uv�(AY���#Z_��'7 �	���MϘ-1��H23�`u���T٩ak�q���ɪ�U�>�|�%�ˮ�Թ^ǅ0Z��STF����|>/X�^���Ty�U
��IІU���\�o��e޲�R��{�2?�L���φ3Ձ��	k�#VcWZVƨ.xi)���mi����>�� �.���U{{T<����y�i����ܹ؀q�Ǐ�Ҷ���#o��#������tA�G0��#��+�@vl��/d+�����������ǸZ�\�#`��E�b��?���\�{�%U�ȋ��,)y�=%�ٲ.�Ѳ�w�
��[�P��T?���8#�v`��ʶݨ���v�����3E��מ&q�=Eb�ZץٶKd�@�Y����=�3Q�{	���[��ϵH<8A��z)�lsL(9��g@��>ő�X~zlA@ة��92����r��R��q��*���֐��5�c�O �VH�70!h\�Ɇ���\f ��!�,�,N��T&|��$��ϛ���Vꥯ�'j87���u<��6FN���٢�~Y3�#߂� |�u#�PкG�A�#����*�ͼ!����A���v�E��mi��7��:�L����|{��?���f{
z�ݯQP$��*���\
�KC�q�c�ֽ��m#p@)r�Np�����J�� ���)/_�қ

���el̢YbE�9�����&�
�L;,���/U�.�s���*k�¯���u��2kK�RM����������5P�2|x,��)m5��|h+z��?)���a� ��C�HAگl��f�䙕1� 03��?�n���l�rb-*p$H"c"��%�Iϐue�'�}��^�럪>W�B��?�t��~�gM`����r�o���
���[�#�
�N�M�/��%�I��i��1���RZ�y��<-�����և �� ����y��shĚ\x��FT@]���m �g�/��@!��PE��(�����x�7�!Ϩi_���٫z�-�K`�CG�(g=@n�;¯�D?=/���(+�[���3��:�@����T&�!Z�KL`�]��a92���jAu�r�A�r%���mnՈ^G����c�4���
4HHR�t��[���� g�Y%�|I��oq����(CzO�]��ڟf����g�s~��4	2*F`��8Lbj�r
��K-�Ŋ����0*b�H*��tȱ�kA)zx��Հ�\�����s*��s�
$|�g0��۳���D�&2� 6i_Iu�na=�7S۔t7D���*� ��=*s�P��]Sb�Ġ�Vm/:�.��s-�߽k�_~��4����{��EB}�m[t����#�]�f��TĐ&��k�U�#�*��Hpج�O��T�߼p�ˌ���=�'|���7_V����r	��H6�4鏑v��m �{�W2��5��Lv�jO�G�u��Rs�G=���}I$�~=1ۓ<tԆ�0wכ+f�.~�;?��0`'b>*'��,ˎ-�ڞ�8[�)�4�� �*x�3�&7��O��+o	�Ǭ
B	d5��HsE�����)^����Si�R~q���T�PhX
�.�~[�a&�߀
�E�x��l�p����j����@��i�PT��SڍV=ے���Jg���e�O��i�6 �Ə��cW���ղa���@b�ɓc��������n�����l�y�_kxg��X��TŴ܄񫨬�ŗ]���(V�'<U���X`�n{���FL���7�����P���U4Wy�6��8���:�K�s��(�ЦJ�LT,L�:L26�����+;g��jț� 6�*�$�nT��y>�>"�c^��o$e�GK4��-9{�i���e��C��z���(��$�h�gTTɜLy{
N����VL�3��5�'	�q��2g�ض��+w.Mt��Sb�'������e��ӾC�3�s%7�o~��\(������p�]���q�ݥ�\%TƎ87����b��p�t�棙��+���ַ�~=�>����Lp�s/�⚎T�A���N�gPI}И���y!�4��<�{����X���q��\�ˮ8�آw3���v!a���չlM�j�gZ�#�q��8X������
��`���v�u��~b6���f�4��
����̾jwX�-��k��y�4�Ջ�6���|/�,*'�7����v��Ȋ�§��P<Ψ�.װ��Cwq@�Ic�7yq�y��=�[��D�f6ul)��eo(�˷�P��^)��A�]X�Q��ZS��fH���#q��<�>,����T�QJ4�%�szl�L��l����
�'�]��݆�����U�e;�	�kȦ�FU��=���8���8{�r�'�c�t`[+�	�#�LGl�>Z�B��Z�p�Dkÿ�`lZؽ��u���x򦱪/-���m���<�dF�>ci�,2���L�:b2=�7�{���F�l�ڨ��^���kjl=#Ga�5?$ߏqXd�]
�T��I�ϝx�غ����������4J��?����t�W`
@�WŹ|�*�8�YI�a�c�T�g_1��S$��~QJ��7�H����\[�m����`���g�V۷Ӣ���w�W2�pt��A�|yҗ;�q�(϶��\Oݠ��{_(-o��Z�����h,���rϴ���$_n2�W�k@�iq�m}��08Y�{'ਫ���X�k�:����"4I)���b�-�U�8��r\�#H�3|�@-;z��J�=хֈY�`�VW�=�� ��ѓ��.����>Z�Nɹ��>�G�[_H?3���1~��@$}�}�4�_,�g�f!m������V�m��J�gX�4Oy՛��:��s���Ѿ�{��~��$r��l
���A�Z���b�Px��G�%�r9&�=�-�\oՔ�@S� �1���ˇ%*�N��R��ĺ�O�[m����Ww���� �vh���(Za��n�5ޱ�՟z	
^W>	�} ���2�޼*���/�����_�I��� �E ������LŮ5��:P�C����,�DhN���}�>��S��߬{��IT���n��#����ҧ�ွ�e�b�x2s�g�!�K�>��7����W���5�D�
 }V�F��毿~�>�,c&�c����D�&ky�j#��p/^��t8�G�.�X�k�;+�#��~6�!�\���#���&<�+D� �
ߦv��E('��mr�����'s��{.|$q2���)�OI��1S�_HUU��K����.�85{���n�m0%$��{Eq�[��� �BWx���2?�E��
N�S�� E	G��l�0q���dw&��H<#��M)f3��dy� t�b�i��L�!Ed�F����ߘ��X���4�r��Lr�Xĩ������V��;�Nb�zX��,������K�y�����z�b��嶬��%P8��t!R�x~�Dm�ΰa?d��#����v�_�L��BS{ �0�("w~�Њ䭘�	�{?�;���I�?���WmV�Ȉ���k}����%����]W[Z���*�.t��?����.1ݏ����!���ql־F�m{u�� 3�L������Z��PԦy�9)�� ��=N��W:ĀnW�dO�ӻ�au�+�2aD�F~1u�ܙ�Ҥ��l�O-6(��) ����4�m��a YIK���~�ꉅ�@�V`犨��E�,aʊ�	������֦7���~��*W�(f�@��$!�q��'zٳ��N#��W�p�w���*�s��A\;�0.p:�\%�Jd�D?�ФNI| 8!jKǜii:�����<w�r'k���z�	MGp�8|W�t!bV���"Bo�XR�g�%4�����(�����R ��|;`?��o��뫱�A���K\=�61���V<muG���/�<(��p%��W6}�a<,�}�̿@P�V��L����r��h��T>�����m[���D���H�F�& v)?�~�ޚ�3t��4)�,�|h=�c
��:<ЩHW'6�B'ݻ�nzw��b��\��~*|�Q�ҝi��N<���=�/&��h��J���-�dB���s�N��5�8R^~���&P���QE�B�a�����\�h΍ �2��67%N�CP3���h�K.��ӈxxi9��!7�\��IZ�`�Ì���������u�����kA?�S�� t�� �9�p���� �o��2���KX<�<�u,j�G^y�dZn�����$]�g��}0�Z*2a*�jDG���܎��1i���B�ɣt}�;.�Վ/�Ҙ����g���&69�G�(�K7�=fG��8�=�J_��^ �ğkA�S�*�hq�I�=�>\�����NX���[�G�Ud��,!#�z:��'V�t�_0�Ƥ��I�V �|�Cj��z
:;7x/,�Cj�Q�����k{�3v�w�{v�	���7��}���n���БB�zY3���^�5��&w����B	���*�@.����}�OK��р���d��p~˺핢��1��3ι��;��!��;T��p�ĵ&��&h@��;J�xZ�1��^�al3mt�G�`�ې�����\[���k��CP�ϫn@ef�Xʎ�$�j��Z�1�/8J,��6�u���fW�i�ZY�.Q���-V�Rȃ}Pvۥ��Y[UX.�>���1_�!���&+9�:đZ��	��>�S�ngCD��������,mh���I��z%��*�N��     �n.���j_ ����$�m��g�    YZ