#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="794890845"
MD5="d8d107d486f6f74ad2d607f893bbd432"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25804"
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
	echo Date of packaging: Fri Dec 31 00:58:07 -03 2021
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
�7zXZ  �ִF !   �X���d�] �}��1Dd]����P�t�D�#���t��L�"*���&���ǡOo���_ىe����D,AV+8:F�2�k6�:?�O�ˏg&3'�jP�MH�m��]y��a�3�t�M�b��~ܷB֊�N�L_������ _�.��Y���r�X���Μ(kGJ�m��m�+��;�ԏ3B�w��z"@GGM�O�~���D#)��Px吡��!��FE�ZK�p��?��?��C?tf�a7�v�D�zd�i0p�g�ٔx������Z��'6{!�^L�k�=��M�`� "o��� h�(*���_͍��m�ihdLM��sV�4=��>�,�u�^�2%��T.�(�{z2�8��Pb_S>$�"B6V��}�X�7_����r�&1T�E�{H�>\��|��"xX���Z��7�QD͜���z�\��Q�VX������G� �ŷD�u���ӈD�Gk�ۈ��[�ɔvL� �*�EzxL�����t��<.���+oՖ�iֈ��<h�;�ْ�� 'i����Ϝ�=̀h�V�ز�?(W>pTƈ�"t�g`*
��k�
&�&+�+������"͕B��`z j��ă�_����f�1��C�%gM�Ԏ�Q��űN+�~�q�3�/�\�����ܲr䏨� ^��� 87�\�G��ͥ�hҀy>�x���U����'�I٧���H0���ԷcB� n,��f"�����C��J��� �?����R�
�A�k���dc��o"(\�3��{�Mb03�Y�� �W�U&u�<�zfcd~'���Q[��o�J7�|��J`�7tv����r}7�,p ����fLtg�[���H�&��0�V��+i;�+[wp��>�CX"ɖ�!���S���^3�j�;Æ���b�����ر�J�����4 B,�!��2�Mצ�po���_f��ʎ�PJ�@�8��ج�n�S��;
�R�B��E���q�xBz�R�Z�cҙ��F���42Fwb�	H�K8J�~J.��Z�Ig�#�J�$ti8x_�G�Æ���4"WV��hʎ�T7�z宵.�Q:5.�$��`2�HK�`���?*��d��W�j,�OB� &��s6W�"��9�����l��%W!�3�L	ڐo�7Waϻ�dwn}*�v�J�i�������<�ё���߷#)����7ģ�O}]��ݥ��8����Q�EQDȪ&�K�sk̎��a6��>�EqnM,�k�II�`�AEt�US�vN)8}
*�۪��I�Nj[����/��3��a�D��"O�;�8x)`55<�Q�ִ���$h�A���]9���ExI9
�a�Z��x���K�l?*�3^T4{�i`�/��FMt�R�/�ߪ��ǡ��JX�+�m˽��O�*V�ӆ���ߞ��K�`MQS��D]�U|R�1*Q2��l�r#C���j�S�m�՝�;��,|��gMݚi!��I`���I��~םVq?O��B�����ڞ7�~Xe���9���`�xaP��u�S���O�i�	U���G��d��D�a����e�Z7 xE����f�����5T?_C����Ϊ����2�HV����e�K$��$��*8\�E��]fj�L@�X����L���u8��Js)<?�ެ�.ǀ����z	|��~���$q4� �_|��!�a6Dr��zW߉��\]�C��>�ogb{ҿr�I�r(�F�'޵�{��3uL�4�T��[e?)�A�L��
ʦ�
ӹA������fU�8�-���������\�N�d�-��J٫s���p�ן�r�Ф2z~hm�H�4�%�����_�u#g�G���
��-�َ4Q���lQ��C��4�U#I覷���TK��G�q�I�L��������1)J%��RڳST�{"9���[�G����xןIw�JpKs�0Yr����\�MR�
��2U	�с�/�?�wt=0�T�;Zkjd�(X��O����G}�F{�_��2lPy�L.րb��7����)#+}�*��t82�:�f���<�GI����U��c0,d�!��-~'���s@�>���� ��O�o2#ge�9��JSU%�"zf��6y��g�}��;R$����*]�����J�Do&��03�_��OWGt�qgcoߡ'���X)	�q�[Nٴ� jA���#D��g�L/6��`�Av:)�@��V,Ԇ�,y�'A� ��ְ�����������1K�#��mЙ�:$
8����L�UI=���6���tm�x�I\�iP�� O~�W��v0�z`�h�ۧ�(�h�2�����,gt$
��@��Kqu�J��i�������o�v�����>�k�u�y�+<a�+�ֻpA��Ĵ�w�C,G�t�@ܪ6��j�`�jZ9?I�bu��pL+�R�[$��b����p25��d����Cˏ�Q1(��I��ho75YP��� �7{��w�Fݪ��jN���\vI�"�GN̻��h����l��X�;/l����+���G��($�����CbA��Q'��9"�^	�w�SL,��QF��Gk���ʕ�梑Q����w[��/�C���o�)�ɟ_"L�O�&�dp�J���K1�H8�P�T�N�ؿ����4#?6�q㻘:�Q>z�w�f%���8��TJh�e��lN7Pi���k֤6�L� ��=�]�*w�w�r۩�N>69c��.�Z����*k���C���@
 ���h� �a'w�m�X��\�eV�_�o�G���ؗ`?|�d_����M�����6���o7�1�Q���)�X�_7�:���R�S�4[U�I0�@7ܖe{�P�}P��f���������X(gK%���)�֍�8�R�ČO��x�ӑ֨
T)��{0mL���ƭ�.��	
��2!q��4�AT}K�\9�������b뗓����	O�n@ʘ��I3�����O.��	��	�^��ډ���]**Eb�|N��]S*LS�C��wV�����,5�b-1w�4UR�2*��^����{Y�A	p�g�D��!㎗���
ݺ�P��ĞZq�i>c��@��T���m��H0���v���C�g�%@�\�q��}7stL���Pp��yDJ�ù2�|k�0��E�$�D	�@�!W����od�o9��r-�|�kA_�V*ԌR���r�q�{��W��u�c`(&�k��n��c�RI�*~�5+I溺��<u��m��iY�ia��������/R��t���*Ԙ��=i`��8L�mT䏎��Ϲ��j�k�gi5�N��+hֱV����bC_
�����+�j�BM���4�3z D��n�;� ]��Ӳ�s�Aa	��c%�f�>�?
���å6.
D�	_���S��[�
{�U~zڮV\Rn�(��e}B��67�C�lt��h�0/��.��i�4󰐜?y�_4`�o�^4Q�~IF%�����ސ6�M1 �7|X���i��C�,V8���a۬x��.*m�gx�wL��7�STUZ����Ɛa�����B�!��)1oj�P�e�+lK�����N����;�]���	��LmK��c8u�u���6z"�Z��&Jڶ+1x�<��3���<�=K�����/Az�[}���=R1�vLN

�x���S�lύ�Q�����C�H�\�����
��{?yk{φ  ���B��ďl{��1��goQl9�[J�#��	��#�5�$����3�y8���5��_:m}�whIpY\lu����\Blp��ĪW���E��D�	v�p��or>T�Y�]��g�G�4��" 7I"�Z>#�ר�����CBw��Y-D�Ē��.�cr�[a�+,���l�A����%Gc��r��W�bu@լ������=J�Ҏ5�!4%��}&��Q���{�&OXn�v/����7��]�g֕>⢡4pY�&N/�l6������Ā �ې[\BmL���E���]9{�a��[���ƫ��/g�8��x^kg�HJ�WKZ�cBk?��1
����;�j#g���`'�G��fVr�N\����s��=0����8U/@q��p��,��Q��l���ɀ�;{�3�$�����+5�%���6��آ�Y�{ �)��
�T��4Qg�:�Lې��9SS*DWFQq�i��'VO�~���L�Z'�J�����i�+�e�Rr��:䝯<�|r���y���}F�ʆ �U�sw��~�ԭh�����^\j,*>o,Wv��B���OiYa�9�����h��I5vch����!�o2������h��2�m_8}ϡ�mhkӁ�����A,e������	a���
�O��n�*Xғe���4{0�ym<�F\]^4�+�Ԡ��X$��u�,p=�Y����U DxdxR��������8�9+���w	G�I�4d|�[�bbV�n�蓥��gKC��]u�_U���!و ��(S)��Q,�4�*�_��;𯘇�P�
Y�I�Q��1��`�삦�V�h�N�VRqX��e�����FA���a�"�ҧ�����%=&�N�JI&P��,<2��;4�dq*�~5@o <�ӳEң���
xˤw}%M�ך���\���`��Ţ���:-r�������Jl)3���}�A��)�����;bw��
��܄�۬Xu�eۂ<s���� I5'TAV������^YJ��h%�g~�Q����=3�!���2#�ʟP|\�>�������ݡ���-�J�R^����n��6\��>������rX�Y�X�ǻ��B܏�d?^�e:W�ds��u{�C����v*BJG�Xv4�����Ϊ�H���BK5F%scC��c����Cߢbu$�e�z8�]��;��G����-��m�w�, �Z<2e�3\��E��c�r��U�g�9�P����Y��?�ā�jT��s�j�����z3���^P9� �8P�����|���kG_O�|:�>.��r�b��|$�1�'��!R{�g�����zC �]�a��+_�!�=�G�Y T�h�����Ġ�ٰ&�c˥3)9Wf�� jZ�������2��'���y��]l�EB����g��-���h�|���)�-����i�.�Ŭ���x�����\���s��悔V>�3�bZ�KrU��D�VKP��&�T�,���2M�F CI�u\s�����9끱�!��#˛v�y��qܡӑ���S���$�7�~Z,�ƻ�<s�D��up�4L�P���=�Z����y.بi��o=�C1nI~���b�҂��=�@�_��A����!�|,�a��� ��-Aީ��7T���鸒�x?UY|p<��m����L�@�����~Z�)��d|w-;��������P:}7Iy%����x��;��jH{z�Ȑ����*�����J���������.�)������Y:NjUIkx0����b{-M���w�@]F����U�[�J��z���2��[]�b~�����NK�8�b�^�Md.�a������0�j헪dS�7i��UE�`�d�r^8�<�a�@,�Z��t-��p��ps��-*��\,f�����ذl�P���xZ�c����Ew	D"~����e?��$�J�馇-o�p�qZ���bB!�kϿ���p�}��P�H+�^j�AƜ�����l�� ����ΞԸwu+b��y:�벰��!7ex�2�sO��'p����XYx�.E9t�X�J#S�4*�UZ�R���95�o�r��µ�\`>��XÄ��^�+��d�9[T��+i�;>�~
�����C>�U�+�S0�*v��?];�M��7���h�cQά��;�';k��!� �z�
��.�b]���	6Ǻbv^`���K�C�2��r˲AX�C:Q}&xc�4�u܄���
�vZ�O��J7����=��02�{�=�T�����AC��F��!OYv��n�S/<:���M>��q ���7��Ȅt��SE��x�冧���4a:��ã�P0��'Y?��"�Į�s);[2��eȘa�8&�J@=Ö�w�hg�뽹/"�M�HK�]5U�c�W	���V�%o4�>��#�k�W��n��[����~����3D�F�z�g����\<�F��<�#sq�-tI���zڳfar�H�®R����3���Dy�-��g��q/.�C� ����\T�l�ص�[�ǰt?K�L�}2F^�o�#;��2��R���`�܁�*	E�*����L,*��$�U�t�{|7�0�Le���-Fy��%qzvٺG��|咺�x�v��Y�Q]���׳���p���}J}R7�$�z��L�!o.;k>~�R|��]m��������������� ���S�"���K'u.��������:��]��ּ8"��;an霣$o��3�:��~�(��1�}�T�@�0zO��9+�Ef"\��$�N97�d��-�0L ��W����4�G[2�}"t�j�y�q��ĤX~m͚Q)��Y�"R�}~8�r�gm��(!�А*�@��s
��*�#�m��n �/<�y;�8���|6�&���Ik�.>�f��}|j��ek�=|�f�&K�����'UM���w6.j�����z�����Z��U�c6�����eS�� TgW����(S^G_��ȥ��}��6���`D|品Q8����Y֢��M���m7��7�by�y�	�f��)�q"�P�tZt!2ǹ['Ě��e���Wq���T��-�3kg)n�|��AtR��	�rzӳn%�3zٱ��G C?��z^&v��*�x���㯱j!�����=-�v�O�S��{��LvV�b,w�h���äL�+��ɒ����[�H�~�4�KhHFm����d`��0l廞Y10M#��͇��~�����UJ�������/�������`{��$�������>���^��eYN6��2�Q�)ӏʪ�\������Ю�����j��t�$V_b9�Zo���d��6�U^.�|@n��X��7k�'0�N S�H�����|��?s�B�^�]�.lr�㮉��L���*�jd��Ȁh�c�%[�z���@�-���Om�I-�5�b1+,I���5\��1�Y�-�#J�Yc�x�D�Y��#�8�:��Zw7gU&�=}�Q����˨�q'�/�q�C\�9�o�
#.cG[RpF�Ro������d^��Ro�*��f�5Em���PT�҃ا�����9E�o���=��F��S��vz��՘�B�$����:z�p���%�V��ڲwfV*��`)i�0K�>;���x[��Y������/�:W�Ъ�����l�/X	\�T-�
���*N
8 ;�7���۩��?x{E���[8�����h`��[��cf�t>�tj�55��߻|vqw�A��17�Hm)�q)�<@�D��{�O�}y�W��TMq���)g�V(��6S}
���j�Q� �IH�x��{���>�18n�+{,������x�=����H�7Ȋo7�I���عKK����J�/�ShT��p��4���uG������)���娅1���H�SAY�*<�*��˶џ�1|Id���3[L���kD��^s��Ɇ�J�bɴj[k)f��n��G��HJC��$F=���,����W���es��!bVU�B̐�9鹬}�5�]�� �I8�^�y6pyx:g�D��P�����O�Z7�[�|�Y�Ly�TN� M:�)�̜	"\A���H{;���d�<� �]�����%�|o=>)��Q8Y��j��K�\F�L���/�1��?`?�Z���!Ū�ߨp7�d*�O B9�Y>?��Z�͟�'��o��%�;a�jYf��`����L
�M��6�8��-�1t�,{.�k-�G!��r͚s�s�NQ���W�<(�
�j#��#i��kE}�>p=���t���Eʟ��I�O���/�1��i	�5Ԛ���J�q���Le;��F%[E8�,v�$�:�a �����a��ovՆ�l']J��l�	(��3r
�6��.���k`� /�ݩʡ�;ܾ�x�y3������A%c�3��G!>0�[+��? �az�&�L�D2��i�*C����2�!Kqv�mUY������F���`�s�w��klޜ�e#l����ܺ��V�W���0O̳	`���dur�R�8\�'F���}~XE�������DZ�ה~N��8P8�EZ��r����A2�0\�%B͛M�.9à���䇰��cI�v�U[
��W�a6bQe��D��i'�Ҷ1z��#���ū9��~��p���WXOk}I����<r'�v�62j��7)h�|l���F����B��`G�μ�E�y7q���[����oTO�NB;q(e.�0�f���c)�pEC黿9��P�v��
A��q���63o!��y�@���=��'�qYo�`�N����x����m�ڣ�?���E��=��v�o� �]0�N,�}N+�	Wx�sI�����-�Wt�6,Gü�[h�:.sY�U�.�L���h��{Kj�l,"J�M�0�~���Oh�s�[�hE�}t��s֒���ηK�q!�%�4ʀ�ހ�[���N���z(U,�*�~�s�)����O���gFh|@!P����;�;�\��p�s�|�xG��� �ED��߱�K;s��cHAp� ��9���A^�O�,cG
.���{pS� �l��
j�ږ�*�DdF���F�F�p�o4Z$��k�9q���	S��oOw�k#��I�{���q��k�N��z�T��eڣ��Ø��F̦HF#R���=d�y,��u�� ������J}w5��F�g�o�w�PV�%Bo~�ؽr
�ٍ{��t��G�Nv��>��1(T)�	�N�p�J�`M?�w���7�]V?��*_�Tx��6
~�?@<@"(y��LHB�E�FEY񶾘NZ��bg� ���Wp�X-�\P{.5-�%o�z�����[��V�`)
�wY���g��|���~�و�]��:���q���5��Wo�@	��IrD&O�V�����罅Q��=��JW �R�B���g������s�xP���ߦ�����w��
�Q��tld��{���PM�+���
������d6s-"��N��=Tɟ�����B���JU�3�Y'k��ȍ��鯌��֏>,�-Rͫ���2@�[隿�J��U��z6�H�{	������:�̮� ��Ö#����ɅC��e�I�u0�Un��q�^3��]�����w��̮yb�LCZ�=`F�����-�&{�ۑ&ؙ��[|pxC؟�"+�g��f��w�K�ηN�Ί`�=�ʎ�V�/�I����w9�A�[���8���=O�&mXוG�:W��$&�^j7�������TzYV,���:4yp7�"����?r����n!IO�q%s��+�A� ��f9�����Qn���w��n��RiT�ۥƛ�g�3��OS��k�#G~�XBj���D��.�2�A�)�A��S�x��oAW�	�(���#tV�PBn6�Z>j��"����j�K�@��_}a��	�ô>�6;R�\}P�YP�Rm5�FJ�O8i� ����6����>�s��R5{xb��1��?�+�S	���B�R�~v�� VG�"��&�!�����MS��<�j���F�vf�}x�*ى�I��_�`�6W"��������x��7 ���O�@]���#J�����n�8&ۆU_�AVw�_�q��LB ���
]��_��4C��L�1W�z��?A�0�C�,9�4h\Q�\c dt��E<�3���P�ŧ�yg�����ZN�YG	 "�Rs��=_�S��D���u^��I��x��Sv� hD�S�>O���-�7JKaBa�k2�"�*��(�|��gW����BQ�2��T��0�� [y�j#�Z�4�*X�*�΄^���c���F���{��X��n7)��{n+:�A8��ޒ�*�]8�MW��5���.���S�IuWϋ���iB�f�J��(AH�B�oa���i�zw4tL�ۀ�m�D�,��%�C��e?�{��zL�Z����ae�(�#,s��"��m���9/�%hFC�ASQN�F�cf�>#+�#�q�A�p֊��9�t8���0�}�冤����:�K�¼�#�[��F!�v���<Iݳ�ڊ�Y�hd �,X����;�(��ϲ�L[��z�E�?�u�A1?�6:h�Rf vK�>�#������
��ܶU1�B�sF�j[4�дҪ\5�n�|��]��ep�^��ށ�yO6�i��T)���p�[u4�G�w�F�E�	,b
������=���CȾt��&�kM��:`ٜ'}��ѫ�r7�'w-%��"F���a>,O`�MÿC�s����yӨ%>b���r۶j�*��L������*�CX20�����O �?�Vj�P�4�=*�7:!
�%�f؏�6L��� o����J�0��s��?ԭ�ϙ�X����"8Nz�������TW���:��V{����}�tq��q�\����LWX��Y�es�ls#��޳	7��;NW1�$_裝b(7�9�.�1�0��s�;������45��� ���&�F��B��m`؄��ʂH	�S�W��P,��A��u� �³ʲ����tY�����
�	JK���Y��k*�֡��'���m��������j����`�C�o�~���F�;
s/&�����^���j7-QB9�,C^*l����d�� �+%�=*~��Q�x{ǓI*����Y�n6����'7�o�j ���<�\tm+5�!HK�t��+5T���4,<�3��D��\�X���K�S]-���h� 	�6��D��&��~)�1�=]�	�����i�w��X��n�RAB�$'Jc[f&�8p��f�jO(�$�^Y���&d��螊5�����qԦ�җ��t�����9h�,c������<�~$!�p�eh�@����խIsD�7(~�?�ɵ�
�%?�Vu�\�q�l��u��8Q��e�-V$l�c!�s<��i�v�Ʒ�F�I��k���z��:2��\�=�nv�\�}�㍽z]J1:�H$�	m~5��y��0
�`��4�e�)��0�lX���[�i�;yj{\d�i������*:�Z�|5��3�[�koT:<�g)��e]�����B�>�Z���E��9R�V[��Tuk�zEuX�xH4#bk��I���9Je�Z2'f�+ ?�O�@o��;��mQ�ѯw8 /k��"m}��`�BM#�.V�RU�R��R�u��xl�'���K��B�쒎u�ׯ�\�BZNO��b+��ޯw�
��u"�����h�t\�A����2�gw��!�B����t�9X����$*�Ls,>�9��a�����^R4�Ֆ�����2�(LGb�L;�a&��=���$0'�!~�5{�5�ro4a0�#�h;]��x��8q�Yr8m4>����wS�f2qQ�M����w;���\�LvTp7�/9���eJ7v��<,���Nw�;u�*Vxz�p�� ]�X�m�~HL���"��%����!�ߞ�مt,ͩǢ<����^�˹*`xמ��=x�B��s!�$��Uk��/���~�z��]���p��ǎ'��ˬ�d9�"Fb�i���'A��,b�>�� 2��x%�4;���l�Rm���ʹ���L�~l6(yV�����Ȋ��g��e,�w�j��gcj�ϽXy)��tKΐ�?Y�ެ�����L{	����On~��h��9�e#�/(g�{x��[f�-ߘ1T�󷖈Bu1�J�����z�`@v2�"K|̓���Сz���*8u���ٶ����\!�ljH�/�nzQ�-�x :�!d��'ԋ���{|��C��ǉǯ��r���V[Z��Q��
N�>�����WM��Z ��a���/�X�\�v��8�c:|���2�%�wṥ���U�Eظ�f�vB���ڲ�5ߞ�Q|͐�t���K�EqfM���ӯ�gѕ�S_&�*�y�m��3<�L�ES���S��C����s*�/��B�6���zzbt�-��XQ6�r�?��!u��H/۽n�7L�]��h�.���t�Bm.̜�i2=X�!Z]3iZ�`�;�x�"��;���v3��s�y��t7o���̎��FƖ��ps�l�o=>s]��t��Y���g�i��w@ILy�>ve��,ܕ�?�/�1������s^0�����^M��#���}
��X�ὙT��A&?d´�+���šֲ�8�.+�䀧3��4��f��۠��Z���]E��:����%VN���9��y�<Zo�;9w�Z������� ȥL���O�8N	�e��G��\!@��nH\�l��#��s�e�,����^pPFU�֥��A�DU�<.�#q�~c/���e�E�K�EK4<H�RS�y��J7~F�/Q+�k����G��B58�c��V�E��8K�17B圃� V�v
�3P��騲��)���]�*��*��fJ�t��k��Qhl�E��S��Ɯ3��Ē�7MIN��@S�bWܷxth�5/y:ۃ��yr�>�Ɇ�&�"8��p�" R�IqS�ͫ���:{���g6��Nzi�M�v�,T���!�j�O��yi����]g����ՃZ���w����yk��K�W^\��j��u��=|@D��Qs2���UA��,ts��*��Tq
�����wYo�8���ڦ^�r�4�1Jf�l�R�������ʌ��%fcaNk`�M Y�r~���į�U�����fVX|!��U�amGl��>�H@��L�ɀ���3�	�CS|�z�Fy;���K����9ߛ^*���\+!�tv�����Lv�
�1�?����X{����v���G�9��<Xd�qm��6��e��]D#����Q���^M\VGh�s�Ҹ.��v`;�ƺ��<��0�a��yJ�ܹVBŅVM�5��)!�.�DԀ��@�:\*��l6:
���f��e n��S�a�$��9�G��+E��!�ΔB+a 8g�X0.ӧ��;��S����gk��?̤[���z�Zǎ �yvR�ByJ)��+��$�uC�wp��Zu�?U��4?�)�0~�b�-LM7���,��]�od�ֹRW������@�t���I@l v����4�@��|��E]p�|��-Z�t���U��#�¬�J!al���qaj��-?`�r]N_��Ly��).�_mQ���M[w���*�%� ��8$f�?쵘[z\��Z�A���d�CY���Q��,��:z�g��48�m����@����;g�*"�������#> ��Ll[Qм̩	����B@!E9��{��|B��+a���B��:��2u�&%@���
�A[���7v�q�/�rc�Z������=�����"h�^�h�8������Y��?R᳗�<}Z5�q�ѽk[?эw���L�H�w��9%��?�82��\�_D�o톪y$ua�
�Re'��@��޴M4N³���Vi��'����sF�W�50�u8;������lI�s���
�Vr%�.0�A�J����=U�{��j�F�8��C ks�~��v��eKY������Qɻ�J�`lw�k�Z�cxX/*�����f���7Y�[X�3����Y���� ��T��պpw�I#*،�2�;�QX^�	K�M��n��iɸ�4��C�k��Sl��D� ���'�Vn�/DJj4G������>�p/i��#B�Ј�ژ�ͣ�6�Ճt���N5�)5��=_����r���?�a���
Ȟ/ut�l�1��:�L��=���ؔ��G�]B^ >���}n��Y�a��X�i�%��Ƅ�v����*���9��:�P��VrT�P/M����{�v��DP\�,K]�T�>�e�'��y���0i�k��,�&Z�
�E1�����?M�&�����\�#OB�e�K]l�z�
r�L�3&�&ሡ؏hS{W��\%��)��0�!0��'G� �۽�q�� QY�$\��Eᅃa��saN3�;�π;��|�g���+�Th������cc¹M#U�A!ha���p�a�@`�|�%�3C��s��X���4ڸ�+g͗�ݦ]|t�0���^�z~�"dM��p~c�L��%vlC�Qڔn��㒱@@}Ȩ�/	{�/,C�w� �?[~o�f⍆�]�ڤ�T�E�Թ[��Km�`k�??0˹ �+YD��Y��'�������&�Н�~M.�!����,Ю�S)���&:�w�� bms���:*��Z����R�k��^�P����\T�K���&�j��f��ջȖ澠��	����8\l��2��N��~�6�2Z�P���o_��N��t�k�9�a[���-�:�U��`�K�'ܛ&F��kL�i��K1Q���J�Z+b���3�_���I���M,���Լ`�gI޳��"d
w�KG]�4����4�	�����9w@E_���|��gŎ/��|�rl1�W�g(���+�U>��Â�R�g9j��ff��f\�~a�|N�`:q�]d��E'�a��j����J}O����3����OL�
�:H�g����p*'�`�}Rg�H�$ ������@+�q�N�~�����$"�������~�W�4�����A���zT���r�������2�.��G��W��2�|�<{0��w��8nTd>1��`��	C�=0�lQ�0-�0JUt�"u����%�}7,���yM*��2r������V�-)�Z�p�!�Н��N�t�5m���Q,�I�i����8J�Ք�G��ff����{��������Y :��d�<���<J(JJ�V�8��~k�YЛ��;)(�:`�����7pc#��8�<j�;3���͡�\�]���Xc���A�(K�x�v�}��E�b�'��7���^;M5{�!�7����Em򢔪���OK�(K�=��lD���{�\�d��-eu?b��$Q$���H�EΨ�� ��@p���l�6ꗣ��&�rb�1�UQ�Cb����	�̼P7�;=�f7�~ܴ�Y+3�� u�P,��O�;�Vj[�3y���
9�7m�.0`����2�SG�ȓo5s����v`	���t��Dd��9/�~�����N:=�
� -�<�*\a�y��Gd��%y��7/R6���7��d{gͪ>���j�8������c~���#�<���7�5a�ƿ���B;��?�t$�@O���*g���[+�����E��	I���-Z`�$L=NJ�++��/�-u68pP�O�~��#����i���e��A��ϸ�Xj(���w�QJn�q.4i�B�D���m��h1m��!O�N6�w�!��n]���?u��r�����(~=0�X�G���u%,x�.��i�î��	��.�/�9��a�B�5�5'&§���Kdu�U+fZF7i�ͬ�6B��T�ׂ���������Ԫ��K^w�Ml��T�T�� f$j)�$�Y�=ە�������Ĝg�J��a�)�	�D���ɋ�A8�ؖ�L����qs�����k�C�/ f����fc���ف���Ԏ*��e��O\qv��j;�@�j�b(x���򱜲��[c�5*H��ܸ�,�n�0���O+(]��3˗�O?��g ��Zvl�0y6R#�@ޡڟe*�A�Ks���~���%�d���XǙ���N�+ѣt&��VTc���I�'Ν�i;����Bi�qB��xC87j���Wa�U%Ǳ%cjI�*�����x �ny=��q���n�^�yǠ5����A�ˇlpF*}� �<Yˮ�9Z���"��hp�1�v#�]Dh�b<P��O�q\���ְ���P74Iu�a@~˵�i��<�����bRoQ���Jѐ����
%�%3�xx>F���͋����#��L���0x���mJ��:�m�';?��'�9g����\�+!5i����v�;IN��$�,ȓ�j����!׽�zc�N�0Ӱ"������Aڴ�fPe�$�O��e�)���tT�7�V�g�> � ���,(Rt�V�S�J��%��؛�f��t�48���օ���6d�|{��#�藔
vx�E�.�9�6�Uޗ��1��A�y_�),$*�3,�h�!���V����d��-��F�W�T�UxZ�B��p�Jdv'�h�jCZ1s�ߖ1;���g�t�o�O��u��t�5 $��5���?E^��Q�4�<j�Y�09�6��*�ڀ���6.�h�L�=B'�����QW�BEG^�x�U1奪�}6B"�a�'E�g����dg�r�,mP%��\�=�Z��嚀��Ax6�I<��]_;(�|���Z�B�e��I�ҝ����'�^B�K�Pb�%n�<&e�������`�����,�Ǎ�3?���L,���+���PH���_CR8y�fp�}�1B�q�DL3R�̕i�|sۙ+K�?��kT���qf��MM�Zcr>���?Z�[u�%Jmy�%�4!9�`P6����PDvM���(Q� ��~���l�\i5�=����%ˍ�+8aU4������0g�7�?R��w-f ��yr��W�AÐ��-�O�s��\|��q<�k�t��h�7PW��i�s��X�e%+��S�F�ˤ�u4n�i�2j}�učƴpg���k��0��q�ɏ5�@��x2�E��ٱ�wk��5v�ջ>S���i
kU�G��j��{P����J&�~
��n�� �+���U��]�L���#�.�)�/�~�)6�KA��0qy6��Y�Q��y���S*�9�`� r"�4�=��z1

