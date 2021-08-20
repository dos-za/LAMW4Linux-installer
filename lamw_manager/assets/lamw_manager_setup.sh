#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1524145238"
MD5="c62ee2742971ceee355ee3f311afde42"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23600"
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
	echo Date of packaging: Fri Aug 20 00:54:17 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�aq���	w�Wq�֐����
�O��!�~�%��;��.9L�_	CN�D�O{^��1zkc;��ҜXlĵ1���'7e�x���[�K}��k��DP ���,�QV����.��T%A}N��`*���e"|�19��龽���#F� ���爡�og��ʽ��	AW��U�%cB�Ūs�A�;I��8��Z~Rm�i��0���z�9�F�G�?GZ�W/�ry��,ջKa�P~P���me�/��B��Ly��+�&��X�f�,�����l�cv���8�88o��?��v�/;��������2�HP��E߶΃:+��Q�ҡlx�f�Z޽�c��2���2�z�XO�������V�>c��s�y ��(������yt�c1���G����<1�3qgV�O����+�$���q����6t,Ü�ⵀ�?�o�����ǂ�����
��Y��n��MJ!Ɨf-�і@`�!M^���_�.L����f� EO�W�N����x�ߋ`���^H�]r{g���.�6�+5�m����墌j�n'[��wf���<�1�l�08^���\��Փ�k}�O׼Էt��o�_BF)3����uA��#|��~[����3����`�D�_�ϵe�)�»`{��پ����Cv�f��t�9ph���Q�.T�͂oW�W�ܭ,o����=�/́[��Y�=iԩ%��pF�y9Wjm�W�p�0�
�Ő�&���@�I�?�Bp�.]�B"�niV�K�Co'Z�/�:-����/(N�ʚ� �{�V�z#���8W}�-�=�k���gO}gii�8�͜I�ߘ���Eh�?l+�'�Χ���3I	�;�@�#�NN�n79q�r�sa9(�d}/�B5�߀$$�`��>��0��]��]y�J)1�ԈБ���������l`�hU6����u}�Oi�S�*���(ר��q7Aia�\�}���nŀ2�&��u���o&θ�&x;7���m�׿��]�1Q��Bdk_<A���ǔw��-ƨ�Ú��p������vg�#q�7'�,�K�&<��!�?7���&��o>" V���o��(���wW�0�T�����D�U�cx��F�_Ǩ�pP�i����pL��.�M��! E���.�9�
4i+�ar�D�:�#��R��׀\g����jvU\"L����Fl����u���Ρ������R�[�s'�����lfP
�}��I�9�-�N�J=����Pu�H*�L9�だ=?`�~g��g�YU��0��J|��S� JFf��	��S�`��Hb�G���]����b@{hSw
��TB��0�)χ�۝ך�Ɛ�tc�UY�m��^C�N��N��������my�v�!�G�i)P���Np�~)cD����h M��c5fI>�<���P�A[.����R@Lr�	�yZA�`;�[��@�yŀ�@��Xd�Sc����B�_�3my��I�▀��S�(>	V��i~�`�v�X�XY�J�s�0�f�DI�fR�P)���9蘾�Ö����'pa�~���9׬;�5do�0���90d�+jD<� ��<��K+P��h�ke�ˍ2�&h��r3�V=��rY�$a�m����5=~:3O����e���QD�ӏ��!$g��1�iq��:���p�;Ȁ������d4ְH�{���,�O��O�&Ǡu��W�\�h�5��R�}�T�A��P��"�X壬c��w�_�
�'jJ+,�t�ZgubW���>cI�6e"\1�;b�Id��:��Ζ�V��ק�ؿ�bz�sL��0K#� 5�	��r��MZ�J�N��t=訖�4��U�8��R7��.Ē_4��{�B`J����f�`���;��V��U�`�%����8� B㩤~y$�`��ه���h��(c�Tsv�Yī�Fq��՚��ٴ�-��fJ�[�Ds�z�%�ۂ������tU��g�	�H�ib�CW ����.�]�/�O"š<��6-�z�u2w0O���ѐ���H����׽�9�aZ*3KFn2�f�}����*`	}ϼ�����ʓ�/�S#m��}�YZG���b���a��G}�� '�h6��~пf �|����3�5S�c���/�]�=�4�"��2�d4G���{�Zl��������698�r�lk�^��?j�|Jl6N��o�R�=�Eڹ�jI�C��G�����^S�Ç7��VR�eh�1�Du��,��<I�	��l�$K�`��*	�㫪��aEa
mӞ'�<L(�I	��R�@��K��?X��Q�g�a��1+A���Z������LOU�;�;�@�vl�+�R���L��e�{)*�C���N���[/Q@$(�����(8���٥H�@�-|p{~s9�Vl�� �'|��Dq;)�5{'�'��}�J_BBG���0�R�����K[UA���)�TҮ`p��џ��R�o�YT�Ni�\��<��Vl�-�٫�<��K�iN�����_�����_�H2w�mLOrV ���An��������߷1'%ߓZf<�4J�zBf���(��+I�m�H�w�"Pv��_�1�eXF]����[�0?~+nY�yG�d��1�6f��gO�3��3�wP/�|�O��ϒ31mU\�>kݛ����,f^�z�y;-��S�ȅ�M
+L�ғq�Fl�>\���'��(�"�|�◿~զ�R���[`ވ��K�������{��(Z��.�����,"�B�`*����K������b<���oZT�Hx5S�l�5,d��	>ೱyM��d<fkT�f �cЦӎ�sf�S�4+�Kxs�2��o�`��)�A{0�|�X�C�]"!���S;A!R>��v�I����8éJs�YZ�W��VX��5�9#�R�A(�<F�'@��Dj�U	��U���L���9��;�>�K���k:�����@1o��4S����"�v�[����>�:��K�T|��pA�-��'�9��fOV$�2�Ü�*�ĦNq���g@��k}�c��#�k}�h��>�w�
ˡ��h04�_��\�.;p\iQ���4�(��?;NU;{��S��je��bd�pd5���DM���Z��n�ŵ��ĩFT� I2�F�Y���fJkկ d����Q>j0I����M�}��C �HL�!�f�,�7#����C��,�(�)��ㅌ���}LRU͋y�	����d0�q��S%	#�4jc�[��i������F�A[���X�J��$��u#KA �θ�ݗA�f���1��/$��Cܕ��0���h�R��yEw��m��QQ�RDF��Á�J�h�2�Z�d�M8��~��R}y��i,1���ZI�+���R)OxB��4��
'@�j�}�~O�-}qSfG��s��������s�~mTә�'f��62HN�_Y�M�, Ѧ�%6Gh���O.��ې����VXN��-�<�@B���vS����V�P��4���� ��~'��?a��9��{�;ԧQya�<hɗ�"V-���r��)���P�����*S}1�hb~J�����<0)��H�}l�8��>����o~1G���m�Z���'�~��4)�@�a
�>�5":;�_L�o/b%��%�%V���1�ځϘ�3Ƙ\�۞�V����&5v�s��E"��'�&l�p�N���ّ�ljI��_nK|�{�:� �}w�2�WD�u͞K�B�0��WD1{@y�4(��݁6#K����*�qQEx�Z�4�:
l����شof";�uU',^�7���d�����2��"�y�'�$�9�f�:�K���	����'qޱP<�9 X�4C��:��5;��8��@��M#g��/� ;��ن��o����8�A��>�&Ϳ����%��2�a��8E���*_Z�G���JOP�d~I����K���e��[?O���Y���K��C�^?'< cc4��{�d�hm#����B��< G�;Q���)[��u��)B9Ͷr~��fuQ'��k}Mx��(�W,��^f�T�5��6��#�m'3U��â-J<���r�f��&A�v���!�!Z['!L�.��b���(5��e�y^C?k�xq"*��i2�hgpNV\(�q�8d��G��}�����/}��v^����PVju�+��-n��&V�tf+/��<�3p+��`���K�[!���݂$郯�x/c�dz/���=��>�F��%!EՇt�MS�n)$}�V�5��M(��?�[>�X ܑ��_I嬨��N������M���fro��	��Z2�� C����(�J����_����\첎[H�w��Le�+�_l���`�M�F �Mm����/�I}�"���q6��̐��q�]nRb����*>�o����q'��\�BV�\7$�,a�QFK[�7�Ή˸��
	:��Xk���͟P�%BM��7�dQ��ܼ:~�I?�l�f���s3��w�mS��P^�������uj
Y+Xo���̇�
J|4GY�[���05%\Fg��C����]���"�=7�C�c�o����nEƏ��~�Ehφ�2���8ܿB'ǫp�z�y	ݷ�v@�/�)�?w;��ۂ�`D�� ZS|̼as�����A�&���)���v7�z���r�8-���9�A��^�j�e��:�ZkY�X��8�}�C��^;q�yE�vH�=lK�VӀ��?�(us�&����	�s��������n�C:l�5�t]�瘢�m�n&?�Q�7MH�bщB������Yle�t���e&���"�I ���6{6�'#��.��Fyo*y׸�5���I�E75}�>�(�
��W��<����V8�h��
���w�5+r;�F48���/�u��'�S/Sc�$(M����I{N�w�ư��i��^��/:B�.�����Ѷֹ��FԼǿ0�-��]�O<l@[�"b�.�̏s�Ƶo%>L����\�*�9偎-�}Wߚws�{�Z$��@�2��M��w\�-�����ꑮA̠�3I_���$�lX�IԊ$H��i��pǀ9��xg`&�=˪*��5�Q��3a��V��$~�/uŜS�g�"$Xb�6����3����Y��dě��4QB�CjG�8a�g9�� �c��!SϾ����X{T�[���U�$[P�5�F�0�E��������-���L�����*��o���̪��0#����W�J��,g��g���n�W�˛Qy�	��a��a�^>�57paϦ�
s�!�8Z�{�X��~]��\̼�)U�`�Z�>����&�c�*A=k�܁���Sj�����.�=5��Q�BOUTN:ע�]���k3�{-p3;�i��?&i�qq�d�}RX����}/b�t�-I*{�1mRٯ`rH,��A�&V��ȸg3݄�k�?Ą��v@�hHӯ�$����%ͯrx@�����/r�9���I���@����#Ve��V *�ٹbԐ�p�&z�k����k��x��;w��\�{��.�6�"�*�\~,�R�5�ˇb�,#L\�	�*P̀��q����gb����u�U![���d��� x���vv�6��������菤j�V�ܓ�����3�b�;��S���q(Z���#��c��Yz����A�?p����BnK�ĭx�A�~I��E%֗M\)h�b�@�$�Λ{�,h�����x<��w֠M������k�i��4e}�MmZ��~�꿗/شr�ˊA�no��i� f��:�`���}�]0ƕ.�2�X]��'Y���[	)0V���
RʝC��K���9�2mh�4,.���!�Rr�r@*�����;���w�;p^2�X�`zQڕ�Q�ͮ�Z�<�Q#�xz2��#��A��z�yV���7�����$���@fKʦ���<^�$� �C$��,�])�!��2�SGP`��`E�gi����nhݨX�E��[�� ��=]%۬��}bP�UVV�WV���iv�{C+)<!��a���>���rTz�����t5RW�d��D\���"���հ����c�/'<}�o@���\����Ȇzh�z`LIp���Q���t�� W�����ݲ�tX�ܭ�c�Uڴ4���N4��tj�0�Oz��u�9����a&֫9�~�].+�����:��j[iw�-�r�
P{���m�^?"23�`��TO�/w��*
(�q8U�A����E#;��n���|TN���о<o�ﮌw�'�TW���o �^�2V��1�?�Rr�x�i��9��x�Fg��G"�U��|��}L� d"��u���8o�db����[S�%�W[���ڕ�O���-w@�~8K/��I�O�x��;c�S�w���:�=�ܖ�C���n���tB��{֫��3�X�#�`�
9���ԉ���U��.~�Cs�o���E�(�kdk�Bq��Y�3AZ����\�X���fw��Ӊ�~d�A�o�BLH�k�pF���F�Ю|�A� d�^����$�ӟQX����K��ʿT�\�9��9��k`���~�5���^GP#��9��~�9�F	J�;�k.�D
��!B���b9B�+�|}�t��.#��x,�������Dٵ`���P�1��4��w�u}^'-�ew���{ p�fޓ9Y�z�,D�S�G�˛GF�qW-l�1C�.Q�ExB�2��T,#T��B�1�F�d�ڼ_���1�����.�*�i�!�w���Op8r�D�c��䰲�� L|�/��I,iqI���Ӣ�����cҚ)�u9m .fҎ�ȥ�_�$=�T�@�}����_Hq>L��9���;R������m�l�R=��l�����5�R�X:����=s��`:&u7���*CS;<j�x7�{��J����;d[�C U����D�=�V~��p�;�G��IDb��2��[YB.a!�Zv�(����1ѽ����S5�b�W�N����5�ʿ�����[]dE@kA\O�)�j��q��ȿ�"��.����>�M�]) _��΢�`k"�n4d�ƥ|mB1���)�#��.���qmX�eyG���O/Ax�je��+�P���f�Z=����I)��pڿ���\)ͫ%�O!��Pa��NNR..2x7A��&���I�d�do:��J-�Ff�������:�"*�����Te�pKQ����EأQ&��=��$.+'�9,��Q�'F � ��xwQ�*�ldJ+�����W�H��_c�􁷤���0b]c>���}���@40�������i�SV�v�H�+/'"��4¥�[:p�d
���K}��n7��k:�����i�	7-�p�3Wsb<����p������T��?(F�࠮&Jd�V�TBQ+a�����whd��@�����E�0�I�-s#㙿R����m����)��m����a$.�ryU�E��`��c�>��Hb�c�\GX���6�p�N�XH ����b�S�ǯ�"��V_sk~}��K�A�j�$��e	=�J���2��q���Eg.���*�3:�^7޲�h�����d5�V�"�,\둝� د���K6��kTI�P���(�f�����7K8 ���ȱ�*�g�w�W�bu^��5�L�_7�'�i��!>2�p?c���O����&�P�7�kO:����ӎ��J;�n�J��m�����	���<	���j��Z�%�Ppą��\c��"CN�	0�����F	]�\+��J���/��;`�{�5$��y>�,2���JCv��r���/|}���G�}$Lc�w�Ւ�=-*,jH�����e���;���gr0�
�������hH�tA�z��3\R!��mK �����W��:�����t����`�gL���	�'�E� ���G?�./t:��t�X��V2��A�Ya��e�(���(�ٽ�&J�d�ûG�+��U!S�*�ͽ����p�$�����~W#�4�����g��[𦂏�� 9�a0v�ݫ����yC�Ҫ�W�	i�&���I���E/�ג6r��6�;�y9m{F/⛮�A�����%�E���|	pO��5�0��3"ݚ3�ң`�j]i�܊��;�K/$��!����i����[�OS��8�Ƞ�k4��������!�G�t��L��^���e������^��#!:�������|l"���3z���Z,Ǎ�(�6 �#g��l��zO�[Pg�/�X@�6���"{��c"��%S�vŲ����b�j3`�� ߚ]bp�J�v¢瞙]�������Ѕ�0y��&~�=��4J2��@v\Z��PR!�&%�c�pC�����x��&�m陪W����$EJ��B8����2A]
�\l&��)v�{�P���c	Mz.\ۖzE.�b*H2K�P�jY�5��1���d2��N�	H�d����.��Zpg+�)7��\]��f�>=�yK)�k_��(!.cˊɣ��F�`���HjU�|dq<Ņ��e�S"hv�Ѧ&{<�Ɠ�c�6��J�=�� qR
���S$����CA�>m؀���a�b2��Rd�߈���b�yR/�/�D�9�G*�M�L�w��ʾ/���ܷ��$��۳��S.�ϥ� E��*p�0(���HQ���6���|� ���a?���C�'���2����'V���j�ڕgDi)l�B���!��M�3J�~8-��ء����7|���	{"o�Z�s�/.��ӹ2*��e�;��.��&<G�{x|:T`�������ޤ�x�\G����.��������Xz�1b��'��՟U�6~��	�η捝#�{�fͰ4�Ǆd� K9��^������������I~�U�Y��-]�k꬧碹Kӡ��6�n���J�XG��%�I�0B9m!��:Y���-!Iv�AL?}d"��S$m��kRq���{>�SGU�$F����at15�}UrA2�9�1,��$q��Ɵ���=��@/!�5�1+�_�ɪ�)�z���u)y��NI"�1�=����%�5An�5����#VV�ys~t����׍�f�=���8vRvp�P�5�m��K5B	ª���Zj
�%g�vn�1��Աk_�G�|��u�x�dx��G`v�d$��8�7Ax��E��\hs��%%e��{iҏK@:�g����YGIQ��*��tI��ΤhF%2s�9h%6}={!��SWe{�$������G���"Dy��!����Ҁ2���Jo�誣��H�N`�����pĉLK֤Bϒ'�����=�dH�>;ᔒ8~�~
���	J�����x�;�Ԫ��Z���s����iX�ikY�x��k�#�A�ii��FJV(:���՟��c>=��j��##s(ã'z�n�R�W6I��9��mPߤT[�w#�,��{脀�-�J�a|��y�/khY�R�R���ɺ�O�[?�i�!�֋�=[I(2I�KĎ�̞([)@�^>�j��J�rn�L��XK�]|� ���a�=��&`�權�����Js��.���@q�?4-���M�bq�X�sG�X�s�����F�xo���$toI��}D��(�@y*��&��6n��F�v�O|[���\ ���i�(8��#�O��r(clk��N��%��$��u:���l3���ڍ�}xU��ֵ�H��8��4��7j���b�/���J�`e|�<.^bRZY$~���X�q�@�t�-��#��^�5�&�ۑ���^;k@�8kNJ?
�����3��P�8���e�5��-���Ue)�QM�|_/~�7��k�����c������	���Y�	 q�bw��v�����,����-x�ƭ�̠�������Uo��9�* P��pZa�;!	� ��̑E�>�0�=P����2�ێM'@W�$.stN�.t��GͮĬ��$\ �P�/v��-z����@�"#����]��Y�Aٶ�|lb�/y;W��ғ���M��������*������CZ�>AP����� ��#�u�T�X�\;�,�<�\�oEz���]Ҟ7S�H�����ι��ؗ2,�����d����`��ZNS���^n��o �ŕ����i1K@3e��Rh6E!�����e廯��j�tg?3��#�&�dJ�`gy׮$gJ\Ř)���8������g�쇟�q�_n��ވ��y�|��mJ�W�;��Ҷf��B��܆$���_)��( +{�����x��l��s��EG	��S�i�B�$���h�?� ��kp��sjGK9�S�_'P��biE'������:�DzOY-x<��7�,�R;����V�;��'GD�D���ǋ�t��ʛVH!w��]�GB�=�k��;��	�yf)Jl`J�d�t��q�?O���
����j�!LO;R��n|�v#P{�!W(�_B�s)��U�=�D�TB�V�i�f�J��vR�kϙ�q�Ձ͏������t�@���h��+�1�ذB�cp+��]z��{��=��jS���+�m5��	)S���o�3�����=�BtACy>��KM�Ơ�^�_�a�O�Y��*�	̽���
�V�����pX���J_�{�.��>�E,|T�#L�|]{��V���G���M��E:��5�Bv$����y���_�Ȁ���K˄��=�v ��:�A ����̄0͈8�@|"���`���؇���`�[�7�n?iK�U�њ�!�/�*���Msj�B�J�j,I/���b�N��73�P?t��~f6�#�F���Y��S�Vs�׭��Wj5��?:.^��4�Pit�U�J����Q@E�=�PV�3��sQ���]�ȹ�,C"����:�z>RV�AtM��d/�鸀w��5��)��z�M��m ��"�߶-���ޖܴ��Xw߂p���7�F��Z_0�=M��j���D���5#O���K<1tq4
���׺*w�(��,�Z����_q�����~?��(4u��]�1�o[����f%=7"�5���n�d?� �م�N� ��l����r㿕���D"V��c"�x�b������>�RO����0��3�1�k���8�r�Nf��~�Jng^ŕ%
�w�!|�����
�lT�:"��!Ͷ2� �}���	o�1�X?U�nD���K�o���w���6�"V�P�f��_I{����yZ�AfIS�bd6A��'�7��F�\�?;G�,��~�X�r}95Ҝ�c�9�]������m���F(�n:�m�5�	},w�b�,�ɶ�C�4��6I3�nh����+s.1��a�3��8�ǝ���Rsϟ�n�#�y�"CU�,%2Yj���Xj˧�$��)�b@/�	�PN�>�N�7�C�Ȱ�n%_p�g�03Lꅒؗ�m��㬞P�4���\HTO~;��(����"�$�E��/C|V��}t��&�>��l7���H�f�jz����*���;��8K2�^L��H�����)I��/�N��/�����(����@���i�F����E���������2Q�g3�g���DN��f��J�A��4ǔ�T�����0��'B����i�픙#��e��R �M.���d^����L��|}�^)w��/e)t����yfM7h,�$���3��+�����y�$%~��l̴�(r`�¢nhD-�I������i�n�{$U�5�$��˛��H!�kK^�Ƴ�XI�;I)a��n����b)]�߂�8���=-�ô�|HX�N�� �ϭ{j9)��otF�� ś����л(��ݜ�l�S�)��B�����e_�����m2��"uڣ��6�%���u����5���)�G�^��\�=�ZXi� s�c;#,�E�F:�ꮆL{P�.�]lgy	�A�2Q��#��w��B!�����2��n@�e#��
x0�a�Ʉ��� o��h�X�C��-��4�r�����}>v�2�U�V�s�~���p �2�I�����Q�>�e�o%^�;���]�,U0�m֕��h�8}��EKĪ"����2kՌCC����4�v�D�9.�?j��k���'��U�ڌ�I-q&��	ez�D�0�~r�&%��l����"�*�$~O�*�pȅWvv�����^'+g�2e��?�=%��9ٛ ����`�"��%���-�%�����%�]A����v�:�ْ`���O��iy`r�O��.A/�:�א~+ 	�e%�b��|��Lɩ admI ߥj��.�*�\��CV�x�i`���#GG��DiV2<�'>¬DxX�v}��`TF�*�����l�Py?�~������B�r����� ��1F�;9Ɠ/�9v�5]Q͒�#��i���|2sMv*�L{{D�킺��`-;;ϓ&b��d���������!�껡�OR�\�Tw ��5���jUc˅a?��F�x~@ �� 0oP����aBO/N��:J5(��k$`n�:�h����=�)e՞%Ū�:ո'1a����� n�X�{:�� U�4+]��Kq�y����f*������,����C�1����A@��Y�.�|����8����-��l11�>E�͠�iK�27����TxW��!+�e>a��C|����/��]�E�T��B{h��D��I�Bاu�3���>�T�����94t)@��ES�{��esk��ץ!I��%�m�k�7ݍ�BB��AAҤ��t5��l���I���A"��p�=�zo�:S�u�����P|7�M�Vi�!�-�=�(�����:ZX�6�d��6yS��Z!�N	:^�%-6�����w��/OƁ�Mw������$Ss��� e��狈Ǳr4�
A'�?��+ɚ�f�:����8�m�]Q�\^�Bhq'���eIU亝�|*⻨���έp���h�c4��z�6a=?�^)u~O9 �<BD��E;�9��^]��ݰ#9̘L����rq+�3X���uE!��8fd��8xV3lc!W��4$�x��3�݆�s�,�{
���|�9nG��T����	%���P&V})�S�=6���ܛ�ݵg��e��p���8�b��1��%���)R�d��K)� ��e��97lr��q4�-�T�AL3��[�}��YJWF%"K+H^�k��ܪ��ڍY��>U�>�	1����2U�/�^2��C`�ݣ�=��b�3(���6��]�ok�N�,7������-F�ax-�s��'�,
	c/#Za�X`��p8DMR&��
.|I�0E�ʁ���6 C�is����DILZ{t��ْ3(�rL�(y��rw�ޢhY�7M�^  IS��V"�X�6��у��A����.�{z.��K���[�xx��꩟���f��T�Z��{]���ͼ��.�v�e�HU���"Y��Q��9&���˥^�.�3
�^t%�{j��C�i~[��q�U� `/���ӈ�8��w�������� ?ă16D����h/4x�-ѵ|��\ՙ��3~2Z.f)O���&�z�=E�mf��ǉ<���>l�����j��b�ع���[':#�T괭�إ�p��z#��ɠ�?�A�=(XG3ţ�7sE-`�?�w��H����8k����)巧���#�w� j*³�&�a?�7���hPCk�7��=��*��
����)��-��<��>�}<���#c���i�.$�hR��,O8��`c�W��.��й��#���[G�|ݨ���	����.�0)�a%ʐ�:��W?N��{FG�Q����)�Bls�� �d��%+�38��̈V�
d��͓����J��.�"��.R����{�O�H�(���e��_�zgƇ���!�If��?㍍�g+�����		��Ԉhljj6���m��h��kQt ar�m�m�	����u�(����EAk=���OD��]G8�)�=O�-��8�߂�����m+��(�߆�3�/�WY�n�ԍ���Շ�P'��5tW����p{ �91,��h�&�0�(#�q3 <V��E%�Of!�6�p��7;�������O3Pꋹl��۫���p�$j���O	���5��k���<�G�#�""�G�m�n��_�}F~SWA� ��à[��٬�O�^�8�1�x~���kD(�>M��O{�h���N3m��{߻�9��*��)�Be
�K��29����|�B8Q��5�����,7�f��w���ᵗm��a�N+s�-�.Y��D��ך��7ê��B,��H��i�=G�T6<�A�������o�C^,��73k�gt>h�a=:�Z*��?A���H��k�}!J�@���I�غ��A�!ڭ�j6=tiʭ|�N�N��[{M��`u+�ve�����T#?��i�D���?��S�7��T�y���������z�1/���6!4#]\n$�P�����������=���8������B.Iw)[�����(�3A��[��A��u�K8M
<�J/���Sm�a�9T�u��]S��t8/�Zf�r���%�:���ї
�������i�fnap�KAˢ��J�ae�ա��z{i�>7L��=�v�ѥ�1��2��������e�0P@�)_��*Xݎ!���aki�tF!�R(>�m%�x4?��/���p��}�kz)�q{&6&F�F~+R@�[���k��|Ę�f�B�=f#'�z�?�&-6�.�i$��Lx���I8lp�B�&>�n�&�>)y���_{���*.����b$�Hw:N6b�tW��B��Q�ª���L]呔���n�F�5�TЈ�`�x]�7�PpH��H�R��������^��S�PZž@'/��Nþ� T�?$z$�;��*��C��l�\-�m�n��άoY�q��
��懃�@��@( v�_`?+�wh�3y	a&�������K�����U%%m~�)G�n%r�;}���ŽOk�3�{P|��[-�7Ry�g�v��s9��f��d���ـR�ޘ�����̿(�d�oRҡ��k��t>�x�t%�@��H��歂�;�V����(S��o��a	�9TNR\s�o���F�/� �zg�.��v�o�^�$ l,ˍG+�e���r{rS���v�����V
�^'�I��`�����^�g]1��?�%�`��-ev���L��D,�7�
�vN%B<���z���̀m��@��cO�zח�N7�>��r1EX��0��K��}ê$ӧ�\�|R�sCzL�Q{o}ܒ6���Q��"�	Bb�?R��5H�����������#e���B���M��vO�CWJw����♖���9�B��Q�/�� ��]��J'y��PQ^�����[ҥ��^'t�[���&����*�����EBy�i�1�n�8�Si*�@L���DL2�B�R?��Z�����zR/�)`����	;t/ESVIt�����
w[�d�u����>���7'z8�e/܂	�ѷ� ����j�d���\���"�'����-!�%d�S̫�_�PO�]�r�!�)�c��W7	��T�ӕ�G'+�Ma���a)���qi�\q1��U���L�[i�NC&�[������.p/��K�ߪ�U�����%3�,{#9�* e��)��A)�G��HDj~�geY�L��Ҥ*��b*Z���Ǧ�P��a�-̡�-��#���g�����ZrК�UsUQKe�-9�����eي��$uۗ�v�%@i4z�T�'~�|���Gg��� {�~~fݷ�����Z����~A�@Z^��b�C�yu��tMj����WW��-���ee�<a+�d4�©~5���=��O��C�d#��v�'���'���Y�����m�x�;�FL�X��Ǎsv�g����J����$��)�{3��@%z�u��~�?eN��|̙���-����T�#���l�6�U:�������,eJ��/	5���=4!�ڞ�$#33@K��C����ʶ�g�;�l�}��δTb��)o�S�P�v$������PUꬮ��^ط����n���Re�}��O]C����D��ȟ�D�MfuHbQd_(Ǜ��L�����/#��/�tO�@E����q&�-q4B�!߱�0]��ɗ���Q�nf�l5�ջ�� ��=�h��Rw0�k:�UK�D����ˡ�qi�5lC��I�C\%�a�9KM�KԷ+�`�=�f1�K�q6$��TWå�2�%�8 |������5�0���y��������w�<[�N]V�C:$k��(h
cj=e�R,�����:�O��5�5�k��:� �Q�炪|Z�,�!��Yd�����H��g������k$2�*�!^Բ������7�U񋫏7�W�?��*b�U�D��%t����:�!q�8�N?�� �L^��*�!���&¶���"���ܝ��������9`&��6^�oSe�w��ɯ�-��R�>�}���g�9�����j��d� H�3�P$�C��=����Y�k��G��<`)L+�`�qW�p̨�m�M�����{�i���������V�kUSC�\�W���&��p��J�n
G�c�10����.qkg{� -t��j^�n��_#�b����觋.%�����wƼ5�:Ş-bh-�⪚Tr�V#EM91���h��.`3^���4i�<��������_-��f8wgL<:�6��w�,�]T�RU��u�ˬ�p"�z�T:>�Y�eJ�����͍�����"�������x�!b�G��X�[}4W皰,.�\
���;��Gv�nqCORzІ��Z;�2���yC&�q�}3�_3q��]��� �e��¹�b!�n�S�z(�8ƶ�@��=�)
�m�C�i:\�&���ָ0K�%1\�N{�g������Zo�U�Y��š%�L�������?�rA�d��3���F}@q���������a߳�=�@�k��'�Y��j���b&��� 
zI \���?M)�5����p��>5�������)F6|Y�Ȟ�k?��G��zU|>��meK�$e� F�Nk� ��Q��?X�l����7HLxC���VQV	!O�Ǜ	�)	��433���g-
�4��rQ�q�춌h!)�ф1�>����ZntW���ߡ�=�V2�M�D�� ݵ.���|U=WX�lLV�۲v��<o��������Ý������#�㽆�?�� ���]�}{�ŕ�>Cv�&A�4�iR�G��Y����#��
�|E� ���d���_5�yAP&����\��D$,����L<L��p���c�Hha��D�bi�P��r��> i2�8�˘Z�i�Z\�	�w�<meKW�~�������4�ف���)Z�?����(3v�X��Z�=�p���<��n��k��z��n�gZ2�oM�m���|D�9]�E������TR��}�5�ӗ��co-�Ez����
������/���%�l�SYk
�O�:�{ni��m�G=ڙԡ� -N`�-��24��x󷔶�T�Y�m^g�l��䛣<�UeD_�C����5���YP�Χ-�e���*/��,c[�OF�g�03�mL-u���#� *B��[�H'z�M��3����խhn��"�Je�愴Q̕��k��B��Ӑ\���� �������v�(ܷԩ<%��|r��"�ǰF�C�e,������q�}]��8��0��ܧ����ڒɮ �i��l~;��~�f@<_䠳�i�tI{�2����֩�Pp��zb7�N�ZD����J8y�^aV9�{'�wEk0��`��.R\�'���]��1;4y/�#��6���6MrO�|)BQ���c�<w��	
K�m��
� ��Pɪ#�v�(?�*i���Pԫ�mĆ5P�������.�>�����K��ْU��w)8�J¡���c��\�^^R�q"�iW|�w3�N�LT���"2n��bʆ�$ #�h�=�Y�p$"��+�ہlZ��jI��*yG���]�b��j�O#ю)ߦ����**�TA������0a �?a(Dh���z�o#��;��6�u�zb� Ui��I��(Y�k�Kj�����a�%N���T�m}�نf�˄=ؙ�8x|RY^�]+�s?�,�9�^�O0#�1��E܇��s�"��M�V/@�A?Y�Lx�g��<�ѭ���g��l�ܔm�R��du�ǭV�I5�H�\��^/AH�'0���G����$@O>���-�[�0�VzyV �.�k~^����:J����ћJ�2/��C�:|D�})�p0���z!��Ԇ�X�l��5c���@<�rt�K�1�='@��^6:\!!)9�p��'V����B�L��V`{&�L��;�7K� y��3���Y�j�}D2�%��c�mb�ʘ	d��[��l,+� �/m�z������c��8�~Q���Rz
^�HthpV�@k%�c,V�X�kn'�bG������B������������{�4�lDnRȮ焴/O�
�e>��њ�K�w%��Z{��"�"�}]����N���ձF�L��k��у�7+�kq,���Alv}��I!�Vi���g�������k�!^r��BC�}���^�����c�F�/	o�z�.����zn�&![='��{��Ek�J3[s2�Ef��P�F�{9M���كu�1f��a�x.�u��#5)���:7���}�L5x���H���0�5'��$�i���e[~�<]��'��Vt#��?�nJ�1��R҅���9��ɣ�Y� =�>�y�>���]�;;�:�ݕ��L=� ^����ߋE{	e2

ۛ_�F�D(b��*�;Bc�8�f��wN�U0F��HU�����5�V3������+�1K[��xf[E{�<��w��O�خ*ݤ�EA��"����|-qm���J��]̲}<"�x�+���ؓ�ż��ͩYi�d�����B�n51
>���z���9$�Aw��DJd{i<�^�O4\���b��Q/t-���	2�IL{s+�p�9;%+� ��rS���L_�s�2����K�JwXh� �u%��&}QR�ob�Vz��;{ny6��V�P��v����x�F����M^��j���.�(�o/�b�Q��ܒ^9��T	Q���.�:�a{e���x�u���/dS>�L�$��q�6��Y"�0�9�-��s��/,��n���G�����mS=�<b���!κw�A��k�c�*D����+�b�^v:���]בzj\ް������5��f��&�ܲY���*t��0ٯG���1�I2�-N�����U��f�-l�6Dv��V��T�A��C�4CLm|�A�X������"�ɹ�h�<���[)�?zt���M�>��C��pKr
��/�"�(���9�r���%�xl�=m��h
\��{ב��<���n<8�|� 2���o?7\��,pY`!�ع�:���K�����wc�ED��|��,���9�D
����!]z,��	NZ��K�}�3ˠ�J��Ɓc'�6��3�Z`($z�L��b���j�x���Fv^V,�t��n`��jݫ�!�27a�C�����N7�?"��nT�����U�W����̅4�q��!��n���5�Ap	����D6#E7�N��oo��TӦ�ਸ਼Jȋd��.՝~ EG^��t�"��NZ��[��Vg�d%��u��A�S�ME�J���[�80d�Ae�f��N��|�f���:K�&�v��MrM,8��T�XJj��7=�u8�(�k��ɱ�Zq��^I^-�����b	<;SW�y�%�jR.��<@�1�/��,y%3�K�	Q���J�c�>��j�P����X�Us�Z�����Ф*���
w�
BF���罠��Ci0A�ȇ@$!������C�m����cׂ��|��]YN������C �ӅK��90vY���nB��o��ر_Sn�^Pmw�TR�-��/*�GTؖ�E�h�O`����!o,�ɿT�TѬ*�z`upwye��Tٜ�7�ZH��ԯ����E�l��⶧���1��~S�A ��W-[��F<E�"?z}���W�"�h0�`���"��Җk�v�n�K�iH��YjWp�;��G̨
�����?f�U#I�t�������Uv�UM<��8=�p����%�Ѵ�2���sRËPׅ\�'�+s�4���򹚙ޚ�;RZ�U �N�n:�v���%�0[�W�;��6�n���K=�7�N0��s\¹3��|�%(�T��ԔL�/�S̎An�n8�S���UெK�8�߻��+����\��%�'�~��#��P���D���d�EM�pe)u�כ��J:���X�#<4Ǩ�-������Y8�:�)��u�g��2��n�=��`;�]9�H�y� �G��S��X����nU+����2�����T��>"���<�할<,0`)�Fl�B��z���5U ja�������}2ȷ�3�ѰBG��&� R��s�Em�k�t�RYi�j��AzZ2�4R��|�� \�����˫0��5|��t�c��V���L����ƹ��6vk�71vl�g�D�!"�`��jn`���W�e�ޱk�Gn��
�sA�쬴��bO#��S<"�o+6��6�j�܂5���]ʧ��QHaQ��_-=ܵȠ�#LN�iQ�Q˙d��$7��x�;���e��sa�ڻ�֛ kd�3o��e)g�ŧ��]���E�+GZ㍰T��ҿ9^�ؠ� �L��:&(��]w#�A��,��އ�i����/�]��α�*ә3�;�H)�ɘ{׏s�'IUʓ���G��υIx���Z��`����v�ſ��0EJ��΋������9\�Ɓ'Ն���!���h1_'��课O�H� �I� l��]7�s#K1g@��Im��W��:�v#V����6��+��*���x'�Ak��%=I�md1ɗ~1�U�\ʁ,ಕUڒJ�U�τz�!��EX���0�̻��f�뵡�>!@&�m�Вu��j�w��<z��U�Q2!�����P>������RuY"�Er�ě�0�	Xjwk&���أ�d]�����_Ϩ��[�8�@�B��,Br�e���i�cʋ�Q�z�����g/��t��!F���<g��`�
_G~}{��;������G�\������`1�"����f�X����a���4N��a���x��=�w��E��k|�L�a�{P?#,�U��@e��@ >Tަ�GN[�,�Ҍ��J���%@D3F_[��-L瓅�)��G�c���g(4�|��!�ĤsԨ�4�v�x�������,-x�3���n|;���IR?���X�M�<�F�j����i��$�2�QB����C��n��Vt/AIxӍ�P|/도���!��i�R��!B��a
�7�A��e�&���е�7}��kS�l��XEaX �������o� ķ`����Z�=�lB��2㳒	��D���D/�U�ҿ�O��o{l.zb7o��Ȼh[��	�/b�ه����Jp R�Z�zHf8�p1���{��h���?r<R��$%a#M�!�i'i6	�3�m_��.�)�-/�q�G�c-���-��d8��n�}�3�[!%G�� �n��@|���T<2$>�x�[�����w�O<�L�#UX!��g����jEt�l]{�5����O}+:sb��Nv �O�����/OxRp�M�(qW�`��G�{D�NK+��4������{4���Ek&�?�R;&P�qĮ����M�]��=r#X��M�)�����)�.8W9'Y��	nT�s���Ӧ�x���J6� h͑��j��|h�-;l	�$?�CmQ(,o�?3��=4x�RA�Z��,�Q�2�������N�t4�y��%��"3�<�T���bT�[j>�����7�/|	���Pu�F��N�"|A~��(��k6�>�s���k�'��� S����ѷ����q#�c!/�7��2)�2P�p!J���H �|����p�(p��]SF��Q�����Wum=1��3M)~���}�)qEw�o�{��D`��2+V� ��1X
��1S0o�1IJ$�|��S����v�L�$0'�0=���$M����Ӵ���bF}nU�4 ����7��u�)^X�4O�&�Y�$D�$�����2Jp���k^<<�0�Ү�+>�[t'\G"K�s�S*�rI��I#��RV�:wAl�Lˏ�#�|$���C�7v�c��ş�*:���ǁDje+>�u���C�c�B�O�e��p���G4p�{ �5�`uF-HFyxhz�1�ԄJ�6H ��q����ho:e��]�dp�+��;��S�{cM�PvQ�����ˮ�d�!1����yRy�U������f�����4R�Fj%�-�~��<�d�Ȓ��&d�~	���R�~�a��gR�N�(:ǮJ��_!bop��kҰ�L�.za�Lg����O!Zlv��o�d߉���dl��� �0�)}>5@�����������OHq���ҹ��l�m�Ms�]b���V���]���?M�}�g�|Ԃ
HY!c8u�̡hB�J_y��"ムx�9��8RRQ�.f���M��Z&�LO@X]z0���-���\���F�^��_fVс]�NKϨ�^>��G�j����-�ieWѢ���O��i�>��t��όˇ;L�JK!
Z�6�@kQ��<5@��q_��B#z�������)�Yy��,�)46f�&���02��B��k�����_�3��X*�b����u	x�c����CBI�������c������'˷���~D�2�i��'7V2�ގT.�(5��y93��.o�I#��p.u'�a� �~�r�8���E�F&>��)(��s�@���r�<�����D�j5~��e+�n��rk��=^h��Ԩv�T��|3�g�OeS���r�_��zQ0��p�C��6o)$�V���/�5���<�blq�x�D��"�F7,A*Q�+��	n�W�Z���PqF�͍7*���k�K��r8�u�[V�����y������^�4�f�M�DG��4h���� 7pV���� �����}����g�    YZ