#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2592133703"
MD5="498d871eda8395a8fea04e489e99237b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23312"
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
	echo Date of packaging: Sun Sep 12 19:16:00 -03 2021
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
�7zXZ  �ִF !   �X���Z�] �}��1Dd]����P�t�D�G�S5�X/�p��ɐ*͞�-�]m%�9�g�s�����pet
�f�$[b-0�HbQ��<gd�o����ž�Ĝ������tPa[C�d�Q?�G$jf�wH( ��@1�J�Gi)�G�_�#Ru-/��[����s�[��Hr|��wTr��z�YP���餗JV�����6�CԹ6̷6���Yd���l:�M��z&c42�tE�wG�����4��0I��S��C�"������Mq��Kq�3Ѧ���-e�mY���2`�@����*�j:`�����x���K�A�R�����~��]>3�T>�Fz��ɹ5���/��ӿ�ũ�w�R*��Q2,}�K�����r�1��1P��䛳i��p��8��-h���Y7�L�_`2��H��=	�rG�
 ^�X$��V)�tKB��V��u����Bǝ�c����ᢓ�2}�:pFL1��Lr���/#;!@�ᘙB�˳���$����f,m�^�G����vr�^���N֐_
ʢèE���
��k~=:^q���፠�%�E�H*oҢ��z���a�/r��Ф6�+(x��uY�#���b��m�/y��Ƭ[)��<���}nz?=t�Ø��\�jeL�yI�H�'�u��������Y�$�����N�;�9��X�;�"d[S��p6/���(jT�H�z0MOZL&m*4H�}**n�z�jnj��- &�C�,L�=���<���X��jK��g��ቁ��ɭm=0;bU�r�,�m-����>
`>YM㼿Q��#]vGs���%�C4'ٞ���.C�>Y�F�7*�M��h�&�A��i4R��W+��v��i��%������>�i��D4���/ҲՐ��O,	�����2�#�\�aM?���H�A-�d�|̒H*b!MS�������À�7�1�@_Sjs�hrn�W��0�;b<>P�4ہQ��t��©�B}��I�z�~���W����ܧ�E��`>Į�ul���`J}��B`A?L��P5��'�`pt�G�a��]�\����e)�ycBN��L[*[�rR �ܴ#���$wpKy���rS���,�Bu����/�*Yw��Ԗ��`�D�St����Y3N�,�KԩW�F��P�,)g��P�J����!�bC�c+�J��Ti��~:��_��̙_g�2!��4���ʊ=��Ŗ�G@��2z�ԐSD�)�v���jg`��!�	zp�1���7�?��f��e�	P��v�9�*@}QB�>�z���R�t>����II@�
�o��9�>���0m:d�8��2S̷ׁ��0,y�`0��v
�Fջb� aI<�(����HT�B���a1�:z����A�b7��{�%w�mM�D�m���P����?�2�2,���5�0�`{ԉ|�N��V��(���<G�ob5�!=�0�e��J�Kl�qL�p�9�N^�3kl�:K0�?��imH��^vY}L�z��gdxǺ^ze��ٲ ���ԡ�Tc�t^�7_s�?��l%�S�`�O��\��ٖ'�Ss���mi���<m�v�n,��ėF�*Uo�\8iC���J��M��q1FJ_Q)XC���GO���j�~�ڝ��^���oi7�Rڒ��9@�5���,��h D���x�'랸fށy[��g"�����bH�/��*�Xds�I��3�D�!�G��0њQ�ħ������s=��Vl0-9��������r3��"�b��e���Z\f�& c�w�씲�es:?��DX���9��&�,묅KR��D���xD���P���l�H+�z�Q��E;N�8&��]�ޭ�r�� b8M� ����k�"�����X�8��c߾��W6h��f�W]%�5%e?��0K��Rν��"��?ה������9C/��S(=g���\\Z��*��V|q��[��J�%���[`:��V�j�nft\�V/,'�4q���y�B��ȍ�|��z�S�8_4�?��*|���c���g {x��.}W�!%���L�V������%�h�#Ev��ي�2��o�v��5�A��!
N��#����t�`��O���e�7�B�����q^��M74����D9@�M����s$�3��?u�D32�<J0W���p��h�d%Gg�?w9�G����� ϴ\sec8Ή<9b�2�o��&:����ئ��}��+%�HI~]�p�9���Mm�sfH$�~e0dΊ*YS#��IIPJV~��t�{7���ɸʑ�NS}��H�#�5e| �ys��%w�}�ͣ!Rz𥟟8��Y��i��m���痶����l�2�"�P(��ho%�i����K�h?���`�l"V�	��A��qnX�/uƾ�ug�=��^N�kو��U4�����傢��?Qg�|�&��F@�)�_Rn��kȵ�46��N�ţ��p��V������ �[̛��_�Jxz�fvN8�N�I!b ��+|�=
�����:�`�J3��g1� ��4Լҥ	K/Є�=:s�K�I�M�Z|��=�ou�]P�g L�`i�#nZ��Pf��b6|�~z����֡&��#	s|V�<2>�}`��xU���k{{~1���tb|u�~f~W��x4%*1\8e�:!Ey���y��=�����r�<���:_�.��p_���㴿��yK���G�!祼E߈]^M��J����^��E�=�_Fb��y�f@�+(u\��x�8�R.̬h�7 �k��i��I������S4�ŝ�pu�gX4p�4�����E��H�����~������fpuD����mH�O�� )PDC�l1��d��Le jw��p�k�h][����6dQ�]��An�	�%�� z�7Z�ؘ��O!���{|��c��3�I����@��Ż�	��~�ɦbԴ��s J�O'N��6������.�뵰������UvBCP7��	}�3%�=C��B� �zz�z�L���RK�X�J^Oٽ^��n/Y�Z��48n�إ�X4�������Q��?܂W�ÛD�����0�(q�j��.��"&Ո�l��$�P��J���>j헵��t�ǆ�V��C:��,Kr9��@������jfo7w�����	���ᕰo޽k�@-|���� i�#P��[�0�mƏɿ�W�Tj��]efq�E�Ю���VP-��񺭉y�~�#��ڍ�m@����ᘓ'5؊�)Wu���&�e�d6b���V ..Y��G��e,9��M_G�)���RݲkD���/Z��a3S$�kv��2���X mo��u��2������a� zL���6v�a����.R�����
Q)b1I���C� ?�� �����g�v���]��>ʾ���yꟆWj��h���s����HE�L*��)m��\%�8�����F��Q���fgI||�d�U)6w�T�v����K�ީX^� ��?0���vyE��H�����U=��BU���R�l��(����*��p�X�:|��9�{����- V�$m�<���>(�����X�Ǚ���]��v���Oa��	��I�����v�S��`V=.s9�׌��T��֏/vLH����"��]c�Ƽ���� �[�3�ve��}�$�{�V��a��6�"���w|�t�-�{��{3	G%Ph�Ixf�=_�`x�Mt�p������'��a�j�q9�P���!KB���oŚ�#)Q�cQ<$�[��D��t��MC�[��C�nb?�D�%[3���|_�,�S����E���F�I��%�}̴�厡�W'W�I+.���q��^d"�d�Ovf���x���t^<K�u6�����J�Y:�%�1��
g�M���k��7�� �x��Xiؐ&���?("�� �S��*�6ih_B��v��9��V@���7��� �X��1:��	���m�_-*s�^�]���`�֧ ����t~E��i��V8N�~6c�S�Ó��^�/���Y��E'G�2�Ҵ?z;C�.�BT�h������\0kd���g0�q��$��w�>�bʕ.O����L�2�6L� �j2ԏ�����X�-+4}��F`�!2e�Rʲn;�al���L!8V���1�6�a�}��2�e��7���ٵ��q��݅B��@P�2�)j]�#�O�z{ٟX�Ƶu�1�t���r�׬�%%����5Z�A�K��K�	N�T:0d�&�[� �H�N��m���x�^��F��$.��d��\gkKL/�Z��U,r��?��X�GdY�EoB�m��x�8�o0��e���ʮ�?�����Ȼ#y���DHa]ԚC��.��e��]O�R#��-�&@!��h�a ��	����z���<ie�ؓG�� ���C5�|J=2�E������P��6˾a��ٻ�)�e��H��h��\�z9��X6ƭ�:�}�S��L|�������Ҥ3��8{֙�[2p��"���C�	mO��}�B��4nꎲr&~���z������; ��=��5�h|�`h�%�[<��ш &�����I1b�#���h��w@ lM��":�#�֓�8"v��2�ť��=�����ٚ��a8�t��,)��}�O���B�Vv`�8���2E�=�)"�u�����t4����j��5m�	pk��]�j�)IlF�> �d��UUg䖻K�{��L@3o=*�jf��(�������+B*]��N����h���5xG;�q�v�%�\�,]�9͔��=��or��ŌA�*G�^~u�L��`C�����E�U��yDj�?���ZԌ���ͬ����������N�>,�W����5"�Fț��z���s(���ڊ���!����i���i%w����N�Z�% cu�	4�z�ʃ�&��˫TU��Q>��R��E��l|���|�P��%��?5���ߧ��<�˞Y�9�0�������2���rv��7�C����2� �
��@Z4+�,5~x�Z�˨��#��m Pz�N&/�*9E͝h@��؝����ͩu\�����862P�|�B3=ԴH}'�i5 ������iiq��'�	t�氣��>=��IC\0Ԋ�����c����Έh?�ŋ;�o�ؑf%��k@;�v��'�DΖ�9�[2���U;ށ�x��dŚ���a]X��5�܌|�n>h��w��z�g}���^y>�sOS�А�;��I�ZZ߉8��\���� ���0�����ƒ%&
)Cg���B��[�i �VY��rK�ނ����c��F�9�r�V�H
?����X�Mu�>������tzwd�|]e@�$�x럠ە."h���
7��Q��3�xplp=�:���ƫgw$]	e
�����
���v��T)��.�uj����I�'���Pn��#�C\ ��,�|���sY�C�
�]?˓:�����{������>�
&Du0��<��{ ��?�ԧ��f
E�ؚ�{+<.*YE/��Eʳ���}��ahpĺ�o,0ZUB-���1���c�huW;�rЇ�mg�xN:~��ڵ��8�1�%���;�T�f���sAr�Ҁަm/�˼�ͼ"�a"��I�K��B2b��7bz|Xϒ�҂Q}>]�v�����(#|x��v���?����{�A��Q�{��{Ȯ�D���RT�G��̑ČD,�a���cc3�'��"�!�o��Ct]�n�:'F�:����?�f�[u-�����^ӳt�c�C��Q)ZD̡�6���y�)2�su$!���ە������w�B�]���H"@k�B$e�}}ΕӦ���d�.8�RS��A���>�|�!c��q"��7����Xh�i׽�&�cGC+�?44N2Z����_�G"%t*t���n�|k�Z�"L�"�t���Pkb6���ϴP"ML-��Q���'D�IF�@D�6�����ztk��z�q��;�N�4{@øv�h�hs!�Տ�u��.��z%���J۠c5����^��Ծ��a��M!�( ��ԓZ}����^�Y�&���p�@��ڃ�Q� ����!�jr��
���KbF��,�W,�a�॰$dƣ��e�́�5Kï��8�6D���s�����#����B�z&d&\4]ĉ�G"8�������D;!A�,OW�P*�'e��7�:�(���9;��,��R7�ٚ�
�#%�"7#FM�����ي&�K{>cqב$uf�Kcw�X����B�)���o�}�@T@ �y���<1+A%�o���[��qq�Qm��Λgf�%��i�����ޑ-KKx����r���ӗ��Tˮn�6v��H\A�%J�v�"�7%���F�f0x�`�N7VW��a
QW!�b����jy�.��MJ�ꐝ���R2?+.d��6p)�F_6d�'|����8С3�b �ln�(-��^�\�
#���v6m)��=�}:Yf?��_W�Ur��{Fo
jS8��c��8Ѕ�vW��[��\�⺥��}�JlPV���1�W��H��9մ����,[{�7
��������?���54O�Q����1{l�"��Ave���x5P�{$�rA� �Ƙ@�����}<^�Z��~�@�\h�c[~�����$j	��?��8�=�%�q<5]�pW���Q�.˝�J�ڎ�'{Sb9�O�����{B7�%�ݺ#����J_�F�v�*Ʀ	����J�Nw'�M�,;y6-�����o��㍼l�&6�Yd[��1�{!���O�ࣝg�%?�9�|z�#ľ9����mhb�����`��si�N.�"3��
Zkj�}%������H��6�N�߆�?�H��le�}y��kh�\� M��{>̈]��s����!ЖA���	�.>g��N<3|e�۸0���UҦ��&�e5iR=-���W�V�yS[��f��ᤠ��o�L�P����X��!����FkxnL�M:�<�c�/�n\0bF�R��ݜD�I)ȱ3��=�Y��FW"�@֧L�`ԕ�G�����>,;.��罇L����j����<¤�7O������Ns�4JD}��D�pTk�cfμi���b���|���c3�����a�d�'�"*%^��I�M1!��Ӎ��h��>���p�"wo�gw�a�(�<IR�4�%d2�	TQ��V�_�������|#�g+�~HG9���8�]�������a�?�=��QiR���V����Z�e/G	�/O�u�7��4��$�ua+�km���_f�ӊ�uŠT��t�Ә���|�]�~��9Ch��y�w�����̜�
w;o�?��G�w������yޥѵ��p��	H���T&C�>�ϫG���$�lfVS�h���{鯱EmD�\I`�FMͷ�RPe����b$�(�x��!�0�^��3{b�R���ǖ���[!��O�]�Nvn������)8N"�}�c�x�����]�i�`6P�!�'��[��4b�e,8�͐#��5X!��<Q�e:@UT�Z��p[t[.u�H�l}ӑ��w5���x��&����Qk��r蕬@�C���
&���aB�=d�����ܔ_�k�����ƙ�G�9�@ ���hn�B��'{e�����w��Hv���E��d��>��N,�!��RM�!��̮�Z�5��~�i��;��9���j���P�ղ ��JdT)�|b�?��W���,�Fi6bE��S���z	����R�s��j}�0j���|�w�^��ylk��N�A73E_���v'S�ܩ�ψ��z��^�$N��~��~��C!�=��uٟ��nP�%h�㥨[��œʂ �j��Aw��2�ZD%.S}	�
g<v'$�������'�*({��0�S�j�N}�<�0VaS׏�p���g��K�'�l!F�YH�/<�H�y���v��$�)��z�%�#ś���E����'� ��/���'��4���;��s.��k��,�Sb+$#݉v^k`dB)�+�;���&�-R�W�G�6�$X�;��|�H����AjD�Y`�uV	VZV��������mz0��eHb�z��D�����A���9Y���6�	k��|�5i��Ø��ߑ,��Ոh.��6	����~�%���ԄMl>�I��a���&�,!�:p24
��#^]i'm6&���U�A	��ذ��̋l÷,�|T.�bC�ќ\t�o���1��_%���2"M��v�_?/�H����.f�i�/e�w�k\`���r���N��k8����z��8%�T%p������-�*����ܤ3�:h����toY��SHƖ_)ZX��(�fu:IF_Hǖ̯eC60m �B�{g��S�����#���b�oM�Ny90�72�!	���c�.�SK���uP'0��T�"�`+rϚ�O�%㈮���W$}��d>��i�TD���g���O�aR�z/E��x�Q���NT��WJ�ۘ�(�rف���w�X�0s�C #����y���6�0�������B��LY�r,%hb��t50�jH�a�	~�{�&��V��D
r;3�{O#�N��`�*��.�f�H���K3_�j0� |�:���2�5BmXuz����3O@���Vʲ�l gs�`7��x7Uð�ب��� �id3	��B�Y�ͳ�����5v�s���qrkL����&n����z7��XEh���#�e#~؏�!�Y���I�g���~.�(d�[$�k8�l3�:���%�Z��c^;�~)�"�V��\PO:@�#��}��w��~a�Wp	ft�U3�XtA�W��QM2g��+�L~Nu<V<;X��W~��d����>׈�))3kX/x~tԕ-��&�ƸL�η�n�Ƭ�݂�͛%�c�x�}���Ic�KB"���D%Q���"Û�9��G���� ��#���K28�#�|2k+�Շ��/�f?���%�|��Yp�Q����H��ԑ��o$��<!�].h�=������C�[��^��;��$I%ƌ���ePP���U5$��8�9W��,�����[%�x����7��s+�J������p��������p�e�������u��GHũc�\h���T�'��ݶ y	_�u5���������-��)+onG7�Ū��J�B��{,�2�V��)$�0l����*nw��q�=I��Ӆ]����a[�q2�53
׋ q.HFt��u�5-q�n���3�����{u�]L�3���HB���v����b9��!G0�B:g��y�U���JA�zF)�J�Xu{��W�Sڨ����yj*��eJA��	�ٱdr=�I��k����BX=l�ӹ���v�R�$�'�����v�E|R+yYK���/�j�H�"��Y�".X��:���
őe���6��Rs��a�f�Jڦ(k�����#3����3o!���D��/� T�	!zQ�t��5�������K:���<�dQ�߉Qw�5�w2��`ך���q��:�������:�<��Sq��m��M��8JC�D\)����)��b�	Z��XDV^�̧�aG
�/��9�U�2��pff�R=ɭG���N�����rX1���+��p�ג, ���$�&��8�5��h�*{=�t8��6���QN�7k��rk�z�cH�ҧ�%P�?���J�&F.�Kʌ/�ݿ���Gy�Q��B��:�J�Mk�bS�Yo�7ō�u�`-�LXƢ�����hs�N>���4� �� f;��ҡͫa����.��ݸ?�x[C���?M��Qa�y����dd9���j���3sR�!��L�ѸP0L���Mx��J?k���qb�L�b���o�*�^�q����Q�M,�Ѫ�v>k��qs���!<�w�c;�
5{�k�~�Ku��Ɨ�had!'h
0E��G�L,���/��!�
�ڤ��W�G{��� %2[P{��΃*9��_fu���n��s��۫W�M�7v��{�T`�o��b�^����Ė�Ÿ�<���2#N��	 �0h0�48��4��O�]�I�Z+�I�����u��+c~kD�}(�C-���~�F[YO�g��QU΋�Ƹ��,�#w��}N�}���J��&�qm�_��>�L����Po�Yb��w�E�q�_"6xG"�}l�.H&0��~��[nB�O��|��)�1���=��IF�����],M�~�SYҢ�f^��p$�jM��xTy�}��,=�r�յ��Y��b�P4b��/>� ��؝�N;s<����TA-`�|[���g^>^�rw�>?c!�k�M����������@�ע��P�*9�{Z�}��
 ��Ȕ�f�e��A�,��w�>�!��F]�03|Y[q��d�D�����4`i����G�yR�ڦ�G��ӕd�7G�~ki.M)s���s�+	�6<�;���P+ 7�K��y��{���a�0�iq��x=�J<��z��jġzP9n��=�9�ڷơ[����� o���Hh������R��b��Q�fsi�nk�3��	G����Q,��K1L�x��Ѣ��R|Dm5jsO(�:Pľ����E��7G,HG��ᚯ�����*aCdv��c���t�rQ�w�L?�e�
��g�4�*"��|18p����	`��5{�?\��oīX�"Ѣ�]���Y>Ve���������\�>�������ٵ�ջ"/%W�O�:�N(L_�5��j �/X�132��ƽaE�w����1�VX��c� O�7��Z � ��ȶ�`=��I1�bl�C�\��M�Wjh.�RF��f�d��O"ַ~th(�j4{��f�F&�t*�bl\<3Sh� z�	N䗥ȥ�O̹O#�����h."o����3"�.��}��e�(a�p���@t��Y�l��s����k��Vrh2����ڗ�A�����{����i��
��:�A48KВg��������Op�|�Wgq��^���u�yȎ̩�.�F�,�c�qi����|l2Q�q��E� g�d����Z�%"��E��J���h�X����S2�>�
|�d}���6�yL,��y��Up4#��[�VR���SD[b��s.�L��yYv6
��LE�<`�WM�C�7
<���d8�_��*��YY��kw�;��n~'H��p��D�=��3�Ӗg��R�A��j=����G�N=�!�7�Y.��Juո�˽|7�n7��%5<U��p~��#�P)�j�N�O����%�F@�9�<P
|�n�4�-�Lc�sz<Ɠ�9���\�(�0����Q$���i�+h��5]ܘҀ���V��cFN�Z�}�j�@v�@�Z�x������ۆn7aA���=������|�Lʿ	m̋��\|�kB�'�oI���˽�ٙ�P�xZ��R�˟���Xj6�w����f�S���]Yn��I$�k��&'�ixh��b��
-��$��/�J�!�޺�����T�T7��
�YZ�?^˘�R�\x�6m0�*_:\�;�E}�;/9s�b�g�������W������F�֤y�J�'��k�h2H��7��Έ������@tw� ٙ"^��vDK�Ҷ+ޫ]B#l,i��/�-U���<�e?�_��x�>�Ċ�+=Xl�d�רj�u���1��C�;'U��#���Ց��n�i�|�ފ�s�6��0�+X�)��NO����Ń@xuuV%����Bl˃J6��$�������y��:«�ǧ�>���p�BSr�cO��w���l:0q_Z��w�Tl"�������g9m�6XK۪��WP�\��]?b��/�9+�h��=�e$&T���@������q-�
4˩KP=�9ms?�Ky�?
7su�Hr�>�8�$��������U=.��_�s l'�����u'�s�FZ&Elķ�"j��
�2����Ej�c����
��EE��Q.�B�3h�<$1��Z��Z"���Nc��.�{6�DA[c�m����\�1�xc)��֮s�?�ƈ7lL�Q�R7P���PX"�^�#����g+�;&^�5�u��	E�eg�(9�<�+b=�?V�ோ�)\�����$z�6Jx_�
�昭��"o�W��P�Խ,�	��q�w�%��bS��iy��#K��������<&�e���=�2���8��#®�@y*�0)��<N��l�Լ���E(�/Ղy5�o��c�lY�x&}�a���]�K����@0��t�H�Y��w�?E}��+m�,#r�Op�lo/�@�t�����н�LOf�\&��	�0�X�,�v@�LƠ�(���.�o�:�$�ޛ(P�
0�ڷ�A�c���y�h>��Au�0�
��3��V%��I9�zYq{�=ѧ
UЈ(�JO1���N[��_�bLn���ɫ@9Fe�CQ�~ژ��{L��>�h����ή�1�mô�Ύh��v��0�c����r�[�:�oOz9Ha��)�[�"Z�x[�y��b��3�;�~:?̃��6���F&Y���"�5#�PQ2޼��>�S���W_fm a�| ��e2p��`����V���ÆGj��^w�@� � �8>#.����a� j~;�����a|�V��� �|h`���d���<X�S���[)�8��咃PY(�2f��ݖ����|��p(d����ܟ�a
ʠ�i�g2 XQ����4zQ�9�_L�)�޸����ߨ��"��6ʁ2(�(�cS�k�V��em�N�ғI�/��!k����<L\O���s�?Edq�db��,B�cA�<`�}�|1v��""����낤N������U�~k��/��7�]#�E��Q}�g�#�EHzZt�/�R<h�_P�N�����.�i�^���;u�Bd��!�TX;��X����P��cTCW*G+a��Y&4-Wf:m��s�H�����N,-h��6�Ŷ������2�3�ķ�X��s���>�Yw;?�X���d$jZ�H]��A��4}	�+M�i��~�:��p����y�N�=:NSŲ�&��5�ax��\��(W�1����w����Αb���98d�L�iB�%}g�o�`s�ių<�l�š�D7ڴ�ZA?�G���7�C�����R���'��y��M����0{�j�+/Z^D�ۥ�\~��W���]�ԕEX���;��h��:��Hb���nМ�����HǼI��_���<�!
W�3��z�z���\���=3O���&�"�>�W����d�"xD�\�޹s� �{�\��Q输�"0���#Jּ����%��E��J��0o�����^	�����D���E��[�����u��W��]ePHd��v�fb1�6�'���<Bիj{�7�M�C��g���E��f � Q�U{��E�:B0R���#��n�HChfت��'���0��u�j�_hC�*���m�&�k,�� ӹ��+�ڣU�63�厑�����(���>B�:�cL�Ĉ�J,�iA�����99�f����kh8b����cN���KF�
������_E>��箵޻�g��kP��D��Z���o�ڴ�ɼt1{��wy>>�r�l��,������A(��lk�K7-�R1Mx൧�P�$�FH2�oc�v5��$NL�1{�	Q��<��?>����qԻ[Z�c�4��{<�ߩ1��*�c|2'Z����*I�z|�XY�:���deJ݉xE�]|�!�y����*���8D������.�N*�[tQ�!����^^���� �,��Ϝc$0?`��7�l��:�A��쐼�������d��ݶ�D�?\`p�wV�LC�$`�D��>H]��o"$��ټG��dK飛�vK@��~F�'�)��X�ds��p��o���vL�U.;V��x6�ǐ&	y���|��3���)���G��=���<6�N�e��(aUaM�C`���P�tl�s�O%���_��N������ �N�A�*���.]��B�JB=�΢:S�ړ��I�v�����������T%�aI!E�*�o��b�O�c�=`�n�)��_��&�k�j��>��%N�U�x����ޥ��댪����N�*��uZ�v�7RF��"@���~+��w�l�=����8 ns�W��j"[�`����U��E���<%��ş�X0���H���֍
xm9s����6�;*��D���~5W4t�I5Ҽn� 9mȓ$�ՠ��`���ܬ�fL����9*��h3� �~�����$6QS+� �e#(��F�C�o2ܖ�����Ç���4g[��^^���3I�:}�<�!���Ӹ�(���3��vg]Q�L�JӟʇD�u�m]�X�*�����x֨>���N�,���y8"�d, � �! 9;�D���=*���9�w7l_����5�+�\���MF�da�l*W�:��p�":����E�a�G2�sŢ�,)nQ�2G_���w��P߃ud�J����b�1t��3�m�e���`d-��][W�Q�������Bk��ȴ'=BC\�4�U�i [��>��H�A���򟸱�Qv�]�@�m�W�84�J��F���F��WQ�Ir�!-��w��pۗP��q��[� :1���yYg����P����t��d#z�	]�����ͭ������3o޾�f5�n�C�B�n/�;��xL��~�OWi��ǒ)߮DS�106���������1���!�n)`;�	�/��r����ɐ^G�k����4Ee^\F,���aL�X���.�ߏ:��i� �c���V�e��n�%����쪔~R��/�s��(���(��)qa{�)��^��wB���Op��\k1�����7vE�CO��-��p�Ŏ>���v�7w�]	y.f��h!�?�#�^�e�K_~Z���n��1�Q����]�'�� 1�a�Ū������A"��6hDx��J��>�O����?P$wHI޹��2�1�;c��;�V��5 ���(�?��I�<1Q���ݲmn,�=Da�o�1)�H��y���]'3wg��x�������T�]Ar�>�E�{:{� �B��?NE��*0F`�c|A���������i�^��Q������n�χd��Z�+9!L�6�z�H�_b�ee<-	V&VA�c�^5���;0ݔht�n����%T
a��I��pX���X�=�JU^��v�����3��Jz�<,�9������!yN���l@�&�3Q�W�V���-�uu����Ef���O��x���8t�P=|Jz�˪��TN�{tP�������"
��&�y��x0��bࠅ��H��Ш���L�zl2�Px�Y\��]��ky�����?�x5]k �����,��+�ɣ�2ߐN��r���(NsY�NCc�Oa\����:7y�5���܆V5���q�`hHR��?/�~`r��v�8�ܫV�᳁��h�.�0��x]�c�o�60Ȁ��cw~gB`E��8��z��I�AXV�̤.���팵��|})�c���e��$�"k�K�>K�s��8����Բ	�(���>��gA�vVw
��F��Fc�F��YΗ�h'����=�0 �q��w28Z�����i�	�+��,!�C���B���G����<o"�U���=��inj�����"o�t��W|�n����k{^v4�f���lm6����&uXCp�O�%$��ZK?���eM.I�q����`����+��#o��)���w�i���c�������	��bcl��D���XUP���^�[�0/��g��l��D����t�BۖJ�qiS�S�DYD�Դ(��	Ud��b���Gb$->�[.��X�<�r�"F��	���D�Q��#?j��(?�.�pCshAj�����!qGSc!���sL�2*T�:���0�u�AwH�{�^�e)|����EӴf��Ձq���� L<��UsН7��ȉ�%dyWyT�á������A&%Kׅ6��N�i�>eHf]2�Z{0�9�Ԩ���,��Ԣc�^�E8S��������CVvEb�u��g�/ ���%�W���ī�ߦ*/թr���޵��W�@B^�S��È��`p%RL(���P�"�V�'����ZBR��nӦ�Ͷѓ�z�F�8N�����3��/��1]�aT���q�*�ɽ�`݇X]q?y�7��Z�`� N��Ji�D�8ENN��U�o���j��u[�o&�]�k^xGS�h���d���&eL(Y�E/O^�u�7b'���a�Y��c��Ċt,��z��?�梾y�4�X��h�Jв���qCH��;�A��/pұ��VՏ���l�0�2��~�t�@c�?�M�ruR��Ə���VF�X�cʽ��>eQ�y休bĶ�S�{7E<>�qr��Z������fC2\�X�������a�	^63��x�gՒv����k?� 6�u��o���1�%n�R���_���aj�$��Ļ�j�P.V܋qP�il��=V88�2����T������[ǲ���ElP�������=pD�Q@�D��g/��[Ծnq�0� �=�&�������� 1�(���eN)2�Oi�#k�Ոu W���ixH��Ҥ�����.s`�Bhx�/PB�0y��{S�������iH�G�>(*�����4�n⬦��k?���o�DB�.���X�4j<p��oP)�|~;g11�V�3�Y�IW4W�μ���(qoO�l�1�P�h�gw���"gC�ȝW��ז�����Q&���B&��7� J�
��B�]�b�ڹ�����#�`X?��J�.g(�Y�9�|��^a'5�}�N8�bȗ=�*%��`,8j��<��Co�������)�4�G���:����]����S�O�Gq�םN|���|w�������X;���=�A(�ZuJ�9 �
:���9g��`E����*��.|`�+!�z'���I�S����C�#q��$�e�YI��?��d���Q
�k2M-]����{��p�!��֞�α������6|����+O)�<�?�.S�:C��g������!�B�Cop"�k$[�����hA��B�
�y�7{4˒��be�hp�����@>�:��H{8������|5���(!w�L�)0��L"��k�YB�tk4�ȉ~���������&N�I:�w@I鐾BY��T��rJJ�1{8V����Six�O�ޒ�PIR��Q���G`P�f����_�D����-3�7�O=�f+3s��r����#�0��"��Otfp��;{��[W`�]|s=&�������<׀�-P0�:�E[`�����)6���&ӎd�
��?d#8��].�ae�hO6�o��g+�N�;X0 ���b�.:��U��= ��b�P���
P�����_<�j��:�U���ܶ��WnղR��˸i�˕@��ɩڃ�Q<G������vÝ���+Ǉ�l�L�"s\�"W��L	����]j=�*��d7��̔��8��'�59Ot�GМ{�U�Hm����9�4cjPY�#�gT��}���^�R����5W(�	l���n�B9D�]뢆<�*��[!�+�#��(O(X�0�R�W
����fs
ʈ�k|���}1tĿ��q{ٖ���d��ch~q���I�a�&0r�[i�	F֢����H)?��5'�� �לc&ʹ%K?��&��`?��G:��i{�Zm�MR��4U��R��dg�L&��O$��c�0h,��!lN���>W�S��vxY���	o���Ci�8Zp.�p #I+s��"��E�R�ZNzF��%��t>s�������(�߅O ��w�HX�.&�����ꋂ���dkXB��}�2�H�7`�3 E~;QH���������߄7�-�����L?� )�41!L3E�m��\��6˔�%�񔀟�Q����2���,��s6 -�ōC�C���
0�����"�4�Ё���%X��s��9{�e�Vŷ����P�-�Bu�M^ �E�0~�K=C�4U�#��F�B�߼��IP0'Oͽ|�5�Q[If��|�����a�܇�ώ�>u3 ��<�V�@0Wv��������W���s[��t=n�sZ5��1*�3r"��z%�Q>�ad���`͙�X�Y)F�֔,�M��*�
x	�ZGFxy}!�/�U�P-��c����9����gfRH�h�C�	j5�Z~����ʋ����p%y/x�����ߪ`w��n@�e�n��}qP�6u���Wշ
z�w���'?[� l^�ҵ�S�{_7<6�&�T��R��޺Ԕk~�A��L��ܿ��Lw���	Eg�]�F�7*���J������ȅD6�
lI�0�P?e��w�^la9j9����3��N��/�Ӵ�S�N��F,�B�Yťc�X�ϩ�t\?�ONA���D:-�*�I��R�Ԫ�Y��������.�ro�8Ƹ4��G�9o
��1������㒅���vP53�\?������ELrA}����,?=$�h���ܠ�ݨ��/D��(�.�������AӍ���=�i�e�Y1�~�t�n�<�9��T��;�Nm~WxƲ�^5��,���Nt2 <)�z%%&��ؗ�W�F��MP���/ϳ�� ��B��ƨ´���P�d�6w�5B�M�2EQ����������6B�>�d"��P-B��{�J����kFw�T����MU�7 tT��ɸ>��MA. ӓ�K���78=!0�L����6�C��I�~�`A�˻�De;L�G9��[�G �_��o-)�Z:Ƅٶ�7�]e��ĒO��5���}�0����Ĺ1�ۍ��"(]k��1�a ���@�.�Ծ*��+��?�)��shJvs���*:��\�!�l�����D'�7��v�kfL�Z�����Q/[�GȆ�.tn��OZ-�Fý�ڎ�!��]�u�9�Ȃ٧U��X�p��[��D�����--�l6�C!���@�A�[���;�49)�_�0��H��WQ�1&"��x�0u��Z�b��{���&ß�{99"bX}�BxX#Z��W\����m��x��!�T���}��rr�����k7Tؚ&|B��Kf,}��K,z�ϔ@���XÑэ�c�g��n� ��������*�,��x�C<�64	JC�ɌyIp�f�P�6AZu�bH�A%��0���a�Y�t�[��ɩs�u><s�c����yU��Lp#Z��	R�����w)F��̓�m\0?\�Ⰻ�\w��y�\�g�WB�S0��S�Բ<7I\3[3�G�~2Fv�۷A�PU\J~���l�H�;��v�mD� �wmR�K�V�vN���5�K�@ a"d���dw]�G�A��Y�y��+[��tJ"s�.���j�1�sy�ނ�xo��{�r�q��1��7h �?���W�~����5TU�ē�W��u�v�"�L�����\/L��A(n�ˀ݄Jn��
�b����~�i��i��|0<�_�K�>6�x��1��L�S2�����/殝{�z`�4�dd�}������Pv8C��pً��� ;g1{XD����z
O�N�w�����=D��~���UC�>k�p���9���������b��!q��0�m�"4'���+��[ )��n6$j�Z�$��S�9�]��`�H��y'%X�E�ky�=��1��@�c+2�$5[�2�9��W@t���Qu�ñ�J�x���d���t$��r[+�*�w�\Ҙ���a1Q�=�t3�:���`|����q��P5D��~�=O���!�]i�����k�Q ��`-��L"����q�A++r8�#讑 V�#9��������AU�������X����Dh��7䣝��\s�՛�<�X�',����QVv����a���n'Ɨ�U^���*dZ��?pG�	X}����7�0|iὝd	��"d|�<��c�^�C���ַӿ�T��io�HVZ�2����zM�Y�А�P��*�_�{Gs]������O�A �yr��e�Ǔl����yY��Me�xF~�c����#�[���@��{���6��%ڂF\r�^�b����?7�7V2�����p��v�������l$MJ���Y�0��� r%�S�^Pٗ���ٌ�¡9y��:f�P[������%Nr]��{-�������;�~5�'#��D�|�YˏL�|����7j��k�OPM�+gV*@���%�C�B�ԯ��C�� xG ���������Q�5���08�U�DNO�c��ߡ�j��
�甥�U�kXoK>��ҩ2�;S�O��)~����91_�b�� ����^���+c��ʼ�*�Y}=��6&���+�r�N�g���@�2Ȁ������Mje����] j��o��!Gl��?��rg��k9brP�,�!z���+�lӀr�R���4��*'Q�v���T�� ��'J���O8���)܃Y�~�	���/e��a�y�T��r�#�9U����;�d�x�ɋ�53�kK�3�|#�~�S��@�ֳ��� ��Kn��]�БT�<3�/��Dːּ������G�C���0ԨDL�Ic��Q�]����]G.����;r�.�<��K|��gqu ��Z���A��)7�0-I������)��V�2D���Q��R��%g�ث]>��:���O.���.>JB�^�)V.N�D�T��~�T��g��M��B6l+,F�a���h�ÝC���O5�,� �@'�� ��u�̝G����xs��He5<��-��%m`z�S!i��9c�CI���5$r���Y�ب����,�A]���t��T��2.bl�r�"APϵ�p����b�4U�fi�CF��
�hr��
U�H��!���j��[�$|����d�ҝ{D�� ���WT��iE���{��*ndX]����X�z9֣�x+Y�����#�!�΅�op6��E��à���!�P%�ǪH p��ĉ�]���E��ag����t�Y�s�r�F��2' ���41�h�Ӯ)�f�����@��r0=/�{H���H�9f�O���Ic�8yȿ
��A�2�k�1ڜ�#o��������jX�}� [{��_����q��J��#���-�d��������⭓r62ɖ3L�A5����iQ+WM)�g�g�0׍2�1��D�w^����s�:�0��D�F� ���TXJ�����X�]b0�h����R��2�5Yh@�$�_��Ϟ�F:|�ތ*5�DޫmK�Z:�e��p�@��.q j�[[P��w�C�g��"4��*��, �������Զ�YUK2k�e�f �լF<��-}�	�X����*��;̡����EJi���#LߴRM)�W$:Pn��}��i(��~��a)A�9���wU9=������+�$Ks�h�P=���W30�beN��<��g�y1s� �m��AL���(����X�(܇�c?j齇�<0?lQ.gx~D
z ���i:T>��L��K3XO[���/��-�B�Q�0
9�$B�l��Y^/�G+�XZ7ͪ����`U�Vm�PV��\l��U~��M}U�7_�~1����w�F�����N��X�
�%�ݭ���7kP�1����P8� ��3�shڲ�����@b	����������~���71q� ߫�r�q<���ٜ��(��!"t-���2�#�d�
T�V��lZm����;�Z�y'1�4a/W�|!:'�=N#�,0;mك��a��Zm���p�
q��+�E˃�"n	g-ɂ[0=wN뽩�.�=X��4�H��M�x��o�\��Oxc�4x��Sc�a�����'���u���8�K��n�����Td9!9���`�U�(#�͞G�N�fr��aU��8�,P������ԕ[�!ޛv��w&K����JV���≛Iq0uia�u��L��S�:�F�����"�]7��vI:�����P���z���j�NYj��}��:n��O��Vƙ�vB��h$������Hp_K8�̺�a�n�i�*���m�wx���H�gVE��]�Pb�)@]���u���o����5��y1�W�����b
2�9H�Pߧ{�h��;�N�C����_��kK�Ш�5��e=�x� ޞ�I��?ɾ�e����U�r��9��
:!�k7���<G�����]�2��~��=q�`��� S�aW.��(f�o�rLb%zt5*�)�C�)l�:�� ��R��z��فI8�x�XɅ�ſk@=u�8Qi���O7V����k60Z�<?���&� ��Ax'��l�$-�����,�j��Y#����n��7D��,�%���]���y�C�e�^�s�	3km�$�5"�e�찑����9UF�9 C2=v�4v�XY��2�]|����m5�oJ����]j�����I�`�o4)��)T�OM_�2����Y2��dJ��gwG���KS�?1C�8Y�8}�)�I����&�}�XtRoɔG��Pˇ����K&g3�%�vx.���j������}l���P�l��r�Ib�IL�`��TN1oK@��c��m�.	�����L}ܙ6���@%�MG�ҵ�x����ؗ�
�nY~��\'Ӹ'i�ʓ�A�m`BMɏ�O�N*��s8��pd�zL�(XC�)�w��DDC:�6@> ��lh�P�N*�����׍��M  ݑs�p�M ���-��ޱ�g�    YZ