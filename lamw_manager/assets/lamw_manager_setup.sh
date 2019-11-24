#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1335344665"
MD5="60cf54a8ce9aa355e36e8a5b62964267"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20453"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 18:42:55 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=124
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� _��]�<�v�6��+>J�'qZ�����e�*�쨱-]IN�Mrt(�S$� e�^��?���bw�HQ��6ٽ{����|t]��?��y���ߍg���w�y������~������zc}ck��~�>̀�G��W������S�s~1���9���d��6��������?���T��Ƕ��Mv�T�/��*�S�^ЀٖiQ2�L���c3��a�1�'Mgnb֔jˋFw�`bSwBI˛�t)�W��sw�z}���T�a�.i��m}c��#�P6	l?D��%�,�*��� $ޔ��;�����ǯazT'�3 hp�I.��i@�^@T�uH�]%���ԯ�I�^�о�~~zh�'�����PkOդ3:>�:'�a���X"Y�\ou�mCM�O�Q�e�M����>���aw�~�f�-�e��9xa�(W)
��� +�C
����^pU�;ls@{J����{��׊kQ��=�9W�����`~����U׹�osv��Q����ŵ���R�\ �[3��s����[��;�o���e
4��?�ʞ�]���J羞��O<w
�BV�`�dVu���� ��{_�=�,���|��p�SF�@;P�T&fHtN�Y�E>�+�������D��Bw#ǉ����|c��d7a1�e�k(A���1g�O�ҋ^��NGSh�7T ���k���ə2���&���D-����t�F��u�v�_����oH���bz�	<dă������P�te�yAT�|���h�ԩu�ϗ-�pid�PYV�Z��h�j:[?r�:D��zbѩ9� �l�y�f	�Z�����R�:_���Y{�c�6��C1#<��!��?��tB�� ��A���Q��7���n�3���7�|�WI-gي�����1�
�.��vH����P�J9�:q�;A'������Jc)E�"�BI�J&	�djR V�X67��t[ycL�ܴݔR�8Y�z�����>�J������@��$��D��y~��1��쌂���JE6�� N>,�oEM�X���:�/�� �U/�/��@B�*���xV��7�=�y�����w�6)b4g�v�J�t}�|<@��MV~E�=Ǐ|��ܰa�b����SK1 �-����q^
���_M�� ��r�������U���F�A��3��j�_t�s�&�Q[��9�`��+iuO:����>_�$�Edn^q����Ga���dϦ�$�>�{�=�!'�`��qcJ���|Y`9��̀��NV��_"W��C��h�mQǞ�2
�L�\��9eԙ3�EH<#����@�tbd�c:�%ga�]]O��mO�:E%��Y�;��+G�_���xD{f&L`��2��3�D<ӡ��:y����{��uM�[�8�{��_���ÿY���x�P����?�«6�lǢA��}��6{k��o�?�����g������Q��y�&�������vp �Ȍ�4�a	 D�]��xT��/��4��֋�-�4]+�l�+9v�jѐNBb܁����#S�q�e�#��z��e��ǿ���)/V��/�H�֝+J��&��6GS��Q{�V�m�"Zwi���a���X��O��q�i�PW�`Z����ȥ��������vd��%9��4~��H�̉�����ج����xN�G#X��&[��i@!��(Ʃ{��t��3�ԡ�x�9Z��&�2:�<�����G,�{�9TUk&`�C �8i��tVD�o������:�v����E�^�F����ȥ�{-i��%A/v�' �2.���9((�̍�֕��\@bJ3W^�+=�B�qu87BeX0�� ]J^Ǿ'�8�gf��Q�pXt�S��Ds�f�������]!xr��a�gj�/�Dc�/~y��ARC.��*��|�T���_Iw%L�/Q]�o�`v.���r{~������J�Z�R�ATu��s��ڪ��7�����p��H�Tyƛ�'pO�E�]Z!!���2� �
8Y�n�?=yIRC>�QX�ϱ�Ɋ�Q_����l�W�^j�����&�:>�������G�[G���7���6vfBt
�cH��y��d�<��Ʊdƛ��Wu����7�du� �N�����BoJ���F,ץ� �"�⠧�uKMy�3�P[^{�xH�����Q ��
�ŋ�	�PLx��<Ǧ�9�`.Ny�LwF�s�����"%��uW*X� ���}�N��d�#�-�V�t4l��C���U���>RIw���������@ �|�z��I����A�զJ�����7�LEp�ʗ3�+�2�[R�dw$q��[m�QIËX1D���� ��o���D�����{�����#��ӹ���� X��ݛp�vx�.9 �L�MV���I��<�Q��Z6\�U*Yb���i�T�U-�ij�].�+�*��2�/�g���Up9�Z=�hD���.4����V�>�ǐ�l�������_"�y�xq�$�e��&P+�g�C��&%�x����`)�X��Ɍ/m>�K�O�>$����E�HN�\мغ��m�?l�cH6d��`�0�-�{^8��ʖ\�dx���EB*q{Kj���5G]4�͓�~��?��p�A�)�x��fKT_�5<qv	5�K��CN΃��!)}9oKb
��呄X�]�,W*�b�3'��
���>h�����2I�mע���K��5��x���O^k.�L8�Pe�����kFL�a�lpeX������r�{��p���q�w��_�t��X�%�p->o,��{փ������Cym�#ă���F]<&^'.+�u�z��p��X���ۡ�g�aMB�ƕ,�ߵ��x>?h�F�!�nw8���	~��x-q	���rp1?�D�s �'���p~?/=�����C�W�V��ޚ\����(���$�Sr����<D%?���t��5Al���C�Ԣ�MB��v�)y<8}>�u0l����=i��k�zE]�n���W��n�g�;��u}gg��Ӟ��N4��;�1!���RQ����s��Y�vC�)��&���`��p���œb<V�B��i�셇�����u�{�$KA�mQIU?�2"g����,V��fxf�.Xj^! �r9�]�$by +�٢j��F��#�4�	ҤV;�vk�*�A� !�hJS��1�S��+���<�GƻIͱ���N-UZݵ�u�1C0Ws���Zt2Y��ۤƄ=	�#�m9u��q��;�<ra�w�r���?�~@����U��,V�<�������0�z&������g�	B��%P�΁Z���(Y� �$���
��7���$':�"T*��Ƒ�R�ŋ���IB�v�=O���S��u&=��=��5�#
21��
�Ņ�s?�XPx�����MH2\�sܸ��ЧU�N%$-����e���@�X���7!b�h������`�ȋM�3c���J���(������a����A��:.ؼb��D��c���;)���G�a /
 ey�՚�UzN���RX:�mi�s���R��Ubo�t5�	��τ�܇<����Z��e�#�EK����X��[�p#_�$g�2�Ja��B�(��L�5�V_�A�r�)�cO��`��Q�����]f �{���+.F�v#�4̤?b��Q״�&^D�ɓ1�cX�YSD%�{�Ҡ�8i�'�F=׹��ok�!��j�++�#ؘ7v|�:5�)daM%;�o�˘{�%�of{;���~�`x�s�:��<���1N
)+�H��q欙4M����z^��eE/'RT��;yT�9/���?F�+t��8!I�z����%�)O������S�*1����7{�w߭��O�^2���F�x�$���O�����w{�e����F�Kd�.���ӑ7�F�e�����!Gn�\�ZB�;xSb� &�*����z(.��LO҃��V~z�vܩ��{��r-�A���m�O.�������}��@8����z,G+�+f�����|?��w�!xy��,��=�IY�Q+4��O�ي��cL���C�a�{4Ƞ��8�ɾtF*=�N�2HM�Ԙ��FH#��XLF��^�����*v�˦�&q���֠#��(�A2�w�A���źX�����Iw�9�u4�pS� ��p��A�#D�{�|��L��.)�w�j����)W0g�p�n^�6<Έ�rr�R\5O���{��o�f�� �c�-��9u#�Q36�'�ڊ%�[\�n������F��	?���z��o0����(�����.D�����K9��X8�{R<��T�E}���]�=Z̛��e���;3�o�E3i��#�E�sjd[���ޞ�Qm_�I���P�n�<7�+MdTOL�}<�<C�E9����rR�:tYy8�V����xDl��ա���`n��cLM�0�t�S���[̆Hʌ��T܃���!��Bq8|�wx�^�3�➰����}�rLƊ�>���d��2�/5q�p�?��z@�5�O��l+�� 6�[Z�H�Ti#�7��=Ϣ0�c^�U��W`k,f���^O�9tP?������3�-d�>d�W��o���m�����ː��n�g��߃C>���t"jԁi��&��j��/P��{������9��4f����}r:���I�_�S��A�N��$e��/�i��p!�/��?O)  ��6E�>�����3������)�[jZ �:�b!�k�A�E�EQ{Ǝ�Z��]� @�k$���p���Ф�e�$lv����~9w>����~�X~$�(ҡ1��џ`���{0�mx�RQq����I�'J�i<���D%eaY���� l :P�dJ��X(N�(�s�Q����.Y]�EC�����@L��#�erd/�((�ʽZf��ԁ� K��\�I�ʌ'ٵ�����Z��k���o\<���@��s͜[��Odo�������JU��М�(�H{�_�V��qBǔxf�g�࿠`�H2�tC��'iU���_'?����S������"�|�� K!?%kk�J�̏��D�$�*���%���<��6[u	 �AK����o	�7@��q�!�$�|��M�@N�EO8+a̱L:�^��2��� ���/�cf�YDIJ����AhZ����R���})���86>��\h�3�ðL�|Q-�K���R^��Vw�����D� ��	�ma�W���0r���<�Ks�@X���8��C*���[('ٽ� �XOF�+;�������Y����j��Ľ�Ν�:Q�蒋��ǟ\�H��KeL���
�g*���{x<���r\+4p���������;|Wye�]�ֱ�z�2��jy��2'j	kT����.	��U#����\'_&L2o⅐���YvGV�,'�Upu��_�W�?D-`N㳥����(�a­��u���}[sG�漲~E��1I�  uiQP%B2ۼ@��m:E�H���V�hY�w&�a_fbf�l�%3+�* iZ��!"$y���<y�����#�C�W�$E�m�צA4��;���OI��Q�<�/�o0zB��w��l�_̈(�|E���q%� ��eK�����(�w2�k�������b�	���V�G4e)���	��M�	e?U�F��B��w�cXt�?�L��-!I�t7�Y �b(�}�T��h���J�r0>�=5f��핍9m�U�{����s���]�`ڛ�O8,<�ɀ��k���L��_�'W�tTv�euu�R������i��۫Be. R�6Jhni�y+������j��\�E9�!ΜZs�5�nI��׬�:+�fTաB/�tuL��)U�u<��PW���F��S��B7#�q��Y��sp��hM��-R6��H3��E*+�J|�Od�iaF�p�E����٤ם'j�|H���{5��a���;�ǌX�?x�$��U�W���ޏ..�_������F4��Wع�U��`�����`��{?��c��(���t��Y��9���74i3��itq�����U'鏹��{.!�ɖq��� �eu2���!��y����=T�~�}T'X]�GS���x$S��p`|���O�"���5�
�~���ʡPVhV~�����"gS�E?�x@O`�����o�~8����l(���W�a�o0pY��O������z��xHD��'����o2�tb�)�DZ8�HO�W�%��y�� ����,�-���m���*1i�H*��K_��Wd4Kۂ�TZ�,$�e��R�f`���Җx���A6��"AY�\�-P�8Sw�3[���E�F �
v�v��.�JV٪��h��/�����^��r�
�������#�
��U��S�A_q���^3DzB�2��sy��p �Ӱo��z M��}RܼD�A�N	�} ��fq �p�+0�f��:��ڍTɯ�6����N�m��'��R�$�Qnq��)BR�%+y1|-mJU
��r��������`�~��Z�IS�gH�j
��s|y:/T��˟����@N�˦�.vǓi��{��[�X�
*�l&w)/r�#�S>+��_j 1��
CE�@��i�	��	#�8":2|��w�ty�hλVH����e�>w����QɊ%��3U�P?�;��Ky�d�t���F}�6C���0R�)���,�^nH���i)��;+|W �3��N�D���V��"ӹ���k���_y^-y��r��$y��bn6�XFa	Y{*3꒹�>3�� �H�	��O$ɽ�%�vP��Y�CB����3��uZ''{�o;�)=/gb}��%�x2��sLz�qޘ�3�H	*�5���+���O�F�l9!~���I�V�C��j�x�-�|�mw�d���ّ���at��9�M�,�#ep4���n̍��F�{&����|����l�n��m�n�W�
y��}�6;�L���jΔ�
�+g
�2��u�ٞŝ��# ϲK���*)76�����D��-Ė7��a��)�����K��j����T�3̣��Hp�\�RnUǠ�l�/ݾ�+��J���)R~6%6�!ƹmv�
t�pa�o�kE,$G���h���0���W �È{Y��|L����Uv��I��4���*��(a�	����o���j�,�>�]K��c�o:Dk~ۜ���R�m�T��$5�J\h}n��.r��;����y9��jJ��j�׏��F���V~���� /F���bV���@0 $'ɍ
\&\�,��a>_:~�ڸ���K����b(Q�9V<�'����l��������kl0�N@�t������J�}gQir�ݥ�7�������F_��ϫN���U(�1k��*��q�@# �,����*m�pte��/����FͯW7|���}�d���ɛ�3��/��/x!���U�G��D�'	����b�kK��Xc�̯����Ԥr���_!�K_�%E�4|�`겊��4󋚣���&�bj�e�Hn�N�0-x���y	���t�m���w��4�s�g-T�l�� �볅jyMYv�.�s�8�q�'(�u��Mgc~&v���m��+��Y)��`�)��f��(�W�qI������
jBZ��M[�������c�F�b���F����^Ϙ�W8��z)Nj�k�A����Y2�%F%	7i�-�A��K~O���S�K'��� ����������`�7��GV��t9�%���[�7s������-��J��6�u�́�f��1��4���@���?J�\pi�Xm��
�|��]xi��|P.K+HV�e0޼����W;��۝��w�����8F�O���V{��,����׷7�U�2�`���?���L�:��� �zg��t�a�m{�Df�������׵ʤd[V������pF��̈́`/y�@wrG����-�G;�n���� � Q�����Ő��W���1"#K���t|M��=|V's8r���sp_ 0Q� 
/���n��[���5�X_�/ؗ����R���g���İ�~���^4r �t劶�p�n�/&�jk���(`����m1��
4x�̔���ye��,�y+�/ƳQ_�cQD?�\;pxȣ6�9Aps��谵�3{��r#C�v�{����D�Y�9!c9�mڱ��`>(X�B�+��$G%?���
�c�R_&���U���$�!;�~��%�-{,ak�]��V^�੎|m'�����{��b�E4�j�B�� O�\[w�W_e� �����tkɓ���B������+-����Y�&>���2�!"�2+�Qf��|�|h�K.�����N��?l��n#\��C.L�p~�`kp6D�}��l������ U;�	Ks7�i5I�T���9��;9i�vw�흿`�rf(MT:9���|���Ճ�$g��s���,炀I�>6���Y��0��5�&Ї ��k$RE����u�����)��:e�M9���HK2�f�H�>1�2�Z�Ă{��}�'�T��I�g�.C'A����5Z����J�E)���&G)�f:{�	�j�����^����P>�p�7˛:T��T.Z��m�J��)k ᒵ"^�V�1�<L2̐�D��:��}d��=N#�ўIy���4{�칐7,:w��0�	�	�_��47L�a� �9�^*�1��qn&���Fmsr����l�)ǘZ�^��Hd��S �=�嶂��%�el�J�2�r��0��d�����ѭ��ʶx J��dA��;*$�tQ��:�x-�!�He3%̺~3�L�I��h=#�����3�x��њ�j���J��H��^���F�h���������	z��ɦe�b)�weK-��ѫ1V�)V{<���i��A�8F��-�8�=�.��<�/��O��x;�M�oƌ�i`�I�'�f����do�'�'�lD���q�8��
��2L�F-�n���V�HB/�j�p��tg�]�/�cr2B'w2�X��5w��pj��z�A����<�'ĺ�O�~b� I��yOT*0q!���a�����@�^�)W�B�2���*k�pJ�1��~�t�@����+�����$��ūYr��16rC�&�30ۖR6���qW�ϗ?a��
[���T�aB���pV/D��c2e��⫺��QCv���hJ��uV�_Y���6��g�C�&$��H��K,���|�T�L$��U��T ��Ce6
fX����z6q2T.���a��.�e�+H1�"���J��1�{�y��0�|an�'6�\q��wD����_�0߽��e��l6���7o������}����y���%��V��-W޲ ��o8K1���g��$QAU�&h�8�D2����2�W�n�]Ti�1mS��4�K�=G�J�=��psu�2�΀8�Tk��$�
WY��BA�dn	
m�q�5�_Vi<r�+r'AŲ�M˱��F�$��껒B9����;�~��]�>D�����V���4��;,2s�dA�r�8P��S`:Z�ud��KÄ[�k=�S�D��@���2�<�a����~z�#^�>�r���״Pf��"9�ɲ8&)�I&�Mo�wO֋i�W*S�e;��?ؙ�Y�|-Y���M��TUUH����i�^��ܒ.�"͐�F��Q�Gݷ�{��e��n�����d�G�Sb$C���0�)����������J��y��p�WR��I�OC�$!%�'��(��'�/E8���X7w{)�g�K���j$qb4^H�a�����Es�2ɗ�#=�j�W��H<Ӵ"DL@�4�Ky�o%�Y���UaʭT������_3@"�)���~�޷H����D�L���t������U�w�OZ�Ý��o[�7��q�����^9�5��H�u��,�Ң������CU��K69GК⎥���'��qB�R������Fu��`4[����1�p-<����t�Q��Q }ߨM�џv����{/C��C0��BA�>����tҙ�<�]u�gV��dV�1������ϔ�K�-���,��S����^�׻��,�����#�B<efS���ӓL���5��N��a��\}b
y��s�}��jT+��NU[g�>�s�S���U�o�� '�rln:e�{��HRCF�ُ���t�10���8��]����0<�<��iu �v��v��o�Pû���C��x6��t@8Y�0=����#���xH�y	4=
��O&A$��R�Ɗp2t�ێA���[�	��p��9#���`�d�R%%H��Je2�/C�v�Py��X��^Hǣ�m�p��v� ��E0L=��x$��FBzR��8K��������� �>O
ͷ��s]�F+g���!�8MQf�O�|�P���B|�ԗ�!����܂���Kj{���a�,G��lԙ�'�����O�H+�AxG��η;lt��d�vY�DA!_�D��ܣ��X֥�E�[o�H�H^I�T�p�x��n��h(I2N����t8i���\�xq�����e��m}h�$`练-�g� 9nf��5C�І�B�fU�`\��H8��c�Wٛ1]�)���ް��*K3ϕ$s�!�����ɖn��Cz��s-M�nL�rn��) ]��Ivh��L�Z��A��C[]�� 2�~�0{z��2P��2�!xh$��#Z+wX G�=�����<Yu���^u�=��c߲lʍ9��q-�O�Ȗ��<��9�Wlԃ�?Ft�a8��	Y�O�X3�6��s��VA']���߶�t�iu	��U��ˏ�:&��E�l���~S�6���׬�L3Ş���xU�������@d���׭�N����9h�� ���� ꅣ�6�ѸK�>F���ԏn�XG�0��҉���m���v����u^�&\�?4������آ��U�8gon�ISk�)W�{�u<+sp����K��ح�6W�1�齙�=�щ#�9̷��d��H������gyIuA�������	���.�f��a���n�v:�Z�`�Q9@��ڈF�Kw������3�5�)P:�N�<ǀ����&"(U-P��������y�8�Ի����$��o_�T.p������@i!�Da8�#	��30���jS��U��(�D����X�2h�R5֙$r�k�s촁;��@v"ؓ�E��]2Uv⑘B5�(�&R�ԡ�gN��'_������	�H�A�]��C��ɸ6\F�x"�k~o ����EȾ�F�<^��f���[݇�`�iKò���ENO^��s������"Kz^:5����W���[���8.�@s�&�� g�y,,��I�5Y�[���<^�,��AJ����SQi_���P�h,��hQ&ea���Uz�FݤU�z�*���'qti?�g������ʊ��h�J�^�6������"�k�������V���ZX�U��F3Vmt�M鰅��;��a��C!�PiJcT�Mf��2x���1g����^�k�j�#����=�Iv��{���?77DI�jH�T���W��m}�N�Ot���1n"j�� �ԁ�ǃ�B�}�E؀���d�sU���x��W���M���)�X����f�݃�yc2G��$6o���!�OV�^jT�mJ���h�.`�t0���(4�|�{tǳ�t]��l�_��%ߐk^�g�����X�9����8�r�P�~�Eg�j���ێ��y�
bYj���~?+R����R<��O�ƛD�	{⤐��s���5���ԝ=�����UDg����	�6,J�u�K\�z���rv�`�Bi��>�d]١3ڠΠ%��j����b&S<$�ܙ�f�|R��(�+|��_� ,�MRP�k������Z�D��H����q�q�Q}�i��������� ���P6k@�����D�����
s�,���g ���1&eS1Ҁ�x���ߖ&i�î��S��� ��lX���$������g�y��/�K]�{+�pm�YTDzȺ������߼����`me�9��,n5W~<��!����M_��|٭��"��z�Eր�CU\&u����l�):Caca����E���ޢ��������~�_��	Î�f����c_M+^�G�~��"	h{W6�������7׸�؈F��m��/�F��I>���rdMG�:�ۗ(���a�Lj���?]���؀�N|�|w�R��������ҊE���}8���
��_2C0y�%hԴZ0Z��<�;4,{캃�h��n�z��u.�sc=/ƤOo��	�ʼ�pR�F�:���p��r[�2H,�~�Wm�Z{��x��me�d.��O�eCZ��@�����ɐ���׈> `U�[��k]e	�C��s�S�+�<5�nQ��&�k��6Rk+U���{�(� a	���$�b�`3<S~�%� o�z?��_�6i�u��yq�`�N�3��S�D�c(v�#���jmBSy� ���\��hpMV9R+
�$�rġ��,��\s�tC:��]�z`��ϙe�EI�z?��1]�{f6��){�~��ad<�>O��J�����K�^��i����b����k�7F��/�!̺8.-ڰ��;Vvr�A�1S�5�~7�(�6T�u�hf�`к�K��*�_�S��0IH���xqL�ϔyZ`5O�򐲞�8%6Ѧ>����d���/+�
J�����+�*�����,�ZdU��!ve��6����rL���Y�/�����Q�T$�UcZYN��ш��.qT�F�
{��������������GB 3��Ib��R�Y��P�&��q��t���\H�\�R�uI��$D@ �� ��%��xĎ�P��NeBi� a	u��
�U�BC�A��%��(���nǘ�R�J;�M�`-2��Y�Nq��������ڇ������G�(�B O����� ��I�N�g�2t�U�ĉ�C�t7�ݍ��Z��%s�4'ms�
��fm�ʴ再�R�S]�Q�\��3gT;/[�F�K{U�>��XXf�::�-��Ht~��C\��zG����d�O�Id���`qVg�gV��+��ez�L������Lh�UIfҝ���&��Pk:��R0�<��;#M�$���7WV^!{M;J��.�H]��]�)rz��owv_Mǧ���#���!����R*ɦ��GFa,�� .-óY
9<�T�ȣ�X�H���Vl�A�u�o�vi�F�L�	s4���/ ��A�zN��|����{�3L�3m��fp�/�Jf���ӂ����T��*�����Y���M7�����ج�y�wi�.�tKI��,�Cb�p"��(��I��ּLՒG�\\wp�����kN�����PE�$O��~N/��`S���^j�/{�q�n
`��������l���%+�\vS0>!u�|S��Πo���%:#̦r��{��N�;�O�����n�� �� p<��Z�9�ǿ��
�u�װ��˛z�]P�Ƽ!��y;��h8n�1��cD�!q��Ձ>��G�S";r�Z+��6��E�ކևf��O;�u$�<�iI���h�����='s'!+��_V2�A�Z	��l�T`�치�RFb�>�!��Q����X ��"���}�96�J7U�3/ظw��N��O��c)J�s�e�9��Ts��ce��^�������t͗;e\g�?'P�o��W%�,�5������Ǐ����V��O��=��=��M�������(~L�S��'O�%���w�\��}��z]cֵ����և{V��n*\[�l�e��Q�;�h�AA��P�N=���Y[Z|�ve�WaTa�?:8n����BC �w���������t����)*�"��+0>D0t�*paG�i����k���\�4�)�W��X����O��Ϣ����C?�����1�>��>Vc��*U���M�����9p���EC*���sTn��Z�y-�G�3g��ޅ�&���6���9���������;�=y�S֔җĀu�$։q�>p�ɗq�����ָ�T�R�^������&@�^	y�qo�#�"���a�I�$��N�ޠ���.:�����x]\�^=�{Z4�dw\E�5R�p ��W(k�{��JE<���o	RTo莰�T����W�{$v^�OZ<Y���r���y6�3Ie�7�Y���ϻo��;';h��i�{��x9 �2cD��Sh���D~���c�� }H�~�m�vJ[l�(�gӳ���C���n0�8�J�� ��
(���qX�9>��Ϧ%��(���?�nl���N.�Y6�����!�J�CԐKp�7�# ��ݦ9B�]-a��@Q�#j�ʇL#ԁ)��0�hg�˔��5q���9L�ՋIo�L�B^�T�a����"��F�"1����������%2eq�d���l����j96B*Ƈq�-gE��޻�"�Ѵd������2`N��YP�]����q2�j6�g���,[���v�,�`:�m�`�a�J��lmnn>����Q¶��-�6�uL��ן���n��R?"�$��ϲq�=�>�ʵ�̒n�Y���+x~�֓j�Z������1혃�x�땐�#h�d"�6XHu�X�ԭ�\m<�d�ܓ(<�^!X����>�,Z�Z�w{����������<��͙�[jSH?Y]Xվ��t��(�$����s�1���Uu��P�Sq�x�D��~ZȄ̚l$Țh�=�3�&�C�7\F�w�s�~NB�ƃ��$���9�����˪�w��;P�°�u�v[*��h���p�����DJ�1 =rYx�u���J4Z�^x�{S��)�b�3FY{2	z��8�<���|_Z��ݽ�ց�����هτ��EU�c~?��%�Voa[�:�>v�|�m�r��g��[#I$��:��Ƌ����:���
�5qܪg@��%��j0�Adk��Hx�{�	�hZA�l�+��
���ǟ|τ���Ys��=�Ȑ�	�ʃ�{���>�*�~��j]�HJ�)�,=Rqt>c�X0c�S:�2����.��G9�>��w��p�=�F7}��O융�Y���,J��#��KP��?N�ju�� ����~���st�*�� �Q�z0i��sC2�z5�^�a8	 π�j���ip�Բͅ�:�pL90���ťŜ� y�ÅT'K�f�U9�Scܐ��V@��w�a�uGIz&�D�L*	�P	��*�\�<[�8aje������m��>V	���Q��(����T�O��~��)e�E��J�n2탯���4`��ë��/�����z���&^�W׽��4L�l��mcܳ��W�w>�3�Y��'6�SM4U��+~�_%�8��y�/a�^Ld�t���`�p+#��+�h^a�c���rzI6p�k�ǚWM�?�Tp����E�A�:Tz�_��6^����ݻL`K���֟ŷ;�=�=:��]�k�>�X�6*r-�.�iOT���N���1�|�h��?��~x�����=lV�\<&���م��x�P�`�\��i��i2U߃�{#��]��j�s�r0�n��(��Rt�?G3�������b�O/p��I1��`T��(b��̹�sq	���&���T�=�O�FJ����FT&�sB�r���5�>��,Pw���k��xT�����
��Q��I���W�>�V2����L�[��dH컝=��{.d�"7!�� N;��<o����Bd\�{�����0B�w�G���j�8DAqX*%A��@�,��b���@|݂f�;w"��e߮�|V��\�E�kZpf�~�C[qgȒ����e����j��Ԝ����B�����`�������o"ח+�-S�14G���uq�a��t:.�wYe@�/�"�~��Y?4��V�Q����������g䮶[�-�����I6�q����c:�L�����z�H9��&���)�:�݂`�kR��_�0�a����]݈-�3���]t{�U�w)?n��E��]Z���ܚFښU��+�p(�m2��j�,}�5�3�\������BdkU�M��/�>�}$d�C
l@請��ߏ'�(� �|�@q:��z�J���U��(��j��}�3����KՒ�7���)�1WG{6�h��*_����3�{��;�g�TkUS�J�U�D>�#Z�SlVpD|�G_���/ni�ih8�q�<A�Z�|�l*��MJP&6F�G	|Q\������9��	���������2Z@�tp�頴\$�Y��-�x�<Ϭ�l[Dn�ϭ����G�#���ч��Z��bMT����k�jipVlT�O�uU�5ʎ��Fi_�S�C��]���W���[��~ȧ��RR�h�"�D$uV�Dhh�2d��T� R�����ػ�T�-��뵙�!��`��r'�y�38�ը����-[�/��]�|�����޺�����[��wk@��o��f-���r:'s�*�"����(���vO�I_ ��"?��kvWx����b����Y���2��xTIP�gd�<ꘊ��@}I|/��}|u_6/IX>++�J]Ks�I�⧞g��f�����hҴy%�ENUΆ($.r\F�.��j�Lj]�6�%��J�N!�GAH�0�']��&�Z-��[Y,H{LaR~?ѿ�j�>%�8�:�;�Y]��6�W n��~�:�}�:H{�}���/�Y�<<$� YT�Ua����_�1�.i�6��Lߌ��R�5�
RBMėIs��.-mDI�ȡ�����RZ)���*?�*^����F��^��Y�*g�&n���B
P���X�Q7S�|v�dM��.op]1ebmh	�"\�m./�z^T���1�O6���q���PE}�M&��O$�����I�(պ3o;*�\,���HT���%uƟ���%R�QZ,[�w��Mp�B8Z�Qp�0̦�*/L�찗P3��N"��B5n/m��u�{L/,�R`��ܱA��K8��r��LeU�R���4���.y���Z�����n�u�ȟ�`��2Ds!��̮���:��Z��vAPv�;����?@�E	��zY�kC!��1����!������U�V(ȑ��T�*���Q��*R��p޲�f��&␈�� �{���~@�'S8�c2x��'����!�tsЧ�ՙ�؅sM<H]��	��ƾ¢�r��
�Ɲ�1����ip	��
��/+����QN*�u�=�)���ˍ�t�\��/l�#�k]�"V/��CR����(�o}d��ny�s�HB`�����'���
��ϙ��� C��?�d"�.��'�� P�SD�l����h�R���h�P��֝鉭pPr�ۺ��Dex�o3Ԫ�i�a�B�uJ�>�~�WV�l����nKӢ���L:?.<��ߠZo/�)B�"�K��x��ߤZ r�Z��Re��_F����yL��]-ż��~���?�_O�J���p},�3��7e"��Z<�L�X��L�����7fQn��(?�:��؉�+�S�4�^0	��4F���Qd���b6 	�l���i0"gR�0F�\�y��}����r���R�S����,A�mi%3lo���� �I�}C�^b*��`��]@vۋ������ �K��[���޾Hb�W���OC�O���f�\=�")��t5�@���ʹp7un�rϮo;@���Ej��eA�b��ԧbH�E'aJg�vf��̩��M�������"�)�4���ߴ�� x�1�1�e��J���f��b��=C`�K+t�»\~Q�e���6o���z�V�����]r^"��U0��6M���kO�>(CN9�T���4֫>3
���^鯋��:�O
I��Xs�{#h4�(
*��+��bv[�r�r�$�y��������~�:���'��S�?�������K�?����?��������o�;|����جg�7[��_d��||䜠�^W,�����6$�3�㳪ؙ]��3_���|�U�!�/C߫v��;-�֥9�I��ve��w�:�ݚ��3P�0��g�XVtv���~±?;�s/��J�L��R�Lč8}�YQV}�ҭ:��1+�a��
OoXV�q!��I���c���n�Qc=�u|���A4bϟ���P��<¹@�!^���G���7�Ѱ���iSY9�Y�2�6t@�*�;������e�KH�^HM��X���J!Vtrh���H��g��+ݙy��
����HN��f2k�0m�������LM(��SN�Q_��i="S����j�l
�#���?/� T���B<4�Gu��,�Ju*o+*u�kR�εX*t�eT�$Y��	S4B�a򟜧�(�kA��R�Y�k� @��gp%D�_�̯s��T�ܹ����gJ��2u;���n_���㴙(�{����������I�RE0	�����ӓ���^�g�O�q��o��S�
���������C���?�'-L���������z����������d�f:���x��F�����F��"����l*F�qS҇�S��C2�z�)�?����y?���f/&/���4�._���<Q�� |6��W^���=�SA�^� Pő��S��f�t,��f�bN����������Ԁz����s�"���6a�M�ɻ5���e<�#W�6�ɬV8�Ή��͌�r>ݍc�X5�������U��7��{�QO bW�s��&��O�����d�5a5�o����-� B
$Ep�>>����Q��
�q�VI��x}�1TO���ԝ���#l=[�%�A5{�{Q�a�j u��a�p2%ϊ�l^/R:m���?Ȩ��pjF�0PJu�� �,B�8T_$�\�X9���cQ�����	�@�@J+!�}<�"P�f�1[B��L����A��RE4�ĉ��5&Y܀�2����-��������;`��F�+ X��x�g�n��'�Y�V����y�-7�&J*���>Μ�_QN w�WOkr�o�js�3	�aF�����8@�R�a���pܭ�It�L���nʢ蛓�6��9Ѯy��m~�b����xf��-l�װ���4)���"�q,�$rC}������5�2;�;p�lC�>�����x��{:ҧ�, ��T�0B��K��E��Ъ��O�'��a��5׿<����i��oln������ïF��d���dA���(������o�+�Hx��"S�Ç���!���n�Һ��$����3s�̪��'�ÇJ𼸢Q$���>�r7�O���H1\5��[�iN-r5�cD˃݌�ƩC?�SE��C�.��ne�ːu�3&?w)������5"p�)�]Lq�3'�%1�.3J�H��!;�f�a�܂2����{a�]�-�S�|Q�T�����\4�i��/ �Q��BY�X/�|K���J�� ̮)Ѽ�1cIX�F�g�4�Rv�n�~-��ջ������D��$�_<~��AuQfL�����$��1*�ECh=Y�d~����7����:�K�|�X���5�J�P�l��'����H����8�I��wxX��76�f�?7?�������hJ���N��9crT����|��/@&	m�J/�!�w�0��x1�P�Ci�,�-(
��z6�=_	)����8k�ihۄu��"�>�/�./�����Z��^K��������s��B�q����=h��/�6�Az�{Q^�z���"�EP�u�po	�_��ݴ�\�|�3�	hdX��"���r�WA��s�(F�����gb�DD:��F��D����(������ks�H-�h�C�˖��U��/����=%ѓl/��q�,:X���>��GqЃ� ��]'�5�*7OT:$h�#�ID�(����(z������u�'��$�9q��&�!4���p�*"��o6ڦn�
PBOzmL�<��#e������=Mu�ji�&��� �	�"��xP4�>�$�i!'$V-J�-�竸�����?�������s�����?�������9c h 