#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2723982784"
MD5="13fd90deaa900a2cf049327451b0fa52"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23004"
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
	echo Date of packaging: Tue Jun 22 19:44:40 -03 2021
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
�7zXZ  �ִF !   �X����Y�] �}��1Dd]����P�t�D�r	i�/���44�[�N��}0�X�{��p��sϼ�m"��A��hK�1��V�e�=��u}v5����*�������=�"&G�^z�+56�-T�f�hx��0�"_ex�E�!�}� ��?����9��b��>'�z��������#�v��x��1�f6�
��}�<W� ɚ��*��Ym�J�T	������3J8��i%2��Kn�f2������s�J��j�����b��>�S$>��r�zH�ų�"f��5�
X�$� �v�K2ࣱ�Y�#������g������y��Ob�l�c�3L?C�b�'1�e��L��q�l�b?<�������W�S�jr>'�3� �A�d�5��3u��}V�O��g��%���X~�]�_� �H�J�N��*���8d�F����b���w�?�?-Ep�S��1�ƃh��G��[�����YVk���)K��"��E���P%J�(��7�-Y�w������"t|�ʷ�M>��u�f�	�z�8]��/C8u��3P�R}4)��w������(D�#?w��Q>x<oRףʵ� XD(V_V˛;: �8���>�F�����A��Ӧ�&���Ơ���_D�R���8< _:��S:/��=�d���D��v.�¨;6�5n�w�ݺE�VB��,]�@��\c�=�#p{��2�d�'{��^�������ػ]I���|gأz�� �F�+7���&���P�j{��2�6��&y�g�4u��J�Ha��� ���!�&��3�G�|���[��˕�.�#�Ss�AdWX�dk?��o�s���� ��t)�DU��cB���O*&9���}���r����K�d0?M�Ti���E$W6�'�++�K��\�,��z�:���QK�8���D
�j|��k�����Z0�ྣ {�!�	�so49��(���zJCq�U�I��3�'�G�my�O���6v���)��E�ƣR½��;�VHmI'
��f�=���{yj���-H�\�%��X�&/�E���c�����2IC������kG�B,|��n��qP��uv/e�4f�E2QP2I�9�� �Aa�GK�gb���	cdޠ�r�cT#���gF��	.���9����>� ,�������͓�����gL#�������8�%�Oey�\Y5ܬ(!�x4,m甌#�c�]
���,#EM0k�l�XcM���Zf��S�EOiM\��Qzo�~2��a6(�<y�����2�S��SmMF��\�B��+���5` 5�Z�8��w�	�sHt'p�CL�mG_u�ik�tew��k���JS�>�G8�i�;Dݺb�~I����Q=�v<=�j���N��c��	^�`�J�.~i���O��寃gI�r"f��ԇp�cF_��pxe�`�Z* /=�]����۴��
;(Nn�������Z�}�4�A����ܔ���� ٴ(-��n��0�DЉ���� ����K�8��$�1ܗL�w^���O=Ŀ���P�x΋�z>�+pw�s�$�2�hn�
�",��Ϳn���f���T|��xx6I����}#y��יQ�� k0��RG�Ya�~���K=�KܻV����$�)���}w��� �M�55_�s�2'2RLE(����]��J4a~���r������	GqǶ�um	E��o���L�[�/��:�~D�O�հ����]�N�4��5򐡖��fg�xaGaB>(�6�mU	;bFr����YN�e�l���V�dqّ�yg���L�xĴ�a!Ղ�e�dvRV��BVY�"^tA��{�,�/3��hS���}5����O��wi{_���Me�92��isk3�_v�
��oD���ޚ�OR��:T>���"���=V�xB�ժ%/V�O��Q�z�K ,���1oϱ1"�=]hj���s����g�로2�V��Ȍ������Ǹ�P���i�(�yVs\�n��Mc����Z�8F�Sչ�Մ��F%��pEB�:���jHx"d�R��/ч���M�S�ݼ��ޮ�9ш��/H��v ��"�M>������)�{\ Ѽ�揨��_�t���P��V�$%\i�n�u+hL�!��[;j��,.��US߽��q��$����q�C�3A~I�yR�P�_�~A�oɚ�=E�oY�ưd"Lw��=� D܏d��l���P��\����ks���};-|���y��M|�)��{it6%�pA��ōt��
� 稣��l�'/��Х�O��d��OL��L�����G[���r0=�2�tr�k��Q�o[J����r"��`�Z��C''���^���MV8�|m˙-�=R4�q�E~%��E�L`��[X�)�QxͭrH}]��M'a<eoY�_�W��N	�*Pq)�onP�_R8͐��:'�?�ґەI�۷� e�֙@��N�v߼��F|`�	��Q�å8��E��[۶�!����-��1S����Y��~�^OM�f>>�ޙ���e]��h���j>WjF"����Q�De�"��ni���p�3oU��s:If1��g#n;�����?%jb����^ף�$z�`X���7��\
��8�Z*���Dr���|m?�H�Ό�mz>?E�.p���-R����6�@����ǜ3�:N����dj��}��c{@d���Ɨ�<3����q���f��03x���aԭ*��1�]vOm��C����ت[K[�4'y�t��q���Z�c	cl��;5[�8�O�y���d_Q�?�hkv�#o���<��$�S��"���~A8IW�\~D�N�&����Ȱ\�����E�����{^(h���8����^y� V�� �W?�h��>�ɱi�b�~C!^,����A.'���t2�j-��毌�(d`N���дx~z?"I4��`-�p��g߁��!2��L��L��Bm	l���'������٦��뉃,(��4$���B��V�unKNbS�Ȫ4%��ODJ(���ZA �
�j��E�>s+,zR}�Y�Mgf�C���s݇���������MN>n\��eФ�b���dj#���@$�w�N�t;��R��&W��c;�hZ3�-������3��9',
��gVnJt$
��l��&�9�����`����h4���S/�_�����֒��	I�P}u�rR�SN0p#d`o��I�H �lh��<���|[w�`� +7�ݧjOZ&n<�NS�0�Eذ�cۭپ_�7��xݤ>?�_��c�K�:	�i�<h�-��Y�J�H,~��e�[��pǋ�"��Qwr-�)���>�pW�;�)��o����nwX�$3������3��b�����/~�.me�����~�-՛��$O݄��^��؉�������+�[�O=�v�^����T��r/r���.띰M��p�ҌR�C�_�/yr��v�:�[�X��Y:~Y��"�ȳ��T���F��n�Vp��'�I.���d�س��J#a	�v�t~����
Xѓ<3b��������s�� N��K'[]&8���>Ĳ�����d������Ŋ� <B���|5&��I"���uE��o��~rL�t��t|I�W�w�=���%�������xx���l��f��&�d\���k%ڏƦo��k��UռX=���յ7��=�(����T����N����C����4��I`�H��!�bs瀮�F���_>�be]� �l`\Fė§�#�8�� b_^�%� �r�ڛ��nF �o�¶�c�F�=mza��mz�K��o��l=L�?�Z�e��V��Z�^�vS�ª�ȗ����Ґ���S�7*��ȣ����t�����o �_�ǖYx�����	m?<�� Fx��)Db)9������A�-Y]�F�$�{���� [�V
�j
�'Pe�zWf�<�0?U�U�Ċ�%z�t8&���/�^
?�wRm��R�$��㥯~`�� S���n��ΎY�ԅ@�����%�~L����>�1�h�.K.r��\�0�/���:��9��M	���8ah�3��fI-�������?Ztg���d\��0-��MnBS��!i��:���%�����`���V��������7�1۰NQ�=���%�E��0�,[��chw�WȞ�.xãG(Y�u��n��kd�[N�Ls�2�+E3�3�l�}��7RO;ϵ�Q��l�V3��򓂢� ��7���Bj:ʹq�������(龛�0�E@�����򒲮�m������vⓢ�����ѥ{�1�@4<3��G��!}�ӻ3�B����~�!ra�yB��"N��䵝3r�R�����.�A��)����!�:��u^��AID��y�����L��p�.e�*�.\OȢ���Ľ�q*�5�एe��{��G�D���f�H�hA$��X;p�q�<H�r��(���ʰ0"*�=��]����9�9Yk5��G{�$,�-�����Z�!#֭P��ZZ�k�W���i�$����lv���aw�8�*X��&�CL_d,cU��65�^��#���ۢ-Չ�ؐ��G~0�� q!��}��U����ǃ�kS�-1�@E�f;j� ��[-Yb���_��@c�@q�5�H!��tȁ��#�ݷ����]eJn>S^ym��,B]b�E�
d�Ϋ���߸��f]eKE�0�9�Z��ic��k7�9K��}��΄SR1�XT�N��N�;�*M�8��v���G��I��U�/��;@��������/�9A�4e���R��*y&��J��%��kd� !�#y�}�E��W����zr�r6�q�"n�Ϝ�0�,np\;��^����=��ъ����y8�~��7%Ŧ[�Nٛ�
�C__�A��v���}ԁ�3�RP]!
�W�o���@��2�2W���X6���D��L����Xv{�8lܘ����AYZ�i��{�BxE�����WW���[��7��]���\ы��Ln��ef��4��m)�ȧ��E�>�H9i _"o3e$-��a]�3��aXK,L�����T�6{i���CQ�Q+w�-E���5���2��z�в�H����_ל ,ES��G�ް�� �
�a<��2�ц1�'C��!�c�2�Ž2B� �f���P��4�GK�X1��C٩��s`��eh]a�?ѐ?"Qd���Oz᣾�1��=&��!`F�
kܽr�փ>fQ#M
0���ل���y�`8'�1�9�~�V�8<��k��]v�� ��ri����@rZ����4~�	��P~j�v������|���U��tp�X��^�'Wa�g���=��	{�Q��Ի�F�H�R �v���r_�1@�T��g�=�m�I�Rqӥě��-2�8����~�o��$+�Ei�M�1����
�\���ZB��������̀�2T4֧ɜ������\�g,�3��e̼�,����!4�I��C���^�ݦ1�vL�@m��wk`&��Y��I��؂�O5���~Y��O�k	�|V��𙪇�Ӻ����m&4��>��+�ό.N���ӈ3�R���<$�+4!ͩ����B�bf����c�W��%�'�-z\�$=}��[��7������c1_��7+���YZwy~�}KD�w�.5V�@��>�'��Ʌ��ހ� ��)[��١�i����� sׁ"jiD��W�'1xwW-��;ߒ��ƖS��5�㌁U���N���]�[[��;~��n�}ci�mzT۞^�O_����#A�q�,���"ɯ��e�E+Ve^�S�+��@�@v��}�앭#d̀�	v�a,���;��RB�Ijh��ť-�;2C��*[Hx�6����+��l�d���xE ����ު���A��u%�9�&����\{��08�� _.�7,;,�H:Ӏ�hp��<�f����֘8�n\��y[{�l4��;s�KUҰY��%��	2�,����
���jT}���뻜KF�/FŠ�|�TF&t�~5�)*BD���X���uq���j�Yp{�snXVf�;�-�_��k����^M/e_fu�;^zR�C�ʳ�S7֖d\��&���G[���L�_�(t��t��Fh����0J��AD�%��oF�+Y(a<%�^و��N����;��v�i�m��<�A�4�����e�WG���B�"�l�_�q��e�y#-����w(��Q��R�w�b�/OA>���s�p�;��NBp���P U�v;G|��Љ+�pH�~է?��y�ro���=����v��N�Y�州�����.��JЭ:F`bA3���)�-�ӂ����T�������%)c�4-�U?�k�u��e%���^0�*����&sl^aH�g$4�׬�k�Ru����KƆc6�,vO�ޮu���b�c�22��Kۆ�����!a���)4'�-�g�X�za�;?͓6%��CD1�Ry���=��,&���_*n��
�;����S��
i
�pgU��Di@sR���)t��cS��m&VKG ֍�nr�;�ӻv ���ܥE�C��o��>FEL��b����M���(z�[�NXq�B�n�GV���^k��V ��G�Ȅ}#��Hf1�s� ��z!)�&��������>�J��=%$����g!@��N�?�x�p
S����ټ�c��7�_��귗�$o�tm�G���×W¦���Z��/3gΰ眬�3I/6���x�/Q�3\#�6�N�
��:�?2\��Q��:��"8`j ���ĸ�VO�`�L�Fz��ɆL����G���d��%V�̼ȓ�31���Y�j��C�������� �&%6H���ȗrډ}�����>�:EO�7!��V-��D�!EEX��mq�ȇ.7��Q��+t�D�#�����=��]��~� �y�4���Q�^ׄ�+H4Eҍt�X?�BO��f�kG�,9T ��i����>gP,�L3U��Lh圅�3KLq�A����n%��O��Օb��*�ؔr�Ѳ�Q�Y�b��>��+6���<v��VJоW�����V͋��\�ĳ����j5tw$��iB�/#=�m^8Y�ۊ�;��Y"@�t�S#���[��1Τf����������J1rT�+�2� ��Mg�j~��̪��!5Sbd`���茜+Ǽ�ܧ3S򅋯���A��Gv��<�C�C�Zk��=��� i��s~2s	�Jh���|L�쬗&�'�|#4,�O���c�Y=]�s��Hv����nR�	��S$���u�ذ =����^wҖQ��i�x*'>��8��$X�q�!û���Js���
g��%0*ʫ��gl�6������#�$�F��j�'�y�i}����:q��?=
x��.g¿�
l��עۉ��ى5��> V?��a5e��`.�	�y@B�K�cH���*.q�TO���9bT���d�tUj�ҍN;��&YT|m�u�M���
���he�>�+���qn����,]�ř�;�ɪ�+^�ڹD+fw"�
��E9!{�1�8bef'�>�ۭe�^]���B��g����{w(L��{����!{�bU�F�>��!� gF{��������S�%*�@�	/��uz�X�����&��z y����@
���9ա�n��/����S��=����5w���?f�n�F����<�K�w��������wj@�Kd��рk�䳗H��K~�%n� i���s�H��V`� �`�T4@�=���I�H�R����0��	z��6�S��K,�%`_�ڰ����un��6"n��k�P��ϵ�����4�1��E�O��Y�����gԦܶ��$C�$����9�u���pȘ<����W�-�z��Mam.� 6P�L��KO���q�{nu#:�z�ʇNf��Kq�˗�3�M�k�r�1�Z���J��+�_V /@�N��W�~˥����>��%�ʜ>y�_3E�.ѩ-b�߆V)=vxv�!�5�t����U��U��p;�f��	�����e|Jɟ�Ʃ`@>��1��S��O1�ܠ��N�W�־F�0�Ϝ	̌�j�`h� ��-����I���W*���yig�I�I�I�Y��U�(Fl�$k�����ԤT�67�T��@.��VF={�5;��#�CQu�ݰ��ޮ8���"�H�2*��� c�(�W�K��ېMD_�Z�؞Os߂N����+;g)=�&e�@ɡ��:�k$�aC���%R^8gP�$�d��$���G��H�˚�����'������4�����r\�v�U�����z9Uz�@8�G� au��Z �
�]�o~ s F�}@�����l;11�t��o�V�'��	!&�5��,�½�������{�m@6s^�4=K�ݿc)䔼tTY��Ō�С��O_\��mzAyy�Z����.�d?��P����s�;��W�5y�K��?03]�c�5�G��Z�?M��oI$�r[����r�dXQ��(/\.[�R����u��n�f�_��/�X��;��A�,r@'��ڱ��F[�'�T���8A��D�`i;���r=tQ9
P�H_�P%7T��?vV�]7�*ݍ$ᒰ5뒆@-�k?��R�GV���ƹ'X.)O-��Z�CT�pq̍'#RU���yPȱC�c�# �:��	�j���ex����xeW����5��Z��e,�x*�D�k�E��=~~	-A[�h.��K%:Nj�5�5�>�ف����f��	S��]`�"��Vc��-��r�<\�0��S��%�qS��g�����ۮ�}�֕m�Yc�u�j�����xA.b0�sF�fI�����ҷ["��Yc��Ei�tC7�tNh;\�/���4!#�]j�_U�1��g��G)�ܸ�\K���	��	8�$�SD��Ft��Ǥ2I����c�b�,�� ::��5�kY^�k�����m�+E��^2�ڥߔv	s��O�s�	Y�gv���Uڿ�f�8���.mȖ��Г���)��)$we�ҩE�BE����5��,X��O0�]�B��Q��-�GzK�U�dً���R&�3�:Ƨ��2����>��4��h,L=�6��ݴf���..�&�*�F�����z�ufc���Z��4hȔ�(�ߝ�9 �M���,g!�<��D�ǌ�k�����"e�1�4�&�떐}HUϠ�9w>LZ�W굥7���o�_�S�����E��b9��k�wF�c�\�<;�Ʌ��1��Z6��-%����
����d����(S�T$�R	:E�}�0Nمh}a#�^�4�T�0�dJ�������H��A̵X,��Χ��L+[�E�-ʹ�v��3�[��m��C��ڬ"���c�7��`�(ߍ�9�L��>��ߵR�ڇfMpG��;KF��x�4W��Ru��y�pu��:�ﭡU���+!IMKm������(t�P�ޮ�[y#"F�WDR�g�1����_h������BD�����{'��r�6���f��X	IZ�[UK�$��#��7:� 6�au͓��rh�sP��NztIt��lW7�F�S�h����Ȕ�f�������*��s�d������/�?�H�un�ʋ*\������9�R2��Oobi�Eh��\͗�͊�<�1��̡z���7��GBZ{��jY�7*��/8����/��i]$�g����0J��)�a惿�z�Hȧ�C���٫(�wPTxi��u�|���H���?��9q�5X�a�Yw�]m���U}�{�d��66���9a��g�Q���-`��:G)�B�jqN�����J�(!����"��4C�D�e��}���+�r�E��&�p�x{H�}ׅK�F��W�gڛ�����2|�җ&�W��CP���ep@�N�}�r�ڠ�4 �Vç^i��7�n�w��gcT?��R�(��Lj������H�l9�؅�$�����������:�>=
����wI[j���x����xO��A8�$�n��$-S��zj/dF� �������W�62vg��X����<�?/w��+
wT9��:��<_k}�p����]�f��?M�I�(�"`��K�a^"�8o�F�:i�	���/���b�_�NU.Vk��2��A(�C`E�Z�#yb�f�v!�=A�>��-��)�y%p$>�Ԁk�K�S�t�#��5�Z�`��x�[�87,Ua3��{�(i+��j�U�dt�_�=�N�ֈ�>,.��_�g.�_I�����k���̇rq�<���e�B�c�t��#թ��M]�rQ���l����� F\F�DR�����^����W���8�2��-�~���[��ͧ�!���{J�&�z�K!tM�Ka���x/D��]�L`���jq�� ��gY{���T~Upiж/�v1��e��r����������s	�����
)ga�0wf�Sk�����]�k�ɷ9%Y%}E�WfV6 /�;�#���x(�L�y ���>���C�n��)3�F�JY��w�v�h��$Ń�G^�w����!�ƭ��R^^{��D?��8�㩶���!�\p��`EJ:N� ��v���繕����e�_���$�k�u�;-ε�zmgq��TƧ�gD/.q�����T��C9e�,hϦ��{�vCb��=��A��E.6a�:��{�?y���T0Pު��4l�:r���K������#���:u}��Q�"Ԉ���/�C��m��s�PA{��>K5J��9%�[��HHY�=����<��֥�ھ\������6(=zQ��R��<,�5S�lV��"OV�l�-V���I�]CV�q�D��$"����E߽�KE؀Ô�cZ��"Q�-T2Q��%�HZ�ܻ�����Z']�hI������c"
�Ϝ�V䀣X�FU$�5�2��ŕ�F��n協��AX痶���<c�D�I�*g{�ZD��>g��c�S�v���_���3r�,�����$������i_�s%~E(_ r�X.�pj�P�����uMf�|k���ſqTt�G�M搖���pa}��4,�,���9������Fg�2؍�ѯ��P�P�����. �O�l&�����4s�Ӡտb72���8�\�����\&��co6Q �a�ș�y����DS0@�Yz_hh1�]��V�>��v��S�k�5F��֋��l�h�W�%��S>��<��B	��m��=�oY���2���n�٥I"�L>�B�.A�[&��xm��D�ĩe�P��}rH1�A�8眞Tvdd1�V��9SPX�h�g	�XL!�����Ȼ��p�P����{�;�srPO�`v
<D�������8��ꇻ�L�0�疎G��5M��?t�9��D�E��f�n]�ϋ<4o�Sr�Eb"ʚ�&��� @GXi����PU/(��(�E'k�#�nB	�ʆK|��_��S?Ot8��=H�v{���7N�s>�o�/��@�uJ��N7��\��?�&X rO1}�R!o�˰ɍ��Wr�~� ��j�`TZ�C���cl
��j��Z��1����69�jv�I��A��ڮ(��p!�A"!���H ;�\Y����p>���8�H|��|#� �1Iw�0&d��e����fyڸ�Z�G;����{���,tp��(���aL% ��(���0o�2*�$�x��A7���W{%��ֳ}��A�:��jēyj�x�a�8w;��I^��͘�Z.�XzRR1���!���V������n\E�ݠF�T����E��V���$�g�͍��� 䫰.���:ʺRhϺa9��ޱV[��&ّ�L����+Lt��p,�}�1@�`���6Ci�6��3�F>�VI���cCu�����;�Ǆ�	�9����R"&ϤI����������P�>�^�UDI�@4y�&��9\S�ʩ2]��7�.��fR����C��$�d�z��$,�ψ�L�2�&s&#�Y��~���m�+�i�/�*� �Ϻ �bL	�%��@FʥG�
�R���.����L�)��y�7�,&�����$1��n�lP�L���W�I��.�t-��.���/j��KM�C*�gV@#{uwG�JXKQj%X�X*�R�<
6��������1e���{�t̾��ר��(��u,B�A�2'bZm�{Kj���	7�;���Z�B��i�/�?��!��?o�C��D\&,��XL_U&��`�z�tV���?�eO<o>����--qg������T%6����n{�s�8|�q'����~�B�^[��6DX�'�/=̘���͐h-K�βO�7CmOoGd�~�V�����zQ���Br��ғ��M6�z� �X
3[�%�G!�۪��%v�s�F���6�u*���.�0��c��V�*9G��M�Yq�%��^�b��9�2`��y8b��-d�����vJ����[�L�JT��~�"<�����0�n�j�	Ym���<���p��o�_��r���-~�r�m�1����%����Au�FʨL�S
4��;6{D&�l �w�2������"�l5g����*@Q�rd�Ӱ�$Т�`0M	4;����\�!�L�;�6H&�şi.2���Z:��Ia��2����?R��̤RC^/�Zt�+V��]*�����E�^E[@�K�+c�mcwȇ����Tm0'�+�D�����z�C�mO��E74���F'u-a�ҝ�v�U��JǜϪC|���})�l��7^$ű�Q���䫗�M͇�o�+U�{�F��C�O����ӯ�䏸C�j�.�R/.��۶�k�LAFl���h�LbPT�E*<���r���w��S�½�T7y�݉Loii����y�!=B��s6G>�+bzepڌ�,�s���a��J�J�u!��w��r�f��>X�P���E@��Ōb�zvu��2������9�����VR;�\������ަ_���^D|��u�fz��y��&���T�"��Np����&=���i1�)��h���P���0�H���׏�W�$��y=�[P~��٣~����ߘ'm�%��Ry T`~H����_<�f@F��0,WKkV 0�k���.�Ml��N�>J��$ �L�{Y�m^�7�໏�w�1�`=S��o�=2�e����v�Ɔ�<�y����+ӑ	g�K�����WBe���S�0�_��`�M'���}.q���&�1{��<�dR��d��L0�q��(�5Q���Oܥ�z��O�ox^]cT��.{��1����{��B����څ�J�k�uL�P��W�2�V\��)�ZN�ʶ�7M`��ᤲ�;7��C��ຑ��wC��1�LJۺ9۲���߲�S�u9�3:�f�Ԩ����,#�:��H����Q�@�:y�}E�3ql?�(d6�F�i��ȶ�M���K�f֊F�w�Jgq6���>t�4�W�P�x$�Ŝ_����v� ����p�����e�"*{kR�trLԧQ�S��2��l�˶~5�{����,�]�pN�08)���
�@|px�`l0h��H�+�&���?� �KM��L�N�7��&�ذm�ݕ8e���'��֏(˒��X�d���������䉥x�l���zŶ}tA���,�0�|Ԫ.�����JG���yˬ�(���4�9��X[y�*�E<�~����2�Ѹ��w[q\e�/���/"�= ���y��5�I�XC�_�/̈́��\#���z�Q�_���)��3V<�O�fl��[f7|�3�s#���Syb8� �6���_���u��ᅺ�V�������n�'J�����\
���Dz��͏���i,�,�0��:�_�8�_V��/FoאO�(��w@,�|���]F�P7�U���:���� cVC��y�Qa���8���[�	�!Եmuk�9�)/E�WUh�.��(��_�%��M!���F*����WdP����j�x���r�®�%��)s��s�]f�1��LBb�!ۑ6p����Xn߉$d_��G�a� ��d�U��ٛ]�,9V	=ɑd�g����;��F�D2?�m�����|QY��d=TF	���+9}bU���۲P�g�42�)B�b����a�C2g����}�[D�	�����a���b�J�I	��nnS�<q4�p��V�*�����[�X)��6���RT* n�g��f�U�[L��$���5�ek��s`5Pʅ���,���������fU4Mpt㪑/�-���_{ʎ�o?�B� �E>�ъ���ð��o֣�J9b����"ÿ�NAX1���3O�S�T	�?�Z,L�@�����_�	�{�s�o;�?^-׋��h�`��B	J��S����_�$�#�c������ay�Eu�r&H��rc�8B���ǔ)熛=��ԃ� �dv�o�p��OG��W!��Ϳ���yd�s�%gG숔2�Y�H~+v��4�>%?�E������ �N��:�n;�������H�.x��'�+��H�q��*N�G�p�4?��~���Rq7��'*+�y�����2���|R�*��Q8�kt}��n�67����؋֜�����k�xQ�B״K�]Xa��K�=է���H�3��el�y�g����f��W��!&O�����e��y:@�4��p���=$f�y�2�f�~�U�w�sMB�'8\���G^#�r�aA0})������j�jl�"�_5����Rp�]N���=?kWRpx��E��(�$��E+������U�Q��/�
6
�3�w������e��Y<�23���5�K����*-x���߹ЊE�S�،y1�G��6O�N���ஔ�<����^��*�f�G�1��ll�1�4S^��t9�ݦC[�j~�O]��o�5�*[�Z��{_�ɴ�*+C��c)�zt�7��x�ǎ�n'=�ܤ?�8�:WK;�'а�-l{�D��V�<P���vYh���+ I���V𜇁�2��Ißt>�l���b��0�nG03"�����V�퇵*�ѽ����<~�*ך�7����<��I"���g���DҞ�9�:�Z�𒌁�����𞶝�M����q��d�(�!�'���Q}h�鷃�o0�%��ޚg��ˉZL�L��v�lz��Ȝ��,��j˺)���s�S?;�{��(Mu����K]$�y�x��Q�D��&?X�_{�ܐ�H��ۢĀ��~�K������Qw.�s��λ�O������`�)�!eHo:����.mg���`y��<��Բ��MQՏ��;Y�B��h{�GH!�=�P�@���ۂ�	C� Dњ�RQ9r���)�J��c�sO��l��溶i����W"�B�_��<��4���w���&���K!Q`�j@�;���OېZ��a�d�V�AQR�;���	�PDܷO�F�7��ƾ�e&�xS �z���t��㈠O۲0��ud�w
���.^*�j�s�2�a#=�OuD��V�ŏX��:Jy�l�3D0��q��3f���B�ǣc��awշH{~�s�1���{3Uj@i�O�ML���Ј���Q��Ϻ��ٗ�ϒ��T#��R�$uиz�?� �UWZO_-%���[�$M�s/H��T���!.jp�>��ƌ�)����D�G>��WY�;9�+dS��k��{�N���&:}�n��]d�+��	g��=���,���cit@4a�����/���j;/��7H�E�Xd|��h��X.��H�8�����4�c�;&��B�:B�Awu�����ʤ�Z��
�)�y���"��:�0��Y�|��lr�)T����=cMH����o[е��4U�8���������)��\�O,���vL�P
zձBM����HK竐-�+x㯑�yaڂ�&�㖼�>i�j�iG��g������8D}���p姮Erc%h�d��T�+�72_�*k�]��Î�N�	�ΟT��/� ����H�BS�I��S���t�P�=S���O�ֆ	����ቒ�\�֧!��0�qų�r�5�<����Fh�~�AÊ�g���_ӑ��ld X���|���`��uFƹ-v��xE�S|R3����(�	�$�n�R[	��K��@�I�*�RiK�f��L����d.��@��0ʵ95�M�2�I�V�#�2�Ɏn�=���QI��pO{S�&nD9p.��|�l�/����H�oH��l��P�@7Ek"d�_&����ı�w��G�xqY�x�U����!��1(���>�_#���w��t3��&��>ʱ���g��m�� ��0�S�f��xij�S,Q�ˊ�E`�zR2wPo�m+z�����J���@D1��(=G���X;�}�>$0�������\zTyl�D6-݈u��{eh#�&�R.5vb�J�����Ϯ ���7QPP%u�x��+��p��T���G��WN=%�ŝ�-����WO����S`���z��:k
�|����Njp�����W�p�T���%�DCխ�ѨC��R���]�B�X���Ch�z��EwX�05�(���e7woH�G��ǣ׺�w#�ؐ��O:/���=3$6yk�t7:T�(�m�Uxp��Y(�� �#�wo"������
V��?a����d����I�'�:�-#wTND�Α���l_�a�刃�n��:8��H����9fs+3Ժ�hy�{�ھeOpf�量[�:��N�8Io��2#����~^�� ƨT#L	n���{��^��[�g-m�*ѼM�����cѷg�,���N�)�]�y5JB�^:�zje�)�Y
����:�ѧ��M�|8y��VCރU�	��W�ϐ{�xg  O:7�(�X��6�$ݩ�l*��+�l�?�$�K��Q�e��=��?s��Qw�Y�u�=����Q5}�����R8��!@=\��3��;�x�O�� �X�9��&s\om�?��b)|����fg��	a��;�GJ]�C�|�ڞ!�C�iכ�+���G����R��k��ϭ�i��p3e8r�r��*b��@H"���=C��3�Hrj�Q����X����M锟A:��;�֚[�zP{@�ꮑ��+s#��Ƈ�}=�6U5ӹ�G&��DJJ6g����g`��z�Bgl�ż<��7���*�#�k`E���W��)w�M�ѻB����Sm *V�o	�*%"Ŧ�m-x�3����|=�G����?S�z�}�R�W)!\5S&-){W�/�d���X��"fY���}^|K����Z˳X9�_�h�;d���+uЊ�N�J�\u+�Mc~��ow���z|�.��p(��h1^+�;�(��l�r��ʃSa�슸���+7j�+ǯV3����	�ÈXY��0R=��~Kh=iգ���$F^e�u_���&o�_��֌P/�i��gC��uX����}U&}smZ;K]���J?OX�o��G�����^ՠ"&2����-t�j�jt��<MpZ�#7�U��}I��*��g3z����&7!���W��sV��H��i�����0���l{��@,he����Aj8>?��z/֝������D?�[_��Uw޹n,��ǍK.42I���<�x�B�Y�u
��?N�$�Ϊ��]���`�h���+OO�r.9�T]m�`ʝ�.���,�zfW��)�굅�`�H0H���7eHq�s��/)�( �7ϻ�<�
� �/��>�T�$+WG>���HC�K��Hu>�lJ��Q���{5u�S_�amP/�)�#�JH�Gé���g�����k�ov7zr���t�2/�"�:�,���=�%�c�ԉ������"=��
���	u�Z�1��D2������+1���Qi+��"8~;Fc�6OVФ3O�' �!��W9LeNs��#��g�G��!�x�:UW��$�	�l˖G�΅����#��4�	~�g�=�g�;��C:Pw֍�+�<��[napi&�zԼ�a>���8���C�t��0�M�T�>���C;UU,����K���A"�6�~d�d��.�'�>�oX�K�l�(+�S��{ʽx=�:7��旵�X��-O����N����ʺ
8���ȥ�� �����i��ĳ�<��Њ�	�wI������R.{uv�?N�"C/Y���J���P�[�I-�l��:*Hq���I�c�G�[j�dJ��_V/��Q����[�U*Q���)�����w(��Ѳ�7������;�|�u�DL�5�v�mC��J  5�)�V�R�������Q8~�;����	�Y�a�����v�dkT�#&����?�Cf92SNH$m�o�Z+A�_���6�����~Ks�)�I�W2^[C��;�s���N��^���=�.L�Q醂�/�i	��vW<��YO���4ß*�*�X��V����3�:-6��9mӄ*:����Y`K��U�(�<ٮ��2�^�$�\�Ո����P�
|�m|4¶4���θ-���B�u�B6���iǃ+_�R#h��R>��'n��=a�ejJ�xZ.�T�8�3�<_�H"Q����P
���~�D��
V�:��~~��Џ�>
�M��d�Ok��:�8���%�_� �^���z�|j����F(�`(�X|�+PL=KY?n�MuFKx�2P]�d�'���	���CyY2s_!�!/�i��Ӧ}��A�,�5�N�U�q�J��O�V�}�?�������8ʳ@�M5��;#�m	]ώ�;AܗВ��<#:f8��?n7ǳ~��ʚ}h�J�����G�[�Fe�Z8y�v	4E� j�l�l���> 
b ъ���?�Ҍ<����r*,��9k?��Q������X(^%�Z1u����fVe0�j֝6�B�bYkr��ל�I� �H�7��� M�
��Q�����N��"�[;!)(v�bHPb[y/E��;Qj�������Wu���}v�ƀhI��R�De�ض{�I���?X���6���+��cLH��>:���m$�1��I`��n�9)Y���x&��ѣo�S����;:Ӽg���:�/M��	-�A�RG��g�Sp@
�����1?Q!�fN����7��8���+��h��S4�aÈ�/њ���,5�,G9k��BGޣ��y�Y�e�	���?��*c��G���/5U��2�q�{}���1��0�j��[�97�	M���R�G��)��zX��Ňi�zy��+:am�(d�l���_M���X7�Պ��$�����P[���(���8ׄ��{#�a����'_g�pvc.OU�n��֠�d�j�_������&azI�vX� ��1�Z�l���_M`��y	1�Rq~�k��IJ{o��r�9��q5:���ø?r�IL"z��xV�Eyt���1��C�]��Dݧ ���ݻ�E�����_���_���{�mJqqG�* '��?�=`�u�8/=�h	�P��y/��-2�˞B�����M�<��{���4�o�o��5�L�c��p�LF65U%
�_�̃M9�́;�O��@=,��G�m�3���bw	�^l�?� �g����5�c$}���,��ΉD�	�>ƿ��:�� �I�Ŵ����1�=w=-*;9J!8�q��P�}�t����ibJ�%Ƚd��o��NŐnήCG

�R�kQ��=��z$S�93�~��Q*-��3'����3���YY������v�O�%-ߠ*&`ҡ�V�����MW�*nM�>�q,���u8�hW��P���P����z�����zc�Z ��|���g��*� �`�,%�q�|혧�%��j��:4�;A�����,�O�|�{� �dH ��I�;���T�h��=�k��e�k݄:�������	���y
�&= ���Ⱦ�#�@]�Q���G�
�&��uV槾��DQ�q*�̎{���R&c������<MA�b��x�R6V�z'0�uc��φ5C�8(ݎ����d}ҟڋ%�Ң����s�����ǣ�Sx!���4� #���D!k�ө{�Z�|^��O%�i�˫`�{�l����/^d���r�wy���p]��л,J-�R�Û�����PCz(�:�	lܲ�3���^��>Ձ�Vʡ������gNt����u\�GN��x�'�d\����\@ߥ�I�׶O6�#q?��[1ns�><;����V�K��+�N�!��(�s���<-��'X�/+�7�p��P.c���J[�����j�1,�����������|�b&�F��sZ�FK���Q������dS����?<tڇ>Y4���<Mk�y��^�A� %�M���v/�*��ӳ֕G��T�z�[y�8� ���SD>�K*�V4�u}R8����_��.�]Z{q�}��9��S�?���]U@&Ɵ��]E�@��]�r��cv:��^��<�R���y@�*�l�P)<K;��u�4Hs�����x[������I���9�WJ�桎�j|�M7n��8SwSy���r�W�N\�P�wi�?��Spp�&ȹ�V��l�8���{H"�}��%zT��4c��a�H��ڧF��l`�{��O^���$Ex�o�eZJ� �?�3��#^s�ӆ�f=�(!�j�A�e+��A P|��n�;�+�$�P�+p]s�@�Z*��WŪP=O�k���e�@�.�-�Ձh]����Vx#-�Y&�0+"u>M��`�~��������w��AbzG�V[7��_����8����R����kXr��>b���8�W���r� ��>�Vq��%������'����6,�,�d��H"����Dx��8>��2�54yD���ٱ�d�={Y��B��$Q󫞼�u������[��*l���B�;�N$�7�4�Zi{z��������{R�SOH � t�j�H2X���Se!r{<�\�r���L:E��R@y����)K�w�J�ׇX,]9��zr���ז�k��55�(b��1��Xbw�ϲ��e�c`Mx�9�Y0�z�'"u_�R��h�)�0�3�N��U�qH	��!���:�.�s��z.t��V�@���GSq�WM��0�c����;�	C h�K�vv�P�PUC�F�S�f���owU�U�*L�^'�{��?|�B�zf��X�^�Ї��ΫY	\? �>��������F������!���U��<Iȧ���MU+q3x��,!|����5;Je�i���x�}�X)WLμ��	�j�n��J�i�gG�fE�z4��sJ'��B�)�5�Fm�ɣx���dS�&�yhp$0�M�O�y��i��c����rnQ��40M�@U�A�O!s���~��#�)M���P
��er�e�P,�5��e"��Q�XI.����~H�E�	�;_~�a7Qe�yg����<7��@����-R��6.�MZ�ז��U�C���D\��߈U�"N��{Kއ�1Ͷ���`n�%]�����?#��/5t�����[�
�sn�*D]���I�"��Kh/�G"W�H�HW&nrK �G�"�(�IoI���"��c-"g�aL�Xh�8]j����җ�����qh\<D3T�S�/YLk�,�����YEY�Ud�������Y�G�'�:rr
O1����RK�"�P�JR9�lJpby��\G|�&)E�͐1�{sp[σ��1Z�Qk�(Md;��}c�����6��v\*���j'��H:k��<�'`�qi��4ENJ@��y:b�N�|����<V�2�Ojb���<���&�--�������'��;4��s։z�������� �v1f�|�7H���VM*BHV�ʵxV\<c:��c=ZʘGE�Q"��)	/�,"� ��&�8��m��� �/v����2��"F@��T��Z�D��8ea
��[B
v>��?">V�lch��V�q'Eg&ڤ����_�Z�"�mW
��M�����Pæp*�]�U�[w��/ �T�n��jy�ٽ��O�-� ��cO�A>�!Qj;�-/�It���S�O嚣jW��v��L,k��X>I�rj�|�o��	�s�޷�:�\�U����);8��bU���, /K1�l29��d�H%�S���q�ju�dѱ]F��)|�xⴕ�q�����^�ލ:�k3�N<?�=��A�I���
�����j��
$n4����T�Qe
������1C�^qm�(m$�)�����n�/gڦ�S�6.Jb�e��y~w���&�8*��ć��9xw���� ����K��,���ވ,��Y᪪���0�:�~yM�&�X爿��3D����p��B`t��� �+���D�'�{A��31���5�;`K�|�%O��ۛ�T|�@��J�d��@'�%�z;�������������� @9�b �,I�q��f ����		�n��g�    YZ