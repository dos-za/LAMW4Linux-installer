#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2251700966"
MD5="828498abc5840a697102610a24eb9baf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25672"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Wed Dec 29 01:19:20 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���d] �}��1Dd]����P�t�D�#�M�R���	�����{��a���!�=6��<?�g�\�a��qGq�&��kF�� ���$7��V16�I��N�ɐCs&�)�wT�n�~T�9�Y1_Œ@)����tY���J�3��0X���rO�;2�^�J��̢�3���ó��1P���Ѝ���Z�"9\�*i�����x�/x+�T3���1�:=��:� ՘^�O^���6�XS/��xv�����7p�����Y�(o��t-�̢1�:�T_�
��RZIy�h�?�w�w�����ZК����1w���f� �T�������9�"��q6�a�C���� �tR�/�'���W@,��&��QC��!�5��Q��W'���c�e`rC�9c�n=ーk�l�ݾ���O�拐�;SE�L<'<�J�9�e�H���5��I�Sc-5�4����ԓ=�x\g�X�IM��S��P^�����U��
�:~ve~�nހ�Ȗcz�ߣ�^Ovx����~a��w����EN)#�5*����v�'n� nTH��Cqf�z����E�#��G�1�3��$a�ǲw��)�n~�~Ԁ��mb��G��9R��&�k�ex�`9^F̆�^�;��fb�E�T����c�Z
gR¢���叁�|�_�xfj9J�޿$�R�����/��y���)}����u�LN.�y?'�w84y ��hoGs#|4��v��pcճun.��ɺ�w_�\$���&[��o1;��`���:՗B�Ҳ�j~�@/���=��R���I�hw��KӰ��w{r\>:t���P2'�/s4GT;�5��t�z$��j�����TڬȂ�5\k�K�>P�G��H�KU���:���tA_��F�0�m���}ò��.f0�pJ�_���2�w`�C�FtvX��Bj��T��6!�
�˾E#�v��3^��nz��z.ҽ$����~�ü]}����Y��Y�=��1h�Bzh�Ҹ@��0�����SHX*㩓)>$����Ր���f�S��:�W)Gx�9�����#5�V ����!��-$�Xs�kK!�w����TQWw�zO��4��q��&��h�_���7�˷ڒ�*Cb]<�O}�&}r6t�f�%�M�#0�u`$������5����NZ��8�� ��/"��-Z��ys�i����aX1S��x��#�^$���*X��Б��i�oS�霔��	�������W���*hY������s�B8��J�sqt�9���K؉g�$L-���4/�g�{N����!k����̗'�Y��A��(!�]S��u�|<�ÂB���B���e`��!��⥄�ۇj|���eࣆHO*��<�w�_'��
ո�NYcj���Y��gg&�# �(�0#��$�~[nǘL%����>��k[��G��A1Q4˃�)X�i(?4��r���4=��2w�!��@,�s�.�3�+]��qoB�|Hx{4X��;v���]�|}���ť2�Ž+>�/!kuz�R'�?�����{�ϛz�p�	��I��I4�"��}��n���ҟ/�J�c��=�dF���^~<���Ѓ��f�`�Y�L��s�F�F�if�����]4�$H��t�e��
:��MXŁ0X�L:��d�)�q�+������2�)ʂ�.'���q��H��m�)W�����f��u{�ٜ����-[y:���~O3�4u\a�����gD��h�
ڋA,�=XW�O
���t`��?�`�Ξ>I(���(*EH���3��-�V}�����+��瓲�]�^��sN���+�Q�Ѽt�mnqZ�n� �w�k�����Z�]밐Og��!r�Җ��P%�A��aY��� ҧL�ã4R�>��H(u�eu�0�-G"�����e�E�Yp��o��M;��u�}	q#дo��(CXv̮ 	�&��U/�:��*�0�#r�w�<K���!�}Էݎ"A!�s6*@��c�ot�IdKߪ�h�n��]{%��#��g	����'Y����w�<�(�����?� �H�ֈ,���R�e [o������X�8R���@��)D���HJԑ]�l�/60�/�������{r¦�������
��5�p;N:e���V�v�Q���#�<�t�Wm�;�����L�0��dV�/�����u6pWS�Z��U���A�E\rS�nI./�3���b��*xK}A���\>�%T�n&����~���_O£
cS�sX6Emm���0|�`�o���1���BFAI)Z�����.������dיǨ�A�� �}m4}�M���ۤ�r�n��_�SB`�m=���2_D�0E�7Ee�Xx�L�فy��h������`��Ժ�z�Y�.�kѠ�PO�h4��G5������N�4��S��m46=�G�j�b��0��g�����/X����u�;P���xtW�/��0C �D�M�[�.ax.�"��Y9�Q	hT4�ˆR�e���]7���m�R3)0?o*~[N�u��Ǝ�<�X����iϡ�� ����dgwu+1�A,�jT�Sե�v	�#�osH�uc�
=0�Y@�~s�y U��K��f�+TXs��x2	xg_:�
s5��#�γ��X]�M3Ik	UY�,W)��|���
|�K�E�ݸ$��&6�ך8�Ǩ@?Hq{�xFPFC�j���P���>|��2tVk�M�t��"�WXNC74ƮH)�� ��7�!ҋ��r�ym�o$8��sr������71x�l]�N2��o�J���l������Zm�w.�A�R	p�>�U&���`W�20F��Mf	�;�N���tx���1p�@�m+���x�����}���<��m{�&hkW8	oS���5��n֘6/�����C	���2Ӷ\��kz6V�-e�ܝ��IO��:,՞����S��P��^��q��d*��:tg^�+^�E!�x�R��Kc��Q�L���H�/l��"��]��AB���]���FJ�Kh�Hh\�t���Dˁ���Y��̆p��V��N:˳�*M3�ѧ��|A!��@a�-1�[�\�?����+[GfT6�?��BB5	ߖ�.O�쑩�����p
բ^�6{�?D�z �א���ک�P�[�(�x�.K?���C 
�^PtR��*\Ͻ������P6��*�&$:�{�b/R�E㱉���q���Li�u�S)����Z�8�J��+ˋp�Y�kL��ڹ�گ�o�Ҥp�	o��{d2� ��t�d���wI	�k�ߍ��`�4��1W�Lf��*�����^D<��?cǌ5 H�ɉ~8��IZi5�r�dg��6�<V�|��wCŸ�+���)6���r &*�i�dCa콍�~YɌ��;���.�e'�'�V��:-IR/ �4g=8q�:u�.]��XRڣ��
Y��8����	}�w.-.h��4�*ńH��6�����7��be��_���-�O�O��WY/�TJpftP�Hy )�08?��X�L�V�FY��$������P��+�����ꉷ�'�c�H���8����wta���r+#��lS�28z�FE^�)'86jE���b�yd���L��E�bF���#���t�2|o�����z�PF��Ɍ�@�y�O\�U���umvs�Ś�}�5y�,1���a5�TFk���F��j�6�Tr�1n������l#��Z�r�������|�#ow�2�\��`�u�Ԟ�=s�2�j���n�JW��y8��@�䘰�h(��=8\w�W�Y�H$'���HnQZ+�y��:-�8��e}B�2� dr�gL�%:�������.���}�����ᐺz�6����s�p���~�Q��׈�u�g<���c����Gf�x�v:kj�3r�����}Hr��D�@7��\��F<�^�2�s')6�&���:��M��4�MI�ă1̶,W7^Z� �#�t��q�`�C�=�G7d9H�[���̦ȏP�y���w٨�\��v���>^(��}���\T<c���J�~w=��N���3���dw�"�H���U� ye�T��Y ��8����G~&���/E�Qh�f��G�q�HUǱ�ʹ�:��Hm{kLHlPu���뮱^�1aVEq���k5dv�E�3��Hb_��7�ėH3Y�]�d8�5i�ٍ ZCZKďxI_�a������ok�ʜ�i�Ư�z�ht��W#�Y3{�QH�F��cN�����������d���ӣп�]�\���=z�N̏��q%�)P���4�T��K#���a����ʃi�AC�	'=��Q����6S��9�+�F(7`�]���������>�Ϛ���l��{fH#+�U��ۿ�Ѹ����kӐ9r@	!�k�:Ϩ��ed4�{����+��cϳ�~(�¡Q�m���1������� �^N��>h�-���e��X��;�\sâeY�L��6�&e��XՌ۟��P0���n���*ܶC���Bj�R���q���:5�J���6�d�*�z�^[�A�ɢ�u�Ee~-��}i�]�2#�3]�(3#�s�}�R$@�j�/:��ƫU,+n������eB����ۮC��;H10�v�������aV�7)��ؚt�E���V�@۴���H��u�/�S��^h6�Q���Ņz3��r� �%�Q��p��1�)z�|ܛ�٣��#��c�YՔs��c��	��.?��d^��Ֆ�)���kP{f?�m�YQ��k+��}���a��oB�4l�l�[���Ab�V�h����`��<�	���vi\�wȕ�5]	8����]��io�k��RD6�ӹ5� ����0�	ۤ�����l�#Ƒz����7!
���q�K�0:J�!s���F4,�]u�ه7���Ϗ=�ɲ����0K��8�<��4���˽��T�FM5��
�����b"���&�7_�Ρ�xm�薠И.V��?�wKQ�Qeo�Đ�=`C覡ʴ���4Q4V�be����<�߶}KH����Y� ��T���_C@���"b�s@}-$  �4	=���HS��#��tm0;0�ɝ�Xn���qq@�K 6H������Z�{@��ê�	<k�+nHu�C5���8.��ʩ�"��RT�Z4,'�-�)�b��V	�sɞ��(_�D]7���3S���H2BЙ[���2�yθ��,D$�Ւڵ������'���e�Ǻ��K(U���G��{�`Y�?����1�YW������%_,���98N�b�s���,��v����0�3�R��`Ј�ep{|bF5p���%��{ ��|2�O��=Rwj?
#d���1��$��O�>Wq�|�5��l'�J��}΃c,,LK�ݼp�iW::�8�h���Qԡ��Oq���������S�E�Zǎ��W��x1��s����n��jc>ޒZ7N�Hjm [�����0s�A�d=z�����yySb�n��X��^/��p�iw�R���m��Ӿ�Z�� �p�D)9>m�ka�(jHP7�!U�过�-�Qg����t%�����<M���ھ����f�L��Z�� �P�����L3�B;�;%�գ�u	k�p�sg��m��ʇ�!O�bmH�i�T��������W�h����y����S��v8�U3��i+y՜�Uj&����F�a�NF$�b�`uԲ�M@ԱF&��\a�h{С��l9Х��Ȋ��טj���(�Y��+jC�e��T=�ѭ��+;��v�^������PDk~p�]C8��A�� ;����E�~����zՙ����u�T�.S�eO7aM���iA�U ���%� ���3�K�q�[��0����l����ʡԷ�$�8�c��X���������_���%Ĳ�� +���#!��h���4Sэg��n��|ܒ6�'8W�58u}5hIF��"�A`���(֋9?@9�O�@q'�k�7���`�_��d|�@�6M;���Pwp��A�N���b߿!t�9����'�޼~|�5����(��z����^�Gg�?(6���n��0��b����d�x�mt��yh����O�,��B�A�mPq�{�(H�qC{]@�0 ���؄,�V��"UK2)=���w�˟��+�5���o4��uR�FN؄jm�d!����H�"p�+ �=[�#��?I��,F]rjK#����&�H��-h;��EC��"
�i34o�I��`�S��Z���]�|	<	<J=~_�f��Q�6�s�E_Is��X;WV\�EH�'�k�����8V�x�q�PӼ������JKLAm��P�����BeM\��٧��Q�US��yW�̗�7�
f�G�e.H�� ����
&<Ԝ��7J4�9F!��!�:�V��1�઩5���U#��6�$VD����F� �尟����G�a0;P�Ą�VTR<a�zW����� �M�O�{�3N���>����(�ìުV��T�������N&2y�ؘ&<��6r��ܔ�~hwh�dDގ1��/IU)��;���P��뙔V�c���u�ĳD��@�����Ew�WvY�Z06&j�q�0$��7k@M�����(@6�gWW�r���Q�%�mU%��}���G��#����h���k�ۇܺ��&��
���Pe}�5x���XC��E�
���f@$P�	�����2�I8���xEH����q�G���P�1D|�nfx�x_ �� ��Bb�Q��� ������H���":06Qlш���E���ފ`)�>��-�`���'2��Z&�/�n���l�����̷E�ɽ�����xs���Gg�m ݑv��D�<*?��Ԧͺ�L`n��G_"���ROC���$�J���H�`�0����T�(���Gh[k}�T^w� �Lʤ(P�wh������e^�Ö�b1އ�ڏw��� �[��#^�<P�\({v4^�����6=I.Ǚ��p�੊��s�䕟�ds[I{�ʛ���G���XJ,�X��ty@P=."��O:`��LC�l�RNL���0�� ���(�Zh��W�K&L��V�K�2��l%e��-�h�Xy\����9}L$X����_V �k�7�QT�fX��B}B`8�D�}�S2NzE�3=�����TL$Un������N�!��%}�)8�ӑ��������1�
�QdG3&�"����M��tv{�IF|��J������V3dI�OK�Ӵ>�W9��d���jjr�*��'z���R*��xx��� �J�3���0��'gd��e"D��k��&���3��[�F�4��)�>�DF:}K���pt`�n�˜��xL��Aő+�[�>
��_l�����& VvU�էĿ�'d�m/(����V��T�]���~�
��ѓ>:���|e�5��frEnI��U�><<Bi�'����B�Z� SDQ�w��C�'n��7�Z�;�����j��$4�n��+��/�݁���Pg�>024y��I�y'	��ap;~��P�\�Z`A�~)�X�gRΕ�z���#7���X���h]=��q��X��~�i����Aq�ŢR5�����նY�������ufuo똚�"Fb�6a�A��l*hx�p�:K~�A��ʹ38~]+��H�b�yho�m1��':�ָP<�ߎt�'2Xe�x��{�E|�G*�9:z�h����n�~�(��I*�G:ؔ?m8���M�'� %�8�4Obl�i`
��;��e�"y�Vi�����.R᝼�-�x�(�;T^)�*�A�՟�\"���Z��mcjӇ��]^��E���=?Q�s�u�n� C����F�P	".��hs�|�(�������w҂�c*4t�o�17(�I-� S�s_}���Ɖ��i\|$��r��<����U��9e���+�M=-i�� CX�����p���#��;�e����<n]W�����,��+W��K��g%��M}�(\�������i]���I����ഘٍe $�����[d3���Dmr�+����̲?���DӍr��<�(�w�qn�*�]��G �z�z�����7�+ר �f��]������e���寡�oVږ��
m�-�I�tҽng�
.�srG޶��@��Bq�tW�n�������Z}���͢7��S�G��˕|�'��řuH�pT�%�=ڹ6h�׽�-��:ڛ4�<Q-�L]��2�L�j�
˅J�z������<����E�̘��!�ӎ���+%�����@ �؃zMW<&�߽Gx�(�L�)�3c��x	��mr���8�i2�1���2��]�#�2	��t#�L_t3��6�pЁΧѡ}9�����Ӷ%'�:��Ğ�	�������8�
	�w�X�-�?V����Q�d�y��4%<	]-m��c�ʋ`��nK�N�e���aF��7J	��Dd&��"k�|�����VpO���H2�#�`OΜ����f`�foy�{cqcZ.��P|^/\]���	�r��BSӺ>���s��P}6��c��%�O�B}n}1 {�E� q~�^�k�k&I�LCCHg���lkugI-�hT,���{��a7-�O�����F$^^��/�e]�F4�#i����"6P��"]��΅7��%��� ��ʲ(>�%��j��f؊��gVͻ[6�`�`B[%�2��\{K9�s�  ��ow{�y�g�=3�z7���&�'��h�6�#�RoLE�>�Ge����LG���m���?�2�s�ܓ�����
x���""'V�^�&se�P.3�=�U���a���� a����{�x���ʹ'�����۝�9�TJcPi�xr���$ƥp��v���΀1ʙ6�Ek����y� PfQ�kyhn�HC�zڜ$��@Ω��&�+��.�e�U%���,�-xkNX��WW��{�>�m�-��`�����y!#�+��H��$�`>6!~3L�vt�/��3+��l]�����g��r �΅e,�։��5��7��0�<)"����x�K3�d���s��q� Ƶ_�Y����n�>j)Vq���nh�R�H��x��������v�b��FS2����z��/�d�-�J�d=nj(�����������LS�!��9kj��M�h�x��H������9�y�r]Qu`�t�@�������BmL�E���X��P%$Umٞ�~`Y�c�nM�^���\%<��~ZENX���V
	���T6�:�h�߮۝0~�+��jMeK�e��lՑ/y���u�1�����_��Zz��;�J8�:$�PR ��{���Ͻ(��A��e�l�bȪ��K�vO��I�/{ˍzn}׬��g�d{�˂�O8�~p>��k"[�$=)���H[��Vݨ,K�qMm>��#�&����J��h���{vg�fy���pj�kH��_A4,]F�p����B��5�Hq��a)Le�ꤟE�����>�HĮ��D݌/6���
��<���˞�?"����qN�3�y��[�k��H;�Q�>^���ks��.Tf��	@`�lu����m�4�(w�l[���H-hAW)�]���jZJ��y<��.�Ο�����5U���'�0�\�۳�u�-IZ�px�}~W�I&� ��G�zvQ1g����FK��y~���
,qW�}�s����i���B7�|>D�P�!��~RFsp��YJ�_�s閒���X��y@i_��K���M`����c>��{ڋq�~�NÖa"��q��1������͍��]��)�z�a8�v<%������U�����F\:)�����`= �^��Q�ɵ�>�RsS���ۃW� $�o^W��2]ʩ.~O���l���H 
�Bf��s�V^2��S���S �?�S���@2���1�3�kGL�'\�D������S�,�WO��y�w�1��$N"�v�L}\eSN����Z]��{7V)I&�i�_�6��R#5~����UV-�c���}��c��Y�J��S8V�;��z�d�<�`�P���	۠�cf�fce6�GBB�z%O����*�a�ʖL�|���\{���8�y��, �l� ��w߭�����=��*K�yI��������ߘ������p}~!��H=���}��^g`�0� w~�(O�fn��;%��ӗ�=5m%'���#���ߦ����\3C��������!��G�3`�On���ˍ�a9��{6`����#��M<(�7($���?���z�FPn!�r�2ә*�6���2�oѸ���a����3�EÅݒL�h�ME��n�e~�F>�ר�
Q�>b��$�-�˒7�P,����	s��R�Q�%?���(h�8bR'����ZS���|�!��5GdMN��;@We����0�h�y}?>���#��^�8E�XK�ɫ��%�	wuPc��,)b�&	?Ć%"
ٽ��A✈�o�]��E P��cQ�O���eZ�4e5���K��Q`�$�\�q�W��NrgP����u<��Z~�c0Q<'"(2��%u��m��ܗ|�9��'eA���R�6��H��RP�k�#d3!��.����E�k�}��&	��U �+k�O�	޲se�r��&��!�F��FK�G��%�g��g�w�k�!�C��cJ�����[��� ����!�����4'̳Q�NZ�f�L�R��j�	h�1��'�?Ԩ	@����MjGSN��lȽ�z:��>?B�9����r��ܩ���x��\�4�r�":޸���X*�ڏ����֠�a3\�1�V��P��ܿ�<�<��{\M�VՒi;�U����f[�U�_$���ˮ�Y�ՠ�j&��q��^'��+SB��]�@��#�R��K���h��m�2#��W�����'T����]ɨN�,�g�~%�'A�.Ќ�o1�-��Ɗ�E�.�ʴaޯ��e��lg.�qV����U���BK�>�X�.2��B�,�G���dO�6�����x-�a9Dd���wR��=�f[Z���X�_c��Ŗ�w[����l�.v�u�����i��D�0�br��F����C����|���꾏�N�z���r��_�I����
��}��du>Q뵦�-BD��9=��Z�׷s�`1m��䱴MnV'�kW�W�G,���ی����O-t��P��M[���0��T�Q�|y	z1��+��s�)�ENC��kĆ�gW���|R� &�=�X����3h6��	��h{��C��_�\��U"񏳔��:�xUFk�[iw��~D���,��e?/���PЎ}�UR�m�rcҝ}�ۉi�q��!y�c�Z*�K\����W5c����
��h{2]��`�XK鋡�01PG���#t^���.����"��6)!#(�vt�ti�u�6��������i��k�_۱�B��3i:@�=��8 ��Ů��Gj�Ə3�D������;�@!9`*D�lE�k%�]�_����D�"��
�;�%`�kV�^�r'32��=��}6���H�Bw���h=���t��Jg�*F]�py#鋖�L��`f�&�~+�ݬ���KJ�cXk���RJ>wI4!н2��z�ӛ/�i�X��S��30����Q�%�zi_�r�$h�y-�ѭ�lF�s�dW�O*ds|����~)�Ѱ����\��`���J�
����k��ZP"aŚ4�G&�φ�ĭr�t���<�<��m��� q�.�(/'.�ۍ��2r���IW�L��YNX{뀅����P]�M��h��c�&*�y�Fy�F��Ŕ0���y22��=;4�M_�F��I�pk�-�����ؕ�N��W/:@�:��[� ��g�d�R��~O���O[Hl�#������b��8Yz9�`J(*@�N����z�^b]�v\SFݢ�m4s�L6��;җ�[��Sx�c�+���� 0@�fH�m?���*b�~�����X���������A5M+og�D,b�ޑ�)�j�r����!����5;��6�"01���g�)^
�iƎ���0`���K���'�s���q�Ml5��#�b�ч^�a�YH8%Ju�A��(�^Rr��7+�|U�TK䙳�"Lg��c�D�R͏�=�og��Ԇ��|j�m�����ܿ�O�w�	�v������hˮ��E�b3ב¥�:�BG+��g猬�hJ�x6�t��@��E�L�(�><�_.�V��V>��� �ES�X�FC��_a�:���n��^�����<��F�[�R�R��k�[�7�H"sCH��&l}�tI�����O'QS���9`�1��9��\���ШU>Eph���q�f�7t����)��2}���8��0�����ِ�T�i����x%(
|�DO�F�R&�`������b�d�������m��rl�H + �ڕ����ҡ���y7�l+5��U�� �ſ�;�N�u�ش\�f_��RVt���̔_����4��5�ƽ&'�!���.��s̞�D��š��=���qV���k{�	��cgK�r��������Hr�O���1�WpJ�:4�dt���Cn�z6��î�Ʃ!�
,a��7_���a.X^/�,T�+����'��W��#�����W츗��K[I���U���X&��#2�HDB�i\�\ж��в�j�2��A�Q[]=r_Pn��4�n��r��_�&��=��7�n�������#Xcҡ���r��Q�u�����*���5��x�1>�	/�˵F�;5ށ�y�\A���#�"�}BIn��l��+>g��\�A&�G�zsU�R�
D,0�D��K���8�(kO�@y1#����Z�,+�4y��(�r�<H��~,�։�F�m]ۻ �F8J2�+o�1�ɜnu0��`N���VO���Uw��]� �:]�&G{�@�Ï��5��[�d^3�V��U�(cg����x�XqQ�y��
V9pZ�gW~�$�ἣQ8���T�pfH���f}��S�����ֱ���*?��i� �ҶrF�n�T�@����KܐQL�HY8��	��kP��+�ѿ��,�K�e���W8���D3_\��9c�4&�����Pб�f�Y����Ia�����L(Hu��-�-j�Ƕ��0lOh�@���i�qHl;o(��*������7�E�	�h8�I<����~���w��.��ֲ�Osb^{@H遟oF7�W�`��+�ɲ
��/`U7�F��$�����W!B���o���`BK�[j�
h<�7���¿�%s~�C�Gg0��+��mG��(���2C����_Ұ�mSM��u�h�ur� ����ޕ�tC�::�(���t'��iW����Ą����)��S��Me@���Kݺ�h�J�����m$�{�����U��o�X�n����B�쥤d����o��Ɍ^���=u�O�*Db��S�g��(��a���
��w�=����.L���S��"���/��L� ��u|P4!4S7��CVhE��T���ɪ��뺰Tڈ�+�V �f,���:{���/����ML�#",�B,�	I=��X��1�Y��d�`+�^4M}c�-\���*��:t�������sC�5��{�ּ}��4�q��l�AQ�>H������b�w���!��F��>D�rh���������
��U��ٓ�]5V�p-�B(W�qJ�
3�<�i�x�IQr��{Tf�UR�`f�,o-��I����0a8͏�yr�#@�" I��[��W��7���!���C��w�B9��ӱ��نA�'����8M������}2p�D�C��sI;��>�X�[��)<�  "<��U�U�?Ypyʣwq}�p�5�SW��u�r��*+��i�+��3Y,@�E�'���N���6�њ�B������/a잪^�8s!��C�,G�P�J��)�ے)�ě��|o�m���~�?$+*Dx9c����[7���*���rd��Q�Γ7�O���f������1s��*��
�S�N�}YI*�����`�p���X[=�B��F�f����@�P��I��p�>�R�鼢R�o�9��	�#�(�;����$ɿc�:�8�!G&m᯸܁����qWQ�;�IkQKDh��W��T�qq�0G�e�WQ�G	A|�?�<X���SI�\>;T^�=r|�;�&יI֫�a���`u�P�L.��L��c)���6>iClw��{�Nk.�b�f�fD�#�ά*��M ۷����N�� ����M~7�7��Nu��n��K�	��D㢢0"���s�m�܏�vVm;Q%��e��
�5e<��%����&�\�ʺw���+����+=�犬�L�\��ɤ#T�c�%��1�ܔYsH��j�U������W>��A?u���9f�=�S,��p���ww���j���?������U�EᗣUm������t��5$��&�B�@a?�eh�{u?��?V�%��V�v�܇��`��a>�O�-�F�s��U�Ri��+D��	­�"��!��U�jk�6vz{�Fլ�~(�����gZ:�yϥ�pw����K�-�+�&]�� �?|TY&� ��1#��=���t{\��'�v���I�.�<��A�7��.Q����oa7:^-^;Дb���
��bIry@����ć�3n�xwv�j�*!W�7��{r�A�����*�Ì=D��;g���˼�V��A��Ҏܧ���'vq�=�	3x��'�L���8�&��+�),�"v���Y�(7��mZ���OG��29M�E���['���@�' �[�cXjVf1���h�İC�lÇ*�W�`��4ڳ�e�6�?�?�H���=`����m�[��F��6`dh�A�chF�=���3:�k�iI%ͱb�8��:y`F����@��\'����=�B\Q���7�,Ⱦ��۟�h��j��?�*�0��w䕳ƕ7�)MB`8�OJ��j6F��I��7r��V_t���V��H,�x�*ٹ|	1I�Ǥq�C�^6P���K��&@)\.�)z 0+ӆ�o�,�]&Rp:��d �9a���V�:�- �������m?-����xԕ��;�^� b���&Vy�؜�j��Ty�`�8����V�K�x=�I�J��"!@.6�~��k[?H�̽ߪu+M,���SP�&����0$�)���e ���k��f��
L���%u�B.X-齎ya�#���҄��{mt���n�����������)�('_���$�ڳS!�
�iz���nB�#p�n�ތ9Fj�ї�ޮ��+�+�+ ~����Y�%�Bi���[��q���k�]�B�E�R�KAq�{\�e�,i���`Q�11)F(H�M�M�o�m�4���SJUӁp�ս�s���U�[�ry��o%�kO�A��(K�%���W������s<�A
�c�4A��z[y���iBC
%!�;���@�T[�Ȭ��	���d��/����҆vjT:� _��������)9@Q�J�]�������ʭ:�E��?ʫG2�`[f�z��o�	lU~&�w�;�^R�5
��̙�U"L��E�A�A
��ɐ_2*Y����w6�}���x�o/?����[�Hus��"�����ؖ�G8�zz���^�}�"��2<�E
���!L�;1���oį`�Ɯ�~*�w1I�G� ��5V���A9A4a�V���Nl �
~��8iv�t�4n�.j�-����5n�|�D�+ƭo!��>�y��
nZ�" ��P����X�1��%k�vX�"|�p��2.�C0ϵ-m�/���ۊ�����x�Q�E�*=&�S0�-p��5��Q�';i�Z�,i����t����*�/s �ח4��	�P�F������;�/�R�\�2J�%�fp$G��7�JnK��|���%q�)ԁC��Ob��`��6�K���WC�]q�X�n��r����p1V@7���OR ��}*�&kLh4ȃ�t�;�I�L9?1�)��R7��(N���ᶤS�80ztm��6E�����i�Zj��}�P����"b-��t䨋�*9��v��,��b��Bj[qr�x�XB�D.p�;�b��
O�n)qs�(D$(�����{c�h�Ȳ�*�+BG��� p�?�$O�%z�&KT��-\,��Us�KRI���x��NQR��ҡ$� v�t�/�>�L��l��톘���Ӳ����Xe�$V�݉�J蓐�4���=c5׆x�z*�Ţ[��n1��|l�s��S���]�>k]Nt�C9��}6�]�U�S��Tj�Y�6��<�4�"F���4Q_qN����>Mh�װ'�ˆ;iUߛS��Z^�N�
ft��e/�X��;7���:�i*�i�bN$�GAn���ؖ���ݜ���Y�<~�E�'ɤk���$���h
��������pLbч_�5d����囶B�����2�58Pt�F�"�Zٜ�D������_V�B�!3D�0^�D�������{�x�	7��j���^H#��x_{��$��_�k-��,U��pQ�rV��5�e{�̐m�+�-���g�ɜs���Dߤľ�$b����w�*,Q�GY��y��#����	��|�] aB�&���A-������y	0��Z��ך$!�#K8v+g��9�
�������;�פ�^ZgϦhf�j���<�N�r���frV-+ǆ*h�v�Ʋ&��\�+H�*ct�;S[u���fB(�'^M����x�Fʦ�2�/MI$ �o>3�0�����(~^x�� �#�5����YV��� ���*��\`Xa�twL^�3�܇T�8&�rd���f���<�|���!"<�*֨х�B���02q�Ռ ��u�T~�A�&��R�H�b=Y�~����l�+�r n�-�V��x4�⡙���H�L'%���Tj� >y�C��t"J�����@�QL�]��d+oV���Ȧ*�=��>$��$uPO�oQp��=�v��UP����H���iv�:/��tF.�0|��23�����䖍�р�E%@���^�.ul���5x�-0�c�^�釭�]��e���":��Q\+�WR&��pl������h"-�`��/�ie3�L$��^Xu��j�٠��y��"Oxo.���w'������w!�_�uz4P�o��(��2���`GR�*s�.#�6�BZ���^M���Dm薼/Vc�e�z�S�0�K�zM�µ��l�uM�9�d~-qX6tacW��f�c!#�9Q�)�����EPG_��[yC�]��u1c~�>�>��JX�=AG�����-�ܗ�"*�-��VSI����^�kQ\a.T�ⒿɴI;d��3W�jr~�E�DU9����@�Vq�V�|m��e�V9u�����ui	U�Ռ��='�J��Z�x����g�q���D�RE�5�xX���J���#;rS:�l�b��ɀ;z��J{��ѷZ?%�p^��o�
��E�������~$�x��,{[V�����c] D�A2�J>��/�,��sBt�D3ug��p ����V�%�I��G��E��������a���̓�ִ�iz������8�q���Ѣ͉��|����*��բ��A)�������W�j5l���a���MO�~Ui�Y"Ս�߲66������w~�*����{�@��|#	8n�A甈���K��{�����cJ/��m�NV}�r3�FU^4C(%-@E�H�J?��j���$5�i2�9<�� i���!}�7���d�*��\�Ͽ�η̡H���5����B�����7��{R�����J���(S�`�+���
�.�$���.G������f�Za\�O֯�m]V�95X����ѥ�7�S������S��`�R�d���ђ�6�*�����ˬ��',��g�9��4ú��ۛ	G��ff���3^��*�����ÅAv��Ϩ�&\����4��*xfB�������a�
��e*���S�[c������ıu9hc���grV��������|=�1��'_ȶŮ�2�L����eDU��D�=��������o���>W?y�SV#'�����.G�7�QN�kL�L>Jĵ�E+�6�`'f�E�[V3k�|)���״���{��]p `Y@D�2;G"�Z���_���C�l�7�Je�>��
�+���:l+ϳné�^�.���J��a��*6;/�9؜�!��&K`��'�	� �!�O2NJr���V�ـ\����v{Ѯ�ǓaZ�S���}�fS��F�$5�c�<�����sٝ�ő�Ԍ�ʞd8��K�5o�ʗ�|�p� �V:ڍ�����y|���-J��s��~�!�WiV��!�ԑ�'��I�y/���mUD@�\i4
�oU��*�P�,��7[��Ƭ&�A$k�u~���#��#����#���\���c�F7�z�I� U�I�����G#��YX�I���,m���8�7ײ( vld�(�jøػB*��<����Ȧ "��`EVE�I2-�����'J\s�%ki��#,_�,VrG,i��b�:��%�O�Y��`�¸�\�����G�sT�%�+���`I�5({e�Ю�I�ݖF�B�礑��;�M�f@4��W��+���1��PZz�wM�4j���I@����U�O JT� ���������Ȇ�#�#�No�6�w���l�h@:���״�h�I��!{� û�AҔY�N�V��k\"Zdmm帧��[R�{�L�.�cgM�����BL��I��)T!�B�}x��JT�]]M��'����u37Wp �M�L�?�;�ֲ �e�6���y;��v�{"���}�vϞc�d[Z�`T ��E���XF�;ʼ;|հ�9(�9R!�����KtQ�cF�lr<x=_Ħn��.uԂ��&�/*ĩ��5��t((l������<e�T�ڂ밸�8�2<u�h{ԡ:hĳM����R`p��&RM~���` 6��&��<��&��֯�^
��o��Uf���^�G��9��U�(a֡�Xw1hzW�C�Q��a,����3�t>��� �3�D��$��s1�dL�����v)�k��c��0a/��Twy���@7�H���6x�JG���z���jt���P$�MF�`.��z��D�@JM6��Eʟ;V�|��b��Kޔ����q��_�,����\��|ف&�q-����S��A�6�bC�$��$��Gs `���	��R�X�)^�e��xo��r�B%��9!��~�T���R/z�>��^;���"�3�]��i]8�:6ڶ��~�%_��FZQF�Р��l�~A��j�V�M���.Z��5¥��+A�-p�y��}�ڠ'�a�S�	p�N�/}���(��k[�,�s��b�ђ���0�CI�D/��.,!1�@��w?�����؅J���e�1��Y�:X�I�8�J,�����6~K��NY��J?�2W{�e�l{p�p�pYOd�8֔3I����0�nz���j�k�TE:�� Lа�9.��O��M 4���m��0�~��1�Q�-��o���|���ћ:B��i`�oJ=Iψ�Y���A�zY޳���9�l�l@0pM=ds1�YP�8e�����,"< C,�7�S�ӟ0r[{�A����e���5�@�LC��~NX�]�-�.Xz�48�f3�3�M��Jl1�ӡ�~ש^��U����ݚw�1p
�~�n��8��<�\h~�袨�Y���_��rNsNV6xV:��.��P�&$�!:�J����������s����̐��>��A@ c7|�u��U�����>���_����JN��J���k��?���%y�2�K���j�N�G� \ț(�p��Ļ�*%�vGYau����U��,���G��q�s�R�@�b�v�����˲�A��=���d�!DJf2�*I�8�	�M#Ո2�TߒNnCNH�ɘӘ���Ǜ����>�l.E1:�_�����g�?��J}&	,����Lb�:{�WSnѥ�Q��j(NXE$m0b@�exxzA�����R uY�g���g�?�ޫyz����Z�oGSfyyl�$�ad��f3P�Z�\ڈ��\���ڔ�Ĵ�����B(���B-��$x�ΰ���M�Xzd�:_�&9�6; u�ɯR�RK�K����kBsX��'�X̍��5D�{ 2���a~ֈ�C��)d��	zcO�H\,i�Z�%o pe�=��"[W��#�� #1����-�e�N4,ݖEXL^���cg=����ߨ��)�_�v^A`�w&ȝ�w�Őf��q#'O�N�H$4�tA9ͼ�yyKSj���S�x������ik��d�>��@�C�[�$x8�~9*������g?.��u Yba�W{!1�K���(ZI5�b��+W�� 9�p���1���QS��H������x�H����,���{9yY��������߷kQ��	��Fx��{�`"�X�8��e�^=܊�nH\��J������).q��r����+���U�^}NB�r�ƶ�C�a����ǯ��6]��m����ln.�������Qx�B�����j�8��1to�
aa㨩�"!༹���㛞�=��G��Ã���
�bb�nuh`�,ȗEG:�i�lEf�k�ԯ-Î�5d�����>µ���5_N:\3�bb����s�P���K�(_I%�Ba����<F:�<謬{�%�چ�y�P��x�H��t��!�i����4(%�2r�о�[�R���e,��2��4��{�L$�Ǝ���h�;�������׹|9��^��]���j�\&/»�  ���hA�wn%,��͔ؼ8����Y���_A>�$#�x/YL{r����hS��N����K/A���w򵉤�J~GY@��-��i}�ч�MY�^ܦ���{���&d2�K��Ǆa�X��$b-ܹ3���p��:S͑r�k� ��lX˨~R���-+�� �ժ��h���&��^b�]��P�1J� �"��B6;,BLȢzZ�ʶzX��C���5�b��m-�M {H:��Zw�f���������6Z3E�ZV�
T7Μ�����"\W�^���u2NvRo!E{S�ߥٜ��+%`��^��I�G�4���d�'g��w�Ό�^���L��5��Sj͗7Y_�"b�N�Zn�{ջ<�-�e�#�.��qE{��K��CNo(�+�����]���0��+����9M�8p��d�޴}}c��j�N��^��ϟz��b!<Z���Gl��g���W����kݤJ���3��cyK"A��*�o�Q���|ŋ��4XE��iYä�����j3M�MUa|�e��i�9�DC��m,��V�7�c�]s��6���cr��U�����X�p��{ވ�c�hha�n���AI* ��>���a1؁��,J�|q���D���EОe��(��3�:&��o�t�eX��==Nֆ�,~貼z#4�Q~S0F�м�5r)�˾�rG��NW�k3�֬zI��u�4��)T1~�0S����a/��Ƚ�t����1w B#�k�	����nVw����,Jk�l�</�уTi�"��<:�S�{��7m%�t��0�L��i�\ڙ�|(�-ء�^�n�ܭg1���	B�G�}�1(N�~��PO�{��"U��P����z�G�W�{�wj��/u�����B���?pӡ cㅽ_.V���°/�N�*1�\Rg+�޿s����c1}渱c}BCćm~�m��<ҖRh�K�tr)c��A��l�l�nW@w�(K̎B���_�c�q.�?)|]r{⼂��u��:*�=�La�;�5�Za(�����o�|�� �ǖ�����Od��ۦ�Q��|u�luJr�3k�O�ʠ��H7b��ƶ��iNJ���4�s3�B�d�׹Q��(.+&[��$���s1UW�Ni Ix6_l�z.�Bg�1�23��q]WA�3K�jǪ�$�����ܻ��a��閪@�BfXC-~�h�(@��Q ��e�t�m��{ia
�i�_Q�u;>�����5���K#Md�,���;���ChFuQDD\˕(ZQ�k�;�U3Jjo�'�*��ػ�0'ڠn6c�OJ*�4�թ�x�/�4m��L�rG�5ّpt����=�\J�7R�o��%�.x��� A��m9
?<`���x��v���7��E'���H������K�}�"^ׄ���m���-L�|� __���K����"iMxK��L����#��0Gq��3P=}���d��IO��k�Mr�EtX����B�7ݛRz+"��������KoT�8Ձ���N�?�sm��J�>�����-���B�_T�¾X���S��Κ�$F�'������4���$C'��IRZ��>H������c�7�%�����.ɪtG?Ml��I�Ko�4�7��3�������={�
g��64��8gE�G�yM���O<�>�|p��n�˦����y��iJO�˒�o��wL�T�`w����(����R]B~������ǉ�A����D�u���u��[R���m?T�q���}�ΏqG\��xVȰ���x�-��W������+�1�"=�Ce�y�C�B,J�Fזq L��G8T[cK������X^��=��-^ǘ"�k�Q��ğV��#��U%�6E�"\ x�4�0u`����W8��7�?ey�5��A5�j�vT+Wb-fq"_�3ۢ�:[��	�%��	4�V�t���t�,���GE���s�c���:0j���g
Ǥ6	S��	��~��C{SFf�G0�����2�����Xf�G���1�9<���	fe�,������LA�R����Qf�@��v�F�B��?/w��+����:�p������T',�P\��L�3|�T�v���������j	���!��WA�E�4 T�ŎI�ڱ��B���� ��Ϳ\�G�7�����A+>���2��|�}O}�)��?L#K�H��}~��:���)�����r��E����C=�U��K�	 Y��T�$�T|�b��d�z�h����bD���dw�	��@�8M-�Ԕ�EO�&SWYza��-�&���^�������ܦ��#�f�z��I��ѻī�d���077N.M�wP�������+X�-A4�M˘`�V�0���oNN>3ӏ Lk��m����v��s��hC\���@��W9�h�M<����k��R<����O��x��M��R~����B����7 |���G5>9�?��[8��y�ǂ�<�&~r�,�'����"�Rw�_�;�hE*��>G�{�9B3�h���܌+�m�!^���2޴ �	~�Nñz�(  X|�"|���U[uq0;A�a�W���=���(R���x��K�ZZn1D�ʴ�G?�8(�aJ	�&���[�|.�����x)B���$wd�D��f��+�`_��̌L50��6�ٕay��S+��!Eh��I�7�o�R�;x�i=0y����>󾦷�m_�µ�8-U89�h����?gRִ��O!̻4(rC^B��M�oe|��Dddp�xҬ� LE��hM�N�c�#�g��s���"(��
7�֏��>�z��^�K=�2���?�
��*|�waו�<���&[YyDkv!	g 10�KL�XL�[���˒Y�T�2��D�?״V�~��.����cp*�X ZG��TE�E"�~��6Hϛ����"��x��F�E�O����0�d���#G��C�C�-����Bl����7�G샎��s����N7�/s���s��c�uS��q�(�c�D'v\�; ��lq	о���t�(��l���gkd����DC9�k�<��ӀaJ��l�����<Xۃ_���6�)N�,	���F���@K�LA�Q)Y߶�E�*z<&��G����ڧcZ+򚈾�u�cz��v@1�8܂���C�{	���5#G��ۧ��uFM�%[� =~���r�Mf�~ӌ~��($&fc2�n�f�V�	p��p�?�"�祂�9��T�О�iv8(��W����Q*���ʭt�o�M?d��_u���r���07(p�ܲ�U1���z�Z��F��=�
,�& /A'�/3�5�uV������+t���Y������x��F�:�rCH[-���2���P����k��h6�?m�D��g��F0q����es�CS�T7�"����!z�5��f�����l�$�z��^K[sti�w.��Y�$���	�fj��օ�{�؟�L-�z��7��̓p���,���M���ܹS���9x��?cuc���e���u�R���[�k>Ed��c���9������R�2�r_��JW-����s����SjV�b(��8�l}�.RA��|��VQE@��+"Z�^��01m2vhB<��N���P�<��㙹�5�%��k��}^[��2�H��PV ���o˳�����az��Y�߃�9;\�E��Y֘3N:
F�6�TY�
��^x�Z�� 6`��&��F�� ���8�%�q��aɀ������~$��t�NF�-],�{Y���ꧦ�(|?�(�`�{S���ST7a0�w	Iv�A�JaKx����x�n��c�i]١�=��;�Jo3��� Ќ߯ţ��x,�^�e��f� G�\ܞ�P]mY��;�xH]#k@H���	�?8U�ꁜO��{堝H!���� ���;�_���@L��`\j���5���� ԖӃG�2��_��~^{�5,�"U�&���Z6W�E���ڀmR�/�Mk�gm�KG�����B�/W�t�#)}�1.�	�$�����*������j�Ɯ�ah9O�#�'.�0ff�Uc/�0�Q'�9�t���uL��������$6��#M#�p؃yy{z?5��6�W��§M;��}fI5�a�U��H�^�TU�H󭷫�
��Ҁa�	���
Z�MfC���X���<�.�_
zeT�.XM���X�m��r���5Y��&C����u6t�?G��P�P�>=�p������޹E��C��	������Ļ��]�H#-���!����?t,-����%��b��� ���{'?sf�S�b�    ���/# � ����A�c��g�    YZ