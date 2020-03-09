#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1660892552"
MD5="3b088551fa72b69f842c134b1c512daf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20760"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Mon Mar  9 02:45:12 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j�4�m&&}�t�Ώ���V7F�,�:sם��A����%2�9q��l��w���ҡ���~�#�kC�
kQ*���� �zg��](��l�;�Ø�ʞ�B��=z����UQ�o���~���߄|��Wݽ6�qc]�ܩ�C�pn=��9,�t�j�Cq�-4N�"jџ����� �{l�L�e��4�k�6��7�*��e@��4��e�@Y�;��b!���1�=�q)>�����2�;JOF\��l궋Kg�zv��Y*=��﷉S��T�.��#�g��D��/!znZGb�ػ�����x����HQ1������p��Y�>�4T���˚E�It,�7-=!�>b��a:�f�@_-J{�Du�w�H�'y_��p���=�w�������U�I�NF,��	�-I��+�g��_�_f�N����3镧�C��e^H��=��|�K N�e�{d�#���Oy��!ڟ��(���{���c�h�u�j�$����eW��	��4��&����[�<�y�w�����'.Ȥ����2�c�e^�7��U.�U˟�=E�ޞ�k{�����it㢻প���4N%#���D%g+����gʦ�b�}fV�5s�Ƃ���
��s��"���N6�>�E˧mj����E_���Q�Ìܮ�P�]����g�v�ߎoM_Gh/��(ǔ��VŦ�"��0��+�o>H�L@�N	��L|-�R2�H��4��◄�Rs.)�1e��L��O g�M��#?`�˖���jeБ%ɡj���ۢ����%$�P ,��ɇq��y��H#������D���=6R���s%� ���8*A��vf��S���A�f�<�:��{���qr��V۱j�ǥ�ַ��wA��S�W�7B�7�y���};O,� 9���,�]B���6���q��?�r���J\��d�7�*v��XdT��Ąj����Dr4K+Yl�P8)%�'�7�8j�D���0�arU݋�y�в��>�;�������7����i��6��Df�ڹ��I�S�l�t�� 5q)�q�.��9@�*X���ߜ�9;�C��ϻ�%�p�ha=�f	gx��8=�z�t~K�E�毎��>s&y3	�-�	̺&�TF0�\�&)P�=rp|o�4W���P�ħ՗��m \�	��p����{X6uf8��e�D�p���&�������(��u9n�xERg�A��7S�o�7\`���Q�N�eTn�ڃ�%z��eW�Yh.o���9�`	_�nc�����rc����tۍ� ��,t6�C%Rl;�0Y�J���A�7�f6�.׼}����Oh���1�;mDz�m�M>����F���B���C�.2+v�2����3%��ՍS�$��b9�A��9v�������S0A���AZ���s��}V��~�iu�3���U��;,�l|'�`h?g��hT�)�ί�A��\�.6l�Ku���x<W8���.G���@+X�:A�ȴ ��6m2�
�H��փW���tmmZ婟��Hg\3�ѓ�>���9��>k��i�8��h�N��~|��^-g�:݄�.����湇٬Z�ŉ�f5˄T�f���b�T�\#�K��	�0��\�T�d!tǞ�{�	0jȤ��~*H�[�� �ZU	�w�QL=��%AB[�f.��z�>�=���Ԉ)#chm HD�}~���zQE�Ʀ�9;�=a������TNG[�ƹ�/���ѱ�$����_�#�#��Ąm�l�ʺIg[�r�R��X�X^9�����@/�H�,[�=��$�M`v��V��l�az׏����O�n /�N�o�8��/�u�/����mVS��y�;��t?~&��pvK0a��9��2�w�{��曠M�v���	-���^��dt�1@A!�Λ�핥��!߅9^��|[�1�ՍH`��I�L�ԎX#�H��rJ����!)���L���Q��>(�iI�Q��
���
o����Lu�H�wC��?3e�� ����
����3HQ;�v��[n�W����G}r,T�J0��(�	SpT�.���R�[�m�΃�}7�炢�U"�?c�4�������Z��[r�^�����7O�Q�11s�ũ�$sJrX��ؕr��g���	����M���+��:�p����k[k�e@ �ҵJ`��	{a�w���*
1�E�����g2�C�i���/�t��1�#�K�"o��5�(��^P�,1]�J�Ů�Uz��p�'�\��q����u̧�hP��B�J��Q�{g�E�Wvt9�h�{F~JB��D���-D��,�0A:���.y{�C�j.ȝ���	�E��p������Z��r"b����i����3�:Mr0L9p����5��v���k�"�1�����Q�te������p��j-�Z�,�A�������4ܺ�}4_���Xյ�mj4����b�tܘ��8�Xu�����9�U�4��o��̢]'Y<�W������C���h7�E�?�S��y����?w�0�e��9k�7),"�.D�����ފ$Ӡd�<��E��aF��$�Z��iL�R׀XS����'���������y����#���!l�6�H�P�E�S�i=�a�ד�I�TM�1
%mA�;�Tr��UM�����u��K򟡨��2=*b��%u�Y��0n�-�]X�&*!k��$4��BЖ-��L������L���ӆte�I$K5X<\�����A�˚2��_��� �'����b��R���ﳄ����5uxD��H��GMc6^�[B8���Ä+Vc�.ʍ-{&�D���8
@J�L$�وO���b/i+��g���oa.�EcY$�� ��	H�����πZ��1�����t�>�Kr!K�W,¶g&�%�A�F����)�܄�����#���$��*�̿7��y�Ǥ���4�3�"�i�|<-�4��g��%d���&�8)z o<K�塬KW�D-W�`���-q (�;�ۣ̏]�ҴX[�m��@��*+���DJɫT�s�]�2�����1���y�粋ᰉxjڰ�zi�p������u>�R�DrU{2�k�f����2�I6��hE�Gf^�R�Ww��-=֊��K�6A��o���:y����h$ә���$��Q|3��lJN¤��8���e���� �{'��\���ʢS�'���X-�>t������Vp@%2��D�V��+7�fR�A;��Xcz�2�*X�ͻ��x��Y@%)�ǯ��l��u�5r�w���vؘ����,�m3��ɮ�	��r:�u�+��e!����hr��ZB���`�'̧e6���Lt���#���{����w4 ����n���y�c�����/j�E��}�N\ �?y�[�;{��9E_�L��ʰt����ؘw� tX5���E	BZOItrh�����-!q+_����y�VG��^	�e�������;��w:F�uU��\�$W��]������T���S#�U:18(,m�FC9ˁ��S;�A��S�c��s�t�#��]JI̕���a�� *gќ@딑0��D=>�gn����l�FV���Q9{�,PF�qf��S��9��F�O�}�VU�2��q���������ݖ\b8C!�ǽ"NCؾn��5���N��;���Bw��	�:��
���?I�B6�  �l������I(\L�R�e�)���k���Ǝ|�;���j�K�3ͻ~���;)E�
�r�r4����<��<���T�a�h#6��F�X�4�YW�~��"+���H����A�j:��#3;�L?H�EWq�j�kI���7�����="%<�j�%�a윳Y�}_+��D�iQD~Z +������a��&r��H"lV�	S)s�e�ı�ӣ�QV�J�UX��=�/ږ�eͥ�q�6��9c�;��N���ϡ�]r秂2��l��w7Z�# �c��jf�,�_z@����
�`;v��mwoP���Qzm�h*[���@Hgg զ�����O�;�*�%>уDTw��<�2G4o`4�h���gPыݙ+�{��x��|q��� �?8�h�"n�%�T��y'p���!��ҋ:7�%���	w���0�eg  [�]�,^$h9���dN�vFrV$�`���~N /���#�:�&�c��B6���w��Z���(y��y\J������n	��ݿ�ǿP�$'��[(�$�}����v��ap�����i�No	���F�Wa��_���Ahg�$��@�~��
���7qh��B�
	*'Je06����y�L���f��ҏ�pƤ�~�b��nRaؖ�ڽ�6���g�C����k�0�}N8����*�����A5��nV�^��m��q�C�=:MeN�$ig`���Yfnꐊ����/rx�3�ޒ%����y�}��]vG��͞i|��
�/2�,��c���>HWc���wxf�K��>'0�5��_܈�!�~\Pv6Ύ�� z7���E������w�b�T�<C٫ �K�Ryl�����^q)�P���w��?�ŋE��֖�6�f�hT���I��V�@�G\}��O[���'�GV���<��=
 j%�)Q6��DZo�m2� �6�����ؘ=�V���J��z�L���}m�:"���B�&�C��/@(�T-�*�e���Pz�9��%�7A��o�V�������n��Т��$6T��EG�K��A�B,w՛��L�� �!X&����f�6y�tB"�͇D$U�kG,Eݽ�zE�GA���6���*j,�)���7{u8A��e�4T��=Z�m;%�bD��iE���?v@�xG��om�� \��ڦ�F�͘��o��_-���k���J�]f��pg;��3�;8���n{5��7j��# ��8��g���79�ӎ������@R�d����㣦�q_��QmV����'pCd�-��M��U��- Lz�Mf�arzJ�ߜ�_�X���X!`�[�ШP
%f ���'&*������!LGv�w������Y�i���A$�1�(�'$����a�>߮,�)�@E�P��Zz)�I�2Ӽ��ǳ;,?*���5�:�9�ǰ���ܝ~#ir����ϝ�t"F"��Ig{,mx�ـ +,���J�A��ȣ��q�)ϻ���Jm�Y���`'����E��f����0�L�Ѽ/�b�%_Xgq�Q�#�H�&u�-��2:���"Ֆw�B+D	H	.��^z�������B��sK��չ������T�M��aS���߰����	��5�
��ϑ���	a[�B���a/��m����њ����[��̠���˦��Wv� 㔓���HK.��K���WX��Gp	�3'
Q�y@SHBxJ�W#�C/U|%;���fe<��+I�UE�2M]աy��]���=�0���
�l�>Wk\@��{ٺ���Z0\?o�)����{�p̀E�e4g[К1�i��ip� ��?!�4�æ�����0����S�7�����Y�0�O�:3߭��~��u���"D���\�����z����~��)�:_EZ@'�|��uC����h����ܸ�Q�0-�x!�_��=�5�!"h�a��`+�����b��~��%��]�ԃ��=%�V�A~E,� �^�I��R��eԂ j%,^
 ��Ƈ܎o�³_#���^m�F�Q3�SS�X��
:ž�;���5|��!p=[����Y�~�#�-��dh�\r��*��0�7���^��K\I�hw�h��������R�tC�`.p�\TJ/|D/��.��Ue��o0�ǜY�o��+���E���y2��|E?>L(D��o��nq��⎺G�٬y�>�r�ya������UD��%��_y��Z�,�%B/���y��n��oU���q�Q��L��?W.q�YG5�xM���D���|/�F���%O��L�z��h�/� ���8 ?i:C��EqHǛ��"�w���=�W\cs>ܮ��G�d�+�<PD���f��nu��iAҸ�K�#��)u+�.�H��&G"�D�'ϳ�K�ʔ6]-~:7ql�fϩ���˅(_[R�\��F)p���X�{qܴO�=���9�q#�C���dϦx� �-�V�X\c���֫_����6J#%O[�O{2�-���̽�B���#Rʚ�9��'U�͇�.������^;p�%�%������}�|�q D��o�u�Ϝy6����dyZB����h��I�~�{��^v�<D�Nh3����n�f�6BqV8�C���[��D=�:Ȋ�~.���[bR�� |��9����I�a��v����"����?+�'u{-�(؝O+P��.���1G.z�I��>����x5D��s��I�m�^�,������L"d˙�	�Iĳj�mI��:��g��<�7,�r���N�,�˱�St���<>v�q���}����tĈ�6���Mq�C�oX�G���I���U*^e�����3��Ҽ\�oV!�Xj1�b��#�=+��
���u�,i�^�R�?Z�@i P�,Ҵ�C�K����N\�K*	s_�cft?��%[N��ɍ�s�R̜*H����H���m3wj��B3�nÑЬ�%y����?�������"F��T�3е�D��y�=ù�~����b��3��x��f`Y��?��aO�����k������)��љ
��yq�
'	B��J-�t$��k�`ƥ��� k3�<����;C+Yv�r�!�iv=�N��[tEE�Ţ��Z2o�u���n+���*�q��ZDW��A {�}���ӣ��b{ݹB	tc��
����*�<�<��4�ղ��]�˫ƹ[�Kƹ
��4�fO:N��}�P]��p*��<��&N87��;;�������������M\����$sp�����ܺ<�y3�>�@|,r�R������1���h6_��Ѽ*���a+�UJss�mp܇�W�/v���۹��A�-z�9���s��v6lfg�1h���嬊����oz>�-��;�ӊ�*,&�Յ�!�8'��3�<VzO:�j�P(�]l�>N?K7}���g�dB���&�D|�_+�u\�s�JV�_}�L)��3(:�^Xsڸ�O�� F��Yt8k�B�-`Q��~ H�|��S>�HA��U����ljK�1�O��8��ቸ Z-{�G��#��BI�����I�N"�2�\F��jP�
���� �q�0�}�5�ֆ�4�̛i���倮����@R�A m���>�] Z{(��(�s���_���m�Z�_!�=�G�rS���'�)��߀��>a��Me�E�_���c�s���������й�|z7d�˂�`	�&��!���h&�j��I��X�A`�H�>��8������(���>�S�mhµb�J� �H��,{\3�oPP� Qʹ5N���}��Ȋ}O���}�3�����b�A�^az��7��nM����VX���v41��[/>�'}C���e�%-����9.I�
�
��A6QS*�k:��''Z=����ō�v��%O�Ջ?8||~�BU܎L{�qV��Ľ��Ԃ٬/���2e��������Yy��n
?�DB�j6���a-��^�,RP|�US��V�Z��B��I:�Zt��.P�f�P��*�
�OU��>:`@�V�췗^����΢M0�k(�ta�m#�B��˞��Sr5B[^��l��M�V�Kj�����W�Z��H�}R٫ӱ+X,Q�151�S1�;��< <����0:��nZ@�����"�]�/�V{��'�e��f���0�T�EC�5���3�}�	��#7�:&:� qJp��Pd�yo�z������qV}B��<EC���(.�?�6m��`�|�y`�4�ny%�y-�}��ui����2��y�0 r']��x�G�)4@��0��P?��0R�-���Y���#��:�>��^Y�% �>���}굊˴�x|��zS2�M�AN�5���y��QVv��ė���Ye��g�'Þu�����yҳ�l�V��Vt_���~��zk[�^N^�hW�Bi+h�0���w�{����w�`�y�5n,3�u0a �O���Q�H�a�j�0�����~)k����=:�=|"�����bMk��.�`8���- ���ΜN��r6v�qv�(�B�g(�D#�`;t�O��.<��|�/m�9(7�Wy �t$;/?�C�F�>��,���Pk�ń!Dkb�c�C��)��	��{�����4����{����;r��a磸��i&��(�x��k�J7�l a��I<���[s��T��@A^��?=A�u Eꏻi�z!Pw��#"T=��u�dM���oQe�˯iQ�X�j6�|Ɯ[=�ZIC��!����*|T�c���Jz{��]��0�s>��p.��%���Uw6ti	��:k��Vl-�l���B�mTYȤ��������a��-��{3���34{�����P�M�g���JR�:���/���q���������g��c`̀>�ݷI<�KsH��%O@� �W�����j	��by]Q��"�UFY�tՒ�	��Ė�4Hn����# |��(x�e\�T�R&��������/��u�^�{�'a [U�c��_f���˲y1��dɗ;GZV��-�~Ŵ���J�F	 <"����J��*�j�ZȺpN�q��G,���"ka9C��/��ǝn\�0��}�Zc�et9�-�AM�t��c,�t8��@����M�?L;A��2�:�"�'�B
��������k8)#�#��-�����v���X>�~�$��6�=hM�0�y����!߶-�?6�MY�b$����>��'t{��k@��(��W��K���p�TI>۴F����&�ٚ�0��i�.�ڄ��
ÛFYQ�5Ԙ�
X���v"��%+�xVWL� �#�]���.��~�����0��ԅ�=�(=&�;Ǧ��Ga0I�.������W����F�̉]�%.��@dƳ�_���(��C+̏�F���#'% ���q������sfjeͼ��q_�(��ɳ�F��b�n�N=i��]�X�?K�<�f�!+ �Ck��&��5�/k�
��x�"��2���|)C������ҩ�OG���j��(x�FJ�iJ�l���9�S��ZИ˪Y^���u�AE,����d���� Y#"�-��P�ͨux���'�v$��ew��(\�𝘩��O<7Nl�fd�ۊ�
��4>S�8i��F�m~Ú�z�eK��-���5|-j��F��=P-X�^�k�G���G$c����K\�u��aSF�2Y	u���BV���*��� S�m~�dAJ�;Wy DL�&U��C��r����^�֝����Ӗjp�����X�/��S3�̸-#�]	}�9��21u��9�20�2�9f(V�Iu�1X�+���@������mx�+Y���n+�2�����6%"�©a���룃޾9@�	�-�|a�`�����G<�N���\Uh������Y�Ǥ�/���o�R^��W�&�|= Q~��P��"p}w�B�\d�v ���T��j>*F[K����m�s@��0=c��+��Z+>���,�d߈g�SZ�Ǖ��+��$�f)�*f�ؖ�� #���֨�O�=�]�����O��A]Тy9���C�Q0��h�<� �n��������G�y���u�Y��������=%�[<��>��a�D�F��{�x��h��s�?�B0#79:��h��M3�/���+��m�N]Ͳ�N����hOs�o0��������R��+�7Sjmh�D-o4
�V��#��yY�a�e�?���²��j�q��-J��H��@J�Ds?���^�
��4r��ngd���U�� D���e^��y��.�:d����i5�����Fz�n�7��y��Y�X�K�-�@Hb:��Fβ��U(��`�����QF�M6d㧉��<��^c�3��N���ȋ�
����cMC��PZ'������nǌ!AP�M��ԪPa�@��I�?����B�j2�a:����i֋_��*�Tt����!��^i1_���������\��� *<(㩳�aBA�o.^c.�sҵ ���e��<�9� ���ꊞ��׫c<����Bc'd�#t:����r}&\&���!|�Yh�D~L-�e��I��6�jCF#o�Ȫ_�e�ia��4;�����R�g�\���ͺe<x�/�{��5���~['L��P�,~�p�0�8s�����Y���0���/̐��4Q�GZ_ú�x?%�m�	��<|���2��f@��B}�t�k����ٯ�_̍>�n��3�S��yF�4CN��:�)`��Vd�����:�m7�
1-Db6�o����dI�GR�|�t�����#R�����G�J2>,�Wt�5w�%�p��6�H�DrS{u�#|7xFr�C�4a.�u,��=�\C����<]�z�k�p0>�V��F����V9�r���C[Q��gJ���'*�K�!�h`�~|Ǣ�g�p�r�S3S#-î���=p�C�ef�"� A�xpb{�3��ڶ���m:"lT&xd>?�98Χ��bW��s7�9�v���[�ۮ��v�y�m�dg7�C�4j��2?Z
&`��J�?x5�ez�+�.[�7Y��kMͪ�鲦�'�n^���K_��%� n:Xfz�]���k�����8FۤbX6�o��
��|N�C(*�m��y�qա}/���ۅ4�5��]�O��jh3�%kMi�q|r�Q��7d@�xP�>�͛Q��`�T��"Q�B)�CR9�Z}��h�ҋ���"�nD?�� ����2�t��r٭,�n�U8z�]�C�>�6#��Y��l'�	Gu��On�⼲��(�m�8?>�>%K���J�i<>�R[�(�~�o�I���9s���*C��`o#�j��l�bw���/��R�m�3�wYG"��ES)�A?�N�9$�-@����h��Via5-�nZ|h�I)=���0�)4�7�o9jٶ���cz�z���4�S�A��}�,��\8�fO�'�h�29�Ȋ�T8l跚���fkY�j�,o�^����S��|�ݱ����w�7��_�<U��h~���[e����
ڰe�E���0��ջ��}��u���"�{�U�t}Iз�0��l�;x�0Y�(��ݤ%��L���ޠ���t1��A��ͮ.�0W	��0�Ż.��qs�)4R�L�;�͂ZPN�+�oo���� ���l�&�L�(<#cH'o�a����i4��d�!�����]N�$�m�����9�bu�f\'B�"�/��'q��k������}R�>g(̦e���m��}L�5񖺒p2є=s�T��"5���-��D�;�3����ݙ�S�0����{j�V��h���z�p`hH���>g��,��Ne�$�`+����`����*����p�z��x��i�@�:o�ě�E�	�@�����a�L�g)���YO�^�l0K�(%�^Y
�i��̨K �V����=�t�j�����9��`�B̀ D�{k�qt��3c��;�}8>�}`����������!��	qӠ��J�����m�y����]RܛJJ�1]�@����T�$���_8e��U5�Я~ae6��(N�f2�=7co��3? �J�x�yUeT^�#�UP9Q�O�T.R���	�@��l�ȣ�=�����*ӝyA�&Z�P�Pz��`�`R�V��r���o),����Z�lsI��i4����y��Љ8ƽN���	��'k��%7U�]�j�951"��ƽ;K%LB�G�^Y��!��QF�W�F�x�|�h[u,U'������V��,7����M��
�Ncm����+Y�ש�S�Żܐ����7)�s�te�z�&�����7�B�P�1^Km�i���F�2TJ��΋.��r`�)@o^�NZGA�qc�vu$
5Lq��د���I	1��D>��8/6p��E� 8xK�����؝4��jϡ�+�f֑4n�90�ck�O��G@�x=fєB��>� j���)�6���B]�J��b�r���ZAm�3�qhgR�6��-�����l��~*#FtH6o��VT�K�P8��Sg��?dRD.RY�0ٍ�Ej��D�B���e��".�=H�����fJ$k��J�o�U#Ow,���C.�.���h�9��C��;��&î�%y��ۉ�oU���t�9�X�L�m�OK a�M]�S"�l@p�2��y�x>i��	Bk�s�6���\�w��J��x�N�T��q\�P�J�����޸}�x}��+�e}�����;�l'!�����������ϼ�{�O����p�b�����,��k3%]�-���td�q��c8�5�8��\�}���Vl|1Ry(��E~����X�C�ix�d-��/p����Oh�Ze�Єo.���c���2��U.��E+��:
�,m�7��q�P��-=�B&���w���L�
�gJ��W�q�$���T��p��9S�ed�,����?;m�ӥt��j�nfNV�d�!'k 6��q�9^�*�$D\������\�5��;�XG����j���Jf��jֶ����Ԛ�.�%�z}����ٍ]&�%?'���$H�}�[;�Z^�o`��f-9�43��i]�^C��OP��$Ԓ�+�HJ4����Za�H�%}���/��/P�p�f���{�v`�$�^&���-*���I��5���d�{�,y�8*�2�Zl���S5M�cy�W^�~�`߃8Nt�/t�������3�f��f���7�M��U&6��o^Q�	�T����ZrmC�M����8jm�0��sR��@����c�"�)AT�G��{�:7"i��q��U�[�Td�,��Q��@���K��SN��!RL�|�u�]��9qcp��i/�o
���}گ���N�\(��3D����x�$)]~�/�=v�~Z��E�HG`B�h��\(�Y������Ao� hFl���q���K)�tB]pр~�+�(���n{"���K���)Zz4'P�r�S�)Q�}5��l%�������5�w����)�D����Fp���ׅ\Yy��7%� )4&[8@߳y�&��J�7����n��s<Q�|�+�1�&L��,N���"�2�-�ʈn�%��{[�
M�yl�sL�y��>�*�����V�r:����C>�/X����4�oFMe,�y�=���k�7к1�UI�3���N�����J�T;ds)}p�a}�P�2�T�~��h�bG;��w}@@c���>�Bj)2��L�fx����p}U�n%�@�^��$�W�%v���j���6͟��ɓy��W���|6c��N�W-�q�xF�'k�	-�vAn%�{ե��O�wi�#���tb�~,E����!�&�=/�)�#�W�Fv�i\�^;c��t��^�<���mB���x� -�����\&"�[/_�b��'J{�*D�?� Tb]	��`�>���p�(�W[+�5�:K�&㱐�SzC�M��Y]a
x'p���XHZy 5VU_e�DWh�wUI�_�8�^�ӴǠ��s8�z�(ϯYW���r_�vlC��"�����E�P��X>;
�m�� ��=��G�=�תby�>��YE.ގ��I�57�8�p�j>`�.���"����Њ�ϸ�����G����1�%~Ѧ'�����rQT+vr�k�����K����u�]��X]R�h�'M$�eF��j;�ۛw9�բ����y�)|fx�����P��kt�(���B;Zh�T���R/��dV�32*�?_>�!W/�!ք��ۉ�;[�y��)B�&ޑ������|��4�?����8��iR���;L��!�� ������tPD��`{�L���>��	��hq��~4h�Ϛ�&���hp7���j����b���9�ȟ�x@�G�;�� ��*|0Hx�� `�ny�rcK�U���@cj�|;k0��oGT�L�k �N�~5IS�G�#�I��s�_׺������V{ǲ��<b�l��n�z��eA+u ���s��	 <�ڱ�ޛ{�Չ������&�Z�ޒݗa|�	�6raf���Ȏ�)Y۰�7�M���aC����;�*M_}�^e�r!�#,_�����/��3�gC��N��;,�P�\�s���2[3`3�]�����I��i�@���n����;8����.�;7�����2�����I�o���h���n|��VD����g��Rg�7�'�i/�h�����pt�5v��"�G}ɏ.:��ϡ+&�؆&�']晬�4�L���7N=:>汷�Yێ��	�YdH�l�2���.�@���6���q@��������|�E3�)����цtu�z������7�+tS��|:����O�e���X�hI� ��KÔ�� �ѷ�g�}��(<�)��O���l*��M�[;_>p�=/��u��2�']d�e��+�o�3�3�j���|ܺ@vװ�� �M�"��.�ލ��8��cR���� �J�jU1�% ;��5۾��)�z���e��ь�Yo�0��S������F����"/��c�D��=y�g�
����%��4|(�nRn�p���s�V��D�?2֔P�Q[Y�7BL����ԕE*��-ul������v�Z� �V�a��}N�#z��e�d�S��ȱ ;����n~بß{EwW���-�G��U��1����u����|�߬o�[�
��n�g���Q���x[�`E1�Zq_��5�7�+f6:��T�BU�� ���Z q���PW�cH޲��e���bDw�|t���RX ��s07J�w�5��+f<���,8�
�'B�>)7ప��o�hW6_��#,݋�)/\�F:u0h`O��A���@��#�PWYvTZ�\���/�9�ZF�� ����-��f������vy;x�(�����6�l���p��bƗ�g�ے�"e�{�A����g7p��H��aE�|�I���}$�8 -�-\6"�J�#�	\���@�E[��x���y� �b 68c����E�W�Fܾ���÷����f�En~ٝ[NC�r��T��l��*����,��.�F���&����T%ܯ�U'M�r��UE����4bz�Gi�_C�#X���BRE��G��М�'����`�o�6���P�_6]-B[!��v���h���z#��UU�+!8�6'���OO��/&�%�F��)D���eRw�2�6ʿ#%7ͦɅ�s�a�z�]�[��ׄH�΄=������K�DZ͈[��&O	�,��M�V��-�7c�GZ"���p�'���n���`ey��9TeO�Q�O�<ݡ���p5r�oeo��_������ֻ��cM��a��N_Ve��N`�� 	>I���Ve��ˈ*H���暤p���	��lS,Rȟ�8bwpˎѴM�4��+E��Ё�O�%?R#b�0P�Hz����M�6��a����r��x����0�H��PE9�7�@��v�i�����*�W�k�?�v8����5��e?8�F�f�t�oJ�׷k���w�i�$z�{,"e����
�	�Hi3*>]r�]�^��v]�%$R��8�*�`i�xH[=�s��� 9�[o��PI�������B�B���3�,��1�S�-U��\�]\y���[�Y���	�!:��hŒ!�<:hy��7IT�ܔ8�- P��á.M�Ѭ�V�IU19�5+�
��O�R���`����4)�2&��`Z��1���J%q�	��׬�C�0ȴs�#nlͻO���P��KN7�
�?>Z.c.��I�ƽ����u��i c{*Bo&�!2�0S
��2��MT�*dw_��}VMp������ďQ��'�OqA�Ik8�&�Mft%����j��x\�h���_�*�A�(�h�kB��.ő����a�f��;mz��N���<L6���~���.R"�M�m�gll�j����4w=n�i��Qo#L�6���	~��}���xMf��XDK{
�>�C�֦(|�l?Z�x�Pu�7xN��{b	��\�x��>`2	@%��#�9PF��b�wxX��>���Lf��Q�gO1�Ff��Y�����g4B
y�(�Sͮ�\8⃲��o��~��eX����|Ni�AN�U}4��ִ���%�� �k���f�c������"S���:L��vh������U[�-k/^�'��1z5�'��	��@x-�� �z\��H��zMl�iҕ�-N����W��]��ch2��U~�xw����ˈ�>�'[ &S:k����`�ZN���saa�K�қ���{�KY)9�\�q�
oW0�dL��O�ۗ~L
*�As��� ����>��(�I�"�&��Uc׏��U��G.Wk�9��F�.��*���~ǐ�)Z����Sj������l@\�݁���`��~&&�O/����Z+���+b~�|OM�P&�
�����ңǦ��Q���ׄ�ۊ�)���Oy��$ķ6ژ��7jWM�<�:v	�ƹO������U�U#�X�{H?�zB����֬k~�?ɓJ0y�W�H�]dMY&l��Lm�Ύ��n1���t��R��9#y��%��IH��^�+�"ź	�W�R#�WW���؉j)t�v��.[1J�0���Q0���U+G諤��X'P��s�	�ZVjAB�O�j���J�W�^G&�I��)�\g���XܶNק��.��֕ل&�4���WL��mBH<_� �<���݅��;�Rx �� �:h�7=:����1�
�{ŲP�\X�F8v+w-Ĺ�Vs��s���Y���(���x���#��������܈��m�U�odܣ�V����G�b7~V/7�f&7�ش?���Ĕ�Md|�5�"yע����G;�d�Q�z��x��G6�-�Zf�d�1=C� B���cO� Z����Z��	�ŝ��(��c{�ɩ�]0�~��L��n!O*�z��%�,�(v	�v�3����E�����P=F} ��춴��i�M)~��#q���R��z[1���0D�$-�-�~Y��o�P���`��vl�s��ؖ?R��+��igJ���7��dc��%���Z�3�[��U�e�S�Q���W��O4}��|���$����fr�3�O�%(�a����`�|���~�ާ(k���}�Smdvuo�l�'��x��{���3;�2R��c��� �Z�\�G���g�q��`�&�ԍS�����/p �L�7
%	�V������6�Ā�(c��P2����P`��1S``��Η��oIu�2L�a
#��&�*D!q������z��@�/�E��e"�[| 3�:o����Xe3��OZ%F�MKc/RʂM�$�_�6�J�|�
�L�� �أ@Ξ` 3a�ڪv
c��Siѿ�4�P���k��}H��]#�u�¿Y'�>'���)2�4}�l�/+����`xqΏ����S��$bE>A��P	�
�HlA	1�������~���=��_�־�
ԤC�鰏���	��⼻`�|2�8��/�/dz<E �.������p�?�Yka�,8YE�_bQ�nv��++�����D��p?�A�J�吖dG�e���;����I�y�b�J5���tp�n�1��(����� E,��uT������ټ䪹�J��e��|yG��v���s��
�g���5���݃f��V�}Q�eZ򦝏�:���,�\�`z�œFO�������[�q*\����_��.���3�݃rW��sa�ׯ���3��Fr�A?j>��OL��;���A���u�2�lߨ���� C��{�#�X����౺G��*��O]y8��0�u|{Vo2�֍'�ֳͪ�Aff�k�M2�� 1�g$�ݦU�~���A�{΋u�؛�f�G��G80VU���.�L�n���c{p��n�2�I��RA�G�����y��9TO��p�<��K��5;���|��:��M!ȝ�*gvqD�H����ݫ�ac�~��	'	*�3Ī�gg||P�h�-��̝�s8I�"�]�i����垕���?Iĝ�ۯ�r�H�N�D�$A�g�0�uT �����ݔocUP����B/C˷ZC��n >N�����}�?kF��i`�5�EM��H�g�5A毁�a4fߒ���O9��)�G�3v^bS0�e0�#��E���H��R��v��{q,^)�{#[Տl_�kF�)P�8��1�S��l�z�0js�*�NDZ�)[�˒�.U�.�\_\$�l5e����յ�<�h��+��n�?Ee��M�~)��+�l��>�iW4Y����h����pu�0Z8��D� ,O�BT���ץD�ӜRж��<��l���%o�d�x��A�47�U!6Z��� XI��f��ū��{�1�Å�^��pqt��/L�]Z�^�ʝ�ߓ�>1c�pq�E?��K�H�F�[BK����>���G���1Fc�7ؘ�
`�|O048bj=gS/�֒K�:m"����0�6�ۢP��z����iV��ji�To����:����fa��2QÌ�Ҽ`�lCY��;�,��]a$Q?�ضaj�E�^6\�����1��ȷ	�9�\0����`���9U�mR"��ua�#ag��u��Әگ���&XP3�6-�������+o�K��(�(�j��:%���_0X�$��O���y��G0�E�S�>�*;*�C&���j�)w��ۄ�{h1� ���^��l���
�nZ�5�&D�JQZR�Wf�buz�#���ī	oq�w���8oӣ5c0�E��㣞�O��\� ��K�q�<�BHj�� _@���od��5.F�b�w��=�����Rc�W�Bs��D�3]�&y��ذk�`Z셽RÖ7���f��U+ly���GM�=Zo��^�ca~U�jܢDd�o=6L|4���J���L����8��a�޹�=ñRI�iֻ��'�P�}�#���)����O�3�;8qURAٞI
���u)�ˎr\��8򀬐����,Y�qd��c<X�`�h��;�_��<�B/��gbU��@���jK�Ӱ�<��M$�wN˜� ��4O���"�Gע��s8^<�X�#�eE����&�Ppv���"Q��pZ>��4-3qj)��l�|%64!6��V�S����������|�=�w��E�R{�qOZ"�#�/��B)�Q��g�2>���E���?J���%��A�P�hC���X X��^�����̞<G�q�B\�a�G�OO��FY�aq�p�rB?��>�j�a���䁵���iO�N����c��B��,���܇�n���56f�1ȔA������8����v�P�{4�������!�������z|�oN����V^��~:�e{�V1~��8O4m��P�t�G���íP3x�v�V�J̯G�q�$����>������]Q���=��]���5�Y���Q�`�y]�I�f����g��^��E��6��E����j��C���j�#rb~X"B�9�e�7�bGa�]��صz}�����K�v���V�x3"�8��h�J$Q�Y	�A�)4�LK��0F���
�ԥ|w��o�c�I��8�x0�[5����0�p�����x���Q���)��˨����Qoa{��-�؏�Ф�&#��b�!�����y(�
�2���ޥ��q��6��9�R��x����O���_�k�X#��DOR�3�<���2=���;NoKi�ð.S����A��� $3=cU�oZ&.ƙ�N?�A�N�b+^�M�?e�X!}�n�`��v���T(�����*�J�(��]���L��O���V��[ƹ���e�zx�\�ռgw"J�0�K�AJ�A�_o�O�yڰ?
@g�y��*d�3���DB�mR�	����pvX`P��}��扵i�F�d颰@ι�t��PgO�>F��VZ�4����]����S$��)������Qѣl��ݙZʝ|��}�H�X��q$UmjT�$�tQL{�E�O�:�;��d
�������$�F�:2��@4�����g��L�]2��]_G�
�   j��.K�Y ���п�ȱ�g�    YZ