#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2759277282"
MD5="b62ac8add24fe4eb230e39ee4c08ca46"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20976"
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
	echo Date of packaging: Sun Feb 21 19:07:48 -03 2021
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
�7zXZ  �ִF !   �X���Q�] �}��1Dd]����P�t�D�� ���W��)i���e�ոi��dȼ/gu.=s,�����3���J0w(�ݔ����]ωc��ƍ�Ēy6�H�"�'k^!�SI��
�M�$�.Kn6p!��@�T�`�M�ؖ�����$Q�7/�7r4���l;�*Dlv��@.�Ѵ I�L�]�
_f�6tJ��g�=��^�c��ߎ&�y�KJ�l8�#�~��]W�:��i�/ҹ�����ICd4��k��dUf�l��+�6]���C�y��M����|X�*�aS��3|��Q�\�u��A�0�ڊ�vmXNO��_h�Ġ��b��]Fa����/jP4� l3�Z�?�3�)P�pyP�H;�Ry~_��ؗ,}VkK�F� �Ǭ�SE�lm�Q!��6a3�};+��_D�G~��;��PDt�y�f'gc0��E�a�)<��M�Jd�1ԣM�P�3��	~���(ϒ�y�G�4�ݦj�t��k�����|9!��{<�.Lm?�#��-��䁭�k!r�%�Y��h��|H��e�(��°b�O}����A?���+���~�g�F'��`\d��� ��^��r�w�[�|���i��`�\zg[�q!��FT+ t��U{��P��]����8k1�D�D%-v�Q��~�$:")�� <�s�J�\�wFV?�(�D�nߝ8~�y��|��C��A���6χ+W�d�؇+�����u�֊��]�*.�'�������?,��$
��c�ƽ�(�$u~4ߏ��|>�S'$� 5�B}�s�4�[T!NH5-�]�f[Đc��M�č�Fȳ��W�U"�Kx��4�n�*��P`ԇ�э����+j��R<���m��,��!Sa��EV��K���}H@��*�ކ���n�ѯ��]��m��f���zO1&�<^���/A @:Ϯ	��θ ����>QG0)���n��7��K
�b�������)��e~y
z�$�;�Q�"��(4z��7�pv�	��͌L�z�q��Z��-`�4�]��Z�E:��􉜐E�@�	�`�~��7�qD3��w{�UH�o���*� K\��Wi��������M�}�Э��s"��F l�'	��3����94�")�睽X|������{�J���(�n.��,mF��^/; S�J�-5�s.k��A��Yǉ$l���(����v$�ݏ�+�
��P��di+��p��_��]o���!�[������2M.�:��f�����'�/E�d8�%�Ƅ;ʛ묗�-#JL�.M��4^��k"�\�^/� �H��K�"V;�'�/�)�7�(�1�Q�"�C��LL�]�מ�$bu��W�C8:pLpU��=�����}��{s�S;�+{0�T���@Y�{�Le�֪��X���R��=��J�X1&xa��6_o��0��ďx;���`||�.g4���
���I)���&���B�ƣ�`���c]%�P���3��t0�5��a��9��0����,ڊ� !��ơ�T���l����Eu�k��yjv��z�u(�3*��ӷ�t��S�����N�R�|����}�<U�j�,���ڼ�;S��\�cG[�+%͞�b���U#6�ah�9q	���K�zR����jL�	��8��Ӌ�q$�+�":�؅Fx�>�� 	��`���_')���6o��aE��j�\19a�	���_�Ԍ���h���V�P��A�c>Z>�@�O{x�If��� �1�a�,�r�)������G�k6~���6���H�[�Ȓ�Z�vc�;o��D��o=<@�g��x^��UN�y��;�)&���Xi�Fe5�>~%�
Qy��y��S@�"|	/>��4��<tl��Z=�9���V|�X����J�0��CI�\�ȥ�9��_$`�~�!������4EQ�F�ҕ�S=܈(ǽŨ�L���ՃX��p�J��%���l��'m��^����X��ftRn�Ǟ��8�)I�W�<��y�y
]=u���Q��7��Ś�h�&�e"������̺�x%f��I��n^s�����,s�P�S>pJ"�fQf�u_nۿ`�{-d,�x�{������f�����E��y�8�<'Ǿ����v�±���R�?�Cs�U�w(ZC��
 ]��kui��G�D��G}F�Oq72�U6wk�3�惈X�� �2�sNp@���ÊiEĻZ�5a��&!��E�ٸ�!S�#�����
'D���xm�����*��P\��G#��& 	�@�C ��YQ
Y=G_�񚅩�s��-���Z8�{��=*����	�'Z�� 俠��u��-�$���0�IKT��f�m2o��W�VU�,jH�L�{5��k��MC��4���צd��SkL�-{I�oLO����OR�b����^N��P�#k���0�.eu��OV�mp{L�>�؄eY7����u�_��h�yz&���c����b��r�|Я���5>Z{Do�b�vOE�A�x��㐜ۗ��K�zD����U���#�-�������|0�����%!D�M���X�Z�LYWN1���
h"h��m{Y�ƕ
��l �+Ż�%��������|-��@�Z*u���<>����T�kw�^��="�Osyl�iY��wc�%�h����
~kz���7s(_1K����n����Z���+|"vi��u�W��&��<��[��=��P7�GS��J��fA�����$x�$�:�A��wG� l�����[u�Lh������1	�I�C���=��+CoJ� �!O.$��F����>��k��V��^���{\l��nZ�&SWt��+M8�Pټ�?L�^[ ԛ���M�r�f�K1r���s`r b�C,�rZW��ڱ@��d(G`³�/K�56ׯ��eۼ���7�f��Ƹ�����Ԍg�����k�oK����V��+�P�V�_Y��^�Z�#��p�M�K?��+b��w%u��\{����.��;*̩!p�*\n�	��a����� 3���>�"���^������(�;�nEITY/u�fe���\�K����9�~��ʂW�3k�}eel�I4�֦����\�o�Vy]~X�� �
�݊�'����`�*牭#�G��H)%�J`)+����+y.P����d�7��b�$`�1�a@��U�3U`
f��ۑSe"�݌����P;-��`}&�s��3��D;bh�i7?���� h3�Op�j�P����=jA�~��G�J�|�{�ԩ���XyM5�ݨՃ�.>�դ �����:��#�vUk�l�3��?%��q[�NF�Y۔��LE��������"b��f���ݸ����&�ħ��;gނl��F#�G���N��=+a2��1~*q��r�X?8b�,�����D=� Wy�]���P�X���Y>JI�RuʯS�A�~��Tx�5�@�Rg��o�$o�6��z��Z�+�š\�^������ݙ	.'Jۑ8�bZ��Y������A|�����RMlq����;�̟
����dJ��K������D6'���O�����d�7c����C����\�z�ߣd�[
(��������"ן&7E�+E��s󠸷f>�.�c�v���a��#�[]���?��Wj���Je�������'-���dwV�G�5��󑍃6�&!�͘wjh��c&�aha��=�����}��&K��# �6"p���Y��M�$�Ш��W��j�5x�~�`���G���UJ��O������Й.b�Γ��v���dtlrK�­@�'nɗ~��'f�&.׈�\������gn���ę�>�E�x�]۱��!��5zvZ�op"ip�>�6��Y�T�Uģ��G�iLc����h��]}.�x���4M�2)!m��9� $�b�A�=�t<�C)V�5�L�Z�*����|��ќ#-C�̢5c�+�Ֆ���חD毲��+��C�q���%��;]������n��,��PO�����"���#
Y���p��aX�!���bd�ʒb*�(�e��'>��-��9[܌t�����W��>�r�G@�I���l���O��)>bږ�7����Pj9©�l�,����D�ѯ�2%�_	�IG͊�@�A<�PQ��C�
�K�����{$d!W�-a��̙��E����]9CE��s���my�����QݎD����3��}�pY�|W�N�+NҎ��>hM��:����mI�9�x^��>�ی�v1kw�O���m���K�v`�뛭�u�o�x��{��b���K�`�w�G�R/����қZ���Dԓ�Z{��J���i?H��;�n닭FĠ�z��x�ڗ1��s2\����<4Ꚇ��e�z�Uh��x.�끋������R�:x��!��r�=i�1�(�>o^�aߑ���@a��l�87�����H�G��"�W�%Mސfij���.��3���l<nʵ@d?�`���h*�$	L���X��J�?j�}�Y�����^J�{H�=?)U 6����so�7�g�q�*�_%�//���6������ "R��8��G�	���3<"B3�����y����/h������ŏ�̀6���m�r�g:*c�	t�n̑� `0K%x����jW��U?�+�$��÷x[(,��id������d�)ڕ��z4O2��%Z�D#ڗw�uhU9S�w�F��\a��`�!��<�T�L���a9^+fEM|ԭg�����eS�����c��!^��l,)��^���f�>*��Ã���ɠhh����in���B���Սg��o�,�2�3��E����VR��N���a$<�UmN�>��7-��-:�98%6�Kc ����ĸM^;*o�eL���5q�E�'@�
$�Tem����$�8�α*���>�SؐDЩi����t.sge���J��$}O
<7ag�kU!��C������E�p6?B�D�ş���mt� T�T��m�Q�Ҕ_�nh8#9�!�`���]â��B�@�F�4�4�fQ�yd{�v\&�,��L�b~�G�FMy�����߾9|{j�5z�H�)\���<��(�E����p�A���"s�� �kzX�����,I����c�Y���B���w[7t<\2, u9&�XL���r{���}���*�.���~C��a0��,��:�ӚH�^����5%�+n&�8ن_\P��x��+�N�X	gw0��Hj��/����śn�/pu��@�oၹa�/?2��c�����������Pv�,JhB�	�H�}
H�>��*�	 +T�h`���Ej3�Q�MM���� 0S6��d4��� M-#�]��>�t���gy�A �hE}�D��q���N��Յ�^D7�����
,����C�'X]#1sʘ=�.Bd�RY\:�@��oN�c._Oۚ)OGs�uFU�sN� ˨:���6��nї3+�����ܑ�C�Z��Ʋزy�����`-���| �6��V�cڢ��GϢ�%�-q'�CodUA}�T_������R���� �nϋ�j.O�/T Ҥ��Mq��t�A{v�~��s��z�8=�Ġ5�Y�����9�Ij����$$[��A��ɤ.p{;3����3�s�z�Pō͛믄֭zN�h�r�)�2�6&
z�kb�#`.���M��R��4�G�oI�C�2(D��&+2D��]%o>���^E�'0������c:�k����?��/�#��>$����@������11hON�&j~;0`��8�|��C
鑵"����!`����@���A5��,Z	-��N�$���&i6 
Q��/���0_�MTJ�ѧ�M]أ��
�h��bQ�k(&��vP�ף�4T2w=�`ο'3W{��"�L�Kߞi|�����/�?�j�*) ndN�&Q��l�UL:�#��7�b�����[ڽ�ř�#T��R/�$� S�"�E���/��+u�=V�b�J��B�
,ߋ\��_�4��G���ʡ��x~���6vPF`y7\�d&A�R����wW�a.�w-'F{^��_]ՙt��(��sb?��ʾwn��%X�M���N�����{vz�����{?��<hۍ~[���LUg��hi�&~�t��J�͚~�Qw~�bЂ0��>�j�t�x��k�o&�QI�P:�$�Ř"w7g����oM�*�oS�aZ$!/��Q%���=�v�f����Uon��/CK
����+��K-�ˇt@gwJ�ǄCG�G�Aq7FB��%Of���k���0s��Nh��,@x�? �λd�3q�f�l�Ax4�@�䐅�eff>?��=�NB:o�h�����$�{ ��zdK�����5C�����I�{�T�coxֈH#�`)q3��zs��θ�����apj#��G{�`���KFQnq�":�R5M�Ϩ�}����_��?���
�W~X&���݀+%�v�,�25�k9�t#cPu�;�iZ�ėl�Z�OK)��3���Y�� �讇���-���l;�3�Kuԏ��u�β��a*���Tb�E0s&�(��W��OrȵۣPm\��uQ�i7��^��W܉��y5 z��җ@��V�\�_#ю��KJ9L�����6R8kc���(_/<��˶e~'t�cw�??J��������j��gJe*��S�ܷ�¹&�;�WM�?�{uT:����m�wȴ��i�OX�k�;	N����ҋ�Ǭ���O�*t������X�u������r\-�g��|9'nK���^�x���aێ
I	¹�a\|52aU����F�]��6_�R_~M6�
��O!NS��'���Fј�A�\c��4X�I �{��N��(�Y������b0l�99ǫ�6���/C�3O:ކ)��rK���0�G��C�a��)04����w����SHG'�M?h�U$50�7հ�1�KL����3�X�^|�9�\]�]X5촥�6gU��.��ؘ����#�J���&��?�j腡�����X]����)�2��So:�y2鞪�J�oJ	w�����u��]���E[ZF�u3f��˸����0�F��p5_j	C5
�$�eT5��4u4zj���{y5��s�h��t�ī���E
3�3i\H��aV�(�G}���.7ڛ�j�N��A_WD)������ � ���q���ÀC��cn��`׵.u�;������GT� ��L�WӂZ�һ�r%��Ռ���l����_��[���.�9�}���U)}�ئ��XZr�Kbbk�K�B
���Ր	,"��&�x����f�Hs��/�ZM�<6�?0��R�vKc�>�י��Q������h�u����{Ĉ�FV|9�yo͍t3S*6�^~��k�7�ƒm��P�ڀ�U��#c��QD���I�<�&�Ϟ�C���IL�`K�q�Bw����K���9�׭8!�i�3g��a��^>P�\�聛8�i��%A���Y1���t:�����g;Gn�H3�����8��7&�Y��P�UCи���DI�b�Ua�J�b*N ��Hw�;�Ď�����Yy銟3��?�����FK�n�.pc�����E7
��d �2�Z"V"��{�N~��4d9�oK����~�����c��C�v��m��'���/z3��G�ǂ�\5w����<��,0�f�/rK�E�X�������L��M��9��)3�U���9�+d���]�i�&��a��%E��I#LYV|"��\+}�{P���5s�;���h�/��<O����H��Y�rԽ|w�lT)N�V��֕�?5�B�;I#n�E�H��V	"�Ex�,W!V��Vh�w�s x1�[1� ���(����pr�����Z�y�
�p�$3�m8pC��6�_v6���:�ǽ�:��eOi�jZ���1�� 8vk�A��1��e��e�+ s*��f�eBy��88^&�)6:D�4V_ŷ�AF��/V�V��tF�JHf3��©ZPvd�ޮ��~�sjM�fk�F~N�'����n�~#��E�dT�G���cd������b�F�u�����b:�	�VX`W�O�Ɖ�����+�
 �<:��J���k�	���!C�8N�w���,���~Y��x��バ��nd|v��#j��X`�v&��I�u\2�iΪ��`�L�}��P�N���0t���IGGf<`h	yF���8<;��f�܅�;en4]�N�Q�P�|���?&N��W!�e4��p��!c8��^!��6�[,��$fr9��b��YΘ�sC��W22��Ђ����l��Jk��q�`�iR����8�J�@P��|�$w���-�_g;AD���,�TiZ'�I�^��µ)`^��������9�I ����"w�'~@�s+�T�R�V�/)�ٵ`n@�dد���H�H��c�תŤmQs ]ۅ����Cf��^(}�`�Q Ќf�@F�� �C���6$l�m+����%�Uw��qȭ>�h��Oq)��V�K�e�o��G_ga�0�����xʱ�L_-:YkxR�@�nҥ�s�Q�]E�:��RI:Q5p��\�}��#"�81<m�C7�8��`ڟ�	�q.��W5L��xKb�L#�Q�i����I&���`�M���� ��k0R����Zev���p�a?�h\-imш{����D7,����r�{U���u�������uI���Q�$B��@Ŋ�f	d3�^���oiFhF23���#�d4g��~y�6��� ���A��8���c��fw��ӎ�J�uY�[��)|^�� ����� mzɮ�;�2���ɏ�M���gn��5TR�Tdi?�.�ӑ����B�*��	K��X��
