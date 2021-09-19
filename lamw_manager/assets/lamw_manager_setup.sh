#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1507055575"
MD5="2ab4bc38b147121440cc1bc411bf64a1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23820"
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
	echo Date of packaging: Sun Sep 19 00:11:34 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D���4�}k�tP��(�_[ay�bʢ�M�G���"�2�n?�b�1Z�/"2�DXj:��)ɳf�3�Þ�A �0����J�#��PZXb�8~�+�& �����H��-�&<gC'�]�GI�Ar�d5�U��/��lU��1muf��e)|oI��fyxƟ{����2��`�񖍩�<̒�᠆�.�%!�Ax�������g������w��k��{�=�;F~(lW������|`�W��Dk��\a��8����k�:s�
�
�:�
�6_K���5� ����#a����[W�yoq �h/�x���+N9�N�+,�}�:�i�,�m�[������%���{4��MzLyo\�3j�2n-�Պ!輛j[�YIE@�0�w���@�U�����D��й�,���o|��c�M��A�)�b�@F8��)_���i������$�~�>�(�?�Oxز��B/��ů�ut���Z�T}�m�W�|��Kq!�A�8��û` (h��%4'��S@�mя/��Ri}nZ��L6�$�������X:���r����Z��.&:1�G�>��Y������)����_i,.  �����?��S�� 9���IdcV]��f�K�0q=ݦ��Bs ��"����fPL'����y��W�� 9�	�m�R>\d�O�##d�0�����l��Ū�Q��P �xX�if�,Aʕ�O��� �ay��diP�bW�L�o'�d���~9C�Y�������$���/~���W���sP����*�� ��O���Eq�D��H����̍��&������Ҍ�%,ːq%,օ �a4�+�A��=0�|8�A�w/����)��c½�H�!8<���R����HVI}ۨ�\��o��Ǳ�h!vWn�"�P�$������f5�,��tw��[������M���q���p�p`�o��(�ۈ��KL��N �n���I�ͅ`z?�g�Y���o���Kp�!ڷ��$I6?R�M��3%�U:�E��fÎ�C`����K�B�N�ێ������2~��	B�`�����Pa/y�z��i��ߎ&���k�K~�d�d8�x��K��/x�W�>��IN����$�j.�ū`eב�����[x����s��{�D�\�l��W�P�oC�6���s�	���iS���=ȿ@&W���y�-I�mK���2~�4�T�|��I�u�GyX�Hv�Jm�x��v�`�#ջ �%+13޵��͎�~_��w���y�"��˸C���qng2���.H���jC��tls����"L���eT[^ZƇ�����T�Vh�Ws�b�;>��}�w��V.�̸��v(��_���*�I�?�G:�n�ۉ�J�m3�����y��ǎ�1���ƙ�-K[�;8��Ax�XZz�p?��q���� ��p:eT�)�"��_�}k�SP���+������k�v@OM��Lɰ�k�������J5:2 D��b��&N�0�p_�hoǧ���U�>�{ۅ��S0=MlZj\�?Nl�s�s�
t��v���}D^�<��]j%���Xj�Ȧc�>�ⴌa�S�QBs�5$-�&�=ƹyB�Ou,
�G�-T`�Ϭ9��3��?5��z�ܳ���G����;��*�C@��{T�h��me>ڝ�Ͱ��	���m*ĹB�>��1��V�Ur�ʒ� K]%U`N!zo4J��]����4�����*��������69ȕ��>��<�O�%oڑ��E���`㗃���Ԧ��R�[�~�^)%@�<u.��\/���c�X���	�Ďg�`%�鞨n4f�M�X"I�Xtq��z?�S�C�e���<g�i�l�8\T�q���i����֙��81ZK<���>ٹ�<��0�K�smU��]O��F'	ۍ����\)�d�-�
�8�R�9�3N�
�>�)FZy㠃��n�N�,��#An>�&*��gEyFo2�0���;ޜc��KT�]e��I�'H���O��o�f�"�zk.;��V�Ae�}��2�Q�U���Jq�IՋt�e�kS���6�����
����8�Ϡ�Hg`��|���J��~4%��}}B���th�6��LM�4a�jͤ���~�d��2+E����)DJ��̧�Qy����=u��M4X�,� �
m��M� ���3�v��]�[�N��Zb��������B���B�ZK uQ6"\��&���~a~+c�>��AJ��ZI_̻���������Vo�]���H���'�i�9�g+(��^��Ӝ~f�a�r<���]�{[p.S,o�(���^����]��e6�S�+�"C��!�D7UN0��Ai��L�������t�8@&5Y��U^:���F�����QlL����^h+����/Q?ݝ~5�xY1p���Ⱦ�2T���j���d�c��4@`���m+N��ɍ��88�����d&����g�֚���Û��YF���ekȯ)��(y�������2H���ظ���@����BϷ֠W��@�E�#�� �Tb�g��G�u�O�}�[���0z���(	>"9���X�S�\	|��g;C�ˡ��B֒ao�}��y��������ߗ��(��$o/� M�����9^��q�s�}���\$L�����.�GQ�FQH!�!�iA_eX�5������������S���_�B��5Z�!�u����ƫ��{�0�s��Ɔ8�K�dS@z��!F�;���k3�L�PdRR�E�xʐ�A��(�����Z�q&�e� D�����I{��8�1�mW�#s9@d��ӵ]�Y�0�g��++��wMg�-�✇������c㦞�4<#�}{쾻�[D�����`<����{�m�c�G�U�n�Z������;�տtب)ތ�Ƞ0�>^��ݏ�Z���௑�kB��=�̯G�Y�A
�ѣ_�-�fk����pp�W�q�?-�B��k �[LiX�vS����oFü��.I6%CZ��D�߶�;��IH�Ć0�j,sҶ���Q��%�x?��� �:J7�lz=��z��V���i�}Q��Q\6���8{i�����J�b��3\�*�n7҂4��p�mg^��株��G/8T}�J�4k����V@lT}m���>ŀ�\>[�+#��~���b��:p5&N�QdV��%�y���Q�>k��-G��>W[��!ߋ>��jJ'*U�e�͒����敁�.ɟ�Y��|� k��= k.4�t� \�[�� |�*�x���<���˱t�*��R�������$�I	vZ �T~7X��=Y����n��@������/�B+[�.��NQMc������B�U.3LR�	A���!3��īQ��L�ܻ)i*�l�2��2�Y̌vWqӏ�� PH��o8��NUR�05<c� ����
��YI��p���t����dxu�Pb�	a�Տe~��}�Z@��`��\�E^ۆI���e�tY�� &��d���":��Yɤ���E��(�:���G񙦷�����d�^ꅷ��wX��v	����9cM�!�^S�D3|�]�^Av3��V�ܩ蕮r��y%��g��J�z���V�'��`++�,!sE��#�&�T��T	�D�������uB�=(�OW�q5n@��0"��M�{��6�<���6�_#�PC_���c<\��G����bH����gm ���c�0z�=��{�S�}b]([��Z���e�MU-s�XjBJ�%:���4KN��a�G��@#��R�Ѧ�JƼTfz/��4����ɜ4�ἠdTu-�*���X����&"M�;�}��+��h�����i��ϟY�P
PH��N�����Ѳ���K���q�R|I���1�S����⛽R��X� 9�:_v��
��"�EU:WY4s#��o���̀�?ss�r�T��'P�u� �	 ��Y���S��OVW��0~�BSx�3+`\%��C%S�L�So� �JV�G���]t/\�\�<AC�]��o¯D\��dX��|\|�^��;�b��ۍ��D V��}k��^�5ywȯZ�֓N|a�h+O$��͗4rip���m}|0^��|��,G��nDRX�<N#��
e���Z�1�� ��@P�>yC���F�K�؈dv�'�z��l�':'�CƨOD����R��L1�:��WY�T,��^�d���u5�L(��ߠ�Yk��o������"�֮1���8�~��-X�쫠F0�V���o9 t���\��^�$V���#������i�+`p�C:ɉ�.����m�W0iciq*M�z�j�]ƒ�KF���9 �&�7c�mS-���]�L2�ؾ��m�HGD|�Gi?ɯ0�IO�7-�bO����̆m��+8?�/v�\vj^�����1�#RT���z����$���k��ٜV�hx(n���\�R����n��
a��"p�L�xqb���� ��+��6�l:/�i-q�����1�C�����1Q��bh v�@��[���M�8V���Dc� RP���w�����E������2��X���;�Isc����G6�M�j�pR6��"����qpO:����X�D_��N�ٲQR�*��ڟ$1r?�'�Ch�0�/�
�l���D;п1MV�6#��Qg�m��=�1�1]����ؼ��^�/�7>u;�r%.��%4z��E$�w��U�m�B����0���×��N�������T(�w2�ނ�uo��N��Z�3�'g�s�.�IsB�^�%k/~�	���y�BLc4�k1�"ppԧ���@+��T6+T��n�jp�`�"��j05ѝ���(cR�V�[^D���G�,?�f�Þ�b�}��N�m��\� u�� `/ǀ3=���0�)�3�4�Ӎ��\�^�;d��G��	��_�q��A����v��T	�7#�[���SC�0�(���"�����<�
�����TW�z�xs�F	�L�htH��*�ۿ�'���iԢ߮4��ĽE�Ux�|��͵m��ު;�W���4���DĈG�&�4��g���*�B����y(iSN���$��7i��vD���Z�</Y�ܠ�j6~�v��Lm��؜�5����NR:,�w-+ܤ��G��T��e�8�F;��;�3fP
��Ցk-��RN?��<kݾ�� 3H�
ݶ�ޒ���.;�y���iZ�v�g�Џ�ڞy9�񰺨r��lA��J��8���B�� [�tR���䙌(+d�C�nᧆ��D�z���3,�7_���{�0ѐ���Y0�}E��)sLY$m���6:�ƍ�
���6���q�ӳT��7��O�B�ڍM�be��i=M$]�b�r�.fh�3H���CB��}w��(׍�Ͽ^�ٵ{������"��h�f���o�u�����&��D��sW����]l01,9P�>�������_)� g����Q���<�,�#V��X~w&�:�#�BA^�*5�r�M�������n����T�}^�́ihD+���N�n��er�������[63��/�(Y�%�
����GV*�=8����-o,�ZeЉ�*��?�U��f��툪��&P�g��,�Ϗ�����*wI9�q��+��?�S����K��e[��	S71=�O���O��]X��{��!k��S��DA��R/3y���4�%4[ꃗ9�`�ɑ����_(),�9�pʁ�=�ȾQzef�	 ��5%R]z����/���� k�#b�z�R��!�v������*�ͯv�+%0|��k�<C�y��*j�@�Xڬ�v�����Ecը4Y�c�؟�I��C�\�*�q���׼'�`�l"�����vͫ���_(	{�`q�o��$�?�F�JS�I�.�P���? 2��?t؊д75�ǚ`sP<Ab���I�q^h�B#�F�l|}#�?"?���,~��ň���oG'�y�E��k�*��̙�hGs�J8{����V��9�o��/��D��ﺊL�,e�_@HW�W(����.J�5r�3�2S�e��N� �{�$��ͥ�[ߝ�*`[-9RU4d�0�[�m����r�,h�}Q������NZ�����:��P:����rg�"gY���b�����!/�?=�����;F+���YY�"l�e�̒��Y׶_d�P��!��\�)��Xm��5��.u�*�K�J�%���}*�k�U��1�v�hdʷ?b�Z���bƚBӜ̉_,\Ѣ�Y�:������-�>�8��)�oT�ǒ�`��r�੊��ܐ�m�bB�$��m���A��,���;�L�!_#��	�gLX�\.g�ػ��+n��KG�K�(jēY����F	��i�z�g�z�UPD�e^xQΟX��H�|��6^�.<Ե�*��d�1����Z.��?z���S�l���l����೉�%ܽ�y�V��z)kw� �Y⌈5n�C�ujk%���{��BGB|��T��ti2����unʭ 
x���$o{߀�(��)�C�����v� �xа��{7��so�85/�#�Ř�����U"Q"F�M�@d0��Z�Z��j9�b�唐!o���3%�g<�P�Ye�8�+��C��2���6ޘ�g#&oam��7���X�>!�-Qh��r�3Ke�*E��n�[������C##E�q�h�"7�n^ثn5����4J�g���ISd2��X�0"���v�ܨs��m������|^��v�g*K�zy؝��4h���Vv�<ͤ�{���Tf�~��z�>��r(�0 ����s�K�rR��آ���ݩ5̯��,���rt� ���ȉԞ�/HW²�Ѯ��xn�LNlV�[L.ua̶,�v��,���R	s��Fۥ�jk��c�1��T��ƭ+���({���h���e_ɭI>�}#��H�Ϫ�x`����x���(�����n�qYKYS=_�q_3l(g&NsQ��X!�*�ؿ��n����/ۣWM�K1��@�>��c�בSjtO�+خq�.��_k�;Q�����BT����+z{��Q�:��fHD?%Y��h��8��!��f�|�}j��x�΋��O���"l`�]�*w��!���[c�>L�x��^Q�
�����[��Ǉ�;i�����,Zjq������7*�r��*n������z��V�8��*!�o�Lw<���mĮ£�{'k���w�2Va"0��o��������y`���ِ}��.VO���>�T�V=�S������n6�xWl�����v#В�wsk�7�E���D�K�1�w�\	����&��%��܀B5H��)#{�`�P :��
�>�3���풺�� 0��hV�-�e/�7[>��q����/��"���O{���h[���g��oы�k�SE!���<���?c'��#�Țk¿���5D�B�$8�/U�ge�󴴦n��|�݂ꡆ�eљf�g����>%���)K��0̌�R1�"��1ؓ���I�6 ��y������Z��1J�JV(�8J����������Ktut�a����i>~RK����N�P��c��yű�"�t�1����K�ˢ�D�q����\G-5�%�G����w�H��m�ܙӸ�/�͟���F,
F�%����I���F $'z��2�L[!�o�wv�e�5�X�HCz�d���K��$4f�n;�T�]j),�&fp�̘�>��o�����4͑b7�a�(%��Q����AC�^$��w2o�6��q��ˁ�'��LmT�<���q��w���X�vd����5�p�NJ��gL��2�=�/��w�����m���ˊ��V�Z���Y�S��]�ID?����U��I�z�W�Ӑ���J	Ã�%�W�LOV1�0�Y���*��eU:}!M����ګkF��7	���ܱ^ryʗB�%O��Pٖ���ꋖ��E�fͩ~aR!)v���-ч�݅(C�Z1�[ͨ��S�V��Ct��=t���I����<OzU;�/��a�Fk�+�n�A�r,2�帒�m�œRf�:i�%G��P	�,������Pc�m(>lk�!�;���T�;���H�A�짉�գk�Q������"5 ���OT0�����ߛ]��=$3��]q��vh�۾���e�D#�{lhv���h̬3o�d�r��K�vFpdh�~ߋ
�K�O9��<a�3x)%���z�7��NXY��
K��H�Ljܭ&ݑ�� @���C�i(�X�S��6���H�DU�#ƲV^�����XO���<I\����.�`��W�ao�(����ч�9.�Տ�5��T�w��,�مHK
K�8�8]4Ԙ����a�$��Jކ�h�+�N�G>w�n�TF�M��di�t���ɸ:mD��:ԗm�f4eLr������h���X��LB�>�^�f�a8�N|�U��#'K`Ս8ж�D�1�V�T9L��E�6pؖc�0��G��k�Ž���6]�0�`zy�]<��/�ج�y_,����C��6a��+�E�ZXn�$mI?�\�K?����Z�{����0>;8i����വW��y2s솱�!I6c`��Ϳ��#���`��1#˻����'�e�-���"�:��%8Oo��W���{���r�Q�mD_���T���Zw�~R4�	�(O�/P;*W
���y��ִ""v�C�YJ� Dq��V��s��,�hUt���#�
�g=��!(U6A7wz�)�z��Nok���fz�T�\�1���@#��Ս׭�T����pM�b�֏�Xǧg(o�9Z0%�դ@c�?i��>��.h������i�hM���9V����Z��|#JE��ê�����c��	r>@Ƣ�SW9\��+zAY/eϠ't3}��q"^��//O�" 2���3"- ��K'
``"p,f��%�&}�Z�3
#��S�G�&ß|�a�� m��=�2�wL��������[,��BՈ]��7~օбN��L`����2�\�Sӟ�J�2�t���Cp�DYQT�w�W����z�$ffc�l{�ɏgrT���;�+�doǂ�\!�z��4l���P5��U��g�&q�$dlVc�
��a�J�$*��a�>Jl��L:]0HU%e�F�$=a��юc�$�xD�9]��ZL��������'S����j^}���=��l�r#ʹ�fZ*N�+�� �|�P4�x%ٺ��X�pbHD����g¤O�<fWs�P���XZ$�'D��E�����&�hv�3P��b��0%V�}Bœ�Vqx��3��,
�5����uf�6��q������;O�X+"��Xi`ȿx(���F�m�� ��a�M����Z�2�ay�͘Jtj��l����m�»�a������;yhh�ʭӀF�'��f�H�H�YY��v4�C�b����r�[��*Y���ߟ�a�m\|�}��/��puQQt��'ێ�0����*"�f<��L}�h�}'�a�|B��C��[�I��p���\Wp�P/�=�+��Wàk:��{�{�q^�O"��?�����V�^�w"����$#�#^o��=�i�����,uR+����FZ/7���8��*�U	6[�͚V�ʡ��=�6�~�����-	wdh٢�]Ҙ,�9J,��hs�������$���V�.g�9�&�HζY+�/�&�������aAX׌
4k� ~,n����޳�1/�H�̴�,rx����jC"n�u���kd��~�A-$<ل���k"���O��X����㓥I�M��N_��@'��VX����OK&6�s�P(�V,g0��[J��*uƩ�<`ꀉ�v1��x�6~I� u����S�vtr���Zj����M@���',���#���SɊD�-8���g�r��;��g>�C���������H��dc��2�h��3����ֻRL^
�\�L�R�ʨ�&&K�<A��`�����x
u����2�n(��A�5�;
x�� i��U�>F5��ع*�=��n({��7�-�MP04|�%�~�|�^�|N�x5UP8�`�.(W����� �A��X(>RKM�ɱ�pD��p�f��`j��\&m��J͑4RI�`�>�߰��ZNC��^�&�т6�Bv�
��ʐh^���-j����n,���'PR�"z�02��B'LWK̼��8�ڥ�����SN��j^��;W�'��`�a���T(��8�Ot\�&���u���6,C~��~d9�L�	-�w��{Ք� ���C��4Z9�Ր&]��xl���
��?�OĶ�te�Hiem�β��_��P|�����e>�0̄����+�D�m�D?�0"ӌ3D��CŚUd@��2�xU7��`\̢��=�?�=4��zQd$��;���h�z^,oy�c)ʒ��&�.�6?��=�m����<(�����ݓU��0�.�=���k���-Ĝ�ɻ�Ȱ:��t�gO������C;�t]nFc-fM���Ƣ3K9�b��y�W�^��U�[C6��L	��p�VSˠP2:x�5����d�q��醬!Q!o�p�	{��]t���3О�-��rS1��N�.�0~���ֿ�T����Ն}�
$Q�^�2��L��4T>ֳ�vᚻ�{�"�W�]�D�qc�i�'�Mp�$"��0W���ޚ�M��h�+,�.��l���#`�Y[1O�ci��U��3�wx�JW��K&�dI�<3\3RG�ZkPd���g�H%�(`�<0߅����>|�E��Ɏ-۰�R��5�B��T����`l;�p�.�]y'q/$_��%��N�t{��v�קf����WF��L.�/� �k�`�清b��`� ���G7G6x�<�	x�!���n��u|�l����}cK�������m����o�����ʡ�Er,X��1�K�-�Č��0�~~WC�x6�����J6��7�~��>��%l�<�q���v���� ��U�.ޟQ��K��H�v_ơ�s�Ew��O;a���:5q`��a�����Q�K�&����h��,�<���q"��!��?�Q ����s�b�;���� �jF����>�ȿ�DH�O?�끩��-i����$�M�7O�}�З��8f���l�:�l?X���I8�1,�����+l�as�{
j�gh�i#>�Ď!���?�di��ǹk�5��^T��'�wΪ�	�Y�E�a1g����
�
�Q�/)��'Z²��4��_\�H�R�Ϗ4�p8s�~R��9��i�o����x��#aU���S@f_�^���."a������D(N>At2���My�e������.�PZcf�@�J���dx(Z������1$O㜧��N�P_�ӨV���ICP�_�0�»��1�;�Ǔq�%���D��p�]�ͨw�V�hN�+ -�_;��J�-�6#�?&��_�z]�3�����0(��9����g�Yr:�Kރv����{����}�^��i���)rŷ�n�t�<1�	]�U��Ѯ�dS��+���ex�8��'켓�k[����W�gZ�!�	��ݾ�3�#���s�����x��9t����i$U/+joSs�耋��K��V��X�3&����!�mW�]��۳��e�h̿��S��[duѾ��h�es��VD���d�Q����aq<8���i�%�8�]S�e�! tz��>��n
�9����O�ZBE筘�EtP2�
>IU C�����t�㰤��5ǋ�`�}9�R'��nln \��2M�c�C[C�){��I+_3��xw�5�B�&�}៑X���`%��`{%��=;��:�Ð/��-9؜$��9�������a@HR�؂��g������+WU��۲��$N�`�V���%�,x��˟4���u��j"��/ۂY-;�v֗�O��r�j�@"6IVf6N�q��5,rRޗ�4D��Q{��w>�n/�n���yԂj�!��~Qo�\3P�Y<��2�(pF�:�e�B�`�F2:���C{���B��L���(��Vh{I܀�޾S�p�������W��E�U8�ӢV1%���b����Λ[d��.N?V����e�&_�A[Y^z(�^�Q���lE`���:�5�w5q���k9�u@T�F��/k���KY�U!�}�g��Ί��D-�;k�6�(ʺ]����km���
K�t�z��0r�P����Z�4�e�}��R�ͮ��n��q֑�^���EK��o�f�O�p]�.��\f?x��'@���B�tH����A��B���i(� ��*!���?eE>�"1���m�i�gW	P�َP�#����O.�t�O��)�_S�?�!��{۬X)��=��f�+�� z�����s�� E`�"����ׂ)��������+̀Y���¶�t�I=���GG&_����p�0�R@����k�\pw�Àv��pT���Mn��Åi�q�ڈ�n��:^�	e��=r�49�`̥���#)\�gL��xy������gr���`c���;V�9�y�؜��
z�n���H�������T��`��+�/S��D|/�����BEq��r���r�L���P�,��\������K'�(0�q}��b��o���>������xT3��M���ɭ�MW�]�n��]=�j¨��$?`�J���$�����ϰ2�)@�O�y��H����`���>V�x�a	�BF�ݴ�_���$�mî�p�u4用�Փ=-�LGˍ�hr��A���M����[J�UH�]_%��g�s���mbCD����en��҃5N�h����˙�e�S�ͣ;W.�==��e#&jg�S���(p�E�W�/�ޮ� ߾{"j5�Nj�/�:I����5�6�od���b���R��ߙ�0����o#����m���!{3>���kt��vz�^�ob�a�N����}6�f����4"��M������C/�|N^�*��7r�/2?�o߯�7>�8�ܘ2��ݽ�w|
�v��c7�TýAo��A4T�V �UYŲ?���$�O�?�Z�<�>�짭V�H#��5���!����/4(8)�X`�ïw`��BW�sXf�x6J��j�S#GzM�c��*��T����e�wc0�M`�o����鷮)��ճ'����j|��>����i.������~Y��B��Gw��^o�o�
����N������-5���o��w!�\�����r5╧
-��j��g E����A����-�ŨW:�[��ގ;��,&��bi��E1�<����_�:��w!�}h�c_LL4��nv��"��+?7��6̡F?��������%L��J �%�9CW����̊��.#sx.�,t1�6w��k.YN�{��hR�9sZǼI�$�xpLdW�� h�Y�Μ^O�[�8�\��)M�M��_����{�㈞�����u�êހYU�v��w����a�Dwτ4�o��� ������K��0h<��;�B����YL�/O��2�3v���i�s�]e��OD7?r�L��g#B�\�y����ߧ)NjQ~�g�D����9+q���$TO:���]r\��
⻎T�21�ri��9(��mt�����lc͓g�2��6X��iN��Л5ۚ��zQV��:-E�mcZ6q���Q��Q^#;fK��湙��q:�OeC��-��f�;�މH�9��+C9�Q�)�SAsI��پ��Z��bK'�oTU�Z���n��)�y:��"߂&�]V7Y��Je&���K3�]�l��m){���1�dl���}rޭ+T�i%��	3��� �k�Ⱥ�^�X�>��"(��*J�u]���~5�"�(�zmf�B8_���~j�ڋ�`1�ȍ��h��xX3��@G�Z VaJy��M&��ڴ�m;
����G-�,f]��\��-��z�~�B�je�oz�[xk�ʒַ2�2�x% ���(�CuXT�Β*�/o�
\���	�x+�m�_�˴ޮg^h��z�n�6"�@Aŀ�7��,�i��P�\�	���w�� ҺJ��⥺�Zk�Af+~�������V$;vU����9-UBx  ߟD�xȩd��O����f������J�0���XN;5����J���0��׌ȗ�٢׳���?�=ԑ�A,:6�?����AA�a͋f-�R��/jm]zHzZv�?N�Hn�\�Z�LW^�O9���n��-���>(�)C����y����f��9^|�Y��۰����d �йz�E� ��~/c���5��k_B�#���n��ԭ�-4H@֖�Ρ��S-�|n��,S�`�=f��z ��� �:�0�������B����O��Qow��"U��p��ң�v�ۧ�H�ѷZ	�c`��WL������d�rf@x�����W�j���; �j����݁�n~�� (l���[v\��*�Xp����?L�b��R_j��z� p�I5����axeFُ��0�F=��-�~�y����N��qv�����l���=��z�]���f�O�QD_R�W{�<�Q6� {�-w��J���zX �JC[�(c�KX��V��"�]�KԘ���+�,n�a�6�HE���n8h	�$���E�3\y�!����p�e�Pv��ʎضU�xTA�e�M���Jz�D&�U� ��0AP}(/c���r�B�������[a�f�,!�Bz��K�쫧z�WE )��-M�J���`hݏ�
f� x ��_hj��"c���o�H���k|��GxH�9�ꁱC�P��Nc�,��uG����J���Cv����������3�.9��	M�	�<��'*"�t]V�m!�,F.��P3�ך xh�Hb��D-������Ā|(�N$��2N2o&�+�,��o[ϒ5h�O�޷!iJ��>1']",����H�{� ��$�8��Jf#�|��7N /�Q����$�;e�D7J�^_�fX8��Pq 7>�A��{pe��O�/t�^�&���z���풟���l�6Ąx��N�
��X��W�]��8[ӡ���� ��|��=�-�x8M��S�m5��S�uL�%W<iC�|�)�C8O�$�L�� e.^�t�dT8��M�Z1}�����o�K�}��Y��.X�a1�G��&��]Bd[����u�^vC����(&gP�9��i��E	v�Wg�6&��b˷�/ݢp���A�݂xGܲ�z�hxuWC��)$M�~Z�v�/�V+ɥe[D�B��˞1����K�<�yuUsY���^�_քX׼d��}�~b�8��ͪ�+Jm�TUD��ZW�3{���vw�r�B��k��F4�L�N��52S~�@0-8�B[�̱4�
�s�˝�0g/�;�D
|�hZ]OV���u�xd�^5='%5wϞ�Ǩ%��2�^��R.�/|}QCC���j�2#)D{������)_.B���s�G��g�v��0=z 	���kT�s�<V=��[:[�3�Y+�P	�v��dr���\�"�y���J��.01�~����C����I�q�@����џv���(�@� �6	<"�Z4y3�+R���8<��>���弥T�E����N��mP\ky!�(d���@��c���~j  �5���!d�Z�̝B.Ig�n��g܄l�#}&B�.����`�>V!�5�~R=���!2����m������Osf�^�!�ђ��rو�V0l��ك�T��G���]-)�Q�s7��:���ՀTP؆mͫ��Rdi�!X���[��Ƽ��N#2�Veg/�5 �vS�9/���e$��q@pB�k�ȅ`pW[���n��v ��R7��^AH<�:���ze)��؂a�PA��E�vK���z��Y���7�"(���%TB��#�#��,g��El@��W��#�˰薜7e ���@���5�=N��e�.Q��$����6�x�eWح���#Q ��nVO���eA��w;[��C����~
�'�2����dS�j����c?N�N�	IL�-Pӭ������>�؊�������8Ӱ=#h�׹Pd^&A�B{g8�`�^�=$U��r6���`m�}�8m<q3%A��e�������s�i��N�M��g�Q���Ȧ~�CY��t7`���$
�	���~i���O��,e>e�:ԩ�ݸ��3�H��$�|��1���a{�������B�����V?(�2�w��{ ���%�U0(����ұ�蕨!ʉY ���ǫ�#�� ���2�����4-���U�O�ny���lþ�&A�B��ƢPh^�����NmU{;��Q�q�: dД�����,g��s���{�bN�<�vAw�B(3���y��Z�0�ZR�e���b�TbZLs��˷VU:<>�+���6�~CX�WO@��v�'h�M�<2@����j��o�8�`�d���
�`������Us-�g<����BM����૛.�A|�!�3���%�]��(�O�:��$�����9�{4QХ"̂��(���W�,b^��3�Beځ�wI�_�B�z��V�[{PcD4�1��^�1���=a%���?� b�-��e�7�\���1W5˵�!yd�}���f^�|HN Ќ�?�b�X	7�x�[�e\��Fj�pw�ChP��`��i��Q�d �ß�X�c�8/[��Q��χb�
�cP��8��%��J��l���t��H�=Nk�Rc}_^\��o��s��v4Z69p�-����`#V����r�\FEA�0 l��:uzE�ᮦ�@��S\�}���]M+����}߈��e�(	x�ڃ5����|k����l8A8�:iΫU#�T��Ы"�(sB!����B�"����u��.!v(բ��m��;eo0�$>��y�p�vw	^+	p]/-A�=�-����4�X�`WE�+t
�*��ol{5�U;��Y:�^��f��d��$m5�PL0I����g�mD�e�+�?!%�x�D�~y���Zv�8�s�^����?ɇB3�̤^�,��By/�� ��<,�#��
ۧ'E�� �9?�?�`MHmG��s�����ב��ye�t�O��$iW�E ����ތ[���ZDU�B���/�����T[��..�����o�=�wZ�n����/�~{��8��ۇ�EK�<�-
���L�;}��G���d?N�I)�?��X�ޑ�v3nHT�[ y�@����~��߆�ޟ ����	o�|�7]�gV�b�ɣs��X/���ϑ��0�D�{��+��Z;?��m�y��Q=r=�dp��6�HZ�hM�U�\����N\81�(�`�L�l�`s틠��� ���� *�nCI�8�ǉ�F(�����E�х�+��l�i����� ���9gǍmE�>�!�WG�J��G���L�`�]�?���&�#�4m^���j����n��)�r��A�o�[�*p������'!T�H�qo��{;�u�Ý�r��BF�ܜ�t/��M���Ui�pL����9z�OK�73��D�!��F��SN�B�ܕ��s��R*���X�a��s]\~?��Q�V/t��o&>�E�N�D��1���<�O�
r�\}�-4`6�.e:>)��I���`��aĆt�c-	n8�Q�.͋�U�����3�Klu�_@&̂���3guL�+���-dV�I��o>��˂w�5Nv��t�ͧ4�~TlkZ��l�P^�y�ڧ?'|==���dBѶh��PnK:�.{E{��0� Ns����~ٝ͜��h9���'���&�-��D��p�1u �a��k���sq�f���6�tf$4�[��n>��͢��H0��Ou
������\�W���9��T��p$��tk������ޡ�0�@�	�L�1GM�z���<ꔔ�[��1YA�bc=M��M�+�u�k��a��)-)p0|y�@�b���sq��}|�X�� -y>w�0�߭�P�}��+m�xsob�)�f#�6E�{H���yο�o�z �ƌ=�$��܊��<z���D9��o	1�I΍�Teh['~�U72��"6���C�M#��267�J1�n����@u�*�EVFR���� #z��-��U�	Y�\��Vr���=�`[W4� �xb��Um�� 9h� *�ʁ&)q�~H-�a���V���gT���YSO���ot1��dbv�������|��Bz?L�!����w#O��f|��M�2��ʞ9ko�l��P;��>C̾\��_	�)��i�A% �������"�O�yS❟g���?=BSMW&D�-}�?gW�i��?����'�f݃�J$�*Q��}��X��\�� �U�{>{�xlpH�0T���i�_WW2=_TW8g՚���f�q�$�Dy�A�s�)Y�j���2��Jn>��ی��CDN�Z*q�L�m���	�<(�F��x;x��>);U�K��|�>�W��U���:� Uqwܯ �n|��r���]C�ES�M~׻�ϝ�3u¹�	@2S�����GK4G � ������ME`����+0�k�S�QC�D`����'	�f�~�L)�Sf�A�kV'U:�1�҈���Vp�n���Ӧ��F�̇qwv���Ҝ���1�@�(3|��=���z��5P<-MR��n4M�_2���~/n�9�J"5��f�֤i�ۡ��o�Ɩ�`��Ø�Q.���bQ�"�Ys�9�q6}�^�^(��SVG,��&�A��G�|�r{G����W#Q�x2�yq3�{*0�2]�s��w�����V���
&���z,�����/���
�Y�[�Zz$�9�����s�ȗO�+A��o�R_-��jH%����Li�ȵ ��2���|�4b��,�4�E6���j�|��̇����_R
d�bN��s|cI$t`1qBJ�U�)�g,:_��:��gM�r�Q*��օ���r9�/�n�zv�3e�����ő�|�̀��-�e����"0�s?0���_84�K���y��=�u�LRn��`�jI�T�qZV��k�-��� L�87�3f��7��R��܇�1��ђm�]�x����pn$@���l�ɬ|�ύT����U:-��NհU��ΆI=s���\if?�(�����bH^�x�改;w���&%nA<:k'Ni9ֲZ(+������\�c�gb@*ڞ����7^�K{|��x�E���iޜf�.)P?!�W���($^]L�Eğ$�p���NzW2!4���X��k��[�%N�թ�3�����_�>�e�����곩Ր�ۚ�4HM64���)/�#���%]�TC	1�kf���]w5�r=��*w�ﭴ���+�/� C�8'A0�O����Ԓ�Y���4�ӱ�����'z�2���"/��$M�c����![."��
�Re�����ZJƗ�)���B�(�a�6�B�zbZ-	x�~2�ƓG}$I�vz^���k*�XmA���o��!W�Ȼ����/�����[ -L���f���mz�/�}**�Qj�6�1!H���ҏq>fêAo��ӫ5�i�ssO��d׉k}$�ۗ���p�j��i�G�3�R�g�aE4r����Ƹ��E���؏�����/O��ME�Zԗ3�w�KoQ����5Ї2W�8#RDԚ��+�ǽ]��\6�q�����/���_i���ȤC����X��z�
�W�eq�{�'	���w��'{{�s2��%ɍ��Q���۶_c�`�R)��%\�V^d��N��V���%@E:��U	-�����q�_
�m����ԥ�Er��+D�?}�u�w�Ş%]rP�q�е���v�.o�q���D��W����1�nP�Z��K���'2��[׽�T�\w�QyZy5�
�ܓ�S2�����t�D	ďt��_�L���P� �U�|�q��'�c��:�ɵ�J���׸�O�:�A�R���:ǀ-Z��oR�L�_�Y2�Dn��K�T�Xxb4�)�b�9FM�z�qO�j��ھ�ˆ��s������wX�|.z3#a����	)ݲ��F��&)�r��v�%�>?M%�G+1`�H`�H",����ԛ�yqӫȍ���~��O���7�&���NSc	��@,Bm�hѫ��
����x|FY�"��@-h�l=k�_��EІ�C��W�m�B����;�p�[��X�9G�`�i]��?& ك�;{䫱�+	C�y��ʫ`(���8��D�0PmiC:V���#���B�*浉�_�G��-�.�5�S�����M�T:�s�cZ�$F|��ɵ��p�����l���x��z@zFj��č���bg�Y��[��S=쯤�:vyY65ıa��U�]-�F[W�ݤ})cG>�ъ���퇱���"Yy.t桘��������c��x�1.�#2�u�9��t� ?ܸṗ�\L��VB#XM�E�����҈�)`�~������j�ùs�����4�d����w7�Z����qb=�*a=�qZ[���F%���;��Ì�ł�Sbab�����h��o���n����r���G	ʦ�AA�b\���F��p1Q��'�c�c�i.����������y�uu���J���\�z�@����wk��.��d��H�Ź'�n�����
�k6��sjw	���8���	'�a$��+�^�
^�2�t���A!U�TY���y|�5@O5
T�Ʉ���*���+���<?��NF���2��a�t��ߥ�xUe+>���%g̿~�j�ŢV���DY^�����)��.�6-l6����t�Ъu�#��}�E&�L�GN>#�!�T��8�C(y%l���0�H�L^�ck�>�_C��K�1� ��g�!'�k�����%��a�9�� ��O5�8夵�ۓ�m��]?�n��f�ں�hq~͵clc�(�����[}lc�-J��s1-��.��O)���t�T�N��J��;��$
ฤ�jyu����Og�S�NF�EL�,��h_�*t*�06*CH�����h{�	��Eur���i:��p�:+>Lj|��
aWM���1���6";��<4$LǂT��~�2���듢.hr����DI����)�gLi�qf��e*S/4&
�V>Lr�&�K�h������z7b��"0�^;y.J��P�k��N+���o���R�g�y�i*_zE�� }���a���EX����~��㫓 '�`n{%3���o Q� �y|t|Q�A>(�Zk��A�:�B'B�GdZ&��W�;��E���rh~������|��	�����ep.��dq�}�����E&��s4�꥚�<7�(LN��1���}��= W`���|e�[%H�4z�-R�wڭO���p g�VH��-�t�~k��������s:���,�SHs�S�`�������|B���>����-]_I���-qI:��9����`�N�l�9���G�9wۢ��,�J��Ɇ{�3�_�(�?[���i��ZR���.V9[�L��ʮ6��A�k�V��ǢYľ)�N ��]�����y�$&��0ߴ�1P8��@c�a���ZM�reV�����W��Ci�94����^�zK�|��	Sa��5֕\ u�%����X<o`I�:E��'�+h��g�d�ic��h����?�~�v�Ĝ=	�����#�!����)��W��Y'gc�.��pv�d�@̰�y!z��R~�L%5��'��1��C'? xόs�l��=&|NR�D�@�8���7�z,`���h�i�)�[�ٓ��As�+�w�7���7�8]��*��Z7'ĶC� v�	���x���������$� ��5�е�����f�wQ�ڠ�H�z G͂UZ�����Tz�U�����z�$�dk��wC:Zl��R���.��uӊuuPuBVw�c��[tl4�Nfz�����[j��$�L�3�P���{t؇;��+f<��<��P%y����2^E��ەx�lSļ��OT0�P�-:��e��,7w�n��4Bz��	�����DZ��WZ5�5��8����-T�❔�I�L����+q�+y��!L��9����2�i�8�lVV��| ��i:�[#������Ep�C,T좲���
M�I.f�	��H$��&!6��Sp�L�p�0ei��p24˴��Ar���e��	h�k��� i�'�0����m���ϯQ'"Z��&�����ѹ\"J�f�_|��<�a�����1��Ys&�t�+m@q=ߟ����	N��X����f�G6g<�xSym_2�.{��v�H��r�������R��x�����uJ;�01�m~��zi6�U�*ݝK����͇.�1�&��>��0��܎� ���w9' �no��:Y3����ڵ���å�5&���~�0����F��T��i!@�~G���ވ���Ŗ~��܏�4;��+��FOG�K]��Cf�^W�Pw;\�H�(����yDd1�\��� 5|N�P�����$l�&Wl��o�=P��\|6	+��PZ�[��4���9i�g3+V
J]��C�$t��EF�Α�Y�GS���66���j_�U�o�-�ekik ��bH4%M����|�C�'�t@��{�WC>����е2T̖!a��� /�_Y�Q�0�e���x�%�9�A
��$���G6`��5��`� Ɵ�zmz���mL
c��z+�����3�+{D���ǂ��
Nz~yEQ���e"݌� �$*CT"9h�Q#o��T@�Qy�$�&�ѧ�Yq�ta�^�ۭ8/�5F0�~&A_�2�\�7�	LA�-�l�o^�s�W?PѢr�
ب���0�8�0L{��y��Y�����p�>��)���d�W#͢����xہ �/����T���q�?�hz��:�#����NZ��ݫE�_�{r�(�ԣ��z<^gO�� ��p��z�ج�>�5e���M+��V)�{A5�8�	�qWǦ<��jH�Eq�K8~�7����}�3���&��7 +�X�-Z�CS��w���,���?j"�}���ǆ����54l�aP�Pb�|T���[uy�W�-�Iz�ZЪBBG�Yv���yա�ʇ,�8��Hzb�&��bCkS=�2���ڑ��D�:���y��3j�y=[���j*�X*��ނ+x�}���'�ܡ�#��RU1lz���} L�6��$�As9�����DYMs���&[���������sS�<�U|U�����h5.�<z;9`lL�S=,\���     ��
����z ����
���g�    YZ