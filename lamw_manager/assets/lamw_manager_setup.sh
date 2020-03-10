#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1216041318"
MD5="5039f9a38282aba72be95b5c723c18d4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20816"
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
	echo Date of packaging: Tue Mar 10 03:03:31 -03 2020
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
�7zXZ  �ִF !   �X���Q] �}��JF���.���_j���r�7 2U���0{,���蕪t���:157H[��f��O�$���h��{n�^	��B!�m�s>��4F��� NV�10AA�ɛ���C��-����s�"Y�H6���Q�T!X���T����3�1:�n;��@c���ݛ�&�)���X�3A�(�&��0�@l��ᖒ����Щz�|���&��h�Ю�p��t��m��YLձ�i-��	u�2�E h�y5�	�O+�����)ȹ ���!l���4Q�S�E��,9,����=k:�1��"?�g�XD�Q�)*��]���P��i�J�%n��}6�M$}9b>���pˠّ)>����T�.��ɜ�R����/:�*��o��l�m<6�H���38�bk� gD���.��`�����%h���='"�}�
5�_��`@�az1XW�n���:��z�Mn�:�^*���CYX^�*�[�_j����(��g���Z�$L�بj�^��)_��/Dhf�[8�D�4�d���FQ.SHiR#����Vc_}�M+a*��YB������e���5���]���> �\ׇϦb�z1�P� �#������"b���W��.$�#�;#&�{�V������A$�?��G6�w�f����yʇ�I�!��÷��:��筲�'m�r��D+���|*6�KN���~��.�qCHQL�e��G���W�σ���ӭ��)�7����� .�O,mll���i�ZDh ��dw����??ˆ~�a�t�)P��x��=U4�Y�%9(B�0qG�t���5�K�m1��A-�Dd�K�(�k��������Wy��f��m���K�K8��y���ah��p�2�����_�%�$6��
��j��/==���dxn68�m
	J�~�B4'5]��-��ƪ7�k�R=����js���'Zǚ���Ϯ8�v�zxF�tW'Z� �P��t���n�I���0����o[u_Q ɴ�a�����x5N��p��B�G�l��w�1��ޛ��򤸉�،II�����vT^��pc<�����e���Ԗ~��tvV�XG��x��7�y��7��_ѰW";�/7�(��Np��as��v렲7����F��_�`��褅���[
�h�g.�U�ǓbЈ1�ҢH����n�ÎD꛵��*[R@�?$��OQx,6]��ㆯ�T�"��L�!Oj;�y�/}�Y�����^*������@Z��>ݟJ��9w�>�F�8�[��5���#, xYVw�������J�l�ޑ��?FMKj-;�~"ε91qV��NBtɂ��tx��s�ȱ�����{������;aE\sl�����P`-p���,J<�\n��ƺYzk�C>��u�����&��XϞm�ȴϙ[�0k�s"{rpi�x1�O�0��k��qq�� �����%���u�
�p�4�g�بZQc3,N�-Ю��_��e�����op�6ˊj�A�ЫS��2D{S�&������K�^\��ӣ����2}\�l�dZ��NҔ޻w��<���u��*��!�R.���+�2����|�J��s+��!h�0�< �ucZ�)��Ǫ#6K�y���<�Z�D�C�e�Ao~cp`�b����x�V�0 �Ԧ�Y��457��!�h�T؅��CqZVWsy؃�D�� �7On��5�#r6�>����97V����ʘQ���B[�	e�ݔ����=w�5)�5g?X6 )�w8��'�����gr��jl֤�<uz�`�.�+�|�P��bF3��317�Q�Ev�c�߰quz"����ͣ�]H=��2��a><q+0|NزQ�)�Bm��XhzY�����5W�٬?�ĳ�lc_��k�E�0N�"�oP���{2C���!ƚ����O6/9'7|p��?��Lz��q�M_��X�W̤험��#!���l�V������R�'�s�i���.���A�I�l�1�Ǩ��8mV�pOŞ#�/֒�d���k�8/�tܷ;2_�'L��B!��.�Ӟ�Z&�Փ��E��3����&Ì��~O���Rg�}f;嚸�6�X�԰8s��	�C&�c��lNV��0���zwA��*���*��ԡ������<�'�M㋨\s�xl8�A�B��1���Ry�dI֪Nm��9㏿�>z��S"|���l �j���px�����K@b�SȚ��_%�ԛO�G�V�P�-9��M2/1qGP/}]]���EM���R��i�,�I���C8�bfv�}�d��^�,EJ$y�,soȹȔ*��8���X�7����Ӣ��W���Ԛ���əU"�p����emx��6X\�N�Sa
^8lam����{��{"�}�����3�qIA}&�	e��>J�8��{P�hAsD�Z���i"r�{�%�x�'n�(���kU<��$���
�uu��9�Ph*�(e�qs��Eh˦ 9�������Y�������G� >3gD���s�{��T�Ӑ.v8v\X�Dr��^L*Y�'�|�p\Q��q���`��������X�u|���PD��ݐ���=�V� X&��v�8ڣ���Ī�#bG{��� �[�����oA�N`u������U+FU�DP�����'���ffQd���=a��2V�!�,0=�W�Y(㥐��Qsjs&:�L-u�uY�bɖ�Bh�D �e�x�I�;�j9�ZB�40ۮ�mu���Y��	��m�������{�>�����I;h��#�,Z��m�!t�	Mle��$��L
E`˗����B	,[�+��H��gp(����ڎ=6BҔ(��+-���G��u���H�L;����ؔr�%��<�J�u>ܹ��Zt�x�<S[HMe���e9�C���'���ŐC�D���<�4i�j�����G�h?BJ�����܂sTO�D?�t~���u�(�2�[�>c���|�d@�� ��Ɂ���̎�5�Ͼ�uF�q�V�i�����&*E�\���ޏ]���bE=�&@�i��]�{�\�T�|#�i�@Z6��L��  E�Їg�L#�����^���D@V`/ix�C�Ey�U��tx�Q�D�@���+� v���S�ɟ�6�|�q`�C�ޚ�dɨ&5���}C�V/�7_H�h������'xߦE����&�����BM���Y�̒���J*���%���b9*�tO�}�'߰��h��X+ֺK��V]��v<���5�R��gf�M�y��s�0�w�����E��E�F�TN2�A�>�܉IHQ-�=hܜ�7+��F�;U�G"��5�`X$��'�o-��������|dȡ|��I��?�;Ix<qBtx5ۄ��L��Ge�7��H�#آ��ŋs�/����s$��>V��#
��~������\�B����2�?fw4wG��K��9��}�M�n�n��Ν�*�1��6�PCM��U�[��EsC��� ���P�/v���DC��g,ཱ�$H������/��m�Y4������Q����\�FU���`����}B�ᆤ�� [7Ƹ�0Oމ���������=Y��8��S��X�`�	B�O���4���<�u9� ��Da, �+�I@s���w|��q�O;��IrK�gI΅Y�1�^�9��i0%�_�7Æ����^n�;�J4��ƕ�ZPz*r7)��kR��*���U��y_eil���o�K�l��נs�����lp��ܓ���`�ξУ��@]ZhЫ�D8
IǺ���X���-9c`��D
)�����
f�*��U��[�����{�'<���<�<����-�����\
p��~nv��1� ��Jt��?.-�����8�<�i���y�ϗ1�SK6�#�aX�Ii5�P�lZ��"��*��J5�t[*���>[ʏ�c|�(q�qM$�o�����6�w����?/��Z(�j% �I�O�{`�ya5��ޝ�����Œ�X��kj�hr	��#��/���?��o�2�n���������#�Z%�ebb"*���,E.�W���-�>���Ҹ��c�ҷ^�뒥�z��H���Ra���<mz���4֜�^#j�5��*� 0�qA���5ƛ1�_�~e�Շ"��{�8���4�����9����������H�¿p������^�ԓ�y���]�u����C���ui��n��w����r����6\�4v~�K��UƤ���+���]�M�<Uor���-�zNrh�U�D���#N:+vMb"Y�+�jO/hq�$QY}��(���� ��r�C�[��ŀ��b�rM��o	��U���ϘE��5���~��{`�hǝ�Xcl�lp>foP�#+|N7�9���e[�����m�'�LL �W�ʐ)���ժ�7���������8:A�܁Z�'�{xZ�!16�N�k���IZ����#6�#��~PZt.�&�B����_^�RTu��(��uY�$�a4z8&"�=�,Q��3+:�8΂<��d��j��k�x�l��dG_��-��i���ر�,0Eu�>)y���d�T��@ʽ"�̿s%�N���LK	�r�vg~Q��zH5}x� ��;���jN���K�UH����$KX�>h�"��_פ�VE�!"*���ď>�o[�����=0f�縀�[20���g��W�̊�e*s��1�����(aD���Lcω	�X�:�% iN����T�`EhG��q�l��8�;�4�d��K�� �)#�\�F��h*�I):�aHk�;����C؋G ~d����\�#j)je�f�ܪ�u�@�W!"�НS%�U�ԕ��6U�?y	#�M�>��U�(���6�-�ǩ�؄�ڢ1N����2=i~�bQ|� ������H�,p߂���+�!��/��[lh�fպ1�܀��ףM�>�\��'�۩g�U�]���.����x�a��_�-�� T���4/i��`�h�^j�g(��;�l"c�&n���zQ�M>*����fЦbgnըa)?S��(��^��I*���Byή�aC�9�=)�X��3`�>#�*�#�(򰁠N9_��(��W���m��mUR#T#���-�W�P2+�W���	��������#����{c��A����즹fUP��qF.[A�s��B� �����+��D��(���^Uz�S���Ç&����œjL����F����B���v�o���G�.8�	,�O!
��p3�<A�
)��8��j�%X��L1�|�r�_� �Bg��u�et�cK�RW���J���a�K������&���p����"���i)7ȦG<mM-ڧC�!�������s\�l\L�s��_�\ TY����]=Z���㳛�����k�!���y�ut1���$s�*8�y� �����oɳζ�dh@��4Iy�~�Sp������A��_�U(l[}�3O<���Z\�"F�\��3��1k��l��M�+�cҦdf��τ�0���N��
�%����"���hwn���ُ���P5�8���qke�UiJˡao��������=g���M��>��t�pn<��a:��R���5��O����5�4е�骗5G`"�r�G���zQ�f9�l��ǋ[ ��y���̊qą��r��{��B}c1 '�M��c\ǳ�tg*�&\���������?�+��O�F�s�-�Lb'B+��+up��^�c.�y� �<��bm�)\�k�I��XH�i���u��rT����$�A���]
�����18%2��1v5U�է�-*L�L�$�_�V�!Ҟ����g��m�|���S��Zt`|�˃D���S\�8~�z	3��g_I�f�Ew��[W��M�L�x�;��H��ԧp�t���n��,�"by������
��˄}�Ԁ�G��S_�!W.��Խ�g��:�II�w�f��M�����)#ݹ��\���<����e�����?׼�{���>!a�ֻ甪+��,�M��~ ���(��?��Z���z�:�.�a�]�֋�H��=#
IS ���1�I���@;��� ;L����_�4k�9��Z-Bw63��p������ٝ=������������}Dm�'�]6��@��I��y��z���#�}��[8�:�V� ����C������@��Rŧ���Zh�QY����׻ m>�k�@�v��HR��x	�G!�ef�q>�Q��qQ
n[���,8Y�9�¶�p	|֏�B-��f�:��:�NR���]$	���S``���^v�,G�cl�܋_+˰Ho��7�&9$ߖ�4�*��JF�{?�Ox7/�~-�5e�������?�%;�x5�n  ���`z;���*u�S^h���^�	4�w����V��`���+��b��D&���۸Y��XU��
�V��0#��b����h���ѕ��w���)��f����B���A�P~G��Z�*��j�p���2���[�uÑ�jk&>�3�a�U�$�ڲ��ml1���>��J!���Q�I�g��2 ����PFO���9�+�d~��\��d&���j%�Q��]���*�e��"/�-^3��<+��q�t,�9�"%ȓ�B�Ec�"i�  �T�fmqIX�R����
��=����o��3`7z&9�XQ�^�B𼔢��G�W�)�c��Mm�4���N��O���ڵ&h�3�$�bw�Q�����(���ݷ�B}��hs0�9��)x��5�1�:Ř�~�+,�*���k�a�7e6I\�h9_��0��|��/�����vek�����!���Q㱶k�*g-|������u����6�U��g}��^Ig�0~hWU���~�v�Ў���Әm]����L��a�����'�+X+����`h�6U����a�.�aٍ]�6��*r����5o�z�����uIZ��h}OC��%��7��+��E�4n�?��'"H�	�L{��^��	TcN��⁏Y��'I��vd�_��N{�����p�@�z���Fk�*M�I��8ʛ�(��5�Dc���^Eu�Sw}q�b}4��$ ��f\��Q�a>q����"l��Yͩ�Ș���4z&�ŘW�Z��)�۷O.i?t�Gy]�.����F.�}����6��!z��Lr_ٟ�'��Rb�b1��c�o��)u�3��i��V^�xg*+I3hF�F"C�_�:�$��2�z����=�N3F���hwD�\e�?#�zpYU&��A��u�$��PmQ��0�c01�h�L˩��ܖ����F|e�O�<u�-Q�����^z��>��sp6մ��K����,a��C`�2���MP�{M�l��H��/���)�)���9�O��p���di�c����u־���)D)w�������"��V�vz6"d(�.9w��^�m�,,���&������ky�kC�]r��2 �6������Fuqd��C�yy~�oE7]��G')<��#�c��\/bQ�I1��3���M`����̹Q����FYJ_Vx�n�G�췎;�3���_�%�#mXڡ��jd@?�����9C�^5���qVS��]!ufPqu��i�F�v��)ncpͼ����<%N�y�9��@��gRH��� ����U@�@����R?@[��?��ǋ-�L�
{1��t3a�A�r��XYu�z,���u�#|*u#XPЇ��@�$��im��S4"l
t�܍���P~�[�ӎ��&�(wAK���KU�h�1��z�l�昿��Y��5�Y?[�B���ɘ�d����7� 
ՕDZ�9��ҺT��1�܉-~��ݹX-iS���=�H�"�����3�ޮ@���`^%��U%V����*�!�LMKW�
���"`�b���E�f�Zo��eS�HEJ��<�R��# �'�N�i3�� ���2��n��;]-���vJ������n 3��H`��!�9�-��/b��آ�3����/�cnW�ߒ�M���̗6�o��qQBŹ�S����x.lsc�oKF��45�F�&;�~��b�l*�V$fh�nd�����)$���F�;wؘ�r�Kc�C�Tض�V�v>���6�5��O��ݴ��ڦ¿9㔷$s

ow��Lj�ݬ�������_���9�)���1���_��|��L`-�
F���b;��%�S�74���<������1#Y�[q{U\hLC�5���n2T}�l%���B��t�Qߟ~�4��&z���7H�������r�/�Dm�C��0�����B�a�xi}��'xKc�,iAV�|Ϯ0�۩��$6���}�������qaBv��==vB�>V�y)r�-Ӟ
q�,ɤ��#���x�Z� ��R�7OJg�;/ｃ�6yz�'�,.K���F�@��R���i+"d��l�e?{���~��1*%���.%���s<ǌ���i��^�=jΨ~
D��]����Do���;�.I�VM�	���m?tB�G�tw�3���k����P d7����� �a�1�͚us`B��o�29��4f�3w���H��Ͼ7Ey��蔵�x�)W�+���5�y��o?z��cf��z��jk�de%h������~�:<�͘�������M
���N���ҧ�����h�,�O���'�X#�4��h������3�b��BF���1��v�1,g6����XE(jZs�m�����#����c$��Y/�[�C/�jr�Ȏh@e7���"8�jK��@�tu��#�K�~� �4c����|��l	�߻�:<�������ZH�0��ӳ<7'=9.U�� j����/��-�1���g��i[�>	u�\�u%}�уD�d�O#����r5�����T�9��3���Q���RE��Y�����1�`�S
,�EYy�ɯou�����s���({��5�lK��D@�YV~�&7�X��ێưu�jd]B<k��蘎�����$�W��5��
ܴz�P!lU�L�x�5Ã-S��M�\����\��>]s��Ƞ��� (Z��� &
���짆��������`�=,�Bf�W'��Te3ʔ.ƹ����UY��������*)��"f�½�S�{݅���ԑK#��!WQ����c!�;�ʴꙻ���� �SgV+��b� ��ʌ�}�3h���G�<����M���*q����Ap��=�����\۫���	����i�.�wn*�D��k���x�مSZP{��#z��r��d�{��ƚ�/���5mbD����ǝ	ӣ|��7K��������U)�l�⒢���o�~�8������� #��m�D]\L��FC�R+\v���Cm�g�!da���B'E��'�o����m�^.>��{�sL	���'��o~�b@���i���Œ�����nά�4��̕d��>�b���ЅUn\ըaO[��m$�W��u�'ݙ��ᡞ�����E�O�nX18ݵ,вҐmL���8�&���"�G�b�����p�e��OzD��τ�D�l*IN8u��C'2x���̀���w�n���d���=U)a"���sl�������ɒe����d��qw��>I�-���[o.簘�3�_�4i`����Lm��_��]�)[�|)��������o���me힖��@�B�S�C�4G�װ-*� �m�cTZ�4#(X�9���|��f&�6� �r}n����:4�� L۴�Ѽ�\<y/�E'����U��Mm���.�H�/�t��z�g�H���� �J����Zo����FY�]űE�hG]���vof�DS���֏���u�����u֗�����dH�*�g~���j�C��w�C�9��Q]�!�
�m��<#?O�Q�x�+&o��H�]z	���2T6�?�ae�����R���u�𫇄�_��M�t����r����ҥ�@Y���6{z���r&G��������@JWv��}݁Y8. �OK-�M���䀝�T�j��D7�։&Mii7sٺQ>;S[g�R}#0���nK�_�{tac�&��f��>%׌���{@�4��f���m�K����d�f�/��w��{մ�FK��(�'�a�X�q~����2p���$W��k�۽�r��;\�����iЃ���p��6.B��Ɂ�b$x��s�����vTH	���д�������/�I�z��C{m$��<�{���M(�5�8�)U�t�f�1�ֆn�����/���)rh�Z'��蒪)�͢��C����`�	��U�r����e��	��Nh7�H&\���.�3s��-���[^H��i��WG�S�N���RH`͟��ߋ��HX�Շ|�!έ�<��a|�8٧���K~�X���^9{����I~���11��{���[G�i=�s��T	�=�߄��F�,	V��c���i���m�93Xz���.���!ð�7>�MS!!�&��{�:aW`��vW_��/��kt=օ�(��M�U���-ʍ�!8~��^w�ŏ��=�m��B�R�u�XF�#Φq��e��M�)�SGYq��B~d�9�
��=� �,̳j�X����va������z^|�ތK��0����
�!��a��F.�i(�a�v��:����p��M�w&�H����dX�d���npڹ�

����v�.�X{�ـ��՛�b�^7��#� ���$^��sD!��v30 ՓY��QH���� ��,��)ouv�b��]-h7v�~"M���1&036lnx���ŶV9��*����K�����j@�rʦ �����޺�Wv��!8|$b+��|���5+�iI��(p}\{1�Ƽ�H)��N�LTUH,%�NC�0���PD!]�Y��R�bly�2�K��[�(Z-Ow�tS����Y5K���ۜ_��4�~>�>Z�Ƴ��,���lJX�d#[8��%qaD����>'�A�c��q*�$�A�_���9���c���;<��yY��I�s}~����kQ���A�XBع���b\���2�hWكs��ɏ[Ngj�]~	
3�����P��Ǩc�%K@�������:K�D����d<�~�D��z)a�H����J�2�a��D�x�&V�>*���(c���埵�R8��~!���b�������ؘ��D�}E�-Q�F�Q�E:"�?j�3�P�j�oh[�����h�1�$�^s��2�ߚ)�����z}�sҼ7��]�Ծ�ǅ7%����8� {ˈ����h����#�[�:-#ae�$\�g��#H�X*��@m#^1F�{T��B5�(�!� ����hA|Q�̹=.d����w�~s���D���R��ʰ�O�V\�O7��#���b�N;�S��q&��lb���-e����..1F�'d��Ez��ع��ܥ�ΗJ�,�+�n�:���l�6�2�S���!��U��_T������Ӻ��%he�1jŠb���SJվŰ!���d㋅Q�0��z ���]��}�z���- ����?��5{�V�
�r�w�o�t�4I�(.�^b�=��5"��.�X����:^>;���@_�#�Ǔ���`smR@�kQ�I�����`"#N4'�e�VE��z "Rïim-!1�A���/lP_�ȳ��֗{g�c8TFF�)QG@��YE?=�L@�G����Ƨ�*!$���3"�VB���g���q����A�,
�C���G�(���G�d�[������T��Ȉ�ٽ0փ4n�rgWߣ�7s��:�l��l@�b�I�%�������m9��MJw+7P��S����6��ُ��2��0�Z��AE5@�Ւ�i��N �a���C���yuD Q���!��8�c
�m����.G�����s#� ��%��d�"8\���|�5�m�&� "
�~����pՁ���P��y��G��*��n�AB���"�ރ�Z�p�
%~��[�L��3ME��Ո9�t?%e�T[��m߰������4ph�6����Ͱ����p&z,�4�\�҄�3R|�J���@���
��\G�r0����wc�\ ��ugTx�#�7*�ڦ^�FY �C-�ⱆSwT3�����X���3�eRWG�'2*݋�K�OV�=���T[VO���P��򤆎\T))�L�Vi_3�nT��=cxǶ�'�b��=l7�������z���}1 �h�����`ĜrE�I��`��/�c�+�"�"�΍�=�1.���M9x)���~j����M�����L�H)�DD���8ԅO� ��� ��7j�6e��"��8��ʹ��,%���-��4 ����SإY����:|�:�z�I�!u�zK&��@�)��������bဈ5�:�{L�Ǟ3���;O/���Q� ��<��%4���R�@ͫր����u�X��o�$�jf7+Q�Lf�H٭.\�6H:8�����lq5�5*�R�����+"��<w6�0C�u��(W�����ɠ�ܬ�O3x��t�c�2�z	X�F���8���#�]-�aJ�������]ov�ݹۇ��M�;@��d�k�L���X|�p�-m�
K�ү���k%B)G����-��7��Ͷ�7b.�� ��	g��������$��z>��ݘP2[ift8b� ��"�Z�%t:������<�(2W���G�gQ�� Ld{�B+����H��>z��%�hO/�H`d��UPC˒�4%F|�S0�!�C��S��լ�z]`�!��Ԥ>_�P�Oϣ��+�L9�=Yg>0�K_��[���X���M����QB����"��r�x��)�氁
�O�<��s�%	�
�*�aMh�K���o��(�� w���! ɂ���c�{�G4Cfg�U�Mx;������Z����ޞ�Ý� 6g{g`�޲��{r��˫m������n�������$�P2�;m[��ǲ���=��I��CMT ��F9ߘ�YYycԘ*O%����1�8��J�vy�a���L�h�G�zQ�`�����y�^����C���n��*r��8N�gԱg�m��H�Y���d�tez}���OG�1\.�Z��r1�GR
]^���vi�����.�d~�*5���I�G�cNcg�ڐK�Ŭ��;L�q�k���o7>�'��)Lx�)���1	�b��!�s��_c0b`}�Y0�v�^��N%��i�� 7���#.
��B�U���و	��&X*�E���BK�8p�S�h�T5"�m���^~꺼��s��7�g��P���3&:�0\��u�vy7{��%+}"aT<ё���u�^��}� �Z�N�d� �a݉��� �q�Y�s(.hN\Dj�/�ꐦ�����+�tC��Z4�^F)׳ܺ��(�&pFTk�x=ۥ�O��_F��k�x>��R+o�O{�D��|�Ԉ�g��f!�n�~UN2�
���	��V���#�,����2�fa�3�i>�Wu��_�M��@W
^�>0�l =Ŗ���/c���;O�d0jf��~��J�ܥXT��f�*��~e��z՚�-iga8s�{��Pq�?y�猁�y��(22g���S��enS.�����V�G��@��c����s��oIb����kSv'9�����6}��0CZ���;�{���jҢi�W���$��ί~b�ƨ��%�q3
�f�H�sЕ��,�8�zd
��*�j	��P���<s�����Cx�e�(�R��%�ȯ�f��(����ض�
�|=��Y6��XaGFI~1z�\�T�/=l��W��vc+���t�)��ġl������ƹ/���c���M�T��;'w�FޱO���e�3��/��L�k9ყ��s��v]��h��joIS7f:Ǡ�#^���2�.�>T�i嚒 �إP�l�sp6���\��t 8RxX)/D��Ȩ�[>-�\[�A���g9�@0L�H(Huz�I�� ����̨��0��,���oS71�i8��b�3�Xﱭ�;0��C�d/�T2��
n���+!60�;�g�ҿ�d��E�����LI-��*{k3���'��J=]%9��Aa��{݁��q�DB�O��̧I�*�
�^��WB4|�'���|���w��/�	��6�3ُ�!�@H�<�.-�'�'�쭙 �����޾������o����JH(h�+��67�MsO'u,�V'[�All���8�v2��j(���11��TcU��N_��-�;N��@���BO�*�<�-V�l��k|hȝč�b/����UiZ���%K����>�v�QwRrgL�����$2����;mpw�L���q'����j#�fy���N�&���u:s�8����~����H���9c�!�w]�A��kثD)�±����4�;��:0�k+޴�3���Ϯ�5��2�Wi���㢵�%y׏n!:�͝`]P����?�	 ��ؘ5�~�v�+x�X���GL���j�\#S�S�/�NYhdQW+a�W	���WT���d`�G�Q?���pM8�m����Q( �c�\h���[��Mg�?1a)�C�M��W�k����1/�^9����/��	�<��|�`��lx�!���`���� 2ei�-=c��v&C1�݉�H�
�d�_�R�o"�^C�ַ@�Z�	�@���,תջI������T��ݗ�bA�|A5-h˘Mf�A�r�F�,��S�&���$� ު�j�=�N9_�Ci�,�i�N4��#!�zs�$�5��Z�G��<�8zC���O��j�k��9�̿?�^v ���-��H��k��{�Kt=��Gd7z�n������@ѥ+qf/ّԻ�oӢ�=�i��(��WC�ͬ'k`����@�UBC�ǫ�O��[W;X��4/M8 
�sWpk�Z/g�∞7r�RJ�Z&��9FgK�O��O2��:a�-ͧ�O��>���P�q~}!D���8F*�{�����F�|�t9�^z	~Ϝ�z�#eZG�ϭ�9z��0`��0��i6�nC�L\n�13�Lؼ`�n.�R��[9qYP�.�����4KV��stAs�Ց@�ɉ,���U̜���eո��6f����Jbm�تc�d��L��f�C��I�����&�v��'Wj���4�M�6�{���n�	g%�&CT���)�Ң�:���R/[�����q������Ǵ�1ifnJ�k�+O�S�-�]Ͽ4q���u������
LnE�D�mȻ`�������<IG�2�"2N���XM�3p��x��
i��7Kd��cD%v~eZ��)����7�|F\��*�d_�}m,-(Q�v�"+Χ�FB-'�m����?�������4����Ջ�?է>���p�)4ج�-�����s7��}��YLG�"I�)��@�e��/.A-Ml��X	��QO��֯�j(�e�D�5����w*>~iPļaB\�	t����,�y�-��`�H1?(>�N_�Ma�����Xw�y��D�Y㴶ZW�Q����Rd��o��9�����l������ٲzNQ����n/����x��ːϼ%�y� 0�a���eT�I����!]�?�Z�%̄���� �߬a�y��t�D}�|��O8��R���V8̀8.4䅺���s�.�5��������S��e&���ͨ%謹Lq Q�=D�q8۪+8(���g�z��s5f�2f��%�A7}��Kҁ��,T�Qik��Ĳf	E�n��4���we$�+�`,|�fJ��]�*G������v7h/̽�IB]��fQf��t��y��)�g3��_G"�� +����M!B
d�]�<���۠���{V˧X-�"�2��!P��Q2��TAvi�~C�����;��49f�,��V�m�.Vt#I|+�&9_�YS.Ix ���8�:�^�A&��垰���^Z;'h.��\�v�pm����)	2�㺄�0���P���
�E lY�]�B�˱N�z�Ӻ���7���3!>/���'��Q�m��D��ꏹM�/��n
�)IϵW�C��꽹��#������b�}�:���NwOZG	�lFTLnT�3mCKz��AIM�lU��<�E�	P ��L��aZ����&��ŻM["�0��S�C#Ez&�=��u%6/W�/X��
^�y25�:-�9oE�+���,o��|t������|Ǹ��z�g���ޙs�Pɷt�ޫk�m�b���5���u;	�G�Z��s�*r���W�^�y�#��:��w�
���J8����Q_�90w��p ����e��Q����9�ݥ��)MvݺYہ^��n��>�tlm"��oE���b~�����>��{��0�~��D|j�>�u��)��|ʇ������3�<5x͞)s�c�IY�������T�-wkU``3Z��	�K�Ja6�!��y����)'>��g�H�r�;�ټ6i;��f�W~��&�7����ɿ�&��"#�2(D�A�&�K��� E�%�1��y�s&����<ϥ�S�8��k#a4=�I�r #�����h��,9��A�-s���<"P�R���Z>az�t��%�jQ�.t�0#TN�ñ����\�q��eK��<Mg-���4��Q},��E���cM���!�hǚ�yumq��G�.��BU��H�@S(Y��͞ۦ��֢�h��bYn�Hu��G�������׸��6�W��*�m�oR�I�d1=c����kJ�{n�}ouD�}�'����Q��y�^̖T	۹IH�4��U�a띄�Z���JA�Tp,��w�_�-�g������Iu��6��4ROJ=�l���fS��v$��j���V��h����5v��������>	�lLb��x�^�/F#kY�-4��{	�\&>������z����f3%�	��C3{WBp����p����G6��5�� |ў��^���e�!�ҽr#��W�e=��k��}�3�"��h'~�u,W�P�W�q��)1/�m<�.�q�~�A"C����l`�<4lz]��0Z�k���E����u��:z��wT�����A1�J�_����ɝ�Dm@�v�;�Nw�F>�s
L1�_J6��4 p��^&�lP�~x�/(c!��X*;s0�K�ts��yӜyO�P�/�ւq�p�o}��U���8�;V���r�s"�R��g^p�'�����2\+�_���Wn-fI ��P�e��IJ=��1{���cF� �(g�)��m�5��e%�H��e� U�`���b�)6$<��`���h`v�Bt�Mfm��[�cu����"?G�2}I@<����:�=�Gj��&�9�؁��$u�
]��o���&�Z0�L{����/���|-c����~.�'^u'���rS�b)�A�������r�.�@�~թ׀5x-�Y��sqqA`<��Ӯfev��pֳet��Q'�M�9p����I�-�^O�V�fGg3�Ew� *'�W�(⫅;�%(ɬ�qE;�V�Y�g�e�Hf?�$��J�
)��e�ˊ��<�^ե�Q�RJ�0L��m@��R��<�ɪمs2��	����I)��b.XnDk��zn��/!�Z�O�b2��!C(����[��r`3,dץ����\�O�7`�	��Dؤ͝���`��1W����8�&�NփW�t}c���Q"��bx�	C�������K!�##�5�Ly�
��o��qB{�n��c;7��4}�լ_ڒ"]Cr]�W�\�^8�EJrF��=A[���<ҷ�ҭ����K�M~�������	ӳ5������ls���bS2���	�tE��TX�$�Ϫ��A��=6�Ɯ�@�e�߫��(���5�šV:�Q�������f�� ��Fu��ʗ0&7� �6V"b�{F>���߬߯����@�G����|0��1���|���)������e;��y���,KYf��Z�I�<6�ƪ�+��>��q}Q���C�7�؊]Nq��O� �y���{ۃ�<,ǲ�[�)�-�??j>�G�$g~R������\��p��Y�ң�O�f�{�;��/�
h<vC��IP�B��	e�@�*)�v��<��f�u�"֊�H���D���byj;���0�8��J��]e	����Ĺ@=�Y�5�PC��2Ѕ�9`����ۗ���N���C��f]ي�tis����(��F����V�67w}w�R]�i��F"��Xt�Ji�w{����BA~FƩv)|a�&���Q��Z���M	68
���%<f�F�=@ַa=�Q��Z&Ց���cb��P9m�~��?),��ߡ��M����/)���meY�p|G�V&RX�m�*����*Y}�E�f3�����x��V�yVh���(�f��7����3�X��F{c��^�/�Ƒ!���|��;�P+k���lIm�Nr��*�;�r6%��p�H.��j`�s^��?��
�,_.cD�zk��!�x��l�oL�n�l.�IEeE��t�֭�Z�q4����2yrxkt�O��v)�Mf#�b�[Ώ�9� T��J�{��F#�rK��<d���[&��Ў^��|�H��O����+�N"����6�r����lsN4pb�u�Of`�Rp$*F��<{�П�.��>.r%cZp)�m��U1/׭k���\�ꗐ���PYA�NLk��C��MՏ���VB ��zeM�u�
���m�X0�{Cap��w�t��D;3�yKT%��Sbp�g�o�0�$9J����đd$�s�3~�N�������	����t�Q�A�+�R�����}D�	>ȡ���.�+䝧Ю�'�vw��Q!{s�#�n��:�a!���1jK�c|z�b� ƲqA���������Z<tz/d%�k�e���W��s�L$��{JBO�V���w�X��˂w�y�,*���y��FȪV'�M�|��Ѻȯj��<�g�G�dLՋ�k�g��<�؀x�iK�.8��
Bf0���'�	�.[j�aU��Q� ���6�Z�@�|2�+�uE������I|��w��������Q���)UwC�·nP����|A���'a����n̯���3GW�(@F����x|a�E�z�e�oKh������X�t��T��o&���0��{�}�$tXA��aNЦ_�\;|�2�Q�����R�0#V����,q�CEcx�� y����mʵ��{N�7�W����J��˚H�%�+\�a���s�`��K|)�Ե�Qy/��z�"�����c����0�2u��Q�v�fx�1�_����p"���fP���%���G �st^2���D�����B���lQ{y������`��3~�~+���ەz�L"R⍃CL`%�+-R��g����<n���ZD� |�u�ݑ��U6v��-��{B��� ��e"d�S�'��-��S֪g-(�EI~\ٽ���m{�-̐X�]�9C=�����@�V����� 	M��ɞvgk?����/�`䉅e �1)td&k ��C n�`��{s�q+��pK��9,NJ9MH�(�LyS�C�X-*�	Ѿ�b/�%��h>;EkW��OJe�Lz��a���T�>�/�m�V�Vj
V�1�˪YJ�n*�����֑4^��-�극X[TY����%w�HϚHC����y8�����Ʈ�$$��iJ�Ҭ�*?Ҫ�2�M�����	Ps54��ew�e���d-v����k�M�)&	�=E#� 3w�G�f��:-¦�5�!�/��9���]m�)�Ȣv�*.�:�x����[�U���Z�o���P�Ӝ|�#$�$nn ������8���y$�u��s�<��\O�b��\J�=����?���%��'�f:^�}�M�n�x�ʙ̰�K��뵑�Ї/G�A2y��D�liԁ�L��X�F��b5���4�<�J�	�Z�����a⹌Mv�Ζ��C�����*�d� H���x�>Ţp>���f���'����/��#�mVp��)��5�TK/��a��ur��ϛ99��J��u�	����J��m�U�*��<�Iu��Y�c�SJ���:�ȫ��f�9o�zM��[AV ���T��э�]L-@��	�`كō�L:p�W��ZO]�Hǲ�X|��3�Vv�X�����;�S��`�ë,>F,JId�ԎA�\����=N�̰.�E���]I���eҲ���!�	}�Q�L+������Y    3��Z�. �����O�o��g�    YZ