#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3710175462"
MD5="5f2e090a1e5945f41959b02d770e30fe"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25548"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 19:29:59 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���c�] �}��1Dd]����P�t�D�"ۏ�P�-���4�3q-[_=�����Ӗ*��&��:���d�Y����O1�:���/�4�d���3ڃ�7�_�urڦ�� +��{�W�6�g��.E��#�]�YN�5���=8�sX��jBg���'�\�}�\:2�}�v�~c���x���^H��s�z�m�
��T暉�(�
p\?�W��%p�· �On3�N�4W��X�H��ܸH�s�O�$�u֐�ї��a��\3'�e�iǰ0���?5D! 4؂�<��Q��}6xK�^��OL�P�O���,AŴU7�?Q���&�(_����lT��R׀���Ѹs�q>"JFB	�?�.�.��<qK����<^��-;�&�rB�L!�d���l�ʽ0��dH�xƁ��r�Ͱ�q �f����⧜���vے�%u�P��o���&c&�:�_x�����C/w�1u��b��s`9� �u�
�$��fj��3�3�Ⱥ�#N��Q���$9�A�6~%�N/ �uh��w,���pR�b0��f���A6raU����g ,�3�3�N�΋�҆Yjy���r�T-,���s�d���`�T�2�$�>��vf���?Abk��K5�6�� 6�������N��H���-ls;E����V�O��WGj����Z�����գ�u�g��eܭ2�Hǫ�������L�U7��B��=�CU��=}�']q�âUUv��N����t�����Ƒ-!h~�KT-h��Q�rh0���a�|~����mf�t�·aW{)O�Cjk��ۅ���o��7F�]�ٹ	͇>�߄G2<�+S�D��:�3ugb�9�/p������w��:	�p|�Af�h��'������)�u�0,���G���

�>���~c���-w�e�|�X����K~d�
�,��R��$�5D���/2/Y�y&��^��6+�1��S�N����Ow�˶C�eL��X�6�+,���Up�J���P�E{���X�zF6����C��	4:hIh�\cc�7vf2.f��k����[�5��o����]	���-"qU/x�:$W�e��$?@�υ�V�R�[v�oG�0�ef���0�-w٤=t��F�&���)��]5�,5��Ԇ��7��@�f>Ut��o�/���*��	�0 �8=���������u��-w]iOQ�F�{Wd�����'M!A�PO���� ��O/��'�$�%yz�k@�WJ�٢%~:\����v[?�ҏ 5�IGP�+����8nU6�2��E����6K��V��j|{Z�	b%�@w��ɡ����,ZCw=���Z4���4)P�h!�f�c��?#�y> �^�g��XfȼL��S6I-X����Z�  �i�~-�����d+6�}�6�!�� $gkXK2���(}ᡆA�+W�H�]H��� ?�5�*��/9�Qt�=�\{�����='t�E�L�IR<���<ޑ��T�r;7���(�LW�{:�da��+ب��g/��D>��=�0x��"����-N�ׁ�ӽ8��m+�}�p�n���G�pu�f�0"]��U=չ�'ɴ0�S�.���F���=��n�-%�hoQӭYq�Ԧ��q����tr��_$�y���_�$:���:
'3I�pJ��V	E
*�]�4�X�m.I%�ޚ@U����i#��e��7��!LƗ��+�����{����
6���*f��h4,���dm/�]ycv��V�I�f��� D�,;�Ym��=<�y���T�OA�A��C_l{���w���v�������{��ɾ���f-�E��C��%�/>� ����\��1����n���l�$�� ���Ը��[d��Ay�����_u��z=q�iM�&�[��)�B)+�#f[�o�]R)�f΢�{��`9�yP�}ȁh�f�4��kc������(�f��)0��d0	H�D[s���k����?�_�-��|��!�G
�~��"�e���ߝ�$3Y�)��i���:	�\}���#��#�DJ�U���+y����6B^q"du��H���9�4����	��>Y4�!��-4��N@2z��E�I�w��B61�\YD���p7f�'|�{~�������R���dŅ��6��!NI:�ЉL���$���Z]2f�s���XL�~��{@��z���.o��O�:MZ������ï�n�� */6(�q�B�
4�x�R�L��3�� @ xNK[� ��*|�t���W2F�9l�=��|kR��3�k�v�xi��N��7��d�ݕ����M8�u�8�ɬ�I��ˏo�Ն���jd@����N�Uml��{�{�������f�G�~տ?��Ko,�;���9~n�M�$�k�Z'�V���|)R-��2H�4A�,��p�����v������b/,ӷE���e�O�p�=lc��tf^]���$��g?�;͇) �r�� ��,|�˞��,ư���f�/��M���P�����	Sy����3����dE�B0�>��.�^ڇp��S���G��MQx�G�����Җ���W`Y'�/��ݬ�CƤ�2�06� ��yC�̋d �Ǿ�Ru������� "]�"4֖	��n�\��Q��i�U�a����צd}4�`���a]���a��Cq9�#]�sy�ɥsV �H�I5]κ�旁Zg��Q��5�Q��[Y$�����i�l��vA�=���ĚG�G/�/"h�I��'=Iݺ���sn�(�Go]�|��恘������r����:��2��O6�v� ��<E���j�!\d!KPH���>^�;��Eh�f�5�u�����Q7��p:�t�2aV�;pI9�
��pO��@��J�zbJ*y���Ⱥ��i�H�b���a����lzB�A≨s��8�;�����j'��`��xw��}��"����*k�s�_us���Zxtl'n͐�_�_�'�O� T�[~W��T�3gg�F��Sw���wx����=>eZ^���ò���J�|gg@&�ݥ;�;~���_�;s�ʧq�-�R���*���u^��s���%D�oU��kk.�#_ȐǁDZ�I*!�F�Q��w�&;^��Z��̺�u�G�]o��^nU�t��4�];Bw��u����M���)�\�=j�ۃ��bHF7�e�C����[�n��.eeM�ٞ�ܿ"KMt��U���1��![-̄2�]���3�ܥ��w�;�x��@)��zF4�+�����Q�u ��J�lð�<���8��'�d<��8��l7?l�	������f\��-w�2�aA. /�#���J�_�_���'a/zu��f�q�h?[*��:l���sS��l�R[Z��tɆL���J���1���\�4{��rV�~���aj�)�NA��y�ۥ�	�F�/�@&�x�K}T���$I��!��;ö1$U����@�t �� �7��C�\��ւ��$A�� �*aHr�!{���������&�δgŝ�=3b6�qh�+R�j�2	��yE�$�d��6��G��ʂ}9�Ee\�g�s��n��3;r�M�ߨO%.q��p�/q��������S���ݭ{M�1���T��x! �w��M��e!�@K��Z��W���M��bh �I+uB -H@�"��>Y�́��>���/<��bg�\S9�r����r���qt�B�J�ݫD���hzD�<�.O��W�#߸����|;���K{9kp8��I�ɫ���#J�� JG�^v�>|��u1��Q��Zu�%s�.Kw����@G0�yh������-͗�N��}*���v �u܊I��T9ٕ5��1�M�K��sؕtm��:�D޷�E6~e����[Hͦ��Z'�,8`���N
��iF�>Qg��I���?�5u�1���ԟ
�����j�g*G�X7��������+�儢�i������.ߑ��X�q��5�$a�~������p+��X"��`K/���A"&�ԁ�0�i>y�������5�����I�%5hYp�ր|}�>��CҰ<c���^�d���������ܤ���OE��� |�$ʒE�buk7����&�W��@OL���&<���G��gk�Y�6��	R�o̧`�/;8:�D7�1�G��n���Ĝ����k�~�ZX�������,��a�?{~_Ł3_����e�C����Sn�e������dq)om�}��Wc-� X%C<�[Gx"�/!�F��(b�0�>-��"^�Z�v��0Q/:� ���\s�ˊ��w2����4-�IG�"�%�f���6V��~a@A���7����.�@Œ�4�r�I�Gz	��`Ss`A8�YX[����G�NU���IV�zs�ӕ)�T&��c�].1����	.�����6�������h��Fֈ�.'ʻ�σt��Kt��#h"7�� l�_��.Z�'��o�E���Wp�Ů������� ��Z�W�%|�Q���-�|S6����X.��PyL ���\P���#/r�9�e�%�ok���݀����fM?�^<Xڤ��~S(����O�w#nh6�%k~j-����Z��z�m40��P,���7Nx��~@xx�� R����>����"�#ў\�T�_�;/���O:�c}��fZ;bψ,�y��bQ:=[���xR{�u�Ն����E�~?'�]xe�0J7��O��f�[ID�Kb�&��aV��o�� K�<���зI�/��zI"�]����s/J+���
�L�Uy�X�SΛ�ߡ�6�'��A:%�����e�9�[.Y��Vi��3$����ib@]�+�t.�8	�5ifs��`0�M;mt�L�N`�;G�i��~�K�\��.b<��	�aBs�)?�-PGS���B�#�"D�6��Q7px�= ����4)�@�|1Gk��-"�
���캠ݶ<��6�2t�)RK~�u�ť<�Lͺ�p@e�ΐ���2n�e�J <>ns�r������Wg�F,t �_��3�n��S�v��k��Hg��[�\a�og"c�"��؛X�Y4S�ОVۏ���7�.s}��nzF5@��{���RS#+�}I�e�^�$Z_��I`�����T;�U������ �mV�q|S߉�|,����e�h�i�3��ڻ<��u���q�?&�t~bW�2Q$LPz���pʧ*
"���C߽��rf �="�[�D��\���Pڀ�/:D�N_�g0+����ހ#�9�S_Έ*�Q��w�N9��oZ�B��������&X�0p[�dD�����"�')��
�d��Zް�#�o�y�	���dpE�(��8g���c�GĊ�������d� E�������~HHj_}�L����n�Nr�1����[d�'�o�&``�!��%�Z�%@�%��ױr}vI$�� ��p�������"��st^6n4��V/fo��S	����m���1'��,#=3#}ol���.�k��z�htV�O�BGk���s��l	f�z��/�JmީcA�}�U�v�o�{k������ K����:�P�O{���F�sW�������'u�U�|-�ۿ��I��V��v�G!��R�S{����zd�y])u���6py��4cFe�ѧ�e�j�4��+&r��qLH��AZ��\�\�}�Zڪ�@ժ�§����B�8�Jh3А{�p�~�`��L��ۥ�W3��\b��96���8�P��?"���<OP��ј�ϊ��5��
�>/<{ �@HL��-�����L�cs_�
�ف^��υ/2��3���PS��  u��"�>�X�6�z㴡n�\�>LzfI�4��S�����]Dr���ގo���M)ḝ7Ҍ@6{��K\'�����a~�3 #E*���\f���oM����F�H�|�� ���I��c���?��n@�����SJ��ʄױ|�'�GN���'��:$�a֫s�����ǔ��@�T�~+Sa�(X���vV~����������~�u�M}��G�ֽ�)�#Jo�����5��x��Hh�)*y�8cw7�N����gqG���u�0���Y�b�R�Җ���`]��� �=i{��ȡ���(ϻ���{��Q!��_Ꮬu!�o�+qA�  �N��k��'{U��:\R82
ս~�����?�ij����1���(Ua�J3�:^[߸x2CO�NYA<)�V�+i��5�}��}�|A���¢,RL��A3{��7�l�,#rId���*����@Ǻ��]c�F�~���B���$���.
�=BIu�鹞CÅ��4�6���F�d��s�%��/���l\��0��-	��{NX�m�x=Q��*�Z�%�{>��n���8�3ʛ�\��(dH5�G]!zN���^�X�h�	�Y�4d�vg�#M������� ��L@OP����U.B���4���N��w���+�8]	<[�G��Zu��(��DGw$_	�}?V��QKW����^"�:�mx�Lr{�kt|,&^�q~��[�z�7���O���&�,*&N���եȊaN(���]���o������u�+D����~����=	d��'2�/� I�O�׶N�Pѐt�����2;�,�Դϒ��s��.zz���ɮIh�:-K�2�iAO~�Z�y�]5:��=�Fh��󵪚��'�W;^�e�����ݰBfSL"p1,E���Yʪ�&��P�'4��0'ƜAk��ஊ���2~ҥ��)��,���8F�x Dt��t���f^�R�ǾfM��Mp�������l�Y��D��SzVe4c�"R�W��\�J�#F����lo��,_.���<���1��Dn\��&\��iy�b=����H�:�C���
�Ym�q�}����E��!k� ����^V��mPt~�9`C
Ҿ������[�O7�2%2|��� �vc�5�88�]�g���6���C�H��<���:���O�wÁ�P�DL9���i�$�tlj��W��'[0����Ò��e\rl�6D�r"�Z\��w�7@�x(�O(#��m��&r�J�~'L&&��Lr�݀�R�f�mUK�Arx��3$��
�ʐ�a��#Wa /��%����C��!�Y�-t�<ut�|������^'k{ֿ�(�gN��H���7�b>[��`�pE��� *�UT>pV�\�W��@�c��� �:XIx,��U�q$y�w������/��;p�y����$q�\x6"O��	��`��ON=�UX�c���IS�1��-�h�_�v<���16Y�K%�0p���'2~|"H��++���U���j��{�+��1q���<2pC�/���حJ 47��%�`��6	���mZ�a�x\�p84�e�oA�~g���V13O0�	Er-�ޑ��jؾ��6��^�N;�vO�'�T�uv/k��-�Uv'�I��aK���?|�^�P�y�üZ���cJ�i������Kk�m/�)C:�5��� �O��YMno�rN�w��_��a��0��ט�M����ƩknOt�RhѨnϾt�4	GY��GV0�^�j7Le(�+�f(��h�;AtR�^���˩�%U`�c�ѱ9,z�Fh�>�nV
�yZ�e�B���!�ذa�xk��Cn֌�]D����+aTκ�M��kR�m�XG��� 4̘3m)��a�cI�����.�8~�� z4����p�@ǵ�Ű��2�O���0|�W���g۱N�� �Y���3��ڼx�Jm�-uz��G:%��#�"�$�h���_luw����;�; �?w*�A]/���;�����d�6����6�1A9�U�&���/���g��P���y���p�-a�����	������Hf��H[��e]�_
=�qU#�W~���ߜߧD���o��#�8���k%et�����;����٫b�=ͳ���ʼ RL��!��4�VT�^d����h�V*�b*���>�z���Y�e�F��O0XI,�F���3.��aM�.���Oܫ�E��֝�S���u���4��&���MS�LƱ�z�Wr��TO���R���^�y�>VwP0��D��țEybj9�3[& ���wf_MCgh�eΪ�R��Y9o�!��\b�rc	"sj�Ϛ$t�U�K��y+/kÒ<���W�9*�t�R�A��8��W'.�K|���}o��4'^�}�L]>�1#�N�0C	�Uy�]��l�;��$Η��P�Dq�%��|�;�����<���Aؒ|�r3/Ev�O�>��U!��F�F���z ���v�_�oꝟZ^�w����G��[j5#Fbvt��(zۆ"� �KL�gP
Iz���x����U��Ԩ�c*��|�&;������fA[��_�;����,^~8��s@a$N�zGz=c�_���ƲG�S>�a=�������ʏ���PD3w�v�P�Zl�����G� Q��U(�Wv�r۵�����(4�)?����F�
�!?6$B���o�'�&8O�I�(��ti�|���i����K�Dv�3�G�`��*�����I<��U1�%7C��lg�	��*��M�K	����Ep�RT�F���9Ҥ$��>K�I�ď)ᰑ�[	����^�^"$��_K�����7�Z�.t|�����8]�����"Ơ]��MQݼ�*�����j�����x-�n��s�����v�ս[�L��U�m�1�(.n7U�D��n*o�'�.��f|wj-�r���mu��!��@U�}�|��?Fn��j!ޝ�\�Ǯ�:�d�Q�O��'�R�Y5�0uaQq`n̂ى�Vu,�G��a.[�Y�^��k�Ԝ�j�T��W�:`%����8��[	���s�h������,=e��m����;��GYUPτ��hV������
?A��˴�?�s����%�_z�qE=�T�y#�xM�rt��z��9�Nh��#Dzk�H�F�g��/�S�%�5��i��֨O�֘�HX�x��{i�e./'��.��?bN�QB/���4ȓ3��;*f�L<����~��ߜ[�.�٨U�iy��ʞ��jt*4�׶��)��ˌ�N+�g����W�H�27ӫM���l�`-�]�+���az�]�+��MQ���Z�ޗω���nLNq� ���� �H�5���pT3�'�;��p��b�B�?�\t
 ֡�C�P1MM���qx�Z��-��P�.��Bebd,.3���rq�N�ɧ�����ͦ���O�Ł�Lc��|}���fE��9q��CO[�^��㻔�N3��s9���o����	v	��W�ůd�ԙ��x��?~�q���$���}�i���w�ߚ��k�kyJ�Cσ�{�+?x%�P����=l�F�=J�˖8^F�C�aX}��I&����Y�������SS=?�H�;�:�]�Bh0K���
!e���R'o�>֦��z��+�a+�mJϕ�̯dNȾ1�ca��q�������7	{��Sy!ހ;RXjq5�����|?��eOZp��)��W��ڬp��+2�)A��V���u�q���YR�퀂��G�:^��U�Ss!1_W���:��F�sqM�k�G	Kn~c�AE����b�~������!��X�����*u������
�8L6�H�I����-L����1����y����m�짒&v���Ns��䊟���b�S�M9�ڻ$x/:���ód�0@�w�p���v� 
��ߕ�PEHo���_l�� �!��(I��X��h�{��ˍr�{�d���Ȟ����CW��=:Zo1eb�+~Ͻ(�'�������<�����ⵊiB�c�����R!��!L�.*~�*�;B� X��y��{�͛�J�ٯ��Y�j �^ɲ�q���翉�����}a�<��ɀ�v�
A?�7Ӡ[�Y�2�]���^M���V��2�s��K$2	��_��K�A��_��7P��t��+���,�[�bC��O>3 �M���R���C�'�ў�ۦj��'���%_ʃ��\Z���=$�拕��������� 7���6y�|�QJ�����V��%�-�@�!��Vh�� O7}T��'�?]
��d7��{��FS8�|��^2�bcLL�"HL��w	 ��w�|`Tv	���ܰ��Ɇp�\C3�#8��-XQ��SOE��͒�R��^2�T]+��`��%���8T�,A Wo�Q�wj"�����4CU��Ȉ�
�b� �Io)� ^_s�ٮ�M%a3�@/v�D��zY����3n/����`g�=��R�x(�b͵������*��.慇קc����?֕���Aڎn���|�T�ii���J��>�tL���Y!��"e �<[�WW�K@��s]a��G��/02���3{X�@+M���kѥ���j�wx��)(6=���Üע�\�������W��LQ|'Qj���`��җl�V�@E�2��sh�͉�n���%�u�pY��7O6��W��G�	Q/zϜ�:��~��/a��[��L�9�jc�(@Q������6].h�c̢�p��;�1����LI�d6�4���N~�tʀ��Pr�m�n8���T�c��ߧ9b��*w"���VbZn���͂��j8O�qβ����ПZ.
�A�>��1�"��1@��P����>���aq�uK�P�m��jX�V�X{N��u��-w���±E�<�a��O�uC3q?�ߤ7��Dj��E�Y`��v �Y�'�n�ɧ	.�^%h f�����@��Z����iځ�h�%lDy(����/G����/�{,cmpC�(h.&�]�˺�����x®�/'"�F���e��P�&d������t_�&Ӷ��@nNg��v�CH��)�I��Z�z������+�S�Ь�0�!��V�ܐ?�� �ZF�(J��D_"m6�G�n)%������ l.�b��� !�^�59���`ܾ��Jf�ݮx'E0�U}6��n,^��ﾕ:C" �U-�P�Ԏ2fz3)��� p���n�:�������/���C���9�9�������{�E&�N ����.&�� ����Uo�e}2c�v� ���[l�]�0�)=J�I�^���$�ß�C�6Ş�
��d9�u
��9�͉�����L~�e�E]�u�����&�1�\e�G:V����Q���2�L1��r=��V����p��>��{�C��Q?��a�M��X*����{B/�bkKx�
wtEm�~�?����k6f�~�l����'E"m6�.��;��ִ�	�D��!�<=d4�Q���Mn�\	s�y]�}��>lz����3 ����n�Q��js��	�	O4�	�|��~�A��.T�k�nh1��~9gea�Q��O0�y������ʼMY2U<���(�_�n#ɤϗ+��b���v�����|�9��3:�-^d;Uu����`D��(;�{�������EK��U�TY6������vXv�!� �������f�3&�w���H����m�3鑕9�7�0q<�{����K��8�?vӵ��T�QU1[`�e�|��{����6�/����	��S�!�T������i�:�mn�Ƅ%EG\"��0�N+MNs	���aBU[w�@��bZV<n&�/g��R&��Q�"�G�]�ggo�v;%`�_���Q�\�d�&�ľ��X"��� ��oˋ�V�����j�)��ɾ�Z��߽�&�{P�����X�"�3B,	�v7�_HU����b_�jd��N��3�SװP݈���P��e���-L�?���+�ZR6����X]���K;Ƥ^&3��i�*[�ŸtȾ��O�*/2� C�K?�>�RzŻÙ>F���iB"nɕ�`v�Q�-�����G�zD���/u���iؑVV lZ���?xx����`;=���h�	�U&�1&��z�g�r���zó���/fY���3*;P�5��=b1�w�j/3�yn�����5�21/h���'$m
��9�v8��C��E?i 	�Z�ҳ��M�'��AP^(����yY���� >
'L��<><�
�z>:r7s%x\�����]�v�C���{kj��/��0��!��u!Q�r�J0��+�GA_C\���5�-�7��.��\��R��>���J���h-�b�^^R����i���3'��L��pZ���5N��+#|6*�C�fDᚼ�'��,$�z�<&���V�i�����, �޼!�Qk�}G��yN6�d������$�WD�v>���!������z��q���x��:5v\R"O!�qpj\of��L�IT������B1�Ēi}��Ʒ�_��S>K�uv7(,��0z��D0�a&��E#�l�uJF�9�bh �5���	0��QW�����; �*#y�ЀP���r�Ar۷+�G��YN�N�n�Q�����
p��X�����|i��2���i$�����Q� g�D�*C�&��h�}M�K��l��W!�̖��L����Sçw��R6\��8s�6��uZ�CF((�9�g	�>�����}�I���n��E��&�}�U!S��n׾�����v\���Q����������Y���;���CGȔ���|�<�n��'$6@ޓh2��r/^5͇�)6"�y�t�zS����A�� )2��شa�O��r����~v�&l���Qb��K�g�����l� ����X$	��Xpus��Ic��՞Cr�Ł��L�xˁ���c(Lɐ'���L��C��E��H1VZ�<�����T�.ъ %&���Pej[L�iI?\�B)ȇ�"r��<5�˃s�!�+�9h� ���4��z}@�c��.ܜ-ԳǘlI��b!��'Z������9���ck'�:�V2d#Ai�sϡ��@�[��m��@����lu������n'ء���晀�na�����^��X�=�ѭ8j�h:T��,���U���H�S�a��^@	�sPl%/8°�揯�G����j�8����F�Q��77F�,��Q����[�U�;�{��<�4���l>�ryw)���Y4?��=ժN2W����	��4��}n����ׅ�ji�+��=N�P����,gz�Pi��fw�T�X����C"�E����n/�4.�įfE��xc���O亞�=�fП����p��~���*��`d2��m���
o�-�a�ĆJ�	�`�I�QK@�P٨�x���[+��^�D-S�R�]N�%1�&<|#�R� �0��і�hc�D��5��_Cz�M9�V���������h��Qp��\��(gAb���!���9�l�̧�^lR���<2.�t��Z=	�~�Oh�p̉r"�5�ys�OK:��3��z1ʏ�꼥ʮ��,�B$
^l��B+/�Y`F��ws�J��޴-����1�	���S·�~ I���^<d9���j���`V!���t���5�Tj�>U(�U"�1��:�);�E�3l��D{t�}��Ɩ�V��BQɾ��������3�aV5'$�m���|/i��t�ɛt�ɵ�����t@6��4�g;W��k�t�I��/������E.�v���h^�L?�,�!3��'�����#]B|�rbo"�z�B�]��n�Ӑ�7�[R�8�;�[�۹=u��T��ZiG:醧3R�(�L$a��H&�����B����y��@�VEc��&[���>�����=JB0�7t��&���9I���*��vQ�8��9��5��30N��%�2��(��	��]�q>jt�M�
���� ��'��dW&A�wE7�ܨ�{���É�Jί� =�*>e}P�o�t2�_>ռ]���︂�6h�H�z�'!�O`��;�F5�E��H��5}tK��*�!��(��F/N�J��r�p%����y����%l�ӊ��RUI�񾩓� Ic?I����!�!�	V!�U����i�0�%2��i4�����)�K�����$>�w�WQ���Re1���>�r�󐰅��,
N�9�DE܂	�>�󷾍=�r��L�x�u+r�3��8�`�*���qقuS�T\v��R₊�E�K��5ҔL�mlVhj	pa/��g���}��V#��`r�Z����ZA�r��+(\�(l��]�S^�i��	�(\�'	ʇI;��]��E]4k�_nƫ$�'�9��)w4�׎wBC����t��b�ZN���=j#M`=��Tvg�B�2?=�ã�'�b���n�[�e��l6C��T�J,82tW3����)�f����B(g��L/{�݌⤡��.G`��MT�nM拜�W:�� ���.>T]�����[أ��NP*&f5_U�=j s ��GM���"�J��.���}m"@��1�Z��
l�n�d�F�Z6{��*�����(6�kI�Eύ7Hd�]�\j��m�YD�1�6��-��I����Dm���ߢ<�nH𶄘F˦h��r`�bo1ӕ�P�PEļZ��+����0,���`H�rH�� Ϭ�r �}$�	v�f�'+ھ�[А������ �h�Q�:��v��۹��R�y:�B�٭g�U�`Z��A�:<�2�L�3[$�L'�9.���������)� �;����l��y6i&��A
R;��:��� ������=h)I��K�3\�Bk�i~��R�%�><ɝ�i�"l������]��
j��r��96r<ig�%����?9����W�D��z��p|�y�F�'�M�^,��I3�.�+�0�d�݉�⸖Y����uV���Pn�R~���fyKOd���ӻ3���b��������a�H_��v��BА��R�k�أԥrL%�Z[���T�� �V�D��2b�|�t��3��~�<Z������>��ڹ���y��k�a�����M�WߏS��.WȺ4�Wp�����G݊R�2Q�TT�w)#D�hk��vG"
N[&�ژ�����c���6�:+R��ՙ4( ^4�Mm2ٖ�|�P;�M�Ib��8�l�_�t��qVm�UgK��$9������iቂ���VwM倖T�.���Xٍ�a��ǭ�T��'̑����7u?�0�b"�k�T���M��d��|)o&mˤw�n �l3b����ݧ�ƕ�OM*��AF��
���������F(�����.[#/�(ǩ�q���0�)BMv��zֶ���"���e<�@~��%1o� ����*���g��F�;>\=aK���FA�R`�$~H����OI�=EwQ��p��5�=��B��cp�Tl��<,�%�SA����c��E� GmU<�"l<�� e���d�ع���o��sv�<�����(ZWk�)�I���旪�	�s�
�m����y^C�	j�B��S�����CJe��{�0&7��BWs����<.�М�Qj����jؿ翰6r�Q�6v�|Q�`���E�U�k�N�~)� Rvu����kсD��k|���
��A��T�J��
��ER�ѣ�>�7��(�R�~��0G68BpY;�%Vg�b�T��Vљ����
uN���7�+a��t|�g'��Ѱ)��N��/=�~��< 5�7-�5��ƥ�;�d���H�i}�i����@�^܉��u��� I������m,�4kv \�ظ�Zo�i��7��!���}t�I�@5*f�t�8��wZ� EM���P�[@���>F,���~�3��vK��6O��IkSv���j��z�J&�z��'e���0�+��1V���Z�}jR�kG_� �(j;3m��+�k�ڝ��O� �.s��`�9H�Q 5��U.9b��UA{�<��o�?"��FhYc��=�nL�Ҥ�s�{�Δ
x1~q9B�ڝ�'���bO�O�;^U�j�u` ���/o|����-���*�?���v�����t)���wpj�	��A�F��K�ī ��f �6>tNY]A^a��Y����q���1~�3�G�mi�P2�W�7����OeW�w��-���U�x�3BA�38�hػ6Cs0�f'�u�G)��k�F�Gʥ�:+�ي8��8�D�����tĶ�'Y�������0+/-KɁ)
?7�HgW!��8d�a�j�M׽)�'@"�7�\��o!D1�h`����h���-3�A�̈QD�/�z1����n�D"�b4���3�s�j]���c�u/�hoҜw�ͣ�0�*/���9�i��k+��Ewɘ�˞
��*eM�5��ek]�.���{(#hY\�a{W�n��݃]�^P(�)�/;�?d��R@6*�
WVE'�6Q��SD\����W|�h4�0��~���X�(���q��41�GV>��Z�xd���>B�`KI3n./�
d�H	�8)ld��o����>(Q�bz�-ؼ�D1�		���ZqD�N�r�m�ٞ�#�Q	�Ӱ	��� ���os%���l�uF�6�oϲƠ��12���d�yR-%�L��򩮑�t-�����ͶV�#�)�G�m��Df���ieQVji��@����9�!:Y#!�0R�<6��<7����Zg~�,�,1t��I�܎]৮Р�|���*Py��y��|��^�.���̦Yoy�q��D��x>�D�����W��:�!������lػ�h��!p,J�m�>�EfC ��]�2@��'6hw�=P[�4�w�c��yx���4OU��:j��g �I�>�G�OT�b�H�D)�ӂ�:X���հi<c՚]m_��q���Xk��`�<�\�:�K�+�U;�<��_��x0�+1����j�ܮ�o���v��������?
�'Do���#�UA��%������'檰�\��&K�'.uL��gV�=��T�����
�������E_'tS����&�A�9UcջF����nw;�)����UDC�RRY��i�Ր���a�����*YsE"�f�R�cez8�㺘�!��˺��O����e���@�ȋY�Ԡ����:�i��X.�z�I�����66/��,��/yVa2>���[)Gb���ޏ����n�������[�6�S� �~�lb���oa�(ē��o�,`�s��e����M��ɕ,�Q	�#�<[����W�hmNk�^Nǩ@��j@��++���{��Su_�;A Z�?�L�v
	!��+]N1�L�]�-ge!ռ���x 5A�������0�!Z2s�f͡��d=FnjN��@sv��3}a�rD=�����vwn�>�SE�Cy��?+�2Bx��Zn�����d�V| �4�|�SV�jt���?S� �/C����T�U�I�pê���Ϯt@��)QH�wڑ0���
�S�oSd��eDw��[���b�.�ٴ�Г?�Y�c�����Γ���h��z �kj��55'VE�^R�0����� 'L�-
���{���a��	�$PC�T��G�������X�n+,HQ�$L�^(�����������rmb�k�����g���o�%BCT��D����+d�d�_��%���s����(�[���;��A�Q�j�A Fe��� `�	����(��=�O����!��U5+��T�݀j��B���aP���#�<��^}D}���~�k��}����d�.�c�-tn������dHu�B�Z�!qv�9JͰ<��H~Uaw��rS��;�m(�f�5.���o�6��ɝ�C7��Ӯ�6f���0YS���~/�>iA�]��́`|̞�TPx@�����2f���'�bw���!��]=�.���k[��P9�Z׋+� �A.�됑\��q�i>yW��j�����ŕ8(���Z���ӣ_��CA<�#\��i�B^��SMs�8�/��M4�m���K���t,T��c�}�"Ӌ��-,�9��iYN���z�%��p���o��B��C9:��@⑋/P�kޛ�n���.W���nO��ǊC�M[Ӆ�#��3�2��޳MZ����m�$v-j!�E�flP#k�K��}q:G��K��%*�.	�ύX�����/���$�}̄����Xҫ�6��3�n�[���L:��"���]��\�7/Ճ<Ʈ�����YUa�;������J+�����G.�/�o�*��� �����S� r!�H�ut�=h��0�1��R�͑$N��c�
���Q���Q51e�>�a�=Q!&z���\)�T:=W}���O�+���`������!��D���>��u� A� ���"ny4.�
f{�z����4�����ٳ��Y���ƝE�J�b��v���Z�?�c�n��,��?RIyV�f�BȦ8��ʇ ɂ<�P��Mp�b;��;כp�P�ޛU����I�9����Ku	5�C�zT w��j�?�u��:W��3c������$G����ɤ��N֒�e*�c��@l���Q�e��cvԂWO��<�:�7U^��Ě��]�����o�Z�h� �;w�b�O�\-��x\^�\EJ���?h��H�����L~���POì$Y����g���C�oGf1 D�hLa>P����K����\��5@���DQ �~�\v�j.D��.�"�@�9��[k��?-{������'�*�k�����Cg\��Ut��S�0�+:'�u'��n�jh��)����X��ڳ:�ah�vm��	]:�B�P�.��e2��y�A��
G�+9`C_��_�����s����Ӎ/��F��#!ãݢw��!j��׹{�!��+��|�eն�P�VRc�����8�}�A����O&��b�s?j�ɫq��Y���!����f!ٵ9��,����R��M�`�/uѹ�y#V�ϛ�P����0��ɮP�R�	J�0\�/�~�2)�	��YE �<��&�
Z�6�=�3]�����G$7�9�����,-2�bQ�����9��K�s��� A�L4<N��>>3J�#3�W�$S]�E�������II�����Н.��@X0K:��.2+J�蔒H%� ���= ��3̣�t�8<_L%	��u�fᢴ���$-<N	ɬ�
� �-�؁�;V�#��#@>�_Ǌ��4j����X�l�:�g5�Ԁ�t��Nh�<wnv�U*_�+f��\���}f��?6j��3���	*��*w��ڐ�v��"(��������3�m|SoǋSI{�p|���,@�|2�-���w&mǩ& ~0�
\�����4�_��L2\��ϔ�Q�q�(��
\��{e�PU>"��UgL����˄A�9z�,�M�8��y���Q��6�����Mz��=��z+s?@n	�/c��t���A���6$�dt�	�	bz�w�@.�Ap��"��<"���^���S�#V4��>��|�:z������p�&��`�Mm��&|߉|>�����o{��y����*�H�K���|AD���1��Wn�i.\<|^�������/���;��7é�r�͵��}��n�+B`���0�M5 �t^�qQ��w�P0�7'���y����Vp�Ӣ~��-�k:Q���m�p��J�"�ڔ�ע�/!��;^ȍ׆�Dg_K5\v�	w��"c\v x�&@�)R.�[�v���IF(�*aj��(�G &�;3ܟؕ���x�"��ڍ0�v��R�
V	�0���q�:�0��R�!�Dx	F��:J7������ߞ����!2�&,��3(��(#����=C�B���P�J�B����oh��чy���uj(�����*B�k��`_�����h��7ѻP�;=��.,ܤ,���c��_>�&�;.���w���RQ��F}��٘L���aPY�+�!�$Q��U|;�f{l�����
�7\��0�@ߴsՂ\��-Ml�45���_��];I|���h�!���@����vې��q�I�:�xQ���]ѐ�Q�؂9�0��0�)b/���Zt���k!�{���0�a����$�����?D�OgsT7���ma 6�ՀWT%�]s�yf�]p}�j��L��dx��^���B�З(���:r��>,@-Y�r-9�A��:z��~/OKS{u0��1���Х�C���ɾ �lh�ag��R��V	� �c;�r�$�0I����F��v�>��1�`��bH>lsk�����B�L`%�R)i�]���Fc2��k��ߢ�$&��u%Ql~$�s#*��!���,��E�E�Sw��sȁ$H�t)҄�ف{B�Tl��.A���u��*��!>�;AUۨ��xEkT؂�Z]ԭ�2�kS�̐XH�lY0'�V�D�o��7	1����
����@���\���`�VR�� ��:r���q�1�`N�ˇ{�QY껉h�`3�t̓G*;�xJ��Z��ʲ�v�������;��7��.I��U�A�W���t�3A�����Ъ����-5Ł�tQ@����Xd��ҤB��Ǚ/���ղ9�r^~���R���n�F��5Px�[\S��o��˵U��S0���y?[���S~t�d�HV2��%`���|�D7�\�ȄfW���$+/E=ۗ��~�
�^�9
�K���}P�T?z��|�#9��1.�ı�5{�U?����t^X�{�L3�V���)]r���tY�ƠxL������Mr%Լ��(5�>����~}���揵���vL�9���H�w5�Wn.
���T՚��$��ۄA�2�1���W.�x���b@Gr*׃�M=E��C�{E��������5[+���/�}�RA�6��6�4���Z�}=2�wԽ������APħ�'���)��~��k:6Ic+����n��OE>�4S�j	zÂyZI�ŘsMǢܒ��d��G�jF_����P�'l<��&��y�"�r�����R�Q5�*�uD�tL��ѿf�OӾ���OFd�\��9x��|�����p��y����Sr�3��=�S��v�V2-��],�'0�ۇ�r��[JO	Ш��I�o����;نŃ��4iK�|�;("��\J��~^ �����3��ź���K�*?!v�m~����kW���zԯs��js��3h�'�WΎ��]h�F�.o��<u��չA�Mޗz�R ���i�f�)s�?��9"��� *�u�"������Z�$����Q:�ܲ?-U����	�L�����&mq:|r���褓�M��{;��(z�֌��b#l�ZK�+(�����c]�	!���8H�u�CEݙ���Q����ҟy��/�7m�ip��ʥ��u/�C���Y�M@{_7�9w�f��UEħ�ʱm%A tZ�Vwׇ����t,𠰍|Ģ��g��Ƨ�rF��͚VhR�(�jc��p�(c�Q�BL�Sm !O_�ձ�������'�����Wƨ��xX����,�?Ey���GD!���/��EU�R�v� ��G1o�1�����]�j�(�؜�^��N������X��z�����'��ъL�R�Ҷ����z� �;�vBwkȘ\��;1�����_�Nk�VY(H7M�r@��c�)suz�_��y0�Z	��8�lG����m�4�xQ?ߗa�_=�KE�Vr��Nt���O ~�m��+�J.8
[&"p�{����_4%o
fCf�W�S�	��0�ꦢ���~�÷?�Eݐ'�̋��9=�pV��<��2�4���>y-#kһ'�����-��L�6d�Q,�eb���N���j����K����a���>;�+ �`ĖrZ��{��\�aj�4�=Zq�z�TQ�R��_�ӂ��YHE*�pl۵�a����vI�Cq���Z���¢�"y�
W���Z�]�@;��pؑf3�\]5M�5��R�#T��D�� `���b
U��a���(K�;hA�f�w��%�P�q�P�z����恚nm�4��g��M�a��Nc�g+g���"���>gO�é�X(���A̩ˋء����Hk��I�P���u�@�h��u�ˀL��u��m�ۢ�hv��=iA�J�����g�N#Z@CB�P|k�x�%ď�L0��V��&ۜ�!��هO��xH��g�"�~ˉӤk]�$s��*2�c��PWb��'��;����Ku��.�����B�h�:�kR����h���9}��	�u�T��S�r0�ջ�ҢF�}��&r�f���~Tor�{]	� .R��M+K���DE
�!�Xn�y�T5��X��G��D��WE�~6�R�'���-Al>J�!L��ρ������� �е̱t���n�Yd������p�F��cjsp\0����*��|(�ǹbJ%ӗ��r�&���Ӫ�b`���2hdCw�"�E#�@�D#)�N���e�)o�X�3Q{|L����P��\��iU�֚�I�eo�pP�7�� T�9�s/���������%#�"��ل$�V[<;np��#�z�+�v�UR�j�(̀��d�4��O%>ueG*�C��޻{��-*�p��'��������5����n�]T�y��߇��{YI-^���S�އ��e8
�j0��]��<�� K�T�7�����8�t#\�Y�Z�	^�pgs�u
�q�8N?�4d����d���W�Be�������y�h�2�KXa߰�j-l��P����1���z�7o?7_Ld:䩸Y�d!��<�I!^�W����5d�m�!��%jA*��HU��'��r�1�υ&�@J��J��A���Ч� ��!���+[܀CL�����c��u�HOB�a��k`t$lj~���(K1�螇 N!������_3��J�&7�Л����7<����U7S�<D<���;m��Ӈ ���7��j$� "M~%1�gj��ϒ�V>a��4AZ��3��U���Un�]�F ��������6���9��w���/�o����<���͉!{E%�y�_��J�V��Β�I6��eN��;�����yG(���Y/ä+�sX4�'P��jHuK�#>&�H)Z�:\�E����(H�M`_���:�NE1]�����WM���f:�]�Ҵz���-s��mHQ��,4���H�u���;����^�Ts�qD�o����P��V����K[wZ��GL�B����1n�7f��?�'� W�J��V���z@���[�xT6^��Ҩ����U�R%|�X��
"����0)�v"��*I�=�ںhWU�H�g�����F?qKr#�?�����Q�J���9M9�yN..S>�`'�@5�j�a�����٢�!5�u�e����QI~�U(8T�4��V֢�2ziUJP?@v�SV��k{�a�.�w~�U�3 [/���a��1-4������h~����IǗ�p��a�т[��P��1�����_Z�U�
�+�p�f�d�,�h y�s��q�������q|Lk�:�q����)�?w���//�}���"�
��`:�mR�!���C��7��e�����ա�%a�'q�:����� ��.�C��	(lv<0P�����$�+���2����yasYa�բjIꑠWx~)��P�<%2FM&ɖ��{�@(�>��N#�9�i��&C�
W=�N%�D~ƶ�@��2R9{2B�gAsKO�����\J`@l��D���;�@Y��ɧ_9�Df��54��H[�0S�lj�m������k�8�m����J-gz�<T~X��(�)�`~���4f��Zm�?�����H�� w�R��=�gd�UjP	L��';�Hkf�kR��A�~�*�Wk�g����e(s��!5�߾A�� II�cྈyOI\w��8��,���sD?������r���)�@��;���71�c|���ZwGH���Mki�A��M�Fg�9����R�b@S��_�@隳��@�J�0��+騼k��5i�/�&�Q�(�xq���
��X��f����2���:�Ǚ��;�c%���e�ۻ�ܠ����<9}��g��3f�nAv�_;�R.,,�&��O���:�7��Ma'�Q�rb�j+v$�x��u�q;C��rw=��:��+�|Uv����$<@���! ���TT�T
i��>K^|C�2��,>���	�R��L��`�块�X��V�lo-����l�Q5oZ�}�n�H>ժj�������>���%�@�)~W�ڹ���eSꖤ��n �e���[4]�D�
�}#�4n:3�'��j�M�����Wl�F�8cf���g�('�C���H��������J^�U�X��p��V���F��l������(�j�I\��HP
��
*~^���Qіh�ߨ���\�w�Jx�p9�!M{âJC�;L:�Y�:���[�DD��(�˪C�}u��s���,�xIݓ��b�żUԼ����Ke��8�t/�5�� �Q �/�߉E�}���j,%11���3�;��ǖ�Uq`��_��q��Ў�}[3���=�10��m6��}k��S� $��z��I���k|�}���u�yߨ�	9�2㽼v�<|S�s�U�'X���?�U�K�|o�A: ::ކWm'���;�+z%g���&��G�fo�1���D�$�*ZCG"��s�7�Y�c\`���v@-T��`����բ����I�n��+4�@�Y��@6\9'7h�����O���N�;�@U=nd���;�S�?l4};��z^�|F�Y��qwt�,��ϵi�	�/��.�b,�|nV�"�y�����{� �C��Um�gt?��^��Ļ{����b�����ؤ{IO���w�ܹp��x�B@\-�K#�/O/���|"����g�G�Yi�`���\�6�R&)r�-ɞ���q�6���W����A�*�����H ��Egri?     vlέ%b� ���������g�    YZ