ׂsYR�,t�-HU-@�7C=W�-Ư%:�m@ya��%�Y�1��к�9�-��a(1~�L=���yԨ�)�TEc5�����;j�Eޚ��������;��Q��\#`�g��/oe���B��jw��n��}�&?�5�m�!���rE�g��Uu����
�.�ص�xLK�=c�������e��TKY@����O,Mk�U��L���nԣ�54�|$���K�9�wI���K���:ہ*�}����F���os�=��9�4�<��F.�X�,�S��6>_�������j�U��=?$�ސ�Q@�ʷj@�I�!F�4�jÄV�-A���m�\҆��-/�K�}�[�Z�+'��1���C�pQ(h[p�nB	&\=F���PEZs�y����B)z6������e���+M�̦ƁVh(����^n�@�7JO��
���7����"%yu�C=���S�Z� &SNdݑׇ�ek��ˁY��&����� ��)�ϫ�tv �̙� ��� �ut@��g�� �QL���BH���rÀ��c�C'tO.� �rn�T�7=�<�/i�GF�;�&������ӭ�z1�k�l�kV/<7�滛�jT�̨�� ]_�Z ��B\tC��>�#f���}4��W*�nSL�����B˵�#�p0��(����;������Y鳱Ǥ����LJ�>�P���$`}��?�ק�ȵ��:�>l,�]%H��.��WmB+�WI4����j]�\�M�nU�w7��-��-x�GKN�e�qA���Y��k����[.�N=.�-����A0T�K!q�XSb9� &�e)��Q�\2��R�>Md��T(�D]&��Vcy��Zy���	x�j�i�`�%v��fB7~KU��A�/7�dɹf����Q2�PE]5֘c����D�=�*��i�� �0�7�Cu����#=S۩��$j�A��]�-[���������s�����%� ��W/��M�Ge*��~���0��D��Ld����!���/�Г5BgT�9(��7�M���\7Υ�%|�&� �W?z�o�v�3R���be�����&(F- ���[R���:`�F
U}f�7#h�S�CûS�5*n�:yD�n7�v) �t�<P������"�lUH�خ�=�Wq!]��X#�\o��\����}F��&����������4IO�6#wY��J��z�߭�͓Tj �s�Hkq�7M&A9�L��ڡ���Sb;�<�R��5��j�8��x���jR1>/���4��è8?Ud[����{���`@c`�@�p(�Ǒ��Hn���)M�Ӂ��Oȗ�l��ʩS%k&m�}m^���`�.	�4ݽ����UV�E��Z�{#2��m:G)���1V9=���Q0�P��4#�׬�������9����)"o��?.��\>�S�	V�a5�3?�|�:QL%��Ƥ�+u b"j�v2�7ߊ�/ӿ��Fഹ��y���p��xA4�܆�Q�ͣ*�nU�Q��UT�O�B;�N%s����I��ql�-) D�m�oG�O"F<q�3}����s�?�[�i� ��*�^� �ʦ�&� �~`�0nY��	�\�ޓ�g�]���E11)X½ ����_�`�~;ֈ�`�kDp(:��`��[�����|�/Aؙ��@�#P�D�*�}d@G�<��3~*��k��:����lxꅸ��?�!�>v�IN����`��������3��5��|��C\��]�Ŷ��%��NN�ꗾ!���F\��j�Gx�D#���u���r������p�2|�t<���ESMc��yJ��Z�s�-T��C��{?���އ@mHa�qdBL�J��Ͷ�/���fq�Y�}퓪r�d�kP������E��79euˏ'����\��7Z�(�d6OP�{5��\0M �ܛ`-���!ք{�_q9���s��)y�4]P�O 䎆��L��
�"�n���55L�Ĳ��v��F���l-�:���FY��AT��B*(4��gn4�`Jx�|��+���D˷/���� ��z�XA��'D�DƬ6��P!����J����U�z�Y|;������u�끢�귳 ��A2��uOu�l,+u_	;�N;hk�Ks��2&�����r��&����
��z)�4 ����X��J%F��'� ��n�yl���SU{��M�5{�.`�b�����{8���W�uV5}/T,r�A���w][��~��Q0���ቲ���"W%�\�N�
wT����r�DΏ�3�c,���6����w~q\g���~�.���a�άH�@c���a��x�Yc��G��Q�rҍL2%d��y�~ܢ���󖽮��<{�p'y�i��5b�v��_<�o&)q�oÒ�J���hʔ���Z�H�R�ȻG�a�����v����:)�쥕#������&�2�ƀ���p�b&<�+r�￡f%I���O��a�N��	�|��E)ctѠ��� ���ޚ�>���:*�t��<wB���->%�|;Wfž��W؀0��<����ܷͩ-R�!��׎O7�HN ā-�0���i�n^K�������WB:b� �P�X:�x���=>�s��I ���r���q6�#E���Zyh�y:�F`/1S;K�Q��M%V�K�1�bD�R�h=�/�y0eK���~�o���]}5��P!�7/Z�o�͋�kk���Q6<�>�=�' ���I�99Δ�Gi�z�6}*-�1����l�ro���T��275/�`�p�PN��2�$(U��v��3�l.!�Q�-zV���m���3cW��{�M���jฏ�J@�ΰ?�FVf��㜴��4H�4��SíL۞8�͈S���,C�����i�.I�Pa���xv�/xB`Q�5w�J`�]��q�ţ�C�
�j5$m�h��G:�\И�ͨ�t
���Jf�4ոΙo~�ӫ}�"B_� N୍������ZZJU��桵��h.�~��v��ŁPi�1;�2�0D���h�ˮ���Ew�����qU��asZɹ�7:	�ek$N��8�i2w���Ej%@{׳��T�rk���.�;�.��-i�]h}�����N�6� =5�5f���1������tsM����pp�O��_=i��#Gz[����`ߚ �K��ҩ��pV�kW�����o��I�]��O�oA�v2"?���C�%~�;u2	�L�ûl�����+��S$bAϬ��8�!�^V#DA9�2`�,u�Ƈ���#I-l������݀�z3Ucflڑ#��`.�T����Wd��nD�XQ#<��6Ldu�ٴ�* �7����vlt���CA*~I-�>d����ȫ��BX��6Y��|�)7 ���`���l CE��x,�-�"i0�b2����g��@61�W&"�MҠ��@]�W�s|a8��J_i��LR5���m$"8�]v@��W#�����~AyO�xSI�x�m�^4�Yd\���`�޴�b!�QW�є���ݮ�<"@v%��v��a����J�z��7o�|e=�͋��r�7`��O-����_�w�� �O�����pmͿO���R�ڵ^��5�ɪ�����$>��"��X�D5�ک��A:��#����B��Ly�X�[g�Ci�)[��x�ʟģer��zek��#V`�8v�GS3��ey�f�Tlex@��v�FZ���C�O�� bмe�n��;
�cz��%_@XHӳ5��W#�"����Ӄ�c�'�ߦX��5���6��h���#�T�Tz�D�[���X^�:2�i\��,*�%t�����6�v`��!
�W�5�]���c����m��F^�I[禃H��<�H��"�c|��������� ���8���hH�l�@t-��>�V���L�0�S����D��樨�B,�0q�!��5݃�s�O%1NRٶ����p����-&w6���&��|��5E
8�XL��n���I�A���Q�E��w(�*Y�X���Y0��6��p������XI�i^~��7�h�vC��`�)r ڤ+:f���'ظ�B�:���W���ep�z�M��s3P�����Q��n��\�P�#���\Bm�`��1�@��׿`�[��-#񅎯��>�0*13�I�M�72���)�$��1�@�՘c�^m�Y���a^�
�&@�p� <��uT����Ͱ�J�78�e@m��.�_&�v��o�p3G�֗�ڿ�·�t���v������{�UWy���
s�v�hۡgĆ��1'�(*�~||�X�6��W� @@XZ#&^�3��j�p^�.U�鿇�2�k���W�)�]�ر�*�X� �������fnY`F$b���p����/�
�S>�A�GF��y�W���a$�t1�a�S��"�S(�b��]� 4eN<!J��[���9h�I�	�0�g�ĭ�����!����8����y���s~1s�)��o�Ŗ����a��콫��?���	�!�׮	X��F��D�����Z)���_:�B���;q���w��B*�i�^�[
Yl��AW�NQiݚȢ}��/x�Lr�4�wPx�*P*�/r_�$�V����Ӎ�>��V�P����Kw�R���RMJ�Թ��e��5��v�×~MxB�x��Ԭˣ�bT��!� � {dP��w�3���q�Z�/T��om2�M �˱�3J���ā�[����G*��W6�a��Ix09�bX���W�k{�W�}��x����U��Luݔ����T[`��-=��Q5b���G����'D�Zr�E�sOx�23&�CW;�*JN
*Y�밤��𡮲s*��2�uY�i�+���/�� �f�Ap/Z^G�D��d��@��1]���/[Q8W��������t٠�' �8�C#�?��쒟7{����-�k��g�� �xL���ݠ�/�e`��AZ���`��>� ����R��- ��lL�7�}'��n�o�CM�Fc�k��p]X]<>�U�P��^�U��1�ED�q�9�v)��jzʛφ,��G�J���TA��7��)Z$�,V�Y���E�q;0��l[����V�����w���u�D�0��$�SD��	ׁ�bl�2F���2D~��d�-K�2�@\C��O�PV�喦����w|jo7�ǌ�e��F������űy\��ٌ��W�/�<��!�.��drf��gOC��C�Ǻ8�xsw�h�p�i����I�o|�ױq��-4�1M�W����M�a�>�a� ��Ì�y�:���Ub��-�B�؉���rԍ���o��9�&��_�<�|}H̖L8�����M|�x�38[��h4	<�l#��?�P�^)�=�ϞF�4W)���́J.y�0E'-��L(8�ח�maOs�(�h6˥���B�g��ᙎ��3_]��d�S/�rҏ�����4p�?�Vr!����u�Q�I&�8��2K��$��������AL�Ő�2��"y�3�iy�)ܫ�.A�q���F�z�٘TI߹o�]$	�$+�K Nv~�Hԗ�e2)�rjF��~�CV�j�$��:�2ҔX��0���}NC�#Q��[`���X�m��]Dc��(�!{�粟r���p*����R>YWq��]�����%�d��TK?��ڐS:7LJ.i8<˹�F��������plL�d��r=2'�V���w����?���t�a���/+���)�sף�_�E!l�CA0��"����V�/m���FsJ��� ��O�i��±������V��()�T�����N�w\櫾���>!��ޚ7�aWr�B	9΋���+��F�Q��������v;�BC�k}��}�5�q��ܺ>ﻉ����Ĕ��z���$�mc$7JS�Y�x"y�9�gaZ	0,��A���3���I5�A]��[+�	��dX�YJ����b���A�����_3	NMjѩQ5�x����{�|!��%�_��������?�]��v�Pae��]�E����w���K���/���%�K��5*����!��0���|���aWL�
�!����(mn�*�A�m4�q��>��0�%GaTǘ�a���Ƿ��r��A��kiF���|��3��0����R��o�Q!br��1_�!(F�)����	=�<���������*"�lT�:s��v����D��s�����f��=��.�O:�����j(Wb��l�b:)<��8��E�ՒM����ihmHz���-��Olg��I�O�I�Q�D�����<��	H�����v�*h���d�(ٸE�
�.o\(�X���A��F�Cv�|/��I7�� �W�r�����mE��G��u'��4<v���P�1�m@Z��P�`�r|��6�et3٨kA'AԞZ·uy�d?�d��h-.��΁��$D\�vOl�W�� ݜ�&�Nb_���봈ncŦTϕH5F�x	�7<D�k�[[�2D�𷭔g&HM$�k]Z+-�!��d���to��X�7Ӎ�`[�U8���)�a���~��N�_�DD��i���UG̵�eٗ��@�x����K`&���Kw�f�>h��hɋ��hfX���^ T�����_M���J~������@޹& �k��@��+h�+g��� �)�#!�|�0�h�w��H�m��1爟얤�+���X���m�E�A�=c�eB��Q)�,1�I���,�@N2�ᵨ��;���E��������s3�n�P M�z#ǎ�ǿ���d��Ѡ�8IK�c�]�:��E 5��1e]��r�������C�#So��e��	/�e��O�%y��ȱ��_�����E&�X�HYb�I
�H&X�֤e�w��)���,�~؏��B�@�c@�
:2ڲ<��x�0hnB�9�u��r��MQ
"*�w8�t`R�*�'�Q�9N]~��z
cy l��bC� >�i=����L��ݫ`���m%-��.���W�'NF��0����3'�QE����:6u�KaxYt�4��d?�4�!�g$MLm��sH.�A>�x�װ��A��Y/���k�;��1+� Z�LZ�F��F��^Tb��o�ا�.{\6٪�~����Vq�5���MV0��w��!8�����Me9�� ��+��[	w���tn�]�O���C}_��.L�@TF���ST�I�rk��)�9�g���� K����!���h4���9����tپ���F���1]�-0�i�!Ί��gʦ�)8C�/�
����z5������Emq�y��=��q�����|�IȰyѽ⃼�l��Qrr~����:;�z_$�����;����G�(�n�h�*�ޑ��4�i+v�y�t�H�煉�	��z�o�x���ÙO�(JV�Tj��Cǰ��lu��tzn�wO�E�L�G�҃��4�d�a��p:e��AKӮ!=ŝ�m�'��'�����4�b���*߂":��u#eF��w���d��a+ʔ�V�������1�B�H�;6L�iL(�C�B��+z0��Xo��k�5��튜F���?�/G@^���y�W�j֨�Oe�Uf�(������VW�{8��� ��k2h&�'|ӂ\�Ya|��R��Z��ov�9n<x{�z���g�"�Q�[�]�z=<��5���W�ry�b�əkD 3��Wh���F ��)>�WS-	��\y9��A�<<�� S%�6�"�&=�]�]���1"��ӶKIH�-B΋��0�ThM��I��=���3Q�-�["������?��^�zU��굾�
��c�S5�>����)U��>_���>�=h՜]�����oY�cJ�;(�\�cCkq��ƒ
}��8ZSE�Y
p����̫m�0�������U,�@�nu�uӻ��CZ-�´�úL��\Z$q�|i�	JKU;�굉E`R�61|��:Ռ"R<�+E�W�*�ku�#eߕ)C;�x��IL7�!;���_��l��`��U����m����$h�! _�M�q�bf���ǥM�v�eӡ�v�D�Ɨ�b0�������SH��n�tf�Uf���e��Ҍ>�#N9�I��C�5�:
�e�e�Vp�����F��5�w|��I�W4o�i*�%�k�V�w��i~ŋ���zE����n�ᬰS��9;��nx�jhR봹���n�`p`�6��%c����ɚ콨)ʢ���	����#o,>��x`3v��$+�o1@�Ӹ'0��x���_gv�*�X��}#O�w��8�^S�Aj�)�[�P�*�X�R�r�    ����HX ����砒H��g�    YZ