#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3696761054"
MD5="3732a6e047fb9477d8ec46ff3a6480e2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22628"
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
	echo Date of packaging: Sun Jul 18 02:54:52 -03 2021
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
�7zXZ  �ִF !   �X���X"] �}��1Dd]����P�t�FЯS�ubäL��0[�$Ts���r�xw&<��b���G>���9����h7�%���p��%�ُ�Q�K,��:��v��C�;mʆ=�#�JV��C��,�F�7_���MF|�_�ь�M�=��R^�[dU�ڔ���Q�tu��C����:�w�{�w:���j�:"���	�P]���9\Snv#��9.�p�<�s?��/v�M�{G�$_4+I���Φ�R2�n����k���W#��&�#FF��eꆹ��e���#�ޡךF/K>��fl��4O���<��(�b���Z.Ǖ <�ӛ)��hW��N���$�@�v[Z��n������z " ����Î��~����
��$Q>Zp��\��pKʸ���iJ��h�~R���Wį�b�j� Y���h��i���Ta����5�J%؉¦����;�*>��Q���.g�*�mDcD?u��j]����R��)-Xy7�|�qY����ÌE��7��QnKY�O����Ig-�x$��R��̙�d�)�^�-ٲȧ}�q�	���pR8�|��z�M?CU����VT$�G�ԅ��,�萐�u������L��J�I���'�c�<^:��V2� �O���J�v��M��Zp��2��M�%E�!�Z_~� 
��;"��Ns����qR���m\�i�ߞIct�D�A�r�i��N�~=+$`�2�m�"���d%��s:�r
$v����@Uq�+l2o
��C'/����˱N���� �?ȅ�*��o��8�w�oS��#|\��$@�g��a��EmwI֓�"xd��ސ��Kw�7��
Ɩ�G�a�7g������[i�0�la��$͵2��]�b�d|ʅ�)���5�*©�`e<�Vb0C��*��(��6V.%�[�6x��s�K��W��ZkO�������q�y"R�uu��[�tx���
�lA�i��q�5�|�0Ҵ�g�{�����׾�`���PlX?MW"��_D�p��~3���ʕ���`�rCw%���'��Y�98��p�9u<g�����K}�
V��h��
�1�)R&î�,��g:'�t��c�H����FuF�tFM�&t+�"c7�+k2����'tB�����E���'M϶�{�ub�er�N��Y��ޞ\�P����I�E��"�4�������0gGW�P$4M��a��A��ҫ���Wm\bSi���_��G$\x���D��i;ËAϟ��$۽ޥڎT¸Gk\�KR=���Ӆ�����t�%�k"!$���ߜ�p��yJ�R4�,u�o�.�J�$JbEZUcM���+3�V��X�n��}����g���)NӞ.�WKDe%e������\k�Ӥ��`s��}������q(��S�n�dR)a�i+�}�t��gNaq)W�l|�~�,�V0l���O�C �*��|x�=0;RLS��^j���Y��Vr�mLb	�p�xM'�w�^1�I�z�g_���*�;��@�l�}�+��Ku�+���{D�7��1�;j�Y��\r��E�Y=��\�Aж۫�Ǖ�f�<n�����'� >ꈕ�q�A�$XH�1�^"�:Ā]/8B��;��ek�3�(+'0�vM&8�65a�w���	����iA���Gs�5>�JܚX:P�ɸ�Ƅ�359�?��H�F?w�͚&�|��C)��8	�!�!��%kf
���ǳ4+��R�ޙ�Y�q���2&��ς	�_N��W`Yp�[`��)��$�<�!��w��v�K�Ğ��9`�����~)��i�m�� 
�
Ƅ��V�O�+a�R�OT�+׃�sdg�F�ѼSɊ-^�I����.\���E|��O!�1��VA����ǠbC���*Um�R����\K�*7-׻��V�Y���O�~���N�Ԧn��A�i�c�����v_N$g��j���
Yv%�c��հ�3�����Օ�����z=��/�g����nU6EYA��-}��A�ˈD���8:��#vlI5I�mu�9A�:�`���
"{�h+���(��Ѧ�;�zfT��8�����0S�������B���r��w��)�+1� =�9��N.Û�5�R�΢��/�t�K�2���E��v�d�=�%�{�S7���m�7�cA/N�t����ތ��̻�SK���.{≆��8<�IjƝ��x�Ǿ=�r>������~�.[�ѷ&h��g%[��4�2#H��Z�JEH/a����2�J��4^\YP����1�{�U3�{$��%ꖱD�K����>_{غ����O�d��V�B�o�/;��A�@Erpˀ0�4[�+eN���G�"���؇�GP$_���:�X����4�0��]ңm
�8��"I�X|��ٗ�O�`k��G�ⷅ��#8����m����%}3��Ȱo��V<֎��o�^<�P
=U�k;:��H�x��/��H���� x1ѻ�
���D��+Y��Ң#Z����-�+:D�>����#��|������fn�ela�ܖ�� �ϊX�g��9�c.<�D7�#���A�':�e��E�Lo�u��x���>�T$��.�9���L;+�o��� �;~P�@�G��w��	�j��v�O�Kr�W��@�LwS�z�Q���Eɐ|��r��rD$�pkI���2��7�нr���I=�b&;�����-J^�����nȧ�Ap3�&�Zj�ؽ�3>(���O��0f� ��ft���3�b(��Pp���U '"��@�O*���9�*U�<U;b��+;��(�Oڊ ���H��jQ$q(jg��
�Uel����,_��`l��|�d�]�����5)���wo�6�j�Z֮.�D��{�I��UݒH�YR��Jl�j�f9�;9�no��B֙�D;�[�O��hq��g���:FtW�����H ��9W�[�k�.�u��̴w��m���e�b���]���b�E�aǮ0�r�����y�)_�נ��k/�:=�ȭ���a�ze�Ʊb�9��(�[g���ꍐ_[Te��ǈ.�ԣ�~�"���]���(�)nEs�hB}�-]1�V��s޽�6u��|��1�j�V}�=f��K|�Q[z�"a4���o#SГ B!��@):ѷ������~q���+K�q���KFp�-14��j_а	>2��������z8n�Y��rm>)t�|�!��]��{^�Mk�S�Q�?P]�	,
��{\����!O-k���R���ƅ���&�D��\��m�y!��\�Cc�
D]S���qc�΋3�`��iXq?��͈�H���ϱ�߻)���~rg�V��J�' 
���3	V�DV�hx�9y�s�!K��W�X
<�%�U?��`zX�p�pԶ���оm�@V��۞�f?�P�Cy6jf�R���	���������>�HR.j4��ܬ��3 B��r(��{�����۽ 1 �Cd9A"�r�5
�-��HyG�2�˿NK<|�'��m��tx&_��d�Կ|M�9��#.Gf@�1"ie'��)Q�m��vٔl4���* �?�3����a�A�rh�}ݍ�D�1Q�ȱ-�͎�zE����#%4�4dGřr���:��X�!�๨r�<�a*��/b%5h�s�(7a�y%ޭ_HŴ�_��~q�^�̞�hz��&���MÞ�I�V�!��h�o=�;�pX�o�u�p�F����#�>��6���XY9����|!�>����_f�f=Z,?��SÍ�p/G�OeT̰�������	���%T&�U!���م4y�ĕ25���� �I��9mO�0az�.y[J8"��z+m���+��*2
��-�e�������r6�y�@�0���`d֝&�n6�S�~�>Tܐ�VT8("@®j�VB��od�^�/-����kW��ElP���j�'G8��s&ZƓ��V����z��3��ˬ��s�o�/�J}V���B� 7���[��a���1�����T�Y�I���e������!d�g!C��9�1@u1�\���!�c4���`a*98&4]:��-�ˎ����Ϋh�Y�|�'�P5,�ø+s#���"	�Kwz��	��%�,�
�o�2��=,_L��C�CQP1����'\�g��¿��k��|ҙG������c�[t�'�-��Y���/g��%��~|��!d��\��_H���Ǽ�9��Y����$�a�P*βP�ۇ1�0p-��*�E",ʵ:U�r�"�.J�b��{��t/��R����+�V�Ы��d�m��'��P�Y�J����C��F|��OJi>�`T�Y�W<:j�yJq��=6�D�d5L�É�J��ƹB�h�C�h�����	���O#�!ݵ�#���^a>E���Ð�Ϝp=�|4��
ij���0I�\Џ�|4�z�(���8�(n-��Mh�$Q��X���P�J�����~�=���襮eU�Ø>���
L�DLع�=8n�S�Zߜ��!>�U&��7�^�1*!�_����T9�!�`[�Ԡ�]{S�,��yÕ!����W��SN���~�"�;�l���m+/���g�X5��Zp���џ�������p���[n���N��jTs@���XV����u~��=�E:/܍�dphCSZ�'�3m���'���E�By߀Q�K(���~Z�Sյz<`���? �L�:�쐧�0�(֡�7m�f�G��I�@^к|P���x�I�Z8S�u�&9��W�����_�����t��X2�1r+h�ڌb��k�2X^���3꣸���14+����#:�/3�E��M
}���02�@�}�����?�W����Ll�O�{�;�7�AvӖ�P6)݆�O�ͫ=��^YgP`.��ig��
�����pB�&A�!��/��xĭb`1/"�'J%���*o�qB�n߁�^`:���:�{�ۄ3Ӧ���?s��EC���OC�*�,�ۓ�tʒ
a�b��	SG���~,�P2�/��_��i��=�-@h1o�[��	�/H6�c�
>���4�#��tW��GF腗"�#� ����a������>��5������7��@�����膨z�E��K�?��cJ�}���3s���EUe�%	#���>����fRM�!d�[�?�l{��H���yrt;=�6nù�`�s��ly�O�ݴHR��[հ���������a~����\CB��c*} �X׆�2����P�������,E�χ^�J�����4{{��d���M�~I(��f�4�ҽ�̐��{kὅ�z3�.�&�l��{�e�N���R=�ɼ;�8S���{NujL}@!9��B] },ÜD���SckR0��V�B?��C��w�В��Af��סɿ9F�*����ۈ�4Yɩ�ѧ��4����(G���H�pk<q�K�,H�1e;�l���C_������<�f��d�b3��9�͚%O̰��+��F#�#��O��tΛ��jY4�xy��lVsQ{| ����f�f׀!���fb���ˉQ=$�Ђ�0�M4�vy^���x�� *3O�eK�D���P�ST�+�?�g�K
��:�(k����l�ۓԒo��}4��  xu-0ӥ�eZ���[Q�վ����p>v��#���7>�8�xU������%*k�b�Gn�����E�ڵFQ��L�n�nza���B�Kz���=�KX�
z�L����j��g9��lR� A��%oA�[�@�ΘACۡ� %}&t�EbI��
\�I��O~	#� ��Ɯ�h�OB��
��mtӶ� ���#�i���e����dz5��BR�u'L�/�IZuX��ʵF4��s���U���4]�u�"4PǤ�9�^��J߇�SA;#v�F�4���/���^�f#6���"�mc���k���[���k�{��j8��!�*�k���±�C�'R���D�zQ����w0�4�I�9�yU���S�n B׋楃��V3aG�x[��)&�ҧ�p5L�x�/�vƸ'y�7���:���ڷ�a���]H�/2�����&�'5�/ä��˦���kY��*ѧf�s��T��ҙ�E�q}���GD�7���>�~��q&f�&^���<]J��6���E�_��Cwa�$��x�rp��y�W"�%S͵��
��!��gX�݁CV�Yƞ>j*ۼ�Y3R�r��-�M)��J���=^�����.���6�qVщ3���{��aC��=I�a$�����t���+�W����2/�f\�d�u���[�T��j��(,�*,⮩�a(����`��] �5��v��Hl;4�K��o��!9�Ec��(��G�
���#/x�U.�d�4�c������~���W�.~��PF����;;�&r֗v��z@�Ё)�����D֢���/p��z�4gSR�R�,gb�6j&����j���� ��m=�c��,�r��V=�R��O�g���3*D�7��A%�� w1U�73�S\���G�9�T�.}�*f��:m��Z�YV���DW�h=V聕�-ԒU�ͪ��Ns�8�c�7����a�v)�gN^(�Mg-����N.Z�:ㆬ�I�_���t	�L�n}4|�ZrMm��i��U���"��?Y��ة�j�2o?�z���$�(�-1�eX�Zn���c�����GdTfA��)U?I�AR�N�3�bD
Sx.�:"�*�����M�쾍l�| m��AKbK=D��̰�A�M#|�d���(Z^⿘�P+���8�5�B�4b�\��12Z���fEw �{�zӾ�:� ,�v��N^���ݍ�=$c�.���.ɾD�Y{:��)�� ��Q�MQ���gP�nY�/KJT1�?�Ej�p(s2�B	�1'c���wwB��NwJI�Q��Q���@�
CP��)��K�d\Z+�Q�粭�����9~��*�S��eV$�P����eA!��\�A:�� ���QMӏ>9FD��*�ؓ�˭jE�鷭㷚Bu5�\{0����z]|��)��5��Y$���7��2n����V$½�D��ޫ�clB��n[s h��EͶj� r�.�Y;�:)�~�ޙ���oww�߈T(��WOԁ>�d�'�萇�� %u��N��*���L�X�#7���������f �32'�S�2��%��0��HY�!�}h���y�R�^&�_����v����b0�����%FdNrPG2�v��@�K&�����p�$D�����m��l�!�E�$݈����$՘tyB���  >���]nn����R���^g���z��w�w�?��W�5�*�����n`h.�?�*����sv�Q��Ač1��jd��/8�
���\x�	�&,0-���~�� ]<-���n|I� �N�R�������v��>E���M��ܞA�r��Y�,��M��z��tr�I�'�T��ޕ)��hO�dmn5�9��"*1y� ��M�F����謐���d2:]Z����Y�$pv���y{Z�z�B�y%��+3�R|�����c3lPr����qN�5sv�����\�Y�a�	!0��\z\�"j�a������ݎ�F���b�F���z�k��uf^��!���35^� M��� >!��<�@�I��?<S�����e�E�j��q�N�����b&���@4A����	�>Wg*��(k���zlA�/�-���]ps��	�ͯҾ%;�\=!�:��$S�4!�&	�',l�w4ۮN�\)�<�+#��ue�̲�w��'� �Ll�|��V�4Ϊ�4q��'��� 0�K�0D�_���I�	8mLfp�ON�hfF"Y^�;X�̩p,��O4���:`]�`�|5�Zc�ZӆK��<�޽jBg%��B*ةe~�ÎT�<H*����Q���]�o�M]��_Zc��cx�d��c& O�gZZ��¯�g97
I�^�{��hÿ�\y%u-�^K#�B�*_Q�kzp��3u8/�?u݌�]� ����m,_ -,�V������������k�h�����T�_��h���4\�ٸ^�����Հ�����v7�`�ZC�����_c�.�t�E����G�Z�̓O��"��Z�b'؂,��?J���1�C�Ǜ\� L�v�
?�79�V�^�{%k�Ǌ�{����f]g��:�M���zֿ�2#�������ڴ9 �nmh����|�G�Q$E�Y8j`���C�D���ZؙU�����"ј��/��ʉ)(�TwdoC���a7�����ұ�fzE|����u��VY�Jb�����b�/4K�q�M=NR�Kq�o}�q6G���b�M���|�	��8�L(����]�r�����:�f�d�eE����U���,������)���(Pt%�:����Tۤ���A�6�o�C&?U.�75�N6^��[�5�G��K9��T��8ER/';��Ķ��L�M&T�Қ��V��`2��j��8�heX�������1�Q�)N��*8�u��걅�o�-r�9 Tl��`X3Ŭ�9yGnk&��͔��Y�{%`M��l��3l�<���%��Fo�G��B����-�tq���[�J�5�%�B�H�b�f�;�>�����Qa�+�$�y顳� VϘ����y�A�r6��!��"
��4��5�S*{���:�,¼Pg��ױ
C��Y�U��{��'��7+��ĊM��,U�Z~����hrnXq]�h���ni���sv���xc�=>�q�4�������pJ��<\v�%���U-Xc*�G*;��f�ZcI/�{�|����L��A�ih[1�df�F��{��J]�{��ׯ�p{�y+�`�C�%6�T_r��O<���;�y���X�}��R�D�~�$��%%g>��|��<E�����ex�!�+w$�k�dL�0��q=���`���8b˅�����j��A�Q#Єi��ȬdA��KG`/�w
{�!�ܼ��;E�?�1*��|��NR�w4�V��{�#.��C���QϕT���J�"������;�>��xO�eO�5>�<���w9��pw�aJ�u,�o�Cs5�=�+��s�1�����1�2>f㭴�!��͘!_�N��g���������#s�p�Lt��ɚ�H��!�jf�5A$�@r��8;��P%�9o������A��t���ET�K�讌��ζ��r�2�ʌe9���E�u'���xR&H��R�C�C�>w��I=i� *�}Z��<�vp:���o���Ϲ�ty-d��a�W�>St�G��ݐ���)�n��[�~@���7LĻ,�(lW=c��U��Z;#�8G��' ��N��[z�V���Jk� nU�t&|�V�Q"a��Kp�^9M��I�J򻡁ͻ����I,ǫ{�cl}Z4����m��<+�׷k/��.�����MF���a4�_�m�������t=	+��å� B�I�/:�B"y0���Hgb&�;1��e��f;�_��%n�L�e����p/>�!_������5#1�Д��?<f�jP!�sƴ�Un�G>
e7"�[�y���Ƃ_��}��L�"�ֆLw2���s�8d�DxK���ҩcn��9}{�V_0 � _�1�/�C������X�o�CiD�����Ҍ��:"�1���EV1}�ݶ?�^���񢣯�H%|H�m\�%;�:o^-e󻙃��q?�
Î�Ϣ<�[M���a���r������c��]���
ݼ��4�ӧ9�Q�8z�#�&�J@�����%�DGG�0���e0�ٱ*G�Ӵڑӯ������ekfI��H�
'E����<>���K&Qoe�Ϲ��̠����f@8�`Fh��I{W�ς��Nf�;�#�ɛ�C K�e_�%X���6�2�V�lf���y���]K�`�E������EX ��m=���%�x����'%	����[��d�D�g�%�����'��={�}��^��0s+K��!#� ռS犆S�m���uO��]�t�����
c��}M�Vm|@��L@]� c����xZJ�_��:�B9^s^ۈ��`*���^|������\ms���!àD�FH��/:ai��|m�u����J3͊�rh�{	(�P!�u8l��+gK�����V v`!�,�1�q���w� ��[��Cbς\B�QK�5;�2��_zuh� �t:h�Ψ#!a�T�-�N/���l­��$o�R��DU5�����#�@�^ֵC�d�B	�t���V�P�û�Jg�j� L2Y>	d�Ä����0�G-%���g����/r$����0�y6aa�6(�V>�)YA_]yU;��*t�@)���[Ο��^�N��{�m���SDَ?����@f9!��g!p>����S�L��|y*JVn��A[kGܯ�T�d�aU���rj�%��+w��'`���B����.��ؕ�D���ɷ����Q���^[��"�i�?�SX���_��oO��Z;̇�Ϯ�$������~��T�9��W��^�����QDs�U:��7?��T��$v�z0e�u��hl9���	��Om����'���ڈ�tqvB��Kȑ? v�#���!Ğ���-MG��﯃5MY�*��.e�Ս��u���}��9�'Ci�v�7&�,u�:�5%#�H��BNk�cƔLciN�#���S�%�:z�k�{3tby�\X"�e����\�(fl����6Wԫ�gq�!K0�Vy�� �q��<���v8$&Tצ���_�4(��*��C+������:7�^�� �9 ��o/>S�8* �"�w;}������~A} �,_�[�<���3BdV����X�h+y�o.���=!�;�e������+�������Nmx)i�nBu&��᝜���l�^�D+0�:%>I�6�����
��FV0����9p�}�7/��o$A^AQ����Fj�肩��޽���������<�������8b�"B��'�K=Y.����s&�D1��G;���5H����@�~�� ��?3;kf]r8��R��͌\�&%�H#�*[�hih_�Y��W l ��>�9��E�? �����#Q����Fp�X��O��Q�I����\��#���/���f��ǖ��C��<y�kz��$֣��K�M(���d�䇳�Y�_%؏�ޮSoB�zq�މ����*��bk_�c�ف��Čpt�߃�sG���Y�ռ��ff�Q��{&^�<P�P2�M�K��k1!��4�N@7�߭,'�*��m�oL�:�zY/��G�,%6 6�� e�L�B8�R��QA;q� }�?�&<ʲk�����$0&_yA����-��.3��T����\�����P���*Yl^��z��Lqm9�J�������)�w��l�e�"�0j \z����S�&Ǹ��	�Z��g,����w�����K-�)���W����Q����B\m�u���CL�����뿨�����:{Wk�eM<^����eg���.��*�ل�I��4aި��Q��~}M������(�������EZsԌ���TDì�v���ٞ�k�j���QM�m��'A Ή��Ç�w��=�N;�#'QίEEu������{�Un$��I�3֬A�K���x�ϩl�9� |@:�M����F�X���i8����kSM�^�bff�F
��E�!�@���J/9���5�b��t��'����m�c3 ����n�
� aI���$>�^,C�$��TM��  �N�xn�L����[uԺ��j��/�V��z����0`��V9�mԛ�>ϫ��G�@g~�+n�묷���0 ��2�ux�s�7q�[��>Ӭ
8�
5�н���HY{�N�7�qert6Baޏ�H+�mCLw�q|B�ա�~\���9Xi��N���-���0��p|�	���ɢ)�I��Ә�X/��� 5#}�Xj`g� <���(�n���SQ��N�i�i��\��8��=�������y�	J�-7w�,rhB���e���\h�O���S'��}e�� #-��ߵ:���l���)��+�LśIs�ޣ|�2iR`�C>f�.����x�>��U��*Ҕ��N�D~fp)��Ms�e��p���cPN����~��9�ضI2�!mC0�"s:Y�8Pg�B�~18}�R���_�*<���h���gk?׈[���,:s!Uў@�T�Q�(":'0bvފ>�.���c	����}<�/����"���P��|+�^t�2N������UB���6VԂ6U� �J��|�	�tL�p~����zX���Õ��2��P��=�|�"2��,����δ�����Z�����t�&��[8c|���ޑ1���?�8^��m�8[�jF��Bl��I�y���j���<��`��N���F�Ns�e
�D\T���h�>����r��5��!����)EkN��!P��j;A�x�+���^A�]H�X�ɹgW�H.%^�|_B�"��ޭ�;ņ�>����\fۛ�{�>�-�̶B�R�c�*Im��M�L�d�����h��gJ�����LnS��8��m#��  �Z��5MϿ��u���ۺ�NEs�����j�7�j/�QW����8$���4,q�Kvč�gFլ2�G͛��U�+�4�,�N�dxhT�����^�V�S�bu�����Q�ɴ�$ϝ�,��))J�*>m���.���T�&Z^�&�Q��5j#<-fz��` ^�J�%���5�a�[ĵ�����Dk]s�_�<����-v��sNY<�ETL��UO�v؀{9�ccP��I&�����?[-���
�OG��]x�?8���|�[4_�򰬰Iʐ�j�R��mwyGC&�M�n�C�	r�Ue3`�S1X�jD�q�d�I�3ү���}$0�G���|FY>����l|NU?v�T퐡$'Ɂ0�W��'/p���i�6��HmE�N��
�k��N�Aw�D�����]�5��9m_�(g�)��V��I7A�ԫ��5�VcG�ȠM@�_��j�6�����Nѓ����\XQ]&Q7�z����pML�`x�]���fF����m)͞sᠮ.P����X��+���WX���\��mUkF{C?��Jt�������_f�)�[�ʝ��F3跃����4�^}��J+g�
Ҍ4��!��崀Ԅ�e���s��U��%e�͢�[�|j�ʔXw ��D�"˺3��X����LH4������	0���%L8���ό1��X����7�D��Q��z�77��<�8�7t"]̖,0@WЈye��qR�/�6Tz,�9.!^�_�$��ZD�V�㞣͝�'�S��b��y/�/��v�v�rb�]*0M8N�-�VAXn��q�[Z�胥�>�<V�bW����q6�������S�\5.�:�a��md׾y����͏ٍ��C�Lfux��3�w���7�"��Z+���C� ���%'��$���Ba��o��R��B�����>����=�P�*�1�
X�K`S���&3�Hm)�2�os0h���v��l�)Q�(�Vՙ��%X��I�ԙh9��bvOO!�������N���V#���h�n�1ܗ��|d�~��o�9�B�2�`h�{V�	���qP�`"q��ӡ9;��p����_u[A�FzD�U�2 x���Z>}���������t������	 ���p�c)=Z#��A(F�v�7kP� �j.�u1>mI?ު$=Zˊ���:`��C��7q�n�)��R�.|�=��������6���cs����Wx&�MC����y���,��z�L��^���T��Hb�vҦ�:tf�T�dp��6(r��+p� �����W��a�j����W��� P��D��^�=�@(*V�<3�W
���w��MN�v�j$��&�EvyJ;鸾C��B���Hz������B����������^@X����T����N2�N�����գ��A H�����z�d��gn[`
��5Y�Fv�����J�P�<��.�F���.��� ��2wh�:�����V��YLdy�����@ٱRa������:1=%��3Ci��Ik����9$�O/Kq��Dϣj�=�i�g���x��h���Y��+c[�D����뽱���#yׂ��ˣ�!�H��b�=���`͕̳i����,}���J7c$�7��քMV��
Av�{$�bJj8�Л}�!����$�sC��a�~�+�l���k��%M3>����s�	y��B]��!3N��3�"/��2�Z����nӥ�%�vėx���2XL��Q��A���	Q|�w�����a!?c���9;��}�%����ye��㘰��"e�J�4p'�Iy�-��4z��*�D%u�sNcSG���<�&$Z�$aT���;G�F��e�)�^3���IZ�����{hd�;7ӊg�Oꂂg,R�pˬ��N5�$�7̓'�}O�8����X7�����W�ᤂ�,�#�ӽE]w��O�^�}��K�0?H�9C��m��S>j<0�Q����X��g��{Z�Ӽ�1��� ��� T۳��A���𠕠@i�q��d䞩Ni��f�-�pA/4�^����6ߙ��Ldhz��0���T=�p�V��מ-!�J����Q,g�8��،�s��Q&4��D�S�?�u���5j,{�����cĸB�&`˅�����3`e�`w:3dp�	�TP�֥s�h�`-xP3��	SW��'��k��3��Ǣ������2E�cub�R�q��'��*��-7�Al��A%"d��24���<�h�Ȏ��ۺ���T8���=����ݴ��{�ʩ�@�=�zj<i�Ӥ�����J����p��%�����nxo��ș��翩ׄ�=N��q�Z�+��ZGϲe�o�Î��Bl�h��z�Gn���n����"P�����Nz�]%]t Q�>`�\cJ$gc��ª4�����7d&��b2��_��Ю��*/�E-��w}���ߎ��`w����ǟL��([�|y�!b�#�z��1�:JW��>Ӡ����TS�r�����a�
�
�Z��ƴߘϘԑYN)R��_�ߔ��>�.-=�E��Vݩ`	݀���Ƅ<̚���	[ڜ�T��R;����Ce��2�nlnzm�X��h�ԓ���6g�����pj�ٞw�)Mm��c�,s�����(S���6so�I{����xR�Q�df�Y�n[�����p~�$�p�RC���8JGK���9��<�"@�)&Kb�D�މ-`>�+n�/H��$�Ӑ�V�3�ǳ貺�)�GCOV�5�j���s�.���!�F�㶕Ul�j�,�!�� ��H�yt,��Ն�z��0��iy@3�fS�u��h�X�,��7G�����s'���-p{����ʜ
���q�b�o'�I�hA�J��kZ
aC�F�Y�O���x��c_2�p!��b���฀̰
tՅ�8z:�8档>H�׿(s�� oߏiD1��V�Hr~��M�Q�4-#����
��n�i����,Kɠ�CՅ^�f�9�4b�$�I�߉ir�W��������س�D��9)D�ehX�>�O���l����FC5'��.	`2�P��-6ThBx�[�fH%�D䵐l���O�Y�U^��r�)Qyf�E��P�{ۘl���0eZ�ˁ/0ͽ+�� V�����n���_n�䚻�U��Ż���b�H[��;�7�J��\�[�{m#��Z!O��nߍ�^� G�l�w����s"��ip���Ec��Y����)H֪�:��z��f�E*�=i}�OU���V��L~B�XOXf'���F�q�8P�JH��;�%3���w�=��,��������2�yz#{���L���S~͝жE���w������"�r*�0�j!	���YN�v�S��}S�ο+=S������бn��_�}��p	ݺ&�o��C�X���.�ߊY�E��x��`0��%��ӧh��srF�k�nd�K�1���g���g�ȁr��C�h��hE����}���D/�6bd>aJ�쌴j����9��p��΄�#݅�`Z����콨u�G8}AI�s��o���EHyB��_��M�W~ �o]s��w���Xe�ǎ� T�0��#<���^�v�t$��y���z�t���b�{��-���@F5�H�:�>�"{� PiH���D�z�j��X(b\�e�����^�n��cV��F<މz*�[��,	v�A�&�q|�]`�������X/��_�ۨ�13b�HiX��W^I�X7�2�eC$-����$l�6J!��/�G����m���jU���Z4�%A;?({kT@o�����93]�M
�0�|_�����>���K��lK��@�ߏR�8�K�7��UȎ�Tw�2�ָ[ؓg�G�`�L�K�|����UO-�f�s�x�iՆ��H����4��{��C{�De�p�g��Ⱦ����z
��T � �Z���W7| T&���`�
M/��qDERP�⋓� �(/{E�a�%*4F5��ș�^��+}��^�}]�)�V��ɿ�#���u�_��ţ�_�^%L�<�->����3t���j;u�����j���XJrj4��P�;8M���F��\��[�˨��	���{L�k%ِ���\�7���e"/R��7A�[F��E|Dƿ�+�p�1T�n-u�v��GgVo����l�s���Yw>-�(����S_H���yԦ��oT~s��lH���O�?�U-�P�ȠD���A���_�\&w���j\wIx�`e�[a��H���4��7n��H�h�3���X�M����*	��q���������o��<������B���}>:>�k� �FQi��A�����^��i�Q5�rs���mW�wZ�ڠ�T~��ɒL9�e�M������oayrҁzCI\)>���B����!���;�E��?���2��}�\)�7t�������*�tn�t�8/�/����	����������3nj]�������~0'�)�佧M�ؚ������d���;��o�r�;�`����]�_��"t3
꿦=�^X��>�2���������1Y�Ц_ BbM���^�e]C�X.���=D�h��l?��¾e(�]�#�x��PYr;�����t|<�2N2js,`�@cFl��b�׽�Y����z*�KC��>�.Kƣ/�
��Χ��4<A�!����N �t�cf�r���0����9��°�6E/�LP�9>}k��k_�9�<���� D�o�o�^�7]��<��:�h��E�VgbC���0�a(�E_��"����Q�bu��ا"�ޖ�� ������	q��D٥�>����2VpbԎ�u6H�e���WR"���� �-���(g��������Rw��XqH����g���d!_dss��H�����hu����2 ��K-�'�8G>e�R��u�G��ބ�'���:�`ΦO$��'ͺR^�b@V�'��&qhgM�MW����b(w�|�|�v�����6!f���ۻc\6l���̿ɸ�N����'](��߬r$�S�SO�g�I>qEC�"��H���e@١�	۽�C+�k�j�C�燂�L��ޒ�w衾hrO<��a��y*<��c�����v��) ���|�E��-uה���N
����� ��a����/~2��e��N��"2`M69�]^�D�y�t���q��bm{}�܊���FD�")ٓ�i��T�E���M��%3,�:v6�`� �DY�o�ZP5�E8�`o��^�c˯�Q���^9|
���=֖PJM��X���̋�9�Dn7�)^N�6����R��8�Hw�����u{�f�����N�]��z�l�~�P���޹`'c�xY`AXIF�j� aY�@ƃv���� aO���K�{����h�p��W��m׌	U�(����;o��Cn~�w�:MC�-������c)���d�hU�N�
��s��	768�{�1�H���#9�'���P��l��+b
z^Y�j��
�~Fv�I���߿K�	
>`�=���U������"?0]�t2�~�㱜�Dc�� �=�`�a�D�֋j7x��[�~f��
��i�Z�;���͓������B���'I �M��3S�a=W��Y�x�hA=НV��D#���a�^j� Md�R�{�p�w&`ܛ��c]���=�IC�Fd�
�k�n#z7�����T�
�
e�'��=�4<�g��Pm��B�]?�^ԋ���o�+=�X
p�������]���׋U�#kII�/"FJ�rf[wR\�W�ހ$��Y�*Z�,�;��)��2QM�t*�2�}�U���6]��������QB�D��xfG�%F5A$�|��~;aR�&�0$<��L��P���O����}�T���eݑY��ѷc����_���9�!X��0:�2��@(�&�U�Ǡ���첻��F_k����>��ob�� Վ^>�h����S��tm�;�]��a�:�gWi�w��aSõ_�nwB�C�a*Λ�+�"�4�����ߐOK.g����!ڦ�9ݬ �\j��F�,���y88�*|/�Q�B���ʸ�^��5�l� ���Gp�~ɑ&�\�(�Ǧi}�2)��;�|n)|��([~ ��xslwȟV0�e����Vܘ"�Z�����UV�*��Q�HF�I+�n˟Z�� �\"���v��52�3m�٢������<d�=����"a���H��HP���cr���`�2�6�T��6�^��j�d�u���$3*"	g��GѸ��+s�\R�Jy�Xn�# �c�Q1�F�?��"��l�v�����O�䈇�y*��P<����fSC�a(_��D+J�3%?g�H���Dr�L~�R�<�HO:��`���s#��YS��������Ha{Ra�������/Kq�m��^���6�q�}d�=E����A_E����4H,5+�kTe*ԱY ���{2t[vvY�[2 x;����y���q�j�;�>�����!�H���s���w�nn�K���+������xp��|��HE���k
)��Dt��V��1�3��5<)��;��Kf�t�z߽*���aI4/"^_�<��Oƨ��O ��Ю�P�	e%{u��)Zɕ��
8���*�q�!f��Y�Q�a�ma-�(5lsi��2�sz*	�@ߙbD�l0��}e��(dx� �q#/.��;-yBt�^ D��9PL�.�\{+90�	��p�Ӵ�-Ɨ\�cJdT��\4G�C[i��'>�t.���\>��V�pvڠ�F��M���/h��k�H:3>�B�R0����*��j?�̗4X�C�[G_�R|s���4�����P��d�~��?����o"���/:�9$k]>�B[ 0 5{�i�����A{�:��`�p�p�3ɌfZ���d��M*߳ce�-����n�_EA��7�?_:�]΄��,Q�w'S#nTέ&ŀWeI������!uv��D�QZ�u�R�?���d��W�Ɔ,/b*!#mc�:T���>%��M���K#����d�������gD,�R�u3�BZ:��3ck��\;˔Ր�	��R�ӝ���j���� ���(uGYu0΢��N��l�]l��^���+�$���uN,c!7�cf���}F5�la��x�r~:fd�0�療�xo���|斟QD3m%�7�kfʜ��'��O�����7���FGB�*���oZ�đ�����矲h�ϥ��Y�0�=?������ѐ�(��\;��u�[5�p�˸r�����d�w����Z� #;E��l�y��j��P?�j[����X�LO]	U, �$�A���j�iڃ��e~  [
35��Ɠ[紀���O|���� �hX�����gBv�����Yc��d�շ�u�Ϭm���\]��]l�L<bOУ|�Z��|�e�3����ˣ�F�*{���q悝�.�3>����,PT(c�͒�f��'���4�N���/�<ɴ�3�H�����4��w���u�����7-�]��z��xWq�2�
�8��%��#��ظa�c��m�~��H����ҁ��2���S,F��c�	��RE<��,,�L��N��m=�҄����5i�>��vY�T(� |(��S�)��v($j��Mɀ�㾩�ʹ;��d����n1z+k�bN��Z�O�9OO���	Vx^����q��Ö��`�ch���T-�o]�_�u�:����Qu�z*cQY�239#య�u�q47��#ѳ԰��$� |�}M�pCљ.+K�m��(�]�A�^���2�P�G'ZRI�q�:�R�>S���o+�P̮ԙm�?NW~�g0?�Tk
Ccv��aؾ1��w,�i�NR�h *À��Ԉ�~z� ��*��&�NdǱk�M�p��O�>��9%>?�Ʈf���Z���ʻj�N^������1U�`:m�liW�E��L/x������ﲚ���'��0�5�E�З��s_�4���츬8y��yN�� g�P�v����i<�%�D͋`��?~F�3�]:~v�*��������JQ���$��RG�}�j�EV����NYx��/j�;�N�9�
��#�ւ�c>��z�{�&�����55+�V:s����W�˼�l������]J���C��Q(�Ⱥ�@*�>Ym���\�[��JB�U`�����e�8T`oj�3)�2��߽�Ҝ��s8o��J�v������7w�ҿ�!�ZY������q� _�Y��j��@3�� �YqA���EP[.ۄY ��x-d��3B@�[g�a�|���U�����>��W�2��_Hn`�W�Z���I�S��Y�-#NX�q�H��l�]�ѥ;
�5�AW���Ǭ�H��<�t�������X�ËC�9��Z�M|h�i���m��Nx���D罞�c1�h�'9�� phY'�y���ڵ��S��rj	'����U��+�5��2�:�>�]�ܵK'po��� �J���@D]�2�M�(�_ћ��Dve��Ӻ���,�BU���E��8�
�z�4\�U�۾��}JAׅ���������Q���	*Z%��0���ɒ�����BoͲ�o�k�B�K#V����SY�[�2��K�����eid��'�(�8����}��R��b�D�:r��6���c�.�޶�oO*U9)��	=M������v��\&w��'���ʺ�@���	%ټ8��[�[�����j�W�G"\��??�#2���O�U�񪒓�a//��}RUA}y#I��	�����s)�zVk�� �=T��\���O��1�.�̧�p�>븖��O�z,S��Kk�>�C�f��?~u�8��TM5��G��'��KOQQ��7�}����P0ft���O��0�|�3'��A�=������cl��߉\�vӪqFc�{��/,g��1S��c�ݶ8��7,�QwO& ���� M{�n���r�wa�� 2���b��mU9y[)�=>f 3Z��W��+n���nDG�e(�v�s�M��B��X�H���翰b�~� )TKz���Oo�*ĽW����S^��Q���;���/���4�h�'.��z9dZ��t���@�@�2���PSu���l����������|�ΌI��)Y���O��2��-S����;Nk	Ng�QT���Xu�xV*�e�L��* �H�~x��[�Q#��D�M�A{ƍ"�aq!���շ�8�&숽2���������"-�s,(+�_�n|��`!v���zs�h��\T�K����c$_�u���jl8��i���ؽiZ8�Y0`� ���y����r�\�)m�C�g��l�����N��-;?�X�ɏ��������ZӞ+:    �>v}Z�0 ������W��g�    YZ