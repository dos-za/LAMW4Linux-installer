#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3338484441"
MD5="26fcb6b9df5c57dd00240683a3b0ac70"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23524"
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
	echo Date of packaging: Sun Aug 15 21:27:36 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D��9�Hb�R����R�X��%��#Ay��
����zS�7�:L|�M)*�;=O�L�������K�0[�I����ʾ�x���q�4����;�����Z4�F�E� ���MK��fdƺO:W �\k=c)6�J�tdC=7P�~��b�"5��mti�bE���]����� �����	���G)�7�E��
+'�7��L\���	=%:bO�]��P��7S�M���Th��*ύ;T��y��&/����|dn��i��IS�9������B^!CЫ�@��h�.�7��tɗ&9'�E��(}�	1�2����\�/�`�7@�hHT����7�É�?O<|`^".�FG|�Z�t��K��	�E&�U��_ �U
Fԯ2v����}��w��qӈM�0~�%3B�W�h���7�.T�׆܋l�3�bn���A����� &����P�����b5ĥ6R5_4z����rޛ@J;`�3Q���dנ��R�Z� ��e,�_E��*V-*�ψ,&8L�aU̚o�mj�檛5�)f�-M�%#lG׉����\W9W@�MSv1�W�h�ɰo�H٦��cQ��X������AhMu1%z<�T��R뜮���]/K���)}�~ɍB�a�v��y�h��V�X��~�d@�x�c�Z�ظbY5䰴el>>��-����Mp D3r�	/j&Ȥ�D曳����O�ڢ��?[��-Wn���/g�ҫI�1l'8%��1.���3 ������ի��ѸeZR����{�޶nb�s��L��Fc�3̬6,���W6,�{H,Hؕ�;�l�8F	�ҫ������z��8����U�SY�]��W��K̡�f�(�W\c�u!{�;�3�j�Ȁ+�'9��昧͹�>�${��1��1�¯�_﫿5�����Xk�O
��u�F�8�2�}�(V
/e"'ū@Z%��^i��8B����>V퍽EH��'�d�?�mA6oVd�8��Y׎�'�L���W���j���y'� [C��G`�a��$|�ia'��zM�H̛I캅��{k{�rҀ1�˕͠�q�t���Z��r1G 0*I�|L���h��"=n�D�Rw�A�� ��r;LElz:s�R����ɝ,w�n�Cs��22G,�w��L|�te,2_��a��uc �(�^4�R{�]���>E�jFu	W��u�����ik'y����a'O~D-"�R8m��
FR�7srrk��P�u�è6m�V���*
���<�X�0QHa� ���{�3\��"v�B�������W�_<'��I\�2��S(T@|�g�;���C��]���ʍ���'JJZ�����Ed�B#��xg����OkkfUo���ỜUp��p�%�R��A�T��Ύ���h�N�g��'��t��{�����u���@t�+��yl�#��e�-;�uJm�Ml�?��^����|-]5h��򪜠��_xk�=�gǺ�4>rӀQ�-jK37)�aW����	`��m&Q�I�
_:��m��2��U;�(�T��>�Y1��+�N� �l�m��2�2�ϧ�1�cg'�e�pC��o�/,�&���8r�q�����ބky��D���͋$�R��A�t�h�g�
�##N��A��Rut�qlLe�駍�@��
��@�ƑFS��A��tq�w�(���.}aT��1�v��w������Q:��������=��������B�З�d<<%&��J~I�*���0a�@�KNx�a���R3�d���i4Hdv@Sq �S��n&����ME��w��}8 -r�0<Y�I![\>-ꃭ���k�`"��z �K�� 
�n|9֖U�$�Y6$~g�F�1!�A+3��єF�4o�KE��A�8+k����%��ף�1�!	=�	$�ċ�8,&xǼHq��ŘL��7�?�
��)�%���骇G��� �g`���ӏ�����]���g)�"(h�Ɵ�ω|hc�C��o9��)n����o��R�#i��x;����JQ� ^'�tػQ���2}�FtQ��t�3Q�Q�NΘ�O_]A�J�uB��l�p��('��-+�
0H���1���o��3�O�T�{���]�g��}uky��)�b0
��)�/˹|�@5Mu帢셎t	O��<�{1�(��T����7�K�/�E�و�D�H$�q�|�zâ�e�w¼��4��-n1�-�*�Dh_�L.>�.=�Cʺ�7ۗh����<gl�l�Tvz��g_���]\������ػ7�:�\A<?�W�\���^Dʭ߯1�@��g�[�(����G��G��*��8�(GO�V�@Q��������1�ZW�~4��S���8�H�E�����������`���%3���A\��/Dg>;rCYi��9T�yY���,��J�7/D/���M���5x�a���0��%��I����m�����1�c`�+C����_��AHQ�� "��&QFN\��pI�quD�\�<<��c��-*%{!�^�9�q����;
I�mSݬ�����ܘM�� ���2�~��E�a%8�KU ��p�uY;@���B�k�1w��Љ�/*�C� XD�#��ߛ:�ȘJʢ
��K��
�rZ��𪶡�c�i3��}�''bM���g�Y3@�0��dU�HD�(���`��	%�#�Rȯn4��8϶��_r�F�]<t�øe��nP��]���u+�@f79'�=V5�P����2���ǆ��	ғh�����C�)r��}��*�aQ��jM�������`�,�����[Ĥ��d�3�-j��>ޞ�����&�E�\�]J�q�Y�Pvk�G۸	���`���hs&�M}Ia^`&>���\:�쯪qH�[�*FHZ��2o����_gc�;b��t+iw+�-�B|k�᳄�A'��8/�fM����s��	гQQ�FB5�_��v]T=�f��n!�g!��e�q��S�&��r2&_�z0��E�ٌX		5ɉi�h��ZQ�!�iU1`���'o���V��Q+H��yt�/Ղ���#E��Ǟ;|� ""��N@qnfGђl�>06O�\A�K�gL�ͅ���Z-�.�ʜl�C5�� ����[�7��^���Q��q�؃ּ�p((7�96��x���$���Eo%ea�X��H@�!Z���dc�{pk�ݭ�����~� �9�S��e� ��������!�3{Ǝ�#���f5�8dS	�I]ϭ����v�'θ�)8_f_�1�4�06V�T��#��P��`�[�uAO4ّ���Ġe��yWI�d�&�#������ \z!� ���S�yj���ի~��y����\��,�����Z7$m��ׯ/��3{�
 �T`�����r-�����ՊgZ-�S	sh����� j�N�u�e'���<��O��2�������Zۀ��9�mk��F4uwI�����,~�V��|��8����c��T���}�=��cɞz[2�p�*�)B1�NB�3v
��;�70����i�P������$�ՠ��Q h+[�r��%ϣ�����1:��n�E-�ni���K�N�IE�~�F���-�ZCYE)��y�ZyC�NN��5CmJ<��Ʈ���ױ�r�nX�����̶��C�W���O��x�&?�w�L�)+V��K#��h1�C��a��� �TLf��P@�`��1�J�n*2�+����b�M���1�m<�磘�̸{ ��z�Ucp�N�}��*�Ev��u���ucN����cW�v�rxӰ������+.�� 0��z�9P9���=ۮ��u�k��YNV�t���G�Ş�P�i_աW�N�rߛ{N�DlzѠ:��4�_8������0��4X�
1�n�^�t4�-"6O�%1�n��t���R�����Rf�]m���l9ڨ�' ؂�Ǩ�������r�6�񥔺	?�9��T����W�å�L��P��E��%���ʢ��Kvю�%���{�P���꿝X�5.\ ����n1P
���.��r�kD�})���H��d����8r�u�=���slz���6��
�e#����(_3ß^�UN�T ZC�э讓��m�G/����jDlAOɪ�c�[7Dwx���N�W�t*ײTSi�eO���Bj �A���u6�gT-Ix�@�9I�&^ʕ�A
u��ru%�	�����o��'SY�����VыۤRܹL�y���`��@������p{��//���6��q>���Q-g�Sb�iȆ�y�9��7鶘*��gI;���}�L����K/$	����I�8{�=k�<�G����H"WT\!�؛�2Y�c����V�z%�a����������)�S��O��T-��YSY.�%��c)B]��}��e����BA�<�^�,�[R��쑖�[��|-������m��אk��҃:H׊�U��Q����K�n��S�kbimf1"���(�_����n��[����T�$��.i��h�4Ty㙹r���ļoH/��{#�lH�	�~��C�f�	Hf� ��+pj�I�QF�:��L���p_��<����}U�h�NU��k?��^��!�jf@<�	��A�$[n��!.���y�{�'{ۧ[W���P���_T�u�����5����#i%Q��ZT���쵦�2�j7`�-W�l��Y+(��c!d���u�;}�&����@��m�1K�7:Lq���,��n��r��x:��B��H�%�!�X���gp�!
H�=��;�CF���?��/�{�5_�X�h�-TQ��9�P`�D(���ЇFy���(	��g�&�ݫ�]�Q�����.=/ ���X��C5��m���	R�,�Ex�,1#_B�E���9xs^8:pE���A,��Q�����ўթR���K�K>��z��׃_�a�m�O�C�,N���N>n�B�&-���Q��
�e]>�G��ڛfS׏��EqU�|�X��!S�����0�RQ-�d��U6��d�lq4Y�� y�����c��V"jՠ�v��t>�{�N�];h!�Y�Pd��|	'��m���~��g�d���ϥ�_�x�u�	��ß��}����x"h���+�D4'�Ѝ;�����Wa�p������LjqI���WK�Q4%|���蹛�H��I��%m��������:���H%ā<~�!<��a�bC�r��@���~�����uD�;�5]�;q�`-r{e89ć�������=����a{R�Ħ���L֊��8�֮�H��2/Y�fn�쑌�aL~��p��<�Э���
L5g�r3E�P�m�k�3��l�S�fm�`(s�kP
�5�����B�Th��8�^l*��暛zuw���&������٭���t�g�����0.��-Z��ִ��)�ڲ�֔�i~�5Jp�kn $��aK>�҄_�܅,-v|Q
���`(�&ŧF\�2b%����x����v߅�44��Mn=�=�➩r����=�����ס�x��v�CL���Y}�x���u�/p{Oi�w]�=L!��K_�hɭ0q;�@���=fyNj�����z٩ʵ�R�%4�x������8܇�V�ɆW����A�D�<�;�l�����UEV/�O5�$t�V�0!*f5�􁚧�x2�/�E�ߞ#"��Uh�_%�I��c��%Ԏ�G�i�9�;�/�D��mM*���̂���"�x��J�CԲo�R��n����n��O�<�v�*
�+�{O��SL�a��� 澖ҩ�8�O�)��^ɟB�%
����ړ����$_�^�¥F�V�_MN�/X��ؤRס�[�=�`))��Xj\��"JT�Op$i���O�h��2�-d��|wx=]!|ԧ��Gx���*ͥ:���?��D���x��~���@�
��&���Jۉ0�`I�:#�<���ʮ��G2�y娸���ف5��Y�#�������	R^t~����]6����
t�.�|�U���x	�igi�^0Վ8g�G��I!���уRz*~������b�o��j�W���!��XN���� �NB����KyM�4���a�k��{���sCu�x��0���YÃ?W�_4[������v�����S{�<�d�b���1����E`��`@�E�Hх#�t@���߲�� �����*�Ƽ@�
�X!\�����g�3[1�-W��!gtG̈́ف��Xx�d�\Z�!��",�K���(q*�f����2ԑ�~�ˎ�S6�[d\=)���@㰽��y���rE,�٨cя@*��}?���5��2 ���X4^�q��FX�=:�u]f6��ev������9#��=r��#�q����<�i^e�$�3�sM�t������AE�9�Vo����[���|}&J�oI�!�[*�o�N�l�~0�:t��{+*�6f(��`4����n\G�l���A����úagcM��7w���50�G��zY��0�zX$e7�R�y���uj��߬��:}32�Ag���h5�*����:�i�6��)�{�m��`?�Te��=c�1�<��H�)��*���4gn�����c�:�/-��(B_B�06O�A���tf>����,�������A �#��5��o_�{{2�; E�Y��0]S�^�d-ǀ8����J��S`7@\C�l*�u(籉��/�	�?�s=6|ص���.0�k��X��7U���f}�y�M?QJ�v�@a]c��3Z�c5v��ȗ3�7�W�_�&�6�L�O�|?��Ѐ� �����+���}���e��m��a�8����۱J��aB����~�逴��^�Gf�J0��ڤ�%��[v�T.L$hd�$ْ�Bש}P@��>���:<�W���vb^:�j���I[��v������^ʽ���ύ��Ӂ���NZ�,�'?���=/����_VP-�M>���<���ko�
��7���zf�v�-Ԧ��DI6i��O�R[�=����	�*�杹��a�ǥ��{���hv�Dn�ߤ锯�>_�tDmK�Ff�b	$`F&�\+�t+�V\?u�����@nCm���#�t!v�/@�v�s_^ɯGt����d]����
ҸIoLg���%\�K5���X�������k��Q���mD�u&�|/�^(ur��i��;���&#��j3�����ӕ�w���(|0-����O W�0�0�2U��6��[�a�O��u?�YOȜ�4a�鿊���vH����=�3��S����BzU���)V�S*]��n�W4��r��� o*�T�TAt�h"����vg�	��5�����+]F��S��5��Ζi���h�Ø��9�}�������x��.�@6m��H�,� ���uw���Z=��	��i��}�X��{��}(9dDD��	�Y�᪋�A��s�Z՝��*��wFAW�܍��ԃz�~d�D>��9�R׾1;U��+9�ޘ�LIe\*o~��	�|�Va��*7�Ɯ��:��H]Nu�i|~��;��w\Lw���a���>��������2��u}��z�#C�+1R��T���'���Rn�?�O��nؓ�2F�\���}�y��������M��E��F�!
z��#� 8�F���w�t~
�6��ӗ�fv�J�"	P������ ���%�W]�"R«�T�|hpK�/)z�f�Ԅ7���0+X�=�o2A .EO�gc8�v�I ;�#@�ڷ|g��Цo�C(م�]�#!S]�.�"��$�EVW��S2��SkJ�m1O���gƞ��W-�Ej��x̫ـ� �0�a?D���7�t����tٴ� �K��b�ޤ*�#�i'�</V�#ah��Aܘ�&5f��tw��>�1�+�1Ty�-�#ZGfVB�$#�>p}�|��5m;RI$�A4�Db����ŷ&Q���.q���l9ֽx�0v��#"���{�7�!�,@�ԓ�jM��6<�Kp���)�{�P��÷� .��>o����N�S�s��G����6QԎ&-������j�Q��;�)���	D��c�쎗ѝ���@�pX�*yxn���[����K����K�U�` ����NAM�����G+���5O�ػ�ܵj��0Ξ��(;�~�۰30�D~��HO���*Ti��˞`{���J�m�8��|Igd�~|l��[_ 8��B�糢�c�z:�}s�H�^�	8�d$_dq��xn�+�����A�S�Ik�,4L��Xi5|�|n3Ob�����Ӛ>��˦�$�ZY��rʉl01������8[X8柏Ԧ��l:t��\R����c������>���HE��6�~�0�����������o�Yנ��{���D@���*A[&{��|�N�L&	p�y���ޥR��b0��\�� U�~���	��c?;��Y�(��>���)e�':R\�ϭ�$�-�Q�_����3��$�����G�*�� m @�_ 7b�ʣO�.4NB����B?�1du�A�*�Z���;�h���S$����ֽ���\c��ĝ�Amg��獐w(�Hןe���#uD�j���غ�4�dA���9��9[G*�-��aE�Bj����aJ`6�
�M��2l�ۿ
y��E񎳚3��I�f��e�s8'�%��_�z����R�X�Ϗ�J���<U��SB�
��h��cښ7Ӄ��z�[p��zM��ؒ��W&�����P���f�yd�\���&���g����:n���!~�h�Q~Њ��S���F�b"�N�<q_>�1����el�y͑�u�����g�Gx�����y����=����)	)��οju��~�ӊA�}%�dT�HAq�}�1�PzgbuS�"��k��Ȩ4��Y�C̤�#�:�K�S�z:��CV^e����6 �H䷟�h��?�V��L�pl�	�%��?�4%�y�'rd�o�=m:�oQ�TƂO�B��ϸ��p(a	�Cbj���PR���]V!��9]��ύ�OE�l�*0�S/�B~�@�fPO��{��ń����
�*,�����ˆ��|�r���$7 ���2PC�P�lKpz��3�����I^��A�W������zK�V��	���ڵ�k�V��O��3�g��$p� �����귢���y0�t�2�k�X8���ߢ�ݱ�#�䇞�ٹ'�U���G���F���&UH"�>�s�hF��AI>N��~������FO{="�'9+?$?j��$T��V��X��h�z��[�l���hR� �A�g�Z����Ys������;�(��ښ3��6w��i�k��)�̶o�1��l����ѺyC�޼��,?i�p���4�yc�?
�� 
��N)��<�������yi���ǎ�&6"xe�9J�n�/'��~`Ba�J�yC�ۯ�G���t
��镔���Ҳx1=l���"�nG�d�x���D��x^�["���)ߏ�s�D�gj��B�GM͗��]�B��/�Z���^|Zq3�8�Y�C�|�h6��#�KΩ�]��c8��Z�J�K=��%I����{��;\��,� �%��[q$��r1��l�E�\59��'����XJ��ڽV[bՀ<(L��Iexj���8F=cBsr8��d�JJ;���3x���D���x�'
_h��N*���K~R�:�X�`��G�KZ�.�h`�M��˻�F�\���������w��>L�0�M(�5Y��u�2��D���<�(JRВK��C�	�K+pk녀oJzk�7��ЇH!r(D��΋�ޱ8��-[��@q��O��j�ݙ����V�5��1wǺ�g�!V��R��dX{c�����H��s��_������)[���p��ԕS܄N��w�{-�^-��\�T�,��؂#S��Pѕ�0?�˸�Yi�­��Z���&��{�Oz�e�mQ5q�ɋ!4���1��p/ӑVbN�@.'�v��Y���p*	�P7��7����Ɠ��`8�uݴ�:'�^�&���>$|, �?�<z8<��4˺4:Ėv@鮼nds2��&GDzq�rǎ�������CI�5_[�L(	��S��Pä������T�^�V���Em���mS�_����)��c±�S�z,�����M'��8��GIV�~�D-���q9?>[���ؓ1���w�t���d*�eG��k�kpH(I�Z �c�#d^W+��}0܍���i�H��,���(̖wU���c7����a��>e]m,-z���l�f�{����C M�p��U3?�ʩ���4��>_)Pw)(f_��ƻ!n����c��}�����rBx��lzϒ���_�EYS���{@!�m�`&N}���CЁ�O	:R*ԁ���U�YǙOy��ð����Ҡ�@ugK�]���0�NtĜ�;B/�����
0��~X�9��8����b|�c��H}���}	Ї�FjN�`���D|��v_�)�d��D��>��l�V��[���N����eT*Ѽ�M�G�-��:r���?G��w�����ۆ�-����ӗ'�4k��n��-dĮ��H#2�X�����\2��+UUW�0�q3����#9�D攲OY9�{
��YWbrr'jO>c�u
 .=<�b�@οdu �v2ڙT�Po��V3�nZ2�"�������Q�e�A�����|Иۼm=��b���*c�g�o���2q���C�V�	!f+1��D�U����y���[i���8�� �"�V��u�\�{s����CD���Y<O���
 ʌA>q�9e�$��M������N(�W�G�i�@CW�d�A�dD���FOr��<�g&0]��^�b�2�4�D���Fk��FF9p�op�W+�#V���)��H��'O�P��ˌ�����u$tGm6�D��CL�Ly�,7�w����/[8�T%EYd��dx^v�i'Iɾ��y3��jKų���x�>�M�>ޣ=��k��54�JN�_#�q�`�=������0}�ӹ�\ɧ:���P@����Hu��"1�E�Ap��	���U���U9��&��8~��N][���0��?s}��z8��_M���⥒L���`|�ٽ{�(��m�{���}M���2e/�U+H�H�FO��^�xy�_��r��٦"��텎T�[��4�wpR��.����g����r���6]��(o�m4���� ·�AJ����5�n?��"�*�-5̹�Ҳ迏i�-jz�8WqZF�3k��pI�CR�Њ�4f�/6/F�fc}=�WR�Y�l/��wG��m^G�bG=�k���~�a����2��a\��p���7�U�������&�Х�y{�J��}ǠD�D����x{���� ��@�_ G6b��튊�M���]*��NR�٭��
*O��1�c�Ax�u$�9��
����VJ^� ϑ-��X"������T��m]�������B4�}{�yy!�ҡs�f�ǲ�d�0��*,�Pk�w�i�2��(uO^�w	�Y�ժ쏫�ɘhED��<�j���>����q5a

Hj�?O% ��؏�
=;X��E"�0���A��{ҡ�<ٳ���X�v��7l5"�?�:����:���r�ø0����=��I�G�G>(�ȧb�%s���l�V�	�0R��{����_�9r�@�O�/(��1gk�A;C��=.�eL]&k�=�ѣdRj���`��Hc��*�_�[5@|���z=@u�l��n��G����LS��_P�E$�
M�5Bz��8ZĴ�e�pg�<{��&-�M��݈��ZI?{����좢��g����2��+�E�T�ߘ�2���q{�iW~
�IM�ߢDHH������N���F5��ٵqK��͟�eB�-~���#�t��tc.�0Mᓗe<~]��O���g�M�d��!�&8֊V��b���%��E�6���^G8X�hc[���OI�?�!��	�#�H�P/���	@� �H��\�*Ƿ��P]߱
5��E`	X.,�ȧoү�N!��k~'���y7�~t9*�O%�{�,Qg�L�����G% �CW�TV�g�]\{.j���2��9ʜ��;Eև���"k2Q1N�����>#f�Wt�U���)ݹ����˫5~�e�Lz�U��G�1=2�"�D0�ѫ�����|�1"\n�1i��d�S��r֯Ü���ŀ�ƀ��Q�-9���C���d��Iz�+i�{_[�X<?!��p?��I�	P۳Ԇ>���n��h��YT��Q�����4ڭ��N�țo�%�p;u7��i߭�Wf�n(���r�p��`B�t�'I0�:
*�\�u!���G9h�01��4&�f֛[O�R�/�_���_5tY�
��X���V�MI(f��V�Ɂ% l���;��t�����ٳC�Cb�R��ᬋHA4��;�@��3S^Q�1N��>��f���E��vL�'����⯸ �=ݛ:먩��=��)~��\L���?^��!�2�@y� l�&�u��M��5�g��"c�Of�_5��}n1�����|Z�
\��.Z\N�#f-����_�� �4v����3� �@Q������� S.�x�U§$H-p{�!�P��E�f�$���_��;���艽SG���[�xC��b�"9f�g���q����H(�ϳ��'	W�w��$|�y������8/'T�n��Y3��Ж��iu�t��&0O�ш셙��_�֪�h��^"L�I�(��J��`�/�c�����z$wa#���_t����f�P�8�&=�bش��f�2�]��2U�dr���vA��) ��u��!QX�#�x2М0�=F��Jwul�]ӳ��x@"��.�\U�p�RB�<[�ȸ�ݶ��dx�
��ʱ�aS�B70C�?>�Ҏ{FO�<��k��� ��ۗ��{�Pb|T����7� �����*�HZ�����;k�;{7���j�2
f�Ev��(Z�� ���$���(�E5�|kmo�o"8W1�����^�JrZ�ËW�w��P����2Ķ}��.���5�8���Ię&���R$�Ι��3p#-nb�aV��53o�k������<�{��-�C���d+����zK�ۢ?czfK�6ˊ��9�/��&�v\�by1}h�t�����{��"��m[>�����t�~ɶ�Dz����7]G�Z�#Fy/6��L��>M��(}MǦ�O�U��,w�hH*��:�㎪\�m�51��\���ׄ�YN��%o��W��������t?'�4ߤh�f���K���G{M||*c�R���?��?^���!�������@�BP������ ���iA]`��9�vS���7qe������4��օyt���0u��n:�&��i�=R@�k��@%JAov|�04�nL�&�[ZC���M��I��g]C�"�	�t��+��n�|�Ƚ�Y�P7�簉i�_~.���QH�������Pj��ABsLQkɚu)����D�����4S�b	� ��/��#'�|bGA�G�Ҍ6�_����qLإ��f�v�NM!Y��.����%��_L���������KQ����+J@����x�`ASE"��WšB��9���o�jvчkճ��_�bmrɞ�������8| b�I�{��bG�.��9�����XQ��B4S�-�$�����&���[4t
�qEa����pb9��h��2$�U���8_���vZFR <f�oE�g�O�9db��Ƭ4d�݅_�����6����� ,�mQ�MH���H��{����)9Vts�k��ݥt��R��N^�6��X����>Z�O��/�ۖ�Je�`^�X��U�Q�����u�?��Ռa|g3wl Ά��,u'T����>̐�x?r�"���Ò�1j�4�)�HtM6���%�j�;��؛��W���H-��)������zZ�^G0�iF%/�+��B2��$�Ƭ_3��eV�cb�BZ�cͲ�v֜����c�7Ǻ�S��~�s���ɾf����Q����'��ݐ�����bh�XJ��\���t�.�PwG���@�#��硠I'�it�/49�_5�
*لo�5y��<X��Z/ac*���cȩ�/�5�w�0~�9���������7��zՓ����fG >}�w��+5��� ���w��72~�.��n�QD��qM�s��.w9��d:�=>�y؎��#6�)`eJ~bJ���PEb���C~��9::���WZ�A�)C=������S��Wq�kc�P]RT[m�I�\~�W�^ˎ
�q�z)b%��k
��T��Ny�GѢ�n�2�sowr'���s� ��/�*2�����ޱ�b2�p����d����)q?�.�Xzy�G?e|�_���>UEp�VoD:��Q��W^��̗�8�����RO����V^����L�ݥ<N�>_O� Y���?+�Ӧ�ڝFus��.Ry�>�ܫuZ7��mE������}#n8��U\7$�e6?���h������=<�dg�%�T�n(V��Y���g砹4�N���e��ڭc���y�^�9��繡N@i�}�i繿�<������R\#r���G�y��a\]+d-��Nq?7� wo�ӡ����>������O��
'^�Ȟd��W2�(r	���)`�QSִ���w���$"ϱ�,ӱ��SXvF�����dZ�9������%�n�e'��'���,号��^]dSm�Q�߁F_&��aM����߾6�Ǭ���2���3[�Q�K_���Xi1Q6x0�ZZ��FO���N�5���f쮱�$;�Li��#�Q��OW��Qb��5-�0��v�تzB���f��ҩ��E�w�|��"[�T�cN�M�۸���K�7wI��:����_C[��\��F�>d�X^O����b9�&?g�(��.٢	�� ���x?��H�C#U#�T
ۄ�%d进�mS�	�-������%~EڦxQ�ݏ�|�qM	!L��+��y�����~f$邢	n����Jƫ�;��� fW���Yv>Að͗D�����X��`?�hg���Jy ��zAt?�C��i�ؔ/W�Z�����^~fH�4<��w�+_z�˰d�i~���2i�� ���a����y*�u� �O*p �Ю�u����8D�~H�����9L�f.%fu8|e�	��g���_�R%�LĨ8�g]lL����e24Z�gwZ�4-��a�bx7�P�2�Ĝjg��77��;�e0i���V㏫�.��Fjl�A�ɼ��Uӏ�䩈{��G3�fI"�4�i/�с�|{�|�+Zg�
��[��~�� �XN�!�qXe�dm8\ĴU��!˅���I�8g�a�oggF10��'�q��W�	Eo���UtDR��? ����t�oՌ1.<@����/R�6�1���+/zam�$���rhXN�ힺ��u'��?B�E�𼆺�`��G�zSG�!a˃ե
�C�*�2��R�n�J5l0��#B�X�����s�+���v���W��u�lB��j�e�ʜ�D�|m��6�ǲ8�V ���SȂ����D�O�K���@D�J��o �|��j�3�+�t�I�N�q�e�T��!�b?�vQ��`0|�D�r�Rm�=�5}) 9c����^#�t��ßݷIe4�%�Zu[~Fo���Ȯw8hX���_1������L ����UWZ:����~Aw(Vx�I]ظ+_26������\R���B;;l�g���f��H���l pm!Mo���3���]?�
��YJ⑛1qzL�}�ίb��r�O<I��x��
��h�5��(�����I;��a�FN"�)��Z�wd*oP���5�Ň��������ʖ�����ZV V���[��I����[��i�Utmn�VU��[��5@�୷���n�sY��pԊ,����#��8�:�$|��`��b~�&��@fX�O�����N�ލ�Ѓ��)>G��8�I�s�AON�~`��mR4q�u�?�f��	�HM��.{���^Ef�"Zn�P��$�܂n<�Qm�.U��kyc��a�R (�ѯ���s�*g��G6p$o^�Ȏ�/���4E�l��Ϯah�!X��CZcr���fb�6�ʸ�/��9[�Y^5ї7n'����������OC��B6k-p;ZP�����`p��X&O~am�h5D��'�B�W�?r>�RBW�R�/���u�Wߓ�F����<g�9
�b#u3��G��K�z�C�2B�ǈaD)Pn ċo�WM��E꣮�k��TNpn,e�m���	#9Ѕ�p�$�"ʺ�a�7D��r9�����C���޹���.�T:m�r��O��RD��K���B=�&\0�)�1��>M�i����"����h��]12�v�h���@���J�[��h���Rä�66ך�nˎ��+�sR�������������;�H��:j��<���"�l���ns�J·u d��.��,�A!���Н����J�jA��'�n>��"��# �r0��f�t�4��~���X��/X[<T���=���8����"����$��Ճ����z��3��g=����;A�����3��o�O�d�T�=��{Dч?����⸛z��U��ܽ��8��o]��)�B�V�<�r|�z��,q�Q�n�`���&d�����"?l�p�Le!�&�h:Z`y(��~�����n�^O�L��v�<��3YL�Q�Z��V�]�	𶀍z)����$��O�>�I5���*\�K$cHWqEфZ�-����FY.@ }�^�hT�]�Oj[ڀ�>��9��6F ǘmF5p������0�γH^�۽�Qo�{�X�:F�)"-�\JWP���������.��]��Zx�CM�M��!���`Z�m%< ��̔|c�[svPd^VmB��?v��Y❳a�Z���܆����2m����	S��L��\,.��6��cW�,�K�����Md�KJs��Q<�K�"��|�g)l�I���䏆0�}B�I7De��9�)���q�f4�}!D�Z��':P�o��t�����Zɽ*��<;�^�ܦ�Fሙ���l�W��������/4b ��[�>��"yq�$b]���3-�s?�A���d��M�ߏ~�\`�4��"EFE!�d�락���jmpPs&>��U�^�����_e\){E��M�h�f {��T,�V!��2y��� ͌힊Z�ZPC�0�����hAl�c���-��x������/�����g�"`v"���.��:r��G���9�
hy�n�ĭ�Ͻ�,$����V6k�3s��E�K-W�w(���`�UJ �����@c�[�0�0��֣
����P�Α
����>0�l���Ac4�i�g�
���\�,)H\���:��Ts<�p[�u� fr~ׯDվ��V�?H���l?S�:��0�n�HQ��ԫ�-tY�JȷL�~�����w�E�T��	Ё`�Hj��~�Ƅ���<j��hU� ���3�[A��m~k�S����܎�ǩ���ڛ�6�DM.�d����|��^�?��E,�i�<J��	�jL!�@��	���vrt������p�8���
�6}W5s�V�7B��0\�_��}�Wk���/���_\d��$�-L��!��	5�N�<G-Ma�o/��xR�� �t6&Z�I�
��	>�[��NVP��0Wp�s���Sh�l��� ���,�����XZ������)�������������![�VX΢=��Z�Rպ�J}l/�-m���#�Rn���(0�p�Aj�xG��lB�,ʌO@�I�?�ƿ�Z�X-�a�C�����|>�> �ӽY)�CLQǩ��7ۧH�Ɯ;Ӄ��w�	�Ϯ-ɹ��|N��m"=�aV{0���Zö+V�I�O/��5�`����*� 0��lX��#�]���S k���_���V��:�Ӑ6k�
���@5D��X���13���l᷆=��&.F+V*%��\�F����A�{xZ�2��ƨ��,Ϊ��i��>3�M�R�w=���K�M�p��:�6aA�b4zto�u�R��7Q���r<j^�+!�@��`aT��w5��p�n�����4P`�@��;�a������,Nϧ�D��rg�*�_��;w�n��<�0'�y������/���2J8|���� �-ೃ�nMN�4�U������n�;�^�&P�ұz����E�����~�kҹWu�ߥ������|�J�R�w����<'���S�g(}�d#92o�`��k�Q��*^I#��T�l���w��cMv
������3���ｑ��	�k��f>�Hl�2�۔b�Tw�V����|�rib����n�C�W<� ]�P�G�Z�{g.C��ىVY7s�mE�č3��@�vR/�%�ʖe�vO��F� 7�W|W{�����4��t�M+"�G�[v�TS��{=xZdba+��O/"�"6�d���&�~��B��а���Q��?�3����W�	=`��$��?����`�L����o�������{�@���e��I'7��m=����jh�1Z������~���nҟkcX��w��p������9���d��k���ߊ� c��ƭ��\gG�k��]�9=����4x�s�,lt7Q�8�te��� �}-Y �ɱTz���LG������^K���싓D�K�6��@�����+>d��J�lN��pE� �|��fJ9�������`����q
���fP.���kĖ��g��F�hjz���}��ӧ��6��}�x�z�~���%�I���Okf?�M�ba�
G?�I�Q���V��)Y;��s �S�����,��;�3�S{n�UERX���;�ږ�R��oNL˪��)�����å�@V�klp݀�-7����/	5�.�LGr�eT��e��* �׀�@�Y������FX�G~�8������~���vu!h�Ư��QXdo��FA�j�O��8�I	.�C�W$go��u����id8)Ez66�).8��:빫e�U(S2ۈ�bls�,����c�j��18��yF�Ꮇ��FQ�e�R���)�,ӏ����7͜�y���� �5�e��*�K~[��WH�+[^	��TT*�0���6D�YB�L�|�^�*�Hl���������r%�Cd�s��#9�/�eąq����9����OU+�x���Ps��6� jL�^>d�)V97���S�-y�y�c�v!ͷ��=��AHC�^r�2��A2�Ƭ��d��Xj���5
�"b�Ub�|����P�ڨH�QM>���2�˅Ζ����}3�3��S1����V�Ş�-�9���s�A����f�}|��G2=��o�;,\�!����a��nQ�͕~l��ϯ_��Ҷ����͂���/:G�5~x���)T
��<SՉ�%]�$SuM�ʟD���y���^/��0��~3 ŉU���6k/rt6��Z�2,�x[j��W�me��{:��%��hk���<��$��w��hLP��.�y��h^�b���=�1�Y;�4���5gG��ϫ�\�٣: �B�bG`9J�ٍS����L��>�h�Jb����AWv@�	/1��}�����5��l]��x
�Y�撁dG�xr���u�O_�{�bq@@�@[�<��i�ň5�)��ip�EL�D˸�z)�K�YƇ���~�y�����%�l�E�����$"e�a��G*i��\:�Ѫ�����C�o��F:�z�&���y�^`�N�X��FC]��rV�h���5?��J�#�H��B٧�
4Gk>cʶ��f���m�rqe��s\��;���Pq�Ƚ=�H��$�}Tcˤ#.&R�g���;��H1颯Su+�E���?Z���XFMa��_2����UQ�t����c��U���v��'�������_]����[��I�ۥ-����(A$>�O?M�|�Z4�VO7��<�pe!�3�}�N�hOs.>"0�bά
�rx�čK��%�I<$O�a^�l�)[�E�HN���L�>�D���D�gW3ZL���aC`�ba�劅 ү'��Qk��c�1������s�`�D8���a��&N��@�f0�m�1� QW:s%�J#���� ���Hw�H��~O1�i��يd w�C�^�{o��♥�)��s7��A9Q=A#H�
N���� Y���=SB���6O���[q{��g	���.˳�T^��yQj����L;�E�B�:B��=e)m,��?�e@���~*�qtf'
DY������^uRMN��7���	���4.�M���Hy��o�9v����&�y�]V�C*%8"�%:�,��g��ݯz)��l=����J@�g�G�)���'7�l�d�Z*�������ٟ�	uͳ�����Wm��1%����޹1��~�Q�o:��fy�Ǔ�r�lt�>H0��}��<�B�r;���F��ZخIԮ�q�X \<,7��3�����$�&��=!4��$�ȁ�]������@u��x�.	a�B��b`��t[��o��MlfB乘�آ-�U��|�!�Ή=�R�MM
X�a��HjW	���	c�]E/f�ɶ'I0���Q^�q�?<���-����5�E)�D�`cZ�B�!3����3�](�^^�9,���lFa��Y���x�W�p�vǴ`����s�ܧ��3J/(_��fi�I"a\���g��?�����˽�H����d��P��P����_��5��*"r��Y����6�҇�`9}��. 6t�40�d�Q�Fccj�U됦x�L�J4��4�/� ���Y9A�@���^f"���"<�R�/y�� �嬉��M��:P��߆Rw�!Q+�E�g>&��"�u2:k0�I~H�
F7�4�ҽ��mD��9�绳qPhw�>���F\]-]�Z�x�0Jm1K�n$��4����k��l���r�6������S���L.��m�n����@C�$��[$`��L�Ax{�V��C�jK�+ fؘ��h��H<��[������җV�H�p'��,���2%�F�w��k�����~�5�����	�H��z�'��b��|K�r@J=�@��5<�Y]X���K�x�@q����"gխ<������p��o'�����|�Bs���:����ʑ��s��2$wV�W^��
����2EW�n�v�'�?}ҾF�[3-�|S"`��G{.����]ś��2�'6P�$0��_���F����7^"�Y���ڽT����ϑ�$����'��\�T"]��4�+���54$yC�zBD<����p6��/
�����e��CE��n�=�d�9��e�P��Ez�q�����H��vr��JiX>�s��+1���Ap9Y���A2~�<�C{b�S�׉%JJ~ܳ�p����'��{��_Ǖ@(�@6î9��h�r�+���B�xS����;(2�:%S�#&��کǓX���/�O�q���^)�d���wc3�]�<k�r|ݷ/�22V��]�͏S��Fo	�.]D���.k_\�` ����&p��]��{�:oĿ�QBX�k�Yo�e���Kш��{�=�}�#9<P���*���L��M�G �.���}��ƍt�(�W�#(���Jz�G���5�6���!��$n\I�T+;ADݒMB��|��(:���a@\��_:��a��`-o$��-<W=��К�Cw�' &��oe�����$dx��g�}=�����l�s�?:�s��ME�+H�S[\B|Ò_Q2H�>L_�ϝo�������^��%�s�gc?�>Yb�������+�2�q�x��P�|� 9��c��в�v����ki�9�%�}�8:���\��8?�v?_���v�M��C������_�˩���Mhp=l!�ຝ2k礑�3�T9}�p�l;��Vie�7�a-���hY���y,�beR���v^(�"�����D���N[8(! ���5=��?�9�M���i� �(�H
禄�����s�N��1�o+�|5L�3��gl� �� *?�z�� 8�%I�h��^��[����n ���R��H�>�r��i��&�>��e@�cp����3WI<��;ׁf��0#5�p�s��Z�*�b��������-g�<��A7���+:�Y����2�7�̒�9��*a����>R�QJ���U��/�ѹ���Y�!�/���9�i��z�+�I�=�s�l6M�A	q��8���%��N�a�W�͓>���_-�G���w���Q$�:\�8���Q�ܬ��
�K7�%��0�=q�w8ⶖ� &�}������d	��&FN���^���(X�b�.�������9>���L@�J�pA �9��wnDk�_�z�Ӟ��f�q=��f�<�3o���۽��AʍZ�q�s@���:�7������wC�7��Vh���%J�ba �3F��%{����#�=1㙁���ԝ���zce�����V�o �o���+	5�y�\���-����|�D��.�voEP����=��{sU-x#�D"�(�B�d��t�P���4�8��s�IȽ2�.�M�s:sS�k��m��,��>ӫ�EQ�n�p��_UF�]��͍��=�h����oS��C*L�������B�� ��WT�R�%YJ�+3���dĐ������3�sp���[�-��e3���������A$� m�!���
C�<8��z�k[�c~N�읳2�^jŧ^�B.���$�����|`��+�D�sl��������D	�+M�����IP7<��)��8Ӿ�^g��/�| �CNgwYa v6D�b�N��a�OO�����'/���G�>̹�'sn�lT��Z-j̈́S��� >hv$A�V�=�����3��SRO�%�j�@�x   ��fTmRRo ����e M|��g�    YZ