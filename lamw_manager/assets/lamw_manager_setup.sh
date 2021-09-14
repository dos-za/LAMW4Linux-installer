#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1480963930"
MD5="a95405a46f5b0b98ea139502b425c715"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23312"
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
	echo Date of packaging: Tue Sep 14 13:07:39 -03 2021
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
�7zXZ  �ִF !   �X���Z�] �}��1Dd]����P�t�D��	�P�LvGy�V*d���b�è]4t�O���O\A�?�w:����Q��Z��?T��N�8�l�kR�+Jc��jH,�l`n46��2���G�U# WDA�"�B{3Aʷ'�A��#�ѝ�@.��k�ϸ7O�t��������]�+^Y�Dg�?`���|�q��﯑+w�80���z̃ "��,hW
_����f錪��FRC�ERP>n�^��]��_Y����?�p��	k�n���T�[��0�њ��Ixp/Q��
]zE�!� 4�ܠoR�d��zG}��+����,�N⚌LC9�&xd�֭T�%�w7x6���%� ���:b�8\����7�,9I˶�,�D��U|�]#��H�:L�����։Y���E:P��5 ��x�Z��	;��ã�~�S�����ōt�7����V+`��@�q����y����+a�W���Q)�`��)�T�$$�A5���F�Nb��T.��m��y��Y�>M�@��Q}�/ 6���~��QC��Pgv�9��p�:�K��cn�.���G;� EF&72�_�ж���D���<;�YY�,�r���{�����
�/�o�]#���9v[S�
���F?z���<�)�GH�<k/ϯ����O����A�[�DM����D�4�Z=����ԾG��#�[TT���T�7|�����q�%=�d�uҍ�Og��p:�:��x�<����v32�.ܵ���������GMf+h�{�m��
��O�0�.����/- l��<5b�%}7a(\�\V��w�n�z�FAfk���_µ|(�5����)�0�ڥ���nͻ�!��C³�	����l�����.Q��?� �Z ��r<����y���_�v1���"�	�i���?.Nf�_)Iw[����������D�7,_�gnd_xi�*���9��[���/��|Y+n4�S��[_��Y����	����'����5�\T)��>	��u����bs_�@���^�i��ѭ99=��[�����	���K:�%�A;iܜ?���I�Q%�� xv����ߏ���?���F^&�j�C�����dݐڗV�C�WS�ㅺ���O=�O��veyn�UQ�u�l[B���r��ꗾ�"Ӭ"���ĕ�?^�:x�� �(D�D3�x����*~0��f#P������U'��^e��V,{ًU�YL_��vcm��cSq�Az�Mv��6D�H��3dÿL�;}�ch��{6�j���b���`�'?_k5����ֆ���2躗i-t~U�Mv����/�#��(���_��Ǥ�u���")yj�G-<Ywğ��W����R�<D{3v�jS{�n�6Ĥ.;�G�X�ZbO������5�(���!�]�%)N���h�Z�rk�%���I�"�\��E�$�΀1�H��O��q�\�Jń}L��\�tl�y�����6��T��8B���3���0O��Ȱ���!.�|������O��nvp.�
Dʳ n����:t�Q��[�0#��V�RG��e�&�5�����vg@�|�!ߣ�a����p��
��'C�����Z�>`�߬�!0�'F����VfM���i�ж3���(�}'�d�N�_���LZ/M��\n����(�'�2'����+qg��wm�kDi������D{����ao�	��a�P�����'X��{M�[����ݷt �=Dd�ҭq�;� hri
w���6��c0(?������<>F|Z�T�B&��U((	3]|:T��r�

y �J���,u�]z=<O9��w��	�`���o�?��K/��*2����]�zo����by�x<Cl��T�
��d�ՁW�݊��i��_Ҫ�M��9~Z�t@}����P�Z)�C!=����Z�Av�;`�"?��=�;	�p���uc#\v�'I�v�̼t��w��G,�� H�6�+Eny��J��9צ�f�QͶ��\X|�~������d/r�]��R�.O��(�.��~��̳ѱ���7z7PDj�����]����$/�i��x��"��
�r��̼�l��&au:����oŞ�� n�]���\���s�a��ujV�d�����X* 4`a��Px�ь9��[X�8�\w�Ջ��eb�(z�g���n[�T��w7�L,��@)8
gX�;�:w-s�"I��� 34�m���@�j������XCߓwN��jA��9'<������?cRL�� �h�U�j>�E�႐����>Q"�iL��uAfɿ�D՘����R<h�i2vd���b��~�T�XV���*e�����1X{��<�bO����;]QF:�U�K���؟�iU��|Z���I�5B�1"0���7���1��r!�[v�����F�R�oG��Ncc���(5��9�	���_!�;�	m��8a{~OܩxYT�������O��`6}��Y��'s��i��iJ�)T�$r�2zv-km��y���<�
h�_�P7qs��*���� ����ETA�,�jÕ������6Y��0��U�dQ������	X5ݕ��p���hK�������mѷs�?܉�c�e�̳߁�?����Y:�� D�8�ӯȼ:�^W�a� ҏ?P��,`��#Ӆ����<Cm*W���h�r��O�0D���R��Z�8 ��.���Ed�j�g$	�g͸i�u��\ݮ�,�߬���`�����{�l�Y`^0,9`>�"�gv���Z���LV���\�O�l�ՠ�q,�f�Nƴ�GttU�8vNv�l(r�⒮�:Xm~/g�H
x&,��c�/Ʈz�F>�{{bf;��I�N�3�F���� z�~%ɣ�$�`G��>�T�	�!��7Y�T�R�؂��~�6�Y��I������R�9�0|�.�|�P����1ƻ�/��̔1��GUd������N6t�,vy#xJx6��8��,#n}���n2�.�$n��s���F/t��|�&����L�Pp#�9"��̢�lJT�T�떸�('͍�[��ܑ�(K4t��q���c�b{��"�5�9�}K�%���.餘;�tC�t�)ܠ�=tm�����Q;�:W���{)hNazN$�\�^��(��N{O���F� 3�?-"�����b�P<Ð[Q��`�%@��Y(��yO;��^�������-�ēi��ZzJ�0�):hN�W�{�'ȱ)��9,%5���IY��ZJ�6��4���H���~��P��|��rgx��w���%��J~تM�t�w�_�Oa����vci�Z{'���,R8��y	.�7bxxf�Ao4/]�8�6qr{��'�C�P5�Kg	�}��v(���K�#ȋ&��6��*�3���R�)I�.2�E��b�]`|�dc�:wk8@K fE �L����T��w�r=��Cc��I	Ʒ�!Ɦ��(|toeĻ��������#C�i��qu��3����b]Ôz���4G�у��/\W�FwĀi���d�kפ�ogelE����ƸŵQ�M#Y���aQ
2&�(|�Gܶ���yD�Fa��l5�,Sc��Թ��_#�fٍN7��kr�c8�-'2��F7��A/4�����y���?@���}aBu��M�r��
�'�[���(��s5Hg7���6D{6���u�f�3�����X�e:iz�uu�Cdg>��v���7�z2*�m��K��`�����v�3釄<�c��>�i���md���gs+���	8�0H��6�8�B�l��ݯj!Z�k�힨-�96�ѰZ �����@�җ%�{����M ��^�@����}����yC��R�h|��%s�m���^0�.k�n�ƭ�Ulɫv�:8���{�©S��3$ٽK�S�>�]����ob�94�cR	ot�yĺ}^�����z����*/z�i�q���DZQ��S����>�g�<�-ۚ	��whss\s�B��ϧj�`Y���Gԯ���%%'�UJ��"Xt`BQ'H���ׇ$�Oj�ݎ�ڑ7wN����)����8��Ӑ�]i)��Q/I�`d]��[�ˎbH)�ȃs+��ArL��?�X<t�[��b���.��vm�t5Q���o�p�Wඓ�GNl��#;�o�$����$�2{�yy�O�%�|z�C}bb�EyK������)�
��G�<E�?����B���L�K5��C�\�J��zu��]'u������ǖ�?�QT��c��D1"
�=A�K��(<�\����5��@�8v��N��{����f(5tSD	�I���Fc�Z٩�֎w9�	��d(��18�Jj�s��5��.��.��d��ҡ���\����BH�8���)G,�8��z,I�� f��Pɷy����S�U>������<Ԉ�{���C�-!�:+��	�6o{�m�N���N�G���P"~x>��^]$5��#�W�)�i\���\����0�߻�0�ϴvC0t�m��.F�["����tGY{]�X��5���'�#��&�W���
��A�����/�^ɭN0��G��}_<R��Ilۃ�����)������[��R��R�Yк5�31�$F�.���b����9� �=�ƾ@ԲJ�U�Y��G���e5?�F�ڒ��ɛ�Ŏ���@K����C�p�ߕ�����M4F2��!�4B S� �=�+h-!�\8���iC��XsD]��?C[-��=�`� ��슶in�Y��0rv��rz������l���EcE̸�&kX�����l��ښW3����s�^����C)x�y���yH��	
�R0���8��Oe��Ƴ��S�3���9g�^�R�T_�f�	őfJ�*i��\��`�y Q�o[�Y%U�_�[J/��Rm��/�KM(���6C�g״���tq�<����y�l����Z������q�DN�����A�N	�z%���+t�����,q���^1�qV��]��jw�0�����0�^­�L�k���Kq�����u���A�B���Del2�8�d��Z��myV�D5�)]���96�S�w誮���m!
6'��T���\�EU��f�Bm��5k��#I�����Ѣ�����d�Cb��6Z)h��9��\�A� �u�����+h(LOU�J���2Y��ۿgm�Eӓ~/չD��릤���i#��<����R<�3 ����[g��lߏ�S�'F�V'�j"���(�F�W�J�6�&��W�lrp��h�:������cJ��n�TG�a��ka%g��Ұe"<it�p��-�C����B:��3(^Aw?C�O���� %I�vÍ��ɽ�����d��<l�u��M,WZ?5 +�0 JJ�XU�<7_?����q}aC�z�5A����k@��J�H��9��0OӼr�,��b�h]g)���g>����g`�4�%=�M�(�$��J�pʓ����M:�aZ����[�4$����^�qJ [q`j�WM>�R���é�7�4{'����L�����P�g���o��kHp�m>C��g�<��Bn418ADȌ]�.6G�f��t��U_���مG���-N����T�J!�r6!���$[��:}W>�W\�œ���}h�s�XG������3���m*)E]��І��/�`�2�Ҩb���U}m,;��$3~����
����Y�#nH2�Xw�ߟpg���<�}X�Ć�$-,�՝�����6��lf�'ۛ��oD�jQ������;��]b�[�+�#\��_�R�q�B�T��(�*����R>ƛ$E�E�2vt_����I�r����ӎ�����Ci4#U=IQ(�d"͐�VB>�k�#7���'*a�C룖�����
jsl�f�V�Ѩ*@[0_7�?�D����zJ'a��}�)��?y�oO�X��f[f�D
g�B�("��Y=n4��)�>B�~1�>k/���hzQ�'�N�\�=b�d+E-�|����t9	=�b2")>�K`����䄂y6&z�tU1�Ma�J�����V9�rU;h^m�F�4;���-p�g,[L4O�TuN^,")'��+
�o��D]�˲�g�O���!�?�G���׊Z�/t
vVU��V�03�@UoX:�I��ך�j�2[kP�ZI���i�W5zg:�����i���rjX ��{��<^��H�8�&�J`��A�~��Q���9��E����t:�G�}�� ��*�$�Df?d��L��>���?R�jY��'�CuV4��mjBO0�n�%�P@�-�2���"@kz� -p�� ��K��M��?Ő��dUY���U
h^�����u�ʂ��LZwx1�+��	}��͍u'��8�Ž A�Ą9��O��_�g^;S��Cv�~�-pl�n�̋7���i�3;Y��yK1Q�	5Ð���i�����5Q{R�]�W{X"|��q��&�U��M���q�����*{����g�����lXJX���	e�azSOQr�@���Ms��,1��Ќ{/'���6�9����)w�'�R9��o�qP�}���n�7)ă�G���&}1���c`;�-4�
N/�$yw��lhҬI�)�&��i�ka� ~ E�T�&�r�SK��{�>�ҙ�5I�B������es�Q�t���9����r2\^�6��FP����62%�y�I��8�9��m�G�䀘@�ۗ��~�$S&���<�Oň8^��Y���Z9¹)A���3��G�x��Q^�\�eU����ɩ������peL�_��?�R�P��r��`d�B�����B���_��6;�^w���ݺ;��x��fy�L|����"�s�O�b�wN/V�ՁB�J��V�����X��X
4d?���b��&��d �÷#�û�]|Od5�|�S�	x�.�)b��رdoӆ�L���x���`N��ǦB\�D�N��IWĭ:&}�p�/��,����OP��+�D�[&�0=���:�#�`(�r��4Ѝ��k��� �	!E�O�-�����(t�7\.���J�/٫̀g`pO�0�l�/��z 4��3�T��%���k�X�P�2X�
Av>� �ɩ�3H>��]썩~3Əvŧsq��Ok��;ɰM46�:�6�|1��J�����,�n���챺K8,
�}	����>6+_����|Z"�C�ʉ��6]d����d�@�C0�y7Fcw�
�xqp��wN��,}��lp�~T}�KE,xu����vM�Hܒ�@)q���7+iB�ߘ�-K��S����P��Q�S}=��R��F����ӛN��E�s�&�L���/�$�~dH]��`�.�%�}��y����Z�y(�p~N��K�;F:&�H1���o[4���t���Z�_m����m,PxK_�z��$�X�єne#���C��1�>u�xB��s�
u�_���fޠ*���ϻm�=n�-�HR�r��SG�^6�[�b�$�<=#�`�(Xr#���q�LW_���8K�H4�8����=��N���
�Py�=�H��d���W��-�
W��kd³H�D.&�+�\�r<�
ͼIGp�zx$J;2��W���_��B����"h�e}|�t�(��O��XN�hs���j$�}l�"�(��^��o�5׼ޭ�0����V�?�b�%�����|Vn���0U�#t����_I{�t^h��<Hr>����{�n�����HP�g�"��������0�}�׃���~��Ywͧ��xր$��$~z��P�5! �5�vNo�V��/�z�VhU�U�,�s90ib�h��-�Un�u�,
�E8�j��n*|^��ʻ'~ܴ[YO��\0�?҈j�_]�J��	���1oJn�HO��-W�7V��s����&W1v�2�W�s��Ǔ��
�m5�P8k�h�A%����?;-L�͉����HR�5�!��et�����@���|q��5��;d��G���[�O׳����y��e]�_q�!�Suf-I���o��Ϧh��,��<th�EɎ`v�5(����?�(I��K���}�<��*���B`��)�-���UC��ċ��˔�X�lA��ӌY��@ �;Ơ�� �@��wUF��%��<��i�c�8u6�>e�k4oG	�H�\$���{��p�;��Eq%�����w&���A�~/s\Z�S��[��L�� ι�z@�>�	;�1����d�'�uQ�W�W���L�Y\��ךH,�b��#v�\�W8���D�m���X5-.[*H#A����eb}���돩�;#�<ā����� 'J!(B��y��2�O��WL��h,�xgxt ��� �!�;#�qY���|<>�z�����	~�Dbvxk��>�H�+��$�Y��lܤ��^��?';����9D�095Ճ-�_V�\����+ K�eQOߣ�2I��V�<x{���C@öލvmc\���{�u�^���9����bH	�E4�hDgtH@nQ���C���ƣ�O@��\��H
�E����{���� ����y���J>ħ.��
2&8&��Si�A�q>>��4�w���x'O�m�� �q���U�ي/�M�����g
j8 ������K&i��:���a�L�C�!�Y�'7���5�8�l�A����R-a��l(��f7'��8S@�F�"M�wf�7#y�����
�%|0[�<v�N��p{�M��"�7����R]����Y'��!�)�֪�P+�����[�=�[Ἤ,D�9������I9&[wb���w�Kr'6�/,NVK�[iPј6t[�5�f�;koSRɢ�m�3���^X�w���C3 GO���~��"��E�3�n~��~��ɣ��s3@%��?���۠m�4��(��Nq���S�ׂ�b����9'g��
�3���?ꐼs&����8/�y�?M14�w<�Ze�l$���LJ��@�2[x�����*w�Lez=c� �Զ8Z���r�����\̾��u��Ҵ��?�*0ֲ�K[L�~n
=k���#�~r��̎ %�8𠼱�X��Ԥ�f�^����L�c��Ycq�����ԓ����*���y�9DS���HV&�.���Ā���J������	 f؊E�p۷(��kZj��v�� �/�*Y�Y�Ȍ�����
��d���S�p�/�v�C�+	e����W���7KG��"��[�m�������4u�<W�\���	K�(���=ob�����K�8����QY��`�NV�Uh� -J�v�Ab����/?(&����	t�[�:?l��Y�ȼ��N�Y���\%�@Q������= t�$L;��d9�@�Gd���#�b���]4�W)�����=���C��([�8I�)(�*:��]���TH��)��l�m�-y`"#g�����{�9$)s�fR-8��{�0��C�<������ٽe�d�՚[��i0�lU�5	���{jO�e�����-ivU]�9T,� � ��j�S�������	���%����h�k�T��� �x��3B�e��Qc���*9�&ZD��^������֛�[�-���u�r�_�y4d�&$��m̻�-l`ªt@۳�����oJ=H�˔T�\k}�u�T�U�'nG^���A���A=Z�>�'
���ъ~��V�͘a�!E��	��$1|$I�%����J�ޝ�d�������+��L�R`&y�����±�<00����i��K��k?�v�;z�L��Y��ڢ��W�mz������m\��C���G	�v��ZSuQ�Z�0-\e�%����/+�Mw��814c���qm>xv*��x�,�J�Lܡ�r��_�K�o˃����ݙ��d��G�oa�,P�����˱�� Vw��}
aHw���/''Ze'����2�
m����!���#�f9
��%��0��@���7��Y�E����ס��!-u�:SE�!�M�J�2���\�vKЗ�p����7�<��iv�z�S�*H��I�0�ùlb��sA��%~d!��UT	�y^/	�x�7M��la�"L3�t ��iQ��]W�T�� b�Yܟ���"	 "8]^�O&P��� AE}:�k�D,�e?;m62:Mr�:����zy,�)��]z��cڃ�!�ң�:[8#�(0��W�sſz�,��YZ|o&2T��Ą�oA%�Pͥ&�<&h��*m��	���0��L��^�ѫQ�<�>�]��<��'�n)����>^x߸&"����>�>�ݧ�jB��sj�i@�o#�
GY�7�R����o�/�&����~_���O�K�e�ٞ>�Fh*+evVU������p���	��<c$������o)[����צ{����1����~*�]����D�G&*(��?q��>�:;�/�1`#~nG����7Y黅�ٿulQ�>�Z��
E|��ڪ���Ϻ���Zȱ�f�K�6�h��Q��/B��K"l�+��
h�
��<UAj�y컎���D�0�O��J�l���#�>{�
�y$74q�E\s��<�����uH��ijd��,9���U�!k@I��jG�=����F��-�N��%��#��R��i�@�ӗq�A�aT���c*#����`�3Lx�����e�Y=_@VmV-!)�t�M��C	��b�,��3Jcy����Mq���_u���^[�B�D��v���m��&I��Μ���!H�o��}�h�>�Ԧi�N{����w]�\d�Uǘ�|�s�QE�L��jS�	[�=@�O)5 R�Rͼ�������*
�TG�C�`�s@���a�PC*�0_������4�.��ӧ�D��5�4�����\m����� RB�%:���_�B�Ũ[��㞭7��d��N�����xb.���4E\�E����r���o��m�p�h�o{�+hܥ���,��J%ߞ:���?���ȴ:Y����
�o��)V�[@���l�T�"%qR���AB�!�T���o,�&  ���i=��H�C��H)��mO�Pd��h��,���c�T�O!�|Q�2�Z�g�豚����?���E#.��5�)��k&��J�sbR�{"~&����w�kr�s�aM�q��p&���
Y��Zv��NH6��s}��2�2Q�wA�y#����H<B�lQ��ot����ҥ9w|�H�iR�8�oW����ׅXց�R��Q�v���M�ygl�M���r��	F_�}7Η����Vv��.�[1��O����!�m�A6"#v9��/�C�g����cPƃ��$�M�S��P��˺l���K;�D�`*�fb^�2**��v�.��[@�L���EY}W��~�f���lZ_�#�Y���l)�s�tgr(K70}2ߐ�Wxn�L�3��
��3�VD8�n&�j�'�Q�!�,$@ȩ���\%&�{��� ��R�%)ܝ��W�K��h���}8����+�ۛr�g��!��X1�U:� ��ij��O
T��I�s��sNb���<C��� T퇊�_a�|��mG�pV	+�Pl���~D��J�����N��F���;[�"/#�z��h(��woZ�{*�s���bdM��뼢j�n�?ʒe�� ��aÖ�������S��k.h�USp�Ț���|{��� ������H��������)�Y���������A����ǉ4�w�g��t��,t�*r��_�.�:����<���ۅ1��0苯!ؗeE'1��`컊rH'�U8��2"$����"���4+���j�����)@��6p�I��5� �q��O@��a&��W��ت��&����6�&9���$8BY~A�kq��:����3���s,{A�]'y��u��&zG���m�|]K��^Z�{_5�`��8�/3�]+�	�2����#L�c�6w�ؖ�8��Rd����L���6l^E'���o�"qua�l��/Nvu�]V.>C_���O�ҽ f���k��Q�GS4C��z�+6�Jo�ɡ��k��B�>�^��G�"y��?nR�nJ%�9�.-�G+%B;�� �p�RY�sO�l9K4�8�����&��_�h]����8Lz�u]� 
v�kkytDD����H��-Vm�a3�o����%P�����T��|�]C�6t���H�n������G���o�e�0�S-�ᅑ�2ش�4<͡r�
g�����[4�D�K_�V.Q��9��8�8�����`��?�imq7��Ьv�ʔ�,34�ߴ�<EH��@2�b��e�Qs	�>E��\c�Ki	^�п�Iݘ�8\�3��x���iJ؜y���X���
q��(�U�,-1l�m �ܔ���9n��J��O���e8����ɯ�=�����p���,M>�T(y\�g�<���N����&K\�k�?g"�6#Vl؜�Y�� 酿L)��>O��(�c��K�-da�x�jn�O�s4�d����#2T8��Y����DM���F7���w����i@�����B̬��J�^�啂�K�b�}�����h����0	+��yXG�ud����#�n���wX+=-��~�঍bx��i�I����x�(A�s���+����XT�9��
�kŷȦ�UGca{V1�(�])�1J�&]-gݧ�8�J�qf���k`s�!HL9!9�H^:��xQ<1�~Kcw�.bE�{��Eo�P�������2�7쟢�1�4�IZ �^����~h#�l�E��_��4��#}Z��oB{_qg�@��d�;�+ߓ5��~,��QwRc�S��<O�f�n�ҩLS�� hB �%E&}o%d�2A�%o�@� ��a	2<L�!�+z�;�!�ŲC�3|�e�Zp��t�,�' =KʆBa�Ԅ�=]&����t'S�$�7�Γ�,���,�Qs���qV'�H����:�?��EvF��K�R�p:�p�;����V˵��u쎴��g*�~��uف�H�x�<U-@Kv݈�H]W�7����,��N"���\��K�����`��׮O# &l�CP�X�l0���?=��=l
�R�0EA1�ѻU}�h�DW��b��I�@����@C�6L���1L�Y[f��4i%�@��u
v?��B�oq�Hyr�9�Ɵ��?�^i@e���B�R�L���Wt��4��P��7wѨ�;�dl�[�_d^��b����={^�	�i�Za[2�	(�����ʷfE�\Ⱥ��j�G�g8W3��`���W>w�YG�Xn�h񕟛�rWfW|���wɛeIW�ȏ�E���V�+�B����|��K���&I�3��� �u��#��d� aN��4j(�+�߲;��B�/{
2����~�/=O������NY��y�	r;]���F0m�8�f�ڔUս�D埣R�����9׆�h-�����	��N�l#��;�߫�Z���x�b/iY�:=��L*P�W�N,3��g ��> �1�EC�0O�.��֚w䣞�Aw����-[���b�c9����|~9@��ŉcp �[Q�Д��i���3��aa��X��)�l%�n��s{ۦ,�iWˮ��Z����YQ�ځ��ɥ]#�Q�.?�#�Q~z�c��� tF�^WVa�9�p�]��j8gV��A�|���G�悿�|���&����X$ӣ�Xϴv�i�KnD�_^IV%�<kv�"�q��h"�D�PYPi3uoƌ�e��������*	�UOZI�4�ĉ>[���!��C�|�k�wC�w��s�Oə���8ހ!�u��HlGm�7�<���8�ϣ��v%���ķ�}���]tb��7��.���W۠�r��9Iؾ��z��� ��;�C�~r��J$�L:z��ؖ���n�6�-i��֖�������>�Rs���u�c��c��!O�����7ݯ��?BzJ�i;E����ni��՟�പ`��{׶�/������lxjC���%U7Z�����9_�.1(X�s����0��i��Ì�/\�;�j�N��l�����z�0�	g�H�{��ƣ,�齜tۯ�?_�w�9qM� �Qw��e��� 3���ǆ[I����4�#E�;6Uvl�w�Z#�M��*c��������fd��/��述���7Af]�׵�QFao�h��]�C��2ݦ��8����Ž?$���<�B��˶��)�Z� xx���i5ǅ�WR��)�g� ��P�f�ԄE���L��0�`0�}�s<Z�Yc:#ua��Bc�R�k�f�[#�¹`�B�~�b��#g��ᕑ }��28����)��CS�BǞw^����_nfZ�9�x�#�OT��vu����'e�yۍjL�4�6��`��Ĩ	7[�#e-���ן;"w\��!�Y��v��G(����<��ΰ�[��4�!��F�3S}��J��?��vL 1����������/�!��������1�ʈ3�Q�� ��q̎$e�`�\��Y�!/)�wI9Pmq�i�ɢ	~�(Hw�zt-ӱ7�@��Ԣc��t �l����0�mF;�C2�\P���}=T��Z�Q��F��|����TZmC��l�**Bg${l�ºx�Ƿ���v�%0q4�s�0Cn��4��~A���*��^�����?���D��&��ͯ��o͝�й���!��Z�T53Е��Ɏ�d	ΦU�/Z�])� ��/���ůc��O �@��;jd���~ ��;|]v�Djb�z�%��#QSv�y��{������2��k�ߺ�ʄT> �<��9IK���i�}LA�A]Ɠ*Np�����e����s�^�TؔX챲����F�>A��oI:v�2͹]=�h4��L��I�	�}̈��g
 �/��ՎI�0��W��3���`"��E_ZuB��d(��Y�-�N��8�ߌ��j��"���Lo�ƅ�xJn��p���Be��eѭ��=mJ�����QqKު~�J$hs��u_�Nmg<�  L�p�?DWA@�\b��&;՝���1�DX������`>�pB�i:>CH�כIP��lI����d���\[{�慞�Pz��m�5#�з=Q,
�BN�Y�[�5bjYF]򿙯;�Zoi�<���f ��`,Y^Z��c�"G�m�ޜw��&oOp��>���'!�e��<��H�Q���òw
~�*�̒�H�sjD�|��1Z@�i���|�� ���/������+�h��Jx�ВHf�g�� B�&
y��`uٴ���a���z�C�l�X k�]��@��0CU���������K�)����MP�ʚEױ9;����mb��~�x ^����4w,���1^�����ݝR�U�������;(/ߓZB�T^�z�"�K�L�D��G�#[*/���8.����n�"W�ƾpЈ�$���P�:q7��(��V�<y7��#���/�̛��,��F��4�s{���P#��pʳ`>�3U.=������ψ�+TǗ|S|.y-��l^ԍ��"��p�Wz�y|B	W��rqb�G�Ėg�^|r0��Z��>�~�M���GM/F+��$W�mmq�7�~������^ē�,�������7��m(�k ��D���Z!f4��˔@?"sJ�y�"���%��6�V)i7#�D��	��k������	�gP��7�!-VB�E-Ņ}�kjNep��%֭c�,y�n�LB������%X7�=����G�]�܃��nJ��&�M�N�(��1Ӿ�3$���j���%���C��R� ���eI�p,v������lsw�;v��3��J6���|�z��'�o-��Þ����+qS0wbSw�3�D+��҄�6�&�p3�����Rw{q<��8+@��wYW1�4PO�����D�Rl��>'7�A��Ȥ��H�d�^��;��w�B�l�����f��5#kи�|P�T_;��0��~g��V�4����yہD��yY*��/^�Ylb^��¹ ���h�jZB #9���R+�$tǣ`&9~�Y	G��]c� �f�|ɥ��GC۵4�#�xH����)~���D{q3Į��Fb��
�`k��,�7B�A����cK� �\��`���љ_tr�r�����G��e�~�3�>�ӝS���غs��[�u\X/,�M�����ZC��nK��Mi�ou�P����K2�%���jL�����Ůo��|J�1�(�o��������G�΄cWMc25��96dj�M����N����Σ+wx��efB=*5�H��`Ob�*	������B�RnI�!u�³ea�E_��GD�ʕ�]�(O�%wPO��,��N��7���lX��s9��2@%~M)r4i�n*�\��O#�H���#���Ԉ������z-�$/��Ȩ~� �Nvu$�F�"V]Tf����F�Ҽn�?�O���f���{۵��f�G,�T���i���k�+!���7��9xv�'
� �|�T_'k�P@��~��_�D`����F����x�$��/���O��zC%(
������b�Y�@
 ���7S���*bUw �������j���T�.�	a�����IP��cLt�!�/��P�Q���ݧAb۬ƨ�B����1 �5u��23�J������!3�n�V�Ф��zC�Q�cfMaԊ*R�v���?�f?���^Z�F}ѷ>U���n�{�����K��c�j��{o �IE|���93_`�/�����mW���l�I�-����|E���'e�j��`SY	Hg�γ�O�Z�b��i�vf%�/�alp��(�������^b��1q�_�7�����P��j�d���� �i����S�쬑�e73`��e�x�,%��J`�����KH�aΎ�wm|W��vq��f��K�c�7��G�/51��Ϧ���=�<�)-�(��j�˫[���M<� �S�w� �~��K:_����D;�e0x���5�gnQ@ȻA>4�����<C��3�I!�ꆕZ`��Q�r8-��aP��is�z�1��A'� �kJ	�����r���U�x���.����ND�*?������s�hH�%o9����:��͟�2���5c֌�����?U����l�>u��y��d^�>�A��A[Ȓ�P����U-����Ic9�fo�S�hMH����W�}-�T�츙ذ�m�}y�T�4\�VZ�S4Pg��vWץ�h�#����f��k�Q�˗e#B:��pq��g8b/Չ�me�r�;��ǶI^�:�[��2�+^��+×�Cx�^�$2
�A?�GV
���Y��u�]�ݞqCnJt���{񃛜|UUk�,U;x1�SG��PI����U�N)�a�.-ᑣ�t��{=�b1jE�� Ce.����DUH�hH�N��֭�ν~��z'����ϱ��a�K�`�G�Oe���/S-!��+�b3��������jC��Q�Vy�zhv��/�(������jD�c�TW�j��F��>���o:�bbvH���B ���(�5����S�8�G�f��P��ǭ��R���Ϯ|�4�5�uhՠ(�&*��E/�[�푨71�?(R���7��;�����M@�[,H�������{�4���W��w�����c�օ�m.KF�Phư	�sP���OJ�e�c8���l�A��Ed�
o�Pa�=�2-��gA����9$1��3�<g�J����#���o4&�Lی>B[wu���3�Ձv���+U��e�_|�iCɤX)�����U�ϵ��JkC'he��_^~[�7 �cb/�����!2j0w��1M�e�ԫ�đ]������L�0g�ůN�2w��ݎ�N�:�./�kFm]2�-��ύ-C��>j�	A������V&��>S�s��>
��F��j�H/����VL���G]`������GA�
�	�$E_%T�����$W�+џ5T�̼��|�� 1DpA�U7P�t��x��E�*��e�ət/o���0�)q���O�/W�Ĝ˟{�ʹë軅@��8����	K�	����W�=�"2T^�$y�i�t��Q��N�`��-<U�y��݊b�.�S�T�w��-�{k��A'�ǐ�YҤ ���ؒ�񁫆�#�=�@S��r6y�+V�9Nt@��Ή�=*o�6����
߷lVY��e�~��{�,T P׺;O�Q�ښ��������T%$ld���g�r���ny��Qi�TY�
�vf�JY���H�"���ɪ���9rjެ'�	�ct����x�T�������
됃�u%����z�ϖ��B�2��P\�,E���
�Vh�%T?��K��d��E���}�p�1v�K䫰-������b*�O�ܓ�,�����I��e9�C_v�p�/��G��z�q�9��a��n�-�a�"4�ǀ����Me3�2�	R��$��'՟�Z�+e����r��j1AR6#��W4�=B!N�_ ��5F/����Z���g�7���W�P|�M^]_C`�$��5K�����	q�L3��̏�v��y��m��k��^@�M($�T�m��U���J�czd�r Vr�S7B��=��HC9,��7���S@��N�[�
?�O�8c伋�ዼ�4s?PG7�X�af��w��7�+�Q%eڑ3NБʪ�m�=�ߡ���=�_�Zbfy>�
�ܯ���ы���!m�FZ�bݬ�O�֌r�b߇ ),@�*�g{V5��H�_U|~9��5�!Kɒ���'��@�Yѡ�5�e�����(Pƻk�����"�B���M�g�>�K�d)s��<R{F��0#����_qϙ3�����oSF �ו��a�8*R'2I(4$�8>��vq��C�S�o����*@�t���l��V���7������s߇�y+o�[��NE��R���b�+%��~�V�	O,�%�x�J���V&t������!��1C-4iw�	�eE�{K�U��:-Zvc�T�C�=Ƙ�rg��2�e�T�&�z(m'փ����B��=�c�_b���է�I!R4�p��Ke��K���[�t�8�A�I6T���g=� Г|���_�%����� ����6��ʤۈ��so�g�` �h��
�U��݆��"E�~�Lhd56V�i(>�g�T��7���P�ӫ�4˺�Zr]̫�Z�����$�h[6a��y�;�;����e���c��G�UOމ���م��eTiՏ�����6Mg�Va�j�m�*�
�9KOU�K1$�^F6_/li�դ���$0�Oۚԓ,}���A�޻:���>��爍-a��x=��	���nK+�c�V����IQr���?|E��̙�d$�D�rf��s��'�w��o�7I�E7L���3heC1~OWs��8cs_'Ü�����Ox�H�,�L+1��|�'ׁv;p�!"��ї���G���i��@B�Nδ~� �~��<�hx�l�w*�*��k�{~A�9�l����@�p���3�$��1�"X�Yz��p�9(u춑����O�ȃ�/nd���	�n�Vܜ�]��-~mx�O<����\�;Y�g��M�Y�<�Шd�֤�^9�`�[!(�����Ti����/*����c�;�@��$�ј�t=�b�o��r�j,/���?a�����s�8�9��`��ݜ᳊�Sv�Ŵ0ʌ9ϖ�7#��>����=����!��א�Qm?�*�9�g׍�|9Z�Gq���ڈx���g��}/�����������Ѫ}�9y���.��Y��I%XL5Z�lҋ��
�Q::��� >IPyb�.�WY�U��oV(ƽk��[X��QB�"sM?1X8����M��G���-oRK%�I�2�C�º컮�vh�p�~�O����]�>`����%����k��xgCi#���?`������C|7lz���M�N���P	�G]K+��D�4׸�(�I��ɇR<M�v_�'O�L���I��\d4`�æ�� ���=qФ��I9W���ͯ�s�߹����S�G��ܤ�?����	#�����*;��{(,��쉫���Ûޥ��o�,�h0� ����A�ܣ"�3B�r����K��`�u<�e��2�e��ewi<;c-lY�����9�����V�{~�9���8O���e��FV���n|6��W�,̃h> ^��������E�����ߏ$��5__ל՚�T�u��"�d�� �ی�G�|�j�,]�[u|^p�+1�ջa��k��)~�خ�7��fŜ����3���Փ+m�{.S򱓮}0]�_��n�Ij�2VK�����
����&�C�Ń�%
F�,j��wG0�x���D�܏���W��XC��EW/��h��o���T,Dh��ha��]y>2@�H��;[CHw�d�&�~j�t9@�����%e՛�����w��1�ꬩ���`kR�S\�8V�L�Z
ķ���K�ZPLİюW��УEA���S�Up�n��촎U��ݴ��*���)t�\/���5h� �r<!��D����74��-��=���-�ճ����~7�LRyq��gATw.�_:1Y�NG<w���C�O��hh�H[��C��C�|������S��D����Rtod>��#A��EpP���x7��W��Mͭdr9"I#,�l��S��J����0�/�̧_�[x�	�&�Ӣ������������M�Ykcm4��2�9�kxęJO�'aJƌ6��
|w{�,�4.д𱡓i�+
�Sg���W���i�GD���2��R�6f�L�\y�»Fھ����f��(�A<��
&"%fˇ�*X��2 1\��Ott�E}a�{)}�@����ê�b ZA"$��x	�7q5��
��:�nR��O��2haG��4�K�x�mⱠ�
����t:af��L9g��J�W?�6`>^t��p ��cl������P����f�Mm��M�� ݑ��%���B���r�D`N�Tf�V�g�Za��q�{��y)=ZUS/���<'���w�6�-r�Zz`m��֧q���{����@��%��?�=A f�:�>�y�����Ϳa�!�+�+r�`�b�(!P:X���{����-y&�3����,%\i�"&c1*�!��	�z�~�tf�n ��S:��OZ�GP���|�`�X�u�P�D�|;�z��ϝ�_	�� 9�I���#5��D����
�L`��:3�B���OP�Ut^$�fO�,��w���E�7BU��a���?���ڧ�mμ�f��Q|M8��PAb�c7|:}zM0�K��N����N;�ٱ�%ӨT�A�5���'�8��9R�@�L�~6�Б���yj�[Fǥ�\�G9��^m��2�PHŜ��Y���I�s�����rMgT�3������G�$�jl�/x>V���H��g�Y����v�T#Ya���,������X��P�z������ݝ%�{YIeH�Ұ�IQ��|N4Qj�`����q	����^D�ߚ_|o�&��^�-��^��	��r�:s��ݒ���\��C�~-�7^c��{	 b�+>��ExùTn4#�a�j	Q��W{�?���|�X�lO����I\<�h���=o(ң:��oLe�wߍ���d��=�nP6^	��<��2�o��hON��h�D�.l@��B�r8�= èߍIgLU_^��
��k�9R�m�é�VW��e�\ȇYIdM#v�	�����a�(#}�(��{P5K;n�a�x9eY��|4��a)Jc�q
�<��9��on�ôy����r��p���Mu�<_:J����G�&�y$Ʊ���p0�"�M��<_����5�=�4���R��?���-���ܓ<������Z�l��C63��.8��3x���{_�ɘcSf�|r�(cI��nd�e:��L�Y!mt��?2>����8H<hYt�!��>�0r�/�$�L�iM�x�c�6�����55@i�|P��44�)ς
��+��w(o.0��;BcTB-������1J����|$�������@���?l��US���5_�n++���k�E�����HJ���E1#MU���G�|wT�ܿ���a�98:E(HR�����7%�x%%`֤�U�B�H-2�x*8m��B�ҕ��!�TMF�OK�)���3�󍈭"��=��g�}@���G������YCڼЇ�G��Cǽ���`Nw.��QMh�����/"l�^h���������ɻT?���F�=+;c����6�}�U���^4,�]���T�:s�{ |%6'�\��u�
Gkϡ�驶���d�_�{��:��i�����f�$�#�\9��f^<��*���E�v&��i2�������}g������}I���^�����""%�8���� 2l��#�wj�elK��`���i$�{����tݺ
��lKꖗ����Na�������q�I�0 8���0Vw������*��M��7k���V]�*��d-�̵�(ݳ!~��=�Q�JIb�m:e��sW�\�Q��K{`f(�����b�;W��^�֠`�j:�������5O��bm�1"��� WV|��'�;��HX��D�P�P4N.87�9;�C44-"#Qr@�����l�@	�e5 ����#c���>+q>��.I�m���)֐��AB�Ȍ�^{�(��D�zN���IH^3s?I��ׂT����d��L��9iz�M)�l�T��� �}^S�,{��$;��c���?fN����=,k�	�7J���|O�Q
֢u�=�K�    P���îG� ���0S���g�    YZ