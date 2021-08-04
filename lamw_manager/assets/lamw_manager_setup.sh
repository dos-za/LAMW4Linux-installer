#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3700757623"
MD5="dbe63ac4c8c66f8ffbfaa931d036abd6"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23680"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Wed Aug  4 13:11:57 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����\?] �}��1Dd]����P�t�D���ƛ��O�� ?:/�g��r�OS��i��`��G��}����p���q�f��߭�s�����&@Ԣ�[�ɶ5�q�K����,Ý�D���X���'o2�9�A�Y�)�1�|y\D��UF�Z���vІ�Аr�\�ѳ ��S!{�k�r������J�WB��"Y>z�V�D��]�j�qT 9�G�����LgB.����� �HE�V�q�nar|���A��J�����Ցq]� ��]i�P�$l�f;ُ���yؕH����.��D&b';j��+}���=8q��n,\!��J�Q�N�.�B��e��A����������ظ=�wO_Q��~\f���.� 
Hi;�U����\�C��?o&�ٻ��&o��IA��`������7*�A&��U$��a�)�c}�O�Oy�ǥ�EXЮBX1��D�߄ߵ֤#�glN��O�<���vF��<{+M�_,��,��4}	W�����r&��m��E����[�p�w���$�ØqC�s�?y�[_KǍ���@��t�_�_S��!�%�͗,��礳�[ŋH˱P���l�@K)o��v��K��u��`k�}K��|����,��<��	��h���Ç�h�� ;]��7hg�;�$ucW�m ��WF���~qS����H�e�ᶋ:��g3'��NG5�Yd8��,jN݊�C�K&��J��Iu�2c��0H��̀��
�ɇ�9A�t���\�۷��gfY��9 ��ߪ�QDK���\U����)����V9f9�`ߖh��aӊ�a>42�Cr�F��s�^Ng����;���/�)C�KAީ��wX&ɭ��Q
":'�P�fl�xUT]���a�J1���Ī���{Վ_���#���XJtaN�W�a4	����k�䢰팶I�Æ��-��
�wp�R�@�E\��s�9PjL�w�SgÊ�z�x�o��8=x����L?m��_��ڣ�[Cꠀ��#S
�9X���h�Vx���X��_v�!E�p�Q���6t���� �����0���C��{c���QNn;��w��G{�W�ί�B�rWNd�52�5S��*��g^lOn�I=%��d�`Y���5M��$���Ti;<�[�=�A�X��(�7˓�!{\�v]��@��v���`�E�q]NN8�:�7v�J7bs��ϲ����x��*YA�����.x�#�-S3>���=ʁYd����(
1I����X��c��<� }���cc�}�m�N�e��x���y��O���lA:Q�l�u"��kdKJ k����Z�����0�h pٲ�!5}�L���5�K�F�?W޻�x�ۦ�#"Ԙη��zI��C�F��a�Jr>��Y�$��ڙѩ��+�R����a*O1�g��R��k���������y��-?f1tb���J��������/ͫ/������bه ���-�A��G�8e
x�L�%�޳#?���
z?Y��l[(��{�x�����r��յ�"=?��n�(h�s�#�ᩑL�K�, _��tT9��9t!pW�ď��'�?�h=�#�y���kwY�]��F��.�ҟX���{&��^ږ�9�A�:��"?�ԫ�����������4
ч(�j vppA�빪2Q�hQ:��X��=I������xv�qAj�������/� ��_�~��<1�P\ض��zjx�g�"t��\����d��Z�;9lq]������*�X�
� �RC�
�Aʑ�V��&P�6+z�������D�%Q��ԓ��Ѣ�h�71-�3�͙�\һ�>p�^�����\I�F{�*+��t#�ց��Z����z;\���1���w,�Vg�pt��?cJ�[�Ni�U�y~�\jT�r&�"�B���Tc#蟀���ҹHW0_�������۷X�����n��X��"���N;YVS���u�14l���ݲ����9�m�ֱُ�[%��-&�L^��X��s��,��mZ��>Ji�~ĸ�~�+����u�������3s͠M,!���!����e��"6/^�I�C�3���0�������j�/蔑Z�k����I|���>�es�m��À,L0�R�m)7��������;�a��z�i�~����>;n�f���sQ�
e����&������鄚��evY/䡞�-�� H3)�]�!�0��Ϗ�|�c;KQ�%��&�������M�6��!���2č��#�D��-�^���P9�@6y�t�<�yJZU�a%�Xؓ3ѿ�
�\���׍S��W�A%�>Y�N&�[�s�CT�mJE���%5�O�}� ���Dݞb��(��A���{5׮ C��Y�w�Ŵ��3.��5���!s3x��2yS���7�O�[b�C��M
�؋�)�ɚ��-w�:�$"�����U��7Bƛ�y/���/z�-��UB�_f;G��-��jT>����f�.� U��T������$Vb>J:�M��ѻ��mq&�yN8���KT�$G/��� d��G�zps?�7<גY�I�-���1Kq���>C��I=6K�Y^���S�QQ&jr�� M?�"����	֦�60������NJ��Bht�,אr\�]�%!o^���
 �ܽ^a߉	�P�zP44�{rm�������Yb�;�Ŭx�l������Jn�ou���l�&�����	��M���V��1��M��oR�N!s7o����݅���ekI10m{h����\	3����|PՊ	M����o_9�V[
ń��˯�e��	d�N"i���eڋO���U¡���A�����A�N;L�3(\�?q�{��_l�/���𐲄���u�&(��'��u|����"a�2q�~W"��9�7���X�n+4���Y�'��#߁�@4Z���5k�!��j�<|(��L q�O0��}�9��k����[:|����}��^���g#��V�
�%�ԕ�.�^�$�&�hr�m߿�_�|��^��8ɨu��㢃`G�h:�8����)<�6�d׋��� �wC����	�p�2d�i�%~�Q[g����j"~|d�M��{��t�\��/'� ����?@]σ;�Kl ��R�����It�I���ƞ�f�^���΢���(��
*ޅ��a?�㡽tB��́aY�nr�wガ>]�&� eR:;�2*��/�C����Ѻ:����!�~�Y�%5��g�m���A}�\p0kt�?���CR*��&�&���,�hYx�{�1T5 ��5�F���_{6���2*���@h��[�L� ���d��s&��좝�y�Q����g�[ǎaNV/~?T6�8Fw��v�������1�ȿ����i��۫(��b�m�3�W�ۋ�H����t���D>s�3�ֳ��fx/�ܷK�?�Q{9�@b�80�
O��(�G&����>��SځtOs=dEۺ��֌V�5Q���.6'���`�w���*�L�H4��u�딅D���}m_��D\���d �i��/;���}M)jC6}b�t������V2EsU=��!R�a$�WJ8��D�~<E+,�����l�B��8�S$t��>}0󉌆���`�Z_h��6�z$<��nP�m�d�o%����Q�xT��h?��9�	|<O����3���rۈ�(��0���@����
��\�b}�~�9���;�5e^���q�?o�I�0h�y���iHZ������w`�	5�0ӎ:�"���ӽZF-���Ib� O;0Å�����J��؏�m�}]��h���%!�� "4#h|S�4��ɞ�3�d�t3����԰.	��K���͈I����<��,f���Қ��y����-?eޖ&P�W�400Z����ަ��m�Nt��3�ﻯ��ӷ��Qr�_��Ў&�~T}Ǚ<ߟ��ڳ�/*��4O�}�M��ecH]���l�Zl��v}�C�Ae`0e����!Q�nC� $�p���s3��g�aW�Q���~43����Y.Px�A3����p��?��T,8��3U�6#�Pe�y�1���B�iE�2!8����%���u\�2#{'T1��r[6�m��=�j⋊@�B�#�a$����Ĵ���c5��7�4_=@�g���x��P���	�-+����G�2�fW����n�
����B�\ԙg8y,��̶(oq�+o�YPanRRh�x��b3cN` UZ� 1n�l��Y@S�_B������Sr�N��Y�"���GB5W�0��p{����h�(����V	��1=�L��R�0�d&�Sy��Ż��`̱"�^[p���Nqr��Eǜ�m\HiHU�I��ۖ�r��� i���0w�<3����L�����8D�R2�l��H��P9ǉ�!B���C`�����a?��z�y�s3�(�c>U�@��h�ưq�@~�8�e�5����r O����jef)0����8���@m+�.�y��p�;���E7��������p��P����We�@��Rrʼ'tA��Z�a/���7��EL�3[Ƙ_�s
J��T��n���挺?���2�
�+)�	�b�%/�������J
��N��pt�xzP��B8�_��ZP�ۘDA\(�Oʿ� 1�]��YSɲ�OS47��6�9��������>p�B�{�Kx�f�k�!2E�Q�ҟQ&f�`U�{Q�чz�5ڄB�\<�"L4�F�3��襼���5~�bD��0�:����hcD��K�W�TX�鄦]a��4 �
L�h>d�PA��
�/}SLA%K�5ː0�����x(k����Du�c�Λދ(���i`M�3	_vbփj��,�?�m�l���R�y�r���}qܑ�DX�1�v ���K�ń�$���V���s<�� �D�%+���
9y�z�9腠Q?:�J��ʸJz�p�e�^�|cy�w{ح��/�g�أ�,= ]7����T�G�V�_�V�[��d8R7��T#��]��S����Ծ
�gnh�`�����tSM��3
p��{B�����ʞ�x�������
N#�kJѶ�R�)٨�4j=���ȟҁg�6�iD�#�������d)o�j�o;)?�� ?RF#��$~ksJ�FAI���,�_�Z�`�q\6uY6XTqOMХ��q[����c%���2�.�J+��.N������ԫ_�
���S�e���Br�?��\R��do; �w�E'�""P��٪����zF�K���q_�/�]�/wg?�;ĕ4�>� �+i�¡�8�L��%L����8�טĖ�ZUe�~��B��a4$&� �<t�X�Sh����ٲ���h�6����匘}��cV1�&d��t��i�I*�/Bq,3��7o����1H]�g�R��D��c3�tvrA2�}��0$�������.P�V�����0�o����:�mA�)�6��C�]�]��.��������b��Oݔ�S�A���t��v����~>d
%�)`N�HhrX������F�S��I��Ą/Q�"�.��>��<ډs��*���Q�_bLH�]��Q��	໏���T�\�f>����5���:��L/�̢���n��s�ӈ�%F��{	 I�n�B������kw��)�gd~��O����y� 2� �!����t���*<�6މM/��������` �$��v9O+*��ه;���[wHhg�Wz�Y�!w ����PZ���q�ܙ믋���d�1��(҆���1�'Z�	�n�@�濞���媿��`�_H>cn�Dl<��EO�e��~ �#�X�K��բ����^�Y�����	U{�9�RN�%yמq�T�ς�-���5֒⤊"�:=�O;�b�HF�Rz���ܳ_R�fB1��l��u.ðǙ⋓Ӂ>w�Y`���Ѿ޳�tsy�8$^�ji�1IH�|�~�HL�c��ca�-V��d��U���Zs���/��L�*\ICnp�!��A�����.�5�|��Z�
�V���*÷J��i��M��w¾�
�U��ë��U[�WQ��_,d}��U` ҒX�ـ�g]d{Ӵ��X#;/ĸ�|��^1:{�+Ey��X�\�ͭf��;U\&*��%��ϩj��c�j���|�x=3W������m�a)�q��"Q\�%��,@�cYl9�y��$��	�l�Uk�Í]��}�3�4���s���~��O�?'����[��P��@�M�4�� ?��dP�kP?n%~���0����*M?t�%����BA:��������K f�b��C�"������TOBaw����TJv{�@��K�wJ|)ܧ��='��\h:E"Ep���������*#�6%+ܻ�$�<Iq}������x] �j�B�վ����߿03��)&xw8}t�o�K8��̙/�3� 8 IU�j{t`%��#ً���46�:��.@�٠/!���K�tW�5��������b��j/C?���)���Rqt��v)+�/�'	]Y2o���q��K���@�yh�-%���}��G8�������ia��{�ۄ����)� �4�/0*�ov��cހEIOy_!�����(�DU$���t��z�N�8n6�����W�G�=|���h|!�ǳ9`-����EF 7�(Љ �(���L~. ��V'����	���ٽW3�\��M���=ПW=�W��3�[0L3��uA�����RL��=�mq���>�yL��S��r�||�C��Wz��2�d��Z\�'���r٬z��j��X���آ�n�P�\f��F�GIB����86,cis�k�i���̠��ޖ��e��W�h0�F���Q�&�æ>��m�o��w�W���끮�@��n�I@υ�\X@&D�w�ŃwZ����ߗ�$ �eiIF�,�e�yqrȐ���M���c?���(<��_�ʪ��Gd+�q� �-����O��v��k<e�TG�<
1�N����p�ȁ���k��S�*%��
���Q�8?�m{��2Su�s�;'���dK�l�T���VM_�Q�O�i΂����v�����"J��jEY6|�G�`t8��7^y7I0�;���q#2A����h���� M�ͨ-H��;4-��)%��7��+�H}.N\���7%��J�~�y��W_t�jb� �$H��*��OOr����>�<<�(��m��e�~d�b�g�+P��Dv'2��m�H��U�z��,�cV%x �ʟ���/�tVKּ�&rn���{gô�B,}�L�����#Cy�fm����t�O��ڕA{ʼ�����x���q�!M"�Hۡ^Ϣ o6��y�����J�����l�J�D�&�H���57T���{Eچ��ZK�6�A�:q)Aꮘ�^8�c20�ؾ�ȷ�\uU��Zf]c�S*�qL��}#���M�$Ԫ���] �P��6������f�P��L!��c1\�L/?�@�D�ޖҴ*c!\9:�oG�u�n�o���v�l��8b�k�g�z�����b���9���U��M��� #��Ľ|+I�i��F�P{(�4i��U2GY4���@�ES�;�.�sC2� cl�!]�8%6�ѭ��Xi��ὸ�ř�-ڻ6��-C��g��r�>�/�-9ED?����Bgɀ������,����h<$	tI�ty|Ѡ����f�ʖoJk��V����y�*�8��"7!��v}���׃1���݆�������dr��:F�����c�B��Y4-V�[�+i�-��ݽ�O-ه
�a�k���,	��LN�X!�a���9a��sʄ�fR���
��܈>֚�u���gAzVY��]�M�8����]�l����9���e�I�K��M�>�/�~�|my*(R�ˮ ϑd!�@���x{�4�k;m6��QY�jܞ�D+OE(�IWۆ��w"^q2~��8�C4bW$拮��!�3�æ1�l�B��Qݐ�����c��`Yz�Ad?%7��Bs��FŻ��{�w���!H�j��}�A�۰��� ���D43�S�Ş�}�tq]7����X�OݳfH�8z�(��y%�Km�X%�maq��9	Z����֎^��a䭆Tq��'�V��+�Xb�a(�^�I�
��T�!�6Ɉ�ܬZ]�Nd����*���	S��5'Ǔ�As����'��q���ʉ)����j�6���j���_�[�x ��%�|��3�=����X^9��\�'�"]}4meȞ�k0�|�$^N�����n��.46��23*�"�=�S�|��)���͖�؃)jSg\Ia |��s���6���C̻��/�+}'�����M�o�H�t�Ylv���뤷iYKL�aI� 1#^t��z���te���6�K�m\�q�Z]��'�쿘hviQ:��-a�RG`���0j�1�N4���vļ�����^����>��ݍ����4� �Aq'!;�(?昖(Opj)H��������zw4���@@�ۻadal���ҝ��߸Ĉ�=WlW٢�6u��<�8���8�J+���ɅGD�2�_�C�{;2��hwb\�d�eX,�83
A�7���
/�j~�� �M:����{�ț�&ҏ���R�	�I�[�ț�ͮ�	lE�mI��s��r��IM�s{�>�t��vj��A	��L��a;w&}�Ӏ̞���&u~�����W�d�9��B|���cm�⛔�(��
�l�Q�}���L��c�)<��edS�q��Y+��Pƚ� Ե�AA?��H�IkH	}e[��P�� ���� ���*��[F��J�Z�i�t���E"K�ʪ3T�z0�O�ێ̙�,A�\
Τ�0�^�8��P�Y�'m�%ѱo����*�������:��2� E~�
!��`��-��Qjؠ�ѣ%���?w�pL/�[�	mq1L��~Y+n�_�3�G�<ۣ�5�DO�1N�D�:F���������v�>��q�3�~�E+�ؑ� 6�|���� M^��&W��MҭJw=����;���Rh9ޑ�U��J�WS<�V:����O�t�_
!�@ ���」��K��G��j�<r��#g��uL�]�g�'�[�ή-�%��X��l��kC���^:��#v٭R�����g0W��)����SH`.�Ԏ��a
����h�C5�F��v-��ƉO	D_�l�����Do�,�t���5Py!�vW��]�"�8ؕ=� ��e�1��o�$3�"m׵XG���͵�B� ��hh�!�gԴ��U���wkG�b���}�� �1�SM.�.Tk{�1۷z5�IN���`�I�u�i:W�l4����L6|�6�{�L8���hp%�n�B2=�Fv$����8'��
@���ǘ�����	�<���MNʨ�jUW1�;��Z�>�iT�'w���k�=C�A��.�M�6�J��k~��=�ר���/YEbSj�SG�O1������ߴ)J,t�s�ޡ��e��BJ4?�'LQsοиH�ʅ >pf�@w/z��X<M���3�T�za��K�򎝈�����Y%9R,.�N��y��I\F��(_Ь�q�}����~)�\3�<��y/����x���1؟\c�vd\͓x�_th/���̏��ඃ;Wԍ}I1�ޝ�ϵnzV������ӥ��m��m�z5��~K�#ԋ�(��pn�FEiᰁ�b�w\�6����MAJ�J�]���d_���\\n��hHFH�8��'��Y'6�G�������+��k�����ǀ>F� ��ƀR�Ю5f�4^��*��QI�+���3{U����}u��B�����/���UR�2u�Ÿ� /?1��&t��T,"#�Ǆ�_S����/�� ���y��j�I�2%MM�,��}��>����S���Qwb����HL�����5ZVZ)������@�7���h0��(w�=$e	Zݒ�+��)G2*c�'�6��qK6�x`w��fc�&̲?��6.;���>mnzI�/��B2��"l>����*��W��-�,$���RcV�HS�K���M��wB��~�^��m]��_p�'�����tY�]�Vn�s.����+��D�pAkӴ��L�V�*m�be����t�S�i���/)ЃY��T��&J�&�8��N�f�w����ta�O�������`x5mcG<=L͏���!�)ŷ�nj��*X��?ۭ5�4����垈?A�v��y��rx�(�L^l�;9����.lLlU�p�h��8(\o�
��zތ��k��>7ˇ�ĥfw]�
o��L���Bx����|�3�>���D��^~���e:/J��?����EM���1Oy>|�?�~�&�hM�Lv�L�W��E�^4�Owݭ��,W�Ẕv��[�e����ܠ8�1�h�g�P����l8��C��
��a�P`�� ��P��p,�Ζ���u�� 涯�ѳ�3�M-+(�(Ir�hf.T�h�	6��i�q��!M���@�tw��d*�Ua�6�vL���mS�����6?�Au�b��k��$�.�m|,lx�����J_wU �I�B���)���MX�PZM�u�28�&l����I�2lf���|R��Ñ�5���A�֝��,� Ӄ�c������H��ػ��n*t��!��=�v�]ڋ���^m�Ȗ{$��\!#U�_�	)�-�_:���'�h{�5zi��hzW�m�ä{����f�����V�t��ڵ��n�c~�Ė�����h���������&�G���9=foW�f���#�����w�<L`O`�.�� �u6� �SQ�0A=lQ����7��X�38���7�j��H���}j�Z��	�����!���>�	����p{��ք�h�Ͽ ^_���)�t��YP\�3�6�; Ė��YІ��G��pU f����:�?��.o�N����+QO��\ǆy��| �.{�ܼ\A��~�p�6$MF��UR47�*�ӝ��T�Y�2�����]�#��MMY��im��z�͟�G�!���6N�����փKoeaJ���*�Ul!zF����~Ϊ��?2j�/淏Z~e��¡rd�����}`�1%[˘G�=�Kc�<��ؐ��k�����N��%I��]��w{e5�TaX����_������"D2�� W��Czt��l�J�גf�oNݭ�P�>j�Sכ�߉��A����c��%��ϼ��tH��t3�
���Z�����T���g��@��o�m�ta��@�aVf�HR���ܪ���=ȦЧ�q}���j`�g�Vr�a�&�%��Xg���q���Q8+c�iD�Nq?i=�+D�Ltl 9�b��~�zMǛ>ET-���(�`�a-*��m��Ѡਭ�:�t�WnOJt.�w���>��K���,��ɸ�nC�(M����[�6|m[�݅i����n���d�]�t}̳S{��TE������l�������i+=:����c�,�ɦ���:���H�͑���|gw�_Am�K4���Q�i�>�l��Q�I3k7/	����q�
����J��cQs��J�HYfQ�=��zZzE��G� �'���s��a9&&�~Cx�:I�������-dF�&��zG&̩B��o���Q1�Q>(OV�0�S�(�Q��:5��ЁH�
�H��1B�'���,)�n���<j�o��܆6��6�G��6U���W�4�n�;�BݟdŸ����(0K���b�w�3�������&���񹞿2g�9�?~���ޏ��G4����;cIȤ,�|�]J�����C|����y"7��[f�A���;^I�^�w��^!K��"7�혋��iHH�U*6	�V�����A����P��Ys�96kr�j5)�F����k��,OJ�uXy[B�I�q/_�f�w78�S�j�w�/��h|
��D@�_w�t`��"l���ʡ��?#�u� ߂-��c:qv�2�ml�]����n�A,{���p�-�Px�nD
3�,��]~�I�C|��ϸ��ֱ\�N��/�>��d����6��l������C2ē�A���m6E�)��M�&&z*4��-��6�k�[�{��l5���E 9���2S����ŜJ���q��1�Z�ժ�W-��R贷K�p�PH����b �7D/�t�H�ϝ����N��e�܅���2�$�X�*�:�O��h́�2��'g��%F�<ɶ��*�!���Eg"�~E4�m�`Y�-������_��Y��Z-=o1�w*�8�$i�(��;,vUJ���K?���l�� ���{j(����:�uR�q|ӌ��������NƢ����9m%�l�Kud�4�=_ ;����J؛(����t\1��Ad2��*PI`E�Fn�6f��#F�/�p�39��.��"Z{1X���Y����6�l��	.�'��*�k�,�t���>Y�������2φ��d���^s���5���n�)��|}�f��W�n]h+ؕ�X���BuA�{�
�s����3�*�4�P@(�@? n��g�2K(���c��TĶT�=��Ӽq m�2\�Yvy`6>\#i�՘/>jT��c��|2&-���_�_��'�B��,H�-mH�����L�h�o���>���[#
n`�I����Dd�1���#�����EO���Z=���%��	#��s]�qf�a���X	���8;�b�D���4�&\9<��]jO�z.�>����&��q80Z����y���@c�BCr������3-��t!���Q��
^,�飣��� W�ڕ���ԯ{:�,J�f��d�pD���|�u�8jd�o�ۑ�<*�@߃�|�rY�DںC]j�~ZQ7&�xy?l�f��&~�C�TT��d_V���NR�����������>�T�rA����>�RΈ��b��lm#a�r"���Hʻ�A�����m��fD=��d�=Vr-��K�#~`7<�����ٽ�qW���	4��iM��a(Ɍ(ʲ��0�B��e��>�"ְ=�`���LTT �1ZW!S�X��z׫g�Fh�w�<����܃�r��ק������Eɋ�'��������b�� 8Υ
����=���GC��s�5��I�.�x�3�r����zZ0OD�O��\y��.���2sR	~�|I�����^�QqF�Ȑ/ϖO��_�K%�a����Sʛ=��N���[&���^B����e�}� �DKh�2ۣ`����Ց"\C�&�#��-��8��=u:��[��e$>�ׯf�>��@IG�B1u��s��m�u)�4�a�8�m�S����m���}��>ʤL�o*��r��^����!�y�� `���u��.���{�n�Q�ߴ�\�0���.
,A�F��W�d�C�N�=o��㊖xJ�����I͟���'{(��m�U,|�}P�q��6�r5�Z,�$�B}'"go�(��e�$�3�,�K��W��Z�#4����y�� ������vfP s�x=���VxhQ!��%Ֆg���}D��3���"�k:A��F4��OЪ䭍Y�p�H�V��݊լW�h�]����]���]�����3��'P� ��xbqto�֯g�{�9nU�sr^\,����©U>+3������}Ǭs���J
mҶ�IZ�qE���rx�<�(��!��Nn-�$��.�1�m�N��6�N�j9��j�-����s��%y��Ap}If'�m\��V�*+|2>mY:��~@Bw�R%d'���?q]l�q�2�����ZU�W��0싫�pC��`�L,��\���dA�Gm�m�����k^��w��<�0�r*���%��=�p�9ΞO�Ý��k3�C�,�Q��r��|��B��3��s���w
��@/ͥ���Ei�h;#��"v�����ܑj��(���_��utV�7T7Dk�M�N�B�F$��r&�W=%��-��q����!��I�) �c��FQe�9�ט��kf�����+����3J���]�a*+��^T�x!_ѼT�Iʀ��s���/9@�xɌ0��b���nd�\u��30�D\�⥡``=`����o(_y��C��vB�
^��H����}L&�R�7����X���쵓�9*謿R4�F��|~����2����e��ܑB��`'0
����CN9N-�p�o��%/�C�"�N�P�P�s�o�3�a�|��<��;��$�8��MKHG�ƶ%͠�ox?�!d\N�ؿ�T�(ou`|o���7��xv_���N�[�NSM
<�(���<C_��rIUs�J�G��d&�Dt�Ƌ	������bї'fkߜ��:>�;∤�����L�V�f5\P�!?F��w��,���ȼ���Y�o�7��<de�S>�'�q�e�&�J��#�?،�L���+ڌ'�헥+<�g���\� y;��ǎ��5��fmx\GU��v?��Wے�DM���7��ˈ�y��8�cY;���3���;�����8�<�3*5MgX'�N O�Z���Ǐ���W4��i\8�57��8�v�9����@��i�x���tOa�a���_�l�?`�"���W9}K�=6�BD>�J�1Xr�AzK'V����fӠB�Z4���C�˭m| �_��/�Yf�,�2\g��-ԉ���/���if���6W3wq	f��>��	�f�>�-9S��]b������Y
wÐ��7����j�������P7X��p�����eml��������~4~�8���7¾i+7��Nn�:c�j��4M�o�h�q�^:��'w��(��qH�Pݐ�(o[C5�8DSp
ɤ� ��X�ܚa�%VT��j]F�o&�?X�q����]6K��x�l\��;��A��D��� 0���J�Vm0��|���� -�/3 n��|���a�Ji%��4p�p�ܓ�「Xשb���<V�P]���in�����ǅ�`�Zˊ���\�<)K�;v�� .X�9��t��f�3[%��{�.����$��6������U�Wp��8>[���E&�I��*�\S�r��5��W��ب��x?���Q�3Q[�>�.�)��Fh��Yyw��!L�!U+_�$��%-?�<���̭�Lţ�Ubz:�j��o>�����6+��5k襧�0�WreH��M���C����A���MN}���Ȓ���e2���Q?��LJf�v	��?p��P
����S�>H����aULQ,}5K�a&th/����3S|IE�c� ���o ��G��Řz��`z��v��w��P�ū�����f< ���A��I�D��C���W��iD�� �w/B+��j�Y)	_hpI?�vgf�����~�B�+����W�)'F�u
Z�{�GV\�w
l���%������#mI߿6#��!q�BN������F������^H���n��Y�9����.֦��,�s\ <�H�T{����:�w��(��c���kId�!�i��s�\��	Z�o5�p��<�����T��B��T���#$��AO�H�y����2	aԵ̫��}��=*���a�
W�j���㕏l{eW3���
8t��S����f�%�a��$G!��eW!%�#�JO�����.��-�����$��̖�=Q;|�]h�9��΂>�K�Z��$�3SP��ϘkƜ��Q�I�~e@�ZRg)�PR\�d���_�:�-�zR��\�cs��z چ�@�z�ۉlg����FA���gޤ�����cO9CDp�A���Y���O�����*WL��u���85F��ʆ���Y�y�$a ��mn�EZ&4����L��J�F2�3i.�s��'�� F���f��Y���6���MCCq߀��-�C׵e���|V���%���$�8�"H�~�Z��` �{eҝf}�hN>���Hk��L*(A�m�	�������@h��C\~c�
���vJ�:���hҝF	��>,C�`����!%�p�����6�ؒ��0�V��S�ƙ ;8Wk�v{qy��<�  �|�
�(�y��bꝯizg��Q��^<	yC�to}B���,�F=�1�Ae"�k���޲��&HX��rJb��AM%Gl�2h�����=�zY��	����F���+�\�?H^t�T�|W�eJ��RB�^O�Z�]i`5��kY~+��Yz�l���,\/�C�M=T����)�%8��O��(S��o2��W�!�-TT�Մk��A���A��4{4�'�3F�ㅅ�!�kZ�kPY�b��&��'�:�%m�+���wE������/��|�jwx4�������Ec<��J����� ��6z�����t���� u�@��T�R��hJ�O@H�=��
��p�	���v=��tń �&[0&`K*�L�HLW4.��S��?.��U��,��Wג$*�����t`O=���~uo"e�;8I���DG��,�����>�\^���/��,;������m�lQ�"i�+��1�Z̈mľ=��O,���T��(J�3ob���EL��HS�~f������;6������g���߬#��Ǖ��	��e$b�I�R����rGu{9��o����J3�̠w���/�1eCY^����?@W%	ӕT�tL������H҃���%Oa�{J"mn����䦸�������n��I��P�d�oX����3M@�%n�Lح4�E(����Ckϼq�'�9F���,�|�y�ؙ�m3�F?3}MsE���T�
TzE<�Q�?qP����ē���@0�L�B�t�{�$5��V��R�j�;4���a�8��@*�v�6��r�V�o0�ؒ�i�vT���^=K L!*��@��YR���Zb;���1OR�M[�qkG��ц�$�}�L��R@�S��ϴ����N(a���7y��,� \9+�Ӣ�� �]Gi
�Y��<.���5���nK�	��$�N�/�?i�ǀXp�e�r\7x.�(L��U�����f{ޚ��������Ҿ�[h�`.��#�.�v�
|S>C�sl�S �ȧ,xS��Q�h7L���B���U%���*�|��{L�gAv�^R�I:��B����GEݖo�� B����^1�Xpl�Aő��ئ�5�'�Z~ ��p추M�KM�@c���I��챎?���g�I�;oQ���<�f>��Ój6�Kp���\b�y$���)�� ;5�;0�9�)e�G�� �00|x}#ڜ�W��&�����s�:E�̯Z��ۇ��ݶYX<Ai�ӫpR( I_R�A����)r0�7O����ϥp����+D'��BQ�^a����2�Y���[�#�o�>;e���y �S����~�]�x��ɮ1G�C�k�[�Be%��0Xj����J�ss94H�瓖����WZ�5	��^����*Zc� q������ƽ�1��&m�Ph��9Q���*?p ����� U	`LS���s���Vj��~�'�=[]��,��_��vDcK�P�����5ҕ4�f0�_������yA�U��ٚm{tH h��%,EH��Hl��0	��?�Y�|r�aL��2�ciPp�..*��I�>ذ��ygq��.��p�|���OC�D��2jr�\z�T���.���e��y�Mȶr�~�0��w��o��/k�4�b���Lb}-$�#i����z
T�w��ޝX��?�F|�V��up1+���F+���>�ըs�<��0��i�.)���Wn�Cbe���ɚ�h�q�!+���^{,57���S���f� �����8��%��PS�?W9+��-D.�EzӮ��mӰ��OZ�ɽ����:E�>�=����zHd��W�}\�!Ok��P0j�mmƜ�:�2������(\���sb�"V���,1z����sM�-��@:>��� ÜD����S�n�2%J� ���|�i��6Z���_[$�|z⒦�-���q� ��s�d��<?m�m#~L&��Oͽ�?�1u�&$~�Z���"��8���L+�x�Ka��gd����&��8Y��
M�`��[0i<
��x����\�P#t.A|�N�4���y̅���W��Â`�>����1��/#�{�ٌ��08�[�l�Q!(3�?K�o	mY� U|ߥl�~ �;j��3�� Sx=k�ںd۳Yz�Y6�� �ϴ	eԣ��%�P�4���°�!�^i��w����^Z��i[���@�hHsې��*O=��#��ZYEHy�ZD�a7�_��K���&��"�6 (�ȡD��;��ؔ[����<�#������Xt�{$H���V	m3w�hʹ/��f ��~+�B7K^��0ц��M��� Ɣ	�4��2��Jo���2��Jd�x�����7w��נ^�`�;����	���w^�7���<���Wh���9j�k3���S&dġ�Gqw�'��=�F��b���zg����f���%�&���t`��C��E�$����Cx�����
�ݎ?aZ����;I���A���n��^Z���e�&��4��V��pZ�Xi6�Lĸid�,.P�<d��'@�wȜ��n�צԟ�����m�;��-9G�e�Ia~E ��t ���:?��Axǫή2t�=�Jt�*�����ߧ�G�7��r{���*���6�:!�jI��$��N���lN����-v�Ԥ���PY��7xv���<�	t
�(&�d���,k��z�U�gD��W�X�;:�@��Ā$�Z̽{������}!�T���k�d�H��*�i�yz{s,����_�]�������R2����M��z[90�w�� �֊Ú�lo0��������_F�)����֋��p�[)	��&sa�����
[�c����=GB��ֱ��:{�/��X��>�%���-�G-�v)~��~�1�]�]��y���c���#o��'���]��0��]0=&��z���7T\wG�#�?\��T4�4Ӳ��Ek�3������ ~��٧�f���qx���w����BC
�+���wm nUφ��$lL�b��ç ���>�c�2�l��퇂�������cfE�irh`z���&�u��]�-�� �@Y�~��p�US�&�ӑ�Cȁ$��^�]�d����_�Rå�*2*è\�8�u����m�D�?3���{�X�sU��Ve�n1������L��]��?�#��9Q�y�p6�r���Ϡ1�|T���ˉz��r�/㩸��\�d1%�L�ʩ��Z�Y�D���Uj{hj|h�\� �#Ȳ�!��Y�i�<U娰��.qņ��(L�2�z����b��0��T%��0#}ɪc�y���	��󉌗 J���|��õ��/�a'v����X;Z��Z�V�@/~��������Y���O�c6t�+":$&��H]�#]�˃4��%G�q����kj6>4s�L+bhO�oZ~H�b���l����/��B��O�׭�]���¥��Y��iCG���:����5]V
<�3ic��
���}s:{
v7f�D �\4�$#`�a֤�T
�ίs#�Z�L�s��*@�pT�R�b�ểV�#�Hk�K	��Ů��u�Y���o��s�Yi�]�i7��m�cͣ�Ҽ�VP,��t���/����*���A�b���~ĺ�����8Yu>�1!�F�w��k��L�ӦۧLZj�QHYB�v�rXóSs���:S�*0�	�Źf/C�����u �� V�7�q�ͩ��]5y�������؊��o�?�[�̷ĩ�@�;Ьs�H�,uh5Sf�,\�(F��ٖ��Z_[�῝�Is3�6�?��n��}������_����ɍ�y9la�S���"�q7�-�J��e�W�x��^L�gn��.���aryTĆ�^�M\��I�W�@�mA�M]ƗXpu�y�i��f�0�"�'��↡��NP�g��Ǎw�`�q�N5����wT)f`0�S��6�m+�za�]!�3�(�!+�S.����`#:����[��0�C}@�QDy��S����J'�����ۄ�JG��,�<��z�rh_�%�p�/�)���:`]v�@�
�dh��nG�����/T��F��ː�?E���7"����Cb%s�d�$k�`�u�� ��[1_g�S_��#�bk��G̭R�&FM��P���n�Xh�!��瑍q��/qXd���H�˸�7���"+�9Q1K&��h���B?�L�K���-(�k�F2�=k��:0BZ�/�b��]Է. @R'�-c��u ��&��@�G)�י�.�|Ui�NSX`��q�!�����[U��I�N �H�	�b$_��5�h'I�֬>�o�v�MH�TC�q>�H��:3ү�ދDI����}x���	�z��zԲ�L������ ��_U�VI[�k���"��a�B�Im�ޚ )9NlA
�����"h�����ئ�f����S���}v��_@���p�͕}��d��|�!���۪����q\Rsc`�K���3}�:�sS��lROIE�EBcv�����|E{Й����(NU
K��%Y���(��<y�B�5�a^�tV�B����tg<�:���� �gs'��t��DaY�����Tͪ٫�8Y��!��l��-Dt�O��>�3Թ�Y��÷/��L�섳��G�����4����"���H2wX�`Z������d�6���1�g��N;
@�7��?<�z��$�&� ���V�G|��4����A�,�3��_���~��2�t�]���T�Ӝ�K�����BK�S�����0Rpg ;u
Xl�d�u�!`�x�8d��A����C�p4��+��Uʃ^�6=�S�L��B0�y�8KZ4Ͻ�ݭ�L�k��89��5^���;�,h��ULU�٤x��/ݲ�y����ѪJ�\���!Gw��s�h���V�૳�ƈA�2���7��.D��˙©����0�	�k�n��-Jf�y���p�1l�٬�Y�$������ Ԇ�5,p���_U�C9+��G|,(>��fK��ǒ���HPK3~��W���I��O;�5�����V`��z�O"a�nj�4�������(�P�PS���8:ԢSFo������L\�9��j5s@WGf��5����Z�;k��"��k��`�p	ޚ?G lِ��C�L�ei������X%*]:%��k���1<߭��P��@ؐ ]s������J�P�gzZ�Jд6?|OW�Jx@��x��ȟX�{:$�V�aY�j�V��ݜ̝�Th�p��H�{����7l��>��8%$��1�"�����b_�qa':f�uu2e��%Uc��k������t�����+FzUb�N��f����+��e��r�=�E�PC���D�C�˾%��,��^F%�󹕪�Y�o�z	+ϚJ�<��Xo V�J����A{e4s9�?.�ͻ'4U]�L��S폨 RCiY���T�zt���TX�A��h�:��&!qϜ&f1�M���	��)����9L�R8&��ߟ��ɕ����e������Ǉ̫�R�2�t�|dMoư`�����4���󝴲�U����H��QfQ�{����p�|a�QfQ����X~nn*L���Ў�x���=������W���M;�B�0�:���l�éPCO2����n'��zq���X��D���q\T/]`KI��yhIO�9�њ��i�	�1�@���-��4�s���N�Yi������$���\��N�����$��c��d�����h
�5�Nʳ��1���&�[>�Dl���؂.��%q�e��?3N@�TDiq͚H�'^�y��-�v����h�#N�
�|F{��!�����_��S/�j�'T�?�y��<����0�8���]��'a�ܢ6�=���\��+��{��0�M�]o��v��('�V��4.B��P���u!�x]�޸˖jkD�H
;-��?aqG��Ň���!V7�u����V�B�l�ؐ�p����cʁ�k��L�#	�'Y������V�0%���?�F�H�e��/���T(��<4���%�=���Ƒc��r���]����'�&��+s���h�#��Gr9��9q�}��'�����g��Fە��Xc\�r�$��~ 6u��޶�K��2dt�l��su��Z�d��I7l!π&�0��72�c��Eq�i����@�"���{��5�(�P�;�S��c���rӘ��$�R5�^�&L���)!�c��׊I�������dz�|�D^]��\���쎗xh��S�V�PQv���yӨ�9��#�!�%�u��$�X~�XN��d^�0	R6�몘c�[Mq�"YIc���@���kuw�����B�+�^��8��u��I��i��G�p�a�eӊ�X\D�wKw%,��w$ymv�m']��Qy��gU�\�m�ړ@���cS�KcX����ʱك
*0mk8���#��I���(wB�̢���	]�!���"T��::��?wrF�)���lP�$u�MeDl]b�l�� ǚa\�������iE���-��iH��9Ai�����\ϗ��L�`�	���|/�ڬ���S���ePӎ�B!��f5���h�ʟ��U�^��R�����P���je�]8 <������O��t�*�Iv���M��C&�Xe?ANO�t���"�v!x]d�}ӳ���?��\�Pȯ$����O���'X��"4���g�v-�����/X�u4�r������VAW\Ķ�Q��Rn^��*~?�����5i�XX�L*��ܘ�{~t�����ʴ9G�.2B}��;��I�"?��,����3p5j�jZ�Z?!���)|ǇxMb㳃��[��F8C��+AQb_���s	���j�����H��b��,�V�ڐA.�)� �:�J�u���wJ��)��n����x��dd�(:�R�ڰ��Հ�ܖ�-�ɥ��Р�0��h6�w(X�<���,i�A�9� �/��9��ؓ$�9�m���
��S�,�v+,��Ë~�pkF���~|�{�����JxJ픯�;�'Y�ۨ��⭼���JY�E=X.�$|x>}�G$�Ϯ�x�)���9��
\�m���'9�Zp5���j���x�t���X   �q|{�H� ۸���E���g�    YZ