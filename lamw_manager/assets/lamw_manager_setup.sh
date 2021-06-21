#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2417919484"
MD5="3efc8ac2be276f7ab890ab2446f300ea"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22940"
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
	echo Date of packaging: Sun Jun 20 22:41:54 -03 2021
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
�7zXZ  �ִF !   �X����YY] �}��1Dd]����P�t�D�r��M��0��C� �X���F�-w��@�8�TZI��&�[yg�ª:���:+vF�`�߽���j����I;��,f��3��P�R�&�H���R��y	ſL��L�5P:���c�<i��W�CH�o~���Qr@�����LJV�>�D��is��<,k�� ���j�Wq�,����ao��!���|,O�V�\���Տ�Cx��'ᯝ��ϟ��	: ^�_YǂCl����O�V�������$���!X�כZ��1�[kE5�X��+��["3�2<�1��q�2f� ���Ü�@!�e�\u4_&Qd�EN���%}��{`�s����88�۲����+E�L��sq��4�s �}"+v�ò��"�1"K9�Y���]9�SPm)7BR}{jˬf˗��&��v�"X���u�N��˺����|!W�C'�C+�t�����^��	O���]|pZ�;��SyQ$!\���a���-�Oc,}KN���
w�J�V�Z%CԌ�]����K���&�M�]W+tɷʜ���H�@��s:WVNB�������5��=Wa�:w��P���yy��N�"�M����@���6xp��D�rOR�����wf#*�;�<�K&$���F�|+ ��R�\�?����MO䞱��q�!�эY���bwY9|�r ��`����������e�A���(��.󝲺#yծ��XJ�g0�S������o� $�Ƭ�3n,��j��7��%�Ȳ[nm؎�����l��S���q�<y�  �+�4B�s1���۰��ɿ�YI�8�O�JyQ��2��7��hP����{�F���F�+����je��_2Ȇ�i�Bٷ����;w�r�B}(M�T���Q8y�$��Jt1��Čg��:��{����=��p��Fe�3SԦivą�'o���O�6�0G+��v�5ޟ�ML=��q6�"�L${��-�#����E�<!��Vqh���u�ɍ��p�2:CY�-��HA@����8䇵���P`s�w�.�\I炾�8���f�';�%�;&Ԅ���vX5�.��Ec����+�۟k�.����5]�z  �8Bޱ������ٸ�b�'��/�#Iܿ���.et�ׅ6�$OrnٻEt2i=+9-��� ��ܱ�Bѵ#'���s�H*�]�د�ݔ���gk��؀nt�;���Tj��T���H��6��?��k�}A/��^9��'��}�5a+LA��}���զp�<f��eVIL���3�'sN����L�3� ��]��-H��}���$1�k���0�C\�J��y��$�k����*��[u٫D/�7VΪ
y���$����V^\0D��H �g���4,����R@4��t��&h�(V�\f�UA}K���z����ոF��8&��r��&���=�ǻ9f#�\��[��Ƞ��܍j��S�>@�yWJ^K¤/�XC�y��ƃ�Y�>��``���UYݍ� ����	!�Y"o�Y���U¯���增��yeV>�{��]�e��N���&����>h�ՀD�3��'���dO���E�]\ �W�=��v-BU�Zu��$ �j��3pn7�yNѼ�����< e*B��?HU��J ?��M7�g!u������ы�-�:�ACy�+�xW�U��_\ �%@/��Pp�E��>����₞o�I>���\B���7��֝k�I=r����~uŨ�ҭu�!ޖ�g�eg���<�8�r��i(�׼A���z�@Dc*�aև"���B� ^��%��^��� �J�o,��3S}WP!#$U���6���۬<m�df #�!��Ba�D��cBf{W`r��������������rNV@��f�\�Pl�S�5*6�r
#��mw�/�9|����R��b p[Al�S��j�@]eY�E?`�eg�e����S��p��jN���5��o��Źr�W,M�Y;�»c[J.9tS��5)7|'�ec�Z|��z;�l��D�w�ф��¯�-c!��	рl3���z�;���R�nP�ʩ	���cq��	�CZ o?�h�r���N��m�H��5���^2l�Q�M�]׾�a�J��d\�����"�Gy����c3$.pmJ5�3�+M=�	
;�[jgܥ@�y�5 z'k�邤V�_%>6$L��X� ����&Əm�{ ��[l��	����-4=��ƵIxQ��-��0I��R����րQ�^���&G�j����#,�CNe���x�\��
���ƨ�l����<uֹVP���"(۾���������sޝ��qd��VXˑ|�6=qG�!��(� �Q���ڕ�m>���o#a��1��:N ��d^�٘2?R'n<��5��n:&�|�<M�9Xi��:4 a�t�;J̒č�/�65���*�j[~t}���l�~�&�Af�*���89��߃�a`B���Uuh@��;�ȣ����+r;6w^��RP*����,�Wo�]Ǐ*���� �
l�� C}�E-��q�K&{��Y�+����Uo����kM�n5:�@�b��[�<4j͍�S�8䩆Or��i�`r�Rk;���$_��sI�s�l7s8A�qt.JAgO1��^���PPM�I��O�Q�C�[����\Hߓ���VY#�0�(ۗ{�{R�*-�0ѵj=�5@<s�q��B���K_�o�d�|5���띟�.�y`�0�cn1j�����u;Ǌ���3#�ṶW�ߗ��T�IJD&�;���K֠B:��mq���rR^9�mk^�Bu��P�t���"�D]S�_�P)%�Z�)_��� nڝ��Wf�Ӈ�+Œ �'��Ĉ��ϸ��4gi(��	��>9⹲�X���0:��6s��D�@�J��^"�8��O�/����p\p���e���l�C�l�Ǐ.(Y�7�4tY���;���v�.#E���i��P�n|QLd���LD�����xN �]��?�S���e"H����.��N��N��Hp��wƟ\��^�O~0q��j�v\�w����s��V��9Sb�
?+A���n쵙B�zH�W�����g��Pa^�lz�o)�HG$��I�,�~m@wyP�y�Mo�&�G�p;����/��c���>B^���(Ԫʹh̚�T�Y�3�>_(&-�! |NY�$�xb�, �������V`j�t.n���*�y�`���� Y���pBp�����'o�Za��H~4��VM�6���=[n�W(��x|b)ܮs�Ш��L��3�P���D+�����H<�/�d��,ȫ;n���"�WfhQ����r������\s�"�x�+N�d��F�Q�=��~�8����'�4=�/����$�!z�}��ޱ�0fQ��x��J@1ѳ�j��y�Z�\k;�+f������Q����>�)�cBG�ϱ�s�j��6LC�����A����Ho�}4��6�X�Ax0�L���e�A�����q�%{`_��0�M���K�ei5�X~�=Y�����n�ܞDt������W���ä��q�0>��*$��V���Gg��*����J�cb���c:�-DS�?�YFk��h�{H�Ba �y����*h�i�A|,�i>��kNn��-k��6��r�8��<9�x���O日��4d6Κ7��iLo��S���Q�G>�G�xw�3���!$w+:?�!T������i��Np��ė�Q�x�g~-3��X���Ɂ_ya�Ϟ�ۮ����_��¼PȎ��U6:�{���i;	��� pj{�X��oS0��r�����Bp�P��ȩ�-m�'�'�]e�>}�Z�4:R�k �Y�	U��S~����-�?*�Xt�)gB�����Nu��Wgj���4|[��$Ԏ�Q����eX��n�kF�W�3�Ÿ�аf�t��2�$M<4uf�j�d	��Z��r�+�/��&a�ˊ��G˿��e��^�|,⅍څ�*�S�GΫQ4�4f��=�\R�JL=T�6�۱W�9ec�B8��[����Wj0�qc��q��\畬���u����a�8
�VB<\�^����d���T�x4*:G�_��`��H�c�[�����[������9( +��Q\��{*���"� ������<��J��1n�� IA鹉���Z�q�BK�S~�5����߾t���_���A��.���D�綹�xʎ�?�T%]i�JJ�]O� ����rW~g��KN9,�L�L�nJ:7�Q6-��_��ץ����e;ja�� �{Q�2�w&K��Ԉ>J(�#������@$��uVُ�3�g\}�#�D��� �AT��th��cOY��׎N�r顽4�/3�vAq�H��CB��g�d�fI��HC����7Sf��9��:F�n}��x�H���Sѥ��p�H:S2��ڑ���V��2�<a��_c
�eɚ���\��:�>(g_-P|W4�\�2F��z�e]W�	Kn	K�ca���dgD���7������|�D�{�$�ws��w��_	H�A��=G��K���޹(�A��ت�B�UT���訬m���Ԉw�t��Hѡ?}���+<�����/���1��%i���E&�N�[|`bp�ұAl��>����6İ�twA>�s]�n����*,��=]��ۄ�{�� �֢���]� ;�a�=ށ�-N��q�@]��E�[�|4�-y��F��Ӌ@��&��HmC��w�#O&&]��K���N��{�L��ݦ��7��B�}a�q�F�|\�Ol����W�"���S�7��
0�o��7�Ɓs��iS�t;X�y����_W��7�s^F*�ѯ�p�J!���L	ab�"V�����oz�z���iFѭj3�q���Z��
�97@~,nAu0,1sߦ�z����P����{zn��b&�PO����H�`������`HDH�5������G~;
�b�4o��V������ϫ��b�m�h¿��R��P8q	]���K�xj��7��[�t4�훈������;�#�պ�W<�K���8�3��,�xf:�*lن�<�*Y큅�F-�@����{W���U��=E���t��4"��k ���,� fCE!Ձ��trh~��m��
ItHW��%����쟊����մ*)R��
�|�o����Uy�{]@`3�/%�9�A~�\K-��ڗUnP�I9�F�q�p�ޅ�>n��[u��j�fG��E=�ϭ�^�U�U���V�#�'�0�F[������hey@v������f��|���c��~<[�	� R�PbN�h�D]�%�#LWeà��u+�?%x���E:�v(?�#|��rx��7�����Yސ��"� 0>�������}g���V=U<ay�g�,'U=�q����@���+8%@���Ѥ]ّ�ߟ:vh�������6�yxL'"��$�8�~����d��K�:��Z�h�9�vT"1��`���s�tN0й��{Z���������z�a�$�3��+�w	�θ3`����Ց	=m
X�~$eȯvFÅ�Ժ	�MB��^���4���lN����=��_wf)wVm�Aj���VS߻@�'8��#n�@tal��= ñN��L��b]�"�{�����@���ˍȗ�7�vcE�`TAy�m�H+lo����A��E4t�*�[us5j� <�����#ױo�2F�
�Q0�N�l~:`�g��@����KP"}~!"N��T�\h�\ hh�%��p#���0����l��z�5
x.�Jw��Bw�|f;��dVY]��o��L�L0A���H6 J��GD�h�t���a��i�!��{� �Ra�\+����i3�����5at�#��P�����N����f�.S{L^�(�9t'�}l/���a��5[J6�^C��^3�?��E�5O/�E�F�Q�f�d����*!sb�q+��lD�H"Mn��AV����K��3�	�Z��,,_ivF~Q(3Ⱥx�6d��Q�5	㮻�����-�7�����I5M�L��ݰ��1�]0��5=�J��*3���z+8KA�c�LĆ�T���>�*S$�pr�_)�C ����u�P��m|�ul���= ]��{Q����_��~���T4��V�_��f/z����M�=�a�`i���n}!�"�x��0G�Z��*�c�B��!뤍��r��P�FÇ��� C����W�����Ċ{9I��i�A �E[S��l��X�B҆Ա�t�OgS��i���
0%�����Qkh�OT�&�ϯ���)�.׬�J�y�s(oy J8�q����!F��˞�|�Jj'QteW6��Y�m����,E,$AV�wJ��y����
-d��3[�6�~5d�D����J�.{bᰳ`��A�����
����'�Y�M�R�-.����Vk�0�E9��qO�s������fk���X[U�-N!�j�en�\T �g��	�f�QzQ���䮱��s`ve)r����b��D7i�x�$��f�Z�ϣ7�r&EQ�D���!ӈWP 1�r�m�?]$�������t��P9T�:�Gr=��Q�N��.P��zL��;��?���j�gUG�![p�Q�n�avj{.�^G#S�lL�~�=n`:&c۸JvI�>R�^}Ec�����m.�)#�g��b�}���y�ñ����ŝ�.GpA��0���kbs6��o
��~�ݠ<�|�O)�6�7��|����_n*�W�=�k �}�h[kt|��F�~G�|��V��k�5�1Y4�ʰ�N�85j�>�{
?6u�u����26g_+u�z�I�F>�Q��[9��6�Pf,���9G����w�>zi��ɣ�-�\`��\��v��B��w|C%���q��񤲏�`����yHS��/U^��dB�l�Q�4�#�JR�ʭ%&\EAĩ�:�.z]�0R:�&��؋9�/���aC*� M�z
����1\��`��"$-"��V9��@�⁏�A\9u�lMy�_۵�d�۩��h?Dw���������3X¢�9.K,F�m�f��{2�6��߄,Κ�ȟ`����飯�X�2ԗ+��#-f:\4�v�1�� n��Fg�~1 �� X�v>###e����k߾��5Z���[����D�I��W>q$�\>b��;�5@*M���F�¿�Ņ����i�/2S�06����ǏMH蔅�&"�,E������Y:4�Fޛм�ZB��pKF/�?�5�)Hh�5���Mh�@[@�V<��v\��1ϓ��:m�"�T-��O�R��BD�n}.`6.��n^:]�|�%D�C����ߺo��Px�$fq!�������^v����܁���DJЩ6�t��Tˎy�ԕF������+/qE������u�����Ҧ~�e4r�fM.��{�5��SI��M�2�n[)d��m�i`�YbM�~V�ꑢD��i�G�ᑧ{(r�|DU����&4U�����i{2�1h)���*��R�rxQ��DL�����ֽ\����f��o��8ʚB�͓͙� �[��b#�c̆��1)hhC�#�n��D�bKo���Xm����$p�Q;�3ޑi���&`>.�lH�bH~|�[Ջ�̨�!�� ���u-��_�tPh���]�,X��ŕ1��^H�z�2�+ꇭ(���	K��Ց��p��߹�jڄ���v��c��c(銝S�ݢ�Л$�`���d����
��/�5�E�>�s[��_pq��F��٨���$���j���u�2oF
=~-���V�q3ݚ�G�-�Q�L�Z��ͱ�$�,�,;��c2�S���0�y��Y�i��[�G�8'���(�Q��e�}�f���Et�C�u����|�8�r�b���^�C׫�N�-�`�z�E.�K�ɑ�f����K��!C�r�|D2!ӗ{ Sʩw-(��$��U���nTC��F����������&�_sT�����qd?�F�ȇB-ή#�{>��l��WߎDa�|Y�����?�U� �hq,��2���eE�d���m�<Ī���׼�S6� �"\��&I�e^M )堩`�3���+�g0�V���.�����E>���PZ��G��g�u���)HV"�?�'��N�p��JP�#�$��4��!��a�=�"�f�fP9���<�SFK'B�}ՀT�����b5��� 8I�5Rݖ�\C�lԢr�吏��ݻ��%8�h��1���b��ܘ�����"�A������\�X���/�4N��1�g��m��}�⯜�:df/?�e\*`��]�G�)S��"D;�� �|Y��es���*�Qb�k�Ca��w��M���Ʈ�ܪ�ޕ&`�Js��0����N�i���υ0�y�8�;��~��!�{�*3�����{�8^A8\hս��5׶�L�lL�L>m�xÀzy�f���D�OG���F󽙬6�B��)%������3ķ����zUy��S�8p���>���x�"�O虖�"�YAV���O}��ۜ�4�dB����Z��&0��|^�R���WfPq��gbezTST������N��EZ�&x�Z�x2�A��;���R�١���_�`�����
I�'����K=��©�o���������$�{�қ�W��h�(��%ui\�HA@1��Vh<�
lZ�C��v�)��H�%�ũ)o��7|F��P��#c���D�R�i �J(
�����k#��𾫳W�.X�H��U�p���s�u�#�r����ԥ&��0�f��{��g�ś��!"9��ĺ���TVZ�O�����MW�N��
+���\���(������2�6��F|��Ǟ&fb�^�0���] `�;p���`�z'�����J��%�{����x>��/�e.���s0,%�U6�-��	���s�eǒ��V�[|���������D`��毶�\覛���S%Z<\���ꐚ���Y,E�.���<-UB`�}�#�{�
���++ Ҹ�����>[���OH��-�l���h�c�$��|r�����<k1p{j8����=��ۡ�����_i��y�U����tH�(1��B���ȇ\�f�D�5*���q���}=�9��V��P�kds@Ӛ�#���� #&R�$�J��Q`���HAsN�Z�ߚ��kkS5̍�:!�z�M�,v}x�K��,�A��6TN���-��~������g��\��d� S���r".�Ԇ�?�O��k"�PӁ�,a��E5pQ�8_��N��罭�e:T���q8tld�M�Ɍ���i1b[j6�~g;�kyg>hr�:�-nkzL~#X�v��ޅ{*\� @'Fdξ���l/x}�6�'vM����0&lQ��=��dkN�Yi�<��|�lp}�B=	�������3�͇���ڹ5e���f�u�"�����f09���1��֥˨èD;=A�M��7�a<�%�7�� iŦ��NťT�%y�'~��s��`P���<9<��R�R] :>%��� `��BM"$<�G�"�dQ�s���߃�O�k�*Z-�Ҳ��al<b`/
��" -	��ě>k"&F�T�-|���bW�2����95��'�r֠�e�1f�<��v����(�BbF������/;�n�zI��[�����$p}L�\�,��f�}�?$��6؃�:ڦ�C�9L6�5��|%8�(}S ��K���Z� ��u�T���pi���>�̌ڟ�D�2g��@���T4��s�����g�|a]'�vjb��_����@��멫x�#�@�w���Eu>t	 ���Gp�=8�Z粩��YD�L��,�?k�[�;���0���2�U��+3WM�9X�C[@E9bva@u���&#�K��|��O�(`�ڞ�0���Yo��?����7c�-@hG����7� �&�vB(�a�Z���h�QC�hK�z*(���-O9a����B]��Lm	x<)����}��0���*m5Tռ��5�QrK������R��|�i2y��a�X�T�Ra�<�C�㍨�Y�5�����Y}��IG>g7���e�&otH��o���Vl�K��2EC��R���6뉶ւJe�j�N�������	��z�(�qo>Z䥀Q�HFkP!�,<�M͉TȾA8�)}��:/7Ӎ��yt��*�q��!��(t��?Si�m��6��a�|�OA��/Z��>N*��L���;j�}�z���m��E����D�ڐJo��g[���@#e���鵾X=�Jcw\3�c?ԟ�H�_��H�$�^�/�P�<���;F)�O�b�*Ƀ�Zl�]�x.�Bf�B�4c�A!�䝛�E+Ū�~e�Mhɴ?��=:7��q�pJ���+��c�7��;!�:�g��t__��c	���(uۻנl\.��Gd$�T�O��-��u �4���Da*�!
[FM<��	�m��k����uY��,�a�����P�a�LCT��v-�����,7�WJv�CA��tw!���H89ς��$I���{&�j�ߣqS���Z��[�רh��Қ8E�1�m��ND9����y�>vX�O��<���X�՚��lV{eU��ؒ�/,Gc���#��V�<A�a�\��7W�A:�6I��o�BiR2D�$5�i����Ӥ3C;�h>O=��͚��-}Dn7EQ�("� �;�w��;�\��{��/����W�e[�u�8|ćh����yfoM��������&%�L�f���h
�0j@��Q;���	�f�E��Ы�&9U��pgC��
�&�Q��o\1��/��:G32����a�|iwߐ^�l������5sy����^�R���9�y:���lZ��4�"���0�L���ư��9�x�z]�.v%�P��p5�Ens���5�
b�*2��:֒��AFt�F��5_VLi@;��ܨ��TÀͅ�uP<�_Jrf��&(���,OX�$LI�(S��X�>�0Z��Q�z!��$p���z����&�"�+w��	j6>��	1U�u�[q(Rht�=��矙7�Gu�f�+*5�;F�U$�jT>�)V_���?CV�ʊB�N�����3�q�ﭩ �V���j^�[��u�����%���O[�B�r?�PcJ���J=�r�0���Sw�䢍�M�a0d�)�	(Diw�I,
\-��=�����
Q,7�a'��T�j���=H��;�o����tE��a�t�q0�>�����G�f��ۓY�N�w�']t��p�}O�SQ����.3�H pe�Z�H;҃�(�|��X�����+�`�
�j�2|�}��1�"C���`;�tä[�M)�7��)��W���1jI�G\�hG*W�2�4t����qg�{aK�ȿ�Տ�����Gʏ�e��5ݶ^���R�+;���y����D�@J���1��bެ�X։�l/͒�2%d&Z��o��X�Y��6�H�_����|�2x|i�O�`!�v/P��4:ȵ/hՑ�Z) \̀5�%�5>{5@� o�H{�`���ܚR�8#�NN������wx����'��8�q���K*�A�ZnrX��(�U�7A�co�e���t�*G�j�Z��'�v�4�}tG0qCrm���B��3ݘ���-}{9qD�a��B,u7���n�/|�/��G�p��_ke�MP��O뵨Z��n��C����CVTkz�e�j)7t�a�ގ3��\(�3c	��K�
�^O�ː�d�@wӾ�82�������ŜŪJe��M}��n����f]���_�q�S�Y#�W|h���G���Z�SD�\�sRL�.�֍� �&/��|@A�*$���C�����g�6h>�0o��B	~�%��p��kِ��+�� ��CD)x�Ģ�v�=�T�W��0%���ySn|p���:H
w��<�x~����jz�P^�uB]���u-y�F�[�&�l��MڪU�_Jy���ѫ���wSw�	�ґ��G���yB����@�9v��k0t��6���^�cHH�@g�;�Y�:)�	5�RȠ.�#�^�%�)G%���3X�A���73�e�Ŗ`+7�o�+�5�E��'B��;�ä��"J$2��Z��i��4T��ۋJ`]̡˟-9l{?�r�� ������?��0w���Kю����&k�òJʺ��4O��v�==�΅!:�(�#���vN�ǀ�"�Uø�&�.����"�V�Q�p���C~X2�=�H�x#�K#��1�(�4C�=��}��I!���Hl�[,�\W�^���j����o�ѕ��������s3�ڃx�wc5�Ux�I{�0;���b�����wPY����`�����q��u�&;\�����"�4�Z�C��-�۵"�����Y�5���a@�dv*���f�N��n�\�N����xoɣbp�%]8�˝��>_��d�&t}�ݰ<������ _��4�qýK�=O	�m"Sݗ5��8�).�R��rv���28�皾��),y�A^R�g}5O�O>�vB�Rq�Q�� ����b *�p��pi��~�<���h�S�����~%���á��.�0�h���:���>>����]�{<�ەR)lj���q��wƭ\,4���띡$v���i��u,�K�M�r�E���f%�7NH}�k�N|��\7�R��I��U��ǆ��/-�.��I��������<q��Nbk�X�3坰&yJJ�F�'άǱ�`� �[OS������JO�P��H�oXy�ݏ !���<u��G�D|����	��w���[8h+,6�j�L]����A"�@!��ϼ�_9h��L"<=����N^����Eɉ�^�i�@V�a�9Q�m�P�d��-�7c�̈t�w�A'v��&���U8{�q�l8��]QD��e������'��
)Б�����.���p
�'J��m����M���O�TV������l#~,J	BU��Z&��q��de�(� ���Yք9ۗ�����*�$疇�Y�`��*�̶6���:�XE��@2R�HQ3עAs\q��eųJ��kn�2	L7��o��
�tt��������q@�8�@=<Dz���	�]V���5�I;Y��4]��:�#3�A�a����%C�~�Xu�r.k�9�٧���M
�z��\a��W\濡 ��]N�-�a��<
���چO]q�둰�èkN�<��Of�쌕خ������ �;�)	��=�� �^!C��u�)1��8< j�p(��`4Z5m@ |�3f�eV��Qpj#�^�0����m �Ų9��,�ph�,�f;�
��jj���/)2x��ǿ_�4����ε�����M�=(ua�P�J1;v�r��z>x���A��m�j-�엳-�6 �szA�y�R�)�����M8�r�LgB��"^o������o�R���+��ϾGW�B"*������<�7�$"A�@\)=��gDv����|�������.�ŧb#g=���\�[:[ $�)�B9-�4U?\�S��`F�BPݾȞ����?���h��Z,�oc��fڏ|-(�qW\!���!vsl^C>Q�����M+��������r���HLSƇ�3|3+:�!���0%s�;N<���̲,\xU��P��XF����93�Q�Ar����3}��E)`�/7���\h:���m6?��zm�7�\N֥�M��ʉ�Xe&�-�N�(GW��h��}���Q�1�(u?��Q�_/t)�u�ī���@9R�����tљ9fS��E��3~�),��T-���\D�v�a������������)�ò��h�9G�~����:���k_g��K�GIԷ��uu��)�R��(�,�/Z�]�����4犾
-�#es�T�p(/m���킰���S����J�=����7�,QID�w(Ҥ �+R%,�?p��t�޷a�%ǩ�mA�W<Y؀��.4���y�P��O�o%����6�ˢ�C#ѨSF�l������i���8���r�=�z��kRV >�y�-������kmi{����q���}"sCB��!�|M2p�5���6:�
W��Mc}M�tb�p	Z����ɒo��W�W%�^q�dN�}�}�~��i��y� �J;&��v\%>[��E�_���1�H�pL�����%��-��
��SF��{x[L�+Z�\(�E�^�n��A�����F���k��tH��SճK���m|1��x��'��{�at����4
��U���K����)�a	�W�2�YDI��O��yI�����D��K.�pf�`�%���_L�]7�	�8����}ITՔ����t3�x?�$��'x.�/�z�QLEu&���O�X��qt������-m;�>��۹��۽'���_xr�J|q�<�ٵ���e?4�=F[��|h��ש����4f�\�C�y�O�o\40c�J@'�X7=����b����$�3�#��/�yPL�;��:�f�Q��k�~6��x�֚�`��J��I�hĞ�79�"���pa!XY8�A�Y.�&��`h�,����s_�s��
�����.*u]R�U�/�V7��	;��cR�i,���&N���3�]�JMk4*���B3�*���+�Sh*a|�B�x 8nkX������}j!�d)�r_� �KS��f����
��3�o��L�I���D���MM�'W��K2����if�+���M�0�h��"*�>=���"��i�_�&��?x�����@;�v/2�_2��<CD������_`��K<)7)�*�G���Yo������JXO�?�j����ѓc;�>��>?ϫj�B�B��z����T�?ڍ) �_1���ѨJZ+�~x�#���n�dL7-AlҪ�N�{�GP��~�&F��z��*Nt5�;\���ܰD�w����NW:D�hPk\��>��<V<*�b������"_���E[����P~ѨݥގC�/i�C�ᒛ�Q1�� ��ο�d��|�5�#;�`m�"V��R����Xnp��%v��Ƚ�n�bH���.zl�j/�����*Q���l��,�v��YC����r�*#��wjJY����7*���;c��	�� jh�_`A��E�����u�d��t�:�����3*ŚRRY�e��I�a!�:%A.gi7�-��b�\���5�-J	��pQ�:��D/�ݑH��Z������zx�l�2���úHPNz��zկ��ZR��r�Y�Y�S:N��˦P���Vͯn�卡��>��ORPݎ�0R��.�?�M�nq�2L�t~(�����h�h�N��d�Z5���AQmq����~6V]�!p�teZ�G9��Ո	�cx�����a{�M�8��>�N���d�wc��N��9�3�l�i=�O�SO�W��a�+�v�C��f�S_Ѥ=p��,�n���sLݝ-X��L�i#���_�Q�c��Zl�nLs��ɭ�'�A�K�j7�P"��7A�i��T]�Y������~Z�	�I0�#�t0皾�ǲ�t���K��z�b?�}u�@A���!���i8j�i��et�j{���M$p������-\�s��C�����v
�̢A{nf�ĖN[:�YI48fk5�;�8}�h �f�˥�	�E7��1�Q�b`SO�.�6�Wj��~�I�l�ԳM5�!�נe	825}���~�d�m�������LLC��rܱԇ0!�<�)�_ud�᷂���N�0~1�� .���~P-1L^d8@�g\~�Ԝo^<�8�_��k���L�|���ёbwg���~�}�;a���@2[G�Գ�,��Ym ��t�(�L��'��Z����ױ��Ď��U\��������e������%�i-7�r�hn��qĿi/���Q��ӿ��h8��q�T���G�K��$!�#�]�<���TW��شR�JO��9;��<��0L3�v��1�8d9{�����K�M��Γ�Ӫ|H%���aZ��'-x�z�['M[�@�s+b4d;>t3�6z�+�{bSĨV��ՂI;�\k�
��+����[�|s�tM�Eż���a䅤��)���A.Z.H ���6�b�@?/��E�M,w��)��1�d8�!���|`�G�U�^4A�ܢ�爥�Oykē�FєvR���{�A	����7�%��/G������t~��K�~�2MF�2�����AW��#2L�(ȁ�'ǭ1�0����=׳��k]H�N@�G(-H�d`m[^�Z�^�Z��b�!��k�ƫdzv��k�2�_a�)N�9�[-�+g�勴�ݕC��\IE�����9����%sL/����M'z��s�k�ji76����֨�b�S��
λ�:���H�"��?�1^�g��;�?�pϨ�-7ԝ<�%��<1ݱ����|�8�-統 �
X���}�7,M�����P��RCU�M��J��C����P{}����-ׯM	d?���t��/�Ѱ^��F"1�uGx�1pP;�#8ǚ�� ���i~��?Qܢ�~���g��$:�����Z����O��A�{싌X.�\n���E����$���A�z�W��p�,&�^0أ���U3��_����9/���"��Nr
`�έ�3i��p��>m&����T�on��S��(����|�� T�����KPn�8|8#o����;��z9da���Lh�kC���ɠĈ�ﾃ��h�t�7x�t���X���"^��T<�Q���N���	�2��S�E��c��2yW��4����o��Wq�;�_�|���.���Qzǉ���f���z�;?�e8	��Ł@�x^`�~��ƻ�1}�cF�߲.ޕ��\�8KJ�Lb�b�yaH<i0����v>rx�-.���@
��zE5@QO{����(]b�Yc2��/��V���^�2ufl��v6��U�H�Q�o�h_}cxS��7�31u�px��>�r�����K�N�P&�n�CR�m=��2���.`e ۰�.d�
�c���a���-��d��n�N�*�dA��5��ٔA�a���ߛ�u�$dR��n�lk(�Yz��r�ݎ��Z{��c.E�Θj�,�`���=
��y!�])�K�)���V��3��q������t�#��Q�?m�MV�v�L�5�r@1��lԪ�y*�X���
r"y[+��~]�[���0�-RԦx;OX[�r�j~�u��Y�Fw9�Na5[mJԴi��̲�4�� ά��	y��qwM?��o׫��
v/)<�G�%��!�ֵ�yyLO�Z�YY�Q��j�����Z/H{�n���6�9�f�H�S���.�B�^A���� �:����`��tN'd�ף�莈 '�NP�Q&��U�5=�
��zo�/���1W�r��֣P�.�T�TA�I����͗{ ����-��c���i�9����̑֒L�T.��%J�o3���H�L^��r+-t�I㩜#L����b�1 ��Nm�Wm�@��n�@�m�4c~T�95��@�����Ł]׉�ZҊ�2��(�X���w�����ȥF7)�	���3�_D�I��r8lz��M1��j6
S���z$�H{�qT�|l�s��. ?ᦘ��ݑ7*~�gpٿ<��Z4�U�	ެ�j�W+!��*����Z��#D���J��������kH�-O����g��f�(�g}F�9��ێm��s��#�"��� xbOX?a�벂��%u�ǇT��_���zͨ|�t�[h�(\g1���J�S6zҿ��d���d�i�IOl�a4��^����5f�[�R�����{R"�q�[Wܟ~�I�.ڂ]��B�*:�?�r�T�~�F�C��r��c��T�u���7�k�V��l�BR�.q�lol���HM�k�`4�_��ȌB��-{��넘�>wE	��z��ύ�M_eH��yR����˓T�4��K
Bk� Te��?a�yG������]�JX@�i$U"Aڎ���h�!ْ����;�Ͻu�Jmy��e�V�>�us��ףI�պ�Y$5�ɣ@��ͥX�Gb!��+I�����m��v_�l�(�B�D��/j�$� ��\)=7�K�k⏌�f��Ԡ����sg��Z;��n�r�Z�`&��'��NΨ����Z-W%9��+g�p$��2�٪G~��
���8���g�Q���5XrQa��#���CB�	G��$L�S�^򽻻5�ÖU$�D��aD��CGɪ4����Kؾ~���j`��7�/ar���n���Z�%�!� �cFͮ�'_[t���7��",��(Y�5$A�ߑ��!p����vQ@���gO�[����'���eC-J�3���=���MI��C89��T�<�Qm.�ȡRq��̌�1�Fa ���Z�d�	YޔU�e�Y\�#Ѿ�Ǯ�r�G�OY3����@/��������+���ɋ�����h;���A,�<o�Z��$��K�<�jy��=ȆS��m�+��q�U�-��	�����^z�!�l�Y=�\�{�>u:�&x�5�vp����07�u��^^��.��Zl�	ȟ���i�rE��N����o��c������E���*�����m��F�˗2M�;��,�,�	�Ջ?����v̰Ac�=��-�������;��-��q!�Y�=����򄆁_2_Z6�gD�i\��q�ĆQ��^/���1��3b�k|�������4-NPЍ"��s����d90����f1�zā:�W+������_'���b�Y�����PGD��/�tg��3�$Od��k��'5��	"z����t�^����su��z�u�2�А�A�.��-=O���6VvGZ�rX/_p���*�^P�8׻���:�D���Fn�Ɍ�P!ġjv#/5\Xu�R(v���rUo����c����bM����T�l�3���V��+V:�� Q��{����4 }mRJg�ֆ�r3|����6�W=�����L%?���(.��[�)��
rt�+�:���A�&�/�z�G*e���_5���q`����
�.�윺ٟuAHh�@��p��������j�����ӝ?��
����؇�^�� ��dB�j��be�����g��a,0�i)����@��=z�C~c7\y���q^��\�Ʌ?����|�u�DH��+h��j�ژU�1Z!�i�OB�%_���ƕ����
B�H,^���pc Ι;ʼ���U�^R��dhe����!�>��g(�G)=d^���)�,��_E�Y7w<�(�L5,B|�7�D&��g�#��÷G�)�Ƣ��R
nx���L���B$jV��x3v�Dj��g�K�B�e�e����^�O�^H�]R���u�Ԋ/�r��6M�������ƅB�^��I�ҌCY�~Q�J�s^�B��0X�,�t��Y�9v>�9�?*���7��@�%M
���ŋ~N{<\R�=v4[�;cvvߚ���C�����p���ux�?.M�]�G�X�pG *��_�nX��2o� ����q��S�\a}>��`�xd_�e[*e�@eq�Nu��#��В��v�S�MV^md'�S��R���� ��wS����4rU�ю$&Q�,Ķ�6u�m�d3��z�B��r	q������V��a�GG<o�+��悎۟��S�?�u�����j�=�?��4���M �v�$'��8����ߥֳ�t�@ �ٖ�=r�K��%f»����*�	{�������,q���tl��iR�T�r;�YJL�ȰU��� ��>j�}���^-Ʃ�fH��EG��ҳ�Դ#] .���#�Ӥ��5T��im�Ww��v;�	O�o�l��v��È�*�P��/��ƻ�uqGA���(5�%���lo)��� 3��S:j�����:����g���J�`h�m������� ��տZ���Ay��r����<���=ż��S?���Ss�D�Au?�v�nb�����p�Mх˷�T5�7��z.���6{X�,���W����8���L7�)�$���*S��7S�I,�봟l�f���q�rGw}��qݭZ����i��
���߅�\OF���N#;O�D��bC�C�1l����~�Ϗ�uu�N�6��ÖǠ~u��OE���{��i��R�7�&7V
�$~"'��P%�7�=A{k�T(�D���^�\��:�?�Vnda��<y@Fop�	����$Yf_/�:z��)B�ߚLLH=\ɲ��'�c�E��6�X��lW<���,k#�"ϱ՝�K�։�>� ��Q߆�1���tQ��N7��;#�|�W��l���Lt(v�a9�9cg% Cs�������s]�_)�b�c��i�)�<�/���%�S����p�=jk���!.�A)��j�%ySM^�i�Uw��v�U�RG��ه�^C�>�nq��<`�����R=�󪵃-uq��I�橿��޹\��{9ۭ��c�?3�Ŧ��Ő�c�z����J�D�����2@Z����	�8�Y�U[S�m�?�X�?ƚ�"&�jUKW�;�`znK��f���	tQm���N1W���.F���.DsE�mSB����y^|`�N������� BD����4�X����mv8�5Y��g˗x��FuR����$5s �R�So��,X3	�U�=�~ߤ��d�u��>?�P�7C�ہ9b��.�g��!�{��^�!n���q&�Wc\z��0��s��c8�E4ua:�p~�,�U}�C�*����l�B�LvVY�_F��Z��4R��Z#H0��\�k׿��y��dfU��hhԖ	�09菈�=������|4{W�����bxt=ɋ!���x��K��]Z\ѥ�{�+�jX⣗��M�t?^2f�ɋ �GN���+"p�������i��'��Y7o^����u��� x�X� q�eOh��5�T^�e�n*�חT>и��1�gڼ�K�U��[UT;{��\��7�bzO�AjL45�M؍Z�ŕ�I�a���A��qU��)��=tiX��;���z�)�:��fz��gG�k]�z[��?��deS��_�m=X�.b�-�n�pN��B�������xj�����s�l�b�];kOC\M]L��°B=��3Z� �� }�,pؘ��2���>.�"A����v!K�ͽ!���]�֕OO�:7�7�� 3$����v�!�X� {���V�,�X�|���i���N��(5���:�)A9� ;�F��P��~��z�Q�D�"u�T�7�vɖց��Nnd��7�#���9�ᖋ���	9{��Ǽu���)Z-�?Ɓ?E(�|g�6���~��aF�kUH��'U��c/D�arx�ϹRJ��R�`�cVG����Մ0�Ȗ�\Ƀ��[�X sIV
4~VB`�ecZ��.9�^D��{��/T���/^��sDJ��L�RJ��_!�'���̥}!Rd��� ��4=�-s�nMTCa���1�����|����g1���Kp��s���w����=k��5��*���B�̾�ـ�� �l��U�"Y���d����]����1�A�Q��O���n�"�����sR%U��rXZ��h]�ᾪ~��LA��FZ�^8�.sk��Fzޟ���X�����}}��̦��v<�x+p��ye�>eN���<}���pf��u�m�팔�4��Gsq����P�,���uyD�"*�p��[���D�P r�i��YR��g�{����~gj����M�Κ��ipB���Yb��dה�;d���\��}��~W'�.$��Rݏ^�Y��!�A�y2� ��0��Z�u�M]퍗6*>헎�<���W���h�S��vǰ�2�*?���-ΐ���#�k����=:~^D�~�����x��>3ibwR�K5��b_����yDqx��^(�5�7�`x=j��]��~��J�!H�^���y��70Qn��^TVұ��}��5@ݕ���M����`�gE0�,^�R�^D'�P�E�J�=6������M����%PCC�ۛ�.C��A>x������qL�x�s �h[ ��2t��do1�2�#-�A«-�_D��;ϕ�T�9��hh��Z]� �=�Y�ÞO��/�=@�9�<oQ�����%ҿ!�<P-�Y}��k=��ǋ�-�)�(D9��@�DR7S*�}8��`{�WWD�/��x�%��pa�@0I�׬�9Qq�04��kI4)�6|�z�
Ⱦd"~��tj�/�=�ЧǴ[6C $�Ty䝤[rI���(2����L��q��c�w�nw3C0JB���N�i `���zDM����F��z�-�aG��ɥ�K��a��cg?�wJO��X0�Y�R��2�<�Z���ڞ�;2��w+z��T��l��'��@��4/V�Հ�j[�:7nظ��q��S���=}V 
��+G<�yi�[��A:     �n+nav� ����9��g�    YZ