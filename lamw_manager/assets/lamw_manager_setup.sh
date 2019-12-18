#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3480324423"
MD5="1c9698360d3564541a7c2ebca61a8202"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20316"
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
	echo Date of packaging: Tue Dec 17 21:19:46 -03 2019
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
�7zXZ  �ִF !   �X���O] �}��JF���.���_jg]77F�I�K	.+��'�s�d�=e��X��o�*���W�B���vI<�IϜ�m���k�ioUc�k%nzf���ց��q�T4_P��r�|WH��k�,ă����v�$��gU�1���^�55��-��Gz���?s��4	��h�.u1��t���Yd`���&!�wY$�j�䭾S�YtWt!jY�b���[G%��(h�T`���n����5د��S�峴MKO�������r�Ptzޏ7�Д/���4>��@��sR����lȄ��p��BT��k�=�,�;Zl��6A��}*��NcQ`9��о��e�� u�b@�+S1m������0��^��c���SxD �.d���_������c��i�<�P�s���̨����鱇���5�5���z�;��Qa�J�p��Yi��s��NQ�F��eĉ���
&Mb���Vڤ�-y?�?٣�g��{����BIR�����v:pn`��+�Xgo.�C\�r��,�=Hİ�^���ʬ����/:��GEح���&H��3L����.x5�������%����M:��T�.��Ad��`3^,����S��n
@��)k{2�
Nu��$�/��)�ݍ�<:Ħ"�\_��[D����������Uo�f�zl�m�h �����m1��6ݥ���TZ��MS^2I����Q7�b�ǀͳr���[M����12m�qN��zEK;671�2<��5�X�y{�t�*Uj7� ��y�1���4-�Z��v�[&�v�(��1�m5�"2�
+	ɍ�}�H2��d�`��NƏ8�f��cz��}�i'����*2ڎu��2��S!GP�>��[:�H����i'�0�U�3��u-�-lO����0��O�:�[]�}Ƃݖ6t����B�����T�W�^���|.�n�/D�x�#���`R]2oB-abtt|T��Z�����r������h�S�m�`�]v{��������d�Ѳ���E��w�	�%�2#��ҕ� GKY�0�N]�XG'��{���a ��T_��(��N���P�g�x��|&���Ł��azZ��Ӽ��$�D��K7#�l���P�'�_��1� ��-Q�iP�kpn3RhP�l���^Yѫ^����Z���O���ŵ<������_F7P��8A�I�՗	.��0�꬧�����ǩ��8:��y�#GH�\���O��|��Ԥ����#T����2����xL��p�����)���S8q�[��K__�ó_�^��h�q>?v,�|�*����|.i�|-�$REj�����W0�3M_־�.͈:w�t�Q=�&�V��Ӷ�P�8�ַ���v� � �R�Ӟȴ,J���L9��֗��@e����k#l����j[N�xcE����zqS��(�  �PI?���1�ԚFq K�ٯ�(a翚+`ot��&�N$1�\@�?v횾S}'�E��B.�E
���]nN<��3�)��,2pU`n������M��98����R����=�R}�,w�E�0��R�m8D�^�ɾ`{�N'�}<S��-���q�슭�]H�?��I�}F�^)�4&�4;�:w��Ͻ�F�in��)G��-��:~}��r{K���{��pU��QN�l�Ӹl+�][X8/Q���)�:��O����]���%H�e��X��_��V{�5�O
���K�o��VJ�V�9©y}wI5�pX!�LOU1S	`�����΍f���W�P$��׃�V}(a�����kު��@�+�;��`�X��_"�K��?R�ct�K�3e��^E�tp3�5^0p�L��KyuuB�<U��m�r�>���,�2��M�Ъ[�Qx�X{N�+����� ��W�fsE:��\3kU$e';�X����X9(Ұ��M�'� ����-�Ô,��j�$�x��Ы�~:cNٹ�Ik|��Q�nZ��n��Deܪn����m�D�!�޲}Mմ���ܛ黼����"��PIy��r݃��b�!��J�X�
�k�J���Lc�ur�kM$!��")�xȁ�5
N\�S��&;M~M����%��S�6|�!�*Ʊ�\%c�(A��¹o(7�r���	O}�*�Ob=Ĵ�z�ŞF^?qg�>��b��j& 0�jXA �De�Y ZT��w��A�7?�8(d�?'����Kny8�i�p��=Z
��A�#oQ�;?�B;�����X�0F���g��s��X��T�2��٦��0��)?$Q8�"�athy~)ñTL�y�A��m��5�n>���~��w�t-im:����MϪ0������篍���ɐ ��y����c7�g��7$פ��\�	�� ���u�﮴X�~����z_,M����<B\=ɏ���grM�a�G�ݾ/T_�O����
��0~��ПH�Yln��Q���_������2�N*ݬx-�И8�d�kwq����t7�w!���E��B����.:e�����5<a��V�|�?�`�Ɨ�)bb�g�X�e�t~wE�cO�ڨ�	��f]Y_tr��sC�t�^1J��1߄_��PN UT�ڕU�b��t�T��D"W�K��93U��$����n/�[Y���������M&	ܣ�����1�Sn<μ���j]��b4����������w7��V�x84t��B�H^�0���#^�k =��	��A�$Z�������ԟ}���u㱰{���9C�g���k���F5v〲|�cY���N�
�&GC���@km���S��SkM������!{GgP�M(�j�D��e�
�C鰭E8��s�EZ��W�G7�jM�8i�e�9WkK%4�
�UT��r� ��sb�%= =��ZW�ńB�&�7
�G'����&r	�N�(>/�UmzU�?^�
l��hx�c�@J����7	p�(��\�qS���98v�;o6�{��3d(��X���q��#�p� �㜓\ɝ��	�������m��^;�Q���Xb?��!6uۦ��>�ie��9u9�D�����6����Q@�R�\6�����S{l���j���*�	�ސ��k��@�)�����<�ː�EJd1̳��|t���b����h���K��R�X=$��y�t�C5ZY9�q���ը�o�"Y��	�[�i�������;҉F���G�-zl�n5��G�:>bNvة�ΙaʺY���&z!��@頙��a9T��#��a�)DzyA��{�|�e�6�0I��O��l���YJ�W��l��s��+���[�Ȱa�b���
n��B��D�*��md7�Wg^�:��ʤQW��&:���G*�2����L�=c0|�Qt8ɷ��Ĝ���yt�{������n�t)����ZzW�5]1����}f�t-P���c�k��c�����Sd��G�(U�JC.� 1O��x�#�\����uk��-%������`�f/��xCBHD�,Ħ
r|���w��D�v�N*°�Er&�+�us��Hja����PC�O���o8R���$��Dx�D�lGx����[��Ǽ���*��q�5�W���񁋛�i�ۯg�R�S��}�T��~l�L�s�|�"�P�= ��Dcǻsiz�-��J��&��D'�
�4�j!�A���'��������h�b1=3�g�
_i���W.�l����ZXr�L��B�Ů=]�'d;��9ƒ�A�+��q��<�����A��l©��e}�I��RF`�`i��1W�qc�����JKR�;��r7�ˏ�e�Jd�=��D��^�������we��^`�5����K�.XA;u�dt�o��p�+�Pn���w�kOOkY�-'[Ap<�C��˖V"��xBc����/�He�~����M0��D;R��/��Tϖ_�cP�ϸ��� ��i8��Y�C5��S�����HnU�6�,��|��'����,(�8�ms��l�Y�Ȯ}b"�<����D�W�5㕆�	̚ �oB��-���լ�5"i8�&�\��AX�]m��8A72r�s����2f���Qf�_�=~�{e� �P*k�Zu��X^��d&�O�_�"+fS}x�_����s�4Y��(�
�U��I���v��x��"'kO&v���0}�)����K����6{�(ɱֳEo��H^���V�k���
n�R��?���Ԧ�ɡkoCgb�4ˁ������{*	+���u)S�һ^��I48~>������' �w<���kt�r��'z�y���ə��P�V�=-燏���j���>�Ul�r
��{c�VoL�D��g9-"*m�bY9=}���� �N�HN?�;	�x����f8˕0i��5g T\Ϸ��J?4q��.��u��N�'A�
P����-����	-��P����ά1�`��.,J:��cn�F��;q1�0���y���Q�f�h�s扯0�ӹ�
��]z�,��g�)[]�g��X'}o����{��	z
}��YV$P�*5^T��JV(բ�]���pM���mS�u���i����~��������í�ź�:�@@���[��|��{���#(I��kp��'.	���'��W�I�f�0V�g��i!�T����m�N8�:c\�|���D؀"##ꐔ�9�/�+��������g���N�m�Pu~W�U8�Zإ���+�K�XJ�����S2��ْ�F�6R��ț�UrW�~�ODc��4M�8��w��Fa�����hܒz�C\�8i�Wֳ�,�,��}�Q�_`3�zr�2k���� �$X�SsE(.�=r;�� Q��(X7ap�<[ڂ�'��u��5y����������9��B7��t���j����+ESt��7*@"���H�ըX?c�h�yt/�t
�6*�t��9��ຝKNUW�����������8Y��`���D/�x�@� �"��x�ɦt���:$�����ܚ����;�#�?�C7^��Zm��y'��?gO�B��M�?�����;D���ȗ�<�C�f,�	��l�d�/;�7Cb�Z1~U�P琋�O���#~nj8��Uz�� $��̴������p>`� f��	�S��I�p*�5(>,�'`��U ���ߣN���	�G�Rp�~�;ݰe��z##iL�\��BZY!�s�޵f.j�2�(�������������ۀC����:��?w���p�Y�/4�lr~S�
~"�eN�k�D���s	�f ʨ�5<~HL�׭��&���$��X�A�l���7����
���kr�37��5'iB�p$�����`����3c����)d����a�Y��R�N6'-��H�4H��Enόl2�O�z�ꮣ>�P�'/�7�F6��\
����awR�#���wؾ~�42��Պ'�U���x#��
Q$#�]��7��}�NB3]D>>j���'��ԡ�f%A��r8d�.�ӓA�m2'4�`��)��l'��H��x#.�ui�c(Р���Yձ�_�u����}���x�S�{ѝ��7'葍^O74ݖ��/�~���!�R�MN�FC~=Uj�X��@���� ��X� ����W�Z���Ki��������XZ6�_��'���Ӗr�[nd4AO�mM�X(+U��F���2Ǵ�4A|��J_q�<ԗ�B����[���'HO�����s[%�=;��z��;�.�W�ٺ(HtV����!��w���x�)�����׬d����|f�81/���������E}��zB�ux�ANI�!��P�r����E�v�F��܁�C��eo��>(;� �]�vv-�w�p�G ��n��h�X���0�u�R�"#;^�L�nPv!�����˖t�_߈/m�Ý��6�:΂�v�Q�q��~ՙ&�׫��F�c�%ɚ���$��s�-��қ͓��J��I<��-jT1�X7$Q]�Ҵ~`���g��⇭�Po�a���WC�:ܢne��kV��@�� ��X@KU�n��e��E����a�a�C[���tOM����ʉbB<�d�6�W�Q)�Br�ѵ?q,��v�n@?���/���Tc��A�/n@NT�w�MrJ	�O��\f��Ɍ����r^���n�/�V�n��R�i�
�ʦcAAPX�{�ڞG@iiʍ��a��/åQ�`����a�%1$�@^%^����h��U)˃'�����<`����i't�%�7��q��{kd����I���|���pQ���GnHhG���L��.���0J��U�����mR4�P+��f�J(�	u�6�,S|3�|4��Z?}�nn�.\�ΤitRs�"O{=�@B"�s����s�:yg�1��C?ųn��L�i8����<��u1�ԾSo�t�E�WoH|�f���kuf/���VT{�������s���J��Y,������1��Q-�0TF�
JxC�~����r�
ʬ[馟q��/u��x10r�/�	,D�A�m����3���lW��/Z�E3K�`ss�"�KO��F����l�Lg��)`�������up�H���B�P9�èC>��	Xi-)���u�2�#_����jN��bF'�{��Cs�=���'y2��霓�U3� ���4-����d1U-�{q���?S��o�Ѐ�M�%�u�W�:̦�?�J�h?6�� ��rP�
�� "�~3gM���^��_��|��Py��m((�kY�.��V����M}�
"s�vef�$�ه����d+�������a�-rP�����XET�S4W7����b#reB� N��NY���@ĕ����@Mot�`� <ō�P@��r�S[OO?��G�+��o����Mh��j����ɞ�"3q��?�Z���dE���S')������	�7� �zy��;��1:Fy,����u��|U L楬qL
i�=4�� f�4t��"%�FL����Q!Z,�&T���r	�041���Ζ�r��?�I1v�S��	B�<��G�^
�"!�w�gٶZ�m��P��3@���h��]����\,���X�}f�f�t06�^o��D(�������+� �g�?�㱔'��2j��A["@�#ķ$U_�;�8�|�j���R�6�yJ�6��Y���'�T��8�O��A����A"F�l�^����e�?xX�{�A���kN_�+����
�'y|n�<�YI�����P�s�{����+N{ʩ�9����
?̊���n�ey��O+�[Vl��H�Z�4p[����Ϧ�6��(.���%���v_��ci��(�tqv�|ҫ��:tGf�jɷoI�j�"�L���FUC��_7��M��`�4��D�%�
�FB���0�l��j��Ϡ�ئ�q�NCt޻��	�)p,Z�5��vSvL�o�z�ʐ"�����`���.%�j��s_�_�a���� ����r�Er��X������_�ع. A��w�9̘&Qg��(Wo���sB�m��<��8�1�K�8I��u9����G�h�����n&�l�T����x�za�o��c\K&w���1'�^ �#���eo;D4���4�>Ì��9�^��+�ίb.�?@�J��Y���/6l����*0
�����;G�x8_�N�Qf����_@����XIC%L"�N�_{���X}6o�9��b;q����_�q�sD��B��)�aVQ����\6em|W��H�Gi�x���7���)��;5ַ6��0��h[ά��5�lY�V�$˿�j<lf/���x�B��ܘ~�"yY2�^^40�Ԓe�kJ�V4��%��u�6X��4��\�i曭:��56�X�M��[�1�:��f]p^+���9�T��q��"y�_7Usz�����֡ɷ�&�z���Y-�P�`D���ϭ���`��ײA����0���(��}��ե���(��c�Ք�{���N!�����䳘"(z<�z#g9_4�I����k`����RuV�� 9�6��;@���	FIR�Isw��5��=X�YO���dY����!�|xİ��s���䰌�|�{¨�`�~#��|��v@K9�zq�R�mP��;�RN�ܻ��F��\QY�P�i�錜B#��0/�T�"�B<�@��a�6��d��A����E��on ��W��_�x�d�͉V??��d�����4I�^��FP(�q�"������C ������:��[/&r
A|P��xŮ��lc�&�p��)��m#��_��8B�ݶ�R��>�zH���mK���5a��ĸ>�!k�~��I�0�}���8��9Ou�!��;��b�}n2�?l`eak��R)���Me�J����=}z��Z�),�U��?�<�#�eLn}2�adt��h����$���,k�a�;c�w�6oVB�_Pp<|���*�� �F>t�t�M�Ы:7|���m����p�D�|�:�,^)j�i��Jܸ?sh��
���1_�k�����;?�0+��@��\QQ�����~tu�8{�Q�@�l�_�h7��u�Ma���g�4@���ц���>�O6�j�<��)B���(����ݞB�ô��� ��r�늘B�_�9����g�ET������h,���I�P�u�y��-}��]\ :W1Z�2F�/�o�%� W>�[�;(fU��d6
I7�R6S� 韽nguT�c4��oX\��h?�/&o�\�n ���N����� =V-�G�f�c':�ʶ���tܳ�����;���47/��r� �P�{Ąz�,���`/pq�/��q]Cu�#T�Aᬲ��a�(��D������A�
������dL���-*B��4�7�V�;�F�� �����;�?��SR�Zo?S�f�f���	^FV:�
P�Gݲ�g�����2�~Nz�bfy�%�g�Iٍ���?���2�(S�U�|����lIK	�!�~�-�`��$}�l5���g6aw�E�1�3)���8�NZ��/5��J(AV[y��_ϡ��|:)�5��͜&���'4��A�Z��5�x��Ca��7�}���,�bm��WR���tMe��<������wK Gk_̕<�t�;E�Ј�.+��,�[7�I"�xE�@A�$@n6�ݮsՉ���r	jH�
�s�N��b@�Y�	��B��kE�N�8�Z��^��=���'�;���
�I�t��]jx9b��"z�o�T�ԍ�n�" '�^ˣ�z�����h���O g�����0Gw�߄�Įk5���4��%/ex��G��zL��;���bR؝���Z9v,}��h)S�u��B�L��a旘r�����sy��%Y�(��:S�/Lu4����Ԩ�'Y�x�ض�g�s۫����9�3�]g��aח	��WaA�2��w����2g�7�k�诚�IYEH/���yz5�.6�0�����)�5�R2t��ڭ P&�A2�c0]V�I���X^�΋p���'@P��;n�٬yx�/7�[��le��Y����vJev���G�0��J457v�������=#U�=���ma.5��Y������@�8�5}�x�
Xw�/��^��)���򙰤�ՙ�c$���1.O*����&�,V ���Ӿgt3�E"��P�P4����3O�%*:��<�H��}�+�Wh\��a�M</b�����������l���+K����B1��S~��O6�aר;���v���b/s�}q�G9桊X-D��m7�f�/g�'㮇�J�t�P�_G���]����M~f�^��D6���,�9�Y���{)N
q��/��y~��E+�5�����]���� ��T�#��̊7��B��A�ϘB�W����/͗<��J��1x)��;lqv|��h�kU��@|f^��s'���*�x��/,Ϙn��)u&Ǿ�o���'�fݻ�z��8�Cv��-D
V҂��H"2}�*�
@�Ѩl+U�fi��>]i�t:'��\�`̇<jf�I"T�}#葈�tu���M���R�<��-�8{_.�&"Z�7�hކ��Q�O{��`ַ�hʤ�U�&������r�-I��`��gs֩3��=?g�dޡ�{W��l��	Y�ck�j/�w�c��!��X��<�"�j�\�t��47��߳�#>?7#ѥ\eR���R�b��u��^��L����}�0���$�%��ֈ�o4�C=4&���y϶�P�-���]�`z��Z��R��m�\��
�J�Sַ��|��Bc���v7-}��z��P����YT5�Z��V
��k�m����e�Հ-Xp
G��bL��-RYa[S���Y�eۈY�\��-.�=�ƴ�O�:����	I�������>V�@�cJ-��|XV����)g�t��V�H�I��pX��:|�®� �/��
�FDz/����R~�牟���H�\!w��p���j��oq� ���E_��J�O1>�VbrQrYW�\�sú!zؗ'��t2�P�Iz��1!	��AlY�7Ͳ��_P��X�H�̊Ly�W���/�19w�z��t���G�oH` �5<y��$��Nt-~��L�!���t�k���C�2����ܓ.3Z��|Q!��h!�����p�̵���f|�`lc�ӰtK�ܓ���5F����){�G��,.��7J�4֍EE���w��A�狆y�|�*?��iXEs�	���O:������#���X��=Z �5�jcM���e�x�c}"I	z,G�R츮n�]�����������R�7ξrȁ@���o�A�X��!�(�Y�#_{A�l���^	z��EI@Kqi�������lB�$V����-N? i�M�~J��u�ȮN�n�Sr*j�f�PE��aL=-�}5���tx�$QKF�V\S��Z�^�s�¸-T��a��C��X$��U-����F���336�n��17��ܕ�2��1��]9�}�q���Ӵ�Z?�m�Ϗ0	�(T<�F��-����(Ʉ�@�h�U��뵝f�kh�@�|fw�������9R-�����#p��	5zר�!��s����qs��D��k�
��;�R��n`��x`�c����!r���ڳJ���0%����W肿�ԙ��4��%���]������!��e�Թ��4�#t�������8X{� ��:Vr��kZvЦ>_�F���'.ҙY��=�T�	b�r�R����e���%WR��
Xc��%ݯ�]pA�B�ktK���|���\%�d�k���`����K�L�%�P0��$l<�����X�%*��Wa0΀�3�a.|�h�b͇N�T�TcnVƊ'�B.���82寞�/����~?�U��H<`���D~+�`|�6~Nͷ��%-(P�G��"�!g�>�' Zi��ϓĝS~X	��x�*�>�e;xxwҴ�i�e�(�Bˮ�������:cu&�S�Ke�,��jଂ(���&�E �u�yT���%|7��p�qDEq(�`<<8U���z�neqQ:óT�M#?�gս|8IMGZvWz�?1>��69���w�0קC����[��@��u�KG�Vu�wn��E�^5�ۺ�V�Эﰘ��MԬD>���4�����]�����	��s
_���&��#��v��}���}}$��΄f�ǁ�`(J4I��}ho�V��h~䆮UV�Ur�Ł�9����b7<�}#?�>�7���Q�dF(x�d�+ӧ�L~K��\	e׾ p�R��|���Oaă}�YM�[쒇R��\�v�K���	dT�m��{�2p����E��4(�.��a֩WGd�^lf`�}����=\>S���e�Z�$��;�b��o���S{�l�N��=��α��i��F4�ry>�������CR����3.PC�_ �P/ڻ`!F_���&�OUJ��¸��s�L~_<�Z©q��Yi��A���=�m��_���:/����a	B��s!��g�v�xp���|�!h��\�Y�c�$���?�C"u�0�z��IO�69)�N�O`�̂A�Н'���0�j�JA7A&�(�h���ma�νD)3u��0S��(��k�א�~����3�g֚�j���C��T��#�rg���/�ѫ��d�H&V�(w�8��)B�����tx�C��
���:����]�&�8�u����x�9�����Z3i��i�����ʝ��u�yJg�xo)&�*x~zTǔ�n;IE�t����,=��>V��c�4-8|��^�V���^�N�~k�����&o�^S���Is�R c�Xϊ׆�r�������Ȳ�DI��Ƀ��]�G�on��?�D�-�T����H��/��:�e	�69hz51�Ф�3P�r�ǲ 	�3`5��ٻs�8���rρǒ�ؔQjY���G5��TtFj�C� �,�hD?���@��Ӳ�5�`P�J����8^hr��
���y����˾Zci5��"G|��� �͊>:���/�q���ʜY��q���G��c���XY�����I����M��
�ʾû+�q���!U�$���FV>��=����!q�I!qA7DDl�@=(T;������}\�6i�#6������7�����^��h�����2���4�A�+=3�	�q��)��`{a��C�J�;���sZ;9?�4Z:��<'���z̲�jo;)�%Vע+Z�92��.^iU4L�5N�r0;��9ri-��(�uj�K���{�]��oU�_��="cEx����)8�rO��^
���eg���^���{�u`�aP®镢�E.��H�nZ0%;X�>� ��Is��ږ�g���Zp�Y�B"��'{`�E/g�^?P�h4�~���O�Թd��%��k��-M��1X!W̲A����� ���V��wu?�{/pc@�g�)�.|zk���v������L�Nd�ާR��1&��~*�xb\��Xe�k)�71���p����o���Œ�Z;�
�f�|�O^����=��t��-� y��N�	<��'�? �0�ax���|-��s�	���I��z��-+�b%���B$�&錝����ra���<V�R�s-�<����WL��#p0�����Iϊ�b:G�$��d4l.XFU�lh�9���
���^+�ӗs���ٚ��!�:��Pa�`j V�h����v�s�����nt�� �	��y�"��@��	�/��@u��A�眏`�{39���9j�V]M� ���c��)u3/��4>��{dmf����u�:��?�虮�-��4ﯤs�7���E��x߻dJ"�9x�,������=�&]	�e��rkd�.��Y�{��З�Z��16��;���DB>1�K�v�5PP�O�����^��N}����zޔ��O�:l�cU�b�3G31%r�O��N�IYn.�2�o��/Cc���-n*���"��=L�5j�L}�{{�Ҍ !�� �7Y��)�`O�+�����[�a��d<���&�P���*s[42��T��̦�R�s�(Ee1�b'V�;�f���jЮ�>kLm"��+�mV��Q��}�0=p�L��5�b�=�%@���>��w;ľSݾ�в�
���٦o2E���brƜ�0+��¢�fK�ơʏ�����]��VυzR����Y�@Zw?�^>-e�ס��P~��E�	�C�'��˹��@H���a�s= 5��o�X�*�E�"~7�j?a1%��C[��7a��|��Xx����]�P�jmj���Q��ϨCn�`��y�
j�f0LL�:�qGJY%P���3�Y�JN�'��ۓ��|�2�:kx�@%�������Y!K���������x��ï��7�}��j%"��D��n�d�%
O���nۨ~�w��1S���_U
)�;D�@4_��^�.�^���\��G���{�va�1j���/~�5e��df�րݫ�$a�����\�o�� g76E���}�t��-�VV�=��u)����T��5ݛ~���}��R��Ayʩ���Mpڬ���]�Zl�_���!dO 2I������%b�ѷ��\����!��F��-��T]�Nz��p�h�q��m�� �����������N5A�t>J�F:o�!ߤ�Z2B(3�.��Hm��bO�J'˃a�H��Umd~��<�%�"�����;�Mq����(�!]��d��a/�@U�0�j^þ �(Y{򤪝��Tn��*��Rħ����	������ŭGs`�J�X!��wX�XYJ#kW���9W���tk.){������1T �x6\; ?��K��3	޿��	��V�� ���!�J���js�2]]g���h��
c�y���F��g9����#��h����f�42��xm�0�4CT���S�A&H~��~Y�+h5/zz�N��˰�^[�/q8.,4���W�肙��~? �K6�|.��wz7��%����	��-ҁ{�⍿�N���V�?*�6r{�:��3��L j��<��t��`�[�u���G�L�-)�D�`IVl�s�ҁ#����gFXb��Ɗ�#1��9um��������*5�n8
#�e$O�s��[i_x� '�VPe���;�E�"���QY� ��EC[Z����λ�4�h�@��fB땊��9�ܹ��������i�A�hT�˟��م���^k?���i�b�5^S�l���'��%�'C� c;��/��h�*HJ#�Vq�l|�^�� ��+�K�:�M�,�{����ٽzd�ʱ�\hk2���*�5Ӌmj�j{�}ј�5n	e�{��~�o��#����!�7UA��X���M���i����� �>�_��(��(�-5Z/������VlU|����=����5��QQ��7��x7�t�+H��p�U�h���ur��W�P�<�6Ү�7�0�0�H;o�bs������*�N�~7Hl�� �g9ܯ�?������^���͝���������#�HsU'>4�iwZ����z�ـ���ON����Y^L�#�\cJ�W��ѱ��c�N�Gg!:^b��Պ�����35]ڔn��c�A�b���]c%����qi�)��GU:�B�ܯ�H`�������qDw7��&��$-���":���\K���DH���ȣG��9�4S�N�v�<�n��E\�ɡJa�G �OMO�)ƛV�k���B��j[� ���t����HO޽��p��i�yU��[3��Z,q�Ԓ�e|h����G�f���-R���)���4�~	�j�x9���():�L��X���+��W�YD���UE?<EF稙Pϥ	�?F�b6?����n��`]R�����Q����)P���W�l���P��q���Q��`�oZ��L2	�:�o��
�v��%��T�3R~o@�1ak���� �v���n�# �:���10�A�������������M�&w!�hɖd�<�Z��� �Z-������b2$U9�{=�z(���a��yxV;���ǐ_z�C���}������c�I?`�:Q4Pn���߳��؀�Jd�ũ�^��SnU��yB�t���wȂPS+�M�2fQ�����ȼ�vA� �]Gز�Yi�>3W<(yB��K�\����<���"{J!��.h�G�j�߄��֎$��.�Peq�'���#�l⡌&�FO��7+~o������s�m���J.��$���}R?� F�
]t����vH,���X�ߋ�:=���ɰ���:c��e~���5{��b��Hs8.Zb!�K����V+�S�m��6���p�[�J�Zl� v4XjDºCٌ��#ӕ�3uB#��ܑW����:�kF��fb�!)>\t'�"�(�!�܀Yt�'v���خv�QO�y!��Z�d����K�g50�9���&�˺�{ڬ�yٌI?6aq�Q{5c1_p�=|B�ɥ�hkvnskoڼ"�%�Í�x.n6�4�6��%�nu�~^�� 1j�������g�N�4^�YA$G)$KH�M۸����J�QnhT���Z {��Aj�.q�	=%��n��߇uq�k�0�o���	��P}*�t�X�ָ+�J\��3��%ȏ�?I������xWG>Ü=�A��vZ?mmBn�F����wAa��c[u�L���7�#`���Ek�勡��w�tB���o��M�G��'�5�7�n�(�b.����B�T�6�<��z��9�p,qݠ��3i'�����7O��#`~x9��7�z�XaG)]���,���za^移��Uj~�or'�+Z�=ԛ���"G#5��e��*�*N�ZL>r�������a�9C��Uஶ�c"wx�,7`�3�������x|,�R��+��O�d��v�9�[ #f���n�6��<B*�E��?@e�������,W�ʠ�zj�c5_R�{Uő�����TE���.�Rt/B�r�y�|�\�	����Tr�`����:��.�����:���|;#Z�M)�*#҂ޙ�#؝���oN� <�6�G�>R��$�i���Җi�C��|lg[�<2�8�5e�Q�;������j>y6D�_E���}_�����Ո�%�Y&����"Z�D�Ɏ�J�ua�Pe�W�㍡��XYM�
�e&@��bpc�w�JJ��2`�V=^�2��M�@:��0�A�ͳm�f��7F�UH�*5���yI��l�}�PӜQ�u&�{��(�4,(u�T�HG���v���,l��Q�]e\(��g��V�����=�1�;��B�jGF�M�m��?�X&�����
*?�R^��%���sv��<��׽ެC�1�{I�������#�u�z-����`��-p"ي>~�V/F�y�WTl3J7���R%�, :0fvm\�t(�Km�i5�������S.��L�y���Zm#��N���l�Ca���vA��P�x��[���2��ɺp�$nc1+�=���ʒ��ڸw����5}:MK�&̹��nl[�+�j'��m<�;֦�����@�t"�3ފ@$��I��:���5���!��Mً5��sP$9�AC�iE�t�%(�>�Svt�ɛ��<�J��oj��Z�^B�e��-~/�$�p�@Y�f=?�n�nǚ#?4�j{O��`�
:�)��f�g����āA���7i/y�[�Y���������C�wp�Zܦ�y��W�y���Ig��������8�:zCu��]��%��J-�h�b�6�#����fI��"f|5��y��Wx�钏]z���KNp�4�y�s-D�h��҅�Hnh-tU7��D#?��9�O�ig5���c��z�����#y�ץ�g�������m�AN�Q���IEk��T��j��A�)��z��eї1j�(S�e�:�1� 9�r�0Z���B� �N�a�1��A4^)���������u	����ߺ�I; �N9��͍�������PbyP2�qZ5i��N�������1�R���a�	�J(���=����z,(dN���/#~��g���Jy:'�c+����$ġ�2�A�ZGH��7�yw�8�Y_x�8�<+�|��ߧ��Nyd�A��Q�}:�����j�ۖ�L�q�w?g���~V��qj�C1t����n\]����j�`Hm?w-%�נ��?�Ooz�����MH���~�n"K~��@JӠ�q�ċ�̖U��hk��Ws|ُ����u��i��
p���q�Q���H���a����p`�K$���MA,��Ϧ�<��Qʛ����P�ļ]�Bs��<?�-�i0A���N�,P= y��r��G�F)�B��+�X�')�j����b��# ��N�i��K6�!���2i��ݴ�^I��sf� ����q�5��B�=Dm?����h�b�h4\d�1s,;�r���x�R�2�k� U����䨅�&�~�G����\�"��OseO�BB)AS���@=t����pP�  ey+����\u��ȁñ�	k:'D�4�5O�T�(`��r�\߻SA���	Ϲ��I5re]u��8H|�\ޘDS4x�a1'�`����S�s&�	ԉ߅E�����5��D3q�
Z�۷�O�$����ۨIߣ ��EC�[�3pin��Ԭ�;�,���@����Ab�r�w��a'9΄��_m�Zf��:+9ZG�l�{�/GY4�邕��0�r,w�Y�vV�Uj�ߡ��nr�&�l-�K�O��ue��#�t� <|$(T
ڷ849��ص �;�L�0�{>/@�zD�d��¾����߲��72�݌�C0��w��������x �]TT�c~V9<<A#+��׵�W%�&��N*��/���Y�e~G+�>�����nͮ�G���5D�A#V�ձ°�_:k*�=�@�!�ɺ���v,�(��� ���'E�\]-����� M�u�)	����ܟ'KC�?��I������C������@ -GlL�%]�P-bۭ��xC�֊�o0Y�X�����w��;�G��%mq��T,& +pZ1"��� ��P�.X���������|\V�U���k�S�����f��i��I���)�|� �T�o���O|5 vϋ0˭�u��-���H�B�ҁ}ݿ��yM�+��}����WG������"ݏ��E�>{r�~�qA��>LЋ�k6IiW�`8��q����y'M�gQP�������{ш\�Z`ȵ��3�� �p��i-�f�@>��g`9=\Q�?	�K��l%�~&��^>]���^E�J㍴ &@�;�Y�Bq��Lg/����2��'�+g�W���	�`���7[�R��^�*X#��S5i�/�>����l���T�
�*'O_������q��w�1/�{�(��� �J�z���43e�HO�@�	����;��)��q]�
\Rx+Qj:�h,����n-9�N(2N2��0�JKʁ�#!����tSp�uz�f�����I0���}}Ik�A��3z!iIm��jwm���JD������dPAgJ��CԕQ�^�Z��:�^j��g�q0��6�x6�>�%ib��$�s|��TJ%�sV���IN7�WT�+@���i����6������N�3v���%��|` �(.<�Ѳ���E�,�MSB���.�$�9_װ��jt-,˯+�x�M�¬�n���t��]�� �,H��F�4	�8c�w(�NE��U���Q�?��,��OOO�em*6Eu��V����"d��jĨ�n)4 �G*�j�2�)C�ӿ(�b} �UW ��T�`;����[P�X	-���w�ɵ2d퇦nȳ =p*��y<��Ǭ<�q�s=Q�I2���!X�>�N(�����R�I�̈Fw���3���<)��;�Xj���P�o�k�CX���~f�u�Bг���v�� �E�n#�G!.8���oP�Q�L���އ�l�^�N�ꕫ�����pCg�<i?6�a��9�"���Q�#�45�~P�9�$��oʣ��ĂRM^��I��,���K]Z�'e|8,����=)Q֗�O���42����`��ʫZp���il�ǖ�B�K]�s4mO�zcT�����������C�܊̹'3ͤW ���;��MkL�H�Jrx��������T�!�2q���~Iϫ!g�Fn�� ��W���9�Lg�þ����h���ϛCbO���#�`����oG�����&�����P3��lR [^���b6�_>��
�#��1���n�����,�M��YmL3B5��6H�oCz?��C��Eo�A�   �h��q��� ����XA���g�    YZ