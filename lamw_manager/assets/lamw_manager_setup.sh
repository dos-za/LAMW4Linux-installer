#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1825335117"
MD5="96ce7f76f67e1d996848434afd59cae9"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21160"
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
	echo Uncompressed size: 144 KB
	echo Compression: xz
	echo Date of packaging: Mon May 18 17:54:32 -03 2020
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
	echo OLDUSIZE=144
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
	MS_Printf "About to extract 144 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 144; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (144 KB)" >&2
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
�7zXZ  �ִF !   �X���Rf] �}��JF���.���_j��ҡw�(�a:(���	��=��ϲ=��'��ft�?z 15e��Ð��N��kdV�C�94ll�vif�RAfa��r!����.M��0�}��Cu
s�B$|���uCL�>Ъ���+3�\���
��U�r�Nꁳϕ����s�7���.&�Ұ*Bѥ�9�7�w)=�7}�&��pS=3�n	���]���$X�"�U8(��u�X��2�l1�l��ͦ� z{l�%lC3�7��QebV��C���v(���E���y<�F�<b+�4��0�4l-����'U��e.�XT�ӟٞs���۱���"ڥ�7k�e�"�V�t��f������*�~�ͨ�_�*-s����s$p�uS��8�����~$^�Un%���n�I	/|�X��afTb��r�@"�!	M��s�$O��N��x��$~�����&ia`ʘأ�e�?��$����C|�.��=ּ��px\���,��\C��LJ?��Yv��y&�&��?��%s%@!P�ݷ^k�Z���5��"\��Q��yj)�\�S���_��H�.ء�W���@�0
~T��/�T����L��R�^�fA��ED����a����o[lĥC���En�|o��y��_IXT<�1.P~0�Gl��vyj������2_����ф����܋��y�8��߿��q�B}�[*��c�5t4b���gG]D�����Keky�R}�G�@�OA9��@��o19maDD@co\,J����}��F��C�O�A*�<2D�Q5�u����o䁯޳F�rŚ��y��/�7-��2- �*p�>ph�3l����k�u�d ~�Z�4;����J�A�X�Jp��G�P 3`�w$�7�O����n�9��Q0��_1��> $�Xu���)C����h`���KP�֬7Zn7xިhp��Zt璂@<ۻ �i~X�M�(��(����7<vtug1�|�l8c��g����O��9�3&�-���c�\�>�qb��r����6�O|e����D|�J��\�K%L	��g6�r�&g\*�R#Ԏq��ƑNTT��-,�~0�֪э�L�Vv���:Aޡ,+��3��N*
1�5��Q�l��8�o��*M#��{��N�Ot�EK���=z�!s&���p�˥/'���[ϣ�+3OW:+b�6hD�Թ;m�	���7*�Ր��~PDgf�5?f`�լ	���ۙ��#:˘��q0�2�D]l�vKT[a/�	�y�d�|�'U�Zk��Se��\X���V6��_�U16�`_r�e��3u���oO-�t���j��ֵ���C|򁴵T,��&��Q5��$p��N����4F(�G1�4�m�:A���p�Ed���
�~Ɂ.ySPް��[1z%�H��7谺W:J�	07��X�3( �`LE�q�d��s�3eg��eOZB����A�[��P��aQq��H���T_���0����QG�e0>t���rw0���X��-*�b�bY�`�����_X;�4P�R(O����4�p*fX��\���b�$��/m�Z�.C3��6�������
�U��b�d~��-Ym�Iܚ��q÷P%a�
�t���@�:�,���Z�F�h�T��+��Ӫ>v>�8���H���KU��AxV�;š��c^@?%�hpI&��9K;��nA�f�&�U]�oA��R�]d��+��Lc�!������we��K"}��ʫ�Nw�lʞ4��!���=[�n�\�G��� ���9�q��oH����e_w�Si�h��n���
"Rbt,�,=D�p�^ˍ]ԕ秐��_�����&݋ �zG���jw)��Q̴�
H {p\AE�\�'����A��h��h@ۈn����~��&WB����W�U&���2�&�s3�d��rj%d�ܴS�[�A-X�9����Ʀ�4l!@�;J�Z�8��H�G�����d6[9$���n�Eਗ਼�S�&F��;m~�x$+���KƼh��2*N�J�Ojk :tt�	�}����e��G�+�<B�`ʫ�ZmR�� �?�F#�5v�Z�g�kj�<�~W��3�M$3�C��\��ӗb�x��M
��U��z�
Y���7������AA�6�\�'�s�E���}*�]�3 as�R�@��
�k�#�h`�s�R�Ժ�TEL��R5�xK��O�i�QX\&�e���Q�blE�i*����kS�}'e��n5���'A�X��15��x%3��d���j�l5�ߐ3w��1�D�&;��|��A�&E�\)�c������֧�PvL �x�6�j�\��ӻ#f�H��B!ve<��^`�"J�W��EQ�
*"�$���͑��y�W��"*뱒Fz�C3�MHu��+س#L*"*_�j� t�S��ɜ�k�����y�xV*J]a��W��R��퀓��h	�Ͻ��R���XC�bF)�|8��ZhFIr����x3�u,8�/1:�4�iNDC��,B�j�d�O�l�V���^��<�B�f��ck}��|*���b/��Ղ���3ŕ��\��=�JK�>�,j�yV��U��lGN�5��[Gy��;A$�>CrF��QŻ.v� #l ���@Azs�1��<����{��}���K�F�w�A"TC� r��s��vΏ6�=]�{��"�w�z[d��NF�f�kv��&m���*�eB��%�m��^�\��lq�	�1h#�(S�ip� ��W:g�bn�"Lɚ�A�'�?f�����p����gN۽ɡ��,
��<�(� ���ֳ�^6!� a� ��K˂@���~����9� |����7i�|!� ��ה>ӺJT�Y����[JF��J��c(v�����nZ�����
�6�m�~��;p�_�,fk��NԜ���x
�u��(��2���J4 �a?�յ,(Qyl�/#�6;����F_J������
݋D���^czG>\������'�BQۮ�T�7�w�&y&�f�uZ�������}�s迾Qʅ_�%���a2A>�� �~��.�>O�F|@v`��*��m=�-��H�#"��(b1�����shG+�ߕ�w0|�����P�fj��ʰ3!�]ɛ�P(4~*J*�p.!����� ��H5��5����e����<KT�{�O�����(����M��(@�XB�}��ʍ~�ϓA^��Ă�C�:	��ٝ2�gN��h]�:� ϱs����7��4�;�:�I%-�.W}*N�Y�5T2�i׌VK�J�|nî�d��Nu�����hX��e@��7����mEڊ�i�k��	ʑcN�7��4[!^L8���:�E
�i��2�1�Y�3y,!Y�I�`0M������|Ok�?DC��N!�vM2�ۥO�����+����z��ڂ�~3��QӭG��*���َ�v'+2�/)��$��ET.<1�#��̾rd���sW\Dj�1
8+�h��Q�V�l`L�i&.�C�U�[=��5����!lq�5�1/��˦��LU�����Q��/�L���q��Gj����h�Fs��^�T޵G9�L�7�����e�X�	�����|S%U-�bc�b,���c�l|��3K�R���BYxz赀����|� XPSWq~^��\N��%z���
��xX�\-+�yAj�4&�����\�`�K��ds�Upu?V'qY|D.Bأ8�MZ(	š�����
�s��MyS�ǒu��;g���I��݀��Ho���"'���t�*.��PU��P(�ZZ	MS�����UJGS9��\�o�3/kSvˬ���3�����ò�੼1ۢ���� Β�s$��a��B8���(V}%�O��i�j'�����S�';F��&�]Wa`�'�,q�G�,>�;�9�~�\�Ck�Pg>ۧ�L�#�';�徯moVqu��/��I'^����踫��:�Ό�uJ���ߊ������*K���cG��,�W�v�|���h���(���c��ͼ6��扚��Se�W�t�: 9�l�E<�s�D�����_��#W��Y&$�K�]�e��$QBI�'���! ���l��I�BT���R͜vS�zG��ֆ���=�\�FM�����F;�i����A�����#����{�U��@�p�����0��-�!�>��$��`��jJ���..yô��v;�	�)�
�XyX�G0�Z�5g�M$e��].� ��S�J� [�U�Ջ�}fL~Je����&J7UL�����t3�(0����r'j�	6�o����R�b��J��I���6���*���p�^@+�3��P�ۢ����4Y���?��x���C�^�l�(���u)�gAY��Quߑ�y}+�=����0���g?)yZ�jr,u���������YM�d���F��#ջ��B�)H#��N�xl'�u�v*���4�9c�@I�R�Nxu�i�,��-�������X�)Q�n�H��_�Yi�ܼh���w��̫�8o`�,)nX!7%9�Ԁ��Ξά�8��Q�D��@�cq�a�a�!2�ه�5e��V�(���(��[�TQ����&�9s�S���U����[U��}�o�7���b�-�t:H��#~q��|�^�0�>W~"P�^J�����60#����S����J��W�d���1Ɇpab�A��}hr
{�"�~� �)jj�ǀ7�	'���/B�{�����J�V�LH���W�'�n�d9I4��5��l�`���Tsq��]��ʹm'�xI>�zՃt�!�A�DP��?r�o�E�4��4;�^|�y��~�6#Z�;̈��Nw*������a��*��\L� �{Z�k��;��n«ڶ���y�Aٗ����[�qa
c���Y�R�"�E��y���1��W��~�?������;��<�f[j$���:V�!Ha7 �`}��`0��+�C;�~�+��6�,�����L��pO��q�7l��]'J���n�v��\�Re���&f�yL��"�֢��ɣY8+F0j����#O���gt��Y�qS ����F���f��y�����L�G�o͕Dt���k���⦃ň�ug��A�7��I8�K({��x�A6�[��=|��w���cUX�<�{??6R	hL�	�����C�NL���%��S9��ëj#��+o���x�Zr'��H~++��Lcr��0N�5�y�ݢ������l���լ���J�p�=��&6���Ȧ�|Qڮ-�B�8��d+2��,Z���:��=E`�v�Уł�j��Dp��b�wg�lЏg���>�ٽ��Q�k4<r3���n����~�!+��2
k�-8�[���� ã��hL�ݾ�~��M��t�x�S��!�K܆�BvȲ$3��Y/���_���)��|��8\�V�(�,C�<�1LI�@'%'�_Ğt
渦������k��,�26T�L\	SÑ5���ӭLd�ݘx:U�#L��W�%�Y������0�I����~���V��4W��&�Щ����L$�����vi��J����6� zG�����:{�,��F�{�/�*���A��5vu^�Z�[�^��X�����- �OR�x3Vt^�#꣙j�S��D��a�r����Lâ˸U��������o(%��=�>๸�/����3�"�M_�iiePk�2v���`��>>z��)>0���t���p�P޿��d&G�5��w2mn�.���hÊ�(ROT�sY�N��DP⤾��pӰ�C�Ss���H �	'
�F�G�!�UT�j	��u;�Aܚ��}�=Wʁ~R��r���ح� 3�a�ZG~�(w[HOR�\���"j����]Ӭ��vz]�p*��v��'�5�0<���~w,
#&&��sK�,΋B��c#�{>��&4��K�IX�.-�1j��]!�Te̡�)���([��T��CVq0s,�?v��Û�v�P
X�T�Nh�E��N=k�z�S�{���K[���$⼖�1\��d>�Zv���W�p�w�8F�b}:��,8Di�R@x����-b���M�}��M�~���\�}~��\z��ˊiґ�#����iM�D����gf��U��I� �jE�Q�/h��Y*�OsL'��X��3[�!�X�L�H[� z(�[�0�
Ί`���TNv�5��?�?7��^Z�W�;ɮh�C�k/�EE�J��"`ϔ�9�\�81o:��T�0nX�[p�^ ���I�c#��j�'~�M�����>�ռ�# ;�:e�Բa��/%i~��6W^g�~�M�M��"��7�ק��C�i�X�5�ќZ���K��6D��I���Sj&:<�	�]�P�]
#�_��&��al�$O��iX�o��Э�_q��{�;�܆�H�� �;�L��##L$��G��/Rm�%E*w��4�ն"��I�8�(b�TJq+#9c;�L�+���6�!JJ:��hz)Vq8��i�d;�S.�YR��V��Y��$��G6weJ�/	�iv�Ww���Bv���!���k�Ћ�@&�v�;��-t�6���K҄;�si��l��*d:�R�Z��yz�;x谳�w_�9{�s���Ѹsv�� ����u S��6	W7*���I�4�[c��~SB���u%�Ղ�f!�_1)-��coG�#�@ g�(����CC\pcQ�I}��r"u�+�o�#��i��$�2l᭔R�ɮ5�}��ab�ӽ�?*�9����F�W��􏟳'O@��v��v�tN��T�5�ίq�m���0Zֲ\R��c��)?�R�MX��!,��7����hA":C
a�F�h�R^^c��L�n�%�-}bF7�VLz�OTw�qw!�ףa���d�^�W�oƭ�3�ڳ��b�5 ;k��Z�0��,�b3V���6X���;A���T�:��&!���� ݁���~G�=����Z?�a��B;;}?�m����;2w��^��IyN��݃MxS�c���m���׀�)�>�"�Y �x�B9%�)�yiY������Mq�ፒ��4*��]�~�L�^�Ձ9��c^̃X,��� �]�<��C�v12N�UO.�Gʍ���
Go����Ɖ��W����4�\g :�6g/�BVT��b1��<l���j)�te���5��-��͟��h�vۅ����F����^AD��뽸T �#V^y���\�؂��ze? �v�L$���n�8?��\;�h:_��H�ڥ=�a+��}��Ǳ_�1����9	��#V����C���{x�ZC�|��(��A�-K+Q�Ű�,��+�ݦ���$D)��T/��^�J���Ta'�%@�l���k�i��kzM7ҷc�儥���p��k���[�ғ����3�XjZB\�Eo1�:��lZ���HC�z��N懏�����t
[3m_*'!�<k��g'�M�h-
E`��o2?�����v/$�	BF`̪��swvjS��������2+��*9h�� ڐ�}s뷻�a[�a�q�O�g	V/��{-,v ��l�{�1eKJd����:D��+å+��7(!��_3K���7�e���*�s@�(��JE� |���h���kyq1?!I?���7�#����=Km$� 	
��|���}���@�%՛r�M��|h�*��� �R��>̚3[AK:˦�$�����p�Cn�˖����8��+���(���y�����dù�Ŗq�����!�E
(�F���]��HF=��z]҄m�*�}�'�I
�����C�C��)�͓�2t�0�V��;�~8�'MF��6&�ַ�?x��9�Hΰ�󈍺��i&�!d)�I���L��3ּ{-0.�U4U%�=��LNe�}� ,F�Ds�\dX�:�5��N�[Q�	���ʓ��0B
R ����lujIh�����&��~�(�42Y$v�D�1{:�z:&��2s��Ͻ���V�����0ZO��'��X3��K@{Z�M�^y��f8P��N���Q����~\�xʷ,�î���ع������z|_�_ȩ�-5��,J~����3pabw�(�D�p������Cs�ڪ��otӘnAG-��:-��A����/�;i����k+����"�#�l˄	y.p��t��ɾ��wg#	!���7�nث�H�����Yz����6R�*���W_�q��YS���W2F�z��MGԒ?G芑bviG}f�r��Gr��B!⺛4���P����8�<xd��@	S����]�Z7)QW�$����ȡ�>Y�Ϻ�-mg1�|fy��}�r�v��L-���xj^v��y��*;{��PL�� ��FXh���H��[:�ΐ���݌���g��Ȑ������\��S���3�3����ޖ��Q�N*!J��G�rr�9�-���j�.݊�
K0�/��U2ģ�r$0FYRYg�:��IL��	��v��_�E������r�ɨ	��K�Y�����.>|�BuӪ{4����w�z��H��l�4��n�H'�ng1.�44��o�t^7t�I-L����;��N������n9�3�j��SL��m�b�7�z�W�������d����a7�6� ݅���O��6HE0�%������+"u��7���*O<r5�@M�:� ѮZl��ėA����i��Ҍ��>�����b�����# P��g*+;	톞M�2D�^k�-�('P�i�ǤB��^��s��B|�@�	(��b�C�y�4I�����2���[�����v�xƇ_��7���A���?`��'�d)��"�ɀA���~�V�|���HK�HȔ�<��V('�##g�$O��p����U��P	:>��$���C��;K����AyLXsN�v_���b�nd�PF,<�K���R��ew�r��^D����F)ǋy����21qO��:���j���1�MȘP:�|@�baؗ�N[��hZ�v^uVb�bw�F�k�B��~$���Ek��:ձ��Ǜl���2$}�1�ZY��*V4-��£��.�a��)���9\��|�E��m�	I d�a���mP�T�׉�=�A{��h� �[2:6�}o��K<��8�[�h3a�xs�y߶�����̲�;��(� ���k��pN�����)ƲVY�W�O��[�Wx�:��Xg��Γb(��߹��K���~���H{�h}-b�s������"�ŷ���9êsɩ��"%,q���byͨ>��7il'�hD�e??�/��������߫�V0��g�$021x8���׈��;�a;�Y�ch�P���'K!x��".|�bAm#[F��|٥e���N�F||���SǏ�w��gSZ�mZ˝���������ߝM�"���N��6?�A�b����������h�R1IFm�y�r�y~�a���Y���4��!��Ï�Z�렎�$��坣q����Cg �?�GL_+�D�ۇ��2\@tkjo,�f���)���� 7�%�4�x��(����4��<Kc��IRf�|��c7|��`��$��C��Ҟ�ɚ8J%k
��̲Wa]$�l��]�	7{竩Խ�ٗ[l9E�C1X	\��I�؛��hf6�{iX�.��k�k�zӣ�~	O��d�w1��/L���	��M8�Q8�A�iĝ|�w2��F)����	&qؗ��X �i����i]_��u'�kR)x�b'H�i��;���gQ��n<�aK�^Z���������0�lS&��,Na��=[XNw���6o{��O��(���$�����)<�Yf3IEF]LI�f�vR�^�	ϳ�������h�;��@_�펲-'�i��nSo�W
A�7���K��Y��hy�O`�[�o��Vw_���9Y"�?R���?*6"��M�p�	|O��_�.�F��I�uԅ�� ��0z���r뀲�9A�2�+x+	�!��/Z�����j6{��l4�k��%����Ռֳ{���O9�a�w�LH����,Xn���B٠�B�_���6d\� �Z��3Ē`�z��;'9߅>�A{y�Byd�h`�sK}b��ƍ�v)b哕��e�ᝯ�h�y�M=_��l�y<c2�c�? m[]ql�$%�j%I@'-sl�2���b�� �X�Ci�,��5�	*<<�����A�t�\3�Շ5G�J�|`���j*�;X33mΆ���0%>���/�b�+��(#C׿$�}��*E�<[P�߉_jGe�-z���$�]N�N��݋˪��7�ىڛR"�s�� k�v�\b�"�����J�HF� n���5dw��ߘM���<�)�c���d�H�f��k�&�˄�H�oY�5�br�h��Ya�ifoRa����(³�x��wA�U5�5��(�� %Lw�\}A��ab��p��o`��$c��y��Ղ�&��P���5 5UVo��S\��G�-|�-���aT 
.��נ�K��B�q�I�/$+PGp뿱�d
r�a��rky�#��q3��n���C`�k+P����q8��x�[^�o�F�%����Pn�9[Kؗ����IGù�ݕ����k"+���?L2Qlx�H��'��[��!__����ͅ�ѧ_#�1�d��X�af;����s�L9m�D�;K���mA�lh�zCn�wH���s��,�2��]��P�;�A��i��6x�gE�+��~�$K\9PV�o��Q�mA�K�����%{n��`�ѻ`�M�z��^wE!>ھ��83�#p�G"���1��:5?M����6E�4�Sj����H�`���s��Ё�,g����Ʊ��DS�j_���v;%9/���D�9���m�T*���He�
"���SC�� �ە�1
슕��
0��_vH���?�t���s#s�l��K�z�
�AR� ka�6�b�n�|26�5��'n�/-�6Q`�ay� �r��Ps<��*��E7Y�ߪ,�T?b�:2�G��G����>�~I�l �pWT���PpG-��>3�e����-;���IK�E�<^L���'Z^��O�p���v����\��P�փki;�d��W��Tۺ�2�����GĈ���k��Qr�E$������#���B�s|��ʥF@}�7y�3����ޤ���T;����i��Đ��?T����Hx�しI1�؀��\&z{g����z@�v������niE�戂|���o�e��u⢏Fk��-4�%v\��
�d'{zّ'̕�/���w�e_ħr ���E�"�?�Jf��c�|ޗ*{����D	94j=�dI�b��i�U}C���L�9�Ыe�ܝ��bb���G0u��Y�c�h�m����^ݍ�W�Զ�_�ڣ�<�����7Y��P�����,R@Ѣ�!�'���^�d��\w����E7�Y^)��u��G�����4 ���G��� 4�-����bw����\��+���[c;�P;���G�^	���H(����J���,�ld�G�t�M��sBh�k�?���΁�
���C��W���%�� iH%��:``%C�mc�5�.]L�z�-�O~�I�wT҂��7���3Q.�b�Z�r�L��'?��Uqd9��gry�ţCi�>��4A
��� �*p��;9� X��뇺j�T�f\��Uu ���E��I�zHe�#|y4?�x�@.X�:���ɢp�T���F ��^<��&�"ǰ^�a��&�Ot�V.'�⽁pO����
9U�/p�!e���嫝%$��j�A��c��/��soo]�����O��Jd_�~%��6�*_��P�y��SL1Vy���u*�� y^E��$�v)?��>�^����׏�B}�K~�X.����ΎB9=�m�&���Hp�o�@&^��P�*PN�7��3�iTiYA�3�^i��f	�ؘ-�w&k��Y+�ˣ���S��T�a�}�u�o#q�b�1Vۅ5,_��كrD/JD�M�i�GsWC��f *��j�H�Ә׷��?�`�%�0B�m ?P��`�qR�y���E�I2ٴG𯾟���ldjQ��=�U���\p|}����N�n@�uR��8�
DI���
Փ�^�$�&a�O���8v-�e���C��|dQ�"�\ts������v�~v2���;77���)�Ly�#VpI����$L�!��I��k�9�Iܬn0\GIz�[�V5!᪵K_K@�!�L�L��<_�9��=
)ͬ�0�]�M��*/�	W|�v2Ƅ)��2��Ipf����#���r�[&���~�oL$̹iLx�/�p� ߡ�j���Ut��RbC07x�^���:�q�yՠ��!,�;�[$n��v� �n��|dԓ)�;�GZgt��>m�a�d���H3��]�l25�~_R@������C��t;[9(���7|��F�k:{���P��I� ��3:3;���C\2����W7��D���ܢ�!5�^��R��6��~�Z^�.H���5�v�Q%�K��%#^��=�w�6Rk(��HVv⼏� oqvhR6(�F����D��ۼbc��F�)АcuQ�,�!`��Sܢ�b��yՙ�Knx�s�\W.� ����v	s�{�g�YR9��`�ص?q�8��鰖�7�}
�w��c�J�`���0�<��cfd��maBl���м�{d��� �!�[m����TK/P&x����hbu�~FrT�����,������j u|?��'�����c"k1�7�������3�/�9�B4����AaO4�㘁��P�&F2o���
y�&�"þ�X�o�����<ðu����?�ft��і35�i�I�e���^p���&��7���:#W1�{˯�=7ba���I��T�E���X�M{��ȤdfU�	�y^s��ǌ�K{)�����y���{����79)�K�]��P-��z��G��Kۡ��&͘$^b��T�h����<�o-���/�l�fCiI~{����&H�����!�3��C&�j�<����!�5:��D?ey	�i�.�����Ζ��=�t5��}��O���.,�Uæ�Q�l�GƝ)��������;5�����?'X�k�wD��.t�*1�x7З��u�#��;673������;wiQ�$H�C��of5���\�"vC>��.�>��P�2�V�����$��n�)1�4��1�(�����Z@���Ma���C�D����~��O1��CߡL�!�����y�h�W�ϐ��(�Sy[rߝ�ۃ�D��$Li��_!@�Vw� (�2y�>�:���+� б *��f�-���h�j��?6�	=�[v'��O͘����`�:���)N�l��kU��|��kZ�����3��s��o�3��_�y8:t��ɷ����ғ+g3guZ��+ǙOd��OJ����	o�_�d��� �T0������p�J�ˁEp�Xv�a��Kt�>��/��"��}��2���AR��C��v={�o&~��@-(�X]��F0�v��+�A�
-��W���w��}kEa!$񫅊B.�� 1�>k	RfƯ�o����C,5�D�O�
0��<4��qj��X�:�[����	��<�g3��4g�eŌ���孖�g	�й,g/�j�WB�
<ٯ9����� w>%r��FX�����&�	�p�9U>x�q�R5]�����N� �)	|�ς��-�Ok������Ռ�#�흃Sz=W+�.r]8��w-$�8�5��j���iȸ2�mVp#KahF;�b
���PY��U�pi��z�&�N�v�:�C��R��y��)�};���{��h8GD�{�i�ں�o��u�������1J\H�9��Le����u+NXt#	�ϗ�lE�;�u�N�+���M.�g�fL���p��q/��VF�m94?��T��``�t���,������PtQ����Mh���7���g}n��!�Y��i���@����%%�s�D�ӌ�	�����4:�w;��ՐwL-9~g����Z��J�&#�?��tx�Y���_��Б��.;$P0.H�-�����������C�F<}O�Rau�@G��x���&5��1��f{�\��:�¬�Y�{�Ә�0���˱aOY��>���0���[i*p!a���xO2�j�U����6P�Aa-R�bv����T__��Y��I�����D�X|,B�}����T4����lx*C�9x���bT�|k͛�:����V�p₣FtT>�<'��qb��^�/AH[(�F����L�r񓸮��Yh`��0Oe�B�2S�Kwe���<Y8�[�@�ӎ����2y�/�A6��S	���/�פu��b��pp�TG��<�B��$#�]�f�����g�55��6�Z֐Ɠ�|�V���N��C]�F�ֱ�9U����T��)�b��=Ka++`{Ԥ����q\�2�^bR����j�x�_#'G�Wm��S~��tM8t"���du�_��d\RE��	Δ�U=��p���1��E�\��@��H�����对itt$���B���ҫP�e��)��m�8�'l�2���pg��y�ű���Do�ż�#��Ӱ$����{��"�����I	M7�a׽ް����F�7���nK��߬�K�b�ڌ#B��`���22��e�C�{>+fN�Ìִs��}�AiP��T����S�GGH(m��{sCamo�QS�b<�����cL��FP{�9�E!�V��}�W�Xs��8�gQk�4o37�Y���>�6[[9OhiF��.�ٜ�%!��NΨ�F�s4�d���q1Y�yT_͉��i�96�7�Y�4B���5�Ue�Nn�\����#�	G��;;��Ͷ�^[#�:��u%{w�P�<�=.��m9�`��2lt뢕!KMD�os��@B+jX�Naf4N�D��7�o��w�:�,~W�4c�yB��[Ļ��/ڑ�3�$����˜���_�����}�r��RI\�+h��o6�¾!�j�20uM&	l� �aiR3�Ԋ�b\�3I�:�2��Ɍli�G�:����Tf5e�|��+�hFm���ѭ`��J������([Q
P�*����[U�>Y[�p�3�@�� ��Tu���9<l��./��na�1Q�{�L����E> ៸=^�V&�С�~͢�6����'9�";��[B|/x.-%��r_�<-?������ٷc���ןM>[E`��`ϓ��ڢ4������%kzG2c��r�X��ؕ5���}O���E��LX`�҅�����:H��Ņi��AO^uMdE�(ꮣ�qB0>.��*�ٻQ�F��n)�*a�6�ؿST9MI9�M��ۋrkG$�ٞW� P��.>�Gz�Q��LWq	��p��a�����}n}F�����rp���o��<^���TNh���.O�gT<�_1F�`�n5��D�#��l����y*|�#�e���V�eRA����|��Z�喜�x�����-�x������[q�;�XB�����ٍ�F(�_<�N.�e��<Y��ܢ��HݠW*JQr,ق��%̣�����k��֐n@�F�r�G��o[���.Q�M�j�KFs|��(����V+,^�=zK���b.m:��+�V��UQ��52F@P}�����w�Y�4�i���#@l��p��0��s8���A���Z�fL
�i��O�h�n(��'_E*���KV�0=��i>!qv|�=C����*Ƶ]��_��
�E{�󱢶+ȼ�_{�q^T�1�M7�K�&�+{��>��蜊W�I�42�����fY�;v�Æ����Pӽ����qa���<��
�(�?�'|>�C���	���㸹��:����B������.��F� ->d�)Dw�dl]u�D���M�U�L�^�L�)��t����4�$�)����`w� ;�?12��&TZv0n�y~
>s�[~YT�(�䠪����!�����j֧TL���ӯo٘g9�I�U���-�7\��K���%��u睕�A+�@A}��g`���x�,��S)�#�?}�i@k���0�V$;@���a���DrV8���e��Qw�G����B|t*u%�4eũ��w%��|�O0[�4�5p��wq�u�,�y����c��[-3��"9'O�s��&�+�Яhm��)?@[i���R����mW��1���C%�@~X��R��E��w�;��..3��+��\���8�m1�V���!���;��9+_�FJ�F�����)Wu�9�c��$?���U�~���׍u��9��-+��.j�.֜�l��{��*�fdp��9� JQ_f��I_�P���Rd��\�[p�h(,��c��a�m��gnZNL�&2A����{s�P`гs�Oz,b��f����#j�hsy1n�����|=�Af��M�#����&m.g�z��"�L��N��w�BҒ��k�?�Bx��[�q;��јmI�ɉ����c~�m�*į��r�+B�p��u�Mٕ&�x���H:�:_ٚ('�JC{�h|G�3eĜ�ro_��+���;s�%��	��K��Gz����|�(���=�L���ߎ^�fC
4br�W�`�c��x�������X�.�Q����5��X�g�:3�d�Ų�2(Mi�;h�fG��P�G'iu��H�&��A� rۚI�Â�Әۮ�O�%l��#@S�Zm�{�FM�Xr��I�ڻ������"�;E�&3��-�b���2;H�Q�ޮ���u�FGc��א?�	3sQH�*���n�q;F9��r�6�+�\0���!B��(B9����-Ӎ��rK2S��#_��T�0&޼����V���`�v1��!1d�w�;f:�d�w�b��M������	�6\��V��@>iҶ�QY/Y���S_F�14��)��d���p��j���doK�����s-����k�Cƛ�}��X�Nw�%��M�r._�Är+�M�Cp �o�:e#-A�s�Dw�R`�3����C�E�T~%L��y
xx쨶�YHXk�ןPz��l~��S������~��ZO�S9\����9h�#bj����wF$��]5ţp��f�>��f"��Y������p�K�,sq�L��/ܾ	�- �0���'���}�����9x�Z�p�̲��V�E!c�:j���|��W�Զ��3�`�Z�'�%O܇�	��/��ؓR��!1gߢ^�h�UGr��w���A�D�$Fь�!�^�� =��V��cޗ2N�JD�N5ȿ��>+��X���5��k �Ms[5���g��ұ2x̯H���N$�W�9�3�*����kQ'R�Y'o8�t̎&Ʒ�D4=%�^����>j)��?��["+�jz��M�����_����Cc������ݵw��K$xHcK��'�ɒǁ2N���&�}�G��ʹ����n���+�>�8& ��)pa4I�8[b?�&���@�F���A`��јt0R[=ߎHJ此_Wu�by�S�>� [ ����
˜�n���Z!�� �Dbn7��`n�\\�㓈{��@����5����W�o��M*vf؀q������FP���*���{B �j�	Uxj�f�^Z��V|�+m�1ͦ2��,�V]q�ݴ�DW�eV��J!�~<+w�>��H���?�o�<���������(v�e幢�g�t��ݮ�W�Ľh�1(kd�oh���eF��S��8%�	Z� ^��HO��c�T:��w{�k�p�lHwM��MU�BU�x˂�T�Ӫu�}� �Wgi9K��h���&��QX����W�DpΞ؈���=V�&�Ku1'��*>8q �8���ppoڭ�J�W+�W���l���e��)���W��M��j��:gU^1H4ث����=RpS鍾X�չ��+�_w5g�7�Ϭ�?��0��u��M�*{NO�w�j��h2��=���:�D{�6�Д�R7���ܵ�u�c��.�N�-�������U̠&� 'p�����/��F�s�Z3��~wu(�(��s��:=�HpJ�I��u�I�6е\�?����n�i"5pD�����N��!��Z�R��8���d��G��n%	�S� 0'l�+����7t��>^�t,��<��}��7{S҆d �ϣWG�O������@<��*�[�v=__f=�X]w �����\w`,"�f�/��+8y����HsCK/�Ny����=�]��f��v���lH�Zٳ2��������:.�H`g�	K[��������:n���-�۹e6 ��r��J��6�ް����i����}�ֶ�w��]�W�\v�c�n�S�B����P�����R@QqE�'W��*G�yޢ�����&ޔdd��ܖ������ �;���n���Y��xL�m�tkn����k���	z�F�b�Na^$گ10H��xM��{��u�H��3i�i�)�{���� 7|hCW�������~�'�3�Pv�����dAg3$�C�Ey?���dאp8���W�� �^}�d����$+�����y9�!��,+���%)�z[���J^��<�yaRڮ�Š�?�� �H (�ot���5]|���zP��\�r����`����{:����lx�듯�
�ݢӐFV���1��11���X�0��=L25���lx�ro/���e���ʾ�w�×�piS�%@��l?�	���4�(�3�������`µg�e$�4��?��Y?�mQ8��v�I�TU����7[|o�{�0)��,1����)�?��{��!�ѩ?o�@���`~��aB��ڊ	�������k �T��L�� ���}ثh줠�t\y8���w�.Ӌ�g��(��&nLq$�A���Tu:'w;�ѩ�������@}�Z+Q���+��FY/kOm� �d���0�fq�w�px�*8	E/Q!�G�<n
k1и+�R�͘��a��r�|`m`t`!���o��K�$;&"���B�#��Q����(lK�������RQ�����!�v�A� .���L��7�\�ECd�1��}=L.�ɪO��u������o!�l�,�
\�m�Ha��s�{�Xq8�`�j��'�}��r��*
V���������4�;$Ӈ;AB��Ng1��(��囇	���mf�w:�v�@�5����	�H�-��+�����K:�Q��)�-4�i�un�m�j�"#����xW��#��Һ���X�-���i�\ys�bb��E�j-n�bK��S��ҩ��?b���u�lAl�:
�G9nӔ�Z"m�?Ӄ��%�IޔbxG�I�����^���#gRӾKUfp	E�$��a|��[I"���M	g4h�����'!:�H�:a��0�\7��AɎ�^u�3����1ͥR(�
�_cQ�I�ȜCʢ�]}����ʢR:�i�D%�/�n�3��$�8|~��΂e*(~��u��T�=���?��S+�r6dā ��3o�t��>� b����o1���	�7$�
P뿡�/F����h� ���#�D�a1%Йi��b:�7%��J �-u��Z:�� �Lצ�ۍ��?��W�T��KB-h(�J���
t��J�mɄ�QqV� ?P
3 �#���O��n\|�7�u����U�
'N��b�׻��k,��$Ƹ���hn���N�]E���|l���W.(9����K��j/l�-+�fUb^mb�
S�Y�����64wmV����
��BuC��q|�͆���XX��,�`������sҊ�ˡ[��b851��]��9M�2���j�Å�+RU���m �����o&����j<"�7Tm
P���E.ɲ��aڇ�2��no�(�"ޚ?�KQY�i�K(�$ ^�e�Y�W]S6���ŉ�|��"z�P��%;W�ƣʓ�M�g�`T�M;	��L�T�M�V�+-,$���ST���d�L�G��������*���=��`�s��c���T��T�?�|HO�������i�Y�޹����Q�RI��.9��Oa�?|�X���(Z�\��U�{ ^�D���>�8�0X��+�X�*��h����E�k�	>���F���ڞ���u���.KN綌Qթ�1
�FHZg�_���r!s#����"���e�W�d��68a���8�O�����i���ǊM7b��]ཉ��N*=��{�]f��z'2>>�_��b�FF�d����*�u��%�̵*�[o7�p�У-�u/����6Y�]Ćc�y^�E��ή��{t��1,fA�~��[H���z�\P.M|X �{!iF��"BqlLH�ab���I�twš{�z}f� e�8��[��>b`�����3������-��hwڕV����n��\�0�}s��0 [����#�*j PF�P�����,g=G�ɔ��quK�B�:�|��CC�d�d�����6�[|�&�|v��,FFΔ��
p����!�u{�2��Bӡ��H�pT40de0��K���;1����������a��{�(yK0<%���S�]���7t:�*��x��GS2�3�B�ח�8l1�.�~����;�Q`JGH<4o@�������Y9��J#�@)���0�5�kd^��tз����7���:.Ę���X?��������T��lp`��ʎ���?�{���z��@&ML[L�^q���-����׃�]*}��UMH2~��+~� v�`0�CeV?a`> �8��5m� �����N�$&�AՖ|c�y�   �M�4��d �����I����g�    YZ