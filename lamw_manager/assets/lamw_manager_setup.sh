#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="814138104"
MD5="62ffd7fa13180200ca3546ac3e4705dc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24312"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec 20 02:00:40 -03 2022
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 140; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
�7zXZ  �ִF !   �X����^�] �}��1Dd]����P�t�D�8(��#u.��A�n�(S����d���kC��	�����N�=')��UssN ?�5c<���ڲ������������V�1 #�Z��q��f&t#u�&�	|rN
��a�z�#�L� �r�0Ʊ�%+��9�l����ED�k@m�Q��?��4�Wc�z�Z��i$Ǔ�SQp�埝��H�u7K���:�Me����^�Z��һ��n�˴u�3Q����Y��WW�ȕza�	���S �$���R���T�I���Kx��|�f=���z�����Bo���� {z�jm���K�Q�}�����)6�.o���B��+$��M8�
����>�zt���3�fL_�!�ufU�D��>v���L�e�D��ړ9�s�.�q���e���"�O��`0��)Cy4�c�&|�����jɸ�P��nq��M4@�+v�hn5T-�I��_N<�9=�N��g F�f÷��E�}�ĩ���F�׼O��5B����_Ցi��_�o���V��P������h
q2�%ɋ+�!Ў����J[>�r���Rc�_���Q�ئ�T[�%돆�B$���W�څ��'U���:0A�0����<-����U�VKrn����2���z\oR	YE�tO��Ň$�5��t;���j��S�,��GA���5���*���w�U6��ڐ
D�.��O~*@E�Q��݂����&���_a�;�9~���&%�B
�[����Di�C��b�]��D��xK8�V8>Ὄ�L�wX���:�/�P�Ƭ6��
W �V�#�l��}���@p��l��?p�pr�|+u�Rv�j��{�Y��>��!dc��p��}��f��V�Ȏ����<�a�aB�Mm�50�v�.jǬr��"��d�Y&��N;p	2 �-�;+�¶�IJ�u��"M��fҔeS,uu"R�LTh�V�n0�2Y�F-i^��@�z�����ۯ]�[�S�l���)���Yt<GOg���KM�6��GJi<�����Y�c��J6������	�hC���kXځg�;j�G�D��USIL6���7�Q��E�,�]J@����:񃮍���.��!CW=���ؑ���+�G������i&�`:[
�=���NK��� ������e~-'@���I��u���]M6�>b/�{�"̞a�n�Y�g7��|��*����H�o?����AUe�cqL\�G�}���$nI�K��J�k�A�2}�l703Eaq2_ŬD�7�k���n��N��Ʌ�0�9��#��G�$Og�5�y�9b�=zL��3�"p\O�abѲ)*2���F?F�jMOJ�xe�k�e�׍g��ĸZC������6/�6F�oa�a��zbA8U�+�A@(^QA&��1aqJ3��ݴ
���  ��H�wT����&dT�8J!�y�:G#H���u� #K	�p:/Z����0<�C�_�8��<���S��t_����y��{�K�k���4J�n ��S��sPm_%MJ/|Ý��<���'�\9۳�#dԜ��D,H.t���2ؚ��Ϗ_��b���i��W	��EZ" `��`/���S��;!\��8>y�����b�*;��,\�E��ʪ�9�iG�M�q��D���l���u����ÅC��so�X���"Awb�Eo4W�_1��%��;94p�Q���u%6?NdB�!���4o��Af�g� ѡ_2Pi�Q�z�]B����M��<�m��&�F�6>6DB���Z�X���ZxHӜ�M89bOu������I�G���—>��FH�6��U�20`��x�K��VD��1��)P����T1)�/7�P���������V���ڦ���*����{Z�iؓ��jW������dQ�c�w9�F��-�a���=��]��X�����2����� ���<�b$*NS)�Uk�ʨp&`�����q!������@8��ѭ��ҍ�)��Y�l�V�DF��Ǒ���]g��Ys#f��m��K_���w�e1Ś�� ^�y��ԗ��%h{.Z�;|R3y�{��fP�jL��#�.H��
R&r?�G^R��pȢ^�SZ�xs<`�U�m�H�� �00�Ӂ�w\D�b������|�cP�uD�/�]�^�ϫY^�Ɩ����ng �Z,�,�$�SS�7A@��f�S�â�.�nT�!7�
���4����-,�E�����DZ/��w�i�g!�X	ͣ	[�����v&Kż�i��؍����+�Z�����+g�\�U���U$�=��sd�	����>���i3Z˽Nx�|lπaOH-G6t
`�A͢�!�|༖�j}l$�ۖ��;�;I*)�!��9R��J]�O�k/���Ҏ�I���j(��ĵ'�r�'�HYs�v��F�t٥��3�ݮ|��nZS�D[��ozMS���3�5��e���|:�
'���䛔��&;)_�F�:�H�����A3eg���Av���a��>_�W�n�*̥C���G@o}��z�\��@�i�>~dkP��K����Si9�<���}����Y�&Pq� ��VBڌ~�aO��jI$>.Ӗ�# �9����RX�fK����-%h���dQ��m-��v�4r7��ɑ/�	��.B��qIm<N����e`�+?�WI�x�-��1NQ�z={w6ĺ��te.,2z="�
I��c��zڲ��(���g ���@Б�{���O�7m
e2(&�PV2�Fp�+1A�Wm��x�|)��p�ʈm� 1�a�y��/B�Jg0y#)R�_3�3�@�h�v���M`��eq���d�t#�ʃtES����� PP4y�n��Aw�����/7G�����Pz·# � �ݦCW䞰�b������b�	�	��'�����\dƚL��g�W��,)$MbXl+���-��`����<�ǹUg�B{l[�vӓ��ȏ����%۵�bÓ=	_��U0N��U��RE�!�{�h�`���G<�y��d�߲�}�x\i����B1��<���N�W:' ܾ��*�,_uS��<�>*اJ���Z{G��H��F�O��oyTC(�5gz;���6JNT�&!�`�:f�i�D�U�K��{��z$��	��x���.��Ǟ�|�1o�-�.Qw;�m/�|��!88��{�j�?�����brF5��O�4��;���"��/Еm��48�v���0C��e�i2t�D���"�l��ī)Ő����7(.k*0M��iQ�;�=�ݥVVtgjWK���-��p��MB�)�L�n0V� �KI����'�۟���@O��Dǫ�F�X�(�$�t�^�H�G��ؚN�tl��M#f�s��TZe�?�_��]Ȑj�=bW��b������mX�-v��)8R����౓��v�OeH����#sĦ�@/�I�I߹�k��N�]@����ЪXbE`{v$x2�1�U��_�}����#��YS��85!B�_+�IcQ�6�s{3��G����ƀ�S��^��os��ܟ'�$�ui�bl/�;�����zэ��
z���N!�+��Y�<���Cf�~��f������kZkx�[���{~��#�9~��,�v��sI�?W��&\d���_��t`ؙ�K�����zU|�*�jQZ��V2�`�F��Xc��g�PT�������'�R'�IQ��ܩS{�1bq~�TW�<c��U�2X���hgZ��*<چ��:�O�
��A|�w�gz(��)F²�ev���� ~&�*X.� �Y�XE^�=$�e#v����d����k���3�j2�K�P�h�8�`,��?��F���7Z�UE��&PJ��z��=#���d��L������ˋ�`T�kz$\�X���&,7��O%���ݷ�#.f��b�&�z�ـU��"��%����S�(%�.t7;BP����d�<�3>;�k�>RR}����A�Wl��T�� �<�I�C�
�R*J��ﴯ��3�iS�oP���hz&����e��X:M������K���5:����e��@�@�?8
�=�+�Q�4��ν{k�i��r�|���I��D�}�M�w��MK�����o(�o��-�2M�zPc_v�娶_�	�+6�V���}�V��V�`�����b؀��Pj�h'��X��U���_ �Xt�b��F�-i�-m2�W9�|O�!��Go�)M|o�ID\�B7����՝����9|(3�p���Ц�P��@YS¤�Y������P�K.��#g�%�N)��oo�{�� @�;Z�ݲi��̥-˰f�	�~m{(�N����9����9�]�X��g�e�,U�M�;�67"���	�����K�e���?Ȏb��{F�M���b�[X���_#��:�|֑39�\2x�]!�����q6m2$q�3�|�?�d�~����5]O&�N�Mx��X�����%y�øK�ua�yf=�P�契�B���[�ZJj�k*��t]ܙY&��m�),���ĝ�x�c*��:��{���Mg�r ���.�w�ʣ�,��r�(?u��6�%��� ���,�R�v����?�TOb����8�kp��w�z�h�/s�YeV�x����ͧu5�axA�1e���\Q{�E�;4�3����z�f�l�I��#�}o\>�DyR�❹�U�}l��|�a�DhGz(�����2����G;��7WU�>Q��8IP�n�OH�]���TI�!�?�d��%�`M��{<$1e�2�ccJ7���*ԑ��d0�i`<��@3/���[k�i��=��(�� F�;+6�8�x��I*�௻�����lY���9+��(
[��xV��d�-]�D�"°����W�c���>�/(U(���\�7$e��1����~�8xrM�J����g®�/��#�Cgi�xXu�.�L��X�]G4�w����0Oه��~�c��4��z���OZ�?�~׽�9�Z4O�%:Z@��aTEK��|�iD�ݿ~ �;=��c�}R�z��C\2��ef㲉{�4]-��L�[L6�.���r���=l����Ӈ��������zD���)w��%� ���4��B�;�NK�pA6�ߛ�vB#L��*\9Q���v�[��o�Z-ۗ�NKx�u�Lg;�m}���
AsuV�K>��XK켉7'Ğ����)�19�x�0w��R����x��e80U�XN@� JO'��6�I�c%��w75/�'@���ق+��ɤ<b��]?���heX
�ۆA:���*��4�k4/�l������%���H^��&����r�@��D{��d�bmZ��&��8A���E����v5��SS-XD3�/e+S8
��û0��~!3zn)#,��E��A�^O���~>��������\+�!�p�|��GC��_�ԭ^͛ ^�\Ŷ�,����L$�R�0-p���{KPS���x.(H����y�Ӿwww�5����dK��`?�$8A�6 �Sl��C��E0:	�)!���`��	�[�@X�A[�J
�dD�����~|]C#�BN�����"�|�H�yR����Z�X	�ٖ��]���	AS�.wզ�C��fƨ��>�Kg�1�Ly=,������o|��Z�H�a�-b�M鯄���k�Y�w���׵4L�/4������k9
,�3�Z���#%3��"��|́�$��#�:�������0����ߴe��� �h�V�o��3����_\ذ�,���C4i�R�1#�i�Y$�`�|��,��0��\����QM.��>R�%�$��t�<ɻ�5�h�K*�-�Cj**^^�U�b� ����9���)҄�qG�� ��1�b�\��若R`[��7 }�/��*�&N��D���aF���$��}� �m����F�h�Nk�y	��=�lZU�S�mwItA�k�F<Q���\I_?�3�?_I���i�IB�)�������-� <��d�ˡ�s���z�Ň�#Jh�w�R�Ο��m[����"�iaT���!�`��{,��W��D���W�h1_�E�����̬�k*ұ���@��H*�R���Z1�,��d�^m;�HR��� ���L<�D�������W����]�9i@}�	(q��!>5ܒOU��D���p�e�=����C��g�=TCe�l�+�9$����i��B#�����\O�?�,{���Z���. j@��;�%0�5jw�q	�R��vң8K�;���
����D�J�Qd����j_��u�O�<_��2݀b���L���:����]�����VJ�Nɖ�Y�,����%�El��3�p�Zⓧ�P4�
�I���bd��A��tn�+)�IG�Z���0�7:l��d��b�8�/M�Û5�T�Y�rZ�!ڒ"l�p}���Cv��)�r��1�R	�N'�~n�
��sZ�j�ߕ+�'�(�D�ng;)�`\��6�F�軞� �xu�N� i~����8dj.wm�� ;5U2�)g�XQC��"1�J�S<(����E/�d�7�"y�D�j�r�'Ƽݠ%�#������G�N�
�Ƀ��B�鋝�=$���do�~�E��w�s�{�a1AY���<~���2�=	�8I�l�&�k]zɀI��0�WԚ����2e5:�Ûdi۳w�r!�!L���o��!��Z�!ou�[���0��W-���R\ޭ����l��M1���*%�4�"Z|rlA�(5�'[�q�}�]+��Тx7�����������S��r��᷇	#��䤢|�8�˽�ִo���)��僻`Y �#[tX�������+a��Q� ��&^�����(r���� �{nw4lJ��|�mc��(�k'���2W
V'J�E���
I.�5U����K�(/S�Y���~�R�� ƶTĜ�&���L�dT�|��#��4};�}ˢ����r��nh�CqaS\�&�=Ø�c�7����`g侢��/��l��������4JL*$6���e�_�!p�pK��k͋��A
C󰉢��-	X׺a���1��=�m�ZxK��6Qz^N+#�'�|Z���d�/��4GXnf�V�x�0������K���ߧz�
I��H�F���ǩg"V��CC��&GT�d���~۩�a\;���aw���?���F%0��T�	ߛK�ob�U}����Ѽ2���}�VrH�%deW;S���Q!�ƥ8ka��f	���)f;jU�0�mI>��axg%/�@;v؛b�ku@S`�� \���Z�i;kn�Z�ϟ�ΪH�(���bn��ZL�̃�_���e��CP]:E����5B6#u6J8&.�h�Ei+&�'��;�j^��Q�>~�g�՗�=̰g���i~͊�����$r
�^�_��8ap���տ+t�n���Bلo�ǀB�$
c��U���<�w��܊��D �b�T�O|��2m:�#n�E<6�	��4�X�2�K�4�������dH���`��� ÝC�{��/��܎\DF�XIoJ��jh;��_>�o���8��mB�A�ȃ�&���W{C%����hr��HOӱ`���j�3�	/�����F}����]���T��l1{E!*b���R� ��p�Y�Ax�����tp�n��%�8B*�4��hL1 �26%����l���W��ߡŢ�,�Sm�kШM��#�E���EJ����+����:%��C�@�	�K+�	�"ɘ�im�yz���`X�	~]�:e���ַ
�2<�d9����ps�G�%H6y���;�,��^vC��e���s�P/�شW�y^Ư�S���1�������}%�bZH�̢ؗלVA��j���4��c�2v�6Q3��ϟ��[��0�a�a��>ݘ��`���3##�:�r7�z��	#v\���@���ȢY#2�䘮� ����Z�E���H��ʽuD.����A�ht�䋩(��p"�x�+��f�30ۻ�w��[�3�_�Xr����n��%�q���(
��d��C�7���5��Qr`�L Q��s>��s���, ��ݔT����F���z=\@�<G���?�<t��ۊR5<����
1H*��MP��i|o��\��t�ckI���5��FS`�f��t`��<+��\�� Gȋ	�[��U{����S��ν�m}y�s�\�ix���#�Uf?��K���-�ua|�LZ~��ͼc�M���qc	�x��Xr#�̒#��/�nz[���������_�,�%�`��E�,U(M�6�Φ��1���v����)>�hTrIQ�=�+��R��5:��c�c���a#�����.�d���E*�m �Z1�We11_%��m�t������2'CvFB��ʏ��������|�z��XbX��9v��Pu��_F��=W��Lߡ�� ���i�"^��r�(�lo�0�E���W�UȬ�ˀ��P���o�d`�ቩ�BU�sb�2\�	����4b|����\���MSMp��%d�lV���	���MM��������]5$f�՗[�������5^Z�fٓTa	�R'fY�ۮ�<����hK�d�OL�S@�Ќp���iRc��#��6�i��ZL*F��>�M�2����X�L-�b]�[�Wغߍ$����!��d�jZS~�Kn�|FeA�`�VN�H�2��*>14"W����	�����Vo禎��?$S�d�A�5g�5k��ϳ�V�Ѵ�Nil��\��8�ڸJ�*hF��fD��ҹ��uyEB�]��'[�~K�,�a��K>Е��r���Z��{ݸ�&Ѷ����Q�h��m6p��Ml<��	�PN�.�k�CH����0§)�q
eP`^w"�W�e��	(�� Y�HQ������˿6~l�����(;{i�����[z��ù���6��)�2#����&�O��"2���J�B��L2�.�4P3�A�=�׳cڢ�d���Ԣ�ڕ��줧d����7�(��;�<���Fw]�#u6�Nx����J> ��K�w}ű��:�$H���E���x��$��&?5�����u��i�����\�M9{2�����Z.ھ5�;F�q���R���r��Ih����/p�	�+/���'/�������:ж��pUV_��L�R$�%�X��M�я11���x��u��Q��#iE����ՀL��t����G�{I��M:ٓ�)Rmb��1�g�ݻMqˮS	#�Y�'5���+���L{�=�{-�)Rݻ�����u�f������QL�	.0qp�4�eE.ʌ�|֥�^ۥ�h��]>l*��RO/�K�6O��b�SSğp�^�?"R��б�g�����R�Kk%�)�Y?n׎��3�)��"���Ǭb�qJÕ��W5��Ž��uͺ��0��l�8�洨@��Dz�v��BB,�ֆK����I,	��~�!��5
��7@���*���_�nsg�)�H���=����紴&�,W��*�����i��@�9pEx��'����ҫv��[��:<n�z�:� ΁L���lRm?陌�e���<�F��覰��R�d��Av3��t�l�m'h�݀��j�:����I-yfIy�k�]&�'k�q���� ��*y}��}��� e��c�J�-t߄������&�;��M���
�2I���s�#��`��~/C3[�;f��B=�v���عs%aǐ\���]��Y��3~K\a�a)�I�:����_���Sx* ���z�����A<ҖYU���fJ��v;֤4���6���D�T���k@�\�"�r�Lf���>��tO��0�J�5�֙Й�9���]qn-ߣ3{IݞtHz}�m	l�>b�[c�I��w��M�o�.��ٛ2N(�?����t�F&�0y�H���#��*^����G�6Z�Y%�S�Kj}Й����e�D��G��囐�#��	ʓ��7�*MMo"N�����{��h��G�Y�b$�D!�"����N�p�H�@�y�6Y�c�؛���Y�k�"��U�F����V5�TK�8|�o���8>D�ui�g���^��A�$��6���Q@9o-{�ai��_>F[K�v���K��-�y"��ȇ0At+��/���LC�t@������p��Pna9۝ͻ�񿱼Z�<����n;��Q�B�b���a&f$�����~5ˈ���Ӿ�&�H��HH���DHE���	н��ɵɺR��1�؁��Q�ͻ�K�����S�P��+�ۧH
\���3�����FW�	o4ry�nw�A��q5YT��E�ՈN���HAg*+A�����i._H�R�7��3�ȟ�q�&B/��%v��w��R����x� e"�����L�~��
���@�$����/��1 �^9��.mp��0x4�����f!�J���qj�Y�)]����,V�s9<� ڭw�>�b��^�m��Y�B�W/R��U#�y���i�(q�M��+���N��C*��&Cn�)��b��2vӽSN*A�b��*{�T^i�h�p�!��t����( q�6Դ����)�ˍ�gC������gf�)��r�|�VQ ���l��V�dG���.K�kᙁiN�G� ��x�
W�I)��T���D`w@fD�� ����)����*`�`��̓1�#������{�¬� ����EQ���޺�8��D�?��]%����Z��Pdk�q��V��rh '�)X:^��B`^���c�?�t�(̄��0�?���u���w��'����Q���#��F�
�%V��G�!������3�7�{H-����pL桬�f7֧��u.��k����@=|�儐K#~���Ü�o��*DVp�0&�׉�ޓ�}j|5���>#�����K@�c��uh@f���q�r�l�S_1p��6����q���nXE:���TѶ�r�p7����XΤN?/LfH�d7I�i7�S���i#5�����#n�C-�ka�諣)���!���Ru|��sv�m>5j��D��r�=��22����6����5r���b��d&#�L���O]�W1���S���$/&���e�k˅��0���nG9��ˁd,���r�/��2@����仹)jmD��dJ6�8~�?�-��I�O[$��/�4W�~��I�2�	otX
lH�(��~wda���U�т$�������[w�Y]T�M��-	!1���͗H�T�]�m���$�����@�~���>N�,�8������Tg�O|�jv�����_�<4�zNۃ���U���!9_d(�-�Q���AE���?�R�f���B~�/h��y����I;�H��ܡ�J󥐣�M��-Oi�TG��D
?�]�M�E�qn@�N,n���s301�j&�K�C�74�$=��	,btp`�h���=1y��u�P'Ŷ�ָ�O¥����(�>���%܊K����	8��C�Ah���N4C����9�(�����F�sM$�[�5���m;�BL��p����RW��*}	�Սʊ�9�w���q�ԢO��rU���B��������!�2��3Y5�;w��^c0��Q{Lѕ�l��7c<q'���ΑJT�8�+��n�T� c�z���ֽ�F[����U�)+v|�p�p},񳄏���ٱ��GZfO
�ܬjFw�i"%Kvӫ`��aĞ�N-:��h���gݥ��_�zp}��@��_�t�S�������f�Q���mN��/��@6z������f��2'q��bJ�Ϫ�݀+"o���~��6�� 
M��m�X_�K��!�d�A�i�5�;�̧�P?��R�}���K��J��������x�}��Vg\c�G���Օ�c��Ԇ�2�;��X[����ڻ������%�Ӣ%1�v�+3�#I�mmI3���z@z�Hf �Coԕ��3f��B�k�i��A� �_��n��^Q�``wj��x<٫�J����`�G+�1D������r�� &� ���U���*���,م�F��&B0w��L�Ǯ`8J�5�K#&��MU�t3f�PĤgh�����TSV�x4�XEc�,�K8����p0�v0���GI]Ş=�Оj��i2Du������iߞ]������P�"�mθ�9�'Xu�L�ܡ��{<���i|@�����N��I�Tvl�"J�d�%�n��r�f�������)�z����$)��>����G��}o'T���T��$SC.�J��M� �VD���_���  J�bM`neEh�;_��u���CZ��I��Fi��zT���0�pO��iy�.�9�ǡ�C %�M��.�����}��;�9Ƭl�I[�,/H���(�1��%����X�"e���x:�2*$8{�`���0ߚWCu_�[�a�hޜU����������*���U�,��w:B�c�@dr�2f�F�:=���[����Co���U�_V�4��3#5ۢ��(-����^4�I�����%�����]��5���ŉ�I��`��_�8�l{s�{�Q��^Mv�w�r��{�\OX��u$�Tپ�'�fʛ�[j����(e�^�͙�ŗ y�i�>�r˃��M��r:`;�b�o�د����S�\����W��q����k�m[�����ú9�RU��ٟ�F-�~=t�|5�e^��<�!��2�<�~q�_� �FS�^�}7��;]�>mk�:1e�1`(ֱb�|*�J������Up��~h����|Xc�!X����j�VZC� Y�C*�d�,g(ܰ,@�<�Ѫv��'��B�n��?�S�4�(�;�lFG�%���ٳ�ׄ�R�e�x����~w>r^Q�Ɗ�d������]����9���}Q��{�~ԏ�!��ldx�>�H��!��Vj�D=.
��B-�h�#78R:g�i�����*�M|���mG��8��,EMK��k����N�W�B�X9c�\ݢmN1=u������)F���bк3 %<T�1xɰ�y܊-3^N3������9�Y�h
@e�����z�� / /S����愸lQ�M�����y�'{����Lۘ�[aC��7H}��۵�O����['�%�m���6 �\���fT1�[S#��5�f*4��JR���6�~�}41�I��}`e�]Vq�����i��+o�'� ^%� R˪����Ȗj�kQ�O� _g�"|�{�\&�yb\�z�r��ݗ/��ϕA��U1�%�����*�`�ӵ�}I_%��}L��l��9T�m��oZ�"��^��]-4���39�FH��l���z��ֶ\fg�a�#��c�vэ����%Ac�!�&A�:R��B(} U9rtkjݩ-���5)��J��QGz"g厹�7g���͝sF��Qe�҆G�v��
�+��0E�K���T�w_��wg�!!�{&9 ݋��o����q^iP0�?�����E�ߞ�a���G��O�y&z���.k�MD��<t�CJP�'�\2�9�C��"rT{L�ʼ�1/�M�{�>�b�c1���z����8��:��?�y���=s�sg�qޑ�Q��8�}I��ͣ�(|��Wc��,�)~�;ԙ��&�i�z�̚y��O ��.������^�~�Q�]],�@�=+zoM�򃗿��?��ޠ�LV��Ge?�t�'v�	}Q��PI{0VE�;����2���|܀#��_Կf���b0u���V���ڮ<�"�<�'��0�Lj,fx��Fŝ��{��1� �q%=H!�漐ܝ���A�����5sy��v<�A�M-m���<�ϝ\�� ��9��}��$9��m���� ��]5d5�7p�F��D�hRO�{�zKg f��(c�_=����p�y���Ke�}B �chi#�(5T��3��ż!��qHN�8kW��K���������ӑ��`���r���a�e)�ݩ�����������uCԑ�/>���8f�.F���n)��,����X:�������|*�C[��0���T��$`�=q ����:����z� ̜*ۭG}�`R��&�k��tM��ʛ�x�IM���8"�]L���m���{���WȜ�X1�O�Um�3� ��$�A���(� ��J��)/���f��Rd���Mi����jy����j@o,�*�p Ia�M��fL�Ӄ�*p�<�x�w��}�*����J�4��t���x�
�W�2u�)T��0�����=�m�m�<:k/-��l@�ھ�Py&������X��)�H����T_~Q�Oi��X7RW)�͔P�@j�4l�����.��q�h��Έ�)�B�	���ο���Y��b�Pzn��k���[->���J?�?�w!������`z�n#zB�ʲ���a�u`�|��-�V[W�4%���
Y���rg�:����n]��A�;��K��kfrO���x���`=�H#M�&Y8�8��[ԏŐ�*>$�pf�!� 'h�FI�; d��Ţ+Q�O�~�a��"]ī�N��LO!e왚��,�&}�b�ӉR:��<W��k�KG�[+�������_3��Xr����#�qі� ��7cFm�!�V\,1�!�^�WڶNS�zk��;�JH��\�F��4��E�uO�w���+&K�&p�������c��@�%�A����p��T�?��>��W����'EXr��:4��t(�o�n7�����|]��"�%���i-7�`s�_m�!?'��>�PDj�xY	��ģ�������F��Bq6ը`c��P)LQr�MMj��S̃�z�a�V���i�9����q&����&6U��j���t�O���¶��۟�����v��3��2.�D�O��
E�D�!	���;�|�tb1/K�����b��U'G���C��s	D$�S�g��Ҍ&��EO��{�|�onD�	�h��e?t&��.�+�\P_����9�����J��o�v��N�V��+x�dbՉ+��5��0� Q�w��Z����J-"�w���t�Y�oB�z��ʿQ�C���;.�V��<��4��?'PnA�^�w12�<�ժ�oZ�q�A	0A#-�J���.�������ff���m��l6=��%��U���r����ɩ���U�L�rf�,D�Q�>�>ݙ}Hɫ�(7�QJȩO�{���+�5�H�{y���Rױ)�������[����e8�+F1P�"��uX���/5��ʊs�8\_:OpqׅOC8'-)%B�Pjsl��vڞ}��D6S����Ve�v��6��2��A�#4R����>�XA���0^����X����Pr�Jd�&�B��9fH���ú��)iC��t_h@�wI�?g�ѥ�p�=2l��X6"�^�J��0^<7_�o�(��&�� #۬emi���ͅ~.*�k>�4��m��@F�i�LXu)(r���?1w!��.���Ⱦ>2�3g���m*�MX��ı��������M�o@z�:V�P�Q+A-~A�%l�	�B�ݵ�힛+�s�ix�7�*��������dw���zB3�r����2X���p�-��>�XABbx��L�Б��R�m��\��]X�������;yYت;�is�H���,X#� [|���	&�����)�K��UF/�5�F:�u\$ޭZ�Kl)�X^��n�0eM�Mz$ڿSM���og	��@^w�����.�|�����I�3�
�!c,�?��������X���	0阿�2���l"�����aq�  ���k��23��qL.)a���	��R̗3ۢo/���}�o��K�%Y(�J�0�ei�0��e�& �1�3BS�m��;�T\u�$�%D�J��S���D�p�j�� � e�P2��?m���@���J��yil���:�ei!�� ���h�E��I�|����_��b�9	Z���}�0"aھJ1����*,_K���Fy�Ѧ�%�}D۪n ��f��s���^��3o{5աu�P��zG��/C�<h����+�[�c�Z���N6L(̀��_�ק�]aQ2��;T���,�0������2~A�C�{�-��;�ܚ�ĕ�2K�7y��Y=ZD�$��zR���5�}�3�׉�{�4TN/��X�x���j�M^��>&�}w�h \i�ރ	ɭ)-���� ��?#�j�v�M��<�1����g���tq�0���{������ꍥ���Sq�ϊ"��^�1��3?h+uYiY�1�����v��K:ɠ����_;��hI�����ز['�w�"%��է�}^%��8dZT+W�
�+��>���^;. %����AB�y7�C��	�q��+q��Zg@���=[�^��=�?'F���}���}]|�sh�ϑ/� sI-�,��5�K�����u���Â?�j��E��1yO�{Â "r?�OҦ&��?�;8]�hN)�
� ƂS�_�C��~�c���؛*��֏���t�Y�wz�����N�Z�w������+��:�q�᲍�;�e����.������`C�������%2���ȡa��c3�x��ú0"����b#�q�^�P:h֣�X�kJ�u[�]w����R�x�̥����y���CYwHP8�}��K]/OA�I>e�F4</&<�6�зgu,��5�E~���t�*���!c�X�f'�nPEm�X��٧q�'h�A�sJ�M�=��G �ƶZ�Tt3*J���2��+ G]7�ֳ��AW���Yأ������ly� lp��H2��ԁX��ۖ�z�WKe�+�g�,��c	���L��Wb2˴��g�9���k��Pg��N�\+!$��%E'-d��z{�����P HQ���_��D�6�QBr$A�/i����6DQ�[S=ڄ55���Y��j����E�O�P��oqv\t�D���yu�ď�ȸ]ZO*J�'��F�N��麔LFb$m�:l�����Y���]_�/%-B(Z /Vi-��9�g	����46 =�%9�߽
����qn��±�,�I&�I��&|��<�Da���A�l�J�cH7�:С+�jr�4ֻcT2���Ë���f�O��ѯ}
p��ҩ��Q�{���Չ-�� �h�Zz����Y�p�<��E|j��y�K�sW�`�L�M,O���)���Jd��)-$��ŉO#�A{CAtx��cm��+�g�PJ�X+*���5����s"���ߑ"z�%Mi��3k��& 9��R��K��;[�U>�~Szy��;�K ��� b�x(6�e�0F^�u&L nI������6��Jh@���=����U��'[��15�2rsfb�Y��{Xm�rBf�
9<�o%T	6֖)|��� W��=Vg����Ǡ;E���̫@h� bfЊ���{��9	����۸T��(#q������X~K�̚uCu�E�فS�K""`�}�������6�eŁ�o&za�HͲ�S7�߄��d2&>�K!�,o���[��Ԝ`��[�Rv��L�܏l�u�q�ԥy��p}�w���¹ZuMh��BC�ݙM|������)�*������G\o��6zr|��Y�e��k����ڰ��#̫�"܁��?<.0��0��RE������C�"Ĥn9,~�zC��nV$�r�E1*x�㻟L�U����M��O�X�zK>�-����ܫ�U�,ľ]0h9p�T:B��$��;E�!2* ��<��$R���PV7������l[?tÇ��������V;�����3�6��<],�D��F��󜵲|��	�j��d��3\�a�1N��3ye�=�H��XD�����n�Y��φ��v�u���Ͼ�j�y��*��_��4L�k�P%��_�?͘$�$&�`n5�=���ءh���Y��3�[&�CHSQ|�p���i�bC2��qM����^.ff�����H�`�Ňw����<�HI·�QL��h�^�� 6�����r�� ��P�^��4p�i~�{Ck���#v���r ��9���L��I5�II�Vn/�`�����<�����`qο;�������O�l)��gON�:����vc��36Z�/�=�:�釥b�� ���"��רk�ܫ���^�-�k	�[��X�^HjR�hND��`ώN ���g�.o�s]�/ˌTo+A�����Ș(<9��?DEc�M(�?�F��)� FJK�t�3�����7��r����.#E�vA;K��������'zFq; �c�3e܃ ~
d6B�D�4?s;y�7+I��;%2U��x��]�b�4�Iv�R6�����Ν7�I�?��]
�_���,S�$���rY|f�ΖA����Gr�
�4�����pue��"���C���#Fk�l�T�,G��XT&�N"b#yx�X^�vE����A���MQ׶&�Qr�L=V����+�wE6D�~Ӑf:�}zp�[���
�;��X(y��`Jd��)Hqd�r���;��Ն������7��	��G��px}�,3a+#��K�'�!�QE�"�ȨF����7���!��#{9}l��V���I�V�"~'��m�{����Lq��{�̓4"��'��ma�vF�`:���	������Z�Q�|!)	z��'�b���q��g��L�ػd �����5��ᬹ�ԋ�wa|���dq_Uy{�/M�Q��ث1�ݣ �?_�1G�vzYA�#�T#�r�"�(e��V��+�n�D�
C���!���BPc~ZH�wDd���ng%��5߲�YNH�}z��%���â�\E��l�!���o�Z4)�剋:�c������ِ$z��$���H��EC�D�'��y�D�/���X|I��v���ea6�wll�=�`P���o��^��Kf�-���`��5�O���'Ey�<4��b<���&:��kE��L���E飪A�wxЅ�;��>�;�;����k=YE�a�_��C3>����9&v��1���D?�/z1�����	C��5\���ک�x����7q#4ϋ�a�D��F٩�B]�ZI�e���w��D���8ݕ?�QV�i�n`$�f�1���R)uG���A���aB�EM���5'_b?�ԥ� ?��h�s�������0�"@9_��ulSvo%eb�I|Vt�� ؘ�F� �P8�~�U �L��Ysd����Ѩ�J��_�ɑ�-�Ih���*���U�9�C�����Z�Q}w�v�(%�޻ԝ�TO��%LY��Ƭ?����9�z���(K���"C���m7���?����L��JЏ6�L�O_�~+"�Xi�Ww�7)�6��8O�&}�z�p�)��_����P�+�2�b�$�kK�Dy�9\��G�n���ޤ6��?�}ʇ�ʮ�
W�I�ȼ�	�Q�(�����x�y�^������H�ʓ���'2mj�_�aۄA�:ʥ�GP�ߏ.���&�E�2��q���d�Z�Ţ���!���9g\�+�'?:�F8�)zh@�is�`�z�7y�#�~�w�2�Qo]95�|l�2V��%��H0^1/����O��
�eDMa�9r�SG�j�M����[s�%�T���$`���:̥v6�]}���N�a�l~qUh��*CQL��]v�64~!z��z�������饇�Y��B���a�{�!e�� ���9)Lk��١~�F����6�+�R�xl "S[���E}ܿ�:���Ï�ꗬ;5>o���;8���_Dp+���R�����qɣ��<}�^��� ��!�E2H�Up���ięGM'�V�IP$�U/�9u���\�Rl��G;f�5�����!nȿC��bo�S��J�뷽�DP qY���>1���A7���8�[Ԧ�ȟ�P���9��B�DD?k�N:�hml{���m�����f�#ah�ۺd��V�u����X�@��'6��7 �J��SSM���b%^�|������a��Q�!a��@T���ff�G�*��a"�,ܰ�0�&��P��[�B�e��ׯ��X� -έ���?K�t�#����&;/2.�'o�a����C�� ����9�,{>"�R���Kɶ[e����L<�҆
11��d���C��N�<��2~��ɂQI^��`ǝ�_�	�7�6����?�����ED
א��'�l=s������s��f�^拳���vf�ѱL3�����׷ pM,�9C2^�cv[Mt)�[B*56�2��
�d2g�����!7�j��zÛ)�s�HKu�g~�ϓ,,�|�[z_�1�
㕫��\Hd��?G(�����5mi̽$��F;���yB�K{O� �8b�?�<ؒp��~�&p&=F0R^�$�����|���h$��q�F��=�̳V��㪦�9���]U`��$ݡAoZz��}��G����I��!1�,�Į~<�Y�ҡ\����6K�����}���o�Bp�c�)�8�`�O}HI�F�-(z���y*')�Ī���5�i��Q��g���� ���t����z�����!%vp���>����ؠ�u3�_`P�7��L{�6I�t�@vc�O�kj�2SO� ժ�%l�ƬM�㺅g��k�� x�j��V{�@ � Ȼ[�o�x�
m��`}.U�\uE��v��`u0�	X��B4_�p��øx�*�&(V?�\RA�#h��R��;U�����?�����k~qǋ��y׊���im���HөY-2���9�1''ࢵa=V]�טS��$���������ca��/5ڸ���(J��Q/�M�Jk.ܢ�I�Z2��l�#Y�Y`�²C���-�۬�ߑ/�u��Y0�8��Ë0n�,�*ǆm���v�Yc��,�Hg,6���AO��ߧq�LضH������K�	=�׺��s���%8���;��(|KL����[���ƶ������J2�`1>+S}�0��niئ����B\��Z���#��ٸ%�pT�'<(���Ň;�|�]|���������R0'���_5\�-��
�m�mp����3�u< �y�S�*�*U���$|�̓�2{I���&�/K%q�"�+;Ʒ�>;	s��|+]�� "gZ�P��?_��0-eJ�K��Q�T�X�����m[4�u�xV6X$�:��A{	q�q�����+8uM�z�{����c���70��@��5�as���p��b�>R�Ђ(�k���:�5��6�����n�V�֫�b'��7{5_���m7|l<���煇��%��(l*S���j��g���VK��uŴw0�wA�57�<��c�z�Cv��� �oAp�^Ur�sA~FGT=>}'����vF��@���.$ȳ2KEG���>8��f�xlkBH>��6)r�P��
�i�5�%5.��Թ��,�F�iFS"E%ʈ(��Z=������_c$3"������9����Vצ),̹���A����f�66(�q�yZ������f�������ܠ"���Ns�{ _�D�i��
��|�i�:0iq; ����Ud�zj5�	vX��1W��1#3�í�t�!�,�%^�	�&��@T�ε�O}�dK���`ۭ=U�A	����⯢�5ß�%�#C�
���Q�-Y3�<ҡRE��z(�"3��~:yq��J�3)M�k��Qk�����Lr�5X� �HkT�����J��<�J�tMI*4؀m+�F��$|Tv �H���r_u ��3�UJ��5����!	x�G�uaK��s��I}.i-O*��'����\}�����y��˱N�+��w�D����!�Ȉ��z�}������vXI��wr!��c�4;�{�::�)�B�:8\�a 9�a
ހ�ӊc8��&!��џ��WW�Q�6)�d�2��Q�1��s^k� -�й p�a�g��?p<�l�(�E�II n��Ls���G��������{��Ӊl�\�L�κ㥑���r;Q��$�_wH��7�B�H/����ՔL�����IH��>,��?A�j�~�*g��	G_У�$�v6��a>pSKo31��(�:mn�7I�|�D}ZC�������ݙx7��0:�Z�>�ښ�ɸ��yW�r�4���~rp4��瀗V� ~��"�)����*'s��9��}=�1���ȍ����Ս6�g����c��bq��:r����n�����D �) m_*���q��1
s�5����B�wR�	{օp<��dA<�y�f�����EL�,j��)��3;xO����0\����+m� &0�y��j�! ��Z�3oy�R$[��U������
�v������|=�o�C�~����|F�����S��@5����T#�3���$�b��p��o��cSe�6�#�O�Г�䬳�?��O�6� ��'7������{��m�o�vm9SM���b�o��B�j�uXj��L��<������z�r�R��%�;R�W�&ncM	p0�6��H ��	o�5�:�g� ��tL)g�d�Ԉ��8Kfw�[�t�-.�Xf:���(�e��W�xd��q�������q"��1f�ȁ��Y�Ky�j����G&z�l�#����^O�(ja���7���(Ug"E/@Y����!T���S��&�"k��@d<x8���+#��Qc�mo���:�w[ N�� :wk�����[��<�	�Z�?Aƒ�3[�Q��௕~9���G+�@��~X9����VkUȈ�� J��]u�KL|�w�9仳E�t��^�R�1��z�_�v�uϽi���]E`���K�>�B��S�%�L��!�K.�k�)����1�	�� ���$=,j"r����?\�
5��z��$���~�8A������sx|���\���%Y	AԨ���[k�ѝN-�D���K]��"f�����0\�N���)Lw��nՍ=l7��@�2	���R"g|�v�Nx	�� C��lG�,#q��������"�`:ҡv~{���_��5	m�E�Im��Tp��U������Z� |s�GPC�p$�����7�NNe��6�Z/eY�6:v/�Ti��^�C���������\i�JpӁ 3>��G�(Z�xc����X�cc���6@ ?E���8�WV�:<M��f�#�q���?/�eo�5a��1\o��[�?�`T���V�	9�JJ�1��Q��}k�R߶,�W���-� ��ٺ���o�6�^K��'��TG"�_ |Y����T�ز�c1ï}>�E��E�IF��eLy���eQ�e��g��`�Y�o�'��j��1u�B��]<���Y|���Dt��4b`�\�C���"��#��E9������m�|��'�zLF1}��:�Z7�p ��k5�~��+wn���D��H��͈_����5�Y�H�Ѱt|��ࠔ�����0�lL�t���Z��.�K	�q�*)܎�˽�x ����eS1�|�a4> S�K�t��<K�C�zF҉��_+lC�ܕ�I{�������Wg�,c��_?
�'$��-� �u���2=�m� x�&�K�U�	Ivi0(oƌg䱋|H�����u�d�}�t��B���q�m%�`���y�t�B��N�-��^i� ��k��N_|��룛���gDLV�/��C��8E��/�_�8g��g���\mt�'
�Ў��!%5\�S�V@��<���r���7�*;��+憅|� �	�RS���Ա�D��pB     �72E��	 ѽ����w���g�    YZ