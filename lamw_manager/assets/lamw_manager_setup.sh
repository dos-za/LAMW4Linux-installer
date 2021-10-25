#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3066866895"
MD5="95cea18d013448e35e55252c85098770"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24088"
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
	echo Date of packaging: Mon Oct 25 20:40:35 -03 2021
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
�7zXZ  �ִF !   �X����]�] �}��1Dd]����P�t�D��R��w��4'OӍ�)&yV�n�N:��"t����80�T��s<�3vd��Ka��500m�'�$1D�LFc;Ì�r�"<`�Y7�A��>k+�t��-���a��|�dO�����6��ܭKK�z5H�|�윗ղkI� ��s�eD(�,j�H �=�x�R�JQ��>��.I��K>:rv���t��,cĀB�)]�����T�l���`��kԁVy��XꝔ��/������C�ʓ�l%O�ͧ��*.�{���XI����`ޥ��� �XK�	���בˇ��g	>&�6��u���`r>����tXA{��rO����I͜Q\�@f̸Bl h[%�}����¸���Q�s#j ��^��K�;�請g`X �bh !v13��q�2��j��]6�p��̗I�+��z%q��+�U�5إ8��Ri�M���ŕ_J��E��(ة�����bP
���]CDk
,�F���Pu�`-�M���3��#{�˴}����|s���k�����Ǻ*���.�c+�;U�����@1����n������
��y�%�!uk(���4K<���e@�V��S�U%�eZC 6C)e�j��o�F,��c	i�&;�ad|ǔs�ދh�ʹmI�e���R��ڡ���Iʃר�}���]z��,��Ǚ�4Z�E��̨���kx(O�=�up�=s{�̑�j�z>De��
9t��j��q[�����S�.dB��z�p�T뮾f3~��	`��Nxk.y
b�@8Q4�*�a��+�dfh�JO{c��K$ ���|r`��8�I�E���1��f�Pp�>��b�^���V��5�RI���SE�����^}nN��x��lGҖ���YBz�u�z�z#v@��į[�3�6.%���o?�S��E��2��������Vi�	�6=B5bX��Hb�x�Z����\�+5Ԅ;�[�%
�z#�`ы�س��;,���`��!`�V7t�*.a��n���������5[b������Ҽ�K� 浶7��z���!�@XE��� ݒJ'r�i.���S��<*�:=nR�8�����*B<1b˱��$�"��n�(��NJ���N��r�a���dw@+�w!�l��}�ڹ����,~�d��"�i9���;Y�w�R��[�Ҧ�b{���$)��̜3e�U^Ա�V���Ta�ƍJ��+�g�|b����T��/��[nh;wQ�m*l-4ZYpA�T��Iz˩�'�a�\�9�a�?��?ü����� �i�R�_�:v�7&��iÙF�
����-g���ԌR�Tr,��8N_�̍�;����K�Cb��Pn��I�9^VʏG�w��!n�:��f��g���+���J�L�Vx��A5C-��rZ,���&q�PM�V�(���
��r,f�P;��d|�&��g������7��z�o��H�.䙐6p��(
���Jx���!�8.ˬ�����C�?��Fj�rO�-eø_d(d����֋��R��K⥶}{d8������ę��S���?7��=�1u��iH�|T��]�6�>�X��u�4����x���t���@٠:�.���(i��:��;.z��g*n���J��Ы��S�3v����O��g�o}_�-r� ,�Е��!Z��F}��wU�T[�p�wEWRI�B0�8/�J:���A,2��a��d�q����{�;V.a��T/
d�����4zJ�a�G�y�sh�H�Ċ7���]�X����ީU��⥔��W2��8Rf-<@��fЏ_g���%�N &��.�:�|��dy�HqQf��{4�k��[��*�OƎY-x�VOP���i�E�3��A����u\���x1��f�f><�/��-�5m��e�nг�I�6�쇑��Tx��R�0~&u\>��8U������;���95����(@*tDlP�$��gؗ^i�og%�Ď*K1��kr N��r3����j\CE0ѷ����D��Ӿ�wQg-6Y�le�K&7}�n��#Q����q�<�@I4u��A�$��S�����'k�=^,E�en�=�L��g���'x�6�|�/A�#U��+_%�l�-�0������/����;��`'�Ψ�|T�l^�`���w��(��f��k�e�gAΰآ7��E
2'FZ�G�Oh�
8�$��A�)�ܼ���[��&c__"��a�`�*@b��I��@F�C[�p�r�@0e(��
x���u�J0�{�C�s�䛨�Ō�C�%/1����2HmE���|bG��9�p�L���|�P8����N�J��� �ʗ�<D����o`����Mn�����ro��iQ�����@��d�yWU�X�Fg}�[/Ҏ�f4@$��Dڴ�0��9��T�X����I'˳��r#Wƒ��$5f1�b��Wm&��J��F��R�GMl����2�pg���Q�ś�Vc�Z�J�?���{�4A�r����� ��\'���4ƱFƪ�U�鼎���	������Kou��;/H�W��8u.��cR��o��KJ<��]���D�C���0
��ѦM����7uH�i����CW�+�fD�3�P��8s�����;vɕ�"�8B�e{��� |�_?a}�X�Rf�0�è4j��)���o9���!�p������K�=5�Ha�'xJ�~�TO��@N)[d7&���r�P9>0�����R�P2��2vo�ZEi'ш6;��pJ�ђ+��&� �1nX�>3�D��
?N0;����g��a�wO�_��b�#�$�1�9�Y����I~`.:�2P���*�v�ߠv{�J�N�th]~��}�N�zS�3�Q��6�E��q��vwtu��;���a���]�j��:,L��7��u��:?6 ��{��w��Xw�c��'�V���C� }�n�1���U�&)F1����=g����^0&�v�7 �B[��=OvŜ��ԇ���s��O+�Upl!���s��O��ēHh��+���a[��y�?�>5���έ�I�IǛ��6����'����2�E����e{ihݙ��GOѣ�Ճ��G��J|G���sl�p'���wY �?1��9wEx��	������}:��L�7�� <��uI�|�jա��k���Wo}e�$�������lR�0�2��`2�I���+�Mm�W.J�ܕ�)����}͌W�~�2[��[���n�ovY�y�u��R%<5j���&r�KJBq�	Գ��7Cr������ʈ}�_�O)����ߝ�?�	�ӛ̱��Y�c��A^ h���Yb5��AНN��Gn��˧XO��4��s1cS�L����'����
4Q�	�hoO��ҏ��o����?�rS�#���P�9�&�@0�
���RzjJ+{9Ae�w0�7��+�v�M\�>��'�Q�)�|�����wނgO�p�Б=����-Yt"O�\��wu
a���|�M�%�y��;�) l��yj��5"i�s��~�¥^�j<e2���4Sn$�5�q-�������h���G�������tb}zj��g�
A� �ٳ�#�z>rAl}���z��z���4�꣭Zb�Sx�����>|�5���I*d��4l�2�m,�9+�@L^qw�A�tl��S0Z��襆S�G+�I+�~�ܺ��*�&��
��ul����B�m8�0��1`6��)aF"f`>��]��p+�W�����a�"x] IW�q���7�5ul�!*Ϧ��l�q��㛻Ř�d����@t�H�iҩ��!I��Ku�,���ƻ⦫3t����\�&T�&,��
�a}U�n����!��JL]V���~fS�X�\6�2[��
A3u���d*i~��h /�E�P�+XY�{�Zfl_���|ֿ���t��:?s��U��9��.� Md'��%mph	B��(��1]5��6�����6P˹-h����-�a�y�C�4C����}��`Fu�Jh�Z��Tv��W:�ޜBb������{�(�*��%r,`�V�	M����@2?�Yӈ�Ɵ1z��ȉ~Y�e�F��&����v�>1jŶ���Z�t�e2�ܨ���:"���e��������ʻU_�� I�;���#Q>v-����Ƥx�Ox�p&�,:������F^��e�����ԧF�֖E����$�k)����j�W�����X��b<*�2o�A��s5�\?g=Ljȥ��[�Q�]���X5�� �&Rm ���s�uF�9۝�YK;&�����B}|T�'4n�x�*@��]������������F'���<<��&�%�)��8H0u>B�[��0P(H�pQ����U;�hǞ�E����m����W�c��/�%���cr0FRI�\���]���-hN(�����6w)m(aH�A�A:�Cu�Ryy�;����>�D�U4_��;WyW)y��1��n[�Q��D��S�xU��g�;���R$����46����f ���B��~&�\��9����w_� z���b�P�9(��X���NL`��B�Ҥ�4��g8���5[?u�/��8~uc����� @c	��@�P�����ߊ�E
=���h&�˼�����'�H�9];25�8�;w<c�t�����օ�ڪ
�'��|�=B"g{�&,%Z&o�X�y��6-�Z�(Q3��FFnً����h�Y��ȍ�3S_�A4`�T:��a��+�J�9�7�Ql�OP"`�Q囘0��^tE:9T�g�pݒO��).��K���q��~����Y�� �dn�Y����2���	Z|$�̮�b�Z8Y�� aS�щ��zێ���b��i�1���#�jI���_�n��.�R���ˁ��G��7dSz*��9�U�`��^D.�X�㹽��5$t���Z���%�(�V�	-́�r$�{�`�����ߋ��%���8)�y_@8�H"9���\W��H�UK;n(���ܱ�b�g���Ԍ]�B��_]���#m�P��"K@Z�w �j���ٝ!�&;�"�p��o��c-�������P[��[���,���pjq�ʓN�X�fd�3:̽1]Ȝ�9*4ޗ��3P�X��{�Fr动"��] j�w�O�5<|�m�[���9V��Q��g�RGF��W�BRp�r
Z,���=�_j��7�O�T�wl!���a_Q0N4V&�b��������dBm��H��Q��e�#�
JAB���P� ���/�*�ҳ@F��ߝ��6`BE�2��Gth�~�d�3�Ir���HBҲ���$.���m�T���(F"�R���o�߅lD�*��Ѡ֏+�|x��3yi����0�ff��)��a5�1�~��\����댁0KQɤG�ǲ�a8�����,�9���R%����(�;���H�1{:$ic�ļ9E-����t`����Ihk�k9N�"���.�V��C�ča|��!K�3���,"�Ϸ� {|�c�kT��s���)��V���2 �6���^��_�v<P���d�1���6�+��{���2)�ytC�dd��>��s
vu!U���:���#Z1
[���T��
�V��p(ͳ�F�8x|���,�}��s<���k��h�Y[�e@�[Mx��Ђ^Q�fK�x�Y��n�2D�ᅠ��z����bA�}unG9��y�*��5֟5�1�#{R�6-��X@IT�i2�n�3{��c�8���N/Z��1�ߛ%�ꁍ�5{�[�M_��CWoxpGX��).\y�cB�DNo����!5�vT����� |-y���[�ip���[I���ܲe��� >kSIV31��K�dFT�9# `����g�/��[� ��X����b�MKA�Ir�A��.	u��76�h�n�b}�R�H��M��"X�1mO�q�t���ޝ��a�&q԰a��K^[̴x�{��_�����8�a�S�s0ԳEL)�&T�l�3����#��ę�y㝜޲���6crޟl�Ċ�C5��=?���T���l�~�1�|���%�ו��s�4�T�HՐ)�����Xh
��J G�	�|Ύā���q�?�oxW���\p[�%�Q-�Ao3�Ow��[��q���+�2���6�~��
�����+I��V�w�9�-��'��g�Q�*-V��;_q޽づ� �+Sk��/��I����.� Z3c�hf'�`œriNH~p �z��'�:��J�0���4�����V�[�P _�L��T
+7��95��qS�7$�q+6�tB�8���k�j����5D�Mj�5�ڭ�oB��M\m�*/�}�׏�c��ձ1cZv�	S��
�5 ��������P���A���K�����O���Eiھ�^��'�����AZ�n��deq�r�ʙ��2R{UR�����E��5}�d��������Vvg��4-1�m奮u��?���\��T��-o�c|>����[j@���Z|2�����D�}�%+j��Wm�U��9o�ar~��E�����w��e���Ia55�sP�A��ig6�4*�^�3�}m��<�'�L!�*�o**0���c��X'+ �
9h}U��R�}�hM�ؖ���gD�v�k�=�ģ�r�s�"ap\���[�����ċ�ǽ�V��%��u<ce��0� ;F
䉢0Đ��Xn����w�s�F��	��j�Ө� �M�\��y����w��_�&�>��F��f]���Kb��>��}�+Ρ]��.���
����,B��\��5P�����[����=�&k�ȺzU^��&�:�	4�Dv�l�r3��l�8�[y�X�l���5���56�R�^��@��K�iW�NK�sM�{�ۗ*%��=�>��΀ރYY�6))��|lC��ai���� �RW�{o�-:��(w�C��y��D��6h��LL�M�������mK��m�����uwٍE�o��a;�����m��-���sa+�J
\<FP�6�����"���j ��g��P���lMƖ�q�܅��q��ݴ��9d�0���An'�F�Ըe[
�Iv���#�Q%r��(y�X�H�؍�P9�w��i	��I�Sڋ����9���_�र$#��^]�2��Q|0���2���>��$�n��7��dPEF'��w��/�azfϸ�#|U�mAz�O�~N;� �5_[ �B7I!<���1P
|���x�DkZ)m+�4�)ɻ�=�Le�H�wq���k��eo⬜a�Mm�*Yq�G�W7�s2ހ�
���kK�]v# ���ձ�x%>�D��K5�ϼcڎ����cW	�x�ݲ��1�3;ԣ�~��r>z�EhvY����*1�0��C&��?<E����,��\�̊܀�'��k;C��Т�fʥY��I���Bapp�a��:�"�H��>asII�EL��~p$=$:�ޫUw��)�Tx��c���,qۉy��{U}k��}��^� (U�����������^*1����㨶@�AE(~��P��Y���4"��S�5�zaLu#��OY��%	/�z���T�Lʪ؋�ւ�?x�h�6O��n��U�!��ڐ�؎�F��uȨ���N%���[]�z�Yx�%L�UC2!2�?���wh��q\��d{@yk.}$p�lK�(f��!w�Z�O"�E���R@]���.�?��,�Fp�w�b �D��Xk7萶���������"UL�����7���UhLż�m��˂kLs����iI�'@p2'~�^�w}8��k�iV4��e����v|+ŢuWR�kI�o�w�:F<���v��1��
��8�bx�����.�t� �3콅�(V��e+�>5IG�։Z��C����wH�o���?�
?!:�j$v�*}��VuW�B��c���?���w5O2wq����w���6�����1׳�|��ˀ������&/OVɒ%v�rX�y�+�<1=_U?uJ[�I�ґora����u#�ճ�rz�,6K�z���"3F�������hذ�M�G+����Mkű��V���0D��
Z�@khm�*')��~�[�}�ٻ ���n`�S�X�PIҚ��ra�]��Q��n��(�)-o�ҧ��q+�f{%��"(��(��J�p���p~ ]�.ʗ�g�w�V��F}��A$��a��u6A~��Հ4�z9��w�~
[$
迚��7�L�;:	Ʒ����Gz�.��~�gU��f�s8����7J~�t��88¥A���/�s��t�i]�~Cט��dwǅ9n K.x�L/Οi�*B(n#W��Q<�{_��<!��o��@ sA��#b�&	�������4�pߌ���ړO��B��N�V�lhA���������sڋC�`9�}���lb֎��P�ǖ,��8&�M��2���,��ݗِ�c�tG���F��x��9�E���t��d�+��6���g�"�������>����g�Y!�Q	�l�d��k���F0s�p����㏔v��H][�2���+���� ���j�]m�ߥ�+���t�g�m��b���3.�N;ux��W�(�|�ٟ@�"���W���ierXÇ$]SUI� 5�n8=\4&|�5ZMD�R�g�f�#L2A��w�7U\��������e�=����_��v�����I�Y�&#y�d2�A� N.s��I��\?�l�VhĠ�v�_�>r�\� ��!9R]W�湧@�Q
	R5���,��@�x׬7܆�c9ʂf��T�(1���ʝ�����b�����?]d�asR��b6T�F���Y����9_��L�����N��+��	�fR(�I�vDN��"R(�����|��x���Y?���*7�i�l7=tx�JJ�&)|�|
��u���1cY6����d�'��(�[�=UTIm�+�� ����mǻj(�P����A��[c�_F���ǿ������>w	CϤ1Id���K�'p�)Ӿ�@2=��Z��
N��z�<��uq�+Ȏ8��GB�zH�m��mi�;R\h�]�|x��ڕ�k��q�yYq�12�Ep͓��c�R�#�er��6�T����|*8�m Z�D�l� ���+̊�Mr���u7����u��,�o9�v	cȇ�� k� ���"V[=�
�J{�_��.��Y���@w���f�?$�@�����ؕ��9^!�����8�Q�=��f�}κ�6x�>��O8A��M4���t����7P?#���L�X�~Y���Â��0��x����E� 떽�`�S#���U��QԸ]4]�7n�`��J"�ѣ�ȇ�g���S�����z9,ڈ������sW�5H���6�c� �"��/E�ʛ���-��P-���F�:�"����{�z���U VȠh�Y��3J)
�C�2*���ȫ���ߐ��4��{ڒ],db:,�R��`E�����rM��wk�|O6ڃ��ֽ�{�(ϊ&�qCH�rGn󇝴o�~���Î�L�.#\c���w���
 �ŧ���΁H��t�'��� �:8Q��w-{f��V�����W�x�PԮ#�5���H���bC�"4�V\92 HY�2ޢ�����b������~�yd#J�\���Q�r�"4��D�9�J�?�Q��C!�/�����;Y+��#C]��j6�C3�Q6eqa�eȅ�T��H��G0�F���EKf����C�K�M�����n\��B�����i�`;��Bݺ"Srd� �7��ė�VI�΁�^�*t�l���v׼P�t`���c㨫�����V[��ߧ� '\W}E 8�ϝ�m��Rj��1.c4o]۳�:��\V�?(��w�zJ୼�ʦ��+ �,NTO�b�+�P, Dō�	�.33�;,��`���û�I��	2�H�\�n@0_�����f)��ѻ�,!ZK?Ļ#r9O#��N���	���׸�M�����}���]��Z�͵˧ pCݵ�,rO3�h�*��m!�pQ�u	ʩ�{�]YK��&���Y!.��t��� �D�[u8� U�n��v��曁�{�es��u�?���V�["M�<�ʑ��U����G�t@��*��4S��YEW�uw�z?)�A���0�*�ª�-(���@7?YnG�<���4L�mh,�f7,�D��.�d���@+�y����;0��֡^>x�ĕ��gu�Eñ/"y�<�j$�hqGHe�fy�h����>�`�2w��P��E}Z(�B>{ɉ�~��0|��`&:��Q@مn%���<2)&�V��[ ���2&�	@�~ ���e��[��3�����`�Y�Odο��$��'�s4|]��p�������=�z.>;�]�{�fچB�K˨�� S�#�!��a�E��!�V1P��%[h�t����Pw�-��.��U�Mڝ�����X���(����4[֬6�y����CV�Tò���v�mO�	È��6p6���|��a����y�s�JP��$�A�@&�_�� �~Nޕ�p���hE��i��5��| LԶo�Х ��(���^Zt<���*�1򅔃z86 :^�
ڦY77�!~3s��	?�>	ƶ)"%V�u2 �����pf�ۓZ������c7�4�-���RWf��<�*]O�4�1��[s�Z�.+8��j��U��Y.�@r���,�*�j�����R��p���|W� �Un�������A�V]���Z�1�wXi�|,/�������D^X~ �bP���+3���.����t�hu)��&=�;��~k*���'�(���C��0h�0�q��Q5>V�i���A��2�����5^�^T��-M�d��j�K���O]"rl>����ID<F�
 ���Md����Yf|��j���Z������.
��V�EB�%E�Ʒ���{w�q23��~-q�ܷԅk�����m�e �TW�=Z
���&�z[�@�;5v$h�]���iiR�^��E��H�&�ȨC�Q�;��;'G-���Ϝkӥ������R��8z�3��s��M=�f�S,3 �U<��o8-�b��"���¢���:��ɆMi3��g����u�/���Rm�Txt��)�n���%K\FQ>����[�������S+�~n�2�)�����W�JM��٢����t<��J2�W�*mQWH���16b�y�epdILJ�GY1�c��_��f]�Z4��X��]�r�F�Lۉ�#���]Ppb;]����0.ww������U�-T��`73�l�d��uU�����'�[݌,��_ �Ad�1|gw^S�Ճ�}��ԙ�?ɢ����6L��J�i�]&���t�|���i�
?�;Anit3�3�q1��p�.��G���^��� �0��-^AЧ�Tmg�D�sڿ��J��X�NԾ�ho�.X��ONiΣ�$B}��r�%��[x�9��;A�qp�M%Ҁ�� ^��W%�@���X�R;q��fE�L��ϥ:�+���ݮs�h�,��y�lh*�6YG�O7���i��;��%YM�rMm�8�/�O:g���;�O��Np)� 精���*���1%��4�$��W~ �d�M����3E"����x	�l����1��O�G2�g1b�#����KAwm�k��$Su�z�;��\7(���s*�4�U���ѰA��0��4�¯���?H,Q��F%�?�ŏ��_��t�8�?S�HC�f���M�QE�f����Ħ���\���?\T(޻�X�孾���������^���q������q�I/��;�X��1N.���W�8��?;E<�8L�z%
q������� 1&L�v�E�׬�5�;�yY���.�Y���gH���b��/����'�*��ze��ȫ�8����M����ì�#"�����5��}���ќ�Ģ�ꨧ�	A�ڋ�$H�'<uh��C�#���CŞ>�
���s����"��u����}(�44�[D� ��P�l�)���+ɩ�C���M�Y(�U���u�Ju[�u�C������͝Y(su]��A�B�I.��]�1� �Mё��	ʚ+�ѝz h��1��4? �A{��b1�"7�t�3�)R�����~�hW1y/�f�� !OdR��|L>ˊX.@�)(�$z6�զ[���U��S���Y�g7ʴ:H���1��FTJ�O"�"�g�n���頮9=pߩ�B�=�U��MA5�\^;7(�6�LT����U�58�V��zȽ��Q�Ρ�#��h�l.���un��+h�}t6Os�*�S�X���u�6"y�}6�(�`U��	�aǅ0�Y�c�z�S���n�H�N0ό�?�^uC�dm�ԓV����&�`
�$��k<rqM*�����V��G���V�X������((m����<����yi��v��_Y���R�cW�s�b���)�FUd�Gqm�G���
�t��-�	_$
J�FYbŇS�Z�$�j����kw20Q�@A5i���k�@�i���y;���	���;'��k)���6R��?�9�M�p��&ъu�,w0&�hz��$��F����%�-� �{3eH�7�:[�@���]?^�/��BkMn��Ȃ��g+"Ob_2vb ok�3lf^�5 ���6H��9�<F{�Y�v��&�l른�J:hd�HI��|��,��$L'
��̂���T{\x�aQeZ�2����p�Qd�������jS3�S;j�Њޢ�h�<E��	��tC�����4����2��r"���d���4�k{*�s���7-�<G�o����L��	��np �w⎛��OB�ۃ��2k�%+Eaʽ(	���6�TdW/����9��e$+�3�$p#|w�Ov"' u��.�N�F�͎�	�h7�wGu-�HF��*�v�WS��LŬ`�wgi��B�ڬ�E��\�{���iU�~V��2A�d�&���4�(��>�@Xn|�:�U��j��7��,�Ti�":��g�DA�$�l��!dC\�x��K��Z�`_��CL�#�������k�FO���.��FAZkh4��M|_]�7f_*���U��q&�u%��Ά7�|�2��eK�׷�xOP���#����#��M��*�͐Y����ZP�ݔY$g0��0��nYI�'ܣ�0J��d!^��isd��{�S�� Ă�G	@�D�C���.]�8�ғ�P�Z�d���j����z��J]�Rǻ�:E��~���lf>1�ó�6c��bpK��3�!-���|$�Իۖ�����1�8��X���ζzh��� ���~:�^	7~Vg��sd5���*"�I��A��|�Ċ=�Oz�a\S]g�Bށ"��K>�*�
}���j�qSg
GY�zB@�F�2��`+t�q�@	@<��$�8��x�_�1��&!2���g����)��*�-��e��&�1S���x����g�Lə�]���<��� �BlZ̺Zh��>�+S�J`;��&s*#�xn�Gڱv8xaSW@6�nT)8�>W��h�0�J�6�wuI��7~i\!��n�i�	hu�VZ�0�?��H�}K�@�߆��H��b;������®_D[-�d� 0
˧D���;�����3$�e�H�����Py�Wr%�L��u��A�6	�{q_؛|��E�6�m��?KZ�sŅ�t�s��ey� ��A�"����S;je�g��Q�ȀC��!��@�N��4"���b�N�օ�&�K���!){�1��t�[����-���e�K�4�-�1�gtG]i�_!�2n��JU�[�U���zL�9@=b7��j�I�E�E��<`�-�p�H�Lc>!PƤ��#
{�o�"Om/�Of�1+��l~�7�̴��x���!/]�PD�?�
�<�6�)47�;� (���ó�YD�&Sdk���3���r�I�6���*j�ȩ�=�,�l�$����sCXI3;&���nf#6q��u��lJ��Y�a忾V1���������̆��@�XW9��9�X?'�-O�+L�*�������W��1���|��:-��|�p)),W/f�J8��}ݩ�x���e:�E��	�����b�j�z3.Ð��������7�����0�P�;j�E:�"�wl�0oA*aB�*<�@?��T�G�S}_7p�S�nI�Xu������!�[��I2dYTt:����}�$и�s<�2��cp�X�6�3W<��w�s���]�l�1����.]����MÙ��C��'�i���LT��Y7*	��.'����n���nW$\bB�!XA���D�]UX.j"��њ	��>�ʖ_�g�%��ѳ%ޓWڥrr,(���~V>��1����o���R��8�U�VOnգs���<��9��
:�d�>�#�?4���J��2\ht-�p�.�}�{*���K"p��hih�[��{�~��B�߰���V.|nƽ��.��$P���y�Y��v`o¥�)��BGI�B�VB�*wT'���k,7q��#�}f�P�	1�ܳ� ����X�U����l����5{$NkJ�.��,}K��fU�&,���&��n���p1�t�%VK�2�
�"�y�v��@}�Xx���u��� 4����,A�⃊?/7�nT�k�_������/�c`��/Qe�����6��ğ�����ֵ:/�V�L)�"���6L�eȢq��3@?��5o�}%��Q�͖d󬬆�����|���[�M[Ú��Ucm/�Fvr���m���pE�\81�1�"�ٌoJ@��x��?s�FBk�cd�����(���{˭f8�)��(�x�3�S���4�yX���3�t�-�F(���G-�4����fV���L���:�	�'c���6T�U�"u��q�d"_��N�1=1f�ObG��A��s�Q;��1��G��谁��1�B7���>Kpz��Yjun�5�)� 9���>�
�I3�w�l��IԵo-��5&^�e�&�L�
�c����7���Q�M&�(��=�T�θ�U�"��T&�zҨ����LLc`�r��ξ�K��ܚ�g��J�}�����S$z~6�}DtH� ������5���g;J�x;�}�_�c��� C*^/�#�?>�7�N��0�{�%ꟻaF�����=�S.����ˊE�_+��?���ޥԧ/^���H
�vE���ND���XW�X�T�^C��ڊ�@>��_G}�IS�Q�����7#�)����8ӡ�:E6jʋ���f�gS��LEq���qƴ�c�-$GQ�ݣ�\�
��D��RpDjCNC@E9gU��]6x1��h��Y��`__�c�;�u�b{0��gw������og`Lw�W�tO���:q�\.��S/���u��
|w��B��ar@"��S�4w٫#�\A�;���{�E���S��T���6�IIw��c���k����眏8F��o��c���LBA�%EhVR���=���t(�F�R�WsZir�Hh�2U*زGkj�B5�`	-;��m6�Uw\ZD���ᤶ�H0I�pj��p�Q!#�]��U��B�=�H�5���}C���������q�����Iw�q{��1��^�RSa9%�_j�`:j�0�� P"��N�@��U�7�}�����Ď�qa��-9*�s��%�Ũ�,R2@$��E����]�w@=eDy0�PWq9���1&laO�.��l=���7�����
y�s�}x���6���8{c�V3h��7~��,z��_�A��V)W|��zj�Ԧ�O�)F"���=�Cs����,�G��~�/�׎���9���)B(Y�XP��`�.��^�EK����^��m|�W��y2�u��I�ɎR5��U��B[�"�p���?Ov>�Q�Y��_����#���"��/��=�I�'��i��ª<hᘀ�Q�g��5�8�F�&�Hة	o5ޏ�y��%�ԝ�֏�Y��9i�p���sz舧�K�;^��U$�8%��9b���|��}-ɯ�O�y�]=F�B���c���T;9�eh%+h��S�RZ6����5Ų\�-�4��A�3���0	�^�x�� s��%"M#7����r����ά��*�����o$Ѩ0��@(��]�G|>���Ȧ4+U��/$c� �d��5ʟte���Ɵ=nq0�LA�9� �y#)]FiVi684B��D�%j�|$�a[�����|o�0i
-�%0�����w@�e}��~���<� ���
�hW�4F��;�@��MK�sy��Uր� ���C�b2����uO,S,�l����=�\mq�a�d��#~���̌V�X��85,\+qS��5�,�#�k�f�c"Z%�A�0�h��B"����A��G.'u��s���F����g͒.��	�*�FvST��Ws9AX�d.�N?.kǦ�27�9���o.��6E��omx(5��������^���(�u�8i%��*'���˩�����B�?Y�9�	�7�����e��zى�ʊ�QA}�=�uoII׎!����D��#e�.�.WM���E7�w�.bW7ar�������C�D�[��uG�G�@�o������X�	w[$mm�S°'$k�k����jAc�!�C>����w�pN��=Q���Sim`b���c���JĜ��8=�H�z��-�����Ҥᡁ`��Ïq��܌|^�Gg���o���ZLSaj��V`:o��E2���C��o������P��ب��Y��J���a6��s�P����:�{%��Q�@��ۋel֊���ސ��2��~�E�w7f.(��L�Y����-��K͘�*�ֵ������bm�����-fY��9���E��荈�q���?�^b	�(��lʵ�^v�	��̑��0d�8rÜ-)����y��)0�!eG���@�D�(�+���2ցe�T��_M���?�l�ʻs
J����tH<c��Q����3x��ȩ/�1���^���w�;Q����tȒ�`�#7���\��ѱg�&d�1^�AN�,��	�����G?�<#�C�1�yH.H}��k�֞;�I2?�H��>�)�s��gK��y"�L�$�!�`�<�@�Nv���x��ژg����~ R�G�:�T������^������6an�[u���{�K� �)̀Q,�����Pw�7Y#�T�R�Fxha��-��������1��ʴO�2}�@l�6#� �{�oaд)<	{��桰����l_�� /��"�A��5�~ݬ0��gLth�%F��v�
�+*�{7^!}�
$���Xo-Ls-���wD�عia�P��z?�T�W��RF�	My$)S1�tZu��Lx�� կb�.wz��+��
����)����f+.�5��I_+P�t���	ƚ�+�w$5���=��N�E���N�<�xE�����_w���l"����nL�>R>���6R�p�bNn5���\���6�'a���ur��4'�9Wͮ�P$cKݽ�&{
�m� �^�l��R�ɿ�&�+d�FSڣ��������{V�.��6[2	c-����u�
(�;"lZ	u�It}�o�6�	;BM��Ph���ه��8�Ӆ�By6=Ɖ�2L7��Rf!i�+��� �U���d��a���K�?��J\�?�8k�ٜm*��K�Ǟ����c�Q�`�V��]�Pz�骻�ۆ+�O�F��<�";`1yB9U{2+� �����5j�x�o�mr��qA]cP��V&hk[q�^�F�t��*B�3u�@��Ƌ� �{-j�����{w���>&%�� vo? q~���0�W����ut�슩�OX3��.���B���qё��ਬ�N�]?]�9}�G,V�v�ΞR�O��uxr�n &p��{Sfm*'ٷ����v[G?P��`����A(�x*7���ل��GR��ά�,����F���-�!%#�4�%uLَ�)J���rӛ�.���Y 1l��Nܼ�n��C��YR�N�<���������r�p $�ܟQ%��hn�ou�Ҹx؂tE�dX0��Fđ|�4Y��4�!\��<�3t�ݥشOi�;�3F�T�D�O�_��B�x�H_�;s�>����d����ʎ^apSX�V��0���>S.��n��	`mj�Z.������S:	�dq�Χ^K���t�|�q0��z��H�Z.t�d���n%]��w(mG�!ܯ��ݼ���]��(��x�|�}jbQ��#��`,���w���:k�-hǉf�&� �����q�F��v���1̤.��z�,�`��<�W�Sp)cH�J}�7Mf�٥T+z���!��8��ҴE<Jp��x�KϤ���Q6J� ��q�w�����x� #%��S��y��g폳����!�&񧳻���g���)���=R�@�I%�V���D�qq%R��řy�M/���ŋ��`S����!:��X��
�`\//�6m�[v�/rD��#�X�qZ�;����+�#<�&n�9�l�|��	 `ѳ��-�á�p[�����:	t,&.�{g�a�l��pG7ԼҊ�K��E(������7}?��Nx���3Ew���0�VH#R��V"��=�9w����-X�Υ��j%�\�,r���� �������p�6!by����h��D`}j��6�|${>���tCiX'�b�ѻM�3�}�Ub7�>�(�pV�T�A��W_8��%<���sMj\�!��/���P�t�L�O!�5��v�w(ޯץ�I��1%�ph�'W4��cn��֕�CSx�ׇ�$g
kt��&��6�gWB����Vj6`
��S�O��cG���oy��mx7^ 'P�,��2�|���ȺF.��rȁ�2^Ϩ��p&��?*E�n,0M���"�����C�7F�kғ��[8����kQ"'>���&9Kj+��S]����H�M��:(� o�G���r��\[r�����i4�>�f�M��r�e�C����A�AI�r5���:<�T�@<U=m�G�C�γ��0�"z�Fa-�-Џ ��X�'�`�76�JA��V��BNb��P�L��o�=���s�L̪l�t{� "�v�M�M���[�[>������oB�ʝ��+?�E�@`�_d<�hXB�O�3&P����?t��ݵ��P�/.��EÖ1���Q���)�*׍�5/�cQ�P2S��[ÔѤӟw�ą��,�T�r��7��0"+���5TY�K#(�; �j�l�st�7 ""�!�l3�o�]�QkM��+��,d�����g*��J.��5�dۯh�n��l9wkg�y�����f����.�)���xo�Z�
������K*��܍X'�c��6�AU�"���A�����W"��^�?]�VôS7�E���D"���f��x�.��y�j/2�V�2�w�{<����lr�^����4��hz	V�X0��3�Z��ן_[���^�q�AD5�qӧ�!�����9�0��膏�"��b��Js,[zj�
���E��̳#Nk7d6c��=)x���aDRLF�.ό�3���鹨���^f�3���(-�FF��ܠ?_?�W�o�nγ�:g@-u�sjE+:���A��g������j���l�C�����[��(`�sy��w���&�I2`�����������1e]�1�g�$���l�E�Y�8�,A��z��1I��,�TThn���e�M��+m1��a)�P$���M��A�v�rK�%�ӢY�� &t�k�r�g=���U������N R2(����vdg3,k��yo΁6v�D@Z�j ��۩�
�ȧ�B-y�)(�@�d���@�ߧ_�=���-��aE;J�~�0�����|��ހY�:�N������B�(<�n%J�N�#&�zS�߀� ۖ���[���Ӻo��6�:���F0&;P#0vK[A�gю�KHq�Lg�{@���UR��},W���q%��<����f�k�@ >����}��ct��Zq��{JZ�����r���1-)7~x c�
3n7�)˳�����L�f;���`S�����#��NB�5�>�vsB�d�0��Rg�m,���",2�^I��E�!�xQ���2R/�:�t~����G��TA����.��Oj�\��D�QM?:6�7��p:Q�` �����	��\H���+$���/����9�
�Uu	Ҋ(�E����3m���%��my�����G��W�0����`���ʸ��P�&$g��r}��� t��ϭ����>�u���C|�堃��9��y�8�u,eE����O����[�*����E���P��x���f�q��@9�
�+ZϏd("��@���-�����G_@�X�
y��O�W���gb6���Y��X����.��3��!���8T����$ڣy]q؍�n��\($���`�9H���3���X����{C�������V�!|�ȟ���y珸�@�� -{�]�œf"� 9�8��cԚ
e��)lP��9��-X�����+��L�mۣ̝$� �������Ce4߰�K�+�(	������̼�&o{f�"���P�~)� TH���X`�hł~&]���£ԉ�3yl18l�o�d��=� v�A�ݡGK�&��T|��5 i�!�ie
u~P�1��H�[��=��JXf �G����5�&�r�g������������Ps��rJ5qk��s,Im��@�Q�jm�p������٭ǖ�2�-��ޥ9��wȑ��F��'��j���зM�����TAJҊX4�âT�հ8�W�U�I<�i��8ٌ䝽�!��t~T�	������>�$B�J��<r� ۶�6��)xBJ�������5�4@|�c�7�J+�e�fT���R�2%�$�F8ʰ��I�|�J����@{���C�d��0�RfZ�$��+f�ހ�L�ȡ	�>kl��C�'!��bd���j��Idw/��s&	��l�x�� ��:�kѽ�[DL�^g-p�+�����Q8��s�>2��Mbӱ�}�+��]WO��/y5v��n�s�B[zbY�l��9�1L(n ���IS��0�.A�g��e�0Q��q����oni?�OI�Ģ�$!�ft��=i�l�����i��;#h��|0���-+@��f���1U,���,��P���Cڒ=k#ED�p�{X����:�z{�������"�C7�s��!�e��fށ�j��~�V��'l���*$��j��Wl�y���E�e�)L��y�NGe|��p���4\�1�ߡ�_��H$�JKØ���U2��I��2�wN�CS�v��{X�V�՛�P����&\��D�>���/PFLL���Ώ_�ٿ��9��xfvK��	҂���0�	B�̀���G]:Qk�y��h���m�4�}��)�I������(�ὧ;�1nm�&�����:A�Q);����/*A����7����oS(v��<�F�V*��*��'��Kk�P�BQ�~��~+�~��V\���no��
À�E���?������V�G�1;�rm"�>���Y�h�vx�b��U�jU��,�Q����5_������my��y�69�b��H�����Yz�~�%��Z�	^�>I®�C���b�K�Ӕ�} �s�����+��9qVrt�|DEX{���/�OX��݃=�����|M�~�m�����;X'����I�E	\#mN�����@�9k��8�`��OAC����f�����b؞��!g�9��)�j�Li0�Ǣ����9��e�t��y��+��a>8#?�"#�0z0�#�T�>��cv�ZrC��T0>���B-�O�H_=s��1���g6i6���N����j�&����:�\+�z���Зm����	��g���>�����'ز[���c$�(�̇��akI��6��8��U��@�J�����*���dEy��oQ�s'D9���m�fbX;2p�e���	�&fq�h�<s��J��0�؛U�!����D���`�k�n�kۇ%���
(m!ݝ��?<^�ga=���
��C#:��(����t��g�]�Aӯk\�rӛ��|*Cfɪ��j�H7�ր�$�[r	�5�<���݁E�t��o b-��#	TW�7��c�x������-Ә��5�])�mSv·�:c\xG]!��?Ⱥ��7��t���Pf��B7#j=d*Ek�*ȉ���TI@#�z�������jɽ䷼�AI�CX�eep.�|&�zB+��?_u7�����V�z�����m�"S9Sޏ��Kr4��:|YW��nҹ(�p�Wd6�Q?a�j�7g��g=��gnߨ�5����� _��m4�l�}V6k>�d*e�ۉc��6�s�"l�^�MSP��q�������G��M8&
$
�K�����=�5�HI���z�.��A��xHu^�u����RGJ��.���@�)v��몒����g�[Ӫ�~+��c�!�+#���,d���;W3��Y��~R%�5r��v�V�P����� �%�͜:�1��g���6��u6��~�C�oi�oW�؀d�/'p_L�����b�-���d.�dl�Y���'aB���SD�U�]}�Ea�Q������ѝ����H4Pt�� 'fn�{�GhYd��][[�m����,�J$��`���-9n�V�/��Zܳ,���=������ƅ���d��@!�/��lL���Ud+3G�*)��2�|,R ���v3eE���(��<�O���Ҟp�b]�c�Ҟ�o�]}2��<��*�k��M��=�m�Ĺ.���*:��EXN>e�5r���o팧�f�ʑQ��װFZ��n�rі�x�f����I\���Z腬��>j��b���2���YA�]	[��C_uC���ߦ��������-́A�C/����W���'���gy��.�*wǅ~���V�A��ӕ��C����$9:��C�'��n��3���1���0}�Aj2�Ĉ���8�^��N}9��7��T�lo�6U��Б׵�>-��� �G�_i��n8���v�[]�w���Lםv�G�Se��
��p{}�eBJ*������輆#��3@}��I�ۮ���QA���},�x��N��bO�n"�e#T��H�!�zz�s>K(	�il_�]6]D[@� Ex�������c����rw[�a�T����T��$�Bf �_�n.�\u#�p���!��츑Q��s��J��҃TwS��GME{~�py�Q��'�-������{�#=|�����K�Rۅ����l�,�������Z9�S�1l]���d��G�vԮ�F4�[��!�n#����)'!W�B�E�.Z. ��!�t]	U���$4�댬���os��K�S[<�pkBc-h��G�	�e�?�ѯ,B���2�o��Q+a%)e�s�lU���'�N�(�L���S���;˴swP:W���&�]Q*(�+�ҋ`�c�0���������$����ޝI6�h�MG    �EaUN��� ���g�S;��g�    YZ