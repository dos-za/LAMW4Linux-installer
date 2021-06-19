#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2762384278"
MD5="82587a958d42e41556c258f78ea1fbc2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22864"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Sat Jun 19 16:52:55 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X���Y] �}��1Dd]����P�t�D�r�oP�gu�b�$�d$a
a>N�}��R�`�_AI�ǭ2�����zeؖ��|��Ϯ�,o]�@���+	@12o�ַt�{�"<��i"���O�������Q����Tބ���o"9��z����(�-Zq�����*F�Zc�җ꾇��H'ijR�eDn����ե�z��Z����ڵ}C�El��J81��} Q �W�>��)D|�v_����92ޙ=�|T~��y���!Y1��}(#��u^� ���3V!�kӥ�$���{0�����vT�{(� �v�[�-�?3"� �A�#�ƈ)��e�C���w�/� b��@H��<�-�@-����urqA8mo�x�gDΐ��*UL�q�[ca���̷(o�P��m6Dm�S�N��:���S��������]�����⌦�>�5H���㹡	�\d �?|�gdƉ{Iy-{ǘP���L(�a�N<���^n���xNx}&\��$��r�������Ɓ�R��Y�H�}�����4 +i��#����a{!j�ipg� C��b�G� Ұ��L!*�JO9� �E��94��ۥ䃹���y}u<�Pe{����L��3G	�F����e�EN�}O��?U���ʦc8��b!)<t(��vC�'y�}������:%*o��3{�U��_-��+�Oߥ��l�FL4��7��tK����}�n`�*�y��::Y�K��x�V��?���0�S����Uz�i�s(VA�CTˬ��H!���ȣ��uPf����8l>!|2&=�0qÝ���I��r�wd����H2H�l��>��Mk�������������]V�r�.��Chqt��Ѐ��v�3����F�{���B�$�M8
��M��F'=����+l#�,�f���%���P(,S��Qth-�%�G�U��M �{�QL?��U�ۄ��B�ؔ��^�}�����]����o\�o�x
���P^U.`�k>U���	�z�qL=�+s��6�	(�L�ʆ���B�,�W�䆗��S�ey��k@���G���{���z����O���)��l#�("�䔇_����/f�fX�[T��)4���B�#��=�8[o~TS!V�G\����X���﷦�p���f{��֫m�����n#A�� �k���Zn��˛��h��t��]�+��:���a�C 2���3�l��<�K_^8�V'�I^M��R��̺���腴f'`�[����+�Q�mm:9/��g�+t��OMc�ր�䃣��8{[��v�>N��N`fY[�˓���(���E�3
Lk	����^!����)��@��oMs�(W\� 2�b�y��"D�A?��HQ�WX���Z�J��2�;��� ��4;���ȲUU��oVB�������ֵ�q�W�������DZ������>�_�����i�\�fa��[���\�����S��֥�m�Q��2_�}鮸�
�2�hL��'�sq����)а�Ut���'G���Z�!\H��x<��f���B֪�|��6{׌����{N:�K����X��f4����y�g������V��Xȟ><�l��4 f�vɠQ?������*1�WbO9�>%_���X��l��8���$\9�-��%.H�+��'*wR"P���KF�2����'��ƌ��4���#���ʤ.ėi[�t5+����ZfUxX��ݎ�����,X�������)�g�f��$���Y�tP7q�U\��)��"#�ȥ��2'�4��54��lʊ�]3F&�����]�11��Ni����}�	$W���R�,eg� ��p��7b��Ċ�N/�,0-� �׎X����Ђ�/���eL�#��$��F(��i���^�&�\$�alM���$��/���-1�k8��IoY�[r�5� �:xOK���('�g�����%��d�X���La��4خ�=�l���ds,oB�s%(i!V�|#r�2�L���q)Z�Q>dֈ7+��w�t��;�WH�㖎	��l6IFf����]����-���x�����S�l� J 'H��t�G�.z����L�< �����gB�y���*e�cW^�"dW�D��Y�5��oYMY������E�p��G�7VK�X�\b�?$��w/#ɚ�1�]>�"����6D��O·4r4����hT�ax�h'_qZ����� �@�W�
��I�C�:2�5���L+��>7��S��X��@�ԡN�n����8Ԃ��|c�	$��܈�a���v|l��8�&Xh4�o5f�Q����pp���b��Q#�AH� T��sZ����&0�	�X���B1��U �@���렸�i=�x���F}�D�*����%���@��Ī������@�w�|����J;t�)l���|�5�|�6��=1o��7�����f,�bLBiYXN}������C�yS!$����Wip\�s�ؽ:=�T� #5��1΢�G�a��9��as��1�#�
w+��ob1oa�&iՓ;]kG?�+��� �৒0��t[Ƌn��|�:L�!���oP6�ǐ7kU�E��U#>��1�B���3�=թ<��E����{-ϧp[�� ���H��d�-�B���[�>_�Ø��a(A3 ��:L� X��W �6R,�6�R������`Tm�e�Z��#�s�'l	�Ԓ��(�L��֤��p�G��A�w�|_a=��MI[��#`p����J��^�m»��=3e;C-X+G��waa��r-w���d6�4�!=����;&��'"�k�y�cMd^�s\�m1HY�bG��
J8�3���߁V�@���>�_=��rX��RL�> ]���e|�G�%����2H����!Zr�HO��rB���0 $�D&���QPQ�)���o��+��D���PC�|�WY]eV�Vmr�ذ�\O#tM�D��Ut�ߛ$y���R�X/Z�U�M^Ф����P�3�W��q�7���}�C�qA�=>����{ߊ��L�;(:�e����ɏ�w���R��u��l����+;L_lN�R!p"����\���A�"�C�{�Y�;�	z�wv��; |�C����%��%��t��-8�uj��d^��Ĥ���r�Κ���2|��	��f�CY�e����+�⠟!Dn�抺.���`D� {������f��X{D��Ya[�<H1�"-1�p$^<�Li/Θ���M�`c ��:�F%;b�He�ey~��14.��/�ä�w���v�tW�w�.�O+{�����cV�}���.E�^zi���\$���l\?�JjϜo��P���eG�@���{cӜ��N�Ti�/���ݭ	�q���8��R�#��n��h��8��}�0(�@T҅��8;:0��Ӆ����j��cO�����H���g�����%"xNCmc���.�/ƕկh�C��{Az�9��'=�E)0T%�D�/��m=�q@�2����󰧝a�����ٝ�C�
с���FK-E�<�%¨?d�&��1�Ss�ɾYf'��7-�ox 귧�ڋ�P���/�	%���]v�m�f>Q�g�����^�{�
�`��u�%ND<�^1Yؙ4���Kk\�4k� ����0PB��{mM��Vr���Yug��s��m�ߚ��]{���?10I�ġݒi�71���,�IZs�g�4�Ja��QG�2P\H��1����X�U-�~u��r�Y���X�~y��tb.)ikNS��,(�Ddˆh�|��^c�D>8Z��5�B�&̔�%��o�d�� y0���`�:�b�ɡgu$�0+,ѝl$1>S�)������oW&����3��?Jǯ2�"�/�xl�B/� V��!]���}ۡ����[pq�D|�8�p�)S�L��Lۮ#�?�c��SM)��k�%v&pc:�Y�}�yYFW���8f���B�P��R�l��R��`5���IC��7]��l��Qg��Э�1������ayȜKT���3X��A�@_���B��QϞ��L�BzN�Ȝ sy��B���RA�rŚ��~a{���5��O2��b����1q�L���|���.�S �b�o��h?��TD�oI^s�Xה���J�H�J�֍ǯ�0!�{��b��OwcFf���s��f�>:�F��y�����Q;���K��u��a�^�G�ӕॼ�:�X	0���\#dbqfmBVoQڃ��5�v�wt�&��2o�&|C�0�5ǀR���)�}w+ER�F��P�c�Q�O��YT���c�i�����׊�0�/,!�DHP���C���˧��-�kY������Y2��+�����X�z�a������l�vʅy%5��\�0�G�%�$�c1�����f1��H�R�-�[�b6ɓ�u`����yV

