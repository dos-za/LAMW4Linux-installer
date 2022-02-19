#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="913898615"
MD5="ed5b5a2cace9e88a723ac8e9fe04674d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26632"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Fri Feb 18 19:50:04 -03 2022
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D���0��C�E���^PV�+=��2��F��#��xI�؄:5�O��Z��,e��\�DϒĻs3W)�l.���a�}Q�-�w�=���[i�5�e��̆c���`Ȱw$n�^h���=�~�ddi��_y��J��*�k
0���8�B,ˉ�ڕ�q�9��V����.�y���XU~�+TqӨ�1���[���8�|t���/Q��ԧ�]��e�X]����;.��ؠ'�!��~0��\Қ (�m�P��Γ��߾hY<�ƺ��Ewk8YC�̄Alr�'�D���0t���ϯHgO�7�\T7�u��Y������o@��;p(hH�$����ٵ ��^s�;���AL�.�^;�f�� ����2~$��#�vQ���)��vhK��}p�l�"�����~��Z-)d�]�nU��r<���>�c��Y�Hk��ˁ�h+�o���a��Ӧ�Y�X"��X�Z���g����>-OM��Y}!���.g�S)�J�h: ['9��x2!z6� ���Bgx�I"�\�� 2�:��&����_����fZ^������AZ�w�!~>����U�,0��n��x��Kw�
I�!{u�iv,�NZ������� ��ˏ�1Ev)�Pl�|��Z���x�]��L�[����Tfʽ���^��b�륢Ok��L�-X��o� ��hEDE�K-J|�˶�:��-G�_�����>U�|\t#JbqN%��1��ˊ����UņB�O�d�@..�_���Y��~����R6X�b5�d����j��3&_�;�0�i���!�R�S���ԕ�xO0¥�OKE}��0�{�AL�L�#AdgP�B~·��௸>�*�\sW�eښ%��v����$ sD�U��>N�Bg�.i5%���u�c�|�<�S��w7� �l�e\<����;�jýn���k1XWk��2G�L�72�\M,�0s4at���%��5�	g[o>j�i��������	��c/�Z��`A�5J��5��cV�����p�n"�3�����1(�ҍ�N��*s��	B�J��U}��4M3vϣ�P��"��{�AU����%U��R�ܡ6������.B�J�t�L��å�-���·�ˌ:��tѳ�^Ձ,��h����9�?���N�����q1ۅP�u�g4�8�-2�Ъ6��TP��*m��>���Jԉ3�ͥ�vj�LmJ�����(=�~oXw=�B^#*��Vw�$:�<n�l��[ڴ��Z�K�w�>��߀O\֨s��$��M|�&TV,��srӶ����E��X����3�7�]��5��&��E��y� ���3ׅUiH�V�0��yu����ob�3���2�2Ŏf�o�"�|Л�i�Im��H��0V)>��C#���ԏ�b�?�>dv��!ۀP2N�W�+�o{c���#�|�b˳�j<_cf��G�5K$�m6���gl���e4���69F��7�����ZVə6(u�j]$e���倬Ч
~��un�Z����
��;��z�z7����G�_a��BA�*U�Cݢ�u%�-�(��E��0ph7NZf�X�I��,D��jl�b�����mC���u/�p8�@zE��2_�䄼�`1NR>:�������5�����a�}�V$�{#�d�{���E���ͨ��ɠJ�av�{�W���x�.�UCe����{���`��90#�q�������e�ZTdgj��[���O�?����5�w9����fԖDɷ�P��*�f:�!�D'ޕ����x��'�ZJ�mLf�Ka#���Y M��j5���̟S�H�v�L�C6�HgtǳI�[��}��c!��&�2.O9���]��8����u��ShZH�����mQ�����@��.zr/g�`"*҂HB���� �d����A�-O�-��>�mN�xy6���y��!Ⱥϵ���È|��&���$����F�*32��	f��5ZZ��uV9m�bV��8YPI~�
\#��H�f����[=.'�;�CCL� �BGaкX�w���J�~���~�R�:ar_����Cf�;���>�Ƅ�}�Ot<!{�N�s�p��{�
�!t��K=�}*��F���ᯣ�4}��NŜSϑ߱�F��ėj��ھ��������P�էs0S8���:�PP�	�/������/$���%��D�KtGܕ0M08Z������v.SFC�Ӡ��W��̢!��\,�sXa��\�� �]�wrս��`�I�H�!!��"\��M����Y��|��Y�_�\ ���ט�w��	3$��_9��.Y��ج�7#j1�D@�a>��>�igf�\�+��:<	�.�Ӕ�k*��3:�Q��U�>6�c?��}���`8����b4�ft	
z0yE�e�Y�E�1�Lz��k?a����(d}�8F�LvC�ͳ$HjqP|:2[20���89���g$�w�r۸P(�/G&�85?�=�����?�����t��-����+]{8�U�GI��b+T
:�n�.*U���(_o�mt�Ͻ .��bOU�n�w15��γ��5$Y�H ��N�C#��zly�V���h�`hi"�?� O��Y9��F����5ڠ� 2��#؂�B1ss.^�(�]������԰'D��c��B��L�������J�k��Q�}o�1����PJ�T:����t����֑9Zj����^�쭓�N�"���V"4Gg�JY�-�5�J�V��ԜMN�
6it�����F"#�F�3��7	�J�3���-�r���ZWe&�Sל3�?D?���g��W�������D}al�=Kv*v,�X��I�Z�T��ؾ�-����n3c�\�@��=;s'����k�����}�*�P�v�iC��OX�Q�
˥v%�*}�`'s�D����L�l!�¡���N4�ڷ�Jg�`�7^#�|�O�BM���0r�b����bQ�o�xE��������b� �ԥF蒮�U��>"%�~G���k��(/��5Ӏ�jO���0�5�%x��e�3p�X�Ai�k&T��GM�T|�.�GI����;�:��ë�a���UQ<�l��w\f�5~�dPr�U���=r�^������u���0Ex%r�u�h{r7X�.�S{�>�tBֵLl��d�{-I3(ڍ�C���oAՂ�/�����@�⹨��vu�

*	9���j�X5�
�"��p?���+�fO[_YS�6ɗ�>��d9�[Hoˡ��OBA 1t��Ԙ	��u��nv�8��5�u����(=|e%��y��΀��n�f�$�l�M��k��s�t�UH�
G�Y�F]?1�#��fɗ�o�\��8w��[��i:S������	z��z���h\���?�rO�(�� ǹ p��b���B��� ~�a?�#�V�v�䃷IE�I������!ɨ�fC�K�79P?L
p]Dۇ��p�G�u:E����Y
�����@�;���ش�A�Q1�i4U����I�a�G�-]�O,oc��[S�0~]$f_�
��՛�=7�H=I�(��P��ʇ�� R1�;�����b�g�nzt�1���f$�7z�d�}�&��PS�&]\ŵ1p�&�^�0._%��=��0�z�����O����v��:���E�pv �e�۱U]�CL�1�FW��u��X,�$��q6L͵���L�ԍ�
Nd�p��~�I2i�'7�n��>��&��/|���{���=��g7�Q�\�U?�T,�ڄ��-U]e���ܦx<J˗+����K#v���=DȓO����e5'�nڬ���􄿝@��_d�|��dU �A�Ur��϶���uiQ�C��n��V� %���3wM�E��x�Z+Z|�y��?>��ڛ����,fn��M�����֑��i�e��u������)B^��0)�-��3�`��a��Ym_��vI*rP{\��E�"��jILˆ�'`��E�-�?��9w_Pb�! �q�m�N1|0�.���,�<bkSfTֻ�*�T^(�iQ4�n���������1�C,TN#
`����g�،� �ث\����Ë�qL�?�#���]c�}W�0D	��w
jW��n?K7OC0,A*���{9��/H�`A�[9�����2�D���=�I4$y�E��l�Cg�3Rx������sy&H/B��(��׊0R��I�l�d�1��W��]N�:��ШILb��=�x�����2)�6CIT��O��{vm�aD�o�����%o���웽��.n��8��1�FU�]|��ZT�~�d��̆ū%�iI+`��F�(�-��g0kxg�����۾�~iv�"z�5 ������w%����8�N����p�^н~����+`<X�5}7t^�b^�v������hʓ![X�ya��Ҭ4�р4rFb
/�	�������Ej߻�פ��!>SA_c��r�Hù��{�e��#4���L��ڗ������"��*��)�.WX�-���/�s���A�v��_����.j�#@�� X�-��;OU9�/��� ��Iw�0(ŝủ*k����C-v�M5����9W��w(Ϣ�~�g�)Wͻ�#�Y1�/&ݾX�d�]��'�㙘��"֬ZV���O��H[�xh���ϑ�#r���b�*�u�|y��V����<������݉���;�o�Y-��	�ŧ-��Yn¢��C�#�&���(_�������b��O��p�2�知�d���F�ţ��YH����O�V���O&���@����q�X�[j���%��u�w^<�6��=�������z�Ns�'�2�'m{��|lNp2}�T� -lVwcV�p>I��@[��K>��FS�x�w��+Ȗ\�"U?Y6��V�:q�H�ˎ���L��,�_�ʕ���Y��2E�F��E�>$aѹH���S�����_H!ȉ�9-̈:C�n���Pv�|.�G�:������]$	�H�`�re�����!%4�=�:1W94��b�%�fb���&�z�?WQ�A���\�!%�����m��'��Xe����n�91���:��"��(���K,v6����cw�)?Kl�WtG�bd@�߼�k����Y����m�n��y��0��O���﭂��:F�&`�"�D���k%R�
L������h:��,��:N��R��|<T��T�Mu�	����z��ş�ۭ��H�+T�y�J었��׻�c��(e���7T�9ФD�� 9�Uw+|ʸ;*#y�ɱŭ�%�ϲ�6�}7J�?�?&�@ �2[�Њ����W����s�:%\��������1��p���!�O|�9� ��,l���I�R�f�1��	=�`uQ��&fHC4���9̛�B2<��C��E����N~����f<�V����aS�;b3�{�sn?o���f#;,��H���a���y�X9�k��:M���N�_�2v� %�v%�o��A����]�/,a��S���,͹Y�����#-���7����6盵#��l��
��s?�J���*2����h({���,��S�m�<��Yn���Ǐ����B�$)���r

��41�y$���V�F� �]>KX��Y����o��9��� ���_`�FBwk2=�
tMW�8ɫ����y�����^��.eD�Y���·��9��S��T�x�7���=~�O�?��Ͼ�)�z7oD�w.v;��Ou���9I�/}��/�q���|�o��]����:�~���F���Q; �F���bf�o�����+��N�`��J"±3�.6�Ȇ�!x�Հ�rp��M�R����,�l��6��;
.*о��ĉ�%'�+}��� m�,P�?JL�4R,7*����ᡫ�w���ʞ��lg�"=�m�T[��PJ����������� �]��t����6�1ţ����z� ���{R�ܷh��'
�qmM^��XZ���G'�S���y'e[z �ngێy�����)~x ����&��>0�L��ЃeVP�O<�].��|���6-���Jh�DѸ{(�7 �u��ҽ�<Ϡ�6��7�Xy�JH�q���7�@5w尌����(��/���E �z��K!� \�;*��5���G4���kp��=ʎ��
��*[꜐an�;X���z"!2ю�bS�RW�'9r#��ݦZ��< wn�b��k�(E�"N}�&�g�D#���C�F�h_FE���UF��{@W�tڋ���G ����ĉGڨ �6C�!79Iέc�<�r�2�}t�� k�T�	�$y�\m���N�chM�t��޺׏`S{���~�Dwms��:*���x�^�̗TdC�(r-���l��=a?,�4k�9��J�Ew���Q�"��%Ɏ��d��f��y���4�\��+��f�l��9�N�*|X��{3��A��M{�s�.5�j��igf��<�a������/T���ɒ��$t~�a���˳����X�YTw�0��N2��x7���ئ^���<Σ�f K�O$���2�G����0x^��1�N��h�N猌���c�9�t��n����/�>G��U�8|k8�>ٲ��B�s���.�;T��h҈#��
\�]�����٬�,_���G�����nt�e���tj+�
���xh�[^����!Q���mg�:Py�:9"�؊��B�=�!X��s����l�|b� D�0 �A�Ur��&��<|��IDu��>ŇȜ��[�"���X޸8�	0¤Ju��k{�=�G��J�g����;T���܂b�{�Ŗ��n5�z�%�BV?k���u�3���T���1�g�R�}3�98�zB�]�
2���,U��^�����*�]���t�=B!X�٪_��v�t	��'��	kq�װރ=�b�!�'���&]��:M��%:���ԟ��yɁ#��t�]��p����D��;��'t{�bλ�)��fڈ6b��8x�TK�ǯ.�H����j��҈��T!!Q�!{��D�!^��� .Jx�7�����<c�6u����=��[�T��|��$�h� ����^�O/��M���T�Ϩ��"0�8����$^�$e�����.��/�rD�*���,���9մ�yRQ�=ג��r�P�����Q�(��EA���->}��>K�R��"5 qPy���[XV��L�V�4��!;�Wс��Nl���.����8�x��I�UPKs|9��G2w��>��q�ڵF,����wT�m[���"��=ù�Q��2��0�@�ASkS$SDڞ���������~�Q�(�н�pߪ<���Y%�]�wjyBrrܟG�,��+�&9˪� �T�� ���	\���0R툑��X\���(�%��C[;�P��'�8�#��k����XB�%[����cj��c6�?o��K�xP�Z��k�&	 �����@N���d��J��.�Cȥ���9��f]Hm��r���g�&S��Jg��rt{2�A�)^�]	W�)�b��N\��sz$��d>�n���9��O��c�u(���I�c����[��pa���������w�����c͑���� 1GHXv�_9d�̖���F���8��BX�����x����%�5	�ZMD>�[���g�i*W^ǘ��/�^�ѯ�\�&�Ӻ�?�i��͘���=��|u~��)�:�?>w��0�I�q��	�{�I���BD���4tFĘ�lo�W��5��}D��t�%��������Ye-��x�8q��⭫t|7*m�aNvAv�C"��l�r�ʸI^�RCO���Hv��٫��_�پ����V�P�9�#�8�rG�E�ম��nx�����؎|M��n8&�)&�*�o����>�@SQ�=j��5t>����1�9^XmL㻜���%�^H����Ij�7I꬀����E���v��?�	�����Z�n9�vO�rs���dh����� 즻����Dav��ES���p��歷����1oC����;F��۾Y�;�G�k^c	Y0�!|#c|B��/ X@uP��
p����,�Ы�W����pod_m�,��>��VV� ,תa�.��>��]K���kmc��z#�������˫����-�ܭ{i}���G�/}�것-�ǳ�>\�@.����+d�[!�g�X����LSN`��0<o��&����(�V4Ѭ`1�����
te2�6��( W1��m?5���WmC���Q�O=F�M��en9����Cg�<N���ӋD��7�N����XiZ���d�Q���vTef�����4e���0:��m�(0�h�0�3	O��*�7O#Kg��e��F���S��o�2q�]�8�*1�-���n��N	ާ�7شh���O���������i�+��򂵥F����J1��H�W�_R%l�<����C^�R�M��)�l�n֖�O���0��S�;Wi�T�������J���y��dO�s��;��<Й���y��j�wzG5�E?˼J�J�r|��d��'�/��K�S��(À����XO���a6����L]�}�
�z��Ě�vBO�+�5�h���uU��ɪw.�����2'f	�tA�����Px�8���>��ַaN�UQ-�>�^rJrS:?�bn�K���Z��z��HM��V�����q��3���x8|��֝��in@�~�~��w�ٝWRm���	I+�^;%2I�v�m ����fA��c���mC��@3:��j�R���L�AX���J=j�P
^O�2A�K�iV;�V ��v�g�@=hX��$L���UD-a'���B`8\4�|\���a�3yӂ*�	ӖO�/���0�Ԥ�4�I�T��v˛㼖-���%�QFP9s��92����3P
 �}�]lk�_��/HQ�ObIm�(J������aM�֗֫/j���k�q�y�r��Wi�8�X���sB�oU�<�Fu��h+DeH���"Ň��AG� = |J*�ea䶽�$SN�}�:�j2���M���2B�������:�����~�:�gtAD�|k��q��2�Yy�cȉ��O���V
4�^�o��P�����;0^ڋ��@hs\c%>�uEu�}��f��An䙠�{?�zxηέm�Ҷ���,�-\pᤛP���!�=�ِ�X���4�kJN�D������h��r��uH������O�s{��;b]�T�C�U���Z۲��'�RYFo�w���g0�y�*����ɟ0�w�)Z����Zr�~�p�U�7���v+�����/��W��Q����{-:mYnD�����C�?�����w8%��8˨C����-��F�c҅�c��8�6�<����Os�������@wO�@O��^��ӬR��#q���@���~z[`���$)�"�B���cyNY��O
U�R~iZ<5�,���������W�gJ�#��l��|�X7Q�ie  ���*)*q����YOv3���8���b�����$�/�Nw	3�Wu�R�<�+����y��~� ���v���(�A[c�>-
�η�&������U�H�O�<��L�R$�b��@59r亊���GМǑ.��=$`k�ߴ�v��em�]��vf.m%�/��f��f\�_C�*���Ac�R�Yt���ܨ,5d!��'��O�?��������	�O�R�r�(��<�Y3����[@ �k�dI�@F�ᮻ��T��⡄RR"�q8wFp���ٖ �i��e�����lGAu/5T����ɐ�^��@]���<hP�+�L���R�mA5�w�Bu;y�t`��R]�d���g)��
����~�*�سD*�����:{.�eT��	�1T���7w<R�R�'�W�	�;�z5k
�jKh�� ��N� F�=���A���e�ь4�A�q�=�*�,����,2c��1՜H��U�VB�����pe�����Y1���D��[����	o��P�/��#j�1�����R.
�
Ț��eDe����ٳg�"��𼇦�S(����"�(��3l����&�˜��yrv�d�B�Dҝ�Q\i^B�.b;[C6�v$P��PJ���D��΄����Ǚ͔���;���nȟ��L��0��n)�_~ࡀ=��K��H�4Q�r����Y0yB�������[.�k���*�4��}Sֵc�;;�ՠ,��;�qNK_��w��q�1��j��󿪘�]��K��I�����N�6�:is���慩�1qZT,x(��Z�'X���c�m����+>h����*
V�b��Zh�N� �&�	�/�x�|Mx�����JT��Hɓ��q���
����`��u��H�Kvd@����|�Xv�/I�[%��p�؋o�	 _�k)�p-����P`�*P߽nY�P�������<
�'y�X����&�a���iv�2��^3f�A4p KH�z�GK&��S�*�i~�B�w0��`�}��>���V�6{�w|��l~Ye���Vf�~
��σ�F"c�O1���oB[io6������|��
�����] f2n��A�k��%R9���)�l�m��9A$�\�n �R�+G��7���6��`T5�WÖ�)s�I!�xo]f,�������<K{�Rٝ�y3��F��+*��`9�@?�n���XM�����6�K�䮸n�1*��Ȧ7!�dgu�c�v���4
��g�T�6$F���*ߨ��a[��yf(��~�I�y���Za�����{��I"��P�%����D���~�\���	�>$����A[��}�3>����Ra���*�� Y��CyV/��7[�87wĀz�ĔG7�&��P�g�4��PU��U�Q*	v��~�H6���5*�+�`r$)�;��ʲԈ�d�����,U��*`����D���{���jk�n�(/�8�t-�nj�$�m0��j��Cw��U��Ly} 25ۃoi���y������o��o�D��s��[�;�j��Nj�?&VQo��x](��U<���d^�e2�1�^�Ŏ���_���<^��BH��7Z-t V�K�P�r5��,m,���?���������y��=*���^Y�5UҊa~�K	����eM�~����Q���g��:k$�®'y��W�����Ȕ���ލO[��^~��p\��t�c ]`��{gI�5q��SY?�dGz��
^�ޱ`q#l#�`,��fZ_�>�oo��xKq>���|s�����P��\���4��(�6����r��l��4T����+CK<$[.�e/�np2����U,��딩�.�$t?R��,e��u�x/�X�P3��*�f_���[�av����%�n؈h߭r���b��?��e�Q��NQ5��F'%nQ3��ڑ)���3��d��A���7eP��}��UJ|.�\�Pf�h;�WC(�KcI�0��H��.GI�z��Fe!�� )��9W����=�0�)�1��5&�:���������=���y��ꇦ04�{J�?4!��e)����٠�zr�b���a\%�N_
�ņYv)I�(��g�����@#em��{ȅ��+wuФ�c&����{(]�����.����A��P����^�s��N����M��gTu���A4��������o�U>�N)T������jd�5��T����7��cB٭�0:c7h��ߕ���쌾Z1�.���O�氟�~¬��Q6һ��� 0I�6{LцU�O�ޔ�����L�Hϯ�x���
x�,�+� �Ǹf�l��LgA،�f�<��\v�.�.E�4������*�?aj�+���f,��=@��H�T�q3��r״���t�y�$��!�Go��o�I_ ����h�q���)��V&�j�NȬ���v]MC��,��C�pܐ*������'��Ƀ�t�'~��B�~���N{N��:#��ʫ�d���X�{{*���O��
��e?�|W_��g�i�o���� [�;�R�s�
(m>ֶTĕ{�zh�.[3�e�y6
	��~Yp:�(Q~�����h;E�H��@{��]G\s�ό�Jܢ-���M&��ews\/��t��>��t��zै����4S�ƺ��;�z���S[5���>�Q<�sM��$׌��H쫙5}Y�t�?.��k�z�@�������v э>.��~E�P���!�0�zSmk��� ��#��J@h8Ϟ���I�7@�-�K�i�5��-�?/��8�أ�G��[0��1�����8a@�=`�t3v��{h��M�O��N�)o�hlB"�����vspb�K<�P�K����d��ˈ$#8k@&d�Kf�w�'g5�������������ҵ�'	�&v	���)i��I@���kî���a�W�MV.up|������;P�]<B�����0��s��Ӻ������[4�	���:�9�*�w��2j�@�,������?h+��[�n�m[�y�}�VR�h�h��⁥Ƞ���و=Q���N���K�bOc� p8x�s[{᠆��9��Mv����A��T� ̨� �o�U��P������6]Û?���R�e�wT@?��9U,#�s���(u�/�S�Y|!�P��s�#��I�IO�Xq>�傓%%�7��y���7�e�q�EcP�6����>��֍b���S8Лg�/�پ�VX0m�L?{\-Y�ӽ�0�c[��U)g�����Μ+Q.$`H�zw�V;� ��Z�C�[7�%�Xl�FD�,���7�/�Is>ݚ'.�p`�U/>\���j�gῄ�Z��L~��M�.���2���,T��`����u&n]̋�!5�}�{�E�` ���M�r����@d��sGp��Vٴ�T^2dz3���z�#���������J�D�d��
��+�ǜ3R�@>Sd�B�$�<������V9I��<'��LPD{V�pO4�tF�A��ca�V'��b�Um��;K:^�~��ó�~y������ڴ����G�,�IC�S咶c����m����M̓�<M��:��z\(U�B�!��(�Eq�6̻a3T�vis���U�P�����ƙ���,�� ������s�B�h���	��}����ݗ�d��`"�C\%��<m2�m�:���iG~<Y���g7������}�X}���\��*�L�}�l�d.8H~f��vK*��#�>��գ*N;pZ
�O�Lx�|�_v) y�{vF��fh2Z�yң�*�w�)o���)~b���0�����x
h�3T�};џa0�����Q�w �����=9�$��>k%1e��_��u��8�� ��ĕ��H��4�M��,l+KpU�0{�Y���x�,�2Gz�	�8��6�Vds�m-��ݺ� ]h��i�u�IZ��.�d��h����YvAb-;m]K��~�K�n#��[�$��3 &U�U��Ͱ�TF�%Wqm��.�3�C�L��`?*�?�nN�v�|b�D	6���d�K�R��N~;k���W6
=���Mø{��iA�w�&|��`�-7Φ���._�RXz2�;^��~�y^��ʂje�]n�#�[TN��'���b(��k�l%k�O	vM��L)o%����~���0(�v�t��N��_	���+�41�����;�]&����O�����������Ɍ�r�����Wq��;��˖���$��(͛��І��Z\S�F�p�pg�E��S3O8�˹P \�C2�&&#۫=I�H�Œ��)�?4ͰNܗdc��ˆ8����?,+t��6��2��	�p%.�.k��E���2a���mj>-o7e�G���	y:�'K*<V��T%00��������wQ��}�pxc�\kR9V�W!�9P��39���;�N�!j��Lc�i�������@�Y ������Ӣ9��d�_�F����Av\Zy�
�=5�խ��B�������>؇",����)��<���N�U���|i���t�}A�}{���u���4j�A0�c4c�Ôm_�oE�B���^/J��(´����=ײ/�W˶+3�n+�НkO	WU�Q����A[�I 쌀+WȨ�T����Hn�C��g�Hl�d��.�8��s3�Sb���H6Yu��q[�Uw���І�g0�U}���������6ڲ��s����(�2(��0�dc�d�o����&�*B��W-
�Ԯw*��T�ͥX'�4>Q���"�+י}j� AS� ڍ��kr���:�o��5�lsU�W����$�&Rq������Y��$��_BJ{K�4�8p�h�?Kk�8�Q�)(=V_bW��J*�#��j����� ��<��Tȃ�@&����XX��q���y�~"�[ɂhmTzG�V��6Rx���)��%�#�n����fg⍕���b�|�e����xHI[��g4p�<bG(�?q�:�]jn����\_p׋*�0��##od�<%����	j��{}H���P"n�� �9N09ׄȴ\Ux�)R�[r� �K���<�;�6L^B�o�{�EJ�1�{�ӿ�c����w\>\�v�3S�Yz��@�(�?�d)%��e�a�=�,d+�cv*���r&
^�IJ��3(	���\ݾ���ҽ\.��dg��k'֡`���3�4��ܛ }S��BU�p�̀@�2�ۓBl��@O_��ʮ�1�_�k:qDriz5A�$�`P�1�i"4H�ޤ~�]M7h��^:��� ���Lf�v� �X}�|͙���I4�I�m����e�۴ȓb>-}to�a4g_$,��B��R��$c������?L��}9E��&a�w���L5�u�v�M���CP�*ڋK���Vx�u@��:�W����6w��޹0L��Bc�"����8��[0��nTIdiY}�P�F�������8�AL�ɼ?�{s	�J
���G����/�?��|�|����X���i�AS����9���[�o�`�]�������q�Eg�G;�i�D�m��*���$�In�3>�#BɅx�=���������꫒(�h�1�HH��r��C�N�XV&���Mn�5���H��y�t�����Q��3���%���I��������ߡFL�x��+��}�}��L��V�x���SZ=|7�l$��y~�~�˨T�	\T_�-��`F'/���]-,3���y6��Am�g7K�\P�S�o;���l�s�MPbW�ޒƢE��<�nBG��:D!�Ѻ���X�[f��h'�a���N�_�}}78T��7�ƪ6I��ޙ�Q
^��ͦ@@��Ҙ$$�/�nC�=��F�!o�"��>�T�`�8D�w�il԰%L�^�C�CB�8���A����� ������3���7�����Fn�@���X�-\��W�����<[�4^PY���;��E��l�۷��L���D��r};���/�F.�v50v�'��Eϙ��(��g���d�ăZu29���*K�k4��P�S|5�v��OH���zе���s�T{v�����ݻ�R�H"V6�=�d���ppt>���P����:�qdP{�� �>�S������U�V1S��LS��?:B7w���-NG+
��{s����p��<�8+G�V'{�y�ep�wg���.�����*f�7552'�rps6�pz�&���5�P�_��7�U��7~�9�.dg�|�ӴD/8}�������]i����'�Q��<�R�jhFM}��:�ūv�U#3;���F�-�D����&�.��޴u�ٙ8�&���T�we9�B ��1D2�υn)=��6I	�[�z:z
��75�>t[d�wI���x���ou�r�������S4M�	^�q��HRC�(ꯉ,�;l.2��1�/)
R�>z��0i�3�-WMZ��euT�D�^�"/eT-W��+~�W�~+��\�.3��:M�&aǆ/��7 Z옐O�6�&o�i���%\�Zj9�?��y"W!�w��Ӛwp�ǣ&=!]R�$(�9y� -(�ɡ�4,�ۋ7�%K�=��>�dM;����B�w�!�(wV��P�-Mr�)ߤ����6���+�C�G)���>_8{X�U��M��
���7G�#���,�����w�
�V��}�E���Z�-�7|>4ZJ*�.��9�/�X�@�	=k�
?���~^Cxj����Tm��י�ܤ�kn٢�0b$�M�R�d��Jk�q��j4�$_��}�]G�*8G-UyT��YF<��������z�BЭYМt��*�F���dW�9��cd*��Ո���"�f!�2 n$�6K�6v7s>O����*�8+w��/f"��qH�4؃�y#�I$�E~���Pf�I��V��_o؎�keQ&��^X�y���(7��6��lT^����-ڢ�#R�����g�����f�O���Y�c���i�*�!J�i���J��a��c�V.�#<F�9u
v�`��1�@Jnn\�C5�y�q�bɚɄK΢`n��y���>�s.!Gr9��ՀVRO糠�����b�]x�D�>rơW�F
���� �˴埵q7u����8��^��rw�1��b�YK'�A6�yЩQL�&�:�K�_����1��ɹd�.^g��?F�x0b�Bhzl��p�{�u�}�g�bd较�e.�u�љ�1S$ĝ��_mi��5�f M���,�Nڛ�w|��8E��ff�k���2>bbS��<�7�����=�~XOܸ����~(�Lk稢=�C�T[�(�<S���{�x��ԩ��lc���	dֻi��%3�$����F��ӭ>�HVOxq��I$������F	�tb=�g��JŹ��_�Bx���?�˄�%	I7\��*��ռٳ��NJo�[3̴"��������s��>MC�r-o�u4~{�+�nI�
��O��it�POĮ�HY����|7�\p77�uEVd��lѬ��f��r�I|��P<����XC���-�?��aw���Ξ�S�K�o����C��YCd��L�A��⳵8���e o��k4W4��@+t�<Kp��Q6w*�(���I��s(�sο~��C�$F�C�j?�v�8]�.�L��Au�b�,E^�k��÷�Aӱ]�
�TN��� d5�OO[C��S�;E5�>�k�-�w�+B<��g��:Q5��k��h.��8��)I����T��f�j��ʬ�z�U8���P����744��'�=�v���(�a!�*޴&�"�k�-�l8ՑFm��KtEi�P��~���{F4b��Ĭ�5�Y��k����~��5O�dq�X��$Ё� �[7#R=�I�9������mz���Z��/&�+�� ��� 7|�&%� ��'�l<J�/�P�q��h���H>S�H����Cۋ��e;�ˤ�9���d�י|(�H�AR�F�f�rr�k��
@��d��G��م�/�@����
V !�_~��°���zv�L'�{j��ǀ�Ө^"��i�F$_|*hB��j �#�g:��ӘYSOLA�d9l��u��n_�����~�k�d�l��$)h$ЉT�o����tx�a�u|�����y�0��*�3��MJ߽���(F��w����|vy
�L�{�W���M�{�J�`�c;VY]0"9�����#�[wN�(N��Hи��-$��&�]�_He��(k!~��n���i�w*�R�sG��.t�b`/���s-�E���\?���K����cc��u�L���|N��g�-�)3}��<Y��:5���#�Z� �㑰�6@�yd�0&���8�������ӇƋ���xo�)��"]�u�W��.���[�!���Z����|؋���&�Q��_k��"F�[��B�� �d�ŏ"䙒�W�H�6���]���.��^ ��OA�����sګ܅ =��Χ�R��&@-�����$�r]z�X�)���/l̀B�Pi ���p���5�^���"��t�FZ=iW��bƯ.�4��.���7��d��R�H�V��sn�V>�@7I���~�*d�g��P_�b�8-V��� \4<�S7�\2u��^�Ay�10�8�y�[f��*�,gU4�(�q$4Oť�qG��E�Ѝ��z ��o�}:Qk0S�Ї$T:"�?؃%|���[_�Q���q{|���e�|�X����P;�H�m'�u��=���� T��,N�]�O��j!�^tu�w�3��	5�3e��aK���	
z�y���\�Ǽ��͙3"v^s.��&m�Fշ���HTX�1%��yɄRq��ڐp�L�.�>/���,e6Rei��7�Z�p$��v#V�ʗ��솽�w��h�g0�t���z%�-4�g�*(�V+���S�Hh�f#�����3uv��ᒴ]�?�G)NVxd�ĥ�)}H��J��x��xy�I]H��6������fn���ݪl�Uؙ+���EVm11����̵��2=����e_�!��=1�2
ua�q��5�/��c䝄��c�-Szּ��]�6&�WD����}�jai�ɸ��gʂ�~xK]�.K�S@�xֶ=�w>�w[.C������+��h���Ē:���u��i�#��6 �z��K#��v�m�w��,ƶ(��Mv�9;e��m�Ð��{� gE {��=j��7���ᒢS5J�~B������1g2�
v�R�o4`
���>6o�������?"<�wJ]M'28 �l��9�W.�����Q���'7���2s���#ɳ=ukR`M�{���&M��+���B`���;�$��|-/D׊Qm������G��c�A��qNEc/&�;�HҘ:�,I�����Q���I��@��{E4�)s�ŜOp�V�6Q׻�i�����=x~�H�"K;ۊ,����S9�4Zl���A���eZp�ݍ�؈�b����$S��^��U�xQ�-�4J+�G?>@�5rяR 6v\/��g���ȱ�;��d�ӷ��Hp��ډ9(0�B��|ÒPO��75��x�d�p�T�.��s��,X2�B��6�S���5s���� U ]���{O0��刞�`a�I�|��4Xcnm��^�a?�0gI\����H��]����|e�b[���Ga۪�p;�����`��Ŋ��䰴�F<��z��ZEǬ�ڐ|UduY�W�Ϣ�Z�4�,:��@Vn*�����BC��BG����K P|:G�H)�O�͝!�w�3�&��Y���R�r���@9�:��ΰ�$�g2������la�Q|u��A��J*o��sߪ�%�7ˆ��L4�p�p�z�|�T����t���QI�
��r���/V*���g�hck�&��w>��|��Y�@�V�<�cOӖW�0ƺ���5#��'6gQ�$���� �v֯\v[' bCO���+��iu�K���4��N��^�.lX.P-x];陟׊��豧j%>�&��(�t�Ck����
O⃄c{����ֶ�gz�x8��~�^�iR�^���k��eH���!���������P�8#9�;���uF�p��J�`�P�;%m���D"?�͘F.=�Y�:Re{�K�Ô\��@�_�AU�m��z�+QÑ�8�Ȉ(��
�Zt�����)y���^}yk��e��GM���g��!�;(�c�X;��)�����d��u5Z0S`��EX�B�+h^���B��[����z���(#��2?��!�S1t��kd�|�C���kg��q�ӓe�3�e�|�v"IO�1��)��u���=XG��\���I۵��U:Wss8ހ�� 7)�S��ǖj���H��U_E,	=a(��m}��e��3oL�[/�
�{�T��eX�{�o��@;���qƛ@mP�@�A.���C��H��f��	Q�xF�������L�R����҆���b�J0G��HY��2�(q����uvI�m�0>������� �
�π@�V��B=�>���ܑ��9ç���{�C��5��:�W�6�`��1�����K��7�c�O����\�L󬗅|#�l���9n9m^"��@��X�kZ���v#
eΣ��v�@.��lNg���n�9�&�B�>L6-S4�yczr�a,��;��N#;��:�(�1U��>�E^���q��J�%�.	�2C�+6/����՛�n>!��Ӡt�H��c;�D)�ٲ�I�6�\ 2����zJ�F�;���|	��sE'�{��u�Wtdx�ؕ~�ؿMZ9� ��J�`�W3 
뫒ƗT3p:�&�7���<��|����zw�\���<d&��ƈF������=�,�q�T�Vf~�c�G��K�5z@r5#���Ѕ:By�u�m���W��8d��J(��f���i�X�q7�UpH0o%U��ִ����DP?�>n\�@�>$��k����#5��G��E 6��F[�Y�!����[ΡX/>fT(3�a(*k�B��צ©�2�6k�hL��U�nt���5�Ü�F�t8	�C%���_8����([u
�"���cr�VH�d�jl����L"%GS�n5�R&�p����nH�d���		���%^�~Wű��!ȣ��;U�\�@���s�f�s%D���x8C�W�b;}`(����Od������r �Yn�@�I8�yx7)����HJ��4�6�>�����頉1m��;��CϢ��q����ۈ"I�FjɎNT���!s�)gx�bȣ�����n��_9�q��혏���M��sB���Kn\��rBm��C� x��8#�v�>���"�
�A�_�]��so��iV��/b6�7�CH�V��C�|3�˝=�{��V�+�Q��u��Ã�'��Q�~r@��� ���ܡP���������^�X�G6����w����}�o�y�p�Q��{"�< �侦��vsu��;�ȓ.3Qs�=L�P�L��t6�X��R�2e#� @�&T̑qBv'~�J�Zڕ�f����+W�Ek=��BG$Y/��,p�~p�^���L�Z��oϪ��F�R��(!����u�D1��|glB8͑/�R��e%��K�x�,����{'��n�Ҝ?]��"��Ƶ���K���oM�I+-0!e^G[#��/����g�p���)rJƳ����R?�mؗN��{�:�D��3_��ͨ���B_b�q �U������u�'j��ښ׋�1��H�r�*��BR�K�<m����c�����RM	��j��[~�X��8�5�J�E���V�7k�i5ꋂ�=��[��0��ӧ��>�9N�Yp������P��
9T���.+碰p���I�&g�_����IV
�OÖ�T�E=h��A�JeP�{��v���,�y~!����F?�|��_o�l�ek���έ�K��l�·�9��""�)�,i/nNO����;��2�ʙd���g��4G���x�N�F:�"���(L�!�h�lc��]��j���F��c�h� ��W�mS�����26�y�Hf�2 ��ΰ��8����!���s���<8��{5�r?0@�֗�c1g�o�k��A
{�����c�lV��k�(h��>�]�>W�}�@�J�<PN�,J�AӐ�>������B*w�u{��v\�P�ؠmJ��w�rЕgCJ��H��*8E�4Xfd"�<l�%��g�4�,jQ��b�y"�p���_^>9�"b�1��!�.S�+�������o���p���Q�c����6�t���.y½��I��6p_�?[d�L�6�c�Q����B�{ ��]8�8�p��i`X��h~�F�c��?9����Y��#����Y3w��W�:7��tq���Su7�SR��$0L�q��4��TS`�?�7�d�;f�y{"��٬w򯡰���C'�p��7��ЪR�����xd)��f�3d��~3{����D�(&�;���aRc?�?��0��H�&X8t�<�3vL���2��YĘ��2���
Y{���?ܮc�>r]_�[����8�C��EZ�&����5Q����q0�\�_�>�2�,�]z���k�e�P���PF�-� ��ݓ�7S�,�F�#��*�a�Ѕ����ؠ�4w�|��i�����?���D�{�@iD.���S��ڗֹ�-�d���'ع�=D�r�[���ΜL$�>�_��T���4?���|{I��{�d	e͡�=_��0xA߄i�U���@#��+N����(�]���ܳh�v�wR��S�t��iB�E�`��6Z_rǑ�0�q#�QAm��))������ ������N�¸p)H���#�QN�����Ě���P]vDm�
��XE������ݣw����%E
�����\�F#�lȱjw�n�����$:U\�i8�p�F�C�k"�2���r�������zq�r�"�<�,�p'L9��q@V�%[����ɮ�̾�H��/��6��a�̓�ҥ
#�6tF���OG�u���;���x�_>-��>�o9l�&�aP�Ҏ���!.=!�����=��WfrkS䘲��@���r�d���p����|���.4�ȯ��6礩�nډ�W�B�����͇(�� ����~+���&Él:	CA&���
hVFM\|�|�Q�k����/�,ʯ�@;���sH-G�l�f3A����~:W����G������5Z[V�;6�4�S�O���C{�J����B!��]����x!k[%���ؓMYq\���#t^bg0 ��J��W������UO�J���g�(G�:�h%�h�?ȩb�nۤ.��Q������nۈ2E�4�����ּ��a?-���|2}ɋ�\�fS�,\��59��~i<��.|0����Ȧ2�~��QΊAΆ����,rėC�Z�~Ѯ�y\cf��Qz.[Z�R>I]�?�E��I�����'5E���}� ��us䓗�����yV�D�ћ�f9�B�SD�y/
YW:v�	�Z�.������� �%Q��xҾO�X�=Lȩ��rzz�0��ǰ��ͯ{'�
���2�������s0]�&/�-�� [+�Y�D<��b�+e��C���nf4s�Z/���<$������k�����Qt�������\���V��S
������#��7˷�ߗ�q�n�ǧ'ǉ�%������;�ߡ������w}�a�F	�i���QX�0���|����K��OTm%��(�'�zRXI�Dh�9I��M`;6(%E�?ثs0��	�wZd�4��ƞ�S����e�d�c�[��i�A��&7�s]NC���q����ǁ�X�ꀷ�Z�ܸ�,�>�c�L�荍mTF��K�0uqH2�`F�^׬��j���Zs��5<}�$ȩ������_�i����� )R�vb�z��� ��^�`sN �P ��.�G��1�䄔|�-�.5�jH��B�� `���c{�E����H��d\[��O��-|"YK��2�e���S�OI���(�)����ӝmQ3���򼫩d�e�:�h����y��SIBa�((Nf�o����\���K�V9�S��fxO��}Yc�P�f��:�\���	�!���.k�(���!|�*l;�C�24QjG�=ѓ���S�a��՝Y'���Q���&T��J�hN�^C��k�n�0���
��M�F�?���s.�Vѝ\]v��h�g�7�S5�T��7r��
�B�����jZ9��k�G� �:q��dl�:^9��A�~t�'h���z���B�����݆t��"�k�ZM/R!-��w�����<��p��u[��8��ϑ5��JlO��"� 鈛�c�X
�2����~s��,j`Ă�9�x�B�a�cA5��>�6dvąz	��T��e+�\*3d�~�QU�|]��C�$a�(�Yb�5]�{����zx�Gk������P;%�rw��� ��T�E�6jw$��P�]Lcu�4lS�q>�f� �,=���=���o=�:�Fr�r��@p�>�&f��B�����i�T���$�l�ӈ����<3̛40�H8#C¬O����,��Y�bT5OF�o�Bqkܮ�V-��Ky��O0���P+�Q����ņ�Z����R?2�_r��$��S�� �i-�$����3ܤ�E`��(��.��:K���@�Y�7�4����3Y�<�� 9cFQ�k�� �0�lN�Z�����I��:1��D	�^�K���-	�Ĝ�N1:L�Z^cQ�l%�x{��[o]rp����[J�����m��i��[��y�Z��Kt��|��E1҂]��!�!o��D�Ѡ��%yl-N��/�n��9OUW�C2��7Y��uq��Θ��
�������"T�5�q��Zqx/��K\�Ǖ,�|��}Zs�6�R�A�1K�1>��>�%)�2GQ�Վ̒N@��S.g�aGM]U1r�t+�en1�9=2�!b�E�gO��H����.���^�nZ@��M�ˀ��cnKJ7���h����<�oF󹉐�R�|���Φ��.�j�gJ�ϻ��3Z����|X$|̖�y�|�O�No-2[�5�X���r��^��";�'2_�y�������jw�1W��ep�ULf����P�����w�3+[@rv61��ƉՃc(Qe�'=�:H7~	��>Ѡs�/~��Ǻ:�� .S|�:]Kkh�5#��_kjt~*��5)�Dl9SJP@M+�gФ�'�@�$9T��3@�m�'<���^4�5[�w	"��0�Qu��͒����38cR��u�vp�@X3
PH��z����?)��Դ�V̄E�^G��$�`����G�p
ba��KKk9��(�� ݷ
��=H��/������]��t�;W�-֊����+�Ղ�X�<gc$j&+ؒ1jz�)C�X-�M��y�(��~&!�z�A��"���lw�ȱL�N�pt.$��Mf�Ec�t�mo�����yO�CL�l�\_Gc��-��x�7LN�:I �����_:���`ֺ��%�hJ�Rw��8ݢ�
��(-:�7����h$:���*9����R�0���Ur�ρJ����{	���lB�1���PsV�|��K�I3�Ttװ#u�ګcFrVk�<N�h��7g�8�{1����h���
&�㷏`9�R���|���Hm��:��
��+�Vw{0Q(�N���?�	�B�!��y"�S��1����.}Rg����o�K��ķ�澸�C#SI�cN�ZlkP(k�R�ݢ5��E��@�˒�r��ˀ�򆊍�7p���-^H���a������V�!�c3l�!�����ܕ�� +֌�����cT�I�-`�()N��	�G\E��x�X�ނP(��D�)���O0�m�}���X�YQ�:�:A��8&��w��][�ݹ��%|>׿/ѻ� ��i��3C���O.�r�>0%Θw�b�T�^h���dƛ� 1�7��6�^36�Bd���5J�X�TO�(�Lr^ݽ8HfP�k�	�����T��Ӹ'��B���\��EMn4�/ qJ���+�f�|�A���J�����FR�5�vFns���|�&����m�#,�{������*Bvpo��U���=�%)9��L�gˀI�������|���K���{�.���|`+:���Ʉ�S8��B�����]J�adrJ�Q2�����y2n������$�9ҷ���X6��	�[��� �Q�/�i]��2'���nM8W��_`������z8l��Q���_m8�������������e �����'���b��R������q�����]^��T��(��|p���$E��	S�=�#�"Z����3_t����R�(��<����Y�0�&��0�c��
�%�smf<�;ނ�]�ʵ,���eʣg�|��:Z�C�wW��h�6��d)�2Utߟ�@�t֕0*�;g�?���WM|O�`P����p_�w�Àn	��?�q<v�E��r�2E�b�؄��~��
��x�l�
��̣x���?n�a�PI���4�}�p"4 
�$��H�]�n��@6��?遚�Wۡ>�f��Ɋ�B�W����s-��   ���[�� �����o�ձ�g�    YZ