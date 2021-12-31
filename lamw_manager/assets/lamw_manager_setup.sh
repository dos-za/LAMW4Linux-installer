#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3726048966"
MD5="7fe0602daf13e46501bc153e9e0ad184"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25816"
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
	echo Date of packaging: Fri Dec 31 19:30:21 -03 2021
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
�7zXZ  �ִF !   �X���d�] �}��1Dd]����P�t�D�#��B���Q[�!oe�r�<V%���D���� �������2���B2Og�x�A}Y�ϕ�O	�4��$*�����Opyt��=u}E��? !��嵇�a��gʳv[>d潛!�cq�����I��뎆�np�ht�vƴ�*q��z��H�t��AP�0��.-_�#xX�����8,aGÜkbӫ�:	SR	5�aITh�k\������t�cyf�K;U�;)�Y����P.f��_��Xc��m�.�gHGDc��$:��F���;751���<�d{�#� �^u��6����j��-O�q����i����Hሑ����T�{HB��x�m�+6��|��)�3R���!8d��m%dh�Za�<���A�*�1ٔv�XSx�ן�D�#� �G8���(tL�Ёc"�âP�6���z}m'δ~{���T�/�u�[Nm�E�~\��k=���*�Fx�Fb�Qz>�7%����M�v���+�O�(@���*�Խ;��G/o�.���^�8'e�t��&j��^��o� ݴ���K�rp�N|�~O��%���7�`�$C�Y鬸􄭿���[�EXj1_�W�WD���4%�}��}6�Y?��:���O��C�$;�����qZ�7o�i&�S� n�S(\�������[^2�׉8��9Y-�c��I��!���l Q�����x���"uT�X����2��(r���_��"�����(k���Ͷ�N�#1��?
����\�����Ln5�o<>!����!��"���"P�V��2X�n��k��C_��к�%2_!PP�7? ��_��y�	���*�l6V&I�ר�^��w=ܓTN2%]R��u5�����������4vQ$x �s���Mϭ_@�&^�	�S���O��ʺ���oNY�\�g�X���xډ�$�)<7�RҖ��8�1 ����P!�Ѣ���#�^��o�Fk�C&������D�Út����{�bmvP�^i����DPN8>!��
�S9�6������^!#"v����]����d�B���<k@� ���_|g���,q�j=����_�l��{�Сh hjP����2�5���\�~�t`���|��]�����'z�sk�|*}�i��aȟsp�׀ݚ�FBYU)-��UJ��s��_�ȠR<�@9�J��%�!���;�]�bvu}��s*=+W�5y^~Լ#�*��ss��4$""��j�f��[��Q<�¸0�P9lk���aF�=���>S"h[S�`�n��C���˨}'*_'+e�q]�j�4%Q��j��0F���N��<v&K��l�-`�f�z��h]���y30x�N?C�������r^��#�'t��۰K�AN�2��5�8��]�'���Z�`����eߥ�L��=��qJ=Bc��c�����2k�߽��<���0�2N�s�]TkI�'K��EKWIC
bL�'e�`�$u=*�:\�m�g�1�Y�n�ܢ����T�,��2&K�Q��YOaNnB�r���:m\1�2�z	/�~a>tՠ
�ڌ��Q�YD�{���������Mj�#@���{��j��\�Զ�h9uKo�s+d;:����jn���+S�� t�H�n0�-ii��� Pb����6O�?��R�n��U�Y4�[臺��.8�K�0G��#�_O�46��Pmˋ��-�H��4��/��V8�k2�uKE@F������[0�\x��|������-첦`ֺ�9a6��B�$�v���$/YL�V������X�΁o#Fd�:Rp�_�ڽ5)����A��r���ۨ�s���6�[���n$�q����>�d�N	����\�D[���t3�C!{����}$ .8]A`�K��tb8�K"�� ��/j��^:�ʧ������k`�]��LO�jey&\���e]��P�3�;[��8��w�b9t��'j��/����t�drR�gdҖے����0��� �s�ugf׹�ֹ��x���Q��ʎZ*ZN�t�?���� @��Wu���������ð�D��k������z�{UW\��� -��]��9�u[W���֬/$�_�O��h�,�tdC^PP6x 36-/m!|bCX[CF<��s�ŃO
[��?��=��;���Q8�\�]�zQf˴d2E��(���l�-��M����iq-S�������\��(���E����
�/Ƹ&�מ�X^^۴��I���tFt��8@Gr��)\ᶭW����a�FG�� �	�@Zm����^�N�0�vP��;.0���+sAmI
�����J��I�_]3��q�\GC��F,<isۭ���V�s� �
��RV@&3ᓢ3%���D�tqk#���6��l�"�(#䫣z�����b�I��2>y��ѱ@
�E#Y�����L��w�2�#��M�Na�QH6g��r~��F=�P��n��H�lB�ܸ��&�0��Đ�y1;��o�N���@�T�~���ƹ=��fu�?���!Ɏ�C��T�Hi�T9�����3������C���].D��=!���o�.�x��|Ҕ{j��a���4%u9�wͽ �n ��FI\*v����Ƙ*��y��k
as)�����h� p�;���'pQ���ܫA���ZNd�t�n�@�J=b�ӳމ�3����bݹ�8;p��Hdd�␖���7�OXe�v�7��G�_��'GU����%�6�1k�OY�*�t�ТV���2'6X1��N�ZRF������� ��ܧ�m�:�hV���O��F]QSV���b��0kh�׾T9��	N�}� �)o�?�����g�Ꚇ}�yR�W�N�g%���uB�\�9���v�4�р��	�D3BN�$��@#3�i����@F�1m�0�e�Q%o*&R�_"b k�S5�)y��Mc+����#ؓ'�e���^�Z���b߾��c8��տ���iO���ؑ�^�~3]�&�c������v�gnG���d���0���x3o�+�W�Ģ
)�
>_%��K�L�%יn�D� �Σ� :�o�8�}��M�iHA���	s&	�.�3������*�k ƺ�&��yvU�ObO�?��� ���NH�(n[�A�б4�ɀ�:�mM�g=�8���	9�J�+���I�VK��Y�ӓ�3�'+"�� ꩕ޏ-r>�,��c���iw*�o�Qm��nî�|�ǃ_"�f|(Z�d���H�Ygh��+e�Ӏ��$y��@�Q��swE(�I��Dd�=1���2��f��ۼLQ���.�g��dX�Z�Q���]��)AO���N������m0DN���4/�ؾ�Ɔ�D{�� ���s�Kz7U�'|�4o��3Vn<�6w��j|N���h������U���L�x��i�NU���+��#M�����`���#	xD�W?�h8R����^�@�_�5i.�FƉhDm!"!�S�N���L,��&��ǟ������V�}4���N����&UK�h�}K�+�l��A��z+s
!!�qPc�O�qs6Y����F�a�Y�z��*aW����*!}s�y�k$�
{f�2P*ٺ��Ǟ1�;��~����i"�	7E=�����R�j�F�z
���!(�6�_���" Q�\y��OjQ?Ķ&�'��Q��$�p�%�/p��(�����R��FȲ��$O��]%t.#���Is�gS)��F^�ӕ��ׄB�A��]d֑X�oH-tW,��`m�{`�<� ��앱�x-ѽ0������X��e[���������oجnʔ���w?�?�����ӤX��+�m�e�e2
��~=�g="sW"��mW�@F#f�kq7OթrO�f���Zo�Kn�F��L� ���?����W?C�m����K�:/�O���ṛE�Lۄ� 5��s�!GG��[��︢�Q��^2�A:�����a��`J�[�p�k|n:������,�ן��].���ȏ�
���U���,��Y*�M�$7�G�]�T����rL5��&w\m-�K���EyT�f� B	��B\ʎ�^�~f�ᝉ&�S�LF��xL���t��V�&'2�L�	�3��[3�j,^� 	�@=V�rp*�����o���8`m\m=S��)bo��0""թpnՍ �!�/L�6�x�M��n�`�����@/b�K�n��.ɢj���pt���uD���Nׯ���A�s�a��A"n,�� H
)]��M��)��]�����#��UQ��O7$�~\`��ِ=maʨ?M��}������e*�����%��i9��<q�^���c�n�R�����n,y,zT}ThU�,��26��8�:�fme{p����^\�*�N���Z���ʔ���Jpp��^؉b���&]P@�y�s�P?�s#A�z)�+�kte��/&H,-��ʿ���E�Kׇ�=f<z'ğ4�>�WAʻ�r�+�Txp�����'�b���#����J����,��Am�Bv�j�{���Wԏs[[��6Ow4�^�ѳ����9zZF	����^�2�����/*A����hX����Z���
e�I��cq_y������� �j@�?tԡM�~X}������F/�OK�}�I=��(�L*'c��,�#�i.�%@��OC��2�}X"�{H�f9��"���(M幵���2r�l剕�s&1�U����60��/2�C���2�s7�wn9+^#��?����a�2դ�aĀ�[F��* ~XQh����ꇸ��Lt+K,V�W�)Θ���ixi6e���B��A҄�N�-�Y�x
����5�0�w�g��`Ds��	�Y�O���~Y���5�(��)[�.O"(�.�_5a�>H��9s"v�8��T�D��`��"a�w�� �$�NV3c#�I�h�����d��%6��	�gs�M5����{���69 ���O��@%��ӏ�պb������$�f��
�B�K�k�R���p޼D���e��4��2����&T�U���W6��ɽ����d�'���uL���5G�TH���j��Z�}7k��-@�ڼ�;x?D��8�&�VA�*}HJ�e��h��D>���d�0���S�6��,�� :�H�hp��\i���p$��N�.q�o�~��};h��0N���y_���K6�k�.b��t��rS���n��=At�(4\}��W`%m	d��������,��:w��iW;��@|������g���A��F�,�w~FV*@#��Ф�裣�VYV>�ć��R^r�{I��C�+���?�{)W�Y���W��D�¸�k}��IYv�\�99��8@�Ԟ<�gP��J߂R~���!rb�
����+ _
��G��4Gi��lF,C&�^l���C�{9�HC�m+�f2{J%�m�C��Vk��������kW�+�����_�P���DV��.�t����F/����5t�7ѧ���uJ&M�d� ����-�%��.����;�h�#*���Ї.2�չ��_$M��h��S) ����U��bTӛ��_jD��&mx� t�[Z��tP�h�oT +����E:c\(=�u�>]#��ځ��Mp�2����A ��@o&:�!F��
-i�;�}O�f�;�G����އ�^��!�aGLQ{jx872 G6�e$�c�p\(u�z�0-��ة W��Oa1��vd�ٖ?ك,���L�Q�~��� C����	�������A�$�U����	�&~���|;%��z��*�)9M�g����R/��<_�bZ�z/�ݴ�s�<�
�̢�˄.Vd�K���nR��ʞ�{���j�|H�U�h,�Qam�� *���*d�
:�f��ˡlT��:y��U w5��-��P��:� .`mz�8X��B��c?�Oa~� >8�H �-v<����.��1^Ş?�޵D��N	]�D�5R�}��)�D'��	 (*�fy�ƴtm"�ID���N8{aX$��Gj�&l��Y�4���A��.&���Bi���l���"��^�Zt�]�B��׏�mu�H�4���X^�еh�Ǎ��pc�VU��јʜN��W�1�׎�Llu�s>CQ�ڪ�(g��e�.0S�;*`�̂�	#>*�U��(��zXڷV�˕O��'�!�sրY*���!���!�d(��W�T�^6��� 1�Zu2���l�ۮ�k�ABJ�"&�䛍��x��a���@Q�fw4�/dr��y:�@4�w�/�Q��~z��ll���rD��k�TJ���Շ֚���~]:,�znj������`	�"��;��`�/�!\�&ڸsN��H���g�;Oz	Ua1~D�Q*��%z���Ϊx7NEp�~o�a���cb��cA��.^��;�F�#��I�>#|Vq8a��MJ�vHq��`s���C�z;�f�4۶C�l���%�S�xХ���z_R�ëk�,�HZ�y�`�j("ʰp��ʈ�,�g����$�v�Y����M��鲤UM���e��]G/�bCsR<5���˺�P�d#+�����c�sx'�^\���"Z�z"W
@/��E;��G�uj`Q�a,z�����:uu����}m��4uq��+���n`��7��D�,"��X���:{@S�����I@sI�r������.�&�{n{�_QjG��TP��m�����b=N��md�e�ԥ�~<��3�����P��y�}=��"~}Y��� S�Q7
	�s�������$IQ�|�ܞD�KP�v�yIql-�Be���"���0ͧ�Z�#�KB���%۶)��E�vs\�R&����P�ș�a�5эm��>�^��p������t��^�Ph����X�ڕa�՜�J���l����	�F5Ϩ��F!��~�t�RK�97o�ȏ��U��Ҿi�<u���p����Iؑ���E�R�캓�tUZ	�JX~���}�t%��fd������9$�xi*��[��e}#t	�*spA�߻%b��B�u5���_fƟ5�eپ6��$;���'��|E��&��]/�l
L��W5�G��8�a}�:}5S����<�Ճ=��m
�p���Q��g

ŀoV�r�e��*}��y�I�xa��H,k�M?e	��CR+��S�5�7ͳ�y����c��AGpո"���Tq[��H���+-KWY�x�3���{�{��~�y[�<��h�)���u�v�o���>���u�JP X
�~����ɕ��[��1ð���®YҎv0F~I��gk�v�o��S�Lt��"�K(�s��PK)(VS�6Q�Y+Lb�k�#v�y�q��g�.ܰ�k'��~�5�k^����Q�4�FYb�u����4Hb\3�PcT���5���p �T�����S�=���kK�q(G*}�\la5�{n�4� �F ����s5�=P�!�ۿF�1�]�[�ߓ��\�{�������`<*."E9o�y�������O�e &1]kgX����=h	Q�~�\��-�YZ,٥0��9��nZ޻Ʉ�j�0��kl�Y���|�9�Ql�l~`ф��ON�T�K7e�b�>rll-jq� Z�~E��\�Z��� >@�I����bY󵕼�G�K��tC�"D~v�w&�5��8La!m��쳄%��V⟠::�����(�1�(�׹ݎ����̞���c�zYa��<~k^��W�����[�����9U����>�=sӅT����>d�<;�;H�sY���\D,4����Ǧ�ub�(j͟Rχb��A���+�,���L^!�~�R�KvJB��&���gp+��l��"0qIB��qv]4�%�h��,*❰ޜ�J�����sW�թ���5ŗT��N8�~L_��)Q���xJ8��Q�bj4��n޻}M���cr���3+M���yB{ �Rʃ���a��t`���L+-qy��[*�T��ަo��>�0l�b�s��s��ic��o�?Y�̄��D.d���,�m۾�ja�=�W	�Q�$��{J&��Ln��d�lqkM]r�D�F��^���G{ �bB�ϣV.��x@���z��ak��z$�ks���|�y�?��0\Y	4>T��Ҹ-X�V�T�ɹ��9j��sr��x�+�%I���/��tO�ب�G��WR͡1ܲ*H�|u��way�\h�&�P�Zl~�MꄻH���d�җރMh�ŕm���h�Ќ��A~�K���Sч;�M��N�qL#���=Icm�98��z,xj���<7ú�l�U�b�����EN����lT�$jgt!��\rS[����i��+��	L_� ��0�F�J�1a<��� V��ؒ��-[���-�ڃ�D��OV����܁�r�~Gz�@�\�.���'dY�֨J� ��wr'渿
IЍ��%Q��W�@�C�v�ZgZf��}j=M9ks���*�"VԺ? @�~~zN�����B��	��4$	��Й�ca��"��2��<M��Z2&�!zI]���P���w=��9���2���{MU�b�/ʖ��\�d$���8ۗa§�@����jw�r���a
G��u�/z��f��  ��W!����������D��띎��O��2ʶ�@�X���UMZ�䣊#N�8���;����ʏNW-��i)�ݏX���&)D��r�/�-��� |�|$`�S �>�]3(R�ݞ�^�T�#��6�)�M"1a�AJ�ɽ�<߇�A$�"Vmr^t��gc��v��\N[�&��6"�"#���`y���RөӍPFqQ@���>|�ڈ����w[�c��I]�'��o#�܃��y$�K�˙�aR��E_A�=(3�X���/��(ٳR��zR@<���Z(Mz�c���aeg��-�ܪk)Q#m��f�Bw��r�Hm�rI�2�T��d��*D| 	X�J1؊A �RT�(J"�5-����?(�Ue��:�)%��L� ��},�C�6����RL�p����:�V  2!Y�@��v�EK��;�G!,]��eۍq�l�w���+1n��Z��������jH�70�l�5�`5ʠN?-b�`6�B�H� �8s��a���i�������v��j�UJQ�@����yU�Dؚ�}vO��z�����9鐹o[K���='}��5y�|eD�/��S�A�y�i�*��͙RWD5P�͟\9A!>��S��/=P��6N�B�}��`���M3�w��1Ug=�/q�	2s�ۮ)Jq�]^be� ���0�k� ���I�{Q{z�M���~e�����3�85�8����O�U?0������O��J^��а���[����:��؋&zO�)y�b�� �QY�1c�9\E�ʬ����~<��[�!1�K�mi���P:�"/��%[���Iw���P�%G���J6�ĸ��j��h��N�H��tA#��QHߟf	ZG���q�f�������)w�#��{�T��m�`�QF}�2Ơbu�f%�R#��#=M/���󊤢�RE�ݷD�<��Q��h�"���k$�D��s�A�	��:�1(��oQ��R����� �bc������"j����s.��A���L��)R�MD��d ��K�*������w�_��c��R�i��g�6K������<����v|p;�Et�n��6��#���6B���|�/ ����T~��B����|S�������ޘ��d��py-�IFm���[R��t6��o `�C$�R�I���V����ǨGf���M����H5��́��|�2�ܩ��u�e`�Τ�"(a�SҬ���7'l�4���Q(��j�]���\�c�=)�w���9����W��3���O�� �>�aJL]�:�e{��F�kd���	\���aV1x�Z!@�r�\
#��o�)@��kBm�O}��z�ϖ��� ��PX>��b��~��A�Nl��'�<�}̍W��[�j��i[��s���U�n���8ҍ*[Iֵ �!����z�˃F����9�eD����8���0��X��ƦF;�Kn!�1s)Dn$M�p��zn�Zmh#t��4����E���(O�j�?���7\��$����f��#/wy(�,bh��b|$�V��W�����>�`Z�9v�Ҁ�^N4��[}��o�߁NoV'F�F+kE�|<�k-��t���na��)��΅j2���h����hz���9��V���毅bd7��/ѯ��A�ه<Y�⩑F1�MHʻ,D- ў9�۠�O�n[/��P�}]ȅ�a0���R�v���TxSTf���sR�߇�#��r9�k3��ӹ:�;�'c(���p�f#`̷tލ_i������<�lpq7*��ܣ��W=�85s����vs!�'�8C4�a�S�[/a����L����eup%��gVe��h�n������3���\�OVe�_KG����m����ky�+��"��8*���쉚Alu�7ڰn��]S��)@Y�T$�z��))��GY�{��`�#�a�������J)�[���<-\!�m�+z�m��Ç���<|1�� �0k*�v�)�f�БZC�����	����#� ��}W �-�U���>�>�������� ��ܩ	��B@qo=�jQ_��h7�M��5M���Օ*_���m�j������
����B��L��о�~����4� �6�G�ݲ��_�˭����3.}��h=M���'{5ĩ<��Wp<ďZ<���ܺ�\���[e���3�$U�"rb����J�Z�$&�����G��0f�}mn��	������$�Fl��3K#���u�&�lPcn��#��4��ez�\����[�����ċ.�7�(a4	�.�M�c�ljurX6� �n�:�}��}(��5u��h�u���Ě�&D�[C����V�cf{���Bx�eT��]=����Z˽R��e6aթ��8�sXK	#��Ř�)x`4��+	�AБkTK���0V�$�p�U���^^�H�Bvo3'A�Ķ�r�fd����z~���DE����!F�n�'�)��ܯ����Ru%�D�ة<�5�{Ua���C�(Šp�����t�������M�(0ˉ�,�Y��M�,��c��2oҽ�(���C����
�8���0����~��Ψ#j���TkE���"�hZ*�l��1+�pF��HB�?�'l��m0<� r�� Gh��L��l��-�3����pǢ�����8���]�p�[��x�4��՜>ռ1!G� ��0�+�hI'��r�1	0����<��~C1(���a0�[o߂��J��T�H�y��D���&��&z���;�4�yW:��[��/3d$��Z���i���}��c�-^[�1�:|m4����ƞ��gV������v���9 wDdER(s0|O����\W1dސM7�ᧉ�+#l��U�����b���˶����b��py��4��'k���1j�wrG`v��8���zp�ү�U��*�<[�����%��bj���_�X4���5�C��.�A��k��-ͅ0 &%yV}��,0�bh�����\�n/�(v��� 	Ϝ|`Vmy�F�ڨ�R,��]��]͏s�쪄P�,�ro�s[���;.�ش���b{4�#k�4���0�@#�{��#�4�R(ol�Q�RK�S�� 擅H|�Y���?���`Gj-)1�'R<�����` �e�J��!��yH5N��yzm���ڿ'S�pv ��@�܀}��n�C�*�W�1�b���Q�'1* n^���u���y���X@b�G�oq�I���#�)��j�"Iq���){&nڧ�����h4�݅Ť���Y��$����e]���i�)úT�W�y�"�7n
��n��$ћL���1kI|�k�/�HU���n�Й&<�-��V����K��#�[�(5q��RR����Yo���>kn]�� L���oEN�A����"�l�d+l�+�yA'e������c�g����,�*��Z��>�(���0�\a�/I�%)S`�h%��;�ǫ��
�{o���1^]@q;��K@1�dZI��Ҟ(B5�Y�N9�u���l�rz�bt����dO��*��E�I����F �i�HCgI�
詺@�����j\�|7o�Z�C����>����rh�n�N<zDK��U[h�~���9G����z:<H���d�<N�`.Ď��SE�v^���ĩ͌��s�\4~���F�?i�����+N�(�����i�3t=EP�	���>ѻ���g٩�nޖ�;�M�au�D���`/�����<�O%�N�F>��|p��@#�C��{�ܢ��U�h{=�r���4Q�,� g�t^�9Qe.՟��yM2���lK�P�Pi�*\u�^!l^�9��������R`���V�`L�vP(3o�Vr]i����S���G��l�QP%W�vY���ُ�X5Ջ�Q��'G�}2SL|�9�r�g��3!���B�*���[8�� k1=B?>���%:�}�۪�*�wǫ#�� gs嶣!iS�񂌗k��b^ghۙ��է_-���lQ��阛%��Pf�l]k�p� @��u��or��3�����J�>V��U�|���P�'㛫R-�W���o��^)M��x�a���V��C��!��>J������j�=�gp���`�R�ѣ�!"�V��F��`�r�Z�KZ{�дKy봉��z-�)pISw��������9p�M�e����E�����TV*AP4�h�+��%+�6������[�� ��GO��1C�v�����0j��Ӫş�V@ލx�l͐���>~�z��~�$�V����y����{4�I��-���P|k�錤ґ^�j�]���4��g�b	d�Z�ڕ�1�7�k�	st`��&/z{*h,l$	�{5��,�)Z��`�3������q>{��X��:f??~�G"n��ό�-���|��
9�z�@���s�O�Rb~��Xx�t��r�h\����Kk��Jͩ��®�4w�k[�(⧕��4����F�z�X��'LFn/s��5k���Ц]����䲥��L�T�l�9�B�oKM	�ևK��]�α��(�� Q/�a�0m�B�������l�P�����sT⻷S�3fՍ����'+�o��w���%d���`��t��|�~��M2^O�'�X!c��}��b߲ѦJYc)7Q��\���[�TiE�{�S
��i��J�G)�G$�o|����8�ݹ���b����'�		D%��@B&t�7����zn�b���c́(���VQH�kC/E��� ɬw7�XD��T��*S���� ����_d��'�#��Z�M����"�)$�W����{δ&�=q� ����H�l���q�q_5�ot�}��G	q���m1�����y}[����*҄QO3���]b����3�.��v�l� � p�G	�p*�cj:�2yĀ�hB������I�~��ޕ�D-�d�5���~�V�t��Ut,t/\V ^��:��rF��B��_oJ�����Q�1��|��c	܆��<\�Z�a<+�ÏŽ�At((�a.�D�j��f"+R��6.A�,��v/2ݞ���h���`�Ф�/��	��G����cf���S�Ho9����w�.�/��Љ.���o�`�akƯݑ�u�p@Yt!,��G��>�<Q����	-xP���:�W==�-�*p�t�DP� '�w,!��E��q�;a�Y8�x��� �ժ%�Ϝ��ܛL9l��_��q�����)��^�qx͜�? ����N���I4��(�	�*Q���T�H_����;tnĦ�|���z�T�ﭭ*�٬%��I���������8n�
F�4����T�0�s�G�&;J��K�,�b5r�n��Z.#�<�_�P�SWW��{|Q�~�&X�HxD,ٍ�9����)�Y���S	�"�`J1�
�1�������}�b�l�MU��V���3��d�a0�\V
_V�&��zх N\Z����$���"�� '7�U�V�:�٪����ڛck�>�N~��i���Z�4*�MN�9�7���� �zo��[UI6_�o�qa��:���JEqd������6��<�A�Q3y�u�oȀ=j��V<4�����}��[|ѴL[�p}���m�2>$b���gU�5�t��μ��[A��͗GS�PMa�֞��޽}�]��G����[R!c�ۈa�s����Df�O��!�1��� �J�/��꽯�	/y��	��|��T�9/Cz-��Ia��K}-�9���$U�I7�@���3�p`�0>|K�3^*Z~��1�%�hj7����LԔ�s��_f)	�=��E�E5*A���@�F�z�_wT�o�pt�� r_f�,L�@4�veuUL�Hk�Փ�_5�#2�e[](Pg=!�ծm�k�
ӤTU�cL���gl2����ݼ��tjf����nzKDme����{	��k�������Ϯ�v��� 
�k�&�6X{f@E�����g�������1z�� ��,�f��7���0c,�R���KkP�u&�f��0�=&�����)BmO�U뮼��� d3 �����P��~��t]��!I>+q`���#����/�,9�Y�c#3& %��q"����D�P�W�������l�w��\~�U�9����z2�[���+�U��26J��tI�
�e�k�kB��5��IIN�-�t���}�PA_���g���*�'��y�2Կ�=1�ڛࡉ�O�V����xd�K��8�8c]�xK�_���As]�ͤ.�s��p��j�����	���i��v[#0�-M�T�5u�3����p�	5PE�)s��P����ՊA��H�#k8/<��ks)�,!~\;l�w+��|>�8�3��;4��b|�Ť�"5aU&i�9s�Ԛ쨥�ȧ�%�^o����whf�c�x��h9Z��W��̼ntl�+��N��*a��z�hGކ��z�oW��"�Lt���} 4$,U�d7��1�]]a�/"W})^�4y2Se�=�`��Ჾ{~n0����Z�W-��C9���V��)����ߣ.������x�g+�*<R*(��I82s�<,a�}�$�w
�sX�7�j�i[�PtOĺݕ0mz����!z��fc�L辍��}ȁ���SX5�Ɵ����G|!=I�'�����)�4�8��ɔ�2��%� Q��r�R�(�;Ş#��`rAA����8��g�N���i:w�U�ţky��i�����"$��a��k���OP<�ܸ,�+NK��D_/�n����`��hX10±1z[�ەҀ�Zt���t�1��G#:�D'Ӱ� -�I����9���G$cV��� ��®�8-���2a�'`+>�+��F�|��`���y�M��N�w&����W�ߛ�?��w.4>x=���z}�'b���v̌��q�e�t�3��4X(��;����܈
��k�H�N�Yd���M��;CpJfFS'������6B�o3��"7�Iܿ�I:J�砠c�\{��Bv����OFA����"6ke�*U���m�H)l�V�����m�h.!���<wc�zE�_��19R%(���*���_���#�^�o#&�9�@Ƅ���>{�ZK�Z�yC���'��?D�l՞��L�(|�|�"�t��M@� d0����\/���E���|LS6�85������)6&r�o�9y���6 �l�i	�k8����K�Wҕ���u�?���OE���H|�Sh�,�w�v����-b`1s�r�zz����?'���Jy� ��d�?��e/�a��ѥ���#���~&:�	�����Ƕ�GE�@�I~�����aJ8���ZoU۵3ʴ	,������2���;��՟��.�w2$GM9�&�4%^�픠�3���m��m�J��9���������"ž�l�5c��"�	Z�*�ɇ��F�ku����o� �lA�G]��݊�g!
!�h0�����n�R�9&��)�4U��l�c,Pۓ�س/��it�����2��#����Wk'������z�����q�u��B�t_Q�v�y ���!�n*�����+�-�����\7�v���4���7����6��^O��35�"�JB�����E��a�g�#��DA�ej=����y�,��<��i���-h��TbP�N˾C%����<c^��y��vd����_���he�T�wd�������p�U7�]I����m�XI�����Bu� �B��AbZ�~���7Q��(����|�!�MFP�Z���{�I�s��l��*x����ҖV���*MҸC��/ٜ=|a.�[N;S�[��pC4���x-{S���M��2
��+�H��ʘS/����Q�A��(T%��/�d����q���b�u���C�k`n �?A��x�F%R;�l �53t6��#�:	x�w��@!K�7�݇��]����]��ױ+�7R���yגn;��k<Bu� �ş�Ŷ(_�e��?�NC@�nIk�B���F�1rX,�G�م�Z���﫮3zn��%ǧ���E$��*�|v˖�4�Y�J@�w?�	�ѭ/ *K�$��F§;�����0�	��r�r{z�n;����--�N
@��
�
Ȭ���B�aw5Po�b�3AEz��X�I��M.�����-�(�S��n��(r+��T�:l�z/Ѭ^jCw�"�JoŕQ`ꇞ�AB wgD�����Ц�I���DP�����ʿQ�"��X�ˬ�C9>�{;�+R`m�6'�̦]ݯ_b$ŨRQA^�&�-O�K�����I��Bf��
�Pcד���{�E�h�0��6���,�P�
^F���6��������,4I�#�8y��nl���<��y�#۴KI���_�X����K�6����ZA�Qʖ��۵��xMʍ��f;�Ay}����?O���|��ցd����������^�`e�n�.�DJ�-X{��Y�։j*JH\�CMTY�w�������:	���_��"��Ѓ��6�Έ���-i{�DU���a����+��}�2��ڨ��4<��**��J �O�����ȧ��|��oc��._���-|�{Z@����J)�"��w�J�u���l�ؠ%g�����зښʷ�Z���V��-|�f��1j���}��8x����6X�]!�sGE�J �*گ��k�&��� E5k�����I���D�I+�9I����{��&	��yH��f0�ù����l]���3���1�&��<��(̹D���sޜ��#Y��I�{;�p����+� S`����F���w>�n�߉����W��A�f>H��\��K!c&ӛwO3-�.2+��Dg�I5�[�J'n^��Q�~�7����hD�������l��,c��p"����3J�c���j�r".�i�
�d�����"7�;	ƃ��,Z�}a�Z��X2�c7��QDA��M6	���)��k��1��s�'�Iz,c��
�+U��+����,�6�QDzwTѣ}L��ܒ��u�pn/=#4�����i����t����֔E^$L��gP}�a�x2���,\X�/Q)�:�n3��(B��%�1,mX�Bqm������Є�~���	ܗ�cn���ЮvZ~箑�R�m��q1+��"�)˾��8!����m��q��	V�{�t9���׏�EK�w�s����C�<�����hC	��;�U�?KS��Ǳ�8{���U���9�Tw$�u�773ty��� �ŭ_��?r#�?x�{�ͣXЄ�
����g��C��)�LJ�}o�����mJ�^K�:��$4@PS9x�۬�^U��D�1��d�E��v��y�S�(�e��lE˺t��hA�l��1W.&_��L�D9�2���K�ԯ��z�nm�]1X�T�'���W�YN6~X��E��0K��Z�Ɩ��9�je�k��!ۣ�$��h�� z�8�Ly�9�w��J4��+�����(�4���6Y���΢rG6҈�[�V�ֆVH? >dq�^��hg��"}�{�ɪ�jl����:���h�u��с�_<�E產Us?�$��֔��_�����V�n����:Ya��8��KI]��DU�ґ+7�e��TY.m%ʗ��r�[��!B`�1 �c�J�u{�_`AXH�s� 2�觲P�qvѕh�{
P�����ߣ��"ٱ����x�i�S����vv.l�a�:r�E��Χ 5X*�G�w��F���(�����9�i'��@[U�|<GܥC&��r��^R� 
�P�^�\�wM����H��bkA���L,h�Ɉ0�\��y����+vg݈m1ש�f��3����Zt/C�k�Vc1:�z+�q�T�ɦ$���I�iL���#���֔>w��B����mФ��=l�(+$�%�->��BȀ�|E���z~�;�F�ѧ��m	�#`B������3���WB�T�[O��� q�`������X����JC��4[V�ދ��)�,�^G̿5�4�X﭂�~�֔�r#�ﰬw���/��
�p��5߹��@6����FM�7~r�.���������{���t�6�)E'7�7F�p4(��Y�2o4t�T;��Q���t�fs��2��h�x ����	s`U2> Zk� ����Î�
�~�)�`��]aW�����xg6�9���k��$���?������#��l��[vo|}z|,3��+÷��s���E���\v%�g��b
ֆ��2�2.lm���#�b&���Ty�����v�,���w�|oD�Mz����{k��
��Y�Us�eO6���+�ٶ.°Uk04�+�*�����TF~�66���B�>.7��Y��|SiK�9ZdE:H��$�;�<�#a�r�y��gn�d�.`*l��_2�5��(au����<�k�.'��,=�σ�20OR铽��/b�=�Z[�X�G4���lP3�����(�B gR�����[��F��=D# (1�ZH��G2Ǿ���-�F�|�;K�ə{��K�v8\��:��EQ=���v�<Zm$;��_��F`v�q+�[��Y"�*+b��\Ǭ��w#�� a�xϏs?Շ6~��UiT�.��������m^��;�����~��1WY��������1�\qY��y�����k��T��G�������r|g����k�}}� Lz�;��q���*�'9�#�E�/��c[�PM�����j���e���m=�_��L� ��-d�ɣ��!��h�LZJU�qKY�\Z���5_~���%������.JY9��]�f����	��+P�V��ʳ��<��M�x�N {A'�V�!>$��FcA5<=�DÐ,AFe���GB�kBdy	s���i�_�(�IBp�L^$��k��Dt4-E�<ր����"�@�-���v�\C�M$��^[� ��|N�#WEjP3<#�-d�'��x2�Z����L�X"$O)�!�{ ;�On�w�H�h�h�I�N��Ć�b�'G�Lr�3n �0g��x5�)i��8Q�_�h����|^����͆ ��zG-a<�������q\��L�ri�V뚕���)�m+?A'�is;I�c���[g�۴��oU��$r�*�!�{y]���3�x�@-|��*{u���aim�䰽bUm��}˱mS��IP��#�	�r�yS2f��=@G��u������jѺ��<H\^dpi��(+�4��F`����.�U�[�W_�O���Y����gn����鍇i���!1��(|h�͗4��ҽW��8k��n�=;UG(nӑ�m�4��z�n��
0�Q�eAl���w>��b�X	̜�!8!�-�ծ�v�r�]m�M�R�>C�� �F�NnYG��On�1�5K�p��y��b�دv��g��J��Y��c��}���ƣ���B�)�8�m��%.iyZ������≃C����z1iX��D��c�=C9���x(g�U;�&��|b�{Yځ�qB�C�? ���'ÃC0�!,�O�7�P� �y����,��ѸF�* � �R��(�A��$�Zf�.��#j���t��.����L��p��$�B$53?j�Sp�ʎ�*T,k��؎�s��RJLWA�׾�_�"��c�Ҵͣ������G�>D��l�*�"&��%~���`K�A������=�����y�rSK�	��j]�T��:6p���]E�\o�E�{`�Kaw�+��e����f�jN�]��N	�n��/�1�w��s'p>2�u�Z�k,����z�l�6�v��7���-m�6��ԛ�]7�O0���,=��5X�drG@&HB�.�ίձX�w��^���cPU= +s	c'��!�Nj��i��h�$uC�/�o�])��\+�_�̃�Hk�:�e�fYY�nT�_�SɍfD}$iM�Nlת�#���&��7��P�nԻ���Ҁ_�Q�*#UQ�"h���61ji�j�i�$��&�vW���;l{�M�Z���$ne�j�k~�b�=��`v�W��6T,����q���d%��@���NE���pIco:�z���RW˓�y�~P�bt��T��� J�߫V�{�D����V�5�b0�t�p�).ʌ�V뺹3��"v|K����֯҇����z���5sN�awx8:}���]�ł�Q���EɄ�늀�n�{�:�{�vT���N�䪾��{�#ī;�0����=QGБ�U�)��D��	R-�l�*�����a=�3�
TY9?�m%�:�q��6mf��[@����{tv���v�P�g�&{궼H���Ü���<�/o�Õ��Y�e@���=cOY�(?m�;(�o���aZ�U����A�o��.Ꮵc�=lr�Ey��������E.�9�a�7�E��D�$?Cǐ˥lOl�Ʊ|�ЊQ��8�?u�z�e������T�%��4Ø{%�U�?�c�)��A��ɨ �VG2�lP���+�xYK���f��'zH��@)O�Uŝ�;_�F�gl,�Ǒ�j���{4��l�b|�mx/�pk�O�o�]�ܫ� y�u�RԢL�u��ٺD�B�>	?_��|p)I~�%�y<�h�1�R�vlx���H��0��X;a0�_��/HVs�1^*�V�$��vJFQ����b"/j�ؙs���D�$��m��4�D᝷��d�-�F��]per���;h��^6:�&s��H5��{4({Em+�k�x�h�%��&�*y^��h@6�����n\U��G|Z�"O\IX��%8�z���AÚ�8�p�'�/�+�	����\�Lh+�z��GL��cj,q����\a�b��,�{�l��a۪�`%mD���c.��O����+|ʊ�x��!l��Q�%��Ɗ�J}|'(�TlJ�_ރǨ��Tͧ��C)hB�~�W��6�_��	B� �VQߜBҘW��T;�{�U=F�n�+h�>@y�ؠg^�V���5�v8n3b�գ�,�ͻ()6b|�"��[���ߪK5�jI1Dԅ9r�ųș)5q������0r�����@�0>ŲL���l���n���C�w�=W��s]ё�$Ը�]i�^���#c��!��}@2\�ˈ�pWݠj\!��;��|;m��%�?E�+��/�S�i�;�.%T��ed42 J>�P�EݣX�L ����qy7�_���$N��/��v׳Q!Ho�o�H��>W����F5�]�wi��-������Z�	�G�Zz�Z�iQ��J��U.(p����{'�$�|GUៜ��?c�����(�����h#��W	��ب䢑�y�"O�;p�s��)g,&��:r�~�g���p����nX���<G�동����H��� ���WM�ns�K���7b���-�����[���si܎���v"�\:�4R-�qg?�{6�%�4�z!R��ƽE����v��T~�
�G����g�p%�DJ��rs[�y�1Y�\`v��љ�ݙ��Q<�L#�P�hb���%��rY��2�$��4��Dա��D�#(]��L5D&�IW~���P�Z������~�<9N�������__uS����B�cJi|Bm��q�Ml�-�jVRaQ�Q��KN�C��Wzg��;�z�b���]*�ų�N�� -[���4��1���h�Z�*��ӕl7�X������M����[���aJ�:���������؝Ϫ�#��&�j�:����6Ԏ�󇫍3O�U�kĖ텥��W�* ��r�������ʮ1P�X�?}<	�g[�]���4?00�!�Y!~�v-5_�fS ��Ns�v}�\O��+r���[4����ν�}�؏�-�6�!���^Jޣ�M�y�<�!��8t��,h貜�������,S��� �m�4�w��7tR�%Uaؑ빊�T~�/�y�-�b+I���!�6/	��|��
�N(kh:���<�eN�N0"��+O.'+��K�������Q��{iMb��6np}�5�~��zL�Y7��V2�$a|��6
���?�v�R]$�Z|gn�����iA}I���.��h�k�~�o��oM��Z��8A]���n��2�6[R���g�g��=����[G��ˠ�_� '.� ::8ƍ9C���{-^���.~Ƈ�i�N��2��R�I�B��)���z�� n�g|�«��d�zh7WZT���8��f�t7�SN��
�l���_�;��l		g������pe��p,�
��RE��Fj��=�3�>e�6�:5J����=��c�N����xWc
�8�G^�B�4xZ�S���s�9.nf�C�=u �%�MD�z�J«4��g��K�IF��7[��2���1��|p���\���F��������d�����"��0A	m�IP08�y1Ã�Bra�S�u+t�mԉ,�8o&����3�D8e
I;������!95l
�=5�Q�p�:rM��'��3bI�󂿭���w- ��yLr]�be"�SFD�l-!�����>��|s".�h�M�&=��>6"9R����Z���g;^�L�c�*�P"�J�g�}!��ܓEs���?;vG���a�a�n�Զ��-����e �;`^�g���4��؅�Qc������
�i�ǾD�{���;�hCM�����>-(�ꇊ)(�U�>[�i����6s_��`5�[e���$�.�\�H	'��j0cAb�s�<���joԲ�+7OuӸk.M��Y�u�w8j/�A=헂��-���H�����#�,�$.�".���Į������F' �U�7l�0|����yQRӮh!;'��C��O�����0����S2ӈ�^��D�o�G{^�	�"=�w�<a	���)li2Y�ݯ�����>׉͉Q�*M��Ā.|l穇�dm��Ei'���L�&����>�v繬���@P0���p9�!(�����-\��=���7d9;7�aA���b���&=$ΔC�i�fO�w�q�: ��^U����rE� ��?���5�n��~]C���O5lԡ���E�\�m���SG`w�u��P �T�3Eԯ�ԥ�I*3�9}}�%���>*�=�4�Ͱ^%)��@Ʃ1��+@�u���$3�����?�'�$Q���T-K�%B+\9։���l���{��8�Gd��{���[�I6���w���`�eဳR:׌~�R%�o�%-&N�.���p�&��uQ��7螿݆���q*/�Nhys��P�3GG�"~`\���W-��6�ѱ�:����� A�t DM��B'�+Y��3��*3J(D�r3rU�0]�Wl4�O�Z��,�� o�n͒GRS�ƀ�[�8�r$�9t�E!��Q���:����X�n�"A��y�9�I��cT�͠Y��AI+�dΠ�
��(Y�Д�/^�_�3g	qE#��JQɄ�-ZN9M4i�{��&�E�Q��yLq�k1�Y|G|g��l�������)եe=��q(p_s����Oܦ���5u�Pg���/�"��`� ,ro�c�ܤ���l��ȑ���M4r5�69� ��;]��b-��I�S�D��Izp��{{Jwhi�0�W�f3�5���w��j���<������5�8~<ܫ,�Y�����S:���2
𭆮��TA�y�W��L֪d�o(�A��N��w8�7Ok�V�~��� �A5/i�/�'�����l�"���S�LH���+�>�Wt*�����5 :�v���$�<D���FQ�R��bM�H�Q|25xpfU�O�I�5���av�{��}66�Cm/5;B�F�Uߋ�+N��y��q6|�^{VVo���ُ\��S�+~3EN� �ͳJ
/���y�X3J~ɽ��(�	/0=�~�����]���(�`�*�jky�j����������O�G�&<	߮滑.���S�[�Qd�M�p75�1T���k����(��1.�m0��>���s$�&r��_N��@�\���h��׎wg����Uiv"!��L<�%�WW�
F��z��X��u����7���sD�3IT}�g�u���B��6��#�����4�������tQ�n��]MU.�v����c��e���W7��X���JeFچRݖ���r���2�2��s�aqP=K�.�B6u�;�� �o5V^M�	q��������>����o��5��2�t��=P~��-*�D�U�%�`@u�}���I���p�\�}�
�x�G̜�#j>-G���ޟ$W��)�D(R�;�c��w���}?���;ʻ�+S�5U��fC�&e*.��K��"$u�����4.2u�+9>J����Z�9�.o���/<�N�V��f�Dq��>�д��rĹڶ�0]�.9�p�¬��o%��M:y��?Ax��d�CdL���3^�/���
솺��g��/*�v*=P,6�nmsu��$�3�}���eLT���:����IL�a�r������2�H	I�xU��׃��h�m�3������g̳�u�E5��}+�P��s?��z�byXR���*��L�$���,ߺ���C��ѸӉ�;��Qu 03y,���!�Ã�-ո-�ɀIk�@��L.�b�oO�,F�MG>�C���,��   h�$��WjM ����aA���g�    YZ