#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="993543281"
MD5="de3549114b710cc3aa1ae11a3c4bbb3b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24184"
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
	echo Date of packaging: Tue Oct 26 00:06:51 -03 2021
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
�7zXZ  �ִF !   �X����^7] �}��1Dd]����P�t�D��R[��^,��j�p��㒉Fu���H���W3Sۗ���]������/ ��B5\����0XF.1���@:����}��	׍���m���8h���z��I�I@l��T3����hDf�Rd��Σ�R*v�QcR�y�T���>�I�Q �!�Æ��4��7���EwpB<�[f���~ًM�·�^ɸ[įUM��p�'�<ޱ���̿�|�0��t\F&#�R睺��]@�u�`��Ŗlw��9=n��5C-�W�2��5�P���@���o��ı���z���O}i�I�%�}nJ>ӣd�i:^ڪ��0��WZ'��Xy����՟Y�H�w�U���j�ѶX:�a�y�*�Gv��a \�ϻGn ���YF8�E�[��Yx'+�C[� ��S�]Tn��qF\]Y������"P���[�L�jg�>�|Jd�Q��\4���T?R��X@(	d��9�z^E2~y��G̰����S*��=����xoJ��+�/@JW?%&�pf�4���O#�;�z��Z��!_$��<���������ͅ0�,}��`�K��
K�Q��{J[��������b�.�w|��3ԗ�Br!�@b&��Eǽ7	/+щq(^�*���A�
w_RZ �Ў��a&Z�4<�,m�
}�����O~�mu��z���C�\��ɼn�z��yƞ�G����3�q�YhBjU���������щv��[PTn�jM���<Lu_��M����G��3���1����fg�e�7�Y�o���uo�<r����>AI�
cl�*�
>[-�����Q1��@�N,�62����՘�a~'� AG���������%���t�=W�D�U+�7��8�.�~���"u���ZK�ٝ��͚�$��=�w�B�]��å<"`Gޜ$#'�wo^=ii���Jͩ�D}�b�����>�PƼ`h�s$���Tܟ�ag��~ĭ�*jb����chf.�?ٙ�u]ML�vD\�ǂ���lm�"��8w�6HC�����l�x%����G}Yz�,��GZaW.�&
�H����M�ScB:Hwb �3ގ�l��S$Q�I�������;Fט◝
^^�-��4���W��$�W��%K�]����*�GQ{�N�F��̆KW4�h
z��Q����Ë��y�,=�q��:f�
�j(�|ȈF�埣5�����1,������m5z��c3`���h-i�쾷 ���3A0�eL�Qvx�J�?��4����;5+Fs�}*D�L��G��:XP��Ȣmr��a�n���V���b MJ��^���u�<1[���y����BP�0���wh��P?�g�L=5��JK����Rw&�0*�!��t�7*g�Ӊ�`�DnM+"_�vGe���JNZO+�H�!Zg̙Ϻ�L�Ϛ�ݤ�_�/a�r	�0�x�N��"#T�0�.��/���DF{���\D4N�ª�J��������w�!38ђ�*9��uDkz�/`���H�/;1_ֹ�d��zVL_�y��,�cN�n�*��Ml�Q���ӧ��4�!�y8�M�x��-�T��
�Ƣ���}T����)r1Ȯ0%�*H�S
��@��yƇ������:�����5N��k!��3Jmd��']�!Kmk�qC!�~B��R�z�1�gp9Pga������`�W�27�̦̔��]]͈���{��cڴ�) �tI,��CI��� #j!�֋�'ޅ�u��"������;��(�� �|M���p�L���{Q¨��9s�ܨ��(i��`&�c�b��dq(T��εm�4{���#̄Ҁ&��~��(Nw�zL�Ί����K�\[_F��ݶ;hKf���/�2����%����	��R�A�T9Atu'��� 5��
��C���9V�A�,L��m���Ŏ�*�+���g� ���d1�{W.�D_#�������
ߝd�|U��-�xa����u@U*�=g���x�d��H���?E���c��4��_M�ލKǃ��⿼��g�KJ3+�V�E5Z���Rd7��Vt�2�����I~�I��Ɋ�����-�3b>��?l>Q�ʠ�H�o�z��(���m����oO���=�z/p��K��#�i/OH��S]e���P~��b�w��~����c���Ǭ[Ų���h(Ö>�W����̩��+�L��x�����D{/d[���mZ�˧Y�ͭ���j�?#��*��U� �,v�C��?�x�^�����b����/G>ԩ闲QNAǃ����Yb�~T�8+�l�����l�;�l�O�	�6gΣ�v��ʦ�m6�!^D��
h�7���&(�q����邆jMS��|ľ�(�����N�&u��%�a�� $�.�E,}	d� ����*3�X��8\�6���I�v�̍��ż��I$U�Š>�a��/��4S��<������$BI��
� �\�o�/��U�O���`y�~2��x�߷�	�S)��vWѲ��^�t��D�̈́ 7���EB��W��-��R�r�S]w�_$�~nc8+�S�X���'�Ns<%�q;'���| at'r���nň{k���T���y���n@�� .rd�Ֆ����Բ	}OI��h'�Ҧ�8
,0"#�}�?i�f�]�r�rM��h�m��){5S�,5w����~2�H�0���pt��xWE9�
6�HY�"�/���֎=����>t�1�5��uXk"�^of��4mh�&���TC�� ��r,6�HD���Oo�����q/Lz��T�����ћ�U�#,	�6�v�q����#0�N��<��DX�5�p�$���kA�۞���k�V��T�)���G���W�/5Uj�P(	-����Mx;����p]F�Z�Oj�D�W�w��UZ�aChM���[:#D74��4x�>7
Y�\q�u9��>�9�h��\ת<d�B��I���إ�4Dݹ�d�{�8���z�����Z2K粟\y	���Kj^�5h��.�5�z<��.x���o)���)�\�Q��%A��J�k�+ K���h��? -}M��oN�I�ܨ�~��&8��w��$b��b�yi~5^�t��A��hhջ@p>V������'�p��+;�%���ôp�X�q7�M��_yP0&0uU��G������K���?�i��	��O�-���<�vq��� s��$�d;��)ђh�� ~���n�~�w�X�*���+��*�(�Y�KJ#f�_%��9F���Z�,� ��2���(�oe38�IlX�@ŗ5��Ljz����!%Q�v4��Wu$�k�?sF�5ZM�E����3�!`z����@%8>Wc��&WO[˶�O5�q���Cs�7p"��3��q� �@�ѓ�V�vj���;���lHM�"$P���6�fN%4$Fş|���sI�U���L��`Xg���@}���S���,%�n�4c/\н�~Ձ�H2L��3e����Y���A����
��YQd�����C���|�Qy��y�KP�*]7���^��?��d )��S�v�V�ۚ�%K�_/��0
��g��pu��䠃I*l��������ID4�����X��J��>@o�у�`|�h���^�����mR�L���c�ZM�. Ջj��xދ���n�_�¿�w��`����덝�N�to%-���"V�����Ύ�m��r83����C>^�;��H�y����ѿv�/��_Ҽ�F��Z�}�V�P�	�:��y����Ж0o����S1��C���B��:�v됬	>$$ V�D�;�ǽ�3������Ko+a�k��K_�CEݜ�pi�����v'[�� ���������nY��2�{�r>94cP+�1k!+��:����G��Ν4�p�i��L��3d%��J��U�����I�	p-�Ĭ_G�^��\�^��K1��tI�q�����` ��o�$�u��C���f��TK�{��F�=b���~��%c�9d�ADR.��t�H�$fw�u"Y-�~ٱS��H<�U����䣪ٟ-�?Ee���-SB2}p�_��&����b�+9�%�E�$-�VE�κ�W|I�"�̚��9��e{u�~I�Tz}/H��	��8s2���������k\n$�$���/t*��&wE;)�ɕ�qL8�l;,xd�q��$=U�� a����I���\A�G���� 1�_��΢����F����(�����qA���-PHc�v�Qķ��q��۴l�-:`��+2f�RLTJ9���'���u��#j�3"-�F�)H�t�h�;�{�ds��)ĵY�!��1v��e��Ie��ZI�p�M�=��탷r�H%bI�:�g�cܳ�ܺ��%=x��d8BA�a�Z�M;=h�X�gpL/\�o�rm��=�"�8*�`!��J>pj�:QL�^_}p�A���=�HFvY;/a� :ش$�ᠶ6�2���
7*��L�m)y��X���s���q���j�ٳ��?�Ӥq�i���qDjiЧ�.;c m�4�8��F�,���}�@#q#�%��"7�B��a�CٍL����fS��J|Qe���FM=Ӎf#��,q��_^jS��`�`���������|00dL��{&(�D� � �!�e�6���J�
=�j5�:�sV��6�h<9����noi
��-�ZP{�_%fk���n�1�n=�!��fן�a+u֡�����.dk��}����A?'�"�ϧS��4P�b�q*!�hMs�O�
SB3��'��='��A��8�x�`"�ٻ����ڜ7�$Ea�4I�Rׂɍ�;]g7��}��?2;Q��+��=b��H�J�o�<���+�����[4����P�5�bZE�A�B�j�U��N�[�� w�}|]�����j#�֞��殚\�^\�&Q�Gb�ZO�j��X�Ć��'5T��Y�
NO��=�Xa��6�&2�"�򦎋Z��
��¸�6a�R�W;C0�PS5��b&.ZfެXjL��Tk�]���L����-��}���]�'B4�[!�]m�W$�*�dr�:'���e$=��Y��#��|���x���:Ǟ�$e2�
�3v[���L�߄A��<�����̜�k�!h���Hn#�.����*1q$ἢ(��G98X����S�3���y�Ŀ�]���='� ��?��|�ًY�<���o���5>�3�	QsdX�·�9	�|��vg�����b��qG��iX|8�Tr�b{v���-b2�-?��޻�ߒgW&�mC����Tc~n��Na��P�ۼ���JQ6\�r�}r����=\ ��Pt���;D��n�kL�Ȩj��,j��#�`�#��upn���P|*V��]@��ʛ@��9M7�'�� mBA�&ElJd\z��A�d8=�O%��I����dz�����],�~��`xSQ9C��C�S@}/�2���R�<�d�w�����E�\�olС�?@�DO֎�ո��Z�魴�J�6W�a\�d�?5R�u��`� �u��7�g$l���~vy�:ey�(V�;�4o�"c�Q2yTe'`R*��\�|I&d
>��������[$���C^���=��2
�fQ��P�}������ɡl���'f�����HцW\����'\��J��	^@5C/x��J$ʽ/�GB �)M��^fҎ��"���U���+���g�[tm��٦7`o��`X�S�*�Պ�2�e�"�8�=CGb]��75���&A;�_������ 21���3����T\�b�+�d�r�Z�#�ը�ܖ��9#�ޓ�o\Ze��a�^"e~��1�p�I���q�|ءɻF��2-"��2��1�n���x��,����v����YfF�k"Dۛ�����'�s�kP�]R����2h� d�b�x�h�m�#�m��=���� ���4��KrIbldEx.�뽳A�=A�����ktHcEb���a�V��M￡��de�?p�bjaҨ�-(�!� ׍٣J3 ��7^���%R_�q��K�L�2��琴?L�[�\��\(�9�P�e�ڌ���6����u����z"�mQ�T_��@6�������n'O�\[�w�qI��$� ܾ* ���3\�jI�W���ѣk��|�y S���CR�%e�=J���̉`�[C�'��������-����FW�ޱ�)�^^fc�j��qpvbYRb�|m�hK�$ebs��n�9��
'>FuC��C͵JPn��������0�Sr����1j6�)ʱ�{�%(��ߐ�`�=@Z����k*��
�����e�e�-����@~�Iȓ2A�1��G�_�@a��y!h{3�lw��6�#:W���j�j!a֪�w]Rih�0l^Y� Wsf.�|eʦw��ȟ�4�0��u�^ő��?)��0ػ�����	�Қ=d����2�}m�Pދ����ln��2&��?%܄b�r�mV��.�L3�!�"xyr��^F%5z2x-��\���O��ժ��ܐ�D<GT�U~��ZH[i;�C9�N+J�T*`G��~���a���-�P���}��{:�_;h��D��f��C��*Y�b��kY���~@d`I�?�N~g��x}{&9�`
I�Î��*���ӶX��*�.�7D4km�C��@,�lu�U۝s��ϝIa��xlT1N�����^��X�Gv�W`F�.o��#�� ��0w*�[޳���$v�y���E=�0�x��O>��F�2T��HH�������"АIm��ts1�»��at#����ꀛ"A�Zc�o����G*���18�
�/)j>�2&��li<�.�^�>��ЦO��>&����Zba�3Mfpr�LA>36�^đ���M2QV�J{�t=���;���!�2�P���f��A�{r{y�:�7&��B���]�*��̝��]}X��`,܅ߦ��ђ���WAh��A�=T�1��iy�n�Ab�4��`��P}il��(yxe���q�$+7@<�S��K�����jm��푅V���2��� 9(Ԡ�=�� �g,Jw��"
5���'E �'&��;h��
�4� �$�N�ɢR��*��t)���%P��;�F�Rz���ܭ��5�9�gN&X��)X5!�K�5L��Rmo��e��G��0q�'U� ���&���aԇ��@�u�TA��[���!����R�]*�!ϕ��,��ϛY�|>�+㘭T,>�����Ҵ���X�Ak�ǋ<v �.�z�}	4_�ګ�m�,$/�x&�kن"�S䡒�sPtՎnqA3��\�/��I�5>*�]*��X''�
}�!mr>�f����5�pz��(�� ��Mc����!J�j�'j5_�j܆E��󖯑WB�QӹǼ�	�����[�[KV�ʱ��2\2L E��`��#��t�k;��.��w��#6��E����O@	����#H��o:y�_���C7$m�s^9���

4gxf8�����J��'��6� ��1���P=y5\%�n���[�2��z���v��Lw�����&0�'4�g�9�,���=���WEΰ�g�}}����<��*�Z�Zl,�
^%@�t+LfM���I���\����i'�3^[��w4J�}���8wE?LyF�I�7��]i�\_�v����(�B�JD�g;=t��M�V�u�N����L	c����)�Rt���8��U=� �)vy}n�fO�hֹX�x;�7a�[���͓T{㠵q("oIR,ސ�+��v�>����p�����
/�.V!aj��]�D�K_�`��{�~W��뒷v	Q8����i���\�}ퟮ.�i-/��V��̩&!`S�ˠl�tD�lM9�Y�a�Y!�L�>L,Y�3!�%�6�L�w�8��5��o� V�K�rG3$���8\k7wn5��A�+�:���[.����s��Qoo����Zrjl_�Cy,f)h�tJ;/p�����r=S�_<���}�O��c�M%߻;D%�r�/��I��i:���)˷~����܂�	Xi�'IW#�R��1����a�`��2��� �=�T�d��x��d��F�Z���k�	ڞ�%Z���6b�I�S��2�FFZ�d�@d��r�1�w|�q:OK�.=���E�b�C/����5�r׬'�O9VNT����{|�	� �����"5�k`��n����w�0�J|�� /Cǯ�v1-l�q9�eW��h)����~��z;���j�HшX	��8�ʕy��ު�������[��>d�h(���ߩ��u���+�0?��K'�3�̝�J#���|� �ƃ���7B�Hj?��2�������Y��&Y�ĞY{p���J��C��C�A9����=�Pt����%��z�@�p�Z�X���a��kW��,��I.jnƬRm3�j�z]��ҮC�d��	&h!��t	d��ؕ�15�T���#}�ˌ�Nķ\���=Ťs���^��ɓJʊ����#Kә�rB������A��/.$G�>�����G��o��z� �"r�;�b��
�T��Q����{��0�)j��e6ఒl#�P��:����NÏ��l��'��U�g�vV��ϺZ�$���!,�x��گ���z�H���r��$W��{�ת�T>�ZJc�nR��)�j�7=tֵ����yЋ �am���G��� �x
):Y*}Cװ���Zw��|�����{�$_w'RA�W�H%a��S���i�H��F�c\��?�)��.��s��%��6���WC%�$B�8�iK��p�Z���I5�PlGR$� )l�Ū�����ۂ/��I'�N.�)��<�X�aW��ׁ�]�ؔp��������^��A�/����588|p����gO�z���ߺR��)G�����%P�g�A`,�
��0R�oz�hyeRS�(�ߌV���1kV��^�|A�������UD������Q%��+1�e��t��p��8��������;����_`���0 �	3���Y�g���z�&kZ/s�ң���\���[���F����a�#+k�@g�S"y���k���Bl�mA�̌�e��6��:���I�k/�<E�4�鐞}#w�n����yw�1��F����7l��fv�Q)C�rO G��	�$����DX���0=!�	�� 8��j�l���ly�	�U�j�qUr���� �i݆���Z>7ϩdΤF�˗e�c0�JO-j���k�'}��홇c`��~��Xv�r]LTv#�Ŭ�?'�%��rw�4��΃�uQ.��n���2�:KN��K>���460��!g?���?Y#Bqz"��\q���|?����b&a<�\�\։�s/\҅�tΘ�菷P��t.�7o�� �͊�y��ɷ�4��(��W���O��<�$�z)����5n�*~�H:���F��U����F�y�Y�&���\K��v�PU�==GZ(^f��E1�ChU�\(ŏǘ��%�4-O*�;��f�=�y���E���/���uv�Y�sg�|�8�	{'za˺�7�x7U��c6�o�#�p���Wgq.��r/K�@J�{��W��TK_�,���ܮ11�z��J�\}Y�����vh-Ȝ?@Dv�HA�O���ō^5I�u��ћ�n
�Hc��x?��������e��<_���6�q���.{6�ĬH���T�G}����f_-]'�6� f_�d�*,����9ոq'�yl�Rs8�g�I�a_��? Z����KZ7�$�f��6`��h?��0�"x!�(�����J��IB��a pn��q�{J$\�6��Z8R#4M�����QkDE���<�vE&�*�˨aύiK��VQ�)��z�S�mĊ7�6�b��|BO���}�{�+�1+�l��-k����GL��:���#П�ɩ���*�FBMs�_y^�L<��v\�d�#JC��<(��|�D��&G�0�S�����Otb9���0���qX�2���r���"z����H\An�e�rK�A7���H����ԱK��P���Ҿ0N�+ rP�#�o���԰�U��;���֯.�
n��叺�*,�,�Y�I>��m��r��j�YM��I�Pt�e��}
�����Nh!��+EVV�NO+.�8�;�)�+��>JԖ$��Uɡ^���s�7,Aȿ���!�g��ɱ��/Vӵ��U &�T�KoG�q�HB(��I����Oۚͼ�G+�?����ܹ���o@v��\��I�W�e���h���3a�Y�g��g�0Ww�-jͭ�~�`��,�Yt�����X j�y2�SM#K�/��!�_���L[�,:ܹ�@#���Yᗍn �|���j�W�k��J�x��5ܶV.�?d�?[;���Z����U���Ƅ�-��̗a\�:쨕�4�����/vOpz~Q��D�ÖM/C��� �� �T�Gq���SF��\g#`or�@�FS�I��ߺh�K�:hiS�+�n-:%|@�oS���zH'�A&����d)m���@ Q�U��e������>�.#C8�I���ڏ�l�X�}�ĩo�8$�N��Wz�FA�x)�����!-^�K��.2�Z����T�ZA�K4�҄8�#8�{FJ�p�^�;�{�IG��P�:*�Hz?b׶�=\�4	�~6�1�����)r�r�M'�'2�����W����K���!��Pb���&�D��/��w�D�����
[;��!Jw_jj�0� ��ؤ�Y}�8�BrX���?�-UJ�@�B
E`W���*��YJY�2\��r���f�-�FF>�i~��g٢�[
x�$��L<��'�/��{Z�$��x~�M�Ll�"ި��/�˴���C�ˈ�կ��3�w��J[|4"�O]��!<_4�J��� ˺�ї���:���ix�(�f���Q��&c/�n'�\@f۽��)��$��*Am���^���PN�7���$����:�Kɮ�1L���=�?�[���$@:y�"�	74!#�T%Ņ�}�w~�����;h]�k0�O��d���}�=���A/���~n�OՉ��.d��z�@��H��K𰞉|�)}7.և0޾c��ڣ�
E�b	�`e�Z�f$w���yd��1��OyZ�FazV����`���nIAǠ���_b� v8߮�u�*���P���'t���4���&;�;�2>ȕ�"�������C\��e��)ώ5+���+$�r0��	�Α�u��?_�V/�20���L{˂�R����:S�loa�x̬�W��$�t.�&H��S2cQ�N��@���d� ��򍰙����B�f5kL�'3��I����?��av���'�N�_��kƼ����:���Lvz��h�y:��W�0����b��oW:i�it�S�o����A���F�|�o��>Cy���Ñ��������2�櫓�O�&�INyfR\>��_>�Q)�	
uPPUe������/D�s�E�d���d��9���װ�/I��a{�.�v.3�aIv�5{�$j�T�q�Gs��!F������ǖ�ӈ����y~�y=͢+�kȁ��6o�F���j~t :��(op�K�Cv8��E��8c�e@j^/�g9O����#�C[���-R'YV��d�@f��}4����RY��|�k�����}�"l��y�mA�v����5t���F���龕�$�QhT9?M�U�����8u6�%�8���f{W�*�c�Vfh�`Ļ9��3R�B���t#(!�-��b4�w�$�Qb� y�َ#:����do�q~R�~�ba�g/��/��b�������>�[ ������'�0�.���|>�� �/�!���.zr�2D���O5�y-��ũ����.'�Љ�h|b܋-��E�iw�����5d1,�c�G*?��ER��>A�ʫ�~+ONV<?,�>:T�|���A�t��m�R���Qa���c�^ʽUg�m��@�f�]{7���������)uz	�Yd����Ut��61��V��݁��
��x��A��|Ŀ��i"ؖ��V[{�W��?��mq{k0�����sL��q\����6})(�w�s�(����X��O�"TCD�ﰼ��^,fl�K�";z�R�B~�c�9���M��7�(�M���m��zsog8��|??~���UD�FBps��V�A�Sye)YP�nbtA�}�@��\����k�B��p�ש�?�D�ܜ%�TP�pv�hGDJPK9�]a�hs�liw�4; �I� ]�ABh�z]+ˇg��m^��9��`�80�������")`"��y�ՠ`�=� ���/��V�:��|�*��e��T�?�_���	��=��3���=�t���Ďc����=7�? �B�f�!�˫*!�
���>��Ke�W3]A���,�ի��͊�Q"ŉEu���d��٪�`[B����[���u6�m1�Ѱޔ�d�E��P�ܾ"{�2>�LY-�C���D!��qW���Qn�lJs��wp
�c�Z9���]�i!mCR��/�D��S��%ݔ�-kvM��Y��\�HRDn���8!�{�G���=}�-�Tժ��V���_H����C���-2��$�{|x+�^��i��d���*9EP� LЊ1���ߨ�y�|L,ެΊ��]h�� !�a�Y͐X���� ���D�j0ȱ�M��=���n�F��^z�[�9*y#��<�ܖ?0�N�]i��
yVߢ�S\��U5�;�'i^{�®��S��tsdd�2K;2�J�m��hM.óq��W��M2?����̓^�ƫ1ϳ��>�=�����m���W��=&���$YPV�ҳG��|��	�&�������ʣMV�v���.�7��d@>T��Wf8�sb\eA<Z�ޞ�ЫT�A�F�դ"1�Me�(fK��D�"0-oM�ԈJ��w���-�'m�#�7^ʬlQO5�0P;��Uz�wBqv2�/�qKT�:%|
��nfȵ�����ڛ�G	zo�Gȉ��tT�)�(T��X��Us��.�t�j0rB	��4}D?Gb����Nx�E���7��FA�TT̤KX6ց,�'�ӥ�����ne��^�6h�z0�{��TC�
"��j��e?:��?�I�ٺ8��c�<)\-�������D�<����:*51o�o��>��{�P>���1*�q;5�c�A���~Ӱ��4	I���B���3��`ҰV�8P%�섟�Tb�l�:(��N����������{�](p�p�F
WeH_s\@%C�hj2�_Ʒ�"\�K�Ǣ�Ѡ��33l&v�߲ѐ��j�5��C�l�Ugy�7C�jk4@.U��[331[�[Y��7��^x4�ܤ���֖�o�cB���iB�V�g?��}1���������	�5�]�r\��k[�~Y&75b%Cy�`���k����$��YH(0�<|�b�>e�~ZЙ�.	�Qj-{C��=�`�;�$�o�XT����c�lz� Jě���̆j�l�u,J�q�)[�|:=6L&�$�X�� ,����QL�{<���Y�4 ��mrY�$%%��n-��Ŧ*W�RƯ4�c*����^���#�� ��n��x��LSV���fsm�OXp���$T�95�~��������%�ǟU�VQ�l����]�G$G��T{�n&@����T'T��"��8K?��R��Y-!Ijz���E�����W��R����}��Y��Y�*�W���q�؏{�ٲm���0/�,�F���tA[W�w8�Bu-���G �����TҼ�#��K������8���WVlr#�ߥ]�'�\e����]:t�4_J�^�#��rs�K|i��C�8�w�Q�	�j��N���~]8a:"�/Q�dr�u،�C����hť@�<A�Z��z�Ga��O�w+��1�Z!��u��y�1ɕ��ƪ�+��fv��}�mv�䆋@�q��zC��֗Y��Xb
�(�!;|K(#��m^�01�⟇�@$m���� �����b�=��t��u�sad�;�i}����sG�d���@�� \(W/�g(3&Ƭe�,����7(5c{M�;�W�S��#����w\�2��-T�ޘvq�����ؙ%��!��<�ʪ~� .y����V���]JK�O?tW�(k�+�"�I������Y�>�8oZ�����\t�"
\�3��<&
-E�Ġ*�bM�����+2�'ǕE_F�z������@��6�fM9.J�*UO.a���piPj�o��|�\�(��s�����6@-O}�N�f���L����YR�V�i?	�K�ٯ�^o�k\b�E�����I�d�:�*�ʵAd�x~�.���k�Y��.���1y&� ���B/uD���N˂Ӄ]�Ԟ��#���&^/���{g��<{��R�|�^�v�Ƚv��;���3C e�Hjץ��/�$7$��n!��"�j�&�h��|k'�p;A�$ocʡ����/��p��hQ6�8	gX,�'0:��.uebGޖ��A����) '��	�s	�\hEG}���S�}�E�JU�荒H��>�|�J����<�G9�g����o��
$�o�t���p�����)�{P�ѴSO>d��bd��Z�6�af[k��YT�g�4y7m|�p�. �{��u�B��rC�!-k�%�YB/-%����KX	8��H�#����V��������.=�hSOOa�}���4X
���� � �	�������<�_���2C6S�[�Q���s���`vf&�G,XKY�*�kL��6�q�G0�L�C�a:��5�A���(�����#7���쒻�)����/���q�{:W��{��YM���T�-Cߢ6�U!*���.���	I{�MU#ACj*3i��ȽS���?8i����oc9�q�Լƴ6��yvP���
>�����$ȑ���-&�T����a�\\Q�մ�۴��}	���ϝAX���\�#c&�M^�)6VE����)�/�<|pGc�cK6�ά��p�I߂��."�/b
�P>nw*1Ѧa�+ӈl�1y�40d1��-��u;+3p�x6H���S�*$~zy���Ip����?�o"��V���fQ������j)!9@iSNdj�Iy�3�F�ym��%�Yy��$���G*f�����Q��E5���&�$������I�=��ZT�+��<&��'��rދ�W�A�Z|s�;ᡓ�»����`�+
�D�T֌8�x��
�L�
�YQ5��槫�͌�~lW���C�Ly���G�ʁ��~ �;��o��Mu�єdx��//�����x��)_|��7�
&��AKOЧ�F_f�hSG|<%���#�d˵r��m�-��O�m��H�Xt����tvٜ�8���у��AiZ�J�U6�ά�I���q�u=����ǉ�=�7�J�wOؘ���)��}w�).�\�J�e��ӍV����R�r�C�:�x���rp��k%�	�!�J���d��h���M�ӻJ�wa�5�vE������?8�2
[�}^�͊�AQ#Ld^O#�������)p9cA<I��L���j���I��?*�Rhz�$)�P�L�ߕ9�D$٬ml6	|�G� p�.2>���2��<n��'RͲ��F���b�bi��X������xW��7�b����!�'�3�k�����]��ܢ��q��W֝�(Si2�ֹa 7�����6|�
bb�^>i�r��uɊH�\=S��7���}6s`�utJ&�^��+�{ 98v�f��O˿)L]� �ْNdC�E�B<V$���r����F���l)bt�5���7�����AuV.&O����Ήc(���A�����Ӫ�[�m/8�m��4YA�^��jqjߌf�j:��k�D9.ɂ�(ח����Ŝ����-����w�M
#��TN0�*��<�MBy�+ ���|ً�v�Գ�`QE�!��l�;b�e�0R[�Ѽ������K�zyК4+�05��8���-:�F�,d-�w�8�P�?7?2�P������t���6Q$���7!�.�N��}>4�K��X��CrFև�F\A����T�1uҐ5�k!!���3qZ�㻐�0mj�#3x��^��fx�Z
��M�Wb8�<�N����W�I����QZI���#��~"܈��h`��5y��m��?͠��R�{jI�x���l0i<$�O�<	|G+�By���tz����fhw�fj��GT�k�&�4m����L B�6+թ[�\������۝A �Qu_������i���8S4>�X�}6������#�
z$����a��l�(N�9���;s)#/\��Е�8�Pۼ���q#�i��n�z�O�79�VY�`�s���ˣR�Ac
[����#��w��D~{ˑ�'b�+(!Zf�O����-�{��11�0T�ruJ���9��-�68=X���	E���C��;.n#���F�#��ez�mK/��x$�]�����3Q��c���zS��r�KT�_�Y:ה�W�`/�"U����Ig^Ү�:.�!@�uR�y�\�.�E>[��y����R�!���I�NT��w|�^�]
����Q!�}�M6c����v`DO��G괅�)�*��5/W%���m�A&��gk���VU�q�+���J�� t>@Hu�\_'��O�PE�gj��~�.���S�mC��p�vBY��J|s1��������P	�/\)�K��>XEPyt=emSp���:�!җ6�2ر����9h��5����k@�c��d*j�"� '��!&Ѵ$�Juq~tD�c�S@ҟ�>i���N���s�\4M�Rz7��k�.����h�����\�%�s(ҵ!٤�{��OjƓ�Ɋ4"e�O:3�!���,Z���<k��ӕ[��[����	��±��g�Oh��M�0������ttz���\8~=�ݰ"�T��������qJ6�0F��ܞU{[��-�|�Ö�1��qQ��)m������N�W5�rW3�0.@�ѹ�dMc���1k̋Rd����*��9��ki�6�B;FI]�#��b�������n��!�#xU�$(b�#_0�t�������v�	"MU6(ׄ�u��"��g'��I8ژO�ܣI��t̗�>�A���r�q���807K�u(�=I���s�
��@U�ֈt��z�&L�%20
9�CO]V�
R��_.���
�v���Nw�8o�aȴd�~<��ȳ/Xb�o�\:w>�1���ET6k'2��$;�mI�s���Z ;���}<f��]�p���6g	VZeV��5�)��������e9,�ޏU~#i�=�6�.�B%�%�w������������Q�f�^v��\�;��@X�<�R�g�P�r��j��a���f��av�T
�+Jn�j��F8A;'"ԍt���əlݧ���{|��i��$�J�������X�[,��hVc%(�r@��9���!Ç��NՓo�eU���C�ry.**�����DuK4߂��h.p��w���Q4M!�48h�V�'�%�X����Y���1%�r�$dPE>��������qdxu�z_푻foj�Mr���ͽ<����W"�߇C�����q=T�`�+�@R�ar�-����z�.�JD�	h�_�]��ӚXX̝�s��b���2�M_%~� ���}#�=�bGY�at��e��Z�������V����9�Z�$��p�>����p��X^I��Q�� �;�lA���ڪ6�~FP����j�W36nq�"²^B�����n.{��Q��o �e�W��Ui�Q/���-8>s����8��q�����®�?�K:L��w��J������N�T�]j �B�)M7m8Z����ԫqE��A#d(��
�7�^сm�)M^b}�w;�#	U��U�Y�=�&��>�h�`����o�x��\�����iS�5�5j�<g$�з�(9���) [c�H�����L�S5u0.���O���O�Xg�|F����ؠ��*w�X�t�([�����	6p���/y�7�Ji����M6@�crPף��e7��t��>��NDi'��ΦC��ǁ:m���vdN9	��G���hӌ3��E�E��_�i�"�86��8
�5t�D�.8�3j���U�����%4T���7��c�e��0W�J/�)��{� #&�K�c�T���A�n1jlE��:R��V@rp�	VA�+�E�v�ᔧn��]gR+��%����q�@Mr&��@ǭ�0!)�+>�0<�lW��x��9��D���M����JSb8m=�	��LH	@aĒ��7�i�������gEQ�%ZN�s%��G��|�s����~���O�bN_��*���p�j��?׻xZj�zaN@��=_x��z�J�g<)h8W��D���%��6/�b�l<�q��,rf7���2񉢂(R:��ۿ�(I�9��&b��	zַ�0�4�M)'b37�#���\$2���h���1��u�����Em;ԅ�Q���´ȿ|�?=갉�W3�VN�)<���OzY�D��/]��'z�j��Ȅ���{��\��jOx%��Ť�Lc{I�w�~ �*&Jnr����H���5��~�~�$��R�C�-
����I(W۾j�]'���M���8���#\	����,Ӽ��_ߝ�p���(��S���C�[$�$&�_~�	+��#�in���UЮ��O��M���jS9CENy�������'�r5��i
�~�����u�b҄�����m5�:�Etܫ�;Yg��a|%b|S�W8R�G��A�=c(W�X�(.M_5�H�"׮�SD7� `�;�m/�����A�̜���?>$�O߻3^�d���$,RQ܂1u�s���ds�H�dɃ�gA��/��6�y*�+�\n0�"�i��Ac��[�+�w?�^����=�a� �z1�m'��?�c!�{��9� ��T��]�P�)��� 7''��c!
_b�I[����Y}D�*��]TL51r.e�۸\����9|���f˶瞚Ί�6����a%��1Y�������u__�`&��w�ֈ����E����V�/�~�[�l���@q��69V��2	艴���Aӡ��wI��X�g�k7���8�	��D@m����&xZ�
�Q�Q��5�B��Ŝ� h\��~����;�IYx��r1��xܱ�����>�,gp���[��dS�Ux��Bh��)�Ț{I�i���c�k�{��w+�C��"*���1��o.�5��j�p��^Nƾ���<�<]��(	�9'�#&!8��o��a�ꅻ�g�K�Ifwx����1-��bmL�SD'5����\Al\/D9VK��pTlA�{��d�?#k|���*��Ej�}QY{�V���0����0]H.�w���'�"����a���:�U��}���?+��I�����M�_>�� Ǒ7����/��T���D'>�տ���k?��~�^�[A#຦�[g�Kxp�WS,l4]@�������%K�<W�����6��k�6�]u�M�)bp�.u�fVn)u�Wx�1�Q�f�~��&	e��H	��gdק��3+ �����hp��e�ә�B):7ޣ��Hb���_#��B�<��,+v���0�j��w�n��]$���L�2h���l~��Pt]ޏ��c���a{��c���ot<�.ze��7<P ���TBoE� �����X5����$M�qSM�~��^q2̀�1��\��L�ٗڔ!��&�N&L�H�{�w�E�J�� s���W0(��I����ǫ�� "�+��$h!��!b(�g27��1=kh+��4�� 6<����8�{����&Q�B�B�hғ�)=U��3�˘)��|�b�D7��R@�?Q��so}�USK��=�S���V��\��l+5�D%�pyg{��"C��S(\.n�o���Z�pf ���_|��e���>�,Ӕ:�#K��!u�M-��� ���&�`�٥篾-�::ޜ�7[���X5����c�fB-I����s�]k-��b(�k���Mmم�ۓ.� 4��� ^��xg�A����}�xӁ���X��i���o-|��{fԄCOn?&S8QiҶ���l�B��#g��G��I�8����ށ�b�l�<|�m¬8B������C�9v�P>��^b���\��Jӹ	�$k��(�u��E��C��s�q�����Y(�t��iM����"da�|��2�T�����,��U�3�K��o��ɗ+
�R|C����Fg�i��^�iJpq[R]`v4;5��j|���	����f�؅�_�Fj�9�L��;
���Ϊ>�ð�Z�ץ'З=2*���X}�i.�Wٟ����Z�]	�cc��vP�>xߜh�΁�A��혩n�Rh H��YR_�_���D-���񊔀�!��F�#K~���&����Fu
`�*�+���G+a��q��Zs����NL�thrC�֜�KZ1Q�F���D;9nM]J�up"@��+69�A:��*ȶ*!���7�����ϵN�=@�J�U��mo+^X�~P6���>wR�WT3aK�jb ���dk��y��Fav�����g���*�o���U%/fB���qG�̌9��$�&�������n�S�:��'ZաV�9���VL�Z�4T\�4�T`ʶ�F�=�c��R����o���2}j�.6kSU%@�_�m!b�*oa,��H���<B����P��po#!ß����i�Bb'(����麊{9���d�2DR$�I�ORimD��<�eDht7_���m^P���LJ�w���0���y��r�����<��ǡ��y��<�l0N�\���~3̿C�O��Ņy�U���ĉk��v������d��
�l��3��!�W��^�o�#��
������%j�V���F`���@rP��.4fMҲ��m����9T�B�����K�g����c�{����?'SW��/ժp�o��aũ�;Ec@��%��6i�p��p"��$�|oA�gVZ�����!s�����K�G�W\Q�wĈ3���oh�Ť�Z/<��_�n`>�i{4h5L'~��������(ч�w��<L�CrD�9�S��ߔ.�Ϥ�576/�@��NEz5�'*M�B�#ЁIНZ���Q�+"?|�6�`�Q�4�ՀlyRMR���6�!SI��ivz[����YR�n'�/<	��K���'�t`8>Rh����K�I�u��ԥ�N�%��9�iAX�����4�5KYp�����E`,
{pv+(���r����z�E�A��fg�]��.�IZ�׀oe5դ���(�pV�^�Y�A����k�L��s���i	=-�x�F%���$��/�l��UQZg�%E����M�3�y�[�,�к��}�O�;��?&Ֆ% �jq���,q�䆧1E���Cc���l�|�M�$Mź�[�j��2ț���0�l�:AQe �R��fasA�?:Ap���샟YٯK_4y���+�.16
��R�X,��>���������}�ܪ�Q[�e�ch,ɠ�:�j<�L_�VY���R^ཽ�	����^���!�Pp�xBc���%�-G�Ǩ�?ZY������	���R��4����zj�ߜ�K��s��H�M0�?'�V���+���C3klq���#����s�T��K��u���!�B[��+�)���Ҍ��Yq2�f���%6?X)����Y|̢okc.f�b�@����hTO��L���C���X��}ٻ�ۓ��~M��^�;*���ɰ(�ڇL� 7T*��ZA�����-t��kTM�ȡ(�����c,�g";�m
�(,aYVg����O�>>Uo*P\��+�o�쟦�B��7��?���x<9�>�S�Ͳ�z+2���L�+?Ez��&^��L=���{^NNb����Q頠B��*/=>�Ծ�F�ҽ����m�x���7U�UτX����:j���S����E&��4�� �,Yu��O�Α�<Ob��>q�~<�ᥳSX@�����Q\�B½Q6�S�����|Y���OƇ޿Q�2'}yw�vy�6"��	����H.陼⯼R炍��tb�}�s픖���BZ�C�&�DN ���ý�̈���K�g#Sݵt��x��=��Dj�t��21k�b�����z�]eC�~���w޴ D���n���4)�1���)`�����>ٯFR�\��;	�����̚��|WT���7���ex`��P�1Fbl�#���C;m�8� ��y
=�(	̄�ԌO:7�J�|�g���_~�e���(��l|���#"A���{��gϬ�8Db�q��;�~�7H����,`)��`=8��ixC�U��'_y����~�$��Ч�%v��J0G���Z�#�J���~<���Xy1@4�j���ej����[J�-v��˶�`�Z��3�[{t�A��rj߂�k��+3-�2ƕ�ζ���h�����usa]X{>���IWf���)P3�ىӊL��ˍq�Q3�t/��$y�,���4�o(�}4DSL����td�U%aja���̩�ut�e�ݡ����x?�̹X� 8LV�/k�"�~W$&���$�$"�vG$oOS�9��\�i�}��Aw����k�r��aV=�A�|Aޅ��3���ǲIǪ�f�%�����T�6��AU!����?�SuF�/������1�dU�?��Bh��?���x��:��N �zF��te���?�,#S6��L/?`a~$�L���Ū�*=��@j�f�W3>!6 tMb�b5��W�V�lga�gL�oT�b�b5蚶��n��o��V���������0y�@˜I���~i�-kK�uIY �/�j���������L-D[��m�5�gm�ߔ�K�[v�����<)囡�r�,F��[X�z�����'枆5��o3�^�4#�E��֬�a�["������!�C��$>~�9�/\�C�z~�ߑ�I�B['btN�H�[�� ����cg�Kf�w�����f5:X�Ł�����q aʑ6��6^^��;^+�=�Y܋<�~�m[��o[�͆�T+6�أ5L8ٓ8:Յ�aR��h�@��$��$��R� r'de��cB)H��\ٹ3���``�]=I����<�d���~�Jb�&�7�<i�0�,"���^�G���+N=!��OѴZ��gԼ	�zP��M&�s�F�N:-X��
��{���ퟔ��4Dr�5:}�b8b�'^e5�8*����~'�|�i:�W��8�ʰ;Y2j�����@����G�� *5nO.㳨>�vT�h̡f��.��v$9Us0��k(��yC���V���� ��W���ߑQ6y�/ڤ��   ađl̄�� Ӽ��Aaߎ��g�    YZ