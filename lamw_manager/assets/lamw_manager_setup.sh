#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="555878776"
MD5="bafac10e8f989659f4b319945976701e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23744"
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
	echo Date of packaging: Thu Aug  5 14:20:34 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D��ݘ�WW �j���`�Q����fV蟵t�r6N0�9���C��M��^�[E||��?�v��70Cr��+���d�{�W�Nu�C}�@qQ�Z	s�ꗚ�?��uY�� =��j��B0!]޶��k�R�Z���.�2JM!ӱ��(~�'������z�2x����:�51:'����#�*�q�ku��Q@%��m�4F�_M�C�������ΞO��$�L�r}qE����#J6�w�q�>P����9�ͲN&����!#l���0hi˨���'�����ջ�3�
��`���!`�J3R�I�j�+��2�$*��/a����?��ǐ�(o�OL�m��~����+l�a ����������pJ5���ˍ�#NU�%��{fl1�}��3n�P�F�p��-� K?�^�s�X���S�4%��h��E�E�3&��{���!‭���&��_@���}�e��K�(�}��u��"vn���}g�	�d����f����)�E���j��Q�����CA) �p�ɨKG��a����2��"(ZD��:�A"���E1�HsB��4Iܴ>�عw7�	��`P:�ll9Z^�֒c}�}wO���I}��!]�m��jl.Q���� Z��g1���o�l��8��vߗ�hrE��[,�gs����W��9��~�/�a�X�{z9o�ŵ��P��@y���%�E��,~����6*))
��~��g3�^ZaW��c�W%,N��賅��[�i�h!������_j�q�
1��[�����mD��硜�`j7�� ���q�C�-`4����9�4�!sa_ws��Y��
��C\�;�^�Yȫ�=v|���
���z1\�p��,xsV�5E@���S�zl��pnNH�{4���V!��%9pdC�ܻ��]��%Ny]W.�!��C�du�������*�dt�z�ޅ�'�R��sQ���9Ao4��|F�0F����e?���tչ�諛��br��q����"Av�y��ڜ��	�V�y�� F'{����|��Ї��p���g���X�M�1r}P$9�z�h�L�&&	-�Ao֏��u���H`s�&��nMvD���`�s/~ǻ��U��4�0���4��4ĉ �R��\��%˓\p<����U���0[3\��N������j��ƺC�%N�])������/�ţes�/y���N����r-}������9|K���)��M�o�a޾�#Q���Z����w���i�1��>1�����wM��� �����%��?Z�� P;��s�@K���7������]<�b�n�ij�P��ů�k���̝u3�|Ǒ������w�Y鑩Ժ�`u�+J~��=kˁ�-P��v�=���T=~���|���]c����	^f9�V=^�a�M&6нԗh[���p��t��Q�7�;Y��=���(
�VRk1%��dmɘ�e��V�5�pƱ���$�A�/j�`�_*��1[�֧D�4O�8�ael�>��7����Dլ=rY�Q�����	��}��A����V�#�̧w��P;��}�̿̇/�B��JVmܗ�\T�!5��~y8/snj�c*V0���%��GT�!��m�:#���b)`���̾��#��e8�`��}�ԟ�Y<�pD�1��G��,B;D숩�d���ܱ�܂�x.|n�,��=����	�+%t�UP��g��Ȥ�/ >�#ҫ��m�a��ٷ�s)�W�����0/X�(�*x�k',F�ұ�S������u��L~(�X��Z�[�*��S���]�D�F~�Ѷ=�=��������L5H�])�Oa^yܫ�����t�<,?>)i&�R�q\�@`'�o�d˥����)"��?^�Z�џȑ�-[p��Y��ș����JV�Z���L�(�;�)E���e�C�,�K,� �(��x�.^4��n�s��)�d*�eN���Cb���	a�{W���	�\�!2�R|��k<n�i����Uf���`��nj^��s}�֓w���������Q��!e�3��4��B��t%^eMA���5e���Y�a��.��JW��c���ɝ/ÐG�}l`�|m:K�7�4�:�1�B�f�vq����,YC���l���&<����f�<-D�ڥݭ��m�°o�"�f`�sN$�o58{�"9�,�jQj�o]�/d��ٔE�x��هl����v�K Y�-`��Т�z��Q%b��]��s;���F�o��=ڰ8���Gi�`c��5��?A�?���������cɒ-�/O%LY��FE|)�)�z� ��3��|J�(�_'��ґ/����6qՍ�Wp��\Ԃ���'��p�]|��O�8��Z��{�J��4<*�6�E?{���Vr�P<�X�|<Џ���� 9����٨���/Xt�J�h�c��o�@��eW�^���)�����'����	������@U �4QO� ��Z �l�5:�,;9y� �������4JrZ�y<*���[s�/84E��w����.�w��W��N鎱��M#t�M���Tþw�FoEP��lQ�~�R4���#iT`"��v���&�����zC��ڻ�:7�IE��[I��7.p�:|�x�z���琚���|��n6}^<PU�hxU�s)�-zШ��nV�
L�1�8fF�9@�2�1��u-q۾��W�Q��ϫ��Z����9��6|H�	����Q)�v��enp"�@���-����I�'/�&b�%���P��I���u�E�y 0�h�S�m��Cuz�x����݆fz�91��#�I���� �qKl��QԌ)��J��k�T���t��X��M`�F|Hr	ҕ�ys)>7sݿ���T,��-���"�Oe2���T��;��QiR����h�5Њ���)w��0A����彷~��ZS3�:KX:EmҺ�z��q�� >��K���쯲
]���m)������Wf�h{���c���u��q�0k�ю�����+Dm�0��!��q�	C�e����!�(�Xp+�9X���.[��fE��)�5�|� ��
,�����a�h�B�F\��RS��t�љ����G�����2[M���m�EtP`+�o���X5��:�a�ïF�'m l5̢�-���bi���m��;i_�}_GΙx/aɎ��9�E�H�R錱���U�Xci�0�Tz�@�|��+D'z.i; �t�)�(E�?�Z� ��pՒ y�K"$	��6��	7`��b�����)�_��"�n�s�1V���5�>+����+٣��O*�p���6ɯ�!��Mw��l�:b��r�viFNxhW��I6 �SC���t���k!�����c M: i
*�	G����}Z��pa�̖Z�j	#�5y�mq)Ix��v��nJ�v�O�S�+DQ�)+ך��p�(� F	���}�rQD��]\+>4*U\�bH�]$o�{���Q9�\����~;�:^�~]�^��:�	��1�搣"	@8˳��<�T3��r=Uq��<�&�C�����8Knc��t�ǘ�X��)� ���z9"�wVBH�Ҩ�~Ve!u������j~�2��� 
�b<u����C�y�^��B������� �*u,'��u~_�=��+S��p�7z�@v����"���t+E�i���7�{W�4i_F���p�l+{������_���l��/s=t��^��;�{�=�Gx��J�����T����6��=ٟ�y�ɍt��c�@.��Q&��X�3�W�+��+��^h���?�VyOQ���>��ߛ�s{�_����y�����T~Tv��;+���@��h�1&��Ѣ��K"hT�׼çZ����Y�-D�������J����3�*o�/y��ZZ���[ �T"�)�Rn��%=���Gpf�^,�ш��
�:����r4���R�J�^���H�	���Ӻ:(&��#vme�pr|��Õ	�T2��E��r_{ԗ�$��s֥4�u<h�Y���1�࿰�wd[�B��_��o�"-5[R ��^����M����i�FJ9<�.�Of��`6Hl��zfx�Ы��<&����@�B�Wߛ�oT�p��v�����6�`�7�I�۲]��o�n��MĖ�����.������wRX�����������1�k��t�$/�rn_��z�����ܒ�a,�WQEԎ����xj}��5둿ϰ��+L�,-AU{�V��bl��i ļ��:W��dl����=&��=�&�����u�����h����}��)��7]S]W.N����4�,Sw����*�i}�5����o)g�<R �4����L�|h�d����0���C�ܾ�c�~��pa4ޥ2�J��,YE��6ֻK����v3�)(E�;T�İ��Z`���_^���Ҧ}�v�0�D��n��o�>��nq�"�0|��Y�.訆�^�Ay�l6��E�F[�	4$.̍�P�bi��蟜����v���3�DQ:#�f���dR�F"�٭t��];˚1���}�aSl����H�9�>5��w����1ҖA�<$^-c���y��w}�Ҳ��Q�m�]�/J1yqT��됩�^�˼Dd���Nn�]�QQUH@��e%�)P��]�h�\��������&�:������l�=��f�"���8I�$kj2����c�3��4j����c�K��B$wf�Fޝ>��>���Gsx7N�.�9#G�q�?���Ř� +�D/R�j�|���2n�жW��]�E�e��$��yg�ESM<pQ���ll��S
���mt����1[���.^&�̿�~�%{A9���5�9��=:Tp��>DJl��Te+���4��u�V�a*�������_f&��c�z4#c܋s|	���r3!̠	�6��� �'XcŲ�|��2��!�y��hՄ���Մ��~�n����)�ٓM4O�UN���vR���5�4&�[Á�<�V�[P�������x��֥j��v�#�����&�T4ȸP�c_Ԟ�/2�'u2��4����<YkhA��Změ't��x�V�ZF+�w�~U�x��;�j�a�/���	Y�e���e\ֺ��sJ$�^�f%�a�+��x�!?�B�3�'� �
r�@UH��1�`ݖ��x��u֩�\ґ�Z��7︞�$�|�f����7h ��p���u����#U�
��w(���f@\]銅�)��W�p�.�*��i��p�e�W����3�W��ǝ�B\#�=�A��c㯡�����N�/̢���=,�����)�\�l��}��l�8~���a{
��*� ���HZ�R`��0�<�/&�}ʴ������T���K�D�<\e� ��/�y� ���,�D�[����A2Ҩ���s_O����û5l��>9�p.L�{P�^0X\��K*��w�-=5��n��7����V�5m��b{F1Ɲ�/��N�ťVwϣ��Lp����M����\p��?��u����!#��<"$Y�߹�zFsl�|�䅶��j.��]�Kf�2!zD^�q*�L�<\�j#��)�2�0��wB��������&�����!�`H���d�?�U��ʖ��o�lv�C<�'4�9���=U���m/3ŦZqu��d�P�i7(����k�|qV�AI�Η��Xc��������{k7u�UT�T�,&�.��L�w����!������A>�;�}�|e�`xB3H��퓲�J5�e]<r��	爽�f/��Pƛ��p,Țr;�4��2�hŁ�-w�k��wb��j�\���n	�X!�����X��$L@��B��i2[�̸������*�pQC�=]��t�p1Z����b�nW��B�U3 �?,n#%~��	�C���$CC�p��Яa?a\v��Ҁ���T|??���ޒ:�;FP�Ywn0�bm;�(l�A9^/�ئ%�o�Sy�L%P����J��DJf��3��1��{hIaLCd�<��K�c*:2�K��W=9��?|*��=;Z�8ƃ
	���`��}�w��a��)�'p;);�����Ks�����l|(�������j��&�0��1 E���?���-M��k��Eh�Jcq�����iLrƼ(d�V_nCqI@Yw�+��?�#�.&��7�5^F����}� ����5YYU�%1�vc�e����NU$�HJ�|� ¦l&F/z�s�i���w�wAp�?TU�=E�i�pa��ݤH�U����*U1!x��3�l��(�EV'�/*s��(q�A�����-O|�:D����1���[��AX��E�m���5�:�d<+�a�FѰ�e�o�+��`�-s׌~N����y;���_����lq�-�,�1�(;hZ�������Fx�6J잕�K��h&+P��ya��O�,�MK� �}|�X���"Q��}/B�}4�� �|6,�any�nsY=���_�E�nB:�w0�E��C����!�y��ɽ2��ʢz��0��|��C�F��X~�.G��Y�#���cщ�~����|1�|�+���5�̧���ٺ͍�I�KV!Rl�?����pY/�.K8���)�Y&Ӓ��z^��C3��sW ���E�%K6!+z�j:%�sp1��`1pEv�~�����'�(�k���2sj�U��{�yw�f=�Dx'[�����3Ú��u�	���[�P�H:(Z2��;�\��s 5��z�$:wVw��\TX(�u�!ZҺ-�W;w� �sv�%�Y�JZa���2�5��݃V>������:G�C}V@�s�Eq�%|A�ՙ�!*����:1��b�w�)�%d.gߒ�޺��(��B�̳ $Wʰ�M=elO31lЭ8�r�ʭ�?^�h�ew	.�7'M��߮_�L��|�}Ю�Us	�04��ߗ����8|u�Wo���c}��4��0��%P�g��~��N�K���X��{��ɨ��w�u�{�~I~�i�O@o�W��^H�*�S��@7�h$��G�s]�����3�G���1�;���Rd�bW
Q���9ǂ"-�ޖy���*�����[��f�Ǩ�F�ӌV��k6��+i�r���Ϩ�/���!|�e9�H�Fï?=�V����ľ�^S^U83�㔻%�f|�ȩ?����=\+yff_ɺ��Ѿ72��)�u�:z@���8�1$��@�u�u�&^Ę_=e�E�,��:.�M}���k��_x%��A�7��WהE�;�e᪠$�k��e�~嵻ĤTheʐ�4�KsL�q��v
��1;��9��0���]��O?�=��85q-Y�ʒ�?٨9��G|v��ĢO�]Ӆ�iO�����^ʢbg�����N������\���s���
�I��1�
H3�a�y��'�y�F�[<�;D�å�e0��@_I��Be��/�����h��d��+��MÂ~�(�����3t�\�+8�y�K�����L�]���)�{��L�+���˵R#�i���/Z�NH�tR�cp��	1dg�Wr~�����8;���4�N�9��?�6����
�+�Bv� ����ā�������^��v�7fD*f{��y3�����08(�C�1Os��ch*Tً{]b�4亶�y�(�fȚ�8��&8��^>��
��!�va���5k2����^)Vg�i���F�,9���#A���_v
ƫo8�ݿv%��^2q�z���I��%�<-�Mf�B뽶�M�h!�1!;O�y��Ú�*��e�A��u �Jj�$�[!�z��I祇ϵ�U<Rs��w��e�]��w8�*��1�>�蛇�~����;�/�	LR��(��Ǚ�ք����0z̨z*e�[s�8=��N����B:tT5����T #ś��j¯%ͪʠ�o��;��c'������4$�p�+i���%�$� ��Q-m!��ް�ҟ�H\����n7���lM䐖��.c��8\�>���>�.��Q���!ݨU�
6����N�EcƝ�-�X�l)N�s���g��P�Q�pߙI$���*7��rI�ڏ@�4��C�.�Q٧<g"iL�)(��3W��G⎳�/��� ����W�� �?qn����<�+�)^�0����(�X� ����ZU.�]cڧ�e���%�Ef�/O>�VDP�G"�k�Uā*m���o�}݀2�E">�k����mg�����ۋR��.bH��I�9Sk���	�ŧ�O��>3Ʒ��)�g�*�������P�����K��>\�����#��n�>���6���!�?���b������q�0��v�)50�RW$��`����G8�
N����Дb������`�.��r��auHG� �B�(#�9O�-PSf�25�KD�.D�|ۯ�_2�L��ڬìa����j�EWo3{Ŏ&������@ ��r�G��F]�ҫ�
T\7+ʼ0=��ԁ.��ek�?UY��+�E����Kk��h-��s{}�n,��0.g�iݬyy���@�]�4R�>z��B�SS��S��uϚ4,t��r��Ӳ��:�@NC�<���ȝ��.YF����B�����a\���D�B�4\�oWF��zy�<��GV?gA�!�?���}��a�&���h��s{RU1�	�>��^Gp�������wD`�}E!g�~�b*�s`w��'�`�<��r�tkA3������Ĉ�>��c�ʋ��r��n��s��z�����܁�$
�D��:�֏ţh�v��o��L-g�ӜP�\�d��j�"����h7�6�>kn�c�]\�؄��A���.����=4�#��yK����FI�rR��c���vu�:]P�s�K؟�vG��I�%�r�/7��i�����sz��N�iVO�K�}#�Nx>ȩ��}�#ILf�a�H՘��-�����"������iA��8�8��|��&���8\"Z�]sp(M�eG^�tl�Cx��ۃ���uwmO��k�Mj�¹K4tS����h��J�V=OZiz���pL�R�` �e�	�mg�f�ܡ������R��Q-!v�'��z�\��մ�LeCu`�ӌ���O�^wDg����
"�4�:�&���1B�1� �è\�$1�m�	cH�ş:�L�{-_@�=�k÷�0?!�1��V�H� 搜������^�Ձ�G�(�
��C�6[��"���~aM.D�}���N�?��K�ƃ%�C���\��&X�Z��ݜZ87�5^�#@�´���Qt�`oh�=�R��g�4�U�=e *��i���`%��^����~|u2�q_��K![0�KNM9#tp-�Ѓv:�J�X5���쩱5���3�~��B��H�^t Z���
��{�ua�?W?#J��䐭���W�
`*PޫSX޲���>����£��s'�v�5�2Gr< [��5���8�9�A)��U��� _���ܙr;��T	�\!-�
F,��6㤮W�i�^@��D?o\cS%�޴�I�@0�o�m��J��rn�D�d��
=��a�o)��SN5F~\:��'�9�ē���-l�ǥ�Û�����Kq?	����};t��iD�>���O��[i��D�Z�[�8�0�3����:�u83ٔj����%�cBN=F�N�7/�אW�0ۇ�R龢��+Troy�glڕQ
�QhA�=:�d��Nv�܀��
�풾���.���6=��_�J�pG���v�Z����.��{�z��{U����jz���ħ��K眦��R�Z�R���7,�l�=y]�1��|30.Ԏ6�4a�j�EV/
���uJ�����W:�~i�����ٌU��A>�9B�x��
43t�X�kg�R���r-��oH�1 wp��^;u}܆�(EK�FƗ:L(��Ç��<49��hl
��+r*�-5n��׷�1d���ط�Y�̓�P-a�z7����-dӗ�,-�����{b����+�6��n!)���|F=83wGO9���X�����Y�89B���Ѓav�bɬ�X���@QS�#/z�C� ������9�k?�T�#Ern=�%׃�m4a�L��QS�p��_VLĨ�=f���/6&!�2��>#��d�7��?��������oX���4/��hW��Z�n���Q�а�*|
�R��\�b$纇������S�'7ĝ�q���M� Yij�X���#*���]-֔fނ}��2z���W�l�B���S�UPH/U������V�[A ��~޻M��n&�9?�܈���V��n�Ȅ=�����kL��
�e��e��A�`#\|���7���dМ,&2���3"d�� ���Z���S��F�s_-?Y*��x�z��V�����L����)�w�� <�I��L�����Q��at����1I��Ϗ�{��"%�`�����t_�����!�B0+��,���Xv��ݙ�[Db����Ҕ�K�� 	7��k�s[q⌕��Ec����>��v8Z���`��t���΄��0�\IH@�%���/Z	8�#��� S`�v���a�B�6�=��7�h@�M�!،��ڈ"g����� R(pL�A��ܱ��%�rr�ɐ������6ڪ��p5�`���p��n7,��ڌe�N� �]�b�&�8��nQyeW�����7�B�L�S$�S�'G"����P�_3��Z�b��J�;u:T%�x ��=��2-�F�xC�2���)��OY�.�w���_���Z���ʫ���j�����)�ش���p��U�OϮ�����BQ�'O`��6�g�?���g�h�)�Ϳ����௥�\2������ ���b��/D�z����_Ğ��>I&�8�$�]�Ӽ�V�5<S3�T�?����=�k)5�ZZ{z��$z�p}c�4���� 
���DV\1|�H,���'r6!�7jX�y���.���E���wzɆ����=����6;����lB���X�R����J��'��jNN=Ǹ�����HO���=��SC�}���Z\	,���o�*���e��Ua��E27o ?o.��G�߰Ϟ�'�	A�����D⏿ 4��T���Eb8?�|�~�BX%_��[�9�Tp9ѽ!t�������w׋rЍ�·��|��Ly��nध�_��:����ŴS���CuE?�ܼ֊���Zg�VK�Js�b`J�W��Ue\Ո��j��;ɖ�P��3��5t���!A��&�s�����93g��T�r���M��'��̝t.�a貰�SN7�Ϯ��~����d,S!֍8s����O��3��PO�k�$,��	Cd ��˝��S���G}�����!4�~%����3Ĉ��G��Ӝ��;L���8���0`��3�	ĒsUٶ�ǔ1m�0��,��]���*!횸����Qtɞ�Zm�gC��s��:訟25���
p��;)<I�r�ݣ�r"�L���A�Do�%���P ݢe��t#�lu�
��|A�#.C)�j{��eF�	1t\d#M��fL`]�jvW<�ť�J�1<p�H�������94K�~�ʠk��?,��;��\!�C´
�6�9������%��6�׿�1�+E��>&����ȇ��6)j���_
�d�N=S̥���K/�\�!��.��|�<]�/����^�MVI�M>��%��۹����wv"���pF�(A���yI����%���G�;�Gs�FP��'��<f�y��Z���z�K�`,�½�d7bM5�M�_�N>5�o�UP���
1��c����L '��p�����4!����l��=>�[R��"N�Y:6���8$��{d�Sof=>��;|����Q�@��*�;�`��t�`�����:柘7�ѐ`P�W�[:գ/9�vtP����c���*����
��P*F�"�`�ڜ%~����i,�҉C��ݐ���LJ�8 CI�14���ڃ���qͫ�@�e&U�U32�M��y����ڰ���K?�6s�H���9�����	�`<�g�}�2����l��1W-����KV�Y��,��I*J��8P����|���r��k������������|W�H�"7����ʛo{Q��7���$�D�j&t�I�-�� m�E@�,+��RzZX]��"OxQUi���\���+(V���F�8^�ͨ/��f,�Z~h�W��D�)�1�J�#P��H���.9�t
<��"��$fz�,_(T�eؒ�nϽ�s�Ua[6߽���G_���#���m�$��IQ��:~}��t3���*yO���za#�3x]P��8� ������\j�
�_}T彍U=9Ɖ�}�Hƍ�q��c�%'Fgn���g�m<�X�I��yya��ݐ��<ag�����U@�r#%�%��aT�C��j�3���u@� ���-v�;03;���8!��2E���ȏu�D�9�aV�/ a��M�eVr��P��Օ��|}�� ��*���w`K��2��6��3G8������B�K���N�2<|��y�i%u��j���v����>\��[�Vh����>��TL�_'#����u} ��]��D�G]Bg�y�O���5�*�;�t%���,J�����ۓ���a��Yv���5 ������m'�?�:�رe��mKV���F�J	��z���jx����9��ck�5�	f'�&�c��1ŭ�pO#�|���(��j{�1E�֓7�R�V�d��g��^�yX������`���}I�2��l�+P�Ǟ[|�� <q�H�H�%_���p�r�����xAY{Mt��ȡ�o��̈́Q^@Ry\%a\+�{�Nx�UC;vdEt�C�q�4��Qm�=/��|�9x��74���ݸ�{$���~��"�6ڮ�ï{uA?8���-���"���v;��#�cc&��8o%WV�i��;�2H�2�ˡ}��"��|cq��@����>ggB��˙B�[����2���`.�JA|���uf��ƃ��)�����R�{�&� \�弧A�X?J�- V�G�-�.��Ii�}��y�v4a:�=������(m
�[@�x%&j��w�w�
��r1q�q������/(���|�Q����z�a���`*[����T�~"�k�8b��`U)�ߝF#Qč���o����k�W� ��j���{B�W���P�)��#w���1�]�W��﮻Aq��kW�Oxϭs	K\@�]���>P��Z�Rl�<zE=ɕC%	";K�
��s�������ܩ��K��1���Ǩt��I��/�[�������#W_:�[L<M���'5���8���?
�PF��ԩB�x�V�Sh�G�9�+�T(�a~h��,��'�M;~B.��}1.��h������ꮶ����銆��;L�} �v�ءk�\��I�l�O��
��S;��G��5X��*��{%Y�v��ͻ��VBH����譔��	8:c+Nw�v�E�l�C0���#X(����������0(��Ƽ�T؂��5��`Jx�۞�ކ��hY{p5��pbSj��N�'<'K[�_>e�uT9N������Ԗ�.}�>wk���������_ �	��c��KT�P�FdI���?���`�4��7ۑ�:����6�D����(�\q6m�,G������);��G��$`�E��:�YV�&�r1pa�XH��y0�H�=F(�q�s?�%����x�9Y�-*j�ӯs�Y�B
�~��q�9h�T	��:����Rf,��+"TZ.ʻ���,@�t=X]a�G׫��,�P��R��c▓�s��$��zH{�^H_�%�ba��Ψg�B����P:��ղ���A����ZI�}3Im�}�u�ߔ���n�qh� �b?��h_X���Yi��Υ�MF���$�#�ـ���`�{&�z��u6�7ڔ��L�F��w2��D�Iro:�z.P���_��l�+a!A¿��#nx���pc�s8�����2�7@��V>���j�O�MT|�+|�*_(J�r�
��jNd?0��]������ec�����X�t�Ve-���@
"��:"�Eo�-� dr�-ξ�̡M[Q�{�c����'�E$�'�̀�s���o��Lݾ�~�$�?�AA<}�YuR���$�K���I�t��D��j0X8�~�-�fF�z�T���f&�fMh����_������N��]��z�*]�a6�ǡ[u��N�;��{d15�u \_�J�p{�]�j��r�yt�D�Qh���R���[���09N8�l��k��W��w����o�P�.�lE}��)���{A�P���Tz�y��B�C������@T5<�ȟobi����
�k��o��<�L��n«8��o4�@=�dS��+�Ԉ�Dc��s�ȊP��0Rk�{��{�׸���a��� �%�9q���4Zs�B;(/c��%�����հYg��~?W}^�s\�Yx��}�hl��C�؊m���^�L�,�Pǻ]@�"�0I��Qr�KW7�P���l�J>$��\`�'*"uo�W|���6�t-O�����ڇ_�.��Q�}����54������s6#�&��C���t0�-!��K���o�g�_� J���?��3p%.� �7ҙY�Z@���F �(�� fDU�K�2�E7��`�����҄�e�|���j�Ʌ�=����>�[�����6$�#tƘ[obB1Jm-�C�6�Ȁ��5O2�4 ��po�p<�捾�ؕ�^�P��J��Ek���y��}��V=�A�s5�/�OKE�J�{�������)]Ot�#0�o��mQ�)U��(d��5�*0��׌��5����U?�'y����'!�����Q�8��ˇVrJ���t�Qg�'y�/��$9��͈����p��'n�y�c�v��J���R���y�m�%��f �\�%L㖼O
����^�a^K��n�����?R7�_��ט��b{/X�y*�}����1��

�싊9K�3�+Ov��_"<�M<0��PN;�$��Kwf.jڟ9���ɨ^�������
H�,����z��e���Lf�� �J����T�g1����� /Zռ~K�H:^B�"U4`���s�A��ٻ2��X�F0��:α?��O��f�MU���SGr�a`0U�!M}&3����8e-͐���/�ٍ�@+|&��ZXlը�"�K��+��z0�N�c<J�*�;<Qa�4�"���6�YwN���q`�<Z7�%-�������8����|8�y�	�@XͶ��CM3���L�1V����n�g8NR%g_��ԦB�;rI1w�D�7�']1i6Q��v�FXhe�bB,�U������J�>E�O�-L���R��<T�wߢn-s,d��-�ta]i�!]a%.^�����`xe�e�m��ͦ���Vs\���IBm�W�P��7'�氿��ݖ-҈_,�9u��%
P��´�s�q�d�O8��;���D�Xv&��v�!`A�����g�X��Ɨu)��ԩ�ϗ �zG�/�B��b�;O~+���/���/Nm��o�A�=kŠ�.p�ƁcGw�H�T�K�1����:j�/i����ofG���!���?��v,VWDq�/��oǃ���!�ED�l���2PO��5�ԯ�O�����*s�-�-�d�����_�nQ;�o��C2��w�n���}��	^Dy�\��m.�r
�o�iē�B�%K�dh�G78��U�YE�����6�߹W�>vlu6
\
$�6/c�f�������2�����Jx8�����Y���3%(.����f����Ų�u}���'S�F��Ϙ��.�a�.���_������۪��z�ӽ��W8�z��f�+%+p�ÿ��U��@��Fw��Pv9�m#���'���*�ݜ+B:'�[��/.
�O�kW�k�!��_\3W1RO�<�XU�Ky��S�F����%����QW�"t,ƭ,���^>@�����t�/!q��qLix׷��<6�n����������y�%�+A�@�Q`ԕ�D��|��B���D�$���］c��`�t�7b�9ZPv��t��A�h}"��2DcP���bqs�4E���b`
��0l�q����r�huB�N8�,��ܧ��6b����rW�ͱ��]:���V�tqU�Ijȯڷ�uɭ����s�Z`�t�����>�"�)ٱ���Kʲ%���[���V�D�i�b���AX������2�u�0�.�kVNDuo"��#�ֳ����iy|D�h�cM�V���bʼ����$L���J��:-����|h�)y��DI��5�p����x����Q�c.�c���B�4��]��(�h�,m���j��؁���U�c�Bt/�y��)�|��Ei� �.=����袙OGѠ2��I�t���Ж�3	�>�����2���P�1`̲�( �5D[c��] ���U��H^ay_2�ӟh�4W >��WB���"�=��7�?��F
����x��@�M�Nף
�g�ڢ.����)�7	v�i�ĭ�f���|6}��L�:�q�ź���h���~�v)�P����,�E�=����T��NL.���9��e��M��%��+&�`��#v�ߍ��~&+�l��l����\�*v'ާ�hʿCy)١�T��.���mNnLq�w��,���\�L.��6�ٞ�C�J��x��n��Ւ�,5
��Kſ?����Ҕ<,�br�cX:�t�I��Ci�i�w��TY�1=Y�½�rt-r��2�����
������,��Or߽�l�RD�^>_ۋ[Z�ੲ&gR���꧿�3&��8����jn�پ���L4՟��}�eʥ���f���g��Mf8���h���D��L5�T�F���-�1���ay�8�$aq����o�a[�*�8����)�4��$��3vxi�s�����H1��ݰĄP��
Ϡ+?Գ��@��+�M�tQɣ�k����@���3���V���!!�zە��������?����3�o�ʂ��;�JM�6�Xu��n�QQE�(��\]���hܑ~�+<���4�-㮰3:���G�!z5�F�͓͡���Uw��1�f�*�W8���*��6����Vw��ʭ���X=d��9?[�rc���V&>ð�Bҷ�Uk����r������37�{ y�z^�%��`�^@8ѳZ�_�[�1���	����`>�^��sye�z���q{3�@9G�%�\
�T��X9�X9��ojd|13U��"���I�muk�Y׋H�$c�=��+�<�����z�`}7Vgk�e���Q�L�ܔ`�r��mN���ֈ�*�n��F��o��I���i#�,�Q��L���Nī�<��/l���͂�&;Ԟ0�cc��!�e�+&��₧tEX����c�a���VV�p�����x�d��D�<�y��0g���	��(�tYy �C$���|�y#��-`��6��:R�-�N^|8��Y�|���{�B环�Q�	t#���@�sK 5��>ԝfN����5����nq�@t�A��^珆�����t)��n�.JtA��?�~V�i;�V��?T�_xE��f�Υ�f��U�G��
N����%@�b\B���:�?qH��\Yۄx��P'k����RE�ԟ���_�Sn�/����h��T(�(��ⲁ^Ohʊq���x�����.�O�E��&����g��$�N��|p��+
$�aNb0hL*���<�|���_�ntCi�l�N_ٖ���H[�� ��'C������y����������Ҳ]��3�b�����Dn!��ku�����%b�nlh:�R�Fm��,�/�ɲ~����/=��Gp7C�{� 6���>��ڐ��c�2������<PZƹ�����,��[�o���-7{�S����l��*���a*��N�CW*�ᓢ�ǰ]�xڐ�b��L��i4������_l�q�=h���ֺD$�eK9{j��CJ�iץ��3��	=c@���LoN�U����g6
�k=rz��jȄ��pN��� �5B�g���C��o��9~̆��К�·:�9��x����׸e@[0�]�-L��6�����oÍY#_]#]ʉ�VN5U*B4X���6)�XQ�;� �\��>��N�ӤZ{��26�,T�U?�����CөL�d�i�f."f���z4V\��"В����^���X*y*+�59�9�MU}0�v-c���}�7���l�n��{��E���R�v�ZpW�s����䪸�)�]�����޵��t�[�ey_/V���%e���󷂒��`R�$ 6=wT-�W�AV�Lc�d�k ��Xۇ�%��R�4�'D��.t�)�]� ��X£��E�WL��Ta:���[�R��U@]����0��y`x���Ţ7��J8$�h�+��u5����]�8(K��b\@��]�"=�	zR���rSLoW�?��1�[f��V9��e�[|�һ�]�ܢ�I���[���AF)ӷ/�:(>��9�Š����
$��.LM�=|����^�մ{%�`)e�A��iu�f	P��BbQl��`�ΔR�E^���jy�{}�F��Cl�1���i]��� ��|����6 N/��Q\�K��#$�QDW�(�B�$� 9,Œ�&E�6�i*��
��A�W�8�U�,b�W&�H+�*�A�Ϛ�;�"�Q.����[�N]�'���o8����{� ��kD&"=��s�=Q� ?wMCc����Cq��+���Ϗ�s��o�ȵ$�RG�����=��u�Q�ձzX?��3�����2[�uw�����Ԯ�x:z�������cH��qN��Λ"+\^�|��5'z�ے��u�����B����Ğ�: @V��.~�j��Q4/@a�&�|1<��G��Y/�g#�i��	.V�\��f���M �>ۘ]�s<{���]�����i��A�;�ę:Z�V��cx9륢+t�w �i��v�z�����"+�R]����wAC�@�.�bL�1�g��[g�7�^�cͼub�����r0�<2-懏���bRV}�DUx�iW��4��$^��K- �1@���J�O*k,�@ ��dg1jVZVA��'�hﺤ�&dF:K����w��J/��r�6˪�ӟ����fn%h�P5&sX]L(�����;`e\���p� ����4����^i��@��oG���>�ǅ�;�Ԓ-��ot����`����vJ���ʜ��Lf�U1Ő���N�J�͉]�~Ʌ������`ю�~N"�3]��Ķ���chƂA�-��9���k��u��7#=��$_�)�0<i�m{Rx�f�5��H���?�r�7(j�&R-X_X���jm�'B+�O!?����)�8�b�����rĀ;alZ��@0`�����*�=zn�_�L�]�j�mG�	�j���Wj��4�@�U@����lfa�h���[���;�8��SD*�Fxݢ?K�S����_�X��4�d�c��ݶ�h�xcI��1<>̷"rG>AT(7>��=�Y�~&��O\:�L>}i�ܷ[��`^>k{�m�d�<$���Am��?�u!�+���[��wa-e��fWD?����ƞWI���/�nc�����k�����JgHְ��󗃺��T*`�i���?`���0eL��Ѷ���3x���M3�w�Z�'��V`B�հ�R�zx��ﴵ^C��qz1#�Z�
.�%k_;G?r���^\z���e��V����D4������`��+B�Պ)�`Ը��V�B19�_L���*<��&~����v�! 8x��^9%���t!SnA��
��#��}��iq�^�R	8�cr�{K�!'ՠc�цX�){�cSD_��U��]Bd[��z4`[��CHb���kn����6n5���s�  \��{Y����ŵ]q���y!?>�#�cJ����h���§Ym�Nkʹm��z�e��#��<\�{Q��`+g�$'m?�RūM̓uް�K�R17�5�a�.��0g-.����cDPn�G�s�%'H�ނ��� #y�Ds(��XyN�;b�]�h�*ؖ���H"4�+.���q>����0v.H�Z���Q���dm�"cN�)#Hm�^o�ץ��(��m$kE�i8A�P�s?���qF��-��$dv㏺����0>�X4�<�w�e9~�/��''�t8�1є��{2�)�Lw�Y�3�?��� %�?h%OK:@�i��v�T ��b��>����	����vZ.�׻�;�Bq����9��S}:��������۾1h�Y����.�R[J�p��O��0�7�%�n�e3�#����f���#�m2��e�jݸW�J褤P;�=�ē���6�N}��v-�<��ԏ{JP񑅾�#�J���)�MC��4����;k-��q'ɠi�9��aQG_N�¨R~�ڷ���/�$>�
_��M]`���~^���<�'�����E��*��f?uB��I��͑cX�$�[���bTapT��X�6_���]�J����X��&*�~A`���	/Z�ȋ��W:�9�G��=}2���Kb�[�I��kT�P?t��A�@�YO���%�d��ҙ��, 9�3y͊�z2Ii�.2����"������{f���.�U��� G#���P8������k��Ô2����$Χ�=0{����^�t��J4��_�@�[�'�̯	�3�ŵ�N�S��A	Ӛ��R�S��m��E�3��'���CΈX��\�q/ƶ�d)BR��m�,"���.O&e�������ư�ٸ،������"D���l����dO��U6�1����jpo�V�W�c��5N�6��%uH8vqWܔ���}��sE��*���#��Ag�`� ��t"K�|W#e;�G�a����H�D��}��M�Q>�&�I����X���f{��u�t�Y�^]��tj��[���
��br�D�	 b3�w%H����� �a���t@���b,����d�������z �Xq�if��"A%:W9q��w�B��i����jC�����
��� ����S������}P�.-���S�f�c�CZbM��t���Uw��P3 ����7AW\,�/�أQ���5L9$E�Ȩz�eU"�@���C�hǒ��G�z�"׷?�a٣��X�=*+r��it�8�݆��ǚ�_�cTw@�P��ֺP��W���u@�<�����*j4�����뾂Rh�{��,�k����Ӧ�&R��w#6(�+";�. �ZW�Asn��j�=t�&���;Î��L��A%iwI������?P���#��8�9�GQ�jʹ���#��f���i���z>S>�/ ���q#uQ�.=tK�l3�t���~������N�2z�}H����N����
�F�Ԃ]J��S�Ꞻ���:�m�TwTDz���EM��������5����2������@�Җ�G�KV��A%Z��������,�<eN��I��HU�S������G�J��3l��.X���=%�mBJ����#�A��k�X�+�xˁͻI��BR�ր�2�Kϒl��.���+cח�SŇ�,����RB��{�"Z
5\N������xo�ϖ�����|���f+{2���^�\��x&�?T��\�9�fV0S��ZUR3~�83�Rd S��t���v�ZΥ䅈5y���96M��#�3oc�FZ�U�f2�J���ȭ,�#1�([_?}\kc�SRu�����6��|e�QNh��6��ʛ�"S�$ޕ��d�tYz�?R#rU����T��hى�A4��K8g{0,2p��X�d`!nh�թ[VnN�H�X@�������7yT A�͞m��`�<�
V)�mwB/�Q��ҩusq%��ˉ�7�p�w�._f����\X��is<��kKWy�QN
GV[���P���� h	9o��w�-��K���(:�y(O�@��b�H�N,[�c��0s7���m�#��a(�V��gFf9�<��,�������Cѕl,"V�s�ahۼ���L��>.Y��u���:�W�[3��B���)��dOT�\�F����D4�R�>�}�V�(��F�*څg���E��ʭ�f0��t�Z�����=r#ۇ�"�C��4����9�gK��2�YÎ���U)f3y�Ϛ��$1��Ԋ��+'��e��5���[L?���n�v�%z��(l���RI�����H9�Y��������Y����z����ZQh��m�;�V3ɂ?Dc-I:xH8l�a�`^E��9Oy<���4Ox���y+���*���-KA��4�(���)1sy��u�x��Y�%V�̓�E�����"����]Sk���ߋS�����S�9F�#q�_Q濆0�eћu3�-7ly׵A�r�����Dl�u��]t;'��`���>�� ��ڳP����u��u4"�'"�O^��Z�Q_ӝ����ֆ�i���Lns��݀���?��qG��Kqf�M4@z����
r`�=��u9��`_�c�-X�A����(v�d߷�Z�:��s�I�y��Cy```��^��)~ӏ�G�F/��N�rsɈ�eo�3g��˼h�a>���X�Ex������F།!��V����D��f�
]ڳu'�_��ˡ\w��G:����]�AO�D�#Vѻ��m"��Q�$7�Q�oڊ�B��n�zX'A��c/"��8��+A^;dH�8%p�*����s�6ʽV��c�f�0\�����@{��u�� �|̞[X����z�Pl�[HU(�5b�$"bM��\9H�z�8ڹ��#3%�tL��Q�D� ��)mo#Vo�"B�����`��,�"$�q�}B��g�YV�anv�F�J������=s?qpU���,��E�]\���Co�L�"S�D��Ar�M�T��v��1h�D�yL���Q�A%��ş��J�w���\yR���<"M�����������̐�iM���77�p�LK]�c(�ZV���d��y�x� ����K0���5�hh����]�dn����j�`T���o&�+�
��9v�;Ȫ�^�p  �ǢB�2J �����V1���g�    YZ