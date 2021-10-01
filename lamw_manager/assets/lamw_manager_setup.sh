#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3461131389"
MD5="1c16354ce8a75179501ca0ddc44e3f3c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23584"
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
	echo Date of packaging: Thu Sep 30 22:34:27 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�|�Jw�������7b�xB��ە`�<��L]yqD>�?��=�{�N�b��385-�x2h���(f�,	�����@/։]5<�wދ<��evM]�5qw�c�!|Nq�*O���
�*WH)��c�n���ſ���!k	��j��� -Y@�ni����ܔ�5$=Q�S$(�����*�h�'���q�*8N0&fZ�Rn��z����~������>�%Koz�gy�Sx2sHr�lM=�[���cw]�O��o��� ow'�լ ����p:�����CA��jNk9_��]>���Xi�R�J�w.�ۯCәT&�%k�E��]�}ۮ}�˽��.���j�	��g�ar�J.L�^�(��G)aSn�c٠����HO;�T'�"U
�N�jd���Ac�!ӻ�©�͍x�	��\��[~�+�X{q����h �_5���zޮ�H�H�ؐH`s�IDmO5u`���g�7h/��Y�n8�ȩ�J�~>��v���u�X�U�K��{C)��EMX�[���9�N��\�����d��E��pi4�����E��K��xQ�B�x��3m?��~���*3���Y~����&=��v��W�+/����l2�ma�n� t�_Xµ���'�N~u����K��-C<Q'����mF���Զ��+R���r������������{F%�?�����,�?=� )�P&G�o�$Ì�����.�
�㑛G{h���Su;ʿ��<W}����(%F��½?�\�3:I�R����(��\P��F�W��R��l7P��8����tT q�/ �&x�UF�	f	�l�q�l.d-�*�'sTۏbfR���KlƋ�k` �mjo�q��;��H��i�48�c,� �;��"����CN/�.�b� j�X�;��^�_�nt`o {�k���J9|{�gv�q�//�ǅ��x.�C�q.�u���rw�<���{Kk��'t��0�1��j�Q|ȵ�B!`��f�0B|��!�}�@�,�L��զ�2���t����@�m
Atˁ�&v?�����8o����w�~:�|��+}Y���%�ߓ�Zo�hm,C�q�jI�����u建5R�*1��#<�!��ǣ��;�*���fs�9Z@PE�;�qC�&DǼ����ڑ\>m�0fC/Dt�>Ω�1ݫ�a�7���g{�f��V�]p���5��
6sP��A�qr%'� )^.Hx���ݚ�����Y�l~���[a{���wYA�Q���CzX��0I���ҁ���<�il9�!D�ClU��%T�,�z��9��r���j��Bm�<2�y7P��ٍMp��������ͅKM1"�����X���h㜹�Ԟ�K��kw�<����3�b��j���>�媚��J5�C�Лj@�.�C}s��_#gI�9Pw4h�u��;��B+����R�4 ,�#�Bjy��1��HL�0ܧ�R��+ ��^πx�[Bɐ����Z�?���K���5��q"~f�b��Ti&3�� YM����!2�B[W.�%�ж0R5*>wnZbg�p�� С�vi�L�SYDr?E4��y#w�!��攳?#$����y�7C�+S��~>E�Δ�!�����#�sX�(��':��b���n�l�Ä����O�o���=��c�lf�|�0�{3#�S� ��G��\7��0r/�#�m�uX��v���F^P�������ݓ��0&USZ�C�����;����Tl�aE��J3�Fh���P���;��7H �ߌ�@vEO��G�H����l��Y�K�d����Ff��<�yHeGi����s������"o(8k���R���""��!$���Q�[��x
��+Q`K�A�{�z����۽��#�L�_�Mf/��'~w����C��!ҹȪC:�P�%�du?�h"�~��;k���q`���в��ĎbY��ڨ����6�͈-�`)��vP5{9lF+ݢ�+"�I�n�\�ҙ'�^>3*�� �;gJѨ??��xY��� �R��3xU@�����cj���l��Op%�E��ɬ!�NS��U�ȴ�sD�Ywc�3�%�����w��@�0�rS��i�C-։B�s���@��I�`�N�4� 5���ﰤ�Y{9���&��&���\C�d��v���NW����q�3���AMH=����OD��Q ���a�����g���Y����<7ϊ�B�>�EݠM���:\��t��]U�{�e)�����99�S��^��"*(�~�9R�5 �L�k�y!�z$18u-�p�(�!}���5(4}���Z��8���ö���;�� fO��R�6&�]q����Q5X�d����&��<w��\�Q�ؘ�}��][v?r���ŉP�s>�w���%���C"5$��bt�񼏥��� �E^�m��
�m,�4u@
��B������?w�[o����r�r	�W��)�Z�q�_lw��P����Ӫ�,$��A���`��ٟ	��G�ӿ&;���+�������=d�[zkE�z��&�"��+���w��"~��P�����T����r���M�A4�ߋ9i�.��E�ΰ�_W����Z�<B��G9�j&jT���ZL��'g��h�'��g��_�A#R���w�	[~,��
�ic�Cޕ�إ�L��Y7f����$��Д��"vଆ���B�匇�򜆰)<=;�0Qq��7@T�CPF\�(��W�?�!�N�2��5��V�K�kl����g�y�ܬ��T��o��~�nȠ�)�5-��K
� _�A8��R�A1�Ny��/�!u����][���������!�p%������V�M1�Z(����rP~i�WIǖkOC��
����j��G(���tN��1��upx��C
[M��ٶ#M�D.��č4��k�g�����$�uE*?��t@C%�jy��U�Qf�I=Xl����0��'�������A`��E�M�^���O�4S���n��b*���]z�/�{;�.�$�۔��5�c$� OD���G肞&��t∂��ã�P�6�T�s�)��K�@��s�{w��9�k��Zӄ�D��_���WLC�yk�Q�#5�)۔z�#ǄB�.ZC������c�
���@�47���L.2��0v�$���g叄���.e�G�L2�Gl��M�0Ӗ�j\����]ǥ�]E����v�1Դ}Ӵ*�m3�S9��dgz1�Gl1qPp�r��V�ϊA�q�jiG��[�t}F}��o3���ps�'�Kn����Bc{��OV
���F��\2����v*�̇�8�N�l���Qc��gσv��K-���%�9���5��]27��X؂8�aܴ�'�V-ؑzx_+y@���CI��:���(F��x<�������qњj�xb=5U-"�0��?k"877�y��
w\�8��X	�f4:�:~Q�C��ӥ�!+�a�q�4���y%*z@�;�z"?�1�?�ٌ�ȍM�Ľ��R_�WL#��n8?���ӆ¦��l[3{�52/�1�E�	*;相x��tp����/����=��=�$\��'�r�Vr#��Z��(�+k����z��d��Ma����
���|0��է����e�� �>f'�/�#=�~�%�9����M\���ƛ�@�X2GU.��g���jW!�3�2����_(-m���	�O�D��V=�a�o۝K,@��Ï(_]�/���MDs�޳�=8�!�.�Nl�@4Yn�.N��[����3/��pāF8i��;76IO�����)��'�����oǰ/Y��)�l#�3X�O���y�J �hQr��Ne�:��+��(����bw%�-�������o("��R�p���z̊�#���}�f�f�'
�����T|�Xm�����50�bt�,��~�q��Y��ͥ���5�6�{��r�oC��1B���
�˫&DX����)7�;�W��=��{0�4��^��lt�Z�d��AJ�s�I�e�����P❢�\)���q��/�hX QK�!\�C���c�T�K?���|����%��F��#gCut?G{?y�g�`s�������8��H�2e'�������+F��x�����Qm8\(9��#�x8FT3���\z�K���tYZ*�T.�g����'�9a��]��,k;�����N{˙\��#?(G��+!��ߑ^$�̍߅_���j�V��j�,ZI�Q��.0n�����		|�P�eo©8��X�B��'�cUE!���6�g�$T�p�f.�ᕔ�})��N��cx��A@|6���O��p��!�B5q?�彲��G��=DOQ^jR%�B�׳��v1D���qU�Ņ*N=Ī�u������OwC��b�Xր�$��_9��]c>��XV�q.��]�,}��E{�C��gQ�jcM�Ҍ�5 ��N.p�4Z���'����ҤM/�B2�l)�$}��	����I�΄��p� 2��;9��DU�X!#��0�T�l�&��	+)P4�f���@+Q��d�ON�i��������2���Q�4��Rxd�~"�"#L������u��1Y��1P=l��<�&�W%��]V�vK�#�����C��>�z+I��a#I���ה��9�O�$b$zzq�#(@-�j�S�_+x���񍜄!
rz����'�I�@
�)�xFcx����G �F�;�qS?+zbw��kc=>�V�s�X9� "��u�KP�ɹM�AOO�W�j�ԏ0�e\��|?�8تx,�Ǥ��]ע�҈+�-���$#a�ф�=�j�	��d���}��#ceG�$���5�<cB�cJ�a��G\/���/�'w
kԓԆa�M�U�,	��YZ0lu���;�;�5�'�NO��B���"߲�z�&�8���N<U�������e^>�\#t�+����`�W?���M�Q�A�a d��	e!ј�}�o�L-�W��@����`ںlWt&G�0-Z��T$���!����G��7Z~���u�%������jٹn��z�!Gd�A�/� �y�s�d��[��ܯ\
����+Z��� <�~A�ͰH�DPF��;�2�����r�t���f��'۩�)!���n^�"�i����ɲ`ؼ�����J=?�l(QѺֽ-�D�!��e��lM�I�F�����#F-^z��[�����_����]p�����H��J��a�1��<[�Zy! ��̚9�{��r(�2���������{���ς�=�
��,M0�̚��b���}�/��rI�[�[CY�gDe�ɖ�ޱ�i��J��_nA==XӚ�^o�P]�,��	���*=у�ʝ�{�pl���k0DZY]r�=������8��㥓����Q��yԻ�?��b��	�
X�!Ĳ�׾]h�7#2�_�)������?����t�6�r�R��z�7�47�Q�d{��huVX�c��G�C�n��)��`H<>0 �/����U���\_�a�@�b�[~ʵ�Q�EP���B{=��
�u��z������"�<������qvF���^^)��R�����UL398⁺�n1�s��e����:V%��<p��y�������hΏ+�Q�GyD��/��q�Z�{R�C����_�rU�$�TL�qyU[�rR��ab�"�LP9�	%��IHp���F��/�C��F��a_<"e�N���i�'� 7V�BՎV%��Xª��8����_�$����e�g#����\���1#a�*�4z�j�FݹN��~��/�D�Ś�wS��f4[ ���yá���U�~��wkzL
*
'��:��wM�"`I���$,CxZ����C���N�纰Bַb<W����MIIl	m@x«�4)�8~h�����ΌX���02��"K �6�:E��:}���$R�v�"jq��X�gLAdZ����n�m��#4��f:����#,��C�yd�?��6����ב4#�>É�n�z��R�6��b���o�D�� .k�k�6��n[�t�D�Z������вLO�;�_����z�_�X8�:����� X�X�SHR: �H�Wp;w?�X	�p�C>xuq�FX�j����_��-��~����~J�Ѡ�Z�7lp_O�B��5�IVRt�44m�mM#DA��3��9���Yj�S�{/�߁n# ��/�*�2��M&-[���R�~�qA��~�ֱ�G��>>�߳Y8�C36\�N+�@'����Ũ��m5�9��o6�/�i���C+}��E4
'��\'��֍��M�F�VR�@�����=E#��^��� ߀=o�
�8�}vk��XХ7T�� �B��Ԕ�)��[(��A�!��B���=�g�3'�&�p��Ǵ"/�7�Ѝ[0����x�j �&�-v��2�ݩ�Uy!Wg��������}�ֶ�:��m@��H�ǣ�qe�:P��0	�
��R�֮�Sqro�OW�����Y����}�Dh{�$������e��Ҏu��sA�<���+�Bż��	}l�f3o	I�����[��b�C��43�����d�ڦ+A	��=[�	
��а���9c_�C���c�6s)x�=����{&����,�}>�K�Y�b����|T=��5�S{V��ހ�*�%ې��XLw�5p3nc!sM�:VUw.A^�k����hr���DU��	��S�|��,b�E˺��(�Q��6�``��C.푈ȩ�:��},kȮ��97J��x^��Mĵ�J�u�1(����7�Zf���t)��%|��	mY��z�#N�'TBZ!u�t>qyz'L�5�=b��|a����$9���<�è|#1��2S�/K�L�n
��;��үd�����������j�,sbw��g���+�C���:�r{#��sb�S�翳bo��H-ݲvq|J���F��ea��%���,����j.�k%
�Ծf��y�p���E�t�@)�o��T���>��Qw��Ν�O?�g�d�b��1�3}-*�]���#�GA��EN �Y�ܷ��8��Kh�A��)=E�d����ACBM�����X�[@S�|�Њ9���Fk{Hl�m��(^�����=m� *|�p����n3�(m���}��$�1�$9$T�k�B���Lc���4�D��oZ�=K���25�S�q8(���!9P�\�e��������Q	#%=�T�}���>�����Q����*-x]2���-��5����13�\�\3�}�w���K�֦�,h%;X�;�7��j��{}�溵�2��d�q��'2�#�B0g)�7ӄ�?y1�d�؆@���l��'b�:��ԉ۱an(ތ}H˫K*���^����>�/���9x;)8�q�$]�`R�fH L���^�3��l{�H���hd���^`k�v�������>|7e>m`�,Bq.�I�41,6Go�ۥ= ߘ�r��
Ĝ�W4h04�r��D 5��j ����^���w՚zUֱ��M#��Lñ��vO��� � �_�Ŭ�xib�\�uQ���P](�F�����
i��#�ۡv�-E��i8%���¿īΌ���,h�M׉хe�j�����K��Q�Ӄ������;$g��ȍ]���6D��r*���Ͱ�ib�NC9�������Wb^2��f�m�~��h{|O��9U�~���R�Y�A=O_�����d�^|�_����ҫ��[���3�����B������8�k-��ao{��i��~&Ǻ�As�	�}�r�5�����;��z�![|B���z�=�1���8b��h��k�5J�
� �	2e��U*�҇u�,<'cM,*t��:7uwB�
�>:v[�X~Qo�a�]�����$+TXG%$�gO��+Q�_:g ?�
�<X�sv5���Gg�{Qġ��U��ׅ]�Tّ���o�L#��	��:	������h��G��F���8Л���I�<��+
�\�S��a�
Y֟T���^��#����e�~#+^g��}4K����j!t�c�MƐ/UR�0��O/���Bo���tE����u>u��r�%�V~!�Z���������N4�[3����Z?���:K�r��������B_3T���O�
�z� #^Ŏ�Jո�b�2Ñ�J�������-�+bYd�;�HZ��?YnP���)�r,u���P��v8���%BR���<���7���T,,�'�Al	�ɲ:B.��͟�խ>���$9Y@�\>*��~���"��]ϼmߊ��FC�7�n]������m����ɱ��^W�5#}^v���D
y}�ް|ho'.ϧ~��D�m�.��.n��؊���\AD�"�>lz��}�W:�z�]W�����Ҟ��!���퓅 8��Vs�Ra@O�%��*ѐ��/�c\�a������<��n�=�rڻ�Z&[���^��?�~�J#���E��C�A����k5J����@��;ٯi��#Q���l?�x���K�d�P� Щ�ʝ����p����N��=Ԣ�E�tڙ��5��8�
t
�$�m*6�H�Ύz������Sr��k ���xp�8��b��Z_]�qCsƴ�*G=[C`�7��O��v�s�_I�rU����0z3ai5�d��lA�Aq̲Ӊ\���L�.��I/��)�I�}l���u����>ǆ���&��z�l�Z��4�R����h=�M[Fnq��[�GXS��/�$�FԣR�.��'Mq"��,��~��Bo���N�O)�=Q��Z5����^Ǖ��ɦ�3g�&Hp�K|���b'8��LV�-��� �-1�W#:}orL���o_7(nO�@F��O彫fHF�+��������%�z�;G��OV"'ւ�������(��3���Z��zE�'3"0y$v��&��Rp�{cD���U�#Zo�d���b�5F�����%�EV��ǅ���!�UP����ĩf��7xJTO��}��[x�����x�O���I'��P�@� A�^(^�ZsZ�WEoF������i�{������$$P]:,���@ꞝű������"%�f�,Cn5s=O������^�+����f���M	���B�Z�����u롹:�� ؾ����O7�H⩊�{`�{�+Э]���۹��[����݊wvEC�-���p��-��e� �ؿ*�� 9�<��,\<�*�а���	���)���(<c	8Yd�`7lI��Bg���F�i]x⮳M� a"կ}_�7��^l�Ͻ8u�񃷝���-����� `���ڀ<�<�� ���4�\�L�'���L��=h��"���>v�2z���3�N2��(G�6 Q��k���uM;�-�`Y[#�2	\��6��*d����,�P�S�U!��aF���d	�q��:G���֙igC����̫M���4�q�.7{v��U* �kl�J�����A$�|�D�Q>ef�����#iⳉ�?�K����R�Lk�l��i6W��heq~�8D]p9%:�^�JҶM�1�g���������ډ�J�LbԙO�,Ёhwfa��b7�wV�{��, ��c�,h?��`��-ϵܷ��\���X���K��W�!�wdEѽ,�該��fb�U� ~��늒@�Ƃ]���y���^�qM�>�\�u��ٺ����o�qu�jK�|�O����Ė����?�e�έy�9Oس��\��(�A�+e`�Z�L=��@��.�L�tb[PD��-��:�\�ދ�}��n�_y{CF�kL�/���xO���y�ǔ���D-��vOUn�#!@}\�뤽�{�,��ͅ����`��ߩ���sO��J>�jJ�ʘQ�`���(�d+�B�͔�X�m�^�>�����^+|ߡ02v�L�p��l�?�,�a�B����O�˸p�U%�#$e*֤<���_ad��K>}���`n�o �Em�HD~jd'K��%�q����OEw�X2-b�cп�t�M�c	s��uVG~/�������zh�Γh�Q���4t�?	���0MW�Q���P���b�hW"�h���)�����뗭��=��1��Z9d���K���j����$A�?LO�SZ6�������	�P_v	yX���9�V"&��;��#��E^M�lySa�<UX= z�f���1��z�hȅ[aO�˱���#�Z�0R8R���4�w�� J$7J�:&�t��S�J��Ӊݤ�R��`���ܖ�~����0��!�����$��՗1�}�Y`���3HBć
�,9$�q��9�Ơ�����D4��"���� �p`�k'
�h�k�'օ5�����������'�}�YZ2�D�nm��<�ns,O�<fC�lTvc�у���u�X7��.�W��x�_V[l�P~�&���tW����:u�����=����7�R�_�$~��@K��Ԯ�o¨���R4��D��-z)�_���R�,�B��~
�E	�ZK��Y�bP��>W������P�E?G2��<(�ӧ�D2N�V?� ��|~JL�z��)0���T�G��s�Y�8�vs���Y'�i��ށ֯�I�?t�)K9��O/v M�~��L����#��R���8��.��+�[t�ؔ�⿪���;j��s	%U=���{FgD�~�l�E��+��1�� O���ʍ	z�7�Gヌ��`7����B��� ���;)V8�c���P���B�_}]��������R�(*�+�V�/�_)M�L�%�+�D(�YE�wIC�Q5��Ai�`�ê]dT�5Ȼ���F,��]��(��t�,�j�q�(��42�[�ײ-a|{E��L9'&C��?�tE8�硹Z���%S=)�K�r!ۆx��4rQE�&d���D���YVh��m2�O:r�צ��A�~ߎ7��0��2`��4��"�ړ����r)
���Y�1jy�,exr�6��l��CR�g�_:km��. �mC�|��_�P!�G̟������n���(��?ɋ��t�R���3`��*Je��3f#�Z�R8�������J�-��OUz�)�<+��l$}��nl��|��&�R�n��OB����5m��82�(���&H�Ť��b4K�����>c哬x�߆�oC�h�h"E�
ܐ�� ��?h����nR��0�(ќ��)����i;���*�e��;��S��|���S��e�=�n��D���Ĭy��0{�|���*�T���+�"Lr�0�w��3�u��"�m��kY���2	�N�ǗmAUj���*l˶Mõ{(h���f�ęG��eǭ��M���a��;���"5�N��|�V�(�Z?|D���,3m��^%�ӔV��ڳ�k�J��,DI\ש{��#���r���q���Dj����X4����G@����i �&�B�Q�:]"Q��H D?Evu��a߽Ԧ@���z|
zJ-��G�]G:�L)l�p�b�� R�9Q�[X༨��y�
��Ӏ{)@�g��:���8bSl[vo���E�A1�eA�����tu]v���܉��r�b��O���1*�
5�ܓM��-����O�n'��M���I���J�(2A��f����b$kB��<���p"��V���߆�Ԓ�E�j�a�DHy��X3�#��e��y��r��|񢠒1q\z���z�r�K!$�H��df�KG"O԰��v�����^�j�_ ��aK\mrW�4&�S+�<[�+�7�co�h�ڟp	1���Kj�A;d5Zu��\dM�k|�ù��)g�Ƴ���.�fI�M�I%�D��+|��� @��du9-���Lc:%�.+��-LDg���&�P O�����h�s*�>�q�i[n�k�E�ZF�=#7Lq9��j�ߢF�/������S�=T���Lnd����M��.�Ex�l僂��p�E�fx�&�a赀��\�\�����DIi7W,��A�S	1`m�6�7`����cCd�!�~vhO�Cc�zӣ2�W���+W$�|j�`2��'��%? 'F���<��uԃhU�?��n��cVn��)��:�q�i��A�����>W�d��	���F�iဗ����3��֓?t����1���@�Q�J�#}��l�֙b��f:MW�EQ�B���G���b�a�3��|���G,*Z�+~�j�0��E�Ugz?�Y|ڃe��$�ՙ�\Ǻ�r�9,B��CX.1��{�$_$Qv�3ʩѹG��o�2�<�}G��T���:�W��u�r��
2A@�OHÒ}r)*����,�z�������J���*�8�*dt�ִ�μ
t��>���[}O�a�-��;���M�{f��.p��g3��/�8�`��{�H��h+���)(��Q^�0N��δ@��q�]Ҹ#r����_�z
w���<�<4[�2�{vb]�&$��CAH�f6^�:��{_�n�tH�6B}F���3���W۰����G�Č>�Uv�fc���%N�������_�a+�H<h��� �-w*����120s Ag@h�_�h��=#�u{�M�Zm��f�{��-��ƶ�|5^��O�t�]o_ �8#T2Uf�*
�3[���i�<�����M�(�H�s�q�١��r���H_�O�%�6�)��oí���� ��Y�$W;(w�7QA����՘;c��8r���\(��Z�O������5��Y�.Ѭ��k�`�� �LH���:�t�v�� �z���w_(���w���!W哵\2#)��y��+*{}Qh -�u�@	� #QX:~<{�u���;.��:~ĳ%#����M��O�^k4D�C��޹�3�b��t����1g����٩�
��BEğm��a�n�H��C]�3���A�:&�0���*J�R�Fso��TX.�q~)�n�[7d���B���G�~�0����M�5��D�$"<�%�@R�舣>GC��P�ruh�~�r^d�-�)�H�֯�/1:�.����X�,�x(j~W�^�+0qx��<����D����Q�xg��<��rb�?��d�B_��ʧ-f��������>�O8Y��H�?L��])���յ�S��5�x�9�k9b���#S�o#S/څ����qJ��Ŭ�&���t[�b "��Ms�����@O���b�+n�ɺ���a��,,07���Jr�Тx�;t���L�>��=0��Mu9��;�_��P@D�
W'��[)�S5er������(>��\bqJ0Z�&o#-)��CD�d��%�T+]��	�p��=T3����.�eL�i�.)�������BD����ݯ>I�D٤��e�^RX�"�=�J
+��P	�ԭ�4���������w�>B�����c�w��]�Tx�5��̓�n	�y�s���Ew���Pб-`B��>�%�'�9�/Q��EOy8�� /����w>��rA��GYyߨd
IH�:d�F�^++�!�����Qr[����S-�t������J-n����Y=2��v�����3�� ���� �K�6�FU�\��Y) �
�="���EF��Vc��x�l��[
���va8W�G��&
T��_�P�}����SkP9�%=����4�ez[P�ӕC�~�z"}�r���?����`�� 2ub�9&���z/�e�����t� �q'N1E��w1m��Q�Tb�m����>W �<�5�缙aB `[�(���� ��݇26>�{�goQ�U[Z�K3+��&0�!�*�MBШ�Cl8�tPJ	�M(5ﶛ�|1%��~���;���]�a�Tz��Q1yM�j����������Z#kŻ���/q�w*HFi�|A��'�OK��[9��6�A��Xk5��A����H�kf39��������؂j7���z؆{��wF��e���<�I�ޤ5
vv�K.G����.å
⍘�ݏ�\8]Dp�������a"#�"X|�(*ڟ��
��H�ǦR:Ѧ�������n.)�?�� ��!U��j�nvK�[��`��������$��W��e�IWܱ�n=݁Ehֶ�Aa-��į��-q9�����8�^Z-���aD����?�Ƃ?�vRK�2#����4K� ��$�P�`�m��}����fW�Q�%��nu }�M����Sik��p���2_Ӷ�r��I�E/��x{��6�h�q
&�w԰U>哗t?j���lj��p����by6/o/L~BL����u�gx�wl���ꕺhL7�]���t��2/Uml�4S��5�Xl��>Ц��g�C⠘�T���>6s�,�|���Q��H���Nm�S���h���:�JFR�f��̊�z'y�/٨��[�o�^i�`ZM8�a��KN%#ݠ]=l�(p����`�����A-�=')�����h�,�4���fY��!OPbˆ����6fN�#���ռAX��s��ס����$q��*���)��p#��`�~���-�9�D���ʘ����_���r1	���>ҙ�^rt���o���ݑs��SY�\�I����#���	m�,-+�4p7q;��G�I
+$ ����-���Dc����X�4Z\�f��ܗ\� �jo��Y�������5�%!�����ZO5u@�{3;��e{�2JB���Ϗ�;�
cu� {R�&�V��O�{�?2(a�d+�g��oF1�S���?P�I�|(��h��������!��;�m����������1��b��x�VwmCƗ
�����u}p���޵P�,MŜ�Ta���GM��7���y���[���n3i5/���8�E�@���o
�&s9��h����<"�w�Л�f��� �:��H����z>q6i=�jb��K�\��ŦRu6j`��(�����CC4d+�:N���+DP��3���pi��϶?�C��o��460� ��R^U�.°!\m��:K�肚\�҇��|��	���О�4�;q��ʦ9(�]���pP�!l��پ�����WHA��#�8����ng�$�1Y��{�}~�ٜ;tƝ���\�~�
{b�RbP�J/w����ͼm�s1�L$�=2P�qgi�\�&h�:�H��C8V���9��x��/��t�)��2x"}��g 	���������J���Ob��_�n�-:���\�� �: 
��Xŭ�,��,�i��Y]-�C�<]�CHC�T��.�-z��}޷���t���8��,{�N-�|n(sYc�0����M��G(��������{e��75M�[}��䎎e���,���>��H��-��*��SLo"|\��U(��3]C�೙Wc��s�~��JO�Gg�|����ОJ�;�� ��Q�=��d�%��k�b�d�p-k
��������d��S!�D�/�����"s(��\#5�˪��C1A<�!
��ܘ��77ʦ h���{���év�~��B�j,�ӠkSڰ��� W���"F�A$j[\����v'Víj͌.S9�g�6�Z��O �?õ�AЃ�u\ai,>a�2F'�k2G"je;D�/��{��qZ���<ҟ�;��y�n�Y1�qqڬ����ې���c�/����j�0�ToƂ�}�f��e_Z�+Q���������X��������2�rB֦�xB�D`�F=%�!m���'L�^gG�� �]�7�p�W=��#UU��i/M�Y�������'�TЃ���V���� T�9��X`cߦ���7ɿzI�����ϛ�/6m��>=�_R:�RHG�\�"x�
(q?��p�H�e����8��T���7�8�ѪD ����F�$��a��e���[�:�VW\_��i�u�Aٔ;�S��J���B���� ���,C�&[���.�k-3e����>G����Y����T���gE��5�����*��i�M���Ũ��L��'�_|ZXQ��W_jQ]��hRiNa��?�O���'a�B�	kQ}��B�K��Ho�V*�APF��^^�&�C�2 ��:�7c�kD�p��q nq&*R3�CU'�/p��)+&�g��*���N��7�I����ڎ{���x�/���C�d�f�^(G��]sP�#��cS�>�F���T��	����ً�+�6=mP||4��rr��F_A��n� ^H��W��[7jb���\����X��太��'����])��3�=�D��~__\��5c �@p)ޭ"��%ȹ�� /xd9`��ï.Y��>3hdE��-��-u��j�7#^�����+Ϋ������px���)���'l�@��ɩ�{7�9}MUr)��>��2�L�g�d�W.��iK|G�]��}HpT�B��ml��޳v��˩���m&���Ot�D'��RA�eK�Z����	f�%~��k�v�?�ͅ���\%�$uH-���P��HW�j@��U����<�s���7��8���o���7��[���XV�v*�^<�}U~s��H"��^�n]�5����_���b�_wc�Λ*�3�yO�	�:>v�K��Pna������;60�՝j��<Q�S�@J=߽�K��Ґ�^��#&�3�7��K�HX_c�e[.�E�Xz[�Ivp�Ci`5W3$�[����jȠn�<��[���?�� �J	 ���[c��b�M���E�b&f��O#�S��z����#��DC2|�Wx�g����)Fd��[$*�8{��bu�X��|��L����?���C���i��}z�t��Ƹ��6�n�^�>b� xy&]���%���{w���T@�:n��;!#ٳ��R4�6F�˫;�d�*����@���L9�{��]\��9B���)��K�������M6��3��4��\�����p��UQ� ��A��W��h�V�Fng4���%,��˫����b��b�J�۟ ���"bP��x��eZ�����_���Y�A��ӾP��k޲������DlDȎ�PO���w�ZHŦ�Ƅ�3jSY���E&[���������r�ig˸�a����b�g#G�'9�����d���H�q�E�u���U'�:�P`�ש���9��v!�� ��͐2.�e)�Eԫc3�a��I�B<�˩i9�X��O�D0�h�\g\`!���Ġ��v�C��UTOW�s�FuC/�<Z�3}��'��J��$G�T�������,S�7-�Oc��y�� \P��1q�Z�P�4�]��;`�+�U��$�1rQ�Q�gY
;ΰ�:K0�N3|3�f Ώ)��Z n�C���˜&��vU�W��(����Y79��5!̻�)@M���"�%�#7H3]�h�>�j���Ϫ����P+f��\<ÇKov�@~H��fOm=��j
(v<s�H�.�
�)(���n\?�&�Y��H2�>D����!�_��d��8��~�$�3<�|�P�Ďđ��{o�+b��[��Eޑ܏�T�B�xt��{�J�H��	g8E�M��#��bM3���~�R�ڝ�h"�
�j�� Z��C��wJ~�c��L������Q��c5���\L�S��NdJ]��ÿb]�}Y�Y��W�7�=������I�ЍG��3��_����,LT���^�n�W6'_�<��;U��@o/����=���T/�-e����C��z[`�n�y�.W��h���H�)�/����E>%J�+gȣ���ɧ���a��@^�yE�4豪�4� �B���>u�ߢ8����Y�s%����p��(i��W-8d�٨�ױw)� �9Y���g�tE�.��%��u�U��_;�6f�x�q�b�t�k��]�s�s6j�]�
������%2��+	N_�ש#�)�Ь��~�y�Z������	M��D��ܢ�	дQbr������?���ű�L�$�y��x�~Q�iY�1����*�fM§��d\'ū'�yr�˩�<2� �g������������è�pk\���qUs��W�-_������7,|spΟy�
<N;��h��](=S�h�1J��+Rw�D�EAKš��#���h(���U�S��< y��^�3y��/B�7�̲h-���5m��RQ%�}>nd��!��:Bq�$�Bk`^9�3�m�t������&,��J��U��H|��,��P!v-U�t�ʹ��6E�N�Xz�)3bKF�{���`i�R'y��]*Ӄ������ &�0�U�%w�:�c�<i
�mء8�dv ˈY�ӛ����A�[1�v[ڼ�&��q�C0l"v�CW����K��H<òY&�ц�]��<����μ5�g��/�::C矎����[����%P�� �6.��y��5�!v�S�����ط���H��ռ�!���������s6|�$U /ڼ���C�x�i<~)o:�X��l��=�j|=㆏���r���Kes�UK�L[v����׈E�����x�~9 ��y���5������U~K-64��g0�xh>�ߊ��jS��q�z�ik�)'Ģ����k���W����?|����^?#]2�[��A�w#�����5���u<sћ�ҟ�?��X�TX��T��>�� �eʈ|�0���sͫ��֦t� P�C{ {H�zW͏A+��:�A���w��{ (ia�t����Y� v!���z�83�"OBXyB U������i	T8F���k�X���h�ML�q��!+���E0ot��3�����:&0D�]���ÞB�Y\7�k�~���UrAb��)x��t�(�K~�Ʊ >h��q_'��k��h3:4��ZR�'o3�C|����z ��o��[���e�Ʉ7>�A�!(�Q�?8Ȃ�n���a�B�����bRz�/�{Ӵ'�~�U�π���Ύ<��3�ݖ�3?};ϓ>�%t
K�N
��m��Ҁ1��}���f�v���j�r2���a�����C�J�����"����b.�C_CD�^�tw�s��6�y{�67Ø���D������Ĭ��@�vG;��3i�������c��<P/���Kt�n������Rl7��|L`�����TZ&|;Uq����l��n���|��N������n,˨-�j�Տ2�{uJI*���t<�����cmh����-��3�h�H�}���Z���c�g�*�������=�C��+7�˳�HA�bb�����_�5k��n�Ej��'B���X)~TRA��M0��с�=��ai4��fF�y�����H�o�Ce�'S��hȫh�9�{)v2�o:8���J�-�m�EP7�XB�a�*u 9�9��?y��vV<V�p���ǯ:'����B�~�I��M��Ґrݓ�1��	����r�(��3)oI�dG9����7��Zp��0N�9(��x ��eW��Bk�};*H��؍��沲�|�&m�絻�^\�%��h}=cF���8�mD�t���{����+Ke3I�ɫ`�y��F�s��#E���G��-l���ڞ�Ṟ���+ �>u@h�R_�0�I���y]:�
�%�ӌ���Ձ��n3K��D�e���Sg<2��=ԨQ�B%з�%� ��Lgp�p�����-�x����У��kT˚&\yꯅ�I�T�T$]�] y�b���u;��y�ay+8. 5��[̺���<!�_ '���x��0��������~GE����ϛ�)Rd!?�NcQ%�����ޝ�ҍ_����HJko!�]�<$�8�G=�f��T��E�6z��E��Bg��Ԗ�[D���sԋ9Ж�K3܄2��k��[��BF�%%N=�hDh`�
M�jx�R�%#��$12�E�ɲ���&�g6���N������ow��b])m��a�e)f�G�H�����׻���.4A���3l~P�ڒX�����,1���ku�Yx�eAT���-`x�"nld�a�.@��l�Q����~�/�v����i�_2�ƚ��D�E�����}���<�j����ֽ�Ą�7�5�]�)�X�[0�4�`w^]�+��8�_EyG1��"l�V��[����﹢N��]�%����S$�M$YR�G=��?�������RyC]�^CY�G�����ϊ�h���t�/��������i,:l0�Y��&�b=��u�����3ݮ�O��z��ߟ󫄊-mlje��e��v��D�鮪d����G�E���������y��~���㓉���CWo��A�;�����eB#�y�)���'�Z�}
%�ʜ_Ǌץ�֮<��F��Y�Z{�$P4X��s�mRK ��8�")�e�y��T�>�:�X�n��*�Ծm��"�\IO�T��PE��P^0j���a��=��"� �������8X�i��@
f%o�n5?t�ML�d���ZOWbo>����V>Ume��آ4��ݐ�9}I�c�50?<��L�.�.�g5�EK��>7�I�ƿ4^�^��H.>7�۔��Lom�׵���՚վ|{�3�����92('e�/&X���eip��#�7kł_�����L:������[DP�oN{4��.?�p�	+���=%$XS��@�k��)R�4@��Xo�"�d�g_�2H��m_`m�6�>4J߁3��8x�z ����B�S�i��^�5 �n�j���S9:��T�8X˜*jy������G*���*��CN��16�2�J����n�f�<ϣ,��J5�!�4��}��B��#��aQ�㓛8L4��bxK|ľ�A-ht���8�,���E����!�_1�IE��[J�Z{,�(�]���$���]����źkS�C{�5"��a��3̧f|!�<s|���:""q:"Q�^�� ���?	%�4Cuƒ&����iK�/K���m�nm�^'I�8��&��3�f�����T�����v�NL���u�2	��t��OW+/����ho��?�tҫ.D��A~��+*��0���u��H��i�ܚ�C`p��P;@6�$Ň9����=*�ϙ�|N[��'���Eo�;A���]��n��Q�zF��\��C�u��u���$�j^��K��vk�pq���a�#\�P�u_�^��λ��'�y�(���nq�)�\��$ ��Y{\[�﷬�� �����\;��>,mvP�(��hb�ڧZ������v�q-�ٰ����-q��V�ޟLm�N�t-���"�ەӪO����M�4Ʈ�2���@3�@"��TR0��~	/Ps��J�w�����	))-9�1��Jo�:>���VT����R����Z�/��|y�0�=��D+�T�LJ+�� n�nݥt��t΄(����HW�	�<�W�<A��_vV-C�r����?�L\���r!Gdm&g^}�W����"��R�� �k�U~��Н�b@)I#�uO��K�j����X�,�{q=-M�#��Z��X��8�U�܆�1%LyC[%o�ɠͫ�4s���T���B�<���.��D�r�n��.��p����~��a��c��{��$X~<���(���?II�褑od��3����ի��4������Tp����v�?Hn��n�S(e����!���KL���%��>�Ƌ��� ��G��8c%ܖ�}R%����,?kX��H�ǃ�����#`�@����&ݙ������m�2�ߴܔk\��5t!4b,50���L)��L����:Q�M�V�M7٤Ċ��T�<zqT	ۭ��t)��N��u%{,T1���=�dq}���@'���,�^F�*<|R+�^F�a�NZ>�]32�?�s�\>��3.��K�}!��y�MY�Ύ֗o�z�Z,��Hp��v)c"R6Ij��`���D��T:���������Ţ�gE��w���CR�.��)��C5�S�Q$x�m5�l`�3�O�0>-���{!6\D�r�ғ*��&3�ۥS0�(���VT
���Nnn~��)v�Ġ���Q޾����饏�SM�xh����RRF��c�ʪ4�$�E�����]�B����ަ�巤d]e��UnKBja-�_�O�sx���9+�T�](�TU�'� �y�n*�S�9��t��FP�*j}na������7�}X����s�I��W��1`��sq�?ύW?�V�q+���wC�f�u\^N+��M�-g�y�ۦ�2;=�*���\��ԕ]�4��k�%�R�2�I�M��d��"�t͚p�O�e�Fy���e��9�3���v�8�9����<�	.1\�*u�K{x/��1��%��j��g���\�\��Om�{{�x}SP�ܪ�ct����ϗ{�1�C|ie��^DZ[�'.ٸ9�z�Paғ�Z��p�b}��KxE�C�C!`A�7�W�����Wgq�[Jm8����W�\ 	䨃화��x����q�O<���������C7�%���E{�7 ZG����5z=Xr�k4-�A��髣��Nh���d}I�<�g��a7�h��q�M��>]Ԅэ�Y�3-p)��"�~��Sn�y�����i�F�����E�'����� ���)��|�@��^�����ڵ�G_�=�ƔV���wТ�e�EĞ���~�}��JL��������ʘ�Pq:�d"�q�sG�&]ybK�l\�opR���J�Ic���y��[17�L�dԨ �G&�=G�z���.�e�$���=QR8���u���\(��t
& d�A�oN��_�^�B?�P�����Z�Z��!X�4k��Q28,�	��Ar�n�A�8C��5i.ű Ԇ�v��%��Hz5C�)���a$p�ANT�^��0�i&�n�S)��,Dȍk!�sS�<���=������++�Eۑm�Ce>��.��^�YC��Sq��8UUt�@J�3�,W�$Jtw::ٺ�u� �{�l�)O+8��|����N����@��Ԯǣ�ߟ����C;�h�q7.G�a:���0���B��5�MRB��G�up8�j�n��I��6�K+�o�+ۑ�rFB
��G1�&��pO�p�Y�N��PC��H~icN4+\��p���}u>��⬎�����   �� M�d� ������ٱ�g�    YZ