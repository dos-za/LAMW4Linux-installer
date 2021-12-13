#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4134218890"
MD5="208596b94c5cea6e3619fa3fc9383de1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25556"
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
	echo Date of packaging: Mon Dec 13 14:12:24 -03 2021
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
�7zXZ  �ִF !   �X���c�] �}��1Dd]����P�t�D�"�cI�4>�������A �ZON�UwІX��^��]$l��z��_��~�퇗��)�m�0�t#z��A�`ōz� �4v�{d��,
RI��v�0\�rO���!k�l�>z'��)[�tܨ��7@�_�Yl������D�w�wʫEH�1>��V:J;CAU`��{�½�.�R�gno�%l���<��^u!�!��W�~ne������	���xba��qz���F�E����Ι��$�b"���r_���k�(���܈իZK��HE��i��4{�pW�뀭1��4�6��r�rGaϭ��w:�޻31���^�](�ģ����i�煄��~����`纲3��G���g���j�C�5�"�,ueh>�B?+Ba���Nh�y�{ؔ���?�3�S_9"����I�\���JR�Gߕ٥�	�@�������Nv;1\��C-+�=d������w�=WG�d�ᑽ��Hwqi�e��ٷ!������)�J�Y�'R�'��c��o���ae3�s�D�}���a�:&��pnBCc�#g�.X-R�M�W�� ���5V�ޥlE���u�L��W�>�#Ͷ��������(�4k�*كjV�ٞ��M���3΃��Ub��0X�L!����>�!���|�۟$ώ�2gV�hS��_M�� ��� B\u�4�7�Q�->g^+$������G{��	��/jX��O�V~�ԛ��ZQ��ZTt��U�i�/!����ɓ��sD��S��N�H��J���ޙ�'H��ɚ����B_"�u�0��W�8��
�6��*������,�{ڤ5�:BY����X��� W���^�&�ë�%,Q�^�����#�jq�>te�R
A���/�ч"
��t$95�cJ2OHca�
�P��錷T1)�i{O�D:x���ɠ|q�����+W묏��7H�9�i|���׼���]�t�_�M��W�,ɣ���w:�<�P��O�~��n����h�_�-�J!�O�6J���[�,uV�X>�^�^��U u8�[�KZ �-N�%�_[ƈ��[���7�� �S�r
�*�ZɎ��r���[� ���Z���GY�R1��sP�,.�I>hk���;�-�d��&����TĠ�"+����	j^���	� ͭ�4��}��C:,f7>RZ�(�J�WLnۃpTUQnC�)��$�p"�ŀ�(L�\9+8�&|]f
��<-�cV�i=:H|��p��kP��º�޺�;������y���%wl$�`� #����� �!�FTF�[0d��3{�Wy�gڧ%BFL��8��Z��N�zl���5�%��_`1U�$�S��k�lw��r��pu=��g�%�6Դy�|�ά$I,����4q��ˠĽ���$�� �W���/�޼�ޛr�u�	�U�]N���%�Sf����hz,s���Cx��Q[�!b-{t~��S��+��>�線�3����p�(ט�.t��2���T�eJ���᥼����Ծ�[N<0`Q����Fl0���G�q�9��i���6�96���6[a0O�$��d�U�(�ņ
�3���P~�����7��Z�iE��㑋��cei�G��+�A��.�2�*˼����dy��%7�V����yZ�&���@e�����>&��&�!����28{tv�t��2D��+��h0b0آ��0u���t��)�a���ښ{�r�6��Qr�)�����^t7�>�غ?o�-!��R9V�s�o5
���~5�;_���̡�Kx�y��:H��g"���8�_�uI�� ���6%�G�f�t��6~���'��bV�?
����4%���5Av��`��娴�3�3�	��Q��-��7H��bm� ��ëb�y��Vn蹛�s�#_�AF������� �E0����Ӟ��@<Bo�&r�F`U�pܜG ^K�  ��e"G���<��&��C"��=��D�B�DV�e�{�P~⯹��!�,�0�8W@�!�L8�X�ϱ��&��s;�֥�h/��m%�v�3p�oӥ�
�ut�Ԉ�T�x�mm��,�r�����]
�%�#���:���n� �r�[�m K+��ϡ*���]�e�pR�1����Dwh��s�å��~����.R2�@:C����S��U���=S���o��1��5-�PK����d��w��>�5���(0$�1/	��9�������vQ���c��Z�E�ƿ��r�������j���l�4kl�U��@5�?����Y��5��O�/�����Xq�����ڍE}<A
���sj�4L�֓�yA,\�dv�PL�
�`��9��ȝ������翂���=0�Hr��!��F9���nxg?V$r9M\ͨ�{�s�W���3���X:�"�.z8u7@�ڃ�����K'QE�
5��������<�1���P�M�c1`���30���C���y1!�#���c��n�QI\}�����^�֗��[�rG�y�f�'�����!2.���r���A]�`�Q��C���1�*��_���e���%>b=@&]&�Ώ��e(���	��!�AZezn�P��Td&�i4�g̦�}�D�x쵼&B��P�Iy(���rZ�v�1�
~V:�2�u ��4�";�u�˶nc6j'~�}�9��5�0}P44�
�S����ҿA�킺�����c.4da@Hiy�����!� $��@8 ��c�-��s�^�>����5o�7���7w��E)��2,1l��.
���8'��Z�U��p���>F�%��Cw�GY��R�c@���!7д�72�>�(���<�DH&���	�������Vy��se���6kY+t�)K����3@�������3�`וư��>;��ġ��|WK��.R�K����d���������ߑ�B�!<���9d
5#}-�`	O��B{�ۙ?�Mz�F�];K>�8���!ӛp�l}������>l̆�/��y2t�?�QF�;�\�k�f�{������.���f�V��o�-C��~2�,i��l:���(�Mg�4P(��� ��e���q-/�'�O\���K���>��x�4#%L5^\�{��0ob����i��27S�2a
?_�}�]�XP�G�����1���tH�c=�Ee6)u��T��UIa0V�O��G�A�#�&)�����{|�sԟT�&ȰQm檬�uO�3�=B��J�ud0`~�T$vCƊʪ������ʰH>��98Ot��t<��Ulu��*�����,�����1�c�N�D��"F�5߅E���n����8��?�,�,7�)
FaO�9�~o��Hq�d�<+T�O O��d��H/�C�� *����PKd����u5)!��u�Ӆ`ݦ��d��|��Nl�.v0e�P%ת�
��
��a|d����4�)V���.�0[!�;�QqfgRN-�����y (���r�,��0(a"����10��ۛd�c�u �*kڭX=/�]TDk�c��4�.o� m�HQtr�䞏���������D�A!��" �̹�:,ݎM��V�6��p%55vb2�%|A��3.�n�����F`�?v�jA�C��e��(n-a�6� �n&L0�����!	@9O�Jw��<�?Ne	�
XZ��e`�#�Ob?1�S67f���ʎT�n����Nz�e)�b
��c#�����7��<�K\.�
ؼP>��������FR��xDa"g/��W1 6��?ܿI����=y9�[h*ɧ��y�*�Rꚭ�h��x�y�`+��s�IL��M%���]���T� ���G�}M���Q ��ހ���v�2��=��~��Pc�t�*h�x������(�?�s��9Z$�_��e�b:��F70+kS��Y�i����]��K2�~&���x�,��b�� b�=��X�ix0% �3�a�S�XȚ
26��R3l�k#�C�u�S!N�	 �ğ P���y݁]AE�z�_�r�ߝ��۶7F3��#���� �7	w���F��ct��amo#��^�a�� �E�i.eګ<d�l�u����J��#+��$���A)L�9�+���ad�FuY"�|+�0�tn����޸��j�37	ױʱu	YF��m�(j=l���w��-q�b��L�M�uTn��-H��D�͝b�D�k�`���C��Q��p�9I�6-�v��*!nn���<����0��U}��a���#!;*Q���T�y���J����irr���:�A�r7آK>��.�r�,�� �q{�1�ϔOp�4Z[�bvt��~�<�H�&<�B%w3��9�m'+�p�M�d��f}\��L�Un�ˬR��`�:0US8!��D#����-�/�m�sQ��Q�*Ht8����PL0)x\J<xk�hȑ��r��O�" �t}N��fP��u6!nE]�ݥ�I��5\�f��FM�l�c ��/+���z�J��]^̭9<�M̿�4� !8?��P?,f�86o�Ŭ���J�6�E��W��V9L�Uʃ��	D��2r@�5�X5���A)f}mN���3��˪K}�H��Y�͵p7i�o�$����SI��=�D�_��6�h��n`���=qЅi��`P�����6��7�
H��-��g:y,�!�2��	}}�.aހ��>`vz���[��ы�Ke60/�鐢�H�|�C��H�5`0NK�o����,#U�������VS^�P:Aj�����Ϙ�IzH2N.��犉<��*�ek )�6r!	�;\���®P��U��:�*���ɤq���G�oB[����)^R0D��XPod�eBY}Hl����i	�YL�s�B�i��H��"a�L���&x-OI��]x �(�.
��7�RU�_���'���q�A�6{nY/;��gbդ��o��cd{׷\�d>i��Gy_>��T��>� :S�UJ�1w���։N��O�����$�$c�1LꒇD�4ĥj��F�$Հ2�9��¬��,~����mIM�΅�`$A��k�l���dFt�l��wp����1ED����2��EO[���U��B.��A=~�xH{��T{���y:xΥ%bxw���\���I�t��sx
��l�KnWr���B���z(��7�:�i���{A]5,��5��e�(3�qȇ�ܫ��C>ܚ\�GJM����JLPkq�e�{D֭�˫o����E�Kh
���C��$À?��0&4%N2d����C2�;l�̚��'�p�dY�+A�C�'3�g5,�����-ܰ�I^�Z5cH3����NFu����d���J4?�+3�<%@K��Z0
�f��t���g�/Q٫:�l��ל�%��I�����~Έr_7t�k�Q��������U��e,�@�+��'�}��3�'#\beP)�����BN�LS�9[G�d��L�B!B����FH/�ꀪ�[��S�j�V����o���s-�����T���
�J�@>�ȼ�ZSTPi�P?0٣ޙj���%��G�;'�FQ�Vv�C6�E��c&�2?�����+ŬMw�mĮ^#i%�Y;�p� O��h���ر�JLl��t�� 'KW���>9�����$i�~�����6����n�-�)�M)p��p�R�
�?�7gGt��	x��:/p]ͩ#�����(\ ������e)��=9!���i��(�+ҷ�kM!���o���Vؔ	�R��Mϱ�4ʃ��ZD��O�II ��a�-;E}��:E��Xɉ�R��n�o�p��N*>��@��~ߘ�i��^y�̭Çd�y�4V-a�>��<�p+�\��������Kd�
��N�-Ťtf* �?	xnDf
�E)��V���bh��U�r^QM��a�$�#��i�pOVH��~O�M����w��Z|�NO,�n��2��ڒF�)K�I�m#z��Y�T��}p���(�n�ԟ��>n�ķ
�bVO�f���a����O�/*X�P���ތ�N��:���Xv�3���ӹ�6����z���s1OxF�� �ޗ�����ĮSZ����i��`�m>�hx�q�Y=�O���`�D	�{�e���B�d���q��ޱ�Ժ4��=o����dRUdCM�nE0�j�9�.��[3S7]M'�ט����:�3rn,�r^�u��v�����S�W8�O�{D�(�}6H��[Ӡ߽8v_�朩���թ`@]D���I��8[��7z
����k�4:���c�NjE!S��, �g9��17*P��@�b�c��}��f�H���0dO:��=�yF�ԕ�=��IBN��u���aW����7ދ��� gE�%�|��uP��J���	�(V�3�;��K$2ɼB<�A(�)�'د�x#���ﵱſ7��<�l-`�o���\K��C�}h�����,�t��ˇ��w"a�b�\%e�x�7���Ч�V�#����k��SOqG
:4�vX0g��4�c� �tm^<S� v#:A*Uh���1�^������܃�ի	�\���=�ͷ���m��(<2�{3���07���|�LW�ާ���i�A�P�����o�&��:k�&��Z�	:��uPΏM��|RMs5rr�Q���D6�<���奉#�vӇJƥ60�y;�Y���z����K	�/,�B�*&�>r��WO�	!%�]�Ȝ4Y^�:r�t�U�e�!�YPu�:ǎb���"@@yw!���̹\���F�ȟ�9���bcg������A8��H:���U�`N
;�C�s�jT�Or<��r�z!r�K�6ٵ���L�Ѹm(�̟��bW�a2�[�I�VO�����CT�WZ��͕@+��.RN�<9Q�_�f��=�X;g(�?)v����xxl5^���І�n}��=h�w�>��a?Xg"�jN������< �m8E�����m�h�S�G��y�Z��аo/eq�F`���P�fD��*;E��v��ы��V�l�hC��2y�/CPл�x�&%Z�>�0\�m�������ϛ8�����D%�O|_��gv�✵ʂ:�G�R������6lw��{6��|	t��T̫a���R��o���	���þ�$u��G^��XIdǁd#[-.S�uX��gI~���q�w��m��2��M�����$1H��| >慫�.�7�-j�,x�?Չ4�tH�����s���R���r_��>�XWS�uO�@Ǖ�LG���g��/��p˪� fp�Il2QQ@<>!�����[��3�e��I�?�!������K�`l5�����g�6��ک��J*\�PL��H�3v���w��:<�7ix��`e��b���Ѷo��Z��
�*�Q���%D�ݵ�9e ߰���~��߃:���! B�u*��/`�i�<s�	^H��+����5��q�Ji�u��JVNЧ�֧��-8�C�i�	�
读eo�~)�4��$�{$�v=���:ДǲԾ(�5��6�[� aHLc�-��u=;��֫��r{`|�D��5��_�����qk��ˏ�I	:$s�K�䒸�i%#�<��j���� ��l��K8�ԳϜ�ôx�4�6�h'�[�1�j6�;� W��'�܆��Ϳ�e0W��0fzcO�~e"��@�I�m���W��%��1Y/LF���⦛���O����`���x��q�CKeA�:q5�.�k�Y�����Ԯ�?t\�_���77'âzF,���Vr[�Cv�:=���F�=:��I�]u7�N�ٌb@����������-mn��y�[ܕ���Va��+���3��D۽�oG�_&b�W�O�I��e�$���,��|�+\%o�v�m`�Jr���΅�X�&��Z)��z�%���Z\���\��U��?Rէ��/�~���v��B�)v���~5��g�����g6辁66�.⺈� ��O�!H�[][l�M~G��u�{1~K&���������gLŤ$슷�m/,z���S��S��:�1���w<�#$�zו������bs�zKA�x���u
�ͼ������d��J��۳�H�H���D��-�D�}��*�;���=7��Q�{�*�L�v��x.L�Y�#	I�N��t����8fY�q�@A}9j}[~���S1����P�,�s=BF�������x�A��a��s���P�������Jj�%Ju1�9��L��7����\�,�s~�[^<��h�)���RS�k�'��q�x9�#�G"��з���$��+�Ľ��d�𗑣�i�k} !� �����rD����J+�� H5���Iz�]��x�κ���|_���� M(1�,�`7�0Ԁ�_���=~, �^�ࠜ�E�J{P��{����{�^g.ƈ]�b���r���}�{�E���e!J�5.��^�z+~���xk���G*4 �`�tWN����Pè_
������%�j������Vn���[M�J�����U,�'�A������7�G&���9��,YڐV���q�7��DK����e��-��ie����}�n�z���_�M`>�}��s�P�lԺ��؎&�(����S8+���(u@O�¾�����fVC�42R�P�7�"�!	ڢ�Ő�K$�u%�iq�.�XPڢZ0z�O�G�S�r���_���\Q����q�������M윶��Ԛ��ki�t&㺘��
@(+!�U2ыW�� yֻr%���\��R~�}ŀWJ�}�����Q� �8N����(s�m?�;�6;M�ho�F�ſ�F��"�~�0�8���,���6�8��ly�{C����;ܣp!>"��K@g������S"�K�/%��볊Wמ���-X����'Y�T~7���:���E��e��R�D��Ĩ�R33����O
���N�t��'��F��7I^����� �x�>rNn�+�c����ަ�r�U��<'����9g��nj]��}'�mF]�J�)*��g��j
p�-N�߈��|L��0�I�F�^K���`ȹ��+�%�!��6:UK2D�-��أJ�W��x�����$&2�)���H2(�&���6�[3���{a6i������y��=����qD�k|�"��=��^�B|�D3g����$�r<��c�|��wݥ���х��������`��T��
��v���+��_5����?��>�׎i���3&���l�\����9��6~���"�9#6ʪm���C��;*��h�Z���|�:rF���%�ڴ5����%��#���~�R��h~}d|��ut�"�;`j��(�e�ؾ��.'�пHe����v���,���E��+ =9�[�8C�z�-G�9à~?��	��t2sbW��j?&�i̯[�����YԪ		��}20`6a*L�Bg�d�DB�	X���IxIG��rh�==9"f,�x���kl�h��3�rd��:�]��#?p�x�kYasǥ�"�\�K�>�s昌���Q��gU��B��Kv��D=V��h0Nf�ڞ���$�����s9���;�Q	3$�&�]�j�|g_��6����������袀m�rt�1��Uw������,SK^Ԏ9\�dv^��p&�	~��<���#�@J�m���H�L��)E�ќˏ萦���$o8��qB剚?:�h�u�٥��O��|uR,��,-f�B�+'�P��'2)��հS�֊�d�(B�;���/�y%���I]��W8V��3#"��X�"�����q�G߫J�_�Ľ�5�ɚ,H%J�����y��J����1Q#����h�ύ�(�wz�j�gwtM��z�a������nx��i�����#�-m@$8��Qh�x��؜0��o�K��@�l��*}w߈,����.�ο+�x��[�.�%@�W��B.2�r�v��6��|Ʉ|Ks邏���D[�zA�o?!d4�[���'�>�!~`�P/�^ۼ`<ԁ�p�AwZ{�E0ޠ��JˈD#��z�6\I����>���J~ˁ�g<S�{�ښ+�c�h�Ÿ5�?I	@�i�a4~OK#E�1g��cb��
�h���]X��0�ᓒ� k݁�OG���q0+��MW�B&#��|d��3I��H��X{4��$�!Y ��Ą,��NK������s��~6-L�`��O�tL��C��-�y�VFm���W��At���_Zz?��=[1��@��^y�G��|�^�Y`p��W����c�WW�U@��7G;�oZ�N�ғp��Pv��k�,�ڇx/Ri��n�����SX�OA	����2����;NR����� �r�zn����� ]��cnX����sM�>�3�����1��?�d;��H|��ٽ8AUl��޵Wgk�H���� �GN���q�(� n���ɂ)�$E�č��<�Qq ��G�7h�#��/�zn����/�;��)n����/%�p��cX�qhrVE�)���ة�!,A2��3������۽��&�Rc�a�Pq�q『=҆ j~��맬FQ�~��]�܏$�>D�#y)�T��Җcx�r|FO���vՔ�p�%��naQ��Z�����ʢ��Y ���:*��!a%�lc�o�������7�UD��;�2g&�m���'s��H"[������;��L�[��Ȼc�K�Rb��\uFR��*�*������\��Udq����`�מ��3u|޺FB�F������lF��am8����'NI0%�X�
��X��3��Gɝ�Z�z�۬�׷�ճ�T�YSzڜ���F ��aB� eMSU�8�1���T�����k���\7^t�Z��^�4���M�_�\����������2���p[���=f�qE<U������e�9
�2׆�Vo��u[�S�ԫCf�#y�/a���b�7�������MKMVs�>C�~D�@�J��:=j�)K`� �O�?�[���U	{�t�Q�hn�\�s�%�#ݘ���n�@��cr�D�$NW�0�� a��4�<�oܶ�ʀa��c��:p2-�gL��nbB�pL�hV㭇 |�x�G�j���H&��Ag㘉	~���l�~�3�Gcȃ99���
��"|��3)�R��}TDOҳ'�k��Q˱Q��X[��T��S���Qd�(�A�qbeY^-�[kB@�ӳܫ*�y=��4 6�ZS������"y��	����,���:30�5��P yrJV��^^vDv�e�w3�hk�֗ϷZx	�u]_�J�FU���gF����`��ڊ�ǝ��w��i[����m>�F ig�5��� �������q5�T��m<�mҠ��v���@f#ˎ�X+Z x�ݨ���t-���k��9%�����\��#Ni� ׎����3f�f����'��m�3
��8D"-��8����1�9 V�e��^��/17��uA5��5�0����lWw��[��<��h�;l�:A!�d{&�������,�x�� ��U��I�N�<�,��NWy'�V�D͛Q��Z^u�?�F�<ʮ�S�����0 �����&&��������g�7�݁����H���h��Qg�	I���/T�k8� ����67`=�ES�m5������Ɂ��r�K�A����wz��h���^v��m�Ƴ���CD<X@η���)�+xc:���6U��׶�l�O ��ǒ�-�-�*A���`�y��"\{*�Z�^�D�W�^?�d��l28��?ј�/<���D&mO�����`H�����w�\S���	��B�]�w�� ް�b�!��ҏ�m� �<��TyA������H�ZQdV��)7��C{`Y��5�$OԘ3�B��m��m�PT�%�e&�$�w�T~P�d2��(�vFÏ[��c����"\��i�Z����U��=A{t}�ٵ!��9���KtJw�v��#�m_9)ƥ�d�(�ة�M�*�Pb&ԙ�h&��4�0D?�M��G4��j�Y�/'��Zi3��!��xN��9-��Y�K�H� ���\_Q����ͷ;�� �KM�d��4�n��ʸ͓\N�G��v��i�ˡI�8�f[���w끳��2��ZR�T�2�X�6�6�F��U҈���4tvA�"��P���8�^��X��t��Kr"�R��(����5}K�Q�÷���̓�;��CW������+N�s>j0Ckw>N�V��_�~x�A�A��M��m�eC��	�=�H#�u���,��}�5�u��RZ��M�9f�1Yq�x�!�~'P޻���ć�G�/�m���t,O��ܣ����;�~��&k�Q�"�W^?o�.JD�Z�_���J�wC��K�;t��>*�'1�V�-cC��J�\I���8���E/�T#j��� l���n�TWi��L��0����-6���r?����v�L�Da�
���z�/���F+��
͞�^�[�+�]��6N��ݕ���V�0.�'+��,����ٶ_h�=�>�����ɵ-��w�cVn=o�g����qW!P�5O���D��!6���ަ���)�yRƝ[�qdU� d�OG�ܳ�V5���%��1�zT��,����z�M�ƥ����"]�ޓIVd����]�V��G�){� ��{�x��C�f$��'����\�㈤ �;�B�1������n9R�!�Qi �k�V��lN����a;��=�6M�#�p7�ʳMK���a��J�N@�N@hh��?.�׋�0��_w�E��f^��UR@_�����S�A,D�2WU�0f�Q��h%֣����Ղ)7���t?};��/�Rв.��$�yH�x!�Hɣg-�����k�@#�C�!)vޡ�&��K�c�$Z���rku��L�5�=5[��#��K���GVG���u��6�m���'���ς	O���X�9$e�X͵2�i��~�Z���eo����.|��B�N�"F-A+�gZ�Ԧ���aZb�y�@7�J4m,azjPb�E38�C �׵�+�<���ЪL��/����_��;�3�p����%�iK��A�"'��y��B����6�����?��g�^	�,3C�>Ƥ�onI�V��-8aUX�[9@�\�M7�U�$,:�mxm������ƃiwk��[����zJNˆ{�O��:=a�'��ζ��V傎�	��@)P��6�ʫ�����Ut�����,0��e��6p���e�I`L�L��*j9(\�
��x�n<QX��%���vr{�V�n�2�E_��?<i,�:�db���RL�nH� �	�ܠݗ���&�����.澩ɅpY�h�Uf#��bn-)�>���g�H|D�g2�y �!���c������%�_��2��QÐF����vM�}��xZL_�y��,���H�:17(zY�6��ȴ���� 9R`��w���-�) hi<k�k�gjDs��~�Y�;�_cuI;X�εB�� td�`m�hqgb��1uKp0�N
�����l�K>N�[������7�����J��Y�f�П�| �?3�t��.)q��n"4Uc�
����<C�z�˥�/��$��iT =i�X�v��U|�x4`�=�.�w�m����p;�/o����ђ������Ws-ɪ�+Z�q�x�(˾i\f.�p���A���q��sM��Ω	Kl�h���H����AI{��3�3&(��J)>���4����a=�E��;���q�Bg��e�WnX9���]�+�kϕ&�M�i�U���f�v�J(�|9�>Z}R����8Sh.���ީc���oM���X�Cf��Q�V��|�E��Ҥ��5�;�W�A|�۞�\A��|��������`Xt��[i�yɖ�]M�cj2jj�G�O�"����SK�Hաz4����B�t`Y���=�W]�G���~  ��q�s��]QLͯ�3y9��mR���$J�L��-OV�.d�U�C2�j�
+F�K���L�0Q	�_f<B��>�>�Ӂ��d��d�5��2y9�j���O�s�5�Z������j���3��#�������]y�^��)=H,��z'|�H���9�� �A�O�ۈ(O��.3�#T���vc�т���~�͹�^��Vp˧.R?�L�r�؂����}G�h2��P��m��n�F%��$DS���p�A'7`T��wzc��4:t]K�	��<�^���SH�i�4��5	9�.}P�ڸ���W�EiF������:\��`�-,p�iċG{F��8q����^[*���0��E�E*ax�z���|I2������j�6��i��)�/*�t����^BR��5B��^�Wrg ���r�a&ş^�Jدn�^���:�K��0: ��*��$�P;�FL�mw�c[�J,z5z�>���,?O�m.ų�_dZ��V3�r���Mv�H�aл3���Xٽ�'��4�19����0���6b��H�q�����R���F�: �����A1���fNQw#�v�e�ށ���s�nMt�VrV7>�Zk*��6�CT�Tx��Y����i�.0cw��m0����}����=Y����;����f�˲6(�����s�Q�ZV�~�|��iqc��ĳC cH9��E�x�}v��2�^ ��^��(PU0<4ɎA!hF���\l�C��#v��*G8bݚw���+C���+�f��HI
e�sCX���c1um4�`y�a���3C4����4w�qq����E5���]&0���dJa;��
|��ZQ5�Ԝ$�+:��]~&���}�Z1{�R����ƕ���*�Ƅ��j�L��A�1���/��L��euc[���侂F6Pa�xp)o/G�_�*P�k�P���m,3����׾e��-�7Ѿ*�0�h�R=��������zli���V���z} Q�+�YX*	��4f����V����2�*��S{2 L�CYA���?O��X!q�u�6����� BZ��E9lÅ���\N������Y�7#��Kʀf�ƾQ�u�ؘ�
�ۊ��]I4���[�z݁�tΟ�wNi]B�b�Ϭ��hT�T���dթ*��-s��������ԹU6)QCrm�8��:|�l|��?~k�=�&sQث@�sJ��� ���x�C�&�o�3=X����xul� ~ !�߬)&��f&��ɟdw 74GZY�_��������ĿGj膰e
֊մ���,m�1R��רô�`�a%j����[�\d򽟻�;+>ó�c����0N?]���t��j�����IU�R�7r�������c�6J.�5e���J��<gƊ
w2�cf�_�>� �Ҽ�ʩ3���O'{tz^�ݑ$=z5�\�lX�7���8YAA���RG�U)s�}4��$H�N�
1��xw\���@b�Ԧ���_�(.+9_��:��8����ڞ�w��Ң��w顺d.d�$x.�����32ǰb	�4G��@�x�^"|��֣*�"�צ�V$��k��=MĿO�6��Z � D�����G�Vm�(4h���^��]{���Ha0����qʐ��G��5ym�lvPɚ~,mf��>ty�iy�X��8�����S���B���2X�$5qd�Dn�9VL�&F^�"u$L�OnkI?;!q����DH@�ᱴ�e��3�,Ǘ{���_������R]��z�	�f�G��.j}��Z�����]UVҝ�xt��I�qF��l9S�����n �0U$-lĂQ����F'��4���y�pd�.�i�M4�ן��ꗓ?%>��)��Y�z���.,FT�}�`UЈ-��<R��Yr*��:�c@ڋߐ�7�AK��sk������Ӄ�01�k��m	�����W��W��6*K��	J����s��-k�D��0�P�e�ԧ�e6X+[��.�h�!���:�`�'��vx��&�Av��D���Y�=� #�����t8в(����Q���9��Y�P@G�nq�)�H�WK���?�Z��կ|����i�r����d��Ip(Zе*+R�7xd�r��v��=9�1����3=Su��=ӛ@�a�_:����1�UaJ� ��ku�}*S��d��×(�<8��	'5u:1��H!��{�H�{v��AלB�bUm��,��Q��EQ+��|C��$��9���hG.�2��EV׳X���ռfEkQ�K�W�	�ب_�f��*%y=��uE�����$h,Q�ZN�C����=����n�E-����e�^8[z�a|CcAw��@�F�v�}L񀱱��)�#yf���S�gA~-ù��#��Ά&��`B��dW�0�S��g�U�}�8i�;q�H"d�`�a�z�c�����,a���5gY���b�_؞�~D�H0V$���Ƥ�<'��t�y���t�����սMG$y��p�y"�Z������'�@��Ы�%{5RA�Bu%c��G�s�:����!����� �iOm!�|q��ŀ
�f��c�xn,9�|zr�-Ff�Ex(�mr�,�/�Hw�af넍-]������1�ǒ�E;3��zgt���h�N2ocA=��D���w����:�M [��f��)�h|$
��%쩓m�&*j�08�U���D&�]��á p	�G���^�
���4�B��JׇG�<y6��s�s(��8�h:����w�r�Ņ�Y�A��-�,������zaӪ���{�aR7��q ?��z�4��d��j��{���CRm}��}T�����C�F���I�f�c���t	�������b���B�kn'zP:Q�Li�0��v���j�y
pf��
m�c����6�v���/���� GS����O�]�tWF�)���_�j9��><�FO'�>+󤶞20���e%I�p����`�E��]&��+�w��5 ���Q%�������;�?��A�xz�o�i��|�r*����n��uF]3)6��RP��F���Z*g�ԍL7��]a�xa�[_y��4)��h�w�wz=]��������L�ʒ�A{�K,f��m�����:	���BbZ����� ����X�p���`��1TG�rI�f!�3�?J/{��1q-my	��q_��2_jr�̏���7�Z@����$o�jxNŸ�h�|`B����%�Wx`9H��9�4�_=ay��?�5���עl������ �d��Ϳ��.�:����B�a�'���3�'��8��x�"�J�*�JV{j���CT9�iaYڦTߌ�5__�
'Kp)a|�;��^�yXN�j��h P��l2�>ʹ&�����[6{Nۜrg�m�Ϳ�zp�w��yq��	�FfI���=Z�뻑��߯
z46���Q����\����+' Ζ�C2>m�B��S���1����w��:�q�����Váe�L�wV[E����]� Jg���E�[E�E4�/h�g_��5{�ԁ���V ���hX<�,^�%LZ`���Y�4�\�r����tA�
�9��XXY�N�G�	4��Z��K��Z8�e:�	:�(�_^�AF#+Ŗy�'�n���s����a_<�㒃@�@�v��O���w
|=�7ɠ%�#[Y�&�yړ�������i3	~BA��p?B�����}U��v�z^q?޼N6ӣT&�tU�[6���؀-JR�j���.��N���z�:y ���ѱ�t�XT�����&�`���;�Vx�M�Аfo��9y���ռ�"�/��"p�f�l}�Y����ws?L`Fn�M�F.v�:y��a;4A0��u^y�x�z����j�n����	�W�NƸ���w��
�d 
P�?|��~��ub�ؠ���M�K��,��'_hr���&��h�����:�Gl��SH�	o��L�l�
'��8�	����2��'	g���B�PIf��Oa���}��j_���R
b��W�C��L��q���q߉6v���n������םcG�������-��[�o"��G<�mo����{�J>��x���_�k�Z,�@��~��ޒE���E�{�DF�Y	�7�.��%-=�at��!�����iD$�z)|�-�h�/(�2 \d�Єx��-�(ݘ��n	TL0e�ǪUֹ�Q�N$/T�<ҥ���\�g)Dm���f1^�kڶG�`�c��`}�B$b�a�tS�B�5J���p���[�!�kw�_[J|�̯���3�-l34���.
e_��\)%�~Y�4O�a��`�	'o�V���3�8�;W��b$4na�.k���H��e�(-, ��t�gCh�檡�3Vbtw����=t��G��;�S���j��̗f۵�nB�NL��)9�V�Ru�s�1	Ky6NX�9>%�YD�=>n�Y����g�\�ޜ�T`c��
�Ik���-ru�w��$0C]��fD�mX� V��-�1 Ls7W����������-��]��CT��2��ľ�� �;��g��Y*�0W�	�\�l��o�S�ny������}#D����}ޑ:%���"2V��M,���;�.cEu��wI(*��Bh� @m���=��d��W�C)q��Qe�K�k��!�f�*~��VPQ�=�s��]�.oPp%΅��>�!����(�OS�
��X%u<�?{H��;�梥|�3�@Vϧ��йId�(ԫ~q����QW��|ͦe�v��%��
�9�m���9�|����<�?��v��g`�m�<t�_���#v�gb�77ǖ�P�o��p:�����w��ߠJ��-+aH����\�d����W���V���܎|"��h"������w�y-¶�0�Z3��o7�!��z��bԧb�~�FD�I���5v��JѲ({~({���5��| o�W2����3)��%�*����_6��̽�� P>��.~MB�ָ3�Ծ+D�Dg�"M��kʝ�A�U�<���A��ɋ���}h�]փ~wx�Ģ�GCӊL�i
Q&RQn"�~=^ߵ�yFZ�Ei�v��0�{�~F=M���I�v�7�ի�1�Dc��M_��F`Q�N�b$�B�-_�kƞLll��+���D���Ϫ�����՗~����b��f���թ��Z��zo���)�f�Zd-�&����c	K�C�~tü�Ԏ�_�p�<��B�JM�F8.F�"��A�AlG�Ub��=����9X�Q獾''�A&�{�t�x����ZBw�9���ek�rtf��9�%���×��<��+�o�V�H�y^��:�쫴d�� ]֥]��ڣ�~��I���>��64[a���,���ș[C��n-G�BT)'vІ���
���J�f)�,�gm�Ϲ�����)c+�vκ^�!C�!�"���=J����O�4����}�Q��p�vU�Q���2�������*�Cc�c??�m8n�}1��t�k��۫rŰ�J�D���6��ƪa����9���⦥D��|Jv�.�,4.���U�ȹ��vx����?�aW�z��1�Q�l+��[�veti����W�|8M)s@R��ǚ����'u��RC߷��m���os��)p�K9��~�Q�d裈�loV�����߯�G��T�J��G'�Ak-kw�}r�&,β{_��kO��\f�
������i��י깳�Eӑ,)�.��� ����07����:��t��e6FUx;"��g'_*ڤXr�ég��'�`�V��e��T2�_�����ȱ�ۢ��p�^J���]�|�+�[�o��6�jx��_���߂\��t�O��2�dU�g������g׌iϤ@1(D!8���+@����3x~��.����=��Ƽ��\PU���.u�n{���y��ja��
961����h��L�l�?��
���B���#�{�%z-X��?��؛gp�^�}l>W�N\�f�m�s���+Gˀ�T���^����nH+�EK��-K��w�<���R	�G���4��O�f�a��o�|�t��&�`��ʓ���t$<�|��~��
�J9�mt��>߸ޏ��܊�R�2]}���'�z�g�{�ok	U-��V �B0�1��t� �0Q 6Z'|���a,	̨��a�<�7U����O����S��\X��4�?iyW4�r�rP^�ğɨ��GB%��m.-��ﴳR�k$������-':r.%�~���$��Z_d0�`���t}� t>{�"�lr��[�q'�ZJ�G�@�s'�O����QA3޾AQ��BpK�:у�AN�35����#z�Գ���xb����M�\ٛ����� ��B=؟tN�B�ٓ��!�6�5��i�3���ޞ9�d�(�d!��?��3Ǣ��8���=�{�`������Q˛�}�Mb������}A���D����(�%����C�eh1�UԀ��a�g�$ƅ�'����	.���:�)��[%�� ��X>���r�k	���2i��&!��U�+"5g���$�Iț�.�:�&���)vθ��b0�׆�"N/N��[b�7	K�#�0ؼ��$��؂
�7�2�X?7��Z/cu�oDd=���r��r����K����x�5��8�n�wW����_�d̔D�_�y�.��v���)bl��!}���ޝ�5H�?�I
��,�ޟE�u��61���'��eZ��(��W��]��*tll�(�<|l�aq�㙽�!FޛI�s���)[��@�]ћ+MS��7	>t����/O�KS����62�)���g�P4Y��d�y�uVZuI���}�?��J״v��? �vo�B˟��)ۍ`�;X��)�� oJ�����Na�P+�}Y ��}e�5��YW��k����#}�nC����0����.��VŃ�~��OZ���O$G������F>�tб:'��È�)}���Q�>�3�

�NF�<�y������̓�=�P������F���H�g������s����s�X�����##c�dxdƖ�'!(� ���jzK+���
�BJ�����iF�Z���3�RzyfbY
n���I4�PO'�?��9�^{�ʁ�8�X58�+Z�K��챺����L�%�ݱY����n�
�3�� ]�a�����J���7��T��d��VW�i6'��H5�0�s�Y=|�/ȱ��F��(3xl!���]�����j��a0�l��r����U�Nh0�����@8$����k���Z������q�Mt�ә���xC��7�p�$���
���9ᵭ.�Hq�IU�I1� ׹'���oP"�n���{�6`(k ��ƛ��6-%��<�^���(��E�v�H� �x����V���A���5E�4Mg�(��ۜ���@�Z�@�0��B.8#��6�)=H�~*>���G���U�����0�Z��iƓ�ٌ��}y�*�B�Z&�D��41���5��E�ݘ
h�D%X�c'ЖZ}��1�ٌ}��^��0��M<V��F���Q�fL�땋�g���i1��c��1w��1�a�( �7�����K^P��"���X��]&��aut�V *"����%W��>�#I;�����Q;~T�f��ǘ�!���)��Zp���Ύ��t���� �> �\�.I]b%2$@u�/$.�x�4i�B��p�U�׺Iy??0�V�%�o�Ţ���f��w�2�,?��_�㊰� �6��=����6��1^@��gM���2`��09�tǕD��	�ٛ�fM�,��tN]ڲ�1᥈l�c!f���ʾ�%�"d�I�|��D���7ȣM�Sz�3Tՠ������͸*�1�P��g�>Ä�]8�VM儾8�=3~�Hw�Z��ze�RG�3ϳ�@vx7y�S8�{ni�i��}d�q��/�:xit���:�'�+�r���G�s���N����y�L�c��O���"�X�R�RaL՞:�&�'I����s$ײ9�N��AS���$w����
=p��������R`��J%�� �BӳX�l��e�|\��n�lj�_���XI����IM�eۄx8rJA�V��!`�t�Eo!1��%�gfa)��܀��͔H9$?��ժ�[�DJR�����<�E��������t�T�t*�V�䄇cB9�'7?lo��l9'��6k�@�dV	u.r�>�qsܣ����O��1�f'���M��mN7�E�3�"(<M��Df�X��r��-���:Ee_U�W�Wo���2v��M��)(�P��3C,R�k>��%�0����U�+:~,Z���C��e��s�DӶ�����Fh�5���g%S�)�������Gs���������8�&���t�A��/��<F%��7�f�L�~�ث@���.�F�袪5-N/S����u���ݓ���z	���&9rl#�K�Eg�Rec�N_�Q�t�˄����uH�.3i~�wGp�7^a}�~������\�����ٮ��ƇM�h��*�a7��!k�3��{�@�!E��k�����v�i�˘�C�=!1^C�ʈKU��`�<g�Ŀ#~��8�;���?�x�j�������'d턪.����d�j�ͣ:�u�B6�7��/#� 2���3Ir<' ��4�@��Q����d�ҹ�e,����өq��9�)�)u���ZhvB��1�`#)���U%6�aA�- ��:ǽ	� � e�8���]�}�ޭ'����H��L�.wY]�m���-����ڠU�Rŭ�?�-aMLT�V��:�*�~��R�&��;V���[������_տz#��/�u�o{%�a�VW���(M8z8câ�D���E�|c�V-�O��U��D`�n���;�J=��ǻl�8i"��JfK�0)��3�6�o�%����c�ެbN�P�#B�Q��Ds����|*T���ܜe[�/�f?�F@�㭮�:�&�y�撅��r���DN���i\E�Tz�3$�\�
���%���i��f�z�bV�Ȧ��_�[��:�������?�I	�0��ʡ��KX�m��i3Eq�������l����!���<}��|0f�Z��e����*��٢rX#ѱ�ru����:_˜���/w8r�~�ٿKu3�y9-�>����\���Dԭ�v��~�C��*rE���)�%�Z���&y���}�������q/a��x�W���7Ǌ���*�����>�.|7[WLً��Ι���u6�}��MG��Ğ�濖�tBfYL�Q;!N�Ew�ԕ�ն����g���i_�厴�豇}E��3�����ؾ����q2��fɼ�7|`��	)-ρ8�<��|�A�+;:���Rz�b������-m���e��ӥ�K@TB�
TeM��`l�̤<tB�^�5�XB��+H�l����<��r=x���~���]�DߔY�pK��^#�ªӰS���62WKe�=ݚ�L˗�ˢ�� �Z���9��x�h�K$Z��,.|n�c��\��~���s#�����d<E�=���>�݌ȴ��R|����ee1��"���o�o�/���E�!��^_�'�ѩ�o�����w�wJ�f��_���p�e������c���Z�}�ݗ��%�O^[L����-�XU��~�g��?σh}�ӈ&}Vacʳ��7E�[�d��{S�r��Z`�Q�oN	�PLfS/|@Վ�RC�(��*	d���բ�w���(�L#f��@�Đ�Ð�θDn�(�>�*�j��|�\�hH�%˧urj�ѫR��")���S04�tx���%�6����]!X���&�EA��c,p�.$o�0���If� �«+�L����q�q�픜
<T���@T�����}�w�sv!�jL_��c���F~�
�ю�y�oO�z&��-i���ЄV������G��,�Zl�[G�=�S���f�$�9��f0ZMs;�3��ȡ��k���cv�||T_qF|85�~ۡ��U��E3צ��;�t�����s�&m�S�4K7��T#RC(x��(+��{���3�;)�Q�p��<,�E��������
�J��^�;��8����gV:e\Zb��ۅ�D��刋��.���>�N��f��M۰�3��ϟ[�qA��f%ȇ��+�Q��i㣖���~��~{͢FTDg��%�-���c�=��,�)����d�7䋇�>[ܶg�~!¼3�è�X�x^�I�!6��e3�BI��o4������]��a%����V1�<%�U7	=�	8�|�q�~hn�LBu��"�P�zc�P�9x��_/+����5�s��'�m �G7UO�VoBCρ���N��V��ҭ[��㬽!G}$�<["o�o���s�̶Y�$)ŗ�DFN K`�� �!Ir��K�7\��ɜ�f���3��T��n��V��K��$x�e$��,Ot�k!,�W����/��/���|l()�=gx�B�ΠCV\6E����R�� ���)��s������+ׄ*-�V����M�˸�.����D�Mu���yp��w�{� Րx�5��İ`=�/+�$����f��c"7��2��L�Ҷ��v���%$�L�K��~�Nt�G@
e8.�9�9e��}�	E��&T�)xǅ�M���nB۴��?�mX�Qt0p����NEF�Wv8�I��T��v�=na.?��꤇�F��~\��8�B;H�ڿ�~�̂Cj�Q��i6�
���%�� npm���w�x����k)�-�k�_(퉂Kh�:����v͟0�B(���0���� �Z]%o�)�28�.ܡ��^�'8��u.>�T�S���]4.���@$P��������h�X�T��$�����B-�۪�lu��f���!A�z�~��I��>!�n"n ����S���@�-�o�����2��J��6i�u��UN�~ꙍ��$3׬,�[tZ�J4�5��_�O{L�湪�w�i��we+��7MO��ߐ���3���`z�O9N8b��u�v �k�bܶ�N     ���o�K� ��������g�    YZ