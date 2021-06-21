#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2464036743"
MD5="42376ec0bcc37bfd7afe690d1c542556"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22940"
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
	echo Date of packaging: Sun Jun 20 23:33:26 -03 2021
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
�7zXZ  �ִF !   �X����YY] �}��1Dd]����P�t�D�r���_��b\�i�q�վ��ݚ�u�>Ӝ>�K^�؄�J��FS�R�BM�{�ϕ7�c�N�I�VT዆u�����f�}.M<W��~>8uɨ��� �T#�ea ct��	*Db�~��U(��oV<L����&��\�Ye�	F�fV���L��f���Z��,}���Q��wC���O=ka]vpL1��P�5�ځ��Hؚ�g�%u��R��z����.��3���ST�����z!��+��ut�~�ŢyF�xU�܉��bO�cwc��Yj����E��y�)������t:(��G�X�u-6���о�����V;�� Zm��tz'���%W�@�lNe��@�t�g��YQM�&M�o?�	�B���~/�FҦ̂����Sa4��X-!
�qh�@j֯]l����/��~4L֎2��A��Nd��v�:�JM�R~s�%��"�TB>����tm���-���ߗr�<#^�/��/
�C�`�Z����Ex���,�����ݯ0��*6���$�]>)����\	�}�J����8��)�������h|�:2'��ڪ^k`�klb)��|�u�sbeʱ��˒������`�I��?^&��j���9�@����v6����Hǚ�z��뛩{��� �Or�_���C,)0 �S�1d1[3�I��S6���幥	y�.�����_���Q�ѡ#@�G���ژ� ��a�P!�&�8:=X�G�y꥝"[��/������HH6N��6*�
����e�5�G�͙k���o��ݝX�Av�3"��3����?4�t��t��;���l�(g�4.N�s$읛u�����an�.�Q���+]"{��i����L^��-�����46O���D�͝Y���/x>v��\�č�6�#k���1�ĉ����'W�u���,q��G?��E�#�"�F8
��?�8X���ɝ��D��ji] u��/#���|���q ��6�s����jB�xw+�/�+�3�VCy".+�.��{��;o}� .��H[�"]֌z���~(�LM/����lw�
s��*�n^�S�ie�"�j'a��c������Nkſ�-���٢�<�>a�[��6�rVD�u�9�����4!R��a�70�U���`�S\����8P-i���Qm�����(;d�j�w8�����ǹ��\���Nj�l��r�v��(W(88�y
>B���.��E��5`�(�� )��1����Q�$
����a]!Ғϗ�Wf`�Ҟ����Pl��:��.⿟���'7���i����C�Z��`�Ho^���_�*�EVV��jl��d�B}�F�Nm�d�3�E������ٓ�e ��~|�Zr��� ׄ�����0N��� 	o����4�X�L�5�	;�?��Q�$1�k�"p���㐕�x`���+d*ekZ��]��Хs{�#)j����FD��X]���Am�� �}�7 �c&��U�l�^򼴳l�ɫ_E���JI�
ŀ�$��ٶ�ma�G�Fԅƾ�+	y_�Ɯ���t�*��V+׫-�D3��y"KE�P�u��b�oj=�R=�D.2.��#��.�*W�H�� ��G���W� �+��q��&�-�(r!�[T��{<�Kٜ%0R�+]�B������3�H��O`L��Q�_hB T8���M��M�{r�Z |0�k���ů�@�mT��Dy5�
E^`�A�Qg�w��`z �S�TEʆ �W�E����dM�6��0k��79�o�[��	��rRJ��Cͨ�:��;��5н�ƛ*�&��؜�Vkז��S����,e����)#F��cvȥ]~#O
W�!��`,ӓ����=�U�:W˩H�^�=<���u�D��w%|�f�=��x)NF2��h���ɧ��[Q��L��}����NQs��:�I�ei*�b��Ү��|�t$���_�ǒ0��Mۖ��a�#1�4����v��(ۂe�.F7�u�2`�!��J��@���o���]�d�s����p+�&c:������z�ypT��Ԟcq��|[n�[��Ha��*�@{�1I�['�Z�]x�M��J�y��߸�n�YCW'EʷZ	���q����ʐ�����'����k+���_'^t���#��Wk�
k���Wh�Ww4u�Y�5��-�S���"Wx~b�VN�^4T)�`��tG�K���ҪQC�����մ54��RN8�w��x(ʰ܂���-�x�F�f7Y*�qÂ�m�5���&��+��N!�4�c�ڰj}Հf�;��%+��W$���L%t�A��%la|�s�A;��5<���
Qiԝ��mc97Ո;��p��)�V��ϒEQ��tn��K����{6���p�r��SZ�l�W�H�j�A!c���A ߩ�t�u���^ �3gm��	��lb/d���6/1l�?&��������������wl��L�5^XZL�q��|{ը����j$X=�Bj�`	�K�*��B�SZ�^7C���z<�,y�lJQ�ɡ���Nz��	��O�ï�~�e�TN��E����rц:��&e��u� �����R�4(��+�4Y�o�V3��#ډ�v�6�<��_��G���L����d��I\ģb��rsA)3�E�i�����F4��{D�wh��q�Q�S�Y�S����p=��MR�-���Ա�(͸o�e��P����;�� ���]�p^��z%������e�7���N\~�m#���h���u�����Z�Ef��rjW�-�#9 ,�O�4��{?����Z��a�Rc����9����v��lō��_�\8��.d4�H��&hv.~�`)W��;W�͂%6���V����I�W���Y�����Id�:Xnw}�V��5�>���{k�ztZ���!sg���
�M�#���AqzNl��+7�+�����-�C㻗����77ʮ�Q:�k��B�1	�3|?�g��ԪZWn� :H�Ŋ �X��M�k���2���/���My=�r���L��!������(���z;m���*�+|�CŞs=xLk���������� ,���!��n�A4�6��e����m������ZSZ��[�Ç��͚YS�}V�@�ޠ�� �	�t����k���S@J	��eJPzAC�K�]D?�[���pw睨T,�̶�BX� 8ŗ������2�v8�"���V���tr�I��9�tRO�� ��i��#x5_����| �AR9S1)`���-)��@�U���\/`�I����^���=���p�+?�!��X^���2�/�@��p"#�C=�V��oWM�/X�d��CD����6�WC���?�M��%��l����L��ڔI�eNk�� VO�zD����m�3�D��y�r9����o������,m���A<��c�л��T�5�y�!-�8���l/���a����Vi���UJ�ht}/��p���?�,a[8�٩�m�?rw�@7�@EU\�����ڽO+*�|��~b���]��Ҽp]d��*��"���wռ](��o��X��A6E$�C�|��zi�1V��E����0 �-�Zh �l��l�'w��Y�b4���P���e3򀗳��z�hE:��<��%q�Z����^� ���3'x4��^�C�����6,��Y{�Ӊ�F�	��4^F�Ւ?�xz�#�}��LwA�D��M����$����	t$�5�M��?y�[r
��\L8���
�[8�U�W�v�Va�Ed�(���`N/��8Yq��Ťe� �%�J)͢�u��@P2�䒂�;<1��>G���h �K���Y<͹�k$�L���js�W��h,���gӴ�~�(�����^5�~��jǄP��ԗ��Q��=�-�+�\�3#�� >�ˎ�g�A��o��G��e+̗������o�]p�������?�����|�3L�rkG����֤����_��5��+m&���� D�.��I�H�!X���J��Z��`6D'��`<�,�J�%o�<L8#S������~�rE�] ��'�Jw"S��hj�2��щ�
CeY�'��.���q�0�D���o��}Fp�)ʷ�w������z'�����qF�dVW�o>�lY
���Od8'΍_{2��A$es����5�ѝ��t���������7�9h���퀸�;%vvNqz� %2l%<�>[`L�ɇj����p��A��%�ɟ��Oֵ��S0��~����⋁��m�������ÑaY�n�{��X���0���z%�(�5�H3�� bԆ%�O&�X��#n�S�c7�r����k�x#�d�B,�Uw�*��[��DV(�Q��Eg@!Q!�(�ʀ�9/^��Zo�x�:���m��y�T�x����:?��F��^���K���Ŷ��moZ'k�]���z�ax�A��5֚r����A�O�b�+�5�~<��Sd^}8B5�5#�J�8�h�!T��	*�0',L��Q�b���a����]���x��qɀ)���(PԋDn��
�k|ଽ��	�^��eG|:����H��a��>F�{[���H�ɝ���h�,\a�m�KZ�כ���L�g�	�}��mKސ���)����~�;��5�(����\�w�h�Ρ!�ad'�y��8�bna��K{���"����_ЇQ2����/u�7(�%�~1Ņ�ji���P�������<�������40��`$+���Ry�G�J�v��.�U�Y$c�Y
ҏ��mK�|�l�U�,����,������W�
 ?�w���c����P�O��d�#����Z�K�y���L�.�na�E�䃤DY\7��B)(� �
�뺿���$��]��˔���rA�Y�j���P�'��=P�G�� ����������a6�%��j�O#Ι�!E��hd����%�*V�;�΅b���x������B�_[�p���3K:���W)��g��L}�^Z[��������	*x3RP�u�V+�i�|8��}VA�0W��@�M&��u�c"�0٘뜧�`}��[W� �T�5,a(�ߝ+Ή|Yo8��6��RLы��!���U���?vJh�+j�*R��{��n<��"(� i���ڀt"�
�W���	=�d��<�3�����ܢ��9���j"�ݡ�{���&e]7Cj*�s��`Lh��܅�,{$Dl�9e�� �Fq�(��;܉��a\c#a�����4''nQ��C�G�?�ߙ�����@(���Ux��X���Ż��[�:�ԝ5Ų\�24I�m�Ŏ)�O�8�������`w�uA�8��X����S�^���r�v	�K��%J	#eTq�*��c:V8i�2�>~�-� -t�=����!�%���: ����÷�z_������C]� ȱM���S�����幝�̛ǥ��խ.�z�bxh"�Z�uTP/�:D;�nc��⟛�ē�&UN���V:'�����f����0
����~-g/��n\�i]Q�r8��,�f/��ӈP��*p�I�����SkǯL2��L�r����`1��C��#�dg,!���^��$I�(i�G6��P��4JMUR����."�`�I͠3�z�b���-�>��7��0:���|��=�JK����w������P�Y��|��	ӈ�eP�x<~g�V@�b��t����?�=<��5�~z����9�x������ ��zEy��}������)r��Y��plz�d���O}�|��p�v>��N��O���k��jF����K���Ǫ�Te�{p�l���O��v�һ���#*�Q{�i������{��j`�x���*��Mt�Z�^v�D*�`�Z�p7�`,n?�6�PK""����	�YJ���2�����ī.p����^:C���d,���䢤�@����$��k��C�۰��*��շi�(W|ſ�ND��&dO����;0lM��ː�BW��Oȧ&�d%�?T�-�ߊ�T��A�v�+�Q�	?��w{P?gպ_�l�F�e�erQ3����W}�q�."^���rF��_��֠���	����c��\[�bZx>�[�!��H���cO��Pnݭ)-󫼏1g�����aE V��Pk:���!�ooG��KՆ��GU�;4C�K�x�<+
�����ۂ� �AC�1H���qq����~��� ��V*�6u~r#��F��ǝܫqE/I`��4f�����@m�����E��q'}�ER܊�y�2��O�Ԩ��o�=��[�o�S�#9~^��NT�F8�yp�<�
�#4x�����M^H��^��r��Z��޹5"���g��|����DM$Wg��[�- ����$�>%�x  4�~��F�� �_S�A��'z�')ynфt��l�l���2ZHO�Sy&�Jg�Ηy;��cH�o9/�.��N2��'������0�	��a��Rc��7�j�h��h}�F�
���t,g��u��[*C�:��՟�s��gQ�w���{W�����=�4h�+>c0�!�Ⱥo8)����05z�&;l�I���:*���6�Ot�y��7)���U�7<��@�4��u'�@�m�u�z<�ú��O�#��)YE0�c���~�nk�)t&�_�+����`�j�1�P'F�ϲ�xh�U�����^�}�;�{�Ƭ7�w�&��e��J7!��	�m��k��#@y�M�#+c�dS��8^bW�Z-���w�+�&��������oNu��=k�i���C����*p#�ɏ � ��/�7	̖��-@Cj�y��r�@�ĨH_u5�����^XE�P�QĜ�d�k/1T�@'��e"���E@�'a�_�D������4�c�U�>���1��Z��[�Ւ�x��5n#�V;�]SG_Pp��nl�5�ԯ�Srn�Y#_�O�Uöh�r��E���SZ�=�%*>��*{�I��qZ�d�:#�A��z����3�(OccB��}�G�p�Xi�'�X�?�J���[͒#B)����x~�EB�A�έ? '���Q`O�������J>��nG 7f h(���~1i��:�v��b���[J?|��3��@#�$�
k�~__��) ��SKcb��p��X��F�.���o.c�����/vįb���%Rׇ�]\�?T\����F��k;F��N��-b��f8�����4x@���V��>Z�^f�h���|�l��-+�`�u�t�]q�O24�qQ�T�ܵJc�g%I�
C��4���xZ4� rq&=��i�yH����fʹu[�;
��UK���DtI���R&���1��0�-���Jzw~a�=y7�AL�⚗�**{ah����6�������*d'��TE�HKX�uĝFxh��Y 7,��J��p��t��T<*t��z�֚	�j�K��}����.��Zj�G�H���]�X�.XAY�KnU�r���ͧ�`VL����TP�����H�gU�p��]�@������sMs�X-r�n<��^�5���ҷ�$�ri}:���5CRj	�@>�8�w	�u~V�'�������Y��?FK�gS���<�-�w4`�teE����<�]�X�N�K
�[cs�R��ޖ�+��30�l�'��ox�p�ʄ*1�q�G6D
� �����lͻ��ɚ?�v�W�������ϿQ11�9�G�Ҿ���,K��낖<}�;��XI��ުߛ��=b��Mp�Vvv\urQ<ء�����K)��kx7��+� �8cC�n����o�18y������=CSP<�í��[/[�<uuL���]��6S�TX��2�\��h� ��>ϵ%�z(@����ll\�f2���O%����r��]�
�^�2�Aa=:���(���>�}�3�Qp%-��%���j�v+c� �����I��P��ʢ��������or&��5�5&3��zTU4�Ŵ*5����f�%(����R�ǅ����'�;�����g��r�߶�*���й���ajN����W���
����j1����K�B�>h��:;K�,bCD5�2�G��">T$������٢z�͚���ן�7'�&�*`|�oD��ƽ���X��X�g����9$K���$�3�g79��4�K1�pmtd�˞�$a����A������ӭkx^O����'�����u��+��dĞ�8�����O�
6>�J�"88��F�-�`s+Grm�֖�g����n�x5����o��T�&%������~���i> 1l�YP+8a�y|�̹�b��-XC����ק���!�K���Gj��'(�eAK��S�r٨8���r�8[a�8k���D_OEj.}|d��]7$��"�_����>�Ӫ$���$��+D��q�����3�E0^���ku�*��y�gnڀ�mÝ��JCI���H��m㹡g4M�*}�'�3/UeW<i�1:�tG�Y�],�f�P5�!=ͭh�qv��������_��|���P 0GXȩ����Z�)j����>�Y�@V�%W�`BF�Z�=��n�� M8�/�T6�S��K~�uF[������4u�_�]&���Cn�ٛq�4'� >̆�Q��G��h�a��қ�[ �%V�O�����cJ�t��G����Vi�_|P
o_��I�Y5
������wG�zV^�Ϫ��E#0~w_��IJ^1B]S�v�G��-�R[y�>�=X	���?�7m]ڏw������v���W��N��ΐ9���"茎20�X_�2-Tf��z{d�VДQ�g/���7�S?r���i}�u��n����q9��?"4�3�LC�A�ZFӌ�c�8�d��*/v��I/ZzcZ!/�IP��e�^��M�����N���[-Q��F�����Ydk�=a��i=1d���Wps�?/ԕ���K6a�Y0a�I}���n�}��c����ˉ��/�d�.IBk�J#�6
G��n�lb�����a&�\�\�D�`����u�݂�
�G{�B�,k��!��J�Uh���SL�H�o����uT�PCs�wL_���y` %x���S^I�򄦶
��.���]�:� v���ׅ��0���R�%Lh
j ^�@O�u;W�Cl�;M`_s�⭃~��{:y$���R�`�r���l�`���� ����ӥ�q{H���z�c���j��o����?���C��3�0���>�S	]:�������vW�h�T)�	�� �[k:{��!�vHi �#{�{ l�	�ן�/����n�^cĽ�xO�?Y	-��.y.���Na�)^�
�X�C/���*E���{4��1���Ð��#M>#���3#P�y��{���4�&�Z���k�ӕ`ޕț�쩰�e6�0�s�b'e좿.P�i-�.-�I��QyD�_�5{)��n ~�[����R7(�A�E�����i�����F��h�PK�`�A��d��_��<u��J9=���?i���d��������:��ƛ��L{
¦���i�kR�e6$V�>��G_��A�?��;$�)��`=�8^l�:�ub��%�����b�١kuy��T=�Σ�y�DG��Hd-�~�&�����ς�p�`9 ����i����k }�O�銪r�����,�+��	C�'Uj-_�G$�T]�y3�v�� 
��_�4����G�.��Mk�N���>n�6�B�ڹp��ӏ�].���[e�uiN���#I�4[lI�8Ͳ�6���ftrJ8���ye��+�<�Q�8'�	��4b	�I�@���h��\�"1�F�8����lĺh�@��^Z�.�]?��h�b�|H�d���_�3�-�N���F��TL4��4>.�w���C�B^��'-�	N.��Ȥ�j����a`�ʚ�N���JC���:�l�5����f��KG�-;�sPQx���.�3,'�
�>��A��5�9%��Ve#�U��ۚ��.�ŵRM��~,���B�ۍa�����3�`�^��Wݧ���Ė9�|���jd~�P�i� u�z����nkyY~n��/��Z6.�~���)ﺱ5��ei�6TF�&s�C`�8@��x>��X��W: ��k��}�,�ᖽeb��t`ΞQ���7�����Siy�p���?lo�Iv6籰�G�E�_vl��5~���xˆ��f��TR$���xl����J��Oz(�M*����d���f�&��S�M��)��:����pd��]�i3�9/�D��Τ����^����o/��`bq��q�k��YA�n��j�5�5d���s�yp)�/�ʟ=�Ꮝ ڋq	�`�T^�^��	)�����t�m�_0�g>?&ӷD��Pң|w+t�	ݢy��K[L|Ry�x��%�K<��E[۰p6������G8���Ύ�H(��aЧ�uU=Ļ���.��`�rT�:�Q�(��*D=�W0B�a"w��F#�=���Q�n���7N�U�y��CHY�J��nA,�U���$�����ґ���s�q$�\��6a)W_X�JFM���w��t��cP-H̐�&AB������Љ���HR�K�̟
г�*�DV�×>`)w��a������F�q��l�<B�e��m
E���"�(I�6�y��K�iێ�jB-YDs���VSW���� u�_\�Q��;i���qmF������G�Â\����9�SH���@�I�N�D:�>�њ'~.d����S�7�pn�1�bUY���x���M`@�����nԠ�	X�
�k����e܍������īUC�v��wP�'0 � ~<`E��`fI����� P=�w���5f�f��@��+:�^��W<���$c����%��Na�.�9O��DY��B �T����Z�	�����֜��E��9S���������HN}�WH�5Z��Ị_�A�*t~�	�HS�cB|@ �3S5�~r��	��,*��UN�Z.[�|�M�}�rdfr�����)eviɞ�:!%Y'��N�^�p��Ž��aL��꩸AU�����-�A"ެRt_�z���ʾ�#Y�Ƌ�
n8y�������_�P<�r�(���q־��=���~�8ҡ�e.K'6t�.`����FX�'��K<n���K�ke6��O���6ܧ;���Jg��V�7H��0t�Q� "�?��[��������p���j٫K�������$��Df{�t�f�ӡ�e<��,ƺ�GQLUD�Vڲ���_��aU/?N�=d�� k'�n���O��)��C`��%w�+8?�^�����	ז�1ϔ���ۅU�����b�:g��(�zDE�� ��'�K�~��e�͙���� ��ad�h�y��\�|�m33�b��\醲τ�خ[ka/S�xg��%�بI����S����軓aП�yd���J�`�Չj6�Ę{���E�E���5OS}G��:Sy6���$U��4��5��T�h%��#��1��n
��dT����!��YԈ��_X� �v9��iPUC�\�s0��D��?�g�s�m..����KS�:�=�F��8$���/�B�UT��.<H��m�B[�G��}�!4v	��kZ"����us���/���	����h�$'�IL3��y"E©2���Φ�b��Wu�8��x���G'�Jʸ(r���U��F�{uΒf��
~�H�v.�=����U����=���Dy���]I��&��A�Mִ�a�6O_�)��r墺�sZ޿�����b�6_y��s#c���L���?��IZ6��9GAc���?Q��:�t�n;�F����0g*�=4fPc`�gi��8��uí����x�㐥z����Kqo;n5=T�B�}����H�K��b�%���c ݿ�-�e���`V݇���Bx�^���%v�K����?,
u�Tb޺Ib�\ъ���ӷ#�FO炓�C#�%��+��&[	?���}�Q�ɳ�s9�3TI��@ꟴh��ol�
�<�� �$�H���3��l��\4�-�b9N�a\�͊1Eٽ��|{��J/�^�1_婬N�?}!�ަ+�* ����cH����s�U9�I��8�P-Z���k�9�t�fEG�dTx`��2�
��$�=\+��5��v�y�B�o�C�B�x(Y �B�dq{mi��:�ʼU<������s�t%Ql<���ޙ�$�Xk�؈#���K�\˜�z��=jJHz����{aC�d�����kF9�H7+⨂0�zs�'M9���t�#l��?M��Z�*g[��U�2D�l��z"��G�7�n�J/t��¡B��v
 BA�LZ�65C6A'Ǿ�.�����M���z�:@F^�և�r	m�u����y�z���h(���n8����j �h�A$�ě�b߱�*z4myC��?6�%PC�r��R���Ǝ��#��;'�2�u�NN�rN�m�K%?��Ӷ�iXUE����2�J�*(<��.o0,�Td4�I=�-��A���>���dy�5QV�r),����i���9H%�m��*��:�YৗRU���ˊ�`����l#�T%$lk�G�� �6R�G%b9��_�?�#\Z�f-/�+����E��a�;�BF���krA?"�(!m>O�0;v�4���L��֎��{���!a*����g��m�u\�f�Ѻ[T�Y�2�tX�J��T�j�%��O�Y�VN$�nñ�MZ���X<�N$X=`@}	A�ϟ������4DͶR��QNM8'�o?0c�PU��Q��_$�� ���>[��K�yi��3���&��=��6d���߽i�kxΎ���	:%et4��*�ϼǬ�»�Z�?#Cv+�c��h����D2%t@l5z�x�L��"������S�&/ \2�U>��]1�.4dД����QŬ�y�-$�=��{4��9�FF]�
