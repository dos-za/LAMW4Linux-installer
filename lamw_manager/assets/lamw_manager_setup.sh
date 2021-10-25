#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1158930676"
MD5="03ca2cf3c7cdaf09bac972c195a89736"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24104"
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
	echo Date of packaging: Mon Oct 25 20:51:51 -03 2021
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
�7zXZ  �ִF !   �X����]�] �}��1Dd]����P�t�D��R���_,����w�4Eɜ��\`!�D�90$�g�{(���3�(�x�	'q�\k�7&T��ƀ���݇��w"^����"D-�f3+l�����\����_
]�)����7�<w�Z�g����X�i���1���y,�$��	����s��'�m�����paƭJұ#/���b��eJ�O!3��k����2y�r�R��&pȭ�6f5K�D�1�G$��_�s�1k K�j��C���8�b�	$w�eCH�_c�9Ռmض��=��C���Ī����4�X1bM������4p6جoiC\Ɩ-2�(���M��f�@҈��Y��,$��cjG��/��P����Ra�5Ţx�X�C�h����kZ�v%ʋG��n�ш��t[?�jd�-�@��s���|'@ݑ�"t'�ouS�~��O�^r32�V�X��x�U�����q;J��CH���WKL���"8L��u�}����9����ίhR�gW� t��W����Ъ�2/�Z©øMv�?$�8/�q��w��f�0~)"��S���Iv�.>$�w��-b��i�"Yߏ��`.��G��L�X)u]_BV���o׶�*�DZ��1��%��h=Үy�y�#EIc��k5E��K=(V��ɢa�l�UzQ��Pp<�������?k�_���@��X%��:)T{�������#��R9+����
�I��,������f���o�t��5���qP*
�ٿ]��D���Cs�e\܆?��,`���ώ�#�L��7lM�^;�(��V�*�q�}4��f����q�)�����viv6�SCH�Isvr�����f3��7N�,�b=��c|آA酾H�r�V �__����OU墐I�`B�^� �� .��Ճ���|�#��N=KA�O�m ����(�΄����N���P�җ���~�Ҡ��%�_�}���v
�M'�,S�߫:�V�,m��U+zb;�v�w��~�`��g�Z�=0�S��0�+��P��I �IFT"�'�UQ/ȍ�?��O;,(!��m�g#����ʩ�`�ղ!E��f�?f�W��tg��&����s����z�.�ɠeJa�63�TR�����YTr�ϔ��C���O�`���1��/fU�7�W6ߌb�7B�z�[�s(��+�,WJn ��O�+g�nx���k�H�����(��)"���vL0{�A�b��<]2�n2���4]�+���{|=��w�I�H�?�TF^*���yh� ���%M� /ȋX���'bb����Z`}�7k�����3�$�|�zZ�֜����nD6G����4A[>pX)Ҧ��i9��+�����\�� �������Ə����t�t/~Q<koB�`'�gN�Xl�QU"��G�����0\��rQ��ISCCkIg�]{GG&Ў?�{�:��]�Z�ٝ��y�r?��w�Wn�C�:�A\�t�s�$GYBpWtR����N�-�dY0��\�R}��7� 8�9[
��B�:���ZnNE#�zu�P�ۣG_İ��=�-�=��:����L��)�.GJ�1KD� .�=eL~�c fDa}J�ݍ�Q���`M�JƀV�r/���c�3�;��4��-�Au-��<K�q�j�p̐���>�H��L�!��; ���D���}�J��M��E�-n��uO��!�g� D�B=z�&.�+W���n�jb':��J4 ���w���:H��?��Qk���w��_�ݑ_�"?�3Z]w��)�SSXCN����J���_٭�g�U�}���R]d�L��/E�rb �GlؓS��T"x2�Q�b���#>K׻�ΆB^-~���6��-��.��t�	�	�I���e<ajLT��Et`��YZ������pR���u�([�%� �%�
����nT�seF��r�;�)��������ڢ�ZkO�Ѥ%V9��6L�nttm�ָ�盌n#�ĘuJ����iJ����`~"�&�P�g�e���ll�n��]��'�P)�e��]/g���H:��o�hz��`���ピ��6�"�W

