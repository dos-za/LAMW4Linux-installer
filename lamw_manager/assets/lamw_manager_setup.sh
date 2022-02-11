#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="124370347"
MD5="95195f2923e437bfd5cf3b6959bdc860"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26388"
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
	echo Date of packaging: Thu Feb 10 22:33:22 -03 2022
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
�7zXZ  �ִF !   �X���f�] �}��1Dd]����P�t�D��f0�>�9���H�ϵ �׬%$�b{�o����O�D�@�B�B��L�8�VQ!��ٙv�����5I�t�GV�o�$cۗv��f�|\�/<J%���t�-�w��nN;�H��7B����u��}���l֎א�V������!J�*/!ey�m�VTܯ�cq�TF`� 0�ɯg�/�9��v����3�8,��K�3}���$~׊���!`�6�b�]���\�l#v�1 �x����l]�*��4��_�r�=�K�>� &���m��$�)S�޼�ԙ ���PItB?A�á��}�N��W��WT���o#x�0)Vd��e����Rf�%P���V�P}����ŘY�6F߄W�
�P���	�Όն�	���E{e�2�����˩!��On+��X	�Xwu��s��E!�ݑV*W��m^L��F�i�o���q_�/m��SK���`�ܠ&@�����ͳ?HqK��^�Kk�=я9�I�"^��l�y�m�&��d5�8��<U�7�k�#�ۆ(/+�W��յ����{�u���nAI��LKվ�[IVI�r% QRC�`^q.c�=�����@�7!r���#}wJ������_�Gp*d!v\��qh�)C�=O�xL�&%��P�3N���;��n�2C�?�<�D�X�d5�ER���--��g��d��N���J����#<�Y�ߦ2R�^"漙�
xO[�ϯMn�?:�<�����b�MTUk�����9��64�fXW�`�C��j"p�/_��U��)�}���bC���y�߸�°(WZ���w�T<��t�Y����i*W��\y����*�,��!��S�Δ-�5_ZjO2N�3p�i��R	Fz����Hr�fii52F����?���]I�1�"Y��	))����<��:ǵA7Ǯ�|�U+-@Fw�tb�6����oV��,��&��8�%��)3>�����N�\Ӑ�뉓��<z��f:4PKt�K��AF��
���X�U�V��R|�oڈ���i�<e��]��������l���y�ԴO|5`>�?he��C�����oZ�Pf]�l�����sT�*�H������؉�B}^��8���J��L?�B�u�����G�� �7�B!@�ο��g��F�w9@�?+�U�4�m-�8(��f[�ȏ�}��qA��U_
� X$<:���-~?eC��7��0�c�g�Y$���S���8���fp�	2��w��sq�]��@��i�'Ҁ;�URs�kx�wB�TSL{̑LB +���p^�7��Il@#9\���G���^��v�������?ߓ�ޥ,I]�Z�aN�`��Kyo��3��U|�kxYp�4)|�>�͹i�.�0������1��㚲-k�!*�����7?�͗#��)_���#�xv14ĕ�
��#6��0#�N=ްĺH�z��ɏ˿��ؽ�a+�F���8��'�B�	*�� �����X��#/;hR�L!R�0�H����V"M��5�b@!��ǜ0;v����銩Nke��jݯ{���S���7���/��fuwJ*��F!�]�3K5_�0ŕ���dr~�S�,��R>ñ)UC	�Y��`#�
n� �} �flq�
'7��"U���$��P� i11�ـ׮���$�)�]n]u�j�$O���j����b5?���Th�j�A��*o"�)���d����S�-DXnA��v�!&-i0�c�	�:������'�KՖbc����TU��f�w8�l�@ɺ�
2ʉ�cB��i���h�BU��:�g8�6���[̪�C��:2��g�M�ߍB�7kM�M��R9���?�]m�4��?,���Ǭ|�~P\�2�iz�oN6JRz��A]}M����-he�#��&L��9���������Wf���V�Pu�)��d���:�I=�\õZ)��\#����4a���a��K<o��I����}�iZ4Fz;a�N
����EM5���
����O^/L�WL����:(,��Eb�͛�nO;B�穐`�][�؍�v.�b�ТO*XN>��9�k�u�@���I$q=!����	�6�@�I�����2#�=�Hb��J��砶���,����K!�j�v�8��2 �����T�ڡ��S�e���w�.�q8��?��)�hB#p��ɥ7��͠�w2+��guڹ���Y�i%���z�oDG@#�7`mX�5j��4�@��L\,�'V�$:���{�
���K�k8��g��?��~�{Q����_�i`L�q^c!ێ�=/ᖌ2W�f,���4e`\�h|�N�Y���>s�[�����TKp��A4Av�\j,��6p�1�����O��|r[ba�=Q���B��/?q2Z���v�`��D���� 5�&�f>���ԯ9`�i� �bP����m]Y#����4Y1���W��Kl5��-�)�n�gE�k/F��`�?G��J�zm�U��ӊ0;�1���J�4�t�O��X�ܿ~OcT֝ '��;�c�<��j��ؿ�1Y�d�%r؏�y�'[fC7|�g(j!�o�K��ͷM�2���g�$3{xn�FkQ�������<D|v�_�ޘm�2"7����œ���a��wW^��g�������-�s��u# �)V8F���MoVZ���I.e^���[�y?�m�Z�-̃B/X�U.��h�Y��_6�>>w n���%,�I�P�.=�E��ӄ������dTK9�ׁ���D�!q�t([C%h#t�fX~�1�Hk�{Wi�=p��8eH1�O�0]�b"�e�ٓ˃߱�
�ީ�a��J>�^��8g<4�͸��[ϕ1�pW���l�'�=��,'
��3&�	�����i*�����ۇ�Y;Ɠ~��{e�]Ұ#�!�i����Kߔ+���Ǳ�{�P���hj���M��?Dah ����[���ׯ|�<�Ie\/�b���m�?,�a&l�J��ٓ��	�h�� �7K�{t&|��|Wz��� 8�E�
D�T��1{%�Q��-¡qIv�!p}���.�+v��ջ�w�)��bXY���M��y�l��V�
�CQh%20�@�WPv���/�aw�h��2x��9��,�����P�5�Z�z��vи>���7���L�� "�-y�I�B5���|"<������7Q� �'7ե9&;�y���;��=�WV*��˭��&*:����:?xqo�0���L�F}F��΃�LPK�珸Q}ڣ2�H����yI�	y|��Bôd3I9 G'�1�ZF{����dpT�5�{��QA�2����	x�����p�A��Sy7+�&=t,Q �hd2�������n�פ!CuW|��(6��� q9ׁ�T!z�N�h���.�P�p���bZnm��E�}yL�[S�H�.��;�b�G(�!��S�~�!'��E�]��~���K����3��z� �� �¾��j�|��CQ-�4�5N������N��vz[��WH��TѵG^�����f�o^�_PğrB�U�r^�z�~�����2:!�n���V1��W��f0\C� ��;�Y=Xvr?����p��ŃV���.��s�F.�&��iɝ1�D�}��FGxnK�hr'� ���W�1��WV����'��^�=�g�m^3#��.z'?�O��y��4�}^1�R�����������d�*�*N��V	�a�M'��Oi5'�V�f�m�����J֏d~l��ӵ�\��W���� ���*K���~h2$K<���k�d����(�p�o�x����ZoL(�,ܔ����
E���m��P��a� s<�7�ϑ���b�<ƕ�{הUR/_�����R1X�=w�4�d�v��ا��jZG�B�ǎ�jz/��S:�
<�c�jC��	���F��
�G��]�g������p*��U�`Y?���+�d-8�F�j�j��1�z��X�����$;T�.�zԩq9s����^���"� C���[#D��H��D��()'�D/��;�ڢ���0��{R�p�/H��o�jɍk���"�8�꿶��K���o#A��c��\�� 8a(�ձ0*�F�~Ʊ;��qMgAr�,�v�A���!��'g�:��4����V�h��.��+l��n��*��i:ͦ+i�i7�#�x��%h�K=��)��������c���w	&Z�:Tfj�ܦ�KL�ＺpFS[ݣڟ��L.���$D��e�;#S+x�ݎkg�ϔL�oQ�MIKt�J�[�GԚ-o�M��v������!���v�3�@�\r;/�D���}�:-�b�+9�jaN7õp�G4�4i�BF&P/��j<����up��"��\zuj/��CD���1�/\Ǹ�k<IQG�W��B��e`{��[3�I�.M�"��;�<��A�<�n�z�q:㓎����_&2]��� ���r���n��Gm�5�}���	��x��j�53 �1�n��5��d�ƣ�Z�5�m|Ⱥ������q�]p�{�j�$�v`�ߔ� [��b��t8;AO_�Ւ���-�t��D�u��xy	6}��H��$-WP��f��D�� i5�hȴ���H� �SK�e��l����K߉��l�,�V��ߢ��wW1�>_IUD6�@�\�CӸ��S��H�R�X�IG<R��w-�&f��1���u�ȐZ	��Ns��I����L����9~U�J!q�k0�����zSuʔ��1�E7�RTU���;�X�{�K,I�꓁���qc2Wi���zѦ� ߓ��s�H-Q���O��OJ���q��mM@nȀ��7}�pw��6�7�#�A<�=��/�S���6:e����Bz�©nsf�༷):��DW��<��̼��BY|�ꄠq�ݸ��?���T�i�F�P��d�&5�xr��X������%Կ�Ӗh+�<�T/w^Sa��Ҫu4�V�;</>�B��0�#w"���p�m4���m�v�*+x_�y��-��A�^s�*ow�+�/�*N1y��g+�*�/D��+���8��O��}�G��<)~Ү��+ �� EjF�(6��(�Gxm�M:3���-&�1�F�ݟ��:��#cA�)��֮�j�t���S���X�Q6�lG��n��1�Rl��O�Fgb�E�fmJI�`�,�����4��g,
�KZv���W����E���j�9|�r� A�C�R��Ć�c���&�,���O��}a[��ΰ:�<Z�ׂ��95H(�Z=TX�ܼ�J ��U�m������7�"�G�ȁ?~H�3{������A �(�?�2d \z8�����A����[)�LTm����>L~�����D�b+{O��1Gf7��$�$zf�V:<���`��(,����2"3𻓓l�r����t:���hŝ�	�r�fm�u5f��}��_��&�K�_ǯ,��K��J��7(V�B���u�`E�>����o���Y��!]���N��h�f���������@KW�a蟓2�;A�`9B�~��S�2V��70{F\�8�����Ns��v%�&5V=�\""���b҂w��Fj�)��l�[��L?/r�j�7�����m�1���u�xJy����m�u����s��n�['�� ����{!yz�2p��ՠq>`qH�=3�ŕ�66T/w��&��4���H^����J���E�w�D���Y�B���Y6WY(�@�E�e:)�_��e�[7Ь���H���Z����ZӘ�;P�[��s�����HF����G�S�]V��b�,<J���F���TLB�W�GEz,���DKj�Ź��Z��p��Tm:��zk�$�t�Zim���kku�@s�dc�3Kc���x�8T�"8�hB8Y��j]�1��5ҩ�`O:>�N�
L���V�+H��U��̭���F�¦�J�f6�YL�^?�L��N7B�uL��<�=(;�S�8@ls��P(�9O�.=/��"�m�$o�o��A�bU_�^�(v�
�?W,�����n%����|�B�Oa��-b=n����-��_6�u�ف��39��� ��A�e�#
��E�{
�+#�,P�����.�oC�����C�6u4ͳ��j�7 �ъ�,�[��E�g�Z9yj����,i	S͆�ɓ�U���I�N�O༻�-���Zkh�d���H[��m��$����@%�6Z�,��<��|w\d3/���1���ES�#�ͪ/����#���ڦ[�J�U{T\������ه1�[��VA���M�~բ���� �_�
��DO�`�^;�^��	{-;Aqo9̴�	���{@����:���<ۧ�J+	�<�m�C�M�Bs�r}E��Ԕ�+M췫Ei������"��gLuIj��K�����8e
w���b-�%�7Cf?�ub�C}i�~/����.��0�ڃ}�o��&ͺ��<�V���H�c˞g"\Dl����C3H`:z�`Є֗r����<=����*��ص�4����wa�l�L��%����2wk�4],f@z9�����z�I���,/��4Wq��Pp��m�0p5�c4E�_}@E81Ūya������p.����6:����9�%�W���bڨ�m��R�D�� �i�{���sدq��_��_}��,*��!?p%��(����;�xX"��M�+��?���r�bN.)���1�~M���=�'�Ν	1f�1>��I{>̾~e��-�lŎ�4�$!?�%zmѓ����n��z�h�U�%BC��ʇ���FN�H�bK/Q���b�w�� �Ŀӑ���m*�*G �y��}��{���	�4�u�3��TXŗ*�.�{Ś���Bֵ�}���E[6�HP��Һ�/CZ1��7���a[BМ0���AW(ͩ�6�/���

���������x�G�zC
9ί�t��8�ʍ�[D݉#��GFx��;�w�0~єݨ^}@E�ʘ&��>#�R�0���|B���dOZf��Qs׳ ���
e!J3�c��Ǟ!�1B�-�a��.�m�"~���T����K
��_b[%�c�ygk��fP����]��C�|
\e߂���T��#��]r��R����c]��.�D.���7-�nP�II:,��bU�c�2�o}�!4͍��o�����m�O�vmx�B�Gf&���J
���oӾ�)GȔ<�,�]k�j����&�@����%5`� ��&v�^�Q\�)KIs��A���{7q7��ۅ�Jig-G����&@�����=a֧�S��Q�)m3k\-�ڂ-��4�.�*��m}�G�.��@)hB��M
%�DK�م���e���@�`�Ȁ�c��|R�j	�$�?[�lyf��x.?�8�j��`�d��(�ÑT�K,���0����A9m�t�ƛ���< ��l�Q{F��>)��#�9�e RUE\J9�e�o$�����'��a"��Ta���ˆ�p���psi��B��k������0�^�?n	�)l���!�a���W/^_,=��� >�؏{��n�;���pc���U9=(�^[�Á�c��7���]=�T�ڋ�:�%�ZQ,���'e�p0��K����P�@�E땘I;��I����r$1{��"�@��:*�)�P�
�#9��fQ�r���K� �ٵ�����xy�UyY���u��|�Ov�r Vk�����ŷlKO26�ͺv �M��x���<�/]q%u���1��x�FT	����V������	�SGQؚ�6r��)N��uV[�h�#��oZL���f�Ny��%:	R��Ra���)�
yӗxG6�Λ1�J�����H���o�fڋ�N���fZQ��+�n�V�#�Ā�h��'.�C�]^�n����U�6'��N���o}e�2�����q)c�͘箨^;�v�)���sH+�YmdgK��������'�C柄\�nV���o�ԓ��^9j���#��ֲU�[�W��EJf�3.�A@[Q�t<5�#����V�t��Fv9��񸊎��aL�vAF/�	����{z��H���fB�q)+Y%i�x����A���
���I)q�ȔcUT�p��*���h��	6S<��d7�3��)��.e$,�Ԥ
ށ�њ�+�����N�Z���c��¾��j�)��r� ��0�PMJ���H6�-����:���z����ca��p�0~����v��G�Z	��{}���A�P��r�A�ȯZ�6�v'�4�p�r�\	��KE2��*ä����(D�Qwi����	F��r����@�Ib~�t�'���m�e��r �Q�9�e���a��5�4p;�Ao�f�l�f^ ����IL��A�c����Q�2�������@�=t��]%���ݶ�=�d�_�/���uqrX#��%�v�K�;��]�3��$6�FZ�F�D��:V�y�ך�^	@n����7f��i��ZY`'���Q��a�oGą�ZZH�T�@��M��(i�B�䏋dq.�Lrކ�D^I��AL�k]5�aD���?�A�b9R(	W�z\��G�`HR~�$�k���v@G�ŧ�B�}��we��ޮhK�C�����8�!z˟�T��T1��q=�SU�?�C]�.ri�@w&�|2�C�uȮˀ:$�`S|�oI2��I�~��9���d}i�grv��s��p�|���3Ii'�Nz �����O־��D(L��:����j>��+
8��]/�FBG�~����v� �H��/@_���:r\d�]�����3�8��1�i��VJ����d7ў�)Z�x�?�ޓ��S��u]��͓�l�d�T8�|̇��~P1��`f��V�A��z��*�Ү&�a�Iy3t�L�poE
cM^ ��_|�k�xL<1�-�on�ͼ5B��̳͝%�.�u��L��{8�9"AL��:W���W�S��}���R��b�}�-0Կ�5�J���"��~-�@8�-�'�m3}�U'�2���y[�΋�l�J����%Nt"����@�7�7g��p��rv�\��w�H�a���|�w��X�x���J �ɠ�0���Q���� 嵓���OO������'����ѓ��Ye�.O�/s$� kny��<�(
�U����+���Y]$��Ψ�i��Rrܞ����G"Olf�5�u
hh����]/3g����YQ���9�&���V����:p|��3򻞌�yK=��Y^O���˃��ob��Cj4�
��o�J59
Q�\[��P9"�L�=�]q�cZ��dG�Ո5j��KKe�++�������6 sb+�����xO`� @�I��%b� �*���vN�^�@o>Jk�E�����K�M�w=�����kf2	e(�r����u�yE���
����Aզ�!�?��O�!B�r�I#]�`��p�/���Ɋ,����A�KG.��v���
UW����IēoB��E�����Q4�J���������I�yV#�V!�r�t�S����k!ҥ,~�w>����m�'���m'�4����\�]�ff8 �Ø#6���1m �z�3ޒ�o$�OI�B�'rҒ����]��˚�!D���ei.��W�H{+n��6?���0�`f
��.*KeZ(��}ݬ`�:�^
$J&rZ��oT�����g�~�_F�K"�:Ll��@&�L�1R|��� o)�.�3V@RF��X�)�,�O�z�"m�"Ǘ^��r����0��o�2q$-��M�	�K�g��ז��u�� N�r��.��ec���+?k
ꇇ�8ߓ]mgW����{A�#%B���)�W�b)�"�QPfSÜd��@�c@US��u�W��׎,�#������;ۮ����	��FG�CW�x�|�84��-�v�����b�U/(-�$��q�����W��o@��G(��6��:3�r|�\�J�*��)ȁ��!�����'��7��Q,2�׭��b�����f�<�!g65��v�������9�_Ax�1A��Q��� {x�����Q���R������s%���L�T�<�h��>;߬K$5W,n Y]�o�:t���-���,�����llt7�/I��g�'�i+�_�7u�iS�pq�S׮�s�nŲ^܌{���kT㊝�h��gvP�!S؆d�pդk��-�i��N_��U*��*�A���� In<������O�U�#��F�*�f"���Q!��өe��:���5b\g1{�[�Ƣ�^r����F���9���_�)A1B�);󳠈[ɓ���� �E@���#��Kp�^\%��[�BIj�������	�Ä�S]e�n�D:�)���+0m�}���	�rQ܃[�j�cQP�M�L���Pq]9e0ZC�=:e�6�ؖ��Yf���'i�\W��T���v�~m��?+��R۽-�W1!8%��S�hXsV�B2Rٔh�Ȍ�����.�K�G�ԏ�:7���D�"!�nS0�H�!��dA�W��6v3.���\�g\C���nT��]���3�l���A�7���c�Y���g�@r �,ެ�ӽ�B�� q�e�7���^�3Yc�[�7+� 	0�����������M�֡m�g��t��?���1�N����Q�)���h�{	���w�S�h`d>�,��S��	 ݆K� gj`��p:��/%�<���u������7��7=U)��v(��q-�L�/�>���Q�x�s?t*����^Ѷ>��(���5U�?�$�@��
WFכ�qTnB*Mr�N�t��;N�& _,�yn�*8i�W	�7S��H��ؘ����(��S�iI�e�� �6������] C��{�1��A�8�XT��q�'ͮ,�!Ia*�>���c5%xN�K��<e�YQ�/O��I�↷m���N�?�"7���3��RE���h8�u��N�������iJ޲v��p��ɫH���' 6�@$���[&� .�p���. 3���:��zoE��_��c4\M������������)�u6�4Ԅ]ʿD�㩮y��-8�m$V�C�T3Նǲ�+襶d�S6�%+��0�ۋka���qN��\��u8��\V��8cO�[<?��x���&�7��յ���E]�u�2��AV��Gn5����{R.�溩�<�;�ͲFƺ�����Vޥ%��P��r\�/�r��jL�_��A�˅�'���q/w��6s�"������j;���74ܻ�{%���U"��U]p�o�^r��M�c�F�����=F�8�(�&1 8�u�'���[���Q�6s�K��̰�f�«�[(ͣm�5E�5גNq@4�R�J�r~�3)��𹕠l�L��'�H�Z�_n0'�*L�������V�m�KG���{��:�V���o�Q�"N�w�<^K���k�D�y�4�&�t�V��j����T}%��.�3~a���|>����Wf�w!˵jYC}#Y$��)]�ժ�Ʒ�{�FX�؋焇�X���N����(��Fd������%��c��b�f�1%��o@��?8��OjK3{�% J,��Ik�9���]G��==�y��k��S�ʇ�Ү���l��BK�u�h��t ���K&2aǽ���>��O�#�qvÇL��JR���KM_^0�X{w��/�Ur
"���x�A�X��?�~�c\� ���d���_Ғ���/bǘ;8нx!�H�.�����
m��{��*4��ņCw�п�c���0�^�ӫ���=� �Q���4��L�5��ws��"Qdq�c��]����<c|�E8ן��^9�&��sv���ֳG����
�'�-�����
�������[����"�c�V�X.�r����d⳴+;<d��F����żw�SC:��Qv����g���cJ8m���Zef�~5H�M�����s���ڝAw�ʊ���ڄc���U{f��מ㢙;��	��i��� j�w��r��1����?�J���M����r�n��S���ڎ4�@Щ��V���;Dt��$��|��t]h���}n��a��:;�>j���<`�ӦrZ5?�	��������v�V��_��A��������� h~���0�}�~�]St��|FMI��s�U�,s"�{/�]KtuZ��QG��H\A�w���MR!_��X�Cw}��	+}���8Ԩ�(�s����?�a�*d��I��-$�2H�А[����I\BE��}��\�=*c����?����%��I$UN�CjZ_�=UJ�����I�C&32��+�;�O#�D��f�h1�ۿ�mw@�v��iI.��7�̟,�zE���g{E�:��Fݴ5=u�f�.����˦�?)�KH�������㿷齩e~Wr���Wcm����o����)�(�|��Lp7I���S�]���|����.��K�HI�@��F�V�<�P[���F��C!�� g����g�V�A@��"w0��˓%)"NyR&�hK�?���-񮟏��@��δpe��|{R�^�c�cd��I��O�N����r+Y�$B����K�g�5ۑ��M�Bf%t�u�	3��T���6���㌉��"��51�O5U�o��5��}�T
�Ӈ�{�H��R�N0�"KzyM� '|�S)�&��?���	��r/T�R����Y�iG0[�M휓r��-6������i� �~�8Զ�mn���]��rH^�]��]w�Nk@p�u~�He��c��0Mv�� ���F�^�87K���Hd9�� ��Yڅ��c�z�3�����8<h�z��2jF��Yn�KH�7���n�@�l|L��T���w�B	�?�Z���TH)�)�㾹������+nl��us�8�sV�R���>�Ny4Z�p*�-����î!�P����<�޼~ʓ�a�#��)B��'{��ں���`�MvO�6�#�"�!��A���c��X͞/cG�f��y(Y��X��w{#W��r��Ќ�Ĳ�aK�4�!CnB����N�����[e��良"� X�߸�l-��9��ؕ����P������ъ���`Q����.��zzx��&h~���Zf������W��(�*<	���� h�1���BF)[\q��Z�;>�c�)Tj�+<�N�Ⱦ���F�!V�t�G�&C-�����TJ+.^�0�x�Ex|��ZWO�g�?���S��􍟜�j� ����70KI��;v�E��N� a�M��{F�YȄB�N{j���p�����@����X�iѧF_����@ܩC<'_�<���jhW��?�X��}��H�>��Q)��8,2�>�a7BoU$'����2�E�ג|^8��I^��m��+#a ���*��Z�nӸBG������*���X}�օQ����F��h���;���?S���Mt���d-Î�O��C@���m٥m	�i�NC� 3��}�E|�Fq�ڗ�A��Ч2��V+���|�4���c����(��l����������B�ib���n�S���I���s0��O��S�t]q�RE������@k��=t�PP���g�j������.z�̠��:�H�U��[���(u�9ꕝ��x:�Gwڝ�}���{(`Z�a�ɝ@�ð��O7�0�4ؿ��]�\
�ݿH�����}��������*���^����ɮ՟���wi��C�]�(-�<����� ����H_H��gU�������^ص��b���֔����9�(W�Dʒ�(U��9nߋ���B�cPpp���͢1똓��#x���;Nܪ�{��1��Z������kU��	�)��F "/
�{�x���:ԙJK� ?��w��:o�y��R��������E�ƌ��ؗ8z��<�i�o>��b�e�_��D�\�V���J_�.w7�p�TEj)�M1�yY����WlM����Z��e���2��+�6v�wjp8��c��E	��
��=�f�0���z#���N�����{T2��&�J~I��rbS3�6������7�5c-�&|T�Ê(�\{��e�C�&� 4����9������fw�Y�:����j3�j��Y+�6a}�UH�%�t��/�ڎm�G����|~�Yh��mZ��:{�O{�A���c/�V%z�(��_Iɭ]{��(Ó��K8�����:�|��C�������YK�9���ջ������&C�GS*l��y΄������+��Ȋ uI��#����^+�g6#�Z�r���A6%DIt>6Yf:_�p@�B?�����"[��)Rޜm���C�gO�mm�Ko�����	��������d��-j���=� h
�����~�
�f~I�w�?�J���Z4m	(�ڙm���I;��LQ�rP�VO�X��|jۛ� ��6���p��須���d�s[�"�%w*2�m)����;)�fB�(h���C�/�F�~�m���(F��'P�7�:��밯��i��Ğ*h���cT��f�!�}wW��R
������\��KYO+�	AU?ET?�:���j/���S��<b*uw�x+���Q2�B����������tf���A��3z��y�@=R
@:\=9ռ�,X�t�t���O�(卛?m�W{�dN��� 3Z���fr@6�f���Tzp`��U����y�}O���O��f����o ����0]���ן�PVx�\�\xb%�7�<��o �6XP]�[x����Ψ���ou�J@_��O$8����XD��C%�X F��2ǁuYl&~�l�6HV)]y�2�s�a'Xp���:�N�^)��e��6H{^)��d�Gפ-.:oKU��7��)�)lLM�՝�=p��j���h�	2U���m�z��k�n]�֥Z�Xё���Y�Y�Z>�TCB��ý4��o2!�U�u��G��X��S����U�� M�}����2^+��^Yz2��_�T
���˩m�X�WU�StLqol��|��G��boRp�Vv�l�b�f��l@�}t���������΄Nؠ��3��O?�vS���
����G�佻^Uh����;UM�Gy��F]��0S��E�b�{�Xߑ��lۿ{2��1�O��>�2��ZZRy~ A2O���MI�Oy�l#H"��؃|��D��vq��n�l_�xM���5�I�>�&��s/��i������@��߄��.+R���I���Frȃ.�Pc�y���K5�P�5��$�b��/_��Ђ���oj&l���R)AVl�����d0�|#�d����%zz�6�Ò��<I���c��7��7����R�$������|F
�x7B.���´� 8#[?u���̪�F�z�5��î������/>PVpm�ȩ��`/��T$�2t&��
9k#b��3;��M�BK�FN4�6u,�Ը���߅�$�3��H�m�IqQD�1�J	�I�]^�2�v�ޫ5�	�zN;�z#����˂�_�?���	Z��ZԷKQ�o%�l(Syg�������k��>vy���:��i���s����X]�#.C�Km������������Z}5p��'�⩿j�=Ե�R{�s$�oc>䊴�_1�.��� 6a����l#�!S�������
A�}y��F:��Q�a^���@�m�B�ܛHD���=�b�H�g�;RfJ�Ě�3�^�ZF���I͜P7�A�@RG��
�=��>1���R�Z�&�����N�%��1�F�U#H1*��
�<�6��Gb��	�f ObRS�:�6��<K�B�m����j�ݒ��F>Ƚ�+�0VgPQ��2���o�	�ŧeMp��_P1=�����'ևG��{�k	���d	���ĂP�KǑ[os����*E'R��Z�Rd5<���h՝#싸��Sp���R��g�V�q�p{0�ʳ$�P�I�� m�#�Q9�^Å�a�Z�i�z���*~�C��jg!� ��j���
F� �E�ːZ��/"2��C��W �"�/,��K�胥�8Mo8+����/���"{�u��H7�����,���,��LJǜzΠ�<K~mUT?��}��s���5HQqtI:��>�Cd��7�!�!�古G���`�V!�Y<��`�6�Yy	a.g��{E���h͆��jJ���t5�ۇ>/h>L7���\2;�^G	�
֮ũ�T����S��_�<�J:ː��RM�vijٕ[?��Г�g��_����=�J��+�'{R�4����$̟�9���?``�+��R�P��8�U	,��`A��7H��:3��(?�����U(����|:^��T,Zt`�3�/X�t~�)�*Vi7q�EcƧ��3`6�1&�X��v�d��-���x��@��OS�#��5&4�1�"�Z��1����2K�/!(9��xc>	2�0��j|;��{��	� ���?A��]x3�2��#D;���ڟ�� ���o|�yչ�}�[�d��~�AHobG�s�+�w��$.���X���7�� z.��f�����5c�%�Z�rE,E�hu�M;���>�*�{t��'�Ș+��G����N�����V�#|g��̃�-���/*:������t؋B�D�&�)�f�y%���I��&1C"�����c@�%�<#�EE�������k'�%��6��:�Dkl�6�e���hEM3����8��p�^��� 6�]����i)+����Gq�'lZ�����`�c��6_j��茔����ӏ�4�!���6����W6�����WO��3�a��N���p�9��̃��Ƿ��d ]�E�wx���ҫd�e�< ���umz��t�,���{ ���ݲ�E�G)�qH�Z�*���/qȕ-��w�vNęy��
�]XV�>�H��zcN��1�J�DaCw7�V�v����w`�7���d�B����������8���sBכY�~,g��
I����'g��L�A����D߄���b��������W�D���!�4z�^�l��  #9����diƾ��5[O����»�PI�D{�f�i�K���/%|�!�[J;j�!�c�
�	�G/s�E�R�ako8 ���䮸�9\�]��=)q���)�75��d9�@��������?��%�x�s��`\(��&}F�������6��S���l-N笣Ά�'YO�h�Q�"�'��4}��$yH��z�Y�1��#�I��"�?�̓y��{U�>��� �͆y�0���s�5��A��5�Vڦ(����_z_֧	C_;��=Y�<��l�>�D���h&0Ue:"�6M쟸��A��p��E�X���e9��������h����<�`n�K4���$�a��R�.���<�I�LD~�hGХx��6�������+4��R�VJ�>�X�6n�Pנ=���la�NX'o��d�uL�" 6a��a�9`�M�l΄��aI��������,�dNe��Q�+�	�&�K�澜@�����;�6�M-.�B���G"e���]`�64�J6���]��;��4,�?y1�N�M�EŒ��M���6���=]^���W��I���א�D���S��զPߙ��
t`�zr���^|/�ۅMtaTzF�}ݔXj�f��i(��p�:^`Z�7�<�䨎RL+ݯ�:&�T�66|��w/g0�;�Qb�g���`���� �u&�����.b�l!Nc,�nʍ�@^�3�b>B뙢 ��y��p#�eJ���O�q���2��b������©8mB[O`���o�O:��_�1�o�v-�|�V�B�2-�YO�R	�{/A�0$��A���	��½����a��2� ������c����H�wȾcU��_-�I�˯o��izY-��Y!OU��xU.z��1�������ȶ�L�������Έ�@txZ�Emw�C���A�[��~R�|�н��\�!��O~�:
8���m��rל�HH@^�3������϶UDK�gZ��T��+�a%��ѥ��I�qˠ�UkF���*�O	i;�5@��m�e��%NI>@^u˽׼��Dr��V�&��#�+tƩw�7��2����$v9i� ��K?Z�5��`�m&��ƼL,�7B�����?���\Y.��I��|�O"z��ӂ�CSb��2K�2bIJ�Az��_������*�{T�ex�c_�<��;E���NV�?�r�3��=7�Xx��La���q�x�d�S۪��z�uV��ǿ�w�^O����)	H��.�����x(�$:z���,L�����z�^2�Z�k(TI�M���Q+6��>��q�=,�ٽ���LV�*؇�������H�J.)�8F��=y���m�p��P��%�`ϖ�cz����_��������N�Ѿߵ�qvk�؁�l�㇊[jd����k�Y�JQ��8ʲ�C蒀,#�D� ���'���!�'p��-�_ϩ}h�)`�V���c��dy��NC?P��z�U�*Y}���o�� ����X�
����Z��|4�r���n��h?8��}F�Qq���?-��o9�Ji6�5տfB�WޭW�E�ZX�8�M^��G+d]����Pn�Z �%aRbٞ���c���_w�7��Z����#x�Y�b;��8�����ˡx,���s�Õ�˩�r%E�Aܭ�Mn�"=�9��٘Q�@�|r�*��![����}��Q���Ѫ?��y*��k0Ge"�[�p�j�<����"{����|@W_�D�R�N8K���q���3zw]�4�o�7 �!ݑQUl���c��s��R��T�:�3��EMg����*فA��S!���>�>�&^n3UMdL�؜ض�O����S��X���V���E�|���e��x���2�D�o>3j�V����=ۻ�<�ߞۖѯ����>G�(n�
�]��;R$�tD��lm����ːqi�t�@^ǆ$c�t�"Z��� @�8�6���O2��(��j�b���M�5g���\{B���uN�v����@�c��#���R��h�N����AO6z.0W[�qJ?6�L��>�LXg}:dP!!K���~�TNaژ/�D���zv�'�!��O�6�Z@O��Qk�U$8��k��=�o�ן����/�����Y��߂_<��H����{	��"#P�l,�>%��% ]9�`�2��k&ߟ��_�r؁p�X���P_�*4.s���0B���l <���1�3���pߋ�⮳-�F�f����z�1�\D�?Uk�4�9]Z�ə�k��|��¸��lK��a�K�rX�wy��vJ���-r�e� ��0b�
�/����{�&�n�;�oZ�wN��E��� L�
%	����X�7F<�uSz�o?���L�T�_�BE�#C1^A����R� ������{ a^���K1�@4�B!xa��υ����×�s�'��W��|��@�R�y�*�k�i������?����yz���Ϙ��W�wgG��;n.�L��;|@'���6�	�x�2b��Oȇ���Y�h�	n��h3v�i{��p=���K�O��p��q�\@����S�����א���Un5``��`bs"y��P������Ty!�3�SY.�=F��X��{v2d�hu"��6�`ɻX��s?y٥d��t-0x+��y"�]�x(U����,�4$��o�t"3�Y�,H��ϛ!��˽�Z��A�A���ZKpR���k�M=cV�Ҧ�0��I�A֛�O��K������z�@��'��2����:˝N^�E7	FЉq���dNe��6S�1�EC˷�M��^��x�����IP�m�Y���]���!����O��U�F�5,}ed�j���	�D�3�y=m�u���;���i��?��Ҏ���D��+�V�Akʆg���41A��,��H�>x-���G��?=.�R��o�7��|�
>�L&�i�hs���o?�ۛ�,BWɌ2�o?�2)2�}4�&CĬ�n���WԨ��zڇ-�C��R�D��2,���N ^��׀�('��B	1�R�~�޿�oRc�rX3ܙ�[�����UA}@���oN;���D��
��c��ɇ^l�
^�;�9~�e���{�ob��6)�#�V���٣�6�#���P˥�����#�\��k� �:�̼�0fѪD�v�Q��(/?��K}�0��0��2$���$vn(C51�Υ&��jt���i��n�|b�B:y6�q<�7H'Ya/3R*P��]�=گ|!�4\=X��s�ۇI����Mˎ�����b���*(��&��|H�u��q�Lc�HQjq���0�{,����^{�pH�O`,������p���^�L$ZK���by�e����m1�A6�}r˚�g~m�w����i.�̖��=�)�L7��X%ڝ�#�U'�nWF�,>_S����~D�cl��7�a)������䒉������"���xC����l�bFz_�M>kADcQ&�4��}=�N�K|�a�ҝX��2/�)EYLtS�D�|fKE9��Oc�Ȥ�`�$w�Ϡk`�����M48D�`�A������N�.�{h���V�i���{W�躶�R˘��D��E<�mh'�Y��>�w��u�H�4}R}Kv���`��s1J6CC-Ӏ�%]����A��V�i�� 1�z3C�v�����<w�H	D[�H"8�bH��O�C�L�Ë'�ޘ�CHD�L�bD�;J�����,�����}���W�p>~B�ER�:p��ޤLɌ��%w��	f*���&s@��e���r5&����a;#�!r9	����\!�F Đ�v�ǰ3Wf^~Ġ9�� ����a<%��:�#��9�L�WL�,�gd��	f��T۫k9�U�6���=�ã��������299r�{QyY��X��a�_W�}wk�?/.6M�(^�ae�o���l:։�����&p���7Ä@����Ϛ*�15asi t�I�(�(�xx��I��-�rưu#�f�}:��I��f�,]�~��UL�-���+�8�EuĨp*h�6�A[}���D����?��T�*;�x�}`�.�c��`��eZ�Eo$�$R�|t��\�at3#VC7l�B
l�E�g���a7x�a()�6X���Ϫ�?�'�>��?fՃ�'�^-Je�9�����^(�7/����P�nB������5P�Y:���E3TӪ�C�����J�.�%��7�Y��f`�P��<�2!��O����~_��4�q]��U�J�-�n"*�|&۳��̅��kD�|l��Q����!:�z^X��f�7��b�@�Wl��b�M����2nd� �����@��y��n^�ᑅ� )^� �_�����sr��CV)��o�`����!�)c�"�h-�!5��&&�A���k.?������㮗��~�*^{ঢ়ؘ���H}�F�x
[Y�&�ټDҪYc<q�+�wؾ�{3F�
2���~K�O�4��z�&�-�Ѧ�b2	�����oH��2�� F}��o���_�����]��ƨ0�9��4�w<U�Q�jx��φ9���D�8"FuG�b"�� ��~N�g) �I����E0c�f��8d4V���_����,�c�ѝ��h)n�S]�S��h�W�������#�/c�pFSfv8�ֵ���H��3X�z���fJ�E�fi��K�u��i�'P)��z�&�t-�ʬ֊��*���0C0��w�3�͚%���A��y+O���o1��V~��jkI;o���|��%�"5�)�e�����x��glݯ�ۯ�F�1�� ���B�#�գ3�Y�rOן�3���G.?k� ��N2k��.w�����m�hLImz�Ⱦj���b��C�&4�Б����E�@<��1�8���|z��~��l*[�i#�0�9v�>?ҎV/L q]+Kd�Wҧ�yy�Ih(�U�����
���	����b��x=3��v,�
�������]M�Uڢ���0��Z��5ޚ���"=H���4�d�7��,��AQn��B�[9�Ȝ�'��o�^j��ف!��.���OGD@��R�I&��T)���:�Ý�ϳe��/��\Q�/ <���?���x�"�����%���B�Q3�%r�G�?��}�4�`��9H��z�V����(d,��̜]��%t#�O�����R�cW��о#��\0]X�h7O��T������BH�<<T9ߟ̢�Ū�����BvX��:{gkc�f����f�M��U�\S��;�����7t�1\B�ц�����ح��5�آ���c� ��� d����Y|�+4n��(��:�a����"�]�W��G����R}k��~UIi�bf�G�'�~*���%^b~% 1�v���O�������0i�9�b磘��eZ�-�}Lt/R��1���>a%���N�7t�����f2k�8˛��L�wKڔ0ePm�����"C���}��pǩ��Z>�ۋ��T"߳[b��ƕY�w���=�B�g�$�Ȁ�}r�[���!!
������8}�"7~BAZ�bYe�p��r��A6��2#���/�T>��ԋ����(�-����>}V��%��'����{u��A2���Jk7�C�hd��^���?��qf������a5�4�|Y�_�@ �
4zGɑYvT+)t`SX�.���#R��-W��Γ��GUߧ|���}Ĉ�x���ռh@-�m(���<)�<n�e�ar������-���WT��Q��㥜r��%�Gu^�)���m��[U��R�T�E=�~;�$����Ȑ�'"�ࡡ��B��v��|����G���D\�f(����u\�� ����mͨ���d���r�.���T���@duj�Mq�7�B>��_^�o����>ѵ�C�� 
ˆ��3���v��t�~��&]�3P����;�^�L�@��s���=�C{��bG��1����ʍa)锆Kg�;Pהo�����7�FU�T/�շ-)������xh���V�~��X�R<�*��KI@���s�f08�1������_�w�"�
�З��Y��^��O��H��8<��o�D���:C[&��N��/nw��^���%�BP5,�d���!�����0��&��i��J�]�?�z3[\�J�^���@{YNY]�cJ�
<2?>x
�������:A���J#�ō�mX�pK��3�U6g�)I�Ӛk�R#��'<kj'��Rm��1����l�;���ɔN8�z5������	/$R�P2��\BRl[�R���Y x�
Β��0q��n�]-ӿ��W�f��>����:��(�r�<�{��`g-4���jxE������!]�^��]�hg�}��T��h�Ǳ�H�~>�����!��M�4�4`�b�|�,��)���iB��q#�����x��-{�Yx1��::'i�X��Ӱ�j:KO?CX�ҍ�;�Y
����!��q^�J4��QhY���S��i/���ƜGr5+����c��;}�I��Pp����,V�� �9Sa\~P�ѷ�8�0Z!*ݢ��,�ϝ��g���jY+��Gj�2Qj j�=)f��0}IXS��\�R�]&��
Uh��Z����hC6�'�~{Ѱ�n�4X��R'-�����v\�p�}�52��ŹP,��ş�ē�4����Q� B�'N���턂�=e}Bno�Y�K�]uϮ-p��s)U�'�B_^},yo� 	s=<Y/��VOX�_��XS���
dA3ZocY�ԗ�Zj�B��+e��4pƅ��Y��9���Ϗ�����I��Ցd}E�Z-HF;4+��3��XO�N����l*8!(�4e�j���ڎ�n�)*ɠܤ����L�f�3�Q�11�]��������p��g��C_�G�Y�D���?HN�Pu�>�܋"�3��z���X[	�t�ҍ�8.*Բz���r�L�n�W(J��<i*��s�ި������F5M.���f��35m�����C�
�E�Ŗ��4��#}~�~�`S#:%�0��O�|?��ĕ}l�^l�s�C4-�w"�c�?5�c�lJ��"���d�Qa@�ݣ�	L�]Q��+���!�{i8 ����w`L�nހF}-�NЂ!�%/�1���v����w���X�TG��� �H#��i���.Ɗ|;�t�r��^�x�vt?�i�~����,&���N����M��5���MO'��{�
O�@e�=�ý�0L���aEI�Id,cV�}vDE�mW�V�gv+1�f>�n��7�:D)�O�痖�͝etˮá���$5��Xt��ؖB�?;���jtI?��LHl��n�Ґ��.,��Z��J���3��O��r!]Y{a���yw�8�%i�^�$���k۞W�f�u���O+�`�(�X����"f���NR}8�*�8�
A���kKN'«�<�7�^���e���,D��{���K������9K�N�K�ĝ�n�_��þ�m�,�fA'�z�/yx�1����;�v��H��x�f��+z:lq���<�@R���dR��a���}�'.�*cf/ϒ�Hro�o&4&RT!�_[�"�VKa���,�t S�n�z��;�y���ƱL59�pa����e��Y��X�G	(�f-˄-���զ�.<[��K&mz$����`��;�:(��6��w�+� �;XZ�r���dW:W�K�l�8+�r\�Oa_!Ѭ���{gT,1k�f�v�A��^�I0����,�Q�<��<<�~ߘ�S�b4�C2"�!�?��"���!���4w�0(�38��<o���O�9>�"8�Q��(JX��%�$�R��6��*�98�f?��r�r����̫풟�f��ǚ]�H�>,���<4�^�P�G�64�闊G�=�����7�u[/��7�v8DP���=��{��=C]��o�d��i��`--d���([�$K�޻��`��D?���j���l �V$!�9�0Ձ)�ю]��شU z��g8��y�@�C���̞�^,���&E@t��t�R8p�s�B(������u:Ev��|ҹ�Dp��!��A�U��M曊��`��^�Z��8��:�tZ��p��l�z3
���?�L���|B�b%V�-�ZP�r7�[}.�k��~�
ajLa�	-�e��0\a��E"�K�����ǁ|H��i�����qvIk�,��oMfd��2E}��m�<ʓ���j�n:��7��1��b��+�?Y*�7�~N�N���� hH�4O���P�0̈�*S�R?��|���}��.�XJ�^@^e�w�P�c�}ye#F�h� t��8�����)V.B1h?@��x�?��߮.��A�*ͤ���>�dL�G)��̘֜����� ��`�H��q���Q"rM����+��o=ZR���u<�dOy�\�S��m��؀�$��*5K��g]pp������>�XuE۽�܄�o�	�� Aa�C���(sb6��NV+��<��#���\O�>���p8�U�)�9��l�&�:M��!_��gpOa��Q����|�a��B�y\6K��I���~�P�|��f�٤&c�3��ja��8�ϱ�P-dWI	�Ґ|v�j���=��>a��z� v��]=_+;��CTe����6&+o�v�خjx#����#?y�rd�(j�O��cX�Q@P��23'3�_�sc�f   sb����i� �������ر�g�    YZ