#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2768621730"
MD5="3ab9a09c8ce48f0672787ac7fb711f07"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24952"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov 15 13:06:48 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
�7zXZ  �ִF !   �X����a7] �}��1Dd]����P�t�F�m4^,�e�i�Ԇ��.�{�����k=P��D�}�!�-�'�w"KZ)!m����J�="�	��m�d��E�Ov3v@�L׮�s�D(�@���n5|�$�2��Φ�i��:�~��0��o/�Fg�%	�o¹��9�?2��#d�t�r��ĦOgC��T*�}��(��_^���ݩ�G-��q���l�i�V�����g�5���߻bP��A1)����9����3�^��B�=$�}#��y!K�@#�9E0s�7I<����ƌtr2����x�	pb��	�*	X�!<�����`s�@��r���;�D����ǘ��{��kO[ 5�_Hg�!�>eu�`�����x1�m�}��N��\wVZ�4���\�{2<����Y�/�t|�����:��ܺ@�)`ǹ5�4̹���Q��R��,��E���?z7����d�*v�Ti��	 ���!�J�ڢ�H�D��iV^�����業ocQ���|N��/F+* ���}��w�����GbB���;�M���lj�Ul�I��Ek����b5--��/h�=�r������A/ &�A#��+��}m�i��|2w^��ᄒ`�����!����3��P3{���8[$.�᳻Z5�G:$5g��]B�x$��,��bq�Vg����t}d�x���K�JxJ�ܝot�a6l%���_�By�|h{:V�Qm�����'��@���̣3�ѓ��:P>��P8F� �NU��}��X���2�g���/Xe��!�m4��4RӮ�!"Q6�V����s��
;����ǝ�o�R#�/GL8�����0�!���op�|�W�f�ugc��+ ��k.�T�<r4q�L�Eo��x�93xE"IA�O]ŧ�g��`��ݙ%.�j_�!Pƕ�4����aQAM�ģ\U�$M� p,���(���7��iv�d����߅֌!��� ��S&��+�nU�8��Ci���\Ei�=�Z�=j�	
����0���s�	qm��vH��h�A�#�$^�xk��F=v�-�8I�j����q-�4�^f���'N5o0�#i�r��x�[g���^���cc��rTS �+��vȊ�:�W������C�La�e��3k���@mH�-k����a�����um"l�~���%T�n�!�y����n=��Y4O^!}Ƃr�	?P�<F�d�����[�Uv�Q"����J�2�x��E� g͘|�8��M��ޖ����@�6��5 �ϻ+ |`d�Y�?����AK,�����[h�L+������_(�@�0�!$����i��hL^�

