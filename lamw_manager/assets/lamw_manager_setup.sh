#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1602316796"
MD5="aabb12a633829712312b0071392e5229"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20680"
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
	echo Date of packaging: Mon Mar  2 22:12:17 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j�پo
���B�4NB�EOH��b\����������#�m'��e���7�/��O\������l�Y�7��;��)���,ۻd���:�e!��wh�޻��(�b�����?�R�y*��c�m@V���B�fHTX��!�m�_hTL���]A����L|�N�RX��1%l�y�i�}dL�#�˫&a����|`�|g���ۦ���B�'b��{���Y.OwJ(�$�8g���ܐu���W�,u�w�#$J�'�����v�Kn���	(�;������� ��X)��^�
`������< �ܿt���`3�ü�����LtO�}���?�=-���s���F�b)�У�_�ff] g�������%ׯ��2FC���� ��&���Ph��X�S�D0��]Ȟ�/BZ�i[�OY��٩!��܌�Fa�XFD�PE��{W�/�a�ݭ�Y�N��C��t�\�	I�r}����;˷��0�ڧAhŊ"������LxK��,�K�]Y�]�!�����Ur�swuGp�}77�ٯ[:F���θ٘s"}�f������6��W� �a3!{�Q]eA��+T�2X�X-�xDI���7�݂'Uwgn��>�
���3�%b��q�#�7%�#��d�t��ysT-dn/��z.�(��"�q��+AU7(��+vk�DT2�� ��X�&�O7d�)�^HͰ�r�����������L@���1.��ZXvM��)S�>��*�F�2��vl�@#��C�vtt� ������5�/O�Z���|.(�Ha���Q��������vnVٚۑ{�v�B��?k>���4%)2&�GT�U������N��A�6Bި��68;2�)��W�t�G��^5�x��,��$�Q;d��E��0���i�U/�F�s�3�Yf�ly(�3E�Vq$��>|M���r�%���])�+��%&yV��0T���w�֕�OM�V	�uT'|�~$[I�n�G���glUl����V$���^�`���PX^?��	
o�xgx�C(ܗ��_�� �rMz�d�M�[�\��N�ի����%i"�͈J��E��]���\���og��=������~������F����C��b���66T	e��x0��]V�wٜ�%o�zZ���"���h���>��ˆM5	��$���$������1L������I}$ �N	C�βeK7��w\�'�PU;���d��v�C)}��gQ}l�Fe���d[۔���^)�Y7����ɡץ��8)U��	Kx��6j��v�ꢂMq���?O�T�_5����_�&_�y�Z����,���,Иi�2��w��������D�g�H"�kg�BךzG�JJ��ƿm�m�^������Nd�԰R�ǵ��'3d�_4|�|�a0�%7C�Y�^)���1�$�`�Xak��K"-9�4[�C� _-=����kRn�d�S��5�{A���#��-�˦P_��022h���(����\��h�+.������D�����1`}�� �'�LI߱ �)�+���j��$����I��rY�x��R���Ͻ��Y�i~��g��<�}��߂���/�v�Ժ���'ފ���5�u��BG�M��l����F4�Xp��T^����'g��@�)���z���htN�Ł���#�4�ں�O
�+�F9�x����UӐ4P5���T�j�1��"�D���\l�mg(p����,І,�?�(��g�Ȩ�IJ�"ͯ߅m��L:�q����9(j�㿋��9U'��/�i�^�x[���/�5�Ȫu�W�Ҧ�t�B��"G�(��4���ד��7�4k��s:�&�L�E�<�R������E�u�G�!�m��"�h>UL�@ܐ�me�C��QHU�������:,v8>�[Rz��(#��\:�5΋5VK����K���������l)��vG���n\�h4�wlz�&�6�=L�DG/�Z�:��ϡ]J�;.�4=J��0�3���Z��;b�wY�TM͕������¬�?�6!�j�fft�$I�nu4�������W΅֎���n���{��;������9���)�hA�x��,�y:�6�4>��T�ͬ?�H{�ԝ,`�2�)�ch[f�jA��R��&���3�mc;���Uj�a������7迍�Ib�>�^�RL�Y��i�ێ��^_~}�l(U���^Y�I� 뱫�|z=Q�f�����[ңF��dLp,�Y���塊�Ga��ӈf��0X(�"�_�H�<e	,#茣���V~3�*"8���C&Y��Z�2x&�+�W�x��ۍ����d�a�es���Z4Ko�`��̭P�p����\@��-��lV��g5����ND%�'� n�q���k��F����J6q�u�7dr�������¤a�~r�䮛�5 B�K8��
��pp\�~���}�O��p���Y��ޖ��*	�{Rk�Y'�?��z��ϳ{��`=LW� ��s�5~-s�Q*�6���J��SpO7�zL�ϳH�����+�E5Փ<#0�BK�y�d�N�W�1�nLd��YL�y=���Y����
k��K���-��:gD���oQg@�+����v���w�滁�%�dg~��V���5��������Te��Ԓ�av���q��P~s�/�L�K�\ny4�5X�S�p�w;V�"0Tv�MM�b=��@�2*�$�oB�.\�uO�\&��ꉺ)� 8����z�@P�a��Λ�!R�ϙ� �i"슪���C/��m;��LJ�F$؂�����_~�$b�p��B����q�Tv��-�C���${Ur�(�:&Zz�ؖ���vgiSH��X�#��u.�c��ю-A	��y����f��&�{9P ��Rc�
��u�ί��YO�1�vϖ��7���#i!�~"�������0�m�X�$���G]�����<����ш1#�6[�� k�)���J��|��LՕ�VR�W��>�8�����yEܠ[�O�_9� Y;�,6U�U�niI.�i,z�R P�e�l5�*�3�N���C�7.KLU�w����Q�X���5�n�ө;[��2=�1rw������bR���:��/U2��9�Rb2@ޜ	�\��WI �BmV���*� "=#\����f<7诊�-�d��-�J�UE9�I:qu������
�����*�z�Wgh�~^�
V�%�q"�/G���5Ǻ���*ߓ��`���Āժ�����Z����߄[@�t�嫞ij�����t<z{uc�p��]��OqC���N����Nn,;T<����@��xv�>6{�f��a�}�ӇrL�Z�w���i��S��]G#�o�����o��⠵k�bT�Ω�r���w�^�p���7��I%i���,&Ri��(�!9c�oU![#:,�R!�B���)�!�'z*M��`�
𱴹��SIǬe��[�=
��f���|S�fLb^J� ���]V��|×����7|!=��&�N�H�	큞Fa�h���ϰǭ���H	0�m�oYp��e��{��愕	�J��[�|��ʺg�Ʒ�׺��V'��Ć��.�x��t���9Ƙ
1��>�}�dF.���~4�g�r�#��tr[KuiΣ���^���	M�x1��R���U,.����w����͙/D��rd�j_���K/4i����u�T57f|d�ն���G�[`��]$�<�p3d��т*���p:�?�&W̸�0Q$G ���I��@q=�/���0�"fT�� �9���/. �5
w�|�*,�%v������Q��������2O�X���g�=�<c�S�����T����W��b��L�A�Ex�\���Yt4�_Idf�#TI�)���G�(���6j��Ia[
�'��]r�����JJ��Q&��E�K��߮��	�j���Oy-�3h@��LV�F�Uyy˚�r$.~Ľ�m��]:��d���B�{��NP}f��2���py:�}�?�b'�:xw��
`YjLDܔ���(ӯG����C��T��ؗ��{x�1�52��#���B��D�W�Qc�xH����Z�bPh�6�%5�Ls�l�#�Sb(�jT�6 ��Ҹ�$12`��ڧ�T���MO��*-V 9\T���Z��(ǃ���J¨�W��R��Z��m�-�a���*��=x�yN<y�b�6z�|�ޚ��A��묅��k���4��#O�tI�i�����}Y�-�-8�ߩ�Fxm��6�����ɑ�=byrM�Gf�cVE=1]�ER����|'यP_�^?�R��~��+@a_�n��&K�y�ߣ���J\��<���3��]$_<<] q�ɼjp��A缚I�m���USxg'�.hثR<W�^)����#� ;c-�kh��[׽�{�-v�M���xa�&����i@V���$�w��.�TZP�ٖ�ù4��9Om% ��u��o�Ƅ93"�km�MO����<�A���׽ʆK��|����o�g�9?�5�@�W$��$|J�(Py_]w�!��4ܖ�I6�<[��u+�[qP��\t��(cF�'�S�f�}����rO�q�]z��u�3E�뮮�_S
�����R�.֢I�:�b"I_���n�>E��P��]��H�r�d�P��G_^1k��8wjT��e-����wX���ـ"���z<n���h��$xxn�D���̓�Z	E�����������n���p��nX݇k�g�kG����%��8/���zT�#�ז~g�K-"�tm��c�WJ�����v�����"�% ��	W�����It�@���d�s��%�Ѹ�3���	�®��>���J�7�����J(~�����Ճ����`㔣q���[M('0�C���q�^�?n�0G�,�.�aX�Li7��y�!%��_���1;�?�_Gӿ|0�7��b9~>��:�ƣ7\J$	��ܺp"�KJ#1R��n�����,ؓ%.��k{*P'교M���G����aë:ʕ�Ż����~��\�9�R��	��|r�K�,_�
��Dj�˟X]gsʈ��E�J���M�Q~� ��1�Ԙ��4���W���}x��U��b'�=3���*�\��L�0�>ل���j+BZ�[Z�l\?�4kb��:�(�u� ������U̓���:�3H��~��_��J��!C��!�Nh}^��ܑ�_�aV_m�.��{����>j�'���$�h|:Dq�g&��2T�$4/�G[wp�^
|����Ž^��4���f�R+�Jj��3�s:Ǿi��Y��������W<�����ݽ��74��]�B,�c݊k�_e(��Y�"4]�c��� `�:��v�����8��P�	�x�Хjm#��}���ױ�6u2�D���U#���҈���p��1�}e�;�1�I��v8"ë������14.�'����Sj�w肗��U�!B���+E7��۲�v�4�*I2�"���[l��+��P՝G�e��_u��8!�$�DJ��j��/j}.��Ǐ�΀�? R���V	�c���j��J9��	Ǫ�� �Р�v����3�	J�m7��ʒ����|�O���՛�*�Z�Zk��t���8(YoR�v�E����{����h�f�@V���e�`���_�ݰ�	Z����K?�z�E����%`����VX.��f�f2�h��h�} M��
��C+��fϭ\6�2O�Ɇ��X4!@���R;���뒵��Ї<���9���H&�+��eq(����j���K�S�U��?`٥���vAp��"լLBH�$�}��Ơ�4 ����Ax��G'ⴈ�O%p���T[�H[po4�ʓ��?x�4[��E����0��?JVh��(Nf|�*�h�D�	�G��_xV�gq�],���_ؑ�AG��R4��ڮ5{�q=qy�\z�''�Y���xE�[YEW� �� �Jć��c�y�Ou�ʳ
w(SHH���3xh_�	���tX4�斾QG�XXc7p0Y��pQ�ً�������������(7��j$`�F�&���9K��X�	 ��L:�Ct�x���78j͗�c��^>Y�l y�8��Ăr�wV<�����{O"O�b�I&���D�f�Q��H,������D�4�A^��1c��	p�t�Ab�,Y62�{`��h�V|*���Z6������)��2��f�Ns����8Gp?qc���c(5�<�|��"v~��/�z �	~�}>6��׃J��ݙ=���'j����~B�N�hnK/����h7n74���0-t5��� L������{o��7������2k�F)�CgՏ'rk�$*�DyM.��Kf��4��n��v�G&`kwL'��>�ئ��s�x��h�,�B�ۥ֋!������C%��D�6-�eۯPA�<%/ə��A������U�=7��~��bz1��o�_��I܅��G,B��^v��*]B�g�2�;���5l�b��M]oU�s��LY�(f*�
�p�����?t�3W>(�'�#AL��:���6� �����ϓ"A�H��@)2�������eO��$�/���r�nb����V��� ��M��R���":�I�UE��2��y�d��5�L1J�L�Ú�,(�����g�k���ۘ.1Oȸ�}y��,3�2�҇{�sE���N�I��Km��j�'ܳ�-�j��˴jv_��n�n�`S���dW��^TV~�-�jϨ�z������[y߉F�"��5�*Ha�4�5`6��\OxR���|�&���N\��N-:�~衾
�҂"���PMg`Z�<Yz�<L����u�aHa��vI�@���������e�Cx962l�F�!�����lK�!@�v"]|�ZF�R-����+��8bޯ$�pEF'hi�;x��]�7[��(���]��27�0ulF���d�� ��y�L�*�{�*tң���dq�h~!�7��ma#�����f�S��3�i��Կ)���te	�0���'��cuְ�ū�&�s|�1��Y6�����Q��,���)������y58*�N��J��d}a���`|]��{����/	�<��`�����o���K��@�ݎ�,��˭ܩ�����Pb #f.�^.4�l_�.�D̚�V��3^|�a?�
:��k���p�{X��Q�Η�'O
~[=膔����v�qr��Y�~��k߈�{.��v�2$D�h����F�"J�yk&��ƿ?k�ɬ���r�}.Q�!m6��\�X�;��=W	�q���8�8iWx���EM~ME�AE�cn!f�����ijJz"[�Փ��6�8�1�.Wg^�\��N6�ԕ$�����w�f[
c`M?��~��+*1���l�H=�4"�MU�$�
��+7n�{��Yn�`�'�#�_�wF���9���S��Ǯĕ�G�b�������� �g�7'��*n�Bz�l�#1�b|R�ji�Gn�d����J!���@1�&u��_��KT�� ��ӵ+�CG�[�|�Z�}�0�x�?� ��o�p0��<|�[ڂ���7	<�Ag�p��}sAiB���Ĺ<���r㔏u�1��h6����G����� �v '|:��o�O��|E��z|_�sAH���JV0�$��)|�ƈ|�Y$\˂Ai�[xh��7~��2A���.��W��^8]6�Z䍪��~��.��(��G�n����Pk���~ĺ,eC��Ƙ�!8�n�	p�.�߱��Ah���V�h�Os��Q˹`��3T�b��1�r	��.0b��"p����%8���z��қ�-�n�g4.��E�|8VD���2mJ�f�o�	+�=�a<m�B1_a&��zL���C�1&]E	n?��v�A(�{��ٶzǏ"��ox�n���e�Cq�*iઃ�g���J�&93���C���~���� dm�N=$�.LёH��:�K�.֢�J�y���������Cܑ�-��Ν-�
�'�H��.ERf���b8$xb���N?�snΗ��:�T1�:�=<��@�9�j)ʟH���H�Ͻ�W
�����D]�;�.����B+X�^��%��3)�=�Fx/&��>�����zn�`�Ԥ�v(#m�V4���S���77��x�@� �3>��%&k��[�2�m��g����S;
����h:{'����4�]�Ioٙ���d�T�R�Yo� f�D��~�b���2_#qU�����d���0�ߊWr����>Ux|B���0�W�W�?�96��&��n�#%#����8����Ř�L��p��T�.
������^{���s�4O���g̦�{"ew1�;L뛝����ϡ'^t[$~Y^�~3,c�#���qf�#��C���g���{�x�Z�@̩~�i��m�F�+*aM�Y�L+���n���I%�
�B���/1wÀ'�!�kI��7BtЮ�6(S�C���=�55K̡ت�n�+��.���.#��5Pgi�"�2��ڝo�ܵI237r���l'q<�<�s�7&�����\&���b�K���|wb�����A~���2��4�D��jZ�Zg�{���<�h�w��!k'���aTJM�8~�$;F�c��9�cm.�������HҴ���Z�K�G~�]I��4����!9��C�������`��܏3��p:}"9����h)��lw=��k3�X��,���8�݊o�c�_���ua�䮔ʲ�� h�&�]�@�E�g��s��Ac���6v,/{˧��h�>	�3��u�(�#��4�V�f��	���0��G�f��:?���� H�h24]�)�E���K,�K��7W���4�^i��?�-ksj��ȝ��i ���@�( B@@g�+�2:E�6wg��T1i��PW��a�q������p�����\��X}�c6�h�۱YxU�>�[�6r��ˮI�Q!����"nY�o�K���I��f!:��.ۇ�a���!q�ںH��d`���C#\����P�)nD�b��A�(B�d�af��^�
/��A�xT!�7��fw��5��=x���=2��}�mwi-sM$`�l�(��o
r
ۢ�VN��b���* t�3���*�wy��������2�~%$ײ�DA,�4F�������Pݠ�
�:z�$
���Cb�
���w��������ʌb���1p���Z�DO��5d2��n�pϪټ��IȌ=�����9��W�@���Ol,�d�2+Av��l�<'{���諧�jT|�I���"��	ĖR�����Ո�Y8!J�~��Rk��Ǚ�d�1�M���/B�X�F��WP��J"�j[ k�RΟ�WP�tx�+�IG��pP7�*qŲ3��j�"a1��O��6^���(Q��S�B�8�Ψi��J�����+ �N�;�X�c�0�M]��&����nN��(U��/��'*"�1�71r�7�W��?�iM{���nQޘ�]�h��a��n<x���$��l.^����C:sH����f����{��nIVV���4��*�J�-�?���*��`H|6=���>���	5��P��{{��8�jeօg������/_��(�RW��n>�@�'/���YCxX(9������Dhם!�H��"7>�E�B���I�U����,�:[s8���9���&���k�S�̪q:����(��"��r��M��7��[�3�ᮬ$�=	�����G�O�T�H��?�K��9�z;o0�YE@�s�}e�#u\y�?f�C׾�ġ�tU�*Vc���D�A} �Sk`�v�L�A�l{�U�i���Ы	;��ٍ�$i9�����_�`j��8��U�!��1�&�f��6���rN�E�������"+D�u��P���q WJ���h�M��\h�a��8g� H��(��������f���m��Uc�٠��;��H�@��^��@Y�=�߆�C@�賖Δ
@���Z�����n2��Ⱦ�m-�+w^ģ�	����b��]�)�Vg�e
g���L�.Ʉ��(���@�Ў���a�h���~�l?T�l�����=���E�,r{0� R��L4kI��P	�� �K�F2m�!����B6s"Q2��'k 2=���l�\	S�� �i��%��y�+��d"���v�5W�L�p��%�~_ߊ���~;n�@�܆w���q���AjʳZOL����C�4�8қ}a��M�N��F$Ԅl��2x��ݸ+M����*WV�`�SH\CԅͿ>�\����^�j`�c�k�oK�F��6��G��DV+Ϊ�����V��G�D�o��h�j��9o�|?1f\bE��9-ؔ�e�i4��"�" �cX@,S�0�%˪U�Ԡ��;=�I��yaI�=t.}Y���n�_�)^��ɒ[��U�����x�����'b$5f �R��S2������y!N�/$���.dz�J���vGd]��N�g�G��:����n[�"W/A�
�E����߁���[���n[V"�!@vIxF�Z��M	��j��uV-�+�<�u��˝3�e�]Z
 ��!TjL'ev@�G�3٧7?���7W#�^� &:y��> 9��7�~qyU���}:gC&�-Q�3(���q���C�`\h�b.9����b�r[<����V خ�@iqϹ�@�����ԋۗ�_��h*�P�=�ٜz,��c�r��Uv�et����$��.���މ�A�f�?��IZK[)� ;�k���sk�%��T��&���%v�:ل9���a릵�9��VH]��EXz�E�i�!`-��j��n�݌
�!�(�͐�@X�<G;����I�:���w.v������-�3N�L<�\x"&|�ynȆ�x}���6Ay�=���)b�`���R($������nC���-��*x�����)��2�p��湗����\N�Sq;ߘE�o7y�Ԕ�q@=���8e��H���{��1J�Rh'ʳ��k8}�����|���qm�;-�]�5�39�_�.�ZTn�t~n���0�t�YOs\9��m���!et���wk�	�祭;�[������G4d��O���;pT��5A4*�@H����;;č"Z�DQ�Y�|��g���ED���j�Cʯ��5)�O��*,ԧyx���,����d)or#�L����\Rݶ6�r&P��#-����\�p�ߪ���h�s
O0EP	N] ����NX�����{B2?�����6��1��x�q��t���hԞ͋�;���xp���6с#ބ2�.E9)�)b#�c�F*hE��U��7��d#�m0#TRc��"����V���{,'s�G�
�q9px#�V"��wh�� �qW@,�����f���i:A��l6L4�b�k��v��|v�� ��uRv�"AT�G����Q�}���B���']h�e��2��8v����U�\:�~y�{�p�ч�G��O܉u��}{���Hpnsa����5�1�����&����	Rϛ�{	q!-o��^�ދ���������o�g)�yu�d���ű���H�}�F/qBY��Fg���Zn�`Ʊ�їK(��n
�w��������)�.��k�����6r�YL��nb���f�S��u�\9&����P���,*����$��GL�G��_�=ԺP֤U�hV�(��4�Ȓ)u2sNJ�)�Q����������с�)�[�(�FX2ZŨ��k�>_�Nh1��7�����������u�p%�PQ��x�����r�a�y���{b����W���^��1Z���:���x�g��{�'K����s��
.�5������h	��dpR�B�6���*�<��w�>D~���8����S\�>�����Jb���qD|��*�˫tU�o�X���3����P��Y����!�CS�;�
��U�i��wO^�D�ȼ:��_*sQ���u��$d|nE6e�C��#���O.0TrV\�� �c����%@=_l�u�܅}�Y%��b͐��k�ч:LO?v�ي�x^Q�%��][G��;���3�ٷqf���6�%g!yt�X��QK#g�Kz*a�;[=bǓ�Io��8���0�Ѵ0�'��l���W��:�9��%�G
w�"�z;>;09>�Ō�]�"�N�/�U�"�_��j	�k
��A$�Q��<������H^����� J������ *l
\wy��檙��>�KBh�d���ݡq1��=��j�+�����e�|�!��29��w�J��pn%ȣ>i:�}{�KD�O����i:����������B�H��������mZq%3�!7vǖ8U8|�EC�l=��`��i�Fj&B�A^�
��-y\���ۇ�o\K	��E�k�1Od㰕=QU|��p�y
�U/|��g�\4���:�\w5E�����O[��-�O��_T�ʞ�b�&ī�g��J�MBi�	y�6e)ո����~/����2�^%��D�mL����l��c�6V,&����6�#g���9�@�;d�
�Pӝw�%�v����Jd~
e�V�����.�	J��9:����|=d>�"Z�c��ʟ������V(�5$ >d����{αQ�tNJ��.��Ϧmʄ� �2�&4����O��nM4FA@1K{��Ｂ��h68�pP��_�2��Ya�랈VO5Y�������L+�#�/P�b��L򱱢g\P�$��P�>!�~$]l�~)�V0�IfPH���d�?5��D�{6�@�N�go�r0��>e�zd�@PCDrg�7���g����J�p4��0�
񶿠;W)��'IS��rT@П=��xâ)��k<�
K�ڭ�!HJQ�sB�Ce)���i�*�iÏ"���y�y(L�����>0��ߚ-�-�}H���):��v\��u+�¥�gbn�|�8;;���']�# `>^�{���Z�)�3������[��E�B)��)y
���)��(���S�0/�|{�ď��e��g����M�sHJ���^*�� �H�zɅ���N����r顪�qn��m�)�[˻ȓ���J��ᣚ�>UI%kaE�e�[�+�>�Qo� k�״�^@�fE����X��]�����hŗ�J�X]S�V���شGv�Gc��D��@���]�ϟ��蠨���I�����7�u!̐�u(�B�b'��Uޱ�`DFo��t3N�Sn�-	��hw�X��"���7+н\�'r�����̠%�~�01J�����8�ߍ�0�g&=w�&����K�����rv�w��E��2GK�|	};��2�A��ƈ�S�z�R�%~#\��Ү3N�̷��Yc]
�͜t_�8be�8t����y
�Kiv�@G��M�ԍ��yP�y�Jή�X��Ea�Y��{��P�����H����{`/��|$��p�%����K~0��p/��GhR��/y���<hk�����z��SSQ<s��9abg�����I��mS��Ɛ$/=$7���T�����2���K���D<&���C�@��nOZ�A��z�د#0��D�n��|Z=��cK��bo��p�G�|�4����ܚ�^�5B��]Y�+�O�����sz��7W5��
���\s���5j�{���$~U�j�{��[�>�E��cX��tDB{�AxS�s\�g
V��]�l��E_1:%d�Lt�Lǳ�o'��μ�0i�&�k-�����k��䡯
��_
�苚��B/c�Wm8��_륦�\^k�����W{�RGQ������@W.iy�g�-Д����i7F��&���WC����+���3������K�r�,x����t���X�-�d�o� 'M���o�;]�
)Ͳ$�§&��E*��Ug���z����}�,}��@kg�䕽(}P����F�jL���EE&+��#_��Q߽]�q��h�^�M�۸����ګ���ځͿT�c�/A�'`��K b��֋�r[�]5C�y�/����A�^�cM�u��B����5��B<b�M$�H2B��5EQs.��4�5PO|�0����eF�U,p��=�4턓�9��f�!b��r_���<����ݹ5E�R�����"@ �g��&ʴ w2,�	�*��aIb��5�*����Ҟ��񯌑[ji9��\-��d$��'�M���
�=�w�n���5R �D�J�������Nw���1�Q�3�_y[x�~��ѿ���̅�ܕ���#�zEɋ�� <���'}�
Pn���LtR���ū�j���y����}!�-�zb�� �=�g~]��?0#�i�@S�)(��ćȯ"u#ٮ͏F�jN�Wd��_E�=݁�}�Op�G{kj�ޣ���ʩv:���K��O Y�Z}��CkmN֏O	��L"����i�o1�`� f!l�Az'?��l����ܿxv�4xNqã0hӟ?�S�֏&jߩ�)����C�k1��Hԣ�hV�l��mt�� ���=i�N����4>O�(�hZ�XO.X�4O�"�1��Sc������B�;&�U�m 6���cFl�Ԛ���q��M��h ��ң��2p�9|�L�:U�����̤�PG@
%@-��7l
��h4¿�ΈEn��\��8�%d̙���-(#B#�roD�R�a����pD�[M��G��[�7H:egLV���&� b��\Ow�o	fYx��Ql�c��Y�|��o>�ğp���`C���)ijep�v}lz�h�?���M�t�D���M��ܦ������hKA�A�G!z��D�R�"�˭税���3�P���<����N4�d�e��>��>4v�0��K�ovhcg�bXC�b�y�kӷ�Aw�k�<?r��D%�q��v��Ƴ���}��e��XS��;S���e��odQ���pY�z�[�����2<c")n�s�Z�V�17���~�\�Z��s�>U�gP���&�������aޗ�.�Pv�#��[�Y�8���1�ƚ��i�F��EAe���^CF�N��v���B�R�}pܭ/W����Kۇ��.? �(�&�M:0D��e��5;��W�(�6��&_����ޚ]��� �FU��(?5�X�ס���љgm�FS�mg���-m�}d�7�rZ���L+��+pY|MaJ��A�0)5�/���l�CCt���gn��Qi�{�NU��E�J�m ~��,v�)+�A��S��n�� sa�|���% �~��jĩ+���)�DX���ʁ 8�������SWUS��in�Jkl
Ê��<�G#��^G<q;%�,R�m<wu��_ B�I���X4�� \V`�\��ݿ��=m������T�]�?�sP_�Iv�RA�[���p�~��������<��7��(�G��ͬ2S�z��c&�}��)C����`���/���8�8R�!ry�G~��Et2�y_(%���QZy%Y�b���ų�d�'��ž�͈��f�CS�Lj�������"OK���=	%��\nDԚfշ@\�B�u4SJf�D�J�l�h�pH|�̼�z�e��B��e����@׽��r܁Ww)�TB����D�@����}O�˛6K_&&�ץ��H&{�K�u��Ï�����ȳVǂ�c���������p��O�/W��nN�������s�_7�e^q��6�l�5�EݝF��+V��|e�h�K�����FU��w�*���S�����4G��P@����y�$��k�O�G���R'>��5~��gc,�y�AZyi��ԓ0��tx�l� <Q��tUxxe��Lbo̽<*��Y���&�_Ҡ}�q����:�rW���}x�-Si�+߲Q�ɟ��3߷��z4�DN��H~�=WMg�.c��*
h!��[!=��v��k�(����R�����2������a��t6]��=ADV���q_�T3@��k̃�Ι�b�=:C^'UފȪ$��k!^�A-\ �O=�}uet�)M����ؼ!�M�&��l���Vk#�.�����8ˍ�o0�~S�Ă�jo��R�xg3�U��㚹ջl� mK^e#�)�T��!�Z���g���z5|�v�wqб7L �/��E����:Z��	Ei�Ju�S�Y�ԕW����M3�c֍�).��np�a�aIYxd���p(��v��Pe��$� ��ڐ��V&�e�ETG6�|%-�(�����)`lI�qo���w!H�zR�p�5f��f��ݾΈ��c����C�:�!��2fiQS�Ҵ�{�%����x�2��$�v�n�o	��W�#^
�]U�1m���x����o(�dF$�u�)���`�_/�����D��������Q�N�(F��� ����ο�)�!'Gc��ښ,�<@��U��A��l��@y�>i���\6�Dg�2�eR�U�h�C�৳r�omS�F���������م+piI��}�iy<3�Y��@��ʱ�耦+��w"�Qj�.k7���L��	(T�x��Kts�u�
~����;��'��
�?�5���U�u�,S�.?����Sי3k	��H��{��OYǝ�t-�Cۆ�tf\,m�A���I�~S����}�7���(�MI�����~3�w}�(�:�U<��Tv	k�h�>�q�9S^�^�|�yǁ R�I
	ԧE���}K(���K����;�4��ӧ�҈"�{G(�.JO���b�c����ਜ3�|d-k9 C$vOL�lWz���$��1�N���.�^����μeQ�2z�P�+�`�MZW��&�p����Ԫ-@HH2���RJ��b'�f)Mˇ�[\���>��"�3��A�����s\m'���K�f�WY�}wF�ƙPlF�%<��χ����9�s�-	e�1�[���!}<��#B�c��T0'��aqA#6���"*�aLJL� ��|�V
i��~\�ã^�U쎙{����A���͆-���u�ժ
��$O���d��o������P�}7ɨ�N��Iw��)�2�:�?S�nb�~��*��Y����55�a���!/U������Z+�^����qw�����v���t@˕����{{T��P[Q�{݈A�zӤǰj`�g�B���笽���c��:?;�X���(v ���0�Ӻ+g�J��Η�_�����5�=N��׬'&��ɳW]��^v{�/�o�$���6H��}u�+�d�ῃ�Ѐ�5�R��v������+��`������?r���؋�S���r`LC^�8V]N R��}���Z+l��9Ӓ�%���m���[@g��KH�����>�;��R�k�=�[.L�����식"���˝�_^���)b^�v�:�������#��d���Z��9����xjܠ=�Z��
� v��C��S�R)��t��.)F��K�g�˄�op<%��V�a)�b��A@�|N�^pu-���t����5+y�ḙ�����RT��>+_��ҏ��yU'��&]���"��`���p��5�>���k��N�j3��|�^����ײ����6�]"��c�p��l��Q�:[�n��0~��nԉ����Gtwg5} 旳)Д!��Z�w4�Y� Z���<��,c�[���xFr�:B�c>�O5I�P����T�ڢ�^(SE΂�ݰ7$g�C����}��e5eh�D���l�=Z�r;������d��U��P�y	s	�RF4�A¦M���VL�p�Xk4S�l���5{2�0_Øi�9�^���.e¡���Z�Ҷ�գ��W����Hdѻj�#�#��sV4I���<�����3>�Ae_��:�Ȩ��J���<b��#�l��Ŭ�t�� �7�(CR`J!N��D�"R� ��̎P�2Dާ�L>��F 溜�*gݯ�Q���n�����b�`�[��"���L0�Ж.#\9D�?il�J�HѶ�l�S�T�~>��v��%��J��^V���W`�e�y{�A/�E�ʽM�Y�nD?�Ռ��C�OA�X1B��y�9�����������A����M�B���Eci�2�6�[���f�kG�Ig�u�j�	�C�cR<۞Ǜ�}!6�s�	O���~s���ߢJ�AG�V0��{ կ�Z�@��K+w���7Z�ݝ>�>eP�q%��b;�[�����d��ԡ����_����zi�E��{��vm��q�D���IE��$q�`p-�����8�VBWT�Ec��x�E��u���v�S>ů�����I3}��[�E��d�X3��~�d�[�^�v�f2e�{rB����U����|H\�g��btB:�C�b�Mw�&3;�PZ�ۑ�`�]��9~mH�µ�*������5~�����ϒ�)	�n��[��~���!4��o�3�Gdz�I��OqΑ���lLO&�$��Q���*��)ff�y�L�lH��u�Z�4Д���C�}�.��a�BF"�*�Vj\�r�8��U�%�� �q��	]q7�NeFo�[����h���_HD��f-���?�����ݖyt��u>n�wN�L��m�c��#}e2z�c�����dD�*[���^�=�軼��#5���9s�XX?Q��Sߌ*`XR�gb$�-9o�_B9g��rK��~�rC��"r�=�rQ�xQ�	d m1q����!@`Η�NC��,�E��O���QE��s̞<|����S�{D����_�u�P�L�h<�tJ�4`�\��� aѹ*��W��ݯ���?$��9੫$����e>a�N ���/�;?Et��G� ���$Z�<?<6�t��tĵVY�h�:��K9�
�]�V�� +#�����A��	y|��P�4�C	�s�]I���*���I������y٫_����
>����~8�j�~��L�o[�Yם�<�-��7�N�EQ�ؒ�O�ZYB!�i� �q@KfgB�	�;UD�F��Ru����QwV+C&���vkd�����u���/=�����+hF�:[:0]8�����=P��=�e$2U�v�~L1��'�9"�|JƯӹ�wC �<��.�ߤ�v�@�9��i���ED۴��������A$�U�4�Zѵ��eb������_�KTF�	�%ؽ<YK����X�8��8w�37"��}��Gg?�w#!�����EY(՗�9D28Q@d�G��4�W-נw,�kj�/����/h�"U��v����F|e#��YS���ΠG�~f̑:�oY-�J{́S;��-�g$-y������E��H���o1����~|�|��)[��I��֕7��q��N��/�W���A�د�J��?�Y|�>׊f7���(#�8��	喻� z�c5�ҧv����Y-k_�L�� �R����n�������zҢ�_�,bD��%�PC���LE]D ���t.��{�z�k����6�=�X�dr��½uk㮈���7�VX���4�	�p�_.�iOA&���-#W��'�[���U)��#�fbį0�/^�j��ǆ�=�ru# x��[�9w�quj��Z����V^�m�!�8H�
�IΝ!���-��%�K���RDv�=L>K3a0,	o�-fYMRw�D3�E�x��%m�,�05�AT`V+��/��%)�6�LI�'�b?���8t��WV'�I������lg�q��M�s����I�������E�^�k*.Ձ���`r�)y�NT��eS`�&�weWg~_��ѡ�����O�Ë�c������8+b�c ��O����=��J5ʞ>��My���^��{�h��r�)�:��N%�dMx�6g7	<�\�]B��e5�_4���8����f+��%rK�0��Eޥ�������ܣ:%�cӡ�m�f���>���/bf7-���ӧ���y�G���o�^mA��A}�x��p)��+,�4=�|o�f5��Y'-��{�Qn�N��aAa����`�1�nk7���T�J��Sjl(_=�\��'Xdc%,��nN�O/{�3x�"t�)W ��]&�J�;�{�Grd�>�L���Ǡs�=���D�
��eޞHȒ,��E��?�+t��_Vz����pP��vAR,��bjzl-f�gG(N����"�E�-�H1�G�#	�@>q    >!��RuK �����dw��g�    YZ