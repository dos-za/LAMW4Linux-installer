#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3874399453"
MD5="2177f5062bb6e6eb3496272d929c62d0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21252"
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
	echo Date of packaging: Sun Jun 13 00:32:40 -03 2021
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
�7zXZ  �ִF !   �X���R�] �}��1Dd]����P�t�D�q�� s	St4�j�0$��&��nǣ�{,dXXf�ǿ�Pn�vS����zBU,Ҍ�"f�����d��W=�_0�T��1�����K�f��^m议�b
�9��ZM�q���aw��IJkL u҆��l�X`�N�ܖ�� 8�'��1��g.�@]z1��t9IUU&9'ar~��!�Z�Y33�����S��O^�f���������"�8�j������ª�)3FF>�����o��a<�?l�z?*pr-N�vZ咂��­�����{�N�OR\�y�e(�E/�֮��Ψ�	.��/c���ۣ�=��b9+OtUG������>��P��ĺ$�D��Z{���4�Ĥ1=d��A�8+��ѷe(~���
�.�M��U?<��Y��~4�4��Um"��P��)Yl��طߐ�x�ٳ}�����i	KW��ν�zXt��U�@i�NE��ǁ��fu!zЈL�ۺ{�4j�n$�Wm�0���R�,��b7ES���S���ޑ��г|�iF�Hf�jX�S�z�������ɳ��d�a�g�4�h������m����<�dy)�lce�N��/��á�v'�g�G	ExB=ΛȈ���p��R��T�*Q]xW��P�!��s�q�Լ�D3�Lf�|��T��N�h
��5��UH����h�=S��ӕ���)L���mծp4C^�ؒ��ܹ4�$��i�}����Fo���F��������?y4jٮ4L!�4iK|��[��0�m�|�x��c�����]O�!���h[]�A��Lگ�?�w�� �f�'\�|�4�у�.�!}?Ƣ��3M�XÈ�;d¸�h6vQ$�����<v�rz�o_)�*@��{s��L	������5�Wd���S{Gl	&��Vy�w��m4p���=���;7��?+�Hg#'%<['1K�L��ӿ}��)�#v�<�t�YT��i81�	�I�d� �"Ӓ!�=�������=	9������[H� S9��N&��t���_4��O�~%5o�̐@;���Oz|��W	�p��v/��\q��϶oC���Ԅf���@ GzIJk���,�n*�9d����'P�+z'�8�T	7�/f[Q���n��+�]���k��D��F�$�R<��_=�����_mZ�<�ơ8��U�~U��+
rԒ�Y8,���L��8�l��4�X�-~�I��)�eCx���F��|3@,�k�I)�J��4����}�< �@?n7��k��pR�E�Ufr��� ��ZC?���""g�p'#��ơWU;C�	^~~G@YP7f#���nQ��F��8�z��370)eM�4����+7�}����Ii'���	�V8I������b�L��faZ{�jY/HTj9�Q-���[Зߛ��U���&�ϟ��v� dS��2�g�[P�Ms��96}a]����P�[O��1����^��BdJ����;"�Sq#%�u��+��ܩ	���v`�H`������X+�nEx��⫶2���M˙�Pp ��ugv�!�q��O�W�g�!0z�/�J�8�TDʼ�l3���1I�u�!��Ual�T� A�U��[��g�g�i��p|>��QJ.�AѢr=�>#���Lp�,m�މ]�*�5I ��w���I�VSpr�]��p�h$�d��.�|;O$u������[Kl���^� �o9��kڗQ��kB^�K�x��R��V2�;�d�_�1��wؒ=���/F�Ya���R�S��>�%s���22![#���q���O���LRf��8�! �-�i�ߞ�Z��Q4���h�+���B�y�����UD; �1�~P)~,��Ҹ~ۊ�}W��v�]w���ڱ�a�/W��煒�h#�=�� LJ�O":�S0� �Mb���L����#�{��W������v�`	��-���޹�,t����'���i0,5���hX��������Է`]"'���[�����Fc1��K�|"
�.�M�3A�Rh:Vӌ��p;�6q�|0����H�q�1Rp��\�jKR/��rz��(���*����a�LV��&��B\��;�:~X�Zu�og+6��ƥ������;�K��;c3���~���3{��2��dE���s �E��$nd�[�>N��F�UK��!s#�NJ�ؑ�&i�bY�x� rl}�z������%�ݵ�;t�4��$�:'f�=9�)l�����΢�����Ռz��ڍ�:̄��*v��Tk�,kJ/�Gs�2�u��<����<��6ڦ�o���Wc�
�I��J`+j8��D4'YV�eGgŽYD��w�L�x㰔]�9V'8���u�q9�p&��[TA2�Y�vm�`�_Dt��<�da�R��u����\$����~��H��R�4��(x��\#۝� �k'���z��9�������n�ں�$E�)h������	;d�-�]�{��TT/N@S5)]�.�-/�,�*X���t\��L  �����U:SH��V�@d�"m��X�jS��6��x�\A��I�%<���.�g�n��q�����͗���o���4�Ǯ6�(�5E��̐h-��b�W����2��{�۬&0�&F)��)�;s�!S-���yY��;B�uH`+�������ʒ���]u
T��vz�f����� a�^�v2��(�[(A����5x3�t�rÊ-=WIk�V�LU���S<ڷ���V΃��)v!�	��Q��/�BWH�N/E/��X�c�h��w�����X����~���#�I��D-�����S%Rvh}�$�E�78ԇ��A�!�5�Wx�/���cs�^'B��m0�ٌ��U�N~����r~^��-TNa�y��$�� �r:�ݞ�#|��1�����,���c6E@T�s�'m�����K���vό�&2{��R�F�+!`��Cڇ[�7��*j�F�&�dή�e�����k>�Kfm�An#����Th��!d� ���Gl��/�@"�Hr=�&���w�OF	�� 3~�o��rt��S����rt��ݾ�kh�܌����Yvi�F�,i˅m�`�y�AW��J�C zR�~Y��&�؍V�'(�pP�����%9.��<���(y������ 㚰Z���o��N��s�s�+�4{C�r[Xδ�y�����z�|���&�8p0q_��f�fVB� ���g�����Ҽ��^W�����[�|��Υi�,��5�+R�K\8��{�ʇuҎsX(������~9�? $dĦI/�@=��=��J�4.�k���Ėdx߶ߏ#@5[��B�ZQ4yO�x���b��9���Xm�`N^��F8��B��B;�M/��F�^�T�:��'8�������Nx��*�W0�����Z_tn��'��_�'��e~�i�/8���6�b�� 7������]��#Ͷ�2LB3n>d�7%�1�^��z䐻_J����Dȃ]E�P�T��/�	hcX��ѐ|N�%Y�z�K���Z� u���ƓQ��M��6��O��g�d����#�I!A��6!����z��	�j"K?���1V�yW�?���;������a����^X��t:ցh����b�m?���a't��������C��wTԠvJ�#[T��b���F�>�}�Nu�!B��Z���'̈́jw�&E.�~Q5�7Q��s:�9�j�qM�º6��B�e�c��7�cm�����7����;j��1�=_,�U�J���;M��B��8��vz�#͛v�xbֈK�i��6'�;tu� ��e�^X��Q��~7rY���*����V!ي���Ѳq#���~w;+v�&���P7 ~r:�I��ϘsF�{�pu!�'ei���g���	N$��ă�½�jZy*Ϳ4~Xt�'��x��%�>��gS�tDxɕP�8����=P�q�+S14	/W��ߺ�SRx�\AH�tV9��r��I�����V<���'�G�+�g.-�.�^�7��E���$��b�<bXn�Ϯ�����+ٹE-)����P������x��
d�KQw���o�b�V�֠Ob"Hy���]��VݬcvB2f s���&��[�o���S��/�oc�������/�B�����A2��Y�}%�w-4Q7y�m�=]�y���vY��~i�=�����m�F�J�{p������a�#��ힿ�&~��k��JyN�_mH�M3!~m����%
�c�l�C�S�7ʃj��/t����f��e���GU�cv�5咥3�@��x �W+^�����Y�J�OsF1	�l㈅	��cIt�ʖ���/Xw�~�� ���(a��U�_ͪ#:�����?���$�r�N�e{��R�&y���Ѱk���oD�� Ժ@�DAz��9K�٪�`g�?A����auэ�Y��dv���n���	,Z�]����&��T3٣���H	Z�ck�GCs���o���Ɯ�	�Q�[�M-��EXyPz�������a�2�d%���~ ؃<zl�A�c+c�lٙ�#� )�E���u�Y�OR5~q��X���;�!�$�a��X'mhY���a����w�$�X���k�Q�����E!D������T��7d&�*-��לR0j�Z��[��[8�jM�7����sV��]^����^W՚�ڜ�o?dE�]: 1d��:��` �%���Q�N+ן�����au��2�,J�x�Q� ��
�Je˔��5����C�b�G�I_�}�뵋O���p�oBU���=pM�Z9
E�HQ9�Ka}��)a��wJݬ;���)��J8]w�!Hp��.�e�U8i���Jx��<ibG�s,�RR0	�_^� N�d��yx&i���S�},�������ɏ�󚞱�mz0�����l�rH�>�g��Q�`'~�B�][�Y�kB%��[>U`��1l=W�쓙�98����V��8b�~����<N�p�8�kҳ�As}�_�V��p��*�E4(z�#c��4;k<�?�q����쉣 (���H����"���9�o�Z�3 �;4 !ZVu������,�?1l�R�hz@�ذW*��\��\�i��+<=��s�6[���2s[�kރ=��&	�O$� UɅ���S�A�D�����XS#Ap*��D�S�Z�& �)�}$���uzx*��G��EX�����,�г���L�| 8�/�9pf�{l_7���(A6kOF:�!*���4�ҿ/Y�3ju�,��4��9]�2l�k��O7�T�0��$�|���`�`A���H��3}tX-�&.e��7$�e��dn�^ΕF����n��^�0�r
8eT��=f�4��nM�"aA����;|N�TxfK��ye�B&�=�&��,�1�5;����}�l�WP���rW/ؓ�s�J�pL�$�p^�������շ���>�A52�ᘵ�`�]�Y��K.-����ֲ��O��Z�� �2��88�/:[�]�����鲃E�^�mX$��Xm�A&�t;MT�j�3<�X�S�d�����D"<�����vO���.E���F{�ӟ[ǎ���#�<�x���V&�H�e?>�F�u\?��)�=�n��<@�.C7�-��1���Db�;K���LY�>�K� ԯ|��T����C����N�������Y��^��\Fk�W!qf�m3��(KL}��x�EM�d/�D]�L�e��Q�5�io���uc?|��sL�δ��׳9koe�����ȑ�8��N��rS6Za	��t�-e|X�}�bTӖ�����<$��k;�9*O�ļ���Rexݖ���@�-r��{u��L�е��8�����Z��墢�;�-��\f�|��E:�U�7�WQ���~���+H�đ4�O�NAS���7ҾKj��:��5ނU�Z��}&Q�K{XV��-kF�$^�@\v{A����̏��'������3�����7�
������<���ޅ5ԒiSp�X�x�N\�#�����W��Q�2.����l��	�`e�P�����[d�"`���d!3��3f&II�9�b^�"�J=:/]{e�'xh5��r�mP���q�K���T��Ito�D�w-�7Ĺ��c,�CE<g��N�ybdXʟ�������ٔ�x�D������z�6V�+zV�����t�4mG�v_���Y&�ߺ�k�X�q������
�Fp-e#���~l���g�`W�m6e�Ҥ��(
>;��,�Ww+Ҵ�A�T6�,� �x��+�Af�����nk&�T�Ĳb�QԪќ����W�Ѳ�DR��K�6��ٜC,G6����V$���l`�'#TX�e���/X��
k��/��Q�!��E�@��L�G���2cO��u3K8���^��ୁ/� ��E�T�m�P �Ծ���5{�i�ؿ��4x��A�dƻ����t����B44��d�'�'�A~���j��mS�F�l���'�xYq�"��ȗqQm��7����t�e�?�.�$j@�� �i^]���1��bt��Շ�H�<mؑ��Mt!�;�nƾS��l1M�;00u�$"�o��тv��]�m�7@�d�` \�Q�Cٷ�*9�zy�e�dg�Y	>#"n�z�C�ŕ}�y��ִ��?�bB�ϳ�[PL�Iū�a��HUj��PM&/#��>%�SP�����ZJr���\��ll6[y�x�t�S涐�+��ۨ=�P+p5Y�;�*�P�~g���v�B�fV��n��u;�~�041��;D�pQ�J��.����WBIm.P����Й^c�8d��\5Ww��bIN�����[W=ځ���?'�d%C-�dhET1�A����;�; a��
����ٻ摬�q��@�l�C=�P�\��E��? �(E�����enq��[�Q�V���U8�o�Q�A?Lu����H+;���-�4�(D���}�qI��/�_�b3Ĕ6��T>�3|�S�ju��2�d����[ޘ�f�˔E9��LTf�Ooj|/j5�[����nn��_�~�;WBg:<��x8�̪��	@��m�MV��r�Ep墿K��Z(r�VΆ%T�q��XBz�1?z2��!�4�N���� i/>�\E޲
Y2�Ȗq8�4T������C@��b��[�5�$J�5�\'�4!p먋�K}�+\���O�A���AF��aĽA�U�ȅwgf���Y�v|�q�5�1������]�]�IT9�~����d�����De��\��tL�-���Dcy�a��K�����9L����G�w@.O�
_�b�����d+x�R���?�m=�x�elw�=�;�)g�s�Ւ)�F.C���y�a�;E�Ua�܈���P�c�gf蒗 �rWcc���0���D5`FӸ)�W��J/�����g�	�xa��i���R��eF�U�����&�.��g��Ϸ��n{Q}��\8���&mk�X��S���}y.v�x��L��v��Fx�4jk��S"�Q�2����>���vջB�})Ih>T���w
Y�����Y'~jK�X�sH'�S�]"�R4�%�<$��i�z㱛�#���O�>?:hí�	���Ƨ��r��N��\�`�`a���f\�p���{�+ɡ���FY�[�k�4r����XE�F<�#&-�_�F=ڷ���&Wv�� k�2]����s������m�<�M��z�W�LV}<��4Lꌁ�H2Ld���]S�Ҁ��z>�l�C�n��| �U�R��->�K)�ԩ+���0�x�Չ���2�U���)��<x
��Lv�@�Vn]��@���*�	�-���Li��t���B�
i������/}A�W����7Р>w�Y"��4�r���ǥ��s��>0���'�A�; I�8A��>�M����뵹]#Tΐ[k?^:�go�6��r��SS�d�dL�������r�-�ﻲ#�8ɾ�CN���2�J�2�aܛ�F�0$�^KO�O� z~1�/Ҽ�>I���W�-g���d�<�SBU���@j��+6�5NӞA'�y1b7pB��K4���iy`��B��"��L��+:p����r�j�k�$#�{K�P��ދ�2�+2�!ɀ���gU��'�	r>9��P����ﳔ���5���v��
�X���.��[��P��Q��L��������L���Am��[��y]1�g\��j���	��1�,�"�ex��GOwdiA���Sn���s�W���|�*n�u�*~�t�B)	x
�/5E����4[�_��ԥ�w���ʼ�85Ƞt9�_,:�C�u7�1͍���{� �&N��럟Q!?7nz➷��xe��b=�Q?�Z&>�FD;6?rlJ��y�S�W��΀�҇�����7�5�S$Tq0n�I�;	,e0�(�݀�wZ��Ɋ��«�!�����+.I���N3�ٴןڲ� ��Čĺ�ԥP�p�4h��?:ɣ"�8�B���	NL�p�*>�O����.3DQ ϯ$z��e�n�\J�
�I�"�B �a�<l�����g���T��-j����{kIN4~��n��xS0�<e2��k۟��+S�I���W�R��
[�o�i��,��I��5�ͳ�?�5��{��= ��i('���{����U2@@ba+G�u���];�%O0w���3���-�����IPA�J2�<����&g�u
�*f}[ĆSɸg�vX ��!Eכk5xA�3e�yu|L#�6���WX���_����yz(�31n9��b��4���gt����ɾ�q���E#<L��un�d�	���"���`)<�C%��$�}��Jp4�F�Fh��]5��ӯ�Ӕ���qoZ,�.|��(�`*��	-�x���K'gOmF~ʀt)�V��_C$�	a�H*(6
�@���Ǩj�@���5�s6�����y���0�Տ�h��!�j����X���˸��/�
k`�b�u�h[�_T�\}e�����j$0�dH�F(w�����DM�\Na�Р�&���t�\O���V��k�S[#�ׄf&$�s��,~֔�0�V�})B���?�:Q�f]ex������ct��[����Mɶ��ɱ���"k�2+�yR�Dw{
�P����kMN�i��m�k����?1;	�R���-ÿ��D]��Sݟ]*� �+s����g���Q���-�1�~�����L�c�1By��P/���g����r8�����C;3XDYͬ���m�uv�"�/�T;?̜�E�O�^Ē)�L���� �:�9����$>�v33�O�F�3��.܂���`(��:qw�1]���Z�Y����"�2�fO_�1�儊x�O�����'����u���k�c{Q7�d���qҷ��A(�g��v٫BF��T�V��yN�n����<¡$���N�J �3:wSa�}>PNϋM��!8��QDɂ���%r@>�h���C نe�(Y��1�l��g��I\�CA;��h�)��'��e34�h�I��3/�nƨ��kW�|oh�C�.n}����&�Ŵ��@&m0XZ/�ef�qZ&��� 8���D���5�F�7`���#�ː�@�I�5�dEJ_�/�ij�$�)�.�ST�'}5����S��З�<�H"V[��[z]Eq'U�W��-���	 QT������i�b�Jv7'�m���)Z*����кi�������6��H�r`ןaR)L*׫�dۜł�������[[D���V��~^Q.��&��F�^~r����` n��>��<�g�����Z�#��2Ҫ��0��*_�hv�{���+)��7gJ�W���v�\x��]u�s���SP�\q"7m��N�u.9�?/ىos#[�";L��:��q^�)�J�x��}����/�IJ
��Y�����Az9�$<H�8�����>��?���V+"X(�:vVW�?��T�Xu�K�L�@#�,����K�K���Ȗ6��� �B�\f8>�;��W2/�$�͢��	�/�
������*�
~�o�Gj�!��R�� �P�=2!dkh|��C^np�!�3��L�o)����,�.�ҏ�0]��V�<J�5�Q�MV��:S�����wl �)�ng�f��2�R1�6Cy�$�غ�wIi�)�	�[FU�j'!!t��1�7�a���}�QkS�N3���\��Ј-�l��4���jg� =���`&��Y?�����T��'??�岚�:��
�N�eWɊ����8����6�m�:�H�B�1��?4?@<��S)�C�CRE�b��L���k��V���\�eY�n��ڵ3�?��BeG�L��1���?2uE?�(^8��7)�+r�Q��l�B��?�Q��ɦjB������ɟ�:}"�_�ߘ{�<~N@Yi�Z �Mz�����l����[�ǈSw{D7� o]�$�x���L_��v��V��`qrc*��f�ѐ=͡��k��<%��]ԍ��z�䳓I��џ��<����ԅ��?�#� ��U�6)���1bV��afs\���b��i�C�#s'���ޡ�x�F{�i��W� ���|�ƞf�P���w�r���@#^�>o��F@]��i;���<_-no2��7�6�����9v����E�Bi��lʹ}(�8Poe���9��nG�䌨U:�>�K�P��@�ҹ?����r��%F���y�x��c���/�3e��'��A������9�LW�w��x*� �X[	9�����^��!�ut���l�k]C8K���e�!��2�Pn�<�����+]�q�'��{Z���pir��Y��%#8Դ��h�(����I��\-�B��6�3X��f��_S	�K>b9�B|����ŠL���E��I�b��u����n��0jv�=�A��俄�c��@�7�����1L��|F�/�{���j-s�:�F�nZɩa�	X�E�"�g�6/��I��ٝ����.	�C�^ �$�S��Xe+ϐi?�����b[YK�=Iq�[pF���þo��U��c}�[0Ù��U��Y��`GY|[�}��3Xo�.�d����eT& �a�6��r��n�"��C,�7�}V�4����f^�i"{JA�t�osG�Y��h��T��(32�Y��B�ǒ��]�v4�g��km�K��f������Ʀ θzB�t���R��t�e�oW�VX�![���WN��,��+2$����yw�:^��|S��k�~����-x@g��J:3��5����n�|Gï���p�K^q7$�wa�Ito`$����_����[l�'�����`̪d��1���N��O�B���(w{N(A��v{Mre~$R��)�(�9����ed��̍+��t���$E�'Nc���DM�j�m��*�
\6��e?72o�����6(X
��W^׽8��xE�g��,p�!��ltEJZ�0��Z�>@Ʉb1��%CKk:VUY�Y t�r�f���D�tBZ|,���������G3��y��dĜW�?w��5���1�'a��s�@5�f�� �ӫ$}�.��k]p�����|�}����B�߽��T������MU2V�i&I���m1�*a��M�����5^��T4f?<���ugx���Ƶ��TL;�a �#��w[)�8r���e�2�sh��Y�����49Ob,NIK0u���R�|q�������
ȥ�OF�`0��[S���1�"H:�2���V�0~ѭT� �ތ�c�&�Wzo�(�}�Sd�S	+�՜�o;�"�l�BM#]~q��M#s�F�M.��\�* N�C����았��|��ʏ�J�'�h��L�=�G$�qe !<[R�?��EZ��fi��j��>�fo���C�K�F��������Ѫt�a�n���h-�Q���DH�7p�g�'�2�鐎 ��v�8����9`g�N�W��u��f��#!����w��+����U��P��C@׃(����2��87�c

����V5�R��F��*��E���UK�d�H(���S"�!am*_��]$�/V6"�Y��w����\���[k���463�7����K.��/�?0P	�Z�7v��{@��:.����;��)6-6t�Z�(ܳ��D���M��9���W36$�e�H�v�ϒ��g��7��+��t'��<��	�^o/BJq��uLB[��[�9�䩛���il=��Ʋ�n{j|��]B^����j�Xq�%>3��7:�3�g�+ "#�M�`W��M�� �4'aV��Mʮ�=���[��8�#���U��ސ:龟QnK](҇g|�q�<o���-���+�b�/�h{�^�CP'9�)u���<e�vǑ�#j� 0���̿ /�d14��'-8$���i��W��گ�����)�~�1��78>�ק�GCǤ��K��[pі���nٗ�����~	|٩���t��H�?��P��T�zR�ʩ�C��m���\k��4aQ���͒X�`��췄}�q�ބ��Q��y��(��,3JMK�ڳ��-ڰ��_w�um��f��"�m���~^	��ҽGc�9@r.��i�2�qЅ�y)�e&��+�G��7G��;1����=UԷ������Hh0�h��g��-;�����᠄���^(#���;�p.4�AU4��%$.��m���2�����>$F!X��p9�8����ǹA0	�8E#S쬱2Q�:~zҫ��̓mU4��눚�q89Z�q��YH���i]�/�NK}�i���CWni�(T�3]�b�;M�)���Ne_�.�qn��=�b;_ڵ��5���7�L�UqdÓ���%JS8�t�QP��_��L���N��$�c?Cd'���ŘgB��~�`�@��m���&�N�k�,stˀ��
�6W23?�N
�/���;�g�	ӝR�>,�S�V��%W�#�Z�X���|X��qOt�y�cԹ�Y9TEj,� 9��C)Az��+U�z�_��7��M�O�r�� Z�-P� H_�f�h����6rU����s�؁T���)��m��!i%>6�q�FX���H6(�j+y)F����_��ru�Q?�cM�[O��]|�I��b�Z)^���;v&�Q-�ո�49w}�����a���z9����Q�u�8���xկ������ҩ\����g������db�B��7{����>2�sy�	�N2T�H�����g�=��V>��~nl���O(Qn����m�*S(����V3��(�^n��!�<\�H�0�� �(�D�ƈ>gK�x����HA���ǋu�F���\S�e���ò�f����D�9�9JkT���K�P_�(\E�|���5�� B2uLk�� B�x�7��
m��Bjiz�H��y4k�i��g&����$��M��x��jp�Cp���*��ele�u�֦В�Υ�#��7�����t\����-����Q��:�|&� *�P���D\^^�yFQpMRL�p�������X� q���[��`�)��]�����Ì��l�5}�!����ݡ�<o�|�A<���Z������3�o����f�u�;��H���p���u�浧���FK� �ηL3�U]t�C�fط!#����Q�n�L3�f�������Z��2+�Ro�R~	���������$^jұ0t.�W��'f���T�c�����a�[6�ɎB��,�U+8���w"S�)�8�v�:��y��G�)wt�[
��f.�� ��Q#�Vn����Z&t� �/1?(˛�Ǹ?>�I�����ilGP�8Mz�$A.1�ȱ����0�&�|	+�D��D�մ@-9�\�ˑ�p�F�P�N鵞��2g3w$��)<X1��	�_<�v�b��*�v�Lu�4��ip}�S��0^�)j������J�c�a��e���D���S=`�R�L���w�ܷ+@D�ݞ�j�|-��*������U����KtEa��Fc��rHNq�=�V�g��/Slr�Ep��M�-HH2{�h	����4�Z�L\���M�e^ ��г�E��j$X`�b���x�ٽ3Z\c��+��R��I���N�#�Nƞ��3NbΡvQ1p�%��.	�-O!J�h�M��+}P��Ȟ�/w�ii��-�.�x�4�y���
J�ř�B��7n`(�^8�5 T��AC; �K4�����`��$�E�o{���~��5���������
!k��]����DY�U=Wd0����f�ݡ0����Z�� �З��}����N4m�' �E�3|���9{����t�D�
�;�(\d�L���&D������~�ڶ@�P�H��kH�M��ѡ|�9�rtN��%�̏���n�ߧ�4b�P뎟�|�����5ٹ�>/�5�L:ͬf2��:nsOSF)\�KO4��Tg��40���9B8��A�F�<�Q����3���b=!��ɵtw�^_��� UZ��<j�ۣ�#�8��t��j��0��K�c Y8��N��5�	9��tˈqkQ�����FU�ũ� ��AF旱�%W#�P���הc6k�dK���6��[.��������` �oLj�xa������v�zn-*A��>�^aj�ѭ5���8]	�*<I� ���Z��c�W���M{�iI*�%�S�2�C(G�Y7�������q0���_Z�Ho Қc�e��r�p*��㫻�E?4���5o�)��/ܱ�,;7���&���u#r����m5�1��H�K����.y�rPx�a�.[s�Є��F��lNHb�A]�)�vu��H���C��z�[��;��vZN�+��2����)'�xjk�
�y�Q��Q�˙/�����A�Ͻ}�>jA �6fH��?�RP���܀(�Q͞O����b��,w|�0�l�S�|m��m+dr��w�k���5������A?F��ئ{_�UM�=?u���ȓ92T����r�{W�vyƅ5tK,��uN�1J��8ކ��DE�<�:��M��f�r��Jn�w�s̆��4F�S6��Q���^6�g !x���	��QR-�x�g��I ���ȝB�_N�9co;�C����еh�Y�#�J��M����z6�h�Z5$�vPR��1���Y/�9����q�ҋ�@Z�j��Zd&9���d4���_ҳ��#���h���q*�!���ŉ�=����A�Y36o���H���,30ܡk¹�����5���'��l����T�����3>�aZ�G���xmi�����������K���k��<]����_�}��d���I�D�K��c�g�Y��AXڽE��w�D�i�auoS�}�Z��?�矨�_�CK�VLi���\۷����i�%!��Bb\ZHE�O'�L�ԣ@$���7����eá�jK�-�K5�$r���5�Wa_�P�	?��F���<��*wLTFh��&�/�~��1,,��2F�=��2���ͪp�ςlI_��erbR��w(nÄ�A���� �Է���qc����":LMM�j�+酎�9U�*�*yl8�i�9����-9]W�*���,7L9!X�7>��0���V)�I$��{,��o��\v�Rl5j9�Z��zγj�u]�~$!��# (�Ό��n���$Y���'��@��u%uu���d㡽�-)@��hWH�{l�o$�)�Ux��C����*h���%$X�O���/���.t-�}�Ӕ/턵�˖�mê��ʽYX_ (R�����#����ȱ�͈�dә��0`�?.��=BG�Oxmi��?�|y����폾�R9��:b�U��[N5o��B�40D�����	&��N�X�U@T�����az���T����K�חޚ���^�8� x&	�>��3���m7�� 4�Լ4�X㱖�R���oo�!�� l!z�Y��H˼�20���\��5��X�ɀc�t�1��t�bt5f
���y'orl^fz��$�T6���+�]���nٴ�`M�[����k:�Lѥ�օ6%h��͈����]�����e�3��<��,�5�g �"vw�1��֜6�����}U3m��5�"��m�RD��De��`d�̷�Y�%�B��]A�A�d/)��^���rlL�� �!�$B�ᆦ
�̩A48J�k����Qc:GWpw�
ܱ��\Nv9���e�n1ו�a��@ ��\�^��N����YAʼ�����*��!:g�;���&�D���x��F-�����m���]A<㖏���cc7�"3�S]�3!*U�_��a�4;��n�H�҇�O�E��J�.~]]&a�b�]�>Vۆ��t|/���>��%>M���O^��4ƹ�аAUj�"`R}�X��qb+W0�^�~~�9�x&/����~�������:GR�XA:\�aN�}Ȏ⨜C�X�[�!�g�2N�y
�-�!��_�J\L�A{Ĝ��=���L[o�0���Х���!��-p��g	9��T��� �YsZ����/���7��eq��b`�'���Y"q1̾*���OU0����II�W�Om����@O_س�?���ó�j�ZW��m�^�< �Ʉ�������W���}��J�o�%��i�i��I`�p�p�5�ů�����"/!|p����֨��{39
��Z?��BL��qc��� ?�����I`����[ q�8��R�5�7���S��O�B��YrާI9��$˓Xy�a����=1z�
 
4�zA��i�g��E6u���nt	d�kkv�$I6����u$
�"�U�~�",a��Cbk�(#�������A�#&ؓ�&��'5*��#Є�(�a2�#���ʒ~Dd�
Iyi��K�&�/�J&���i^$���jW�E�����lϋ��6��� T�D�Ef�"):"7k&Hh�Q�=��.A�z&�9v����l�n>~]=��39�?,��¶#�g�)�͋K$���2װ���g�Һ����O�H����\�	�rFȵ��q�Nʗ�0EÙ�a��\h�[rI
j|�l�s��Qϝm"� �:��G�!�i��5����Ɣ��t!ו��Q>����q�w�&�1�H_ƭ"2iM�vNj�*�l��]��td�U(��smxq-z	�����q�qQt�Km��$�z�����]8 g��0��$�G�ݛ���#��L�=�Xe�Qf@�L���ת@|?���-�f �|���̚�*�8�6D��Ĥt8FtP˯���!>�j1\�]���9�|}9p��A����3�VYy�bA���hЙL��*h*��M�R �Ξ)S(��H�@��C兣:"t^���Π�j��=���0b�jmfݒ�|�?]���ԑ]�T�}=��Uc;O���}R7��b����&�R%�K���tC���J�1�E��$#Yy� ����+qUN��k�DY/'�{��~�ۣt�3.c{�$
 ��/�ߒ(�"���A�Q7 -h3�V����G}N�"���}K	N�ь	�m���l�F>���_�vPۀa��W]lj)������c��_�oJ�����}��2;��N7�m�2���.�1�=�CH{۩�^5~]TP�m����E������8uz�~q�cg����xq)�Y�U9�x���=3)����:^oK��JF���Aq U1�0h��[��B���3�{Rh��iH��arMӅ��,?���&zd��9U?������M̄���wM}&��;u�c��M�@:)�2��R��$���W� �.�|��jj����Q�	N��ѩ�ܰ@Ќ�)�4��̪�j��j֙��OkuM㷮'ƿ��'�d_W��ĵ 1 ��D�S%�3����^�D��Y���T}ֶ�"K�J�p ��Ѽ��[k�@>Tb�&������36�=����wl$�W�򟆡�*��6Áx͛�4�����E���3�h�W^z�!����F�� g�K!<T�dw��ϰ�ԕ�GI⊗��d쯉f����k��\u7�?���t:L4���)tBS%���k���5�a5�7���s�ArQM�\�Y���'�b�з�M�u�Z�=�V�0� ^���km�ќ��ȏ�D������s���ڄ40�c���qv�A%|�c`;�<����������+I��qI�s4w�	}o臲ģ,#&z��g]��e�5�4m�-��Γ�̎9h��B��@x�kI�f`}wu��gq*�F�WG�}��k�w��j�B� �Z��v\�]E��q�NE�v��%����@����!�tٖ�sb�bz�n��+( K��4.�ǦmK����e��@û}5���ύ�-��L,9��=�P`W�p�4�ܟ�3 OFi_�+Yr�!���F׏��J�&�ղ�iǂ���o?Ǵ-�&ۈ��0»t��7�L�׎�y�k� ���q,�}������&�і=���4�y���]�n�w�çɄXBSn���B���*�ͷ&6R��wK��!��=�V��e�cX��Y*�v���b����YYc��P�?:��y�-��M��@g���$m��un�Z5��r�M?j����<-�_AYW�+1?��T^��o�9n[���oSr4=*3����o�au��VA�AҦ��䨌t;4�Lu1��p��N����k�i�4�E&�P�Tsܾ|��z�sEMvk`�NgO��u�?y:w����S�w橿6��I؝�+r��S4���޾��?Uԓ��[13����� x>i�����?|$�L|t/�roA���U5���jw���v���!|��d�O3�%��-����y>P�\�T�&&��^@�*j�'����4���L����KM����U��'�0�a����&��#D�l�{(۬�'���rjN�B��U�Cy)��2]RP�=O�ʿ�u"�0�c�.($�k�=o�����Rx���h����� �eBE��͂��/����	|�j��	�Z#��@;�6��'�bȼ�nz� �H��k�	!?ZL̥K��t�mO���KW.UU��&�F��"|<.b�@�<uE-n/s�8��tTt��П������Ё]P�+~����e)�j�_ڟP��nD~w*�|��g&L���m#[�C��3R�ӱgU淝��O�~�d�#�Ny����ؒ�q�	#�����tϴN���~$<�{�ګЈ��\����q�h�%a����A������oV1j�r3Ǘ&���H����3�O�/d�����E�(���ly#���2�=�����Ҟ-���Ђ��JJK�e}������&�7�Hj���������D��KO �B�[k>^ �#��!����uV�ѺtQ�Q�[���d�}�Ϛ"js��#"Z�z��neU�`KF'���ɉ�p���#J����hLM+a�d"G�R�F���۷�!�#8I_Т�~���=Fxe�캳H;n_�#�p�ۋ�wr���{7��J)ES�9�T5�~.Gu�k������x�s��p#�����=M����3ZL�JF�e �O)Ϗ������󮭥�<��]�j�
M�H�&__+�/����o���e�ΏO	��ƜJ`g�V�5��Q��T��H��M�)�(k�� ��Qr�gz��m�i���qʟY��}�^��oN2����x?A�"B �{���?��S~�Oє�2��<�&;V�zp��h8RR���3Fb�g�[����4W;����]}c��>4ѱ��y2�����Τ��i欞�8�+S���� F�D��'�זipn0���Sb(�8ŉ���4D�k/�,�y�����dc���	f�r��PZzjgT/n<RC�D�kT-�BP��
l�9�G�č��Ya����r �;���(�{���z��ĩp��5�zH��x��~˅a?��1};��6h���ƌ�a���7�U��� �.���]�����Z���"V Wއڊ�'le�`�)'L�b%�p�ǖ�Hu�.��`/�q����Ny���~ȁ�عW{����sy���/�&�_���������I��)�_����X�h]�~�v�ๅm!9�]ƶ��k�.0�zN�1Di��	)��-��� �2Γ����?�n�F�9L�f����;md��㗒�SLH�ui
3'x�E|��h�`�"vӹ�$I����Gfg��3� �K��%wP�8�m.�p���.��ƨ�t	&�a}3�+�g5���:�z�J�qL�EeA-�P^:[�~5�(�����6ϐ�I��� ��aphe�1l�^����B\߲�V��E��Wa���)���Dɷ���<�f��|��ʤ�� ���>j���y�s! `6��!�/ׁ[`���례>3Q�dd:�$� K	<�ܢ'D�3C�޻�ք&���dt:�~���Z���*�z#�Y�Ώ)�	5া���z��l��cr�!_Z�1EmJ-�> {S��ߜ���H�tA�X]���My�����;��j+:�8KV#I�MI��S��ـ|�耋�e8��:��>�Y���yaW��"H�]U�9��V��5��
��C�M��n�O
��_sEh@��p{q��Z� ����`�������_x���AG�;Gz��TZ�D�`�ڻ�JP+�ԯ��Hk�^����z/szP���|�K)�k�㴶��`T
�V��t�)�D6!k�5�?E��{�a���嚻�5r�^P �I6\��J���e*��:6�܉a��D�8�ʉ�'�,n�F�B٘���
��w�	��R���%   u��&�a� ߥ���R�<��g�    YZ