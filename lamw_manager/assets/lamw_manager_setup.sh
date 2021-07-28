#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2882804386"
MD5="683eaaf4b430b33ed4e8fb4b160076c0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23336"
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
	echo Date of packaging: Wed Jul 28 14:25:14 -03 2021
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D���$/RA	�,{��Y�էc^dZ|B�?��,��"���Cc�d4JQ#6$+F"��թ�05�8GQ!Y���*��l�e�ÑI��*��
���u%��h���h#,_�$�Y��du0迚�BG�Tl����B&8$�ˉ�讥�CZ@bk�Q�=��zC2+]��x����ȓ̤}%} ����n.�ƞ�������6d�`�)!�֎�����p���\�`���MU�^|���D��H��8�oȦn���,��k)�ͅ���YpY^|D>�xD��Y4�`���ݮ��u>�H�����TF�U�_p`4�-����b��o�=e�
��کB��ap�:��Ph>H�6�O��oed�1�Ir㏦�?E�[yui���nW~y�����,{�@"Z���(>�	]0~Ÿ��C߃ȣ�׉<H,n>k�+$Y���΂%r\����lG�����r`�'�ď��*����!�r��ַm�bq/�z3INd`�(�PS53�U�jC��C
n>4�����#��"�:g�X�^\4�I&<����� �Q��>����G�n��~�Aj�V��d��Q����!�6㬐+��:t�t��D�(;���R�P(L���j���(����Ϊ�C��X�/���*b����ZH�i58Xʀ�D�i����,nj���߫6����J�NՃY^����s�FY��Z��jYtO�g?��>�T�~=&ky�"�E���[��z��gV����uq.7��U���<�O\�<��=�v��*zt$�τ�\^oj���&l�`�X�r��}�^$]ZJB��4��5��n���o�%K#���>{��G�8�p�A�82��؈��IC4!eT��JFJH�M{�P����t`�g�\K��I�Ђ���	����/��*����T�{(/��t�^��<�����6����Is���iV1̼� �Wd��'�#ّE�&�.62��;�孅��\zΤ����,��Xҕ���7��*���ӓt��p=�T����߂������4.����LԐ�q/u��I_���A�c�]Ae|���$So���@�� O�{��#n��Qk��]~aA+�Y4��i��c�g�t�������Iޙ��5F���"5��_<o�uB߭����%3���5�^N��p"C��W֪��叕��A���GMd�H����+=���G��=(C����c�ܚ0���å�v}�@0�۽:�S��H�&ĉ*nx�w!���c��_m-��w?,�D���M;�r��:v�l��v'�b���6$�	�<���N�ϰڶ�l]č��x����^ׂ�KV�qˣe�D����d
��VIi�>�;,:�qN#����F�R����QZQ�Ŧ��#E�AM/$CA�v��J��il���>�vӎ2m�x鎁tD�@��
C斉�.*:���zoy�B:]/�|�}�#�|�D�8Z���Ӕ����r����|���Ev�ˆ��Fd>��O:Ӳ�5���H��.�]�
�rLi5�ah�%׆x����`��ܖ�:�]�wV����f;��'Z9
=����.�0��eC��ꪚڽ-s
��{��8.�S엝:�ר�Ϣy�Ɉ	S�Hϟ�ތq-x�[{3�PJ�8z�Cڻܨ�y]3�����z�*��u����T�1���u�	�cEH#��q�)h���˲��T�?��N�,�SbfGW����)�U.�Y����U(����Y1ο�I�Z������9f(4��+Ze�>�$�8_�{j�����2³�/�|R��6���}�����U�}K�_|Faqk\(�@����B��h댺d3#-��)EǱ	}O���o�n�r}�b&�z�Ρ�1�Unr~Z#�$�ԍ�2鑸x>��9���Nxh���U���;��_�ٵ*]����_S,i�?��8�X�p������Z� B����xk�>X��Щ����M.M�lNy�eZ�&�~ܼ�Ǚt�D���_D���%4����IeB�1�+��g���?w����^�����DE��\��z�-���A	򟲅���{*�炑{ƥ���amꑖfB��#���Hr��פ:9������B�M��	��<�	�b�[�LV��^+��@}�x毹��9���lT�g����N�l�P��ۢV���'X�M���U�P'��0�uDH��/]i=��{��0Bې�ɨT��zz%��py7n]5gH�(RgQ�3W��Kګ��^�D��
��@�<=�4���&��J�Ƞ�j�Ҿj~��iUݰԖѼ�����M=ηSi-V�TR������eP~M��hઍz$4&*�L}0�2�G�)'ϭcOQQZ7i���ҕ텗mx�D�Ԍ2si���V��f��3�c��3*�<������n�L���z�%�[���0���UH��!���b��{Ѐ��#]􋛚PhSO~Rh���e�ـ�j�l.x ���h	r��C&ˢg{�I'}D̰N�kv%i0�2d���8����]��~1n7sD,��܃ںLXi�xD��Q &���z���G���wwԒI�*���l�!e�ƥ�Bd/)@;���t�M^�` �i��R�7ѳ*(�EGb�P6�����§&ʒlq���n2V��2C{9���ѷ!�=N#�%�>a%�Q��5�D-8� �$X��]�Y�a#���m�`�{�>���uSќ_�Gm��@>UIF�+��l��%	4����B���d��$��F��Rm�w�6S��TR����R�R,	�:�$J��E�>�<SG�K�K�ݯӒS+~'����*%>$7	E	��L�^h�� ��7Ϡ�=��!L!*��_>�v�/#o@7���k>�6?C�	U�*^%�eW�~��Jȉ%j9���*B��ZZM�u3:;���o�`�-5H�A�I���7ߣ�J��I���DB[�j��v�G$� �.��+Jq��^��܊���xȗ���"��ܺ�`kwFY+Uߕ!�ó[%�֑�}��8�ݪ�N�Eϛ<�׍Ǧ��K�[p���%ڹ;s�y��l�-Z�@)PX�� wu�q�=t�ߍ�'�E�A���RF�u��I��?-�8�c6-H,.�&��0�o�9�ZY��̶D� B�g�q���12:�;\T�9#86dDX�X�Zv�����[Q�t�l s�j����Z��۾�r.�vH=FJ��F��)/F�`�n�Q�Jh��������*�h3�)�vS�O�&L��w���Ծ�_<���գC��9�<P;�h��K]���������@�<$�j����$w
f����q�� k��&3��uOS�I�����'�Y��dx��S"[�l[q�^����KpP�7f���!1ݒ������V���Ja@�L���,�m��"��hu�G���|`UÃ����(�8q*���#��po7���J�'��e|��>_'fh�%�X�K�'�$�nd�0O�B�|8o@�gXu�-T������Cy3�R@|<�"�/r4dY*~pr>��4lW�N,q^�*G�Ю򂱎:T�c�~H��,[��φ7�Q��c�R�8��;"�n?�aE����E���ִ��U�����K����h����G����[�7T�r�?���8��&D(]�]���,��,�� ���f�����P�L^մn$%�哀�\�aq
Mn�*�eZ�
�*}���r ���^>���1��٤�M؂�Sy
7ެ���U9AH�\��	�쯴�t��M*��AyŸ��2��\q�bx�.�Oԛ���g��G����e�l�36���xu���*Ы�^I���/� .2I?H��0���k�O�_P�e��1�A��m>��	q�>8��^܂I�j�G:2/�aS4�Ճ�ɡ*�C=�L�g���`�m���⡱FzX5�*0`�����/_ҹ�N��Yr��s�Q�6v.b�����W�B(;QP{vt�T��ߠ[�K^�a�/�<������7�J��H	Kp͞A���oITX��d���A�h ��֣W��ms�G�����\֫E��"���,F�����Ρ�'k|�E*5��"�(�� ��;��C�*�D�?�0{���e�\-g��\�ܴ?���+h��|xh�G�'�8�ҹuOKcO���w$��c`�bN�Zal�\�����T�e!��^~�[����+U<�����j�=�t*�j�?�Zd��H�8�tӟӬO]#bTd��ޞëk�k�u,������xY��I��;D���\L��S��1HށiP�:/�|ڪ6EP���� Q�ї$ï��(��p�%��ڪ�'�V`q�H��3��C"�+�~מ#��C��J`���WG��o�1l�DI��D�p��敐+F�Z�v��h��k=�s.�A���]�%CԢ�rZ{m?0�-�y����:�uζ��}fW��$|�Ǯ�<�RE��	�-�B�Å�Sqj�{Ga���}ޅ�g-�8̹�E֝(��2��I�Pt܆f�p�~+T�rJ��K1:b�Y�F����]��66۸�YEBJʾ��%E�3E�-散��Vp��:y���}h�Z��Q+t��z����g�I��8���:0��td�g5���M�����#��*>$�����$��V�R�oK�GZ�TՋ�ۯGIs��;��� n�"����޸�PR`��H�r��Q$�X� �u�rw���V��,�!�ˍ@S�GVM�$��@�Ŕ^线�"��r�y.���Ķm����?b��9ej���d�ǌ�qE� *W������s����1�vx�<��-�Mr�{/S3�{+@�^�W���^�<�dnɷ��;�ⲹ���H_�|�g6G:��2D�%G�����52��5�o8oH�Co�{[�QV����פ��(�	�hD/�T$�g��X��ε�x�J�蝎[rK�q� ��6��N�TIa����>�^�?�;���U���J8�ƒ�����ٞh�S�'�F�~}��0���h
�g@?E&��kR,o�
��/;�M�����\�nI]`��1�A��Z1e���麯��E��E)�縦8��bC�Uө����FS�ne$��}�zI��'",�i�p�a�E0�� uĞ�1���%LW.ę4���bQ9bN�#�/n��ݻ�s�2_>�����%�e����������%�$/�-|��XK��l
�hs]69����4p�}�SHq��y Ɲ�:p
�����5��L�$` ��\J�n9U����B�v!V�j��VQ�XsF�2���(p�A/�擒a�B��Sv�,
lF��:��և�${vg ,�ϩ�EC�po#�+|<�|��*d=��12K�Xr��ST'����%��X��'zo}� ���V{s��q=x�"B�ͯ�~���LcM�3O��9�'�xctyJ�}�V?ٔ����i�8r�Z����۱H<nm���!<`�b�ڎ"9^r�E���|q���m�:�r��j��򪳼��٘ѭ�9D�p�@k΀,�%�1�C��X�CFs^Y��@V�u�i�9X'�Y��^��_*�ƌh����W��ںF�Ȃ��}0�qs&m���/���g0�1���tj�������C^��3Z��nj��P�æ�ҁT�y,�4���BRf��K�v\W�'��ع�����p�-d��B�
˂�vgdB�\Gw\�
���Gҭܶe>=�9�z��NXfR�=V���pz���$b66��ۆCS����=�G/oS��ll�v=.LN;yp�wri��|({�bՎO��K����Uf!��������0��<t����:�T	�t�ؤh�]v��P���p�}Y�V�.����5�E���(�H��|�.5�`l��T�cU/�]�g�c��T��NrQ�d�O�a_it�\�g;��K+�V�~��Y��ߴ��^�&4R.\b�mP��h��ُ\��	D����tV��L-.�v���':
���F|^/�yMaSmUtb�{Z�D��|eC�9��-��01.��I���[�L|"]uͩ~�����)�T�WNwC��f�I�X[z]E��J�?�߄�3�hhL��V����e�e�OWf7!<뿵,ے�h�p9�Z��u��0�8�KԦ��P���Z{��"�tJ��^��#��P;�Ar�
��ի۱�=�Q�8B�ư��Am.u*8���P�?a׎�q't9-�{Q�=S%�f���H���	��[���Z�ہr�^p�:�����Ԑ�Ra����`��h��:����_�%�Cib-�jH�5�,��K����鈇��?ؐxtX�X�.1�C8\��#��	�S�O�R�v���^�����G�Lz���BNR_�N�i�)��p]�C%);��Oz���ww�LY��<nƦ\��|vq Lv)��Qflk�� .�^��ڝ,���g#�q���*�����Ln��|�Em8�ڲP`3Z?��)�K��פ�+D���Yֲ�n�'ի�T?Y�Z�r�9Q��	
����3��uE�ؗ�)�)(~+�͆c�e���=�ğ��~j*+ �[ @������rX�`����	�l� � ���7Ȭs�ů2�개����V�N�G���;�=7e~䮗"��R}����l��Sy'��ag`P��ތ�In�Yw0��oj4]>�I^ohzSM���6 �r�ӂ���ل=I�9���#�
�
v§��9�,L$;�,Kx*'*�X��S���e�0�ɐ�0�#b����8L@&� �
�����Z	���D�������T;[/�ic
�l�k���2�"V���4�vxݒ�=�t�I�[J��:[1Uq��p�!�d�j��������A$��Ȧ�v
��d���4��y�U���^�n�*�ު$��*�~���:x�$�?W���L����U+v�vVS|��ʼp��'�	�6#Јg��*�E1(л)O�����;8Z�h��������1<����"�c�W�ڹ�L�u�P0O����D�+�P0q�4�8�C�N3���?��u�D���8�&��~�.Z�7��>�ئ�������Ț��YG4F�pᒌ���+�{��q�p�Ѭ5|��`�������/����zu��ڌ"�v,"���Ƹ�h1������6�M\PQ��LeA����4k8&�_�����/9䚽�%$}�I��d���!*��́��뭸��/PYutY��{h�����M�b: x�4T�2&���5Qs91�d8��b��پ/�aa^�h�\�!�j�։|�2H���4�ۮx�~ 1ұ��r[gdθ��U�P��7ZX��rek}��Zة�84B��5ZY5ia�`������ѩ)�po�^����2��E�H�O^�Z���+Ja�|#fd�u�b>�-��m�v�6XH!c�9�&�^h�ql�A�&�X��&�w����^i�@�Y@'i�.�����4��M��\��\O��O���sO� �pO�[��#V����J.Y>����̋\'J?iD����NL<��T�n+�i&Su(.�bY��o�W���e�H��;O���'�p�Ӎ�}e�A6�}N������E �q��C�;�A��ؕ9��U`km.�Hs�D��es��V8��np2��N��_!o��������ܗ��\�1ϜB��(8P耿�ڹ�묡\�s[d�N�~3�Q���Ӂ�b�0�
%h��?��i2p���7D��h�GtU��`� la�+�).]����
F`�pz�� ����>IZ��1��w� ���DY�c���1v�=.� �.�4�F.��)y��c 7Hޜ�K�d���ր{s��^�� �Ə{ќB?@�byMn��ۢȊ�f��c��=�'��Cq����;��ޘ#�U+��%e]�*����O/�<�X�rI�D��~�z����e���K�]���%���V�n�=h�#���3��dg�-�^�,ʵ�rw���Pr��̟*%Rx��/�\G&��L���2=E��ӡx6|�g�ZA�k*�BQ�����/��P_�:���gb�5�PgJS𐇣��T��ƿk6R�2,WW����Xr0+�5�H.�����M�	�A�o"j
8�_�q�@v��Y[�<��:@m�z�yU�-��$�I��e�ĠH�'�og_.��I���`�Ҩ};e<���C <7͡��`�$�\�9=}J��hL���v�'�\��E8��%�3|8gnW��3���yi��Lf _˭`�OK��]Vk�ܕ1Y>��}��Yލ܋��49mi�C>�dRz[͝��/r�H65dK��ʼ����mS�1H�b�/�{x���6�$>xv�"%�;r�aZ���&,�U�����罣	����Rݨ�H�YYыа�$ 	�iϨ���e�{�ӕ�
��XA*C�iHm�>!�r���`�W�U��Qd�T�6�������1�0�ky��_����ŘBC�es���3�$�I����7�6ɺ�bx�B3����<Q��墐�澌ɱ��JN��>P��#�$��ڵW��hH4�}İB��T=#������������w��e�D`��S�xB"dMg@JF<�A��
�N��9A�w�T��p�D�$r̽C'�ZE�g|�~���1����T`��ǋ���9��й���������2Z�l��rTY��,�yY����I�����G�<B8��/2����Ϳ젼]��e˙v���M�l�b�m��ez�B�>���&�������7����Pԏ1���k����˱��T@P$���/6�L�K/��]�rۖ��E��:�O��Ue�T�Å^��3V������RWj2�T��f� �G<+i�$�̕ق�W�_)��hUp]s���J֑���D�2P^R�T�@_��x��x:y��qp��L�}��u��Qu>�݆���g�e�z[ʴ������e"�mbw��I�l�;�M�}��86�>�wA�S�L��:���&�70$�H��H��<�C�*�I��g�~��2~��r�-/5���.{���r.�����yE�!�����̴l��c߽6-�G��M���C�8��J�ա[��z3�J��]���'�w��y'x��X{h2��pj W	����r\��f��3:I+ڤ���5�ۂ�<ayR%��.żͭ6@�i\�@Wً�5}��W'cgZN-�G>�R<���fZ��nr�t)��[����EĪa�ᡭx�c�x/��ul��@A�� �B�zB���BJLo��꬇[>텆��m%�ţ�p����K�ѽ�2=�E���+s�[ae��HW�UB�v�y�za�%ǌ�q	Y�qd0)�\768p@z��fÀ�A���Ō���fL!Bh ��b��9?��'�D�����4�k�"j�5������`i�)ZE�L�'���*��h5(;��3v
ǿա"���.��%�Q�H|�u�yh����M�LC�C��ӵ孄�p�7O������x'G��+&����k���&��S����%�S�������-�xJz�y�3����꧜���F��k��p��%����/����8��$	�	��Qx�pߛ�r�/�*�<R�R�IL"�T�3Yn��Yq�׫
���r�k$$�
loW�~������8/P�p{0����ř�L���CX����v�G!+1��{�U��*+�!�vS����V#� w=����K��Yo'vÐЀ��Ce���a�b�O[n�n����(���H�XJ
g�X_5N�g��n��r�ƾO�&y�O.��%��]�~-���(~!\��
��O��{!�Y�I��v�i����/; �f��,!$<6���\�F%t��T;d˘�������NÅY^Y�N:|LRH��m�g�y����iO|���U�8mt2���Js�X��j�6�?Ƌ�Mb�C.�.e�:\���o�n���c8WA.k�zL4Q ���F^X*J#[�P�4���Eve��LArU5���7���0�ƚ��A���[Q?Z�|a6&+=f���-����Pݼ���!�����i��h���r03�1$ı��Љ�T�A�L��H��o��I�yas��a[��k��
[�N2��>t���ƦWF��B��ҡ;����Q�6�A�%��������ʋ�K��;���[�y%46y�%u��$y]��1�5tn��Q��i��?aJM3�g�f�|Y6��;Ӣ��d�0 TzJ�)K[�(p0�u���}�S,��'�b��!��q���p�9�գ.�Uv�6�;�����	R)��ĉ&>�-;Tk�)��t�wI�/�ҘӚ煔_���v G��B��Am�=��J�#.o�y5ݥmŝ3d�/)H��^�г�<i�%wL�y�0�Tg=�`�A&N`r�TÁq�"�%�.t �.�N�hK�� =}kop�?��$$���s+ġ8z7��}A�Ɗ��
�+}�����A���������>��j��a�\���m����?�t8&���2�5!�u�Yk��_�]�j��_Ǡ�S���/ l��i%d�JvM�Ϛ�����Ϧ8�������tE����6M8�t�\�.�'�U��^M����7�J�j�	jԭxw9���jWa ���6�^V���:[cm�k��-�:��#�*�3]
�f��?�#�Z�������ܔ��)��91`7}���O)��pNp>j�)bg����� �����6=��Cwʹ뙓Ta
�J�y�`���د=�=Y)���E�\3��%G��/�Ý���K�W�XQ%���>8�m֡�>�8�gI.�����O`���V��YP^�,' uW-��Ɂ���9���'�쏸|��A�]�hq5>��g�I�f�mO�G,���~�Cp�P]�1�Dr���z�@�V��[s@���.Q�z���0Hݠ��z�2���������5�`��~�� ���_�1w��/���P%
�;)����{�ɷ�hbX��[�+!��~�����m��jK��l��?���r�B�m�A���|���Wϙ������1���w@(3�M����5�ت��d����v3}3�������R�x�a+=>u)	[.��j[ tW0�L���Á��:$�<��d*�N�sL%c5Db��Ɉp�o@u6���ʈ�[������ Bj��1�I������y*�-6��|j���P�=kG���܈�֖B���lK�YCh��j7��/���j=9 A�7�lM�78,����o?���}�=c����E��I�a��Į�Э�b;u�^d^��91�� q2��5�X7�M�lo!����$�!G��,b74�u�? p�ď�K,��0_0U�D(l�H����"�p(�^� A'��N�}���O^U�����N�����'ydp�n�HtF��i�,Q�_X!�C1kk�l��ۉ�0��
��9Ajg��ڐ����D�E�d������~�@Q�s@���i'׬b�������?U��H�=�Y��m�ՐG'm@#��ag�=_p&7�n�}��y�1��%��<�hA;b1�jg"K(���x�(Y6�������f�����(���sn!$�F2��U�%z�,p�BK~���f���@J��T��n�����[H3���n�3K�{Y���G��E�w����C��z��Up}u��� ������_��Z���-��Ț��>n7��e�K|���|PNvxo	�7��k�zC(2������W:�e^X��|�u�7��:Vu�pB��b��V̞	�d��b,������=f 5����*�����c��X�c�������'�xO�/ZJ��������ȧN�+����8��s#�HE��<_6Xӱg�R��!��^
J�N�ʬ���\���rG�҈q�u���'���C�)w��/�󂽔�&���ejR�U]l[S.���c@om��e����d)����%q�zv�~�;��뿠L>u �Hi�K,�����Ǘ��ֱ3h#�	N�u0���ɥ��;��=�#c����F�0 ���)EU��t׆�<�夕O�!З6��i�*�,Z�m�L�*��&�>r������\bW	���4PS�G^N��6q1W$ңn���B��َh��-��Г���Ю~�_���w�{�{H��a�ƀ�?�,q��H�r+�U����69�E��_#�!+oE9�<x�,�v�[{��/@�w��:Ӂ���hE�kX2Co�����.R�]u��
��%�;�V,~8̞���@�D7lOs��R�r�2}�q�R��yr�4� �[��+^o��9r�������&�,��k9�RQW��^�-9g>���Ru�f,?RR,KxI�lk�8���]���Ax�d�G�C����߳;�R�&l|ɬX;�'/\���X(�W�!0xN2�D��V<>�jZ}Y�ҧ���m�J�Ȱ���[%����#�[��N�����g�|�ae�0Qt���u�����p���t�27��J�.Ӵ�#9����I��,�{�j�*�v`���u"x��U�g��w^������#e�<�����q��Ԗ%�+�s���-G��%x�d�,e���a5��?�)�h���s���[&$��қ?�3���lL�<s�f��lz��?���:�*�'�f�r�2I�׮���c�'�F�n���NW�krAg͜��w5���l��o"��gE^�iIlN��-�(�NF����2��{O���5� �Ճ�|c3X%Qf6�[$�Ͼ,B
�@��܇V�����3�d�� O1Z�����+���ܒ*3�w�S�0y	�O��aS�� �N?䓅8�^�pPz�9�L�"�(�m���)Nf8�MT�%N��|�nzw�J]D�G�I��	0ƀz��Ct��"���P��$"���9��W\���m�^`Po���l��& ���=L!?{�΄�!LD9��zO�t�J�ʢ!�h���-��o�<�?���f�
U^:�3bJT��e����.��݌j⭪�aD$�ڲ^�j4�����e���|3{X��n�a�8����i��X<����f:�rQzX�-(E�\�� �ǼD&�'�6=���G���.J��C��7�Ut�����(9�������u�?����r{�6}���buB���@�!^As���ڑ�<`��y�y��H�e�V�/d*a�PQ�K�uߤ۫G��w߃�SիϟTz�@B�i�_:gX�̫��ﭕ�M�\U�����[2\��b-�3�:Q�@�u�����34pO�Cn������A���>��tw� "���F_WnA�/9L�� �+��D^��޵��K�}���& K��yͻ~��PhBl��w�0�)Q/8#���UV�p�U �\�Q<G��Gr�	-�:�}�A��TP,�.5��۱T�$HT�]n�\�(I͐^�~\@#�k���V�O�q�Bh/8��\��xb�$Yt3a�!-e/���	�4<������ (�TV~��hE-�A|S���"�@�x�Ʉ\2��L�.{J�������&��A����*��H�Q۵4��K�1j�v[�K��v�GȵX��ؓ����k
���E�.	�Kq|��V�lqy���l�������wF��Щ.Ԉ� ��n�5��/|l+Mᴁ�\/����vџ�ӎ^��I`7 W�U��o&Jy�Ί]������e$�F�:�J��L[�laľ=�:q~čɸ���q��}S��� Ǌ�v�H=�#�˒FT�аG����,���oL~0�J�W=e����D���2)�}����M��A�W]
�AX��M�x%Z"_65��z��� /.�)N�s�ٰ
�JX�ǧ��O2�-F�V+���d�R�`[J?�7�Ռ��mH#� �c� %1�-��h)m��j<������	�����G�R�%�4F#E�6B��jNCX�C҄`'5�B�����C����
Jǅ�e�hu�����k�Y�O�\�58��R�f6�5M��O���Zo��w��t��J�_�������z.1p�h$�������jIG���1Ld�����7=@��H1�{�V�P�2Z�>���P70�|�ɥ����#��g�2Tk�b�>�)���w�pM9 �{�!�!�)�_�aMR���`�� ܓD,Z]�yrk��Y�!������]�d�A�D0K��T����ڿ�c.QȻ����T�;���3^f���oف|�׊�]'����S����9����-�b`�۴=�#�ű= ��������.A1�ܭ� F���ID	�Y��r6�"�����9`�@=�!^ܼ����D�E�cL$M�����"���9���|>iR��w�C<ߍ��̀h+,b�u�E�G���b��@U��`N��1!>�x��K8/�ӹ��WÚ4�%�1r���ښ�.焾B��K�]�Y��
�����=�C�ݷst_l�3\o�yYz~��\�h��mP�pQ�,��,��@b��$��g�$`h�!��m��-�y��{��\��JJ��J>.��IkY��oq��jU�Zi�}v�=Y�\�e<3S0[���ʝp����5��O�>���eئ\̡}@���C����{�]�Ӷ���d�[��UaHD���xo����ɪ�I=S���k�4yV�b+u[R��u���ٜEY�)��ښ�[��D���9��m�5z�ؑd!����R|�x,5��D� >^� u+����S_W��>B<�1�#��L[��{�S`��QVp�>���߾wc���a� �Z �M(���֠,}��E\���y�P�?����7���#x�o�z���p[SC�#���3ٞ���Ne��({j8�ɢɘ0U��c~��O�(=�]����0��%,ȝW�T�XaK:�E=F�V)f�J�'1���` !���'?�((7�і�'j�Tq�����4q��U�i�@�3 ��,��i�#6 6��D��p��)�F򿢴��x{�S^Di#�ø���P%�9�*�ݾ_hW�|��c&�.I�̜��B}�j�=�:r��ը
��&��?�d��&4�qVw04�/=Y�&.���f �^!�|�t�����C���_s�|�F������q��$��,*�P�d,��̍�&����[�v�Χl�b�-Mذ�?����W��+Q���~7��y%��*���[:a%�4��M������:���eq�~K�A�fC%@��Ψ�b���gv�h,27��FƮ���-6*�r)��$2&]��1��=j! B"Ax'���y���ѽL�?� #c����yr�N:	���pXN��.�Wf��C%��4�/?b%�A�N��~i�G�t�k
B׉��%룔�*kn����H��FU�n${�t�sD �zr<�W߭ڼJ�����w�q`�t8�j���;]�Tg��<7w �1��ߴ�W��U�-�s�h��v�B�O��htp	w0b���zL���9�=�j�ծ�V4. ���<�*�{�e�w�㮚k~��*ͨ<�*����"�2�)�K�T_�h�׋Ԕ� n[cR(κ��a�}kS�[w��F��؈�j�zL@�d�w�ED?��P5
ԙ���8�1X���T/.$-H&��2�z�;˂�����,�g
"�DU\��:��T2���S����D�g^�
l��Q�o�ˣ������Oa
����d0�[�
os�����x��"к(��\[��O�V������ )�9$�6�u�x~����$���?֨�����#m��� ��[hO�ſ�g�e�ͩ�J��`�7h̓�v )�hFmt���m��(�:�=?u �4F2�(�������6�l�fa�kq8Ew���G[V�݄E��"'NG&v��Q�Qc��47<�1jE��iH�D�r�AH|�>"�$L v�+��q�.�GI����U^0A^d}DЙF;`ΦD:�~ƣgV���iF�����E�α�$��&�/Ѥ�2lɁ���>m�g��X/�n�i
����i�߀��fI���?v9��5gZ�Xi��H�9�&�K�Է-���G������&�ؽ�G}���pN��P�h��,���6�{��N}���{����c@��~�pQës�36�%��}�D��K���{P|��=7��ۉh��ٖ��9�� �����<}�*��/McE\
{��������_}�=��t4M.kS��("'�y�����Ş7��=��7-���w�J
��l<��x�1���ĳt�Pa����MJ��5�Ɉ�P���ق���@�
>�'2�6��s��]����H3�����o<��V��I>T��k����|h B5�0����ɀ�i�2
�\p��WHz�xu�t'y)��!<�i'��2�3����a����j���0[oy���e����/�4�L�PU��g�%�٨Vv�{�x��k�1�%�i*9i����*&eL��7����"�t��;9�J�fjVTҖxw�*e���x�|���7�����o�oi�Y��Y4-8k��*Nv�Pq���������'������$���YC[�4!י�~x���"`^�=�p��:�Z/�K�i�����s���\�pYI�4���']�E�9uB���Rϳ'�BM	?I�y����q�~/|>�u���_����WԦ�Q���eUC}��<��-�q�d��.�B1'�*E�I~��ߙE�bg[Q��ѠiɇR]�ƨKܛ����/�=��!�l>�6�<1ə"�` 5m���(��y8��
��(�%U����I�kU�L[�d�!W��3w�Vr�+�k���]T�ȴL����2��Ʃ1!U>� Ddc$]ٽ�6<�5�w��@�����K1����/�[D�;Gc��`�HI��;xuD��[DH���]}e�?��$��W��0�ߣ�&����8���SS�Wx� ���e� ��ߐ�)r�b�c��a���f<oO�(�A����0��ݍ;��hdn"q0��琻�+����Y���08�e��ZY�ky V��.^��c���}���
�|��}] �P��m�R1׸~c�R��o�~�g��c�m��Q��vzΝ�����E;��v ��G���wTU[�(��HM2�n�z��q�l����cό��1�����~N��)%���3C������f`)i|ػ��`xp��4T�02�x_�kNS0�Q����΅巇�"�W�'��8��~���O_�fxo;�~��;F5�]<Q��Gd��M��Cr��A��Q�jn��H&��tL��7�8��L��lV#��aNV�x�G;jd�u�#��.#����`6�
�[����G�0#a����P��n�J�dMDU��BQ&�h���|����)#̑w+R��ӽ��ZgC]��ez>��]�x������D&���[t����$;�aUf}�\�:�_zf<1��{<�y��W������֟�m7�}�Cz�2'���ל��z�G�;��Nɩ;���u�����v֥w��[��շ��3^0���M������=�\��T��9�z��L�o�<ewu2�c�\GS~Otݲ��B�7T@����)��q�v���ꕢ;��#�C�K[�B̈́�iS2��-٬�ͅZQ����p���\���1{[3����vĉ�C��몘$䰉�0X����1�/��'�����^Q"RP����#~MgmAC��w�Sz1�VmT1��Oi���=j�������������Wn��!�X�Tr�Lp%,@
!��k( *��R9����ޣ����h��s�~"���:��/�&�FK_ߐyܧ��Єi[c���G"(��1�;�e4�?�J��м�e^�!fӈ�d��ѓ���	���N��-ʴ����M��'�t\%Ko֠���׊	�L���b��R2@��9=�1D'��?.�Wa�q�m�����vx�������U�S�����O�#��ʉH"�(,�U0�P؟�RLO��e"�Vn?^��|%x�~�^O���	:r �`sӣT�:j�:s>6��J��{����`��u4����8j/�㺫��E���Oi���0�_�)�+����,��ї��@6t}=�D6	o��d8Q����u?K�3f��;o0�39��C�cQ0u+�eK���	l�o#��6�/�V/��S�9�Jq���_Y&�C��e��J����R��T��`���h?ҧ���(�._�6G��e�+�����*�=6�J�N$m�H��s��R��[A��P��!��0B�=
�'(cz�_l���Ԣy�:0`-Ձ�kiLO5R�95���$���@�T�g�:C.��KaʩL��n;����EJ˳7
|��{�4��#����a����ܮG���+Ԍ.�3 ��g��W���K,:��G���8�[�)�#)�CX?��m)���G�v/ޛ��c-^�V�#;���D�M�ZI�&l�2����⋺�Yє3����Y�����x*pL�7QQ�~;�5~Qf�oS�H=z���|)��fOi��A���Jz �[��?��//��4��b1�����J�#�,#n�=xt�6K��_k�tf��X��z�����&E�^
��V�J^.o�ɲ����mm�2�V�²�\�BଧoA��������-������{"����yL��#�4R�$�-,�,I��o/tv��&����"1����U��l��"�>[�-$�'���Þ}?���h� ��]d���o|&�5֪u�]�ʬ��i��If?Q'S�#�t�{�d�!����`3,|�PX���c�*n6�;�b�݂�X�Y��R���g����l�yCйHs�C/T� yFc�JUt0H�4^L�w�O���Yό�ŝᩧWn?94H���6�=
J�ڵ،3p�����Ļ���z�nw�l��nɆ��x=J��J��ޯ]�5?����4yl���e��u֝�͌���tDT
7�x8^���&�|�^7C
X���{���@3�L�S�jU�CHt���Җ��P=�<+�渗�Jf�/������������ER�l���B!Zl���$�q�B��[7V���}�'�]�9�9�	�JP�sl�V۲��m���b�V��U�hє�Q������eku����r]PX6w<����H������16Ĝ�px�t<<�ZT"a?8�2���3$S$x����mW6��5�j�7��w��r��<�?N ��ZwP3�j�8��,k�>�--AA��>1�f�C�y�������;���oU�.�D�@�9{1t�&x�8���<��t
�Y�wlRsȐ>�(YC�?��&����m�*+�]D��zR���Э�O��]���B~��I�:��;=�모B��̓��&�H.��G�.��׏Iܪ�c:����ؕX��L�M;6/ �St��j�A)[~o��w��T@ԉ~��|O�&��eY�ReS:�(>zXz`�ܴ/�O�@����щ�w��y�?ѾS�֯e'�h��� �8]�"���(.��,�|���!��9��k�ȣ2�qP�ؼJG�YL�X���N�fF��}��u@�������z&��M
�6KJM2���k�m�a�dLC^�xsY��$o�~�xp3�+�����T�e�����*e��d�C���k�{��OE�iv��0�����C�M�n
�����гH4c~,-�q�2I�[�+�d9w	}��!v6��M�4��+��+5꓄��t¾��v�Y�򁢫�o��$(.���^��n�;f�^ Q�n���5n9Ҫ�ԯ2��E��ţ�p�d+�e��U���7�i� +�G�g9�y�f8�
'&rR�K��LRmX�vB�
f�Qx��'(���C�f��R( 0$���܀�|�]��6��3�nO[�ab��U�oo-�&��5/y���[�� >�3ƫ\"s,%��@�w�^��FRg���3#)���^t����,��<m����[�>Q���m� W��@��T�8S���ߦpn<�򄯘Ub������*�D^�+fh~4H���h}����M\��t4�^�F=�:��k?P�/��B}�mߏ�?�oł=�i��ecm" DA���"Mk����GE�\�ל��pyyhp�kc)��E�;�恓U�5��d�̘�6����!d�C5>a�v;���~��G�b]��*U>$�F����-<�SO".����0/�*ߢ���g��P޷W�x�	y׸d�WZR�p�dmc��/��@a4I�}=Tf:ۅ�[T	f���6<}�4^b\�D�,���Zz�?�`ria|�����N�	���kڧdz�-��<��h} �9��;��hߩ���T]#����h�K��H/���9�/z���T��V�wޜfl�$���z�u�;����E�|�]K�;U��n�Z����}GO�>�wX�\۰�V��+F�L�ӆ~b�Q;O�1��Pz���"cW��96�"3�/Up��S9{	�`��*HQ�$~Q�׼J�Gs�N�V�t̋5�����yã���(e���9�M�)lV%��`ұXJ�.Tmz�fa3�&)cV�F�]�'����ۉOhs�{gck?�Cڧկx�0��t��z�ľ�$�wߊ��	z'k�CXGDMGEw��x�e���}xf	��
�<���9��%������IV��\��"�O�k�(D0���W���c�ꬺ(��bDv��AO~3�O��M�9	�R�Ҕ�N�^���!�8�=�/ɉ�y�:9z"{���3�;�7��Ht�k�o��އ6RZ�P��3�_�A�A�k��t�+���)���H`����b,+��*D5m�e+�Ѯֺ1��Uff�7�wѼ	o|㇗�̨Y�T�a��q;ED[�:�1َ���o4�5��TQM�N���,�_,�!��c�:��(�U2St����www�'���?�0���M��_��(;Qu�@koo\�v��zm���`�ae䎴(͸2��X��%�YPs�Ƈ�t�C��#�k	�;���O��?�".=�W�˗7��_eA۪l�c��K��$���l�4���+�e��a�w/YC��K�*��9 'rz],�J��;�j��F�n�5�OikX�I%�F�d�¶��5�p�Ԝ�����~�s	
�v�S���ن��q�B���eVI�6���`{n�ұ�g�0�9���(�=q�+V>DޣZ�22!`���������`��ِ��<��@F�,3�/�������@�q�Kj��-��nh��#�AJnd���s�i���6،ʞ#�x�&Qٓ³V D����Vjp,�^D��do�n�Ho}n�m�(3@�p����	����j����Ɣv�*��0g�᜼g��f��e���8�ޣ�Eˡ���ɾ,tRN�1�_�Q� �;>TEx���E�Z�{�%dW�s�+ ���z+���@�.��Ȁ������ixl^�1{]�q�F[��y8HYCТ3cJ�B�e�=Ru�0�#�n#�K���8���0.Y�H<O��r�0nHa-\^$%#�/0���H�-��䡦�cN�IN 4y6jg�"챗`���Aϛ���羪�WjxT��D�&��BpU{�w7���ͤ=�؜w-�ԏ�Q��|:���w)�X�Y�9�d�7^���5��< �F^��&	��[G�.T��9��^b$J����+\�9��@���I��6��K��_*�r�Ϛ��Hf�} 	ҏՎ��kk��1
_ԯ��dg#;�cߕ?��$b�p� ���/�
�1��M��nҦ��i��qmD.���l9�y�}G���"��qv��#�?4Om��b��������~�����U��n����z�0��i�G~`�ox� �$���(��&nTFY`8�i��1ޘ�N��5o	��V��S�V*�v��"�6�齵 dxT���	s}����g�hw��z�c��:g$<���k+1�	�/y�V^L�$��R��7���묺�e�S���7�t<w�ak7�Yd����f<ڪ�Ԥ�L�k;T�y	S��lo#@I.p��sy�>�	����� >1�q�|o �Q#Q��{��)^����� �Z��8��cԜ`��P��:`u�$sݙ���	���-Z���q��5�a�/u"�e >ajL�:�ԙ��D0����kd:t�J�;��:�o㉶�w�`�|~)�sd�r.Q7W�w��P;�Vzo�I#�U���M��-��SZ=KD-z�WM�p#����,>���;R�&1sơ9w#@K �ӹ��p�hx�_��j�4 OQ���4�j��릖8�=�n:�һ�`�n��GI_O(�/<�""7 mJ�aOӵ�=�<Xj8f|� ������h�/��֣x}us�>�6�$�v�3�/~*4�BLFwܕ�D|�0d@����	��l�Zxٶ(�Ik7���+�0�l80,�z�Ad�IB5ֻ#���D8� y��&C	�z�6T�C��/y�U�����^�
��[��,���jW���M�P?��H3q!00ф@&�)~��k����DM�Č���+G����J�R�Ԙ݅��K��iW�����U��n�7ۤ��Ǧ����:���D�8F�ﭤ!�k��t�֔��n��h�c��&��6B ]MM �ȧ泓�6�ZwWU�h	�g�� ϖ�� ,�Rܠ��w7�,��U�SMgTF��|�.���~�(J~u�����߱���K� \{�����V�z$��u����ҵ��%e�҇�gEG����}��쿊c��5��st9�n�WL��g0"�kL���������Ag�d	q��#�5�^��w,���
��T��A���^燵���)e�8F��
�i���uG1�_����(Y�M��xD#��\  �ၐ!$�� �����A�ձ�g�    YZ