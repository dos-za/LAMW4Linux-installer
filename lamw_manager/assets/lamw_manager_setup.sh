#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2071455524"
MD5="752fda8deaa39952778425b6a5865bc0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20340"
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
	echo Date of packaging: Mon Nov  2 05:02:50 -03 2020
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
�7zXZ  �ִF !   �X���O1] �}��1Dd]����P�t�?�B���5$��\��ǰT6E���zE�2��]�Bp�.�
)tL����U^wG����8B���
��ץ���b.�`�%����%��(��Yϳ��*�� �F�����M�؋�,�Q�N�x�Ct�e��ɉ'q���g�e{����!��xl��h�x����Q�����sDC^�J��E�tQ��(	��׌�v�	>oF9���GsT���e$�	d�B�����D�\�$��LM�T��%J�Պ��بl�<��"��4��w�i9�c�h��7[�A0�\���ށV"�%��バ'�$��E�#:���� iR�`�M��{�%�^���/�/Bԥ>�KWr����������;���ڝ^{Q����Zp��p��K7�ӄB��b��,�zIӾ�)e���n��eH���FR�(������HDC���NG:%g<ŧ'�_�%�}��A>`3�*�e��0���6�vuϝ�� ++g�I�d���V*4��=������+w��ۡ�zVY��`v;�D *�)�V�/'т�C��uH֡e/ɻQ�g��(D���� J��"�:0�R6p�d��Ӕ�L7_g%2�A��0�<q��|��y��81�P�'y��H�N�X%g�~��c��Yx�6��y�p��YN�872>؈Ē0���	��zlLY��@\�T���� [�;f�2S��v�|�b�����D�GC�E��۬�Y��E�h�����\o��f��-z�c.3Ӎ�`���,M��m{��!i/`��N�$�����������������4Dr�hކxK�� ��µiXM�=\r���	��x!��E�j�}�h(���Pҵ7��QId���V�+�[ >M�t5�P$8oWHٛF�q�AzH>�^"}#�%��4�.��S��'��
¥�ز�g�Iҭ�2�izc�=˴(�M!���xRU~CM��r�x���A��t�U���V��?BA��%vw�H*�y����*�VM�'є#��u���}�I����I�h'3�b�,�~]͍�cmU�,��l+�=}�� ��}�&E´���3�!����
!]Z�O~�%"�����S�2�t��f˪�t��b Y4�`T����B_�/V'���3���9�W��Й�MTb$���Uݱ��0�bj����xLv���1��t��z�	;b^Kf$��,L�6���n�@��'F�W����]�����5&�T;N��Z�v�j�|�݇5v[gt��Ӄ���U!��ңP�]ٳjz'�w�U�^W8)�����H�e��v�+HZ�1�2*��|J�C�g��3�����|,���u�ٜ����ߓ��n6�[��v�-ZW�t�ӄ�&��u�A��!�m%�n�j={~�[�J%�c�AMIi��j�-I���
��>�X����_��n���++h[�f5g���`CMl#�;�2��|B~
`@�kX�r�@Z�)�˔��	C���tl��ӿ�P)F�!�t�T`�:9�[H�wf+5�5m��!�aWQ�6��S"P���U�Ra�
��7��ə��̑����Ϛ�P�f�r�ŧ<XfjY���(��Ԡ�a5k�&<��J½�e���^�5F�Ĕ{/��<����9_mr�`F=����Uq��q&���7Lk2��k��%|�4�N|�=�c+��=t[�X�?D��4{b��;6j���;⫴�`J�b�Q�bH� �~��F`_D�9N�\QD�,�Wx����;-��9E|�+��Ÿ��>�W�(̎���!�f��2��]/N]�uK$
:;BVb��K�v�7.�����`
��Q��(fL?���[ck@Q�Jm�D�9e��)��P'�۝C�g~{h�����b���H�9)ҳ��D�6ב�@�[��أ���ٗ�5.�Qgح���MK�A�:QL�;
��D5H�2��{�4�x]������s�1kPmb����i�<�k��������t{	ۺ�,릻AOd+	9��NP��ɷ��+kG��!�n�?�\~������oC^a�sT٦�(a�k;�e}ZI�\��\mxi�v��OE额Ʒ��NA֓_
�0���>,��������h�K���$0e|���1�5m��^1�
��Q���
���ǢO��k0� ����g�ӊD��XH����s��Ȕ�x����ZI�	�(/�V��eY-�l9�V+3�.h4�ē&��/��Z�:��9i������*�9����A6;8��4��	G���'h���y�D>^������3A�|P��+`ԡL�5���~��L�����i�@L|�i��?<1WʓX�484���}@M�BU�;/�-����/W��~WxV���.̺l�u�r��9"��Jɦ��l�0P=���;�CPu��d*Pm�]�_X�3�
���DPs$�+)�3zr,OV�FhU8 ���o����Q0����u�1�^�x�d�s���	��W�7W�̄4\�M{�������I��^�uT����i�b��eb� }&2x�1���µ�}� �,a���5Ӓ>At_.�b��5�g<%���ӃP��^��P��5����W�[��Ư#F�F����&�����e�޶�}^����k�*mӳ+�5=�|�3<����AX["+l�����/P^{��� 5�R����D��KX�:~��
�c��2�G73\$�h����k-hoCe�Ս3��2�!�x�X�M�^��� S�kY3�ܔ��de�wD "��r߸na!N`�
B�"��Y}r����7�t��D���%s�xe�&rk�_zN����,ڕ��ެI�Z������|����Ox<G&�&DUԸ+uc�L��QPO8�yq�)U|�\�o����^
&;�:}�|�iu�����_��ba��U���*d��G�e{��`�m��YB�Ό��bu�@e#�9'�|�4s�g�O�� ����N>7�������K��3�H��F~S�f�u�<�.��l��I^.鮢�)�1�4s/��O'EU09!�z�+WБ���UG��!B?S{	�#�dl%��TS'X�����I�T${q|���ׅ�H�|���ƱFԾ����b����X�H�x�0v�*��H)?"~�O�[���ݮS�]���)�X򔫡�����e�Bd����:l���
�x���%�n�M�͹�0(5�Sڠd��
��z��7�k!>������׿m�U7�jZ�a>�tٓ]�Kf����`���)؃ <�(�s;�A��Dmu��ߕ-YS�����\�"�Z�û���@��MGSϻ@����}�����8=z�4��=���`mf����X�I������5���r����v��kHP���n����^�5�|D9��F���$�K��Р���J����L�s�;a�oc������5�E���v��Þ�e���̪{5e�I��i�t����6�:��[�;Ԣ3~-s�T .q�Zb�aa)n��H�[�q���|����* �U?�tWl[���D^�?D�a�͖��̴�4�-��-ϩ��I�5�;9xD�h3����l�L����5�������cT�;�� ��p��l���I�R����عn�蔑����=�������^�"U�Ev�
lw�l]Qh��?�7���+}�P$,�nJ��Z��f�\��,�Fr/\���Q�
��vHiHF�w�D�'��2S�F�1�y�R���<��٪6e�S��C��ǔ(�kAU �uIV�`*�v~�;��N�`��sfu(<!�����.��.b��I�1>2�����Y~,�)�M[0�>���J7Z���b�ú,�:SU�(#uN{��).�� ��Q=���T��K���^~�
#��4��bo�9�-���٘��g"�+�!�Pt3������n���e!�J�¡c��^��y���z����\��\'[����[���i3k$��$dM�3�eC�Y���X�V$Ny�޺�$�u�	k.�M8�n����V	7^�	ˊ�ZW>.����KKO0Y��-�#��(�A���*��Ѫ����Ϊ$2߸��YɮD�X�T�I�����U�^o4{�5��dz��^%����g�񽚵�9�)�5�Q�-�TN$$�57,��W�ĕ{~]�ɼ�T9X�od��¬G��}�럾��	���w�^�.��x��<�zJ��T��Wh�8�]qvTG������x�o��j;!{R?�T�g�~�w�?.�l�j&Q/,��_6����~�X\��8���d�Yo��\l�����qϐ��NT��7FA�:*M6��L	�ʢ&�Vffm;ېe,��P �;����	��k
A��Cv˧�QïS�D��� ���eO(�S��m�ѵ���M~%wI�G Dɔ�G큗��D�]q�	�Dt\�8W��N�a$3� �'���L����}ױ�A[$L)o�S�f���dS�m���:�rlUt=g�����@��%WZFfRɋ�tN�F���kkh���wx/X*�4��uF9VRt]�����0��ms�-��%5��F�Ǫ5S��~l�yϚ�I:��pq�J��
��z�������f��0BSy[I��h)X�W�xzR�?R���� ���[�Ds�G����pψ��Қ��V<B ��0Fz�Y�.���avy�u�yQ��F'T�F�$��:K�c��V����nV���eN2��2�����l,�	ƨ���d�8�h�n����I��Y�̻m��XAչ�E��ѷ�����0B��ڮ��􊳲|�>̅)�p .��ZP߭�-'��i{�){�!�{A� ���2�e����8��#d�rju@3!ֶ$(��x7�
2��m����rޤ 8�G��VS�\$=�����tS��^����pH׭%����gNr[�6��	5��5ʥe�|q�zO��r�(��M���.��D�$$(�Z"���,���*Ar���Ɏ��X�NǦ��:KpuKc!��� f���ݾ�6M �3יbi�8(���q�'�8�nzV�	��a8^��̛ƙ@A2<�սl
ڰ~��γ���S���̀�HDi��xp��f�&K��-cM!Ԩ�n����q��NT/@^=#ĕ<��	�Y�p�P6�i�.X�HF�Px�*SSh�F��2��$Q��H�3�c��)�P�*�s1 ��iQ�I��Z�0�l�R�Sa�*��΄����Z�}k��t��N��K}�	ܞ^���!��r@m%O�� �t_��NB����|fR�ҼiĢMt3_Δi{��S�H@����#5�9�;��ES���g^�Fx��m���D��A�S\�r�;�_���>�*iu��;�pO[vȆ[ �H��5ٙ�]��'�5�	g/���,���{V�B��6��NbUѾ�|�jP�kܤ�_$*(�!��-�u>E���m�E�,�08���d_bJ��CL���>���ߜ%Ls:����ٓ��Y3�K?j�=��
[�8��j���be��%�R?�V��W�$��Ԏ���Qv��_�j�i,��k�?� ���v9�\����H�'��sZ�/��𜏻������gc@G�������֥��]�YNRQe��F��ދ��8����� �b_�8��D�(�Gul��fx�
��k+�=(.')�ٺ�:�p$[⯱¥�k�K�,�\��b�"�O�f�e ��3��M5Lo�/���O�le����d�Q�
s��?�	�A�9�Jc,��g�"}ra2�B�����A{��It�>������l&��Xl	���#����:q;/u��b�I�B�������-X�_-�	$|��^�k�՝��&�a�[�[D�� n�$�����\�K�A� 8�i'6�K"@��,�l�6�@R���p�zj��v��(�,n�	�w�d��� �:yNF>�$/���[�/���(���HC#c���Q������r��E]|�J�����"Q�����Vv+8=�t����'��3D%q�����#ܟ�Ǫ����/�� ��Y+Ҫ��q��#��3T*�b��|]����'-��!4�=u�v��pL�O�g��<�Ĺ�e8���).��sm&<`�jͥ8���VA��-2|GM���S��$O~�V	*�f[$;'���;Md��<Q�c����g��b.&���L���[��\�q�U1v�I�1�O�	|��"�o\Q@G�j����=��j�<��,�:������ZQg���,��A��ݿ�4�yȐ����Ǧ��e��pR�*;��:���K&A\#л�쁲>4ԍ�Rz��Ў	*f���'��3��xc��H���b/��t����@����W}��g�c�)˂��4�C�YZ�r'��"��n�Z3�5U�����
������H�{�������5�i(�S��T
Y���9�>s��4��{*V9sF�P�u��|��ύS֥��ov��7o蝶��x���*Q{n��Y�WC��HI�в��g��1i4��l!`F���`! �;�a�<'#���b#�H�����E���H��O�*\�ڥ9Q����;�u����D�t����Vħ���y����#ߺGA�&ll4e�����b�Hz2���{��A:�݀ ��=mɁ���j5�z���+'g�t�p��R��ڨ����7�����d\v��&�=Wn��b��WWE��Hb�p��*۸�z����d�zYl"�Y*&)�IU�7�%�ʅ2쌪�.�o���zj��v�n�a&D�����e��^|�0mZpw!ᣛ)p#�f�\E�f�B�՝�Y:=�G]�`�'�E�)O()�B�����5���FiϢ�i5��2���c�q�+���vGQ�_n�:��wxH�	ۃ�۬��[�sz*U�'I\r7�"��m[��������7r��95�|���T����������B����F&�wQ-��{ЙHtq�ͷּt��K��PW���\Pw��-��ƸW :��뚍!�4"6K������y��$s�/:��p�E��d�J�0D�z���F'��^t��5g,Вy�	�HoB�M)���1_�7�͹���7q��'����a��.}ݬ#U�X�`���u��=���,��[;���}TD�>y�x���<��3�l
��g���T�D&�Z�D0���)�pOj,~|����OZ�)��&pj��Is}��WTy:o,ct.�@l���]0�,�Ϻ�˙�~�i���ԡj�*ظ�7����HD݋��S�� '��2!l�B�)|�]O��se�{;�qG:5)���v9w�m�v�<�>�����N�٧|�J���\�I��9��P��&5��,���lG�v3QԲ1�f�paE�O30�WӗOm��E0�Q��{�"% �]�[FDzF(3�-�P�Id����I�m�Ow{��g-'������|j�G�­�Ľ��D�#d�����nS�NW�2�{ئ��@��C�R����<}� J�h]�W�x���gL��;Ɓ�K�X�x���*3�r��1���C��3��j.X���;�Ę`�qFpؗ�{AO�SJ������{i��P����T�����h�u�
�k5�,k�v��LH�]?��ع����u�&w��ek/�����k��r�A)���q���o��T�]���rj��R&�����|�w�Qev�19�u�29��e��ON���3���R��]�{���%n�R�3Ti��W�r5�GdŃg<�:@Gu�@a�������{{a�Y_2��H�!�B�e��L�k�V"�����Yx۷��_���]�fo��q�� ի���.��ᙽQ����$�9{�R
�F�`��A͡gk�C� �v�x� ��}k��|3�>2����������I��X%*%�
nW���D���89��s��eO�/��nN��]��rG�Qo�]ˇ穐�7,+Yx! �O@ӌ����� ǥ"�6�Ü0S��w��$k���D��E����r%(E9��������["�l+�%�����ʿ�G���i�K��篅�,F(k8�R� -�Go�hl�p?n=�s��M#`�P���P�$Dӑ��b9��.ɹP�Tuv�_��w>���L^Ɔ�z�2x����3��=�B�q�J�ԹQ�r��)m�!�j����Z�b�һj�>	��7{
�ϙb9����N9F�ӛ|*���<֥�H4܁��p�J��$��`�_Q����|y���_sDZ���I(�L�v���.��\�]�B���L�S�) 9���)B��h�4Sm�՛Т-�� �*T�j��������9���w7d폫�fj�{���<^���ĢVD	 ~:w*"|��HQ $�n��=w�Q}�M��Y�{����RO�UW�	�M���w�^K�x*�L�����[k����
�?�����w��_q��.���.fA���sB�Re���!@V[~�=~�����:��W���eW$3�P��%$����/�7���H_��e�2ܴM����u���Y\�(�V��5�i��]s3�b��])�a��Sa�����es@C�O-�MI�'j�b���{���|o�b�M/o� $�� ��ӭ:B�煮�N��;��>M��8���_u��CǒV�R�_�~'vY�]qF�z�ȡm"7/~�A\J�q?6�>X��TAQ�X��~M��)�NX��ݏ�vF���x����� P]&��Yc�Ux��v�IG��9��ނ~r�3mK�Uz��ǌ��Su>����c��W�@�R%�Y$H����^^�J�X�4�u�)�5g5���T'��а��ޝ�+�ҕ�����ת%n˕́��/`�`O����xʄ����DU6�XN�<�~�5:���q��yܼ�6YA�`�C����ϐHΙ>1!�_�63]m���QӄC�#�2��9eҴ7�}�)��{;�ei^����&�)|�N�
�1i��|'v�)����K�06z
��&�>G�K��>I�By�3�]��r:~ҕ�(ýD|����&Z��D��E	X����i4�;���ⴟ�ieB�-��|~ ,b{�����l�̕uxW/[�EG��ͣU�w>��Ft��V���g��yb����.�l����Ҹl/n4�vQ�T��vfp�����H��D&:��K_��P\����#l�J�-�(h��Zvc�f��#�,��s�NR�z��FшhuG�i�B{0(KQ�еz��ٞ8ӊd�>F����H	����H� ���6���������Q\�]���Ѿ�K�j��t;;�~i�a�}���\!� �Y���ۊ��H�ɩw�V �=���[#�Z:��;�0��W�����υ����X�
��>{��#�`�W�m�%h#9���,L�j��SW9W3K�J��@������*)f�J�	�} [�Ԩ&Aɩ������Fw��x�°�κ>ʿ`sZv�� ��˴�J��[��\o"O�$<u<���N��*��.�;F%w|L�)32���D����A뱎�ŋ�������ڔ��|xxb^�b%���MP��bD1��0�#.��щU.4l�{��ˎ���w�X��7m.����ރK*�e��$n�E���Y������ϥ@b,8�}�TF��c�C��=&P(�H'���	ԺH��m�5B�`�Ĕ��7�$(糇55�`\��zVX5	<�UϪܒ�k>���q9F��%uY(X�ْ�dxۛ:���W�� 8��4K���a��S�+4�(�́�U��{�{]%����)�ź�t=��$굿����ҿ��^��4��N�����
�Wζ�L���"�qN���&�E*u��<ݔ	�P\��E'��z�5$Q���� ���Q۪�P`�nl��ަ�^:O�6���Hv
���G��Lf#ԕ'�����y���j��r�lywss�Vo]!d���$��Ym�cCh�CZ�u�y�J������Ϙ��@�)*`��ף��� )�j%Kf�7=sX�&������+�������<�1k�L"4_�P���p��i�J�-z��O#����.Ԅ*?XҰۤ.4wm�����x]�s & �Q�ɺ�*m��!�M7X��k������Q�V9�e����H�C�}R��\�	�AAOP2-t��GX�5G������M���0󪸤�m��ͻ�a����R��)��B�G��`𿧦�OI�W�rv��J�U��!ب�������0S>�^*�Qqu��0�:����d٧�/NŷM�Q~6�W�X�D���d9�q��q$セ���V��3zHmG@��BN��)�\5�D�k�W�H�(ٚ�}(��O�aq��[|j[o������+�ȟHV`_��yAA{'��{vȐ�@��ǚ��3Wah�%��cGc�ɒ%���rc�.�ơ�f�ߘ��p\�BC���g(�T��Y��ۨiY�q�������j��+���� o�z���#��tI ����L~b���-[�#��>*Z���@u!5_y�"�QY���a�bK���2�|j�:0�.۟�li�
\�h�U����t%Ѕԡ��t8 p�濰�6�skGr�N	34BL���J��w0f�)slu?z�sW��SY����FY>�̧v�mv���֍�Ŕrq���N�-2l1&�O�z�5b�'^���z*�:��})C����zB�l6Qx�F���<���f��T�v�o�7�M6���]�!U���?���1�]7L������Tj3$����X& ��ץ���0���"_��@$��������U�_�qȫ7N������aMlz6=���>��a4��'dC+~���Ӄ0r�*8�C�l9\�j��%���#���g����r�%,�y�ZQe$��,���n)~l��%��eR��
�8�X��⺍�͝{�Ϩ����S�2���hhJ��]�l�1�܀$�H7�N�ٔS7�p�,���*di���S.;�W^n��{
�R���2b3��e���z�`�Aޢ�ق�^D ��a�`�w[�nP���}�)K��|8�' Fa���ɠƚ��_��/����k:�;��$���2�+n�}>�;��+�vΰ/��H�s>�5*���
�k�Z$"���ۊ!�1ٳ����M�S��@!�����w�7A}
_��������׮�WvQ@��ڶ���^+4"�h��#Q{kFv��@�/�(p\�) �J�y�~7�8�x���OB�q2Oj��X�+�wk�g#x������0��pZ����7��0��Y<�)�fw���J+�4�M|��U�Vm�L����O�{���r�Bp4�oR+M�K��y��* VIPzKH����L������{FO-<��%��$��ݚXkbG���sJ<����3��d�ZG�]�>Y��Q�fꌑ��;n��kM�~ir>u|X���	�Za-f��7M�:5x8-;��T��V��4�	d�
S`��+]U*GL;��!�u>�b6�6�+^E�I��v�W�Jb(�8y:�YD���O�,�e�t��ٰ
Y��B}���-&��������(s�����}��+5�H��^�T�>wA��Ȇz��ہ�p}2��~���O+1�|�>�`�F��M���]e��0:�D`�o'�a�y�̀E}�s{�2�)N���(RSlB"���a�ȳ"/U?�A-����,Mi�/p��튷���%��CT�R�d����,�Q�s�T�e�S�:�y7ZuR���?[������V�%椥r%%�e��I�D�:�l���OˆTg�h0��'�H��oC���l�ʪ71�&"V��d[�ix\pu�������n�Tk�3$6؅������7��=[����8��پ �+�U�îzKi�A-U&���L:}؈�ƣ�^]�[����fX�o�9oԑ��1�&[���^���v���36P�K�2�[;����Lb��{AL�y���!���,w|��$�5�����H�_����y��>��S)6ľ?���5i3˂ql�4cG�d>�L����ܰ^"�Z����=���3�wƖұ=���=�����%q;	����D��96f�u�zM�}�u�5�Y꽨k�R�6B���}�&-���E��$r�<;�=����c��l�d�]�����F
	k����\,��r�$9��GV;�;�۠Y����4����\Vc�\��p<-�.,+�z �9a�l�hR*&a�P�z�����g,_�3^�)t�JȈ��I'�Ze���������7忪L@���ve�DTɴ`��ʅ�s�h�I�����.�\ԡB[����B�R��[� h_�=k�}T���+ �L��>�����n������A�w� �E����FՀ�^K�|m4��]Y�&O�,� |���y'0�	�\��x%A���"A�kq���??�8w[0��!���0�����| �wL�r�4lU���^�8`$B��;�#I�܊{Y��B�]I㼓�I��	�Ӷ�>I�#U>,π��L����V2�e��UsQI������r3�%'����|����A����D���t�*z���Mi�P�G_] �au���X8<�����p�����3�MszR~�ouSU
!�WnL�tǻ���_���a���u����E��{������X��yU�M<r5ז��aT�#۩���V"�r�ݼ۟�����Pf�8*�)��2OL��QX�E*�7�W=R��K��4,IRe�b�#6uF}Åea�Q����Iv�&�,��b�JP|&kN�d��(R�9�VC�﹪S�z�6��o�c�9��e J묈|��\��f�u*I\�Ks7��] X�?��`�����s�TGXO�/�qp�g>�U����E��MO���h�nz��n��Q��y�E�eAr����IU�ғ��g���j��c؎��> ��dj��\O^3t�V������ /��ˠ��ʛN�xδo$�iA�5��?|�8&Q��k��$%U��ù}9?�aU�t1?8���IY����hA�
�Ԑ��s�p����.�i[K��E����2<t�cai6���h��D$��Q���BI�ó���᪽2�fMj\D)$���t bX�M.t���� J��O�����,��a\����X}���ē�k�����w��u�Ap�h頵����t1X�s�$tL��WX�*
5�A�#ڇ�ޥ��}���<��v�؞"̯qX�6�dqӔ��+=��p������zfd�(v����
�%���9���fX�e��g�-�o���Zh�_��Q�B�w}?���־ՔI�]I�"�%Jo�5����Y_[�ł��x,�s;���{>#x4H�{�]z		�j*9Ol��	X"�1%H�F��j-�ďV[��-ht�8f~�Ab���J02j^D�o�Am�����w#r�*������4�za�/	s>vә�`�0�7h��L��R��n�;��d�gbK˥�7�j�ߡ�j_K��u3�[���D��G�FAdY���7�F�4���/Z�D0N�A��E-�>*���TG��m�p޷}�~Ğ�Ti�� (�	&F��%�n�\����I��G��\�_CF��N���KX����m��Ӫ�ʄ��Ab	N&���Z������J�.Q��10�9UY �8�R(��s������_���bj7�r>�ܖ�t�׭hp��w��cz��`o>�9�p��Nk8�g	�X] ���i�-v��??A�1E�����M���:��y��F�!�^ ]�ʗJ�+-K��t�D��BVp�"5�}9C���B��ʥ8��q�u��ut��ô�����-e�I|�bF����4kz�L"�_��b��>���|��X�*�B����|���5|=L7�٧�v���j4���8)��&;#��d�:�|�W��d'�A;�OT��ڸ�6)Wyad���_�Z�bG;,tj�(-���'V��|iu)cI�@m� ��H'�K�����T+o4�����F���������n���Y[��v��wW˖yh߻X?B "�U�Wζ�t���)����
��)2Q��D�9M�ܥl^�%^'��'L����S������g`2�H}�e��v�7��w{������֧heֽM=lȏ,�ѐ��U����e�����B��9=�<8 ��]���|��by[s�2�VФ���.띟�@����542Ż��K]��tNE��ӣgdy����H^:C;V�X��d&�Lcaj�Z&�y"p%Y���k	�W�ӟN�ګ�0�uE]D�IQzc�}D�^@����U	�+�<��*�
_�� 2s��Rc��æ��i�ri�ϟO5}����z�b�2O�8N�q��N�&E0`�[g�7�btȥq��xk�����.�/��ռ%^��b�c�=�JL�TJ%
pS��?������h\����ݨ<�c��zA)�=NǑo���}�֫���s�n�8�&���ʰ����3�^D{3���68�<��!=��;���q&�-U}�P�EY�;�@b�������r��}ʙ]4[��Rx�W>j�o�a��j]	O�1�0��(5��*�?ޓ{F�'\�;�3�b#^� G9�.;�>oy��"���a���B{�U�F�>_?���T .ů��=O��]�	U�F9���䨎J��9��E�N0\�Lh���pNN2������s�}Ϻ*)UJN�P�fk%m� U��f�}�D%�f�������@?��w$��h;�4�WRix>��QC�Wd:�m�qv����z�jk�R!���e�9Z���r�r��0���mTK{���н����Z��Z�gyk�E�%צO�JZ�>���
�5��W=�$d�𻬎1P%�6�M�ۭR�S�.tq�]5�x+��tX��e&l������Ź��ӟ�`JQ�I���"��?��ׁ{t�d�0��3)�v4AW�3�9�0�����A��?�?���=���io��T��ݘ�Ʋ�=�ŵ��*��ކ��0���_l�0li�o	1Gɤ���'�2���C�#
��ӛx'!��}�d��)m?��Y�䖹�F��L��bo���7W��-J�@Da�NأH�'{{,߉Vr�k��
�O��yU���y��K��7��� �w\~V�qS���gs����"�\_��Փ�$�	b���l[��]C^�Υ=Gh���.�E�����ߵ�9�L�5?c�j9��-8*��<x��wBN���Ȉ�Wu~u�`��f�*�u�4a�m��뿇5	8㪨�W@�`-����$�Gx�8����oQ$cj����U�?
��t��*�V��ҋ٣m�i,����(�`<�ȯ��N�Z͐����s����ʻ��baVJ���_�R��+�dSv���Y�~�W21?���b���e��/R���x��C	�3<Yt�����J��5�Qщ�bAk����t��0� 9|I�}܋���n7�IJ�x�
d#��V9�����N,!WP�{ kB&���I����k|��cC��}���0F���[��;�ȋ$ޙ�6A�k@�����ЎB�~i�~���;Qg��`L��D������3�v�o\����٨��.�g5^��#�c7;-�G��IJǡ��ǎ[V3K��?0n���������@��Gַ���m���7�H0��y�0l���z�4�_l��`Zk�)�d��Z�XM��$�͈�F��*�w�U�C��0���8���$71��Y���~��;�Te93���ն�L���U��RP�ؒ\��@��Ml��]��E�i�B�6��ϯ��G�03�I�Ac^�]�Etf��V9�b��8j3|���8��'�����0פ~���L�M,�14A��a,@�b�b�ǌP1��2tz�~�
?�09�H�
9��!�C��(�9�����I:�Z�ܻ��m�5�δ]祜�����oY�,�K#S2�!�s�sA[�9�i��2��ʐG�z���)m��8t��k�r��ړ�l\��Y2,���м�'��d�(�z����>L�j�ӱ=�'�3*��^w��c�[o��>�5E���k���J�3HR�����Ӂ[��m�ǩ"0��� ��.�9�fF�<ąR����v�>�>9�(�>�p�GT��,�"e�b�S�YF�k >@2fb��~�I7d�Ǳ��Ӱߊ�yפ@;�"��0�"0n4�v����w�(����W�������M���>o�Ǌp�=R��ld�T��m�8��_�w,�>�b<d��B�Gq��|W��N��x�?�q���K#$�c�>w�iz+�;X#�o�J
��ѿ��fMe��l0��\
�
�|��#�ey���� �y�C�@"���"Q3�������T��J��������',T��@�	��~��w�,�!�X��3%C�\����_���M�e}S�u���L�(�eC*u_:5����a��L�D�ii�������l���L�?3ͯ�����T�v �}n�/�]��S���`��(������U^�G~ZTJd��􆹺��[�W�N���q�\"�6�LS(_b�t�
=-�T	E��G����o���Ơ�����y(a�`���@��{-�H {�Q�	�%�1�i��k����,?��t�o0B&}[��)���R�>�(D����de�7q�&7�}I��{�K��DE����g��@��N�����<s�'g�寗|D�!�|Џh��n�̭E򯑃���%�hǺ«1̶�G�X���s����5����:~�V��:�Z_������*����u�I�����R�v�ԓBiĪ��hNsQ���r'0�����u��%�B�im�*Ǿ�����zq�J/k��]O�*57>����)��h�px���C��m0�%RކL�ʦ����h��X9A��L͘<��py�Ѳ��LUY1�\E��,��5B���u�kQ���݅�c �S|!G?VyG'� i��:6C O5KףPI�T��z�]N��g��Bi�֝��B����1(�
5Hfh���y�b?0� �SQ�ZrbN���1��C��L`>�L�Z��-.��,U���\�����r�����R�b�"�R?����:'��w�f��3"�p�\�H�C�e
̬�2_��,�n1��j#��G�a�Bln����6ә�����[��3��W�JޙUf���;��	���=���l"��(7M���&W��b x޲rDo�3e9�oZ�N��~��e���O�:V�*V�d�����7����]��$O_�dA�����j�DT�!aϛ���D��+>)�+'��Y�Qc�����\Uz�� �=hr�ĄY�d�B	#�B�5�r��ˎ�p����{��p�?=�{ʣsZ]C���z�HS�&�[R�4S���r�L���d��'����#�A��U'��^K������c�ZpRk*b�ҏDq0�9C��v���Ko��*^��f�1�M��z������3ʶ���^���x�C_P�&~����*S��<ฉ�^p�*�8���\�	ka��`��ɿ�xj���^��5a x��;@����E���@��V1�F��Pb���&��*�5����:��/��P۽�R�W�'EN5���<x��C��Z�ҨLt��! �T����	��	�w#�e�C�,�H�I�dYF-ܺ�$Q�xE�ݼ��4��xe�CPms%(P+��Vq־��2��Ij��N`�����X]�tQ|�^Cﰘ0VdʍB��h�8P�{�Ī	��N�FD�K�>!M�=S�S���v9���6y{-�߮�Z�]���b�U��:�SJX�<���a/@Z���7���m���=�2�DZ�-��U�$6�����h��DOw�%'���u_?:}!��Q��U�2SiԿ��F��Ě���I%.�!�sp?s���P���Ϙ	ѹ?��TO8��p �4%IJ�\ݓt<�æ��^f��lO�"��J�C�:�cʥtn����t�-���g��xrK�X0��Dg�u�c��4��j9���)��Fub�^���uE#zB�g�rF5��3���p�d/�ɐ���M��H.U��g�����}�0���1$�0-��E�A2��A�|D�v����%�I��7�=�����S �N�#��I�c����N>��O����;�P"�J����7Pl<����?2����4]�*D\�Ŧ���}"=������l�:�H^!K�6���Q��w���Q�����L[	3v}����;�y�DG�p����rX�{Q�%��c����.�$������xIg^ǎ4�G>�9YQಥK�'Á�y�w
83�C�i��b�ƀ�e���%EP^�f&�!�|�p&� -���펎Ҷ몬➘���+@��\[#q�=xM*�ז�f�3����u�>j��bsB?FN�W
���`� ���ht�;�$>�����E��{ܘ��30����Zڑy]��,�f}��g���*��Q������WJ�L�mm�Eb��Rȏ�ӥ�;Uďz4�RZ�-etaZ|.E��ӊ��-x<�L�Y�j�3ǇLR���`-l������W4)'�wC�Z��\NG�\��5���&v�]��/��*~<�7:"����b��8?�W�(_0|*u�lX�'�.C~$�;~S�71���J��t����Q��XC׭5E#���֋?��$�ЀvXc!tq9���R#N�p��
�t� 	&��w�P��\�_���9��Ȇ��b�,(A�쉃(#-�!�q�s&�C��|�t'F�ͳ�0�ز���k��ݐ��y������� �=O!B�t�F�uc�7fh&F$-��$�/a��g̻<��Mil[!��ؽ�:EE
�׭��������ۅ��o��a$���!hؑ�3�wm�+��NV��jz�}�eu8֗��Nbk�~��5�Sa�s�fC/���Ծ��N�?c�1�Sn�a�9׸,.�����8�tPteu�c�"��U��"/�h�כ�"S��jߺ��;"Q
r�<o��t�1P���J���E����Ҫ�Q���n;������*�.,)@>�}��d rb"Æܤ={}�%�K�`��6���]a~�.X0%��e˸�p��k��.��i�Y%��Y^3���%�4M���(,��Pv��)r
3���̲���r�F��-�Mx��ut/�g���}d�
�F�󌷥kuu9&B�a��EP�����s� �c���7��t)R)��A ���o�ˤ����
@:��9�)8:rL6:C�8�����o���O�+헽��5�t�ϛF��ɪ]�����|-�,�H/FT޼"�Kû����T�RS��1 �1*c����)�51��FL��*,[�ױ��[b�"9L��<1�2�`;ǖ��
�/@��2��@��Ĉ!�4/�f�ٵVf�H*e�-7
�gU.�t ��.�,SmT^De���	h~<�\2�eGj'�e��$bp9rJ�|��H�!�A��x͐����.���3l@��hOh�LN��Q�ʆ�x�4�Z�+������j�:���?c�*u�f�\Y㍥�\���ӝ�ج�����m���Ŷ��e{��{R�3A=G-�O�$.g���c�F�RxlF�Nd�dK䩺�ZE#�^ۈ�8�a�I��'$�������)8�sZ��B�m?��Y����n������wO&���>�@��(�q��<�<��Iq lB?;WM�Rϧ@>�����
�~D�M�����(��1��<     ��rl�*T ͞���%���g�    YZ