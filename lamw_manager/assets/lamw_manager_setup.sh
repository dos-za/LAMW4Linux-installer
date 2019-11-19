#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1871386761"
MD5="99f69caaf4b92703d2822d3f3b544dc2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19642"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov 19 17:32:28 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=128
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� \Q�]�<�v�8�y�M�O�tS��鶇=���c[ZINғ��P"$1�mҗx���g��m_�c[�.�vҝ��n�s"(
��t]}��?�<�������F�;�<h>���m��';��������+|B�>!�q�n����_�SW-ݾ�ں�/��O���';�����k>y@�����ߩ3�Qg:[IU�K�R��1ϩ�LC7(YP���E�����wsɣ�e��B�-��vC��}2��ԙS�vm/�.����>iԟԟH���'͆��U�͟����ozBMV��Yi��Ɉ��q$�޹�S�}�:~�s�:�� L��:��uϣ>Y�>�q�!�t@��:[�_����\���}vz�5����p�ɵ�r܀�������ut���,h.����&'���t�����N��L���d0��O��6�2}�?�d��BM�������!�M��׿*��٧�� o��V�ꨵ�Zd�� wΑ*���0��btD����:��}�N>�!�6���\B��@�A��|k�m���V�o��bl�a.�o�I�4���3-�m]��JlO�C�箳 ^!��oo9�U�������X�}	�g����3���2���ځ�2���`�.}7����ҧ���~!�A�U'����ڟ�wiĻ	����]S����=K_2>�C/��O|��.��ߔ~�L��j۰��2��!ǴȵD.����d�f��u�v�_���UoH�m`1	\C2���`�L�VO(o���＃ *d>M��4x��>��e2�F��&T�հ��&ʥ��6
���Q|�t��V�%H+�aީ�$�O.Q���D��:_���Y��e�6�01#<����;��tN�sN:�����V�~�׭�����?���7�|�WI-gي������1�
�.��f@���|�S�H8�*v�3G'������J#)E�"�AI�J*	��jR 6�M�ln
+ɶ�ƈX[7��R	�8Y}�z>rݠ�>�J����ʑ@��2�ɱ2�!����c
��	)'\��J��8�����ƒ�>����,������2��������o{�i!��t����k|��h�BFs6i_�4�����%�в�/I��K�����6�]tǀ�|j)��1:��:��K��)�W��:*@0��ܿ#�ono������������U2y��^��K����qk�ǈ�7�������n�̮�Q�tCb�W��@�E�0�0��Q��#����@&	��Ol�0&�$�0>nF�岠�/�����3�e�b
Ax���Б��!Q�OE�6�e�&���&�;W[?��Z����gd�6P tt+B� :��}�
��j<�n���)*Hi� �ռU�*���rd���;�G�+=f�U���3؜�<����[��0�����(R��G��7��5�?/9�/��7�����_s��XxUf�iԯ��W�����,���o��[������M������ $�]'�!�!D#�i�@��%u����C�b:��5:>JT�j����v�r�5���إ�A:t�Qp>��K�,�y���N���:���?��o��&��Jݞ�X�x�����\�*�ɂ�֮�%5`����laa�a	?����c�t:AH�?��� ��.��9u��4� S+`��zp���NxI�!z"͟�?�2}.%�4S2���F���h
K��8c�N}�S�� ~�ꮿ�&�����>�( �>�6�9�	�L��Ϧ���&�!�U˜�@Ù�{�1�@NZ}�XQ��G�ָ�ɷN��;�'Z��{���2#��b���ν��s뒠����x�?�MA�,e�k�JJ�U. 1��l�넑L!��.���R,�Ch��$�]?w�K=���%��8zΓ��6��3���X���sW��(~n�Y���XQ��_��rW�K����b�1U�6�Fw3��_��t_w��\���
�m���(Yl[Q�\���D#��~jR���Qe�T��.Uy^�T����bY)�� ��3i�y�\!���NO^���Np��sl�@Y�خ7�p9���ծ�ھ�<�ɡ�L"�������Q��������7��t�!aẏ��`�<��o�!+���kt��� ��.����^_�M	6<��d�D@DUǔ�n�)Orj�k�+@B#k�^��<
��X����0�	*�g���h����,v�;K����-T�)��Xb��2k��R<�4X��?�
0iO�H߻Mk5N4Y1��=��`�􋸇�G��X �=�z��E���eo��Lb�����kw�"�P�ˍ��B�E-��Tқq���]�ь�9�a�Z+
6���L/f�<
YI����{ܟ��zs+� �A��i�7=p����>�Z��%�>����ut#�0M��Ȃ�/�D���p�V��2�����狍P��@��9�T� ������竽�R��)ٝ���Clu>����yoM8˨�m�7^z���-@�F�GS9�R)@!��_Z�?�K�O�>$����E�H��\�|�s/��#�?l��7d��a� 	��n0|����JdxK�\�>BJQ{;Ӗ�?�;jN{�q���h��L#9*\$��67�s�Ū��5<�M15���CN����!	}9�H"
��1�v�W��)��P���KJx�l:��7F��Ԯ=�`oj����'�)�Ŝ�:�?~̈́�� L��	V�+�^��m�4����{����������?E�l�������7�H�=�#�<�a�̢����A_�b�*c�R����;:���<�S��skF��N� ǧ�ƿ�'�cM�C6�$��dtm/�c��4��e��3�}ǃNW�{{{�p8�B:�Y���o����<����}J?ĥ�nS��q�7!���x���'ػy�MU�nP,���_C��EiIX����JK�����یuU���0i�e�l|��!� �9�Ӄ�����y������ዧ�b1D���ٺ�)�Q�{�)��S��#�F��{�n�DnEζAd��hJb��1
���k#�Nώj�~Q}f*QwϪ���eZu�3ճ� ��fj��Ɲ$)Vq#�3&Fs���\�5v
�׵ 	�@O-'j������@�"���J���������0������O�>��1~`=�j��Ʌ�[����
BH��TAw�铸J�DŸ��5�Y��QiF��4���ߕ�F�'IE����@��<�\S-���
�PA��{=�QC�1[W9�e9Q�S&9C�LHR���i-� ������.Qq;X����U_�?+b�:�5..�OcP�V�5ұ =�U{�dx�	�߯�Z���@����w�z����g��!��ƙ�	���� �� ci}W�Zv�r�9Y�\�h�������落��wܣ���j�'���!y�G�ᦖe-Gr������CI����X��[�p3^�$g�R�Ja�������u�,�_!pA_�p(�#�����(�=etR'� ���6?�p�����,�{=�Y���K@T����s7$��P���1L=�$Q�\8�oY�~����u]�TC,}��;�UA�aT|��'�x�}%�(��v�B��|*�sd&����Nf���O�������%�LK�� �5 ��0?辑M���.dq�.��i�#$z���k�.��/���/�?;��y�$��ΏuV'3����Yb���'7�1U	��m�=�i����p_�l�n�%�n�s����q�1קjSv<O�D��t�/����ցL��S��f���F����.���q쑻�Fn1C-�|r�hQ�0J��7�@]�.ȇ�b��
I�>9�*k�g	r�Y��hdaT0��/���\����F}5�[�n
�;	uYgɌ31c���g��9��Ң9��q�:	� �V+4��O&�3�3��9&8���h�B�5q��N��0��;��j��x(�tfc��;�(���t8�&�-B$����Cޯ=¯�8�8L��ߦc�Frgߎ��+�A�%U^�t�I_�2�׊A��蝱H��0�0���E�<���÷�-B(:S	$��L�:�0��������9��ڨ��{���J�u��X�[��U
�<_!]#鲰�aS'$��as��͎�-��W��2>D�=�J.�'�Ju�E��}�]r>������kA�1yfCCc�� �x��X�ܓb۴��b�����͍�Ffݠ�,p=�����MG4�.��N���nS-�9���E��j���s_�}"4S�][����+<k.u����V�>\Ǝ�ԟ�/���D�nՄ.ƃe?dS��l��|܄���薶�A�DӕG�V�c� #K�j�2�r=��u ��Cd�s���ɋ���>��\�[�5�ޫ㶥3Vd�1l$'+���z���q�)Z0�}ҫ��P�g:Xnd� �9���RDB�J��v��I-�J���+c0M���bȡ�Oi���@p� Ϥ7C���\��V^t��	,�v/�_%y��߿�LCx�K�
�V���׊�4����@��q��_-։3|g����J����{r:�O��q�T����̌�pI��A�W�Ӡ-��\��X�i6H�p�.$|�H^�YQ˫/�/M�ȵʮX@m�?(��4(j���A	�U�K!$m�2��W�m���$���$�u����~i[�d��T���t�~r�Ј!��O�����7�3�|N�8�MA��ϏYҳp�/�20���:��>�@�."�J;tY �˹{r-c�w��|��׼�z�C
aCZ���$�Y''�Y�Kʂ�rO��Y'1qZ%Ȥ�{�\��Y�=J�x�?�U�Tj׃a��W�;�^��hr��Qp�g�n��Od>�iOފf��H���ծ�9r��ۻR�л9�Q�xН??:�`���N ��� )�eگ�߫��1�����G���5����֙?�@��H����
�@�G@|���K��_��6��Lޚ��f�gQ�j��7�k�&w���*�a�1�LtqB/��	C�����*щ�ɞ �H�?�`��2��:X|�4����.ܿbʗ�&�E�'؟x�a�yV�	�����۟��������1�6ֲ�T", ���unWr��0����<<K�6_X�1��(��sN^����ͯ��	�ֈG��0����_��e��j��Ռ�ձ���;���A;��K�Ç�\툇�k�s�l*�x2�؇��x�&o�p[+4pNԢi���[|�vS<R�V����0��ry8�1�&r	k�+!�#�]��EB�F�F��9�L�NXƚ�W�^�FdiMN���&p��T�W��Ü
\k�	%�Y��[���Y8��v����:HU��(�M�(�r�-">��v�����m O��J�^wHNc�P&���<�`����p����m_mY���+�-� >�� _��a�&ذ�3�����v�%0I|��o���2������cg_�����%AlOfe�Hu�]�]���������~J"z�E����ӥ�U�nҁ�HLt!����*�@���Y:B"��d�V ��\���*�V�B�a�|��?��3c��*�������X�^�gQ��zj�핍99�����oZǛT�M����7+�Y��c���L�nX�'_Μ*�Ӳ��Q�NhzbQeFZ���*�P�&�\44�ݍ����X����R!Ѭ��oN-��o�R����I�z���g`�_�Jɤ�����Ͳʒ)y�LK)���)�_v<�_����ԺYA�2�.�@�t�t�í���g�q�/�xW�kóa��Ӧ���^�{ݔQ9�� Oi�}�u��q���w�����d$��}s-t�+���q�]cAi��?�h��.
��c��(����t����ُ�����_�4�8X������t�\����vd�8�Ũ�6��#��ڗ�,����[��;²H0s̆���F��=㫬��.z��e�+
��+���]�
\-�BYk0!����o*r2�_d�^��v���5�6��#�;�N�����P#��w���,�G{u��i�&Δ4���2�&��Gŀ����B��|2��,9�ⳤ�#"�e,����Isu+y
Pk���[p#\Y��%���6��RaE�<k"U�������R���3��|���E���k�5�ӡ^�R��/A����:�|�B��8*�v�B�uVΥ���SuC9��q��(}����	ySa��oU�]���)+�����>Q�e�7�`�Q�^��85������l��������#r�!����ab��&Ҝȣ��[������������dκz]�.�2`k"͙�9P.��T���C�&��Q,H������/V3
�T�4YR�d�BQ���$��[tN]��r�b�~yVg�}�3SUS��O7/+������S������ɑ��JkI�6��^XK�(����^��܊��i&��E�-r7VK������ޔ��{;�RY�"lM�����*<m
)`�c$�\���4�p�71+�W�P�W�<��fO*��5H��;�vy� ��7�'��1����\��W@g�̗ɮi�׺�K��(�*
���%�~
�'�\�s(L򨖧t�`Ԡ.�#tAv<�����6�C���$�m'��3���k�/�4#��㜙��u%�RX�-o$s�/���o	���	�&8"Z2|��#I1�X4�L�M]6�pxt��W�����
�s�tj�ҳhJ�ց|�ґ���t��n���g��=����m����7႖M�R@ox���O
���7��Y�W��u4��]8g�d�=ڈ{v)T�?�)��|�f���Ik��x��׭�AP@I�����T��T�yS0HX;�`��Pv<7�gP!�2�n��E��=����",S�~�ҲJ/+f��H�[��ͺ6��٢Ŭm0k��*s��ֲ�Xֵ���)4��.Ͳl�]N�p�e^i�|"�^m4����n��O��;G
�2}��u�۞ٝ�� �eߜ])��a�|;;g���G�r��șֆ~���d}M�W���Yms����a��3��ӹr�l��`u��w�~Lf���(�n���3�%��4o���<QpN����W�K�#���[ˊ�XP,�J�(��Q�5$=g%W�{��BgCR�I�ϲ�n�y��r�vX�ʰ&F�dd���)x?�۟�0������nN��\����*�&�~�
m>�L/�d^$\�!�h��/y��8�\�c�������Z2�d�KN"��,9��+�XnT���1��Ԥ�ɒ�dP�ľ�/���y�hK��z�U}��l)Qw�9���:!�ЊD�OM���{�GL��ڮ����*��x/�U����4��(��#���,�"�ї���ÒW_�d�ɣ�Ze��DyF� P�&�K��'7e�.M&~��W(�T&�a���E�3��O�_V��_=[� ������e�h�s@�PF�I�t�k�'���4��t�N�_u����WH�,䢤��h6���.�l��y��=Ę�u�b�
d�;�W�4�Kr�(��J���1ƞj�`�i_��Ʀ0��E$Ύlԃ���l�����[� ��`͸���
�_�޲:=�z��#��8]	V��PiL/��a
U͐o�4_	�,-�P���(9�	y7m��9��*���RԹ��T:�O���/pʳ{���u�n��GV/_5?�9yX.s&ޠĨG埔v�(-2�+nv�*v��g��!z7�i�~*ʯ�(��I(�\꿻�'�����������h4�����������?Wk��a݃�i��0 �����'���@��s>��l3���]�i�>�|P
M+HV�0>��-�v�h�+_����d����ԍ;=`�D�(Ӎ{C�pߨt�D�H�2[ys} ��5r�NȆ��^ǝ/@�ɀ�U�{.� �;��aA@�POW�Ow��%
��7NC�ƙ�p/_<]+@�#�
#�+;\��������� �T��[l`�I��vq��t`�tm*K�Ǔt �ě8N]1LEC`�
� � �,�,��5�^��]���&Y��V�!��ǃ}2avr�#��q1	m-����HYX�X����$C%���d$x%J/2�����DI���w��Z��e�������r�udlq���͕� �Q���Ƃh���7A����⛀_|�����x���6�}�סʙ�BXgB�J����i�.>��Nd
�mGDn�ؿ�B�7���=�l��Q����_W�_n��bc6
R�´0�{�F�'}���t[�w@���}�Z��I�xX�W�z�0Hl���~M�p��xw��}t��,U�e���������3P2�d5����q^�P9A�%C�J�ö�,����׀2�>Di]�$U3�{�sa��f-tJ���N�Y̿s7����3R��gaQKq��^�9�.�/�Ԡ�I�����sGQ����5�V���J�E)�\�f�9��z>z���j.6��o��aE�|\�o.��P�3��\�`-�M��s�:R�@�$k	$����C�yxR�l0Bf���@8h�G��I�8�t��6�C`c�X �I��x���+�;Po�a���M<�o�%�a�9�A.�1�pl�L+,Y���$����l�(��rQ=_��D8�0r���8嶂����elc�2r�V/@ZS(�G����V��e�M�
?D� }�s��N�|QW2�:z-��C���f2J�u�f�2"�}#�u����E��#�x���5�պ��J��H��^��cQ�h��hp������ľ��d��{��CY�S�nfXo�*;b�cE ���Q?Y!n	uC�n+*pI��5A8ե�0��v6GP�(�ڀ$�N�������%/E�d@��p.JH�4��!�����.\�`}�j5�BϾXr�tg�]�+��C�D'w6��X�����W���Ic����{.�?�:���kw�;�����4}��|NG?/��o˕�,H;������xq�L��.D(ٛ��b7&$;	%;rc� ��J�'d���C��X<��aҎ'-?��A`��Zl��c�T�����
��M�|e�ј4��9"���*����H~@"���$���n���B7��fn���/�'	Πځt8��g����*��!,X�X�Q�)<��p[�B<x\�]�y�>���@��ALA)����X̑C��R�K�M��M/�Ϸ�-`�/q�j��f�6�/�qk�'y�9\��oJSM�ÿ�'-�j���"��"�7���O�x�%!�R��壋[O�����ȸFpo�	nB����_��?����,E�/���vbu��>��b�]�\���ѻQ��Ɗ�*RF�n�X>'��є����h4��hh�47�"ҔZ���"�E�zK�rWFױ�}��{�0�[���ny�*L�>�Q��(����Q�J���m�y���NZzZ3�tH9��^����G�zm���dI�DP�Š����N��twq�i6r��{��%� ق�x�i�[!�'��2�ɜ�
y�I���=u3�]*��y�Ū�כ(���b��������7/�>��vs�n4w��Dm���
�?n)���	3��틤n=�3�tV��>����E���>���5f�S�ڸ�%歠�%G�D
���nm�U����U��sS�:������a� :0-󳤗�����Z �iz��~htn��$�PX���M�&w�|�~1ff����Y�I�hӊ�]�C7��6/�}_�<���g՞���C,֓�g8t%p�<��u#!�(]rr��EC5q�yޜ���5�>�13r��~B���8s����-����$������z�q1G�F�>m�r����v���G��8�  Ɠ(���DTnj����A�殕�x(�+t���|q�_LG�,�����Į�J�Q)�ە��W	>��kfՅ�MS3jW	�:iY|QEm�ԺM�$��t�G#���;���su�H+1y�����Y%>\̓��eM�<���C�0���E]��$�e�iƋ(��T_ЍGY ��(��K,[j��Җ����l�ͫɕ�7���)�̑���x+;����ѭW�{��~ۜ#�ؕ��vD�)�)WY(�^U'h8F���,����t���=��OЏ���8
�\�>�#(�q����z�h�1a��"�t�a��X2�_1��j^P�o�����;
e�p�1p�
Qu�09�"8��d�t������aF�	��XT�f�z����萡M����ܘNZ�me=e�b�������n�]��rr��Ԙ�k����W�N���4�H5�2�O7�Y�h�j���׻G��v`[<�~�{w�X��ni�Y��>�>�z�8VZ���.!�s�����do_Z��%pF�nB�P@�~�F�[�5�_��]�Ve����k�>jU�:��Wè6��8
h����l�����]�$�F�y�X�MG"U�b8����OJ�nKGݲPN��c�X̬�(}��=(}�Io/�$��]�t��4�w�7��r	.;CL��e�\�>�թ㼿�b�uk�e-�RLb;�m�$+�`+�����T��Y1��`��+Iп�&p�=�ldLr�ޭ�O�v�/cͬ������p��T[�����$�!;^n�o%E����rx�\�˩����F?����n��k� ����V4j�+(�K��<�O�s����^{4AK�����FVBU-hwm�B�~�]b8��SK�(��C�f���=.�Y.��o8ڙ�7����!�������Pj���QO(ߑ�l�LM/�>$�(�D�����X�2h�R5֙����r��:z���m��U�g��(�k�l���1�j䤠9a.����Y�Ϝ>�"?�B�����/��.����R�;�X#��#�0�fwx5���J�0�M��Y��-�u	�?kX �y:O�����7 �Ap������a�9��JN��HX����|��xZ4��zኺ�b5�?�x|I*Y ��~�	1�Ψ�
<~�XT�.K(��4_B漢�I	e�+_��k�MZ%��E�Q�<'i�`L���`<c�p����
]$�c8v��㭨TD�S���!4����XG�����&C��Ì��	ɓB`q�q�{/�@������ �+o-�/=F2���oͫ��j<�E�&6��ė�އ��]��9��q�Qk��V!�6�������%-���C��/���ج��{$ۈ�m.��b�V3����ى j�1I�x.)�y6������5�'�H��ԨO_���o30��V�qj������S,�5ϮOذ��Wc���}ھ�+�Y��s����;�Ԁ�kY0ۘ�3�I�m�n-���ޚX�/� &u:�W�E,�׽C/�d���,�5�^�&&����U���&����Y��b��whE,�m��3�d��X�Oy�ƌ�ǐO0#��05���l���&LH�&�S�d$` /f��%��;Q���1�/!?Ԝ�<����C�I��L�m���?��Q��a?=V+�!Sy�x���_�˄����Z�a�Kd�3�^�e5`�ꅝ��  ��,��������Nɐ�=��9r��c�L�P��U2����Ϧ�gey��<�:`��T��w~�|�.ZC%�d!�U��{.��������Ӵ|�����7�cH�x斠$�H����jb����J�����{���r��i$0.+�g��P�1�`fC
W���n*�ӏb/X�Jre~n̘|�#!�BJ'�*a�pg�QCH�>�Å�D ;��	��yI��=�V/�����q函��WQ2~�%#xN���[%�%�H$���,FKIU^&��B0Y�Ā��aٷ,k�~��?�v![Û�oz���}����>�u�k�i������0����=X��g(��Iʎ7p�Ӟ�
�-��\R��T%DY.�P�OSӪ(<�OM�>j͙���5�Z��](vq�V�Ns����Vc���z�ɐ���2r���DU�����2��$�5=暿�Wq�Vm��re��^��B/6���:!-zF�K�=�O�`pê�׈F!��<��D���IB�N�\(fvnz
�W�'������im�ݦim�j�����)�U�(EI
{���}y���/�Q�u�����|��g��ʚB�����RW_l���ý���JP����T����e.�`л&;E�]�y2�9�X�6RX�Y���_ә��߆i��d6V�g)q!�'�ޱ�B�.��i��n�=������b������vpf���� �G�ۥ�;
�E���+"��C�%�5ނ���˃���K�+J��q�m��\��0��8;GQ��
>�5m��1C�/�췿+ g)�w"�aC������s�#5L�5��;�C)M�OH:oQ�xETL`B��2ee�qO�8!�,"J����&u+�*+Q@V.�K(�Ɗ
������E���2�@�1/PS���^�O��ӈ����T�F��S�쮋������$D��� �,�%?ErB�z+w �L+�P��I��*��؜��uͰQC����Y-"f�̪��C�I݊�eBiߘ���:M*�V�h��=BM|��
r�?;���3I��}n*b�M�Im	~>����^�!�1����GcXG�k��,�b����ú�~�e�7oR�É�}�n�+!�Әn����j{�1�ͻ:gnQ���a�V�8ݬ-N[nؘu�Ե�O�#w�2��i��0�,JG%�J�=�[���L�ut�HY܅�l*�>��Q���X[�k����E�pZ&o��V�+��
eX�M���p�Mh�	J�П�D]g�P+�Q�*�(S�v�d�qO���E���sd�)b[)7�!MDt����C*P��h��������_���Jq����S��I�[��� N�͖/=�~2��̘��ԍ�,��q�l�~b.�q6�R�O�E j���"J'����1>y��{����G���
ۙ�bz38��`]V�d������Y��j5�^-1�x����há��إ���؂K��i�re�,�tKI��̌g��fƍ��4{ y[?8D� S=�}�s�S�	�/@��z}CE�<S�k�x����M�lĵO:��'><�QX2�$�=�97�lG"L� 3���Q�դ�f�VO�������T~m���{�/t����\ƫ���{����PF����.\�+��Q&�0櫱<@���;n#�$�a)�0�R:���i$��Y;��h8h�)���_��5��a���e���k-���[?J���ى��s>�{�ζ�r$�)A�|<@���D{�=�2�4��J�|6��2M����C���5��ʶ���v[�����PJ)��N���E�S�pLS��g��0���G��`���Y#�<����O����Ç%���}���g��������e�~:^O��c��)O�r�S��:�4�j��e4d=L�^;K�]���[���ʵU	TB�=T��ê���	�Q0�rK;o��@ך�+Nt����ư��8xux�{����(������������~'�s���2��U���W}�*\�Q�\��F�(A�w�|@l���A�<�%e��\9���gh��l��}�8it�� .������Yl\O�U��!��;�7C.՗�����?G�F9j����yT=S�*�mk2�>3�s���õ���������������m�~h�>'��$�N�Kd��q�>��7��Ű7L����\/ᆶ�t��Z_�/���W�G���
q�y\��9�s������z�룽c���'W
-�O\�*��mX	��z�����Y5F6��\�V�G��)w9Y�_��_aJ7/#�Z�>�����8O�l|Oh��C�*Fp
h�M�]��5e%�u8 y|	����碟p%�)�74?�g(*G�{;0v��v_���͗+�d̻�i[L�|�hv��n������v{g��4|/o^�9���bD��W��2w"���@Z,0�r�~�W�W
cw%<���WqJ�;� �{��U�FU�SD)���[����!�}:�/�f��dpB(��񨶺!��[��'n�������P*��H���|o�u���L��;��b���*Z������2^S�
�ϖF�O��jf��{.��(�շ(���ά��u�ȁ��۰�ލ�#XJ���U�m��m}{|p�l���-������֙D��y{�� A[o�=	<Pjfq�&�RNa�)c�N�d�5�b�˖�;7(u�=�Uvn	I��k"��֨5�8�_����Y��(C�Z	�B-M�V(_�ȋ&���2�Iy���NΈ�?�G1�'�T	�+ɽ� ����|�t����6"�������RMqĀ���<��fR*��j�˂{ڷ���V�F+w�K:SMu�+�X<Aq�f���}��W���j��I{�x����&ԣ�E�SsfU�[D�	/�t��Q��	*S�y'������	��t^3� :�ϵpx����NO+��;�0kL�RZT�V2�nq��M��&%�rZƎq4�@�dx���6�M3TN/�X�����w��j�]X���v���(�`QO �.+�����xr�R>����C��Q���s���R�"��Q|%�BQ��~BJ^�֐(f�D��'5�(	۝�������jo�R��&�DP����O��E#�8<�v?M��<h�_R˝�*J�o^�x���K��i��q
ţ�����\�\��azo��n�W�վ�� ��vǆ=�U�	�����nu�Z��_ԑ�>��l���6U���cҏ��*�@U��w��M������~�&˟y*�U�?e{�%�4�������睞�����'&���ݯw��>��-�o���9b�u鄠2���U��=���r�`Ұ�'g��j7�N��b�v(���Q��lrnv�$��_�F.��<��8�����s�SU5��pћ���o9�u3�ǃ	i!RT69�dq��G�b�C� "Z�-���L}2H�T[|3�u���O��P��Y	|�-h+����	!TȻ��á.����y��Vp���pP�>���*j��a�����ʹ�a����&�"'ү�p������qs�d�ax.!�T�	�]�s�M�[�2�S���ݰ\��}DPZ��	�vv?|?9Q\A��$��t즺��	�z�*�~�4����:`.�oUI�K�j�9���BG��6\C)f��o��3�v��;��}�RS�jϕ"�X&��բI �S�2����`LNX�+�[C�N�	�a�;���Qs���Ze���i���J���W�&�D�w���N���\��z\E3fa�!a:t��~�xg0l�/�Mg��m��g�;�à^��������PG�>y�|��]�Y��f�2-��M�c��ƣZCU�%ٱ�� �����0}6A��o��Z�v����Ū�W�$��IF/#��:��QM2��@!t�֡C4=S6��{�ڿ�M�c*���C3�k3;-B�c��r'M&�3E�H�<s�����t ��+����+d��y��.p��KY�<a��,����Q㡌.�rY^�K��B�N�NQ�'�مf�>�$\�}�.����.���7���xUR�^��.⿛�^��������Cn�P�X[�3�<�,����m'��^��t�0�@��Jd������X�Ԣ��)e_�z�X �d4C���
+ }4מ��E���^��k�#V4��c2�x�z�[zR��?n5���D�����������?��_c���zA�o���ǝ����[+�S�v: �u�I@��oR1��Ϣ�*����'�����ȟK������9���}�,]�p��?>T3ԡ��'���}�V�G?T�̪q�A��K�d�A�m���i{&�!� cy����6���v��E�����6 j�/�YTV�%)��B�A!�+$]3�)1��*�j��n��V����dQy�K�	*G{�s:Ln�Ӏ������x��{;���.�=N�)�E�VvZi1(��c�	���#�����!L�ܾ�4��ҋ���x�� Ĉ�Mţ��XJ�8L�V��V���96'��Iyt/�G�{��<�56�P&�9p�-��8C��Rܦ���\+G�0M�5W����k��y�ͲB6�i��~2>���*�C}4�$1l4�v����^���֔�d�2�D5;/Z�9�C�]��л�z�� m�ړ<�
�i��o�ΚM1_�yF���~B��vp:i�}֋%!�h�|�ݢ��HRx)��{+nr�|LB|�e�⵨�|*���.�v�h'�3Z���z���-��^Ql�L�˅�Td�9��萹+�t8��f��,n��O��� �y��R�<,�
\�7���������9nӨz���C*���^gƽ�s[	v�W���4��H��>���v#��)���`�\�;��	X�sӾ�d��h~��=[G8a\�ΏƄvG��(��H.�\�O1�q%
��5�K���\�(w��-3Tn������8���t+
e�Y/B7���Y�mH��c�[�ו8��9�:�*�夊m�;��$��_�D��̈́���><��T`�3~���')L���M3-�Ri+����h|+�au;(f�0w�D;�p��E�����ȏfe9^�����;�&*��p�!�,�Rs�6(i�|2�<����r��,�xXj�t�qnW����O���T��<G�TSGoN�Q�KP���-���n`I��нg<Q��-nب���#8~�E�z�7Pr�k��b�q��.�Ê���e
<�t	�-e9k�kbqC,>r�չ;vb��5���5�yǤQd�����G��� o�c�ܐ����Gy�"��	40��@���P:k�ksq|?�u�e��-�
B��G5ick�}�KL�4_�1��gk6Џ�)���g�z˴7��I,�u�i���|=ռ���.���N_Lw/�n����w;U���E��+-"�9u�`e�9�:�F��jpNF>��	l�~��+�+Ѓ��O�I;������'ٍ'��66&��5�{ĄVDm�,�u� ��uZVͨi�VI��ډ��ůs����"�\F=�+aߔ�ឿ$��"䔤��=���d��Q�T�D��pEX۬V��R�Yx�ދ5/�7�Fæ�l���b�,ɃKPj(7΢N�O���v��'�c�~���F���w�?�k��ȯ�����������7U�>�����7����ջ���3��!J�F���c�v��m)�D���*�'��$d����8I��O�ʋ8j�o���W���Nw������'ei�>8l��5gi`�``��Oϟ�4�����yp�?[�s����%��r)��mnO�ƭ,���V�VO�S,�0�h��w0+ظ�XᤁI]���^�QcW�iWϽd�N���w��><~�c��5}�D����7ڰ���is�9�Y�R�9��l��u���z	����zE�%���B,���"SU��Kg���ݚy%qUE
�$4�`3�5d��DK����y�r������k����KL�g"����*)��/�|/� T���J,6�Gu�1�z�*/3*�i�kR�ַX=Z��y�h��%'N2�q��m �dr�T�ׂL��L�Y������;�	�CQ��+�z��{lz׺B0���Mi�V棎A`+�c��MP+1͛�����II�+�B��\�Z@�(��S�!Z>��h��sp���]
hۍ�|;�M����+A�?�>����)/0����~F���ud�\�o������ُ�G<Z)d)�k�a��z��L��p2��J��ј���>���kApI�y�t�ó8} H-城�O�q:\<{������.A���.<�%���;�4�ڴ��O��3���ɨ��}Z���u(@��m�p#���k���v���⎙��_N�x���ʉ}2P��e5��i[����ίA���5���r�eTx����N	���X
�t1k[p����Ɨ��6��C)�U���#�q���|���'�D�@D�#�U��TA8��W�Q<P��0�þ �>r��yZt��&��F��΂��$��3��C+<�s�c�O��kM! &VG�R����4Ju�.r�.��#�0F��
�,S+V����vP%Ұd��3%��V�צ�W���r�o�j��3'ޚ�<���=�
H\ę�ԑ�t��/��vr˾#m�g��O	�6��h�8S�#~ib®���X:��=�\X�z]�l̄���	?�Q��`�՗[�	WU���\�n�=Q�� ?�boA��8�]��*���m�:� {��_�i�ظ� ���\�������������N��Y>��18�F[�&���X�@a�D1O�_��T"�y2
�������}#�7�뤁��Q��c_ϧ�Uu*�������qvEoY$�[�F�r����H1L5��[�yN-r3�cD˓ӌt�ԩZ썩DRR�!	��b���2d�����ǔ:Pb~�T�A
�fϸ���q�$'��5��o�)�N-ș)� �h͋"A.�-+�35C�Ķ�$��4SĸB"XДQ��RY�X)���x�������ͮ)Ѭ�1��$�ͣ�X8O�w�߳����v��O�Ho-@6E��Hv6���YuQf�I����)�b�Qv	-�uYO��.�h�g+ʸ��7tKI�uϒus�����*�-����������@H����̪(���ׁ����c�������;����ƴ�h��T�_�8%G%��(��Y�1��������y׏c^���^ox�w�JKdi�mA1Pذ'�ף��J
p�5$��X&NCk��@�lwqox��i|���Ů�:-�z��T���~�����L�G��;�vaڇ��6�Az�{Z������<�$P�u��]��S��'�%�k�A�
�urSgԔ��2,�a�L]Hp��Q��s�(F��Ń?�|�Dl��X��(��8�p��E�?v�U�T�_m`���C�ݵ�xo޲?O����_�f{B��^d��Yt�0�G]<AҨ5A"+�<N�k��i��tH���D� Ih.%I�����K�u�g��>d#9p��&�4���p�*"�F#�o6ڦn�
P@z}H�2��%�x����Efzn4��1ĩzB�^\p�%P�("��L�g���B�InY��[(�Wq�>|����}�>w������s����}�>w�������O����� h 