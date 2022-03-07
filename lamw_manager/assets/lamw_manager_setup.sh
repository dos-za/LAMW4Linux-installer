#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="222478080"
MD5="0ccd7855e07af618980f15ec4f0be0b5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26608"
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
	echo Date of packaging: Mon Mar  7 19:25:19 -03 2022
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D��/�,N��+����Nh� .Å���i��W�v��9nމy�||���aIJ�����!���d,�hq���[��*��$�#_��,�M�����!\K���.��=XK�em5�y��9�Y���H&�C�&�����<"!G>��2�?s�Ƶ�Edx�.�H^D��Q�p.�Jc��o��*���N��]��y��CZ�)E$w��jߐ�PU�Ʊ�-;}��.�Dg|���E���A���G^�����j�!}�t$�S�Hi�2G���ވ|�h��]�w�گ���\����kq�Pa-�0pV7��E�?�AƝ$��D�1i��ҙJ�"㪻H@&�7�b�R��x�o<���|�&/�77�F�T=��R6-mǲ���jf�f y�6��7��K�˲� ��ñ�)�ѶO�s�趇����S��,���p}�P���	�X��cHQ�O��-/-���&�t&O���E�S ��"�r`�'�x�#Jɾ����[��ċʦ�	�ƪ�%���O\��ɜ�n�l2ك��Tʓ8����OPq�@���umӡ��;��zϧ ��'��l CK�f��њ�\�\,�p��x��R���V�����	fw(����B�#"d���w��������(���<�[�W"��,����*�%gBz) ߫��-��"k��;���_N�웅u]�<��E,L�ٛ8��ƒs�&�䧵s���#��J2A���e~�2��Y���������#V�x��%��� `��v�"b9Y#F�}:\�Egc^��[�D��Ƙ�f��n��r��px��r���6���,+�ZD�9:����/��z[-���c����&�6�2=$B��!\��N!t$��/��Y>��l9P5D�6�S-�_��M�w����ĥ��Q,\-�w,i�`HIS$�4;��]CZ�|�n��y����Jw��L7P?C����D���R^�`��͕d����9�P��ȫ񤙍l�Uko��+ ��S����h�x���pW%L��w����p�K�.�F���{
 ����e.Y&��Dv>-���=k��{�v�N�����B��쯈���f�uԄ�z�0����i�������ڄ���8���r<�֛�W������~�Mm쓦�xP��рu�t�b�a3'����<�R�x#�"X��D�������>)�E�S�Ͻ�=�(=A9r�,��lӞ�G���{Lx��}_i�h���[�Z+� U��&� ��?�&1[�ť���B�6���I��&���:�|=`�,�8תz)���6��]8{	�]��GYzK��x8\��.�����ى��hP�F!��':��B"(��q����5T�	�i4�ߠô���^2K����B�f�R�>y
b7,��.R�
w}���+����A1�+lew �A�Wdq=	Zr_�ʰݩRO�-� ����}b��'���9�o��jt�GO�=��H�mU���c��r�І�A_l����srˈ,��X<\mi�4��BJ�c�O�N���p��� ڨ~���:��X?She�zky瑱JkH?�2���ґ#s��_~	*��0#������$���9ޤ��$��k�>�QW�(��TC �3��k^�wx�����o��$w�!c"֥4`__��9Wj��/��|I:�rlȊ�F
/A��Y��V�;,N�ʬ�*.�����juIB�=�S0��������.N=����N-q�uI��7�^{��L��>���~Bsc��R�K2�Um����m����U��T+�ΗEѻ"��e��i���m·S��_���n�Y�}>�@s�H�7�߅h#@�,|�����J ��O�4��Dp��ǔ�Hˏ�X�Z���u���%R X�co�����]�Ÿ4T��S�Q��$�y#tE���H�a���G�y�uʗ^7�U�W�Z�$9:�Om@\<�|����מ*\���z�+��Lh���aV�)��%����r�̍m��}����yc�`���`:���E~F�Qp ��D$���W��h4��L?z���ٸ� �B)1Z���D�IK�;`SD��jI���] ᳞Sm�--�}P�3�g�sAq�j�GU~v�x7g?��1�G������yO��i8/�\0hV�b_�� p��ӻ����`YmC��T)�\�V����>sMۛ)��T��O���>���G�U�n�f�2w �����`���h�8/����d��2p;���R~��+���� Yt�����3	�h��ൂ"���̷��#z�Q2�Ѽ��[����+�rah���qY���ܽ<�,�dT\\ܬ�������$��u�Y�ޜ��v8�2�|B~]���k/��K���G ��U���/�Պ��4{�w�O��t8<'
�
ǟ(s����)H��a0丈�)u]P4�ft���<��D�å�/2�8��K����EZ�@:^��Z�>^�4��+�܈�P^���3�_S�ھ���k��{qI�&�P����II=B6h�R���_&Z�d����K�H�%!��*+�G�*����~(th�O!���1޷�B����������~�7�)\]<�h;�p��r����闫ص5D�(*U��C������^�����X|�L;Mǟ�%���,-yd	_�a��� F�\q��(�$�5���?�[f] h��z�����Fߙ�(�]c$r(�+��8��c�f5������<V'�>R5�d;Q�j��$_߫UW	`U�`�ݳq鞕/cȮC�>�܏x4�ic�+>�D����.q�+��j�b��&ᖱ,\j�Ņ��
@6H�D��^6�����_���`a��~Cݸ���[`#��_�^�c9�1ZM��H������	�`^ͯQR�Jj��B�8$����+���.b6���pG	��tј���=Bm�>r\��c�����3��s��<b|N�&3����	҅�])�Q:^�#�63�Z�h�����MN/&s����^��h��l`z���#�*.Y�j�'go�1�G�O����`Nb�ov&�;m}#\N�$Z��2k�.M�^���2��.-,o��T�����
��J=��3�U����[|U0ϱؿ
��Sj�;�����XQ%d�$і `4�2i����=[�7Rӵ��eu� �ai}vY���@l������ig�P�1���o�R�}��s�?R\0�뻓Զ��"r�sP�mD�>������-LCA��1� 	�W�I��-�:�_�,�`ÌCĻ���=��EOo��W+�'G��J)����	ϳ��2�����T+|���A�� ɰ~#\O��i��5�_���	����6��My���+؛t&B4����������J�y>/*7��Ǐ��y�w��c��n�a���U��yY%7�a���R��I*��f\�
k��(1+�^!�v�<�hz��r�i�K�[��Zd���q#��t�">�W3 �VV�&9?x����:5����d< ;�)rq\ V�%p����8��|����EBgat����Zf�8�)�8(2��,�!D11�����po��#����sEL>�/WOF�qE�\��.��F��U�)7�S[�W~f�s$O7M�6"!v�U�vK���1�Wծ,�L
�r}�ڟ�<G��XҴ�+g�ޭ�!aH5���P��|������Yx)�{���K��� \Dp�'�鬱,Ny't�a��ҽ/���f&��)4.��?����*��m���;9��Ee/�6��~�c-���j��o��mvnC��m���v�� 2VB)� ����z�&�wHFx�X��;���@
��ls���Ɩ�8	�+�y]���i�[��@�A]�q�@�c��6������a�Z��]/^��+�Ч>3E�xdD�MCs��(wuu�_�x�@��s��G�����+O''ђ��W����lս��i��kD�{72��go�P�0�{�'U�]fn�xSׯ��Q�����U�Z����ʊ<Cr+��i��P�S����K5#����s�|� �ü��{�SC��8�7��o���s�k&�"��v"�����#c�⠇a��<m"T��4:8��?{.֧3X�^�=*^��:!x�M,{�gi`O2݉,k�Z
}d9����*��.H�k6"�]7+������h�]�p���K�%|\l��\�Fj�+@+T_g��R�g;!�:�x�4 }��8�6�dt��w�GC`4�'r����^��7eu7Iĕ�G	�r������X?eݝ��Q����>���'�)9��e�v���2v��jI*˫7:�pƈ&��"��v�H��J�'Q��F�K����1:��U�9�G���G����5�Zݚ�Yל5%��щ���V*4i�@�x1<��������M�J˚�i�i�BOb�-�VF���8���1Z�Ӛ�!c֢�����t��S��D��q�c,��4ur]��n��}|��B��������M�t�cG6�9����"=_��St~�7��3�J��uhzU�##<G�)�19��/R�o�}��4�X%U�x�-��P��F9D%`}�t������Q��N����M�����&�vz�b(�QgV��/�H��!�`,'�e~;/h���
4��G#?c��GY�%�[/��J��#�_k�[�G����`�m��0��U�urKM<�sU܇uT���eR��
|�F�#�Gy���ĭ���L�~�-�4�x�J�����oR�n���8�3�
�������G���˹z�dͷj�9p��6�e�|RlBa��O�j�*Ve,!�]���V��c�P�) l��5�6ޤ�X+yV�Я
O�DYQ��oe�!o��
�4usIB�-3�B����sk?�O��`E� �i�-�;@X.(�bw��x�I�UrZ<*���I/vtژk����M�?V�W�=�v-�[�|�uq,�FD���wޜ���w�6��MZ��_u}l�U����nX���ͥ��hT�7�Vr���<�bɧ�_��XQ��ռ�N�J-�2���Ӷ d%�>@��u���+8KF��= ��_r@�ȝ�&���>/k���>��'�U�:���q�[sA���cRa���3��|��r��Ka�� B?Y�8�)�o�D|���L��*q�����r��R�d����.���)�n=~W�7��m3��nX�#��1_���X�N�`� �"��-����th���;Z�d����P7ﳍ�9j���[q*A����(b�{X�~;`B/�\���)A�{�w$���v�W�1;���V�߀!�A��Q��j�#!u��V&�h"_e�G������Z��R��Z8+	;]��sm��A�Y��ʣr7'���V�îX]37�*E ŁI���b��&W+�m/��%.yץ͡�c�&�A/Z2�V	(�P���N�(4�!,�x�n����������U^�-��u���,3��"�%��_j�'��Y>��>�^[�Γ3$.�8�D��$���FtvEe&��'ߎe*vI8����[od����H,Y/�h�ى.�+
W��]F�7�������?����޶�3���fG����9`��Q����98���R��d�5V�A��1�O��U� ����}>A������ �PY������`�<�S;���3=H!����(2�w�6q��O��w0��C���
�uMi�V�R�]?*�¬upC[�� �4F����蠝8�Щ�5)�1�/���(�5&�yIFBؔ��\�4$�|�����v�t$�jM�l�I��3`��1 �}��V�EF�~:\N�8>�#��c��{�m5��	G�7��T������2KzK,ma�{�CD��ȕ����^Ia�T�eSq�>d5��"C�]��]��J
��s'�T7|Pc��� �E�.��w-D�<z��ǀbщAA�O���`�J��˃G�~�9�?�����R�2����'1��-��3���X���"�X\����K���%j��}�݂�g�k�X�wş�=�7�tk�dk������7o���n"�:%��7��5?
�l"��G��(�F�<�\��͆��e���S�("	�^��%X\���䩌�B�m�ǵ� �����j'��T��V��Q�aW�c&��{�H�r]�Y>yðz��)��@�9E�A�B�F���њ�f�v'�=��� E��G7q����(`I:��r�n>>p��(�HT��K��q���1B�=�q���?��.�E����%T[�/2���>W{&� �1�2�Na~�c��ȳ�ԝ��~)��Z퇧�9�_~N�sC����7�z��&�K����F�����:�4$��K+8R?el�̣���bp���MX�w�{?����<�f�@��|���N����LS4�ϒ�
�I��WF�nO�\�*���k
7�8Ie�j��ep������:*���Ty�\���ݶ���>0�٧�>���?u�آ��ç�=��+2�/u���I� �����hq��G���k,�~O�a� ~C���,0�����@���M��`{��q�f��1�J��t!����َ��k�״�pH����
v��.��y�����e`pD�\A��}�����_v�_F0�E��`�pL���:/7x
�h�h�W�_5��!�F��i��
|́1��m��󊦒�Ǚ��ӽ�fk�b��D�X�"7��t86"��Ušklτ��ƾxm|�J{�C�Fr��Q�p���1�u���0��
�a�����e��)
�foq�����kW� VxNt.Q�ϧ�3�
ƞ��9�_6��Rǽ\5N��6�=50$������H���t��6`�t�������Ҝ�2�頷 �(A��R:�|���|��D�'�T�8y@I���Z�΃�ktD̪8��'v�!0�6�+��8�X���aj��̇�"�G���@�Z9s3��UF��=�ǻ5,����g.E�3�]/�n�����1�*��$T��ץ���%�SO���mR)�^R�@�w����jx���o�����*DE�9Gg-g̶by�����J��:�0e<�y���{��V�R%}����B�����"�Ű��'V:��#�������iC��#ǻ��J�e9�s|���-%Q�3$����G��dj�o��-3��!��v@�L�����E�'`
g٢(�������~��A���p�EEz�]���"ˎ���X֦#�s�a@���"�>�,.	n@`V� PMDo��H8M���}���бڲ�v��no�i��_��kNٝ�+��N̓؟8�\.�?��՛*!�iZ��]Ɯ���0'��b�w���0�y��O������K�$!#Bϛ�lr�fJo8�+��j�QT��~�Ǒ��:>��G���rW�[&D�M��k������U��	5>(u��P/w>گk�ʮ��g��
:9:������Y_��y>ѓ���)���t1Uj�tĲ���Y�3���Es;!��ܐ���E��|��q�{�X_�2wv��vs��1�Z�_�� �9�"=$�������z����1�\+�v��acv�E�zY��1��-P�)�B7hk�C2;�����a+K���B�k�$b۞@I(x��C��c�{����ܵ������1�+l�Y��q���̮�o���J�D�$��y�oƮ5�:�+;5t�[lI���5	=�3�iz�A�b]|��@����i��)�/�ò�7��ڹ��ϝ|W�O	�U�1�"��`�!�zS�4$�)6Oz���+J|A�tEY�j׾��E��=\�{��-��N��˕Y��8T�����i��򂡀�!! a�U�q9��;�%j��x��.�O��0s��ʘ�\äB����G��dԹ��-I5�p5,UFn���v+��9r�������U�e;z$es���f����¬�6��Q�7)+kM5U��������ӗ�EʢR��U�F
}�_�}�cx�W�'W�����X��N���9n���Џ��?4ի2���C<�`GH�d+�������DhK(=��[�7Y9�o�,����]�M˲��Нk�P�W*򩓎Q}�_�Dr���o��4A������Vc���Y�(�c:��VOr��XWH��^ڀ[��DЁ>��ћ�j��]�b��ʕ.�=G?:�e����-�^8�?U6#w�+c��4�%Ԣ��28O�I��v��3ߘ[�,��%�!���ܚ7P���~�ؠh�$��u�Ǐ�����/��E�J[�j��ϵ�[ o����r��J���������>z�=k�m�|��F����ݤ��U-X�%<TKޮ�X�5+8T��@	����js�h���n����b�Vd�u�C��u�m��չ������&�T9�p���[�G9��'�$�qӸK��=?�����v�P"��K�����p!����x��V���8�Ks����J�	��E�;jZ��_&�6�x[��9v��?]n1)��3�F�d������-9���o���λ2���jGi6��I�;�S,�D��b��x��`MY��n�HGq�������'��A�gr�)8��}�̫�����~d�n�r�_�w!k���¾�K��X8[��L3+��~��'u��)�̱��ݽ�c�Ͽ�o�W6�_���������s��zmy���<�����O����/\y��Y.���零�Q��ܢ�*�e�0�c<�1�Є���UR�ٜ�r:;؛i�&$�괖�m$�7��r��%���r��1N�\�P�g^?$)jE�)�w%	a�3�!^iZK��Y;�QZ٠��`w�Yy���ƭ�V��r�i������U����W�V����x3������aA��s@��l8݇mC�b�|�p�*�[ߤ/��JYӜ�!���|��g�g[�&<^eR�3<[��R�����G� �'��d"���K��sfl������9O&�m֗!��Ww��f��D�iA���9Uڶ2I�Y��_$[ �p� s�Ǥr���#G�)�H�zS�@+x����
��ѝR s�d�)X��@����<b< qBF� k�Ո>yh�#|	��RТ��١U5�QDR���R���B����ry�Vv;��^��Շ`	ϼ_ ���g��,g��<##���7�nR���L��61���� P[U]�o	{4y`��}��W��rm�����J���q-�Y�M��r�����i��d��3�8�'s���߈Æ���?��{����?)Q�����W3������f������lD���Kt�8�L�'*�"h{V��C.�2�tZ�ِW3k�_�V�/lk�{�/ʶW�1�\U�Z�+<�ڌIqxwU�.h0�O�c�:j��Fͦ,:�h�>��֔��{�LJ����[����Y[W�.:\WL��t�c���ˀ�ZC�&��#��C}��o��fp�B����b<�i���q��\3j�߃ɭߠ��>�|������A��ԓ��\zNfykr8~i啢{��<rl$�CN�N�+�=�a�9�he�lX,~�P��_�������+РK�d�� @��0>:����& �~VQD�σ���T�5��7����#Ku�,��Wp��`�$'�r�s��<A%c)�sYM�7�<��g�)y��ս�5�_m�y���L[K�TQ�O��<0�c���_�f��ưD��"*e�rPY�VI;���4>& Ƞ�����xޕV�WQ������13M�&!q�Lg������h��� ��ǒ�ǃ�s�p$x��S�(;0"��Uf�5b��d��	�l!/2��Ɨz��
�������O����c�{������A`Ҧ���k���w�ݦ����zl�=��g[�T�i� 	|0-ҏ8L�l];T&v/�8�!����x�ư��Gl{�/&����jP"�<��4�U�P�au9����Yo��}���y��_��Ψ�pǊ����9KYC@Y��#�lzplv΍.U��/�|�&�E�%J�j�~99~8�rC	ҭ� 1/�Ճ�Uk�L ZS��1�9g�V�m��Q�c�"�s��!
�tXG`�3#�)m�M��)�bj����}qȜ��bˆJZ'�eB2���3�4�u�=]��KQ�p��L�3Ȍ��_I�O�R$�~�>:A	���7|�5�ar!� ����΃�"ku��~|�[NߒS�@����藮mM^;���jDW.Bt�J]�<>�:OJ;x��{��ҜS�ocR��d�k��h���4K�x�d������T`����f��i{��/�u8��:�Q����4"�]�G��B0�,�t"5k�c�ƒE�(i^}��na���Tx�G�8ez˞�����OF¸䍅���e��c�Q>;���ʦ�A�`i�1��P�)؄�F�D!����N'���h�,XS!Ȱ���MW
	G��d��<�g�t�Ό��2N+�k(�щ����\��&9���=u={���d���az�&����'-��S�Ą!x㞶��-�q�Q��1{�����s��^�l��3Pࢱ����f/ja!�P80���7��7�e�*���߽�dn�=C�]?��dZǟ��Fj	P`7C~U2���"��}#D�Qe�.*�D�>�0Z�2剜�eX�"�í�"�.MDr���_�2���Af�w�ʄ�QQO���W�B�Z�8�?utwU��U�C���/��E2d��	B�u�a�n�_��m�z�}��f�Ǖ(Mֽ��#����\��ZgQ&�����X�9����c�q4.uJ�)�˵�hp��:0큓�>�׼��1?,B�!�0b���ow�Y�fB[��cw��[�;�ך8\c
�]�]�R��{�Y���*�8i~=��D[uP�֚���Nj����@�j�_K{pާ�Q��)/ N�g�Z^��7���K�󤣿7�6�L���jxJ��b�L�6��v�X$�祢;�I�#4�9����W���*k�pٵe}��gG��,� ܫ#'��0�� ��#�Zu�8��=���n*��.��_J(�i�5��@�Y�+�a�c���aj�ζi
���F9p��M�q�m5��Qtn\%|[H�	�S�M��}���i��t�?8Z%C΍��5��49`�qh��- 	3T��,�ҲYd�|_c��9_ʲ*\B`݉`!&��"�D���y"|�+.4k��Ǔ��J���wG|���&h��?�m3�Ƅ<���y҄#�8��]��n�Q�����c��/v�\��嚎�.>�b[�!�o�)���_�09�_7 �)��(ϼ��<Ec��B��	��
,�#�	t�`�&����d�̡��Z�=4���Ju2pFbż�x[Ӹ�g��h���wPhju_����f�[��洫���tЪ���昧n����mB��U[�/����=�p�$l��.��D���#�\�3kr�;m��q�X��ŎF�V5��i�u6$㚖��Gs&�:��o����d��A�%طR�MF?�$�-+$�-)�KWD��p�ԁM�+YɇL?�A�u��(C ��?&X%��J/��c�<i*9�
���.�E�+ftH�EJ��dT-кE�V�bc�����'�+��IY�J�E���G���U�뿺N���(�$a��Y���Ybj��2
�0�ӊai�te�mQ�apU��]O�a3<����
��a�k�v	(8J�Z�\��,�UUI2��Ip�eh�
���%��"���j�i6�f��}-��r0LȮhRa��+���(�+X�
�O�����0t�{���w�����,�Kg��X���;v�8N������%qɾgdw�9&�A�X&pQ�{)��P�>��.-Q��0AG'�c��꒷��*"C)�2��|c�����L@v6�<rT��ye1��D����n����3yV�~i8��;�Av���u���Lt��)tL.��l�F�����b��#���Q��_�!!�0|^QSjl�_�6�XRQ��_��a�n O
���@ۏ�93`�'o�{K�W���ծ���X�7�J'rX�&��^��n,�B��GNV�=�Ԡ'��}`t���_n����[�us�L�K' � "�3[-x-Ƒx���a��%��7��:,>I"%�v��&˃���Vw��/:҆T1���]D��c��\����ٴt��sE<��$KPg,�U�6�O�6�dR?��p�xF냹�Hڦ�0�8����`7��j����P2��8(-ϸ�>Gb��#���'���f��9��¯c�[�b��%�[Q�Xk�"W&�û����{]��=|�
\��1݃��ݫ��� #��@��bR9�g�[ Z���j0;��`ˈO�l�M����J:f�䲧� �,��S�, �3�Ӽ1��dJp��F�|3���ݤ�7���9�k�����VSL��3 S�]F�[�ST3�>�in�!�s� Td�}&�"�q����0�����ާKq�.��ŽKs�1��3NJ���zfeS�,ā��H��!H���`;���
�����xA��od⇉𙄯Vr�!eu��Ǥ��p]�iEj��p�B��"�`ʺddK��.-8~��o�7�>?�.���%����w��Њ3�C��{*��}٭3`�n��������<�u���5��]���вk�����F��c�$'��Ĺx��|$\��[�6e�z?��I�<��6��T�ڡ�K���<o;�,���W/��kj$0�R��������-F��Q8���O-fݺV�΅Tp�j�d���M;{��Ť�]�5��9MO�|)�k���:#� GH�D�5Z�3OQcr��Z��=��c�RM���|k�~F�M>��������r�aY���MV�aP��_d7�	ր��:��O�� �P�M�ZM����	���"qn�-�	�r?"�N�|Sr�OG&���wj�nօ��zF�e������<���Qdt��g*�+�JM� N�x�wd��i;�A⑓;�8�|ʯkh8'�ɘ-[_[��u�ɡrְ��D��J@�v;pp��գw镅�AF3CXD��� v�t?e%m`�t_�D��!��N	}�57h\�g9I��M8��6��U�kV���h�ȥ�l@����~C1XR��}
p .�����C����N�T8��8*Iu\�v
��vv�rR�/K��F V$�%q30�@b���k/���)���EjM'd�]�'"�oʚ�~�N�$})p��ܟ�.Q�1zf�ÿ聘'O)��o�J,+���s�PU���1���ueww/��E�
e&K�{" 3�5>84H��cS�G<S|@u������\���+#*��$66*����� �τy�c�&�t���*>#��M����(rB���,*@���M�p�8tu�w�?0�)������ln}:gu�����t+.�-M��a~?��L��6�6�Ӷl7��5��O�����7޳)Ϟ=b�$���$�V#˨��#r>�?m����	�\\��]m�&toz�$�N��Y��@V3aQ���"��X8�*�G��]�p��G!�R,���Q�"�U��!��V��F�¯FIO�S��l�E�Z	��0ԟU�t	�����3&^&��C�~@oR���e�Ѷs2���+Zk���O��Q<�����e2�ߑB��_�H�U��"Q�n[��Z1
���\�X�B���N�j��(�^`n��e�U���X�������u�⨶E�();��z��ln1{�y��Y��d����	o/9Aր��9z�$�HL]%�B��36�ɉ>�����a��d�!mg����ﱷ���@׿�����(ki*������T�w���?*��Ur�^�%i����)@BK�e�V�w �E�x�"�j���8g��#��H�r�z ��{���z�0q��d1�=�=�8�O��q��4Uj:l[�
U4���)�,��h,56()��+�9,���b��H�!�<[�0!��髞6�u�0�X�	��~�_%ߟ�����M�_і��l��V<�y������'��c��R��w:���H�ҫ,�3�W�5��d��f��C�I����ܢ�W���]=X�S�{�H^#A�S����vdiJ��C-ҵ�HΆ�
 ~,U�m>:�Q-�y�҆p�_F.��٩Au��3����xȰa��ɥA{��C�v��~����E�v 2�B{&k1�|�f�)��x���%�*:�q=W0P��Cbח#z��r�Pl�]m֯�]0��:��H����\j�PDޕ�k��*�b�Fbe���38��"�}��`>*b�ДSE�]|{���I<���m�c<
r���L֦-���L��P����Z��}]]���;t")e�#W�C�	&�nR�ַѢ���*J��u��&-��н��&���=�Z�g0�<�t7�SCZ�V�:d i��I��zK�xۆ���g�=X������r�+T.�+��_��b5+g/,�S�o�n?�10	�6�j�&"�ih��l
~�Iϖ�%�,�!p����*�(d���1�c����*?�( ��h�~;�_�`���H��tT=ϨZjQ�E�wb7 ����I^ɝ�4g8�j�c]����]j*4v+�� ̼q,����¨Ϳ��>�	��s���������>/u������P}�L*kA�Q�f??S[��m+��ے���V�z(V@y���D����E��"����8%W5����H�[F���`�Q��Iڟ���FZ,V���I�e/�0J#[ƺ��� \�EʉB\MΤ�Oh����%�M��}�R1�(?�v^����(�{~>ho�Y��#� ��U�N�ڻ�~8�w� �w�Rb,.7�����;�f�^�61��I�c��Ǌ'��(�g���U��������DQFD�?����\R�!�w]b�M��jlm���$�̀��� �;J'l� ���g�ǩ
���uk�q#ëA�����=Z#�� �� �(�1�����u�#r+(���T2�\[�5��q¤B�8eV-9����d��=@K1Fc��;�B'����e�NjaY�qQ�����.�g�GIӘ�⮛�0ĵ9
����.�}���������T#�>Ot���/�[�9�٫�b�'Y�8�j)ƽDI��W�ޗ^{��V����N������Uj��k�:�H(�Us6��~��`�N,'1���qw��Ϙ2���f�[�C&�)�9q��]S�DKA�Y~�A��
 ����Վ�?9[z����)��*;�ro%8ᑼ_��BoC�>4���<mv�PkX)�3�s����W��Z��!��|�A>��S��FܲO�W�R7@C܆J�q����)���T�ޖ����{����QRG4O[N[����O5s�RgAZ]� ���t���?WJҋ�k	;&���u$E!��޷恵iY�ܴ����;TvGmS���Z�_���y��*M'elA�k�\���'g��,Z�K�C�*5��lT�H�D��'ͭ���O-����.���j��{\aa�W�r�w{f�d3B.�&09070��!����/m�D-ݾ��,�G9�2v�aR@~�_�v��n�T��o��L�k)R��v!�@����'��w��ӹV�`YdȈ�Zf�O8��� 9��[�E۞&U˚�ɦe%�u���یti��W>;��f�I��Q�i�F_��c� mY��u�-�/k�3��X�a=>Ns��_ hK��a��ǐU:��q���x�\ɇv:� ��`���I�3�=k�W����M$�Ȍ܋ߐa�h�ZBM{0�)E���1������D�(�<�\'o��x�0�"-�HǹP��`aʛ(s#�!c���'�2E3K���_4k�	�m�V�1���B�l�������m�8Q'�%X�ww�
j�c���t�~~x��D�=�yl�0�c.��T�̿�Mc@�d%Xע'��BmNl!��J����,����C�0Oɶ�ŧ�_h�/TXqz���`6��D���� �gP�@ ��-l��h�m7�Gw�Hys59'k�K��I�G��CR�0������w�B����M�nV�r'���'|q��D�����ӕ��°�
���c3[��g����� PC7��ê8O#�����c�9�%M�]��`�l��)�bw6m]�����������I�?��l2P��)�
r��
�F�WR�+���9<8�ס����RGht���χ�4�}��it=O���VA�^Ѿ'��Pl@�x�:���..w���������*��0��ۺB�JO��V�tG�*w{X"������,�FZr���Z�8>�����[���΢�9��NW�S����u�BY,���	Xg*T3Z(���I�OK���A#t�������]��U?�O=S�xj��?��9�{���g�X�O7��t�m��E������ũ��4�������� Jd�p�p|+d��+�Ytfd�>Yge�FF��GZ"���9ZJmE�$'�)���)�Ƭ��H�m�8�lgv��C��!�p�#�I�9y�8�zfz��]�v�7�d	���$KִBn�u�^`a��욍K?����3J	�s������$�`����w&U�Ҩ�� �SזuEd��:�/�Wq�]B�ǖ��`}���ѽ�*�o��2�W6MeLI��(�H~.	�����]�5�?�rΫ��ON�\M�R Xҗ\�0���;�ԪP��&|a�J�i{O;�q�@�-�����\�>��~f�;����Ju�@<Ϲm��5�4�;�PRӘ��H��>�_I�Ǜ���Z}r����������iJ�Ս�f�����3?��YL䂯�s�ȃ&�����ǴZ�S�w��9�������:]з�x�U�@#�#8���K�|%�9���x�F*�\~7��jc+x���-J�߼�;*�%ER@o�%�����u�T�P�0JJ�i(�ԓ�q�����Ð���yĢJ�I���Z�}�l�1h�J6C8hK���ȍvs��?��&�� ��>�ʰ��RQ�Fg��	X���t@ټ֢�-�c�|�����D����B�2��,�~��:r��0��2�v�x�mH�L�����,��W?q���������yP�b���淌{I�9�ᛶ��;���L �߬M&i�N1�&�B��T2�ݬ
���vDrذ���Ֆ������oO��W�G�;:�'GG���ZOݕs��"09P&��MD<'-Jp�6��oC|`��Sԥi�dP��cv/�ˎ�A<fc�l�8�>��=by�n�ٲ�7p��
��l^V�����|�c�ZIo�Ǩ0��KY�/-��v��fӉD���4wc�e����=�%"��	�0{��P+,�qF�M�<��='ةH�)"�����\�^.�Y(1T
��Hb7a~���%O�ϻ��>�nZ�������湑&��;z�h�b����
3�>Y��	�(��gi���� ����,�n%[��F�;g���żqU�'�Pr���%Un\��lT����S��n�3Q�|��z����t;�0�N���a����]���V4m�?�w[%~"3F)��FBX{Ʈ݈�	;H����d�Q�S9�9�l�;����W:&�������3��%T'q�W��y�b�A�x���G��Eb�����Di��Uq���U&�}J���(�?L�e�<Q�(�ެ��//���a2sJM)n-R�oM>�t��W�����߲n%��D� ��-v+���Ia~�ўP6��%}k��H�;pbJ�񖠞�4BW^N ܩ�VO�EAP�1Qn�$�'����u9�.I�ӌ�}�����j��5�sKǀ�M>	��1�D5(���+
]j�^O� ���쫝;�&��n��l���tNt�Q��\Q�3�I��d���|�](�y���O/�;�1$��־�;�![�Jz� v�����Tg�g�0=�9��`t%�ǃӡ-�Ν���� i3(U���t���|?\��!�e�)M�_�S�B��ȖV�+zut�hS�\������9&O��B�8*�EiAG�ٚ��g~zI�><-��vj�O��hLә����0Ď�\�`(�͒�����,q�~�uw9?�p�v�^�r������in��TƬ������\~��00�Oh5��I���Gm���
T:ʈ'�l��A'K��h�*׾���0͜���tA�L,�d�W���W^`��b$�)t,�'�T|U��X�Dٰ�= ��P���ń�KK�iN wZ;Hs�EcXA=�1�JS�U[��A�Z�|xvú�z���o�����lK��i&KP'�و*�+;� H���3|���+�هl�^<��l�*�,r9����`�4���G$�����߻�+���G�v�:�jϢcRB'��|�b�1�~�6�fuk��\�'ڧ�"y�60/Y����y�M�&�S�ny�����]=�B�xo�hM|������板����7��g���a��8�`���>_���4`��~�b�O�
2��7����� ����]u/[��P��V�Y��Zh�do[QZ�e#��k��%�x{f�e�/�,��*���?L���ٲ;c{�l�����Ԥ����ȏ�Q82kR�{y��6C:�
**f�^;M��D��;4��:�E5s�e�2��ܡ�_J�Ӷ�����׾���έ��x�+:�4*�{�w���]���c/��^���Z��t�1��LfuA�>Aq����a���Y�|���١Ɵ�TԢQ�y�ڧ��U�1�l��w��3�-���mz��G�M1�f�t�g3�W�D�x��C/p�c^rg8�f�?Ve7mD��tv�/Է*`):����z�\�K�<`�;�-�,,���S��Px9��%�AC�m�9*N�Q��9%�z�"R���8p���ɫ���EXg�����~?�w�g�i�ȏ�2��f��¼T����_fZ��L�`J�|�.����t����3t��]Ei���:7)^K�)q(�����<��$��B�\3r�}sPYSy�aRH��J�ǉ����cي|����X��>bꢾ5.c\1|���������veJ�EWzd ��²q�<-������Q�s!�R-����Ҏ�����2;�mW���E����>p���G���Pj5�Ղ$�B;n��r�؜R��
*����xH�e�B=�Sˀo"g�@F?���ab�o5M��Z�b�a���~��~k�/��>5&{	�;�j/��R��jRL'�nS�7��\������eS&~(,�)vg�� A�T;��~��̓Q�Eތ�O�[Y�������`�2�2�=��U�~>]����Ik���EP7dRwZ3���sF�k�~�1�(8�*>�Q�yo~h"�ߟ�@�15.���gb��kE����/�>2��G�;eL�QBlZ���.2=��??��L��
*�MN9��G��ð����5�)o��!Z�@/|����l��=����~��?�N�3
ډ�8�D}����cz��KDV��,�/=2D8
���خ���)t�|�
�`��Ί'�Ǔ�����蚭;vZ.����ʒ
N�v�Xs͠H�����1
ʾ����Uz�I\�w~�ө�4/I"@Wϟ|���;��k���S� b=��y[^dx����jE��QY�t!kl��"k*
/���;�z����(�\g���3P��2���:�F�bO|��ɐfdQ˓{	���O�2�����B�)� j�+�GJI�	���}�c������ƹ�lӷ�6G�Dv��pe��g�vg	 �V��7a��8�������8S3`S���Y��m
`>F�q@�1��%�tt��ئ��=k�4v�7-mFe��3�ml�^�s�j��G��<��h��f�U9�!k���x*=~-�Zrjd��~���eyY
�~�;��}f20���m��6���V�����O���M��``��5B!"�Ed��z�ZO"�i6�wC ���!��A��l��ܧ�ݕA���X��ge͔0ZF�p�Mʆ�/k�����H��:P��|�$�S�����#��`]��PG+?�1���[m*���������K4��B㣸�� ��R;i�����!�R������uoiE�����{��
p�9D��|&���i}�3;�sbqUf/�j��VGvX�&>� �i�`���:�DN{sV�c�P=��?���d�R\n�d�Ə� 8�Ȥ��d�q�P��K9�q<}z����0~!��ub˷Xĳ��@_�B��wU�<T0
6s2�C�%�k���
1g'��sk6�~a��z�V׭��o�7���
���ʱN�)���(����u�"�ԣ�G�YBp�6����F��ڣ�E�?7S�tCF]���b�#L|��'_�=b��(����f�P�;�zv���B�W�UU�F}��9���JZQƗk�6H�N�6�����	�i��1#��|�kƢn��H>��Ef(�E�l&:�0iD�O�?���cCڎ�?�G��2r���6���x�˩u<�]�-�B���Б7�m����>�p��1�4G��F��w��f��?+d���m���[M	k�����>��@^��I�0��7���:��$/H�"F:`�dX�h$k|#5��$��XpUE��m"˹e�5 ��c�t�ys��,!N�vӸ�я�dAݢ��HݴN(���;
���gJ�A�a�QMůo,�ۼ{$%�bXDG�p��24ٱ�J"HOF�=�wՋ �~@+����ިӷ|�DJ�v�
G �p���7��?�	�0d]@Q,r�PX��Km*�����h\O����|��]ķ o�Wb+�[��N��z�jL�vX6Fd4Q��[E��G/g%)[�����!#R�[���0�"r���@X"�4j�"z�K͇�#`�p��۱,��O6�<�~�(5g%^,��7>�])�|���iLa�st7{���O@�]*�`�M[������.r�)�e�n�Y�mA�:���D�6��l���ژ&x-~>2��Gz�$�}O�\�?!�<�W���*�}� 8��*Ix״�J>��>����E�����s��>z�E:��<G��Sh���l��B73�9�x8��D����p��7���t��q��A���7��`6�(���@�&��8Qf�G�ٍxQ2�9i*���Bz�TZ�)|c��IoFo
η�䍭c��K�R��q���4�+ٯ����F8�ɽ�l���i��уU/	&q}���"���?���b��M�UϴE�5)�㞶w�B����j��oFAqf�l�m�Ɂodɳհ����U�-�J��mv����4�rx���"���!&�v�Y�!��fG�/��ml�E"`О��҃��8��&�vzu���t����J�0�6�L�Y��B�������q���������\oD�c#�L�P1"� ?�Ug�6>��.(|(/�n���wmS�F���0-��q~W�F��6�ȈA�-�.�T4\-���~�#c�WR~X6�:����|#�w����P"����f�ݒ{ ��y��r�v �j+�	[{��0���|\��`�-��Nx�y�%�]�/Ĩc��g�  f�!�o�5�L��[����I!<�s7�L������:���kO�/�����L����	��!�y5��*�V"�28�
?M��X����DP=(����0�+���.�.B�1폩�P�fv�I��Ș���I�bWظe��H�T�y�>���߮9�5���@Q]̮�A韸�J�Vd�^�X�k�p��vN�C��K���?���4��<<e�.����r�":�mR��X<������4n3�:���M�3	�yΛᢪ��a.Zr�-y ��^8YZ���� �1=7�=S�瑕�✯ �O�cx��p��[��P���(Q�fb�4;����)��e���$"��1�fO����)������J���4poR](h� iJ$�G�*�P��1�u"��ّ�e���l.�]���澌�b�"��SzD*&�����OB�fs��<2*��T�2ɕ<�vӯs���1� D�@�9�	����S�}�.�Dr��UD��T�w+��)�'A�<񑓗o��\[�Ж~Z>��s��t����8\����l��p�a�L[��!6 i��&'�"͋� �����U�O� �1��s��i�/ĝ8or�,RF�0X����LP�F�(�1i��%�m�E���"����G���{�#���aɐGj�֊�|vN�a�O�c,�V�����G�-�%��ۆ�_�x�dZ9����?ɛ��rU��(~��(5H���b�Z���&�yUTB��ߓ@�ҡ
�j�����O[� i�4I�ᗏ��AcD�QЧ&�p=M�h'R@���}��$
ԝ��.Cm�=���7̵���;�p���}�xz���C�/���_�>4�	%2��T���Jƥx��G�:�m���n��Ky
�6�[��(��:e��]Vݱ5�Nc�R|�� �~yk{�7�<��&ڑ6H���p>��xԞ��괋Ƶ���*����w�3��6v{e��8�#<��3�0�ٕ�ꟊ��s�_}��'��G~-��+EF���:�����<���eE��gY� r3��\�X®�Y�Uc��!�����'�a��&�'���z�A��� ��S姲��ا��ըٳc�Ko�ނd}�*���']���� ���o�i@l��j�Xci������KN`��X�#�2ވ	���Lɇ着�Z�a(�I-��[����6����Mp^@X�,��B�ם�l?uQ���s��ƶ�Z�LT��շ�?��w���_�:�H��|���YJG>�$r6	�w�9WVxx<�{щ��dQ��V�vT�wr�<Ӳ7u����aĀ��0�ܩϘd��gGE�MW��+�ݡug��(������s�"�Cgq��*��v���j��M�g�ej�JN��X(�������c���>�ÀF'�K�c���dR� 
�᠝A���d��6�)�7(�D ��*-6}
�h��z
��􅛹�lĭ�����������!�coG���o�{�����0g<u�:Wb���wVK���m�jv�j�U=�g}$��M�׸��y$�m�������*\9�CD�4�D#>	^(���3չ��f�l=G򱓙���6*�ب��m���B,�n#Tk�m�U��w�&\�^`��nl�/�/�/)�釼,G2��hך[����V_��ⳗ�qF�#/�7E�wU���|F䶸�� &�D7mi�ӏ׎��"��yC�CaEF��Ҡ�i�pw�F/|���{ ��|���t¡U	�K�
_Xk��n���Ͼ��v�*�"���:Fo�_2��~mw��P?��-zcዬ=NK��43=i?�&�mۜ��M��k}�)����*`�$��ݲ���s�������;<�W1� �	N8�T�z�x�8�ڏ��ܜ'%J7�O���is2wD����� �S܈���~�XZ���;�f�v�g����2^;2��@d�բѿWy�K�Lp��!X�B�q� V<zw�8sPs�?�r{E��>c�qՓ����fB�B:�D��ݜ_�&�Y3VmR�)�wu*���>����L�)�k�Y�ڵ�y���I�R�F_�<ڴ4���{B/�|K� ����t�<�0��FR&cJ/C�BB��g�[Ǜ��� �-m��h�W�/P�Y��Jh��}����na�� �-�]��9��I�Y9��2)"l&�G�{�h��[���0����/��yʍ f�
	�WI8��B�{ͽ`��^����i���	���4�Jq2��jVWkL��Dt������R̾gk�Zl�y-o�Ð���F���O$`#�Q�]��H	��w=⁾�*�����/P-`#Ĳ���4��o � S�Ki�ı�E�`/��hϞ0Q��{�9O,bq��+�
�(��ɖ؈�cnrQ4Z,�ƼG6�����;�䅆_���L�z�{�G���39�N�<�6�v%�	d5�<z����{�<�	;����Cn�p�܆3��w/4�?)9��M#�g��2R7oz�Ip����RC��Y�4�m�4o(S�1���#BҠVH����m,����j��>���V謨4>���f�ݏ�А�Q{D�g��Ͻ���Z=P�Dޟ��ʐ�[y+=$�wo'��a��!��2O�.��kuӂ�Z�����^/��;�^����^t	�3PH�=n��Zf���-��X��,�ɑ�H����t7[�Y *������Al�J$�p���	d9����D!i��[=`T����>���g����0qC/%!�n��������T�Ĭ#f�	iL,~��%�(r�}X^�#Έq�p	S6]�t�fw����4<Bb��ږl�u��QTw���=޹YQ�pz�M8��>�Q�'��0CԴ����B�e�h��=��῞����,�Dc*����w�{7��u(}O�
��?��ɚ41���(O�ŢɅ��e� 𣢋ĵĲhn�s��A6e��m��2�؆J%]�_,��]'j'��B���q�9)"�-�!�#0P}H]�`�,L^h=�Q��o�8���&��=�q�씧 /����`�J�h3�]���X�y�(��5���}��n������P���-]���C&m��n})��&���,�;�٦�>
B&�ٛ����ET�U��u<'�ۆ�h��#kds����}��b@��!2/Ow<?����~<���E�>L&�s���)T�+̒H�f0���x�rTg�Ԁ@�X;�_�i���̧ЅI�Q|,�8��HĶ�����#����%�=��ެ	����zJ��%��&a -��-���/��"0~�Ε����S���b:*٣�1
��"M�����v��Y�v ���^�r�1]�IH<���n����>Jz���bfy7.oYǈ#��gu��baֶ����]1��щM�ӡjդ+zT٤Wx'�[\u些���B.,z+ks�i|%��)�j,Ֆ�F��ʎO����;�"["Cy]�?��ɋ�W���7������A+3������Zf튊�dz���y�gǍ�=��[sŉ%� �E��0�</@dPAՉ�wiHF���	�G�j�t�� {��SEV�#`�-�UݭL��op���p t�+H P���*�����z���V%��sJh�lq+U�l���!9�U��r
K�ЪLʈ
����rh
��~C�ٺ�^wKԜa�g��\[-�vYKY�A����c��s����e4W� a�j��*�X��;�p� ,jи�UK8�hRT?<$%��h荽��Bq"rn^�_�u{@kf�-��S��LT��8V�'QO�1]�Eo՜���H6�.3�4)�U*���)
��#�eˢ��6=;�8��<�<�����k&<4����֏�}��h�l���ZV�'���7p_D+\�oS�V%6L�Ȕ��5�ʔ4�D�[*��Zj���5����l���D�5��/B�h;^"b�q����hϡ /��z�"=f��#��C�i�Ӊ�_=���|���>t�6�����`as�m����u]~��e�S������������Q�e��Ħ}��D�\-���m��V�v�K?�m�C �2Y���J��d:�p���f�gq8sK����JG�99������6�ո���!PsJ�i��A�5��!���Q�"��-S;����-�x_�}���1ڧH���H�C&﫪Z��r�8�3��%CQ\���%P����W��gW�%ݼ���n�^c��v��M��= 7N���>K�X�c����d8 1�ᚣ^@��@�KF�f�X�V1�|�u�*#��M��zU�m�z#Q��m�?}9Y�ht�Zt����R$,*�N�.i�4o��4YDqQ� �#���G���*͑ޘw��xm���j�L"�i)�X�sQG��1y�9��K���d{t���%�^P����     ;�$j�"�� ����f�丱�g�    YZ