#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3180245651"
MD5="3334643c3b8b40a7f0340a0237bd85c8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24528"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 18:39:14 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
�7zXZ  �ִF !   �X����_�] �}��1Dd]����P�t�F�Up=���P��c����2��mt�g5͗��Ĕ`U���w��ӴLN�y�œ�E����z������T��dxi���jP��e�ś��@��L�|T�V�Q��}	�6=Q�Ԝ�u���Ebi����%���˳;�)���z��/fUl�;�-R��{�p��rD#7�s=O��}��o����)6���
�hE,�O�Dt��GX;��-�cTR֌:����������R��	s���H�����=u�T��f�m8$.���~N�����Co��������}�$���*����^����,a�[���V?I�����>r/��SV�ȇ���h��
Z�q�iQkI�CN�����l��U%#�=AN2��+Eate1^I��-8juX|̺��	���;6G�~m`��P�dY��a)����3jr�>��|~�N�e�8�xM�9m�c��òl"����̙x�P���٥������ݶ�%��1Q����ߏ�2�C��y�[^��O�	��|E(�"42���a%�����$Ÿ),�@rR&�Ԑ�:06{S!my�JX1G�ۛ�~3��ܮ�sF>�I������H�
!���t�_�b��+{ѧ���� K�rn�I+���d��2Q�$��ST���'��O`?��:�]��+g)H�`χB�*��8��TG��gG�`?����9i1�������Q���pՇ`U1#Pj���!üm���w��Te���\b��rP��c. ��吿KtD�ڥ\2�R4�Z�Ԗ̟�>�\< w�F%TD�d`�8�)vj5�=��8S4�4Ηa�(���؛)?�r��e;��݇���=��e-b����O�p�O0Nn�S�g���B�1�xcH�)I�����g4�.���k�bZt�J��C((f����d=U�!��3m#c�����P�e�7ū���r9�|y�4p�T�7���_@g��}�B�9�;�-�������C�/+�c����o�`Z������H��_�)�k�S6>z��4��odV�{�~~�|WU�p�&=K��~��,�Bsb��o`��)Y���$on�×��p�gח�*P���Q��TEw���vh:N�d��nE�pD��F��\݅1)�TU�x��}s�D��9�v�ſ���k�;Ne��A�18���(�����FW`y���<��Dqx�>�u7����!>�0q?u�<Y�L��gƽь~y�f0y�c]~G,�oY�Nk��J
�#�·��Z$'O:Mfݑ��{�&�l�/�]�7զ�~i�#C��*�l�x4�1[��<!�{��n�M�MQ@D�ekc��Y��Ӂ���,���t�,��x$u����
�,:!�3�O��������t�Ne$�CK0śCCB���A��Ԓ�S�*�=ޥzJ���1��� ��W��J�<����C�L��3� �	������:A�0�ɷ?=���+�sٓ,\UF����|��G	M}P��ǻ�)F�z.X�?��4�o�V �n��t���h+���3�1�q>���+���`(�^�L������W�y��m6�/`��"��j���'��BOa
�`ϵ�}w�sp}폫{����e�g�#��Ӏ��e�����w���i/��*r�,��j��^hD�f
ś�G�����@\$�$��+�/x�?�VXӣ��I���/+��@:�/�ۍ�$�e������|�e�(��B\�gGadP����e3����0�+u�o4�/d���m�IP���Z��e=�+���˞��hv����Ҝ]����ޒ�U�����DX^�*]^�h�`v1���%N:܋If6�ڂ�N���'��,�]����1�"��Xj�|�{�ڝ�/Ѳc`[J�P��h�g�~ ��Ҡ3Q5q�`(a�n�����	�>,���
�,</���Hԑ%��;?~�c����}̱����Z�%$�ZL��(��j�`���t�Q�rU�)ya̖Q.0����@���� !?F��&����w�?E��\��Xc�g��Ut!_J�s=鼅�a�Pp� �~\ԿF��,�w���,;�"B������Q��cl��?��bq�;@ٍ�~�>w'ɟ��k����`[�>v$[�]�1�=�L�9���+�@����.��r*z�a(�l��ebl:o�����3�^�YT�S�}�ȅ�B�P��=�����' ף|�+}2�`&�Dg�T����Z,_R�P����"¼m�*�+�=R��s��Q��f�)�6G2(��;�CuZ���5����\IO�g�Z��A�(a2i��Ǎ�^uq�:^�|V���R��n|/	b�u�D|��5E�r�6$��` ���U��ư��	��"�o������iL���:�:�>�|���^��4:-�C����l>�r�c���Z�o3���N�&����e͙N��*q���<ʒ\��{\�Ŕ�̩�7����r鈇��;�+�y*�0W��`<�s����	�7��aOM�QJT�Jwh�^(.�4VԱ| ����հ�0�� �V��T&���0���� �G2����1���`Y���\2��'%Z ȑ��I�ND}���k�,M�(d�ո��]t�ߩ��1ZrʙӾ-�˜���\�8����K�*�p�O�����N�]A+����3DhH��u�����%��\N��S�P��3V�ղԺ��P$�SA�@��9������rm`����s˪��L5Ի푵C���Ɔ��t���ԥ��*@�W���\�P�>;|T���vtH��
۽e��Q���%��=���1��g�E��.�)w*nH����4Z$pD����z͏H;3��}�P��5HI!�l���i�i�p�$�ҥ�14�S
.��"���t;hn\';�C������n�ħ�VG�!��8v���x��}U�RBC�
�:�U�g���jէ�����	�%z��@��p�gŏ8{�#x��k6�CN^���B��?�7ӛ��*��E&�Jr9V�w���~�eB��r���
^�&�@�n<9��y�w� z#�h��S�C�S��p$�v�i0�Q����ⱄ2���S�j��b\c���i-��������r.Rv��G�9�y�:��ԚBeG"&�yBu�����+��턒��ٖ���F�J�>�3^O�d�G~h9�e�������⢯&���nh��I��- i񞾸@<m	CK�Bˁ���׿`��P䝼zN`C����ċ��U�~�X�[(AN�*%vK��ɧJ�~|��GJ�t�R���)�� �ZIb,:I��G	�Ivi�d1}��N�y0;D����(�o�$k`�s�[8�s;�t����\��],4)hJ�Q@+yU�B���D�ߑc��3�����ʻ	M*Y;.�u��UA!Weo��[V#34�RSuF�/��a{em&J����Tך,�K���4���}`K�vnĽxm}D��!�'�`���i�����ւ�����b��~�f~���F��D	��&��a�[��4��;� {&(��/���]�}������E������`YM����i���P�)Z�1b�����j�{���$�a�$���Xa+%I��?�хRK���0D�ɖ�W���X4m���A,Qu��	<�2Zi��P�LJ8ݷ�<8U�QkBU��"uUw�dv�^���P�Jll�N�Ojk����b�7f�o.�m�C��.�c*��;GT�����1�3�"ʙ7�HH�Ċ&�Ʒ��8�;i����os.�E����w��97g��\�Y�u�ug�v|��6��Ys����0�p�`���L�H?�~��Y�3��gK��驎쉩���)	�a��ޟ�����.�~�o�uf�b�5G�P\?]��$[rW#�SǑ�� ��#P�̑CV�)&�?��y�xd�㉟Q�T����\����r}ξw���^|��8k���t;��T�q	Ϡ5��s����g�z� ��Ø"��]&�Rc�pw-�m���;���C	�-5#p �A��Z,�ԛHϝt՜��$��E[�?@C3>��Cgןm67f�=q������KNǓ��Rƭ}�ѓ��N��E�o!tONO�EN;$�M�!���ۺ�{v$:R�$�g��*v��6�Nk��'��i�o+o�	S�T��L�N��Ѽ }����»%��?UM�D_A[�ԡ�Q�{�F��Gd�o��٘�8��P�����J�F�[ǅ�8�䅃�'�2/^�	;��;���� ��R�AK8f���$5E�OG���pO���2b���ctȚ^ǈ1���G!�M�hԹ�L�
�/t�snyh��}��E�	s��Io<���{;�a�~�Ne���B��I��D�Ř�-�'��D��[ݝ�W��G���J��$�Ս@	��xh`/e�WæA���y�Q5�q%�x2��6�� x�c��"KWO]��l��k���AN�I��@>F?+�3�d��;F�"�z(q��Fh:]a�j�&H����I��翧6F=�&\H$�r��~:ٓ��4���4-��U�d:��Ɯ�b6�dE}�݂�#����IO�^��κ�QO�y?He$����ja�����E���~�#侞Gx ���3��*�Y�桙Z5)�g��G����KM���V��͘4���5�#���d����T08<���΂-o�1�#z��eZ��紛�y�wf��f�ӶC��xli����}*����#4����l&�:����!��,)4'�M�(Yˉ�x���X�Ax6�D���j=u+HѬ�����Y~��o��"!�E!:ڧ�U�07X��1�<M�qDĭ���]:w$�\���H����l�n;��t���x���M��	e����^�su�Miˑ ?u�lJ�Hn�-nʎ�a��p���0�2}My�Y�!:'dF���p.�^�`9�V�J�g-�xQ�F+ޝ�Cn�4:���gN�E�J���;b�<��Fd���,&����; ؒ��~���˘�>
���ل���?��B���h�~�@9�X��&{<�A
��E��Sx��-4ݱ�������4�t|+&�������(*?��|�ޒ�?� �Q�F#���,r�	�@ܳ��Q�T�{��	}��|���%��?˹%����+�^l�$W���BrH����;j�iaP⊴��ٻ��]O���j�l�1�wPC65�Lf������h��׹�kV�A=�-�~�s���#e!�_��b2�5���&������#/����N%�M�/��T�A�_�~���@t����YTG�M�b�׭D�x�����ݫ��M�H_G��DR��H˳X�BÅ{�?�aX�F��|b	����'�O�L�S[115G��8U��/�!w�zVމ�C���'}L\�fɴy��6yKsY���'C)�w�Ƴ����ƒ�����ģ�+|~�c ��)eq��1����������HV<�-���Y��c���*���k�K��#�1�Q���M�"%��Dg�9�HA�kR��8U���۹`���(��M�U��g<������Z�[�d�~K�W#���˚/����@c.��\��X3� ������Y��ʪs���'�%��I�xb�lH�{�G��)!��.5Q*���"�K�7o�w��^��f��F�p�y�h.���@����	_�k��"���*�~�J���	Hk�da���ϡ.'h�*����iIB@2�ȨH�9���W4��X?-z�+u������w�a�ܹd��di6Z'�A͗뉂t�
�0�1�/�X��)��_г�� ��M�\v�h~�,��=Z���v�3�H
����饳Ծ� ����0�.&���,�b���zWg�.�i	Ll%�l�l�����Dn����Z�#p���BGg��'�����	ڥ9S��w.�j�N�����g�0��F���d�y
��d�2���4�^-�/;h���%늹����������d��X�k��*!D�1�Sg��!�u_��ʴ��O���gq�t2�Tzg9�
(�!3���^:=���'M�#�t�d���c�&�/!���/�.�d.W��N6���P/ �"��ǏmJ�k=�hmaK
�Sta6ݚ��`�'��#g#�@���#����٥'@�IH���X~��q�TW��tj���,^΢3j�!�߫.K�Q{���n���Op��5��:��0�ӊ���:�\Te��n�ו?�r' �ؾ4?M�xՆ2`*JRh�%��'�K����l*�᭠�p7��g�?J�v��]�GQ�3F����y�ޖ L�� �/5q5�6v����G����I΁�￧�=�{1T�c�DkGk� ah\��	�g8��#y�����W0	��Z��W�j�}���`gi=Z�Ox�mf�dV�'9a�w�ĸv��% vǠ��~8�������f˫-f�>xd�|���{��ɸ�"�$���fnV
W�qd�kC�c���#ʛ����YմIV�k#RQ��Oȁ틟`�=�0�P��"���T+�>Bhw'�I|�*? ��-��dn	�gʲ%^.K��R\����R�`^WWD�B#E����孏����GS�\�BXl8T��C�@0�7X��S_P��r�Hy]0ڛo�Ib�;�#!�I�B���O��Z�<������{D���o	��^�/�@�lP)�Q}�a�W���/o�mys=n�-���ֲ��[����#�&m&��\���*e�����"���]ՇGPwat:ي�$!����ú��F��i'��*�5.ȶ�5��	�?���'�3���d{����t�c��N&?Q�_�Zf3��9����o�}�w��9"�;,�^�����eT�0]]�s�r�Q�x��C���.q��
[�-4���G�q�Cn|�σ&g���e���$z�Q0�c����%��S`i(p]�s߬\��#�|�B���Nf?�V�K��"��Ʋ�$�KTE3>̇�Y~j�b�%޹w���q�[���7
�����v\ �����D�q�b�yyPj����y�*�"�K8�v7W7MV�w���4�Z���).��O������+S���_�|@%K�tAC���Hw1����T@H�����*��  �JG0�@�����Ԏ�w.T�����r2�̉�}���r@M��4���栈�:�=�I���^�|�5���B0?�oJ�w	���(\&�s9bFO._�gL�5��d��˾i*��H���IL�7�I��pO�������"f��!}����%A�:FЏ�W� E���f�/�S�j;g�Q9�@^�$�j�/UBs5|�J��y�-�%�q��=Ƙmr���'�[&��TE������:K�w8{V��| �2�ۼ������^��m���oF`|��w;5�+�Q��OG�<v(�U�4x�Fs��|G���s�1�aE���~���,�cϊ$��{\�0>��^�޳c�`.��?u�I����*Ӽ? �>�3���ej��T�G�1��i�_�8�!�0�f�I_0�ay���yA]yD1��ٺ�VN�ڞ5��&X��m5]`��q�6�#l����wWs;7J���d�Cs������L[�?d��~P��;�9���kb(`^x=�t,L��׍��h,)*��#�p�T�����K}!6a�g�?V<r݉IG�HwKVԇ����F��~���|l���}�A1u;��w˗�>���<���I�X����Q����&j�V���i����t�_�2vD�a���cY��%B����M�`'A�K�`<�$����޷�~��������
w6c&1�d��wW"-f����E/*B��]��ѯ�",P�o
AV�J���4>+�/�@f����b�3��21iw��)8�ܟ��У��oX�U����t0y��
��Le�zgi�GY�>9+)����Ȉ�Z�w,�Ŕ���w�P�K�kd
��k~2����(t@-����U�MiEۂ���-zo�4Gn�*�����D�$�^�ނ�o�w7�*�A"��E=k��ƞy;��J�MIYv�p��G�m9P!�.��z�������W�jzb�d����mAʓf�Fꘕnu/�Qï� 0�#��7}ދ��M8�^HGrA��1�^!�%}otM���I�f�1�E�{���>�A���P���:���f��
�4�T��?r`m��s�F���&���� l�
����(�(J-!%��n��ڽ�Q�"6��pN6Ӱ�s?��gKS0��Rf�3�l鍡4�e]��}�FK�m��C6����=����꼧d��U��&#
*�9���M��Jp��}MŠwq���U{Ҽл�_?
��K�p��0&�,�/������h���ۃj���8e�'J��0��][�üo��T�V"֝N����˦�N4�-����4i�qO)0���;����p��)v�ǫ��%_���)q	�x��91Ak
��׭^"nxFq�o�,<}g����v��P��p-��_>Ǣ;MEI�Ѕ#s�M���f��XJ�:vR�=<~��y]�r���~
��(��+E�b��1�H?o��ϑb�[�3K�	q�s��X8�jV��:��&��3��V<WF;��@��vmG�3A�H�����V��y�ʛI��'�fZ*;��\��� �
��z �6��1."�������~Q8W�[v�m-�:���Z�Y_X�1��]a�%�:-TA ϧfu��?�v�pu�}w1�\w�1��~ħ�p�Ow:}��u�L�����Ǐ��`!��V/��萢����p�y̘ǸC�2�����
P� Y;#�,$H�Q���?'��~E�r��*7R��hR�P�b�]���g��Q�a����h��� ���,\����?� QQ@c��zK ʮ�m���p�����Ƣ8A)��&Oa�W���|��K$1]w�7��48	�(�sv�%wG�X���#�@���I�VK��.M�\�����Z�g�%m�����2oɹ����Lq�RN�����5V ={�� �;|�n`��y?Y�EW��4���Ȫ�|M���@(VE9���x�i_���R��R-�{2Z0�\c�:1_�&jc;�aw[U���`� J@������9�g�����&�P6�\;���]�}z�{�7�.�l�X'6S��E�5�c��0�@��� �|���y�n��]��%��i�Pau4��{JV�����m�P�GB���YipրE��r�������,Cٕ�^��
[�F�ڝf��"���4
Q�a���oɞʒj����\�,��K�.��{X��9����Q�N32�R�R���_삻R8B+�K���e�u�bIS8���cw��f����B��E��2'lO�=�_)b葱�k�CRrp1/t@�$K�<{�C��L��p	��y�D��w�r9���yC�jＪΌi�te8A	�L����Z�h�������|NG�BS�Ι��`�8yWe23�S���a����5�s�9�sgsG��N�̥�;%�v�V�0���$C��U�������4������ ���?:r��v�uQ��U�4t\� Ѧ��6�bஒ�b��4طw����,Z���Q1�������,�~�A;��^!B�%Ŕ�f��U��}�]��a,��>����$ڥu��♹0˘�!��V!������Sb���Ir�wH.�k�~�c�Χ��G���g���\uBEP�=O���"�@4���c�6�w��%>J��5g�\z��+B�W)�� 3Lsg���=7���8@7�n�fqf�l������c��M��{FAt��R�vTΌcڣյF�x���+Q��ZB�OAen�il�p�B4�0����=�JC�'�y(�n�/���}�H�7��$P#V�'����)�fm;��z�D�+I�:7CYD�=���唧-a���C�|Ho���6�+��p� ;����%�0�q��{*���8t�	#� ^�\w]�N�G��zl�S4$SP5�O~5�@ꡢ�ӼW��\���	P�֚�B<
�Pu���~'D6�]`2ow���Z�	�é�*�y��&.D w-#/����y̞)�bu��l�8hD��q�7feB�3z�>�*��!]������"��K���Pg5���'��))˽�v7��/2��`��KN̊�o�x�R5+������\�:�
��_=[w�h;(��D��0��S�k*"��]��j�˛��g�	 �A���R�>B�	��϶����!(�������1�%��T���w�
+���ZI�/:u�DPP�姾���ly�[,�#/��=�����O�L�Hj�!|�#h^8�����t�w��*�����F�23�?Qi�o�s�xx��T�:�A��@�ð�a�y��1O�b
��y�!�]ev�I[Tx�}���*��Z�4���A�:��;��_�EK��.Ǵ�Oؕs��<e���N�U'B%zƨqZx��(���1[�r��S�	�Hj�[�Q��5W����a6^��Ȳ���VQ�+�m��:O���A��wDi�9/G��	�K�}Y���1����s���<���X��[��|ݗ�����x�|Y)w~�~ޖ�����o|D/�=��[���V�������bM�0�C�EI|a�8֥^�>e��N�oc���r���^�t�b��3�S��)��}�'�Ƹd�F-�dg�.,���t�<�,����ٺYHa�6j15W'�+�BE�QX�zad��l�g�p*1��4ɘ��3!�XY��d�DP1s���%(��d�;��Z0AjwU�����߻x��Ȗ���l!qV_S�D���Ҩ�R6_@���>\���!�Q��c��^�S��y�6r�W�%ᛵ��C(*��y`��e��'|�Lg��u���m|+B��
i�k\4�q�T=�\��\II��$:J��'0�9�au�R�������!��P=ӕS���wΎ݄BR�V�Dg�.�u ����rg�z����*Fk�G����5oa�3s5
��2���%W�-�+m-��9��+L���׼]X�/P��~��͆k��l&�;��P���{~dq����/U�G~����p:(zn%E�ڢV!���BX#���O�%%Zᤏ+z���S�g�-ד�$�����r�V�+z��$�͎�)�YQ`դ`[�-*>|?� =����������>�� ��8j�HҽJ|�c����d�N���A�eZ鱗�(Oz#dp��d�h�5:��Zh%���HD��r��-���?Z��?��}5�}4��0Z<�����7����2��^��-��
弨�<O[�dc�S/�h�a~�̃��_Z�2�u�t�Ϭ<��ݯ���`e12�bU�U����U��'���q��h��Y�E~T �� "&(t0ƈ��:0�(��da����Ȩd�-��s�!z{�����M-䆳��_�͎BP��fO�^O�i\K]���B�!b&"NOM���0���C�L36.Y
�c�/��U���hǾ���՝?���+g�A�7l���}qyx�����tv�+���x��r,#�z���{�Caju�Ud���Z<ʯ,W��bѰuD#����~`T9�Ȗ4K�0���,����+9��;��H�	���韛��z�Ή�.����:�hp(P	kt�x�'��HKTv�QG��t-�of�� �U;+@x�"0��H�j<N�F�:Պ
U��_bg���9��3[�b]7}�'Z:'h)	�¦/I���;Oq��p�`C5ܑD�J-�b�28v�������>��$���];}1
��K-64�$��M��L�>��s������Wג�\���Iv̅.�M5���H����#LL�\��J�zj�r�-�V.���xޗ�bP��6�k+}�cD���/p�9�G;�/)�!Y�g�QX��l�tY��Y�8' �r�4���m�4�yK;ld��PiJ�b:��6��G���3����ѹd��F� 2��o�U��(jHX�Vle���T�e�|�IO��E��AM���J;�4��@�UT6�%.~�v��ڛv�b�Q4�O��\[�
K��#a�.�xX0r���L��+���bi��R�Ó��6Ty��{��9���ܾ�K�N`����D�$7�3�l��
�>�i`��g7:pgp1Q���h����pC'�`�}���$�l|�&���_E�tL���_�m~��הd̜�G�W ��'��J���;��k�1-�(�N���
�	xT��4	�|h�˰��s�P��7�e)��� �E�ҽ"`Q�MJ���v?%r�"(�_#��l�`��@;9;��Ƽ3�P)����dQ/�gn��
�s3$7i��:*2f�Fk(0;��`��tt�"^��)���M��I�~����=^B	�RW"0���igL85ꧭ�����I7���u��D�5�����s����ʽ�Y�%!S�`�1��q	��f��6}X㺍��6I������AYF��e���Ȃ�]%]�R�� rmcL;�N�<��Ak"���(*�ӝ��rS�$}���}4KN�@6+7��';d)\��8 S]&隷�`�fR-5�PX§FqV������46��Z!�u�c�b���~��N�!�h�����KZ����EW��BN"�=JJ̓:_�'Q���
v�qiش���.�-�k�X�Zh�9���FmO�;���^�ե4��Eٮ_�vJlEtŇ���2UR7��d�K/M���n+����:��m8eM��Q�.T�o[�E�=���eC�Ż"�s�y
��2:[�l�ʍR {+�Lȧ5�]�9hn�M����9J�u��*�y��?�(����9�ϔ��|da�J]�X%⎳�O�-�!A������}�y��L�~S��. JN�9!��>G=��IZ'��}�Ÿ�fT`�ruZ!	�_�,�7N(#'���3ߜqSlr�+�(f\m����F�	��L��	��o�������Y�Wb�o��c�?�ֺ�>� Z�^J��Ҵ 		��#����q𛃗7F7.G��0�~{:te�R�W�x�o�*��.M=�e��b���pl@�L�Y1O'h�q�X��|���t�������I��ފ�mz���u�4kc��[M8��n.�E���p�v���P��p����ס�_���ej�����t>����;s����S$���pl�	�WN�fb��A�"�B�vM"CE�2}~��}�
C�t�г���;�>��0r�)올�Ͳ<�)Xy?B��j6����r^��l���������44#0���4�^�L:%qĻ��4��$8=!�P��!�z�N+a;D,��w�{Н/�ؓ�?X��,V���ͻ���VٲM^6i�s�h�`�=f�E�vS�(�(�[!.E� E*f�2�nO�HU��ErC;���*�/��H�>5���0z7M�*�<���
�8�T&�M�,�J�����{�x���Y���J�� �x�l;��楱�W'_��!/���?q�r�\)���؁��|�	�����y�"���f8�����D5߱v��+����]N �|n�*���q�B}7������(�y��[h��{u_w5�E���̲Z�}ʰ��B4F�`DiF�'��Ȅ��I5,�\���D�WSp&sa�&6�~v���\�y��<�·�����$p��ϊ$�g��X.z�ycBӳ���1�u�FNv�����uJ&���c��j�UH���9�:ɏ��8�o^�H9��+Ҏ�8�~_fv��1=Z`R�Y�S�75�:��h�Iv�-����}��[�NX�(���b���z��s��t�x��G5l��s �R����2�_�'>�v��1'/~y��%��2	��Ɖb6%z��jݗ�9۠R�O+@7k�/�J�;g�M18Z�������19�5b����œ:1)ܭ�V�-q��]��k�	�%x<���] ?扜"@" _n�	�w���x���tp��̝�08�<M)�r���k��%CH��U>T1&����@�
�[Υ�62O�
{������{�|�je�?�I��K��H�߆�m@LH��o���Z*E �t�W���9��:�ne�4J �Fd�h��u�KuDJE/6�)��;����w&_�)�A0xnv|`3��H���x�m1,�)�O.��w���.�C��/j�jyOI9PǸB��R����Z��\��l������7?�o�Z�������s&�YOi�6=�}Y���i��l��;�92ݱQ���ҋ!~[�v�P�6O8��#������lA��Ϳr�,�>�0��	"Y�#0���^�h0���D�#s����P����[g�*})$����j`�g�!i����d�'L.]J�3��)�I(��/{����u�y��I���&��9�k��Rm��;2�/�u���U�&R�"��ź�3���MRs���N������$�"�Óv�q��X�sT���w�w	��� *&|y�͆�i����l�E�Oߞg4ߩ�g:��p>�=���O��͙��ݨ����=I~T?����8e���l.�lr��Zr�c�̠�6�[��E6y��Mz6����EX�\=B�0�=���EΎ��PKw���1!�I�\Q��@uⷣ0��%���ɫ/д�*�}T��/w�>b��Z�����S���������!Z%y�ӫ=*̻3��k-5����h4����ץ	����A{ud���y�K���H��/���Є+?�'�
;�����@�TPI�"��c����=Ry[nK��k����!P�E��>��TE������`.A<�C��|	��`"$M{�������?�k�vB���L#s��N��~O�
��
)�f��2A6����[��':�k����Om&���5���f�}S�������,e[�mm|!����h!��������6&���$���}�|}�pȜq���D�
�DS�U$�(�
{�s��<v���Ӻ8�E�}�x9�p'� ��/�U}�K�2���������>�4ׂ�&���r�&��m�FJ{ņE�;��KANx:%tHN�#&�ȀLܑ�S0-kX;W�z�D>x�z�Fi����V�?g�Io�x�
�G��Zς<�FKZ{)��� �xh�:3{�C�6LW�i���N�Qz�x�]��:]�f�����ak? ��VP
,���|�������R���1.��j�����/.���bN�f�#��R��1�NҬ����{صR< �5 軘���)�Q�33=ŋ���.F\5�=}6,��,��{�+�����Q��sˣ�f�bc�������G��`�r����I���\�P:C��5ߡ��V�Xx�m!S���0�Qnh�������Ƣ#�.o�i��5wXŝJy|\��u�mDQȰ���c��p.**�	�j��2�,�s浛s�_/�Ky��O>2��s�l$E·�r��/�ű�)6��Y���%=[�,�h��G��y3��w�z#�N�W���{$@[n[�H�I����	��+��j!�����-8`vb�+��,����$k$&˟hXU�1d���'��wl�ɧ���W/i�-I�:#�R��#���k�ٜ17�\+�$k}��8���,���O�Yw�%�~gH�dr�/�$Ekg���X��&���N�0�&�J��/1;�n�|��;�8ev��O*<m>�ɤ���+^�>-zݨL�G�t~��|.���4����p���	ۉ���,, ����)�PɁ���%s�:S*(41��Fr��)���u��|gW�m�J:v�h��o>˟��yTx�x�ADb>3p������0C��Y
_�If"�e��0u���J�!9F�}s�aG+(*&�wh�>R�j�'j|��D�Y�-!B���Qy $��g.�ƨW�Y�Vo����JZ���e	�J��%7ҹf׹+�zlOqp:�ْz�/	J�s��U'�ݲ���=� ���	tyn��/=	W�D����� �$�}f��u%�r��"]�K���n�H+�ڽ��u�=ϳ�Óe^���ed��ޚ��:䵕
Zi��E|w��m*�";k�����Z���V��[>R,-E���+n��8껳5� Ƣ�
B��k���6k�hqh&M���}'4�C���T& �M��~�L�N�%��5��pI-����̿��}��ήV\2\��yC��
��+���2���	3�v��٩{B1�^���mЃ����|�2�	��FNe�!;��O��?�)+����t@��_���֟�ۍ��+�7�� ��m���vx�,SX嬤�ND���f�
ą�!ρ����@��<�?�%����fZQf�����)	%�ip��R>2Wd��3u(ɊKs��CN���),��$�� Q]Ȼ�-|�	]�0*��(�>��M��
7�c��-�V��+l_ ���C#�4`Ou����hQ�C�#ANSH�����x�:�Y�)O����1�ڥ��+�l4^\�hS���.I��T>x�J5�D���ĢY}�]O�.����0����`�K�$�Q�#��M�t`��V$R4�>�X����+�5P?�`���f�&����pp�Q��>�������(��שV����\�9gJJ�dť!7;y
�~Hԯ��0c�m���^e*��z�D�{�9�Q��Q�c|ș`���p��Vc`��U���w2���z��&dՊ .�؁u�(/ߤ�Q�sn9V�I�,�X�滐L�@%%qggÀR�@@T��d}�SҘ��8!�C���-_?��m8q�IW{���hxX���Dy9�Ms�FZ2��o��e[ݯ�n��"4�]��1��9T��O#O&N3؏�73�+�_Ժ�K7��t��D���u@�!9�jVh"25��J����ݥo��
�jy��Ez��;�L�q��A��Z8P�Q�J�08�Ut��=�#T�ǁ�'j$��5�����C��R1��K�Q#O#c0n�׫�Hǥy��)�H�7�k!,l	1��{h�D�Yʒo^Z�0��(���!l��\LPY\�'*���`�������IS`�t�O�qH/�����-����������X~�w�&��[����N�h�b���E♀JX��Q8����������56�w��y`���L��Ll�p�bmL������P�C��{׽Peoޚb��p}�r�RO%8&����SM�n{.>�l�^P�/��ʔ�	7
R�i�E-�Q�:/�E����-�ʉ�!_@����!Ւ��*ʈ��Dҁ��;�v��)���Tv>�֔�ފ��H��9[�������g�=��Q�f8
�i�;�!�,l�M1��V�y�M�\w��.$]��s�M|<.�G�<0��ꇹ�<N�#?�b�cb��L���>%G��a�ƞۍ���79���2�~�˞�;��W�	�J��q��<!��qn��p��TwR!�Q㣻z����i=iym�"�rI��"��T>��i��߽7�Äp�͉��bZ�;�řfHؕRҟEa�����;�5�����S2���eL���o��1$F��0��UdSɝ)�B����ո�+|�9�zhW:�p��=|�֪��:)8.�����E���oV����:Ol.�PI5�v���M%mm�xbY�R/�9̬�ef�scV ����8�uk�|i�oY�o"7׌k�� ��1T&�m"4{��am�,��a�'QU�/�4\|����=:����=�5�)S��ؾ���8}ی��m��#-�%lc�jZ+��:?؂Ӧ���O}�6�q<��u��}��$����FM����,� j���3]v�諜�W��K�w�g��b�":��2�d�Yr�hw�\rE�pbj{���������
�t�~JtBo
V�^Ec��]]j��1	n��%�X5�G��N���(��lh[Dz�ʇ�'v�ֆ��A"�� �9$v��d�J����b�{��vb������v��F�߫��ީ��(|��벶~;L�tj�5��٪���"�\���M�7��ۏ��1ӝ�F��٫#���a�\�#P��/U��6�W���n�.nFz-��;���{��~��%��F�G�s��{���ҎA*C�!��Hf��0J���Ym���hf����tn�GI������/��M���E��P�D�b�
,��=����&��f�(�?0�1WA�� �[A:S����Q��f��֬lv,����M�]�=O#�H�FUi=G���b����G�S�4��:kz^m�=x+Sv4X+.jK��ڙ600&$/�=k�o0jV�n���N������^̬�l�t��D�kWp�#��)W����!"�G�.ט!�囦�$�U�2Z�J�w�Xç�ձ���Q���%b���}'�S�,�۫}�F�m<��І;2�u�>�g�֝B~������#7�m�a�Xr�8 T@�|�_X}��|��*���}�io�� ��A&q��\��u-�Y�p��&��(ڔ���{�����4-��hX��KɤU�(G��ut_e)*�r��o�?~���׀[!�>"N6����#��:i��g��gb�A�ʕ%��T5�eGU�A��׏V����N�����C��p�X�va��A����rj��2�(�"���{&�j�7m�ō���'�]^��+��Di5����րr(���W+���v�Jm��;~��ZO��D��.!��N� ε�œ�(��r>]�YɜPZu(w긎�7�:�dꀇ@���W(���j��>�m���J@7��+]�z���sn�)c
�;�:���������LY/5%�&|2#�����v��6�/�����U� �Z�OaҠp��*QR1v&\�١�3Q Ցm��"ɨ^�uόt�Z&�D�rފ��g�:�bR�+R�dK�f�#DڄT�ƨ��x�5P�k����d���L�!
\[eR�^��>߂T��Ȗ8��[�)�i8�	ZUz�n��-M��ˬ�H3X���o���>��U��Z�n���s:o�y-'�?�2�{�;�';T�SS�9.G���3 VA��M{3�\��MZ�{7��p�Gv�f+���dF*،2�a0���?�tW��������~q��z����ǟ��F��f��ʐ��V)5&�#h<3�$Ք��J�Ph-���=o�P��j�j�?����m��p���~̀�LI\��.��tG�$�9�@���9:��,���-|+^�NӴb�����ΡU�͜ pS#8h�)�ܑ��L��;p�X�}��3QU�z[� ��Y��O�����b@��mϑ�; ��Sdq�q� ���Eɸ���(s�������XBFp�9�%27@���Tq8��n�~h����<������<�'�K\����0�����~��ƥx2!�l���a�x����ܪ�����I�~�mu����+ϡ��v"˛�Oa�@|��>�OQ�L�=�����t�l��`Z9J9�O���hy��������a+��|��û,(�Xe%	T�����*�f'�ٕ��H'�T�[�����x��"�V�%�tz�c�m�'7��`�I�ը��8���<\�l����Dh��_N����CMT#�.�fp�D�LbTsg���oLA��?�4�_�
Տ��52)�z�v&R�n"�ܰN��aR�Z����na$-=ӆEk,�i+G��GV�Ҟ%�x�)�w�hX�ss�Qb�$��_�a����ߘt:�E�6�'rQ!QX/��G�q0q�ߜ�U���B�m�t���Rp���\�ރ[�����!9<�*H���(`��Ij�cb����+��pU���,�)�87�pzR��$�?:?~Hy5����l�N}�i�.{�Z#Ř�㕕���l[��cw#�EQ�d�=��3��'�Utp1��l&��Jx-�'�a����:5]ag����J��G幌#�س�sA�뺏U�H�
�K�_E�`��8�gL���f�}��#E[��m�wsrw��<����U7�K�55v����.�Xu/�����bQ�N���:�	��~	�]ʠj-*����U��n�;�nE2h�3'�D�)_x����G��7pƁ-(ƞQ��	W=�Z�";�;�	{��l����D��fE-̦3KO�K׊�\B�Zİ��V���&��4/�JE"��I�	�Ѝ"bc���.���,�(��o�&�u�����L���|К3So}9��tր�<� ,}!hT]��@=�A��D�ZD���v2p���{b땩�s��4Qm�9JY�P��3�7����ރ6�wK���k6�8z@h}�\�I,)�O-9�S�&����=�NE�qe��m������ڍYߚ�'>[U�ҿ���ҫC�w�H*�y���L";c�[�i����>̦���
�*e�-��!�\֦I,�ɒf��Y?�J��Fq�����V0�x}�ҙu�_`�]�C�'(���Qw�+YDO$+�
h�]'hƢg���՜�=���@�G
��J�[�2�<����x���c����������x<}ˏ?�T��P��5����)r�P��rԋ��C�Jz��:����_	u�c�KW->[�J
�렚ɂ����u�dԷ;�`���^�$[۪aÌ4r���-�ʟx�RY����Oq���H�!1=N��ʗz�>v�_"�H��F{���^S|sAsy��/�E�"��&��)��홂�����dn�������u² >7���s�hOCe6:ղʿ-+S�F���$�F��r�P����P�GlՆ�1�u�vS���]c8�H�ӌ���	������L�&��1�֎o\�d|���]m}�2�b��=b�ȧmk�	�^21.�^�,d�vy�N���Ed�^E�\E[U�ڬN�2��d.v��"ku���(��@��'\��}�Q�(|��^e�q�����.m��r����Ե|�1(��h��.H�?-ަ���ۛ�Ɇ�"o��)YyQ �Ʋ2�-�`��i�<�+}6t}gҷ���s�i��8]��
H���{��1���V)^�-w��W<�+�B24�S��;�ѥ/��$޷w	�[z��'�helԲ�[V #@��Џ �%���4J�.2���J���O\�`g��߃���[�Bڷә���I)���,C�׬wP�4��'�ڼ������쪘�S�p���N�6?��8��TS6� �ÔZ��5Ǌ�3-k�#ʙ��|���@:����ﴞ{V�rp���O�e�$�RA��H+�/�&Ak�5��w	���a��$/�5�� ���r��XX�8A+�����W��l���^|P�yL"����_d�.���=7��H�-M&B����"��M:X���_�'2?��ER�����`���d�� �)#?Q�������7;�.8Ar���5DN�����5O��(lٞs^ɥxt�q;�.N<G�{�|s-�����
�	�O��C^�z������ٹ,-㦖�������1%X��O��h贪��_��A����Ɯ���DΘ.�\3&��!�p]��	�'��,�NH>��o��5'��!q=]��a��+�k���Ŏ-P���jFv@*kЎ��`�OP�5��	Đ ���P���j`o�k�n�s�T���_���<�mẠ��t���R~�B�}K4�) ư#���"~���)����W?�-쟇��
��u�N��͟�͟/ј�]^���4�a�\�G����3{֒����J�����~C��B=Gy8�\��#�ȓ���_������_QA�{�Q����CV�'�dM)�S� �׽<6D��w�'�j�>�ni��5O��	Ǻy�$��r	�K��Kr_������b�( ��
��l�_g�/��l ��%~Ξ�Yi�X��.T^�F"���|�.$��T|`����>�6��â�BU� 9�qz���r�ݍi#�,�k�����]g���,�f�c/�\/M/O����w�Z!U�{���X�
m5�]�J�2��:�>�?,	}ԩʔ�QrG�}c��89pz����� |��^���AFm,H����bJ�1BXR@�_hy�@q����-����&�\��(}��+H82�T[Y2��	�\���l�_$�.�S��_�%��f�Q�񼾸�C�֊R�i� ����ͯA����bmz��?z� OQ�n�'��-9���P���	��!��sj` _n��Q}J���W�Oj���#W��O"NC ��f����s�&�6��i��	��	0b�-5WfR�9�Ԃ�r��n�$%C�!�x���#:��禷C�������Е�6�R<՜QgN�_����;�^���0�p-���3��_��^�Za1��x"�YسX�>�L��6�0��K�D�@��SWr:3�?<���o�Q��~6�@�kF�K�xL����{+��_��y�/�ת��٤��!K����rIp�0�#�$eGG���%�f�R���#e��l��v9�C�w��Ɠ�d^FK� �<uq�����z~"&��?�fg��Y,N���۽G/=�&���n�OQ�P�����Y�����ѱ��-C;SY
�Y�<���w8,[��+JI)a,�ހG�~���"����ψ���@�Q\P�86�������vǮ�p��C�=Gs�G덫�/J��?�o�q�!��j��9n.W|�F�3������G�!N�T�����$ʜ�G#����Ęl��w���>0�1u�>�i0�E������a7��	�a��.*'����Ҟ�)�MrN˾丕N���9&������х.,��L���)`TM�_pxJ�98�$d�@d�%����:�a�ʪ�}&�c"U�uJ���$��e�-�
��ŕ��f�q�!	c��X�I����MD��%�؍0��T�37���h�~n�kz��ɠȇc�mPk����Ow�7,����%��(��C�Qn>��oK�M��t����Z��Y�=�0󞙊l ��mKX"�Ï�~1%nᑕx?Fx�W�Qr�퉕44�j��3~)��l���o��ř󯔒�*�T9/���>�DF��_�PI}y�v�Z�> �����{Sn]��NV?$�s�:��v�@"Cr�ۣꢧ�"~.�E��q���^�ڂ�Ȁ�'�N9N�>�����e��\�ȵ���=?�Հ'�"y<�`C%��J��_��$�&;벮ާ��?
���DB~M�3�%�\d��}D��s	�2��)}tV��ӂ���Iz�NV\Ƈv+��3�|Q:���F�w�$J��������"r�p3�kϤ@N$uo}"�������B��+��B|�U�� ���R�1p�e$gt�?Z�7̦��l�leP���Âw���1�׮���	�y��Ӆb�x��L���+����et��0?��}h�[���fKaC��%������?<�WP*�2��] ��oC�yQR((ޙym�?�eB�s6�k��olO�&��ex�s�����5W=�iE��	?��>*n�YL�$*$$R�Z�ͳ�k�)D�-#�hF��o���W?���2�;��(c��Bc+$����E`�Gɹ �۔vx�܍���0��N=���B���n�\�`�C����o8obR���1�e�/c�O�X�f���ׂ��J_�������C�a-ېȆ�	Xqn��o���.Vֶ�>�׿�!x����hg�oXِ�t�*��4<(��I ՞�W�n�5E�z�5_����p�o�κI o0�;�>|($ͱ',�o �!���j�O 5���/E�� ��<�bu�d?��Z�E�T�u+�kHP���$O�;�̶�v���o�>�ﲰ���t��nY��lߧ��Y�v��HF8b���7(Zx	�Fk���r�q+���������вQ���W�=�9��I��u"T3Ơ9\:�=.��1V][��U�/Ҳ��B��Ϭ�0�7I[:�	"�Kƙ^���   N���_�� �����GR��g�    YZ