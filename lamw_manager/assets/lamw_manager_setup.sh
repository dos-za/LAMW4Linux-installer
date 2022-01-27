#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3419496199"
MD5="dcb514a3b359ef8ab916cfd3e732d627"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26036"
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
	echo Date of packaging: Thu Jan 27 03:05:14 -03 2022
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
�7zXZ  �ִF !   �X���eq] �}��1Dd]����P�t�F� �O6���2+�z���%(�u�I-��R��&ֺ}��:ک���}��*R�t��x���ރ�H��O����Tj?vZ��Ub�%�n��!�F}=�䄓�f��c�n�1�{�OȬ	�M���Ɉ��x�x'{)pn�'=	���L-`hnp��� �Ӧ�	]o���M��O����*�����+�M�>�d�[|)��ϰ*B��V��KOe�G,�M��,���|�u-�3Y�R��!�RH����A���&�(Ψ;�C�U9�x��|���Dw��R=*��V<��x��H.�w�M%%#����4�Q����gd&՝9. &c�zi?Es�@ɳ2	��V���.?N1�k�.�H���;�ۻ&B'T��0
,�i�*|�N��������ԁ�C��E=��\��>nᵤ}(�uL}� ݠ�YJUv�!���.(�����cx�:|��E��7Y�M�����:��<I�� u�t��?���SE�6:�ӊ?DZU~׼KB5��I|N� ���;FM����I��Ʌ;�������x�E�K8 �j�VX���1�I�ɞPG�I�K:��DM%*SQ:5���������N�꜄M��?�n�鎴ۆ s�P�f�㳁]����Nmb�[��F�t�IY�n�ul�0IB6+�+R��d�N,I�~�k*���~a�εYc��^�u7�F�A/�w�9�v侧5(m$ũ)���e(>�B�)�>���<����OX�bA�'�2%_��t]0������A�lt��%Q8T�#D?ڃU.����A�?YT��x�' �r51Ǣf'��9�����@�{��BT�8��;I�ٚ��cn	�wk�"��uZ½�ɂ]l��mEK��]�"ʲ�i	${�(\�p�9�Q=f=��W���I�3��QB�O�������&���7Ħ����n��!9[�Da��x��<wEVT��q/����i���[c|o�%0Θ��Q��R�qK���oU�EdT����U����?&W2������R����	"v~�?���?���3�@2���Ҝw2�w�Z��v�֧'��~K����\�t)��qX�SK6*֧��s*����12ZL�Y؜���n�)����m|��H)Yc��BG��v6��V��=���2���: �&K"BY�Ul�����J�y&Q�ʗ�V�*xT���'!��o�����9�@Z03��!�G>�	0��2�#:ɘ}�چ�9�.����U��q���y��~��a�-�#(� 	#�Rg���bu��9|4�X�\�A�Lqx�#9�_�P����J^�M�NuxΪGB>�K�\��j>�2Xuk@v��9z Z�_ø^V�����p仑�p�d�hu���e5
�������@�xi����\��z�dӸ��Hx� �|󧱘��/�����(�"�f�M���.`�EL�� J;�n�3��檢�g�"��,�P�[�<
��Q_I�Qe��G?�q�ԡݷ��0%W��s�p��A=j�����W�����W��9�X_=ğ:o��5�3�����4�<ٿkVG�c�f앱��L��x{��ϕ����y i��\�?Ғ�#/&�Jp��)�(�Qacr����O��C�P6�d(�$�x��6���Rdp�{��6"�'��-��$j�݉�Ut�p�G�0Xc4\ 9��~A�KV�\_egU��h%.�:~G��(2�X7��8�J�
�e��ǻY�|l���
 Jz�
�Nbj�j�S�^eW�W.zw-��U�(e��!�8A�P��߬+�0BJTp����{*X�"+7���H]�.|�4�����3��������78�$س���^q$�B���wp�[�E�J��{ņUOI�N�t�bkG���4�2*H�˽\����4�q�?t�����NMнe���" ��"t^?K���.�W�Īn�r��K��`pJ۶?I���	\B��r�*�/J�s��%+{��� \��ff�������'Ae˗�0���B,��N�J�]���H����{�/Ԯk�t+m��v%	y(����f�}��N_sȑH�U%�������w�G��0�����ue"�-+�S�fkLtw�!��:�c���4�X���i�#{��ψQ��w�r$Cc�O�3��1=�K;XɊ�>��W��0��9)���5`u[�������zrE�ԥ3%�P�H��P�RZͮz�0��w;짴�>b�R�� B�%����+��m�r/��5��c���Q-8M�}����Չ)�P<k(�yڛ,���d������'L���_G�9�UMU�����	-=����~�$;AU��۾�P?��T��!rc�Z�����b�������9��Ϗr��H�q�[c���G��:j��f�vg��܄&�L���52{�cG#T�/��EKgB<�P�<T�B/�e%�k���TP����E5z󏽅�A3�I��%�V��QT��Vr?ŵlB��բ�+B�s��1�v����9��Az^]Rl�or�qD�"J�*���3x�����	��S�Q��5R���J-m�t��/��:	�5�-�$�#��R_h!��p����>ƖǢ5w/p�ʥ�+s���C�"�؍���O�Z�_^��<0��&>�)��9;�C�T�'�"�(s�E�m�.���u�����!4K�T���֌0�뼹vu펥0J������^t�'�t��}���	W�}tA�,��3�����.xT�-FF%�=�Xt��c��Jo�+��'�eSJ����<��Y32R��U,�w��X���_��	4����q�s�J��̙*����?�_p.�ӊ����+E1�k#ޣ̽0ޛ~�V�O{�(�N+C�����*�����W_KvM��w\���3f��F��Px{�J����%�ɬ�������Fkn��Ζ�L���9��DȎ�.)��>B�Sw�玟��6(�N�8|�����O��8:���P�!o�)|��z�CS����Q(^R�T�Z�V���R�rSE����D��Z�eDm��� �JJo[��y5+��!E6m����W��={���FvS	��DK��%{��fR�٪X���a��g`���F�{���R�9����Z��Г?�|����S�v�Z�?��x�RirPsYY9;5ʟ?�x�ïm ��}`Oe�28<Xڙ!K'�qt2��궛�S�d�vh�\�(�mc�΁~������n��P��T-F�c)����r⌴�@ה	ͯ)�M$9��C'a���`���Y�v�N�R��S�Q�]�V��u�\�|+J�m�0J`c�2'��������4��P�d'� {'0��kKq���탏��ږC�j*ָG�qOߑ�wNu�*8���ؤ�H���4F��a�>�~�-���nT�,^���;;{A}pm��2�� GB�n �s�h�L����60f�u<Q�֫bA+ύ��u�Y�±־�7�w���}r=��h5�s�[/�l��X�;}~.��a��J�����y����n���W�Q㓖��M.[mD[Mo)j�c�G�M����b���T�{k!}�ԉm��>�	��5��ub��9u�N�����U�K�uyy>�b�pP.D��Ȭ� ��G�u��I��_Ń2�ά��j�V��#��}m��'�B^���s����$�S�`�6	.�4Eh���=�%�g5 �����I��`8�^�qf��P�c}逸���'~��i�!�5a�0��C�����S�P�4V�q�7�0�#����aԦYMfeON����$���� �qD'n���Z�=1�b��W�ci9Q�T~�p��:S8O�ʛ��8n�b}_)�<�"��8�tq<Y�Dmb��p��3�8n/NB%�m��Ml^"EN��5��q�i���3����׉�r��N����S?r�ֈq��VA�K�O���Y���qi��Ps9��͉�P���p�ZLkɵ�G�lOI�p4��X���~���[����l8�8�&��$;�5��]�<��b_��8�C� �������,*l�c��x|�BJ�����֥��8�����L����p3�x����&m�B�|�;��d.0[�&UH��f|י���-h]�m�8:�}L�����ve^��v]ٞf3O��}\�D)���;�9D��NQZ}g��.psn����r��M�C�o��՘�� ���hr�m.�t�e��~�����?�[+�3\S J�6WJФ�4�w!�ZK�P�<��Z"�����<��Ȃ�)�3i`��bTm��������+7��Ԟ3���TE}M��_z/�������Bx���짚P���h�e�/i���/Q3E��E�g��%�1Λ�mzv��wޒ8R��-lj�<��G3����m-2�b$���I�ʪ>J��3FT3�+�d����>�
L�F"�i-���~q�Nx�����7)��6�T�["3N�r�{ɟݾ�/#f���v{l9uRW��W?�g7e��&��6�Q��z�M�Q#�4�Hwra����>~2��	��������o^?U�^a�e5��I^�[�mhoa�>�����!�MR��E��	�1u'S ��g�M�����B��~N�~�y��y��]h����toL�?0���VjQ��H9�j�?��n�lM�F�&������=��-�{�oϐE�98�@�lX��)��M+y�-�L_ J]�]���Or�+�E�V��&���R�#N՚���g�&�٣��F�aS�X੍��]�����y-���!��Ay�����N�_p��z��KvL��W����6���b<�&@�*����S��hsxԻ��K��ԕ}{�Oq�O�J�;�r���玤p��<�/4�C�,�4�⋑;��B�<3�@�u���ZE�^�S�8�>ԗ*����6�xx�4�19� ��t�$���
;� P(��2�\ܘ�i(j���7z8R0�)��(˶���V �]v���H��3Ę����$�!�������Z/y��k����o��%l��P<4N(�t�	�a�,v@9��'��,_z��,!�!�:�r'@�~�5\}�� H����R��qR�����1PR������~ �*��hIk,���fTR�n��z|�C��6m�Oy\��֓_{�`��;�78��� �٤#�c��z���o��/lk��;9t��e�bG�y�P��m͸ �G���9d%�c�4(*}����~a�H�k�0��|$nX�ӭ ����h�� ���U�� j���k��D��j�z��� �c# Y-��=����=M:��rV��~LW(�tK���N!����E�k���Zޭ�@��N�XU�>wҹ^����AP�3���gp>�_xx��_GE����H�u:�`|+��_<�0ۛ�����:��e�uf��rXM4��|��_������n�6h�����λ
�`?���ؑf���~�񈷠ʡ�eOX�GȖ�q[ZtX��ƿX����u.'GLP��t��(�Ho���dŲݾ7�:����&?���IӔ������]W��q5������t~��E�=���BE�y'��{|�Pރn ����NL[Ʒ��Q���~�K�ぃ�B��V������������ZkAX�WZ�7�K��{y�0m�p�(W���9���,>�e�v���+�Y2��?��=���Nl`�-Mt��_����ލ�:�����4����ݗ	D
v�3�y�ٸ'�bKE��D���P֩{��rC�)>�)���XA�7C';*�u0g��T��VS�D� ����s*�����O��ԧҥFH�'�7�+�Pz��O�ud����n�O�$��|4��PK�P���Ȭ��g�x��<W��ֺ3���R3f�����u�t���mm��!"�[d��}8�l�dt-��Ժ������|���`8qYq��)�\s�=Cyx%�JܠM�l;-լPb�iO��0�͗�cm���TY	�HI�ܺ�#%���H��J��fj�Ԍsf�H��fҴC��QMYF����#9��b��S���D\=R��y��3�A3IZ}Ya��BQ(�	��f[|��ގ�����7��?���{>m.͌��ԃ��>2SB�q]�=����.c\�qqU<	�j$*'�)3�����g��T"�ehH�֏���$�J�G-4Ԉ{�c�|�1V����<	N���
,3�:o�'c�H�|�55�F=&IHÊj}�&Ҩ
��Ib�{�|;6v�/O�I�G��N���2� �R[�K��p/��HTr��̟~�ổ���ҙl�w:�|oh�zw�� ��.�a{����yU���������XXtT�S��$��Ԅa��D�"�(,�ϓ����S�G8�EE[�.#<���3ʭ�NGG%��XB��8=sC5�?�L�ߥ|I�i?��P�xAg�j��AT���O4YK�����+�YFol�}s�1obv0=�"6?�������K���Sg.,�g ���h�6l����aA'!q��|{8��Szٯ �\�N�$p4*��6��a�S/K��W�n�fGdQCYr����D�bP�����Z=�y�g�Jv���qGB~)��~� 4����>�|��9�@�h�q�P�5����?�����^��(^*��q�N�ly���_�tѤ9�A,_��i�̃�*ҘO�忸W�~�W{M�ǋ��� h��!?�e9(Z�F��ɛ����f�uᅘ���Gۃ���%��ù �\D��f노A*�Uc�M-�$�o)9-�ę͆����;�O@~�\������L�G�t�X�8�cb/jRɣ���,b~��B?H��R��i2 �5��b�6�ZZ�#�Oq5R���B%����hl��R�.��r�-�̣�b*,�z
� K~t�Ixz��&e�{@i�J���#B
�;V��n���#ձ��3��	Ox�b���g����ID���Gf~�C��lI��%�c�S^�Ԍ�Ɣ(틹���@��&��5P�.����sCG�R�8Gl:D*�H�T�FG�@�tb1�诵�@{g�!��-w����M��b�����[���½�ӝ^f��P��F2�)<�Xq�����'��Sq@K�3���؁��)��DO��0��4`@���.[&��/��r�j�3��qfYb��9��2��Nݖ`!�)x*�����ni�&��-�
sa�S�z�	�,���el�+I'�5Ρdge�gx=E��������I��i8+E�JZ�1�=���K����^栃�*X�	�!�}��f�?��'{�.�<��*б���{�� �|���`X�<��X?<4� sJ�� �R�&�H�$)k9>��>�%���d:�,�6=�P3p��o3ۤ�5YZ;�O(�������7b�X���g��q*mZ`���$k�@���y���n	�-�@I�z�g��}i^h����"�ז�SLf`+э�	G+�/=�tY��L���;"�d�X�A���~��dRX6����Q��p�:!A;�&��5*+���IB"MSb�y�.�?4�c��(͛�3!*E>s#N��M�����~�HȝǅJG�1ha/IE��A~��q�_	l��PC@��@�>�I7��t�"��^�pL���p�Y��?����&��-�\�b,�-����}�
)㵒
N\b�B�>0�)���n�{�fA�sX��������u����j��kj�!u�:D>���8}.<��yx3X+����}����^B�&t"k|��2��$)�fn�;��UzX �r��t��=��!���ibo&Qr�Ϯ�#Y�,�2��JrD���=:Q��g�ӹ,�Z�'Љr��,�CY���T���l���L%h�y� O��6�� �H��!��V]!c|���R�Jc`-uS�AC��A{�'f��~��E�H�N��$�n�{��jCo
8��B*6?��a����m����a4|�`T�!�����`��d*����	�ȃ!��0���<�ᬉ�FʗQ��4��_ʑ?����I�Q�ږ&��:���f�܄�cʫH�"������t��.��K���)��#{ �|�j�ƾv|Y�AV���>�-��䜹sp�]� ���'�w%'�wzB���%.�i���
ƴ@�&ݧ��m[wע*ch��k�:�И;�ߕ�z��v����Q��;�E�ep��|w9xf'?�zLS��:���4a�K���eemPv�̱5�?9�s\	W�P�x�����0W=rvKԌ�<�g40X�I���=���h�⋖ʌ=�4�HM��ԘP����ܐSǨ�3��"����Y¤-@R�O>��� �:E$�5Q��[I_�|+��#ݱp��N��!vי&��n�/+3���u�a85񝄰��s�Z�1jF*���K���#P�N������m������I�hV��\�{����I(@�%q����3��8�\_�+�q�1��pn�og�}.�z��]�N���Rj�>���uR�ݳ�|2u��N/I'���T!�tX���l-�ƨ�NZ5�u>�M	�#��ц�067�KS�1�G`)�X�����7Ͱ�YP9%|��I%�X��!`���c��׵Od����/���m����p���/Py ����k�@���.3}��eK�x�6<Nx�~V�TӬ�{���1p�V��=+J7*�	��$��7��ɮ�"K)�Ts�+��"U;���b�)�
8�ܫ���Nڟѻ1��p3!Y�q��A1d�7����x�Ǫ��q?vUg�[F��h�2Z�B)�����aBU֣ւ��<��%�Զ����3c?j]�ߔ4l"լ�,�D@���}�6O((#����բ0��Ѝ�r�=/o���'No�
֣w��s�t�F !u3��9��j�):�ɟg7jiA��$��M	���ï�׺�W���4�,�r�ZЋW�@۠���;q�����!���Rl�q��g��ҕ������j�I��]���y�P�Z�ƻ�?sϺ����$=F �z�����jLb�����=~�&E5�����r���wGT��7y���m��7�&��������t$ ���%	Zp%��:�n)[}�k༿h�(��%�oZ~|i�v�;���"�3]G1���n��������@>pBv�T#J��� �������!���,��Bd��;
��Z<�.��;탵-��3օ���S� /��lb1�k��G��o\滷\*b_�\��Ξ���k�Bk��an�	k���fCW]b޽+���Dҟ΁����?{'V��q��Y�l;����D1 �����Ө��s�w��Y/��qe���Ӈ�G!7�(���jNd�b�n���((ɩ0���Z���a�6^
���7�fg�ݶv�6��=4���9�����;o��/��)ӊF 3��k]G�2Lq#_~F[���G������Ũ9����\ۘ:��L�ś�򢣌F�hAO�)����i8�RI*q8t�%��&_Z'S��[��wݷ�1]&h@*2*�޴o�Rg��LT�6c��a�����Q^�[asa����I��W�4���U��[��:B{�"?� u�Sn��g_ �8����:�	#����RC����;��Cz�@�K>u�8g�E
������VsѦ�՗�I`@?1l0s'kei�� �`�徴<�Z���t���=���`r瑞�ds�C�eP��=+o�������!�>��B&��}q����M}�1E��q�ȿݍ�r"d_���x�GO����d� �[ՠ:b�P$�xrg�ĭ�����a�EŔm�6�\�4�K;A�og��TʧϢ�}�.���TX�Q�}���Y�+���K��k׈_�|yF}��A�ݯNG-@Y�ϖ�mG��"mCQf������Y���������xwOL�B|���lV�����eMN;~$d��.ڿ���hcJ\s��b�j�ض���P�xw֗�-���0M�e~Jxej"f0��~����p�k����9p(CgEl�v�\Z��dQ�_��NNM�K3O��-�	��4X&#P< '
F���Z;־'�u�a�ceełͥ��F}��M������~�6`�l���2��R{1��:�nOƖmD�Ł�'J��J���cy�X�DOѯyXS4luDq��v�qX�,�\��jFyWf�9��_��#P�U\�&P4�<!�r���ޚ��2�5�J��Q%�$�.;��� T	s��K�
�N�[��2,Һ����맹�
�fJ���U�F��a޽k�O�"H�?��T@^�ipK�fQ�j�S�ʘ���L�+<��.��Ӓ%;E�jD�\ŵ_" �f6ԋ\�� :Ŀ$-�e9-�r��j�����DJ���LZu�{6�Q@KԆ�t��S�A����~QB�*4�D��0�@��/���e���\�'������UThE��x�A��7(����u����ʡh�R�=SkXU��RF�
O��:}(�6i$äF���[�sa�/�bU�$����¡6���,�_ͷ)K����.�H2���n�u��I;�y�l<�ů�nQ�1v��ZP��:R��ދ�����B�V5�iҞ��'%%�y4r��ERPp��>{���z����1�� �q�@ݿ�8�q���IgKߩ��L���VW�e)fX�9�֏��Y�El4�,�.Y����ҬX�_.z_1�����n�(:�µ>>>"��$��QJ��J���F�WT��-�г��*�_���L@�gK䭟�h������NcT�TRWe�铼��9�.��˻d�AY���I��K<�����F� �)���ܛ�� 3ii�Oֳ�t����!�aF��b�L4}�8Aտ:"���M|ڜ@Kw?��[9�,A�;�͉�Wlکmv�E�`��'�q�����`rx���"��=1��監G�U}�ey�t��ӫ��\B:!�$k�:2Sx�����q�����lB����^���k2浮Bt[�y����Y
�,�pm�����}���ۊn��kv���l�p5���r����ʸ��C
=��}lq������Q�avL�	�SP52N�?߲,�Q_�Ĳ�� B����8��rE
��^��Q�^w��2~�C�p5I�ܨ\�$uZq��Xx��� I�ڵ����(<�1B��>2���Qv߲���K�[���t��2lA���('�]g�Q	t����l6ç������K,f�����7J�MT�<�n��v�&fJKHV:�2ޞ#��^?�y&RۚEt Eyݬ�~ڼ��?���]�=�����OP�յYc.��w��"��o�� *�Iő�\���\n��n�}p٪6E��o�t'����	�0�g�)�n��!�dQBt�S�h�>%y(�� �7b���Q���c���P&W�|lB�{\N:���T��[��+��f����8H_oK�A�Q-���R�x������g ���!���I�f.Au�W=��++6ʷ$�a���0����1Ԅ�Ӂ�j�Z���MX�~��F���j
,h!g�X~�,m@j�ysR�\D����U�I�1��S�^Q�7�g�P���dˊ�^�;|l6��n�f1���+��HQ�N�B�Nʧ<4&��D6�Uڍ&��Z}���ңA����)�1L�m&�C9�"���@��j��pϗdLeE<{nǼc��s6 e�_`gdfTC��`l�+i�4\�D���)��K!���fV���s%��W��kC�B3T�n
��}��uˑj���e?>�_���D��쬋�qa�ߙv���F�Y����Q ���-@hi�H�S�93
�����+�%Mt�m�Jbx)X��hk�b��泞�j�y��kn��c��x4�	��ߙّ�yA��cU��%������|��i"�`ߒ�	e,�x��L���6H�Z*��V���[]>k�g��L]\�����m�MW!��G�Б�Q�i��e�a��k�R����3�'M���?UQ���ˇV��Fk�Mr�i��?���-�{�NFȃ#��>0W_u��9�V%�G�i�p_��%[SC��zlh�=��3"�@B�#틃;�ÁS�,�^��7�(}7�g��C�3�խ�����{�I�d�� �{yY�PX}�j����.;a�kL><\>�m��#O8�|����Q��`��
��НtK�wm�Juq5����m:9�?ԇM�x����Ntā�<��S��P�/���|��1].Z�\(CE�a����UI~�_�\��#�=��j�X�w"��a��
m%�>R`Ha��h!�Lu��I�!y#�36ڞ,ŉf���^�'�����"?�9��-�y;9�� v�g�H�� �$+_���?��h���cq��F�7����]?�o��(��l�5�� �^�ɪ��Z/v�zCY�?"�{��}�(�$�.5,�K��&6C��:�"���hi����������b�ʡ_'4���7TXo�>��a�T���0�*�40b7��:+C�D1S��g]'�E��P��Ʌ9��Z=����EBu/�D�h����>3��T&`��=��̙�-E�e᤺���y��~�{�4A��J3����>4||ϠPp��� !j�9�^��G�K�Zn�i�!Ov��ſFy� 3�ŵ���}�pU\ŵk��Y�]�b띨�����(YL��Β�����n-�W^�?iu��K�9">u�"�iMRvKl����
  ����ȥFG�}��K�35*�^ը��o�Yc��y��8�1�g5�9DTp
�ʥ!��Ʈ�� ܊���1x��dY����3�VL0*mz����%>�s��ba�e�܃�ՀS	uF8m"�9$�?c�4g[�������q[����|���)>�rwg�!`;[}}�] �)�}wkZ��f���=�:����\J~r��[i_Zw֛v�t*�߁�벬׹/�t�Or1�T����\dK>����BpR��<L��ҕ�_�_�����8��f�[�[$�@S W�&�J�����>�.~0�`]h��&bv��}�����	����N��J
|�'[N���h�;WPx8n�{�H�Yj� ��m�R �7��I&�P3� �BG~�ဝ�"���4Y
x�Bé涾����=\
v�pZ�.H�JB��[����f�����cV��b�!� ��BS�K���O�+xGUt�����(�#v$%����	�W�V��m�����v=�n��z�0�ᤊ�8�j[��2����#����p��ǋ�e}y�˙�΍/f=6���ɯvQF��b��aC�/WH��/j��"F|�	  h�2zRcZ�ejG�K�X�?	���YƩ�S�[��:�����`����	�Z��T��+�e,ʾy��^Z�p���\CZyY|�Ѡ�O�^ғ�Q��U;�s��4T!:h�`|�D�Ť�УM��QI��M��7%?U�������l�d�����ڍ��
�������r$��e��u��{����w[L��YRFڙD��fv�o�b.����L���2Α>�P����|�����ij���O�_���>�^!5�?ľ(g��Yi���q2P�'��+�W5��2nGB��ك �{_p�~��6����2#<�J�^6��2T��u���G���*Z�5cE�	�%S�Ѣ��Ѿ��n����ҥ�D��N�X�'kK.$�OM]��� |�3JM)1 ��Į>�c	�QJ�y<ҍ]|�!'�i��_����˹�>���&�%�kL+B��p܌a0谕��=�ZLy�EY�Z���M��A�~�fY�$zS?"O�_��?9����8[�P�﷤�p�G�Q���à�c���D~e� ZE�j�7�`��r��{�E�\ɉ�y���xzV:3X�ʳ�t���XFB����D�49��i<������1<�'�/F��t��؜L� #��@�T�q��,���%":D)�	�º�P:al�[�� �+�Y��t?�ʎ@��x�34��%��� � ��g��6�q;��+��qr�.��v��.i�2�}���6��vs���kˑ�&��1���$%vn/m��Z$�/!XΣ��B�%.q���y\ỳ����+@0nm6�N��g�I���G�ZA�î��}��3��`OXA]n�dE�i I��y!!(�>jܘ��zl&��s�X_�i]̬&���0���ý[gdE9Lnݓ��K��E�>�fx�{�&c�A�O���S����{���A�k*�h�lh��&�O��^��S��	���m���r�6+��'�MІL�w5ig���P�@��E������s�E���K���M�]u�s�t�{��-�����|<KO"a,DX�q6'�!T�n.��>�ʻ���E�E ���t�ɯ)M'�z�.�Gú}��_����N�`�-o��5f0"��h,��ͨ5�e�N��Ro�E�6�����~♄KN!<4$]�b�-���� Z��䛞'dm�kb��Ь~Mi9ˣy»�8������J�f_m>JJ�K4�%��2�[RC������3�1�@ٚ��p���*�׉P�W>զۗ���i�JZ�����}���5`!����(j^���ҰP% ��kj����9�=�ŨB  �%���f;mG,��z;rS����#�h�z�B[s�5�u�'�k!��U�F�&���Xh�{�Q(���8Y��8"�j�~�6�Aq���o8�K�k :K�;y\fɘjlƌGs��Z����������R� ��l���}���gRdz��@�T�h�rt5mk
p[͹|�#|NNxT�%�q�^��.��R)����fw�0�G	�+�GS��'�1�?�t�|�沺�iT@�:U_���P�79[��k-?��&�!�)P�1[߶��(�t��	TY��|���o�&���|��l%��v������!JS��"3��6���E�T#�K]�J�]�/x⨏ğ��Ֆ�۫4U����t	�c8�l	~��^��-{���p�&v�<�#�?����;�qe�2���y�=��.�M��������[c�㬛b������d��l�jbY�."����t�������`�q:4�U�P��!Z�3�_�8�����_?�����ςLV�,����e�7iЈ<�΢[Pt�a1�{g*�����i�]�/�qd�8�;���BV���1v�<�������¹I��+ ���bLZZt�>�� z�P4`XTy���dg�j?_}�g�uE^�z����=���9ڇ�A���wq���~I�����M��ݲ�e�'��t�L!�_bF�=����g-l��jz��c+%C���(�(Vȗ��f���4}��M��[�-���<V�9�.�̞ T��ӿ�/��$�f>{�֙���s�!�TR�N=+r8��z��s�I ��柇?��dLC�&�Ԕ<e���Zu�k�@��� =u��Do��ȼ���a��h�<�{o�}�J7���[���}�Sܡ�H�OP�5㜡ɪo�]'"�'�B���!����aNc�˾����l�>>�����1�>���!�hc�=l���Z�̲��Ob�-��?dcC�g�롷n=|-�$ۭ��(����㕈��.�x��C_��0���J�� ){�����b����a�:f�����������T��i�Hx�gJ�e���`��>��ј.n7XH�^\��$�r=E�J0Y��!(gɫkG|��Ĉ	+c��Z$��F̨���$�zN���G���Z��I9�OJtm��l>��э���0y;7�װ�5M��޼
ٓ�Rߑ�������AN�7�r�џk���<���}��H�s��8=N"�g��<�t�K�����JI�Qʓ�-raY�J�����1{�1㪎j,.�iNr��=��~����2���uy�ȵXΣ�&F_`d>��H͇e���HÀ�/�7�2��!W��~���Zf9v���X�p>X_�jS�I�Z� �&c�μ��D복	�k?u[D���6��4�� ����m��>��X�>�����]� �ֈ/%u��bσ�\��W��j�N�wPe� X�D��`֬21X�ud��q<Ļ�����YI��d;��m�$.c���̘0��g<�?�ڹ��0B6Iұ��II����@V��ߗ�m�K����PQ� =H?�]��Ͱ>�}$N����Bߗ@��1�=�`��S��t��j�s߷���:Ck���B�"�d��OԚ枷X>
^'��?"���<�̋<������/ �e;�6ްX�5(��(:�[�T�S��<њ��n�/�=�7B'�82�h"�=��3gpgV>���M1�٤[l]6w�E%S��ʅ@5+��y�t4ˍ�XՂ�Ԁ�i���2�f}����Zgͱ����É5�1T�2ڇC䜐�Q�i{d�&�؋P��#Z�F�la琙;r%�"���#B����ˡ�6���@�p���b�[ل�S�����m��dg�D�q�}�K4��Т��g������+���ޤ��٩�Y&\QxR��w�`�%k]3u֊���idqR���Z���]�i}������A��'e,�h+$�H�xq�sf�zR7G���&_�xC=7�)$nĭt�O$G�����
	P�OS��>�M��+:��W�3p���3��^<ìW��sz���R|�vw� �{��J��V�p֒z=iP`�<*�u��yU�����F'�/7e3쪨}�J����	D��t<}2~�g�����O����M�*�����Dm��`'O=�4`ש#�)Τ�T�;�i>�u������:Юt�ݚ�b�<�����q�a��m��땡�-٨��
�p�`�%�t�jl/ܷ����?xe�r�1�:n����nM�3m�r���9�0q��h���jM5\(t��`���TY��s�t����z�C6冃���e'��p�B��O�I�|�]J�$�=� ��צn�<��Nt����G&.g�l����H0V>l�>i��8Yt	R�U���>�#f"�Ĭ&��^^��<;�b����Ro�iw�����~q�Z�#LrNBnLFM�交Jt�I�`Ǡ�P��z{�<FK]mǶ���y���R�w�pkq��;d+�901�	��`�$5	:RXg��CCj.�DFX���;EG���tD�kJ 5��hܟA� �ل��5$�'�̉�h�웺_7�ghl�r�d?��U��-ki1S�1,W����3�QH[I#Y���o� ���xx�� =X�F��d;����Z��5'�2s�0�'h�p.z���-������dO���K��Xȑ�����8t2M۟U�#�����U��Y\8T�Ʀ�p��z��C���)��f�F�ݑv�xܬ�����N`��8�;1�+5��P9(_'~=1���4��Ty�,0�i���֕	R�n�e�d��l��Q�m`�5Ğ6��չ��*��ס�� ~��
(������[01�)wy��~�K[Bse?h�iy�߮鉓����G`�3EwpGCfNK�O�6�Q���`�䷶�%��!%�j�g��@;��%�nf���q��G�]G򦠆�\YJH�J���]�M�]�Zh*q�>��9�u7zf��e�!c��2%�*���k�{h!����4@͛�&�b)�aAR~�惵�,eP&p�^xbT�ĂT�ȯb��&ozUks���7~͹y�@U����K{R���4�@tx>FY�����Yp���԰�M�n��x���j���~F�j�h��DJ�n�������gū{pY��9=u�"�X�#�)1��{�P��5�:�8�+_��k�m ����`�=o���r�t|6�G��c�;ܦZH��(��<�ov�.�L������V6J�o���tPFO�$q��#4��+�JDMv&�/�"�msx��h��s�+����׭�8��ec1�Uܤ1�E*�� emx�6cf� ��~�c����H��#n��иN�yV�p�����UdP� ��i7B�-� ��(���e��Eڀ�%�u%M{�V}��Iw�>����k�͚,�l���ӥl������wqhو��s�S/�SwjOh����;r��)���vǀ�֖ B�e���ԥ�z��+��)rw� K���!��R�(���{�yH;��Bѷ����*rK�v�Q!���-��+/�	�Y�l�@4�W�@2Q�3�L\�$H�~\��b�1��:_8����z�_be�4ƙ[�E��,�5��e�HЁ�)�O�NŊ+R.<�&��i��q��Ji���aD�.����Җ@*L2������q���3���X�U(���:fM�<��9n��^zs�A����U�������	J��%�]���eg-�;�;`���U���W(�]�6֫�@%=��ڣ��`�B��b���v!���+���пP~��[P��E>Px;�����.�9A4w��Ho���>A�"\����I�x�Wq�6�Q$z��?����ER�M�v��"3��o4����u�{�k|��#W���˷%���>\�pv:)Xog��3���v�T>��,Vc�������m�u��		��ǟ�	��3c��0��xa���-ZꘫX�U�M�z�S�a�b~m~U1�>ÎY:ɒ�;���0�۾���Ϫ��޵�]��ۜ,��n�YM���=E55��嵅 �e؊�������D��J��а߽����f�\`|y:�졆R��`ɢ�ʵ�M*u��Fb�)k����'�D�<��f��ɯƍe�:|"�_��	�8�F�L�=�{=�'��.# 2,>���Os��*��
���#};"���ݕ���\�w[r�A���/��+~F�����Ƈ����Y�,�a�H]�)�(�GP8�qKp��K�/����/� ���5iܐyZ�r�f�7�(��1H�we���Ul|��+�4�G\�G��=�ی�/�#j�
�\�B��q)�"{w�t0cқ2�L��q�m�եV�Βyv
�6�Ӈ��S WK�G�E�i%�u�����o��#:����W^�v��h�2~v�<����4#\O��8v��	Wk�T�ֈ"��L�K�4�y��?�uM~�&`�Y��ueg���:�U�Ӎ�]���Q~�J!c�u�7��#���ũ�;�b��"�x\��*��:����ڜJ����"Ջi'�������pHl\%Z+9���G���h��#�ASy� �Q�fd�_;j�i�<QB`4?sW��5��a��Q�Xǥ6�_��V"�l+=��5�z��p�D7{PX��#��ܿ`&R���j��t������Z���wM�:�]J��.-���'��"�QM��������X�+o'�n ��<	~$c��S?c-&�p�w�hp��;B��F�r�ca�p�ڪ����0"?��c�W�����KAC*���>�p��������ɲ��7� �S�]�9�v~��	uřR��`���SS3��C2�.�_�dm��I�1�b}/��S�г����Z2=b]ڴV���.���񙽎�K���PY���]�H8-�@)��y�R���f�[��E�q7�Eh�*X�?o�,�WVU4T+�N>���DڏH�j7GR�K���=ב<��6��6y��1
l����ա���ߛ˾|<��.��fB��M�s�Ձ�5��m�OxII�y���@Y�^�fJ�a���D.�?���k���/F�o���G�Bb�@r&��Z6�R���fo��9slN�?�;Uh�͏=�,�X��}K�1|��7vc ��[+��Ů�!��@"��~�j��`����"�9��V@�v��M�aa����Xafx�ʀ�%��,�nA�����v��4�;��Wq�W���1]Q��v��.@,ͽ"�@1�*ߘ�|��9ޗd��*�0G�;����E�2w�˩�]Z� ��l�c�f+���$����'n��-o�wf��n�O�x���2��K���[WEz��+N�R~H7�vh�4�޴�[��( ��%��6�P�S�tE�H���1��)�N�c��;-d�j�M|o]�����*��q�s��J!14�&?	_�x)�w�X��� cz&�&�d_�~��*~r�0I��-������#-�=����8s�|�����n�^l�d�%�Տ�|�����B��8�rˊb5=��n���<��W�8uZ~�q�B�w~�	ۭ�:�K��'�oE�� �S�,{v4����6����)�!�b$B�7�0	#�LW���qm(:�/+Y�� h�k�7�чݘ@�a�UR�������0�<>)\p�)�T"�J�^�B�%MA~�,��k{�Yw��k9JXذ�X�:���ó�n	����'���Nph��`C����B0B8^�%+�T ��̱�t�,o�>
"�*�B��5l'v	���E4b��G�J�[i08�߮�����)��F|^���:�>B�GBA�Im�Ko�Z(�"�_T�-�_`��$F69��������3M���#�㱠}&UW�V[�S����c��&�ve�Q��!�TA��ͬ����i�L�: ��ߌ0�7J'X�.��`+P��6����ph�d���h�x́A����+|���$*)jXV�QZ���<Ed����Nk�	(�tq���}oc6E~�y�f�����]1���o��Hk��@����6+�"��6[+�Ę�T=��C^!]�(On�V}�u<�) B�9Keq�'W�S'c���-���^澙�'�,��002O���_r�-C�� �,"��g]ꪮPJ�n�0���� ���k%޺�[��x���b��
�3�3ճ����J�o����{N�w�ҢC!_��H�hq�G~�s���c���#�c�ZI�<8�=�/=�Gveu�n�.7:��=��Yn�H�ۃS�Z�3Z2}�i��(���D:��S�|Uv��]��$p������[�+�hrP�H⦊�+�aB�13h2�"g�[ߟ�+�޵*��" We
�C�|�Sc�T��-� �NB��u��{�|��ą����[�ա_��(3�l��f�5@|��Jw��璖�=�p�n���E�\.��L�]CQ��\�J�Y�_��KJ����w��k�l\�|�����`�C]p8EΫ�Z�}ه:�31�dG�nf))�S�@|�7�yB�5U�z"~���T{q�[�����FS̥ia�F^Uu�I�����>�9#��]�T�|t�:�N\c�)��s�Rc3%L�D���x��]��1D��4ֵ/��zS�Y��=���+h>�S=�F"?��v%�)S@*�0~�
�l
w[͆�l�]��r���������wz�,�i�H���O�:�+�K*,B���=�,e����S���E�	P��n�Nm� �E-�o�i�G>��YX��Q��C�LY��J�j�t>�Nj��EHw��=��m7����fՄʮDJx�V�?Q\�%Ki����)q��j�E���a�t�ͺUdr.P�A�}t��I�6r�yAT��낭�!�1�b������]!u�fh�5k���VZ�i�t���F������sd���.���!k��/s`M�	�<�h��͎� $>;��w���	&N��p�����K:�a���G�
x��N�W����3�ԳQ�)�E�{3�%�D%XUWSm��-1&x��  �t�n�����.e7E��P3���$�c�9�RJU�uV�g}~7Z�)$O�P&��w�c��^��U��(�F� iq��T�R���'�bb��ז���(��%���:��3��}�7�r�P���K���r�sۚW�e瞦ZC�^Ϯ�"�=#M��)��.&�w9W�İɴ|W��Ť�S��K^�����܊֮o�b�
_�L e鉻���Qu������B���Uu��k���g��Ɠ�}�0��kөZ��}oR)sK�P�B�� � |�0���܁2��-�vF���hZf`4�2�:�^��0�q�|�c����0D���)�񰇬ħ_�G���>p�A�f���1.yۦ�7(��R���>�ͦ�pB%Zd���L��	s�A�@_��s��1��kn�[Y������9rm��+��P1m��e��
e�|�Q��(����+=G�9�a�o�&b� <���T9��Nn �M��%�ϓ�3PlX�I+l�'��ڸ��٢�<�l�*�BH3��v��V[q��u�������lb���H]1�f��"��	��P�?wDS:��-5H���x�bA��I� K8d7#26�ċ3@q����8��$�_l�лi8�<-�-��o�'����O!���)���ʤY�ZܓBُ�ޜ��-mb�A�C����Hmc�I��h:��Sy��O��[G�l,=xE1��>���Ae��Ff��^��U&Տ�k��o����t��HL��lE�HȖ_��~�T(r�~���QOSL.h�Hh��UbK"�f��c�El���F�Ut$wx��ԶT��.{ ������;�Sp�Uy�����]u&�i+���;�g~��QY�4R�f�#][	��t�9� ,�S-�e�M]?*���<�F�E%��g �gcʉIKւ�[�qa7d�Q���f	�v�
'ù��@�%)�n��&����5�c,C�h�����m�cA�e�f���H]n���Vp�/��f>i�������Ojl����BÙ<�!~�wlLG�QY����ј��U�^�GQ�߳�s���PQ�F��f�P4(4�c|��t�z��+j"h�}�{� 0r$����~e?n�7��Dh��TO�]��Y=��fm�����w_�	q��P�5�Ҵ%���ܾ`��J��n�I.�k��zӒ���T���x&6�Du͖iD.�¡��b6�_���@
S����l������*& � 4M�	��J"&mXٛ�Y
R�B|w'�
9��)^e��jA�ݿ"�G��6|6�  �M���rn�|ke��"|�%*	��E���|�>�ܗ�k��gq{W	���dƼ�����ď��+A���G�'ႇ9�K��9n`a�G{G#ܼ��5!F� �a�k̕��؋sb���	�O\LHܽ<?��hK�9�̢k�Fqi���] �.ƆC��x��k�ܾ�y�^�	b�APF�u�E���]�N��W8X~?[1��M�j'����jTYulOO{Rg�\g.���[�q��b��J�d�Μ�-U�zmh��5:J�H�v�{K6Y,m�& _9�v�D"77E���0+�&η�}�B�3�E�YLm�p/`���{QȂ��R�[4��Q��9��|����c��~�7B�q��aˊ0Z_;'���K
|�V�>g�����(�1R�/�����3��}3P'�3Ɏ��g5�����������=��J5��{(ʷTT���i[T<i������'W�,��ʚ�L��� Մ]q���N�g�2n�,���v��wp(-��S��vWȆ�ށ���e6���
'�Ւ(..���U������yv&"��p0n��Lb�n��	`|pC�4ߧ~
�q�N��3*�j��2��nQ�~�<��5=.~ص�N}�y���o!�X���'�Xd��Ѐ/	�ˏf~Os������r眪?�.�&]2Y[�]�M�+�5ʶ���r��"��U*�ّ���� ���G��bG���������\�y`�!�#�>j����y&��mf������}��-Q��z�yM9@Օ6�����N@�ګed�C�0�6C�A�@
<���˴���A�}a�4'X8���	(B)[��[3���e�;��h��H�6��_�:aLlig<T�Z5���6�s�a��vD��r4Ћ�=���F�_q1�7���o�J������ǎj�`G�����
R�a����ZD�vE�ҕ��#V_
z	��5��Z�-�K�����7D�+a��j����Ksr#����?���i�]RI�ܦ��{�H6᧺\H��D53�xA��F�>�9G��uW�&��s����r�c�U�/?��O'1ͫ~�!�'̄�'7��݊����J*����D���.��ش$���L�}8�+Գӱo���d����Ԡ��:���=D�Nž�ɭ��v�+^�Jǳ|�U	�d�v	� �P��أ��%'�kwˏᖑ�"A��]V1�=S"���:�;��>�&T��a}.���Q�����L�##�y���=��ϐ�Cgb��ݤ�&�Q�$�K�ⅹ!��I����@
���QT��\op׾Vum�[?Q��
%�v���Y#z����OL��hy� ������]�|8�\r)WY!}V>�����6�@?Ă���h�<f�x���m���]g2g�BK�&�JOa�n��>���X�}RP��mka���bv)�PM��<O7��,W�������Pȿ��,f�v���F�N�Q`��M.E��p���K{��� m0�A�����adjt'��ѷ��3V��A�i����yI�H�:�s�*���H�{�*ـ�����3PK����T�Ή;T 6ޡB��|����������1�lMV�j[����3i���-9�)_�5����N(l���B�V���=C)�[b �v��4�2^��q��c�8`0��b%@8B�ߪi*�u�1!�zȺ ��OY�%V�0��j0�B�e�w}:V�u��`+	�i���e�VL>�JLK����\	�H�!��Mu)[U��%V�n�,��FGT�X��:+)XBeƓF�e�4���F�`L
�=�`��թ�~/��gڗЎ,����x8W5����<��0��<-���B6��!\���B`w'������R*�����;��nh�_Jbb��:%0����Y|
H�rB�v�	�&|�G%���A�y��
}J�g!�t'�4G�iNǱ2�K���)cn�q�،�J���J�G��F�|�yt�����՟�����X�=�%�ȣ>�>�Q���ΥeV�m�S�1�oY4�D����3���A+��!��sO�){#;�=�`�~�iR���R�M����^�Γ}�tY��Q�����Ph"�ԅ��Ǣd�קM������� �O���B�YWS��W���Ԙ�� ����İv.��T�%��i
	]\] ڈ[�N'�e9_��==3u�����Lɕ�sk�YY��ک���P���I��9��1�E���47�Mcb�q�:<��4	e�4���?)�v�R�߉P���8�g}X��ya�}��ƎBI����yY8"s{�Ae�^��	Ʒ���B�w�W�"ۨ��	J#���a�d����<��:�~N�cٓT6�`>�0�"|%j:��D����G��J̿(��Jޥ�z���iXW�J;��x���u~K�#zP��씽?|�X%�;6b�nk�.���%�i�1��!~>:���. � ŋ�^M�dbV    D�c�e�m �����t�ٱ�g�    YZ