E\jD���t���K�7
ZπV�ON*����(�"��u��|�Z14��巯�J��⫇�]\�\)��ϋ�A��OsAޯ�r[��¤|6��o�\b��h�n�.��Y��FWZ�9B��,�+��S&8s�["qR���B2>��q,dP|��#��[�2����h.\��[�-)IWq�p���oM�I*����n�&�S{�:��#���1�鹴C/�FM?����'=�]�}�^��\���o�a�3R� ����|Y�76Z�aF`B�_�O���BȆ�+|�
��5 �G5��Ǳ�!���:����a�͓"�r͢@{i����d�:#�|�ޅ������~ ��k��/=G-JR�~�ެ������� �����o|q4U�o�^X���Rna�{QK"��|�4ܡ��\��;�6+��e�����t~u3��y��Q.Pd-e;��s�m&I�vc�WؗJ��V&)/d��V"�Zۜ>���bzq �)�O�oO�}��n���Q��9|;�.��m�����|,h�%lB�ؐ6���tct
@������ʾ����IzQI8���8���m�@̐P.,���0ڡ&�}��wR\nW2��	�B8kb�l-���+�u��}|ע�EK�0Y������&J-���{�0�9唕�Q,T��B��?%eE������p1e�� ��w�������d����7��'�;��7�3ިoR|�y�O/���j+����eH�$Vn 0�F��X���`8P2)�?@7��:��¼ʑWݚ ���V��􉙩��U0^�4gy�L���tQ,��3��~��5Hݡ��TܱEI�ul����^��o;?A��tu���59���x�>HB�	;a���K���|,&_��А'�թC�+��*&����{A>�d�E��䯅��^�����B�?V�hk�7��Cj_r�J</� _z��t| �I�K!�q�������XF)^ꌖR1N���+�[���
�</j��"aw��?"Nf���];�A$o����9��E�x���jDz/�li���,[��O�.>�3�D�ټ"z�ۋS��b�JL����W�D���4V��ihKI��P��L$vqN�QƵa�!���ė�`���Мq��iZ�	sA�1�綼ynx�E窥��E�y麫\�K��y�T������]��M�y�Ɣ���d�Y��qΟB��:������x-�K����ѳ5u{'��9$,��ia����Q��i[鄲�H����롤�)�����NmJ�����c����>����Y�Ga�{��\&׉@��ɚ�)o��ۗ���7���UƬ�� �bQ:G1�c���#���X0z��!��,�Ey�d@%�{�t1�B�x��r��bu��9u���+?o<�w��^y�:�&�	�d���#�|���$�ǻx��s���m���Bj ��0h�9�*E�.�(Lņ��/œ�~�U�8e�x�*Ӓ�4н�S}��HB��z�M3)Up�ޯ<!�|Ӡ�2�Y��j�hm��,�@г3X�R|F.���`@��#���g�ef�>����=�Xq��L�)� e�n>X�
��;�B�An.��H��3��|�|���>Y����A!R�����D>��I��9�%Wx:#lǄ���ڽ��7nż5Jw�jx/�R ��6�+zFp���	�<�u��l����CU<�ѲP�vJ<��EFTe/�z/�w�u�͋�-U�M��\�x���i�̋�s�I�8���(<�ǃb��n|�$��]E�R�a���6��R&��[�h�x�H|R�;��]@�֘��06��h�>#X6"��C����R$��5�s��*�t��`����_1[�����qB'���a���B�{��g�f|)�V�nJ�^��ى�O��L�u�k^��W�+�����ҩ۫��������Ap�1�: ��Y�H����1��5f�������Ț�g���K��� 
xR�4���͊l!���9�O'�Z~L4�.���^�F��!�]ʟ�n��E�iԺà�ƭ��->��;I]�z^iu�Y�&a��p��"�`�t���OѲ2��+����wW|�ej�{.��c�@����$�>�������kn<g.�wh�E�E�iqR���Nmͺ�0��q쒞"�p���{��Aҩ�w�6�����!Y�y���΀���V������P&`��nGg;�����i�|�P�����#
��UF�:p�V��z��c���\n9�vz|�g������	��f�u-5Xpo�.$�|N~����Ků�6Ñ��9�r��� ��櫭A��������<Ɯ��z�J1O���؉�lhA-K��\(������'G7��ƴ�<��[gcؗn�f��$rW���+A-3�|J[�7��'�u�k�3�<φ�~�����R�_�ė�*���CRI8�~�+�)�P�>�ap>W�e��c�� '��~��i���M/�4*�����;S�
m�ʕ�q�U��h�'�W�<s|Իm洄ԚE�}Jh�� ?�M?���O ,s0"�F{<��p�G����:Ј�"̃�
@`v=����t��e�ꆫ�W�Acޗ��z�T�v�G(�j�3C�uP��PN@+���MeSm�g�M2cg#�4A�e��������`�4�UP��\<�I�eV���=`����B���W}�`Щ�'��$�<��# J%� �f���Zd �,�ŀ�/CP�POϔ��8}�!�k��h���c���ߎƪ���"�a	�y�1�`{��>L9D?v�
ߖۃy4w�­B�-�I���!B�*3�F~J��8�^���vC�t�a�(�f��������yU�pa>�	%���
�LnPX�$�Y��K�,��N���!�e�Kt�凼�W&�KR��=��2��A��^'٧��Vn~S?�k�� ��� 
��-��ŭ��_��?�X�dM��M�t�r
��968,����(�Yqʡ&ln�FB,�E�V߹��|�G��%PY�����Y����2y��"2�U<��D���K��9�g��k�'>���HkpA�.\PA�vC#�x�i��*|ӌ��U.X�jItw	�̇��������e8����5��OCT�zb8$���0H�jN����p}<�
���d��ᘾ@��� B��k����;��y�I�.��@���ϩ�ע��^�\�H$@�~CT�0/�[s����%���B��_}#;�6��bh��d�vQt���j\�0�!R8wi�o3����> }ޒ�DN����W�[�7d �ԓB�!�����n#�5r�sc��X	����E�g���~9e�Bٜ�Oɸ�-�T��=��d{=��ޠXw��Όu)�8��gǍ�����[���K���\O��\�Z�c�%p\���t���+���J%c����0⧱��g�5d��ذ��r����OV�3��	hg��,+��ך!�֌}�p�|�0Q�Of<f�*�b(�2'	��>�NJ1�i;�Ĺ[ ��N�G�o�TT=���HPLp�Z���||�@��2ºgą.��(wLBTm���1<a�nMLrޣ���`@�8OI�*a������T�t�Zf��A���ܞ|>!T��B�shչ^������wz�g���:��!�`NWG�i�L�U���Z��Q���K$�����Y���m�
H>�Ղ��el_�ks�H�Z<���4�ק\n��5�C;F�G\R刨7 -!B���8�7��_p�����A H�1���ı�XY��{<��� ��ф�H�7l;�c�kPz٢��㟷��eU����IY��al5�{�	%�uI���-����<X���v&g&T�?�h��9@ǰ��,���� c����jfx�PBuK�a���!-�~�������z)㇨ҹ,j���I&:7m�~�()L��'5�ߏ��+Θ�#6��%�.@����j�s��{oYD����+�~�
_�8�]K�m�9�Y���n΋H���θM�C���O~dMȠ�z�O�:2� �_%�V]G����*��"�B�����ݛ���vX;�l�/pj]��M��C�q�Ch&	u��)I�`����>
��U�i���6l�2k2�؂�7�Z@`��ہ�8��k���R��>%�JJ��p���u�R!m������2,��<���g����z�K��K�V�m���W:��"�PZ�v0h�à5c`X�[$O�V��߼�l�^��7��vYxf�A��j��h0�ۘ!�v<2Dk��Z+"�������<�_�����D������(D�cl�G���u�}������x�5Wh��Ǳ��X�aWY�Yȿ�.��O�S�v���D�� ~U��#��^��i�#��)���W0���[��d\l�3H��	łs�M��򛖫v��R,�U���jn5�,��3�ń���@��J�z�*��l�h�am�d�V�H!�d�-�P%��]�k�-�����H�ZtW�+�\nOwP�,z�p�D��z�悤��'k�����	SQ���[5`,t��rS�`w�`�j�����0�AZ�]�]����ya�U=�PR�Д��hT�p���-K��?P#�_	P?�S��(���RQá�n�?�����<�`�m6���(¿T�Z)���ľAU%4M2
 儚T�Ձ�ꍔ��4���Io��ޖ	o� �AyJ����ZL'��
�o�b(���9_cvQK�����L'��#�F��(�nT�Nω���U������9�~���E3�~\�K�4S�C�k�Ϥ�%�߶Q|7v4%EW���O��i��(rq~sƓ�g�z}z-��5�M;�	�Mט��}N��� ��o����S��/�.�G1���X���qz�p-�?���O>$OFn��dQ&�]>��/�w�H6@�����K
m4%>�F�Xؓ4�3�T;i*�n�Mт 3���$E�@Q�j�k�u�U��ڇ�Oԣ�����MA��HP�	$���:����Dj�A]�:����r��1�$!_Q,VmR{v���p��4��M,<Κ�C�@5�����#(�[�YA����ڴ���mQ�εM�+Ց%2T	G]|癮�ɮ7�_OJs �*p�O�Z$�sR�����n�+\jf�H��&�4.�z@1k5h~��ET�"�j�F�� �hIS��x��2�Mj��\�0� Ӈ����g��^w�P���ؙ�Nܙ:-��yǍ�4m�O�Un@��SX%�pc��lt>��NwU�P%G�f?���9?�aº�����l�6���O����\(��e~Ʋ����jvtlO�iTa$�pȪ��g00P�{_�Uʳt��s�/��z�8��NZκR�_��m�8�zdh�nM4{3��)F��pq� ���$M���t/ݳ���&G|�݈a�$�)W��b�8��g�x�I�N����ʐ�ķ�<,t;��`���k�/-��e���0��>��������+���X�?�YvH�wx?�� [V���?��|U��V�/O�r�m�����?(>[,ik;���%%A�g��	ks)f&���z�$q}d����5s[)�c�n�'�ɜ|ԣ�h�D���a��i�?�\H���r��~��Kۦ�:��-s������8�8��Mr���v���/9�K�����	@�6#��l�s�+4˪) 2��� Au�G`�`e���9�B&Pjp�����`�ٹ�bB�o����5K�T������8�_�{$G��,U�e�_l�a>�V�����W+�
���04�z7�Oq7NF�9����zUH�˘O��|:�)�Ӛ�T�e5mo=b��x�q���غ=��S��T���TB�07��9H�*������~����9С��[ʘ3N_�O��bQR4����rkf���;���++��.�@RT��~꛸���Y�i+�rH=c�4$��_fC_C[(H�ቾ�t�
�1���eiV4�Q�o0�6�~X]�%.��m�`5hù�������G�����đ�%~�wx&���P{՟ӌ���G��
��<&�����R���Ĵ)��+�t�~4\��|��j�y��?te������f��
���F&�M�	l?K�@l����.�*�:�b�Pזd���t:#�K# ?��n�<�9�.�,�ފ��ޙ�_�
��V���`���gy-��Ҩ�9�jؤ�H����D�w#�UOVaB�C=�U��i��h�i���J<J���泅qf�"��̯R�"��3����|b�a��QG@1��Uy����+��X+{�:V�ѴN�T�=����q����0�zM��])=�z�FY�#K�s)#��Z��TӚ	Ŵ��tm©�� �P��P/n��X�;:Q!�()�s�GR��mR��G��z�	�<Wu|CV�[�"�nl�NG��=(��φ���J�r��XX�0I�^�Z���N�#b��k�Hn�����[�Z�sj����Azo��l	k!���;��5aL�ȃ �ҙ������!�Aܰ�����s~�'%�N��M�� rؼ��!2��7"���Fn�5Z&J���O��t�E����(�(����&���R
�տ�� ������ {�L�u��ǗT��܂�������^��:�:ʜNd���&�M��(Kt�s�y��4Ӏ�������K�O�/�@òI�=�hC�3�q�H���CC?��E��Q���S��xRm��w��IB�?WR�!q���Y��cԯ��OA�qc�,��!�j; _��dd�Z�j�x��-�n{l��1-gN��S�s��������+��2�9�'ҍ;��T����5Wg�/�f��M�ߦ�M6��O#��ѱ�#=��X�8��_@X�m�����+� 1R���?p�.�[�Pb��^��	��>ܝ|~����SV��C����l����Vm�$��Վ��eay��E�,�Xs�	�-I��V��V��]��,*��tk)��?  �.x��4��\�<.҉~��R>#��n:���Qw���k* ��f��3%C���R�Rw~�6jE��}����-��l\d���Z?��f����pH`�3��\E�V��'Fo9ͮzv��N�n}�ÏFi3����k��b�.�����.W�_�n	p"T�h�s;^�rm�|����s:T����#�?{K=�3
T��+�i�?%;M�ے����������J���ۮ��p{��h P����$^��[��I���-tDh�m�i�w���F��W�ݡjN��2�)QL��d�$�myr1�_F��(�,D��~��xC�� 1�z6����$|�1?vKo��� 8��+.�xJ5y>*��0 :�uS���'1���`�G��ۣ!R��h8OU�����V}�}O��g�0��Wb���o(�̦a�(�֎�v"lEWĭ� L����	f��E�$���ϸ��i��,�m�)r�1j���WI0����`Mi��/��z��h-,�����:J�9�w����ʈ����]�?�J�O}s�"�:#�4������o��
��̅�8����H͕����~���fs���eN��wzq��xo֥2� W�ȹ���{bװ��E�,2$Y5��8�-=��f�ֿ��`"$�Y
_�U>�V�lޏ��V��j*7��G���U ����~J[O2p�TG\k8	�8"���K�Z�O��j���o��!��ͅ���m1�Bo�o�^E��͹�<N6Yq>4�2A��v������)�'�6�1�(������+�#7�>��d8/&�*U��@+�K�V�&߾�Ӽ��Q��H��~�j����V�p8�WWY���c�Ͳ.��$*�h�s<}L=���]�ά�������nnL.�����/�[��)qjIǑV���\6C���6���8�]X����P�D�^��6Q��2&#�^���UX��9��VF!iMfFo���৘M�)��?�Ѽ��9����5�:�MV�ns��;N]2ѣ���$�^M���Y��[�,˅��] �K�0��V�%VY!� !
��6�C��Rs�D�rI1C��hI՝U�R���2�;��~��#vX�j�F�o��^2!���cҲ,�ݙ�TQ���ݫ,�ck���	j#˚,Kk�ƽM����(��Ӛ����{YU��F��A iAX@�bS˧h~���@H�<wԱ|=�n:��4��nw<�8=�۔���+�ϩ� C�5]ipg�w�?�%���kW�y�7[o~Bㄒ�-��a��F�T�,ee���(�~��Wk>M�cJ��"e^/���}z~�_����I�U��������*|WV�f���Ȑ[���'�8ɕ62�W�B�F����Ze%�Vʼ�	�!^�n�*�w!Df�\A;�CU!yT��h���%�A�VGԲs��,�Q� 𢰳��<��a�϶=���f�t�o.�̟��La��¯���,͋}��k"~=7B�g�NW��ruU+	�*_I< �W���@s��Co�n`��?٩��z�94����E�ᘢ�Nt��¨�v�d�G�\�����(K'��5U��4����_�8��W�hp<��[|:!ou8�u�̼e�V�	�Gm�~iA�2��-����?�H��_���~1w�衩&D&1c<�^%��������&��u(
��}�R��şk�R4[B��:E�}�9Y�[����{!��+�T6DX8Pz���\�2M0Vo�kA�Ӎ���<��$'8c��Mj{dh�C�,W��JLx?��{ȄJ�ŗ9�"�V�� O�e"�`���fE�f�#�	%u�]U4� ����Hʣm!@G�)Z�!���� �9��f��=tE3�u�7�܂=ϓ� ��1��4���>����&EqO�X��I�jĭ	v��O�!}��]s���cD���˛�pA�9$@����q�R}�5���*|��j��x|�WJ����2�d���\��۱���3dC�����`Uчthܾ�������ea���4�^"C�F9�l�q��h�����z4����Q :��)k��O1�9Q8Z#^���ⵇ] �q6@�ٛr����yօ����{��$���c |��zωZ<���7���~�Q�pv_�Z���X���C.�}�ٔy��6��C��2{`�4N�"�ʊZַ,��:j��{��I'���Bj��_D��r�4�\u	D�c�b�_����{���=�[���v��y�`�>�c>�%ԭ
�n������Ŧ"��$�KLK��ea�(�BAY�5�B��6�>�~�E�yS�ea�S?�d&�4P����Ϥ�M�(����Gy�Ä��=}��/�i*"�9A:,l�>:Px�p�G��(���*+KH �Z��1c�Z�s�nr��0=��2᡽&��
�@���f�;�9
.�>���ۂq�u!��O'yQ�e�4b"�!��r�c��|���#A sɪW]�����@���FR�-%-���"#� �B_
����{� E<t����g3.q44�O̠Ջ���c� ��m�Y��\g��3��S��!���TC��ͨ�KZ[�ڽi�"�<-��:�Mj��~>�8LC$��!W�b�v�@�� �����*��o�m��WWD#�)�A%`0�� �G��b�{N�;iq6�v!��s�@�
ׇ!��5w��������<x}m��M?��2��g�����S��,�OJ8踪�Xf�b|�u����H(��0̗|}�9Q%0���h�\bi�H4�����9a������'㿴�A7�p($�aP`A��6��֥NB�Ր'`��h1�&����r]"�	�������j�������v�����RJo��v�.��N �ɩ{����5�@�3w�΂��|����S>�h�YA=<�$�]�0�[>���z��Y:��qj�cռ�Tl�>���M]�B7�0�!�� ���\�-��3��5�L�N�Pb,Y�^-����M� ?�_6>Ȓ�����]܏���'1G��>ilJL���A��i�#��8eT���h�iTQ���s �eAxH������uYN=cFKQH�h�<�s�:1�-�K��h6�L�>�'�t��B�zwH��ԑ��}v�&y���Llz�VV�CQ�p����u����h���o�z)�!$�����?[��W���@���G	VꚚ2��X��ȼ�u[N1��F�NA��.�M�p��C�;!)�E�m �'Ӏ͜[ڃ?���Z2-�.�RwK�=�Vg�@����D��saoP��-mޗ��͋�cX���-O�jE�3�E��1��W��/_�N({Jo&X:hb�����S�cG5�0A�5'��)ﬗ�����oP�Q8T!�$:b��9h����iX�=I]���>��'(�M�0`#�01\|>e
��f��0����Mn��S�p��sOΔ4���S��[�qy�x�������ul�9rS�S#�_5a�n+�'+#x��o����Ӷ�l#��=LU�i:�
����}R��*��=y�pkGػ�'�����	Q�3gl���H6��R>.�/�ӕ�ב�o�EȊ[��t�+��ꑛ:F�N�&�������d�?%���V(O�^�2�%��,HK%��N"\��R��[4Y�h�l��q��`�{�%ݚ�5o��^��!���Ca�����f�~���$:���nG�}��n�V��}b����y��q$ݚ�p�<�Xa�aɤ��yǬ�20S���}���Ft��9�W���1D���g�˧������1TsK��2��$V��|�X�^A7YƸ�e��!���D��@c۳!#��N�z�G^�`M]n��6-<�e��B��l9Q	�4���0�f�ރ��I�q瑉�C�`?ïN��ăx3�Rzxb�
��X-�*/��.E�g�������LhJ�&ښ��A(�-�,a���g����)fF��^4����t�'���ŖKp_�,������ƀ�OK�
t+�aE��)~��Ќx
C��	��֨�M?hn�����
��ƑR|�lK$D�9��z|���!f<9 ;��|��Ky|?~�n����[	���D@ϻ�c"�����1��d�>�m�����*�#��u�\��T��_��i�X�G0Pn?;j���>ݸ#�#�\G m�3�)(�}"AS	���K&���Y�.�Z�2s��O�%�U:ĹosX����3H����U#J��t��U�I�Mpet�z���s�v�E��ap����[�u2CH��0/֍���ܶ��\@S���є���p���C�\�{m���?�j	.��d���7
�t�R�o¯%F'"bY�]�v�ǅ��^*7e&3��ٹ��贐�ƀi��
�Ř�`�bPᾪ�N�uU��}A���-ѕV��^6 �ͳ��~<��G*�@?i+Ko���fў�b���"DO�Lj=�+���>��9yѓv�D��̸*j����yF�M=�<����.�Ԝ��H��F&��wb���O�6���h�J�١+�a�	��4�N~'��y5�L�48;�N��͡ �����P])� ���S1��G�8,�2N��ע��8+��jK�P�|E�����P쐘�z�*�a0����3��'gD�y�Y     U��k��� ɣ���Fcf��g�    YZ