#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2826726875"
MD5="577dcfd04c147d2d9a27d7f61cb8ba59"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21479"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Fri Nov 29 19:53:28 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� h��]�<�v�6��+>J�'qZ��c;�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ���m�n>�n����A����Ɠ��6�7�ͧ���/��Xh�<�L׽����������t�9�%���dk����;����u�?����>�]}b�3��}�OU�����̶L���h`:~��G�1�<j9[h��T�^0�K�S��SJ���K��DD��K�'�'JuF�fCon뛍��B�4���Fg������f�7��x3B��(�>j���9P��� L��&�Lߧ�yQq�!�vA��:;S�'z�{@�~����H[�á���I.f||8wO���ё�B�����:����;�����N;��s2�ƣ޸�;ʚ�0��Yk��PQ�R5F�C V����:���w��*���!�[��j_�ע�w{�s�R)'����k j�u׹�osv��Qf���ŵ���R�\ �[3�����[��;�o���e
4���?��m\���J����O=w�BV�`�dVu����� ���@�=�,�,�b��p�SF�.B;P�T�fHtN�y�E>�+�������D��Rw#ǉ����|c�F����ʪ�5�����}��sƧu�E?H@g�4�*���۵��&����B�PZ�Z��STNP:M3k�:W��/]O��7�
�`1	=�2��`�l�VO(o���＃ *d>MQ�4|��>���d
8�43M���a-�M�K5�m�y���v=��̌�pC�V�üS���O-Q���T�d���i�}ϱA^ء�������K:%�]�����ը�?�����yo�A[��|:}�����lE�ra��P�v��K;$�z]��i�~���ȝ�B���q�|�����p�\��J%��D25)+qS,���J���1&va�nJ��O��.C=x^Xp�J%��X`�X��}uj��y�<�U���dvFA�	Wd�"�@X '�÷�&m,y���>�/��!�U/����lm���67���'O��_��/�y�]�M��٤]��$=<��<B��_Q*#���#�=7l����+��R�|bt�u���BU�/��uT�p��G�����*��V��W������U2z����Q��7Dm��֨�ۯ��;9��:�dr���`���y�m^ċBsl�Wߓ	<�.d��d�Y�̆����M(q<��e����7&�:Y)��G~=�\�*�#|�ib�E{acX�(`2�s]��QgF�`!��o ]Ӊ�1���l�����vu=V�=����~ g5o���3D�Y~�.�홙0��*��l�t�L�g��Fp��M��Y4%o����U������������������)^�Id;�������+�s���Z����S�|���_�{�䂄��&�>�#�hķȿ2�.x�AQl�"��˧D'�֠�|gK#-�
<��B�]�Z4��Єw���x���̟�i�i���H�M��hbYn���m.mʋ��bbc�K��A��u�Rq�)����8`���`����]n`y�a!?�����c�t�aD�?��� �V0��9v��8� c'd�캷Ǉ�ntI�!�"��?�2s���432���F���h5�$"cK�>(Dv�8u/�c�\�Cs��:����*a,��q�5zn�z�ݱ'8�CU%���a�<��V���E���Q�5������މ/�^d�5i��qQl��\ںג�n]�bwz�,��1h������he]i����$��4s�EͰ��)�W�sS T�~pѥ�u�{�M{n��	�@�E�<eH� @�9a�b�៎=����'7Z��{f6�"�K4v��W�$5�~�c�X�'L����tW�t�ե�f��̞�!��*��m#����� �DUW�N�19����~s�o��/��J�g��y�d\T!ߥB~z����	�����F�ӓ$5�#���k9��h���6נ�`�U���J۷o��79��QL��n?>2�:Ꞝ�?�w�`�3�SX@:$�×'���7�%3��彪�>�翩%�K�t�T.�WzS��6b�.��Q=%�[iʓ�9���
���C�C�8�T֏h.V /^,L �b���6�1�iq�{f�s��ۯ,T�)����R�����G�+p,'�Im�����Qkp�&X�^d������ΑJzô_DT�=�����˧-��g/�/��$���s�}m��T�|�1�R(��%U�Jv'A�����4�ȁ5C�ZQ���IB>�f�	K�~_�J���?���>��<��q�x�L{޻90���@ˤ��d��]��ǭ���eC�[��%�����J�_�������r����/c�*�|f_yY�3���V�A�� QI�.�B+���l���}Y�vK�}=0��%��׎�+�^F�m��~�=�hR��G�9�	���nʝ���6�c�T���C���:\D��d��˭{��F��6�;�dQA�naf�����00}�l�:@��y ����6���Q�p|�C��:�����X�
wd�'!kn�D�%jP�g�P����)��<<���җ�$��*_I����ϲq�2�(&}sznΩ��������Qj�/���v-z�/�$a �]#��M�������ʄ�_�����_~͈�� L����+�^���Y��oo�|��������үf:�������7�H�=���|�e�ġ����Ao�b�.����Z��e�]R,``����3�0���T�J���Z�%u<�����A�7c���@������9�X�f��9 ���t8����E�RO�̫Lk�@oM����{w��{��yF	�)�}~\I�������C� 6��g�wj�%�&!~`��<�>�:u�C��D���F���m����7������~o�3���;����ف��A�o������}H�_!d�T�#��D(~����bJ�	i`4X�5\$/c�@��U��P,m��_"{��b��r��1�JPr[TR��O���o��F4����������G��\N*B��"��C��g@������1l�4�x�4��������m� @H-��%y�����J~@췈��nRsbkq��SK�Vw�s�w��Ղ�1�V�L��6i�1aO��~[N�y�!n�/�=ρ\��������P4B�.�E�!.�U*��(�5�g)���	b��rNÇ=B�	c��y(v	��{�~o(JV/�"�m!��f�q0"ɉ���
�qd��v�"s&g��i��V"^x�w�Τg 5���fvDA�&�X�����ax�
Oߛ�[��I�k!q�WS�T�Jԩ�����Zݲ,�>��~���&D,�-�a�rcPLy�� �bf4�x@�D��0����.�ݭZ�G�D�!���!&�KD�9�{�;��3 �O��� � 0TVw[��,P��t)�,���ݖ�:�+^]!�<?y[%��H�Q�����L��}ȣ��iȬ�H��Q�;2!hP�Ԡ<�D����7�%HrF.���0!�.t����]s l5�e ���.w��9���PLŸ���E`�������b�j/K��L�#���UpMKo�E$��<� >���ET2{.Z��Fz�h�s�������* ��b�;���pc�'�ScQ�Bv��T�c����gAXra�f��������?��C|���QG㤐���t�gΚIӔ�~Yo��e��Z��r"EeX��G����r��c��B7!/���$�ǻ�^@A���m4��j�U�9o��ٳ��nȍ~�� ����w7r��%!��~m�:6����S,k]v�7r�\"�w	ގ���yW4J.�M�9r��R�
����[1)W�4��Cq�G�ez��䕵����μ]�SU�k1�-�n�~r���7�4f������N�c	8Z�\1�\̘�������u��;4g�8����X�ڌZ�AL|2�V,=��cڟ� z�z��a���O��3R�wʗAjҦ�<6B��h��b2�����ȸE�T��\654���G���BҐ�X�Ͻ{b��/����wNz�����!����7�+E!bo�[�Ktf�EvI�x�u��V�wO��9{��w�"��qF�{�����y
��X�[��|6���lY�M.����9��;y��V,���Jt������4
�N���� �{�}�!�D)g4��?v!ʀ���,_ʹ���)ݓⅽ��/����r��bޜݶ(;=�Gؙ�/�I_y'r��\P#�55����E��j�NsGo��"w�4���\i"��xbR�����,��5\Ɩ�ԝ�����D�z݆.ƣ� bc/����|܈�5cf����+��l�b6�AR�<v0�:�̶�
!���ы���.�ڞ����5E���c2Vd�1l''+���~��;�{�)^0�{2���P�g�X�d� �9��RDB�J��q��z�I�J���[c1CԖ��bȡ����֞��^�Io [�!Ӽ��}����h'��%�\���w�.ۿ���񆗦Q�L㏯5q�V÷|�Zm��פ�D'��m�	[��ǝ��qw�9N�R��<�Bv��%)�~iL�>��x�3|1���y:H��)�����E�Qǯ�]oA��R�����B��<�-��3q���B`�R�B� �������&�-S'a���E�˅�Q�(Ζ������#!�@��ٜ�����ރqo�뗐�����tO�<Q�N�	�o$*	�(˚<D�`с%Sھ�Bqb/E�c����P�v���(�ԟ�O�`rmQ��#{�e)@Y@T���0�$��Y°���L"Wf<ʮž_.t��j׽~���~�����}o�k���|� ��;�Fn~�T5iͅ�b��7�9`z@�tB��`�{��K
��$�M7(yr�VE*Y�u��[~=�I�Jl,b���O8��S��A�����O�8�@����l�\[��S_�`�U� "���|ON\� �.���L"x��OѤ�^��ˤ#�U�1k3>�����=fƝE���?��&��.-ܿ`ޗrH�c��υƫ0�<+�����!��D�m��}q~`����A���Z`ޖvx�a��#ǉ��C�4w�%��،�0>���Y긅r�ݏP�F2�_�9�>u͓|�ؖV3DV'��w�wՉ�E�\�>���G2T])c��P?S�}(���u͕�Z��3�O.~g�L���k�����u�C��9�Tˣ��q8QKX�J>�܎ wI88��X5�x��:�*a�y/�ܽ��Ȳ;�Je5)Ũ������!j	sj���S-��fAn�M��h���o{_��F��y_UEvI��%!�?�X��v3����{fL�B*p�%�nU	L����>ݳ�r������l#"?*3+K{ܻ��*�32222�x_��	�S[΂h��-w��?U�j�fd����0zB����~m�n̈(�~E���v%� ���%��?�E�K�=JJ��TN�JzTQl�
	b��FZ��%�����	2����F�ύ�Q*����[�1,�����N��B�z�n�� \�P����B�ϣL
����0>��3x��+s|�˪T�����GO�~��*�^�~�ÕG80~�08��9�K��ʙ��欬�n���1:��2'��us��S��T��*�[�＊��R��V}�Ss�TH4/'6ęSYο���}a����A���e-U��Ѝ(S.	��ɂ:�Qj�F��F��U��B'#�q���h�}6p�DkM~��r1�ˑz2M��^�䬘Ȑ�´�!�E����٤��F9H>�kǧ?��ݢ?�/��	G,�|8I�7���>����_Ӊ����v4��W��x�?hs�����`���~���I(~��'����Hҟ�#���ХM���Q���J3�J2�yՓw���/Z��O��`����@S�#	N{�4����[��;����?�xN�HA8,�¡�UT:z<\�hd�+���W��T��j͊o?�B���i����'�7�	p�˵6~��	���#񍨄E��u��IO�Y�U��.&#"
��$��}�I��6b0���i��"=i_E�|�/��h0�A$7Fc�4^Xz�����Mb�0�Q�� ���i�l0�Si1r%1�/���3� #ٿ�Z�r�r;�n"AY��\j�1�8�g��YtY�z�$Q	�ӼQ}�t$��7Z'4P���l��W�S�³0�P�rdV!m�^�>R��K�����:�ѕ��CDf� ��=��pAr��	u�)�3%���8���Hp<7�=���m�h׮�J?I�(��04*���]O�@��H�2nq��酠6,ViV�j�fޔ�PDk�.�/������D�&��kY%�ݞ!)�)X#V���t^j ��>8R�c�<��-�^,�dԋ'Y��Az��S�X�
��l�t)r�c�S\+��_X �	���
�D�@���� BC"F��7�+���c���{�Mtf+��b�ܞ�X�僯UR1���G�)�G��$:'C7J���t<��fX�Z5��bJ�f=��+�l��9��"��w= >��G�[�o�//�0����q-�r���Ղ�'pM҇���,�z3�e��0Wd0��2�,,`��!6��@OP��8<9\�&�����A��*��7	�FG3��$��n��ꖧ�����M������g��8�qљ�ӭH	*�5��̕ݫS-�>[�_�_J�~�<i֊P1��9��ô�u�]"9�o@{��v��:r8}�L�#��H:��7�w#��~O�y_��Mi�o��rr���B�g�RnG�j6��L��`�8SЖ�s5�������� <�C,�����\�U�f�b�[�[�A�ֆf&z]�7킪�l/w?i�m	�N�"��b9PJ�Q���u��t�~�V�|j�n��Cq���kl�C�s���D���ܯ�m1�h?oG#��+��р�0��gK$�1][O�9V�/'`C�ʋ��B��զX+� ��f+�6��9�Z��W}= ����(x���'�<!��nT�B�s�T��[��p��oy�r�zR��b5U�j5���%�^�_��[Y�^P#_ @Q1Ko/Q �	r���=��xX̗���Y�>��%��Ёɾ�J4�y�������1#m�eAE����S�dK'mlȊ�$�w�&F�]}C|PёqH_j�����~���*Y�b3V�n�\���^r}\�VVZ��Cl_z�g�8�>j~����	���t�㣗�����Q/���T�n�/�$�	�>�����ߧ�����[���ͷ�(l�MS�I���>�EYB�H�7F�*��g噟6m�WO��/���=F�5:M�¼���U�/f[lL��ud)_�X��P�I'C(n�=Tk�ҳ���u)����l��tW�����L��Im��0Y�++�ʩT[�0�|Y3�k��+�����3U�Zy%�5!/`��-p���XX��F�b��)�F.��	��nO8�/ip���)N��k�F(���Y0�:%F#	7i�-�A��K�'�Ŷ�؅�?��
� ��CND��F�����gyeΐ�_2�_k��޲��V����������V-�́�f��s���v����0`c����А��(����!��{��zYZA��/���U_��?��e?l�S{�W�"�	�|�(�?lnmwjK'���Z{��B���<����V��Z��{�6��6����z����p�Hdi��%�����g�I�֍��?�U���9Ҭh&<�<8��������߼���`����^˟�/�Yj����!��#�fZ̪
��%��3�ފ��钡�=�B�ag�ԣ��G��,��d0V��S�? �ؘ�9e���"�690������(�pؿ���6B �hL�o�y�t�#NQMLSvæ�8�cf��\��J��g�8L5�o|���v\�ۡ���S.������>C�Pvq��Z�M�Lt��m>ܝ�V�ŊFO�4þ.����x�ℵ>��^�8<�a��qgioo{�1f���v�]F8<�f��(4+�	k�oF�P��AV�u��9�]}%}-������W��<e|(a\�oI�D� ��Ќ�J�e�%�0ঝ��r���k8A5�ph]����6�B��7x��Ggy�E��~k�LEeq�S����*Z�|*������*�}����I��>��P�"��I� 6��R����i�MP�e������6~Z1��`�!��y8߳`8�58!> �M�Uyd���GH����k'��I[de�=��9:���mn�K3C�h��ɱ��~�%ˋmA�TI�(��S+<a�T�n���s�	�&��}�$�B"���{���B�h,TJ��9��Ʀ����K�$gNK�_eT��E-EbA^�a��cT�WŤ���@�Ф� E�z���!E΄RiQ2��kS����Ϟp{º:�ֆ��V0���)ߘp�wjk����X�`.��q�bꥨ��X����0RƜ�p��`��$�׫���0^ч����4���b�DL�Iĸ�����;Po��C�v�n^�7���3'�+1�^��`�qn�:̔�F�91����L�,�[�z��G���ρr���l }�3TM����fe*�2-�ahu��������6 ���ɂ,0΄tTJZ����Pu���i�C��̦J�u�zd�_�~��({&�����3'e��њd��(*�$R�VY������x�1�&�}� 8aJ�uB��4����U޶Ԣ�9�jc��`�q&���@lq0�VHZBcs�{n"�&!�(�K�!o��l�P�$��S�2�U���1>�_��B�$�19�bds��D0��az2ކ���F��$���6�Og&�B��)�	��i6�N3:r��0�VG��HS�~R]x�r;��ʸ��Ҝ���u�����U�J�����@�^Y�*W��6������q�0#���?�@x���%WQ2�o|ǹ����MG�"�G:(k��L� �p:�u�<I�~��qz��E�48GD@Y��\��Z�`t�	���4�!�z>M�,>�Z��<���0L��$HW�^���7�?�����o�t�	sJL��X��-V��>E%]l���?�Ш4�g�"{1���D�O����B���jm�P����2L�>?��;#H�I<b,B����c"�s�~�	����tL�E�"��;q�d��E��c9�+��yʫ�)	S5Q��p�IŶ�>(�N�W��u\��"�-�<j�p�Dcy�^�̙몾����~b�y���;O5�@�0+1��.x���#h��c�/������g�Ak����.����?p���u*_0�����.
RZ����Ev�N��a�@7������ȵ��1na��E���fB7�q�{�����R|�3N��̻
��g��L�51)F�g���zr&�b�ӛ��FR��C��o�i<
��}p'@������Z�$��J�RB1�����q�]�1|�hb���-���o��G�wx�J�A�
�8P�DP�RZ�-<�����7�ٸ2�@i�B�.庩�����׼R#^>����W�PÑ��e�3�ђ�869���Ȥ7w՛{Gs��4�+)�:7A4�fA6M��M��9c��|����?:��͜�'���lh�V�jo���x��x�F��7�I���Y���Wu�S�H�xx�Q�K8ƣ��~����7��4>MP=�z�a�V�C.O��HZ�eV[�[mV�c@k����^\��[�&� H�ĩ_��f�:U�#ZA�fT��/�d�SU[BH�Fj����"b������M��ڸ�-@&Ê�k�+� �M�$#�h)1��a��6��>ؚh��⾭�������o�m�m�����)n�	���%V��s�iF�v��Ni��k�[E�/���M'X�.U8�֔w,o%/_D1)��ӷ�%�%��5V��`�9������;>@;S���޳��4
����I8����Lt��ދ���!��j&�v���|:i�}��]rϧ��z�����'Z�f���Һ)�-��4�͞�h��QQ�) ��l&Tp�&�u�q�c.h�x��s���p,����6�m�N!�w6�zρ L��&�~�"�2�vV��Y?~�}�}�j����(utB�T�W�����xz�0M��� ����� ���(��6/�wO���#�|�ל{O�CD��z���1�C�|d3ci�E���?�X΍E��5��)Tp��������{�,��h�."�����49���S�l*l~�V��>bA�a����ǌ��g�t�y���q�n�'_h$D�� {��Y�ko��wu��+JIfL9&7?��ذW���[Bd ��6�<E�KU¬�2B{2��R_�(i�2"� ѓ!�V%���~ԩE��d����ٌ0�����)�
�V0���e�M�����d�vQ� �� j�v.��G�65��J�l�64�Y3�Q:e)��I�[!���!�bN�XV�h�Yj�����\F�Y7�_�s��揯ׅLi����E�P�=�H�Y���Z<��R��9�p#EG$|a��<��a�Jb��g���Q�y⒔n��N����qԵ��u��R��yuA�l������1��5kцV������V���}�WK�R��^,6j��:g�	�4+�"(����`Y.y�s�VGmw�yW�����?�%!GLd�%q��R���bD��Y��Uw��4h]���׆�[��Z׼�鸻�#�an�)�-5Hen���X�hPeg9>��(������+��U���,�3Py[";�Zh�>"6�����nwa�7_o���G�z}��qJ\s�(�
���(t���+"H�Wlh:�a��7�6_m�^���*~+��M�L��%��?�ز��V��lof�mAS�<����i����68*�.�c����	:ħ��;9���:u���0����QnH|�x���
�R� ��J���}�?h Q�f��[������l�p{w{���l<=C0ɉ��hkꮠ�����[2K0F;�Y�G����Вtfw�DD %����3�o��o���Ǚ���]�	%E�G	U���&�3��k�گ	(!��i}�J��z$Kfp�;�SӋ��L��Wr�b�����Lţ�KU[g� (��&�{���%z	�#������ka�Y�� ��	ȪCό��RO���2z�}�o�^���!zh���KK;/�G�^t����G_�}A�Y�d����T%Ȫ��a�Y�ò𴛅y�d�ߐs����,aFk^85�O�3"�W�m{k�>E��p�3�e,,��A���jl�[���~�Y�>cT9�ģG�X��d���yc�\F�2I�m�P��қ5�:�'���.`�o���$:7�ϭ��x]%���R	7��27xtQ����p�@>0�&kf���km�VkԪب��Gj�qF�-��1�7�41q�F�P�8���2��@�A��K��g:*���闳�7_�L�y������kg�U�\�	IY�wwp�Ҍ��c7��I��>����i�Lж$��/��$W~`�6��^��E�N ���8����b�[��oM�x�	�<�[V�ؐ>bz��Y��f�.٠rS��F���2�D÷�����a�-�8G�I2�d+jE���s �Bc�>�M��j0�A��[���͇ro���(��;�Ռ�n[䲛I��Em��Z�u�n�T])��r���O����q��I!m��[k����(�mL��J�W��l��܃�����D9v����>B����Ϋ��#�^\I�|#`��xWS�ћ/HrD�9B�*���H�8���L[�3V�"�Y�N+��j^n��y�1d����?( zN�>u��'��v��J��b�w0l����0l�%H�@�q�@zW|W��8:a��Y2�/�@�Wmt�b��G9�.�ߺ"K�î�r�4� ���,I4V�9�9wq>�Pz�ty8x�rG�_Y�G�nĻ
��{��T�n�a�4��� �1�y��%�� ���^u���[%�E�#l��<K���LrD����DD� 0.��bYL�N+��7�9�%t�ԍ�J���či�o�k���}�\]`=�9{��
���h|�S�nW@_�0g�5�}�����l; -�����eS�x~��+fK��L��ŋ?=��q�@rN}��w撻�����0Ҳy���]���	,�E3�w=B~AK�9�%���;{��ِЮsW��\����i�Ȝ��4<��t�.�E��ʬ��H���rQ�v���� ���aV	�V��r�ʱ��[e�Z���!B�Ϋ��8��Ȑ���W�������ɇ���э[}1�#C�6�s�S�$y�=�E}5M��ƛ1R��Jf���Eyq�E�a8	��%3,��8sU���ilR[�>�-F~��K�=����M���j;K]����K�p��e폇W�"L�0Oʳ@�$�^.��2�(�� �����w�ڪ�h-+^�Y���]�e�OgE;���������\����'�WV?,���|%��dLY<�9h1g1�1�Ĩ&"^]fǅ��C���'�����ͧ��_8�%�h�g5@z�	㸬��-��J�<����H�{��0�R����SY��qP�Y�iV_Pbq ��[��ª:@!/`���p(UT��(#�ɂ806��e���g�1{����d������ 䨣�ݣ$A�Ԩ���������z��#L�]gyh
3��9)*�y��3�\0�~	��z��@�\Ř0(V����1�W�Y���C���� ����ρ��P�Q���#�P���H�#B�@�j��O�]`<0�ce���E�7��r�J��mX��#"��	�}���?���?ZdC��Q�����{~��q� ,���`x�'c7�^��=��v�.���[�Z.\yW�ͪМ�1\�E�k˺Ֆk6f]�OU�Z�3�-aN�vV�2����p�2�;;03\���k�ȑh�*�x���GÍ>�����J�����`~V狏�V�HB�[�3�Zr��3�n%�Iw:[(K�&״e�R2�|�PCZ{'��I+��(^ӋMi�r��[U	�����}���6��[ϳ�x^xDpQ�,���5��ݿ�	���ʷ���f���Pnte���<AҌeW1�)q��um�KK+�t7&�T���:q�!������%A�>Y���J�k�-�ۙ�bv3x�/!J��V�n�T��nW�2̩�*񝗢����YɆĭ����K���`�%��,�]���E���RRo���WX��z3��K�{B40�'s�"�V33:�-�8�c�0���h�k��V��_�o �� ���n��8�Q?wǛ�z^7r�_��Ax��>���|��ӣ�]W�π�ß,�T	m������azSy�vw^��6_A���[�p���������bK-�U�NV�F��]�R�o�vN�����U��81G�	���YH�eu 3T�(9bJDGn^ki�|���hlP�i���ɦ� }4�d���`a��Fu����G��=�C�]��O�s	UK#��.�*�$Q���� ��Q��E蛓{�r0b���*�s�� ۉ��,>�����y%��s�,l����Er����������7�kL�ӆ�g�������7��n��Y}Ծ����.�[Y���ō�{�P��.��u6<lΞH3�����Et�ܞ�7N�� ��.������_)ʎ�uho\WQ�����q�3y���gy�)A���C�O�}���v�F�<�%���a���í�������9KS�9�� ���L�w]���á�{��zL"��$Vhκ��\PF�^eDG�e>@[?�N��ﱟ4;R�C���d���x!�-��B�.�sh"v#�:��Y�%+R�?_<G�Z9������zf�*�mk2I�0�g��h�a�s������7��\s��1(kN�b�:wcǸ@)���˄|�uAEBk\F9Ix0��i@�@y�멀����4Ğ��;��4���XQ��������K�R��� �J�9���쪎H�+�R?tx����j)� ���'�Y��j�S��PGk�ܥ�z���w���6_?���;����S������y�!��}�����������y���ݎ�����?(��h/}ϩ�i�X/��}�c���`�yL��&e;5
&MT���$;�/Ä<T��q��Vz���K@)�����:�T�IvO������c��b����u�{�-�xl��w¯����)�M�C. �^���mu��1"�����o4$=5��SqY�=u�^uV�,*��"��Uw����\���IIO�BߣT a���Ƣ�\�A�{"1����h� ����9
eI1���Ÿp��΀6��<}f��4hL�F��yR�d��~�9�S�� ^�E�.����x 7���$�����Gz��J��'��B���S����$�ǧz��E�u�	NG+��h���{�m#ߘ�fV>Q�� ���	���j�|�rә9�]}0ۏ}E�Ec�Ќ��h���4V�	��n���R�&[�=��╢�h�;+��"�lL7f��3�a���n�2���<~���'�Y��oX��fe��3�٦~��H�ݹ���Q�|�ԝ~*�l��O���/m������٣C�#��<��NO�1�<�`�`&�)�~������SC�o�.#:&�������-S̀�G�i�����B�04/��.�OF�Z+������簟��HU��+*��I��>��)���z{︷s���H����8!Պj�H�.����U,l��"�c>���%�z�����?'->�[g~`��ӭ*kai����&�n��|�s�a��###i�GѥO�p�	�&	�(��!�]��:�l�������}�a�n��@�+A�0JLnBj�������]*U�~��FCU��&�J�Q��$:�r��3c�S��,/r�C͉��V�� ��7O��گ;�+���f�f���}dUο�Q��dc����]����~���S�lʢ1�2�zb�� �znlmT/ƍ�$'�Ҡ£�hj3�Ӧ�\�q;ʀc�A�m�����ɭ¦)�jP�'��N�q[Y���V�1�Xq��fK�ɤ����j<nPΊ癶 	S+������ku\Х�%
��-��"���[y���X�Oha���)�LDR}@G���߽�1f<Z	�ZOF��������˝�v�<���U��azg�n�Z�}%�q�[�%���|ǆ}���R�A}¯��c�HI�w�D�s����D<�OzXTc8yG ��Wu~�[�p����l��1�5���,~���5�s���E�~}Um<�	h�{�?� 8V�_m����y��ܣ�y?����'�:����X��e��b4p�{4�W�Z����V}^��wz��f�~��c�?��i�A��m���y��߾��L~�wڛ����	����4[˿�s��ah;�(O������@f��]���D��!CP�0'A�䑁K������?�V	5�`+�x��H�q8w��w��ه�L(9L���H_���Їc�D�������Eau�츥�I�y���0�-]���\�z�6�9��qsN���,��j�$��N��(ۥ�w4y8�ߢ^�ߑPF���Ө���Ss��H"�՟kIP&.Q3i+�=>@2`�mC3���-e߬�|�4�9����4g�^������P$���OjΡQ�/5i̩97J/juDӹb+"n�&��+�������P�+�V��w%zb��/��j��gd)q��V���*���nYz�d����j܃�B�¡p�]o���p�d7Gvj��G'����u�O9���LM���:W"���7��ֿ�W�� ����u�\]{[vf"�ܠ{�f���Q~d� E,�SZ�6�5�5K�����H(d�	�Q�}�5�g,�g��'�
�4{8�b�g?����-���{�������7��z�+�3c�f����B����U��Hd|�VC��4��������ě��̔�X��p:V�h�)��~����i�7e����i�)�^��LZd�e�	��t�l�tR�
.�h����D����!Ӡ�#��v\�P�,����rHVJ:@C�
G��P^�����8��	��������e4���
�a�x���[�����>_+O��b��V�����[j9~��=�R�.�z�����C{���6��,�d�1�+V������E��'�/{q�u��y��/��J�n y���j�E���Ӕ�H&*:�}	��(e
��f�#FH�S��3�F��o��v�0���敞�!�m`��r'�n�3�����_��-�
�������ם�����i�~30nڟ
g�g21&��/b��/���+���w�:�E��^~(}��6W�����*q�]ٚ����)�D� /�ǰ�[$��{�0`�{��p�����,W��
�j�8��ws\���t�P_�#��M:&���/(;j���ϋ�Q����
P��f�U���~�R���u�I��s���Xu��-���6�<{@τ�	�~�~+�x��P�T��B�(fm���q
�i8�!�<��<����ɯ�Y���E��`fZ����Ʌ�F�%��6�b"7��1�S�ã{z	w��<�,�0枉��/
VU�'�I����<e�\�^ļ:�F��E��y��`�:6��]��8��ͽgy6Q7s�|��`Y.�TZ���	(�t]�l��NyRVȓ��W��O~���AG�,�E}lN&����	�+(y(Պ�m���|�As8f����-j�=af�J6�Hb���簿;Θ�����׮7E�������������	���a(G�MJV��x3�]I�/N��dD� 掣��i��/�ʔ�u�*�v2D��t����:�����B�i�[<���&�L!C4�x��jyjl�8���	XO��fㆢ3��;@<9�0~��lT�O�
H���l�j�)[ʱV*mPO ����3[�P](��e뙫�<��D��[� ��v�`�Oȭ7	���fZ�� UP&�!�;�6|�M���g߶�����,*Xw~PV�J\H�N�У�FQ�"�����6�U��ꜹ�0|��O�7���vq\�a�mHn��o�r�dE�9]��x�#�?��X�x?H#i��[U�F�S~_����Bަ�q�T�ġ�ӷ�z�������=�cSÒ ���h�P��Ɲd��-�
~����D�z�op@Ió�Y��[��8|�FP�T��^�,�j�@��%�sC7�|~\^����Zo���9�$ť��d��?K��@�Z7���aEC�E����<N�E>��B^�m?����_�Gy���vieV$�5��+��O�x R S%p9#n,��Ym����xw����I�n?��i7K�$�<�I0�6�2@�b�����[< �/��B�-DP*�tQ���4}mD��|�m����D�%&s�7��׵1�KL��qhܱ�=�2M�z�"I�PG���F�F��S%¹zj�Ř�t5@�Q�y����rS';<���2b�I��˂�E'��6��+�v��r�X	֮�7"�x�Ū�Q�E���h;"���������cvmʳP�����}�3]劑���c۫:b�i����вzJM��D�0C�N��ojF@�S����!t�Q�՞���{r����r��^՞Q�T��1�y,^B�d�XI�;ch4p	�&+���D��r�4�{_��������Y똃������Z�/����ϗ�@��t������C�s��=����2�&�A���N�y�-{��9h#}��	o�Z��yrxV'׷>� h��k�زrϒw�+��g}��{���4`o��,��C=VЈb����<k0��i^�,e)�@)���pcg�i��iƑ��p��?�ן6�WT�E��Æ��	��m�'[,��/�%��s����t���J�bͲz�� y&I���w���ט`��B��^H���g-�9�,�i^��
��~���w4|��Q>+X���FT�'�^��N����8{!��@�K�3��AO�
�(#l�2t�fU�P�4�M`��S�E�.����l�m����lo���cf�#��l������?�q�k����w����q�u���󿶺ֲ��ڏ��߾����(�MЍ���`��;Sp�|4�c��s�z�3B�j�_�e�������~��6_o{���J�Ŗ`AY�;{�ݝ�g��4�4D�����9�)<9;��~���.��̳�]��ix���ʂ�Qǯ:�ҬJ��ZuR?�C�	W�s��x�����d�M]�����8ܡ�z�ю�j�5��<���a������8�\:�3�m�|_=�C�!�#L��JP�uu�$w����~$wXj�_�/&��L�ӗ�X��g%c�Z��A��8����l�~=�\FU�1=�I�c=�1e���C����DN(��KA�V��Y��0��K0n�!�ͤP1�?�����'&�$E1l���d������(��Sa�O]����Я/b�/Ț/9v�r��F�g�
kCBq��#�q�o-�eG�8���qƂT�rWx�����s�K[�-ΔfkE>�<�z;��Xm6��5����ˠ���I�j��/�}�"�������@HX�1��1_m�G��z64����^������*-��y�r����#��0 Z�+c��S������Zm[�{p���R��|ꃡ�>a�~�JLs�ly@���0p���� Xl������ΎD:R���S��&u)��O���9����a����7�n�ð��'��x�FH�>f��܂"YN�\P2A�'m漷�� �ڳO, u�\�׍�	ۊ/��80��[h��킓\
� �C=���#\�CP����&̔��W1��[�~�z����d��Z��f:V�B�s�T+���M�����\o7�K*�-�B|*_�Z�ݾ�כϬ珮�z:�5����?G��O���u׳Z��UN�}���/cA�A3LoW��/�?X[������;���`�q��!B���1�3%�iL&��,2�FVu:���wA��p�؋/��)��~x��k6������]��N�Q@��=`9��ˑ�\)c��I	Y�ql]���O4��b��>�P�L̞̱�1�5��,	��$HP��LNQ͎k�t�` �/�kR=�^|iN�ZTjG�<8j�/T�+��;F�KzI����E.ЉPR�}�}�0"o�G�K�.��/0��j�O�0�mJ�&R $y��;�����8�c f8�����v|�{ B�}$ ���S"�\��m��֢�zV9F�1͇(��m���14:��������A�(������V	�RL�(������]�윟�H��q.
��2zT'���a�]�3�`p�4<��	�zP�$Z�mX��-��N2�0���Y����>`��6��(E��t���
�4V˖�A��Z_Bʳ�cW"��Lr���Tà�cX�1�V%�8?R�D6uf��tI��r)5ұ:�*�Y*2hI}�#��dq��������`э�q2�F�ϗ�=��mi3z�	�b��+z����ThzP%e�p�Ό��.X"A^<j���^>�͑O'�����D���a����#��v��_����2������>I�h�8��g�}0pſG�?߸haf�up�Z�%,L
��%��3��[�_�l z ������)����O��������Et�oG"Z��Ʉ�\&#��?΁(���m�q�K�o��ϝ��>��};>M'������Z��f���y���4	Y$#��w����C3��\E�5H�a�:���f&��
����=ix2�"+笗��%�����<?�o�m|��Z�~Zne��5L{��G�K����T
���h���kg-���k��WW���k2HY�<��mZ�Xf3�����0�:�"���e�0���'AN�B��iJltfd��"`���Q���Mz�
p��-1�)+�E�<��&@U�f�������оat]&�ܖCzפ2\�6��_X��ƭ�(##�47*k�'�1sY�AȒg��I[%�E�1�[6[r�\��Q���B�ҩ�'�s��_B��M�l�׽V7Qiwm�)a@%,��P	�R���S�Ƣ:��Na����u�7K֯��ɓ���x댫ʼې�c�1F�ĉI������������v'�!��~F˄�����I8"UsU�O��D\*C6R�d��(��9����O�	��Ҁ�@1d�ò�I��w|e
��Ǵ&�A�-�Ƞ�iV Q��\ķb4s:�O��K�p{s��6��������FB�=��q�í
�E�-�0W'���jd��ڏ&��)����-�Y�2�A�<��o��E�QE"���I7��͟�����'L��j��_V�V�Hlԏ*��R�r�r6��O��?�b�I�"���,,Z�H����IЇ� ��]l��B�G���$Et�ݏ""�(��Ĭ��-��F��C�@J'0b��MM�+�;Յ�!MZ��&��}XQm�OW������4Y��Zj��$杖wQ���K�D�7��8׍*�)�7H�ɀp�Ѥ)2Je���,���y���ܬP5G����bA�Vs��!Y(�!��h���dv�Ɛ[O�M�ĂUјҰ?M`f�J2vR������~eTf��	�0�"�G�@�4a��W�4ɰ��`�W�a<3Wm��h����h�۰��H��s����}�>w������s����}�>w������s����}�>w������s����}�>w����s��� � 