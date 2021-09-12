#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2607082614"
MD5="955998eb6112f5763b43ee8456a765be"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23320"
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
	echo Date of packaging: Sun Sep 12 19:12:47 -03 2021
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
�7zXZ  �ִF !   �X���Z�] �}��1Dd]����P�t�D�G�3��D�Hd�sYwtr�=]ݝE�K��V|=�£��aº��^uY�(P�������,���6�DE:�_2���-�˜�]�pH��$-L�j��}��T�cj��SF"ą��DbSbA�C�z��dK�l49K����]�*����H���ۻm�,����I���s����MԵAK��������D���ovT�*��[Py0d�XعA��.C�fjU`��f�.�X�W�ʥ{�+fmE�e�nɳV(�mAF� R� ��iN�����>E���5*�gM�әR��Hs)xr{5)^��\-�E�-�(��P'��ET����k��s`6��������b�3�v�e#��UǽM���T�q���`[6�F>��n��"����W6^W�7�29�1�t/��fz4�c��e�k�Ė�^:N&Oۙ�8�w���O���Lt�]��AR���K��� �uL|�� ���'���*&F�+d�/�� �E}Ko���{�Y6v߅'R�zf=���2% X������t�T�p��gm�'&
+R���7�u !�h�ɟ��b���-�O�ԧIIկSt���um�9���#O��kD��А��QX��-�Q�dЊ���J�D�Ys��?7�c0���eg�V��Qך]><�k�
�4ر����x8`$��飬��!�{nܦ�n�*�h��:!���Z��Vc�TW=��ađ��G��Ϡ�10	K�������|��Rl���O6��������d7�L�y?�_ڱ��+Ih������1�潱���������̪#�Y�����b�EL�-*okD6���HG�DH�o4����g�E,�?'�8LiF��`|u%���E�ޢ�PN;��(�=ӕ�~�rm�:^Q�Җ'�xZ�6��)rQ~~���	���9��x3R*������K�V��zNX�x�����b��j��՗cػ�2��XM��ŏ��]b�v�rd~<s����B�.�Zm��~D��C�@w�G?��Uyo"'_\��!P����{� ���WaI���IhY߽�[v�2���~;<��K\i���ש�+@`3�N�lCɨ9�dn��\��1�uK�@�6HR\ޑ�a�y����Tg����B4�����<�BP�a@<���P8E߁R��$���lz�����g��C$#k��"���DM�R�t��Չ����G�n�1s�HT]D��(�__�eF5_pԮ��8ll\'�'�:���}/�L��p�%W�au|[I��.*A*�)��b�%,����#�3��~�o?�]��v����j������g���8EI?�DXr��~9|rچ��N�uC]7�%� *��2�p�)���)>G�T�_,��dJ�s���`�]u\!~��5ٻ�����\��ߵ��Eb�P� �\��C䪓�^�	dJ�Ӌ���FΥj�J�p���z_�@AfB6U5�������AdK}l��H-����Y�aAk���Vb �c���NS�Zn�o��B�v�fy"���r|U�^�x«�I*�hs;̼����q�M��Bl�ʫ�&�N���M���{a>Jc�{�4�L�8���=�c��(7W������y��}�`�<--e�h�a�5P��O���)C	�	v�Mxx�[��9�Э?�@��Eɟ�]#|�/�������t��C��?��)�R����CM)�M�QQsK+����z�l7�:ݻ��/�.T!Z��Ъ�����ʻ`�>�(�曐+`�sv�"6S�b� 䖕����_y5���y5�a�)�7�SIE�Ѕ�����Ώ���ѻ��	�W@�`�jM-��f���,|�4�{�8XOŝ|ɮ�Ѧ"��gq�E�Ǆ����{t�j*j�$��NgE�L�
��1��+;��s���J�MG��F��(ن]���{.о��r�~��|�q�	��
�kJE�7!�jm&���&R���ge��6���u��6�G���~b���0����d�K��=f�F���)Ѣj�v��2H��ʥfd���j�9�q�A� J[�X�ʒC�~�ɠ��e����q�1Xs�H�v%k1��]��з�F���
�S�?/l�KhN�4 �E�x��H �M���C �[��7��/bQ�]��+ TZN�n��H�`Y���!���j�����YX���p�y��5 �D|4b�=p����q�1i���\��������|������+��<�58��7_p����������ej7���?RM�X��{=�?Ha��MK �:�e�F�۵���"������6w��umqq��b�YRv2@�ؿ����n4�\#]͋羨�����P,��EK_�����%R���ׅl�>!����F�JQ��������T8�H����C����4I�\U���m1���3>� �g?��j�oJT�&�J�1��6���i(��T�)�C�T�@A������o��o�����I��_4m�����&*�>	$,�&A'r,�/gK�>>�p�Ns�b'���BP�(�Pk`��Cifr����!gd��+�������]l��!��(,�vw��]�/��a3�ν��И������Nf1�$���r��Pb�,�h�ڞ(�׾���L6k����� ]��2�I!$�� ��E���2o������j� ����۵���S�o+�#���#���T&$n��e�����҇5sv{�6�/��{���_p�ϐt�E_�%�kSj�S�o�,tZ�'%ɺ�soU�ۆS���+��7HT�+_���}	���W���,,��ޙg��w����q�ȁQ�P��E�;r����0�C0^f~+8y0�3=�!L9'*c}���0�/�n�A`;�k�1�OH�`�w���= O�sn��y0����h�����1{>\l1��!�sH��ꆽb��f�?��&�Z��Jj�R���Ɏ_�3��%��uQ�$���̺kA;�]e��7�{/�GL�Y�	��D�b|B�θ�E�@y��[6�;�ʱ�f'�����f���`UX���'��pycbu�y���L�}
��L���5a}�m2����"���(,0kXc�݄�@�(��}��C����ͪ\I�y;�8�t�<�ֳ	.A�4	A��x�'Ē��i������C_����ե���fX����dR��C�H���~P�&�
pj��.6��,�8@���0�z�S�2\�r(`zB Y��>AV{�+]�f�as]���OaU�^Ȭ�>5��l)mr�kjb��֔�er�
U\��;��,�{�y���#h��}�����}�#�o��f�&�Vj�£��1>���Rb~C����ˏ��G��e�ͪ�mU5Q� ��~c���XWw������_�[���(�c�T��!s�ph���� m���Lp]�'1��窡,K�<m��n���¾x.��Xe'컾�J�SZ��2�2���<�>���V̉)i�.���W+�D�HKJ8�.����[�Q4�.������֘��!�Lϥ�)���[|���( �+�>uӷ)�:W�j����3)���B͞)	�����o�S����Zj�V�}������3��o����մ�|n����&��1�Ri*p\#d�6]�G>�0G9�t���4�H
.�jI*޳N0S��2����T�v�1�%��{�����},g��� ���9RJ�2#lQG�+ 2>�vԇ>��X �w{'IDc��+�ݚ�Kd�بM�F*�xP�Jnń�=�ԐӸ/]& ��b��i(@j�)Ba,>?U��/�˝-2��iC�|�p���xM�=�9�^����b���A_�Qn��՚.IG�^]��a�k�@|�� a���H���
(|��|�ߩ5��D��l}Mg�S�36����i��j�̢Uh;��|CJ�3��m�H���]f_fSQ�q�-��_P'��m���>��{�#O��(j+�~����xa![_n�P�hr���?������d����c���ѱww槷��}m�������	մ���.H�Z��ǝ](ǰ
�������V�Y�'��-�d�̍��^�%��;Vܼ�"U␄����jI\�9�3�Ψ��?��T�����c�#��d����*��S���~(�[�!�U'�[�B�b���	W�������4D��@�����Q�%�����UR�� ��G'��-_7�e��0���UXX��[��:�d�ʁ3�W���M��QLM���:�����׽�x�dL�V����sp��������1�w��,d�jP��I����p9c���W���tٿ8p@��_�Oz�\`�S�J����_�^�A>nT���ھ\O�����)h���-�����f-� ����wji��ҡ`�����g�rz���އf()��	،� ��~��X����N�aF\��c�����2C=���7��]�8�+�\��Bz��
�+0SM��x**����X������,�l��m>�%0m��&v�s���s���QK�g��l�:B��V_�k]��Zv����
ا �\�iBL}�,����<�|r>�8����[�C�i�պ�a���MՌ�nS�J������7<u"�ÍW�t�v�5�K��b٥z����ۗ<_E� ��mU_������2�� ��]3�x�qY"'�]�=Nыro[eH����6�up0"�p�}YG���C�+�?Z�" �Decl�H����O��l�^nw�љ�c|U�����<�n.Is�aͧ�������Laz��w�:����h��g�F:��5כ��j�X�	���/ܗ��iyt59��b�Cm����JC����r��6�lnx���kE)Ԉ�Tk��4}�G��	0-P�=lѡ���@i%�[�x}�ؤNb"O`ZK����ٟQD�vg{�
Σf���V6��r!Du�?�`
���af�jC��0ﵻZ���p�J0���1}��L�k���8;�8��M"\��t;	�)U�X���������H���x�%��o�	j�A)�X�.�!`n��H)�lH6��o��+,�x�A�&������ш�{�6ic6*Z
��s�C��)R;���l�K��^�f�B�x�>^A�d���f�o?�asx��`Uel��7tV���2���]���F��<-�W�mг
����
i@Q����$F+�Єᐏ��>�q�0�C�I�� �י ����]�9�C��%�L	}Q���S�AQ(�p��Q���!2�~�����44Kwt�+�l.oK���|� O<�5�R��9�Î�{�N�}j�[>�?2b��������/`ZP }h(qmx3'����\;jA�A���p��֟��?�`�J)�w�ֿV�o�S�S�'�^�dGs�� �,�+���L���P��A}���t���	�Ԧ>�O�������&��[��҆���Z�}��Ĥ�-�K"k0��c�����]y)�� ��e��l�S�?�۷>�6�B��U�ҷ71ͥ�wޠ��d�b�/��T9���d�W�A�?Lh]�3mg�6�+������J�G�D��C1�(��.�Ģ�[�4A���X��+Ü�*�ROν}.W��K�{(�>�-�gXDJ �aE������-�^��Zp̮��������+.|���$���s	$�9�z�.�T�E�����D;��Fx[����K�:�
��tͭ����T�&iZ�ݚG2}�g�fbt�[��̽C��7d����G���b�k`$Z�c��Uٷ*�jF���[�~���cU���@)��\�`��CF��Uq�~,��C�ozr�&;�#�{�a���m�2������Ix�{��� ��p���p��Ɋ�H�\��g2�q؂X���>�WPV�s��x�~ޛ������s��p�-l+rwj-�NP��SA�"L,r��X|9\����o{ ;��{V�@��f�4�>(���O۪��r��`z/6ih�����Ɋ�j�����/j�l�JU�O����H������Ex
�!,r�89��sn�%Av��%�@$��,�k��%�y��Ф-7Daޫ%�}T�Ե�v_Ew3J�La�3-�|ՖE2N4�����-��}S���a�Sn��y�����#�i
X�n��f@����խ��]	3+�E\^V�`���\ޚ�b-��T]�c�,R� �"�����v��k�Be/�R=m�9`�i�j3���<ndVz���ph�\mДO�Fq��P�aZ���RЧ��FO� �ز�<XwT]���Lr�����Y�~"��ݑ	�/F��Sq$�}�W�g�o߰��1{$�?��G��~KY�>�ah`�<5＀ܰD�;,�y�������=����&���Q~^_��̉F2�~\A�z��W"�a�0�b��#[tTD]"�η#v%}	���	M0U'��Q�I2]�)dB�E��$�$��kT�l]َu��?��*�}]� �y3�]9i�Og�)(*;�F�H����d76ԣ;��3M��4��+�_d���	�xu�Pn����:#̔*�=^�*z�9dG�Ɖ��O�5v�eY-�kҒb�_w�"g��I�����HƝ@��A��Gَ�z����W�Ņl��6��X����=�Ȼ��L����%(jvfG����� �YseD� ���wlh	����Fؗ���g�5J�ukB���&K�K/����!ię��ʤ��Z���C$6$Ql���L��Jc"����8�? ������#�۳%�+�ˎz���MGe�t3�)6�-�e4�1�MU��G�I�:���*{�6'��m��\�a"w�|nb�La*R�|5��bQ�6f�e���`(��[��� �4�0r��<e�+.��Y��Tr���$˺��S(�O90���DS�:+-d���;�"��Bu���G�m^��ɲ�Gg���x�ᓤWuNL��X�9��;-���܂��e����pR�:���'O��{�9C�ۃٙ�:�C 9�V�W�Y ��+o�si��㞔�1����K.�<�ѡ����5�~ ̍DH́d�E��U
H�b�M�Z}���f1�A0�h]�;J�ԑ7���k��2t3�
}��E�u�����A}Zu �2g6x�� ߬��H�c6���6���2A�4 �rx�P#��4�؋�u]�|U��l<�ҫG�V�S������o����SU�p̙)lV�����~�ھ��C����m�=�5I���D�M�Q�x��\�����W7&`gV���&�d*�,u_��xH�K�^�`o��ᬑ��{<!�[�� Cc��L)}�$ ������D���{?���x����0SZ�v;��_��ŕ���
6@6�f��W<��=Z�Z;�|Q	3�g�����L"RjW,'�E�왇�zVIaY�j�klV�/6�I��1)�d��h�����i�aηs��&/{<�'�;�ZUf��gM抩�v�!���0|
�cj��Z���"��u]��50�
�!�O�B.��S�􅾌�Fu�R��"�n{k�&*W��Dβt�-�eb���*~k����!G-d������n��ٕ�e`�#�w��=�A����&Rq.΍6���f�b��yY�''XEk��Jy�D,MbJ-� guk�H����9;��\�D@����q����So&-$N��"�-e����GuF�yU�Y� ���RdnJ��=�/@yk���o��h���?��f���*K�l����@:���Y  `^P������'��$��ӽ�q����L�v@��k0>���7���X�'����ex:��wޟ@;�/XE�_�$����E-S�Օ�d�WX��a���F�h�g��HN�_��3�؆J�hS�	Q��4�v�������n�$[��>2�J|fY8���q�<�b�p]��r(Yd��^�_��c[�����~��_�/���QQ��tk�c�1nV�$��%���e��ÝFYO#��∳KVWU�c��i�>��ג�4�(�+'�eM�|��Y�Ö�`���,�.������l�>��Z֓p��w��t?�N,
t������= �4>0��3��8��l���u���9%��Mp� ���ÛD7��#��0g/��y�:�+{$_:}3W��ӛ)�y{X�_�w���K�ha�)��06� ��Ic��kHm�J�̂9�����kG��g�ح�������
���k��˳p���j[�Ù�C��Ge�����j���}�C�������1C?�o�glF�͢� �O�>E�^�ͯ��'g]Ga��~�WW�JQ8���r��"�R6o{�6�/j�X��:�����q�5�F�V������"������w]�v#���f�&������1�u��C���X� 2�u���y��0R�i�e�Ƃd^	N��Պ��V%rt�y)�=i�i`3#�_��!"�/��!�m2���x���M�B�RE����M@/0���B3U�]�Tk���F�|��9o>�RCG��q�Z���s� �rv?e25J]m�j��LlBV��"�K�ש� ��VG�,�#����\�f���<r�Mf+#��0�V������Pb(_3d5�6η���4�i�����]���0��)�I~����Ft�W��p?�G�51��&�.�s��NM(!���{x&I+$���آ�D�X+!<�����Nj�x� 0H�"e��Q�@�E��@��kbW�Gc-L�y��<� t�z�}�/a[�F�7_��[�)9��`1}r��Sl�JQ�#�F.���5U�����X�!��#'��M�������죠��V�hM=tkГ��QHȠ��AT�},��s\-K(!����A�F�ɿ�|�[���>�zA�-�Bk��tV��:L�-��ڳ�룻L����y�:��y��"��D~�Z�x�"�Y�Ƨ��j��_�T�M��q��M�4ɖ��>|��sKQ��꺂�edb�dj�򩢍�c3�N��PI���c|��&�ƅa����*�Jn�جt�[S7�4�"����i��R�tWJ�Ȋ3�G�|�����W�����l\��E]�lX�~��j!<^���X`m	�b� T�d�2�A�d$��|���:S�����X}�L�lU�t�\P���8���1\c/��<d5ϑ
�N�=D�8S�1V�����=΍��>�P���'��D{�2*�Sct�޼K�x���#1�en2��Т�N^�WMs���$ns�b�l�&���22R�B���YV��e�]dp1��u���C�pF%X���dS����q �E�i��'mhU�$*�7�P>q [lX����Z�,��ws����Y��&�5[�GU�X�)z���_��
�Z����)w1槼���Y�w� ��7�&$v���)�&�hN�K!�@JIz,~Dj��p?Fk}2��L�?�����P��~�W�dI"�e�p��ُ��`��(��ih���T 29����3��Qp�9���̀� ����Yi&o6�Q'nh���������%�W����:�I���/�Zt��{�L]V�p���/�5�e��];�|�Kg�i: �<�[&\��-�j�sA��B��z�'e
V�U��UfeA�J��3�њ��1(}�ٳ]IS�%�_L6$�F�&�0r	g��: g�dA9�eCG��_݊0@�=��zO�F�]U9y� ��M��-,�^�m��$`1f<�.;�a�x��t�n���#rGJ���7J=�F�!����.&=ذ"�iZ��6/�o�&<�d��;x@�<&�]��lu��
� �B��'T���-�:�df����S&�5c<fe��!�i0����k�x v��-`�:I��o	8+��}���I\�2�-F���p4����2��	�_�,s&��4Q]�L�a;��^?2�n�����x$뜓L������<���c�<�ey�� ��l�(rc'��qI�(����dirK����v����L�������im�[SL��d���R���SX�uR�C�m��+�ҡl]����~��� &k#aZ��ء�ˑ�zd��)Ȫ����S��f�Tm�\B���-_e�i
F��-Bkk��'TR��jD+��uU�]�;�]�3P>���/Y#���{�����d`~mpi�E���\w(���lҧ�Lҹp�	��&��ez����F��D V����}�W���IZlZ}S�T=a��w[�`����Mu���p^��j���';OW�=�� ���@���$�>���CR	6���V9}�N0�+�.����z(�XOV;s�䗌���Rx]���SM��i���0��,bt��J�B"[n�*�Y}�?_��3&^���χ������&���c���q��<����ӡ����C�q��xw��ƍ�k=��]p<O������~��.�wL�uP���~����L�P~,�;"���AW]��1	�X���܆HP�� _E�	���_�S�4�Mx��k+�M���AW"a+�c-]��(S�)�o�t���������z3�]/!��|��[���Kӡ浠���U@Y��ɕﶢ}���ev5�.�)���L��[��A�p	Q���q��� �l�Wr�����:tOda"��AU#��������R8�'��-��&��&�i@[�`�@)ѕ�G=k>:OtG�m)6p�� �RwO�"T�,���Q� I!fy�����'�*`�����.H�Ngh^��`����zZ�fdmȴ�1��0�ǜ=�\C��:!~vN�\M�$�Ȝ�0����nnm�����Sl�u����|w�j�}��@Bף!ă�~�0s�5�;�l���A]'&�����Z+��i:��׊`�
w	M&�<��(��Wgҏ��.��kq��]��H�g���@��:��ഛyVM
"E=������>.���*gK�S��!P�AA�ƯP�.�݌dw�=�>�֣�f�)1��v�B���C}3��0�=��+�`:��4�9M��z��fwbʮow�x�}�z�Ը�>����`����\��������ɵ�ަ��������E`UՔ=�"`�����b���y�j�h
�@�D7��N�v�GΖ:vm�T7��
���N�K.�(���d�K7|Ҽ��G�]�. �@�p�ܫB�fLZ/��R��3&He^��_�t�l8v�R�K������u=��`�Kr�SQ׆�KkKG�>0�&n&)d����8M�c��D�(�3ATʭc�!�%о�|�9w����Z�A�������M)�>�+-	X^x�al�'�:��#�X$�p�J�=^ֿ&��۳\7�p&ڷ�1���G�x6	D*�C=$�ū��{�������
��70�8�+�]W�g�]u���?d�7�#*�7�H@�y��8��OQ��d�~�QWs�i�U���"��t����ݙ"?Lނ�d���rq�Z��0�d�F�<��Tk���5yl�G�J1G<��ӑ�C��B��_�
���Rw7i�"��?��PҘtإ*,A�e�S:�t�3����k��7A �aqs��݉����� _x�u��4ԥ^����-�H֖�Ώƺ��(�� ���~��~�I�_�k��Y�,�HYB#�_`��%u�� 'c��*��ժ��g
3 �,�����".��Y%�\�4�������\h.�S�{c3��������z��S�Կ�V�F�|v�+�^Bã�d6�⁩@5���O��	�*��O������&v������cHsJ��Ӭ�1۳B�D��mR�~��lN4?c�Rq�{9�D���a��4q8{к��e5?\�S0ܦ�kfԺ��}��e9ꚼyd)1��v=Z�5��5C��[��k�8��_��Cr=��eMNuxkC>Ţ�H,�2 �D���2�^X� M�2D0�I�)T�@-U�U��A.T:�X\���ɵ���D+���7x��yp�#g�T�K�*\&��w�LoR9Ao�SyFGF�|=�TZ��@uVn5�*�R�������+ �(z�;Y��_)*�p���E�/렴w|��M��)�i��b0̙$*�3ː���O;�~g��y�%M���_���A�P0eBu�9,c��P��]S�7�fw�/�BT^2�n��NE�O����M��h!J@�#	�#H�zlU��LY��yzn
����+�0ɿ`����+-���y�T>�#F�@[��A���.m:K����@��Cij��$DQ� �ft+r��6{m��1��5K�B"r(֑v����k�Ww�j~����Y�E��bQφ6��a��(.)�]^jiX�|Sun�2�S�Q���#`O+)d�"��F[�w�"8�Xb���}�L�� 5�#�NHE�Yn�U/�� ��G(d5hD�rbKfˑc�/��3*Ɵ���c��A�̎tc�G+4	�2���iR�Df�&�±F��׮x���J����&JQ����sJ)8�M��f���	M8dbO�F����LRq�Fb��틧R���i�<hHwK3WJ�sXĩX�׎�\q�b��d<��{�M$Ei���o=N�h� h7���:��=�:�����r�M�j��,�l�?.)��4��-@5G��:�0��S��4rzVY��{��<8��1�[��ڼ�aP���<
>�����^�Z���DB�cW�8�奚�W����]&��R����{q�z�>�fw0	�������Ơ����u��	�0�ƛѕ$��H$Iчhh��͆e���[Sz�4��2԰u���=b�
 R�j�������=�h��N�-�����Y�t��;4��BKs�
T
48Ty�*���<����7���{W�WG���Y��"���Qj-Hf�ԼN�hP|K���(��(�)5J]�ê#��tg'E��ط����/�s!��WW7�n�A��;ʓ,p�q�l�:)�d��V�~�J�?���4`a���x���$�asZZǺ����v.�%�GC�LB �e=*�����S-��9<~%xJH�]$�:��<h��_c�\���Cq8sq��ˁ�D�5�|̯�.��!Q4HR��� To0X꼵<�&p=ˁ*,'�	����^F��x0P1��7Mg��lb��~�|�C@��ȨF�L>C�H�@.<�a��9er��M�ԣ�R�^�7L6�A�껻�was�E�C(�߁/���DU?����Uh2��7��D[�z�H E��Ϣ0��������p�_����/l�N�WW�?[6�܇d�����c>��d�[&�����%���-�;s@�I���z-�Ė���ZʶfD����Gx�[uR[V������L�z�/;�� ���O��vcMLc�0h����ͫDJ�HX�d, 1��I�R�2�<���RMϢjo`�\�M��������m1��Q��/*E�R���Z��~|�X$�"��?��\��H��q�z��>$W�R�iGǓXPϲ�@䝭J�x�~u����z�!�L�iFQ�[�e��fB��>aS)��=��r]��;#VRK���=�C�gHEo�ř��ƈ�!J��47	Ѵ�aE��>��� �D�l�0�L���i4gzbO�A^(�3�3�녕G����-���OW������x���$���A�~�-����~����I<�s���s�!t�?�����3^.{���m�dU��כ�Ҩt�5-���^#P���H���\��X���`��d��R�/�g���(��ף���/�S���4�`������a������H����Y��
-�if>N�/�n���(J(�<�N�����!$���OHxrx�@q�\���WhM�F��K���OT_(ք��s�|�;�וW��=T����H8j�yU�����b<�Shq��C�g���e1h�r����M��F1�0���$���C���~wN�A��GE�d1����r#q`v�}��,�ѣ���3 �5-��RZ��J�K,dB�~��.�P�ˇ���!S�9��Gcø���1�Ƕ��>@HcQ�)Ӿ�o%��ln��_= �/� �G�+�\
�B�`�i�s�4e��.����ɧZ?`BJT{dG�~%��_�P���Xa:!u���Fi�x���h�J�3^X��¼��;A��rp=o�1�<�:*C� ��R��U�#�o����)��{
_)���CA�@�(��1�9l�(�t
 �`9V[^e	J#g~«���s�H]��яkL����������+�u�v��L���-����`ii!�3�?���"��j'��d�X[�eǆ�L��І@���o�Q�~���S�ݛ D���kVɗr	�0��?��0ؑ?��>�5�/�6��Ѹ����L�J��Al�H �-!^�� �����L^;�`ѳ�e�椮'��[���Yd9�@>j��n�'-�&����tbb_@G%�U���(���Z7�����d���Uu�`k"�}���]��y�k�$ǖ�>����"�w�ܘ]f�hW_8�ae��J�3�N{��̼��1�s��+)m�F��Czj��'�J|&:M_�n�+X5Wo�hA@:�-F�v۟䭛��Z�EHAO��U7~�JEE����i�&D�B��1�V�ہ���A�4���Gb�X3|���>�W_��V�D7/��VSt)9lBC������� �/a0��.?�b/���2�ޢ�g���0j�!�!�fK{&őU���ZZ����p9gQoa�ط1���s̾qBU�q��	0&�d5�5�=����-Ǵ2Bn���5~��JTC�=u�K����˝������;jf���}���_Е�Z��P���HУ��w�{�"�`Pw�ك{�R� __ ������b��'yX�.��~Pڲ����zj����On�3%�:JR�,ѻ7�%w�.|vg%e�%�����w����U�q�ј��q="4�ڧ-3�V�^Y��2-��� #�Pr��|O5��_FI �k��?�h��q���1C/�F�#���}�BE�#��h��.�um�%� ���_��:�xu�̥iy;])K�L��p@�3>�M���KQ���#�_��y�wR�����V[!�]�V����է�)R�B�S�h��1|��e���ܮ���E���ٽ/N�� vn$��/H�Bу�,ҮL790c7cȸ9��?�'��ٟD��Ɇ�@4�VA�H��~���DCڜ��\��I*�f9e�&Dph�t��@=/m���`,d�	E��9(��ޮ%�����������7��}���h��#U��P5�1a�a��C�rT���m�9R�]��}��5�ƪ�|���Q&B��q$h�(�z�h�g���%�=���yh�#�e1�8����}���ݣ��mR�ڳ'I~}�H�{t[���<��w����5�=������>�Q�!V(�9YLH���6���Ӻ�-����cΡW3�/`������R��+p��K�S�e����v1"�>8��5��bNP2�Hc�@=k�7A�]t�a�����W�6!��Uf�z�y$��b��H�e9��X�8�1��Yru$ ���j���tHN�z��,�L?��S�'e=>�=���x
�P�J�Q�œ�f�3I�,��O F�B���G>e�J�
���(JCa�� �n^�G����u<P�= �
%�ւfL�rQ��oJ��\\�^� F#;���)/�+�6�E嚓�i�ka���)����w���@�y(�%����,k����ҥ0a�^�Q?8���τ̔��!F�%����d3��([�Y�"D�F����%�V�A×]� ��5G�-#:(>?O�m�����!㴯ox=�#�ߐ"L�W��5^)���^@���9F�܅��9���iV9L�e7 ���ӊ�(r�Ὠͱ�����F�k�ǟ6�;#�B�����L`�w$��ʟS�����qU�Z���`�Nr�(֤ak����5҉,��EGpV����(-vx-I�Y��@o^��f7�TԆ+�݅�Ң�*e���æe�kU6@�)F¾��{��h�lU)c}j
�R�s.��>��u���eͷF	��)�I_�p�:'���Ò�1�Gp�]��/rn�S7L���$c�q�5X&��{n�1�ƻ�����������XUI_��bb$��-$����_����Ag)�7�Zd,�	X@>�^��c�"7��r�n�
M�i��;LXp"N���~g�D�8f2w���7TR�Q&e���o˸�T�R	�L�}L�J�Xr��9�J��(nu܌2
	���c�=��X�~��0C@Q�;^�&���,�n$�(?�h�J�Z��i�`4�=l�/Չ4:�s�u1:Z����R���
�H�a��& Ӝˀ��=v����ܡ��'�����Ȕr��/����A�I��Q�y��?3�X��v�(:!g�R	y�E��V�Y����A��Y��k��xqT"�`�(��K:�+��ǃ�}pޛ6�ǁ�ve�p�Մ�g'�=���f�VB��+圦�i)��V@[�#(��1��d�e.�]��!yEY`T�.X�����C�����B������D8�Ee���+{d��ï�AL�6��z���ڇ�3�17(Xj�&^��0����7�p4�k�����?�F����	/T�1�1��EW7�~|�`g�G���;ۨ��lҿݯ?����I���m�+�U�4�;�ڑ^n����Z��A\�z}��[�q2��9sˬ��qc�;fJ��4����٥Hqp�x3�.=�Rݬ�28�mFR��m���Fj�B�1�bqbA���X���,�z��A1=���Q#�|Qf�,��V�D1��n�>�6�Xt��C*
c��Ѐ�^����?�]m|�K�N}SDP���v�@���7�o�HQ�����%�=Vf_�t���d)�zz��f�U�ݐzGk��P�ϗ���R��<1/A"�55�C8���`bh�pL���vv�L{N /�_jBκ[^LU�*�.W�|�x��%�����(a�%Ǖ>�ٕ �<O�,4�W{yۀ�b燤wrL:_��\�Y��7
��M��c}�
�o��H`�����#�o}O�`�V��z���D������	!R�B�ǎD1����ZtmoyN��;Ua���4�-J-ed��e�l7���e�9��n^���SK��=�Y�����R[�TZ4�oy0��Ɩ"��t#�*��#S���2a�h�EZZ5�n7}�/�4�-&�d>�j���K�IK-��h��	dOp<�cq�b�*�� ��gԊ|Y`:�b+�&nۉV�G�kL����${mEɛR!x��X�{�X���>�m�Ã�!%��`�!���A�8[���zG#�V�%�s�Sk4���?�z��,�q��Z�HZ�I��=V�S)A"����&�O��V���,���F<v��ާ��x��b�_'�&��4y/��s�0:�<Š��#.v߈2����A� �O��GPl�IT��H]�Y���^��h�e��䒠gI�eDc [��\T}9�4vMӍ�N�+(Y���B�d��]���^gӖȑq�~{�F��0I �k���|�g���>3��>2FQ�h�(D��Z@Bx������P]''.4K�"����'�M�T���A������cq�Y�Xܐm��kp"�.��-Upr΢K~aJ@`���dU�4���v#�	�Z��Ry�P��!��@?�wû?ORSw}�9:���)�yek�l�m��?�=�h����M�¯J���8xV��Q�Y�p�f9�b���5P��)ߴg���uC��,�^E�rޓ�FW�nw*K���9�QAY�C��%���T���(��!E+T��V��7~<Hn���^���j@�)Z����Xc	��*U�`UL���Rc Dt>D��>ܧ��.Ɔ��ܮf~����(ւB�<4sL��W�i��Y�x��c]�V̶��.�#��>{�77Dy���+�\E[���m�׊m��K���U�9 �ֽQO|*Y�'��fA�i� �*>����S��`�:u�!��0꺊�l�pL��2����A�aA(3r�^ꎠ��Ho8�ꏽ�[桱��V*I��hl��w�'h�!�l�Aa>���R�Z���L[��\�6����}έ�,1�����k\�¶8r��g �+'�uobO��g�f U����:�Q̫e��V��>)q���x��w;i�%Q,R��
B�Nڟ�5'����K���ǴyhVe^2W��X$?a��O�Wݞ��t�ņc����$�u3τ���tH�b���h�Iw`}���/�pGH��P7���'V`�	9 L&��ԝ)�����5����Eހ	ܽ6�F�������K�g�@��S9ᴛq��<`f<izS�q��e�ܲR�m(�XW����߰��P���������hpT� 0@.ec��{��;~��z�N>2����u�2�-�D-�-�Ȯ$��?�C���1��m�;��b�:�k��$
����$@�������GO��[Od
�r�5�0��z����x�����Xn��� 0B��.⢴����V�)�*�����f�Ŵ��.�,�>��x��;��v����@T���9e�5�#]%"7o�����=�r��y��qh��v�A2L��I�.H����9f/g�Yu����5CM=�$�`Y�[E�p�6�QhY�S�*Bٮ�I}̆6���:�Rsജ��_ŬF�~L1`S��?e.y���,p��d����2>�0:�W���*\(�­^�3�9��u�f�t֌�`xfǈ�	�]8m�mQ�
���
`�}>�[ʊ����:�~p>�Ʒ�u/)�Y�U\������CF|�I�e��Ε|�|���-��ιOU��~���v� B�}��I+'~�K��o����_�^�����$�@=+�zuV�|F��l���tуyK�s�DL�G���L7Y��)�UBFO�7}�p�i:�"�C�Lp�	K�$������%�����E�m�8>4��\Ks���$�U܋@WP��kzQ#}��0�ڷT��C^��59QṠ!�=Ni�T���b�k~T�3u�8�D33��1\Ɉ$�G��jn,PX��y})*��}�.$�CɖC�ll	=���q��Q	�ב
�n��LkΧzIɺ���jn;����$_^V��&$��� �(O���ˤ�%4k%k�Xw��^��<�ᚿG4�Z�v�ΰ�z� A�w�C:HwM���
K!Ǵ{4����bu��^D��Es?��r��Bk�����H���>-�E6[�^�By�0�ÿ��C�C�����d����Ah��{���.]͚��')I�����"Wn��8�<�N�Q[�W0��Ɔ�aB���R�_^o$�F�[�*�o9�SZ6L(pF��{�|:�� �/$�Hd�g�ݪ�D�N~��>a���㶓��������V��+;+��m3'X
��h� b�05+���B�΅��6��ʿ�=�3^�x����Ȋ���<�/��[�?)̵���l91�'X�rX�c��Z�G1Y~��n��NP�=���H}���*�ݳ��z�Hu��
��հ����g�:%����R�2KN�9����k���P�/��ޡ.��@� ���H�;��u+ػ��ڗs��M�
?*�W���T�25'D����5�j����_❶mZ0��р2����^�ɔ�ΐx�"��GkTKU���V�U���
ꎌ�\����'g�e���"�Gt�:�+�t�8��\���dXٚe�.c�]�0���T��N�P����q��6�M�b�-�{|�S�����6Ld���>K�r�|N\�8{ZO�u10Y��#�t6ӳ�F��# �l<<ޟh}Z6�@h�q⥰���pXY�N�:�j���ރ� ����Е%>6R��G'�����Z��4g��=jwT~�
h����a}:Y��j�/L�H��L��%ԓ`��6�XnrcoT&D0��e�.M���f@u��[Vs�ǲ�澛T ��1���Uj��CG�%�������T�5`�G1�����"o�e_E��[v����m�kPT�˴�Q;���ײ�K�1#���=��'+q��g�\��RT��,�C�
<�=3������
���W2r��0N�S�f0�*���p~�R�Xr*«��\��8�����1����XYN�:�F���W�GA�qH�2���q��?B�Ǫ��w�XOm��ً�ͷx��C�-�!D[�߭(X�x���;�`B����8��xk�"o� @��ن?orl���b��H�h�*��k�Y<��?y��&�a������s�{ �nx	��'�.n!ң�'����Rtz���Z������8��Bz����)�83 �Z�a{��$�����˶$\+�,s85����A/�
pRI���1fVr^���:C��_�F1q�4-��7$TL�l�)*!�}KT�):M�v1��bLظ��Y��o�-������V֮�9]�#p�W�EcmTY�i;�׎��36(���	�e!���s��}�0�?��y(���R��N��L6bX�M疨���Z�Ku��ǁ}�Q����x�W��M�BG�	�ɗ���FB��	#���l����!x�Byz�TB:w>�~�(��ʴ��tfP��ŉ���y�S�!V 1�û_�r��j.M�<D�kކd\o���{���BS���N4S-^(�Zi;2�D1oy?��3u ��FP�"�ᱼ�6@"w\F�L����f�C�ϼ�1���x�w�f�ztw���\��~��^ �[�j\}�.��e㟱(3PJBR�9n����]����5������o	��
&�C�ܠ Ј]���O�|?�-�'6� \��]23��*���-x�Qo�[�M��������������D+b�u�"�o��n��#Hx�� ~�
|���6C��I^��C͐�|����_8u��~O�����_ �<�a=}����'[z�Fp��񸽬���K�\Lj�n{��#A���k�3vv�_Y�*���ד��s:�o ��R2V*x�����)	0%���j����4��1�5$���~�����k���9謶X�G^Y�-N�vB�g���C]��ixړ�|�����!����\���)M�r��h���LJŀ1J�s.�9��q���p�:�1X�-/�k\����j�� �^~�M��)�|G@���:Cq��d���������ɍ��<e_6�e�:/�x�#�����	�w�6�L4��5D��E�)�JK��-LI�Cj���v��<��� �-�˺�����+Dx�r:��}����?Gixa/4u��9G�+������2��G���D<�LK`�A�n����b�����r7��a�����~�x��o����������X�C�y[ݡ��9�?�7���ۈLWo��]h@����9��9�ނ���Vv�q�X�O�t���8�^�ͤ�EF�g�h��q{w�J� �A���2~��%M�hnf#dU�B�ǥoF�M�=%������a"̲�xhu;�i����.��Cw����Ǖ:W����6�A��:������4�������1�����"�R�"��~���_ԊC07�P��A��6nQ��><��SZ����O<��/�zF5S@��r}��[Ε��s,�
�Z�|��e˓�|�#��tu�ħ���}WXSd@C�MS�&}epS����T=q;�2Ѷ_����p��\q���]�s9e��Nrց�ѳ1�/^q��W3s$�3�ӛ��#H�B�S�bzW�e��K�?A@��r��{�P۹�l��bwj�%;��x4f!����}ٕ�o&{;����j�m�߁T;�:�k��8��	�(� �,����	=[���b�C��/J9������ٗ�T�j>q���Ö}^I=-V�Zn���*�C�5k���V�o��죽!�����֟E�k/u�i8Hy���_1K�OF��R�y~����]�ڍ7�g^��P�������`T\R��^j���ֲ��5X���%�쉠`�$4u�&���_`�~�w���;P,C�ȸ��޺�9���{���>���	#�Ś��n)���/|�HNW}�$�]��R�̽L�ǈN�W�`1����n�B�y�e�47�)+��Z)@$��d:Zq��ы
!#�� *�r@�C,cZN�$��46o��!<	m���%Y���>��d5��	�ԯib��`{��p�r��o�����?g�|�"x�
��h�]�V��uueLȈ�w��& W�ڭF���xR0�%�7����}k����O��oLށ1�f�0nď�A�vHfK��"��x�����aGۜ�g�J�UP��LD���D���e�1����ã���B����PcT�pq���!�6]�	!�o+�-��3+A� �q���	&���A��j�,扟��9�2v��功����������/�UDW���]>Y�`0�}�ķ&�{^�v)o����j�ȍ���GR�lQ�^�
��L��Y��C�F5�����R1��g
i��
�
jaUrY~Kh�ڔ�	|(�-���t�]�$�̊�\���_�� T1o-w�f���Ӓ�Ȓ���0�"��۵_���rwME��/�Y�]��;M��̴p�M��A`�ǓTf��+@�h �=yS�=� �����0'1��g�    YZ