ڣ���W,���y�	�v��AOD���5��ݲ"nr�tuZS7+��\�w���6ope^��3��.=���W�5�̻P�!�"��u
�Ѻ��:�
<�w��L�Q� T���fs�(�|VZ��v<�ur&o=*M�x�v�B�i���ї�����l)���E�����[*�jK���F�e���OW��J���}���:6*,��ؼ�R}��b�:uY+#G	,�<JY�yŞ�<ؙ~,jE�|���'ת=q����z�w��-,SW5�o������^�@-��Q�n�eTV*�+���wnܚ
�Ep�嬄�J_���9"���K.�'��Asн˫�I���{���B�9!�F@��0֔��_���N	����@�O����;7��㖓</�X���3��n>����%v�lZ3~�G�(2�W�3Y��m92k慇���H7�t6D�=f�s�^�6{��H����^�ͮS_ ��vX�8���3L��طu�`���]��h��aKyf�R�����X9��r�]g�1��S��Z
�Άs��ԧ�pc��
�9~gA&e ���L�b���H=�/�f���6��"(Ӹ&��3����3��ڜm��i�e��z���2���w����_6Yv�&Y�f�驴L�s'�w��z!�s�O�G&H:��\o�h��ǿu��:'C����H������:�yU�HL����(�8�ȸ��2�B�Yq0;�rlX�U���I�4Ψ2��t�ӗPR?��=S�Y2>��\���)�f���l�?GSQ>:��M������H]`��T�H�X�c�]�+5�x���]�h�Γ{�z�oϟQoP��<3O�C�O�� �J)�������d�,5��K �X?KW"ZE��Xt��3I�Tރn���+��Z/�xMm-t3q3��s�N�!��oĐ�<*�Xp�����,?�	Ұ�'�@��h���1����{���m� ��gvO�i&��|ќ��,�c�o��k� S<TN����r<�c��$�Y�-�@8i���z��W�O�s�_�$a�i��o��*x���e��ך�6�߻
��|�9.dq�BW�T���캶"��u��:q�63����ۣZ}+	�F��%�\l��V9#?3�r_T=T�g9��IT���K^��̀�<r���<�ĵ �*!��{�1~��J��8���g��ʁF��c�U$,� �����������ƛw|����'NN�e!��,'�誸�]�Ҵ�>
n���cr�+"%K�KU�b�#��#���5�C?�g�	UX�R�����+ߊS��a���q��O��?�:O�/�xqBe͈۹�x�;�1]���%z��_Yu8Խ^���Ҳ�A7_�&�P�馕FZ�'�q) �d��h'�x�53Gh��=o�qޣz-�f�����ϨQOHL��>�9��j�,@�)�O���Ì�W
Uc�R�����2����3�cH��]yj�w<LW����d���I�1���L��h���2�$�4�xo�a���2���ʆ#� �Kv|�鴑ܜg����8����7X���<Dϵ��� ��!�v\x���f�Y����/m;w]'�c�ﰄC�MP؛B���F	<F��-2S:瑫"��1O&��uN�u� ;b�M���JÆ��+�$�h[��z��e�I6��� �KX�K� �=��Rn��c]<6�Y���U�nJq�d2���S�bc.�\xJ����w������ɤy϶Y��o&�W�'Z'�^���Ae��洀���("X��೘�yE' �	�C��'N�%>v}@K���V�W��n�9H�p��!�?H�e�u����FL03���B���D4З?oMV�-^�֚�dk�j<���;0D��D�yj��j �</O�h�(΋�O��������g���h+�L�,�0���L���~0�ϋ}�:3{���yYϛ^]���q�?+2�w��)V���҃X���5��׮������p�� �@��D&�D��rl��-�'tK�i�v��+&���?�4�IQɅ�epA��] �<�x��U�s�HX`�˼��I3�!�8�?};��N���-{��������2�Le.�X�_#���\��-���D��gD1�vSmb_�2�\�`�h�]U�8Y9�|h�*V�^ ��GY�`u�J��'�M�9�`_�s�\�ͰJ����(f�E��^*X��f�.)	)N>�p3ZM���o����z�}�˕oq-��	gI�u'X�ߔ�R3�7�u��`I~���+�,�b��|8��R�#k�q޾�/�_��yڳaxL�zH���lYUK�N�DI�Gr�*q���d���X��B?��#�������c��U~M[�w�S�9�%��IȚz2���c��ZW��]]�Q^��luo�1:$��)�.�ꁴ�4��}����W�������:Y�jS)iQ
t��J����n9�HB������+Wd.�w�J��`I��a�����Ѫ-��nO�I��X��@>�B���Lf�.�ڕi�����$�m�z{ǽ"s�'j3	��AD�0�D�v�&ɦ	�XH��9��ݱ)��࣫�����0_D>��"�ḧ���/�9z���w�5��(oũ��f�Ϻ�m�����!���q֟����ϲ���y�TMhU S��tG/�]�a�
O�[�4m��F����j�.�E��^n�C�>��e�9Hչ�_�;h��KDٖ;�[H2���{��W0�x�2�>�tuz��@������aխ�S�X�{b}Z��ehQု!I^�Y�-Q�~�ok�A��he��]���ǡ#�BŐ�ˤ�v�ZMk�z.�ﳸ�G���s��N6��9\}��]-#=�]�m^! D6�RJB�\�XU��7O�#�M��Ν����q�$f@�A.��a��0���ld͡�36c��p�p#6v��}�g������1}
)�P"�G�o������ 7���������W�0���[OU���.�#�R��1
��I717�3����G�����}���:U��z�_�2'�;���jY��\�Ey|`��{)W�G�m4m�ۊ�F���su$w�'�IO���Q̒mlt�M�4�������x��4����P˺z�4��ȿ%�O�n�.��$��'.��Do�x��k;,T�L8�y=޳��{�����:����	�d���
ހ���i�c�c�_Z��@���Y�A7��3�G�I��c��	��?��NE��,"��M��s�Q�h":8�uY����M:��n�\D�6k�a��6 v�V�4�m�*]d�͹n�<u>'R{�XmX�o��h�rPh�7A�x�o3my����/��tB`�q�|k۴*!Ü��!��g�kW��i;���r�Z1m�uI�7��*!�B�M�!�;��f������w�^��#�;��[ټ�g,����
�@�� ��L�z7�[pl�u�iT�SW�_�>��%m'g>AV.YJ車Ts�\�(�;���2���QT�U�m�߄��sI�t}����	O���j֭��E?}z�a�%�h*��<�C\x��K �QV�39�ɤG;8T��>����͐�}9E\�ncW�~������V��Đܮ������f>_���1�9�d���QU�.g\�YC�e����� (+ ;*{�I ��Aa�'�5��h��W
1nd��C]@O�u�W�,=IPU߳ c�_WL�-��o�����움��:�%�'�t�"'X��4졮̯�����=��k]���|;�pBIc=�n��
<ĥW8���P>V�z��T�W�$I�Ɔ�x#�n�Z�'�+>
3��컞��=���M(�j����T�8����c�ѭ0p�#{S0�.��_zJX��WB��Gg��)���&�>B
��Pyʛ��S=��=	�������E1�(�?�#ij��	\���=�ד��y]�31��3��X�������۞z�g ��{�FILY�0�E�WsFx��d+�/���ΛU_b'�i�h�)�Y���Ë�3���s`]��Y} ��=�Tk�/�^������oFTxܳd{9q�
ܫ�H��ʹ�I�H�*=�{�A�j����l�(�\�6��(T'��7۫,�R�p$<9������ON����j9������(��@�ڠ�@�G9�.:��_��uZۓow�t̼�H��j�f^nl�h+�NMG�_������In�@�0#�EҴ\Sq��M�f����>��6�G�Kv��U0������D��7�Ba��ޫd�:_[���x�j��L��M���ƀB_�����;H�5���#z��@7|z��*[}uJwfQ��G�y��=y�����Fy5B�F�����jeS^�FA�3�۾v�e���O��T/�^r��P���D�F�v�$��)��r�f��D3���^�p�(��M~AǠ��ٮhI��b�\/�E
�͞󦠙�}XL��]:�1���M�	�=��<"U�xm��,{D�;(�A���%�����,��X�,���(������,��Ʌ}�b��tzk�|&�԰X�yݸ���5�J�x�+�1,X��餈�B������!�)<�QUؙ*�ޔ�eG�50��ܴ��:�,*az�TFm1��X���=�)��zv�����Ї�5t�xt޳A�� m��؇���������5N`��j�L�&h��$?y���-�ۈ�G����{	����$�\��iߵ��;���}L����5䑌)�>�y���DW�f����<�/#+�1D�s��\0�F���=��#VS����N�ca��u���y���
�X� U
v9
��i�`������Ϯ#�Vז�.�}�r��>@ZԦF@�ŵR7�!]
���[e����V���t8��8��ʡ����H��1��28]T.컓����	�!;"0}�`?rƟ57�}>W/�٤�b�y�~8�W0ա����[��X���k��D�(�LJe�b�� *�}�[5�?�5��2�_:�G=b~+��xQEQq/����zUkb�(s;�蝏�����Ч,�/\/g/J;VcI�w��I�}�r�wW�K��J�2�^�N7���8x�˄:v¼��Ҟ�O5��w&s`��">�`�qK��Z�B����F}
�l���7��h�Qc��'�2v�ۧh�V�{�@y�F�~�Su4� 	�\ՒSKc5rBj�r�е��"�C�%��
J�)M�@�o~�n7�p�m��p�Dյ�I͒\�����P� ��ֵ�)��ߖ��?H��V�zWXN�LУ@ŗ@��_,�����KV�߃�RK��ċG�U!pݤ�)g]eP1h��Ƹ�`q�{~�����#�ٿF6(�~��xB�3k������"�l���,R��b��|�}���J	 r������,�?a�v��H������Px��	��<G�v�����kKT�;!�G����
�$N�:�a�:a��m�E�Xc:h*�)�����d�0^��%)M���Z�(��)kR!���Emr;�1[N.G��Pd�O�Ƙ�i���j�r?�0�	��F�}�҆J�@���-�O����2��י�v��LZ�uU������9i�]a�_8����������?��!�����>��Cרu~��C���;_\�,c����&m|��G�{��c���*�KJ�?K�n���+�3�K��6M����p������5��� ��SMv��&�����/Rrx]1xM�u���K+��p�{&�*�=^DL'�g �|ܑn>����A�]O�h���xjQ���p�7C�­��V��M6�r�iz��CJҢ3�A��ym��rs���V>��#��X4�h#��*�yu��{���\��$�3�<��|�"[o���k����@'�֓��})Uv��rh|q��_���a8ax�Hd}V;��JQͣ��K��������YG��^�k�o�U�̵��h��
����b��1� �����ǞFl�4�9�Kr��')h�z��~��k{OL`���h�adW~x�&��6�ۊ���q��D�$�'d��C-e��@>��;���A��|�>�� ?/��?�kU$���t�0uz�[�>�e������j�31c����Va$����8!��Ї���(F�(��˙V��'�������7�B ��od�k0�O�;�p�9��h���M��=�z�!,��H�=����h�c���Z���p����B����q����:���#2q!l�̾�J��m�����Ƨ�<k]��oej�H��x��� �bB__ڸ���[L��5D�_[�²�C�ԎT-3z�*��FH�8�K*������}3}g	 N�X��u��e� w��~���$�4��b�B#���j�j�r�6oj���+�zi�&��سRWH���)��[�4�ײ��W�?�@��Cr5{���/?Ρ]V	`�ax](4HN:�6�3�u�W���Im�t�a���|�xj�XĪU�������KǛ��9���sUL�JD@��&I< џ(�F_@6�&s���ʿ�w�~��6�CZ .@�˝��`ݺy)��K��2���nx2��(?*`��8>�`��0 {�4ݨ�>���d�����m��"�u��}vD�T�yf��ݢqčqk�.�{.��y} w�FBod��I�ز�o��xN��jm�Z"�K?�e�h+e�r9��
���O��b�Ԥ#��P��(TT��6�.�g6����xÌ��>�~5����|��Ba�M�ߛ�k3�ƪ'��'%(�|�p`����0x܏#c%��[-ؙ�R��a�>��.J��W�}-���y`�A;���s���M<z�s[���u�q��a�'������)KT]�kuZ��ם��%�:����	���za�W�.�Ʌ9;�����Jk<Ki'���ř&/(X�m�(Z^��t�Zگ7^�圸��R<i��T�����8_ŀ�����ׁ��9t��NƧSh�������e!��1)��~�U�9J�py(t6����@{'��7��l�U�V�M̦$U�[oTZ�:ɾ��d�@]���6��H@H
���ePU0��A� �/va~�ܝ4&V����ᯖ�	�-�JDy���u�l��ƣ��*Ŝvi#jO�	�
�P�b4l�kNv�`t�X�.&��<��`f��&yA��2�\�8����[�_��'P��M����5��HI0��e�]a�@��x�lp�e$��g �����*A,`L�+�t�	6`%Ȱ������R��>ɀ�#ȣY��jo��b�woW 'K��#�Nr�r��@9���C ��O-��3�Q�����,j�Q=5h0}���.����bV���ǣ�
��<�%0{D��@�uK�u<��:y�䁋c�h~�֤�if^�ӆ��1��r�H� �zI�ٮ�Rn�f��f��̓Ū���Ә�[-�M�N|}��T����Xe��,ʋ�v�빱`�6�3�����C��T\%�J7���N����[��F�3�F�d�.���
����x��,t��o������a�!��Z�@MB���iZik+��Ձx{�ͶH�qIv���zw8��.�%������� �'�_�n�f�T���<�!��yѐ��Z�_�?��?��0K��+�i�6�;�	����P�c�
	%'�����G�T�7[9P����� �Zt�`m���ܻ6�{���V�-=���r�S9��l�tp(�/>K����G�<�m_�=���KS��q��V	��".V�p�ʸ�t���P(3�lL�6�T�T��]^pP7��_�/W%�����ɹh����7���)�;�k&����~h:p����u25�9w�����sh�*Z�<I]�k���]�FD�(i6���<�`�ك�� �Z��c�2�Q�v���Z��]�1b�=�S�N���C�4�y��S/�N>I}� l�)��4�߬�	�T�YC@������lpPZ~��!D_�4�"�.�C���;P�X��N�o7泥���,[��٧���<n~&�#�?>�A���i�Wd�v��,LVn�u[�%j�@��U�ר�F��I�ql@������%scm���\Ƀl~����$)0_bhB��B�.��x�5e�4�Fb�J��b�'��i�4z»RΡ��%/����l�l]f�P���Q:-m�>�UE8���.�$˓c]3����o��sj����R��A.�;��\�H28�p�f�z����N"Mg�	� ��:���[o��T�� u:n[���8?!��B�a+	 ��d۷7��6�B�9|���[��H�S�� �<Kή�-�Eײ�;�k�S�i�#�����Y��U�H�2�w�)]{�t��x@S��q�4���>���,��g��R���4��ҳl����>��΋uUN�3�3�&�%��t���й�ƤlUr����E����ΓR���`�G|/9Q�@R�fWG�ʽO]�9@ߨ��=޵&��a� z�i��:8rI>�O>��>q�x_f[{����DI���������{'t�")�x��}Ly
J�Q<\��<^zJȸ������*���;e���S�/��>Y|5�޹��/׮�����gUN��Bnn�*�!Z4��V+�xT�����A��V���ۀzR|:xk�Ӗj<|Em䏾���x�)���+o�b%3H
�y�?Gz�|R̵1ϢUQ(y�2�e2����퀮ʠ�)&���ɉ��>�ߙ��dSB��4�+g>��n���T
���d��k#4��֍�[����M&U����Rܞ�Z C?[s`�B��`��������l��{ə���3��u�<�Ou� �[�e��y�#zM�� �����y�C#?2�ꉦ���i��Wyz�j�1LţR��`��H�0o���.Z:�n����=":�.��/m\���O%Wnhd�v�����}�j�c��u-�m��\���o$�����ETE��d����)�mx���p��da͢���O�r��n�l1�E )�[6�	�El�謇G���`��_ ��Ո���Y�x�<O��0N�w��M�Q}0�mi�\�;�S��6���Əd�y)�7p��i�������]�u�@���v�Բ��z��~��!�J6(G��_�[&�2�������V��p)�x^�DpFՌ!����*q�
��B�}q;�"}V�H���w�_���a|?�&�l�%���ߖ�9�z�R7�GlAN��H
�ħ�ur`��'�����������q!��X%,���̟b���1"�I���r5���}&��?W<�wN�KSqx�����ٜ��bM!�ח?gTt��H�Ej���|�ڰ%efOA�X��g/�������1X�N��z���,��_",.2��kG'gkS�^<:W���qCo��'0L��^�n�anc(����Üb8���
��n���r�ğ@�C��#/��p��Y�~�Ƚ�W�� ���P��OAڸ%"��h�kU���ۢ��;'l�8��;z�S���s�N#��������"�uə�>2@X��Ǒ2����٭��%�3�L���3뒐<D���	η6�[��
45l�-&z���y�����A��m��O��/Ag ������L� D�nCL��+�*��=��H����zU���ꃻi��gChv^u���99�7eC�9V���8,h���yR8J�d�ue����ϥ6<��@v���8�Kz"�3oG���%�}�-ǣ9�b�@������Q��8=�'a�䟗�+�8Q���[���(L��c8ON�#�J�d����n��L'�s���a�z9��%���.�٫pR�ZkX0r��.�����r (%П�U:��I�QHh&g�i��!<��g:���=����b�{gĚ��.>@ED}ZExd���҆���R�y���L��kO��n�oz]S���Ǜ����5* ��b(yM;a���Bo����r�o,���y����oT���f�J�Z �8g����Q�Q��M�8�bxMXH���E
�
���7�^3mó�c��D�Y����=��1����,[W�,��~����{�3�?#�w���4�bW�S���C��^�k��<�#U�[j.B�J��[��(�]b�`$�m%��<�ᡊ�Ǭ�Y]�.�C���P~7���8ɮ�Q0D,��w�B
V�R�Ǚ�_s+ִ�\
z�k��6_���h���2�vR���l�/�l��@�\OL ����M�&Rj+W	�Nn��ⶐ�h�����ɋnn,�PȬ������j���.*�o�oFYJ~�p�"O�7|E-y��\�fwp��xi4l�F6Eۃ��P�j�F�=����ּEYH5p��gu�9�`�l�+Z�GU��/<�����h���-_k�O�pD0o�Xʲ6/�ƻ���G�/D0{���i�kD�>��͡{��A� &�=�I&HHU=� ym�9��f�<l�!�4we�Ũ�LV ;�y�	�jVOgTG&��|쟆(�.@����Tˆ]dI�ǩ�M�4��#~tg�!��h����%U��y΅��a;�����I>�6�)l��6��`��5�皒��`���08����l���l#i4��qʠ����q;�hM��<
0ٌz}��}���JAq�cN��O���"�.ʹ}CZ4*Nq\mѷP�����X���~Ȫ���)]6�5���	�x�82F)w�t����Azٺ�(v�1�7�A~�\TϨ��yL}�WTf��r���<����ʝ�o��(�ЪZl<A[B�y���va�i��E0��?Ƭ�[UL}}J��:!�
��Aէ=�������&�vs�=�b�����+"��y����.�D��2&5;ŭ.���&��	�0B����� ��VG�(�\ߒ�?��4e֗X]��ɏ�᠀���v�PJ7"j���R��=�tx�z����&�.]3��1���+�A��#�Kj�L�F�ꈅz~?�(����!s�7�Գ��ۚ�BO����%����(� ���	i]�R���^����r�7��;�
1�`r*������s*f�7��z�#Ҷ���*�F������9ݸQ��-Hg_n����7)K���vǍ�$��MbP.Il�����DR������t���6^�	yΜ�u��U����n�,���L6�D�I컧�M(ZE�@��6��w!���3��+���?�?ޮQW��F3���KɊ�T�or��ԉ�D!��ʊ�m��![�����D����,�Ό���V���p޵m�;��'m����'A!k'�5�,��lC�.]~L�0�yh��Q�_�hZC�{��6��[W���-�<�
d��j( x���l�=>�߇��lh��7�$�PB��	��mv|���XMs<����v�W��b��K 4��+a$���-g�:J�и>�91��X�X��n�k�?�Q��4e�-���&WT�^݀��;������$B��'��a#N�;ɐ���*~�h�Qn8T�vz����;��x��8��|Wd�r
�)���,�����S2P��µPd\�4,��-r�ͷ�z�U��V��ո�r���W���|3������nwF�a��.����x�pJ���3.^D!sT�:�1<�5��/�a���NgNy�{�,T%�S�ͽ�c]��|�ĤI�Ku/`c�
Xt�ߩ付O�t6�,���_�|<�-w��yg|���k=��굘����6��F�ԨA~�=�ä́/����,7��{)
ga��?�&���)l?#L�	����~��ZD��چ=�x�0w��s������7��*�����yl�J�?r�j�Z�5#��I(HE��s��x�,ƇJ�K�������!�������:`��aop FzD�8#w_MA���s[�p2�aA��vZ��_3{N��W(]�# �))�rϲ��:́�s[�"�E���WT9x�j�T'�I�",��ax}ϕ�^�{�����Wus�yqs'��㼙��N����6���oG�%Z��l]����#�����ߟ���j�Z)H�^\�wH�;~�M��kL\�t��މ{$�^.VGӥ(�,�����yr���ת��Mߪe$0��p���(����yvJ+�Ҧ�+c�Pa��[�B�b�l�Iq9�.+h�:�=�n^��������ϋz���R��B�V�����aj1�Bv%3P���:��m��@%��{0�����7�KOϣ1����P�{�skI|�X��\\��s@1�DW��=����y�#�����Jh�F�B��yDw�������w5�H�*��������A���0�����.r��6.���P`���Lc�g����t<��Q���v��u����JTf {�;Oڰ�W��*p�"JŅB%�=�\"T�<�X�ð"yƛ���R�1�hu���қt`�v�F �F*���2�:;	�h@`�bnP+�
Kך=�'υ������H��c{1��s�>���*���Η�ljx�C�R�`���:=��~[C�uy��/ٶA:���e��|OQ��V�#�]m�n�;vl���$�Aj����i�"wY�oy��0�ʾ�a�rˣm4 �����F�z��x��tA-a7F_\Հ&뢜1����Q��W3ڇ���~���7g{ų�T]�o��y�f�2��׹�C<�DL�	"��ip��?��U=���A`®��rB���K����eY��ݫ���,�Oy2��6M	���)5�ʫB! |�>�����24���MS$M�_P�ioV�zgJ=����4��k�x�0zzc�F�B��i�z��O[c�Z%�h G�އ´�`�0�Kt�P���my�1��<�2.z�Ob�7�9vze�k�����[��V̔��C�v$GpR�k�Sc��E�}Y����KU;���I��T��N�|��~���?a��U�
�f:ٮ�����Yo����g�#���|H�'�:O����M���8������+�-��W��C�l���໊%\n^�B�@;�XH�{q�QѮ��Y���?c1!Sr��JJށ�(� �2��(8�ꤥ��^������6Iȡ)c\���4����x��<�8K=\S,=3o���"�
�bJ߰r[TN���V�WW���7�3NIn1;�����;;6�Wb#�*ma ��R	� <8F�IO���D��&��ONn�\�!�
�֜rBUǨ�������5�6���<L�/ɀhm�e���,G#�Z�+O�uS�H��4�5�זEYN���[J�I�ؐ�J���
��	h�i�?s�[V/�?m�����D�ع,�����f��S�.䟋���e?3�G�*��ݶ�wY�5���|��o9<��_��Y���b�>e��D%�{����_$����y!]T&<�OO}6�/7K��/��|�V��1)�#��)�P܌U2w�D/ h���E�gڃYx�N��c�-QO	��«r������ISmĽ��9�����TV�M\��F0�,�]p�6ضgWv�1q����6)ٓ�I|�zޯ�H]�+˸_��?��OʜY}�{�S͛Z^1���Ϡ�(�_�wd� E��I~�qB��bG<I{�x��С�D�(���a�9�����Be¹���J�L�������
MDE����l�`�6�m��\.����I,�	�j	;e(�ab���Q$u�D�u�R�S��fΫ"T�#2�9z�r��l�cw.����k1 2�K��;��fji�VX�����P�@������/Põ�Z~Jj�w�>�~-D�'��"���NxȞ����c6ZkxP�R���dyZ�����h��
etVo��I�[���q{���~�1~.���Q�q	D"^�E<�HU��E�*��iKȲv�w�;���_����Pz����_�/��Dc���ħ�a�p�������Pc �֤��*)6<�V��O���3=����A�G񦋼��H8���(��2�ڈ}A}a��s}�^k�h�����ES�s
����ӵ)���yl�~�n*{�0����['�� �������#@���|NR37�s������${��������$�J�Y��&qT�0�:y�F9��!Cj%R�s�u�,oJ��B����������)f�>A���U����ͼ` ��x�\� �����ٿ��0��l{��4����T�L��ow5��G�����0X���م��)Ӫ���TCn�(����
͊LV�����_�\k�R끤=��~2J�Ш�Dkx( �΢y�e��+��_@z�{�@L�w����("g	��f���V��tj��K�G�n��4�P�����\��n_L�h)�����5q�"oܔ��ē7���L�y��r �(�������9��+7vhв���@p�9P��B5�����	���f�8��jNK8,���p\���_w���b;v}�5��5����:e^�B��6��o���	qq{$T*}��*��2����(r����0S4�6F�������/ш��9!"���9�M���:��V�e
�*`d�Sf���
��)��J��R�G��R���+i�
��	���G���\-�J	7K/��e��#���;lq���jV� 9(��� oՃ�'|��x��MP܇�/��U�z�K()���E�\L=!Ζ��ףc֊�F~��P��Q��!(��2F`��1a�WI�"���}x�XBs�)d�R4xI��Uwڵ4��$����J�8�y$�d,II�m�� ab�gE�V?l {5ɻL˛��UdX"oNm�ۮ��=� �!M��#�e;��3���n��ȏǓ|�s	GEZ��<�T��1��#���Q咀���=9�|H5:y��O ��M��?f����nb�t󝽊b_Z�4�[P�s��19��x�]�7&*���ٲ�8��κC6����\����7K�{��	����A?�7qS�]�~�1�W�������[��V��l8_E|�=g���̛C1�׀�_;�b�콛^�Uw��Na^�x�a�
! j�b�b�UW��xGG'EfWS�\�`B�i���,:���mf�1��4t�E�%�J�+``�͎%��q=���ۚ*���٩kqK�m���f�%1����];��]K�^"��0)�&�,]�������'q���W IW��Ʋ�D��*W�TP���"��G��"X��1��CZ�>���ʕ&������Z7Nwj{V=�3���"ly�q`����Ŭ�����~����<�n�M\����C��,2�21�Y�O�c��i�4>9d��OU���u��z�����������5@�w�<�`�*�<��"c���
��I��ۥ��q���������L���\e�#��R�ZC�2s���\�h'T�LD ��p�#�-���x	V��ףL�heq���G��](��>"Un�	�]����3��  S�@ީ`ŋ�2���N���7:���L�ӧ�|V�h�c5�x�WaV۔�Z|$ AA'ӟT%���FI�޽Š���G�b�jqW��SXs2�y$��0����l&�p�[M��\�vՔ6�>;�~��(e��F`�0��i���3��XWWj�x1�k	jm�z�6�$P���	�nG%����J���NPn$=F+&-8�r8VӵWiHL�'�<b2G)w�d�MQ��{"������ˎ{���q��E	z�� k<R�����"��S��*%LQNm���������Kme�V�I�b�z�i�p���v�1��R�螞��K���)	vϓ�0 ��\��%��(ZxG�����#�ěߣ�<�+�(҉���>s���x�X�+��V���l�V��%Dɐ)�d҉��zMa'�AƁ�R.tL]�5{'Y��b�|&1��Y�7v���}e�Jn�(��н !T��ŗ��9��Dp����ʻe`��@�'�.�9��"z�C��u6	��o�-�ߠŦ�(��������Jw�� �n O�nc!��`��(t��ݚ\�������_�Y+�<y��}�#⁪^]��0����<E��FϙnFl�0�Z�s�`���޶\��@���[AѸX�;+�+fa����H	��!��o�p�۵z�ߵ�?c�w%�(}1�	jq���ɾ�m6rP��F�9�_}��k����s|6������hm���C�)E�����D����Çy\o���w��m�nh�b��gD�r��Z��TH[9e�e�
����3���QjdB�7a��9W��~�$���4�'���O��_����a�+�-&i��|���	�$���ᰘ,4.�b_�9�a&[L-`@�tъ)�1
\�09�0���m���
���R0����Q}g~1Vh�Ec��[ޅ~��iAK�U���(�I��Wt�����>2�9�7�u��度&ށkv$�	G����n@��,�G��� �j��QO�L=0���"�_��]D�/&��P���Y��3��gd(Ë��曞9�a�j�m���_���9V˻?��2�C���M�]�݆4
���Bg������I�u%��q�a�2^�z̓�gve��'�z��a��K���ƙ�^�Z���`N���a.�'1ʏ�j�,r涶�\��"������,�ψ�?~���@�(�z��bD����k����K�8D���Kܳ�+���u�׽��ߑ���J��q{�F��  ��SR.���x�q����ܔ���쪊�[���nķ+Q�h�UF��ȼh�,z���^@4�l B�$��!-Qt��&:A��Yy���9P�JDq-���m�.]w�3��y�P[88�����g��T�2Sm������Ø��@� P��-[vB�6ｮAVT������%�`y.��&<��Z �E�I�����+CN��8n�u�v�Kʽ&Um��:�0LO�����Ss�MC���!��#�#�CB`�o\o�?��6`�e�-�F����$A@	+jP(be�8lH8�|��
¡���:(x�~�����0]Jn ��ҸWC����+;4䲫yy5��8����靘�>D�M1������Ɣ�Gr)���.+��s�XQ��p����z�j���}>�:Y}���+,�Tz�4K�x�������:R@��#�T�JQ��]���k�=�k�W��\�Y�]+=@�Co6L�v�s��ԭ�w��UJ	t���z$@bG�K���㞼 �>�QzF��f+z��'~>���gu�ȉ�!'���& �a���f��>vVa ]��d�#��=:���;�{l܍�&P�ͤ��ro�3,�p(FW&�"�eJ��=��޹�"¶�-�ʲ=��z���Y9���� ;���Wm��`^�f�Vy��BKU�c��EHG!E�s!Z�	+�2�J��|Do�EŬ�˵e7Fj�?��߽�:̚_ä�T���+�ԩ���Sܨ�6���\�:J�#��=5�앧�1�ۨ��N63�Q`e����˒���pUz��)u胇:)}�&��"@��9��ȹ2[���Xðw������+~Kә���j�|��T�I��5iG�̈́9�/��=>�
bWE�7��w��>+��p����TH�����2"�Ҍ��R��0>���J����R٪��!2����Ej�U9k�:/��f$Q��V3�+L�?
>m�CX������z������օ����-�c��.W��Kx��Z7�>H�����wP��
��Z�r���B���8so6ʥ����jK��w@�(��Fk�8Y9�)q(�b�%���-�t
cy:jق�(1�����x��4���A3m�o�ʬ�nmH��l�ň��"���G�4�+�>���{%�v%�a�K�$wrfITy�c�%�ʘ�uAΒ��}���3Aٱ<ʜ!���%c����}x'�*�zK"Al�Ձ���k�=J NZ�2�e����U%��=���ٽ�σ�0DQ�3���'nfɷ�ϸ�16}��y�1�5�$���uU������Pnt�A��|�8y�a>W'�$&��ү�����50y�@.�hB���)�A�M�w�&�w��8
�����q� ?�@��a� �e��KsH��k-�����S0�	�>���b�w��RdV#*���b��5��l��7
�N��4"K��0����q�a���Y,�媫��Ã�ldc�[��0s91�ȵ��A��Z��q�\�ʺ�E
���Qh9������*��� ��h��[�oߴ	�VG�Y-�ˇy�����u¯a��])���4����at �6q��_�m]���,����~�G�Q�~�*��- ��iE2Gr1��Q"��V;~��}$������?h:��$����i�նx���IY\2Q�1����p���	��&��?#o��o�C����\~ޡ%C��`��'l��!5��UtTޖ�����<���0g��	J�*_��b��h�����CJsU�H��փL�ʷ�)zQ������c�1c�k��o����1�E�}N�]}]����K�8όl��NI�o�o�B��2N��x�fa��rQ�3��w�okW&���H��J�
8<3_ϡO���Y'�L�����K�j�v>Db��O�۔�������`�U]��Wt� �LkG�G��T<Q �9jB`��}�4m`�/�29�"pXϓ�V�`M R�,_%%
��S�U��ҩQ�7�#�3��(�""�:��_Y��zl�V�U���`����~��D�76kYR��� z��/3�e7�fZ��~���im�ا�e1�K1�H��������r�[ "+�Ov��1�<;V�kƌ���?��ƔE���8 �A��G)UP����������W�� �v���*Tp�Q	���r�-񅦮���E<�:}��4��Ω�
���L{��C����?�Lc��.���i�K���;���R.�D����a�Ϭ����<��N��M�}f���b�\cPEt�+�i���w!݌�e;/V2�mQ��bGw�u��$f�tLց�=h��q</�V�M�¢�A�pCP�\5k�MJ	iX`�)%�����*�9�)>6���m͓]S��wf��j�h�c
@���%�P�m4׆"ͦ��s~��4�^b�2����ao�1K7*g�'QH�='�S��p~����k�޵@+5#���W6�:KNf����-qy�OR#�j�CM����n��Oa�L%R��`ay��B��!�U|%B��al��s�i�B��%�|҃����R<�5���"����6h��� pO���V�0���Z�Rg�ɯ��\i�e�@3
��>ԥ�<�8k�d�Il�O��!	�Wt.���f4��_8`Q�7k�C��{-|�4�|�Ĺ����K�- �����
�JAٿ�4����omT/f�������7>3"�&v���5���6Qݪ�ֲ<9�*(�r�O`$�[l0�����v�&�U�ɼ�H)W�����1m�%�||)�;W����k�t�p������<��G��I3^�$�m38~�y?u�Lu��Len��%���¾�V�vlW�rU���ѿv����o}o(#j/�AQO'�}�
ۛ��2tl
3M�&мޟ�A������NJ��\���o�B=D�'W�6��fC������R�NB-�u�B-�i�Ew7	��P�l��WOe蠉�W*d�:Qm�@ޔ]Kb�7V
���1)3���Y2����=^�:A��z�Vr���m
��ښPY���5��j��A��}NƳ�x+&0X�	|K�a>���n�s��2�������Z`��8_oȨt���?����ҿ$�9r����mD���`�<C(��Sa�h�]��iށo�D ��~�nES6}�a�.*x�N3u'�X�<�]Ƽ){׉��9�&�ie٥	#�JJ�n���0�rE�x6�d����,���2����Tʁ�M�>����8|±�J����W4�o*��s��0ʰEl�ϻ�����C�M��HѤ��?{���Y��Vl�  ��jH#�/nv�}V$橻"y��R���J�eNt2Q蟩�.bKE��D���v��s�9��Z��FGg�r �v�W����`�[�}�7�'����]�z�3������;�#t��+�?\��0�y8���s���s�1��eP����Ac�Dh~����T̎A�)��%�ײC���|�3�0?_`
,���L,+����?��:_L=m ov�E�Y�����!��~�d��Β�$����dd�P�̬�bw����.yP���;�l�El5� �Z ���3��H���4G3΍���q6 �&��=>���]91*�Q��
$e��|��W��0��繋,���?%����&�s� �r�����v74J(�Z�Ր�y�&��\5��V�7��c➯P�����ڒ��r���Z2�H���E&)vD�v
��M�^v\��ن���_�f�?�o��V�w��}�RR��p9�9��S��=W��5��tG�A��x���"`^��1u�y�d͗���Ĩ��Z)��'�(���+�`ڙ�z����w��')�/_N �ĉ���nL��W�>0Z�0�R*�0��~���Km��	�z�/��ϯ�_2trL���?v������k��}�<����
�;c�_�{���}��yR��P]{���ݓGWL�V���"�b��ڂT ��z�m����yGέ0.��z5r��.�<|�ԥb�� w���2Ee>��$�G]�n"W�����'���=�X٦�d��Sݬۦ��_tq��\�v�~�1�W����F8��]�����NE�.�R�Wҩ��W���?��)W��� ��X�8�o�x��j����2�61M�xP�����ۖգ��;I�i�*6_��8"�R&�;g����Z�������u���N�,8"|����֏���w��md��=�t�j�GBi^�Xǀ�%� :��m9��ѧ_���F�;Ɛ��N[ه�X�&u��dc^˙yA|�]@�1q����2��͎���in���ٛFU�ش(-�b�����W��إՙ�q��+F����f�����r���q܉���.����NJ�e�] ˝0V啨��w^c-��?+�����:�鲨����:	s1���u�l�>�r�:QMԤG��kދ��<dԑ?�Ō�Ώ�ڋ�b��Y
�Y�*{Y��(�t7c���|�|*Z3�n@-| Vl�]���O0�8��
-�f�J?\C�T��>�Օ��$p�+I���|���V9�R��he͜�d���)hiP�3eC��8�|�Z4F�bÍYEQ�v�a�}-��r��!��Acr�I�@�h�y���Ry��>������-@aʴ��tQ\��
ƯJFL/]QӘy��H    ��� r� �����iQ���g�    YZ