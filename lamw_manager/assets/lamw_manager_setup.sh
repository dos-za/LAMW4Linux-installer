#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="133346406"
MD5="ea1826e4d7eb42f516232280ac7df40a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25856"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Jan 14 17:38:44 -03 2022
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
�7zXZ  �ִF !   �X���d�] �}��1Dd]����P�t�F������n�哗�8BY���|ɣ�k��L$��>��oi�Dm���$(�0�V�S�����׮cG���M�R
�ʹW���Z��{�V��,*pZ�)���	K�I����jc�3F�nf4����t�x3��O�ݤ{rn쒧�ÐR��˞-�2��0�o�Q�3���<�vB�P`ﻍ+�rQ1?Jf����"��o�s�{�akSV(7%�l�-
:ڼ3��E�l�� �gF?MgڍÙͫ�P�R�p]������R���|!��:X|E`Y���SBcl)*��g�ep���_,p�\�u�e���K�� Tr=��fz�����M�+�ҌR���فLE��Z���KC۷{mE�<W����	.�^�R�)�.�E,�����x�iuE&�v��..��0� L��
b~�ikV� �4.X�>_~��	*�;����[l{��p��/7�����i� ��<;�Kv�3[�6� �]��Z�~lpmU�VD8��SǄ�8�� �i	X6�6e{t��A�G��@��EU��-W���]�2���ݲ�Ǽ���L��S{�^��a�����EJ��	��pL����[L�b�
 ��i��q�w0q�٭@�K�LW���Tf\�H�¥l)�7Q���o"��4ܙ��U����������o�]X�
$�b��-�8�	<�o��H�X�k+e���査ܻ��/�����9���A��]pU��Y���2�K�	S&���~�-�/H�zʏ�#¹>�o�F�&������]Kҏ�`)�O�X`�	DH�1�2$�'Ŗ�ëkëN6���_��\�f.�N=/�FT����!�.�N**���fmX���Q��Z�z�R�liN�Mm��#��Iͮp��J갥�s��B�&f.{�u91D�I��AN��ǟ4/��)�������$�'Z��Y�_�;frF)�۴�}�ok��6�NĨ�\e�H����ٯٻ[��&s~{F�=�NL��|3�]��6| �,ɫ~c��&W� \��2����}�Z#{B������D�X��їM�yl!T@��Om��T���߆vΛ���'��Bs��+��>�����8��Xzw����3�	���CXZ���?��&�د"*���I�vl�}na,�8v�ƀ$UR)�(���=��\}/g�_���^�f�E��� ��K��&�+_jydt5J�:6JNk��1i=��J�K���Ck�M������u��0,��*+
��Mg�X�����?R������|]��)W6��� ��U��X�5�a�rH�5�����'m)0�8/��{�{�i�&�3��q�/�Z��K�z����$C3)m���� �3��w	�	p�u1�S��,4���c�O��X�{�	 1�� M���|�Sf�W���Hj�A��*�t���c������s�b�"W�����r�����!p�l��!i����ߺ�׷`�Z{E���CP�KP�g�D%�A��\WIZ��;pޡ�T2�m�N�E2�Y�c�PUE��F��8��^Ԥp*7�r*��|ȹ|�\tj~�*m�l�yii�[A>�X}EZ��T���؊o���#`�����kA��-�4��!H�-���E�r������n����&*�i�)��q�{-�;��s��}쌵b�b0�s�/$1�KhF��>n;�p�A�C���-��/�Cm�_�)M�B���>n�VH9dWP����s�v�t���T�)���)^B�$����im�)����2S�%�
�c���R���K�����ҙ�I��5fԜ{�`�,���~�N0hw`$�	-��8��w�I��SP
:�V@x!P�W!��#���"ZY��-�Ϥ����P��Z�i�'G<���عaZ���{�3
�@Z�B.�-�zU�|�w�@$�d굓.4utN,f.��o������6pD�k]��3��'��CGD�8 `TY9R@�h��f �(yG B^2iT$Wi0��k\R���뫪X��o��1`f��p?:Y,e�a�����ŹL�����h��L�1Z�Hm�h،ɂ���*�SNi8��U�;")NW�ُ�|�C9p&�kHd��#����c�9���Yſ���PAV��	��!8㝌2i��$����?�h(�q� \� �SV�W�1�`�D�B�p�&6�ݩ2D3$�G�E �I���``��1AL�Qd���`���PT,hI�ClK+�=g@�������$�1$h�:b���l��<e�Ɏ�&�u����dT���6���r[88�y�Me]E"\������ܸ�<��\c��FʤOx�TQ. ���:?v�}-y�z󮡳�S@1{�����I�BSA}7���F���V�w1����n�H�m�T-R.�Y,�x���dAD�j7��]Î�~�2
Y�C��:�W7����$��.N$�%a�̶�(/H�"C3�mSbO�H`JH�%S$8/dM���_����rf������.�'cq'G#�z� �2���g[@��W�y�W�i�ִ�"&�x.��f��E`�b��`5L�Rў�`�d�nN��*:���'�ͨԪ�ɧm�+O_u����m�B9�#�1���2BN���Y�9A.,	���<R����^xq��:j��bv��/3-Ue�9�l���U�0���b�17Zg���=�ĺ��Ԯ-�W۷�jL*(uN�?>�eݦ�ё#�l ��8��*9�^a�>(�)5n6R�ƒ��靑�u!���]z5e�\�A��j4;�S���& #��U��r�������yD�y�f�G|��������y��3V�@�e$va�P�[T�	��L$�WCd�ݨ��?|#�Ez��=�񚏯2+&`�v �ny�a[Nd.�ևnrm�+ ���;NFc�d�N�B���%x��c͛]���Li#D���ȱv�2ۭ;���5XE���` �����ZN�r���˦_P��0s�i2f*xJ������m����{������y�w��|�0G��{Q6���1z)��:�	|�,5�����0��>]�T���!;8��@�W���)y��=��u�m�K��~�K���VJ� ��9�7�q��t���A�;>��9s�����\4�eb��ҿW"��k޻,�������tI���*�k��[��}�G`
;&w����!W�<����`I�^�9�r�K�.l���ei�������J�mE��X�<{�ɬ�x�ًp���`�����ɹ_��H<IAu³�,��K>Ҍھ��7����Fy����6����2r^g~��繴^����Gs�g�Fo
�D�׵H��Gp��]h4v�<)�k9\�xqP�N�ؖ<4TQ���&C���5�;"\b�G0��rgV�#Y���
�"8���w�|@�Ƃ��[��bI{� �Z)XG�������g~��QN��|n�ˢ}����o\�֝�ahv�b��Nl{�8d>�A�:x��[5�=#T�4#Ͳ�>�Sã	�$�\��B�2�~v�6h��/ ~ VG�8FE�/��I�Q�Z����b�S���.�#��l6���QH3�K����:]t%/�qT{=�%\�i��g��4�t:������
����J�냊U1H,��:�T_�E����F��ίL�H݉,�wB��d�� {��3#���1a�Ů����r��vT�����$@c���NL�����j�2�s.@������0���㕺1����j��*�m5
Sj���n�KQ�����+f�INH^���	}o�-�ޖ��d�3f�~�)�<��:!eFڈ,�_��������� �ŖTm꣍"�����IͪF_G~�5�l���my��0�ޙ�>��z�H��Q
��r|�U&!���荓�$ǌ�Nl�D� v>�`�B������v�����/?��O���E�����������#�����)�:XƿU�ɟ���5,<&J��`���d]F��& �\l��"\���I���d8�=���#J.k@L�kE�+�[RɃ�&c��{$n?\!�e�<�)��~��0�������e�.���� Do��ʹ�r�0���V����n0�ߏ?W}�uO#Y�p("�w_cKc;ת�&"�dr)�8bV�M���V��J���	�7(�G�����w5�$9*E�?A��A�yv^�U�ͽ���# z�p�RNB��I�(�6y$�&�ΐ���(�k� �G!�0�͂�-$�Wc���A�@��T�r:4���4�c9g��a��T�������vks9�d6�n��r�H��G
�٨t�������Xj���J��I�,�w�R�K������+G�.n_��	d[�h|����u�x`���Z���M !�Dv�o��k��瑫�����,�X�r�wv]���"��#�T��c�Q
����j�������J�{]^���NYb�~�7�*g�}�^q���3�1[IZM2Z�+iK��RVtj��T�[���ܹ59��|>������0���m��_KԺ��U)m��
c���������7����1�v�"n�諾�6�Y.�Lg.�)�?<Q�kPi�[:��'�.�����i0��Q����ۘ�!Xp�Q��Q�>V�*�g�VߌlKq.�J�J��li1{=��
����f_�nW_۳��4��KG�G�ig5M��5RZzQi�g�~<���|�TvyۅN-��ơf��.H��g{U��.�s���]i����q{�YvsM�V�.�+a}�!���hb��6v'�A���+5{�{s����)�jO���+~*\�_��
�{G�i�T&���X�t���UW��7���lS.�m/���0�M}A�����Pi���P�	��6���R)?I��?��<�W��{^��B�|[�����I�6�@-�o8�u&	��$�!�]�wϮ:fR����Z�P���`i^�l���4�Hi��2��*��-��S
_{����m28
��m�D�O��W��~s-�<�k�����5W�g���f 6�ʄ��&��oX|o�6���]����R=���I����㏌������@J������00���'��c"AZ���AJ�� Ս��ﰷ+;0e}2�;��Us??��T�p0~9g�Ô��tYT�@��Q��T!r��y��0�풆v��뜳��J՞ 6<�I]O�&����]3�t�&4ki�'��'j�{�V�}۵��+�ܓ�s�w,�a�8!ް���y'�2(�ͥ�|�+��T(8��E�7Hh��koe���!R�և$�;���g<����"Ђ/� x�
�KQxP��6���u�Q��"L�M	�x�ys���@���o�wL T~8��!�$D�yԠ���E�n��O��Y[O��g];(�W��ͧ�r5�y�cr��LkW�ົ��ǉP�W�x$���%Y�T2���u��e��V��Jj*e��n����5��؉OtE�dH�6�]O��4��T�7�Q4m��ֱ����'���:��@��Sd�7���Z�k�m� UGF���T*�_�Ο����7Z$�Own�-���O����!=j��-VQ;>��Ț����x/��(P}=O2��÷岞��j� �y�k�N����]	�����IB��v�Ѻ�g:a:�\ ö6�`S0�b���	�u��<�..Y�������4�.hMS�a�̐�MK���FS
�VQ.��p�ڃ�h������h����A���DG�W1rZ�?��]L�c��g�2B�f��IT<r�97@���i��? >#��Wֱڭ>+����Gz'�})�&[�;l�g$�h���e�A�\4s���v0ܺ�3�M�sZ���[X ��_�Ȃ�
�� ��Oܶ|��E,P�o+�3�~'@PO��偞��e��Gi����y���\�0�O�'�/��u��)�N�c����T�=~��m���s`��w���Cg�T���'?}�M��Ĩ���I�
�`]��+�+^@w�$��d�V��������P-MMex�|6�p��?|pMy{m>Su[J���\N��<�1Alx}�b5�|K�o�I��~M����ك�k)���)�	^$�ެy����J���m�yh�!�$69�h�h4	,lj҉Qĩ#�n�)���ǹ��ҫ��k��N
��V�sZ�EC�H^9vYQ)ޘ�v����&�Z�2K�3�wd���*���F�	�7_�HH2� ��{�ӥ����v�l^����<�#��� WY���`�b����8�س]��?��@F(liYx��G�H�CD)���J�fe#�&�����r�5u��ע��J�X��S}۰_6�����ScB���=�CVCHԢ�-��C6�^L��]�#�J���uR���v4�tl�Ϗ���y�o:�z�8ֹ}�Lְ(�-���z���	#al���������k��?�[��e�Xw��\�r�{ �5��յ�8~�[ \�tp3w�}N��.���gW��.(DGQ�=t�=�
�Ӊ3&���/�Y��`'��
w֮���4jd�#���U�3����x��m��}nV�@�:��l={v���#��=�v}�%��tP�����	�F/�ﵻA �}N�eA\��o�"��C-�Q�FKK��ϧLi\ҧ{"�b{2|M��╭R�*���J�����}*Eh���k5|*D��Հ��D�Ө/OBx(��GO9��ŏsg�	I�T�N$��q�f�8��Y䇁�{JČ��(v�����\���N3���yy�q}I�
S��?N�rUHַzw-u��K�)����{�o'�	��D'')8��cd�;�y�6��x�	��36zbN\���*~�hye�W���Z�:4��s�:f���kI �$���%�A�R�����3��?Y��k�i�P߳QL�y���>�ۢ	�o�`�1�� \�2��B�]vK��zdѤ�����Z�s�������H��`L�#l��[|x�
���y��^G&I�
aIO(�I�K�r��gGQR�&T�Z[>i]��\�D.��1R>�4j��� 8��ݣ�
p���Ԩ{��>M���{L$T�H�ӕ���R_������{E3��"�#!��K�*�+�.�}��02DO�(tx��W����	��U��2>�d�ۆ�T�f�8j<�BxԢ��6i�w�����Mz�8�Y6���y�M�P�!��ւLϏ?����X�u)�d�/o���$.�M��O _��Ъ=��(��f�c�#\-:��pC�5"��Hc�R9Jxc±����#�x�c�qXi��LI������GJ��*�Wq���/WAwP�*{k'�u�s)9xf0���N|��5	���ͪV�N���#�hSGߐ�L�g`����U�z�ѩ�1^&O�X<��&���U�%	!9Ȏ��ƟW?J���~A���AZR�`� "9=k����U�-���HgÅ-�h�Z����~g�o��M���
��?�L`^~f�q��sM�P������f)?���8xS*���l�K�߭�Z���G��j1���Y:��}�R?J9OR7k$zc�8��@�hy#2�+�<|׊�
��Ax�Sۻ�RdtI��kLcK�U�B�r�xf�<)�,v��!�|���\A�xb2��/�c��4j�1Y�h�q�ϴ�mXS]�EjB����\�/g|�Z�����@��
�����k4��W;azQѢ����ԾW<sbش�`�'Wy�vE�v��%��E��6�8�?e���Tl�K��� 7$�'RW����<�F�DG_���~7�K����aʎ��)C��7�A���������|��ȳ-�¨�63�s��xsd�v!v��,C+���-�.�Tc�nN��{��ł�� Qߥ�}c(���k��}>9c*x@&���b�Gj��9�
��$F�s)0���/�L7b s�����X���Q��<���]/Cٛ��= ɺ����9Z �b�� �߇j�
u�����ٯ�;��øWfM��
�;P�B�?*2��������^h�i n&n|A��^����f��k��n8�đp�����'m*e���n����7XiӉ��I���3O�Xl�@���+���A=�n~��6�I
�`(^����!�~G�^G%�7洧�,'����!?��[�E������T\{�=�/hS�Fc3޵��������F��S��z(�6��2�EQ"rl��f�5y��_�.o �D��*�<�����f�"GV&Y����q�����x�g>pU��2�O]�����^"/JM��������.��*ht�]l�������\bʮ!M ��R?��y����<�	~!��˵¨.v�Oxk��{�fN�W��n����Py�~?� yTP��x��f7�N��r{�qpܤ�Km�o?o�A�E� �0"㓖F̡N��[�K���;h7�(���ܴ��S �O�/��G��϶����T3ĝ�U�>�P���B���ݱktB��4WY݁��wD='�/
��G��$Ώ��E�5���o�ĩ�+����~uoc�*�.����^7]�(�� �����aj����E4����Ҳx��1\	������dx�gO՜~y"���{O��I�)�ʾ��n�j���o��.G4c'����ը��[�n�pZ������*_���c�Xt�WAb�_�w�,��+B�/���5�CI�vR�V=�خ4�R
�a�1���@U��l&���O#�=g�\6Q��z8�u�'�����
����鵱�L65,��0�G�66:U�l��+Uw���MYa��0�	�4�g��ٕ��0x1���[���F�T��3�1jd��wޓ@��l�x����� �1�e�ծ�܀�d�DHw-_�˨��ɳ��Hg�8��W���N�Zp��~���m��_R	!�٣�$�f£��Sd�؛�����@��nP@}$6��AA���H�WƮ䁲�	R�s**�5S�������$}9	�F�]�����ȵRX�W����s-`H9nf!2���!�W���*d���)����#s��U?F�T��, ��Ci?�L���7����A$�b��<�.X:%ƯOGn[�#�DE����v�jGբl:�U22ܰ�"���UMl�a���'�Ĉ,O��_���x�\����z�X @ ~�%|Ԙ���s�b�	�aJm����%G��}�QYS���$R\>wZ=�z��&}�;�Ց�9��e6Q�ω��,ʦ��jӻE�`� �ƺJ�Ǜl�O`>p�+MF�]�Odȁy�e?d�g��0c;�jm�='"��k����1��D˄�u�ی|�[0��^oä��Ɩ�M��+�?���p�gΓJLM(�.��z�3Rѻ���+�A�MO[5{!��1��&8�`璍#��Ǭ���9��S�H��4q�G�G��<V���:�G�H���P9��(v�#ܲ.����h֍�3`CJ��jaR�u���<����Q��S��}�)�P;J���t�����Cr�0�8��`�/��Q��G�)s(�ׯ�;	Hj��O�Ӻ�.�ɘh�	}��x��8�P�L���1)��wJR4�L������6~q��/A�4M�T�ss:��5ti!��w��+Z|,���j̇{����~�1;�~fCeN>>��aY��'3�s�7+�(v!n��/�w�"��}C��_K���u�2<�F��|I�mN���7�˳e����A훁�\Ya��}^Ͷ��Em�!�w(?p]�PB�$N6�5�K~ǎ�a-�M�'���Җ'Ǿ"8��Ou"�����'k�x�=Kk�����o�n��%C+?]S&ix�f0	,SV��9��<��֭��!�R)����%Ƥ�$F�ћ���%��۽�X�,�^#sh	�Ʒ�@�]E��?f�pI�d<PW��5v��ͪ�W?���,��Q# �/f4����(�����a�X�����E L(
YJ�3 �'dZ��U&��·?��G��JQU�z���]�5��tLX�-jc�{�r�L#����gr��#Of��NѶl6����:�S�W5A�g��@mm���!;�����K�LM'�N�_�����n0e"�{��:�.�l�km�dx�Ş������
�
�`S��
"�+H��0�
��زѬ�4��i=��'����a����:?*>��I��z��E�ʅ�����O��t%ow`4�m��B�0&���^:�O;a^E����6��8T-�>�7+/t���P'"�5�h��DϡWb5m�b
�f�i� �q[Ki�{�N�ڍ���g:�Ng.g���<^n��N���a����#5^������w�*�]$���ndZ\�� vDחr��Ꚍ�f�� -���nY�W���s6=�j�X �IᴑF�;��OhxND��,�C����ĂhܲQ|���o��������P
�?�\)#�G����=����x8��D6��!^�˓O<��ھ�s��X�暞^�O�j*l�NT(�#w�����{84�U�9��u�8Xl�E�<�=��>�i~X.x-�"Y�(��BEӊ%Wl�����8�W���3��J��4?��g�4#\�k��C�'ʏ�wl��y�UiOm,�2�qA�|�Je�Sƙ�x���:y�K�0&?<����{ܗlBQ
N�3)C#�0�]y���[����땾ɝo�1o�3�C�x�+5�*J�O�ࢴ�MѲr�^�Q��)���uz6��a��%�w�����U
/�?�=ʬ�HιQ����w��]�s*d�褪f��{�hL]��t́4� ��x_��+��A�S��=\̂��`��e�˴���̠]��G�_�iѸ��!	���m����<�6��n��h���w���^��ަ�q��F���j]��qT����7����왔���9Ԯ̽�[�>NK�V4�Iq��8��뺀����S�����Tli��3W�i[��VJ�F�fdE�,�h\��e1���i�%|��kX�H���8��S��Sd�mhѡ̐f?a�����ߋ����R���N3糭~]VzQ?=�����i�\q�	���7Ft�����E��Yק�9���SU���;
D��j<�w_"Ԫ@������*P�,�JM-�*{�'�x�wq��(~Xz���Oa�Z�]t�uWK����ݝ��~���,�i� ��9�M\��Μ��� +.�mz��ґrɔ)��F���Mk��O,��u�03O�h�H@߶����]	���Ŗ�w��J�K[E�Z# �o�7�����O��`���������r�7 �OP{����Sr5�ux���p�=T_y�M��
�3��3�	�?���d�I� ��N��[{��/���l���4�6��-ZՇ�W-����Bj���������h�ܭ�i�31`;�3�.HBgn�,kP����%�=)��C��(��ջ��0�'7>u�JL��Ж��ۂ;����r����ɾSF��'TL���M��e�"G��m��+�̬�a�4n��D�o�߽�ɕ%�����I�y�{Y�#b��5t���4�W�K�E�QU^�����k�0�_�h|�Y��)��g�m�#/<�r���q@c�u�s�����hZ���e� Y��3�T_6��Mb&�!����Kv��D�d(;4�Mh�jV�.���S9��6̢cvٷ ^�<�؅�:8�P�.��� HU�u͙_�#�A���4u-��HPM6���vE��hYk��eW1�s}/1*��Ru=x"@VRf��0%�U����%�8��d~��n|5 z�%�t��Z���qȭ�i�|���{�U����� ����fL�"�$���0�C/nkQo�������(��uss�95�~e�I
*�-]O����U���!tĝ1����G��4r���1�Lf|��I��^R4MJ �d�!���`���?š[�Q����4��ay��0�i=��nS�1�4g�}��W
Lx� �5�E�)�����b�T�����u5h��Ȇ4�4L�ܠì��Y`�h�����ۉ��yB<�E9G�CS��EX�_�s�Qu��	���������Q��bnN;��]��H���m��#�N߂��2� tmDƔj�-H�W�ҝ�D��c`e+�����穇��DܽIb_�ܞ�]WMk��*�"�ޚH5՞�1�YX�$,�Z��e�J'#�Ѭ�U�>�ܙ
�l����H��i��C�,�<�`�7M����&�kA
Zzgա���Y��F�Fey�01�f�\����"�O�KQ(���|� qT���HA�u���Bh����K��H�:È�\r{[�7�do���s}l�ٳ�mѲ(��n���k?Q��qE��`k�P0��$p��nǐ��ЇX6�RY���%Q�D�.�d�X��f�S�P�T~���T��t����^��X'�zϒ�J���3p�Ђ�y]�>n�U����}3
'���[$͢�~=�d�6��"K����l��ؐ�6�Je*����^�뢬T��}���ċ�?�/�e# [q�	����If:c�Ґ��wYf=w����6�p�1G�B	�;S �7g�J�KJ�%�Wu{���rʩ#I��!o����[3�jE�f�P\���a�nm�>�\$�۴=ӆ7�67*�"�v��|d��w�߾�@�T
��ș��g�%��%�oZ/y��}���Wu{6i-���i9,�,EK��0����|3����2����Ǳ��@����򟂕Wo��9r�f��@j$:]*9h7}�v��s�89��'�X$U�H�B��z�M���MD�^�E_�upߙ&���YZ��ƚ��Sbɘ��A�N�.Ի��le������c��G]�j��S��1�ҍ*���E2nƟ�zm(�a{�wZN3�L��`Z� Ƃ�a0�96ѵ���ܜz���$�G`����o.6���~L2�� �`L�W^l��=�i�T����VA��(�z_����Lg�ujH�Hm��&wP���F82�5�z���KF�V���|c�_��o�tH�屖r8;P5(�R���[�)�%�-z^g�e��f&����Q=_�q�G�qu�A�%����W|�`[�]���֒�xu��A,�
��B6`��VS�f�1���XY0�6��Q%��@�݀h��5z-R,'��ma)�̩�	V�X���/48���^�����c��e��P��Z�<��P���F���!��ʽ�#��,I��c瀕Ԛ�?TEc0��S��e����b�&6���ɚ�s\i�cᙶ}��L�q�\Lk�e��mPe����K^R=��Q�-��m��W��~ ��PvW>������X���Q��{���i0���P��ֽ�Z��F����|�L%�RT��ڇce�g���u�IƑ.+-'-|� u^�=u�Mta�[g`��VD�!�kKU�����A���^�I; �����`�N�E^$�M�e����7\��F��z;����N��l��4�/ҳ�������WLqX���;[����l'5�be6�J��~�!/�q�"nzG[����g� -Et�I�k0�}�@%�5B�PC�6d����� ��3�L�z��!l������C��[u��M�C���<s���PjWT�]�s�
ok�޼뾕\g�5<��|$��Ͳ�6,-.��X��+�Lӡ_̎Ҍ:4(|���֞���돞y�@����瓿��x�!S���y&�rΫ:�����`��Zĵ����+��{��-������ZC�'�xP��ƶ���7����[�]s���r����g����0���r�ۡG����W.�����p6	��B3&��k{�O<���=��>� �yt~����UD�����V+����G5R���6�V���ƀ������̚�y��{��|T�ˋ�4ڝ��% ��Z��Iql���)�%��<����r���Յƺ�#}R϶6�Y�͟.A�v��2�+�&Z$�'���֚�俒����s����=��|)9<C�I�:/��� �2��$cp���TpYÌ|��p�D��2���Ӆ�LI�?�5"X�gC"5��]���p��%�.V�N;~�D��<�`J;��X�i�eR3�R2�ݱK��1��`��K�V쌵��7�r�&"7k/�n�%	5��׀��$`1����d���\T,j	b�'�Q�5��oc#g���p�(v���2��1/�Mg~	��q�i�C��\�*�꠺�M�~No����ChNq}����?�H7s�nX��4��9?_�!���Q�����%R�Pl4Ƕ�t��0V�2�:�ؔ�SY~�5����'��4|�@p�:�̐'f"��	6�-�����ɚ,`ַ!��1���"q�b�Z����޿�cbB�'s U��^" ���,+-`�Y�wicV��V�ASC�<R=�ɚZ������r����b:vo�,eL��R��>׌�?/Xq�w;���E��2���3�����x�P4����PbՋ�P�h6�5 Jq�-a���˰*�J�yȪ��O��1�8]�{�R��b!��C���C�v8t�@rR̹4^ŋ����YX*#r/�U��p��[?T�� N�'d~�瀔
��j�%7�tQw�-�}����Y.�tDEs�E�de�Ÿ�tCt��@��ԏ��kypQ����)���וr'�`��^&	��f[��%��9�c+�wgBD%TlEUN�ql���MZt}{{`�+�z�4�V��0���|=�x�Ŕ�:u�z��8��%J���l1�#�S�����sS2ŭݿ���Fc�?!$ϲ�%��_\�Kd�V�˳M;x>i1���g���|�t���K��Գt�7d�'��;9���Oe��)x�O!r�� J�Z�{<<
��I{���P�ƴ�|@Q�1�ijTa��{5:泑xo���Y�&\��)Hƭ�K�T]�Z�k���E�R�y�l��-��'M	V
^.U$hJH�o7'�Y R�]a���;�<9�}U��A���(�Z�2㘽��/�Qo�tT<��T��D�;�#]��j0�S"��+�
^����Ӯ�����ۄ�)2��^ZB9܄⭲�Z8D�R0MJ�U��g�¤�;�0��E�W ��9��R�Ϥ�5 �9� y�|��5��xN5��
��1U$�啍����Q�lL�P�T�l�*m����(l��9�tͺw9>��[uK�"h~*�{�l����\��׃��E�!�~�Pg�N�gq��;6Ύ�p8g�kpJ�Hp>Ks�揫B3������$�����rV��64�����L��Dd�9/�R`�t[�uv� �7ֵj/��-q���q���X=߫
zGu��V`�?nL|e����_sq�׈i1��:m���&ȒA����=����w8y��\��x���1`�U�zס���A��9p!�y�[�U��mw���SC�X���N�B��ALSЅF�ި
�bC���s��"�wӓ;*݃g�����JP�ߩ�zܖ���,�G��5C����a��|�K_&rX�#���L�}��_���۷T���I{��@�D���>J29��c-�\�I�	�����a;r��W�Z�� 1�w�.Б�:����k��(�#���9ex1C�����̭	��Sy�]��5��7k��~"d �H�;]f@�r�h=j�4-ȱ�.�״����!E�祖�t�k�z�c����\��w!��2��pvڇ��
8�����B�P=N^����G�!����m6g��5�����D\�ȅK0&*�,5A�������c��L~��/�Çn{�8�HFf��oR�-r��T$��t�Ќq|��[�S
� S�T�U�_����x2�\��ۨ�02�32H6~�m/�I�	��T.A��@�|m^cF�q���rٓ/���9x�5�i*��\[��C����R�ZP��Rb���8v
<5�EnZ���mF�~��#O� �A�~���L�C%zs#�C����r����E�6����e����T�A�3qk�G�XTճ0n����z�C��m�R-1�X�7"�5�M�3���S�R�h��9�§`f*�_��=��k.@`�\��y5m�K v��|���˜�4�V�!ᴸ{�gس{B�z���:D�aD����Mf���Li���gN&hn7s�R��j�E�Z��
o[�����U�&"��9���Ff�-�-��[����#T�y��ܱjt�!��/ǵJ
T�֔�j]�-	V|2�o�>�~m��I�L�Ũ�$��ps�_�,����(��!?w��`�9]~��.N��nɻ1��5OX��x��H�>�'�'�����^`���՟w����	�,��YiA���Y��9/8��#�^��:�:�l����6��Y�q��d�
wn�ˏ��	�;[k��+F��KA{�Wo�W��c*}e;�.P����*�7�h���vUR��H���� Bp�\N�}k�>���O�������~�w4׉��(�>N���iIj�9F�'v���Ly����N�����r�i	�\mD����ʼ���F�(�Gm\7�x��Ul��"��]�y}6D"��}���j��a���h������"�4�,��ϟ�j�X�r�	Jj	�ұ�xd3��sG�5��В�sGAozL��:�q����%�WB�G�_�Ŧ��B���-T�9P��16�@��t���'�F�s8��/S�mz&�(Ƞ���'R8[3�3���i-3��� d���[�D�s�A�gQGK��x�}�I�������I��Z��X����ӆ*y��4ߠ}��?�J�P��lk�����h͐�����B�n��_j�ؘ��I��# ��[��h��Ϸ�[�D�J�ao�~�L��k�w��	�|�X��W��z3�r��W5���f�U#������aw��̎}J����ie��ߥ_�W�ɒ���c_��0	=�E?������I7����X�h8xI' ��$N�g��#�����y�����28Y���_��D8��"/z�*@�S�k'|���ޤ��<���s�OQϜ0�>�=��
���$��A�g���r�!�k��"!�)�7sL)���K�h�<�S�:��о7c�S���ګa���j�+̷h{��}%���
���x�'��i�pc��J���n�Lw3��b�=һ�V-���~nճ^c���a`ܝ���{��@�G�EB˸�&�ăa��
����"��QW. �drӢ` ���͔�.ؗ6F�ռD������>����\ڸl��:Ik--�k�h]����l.6�^������l=`��z���*����I�5�G�}�/�չ�`#��4c5F���&�5dN��X�/� �N;\�z2�:>�*�]��m�|NT��wv8��	���K:�
<+ZZ~�8*w�?_���	�|*z$�"�b�5Mb�n*r���@%%��z�d��#��zY�AO�ٮm�7Ogֆ��~��`\s�����L9�W�g_Xvߡ [�v$�Pf~^{j7{"W��%�B�g����2�O�ǶT1wwQ��_w��Fg�U���W��;/�p*��M��ԯ(yc�uL����G�4ǣ\K��G���Jb[jr���r��#o`��f���m7�B�3i�G)H��g���Bh��;��t#���v�i�k�Z�Rs���a+�Ri��k*Pk Lv��A^L�Ϲ�g_�+.t��+��j�  �ٖn,!���i�����\��O	�#����i�pŌ"�(a�εn֐j�l��YgɆ[��[n�i���C�1QF���9�0z��&ղ�	IҼ��8pcdڐ7�[˴�Q۾�t�M�~~�ײ'�Đ��j�����ƶ[�ѽ�����i��@Ea5�9X���]�@��`z�`�|�]�-
��7<���8?�R?%�q#t�`�ȿ�}���g�५���5`C1��o�zn�RU��nJ�6���UOG��~6�CG<T���'*�g��%s�|~y:M�����M���KR����JV��V��P�&�����db�qqd7����8�m@hB�\�pTu�#���Ld�'��b	o����E>O�,&qCB3�)ifa�����eO[�#�H�{
f'|՝���1{�.3�c&����0dE���y�-�I���V�O�L���5�W�9"��{Ԝ��-�
�( H,�'���Xܺ��
��Jq���P���z����R	��iR�nE�g�_��ϲ�������1��g�IY�����ޯ�P}/T�r{j�O��(�)��`���5��(X^j��NL`*"�A9|��DW=;1�Vh��s'��DS�Y����^�#��]�2H6N�:!�yJ�_���q�S��Q�<����Yc���ڏ�T��P��|�ṅ0��z̿ %���?��p��ڗ�'�w�t=U!V���r����;��^,�]r���{��R��t��)���ULV��>���T;	Z��cf���!0���F��d�OX�Hs������3��k�������C|�B�h��e&�{M٣�O���ȱT;��|�!ȅv@�0(���d�v�6Kv���	��<��☥�3���q$�)���.P�ok��DD�w�I��	%��Lc�SU�Aӆ#Y3�>0����i�X��ِ"@�?�@�Z�c�����&O^�eQ����kJ�r5��G�ǣL���~p",�jy���[U&��+�y��1��"����hN�6��<A���ғm�R���!����`��;2J�}y�v��i�����݃���v�'��s8��o�G���?(��㺲k'6���v�:�t�V��y�6�䟎-�Z1��5~U�e�t��	ԓz���ϰ���S_��1�`�Y��%E��8W���a	�7�#���h�/�����sE�@�$������;�����%}G�=@<5z���B���_±2/�ڊ���\C^��
'�}�8���!R�Ǣ��ZfZL(?K��̓��OԘ�A�#���y;����� ��F�6q�&�M�b�3�s$(�����({JA�ü��ε{�� ����������;�@��|yY���s6qeΘ2X�Ij3HڲA����"Yr1��i<����>��ȝ���xY�,����ʫ<���AV����A���NU���	���}Ti<��H��Ř���zI�a�0l���tL�mˉ<�)0�?k ,l�'�x,��!��:�~e��V����*�5G�%�6�3�?0	?ΈI�z�曔�=�C���(�.3Yة?y�t��$��I�"P���>��O��L�4������R�V��	��hit,�Ҁ���rߤ�s���pw� �nY�
�l��&�,�a�@�9#�6W�	�`;9aϋĲ��.��,} P��.�� Xh����m^�'T(�H�%�d��;�ߌηHz�:a ~�Ê� �=�Ġ�
[vΤ�|ɸ��jo�c[��f/NJJz%�������y1i+����Q r�џ�(��`2�K�\���_��d����R�~�h6X����46CF�b��A�Og�)e�� �'G�Y-�^�p!�d��W5���l�(�w����T���7yc�2ں�hTt�o _� �S��2����Q^Mv��;(s1Έd/&R�o�y��)t2�&�C���q��M��$���}���]�9�n]�"��[wH�O�d�=�DĚE:M%r�T�},e����LE�qyԟ�Е�g�^y��ip/����\���g/l����a�VY���j��K�]�Բ�����`"6���΁�t���{$62�<z������
A�T�4�J�H%L�l�Qԛ$ �n���zh^F�g��`wx�����PM{�(9��G�_K�g�IO@�P�RnP�V�䒾s���8k�9�'<��h`T�s�� VGMg
Ta��wc��/
(�ALE���c�P`�p����%&�������N̄
�[��͆ufHtwF���#2�zHy@;���EAД�m^�H�!��f���5�����rWf�I|��'���G�/)|�K�����/Ey~<(!V�T	uOSV�%ez���}o��	W�J,=@P*f�*6��h�56���bdQ�*]�+)h��+C}��8�d��O[ظ.u'�9�<*��-����S{�?Y�
B8�OXӇb�}�eDȍ4�R��aK�F�ˇ�j��o3P#��}9���di�����ѓ�1˷v�R�r߈����uD�Ï�cM*��_oe��ƛW��@��1��ֲ�_�ϭְ��yC�#��V��rg��?���5���r������w�9r�>�c`c�8��xB����VD�w6����%������<�0qx�}�n�E�j oc����3T�� �{��0�(��F��~� �dHY<{&�2��R�RtRNC�{�\�}*���Wߦ�����ȶ�K����Z^T�9�!u�n�> `�z��	|�dm�h���b�QA�ZP��?]?H(m��_I3��&sm�$a�@���J�����b��A��^^��h��I��%t�i��]��0�CF��ą�^jW/b��'�.Ѭ�Ke+5�d~f�wւJQ�?���NI���Du_t�΢�w|���7$�˼W#�X��qɮ�cM_�uzR�#�)��ٸ�yR�7L��_�|r��7ȋ�
.�$�5����cVm��W��� ��XRR7�TP���w
e#c�9$u��g4f�`u�U��&M��mIg2vr�����⍽v~�Y�
�I(��DH<T��A�A6&	#�o�z�H�up�p���̠@`Z}>�7%�O�"3�o��$H�RT�T�ۉ�O2�o��G�*���5�ڥ$��m�	���`�]��]G��$�.e�S�X=��?�����?tC��������017���ܒb�e�H8@:�Ñ͸O���"c�I��\܇u����(\�a�����b�7�|	ǎ�z��̅�G:݉��H֪^�����/=,��U�eK��~�X�Ysa[���Α��A���M9>]-�����������"�8m�8``�-\�L&-��l
Y�rX�T2&�D�����ܩ0�}Ʒa&Li^��&����w�s�l}>����!�s0Nj[��|����w(Bk�� �c��z�cט0���"盎������G�܂N�U^J"e�
	,��Fw��;Ԯ�+��^�DR���c�[Ǵ3_%�:���]����6=K�o�)"[�W�� �?���d��:;�#I=�=��i{��
� ~�;i����.�п�=ΎPJ�;r������ՁH���M���k��ےI"(=Ʀ�_$�3+"}*�FP����.irQ@�R_�<�y����Ά8�3�'zS��t����Hd��~��:�0Oza���gM�gP mU�������|���#U�W�$��m0�Ra�E�$�M>J�z?D�z�~.�j�D��b�M?fJOA?*�l����)��_OICe7��{�æ#�ﺕ�!c����Ũ���҉I�^Y��[�P=�q@a�>�g�Ft�5ʖ�e��$W[�:4ؒi��6�[��G��nٱf7c��uj�zP�(A�6�@~T>;�"��?-zPv�N3k+F�Y�^�ؠ��Ϊ�=&F�D z�1��	 O�?~��ɴy�ӗF.*Y7�m�.���KTc�`kI�[�#f�d<�&U��]6��rs���\Z�d[JDMߝn���t������(a�o\}>G
ь�tc��:;D�B��ԤA��@f֦F��߱�0�k�~�v[c�D����٣����ӹ�)ű-a��D�&Lo���ձa�W��dW�n4�1���%@����y��{A_�|���܌����3I���-���4������g��΍�J��8��KY��h|gRh[�� ��k�5<Eʿ�E��y�lD)4�@���@c[^�i�2��ޱ�j\�q�lơ��K��6`,D
�
�Mp��E�@��V�diY;��tZ���Ģ�����:����)�k���aT��.ӜQ�?6����|��4p�}��C���K��v��s�ή�u��xhz�v�%��F��6͹ܧx���Pu����6�AKw{3wr�X�T)*���\q����om��.��Fڨr��ݩ!L8�Y���`���F���
'�����=t�	nPZ���g]��h���c��T��	���9b�Rb�������_4��or�ؒ�#�t�y���ȋ��c��z���������%�q���w��)*h>A�T"�#���tk�r����2�-b8֌H�u�v�~�bbڇ�� E���^cT�7*y=�('үE&Y�����Ɍ�~�W��3^��F>ҫ^��?b����{�P��7��,�:Ҭ�(bT�p���x������!/֒G�5���'�&fc��H/	���=���KDF%�5�b(#�£�A8��Z���9X择���"�6��v�� �5�Dv���Ls1Ĵ�2��/�@�Qce���Uy��ՌH;d��G�p��6�3H�ոX��^\'����qٵ|��~��9�%�[�F�6�t0B{#�D��V��ad'ISI��Z�?�4�hZ��[+L�)�J0�\�h����Cau�¨4�;��C�VK��!V( �����@F:U����ӌ�^n3��Cb�t\D Wt��x�kЯ���=X�-I���xYkO��djD�NfJ��Z)���U>PN!dB7�आ���Tv5<4t.|�����C���ž)w�#j5�� AR����۸B��z���ztɞDrR^}+�+>p|�������6��#�/�Ή�C�9�w����J�I��U0�TgA��T���}�QG��j'�	pY������m����D�E�E5��	��e��ȄD�S���j�o: v�ʟ\��ڇY���n
��2���Z��	*�d��vx��	`��%��%a�H?�>��pC�G�}��\+���]�%��6l��D���{�?}P�'�sR��Wm���A^�vI$Y��Eja<ڪ�/���K��7�F�������z�b�{<6cG{���������Zж�꿓��n�ehg���_;��t�����[6ǂ���2-��l��uk����n�OTm����LSUL&���T��ޮ�|3�yc��~��:m��������&��V{ÖY�|E'~���ۦ��6���Sz���73���9ߊ>E��dc&^� 3ׇf&��q��U�)���5Uһ٬&�!'�85]kj���n��1h\��ȈX���z�@�����^�hDQ U}�M��R(X�իb�<"#���#��į<����tUmU��6䷻��p��N��6f�:��?�Ă�>���d���Sr��b>��v�����H�bH��ȅ����w蹉�fZ�a��h�<�`Fd���N��\!�~��T�G~@R����ZeJj��޼����,��'�r���֌���3��Z'ꯪSQ��$Thcu��b b�EމT��y�;a)�\�Ib'�e�Z��J����N ��\d����NW�]��z!�c�x���,M�?�����M��@b�.|��d>�0�L�@� ?�J �:��Z,���&65�o�Q���jGw��cA��sNU ۈ�X�z�c���}�ƨ%ٟO�K�ˇ<g�Y	wHkʛ�(g�/G�W1����*�G���g�Y�ʓ���%f�W�����Ω&+f�o�<'0a���pF�	�_"8���}�]�+��ɿ@wSE�]�M7��{���x����}~R�OЉ\�
���v�_���~�ځ4����z�I��~&zZsҫ�]�9�a�s0��'�v�Q�Ծ��Yl N
�SKȕ 9�H��hs05c�5���	:����i:�9f�Ma��M�7CzAs)L.�u������k8�$��FdW��Yd����>X6v8,!���|)<�jsn	_={m��tw���xɒ��Z`~H;�'�r��HO�>Q5ft�#��|��[��X�����˄��=]ŹTv�?'�"��|'�`%����p0LH�[J�1���S�p_Ņ��Hu��=K��򐟒��^���J�o����)*��d-���z���fO�U��|H�c�.-�
1�	f0/v�g�)H�D<��\r%O� V��.3x�[�x'�O&������"!Q��Ѯz�T�G��5��`p�iB_& ��0�n�P�h֧�з�[�(�4H\�,
��	O"�ژ!��&��`���e�S7`	�D�e��Hn�՜�"��$A�Fb�3�2���U���v2$s���sf`uJ��0�Ź��k:�N�Sa��E-ZQ9,��`ت|j,�y��j�B14lR�W'�ʁ�'p����qY���1V���\��iN�J��u��㬼��ܼ|��=.�_��=��P0��Q���HƔ��SR�ZG?2��S��C2'��,�"�g#���sN��KN��۶��E�Q$���r�ub�D�"�M�n�U�?	�a��6�5��dC]a��M_���V�Τe�4X�AU�-Eq��q��x�b��٧��|f	�zkKZ�(qT�U���H����nt��$D�n�eڻ_��5&�'	�{�'�C��_�<v���r5:�R��~�x���D9��.h^�َt�H �6��������K�7x�ʣ�Fu�>9LDǱ�͡v��Q[�+{Y���`�=.�8�����N)ř�e�3ťMėr9p��>b�f��Y�g���H�\�pI�y�`n��n�D9�j�к0ۭ�a�,?2��kL�f��l���;�'h�P�deZc��=`��­�M�V�+�R���mP�f�Mr���@oOK����N�Ș\��Ó �akL� '�-�(�-/�9hv��t7b}ӵ��E�Iey�?Gu�D�r�jYhc�
�F���43Fۼ�Lf������w�q�#cJ1��1	�虛�����k���=I��gmn�����?�6M� ؒ�筼�p��J6�>IX����؇�L��d��$��̷aJ�h�u7gj����v ����d��`=�9șJ)��P% sE��P%~�-����\��j���A��ν ?��ɔ�AX�ЇF�PƅZ˷J����6�ͳ,~�7�����k�|����Yՠ���@��^��cl��j##F����쟸���~b
G`R�(�[cE@�?�g�r*.M>�wR�m�G��� �+�e��3��������H>���*�i�`���PΤ����g'�.��<�B����$ގ��f��-[�s�s     �?�Γ2 ����]mr4��g�    YZ