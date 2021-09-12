#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1574070342"
MD5="ce1f31545e071cff05f15f36989eeff3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23696"
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
	echo Date of packaging: Sun Sep 12 17:16:51 -03 2021
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
�7zXZ  �ִF !   �X����\N] �}��1Dd]����P�t�D�G�-W-ss$�hMoN�`L��[�'�
���8$T���tTɆ*��XN���M����N�q��Ϙ�"v΋�zPם[g�?ت/�9U8�@�s]��M'�y�R�������z�U��Gf|�=�˹����:|E���?�s�p��3�m_��GF���^�q�����-*n	��O�J��&�D����\�䫉��}2Th�i��{���"i��=�G.hI�L�k�%���t.4�
��Ҭ�`o�L3T]\�o�3!\X�����U�.5(�Xݩ�b�����Rb��gz̙�>>O�ln�"it��C��eIsb�>+�¼l|R)nE�����J����!���ex�l�Ss�B�M�M�c���E�ʺ����*Lp�1��k/�❕J�q+��;�E"�F ��ZuP���`��"��Ḵ�&=��w4� K ���Շ0#,풷�D)0�K7ͯ���#`��ghք�B�
��t�F^�%8��w"Y��cG�:μ����0`�<�0Õ��+�yN\c�����AF�m6��hi���3�;����jg���P%���@��������(���;kBVXye��Ú^A�p����3��^�%��a<�qB�<� M��f���:h�P��I�F���0�25��
�S�`�$�~>�l�N'=�'E�y�0i+}��&&�F$n1��%��_�Q��/�{!�~�%S�3M䓹�O���;�*�����r�.�$-|����,�\�LQ��V��������	뗳A���K���;o8Y`�����92�Қ�i���%�b^�?���oS��*/�cq[���.^�y੣����6Ϩ'(�wYO�VN A��S�#���.H��ujE�GY�X+`O�"_�g�_K+��,�;go����$б��dfbN�QP"A�6^5�8B��)bﭢYr�-�G4df�"��,[&�L(φ�}�j<��2��ߖ`�X�9�N;�{�t�D*�KoT���e�*�R�Ҡ!ۂ�G�^�F?�p}��
Q���^K��k~C�q��-%��'�8D)�wH�7[O����oP�<��n��p �;�������r-�颥������LU��H���S�TػB����\��p̄�HJl���['5c��$͐d���-�$�;#K)!�&���%im O�/A�ry �ceB�&JZ&}wx@lk�3Q��$��v�޶���{_"5�!�W��u�b�&���o�ے)���\���Q�:1���Of��@=D��]%�~�
i��lc. �ȁK�뛛ʱh�	q�P��G�O��Po�n}�g	W����Q��}��S2�]CE�S#��Z��7� 3t#c�y��/Fr=Q�\u�+T\��7w�t�g�t[���n'�����V K!�H���h�c*�-]�N�V�zY�
�n���*2�'�r�A�YE�@͆����
�^�~�pf�{Zꌳ�yļ�AĐl;h��jl.����+ܴmn>�S��80g$�M���&c�h\�����nRI�צ��;�73�!�9��H�;,�C����y��5�ؼ	��P6
��Y�Y�;��������`/��<���m�yA�ʦ5���!��R��I����W��j�P"'��D��y�`P��J��\+��>tH��Q�S�o:� ⒁����QQO�a"�z�>��n��ߺ�_�ڥ�;3������؂���@
~���-"A�}.Q���ӗ�Q�y��>aGr�%��]{�MEH2��MZ�ym�?��\�԰�ͳ���:3CN��G�n]�D	�U�L~��)�-�jp�eLD���ɰ*1�Ar�|B��T2)I��Ӡ���ú�
��z\��r����E"��HA��Q��R69[���<ȏ�4�\*�#�ao�K�if������� 	���6S\2N���3g0)U$ŭ��B]	4�͊��g��o�^X�w��-$��}�|�6�%Z��Wg�E��[M�sH����d���pWV�%c"�l�%l{(�ނ������Q������u)�HÓ_e�f�^�N��0B71 ���)��!�W�|��1�~��ې�B=n��xlj�*��� Y�3������mzl����q��`�RY���C޺���Kq�����~���=�S�x*6S:�fC�]<FEV~��#��r
x�`_�KJ]�����ާ�����g��OD���1��[p]T��!ߊR&j7�[�F��?99�����H�$�:�W�7ia5�2��g,�[��a{�(�x��rg*Y�c�}R�;��mI�O<�n��C�LR���:�f�����q� ʑߝ���&f?����L�~x�a�5 ʡ`�V��h�t�v�E|�(޾M�y$c.3%�W^6����/eh��|��ӏ���pv���9PbM�jo�~ W�~B��Am���$x�`��b�ƕk$�9��/������vjSYflu-����4�\������\������b�8���nQ>��oUR.<~ �3�LN�����~��U�P)�7���~ʻ/)�X?��]YqPܯ�Wg�v$�����q��}m�=�{�eYp�<��pi���-�A'O>�o�I��{T� �O�rA��Q~�` �$βEv�2��I�:a%��1"m�}&\�*4fb�=u(��CK6���Z��?���>�����e��_W���M��ސ��'��*�$y�.d����B��F��$5��p��~��)���"nJC�?��%������Nd����p��'���Jخ�7���6�5�z���_&땄!i�Z
�����3+�$���#�	S-��zz��JyG�\�pI�G���KA���Tvz��=��m�-��~ľO���ī�Wd���,ź���V�8�
�yy��)Ռ�G�8h���8��~��K*�2�0������!�r������G'(;~��鷑��RT����ߤ���j{`!A��-�����-�;+@A�y^�ť�e0x�gR�u~J����}y.�.����fs��͗�����D���k�5�
�ێ���ﶫjͩ����Ȭ�iP��qG����;�qKt���bKS����%t)s}�%���jS�Č&��&.�/�iod��:=�v�!�_bÅ�%���*�Ѿ�ۂ@-20`�AO:���)��B�����o����� ����|��~�S�7���~A��Hz�Ո䴚Ź���"δ���,�1�(^����)�0s2.�v`�A��Z}4�����
_Ln��8V\�t�vB�G�68��%��[����5���ѓi|W��!ף�X�'V�Y�\���5m~���~��d��W�2Wi�'��)��Ӷ����pL�oB6�T۱eC�����z�Ѥx��'�b4T��#w�m��W�����-Ŝ+M�7!��(d�� c�-{]ɇ�XY.���A� -����kb���.}�k;ӢH�,� ���h�Ψ{�01�zjz��o!�pƵ���CjMu�%�©j��.=��l�效���+[!��Q�h/�}K!n�
�8I.�!a�0�[��i3��ai�+��r_���?O��s}�{|��o�y�[ч'�`��n��Y�T.H	q��9��4��Y��3����s-��x��z�/]�r�w,&���h��݋A�	!��G�kA�>�pȓ|��b����~����=�0��ͦ�m��"�����=�8��SB>��#%�į���pF�a�۹�X�����Y��'����;�{JMɅ%䙰M���c��n�E����={��5 ���:K��P`s����6��M+|���sŴ����|�=���x�"�(��I������F���v�{�o4Z7:P5� �	XsVƬ�hYd�O!r��;��y�Ԙ<H��|fi�D"���[[�����{�ln�&�2��hA��|u��	Ya`�e��B+���/*���LLGvep3��*��,� �Y��O:AxT-�hiT�|��7�CԠa��М;�q"o�H�<�]UM�$e%d�?$��\�z�kWgz���M�>�l75Z���,/��.��d�cc|���V����%iذ4����B��!/�� �Y�q��g�F�l$�
]�d �#�*pȮ���Q�D������UcF�k��g�)�\a2R�_��t���KBQ�x��a˭�q����/cwO�.���h7V�����ר�D�G����0��s{�
��S*��N���-�MT�n�*F�?l̕-W\�6�6���!�Ȯ�nl�ϟæ�$Px���^�����:Mx�.)�?��L�5�+tү�]�Yo�ӭ��oȡ���|�ߚ�������/��<�֝t$¡%�Y4P��E+�~���"-��S�;X�ퟃ>r��#�ވH�CWF�񅒺钴>4��3���Y�l�JJ��vU����[��!L^��̧bM���ԏ}_�BŞU4o�C.��	�(h������Y�m��.E������.6�/�����py���g�n�i�w������VA�)~���V-}ɣ��2�^rQ��������?�1��+�%!{�[�)��d�/J/}�X�A�����ټ1�b�}{$�hhO6(�˲w_��~�1*X_�7�,*��y�g��x�.��tI�~<
��>�(J��}m[�`�PµMR��_�+��a��N79�W1�6�x|uI��⺪f�E�|��#�ԀeC�=�v���ː��QgVRL��+��`�v�*l�Q���1�M1�3��������&�FR��X�q����&`Wo:	߾@G�bq��c�4L��Sm	�H[����ݕY
��n��sMy��yUJ�VL,5���8Р.�������ζ�c�2�&�tn��AW���e�dTޯ�◽H�y��ݎ�k��ޚ!ܣ�)%rn�kR�%���s
~tl����$�ae�'�om�}�a�N�w�w�������e�O5L���PF4ȒʖA����Y䳚�Kze|�ȕ�κ�$U���?\C2\k@�y������-I{��9ZP	� ۿ�2�X�DLOw��p9���x�I��,{1�|�h�؅@R�YS���@@�������)�Ba�XO0�@�6y��4�uk�)G��j���g#<^�gRq�dk��Fe�wF�l5J/�#�HJ`f7��W���A�+������D#��cN$�@��3f���7�qK�~�7.�L�@c�XY��R(M�}0�`��-�`�4����(RQK�_�벅NsRQ,�l�l>��^���Nfe5�aR0o�t?<��G$���Bj�d��G�0����6����ݲ��~7]�v�G69�+-��H�iG����S��w�)�|�$����gXK����������,��.�v�.�7�|������u���$[\4��瘵��N	 j"���d�g�Tt´�m`0..�⹜H�˷w&��A^��yQGZ�}�g�r�*��i���M����)X��M��Z]�韟�z���`�<�Y�,l�hr�^*�: ��u�P����]�?ٰ
lF�8��[�B�}�+=~�cu&b��
�G:��Cz㕂�F���ͦ�}�7�P�P/���#{��!H�ܑ�����{gK����r���tC��Y�C[�Ȑ�pu��֦��pl�26�|| |�Xe
��Nꛦ����Y��Fd���y��� &��p�r`L��뤊����D�ͅ��`��H̅#�����r�*��Қi%���Sx=(1{����Y)��J����z&jۣ���&����a�e	�H�Gv�����8���ߕ�.:�>>"#�>��\����fō/IK>1<�Ѻ�N��U,�?��!�P�L^S��1�F�g��,	gB���Ɨ�c`I�;v��� B>H�9��}8�z7yQt��J�r�'"�3θV��4<��(/��iʃ�f�x�����:^���N�+T���I:ŇV�\i��}*���&ɤ���>���"2�O�����6����x}����F��v2"��f��dm�$�7��I)l��D�M��6r�VG�a�������o�U�P�ɳ��������y-1�+X�4�▆r��K�������.:�+� � 	�qC10ۘ9�*'��[H�\�T��s��YB��
�\�`?�"r~K�ߴAS�y���s0�@��>n6v������1��l+���NI��ϼ&ah<E�����G�&�)��՚m�Z>7kp~z��z���Y�>�K(sVN	v^.�aY����®�j[�#Z�K�.N��v�kᜭN�|`�1�6�K�r,��b�n�	9ZV���vW��h�	��L+1{�ˌ�$����v� ���u�q����vRM뢢!9���s�H�җ�sQ��rϯ��= |�0_�Y-�X�Ж�"��P�Sœ��z]����ћ�����:�3xN@��}k#/9Qon���z��!
�҂���{T'�?�JL�mWw8���Z;�V"W�A����ͿYTm1��O��[U���pe24�{�$����<��	}+c�K���gM��K518�
@1�܎蒚������������U��p�z2`|[�r��9YQC�)�`H�$��W�j�W�� ,�ـ�#�g�q�P%[�/	r*� �m�/T�'��jN���g%��v����x}T���Ї�]]O�z��;���=ͺ��7Uh���[������lj�$���(�.��HI�t[�\/4�F&N�5S��=�d��Z��ܐ�%}����A��;HE�:�1�!��_ة�d�K��+Ә��x(	�"��Oj�A�8�9�ur槩����m�W��"0�a �Y��u�+��d~�")3��L���F��|�-G��-�)�s|M1z��	!��h�b�Q� ��(v�@���[��71��9�{��3����A�ֹ�1	9{f�>���	��z�v��k0b��h�RI��o�O��k(��|7/�Ұp��C�ƟFӮ*�/�N�8(K7��[_*<4���<�6Wt�S��.����m� ��I(�T\=��ܫ�
�Zf.���W�K��/�w�R�&�B����45���ؓɕa�j��@jK��ё���� �Ǖ�T��ca���Y�(<Mͤ�����4�֊/^LF���ϗ=���B�l��`C�H�� c�~|�q?�=t�)�gz�SH\?H�[|H�*�}�ǣw�[�=�EtU�l_z{{$�D��|��lZp�e9��@O��)��l�.�?ȏ���uL��XG�H���l��'��9X���/��� ��L���R���r~
�̓3����y������v*���*�̛�JX���xjp޻({-�1~h`<>'X� ��7WHX���y���K��-��j#ל�է��ds�v"��=���F��/8��y��q�n1�����$~�cV��׃����Q��X����}�#h����UN�0��(�M�Fz��-ǆ4&j\����u�O�L8-�R`Vn��~��1��P
���\�p�Y~��D�p�ۘ<(9����ɾ�F��0�җ��1�'�{t2.��\�S��e���֖+��]�m#��z��AHK�b��~'�`+�P��ʡ͔a�aL��x����!ϗQ�� �W{��7�M=����eR�%�����c�2RaALϺ5� !NK�~+��gƻF��2E�b�gV����R�%0q�O��Y�6? ����d$ ����j5�����$�R�ꤗ�Zp���F�'��uĎ��O-�FE3��t{JN�4g�����v5�y�� 2o�N����V<�>:5_�g�U�q��j?�5�NN�Ӡ���пP�|�dK'a�2�$���P7�c��KzA1��E�;s{7�1\�I�ۗ�$ʣ�N<=F����׋��ߠ�]�4Nv+�)�枟��D�:��)Zě��$�G臯����H2H��
f�Ǎ�j���m2�Z���%T��K[�0���%~9����*ȼhzJl �I�[�$�/�W��{�[�WBLʝS�ë���W�#��v���F����J�,��g�q����<A.��K�^f� �&'����3=O�N��/�5zQ[/�=n�s�&jߥt�CZ��`W�a��'Wb�	�@��m�@Rɽm�2�0�E���#�6|g�CC��~x �nf�S�l���h+ЧD����]�u�aG�u%8zǡ�ci�Q��v���{�����eJa����)�4a���%�zm8q��.W�2���Y�~q��k�Wԓ:�@�򃞷s?�?�~^"�Lv-�J�N�iIK	�)%_,V�o����Ո�@�&�qYH�ݩ0��X &2���Y�k$dΡ/Ÿ`E��u�y�H�y���s$fA�?���J�W�*0��U�l���1�\,����g�V��^y�R�
F���<�9��������у�s=[�=(6/�[є����a?'Sk<o�),jX���J�l��)��(�ڱܷ�a��Y�/�yր��G�LY�n�5[�@̧�v}и��{�}�� �g<�A&�M}����N+����7�x��,�_u:ܚ,�����ހ�5�E��e�fi,��iu���=3W��$!�o���E���"��z@FJ̖�A���P���7���mD(�l�<�ușrc�{rl���;xO�q�LW��3���OR3�r d�GZ{��1Z�+`Bޤ�*�)D���|B�.�nk2����1�(�$}!�q{I���pu/�=8�fM�˒�g��[`X�I�b�\.2Ey#�!M �%�|��V���P�7T5X��1�O�؋�/S�:|�ܘ�[��+��<ڈ�z����+3Ŵ�II��d�BB��8Џr9+��y\���OF�2�T<s杵�X>H�Gl �y�Ͷ�����#�?2���ӏ���-�o���+ƅfe������f�A�:���ms4j��p�ZWq+uXg����#QI�����@���0��R5w7��g��qPP�6�=�/ѧOK?���j�����g���}���H?�>���"�.F�L��}��C	��7gtow��Ŀ���w	1�Ӕu�5e�8U%�#��r�j- �1�>���|���O�8̰�P��"�+���<�\��G| ��2;,%*��e���074r6K\��cwrtc{��9h~9‟��&�?Èp��R��]��z�`�!��݃�?C��Q}?��q1|�$]�Q�e��g��&_m4���"N����:`q\����!��ӱg�{��U#{�l'� ���K��iP��z,���|ro���yw��@��"D����e/饱�]�ja��#�����4���m˫�1
�\�F���Y�bt{|~	��,]f�E�zUI���Nm��L@3'뾠|�ZB�lc
���+&��IB��z�l�
��1|��J<R��)o����oϫ�7���4^Nk�&�n��x&������ICbm� �#�08�!��Hr�0u�-�C���|`�7��i`���R_�R�;�����IG�L��
Ғ�F�12|�e�7a�+�x�
����%^|�h� �05o�L��o���l��m���J�g�.F�7�<.���x^H��]��qT�e�,Ԛw�إV�_���~�E���ow���{��-T[�w����`�d.�I�~lE�Q�qn�<Ym���֩����Y
�ӹ"ト���4�ߡ��NyͱL�iv {�ᐏz�es'psط�;QT+ƋF,-�C��ӇK@WS��!���ܚ�j�0*���K�#��8z��룿��U'�ث�&�����xzי'x����$�.̒���n��KHwO�
@�g`�$R'51P��#0��۶�j��yѢy��vj#*L���4fRQ-<�\�g��}@�p1�[�?�6�q�5E���д�rMU��vt<������w-����#�b�ȷo���E&�B8�=����ۯ���}�*#���~����5�������ːN�>ih���gVNa��l�'��*-�RNЃ۞\�k����&�P��!~�yu��tz��1������/�=$M�k:����[��LB�q�����J�}�mq����D�����ה�P�-���]{ݵ'��Kn		R��3c���E#�}n�۽w�+�z�Q�-��%�Ѫ���\Q����Q4��]KSE�E�sϞ��5:u�XG�vu�\Z���A��k�}?���^�Ug�$y���0�24;<�f;7Q��u݌䳶��,3so������Ƽ1��^`�eB���qM�0A�����^Z�Q�
��qIt�L-:lw%>�H�5��%�iQ\?��J��~;|����O��%�D��[��Y�qQ����,��X�M����6韊/X����씎��Rk��#�����U珣���7AP=�fF*?�ȷYR4�Yށxw-�f�i�F�n#�_�/&Y���DZZ5K4�m��hc[u�0�嗧EM	d��#eR�_cÍ�hmuɯa�d[��6X;�E�0��8E������K��%�0��4Y=h�����h4+��;=��/��]�h�`LME�0YٱQ�6
\0�J�3kn�A���Ukp5�l�V5��L��2 �}U��ZF���6q���VJ��(7�������m���!jw���ҳL��a�5>9�G�x|��"�&��%I�ǦS�;�K�u�E�'0L}Q�50Ӭ
%��"H�����S�'�p!�
���%{�6+Y��垙�ĕ�/�3�"AZ��lND��n�If�Xcwos�����1��s��z߆�}�]�e=RHq?C$x�a��#כݮ�4��m�����2�/:湔,�d�ތ�N��M�A����t|g���*�:'G^	�#����W�������p������n4M<j�n��m���R���,#�4�w��7�:SCӢH��&Ww'�R�,��E�xY��Ύ��{~i�/-enw��j_$�j�t�g�4�;Ѱp2����\Qv���O�@j5�L|���ù�{�SZ����}U��Z<�Ƌ@D��=7�|`�G<i���Tx�c�u~�������̒> \���T�ZC��{���UkKi2a��X��+zPY��b�eh	���SC���f�9��έ�Ga}� �Yc�u�]��~�k��O<v}�p���͙b���TP�R�K�ڿޞ�N�iy�z`>����r֒K���uϳ-�D����]�C+�4��D옆��.,Qg�ػ�Jc��Ʌp`^�ɂ�߈l�l�9��#�T��\ȦQ U�=C�9� #�7Afv���n}��>-!�ΝsA��Z�I���H0�'���gرj�م��z�(3Yl�Ň���n���A��*K���}4-�5��`�f��y]��/��P��}a�U��[���ӫR쪮�?��?����ū���,�$�|�&ַ�׃�.�CU�܋>`آv�Ga����eK�>u>��U�#፶��ڴ�}(m�:��_�u�-��/@�-^�- �A,RI8[�yy����Qc����W�����X	g��t}��G��NrrT�~�>*@ Ãw�ķX�CB��g�T�o�o%#�|e�u��L`��VB~:�c	�o���`�o����8"���8�-k�� ܅��Z�Twۤ�N�N�c���ή-��&��<^C�<��s4i&x��u�I��#W3����w�����yf�n�A�b��s1\)�>Ư���!N@��n�ߒ"ܭ�u����_l�@&�	�> �Son�K���P�X�����u׽"�$Q�\�B�'�+�g��`���&��ƌ~�A4����؀�;a(C������2#�j� ���m�@���;(�StU�7�#~CC���$�k}�z���@�	!�˫�/ql�k���)=O���r��3&^Z:i.qU(.4f������L\���\���Y���q@���t��A�d�����j��H�o* �|�k���B:������zؔ�����S1?�5g��WI��U�$��^s��:P�� I}j5���)�$��\�pں����D\��B�{�1o��w�%�%{_�P��O��Rɉ���8��۱P�C��L���2SdZ0ѾC���"���,W�����ma�؍c�,*�4R׼Ms��v^����f�?"\� `q��.wr�Q#Wq�$v��K[�P^����T�.�V��0�v`�fg�L?t�fǴ&�ef�]��a�S��ɨzg��v `�i{#5��z��}�t �d�n����90A�?����5�'�t�·滔Mױ������i���@B�T,�e��!����Չv+�5�*�����o�3YZl�_�<���m�u�nW�"�ϗ��)��	��0`�8������!I�^
Z1���&��2�0����d=Ξ�����w�w+�������O�t���&9ۧ�_/� ��i�3�d&Q�����PJUl�_�g'Fs)J��i���)h�~�\Q�[�<,���X�
_�M�7'АÀ�OF���ᬢ���[~Τ�-9�!��!_�GxAY������,)�9���¤������ ~-+���`0�O����5ѝS�W���;��V3$�A)X�ȡ�ɴ�S��R�[�E�uӖC�M�!�-���ag��=@.Qګ�E3�� ؛��s��l��}zwY�_��R����8p�ڥ�(����M�����5��\�l���(,\@\���ӈ��K9f.�vf�P˲�ߌ9����=u��~Ƥ����`�EjES�5�!8����E��V(�Rla�\1�w� ���=-s�O����UP��ٜ��Y���{1[�E�L�TM� ��$I��~nA���5��;�R�l��A�9Q7��uOڐ� b4��<iC^���~�2�JaKD�: d��.��ڰ"������>�M��鵟ӗ�W�N�$�5�^�|}=tjݽ N�2~��A��a$k1���w/%V�s@����i�TQ�m(B�bw�i���x��A�oQ��BTx����qN��	�9rl?�;�^xlG��PmՋ=e�O�c4=���}#~���4��l,����+3�����s�ڲL@/x�{���n�e���&��2��/G^Ck��Gy�RM\�C������t�9��������2��.���.i��[�vy�o<��E��<����������!�L���n�;�m�J����=]�z���t�9��s��E��!ZωT\7������Z���P��#aͣEl ,����#==��1�Ju������>������6��ZV0g���i@�%��Ƀ��Y�V,Ұ2�s�Y!�m���gXc����ΙĊObX���'/o��!NVT�1�xx�bF2�0��68-h�7< �ΎN��Cym~��9����cm\۰��N�[��>𱅾o�f��i����W����-u^H[�Sm<'bq,���}XGB,
��-�U��foi�඼Av�}�%y�R�b���?&�:��t��`�2>�XK�:�V��:Q�+hQ>�&h% ��zO�rE��qU��#4	���٨���C�d��L�E3��zyOō��:&q��/�G1�O$�5w�$�n�?�P�X����>%a�^�3��q)CȇF�x4�ܓ��1�l�9 ��7%�U~i�·��	�,�C�vX�?�~%��5"Ďl�F_��ݽal�S6�`��=��A�M�rw��D��"}�w���u���x�`3���1�����9�zǎ�/�Y�Z����9������n=zAwG����ϕ2��qs�):��:�������`� �c��a�:{�Յۜ5�}�U�Z��|r7��v�jƽ���=�{Z��^��eq��-Ķ���d�|W�����M��P6vݪp���=y�{�}ֽ��W���.q�	w�!����{\7Y<Ȯ\��{$v�4�~���E��x�`Ҫ ~C�C��^
i���r��Y�*
�~��bX�H�S��SMlފ8���ѶK'��d�a�E+�˒	QK^6�^�:�*!��*}�q�)��!;���j76�Ͱ�o.��x����(��v��Z�`~�� @=IeX�f�A�$rHIЛT��nL�,A��q/��vZ0Id3�0�fb�L��^������3?U�Ď��\A��i�.r�֩��7z�*?�|wۊ��ҩ��	��O0���yf�/4��-P
�ÿ��o��ǚytUm��l7�9P_����l��?$��0qZ�G�hOz�Y�~��p�wB��{F�.�u2N�����"�!�3��J��XKYj��H좈e=�"M�#M�����geC��򣧵�_Y��	*����Oh�L��Y(WΩd'�߅4b��/�*wA�o��m�nKݢx{i����ˢ��0������,[D�Ujy����_VH:����_X���g�_�z���&x��G��OH����'O��s�b��,���v�^b�]����5�t�cU.�����!��(V�>j��V		P�|.�QoZUT��C={�$�����N�R�@
�B��8��d� �k���OQB����+�װ[�e��P�{��?�9]RQZ/�Ȳ�;I��s��О�H���=�����w���}M�'��)*��ݤ�����	�kd9[�Ny�:�����M&X�($e^ENV�����$ֿ[�rt�Y�b��/�X,ġ��~U42��i��6����@Mq��j��l�����dJ@v�nݑ�D\0&�?n���Nߺ퍄�UE��V;|b�SL��0�|6J@�9��97T��AP����R<k���@��<���Fh�J��=�}<%�u��^ja2^����]��aCp�_ie"��|�uX��'�o������];�L����|���0���L>��,;m�������I�?K��e+{˰�>����hܖ���֥�˘�F�S���n��ǚ�nc�t,9��ʭ���ن�ku��t#�(2�&���9�p?Ď��#��Sݳe��@\�ڔ=
Unc�0�XC(6iۑ����ɾe�2�P[D�-1��'����%7&�c��R�f�1���Wu�Y�h�.#ek����}kfi/R3h>�9��]��Y��^�4|��^�"�g�X���t�h&`Zb����W�ʍ�%B�ۅȿ.���c@�E��Y�çw@�35^
l���-$��==��������Ѳ�^Ί[Hk��`c�,t`T*�P�j���T:S2��u�3>�T���A��b~{[u�� Т��qI���)�q1��a���������4��R�-�� 1R.�M:z��WB���7�ε�|7y���̅둊?$a��fg��k�-M�b��y �`>Wq����ƕ^`c�o�](Ȅ(�Z����WF���bdF��zP�8o�5���� w�R�/I)/̃�l˜b1�EPHV	+�؛M�{��LvbۍI��9���^"�DY:�t��F}�)F
*�S��^����ly�&bB�c�:q����1��]�$���+p.IĤ@e�H�T�j4q���9�����q�H�ԋ����ٍ��Z���saS��u`*�����ILM*��~e�	9@/�Y����Ϗ���<آd��^a����=�X�"�.�IϺ�^�{�ﮪ��(����˅�-q�"�F{g��9*uI�Rtq�h�ز��]�
�����N�����96K��Hk�p��EzH :�։��qq`��u�)�K83w�W5����{Q�>�	���Ju0�|�<Q����%�g)Eޚ��(p<\��&�3c�M���M�P]aO�G"a�8����u\/z2m�[�S@ѓv_Q��[Ju�WV�/�H:��"�%9�#�����u.��P�´�]��ۆM�i�O�H����-�B��!��d�L�Q�Z�(�-��XA�zl�W�<m�5!޲���߁��?[�XP%S$K�J�������$��إ^�Í����m���{!?�p����?�I�U��� ��hb�dkH�: e�˕L�ш��w�/-zUL�$zW[[�V�w6�m�9�i���{��_��rC;>{,-t��m4Ц�Ԑo�4M�w�F�}�`���b���K�9]?�M�4$���H���CI[��LZ�Ӿ���vH����x�q��5s��j��cA}�Uǆ��Ng���@eU����Č�N0ta	͈p�Ո���C�9�@dYt?��WI�A�1]F�	�,����%�QTA��v�8� Ct'p���g��߯����=����wV �p��b��2L�f	�MX���zW�Na�,��  �X`���nt��s�Ϧ�X����L��~��ܬ_n^M���"4F��Z.�9x�j��"�� �Џ����:"�]ٮ����
��5	�(��	]�n�V6 �F�^��Q��E(�'t�g�R��\󷙭mg~�N�r����J9!�_,��L�0;��J��^�PGi �U���<t�k��<��_��0Q�55;:����IwKі���I�gv�d���*f�|k�#�r��P� �j���㈞ҌE��2���V�P8��}�A}�&>z=�C��	��ά���%]�>h}���ʂ�1jc3��\���BޯZbXD�	Lfߘmq�[{�EO��SYd��ay�(�2�����c�2k�&{�L'��~��N+�}AL.-�f��U5���g�d���m�vz֘�>�-.��`ޟ%'�1�'q��� �+ �d�דI{�Ŕ-�؃@Xut�݋��2i`�i�딪��6)zzUHv����0\�)=��$Ā�@%R��>M�6C�T$d+�q�e����N�ʮ�@u<;����m+���n^E�hFbHd��J���"#���Ѫh�h����Lz(���_y�M���7%��N��*���M�r�95�"��ɂ�޾�3�eV�ܕg�y�30^ܝU�y��$��U^�,�s_��ѩ�I�+�D#T�i� `xS$i�H��Ғ�$v���Ϫ�{����iX����ʑ>6NO����J�WC̵r�����%̵Xݬ,&�@��6�nW]z-Ã�gwF������h̿5�.KJy�$�S�S~̘)���4%8�6
9�L�/�ATG�|Xܧ�PǙ� ;C��ێY�������=���oơ������ao�ם"�o��E�����r� �P�an�H~��0l�ĳqi��`��ǈTJ9��p�7�2a�{yӮu���W)rAܼ'=\����3���ķѢʡ�k���ƲE��d�����T���\Cy��-�(�pת�^S�#��Ϳi;d6𥳐9�su(*;zW*I �S"�PZ��TT)��[�i(\���"�x��hK}y�r���&�eM��~��"e��W{���^W=q0L���f���h0�.#��:�I
t �{�i�Pm���(eH
�1y�1�&X��d>�<k?����%��[ǟ���et�o��[��D���?&���p6s_܇�Ϗ�G����!��~G�'���!֖�+�6�G<�<���B8n�w���-����$	8��c=��,�j�M�P@o'��ڤj�����7��$�Y�y�2-��7X�^'#���f%��5��+kH	!���IO	�Qj�j�W�E��%i��
��_6kL+���T}Zm;�<�0Ƿ�yOw�1QD h�-���}�ڜ&҇�W�{�^�5�DT�	�ɚ��S+��pMߛ��q����f�W���������']��F~��g�7v$�
��j���V�;�F�f�ʒO u���U���&1���Ä�!�}eE`\j^��Z.�r���]Bs�K��S{;�2k����F�H�V��%�Gw�J�mT���M�$=��Uy[���
�a-m�|KU�5��ƥ��ʞr�k�"�&���D��-B0Tw��~�9�p�7~�w�đ^��Ztc�����^��OkS4�"�&3�4E{���$����� [�egYu�Y����8���8}۷"4ܢ�!;TV��Y/~�n�,�:�5�Uj��u�6���=u�c+ge�0���!��\��ϜR� �
�wG%w���qR�&���=!C`Y�Ѱ��bE��F]�I��>� 
3\��΃1��x�el8!Dp���-���&��ʈ\$ڌ����Kw/c� �-�5&��1���+�_1,�ZJ�w�Ԕ�q�l��0���n���^�0c�/�`�X�(�Fq/��G�ϥ��/�3�s�K6t����Tþ@Thif=+L�}��^\�|V*{���J=�����; @}����l�
�X���i��-��Z�
�d�7H�/���3G���oB=A�w��e}��l¾��q�D���^Y�$���T�%��+2�Ao����.4zw+����B',o%u�g��@�t�@&bH���t��������#F���@��ϝ�nA�O{�,����a;�#V�U�t�Dg��q;Q"y�9~�J�%[	��&o��+u�k.w��@Ӯ
Yn��-���^�v6Uv���큄 �\�M��O��g�����P�B4+�ᤩ���=%���ә���A@O�9���V�]��nRgr�����)������8��w������&�-�����D��1�QNfL��x�D2�8|0�>�#0�Dc噕���G~�p3v���44�ς�e�I�`'��9��H�4^�]n�Ep���oLn�/�`�V�{��W�E�qVѵ��VI�����b)'AμԂ��v��vU��o���Qb�~������C���r\VJ��/3�ܣܥEޮ@�����ϧŬW��8ꊢ�B�;��4K�'��6@��& �Щ��=���$'UG�V���w6�a@�;�Cd�v�N�����K]li[�&<U��S<\Z�x��؈M�����2���ۑ��H��(�S�ύR;M�6{���.�u8Dcx^[��p3f��~/1�*p��C�uW���\����z��3D���u����鱡P%TB���{���h���B#j����xK�0V}V��Q�.���j���!�2�1@�~l��4�+�fP��eq7�b���1�E]D�2�P�[�y'�S��-���-����0b�H�a��92�e⧋�ty�wV	��< v�2�tӪ���QNl#��1����E�=���I������YB� �heB�Z��^5M�ʌM>EK�7U|��[!p|�]�z���)8��1@��tw������ٲ����V=�Q���&���"c��e��Ȟk����=�&2�ٰ�Y��H�7' $��l� �~I{���E�#Ss6��@��_���h�.�}�\�)*����c/H=R0}��XH*Xӫ��S���q5 ��wZg�.-@��ND�������H�M���ث?)r4��YqT�:�IJ 0&?`���fyQ�-<kV�W��t~��h�2��3����k�X�� �v���d�Ƃt���cNy��~���[;���]Q1�D3��I�MQK����]�d"�J�����O��P���O��[�Y��e��;G��åLw	VpQSz":b���F�<���	f`@ˡ��ތ��!X� �y�����!��Q�8�<�	{�Q������,|�
�w��2�$v�U3xG3�}�ڔ??���ײ�d�������V/*ߞ�Bd�1o�q����� h�5�#�q��l�Ҵ#w)��_�Vi�^�VzT�5#/�4�O��@��;����o󗬩<�ݶ���������=��Ao�����"��b�,X��ǹ��(���H�=��a�X
P��E7�ҜؠyJ�(�
2U����A�e��@�����tˤ�"H�e�(���]��r2͒��g/�L��J�������ko�'��<GF7���ɬ�	Ķ�A )V�;�N;���Mx�S��D+��!��#֟�����9"@D���)@��җ�m\Ԑ�b���G�<���d�ɫ�Z�낷�x�(aU�1���:��ۃ�B�� i�-H���o|�S0p��������=���:s�`�ɮ`di�<�~��QB��!T� �
�r�t�+e����0��ހ�}0GJ�\�{l��/��2����o@7�z�/Z�~\9�<�ŭ�cݭ!5���5��;��D!�]�rc�� ?�]��"x�q0�jr��e.�r�&��Q݊d�K�����gw�5�k�_=�Bv"�[�5��W��J��X_��YR������fhM��
�Omҹ��5�UN�[�G(��AA��gJt�jE�H���|4�����G���G�ən(44�w�&΂��Xr�r>�؜'�%�.4�sc(R;�prn�m�����~<G��>^�������G�����S9�@���ПVC��יHv�q�h�Ja
س��{y]�`Hđ�"�����V�<��[���漩�c��6t���͠��a�����f�w!>��� �m��L�'�16� m��	�7������®\�:R{�c�4�/�u�›�}L$����J����i��6�x��q�hr�n,�lƩ};LB�g%G%!L;=}c�O܌I��'��vZ(,�A����
�$ |<����aUY!�Z��`�>@v����Υ����-;�xR�
�v�R�*���������}����+Ӷ�"�X�
&]�z1������sK?v�=�	5��tˌ� _�F>�_��_���x�w8�=�A!�S���;�j(� ڹ�:�����x\���a'L)�ź/z��Mi��8�W�eh{ѕG.^��m�9�4���<�ѵ�WY��b�ї��s-�l�e�hԢƮi��/G�c�����uQ�×9���bogo�$y�O��Jr��s��J(����?Ȭ��5#���:��K#
=H�������O���k���e$ᓀy�D���
L,oXe���MtV[><�x߬h�Ǟ�Vȭ�q���e�w�/@1X4h&s��*4�*�����f+ٜ�=E�b]��QR��${*�D��]r����.r�E�U)��1�f�X�����iteZ�w���K	)�]ndS�C/��J+��ؗF�4�>5:Q[�*;�1��$���w��v�Ǫ�n��L"F�c�dG��4W����-�ݭ4S��C���;&	e�#_4�|,�m�����3��+R�@{�����f�z����=�O%�-o�`�U����(��8�ۑ%<�
.ns��ΠsF�XAi�����ّ��x3�y�HX�q�Lw��y�E��͊cEYH�*�Y�LI�a��B�:�J �t�ĔP~�2A�U��+3�����b&����-Fo?]j���(�a�p%��/f��/]�t�S
N���M�ɧ�0Xb�>AJ<��G��d�2��%ָ�9s��c�p�0�zQ�[��AE���ѯ蛗�i�66�Ƹ����C��0B���4mY�T�_��[`H_��o�i�J�qG�w�w�3�z��a�&H2}r�/�l{
'G�0B0�필����p ��V�EsA4id��&Ny%!o�����*�P̅����up�)~a��D��y��oj�L�yv�����h%R`��T~���0��[�(���0�xB��������������= �Z)iyqK���p��Mq�v�m'}/�ǽ�Uc��m��I�h��3�M�<�3L5�õFGP�
`[�&�'�1��k��^ƨ��6�iv�
��^!�!Ѹ��F��祢��G��ٹ@��+�h���;#�N��t���rWdi�@�[�v�vє�̖h�(�5�鰛�٦�\X&s��7���҉� d,�i����R�*��b���Km�H��}��)��G���u"�)�)�J`xj��V�r���1�
�eQU����H;6tߟ�A� 6��.C�!��^����-�y'-2���bZ�sNY(�A�d����e�ه�/fZ 
D��/��O�3k��w�+�"�3U��R���w�ʺ�����	�+|۶ؕ��]��Te���S��i��V����>�����k}^��M�S��d�-��4Q�HH���9�-]�/�8�.w����*�I4�a��#��>�yZ�bL<���=~!��@�e��:��N"���'\��"}�� ��)\W�h�s �i��f`�@�i� �y�̍����E�^�}���,�'q��I�ܲ-�a�	E�Ke��SW��I0#c#Y쯠�)���1�ޓ��Z�*-�B�A�b�e��"�&ޘ*P� ��g��,;J�R9�a�;�m��w���zm~�0ː>�3��S��9�Ѕ�8��xpIlzJ_��{�-��$&�/%df��3hJm"����/�dAבM��2�U�[�U)	�3���߉b�/�=��j�lN󠉁�D�!���FMLg�+�֢�q�+�A�����J�j�9�h,�R����Wբ��:2�R��*X	���j��Y�l�7����+)��B�ޓ�u\?\������!������?�0LXR4�X�z�sSx�+B�N��c�{x�5H<������ʴN�r᤟��0[�h��k""�"�*�V:�#=A�s��ҷR�������L�= �~0���2T|���#���_?�~���T����O���T�ArA�X@�{���p����:��"��袓&{���n�9=�����#k\�!�ܱm��n0���]b��PĹ�gqƀ��1&�#�o��u���Y@�c�4C�L�u#�a^?*�n�AO�O��Oq�.T ����^]���c�z�$:W�AUB�VC�ê[���+a,����C�*W�ymܺ���6�snNv(
<�b��?�����I�S��sZ"����ga&PҨA3٪�#��Aĭ55�O�rE^�*��r5)en�Ŷs=���/���e�9��S���%@�s2���Ĉ ��zsG�k�J@h�s	�!!�9[ ���t�a/�HV��V��QF��H8nz����`��X�0K�E��u����ˑ��ձ%3��oN#q6� ��!��f�޹�y��?iN̕����:��?�
�ҋ ����� ����q�bjְ��Å�	pZ� ��`�����:��@��l`�|u�sd�U��fz�H��L�,Z�pz6��E�	��; l#�wi�1��qHyQ0�d:��P;!�WT�QnWm�lQ�(D'�' ���W@l�:�Fa!RNLL.�����yo``�mzʝ�?����͝�Hk��CZ�0�DfU�ө�Ƚ^u�	x�_�kV{	�D�Z�   �D�iC% ����*X��g�    YZ