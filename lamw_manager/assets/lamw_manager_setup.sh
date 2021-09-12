#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3426184144"
MD5="a6325450a58887093e167d956acc4bc3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23224"
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
	echo Date of packaging: Sun Sep 12 18:54:30 -03 2021
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
�7zXZ  �ִF !   �X���Zw] �}��1Dd]����P�t�D�G�R�KCDd+[���4A(EJ�K
|z<�"����/��c��ʪ&z�=��!'Lf[��K�T.��C,)�L��6�Z��d�嚥�����,��|��l�r���*���\�t�M�%� %R��z���8��V3�;��Ҹ������q�����	q�#Q���-M7���w�J�m�%qɏH�S.�����/'6��u��s-�R��@����CT^$��K.���|���m�M��\3�&_�z���IxM�L��ڻ�)�xq�o����� ��D��mԖf�]Z+�X�gC�_!u8��.���$?�Ԗ��-�"ߙw(���2L��Yr��Y�3mP5΋R������Ȏ�W�+eIsI���Kg�h12(�+�2��=�*=aD�'ky�����j��> 8�\]��2>!f�d70,�N���ʛ���*K`d-'�Ax�)�N�'���ѳpV�X&�L�3=���vx����p�dk�]�Dg.H�"�1�� G\�Қ=�^.�C)Gm�]E]
��V`��\�K�ξ�u���:6WDa�'4�x�;��$bP�;M��w��uAB�5Ʌ!�s�&���m�*���g��*i�����0z�;��Fgr@���y_�%�T�^������7��oƦ���Em�'�F
�$��|�T\( },!��_�?D��Ѷb�:�1Vl󒂙u��&��Fd�!�5,�����T���֘Q�?ҳ 'w$V�5J �,���(�0bc�ı�MP0|�ŗ������5w0Y��LQ��g[�����|3	��*s��[72�.�["R�!=�G*XE՜$#���D�m�Y�3��R�l"�$�%����S�ai׆������p�=��0�J*e�,�ˢ�&l�|�)s"aea�M���h�Ȗn�3� O��D=	���������~]��$�T�N�y�E�bϋS�����Lj|*���D�'��դ�:�sSJ��n�S.w��I�O<1DV�����G-������6��ڑ�_���tq�0��)f�j���Õ���s���M��\OM,�{t�����H��B�{G�^��D�!�������4�+k�G��3���ß���z���?	K���Q�YNڰ%Sޞ���Z�lqۓ��HѺbu�~UF}Z}'��"�d�)I�!u������_���{&/���{���%���V~�P���n��`}�0���gCx�G��̱�w&P��M�=�CpMV(��D����
�+�E��B2�y�<��p�M�Y�﷑EM`�h�2s��xƕ!�˰�7��p�DrsA��}��r�U��R��e�05B��[U��Ǒ"&��)Ī�ba��iY��al��%]�l��Y�ϹV�	9˔�(���R��P�@f�5� >��6�$G=|��(VU[+A����h���)��	���-��L��^�5�i;��h�nH��B��k��?o�.�C��ʍ]�WB��1_�RU����������`�l��5Bb�p�GđZ^��.�נ2q���{Q�|Ѧ�� @u��*ZY�\O�a,|�I�m�D-t;�۴���	�<���C;�M�Q�|���wP�j��V�_�����7M��ؼ��j^Od�����y��,0�ݖ�qr�4�5�o�}��*�
	\�XB����ۅ�g��i�f+R9�V9��{�_��d�PMݏu�̜j�K��R/���p�Y=�Ӓ���(����(�����?CV1\o�	��9,��So:�	z� �W<�ͽ��1`��1T��7#�B5g�$X�{�)X��Dkc����z�S�p3�A,C_��@���lq�c���{f��6	'"o��	,8?J/��r�P>����T�B�pV3�`k-N��W���c�%���_�V�i��a+щ0ĆMP�����5^qb���[;`��1:|�֥`Di�W�$Qց*��ji��߲����k�p�m�Q�G�g�Eh��4�MhrG{�ު���=�e���H�վ�eF}<�r��0Jv�>�������4��9�\T�@��9k����	ɜYZ�{������ӝe$��d���HQ��\����N%��b��}GIb}\f^y�#~}|�cn��L�,��Հ�&&<�	Gv43��+�2YE�vמ�#��~ɐω��� �f5���55��qO�w-X�G8Б	�	�'0�L�V�]b��\����ij���u�E�<<zs�ׂ�u+!5}��?-?�m��=�	������1Q/E�t�©1U]�������ܠ��T�U�r����Cꀔt�v>�����炬� *��D
�0��U$#�Pb�a�"ww�'�������u$p��O�_6@-$� <5��<�i;�k�k��J�P�{�C�����St��"M6�خ�E����-Xm�������v����)>�r}b� �+�XH1����Q�a�K$9L �HxU$Ő��*�;NOKw�T��� ��ޯN���=em��J�ӳ�и���M�=/���آ�(��k���J����k��Oe�]j9��%��h1��"���x�������r#�@����A�5)R̿
�g��F����S�`�g>���"�Fr��?����XƁG�!�$$yk:J�-B
�i8UMj��Q�6%�]���I18	��/6Io��M���:
�5�6Z
O�v����h�^(hƵ_��3,lO(�r��A�Ĥ�DV�@f�zq���g���`��X^�V�f�jڻ��Xɢ�ԧ��c�ff��B_Y$:BI0�A}�(�ϰ�in٭���1y�-RF�#eZN���Wd���!�Dް!`o^��q��n�#�3]���)U��J/{��� �H{~_P�B(��&����S����&h������S�ofʜ�J�i���y��Q���/���05����e� {��q��H�=�&ZI��}�0J�&��)"�)����f��+,j;ѥ��Џr�56�a�ɲd'�'������}}�{�H��c%^��?i�U%+Y�%2��D�"~W� ��%c_�R&��F�V�;�R,�=��<�"���%�	��1�����N�{����!�)�����&��'z���(�U���e��
����uG�dx[ؐ�4�W�/ �4w�`i�mc|_�l�l��)�+?�f�/���R=�[T���X��%�qT�Wˍc�!�v�sJj-�q��s�:w�_��l�V���7����I)5e8���'	�hհ��{yИ���c����<���O�����j���y�̅�?���E�p�z��l[~^.��EyM�F m��yϫ�����*w�x����z����͉��_ՓK�{����DdV~�T���K�[I�s1F��V���1�W��q�4&V���$nz�F4�
iJ�].+�0j&��eyX�C��䌒�N�[�b��\���i�
�b�d�m�)���TnBf��Q݄ĕ����Z��P�!��^U7�˻K��+Z����C{�'������J���.���%��YP��O"M�[LZ'Es:i`rV��qN����|�k�H6d��l1j�8o�@���N�d���x�]�@�G�I�19���^�2�G�ۯ��߁��ȝ@�>jB���s���m8:@��������tY��+�%f�%��j��"'���D5�V��0~���+a"�L��\&�؏_k�.��_JT�g7�hUH�څ߀��k��ܸ[����1[}��V��Ex�#`�+��˂�P���aT�y�˨�
i�z��"J�)�A��9A݈�d]{�/����h=�c��_�#n��� �|�y��� ��A�D��
����1�Ħ�*��K�W̆J�,1u����Cz���PWi���k���˽�\Z�
/{�!��i�ap��Wvn�Et�Y���vTm^h<��n�^�^��������Ղ�
}�<�Ua�v�4��~���U�1 6�Sfr{n)�߸���?MJ���^�r������������x7I3���yS_�EH����H`W� ��.M*u�I����v���=L���4�z����9"i��O�vF�B�Vo�yH�Y���˘qSqOX�'�Y̨�Z��/����,��m���HW0D
�?�M{-a��͆�D�s��2ʪl�ԠNv1Y����R �S�EͷG���+��5CJR-���,Ϻ�_\>��S���L7�\Ӕ�����3,��U�=W�D� ��С��T<t� Z��mD�g͞q��X`�A�)�j_Ԫ�(��9@�C��nn
t�L"w:��>. G���.���?}���4rH�Sř*�7��|bw��>�hJr�8R(]7��R����j�!�0|	��c|����+|��N�5GU�HK�i�ޛf��X\����{�� �=��2��Sځz|���Op������{����?	C�qbt�D���z�L~���'-<�V�Q#�
@}�E̅�I����,u���w��a˩`����N��l�I�����n��{T�8LO� ����"陫	.��ĞÑ:}�y�-��/�F�	�v
�l�~t��T!�cm.���yV:��舾�����n��[%#[[5�_�0��y]Y��{E���L�;���;4ti?ǫL�l�0��?y2���i�\5��>v-���-�>}�i��f�ߍj�)����"�0�7�2h�1dA�4b��]�-O��}l8U���z��ߣ L�g��S��[�x-�d�0yہ!q��?���0�N�;�˦��rʽ�=�O���-g�k��^��z�q'S=�fQrAh]�g�A��b��N\%L���`vB�9w�j�i�h]�;�¬�[����e��<��dՀ0;;�^�c����Q�`���4Ǩ+�B�O01�4&¯��=���5�Ǒ���j��ҸVw��Z����=c7|[U�b��R��Zdi��g@D�AKs6PL��k9���+A>x���<��ׁ��^�T�}�6,��7l�7�}�em�'��ȝ�84�f"�d�sf7�������(�H��+~������\V=M�E�Dj|���c������o�����B���#���ccnD�U1���3m1��QC��Zp6�jlj�ȷwvD�����"�+�_t7�`A�:�ٜ��q��(G�ej�x�✥��&�<�bc�J��܋��~f���߅��WR�/����r�{�j���&b�)`��V~1ߑ��׻�Ra����t����#��
9�_�=_O_i�u��/y7�sq�/l9���U��{@���Q��T�2q�n��9K�t6���c.X�e��L9	_�V.�n��p��`��"�eg��nQe���g�o����C�S���q\��������0��w��If����6��^�!�A� ��g?��%����[�3|�9+x���J�}�j�T]L����nrc0T��>aٷrE<,6G\��3��;㰛F�(bHnȢ�v�KR2KG;��|x�.�H(��YOl���Yr�J�.}����Mv��cw}1�2����}�ݑ�_����Z��ϴ|aTc`�C5r�7W���f��u���N"��g����Y�4mz1Ko�|��W��?UQv�6tS�Ub�
MCmR���i�����y2K��rGث���v�c)ss2�����{�F���N�������@o.�7@�߃#y�׏C4��LNTIǞ�e=��u`A=�1���[7��!^��`N5��m�V?{�ǣ�<+>!JS�rR��Z<6�n�n]��%�P��]���8�;�F��{RgY`���%����}!��e5>����P����2{��(���ĉ��� �J�� ����$�F)}���9m�����X��D�V���Q��(�!/��$v@3����NQn3O f�o�Bj����S	\,�Q�*h�il�(�w�� �(Ж]�V5G�������.���o�~��H�	k_3�H���җjYaZ��N��X��e��u��͛��H�Tܑ`č!�t�߿���{�2�n+��޸���򴢺	���ꞻ�v>Cׇ�r{�
�"�� ��h�?O�bJ(�6Y���3����y񧆄:���o�d<���Aݕ3���Q��
� �Q��U�v�O�ir�n�TA�k�E��֬��*I���;��j��_R$�;�A�F���B�Ӑ�mJ`qP�XmZ�sSO���A2O���; ��s�V��	���w��|��0�85����z�1���f�u�`Nor8��Wo@ v��*�T ue��;Q���[�5#�Ġ׆%B���I�hk���m�R�Z]9a����An�����=�GrA�ZU������oX\I�}ڀbh;e[0
�tkOS�n��t���=!�\�f���7��u���DMe��AS�]�ոGp�%�^�i�j't0�U=�{+@�&Hۋ��O�
�#��o�;��^�Mh5r�yȆ1g�gZ񘄰��cTV~��!q�%�Y�������+�Rd�IA@�܇H�@}�������i)x2��s��.P��-S���@�Z�v ��Y����S��ϳi�p�02�Y6�"���]4�5��J�_���~>0u�K>ܻ��K�Қ?�Ϋ#!�M�N���C���m�ް��*z��s��!���Ò!FI��� y&n�
�WV��w5	�ǺK���`/̰�䣬?������֗\S_�&/���Al(�����>/o�ݻG�����Z&%�'�jX\�NÉ|g;�ͷ���.9��:�Lև�v(}b�7N�������$yu�'��m������f��X9Ψy�<�j���%�a58������mO) ��ˬ�҉h�l�Z�ʇ�z��ܩ_˕F��s�,���\	L7w継�g4�%���	$a��z�Ə\���sT�]�6u{�"��n���%9Hn���[���ɩ#&3u���֪����6���|a��,k�}T/I��i�xe��^AO��|��>yT�dI�K�o��[����e�j#�}��S��mx��Z���J쏴c�[6ŝ�]q�&�H�l�I�����5h>���y+�V8��dB���D�*��ѿ�.�V���BPL��ث��]rW� ��������g,#w�Fvn׫5���l������Ri7�����21�.$����n��DXѕ�y���ߕ��7!Hg�T���κ$�����`����Z�5z�e�<�������B��wf� �(,6��r�~ ,b"Hfb ^���汸���!O2�0T�
QM���@��~;y"T�I����%�!��#=0'ƛ�|pc_oz�{o��Hc�����p�dl�[��`ni��f9���z��f^��7;�n�
e~
�X4c��k4hB����R�v�O۹�c�t��ꃈ̑�5�h��[��]~�+�D����+7O'��e{��.$���9F!����7��\�k���`d����@)8VF�q
���+�/4��c��#y�A3z���W�q0�C��v>�t5��AlƊ��s�Z��� �pܐ�!n��LKOn�*�L��CX3���DT�߷⯋<����/6H9!F�t�U��<�c)w����U�0ฏp����pt/`uI�~[so�,Lʬce,�{=;a_����_��xs�� &�p����rg��	�n�r����n�}�7�p?�^�e =F~e^��twj�/�S�Rzb$�\�"j\]h>*��`)�~
���-��z�D�E|��.�B�d ����wZ�l	Y�J�I4��uPy����Ә\P���J�+w���	A�\�Tɖ�7�y��w�"K8�Z�<�sb�_�$�$1��yH+M����b�c�|A:���Q8�	�RG�O���jQ�r�����>����:�dE8x�mϹ�d���%#)S�;J����D��DqP��ۉ{���;�4$!T�w,Fg������P�/��� �u�`�D��m�N0� N��/ި�����=IΏe�]�	�<?!���-�q�� �6 `8O���}L*.���ɩ������o����z���Le��(���\����*�WI��c'z�����R8���R��+�Ԁ=�U��<�T�
O�KKη�=��ڢZ�3(���쟄�~ �Fi�HEOE�{E��T ���P��c�w����<�@@7�\�}$oj�;ͳ�]�RZߑ��$��O����dJ��T#T�C�v�ܾ����� �H&�c6^7"6�LXEȈ���1�C��V���zꌾ�H���3`��
�%������MHY���lZWv�1�P��m�Y���B�o�s�"���03��"�b*�E�tYH�`��HZ,�	r�	v�Q?����	�����")��A��}q�$����ݞ4t� �����]{�+��r��c���:�����Z�g��p�߶��`f̣3�86}~qt�X��C3�ev��>Ga�;|L�����&+�]�i�L�p-н3�����Z+�j��/���?��R��������fZ�C�;+3�{C&+� C8�9�A@.��
��g豕���.�[�#ܷ"�Sn�{�Ν���2����	ů�F����ސ2��!��C&U1.|�fH\�!:��Uʈ+q�:<?�l��~�6���ʇPx��DR����B������0G24���~���y��U<.X���\�ƠA�1�n�wd*^��x�Է'�^25����H����x��>������a��k�ܣ���l�~��
2c�(==�gu����;-��G�T�Ԡ�`�}�&��.�XT��7Dg�%E���E�TYOy��?�У��U��XQ����-�4H�yMV�|D�aY] ]R2DӮ�:�ٛ��q/[7l���n���n??��Ir��Z��en*�f�/XF�Z� �T�&��(Qvt�	�l��S6�|�6�� x?���5V!m����+=�k��Gc&:�Z�DV�K���=47Z��������0[����Y����z�K��2�΀5�^t�\��];���$�~�x�=���j+������Bh�=��-�}Q�w�χ�^�K[��m��t��o�~�E���.�OJ_�M��v�|��kO��q��Á��GU�:dz뫝ND���.�/�U)��`��aV����D���@aZK��bC�\�	�����gZ�)�V8�|;\�X�A%�,�4�?���E�@�}���]YY��|��>��G�͡Ѽ�0�j{�#�]x��P�w#�G�q9=�8���c�I1�� g�@���R��1�FQ��o���=ƕ+/�^�����I/�2n��H����5Y��W���ԗ]Jpɔ��m�,K�xSo�F�(��q?"ig0"�N��T����n�Ν3Y�q=��m����e�S��N+�_��WK������r��
6�ywaL��L#�u�s�c�9�Q<>|	���>n]`�b��
����_��,��r t�V���S�բ@��S_��קLi,~D��*�����.�b�x0~�I5���4-�x���o;`�`�U8����sX,ݮRPE|v-�CU�1����{��� ��M��a�lP]������5r�هA%Xi5�B�3�K�}L[��0M�IS��d�����?0��JR�����f�u����~1�N]'��%��>T_��yb��~dN�%=|E<��t�#��A᳻���XJ2M���Q�0�������t��{�>���eÀ���$�Y��O�a@OV,-��'f��q4+�q��K��ɧ�z��$�Z���$B8��u����CԠ���i��
�N�5.zc���7�e_)���U=�@����|T�0<1���M�'�Y �]�d�kd-���[��k�)���w����_	V������#6���2�r3�6���T��[6��;���(������X�-z����䈉U�Fب�9-�4��'oh�����ߢ)���o����%�#�Y�}%�R+������Z�~�pA�~�C�O������s6f,�

z�6��Xq��5��F*�)Y�Lʂ���b7��y���Q����ީ
��֗i�YDo�7rI���PL$��PEfSKnq�=�]�u�3��͐��N��
���ͽ�`�o֜�Q f�Y�I���b���?��i�
Vzv��5<t7�t�q�M_�;J��0��(����B��7����7�t���,�Y����@���o�Պ�|}����}p�x׮��H��S7�KW�4�FTI����]\s|�CGy"!�e��>ϝkh�/[k��1����<�b�@��o���K´�d06����2��͖��Ӛme���\��b���M�Kd�X��r�n�$�q	���%C���?
`3��8YgA�\���WJ�`��V��Hd��@�)a.�`FC�ߣ�����K%�������F��"�*v*��5�K�st}P�MBmNYJ%=΢��GC�%G5���PXqhnj潤��GE����7�w-�R��_7c`�§K�(�C��gKJ�s߅ )�����oaooNħ����e
-o7�s���Q~��:��v��M6�Jb��X�[������	�A��2g�t���i��A&�(*@ȃL��k�u��5��w;5 ��|'��nǭXE#댷�gS�oc�B�R��s�P��Y�E��!wR���s��K{�ӫ�ŎN2T	9�&��E�?
Zw*L� ����}ڭ���o&�Cy����+�ۥ]/Dz������ds��7^h	��mR��H�H%���M@T3���u��1�{9��kӥ�m�^^�~�
]wA�Q �*�pi������]S�X��Ӈæ� D
�\�b�؝�ye8��a�ʪ�B�ؚO�m�P�t���yL�(�gZ��_қ���_S\^Xl�I�E荇'�$��� ���WGĐ%1H$`�?�T���G?��ڧ͞c��"���������n�V�//�|m�&��*C�s����d|H	I��&�.o�P�R���崤�1�=,�V�;s������G��d���K{��܇Ne�,�^�&��ۥ�f���Xv.)��
+��[��:��E�)~X�G
����r(?_B�3ޜ����ڬ� ��2ä3���]�g�]�;���eL�:7w}�BA$sO�V�@xђ����k�̏ 
:n��r���h�ќxOK��M��
G�Qr� ]�좖��bj��`���Y;!�P8��r��c؊���#�,7��=%`sFv�c��'�<�͏��cx��bP�[#��J�ǁ}����3ߊ>�>\K��K<k���dV���*��@�r�p�6qhh{`�.��O���jq��m3$X�9V�.�A���=9�ӊ.��.ة�{@T�ZZ㟏U������,��Q{0�_�M����bep[���^bO�� ?��h��7;7���۹8^*�� �O��iFl�p+fSl���M���c��c��] �3`!�nR��Q�ix� �^׵��c<׷j��v<������H���&XJ�Al��0ñόV��m��s��˂8�m#�>=�M�(��sP�*M��U:��:��`�z��?����YV�b8�Wi���׊��cw �6�2v�>
n������+�3a�������I��K���:-��� O��pD����P?-�ʶX��a6��Ž�3�j�o��{Ҋ��)���~1��?�?w$D�j�6��� w�,n4�,F"'#��i, S���r���-�ƇYn�!F�wwT��mNx����c)��i�kλ�I����&�TmSڋ��s�:k2(v�`�&����y�V��1��>���8V|�(�ؚ|�})m_@��B�E����Ǉb쓗`�JS@ �h�#D�WR����"@Q▜@�R,�
�z� p肟���H�,8-'H��������:��!],l-X�4�P#�<��Ii����'v[>ԋ>s��b�>34݋߼�x�-.��P$�[5}�(c^b	�p�?|��/{9�"H,�j銡��sS>N�Hl�	<c����t���F63I�qv�<l�{�p��~=|�DR���|�5��e�eK���b�F�-��`�B��IH������-�q!��!��c���P޽
�UԱ;�1{��X^?��|�ma�L�y-g$d�ʸI]��P����M+�1�X�kʞ֥!m+�S:�B��o4
�a�<�oG�������h�[O�IƠW��7�MAx#��������A�ey��Ȑ�*�3Q�
�ϩ�$9�'�U����h�w��,@)��#r��h,L�ì�����Ӣ�c>�=!6�Ο�p|3�+DN�P�(���ɷ
@��ܔ��z�5����I��fX'���Vb.�68�G`�Nh�Ë���-�jj��$/��'����u���H�&݌7��}^��uxwQ�tP�5e �����R��N�Pmy7���|uˌ�^�̠&���sf<0;4�#j�d��N)+IަGd�g}����U�q&8"\}�N���(^��D�6����B�m>��p]L ���tu�Q���2]-�%��7(�����.�'��k�*��R��@����X�sN�<knw	ǝ�G���k�y)��}Fzm_M���f�hQ��מ�0���
�����#>���;(�.[��Y\�����1������+���2=��D��� d��H!I����1�o�7c��#�ݫ�����gd��]~�p?]�Y�A�2�;^Y���)�R*�G�}�9 ��TӃ�u+(�Κ�eV�_%nY�2Cs{X��R�V|'y�}9���m�BϚ�%Ε���i����ȇ��#]���:6?�rj��]k�N����c�I���<\�s��b�ŴQfE-�<�PQ_$�XsB���G�a�\\S��tqi���]��4�sӢ /�s�#"�"��?�L%��e&�Gm�����E�E�=)���@�r�F�P!��@��ynҡ%AA���Z��0|�/`;?x�hݨ��C��j��z�Ɇs��eɊT*���Laӱ)?�g�Z�Ɖ�"�p
��pR& �4."���3���o����00{1,s>W���F�����;��JU~��i	�?�A}k'�h�a�E�3w�n!�M�[���'��m�����1�@�$wSI;J� C�ʦ<�D"����'���u{����#
�j͐��e���qd({�v�c�]fZ�u�6VW��qgϣ�R� ��O=��q7O6�������1(e�a��a���.`��^M|<,9��rrV<������K���6�-�����U�mE>;�>�/2�ʿ�Z�:���#��g����� �ͣ���qD��hR�^l'�2A�dU���v����;Ï��}	.Լ�K&R�s9���p�Ӈ��/�Zya��5�r�oL�8�*֧qq(�7z�t�uT�a����Og-IQ`Ś�^��%
�+��P�QCP�A��\�s�:,�3Ѱ�f4Z�,��$J�h���Z�Y<_	r@�s����q�Z@����q�C;A��ƻ�eoA�E�|ic���o,�ej�&パ�}(a%�r�>����`��%x>Bp�㳞�뉡r��$�'-V�O;����_7�`�G��Y�8bu���`k)��#�b������� k�=^�-*'~ K�a[���9��\��|B6T}?7��k�9�9ưZOH�.�=�D34����[�	�����B%� B�C����b�v�����\�]�Г���#D�]=���+�X���L6@@�>z��J�t�9��g��á��5�:6.��۰�������;n'8ɕm�P3��
��Z�{C
	 Ӻ���<(�cGg6�3����fɩ��Me��f�7�S@�D�6��Il�Ia���cPWW��CZ�f<������:#&�IW�ꠋ�7�x�{��S:=BV2͜�#�3,	+[��T�-��+{�sj�Tzh�]PQ��f� ]�d�D�'�����%|�!��=�r��o(~�|G�����.E��x�ʖ��C��I�����A�,�㥰���߾�փ�O0�4����
��[���ck*	���h'4{o�,�m����L�Ϣ�Q��-�9ړ����&��a�s~Ce#-�jdB�'���\�O�II2~a�H��H��L2�	d���I&1%u�d����d5E��#� �4�x)	А�?�)̰����,�]ϖ2�%q��)���F�>NW+�!G߶��\���`�;��LU��ʔ�?-��@���5�p���Zc��u���U�I����Je�ϕ�"6a�	+'=O�Y�	�K��0�i@��I�i�j�l"T�qqʭ<����&	�(U1Ơ��vnY���K�<�U[t��;х?�z�?���8��O����Ȓ!)
	�	�JzHbi���,6߼���- U�����IЌ`2H��B8�7�u���ԋ� \	Km�J0��jnŉ.�1��Ň'J�*	��at�g$"rU�DD����3�OS@�n�1(|���SU@ќHB�	*O�r��@a�6_�<�N=�@�����NJ�Թ�K�
ފ��z�d4I��D�[\{i)�y%p�h(�:�'�� h3�c!��(�T�881�_W�b�z79�{���E]�����G�2߅VKSā`;���nS��Rkj��A��>�i'ؿ�)�B��١���H%A
�9���a�-Ҧ#�)g'��j������K�ޙ����	#�Ѫ0%-��4���7%���e�b�|��t}2N�∵NT��r��*���V�!̓,���`ߡ�O;�b�U���G�I)�O�>�l�)�M|�~�7��d5�@f���@* ~X�G>Ao�PD���a�����=.@
�Fb�����K�cjӋ�;c��9%�ձ��hα��<՘#ڦ�S�%��b;Z7��}���Qf3ܥW-��L�W-�~A�6���&�:��*�K1�h@]A&vt'�q���o�*�@@U�:1��R꩛?-FF/���� � �}~��h�"G����d����+ԋ~��SJk��*ʩsB�HW�Ӌ�Qw�ZnJȆ��{��%h�8���>A( ����4S#C���3����eW(�[()�޷%FF��P���ܨ���9'�����ǀ�7= ?��{�Ր&�� �F��?l�� UQ"5!�^W�R�vaH\֙���?�_F�S`�A]کkZ]���Y�nB��ׅ:��?R�>��+�����N9�Z��N7U��C.C	�	�Lg2��յ��d1fɆ����?��R� f��?��� �K�~��9~�T�^T�ϵ��u���Z2W<�JA̷cZ��YX�+gE�.Z!���$�s8��Z��� �g���X6z��=vEU����y��Ŧv��ٹ��b[�(�L�_�[��`OO�򭙻�e�t]v���oh."��Ӭ�Πp#�+L��%=�4�!^-l��$�+l��X:�·�h{��!��9��s�
r�S��f���Z�b]�)��򊞒�3π�ܭ	���y7^R�x-gP��3t�1r�=�dF�T��o�U�l��Ԩ�s�KW�;(/f��X*�_��ʶ���Hlq(*w�n� `Y�1��C)���o-)��s[�]�t�Չ�=m�(���"��kX@���r�_�-��vC�Z6�ݰ� �+u���8���~��K�p��(v�]I��p��4�.�W�ftG_�=��#��Q�}b�MWG7�w���`Q�1�sGJ��=Z�ĭ�q�
��+��nqFWFƗ��`	�Q���SN�G���k�¹zX��WlX���y�r>;����_)3׍?ŧ	|V��##(���v[/.�J�����WM��
�#r���n �/-�e��y��/CQ j� s�%dBh
� n�|(<qm�1`�D5�I�s�	T��<!и��_�C�Uz�C���t�ga�UH�J �l���f;���K!*TS�Oy	�Vө;��g�h9�Ô���VRxWA�E��KȂ'�@�u0�3�18��t�=9�/�~���ۿ���IV���-/��� ��DP^�I<N?����^�j�1;�KI����&}���L����3��NyΕ�O���+�����[�q·�9Уǆ�.<�~,����_�w!��M�&J�·q�a�fE��4�m���^��dH� �V��
E��Ѧ�I^t�����Ƽ��8v�݉[��Ǣ4��CM�BF7������i{����KPUj8	>5Jz��}�S`��}������`��<�.å廙˒�b֦"nȔ��~��?�]� '�P��.�y��nE��M�C��P�ϴ�Ə�C�6���X�����d��É��-�����w�����>�SJ_l���\j�J7�����?�G���7�G��Xt�k�����uϏ�͟�a����;�����wH�$������UU�5՞�zO�[�$���a��I$��y�\1�=u� �#�c�O��U�Z��A��2&K
�^n�hD5��݋*<��ߦk��������V�f���-��U��yG#�֘x�V�Ǚ���/uX�(�E>���P�� n�_G��C��H H�\.eְ���%ٛЧ�!���� ���P~x��D�&����� :a|6�A�	��'��\:��W#�2���DF��\gJ�X6ix쐇��k�����6�:�@�Y����h�E`�o�7DZ�u�4���%��3��/x.�tI>��_<&��?��x2��F���]�a����L�vzm�20�:C����@D����_c_��Χv=�sdꗯ@)$��}�Lzw|�B��5��_�c5 Ȟ����D�.�D�j�3=3��[�Y�f�I;X����mp��@�h�V=�`�pĩJ��{ҷ�ݱ���x�	u���H�y(֯��8��߳Ű�<�d�j>�"�V;fD�9�v�`xj�n��iܔ�
��*XʺQ�z���cS���ts�yYG�/���Ѕ�pӋǶ��HvM:>Ňw9�8nŎR?�3Y�M��oDܨ����6��_��ʣTt��G�N�������^����XwTMR=�Ç�+��
��:���Z�n�b�썷�=����eT�����9��	���q���{4^hik�L[�c� -<.=C�(�L��ϴ�[��!h ��'�h�n���C�{�wD����n�y� �u�S���;��4L�J9�"G,��)���:�g��'�m�;�[N'Ɵ���*$N]J�_�fb�_3ёk-�H���Ut-wN�!��r^n�r�'��~�Zm��z���h�%;1���=إp�_�2Jg��T�b�,8��hD�J�����̑N�K*���  /������J2�D��ăm^�
����PUa��̅�I\�T�1NF��I�`�"C���(�E��C�T�	��A6�NA!}��gr���j�� �����|5�J8�ՠ�4��K-���w�/a0�"��p

�W���O�x\E�{�F��)^J�\v���-������Q���d*������ƴB��/F����qf�na�jA�;�rc���Y��9�k�C�sP�����!eջ�����^�\�D������i��!IoɈBզO��.�p�S��9Y�0�rgI3ͦS��0zE�f'ǃ��rp���s�wБi鴸>�&�l��Q��)pgj� �|��j!���|��D8��j�A6M%/`��N)O�B.�t��yU��S����S��5Go�� -v/���`P*c�@�Y��cȡT�Doވ}j��ӌ�e.ĭ5Ό�66���
�:�I���G�UC��ߝ��ֽ+*Ie9YCP|*�n��uPbG� �c�BfvdƓ�;�-��}N
.M�_�.Z�s"G�!�}���m3����~�ۑ�y���S����]�&9z��F���b��r"E�����[��94�Y2j�e�d��T����&��cu�1�)b���NG=��*��D�CFCL�����b�;�mz5S�f�g�rF���:2FN�aj|`"����2);�G����Xt�٠�5+"~L�s}��WJ�V^&�����ǔy���߰4Ǣ'��	�+5a�}� [�w�!����5(���b�Xv\�g�M\O�1��裳j`�J��Fr���VK��?�n�Q����5Г �>��q�n��~��.2���e��`2 )��.�ޝ�Q�w�Sg=������� ��˧R���>w2�NT��#�!� ,u�w���}��E���yƺɞ�*�n�$f�����j�U�-ʹ&�6uKV��81<�b� ��.�[���ʛ&oj��!��e.��ĳ
  /��)imL���S5�鑙�µ|�o��=΢4
V
mq:M.����Cm��B��a�'4���xx"5� ��K��PKF�����&��
eD$��*Q�=�(��2d��ɽ��U9� ��A�;�]
�U��l��+'�$J2>w}���,%6����j�f�/N����+�a�Fv�='��U��?dӤ�X����;P�ת��6�y����˿ �A/9~����X�U��7�_��1=m؟����3m@�(�f}���y�aX2A���q��Io��F�p��w�ˡ4>D����q�-TÁ̬cI8et�Mp�)�yH���&nM��I�����4vZ��\ӕ��0���r>;�ЇyS��;������:����>�E���77�Bh+�x����_�e�(�f>����Z���x>�r�[5�����@�Zdi�S�&���v���@�Ǘ����Ke0���G/�!���C�Y�0j�%��%Sqw��2���`9U[�t����O,)�$�}��]��5-���]�ʮ����
E�Q>�׿��	i�9ʵd9E��P�-6R���|Y5����]|���C��%��.��I|�e��X�y]�����D�2m"|��b�9���@�$�9|v�\s�Xiɐ�4� ��
��h���Ab�{��,~�NԢ�����^kK���0/B�u��Ϡ�
��#��qT�=YW�$�5�z��
�!Q���� V!�:t%�aB�Q�X%��<����8Du�O���:~����NG��!�>� ��������"5AE�p`�<���n��`��jt�L�52�A���R_���.Tׇ&��j�ĮM�Щ�|8D���U�����]Ϝ����&k/:��K��5��w�ܠ>�NU�#a*��(�3J�~����t�Xǥ���K��Z�:L$ �j���8L=�47Q��B(�6H�ѥgS��@��#�6��kE�>�ˢ�;�	���@���ex�	،��d���K���.0�0�::+����=�
�VxlpX��5"�=J&`���*]W�A����+>e礒���a��.)�>�Z��J�[P��Y��U��d]���9d)�b�z�p0��g��%}hv�?w��x�:�EV�򑙙4�z��>F2LA�lPbn>�y!����"I�j)n�$fK��G�O�(�`Ѓ�(au�˔���Q[h S���z8��Eh����v��fHМ@�4֏~k`ր}}��H��K�׋%W�[J�6�1�� t;V�=�&�Js��Մ9�0T�=6�l�#�k�J�y����o�?��u!��T��yQ%�x�s��[�^j6��}�T�M��e0X.�� �H�X��w_ �'�-"���j�d�ݸ�(�ൠ�O<�b��J*I����ٓ�Wث�tK�]4<ڄM��\oG��m7_&�ӿ�E(����q"����:��2���n��^R(��Vb˽1��l���t�Q�/�09��-u�����/�	�)k(��T=]���i�:鷻Y��w��l�}b^�
8v��e�c��
�������3�?�Y#�_/B��Ʃj�Y�L���D�@�*�l�YLӬ�4�`n��ˊ�#3^�Ŝ�����r�{�ڔ��Ϳp!��4�b$DJr]'�&M6_N�?��B�����ѩP�� v�9G�#�Vp�w�z�.�/��fg(�ڬ��\��b9Z����uS�Ԑ�o�YDla��׳���3��;e<�z�W}�?ud�x-��J��RE��s����N�`	�s��N�ȃ��ЪD
��b	��<~I� ���]�{pt
�1B���/˽�]�Ï��<��WTf�4���ν�M\�AFy"sV�1�ߦ���?��/�	ʃzb��m����2Z���SB��T"^/�v��y�����o]�T'���JU�2�9!��b'�x��px7S�v���	��s�Ҫ��^��u����Q��rX2
hv��lbu��N*�������(A�	F8�3���U�h��.R!B	5��,��e���p_5�h��H�71�	ϡ>z����)B�t����� ��vTf�\﫦�!/%0"��<Y=|/ݽ��1�i����<�d��ߺ�L{茠Ϙ�r�]�We�����ȩ�Aw����Hyۅեn��.P��H҂�ӬH"��s�t*��G2�Z=^���s y�y?�ݨ�*�U&�sD�����eA�ň7�s�,[k�4
p��`�8��A��į�X'���¥�ڇKBe
w�?}����?�/��@�]�Q\)����Q�L�N^����x�M�`i�vh�~���e���6�!s{=�(��h��uI��!��Hu�j�����-��M���E�G����1u�c�~^50����Լ%L�~�"Y�͛v���;:Kʼנ'_$"p��{����ĥ,�ʼC�����u^k0�4'b%��p'�uՆ���2�.B������\�̟�Ά�sc�YZd�[�X�A݌/�ۥΡ�Cˉ�&˕�q���Ja�4:�)�Õ ������Yx"�V�M�݁z��F�{�~&7պ����E��ؕ�2�8,2	��2��Nz(̓��]<�iqD�Hqfv����G�h&����K���
U)���"޿�E��2���J��gF8�����)"e5���䬘�#Z␠NϾ�/�H"�C�]ā��K��q7�m�#D��O'����R���j
�܀ e�L�n������$l��p^�JR�@w�ߒ��bH�M�Ҥ��Lc�酀����^r5���̼44w��?F�d��I��k"3Ȍ���EK�,��1�?����{����JUm�G�[g�;Tol�_M[Z#�� ��W���;� �iy�ݏ��7��:��sɾ�[�/�-��[�L�= �6�����l����`\��{�S!�ּ������)$��^�+�2 �.7}r�E���4Y��6�e�C��%�7�Vexm�-s*���*l���
{�����=�RG��W��t=��Z�X�ȶ�8Uƥ�꿅|jd"&6�0↊.�.*\����u�]jx�Ϋ�e[n`�O���o���R�b��oW�k0�|�׭x���mI��0���h܉�X�f�aB������<���B`��Cv
�������E�,�q��-�#�.��J�g���
�����cr��T=&���Sϔ��G�A����?�v���d _���+6�쫌!A��u��(�f4��	��P�w��+�-�>��u���Fd����S6�2�B|Pi�u���K��,fF�(xvh8l�60�u�i�N�YO��Y�����!�E
�'�c6�^u����#2b>2]Ԗ�*�o��}�3I�-���0B���'?�n&qX���~���$��9g(��:�2�Օ��42V8�#`jL��`x�e�d��.A^"*�ĝ�a,*�qƊ�4�3�mv�6k�~�F��r��������W���oh���d�|UnY��_D����p���ҿ�#!�V2��Q� ?ݤX��;��`�����߳���\W�
�dk��}sҦ�c��,׬���.�1[T��n��H�S>�=���Q,�Z�D�>��
m�7��O@���K;�L��a�
���k�D���OA���Ij����O���~� azsj������-��ˏM,��-�߫�����L4^��s���.��p�&J)iڬa�و�T�-E(\���6�˼$�#�>�".s��M�!$p*�mڬ�N��G���} �9>m_3�R�~X��4)���<J߭����?�Q��������nx�xW� ���*P��Ǐ7�W���	-=H�G�o�I0xTd��-1���;�I�9ܣ�0�!���H��n�X0�_�gc7I�+���y>xTᏺ2bv !�\�=3R���1�
�XW�E�p�E���$}��@"�'=���;O�sy#�fo����9��:mܙ����u6+ ����{m��6���Ɂ���������Sj2S^W��a��-Vt$#b�m�����'e���dG��6-��;\�=�G#�>I�*�3m|2(�Cr�9[�~]���_����uKՒ�-�QbK�������ӯB߱�]���?���Fx��ߎ�T�x��L8�x-g����4��v���!�Y]�6zP]nBmiF�d���:�2bG�2\���\�	�G�on��xy�c7�S��SӴK�KCv��������U/2���-I{�Q� gi7<�ɘ�uKo|��@�c�V��v�1�>�|�TE��B��F�k�<�W��q���/��gB}!]�G�X�~kCj�u�0~j�6�}���x����ux"]F�EE���%�\�y=�h�r�ͫ�I��f�5~�tR4������m�x�U.�6x�w��c�'U��<��D%O�b+�7?Vh�RlE����L~�<��<y��R��b��R   
��/�� ����9�$��g�    YZ