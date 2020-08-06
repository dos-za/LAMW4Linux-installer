#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3104723965"
MD5="6a971fec876ea1ab28d8151f1c25496d"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20804"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Thu Aug  6 19:11:06 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 160; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
�7zXZ  �ִF !   �X���Q] �}��JF���.���_k ����)����Gؗ���=��~��]�?Wó�c���3��̚k!qk˪��A�wt0���$ߞ�ġ����go@I���cu�=X?|Wq(q�u��qK����q���~�O�t���_<��j�$"GrX5#Q��.% ۊT���S��*8����N�9��7��k.�\���ޱu������e�}��e���� U�O��mg��:/}"��4)~ɣ���~&E�^nٻ�������Zi�1��
.�d:'�56�s>�����]�����	�?���/	��)rľ�Re�ꞢF6�\�T��f��)������f�leq=�ΗN2ޟ�2[%{���8�Ѣ�'���P�uR��y�yJiȮR���P�t�#F� �(R�G�B�aq)^{�;73w��O�SV��2��I zzʸ�b��`d�J�\��1��-)��o�ń��3�VO���7uC�=|�W#=�R G�x�ţ1��W_�[� ��_/
�z�w�&� m^���l�'�> ����30���6j�;6z'�Ɣ�[�ӵ�đ`�@�\�i�L�#�u:	�/X��Oj��������U�" A��d(�[nܬ+dv@����ݥb���������\�v.�� �U�7k,|{��6P�_��1��(̑F����5�_/XؓFB`�Ȕ+�H{�[��Fv�9ל3���(@��>l&e��eЋ9��>q7��T�\��%�Q�5��/$T�.o{rtA��A4�L&'�G�*a�aba�qc6��q:��f�m�D�k�K�)��(���T���t�mx~�R���J��ʐ�gBN�G��48�}�W�L`Ÿ�)�Ŝ�v��*��q,�M�h�k(��p,/ �sm��(4)'H�G#��QaހY�v��!��5���=�<�������G���
�����D8D
��29��A[���m�@���\�m����!��];�aWY������p�8m�[����r�������jW�i��0Z7�fNJ&�D�E�glߚĻ�ꙁ�|@n�꾛�w���P��e���=�=�m4�
��"���)3�����ӽ�Nď�|����jy;%�K��C�]���-$ᐙ� v/����b���*w�UN����*�
��ېN�9k@�!��K� *��c�0�?� ��<�;�&��u��#��2�����%�MZ`��8쪫љ6$�k/��I�`��d�ń�ɞR>N�S��,PT%#�1�"�%���i�_����v'��,7�s���V��:±X�^`��@�R5�W+�n=�\:!]lj�)�$�L���wz�E;ѵ.��Y�I��|��f�r��'#�`��b�숰�PRV�^��A��;0LW�����)���oCe�1���:g캻`�F�W��][/�J&��r���?X'{�M����j¿�۬ӝ�����?�EZM�}*K�;^����4�>@Ě�n���)�^���0�l}�t����/ �M I+�l��K*��l˅4��z�`.�dE1fQ��C���k[�~Sc$Q��`>��w@�Iy� �Tݨw��{Pd4l~��V�tgd(��=�P�vvH��`�\�O����쉋�J0���*��nM��(���/|�l.F( b��8
��o��L⿈�e�Rn��JS�ƚgڐ�n��ע�vQ::!;�.=�mM"3�A�N���ij�l�ƬZ2�Gu=�~f�=1C"���р׻5$DGu�z��
z,��cuD׳��"F�!g�x]+�S��Lm��EE��{G�����i\������~n.9	 ��g�R�[��ZV���zw�"Ѵ���~���ؙ�ʈ+�H��U�_��u����'R�m�!����u�Z����c()�BP!ٝ����d�'���sZ0'#H�[�<�K��i/�Ol�&�Y���TtO��[���g�t�z*}�z��.���&M�V�~8�+7�k�Y0����^�9lqu����i���1ǼJ��N�u�xf��M��>8$W:���Jfv?=Le��mm���iq��%Y��%7˫�3�5=�p�����v�O�-�����2��0/�� o��6(Am}�ϓ��ɐp�o�4�4�ewZI&9;}��эX�0K/��:��M��d�;~]�V���k��O:�	p��Na�+��^(ꩴJ��"�Ջ*�j�����T	F�VXRiM�	�6��3��7ظ�F1lm��$gEj1��G^ ՛�٨&�R3��\a�J��Q}�%�(������Ey ����3�!����H��?͉X��q�*B5E�k����3��(���z�����W�=�aB�Ĉ�Ǥ>2�{�o�g�����:-{/$�MV�{B�.ɩ����O�cS<K�0F(��:Z���g�������v�ӏ���sȫ�M��G�
W
�����,53��r��� �3�Ff/^t��9����ϨM�x!|���~�C��rԕwUӿwR	)RR�t#;.�2���-�<���a�0����=�$E�}���nĢ^<_]5a	�O�V���y��}�1��{6����' 3�x�~xS��x�0�,�������c�U���闇�d&Ɔ�zت�0M&i-�t��I|~(@��i'��M(�~1�K(�t��n�%��>r�0T'��m����9��!s�T:��<d]s��6��l��0�k7g�i�B#=�]>D	7��v)��Р'��]�4��J�|7䔭*��ؖ�=�k�0�+ʕ� ������t��k!FPODR{����I|�aJ�m���E�*�N�/W2��u/�	�'��#�+:ғO�O�=Ӧ\B�.F~�4��
�Tʍ�ud����'��z	�p	O^�'^�x�R����{�FJĭ��8���?��WB� ��FxltY:�o����$G��:wQ7׏ӕ艓�x}��l�zb1�*		gs��R.�������Y9&A���15b��� �z�TeAAsj���IO�*��ג�{N
���^z7����w/F�3 ��z���|
q�_��@%j6d&��+�ō�=͑j�O���U4���X�3�/�g4��d@shԫ
�v�O�� `X�=��C�?�_jh^��)�������&��za����y~�O�*lR��t�0�q>4�`����xt��jj�zG��������ԉ:�[������)��6��k�1q�����̉�u��<��I���%��m��ɤ�F��{0�X�}=�C9d�����A�֜��ɝ�j��d.y�
�����yJ|J��vť	�)�h��a=�CY�L���}��ˏ�eG�$o��t`EL���UB6��1�\6\�R�v��G	�v�2Ѥ�r�����38!�C��~�� /�z��>>R��39g �w�.߃9��.Q�a�����3"d���6W�~9v�Ǫ���3�6�W*4��tM�4���_Ŗw�T��!���dI�t\��U�Y���~���FZS�E�Pv!�bs�X��^�#F��O�+��!�E��Ƿ�	8�D{�����1z�zʘ���z�]zq�"�e��'�� ��+��Q�����š)?�s �>����mgZ��ɡ�[�L�XS�R�q
��Tg�3�ƍI���~[+�*ʉs�[^�u��_m����<�0_�/ô�HN� o�N���=:}��vo�% <1�v�\'c�'lU�Tp,��)��v���0�ג����8e��fC�
*��M���k�Z�b���&w��Cu�]��=���q�j���<��9*n_�� <V�NILS*�l6�����&mG���6����o�Y��T�O��P�"�F�\VW+u
�f���
�`FY��K����k?���f����K��D	%h�����l@k��k�dΰг]�.���³�dJyV�1�4-�Ǖ AߘH�N:�:�2,X�,k��?����gc^��Vv쳛(���C�x<Q�dw1�Y'� ��'��T�ߝJ�^}�|��Q`[wQJ^�\�Z�Jc�2�#��֌��N���,?������R-�L�����������j-iI�fR���/!х���jni�\���"���ՏC,�n��_��94�1�̻f���&#� <�0N������Rݛ���/�/�kya|+V�LUks�_�t���K4�yq�"�,����ؒ�m?�C!���x^CcQ����D^@y"~Ҽh���*�X��(;��OAM6�J��^��e1�Fy��)�,���	l�n��I�N��"����w��X^$�!X�Q��ɕ)��ׄ0���`10!����h5dX�3ǲ�	R������%
|�����{��%<��B\V���;[��a��cɪ��"��h./x?[n�,p��`g���s$��^L��;/� �<�@�n]�3�Ẳ��݄�]0ۯ�B��z��
���V,�=�M�_��SZ8'*X�}�(�va�
��"˭:_#�t�BK䝌l&���S78a����Df����M��i�3��E�oX�Ƀ=��q0�Y�P���37l�/�P�0�y��B_A���:���e?��jN�ip��$��~W�#[��:���ӟ��{^�~�M���b�i�P_�|�?�a&�Y�|áC�@��&3�	�+ Z��`=,$�#��� �y�v�����0�	4�e�]L��D���Pc/�~�����.�:SIЙɿd.U��D�������%$I�EЙ��`'�GHm���Pb�u}˻:u(�c��p����X#���␟~?u'��� �[|�.�a�G�Le^��諔!O��+X���(Zr�;��`�Q:H��:zZ {&���*�{�ZD�Z���N�n֌�zLn?�,�(���ٗ�PYE��)
�����	zd��h���=��-�O$����x���(�#ach~�n	۲�\��`|`A�w����!'�O̿� 	���U9ƒ}�F�媷�y���thZ��pM�r��WIIz��T�N����B��K��<F��-�p�u��@�;n^vɬd���ؓVi�T�s�
̥��@M(�	Q�<�Y�й��0��\��D��J������	��	�+�^�֮�H�,7�͛%y��CO\��s�Z�t�آ�Jy*2�{�]Wki<n�W��s{��M���
 Ȝ���Ж��	!	��k�(��kJ�;^���u�T�P���c�)
0{��x��_��L��RV�aV�V��c�+��ިr��a��Җs�.!�M����������e�ы��GЗO��i��=s����T����B�_o�z¤�?��:|OW�Y�t涾swbo�ÿ>sf7��w�Eg
x�O�83~�nW찐�z�>��T	���5�L��p �V�й����v��Y~K��vf�K��w����i�h�ob�.z_NR5��IP����~�vSM))upLђ�ԅ������2��߹i��X�a��!p�Q#^<���"�����d1ez�K��Vd^���_݌Ѻ1z�+�����7�b��=`��Z��v�@��8T���k0j��N�;�d8Ϋ���f�����5��?�W���&fSa�Y��ҋ�WC��{Gs�3��2�M����l�����f��E7�[�52`PQ�(H����<�y��W����*)��C� [;B��h�-b�v����e�[� ����ᥳsF�4t=1�����ws>V�'�¢ٰ8$�au�X��V*�/L��,�`��(S5e���ű��> ��>�2Q�,�S�e��y�wy�ا�@Ѩ�Pn�s\*�ST��guي<^�a��Â��Z��e�x&�Ps��HP�g+�`g���Z��y��v�R�����	 5�c`v��`�umb��Kӳ{ĥ{�"y��!��a��@͈��y�+��8pW�_L�c�`]�j8����P�Щ����1k�Ɣ�;wPZ�5�_xG0{&}�`歰�����vzG�:�h���2ȓ��!X��k�~խ�7�Ɖ\�EP"^z���������.�YL�� r;Ȑ�����,Y�[e���b0	�߼ڬ�p������������tR~�¼K��9�ok1;3f�U�]g4�S�`A�nW	xO�����4R1-}wyh�!��?�JS��yH���%��i�K�ts�Α����{~���H��C�S��ŪMg�ХӔL_lS!M}ؠ3
P����&�g/��%)�����������*g�!��~�����'6Ý[��	�9�EP�"��R�A����K��Pې.A��ƋVG��*�n��I��i��$%�G*��)&ڤ� �,nf$�X��`�I��5[���W�3���	�iE�m�'V�Ӕ��r������<@ɴ�{�\^p/tލx?�  �V�՝�20�ҭ��~0?��ѿ�o��������Lt1e�gzx�ע��zyׁǣh���OOo������v���૾@U8ץºp��f'�F[�X��"�����G�i��	 ��!H�i^%X�8������ఌ����0&���X�0,�"�Y�S�X�7D@�gu*���j�7C���t�ٲV�k
�В e[R,���$��F�)Mơb׭��N�F	�C��wm;��T/�ި��I��|-��Y�(�|��}�Rɉt�sD���t�L:�Rd-��-6bl4���[��on��S'h���Y蓹.�<�Y!�P�Zq�m�5Tu�9��f�|nb@����h���J���x��-s�,��]�%�"�_&f���c�͏����z�4�K�0���kn~�jk��~}�o&6�p�z��M�1C:2��V�b�b$E�CT3�/�Y��I#��� !��P=I�sSˠY�����0���df�uF����� ���;�6�0X�}�_ $v�l�C<mr#n{w�XM�Kb�8G(1�ZN҂����L��8Z��1o�E�����X�. V�A�%�҅ܠ����x@"�~�^�I�K�4�#O�+Y(-��ZE��)H]�i�b��)e�����
\NҢ�^�@曉yX<6nT��V�FwLj��X�VLGJroJ0S�7ºn%%�{�$�>��-�	W�](r`�K�sSx�J�;��
,�я����V g�'�d�A�����n[�R'mE�5i��+��v��0=��v۾q���+�]���J��^M��V	Dg)Lu��]����>_k;ֻ�.Uu4�s��[3B=.��J�5��0yPZ�`�f��SE��9������p��}v��,7wx�+<x�{�l��PՄ��'
4~F�j���k:��a�Ԉ�{��{�%KSj]&���-���ᮦ��cT6y���W�X�1מI6��<��Ug�Δ�Gޑ<��zK��N�E�w�Ҽ�>��x��u���%�[ޗ�*�@�<�t$���y��pW�A��������7�I�N�;�,*7�<�-7���vYA'�sU^��=A�u�X���Ҧ��w�]XDb�P��L����i��Rj�}C��]��l�76�QnRڸ�V?X�h�F�g3�6�3Y] �f��iQK�cT���'(}l��bƋF4��@W.kJ�Ǎ�c�{�-[t�z/B��Ts�Q����;d$��� ��R��7��ە)Ը��p_.#�Z_o]�ƘI�k�F�N���+�Q�8���>�rȝ�NL<��Q�����x,���֨b #ڞ7+Y {6I�+�pmM��ש3}�aq��4d�?S��P��ZLpts4a�i���aM�
��, ����s~��kV+�
�^qpFkG���<Wb���(򠆯�M$�w�sy���"h7t�Q�o�����h"�O ��$?��U��
������s�Awe�Sl80��7�F���F<0��:��C���y��,�����t{5����͝�(�r�@]�����W��Sp���e�T"��8��U��H��J���X֢ƸgO-q��̒���h�rҵГ�΃i�H�ױ�m��1n�K��P�X�}a 'SF�up�� �f�3�]k��t��\���J�J�d1 N�BJ[5�ȕ��w�k����!]��W�Y����,��C�-WK	�8�i	G�Y�FX6���*N����?l�����ިF)���q/oCQ~|��^��n�(��<xߑ��,�8Sm�P��n�/��][_��k}w3���:*��8��;T��}L��<|~�ZQ7 ���tk��K'`���5�B�����-:j�+��t g���E�d�}��R����љ_A�����
)���%�l*{����RX�y �_���u������s5��6ϧ��uK��7�e�K'�t����.�����jX��W���@��J�7��T���.�ۊP鱧�O�V�[����k�=�e8��{���";�mpF>����Pg��E7k��c\v]vm8.GsV�9eG�<De}�ߣ�� wY�'�c^�Uկ�p��Rݹ&�Q�AQE��Fc;�cV<�W��A�k�pߎ�5*bCPt�T��7TOh�l8ה�0b)�Hr��L՘YV-�^��2����~(KU��m!�˫1�x�J�h��&D��<�!��悋.{��9�T���,��I��B�@���*q���3��۳��8��!��m���r��'ڍ��ZQ�d+˻Nx"]�A��К��Z��%�t�k�6m�)4�S�mQ�*�
`��Q
"��B�F����= ``�0����x'��3���yP6�9�:ʽ��,�M���%w10}x
��||bp���T�i��`�@���-�(���<�f�2v�RY����aM��S����b��<W �b6/��>݆Q� r�@�
��ܴͳ�?���C"��5�����\F�ȣ��^�b�i'�˿�~*����x|�^dŻ�Ix�F�!<��V�~	�ވ:�U!�ۃ%U�=�!;}��75.��m��a.�#��Ǖ��缰�rm&��v�����:��#S1��y3J�J���.}��8�da)�T�k���.𸯶��ȷ���]��zG�̸#�D�F��]C:č}Jmm��Z�ERF���QG&�L�/�<�ɚ�9%z<����i>����/�KJ]QbʎN<��n��eȮ�����~��4�ܩ��3Z���%��b�9w'(�C�7�(�(/�[���uF��Ll�
��P:���0�(��_�p�U��(ٍ������-��mF.f;Y��P��lȅ{�効s��
�<�|N�Mؗ�a_=<y�Q��_�"O1����%htE����u_D/�z���İ�da�y��R/#���5���ʪi;����v\�=y� ���>����mOI�]�ʭ	���+�~�`���+�p�G���SE�7R�r����A�+.��}��5�L;*w��5��v\�q���Gӈ`�*�A5#\�Z��	�d*}���7��V$>4.Up�W���&-H]fD���ī0L�\fl��y=\�@�\D��p��_����<[�x�^�+a����
t�C]$|~-\��M�4(�-=zĳr���k�!����8 䝜�"�v4�6F]��57�ͣ?Ffȳg��{�4Zܶs�FC��V����|T3�;�M�[x @[K{�S+��J�s�X��D�{��K'i�3��K֢O`�R���`*�W�c��a%�d!O@�q ²��ޭ��ɷ�����|Va��{�>NC����[��ߵv��'�-'S�����a�GR�(f8��ɘ��������f�!�Y���`���x�zQ��������^o�KzQ֢�p�&=IܧJo�w�e%��n�9�q��q�6`X���-�HrW2/^�+�wϏ�t`1�����sXg,K@���7���/�_�mK�}�G��>��;ڭ8o���]����ُ�T:Fʫ�tw>���27ۡ�߬��ύd<
���=^kE�����ʐx�\e,��Ǒ����������G�Vc��v3��BG�*����,26�4��>��@�;fyW��&Q���L5��A4�|2`^�,-@w�@$��>"m���$��T��f�i|R\� +�ϫ����ʡNI�R��܊�8�#u����snW��c���������(�T}!$=w�|�$���v%�OL!҈!;�R�,ֽ��}�H!��t�mI�5��)H����}�h|+��M�U�8�Y
z?�h� <����Q�}{4x�g�/)Lc������x��D�V�c�
Po������=�l��/O��_d(=��7�;̼��=V����`B��=��5h�dE�ϔ�Ѿ��I�pbxIp���S���ߛ���h+����B)D�N���uՖ3�b��er.��[������8㫶غ��I�]	�"�b|Q��,��,�+�O)��'�A���x���?h]-2�D�(��k�*�[���
]����AJ�[3.���>�<��������{���r���� ���o�l�{�<9��l)�#���H���
�([�Q���+=̓�ӷi�NL�59?�X� �S��[���M^����r�N5�FU�8o'5%��EL�Bg-�D��-�gE�r����{n���D�\��ޣV]�
q��$Ce؏��Z��\k��'��MG�Qа�w��sU����%h(zQ����Yye$�}�|?���a!u�:�	�� 7�~�+���wڼ�_P�G�x��E��)�/�@�S���%���0
}�TD|�&��lf��ʪ�)ؚ��6���!����������f��c��ܻ�ư{Y֟�q��CB+I�����������؆�cf�˩��y]H�,���]5W}�d5ıA�Iֻx���b��p�JP{Qa�Ǒx�JhE��m�]DKW� r�ԅs�}�'�n�3�G `I�S��1����ٴO0�[`��`�-�7�=�H?�n�L,�,�p��62�J �4-g�d'�#���Y��݋&C��|�Ku����0-RM#��fڮ�J��7���A�&s�7��I`�{Z�]oȶj��^�������Iщ��'7w���n�˜	^I���p^�X��A��Љ��<���a%×�$m�ZQ��k���;+��GNZ�0��ɸ ��G[s�'k�@��4��Ɇ�,P�]��qW�omP-�ժ(�l@��� ���+����nr�g
Qى(�ca;h2��K��xq��7[-~T�e��ǀ�"�.dЋ�=�yR��X��@_�Ӷ�m��Z���I�ّ�n�^�i+�H�Ny���k��D�q~j�y�GXP7�k\T
N���2c&o�(!=�F�Sz-D0�u���#\D�g���k+�+�2]V�ژEy���4:�PC��S��3��|��U��ψ0e��D�K"�_z[�yL�/��:M%=q9IJ±����$�em���[���?�a�^�dZ�T��̍a���w���;�6ǳ�)�e����H}��M,�'�=LV9Y�c����$V!G�v�5�Ng�ͫ�+�*���<�����F���1D!���F��L���@ ��qAL ���L�i>�R�p�M�`=~wG��@Ȏ0fѼ�T���>u0w�I͙M������i�f����t@�c��g�F���4lm8��v}�h����ady�C-p��j4�42���6�4��!�?�]������f�����:��g�j�@S儣"�w��Tun�kf�㦪�Լ��a`΍��ξyaՄ6A����z��E� �&���n���Q<T	����~�Z����W��=�O+�nQ�I���\�\��&}&&�3��ү��d_L���g�8f��UR��tY"�?�h�;-"ь�bp���	��� �ԣ�
 �7�7+6��b��>3�j�9l-����e����� 嚖�G4�÷�����3�5ZƱ+���,"c=K �JZ`#�'QRH]K x�8�%���\�]3ߺ�CN�q�|FQ+=GJ���<��S��֛�"ܲwc���(��1�3���7��ӎ�i��`�>�%w\'-SW�>N�'�֏R�g�VhP"&��!��"��O1�{t�zx_lb{�%"�������9�I�����p`C�:M/_�s������L��u�E#_��ԞP�[|kRK$�nU��1����L�]��z�/�� �s�k!��*�a������
o�uk^NCz_�^f#�:��F�I��G:1ڧ�6�3�U�Iu�w�T���]--�.��6��]S�3ݩv1��s���G�^��Y�s��m��p&�.Ã ]iEZ������|D�'�;��܄U�dB�첖_x��_d�;2X�EnMI���QKHY)]lՓ�~�C�����w�R �	5j#��K���P��6�alk�/I
*32_�=�tJ�Ec�;$}K�0T�G��y��N<��s;E��gYq}:01��c�o�L4���~���d� A�Tk`�Ϭ���,������*�_^=8D`b�
.^�[䳱�P��ù�Y��;o$�k7��g�*�O���L#��J��ڕ�=L0]RV:��$u�࠺����v=�:2����Ű�����m�1����Dd-�W��t�q8�aMn�<���5װzH�����|2�K�j8l�B�,qb)dbEZd7��x�${��]V�=PA��/i���
I�r���<��X&���}E�n<O��5����q�x�N��魎/E������]O���('_ ʨĔ��k��'�le�G�́�d�_M��%VP��������pVmh�F�*����p�`��=�)#�?Kx��C1kC���.l�p�L)�;��tc"��GRe���`�$�+IU0�D�,WU�PۚZ��p�eM"Ȟ/;o�0"����?̣�N?éN�mq!��.y[�r�-�3.asUC2�(ţu�S5���&Z���I��!�lu�ö�oo�oY�{� S���f9�_�ԓ����t]��ߦ�ڝ��&���8��~�7qO��=�&�:�r�m�"�<ײZW]L�^t�Óo0�S�۳wu},��Ij;r�c����ĭ'�YI(4�}�����B����!���{5L�P�R�ݬ �R�)�O��K��y%��/<-P����#,)����R����&b4fox/Eb�)���l�*ۦ-%�p�˛�8� X�����������֥"��!�0��h�#��~�nS[���j^��}�Al����'|�����,Э��~Վ��7���$򫉍,��̼ͭ΃��Ew��<ڟF �ٿm>�O�������㌾/�Mϰ�a~��k���NJ����z��9!d�{�1P�8,�"��K�@��7�Q��9S��BA���rE�8K��J6,ꉑ��<�$�m�#g���wbO57�U4}p�g�B��fo�3���?��Xb����C&�͑E*�i��׌Wp�2��q=���[ȃ�R�xD�
��V0��ަ!L�La�.
y*�biT{&�ƿ g���i}��=��L�垑^[\�zq:n���h$�G*��o�:n�	ա�=�L)��:�]S��J?����fL�>�qV�����y��c$l3��&�v���dئ%#{Ţ7Ѐ"1�u�R��QP-�%Q��e]�7&�&N�)rI>�iO�ֿ�˒> �4l�H{헃��c	����ݨ�=m% �V�g��X����Ʋ_����ܽ�J$ yO"W�V��߅7oHk@+�C$��r$�����s.�|M|��a�1&����#���f/
�m����n3h��>���a�+�u��ZC�(u.����t`Y��ǲ�'�-	Y3C����ڦ�=�I��a�*�����f� 8�~(�b��~�y��.=VЦ�5|@u"<Ҏ��ۑ6Cu�um�h�Ƽ�h,������i�؟N���W޶V�X���M:W�qH���n����Z3�2��b��~�";�μ��9��(si����˷Z�s���lZt��FzlaBSf�64{S��'ɉU:��GZ���ú�#P�7�G ��2މ.�7���$�>���r+���y������Fe� F�;��N��ԕ3��[½�X�s�R����XỌ�e�%�y�>�x�(]�E)59?v���uE�Z\j)4� �Q!K�g���U ��p�� o��`'j�|2��Wg����#�5��/ǩ꓁l7�Er�H+���>�_�7L�5�Q<R7����&k�KBˬ׶�+G�>�ʚ�W�g_�������P��EI�BN�J�^U�:�]y.�����\��oRJ2F:t�LV�/��J�K)�әs���rs !ު2@�v�0��t���(�@镛V����C�&^3�{B�������.�
���D_�ݼ(�-�"�:hΎ˵���2�ƜR��6XPiD��@���':��06D�����m�u�Z_A�O�p�	���8_�>v�e55@FY���L@��	A������M.N����p͑lQ��c\>M��<�˵c����<-��۾�*���Bx��Q�z�4/�)�ev�z����*��δ�������5�)=�X߅K��?��i��C����n�SK�����8���?l�7�Gz�M�q(i���x�������� YaQ0�x���' m?�������`� ��(<��G��:��I���s�E��E��z��N?��I0k�)�A��Y�큋(&�#�$"EԜ�{���+����t诿i:����v�h�vx o���W0��Y�pUĆ��@���R�l�dM�Y�(�� ]BCU��;sJ��8A4�%y�O\��E��mp���Q��y������5��k�/�zI�ͻ�I�!����y�[mTԆ*{X��5���֗��	.�����\]�06P�u�!�O�ӻ:�	M*�{-���=��N�]�sk"#�*���|Aҳ���ȗo�YQ�8�� ?�(άz����^0,�8�H�@���,�Y�Y��FeP)+hQH�B�8I$ӥ��[3HOW ��
�@�F�	���I�T㵈B%%���u��<h�e�����,�Z5�17��:���hX�_ۿ���f\�Wc��>�P�"�3��ko�6�v�}c��w�
��\g�nj`B/Sv���#��uj��G�8�F�Q�@C?ݟ���1?Ol��� 
F��i���a�.Z
KQ��K�I��魣$`�c���Oe��
�����d�m�I5ҳx��-e+��b�g�I~�-^P�iU1N�fh	����j����<O�6i���ƅ������)��ƖI2'��벭��Eg�<�����EZ~I5�����!E?}ՀƼT(o�=�]��.��Ya�M�<V��P���K�f+�r	әo������|�u�~�4���8Ju
���ig]�������B�sM�|Av^��emOX�.��zx̔peFq��,@0!�z{2]�V���<�q�N	#�x��*8O5
������݆�S�!z�w�t�:G!��N� Y�<V'�wQdnφvh���!Q�*�S�{XO�@��+N���(W��PE����NůZwv����ei�F�"��ã������"�e/�S�8���vR�D�o���P�26�4d�?|�8b���+���Z�
��NY�3��|zQ���9$�kp�'�[�Jpbo	v>=w�h�Q�9�+�۽EJ|{�g��"�[y�����{2kx��BE��=l� ��,W(��x�<��E��t���U_w��}������D�'DlF���ߒ")M���WT$;����;�D�����Ť��`��>�((�[��ג����?�LZ�(���\yT���痳5e<wU�]Hg���m���2�Tl�I˖_z�r|��eU��l��E�b���k=�Uz�0~�3pϺ�q��u0t&x-p��w��O���Qg:�HXԭao��$�.T�5��'M�Q��o��D�p*�1����k"�J����B��F�p�_�t�M-���u��%1�zFy�e��Y��j�H�8{��Q&#�DuyX�Bqy����Ax��K����`�Z�κ�����]�+�SY�V�k��1�+A��(�d3���)T���g��>f�����4f��51��xS��=�u.s�x��2��u�Xν�ڈ������_�i&�8��N�նt[۴nj��W�#C�WnۗqJ�o���Q�=�(y�:H��Q4Q���Y�+��T�F�A��ѧ$�2F�V��嚺L)_ҮA��ϓ������[�ӊoog�[��_�$-�wV����4��Jy����ӉeV_�73F`��E�}���qTH 0a�ag+���q�:�J��y�2� p;���;��e����HO�x��Z9��!�ɀf��Y��'����0Ń{�~l�$��6�fY���VB��"Lś��*Z{y}g��kޒY��aZ���n�㫩:�\�[���b6kR�_,�BeU��?8k*�m��������uH�q�t�
�O��us��U�ە;�A��IS�X+a�@8I�)�����\e@�Zp�S�ao��Rg�#d7IM@���Ft]�*z55��Uf;}�Ǐ�ƓT�3��!Lc
�Ѥ��.U�a.<��G3�?�0]\��
l�⬀J/l.L��X*�o� ��0�����N�5{M�|�Z�шq����@FЬ�ݰ�
�����D�F[��_��2����S���\��$S�.㐀���VY�76X��h&6���B�'A�%7�b�Q�Ȋ�i4�p@<Q/�3Ϝ�3""|o�o�%��h���3O̘�u�����zm,��n�=�pq��%����bMv����̕^�(��1�v˟qL�yҶ
n\�iW��Y�ģ#ة�X�?���I�TQ5���$�h#�g�:��؛��V�'��v��+��6O��K�E*<E�@5xψL�N���F����M�o��W����y�rg�]iA���n�sChzUG<'4�e�x���x��7���b}�u@}V	��oq��nY�`�֡�>�@�<ٱk0����g��g��Y�ÌC�Y�4�`ʣ�&�43R�S��[:��]v���j�'Y񖳻���J��z�*��F1P `��B�ӊe�:�⾌A��a���G�$g+�8���xCB����ؑ*ǭ�o�j�hx[�Hɂ,�*���m�^��B�Io�יR�hoA�Ej����d��j�MS][:\�%f*m�a��Gۍ�M6-�� ���1�@"����X@�ȼ��6��\~�?k�Բ>�=�
ߩ��E��4T�,П\.�
�b\���ò�-���h��V|���x�M���L��;ҷ��t�k���㙼$㋪f����s��~�놝��'��S�X��]<}ٖR���-��LOuC|�����RՊ�n������ǂ��`�[۠�� � S�_����֐V���Yh�oD׷VԵ��(�/<�^�����Y�m�ʫ�[�YC�!sח'o tGm!��5�p�>�0%Sq�dk4�5��U�_R�DNJ�p���(?z:�dj6���&��R�fL�${�Z�%��a�痝ls�ʢ�|��CSܪ⧙��1���KkÑ�Η�/���	4=�t��:Uq��V���S���{�����W�dM���H�|�w�6������BG���g�`/ -�p�D遬��ݟ�Ց�k��T9�UA�U�E[����]lV���מ����9�"�ϊ{�孓�zm�\�FC��-;�u��§�%	ZÐq��p]r��S}[�r��Z���ߠ��(�~��s8��w��1|�B� �	2ʶ�*DE�h]����Z�>��N����Q��L�"W6箩,�fq��<�
a �����W������R�Ws�1���@��1!؛]��w\�"�M�9�%��a��P��S��x`�G���UP?�I��d$�<h%*��>�_��O�k�P,�Q��~��]�ض����!'��� LBՆ���������@�j0:Oؗ��wW���ӕm��|�Q�Wсr��o:x��K��R�|e��cQ^�o��S��7qN���.��{I�Fڬ'��]g���}~,NOU�FY[��C�|�
j�C��r�`��������'@F*�{۞����n#���Ŏ���g�>�}�����ǲ"j*��:��@��"ۙ��6#�ͯ�� P!�`�c���gB~����۟L�ES�H&�Ciy\s'D]S:QV���@ce�.��ڴ#��/Y%��v����K�"��:����OC
�����*��S�m,�Pj�k �n	�{�Ukl��~n�C��N*iXg��J�H�m�O�3�����t*��@(|LHRd����Ð�+��˾r
�K1I�e̳t
d�	|���o�N��(�l�D��d�.{�X�{Y�Z��Cd.'�6�z�ޟ�z���ji>�4fpI��sJ��F,�"��K����9���$�O��Ѳ�m��r�qt�	b��ݡ�}�:��)�J|��	u���3�gڪ��Q�7O�Mhu}��\A��:0�5e/�bU�(K�j��/IZs�R��r�'�ҽ���&��6����H���x���Pc,��z�w�-�r�E_��<�k�Ȱ�m���]rp����Z�iP���WŻ���OYt��͆��H��o�x�׉�����!�_p�����j���6^�a�~��IAW.���<4�/ί	0���uL��1p��C�a�޺k:�I����{sh1G{Y�5�����V`ܖjE9�H�R��ᔄ;��.�݃�@uz81u�
|R؎??���[�K7s��ԟ�񾀋�����l��{K�Nt쬡(�&��g@EG�5"�C�|�|�U^�P��fD�R'�������sD17��fU�o�ˋi���ì{�7�Y3OSo����<췹PKnm�D���:.������0|�eR�︍�Y~���UP^[vµa�<��Ւm[�����4�E����WMn_����b����ܥ	�WH�Ʈ�ŭ�v��4��^��� �ӿ������d�c�q�FMT���89���?���Ҷ��(��Ӹ������bf���	p-'�s���82��7��>y���1|Y�\����S��E��sH�prh����K0��3�; �w�*bk�NF?�[��`:����"�z  �����GAJ�ɓ�^h+>4�RȘ�P9�>�I�y��O�,��H���Rj�*�q�oQ����x�J��C�(��O��.�Q*�	�y��Ub�cn�T���B�.�!�h�n��q�Vǭ~Nj�����Lu5����~g�_��Y�q[���$#<Y3��`��~65���7�;�$���<iV�c�a%t�F��&>� mqwl�³�����M}���%18!8����.Po+k�$�j3������E�+��N�j�ᗅ��T�8}ׄ�s�
>s���[#�)��E�U��+�0ye �i����w�|8���	gøI]l�M��	3�Ã��䜨�p���|�_=��96Ϣ8�^��z��pu�M��-ҍ0cR*^�#y��S��Aa�c�u �*�3~�&ψ��E#��e�\IJ�V����3��ѷ���ϲ�O�xz�Ǝ���ƻ��t���V�*:<̍�G�B�3�T���X�5��[J���������v������ 3uzE�[��OT�wߥ���s���`k6_%{��D
M�pA�§V��j!���s��ͺn��g8�Sx���!���!cד7�{|�		�n�b��Y9�����H@��k5����i� �7����VA��x�e�`Å=2�Hiv���ɓ}6��CmU&Z�3_N��� ־�#��JxY�:��y�&�T�A�2t#l�C^~I�I�5T����Z]�r��Քycm�
m�1%^͊����mx�@��˛_`h�!�C{�3��R�] �A���m��J����s�9�b�u�oq�8a��/?V���	��tn��4���#��O	��af��"ٯ��i���n^��+)l\�+mz���[����"i;W���ZNP���3R^�p:����<
�k��l͎ޝ#+-[ܝ��P��$H��x��^S�|�L�?� :𴪀 !���*����nq��s
4��;փ�#��Vy�j�5^���c!��g��ٟ�O�r�=�����92�?vf����N$%Aa$���qou�j�FT����;���3�g���J�S�R��p�x��A�S�RB��g8�q�p*��������+Q��I�wX���a�:agL���@2�A�&j����S�&��h��U�ݐ�)J��Vp�1���Q�zz��RT�e|E��0�7)c��HK���YM�bASz�k�P���j��j�����A��g���,=m�xG��H_���8!P TM0mZd.K�֝G4�i�q~������ӽS:whƫ�J1��������e�����K����঴͒U3;�Qa����6�:}�:�p��H��=��5.�S?�t:�   ����G�� ����!
3��g�    YZ