�h�9w��a�&X�Q�Zg�%�e�$c�fq���i�y4��,���#7��Q�g~���2�m���? ��L�/�"�˵
6��>(C������k@�I�"m;�$�B�B5K�JH׺�T�ē�c�����Y�`�V�*}��-��s8�����a�/��S�U�����E��6_�b5�sʣ ]�9��J�`v����CW`D��}G#�V���z�`=�9��uy���_��W�E�7(�dɸ���M^g'���5�>�S`2��t��b�<#�1o�s��U<����5G�R������F���������dїq$�	��[�Ѷs�y'`f�I�8�rt=��;��W܏��?HUް�<=r+�h�1,����/9X=���RӥU=���t���G�D:�U��}z�<��z�B�)�ˇ��)�f:���j���D�\�/��e{UfhI�@ߣ�:��.�C��d?��x�Qx�Jv�#��GϪ.�c��Ԡ�M����\,�t��LJ{�����-b�{�-?����(g݈��]�� E��4us�0;d�&	2�s1L30Gʈ�"�.m������j��k!rcX��G�m9X]�~���TT��N����K��ݻRb�C�Gђ(t�A�5�7�^I��y>})rP2�6���}��X�y7�a��$o�GUWt����2��W�'���^�֐�J�ܨA((��aq��}J	�<${�	Y���1�9� �1|ʺ�w@˛AɓH���4�%�р~v:�c�m�<�)&�om�sk��>�_\Y-��.���}�򤖑�=�v�g)k��7!P},���r��Jw2ז��"�|���h�W����7/��'[��ߙ��kF���*b*��A��j��MS�~��p�t*�>�Ցݬa�	�V��@���,�n�.(x�lpybYAn��M��b��t�ML��~�BU�������<��S�C��o$g�;�%V�m��%s��̈��H����I���>���p����o&���@,l���e��L
�����d|a9�݆�M*A�( �
/��8������#�ٕ�:����2�ӹ��M������h,�c����_�d���<��X��]�#P�:�J%���n���{�d%c,����/r;t��r"�P%Rx����r_
F�6�9>D���^�c�g�@lVA��@ð2i��!�����0�B%^�l���n��X���(d������i�e/C59�I<ms���m�䝔/H��LQ^p�j�ނ$�*JN�L�k� �r/S�<b�AcԼa*��|�z[���<��H0������V�Ru�t�hz�w�ūԏ�{����R��ϑK��R8mF�j���Uov�����d�Z�ϘXCJ��LA�����O
lE ��9���0H�fd��	4�Su,��!��w!��9t�tl��Ȯ�e�O��	=��`zw8��Z�%�,eq��*�Xi"�^��L�+N���m|���M.�z���Ѯ�;'��Bqm�I��l��?P�1��u.��Q���e�Oa�T�f�C��z2�m��@�0�5�$��O��$
S�6�fy�ߚڜ���
h�u�j���S����O�@��Gs����^m8;*�}*d�o-n��0�>f7���W�)��SU�zǹ�	���<0�L�S�jb��#���8���N8�^�J(��2�|5�lN�!&��G/0��L�#V$-k���!��~�`�7[\�*i[ܐ+Y��tv�z *�t�x�`� �J l�R���vf,EἺx�/}FS�2��#��Ȗ�m����؎ul�y��T	���t���~�� ���%��v8S1x/���f_9�f�F�x9^�e�|����x�ՠu��s�U��LoQ<�[�۴/��onx�S$IoZu���VF�|��EjASu�0�N�C�(�Q���~YgPO,�86��&X6VJ�Nk׭�^Z
e3b�z����p�W�A�]tr���6��_�cC�? શ�x���9LN�r�)p�G�_��c������7S��bpA���T��Q{9?�B��{S=��*J��Ux�Ԏ"����CHP� %��̙�7�.�⩪���p-l����̜l��Ï�f�-ȏejRQd;[��ͦ�� ��̀Y0R$4v2r>U����Q��B@h�R4����h����,��/Sw֣O����L����t����"i���A�D���kgE�hb����i�Q~�j��,�­p��P��}�-mp�,l���{����8ڠ�t)H��fF �hRZ#rZ�tA���|�[�h�V���s��|��֥<��D�D���ܔ�uX��F(]�ᮇTe��k()��b;�n�U	Fy�^scfdײ������Yg�M3�{��|5��kJ��������ǭ�[-i$ԟ�O������>.~�㔉l�0���Wt��P�_q�r��2�zHCp���������s�:z-�`3=���w��ۅ��q� ��7����J߷*hJ~��U���A��a��qa9_Q���Tߘ�/0t?�7��8��;M6-į�=��2D��?&�U�NG��!��6d����!�M���q���Ķ�\��	0��dl�3��'��~��׸s�TAIg�9VB9�`�U-x��V$�W�\,�-�g��b�yO��?Q�j�
�UJ�o�s�������ˣ*{a�/�q�`*�y<�}��3�ABCB �'0.�6�J�&I�8bi�S�P�ƕ�,6ɮFR�_I9K�9�$pLoM���P~h����'ˑ�K�L$�����#��-���O1� �K�_����|�2}>l�&%�[&���j�*��@�k�m1�w�v�V_O�B�ئ߶�	)X��
;J\i~�<�R�^�1�W�9Ir3Eg����ռ���'#dh3r��|`��ѥ���~�x�x-�����Y�������Ѣj$�֗&�XjK�qI߇��q��
�9{��7����Nv���7w-B��<l�r�TD�
�z+��G��ƕ2����W����,q�kb����.���	��}�Y U�ߒ~�&�a�'�Jz�^��.҅�-Gv�GrR/�>�|�Ҽ��'�He�^�&��~�[�f �1�M��t��.�|�%���
��w�a$V����Ҙ�ǜ�⡿���T���+�S�.�FB�'_CPnT�[w�BۚGQ��[���H[X�u1g�^p yaMX��.�\Xi��ϩ����C��R�c��H�(z;���h�Ú>'�q"%��1�P�l�1�L��&-��7<���f�B�3��<p2���^�g#y���ή�AK�5��O�������&�ڄ��5of0��a�ɺj�><�:���������9�^�l�����%*J��&��к\� ����S�U+� �/y@��C/\��?�Ĭ��O;��4F�hԬ�$��I�g'c;mV�u%���*�A��Ċ�t/H���)c�r)�`��S�j-N����q�JO|s�7tz���u�O����Y�`�Z���7���[�pO-�W}/t(G3�:/cڵZ�:���w���0Y�sG�iK�]j�K�O�H����Г��v��'&n���]`*�%�6��
��+��w��k�u��L������F0D!{_�So\���g�M�I�r�Z�+(q����°51����4��/�hE��o��J�2�O���V� 2�'�:H�\2
Rϧ��ꠓ�������������{VB������v�}w�)��9\�'�zz�\�|H���=�F�4U�*�{��F���T�X��A���d�m$�x��x��B�3����=�47�U~�b�*� ��/|��ݦf#�1�ߐ�2<���$¹y��}�+m�{�0�[M��x�؄�N���4>��d�|��AF�3	��5yƻuQ^_Ck5���Na�e�ӊ�,b�����Ux&�*F��H}�#^�ij�2�/�^W�� ������\�/��M�8�`����\'8,,���E�8������� �)��~ԥ��ު
�#�DPC���v�8	������L���L����ߤ�҆��92d8�:FF�Ů�+���Q�J��򉤟'�<G�G���x�l�Q�*l���^�B��Y�ѻ��9I��j-�\�?3�'��������y��׉��ݮ�kq��fgO�#͕��J3_�BA��i�!�/7i�0��}��e-��|ڀD\K\�P��'�=���0ңe��R$ψkb�ut����4�K�L��A� �b7�0�5��$�}���u?z���E����`Zy!��}������.{*�NW�iG<��^���ؙh�
N��$v3�H��I=����OL���w>��{����YK�H�W��+#��b;(�KH�9��&9g�(1t�e�����et.�"��z��m�X�z��O|�h�i��g���
j͛��y� +ut'���Y~�یD n����������hM�s�f�RC�F-.��0\���F�K��6��Ȅ�����{έ< *\�0,Q��ծr����s���5���k4Y��*���<Q�<u�؈��D��dr�4	���`P(U�(>��%?�h_6_Fu��6�1t\��w��%�g�Shr{=��Ĕ�k�p�9��L��Kpi��V��(_��uNPd���
�xJ5�G��2�o�i~��Q������Z��$R�Ft��ɯ#kM��1?'�$��r������?�:wͩ�V�DR.�,?�&����{���x���h�_�o�x,�)�6@���7O�e�f���edX1���!�m����H�|m�oVata��"��������,Xҷ?�b߸��o�zΒ�	�܋5h�=Id��Ҭ��&�+���	���՘ ӛ��e���h 2t�-�@�f48�QB���|"�껊��Sp�Bq�1U�M����x�7��]sz��vD�J��H�͸�����/{:s�һ��ր=�.nߏ�P9�``��&%�V���f�+_P�����? �4"���d7׾��0����	5؍2l���[�^&\,�,�m��c�X��{��L�N��9�Z����Ξ��iH��P\�z��'=����oVQ�>�X���,����-/�PCڕ�>_'t�PQ�~���5�Y��ׂ�I8���T����)B!�{��$�)+hRz80U�ǩ��s@V��� �6$ݠ7��n����[1�9x�>��aT��g4�VT<̚���`�wD�n�}=��NQ �Ѧ�pG+�`��Kφ�� 6F�(	BwA��D���]����9���-�w:��+�*�{��';ߖ�<���D�ox��;���0�u޿�o��Q���>� gq�Y�j�DKx{���n`T���Y�_���;�/��־"��=��ntXKΑC5�VG��Nh�ʱUT+k�_������@�eï�IGE�[p���z���3K������,;Ѫ��^v����hj&�d����m�!�ժ��k���|yK:cf�;\<�\��""���i��/8�ݚ�8��!Ԁ�J�}�B[	�]�"O��,+W���'ݥ��8�A�~�5����ZeNٯ�g��;� ,�ݲF���K]�����?�vQ�5�S"����l��;fr �R>$'�:hBDt�W�(a�}�`�}�|J xe�"J���A2ZH�j�`N_5	ƆW��r
�'0 ��q/�]����sb��>���Oa��ي��D������ȩx�0Zf3�1�%�N;|^ �O�L�`l�`�K"����G&LY�V?�r�����7EjIw9��D��`���.�+J%2��oY���_�&��^*K�F��m�G����,�h$���I�(���^w���e���	 ��r*��D��3�@��Z�_�8��26H���o�P4�!1X.���O�<��G�M�o>n���a&�#��	4�Ӆ����ǹ�T���b^9�s����7�EV7d�Ȑ�t�a�u��LT�zҋfzb����o!:����C}�\�*�D�JN�ܹ��@?ݤ$אh��M�_�z�:E��)�J�ɡy&�P%��q�C�������F˃b'��6=��@�aػ@����ED��� �ٶpSi�w@s��5�k��T�=��0��T;�1;V��}ܚ.Aؗ~4,�̱QB-0�
ZMsq�rLul�B��q�e6�}Y�D�Yo�?O�@�-�~���Q�s߽���8��zkՂ���Yl����f�a���(%$�������_;��e<WtIo��$]���Q�}sM9�Eϖ�Ш���6����Tp`Z��ċ$F�^\�:��Cc���rS|��Yu�e�O"{91���"�	������Uv�GW�B �Z��N�ݦ$�6E��U�q����C�R7E	�U�)�k�U�#�����:7!xS��;�E�e�H��7�J5- �6�u�S���c��{&;��4H��.|�ތD��#J���`W�IJ�I�bz�qH��<R�h�2-R�� �`{����OӛL,Gc`"	؈�1r�W9��	�	��+e�J�bӱ�"�CQ�/�m=.�S�zScng���n� 
�Q v�]Ê[۝��YBP�r���G#fY�Fb�?L�O]��1_��TV(��
�!�ibV����J�Pm��m3���޷֚�^����#0��&�� ���������yi8DY�f��e!
�ӎ:Z���IFK/�W��dMm \BeD�LS�%˃�F.ȅ������͇��uJy��V�&{��ThX>�E폮����%����� <nQ뀢+T�U���~���[��k�i��e5�u�ш� ��i�wzOnQ�ח�Psj�}E =�z��C��o����wZ���!wi�.�Zr���L��>�&5�ҍc�rZj�Ŧx��E�:n@K%��
T��I 	���0iD���pU�<lO�����1�fJ���>�Yn���� ^py�`��>G�ؐ��b�1Fy:��f[�9����$��)���1CK'C�����e�Adn`��A!�%�Yu������zh���$k��uOWh^䗱?�;�]p��{��4C �|L�#E\\̅+rݛ:�����YG8~��5~��F}�
KD� \�Y,5#c!�W��jwCAU�4�e�M��p_D�s�G��.�՜q�iB�wS� �l��?��Bp�SX���:��\<���~�r�'R{�З�R����oA*��B�����?F�i�� �������{����w�iT"E#� �DI}��絊�%��e+:��m;��ST�X�w�
�8�����C���h�� O<��^�{�����^�F�}�D V2�^M��t�7XjT�f�JH�\�X�t���}�ϭ�ny��ڽ�tU�raQ��Gn��u�Ȟ���m�W�]}0�`��G�Vnt��D�0���*Yɾ�����a�T{�"����-�c}�nܱ�&^ ��F�FR�|�{�̛H^b��G����yY5G*c�q�����c9��V��ÜN\��=Q4���gN�u��F ���e'�Ux>��[S��]Y�\DTϣ��wy�@�E#�wB#p�12��x�/ 
�,	��a���B�$?����{�K���Q�X�{u	����	�V/�%Y���u�K�4(O�5y~Ê��3�,n�X���H�~�:XWz}0�������^�6��-\5,���!�ۥ��6FU�\�Uy�����@sM`/W�L�>s����:0��>�$|���g<�n��c������z*vV�E�������.�XK &�ճ���R�r�<�ii���YS
´�pgZjV_^����D���P����U�����O��L�n9xfU=���3�f�����C��S!Vs�.�Ѫ�s��NY���[�6�a�r�L砟��R������D��/�&}��)���Z����a����#�uڴ���d��k72gn�[d`��-��0�/�F ��f�iÅ9��fBʯ)����$6�����:�-يH�*pЧO�R��	�vs���;�9�~7:`�hr�>��>[h�L���ni��**�_L��8T�6ˆ����wmBm���j����Ks�rCw�	'��3^�����&���4G��C@'����5��G��v���q��x~�8f&��R�<	]����YD�-M_����@S���`�
��m�����nܺu0rD����Q�6��t��G/wK0H�[GXH�������s��uY+�0;,$�=t��ku�Ȏz��,׬�X2�h��(j|��#����䡄@Xxݙ��5ٗ<���'{������VVL����g���D-~"�~��M����E� M���肗�~O���V�>�=*ʑ;���!X����T߶��9��mgd���E�2�u3s_�<{��lߦ�x�j�ߝ�dl��a�:n�R|� �٣�g'Z��T�����iw�-�讀�7�'Za�~�kU>0��,u��ǚ%������I��rׂ���q���9k~'���U>w	���3�떝�l`����FR�Φό�ԲR�X����a��o���1%i����5~� Cp��"��0"v���	�b��w�X"�!�YM�v��z�|���æ�ݔs�愕Ǫ���ϡ����{�A�'�y�h`*C�	���,���[(D�i��/�zQ�Q#a�wj��3Gbp!mdS}Vw��<޸!��N]�����( Ό;��oq!�g:����\��S���]%��;:9"�8�Xr4���\�0+X�u��7Ā�w]�5�SϽ.�4�(�q���^&�׹��GE�o�F^�p�f��ƭ�E��:��8��?Ʋ�Y6c-Όy�Z䓡�f�>�J�ur�Y	pfv3��J����`@ A0(���{������ʘ���}T�Y鶳(
2���p���،���
(�M]��t����D��
��d��y�y�}�@*C�S�\%��9��cBS}*�2��FB��B��s���B�ޝ���܊?D���넼��D��t>�������~r��^���36w$h���JN�y�\�LN��˟��ٴ�n[ O��琭Zn�1fO��� fA��?X�3��Ŋ@=O�]�1�:�͸��=����ĔZ��1nE<��0Owb����	ρ	1�o%`�ih�H
t7�=X엂�bvPy���#�7oG; ������DT�w�K����j��$Jɮ�5��3f}D�sWk�� ��)#aK19��Q�:�S,)ж,o��W���x�oiF�i���?T��x�?�ݓ�k�����6ɬ�ٛ�	�S	�n�$0��Ik��W�4+�G�"\����P.xf@1�^��M����_,pG�|�I���i+�      K�n�8 ����9��g�    YZ