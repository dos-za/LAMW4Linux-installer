#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="991668972"
MD5="c299835a038ced4f275330aff15c4fcd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26628"
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
	echo Date of packaging: Fri Feb 18 19:48:52 -03 2022
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D���0��X�?�\їj�6 �N���]�&կ�Y���u��?��CzFJ#6��y�+ U6-���͎�g/�̲M�7@��]a[�<?���r������t��9����C+#�#2I��S��>s���ӻ$!�MX��4�5Ҙ��!V�fC�����NL	�׫|����n�ia:��튲�n>�Tt/�*!�{&��,cP�Y�y���2�b�'ok|9~X���jQ���ii�$>�5V�De���Ի�fA|h~�K;1���]"�f����G�b��zǹo��"���\��Z|G��pи�xF̍�Kf=���mO%?����b�$k���3�p�مu��|כ�����nq�YUNtFr�f�$���[X�S`0�6����N1��3.��f�Pb�:����Wt�^RY���P4�Ӂ�����J~ud�������;��[;�����i%�ҋv��`ن��|�9j�F���kwl��I H��
FH~�J���۹�
f�d��|;$����[��JJ�,�l��Q�>]q�<��p,��DA4�t����m�g��e�w��r���(e{�>���<]����~=5��bS|�˨5����>�S���>o���B?p�_F�^��%+�(%����_ox����(�Y�2�e�\�`�I����O�=���\MƠ�� E[���{?�/�V)�/h5���<n�.�l�ͩ�ӈ�	��e�;���0��ߒ_W�QM�I��v4�M�t��K�V*��h;<e��Tg{�9<Z	2��n�1����϶:�w���z 6{>z�y�a��T�s��xb1V �F����RV�Ȅ��ڭvI�Zkt>[�y��-N=2���^8.��~r�XdEpki�ώ�-Vٴ���ӡ]4� ����Z/+�j�Eg��h卑!j��"N����k�7���DÚ�j��=��3l@�~�d�Rps�¿\�U*\����.U8;�E��D����Oפ{ ƿ�v�V�s�*�0���!9��zq��ƺq/���Z�&���vNI��'�D+�A���	��< R����Ŗ��
��P�'����D��!僔+�>�ʬ�ǘ!4sr40�'h���r���{L�^�x�����	�OxhF�\��S���Q�P�nHc�eɃ�l�K�9� �Q\���'w����f�})l Vز��,q_�)��AK�ۖ2zm�+�h��֖?P�+M�B�z ���v�<�L �'^yo�N�h)t$i٬�-qO��X�� ����%Z���ϡ}��F�,� �2��5K�J�����C=2+����ې�-�z��׽�?)�zɯ��֙|>6�I+R����8�1Ο�F�����T��$��jGJlZ�7�)���F[� &`M*
(3��%E�Q����yb1$��5s�C����~m�����7�g�P�7��.%���[̹�l�P���WD��?��E�vap���F6�o��J��1�h4r��J)���B�n�tC��h��,���5=��΀����]�l�9#�,�|L?���B�����
��s�L`ƿ�5�0�`d�M��F_�6/*&q��@�Q�p�^<K>B��٬�H�[�H6=�40/�?k�>gS��>,����rsfr�lXr���J���'z,Ѹ�ul&����P)* h^���~�"���ZU�U��"�C�*�`��!v��H�1���@��c�u�x��ΰ�n
��z{�Y&ǔP��Z�k�a�%�e��M�Y���\V�[A�s��|T�rV�@@I��@�� �<���2^|~���Ӵs��x�-�'����ޥ|c�=�P��"=[�1N�J���D_���+�H�s#%�h`J6��ho��)�v��3/���Cu��7I�����%��=U�����p��5��]!�c���˖�@8� =�����6�%;����C�p���U��Ǟ��\"����;��۟
̄����^BS{��H�$#j����d�Unp�YU>h���yAW�~�6����eX��-�|X�:<#�})�?ҰS�9�w������\�H��yG�����U��yv�>��F{F�9u2[�4�A�Ϙ8�{���JE��~{9K�*�5�=&&�x��K�9܋D���;l�\��$�����[�s�ZZ�hR	�����@�(a�5�a�ݥV�A�P�b�˴�ҵm�Y�99ۀ$Ԥ�������5��)LU�,"Uui7��b�������1ǁO}-�?��.�褂�&�ဘ��o-��e�k�}h��΍B�ܟ��K�q�Ֆ4��:�����c��p�w�hx�뵧a�Y�6�	Gjr���.y��4鮈
X7�I5�Z܃����;U,�j���ѭ�qlߦy"�t%us��+��,���f���%?֓0�������=���Pj]�&(&s���يDƪ�IK���^F�Z��<8��.����	�A�l8�R�oP3ePo�h�r%��0Ы�\��NN�P�BYK��j����KN����(��jkY���"�2�V��^ր�х�?f>B���I[��<��-J�|��'����ΗBQ>pG9���,G��W�$J��D4�\HC�EV;#��)�&�Ż^�u&w���.\�Z��+;�g�f�gO����������<|xi=��FA��%���j�l��b�e�����!��,{���φ�B��޻�k��,�c����]m0�����Ta�W���o��v;�l}���0}\A���⾃ o*ZT��Ұ�Bˊ���+�z��.J	��|U�~�8�Y~B�r�3�pB��|@��(:�ʆȍ��(��O��Ն�.<����EFa��3�?	2+I���e.���5*ȗ	���x{��SD_{5�3�=� �/�Po�M��a�Nk	b�	������w�[<y�	��R~���ƶ�.�L��7�k.���Y<X���i#�n��,�{���5��V�nֈ�Er:��-�ڻ�z��=`�\�1ęa-�`1�n,_�T�,�=��	Ή�i�����3���_@����ǩ�*#�:Q)
��֘�E[� H��+����2�����Ж}�[6�(4�4ya������sԁd4�qFq�U���7q.��f�]��_77�C���f�Y���;�6���g'�[ �nԣ�C{�γ�F�t���Gem���(hqۖ�p�K�����4���D�"��S`[$��!(˰��뮥�+?*i�S�D��g ӄMÔ?�p��0k�����e#ڥ�j�_�?���N�@�� ?5c1�s�F�M>&������ X?�f)����fH�q?�^�k�	x�����dU���C�׼\��Q�p<+V�w��u'y��ᖰ;����@����W@��o��	�8M�gQ^����_)CG<my�� ���C4�|�D�o�-)3�B~�? !y�r{�J�l�R�G�9u�C<��H���ɷ�p6X]|����OKg�dhJE%�ҥYM�����/D&�}���FA�H��2��A׽;}�aZ�D8�+��
1�3v�6���d���yy3���\�����j;�(���X���ǚDې��<'U���~yc]�o�%��s�}�P.k�H��_���:si�Q�dY`�:(�s��83k��~qӏ�� p����</��%����H	��T��n��Lt �����9l�A��!�!��m&˲�;�ؿ�C	����5"�
�,��>- r�6�n|$�T{�}�������ڤ�I��|9�*�Z(MCyS�EPn�K��ͨ,��Y�fl�dyz��)Sg4�pY9���|9b/�m�p���㿎_趄�՚���C�N-`1�P�(��p��B"�e���!��4�����C�B�j���yf�<o_��g����_?1D���}0�-E�O���(�р(�� i2�6�m��X�p\�}�*Y����4�K������3?p7d����D�ѮI0p��#-|��D� /�HgIQU�<��й�S��I�j�-���vic8�+��k(}gE�c�"9#�F����6(���ka��ɻ�(�k�R�L$��FWɇ����B-�T�Z�k�W�e	�K��VT�k��1��:"Y��&�"���;���"��������y��+�bƖq�Q�_	�����# ����k����qP*�[�����7����ͦS�b��r��tp��'o��վk�a-����D�N1�"L�:�˭\�
Dú�>c�	ʩɯ��q~����O] �`r��UݢBÕ��==?J&���9��@6�C�F$��5RѪ�6���a1.�<���HN���J�:M&�mP�I��w�=5Н)pej7x6B	t�g�u��a�"Ҙ�S�^��Q8��u�9<hYH�,�K�w����Cp��bS[(�O:�<A��UM����@H6��y�ׅ����S�V�KRY3� �G�뀾^ZAe_��KY0>����;��n��;ؐw��'���g����	���v�Ny��C
��%7s�olBMə�߮h�r�[�8�dj��r��}�$�a#բ��9H�A�&�j�����̞�r�4�Uvl�g�t���Y��3��ס=��\�flEv6=Z�A%G�N��@q�'������=�뎍i��g�t����Ǒ�ȝ,����W��1�g������H+�[(�p��&��$�HPkOK�Sw���Y��E+9�l{��t@�c[^�<�DNp5p�O�m��Ū��}e�2v�X�p3��L��*�����iA�NI-�'3�;��xNml�s��%������ob��?���3�a���Q��73�_KI:� O�m2i����V26��Dg\u6vPq$�7RGL�~���53�?���a������"ޘeX}HВ�@��r[��K�C�3J���đ����8]���V��͑�fƕL^TdX/v*�wl���P�$����`&��U5�D� 
E�'o���7N��G9ʁ�Jr|�W�$�h�X�K���+����_VH�������Y&���{��M�6�(��PF*��ө	�"�@YĆ@5���^lv �"�P;������u��|�Di�)��v))P_�e��3!ѳ�Ø]��;�F_9X����%#��z??�
z�NUOH��D��� ��
Z�A���!�Fx4/�|���f��ߠAx(���V�N۲S4Wj%}l%#Q����D���kʭ��+�t�~}faj��:������?���Фqt~G
��s�#��
�=�;g���C����h��g�-��G��L���X�K����-p��~�%�;�Tc���I��3� v����M}��]|�ٞ�;\E�@�;N ��o�Q��k��`޺("�Q��C���H`�ip�g��B��$!��<���orY˳�����,�c�L�B�4�5d��s�3�ec�+�G#�������@`%˂VO���N�G�dl��v���a���I�5��9뱆��\�L�M�I���RR1A�T5���>Fv估�2]@Q3�!+�'C�
A����s��6Q��]��\k�O~�ٝ�Or�����)'��|�}�k����)ʭK���_j- m[b��zĈ�O6�WU�E|�F|q���*�^�a�":=�{x�U���D�2yS)�	ֲ�XT-|.Sw�]�h�o�Z��.� 7�˨�8�Y����1q5�n�oi�'`�
q�~�����`��ޮ��m5l����x|dv9쟻w{]��WyJ���.��|1��=�k��$�Z�^�[=���� �5����rFqW���k���Ӧ�__���񍠸*�kϫ_2t����,1��@��~Q��|�QfĽ��@5�Mii�\2"5]�1���9[,!�k}�(Z̒g����?$;��j��x0#��S�S0�Q[�1�vHw���T�4�D��xvƥ�5Y��'җ�q���=��Ƒ�����j�{�e���b�CJNђ�i��D���dv�x��޿�-_LE�y�0<yi�<[W&�%?����E���+���&Vy��x G��'��>�O����_�!w�T?3�`@c�|�LI�I��No��^�7��-?��+�n3a����3�8�,��].U<BK�663���1X�¥ĺQG�s����;�M�,�2���s�Fb�T������
	ߥu^��(����E)�2�Y�=����\�FL@�	{:�1��N�0���7G�R^��p����E��:����C�U*|P<�ծx��X��T��6-a�O����3�f��}�
U�F,{���B����מꗤ�.���1���f��8��T�C/�-�*���sL�>��1��z�-��2����XǕ���F͸��z��e�u�I�����/g��{�E9`�
�-�z�G_==�G��ZWc]9T9cK����y�������ȍVõ廴�M�??��@H�_o�	�`î��"[ \���[m��1��ș�U2d�ԡl����݆$��Q�^i����;��2�/@�w���E.q��!A[�1my]w0,�$�Wv4�Rg�Ԏ|����ƕ�"�I�ek$���|����G�S.�{�����[�h��*
�A~�Q����-���t���=t^	��,��~O$a7�gkE� ʼ���B���?fS�g���ޜ-BR�(/�U�D\�T[]�2�xF��W�Ǘ��<�ݿR�Ζ��z��;g~�Ǻ�UK˛[��Ԉ���eYE�HְS�Q%o��Sæ�����,�y�i�S�l���	��4���T[4h^�G�.u�^RU��P�Z*"3/{�'@�
2��)GΙ]�UQ����k��b7dv�8v������!=8���"[=6�7����5���Ʈli�a�P aq"�|#SSݙ��V}�E����I�P���L����� ��{��_4G��>��s��"�WO���O��#����/�l8��u�Ba���"�W��Q��ټ���B˝jB�T4���w�S�WU��R�+�m2�Z^����~=����s���S���\W�Ɠq}�V�5j�8���'m����'�<(_r�+��E�LXSR�r�;7���m?�͹d��Ft�|�8w��b�Fk��ʶQ��5oF44�7�|U���i����܂�N ��ӍàZ���C������Jm�cE�Hq k���J[KC*�z�D���7�e�!wPE-d���)\���`��Ƴ"�6?&C֠7�W�|�4��X�AxXW��Rݣ�(+��2�l ����	����I��6�S�Q�<�?s�� ^�v��+] .V`�(�1�)D�%2j���c
����F�M,,F'3"�i@�ص�A��d���M0۩�r��פֿ���&:��Lu�t}+�����V���{�~xP`�|���}*k�s[�2*�[V���[Yk��7�eF���
��Bnt��,s�d�A�4z;<1�*ۭ9]Sv�jHFb`���u?ߊ���|X��^S�l�~l�߽x4�L!W*�>)X�cܲ�릿���9�Q�ȶ%QD���,�z�1�g����rt��d��Z+�K=�P��K��)?�P�%XO�x�-2In[����=AX^�u��4���*��S:��+�b��������}���y6�ë��:�}
�����c�VT���]b"wz�յ���SwG���_�K^�j�r�e]�4�}���W��@���K-pKe��C��J���m����L��6�'�"�X�S�o4��h�#y���Ai��rq��|6�����c��~��8t�J�N��7I�=�FJ��&.��#D6��S�_Xq�1�·��;���
T<�����O[I�Y���^̆�Nrh�g�|E���8��$��LQ���s��R3�r�0��]t��:���z�ͳV����Ղ\�X/6�;�Lޕ!�o����?"��`��O����{[�f�K�z�ۅ���;#�B(��c��}�S�5�X��L=�Td]*�2MG��� !�6�,��Zq>����u��^�����'T��J�A����j�=0��\^����lRfS�;K�a\�֛[�R�`���e�P�ϰ�%r����j;�s�@q���g�Mi�F�qu��;f�aiN?�}5�^* ���hi⤍��v����� �D`��r4��;�'vV���CY`���l�7+R>�xi�,���\W!4�H*�Nx8�O�LM�7E���Z.�a\��ס����w&����8�q1Z�w��������^'�!(Z�?깃FĴ�@wU'�>67�� u=�������\� ���2=�rE�_�&Q�(M6���� �ա˯9�r 3
L�j=ϫ���C{��A��/>�Lx͚��aQ�6�������}�1��	�{��xj~�CuuF)�V�`N��J~�ex����� P�J����A��d ��杚�WH�f'��W��z-�C��5o��c�.��ˑ����𗎿�� �Z����i\��;��`�Hk���c�%�i��w蠤6�����!I�R4�<	"�oToW<�%�K|�6��8'�B��+j ����d�T�|eI�g ���H��;ߊ���Y�.}�U�J�q�P�����KmFkd=���1S\>�cYN'��S��0e� 9���g�Sg�3M��-!jR����r����6��:^|�.*)L=��Ϻ~��C=N3Ƌ���C����0_c^�*�3-�"��(7是�d�+:��O�ų|x&�YQ���?=B2�b�{�`��=��3Q`L����	�j������Q��6x�z��� �P��ɚ��_ٔa|1>{�\��{��r�i�U�E��- �gI���|}/�,R7����.lJ�9���vxp܊N�����c��b6X�k���n�%���x$U�j�6_�;�?(^�]�~Xse{�9�۪H@�tV@�/:�e���в������\�tcj�|{���G�9�8���x�G�3��cI.reh5�̝������7�I�y�>��n�#�r�9��5e�ɓi.��\�L��C�Er�$K�31}pgK4"��ܳQ_�![a�5-�u��o(�]!�ɏ�J�o��z"����Q:̻}��	�qե����>�_m\@Y=IN��x�G��q5s�%�@�%��Uz���e���:Z�F������2We�Ub㕕��
]���ʄ���ï�N�C���S�Zr^�$"�zV)���3(��)$�%Ϫ�/+��:�0e`˪5�A�����|�� /���t�9��4[s����"$����;��r����yw)��]��zeH��(l'' V��خ��vW�~��H��$��p-y��xO"`@Z$�h"0�r����l�������f\���F]	-���5v�C����s�]��d #~�Y���D�I����o��$P�+r[�>a�
�w�M�8�|�q-6����Z��.6���Nv��yg�J�*G6|����`˗U,m<�KW;�ԫ!����Oߋ�k�B/���G����/�3�KI�~B2��O�웟-G��2E��շO�w����te��?X���[����A��k���7p�6�hpG ֎הxlm����kŲN��U�����Gz�^�D��J'�h�2�s�*鬴7װ��8z�{Ap��s���pr���N�����^��H�)����+`	~�c���Y�_�_�r�%��t(�i���i2�I�[z�Y�ͤq�@��	�z�tP8�X�#�mw��,�F�� ��<�~�@$����Xfz�T���DB�!�h�4���q� �{��Ɏ��" Ш �"�M�J��$5u_���V�b:6�_8���3Ť��i�$�>p�����k�{�&��uJ�z�� ,R�`ˍ���U�P�.����y
=c�ǠO/���) "i�yZ40x�򓄒�*1ab<����MK���j��l탁�JP��)���|�)=��:���kC'��u�s�T����Qb�x)`��3�	����G�����d ""j1�S_�C*�������vV�]2i;-KY�xm��鿎T }����`��8��\]}�'��w�+���m��VM'�:]u��������$P���ԫ������fv��05�C�y���mHr�a����ڵ$�����\c���+��Uk�W4фya�W�yW�̗ �T��Ʒ�Wjb��#�?��5�n�%�hY�n�Hae��	�1Ȅ J�!�t$ZG1~����w�&ݾiBb��ԋϻ9b!���1��邢�Jq��ݦ+e���� �&�j������݅�s�+�� @tp�+�ZnثSH��n�Mr��V	�q	��Q�V��l�m�3��+�=���"�����:T�4���af<,l"4Ab�/�mT.|Y�L��qmE���֙�Ӷܘ�	q����BXc���*�g{��}�v���ü�(�������/�4��BMr4t3Ai�Hրt�+6�uS��ȓ�������fWN�3b;�`���ݚ�x�Zw�_�����f1>:��U^�� ������m8cɼҷ
=���O�1�P���~m��u�� 곤9�H�@8��65[�	V��U�$��8ԛ��b���n8�v�}qS1�1�4*�*F����nL�ۯ��/u}T���D�l�$OuL����UZ��:����'�����/6ˉ�÷C#�_UsL�k�DT��qyu�&ѵ�oR�~��ڈu�?Oh��� ��j�q���+���D�g�Oԗ��v�d��&E��K�G8w��~���!M��W�28�ޫ?�G�t�V��~���ӵ1�x��;Y$�^��b��l��s��{����b?y���zǅS�L��]v+(v�D�KK}�kX�n6��������$F�=�:CٚL�A��k������k�rL�!^��t-ZR�1�{���(��t�WV��d���Cf=G�H�8Z�˓0k�,�|� ����w��匟�;���Æ&��7y�A
$�	�� �~�x��;>�����mOY�LDey��d�-a]A���i����S��һ��≭C���k�)����i{
�`�Ш)~���K[ˣ3z�اx�\��XQuY�r��j+��57�D=�jP&��m�����$JFj~�6t_/tIV?�ꌊ�x_U��GE�a4p�M*�O�2���;g�v�=�ĉ�3�ѣ!���,�ŭ�J^��Q�A1�5���LC@Z*q$����,C'���ô(��������@��둱d ��2	pW:��qt)�Q� x��Y�z�o%>Β�n�#�Aɾb�m'l�͵�����~�2KE,_~���%拾�PW�H�O���̗��Z�rH��8p��U�r��ݱ2x�b�	�>���|-�f�G���N�|���4&�j1aiQL�.�64�,2����U�|�c���������߭U(H����K���	�P�}��kg�H��o��r��J?I�>����"%>�p��_UoIhQJ�x�UN���N�����lkM��jo Hx�����T���&���u��"ϩK	�����0�@Uj����<���,t[�*.��[����w���vW��ҡ>$�wPqs&js����M*iS+�E�aE5�g o���O�(,�=�e0�0ʾ�Q��@X�i�4��y�h�=�s6�^��T�-?�@����S!$��.L`�3�Sp!m���j���ta�^���	6+�@&Ej��)���9h��ܝ�f�u�a�&n��Q��*C-�r(˃m�qZ�~�>��o(�<���b�|2�U�[n$�0z�m ��c�o̥LL�`{�
U������B�5~o$��h�S�mPˬ��v�b�#��4p:R�K$B4h���"V#���#.��Agd=��(�!�q�E���m�@����?~(�Q�{
=���� �4����>5]����ќ����������2˝N@A�1�C�|��ᇫ�g��NH�$���+�e�o�/qۍ�VF���ܙ�a�-�|AC��|^����#b�Ɠ�O9T1�����5�|!��T�auB��;r5��0����� 'U�F{�ՉZĻ��F��G��b�G�.1���O�����tV'��j}�?� #�E��e���<B�xs�<��P�6ة�`S6*����ߣ+��F���_��о_ǌ��L�}D�a2"���ǂ�|x)u)�����'�$��0&�_���7�3���J��rdw���6G��������*�8AEX���c����e+��d t�QI�^�x���=�{U��������rƿ��aGau��s�!���d3I�:1�tMZN�]O}0&H�mͮ0#���*o����IOԱO�pE�A�SY��Ύ���C���J?h� �0��MZ�_����u������j���#���i�chD�k�z������]����f�eA��$�>��#���x�(0�u�����$`z@��/��v���^��M/i�`�D`����J4��}�6�J�$$�1Q2@�y7rF�b�%H��� <����/��R�lr��zFTDM� ���'4 ��/���?�	b�ړ.��^l�Ӯ��./A�'�\��7 -�]�6
$
]q���%�s�T� >6�I$�.���$��|x���x+_z���t�W��h��H#�gw�l�{<0\N���W ���a�z���� �>Ql�9�.+�Jc'<Oβ�:(��2��^�1q�:��A9{��I}��6q.|�c��3P����P�sܩ�_	
�f<@F��2ړ�����$�H������1�9�b�,5�Z��_�%2���
��ApF�F�$F�ed���V�K��4�'�a9>P(ݶf�i�x�[�i;v�+�v��2�����s���,,�"Vb;�-����N�@(\R�3�C8����_���Sti%}(��۵!P��Z�1-{3b�&��~��������TY�۞�PN�&��
=�a��إu�^����v�L��Y�k�=�_�(�H��R�sQ�)f1i�\a�`~��f�|ǸB��C�&��z��] �_aq�u~�Cp�jR�yt:
'oEa���Y����?v;� <�B�-�7R����un��?P���v]+�
��N�1�(�|�?s�e��k&��{�Ro��[��UB�H�Fs�N��-Ԩ�F� ��"_[�%� S}q��W͟Y�NE�S�loP��~�g�P�렑K��@�m�@u���G��+��M����U�)^r�6`��Q/��~4'(p�%Y$����\�wf~c1,��K��r<��m�(c�)ڬ^Z`��B�^���Np����אթ�"p�n�[}�G���
��P�j�����|0���q��P�e_^����Ihj;�W�Z��Y/�ow�*����~�6�����t�8�@*�J0�|��r��@o���|�� �<-�]�����ױB���^��d,C6�'� 0x�'��	�}- �x��@�����Y��`���QI�?푔�F!��Xy���<�:fg-/�5)��v�s��|K)r ǈ�$� �d�:�2�mh皢J��B�X�©��
{Y����a<�oi�%�b1��t_��e%�+Љ�q�r1"'#���f2ʼ�B�f�i˥�l͠%٪ӫ��y�̎ODRM.�0z�p����j[�ar ����T4������
�gG��C"�⑬ɞv�w@��Zm�ɢ��TK��9�z�,8��h^�/ӕ�L�r+׎�A�+D�B�t�̡n��z13?���Q�Ď�u,&��3�|�o�=�湹i	t|ݢ�:�00ׄ��@3NS�y��>��$j�Ul�x!4_6��s׾Z��{��(@�6Y����qZ���ݽ8,��s9B9r�C$���� ��a�,C��M��n{��N�[�V�Ku��<'7�7_�>�|����r/8�k�
	�NA&V��~��?+�.+���x=?��E�{i�i�k%�8	jŪ�zX��1�Zk���C�`|���'�@�������ua3����%�p��$kl�4�׆�x��gp������/��H���d]���+���(�3�(a�7�ޗOg�x(�����챦`&�D����C�@�C�4z<� (���X�[`��J�� �4�ǖڗ������3I�]���R�d�"�\�Q��_��������x��)#r{?��ϱ���&�Z�M�v�N�x��v�w��m'�p%���j��8��%� 4��+r�'!�W�_�>j9���(C{��&�)XشjQ! @q�B�+�˲�f��V)ņ3iB����B��Ȩn�A�ԆH�<��}��X�e��#�Wo�Qv�r8!�x�˖�g$%�w{�#�[�Ȭ�TA#�I�Y���>�@8T2&UȨ
YU��� 8+���:R���RkCnJ|m�$���l��	��u�r&��5Y����C�nN�蔘U%�;=���u�y���	ei���%>�Z�o�a��wS�Z�+�u6}�@�E+S"�"��*m�_�5�6<_�bO8� K�Ѐ'�ٞ��W��<T�܂�隥��G^�`c�G";Ș��绉���Ig��Q2�� �� �k-��������V�������	¼����eg{0l�_���_���(��l����7�'j�}<�������ʪ[=pO-����L��!���kD|�b5*)gS5��$|��gBOf��o���r�hF<<;��nFKa0L(!��,҂5v�5'�Ir��*&�]��M��c%6{�����j��D$���+�J�w�0�dx���Y"ڂmT���?\��ڎ���XD�/��z�m�"�o�2���,��ARL�J��-U�����f��@?,�~���%�hE:m��P354-�T��m�ΚNU�O�q	�yv����N�#�p�g{�nC�Zk��i�r�]�α�٭�~ә��Cy��Vma��$+�ݑ�?�"��B��Z��+?G��vZә�Z�/\�wL���f��(Y~���M��Szu��C	�n�w8@��<�?oB�\��Do�	'G���$��׎?�>����ԫ<Ǟx�����M�wC�mPE����Gŧ
;��V��ԁ�ȱ�V>U}-����90f0!2��$Ķ-|ސ7h]?MVڅ<��T՘t��� ��]ʙ<$�����R�_���0@�t���ey괄�"�>5�����f>��騷�{��5
3�ci�?^2i�j���O���hضg����*�v�!�'N��4�^�|�kf������Z��d�a�{��~����[�H}�h��"�J�	�e��ੵO��A �|��~���F76r���c���-�vE��s��վ�q�Un �u�pg[�+,��/�������ւ_J���<���	����Tl���Nϝr�'k���+� 	r�' �G��B��n+P�ڴ�,K+�\_��}�!��p1}	��ML#��M�h��vp��V�6}���-�Z�~�@~<��N����4�^~$�4�X ��aΠ��U�u������cJ�9p��t&���6���2����	�ꠡ��j(�E��+�F���X��R5%�O�3Q�ί/�ED��N�;̦�
�!(]SS&S������#��ž��a��+�ګ��f���gZ���p�����`� Z�~4`��>
�ؓH�"kś�#(Ѵ<�K��*.����BR�)c��N8зYbâ2�n�)C���Q��%�8��t����F�/��z;+��4���L���Q�'?���lrWݹ��*���G=��= ��T�E�M�)�[cv�����:�?7!¿ۥ�		B״b��b���f���S��%%h�b��ⵠG�G&�:�%�%���A�,t�c��;�&��~�}i�zz�Z��(�O�g���F&}�B��N�8�!ҚF".���U���q�O��H�C@P�v�V`l9�*>":�!��D�mg�H9c$R��?q6� ���<����D���/�.;�{��i-"d{.�+)Œ�[șT2��p
T�.�EQ�PsVt�p��e��b���v:Rt>�k���Ϋ�ة�w8=o&^��j�+Gh����L����=���q�a��G�O��P(w��I�ЃNj��6s@���4a��5n�S
R�u���(}naW�*��w�����ϸ6�*pR�Lν��{@(X�v���u-��a��/����-��D�s�$:�T�1OC��r�Kg�@�HW*J��!�Ap���F��hn����F�9.�>��4�_���7�W�=7��.����׫��O�?��J���#�.<^%ʂbW��r��cz(G�]�IONq�>�ZҚ��0�R��w���.�T.�m]���g��̍y�u3MUj��X_-��������W1pf�t��Pc�GY����:o<���7��Б�[� (�YK'BqJ~�V��=A�_,��c/8g � ����_��Ĭ �A �5{=�f3���C�q栘��n|߶�
Z���7�#/�xcTu%�_H�Dh��T[|i��B��Z5t�<~��ʺ4B��h�4-E�jNKԆ�E��@��@4m%���$>���E�/�D|d1t��:<�F�$����*�~,��-��Fc�dZk����b���u�h�����L���D�JenuK P���&�Q�� ���qv<�%�}!�f��2�ߙy�i���a��Ʃ�ƶ�d��e�g�(�Q9���'�KY������݄�k��G�|o�M�b�>IS��}\h��B����Ϊf���,t������W�Z�؝�4��N����,E�㍾��>\L��*)��[�W\�]f+Ӭ�p�� ���b�Dv�?����1�������Ė.F��^���։� ��H��E4Lc��Y+����F:�
�R�!���V��D�"N��u�s�����Z~����%�fw17�&Vb�,��\�^m��P���N�\�$��c]3c8\�h���z
��6W@�ا�z��Ԣ��4D�1�A�:XQ�T�Nr��s�Y\D�+����}BX��ݙ@z��}�) �^.�2����'>���X�>�&��X�C#ۭ�ci�:Q��c+O�@LC��� =V�Ӛ�u_����ѯ�
��ua]�Q���~M���.}��7��#����|�ŋYU]��l]Xw�=��0��68��ve2.[�?4p���3i�����@6�DXV��d��*}��f
SV�R�������z">��M:��[o��@�����~�z��ۡ���ڒ`��i!g��I�+(H+I�E*g!-|_�����۩d�A�[��Bx����}
`N:�~'dQ$b��)r�P�%Ż�\��F-F��Ⱦk��V�?��'B�M�$�U�EAZHn;V�w�U)�Q|�)�L!S�=�x��!����W@��]�		�	ʬS9��-Zc�( �P���੥H��P�x1-�!Y��Y{���ὢ��'�⚓/�;�-X5����� :^?��]�C_�P!���s�ЦY�l��=���A�#�-<�o���srq]ffRa�,�qw�}��v�^�ve�W�q�ACA@�߄��L����(�+?r���ϕ��{*Ӆ<���er�$� Fוx��d��q�<)�Ѧ��nYK$V��Yhb�r=S���� �դ�8
)UhJi!�H��D���R��j�Ӈ�`݄�jc��͚�#�Deܓ�ǺnU����M՟�;�.�,�,扬&w�1�O$��~+��6%y �5DR9�И#̘��NZ�w�|J���3~O[)��*r�]��)�I�2c���'���>���厅{K
�m��>�v��Oq�Ʉjސ8�I�r(<����d���J���;9H�'7Bh�^#.}���G8��Hu�jv�}�ˆkr��b�B!�:p/'R9s���1V��7�#f
�!�,{>�-e/�����!�����X�	�`���e����P@5������\���!��`����[�7?-Ske��!D��a�N���ɝ�~��(��,�PL]�h�üN��C�\�M̪������q�P��i+<�I��tQ@�k��@J��X�i�'�N\*�ȶ��t���t�$�Do	Mn�]6{I���X���6�Z��!���q\nB�b8�����!$��g�OL�͎��`E?���l̊��U��!W�ړ��"綳c�b�R��ڜ�d�ek��8RIЖ��+��^5j� P��@8�N(��A��{MDG�, �*%���wZ����_jJq:�z�e:��������d�C�O2/KHp�h�����~0�+�]2]r;>��G��w�g��� ^*v�)6*�����6.�[�|����NG�O6b]�H�@u�v	�EU�1��{�_d�
CVV|ϝD���W���>_�Ua �޺��?���D�r�q��Ԑ�c�}|��<%*	�����l�E��hR��r������WF���qݕ���|�/�����������S��@�����^OV�,��
a�$�.Dn��{e�,Iҭ?)8gx(�CD�%iI����4i-�H�Ñ�pa3'"|m���Z��y���aTJ� c|6���60�'�e39Xִt����O�D�W B�y]���	��q���	-�7g 4�}@��5=����&k�d������0����]���K�|T�҄�]
���|�_�4�x�L��1��	�F�J;����0뫱Ӭf��l2�I���R�[�n�?�z�י��Ș HlIZ�t�Q��O#n�o�I�vP�QԳ.o� y)9-t����3ƉyJ�8�P��߷�]��#�X<6�U���R���e,͘���|�����g������A�A$;���iW��[�!���Ļ�PJ����ە�.�g���,���Q4�7�t���J�r�hb�3�ԍV�ȧ�i(� s$��� ����h�K���v�:#M|!򏣈�|��]�R��Q_C��r���v&)��2]A��p�2����䜌1�]ù"�yt�p�|T�=�i�R}�H�ތe�v{MLlm?.��iZ�#|<&:��zP��	����w �[n3�%;^�
��&���V&����t)��S�;&q���K}�Ί��rֵf=pj�[
F�����[J��JWp*bv��u��Y�w�z����Dw��k����q:d��;0���FۧQ,�(7"�
u֡�yQ�2�A!9��X�滕0�eqIe҂�9��)���Ѳ�E/��ژV�lO�M����2�
|k �`5/�����_��E�k���R*��(�Q"���s��V���p;f3�ΦD�߲�ؠ�O<���iCK?g��s3���Q�)�2�+�!��:��ݏ��l�3�JY�M���h��V���v�go��"{�e�nFkTƢ���(�ͷ�r�*�Wk�z]�J�D0�P�>��qHZ��g%Q��[b�u��+cQ	��_*A2$<�q��!���{GM�O*�<���^>����$������� �8"hB�Z0p&�Bfbs�`P ��xge�۩ ��~�>zXS}�k8���6~V*v�<����K�-��ol�C�g'V��l�����4��>=B�v��G����2�މg��ݱP� �9�JQa�Nc���	+K73KxCZ�	�}���qE�zkE\C�bcU�q��?�'�TN}�==�J���0���b>f
o	��VPkb���BXJ���0���4X �=d���z=�7��"��wC�+l��(*���8r�p�ҙ^��!�:��g�wW��t���c������������/�w���n}Y0�T��^Ք�F�I��V9�u�b�N��N?9��o��(��W��Q
�Sճ_Nj��H+x7>���'[	���'|^~�u�r9��CsO��v���Q�Ҿ$>0���q&��Ai�����^>V�$p6c������~ۀ��^_����׳đo���H1���68,�!6�����.�����WI�@t�<�RC�Wl��>�mݣ���f��AOYY�<���^����A�x�x�.M�)�ܺ���v�Dg��/o�����>%��ghK�y�=��EP���B�i0��bt-C���#�P����kc�s���I0�|�O�8.�Z�K�Y��7]�R�{�~
�Pɽ?��q��~�RH8�'s��q�K��t��dP�ށ��3� �o�������rU���ߥ�{�6Ut�b����f~jZ���d
F%�t9�>E!ZZ+l�oz�0C�J��6��!�rA�T�f���,C�݅/�S.�\���b8��I*���D��mq���P��k�h�h_�uC���.���qk���df���֠������i���ܛ��0�;Wz���$�&�$%۝óʃi�He��yƛ���h�j�'Y̎}\���Cј�A���Ϥ>��D1��G���/�~���Da�4f=�A�c۪^�TGxɚ����Q^w��5 wygi�9E��ϓ|����u��*F�� W"��p86u��F#=Q����*S�oR���/%���kbbqm�S���#�!f<̽�#v��^Ċ�Q�8-�o�žB�Ǣ	��
�����m�o�����h����b�g�D���4Y�P�Ul�	ݚ	�E�n���`G�#��Ew�,j�o�h�4�����>5�'$ڠ���җ��Z�s��òZU� �,����Tl"�Ng��y+e�e?NR����G�{s	��h���I�J�;�"g��"v8���+s�	Z�yED��C�5�N���#F��*�쩤3��E�R��J'�� k�J)���k��p��I5�<Rܬ�	D��-u��#�K�XAX��o������Z>���X
�*���1�;��K���g�Ȓ�E�*y\�c؃7�9<��z��_��pO��9��T�Av��U
�B�6�4���z���ĩ�%*3�.���v�>����x�Jqષ��B~��߅B�/�VMk1�m��b�m�4�E�pm�8؃��B�����ᮊ9XE���L� �k���m �|nG6�O��)�h���~���oh����5wcp��m��y@�e����_9_�rշ5q��l:�!_�ύ���[�R	[� ��ە��ߐ1�;ALb��a�?��W3{����s32��9aV<�H:��P`�J������Q(��nJ�	��z58֯
�m����IN�ʄ�dPs��'1���׭���>�U=Ŝ�U/����� �@)-n�0����_����4XC'��rՋ,�`�Һ�JP�`�� �ϫ����������O"��R+J�P��ּbuǇ�8W��`�u�WX`k�{e�U��'��Z���,�X�?���|8q��&�UZ�5Ur�6��	��xC������eۏ[�~�tUV�G[������1�ཱ��Z��B�X���CRս}yػf�A��Ǒ��"��92Al.�~�ɚFg��]uyu6Cc�����%�W-f���e��B���o֕�ڲ��e�jz��l��C�E�{ Z�Q�1����I<�� �8��).cJxNt�<�!i������*��,�{:c��Ur6��J#��~�6�bu饮G"H�/WH�Vg�q�!�~Z��j{t����O��_YJ=}�U�������2��o�bǀ�����{�I�M}Р�����/�H��%�?n��ܤ��gje�_ȃkx"���4!�a$5&��,ؖ�1��n���s��_˨4��l����nx�"YV*,����s�43�r6`�o�j�+j�g�3�cd��4������C�毆j�c�vk:eLpN�^����r�'�#ɱ[.�W�u{��z�|�OqgRŬ}���F�5L�KY�C~��I�J? ���&~d�[]5e؂����ӒW��s���Z�vY5
� ���@�6�pd�g�|�sgh�{ȼ�T�?�@x�y�d�\���a���f"���ꓖ+ ��9��Pd.Z=MJ'�w;_s���^ҺF��Ηy����W�Ky���󝈱'���Dlx.E�xhiaSb-)�6�U��Ͻ�vT.
��pE�9 �te���S�f"ꤸ�>}�͔�2m��W�3�x��B�R�5���My��
Z$��DK.n]vJF`gZ�W�ǣ���A�9E�T�Et�B'���hC4L�&7��E���E����l�����3���� �l�/Z�]	�J;x"S���x۱0G%t�;�I��HH�&(L:t~h��{���b���1�;��W�D[N�2�d�0�e=��>�eCsM�嶛)L��JTrk��7�h��&���I`�2���	��\q�Yϕ�=B�}S��fW�[����<�u%�m�=�����yƦ_.���Be\���@�U/(�Hg�5��Uű0��߳��7$q>2�x{[�3���g\����#+�D6e�et�ǓVbJL������� UhH"2��$2���mF�@���c������t$ϊ>�M�!v*����j0�����P��]F2W��_�4��  p3�[���GQ`'�	�z�ۇ��!a�����A��e^1����V����9�@߈��Uo��ƴ,�r2%+8g���)X3�>n�Ɓl��C�͒p������d^E��m�LbX�{�
�es��O���a,
E��ͤ�nr��g?Z��]��ݯB3?����^W�>�I1���9�	-�_�R�����䘺?ȯ��(�thL�/;��I}3�#�xp"8+Zy/�A뙍�
�t����Z�G��ʦg,(K�L���G�% �%J�_�E�hm hŻt'xd���&�a�6���Ne�{1�1Ae��0�C����A�kߨu�hvG%����j��ӓ���N�����IP�"J�_$3�V�ۂ�d�,f��9Jiq������
��ja�|��h���F�������,�\���&��F�>�O�� l,�Tum���1^��X;�{����fY6n:2���j�ϴ�����,�y��3�J�����M+C�:�E	�
%Z���a���gS|�w0roN�Ե1(�L�C"����j������~Ih��C���k^!�����ˊ؄�w�~GFH��M��`� 'B?}RݰzqG�כ�<��?�'��?h�A`�H��U�F�z���b��I��+���B�3��A�-?���b��80�0�selRԦ
�Sqr�n��cy�����@��r�\�U�Z�k?+����?XĴ�$ذMTy�^��ͱ6�0}5y+m#<јݰ�Iٕ���ֱ� �T�����Yey.�]\���dFm*���"�s�b��ݭ;.��,+R�Ѐ��ģ`Ifڍ��.��C�}�J"�������l�I�����:E 2](��ҳvO�߁5�J�2;�8�}^H��Y�k1A���$$�Ku3�[@��䈨c�3a�W��;�։"�m	�ӭ���Pɪw�_�C�����������oC�Q��|���9#�N�{TI�$�_��<+>�{)^5�t�	'�S(U���y6��.%�w������"��|�]���<|��tꏩ��{O�����ww�|�ӑtB9,le��)L���^�.�6j�Ɂ��Iy�p)���73?R@'�C�����b�q���# &��p�� (�[����*MR��鵧++n*#6��K�Sc�%���B�!O�B�y�ջ��s8;�v���ـ-��5��p�����:o�[��<楏m��ZK�}5n���8Yg�y��b7M8�����%�6Άq;�2���u�%yߕ݃��2%Lhgo�p9��6��oz��C"��0��<��ճM�3Ɗd�y��Gᑳ����CP���z.�`�5��go�#Xͥ��y$'�qT�}lu�$>��k�	P�%P6����蒟TZn����x�k����r��; F$��E��jgu�x2�m��WZ_YXU*ix6���~��Jl��GhCcl֔�<̘|���a{�4��>�M���F�T׬�KE�g� �+QZ*Ɲ�A�H�n��H�9�}V��dk��z���ʇ7s5����p�_��ɵJ5�9c��n��*�W��/Y��j�iWOj9��+�ϸ�ݎ1y��>H��у� �F�k�"��RMh�v�6{`���}�&�w���*��:$�}E���:�̒My��E�\ZJH�t��l��~�pL�,�$Nn��./��QZ�'4B5����l����Hpl��@�5^����G6$c��D�A^t7|���Aӯ�(ř\}�%&�2��i��[�4����?�B�J�uʉ�q�"��3t��a&�(�����[/Q	E���T��jk� Wv<3i	��g� ��Oa�R�	�6D��I��"V��%p��Ei���T��r�����>��K�i:�(����}_����9n�O��	.��o�[�9���������r�{�QR�_�V��>H�I܊ɺ�=@���D*S

C�H=�Z����\����W�$�"aHQlOQ�:�r����$_���G��}Q8�ERM˧/f^�(�cC��<J����z�u�&�L�&�M��(e��h�0$Wf/jX�y���z[�����$���'ų]3�y�Ә/�16̓�~��@6=��_ﲖ�X���W=\�mP�N�F�͑��3�>��ǌ��R'�7�� E�3țP��E炃���a,�]
�Y$��V�{�)�p?�Q���Jdh,�2�uu������D?�ΰ
��2�Ij�J�t�F*�>?�v"�O��d`�9��������J΢x�ؙ;b�?]�mM�C��S�>,���[ �KSZm�B��1�v�j30r)A��Y�&ܻ1��u���59��Gl�G/ֳ��� �&�e�Y��h���l��/9��B�`oۇAnTK}�_q�vD.�J����	����Ԭ��+ה�g7�/�z�X�Ϊx6�%������L���l�:h0��'^����^�Ĉ4�����9� �:a���[n�x����pn��M�#͌�~a2�-�d�P�:��r�MR��`�5RZ=U��,��xWn��Q�"����H�J�qp�+��_牓��+ݑ���H=ɆD�?ё�]��Gv+�����D��:�xD�b��$\uy�t�e�Ĺ�#��$����Ф�Q���&�9��( @O`����j�@JU
� ����q/�'q�8v{��j`���wZ}!]���r%9+n��۽G�x�Ku�XxWGDr^��F���c��=-�"�_,r�]$��)Jn'��m<�݈_�Յ�/KlяԎ��)�6���O�@��m3��3m��6�~V���� |�鷹���+��< ��w;t�IX� g��(_�4��[������9)mn����t�6-��1���M�P�;��<�SKtb�M�bu�S�աF&q�N��q��4�2�ݤ��Lo?��0'�4\ ��~�eCPOh
�X�D���Fa��.ۆ���nR�#�)Ж|��ͧ�uM ��N�>V���P��=<��Hh�o��#B���N�U�)Ѧ���e�l�b�A�Ң�;�U  7r��*�8��&��w\竩�Ѩc8����#_�q0�u#�������J�'�sr��gd��%����B�76T	F9�\U/a�*OS��{G�2����Տ����DՌ�gwr���K
�Di!�
�GĮV�+�����ד�ٵj��U��_rFt�jѫ��A!�=���VKKxG@Y�d˟Ș{��'}���=�!�j�
��'�ϝ��b&\�D����9��N�ԙ�Y3ZǞu}����-l�۶	%�J��	r;�as�}��eR��Ҩ���45�8U�wH
�XM_�[�}��X���E�Rڑ�T\f����j7(��\)/� D�J�M���!/�?���v�*r0����q�L�I�|BȀ1�PVD]���: ʄJG��o�0�>7�q;����ͤ��n.�_\F�m�\'�0�9�t��Ů�xf����@�Eű�"�a���������[Z`)4�o�i�f'�$���&�3x3�   ���K��� ����E�7���g�    YZ