�phWz�߉P��-�ǜ��fΊiե��@��!.�7W� ��E��<&O����X�3��)���&�bG��(��I�KJjP{�ˀ%N{%^��}P��磋��ZX�Ά����t�2Ɔpj�g|�qg�4��ñ����L9P\,����J^T�۟�U@���Z�؊��y�B5{{Z��I��Ҡl~�h�9��
Z4�>D��M�>]H����;(d�F�R�23��YiM ?L_��I;3jAS �q���bӟ{�Iւ��O��&H��I�Xn�۔l��5�e���3\>��)G��
*�C<ȳ(<�>�.�Q��c"�a-�����_ WI�v��(0� S���f���I���{��3N���09��qn��~^rA�����"��l�p~��]&ʦ�/�z2qZ�ܠ��'z)���-�v��\s Pb��נK�9¿�;��2\8��`��(쀊��F���wg�|���'�f�k����������[�xߦM���O�g.�T��M�Us���7��"_їdN>.�_���������1���+��a�16�,0�h�m�n��Z{��ô}8�զ��{u|+j��z����;�tM���L�5����yҎ��8���6�� ��;�`8r"c�5hϋ���Cp\�w^��k�j�R��� �E�b�5�o������|N�UD�R�EMc#�}�Ӛl�mS��y�B�|��۝,oA��ݔ��P��� /l�4����OYX�bQ�32k�4�=�36��������@p�O&�L{��m.��6y���ۊ�ѓ�D�8��ŧ�c*S(!r%���
�Ҵ������A�	r�j���%�UL�ҵ,���^,T����pF�sE�|�����&К�C�Km�#���^��ZJ����#a�PhZ?�d�~��f׵�Nfn0X/���#��(_���h�:ҿN"	�Vc?-S�J�]�k�eO����OQnU�mJh��鈲smKMԀ�bȓ�;�y��w��1����TC��אn�����%�o��]~���"9ȴ�Cj�
��3�a�i��0��+�c�P/�zS�YWR2} qT�L4�k�^ S�+=<��u�8������phQ���3���R��;�6�͑JǤ���H܍ZtX��g�G.M�Ks��Ca*��u�n�����Fd?�rqu*��j�Q"����{��u�0M_5gjs�R�Fjޘu ����ŊE"kZ���o*�g%nj"�⩼똊�>`t?�9=n8������Ϝ�y�z�&:Or�Wi|R�2�n�����\^�������c�\��Jx��z�}�S��L�+���;�>8�-��!T�V�W�1�|���VϺ��n�>oa�s	�>����%�pǷ>�˘� 7��P{&I�e?&e���*�DRHλ8�a>�G٩�)D^u9ܺ���2�#� ;L�n(C1�"�v�m���Th�7mB�$�x8����G�þ�>�T�k��7YC�42&?\J��!� �����l*��<;�<ޮTc���k�*���H�t	����ȼa���~��D"�Ӎ:����bj�����ds|���.����b����Ŀ�qނ���cf�WZ��`Y_���uJҔ�z��WB�lL�N���=_G�w�9��L�Uy,��rY�itis� ��y���+f}'�7� ��_�J��ï�'�g�S(�!�|N�s,%h-`�I{��nA��R��@���l�.�7�c�.��N��O�aG]�j��1Ls��Ƿ�l�D�+iL���m���4$��(B��۵�c�e����F�4FT��=��dg�f��f%7�"�y.��
���/8��oY'�E��|��N�Xl����l�F8�����HkK��Ajγ�_<)g��Sv�bI �/��y���8�o�P���˩*�>�Y��&z� ��'��/����u���f��-��O�����漜��->�S��J�"�?#��1B%!&l��n�����Kg�(�N=EXϩ�i�UD�)�{�I[6��(q��Χ�90�<����LYF�!#�s��ɓ��L����
Q1��b����9#��꽉%	o��^��3�k�s�η`�<�C�A-Z��~M�B=����y��?�}���x�����Gu2��*�7��_WjC�!��ۚ;�k)�1�;�� �і��&�6u}��������ē���J��1av��u֋8�JNpNX&PuC&Y=d�K�L~b��]�ʩe��/�Qi����!(Z��Ie �������Z�c�G^P)Z���K�W۵2�N�myM���}Jdo��gh��"-(���7���w�'��G�"�#����ኝ_��,\z��wz��W��Ң@g0.?��w#���0n,I�~��p5�aI0"�u��:8�:�9���sj�����"vqP
����0k�}�x<���ֽ����{�-�n̏���_0_���S��+�V�r�CQ�ˬz����-~���0}��Q�
pny,#��R�X��DV�Ƕ�z�@L@��+I'�[-c��+L|�@~J�֟8�!"k&렖��(���W%���M]�z�n�����1�J5�t�eL��a����Jؖ�p>4��9K$��C#lͥf��ۗ�u���U�Q;���5���4�AN�s{�蔘��QgNg�.��I䖲�)�#�bjr��f�b��z8L�k�Z�{�<%����xG��^��~
��������nUp亐�MZ���#��W�_r����n� ED��?Km���^*O�h'�L���f�����O��$���(ʊ3��y������V��M�Rp��4!����8��L���䀮7G�߬���b�i��g��*v;"b�P�����LXr9�f�Jf+�P0	U��܀��7%WgHA��_4A]�W�N��~���v޹������,*&p��:�xY��*�Ò9�4���K,�|����	���s��ƍ�]Y��u�0fK�Fii �yXQ�oVTk9�a9��T�Z=���=���3�E}a_x�W9�9�e�l�M���2J�g����7#��-{Ow�O���6o�<�4ؕL�;nM!Π����X}�|�W�'2��X��d�ȏ*�).�A�џI�l8��R��`~(�w.k��5��w4T�آ����� ���2���b�K�����,7��qŎ�ng�%�c���?����Z�pAl�QW0��<�6���}��̳���AA.*{�ĐE�uGA��τz|�49�)x��]x�9�k��|t>�j�lA0�OX~�_Q}\���,�Bլh�ݘ�����)ΖJEGj�p�A�}p�<��3�{��/t���*-�ġp�g��p;Ϧ+wv��v۵�:�/|R����K�߻v�r]���EɃ��ߔH��1܄��k�
͆P�Vm�?h�T�ʖ���G���a����Zo��3�R��T�@���S�h)K���,�բI����& �Z-u��~��؛Ŷn���9�5�E�?�5h^�� ç�^1��|G���i���~�;lj�q��t5'D�������\����}~8��	�5sڸ��M���C4
�#����H�\0�Y�ۆ�^��0�횕f����ʌ4��VqJI!6��i(����T�������=�V�&�|�����d�?�G.�H��n0�d������c�u�{@�Q�w|����1w߃�2���j�����1���ė3Zu�d:�Y��л�]��Y�����j;Ҽ���G^*�>���P��{u���n^Iᡣ9gً�@zk��Х,!�w��C���>��L��t�>hli�yѥ��L�7�a�$J�K���c?>L�v��o>�^��X�7��u߶���"���o��tI�x`�]�#�P���#޵'�$�a����vx�8��Ka����X��;���;��q�7-����>�i���I�Q ǵ�2�Ë��]��&�!D��M�2��l�B���'����6�� ���4Y�����f��?tφ6\�q)����֨[=�����+Ǯ����IǄ�ŝ���*�QW�\��OL��jڻ�Bht@�&�7�}H(� �T��i�tH]\��x���ʂA��^҈'0r�>GD�B�3,=R��i\��|o3�����s6#=�:z�s���P пX���&���/`�O6�����5�(�9�d��x�yB	���k�5����E<�3����qh�x�C|%U�MԀ�$��ɚuN����]�!�(:Y}�/��[R�f��z���W�f7�E���]Ӑ3�3���X�_�ٻ�JK��)���,���	�psÖ*�|p�[��VFNTI`�}`z�y���x��9I���r�t�h����.C�ޟ�	. �\�A���(K`ov$D�i(L=��@�{�ĩ�_���o�ĺR�����<��ٞ��ռ5jq�-�>_�v�Y4l�X�y�;�����fw�ֽ{�ν.N�+9��G��C�2w�C|�Z�nѓ�j�2������G�y��Z�^5�$	[|���*t�"��o:^G�[t73�ʩq��ܔl����q~�5�g�}���g�9]Z`yx>�QI����+�9�>p�c!H6��r���]������uNz0�uP�J{�z�C����+���df�R"U��B\P�0�R�Q�g@۰t���yE�����N��[c'���c"�z���,�������QB�g�R¬3[s#����-5���X�+,�&��,d^��$���"�W�P��5���M���gR�Ú\��m���W6��*[�g�<Ap����
A��ZK��8�obS� ��kJ�ů�vD��E��w�{k3�hF+XZcb5�(ۓ��Xf�q����ތ�W�}��Og���7�1n�!���0$�������%𯵕�#U��ח��9ed�PCb˸A���V�tx:TU�����򵭵ԯ0?�"��U����K�
}
�<��A�u�}���\�\�E�wr}>C����)��+AԄ(,qfbO�O��ݰL�qV�[��U��&��v!��o���8�L��k2�P+B�[��!#]�f������VdK�O��q+�G1�fp�xJ9i�}8��`�UB3]���?�|ˌ��WR�����]?��=	����0e�9����1oB��n��aߣ�d9���0��N�	��̙=�SX���X�r��D�,�U�-Af��dbW�U�4"3uj�҈�)��L�T��Wr��;�H��nb�(W?n��+kb��W�T`�y~uoL%�8'��as���?!��Is� H��*�p��n�~Z�Zm�s�菱�V'2O@Xf�Yj���<���-��̮
�t���[j ���tC��|P��6�9�c})e�uj�b��Ѕ����d�s/!H]��b�=��(��'L��1���߾r����R.�g�:�1ϯ��C�&�8ǵ�E@- ��Ld�⊝�sk*8�c�𨘛��ݤU��� �0���`('����v��OO���t�r���"Gn�YWh�uϕL5s淣�Q?���C�Z.>��u���j����-����@y��a�m� ��B�8W]�z��y�z� ^���K3D�{R�f������
cwխ;�^A�Ъ*lu��a"�
�+}?��Yd��<ï��W�0����&s�p rW	�(F�eA|��,#a�H=��E�� �)u0�m�X*�<���r��U�q�a�A]�|P4m¤���b'�q�hea͸��6F��d-��;[������FEX����q�����=�snb���L�L��Q��=���y�e�L�6K]�#P�}�p�7��"�N�,�e�d�㯵P�$��E��LG��+�R�V�����s����i0t�|V���06QX*��0�	*�;��}�F��r`�&��ܸGW�W�f�g��y���!oQn�s��R�Li_�!5E茶,hÒM��Rc�m�ar�å5��!�������\S����ay݆F�sU~����In^�M�aN��}U"!m���TD>�l����A�;�Z�0����K]��� [���J�����kk�ޝOȮ��v�z�ݡ $���S| �����TM�7k��e6/�?�J�Djx��]q�͚zӘ�S�U`Do09ot�x��јgk�ҩ��E(��ۅO���N�_Y��K�kAU�)?1e$���p��Fi��
�nP*p��^mc�3�lY�%��wM�9�Ցu��(�fl��	�_F9��jWt�����tO�3Ǩ�Y�*��»��(�����4��,�;�V:�"Vfn],c�%���H������F:�l�X�vo)P�R��������h�+�P�g��(�mu�a9N[���O�^(� �d�O.�����u`��^z��:<��ä����>�)G�����l�F9Y�=kb��nͽ�=�ͩ�ہfR�8f�\@[Ƚ �.԰Ȑ�z��+��Qͩ%�F�)�Dsڼ=-��U��w���Ǣnz����^뵈d;c��7�ˬ��e�n1 H���]
>O$���X�R���:2��?�rׇ9��jT�'���b��lag��;���H�l��@���$K�NK����+��������TӀ[=�j��vA��/ټ=��Y�!��Bu2��3Q��%u8?m����x�z΃��=� S�Q�< 0��d��d�D%��e)W˕��� K�÷�j���Nt���{����pc��r�Ϡ�����t��yh���˫}�l��<�q��,��T�S{7��,6\��=�T����+��@�W,?�8l���G
	�D
V3�V�ǝ������5>��B�.�	����a����[�D�$@7�f�v��C:���{^b�uȁ����8�$ݩ�-�0(	wٌ��2�����F#H*�'7�\RN5����(\ǝŋ���C����؇uKt'�Wm�xH!�C��]�ߪ���e�`��k̎���\����G���
'�v�|S$L-����"���̼���G산�y��A�Y�\rӽ=�������~54�Y���<P�E~ڼ��I��wX#�G���ig{0`�nP�+�,~�:����|�5}a
�m���}f���VɰL��ä_�#�A�I��CE��IV��Y��#g@�D���+O-N�p��[�B�C��FnL2��,qb���#1�R������,�W� j�E)[$˶P�i+1[��0w��-���_� �v)�=�P
hW�;Z;�Z&l���3�hE����E����j�/Ȅ���/���;�~�ͭ�A�����t"�k0+ۣ�������S
ȵ���T��G�|��*�)�Og"��%b(��ɻYo1W��_�����Wo���4ÿh���+rlεĽ1��`Q�	�L!��Å��}6>�f������e��v*��k�����rk���:����_ܫH)��l�}��d��ba�-��)�Đ'�{����Ɇ&���(�}��83��Yf�D���Bh�nܘ���vS��~��`\�w0�6yo�ԭ����$�RO�`銭���,��k��7T;����KX_Oi��.�Jc�:��k������1��M���SЅ_4v�$ѩ�J���u|[�Ϗ���/E��h�3��H�dpT�a���q���@y���Z_x�ת��^��*��߆_��4�1��=�->D���ڲ����!�1���I:Y"4P��	�������>�v�]��UR�e}��㝸D��'���;�8��#��kBo
��<�*X7�wa���ԓͅ��V;���z�li9��������OR N�� l\�%�T$�BS7�a��]���S�ÿ�u� 4�^m���h3#�7+�����~#C�U,���x�*�:.�L����1ן�Ҽ�7�B�R����{M�OS�1�B����8���&h,�(U�����e�f�@@�#����:`�Ν@���\!)�hE�22�u���b;	u���-��r�Y���~yW���� |3 �;�^�o_*���?���'7>�	F���h��oZ(���3�ַ���d��H���+0��zG�_���w�k�E������I���}4�α��<j��T��a�T�R>ϻt���+������LTɃ�:��BE�W�f�4���*�
����C�������1�r�,��*���^|@����*G�G�|�B�6H5��l���Vx8(T�HN����ƞʯAJ���2w҈].J��!���qg��![]<�D��x7��$G
5����{d����{>�I]�q�E�F��)o|����'�fedhE��b?�ǈ��F���1�����.�e���N:���)��l��oc�Rsz��-hS��]�Kt�)�$�rh}�E�}+?��6�=�ܥ]vPζ�y�ݿ�6�S�M��"��Q\M�c>|M�(��QZ��u�I�Q"3bQ�K��� �/#�V��q"(�L�J<�B��o#�2��B�R�2�2nt�D'W��� ;�k���	���DCפ0Y��\3Zi�'��� =c�(��Q�i��u](N��)���~����B_�i��e�}�VA#���T7ck&�BOՒ
a�D(I\v�;�6π� j.�>ᔅ5��2����l]�R����d����D��Q���S~i-��}��j��������D���o����v�uQ���n���^j��4I葮?��@Unݕ�Hc����.��]�uk[yH#cC&?����Qf�\�R���)�v3�Øv�C�����NX�f��ў�9Q��r܁3|O;�.j�>���33�/K�ɻʄL�w36��H��l�LX�̬CS��je4/��S�h�{4_��6zs���1]�'��47�X�&����#3z6��DA�0�:ͨ�B�&��(��Aϥ�Sx,C���T9�3�cj�7!�8�"Xbx�asR����?,)(�I�8��2$k�s�r\Y��N�]��|]W��R��
QPv��c!��pWN�tg�)�;�n]S]B��3®On��zQ�e�GOF�u\�m���>\}pf����	H"�¡��ng���Pl���_0z)�LG��qy�4�FѴ���r�����>�d໓�����@Rb�n��!֝���+u=����3+�P*���>�ÒR�F�����&�w gA�ՐS�1f3�HA1K�4���\u=Y1�X_�2��xz�yI�I͙����;��t���,�)��ˬ��$�ֶ�����X�%�؋\wk��)�� ��2�~�ݫuܐ��'�ׁ��R��{�����]C��e?�&��z�[0q�)f���eɳ�^� $en�ڔ����L�x>tJ��ڱP�ٗ-��Ap�����*�����Xpǥb��mJyLn��
��/��A��D*rXA��yG)��*hU�/h��˫-��H��ΩR�)Z&�|���[��2V��;P�57��χ���l:X��a�]�t�j�@1K
ho�7���V}��G|h��r �I.�.PpV�u�=p��w��g����,x,lB��/ ����04E �wU�Ex�R LFC������\�~Ãh��;����n@�;�HRJ�Y�[c�`������7`�*�	�[��� ����8F��7�g�&R�����W��)U_�Bґo0J�܇�O;������Y姬�9�Y�A_���v(�0�bid|?5N����zZ���iqWä,�~��! �U��j�C�i�M6�1	a�s�3��ۊH��R���  PN{��*��N�L{'���f��qWai^��7b�γ���z!���5q,]-e4߇AŵO��?0��=�2o%Êa/�P�-�|EÂl�g���T|$>�O�}8n�#[x�#�Цè�KO[�ma�¢�vf��jc	6}��Mi�6���KZ��kG �.,?�MqWnh�ք���4)��!g#�N_�11��)?��L��;.�9;ud*�ȳ'S%[V/:6<�x<�����צ�XFz�'�傉�n^���]St��#�Ǌ	�(�AZs�n	�K��ٛ�~/C��w� &z�H|/�e�\��1���}B�b�\`bj���{�$��n@k�P��kcB�R�����t�:)�1z�,�5�_GGJ��[Nb��6:1J�>��j<-i�䂆\!5yb��r�#�&п��%ռra�$sp�j)�E�rD�]f�)����n���t0�wZ���6� �x�)�砄#� ��,Rv�����n�ND�>�ì��^��I	��Y[��ð�:����$�>�ey�h���/<v2�?Fȼ ���ҭ*%$0�e����r�����;4���̉���~�u�oԇ���D��� ��Nу���hr3,�~��B|��_c�X�@V��E�j7,�P�� [nX�A8�'�J�b�d˒C^�;�aȋV(�$n_�ǓN@��_�zӂ��0���ԥ�`\*ۯ��ߧ�;7sl�V����{����0�N';�NmԱ8Y[���;'�G����j���3�u��FUob�I���Xe@W���x������۪�pA�3�$�R�8��+��^�K]���[ӻ�����.νf^�!JW���?��Id�r��^N�Tk����Ҡ�F;�?u����sy�o*`�.r��+a� ��v���Z��@�x�6�*(�>���n�t#�	c/n �p ����H=M�����ƨ��k�Ðx����@����s�֦(�{�4t��Ǔ<)�'�fӿ�h4�PH�jB�z> c��^y��R�S�wO����m�JJ}��Mf)�8%!�-+��1����o��t�q��lW�uS���Q@k�¦0dW��ڀ�i)��P[���X[s�;5#
ȹĽ�׷Մ��\n��rË�K�}!�2NQ@%������/\p��2cp�s{k��}��6Vb1�z O#0��>�����{[����a��>��ia���-��c�!aR>SF�1ݿ�'e���SlY��B
q�_�R聼c�
��bo���]�"���UY��V�Ih>��ɿ��'�7����
�>�H)5x�5�A��"�a��OAь����:�x���`_�]}G�	/#P����#l�5�f�����m�!_xOh5��Y�ug:�נ�c�<DL/����8[�^�kh<�x�̦�lyfli��ڛ|A���J�Њ/�����t�@9�իxv����A�1C5|��G)�j)>��}�a'H=�L�[2a3�Zg�&e���߬�3#(���Ѩ$�Vh������D�Z>R6L�л��t�\���75U��Er�<��1-��lF��$�RGZX���N�aI�ֿv�*��}<�A�V(���"�3�+�1���K��B���r)t퇱�TG]j�4�u&(����Y�~��o`{^�nXS�:�g�9����(@aF��tN`I��̅��Ba�dˌ	�	�C&"�1��յ<�=n ���^E������4�x{����+��5��+��q��K�H�C�9�p�rH_M��lmB-O��6QNUk+��вds�&��b5�Ӟ��
_<�.:֌�R'�Ӌ�ޮ7��-�@��7��s�����}�<c�B�M�3+�{5�
�B�-ju�N����Һ��G�NK��.aL����.9���9n������f��Z��"J[�ݧA��Sy�N���$�Q)�'8YдT��F�����d��y?Ն61U*Ҿ� d�ծ�_�P�I5�߰�Y���e��\��չ�ϻ8Ȕ�!�d�6͟(��� (~��`;D�=g�����ݐ�o+%Ag�  -*�?�ܬ{�sh�8�e�͉��G��Ӆy� ���z����EFC�$�V3`B*�FkT{=]�GΫ���4�FuO��Ѫ�Lks_3D�1G[�S`����K`vm2���~�p��I�B�U����"����K刅T����9cͶ}u`/9�М�N(�����`�a�(�!	?���c��|~��Z�%����|��,F7(�iN(�qb����-s��]�3B=�l�ĺP���B�ˑ_�Vh��� _0�9��,9�/fF�@��R�3#s��5D)����D�D7�<���pt�Ŀ�O��=Ěn��B0��f�1Ox<=:��3$�G�!��d߬���F��>�Q]	XND<��s�4�S�5e�E5�d�aL�٥�TVD�j.{���Fg6��GU
�B⢊���"���ŭH�+F������6�%����M�]��	F��/=��o9P-�|I�,Y>����C�ކ��3��kS��eݓv�:v�&)Z�(ntc�fm��
,sμö�ӎ�!ȁ�&�L�?.���2���	;�|�8��0�{�4��2_R�J���Qk�L����G���L7'�0���5��K��:�`�aX�d��3-�J;���-~�٥t�����K'���j���Vlu�QV��c�S&����"Ll���W�,�f���幚�c�q�lZW�}�w��wV�&o3X�U�x� 9*�O�6j�`�}pe< X��R��*��A����:mB��4e�ڐ�����r+��e�G7��ѽ�P�{�"���OJ4�P&�24�ce�C�3�P�m�a[QH�F�U�
�ڱ#yOU���&���UQi���to1c+x�+j�i���'�J�r�"������K��s�sy]��%�$v:_T`�͗TR2�k�gO��	{�3I( �5DO_�)�k���#pk��MoVYC�
!��h�J�t�Ա� �J�MZ&�� 穳�zy�%����zg���|n��8����@��Wm�*W�uʤ���o���P�&��z�!�?B�9~%^� �W���Z�b�{!+"7��`���s�	�_^�K;y/���ߊ����Z��6�u~��aik	ߠ��G��vpMbq�r�E7+��%��HS�w��an=mNP9��>����ɠ^R�z�T��,
ÛH��F�O:�F�i����Jy:"E>�L��tA���?U��h����Lm���0��l6Nb$��`��h�E$�ge�j�-&��Y��%��R�ز�������0K�}r����WzL���=b��l%kD8�~'�y�tB��0�-ܯ[�o|�|̦0����b�������ѷ+Bx23QB�}�
T�cz+l&��?��J�9v�M�v�d���}u-�z�%��D��E�]�t���L�ǰ~��YK-P������$��yF-���@���n�S��U2!w��R��� �z�urhhn�E�晲1�OD�(�śPm��&�?o��o������eg[e�;h5��H5�k�۾�^�������z����6&#��{��� ���k�iXg����r��l{�q
�鎉OۅS�i���6刘���Xe�e��3��?$w8iT���90��'�ۉ1J�D��
��J�Y�Ra�*H0' _��n��� (_��-`!�.���|�{I�i��z�ߋ�iF����g/ݎI�J,���
|��� X�A"^.f}�/P�p�栝dZ�D�	Xq?ϞѲU	J� ������wV�V��'�9#����U�l���h�qJ���d��[���X
oB`���W5x�t�"�0�h%n��f�e��{���B�j�����h��}�ũ�Qk8֥�>�����`Ҽ�[�:wG�+g�@c=(h4UK�v��9���cD����B�^s�j��� �ͦ�O{��g�t�'�fs�$�}���0���� YF���(.`��!<#��*B��+_��Y���M�L-�q���v8IA}�=;@o�:��'
�?ByKh	W�߳{��'.�%߻�C��|�G�':�i����&�"��7��Spƣ��pd�ن|�aCF'B�YM�`Y�h%N鯢�,�a:k,�0��Z���F��K,�pA���e�`��<�#��ĸ�y��;)G��nMR�W�D�ǟG	>�O=��J���~�m����	��ò?���j5�|�s���0��"�H��0�7�҆��̞/��[Zѣ>��Q<&�Qh�}�Tj.O���y�;�y�ݪ��/�>��	Fy��J�k�u������W���u���>\���^)��s�% �P`%����H��?�x�Ɔh=��i��6q�����D�]�L��f!.��݆�Ԯ�VA��؀��z,���p���y�E��� p=2T������y�b_���ծU0W�%h�
�,�<�2�]��ͱ�8���&M�T"
p+�ٸ�����eL��^(���j��LQ|��0ҷo���3&Ϣ��������A�]�Ԁ�P�{@��ſ�sl��'��86���Ȃ(�a"M�A
� �G6z"T�.��[3#��ӷ�+����,G���|�z�8jx:�9R�Pj_��rc�L~��Ua5����z�N����4�
�Y�I���|�f?�9Wu��� /ǀ��ee�lX�y��Q�a2�JD�Źǣ[�+��]C@m��JLM���N���}K���yG��l��z�ݵ��6������,��Q���0#��%�V������XI�=V�qL �-��N����K��	���5ĕ흝,[��Lڀ�u�T���l~p���?`��N4�{��b%�w�\�<�vX���99FW�Z)F*�Yߍ+O��O����	���:q���BU�P�~`Cw�2Iӹ������k���%�7婂T&p$��(͟ێ<'<�R(V�o{qB�$��F��2��Ii>Xx�5�y�o"�r{���gly]ς�z
���TPԸ�i��*p�+U�?�zC~e��Z�6� Y�1mݫ5t���|�lL��U��-��ֿ�����m�\��bN_�Qw�07T��ߡ�@���̽V�?0��B�h�K�cN �O"�$�O���ԥa�(9FZf��P˦C��&B�eS��e<q�H���e*��r���,�b�K���k�nt��*��~06/[+�a}�`r!0���j�{��_O7<���)zl��QC}�"���K���6�s�I��'�:X.!�Җ�/��Lbs�	�|�1�D��=<��hz��ј��H�h�x/��"Ӿ��n�AB�\����l-w�3᷐M�M[oٮ���	߫�d�aU�6���p�49UX�c�����������z�e�Qɕ��q���6���XJNy.߬4p�\ ��J=u�Z�*)�j�����/���^'E��P��������'nb���U�u�bD�kS�V�߁�{v!�K��@���`=�?E�@^Y/�A)�������w�DQB)�7$lW@��	Uu���o����)2�&"��A�y�Q�C�Ջs䚃%���[���vg��B��2D��Q��Ľ
��f��,E�]�W@w���r)g699�3ΪU���[�
F��X�8ҩ���G�(��L%�У�����M� ,�Mq��L�+:8��<h1 �ˋ����F�;xp��w���g�.TW<�u���������t�]R��,y�0��R%���h$����%�.�Q��|)O\葊�=�5v��]��I}���"[�u���(�p�㠤�$0܌	�����[�E��dv'�ֹ*�@Ȩ���i�s�u\�e7)���>�>&4�'/�U�L��,z@�g��~���$xʎ����PϽ�&�X�1�ZJ n<Qʜ�uK�Cxu����XM_yѲ��uS�kw\%���^Z���� <�l�鬵����犖��y߻+��G��LkJ��A�w�!J�i����Wc�?.
�&�_�ֲ�u���� �oꐱRY���N��X��l1��+p���/����N��Dv��`�ϋ8�ډ�����i�6��^��ʽ@({ۊ ��� 8Ħ��<o�K��,�G.Bh5��w�Ճ��+����x*�P�ƭ�������At�)���w+����&`�u�@�=�,�0iB��C�E皘�'�@�k[e����y_>���)����ǘ&F��������}Y�R=xB�����4+�4dSB�?5�Ivg[C�2�h��K���c���9��xͩ/���QӍFDD ��ɀ0թ4��@�dr��w��l��t���=OH�tӐTa�R�ڷ%�u*�8�m�}|9�ˠh7�IsO�XK��\�rDP�'7�X�!tA�B��m��p,�}BwE.R�g\VN�����z�
�	��g��zڗ^Np�>+)#�I?�
��Ma���aH�Z�zmF9�p}>�	mc+���@�Ư��}�]{=��hKa�����B�\�p �t���� /v,5)��~lz���%O�h�9WkςP`����2Je��X<n��9�P��j3 P�M��}ʴ�0ou�c�a9���Alsq��ڝxf$�ӫh}'����u�D|�@�O �pd9����;?����
K��#ȋrW���+��� XɶPS}�����8:$�>0T���n����oVh�{��AL����U�=���n��Iy7��`f��U�0�P��У���WߌI7���П:j�B>bW�吏e5~=g����zMj*�xc��¡);���4�Ӫ���yE�ٶ��N �<>O.�@�[w]��>a�{|�q�����ʥ@���b �|]�u��OB;T6ƁX�r=��eSR���u���Y,+)`���цE��7�̞�@(��d��]�P�
���#v}/͆Ykģ��Za�|
��k���(z��|R���8��2@_RN�l��)��������C�����T��L(1<�l_|Op�b�?��� {m�����
L6X!�혚�uw{R��j�0������q8�ƾ`>Ŕ�)]�����,iE��*�>�T��|��&�yo�[�;�����?++Y�������CA��;�4$#4:}�+7�\ܑ3qh���x� �o�y�{ʰ>�. �f@�u�ԡEn�5ɔ��������vѣ��j{��ߍzeH���sa�x�ĥ��"�L#�䊁����|k�ʐ!�\\���7m��w�K��%(%N��O�����x��,��9���#r
����RR���W���z���˵"<&�5�qUS<�;�.��pC�`J���~�^�	#���zY�~(7�r��;�dބ�z9��˅�6Im�Ә+E�U'M&����!��$��<7�SCv��$K���\vl?K7,�S[&p�� ��NE���qE���5�|87�.�`�zH��Z~㴱mL�g��[w(�򘈏cm~�7����J�v��n��j��`��#Ky�t:�������N�W�I��z��x�;[�W�7S�^��p� 8��BdM�[�g�)�AҙNqƟʹ�P�i��knK<�����Fڨk��:7�N[|�ϯ0s��oI)9us���҄���k��0�!(���V�!�1s�ꮝW�#G�Fb �9�V(���*����}��L�(�������~��8���i �~d���X��i�S6u@'X��7����ĭ?F+���l�k0*}X�&���lFI���	D<Po�����˄5u�6
ux���̄�>��ra�%�@��F�Y��ky ���i<M�� 'D���\����R��$�Fv��AI��V��������$G�qR��TI�)�l=����@��'e�B�~�i�G���@us����}���0���,<�c�XL�9& uj��G�:��$��j�R�	ݲfcj餀��}*\��d�����M�٬Gr�A���+�0e��NrfJ�қ}�e�ߐ"��[-$f%(�"u��s����:E�˩[����y�|��v��@S�������.��ݍ|tL7�-U6��D�"&�8�^[b�t�y��~P\�i�;�tTi=%�η��W������1-� t��ag,�?`"�nJ��Y����8��    ����b? ����L�����g�    YZ