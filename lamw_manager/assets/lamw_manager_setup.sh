#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1545253322"
MD5="e2a9a1bf2854d0cbc2c8c76c43aba6b4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23092"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sat Jul 31 16:54:52 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����Y�] �}��1Dd]����P�t�D�`�'����=�p�!Ω��r��dD��<Ow�b�N��n�۞^lKL��&�9���!���|uݻ�Z�C9ڭ�[�'N���o$Cu�Z�%���1Q�`~������i�B��1�o8��3a�Ҩ�>4%ɯ�:��d�T`��K����A�Ӫ߶���o!��L9��[�_�E6��謨�+�W9y����7@��z[>�-�J�6}bݶ��Py'T}�,�&[��]:<_ʮE�5�7_�4Mϻ@
����2$�#�V�獩|�$�(�C�H�S��D����y�5�k��eP��Rܬ�{X�t-or��+8��_�p�!|��rq}���u�����~�_� ��ᬾs�AK�9���-K�05B�.�[��݊��GC;k���I;��b�@����/w}���p=����OCAi��� 4�%oL�a���ؼ@d,��C�ش�U8�>.��&i���d!?���4��fA?��Pk:zo"����J�W^�u�{���Z�f�a�J4�Ў�k�2ǚ�hM��҂P�aFI������k���ZB7�A4��}A��-5�q��zgЅY�"3�OR!�߂X�ezy��=F'�C��1G��+z��5�d����X�m l������w� `�����E����T/�&�����8�f=&~��U[��O���Z�֕x3��[CZ��
|J�����;�T/?q߀8�7��s��{;��K$r�6�XͿq�M,���|���n���W�����~'y	��)k����r�{O�k�r�J�"rP豃�� uzRux,_?��,�>����H�o�~���FE�?Q����
_�ҶvȺ�.����X��;��0W�����$E6�l�i�*aiI���l�;���S�t2��dS�'Z��1�������02�4U��,'oN�ݚ��ǁ�5PcX�D��B7�\&��_dG��D �w�X�E"�MP֯R��P�ᴵT�)��k�������hi��U7� �7���.!�b�"��$U��j�!������t؆���tҚ��)'bM��F�ڐW����Ɇk��2��d� ��ZL��m����m.O��sh�$�������X�Ed�N�n�xN;�DEv!�����י��ח�h�m"��RV��H���<�2]���Ql^vC�i?�nҌ�����D��c�w�tM3�q:��~���C���B��%�X�҃:Au!�ia]g�}g�gu��UC�MCO�<�d�>�&��E��Do�m�f��c�l���}$�7�_�%��3��y`���aF���<��E�ɲq��j�y�a���w�Y������܇"ƺځ�U���p�ћ��OpJ�[�I9&�C�Ͱ��f���c�	�$"��v��ǴX��I'���R�����Cj����&H|��<3������	R�6�VQ�V`f|�K��,|k�,��n����{�����7���.�ϬvM.�P�2�U[���chM��*6^��g�J�q��٠L���� �G�J�( Y�%\T�[v-��SpCj���H��!�=�֗�5� � q*9UD���S�z�~X���㢦%-����4��q���R2ֈ���p�7v�Q�0���Im_�p�q.�q�s��U��(����T$D0��ׯ� ��+�w=M�,����k��4s3hy��)��S�5�s����|%X�m!�Ӭ��A��#���%y��tLT�e��� 6`���v�]zE(*��~�ۇp�֭b������q0.��gD�C>< �z�,)�W�ȗ�[�_�B%O��
��E�&C��?&s�.�h���j&s��a��"�u��¹c/�')&���%3�)�2Q�v*���mF�Z�c�Y�W������z|�
��"������?�/��*۷L��� �T����&muֽ��Rd�Z�L�⍑w��*w����˦,�#f�_�޷-�;���C٠�d ݤ+�ߢ�DGo��j��d��k0�`_�~��R��BJ��+h<_�Ԙ�7_�ݗSR����!Ë,���u�C
����b��]�)a�.�Gwv}���f��u| 8P>x΄!�{Ϝ����I��{�=�Wa�xʞ�V:#�٩���R7\Fd��"�p�vf���pW�pp3�,��D1��KJ6�D�=[�&��kF$u��aەsk\��٥�7�^�cb�q��''�y��x��O���ଭ2�B����?�fY]���6�nװ��K���jB���T�Q�O�z@H�11]��/�K����$	kj8��]��Y��� 1�2�P4=E��cҰv���`Υs��o7�х$5�8$9\v`l�|�r��ۉm#�}|a��T���4�$�0)k�d{I���Azx�I[ 
��M��~�\8 �5nN��r��Ш��;Û!�B�_�����f��q�� Ӹ�ǔ�/��Im��z�}E(p�"��\q���Ԛ����/�s������j��dX�T���.Sk�r���y����(o�A��ۍ�Z�޽�Wq�o�� J�����f���LWRW���G/l4S��V�����{,�|��p���BtK{��@2�٤��$�/;<"mݬ��;�	�G�Uy�O̥j����W]D/'*���<=�m8�X(�
���?��_l��6����+�� ࢀ����ݳ��LAJK����@����S�f��K+#��E \i�K��.��a$�C��%I�m Կ��U�܊0��j6��z̓9ߘ�~��u�K��('W��"����N�e.�Fn���>p�e�����b6i�r�Q���FRj�{Ӟ�8�0p�g ��j/9�9~�,�ŉ��t���V�P�s�m�j�I��|f��?�(�prkX�~.��?��ӕ�����sq&�$�d�y� ��y�kB]���2]� hiι���ä�9*����H�~|ͼq����[���]����x��¶���I+w[k$o4םo%���x��,h��gL�4 �_�t]:�f���</G�2�S�-Λ8�e=��t��T�Ran�g�p�D�����_��I��{���i�H��:DK�a^
m������;Qc��Tjg�9¢��Yf�z"��~\�o��
rc)���w����N���R��_�b,���������dD���`���!i�l��Xw��6Wp�g��D�ݭ(�U /�����A5�A�,'��x���g�ۏ:�jm��&@��Oy�wj�jp����ҩ�[Ox�����^s���M���[���_<�,��MH�a�(5q.�t	�
��#q�����A-��`T��z&:l�胡�xǽ�y@CGI����NV*�����|�\���u��a����" �RS�E]!ҋ߹�y�d$��C!]0-��$��Ĵg@�D~�8*<�����f>�I����l�h��p�D&ɒ'ߣf�'
[nH����-/K��5�ycx�i��}�b�\nv���)�;B��8�dQ���p�'��h�Cn2���ˤf]�/<�GQ7e�3����؜��BZ�h��������z�ĝ��`vGf�7�ؔ?�̮d�`¬�(��V�~�<4�~�&-�k�g��/ں��w|r֗g>\gtCפ�譁��y��D<�>��!}����U�w�v877-"<,�V$�P��I$���k����R"���׆)#i;�ûO�-�I^����V(� �/�!t��6������w�>���Q�V�u��AX�5;+�������X����@����#���Ct���x�,����A�*r�&�?����q)������J/g��;�H�i�G�~�<�>O%{�� Ֆ���do���*�#-��I����.���(#��>��2�ף��ѡ����;�=�_`p����f!s�4v�7?>qB[�<�&�N���3�G���7�1�J��@��|�����#�k�;������m_y���d|L��J�n!�Ř2{vUҗBY��g�8�<��AE^��R*|��� �[��Q���R�Mf�O��O0-��Q�0����LB��32��9]f��9T`X��t��o���� J��ehv�h�54kQ�m��A�TE�I	ī�%-'���l�)�Q��F��I8-�1٘ۥ�����z��o���53Y/��l_�������eOgY�.H=�� �5�����9�GV=�~k���s�`�����?0�g:�ư7���"��U@X�o�	��RL#����~&V�}��+}V�B���r�K�g���*�c`;�i��~����� �Kk���s�)�{�/z�Й�C��*�G�C�+xs�)�&�cp9�Ή������^u�����.7�r��6���Gg(�����vɸ*�� J+]���$ě��@}�|q_1�gSB4L�?����P�ə���*>3�T%|7Ю/�?;P�t��V����I��nB{hus! �1x���g|��7��fFI��̄9)[�7�*�y^Ȕ��1눂Ԥe�۴=8W�
������%�5Wp)���|�2;e���
F�lyA��ŧڣ�N{���o��|\˝fN�G=_�ӥL7�� �.�d�רYzib�����3��WT�_`���ꣅ�Na�V�5b]���b{W�<���r�S�4��kI#u��l�h`�+�L`��;|{
�%��L3��i%0�lshHա��y"^�*i8���#������L��jF<�S�'�D���.�U�*=lk�!��
xzS0[| d���ϐɔ��������	W@I���G����V��+��%���F�mPh{<��L�;�Z��gU,}3�=&���5"-��r6|0~Qȑ'!�u�;E>a�vȒͯ7���N�ʔ��a-��Z��~��Ⱥc򩅁��A��@���ɏ��W�U,D���ҍmpH��je��O�WRg���G'�0d�����_Oq��g�w�����R���N��F�	�F[#:X_k���u;�����{o��i���st���A����]0Fc[2DzQ�W,%JȆ7B�cl�zܲy��]e��L4��{P���g��)h/�����X��5�X}g�
Bv�Y�F��W�B,O�pD�c�K�ع����T<��K&�"i�K��CbuX�!���3ON=�
m�M����!��
�ĝ�:�o�K�_��l�5"gQ(���$�Q��H��2�!O
��2�1��X:��J� ��U|z0����j���fEo��Яf�ʐ �4(�H�>�.�pN`r�=Gzx�[�ڊ�h�ȿ�r���(�5�ߊ;E�`�>㫻�
ߟH�js�S7X�.����-������H��W ��ٱ�{x�aboZ'�C2@���[���F%��l����/&�����/��/�Q
�9
�g� �[�����7�U�c[tbFjmK�|��7r됒9e�]�F���0v�V���s� io%����z&�l�޸@i1?�i�=h�TcW�")`�c�����G���(��1�����`��XF��Ig�]�dFN�Ё1�)�׵�.�O�ݦ.���4K�}�f�L���n:+�i8��/L/Iؒޟ@�q��='����e�g�
�1�F�\9�T�PaU-����=����2cu�o1��0�A�����?wڱ`�;i�^�v��^rO���a�D�k��LK��v�|vU��o���
/)g��?�6l�^=����V�|�;�vE��b�ٱěVK��	�����&�8�ؗ@�/C���f��1�� ��g���b��85��;�)�o�l�R��l�f����1-�]��a��Y��PSM%?
�L��0Q2ᐕm�=�Æ���,�����5�F5�1`��B���)��x,�{S~��T����A�|�Ӛ�"���CB�L�T�� �v<�Y2�a`IGla�*`Ũ���9k?^��VS�]!zu 	MJ)<ѧu����$o+�3&\��R�ؕ�Jȣ��4L���m^T@izj:���e�����-j#��S<��or˵�tP	����0�L�3�0����::{$膐x{)�gz����<��2N���;7j��4Q��4�����X�b2�w�k ��]�>|g+��pM����*Ubr���%��H2��*o�{f{��C ������)\u�Ʒʲ�������T�(�37?�B�S�;D�ɳ/�r}n��YJ�T�xT��.2�>�п԰�|�\ԅ��X���<��/��ОO/RV�T�SW��'���{�h wߔ�J��(<�=)�Ͷ������3�c8(&h�"�WO������h4�4f�U��aH
��T�ꆿ.��퍼fq�s�xn�9'$?���X��:���1�4�c΋<8����-{������I�#5���g��	g`���贾����=:�'^�rQ�3��v��w?!�^#�9s�םZ=���Hؐb@�,�%�iMҺ���^Y)C�`L4AjO̼Ø1{s
��,g�*���R���Q)�V+T��%��f�xkBN�l�U�YYKSg)�()@坶�H���� ��
��9y_�h�7!/B��y�L�+��cFp�̛���eY7�N��>��\$�ګ�>XR�;U��-O�SHɜF�fy����n���~J�K��]]�Uq[�H����\�>�0(�HE+��n���g@�5��--�9�7���;�/�p�=���qR��%�q��m��Xl�Ae{�Ҋ��]2b6M{+ܹ|�ۈ����yB��OiUh�8�����9糍���/AB4�y�%8ZB�0��H�0`�	�T�vv�����8e�L'��0�O0N'�㑠��K�gz��%���N�|ޒ�O�ZV������������G�)�SQ�Aaa�z�b��<���n����W:=�|���jm{l�%>IvF�t��G(i%�
�SPd��	���0�cwÐ�#,���b0���>vL6h�	3^���(�bʙ��f�B)��OS�o��:�sEe�D�6�A�?kp~�*;�%<����vwET���'=��OH�ȕ|&v0��yyk�>������hj�^p����#��h�*��G��C�y(�Sqcas᜗U��cY����⩶���?�r�st^��������w��i�ۑ�V����﵅?Y���m\&�q��k<��ǨF�]�7`�'���)�ޫ��8F���j^j~�~�cf�+1�]�8	��T��0��gAx5a���7j͉EH�����?������g��G��C_��bX�|J���^������pq\�w�-ȥ�ծ't1w?�+������;?wMB�[C "���b�d7�H)}�7M�.[��9G���\��r~?�h�_���}�ar��R�����l��U8��8:��@��y,���ᅩ�*c�$O��?�j����P�v��ݠ��dL���?�ŢCR[\���;XN�2���j��Q�hv'��J��!�b�.L��&s����_��O*����,/`4Z�˖﷬<tWy�%�]������H��2g�"A�kF�#�I��9؇�KR�y&��Ł'�Jz����a����+�P�`�Y�E|
�=�[�'�lI5{'��y����mg��T����Z%F���G̜�� ���)£�2_���QURo�D�q�ޓ����>{�P5�M��9_|W�J0��d�MܒT���W�L���I��fʋ�4 !��q�e�sK)*�ps{�Y��qǢ���_�� �Dt|>�����A(	����sjc�h*n�'WZ:�g���2�k}n+�ƒ����<�6���4�J$8������?A�����,[�a��*���k�-P����q1cXU}1��^���{/��X<�FE�(��<�������K���C�@��(2ȥ�r�ZY"�(-f���~Ƃ�.�/̰	���V�.`�KAnnF���i�kuoh=�_���b��I�Ǧ�Mʇl�H�,V\&!?�"@'��	e�u�X�����}������S��+�L��b�P׾���i^;b��/� q�h�)I���7��POO����fhGJ*C����Y��¨<KX��k��l�Ժu���{`ɴY�	�M���B�V�`��l����Zg�1����u�շ�g˕����q��G�1��Mr@kf�	���~�4��b���h�vV:�P���j:��3�Pi��w�u,z{����R���g3@QŞj��A��|o��Ӆi�B�xYPeK���<��53�0���`���ΟPN���B�ӶH:E5u�
�������@��Z�������?�:��Ya��}{g?9t�_Oןw��R�8�X"�3����{P"���Յ�kp��7�|~_�����d��"[{�AJv՗�S�;nԎ��P�cꃌ��Y/#��
BW�"�@�̷4�,j����9\`�~벰�MT�ݣ�&��:dE�pRlV|i���af#*�}�{�'�]W����yνuڷ������Ҍ׭�V\-?I�^�䓳E��kd��=��$'5�兂mH����k�<)�ɣ��v�Oyn��BΨ7�x��sfs9g�X�tl����Ң���;*��ؿ �=2��9�rKa?�q�p(�
�$��v��)t�Š���S���)��xuu� ��J��¿1� CQ=��uҐH�����K6�ԛϊ8��t]n��G�u�o~�.�|��^@W��1�.}�)��,'�����^״�x1E������ݕ� ����k�4�v��2���xҚ�p���r��D��Sb�B��6	�$�r���ؚ��a�'���J}<f!�<��v嚩U�)ғ�i���ɡꋌN��dg
%*P�T��A]L�$F�p~5���f�����p��qkk6e����R�H�ڣv�|�,����\k"�)�o���s_�ȱ��
� �� ����^o���5�{ +�N0L���%�t�8��K�&P���  ����;׈��Qb��1����� 8
��.#�ӛ���z�y�N��JK�����E�̫��MR@��e�CF����r���"ҒfK�(��
�j�vP2���m���"B��7: v�V��V��L�����0��f�+�D�*�h��鴃nxn��� =M��8�$�+6��V��`)�
Z˃b��a��@ߩ�W�-�ԍˤʸ�q��h��5@�B��u�h���Ƨ���H=��'����ǅ�4�Ƅ,uW:���D�Qh�����Њ��|kLD:�KWUcs�N����
a��`�	C���S�䘂���@�U�z ���@y�D�9�����Z�C�+���:�k�8����t�)Qjb�7�+�/-1���d4z'��&�$>q�͏��k�~��!��[��)/?�8�p�ǣ��*�W'�$a�^�v����6XA�,�[�l!�Y�m���1=��__�� �$�[�bf�r����.H[	�����Oz�W1W�H�+?�Fd��� ��z��:����8��B%�Q�|w��z�P_�Dس�����#T*k�T��#��m�U��s�,�k�-����f�����Uj������	QR�NL��9M,����G����f_"��i�'�������$��Ν3�S���GèVݎ\\�u"�;�=b����%��id��r}Yc�Y�{?]
d��?u�G}7�L�*Y���p�%P-����)izo�x�����L�C8��,���sS1�{5�?�I7�2*�j��Z}ѮweQ���B��!W�ĭ�fAm����]�晻GZE�PW��a����S�1$�өHtx�8�名�D늭
<LR1�[l�H{��-[�41�(q4�v�뭣�o���(�%�l���=,IgÏt٪fG��puz=*��RA/Y}҄wTv��樕D����ģ�9� �-~��*��\3�u��y���ֱ��_�s>�%a
��sD��S�qS���d\� �=��cEO�{��럖?��K�5��u�TR���dJ�=dL��&�R(��0�-��ť�6���m��ܨ�����4a�^Msd�l�
�JP-.��m�Aw*d�c�}5�Ұ�?t�YE�x�K��c���Q��O��ڏYˡ� �Iӫ�a�k#�ܙ�hX��)��yv�	%g���[H�����nk��R#�`��[�)��⿨�)A��!�*T3�����>r��D����
����>��w9��U��'2g�Xf��uNg	4v�8NF�X�̐mb���$�<27�bs�99����5��a��?�Ҩ�h���h�|�3Kɛsmsc����f�tk�  �a`�DMGy��Ь��JQ��{]\B˫����Y���n���b,� 5|�22@��k�ݸmHO��۳3e�ꒇֱ	D���T��p4󕉅� �<F�*q��ŀ5�%���P�y�S�s��0PJ�{K5K�҆O
S;␧DW.���_��e�M6��"F������؝]� J��w���m������O"d��!hA�����z�.{Rum�
O	�����(c��2��$��������J/	��y�.������GYE�lW~3窤>ˮF���qʹ�z6�x�4�A]C9�T?7��H��b)4xx��_��,$��G?�{��hy�9�rJ��&��:�"����3\,TΊ���&ӟXƵ�\?W�G��h�[��<�;{�DO�J���7ic�dM��!qEu%2�U��dA�i���-����"D�"��p�!�����ҍ@�M�ї�S?!�z�_�l�8� 9N���Y�d�ar݆Q-q{՚_}��q�z�\��(yQ�d�yS��V���q`@Ђ�d����AV|-O�_]�;J���6 �@7��X@�٧;&o�Kc���(\"��(�N�K�95ځ�3=�(cw}�����������T 35n�O{5�/���X�'�8N'_���5Jո@O���C��������C=�6"&B���x�d��n��ºQ�~o�oh��Ce[EL�K�*M�a*>���m����W�$�9�|�����%x?���Ŕ=�6g }C��Oc�E-�r�F���J�j�u
�SZ�@�4<��8?[�],��&*�+��-!e�>��J {x������0i�|�U�L�E)b>��>�ڇ׈�7�5�r��B7�`������q;��d�.`��IG}��s��a��a�<r��pܲm;snE��3ebY���8�E��)*M��[08cZ0��4��#��˟��"j+.E@r�#��|�j��s��5yS�4�^t�j�-+ً��^�] ]_ ���@��Y�6������7�VCT��A����G頳P�D+���N�N�4h�/����X`aFT<�����և5 ��%�S[�U�����u���Iצ�}\Xj��آ��3�7JJ��8��}$�Ĩ�'OƀU��X�[@����Mb���Z��I{�B6+�=�5�$}�ySҰ0=V��[ZG��u��M4b@Y��[5�p�,�҄�'��n�=����ҋG$�=�Os�^�`��*�w����kC��r��d|�G6����p��88u�	y�=
�s�Z;�8�Y�Hٵ���KW����!6r�tɪ=� �*����� ��zN�=i��۝�`�{�ns�������=v���X����D)'O$%���r�jD��ˮ�u�yY���*e�r7)b�]ѓ�q�~��	CE�46�U���D�-n�U�v���[Đ<l�I��zef(hY��L2;�='�07檲�M8���hU>[Q��E���}a�xQ��R6�,Z^[|}��}�����H���4���@����q%Z��5~[S�5��}ٚؠI��鍊({�Q�ۄ�O&�D�,Qh��!O�����y�t-������,�K:
��j
���qо"y9ii��'%ޣR2I�v��q#����.ͪ���� S�8VU$&���0^���a�r]s�Ц+�����JCè�v@"׷�Q莃ҷ�l��(�}l>,g ����bU��Z(tzZ��.��_�z�"�o���Bu��e)͐����.-!�q�e�z��&�%�~��˓J��7�{ �'@�����H7��� )�é��r��/����
� ���ě[]��BWR�4^�8�هZCfz���72�_dI��RS�.¼��*(;�Q���N�($�,��J��|��`�3��q�(EV~4��x]ɘa"�X�X�5dl;^�J.a��Ů��z�g˾��D��)v����˯/[�I�&v�j��5��`�/�>\��$p��%֎LOc]MD�ع�������ط��Ҩ-=� 	�yQL�����2/A6�`i>!�4��8jV�G���#(�j(�B&�@2����	��4���Xb4�'9��p���ר�>���[]`' e�5�N�*-˗�'.�%'�W�I�����ᵚ�Z��&��U��Z鶫���cq��E�VF�{떩ި��'K�v�M$�����F�գ�5���mF҄�CW]6}��dR�w�7��)�"�mȥ���Zt[�$l�,�dѿ
}������z	}9�T@j�;6��BX�I�5���!"'ꙃ��~�C/H���r0��I&�}f���^g�$ј��h��9��Qi\2␪�F�R��*�Pv�e}*�V���ԋKt��5�Wb1�<�K���V��j�h�+���mا=��Ck��]�NVs�߮�����r�\V�-�/�U�Y	����/�a_��I��`n�	Y��Öd�;��L`V�"-z��a��*X	�.��0v�bY��xSw	A+Bf?�[�ԯ����0�u�ķ���6AJ�aJ�5ϣ)l��3)pv{,S��6��-nzO���H�Ǫpz��\QY��<�����I�M��(/A#zy	��]l�*ҖPd٠���P�a����>���H��gqͺ\�:I�� `Ƴ��s��A�J+N�ԟ7N&L�r��0���/�O�G	y߆#+����j��6]�fe�"��bol�e��5�v����yj�s.A�����[5'�����H������t�`�������%�$蕭Y�Y�i|�Ɖy��nZ9�kl��7����ɱ1*=��Ed[�~��&�	��<:M�hM�� m�j�ˈۻ2îܖ(��G޷r3�H��~;��-�Z��`O}E�(��r=�w%+n)[E#l����UhJ�(GiYU:����#-��9/I�58�Y�%; ����k��g���lm�1��h��K7�s�Z���ph#���d5z� �����ON_� ���\�����z�@ת;ś�#-����"���1|iJvEu.����u	k���y��WB�L��*�������Zz� ��/���7W�D�~	`�3~|��)NEC�h�0&�m�L߯f�
�P';ҧA�L��(G�<H���L����j%�]�ӣ=3�CL�,brS`��U�/�#uQ������!&Tk/�%�O�r�2V7�S��N'�d?!`�M�/�˃�<@� U�xx�F�P+�o��i�[�(�{T������g�*��n Z�[r?	��$8=mE�uT��aS%�/�*��^H[ߕ�f�[��>��M`4b5U���M�5�=I)}�*Uz�[�K���Z-Y�t���ӶӾ/��j�{�1�r���To�k��� �Һ{\��C~l���}0I�#0�<+��>=P*�G63��6$��W����O9Ӻ#�|�M#��j�f6̉�=�-i�]���1��V��	��Pj��LM~R!�l���Z���A7�L�n����� ��f�4���4���8"��*qp�pr�����zƔ y����(p�$q��1R�3Aà�D���$������yᢽ�Ȃ��~�!^O�F�K���w�`�Y�����uO;�*����(�!M"�_;�v�*��l���
�L2���o�>�g6�W����/�QGG�a ��E�E���J7,�En(�>6k��޺��&5E� ��A��{��f�X
�+�$K�����v:�__=T�ha�I�#� |`�~D##��GD���c�	 p�_�Ց�O5z��_�}A�>���R���
�V���h3�D��g��W���F�)S�9XF�2r��5��|�,ݨ��B�ץ�P���?��=2Lw���4kW�f$����s?���Gw�����ȑv0��&j��[�`�p��:0�b)��%vd��<ӇBցI@�����l�LgSe~s �վ�dTt����_A4�ċ��Ϊ�|��d����XE_�z�.�U�
G�2��V���Y'��>�9�!�șfY;��7�����ZX+��� 	HY1��h��N�t�(ԥE#/xݑx0^�,�r�(Q��3�%l'4nS-ۄ��}���-�`�B���:�n0����k�U��R�߲���L�OB<��:
S/@�� ���u����/�L�=�s�t�!ǫ��*�E4cTI��^2glv��K��P���^ă���w�lS��aa<V��|ўYQ�p���n���m��ܤ��q�CYhF�q5F'h�ݻ� �ϡ�A�%�['_o���w	����	��C��a�gʆI)�!�5��D��Vj������{[M�$��ʨ����T�	i7��;W�B�[ݾ4�~/�K�9���eћ�ºr�>����~O����)ւ8�!�]�n��2⏩g�e��j=C�i�%Ⱥ#�*����M��,ԫ�EKAqAyɲ�U�/�64�WhI�G�0a�WuUl�J�	7����|oL���� �b(�N^�f��]�%��%FB��G3ܒ۴��L� ~�d��-����m/׶@2'����e��`�e��*CO4}�'��!�
V�#�����OM��n�a
����$��a�/7֌�C׷�X��ǡ��������ߐ_��f8��S�*R�f(V�����R����t��`������͞��jO����ڇ��I-w����?�.l��;�֭�<c�����7&E���h<��ٯ��Q���KQ�Q~���l�����g�+P���٩�$��_u���W:s���J������6_iRf[,~<w沊Q��smx[$�$��n��ܚo^��Ԯ��O��v��Grk;�{x�5mpގ�5�����5�SGoT�}�R����[������7��n�(�􌘏xd;��p�'�F��30�.��1yp`�CMI�^V�-�jR�i� �מ:�#t��I����ψ\n��NT�kչ-Q�Q{�:�(��t%�7�t"	�-4���n��S�5΍Zh��K���q�L���-�#g����R/j�P�Io��Q��JG�E���;q��F�ƣ$�B�'"R������
�RC׿�~�h������
~w-�e��7��z�[.���\�9�/��D���71�9b�A�:�m%����ɩsG���2J/5(m/����� ����,�󂁈J��+,aPv�}�3]��U�����s;c�T���F^U�n`FU*I�e^� �t(��&= �����˄I#��C1S�U� 2�T�U�\h���
�"���28��Z���j�Rr��LMD�(X�B>�(��
����Ǉe͉�y�:���xv�a�Vw��.Z�Y�&|�s%b�tӑv�4^^�9��������j��y`&�R���O�ݵoDX��>!*d�S<�������2I�@o:�D�{!��"Y}�us�睄��dp������:���ٓRј��7�L+�d��f�R���B{�Q�<�lÓ}�I$C�48˥:���
Z'�:���|����5��\�]���6�%����Ф��hwb�%x�� .zҟ��m�Q��s_�B���s(�����/��ӑ}�d���	��i"���>�-%����Z�̖�.T�$C��6�:m>����"V���J�x$�*�
'�|B*W��E����d4� ��T�?���o9y񻘛�j8CDY7�*�Y7ch�3��?�KA���1'�WT�eI�U���w�_�68HC]^w�Qj��w�O��wʣ�R�*-�kb7�I�O78�����+�q�>e5�1td�!��;���	l���d��lܟFC�k���8�jåE� ��3�-}B�w�������xY�����2��	�wtχ����{��R?��G ��x�ER�P6,��7�W�ӿ�����X5�嫐��֪tV���2�Ah����<�'���V����t���[�����\^!k�+���$���bx�)����� �*e���B�.vu�8�Rvr;G��8[ g��c�X*P
�����[�nS�u��g���I(��R��b�nW=��q���t����o��Q���zjs�u��r�۶�cڇuʡ�
��.���}s����Ε�3̰H��IH.��;��s��Mڝd��p=_ϐ���J� ��=���R��v�����"�!3�~	Ёu�r7�+>�L�V�����s����
��t:�s�����7��U�P$�����6I�Z�AN��5��{n+gZ��6��)ǭY�q�X���AVՕ�Lb�åR��C%l���H��-G<��&BG���nƫ �k�*<J�£�3UL�Ñ������{�I��=kn�gTB߭"�[/4hSt��(����N5A�V��_�*�R����Wy~��<.t�C�7x|=M`�E���,[�Գ�y�2���q[%ް���ȃ����Vise��!o�:�gh ����`S$.io9�;׆k�VM�Bp3J��g����N�SW�pk�òz�6^��#N�C$���b�܊7�9����]�sX�zy�5�*� �4��#_�q���ņ��_GoOBRn`��;}#ڋ����:5��mH����[Ō�(��C8̉��
KxZ��tL]��2qg^��k�^2O���p��!>͑a�r�O% ���NvG��95ԏ�V�ކ�ż���V�޻�Z���ۧi������!�`f(����.�e(��7�d3� F[�[K�M�2�(qF8��J�6�/�a�����H\�9HK�O��z��-��Y2���oG��3��7��WJ(�}�n+?����ki%	�&���d�]i)%�e9j�K�8�A�x���<y)]ۋIN���2v�&k����{��򷽁�Xm�Z\������~�[�gj����V�4����_5O(��n������~�L`0�<�1�_�u_(��t�b�vh�3��+B�o���F�k?Z��o�I�!�'?��f��A���B<���;ƴ�gOcq�����2�V��b�wiz����,��C#`� �`ϣ"଒Z�πY:��̰��������^�H����\�����`/�a�Wz�
����K�j��^ؘ�XH�L�� �wSy]Wo6�(1#��b4�,�3��jt)�׏�P��!M�pn9
�kq��.�ߋj���!�˻
�N�ܴ����[��ϸ�0$�>Q�^~�p��K�?XzT����RM��q�t;�g�+�@S�SB	�Gm���&M㚲�湢��4}\{�a�mJ�P\g��pJF�!��o�d�[.������p�U��+�o�^0����b7~<�Jj-�Fѣ���-�q�wj��o��s�>��:ͺޗ\� �1�oo�ٖ��k�Y�<��zDY����:*p�j�y�5B����{M�el*�|N��o )��@^P��9�@��*��S&
5##��C^��ы4��}��2O�t�bFE��<Ϡ�a�|\���/e�]����9�r.�ɭ(Z�v���Af�/I}^o4�M�*mecX��3��(횉`w'V0RQ��ʔ�T�a�.'=Mԏ��N|T�6���wU�����0f� ��R ���"tML:�Q�g�Ł�Q��9}����N�f��Ͷ���3l'�[��L��T!b Pg+Q�����i�}� �[����'��IKC��]�Dķ;�rh*��t"*�^\+/m�_��Pb��	8�S�h�D����:c�s�[B�2�+�(�=���#Ū��lg�,�W�;A�:zI�z���ؠ���U�M�L E�{sUR�٭q��}	��΍�A ��6&�1�Pp\�h��q�Nn�E��%PX�)��2�s�FԷ�����3T�f�8ȴ&F�S�A�fV�	�c�H�W���j�a�;O��m��������0N|������$s�CI��ѯ�L8��1frU�L�³��;���Z�{iu�s�^;w��W����5C6"�i�N� ͸OwC�]����S��!b��>�y.7/�dä�WiO�����!5xq`�zxy�tT&B4˷H˵ hI��ߋ00$�2�ȍ7P�<�=ڄ���B�5�fF�B�������)[bk��ٹʚ���hU2G�dw61�'�y��-��F��6.o㡞�,%�Hg�F�~7�����DR,�J�{�4
�Fܫ�'����7�6Ӡ��T��l =)B��/Q~c6�x{}���b�0��C���c8�pH�7���o��M��oPґ"�XE����R|�[<I�mI�f�R�ް����qU��)9�$����%���҅���t)�j�=�������@N�%�ryk�8��a� ���bs13�z�uڒƯɳ�uU�{�&`�M��q��F�B�m,R�JRKa�z���b]�.�L �p�!�]8N1�ߓ��]�e�Lݪ�s)���E%��9�
@�w�R��Y1t���ϗўY��t��|!tB������U弛��?�p��k�P(S��e��!����"��W+����?y�L��o���E更��_gh��]_m�!N\� ��տSQ˅��k������<NY/�%\�4�j	���xl�o���O1�I�-�4D�tm�Jz��06Yui�	Z��ݪ�E���<��9�`�B�lS�˩(=f{X��K7��@�ƹ5/�|����ʙ�����C�<���9���*��,)�h�C��ӿ�ßq��n��Iz�
N�=D5A�o\�>�1�n�p"ΰ���>U {�k+Śy&ƧӒ��=u^X���\'!X�l�Q�������	�9���\�a���ǀ�p:��O+�����>�����4ܭSm�G��j�*�!��|,����.��fLm[O:�A�Jm1�%�~� {�ʴ�	 v1nSTM���	�YM�^�Y�x�|����Z3� tU;�N��G`����DH$�����I�Ó�6�/���FT���>p�Z���|WWe:���D�*�qqA}22BL�˃幻�7�R���{v�C�>2|�(�٦i�R�ڸ2� V��@Q��.���zB�<���ޒ�m"na*�YW)�K�0�-ƚj����F�OH�#yߪYZ�{��'�ݞv�E㻄�]Y�Na4-tc�����W�t^��+~��+�����0]Q������S3F�#�1��n��D��Ao�����n��f�F�0Mr}�9��t����^� �f�Y�r��.;���XAA��E]���>�6�����B�	@Y8*���R`�^4����^�����ee��k<�w����\��=��@p^�?)���
��a&'�ŰL
�Rs�!��/ǽ3�೾�kRc�c�:��q����/ڬK�ŀ4�lq��6l|)"'ߡ�QV�%5y���D���.�U#i}h��5��A��\�X+��)HQ���P�z��J1���\Xuv:��M�9�B�f�~�3�/1��D���3��'WN���a{[Ѕܝ��$k��GT(���e�_[�#��,���k�Ru[�Z��XF�(���I�l{�k��,�2�;�{ƿ:�ɕ��vo)��|3E���(��u�U��MPI� �+��!&��;���R&���)�t7B���`Р;�?���1J�ޕ��S=����!;�-13�Sf`���E��<��CnJ*�~JXn�W3Q��f36���m�e�H� �&a�	!���V�] H��@k���߻�\c�g�H嬋/�-77ڷ,�$a���v��;�R�T�����^�T�4�חhJ#�Y����rp�P�9%#�&Fq5g-�0˽o���έ������v:���H����#�����!Z�#,Z ��łhx6wR�HC��Tc�O��Sl�V4�������Tg���,S��T�s�����\r����%sY�Px�p6G?�D����)����/�0C`�����4o�.Dt��<s�pT��&#�G���wZ� 촔����TT�:�H`�[�B�F������83����Wկޚo�wa@iN��@�p=��R�ҿ�N"�K��-T5Y|]��Z{�A����G?T9i�}#���̮�OP��`�B���4�9~�AG�_�8��X"��y�Y��{n�k$��9����h��,�%w�d���W��qa�Y���t�q��2���j�-4:���G��Uij�ҙp/�hF��J��Ӵ����>
a:�6N��%c�K��b�(�����2��?������N��������S�~#��H�W��H�;����Ǉ�D|�������jMĀ|������m�%{,T���&N�tŏy�����h��N��KA�p��n>��)��!@�Qo��^(�Kq�k�N�H����"��Y��dN�x�x!�=�^0�#?` �<�2��?)�n`E��uD�J48���L�Aosr��"=��S�_��RIt��3/L aFB�Z��l<�O�cgK�.�L�]��j�ˁ0k�?`�V�e��	�L�-G�ʮ!��u��qp�0��X�f�h��^�����d]@�A�r��}w�Vt��7Ha86���4�����y]J��Z�T�]����(�3����t9��|����:�@�M������#xvG�.�yC�O��uS�b=Ф �P�)�����kJ��p�G�1�ǁ�]���S��'��lˊ*5OAͧ#�8J4�mt=a���`Z�dIR��y� ���=�vK׫S�fG������on�n ܿ���z� �s��}&�'ݶ^�Z�>%��b�Dao�#���:x�w����	�(2c�"t�<}l{����P��y&55�Z�h0��*àN�m˪�eq�;�a���'��|���2��yp���F5��*<���˫q�'�g��G��Dw��F*��~7�ɗsb�x^^s��������-��_̿B��k�- ��	,�4��7�n�説���G��(�=��-1L:`p�`�_�z�[��l��7�c��}��j�J��W"��A��E萯l�{�eA猹�)02���"AiĘ \�Y9@g��Rˑ�(t��E�WY��p<�	ij�$��u��>�G�w�$��Ф��o��)���륄*#H�m SʡL���3z�<8NW�E�� �����m��=�~Epb����?v
��۩��u])���k�v'�Hm˻����إ�Q6������y �&����Wxa�"�z%eQ��X�Un� T;F"s�f�F�H<.��l����뒆��ES�&��ToA]��]ޫ�����'T�d���Q����m])����څi��/�����%��^�a�w�֣� ��-Y�!_�YP�Wf���!�e\��h�u6ݟ��L>h�����.��1��rHJ�\��@�r�b����igN$��VL�ԣ{W��MZ&��-t��94��ZU1ݛ�C�2�i*A���k�v�܋`p����9҃��e��T[�^vR.�d�o�/w�s�k]�P�9��5�#�����yTM��W��*ȭ��U�N�8��&�^q��|���l�����1//��m�e�������u�N[���O��vM��QŎ�!�+���hG���D�͖M_����o�i3��#�Z�~bf�0���E ����
���viɹ�f5�&�W�5�b�m����ȉ�c;YZ����Ƥ ޮr9�@�-�:�*\I�d��o�@mL�N ���Eψ��ŵ~�]�cz��9j�0I��̐H�t�">[�>|�~��#�֛(ߚ�hd��]2���B��ɐ�v�&���D��w��Σ��Kӏb}��s���}����;�>�bޱ��A]`&�`� ��a�r}z������͞��#+N]�;:���T4QyC$7V~�!qq�H����7�
6�Z��Q�������w��c��'P��8�^�S,�r�ؼ�Рm���'�ycU >?�������+~+��Э3�}(�y�/�KxHe���ʽ��(D��l�j���Gu��8p���y�D������W��:9�{������T،XA��DMA�E�"/U.�����A�rc�$5��Q� ��=a@Ѿ�
��)�z�
��߇� �x���n릂�L���O�x/fWeh�o�GY�Ok_�2<\��4n��Y!=�O��G;)����|h�����������wٓ:�������cZ�ȼȇ���2*y�J֕��K��P����>"G����am�!z ��N���+p��.r�!� 牴f|��߿q:Mly���C	u�`ݢSD�I�~�]�asVlF�     ��8���%� ����C+���g�    YZ