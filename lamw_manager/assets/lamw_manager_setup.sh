#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1427386955"
MD5="6d76c2a1d051172727659953aa1b7151"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Wed Jan 26 20:37:29 -03 2022
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
�7zXZ  �ִF !   �X���e[] �}��1Dd]����P�t�F����T�VK�BX�8(Lo�汀b e~��;��=y`>�m��O�6Xjn�T�.�j_K�&�7����￻"�IB|h�݄y8�xO#@�L�Z5����vc���ʘq�񏏔�<g��o�	��:���ʞ*7����V�� �7"14g�X���&N}>���l��R���q!s�M�r2KA�E����\G����R�&�m����2%{o'��y�&m���:͔�^�����tF���ًUG�oJ����" ���w�$%���F���H&z��	��V�i��c��m���pAi�*݀#�%�t��8n/�	�����ЧW[z����.t�-��;U�Źk��<��*ٸp1M�W��_A�)o�4dYV(3��2&��5�Q;��x��4���,�o!�t|5�	�,��Z�bb��]+J�WE����y�=Z]�Ɩ�QgY`��/0�%�\�60í�dk6.W�A��T�hM�{^䁮��jd�8S}�v(���j���=FhI������t3x�$Mv�Kt�}�9�X�DAA��#-5.0uA�ӷ���#č�����!��)��v�[�ʿd+��_�3\@]*�x`��Y��@%�e鹎��H��/^��>�᪔�Y���C�c�L�3B���ȿfs����|�)$_5v1|�#��Rr��ьk��� �ޔ"$���T��
"�~�
AcJ��:�������� ��I#�ۜÿ��&�I��t�0J��Y�6��^ׂl�[n�XMZ���'W��̢6�A���)Rn�v�Ő�k�������}
9�bgfN:�7`��Jں�t��A��[���tkl)P��g�5�Nǧc����s�}���%�m�WG�+�q(Nz+se�v���;��$�4��M�d��RW�b垝�H}F&���@Ʋ&�����c��6c����fǬ�;�-��DK�Q��Ab�lw����c�1D?�XX5-3�����XV�A�q��U�������hej_��F�O`����`�\�گ�NYA.�zdw�A����rQ���Oi5��. �u6����h@zQ�Pݔ�,�&��r+܀rd�'�6r�&�� ��Z.�N�	����Jl־!X�89N<B�'�8�Qv%Ԕ�J�<�m���2{K^6w�{� �~�����İb�lAb�oA������D�U~�V��Q�`޿�݄#o�
�<d_��祽"��H�	^�"����7 r|����ƾ��	7��1��$)�F�Ր�%XUe���?@Tat�������T�ii��/{�
����&���B_Ӡoӊl+��t1P4��izu*���Sc�hL�D:���=o� f���֝Bƅ1���[��:�����C��� ���*y;4�O"bf��l�/-���tm�y"�E�Hڞ��)��X��/V{��t�t���_�:���Z4��×�Aj(o�MO���f���ψ�����dh�?:��'z�U�\_���ɼ{�3�/`��8,
�� cI{Hd�4�w�S�H5xI5j��f�y`E��8~l��>�D�6���?��F�yl��	�	�]Vb��8U,�9�W����+���Hu��Q�����O����q��ڭ�E�=1y'��1���'�m��[y��4��\��0t�NM.Q��I��@�b�J����yQ����q7ckY':�(q��u"���'���)�k5���~KU%��6ԫ&fEV��~��ɱ=���of�gd��##���0��8߅K��W>���T�T#�\�1%Â���iO=ȷ���D|������
ƺ�b=��̵��/�u�u���N�[�wH��n�Jެ�ЇS��Q(xŞ{��d�Ԣ�ܙS�����!���:���1(/Ƥd�eBuԍGl剥~�⠽�j�B;HK	�~����j��)��裾O,�d�O��X&CE��m��8ҷ�����ځK�`di�ʳMۭ�
Qm���`�7� ��K������;����Xö�`m������|�v��D�%�EJ��;"7�m%J&����[����W���*dJ��g�)�q:4S\O�"9��!OR�5�_OJ�V!-�i���9����^\��t�n��n�=�=+؏�~�f0 ����7xš��F�E��B%O���N���a��A@=˼��_��Q��zs�����}�^uPt�U�q��Ϫ�
�UԜ6���R�'[ف�u�sڭ����U�w����&Z���֛�|"D<1ΈF�Y�К�[q�g�k�)�p��N�DN2}t��O�f\�`3���sm=?	��u�ب��b�aN�1�Qnə�z(��OI������oN�?�L��A�Z�<(���������F��B1���ǽ�;'<�b]���ҩ�f���u\��v�i�yPCNʹ��`#�~!�3���o�����r��,5i}z_�Zf�:*2'��WA��p]�#cV*}N?N�۳�W�͉������$%(��@m�Is��'���s���Ql����7�v�\��`Ro�u���\؁�����
�XѪB ~c�q9���؎�(L�x���"Fa9݊9��J�����<ޞSW����|�5s��g"U��%�^`�Y�z�'�Y�/�θR\��؁��p��¨/��3܋���qv~�=�#���N������q(��Y�\��ө/tS��.�s0;i׏���^�ˊ�j��E+�>��[�	�7J�0�Zg
]�O	<���S�ʮo:T�*8y��ɂT3؊rX�YC�
�x�T@�-u�a�YGHO��̗��|���ojя4��v�K��'�y�SRt��%�-�Y��H\%9�S��i �y�]���A��J?����}�y��~=��ŕ5�b���h觱O��Ƨ�y�4��?�?i} �x}��������]����9u`O������͏J�ʅ�L�Y������	����o�ܥX<�8�M����L����Ƕ���=&[�R�/�0������M�W:�h�#)�h���6�BV3��r3��L����G��38@��;�˳�Ro2����Ble���`E����b���n�����A�X�,��5*9meuE/^�c��c�N�!���a�D	��!�D���BR����Fo$Vj�w�XS���!F,��e ������;�,]�Cj�h�d���7�P�EL#?q`�h�x�yX#��lw�����`1U��n� ��v�+s�S*���k���������(�h����?t�)�x��z_0"��������D1�e됋O�
��Ԇ��A�9/چ
��I�����w�r��d�I�����H����+)UGG.�⪩�F�C��
��Z��dﬆ��d�+\�?�9�Y�����t,��:�k(yqcI]ɒ�	�
�e���6�
��!�4v�����>�m�"򄍅���u$�h����f�p+n����fNUR/��h�vw�=�L�BU���k�؇��&��C�w���uiE��~a�j�z�Y��C~(L�O�؛D֓\ǲ��_��*��@�޷m[4y�+ū��5�+a��;�B�|.49�I/zp]�:��P�(L��._Y���]f��+ �R$a�[8�cZ�d'O��u�=o�@�ƚg#�w�=�V�8{�I)�ڕ�JF-Rw+�����.=7-���a7�������]�Huf�.ީ3M͠�\�}�Njd���KLY%�ۜ��^4�B��ޤ!u�H(��1����x=��O��u�#w��\p��SS5<,�/H1��]^4�Ch:��Tp�_��'�T���X=�mn����*��\�?E%+�����V衹���6{��HFv�U�g��ն��+Xk�d�gZ�t`���k��Dl�����͋�lp��"�]�W����97���|�n����$�z��OmVz���ħ4� Hk��@r��Nr8��9]�Ǉb�BF��/m������D�úh�&Ci��c�+L��A�44i&W�K����
fɶ�;-��m��L�{���Q6�B�n��6 ��zq��}�䃉#V�Z�N.���]T� :��8��<���H~��,�^O��*��ɝ��j�3~�.��$C9-�7��dKt`���g`'�<��Z=m���5/2���?�G X�L��'),��N1X.��ᰝ��-���*��GoT���0��I���7�s]&=i��o �
W���i�!
Pg��[~)�O�|g[݆-�P�Ըet�gb����-7��\�d�EU���[t����@
�#�
ߴ�Lpk P���������瀹U��Yif#9"�J�D�_��$-g��3M����3Z�<>���A핰P��ߘ�$%W�hsZW����v*Z_~z�����
Ҍ��/݁4����ԕ?�g���um ���f�j9��7UzXN�P|]ҫ�5�da���t��	���^|��xo 		�eļ@o)���K��LP�V�RTي��r<.|w���a��
��L���D /�b� ���kt�S���RT7J�|�*���>�	J0��$�H,`�8ou�Ɣ�w6a�Ԯ��J]��+�.�_�Ùe�L�{�TyK9��?"E'����f #'Z�^@JZ ����tD��3��������Ux%�gmAw��n���{����`�Uj�v�5K��@E^k*Jt���U#��x페Ë����z�%�qā��6xf:���5,x�mzlq�1#?WL�wb��'r`ޱ���B�l�@ت�l���d �S>�_�C|�â�6�]��+.�w��vD�4��:D(��Wm'��_��9Z�E�zɧ�Ĥ%=#��2فO�X�6��ML��A�i�Y��/K��^<����8hWBY��՗��r�!@e���!jn4�B�
H��$tREAK�[|��lfH��W��E���%8�ݵz�W��E����a���8���L6��s��=��� SnT��ﺎM2ڟ�+kʤ�������	�<}�	c;�*g��6f;�?�e�T���+��*�G���1I�(��� �)�d���hfʕ�|���Q���`0Q���W��2�@�Y|6�`o���c%�g��o�W�	"���yuV�9c۷����e���g3L��sO��;Tn;����
�S��u�m�]D��䗰�	��&�.��'jX��TFW��@:}�u>��=��٧):�/7��Խ VԢb��=ʸ>������6P?^S���Du��p����i�ԃ�^��2~�l+*P[��S4�_��R��V���&���y��\�w��<_T��� � po�^2����|�|�s�2)��H�M��"P�O��k=�ܻ����_?���ɑ��E��ˊ�`2�g؇`#E~�6F�G
��P��AUyb�m��S�3Љ�fK��ʫ~ _��ڭ��d���\�J�8�K,0%7��7l#Hyk�w���t�2'F���6on�ɋb�E?� T�ز��r���xl�m�5�Ƌwu@��,�|	r�n1��B���O����<�p� ����{w1���י��>Ұ#Q�-"G�3��.̃�;jX����r��Ƥ�l�N;��J%��D����_:U
���
�_3�`��m�Ď��d)w�`��aڞ</q}�ѰoaPo��H�x!&�`4�$�H��1�8c�C5�u%�
�|���D+��A$�S`��]<Ģ�>G�� �u) $O��G�> �ۺ�,���R���wH��6k�zi���.�T�>X��ib���Q��&d/WN5Hޜ6gl */Ne�R�k]�I�4��2����ǨxH���`�`�����S�R3��Ç3y�g�~&g��r�qXLkF=�$:{y9�	��A5���I�%��и��&[vϨ2����0��w�u��4��V5�y�|A��Qףb%w�v��Ǵp}0�g�w쎫������m���t���>�Y'ߤu�IBj�W��k��K/'P��2�z�DΜ`�>83|�'!vG��#�~E��ȱ%R���P�iϔ "�k�\Y�kW���^�`��_������R������a��9���-*S�8���id����t�9�7Daf�摎2^*0��"^��K`:��  ��~#�b�ho�T�s��� q�{�o+�"�m���qJ�y�O�~�T�E= ��$ik���f��\�v!���v��
'��]q��p���}�����d�����'�c��A�g���w�G4,��;{�G�g�D�K�ft6�ʠ8c�=�HU��/ߗ)���C� �$Jď�6����I��BE��kk�iǥ��u:}z�Z�����<�-=%�)��������~�"a�`�ǽ��̝��ɲU�$(���Շ�������F.�^#�4].Kd;ȕ/����@J���B��7q��=�Jqk�����ѻk<m0�U�R9��^�(��X�e�#_�����P_<�8��|Apd;'8��.?��0&�I���;>���:@�0Q~�8��ð|�����t(MM�Gn����ǥQ�����N�����ԟh5+R?�^
��i
�F9q�V������!����c����+'3W_ل�-Y�*!���x�5�A]g�L��Pӯ;�bUqD�����V�1ǈ+,Êw�z��'���}O�.������+�:N�+���������$��,Ҟ���O�[�_.�o���������f|k��@%K�d���,��Z@��P� q���{�X5f��0��*��ݍX�r|�"�һ�I�������8��	�{���Ħ�LS�5�@��Z���Wض6v�&'�l��a�4���$����<ݪ��;{����@y���y��b3Qyxw�O��[�3�w'B�S�/=_嘴j��*j�D�Pk�;��p��>UZk��lq׺��=�X�:�L�����w��=�e}͸�y�_D��.}�pi�E8��r䇰�6�	�*��I��(�d�,[:� t���Gh�HS�z6�Lu ��2Ծ${.9F4u����#�1�b�r��e3� k!���3O�ȵ�w�m&��F�M0�{:I���t Bi�]� ��@�����?|�ώobA�N�`Y�d�Dv��"��+ا5
�!�i���i��������F������i�"_?����Ǭ�����3�j3 ��ǁ;��nqb/'3ަ$��e*��x N�T*����H��?�˴����mex *���@��0��+�^�!���K�9�d�F�vc��o�^E�8�Xx�eFc����_����}aQ�Ǯ�:Po|L8��;q��﷾X=�KC���3m��2
��$�A��	�U��"�8tf���4ⶉ��V[c�����EB���iٿOiq�N������:��+�~���]��%�/������[�)�n�ȣf��rG=-~���7?�ȏ�Q�dJ����@�9�>�w�Yyy)D�pr-��l���w]ޗ�~>}��L.R�-?i��'�H�ܺ���z+l���*L1��oxY��M��XQ_��[���6�߇�g|v����OS��=�vLU@��U������i[~e0d�H��zX\JĬw.��-���ۮxk�*d�3�3������ �,W��{1h�����
=��q�����f���v�컀y�m������6��C��+�;�'��#sg@��4J�N��H��@2˥Y���i0���ef�8��"c���1��茫~^�L�y��H�Yh ��΢crΉ�:'��]l��ȇ��0Qj�_ALQsһ�{�3?�.\���m搴_�a�8�ho�� Q��եr�S[����A��A�����UK�1�3�a������T�a�������E����-�F0����m�]4�&��h|�>�lwFulJ�^4>�r4�O&(�������b��(A�lC���)8r1���p��%�7]��w�,[:#P���i(F[3�BJ%�i�0�n0����G�5K\V���k,��
���0���m���6l엢K��pi}e(�\�{a�7��0��s��LJ6���,0/L�꬐�K�����AT� �]���9��㡤H�H�f�'����iI�f��d��((�P:wEYg�+4��wY.[e�4_T����!K��y����1"�9�D2����'_^.*�9K��9
����ޔ�9���F��[�4����d���tB�Ɣ���e/��`�G5����|���G]�y�����8c-/1Jŋ&.�y+C�X���z�RM4C�3�z�g`g+	�
�`� (��X?2�� OÓۋ�狂(�U�ح7��䧓P+�)F@1�*i�sG����������C�U$|���#K��/'�<a�r���sƔ����n-č��� �Y���g�8Io����a�h��n��t|Q�ï-.���0�0;%)�F��]>���@��ܯ��9Aه�/)WF�Y(�z��$�����\N�d�v�c�y܉�R_>��2�OXb�*�x߼���->�ai�w^�����r?�S��#daS�cN�.���M��kb����X��/{1�(K;�D'\y�2�]�b�Y�UZ@S����P�"�#E�+����T�xD�����3C���8T!���\P�����uM�T�
�ת+)���	y��y�1���>/Ϫ��H�I�O2jRg"���$)yE)[��ʳ���/o(;5Ȁ�*S��R?�����.�Vm9��RK8�P����B���1
�75�7��CZ�;�1r�5ĵ=��J�:.���9����.�:�ȽP�{��dW=P�v��NX�2�w�d�{�ɘ��Y���1��sn	�Jzޝh@�O�9I+舢�k���BV>>^�Lk�����u˧��.��k����#�خC���v�M6P���}.��jltiMa��������([����(�AaW�],������K�K����	B6��^}JnY��B�(I`ncƳ��
�+�i�`�����>��������a��u��q}J�N��z7����4&L�"P������F�
��v �v���>��Kd<bH���_<��6��E��1Y�Qa��-�S���[�u4}Q��
5ǫ�#�޵�W���
�����Qe����e8a�,b����q.RL���K�(�y�~�_�	�������.K�>��J�՜4Ht�Ɵ����;��bK���.�u"� b!��2ɡ�S���~�3������t^@��V���0��5w�j)i��:g��U[��S�U���p��:{6#��(��G�*��%�l'�����.���]�U��z �')��:�铡�Lˬ]��;�	�vR�ە္ys���G�f`a����'��[��Z�"J��OSkcd�_�CY��m�y�G(_��<�#UdR����F[�#���u��0�l��h�.�ﵶ���k�=��,��̌��F����B�D��j���ig�f%�O�u&�,�m�c�:�̢g��ur���	�ޟT@o��~���:�R���6h��՗ĥȢ��ߑ��\�6^+�KC#��K�Jur�ׇ��1�3'��<�?�v�4-�+��[��?�F��a��2��,��<C��$6�4�L~�!â�츓M9q�����"��}���ww=�4�S�fe;��<@�L�kX�WXe�_5B��G3L�Ͱ}-�E%b,A��^�z���k!����������v�T*Q]�W�,�1a�g΀�^���NHN�Bw��CK��C��Ď�A@�`m)�D�k.:u��,�aP�6q4y���IQ2U�p�?��j��0n(o�z��c��qӡ�QL��հu�3�~���	��#��/���ӡ*^�j���}�nm �t�-.��i�<lݬ���u��`^�%/��X�|D��@F�����EB��ݽ]e���ū[;��%��f��T��;\P�����Mǜi���Mz��&�E��S�����68����9�	��i̐�q���RH�fa�1��Ҹ�5�fm�X�����!����P]s�<��fL��dJa_�L�YT�&��H�%ȡd$�0����n�;��T �M�O�R��
��l��&�l�b1/�IS����c2tu�z�h������uH!j�W���b�°�*�-���ݓ?��h;�Z��k!Ω&v\@��3���c�~O1
%����5�n�G����D;������⸰Gh��}����>��us�s�^�<�%�*R(u�A今_�\�7��j��T��P�k�������#�A�U3X��Nˊa$I���w�
�5*�u�s L��f���ۢͱ��7SNr7>6�fC�I�Ԡ�'�{.hV�I�%�6�1���v�r"�^g����R]0��6?��q6Zg�1�ѩ��B��z�A���8����&IK:2<�ߕ\�̾6$�8�kf)z��^�,�h�-���N:��q$}�"����/�!�/�v�6��P$p<��R�$-�4�QK�˰"�?�[��gv���`v����{g��{@Σ�&ƱN����i5��2��EX)��E��G8��p�k{^��o����H�X�j���֧�d�zl9$},���f��z��ٕ�C�1<�����20R�.��l��g���� O����a�}nC�'f�Qa��~K�`��sfc�p���1�v1���H,3���T�̟s9:P��*�s'�g���(�
�8``�OZ�9��r��}��~s���F|Bzp����3HPz�0�P祠r��U褒��ݝ5�-l}7H�׫�RB�>Gm۱�$@ڽ0���Q*�l�~<��+y��/�6� ���V�+ӡ��g� �򠟋��n�]�j�M8m����;�z�-�ƻ���&Ƚ�x�(ݎ�+F�ج!}9?YO>�R^I�� )������[{��m&i��ſ�'Ze��l��49a��>��/ģN7E}��� ~����e�ҪNQ^�u���L��~���0"��	 噥���.����\+j\���]ډ��k�!�tK���n�O#�W���}�OŀQ�F*�4���i6u�"e����#������	����譸*<�b7d��&���=)���/|��%�����M����qzDl�&�ݡ(c�֗�H�en}���#l�D�4��s��5y'����Z(���1Td�;�D�ˋ�ݫ�C���E^O�<WD��r�X���T�(`�9�r�6ԗDr�|M�~�w�(�8XRz(K=Γ?�~Gt4��Ӣ��U�j*�]�-�u+��ޱ�H�xx�؁�Q$���� �^����
o��&�A����c�0�,M������Q��|;j;���~I���`�ʡj36�S,�N|dQ�V˃��?$���G��P��p6��$5��r��4ke��=[S�^������S�Ooʱ�p���O�r���쪗ʔN��<d���
q�a�ad���='�Z�8��0���>���ltF1&T_�H�7!�Vt�؂�g%�^~w�����<e�8�������^��`W�'�U���<<G��3V�o ����'��E��� <A���>_	P>�T�]�����jn���<؂����ur��j�OC�/�ז�h�ȥ��O{�I�?soP��I�+8�5�6�+��i�S�%�y$�B��-�0VB�M�h(<�}�M�Q���ԉ���V;2�I����:;�,�+�ʄ
��eŮ���xk?b��Ok��wqe4��1�*A��;�4��;I��>�zl
U��nCp-��� �HB9��2c?aJ�|��&�b� �of�#s ��-r�M;����~�6��3K����I�<
?���\C�>�����h.J���\u��j[��#�N&g�����TQ9{�}X���O�=�@��/��K��A�:U'�m6�N�a�o�s��q��K�^�-9��ࠞ�C���:�*f׆{N�drv��x�K��Cˏzax���1���z.�����a���)���m��^%#�dK�90���e{8�� �v�
_��������|���h���"��,/�����f��6ێ��ur5R
�c$&� �����uޝ�(W�o�=�h}�8����ۇ|��i��aF����}w�$���b<��Ip�TK�#��H�ln`���,�1t���}���5����jH=��p�:�w�C]��(��Gܻ��#� #yul���1�-J�����N�u/}E¤�$U}��{v7u!,��^g{I�G�8
���-L�]�t�H�¨�R%$�'�˶}��SIt��ް���\-�~~�`��)�JJz��VMn:��r�~�Ev(PK���B'�3؈�����5�]�����i�G�p!�'ܩe�!�=(Q,��|î���NY���"�u�}o6���4�E-[���!��B���D3�\`�x��^q���fP@Q����u<�Ϡ���;�9�w��i_�<b5Dƨ1}��)�(���
�	(_+Fܷy��%]g��|����.:��k�[u��k�gc�e�sdZ���gs��{�:P�!�5�,k ��V�R^N�0,L��S1d�Yj��K,�t9�J�dfB�c�~m�-ۃ���]������B�]��`/$8 ǲh@�)��p�p���h�9��K=���r�l])�MV�Vۧe]��EGA��%��l����,����3Cf!��(��rT�E�àK�𥽘)�7�΂�|���ʸ�75����j��=(-�v�]$p�TO�y��X,s�����Lj#V��"���=�e�r&�נ��K�nI��i��žBõG�����y�����uܔ�E=�A�[|#�]Wt	[w���[��%x�#���^O^��B�
�3��;�=;�-e�
1(Ji���:��,�p$�6�K�֗*hF�E`���Y�SpTU�iџ���7�ҝ����.w4�u��E5��'�g�'ZӇD]�����]�z�+Wc�5k���9���Ȼ3��Hx(b�쭥��^�Ex뚿+i�4�4����m�5wR��4)s�؊��`�PH�O��f��DeXE���G.���Ք�P+�4��������ΰx�b���R�=�����W���R�O�5��{N�7�K��_��ȗ%T
nOY�qG�����Lx!E�ڳ{,u�KY�C���|$�G�?�����'y��&�/������!,Rzo��Lݟj��CXLr�˨���Y���3��)��{�����}41�lrU �T��_��U��"��-�u2��kS�|�HP�t�_/mK�Q�G�1�Y�\�ǭ��|�LN�,�L���6��Ct�x1�����Qg��nX��Ƽ?s`c���쩜3�];�nSG$m:���8ʱ�Y��{M]�~�F���ܷ��7D�͢.���}ܦ쌮������{,h�CN^�[����e�Ƥ�4$��Y틵�*9����Yk$��04%Uo@�!�x�d"~�g�@�v�x��P���Ĥ�6y,�r�����L�ǿn`sak@����:�As��}g`)��jD��(��H��J�Uf�ſ-�
���8Z�� 5�Qn�{�Kf%]^�0F�������J��uG9�N����(g��t��ϝ"�N*͛[�ݚ�B
�����^U���Ԙ�C�c��a[x�Xn��)��*;Q`+^Hiy=愇�b%+� �!7ʑ�%~�X:~�C��?n�����ʽ �M�#E6_rkr������m�8��W����Eɻ[i!��P���1��t�"���6��B���V�k��cZ����9����~���˿H���8j���C�����.S��-�o����SX�UHEG,k�Տ��V���y��=n��$��g��h_�Q֤n����m�h�.ǁ�P�>��B��<#Jy:��~��?���JA�� _�,KD  �[��I�C᎛��?6�n�Ι'rG�)HD�I=gWN�۞�χ��=J�z��/v6�:�q}�q���v�����+�U��PE8����(�~P�(E��Lٺ����/}�����}8v-#�_���)[�,��L��/GMqϼ�V֌t�]�)�؋~�0�x�d��(��TP]z��ު�ܒ�J��q?����f���o�S�?Q�}��tI9^�c�c��ۢ|?��7�s�D�(�=�:w�Q͕Hty�,)� eoYW�Z�������������]��i����it�u��s�B%f��![�&�� LO�o%��;?�B������˖�	N%
�DmJ&��")��N1����CH*[�E���?���Gh�����,n�C6$|�-J:�V����ﮯ���*m�{�q�d�^�	��}�N"Q�CY��&����b���;��V=Nu�厼���u�@M�]��1�����Cd� ����o皉�꘷� �JC�gwEz�s��3(�<4v����]�ՙ%t�sX���Fr4�8�n�&C��k/�Κ����X?���ik�w�2y���Q��
1}p4���9^:v����O�Oo� K�?�rVș��q�[�.�F�����{S�x��rz>�rތl��©�Y��Ei���ޑ�P�UMH8�V7NE7�l8'������;=����݁�-�AT���k�/����H��н��-�Z�z���7�;�-ِ�Kx�y�iG1˼�}V���d��zZ��b���6x�!$�I�9h��~�n��]��6�EbJ��聏'���9�����"4@���H���������hV��!���='.��Bܒ��G�Q���r�M�7�R(i��+B��)ܡ:��?�u�7���k���k�Wesy�F-[��9_�*H�-1�ŀ$�O��ؚ�@���^�������f������EK��X]�S��\O����t��d��U�a `�*J�Xkؕa�)W��߲�Q�q���ЏȤ����J$FM@�r���c��ؼ�Qft��0��ʮ��&�L�l����n�n�U �xà����;�U%",yrt����bi��H;����h$̩���h�� ]$!�o��gb�)�A�~�˱X6�-W�\�����
��J:KrX��g`CZ�Q:�U�c�N�e�]���epc��j���9&�����.�5z~���X��^��͔��9�A<T��E2y~8���{�3!ֺ*_ �Qp��ړ=+�6�b���� ݭ��*�~��s�7��&B��˜-�&�;g�{j�V�W9�L|cݢ=�������ŜD���&;ݱ��{�v{=��"1߬�����O�p�"Op7vs��~i��b]a3cc�&�&
�e(�H*)���B" F����<�W�v��a�
���[�|����Aω�Ռ�g��Ҟ��j�؇�5O{b�>��sMl��?�����0���vF�̷T���ǟ�}���'f�-&�55ma�5M�_�p	65l�5�2�G�>���[a�_�o[
�����@�5yl�;�㦦R%G���f��~b������^��T��&�Ta���ͼ=RFƃ��YPt]�ЎVy��,� J��I4b�ƽ	�R�[+U�Շ��G��*�>���_1*`[dOcR`򾞿�m�84��8/���.��ϥ��T�?��j��S���Q�����T.��HSF�.�I�����G�x�=�[���d�;�=_���/�&.��'&H�H����ZIX�\�2��*$nQͣp�y�-�����)�h�g�Z��_D��\�b=����A��YT�i�Y� �ƫͷ��B�oQ��~�1�}�9��10��4F��,�Q]:��6�x;�ă�,�$�8���ؿ)�}|͹���k�Q��U�O��\��%�>탆&��>Yک��R��:��f�F����G�@]���?�w5kLER*�'�Ɂ�I"9m�)���	�m����ڭJz�;��Y..i�l�F�j^;�jnF��7�����f���<�l���L@T��u;�+��a���/ ��$��!����4L�i�|A��pd= �z!��-��b!3�.B��V.3 BM �Gi�	'��2�!|��/���*�1��͂���W�_�s؊�8ɖ�R)�e	�IO87B���<�
�7Ի�K�b���qP��h�*�����5��| �+8��8��h��vM>{�1xB���o���#� a�ܐЅ�*�{������#����-ä��M�m&t�w�"jӕ֔�#�3�����-�ؾ��j���ۛ�`��o>m���o����8T���;�;��w�<x��I)���v�t[*�N�#����I��&EU�R��8tx���E˻<�E�t�@�5#l��:F��]jy01�a<��Z�\�T�|��[lve�9f��k3;5_\��g�Y������Z�2[ �6�}��i���T���$)�L��Ν.]L,<��
Ѐ��� ʞ�����U
a�m����iJ]!V/�VX����,�����n ʶ�yf�����M6k�������_���Qy�jd��4jZ�a��LZW5��M���1DG�Y���9' U��Q�ܿn����P�Y�X��ߚ���\G�����o[`he9��-�C�0��˜[eV|`�,���1M���6�+�9�y�
'���̮R��\q�����z��׸����}���޻]� �f�߬:�{̥;-܊Q8(�iKrgm�so0" L�y�3�����p~5��ޜӍ�?/����l���`��.Lɨ�2��#xr�e���TŎ�Գz�a��ajp'��D�a˒�G&�e欁��V�CC7�Rd��V^\!W΃B��b.��� ��i�1!N�k��R��|��R�0n(����ɱ�=Su�ݣY�gD���)�4���>!��L�l�8T��w���Tn��6 ���z���ì�t�\���ܬA��`�]=wi�Bvo�����I�PLH������AzT����5E	H�-�Eh�WiV�^���a��١�`�xNjt.�Pޙl|]��B�P�Z��'Ta�c6�P��M�|
BD���+���"�yR���e��^����Ɣ�=�����S{�]��%�0�@���`)!���A��Ux��k���a�9�ݼ�:o�[��`��*�,��2�c�:��5E)���_yڋ�##�|�6qVH�͢g��HR}�ˍ�1p$([־)�Z���X�c#�Ns}�������b�3K����j�"$}��TP}�Β�X.#Dnjr�p��v��dBh�1y�y׮F��Ri�2�E����'KMˋլq�]����#���.,���-3Kd�0vi����B�s��iy��W����t~�j�;6�64w]2�^�#� a� C��.Q�Uܧ<���!c`��6����_2�;hR�o�Y���+��Y�W��(TjyL\D���瑩��{񉏙�舽��N�$�!�G$�	٨�Ɗ��3��Q���`U����X� p���v4�?�\@jȀE�ey"��a��F Dj��3��bݺ����b]g�X��T����o�a�z��݊��X�7t�N'�*&ʒ+4%�!�j��W<I{��$��iu{ͼ8���:��.OP�x\G�дx!��3�����3��gJ�� PoR��-�-�����
�>:ph�W)��X�>g!�r��^f�\Qɠ�=�����0I�C�dڏ��Lo���-�u�x*6�ZTl�r�\��v�Ug�/�\JI##KhxAkΚ�-����t�,Ed����Aq�(���b/Ԫ�%¦��ķ�sƆ|�ה6��-5�|e���r#�yʿX�����@r/���p��ں��ť�ccDp	��k��yC��W����G ��Xg�����������~�������� ����C��!��^/a���t�R�\ r�����h�TB��9���<���.�[�`��*l5��m�Ln���b�N"����H���Iy�2���(����Ϡ�{��f6?�jPÖ`eB1a�U�dA�,�`~���0ղ�ُ�baž1�{8,\:�	�{g����U̅���;�7���_�Թa�<=�Al]��7���a�&g�|�<��}'N�2퐶8gU�H���J�l�)� Mqg21)X�@	���kb��)���B@~ �����[�%eNxLߺ���x�&z3�4�Ǖ�ܙ*ĚV����c�p�ΑsR��*�h�5�#R�zU�:���]�4c�W^��Cĩ��.��suxMR_��/ܜ�U����
���������]�޿h��͸���w��{D��NGY�������:�d/���l���*[��hE��+�����Ѕ�_���q+��(�2?�w���j�����H��y5i��#wJ!?��)،�I��Z�� (�N3�j�E
U�{��g�sjϭ�g=���� ��Q�� ���0�����N'�-�\�BdLk��i��Ȗ��/]���ܓ��U�i)�y�+B�=��lk��0�/���W�ٗ_x�a�����$��r���R�5Q׷s=��������B&�T�0���X�ɴ���N,G*H�P�&vc�tPpϾ=�� ��tB�GVeu���,���]d��i���߿���{��!��8
�OG�:I`�?�~G3��Xv8���O����|i���`�����d �oa.��Є�$���D8�<�x̌�Iw(hh[�z2W3�u!��N�𰋨f �S	����։W�Āi����I�^�oÁ��cR?ͥ��	�j@�r0FS�!Q���FQ���x�Q#C�ǀЩ2�i��u5��1Ҏ��<z� ���_FLT��S�,�6Q%��c�
t�+����y �G�q����0f8�i#�qVȥ���^�� <�ke���a�^��	���g3����Kg�w�D�4��Eń�7RΫԚվh���l���a��썖��L���H4~n��7�I_�h`w�bu�m8n4x����G\��g`ǳ��K�,��3X���w�2��}�r5zA�W��A<Ǚ($w�Pp6j��� ٳ���&�6��nZ�q��U���Km�E�e��:Im�8��N�%}*?<���[�W�R��<���˅^̴�SP��(Y{�%�{n��ySW�6��9�֭=|�5�{O��Ƙ�JWX!�����H��W�	�kdm�������Pd���L|c	��Ӕ����RXyx�a��=Jp^1Uj7���!w�{eG@�u�����y�f6ð�I�#�!��@�A)�?���nQb �(+��
��,ԏ���piNF��t�����i���B0�����
=;R3	�t1�c��.��ts�5�a_�u~j��I�����Dv�kP��ǭX���Hתp!�L���I-^`t��w㭔�S9��sPH$d�Ra�/�(:�
���>Cyơ%���ߞB(|��,�t�
o�t��{��s���v��f�W�W�#wφ������s����쩽� _�[��Tޤ�<L*4\+�[_6�ϩ�ۀZ�J��H?�+Ll����ru��g������У���˾Vr����y�x�@</�'O��$�5+!"4T��,-�d�q��؁g�tO-Q2��6��zڿTh�/\ ����y��y{�>.p�?5��`�yA�cO'�ZZ��>u&�B���6@�R%[=��V%���Vjw'ix��L�B��^f����*p�0���&+��>�z�H���9�i ����.'9�>(�����e,GCk�m�ʻ9B��T;� p��,"�`�cDύ񴪉�L@�e&VTX�H�#�Ī�ȴ"�	vk�ck�fS1o7I|K���;AfW�SMn�mɆn���/r�R3>�.��xͿ� \m!��&Ix%�_:�~���*!4��M�<��Ϛ�}+5^oAL�d��X4:���m�'�Oj�؈��� ���l�*�%�:�^sH/_�4p,!��y�h�.Y�~������'Q H/^���+��n�jd��"P�m�&f5c*_غ4ҁ�]���Ƕ�n.��j�t��#)@>�_)�����j���&��ꧢJӾ�P+���k�s������E�ӎs���/a�����us�&�� ������	�W�B�r�>]j�j���o�K6S~��������0S_u�4��M���m�q��d�#}�c1���'��H��Nۯ�2k �t��V����˱d��F}�f ^��O� �%}�ђ�|�\�J��K��u`q��sc[��9�u��h4�p�ɬ/�<�\G��鸊]����������P���'�T��싢�]H��D�k1h��&k���u�´u}r�o��$�=}�)4��;�f��U��?X� ԁ2�Jڈ���e/�º+�j��f�	I�x�
���"o��[/�w>�{�$��j��J8��/�##w�7��c1sj`NǾ��Y�U��G�d��Z�C�R�+)E���f�xM4�\:�d^D�C�����ls����>3���7�Þ�������󁻔�"�*�+�Ɋ�y�m�2n�e�����%��.TV�h9�^��.jit>"��Q���'��n�����yd�s��ƈ
�=��X JF�x%�adi��|�������Zu7����ȺG����z>��#�ߊ8t���C{��?��h?k�	=��������c�j��8�Zq�|�:6r�*}b���2ʾ��4qϴGlL�x�W����VwN�(�H4w�4@͈kT#%���"�u����)��{z����-޵w]#�ǁ5��6>�Q�� q���Fl�QHv�����C���	Y���,�_�����б�2-CuUG6����d=��BNm
�gs�m2��=ZX|#�v髁y$*���֧����>��O�8~{OW����%ӏ[�Ag�t9C뙼��ڈ��8��^�13z]�A	S�7=���`�dg[1�m��Zl{U+gFe�Ҽ~���\���:���z��T&s�Y\� V�K�Ii��6q��Gx֔2�9��a�5�n�al8�}� ���trx�@}.T/�^��մ��k�q�!�)��ϓ3��F�O��?�NH�f���J7L��b�(�h�Q�)������S�Z��P��-ACI�"F���a��	&�N>�4w�T/���W���;�g�>Lyc��͈H��n���_8o�3��Tf?�-����ʩk:��Ǉ6 �(��[�Ӱ�ǔ*#��X�a��K*��F��.�!�*���@���E�=�c�ԑ�>�>��JoA����^��/�p��ߕ��A����Tz)��#Q���z� J�,��A}��+���R�J�ږ���s��l�Sx�#�&�	6���S�Ǹ(*���U����v�E��@~Z�S˜3�����mn���>	c؋er�ٵ��w��}�O�U|4C{y��ٝY������Zyn���U�����ֺw�G���~k',�]wᑶ�����I�z���Ȃ�!�	U7G�F�4�+� �0��V��<���ٝJN�ܘ9I�B�?�ǅ;+5��7�K�����d��~P�,UC�*�����К5���+�=$kX�����/��;���ߎ�/3p�͘��d:A�w� +Q�\M�iFmڷ�C'����T����&�o�O���7k��<v�s��qȵ6�p��h ̀�B�a���f��4�	oRn��f2!}��1I����f���}\ߌt�/h�`qF�@2[�|�|�r�!��A��,�����;�qN��^Z��J�4��``M�JY������3W����XE�U9��*��TP2�Hߴ���*�b{k���d#��ያ���Y�:y	F?*���I/���w���>cg��
��l�z�*}�3?��'GN+��%zT��Pp_��v-�������G��dK���z�$�<�n��^f��O����}w*8�by)Z��X��eS�}�p��YV3��I�N�;'��nTK�Z�|	G�"� ���߯Hf�O�F��,��TGu�pYɎH�wVk���+��!�;� S�H(��v.��Jٔ�:,v ����dA�;*�<dW� �U@�,��:`�{d�<{U7|������^ ��"Ҟ�eRs���8Pz�gݫ�1��^٩x��B)��xt�Lz�'�B��n�y�\J���|���P�K�O�]!0.�]Ga͢D�|[@�� �b����]�Ͼ����(�x}��9�ym��F.�x�Q<�z�+�L�b���0��fI�<�t�x$�<t����t.E���h����s�οZ��Zc�7�f`��>f?es�2&SY����"�B��`V ���&!��N-�ؑ�C[�8B_$�=F�	/ȣ�Ε1��F�.>��Ý���&@�I �:n%q��6j���["�pAR�<)��V������XCo7���$�Y~ԣRK%ȝ�V}����5�m���y������ t��q�(�Qc���&[N��d~�	��U�����֥����ZZi֩�����gg�k�B�QG���R�ؖ���.i�ZJ��!Y勇�?|[���N'j�H��P����@F`�)��}����pH칸z�6C=���9hC�~��;=]����od� �~D���~�.�^0Ţby/LkeԽ���o�	�*�_�l.Rb(�L�Pu����6L;K����V�z�v�J5�b�BM����-׍<��v������ook�>��9�:���%�'Gp�P�.k�QC��{�?� ��ŷ��.����,��9�%���oC��j�A>A�eUЇ����ζ�v�G��������=��m��.��������<�ꆾ���N �_�`�7��'L�j��8i05�h:������4�����e��d�g�ɐ�%5Q�0a������rQ�HlU�����-yeE*��f�������]^���U��X��\�G\S�䜆��M9{j�-�7|�@�I�H�u���#9ރ�� �f���Ƌ�w���BC B£����D◰��C����^�.}�Ԥe�,3owI�b^kc���k��あ}A<҄�Wo�Q�����d�c�X�^Y�����9U�ji=�7��"�Q��*4As�go_]�]����c�X�q]�K��c�ȱ/�JP���&��~QkI�|���[�3j	�sĂ��2�D���v(cN@���D�R�́]"�S�yS�З�#�Up������rnx�g#��+���XK��Óh���n�D[g��s�J	.<Y�A^k�y8���e��
�R6��K��D����f4/b	$�.���J�_\�k���=]ٌ`�x"Vvz����4}�=���bc�6��?�����3�Fo�%���<��{�v����Nb��E�����kS� ��� �	�m����Y�@f��C�`�.f��h{y��SzZ^����J�/�o��/��������>���<�����Y>|=3(�}�
O�36�^i��&�EQ��s������TБ4�qp��vJFx�1
4T�`/�/J���F��H��m����]�K���(P�V�¸cmB�\I�r�����u�t���#����yzX�� ���m<S�d�@��F�@��`$���f����Ik��J�3�3'7)�m@��H�_+-�P�r0��oў��.O��g���i2����vʘ#0"M�����]�]ESp�M�W�VJ]�(��q䥍�A|U�3�=���ɬ�c��}��Fg���a�Y�e[ ������|�>�z2�D��Te$I��sN뻦���5���{)��TbN�����Ƌ.�t��hgXV@��;�?�a�E՟�n�RsI��ѿ�����x� �^��Dޓ��~�3j��7��ϬH	F�c[!juN��B�=:�}u���T&�jņz� v��c��A�Ȕv���'z��!m�n쑉�$e��h�0Zli@w��e���hD��ץ��u�v��L�{󆭳��8��I��蘣�,��r)Kg��ح�3ys�����<������E#�vq���p�W>T=?F=m# ���@�D��ByD�凕��+��Y�b뀉Ė�����-Ǩ�L���kI�{`>L��nC�y���X����7�W��&xL�]�xm���R*�2����4�9~�Ie�erG�M����R�Ö<{�Y#��\N�Bۣ�,��.��X+�� �p�?���r�Ӝ�\�=��'�uc w��|n2i|a�AB ���O���%[�
���B����@�3b>�'Ux�v>�s���/8�V��^^��Pi�B�<�ߚ��N���{�z��A�xa���7*���BRUH�*	�$rQ���M�FŲ�f���K�}EaE������`3]��l��kaI�"�Pv���(x������4I��͵��,��*�����<m�(�/JT���sN���r��p�)�lS/hF��%@��?���ǐ���n�L��N���2L)k����
�Wq̔��0�k?
�!��+���;Ie��@�t�d�OQ����d���'܄(n�;6P��/'Z�l%�v�BO��0c(u��%[x|;Ȋ/2o�(�^� G&�I8��@5˞3b��ʌئ�4�ack��~�E�u*}s�S�Y)ۉC�o\8�*�n,�l��p�{g耞��M����?�Vc��
�V�>��ȇ�}���{�c�[���P���nӄ\�	��@"�RƂ���:
���T�)�W��Fpɡ�L4UC-��I6-a��i7��xJ�ɭ�*�}���N����_# ��������Tһ��P"�b��{���L��ԃ�a�`�I����g�u��#
%G)��π���hC��b_��c��d�y(c���9�8nS=��r��8��lm���bT?,B�/C�ײJH��w�{?cf�%b�s������Jv~S�@��t����X�V3Ř��I��c��.�	 �n�鉖[��,Ohv��9�-	��Ne(�to>�h��FF��'x�=Hoaj�1v����H61�nrju8�>b�o/���n$��B�)yv{[��C:�yC�$W�4e�v� JdZ�}m!ud��9q�>�J�ic���bl?ZfI���~UP���d���������'��t_!�U�Q�s�*V��м�,8�t�J�/�S���uW͒��4%��ƥIv���H,�P@,)ЦO���$�b�����Ÿ��⩼Sz�K�ɎG_�����h-d=v���1U�֘D.:�?���<Y�2Ŧ�P[Z˟�g4e�v���uh��ԩ�H�͞�ǉ�9������MO�<E�붬S���J=����۩����r�Gԧ��v� ��t�fi	��t�@\��ۛ兛 	,B/��7���'���(���Aԣ���r��J��\�_.9�D4Tw�+�Wu���E��0{$��N�i-c��W�b�8�#|��Y������*�9�}q��{�$yF��k��g�@-�.�~	�D8�|��[kAz��� ��U~eKͪ�K��1���rP�:E��`�'��D�����8�`�����=��Ijgٱ���֡8F@62���F�=��l	x�$  ��c�'C �����stN��g�    YZ