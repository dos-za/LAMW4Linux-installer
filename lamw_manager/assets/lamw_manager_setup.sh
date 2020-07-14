#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1214482643"
MD5="2f2dc8d15eacb323ca3ffad99161b08a"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21300"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 14 17:38:26 -03 2020
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 140; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
�7zXZ  �ִF !   �X���R�] �}��JF���.���_j��7�mtr��	��BE(���>�<�Si
��r��'hLU�Cn�$\ts��elsW�g��>��V�F#�J�P�>�"Q:h���E��^ފ DB%�Z��e=��>Q��!�ZԼ��]�¬1V'Q�Xu�x��v��d�ս4�O���Sޡ'914���)uQ����V̲A�>i����ٜ#�=�)�\���1�2�~}ϙ���#1=��胑o��w�c�f�
K��}N�(톸8;��Pڸ��*��m~���Qa�"EiA78��PR��2Fİ7Fy����Θ�sP)z/�S���~7���Ѱ�dO��=�e�0�<���l�ނ�o�7
�ir�W����.p6זK�>�H�~�q�]:~ Bd�S��7b,O+���Q |j�H����'ߧ%�q
�ŭip�K��Q%H%�=nIk�t�aW/69��,��߻��n_.���h.Ť�f���?��{�*�}FuF|X�Ĵ˵D56d��V)1�p�#�*�-���pL�����6z�
��s��'j�k��mR�c}�K�
�70�����)QH�����\�]u�r4�h^�A[���DP�7D:QP]� ��S�2)T��.W�b&�z����-%{�BV�3>ؖ�� �J�i&ىV��r�Z�;[�S�������ڔ�x�� "aO���0ރS�OKk$d��k�␙ҭ�_���*��z�!�k3dp٤X�b��y��6�Fq���j�ĵ�F�FJ��pBm�����t��2	)�H�f���g
�
o� |�Ө��@�Q0`��}��J�Y�ZD��C��Z��Z�s�X�{��y�Q�f���aY�ε6�ʠ^� ������;_Tk��.m�Ҥ���T������#����,Ի d.����8/����X{�V��V6�W~��)�Kv޳K���B\��n$���f��l��a��KEX�R"Ƀ-�X9>����jD,��D�����ľࡕ�f�^-� u��=��cU�5��*�����ٺ�������x�8�3p�I�h��B� 7�J7�Oa�V���av��D�vBM��k�	�k��&��ȁYx'�jl{CܑSS6��[��(�6�#"��$Ӌ�q����J�x��I�K��L掟��~�e��¼�+� �M��^�:���4�B��4�?�G*�ܜ2�<˕#�rCE�i�4#|�ӚIӜ^Y�#$���E���(2��!V B(��%�O&}&�ף�M�@�o�Y+��Ҟ1[�%5�{!O3�֤oi�F�����<U���+���s�TS��|ҋ1k�vGV�E�ό����^y�r�#|mKV�����RF7���>y�q����E�|�p�Ҷ�!���V�\;�MG��{��P��A�+|2��1E&���X?��^��
mO�I��V�c�x �I���S2ğ('��w;��O�!�}�֫3�-�Q
'*�� ��B���,nV�_c&����ZYWa�Tq@��*��
�5#��չ��S5�h�le�a]���T���8�O�ۤD�>ξG�gSz��K�W�S���-v>���ƅ@C@!���UeԌ�:i*�$vzә�����&<��4�l@����@�V:�˗m��>E@�l����	�0���Ko"Vʄ�x�R����,�<�5���r]��#+2��?D�2=���p	G��k�墌M7>���%2�w\�!��a-g���6�Rn�d�KЏ�I�Q�WJ�n��47Ԭ�@�ÿ��]ڝ�a�K��������!o��\ϗ�bU�g�ʱ������Jt���5���4���Ƽ#j��5���AIW*u�62��2�Ў�q�@������`T�@��yUK�>�}װ��9x-�.Yږ�4�X�`.�ė������k���?��`�0�z��%9w?�tJm���<�sb)�9V�ϳn�
����X��~M�G�6y"��,�T�����L�&>,�9,��юO�t���,2��,��<�f�����mr$�̟�T���d[*б�t	�]�z��)�M\U�l�)���_�ܜ��ۮnN@� ��*��j��j�?9���y X�+=� ^h��@RJ
������L��vr��g��ZOi[��*��
6ɪ׾{��ψ!�����V-�ǀ���Hl?�8s!&�ۤ:�z
M$q"�3�T��/X��J��9�y��*��s2��E$�;�H���_�odp i�t}B���|�J�������Q�J塰%w,'��J�+<�=4h�vF���Dq���Ԩ���釵�J���K�OP/�{5�D���7�/#��ZPQr{j�~�]���Eb��
��7�^���>�������2P�mAu^/Hn�Ӡ��&*=���u��p_�n�P����������Lތw���}��>_�N�
B�MJ�Kf�mlŰ���DPՐ����(n�D�wTk�rȾ�P�[0�^~"��@`A�5�.�s�f$�%�@G�����h?�-Ej���)���%H�3��v�zO���W��m�S$]Z�_�.n�@C6��GA!44��:}'��j�n��
�xZ2��ˁIqsDQ�r�{w�{xV�5W]���m��su���O��xL�A��p/�&(X�b`���TWbњiΔ��۠ぐka?.3Ѥ�^�pL����5���͙n����Rh�-H�*�{�Fbؼx�?�m� ���$k�(v��x�\3�E<<uB�^�4��\��t������|à#O�E%y0���M����Rd�Fǅ��?���185Z�e�):0�#y��%�@5J.M��1��p����ѽN��P�.�uL�B3c������VC�ve>���^]E��DDu4s5��	T�qN�4�=���O�)�9��F�N��Y�8�U�Y&�k/GSL�9D���#"��䄂�T7�eEÌ���ф��XQ�i���s1nC�TĘ��OAJ���vv�5f]�İ{��%��~�/�DX���6>Cmo1��8L�<L�>Z��iq�r�C6\�%y^�3?�t]�]���U�%�03`�����ۂ��g�:m��>��j���^�cF�����q�e���Vw��3��g��<F �5�=0���B��q����H��Nvؽ+��Lk�K��Xm�9�AU?�Q��C���/����TP���6I	G�Z�M�٨�6Z���NI����q��^�Oϖb�+�Tk4<����]�M�x���ׂK�㠶濣��Ȃc�:1|.��?�'�� �&���H�����%�����9���Ի~e8�B^|#U�Ez=-��^�'��S��mx��%�5�e����En�S~�Y�Q�Z,=	/V�d���v���>�!k�^�s���x!99g��f��^p�	B�J��+�����'W<M��4y�T��+}o3.ٳ?���6kDʛsp��<0#��J�Ae�R!	����3�����Ø��1�0&O-}���# >c�!rc�Nͽ-̀14VI�N������ٗ�Tix�2��WAC9���?�X
�$Ѓ�z�p�2.[�*)�1�J��K4h�+�|�� ����r��Ś�|"v��HoD�����K���%Í9��*Ll�\�5��2?�sRQ6P~Lvj���!C+�#b��I��S�=���1'[�*$����!?������'"�ŕ/M�o�;U\��	�W	�J��l�e�{y�z�X��on]l/����{�BYbxO�<��,&�h#qΑK�����*k���+z�;����g�Z`�ш�Z�|� �T�v����s�y�RM� ��W�2L蚸�9�/=�C��ac�71G�u'�
�%o�o�۟�"�6�Ӌ��p�%?f�޺������3����b���Y�� ��;_�w �YV0Àh���y5@HǏ.����]+��m�{�6��Z}sK�U�R	vĨ>�Ȼ'�pM�7�Q��§.
z�O<9���9�_�:��������vN��5���X	"ܺ�vD�ǟ[��::��i-�A���C���s m ��h����we���T���5��L`z��or���jj�Y���	�i�X��$�6����0q?FrШ4=5&r���y�,��8-�<���cSgN��Y �5m%�����l('��'���%s����w�\1�A���~��u�Hrv�8'i�.\���/��60��2�K�=x{�DÉ�V�{�|�RIu2�G�^{������C�%f���������µw��D�7~���tQ(��� [X����5��L�;P6���g���G��N���gFޱ�;�f�m��z�-	�epŶ`�mjcT�$��x&��F>te�d�gMw_��C-�U�(Cܩ]Py�i��m3��n�$jo��e�gQX�+&Is�">
�c;_ؤ%�Ղ{�	|ۄaE�CD����9D�2$w&��yz��Я�@�����ͳ�ႈ��5O�����m��Y�	@���ͭ����
��.�	w��Gj�5�#{�Q^��qY%peHMz#����.�W�	t�sҁ$����@s�c�g]NOb�'����I����4����>D�MJ�D8��#�i	��+��}_V��j!�#`�`O[��3!���B�9�����lqr��ȳd�����=@�Υ�d__E^/FH�w���A��G�k��`G4���/Y�e��+�����w"�ӆMB�X�ns�s�Ox�@[B��ǲ�@�����~�������[1n�Q��2��&z� g�(�+�ʭ|�۬".z�k�����"�ËH�ܶ�����t�ni#�u�{ݫ��&19����*Řg@	��x��&�o��,T�l���B�Նcm���pUO��7���Q�'~l��k6�N��<�{ͱ|�[��:ӗe��G,53�-\��������r��N�
�r�X}�
&G7��|�����o�4p��+U�����+-�s��mKS����D��8Oʖ�l�铮qaE�����)>[����e�.K~����D��v�-L4~����ܥ�����w�b����ϲ\9D>�n%ԩ�vg�k��yQ�1�,?�g�a4dbaz���s���O��9l�@���ȣ��U��FΟu�̓ȥ�{�L�yH>���\��@R�ʅ�G�%u�:1�ʇ�G�`װ����
n*w_��x}AqQU(��N�~8������^�>�g��5��bK�
�5@��7P��;\m��^�-�ʭ��0:���u=*����='Y$��/�����d}Zڢ9��EN�|�c!��.�ˡFL�#3�:{��s=.PZW���>]�Kʮ�Q!��̭K�?ۓ��Vѝ�d�,O�c�Kv�����b-��y�z�A$Zb�����®jڞ�=G�2.Ř�c����6�֟V�!.�҈b�g} ���ʭ�ԟ��-���`n�)蝥%%�����SJ͒U��T)pƍ��9,�� ej�,���Ӧ)>�'ŔFM�M��(ųOK"Ʈ��Ɍhߞ�$��&��4�򒹎�"ja]ׅ��m䲰�d;Ԗ�Te�s}�:*S��zk^���ö+=�<f�&{ԿP���������p`*'+�2�1jnxM����~\b�ҳ�Oh�ǲY]ó��w����PE�������}�{�8���}ʇ�|�o&k�Bk�"�X^�ww�0�ha�dY�����9@���G��=Dw�j>)dv�Kc.�U�%S.���$%.e��0Je��0�<%�%��s�A/�2'*�q� 6�q��+`t_.�ra-,+���I_>	z�*t�\ndA^�Z��4���F�c=q*����ɡ�/Z����^~�<��g�f�hT�D�^�>��;Qz)!̼l��K�j�K<NSv[�v�웞�j8�����(�G����`g;ajJ���m��[:��Y�z���Rv�AEPG�XoFW����pT(( ��������U��-n�z�0s���6Ӡ��c�9ٖ�4s����?p���B-�YM���k��(P.�#��ݘ��'Ora6(;�� ��\b�a]!��0<�(D�4s�
pM��t�p8�bn=���gHa~�K��W�5}J�M0�:�x�2��������F[*��d8G\�${I "�nK�+;�xch����C�l���4�1�띇oHڣ��w���-�~�/�t���4�h��5	,#�a���AN~J���"��y��%��Kȷ�Y���v�ͼK��&��$�l��O�Ȉ�U��O���H/vr����,���Y- ,P�{�Nv8��'�0��.
��+l��Hj�W����ڹ[C�y�9���0^q��Z��nx���P����Fݿh����=i k���7�zᓚ����V���Z':���#a�סh���&F�WP�&��B��8Y ���Kv��2�K�]D����*�L�)_"<+�3N��wةL�NwBC�7�u�-��rx�yhS7)�;!����|�d���4z��Oz�$O�MF�W��	��#���~L.͙�ꗊ�ÕPY���tfL�U5�v\	qb0�;Cbnow�|�D�_�[�l� o����y�xΏ��s�ԣ�F�o���"?p�Ԭ� i�2\c�bIՏcdd�ſZ���"�d�}U�h��3u�yn{������g�ԤJL���d�m�Dp��:d�!����<�����ټ<9�<�ފ�p�j�py�+d�'e�U�EYM�j�(L����1�RA��2Hh�e�U%�5��S�����U0��/��x�꜄�k1�!��`�Ov��%B��yN����7G��Xl�.ig���}r�x�~T����m��,HPw�Jay�a��᪚�w���0D;(�F�*$��Yi�;y�C�����ѱ�}37��v��S�Dh�X���0$ۢ+T���\vӖ8k��9~�l�P��Q�pb��)��WK8�<�G�g-H��7������$���G�9����8�`u��G�$Mp�C���Z�#\J�Ԝ��#lu+��k7��2yDU���r�֔�@w��	8��!�����ͱ�X�Ds�wO�@��ճ��OtB)�T�Z������sy߲�VŖ������<QU�=0����'��%��T�i^��f��7�͆!W-i�O"�}����/�ȇnb�&b�5_�Y֢�I�
@qx粼Uϵuo�X��E/p�'�+��d�>��Ų�����(K��N�}��,���n'<�M��#ږ��%��EKa��%cb/�d��(f�w�mijw���_G%7�z��"As���MpH��c�S��\!�5-
`ʕ.�Ԯ:��&�s��}�37/ 	T�H҈5Db�g�X��m�T�xf�R�,�?+YB5�M�w���� ϛ�b��-�Ua;�0��|�z����}O���BcO ��57�_#�A'Z
q<����I�H��ըex_A x)i�󘊙1�B��(Q����$Q�co&���Z�wM�B;��+���I��jV~����)����N�������na#��!\��k��k��cOc� b��b��n���ӵ�B��TLS
�@0�-�����䗅<0L�ִ�����B�Xf������Z[�s�a1�Z��Y9��s���'խs"�L<�8[m���)GG_�s�����STfdPִ�w�IC�
ZdȾ�2�n�����|ff�<�C���{���S3I�^LgY�b}�������o��
�;)R��p���.T��Xa���6c]�%�!>�e�<I�V?�E��Dr���+�E�e;i_��,��?������`L�<�U�ЮM��`1"{�ҥp��F��h�;��J�6~��X��:�ϋq��Kz�o,˯*�M�X�F^�߳�N�6��
�v�꠯M\O��sX�����~��C�;U`v�k��E��c(Q�g��jS�������_{�6�����������x��V��b5JU[�G�RB2B����5x8m��A�
�"���*_���;C���|�?c��ⷝv���h����)gN�}��܏�_������'p��n�г,&bT�w��xc�����o2�x����!�$��8c��`$��r��n8R\X��l��;�-��B(�t:u��e25���#������֛���{/b伺����9*է��MUQ����H�gѦ�^.��V�2�_	��u������`��������z4Т�̜�х7�Z��h2[UvE��M	�f�+�����OH��D�"D������D{ʻk~����a�:i�j:UDι��} ���#�>�M|���EZ/8����CUu�m5�ʃ:�f��Xe�&�oKR��ڜ<p���nңq�%4���S�5����٢3)�[�l�pZV��Y�֧$W��@O�Ev���-�E�V�j���g� .�Gޝ�����`b�$zT)��v���]���Z
C��Gl��ս����4-$�i��y� C�v	��ܜ>�%�J@M�$2�������PJfý�FJJ�� d�J��G�P�BO�_�(i�;J�XK~[��5�{ᐷ��eJoe��P�<2�P��~�Br}�\�Kaz7`����F}���/�V�Md��$:�_2���.�R�=�қq�S0!����i+~茹��1~'��G����4�-}	 ��U�?�+�џ�����#���`���9?4�_C��Nft�,�/�[PtTŁUګ=ҙ�-�Ru���ɕ|���W��z$Z3��ͷ3#�g�������'���������{�R;�!j�8�X)u6����(��V�t#�c[�:�~EA�a�<�ջ�pJl�?H}�^L6gǉs��}�k�}�N��fe��g�T9�0�>��w���X�Y�����¼���^��j��U8��x���RFoy�fu�����' !�i��VW#�8'H ]�VRT��F�L�a)�1�������{�5p���ӛ"�
��&
gak	[�hYB���k+<�`>�m��Û&'s>�������n���,��Fy��ڶ���<�p�h��L
Ln-��H!+�$�'����8c��ayA�am��qy�i�����FB�6����Ÿ^�y��I���Hga����}�ߓ*�Oc��&s- 3�f9�AS���R��A��y�ȍ�,zj�>J|7��Ѳ?_��*t6O_�:��2�z$�-*y'�`�t�vWx�����ṫ�BQ�K2f�����m�23.��D��'_����n��ό�ygvE��ہ6/��xC�ci��>P)��^�c,Y�$���-�%?]򩥁g�D�x�9�q����*FEW���X4�OǛo��1e�Mbm5�#8 =������|h�Z�6TW��K��q�ˮ��$
c�V�,-дe��Ub�bL�5�����TܗU-�?�I-���5�,9)��m�|=η�Bn��A��
m���Ĥ�b4>'�� ��_���*Iߦ?��VT�+ÿ���D>��
����ݤ?B�@:3��-�N�d�x'M��"��%_:�	^��V�*��v]�g{&�DO5�c�>�sfxB,'h�;`ŷ�?�E����B���hv��$��0"��5t��I�	����G<M�
]����R���y��;��tQ/	�z�V�ڎ��v��%��Q����{#��֋O��<��o9ǭ�+��!/�f��-��^"it�+;���.���",�t�} ��c�A�X��SO߅ŖU1]����!��8��.Ȭ�s��%�����e���+&m�F�8l�S�ŷEٟ�o9��ב�F9-��ɍ�JCCѠ!<�v*���!���RфAgȊ�9W�q*&�`�g$@(�iO��@W�}��	�w�;��-���}��Re�<����㞽n�L���U��i�G����,����&~����J0[�s��c��^�_�)+�hB^�+#
�oze	�Q=ǔHa0�;~�3���d�x�4��x�FG�����ω�1�BPK�ںK�+qc=ZJƻ,�Ԏ޴.�7�^Q4dמ2�q~���sQ�V��9.��τ��d��{��s㴆�����ҟs��Z��	$�D���׆7��@e�֣�E���"4+8�D7�>&�k�9S��Kr�{�6F����<B�l�f�B_2_�7dO�>�s5�sK�;�L�� 1�"M�k�օf�n�j���y`�0��&{�	:���H� F�T�b?Z0��ԷO�T�8��AX��wBAN}Sei~�)4$u�6.��%	lڅ�~�Y	��H��O�V�lX�<O5�Rq�Z�r��z.m�Q�5�H����mo���oW�����ް
�8�8��p�|Pt���.�N���%t�W���5�(�44�f�=�h�Ui�����7N�����.���g�rm��IL/;߀��d�^M��$7u�jqM���iAvgh�D9p�7�mKق�����z�]7�6���dч�T��X}��T�h�ڐ�GcK��Y��f��u62���JG^Z��9$x~�x���Xx�t��k����[G¥���v&d�h&J�l�X�YW4�ٱLl�<��\�3?(���P�?�˔$=������b@�����F��aZ�X�u��F����J��5`�W���y�g!0�Q��P.��`q/%xNbsF>�#�ٚG�L���z�Pt˕\�P�I��Jn�FVCu�CW.C�rs��^Ax�$W�*�3�O�X�@B9���6�6ԫ�Z���w�Jp��4FgMn�
V���}�v��9��3�$5����m�,k¢흓������4�&�����&$Ũ�T"A8T�%��j����t��(/��鶰�a���g���p��Q�Y�tb3�CYv�1ՙ��e���O��o)�ӂ�]o�WD5?�.�)�dg�;ߗ�o�.DO�L�[���L$�͇?_I��X.si98���9t���U)����x8��TzDJ��� ޵Uc@�|������B
?���7U?)ˊ囑����l<{'e2���*J�,�	�`��'l��5���aj�O�H��`��˧�5�Ƕ�"�Q{���r#׭��\���#w�o���N��_�pu�����*��O��d�SF�]���;5��M�ǸDmǞ�jiyT��,<���j�݂�� F��v�e��wj;�E=�l�$<��g���K�u��~KK��hS�5�BH��ƫ�_���1�D���8'�4�h��O����F!�+c	;��\"Ma�ݖ���S2�%�T�D�F �����w}��@)�]�}����6p�X��_��D1d�cT�hvw�0�|rF9p3�����k���+��z������.C�t�*%iH������]M#F�}��v�J�$ڭ)�������t���G-�%���}o\A@Ԗ=@����P3���4�g����j|�������;���3y���%j�W	m�+�:^HDZ�����9�pG��$v%�N�\���,���2��P=����'�(������(PK�g���h��e���ތ�bS;e�����5@��U��`?(�=jn���/�����=��ov�}���t��7ϔ��9�R�f�2����/.�����e%�͈��f�Cn�9|ς�P��1!��Z���B�`��F���"H�_�&TݤMPr�?v\bД6$�/�a6�Aj_I�T�H���X㍝v5�Un���Gs����'?�&�!�|�q����^���&��
o4�`y��rb�������~^՘H˙u�6�������	���+��G3P]z����9e�38�������&bk2<I��yO��ՠ���Z��V]ik�����}�,*c\O�Rs_��VlJR���mb�ة�(OAM��?�~E�a�-��T�2Vl�G�P�p��������/�[����4M��w��"y9\*��c�|=������}����gk2�.�7��BA��%[��l�S�fN�k�����un%����Yƈ��n%�?�C��]h^�O���m�������69�l�@ll��XO�.��e�I�4��*7�vA¶j-�Q��u�S_,���a�س��2y��\�����،�΂�in���o�F�,���p(F�{�ow�f���.ЊM�6�������i5��W���u΢�
�r�58l?肇:��N��$f�ꕶ~���J����bM��d�[EB�B�ԓ
��z�r �z|S�.f: �I��sȢE�Î���À�7�IDf7��'	����Յu�>��O��{04.~
rɢմH�>H�nK��bT��>�sJ�!ވ�Ա��f�f̦���e��FKz�D�}�B�T]�v�`�'�'̙�Y�C��ܡa���P����n�M��)S֋�?�Fz�u��{%]H �;�j��Z��SxF���C�m��B�ZbL�I�XA?]{?�zE|��A�M���l`-Oƻ�Ʃ��?�l������	8�2UX���}���qR�e�H��!i	�v��ɖ����=�w�_�A������?˖�2f&˕tm���-8�{me�X�8�Iն4�%���6���v���R`��.����2��4�JKXc_d�Е̓�1I���O�K��w�A^��V�����O� !�q=��G�(�
b��������T���W��ԲU�7�ǆ��Dd3jb�V�i	��*e���+��Ę߃e�%]����Z?����v5�^s 2�@�ߊ&�5p@�L,Ë��/���0B�#����oeA��#:hUu��s�'ll��|d5�p�rG��l`�)���n?��h�y�Ra��s�>qn¾.�`T�(�SN�u?]�<#(�A��ĺת��UY��Z���[�����_�>  �}��T?_���5
��ʏ$�ܘP��u��Zx�*9�[C����B�0P5w�ᱢ�"|��,;��=;`@�\R��m,cG�iU�FI#dC���ٴV� J\�H� ��!2x6I_qiL�bv�.��4k�Ty�R&2�$��f�����d�~��'�YWp���*ɷP���QY��S��t�{��JM�h
� �P�s;h���l����k�_���ޜ�S׫+E�5kp���<�`���M�����D�/��B���/��K���-Bc�FmW�\}ϕ�g�d�[����ߪܠ+<l� �_Nv |inX��xw�ӡԪ�v��D7�	Vjj t<f!:�`�-�C`� �HK�nȐ�dmO�3�v����NS^���;z�5^�	^���=�4T ��,��d�`���"UA�c�Zź�H7�2�I�k؝��Q~^�U��k����2�I���/�֩��Y&5��YH���������O��B��piCV~Kf����!ye�W#c�"�˳�k^*�~2fi��ǤnW�ˉAc+zex�B�w譹�+utyħ}�/.Xw�H`�i�	�:G9 �6��gƇs:����P��i�n��L,T)t�iy	�k�P�ۓ4��D0)�x��*�w.D �D��Ŵ�����g�8�ڋ��u�]��$^��i�꘶��6K�(˫���Z�Qf	��H�k���
��7�
תaф	ISI�*>
��iTԤ�TĬ����'�oԭ��o��KBl�5}�IZ��]ڹ�f�M*�2�6-����A�a(���/;M�(��gL��w�<�,���ex�r$a�'>���j����ӣ�W�.�4=N%�=lӁ�4BZ)�����MÎ�� �~���·ڽ�!}���6�A���ط�7��CLf[�z�~����6L��A�@Y��w�$ޏ�R��
˛u7d_:T��V�E��d�4�W��M0N�5�,��}TB⥍i��,e�]:�sO#5�3��*���rpG��.�1����f����Ń�fM�.ag�?Z�x7�XɅ��"[PA�o��v�Z�cgۊ\bXcWg�/�)��D���(l;̏�"|�|��i�^c��Vf�ji��YʛX.���<�c�YW�	����� �'�l���x�=�)�m��"�p�8���,�e�"j3Y[�%� ^J"���0����";������^?���^m�.\�vx}B�;�h�)�AQ�e�׸�	&nF�p�т�|��f3�����	Ϥ�l�yq�Xx� �Єh~.;ܺV�?2���냖v�j����E�����O�x����-he�@/`j�s-�j�c�]��CFF���*�*#�zIV��B�� ��.؁v1�-�7M������{�Q��۾*��T�\���T�N�=��=����q�{W�e(�F�].�3�����`ô)ˮ3��)��\Y�G�y#�j��.�puU�-�9r�jE��D]l;
��V��>$A���� 3A���C�J�O�� �v������h_e�0� �����<����i!��H]���/�-8��g�٩a�e�L%!�Z��ȹ{)_/��W
~[���`S�8��R�Q`�8�?�+�U�NJ��)^ 7�>{/@ �������`�1�әn�8c�z�¤Wk�<�'���u�����ApW�f���1��K���3N?T���+��W��@�c�/�;���F�@�~��������K��r�#��r�I�
��/�������	q�q�1NS]��*(��@�𠇦[�Һ��Cd�2��W��.OOW�9B�I���6�7����mƬ@�Hh��6���޿��l���h�>�F���F7Sz����F�J�-	����Fy�A4$�0\��%Y+��Qkz������*�N�z��̠�(�1(���]��I��2p�jj_Vb���* )*ӻ�;aF�qRS��_Z�C L[h��ǻ ��ˮ���i�y
��i�Tk͵�+���(k��nc�'k�-�Fߏ��
�s�٨���Q��;�~@I�d��#M�a��X~e<�,�����<_����f}ذ@��vĈ��5#��/��f�	�`��sQ��×�ao@uL_ ''�E%VE�.��yi�*����������%����q���+'QJEM1K`��'-Gۄ��Gɨ����N��G�J��Փ4V����gV@�N����>��sbBk��IR^0n>��(���HD�sN��t�9"I3�\��c���݃��c��N��qB�D1^��g=����r&7�A�ɐF<�o����/�+g��Uƌ�? *����:.	sφ��	����"���ǵ��h�s�M�s oPTט���J%�5ʔ�oT�Yu̶�<�ܲu���l̢�j�q��[��
d���}--ĳ�sB����΃�E�%��	m� ��q;o�Itn�����nU�bq�9~C[��Y����h=0�I��	��D1�Dp�r����"4���i��{��v������r����uBQ"`�$;����H��%FÔF�M̠��4��W�o�XQ�I�����5��1���\dTA����Fv�Sr��o�m3qS���M&jYJ���]�ڕڄ�T�j^zv�O��N�"�I,w-��м�}�KATF�Nf<������X'�Y������N���$0i��b�V2��;s���`��qDؾ����xW����2a�&f =���i㿠���Kt�%M�������Y�.����䷶C�3M�Y��;:H9��~=�=�޾T���?��Kd u%}K�Z��$)�w�RK>����(�+j��@}e���SLcB��v� �� ��i�k#���rg A�q�~ʥ��6!F �8�������|�W�kc���E�.�9;�w��l�y��R6�=!�|*`r�}$2��s��w���lO4�/��uimtm�o�,ʾ��=�#��@��L͖������;�2���EP�p�Z-�hX�ǒ�Dz�hY:�÷b��aR�!x(���;Z����yV!���6�i�%�����AM���Ko�*�A�gX7K�R�9f��T*^�%
���"L�_W�w�y�v��x������������\�R;�ޔ�;��.��*q����l2�p�[}7Ɲͫc��gN����M��Q������Z���SG��A��(�,�ƀ?���-P�KO)�a�ҏ�HR����Z��x�c_g�|P���ǚCX	��(z��D>�ã��+Fb��s=X�>�Ќ�\1�R���H�1���\ؼ{���h{�=�+�Y��&!�pi����BT��B2�>)���G3�S̟�7z_XG�|��u��7�M�]m�k���y=�
�h�[��YJ�}y��+.j��$�}�^`W�eC�vpE�����K�V�6a|����
�t��H���
>&-�$� ��)�~��Y�JN2g�/�\�A_)B��Y4�R[R��#�M{��B�S�X'�9�qsi�=k����Rާ�3g�m��s��;S�G�o2����[���;��F���i�P�����#0L�1�=�-l�}�k�^���n߸e|(c�:�ä�@�#S>[��;�W4���~/�H�|F=��$���\�e���.���mYފ!3�4�;naT�H�+�,/EBo��b���oe�o濒��U2�&��H��{��ئ�gXB���6���4ތ�9�. �X|��~�0&D�~��\d�ʥ�9q��F���ھ��GӰ���D��c겠O	��`��a�k����̓��:���!���i��7�B�&{F2���oT�ӰeP���"w4x:=
�����=�66�E����g,�-k�2㳿Mi��Mm�*P�l��|��f�c&�ŢA���I�`e~	c��Sf�����X�����	��7~E�ӥ��|t`İ��Y����OG�EW���#�'��p�lG� _���������fQM]��;�
�s��*�ާ�3V�~dIF�o�諙�JȎjO$�])(K�ᢆ���=G�]K7���U�Gm
��ΎS)s�� ]�L�`���Wu3��̺mYl�{�ļ㬧�i�,
!�������wb7�q%5����5bmrc�Vk+W��ȝ����	���w��JoA�c��=�6.Ƽ~7=�>���9���6X��1H�KM��¦)X����$T�'�t�fk��� ���b�tP���5dYo9���֨�ɓ��1~�f��MޕVkt��m3U�CtJ/�MZO�$n���E Q��qD 5p�N��� ?��7�.����)��e&x��64$���
�'��ѦV.
�T��'JSBч>���ȣ�jg0�6����lg��?�"lY�`~�Ӌ=�z�J��58���w�|s����>YB���t{�m�DC�F>�Y�w��o�$� ��O����gAh1:)�}L����c��a���Ԅ���>r.�5I�˓��Z�u��W9��|Y�����+޼#{�3�f$6km�'od��o}�|Ř-H4_�4@�wi��h*�{��!{�d�C�.�G�Aq��m�a+���}7�^�A��t���N�|��Ō��B��@D����a`��,U:���X��8u ��_�wҴݦ �K��z�G�BJp�a�e�S��}���!�
�G7p�����iX�����H�����bB��gl/�c�GM�:���om��e��f�$�}d�6u���M�)$\�և12~ߪҺ�#�Ğ��E��ӂ��!'`�&+I6�����D�_s�U��U��4���=�'�I����YF����@k|a0.�g�hj:�1�t.���#E��9��9�Q�*ré�xD�o��b�Cެ����;�|���Dk7�78'�n���.7�t$���<&UL���'!�M\�>�Ϸ��/-/�����X�0�k�jD�"�{Y:�|I��$AeD���[�+E�e����D�_x���Ք���2	񒙙����t�Z0�y�Xa�+R��mO	�K#��)M¹��1Q]����(Y�l� �J>�JO�d���R�8i�$��+��Rܵ�PQS�(}�U 2�*@�<S\zh����W�O��3&����2�C
�]�l�Cۅ;��i�&j�j�M���Ig��͙�Kg�)\ЪT5E�2�'Ҧ~02%��d�O��f�1��8e;����C��ZK��ޡ ��ƪ����SQ���ѯ���>�� ̡�Gd����C�Ů� m1mG�W�ݵF���joD����p�z�'���x*�u�n,��B��E��s�v���Ij���MU$�:>�aC�7��w�^!�7p�	��*]h��C=�o̠��L~�Y�-��Y��v۔AʟAx������L�:�՗�0�bJ�|���1o>�ۅ�r$�-�h=�R��-ð$�n<h�%� W�+���Ԣ)C�dT��X���1?~��Az番�jacѥXzi;v�{r�g�K��*�wa��e�Gf��	����3w�����1(;]�7�N��^v,���܊:k&�Z���?�]�,�[=��358F���8uL�T�����"�r�(���q�*8���T�=����nח^��(b�T�Xsd�������C���y�6�f �MLU�\��#�"Ⱦ�I�҆W�</�Y���wi����3�U<���T�2tA�R0�aX�-�$bF�Za�J�rE������!���c�u�聿)��㻒����f����u�2��Gu�;�f�ZRl�������x��6z��҂�Rǐ"��
D�Q9�*[rVr���/$G���K���s���o��!s�:<ڦ`�'��"Q��� 98ZF�����������v�=:�֎q�Qq_�bu�e�&�ľ���%�Rd�Q�$��8�$����5T�?�)�O���,���.>GY���f8�!TOv�UG�#�����ic3����u+y�n��'/�o��C��w���GR[�>���wI�����^z�
PgOPu�N94*�S����;�824~a��N�8X�5����;}�d2�#8��S���6c`ڵ$a�SϪ��P.��nw�=�}~M.���K��,�̨|S�1�վj�2�'��5��+��MI�`I�l��	�+�
��Fd���0h����I��/3/�2�k��+��R�
�g��T��@�Q$/�:�x�|.]zO�m�ޓ��j@��u��l5��.��H�`��[�C���{�Fj[���iA9;�ō:x6�[�o���B�`��x\W%QԵԱ�;�u%�|���c����cQs��UdFqvKD���pC��(XU�κ�6wZ�k�U���s���?�DlS�{��Z�];�};�"�5�_H�Eпt2Ak&OM����b�G��R�qд�DfW���´	Ń	���-kāX��Z��p��\�l�YR#]�־K�PǗ�ؤ+�-�SY?=��v&��;A��[�-�Vm7m-�2�&���j���5�,����]��q�k�g|����%��S�����H������9:��^e+�?��/�4�����D���x+f*}���{>JHR��!�O�O�w����T��dRcm/R�,��)M:3��BN�8���#�~cX���:�y|��)9f�����u�~0[7��`�!���B��Vm� ���G�2??�i��d�C��ȏ9�:�=+�CѮ�[�i)�HC�C�����~��u����Ym��^��B c����6z�����3z��WV�R�J�(��;���4_�G9��i޾$G�����!� +ܐ+0y?�,�Qa>�6���٧8� _��_S�z��p��ݣ�������XƎ���3$��0�4��w�4n�ҟ�l�A������~|�%Bie��/�)o��x,���?�O�O���[T �S+刋L���"�X�џ:O^P�d5ō�P���:Y��~��~ɫ-�����(.S��U5��i�c4�0�m��x�`�e�h�!���=~�i���:'0S��&|�*�XI�WL�D[�������&�=�T�}W#7(���m�a.�a�I�bmǁ���n Dm�����#� �R�Q��$�����y�B���ǫXt!����l��OCL>z
�z@RC	�e�� ��wa\`���1�ך�F�HU��ъ�-�baGŬ��0/uk,m��_Е��� k�E���u��S)d�B�F�%���W$�\X:7��4Y�g�(�ܬ�]���f�7��q`�Dx�� !��Dڋ�Ɲg�p.h��)��\��O+��0��!��p��"9�n>H��`�k�]>���)�+_C�اI_�tHj;�F��^�b1ץ"��V<>�D�<�ލè ÍT�=�Ō�c~�D����8@�;�CJQa�� �)Q��ˠȫ��]�x�������V������_%�bs�m��%-~]}
)Ш��)�amS����g�8��cD)騋�d����+�cb�]�@�4�B�:T-����nUܴ/UC��G'�`�H?;�.��N:2@�K�efϩ_|�E{�8.V�E���������%; @��6Y��d��>�u��*̽з�o��n�+���|`h���i.L�Hbͅ���[a�hd�5�oYi�IN%u`����d� �{�	|��?�&F��O�0��F���0jjL�ܞ��yDρ�2I�0�/��U$.!1)��Y��1�ΗG�AE�n���T��:�����+��ɥ.ɿ$B�����]�lv����n���h����rI�m��L�$	y���ݓ�#���1)v��Q�����6�;+Z�P�2���LjK쳩��*�V��Hސ�j�H��A3 ��j.�ֻ������^�= ���k�F1u��IC��&ؘw}�g��w�b�����mҊ��XW�&��ԑ�U|QQ�ū�R�O�D�8���ao��|�;!L��71���Q�    ��= oa_ ������J:��g�    YZ