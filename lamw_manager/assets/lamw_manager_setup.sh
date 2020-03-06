#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2867317462"
MD5="95ee1cf5148f42100f32362856e137c7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20748"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Fri Mar  6 04:50:46 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j�\.?Z�qc���r��nߴKE��FXսy���r�T(�E�qTq�aÂ:���(%�8qFk����,q�A:���P|�#R�����TCJr��~w�frƪ?��T����G�Y��tQr��w�J<p9��0O��T�0�6J�Oa\bq����jW���ʧ���G�%<��r�"Z���Q,���x}Q�K�x�]0��NS�;��g�k�J~�!+��C~���6�ǡ�Iҝ%��;������W�����"��I��>k�CT]ɻ�����qH���^[��_�f���jLJ1Ț1��/�B/���EB(y�t���XV���ֿ�zy�k�:)d��o��:��TS9pn�|�1��
���D=*x��%�Z���2�����;�y�P�b� x�-��m�Y��v���++U�¦+e�%M�u��)V��v�y� ��.,����$&OTd�=X
QtD=T93=. ��}@�VP�i}�P]g&Td����^�me��������H��[���O:e�<DO:��ؑ��k�*�����:��ה͎�S��l�1_��!�Ί��7��y�vN�Ф�^��O�腝"�&�@�_�����>�5uˣyn�:��H�ɕ�M�k��	�G�4a->�)+���ᣲJ�c�ʛ%>���`F��c-/�M��S�f8H�h,����s��pr���3+�����! �%
�������m�˖y�3�����[>bC�ߋ���
��~mo�w�L��JoX���o1��S6ĵ^�]��&�B�p��;=!Q�j"'�HF�����\�߇�f;t8l�-�
l~;�A	H�,�����kP���SCa24&��C/�	��T����ğ!/V���_������2LV�����?c�^
L[�{�h#��6���$�;�G�Ԉ�13z(x6�Տ5��r�qܑj8�]�eGYH�g[���J�ˋ��hR]jd\��	���pXD��?�`��"+w*s䐔5]�`~U�-(!IX�q�n���*�"^�����Y���>(q�.�����=Ã?��'oG�V�;�nd�>h���
�}��J����Tm�N~k�E�ȎZ���[��a����6�!r��d���ʊmQ�4�S2�\���ѓ�xg3Ҭ�Z�;�@pQ�~�(���m*�#�F���f`�`\YU-_��>�*�;����lkF��	�~�.+�K���qB����Ǭ�=�V�d���ݶ{�]�.T���(��Ɩ��WXH����L�)�}e�rs
;ys��s��Pz�F+��W=D0���ޫl-ݝ��<"�+c�"nm�����"25�-�R���V��tA�G⁆�S�����ѷ��=χS0�y5��/��R;���ú"V�L���]�H����Sߜ��i4&m������&���[��Ɍ �w��|I�����'9z��&��ء9��`����]A �{z�0��Z��ô3� �@��x�����~}z{�la���̭���Q`��9ͤ	R��o���5q?~��>�i��J�K(Q|�K��EMx�K�Hޑ|a��`L.�]^��� ��G�0��~a@�;�!:���L���C4��`jAN{|�����.
�Di������z�M-�}H��U+��i�:�,��b������)��ћ�!�I�O�W�R��i�� &m �~��;ښv��_��P���6�$߻���։@|�k����Ց?�4Z�^)(�@�l)�=&�^oS�4/�<��8���G�+�q��+�P���4��Ԓ2q�zd��W��gxP� skv�t7Mc�wx3�"�/��IHae���n�lZ��T���3df
����8|5w�a3oTbڡ�/*�']��)!M<z���`C�������*���0�D�+}��19�[Q�{��[00�^~l���"��J����bd�W~sl��Ge-�35~�x���]����;@v �
n�u����~R�D;�E�)ߗ�Ȼ:�'�Qy`aI�2�J���`~Q!��U2�Be������(dڛ�\��f�b7��Z�r����b�I����J��'�~��yg���4���&v���k���|t��EOq!�^��W�! �&�]P�ҧi#G����W>A�sY�4���k�>�ɐ�`�r��HX�݁N6RѮ��d.��	9~�W̠0=H�4PM�J�����2I�3�2�[唌�N-��
(8�v�O:���A��;ƣG72�>����0_�"�� ȩa��RW+/op�D��Z�X�"Nҷ�6�yIh������G�@�MF�Y $� kNP@␠	`�$���;���ƛ|�/U�����gxIf�M5��� 	�FЌ�`�����h��3af@�[�Ck�'9��H�K�������^��' ��j�t��������K�y|��͑NL�%Y��R��`E��*F+�R��~�?��o��u��=�9�WE���}�_6����s�u� ����'����x�sE�������/v �$q�dh��W�:��z���k�,Ɵ~~ꖾ? zd��)'����G��o���-�؋+#�$�$$�.xX��pFH0R�hu;��ž��0�[����h�;Mm8��K�ѿ[")@���P�D��ఊ��=]�����I�0I���?ݙ*�I�zRV�W�IP�Ym��������X�	N���a�k�d�ۯ�pfrifm}�8�O���=T�G������Q�Q&���~/�iT��?zvƷ�"t����n��O�4��PůH�@->��)��c�x2�n�27T_�����qF����q�&�X㢯���]X+}%v��<�Q��S��鍝V�<B��Ƙ�LnLU��;w7jiiv��ZH�D5��� ���w�FǢ�	 ����t����,@9����S�>�ӣ'�9�gߐ�û�1C�B?({W��@~�i0���B ށ� q���]�K3���v�Z�����ER��J������4�@�F#.r�>��Ξr!��<�0��]�$�ի׶h����vZP��ɶ@*�ڇ1gJ�j�iV^ZN��MJ�AIn��-��Ő�L��`�^D[���S�'�~��*薒TOՖ���|�`��Z��w1�ӗ�_뗊h��&�7{�����$���u?��O�'%��!hZ����!�y=ME�u�r�!���!�r�{c@��� R��caF3��pA8�p��%6eF�M�ޞ�40Hl�1��1�wwU�\�o��:䶑9׊�S�T���Z��(�W�*�/5�0{���=&��"�]�K��A{���tҞdf���9T�;�'=ʈ�y$;�m���j�;$&���
��ǫZR�1��F <�)�:��k�a��BĀ�џN��Fάz��!��	LgP:���3�������n�'5ݓ��t'\����Z���\�o$%e����FG���g�f���Γ��I !j�LR{�Ӄ�y7C��t���2���v�����R[�$�^�#RT�%ڡ?l�ճA��X�PIK����o��0쿫��k9�����R� Y��A迚>OFzp�癶>��׌�{	=�u6��tl،A3C�1>��?�B"�R)τ����Q3�������p����|��a���z�ko�le@:mh��aU��k>�ѻO�r���v�`o�ĩ��*�B&4\�Q�:��R��dӕ5P�O?E8�Z<��_�0���A�������ڛ�Ҝ�?�ZO�;�&�E���N��x��̂VCb����k���h����7�\��>�:�$,ů!za��,����#ѱA��%q�T�D����;�N�i�� ���>I����B�%LSaV���oN[,�܀���k����$�֋��]��y	dcI.c��nǍ`N�<��Az��](ue��ؽ����n˃iel�����A�ls�'s�M��g�����$|��6M��Z��9���NbĞ{|y�������K�#�zй7�du�A0�	$b<���M)[%e;0�D����κ}ţ�T�w�at,�I���>m�^���P��V�4��w0����]��δӏz�I�JpBH�zY�5�$uѢ赯U����SRǐ�F��Hna`�����c88��>����7��KL��5���>L���ɝt�D�\T��#d	�(����|�� �I)��2ˌv��D£�U���EN��~)ų ���ϋQ��gV�t����X�`��:��{�}���v�s���jp�5��̒9��������L��P 5�bSgC���(_��j���r+�9�dk�\��@E��{���1��z7]ͭv��?i�Oݘ�CC��<4��oE�Kz�R�x%����Š�o�p[�<%�?�Niش�8�+S9��͖�3��{�AM�z_Y7����!��K#y��]�KN��<G�aVJmC�Z�%�)߇y��":�ۗ��L6!�P�S��:t��U�5�n�om� �8�ר�ϭ�O+(	��� ��:��V�@R&��G�
���ضƑ���� ������r/;�̝���d��C��o �zG�x�*ٖ�9��yvY��S�@�$�O�S0���h��ֹ#��6��*"Z%����v���Q��A=���2(8��������MD�rA�Ǎ8������g�I��b��zT���J�#z�����@c�����?��) D���1���+J�(���[�j�J�T��>恷��2S�꾭w3�!F���鏟�U8z�"��"��[��]�5 ?;j �����*���h�Y&~k^cNq��3��iP�*��;�EݬxL;��q��gU�;
R\��?����{X���v������I(s�P����xO�˔24Ӌ9��9��X��_�6�g�U-z����d=���L���Mc� vt�����Y�k�l������!6c���,��P�j����E�Ȅ �$1�Nl{ SbfX!���SJ%˙��]��չ3�L�ּ�����vx���ٴl�D���'he�
}��_�WAyf�8{����v�E�
0� �j�!2�ۿ/��Cw"a�ʐ��̹E4`�����֘���%'f�;�pA���Гk��@����),?���m�y\�V&B8��WA��W2��Q�_H5��Nc�褛��î*�	w=nWs���K�[���� �bMR�I�[�rkJ�|]�Ѭ..NR A7؀���◙�<�b�[�$Chݿ$��:�R��F��N�M��"H$SrWF3�H����X��H+�ZT�8�_D4�Ү c���!�8��u���n�\�P�uE4I5;��v��ɻ����H��T��tG
}\
�dn�я0��s�l���T�x~и Մ<�&a�eD+�6Y%fq�v��A��A�ON:����nQ]qy�K흢 v�XK�sx,:���/�_�;��fbCڧ
�x>���GvTH[4��喜儣S�5
~w��BIb�Dd5�k�0�*��W�Qas�x���DB�ž����&� ���Z�ӕ�o]�����O�n^,�'.����C��]2�
�z�l/j=q�"5v�N<#�ۭ9�� 1RR�jb5����%OߨNUV~���-�ix��Kt�;h�j�S=�� �$t&kg���ի{�͔jX])��ʤ����1(3LIN˔[��A�Ղnm�u`z����]��Ǔg�#όMԾ�0��A�f(]3�֔xWqp/�	��K�}bL��*�'k	'�>6=6���A3�ґa��f.��u�5�����uX�C5z���/��I���:�ӈ���_�:�8�Q�M�ƧI�@�V+P����g�`KfK�?�=��0���]���4F�ځ4��(��K�r�T�l�$G��9N.�>(�{4�D��85�$�V����*� v\�
V�-��b�%3WT��d�҅9Y��D"!��ˢ�x�h[�LH�_�z����y���bR�+�(~c�͒��zB+��L|�]W��� h��Y����׾T���9���T0� ���ݫ�>D{�J��S�}GC�Ӷ�a�HKY�Fo�Q�Q�`��sUJIH|�l^�v�����ܤ4�=?6l!D
���#������PZ����"4s�j���fb��gb����^�^1��i��)Ho���*�P�D�_DMj��e��(�uʑT m��U�殭�[����c*��_n2&��A$��`�A����d��\γ�I����1�Q;��=�Qj5����(�� D� �E�8��x ��u���qeHH̫��P+���`#On�̉��Bڷ=����O�zuݤ#�%����t*�-@��E9i��6�u���R�.v{K�z���xl����'�Q����"=��I��jly�l~��&q��f�+Ĝ�d�P�Z����*���wC���9z܌�����עv��/�w6�68���w���_r���<5�Q<��$���Ƨn]K��(iG�>;t"j9���/$	���������г(5�n������G��N�d?���Z.c"`���=؞����1���NE- �|G��B��0��=�\j���Qmye^��\���k�^I�M��vS"fD���+�cqW�%�./�hh�`En΃�+R�w2Oui�֊�D�@ йhڊ4!�?�m���l"�=�
M�Z�A��$����BS3�6v#�H����~~T޽/�s��Q�#/AW�H�D�r�_���DTUy�d��I֙A��c�s~���B�D�S�H�u@��?�F8���OlZ�*@��Xޮ0H�`�SyQ˸�@��A���}�u�k��>�!/,Bh�W� 3YЗ<z��ضg=O>L�/,�JY���"��;pd];;��%��yf�F�0u�q�;Ⱥ뱏������ʙU�7S�u�M_,���h�O��4����҇�O[�{�s�a����eQ�����9C6%W������γ�	���;;��c��ml�:	=�LpY�Qؠ����5Q�:V�?if?��״�W��O�r�����w��e$�::6mT���y# ���R��VU��Mяsb�E&�/֙��ux��u�u��IY�qH�eVd�01�)_�ez���7��R�+�[�����C'����4��x�1����/����\�aڽ��;��
?�X2�D53�{7�v��lSCg6D�����?7��ō9��f��:��
EϤRv�L_�Hde�:��K�I��K%,���R�Zv$�ǾMc�Ԗۜ-�U�∖j=�+(�����Չް�ѡ��Ne�GC`�OPM���1�>�xm6i;}�[!nt� �4˃l���I����w�P�.Չ=��:�N�k� B�H��#�q��Y֡��y	���h�O����ž	7�I��N�ڧ�����Z�y����H��B�PA*���2̘Pj�w�Ur�?J���Aʓa;.@T�b��i$�]���}?��=o!�n�qB�!!�(6rƼ���u���2��%c⋠d�2j��W-�$�����f���.�?�'ݎN�2�a^د�t-�
�A�m�'H�`6DP�����^���a�n~�n�]%~�Q�B���_�ߘ����1`�,+�6�Ja��6�Ɗ������$�
˖��v�y�>����TW96�t;/wl��4��s3��cᮊ.c*�V�b�(����n�6|k]7G��3�׀V�*�V�U��N/7�L�Y~��h�}*���������J���F��e��
>����@��I2{@X��Ml�1��4��Y�t�Y�'��Ӭp"'�s�o_+s���I��D�a����4�l��;�γD�W{�.K��k�:i�qGm�Y���j\����M[1aR�|o(@��dY�#m�wS�|嚛�x��)"4���kp{�iט�Rh �*�,�I$GG �Y�(��|}"ሞ]��ZA�������"|e���KeB��6A
��:�(���k뚢���
�'��5������Ǿ�>�G��=mk��8��`�P�_�/�����.R5�@��"��C�v�C}��WКI���0�����˘S�^�<�Ipt���Ľ\�v����vb�w:_}�O�Xr�cc�?�A���y�^�Q����\p�?�X��u�gOE�������ч�]�K��U9Plp�/�C�EDSc!�z���c�^�#Dk9��"��LF�*㜫�P')�����:ʁW�1�Y�(��:�@ҿ$�r�cz��W�����Z��Ѭ�-U��(�f���u=�b�-��]��@�i)bռ���_��*q�\�£�|�t��Z���z��I+�A>�Q���X�?�yN�U�lrH� �ά��Sig�L��ȣ���K��~��b\�⇊a�kbb�B%!����y�h�����Ǚy�/���oM�Q�p��vu�Ϥ)*��Fy��P�Rze��b�L��?��xΫ��ū�U9��K*`=3�-TG���$ў��L�5� ��I#3lT�rG����UWq0@���"��z�t�w,+���G��:�`�As��g(=�iB�ɔ�w]������~��d���RW���BQ� ��8�MF�Zlsp��	#0����Tz��t�O��ڰ�;��O��Ib}�4�b���I�CR/�.���y�s���WG�� ���v�YQ׫��p3X9�����E�2�/��+����lΗ���sR�������+�sO�2����1^�="�=���RUkw�väNH�!�()�1I�A"d6�r�zM��,}��0�sÚ��d��L�=J��Ul�9����\eV�h ,��Mo�`47�U���9&Hl�=i��iT��/4G��ӡ�0!B1E����
L�]���]���!j4
-�z�
��A���H��"�@�K�,d���M�!�@�(Y�#��O�P��˧r[��i���I�l�Zd&���\dX�"P����hN��n<��V�Z�Xp�F������>Ȫ��@U2�g>C��E)��~�[�x����}��1#4����T]Ɏ|���/d4�d:]�J*�� �a2�G�=йg
[�0=��Tc:@Yl�1@�2s���
89�\x[�!�ڃp4~����,Ķ�4�Tl�6�3K,;;�a��*#'j޻��@P��)��!�v xkN*��S&�UU)LT�ݻ�2��ю��)s��9�~�瓡�ד����P�|#i;^V���[�����$�ն}J>�����yo����M�gҁ�'��o�!��dyQ�(ؽ<�|�xk6\���J�3}Bpg�q���̂ԭQ�UDk�wP4���*S\V�ү�Gf�I��<+1Ѐ�WE�������lz�w��� څj�m����e\Ɗ}�b��
���p7Cy+��a�#;�=Gm=�u�N��[]�k��{*U�i�!;#�d`�7�!2,��A��ʆ�js�'������e�z���(���e�Å�3|��sÓ�~J����v~<tw��ٔ����2�4F��=�63� �A��u0�r���=X ��^�Iy��:W����N)�	E`S����6m���{S�e+*����Yyx2GZDs;��Hă��SC=?���)�KNm�Nķ�0w�=oʪr����q�j2����U-!�3!R9�� �I��/���,T�D�!"
#1c1�J���PS��)Y���p��q�b��J����R���EK�d���	���̼���7d��b�:,Ƀ�h�P�YZ�씕,� �~�d�AQ�L����}�HEtq��$��r?D��������D�x��dӦ��QdP�rB��D��O�B�ʮ�(QR��4a* ��_�~����*`��u�,�W2��oH�	�-���{%`���}-�0�����f�$U����q���Q�]��)ǚq�5����F��X{Ⱦ��&�e�9�zxX���t�ر2�!wf��&i"�ݐ��B���{W��_�"���P9S�awZ����a���{Xv�-��T��3�����[�Q:�X�0�Gvo���?hC��9���/�n���;��d��w�i��A[ď��Ov�Cؙ�-[�?��H0���!c�ۑ��d�Ao��D�y�� hiӣm�^�M��(��r�Zje��z��.�3K7}'�G�s3Dhvb�$�����y�\�ׂz��1���O<y�VO��.}�����[AP\����h>���sT>$��酾�;��DΎ�(,!��j�]�^mC����9����J�oqdis�F�٩��o�D�U.*1�<�~�EY�w0��x�y/X�I�f�j�C�]նp�n��nlYfn��֧�T@y5�~DX���#�?�������(ͫND<g�^U��̏�S�?�ց\�\��v�=�.�yE(��؞uU0	�k+{��D�#�L l����kv����h���5
{3H�:r�?�ل?�<l��bA0���|y�,���^��!W� ��h����QÁt��W6Jb�X$�A����B������q�{�ǎ&w�Ā~J�1I��Tv�2a2���Cmd�υr���vC��%0��o s�A0�3V!�{�G(9�l������B�]��$m�f"G��¶��3��xD�<+K(���?J�:�E�Llc܁ҍ��%_;��C��G�F�a󌛻��s��S]8#�;ʇM$��8Z����ƢP�4=_�RMI�����ֹ��9�ݚ�/����)�T�t���N wD�o� D+Յ�_�=��a����\7�Z�֎"B�,���L��s�7S���3Lk%V�<'q�@�+̦앨Ľ�E��G�2�8׵�;��[Wf�gm~I?�E�<6Dښ�q8W|	W`P���3��������V����
�b|�m�*o:>m���-ǆ��h�0G�E�;���OBN��c:YBs��`�$6X��P7m�T/�V�0�HR������<i`�t��_�F*V.�M�'8`��t����)��[]��
?���UG���$4���OM�;e�N�KF�Ӣo�tG�'�f�!
 ���_�RF��^d�|L|}�_�!��ͻ���f��8������(�7�m��[��3��"�H��Ag����s��5:��Sv@������=�����B���m���\J��;O�%��+��={�ky%�Z3�G� gM���2G|Z�{K�x(�1!�P�����٤��݄�h:��������c�=�H)��� �<�C�}�*�z��f���(�`D�y�xn  ��s-����Bʙ u��|���7Ht��7/�S�݃�6P#ZTHȶ;��hp4�P�Ï�B�-�Ve�4M�֝7����/V���!MdpU+�����
&Lن��ݘ=�f�;��2_���[�PS�ɇ�|�O��5}�!����Z���(�¨�௾����4���I�)GeH���`���2�X��*���	�X�������ٖ�����4B�� Ơ����T��͟f�Q�m i� �E*��o�풯��F�Db�X<ת�mq��ʞ�b�w����GQ��b�_K4zs�$Љ���v0K,2��w��u�ђ�6�uLs�e
�h��W�wD�\���]��d��X���Z���U�dE�$T��L;4���z�޹������-_Xi�ڭ_�NG�Y_�w�+��D�i�5y�$|7I�5�!���?i�o�f!��7��5��`x�v@��+k}����J���l�zïq�m�Z��;�� �e8�C���o�\M+ :�Zc�<Jx�X��
bz��V�l�|��-5�����=T&+6�*�;�%d��I��1>[��ܯ��� X��ҟ\Ƚ��Qҳ��%e�
��;���"�+�F�݆���X��Cz?�z�|⽱צg5�yV/�,.N�B�>��YB;�SPO{�@V�V�T�_�S)�1���]J`t��H�96������]r�z�:�7�"���?�3��ݜ�&6ؚB�Ҙ�U�i���3uP2"�o"y��̌:�� ���A�^B�4`���W�)�%�|��6w <WE���5��~�4�a����� h�1�-��):�O���w��ue�F�=���X�|��$
����]s|�J�f��H+�I�hov jfn*0��?�/c��a)���!)��y|�}����-���>��1���vs�c����z����˶K��(�R�5��|�X"H��/[�C�hy:$�˔�1E���.�3��h�+W����l"'R��{��"D7��C3�����%^�'wU�T9�VQ�!�Nsxwj��Mcf�q��k�v����.�ҙ���Q�#a`,��L4E�߳SP�É)8�P�r]��DC~U�">`(U�mzKb��ύY~C��æx�[ h3�4��f6gd��Z�=��A^ˢܜ����>����J���P��b�8�q��'��L��ͫ�6�Myy;!���Q�У��y.WR�f��.ρc=�8�0"'{Z�͸�@� .h?�i��/�Uas*v^�	�j���Ө�Q6j�u$n�Ta ��fm����P2�j�nsm55�ᡕU������Fe(�ֺBK�6^��8ے߯��߫;�I��(x�h���~����.�*7J>�Y7���nds�T�e��=�����k�>�A�����\�;��H�+t#K��7eW�����P������/��Yd�����AySE;�r�X��ln�/51�)�v���Ͼ@��9�r���Bz����Lr�N�J��*cFC<��C�C���B�'����ru�B�����7�Ɗ���:{>W�t���v�cN~X'z*��+�g�yE��V�d�?��tY>��XB��6.�|��)�V���3�|�I�>�p�UR�Ɗ�\�)K%Q�P��c��d�a��W��3�NP�����#��奩^B����ޏv����dx���+����X�_���/�!Wv�'�UOCA�Iӥt� :B'�7��l�}�9x�L{�@o�;g�0�l$�� ��#U`�}���2��7����L�/_{�ڔ케B�h�����aAQ��7�B[TQ1~�QӍ�w9՟Z��$&]̩�i�u%�����8m$�1�|��E��(�}ys��`�$�|�R�&�a�B�p]w\wY����H0�����_36D�M��m�c���������ř�3c5���s�����N#��R�Ҫ4�b=SM4'��|a���oj��l3~t�|�4 sv]��O�Rx�/����A�K�_Uv5W0��Ģ��Is����*� [D�u��4ʡ�eQ����\ؓ6��yҠ�W�s/e?	A�b��r�B�-�U_�+&B5!Q�Z�N�N.#�Rl*�,Wf�'@I��$����Sl)*H����T�ot��'4M�^w���_g��wA[�������w~���odv�v�x�ǧ�2��)8��[Ī�:Я�ι�^�Х�bu��d�R�|.�� 6J
��u#�z�#����J��K4(
�	?�Z�����Bv�8�r�q?�� ,�$�Y&�iW3�"�6��恡�Z`g����p�??&ր@�,	/Y�89��P(�:��RS���6�� OŖ)���W~*@�j����{Tv����\O�D�Ɓ#����9�p�LC��~�tU�Yb��[	�=��kZa����y�
a�X;"6ͬ��G�3er���Zy�V��Q2�k�i1ܪ�6k����)�D��!��s�k���ߑ�/M)�����	�	��z��L�Xq��mȕ5��M��Ϥ'cH�_�goV���Ki�����>M� �)�G@<ؠٵ�6V]���g�m�E}4l��y6`�@9��������yF^�xSe1q��L)R5#D��X+���*\�'W23��s���W��s�bP�H{��%(LWn �X���3�؝����y� w�M�Z��/q�x�]�4�@�V�i]���
ĵv�
S-󬸷[��<����[?��$�����\�Za��Y���X8h@k"���5㙔6V!��`\�8@�a}�D��[�� �J]��GŢ��p�%��[�֢4��*u���Z�h�
W5N���dč��EN����,�����w�F�٣y��7V���Z�P2V�zU�*8����V��N3�<Pzf��E;��zAN�&U�'�&	�>����V0�%	��|���N��c�ʯ`�T��ĳݖ�ĲB��q0�z��%�Y��߰k��G$"zO�p��d���u�4J��cX7L�6���O�,�=��ss��ZK�Ⱓ�E��^_�b���R3^�&��o�]�)8CN��x�un�!��톧�j�*��?����
�����+x���)��,o��H��:J<�|�O	T��`o���q�����/��{��{�;��Ij�k˰H8�9vk �'�m#�m�D'��R�֢	d��Z��L/o㤍��d�����3��n9?�;����4��?4_��߽w}�U��N�gi�:Z�d��-��P�4���L9�	0 �Q�^�+A��=�0�=�d�����_��7���P�2З�z?�9O_"�^u�mG>A��N:��� ������"UU{�!��Þ��ZK(6:�<����A�4�x��[�19M����k���1�٨��(D���:�@��ԃd&���9a���kaH�D�<U.ڛ��
�,C���t[���S��Xһb�������כm�Ƣ���\��n��w"u<�&&��8�SmG�wb�W���Qډ��YP.����]�da�W,��Uz��p����֌��Ki�c�����S9�W0*3��7�Y������C=ޭD�މ^�߃���� �
H�A�Kz���4���J.�R������BF��;�0s`�����5��2��J��z��"2޳�������UcW�ɕN*}]������e��G6�#�݊�l���o�k�>Q�y]³�?�u��s���l�%	{�5sh#�V�6g1.i��i�B�_�G=MϐP�PI���-��}�<���d����QAb�I�J�sna&�0<+e7���z{���a��._�V�({u��h�>bS����gQ�t�R`nA�v#I���H��0'�%e�n��-rT���[�Te!��WN;µA�g���~�3Zyf�@�џ,�L(�ʗ��C&�@b!NV��P�i����'��
B�e��{�Yw��Z�m�2�ݶ6��yq놙Y��u�jʉv�������	Z�J�����t��}���Y>�Z���*OE���4A�Qm%&���uZʼ�Veĕ��U�l2���e�\�S�1�L�&��0�h�/0�*3�L(�h�c�N��C�	��.��\DEf�ǅ�2���/����{�� Ŵ��("]�ʬ����V�粜�4z�߰7j����$�@}1�FE��T�֬�cV�@@M�!P�L>��ǽ��+U������`���� �>�*���³B6���~V��l�wAy[S�[WhQ_�\����M�O$Ni����wᵃ�CJK��#}���@^��I�����������x�,Xe_	�>o>8�=lC&L���1���0*��Yt05����̗�Q{G}B�6�c�0UZ��@?�E#z$.��W�1�*�jMǈZ��^���:�c��O�p�x��[C�iMݝ߳T�9�L`����B��5-���VM}'T�ێ�
�AYe����/�E�k0���aJ�E�2���tK��bƷ+��s���"�i���<��}��}�rs2�e�̷x�=(��vt��wDTa����a�[^��l%?7����#������;"R��-�!��P4�pM�|�?�L��r~s��m�*=ۚ��s*[�W�Z�w�+��X��v�)HV9�2�z�m=R��zt������#����>��  y�����f��b�^�-�l!�2�i=)L!Y P5u����t��W���w������F��c+��,p�@x��*UɤW>��p����nHKFw�<�/�?�g޲��Q���*5��3x>�!�v��䃩�g���M��H��%;�`~+|C&���Z!���	�I��L��#M-�Y�/(+�y7]B��^)�W�9a3�i*�L*�%UE�%��+�	⡏ǛҢB��&�ƿO�e�қ0��ր�w*-l*�� Q?�@-�w�If���߱ee�L��[Tj���=��.� <�s�=�g���Z=-��E2��ؘs�a�WD`j��'t7��ZGo֔�G�d�]8�#A3*��>�MK������2���S���Q��T�mu�v��s�����_�؝G������,)��%��M �'$��V=Z��6oҩM8�Eċ9�I��1�A���5}�W���d+	q&B�}BN���6�>� 49�� ��l�&���6�78:� �������j�W�*f;~r{h�����c+:�	��#cc�3��AX��m�l>�<j��PN#V^o��;<��lƚ5�v��u���/�r��\��֘lj�\���[�D�8�<���3��O*_m� T����Xc�`P��=�I��J��2�,m3Rݖzd*>�)	�3d�Մ�����R_��K��d�w�; ��D��RQ_џ"���4�dx��!EV>���G��H���)�:�Ӂ>_�6/�˲G� �ͥ+���|��ښt,��cr�g��f�;���*wgfU(pj(㍿X��Z�L*�*���*�s�	⡳UP"�����
^B�!�z�'�J#8�GE�h; <��r�~�Ҋ嘎5ip�	�ìΡ��>(�P�,������x���ƝG�A���]��i�CC~��'��$�DPGp0/���6̎��VU��x�kAv1[�K�D07��C-�]d5�z^��B�-�&w\��9�a��=������o}�^�]w�>�4����!B�3�B�0�͓���7���Fb#-K�v
@�Ҁ�T|����S�q�B��q��"ly�aY,�?}�9�Zu��8zE4����H��N-[ά�C�jf���v�Cq�e����OMĸi�9Yc g�v#9��ѳ�X��՗m�"ԉ?��x�6SsEuI�}c�U|�EK\�S�F��adr�1�t���"٦7DpA�3_il�&��}�TK���CKz�.V�}_ܣ�뺿a��r��)kבI��M���Xb,�@�y�+G���ODє�M�k���-R0�@v��羝�g��\M��:���	�l��q��	��6��;y��������+R'ow#��c��C��u"p�,���r�Cn߻�#��$̇��m
���[�]����H�aC�-�|)\汥�I�F$���o�#nH$�S�tm���	�gҕd,x%�Ig�>�/�lOJD*߁�&X�s2����CU����j1L��'�Xy��B�1��5�L�q<j��+�A�
�I�V�{��GH�?zY�;�2"�M��BC�m�nY�~��;į_	�23�K�$͇�4���(�£�z�Z��F}����]��q� ݾ�X4c�]��G\<"���@6� V�t��O��p
��,���9V�#nR���O�R���CiZb;����-A!�h�
i_�Ɩ�<��?y.U�����7,ˢ5�РQC��<�%U�f�H�����p�C�e�Q_������ƎE���[�+��b&�;ˬ@�=#���u�_vx�q�S۵��=��Y�.�,���z]vԟ��z�O`j���"\��U���L8��؇��,E���:�t��Sx��BB߹+�aY�㬘�gv�{!ov����Xrl�#�#�Z��8���"��"=�9t�)cN72ҡ���(=����riHͺ�����D䭧@0���k�:A���)������|X3�l �bپ$Y����P��|��GG��"í(���\@.���v�C���g�K�+��1�Q�v~O>�t1;7�"ԣ�0�6ن�e�.��B��Ǝ)�$N����j<ݿ�i(e��ܥ,��x� >9��3fW���`�yl�*�әFM���8e7f\n3�X��k�4@A��#�����gJ�ħ��;#��\��;L�+p���b�s�Y[�/�!���f"�����VlN��U����_��ŷ�p��m�5�Qo�L���T��n�38�n�� ky��.��]���-�%�D�5!�CAN�>֔*�#$�����0�Rb����vH�������``Y����Q|���!���*o�$�aMjCLm�ҿ��U�>��{��"��ώ��QF@�́c>R���4X�`��t�z�%�C�\�y�� L�����@�O�х_���S&�G�b�L���׈���qV� T��=7[�9��(s�뢀]����
eJ\}bG���1����*E��_�s�ʆr�lh�J$������GY��i�����4�<n[��vc���������x���飰��E�!>g1AV��z����q��Q��.���g�^S�s�a���,_a3���kc^���l���Ws�ɫ}�4-��
�Ϝ�#e�w�9��
Ҷ��ìe�,�֭��a����_`[k��ZIT�W&'=���0���2���d�G7s�����	e����~Ɯw[^P��nX�җ��� <�Lɧ�D:��/�l���D�S�'r4�庎���z 6�#�!�qc����+����0�Ǵ%�w����E�!+��:$���?�A{WI��ΑO���~rV��4��;��Es�j+�[5˥a�1���+���_�d�1ȧ�M�)�.�-vK�E7&�O�Bd�l�)Ƕ:�	T�(J�XϦ1��d=��"�P�Y�`�7?0�����Ѽ���G[bC�*f�3�����`��cC_��������: �$�U���,��IF��<��a���޷y�g4`|�V����i�cO?o�څ�Xcn���u���{��x�t���w�q1s�J�A�gg�	�<v6XY/�9޵J�p|z7]=7�t�r
��E�讍�	d�,mw�Ә��2?.kT�#;_�-ER5+T�0(lx��p��#��!�R��~����z�Q����&�e��7|e�?�a]*��F�o�M+��}�y�&{��eb���=kq΀�����(G!��j5���Y�(Z�| A\��I&�o!-f�v�y��p+c�S��.���: �ɷ*x48�WW|�ѐ�H�럺��\���zb��1�.�~>u>�D<�B���ٷ��<���L�iE��Ҷ��9�w=��=�r�-�Y��x
]�u>���Z�`����˥���kwW\n�V�)jKo2�y�
g/oV������29*j%�	�e3�7ݯ�Y:�e��?��� m�N�!�w�n�OEP���t~)P�&˗����h�lc�Q��P(���T��m~8x�I�޲�Ÿ h�E=m�/���s��ͭ(����X�e� �g��-B\�
|AM�<Ӄ)�j뙰���>���@�oo�o��GT	B��ޫ��lC�����/cϙ�m�ib�H�!N^��ѿ���_z�sW\�D��e��C�u2���N�_7��<���Bq�~1��o�c���Q}$M�(x����X~�C�_�T����V�/Z�-�_�ySa��@P7w�e=���͜n^���p�(������z^_�$#\{����\��$/�u����&��YתzID��<��@�`�J�:�U��dQw�,;�1L��,�E� j;�\M!�0�H�D�Y>>U	1�7�;��^�S���F��kR�M�P���0�[xc�����w�? ���i�q����9�Cq	�I!5���	�tJG:M+0�îS!�$']����P��?G��֪`^m+-��Fhg
�����,��o�
S7�����+X�ܞgؠ�P��5#��ST&�s�U��.s'�^\vd�0�Gl��ꂡ�]��u��$^�@RHnl_)�^�xJ�*���CdJT9ܣ�y�0�z�2S

�i��L̷;&��I�_��̉$7\^�f��q�1�Uj������=�<�r����`߿)��D��683�� �O�Iy�Η�V	j�㩱�����Gq13!"�׶1�Y��P �g}bP�+_��;U/F i�r������M�>ţK���#�i�n;"	�I��߻�� V�����!���ƻ�YO���~�4�X"��e�eH�P���$%q �3��S3�ہ12�b�vށ��P{P�a�4���]�Q�~� ն}�$/�P@�tڬLm�Μ]����8I��?s�T�ݏ�	ڑ_�J�c��\
Vtn�";��I_$u��G/��U���D��V9]>��6g]}���]{J�IBb�O9Cp�@�8y߲]�܆�2C#X��    ް4¼�pW ����vֱ�g�    YZ