(f�~uOe�=m��M}Or�Iv^V��h����M���.�#�M:�K�ECtZ���#�}4Gu-��������g���S��һ�`���%�B__��e��=H�R�pCΪsM�6a�����Fr�>g�;	NU���� �G��k�mC��V��}��7J�C���8����zU�X����j�D���qFKv�0��7P��q #�ٙ���H�AL��'��M�ܧ�y��v[p�	�5��s��� �P��s�f�`�_��:\�Dզ �������K�s�0O�N -��yƒ{������f��#i�"����ۣ"s��0+�٭mg�;�ܸ����{e[M[�`����k��%��f�{7�P;���g�0�9����-�Cם+�� P�%�T멉̢q����>Tr�B�VNjZz6��]y��v�]��x��{��"�06����Rj`�O3�0�X�Z�
W=�u���H@�5Uk3T�Ur�`'�!�\�V��6��.-���}��Dj��ߏ��"�
/H;a�7@%;������@�W�_������I������Q��o<��@5*�KD�6$ؕߵ�]�3��[����5�t]C����wU�Zd�	��E���UT�J0ő���Aw���e� �C䱋|�?�;<�O��g+o5�h�;B_�R��[��Y�b�e�[��ģ�������z�$d �L>�F2��;O��!>��Q��
�ӏ$Ǹ�' ����W�z@��eqk��B�lA�1A�0n�2HJi���`���!����y�fo)��L�A�ڗ�p.W��nb� 8��)y�k]V� Bs��$?:|���fovt̘�R9�z�Fb���4x�6kLp��L��6M���;C��whxC׼��8�~i�a�|Ә��x)�������P��W_l���p�`��񪾹�EK��	�I��T����R������!G�KvXF��@���P���p�+`ĤF�wR�Z��H��4������7���r[f�c`���H��F��!C Ӻϐ9���Ig6!��.��[�y�#�;��*�]-����,�s~�ϗFI�Q�L>5��!�}�nZID1
%"?]��Ȁ@h�!3�ï~�ƽ!�t��m������m�OR�ǈ�Ⱥ�&J���rH��M�/B���&!8.�t�N�������rXd"Qg*xi$=�`�?��;��5� �;�d|"y���Z� �U�p�$,��<+Ύ�P^N�;O�z�؇llxk�)����+�����͢�b�n=N�(��h<Z����X/w�f��句1*֍^8G��XÚ�"H���*B(�W�N�i��\V~	/�3}(�~pj��K�� X�8�<4�w�xrxO���l�U[�õ�3�G�w=w`1���5N�|թMJ�}K�1��9���M��ރ���XK8J�ڞK�kwY ���g�a����D����_���x*.��bP>�N�6����Κ��`�5o<̈�ij�Q@R���W���a���cƬv� =|<��������nJ4%����0�a)#ɐ>D�M��p�R�ɟ*���n|4���z[�i���+q�N��	��%LS:,�dGE:�ݜ��;��h>�"�����m�p\��4'�G��̦�O��ռ��� ��x8X4[!3�4���թM�0���\{wv ��h��o4��9߭���e^l)ˬ��ߎ�Y�*��`�]��|\�^+�֕tQ����T�N19���UX@b����,m��V��
agZ���҃_5�/Q��r%��B�߰C]��6�}����N�d�|l��S�f����f�-�{g�3�Uo�(��V߸�0�K��[)CI(�,c�vI��!��wF{�Z�@+��c��*��11OE2P�$�"|�Z�������GO� �1r۰p��|uF R�-���L)�����
����_�8�w�R�e~0-N�݌f�i���|�<%�5W=0�$�w���j! �����/U�H�3�)+�'�^��C��֭�z	�'�������r��5ω�v�����${��4Ttg�v[��<���.�8?�2�����>Z�k�]�p��k���g3}j�{��l<"�\�[<�A�O~w����0m%6yb�s�H���֗^���&T�dI�a>W�3v�c�sJ~����~��oo{f�]�:����t�9���%)����_,F-b�u��TY�v7�Q����]�X��A�G5��)��`ԑf�[�&j+UO)'VH5����~��d����y����	������^ZO4�D3k�!b�����|[�?��.w5,�Z0�@G�ۘF��k��n�$ck�(�
����t1��x�lk\y��'A>^��y>�����Z[�!|kn�N�#N�����u��{> -�n6��j܍w`�����1H�C���U/PŴ�VY���6p-h1`6����!��8�;]�ܴ/A�}���y6���S _��lm~��o^ߋ������,\��T�j�4���E(�NGks�&��>�z�AO�� �'N{��v[,)�:���rF:�b�R�FA��v���=�5T��\�MM�}��[鶘M�߅v��|ω��Ö�h����M�-Ij_I�FHR窹Cm�UEQ����bOۿ�� ��x|Iɦ�DI�L.ۃ{��i�v��ww���u�������~�SmL�wY^Vva�1�������xkU��W���N��"p{OS������^?�oAN�<������ �O^Q���
�%>]7G�L/�Y8ؔFL� ț���Y�=�rQ�bD5��G(��$u��B���ܸO7�]�'P,��ELIX�
^!9ЅdG,������Ջ��Q?���Q��n5\L���b�;|�`�c���u���}�J{)V%Q��jP	�eʚS�{�ً x�������>	��[' "�w?0��c)���;�D��<{M�ݏ_��U'i���yV�0$vmA�|�� �?_��6�`��Q*��^v3�h�X��OS�L�3�,�ڷB��-Q������X1��/Oʌ��C���4]�QN2<\�\�lI�72]1�.2I/����D��e���ǒAҙ���T����a(X~�7��K|�f��l6������?pmO��Kj�UB汈K"��ЌV�Q��53�?;�ў)C���E�Z���m�1g�Vz�Py�fa�t��$dv!C���-�5��]�}��69���\VJ�R|�@*�f�r�\���D;fɾ�(���Ͽl��Q��y��w�����y�^�{j�8J�ϕa�����!a�8�.�K%pmt��Ч�m}$�3x�{<`�����1m���ҷ<�g�fࠋc�/�y4��Ve[�|C�(˒�f�m��*&�E�:�V�T->���8�;��fCg�BC�g�t���g
���iɊO���s ?��R�v�k43{g�'���N�-������Z:��<�,��g��>' |	���x���h1�n^/8R�{_����(�5����/~^����֕{��:�B�X|7��#O���MWf�bIF��<����A�9����9ڌ�� jm�&B����v>��QьbF>&���|��)Y�F����빿#-�yI�����PONFF O��1!�]�MqF^i�?��s�qb��㰶������0�:U�
��V�E���!��>�"��f..4���|�&���w
V�1�mU�E��v�?��"Ʃ���JGfߨ����Vs;o)��F�*KWc�rAӚ�� b��2O2��̵u;�ܼ0E�d��%�X�	��F0�<��De�iK����00I�	�,[�����B�<�mRd��$���7��C�_�,��K���3n-i�v�Y�t������C6�%h
0��c��VbTR��L$T�_e$W>�\��[�g���͠0��Z��I�ՠridŌ+y#��5��d�6`���ҭ�A\t7�v�Di�С�`��w_2Xm].��ב�Uo�\�$���b(���w\\��8g��x���r�W�z]Hks�U��J�}��a)�_��تzC��4K4��0����������}�+��a�W��|c]#hpfb��H�FT�_�b�m��{�:����V�n�j#R�V��K?5I�oR�T���4���*"�o�So�?�,��F#��7�6���FA��l�ڈ)��)�g��!��oH��Z�[���cY}s�DS&�I�p��q�n&��7�'C��m�&o��a��i��ĺ��<�7 �[�h�JE�ԼX �F�����a�OI�ڃ�}�8\��+���
�4�q�I$ZDTٌ�yh�Wx�/l��+b���̶��'�Ey�"XPGBt#f��a8����n2�����4�CNZ��n���(�a_C�sb�'�F�����1`��j�
�,�����rK���&�nW��،p`���"��*��'y!�u�L��@FTj�n*� �܆D?q_'olպ-�Em����0��߮\#W򢅬��Ǵ�]�#��@!�5��3�O�V��eu��hg̊;j�@�c���x�Ajy��Sd4��7Y�:��آa���2gIߜr�$#�w�r��|o�MFԿ����
�Z�-�C���$2�bG���i1	zF�ce�.D��G�;�G�k�w�2:��!�XK�)���}�_���)rp��j w�q_$A�Ze&�����Z�Q9�p�"���{��(2�kRzY��$xDyX}Mv.�.����C�I�L� 
�$w�4vbN��]u��nwڨ[F�,����sѹ��Fm4�����ׂ�y8�4j"��W�-3�n�����1���_AB��CH���U��^N���*'�1��m{if"��A�S[�3� OhghJ���r,��u���2,trjp�'�2~oЏ���F��-5�(~�+�����4��$GǞ;nE���)�{UT�tz�4�j���IPJCdV�k���.�^��ք�f��"[o�t�)�)�0?�9&}H��Z~�M����>�{�1�ұ��߶ k֣|��\���9�+)�*��%��RP`��@9ZJ���Hye ����Z������"���2�#@D(@?��)5�Hhfү�΁�͊$	<�qc͸T!���q$�xa�"D�@R=rQ��}�8��t2
�˒�ǎ��=����p�����,9�7��'DB�3E ֕�^]ӡ�������K2���КG��Ryr�C���y�"bt�I�L��K��-�8�ת7q��|Z���kUtU�84�,5;`zA��X��ʀ�g���613K'�wú�YT�Ƌ>�(h�&���o#&�$�*�� ΀<cy. -,rm�J0�=��E��.
�]ƪ����_{Ҵ༱��Uƿ�,眸ʞv�Gҭ>"/�1�[�	����BY�<�J}2U �%w�������hU9��;�4�	�EiˇT�v�s�� μ���̃܋z7]D2�ں���|e\(A��I�0w��k�74�(���Z��S{s�Hh�1��j#3G>�=�!�a�;��z�������G���YEZ^��i�3~�Z�:7������&�����_�I�zӚB��D���į�=�~ [k�o),�Q�?9�I??������	���>�9M�X���(Mi�)����=2z�Re��(u��2���A̙@2lYV�d��,�|1h��
||�!?�;>(��!!���]ս�8�����r|��Y���~_fO���<4�9�ɱ�[։�R�d�����a����l���V�^߲"�I�-�O �N�\��Tҥޖi��,��TC ��	���A|�o��Ìd��Fƛͽh����c��>�+�+�x���������if�m}+4��ғ���%��D��ѳ�����]G���٘�X�Ɯ�P�p������?SO>��������}����9��&�ʼb�?b���*�T��-I�F0 ��"����,�":�#��D3-�"Y����G�Î2Gc�;��cVFI��}M�C:��L���}&�Wly�_��d�]�}z��+�й]ql^���&B��p�5�&�����/��&�o�ܒ����]g\��F��(ű+��X^s�6�Rc��w��OTh�c%�f9&{�j������u�v����?� aKq�3aë���`+;iK�[*�ɻv(�Qٙ�A���ݤ��z$���V��zO��aG�)�JC�尷+���c�@̘)�}aw;-�0OIr�돋�4JגW�O�q�����;Fi��=�W��@,J壄�_�r����c�Mz��)�>VNcsQXޜ��
�s��6�1�KW �qij}����ݐ\ڔ�b6k�'���0N'1�"�~�B����@�3�5'J���|��HD����q�7��꩞�5>�p����f&�!,��`к)�T�9��`�p��\^
pP|�"�b6;�-�htg�1r�vu�����8z�}��{��;�Ap��^O�Ɖ��X

��lk	w�p�!�)ݙ�:�^��k��6D`͢<t<p���e�)�)��kkrc�qʞ-�9N:3��Pb,\l�lJ�hP1���DHXw��a�p2B!(�k��=p�{W��~���4)�A��� T3�x�YY��ߙ�iš�=���g;Q�Vr3UhAg ��o1�0|R��R�06gc������;�����ן�l5�ϑ�'���o*�A�2�2@���[���<)皍ص���*�E�(�~���(��$�ꝥ�㴀Y%�n��s�0�Fu�]<�פּ�u��+~}�B���q�����VupL�Xs����l�r��_��U���+t:8�Ev'�[�^pG �x/�J�w�:DH�]����ꮖ��/p��`���������:Au$ڣ� �S___��u`���fK�8����\�cE�=\]���k�d�R�1ɂ)+6PAߠd>7����x��.��ky��}���3|1$.�-�a�N�cvÙ�x`W��Z��:�8+�.�F��l�I�+R� �'F���ص����{����a�Zh���= �OQ�Iv�2(��j�IWM4�zc�)gP�Äm)��f��/�+�u|`��E> �c�-32�$Q��s�"n��*���vR,ғ�N�`\~���>��D�V����a����z�e��ג��Ù6��P�ѩ��kW��qj���@w��k`K��o��^$ �3�){_�35q���Aӊ!M�����D���}�>
L���&�����	�jDB�bB�m9����ǀ��%�2f?�P����=�3Ҵp!���޵Ǟq������-��IG�Q��O�)���g���Ɓ�Ыm��Ta Ҫ�I�>�bA���F���I�}�w2�$�D���f9��k[xVi��Tz�8S�����=�k���x_���%�<I �GdԞ�|'�~pl�Խ�Mn� �t�;"�Yb��X{amG�n5p�O�z�l�938�}���A�!�óV���L�"��;;����@��;g�C�˙3D#��6�)�R�M;�D+=Z��<W}�*��m� �ĘvY��ı�l�m��:3S˫�-D�7d���C����N1 �X���JK�M[��4��/�~�R�������v�^�q���,`t.	���'���Ŋ���3����1�a�qT3����� \@�6N�J�.p������e��{i�?幞}د��޺$"xσ�V�E���;���b��:��ʿxC7{ �[��Bӧ�4w�@) X���d�����^� e=8�ZjcՏ|9N���6���Ep��V�{a�`�L��R���>���<3�H ;��o�\�tf�Ł��
��x��sV.v �����$0\�A����f�V,�qU�df�ry��l��[Td��s�ݺ�@o���3>����\=whj�׋���8a�,����Ǹ���bh}{y��&#��#�lt��{x�40�� ���]5�G�)b�Q��oD&�h�> �0���B���}aD��]k�?(��n�Tǒu]�m��I�ђ�`�T���e=���?��h(��)�b'�����d:~Ȑ\���N����	�н�q?��7�@@��úv�V���E@� hU�ڸ2��L�����,�z&&�;$¸<�3���v���B�d�/�ͮ���z{���D?�R+��� ��WX�X�+pp�n?��0Ωr��������Թ3*Y�|�0	��� �&�8�<$��:F꿲�+ID$FȆH�-�ۓC[����L��c��'ho����c����9�з6CKe��,�*�8*:�E����7����b�ǎ�w�v���[":KY�TfoE��b�brdR��j�L��_r�L�<8o��z�'vgKv�#rHO���#��=�`�|*s������!���a����GY�E+���ԣ��Z��^�WP �U�%�(�v�;������#���d��{>X�������QO�v�2�g�*b4��Z�|&�pő=����i�7u�SRT��5�Cc���^H$!�6�hP�3Q����z�wN��h���~3�Vj�K�+$P��/y�x�XU��&�I��
qj�kKc�Cp4��D1�?�b�3���˱�!���q���a@�?<g��g��Aer��4�=��(P�����$ӱ�7�'�z����2SAxS�C��o���GsSp�ȝ�=v��0���V�v�H��/(;��z�2�'���K�b/���v�0�y���L��U!aF�:7�B�I݆bfu���Z�1�}1��?�ޛ,�)�k�*l	�E�"t���
�X�^�0o�/A���$MN��y11Y\|��L�{K^��j	�-:��y�&���[�\�t�owo�p��m�ڜ`G	�oc�]Y���b(� �dD�FA�O����gސ�`�g�&8=P�r�3T�-mH���GeC&������3y�1���P��AXzM�� �6�\�Ǹ�E�H���uS���PS������=?���W�JXY�ű"5!dl����4��~
@��~[pNO�hM�*�.Q� .S��AbPoc2Q��f*aJ"��x��&Fn�{¨P�Ǒ詗97��/;�6�)�o����E
��qB�zZo)�)1��}EL~Ş�4��&�9���wMI���ޮm嫯Xf�viGur�ˆ�6��.���Ϋ���:�U�+��2�Oy�*��$�����NC�O]�^� ۅ�ϟ�gequgs���#��$L\O|�0��l^T�d-�-5Ҍ�A� eyt��ٶ��UyF�RD��
�J��}S�$Տ����E���X^��t����	L�[�Kؑ9C9�� �G��W?�V34w���¼q� @pw/F�;x/�x��_�yK1��j�q��5�a�(��$#q���~?�E���T��,y��-]�LP���j.{
�vXQv���>z���ӹ�dKڊ��9������؟&7�2aK�U��|�B��b-�6yv��C�:������{�K��Kx�?X!.񏍨��b�h���/;���)R�r�zQxK �U���6&�q8r2[2��Y�5�e�w�ks,���,V�c3���Sb�DP��d��j��Ւ�$g#oBL�ڱ�FDpK��IQ��{-�5�gL�HM��8�V�?�l?3�j8[rHN�����+.3�G�3H�n��>���:���3�C��]Eo��4�����A�q��L�.v/�w,�����.����>3�dS�N������e�*����/�T�כ�!��V$	���K���ڵĥuR�)�]�=v���5BZ���eۢ_�(�Ԭ�]�W%>���>N!��d�v7	$"�+T�o5ĝ�Jǐ4@�$
�3�r����O?��	�M�>�JWᎏ�
ϧ���5W�|�L�@�����=��ɐ1ɚ��kk��9ζ�~*$�s~�1(U�7�L��u��-Y�`�L��0���TC|�vB΄�LR,b-�G��KW��f�\��4�4+RtƹHS��~�p�B����S�����GQd�(aG��[1��^�<���?a\K@�X��"��7�f��kSxxS)���$�G�Fק������ú���>����`��t��yz�ܨï8@�6��L���!G;^�Eg�Y�5�#�0�ն�Z�y��$�[!��`��������g��)��ݻ�j�I��� �^λ�@4m��v׫e$g��I����H���<�p ��7z#c�7���4%J�/��ģh���B6�>7�zF���H?�`�H8d��T����4��ߋ9���K�/�'�F�W;/q���|(�RxV5%��;	|h�6�$t32����f6���fpYmG�9�Ѽ�?����ǆ��w]�۫��o]T�r*"u��`|�9Y~*�+��ಈ�n%[M[:rXW=�˨�*��~��Ì%ޗI�K����J�XpPS�|E�Е�ų�Vg�~���.F��wO �m!�=��I15�Zy�������S, �jc[V���X�鸏�|`�sz��H>2�<SHwA�(.2�ER��5?|��92s��?��`Zd!wj-V�L+e~둒SC<v1$_���c�A��v}8���JՇ3`����V�&C��i��H(7sj%m\l�^��1��Ωi���Y���^�1Pd׏�w!+�t:_�B9�@x{��B(����5n���b�r�*�[�HIBLaTXE���S@�h���{X�NCi݅��jV6 ��V��6�D���#�*BS!����n������y�6��W��Lw�~T�?���K)�.���=,xR��#��6f��\�]'�P۔���ѕ�z	�0*1[��A�A��ͳ�S�M�+"e�qǨB=��:f��V{p�pq*	!�.؜T�V.��*�R��?����৞�� $��{T��/Q�~[�x��8�
8�eP-�K�,"���Y2T&�c\�n���������͐�g4���B�^j���
θ�P��A��;�p�TCWZ�5� c2c��Z��RN�m�fjt��q0F���'7?캐/�{����X�z�IH�E��wT�sY����е��>���+�]8%Q���k"�pҗ]�됕� ����vQ-��968[�O3=��=���x���!P�";f����'V�\�@���������Rk��?�|jh��[�s�?�D���^1��/�-L*42�&u'�1T� G�ա��R�)�3沙	�u�WH�ӥ��]#:������YG�'�Ԣ�f�N��f��Μ!\TD1�p�YQ،}/z���������Lt0�s5F,����J޾�,�#��c���R�aq�M�	c~�%Ի,������趡S�l�y���k��Ŝ���
&��P*6s��)���Gw�%`RA��9=�C�鳯�ۡս��
>nd��LJR��?��ZBF#�ɰ��@B1������o�h5�ӯ!<zs {�>�?2�c���;QB>Z$���A#�׽��ӄtjWOhkĺ
(tJᩥ���T�Â���L��:��Gq�E6�f� ~J�X&n�ߑ�bw�j�6`b���=�	\��L�'vu�@<b^a�� �܃�DH�c�3�"L��V(T1m�M�
�U-&��JYX�"��DE׶m�O���e������]���M���|#~)��q���Ոzb�n��ǎ������edz!��� c���>36{����w������Z��۩��gKH�����U�;���]Z	��Ugޮ���`��hꝽ�q���"���	N�������{������i���a�^���m�/��L��+�n�����'�	��Rh�V��/�T�e��i=@|&�d���9O���������_���h�%�{�Ì�q���aq��>��	җL�)S���̒�!���m4]�"ꓕT:�!c��0�N�ú�Od�y2�,k��n���n�7�鳘/ ������`�n��s�\;��PGK鋰� ���i�A�^'�Y��T���;��Zd�Y�0���S\޺�s�"���J�f�8� ����U�K�vS�SJ�|��v|X��uu�مb۔��GD7a9m4.�<�� ����Aa�m:G�A�[���e�daGhE��U@ts�8BF����\�Y��j�i�N�n|��� ��T���D
��+�.'���zYB�S����Ӿ� �Y`���J�@�$�qQC�$F��ǗH��D�)�T[
���Tۂ5E����~䰅�e�Mh�GΚN�B�I�����J�����K���)8��eEb��R;C�o(�ٮ��Tl:�a�.6�����0<�D�I�?�cq�{�4k�3���a��k��YY>IP�795��5G<rRf��=Q�0?$?��]�8G?��(٠��K"k�[5#�L,�3�V��>T/U�L	��[u�/�PB���N:b^iy�f_�"Yx��ѓ;L�%6N�����S�g�����8p���Q%Tx�59:��7o�&8jܒ4���:�~]�hpi�fcq��.Z�?8%$ٛ�3�q�Q�U��Z�nv{1����^	�.��-�U�IK����p	�S��I�/�f�&57�0�8���Ƞ��S�'��/��ܾ�O��G�N�-'Έ��Q����)�L �Ά{�$�j��˙�>���I��X����a�e��z���2���X�� �k�
�Cm3��~!|�l=6����A���k�C��lK�� ��|� ��8�+�v��=�BL��,3b�L�ǿuPN�Mg� ����u�|[��9�y��J��g��R��/k��u�=�$���8d��'���u���̓�_��4�Su���O�� �n����.}��[�\���u��IJ�W���p\��J��E��B,�٠�k�Bim�'\@!��8w}V7�
Y�m�{cg*>_ר�GCe"H���#'��W��O`���BhBjK�[^!���/,��A~4��	꒣C��?� 5��0q\�
�/q�"cr�ڱ}3T�֥�Yd��u��Q ,QնTp�2m̙�����q������ A�અg� ±8W#Y#�'�X�E�`�O��c�)�B���?%�u�K��F����C?�;��n�g����];���qو�s���2�`�xK�>�)�Y9�^�=3; U�E8x��ie!�1�#�*[�n�Y���Yw�
;ư`Y��Ξw�2tKY�=��F���;�h4��3:$@ez��ck�8�B�Ao~K��Q��9���U�\��&�إ��M�Ћ��,�0�����|����VJO�<�TҪ�jV#
8M_��b;�;^����nذ�l��9$_\��}�M���	�����P(����CkϴP�����>���t��E\r�P��N��յ�<9t�����}���jjL(�mэH� ��ڽ	�b�A'���j�,��>�c{MǺ"f��4�^�ǎ$����H8>ZPcC�����E>�V��c��XX�FK��'�hm��V+�%������!d��y	2�0�xI�����=}��q��v��BF�Anɯ	�L_�c��a�-*����+���/�YL`���	�<��^R�=���؛�
aO�'��t�
iw�q����8�ͨj~ܒ}}����
�Ȭ
b�3�U�0��xA-9U8do����rZa�cG��Ƥ���usS{ډZ%�g+�L	�+��=|�؃;�0�L�����0�A_�(�L_w���ޕ����q�;N�+D��f̌r��6K=���u��x�V�(�F�N��SRRPܹE�I��W}a&��S+�2�>��j!a�p�2�ٓM���@§��=��r_�A��+ȀZM+�5���fT#�ka��rCK`�R�ƋS��|0,�Ӌζm�?mb��j
�ǐ�Y?�{�K��?/t�Fޠ��%|h�q@�Oa������Vv���F�� O�%[�'s��	u�n� v���H� ���Y���ÿ�[��RdD�g���h�p�@��-��O�2��R�e��T�=t�Ȇ�J��U-� Rf֑��D���360�b����V�~'��O|ڶ*"hv-�p��,�i���gն�j���jr�M��1��a�a�c�we���_��Dt@�U!V[9��CE�J��]���r�'K���=*T ��!�a1�D��Qlwh��#M�١ج\�kM�v�
^�4�19��c4�y���r�D!pg�ê0�Ɠ�?�Z5>E�Tr�ˡWp=j�\U�!�9�o�X��$	I�, �Z���h�#��zzck��h�j,i (᧰���Rn�-PҺuqfo�1H`�&'w�����̚�=��^�ɣ��-�S��p��z�=s��j���"}��셛©.�K�TP�f-�v͗ਔ�!����{�׳|Y��]���L9`W2�� �el�%�R����VoJ	���NmF6k}��RbA{�#x�Ṋq��FWt�f����z��#����X9\���"*�ʧ�Rab�؜���0VH�ӗ/�ȑ��CJ�i�@����x[��^g7���JN�\5OY#X(�� �����u��ҫ:�9k��O�uT �&� �|��Eޙ5��՛��kx����i*;�� �H0���F;��m�9a�y%z&���%��Ē��L(ЦA�����0�y1���T|��y�p�J��QV�,��ܑ�j�[rϠY|f�M�zt�а�*,��|Bn��˳�6��/��,�dʢ��G�iN�#��ε�ۻ��T�4)=���B���}J�}�&%�.B��krقS���������d1�rj�_^ܘ�㮤]e�	,�O�O�a����	��v�8���힚�W�)U@{� ٿjNr�ˆ]m���Z���=8OeQ�RD�2��+w0!q��$�s�������w����rOa�����ksi����o��� -d�{ܼ�)��[��Y[�S�����v��P�4P1%��2&��ڽ�ͫ]�3ϋwdP=؍K��J���U� NƁ(�G/Y��a�
3|:����U��N�EO�9�Ǭ��W�9�w� ��C������P���/eOWބ��h{���$�%~[>��ۈw���5�2���HN���Oy�#n���əa�z���g-�ϰThۗ"ia�"�b� ��\��T}�����e��z��YNT���{��Wn�c���/��S�'/Iu�G��N�|�6r�Y�^����/\�u�K���B���kn�2p���(�q���Ct��
k1M�����p���;�G�Rnb~@E��98c�e0�
5��?�WZ�G�{���N�����c��ay�z1<��.ڋjpi�����gS�a֩B����[K�=�6�H�M�s�տ�H��#5C}��6�}b��4T��lO3�(H_����:��v|�w�_�K~�W����"��wu��qT;Z���]�Bx�tUd��6���@]�n�C�ɔ£~k����a6�-�<HŮ����U�e�#����\6��Ë��
p���HB&�x�t��:a��WlK�N�i<	�'PQ-��c����X.��&-��@g��yz<�O]W^���
ԃ$�}q�:��RA&�I�w���M�B�c��hR����;�L����Y���fCW�������+-}7ӫ(�N��{a�1X�����^��S�����/֎R`~dq�*K�R#��D��t�T�r�x��V�cP3S��D�Q$5L����T�`�O"�RoR$!R�^D�sIa�R��!@�^ѭf>,qe�fC��.��)EQI�f�`D�)D���2�5�Dʷy[&AZI�	�����k���CC7�%��q�֐�T�6�V��S�`Z
;�2�Y%t�(Oo7(m3b���G��0p�b���D�s�5�!]|�˗:���R{{�ɖ�bC w� .<��e���v�3��܌�	%�%][Ͻ%䍶�A�������Ƶ��c���
6�B���UN�hq�l|�^`��O�Մ�\���u�A&S����r0ǛN�� ��N��5���~x����v�������q�,��f�	�����j�Wp�WOx6��N3�a!��IEJ���Z��;H�
J4�c�O��gS� ���w���UI�q����QY�����O;��8C��Ļ�~�RÄ��6*�\"����Iv�9��C��n�ϭ5�B�3r(w�4��wA)#L��|��b��L-�2��tN��^Kc0���7r�Yq�Bp�xj���it�������N���fcP}ݨ�m�JY�C`�oT}����D�=��t����ɶ������-@���a�S��vk�L�'�Xu��#��on���_�&�I������k�o>qn?Vj�E'D���/�؇jV�M��r��(��q�ǒ�D����<�|����᯽ L�V-]�p�eO�:��d]ު8�u�F���mIT��P�S-���Y0
(|4�9�NW� �Կ��E�D��L3�7�a!'��Mc��]Z�9�O��[F؄�ᶛ�tN�u}jz�=UV:9g�9�xx�4�1�߫�(���F�ׁGy�D~���YZ�6k��S] Hm_*�?Q1�%W���OУRu�o؜��hx�+"���HLg0���l�ٙ�y<��aP$Ha;��$=g�]� �,M��b�����m�`�.���͒s�N�ɵe��i��u�,
���Kb�c�IP�]�QG�T�Z����T7�n}e׵�*��&N��J��9&#h06�?�c�ߣ93xM�0��K��]�MǚT�t����[��X�<Q'�ի�/'��ݰtc���;o�mN���js�?���F��nj
8�@A����h�����N\���GF=y���V~�	'O_/惙�2�{v�&��)d<[��2��7Lw&��[Hq ���i�?���K;��[|t`
`�rj��3� <N������1,�z`M�A�Qs�6�R�c��F��6��xq�'R�K�I|;�	�t��O�� �e�(�![��d�`hn�S�܂�FK����$a�m_�Kᕣ�B��@�e�;k�Ʊ�h���Vr�"6H:BՑ)�&O����y/	��Y�.(�5�������P��O%���?D�H��l�8y�q�g"�v�
��-k�1�ZI^�J���k����[�(�������]}4c�o4���V�09��2<�8%�:�Y|��p��:�_)IN���6��(z���������D4���<�n��j��-G2b��2ܰ8x�U���8yI7PG^!򻑝O̵���!?b*��i)WŦ��V��9�^P�c�Esb�=N;<l*��8�5>f\��zq��ݸ=��؏L�ݩI0%V�H��aۊ���͹�Hl�f��&�R.p���&�յW���n��M�m�8�{u��ݯK�ja��ƺ�ο>�w�K\?��m~ ��ۘ0�Gc��=>�`�6/�ix}����n)�5e_J��H ]5��i	�[UX]̕A��.�������e�p����
��q-d���dU�(�LTI/=�cXBQ+	�r}��:Z���;���J{(���ѧu���ŁV��h&u�������5ɧ{�ƨ���p�)c�/�J|�j���_g���8�Xzw�~W�U1<�-���̰���k��p����I%}���=,��ȥ�Z4���ؓV�R��X1j��_���#�d�[��N�:Jy�hM��1�{��r;b�n :��^�Jk�4���ӵ�aǩG�7�<Tőw�?
��;pM�-<R�@	#�/��h�]կV� <������[�r���$jX�0_��Y��������h�a��|J��G�B���ʱ,ƕq���e��	|+P��n�u�Zm�C� ���5���[�0hD��q!��qO:o=Jp)pÂ 00�핋j*�������N�>(}AAyiZ;ʵ=VFV���������)G�mn���α���Y3�Ꝝ��$,�Jvm�l�i�#���_u��~���=9��":g":(#(T���2�AÝ�L��έ���
�� �[��o�ʛ>@`b��p�Ȃߟ����%���%,4U㮺��%���6�B��s6�~���aj���d�Z�?�ق��A��Y��1���4��Y�vV��^���>�O�+�7LwK���`�$QV�����l�L?N7N���+����C_�e�	ӸҬ�s\��9kb2�J��\=�*�q
@wC� ��!m��;�ΘF��K�Ob�(�r�y[�i"uZ+T���mef2�32q�L*���y ���7�3��Jج�>JO���E�?m�����1��W��;O��3�A��oy�e�����dC@�*�7���Z���N9�k,c���7-���A9����礢ӹ]E��RNu��m�Q���)kk�;�]��tȬH5^z�n}������:wU��K8$�B��>�8���!�W݇1*�aS0�Y/Ny��y�� 
��7>��LӁSS��� &�] ���eQ�њU*J�m��<��n�����}T�ih �K�l��+� �,�Հ!j>H�#^�b*sͧE�9�:����{��7[np]n��^�6�)��/��j�}AlD�݁R��WZ�4�Ē���G)��>�E�����E�pE�s*��Xb�DDYbdR��K�iL��g�VE`�=t�K�Cť�"�D��O�K��I\�<Ы7G����jh��F�R�cm�q`k�f���Y�����+��M�*z����T�*�^M��W8":'��670I���o�}�����T�6*��7�C"ׄ	}p����#�7�I\`�����=f�^\)2�����_�=w��^��@T�xњ������7�o�s��r\��ߔ�ԥ�ly���[�{L�7����WI��3v���FK��D/{�,]�ݙʾPs6�ai��`��u0P��ݬ-���e%�A��1�R���ө��uJ�dy;V�e�(��)X �`ah���֐uK�����p�	8�'�]���+!�c=������?�hi"���[���	�B!L�
, ��|*��w'ܔ���LT�/�{��ء�������$oS(�X��#6)���ٔ�B�}��I��igx���H�%5w���oy�]"ֲ���!
Ћ
y���� ڶ�v��B8�ъk �-�(���� �=Y�t�̕���y�N�� �t����Ļ��@��)[�qC]�<�����I��4r]����Y������)�
~�����h�R#�>=^ҩu������s����+����0�:�4�[Y�W�E�~.T�*]]\�
�C���|�_�i�&�ג���<r��(S�%�as<�(��: ��/�	g���� �l~U|?�mb;��v����ftY���� 6f'׹2-䁮�U�:@�3���I��.c�yA$+o����E��������/K��(�Euy[��0(�	��Ƥ)\k�]�����a�=3"���!��n��nuF�qa��W ��-�+���(�[�	�8=z�>�0��)dG��E�uhK/K�e�b���l2��H��N/9w���V��
�5�GP{�6ף��5�^��2q��*��}��1���N�d�j��:������n'xV�c�$�yt��Ѡ}&l���G�O*�{��d5m}��g���RY�0�Qq�Z�b�����l|�y{�����#vA@G�W��u���؄�L��J��2�&�0p�Kݽu{��e�@����$�ɪ��i����,L� �BKآ�/2�
��%"�؜�s�t���������D{e������.�0��n�I���ȏ�y�����Gఠ��Vf'��'�:����OΛsםT*9�����RQ��Y�x�)����z�u�������ڴ�������c�~�:�Xi�VҖXX kĨ~���b�,�#�j>��	q�'� 5k�m��;��TMP���GÝ�j>v.�������څ�&���65������F��N�ԝ+zШ7�V"������o|VE0���H�e��~h�x�Ϊ��{-�W �.�?���mvN�y���P�}fA��F>�R��+"�t�
pܠŏ{�ij1�`0��:�r\)���}Nn��"�<��^�<�'.'.��7�1���8e�PK�J�7ob$T��z��&��k��j��DU�:, :*���m������@���FA�Yڮ����{���}��׵��"��a���a��Q�s��(���q�<~F���c���29����udIl*��l��`�"���_�m���l����U
��~!�V�o:������*����U�3g�ּ�vh�s}�<�Q#;i3�M1�8�3�_|3���0�w�2/�jݛ:�!g��D����.��:�]�����'R�/5���PXD7��7F�ib�Cr�>�8�8P���Z��+p���ߑ��3���
/��WnzY�3����!aN��t���{2u��yc�#I�wC� 	�P��c����I��^���0?j�Y����X^؜t�S�sn�k`~���0�T�%��},��pB��tR�z��f&gE�!����d�Â���+� ]W�sc�w�q�G�N(@���8��_T��۟\|�b"*g�8�Ax�7�Nү�����o^��~*���@ ��,^�٤u������:���S��#]�dZ�*�yHk$<�!i��DsP��R��(�Ӛa-7�N��A��dA+=���&@�"��^�Ԍ�8��`�C	*$�#-t����`ԁ��;��l�D�i�^ �{g�j��DO�'�!�����6�Ed/��7��#ScJ��ʯ0^I��
~�H��>��J��1��b� <#q�WC��Y՞����҉>��)L�W������.�Jd8��
�D��1}&F�쬇��G�C�Z�.EިP�3�#6��[><�Z�ͨ ����#�z��No��?Lq�z���C�����ƪ{�=F��*u��!�W	Aԓ�T&����S���2 I��:K�}�����CѼ(��L�1�7�e2)#Ao5��ԏ�x�s���S*������@�y^����{kc� i���-E��n�GL��+���8|]pr]��/�V��[�L5���p�DN�ֲ�|�E�<~~���R��nY��e;*na���6_�\���y��k\�ʹ�-��w�~�� �D� ���Ç_���{C�n�Z�m����f�+��w�/
iQ�I���H(���r�S�>�ټ�պQ�r�;�o����j�v/vY]��:;���qJ��u�D$(��sl��S�����ךπ>6�@^��»� +�c
����o���#�m;�K��(0�xf�<�G A�|8aG,�	�����	��h
d(��sH�4cԊ����͓�A{]�[�>��d�F�:p;�ڜբ)�C�1�_�} �2�hL5�-VW�{����z�Q�Ū�VCq��R�q����ؽ�
���J�Y^��OK����I�XԾU��[ow�7�������=.]���x2��<jc"\�G_�ƈ �ö�}LkT�;�f��Y!�h�>O� �2K���-`RQ�v/�kV��k� �&-s�AD*O���E��A:�_T0i��g̍���}A%���*9�}����ݒb�"ҁ{'t��4�~I�ũ�
��dXOm<>"�gX3,|�&F��oЅEA�y�̒8��y���KN:� �y��F���x�s�9�`�j�7>�B:�x�\��#�ږ���җO���Z�
��0�0j�f�|q�!&��q�-X|��MJ�á�J�W�?���������fl#sA�@ƀu���4���%SYEm�[n� �@^Uy'������@]��ŕZ���el \VU���E��nF�)�M����p�=t�ǝ�L-S������'�cz��7t4�n�s��-��H~m\-E1��$�{C\��)]�x�ء��~-��:�(�T����l䖋�4�Y ,�L8�c�bO87�"s?��-r1?[En~{Ɠ�7��7!��m}Y�������F��o\g����n��S�&!�w�P�U�a�_)^�kDZ�;��$�	Ƥ��O¸����Z���aE��"N��Ӄ�e�T&6���ʣ�KP>�!Bc^@�����P:�`���VW�Y��g�����%��;_w��9.C��s��=�����+���ۣ���,�Mm]8pa;z���`vw����?b���D~�kg͚��C�j�遐[ܓ��+o]w�e��O�!��s ;�Y���½{¯���� �BH$��K��.vbh�;D �N�j	�!ѽ�.��E���B���'[��/m��"ِ)'X���8E���XB��tԓ�
�L�ު���C>.�'O[���� 3'0����s;�Q���&��l_�`�W�+��6}{��sf��������/�Z�A���Ҕ����Cw*�і���l��ڬS|�"S��&a�ʟ8�5f��`�jϐP���*��)�'� da ����f,�-��D,�VX1rmp���6b�Hs<١�k��/��Q{�����j
!�oJFF�H����+�֛Q-־�|�wށ��1����a��oֶ�����α���:�Ӝ�r%�hS짔�OҺ���f&���3(���ȩ٦yMJD5��Z�?�_�JF�3<f�>����O��7�k�/�_v`��۾U�K@P���c=� �x/%����c� Ө�9k`W =�����*�+�ƴ}����Ѳ"�;�5�)��`3�a���P��{��#��������p+�a*4���5�o����a�^j#���[x��x���T�E

`V��2�{ޢb1
��̿��������>�����_y�x�����7' ���/��m�X�l�f�O��w�\	����Զ[s5��iЊ� �KK�Ϳ�2尵��1�C�^3��	H3�w�g� ���i�D;̫����s�����C��
m��B�l��TM��wͬ �*�v������ş-�Z��n�S������چz,�x�z1ٌ<��Q��f@�   "S��oW�* �����?=ȱ�g�    YZ