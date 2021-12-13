#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1493874499"
MD5="52dfc7486e2050f550248149b9c6bcd3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23964"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 20:00:30 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����]Y] �}��1Dd]����P�t�D�"�Su�c�>�yRO��*�V_FŽ��<A����u��!ȵ���yM�	��؁mTr�a�./%%��i�"n}Ӯ�D��ȭ��a'�ݝT=x�,�~
i�:0 �ē�=�8E�����Oj$F�,}5c��^v'���G���]�����H~�x�j琗���b���S���,�Y`���%� ��`k�fr�`��fm���q!�@t���C�d��櫽���9T�l��&La)$=�6k���ܢSco�-�Y�*���<�㭈�5[�۳��w���C:x��z��>Ɓ��L
E7�2�0ۮU�o��țǫi���>y�q)�`땉�<ܢ� �ZUԸ!˂oY�;qsy�bL�b�>�j��(�>�\��Ve�Z�)A�KN����?��"|����MOW>aA6�|*������yT�;�1��)��
�4�C�OǭA���2u٠q�7J�塶�ȥr�ߒ�lZ^��D�h1�߽h�J��[���K|+�rHJ������(@}p&��.���{ČwZ�	�cR��-od��&�T�6�|��3�^H���8*���\�?<:l�����ޛ�D?��
��ՍBt�_�}m�@�o���U `���=k�O���{���fO=C�R�m� ��0H$E�cL�s?�}�y�嶒\Z�&�A�@��a8B?ϟ!fl�m�혘:x$?�@�q�J��bq^�v�p��@��XF-=�����'�w6͂�q�1��V���֥ج��)'m	��ѪG�J��I���Nt���=�/j�6���q�~���NjvBw�2�0��%����%^�fj���X�-�-���,RP����=�4#�f��������$zbD�N�����`��LjO��:x�>�J7{���;(l�'�+~��A� � ������?�h�H�#8���"�h.�E�#
�p���5��M��$�⍔�/@3k�x���x��A���2,��h�ZP/���d�H�!����LI��'���WtS4���,�nPޏ<Bz3����Vpu-=f���Y��L)ߦ��>�!��ҷ?D=�Ai��U��TI�e��:�p>�kO��L������m:mh�D/����w@�酗P���⤾�L'Q���9e�S�K� e�{��K7ߙ��4h!�1ܨ�im�OG�9xs�}����r����OuNC[�] ���-�-hY���dD���%�J�����o+ĝ$Z�����Q���Z����!l�(a�5V�5�~>-;���ؓ�U����Ρ1�l�W˩ʿ�
2��X |�h���c���ya6��pE�X�_�8�\�z��_�;���[R��lW�@:u����&
�UW�'�J���0,���=7��/����D�G�����<�M�Ʋ�CM1����t)Ɂ��h0�������X��?����K������v�Uh���T�����rZ�'����,Ԇ*�!�u%�s���>*B2����b+��/~���HK�p3��z�'1<�]Y�\����U�9kl(����\�!��(��3"�%v%V^��z#	�N�Tu�h>i���h�����W)�*�p�Bq���ai�rj����ބ��"���)�aK����;cTn�+�s6�Y=�E�0&,_�e�`!ɢ3*r��5�Q7����&�צ"�����ɐ��̸^�Y� ���.��.�d&/���$��˹$�۹�0 @3U>�/�S��U�Fἷ��pT9�?�l�lm�=�\(�������]a�+[�]ZQ�����4���5�XB���*��Űy��̭u�Rz����c=L�J7��cʦ����ԶB��>"���V�ys%,ٺ�D{��֛#��z�.h���rய��R��U��]����9�ϱ�� �<� ���1�'���24�T�,�,�=o49U`�B��T8d���S�ӡL�'��.n����-������7��?�8h`�2ˆ�ܨ���c�N��p����Q���C�do��Fŋ�[��$o��t���������FT֨d��3�@p�<�qQc�ݿ}49i,v�M2��u�=�E���Q���@�Q�����\���J��2\����n�nP���X�r�U�� ���T��s�Znn�#���6+1����tH��H��x�C��V� �8������&��� �͒UIC~��D��|ݮ��N����o���H�}H��z<��~��MI���`��CY�OLI4��"]����d�P/�V)�i��U2/
���.SCPn���+��)2f#H��;���73kP�&��"UK�B�	���!��m}X�[���?��L�`7�GlD.���iV�q$���孁d 0�|���O��G<᫶�G��A�h��]�_��~�1�%m�E��μX�P���m�����t���~�q�Gx̹U��(Q�,����j����rg�zE7���D]�hO�x�^&oIaݟX]�v�rS�%Ci�U�#�O��^�J��9�I�������z���O��ӈ���F�/!�8Z��6�>4>EՎ�������b�;.I��t���_�,��^2%J����k(�c
��=��M="}�I"i<��P�A��JV���� �;w͙�N�=�}O`)[�s�x�x��������	+\G���8�\'@I"���X�5���3�͹��������g�	�����׭@�Ff��JݐP�5�_2�&h����]���L��˃	,q�4U���G��.̓�ɾ���6�qF�M���u�\Ry���)mXuF�u$�\-­�I.�]�C����N���5���ܳ�H��W���L�j;���b��i��:M+1#�=$���ie�ˌ���M"�8}31		4�	��Ԁ�G�-2��,}�t�8A3��~��Q����bJT�����"�L%��'�cH!V4T��$��8t�m��W8�d���'p�K~���$V�ޜ�@�.t~�ӄ,2����*��:�W�4`�n��뢍hK�Z(<�8o�M>�n5śwWN�=?ᥫ�jQe�����?ʘ�ZY�d�����c4�,P��s��Md���H�����;�y�`���*%��^��?�3��Fg�.Tz���k��d�H�S�!M6� ��%v�H��ݤ�޶S~L�;@2N��hvQ�Kc���p8�jD^����8�m	�mY-��h:P? R�ey�@�QgD�* Ml� �t`�\�AS�"L5mh�[mC�u��q�XSA�Ʈfi�<>vA�~X�kt���5⿧��A	<w0լ\]�@&���̇Z�-�ӆ���(�]7�8����7��x{�1�d�k�"�t�ܝ��z>�v��V��k�b�xe{ç����qXQ���j�ŶL||�O\�&p��d+�F���Q^�
з����r� @�3B9�y���l�:�^�����ݺ��SҺ������0�i�M�0x{���#�Y�>�yS��r��f�lP�'3(4�_�!���,I��}$\B���b]oE�;:n�X�V�z{Qs`�4(
[�����4��S������磜L�&�̞�p�v?���;Y���C�d3�Cc�c�.�Qv�mU��0潹���s�����o��.?ScB�T�l�u��"�2X~���{�ָ�� :E�/��vʀq�hi�XRW��v����' �K��X��p��uL�^��a{{T��R����q�=��[��9��AG�%`�K>8�Y.��NT��N��8��@���tU����*w�:������5~�DE�l�l`>���0�fy=�8+�2��>�Qپ��+��]��FZ�߰xN�c�q�`>���/F/_��4������-'�"�,�I�����N�YҾ�j�0���Kp�*v�ّ�O�Y�����|˺g����c����%xw��}�?ixe�[� ����2%s�})Q��M���.��5v\9�o���bF���>B�LU�<)�A�H	�`�G�c
���\PT��������k��2����u%X��'B���*�B��~]�A����I�dW"�	}G�}Ճh0�7�&{_�d��3>�Ec��B�M����>���c�Ҏ����)~���N�	E�d����`���?'O��nh^Ǎ� br�daGхq�	�0�K�4a�*���'�a�O�'��ārG�����O���-5?�t`��c�C��	���KW��7 ��m宰����W� o	v�����Y�.)|g�:���1ŋ��+����Uc��C�ʉ��K���Y�-�-�s�p�nMFԙޣ}o�٤k�|k�ؘ��= ��Ǐ���?��r`pl�	IA�ou:ûK��'����{!�H���FL��"�?�2mp�=��^rSM�2���.���f���e`�m�M+�G�krH�i��޼XR���a/�S>���E�#?�s'(�.�#�h��!����"�0��1�+�:{,�?�dgdb��밗�)-ܡ�;V�@�I��G`�M9~7#�EE,#�6�3N�_-%��M#�gp~w�9H�^�J����|ok���8��A������P������c��j�+�2㯝�B6�FMzH��x$��;g���
yseT������hHt�Hў�T��*���G4����\3���8�w�a�r�,):[�ֆ�5�JE��F�6���U\���ִ��}�K/G��R�H���!z}���O516:h�6�:Y�=Ѕ��a��!���v���L�m��꽵L��⚖N��{[�AT�@a���l����b�k��.�Y"�3Ɨ�>̟�!�ԁ�WsJ��=��mȃ��c���b�O#%�Ws�4��϶՞{-��@f��ԣ0�T�_�h�Z�`Ӿ"��)ǡ���ⴎl��K��r�o���5��UQȤN�L��&�������l!~�P5����
�W�����Rr7��O��uk&P� �3�˰����D�C�%�F�j�J�QV�AX��l�v�2��L����S��#��A7J�zc5|b�ʹ�+�.��Q�Ǝ��1��S�ޘE+�s�RĿ��?hi^���w���jI�{2K�W��}��@�g���fܻ�ܲ�X O�s�s�J��.�;"Q,��� D��̪fK�m�o��80�-mJ���{��P��@�g��g� �1^X����*Z��sW''F�L� �������j��A��|^�D2��ANf���hKɷ|�t۞���r^Z�f�gF1=g�o���K�/w�ޞ/��t��t%����a��#���cu)�%F_z1G���m����3�6	�<i,i[-��P~��?ف	��u��h��S6���_��[���k�tM��$�
j�#�pΌ���5��!b0u���,G7\S��dッ6�r+�h]
���h��)IQ8��u-��v=n%s+Úe&��|���dQ��._���=�r�YM�d]4%B@�ǳGwo��p׵����ٝ-{��Xe�y�'CJ<H��"��p�
z�>��w��I�0]���T�n��{Jb���PuS ���gtAy����\����#{{b_5�V��zrQ�	G�%�2NCM�t�NW��#-%���B3�q��V�ܘ����nOx��k��|f{�g����T&@�D,��%K��#��O�|r����r�<ְ|tV�3�(tH^#ďOF�SU퓴�.��R̠Wv�
�EP�ü�jd�|�e�1��p����;�[����RR�䟇�L�W�;(�N�^���e��n���3q�^(�F�>�p�v�v��(�BF�����4!��ѽ}��-v$"�@���p�䭨�s*�����լ��3�P?��:��#i���My���	q�C3�2��\l��d�9�����ʙ��,i.�^Q�3A1*u�d'���ίBJ0v^�[N;Ʒ�AD�������I� bVz�'�O���k�M��ӕ��}���E��:p2�d
d�i�F����J|EI�*ě=R5Q���b��8퍦���{�,���U ��PJ���[�TE������ xkK�2��R����C�B�17���*����	�ɥ8���v�H!E��&(���{�ؕ��1�%1�L#���&���J�m����M�B��sYg�P �\��璉CGmNBA�6T3��A��L��j°�=��0�M��*�D�d��s3)�% R'[�� ���M��r5ӄ�g�p�AgP	���*������/	q���eX�H%�G��X�P-���>�������G�V�0ZLM#�
�D=3� |��a�;;��ï6�BC.��?2�b_������~����m�ވ�\��|)v�U�.�F	h��3-��W��[oc�>v�60Y�
=8�So�D�Q���C�2�i��Q�.��r���ax"|\����wR_U�׽��R�	_��BKO���@�ח�� ������Q�;ġP^�5��wډ!Cx ��ˤ�wBZ"`�V�����?�	-����#���MO|�&�"�VnV��)����0�8���;�����~��˯�������l�^�9���\��M:�ȱ
RR*<%A>%�<bԱS�u �>y���I�Ap����~
���Ar3Ƭ�}x���6�dKKC��.A���y�fʳ/eyj��&\�!�tL�IgU'��)W��<&f�;�ϙ�-�d�;��Br?c�p2}�bth��*������H�����R�����%�Fx�W�Y����U�� �T�˲1~�77�`�����C:����O�Y����Fw�4bމ� U �h>*23p�b+5ۊ#�u?v�KE$�3�u��
ɦ�VX��6ri~>��]f��E*Dq�豬�eQ�T�7Xv�̟u�+������߾��* ��~mA5dk��w�DP��'��.7=Ƅ\n��p�J�L��]xf�� �RMm F�i��k��|+I������}_���hkVퟎ'�;�eeI�?���uO�ϧ"��O�Q6E� 5�R왦T�R�) ʃW����^��'�̀4�0����(��u��XCb&{�Ń�~�{�f���|��I?��J����}�bK:(��3�Ae��� �+��A��p�F\u�� {d�Ir����c�4h�K�y��I�{6�f�g�=�����J%m�D��ph��Jet1�v��d�~4c�x[$b� z���T�s�Ͷ�$��qo,�h���9`l!xh/,!�7��>�)����P詄����ҘA���f��m&(�)V�� ����Rq��Xq��E����ex�/$�	�����{ݶ<��e����{���̳'�W఺�p��%$G��ǿ(��=6]�0�����?}�Y!�)w��ܑ�5,.�=��b,D�u� 	ķ�RB��S!r�Y��R��j�S�lbb�O]~(fb���*�{2�	���Rd��d��W�����V,:s�z�����5���=B���_}h^���c?@��=�]7��+"b5��',u���Rv����<1�Bk�x2xH��r����ؓ:�J�^����.\]]1�o�x�s��_P�#
��RZ�}?���*�&�
�.��&��3��>��s'*���ye��Q]@,�}�sҩ��,?�G�:�*�}b��&�o �yr����`Z�czxL�[�����X�ZM�A���j�2�34�����)R\��D��ˋ�H}F*�����:�����f�X�a�*�I����/f���W��H��������ti�V,�rS����@#�d�1�?v����-�9A�������[;/)�dV� �aL��c�mhC2�����ϳ��)�G��[wb�1��I��������H�m��ҿD��}�Ê���\�m;)��U�!���p�~+�6��|W
��C�x=M`��3o�v�?���G�-�rU	e�$��{�:h�
����7'��3^�����,5C0�c��=����+�a/ ��g�п�s?�c\}�ɭ�rW�b6g�Nӵ�j�W��d� �
7-o6Z��oH�s����p>ݭt�R�W��<U0(�7�v�O���P�?�J��� �<T��/Ϙ��"��0��Ⱦ�Z	�Z���Q~��Koฃ�ʈ��O�����p|�Ƣ�P;���%�Z�g9���ȟ�A_�h*c4�����7�I.�X��x�=�iQ�cr��x
;�F����]�9��{9mp�����ҝ�����$b�.�W0@�H�q�o���Y���^{  	�(��d��0�Xe@ھ��W�6�"^��, tӜ�v�T��i@����0+4g!��:��cb֭!��+Ѱ3j�x�z��2��,;X���n4q�E��	}�"��8^�opѓZ4� ���}z�e�ȟ��J����-�fG�)�QE6�0��D����#�O�Ec��/n��(���3�.]P���2x%�{�����юsL����v��ڏe���JW��ٸ?ˉM�-E��T#�yT��8�2pdȵ�&Xs����
z���́-u���D�0LP��\���v�8�"Nz��/��gO \��V8j�n&@�{1^,a�t�L��"Je����^�8�����H?j�1�2���ct%�x=@Cy8И�~Rե���j򑧧��a�!^�41"WjL����9c!��Ŧ^q� >k�a�;ϴ�~���.-F�T�w4��]��/�tt�3Ao�w�f��2�-��f�Y"�*���N�;5�_��O���~g�a�vU3��������2�����*�����]z2HѲ����d��SZmrK\ld��+�f��qR�<j� `�?�[�I�9�M�vA�812�����������|uKH6�ʺ��(���[��n���I�,ų�~u�%����E���^��Q���.�#�:��O���J�H-"�G�jbQ7��1�7�ϒ���k-���ԇ]�>y��\�`�ӛE�a�a;x��}��Nۄ��BJ��ҟ�=֦,��F9 E������U����W��Gy��U$z�2�2|�V�x��M�Q���YA!��y	�DO��]0VrV�e��'��	����������BD��������1�a����pk#K7�nN��w'��%�\��]�#��j�`�0���Ć���'�bc�)��(Z%�x��y�<�].b2�4�����j/�E��Kx���)�<=)� r��J�ԋ�T���YZAw�6S���'����(DQY�����Ō �i�xZ�c߰lL5��I@�!�Q|aϮש�e���l�W�$b�u�ZТ��fh`*���8�&:�L���g_�h���+�9*���a��\�1V��[t,*��mih�B�RV��!��]���S�Xf����L�E��2�;�S���xb��+M�?uL�9
��
r"��TD�s��PW����}�_�`&�}��
�|>�j�%�lJ�d�Xn:.����cϣ�9D�3��D�&,J�/o�c��1x���B�My1�𑦠����p7�\�s3f֔cS.�:Fh%�2��%�)+o��\���k��;!)'Z�s��!r�W����1��f�r�I������Fm��V�qm�D�F�Ig��T�q[�@?B	�/��3�M����0���:�)������ƟM�;+�P���\��������җӂ��1����7j�\�$z�@>}���кʝG��1��k@������-M���,n�WsW�����uߨ+�鹚^��gwf��c�{������k���ۈ\� �Koú�TRL!a^�����ɛ��������}eE-c._qt�����7�$��*
7󃔯��.�ٔ�k�ɑcUV�ю�i�9�����F�9��D� ����G_wz	��r|aM�H��>�ؙIQ��+J~��j�4�:&���"��R��=�QJq6�etۻl׾����u��T�ƀ��S꿹�<��Z�|���`����!����	�#�i�ʮٶ2��/7����[���m���-��=�{l���R�D��Tv��PM����#�����)-��-�Z��I���ۚ±1�TAKw��[�7I��=�#�?&�+ԝ1�g��4g����t�kP����+}��%;&�h�8D�9�؟�:��ؑ\�qª�x����J��{#�ʏ��&
npBG�B�T���J	<��>�P�S#�����;_4�Q.�q.�mu �Y�
����?
+o��2D��JD���oc�n�-MUJj�'��="H���ftU
7&1���0�<���&lF	"�T����s��i����[��K/���a��d�?�C��B�b� ��;[t��d�v�zM���-ۦ�EYʈ�k���΄4�P�5�;Ѯ_o�!z��
:г��gM?>��bM�%��2�j�}��"�%��3]�P���./��-�.��b��/�V����<q�\ɪ:/�JYb��Q-�!��iM��r?�i�T_ZvW
?
;�aY���u���+���kB����[�ymĄ�im.gm_J0ƺ�;������/�)T���_�W|�Q�Ts�D��E�O��t�[��+0����3bA���7���8s8�@s�l�����N-r.�� �
�C�J�y5�:���F5���؎����1g�ł#�v�Q��Nm�����q�y���n�������uI!D<�8C(W �a�d�|G��Ȳ��*1D�u'�#��"�y�O�
EՄS0T�9� VV��5�Lw���pB� �����F���+&��р��_�ː��7Xu1g��=��~7�A����߰A��OS�e������Mb�b ��A��<���P�P��iT���_w~b!Q��p�T�^d �
1DgJ+@��}]@��5��Cޏy�]S�Bl�G�g��� �����ls͌��)2�̣��Q\�#���Đ�ŀu�N7�A������@G���{��,�0�mbZsV"��JqE���U�6>�U3M���Ҷ֊64Yb�978>�d{w`A�Y�u~M$����w'R��$�p���QNV��p[���|Jx��t��!����U1t���4�:����pd�G��H9U�/�r�:��*~K�שS]��/��A3����8)���+�H� �{31�VǱ��Vڸ_�_M��#����	Y�ŃyyS �tD�}Rj-s�{q�*�ӛ䷴o�#�����WO$��[A�+��e)�T�U�쁃��J�|�r�'����dgܾ����es��V�FF[�S��1XQ\�{�x���邱�ߛ�X�Uܰ!v,�>�F��Zx��=ĒX�aV�Ӡ�(�t6���ņeJ+�[19ȅɟ��a��eOL�5����}.Ȓ";N��)�.]X�g/9��� �g�O�B����]�(�f^!��E�+3���������e-dP�q8�⠏�Y��2%�ß��˛$�Lؖ�ޚ)Y3��o�Kqv��b�"����a�Rbe�ȱ*�!3e�#&õ���[���b��?6R}B鿫�.�@�ӀѴt�_���6��?��9�$ǘ2���{��b�N�XΊR�q#7�Wh XgA��e"�Қ�m�V�>C�����[���ĆrF��!M�	���s3����J��[i����K��8`��U���w�Q#��G�;-J�D��,6Zi?2m�tSP��_��B���("����yc�����"yؿ�+a��v����߆:�;����y��q|/���F���4��D�Nd�;
U�SN�i�sG���	;�����[���V�]�[��z#DH)��&��ŗ�2�Ȅā>�m4��|V�=,���R�f�2ql��:c��Ш�E����{��9f`��Z9F��8g�"�5dE�]}��!y"�{������	L0�a������_��J���Ǭ�Aۂ7�\;I���D�)��m�,6v�e��2F����[9uX%7'?Qt�ny�ֺ����4.���6I�N�S�q��~-�}L�	�����M6�0~,q8�Srm�e啂�,��Ik/��pO��zʉ"�5��'�:�++n���"�G��2Rhh?��<���凴V��$bS�:.����|Mŧ����C�r�w��-���H��HE��;h��� �������1[�����)��&���
���=�R��*	(��RB�����V�R�;ޢ��&\�G �03�ިT�{�*�\p��yE�
:��[��`�P�kw�����vŕ���e߻�ZH7���]J��]F��þu�4($�п-���b��&	�}u'�������fc'���8c��_���[
X�ʟ[@�2P	�vh��&���@\���{t�WnJs�$|8£�;p�w����� ?�B��*; �VgWG��nԢl�KV#�/���U��\1X���y|+��D� O�cf�����1)�ԂS�8opOu>
6�i�]c�W/f2z�.���瘠��8Io������kab�4�8@���"���ms\��H����2n����\=���5F�C�b�#.����Z������d/+R�ߒ�?K^۾���t� �B�wvK�#rcK��������}��5�U4D�sև6��%��1��#0ћ,8���Խ�'�sq��\���6�j�$���W��fd���V G�݈*+���ص���>*������֐�񂌳/g�O�l��hU(y���>��II,�}��clĨ19'��Ǻ;��şP8�M�	��z8����,��A����n��&����ރ1��'9F�P����0i����Ӿ�ƾA.M��"�8����-L����M���3"��N6i��!�n_�M��:-�����c>͛���-.��'�F��-��~� �� ֓OP���Ʈ�����M�i��0��5�6�9����I�H�Hh�S+� o	��g<w8ii�J�j�SU����X�����J��,c� c���*��pr�1t��>Tq~��:Pa��n`V���
��x�����P0�=.���xy�y�>���j'܉$��e�LP/-s_��������?$sQ��:�0��i�V�S��0�۸γ�zز�ٍ<j�ɲ�$	�O���n[����36�D�q�7d��u?���(�%<Tc;=��հ ڧ��-��j�ɱ�Qɳ��nЯYg�]B�y�YS]tIq���s��(��A���߽�HyK'k������A�E���>���I��dA�U�rX l���4���BE)�u���#[�l�g4BC��8�޸�<�~�{	n��}7d���u+��VV�C2�3��� 8���3O�����:���t�6�G�?˞'�Sv#�<8(%��=��3r�<�j�40:���G�Q5�h�$���*�
\q��7�PN�>��� ��LB�E�:8�=�xv�n.���,:��gO��V� <��k�]�ۮo�e��Y�ɼt4���C-�9s��d.�SN���	RS�C��
��G�c��yOԓ��~)�J1�"���)���tv�V�'<P��E���ꠎ��+I{�l���A̐P ����LH�?H�r ���_{��s��.�`	g$�&�Bu��� J E����s[��j���#�&OK����� ��N)�R���뉹OgVm�ef�v�d��j��*#�k=+���ҵ��J�9뫗�����s����ǻ�A䃫�^���]h����,�^�,�)����1q��
��j.g1�x�QUH:}�-��n�ڳ��a�\+�dL;�(k`<>���m��V��\����X�!d�^rv��.Ʌ���:���h~-_����SX>[]���#�[S)[w�/vC��Y�}�Lq Y
�jwq���M�d�Lt���
o��]�7� J�?��L:���g�������m��P�]�g��޽�����+C��Qy",�#&���RZ��.8A-�bCy��Q���.Z��[�nG�٭?6/��b؝�Q&�Pn��jc������>bC��lzѓ-6*�n����Z/�4���r�y��ZАr��5���*Y��8�% J3!y����˰�Z~�WM��p~��a@�5�����F�����.�i��y��/M�8z`��H�@J��wʀQ���YG�*'�7�	E��mV�.�Gc��CM�ݩfWd�W�v#����-�q�d1�w�������V3��[@J�$�0��[ɱ"$��YfƑYhL*��~^Y?��S{����į���W�nι���c���YI�l$���� md{s��V�Z�X!�z0ݰ��~`%z��ǴM�c�l��[��C'����m������n�]� ���	�R|gRg��^J��1�ܻ/�N��z�G�z�>%J�����ג̢8�,D��.(+":_�  ���4�{�����Y^�JkϙJ���%��7~��k9 ��&�'�9�f���v!k����y�<5i�hr�md�%���<��bOE�й��2p}4�|��Xh���
�I��ۜ� �3��""*!bia
�z��y�������Z��6Xw~��ǝd:6�LZq��)mΩ�4M������Pѣ�C۳5L��x�g��w���{�l�c�qT6�|��ĬL��W���?��� �����,��+���y��VٕL��0h6ʯx�lMz�&�O��߭^�9�i�}�~�<�a�hX]��4O?>D~a�);��!��ҡY2����-˾y�6�입�A�ݮ'�	߳�ϻW�X�_�ѭс��©����:�	��R�->@�.�5:��2T��7*�h������VMɉ��k�ՔI�p��3f�\�]'+���A+�����6=/���nu� ��o��g�Jj����^�,�@v�\�~<�����M����-\x
�Q�y���X����c�4(�5ʥ�R�t�=���W�ޔz.T��'��=-6Ý�Ġ<6��yS:��}Y��oq/"�m�z�l7s�M�Tצ�1� ��mߓ��z��1H�	� ��/?�&���{=����:���g��Z��x��i�l�b���� �)��e#d�=x�T Y+۹�hS��ۙ�ླྀ��"��@7g/|=��x���	k���|6#$�?������m��Iu���־RP\����D� ��Y���{)c��~��a��q��&�+q�İ�O� �X�Bir��D���ծ�
� �m ��oZ)>���\���R�@��	;(�1��I-��>����Ƙ6�or�&U*��x.���UG�oZG�Y[K`���]݊�n}O�i;�^>�>$���>�-�_�k��j����xH�\H	�q�(qkA��_��9k�9��lZ���BfyM��;Aj��IJ�-G6�s,��B��4�toW���'6��)���I>��4i�"#L)��I��i��f�n*�m�+���8��$���'�m�&��r���`�t.�4��p������Z�T? ��[�`��tS�;��=~'b�H�,�i�ƵjCS���X��d�{�Zj|e��I�����w�#@�~&8������`��'~�-��.��^2�l�c�y(�
r�n��l�-���吝M�dɥ�L�a䈅<�.24��E;6�/�&@�����*7=��`U/�5�y�aR��Pױ����뮯W)�n��T⌄��5����ƨ)�`DY�2F⾿�l$�Ut2��[��BxGѵb��#�,�8��ʹ��ߠ�U��c�c�"���/�r�F�V��	�)x""��+�H��E�"�FZ�y'�lo�L�R�M<h����5���(��
>���.�?�IBTt��7 ��q�ʣ���T���2���_vЂ��Շ��8�}??��n�ۢ��<�eA��
-2��<[H������H�������L'G�%��E�%;�?=�S�6�s7���P���=9� x��Q�������d�
:� �� )?��z  ބg�pu�\��-��z�_!6#�"S�Ea#��v�>G�俾B63'��Tt���A_%�����FA@���U�ϣ}ƉSy�l(.�A��o�ĎPM�-���_yg	|��3�V$_�[���g���M�����L��Ys��Z��Oy�D'\��;!�!�� 9����Υ+�����g	�)>Ԥ�Ш[�MJ5�ˡ`N$6�Dَ2F�xɦ9�S)v�Z��TC3a���x��5K:��Q�P��d�7�,�2"ռJ�i�T�jM$k&�MM_�Z�X#�~�.�:=�#)��`�������c��
�ܢ���n]��[�>D��a�Op�e�=��}z�7���b}�:�D"�궂���5o������I� ɱ�K�q���`ep�j1�n�D�L#>5FH|CrJe9�![��E�����*�%|l\F�/��,�'T�9o�����m��kT�3�Yo(���۪$���&5�풴_I�سa#g�[�Xum��YIs�P��v�l22�j?��vEM"x�ՙ���eP�G�i�<m䮘��T|\1W�~�� ����
	h���"L|�_�u���S��rN��H��ڏ���V'/|�+a5����{۪YG��-Y�*����e눱 %���=* $�(�V�K�"-�� ���՞1C���Y;Ť��1Mڏ��'���*%㟘$�F�tU�0qM�9p�5��S��~ޱ���D��_�l���{/'�쨧�V+�'��M�[�$��ww�M4�1�����il&���;�B|VLp	�����=I��i/`g����!p�"X=��m�%��x���`~N��X�5��F ��>9 E�.#��5���W_�S�jd�I����5~^ �K�hL���9?c�x�w�D�.����쬄ns'Ol�i	��R����n�ڹ��7S:c?��i2O�����p�1���6���d5��������呞�W�rigH���;u�b�g4�~��ꇨ}V�{���_��V\'e��g��R\��nѤ�E�1%���Ny�,&!sc�O�,�O�6(~U����$�+�(Eu��B���d��ц�q`vL�!CU���P����1���ǲ(,*lÙ&y.�V�`��^���I�Gk"�z�2����J�DJ�eߛ5(�d*���$���6p	o���+`��h;ɇ�����H���ormug$��=�B�d��Fn9ǚ���lp/p����JR��d��8�F�B� ����E�2�A���k�;��M�f��zgY����������|av 7���ױ�W��@���$��#���egI��[�\�G5�	k�~K^��cB"^�Ƌ~l؜���k��̒'BXj�̪�GW~B�^S�ȔH�9����i�U��j�wl�h�^������l -�a�"�`!���Z*t��0�� �]�L�t� �Xms�uq��>,�(���@$Ey��Hd�3d��Cu$=�������P�<I�|�����a����7��o8; ̬�ۂ�pY�����M�:�1�/���ÿ}��7ҾW�9�BK2�gZN�Rѝ<�A�l�PEr"��&�g������-)���%�Spd!f���D�gi?�!A��z��.�+��42�pB�������\g��I�SW1f��gAP����m���h��fBi�����K���Wޞ��,���P<�>GDIE���l��;��2h>�#�<����9g���O�`�Bz'/��� N7ܮ� 4bUŖ����T����,�+>��[�vW>J��PO����I�yoR�̄B�
� �`�U}?�H<	�o��r���BL�UO�E��P����6sX��Ȕ,��I�8��X�I�Gz��u�>�Q��J��L���S�h��=Y�y��wZ����'�y�f_��d�྄��ގ��h����Ǆơ�3f,M�q�@5���[M�2�t�]�i��	
��N���;P����*`�L��}n^F��@��E�up��v���N�DGA(M$�U o��P+������\�� A#��AP[�S�
L�Fgc�[vm���׽
},O��~��qb�aG]��nՆ�ӊ���A���#��l�>I��U�][��ަ��["��
uo��T�dM>ղ��5]�u���h����NU��֔�ɊP[ʲpƭ��q�XI�Xb'�vv��$a���J� ����#/�L�1����Qh���Q~`]�5x��IЃU���F@�t���W5�b�F�r�գg||�������G�W~%є2�~sf���jw����v�0m�1S��J��`��~��'
5�G��h�� fU:N��ߑ � %^ҭ]��!���4D��#�Է��Q�UbLiǸ��&.a��5�z贝�q�� �s).��I(�C�]�l��a���W�(��ľ
�z�z��c��q����u_&�׍ڇ*V1�c+�|��̜BN��֤�`����d�WЄ�`2P��U�U�+�C�|�@��c�d[k�5i�Yn(
�Z6�%u>�o�S��t��F�kR��}�j/�Q�<�-��|�fBG)�c$�+���ԃsy�'gY���.M+ϸ�9���a _�@$ռ�64���eR�O`g�[���I���sD&�Ε�>d*��2p�Yh>�"���~�C���R�����K�g]�~#��b
Ǽ�������(������M�G�a|���߿J�
۶ ���Fn�3�=P��c�a�Bm�%�0d4XeP��w�i)w����bQ����C����P�7T:��<��,����'���	�q��J�ف'>C!�Jz*�<��P���Ii�����OJ�c�-�i�Sjp���/gI�y�;Kfe��
hS�ӕ��~vDc0s=hq������f,��dB/ k�	 egh��x/`Z�����1�Os�!8G��o_b��繗$g�`�XD�k�΃�5�[�o�qL39��kXL�]By�D�1/$�K��ʖD������u��!��UE�_��V�+g��/0Ξ�C���{��a�O+c������'����Bh�?,��g�Zu�����\}�u�|��;EnT��FE��4;�?�|���CH���0 R�N����O�RSuZ��k5~���+�9�=��x�V[Bn��vZQ��ΐVK[.cˠ{T�J_�����v���@��Q�bR��:��󬎝����ʑ��/�|�9�^���pu�}B�a����V��@�b↡��Ԏ���F�f��kE����ǘP�0"�oT��3
��A�oZz}�")��Y3�?�K�RrI?��FF��!�q� �eR ������)zT�Z�O�_zs?֔��u�Ɗy��g`�EzGb����BFQ�K�������u�"p��R�}��'�Y�g���8�q����;���R�&��{BЄ��F�$ע�Oq�P����˼[�	ak�-�M�Y��o�Er�b�t¤%�9ml|T�������(Z$�����Qu �4kľw�n���>m���GdlE�;d 	�9�c� �����ڲ@�C �N�
�1ێTpXsք��Ё��a��)�S���	}�j:p �SLm�����z���8;��ػ��C��j���4�M����e���#�~"���.LD���"�ۥ�Q8aŔ��cv�#�Z,tW�gP| ����lscvA
΍���(�l2�7�,+�\�*�1IZ�5����狆kbQ9˴nt����HP25�h�`A���,��0���o��z�r��ō�@|��wh��L>�!ྛ�cp�>mh� ?,Z��\�P������#�����=�RJ5����L/�j%A)��E���`�J�M���6K�5/ȍ�J��׎�I�/��u&�`������*��lZ���v<�y���-��j���Ӟ�U�_�ԓ��.��8�jnT��|
�"���d�}�;,Ŕ�u��A3O��[t��d��0P�بc`�܈yx�`.FEM$�,!��[�����|c7x����2NZ��,�h�A��P<�n���_�y�A�Y3cF*&�!N:l`��i#.�27
�P̾*�'w���|�VױE(�Σ�y�Q"�WG�7:W�CrJ��]��v���3YQP% ��!��2"u)j�5�HO����٭�#2���V͝�c�7��fh� �zƳLͮ!F=���(�����X$���p��ӳ*���o~W�F`�|~8�;��5te����5�L+�� \v3/�[kq���v�l��G�O��0�	��~��B�5��[H�ԙ3H�)S�<�1�}�Z�mH��ɼ������ƣן�m��gZ!P�~d<sg�B��@��~���r����gg����"�.�/�{Q>v(y���o���j�fi�"W��=�[�x��Tz6�H�H> �gb��E�I��@�M��Z����/�ϮG��Ӎbv�8lJ��g�h�*��*�VW�=��pt������Z���Q�PI�pzS�[葃��������wDk�`��R
pqI#NA��@\E�ӹ�X�&����f/D�� �-	��;�fE&)�F�� y�Ib|�Ȟ?�Ե�ΊJ�o���|: :=���5�֙�p��>P�s�M��+���@�w�`Y�Y$���`�jf��ƹּ&�
��L���{R$�6�A�U	���u`W�&�UX��;�A
.���,�X�5�(�"LsS�Ԣ�9"`��S)��l��QF{�4�k%���h
�Av#|��6<�d����w�u��O������PjAx7�|�!ٝ�0�ڝ�(S��]Ƅ�PS�)���`���J��m\ȧ�+�����H��⿗D���wפ�j{�u�Sۧ�|�mU�`=���*�×M�>) 7�7��G���q(h:,a��/a�%�ny��`*J��Jb�d!L�@�B5�sA��1� K;/���)0Ʃ�3\4�8�P��ʰ�߱���D8cgStA�G�cZ���~���J1�����b*}���S���(�|�0w`kONL&2o����.SZ2���?�W��Ov��S^RKE�e/��w��VS��}Ե������R{s�×�ñ�j��J"�C��tH��l��{��9ϓի��-�⨵�C~7M��N�W���1����E�%Am�CǛc/�d3B���k�D�゠����՟UA=�}�6��|*�O�jѨ��M�>g��3�ԡ����e��C�N]�$Ѫ�Y�\�}�(Zy����"��\u���HzF!�w/D�i#�?A3(}APQ:�g��`1��@�r-0e�����L���ș��(2x�m	�g)~C2a�)�h��D p$w�[�#�yg{>��ol��fꤋW氦�b�`n�Ue���E�mc0���n��o�h��rWۖV��\������=� ��ъ�r�V��/k�SI|��@~����K&�ȷ6��rSV����J2
���)����GO���u��:�A��\!6/��G�vP��
�
;���E"��J�'��
�
�W'����ƪT����6*�RP�.�q�b(�2s��*1|�R���y"� wU�s��f:�	+z��bS��>��a��Q�]t0-�AjF�f�,�vns�{ۦQa�V|�1�s�IU,u�x��7>nN�{*d� �_w7�x��3=z�SycbH�@�I�iPe�������E���Ύ�5��C�	�]"��M�p�����y����(=��y��_4W����^1{���)�'Q���W׽2"8�3��8#� ��۟G�M�OH<�ƣ*������C�?�A'e(J4 �&~�v)Ȧ��"ł�J�ĸ�mp��q� q��;N�m��"A�G��##DP�t��t ��Ց��-��OG^�,�Ά/������ņ�5QN6ַ�)�W��3�}�j2S��k�`�;�؜���*����h���2��MK��@��AaߓF��5�L�^i�[wΖB�&�b����c��M}�O�^��|�D3v�����X�g =��A�mVq����Z"4���焔|%{�j��'�{w�85��/t�h��ܨ�! /b���,��'�5������>0�����YQ4��9�2�Sf�t�?��7 �Z��Af$�֝���ֻN�{r]�,' 3f0�:���g��~�Ϲ���Hl���Q�(� C�����>�����y����f��Ǉ��t�64�Y(�X�.9���cN�9�~P_��ʥ�@jp�ڻ��e�s�r� @\���{�#��4����K�3���^T�z+m�&S���[ؐ��K,5x{�����x�ڼB_��^t���#����%ۿz�}�]��PC��Kz�#��?�{%S1�=c㽏tsQ��OvFc��n~�^o�$K�J����{N.Zf������WP����=�]T#O�J��Ȓ��xuHO�(&=����\��
ג~�~�s���B�����B��T�3f�4��>i�c)��`�bS����a��0�$��x��>��\s�6Y�e�a��(Dԭ��2�f�`K�V�7⧁��� 9��<ޙ���R1�p�V��R�ORK��H��Z8�a{G)��1�۲i���_]����?D����.���bafb��n����4y�l%ⴤ2����pÖW�{��Qa`6�.�>�-ǗGwM�b3~���2U1cGW�/`۲�e@���Cɳ���?&C	o���#������\c��ҏG�Jmw��?{��i䁍~82��fOy�!���w^��;��b������@����@��5?��`�9le����*�벒��ё�cz���������&��K�}m����V���:N=z�U13�i/r<�����3DzXv�b�����s��A�U��+�{��H׫hH*�����7ht��Ts&�`����q��KK"ɰO��U��:��u9� 89j��eB��ף���+�.�j�&l��I��O3��I'�$�Bb1N���ng%f¦qVr���(Ŝ���_b��9^"��-gѼZ@VTF�L�S��r�d��#m�$���G�S*w��h4e��}���e���hJl��~����ӦF�r�6��\>�m����ֳ:Q�m���Rym�na/�h�Hz
*�x���e}�rM���Z��>؛�|<dC2G�u\ӽv�36>-��K�WH�7�1ӊ��Lk��X
rKq^fsm�5#�zJ�U�3�m���[+�ˀo�Tc�bTIF�^
/�i�ύ�f�,C�E�ͳZE�qD˔R�!yK8X\I�����30f����깎>�4�KU�HH��v�,��)�|د������naH6������4.�܋�hv6��p�4�]D��a�.�c��OS@�t�n�v���
>�Y̓r���A���kÚ��LT���T�Y���Eg��fVw}�~���/�����`<qc$e�x�_;f���?x�%=�����L�8
�ZW�R���76�Q�d{ݗ�8�ag@�1�J��gb6�'��Qp     j�N��!� �����rjб�g�    YZ