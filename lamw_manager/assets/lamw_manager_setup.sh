#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2920302773"
MD5="10c960b29957bda95949bc57ebe8452f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20892"
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
	echo Date of packaging: Thu Feb  4 19:26:11 -03 2021
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
�7zXZ  �ִF !   �X���QY] �}��1Dd]����P�t�F��!�<����I��~ �������<)=cY$����4�n����%��8Q_^3��ZL
�zOp)f�%�;�S.�v���L�mqF�5Q����� ��p���D�Sw���1��mM�Ҡ��̧y/���62/�VUV��I:��;Vt��&�1;Ԫ���aj������2Ͷ���Kx�|�l�jh�ʈv�?�;!3Б��ߗ��	&T�"6��n9i��|�_��{@����!�+V�N�Ǽ�!Q�W���}k�1�'*�A��!ﴵwh�Sj�����!�5�p)�a�8�[����[	M����N�����<F\cv�f��`X����n�����UE,��&_=b������6��d� 	cmS�m����¦�UY3�2�_�\s� y$u�K�(�\�#�3����.�҄��(��u:�|�Y��J�L#`}Yv'/�,��=��y�V��g��j��K�>�Ȭ{ξ_=%�{b��n_���WD�����{z��m�Gx� Bؐ�$ q�]E��w��CA	�/���Q@�	�os��d������T5�=��Y"K�5;gg��K2�7]���KRS�67#aFb�kW;�'�Eׇ(^7g#�&��+��E��㼞�D�6�2.&h�󒤰�1��,�v><ԯ��swI�y�EA��.� �}��$�5(�����i79��E����>�ȿ^p�	�O���$Hq��9Pg�H� *=:�� ���"��(~�F�>
-�b5o�9n_�sm}��6�=j�-���\�F}�� ��{ICӍM��I��
2.uX+T�H���W�OC���$q�<�چ���b�Qpg�l�EZrk �xKǉG��5U�<�M�י�ؔg1�)�3���k�H�G���}#ӻ�ƞ�:
E|n0Za�±�`��cJ:�3�:h^��˽���X����@�!t��_����r�v�7��Q�o�v$��휗Vb��J�aT)9y�:�<ʃ�"�%Y���+�p�į��o�Vk~�yWp�K9�+6A���\6Rt00�f�5�	n�p�e����m0���L��##�����_��=Z����x�U��� �Fϵ���(z���$�.OO���0�ӂ�|��|Fl_���@U؝���>����'-��Y㾻t)��ቼ%�;���L��p-�������k�Z_���*(p?d���X��!
��|d15p_���z;��k�]�^r���=��D�:��l�v�l}���?��V�M�^�#7�K{$�d��^C�f�.?fBկ��%�f�OHBz6'2����N�����W��݋����#ܽ p	�+��P���(g��'�u&fPۻiR���
���y~09w���uf�?g��ܲ3ϋ8�'��&�����p�["�t�h��Uo����8�K�&8gV���c t�ma�=��r���?�U�3l�l��%�Y8啟��/�Z�w/N��sDD���o8�8����YU�:��8�(���}U��͉�v�0�䌒������Κ�������3o]��!1f�� &rz�b��|��t��ݶ`�����/.m^�0�(�+��_���f-��w��O;��I�����z����D���l����B�I
Zt�ܱA,
d�`y���r��\�2�4���a%#
P!^7���Ι�U�ڹ �dN�ofiŬ2}��Y��py�N�W�wy��H/ ���G��"y�[J���.		�f:� j7�e%@���o��V��ot��D���x[1>�7�a'*����C)�L5q�;�,� �Uo=| >��q���7�f0�����������:��0ﳠ)S�K&0Py�Ij�i';x��:l����������U��~q�y�v�koo�a�z����� ���m찖��I�,��ӓ��s�k�M�jǨ9�*��yz}J���"�.��y��3��t�n�,�B�[�l������e� <0�@����x����Tpѿ���7��1O�r�O�+L]�5�qI�S��?�L�!�u�Nm��?��X4�;�|��� �MW��P(�U<*����U-�4�'�kh�w�*��R�1�7t���T�5	����d����꡽]��=:����!&*��;�+In;�1Z�A9� �6��&7���%�ۈ1I�F~ؘ��M�g�g�72S��ߜ�|�d��s�Ut�袺�������$��cSWl18�g�غ��+e\���h�������f��%ʡ�8@�5�la����M��Bf|_͍���* 2�w��{MXs���.���5A��V��X���ˏ9UO5��_h�.Z(阚��Q �Z��mWQ�P�����>�9y�eUbB2����鐧�$���i�l�AU�hM���_Q>��0��:��T�>�����8'{�{�p�ĺ^��l�w�}U��4�"�J�k��XB��'sY܍H�E��:��WaLo��B��?�m�F��w�6c���M�/��#qV=<���ԕ�@p~�~�K�^9�o����M���iZ_v*�VSy����� p�{͈�w�2�=�9���'#���䡘���*c����X��Ѷ�Ӊ��5�|l*��:���dxw�hW���xx�����Q�b,�0B�z��K[���#�;Ȋ1"f]�Ɵ��v�|N�2�ĭ��������r�|�%b�D�2�¡��\�}ߑt��i�S<\�QB1-ݣ;}\	��^��2����Va��h}�@j���gX��$��0�h��m+�(�|�tN�!��)��Yr��칯�L�,��Im�/�}Z5�h���	O�/��*k=0(���ç<��
t@C�),q�>��';�zb�rI��VM�gm�_�4��$��s�U�\܆�ڔ�{v�����-tݎȐıg�ݙ��0�?��X���>
��5����S��K����ř�-:�s�wgC�c�i�vd���<o�W�Hn��A�j�h|S��#�)���h�����`���#�����R���d�~E�>לP�3�Mi&yeP�����;��i�\�|�f}	�cYj�8�uV��a`�ͧ�^��w2k>ҷ
����8RYD����.�T,]�GG����N\^�譏�I��m�"�����뱔q����d9���W+���Dc�+���l4&��R��h�W����+U*���ㇳ���Nr��p���Wt��l�,�.��M��f@y����<O(�N#�;��P�Z�Ӈ�����b�>_�����=��xA��/2���5?����o���­SP�~]g�kz,�N;���9�ms��tN�@�)��`L�˓�g���Tb�=���M���G��kÄ�jH�8�_�d����s�F;�M���E�zH����k,57�\�Di�丞Xx�^o{-zzW��\�N�?|� �yul䌳��u}
v�3������H�ؠ;"Q��zK1�����zj1˘��P�ыK��a��Jl�ť�췝b�l����n�v[ݭp���<��|C1��C<���i����I�m�)��8K���6��}��h@Ĭ��d$���d记N��~#	Y�d3��&Y��Q����g��^��#�u�f�
ya���@z:Pd�.J"��Q"�֘/�i���zR,�jǌC�����t�e�$���u��bfs��ؔ�#5Օ���#m�0 F_�b'�@O������Y�ގ$;dgjH��N�k�CJ0�wG�V�n�I�o�Y,�����w#��#����HeM�W�k.)���\�������{��eg���X������T�OL�/诟L��j��tx)hE�{�*����<?���㨿�+.X<W
���d�>�uH�Z����?�SJ�_�R[�i8���W��_Ò�Egu:-� �&��n#���32���fq;�l�?����ƙ��,�pҊ���Ƣ�r��99U�8d�/uà�m�Θ!FY�y�$g*��/�J�(t�c�ͥ�$'�jI\|α��
�8�R�|1�Oi��W���7M�kY�?���`=wt^2s����|�l�
���<,�'d&7��o��0�(�
�Շ�.�zڤdCg�`�°2ds[��Z���isZ��S�5&��v�p?h���WC�3��C[����F�Q��0>/Z;�z��
>O,0� �G������s�ci�!����b��=�K��`�O8s��U;7���~�D�-��y9$����5���]��ښC}'š��bo� {ᓓ�~�u�Uk���̸�,b���>�@$ŧ��:2��^����=��͏�L�;tIc\н��oS��_���t
ք>\�AU+n�
��Nc�mi^�9.�V�ѫo+Ϲ��lp�����P�]���E��|k���gSq����Lĝ@D<���V�oY�ne��x�I�>�V04�v_��B�8����a�z�Sr(��r����(�R� �B%��</)z�K�m��l�E���HA�Bj�w��,v���P��΋z�AB����5�C����ꂈ%��̃�C��mMq'Qĺ��{d{u]�dd�����߅!Io���`�e3��%y6��Յ�f�Z�w����މ�oԱ4x-ڂ/��
�#1-�v·�m3W'Y��0ۜ�֒ڷ}��H��\"$�&�n:MJ�# ���/�"Ή�a�u�ǰ	R�k��p�OqA!����}���e�Eny�8��d��`�|�;���*�7����7"��P�I����1�p��:�#U��zN`���7�1sL��X$�����<t��ߊԯ�$i�����;hP��?�F��8���ѻ�]_����I0n{	F�v8�/�I������o�).��C;,�2^��2�\*����Ɗ;X�#����ق��f$�Jw��v��۫����&��h�T��P���^�h���S��/]ʎ#q��u�ku��\Ÿ�~���H_Q>CꇳE�J�F>���qI��"v%��߷H%����V/�=�ۗ�K���Ш�9 �H��������5%���X%��0��S��k���0V̅z����
a�Y뗼�\��a�nm��/"���b�y�_$R�gE�1�_d����ѩ�6�"�{z�LB��g�/�6YD���c���ͥo"Q˃���#�`:_�ގW�~H�!	/�y�0�0;� �w8�X��bp����av�ȿ7�%��W���\����A�s���~8���(D럨�����,�(P|/~Oy^�r�����]#�ӱOq*�����6����͌�>bR@��ꉾ�s0�%Vl��F�[jvƪ|�R@ц"�u��(v�(�r��n�z�,Y���޴�G��"leK~G}-S�d����%:\Gh��y�MWZ��,6����6����Fb��R���� ���!������{��|z<�4<[Kи~:�fy�o�U�E��2����l�N�(�4��|LŞL���C��&ܴ�QXz��<+��,���@o��3$q�,�~^Z�x�dQ`N`��p���׎ONoU �*t����� uZМ�J����N:����odP#ӮA�<ֳ̗������(.BT)G~$����2/J�=�1,�N���\��\���y����#��'�;���{|k�^dA��߹�[�x2;�d]��H{.y򭚦��I�װwu�=�]���b��uVA:5r�Z������<S�iČ<�^�55C�-"����2ضNZq:oY� ���5N��lb�N�<Q�Q�J�f����O�����>��䘂���c7�`��z�s��W�
���P��8C�E�T�s���'��p��T{&�w=��Y�j���z�x�V�Ax�uixvȞ��[�g�[фոF%�N�l�N��
?���u�P�ûJk�(ٌ�F�tA`#�R]mH�_�劑mp4[4�y����=�5Sޝ�{c_�#j����T�$nb+���9��*2Bu?:����i
mChc!�j��lg9QS��%e����'����	,��d��� �J������Z/���%���D\Y6���\��R!r��
8��	7&N���/:�bK_5f]Y��� o���y�$��mԏ���>�K ��L��:���/\����ױ��'��m,rL��=��BG�G�`!���i�N��@c� #�h"Q�_t�JT'�RE\�C
�����W�VoI���lM�cF�����(��D�����R o��鯱dXC�DrS��iMM�H��+�g��4���_n�d�H� �� I%�`�ɑd�l���8
�H��9<A���92ޱ�Nt������Z8!zƵ���;���6��T5p�βְU�2�,8��9�T7'A�����0��AI��E#��Cf�&�P^�:X�]i��N��]s��M[+4����zd�����ds��E-������M�`��
�tɅ��?'ۍ j��J��4 i"��yفS@#^ Z{~l&5
G��aP��D��%����Aݿ)�;�~�T�����N4\đ�ގw�v/����Pa��i�:QeeOm��("�`��`,�����لyī=��u뢮�4����['*�:W'D�+N �v-~ {��<�+�	15}3?R� �$Q�w�RPd���?�1vy9�'o><��BC�����doO�B� S�Q��2����4-l��N �x��ԡ,Y/cns�Y���ܤc� ,��c9�o�K��
S�}
.�˓�6P���|fm\��;�W0#�qB^I۹B�2��&bnhhG4O\>%~��1]��"�k:��T�@T���UPKL`�c���M�f	(�_h'�*nE5+R������\�>QJ2\�!q�H��
/������:�� q��݂$�4[}��s%�B�˨>F��L�D��r��5L�x��Mq��4~W�N(���Sέ��sa�d�←Z�l�,<�;��N�b��1��@{5�cE��.�3���U=���q�O�
����0g�iϫe@�M���'a�X������3����Jw�^�v|��p�Ou������k�Q�r9&l5�|���.�_l
5{�*��]s�E�0��X"`.�lh
�ׯXVJrݝ(��;?�E��w*����9��~�&��?@a�d�^�4
9�\}VQb�z�/� ݖ�h�o�7�>�\M�F���H���:ٓ��Wkj��p�^�7����.����ض-5�!W����_�C��E7�ی*������ҞZ��>u`�$����#��A9�
�J`�%B��!������1��e�&�免�R���F�o��9&��
ƕ�f`�YNs�i�S�a)�{%�"��d���_�-	��QR���׼�Pd��k����s�%����r��.ݣo��}x���
���n�m��m�],H�R1�7��גT��rN�ȑϵ�o=����K�4r$!i��٤��T<T6�5ȵ�8�����,��B6�ci�����#6�s/ߐ*���U��4/co Z�ڥB=.c4��SQ�h���P���#-�1��H��,�l�0g`�˗H�S(;�ׅ^���'�>Z���a)ɬf��
),S�#�mj�tG��D��]%���fsW�&+��۽ �F;�i����܎����,�nuEb�t�/{��<:���Sp�;��1d2�­H[������o�S]�PNz lx�%�(b����@�F��<꼖��u�V������=�v]l��!r6�H�D..�g*�s���|6��¥�j�h���wB����a�,ۣyPyi�q��EJS�L�Q�Bp�;JXf�j�����Xh�]4,$K�Si�7�U�2}O�JK���iⅎ{�}�b��F3ΥDw��N��h.^�t���F�׷�ʱ��|x$��4_��̹D���}�YX��>�G��@�@I�s&��BK�f��B�F�o�������Ec��$J���S�*��ou�AY�_"0@�q��-'5R�����A��dMi�����l�*$�%[�v[bn�$96�cՔHg���?]a��?P�W�-�:�}��I��mf�b�9��s<�����`�C{52��Ku���3�^�%�.�~�G"��kq..��;�Gi�T/��0�tӞD��!�����Y�3�<C��ʢK�e�d��\�f�����>.RE;P^����ݔ&c��� p�s���P��卡| K|~8��֍ �9h�����&��Z)�<��/���w��/�D����|��;K������\�Ӥ��T�<�K���C�Bm�a�*qB�t1�@��vX�p�g���7g0&| �]��u����Fu>���5Ao8�
���K�A�"} ;��~a*��].�Q�v_2�i�%���X��+w vJ��|S'�!D�}�H�q�43��E������PI�O
F�k6���߽��"w�'��qw�k(���X�@���g&��t�g�V�E��O����q{��$3N�Os`�OfS�t�­	^�f/I	�\�v�ltn�C�eʤ͡�V��8��� ��q�x�l}/��%	;���]4vo[�в̕����ȱI�$\�8A'd��+�� ]v(z���9�nm�͂�?	A/i�Kh�w�b$a�Nu��H�����m4�C	���Z�◚����=� ��'SA��z��*�$��{H�N℠\�d}�]��:�눷���$�x��ȫUg������.%��T����0��@�����=?�\u�!�u�/�U"%�οyv�3��`��k��t����ôՁC��9`�9�� \м{},�T�lA�,�Ƞ|Mi"��u����~�j
p/+��s�
]�bZr*�f��rH�W���\P����3w��U׷��xf4X����z�S�P��v�PK���g ��#N���U�u�A3� O�R�l�D�5]�\a"ٗ]�Q�9?S����7'4�jQ��j���yu�:j�c�q�֩׬�K��G��d4�u��_N��7���s�e!�� ��Tc^S�q�/F���W�)�KH�#*#t)��u���y��/lt�����A�V|D]�z�{��	�^E+A��æOqzw�_pr�+'-J�B��z"����#F��ш�9����ȵ��WRn`�ix��6YL�x0��D�x�>���2�>��M	��+F؁��%�f�3�E��V�{��݁����
���}�����F,��sݜ0���V�������o(c���3Ԭ��V5���4,���u�U԰_?���3�B�pZ>�{\�<�]����fˋ-S�Ͱ|�X���N�f�������*n�|�b�4��fƏUD]N�vA�ω��z)lN�{Mc�xsf�M����-���5��Yz����z�i2�ޤJ%�F��S�͚�����odxء��+gc��,^ô�^������D�V\�@|�vbJ����y��u�1�&xIY�������nM�i��dj��w&�N`�u��C�2�P�pU�eF]�Z"��
�]��c�@�<{ݖ��tb������4] �R��!2O�d�
��=P�p��IHA��@k��e�����߾�����y�3�Nm������섲�pB�-P�1t�{g��u���yy&Q��~���1�
�Y~�o)�/��+6x�,�#��;�~$��'�4q�Eü���]�pe4���Q��q�H�?�GЈ^��nہ��3�Vu~?����(�r���"fլ<@o�I�1���;��=�� u�cM��0�Ζ��5�t����sȐ;�Ed:;��$����8���ӊ�"�s'>��O�S>��f���÷6�0і�¥<`#�.uGs
�5�!�TPZ!�uwF[,Z���%�����`�v�a����w
Ʈ��px���Fy3�:¬�J�e�i2�E3����� ��cC����o�j��q=��M �M��������u�zJ��+��6�`v�����K�u6_Ѣ�ܻ��(P�ם�o����?_%�Mڔ��sƊ�W�ƚr�����c��5���7~����Y�vn��+9�P^i=��K�E��=}g������(�$J �K�A�p$����>�F�d�XW6Z�]h�h=CZ�fuk��Nflܳ����Ѥ��FJo�X1�Ə�P�_����!��U4�>���J^��a��M���_��O��%��/��z��H�M�2�6�b�q8���xk�I?���3�$�%�6���iP��_�u^�zT�XS9�3uF ������������䅸��_oM�`�o9]o;�A�d4�'��y���\½|�F�� )\�M�"�](��x���m����$���3ttn�'���<�쯀����Iz��8��"a�-�n/��M"�i��a�˚�?<!����u�Z4���c%a�ϥ_��!�B�.�kѯ���7�����s�-��jr�p�T���Pd�pD�.`�\x�&j�xmD�cV1�3%�_ra���NbEeCj"ſ2):�YQ�h��u�@��L�����P�������� ����34�L�b�^U���h���P�Hl���5�M��-VB��}��DD3�9R�v�h�,7�E�r�Jx�mŞ�p���3#��ڬ��}�q�V^AWmPA�FE�Crd��]>y�d�:���)ݱ��sn�A�wt孵h>���O΍s%�������U~M�?>�M�o�MA��۽�A�����Y���lZ]�(��E�M:��p��]�1v����0}�N�O��ң:f�T t��m-�G�[N�6�i�(����m?V�����9��y���Spc$]j�e�k��+�F,?H�M�s)~:Fa/��7E�\M��9�f�(�c�y��,�#}*	.����دQO�-;�?�~��]�̌X:`ڽ��HJ߾Ո�H���ŀ	��GS�26��3��Ih�CC����l��vţ�G��j x��㛴����@Ն��'���Z�9�������r��!=6�cjL%�NE�>D)�E��0	���;�A��E.�k�f��Ԗ����zE�1�H����ltܡ�dy������������m[~"*�]?j��ۺ{�uّ�{��N��)�0F?9��#�9���$��N�G5LQ!�RONӎ��<�|�ߥ��U��Re�y�^�9���^�A�<�+��1=q�>ܼ����]y�#/
���BƄ��%����tٺ�5��2�7hof�S/_���,#����MHrZzRX0/���K,�2�la��c��o��³�Ʃna�I�l����"u���B#��䢖��YdB�A�)�>�ߑ��N�')�mJ����U�VϹ���2���S(�=�)z9�&������bģ���(ly�Ë����$� w2�Gh½#������EX�}PФ��)P�-QhD�h�8��>l��Ir���KX�k��=����=4��"�Ha������p���k�[L2w�'c���;������ �χF_#|�G\ܦ^���ۓT�RV��&��z�#��y,�䕂?�5$H�cZ��9j��n_��d���
E½���Y����*�*�gMmz�ƪ���d�7��\X roJ[����p'@�^mka���2
_��ڱ��U<��m	K+�h0�|eD&T��W���@�G�.�/�Qz���KΆ8$؜Ğ?����	�/��ج\kaL���B�`�,=�uo�u.*Al6�h0�2���fD,\|&))�=#�o��qbY�� }�o��Ej�����$3�ye|����N���H�\<}1g�&��3�&W��F�W��>����`�ؔ9QB����2?�����4,b>�^[��8R�5�&����'�,/���8�BV�<��3K���qK�/Ug_�>c�M^�|���QsP=[�ͬ�';Z�T;�&r�$�4+k}��(\�_Rn̳�\� ��߫<J
��DjyV������YL7����v,$��y
�1~�}DJL�Ɖ�6�t�N=�ςR���d�4�Q�n�+��e�{:-�⮰�N.T�����'����~�ɻX�(�
/Rc������)h`ǹ=SDvX�2����b�htr���&t�C#'Qy�� �ݨ�D�:� ɪ�в���-p�-���	ڢ��	|����0q�(F�6��}
�3�Խf������v_��!#e�����>8o��>�v��Rݽ�Š����J~F�%��'�a���j���H����TIs�K9鱺	���A.�__���uR���T �#��@F�g��9�-:���"F,<TDY���,}k��i\	�5}Ax,�7q9F~�h��84M7�cݱ�����ԛ��Qm ���:,U�+mo�߁$M^�U+{�&6����P����}d�wd��\��6�*Z���Ϊ�=����DpϔdKb���BIlA/�@O�i�$�9L��ʃ���,HV�8%?� �~"�N��j�ʞG,��<�A	��:h��l�T7E��uVE�q�:��5*.'�Q�쫦Y�m�:a�ǥ��+Gm�8M��,k��h'?�!�^��ʳ)�x�j��r.ƛy�����6����,egp�r3��]�a�q���P� ;�

�"�W�q��aU�T��?4����Q�B�_$O�o2��f<�#��kLW	��B691X�3�k uɄ�!���^��"���Ǥ�X�J&uVmΒ��O��-����H�NAt;��.ywf�[3-��-{\��K��#�F�T��/��tB���!�\�T�c���"-���֯��ps1&�ތA�Q�~8�l�yL� bD�h�f/j:���c�[��cf�J����Ė��VX�΅��΋���˓.����%���%�F����
��.��_��&���/TF�j�qH��&I�@��2��dcD��/��u�w2|����/҄�Jl~g$�X���W��f)g���a}���2�	e/��$N��ۦ��v�5͆uO ��%En�c�c
x�.^�3�_����d9��������ό��f�����6R$�Դ}�z�ز���i����H�6Ya]v�h�7?\�.�j����%�uw$��Be�"���&�in숂�6��`�����*�pf����?���Z�J�}�`�@P{�j�-���b�`-��Ai(�n�'�EꜦ������i��M�59�>b|���_������Y���5J=2�u����Ү�1bE� ��}G]�dF�m'F΢V�{�M�LO��m�)�
'|��u	��E�o9����>~�6���u�}Hz�J�������[K�'���2s���Ӂ��w<*�.���@��?1Ur>�5��1�$f�3	E��P��truGx������B�2Q%�ܔߞ����m�6��x�D�Pd����?���3'��?�E�A�zM:{���{�������P5ev<뻶�eJxQ=[�V�(.H!����7�)���V;u���󞷜�.����}�ۊ8j��g���9� 3���?1HX�NC�����Ҩ��M��h�T�g�óBb�1f�5�egk�P\�D��Mksr�)|�8d�>k�Xʱ!,v���I.7�M��:Õ�&g9�m[�|�� �,��ޅ�FO���%�X�i���,C]|c]��R&�b��9$��p�F��-j3��m%��|�)r��~#\��%N�qa�eס�⛻��� ��.�P�8��M�FD�'ː �<\T�� _!R�����"�7�LF%c���7C���b������r6����f�p�8t{��o���Y�xp~ql�p��&z&X{I�Ĭ�$��1��O�Z�:/ & ǖ��,E��^�����J_H���kሬS�/`GB�Y�?�z8�%ab�U#{�(���J�:���x�v�"��}����#b��q����I��ۺ���]M^8 klS�X��l�0�Tv�>�tξp�� /|�Q��C"P���:4&B�fOO��)iO_ţSA[���b�3ȫ�S?v��x���S�tqف�T����lxC+�00{wT�?sm5�2K(D�O6�}���=D �ON/!Е�@#�5榥R1&ϗyC,H!���Z��n^ȝ�����R��u�]��_�j;I�0���/@���˪��]����,V)m=��W%Q�L��8Ɂ�8�ك���7�@�"�ٛO�9ms�S]D�@���7��y�����= ��-	�X�V��|�N`�@��Æɬ�E�I|�2�%��<����s���E>�h}�fD�o{��Ki��y5����TV�A�&s^��$Ybt���W�4�_����H1���1*�a�ܓAn��q�|ɱE͚"3�ηZ��h�(�o"�U�C��������h��8�hg�L�������)�qzv��%��}�_Y��\e)c����\BT��oSd�7E��t�,\ג���gx����-&���E��y��/J�I��D��&oI)��ԘV�� J��f��	|*I<3�z�M����c�[�*�I=<m����=v5Y�c�ޮ��#�1�5�������&�U&�����0�����ca����5��"���g��2�"�b1���m��~pÈ�ӕݩ-�E`K�W��S�Ir��<�3�^ܧ1��U?�����]\M��^�UA���E�.�|�/��'�#���������ā��H$��_�I9T4�c{��7 (�	���ⲋ��`�U�ڒ�%#�+ю�E�����5�6���^̠I��Xȱ�Mj<�.�-5����R�����(G18H���8� $տ�}9\��Ȑ黑�"���}�t�E-��[�����L �P��U�WG��L7�P���8�T,�b(_1'��0+���c��k�"$AJT)WJ�~���v)œ4��4+�F.{��[	׋{��׈*+W�?�;;lK�L�E��lx����!д�a�ڶE�Q��|y�G�V%���m�� ЈW4/J�K&�"߭y4����'t(/��)+����e�i_���E(�3�Ȕ�V�����1�"rZ���u1z�2�]L�'����#[>�S�&�$Z.���
w"���mR%�}e��s%��-�a�4b�ٹ_3��*�X[Z6�KB�d���K9�K�\H��#��#
s뜻� �=�	��K�#5����L{`j�:Rs+�2%������Y�=b�(�8���Vl�Ӄ��a��j�ي�&f,H�M0�K����TP<�-�籛@�X' ��u��f(��o���s���Z�&�=��3�*�<��0�s�S�VSP5�d�ͩ������OA�%/�TV\����{�M��[��[��t��ռ�9_^�ŕ�3l��KpVv���e;1�N��#7�՜�p.�:�kE�Oן}��F�_�=��S�H�6گ�=$�j���R�!rC��I,�(�J�hX�	���Y���$+��ߒ䌮�	"7�;��K��V�7��J�\�f��RU���GZ�9 S};���^�~U}�X�}���q��|
�C|x�V�U|�0G�'��̵5��<�O�N.��y.9�r����&�÷�"EK����o�Q�s�Wj�O�Z
�T�U�-��d�R^�IX��h>o^Պ��W
�m �l^&rW�����c��Ǳǈ�;8���O�1�bRb����\ޟ��I
yE�cX?�yd��;2�S~6��<m��-�-����@ 1� h�J�A�d�}���	�p���މݛ��MQE�3¡2��Ş��ъ@<@j-^g��"��G.��2�AE��W��������z������ܖ�D\����es�OG�ο�e$M��.9��sePs�|q	�>Bv�8Z��}��Y��/v��_c_��9Y�K�X�ͨ�Q}HXļޟY{eƤ�Ǒ�&c�����O͜C��5)3�G��I�p#�:���u$�Vo��;Z!�*r��Wsa� %3N����lܸ���ޣ�y}���X�َsoԿ�}	R���t�)Z t��$-1���oa7�с<��]��"�n�ˉ�>i1�#�����us6��_��a� �wS��(�y�3�&$0|{�^fٸ#�4���}�:1��R��BA[a!m-&�	�ܤ��6/��ƛ�Yz���=o��oќ�<Ӡ��o���ۯD_͗{S�[��Ӑ|��I.����F\�	-l��ƃ���dH,�6���~ө��w�%Hnc*��;I����p&"�zk�]b*2�{�M��St�� �]j)�U��ۅX�g!&{N��P�KA����O�Α�/"K�~���k�xHۗ8���1�	��Yz<^� �x�����2��~�~e�¼?�(�/�����Y���`���̈́�DOG4���a}��V�`���U�c�'%��L�͇��cr�.�Z�`���ĸ��/��
��!0j�ފ>�ɢ��������+�$/�'g�WYdJ������*�<�8b]�n|�P��a��V�����shd�E���w�%N�RNO�U�N�-�y�˨Z�,P��l9w���5t���Wべ�	5N�K��]�Zo��1]YV��q+�b��������
h��!=-���r��8��4���:y����,�f$N�1u���\3f�K�w �*@��?��e�3JNEX�tϺu�/ӫu�����r�B�G���׺@?FS*��b�3ɗ}��Mk �^_���tOi����<���;�b��:��V��n�L�'���xY�"����]�Mv&�vM=��
��I�h9B\�'�'�?���s���*���#�[-�v� *0{�i۱� +�;pq���t���ڷ�^Hֵ1~�{T��/S[Elj�?��[��7�*)Q����SC9�pP ��x��MM���:�*��ƍGE���[�bhr��9Z�ehA�EfڎNJ ��PM��Ib'����Aۙ�(�b��;� 	��!rﶕI��1� l��|��A����:�_���zy����ѫʮk���#Ѧ���W���m���ܞb[D4���8�\�P*��6�8K���������n0� �Q�v�� ě�>�Bn�7?�|+�sh�S�.�j���|t�M.��`��8Z�qՋ'�	����rf�+t-ΉW��C�s��@�	(&S!��r�T�{E�Ɣ���i�n��ެGQ�0i������1W�L
Hͧ�Lp	�b�Y6�����v`9���Rj58XM�4��rj�Y�(��c���\^t�ؼ�#�s�kNwE�lh� "�Gku/O��Le0(ٷey�r 5���4�z�` ��qpTX���f6��v
DB�����.���������;* F��������V2��N��!�\�ՙoB����2�B�{)ը�Ԓ;&�X���%�h�����G;�$ %�]S�n���r'#�M�vC������FD����7�Ξ*�b}$�#�mx`�>����fk"�[�3��� �ќ^*À������Tl�#f�N��0��U�s3 ��3޺��b^�ؗ���"�Z�#3�ل�.�g�Q�����Z��`Tuje�w�`ƀ���w�Y������a�
!�&���ʏ�]�=�� �v�g��
�)�%MQ�Ǻ(&�X����w�A;ٱ{��cBʺNnyvRz�D��iDC���M`�������jP����� */_�sh@��w�J���W������{�������!�g�Bc(����1yE�@C��fz>�����V�f�sEos��p�3��V�u�ݙ0�L�!2vH?H�]4�j`�aua��&�+%B	�3�CuV
��g��}&zr�-Ǻ<N�'3E�S9��J�si��*�h��A�f�Z�=�$���L��J1O8y-�ڇ]��^���$���P�DEK@v�	�mL'Dȧhړf�I�s�<��錰Ȣw w̹��#���,�}���|�vE��I�z���ũ�������98=�i��>҉	la1�#��ѹ��_.��@(U�s=�n�'y�m���s
���]�x�~�6Jٔ^Ox����Mj۱=?h��������N@'�\� Z��f��$簘h}<��۫b.bۅ�٠xP���@W����|�J�c,Y�	�0�t��Py9~��U�*Y8w��Js���\���Uz���ؓNj�	�~��J�,Hl����J��d��q#���_�Ǝr��6M,fL��<&��˲����Zqyˑ�Ҭw���3�dA���q��B-Zʫ�;�*�ivb��A6��O�h�rq.xɣ}�ȷlH�pk���4�krL��c�������q��k��r�Z[^7�B���h�v1��ڬ��^ٙ�T?`��>n}M_H!���^��[�D�Ӛ������I�-([)�[dB�]s��"7TّɎO���u�g_Dε�ӏ �/�%�r�9�)a������:+|��c��|�T~4����y���.�Wy�v��BQ
-zܼУ[�d*���V��QcF�J���d��]�lݮ	�6b�׭��H5ݰ��^|c�a1a��HW�=O�-���azQ$($��9<4/�̈`�J��>�f��(#N��Lh�[���Ϭ~�@ya��Y�τ.�	���Z��i2c�$/]�s`��X�sͦqW/0���gR�e��H� 
���=���f������l=�jR��E=���M���i�]`�����{XD<>Hʥ��'t�+�CBZ|�9��N�v̵h�٨F�j��r�l#�Ka��C�g6Q)��둲|9�I w'�{5M�zb�颮�����5Q�@3���'��a���G���B@y�<�[z�S�U1��V�f�M�`�4���AY*������u�2���M�1P|e^Niӣp�U�N�CH��6�`mD���xB5�4�
�\�c2��ĩ��7M��x�T_~���4K��&Mt�;p��K�����Ṏc9g:�^�:����e&m"ūM�s0p�I9����5�5$�ɃDVF�Ci�V�������i|��n)c���v��G�f�C"�}�I�^�T>��au���〈�qă�A#�k{��k[�Ez[)�sͣg]4Ⱥ�F��ȷ�6g�����
ݔ���hI�ԃ��GҼ7HE�Ki�F�d ��8R�,j�A���L�gEJYT$�=j
7�& �SO��O%����fp�w�Sy�؀��N+������u
Ty�i��}� �������t��1~�ڙt��E ]�4B%�����}��縥s�AL��g� ���a�7&ܬ�\H�6�t ��:����).Â���5GR"�g4�:FS]搮e�p�>���yhz�G�p�@���|!ˊ����&}�"�^{jЪ�z#^��N��n.Zon�n+�:�"66��d��Ƀ]7��
�C�b�:�z��?�uh.�G��b%/2�P�vu�$c9H����3�����%��|8�Q��>D�,��5o���ʨΫ9���Yk�i[A3ZLӍI7]�E�^�)�g�Ro��4�	��H��L�S
��8NܧӇ��~�.!�΂�m]�~P���T�5^� �쒱�Q}�R�Y2T�8��D�I��
ō�A�x�^�� ��EbZ�����_�I�1�)@�2�w�����0��Y�A���!Kss�%����߫E\a����l��N��`҂���>���lg����q�Zv�'r�a `R�2�G����3��"���R��T��eJ���'�I��m}�eC�	hO|Va�y��(����[R��WR�f)a������%(�bbK�ו/3�L&ꊃ�s�����	b3��N�m�N�t�����P�K�>��hPˍ���c7S��R��6 ������6'3�F
c�mݾvsV��A���9x�\ez\qK��s�W~&�!��JӴ����J����c \�R��d=��S�:���&��c呶��6��n��[ޘ��m�SM���W�Q��LSPutp<P�
Z����m�;&5��|��-4��r�<�.�X<���Y���)q�]�p8�nN-���)pye�;���\��X���>np*�s*s�}����մ�K�p�dz)\�L~�zd���!�l���ӽ2��@w��ƍ��|���n��_��rTCz���7�`�3�e���A`�C��}�*G${��N�s	�*��t�nC_�k ��0w�U͔8�d)^����j`w+v\�Q�4��dVK�<�o��w��m���f&�,o�{�����t���`#j%w��i��p#�Q&F'��%EW~cD��+6C������Dޒ:.c�X�n�~�c�4h#-@�n�|���f�"[�ǳ8��tF�"m�W�o/;��_�d���]5I�O7�-��pI���I�	�5,�F���Y���v�^�]�m�|�^��IE׆v��23@L��Z1=�����T-�;I�EKp:}�����vz�� �c�����O�!d�4�<�:>*h�G�6�Z'x�*	J�1�j':�X��$_�N�M�B�C�5�\y���w"T{/�Л�t[{�aR�܉��y��]Z���P�sgw��t�q�o��?LW����Ų��N�/�t}5��:%^g��p��K��ʳ����j�����QFy��u�ՙ7�o���jS]��rC/�Xv��V�����     �2]���G� ����쨻(��g�    YZ