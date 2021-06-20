#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="661737737"
MD5="3ee6eda8e8654c9f182f6ade282871ef"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22900"
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
	echo Date of packaging: Sun Jun 20 01:38:01 -03 2021
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
�7zXZ  �ִF !   �X����Y1] �}��1Dd]����P�t�D�r�o/���n�k5M�]��z|׵����N��ٍ�/ѤW��dBn�&�y}T��oశ�)l�m%^i����B8b�v��F�hqF��o�ȶc��T.���Ib]�cc
��X��v_:���T	8���'����ZY5�v\��Ͼ�g�;�S��KS����g��v�/p�$��P�^p�vKb
���y@�>���Gɛ>5z&'����O�q`��LDq=>��
r� ��y[��]N��ϱ�t��sGǆwq��� S4�M+�[Zd�����\�Y� E�D(l��S��ヹ��/�0�*,Wc�E�H�)ҁ���l$��y��WΙ�YێFK8�gWF���B�m1�������\�g�p�4������mS�5q�!k���+`&�b�>5�zs�>n��ke���q�?W`	�ϖE@綦��"=c��j�}���c�as� "bua����x��80N�r}�cd��!C,�^$]�s�V��6t�,OP�hw � ����>u�O�W�8���F�4޵�Jm�.E^X��O4�P(�r�Z�\�V@?�9�49q�`j�Y��ʱ�s�J���|4��Fǒ���`pv�Z`jx�ȭ�"N߁5ͤ��7"�Ơ�
<� ��x6}H��6�M��O�����/�<�����s	Z��V���ݘI�f�.l���D�U���`����O�ˏ��k/ˬ����F���o�{F�Q�u�$4X�П�tO�C7
�����g�%��IY�??�uQ�L�eXc��7��fH��(W	�3!f#H��}4 �~*�i��g�]�6���Ib(��\$�n�c:���F�`�ikS��	Y�B�j�i�� �P���~�a���협�[��D���h��1�6��u�E��:�X����13Yk�,��`ь(~���2���$Be��쟎8ܻ���ܫ�+���"��HL�q:��E��ݝX���\��6�)��g�&  <*m�-H	���/��b���	L#�6�,.C��/~��lo��z+-�+rQǅ�� l��,>�D�t�b�&NR���|�>U�m��>y*��	�xVp
�����}o��+�N�|e�K$&��9s(�Q1�H�Ç�X��g�nT>��?^���c�ǃ�y�-���C���PU���P���jݮ դ�vr^3�p˚�$ns�is�W��{]T�~�l���`.�݂X�cjtm��-׳�C� ����F��/�i�v�6��c�@��˲�p'~$u�����-i��;��X!Do��T{	]�z�"�Mad>t����5��IB�[2y�h�$ ����1�i�8��{�����2�|'|'$� �6���������eË�v+�_���v28<9[2�t�6�ڎ��и�A����k<�0�{A���i��p�|��ԃ�/][م� �*ƞ��$-zUcN>�T�f�'�)�q����y���:~HS�=R��Jp1���*m�M���6��&�p�i����3�E��b
�]�J�{���;���=:Vش"���CԳ�����5��ʷ�<�8��MP�u��5��r��V{*-ї^��4�-�g���	
JČ(���?�a�_tt>���G�ù���`�a�9VTJS�,�ve����}x;y�<�*����l���'��i��E���D���4�x�t^ݠU]]@�M���ʵ'}��o&��<ˠ����K��J2�l{P��k�p>�`�q;�����q�Yd!���~��ҿ>���;C�'A+�����>�2��XF�0�����Xm�[�I���d=]��G��%0G����ڍ��k��C�ic<�]�#f� V���dٟ *ó_Y���K	^6g�qC�lUR«�*�!B���H�z`��߈�W��J��h�O����9/5�n�
�G�%$�@:4/4�:������x%&�f�4�)�<FA?A��kx(T�[��6���1!���q�"�f�+t����ƨ�"�����،Z�o���o�����4-`(�1bD��\�4?�m���f���RwB9� ̓��G�]�=JP�~��I��b�`l�h`����U�X8��a<���.�O��#�H�Ԕ[�)Mm�n�w6c\!,���)�p���4��Р��������EC!�e���2�X!�f� 5��q��k�A��������:]r�Bt��)�^����{%���6�[�e�쩣�����jV���V� ͡o���T�Nq�����*��U�hL��s-�Pա�hv����PΝ~�{��9t��ԭr_4�X��vCʅ�xo\�֊n-É��$w�`�i燶��Ц�咾������ⱮI
M��9�h&+�v�_,!1���O	� !�3���T<��b���y�+��MϞ�V�Q滪AOM!�����r��P8�r'0]�\.�0	}������X����G]G����aC�[��K�@���g��9�z�L�*����(MjPd���}NXHܾ2�n��!I�`���ފ�W[\]�73$�0�n��O8�[E_۽��M��M��C'Rp���]�
��6����� ��Tښ����0pw��}5>ـQ�W�Ȋj����H���}=n M+�l!|�ଐ&���o��$�ҡgY9B0�c��8T*�*F��X���ہE�v`������#Ч�Ȩ�e@��[�pОs	3M�/�ҍ�>쩩��Ȃ�:��gԱ�G��-N;���.���o	'`~��4(�0�����"n�9�߾��3+���B:�'����{�e�� ��FX�H;��M�����/�� �;FIB������'\
ȯtA���}5�N���zJ�G��z�����2��`�C[?�)�,
�v�1�Ǘ=JIY!�����$��W�ߛ�#����f��ŵi�v�
N�^V�ы�N���k�e��o	Ȇ�X4l.
��g½�F�����M/@j�kl"�� yn �t*�`�d�)9��*e�+������a��]�j�N�A2�g�'2m"K�}f�7��K��w�T�9�Q���dN0��E^�{�	��q� 5��U9����Y¢�H� -�?�G��n��3��*p����X�O^�.�0��B2qS�L��s�l3%� ˿�Q��Y����+;�/��U2��b�B�M��
>�}=�	Cdm���L?o�һ�	��|��`Cl���l0Ɲ�+S� �	C5m�K�g�f-���i�/��+�Z�{n>��QC�Fo<~w��)�����n�F�8he+�I��RNd���뀾,2`�H��<kG���|��H�4:����\��"��g��p��5bE��8�!�|����ٛv�����P�:��1�Jə�����I�ZJ]����Ã5�&J����ȼ-�pƪ�c m�2L���8�^"���g�v��� ľ��5΄�pF g�%����"�j��6�{��x�k�1�NW�� #�_�9Zn+���#���������}X,?�e�*�iV9.o����*�\�ǳ.zCZk'dc��p�����w��1(y���o�NGAC{����^d����N#�ĝ?�pL���/�F��ʻ��X1e�]�8f"؇�zPM��{����[R�4.��&�줼L�[ߺ'�"U�����?e�z��-ì�)'-=1��	����n�a(�f7(�`͘��:Aٽk�MzNs�6y¦,��������`��B�fQ�p������s��1]P�D�y`�
smfcO�Ō����$T(�S�梨�Ji]l�������L�y��8�¹�.֔��f�.�
�{{���{��� [ �?wI��V¯4������Z!����a=�,�&<�?&-*%�T"�/�C�%z���BZ�${�%&���B��1:�����‑��)pX�~�Qy�?��_�9��e谧��vQ�l�K�H�e��x]Ҋ[��C�^�����u.M�U �C��o~�O��ŦU|A~c�$�l�!=Ґ����l|(ڝ�F��<��+���|���o9O�v��SA�b������y$:P��������-�1��
�E0����e8x0��8�Z���0��q-5\X�׫�0?^�mfcI�yd�N���k惼Ӊ>M^ݪp�����m��@�9�����Y��� ��ǽ�,W�g'�������S_ɈR�Ğ^����=?E%X��#
��S58JVW^8��D01�w̙�,B��+��=��P\M/��_����!<�����\g�����T��e�8�'�����\�j�܊>/=�I��\��+Un�}���\��{U?s���gs�$�M�y�Ÿ�\[�g�b�lGsT8�;����-����_ڙ���X��5��-1͹�a%k��_���ʤqR~�7 ��r�⢓�d��η�~�~�A�:{��ꑔUqf�\�u�*���<)���7�-���ۥU7_w�y���5}�"gP���������5fmN���T����x�����x���Ily1��(�Cg�:�,�5���������P\}�7W ��{r"��ՑA�w���s�+����dw����|�CW_�*�~Z�S���V=L7�Va���n@�lM�Cٹ�vK�B�RJ\N�,?�/�Q���[��������	�t�n!2f�9)y����%8���T��w����=z�m���u��7�P��qs���$?�s��',W�~Vy��g�0�����',k/��C��;_P�\w��U�@�S��h��������Κ��p�>��&ܙKʾ|	��0=�o�o�q�WA#�K}�g=wΥ{�ǵ�| t�/�ww/�Ԓ��r��/�ݮѰUD�|���������_���}�sf�+�xY�����bfL�O1�W\E�'�o���Z�"��� �#��ˡ���{	��D-!�ʼF�����"��>�bH�!�v y���)�Y��H2�x�th$�s�U$�1"���ə��r�>�=MP��?��e���D����V�)��'�5�y<ͥz}�}�wG�w羘~g\�M�7�O��Ց2�L���%$�����F�4ް����ZT�y���A�odX��?o� �M��bc����OGJv�� �G����jO�-~���� �4�~4ݣ뻖��"�YPRs�������jme&C��D�&CX��ɳ3��Edh�����p���R��gϜk���*�xh�W㞶*"b�??�wi�1ɱ֊�8�cs"�9�R�����N�oVj�ԉH3X]!�o��c��)�;Q=�",�Ȅ��!�l�'�ҴF����T ?6�Δ�p�y�b8	wz���(���E6~m�1��'�D�ئ�=���M�?�75	2F��s�Ǌ���B:�<�N\�Ů�؏�9�J��?����p��}�s+�a�=�y4�՜YB(���A$�mg�vWȬ���gF/��.@K=��	d���jr1]���k������+tp�VE���ݨ=.��;1Q�"��c6����I�f������T�b��t-���W�J�����}Z\(���B ����Iɺ�;~6eO��8杚a�;L	[i��=���>����P#�ƽ��^<<���t<��-�`���=���HUghsY���(�ZUo4���R��
ʬ� �� y�o�Vdh$[%u�:�fE������_�M�q�K]��/�P�iCx2�R�����hY[ z*#�w��.��H����r˧�WU1���?X!_r�0D�m�A�|�A�/�*L�f��(�$E����� �q�F�}��_���|��3|�	ZJ��0!��C�rT�׏e$�b�_]"���1x���>��7��F��wCmrx�P��
~��g���~�3�ػ��S��2�WYA�z�4�� �P�����r��%�3�F!Ը�����k\Y�]G�&���75���L�Nk@,��c0
��l�B[FǪ4$��[�QH��&'����U��V��o8"�K2����o�=e��e5������?�~�A�&�TJs� 媉�Z
|�A��IDQ�"ȴl�<~.��_\<�pk����(� c���C/M�kK�%;jRtV�M�m�3��p2��Y`����������9���}����>�>��:y���g[*�i$1Px�I|�5�!A�j�fߍs�F#�Y�]y�{�ɯl�6��S�ñ언�ˏ���zKZӘ�hŢ������=����9��4)���={Ǳ��g{35<���<[%�gL����gnh"r��3l�]�Ո�J���rØm$�;�����=�/���&0t��=�o?϶|�i��b��3��p��K�rz6��/��X�I<� Vp5��·|����&�� ���y��xV�%�k]�̡�� )H8L��nإ8Lt�����eM+L�,!��Mj,�0d����$�c������E������v�1��̼R���5�/�X� �B��c��q|�  �֪�]l���3�lZ�0E�џ'xs��F��ی�]������_n�ِǝj�[*��q��>�iV?k,��t�5���c����ƪ9T5�Tbc�=���Y�������t��t�ȇ�$���7ŬR�k=P�gC��Do�s� �'8���؉Xr�PPPvih��f�����א���7������~��Nb��҅E��:Q�F/�u����m��<�۪Ӡ3��O�J1�l�9ZJ	WȤC�H�of/k���P��|��k�Ԕ����Ľ�A�~��ao��"�o�hT��%�r�O���3�w	sw�WuE˒�arh�w��c_������Жy5HA�y+d�����d�?�Wc�7��]Ӷ`���rX#&��!�I�7��M옦�.�	�A�q)�F;B�-�x�Z�	�g�Ы��f���
"�cۛ����3�ܷ��jk�ƨ�iJ9��E�VtS�j���NHe-�s��}�R=o�A���e��,�-�~��YMK5�N�	,Ɔk�欐ЃA��A��B�t	ц����4���4J�Ǘq�'�5�q�8��4,��Xm�^\�B�p{x*>��M����������}�hqT<����D�!���\N��]�\��	e���ti�*s�����S����SiG����H4���,��{q�ܑ�m�Uǡ_�%�-<����@��o�\�K�2e^�W�Y=�[[�R��51P�$^�Upn���夂)s�!�����Tͦ��Ͳ�ǔ=}w�7ǉlTq�E�H�*�<a���T�F�����
,���6{�]Uy��.�,�����(5r�������>1y]^+=6�r����9�Ƣ�
4��������z�7���*�&u��o���5��nJ��{?C��^��)��HW����d�,�jo0T]�,��&��WE�s�T<�>�`d���/e��/�튴�<�"�#DB��q|�6шuU�
���~FQ�tH*I�ҡ�!����c>5��hy׼�l/���ɡI9Ѣ Hr��Z9��N<
�8��i�&�r>�,gH� ���^�G%C畁[{��2
�w��r�W�Zju���7<�^�d��^K�2�,n� MjGH�V�i�'$w�f29��,�R40#�#kG����>ҋ����@YxČ�E4��E���P))��y`w�z�c�7�$`�������[�%��ny�K.$a�R)A�������y}뢌�]��d�ݖ7F�D/�v"	�����QE{!)zBɀҭQ��?�����Sl7x���2��,�X0�xL�;4��>)Ѣ@�����'��vٺRsXT��r��W!��򻞹z��AS��e���d.���h�sN yl��c�lU��C�)�����_�o'����m�a��и�>��П�������8~�,�]��^��{ڌ����;��"�)�GCD�m>B��#�E�R�,�1p�t3��}������]^�d�'�k�h/��D�g�fDL���N�e����y;0<kRG�khJ��|�UP�$#�$�2BY�s�Q��Q���K5��l| �[��AlFM��I��,������GҰڴa}�����ܨG�L�F4���V�	[����JQ�E�#&�d��N���bP��cB4���r���Ś4X0d󟩝'n���[�?�oec|�nA���͗���֍P����Q�,��%<����~j?Inh>-B//�87�3�{X�]������x�~_��i�l� 	֏,���Z$�m�JH6:lq^9�ԛ�R�hg�����\�S󠈶�����S��u)~��`����J\7�9�hg;������{�A�m׶��c������������J,��_�j{{�x��8�<Jr��(��l�^|p�$�V!<��`F�Z�ZLϣ�*W+�e�_Uzi;���d�v!d�>I"'��.uYY����R����T_�(��G��ڹ�w8��CQF�z:#[��b�i��2y�d�[_��|��1�y��~��K|0w��G{�F�i�+�|���t���p��޾ۓ�� $�Ve_O�p��-��]m���B���+�])7��TJ�: *��癅���KEvώ1SR�~xN��߾zV>�����Y�S��{
�&�g��c&\暁$��DQ����n���g���Ý�z�4��Qp(��a��R2�mR��x������V�P���5:�p��@%ga*NE��KYj�)����#Q!nI�<e�/�4���_���,�������58D�-�ܦ��[t���:�K�k��d�����]��Nt%�\�O5�xO����*$��o���.��э�e��0��y���2b~���6|Þ,�-2[0`�ꝓ)?�ħ�(��:�wVd�0�;mǲ��.pL�;R�l*�<�nZ:b����ƨ�<�o�G׳۶�6�}L(�]1B
R�*��Wj�)���ٻL	\4��#\�+I���mm�)�vs:|�GF����]zE��ΠJI�CɩR�m��x��=��f�Cf��>�Mq���<OxKW�	�;-�a�Z�"�� ���	`��/k���L-n<��y�#0�m��o� `�z�[�kv��w"Z�+s�����'� ����V
��a���h����C��Ee?�t��#��9�����ƾ��#��!r�b�Q$On�=��8�u��M�^��l����ꢨvj��'���;���S���k�1[�mk&v�>:KzS��c���8��G,�ԑl�HKz�\TKsg��BQ�s���¿g(?8�Ԍ��[7#��T�p�`���0�8�9�i����D�k�<�w���,f������gm����7?��9�х�
�>�mca���a=���P�����"�[E��Z�k8g���(�0U���Q�Sb�)��d�?l��;�,T��һ��m��NB����FN��.1����}�CR�C���o��=�K�(Cg>��ս��X0�<��yst2�Ӆ��a��
�H��E��fvJ�V���c��;��,;�r�8A7�-nP+"V-�#�l���p=�7-K��(�ﶝp	n�`ޯayJ����8�;ӰHE�I@t�(NS9кn��	z��������?�����r�sqj�>��I�-�9%ǆ��ߗY^"2�k� *��"�h���I�Vqt]�"|�"�T�vL�N\����Sx�bќ�N ���BV��N	�8+T�S�?�e������>�^"��F?�_a0�Z��4<$�6+��ҟ$R��׺o2�:�m���j�D�K򕞨���z�]�~���(
<����0/�ࠉ��%[�L̺���β�D���e�ux�dX+|!�wR�
t��z�Բ�1��<����/Y�����5���s$sL����X��|��䶇�G;Pw���L�:���A)،�5;@�1�"����ϫlD�>.�{�h��2������%]~q;]n��)?��\��t��bI����`%j���#t�'�G���׆
���o��a���o�ػzk��؄�	��u}���\�RV���%q�A�A��۫��TZ�T�����~p�3��ý�s&�@Ey�?%K&�j-�H�5V�������ך�;�N�/�3�,4��!�-<C��<�Y䕁�~�m*���L-��2�6�73���A���=L� ��>Dߟ�z8��jYݑP��� 
W�(zS����i��9� =�|/DĈ����:`�N�~V<�L��~�K��$���U����i�����G ﯡ��(M��3O�'u���:�5?���V>�G��(�!��)p��W����A�����q�$=A���V>�?(vd���TI�J��B�u��BP��}H��1�9�N����0Ki��������f�˂h�t�����T���䴮S�����]��4o�	��ܻ �]C�YZO��=��Dd	��b����w��;DY�Rχ������?�n?K�-�>��h��TR�_5Ҭ��,��r���mH@:���(�!����l{i5� y?f`��~�y�ɵپ�FsG~���ޅ��L	����0~9y��e��2j�0��u�x-�7��wͤ����۾i?Ι���٢��=RcP����K��a)Ѝjˋt�����'Ro�u�������F��q��ܬ��>���Ѫv��Y����= ]��ŋ,�CȎ���0$��CҴ��*�N;(-�k)`�;�ێEe ���'��B{�S6j�U�,��1�.:�����i���cq��A/rғX�u�c	�*1���8'�!�>�</?e4�{P�2�Dw�K��E�����ׁ�n����) ��̶��I�d�(�&t�F�k�8�  ����(	�Z��4�ۍ��ͩ�O�,CvQ��Ȏu@<�W=��b�����b�AL,#%�5�u̴�ϵl%��x�
,S�f-$Dh�m������O��F j�3^��$���}��[�\7Z��!�hD{L�5����J�0�|I��S��k���t�-���T(6��AA^��*��)�X�p�u�����e�������[�F���L*�N����S,��m���:�Y�wO�6W�y�c�G@]��(G��x�Qȥm�q�4�>���
�A���8�B4���~T){�~���{�Y��^I�=�@�RF3���H��*P�] ��踃ϲ\����$��{֨��C�.  ��0�GO>�mOū|�4���)�r7��H|�c�&����l���q��D|�޷\V�P�+T�vY�ܧy��t���)��mh'%bSÙ�*j�_�g���u=[AN��"|�C���b�+�_�&B��8��9�H�z�!�6�w�B@O	�s=���{�nerE�1�n<}���y1�Ū�54�@�p�9q(Aa,-��bT�QA�|��bM��x��$��Ђ�L�eh�(��O�p�����e��K�Y��~�k~OV�κ�Nɭ�K�.��r������T᥉e���%��Rz��E�]A�Qu�D�p�w_ԑa����EzZ��P*~����W/%�m�?&������냐��{7Ą�����s���11
��Clr�%��45 N/��V<h����!0,�$��:����p�w3�,є��qg7�0�fbY�#t��R'�Rc�A⮕��x}znͼ����)�!���+�J0��u00��[��C֢�M�;	v�	?��c�Wd�JTܰ���=��7	�[��S�H�!��� 7�����g�a�WX;�W���ݣ�+�7�IS�撠��N҅AS���	�9��� �Z�2?�&3{����M�f82a�1�5�,�0R�13_�@r����2s����Yy��!/�`[��Hh�7U)�f8�r_3]HZ�%C��4ӌy]KYH ��1��
e}��UtS�pP"X~8]%v��QG�8���K:���HxOx}�v��WKF�����-���9Y���#�MT���h��y���S摸`<E�Ғ������\2�B=䥬�$�E��?_Jb���Vt�����àW\�v��>4��)]�4�������'^mÔ+]��B��IY��s�hK-uwy\1�Cov{��St7{�A�i� �xrg�n�PE8^"����S[�:�\�c¦�g����Mռ����>1��(��8�8U ��ism+�p���5/���1!LVp��L4G
��Q"oA	����Bc�w{=��9ip�,��`���Ri���`ɸj���;�/���M�N��/?�t_������]���d��K�㾞=�ZO�3Ʈ��� u��q>�?�x��l��D������
Z�b{��$�&߈
|��\��D�*{�Z��)��'��ϧv�Cƫ����_:y^ǏТ_��8?K�a��u�F�
��]_ET�[���!� léϐ�`���Mw�h����?��-[�@�F[p0rP�����;^ϑ���j1���	�^���Ǵ�����*p	��W�Z�Q�U}_�н�~h�� ��$�5�֞a��f4剓u�4a3z�zf]�2 UB��g������Lp� - �O\rך^����y�Ww�_=���h�,��j���n����x�#���⥬]܁�
dB�p���5���{��J�tj|�O�����	�C�� �˂�����k{g�5a���0u���>�x����]hy��}R8�^����0�iS�y�-�ѥu�D���+�Ҧz��)�!V�>�7�G9b�8��n��D�/��UL��/Œ��T�9/ݨ$��kZ�Wf�{�GQ�h�&��.C���_A�V����uxQ *2�Xms���@��C)��a��Gb�L�n��b�".W�%�O�q*�Ķ���(ғ�0�ᐎ�r�XfU�����͌>*B�����b�ǆ�I�4�^*^�|�s��:F��b���8s��4�o���w���A'�\��J�;��|T8 Đ���:�!�'W�(��G��i�*HUu]�4�*�IϯU����{�D1���������Ҭ%>[`��"3��oC{f�Ԟ}��/��@B�G��Ч-ʄ�����D�ڨ�?��3�_p��L�0_�J{Q�s�īEŚ��dr���Y����7z�_&��zZ���u^z&�\0Vd�i@kw���NwJ�+��M�z�|��T�ǚQ������85x�c�a�tcCodL��q�S%���H�����ڕ7�ˮ��ť� O�s��i�${�F�W����h���GTBqOei�ǃ�����9���d3�6�n���N��b��#���6�n��> �,�6^���P(e�E۞]�����h{	�-�c��Y^>1��0�\]�'6�Gm}V�L5���U������X³0(C��8:Ć�h�3��z�7�g�Qrom��̷s��lݧ�ҀN�Zjk���2W�5�������l�^���
5�m
��r��j��K�u��c�K1�ݿ�I*al)ݠ��bx�{E�3���]����R|�'�L�E���io<�@F�ğ��^�6�F�l�����ߌ��<�C���ƇF�Ϣ���� �Ԅ3tJ�у
K��Xl��e��#��<�n�����K��T(�?f� <m�s⚥���z���<�G�����gk(oGu�+:.9��(EݤJ��7��C��K�i�HC*&_'�$X��+[�o�������֔�ghn����7�3�V�V��hdo�K�o�{���5v�����+�NgK�����~��n�V��g���pz������aQ��&63G�j�μ�a������k9 �mΟ�$��6���j�mh�Xh��߲X~�AǗg����Z��,g�;�S����ys"z�d�Ӯ������QX?y�c��Tx�jݏ�F��Kn���7�r<\�6 al2�;cB,5��G�#' G��"�;��������[������w���E{�88d����C|C-D�M�A����[6�3}�]*��xR�`.�@'�i"-�yG�K�H����6��	+[6��*`���@��d{���:W���wQ�Eh|�����QUc}��/�Y����^G]5���Lr�k�����(3(h� ��M�[L�-3L�b�ZZ�g,��މ1��Q/��!e�����m>/�'�&�SYܧ��Ѝ>�0�B����Q�D�����PN�����d,lH�[!�~��P�CH�ݑ��LU�:�,��d6��I?S
œ�ZZ��$�����dKk��8<s"�X4ӷ㉈<���}�Y�EZ�G�������VuW�&���9�|�i�1KEIh��e�����#���YVU�ǤC�:%L���"���6�5��%}3�eݚQ(&�dy�gSs�*�R0��U]z@P ^��L� �y�$|�,�Z*v߂�6�խ_�N;f�C�@3:�ѕ��zm�9;����+^B��-�4rT�3�3(
��?�My�i�=m
����k�.�[4|�K��j��~�O*�W��I�ށ�d@��$���0��_����ˢقIjj�� H�n�~��k��_ #��O�@K�wG��$n�\a1ÕE<l�Zc͘��h�π^헶O���.� ��я��a�ō�Uɧi�Mƻ��[�1pؑVg�u�G�u�_��#���՝��
(��Z�|`��7�8jZ��8AC���l-_��W�	����ﶍ���=��Wk��� �,w�<[�=��7i^kƐ�(�H��2@��$J۝�Gm��y��e�:(��|8���t��D�-�/�w�Ĺ���f��y���%*��e�e��y��_������ƒr`�ݥ�\k�i*+X	�bR槳h~rNZ�I!����'�3A�U�����I�q)��(xG���q��6��	{��>�w��W���������+���P�$����ٸ(��貘?�H48,�R��}�bOp��!������]P���ϒ�3OR�!�pjT��~6��!�?��@n)%	��j�a ȹ����9U����+�b-��o&5�?h�'>Oo�ze�+�3�²��qTRGD�!r`�Ky�n�Z�Gk�v��s�a|���%��jl���Ip�c��#������� �R�=ޙҡ����$cϲ+�'h.u���ji�@�t  �>�)��f笿���ŶD�#�uPGˤqÅ�u;?�sx}*��n�:���;~�ٶ����T�ȳ�����@��F{�͗��gc��Rʆ�y`���z�j8MPj��:��bD��D�/cY\�l���~"��/��r�~1���ן�:�@�]W��X�uy���
{H�:+���NL��1�N��&��1��(���j6;��o����`���++m�g�x��������1�J��f:�>
��(ƎZx�����P�q��
-|G1�\���:e���F�T}
#�86�u�o�r���i+�Scͩ���:��LhD41�uߏ{[p��ާa���J��+F����d��_v��p��._t�.�P\��!uK�#k)��N{ң�ލ}&����8���L/D
;*G���g��mQ݄{�}t�6�k�L�!� ��tx����Yfa��� �"iqui3@jwy�j�����u���?��m��E�t���Aˆ0�#?_7���#4��F/{�^�!H�'fG�!����h��E��Pȶ�D�-�ɉ���}��`	x�ꑜ� 1�0���D`zm�a�-u�P㸝H>Ǝ��K��Tb�T$��Z2U�&��ӆ{��������ۛ6�����3�b\gH��ɐJ��<�=d��N�����~䉝j.v�Q`Vo� �4�s�Y�j��_Ղ{c#˩S�R�@?�t&��E�����0V��N�QgBõ�Wr��܌4�$H|j>�S��$}h0��@0ʺ1����6����#��L��>i�a�8ߓ��\�ѣB_�m�����o�8�6��P�]?�l�j�粽+���n�~1cz�b-%.P�Ec� Y~��d��ܛJ�P��r�Zv�p�[v#�d��*X2�I�ݗ/��L��"
���oV��UpU©�:�,s����S��"��fJq���V(�"�fYN?c���"��VY$o�5�J��Js���]n���l%Eą2S�*���%�|;�3���b%,��4�b(�RA�H|X8@{�s�>�zږ��h��^�O���\��C>^�(7b��۫���۷�*�����'�;�Qc�2D��x-OS����::�oIpk�=�������V3�+5G,P@�7�_C��.��w\��m�_���k�ŭ3@ �@��&��j�~%��@�����;/�����9��@��E�û�v�y�E�7(F�)[�؉��O	�(d-�hA�Ũk2�F����ٍj�7��U3��ݵV0��Р��~j�g�J�<�ZW���1�h��5� �=m����/(�)�����Ȍf�	���r�
>@�V��t[Ի���'O��nw%+�-V���)@2���G�� u��r�
Z�K)k�\s��!"�夨���{�U}�σ�9 �]+h�t��g������;UA_l䑦-�J�;�9J��n��A�?.w�A��	��	^"������:�M�{��m(��{(��Y��Me����'���}��<z�Kr ��B49��� ��}�U[7�=J^XdZ2kϒ��b�i���{ē������L�.k9شp�"���o7Z[�6G>�v���c��Yݩ�!��u=�'ה�In6i���$i��=l!s�D@�J�xO��f��%�Z8��J�ܔb��/rYk���ϤT�!J��]��O��X�/E�X�
|��Ux��+P82��:��~�+)1�������T�@&��p��wTX-�,�&�&�;�3���TyYfh��O����R����_���AA0�%Ƣ����eɒ�M�uP��2���IL)��O��+��m0�ʥ��O|�������c� 0��h�)��g7��E/=0����V��-�Z}}6�s_B����6�+��<�GH���]��tX��-އn��$<;���ʎkX�"E%t2w�Y�S"�*`��} ���8�R-�ڙmd��hme"��S���Sc	SL��n�����D�����
 Ix.1��1��¶g���D�8��Vh����S���������T��F"���[�J�[�k���,f0���v-��(@��6�P���7e�n�R"�Gs�n=��Or����Pbu�A�Tx��3&��N��ا`�
X󬌍Y���̘�W�z��_�����H	f1v��?� MB�Hp5Ҩ��o�b*��N#Ԫˑ�hb�� ]Y�	�-3=�="?�8G�[l�]�VRP������*CX�o!��{q%5�
�cT�\��汋{��6R�@�����N��o�qk��:ZQ�Į2���5}|�"Y#ؒj���O�Kϥ_͋T&�tF��y@V����65�����\W�2<��!Y��@.�y�U�^,�[��C��Ik��abD6�\�֊	d}�P�h�#�;�Ǚ�$V�`��J�(�S'9K{0����0�W&18�	u{}��� L����ӓ� |���f���3�`$��3�σ��I�Q�z4�Y6�vd1���s�'�?tU���+�H����^��`�ٌ�B���SR���8���!2����7�l�J�B�㌨�� 9�G�l����o�X�.	�����w�8�F�y�;��tO�T�V��z��
���i A[^���Rn�kW��
�M�M8o��e���7K"��ϙnz��e�a�̨��w[.{.��h�XR���OfWb^fP:5+�����{���D��������i!u~�vsy�+/�_p�����lg~M�QY��
�B>�i��|���A��)�k)Vu_�7!��ީ�ĩB����u�*�,���Vo��j5Zi�;%�^�&$��1&�pgSF���oǽ�P&���x�kH����;����h��˰��sJ(�ٍU��29Tz}� *�3�P!��m)���q�@A`Rw�^�L��|���d��0p5��ㄪm�6e�t��X6�ي
?ţ!-��B�o�E�8��@!�u�n6#�5��y-�N�* �J����&&1ԕR0|'>����}ڟ�蒮qu&0�bv�!3��mI�&S�=̩���j�g(.v�"*���
j�"��@�f��#>eG%i�&��G.��vL�zt�w�r�o�HQ�7�Z*c�(S��_�;�vI��뢟�р91��L���[	�:�)�[�B�m�G2�ގ*v�i+�_C�"8X�|@+�����֟y�ԁ#�M�V�=�O���S$�tN�Bq�r��n��;�#!�!5�����pY�N��*�����=�z�4GTukz��g�^@Ԣ�!'�Q!9V�N�x�D��k�fa��P)�Ԟ���] �4B��%��v�Le1��W[F,r���*N�9��U����<�u�eS��,�3^ܽ�͙���_���1ds>Ы�@����'�;z0l��m�t"�5��o���vm�?�S�j���[�˘;"ozFW�ކS��C>��|.�{�6��������dLf���$��0�,��2�e��)����ay5�Q�v������NA��ELk��4qxL��/�|M���Mr}�Z���j���E�P�ju�.����
�Gs�y�A�Iu�Jo|� j� ����c�K����sʤ���5������0W.�5[+T�,n�z�N�8<���WC��@�_�����HwM{�=�`rm��FN<L7tYLA��WM��m��28�c�͍��mOV��:;��"�o5N�A�`�m�+�G8@rs�D�&s��������^�"0�'��&,�T�v�[���ҧs�� �+/�\f[��
?E=���{��i�hҼ�x�>Q���;.3ܶ���l�j�6�G��꬙�jB��o�5=�篵�P�~`�-�
�q1��&����\���"�6=��ȥ��e �(�s��������+y%_�NPFyz�v�Z�,h΂قc�ʒ���Oq"~B�+X��g
=�԰�N䬭Җ��vm�h��0�X^��"���sϋ�Kz?�R̍���a�I���V�C���������mP��]�b�U�$1��ź�/e�d�˘�G�P�rc�Ğ�;�z����ķ�`���ĺ����	�1�Q=-8��%��3�n�Me�p��>�{\ۄ4���pm��ή�U2QaG�^]0#�,���7/zN�&�jJ_h�W�z��;0�O��i�à�/u�+l�M�3�I����&�B���N�#<tT���7@1~��a*�ה��m��}���!˲�:��6��X{�	T�/	�f���UQ��y�3*2��ި�?�/���3�$����-2d�)����4д���բ]3Y���;f�k���:ƹhZ =�}�X��&} ��M2hȇ���SKLcr���.���[E�_o�J�v��B�-���ne�}��8�K�r��w��tgy�V>qov�Xa�B͹�1�R
�<�G��h���r�b��3��-Zpo������E-_
�b2%�-s
�~"�t�Gr������!{\4(�gV3�N��#�����6������ }�x��7 \�"k��[�'!�kȼ�n�'�q�Z���N���6r�WG�f�}�����v%�Q���~v��đG�f5l�Z�U�����ͤ�`��`�-�E��|-���i?����{�c��@M�!���.��� �_�yn��C��<1�>��\9��`yҫ��D%���l�<D2�I����Ń%�>�N���� t뮶����)I�?7�<� <����
ݏ^}H�~�?���f��>��%!�+B�mNzi�QZ{st��Ua���,*�`h@+j��M�˶�t��d?���{NxtR�_?sKWZ<���pJ�؊B�~_�2(q�:�S��ed{EzBU�D��J�.���n]�$6��ؗb��(i��pnwI�^E�ָV��V��l�s�T�Id#�'�͛��ժ�r���U��뱋��v��E=�)���#��T�䅚	�@AۡW1`��/ԢΉpH���mU��bciXįM��Tçog�7M�#�AgY '��ɇ%:*�'�&�Q�ʨm;��y>���ڋ�F9�^�>���c��q��+�)��1j;��%�0q��Ha,�5|'�w;�%2<3��nT��T�#/�#��Z��tfm�����%v�I�;�K_l+��^Z����<�O;vgrƖ�l("�@м����	?o���i�ң���$����q9X{��JĲ�ē�}j��=&U���j��F�6��V���Ttb��b�#}�~-E����t�����-Yv|��R���� ���\�+���Gg����n��J�{���O�V*&wz�����.�d�㌨�t�ڨۭ3_yd��2�Y0O���l���lI?8��J��8�� �;�DN�����._4��[�}(�[����[Е������T�qx4n� 8��{V&�.`,�O��\k�t�R�>�,U�������u��a�^)��/�p��>Ѣ�][S4{Krwq[U�u!�����g: *t�w)�1e a��LS/���
���J�p���sI�WY�/d{~��tk*�@����D�/6�B�@Ipg=��4Ls9��ʝ�(cou7�H^��C�~�g��lE���%�`�n��'L��Ѝ�
'��S�Mx�F}F��Y�\�/�[�:�+�>�fݕ�蚅Ywo_+�ų9���FNNt�����I��?�\���:hK�|�t���W��-v�}!�
d���f���Q�� Z���
}�؜&�ʞx�5§�f��V��j�v2?U�s�E��@2�G[��u�G�'��0��:#�%l�?����w	U!����+o3AB��\ѢG�j���R�'J�$�7��|�;��p��WB��<ښ��a 0ɠ��7�)�M D�LC�:�������O�vo�]G�.�R����J�+K���Lh�3��B5w�p��
ƞ�
���D��~�fia�q�m���A��t=�ղ���<ق��(k�%�&���w@�ᕭ�����[�̌�TI�ni)ٜc��FW�Э��I 6@�i,.9&;�Em�@�PZGӖ~�t@�O<���2`��7�-�HZ����%�օ��%!5]��E����%g�� &�]�EU�|S��7��{��/]�����a�˗CM�A#��9.wV��6�[�d���d�d�u���'�x�i#�W�7�+!J�U1���B*����T`��XTüUi7��e��a�w_��|��� �fMf�=S�P�p�54�1`zv:K�΅�d�{
_��G�T�{>n@9g��m�-�u[0�d�ܘN��@�N�/�
v[�ؔ\'�t��=,�(j0#�g �PO,-h��O���<�Ѽ����rh�$�\0��!���֧9y����!����[*���ߝ�U`�����u29�h���צ`�\˒��Z����p��H�t�T�G���E��Qc�������!�-��P� ����!'�*�Ҙ��l�!�W#Zq���f�\u��R���������+�*n�Tq^M@a�(�ؗ���m@���H>�g��9踵b�:��g'TbsU��]������]��JA�U7b�����mV���3���?�]QH6�
�{V��)�Ԩ^H�>�-��n�.�O	i��	�r�~.�,�%�K3#�;�ҕ:�� ����:J�gbL�ɀe�֥���l��Y#Hvl��N�pW�F�7bfH�p���_�(Ȁ�C$��~�C�kV���,���1֌��#�u��h��1�?��_���
�9�����IZ����i���0�1��Q��O��$A2]�o��v�5w�B����uv��U��.�4����L�2Q ��ꗰ��o��V����GH���|鬟�2�^�7e�\,3�j����g.��}�)�3K���h`���� ��A���U�"ډ�HS�fo����JFf����eJ�ꎎ�&?BhYÑ��１6;�����d�}�^�Y�-�.��Ih��֭�ׂ4R�˗�u�IS�[��:�'��je�#�>��
�f̾ޤ���_�N�$�� i�Ӥ_��XQ�chP��%�����b#�2�����)�+^���d�����(<�M���;FW
��H ��RΘc�mkQ Z��9O6�+�ͽ#/ȝ���!+ �1�՟�k�k�h���s��f8	� ��@	
&��}���\�k��W�d�j����]x��W>��s_n�'W�}�r�	��)䀲H���R�>��E��_6�h&$��P��{�l�uoDI�DuX�U�.��OՄC�M�H��G�X�����S6?្q�oA��     +'Ȭ�$e� Ͳ��˼3��g�    YZ