#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2963420601"
MD5="14fe3a90d715a686c08302def594ce3f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22936"
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
	echo Date of packaging: Tue Jul 27 04:43:15 -03 2021
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
�7zXZ  �ִF !   �X���YW] �}��1Dd]����P�t�Fв�@�&���s
`����2�丢D���-z��b{W��������@ e��⩨����z�f��I�z?��o�y�O��a޶@);w� w��T�Yd�+�Z�O��G��
�Z�躐[mKx�9����F�đx�E��N��Z�����;5���;�o(�-�{�*�7k��4�uʢG(%����=
DC��㳷7�����tw!�9	���h��E��,62������A�Ϩw�G'��@X�-c��-Mɹ�i����b}�nE�']�f X)��oul���j�9����,�w������8I�JH���&񡱠�м�����Yh�x�f6�[�_+Pb�b|��^|����x�ɐ��?M?H���pe�۳V3�c�A�p��7��O����3@"x���1����a��q$1�nۍ��k���N�<��5���o���P���e
��h�6����M��4LCW�:�g��J~���q��Axw���!����|<�����|m.�gn��#A�XF_�����(Je�A�7���w�ٜ�5�X[}�A�� ́��(� �����k<��d��ݘ}��mtgU�oi��3a rr'���-A���_��}�t�e�P��Z�z)���vcxfd��4[ZH"�	S1�I��_c�q&ŀ�n�؀?�A���^�HT�(�p��>)ע�N�y7�g)R^)ϋ_-c�^TZ������;�����w���:8����*A��"�cIw���,0�	}��[�C΋ϛ�1!�ƅ��s�d˕R+��:`�W}�
�=�"���#��="�[fc���TpJ^K̹Z�36hAψַ�$U�b9�C��S3k\2�I����yX�^��ĭ=��=Ϊ%�U*s��v��܈~��P�3��+���?&q������a*H����@#
{���V3�䤕PhĔu�s`sa���LlqV0Ǡ�[q�r�,z���,� �� &+SkM��,n;�~T��]����#�=M�/�r� .��g@��dPnw�4���;n+���j���O�D#gQm���Z�vz#L��<XQ&/��L�T0P�W�G-B������;<��[�e�z�5`�O`�N
���Z�ܛ��x���b;�^w���V�B��.�Mn���]���ub�ȅ�)�$��' �1�ݗ�ux8.�C���a)�`�V�@c�`ˉB�(Ɉ�0�d����>v�I�"��Ώu��-���p-��5�S�6��X���� d�q�Y T<�D�+�#5}�-ɽ֭?�/a/n8����t������dJB0�0�ߠM%Y���F��"xϙż���k;��δ��C{���uQq��-,=e������@���/V�A��Ũ8��΂�=@W�6��L.��f	��R��2N��4�u0h'+^,��I�{o1�����x7�	��l���w��7gvn��|X������'���%�'Lr3r<Q�2 �#��"ԩ5{�6J�$J� ��{�u3͂�5�9惰�_Qk��^��'Ql�}�d��٢�:����$�ׁ�<�r�d>ׂ�?ms�����(���.��q6��@(~��Ɲw�Xh�t}l�26ģ�%��8:�����^G�`EF�F2�� �J�W����rxQ"y�1��KgeC^'�5k�/=f��1�y�jTÏ��]( �����ȶ�2L6䄦��H��[j\��w-�xg�X���;�<��}2d+p���富fr�ǿvU�L	d����!����cՎ���V@��<�V�W9�������������\����B.	�lM�/�O�%�"�lf	��tƘU��ŀv�}�,�>��5�fO,N`*3
���1��nK��V���=�Td)ꛛ��ݬ���w�q�a�>U}zjhJ%Ϙ=,�V�v�I��V��`���}� p����d+��?U#�:���g2���ƌ�pl\�ˌ�����Zu���!e)Q-�٧�(� �&<@�0]������{���lЎ��� �xS�B���r�:,�#�A%Y���
Ѵ%��t�?B,�V�Ւ���u�+ɥVy���pP�/���p�GYM��uլr{�:�qFӞ�Mwm��H(��t�����B�RAΕ�śG�� �Έ徵Vw�(2�p!&f�����{�9>d|����&'=�˃%jlB�ڽ��7��|Kg)��Q�[���������<N��
���C���I!5�3��Y�G��N�����ݲ��mn�P��t��'ER�݀At G�A�h¿���g���������aŎ�X(��CdFs�n��&r9XA�K�MW���'��M���LJ�tW�lP���z��?U�����/F��u;��'~qf��������s�9x�c$św�Y�s�9Nc�3$�	����q���ќ��0��� S���O6���Y@>�O�K���)�[M;��ē��<����l	c���!"��Ε�l����amwg#ɬ���?Y(6�*e��ѭ�T����{_n�L714�y�5^(VxG�o��}Nи7D�+�tq�X���5U���Ŷ�	�ɪ�{sU���q�U�������1±�����d�҉�ǳ/�����3� dcF�x��n��ã-�R��V'��kB�����/$ad�[JR��v��{�x�g�䏗g��O�L>���j ��!�m|^*���vC����J)VV�?' .�A�
^ QwN����n�1�S����;��*4�v�m�q���q�k�L��~;T���w��n��f/��ǒ8kǌ
���)Al���X��
ʜ�k��O��R`��yY�lT�9�/������)��e���T����L�2�M5A����ʹ��Q�*9�<�(U�[`�2���&�@�L�Ʊl ����g���p��=!�Fp�����m�G��m�	(�	S��Qz�Lf��}}�Ǳ�`4Vd�(�]�S��85{�V)�9Bm�Zq�	�n�u���;ñ|��r�뱪|R��v0�d�7��N_�)����� rw�Y�Yi8�]χ�X`���wS]�닾8ٕ�ϗ���1�	�^j�Q�J;�f���V4=~������j)�7�'��l�zI/=NFH�kմ�𥉉�+�-�9�S�LFۇ�E��O��/��w���⧊J:��ӌec4�Z�&���x�� S�����b�[�(�?s!��s�^㧓3�/�=#���E����O�q��p��1���c�Gg�	���u^⪽%��K��Hu����{i��G)ӎ>SҠ�T�k���r�k�6�^}힛gGI��������t}&�г�N ��\͓䰺D$���^KgQ��/�'��$��7dB�Q������~�Ӹ6���$�r�ԅ��QxjuC��0y ���5`w��j!�? W!D��$��)0�N	ȅg�2���T[s����z�������$w>���^r:A�
ܐ��,�.'���C�9�A¶��g����Ѥ�Yh�n�{`\�.��(����2�]��%�{�=T/m�W�$�G1������N�ٍ�歟�pܼ�yS�e�a.K��F�����t�2.K�Pu�B�ņ,cjکSŐ���$��w���W�+;�,X��L�hfc3�ϸ0�y�;$l�B��*�J�;�^��� 6LȞ���i�X3���!��瀧'#�f�>��=��;D��v*!��F@����A���xT��ca	,��<yh1��θ�ܟs`)�Kb3�T�h'�ݩR�{⧰p�Yt�X�E�!�#�<��}��p���#8�rМ*������+�ln�8�VK������X�vc{��m.���e�q���+��!��l�"�=FL�[yt�0�^�ܐHfN#|R���R*��+�c��]}��qr+�OD`ϋ9�J��$� ��i�5՜�!$Q�C�Ɗ5)H j�s�����M! s�^��sj��>�|P�����Ќ������o�c�-H���kj���C[���7�[�r�1!��
?�?G�.7�nq�>R�${���V��8��ă'xm=Twe�S~��	 �������͝�<²�Q˩V���aY���v�8��i���f����ʀ�!t�?�����,|�ܓ)��1�o��8R � ��Tџ&(z���73�2$u��.�N�fo� j����4UĶiw�_ 4����W�g�"�s���C�n��F(�;}�uk	xZ[��8��q����A��)ne; �MG����<�+�;�f�V�śş�W���<H�=��iL���8�W�6@�	}yY�1Lh���b���f�#K�}�Mإ��x`�|}Tt}p�Y\1���+�K�>�S������*0e�[�?���xG�����+�މ�S*������/v���H��9�ŗFH�/��JL���xELt;{�ay��qv�l2@kI��D��4��Jr����;$g���|pz��p�����#8�!���_�'�nk.�#L.�s4� ��=��ojȥ��K��Ǻk��!��,�1JV���m��;��߀�e����i��n���No/2�ͥ���L�nx����%Z�ȹf�+�//]C��Q��h1�G|;[�Z I�4�-%�$Z3W�(�a{�����
�����h �h�
�1WPF^oˬOD×HQ9rd ����د�v�s*��o�z�+o-����7"T�����X��: 1k�E�ׅ_���fAh_���
8��J��Iz�ɣP7��T4߇��m������u�ւ���B&�Z�6�EF;~�[N�~k̜$D����@��ѻ6K`�#�ɲ:��FH#��zp��{�
����k(����ݨN,F�m��-���i<�R���ſ� %�r��%�����О��v��>F�J��<��3�˲�Q������T=G�Rc''7�!�ȋo��b��+\�9�y�3����:�0����n�8��j��a��5����2��K�	IC��j��r�&/�a�J��$<�1YD��RC�����)m���y�.6� �=����@�"s�b����oѷ�\��z��%�#q �-Z��o�� ��R�J\�5.�c~G6�1�r�r���b�MME�}eI?{�B�'�C�3��t�BNK�V&���a��i�s����E�2pd�w.�r�.g��+�]�'�Ii5�Nu ���0����֊nKx�����l���:�C�p��[�'%A��>{���>*��^�R�I9�B$;j�A�X�IN��5[!�G�AtUm�+��}a�!�Z9�1$���f���I��uu��.<�l���$仛5>�DƼN�>������9���c��pQ�I������H���D�P��8��՛r�~
#X=|��@����3�Ԅ�tNq5r��Ci.4�;L�^��n��Ђ�c�a�ʥ0����<C���M�����7���t�~�~�3�h  ��S�a�xof�lVr�\�ݯWJe�P�,p��2E1@��o�XM�([[?Bd�R���ᖂ�p�*�bcX[dmD���%�L�V��#����Fp��	\��\�,<zG����~p�DR0�����J`�60���t�����K ��(�G`�ߘ1䅊�����<���9kn��ON)&����i��������mG��?��`x��;�8�dݍ�l4,q)VU�N�q��|�K^D2=�K˚.ψ����Đ���z=��dBp[��!륬.�Ɍ��l�yT��K܌ ��T�$><�c���kV1�`;d^�2'R�O�UFd���L��}t���N�1#w���;0f����%����l�D�ݙ8�v��!�Y��+Q\������tO����)Ţ����7�H4�ry�Dc��_�����S�9���(G��� .A���'���/-0ǓUǉD��cx�	���l������
�*�"�	Ԁ�3�r�+��ئ0B2PSA8�ޗ����۞�8/))_��X�J\?�=��C�Y�,I����X��쯗��2�oq�d�E��F�.�����L� s ��{.t�Ʊߜ�ʴ'�ztL��F��� 	7$���3��=�N�X��Ce����v"=�#ڰ��.�^?��W�G�ѡ�ˏ�l+���j���fKC���1"���׵�P��Q��^�)c�ķu��B�H ���D�mf̫.��Ѐ��*g�;��P#��,ͅ[����YM<[X���(`���J����s�u�������2����L{2Oc�~�����}~Yl"~�� �����=l����9�w�ƌif�03j�t`��C: e���&�i��'j�r�.�z�Y:\L��o�I�
�/�Ӑ������~=w56#�����~(S��i��*���^�O�4�2�L�p�d����~[2S�_���⃕��ϲ��Z�ψ����-�� �Ud�	�&�t�W㡌X]�������f>[���˦���ۣ�h$C�Dy��&hcX0��o�	z�l��^R����f�m&Џ~�c��^�F���̙T@�"B���Ќeۼ�$4k�3��J�6��=f���&�l�Q<4Ĭ���i0�pyqa#����ru��qí38��(��]��(�!�� jU�K,&J���{�g>qI��2uX��/��K�2�OE��'���p��آ�p�	fI��?��wd�Qbo���9��2خ"*�#�xh���2_���[�)|��J"����)a*.�rq(��p�Y�pO��u澘���)�q�AדF���ֳE&u�h6�9L�`ɉ)���~3r^A�.���Cvm��q)��n��D5Vb����?��\�V̌��ҕ\�v)y��2Н#�ss~s*3���L�A^Dϝ�ݻQݳS;/0�,I"92R��\_J/����9�w���9.J�B�e�lG7��mo�%k�h,h������`�aTS��>&�b5�g�^��p���ѳV4v�|�yo�)�rN�Q� #�PF&�Ϙ�+a�<RGW��
&�|Яc�o�u��w)�Z'�n!w��|�X��O�Ň2�_G�ڂ�	(o��9:�� ����HH?ǁ�w�����f��L���3�G� N	C�ߩ��x$�Aʇ�#��i3��-J!]2���Ss<��Z(�ФR���yQu�t��M��D�;(fe&Xٚ1ʔ�Z84��~O�p�/��B=h[��P�-�Ni�Ɵ��NZ��F��GN�X�E���l(�k��/�7��$��`9ޮF�5A��k��>���l4'��f,]k�hՙ{�m� 
�����}+ 3��s����ɒ/W�L�|�j�{�����\�Q�/�ޡ��TU��+�c	ix8���W�5���2�8:��ƣ�V�Q��M�t=�l�U���ȅҤ��r���;B���L�����_�?	����~��9Ac[�<E;�T� rCjw����S@��uMu���8�P�'�"i���1���g����b�)�5��7�h_*GӁ[rp�O�`�H)o���ga�"�}�]E���Κ�2���żoZ�|@�Ƥ���bD�[��_|���P����+AH9$f�Z<�v/x�*u�,��H�'���������h�e��I���N~�|X�>���HъE�P����Nlr�@ĳ�p���_�rE��I0?W���,C$�,$"���G�!�dVԂ��L � ?v;��/}D��N ?�q%���BGHH ���.<J���]�xg�:J��Ο���-�P^�u+DH�U�0�����&�׋	4����yU8�[�^��j�&ӈJ̌�I�S40�w;u-�$�m!n
iO�a��s�(��
!��D�-)�Ճ�ȜP��H�t%8�Js��i�mNͨe�����-?4j!(�Mҩ���I�Ў,�Z��E�jJ��(.�����&(��&^�2��u��������������"�W����u+=���+�+�tt�\>�3�%hK���S���%xZ�.��(|ho�to�-@�yH�/�`���F��}�	����W�ݶ�$�������H^�`m�H} �>��ۦ�r� tv��%�r@+�O�*J(�&[��:�}Q�$��k&�71��9�Pt`��UT���1���i��vW0�s�ۖc���o�Q�̄m�rW��G�����1�������{��İ� ����@i_�Q��t��ڍ-�0�O�#�4��`Kwӑ���G2>�]PS^h� A�Dk� P�	۴.��U*�.ѓJ-���?�l\�y\>����}p}R}7K���
Rb�"SqS�P�R	ng���"��7<6��I4�����µz�k�M^�FU�c`78��z?u#�g���fȈq���&vT��a��5�۩ �?:h��3�fflm����w�p�͎�g-���.�����.	��ө�?��YMGPEfi�LK��8O7ƩX��V+Ӈ���S����K*�Ze�D*�����hm���Of��NEO�ڼoz�`��d���iъ�'n8B��Vcs��t���j�<�!���WΎ�(���a�=lG���ݘ�����2=z�[v���ݳ�0���Ⱥ�hټ.�E{s�޿�}N�_�%f� ,^~�@G��6��JszV6`K�u|�NH-¹�9��3��9�S��E���?��ٛ��z�y��������aR棓÷hV>�}e�n���gF�� g	��@��d�'��?s�������`9b[I�Eʄ���\nD��&:�U�L��*�"u�����I��^
D1[��&Q�������t`�굽1�)�X�_�H���NT�*�<qDU�̨��� �|暊��=Ba%�1��D�R����Ji) ��e;B92�jmpP\kS�-T�[g�#���r�������.�wL��{�����۸�w����+�����ʝ��AQ�J��6n}m��}��o{���=WQ�$e�s�.
���!{V�<�;<5����x#>�ʻ]XQ/g9N��k��e�	&COŴ�4��%����PA�������P)�G�e��g�\����8�qT��-����ӡ.��7O��?^���!�*���y���(Օ�Q�>��+k.*/?�$�E����Ҳ)�E�Y�m����=8�Q#���4==d'��A��v| �l�L
9iڿ�i���Q3��ߤ��WpǒC�);��g7�"��2I�`�f�؊�A�c	���`/�"�����/���������dM����߷����cƀ�m~4GZ��Y����z=��
����-���w�jRM�V&����9jc�q�)c��*r@�:L|dK{�-U��^����������N���}ϭyɜ0tZ��{5L��X�
Ay\�͏�Sw�������/\����CB�-)�˔���-�ϝ5�������睸�s�we#���ڤ��U�Z��r2��"=�l�g�]�s���U��sl��F2���F�ށn���D���jo�e¬c��pk�&1�['Mк��mF=%����MA�g	��}n���/�/st�����G�bS*�r��`B���f�ݕr�����~ǒgx��$(�@��ڮ�X&DK�Ƨ8���ݧf��"H��d�'m+��,)�TCB��r*z��\�˝����g��ZS��z2�<bRu�߯o�N�I�(�h�NZ>q0�5��k�ƃ����2�Yu����r5p�=������}���B^9��#��V<��`�� 1o�k8���pp�34 �SlL"h��6�'�y_���ߟs/��V�L8���	r'R�+�p��m5����m��sJ;*� ���,~l&�(��ǯ��z[���-��LI�AF���M������dG��i�����{ď�Sel�����Me���޵"waM&	]��o��ՔJ�m�e-엨�B���^�:�a�a{%�h��� B�gN���jX�%�*C	 ���1wy_��Vz�G|ܦ��6�����P-�b0�&V<B��*8�c�������j8{��s�=Z� �>���}���GJԓ�ˎ� �2:���^A)��Q�f�/d�`�ѐ�f����CQ{�M��?��˳�j����������-e|�~(i	��Ĺ��ckR&ˍ���S���y�f���{[T���rzJ�a��t���2���^��+.�Wv���?�����e�����#���;Ҽ���xU���W����ߔjT$S�����c�M\|��թs>��b��FB�
���'��B���=Ȗ�Ejn23���F#
_�	������>�LC�I!M��%D��03z�Y�vl�1M^*?�:�@ �0g��t����؉��i�Ymny�
z{Ad��\0OR�ʥu�ɿ��PỬ�HS�G�[~;8L|�z��šV
gz��z�D��`���pd6�LY��cǙ���W�n��Y3iNf�r���ޥ�!�y��&o5T�C�5��.�7��1���l�É�Ƽ��/�����N���O���g�7f]�C	��}i�i츃��Ͽʣ�	�AGZMWt�coMb��b�f6#uzDg��#�)�Cc#�����g��͚( ��`]�q�q �H��'���x ��v��9��j�R��WSz��_R�3##@���п��*��*�B�1.5�j?�+8����kS$VnZ������jAՂ�(�=)�$7R�Z;B�Q�<޽��!��~��Y.�$�M�\!�d͖Cc�ojk���Lƽ�R�ݖ�S�Jҹ�6u�����nB��_�
A�kr��<��U�i���.�m2^��4��N�F��� 5���1+-!
���N�Ho7�~_qI3)�l	I��C牵��}���!N���X��74���0��(��������������"M4�`�5-*꓈�3o"�W5[}yK��Q��,�-�Wl�G:�����1�ϧ����F��M]���M]�~��@N �Ũ�m�!�f��� �":�2ՠ:"��j�zU%?O՝z��������'�9����(���u,*�(�O=Op���H�����4�������FoQ��*��l{�K^Q��q������E�����V��q���2�k��4о��bމ�T�5PAuc0�W�޳�B��{��b&<fM}x��e)�E�.�%����h0��Je�hd�r�=�D�:]]c���]� 4�H�cvW��=�?��ņz�����b��R1���g�M�Sm���C�k�d+`x��6��6։O�����������J�Ȏ
���#���6��|��T�ii*o@?�W������/�H�}eE�[ٷ����"WE���e;!#NWE���o&X�
�qz�ek3(�Ο\#��,�1�h�@���V�f�t�g�����[E�7��~��
q��`��m(^����<��w%���yrI�B�"��.8��;���7l��꤬!&Ng(���O����te��� Az=фL7����<*�7ә���@�1�D�Q3Pl����C>ˠ6�����=;"h	����t���G�(QM��	7K������Y=Me: �t� ���wNB�Ԏy����� a�>G¯��_���O�]Q���T��������U�����;���r�\	��@W0�
%@z�p#T�L� ��ʁvMC9�^Xh��R"b���y$��3F`��>�o�wX˒�n����i�B���*V�~|aN�Z�/Q�7��j<&ȏu�����Ԣ4���h����cp�'��)�	\�.����{!��Sf�{��%�ms��@d�J�\m���i#�\k|�9\�kO�.�1��r�*�o�@m��Wf��MR���+#�3���W�ܺ�*�q�Ƽ�Rsw����Z`/���dȂ��X���|[�����noq���~t�Hq��$�[�@�$���7pqn�d}�����U<Kq?���i�>���3qA���)K[�0�P��<�ѻ����">/2��?Y�'�$:7���&>�!�H�''�I9����u���&?ET�젎؊F�dC��Բ_Ϻ��ĈlK�(�ޕ$�Qul��VX����j�g��/�2F�!�GW6���)���~�z*�G����Z8�V�a h�x�����N �ɟ��~U¥+�$E�<���T��1�o��������bS��{�@_���椺��
R�9J�h�ְ��C�����o�X5r�s� $��h��_���lo�I�&��VI�Yu�s��Z��_����1}�9��
�@v��-M�*��dF�Vb��ƺ1F��y��J��x)~�zY�H��֍�O�~ǏG��]����B���`#�e�*�a���Kc�	R�aj`�T�8-w��f-��xˠ;���$���{��tΝ�9��8�2ڃ��8Ȉ�]���*���L���P�X-w�h�J[�������X��vj�:1j��YY�_�����IX$�i�A��V��([������vG+h���3�$6� �h���8��7x����z����-���΁��-x��0"�o�d��+&��pT�*��h6��b��xo</��������w�nLB�}K�ӝ�1��AAW�p� 2̜�{��\/����T��B�]�X\�a���ǨZ��u�V��g^q)l��a52�_1���q���s��>\���)�GL׶Uo	WS5.��*@z� M�����{�"w�c��3��3�Y)R�V$%ך���q[~��n�c��_��'G��\�NF�V �2���X����*���:b�.%*�]�;-S+�B����5���#���$Q3�A��9O�ly��3@o%�W�f4�(�d�L�IP�x�DS��J��@4����q*|��s��(|��O[qߟ��U��a}���.���rU�+�ٻ՜a�5ս���BqRV̈��HUZ1�!��#��;Gf���4J�\f��>�+pun�ou����9��'8���/�m xI��8���*�Q2�Z
���E ]���UIg&�@k����d)�^2M(�;��'�w�1����ٙ_@P#��� ��	������x���*���ɴ�nh���^ҕt�����tvC�ߗ����zt�[v����@U���l��-u	)@2�Դ >[H��֫���?��sbRb�r��"�#��e$�Wafz��S�[p����Qo_��e��#�l����{vߠ;|tƈ���	-����y2�GM���?~�aŻɂLI�_YU�8�\�<"Z�^S4�*�tu�KS��:��1~�$��0�vlKZ�����9�פQ9��	N�A~����D|��1r��d#���dR�u�������� |Va9xw�G����UƘ�7��e?��#��Z"bF�ۆ8x����0��U�����'eõG���h�����Ĩs�5xg1G=��g��#��B`s�y�3��깫3�N;լdvKv["���jDҰ�HK� �/or@�������9��g�/�BҥG�%�CҶ'<�T�-����/_dw�y��ܿ�i�H���/�A�_�]a���g��|ƌ�����y��q�)�w�{쑦wz*�.�=��6V�G�&�	���x�&�4;��Y����'�::)v(ڗ������}=�J�䥢]�}OR	�ˏt���Y	����y��U]j���&G5�Ŧg�(��:�c����NVX��[I.Z���!O;�̝p>UݴK�#��kd�E�; 4�`jz�J'�'�G��@μ]�_ ^��t��НQ&5x��i
�'��1�U��ɕ(�@gB|f�86�8j'V�d+�F����ӧ�Ю*Z�|(Tہ�<��ٵ�()m���Z~!��f#�u'%C���R�]�#�����x��78oؖ1 ���ɧ{�ChڵS������f�A`��u��N�?|)o���ڽ%T�2�2���A��p�d@�ͫ�ܢ���&����4��F�YΔ3}�K�<��b����H�dz��Q�a>Z�iH����)������:w{�}�"z�WZ�\��H�5{��A�3<��3E{�l����p&/�Aq�uh��D���a���/+N�t.��2�J֯���ɏ������7�>(�u��V�"
]�@��S)��چ=�A\��ܵ�L��C�H~��0�N�j��L� ��s��*��Ol6�*�wʩ��J��G\P����S��㝕�fl}\1C;��5���me��z�L��2q�m�5Y�X#�9�q���)����<m��eBĺ*�M��|���/I��Z}G�=�(��E�72�
?w%��e�7�- ���^�b�5�`�?R�#�9���72Qcr�2.�i����fDx��Z%����?D���B(mY���Zp�t�޾1*�8��tQт�(N|���L=Z�K����}Tqƿ�����S��-�΍�Ǡ��}!�Dx{IW:�m:��_E�<�	��!��� ����]2k�Pz�x�h��3�fN�&������&�D���F"$������eTD!u������:�=���%��ĭg��~=�j`�U�K#�M��h:zU�;5Z���T$�Mg���)�Q]k|աU�Ͷ��u;���`�H}${�ߵ�I����/�����8i=�� �v���Ƹ�L>7m���� 1�Ȩ�E�OM��^�+��ďK �?ͨ�^��?�H���fu�Q*�`#���Bmcc4�EO
�0EHV@��[��W�B��.�l����	xO���հ�Jr�B0QZ����*6��M��P��m�GnGd
th9�8�=x�l3��b�m^��S8�│N����G����vf��^���|B�4��n���'*���|�g`Q-e���[�O�R芹)R;GЃQSv���Pv�h�e�͡�ZP
��v���8T�=-�8V�_�9�'˔
��]�B�c�K���金I)&�f���PZ���Ө�"0��{�)�}^rk&����}�T����9ѻ��������P�|oh�(,uE_(gZ�rb���ص#U�)E7����w6ŋ��š��T�؎w[6��� ���v>ѿ�v��v��_�][G��2X�@����=���)�nr��Q�s(��ٗ�!�g��!���[�����b��&�鞛b>�ı�x=�c>�η��F��w�n���pY5��ǉ`�"���_�Pk�-ܓ~?�T�M�y^�#1t���w���2 ��R���}�!�u��7����<QFxxrU��9�ȍ�:��sU��M�H�{�Znm(�`��)"WNV��>�F�P�0��,����i'�̏�Q��)�_q��`x\�4k烬Ǹ��c���۬b��ịN�3r}i-r2T�=�YN��gzyJH+�?f_�:��?�I��sY,
����t�0�_���a��o�%��8Tq�=Ҋ6U ���`�r s��f�u?�c�hb�#���L>4����CUs��CC7�cala��F�C!xժ?�$�sAu��dp�+���[��j��7Ŝ%Ae�!pmY�TY,�xr�h���G�Ue�N�˭2r�/��W��L���e��J1r�Ĭ5���s>�o�㎶�������T��-������Jkd+�*|��,u�Jy�Z�M����R�i��wx�g?"�9Fj	�� �q��G63�q�w����{qjE�&��P�!L#��^��_~���gf64jh���F��(��6br��mD�H��]sE0KǑVj4���	UsY�=j���r�t}L��9�ť��U�$Ǔ��4U�A������El3Aґ���tA* � AW����F֪xڛ��\
�g��~���R����8�(��@\�}3`���E����gRh��H:-�b�t��J��I�!�&�11��C�)$ģ�PF���8���hG��JH�L�tcJ�h���_zz��j�r���T��9C�C�Wv�L[�x�:����P��3l������w�\C.g�1W�O�� fQ���4�"��]C��n�jn:����.Ȓ�j��r�s�1G���@ ��o�$E&Q�6��p��>FK����7�����i�:��K�'5OQE�bh�Ë�e?<^�c����8�>�2�m�?��Nm�=s�B�����=j<���P�$�ن���/9�i
3���^� G�&� �����UNu�Y�xpQl�\LE"�?��s�<�)T�:m!VX�Og^ �e��>��bp�\c��j5��~�Hc!��3�/1�=���L�Q�n2��}P.Τq�:�)Wr�ɠ��c�"�\�h�?��c�i'-��9W�o`]�a���h&�˻3;�烍�t��X��9���3�C� �hN�o��I���)�e���E|�u�0/fB�?z�h�Y1����0ۂ'�y�k'�bi%�N�^O�x�٢�ȟ�|���4k�4�w��{�0�ہl����ط�hQ���ʹ�ŧ���3x�$#h!����oOx]�.!+-���o���K����! ��KEx����v |!���ra���F|��'z�w������C�I 44�\z�ݨϜV=t�<}��`v�m�_����`���m$Z0܂�4|*]���嗠sD*I�/0�"$�%6�����X�*J]Le� �K�&�b �Uރ$:�Gv��h�e�'����������^yp2���p�*a�s���3	rC�
�w�R�eGG+I����&��µwgQ��n�&���9�v}�S��z��ǏR�i0�u�\����_B����=��F�4p�t��v�T��q�"���r�k�|~�a4�V�p-:mL�d �
�+�&�Vuh[}����Jp,����}��G��P��/����|�;^��bG��eu"�zNe�������!|ϻ�Hnf`YF��!.���c����#���c���4�Y*���K�.������n׳��%E}�`����K?���Ѻ/J�D��U�R��8�R५7�A'�>��!�LT�9��)liI��!�j��HE�Q) ���h�j�,�$ql����l��2��Ӂf����[42tt�'6��3���O��p
��w�)�yb�F�ޞ��'�}���UF���|}��8m�s}�A@�/L���,D�%��)F0v���DOs��.GW��ix7۹�%Vop��s�(1[�)��&��5��[B���w�)FѢ8L<M���cS{
��g?�^h�ִ��r÷��8��RѤ>��7p4�B�ڤ���`�#�c����Fj��Pw���}<|r�V������{��b�k3��&M�������l��#�:�����xIR����qTӺ��sr��� �� l#"�h��.��GRP���u"�h�w��tK��EU���ef�L "w]�qj���y��L �c�/��p�/�|�%^��iWx9��/��n��C���/��>)~]�^<�L�JY`��ĔP�|̾��(#W�Ҽ�sԧ{��q�d�_�ɵ����GCy�r�ꏃ�X�w>5���c�5�F.�c���p���	)?U}:/"ӇJK%Qj����5�ݔ� ��#C6�	Aj�_�N��+�D�cW�r0f����R@�����.�N�O[�H�X���G.Ӓ�C�NI���n`���K��4�O����!?Oa��2������QV���k�1UiI�c����Uƺ�K�������LP3��V�\���k��%��[��e�t�|�Io6��ь�b���ʋ`���:_,��3���LĿ���ϳ����L�L7�7R�G�-�*����uy؃��B�4d�u��p |��r�n���LpJ�@x���Tn)Lڮ�a�r����y�~e�k �I`in�?���8A�1���Ŝƪ6IU��� �c�Rנ�1O�a�\�ւ�ٞ����w-�N뇻�3�*���{��s��� ���6��Zs���a|��������|��(S����6J��S�84��0M$�͘դΩ�����*�R�@
Yr����7	��]F
q��5�S9�w	,G��鿂���� 5?��͚#��.���O�YW���C�k�8�2^�vf؈2�_��=���fQ��h>�r���+�MO8.���R���=�������3�4V��k9�{5A2 ���>�89ߎ����+:���{q�̡}K	����n�Qr�;w�n�v��\��	 -�6�����:	�>n��X"�J�F���
ۈ�qF�L����~ '1�l�8(H�]�>�����|��԰�P��@|�x�����@��~�1�OVzCyL:~���[�Gh��V>,�\:s��j��h��C���qL��ۧL],/�L}7��0�����ldt�܋5�u�j2}�g�:�gSI��2��=ͼ��_����l��2�V�Q�R4!��ͤ��Z����#�O�^@�m�{D��>Eٰ�w�*�f����g�3�ZG	ٚ�+`;{������$B�v�r{-���f~v�����n
�jPT`V�}�Q�z;
�����0}��Ұ��d� �i�W��_�aE�*u� ��8(X��%v7�:�	V�yV�[�ъSE�	c�C���n�/�6]��0v�����b�a�FN���o_˥�f�ͤ'�wT{]�|9�c�x�uK��h�+�|�U�D�������1���	]����gĐ�񦖬Su����ՎKģ1�Nb(���\��d�z6EQLT��y`y�'Z0�낼C0��~.T<�w,f������t�D��'�����3��m�x��YCa3����.5t��1NE(5,��K���e�<Aq����B��h�\&β̆��bH�"q˒|�vC~�T�/$˫�G�
Rb�R���>H�����S�%��IR����F�X�j� :W��i<Iu��V�?��`p�=�qt`�3[�c���R%�|�AL�%��>�� �m|��#}hO��$bg�UE}����,ѐ��7�O�)�#�G��-�\}�^��q7K��˧2��ZU;��]1h�b�c�n�As��\�u$��{������*2a[�$tB����lB��ߣ�,����7����)*�t+��_�q;Y1 1�܀�dh�kdJ��A�]�M�g8]��B�G�v�n��m�N�	��n����F]1E��J��/��	�H�!LQ�V/�� �^+ne/�W]/]�j}=sUs����������5/�Ie��u ��[�0�����Mc!�ܤ'z6u��$@��{����Y��Qz�U�E�|y�@��Ռ����*Wk�eUz���s\�
�� f�<�M���Gd��NP�.`�Q�$��c�Ac� ̽�O7�>~)}���$��B����%c��N���m���$�O/I��k���>��H��r������ڃh���2�|��Oz���J{tB�>�u�������1����"�5��wK4m�rO
E�۠[>���t��kε�8��`��%,�s�D� W�t���Q�j�5����[�ȵ�7!F�=��#46Ԑ���Y�w80�n�L��"�����g�l�����'����k��M<i�<@����I��nm��}��֫��'����ϣ�O|MS:
ȡ�=�DU��PG�]i���U';E�G`�@b\����R4y���-c�0�j9������^ 7�u4\������?�[͑Z'.�Y��&1�tXۃ�jw�mh��+z��xD��������[�h���O�`���Q�������g�E��KY�P�T�\�%�P�oNo2�U���;�Hǁɉ��V�0�J�
V�'��t��Ij<>�=r?����~�n��y�x��ng3��'��q��o���:��\�6��l9��kv�1�Ye��t�`���ｿ�xƾh�N�9x�e���~���3�g�:`8������d#Bƺ�KI������k�	a�PF��i%{gT6��m?"Z���V�h>O������R)t���|���>������X�ܹ�E���[C�� ,�&$s�N]I_\U��1���#C��*��+m��xE^��:Qb���URfwC-'� E5<Y�]_=��uw�������X*� �����������m��.c₌h��U;�̃B8��k��mЀ��0|V 5���&�(��H���"-�7�_�
�4'��%�m2�Dn�+�`|d�t�x��c�m�I��u�-,�n�4Z�,T����	�� 4���LIR��m��`��ď�|�]KR]�^+=8P2}�xW�� ��;)���Q���j�-Y1��\l��EHf��-*�O6�ü��͑�O��1��6�Oȯ�=�\��i[�����Ej��N{����8.*뒅� �4�u�D��b����y��-H�.�|�4W������d�4H��&��T?�"2
'x|�!�*�����W%8��U4W��_j��ҽ�n�M1�}��3����;��Qc�w@�*#�ǈ��"�"j߸�A
A	to�"P�R�M.0�PA���l]���l!sQ��_ߒ���{�4��p��:v��\�sZ褍ͯ�n]
��(�;D�
%�ʢJ5Ǘȼ�ɒ���UB�)�d��+��(��ݷ�s(�"�b2V#���
D��>��栁���c6Cd�= @}h8��9Ja,"���ߢK�ͼ���m�	�����2��G}_�@C�S�H��%�$K�MU9�\9�f*�%�1O4�a\�P���@�h�7�ʬ����BR)�R�: �U!W�G#
=K�6����&O����{�3�>���(�ˌ��=�d����2�x���rĜ����+_ƥ�&�Ld�6���$R�W��ŃH1!����P��
����8̨^
�ԁ���PF�:ÚdW����0T��8=��'`������O�O�ߐ�#�߼Y&�P�O8�F F+9!�ح���1��0�X�8	>��ں����6R�a���w��~L!wv�I��v(���I�>�A{Y����5ɏ+DgPT��(����U~Ӂ��}�lmE�Qض��\ؠ�.g��	�jp#aW(�$_�07�Y�����2g�H����P�0y��~AG���*Ŗ���UU��^!��2�����{�2���]��jΚ_�(3 RyTy���j_������Y�]fk'��~*�Q�7:�<�o�F�W�_�l�ȑ:�@e��{��ѯ#ב����K��D���(��e�ȁ�f�3���O�t�\�0��YB}
L,�ᙙ~����'���Z�qX��MS��?yz� ����۷�N�_a���=K���L�'k����]f'��Q�D�0vq^�����-�9J�_M�� ����$hQ����l��`-Sh�fT�m�%ɺ�gT�MW_I9i[��%t�7��5�+��&�7����:MKӧ�MB�R�;�W�~&�$�!d����l�MU��1M�0B�_Ԟ|��[OS�щm)��M��C���ǭ���b�D"�33e6�ܲ2�ʰ�?�?&
=�H?���`hT��a�:Τԣ��>�'Ҩ;�OY+��8�C�֦�~%L��QW,F}!����mmGQ��ِ*W���cG\g?�^�4���������[P�.�)���j�Fh�S�
���k��F8��Zac��#���u��ӓ/#�o������Sa���H�����{�;�GO%��$�1t�H�$%]�͎�vr��W|�б!�ؾ�ۯ��G��L�����T&�����KR���C�~aA����:�%��i��?GUM�Y�ߣH���?�S�I�/��a��� \Qv��r1���8�	�j6�b�FM4���K�W���_{Q�$�:���-#��0;�m��l:v��z��*9��>x
��i�!���N�v�JS�,��ƛ�9q0��(x����`W���/��pg�s�i��J?̏o�w�&�`KZ�dW��M��Q�Dd�Wȷ5'l�9���zg̅D�fC�Ȃ�ߠ��~`���ќ,
#�sJ�^#�(�9�i�K���~v���kl0��ahmV��5T\\w���W�
��U5u�B���KO�� �:T��qĈ�KHQ��~]r�y�*q�`�
, Y��
��=���@�w�p9�g�B�����J0o�=�E���@T!i��il��N���M��*���e������.�׌=M�3����#��a+@�b9[�����3TX���� k*��x@�����0��7�m00c^�uf�J`�!g�=�] ��B�VhLubJB��l�t�]
	o�=e�t��Q ۝A��:��.��j��Tu,5U6�eiӴ�t�+���03�O*��9�g�zl�1;��?k��Nٯ�Թk����tKdk�e0CQ��E��$��U9A���OZͮ�� ᑓtȂ���#���9?B�OY�R�gz��0A��'����Y-�~먐���9]�K:n/����)�
��>�k��&|�1��� �~q�x���_�wC�7�6�/�"�-��^�Y$�R�@��J�-���Y#iPˠ��.U   h-�M�| ���s����g�    YZ