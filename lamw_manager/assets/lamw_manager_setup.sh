#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1623713086"
MD5="7c2018572c2ef3a49cbf64ffa99a219a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26376"
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
	echo Date of packaging: Thu Feb 10 22:14:30 -03 2022
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
�7zXZ  �ִF !   �X���f�] �}��1Dd]����P�t�D��f0�5��Þ��F�I�f5I~H���PN�8�ڡL'/6؊�P�U�G�
9�����}�Wq�qw�~�	y����T嚣~<�X�u�l�Ftq���w��5"_�ݽ�A�,6���<�+�}�;@�݄�M�3�%�T[���-{~WX������x���=[��|�9kEZ�݈5��8}!"zˠ��%�!I��*�Z�S��u�=�<�Yk��>�V����g>��x��[�0�w�5x4a�xs o|tK7������^�$켓<����|�q��x¨R���<�5�X؜��cK��V��	��X�m��Cw��,�	�B�,.x%�c]�������2iV�)9�9��&^�ׄ�S�2�E�Ï��5	�Ș�Fg��_���/�* �	���p��g�*L�O�[���7��W;��EW�W�:}s8Z>��a^�*2[orH���1b0˞�8���em��
A�B{�إ���$$ؚ���zu��.w�H�Y۾���qj���fW�#�g�ר;񓳢!�S��,��T�=BAA�F9O�tW*�2�v�!��Ӽ����Ϥ<Y�����u�������cU/��h������E˗iT��S#�I�Z�V�y��;H`�H�h�W��l0������#H��@}w�K\b0���mۚ��c]R�� x�- #�tkxg1W��i�Q�o�!HTX�9��sb e><����X@O���xBe��gz,�c��XS��4.�ֵY�;<��M���3ƪ���Z�^ʧC��<@�M:�՛`5p_�8&���<+N��>�^o T�o�-B���>�P�������3��^��M�x�W�����Z�4�H��"E��Z��{��z��ҿޮ��A�*����8s��Xc���[n����4p6�u�Y�M��5w�?����+u�W�|���_�E�T�*7�M���h���f�����@�<,�fS�KN}������WK�0�&���n��8�f���OC0�k�u;�z�K�S�/��3=�q��ڬ3^9<�Ťq�>7��I�ڷ'�Z�����.L�t�a�s�W]�[�Q�Q����"n��ǒj����O��|U���)�c�,���}��p�dtS�Ua�����%/q��B�x]?�b��&�SB��u����,���)�@��}���>����|�ν^Td�������Nz�C�n9t��-.l��BR����_^߿ ��ٜ��"���G�,i�
�ǐ��������&е�v��皫J������A����YVx$Ϙ���f_*�S�RQ���s�X���.e0��ޛ7L�̽D�/�}*�M�p��뚁l�����r%��񡗞���rYNgdf�Q�$d2�����~���&b�\���P�5�V
W�J���%bz�yT�?����FEW�>��j�,�Z�̨�Q��Z═qrx'�ҵ_����2u���VW�y���VhU��֭9N��UW����D/��Ǵ�3�lLr�6����x��@���%Gbd��C�n$��#e��/��QW�&�"�o{���B�:�29�ÿ�Ѷ$$XEf������dƭ�z�\�o"!
��[Pe��_j��D��H��Z7PDu��1�s�@@���<�R�o<X3����&{T�>�4�q,;|+�ay�����H\���a]�p��ivSڧ�?%�.�}TB�A�'Q�*l�q�-찛��{��c���pn�o�{�:�J%-���(���'�]��`�����"|�!1����P˕�܇������i��x~6�,Pu�օ	���o@��{�.��-M����! �]JT\�6��N5��uΪȑ�HyJ�d��e�E:�x�tRi9�(�p�:s�����G����3�S�W~;�s�j�{e|��H���5mZ�N�3���M�&W!鹬���ߙ[��!���h����XC�v�X��3_l�r�Z[��x�/��7?2�Ge�d���=����P�g����;"�e�0���vOo0Q*����k�].Iu)���W�1HZ0� �_Y�{�T�pd��bM"ʞCѼ4ڤG��!�!�k���b�KM���L��)l4
��:��5!�1Bv��\�Wt<�3DV�}�tXH���8�_c�����p/T���D8�K)�>�k��CA��7 �׼.�@	�p�&��0����ѵe�J��M��]s���%��iNP�1��i*!�]�����ZoP/�b�?����瘱�r���I��L�~�e��@�ig����׳n���j�z����1��>7t][ �Q� Dq��R�kN�2�+�)�Yz���׀��<D����G}��=�����m��}��lEzD����DP�'Ȝ�;H��)��x����*p����7`��,�z:g;�G{�T��ۘK�Pݓ;���N�B�H �*.C��#&U?R4�h*֎dl||����G-�*��Ϫ��k��lt�)#j��
�R)�1���� ��P�f{\�����f�ټ�B�C�V�;��~٦��~(~<�)��o8��� (-b�sS�8r���c8���ލ�|{S�߽����i��
�wO�xs�a��_ێ�=G.�A���˹&@�a��"�O�|$~�Clo����ޯ�8��!\��D�&�D��DJ�m3�x������4>:������ N�,�'[�)X?�����=T�W��-���%���n�Vmm���fѣ����ɏ/���i�AN��y#p&�^y��2�瓆�����G2�Vsv��N�j���F�# 
/�Q�$��jޮ��*Fd�@�:Gj�:�9�" ��ܓmV��*�5�b�[���DQ�uem��&L����[:���H��C����Y<L�[�%����+i�A6Ik�ªYd2wE� '0�r2���}����l��6�����$Ֆ�?�����_��G1'�k�c��bN��`�Ǉ}�e�;1�*͓@`�E�:�8s��w;��*	S�i��S�,��(N�q�^��=�͓u�T��^�`���ɎQ=����X�W��a��5���~�y�C���o��,7T�� v�{�\\|����V� T��eb����q��c[WFb����Җ��G�u�7�k�`xJ>��ꣂ)��%*������<+�4n̯���5�>�i̧��ȒǆxvN�3�ϛ�a�]�̲�vB�T� �QN3�	3U��J%��\U����U�7�^�&�t?��m|\n���ԛ��GI�Nj�,P�p�(!!����:�N����7�����ͱ�I1�B?�xf��Ut�`��Yw�6j�k��Tά�P��=�Ҟ�7�#�x��%9Ka���)7q9``��J��Ǡޑ7R�@�������$���p���'������ƶ��ԁY�c2�2ˈ�ʗ�� 	ϒ|�>l,�ÃbNF_ɰ&�8�����5b&<�"ezX�4���|d��J%�=p`W*<f����ו{�i3#g�v-流'}H�HU�>����螺�0�F4��b��UR��Jhz����F9sl&�A��%)�K�ua<t/�c��������y�4��,����+�t����82�  ��yv}��P����ͣw����w���߽m��~�{LJI8ׇ��`L�3�N;��ؠ��9͠�����\z�@���͢��;Ц<?�5Ͽ�N�f%�<�����3I7�P��W�*#��V��I'���fͿ+�}����]�'����gk�Djz������EL���AY��_���?��gG޺�w�#v����� ������ځ�`P9���+�+z7/PI��<�/XX��snⴚ����M�$�e����j#1�D�.��G�K��J�'��lm`<�V���Aɺؓ�qm?)lأ /�7g�,���C�/��Ti�zst:�=\��{��wi�}�*������IT`>n�.�5V�Gfx���R�;E~|y;G�)f�q`����}+�}K��0��ztI>�S֨L�f�T�C�8�Z��Z H�0�Ӫ��o5�V�kBA�T>��d���̣�.�(2R������`���']r�(#�1�~��?�X�ɢ9>�,fǝ�:6p�����Eѿ;��EϊZ�����{�Wds�8��H4��W!�����F�H)&R��Y�EK)5ME'1��ȅCa:.J��3���!=�d��GD}�߁V	?a��5_��.���P#'��t}�a��ʙ�Q/؂��K�O=�d�9��*��	�n�z �gV���c�ژ���g��	� |�VF|?Q�d�N&Rt�Hɒ�/����3�5\�%g�"qK�:�j
�,��.̪������|�3T��%7��]�3�Ԛ��2ܳs� ��\V%f�Glz�EY6����Wt��s9^�tb�j���؂�g%�h�iG���]�Oԉ�T�3?��mv�g�6��bb|���ﺇ2@��fdu�V`u,��͕�L��Š@�� A.o>J&�F99���S)��;���	��(�K��`��X�*�N.tsQ�<W��$Mu��1T11�ě���z=@�iϦ��u�������G�}���=���7��I�;�Koa�,W��*a`�c��Aa�M�θUA�m� ��^��4{��+
�,Y߅�.&�L8ى���f�����T'+��SK*<�nua��K��P�dn�z9u#�.���|���Y"�2-1�E�q������`���ܟ�=����fġiϬ�h�1�@8_���H�^���L��S�G������<씃�ɻRڔt�w���^.��ѯ"��RA%�����Ɔ��B�hi�l:��k��`s���Xܶ�A1�~%)N��Z�zU� L������	�f�%(�O��0۟�nԣٖ�.��&��z�;�1����ǉ�'_��B�8�#���+X7e��8TZ�H&�vcuӐRO�Mȃ���ִ��t�qJ,Y�"
7kh��N�dv��<>~4S�	q(p���y3ޢ�;�����d7��NI`���>��9е��v�����!̎n@UP8^0 =�姾�@;���m�ow/i�����
V����Up������	���T��ͪ�;I�������8#��`�~�#�'?���ě�׷�j�ev�4�\|��j�(:B��_�ưh��ܳ>��?	U�tGYV<7NYqWJ2��ə\Ƴ�~Uۉ^�e�O0[��c��N��N����I��J  �pQ=±����`� ��TWػ#�s���Z�I�tH)�N]����&����n乊�׬TM�&�*�y��)��5��s��r���X�{>��M�T�F�%��9͒9��{���3'�P���Z}������1kL�9�
 ��""��4����kc,�	�>(��gb��I��&��{ԟ�9ݍ�4,i�����6���w�'R5/�偓�	$�b�ug+�Cu|7M֔��\0�������q;4_ v��˒��D��>�TMÒ8Y��W%�rd���3e�h+��������"���R�Y��q��JB�C_7[��|f7�4F��Ft�ţx!�D����]+u�2=�ײ���*�]���Ѽ�}R޷N������e��B'����%!U_����x$-ڍ1[F�-@��z����`2��R-ͮ�:�3�/�>ܫ�c� ��R�����a�@s�H�=���ϧ�TLg�I�*�i���Um^�` +* ���C��`_�z:���9�����x���� 
=j�e%��7).e@·�J���������W���X@�J�طL�QF8����̈vZ�hS�#�e��Nf���=�jF�b�%�nO�STF�-��K +��Z
�2q[=(�w}���J Z�	[kŭn��.dV�@�O$���.���ڍ}/���Lx�a�g�sC��Lg��������.Dv��4��`�f_L+\��v� ߑ���X�OXNI�Jum�е���L:S����I����jL��:f���'#�����F���9�i��x�/g�M����s�H��s����d��,�M�tZ�м'�-/_V�1 05�����$5[�R��я(T0�1b^�X�!04�w�u`OO��z E-7���]�9�*��%R�BX3�q��ĵ0ü��}�G�NJ��j����j���@�~������K�B�ױ�}�D� �#�����8�4K޳�b�S�E�|r�h�ӥ��u������X���|E��Po��RwV��o���jI]t����D��D��^2+^��;��E5�-��0e�h̙�g?���R�iwy|$PԒxB�`�(`����������=�o�桭�v���}�ҍNR�Օ�?\�P>�2nKH9?����]/bX��7]o� Wt[�T�9X�f�ԗY��|+�v���XL;��P���NC|_��ެ���E�O"ȼ�����lǈu�zwMv�m[��G����"X���*�ϽC�V���6��Ut�.n����+�DO�MS�V�!����7,���fI*5C�E��m�㐎ȵ������\��L���:���,���OV���*�_5�����?0�k�I�k�cy������A%:fD���)v�bo�5/`�Rw��k��$P����:ݯ�l�]�4��*;�m?�E>�Y�%�ϱ�� �
����Z~�bki:��C���g��E�QF�٧�
Ӏ�V��X�S�T)�r�>OK�&C[Vr��ەi8���9��N2S�0&�#5HD�?ԫWK6�]�$�Ʉ���:���9��<L��b���Q#4�Ԙt���V2��mo��.W;�vp8�U���mi�L3�^C� ,TH��8�Y�h�[	��	�Ԩi��>���C�{��Y�f��@r�Pc���[���u`����g�F�֚W�\�&B�s.CפF�H�̓��$��V�t-R{ȗ`�Ƅ�10��X�A@0�v�
�w���ß��ڭ�T$퇦<��u�r�VӶ�:$�k]�D��ڍl%WYw�'�T),m ���o
W�E���݋�����z���V�K���pw�F���t�Vo/(��������CS�C�v1ۄVA��	l��Y�&{I�Ecf�U��qbb,X[���m?�r�:�L�M��ڦ2����Y&��z8���]S�����9��5�˚�DY��z�&�whY�֬1�\B �CɃ}7F8�L�'��dS b�����ѕRd>�����E�>�(����ܝ~���1f�VR����ث{ ��C���q-��%D���B%�|̸ؐ�NoU4� ��퀢VQ:>���,���e��~��PK�N�Ԑ|L��C>hT$�f3�xͱ*�w���ry�/A'4�Ւ�T�dnqf5��J�#˩o��:_�� nN�Eܗ�O�l��&���xbd�+�����eޥv�g�ߔQ�ٯ���� 2��l���Flv�*&0vr�#�h�S��Q`�:�П�y���G��P,tlS%�Z�p�`�|"�zZ(}G�Sgm���Y�Ǘ(6~RL�w���P��h:����4��qZ��1c]��CeҠ򓍽'ҵ&�,);/�o��ІK��1J�����>h�aF*`ܥ� q!&��),4�Ô����#�a@]��̛�{��OM9d <��}��'
?,{<�{A�=6@��+"����g���a��f�^��b6�#y�EcS�ֱ|��r�mw8"&�^)و�ѿ	 �Kı����xQ�Hю?R�U�j����=���^��GGd�Y+�{@,��&qvޔ���`�Ne�q�7��.vB�S��ՊuhM��"	_*�&��~��&��ă��d?����T�Kr�lIt`�1��J��|z�\,ѹ���~��b*ޔū���:S`u�[+�I18Y`���ę;?��A�j��l�=���}-�Ov�p=���n�e2l�?���yKS�S'Q]�9����f���A�7��ٖ�XMwq���m2�W�S'<���')�yA�(�;w��8U���]h��S�6]�6�����G�9�A�:�m�c��_<H8Q�Y?'�i����_�p��/�阮�G���S��'跓��J�P;���-��2H,����6�m&��gR�[�M���m�*��lFlB��hܨ�V�o0RV	�,� �:������TBSo���+��\+Cz�s·��ˤ����ÿ*=��t=��GRj����.��|�"�ʽM#�1�e!Ou����v�4S-&�ׯp�L�~ZI���r�R��P��>�i�g��ׅ��e�({���з��4���7�m��ұ(ids���2֨�AX��jkʅ\���4"�S�/����˂�(s���M:���wI��2�1�����\��F�7Jh��,�V�@l�K�Ӗ�i�B�u�dՁO=If"o���'�2^#8F-��M"1��C����%@�9�iZ5��L���S�;1͑؀,��K�t�������q�� ���0�"R1�S�ix���s-���2�9:�<�ϒ���]��5�!�^Mi�=*U�?_�v���!kq�1�\�݊d2���~��d��X�Ѡ�:�C���Q���f=C���6�(��/��W�2��8�6��nE�JUe�C��^"�B*k�,�0&u���z���Ms�B<e@���>�d�ɀ1�}��
%��և0�HX��\̎�)��G�1��qf>e"t�H��(L?r����|�r��4�2	�cةH�3�
����_4Jڀ�͏�!nf�k)E�^_��6��4������X��.�q�)w���_�P�<�5�ڬ��,٭Ϛy̖��_njyC����-Gk�0�-׺ �e0�_��?d�j��5��	��zh�����w��>O�c�eq-R�[{��!�{�1X�t��"����U��c�Ф�Q�l$x�)T��f�suG�h��@�פ�97��(�_œ�^�܋hǒ{��ʠ���ja0����^w<�)�{V@��.�M��Lhd������~a��>Qz�U�q�D��7_*�(�1��`V�ڰ�*�"�yRh�Ǟj�9F�"wm�e^�`�8~�O�+��$'��\��f^6��*���țFfZ���a��Q3�<��`QN�B?:pdpdSM��g�&Z^�ٵ	-yX/�Jh��C��1����Y�h�-�QE@�~\���Q����j�юKD�>Nz�ugH�.�ņx|�jPe�~J��6q��|5�֞=>��\�s.�E)e��{��o}U�߭�مU�=a�k��[-ˮ^�"��mhŚW?/b�U���ٱl0s��F�sD���\�T���Wh��������r�X��.�4J�Q��K]�xn � �cydk���X ��ȬDm�y���{K0�|��e�8u����e�I^�U�|��]��H�8�����|G5��z;�C[�|��_4�>*��r��Z.<넷��۾�p�A1/�I��7�t���vl��Ý�;�~����!]V�2ш���Tϼ�^��a�����r��n����7�h�E���.���С(I�>���m�l��뮹0�݊#��\�Ƥ�c�͵�E�'����p3�������bI����7)��
�l*�;
=%�����[����R����U��	��4����A�ڰ���Ѩwa�v}q�!my�~�BT^����϶r���$!W
�U!N���:>/�ɭ��XC(t��u��lM��S�T��X�~���mL.���9,�H�W�?�gs1+V�kC��T�d�t�>n�9�O�}"e>
�#g��x�����@G�Hu���q��F�F�&������;���$�i}���_�FiU��>J��=���]Q�[{';�6B�L֦y{F�3�]FЫد�a�Q�f�̮�̲gjRɁ�XvӂyU���fs��sO�ɜ�QSǂ8�e��h4>7�[�wq�
&T//�8���b�!�%�O3|7)�ֿ�t;�n���DWm#�v��P����؄���r6gp�S*	�I|�7���b׏�ݗ{��t��}]�'6�=R��u��{w7�B�?�|���*M�}�f\���׆�)�b/�b��
��
(ܹ	%�x��dƁ�1��o�D[A��g��q�M��X���K�n��#I�F�QЮ������l��;o��~�8�N������4.����i^��%
o�e��)�Q�	N���x���� ��n����L����h?Yn	7�=�yJ�]�K��;=Z~�hN�����kM)����<���D3&+4��Sv{��`�hX�ʔrk�Ѝ��:�k-K�f���UO�n�{��M�BBg!�AX��|r�N)�$b��ʪ6|�T�<��rN�L�ԟ\�H��8��c9���p��G���E	!�H����]c��D	{D���tK�eF�
- K�x�����V�e���ދ���1�&G^=H����)Q���hdD�md�<'i�:�v͟R��\#T~�,@hv�ڛ�9-͌�a�M]q�p��l�k��e�3Ai��+�O�TOp�Np6[��i�:]4fQ�T����Ѐ�
(O�yԾ���T_�UV���*�?K��mh�M��Zg�H��I԰r�X�\�u�����>���Qn���I�N�����R�����WH�2a��T�=���krF�0/���ڐ�̙��K�"` ��[&��\�a0�%�Zj�	'�Lt+p3�[�WHJ��9���;�`|]۟FAF�3~
�5��
����r���1{��M�8!O"X��C�.\3��6��:� �K�L�0:�f�I9��%�zO�FIy��ԏf%�1Hf�ʻ�ql-<@o��\{��F��È�0�b��-�S�.�?�O�*�}�+��Ɩ'��=��
T��k��5���'D���PrS��X��k�d�\5��NE����`qI���6 r�L=|u1Z쐯�d��G*I��L�G:/^z����M�p�,��	��	ʑc��J�2֩ 6��H�Pɳ�ŚwrV�.��6�mK^D��L����Ѕ�
�y�T��J��.���;_W�m��!q9�/�[4
���A��6�KZв��f��3P�؝����y�\�H
�Ly���[L�l=����¦.y���91�ԶS(킾'<nr��-l���D� y�t��10�fӓ�mM�H��F�)��G�f(c�d��~EpS���4#YCz,��=�H)�I[I��Y�Ǫt��ּAU�m:k���j!�� _=��*�K-<�&Y�S0�<��1\��ά�	~I�J3ep�ݩb�;~��*vLp�z;z�*r���r�_Z��K���?�@�����~��Nf��H�������SWV)�*`���2�z;(.�Bt�a��)=���0�؍��g�*y���P�^�NV�����sX�OBh{W�}6z��2��*ڠU��f�^t����"�1�ҽ����s}qqw0��m���[(e�<��e���
/<4EY��%��-�%��Ы��5�#��\����+��Xq�Iޯ�P�S/E��f�@�~c��{�)"��TQ����-�
�����R�9g $n�7�]Yl9H�K��vU<H���-����)���.�o"nW98E@�؉�[`G�#���L@�\�S�>	�O��I#h}1xi�ǅ�����S��#L6�VL�diуWw�����e2w�R Z���x�Y(H"�n9S��6���0��oL�f5�}����'��bJ�ɗ�0�Ͱ���b�P(n5��؝��ϑ<�$����U�gkS�ڱR$������[q+"h��ܭ�Β}�nSrt�Җ��ٻ�(l�򁩞zFF�h�hx�N��2��!��c�k�j��5z좢������r�FBpV�����d�'�&�Y�}���y h ќ	�q����M ���g �����0$� ��@&
�z6��z�4(L0����	��ح�42r1��Y4d�u���i�(_�dH<�^r6����osZ���@��$X_��T m�b�F�#ei�-�rA�+,�u�w7p�~�`�B��c�?�������^�.���Z�8}���w�`�B�iG2�Q\BP�T���b{ ����.w׉�d:-������1%���ل�c�I"<~�
�zdXN�>Kp�\�@�|P��8)͹�����k��S��M�<�о�hv����k�F�) �,�.'8���E�߬�~!8`w�]>Jp�~�M���v�Һ��`��6S�	T�КCӇW���$,�Q��-"��Cǖ�a^�~<�Y)�ꪬG���B��Y��-�yU��v�����XK��a�E�4����	�a=g��l*��.���ohB��9w)�8����V�	�7�TY�@S��6�Ź���~/��h����ޟ�Z�Ϡ�h�TA�w��f�h����J��X��+"���2+�fe³��	�$��Ǉׄ��z���Ǧ�D�Qb�dx�&۳+EC8����$+1r�-������{�54�ޫ��l�b�n�HnW��ƛ��q���o�ne4�z�-������tH�4ч]�9VR��6��N0B��ʯ,�ن�Ͽ&� �#<�.Z�G@�A�ъX��
	I,w�PG�<���d�hj�T�+����}�0P-����,�����?n���ex��.��&�O����H��7��\ �2����	&=}YJr���X�f���Ly�p��4Gfܕ}�"�UP�� _5&Y"���7���*�Z(/�S'*M�{�k��0��>wN�R�=�?�4�U̴�bE��Ł0�Bg��/Z�-I˩�[?9�i��2JC���K�������苼�{&���+���L�{��/��@V\�J��، |j�˻t�p$��3R8�4�✕Ӽ�����N�d��2�v����P��th��d�v����F�����l�������_k�����|!V�KI������*��@��Q^��H?���Z|WhH� ?��`0�vw�zU��t9p�(� �0��P<�V�}�ְ�D�=���h�5��*�e�p�<��g%98��s�P(�5�+�B�l��I���� �y@4
�)qHj,�uͽ1�ƟV]�u�^&�G�<Z|f�+�C%7�?����}�n�x$=�Vt�Vd�A>����l�T�a��⌄�� �AS�v�����m��b\����T���
~�Iޑ/�/��r���ul@>��	m$�S�Vȅ)���T��Q�r��|�Y)�~��$��:�U�����i"�a惡�L���j(���;<!�S!q��)��̈́�:96;�8ybw�������.��ft
?��[��D�:�L����d��m�Y�����۔b
2���[ب��3�pv%f+¤���%
e�-B6����z�X�.�;�2I�$L�55���,X\z.������B�kK?BQ#~�E�9����7�uHRd�0w�Jmɫ�_�I?��p��QɈ4�o�1�l�V�w"$g�4û_)2�("w+!V���ƀ;��o[�P5%%Yr����-i�f`B+�v�ڙ�z����7�&���*�(��6�{�o[�G�)��'����N[G
|�f������E�����Ǩ��%?��g��2J<������5�M�E��;uGv\��|X�biB?�P$�ewL� f���Jݼ�(3�4�N��c����!�Ûdo�i˝u̼ޝL��Wğ�$X������wzi�v���д5a5�8�J�W�4Q�L`XRe����~!���p�!�iz E�M�Ћ&�G�KM*r=h�F����P�ɜ9L+0}��hsO�����K+���ys.��)+,%��Uu!7G��ïˡ�k8;]���"	$����;8w�����9� �i��y�� -�_gɶJ��3H��D�uK(�DHM�!�2��\-��k���7X>(��	��7,q 7r��EƜ���N�!Š�և��M�JS(m����<d�ޖ;�?�I5���*@�^A�+%�VJ��ƵĹyx:�����y\]�tBi��������ER�/o� �+a�i�h ����i��ML��A[f����_�'P�O�K�5JWՈIeN�e��n���h�D����#�U?Ԧ[�fi���ģH_1�OI�!�����P�$��| �4�7�m�U`�j���o{��P��YT	tb���Z��U�~;/��ƌ$Q������I,���o���Q/��
��t�	\��rT8I״Sq�-�eAM�ʈ40�b&k�,3�+f��]v
��`��3�1�gJvr@Vʆ����Y��?^ �'>�O��Q&r:_���"����j���Ov/��vf�&K$�Q��7���Od㪫 r�"3�-���[p�Ԅ?�b��H�}
� N�\:�-.�3�8� -Ղ�D��?�p�@9����2�
5F@�f�4U��9��$�9g56k}��æQ�����V��I��\�4��~�6���S�~M���|�8Ώ@zv=R7D����������(|��kv��c��hwm���B�1��˻M�<ґbh����p�!���0�:Z4�
b����[�˸4
!�����W�7���s
�%�c�6�eb���_A��rkn��=p>U����ؓe�L�?���w�P��ʮcG'���<�\Nu��P�,�q�.��'�hy�A)!�j���ǿP����>���Sk�E6A�ɹF�e�͜m��m^���ԧ�ʯ ����ԥ4�5��o~r
y2֨pO�57
�4NL��
/-Ί1��^�kA�r�F"z�J�?��e��D�W�(��ݙ��)'t}{��ł΋9�}�FmaD��ɬWf|�i!�F�q�彨mI֚��[G��*z� a�:Y4z�O4���и��eT5�Y�:{��Y�W#�X����L1   � $��7�.7h<E�����<�����ȗb"�aQ�ܑ�GY"�"�*��a�3�1Gh5�z���@(�p QE�k��
}A��؂�&�@2��%k!����rPѶ@�V�5�U �����0�xjAC��Y�EV��d�
��jQ�y!����j�?!� O��G6A��P�A$#K��>�;�U�H<T,���Fr,g��g{���P��䡚�NO�D�lMؽ'�p3����U��~���ڦ-�?��� �������,a�Ͻ�,/�D��8��:y
�[.��bBw�y]��v �/�We�7�Q����en�����i�!�씍FǸ���y�~j+��	$u�E>��ݙ�u��s弒�ʀ��;�'j��FX
I�7��(B`Ѵ"�H�#J�*�c����J�B�[���]c�~ȱCS4��fE�����!u��Qk#/ꤔ�ˋ߽s:� pvq9�Lj^5��Й�������l��cm-�S�?Y|���.�*6�c��k��q�D$�;�gF�.�m��i�۸����P�s�)��;}˄��h�ֳ���W���Ji�CM��5��*fCtA��75ݪ�$:�<y ��v�.��bC��x�0ǁ��إ���W�_�%������9=�?>��;�,�Km���P_b>�>Zi�S�i�A��TD�)�
�0�1JBv�:Xq�M^����UXZ��ݰX��32K�)J������V�C+�b�y3���T����ǃ������V���7�.���YV�����"4d{tR�O�^p��w@�X]׸���הB|}l�3�n`R	M��jI�f*#g*c������1��lZ��o�g�&B|�3�y�BG��
͈r��ƛ��CY��
;}��L��$�4�'Yоҹ�}�oޗ�h�;J�Bg�Qi4�Τ�1N��&�)��I�ί`E ��D_k� �Kna�眆���q�NS��C�π�C������u����e�pTMȣ~}(=�+>9x�Ԟ��-�np�-��B��v6?�M�0aH���i9��9a���k�=��$@��@M�v1��\e�M'����mwGH�צ<�PJS�!�%ĵ�
(��UO�Kx�C�yl�Y� ���6:�}��L5;���XƮ圍��@�֐v��uDA~Z{�Wp;.���ݷ�x���LF�±�5��>si�E����Ze�N��q���Y��H�Ѓ������ڶ�P\�e�\>�c�+�c�ꃗX���A�F%fCx!A����M`�Mtyp���˦n�j�M��\q�2�?���7��A�C���K��U�-�9U(�ת����a���D�`������,;�_,LØ]��%���O@���[uÁOˑ�%7&7� �N��-�,��2Z��KJ�-��On~��j4�ڏ~??Kn��>	��?Ȗ~�����/?06�-�;~|����B�	b�	��e�a�4������,7��d��_Ñ@�w���T�x3�ȶ�d�'��jk}뽒nPP���ؑx�!�9�u��Pս���h���~��t��7���k�� C�R�١eQ����I<�u�C��m��P��&` r��`=�,p�}���;D)��K�28�f�À3��|���k�)I��A1n	�Leºl��2�c+a��
���^ma��<�1*)�Y�%_��_�.P�2V�R�o�+��u���O2�R��>�\$;�����^h�+;O\1`�Fm�ؙS���Ójh��=\�o�����̤���O�Lm�V�s81A8sl�F�"�"O@�r� �0O�$6� ��,Q�u!�e:�(���i�PzP�E��y#���)d�`A
Wl����pO��1�m��dXt�cJ�~�;�����#�5@��my�
4u�ҏ�-#�Vk�Ú ��V�h�\�j�<cE[�߂� ��' �uC�a)"�2��.��Wmy*������H��;�U2R; ��#��t
:Wd/p�)PY�h�;Ix"Cmc>�&��t�r�k�cND�UB�4_߶:�&?[k����0�{t�+n��`ӱA�Q�s�6B��Z%�|{T��
����HfT�$��8��9.2���$͉�`���!#`�1Tin������D�lm	��ԗ�{�O��?��lj�K͇���.�����o��Ln��^W�4>�����C�kb8�m#��N�����il�4#����љ�*�:�"(��`n&�v��#��,���jP0*�Z��E\�3j�+ �'i����;�d�\��׏2k� ��������d�>��s���В�\%�q��'g U瞨W�.~7�>")T,(pGL����v�=a���m7���'�Hmh2#c�w�o���D�Lv��>�(�����!6iZ��R{�����/4m���Q��]V2}����_�j�o E��?�����R��z�!j��!��D={�1�!��k;ڡ�ټ(�w�[�Q������?��a����Q9t9��ܙU�wvc3�}���u�D���O�tOH�ɍX���z�Ƽ�����5�vD��*����6���U�P_�+�*��_?鈨��^q�ݞ8�w4Kӱeb��c	N��n���^&m@Fu;Y����9�9L%��Q����z������`șPQ�H�12�A.����1������;X^�����Gvdq[O!�{�z)�㵉r��WFyg��d�9Z�#g9G�Q�[7������i|�&va?�ňP��aC�lej9���O�~��;7�h��Pm%#˨�nZ�+Wz���I�P$�4�X4ώw%Ϲ�%[�1���KDv�T�����k/r�Y���J���lhY����d��!�:S켚�����s'DO$���F��!��6����������
�r����E�Is(������n�p&�$v��zT	ڽ߶lƷ�3��|��J�@����.`F=�	/jT#���"6d���R+I�e7_�m�΍r��x dWX5�W6�`	WVuy�i9���D��!��*0C�]#@\oA����~�R��=@Y=�_O��w�AU�H�V�Z#��`^@�ŴHM�aj�y�]
�H��b�H]\,���h��+_���?9�6������iaN����oj'a��|b���a�8P�}�=yo��P���e�0���e�m���JeX�舿X&[=[�-��v��kG�ޒ�A�qD�C:jp��$K�Q}�&�ܘ~�m��*2�������w嬇AC�z���� iˬ.ѩ�K>�����u�Z_@8r�YM���R$t�_ߗ�~���Q�l�`��{���`�������r%S�`z������	��R.B�}�C� }���ц���$�!�ݮ�#edRe��#_J��֙���a�d�@�0�f��_���'�4otg��jڔ��X��V��i���b�;�kci����`jm�VJ>E�M)��D�p�pUwº��>q��o���9��i�0<c4`�����0e�U����x���sh���.�#�� 0��h�s�`����[��I��VU�P[�4u��~���䞞��D� ���x�k.H5�V�I�i�_8�'Vm����[�nU�}������)��4�o�5L�bfu�ы]� U�JA��7��=ՠ�&)��Ĥ<V���+����.���?�����k�%����
�X'f��x�L	�mo�3��$J��|�� F��������"��d��60��^��7�w�e��04?E�^���D��ē)��(6 ����_�.
=�
$ߍ�I�a���Ҧ�����������{Zr��b��r�a��s�-q�����@b�򄬺KG�����7aCG�T(!�T����?�6�B���
)���QU��HH_����4�����aE�n6@奁P��q��`����%��u*���]����x�9oy���G�S�w��s���)#@P�������bU�\����e)���G����4q%5���y��>�1������mv����xm!n��ɵ!�k��\O/Iw�my~E��V	-�-��!]	e�P'�����M���"�G߱�=�%�oQ�y<�m��{����I�5��Q�}n�����w����U���Zӭ���]p*N�:,�u���F�y�;c�
b�.���S�[U��I�*B~$ڜs�*��n������V����b���?��pJ��j�uI�qʫ[1��!�Sx��~g��o�@���É����Oa�Ǣ���q6U�m�,�#�o�.}S����%P���B𦬢Nвy���Oiǫ�T�C]s;z3�?v0B��ڊ�u0�C�7�&:�qsӺ�|�S:���e����]� [���փQ���n�נ{���w��qI*P�E ���{�+Y o�?�ބ��XL�BS�9`��h8�p�h/�L���$�ػ΢^�>md�'��Ce��t%6�;�o��I���p��,��>�|dK�.�� �`p�Mz�Ey}E�M�G*z}�}��6�IQ� ���kk��z���8S���VE�lV�+\�Z�����A;菛�F`W<�ZL��z\���j%���c���ho���W��+�5',��`o)V]�։μ{�n��M̃H��}�$����ψ:�z��=�DQ�v�6$P���M 1�5ɫ���������k�ڧ>>",E�f�Կ��\R�2
��v㰰�+
f���{O�Rj��S�� �૪ݪ��\���*��XmD�v��2��f&^���C	�=��?s����1J?2��-�v3^N�W�@��@�t�AS���:���+��y��Bu.�|�OՃ�Zl$��;T0"�F{�8�)�#����X{��ǲvaS+���O�.�qG|2Ph�չ;@��-O?���u*��9[�&m��{ åAV�S�y�᷁�\��{��=v&���e��IZg,��d\�C*ح@n���.8�,����8��6M�;���)lQU�j���Z�;�i��GnO��0#E`I²t8��ѻ��
�R3�:O�*�YP/�n�h:�)��-p�J1q�0��t8����0���nZ'қ�����Z�����d%�y+�����~���g��0�v�T��@�S:��
�~oXy��YJ�Xbgs���)�Ϊ��3f'~q�1�?L���d ��,Up�Ew��<Q��@q`T��+��%Q��������"/�BO(�ch!�
H�a`�50�^�zi�f����m$N'��8� q�_���lh�%��^�A@���fm�%�5��z�y$:n����B�:O���P�j^%N h�苕p�z�q'�6�wf	�7@�kl�
�!��]s�3e�ـ2�S1"}�Q��@�c�v.�߬v^T@1d�]���'�n���C"�"��uz�����Z�� �|�9��z�$�;o�3�h�u,��U���]��>R��C揞��:�!���&�ѷ�Q��t��}��#�b������'B����X���h�Ċ	<�%'�g��O�f)HqZg���蛻<���Pzs��Yb�˕p�����=:�#<DfV����5��,��l���@�_Oe��g�4X�#�훏�?K����z���زpZ�5e�w�����k�6�{
��EL��Gɴ(>G�u���]OC�E��o��XϏ�߾-�H���U��!&L׳3	�+_-WBЄƕ ��7a~	�k�=É�@;�b@$��?#����� %�^R�3�<���і��m�.���![���F����8l�t�����2��QGO[���W߅yh%���[�'�0�O��QD�����g��.c��Ц�F��G��[mN�� ��MM&���2nQ��T����5��(m�UNLe�Y����o��f�k�0~���p=g�����̘��+r��P�Y1�^+����i ~�0S�vlZh��"U�%Enc͒���^E��t0�_��G���N��*=��H���>��w"�w��Zd7��b��WX�J�V�S���ï��ɐ�J�c����!+�?N��Qp��'�"�jMq��s����tk��)6�_��?�nS�t�%�2�}�R�&���%}x�%)��*k���)kb3��i$[�o��_�6�(�g�НbB�ݜ)�t'Kd��(�8���j������S=�H.��j�+��=��ۋ������X)���[%S��������?[��\�\�1�h![X������4��l�D �h��Ss�����̂䜫,Ww���=�V�/�̿<�X5PnS\��O9*w�ȗB���a�>o��o����6q7��/�����D�>WKE�,>G�V ���"O����ֳ)��.9��͞C���j7��nߪt�|���4u+��Ř���jʭ�����Y:a �)�7ͬa����-ѽ�i�w�,(>`��qH�i������Mn Ě��V����@�N�-N�Cs[c�Z���Y�����aJ#XP���'��xꃢΓy��c,��uӍ�wC!�)��Z�
lNu2n�C��?�M��L��'���Ť��blqi�?f��rm��x_������v��o��=��ҥxG�x?f��~�J{8 ga?���	�A@o���]���g;$8�᧡#S(G#z�w�*��j4���Pp�
���^���`���5iTUu�+>��T��M\�%�)#��V~����U�Ȭm[i瓋�ܵ���i;p�^�7d�5�L�B����#�����eq�;�������h1%^>�~��i\)�_M</2�B�_��JN|\���Lf,}~�+`�s�6����R�����zN�H�ҏbLbĳ)�՟����ET��.v������e>Fw��t�A&`i����k���T�z�xU/aƟ�D:�T�������k�{���߽��:��LZ�צ�8E ie���z�mt�!��_�V%��~�B�SL���s(P�M��e<�YP�^h�|ɉ�ϧ
&�m�Ңw�*Y5W&r�-jxp�Qy�kB��I^�)��?*����bN~�ar5M�K2ud�ש��9����5����g�)�H���,���8�� �*KzI�Y��}8ͤ���d;/r��M87�� ��^� ���@��qX���������wLf���^g�0w������X��\������F8v��$�;	d[��HV;�wc�A���\(�����Cr�]����`TH*�,�/dW� ko[�LD�B�l��7���PP&u�qi�c70�B
���A!rǮ��h$�SѼ���M)��9\�A���V!l)`�Z�[98����>=�N��z���4���!���?l����@�c�D�}�(�B*���U &|���6�x&����.j��`��B�L��s��R�����ze&5���Â2��,���ƒ�gs�ۑ���v�8���˴��(��i��-/��3?w���)�꟬V�(����A���*�N7��E���8Y�!a�H���JQ��6l�G�R1�P��K^��7��0W����W�ޞ�)��J��^`C"~�i���CS��y>��nڂ�%wl��Q2M��lH�1-9���q� ��y�CF��B'D��0�7��K�GG�i@�������va��l穩�Qs�o�4�\�����*�ٌ\}�$� �Yl��yD�����8:��1Õ
�S�^���w�[���O�R�vň��Oq<VB]\��P��bPpR���e�|�+
����P&y"X�{�E��3�]G��,��5%�����Q���),�I�����L�M�Ƕ9V�BI�Ox"��= ��$��'5B@����(��~ic,#`�{���O5��=F�&�T4��B*�K��Xh v�|�j�	���mk�u9�����͠$X��ex�KE��!6
w̋�n�E�q�������jqȁ����dF1錵>���0�I��M���ԁ��Fcr�-��"l%@Vd�ۘ�Ŷ�`�`��� !nW.��*�|�a��U��u�j�����h�w�tzt�@�}��B�wz7y���aSJ+��?�$��4�Wig�&&
R*B�k��Ԝk��]���{"p�59�8P ��9��[���N1[�A��y��e�{ܞ�<֚C�6�i?��*B'ł�a�����󴐗�&�:z㚱��K���S�G��P@k����-� ձwp���1���s�`Q~e��QM��D�Q�6�շk�|ΰ�������蹢���p�1�D�;�s1s���J2t�|��f ��D��+�o	��"-a$q׭�� V��,G������gz?{���L�᳞�;L!��9:���/+f���#�M5VD�C�TSb����ej^�Ay�M�L�Kt����e��zS�	[O%ҝ6�������"ݱ�A|o��0�s ��1O�`�!��ʊzkmӥwg&��MP������I�C���(|6�50�Wn�҇#����g9���N����*�<O@ b'H��0�Kj���N�z)5:'^���Y�h"FN9T��� 
wɦ�Q[�ӊ�H��7�X��17��ʮ��{���.��:e��!��XU�"��1X��[���څuzFC5x����4F�{'���:���ܘ/�ٸ�~��&��T�;�Z��B�L��}��@�cd8ϰcқ?r���~�����m6l*tb��`�$v���b�"�^�!&�����:�����GZ�e��k��3/�	�V6��p�]�W5��4��v�[��-��:� {q�yC>�������ߴ#�J/,�d6R�����ߑm]�K@Z��4���M�`f�{�ķ �o��O5o��6
,�Lww~ʛB,_�����J\���1����w���[X5����5�4��u�&�d�� [��oکna���K�BK|f/	g�rM��\��άH�ja�F��)��[<Y���(�s�'�����@e�u����QOs�M}�n�'��1��R�>J�h
�i~�݌B���}a9�u�!�Nb B�W�a����w�e	d�J3��yۈ�L8fY�(�����k��+���4 |&r|���A����Ĳ�Ժ]����C�_Z�W4l�����ܠ�h�l�4@�eo���~�Yq��g<ў��E�aV����r^��'U�����������t���mA�D/Ź9�y⯧>�b�?R[T���c���v� %��r��c6�NIn�����S��)�~1��O�d�w-zΟ��[q"�U��j1����%�D���+�	�%g١�F	2�`�z��r�L
�bB��s���Fill����H������B�$��?TFQy�3�5��4fO}����r��K�~��=D^נ��r�4�%ܰ��N��R+�(�Fz Z����UJ��I��<Z�m��YP�aUS?�,�pՋ�D
���%���9�A��uLj��Ò�8�g;��7���7(cƸ#��!���Y��!�!)={����;5�ԣnK@���4p�4y���(�״�9>�z������Ln����m�u��1�i�_���c9/������f-% �J��gZ$�`��Lq[���>���mσ�w0U����y�JY�-`[�!c="��r6Ƀx�̋~��bEcS���䊄�W0Es�b{c˵��JF��6�U����ٹw��n�)`u+��~�n:�I�f�zՉ���u���T�����\Y���5�mx�m#���=��f!ń�q2��ͤ�q@��s��<�'s`�T,3)b2)|�:�j��g`&8PüxX�3�4������b����`]�*�}��BT̴L�Z~�A�����r�- +�s&�l&[(D�@�Οs��k]�-m����k�]�<G/�<<��8�p�,b� �� J���lJ{�0����f[C4���Z�5co���ێ�W���N�C�(� ��ꔩ ���j��&Zl��MBK�u�����O���Ō��aئ�iE��&��fb�1 _��(m`���X ��(�	W����*�:9�|2����C�/��Ӻ�2�M�gE|7
�E���.E'mT<襃4�Q�I��R ���l-��_��o~�%�M�V�6��!���%YuԒ�6�&�����Ŷ3o�M-�K����#�cY�l���$���lF�S�,:�u�����S|��b����c���#� p9p|@�M�99����
�PL���ʮ3c+��?���')@E�HO_DMO���0`[���Y7H.V��wqi#���.�.?ƺK^�b9�Ew�d��xb�-I�;��+���bk ~�D������ͧ�ے7�(CG��D8�M]���ӽF�|�9�Et��+L&�#W��v��l��X� ;��Oom<��J�cHM�,����G�Ͳb)Q�1)�r�j
��wR�$�L�y�-�/)D`��X��'_��.\�i��%O�gA��g�oخ���� 6xM��ڹ[�a'��^�{
>�[��I�g_�dW,�&-K��^�ĵ(麴�',��_YKE����8PA<�a�4 ���!�����������a����`Y�D1��A쌬*菓���9��=���8��+�����v�Dv�L�R��;������K�`���W��^hcQ���*�%y.J�h\7S'9���*���΃\�1]�Dl&/�v�O���t���{ha�-��_R�Qn�{qOC_D���
 �� s$�h��ks1��[��ܭ�g:�d�|��XF{I�k;̤�G���X�j/�߂��̎?��'!sėHj��U@�;X5��<��d�[����W����O�.��N rAط7�#R���BaT�F3׻�!r�9�tx[U��WR��λX5)&jՠ���-a��V ��A[4t���,δxח	ϵV\'}�z%·nac@95��U"r���Ur����j�37�!�خ2��$�Jtr�d�mT�
�qЋ��̌~\��f   ���`�# ����V�d��g�    YZ