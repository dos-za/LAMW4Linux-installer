#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3558800190"
MD5="b0025fb15b06fca19c7ad5ea90824ef8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19784"
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
	echo Uncompressed size: 132 KB
	echo Compression: xz
	echo Date of packaging: Thu Dec  5 12:01:35 -03 2019
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
	echo OLDUSIZE=132
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
�7zXZ  �ִF !   �X���M] �}��JF���.���_jg\~^���&eM�
Q�Ա�qZR��ǣ��9J'�F��	�;���¼��OU�cL���z.�PB��p���D�'Oѯo�b]K���6�9Q6��@r�r�x�\�:(iH$��5��<�Zm`Q⼶h���M�h��OMn��$�����.�*4����%�m���c���+vn(�?Z��Y��\
�ib=ml`YJ-��F#���H1T�8��Ί"�f�p�2��,��ZB�,��㚰��B����#Ֆ�����a�;Og���%�"�7�׷/F&���%]��QlŽpj.r��o�#b���쇹�!����zh���-K���6��c��#a}����2�E����s��Lr�h�t)jc�a`5>�&F�C�|
�g��8��y�q���y
ɔ�L`Щ~�%�u��៍�e'��c�9��f�6��+!�-d�~K_��4����N���:1���U	W�2$jW
�,xbH�8�?5(y.C�JUd��hs�g����vE�K����5�4�լ"����S���ũ%/�U�|^�޷�����Xg�x��Ӷ����~��Ը��kL7�~Q�tc1Ī�L�E��SY���m+�9IzQ�N�|%\����<L�&�4��/��qB�T2���!##�2W����T��)d݌���ER�5e�^�i����l}��{Q:q�W�6�Z�h�:�`�6�?I�p@��� �jV)���ۛ�[�+A~`�O�U���|C���§hN�|3�3�N���mح��\�~�4{%��?_t$��Z�r�7�֢r�Z�%��z�Ǫ?|�ɳ�P�e�Cn��fU0��� �E���v]s��f�㡕��s?FV��g䞒~Q����2�I7�͟�D͙�l��O,��?E�=�m%��E�{t�T��0/�r�8'��;������\��Tץ����ߝ$>xi����s��ZS�_ə(w(�q(5�ś�.ˇ�;�*����ï ���$���}�����˶�G�/�ȳ�����HR9R��~�>*�-���W��B�迗O�R8զ���>��%@.Xx̃�7e2�zX9 i��g�cXa*������1���.[��e�.E�=Х��#W,)^�g�vt�_���Cz\�j<_yC
V��1s���X٭!�_aE/,,H�{9�@�n1�v0ʯt�ײ��1&MjɄ҂#_�F���Wt��QN��O����YVȏ��y�ǝ��7g��YQ�wBk�*ޑ�L�$��O����#-Y������F�g������/W�f��ݲ�>�=�$[n�g���m,fm�u���4�,:V�'Mh�t����nK��0��>R��K����D� $$p� �4*�,��!����\S<�;�L,"�ȏ���?�ޤ�ޛ��Xk巕7�U\���o�l쳈�s�)|����֕�������KM5��st&<-��r�L`��8RpS�m�p|�ά�p��d���35��F��g��ȥ�1<�[(y���7��Sl�W��,��Z���%����0*��A���W��U���$�1#����k�~R���GR�oi��i��Q��&�����i^��V���Q�u��Cg��LQ+�;���1D��#��^�0x#���G)������W�~P���J"q �Ec>���)à!?(�םl�.�p�����8B]L�o;+sp��w�a�ȩ���;�檊�M2,+ǻۆG��v�,����`P3��}z���-�ٵ ́!�Ǒ���R�D���#⌲=y���4#�I��5K����!ݝw޵]�N�w���^)N��.Y�'D�-(�D��D�p�pc�I�o^���?��;q��f�>.��հ�H�0L)��և|�t��]�`?ll���f��sʕ�fa�2����&\�����弾�	��T:��t�.x=�~,E���K��m)૞��/ZmpXo����+{=�Q�崰�i��׹��ᅹ�3\�nLȵ�Å+�0��hH�t�\�9���Z^u������K�4#������\�#�M� �!n}�U^�V�):g�۞G�s������I��78��;Z��tz�K�hOy���*N$-���Y[&������b�{�q�E(W���A��q�M}a���_�=�~?��zP�n�	�܃+q��B���e�y8{~�X�
Aa6S7���1di`3'{���aq��J��kc�������a����M���T�g���x�g�}�����¬�����m���*=r�XH�Hw��>*;���l.�p`)�M9�����Ф��R��A��F֭��7d�i���'�ŏ^_�^��d7v-%����=�����e���]Yվhߡ����ɲ	DYz��FL5%P�L�ne�p_51NX���*yE�n��+��~��UPh����Zx�r�'�5��Z<�u�	�A������u�G��S1L��S����	�����+�YMMn��� Hzр���@� Dm�j1_�S"5�Vr�,[#�8�n�`e��� �������V���Z��K(��ER���V
 P��K��^5߶�9�xG��D�VW��S�E�;�qt�N]���5C�9)��2ϯ~�X���e�9i�Aה��ykWQ��sLzQ? ��Q�EE%2��,��8>�e�-�.��{�qa>��D� �g!��9:ԏC��2�zN7$���'��]�l��;���_&��Q��a
�H?<MM��n�9o�Vz���2,.���X�rD�o��L�hr�XR��.w���I~	j*��X��̍�~������`02�k/�Z��ǜ?�/���˵�J<Qh&��n��:T\c�+�̢�13��0����Q4k�Ωl����c'�r�o�*H�f/4o��G����2�W���͊�+ �xe �AC?�\X=�_�{���p��������8�`g��������1%�"XH(K�O���� #�^N��þt�~p�C���L~���]��'"��誢*�	��9��N2�y�O��Ss
n'_W��}4���-�́r&����o�B8#�t�X1�Ӻ1�{3�@�1�|�FAm��`����̃ֈۨ��s��?5��r̟�*������6(:�@�<y������M��o�K�-�B �����
�#�k6X+��ww^�Gn�l���y%Au�d�A
uHz����ྨ���ⲼF�x�2�����gdɫQ��!i���*�o���++��3�R�1��G��&ɢ�7���a�Q�"�%�(�H�
q�E�G�`�Oaު�PM�l��3�_��J�`tk�
z�8�B .����{�ax-�g�Uf��[Yrm��z<l��t��)D�a��.y�XP�@}V�p��r��k��^�a�E��N54i�X�or��#��ώ�8l��ã�N����y��8Ezs�� 	�������nAტ˻);�kw��ʏ]��.�6�����k'�3���ec�}h̜���nXh���#�+B
<��wр[���p�c�K�A�� �x�ĩ����h'��Qâr�9���{	�sE��ʑS��^��_ {�c��
��� g�$Y��O�)D����@����r��#�>S3���7�D�(��T�?b��T��}�aj(�ͅzn��wT��V�}������a���D��Us���2o��3�z�����QSh�K�gu��(Ц���4���.�Zm2��GW����Q�����t���������NV��A��Җ��Ï�,O{0�^���^��~��f*�j�ns;2a�)/�\<W?�O��r�u�;2��^�~{�%�U
8:���x�`/�����\-��;n_ꆒ+4A�~��;��+�^W�W�m��X����j��j.�sY��Z���̞�`{a��;�ݡƝ�t�T:����nLM�]�m���Y�-�nY�+]]+v��^Z�+�������{��%�U��~��#��EYko`��͛;����{���[�ӭ�+�/�:&���㦙7_���R"������#]o9���I2�w��ݵ�І|��'�;�l���w[�%o�?-��G��l�%rR���T/b�ky��ۛ��S�n���J
2|�Jnj9kBa�g?@���D���ȃ:������y��4>��o�x�^���p�0��X�Ѣ.;�����:�>�b����tV�ffpc��� #C�C�Ϥ�6'c�l��KP@�W{i�!�B.B[�6�_J��kvb�
�_j���Y��xK�+�K-�����3���R9�h�*&F���k)���ʚ��ťV��i}���UF�o� ��Q���~f��5�v-��L��V �4����z��
��N(&�<��`���=�j�U��~���;^
�?��'@��.�Aj�_28o4:G�~�Jg����������R��=�2�r�#sW�P��-B���|�f����N���y_����!�N��)gw/�:��r\��ƹ����J�d��Pv��i�|t&+؋8�chb�X��I�tm�!���h����9G�r?��7��"viT]��&��y�}ڗ��Z�(���ע�w��	Ѻo��j��4�@Un�w��J&�����,�_��0��$�E0gw�����~mZ4�\�d��u��s(��RT�����㪲���ɹ���!'�UR2��^���ו;��[Q��o�)Ǖ?���(�HP����
%<N^lsW!�����B����4�)���F��^O?��$�2?�)y�(l$G�� 8��V���L`��b�ב�e}y�0��� 0����r.�SH�F@X�|���X:ś�ˡQ~�B���$�)������W��|7 �Q�qYb��y�6�&��f,	��Q�lt��)�t��)���'�!G�O%2$�H�K;L��'Z(PI�Í���r�o�ա���4{�Id]$.��=���=`Շi6����n��-߈b<���:���B�sY�Df�:~�"苤{ϧ�Y�uRA����cQ����f�t!�O��(�z�_CB
�eR����_�I2籭ko��-��5x�(R�����������L�N�%��_mZ�����Zcb�T����Z�b��"��<��Rgߏ��VW��qⰨ(<]Iͮ�!�-�k�qA�;���Y�W-ܐP
4�%(�l,�0D|�IdQd<���G�_�2>��mv�p�]�]�d�S*�`~)r����+����;A�T�2������ֶ	���A
��D�[�WH��p=0Q�H��mFI�G�������!�Q�]h��轮5m��,��4a9��b���?����"f.)`y��{�dnjlȑ��qȝ�$)��հ����7�и��q��N[��w�8�3׭�O�U�����}�x��w�&(�b�K߽�l֐!jP�C����̤�T�l������~s��3�7#��^��*�X[x-�>���mx������]��]����6u����f�����y��'��A�w��R�?9�Fb�-��L��_ߌ���+���H�2�K��g���ДH����s7���4Ϛ>H�ר��0p������u��x�~}1D��n׬D�������+Fu�1���j��[F��#��m���u��O��1�O�8M�w@z!���J'x �&�U��>�/x}��;���f�i<�TgA��a�+�c�\��t-�Dϡn�8�ￅ5�H�\M��h�8���~��=}�}69p���]�`[\�cNs�I���W������P���`�
��V���-�M�.�c�H ��&_�
em�D
���\��տaDWm��D�)C3���m��,VkR�C͔o���!�f{<מ�W�N��桜WH��e����.������~q�$ʺM��!��~ҕi����[�:{V:n�a�H�K���Ah�>�%���\��3�a�:�H�x��k�Y�eI�#��v��Ш��"c^8H} �����Ş����f�0�oK�C����k�`T�pI�~:y��Oύ2q�R/5~�P^cͅ��Z�3�|xk��{�����n!^�a�b�����9�6$WH���O�����@��C_yu+R;n|�י�
���Ԋ��c�?sf:�q6��v⭥������oώ_r�'�0W���R�%D�)��~|��e�ĺ|ۼ]�c'�>ph�C�vϭpVx	PI���7�垻5�"��/�@��$_��,�T����	����S	�Mh�* 	ǼqˋfSk��Ʌ{a(�>�:u����S��\J��˳��oxI��p&��#�VJ?'�,�۪.����&�@H�.���/�ar�������V�3��="��Lu��ev�c�2～M���T+'Qӎ����d���B����_�H������'e�׀fص*P
@r ���w���4���d�������+d�^��D}�=p��i*"���'�څR�����8�6'<�;ux� Y��H?y%6Ii���vbd�����Z'9�ێ ��@Z�KD��Jng��]���a6�Zic:�(��*=��GN_�x��G�w��[.3\?�{=Ղ�+nY��\{��M�яBfoL���p�װ�m��,��mUH����R�)��RlN��M���u��5�U;�Vz!IHX�}�X��)���l�����2��\�W�"�XV>CK�s!d��Ш|�]o�d�]l߻'NV/��n;�X�YJ��Cj����O�ʲ�t�BK�vGA
�)��Llx	�k�7��I)3-��O"�P���|qu��]��N5_�6��I0�w,��>��e�EԄb��9��#u�"t�Zr�ɉn����ˈ�m�,���'�{�[i.:ag�����K��vm���m��"ЌKSo�4��$�tg�ƄU ���G35#q%\MQ?0�tL�K���-��B�!#�^�u�N�0c��l�!@�V��6!�`��s�C�(���7�hƆ����p�/)vŷS���6� ޯ�{�+�d�,fak�c?N)�h��#Jbq�DP`x�%��_JK]��p#癶�ʖ�}���o�p�������d�q�(��#o������p[�P�e�P�0�`�2�v!Y](&��I��1X��|�¡���ga�J�s�>g�H��3.��������i2�o�Jy���>@��fK�y��b��S�6c��O�\葄�	�j��� �*�ʿ<o�";�FpwE==*��%`Y_��	��4u�2~p��:r(@En��Pb�@4<���wCS��M��$.Q��ښ������{<h��p����h�=G"l;�%�I�8�I䎂T5U��+�Zޣ��p�^��Ǆ����/�x�m�����t̙W��T�����$-w�]7(�ʰ�����)�~���Y%���ȡG�ѳ��֖X�F�3�8<�	*�YM��ks�ULduo�A�Q�'8OH�Us1�҂�Y+~o^mtÃS I��k0m)��3�ޱ{�@e�N�z�=0�YK@*N.�+ST;(ع7�>@�o�JyMp��;�������V�!^�E禴�˝���
IQ�8y���w��āA^���gm�L����	�A���w 6�1;2�H���w��q�1T�nT�bDb�s�
�)M�!(8�p��*V���넞Y B|�� ���k���U��v>��
/ha���V?��Y�gB�������:%� �m8{�ߣ�<�U�5�E�w��M�\��~I�Mbs-�Q�n«�)�%���n��_n�"��;��h��en�;XI�.36�����~e�����b�з,�*�?�(����y��c���FDD0>5 �=6��,�5�pp���Łm��L��T�����TtSI������<�.Y����������T�e6��2�y���B{2�NaE��	���Wu����,�w/߼�<�^����7Cې_�K^b�����<ݜ�k�g?��59o�u��B�z}șh��=�J��#����P-�I^�q �)�Ю��9��iGJw���3x=v��s,ʐE
(@������#����s�K��qo�&��� ���R6�?/��OxA�ptp���A�\ˤ��ٓvm�n��n��KJWP�����u����`(05�S��%ǹ����e�Y[U�p\:$�����b��{��E��xVm�զ�Q�8��R�~�g�o)�$�9n�N,F���%��#i�3�K�
��m�p��%(8�A 	�ݺ�3M���i���ɓ���T�|S�x������u2/�����}z�0�Q�H%�t�$���(������޷[�0X���|d(5�"�0�=���*�F��us1�#C����!4�?�5U�����8�uz�l6�嵜�;	��ϥZM�i�y��xļ4�0Lf����&��3A�K|�k��0�m��+LRv�򷜢�������ʚ�hH�O�.�ap�5�.�0�O�!� �>�"��b�skG�3��O�lF�L����#���j��Wc����p+�O��cZ<��8G��d�]�r�{Mn�]�5?�"�NCǳ��tݧ��!�8-Z2�s�d$Pn#8P<nZ4fפɉ=��˫S�w[s�f���Mm��B�+��o3K4;P�,������?��vl�R��R�����R�ݐ|���D�0���hi'xR*H��?��*,�K�i�*��̳q;��d�u��ad�H|4vv%j-�:� �[�Ws��yH���܌knu$�����s��S8�;�_�%c�%fu�������DX�ڈ��T7�/��97P8�Ҹ�T��|�k.%�������O]�0��yx��I������t��7g��2cVf�fo�G&�maI7���ߡȸ�A1���<�l��ĕ�D��ܟ6݃�l����wP䕎a�u(Ap>�*��$M\�k�m�~���p�5K�5�o��E�7��p*!Lg6��'��ѕ���Çf��B8�^i����.� Q��uh0�4|G�*��|#<�E��y�R���7�N����y7���P,E50{#���8������qM ���PI�ى�
�4~�:�RjkR�G�@���+=7��0�H[;���x���ޞ�Bt�=,ݙ����$��g磝N(w�u�2K��,�(]�����ˆ���T�8q=e�lҋ�w)�R ��7ˠz�� kL!�M��:��.[�3��a�=JEjk�0�P���6+],���>�B��Inu?�D�ЕJ������u�M}eIX<:.��h�*��6Ad��I��W�䔁bQ���9.���K/��\XY�S��f^fЖݨ�-Y�k�����B{	�3,���:��7�˥�(�bp���Ff���e����LSau����BJ����giן�ٗ���]�+�8��Ș�B6��oD�T�VOh	֙���۞\E���DW;^����Y-[X�c����&
1؄���_������?��'�[����C��:˚#0n�:Ԃas&��g���FGاp��H������g/������a#^���p��+~38s�3D�!�f��ӁS�`�׭�`��9�����;B<�
d,�D����%�l���Wb�3��Z�3���.��:�����q���^k��hE&}�̧j��MTY O�א�	�T~.��<pLyKH���4�r=��ԉ���^4��N��5&��@.,��$��ݢ��c�[�e�&N����u��k ���$Ĕ2��3'%?8է�����
�!�
,'�A�1dC5�.u'�۔ 2����'KoZv��}�Zր{���B�+[��	5��
�s��|�TwDf1��\o/[�X4��� ��A��_��)J^�/�yR7�w���mq������; F�EKD7#��:����K��K����1�g?�}3J�1�X٘H��˘�-�w��>�����P��	r꯯�ڠ�d��vb����À���2R��O�z3p�G�P
��o�0�pk/��W��2�1o�-2Մ/���A�9�N����&�2A!kD�4�2��h/�	A�����ˌ,t���������4��&O�>T����@*՛�#=~��j&vp�i�<�����^Ɠ�t^|S��[�i볾eh�<��a�\�#��BI�c@��/N`4o�T�� gv�W�<��e��E/���S�Ǝ*�'p�CEr[��	.J�b�!�L���16*
0vE@m�2��n}0�"�5;e-��s��F�w����3��h/�Д�9����l�Qd�6h�}*���Ү�i�c��L�r�4�׺�,�Pm:�גFV��(&6��|�a�ۛ����W�u�4(�e�D��6m�مt�D�n�%�J���d�t���wx�o������N]Y����J���� ;�.����s�9�q����V���;^l:��Lx�=�˱�K��@W�߿,O�9�GL�!7I��z@�L|:9vN���²�^Q�L^��G��>æ���D���� ��q~tLD��@"�#�2��*��q��8���X������M�=\�}Z�P)���T�BTh�S<�|;~rx�
����u����e$jwp�j�^$��B�i��8~������@>z=T��R�w��z�ښg�����ex�s0��ԙ�Ӣ�#��iH/ph�Ɵ�uƐK�����F��i�#kjV�֖�b���Vl	�þ}K���/b�\��C�#��j���X����R��0�����a�wś�Q[����DtMcZ��h��ycU�O��@s��=:�6�ŝ���\_˃����+���hE�K�׃�)��t[Rj�p��YB}�Ҕ��?$?��Nv���� W!�'��Б2G���$_��T��K+Vؘ^�"x:�n���������?�>j<ɰ�9�ޖ}��S�-2}gJq����u��<���|4�3n���5H�e;86�}sË_�c@���d�w�7w��L@(�p��b��#�xj�V���]vZ�RbH���p~�4;�T�J("?
�Z�^/P��Ed���d��<��|�,[�����M�R�X�]-<~��H^J_�6���*9�R�!5�U�sRGλw��D2(e
qX�iˤ�� =;�`ʿ\Ÿ�i�I�෎��'yڹQ����L�kT�_ฐ���A����u�����^������"���MV�]#3�2��Q�"�d���g'h��}�hW�$$���L���/��4�c$�>lW)��鰤 �N.'l����)��CC*Zbƪ��l�)g1�qt����z�M�q �1K3M	_K�w��6wD׊��#��sC�%�+�j����<1
M(��r�1�^���/��
����	�3��b/�9�Xm	G�o�4������S�.ۋ�"������f�0exk$�Bt���V�|��ijR
3 ��/�%0�ԋ����׮[�F4��(9�$	�D~�k)Z�E���k��A=�i�PL�i%�vN<fā�h��NjV�g6yrb��AU�/=����T%�a���ʆ��cO��&'{�0��@�����ڌ��H#al�S]����alĽO%q�o�jJ��{p�Je6rp)ܕ��(}����̏,�IY	"� �7��yo�ɕ��R�T���|����S���|!O��m����{kB��b�R���`�,����}Po�<��?Av�����}܀?Y�Q%ҤM�P]�`�B���V���f؄��q)�mjg�]N�2g�q��6ו�l٤�+���<�&E+M��r����6R�mB���XN�%|�����M����q�Þ�*�.��n{���1��VD}Ũl��$����[E�jA���[��;�)Ԑ�Yê��!��CHt`j��D�5�~$c2*\��c�+��b�r�m�ye�U@�"A��~�b��@t2����ꬁC4�����mL/���*ςCnpDvd� �|�oB���O!w�&���J�=I�b
�0�NIf"�/����Ɍ9B�`��H��lg���ԋaï>���#w��G]�D�5�ΔqW��,o����^�Z��-���C���Ǜ����(T&H4'�
��=0���j�u^b�M��t|�Y}��mh�0>+g�/�LY]sz_2�!��<lt�)^{�޾O��BK8��c�|0������#!�O��1�e˘�`�Mzd���h"�� �{���.�E��˳�:K��7�z�Ec^�{�!X=���Ԑ	�CF��BP�®!��H���eR*�^�9%D�^��2���_ی������t\����<'	 a5FJ��%+-������D(o�L+ B��i��	�hP���q�����~�Bn���k������-3���!��?%w$���ȁ~w�J��jX�<epg!,�/�K�WIo�+��nA��+��O���a�Fj���	"\�\�f�x�2���!6ؼG��
+l�PU���bd���־����4Y��kw�J9�$�M<�w'aeD-�X/�H��_�0�;c<��v�����w��f�+x!-bf���U:hGQC4쟕���y��M�\���ǧEtn��N��!�*n��8�Ăa?�-� K��[���O�)��R�W6\8|�V"hHH9���u��V����Q+3LZ
��W��CL�r�7Vl �׭��F̑�׿��հC���������#|+�Fy�D]+#xz���͹E����ɏ"�D�8��
�q/�O�K"���= Z�ټؾ_*�¶<�|	r�ў!-s��}yM�hr_�?=�9٦O��u ��!6p�-���zK�^��MKTЕ}��Eؘ�����=%;>�Qr1��T�C�AǷ^
Ӂ�Ąk���4̜�Q2����:�'B(������Pi��D���?��K<Y��I��>�AP�����K�XF��������q�ݻ���9�NQ����uO�����;�w/Y�+b2��MMr�|��nX�<
��w>��S�I��+o��#Y�k�aYR7�lT%�׸�����Moͯ�V��cpHW^�ߢ1!V��~���jl��γ(z�W���8��A�e���GN�>7ŝ��K{�I��/b7+	����qiC+�@�����z˄~��z�<��6��9G��C&W�[rq��Fa�cB��]�[�n3W=3�xӇ���[SPk����yX>�<�����h�Ƶ<�Ғ�a
���K���~���5���Ajz$���W��$���l�.U�Kv��h˂>�:�2��K�t�tc�S
uY:����nE�IG��ٷ�R�-b��1��=Y�Oa��p�W:�x8�����MpV���*"�ǚLn��wh.E0�#f�� w<�|m�3Rf���*�E�,�C�����K�h��%(Q��e�+�&}��@=D8���2��$�!3�["R3i�:2 ��Gl�! p�9T*��_ৗ��T�݇���Wd�c�U��wV�W;�Vڳh�z�g$8�F�=���ӭH���^y���)��_��w�}TH�ne�z�u
���)�[�F�zH��Q�rxP�0cWJ;�����ͣ�3Q��}��hW�w�7�/m�c���ȡ���`��@��S�6�������\�L4�g��Ex^V�X\q�LF����(�����������t������3�\���QѦ�;1�T�T����e���V���y�O���,�$��������8� �B6�Ŝ�S����˯�7Ew=P�cF+a%`�����G��2`��.<��0@��F��` wF�ܜYw������x�5z���=E\0*̘i�vB��CVX��O�nc2V�p��!H�Hψ��y�=��Қv�S�跀:ʍ�Ś� ٠%�%�{L�z��U֞JTR�ڀ�|�a�X��"��[N0��U>>�g�M�<f�\m��q+�M�WW��X�
���	 b]�|8/��i4��
��=f�z'�Ǭ p����|Y�����W��]Y�kf�A��-�$;H�����m���Rj�%���ۇ��E���+�D�OəaXQ������3����U�w�8�� �+۶����%5� ߍ/}Jo9np
&�a����O&��O��Z\Jsl~c��%�(cqp��2��llb�z�V&d�)4�򏹆�G��?%��6�Lr'��<�v��c��5Ɇ;(�5.��2��[����#�E����!�n&�Ʌ������Ï��F�[kZ�6��_��7��{��Ϛ*@j�A�|<��[nɳ:�l?���Z4''������Yȶ��O�s<�lX� �H\��\U�j��h_���I�Gx*�ڻY�������k\^>���u���(  <[����{�w,�̥�Ҽ�N�f6�x��ҁ�^fJ=	0��:��IW�D���v��f����yJG�&��+�?��C����Tfh@K4�Ty	�K�_���E�ޒnFݠ�{���U��#��P�n�w����R��������H���g���p��tX.�_4[>�&hVx��v1�xL�ߤ��'	�*�}��hU���[|W�?���0�N�2���C�W�-N}3���Q:n�^�� ���$3ZV��@SM��"�dK&�#�����&� �М�)��x�q���N�pǴ���z��D���9.��2���`��E/L��>Sى�I C�O:���]ۅ�1o5�rT t`�OĳĩDk�u��\j�m�CE�����#f��?���x#=.,39K\݁�dhv2�p��a�����k�W��vK���QF���ȅ��?�T��I0iG���g�D���v+���9�Řt"� R���
b�,�Fn�*q?�߁�6?+���qN��h	�jN���Փ��y�IvdӦpitpn�[����,�0T�ւ��Ĺ�:R���g�o\��'��CW~��h�t�x��f@�l\rjb:Ԁ�[�+X���IJ�؂Y�:~N��3d��⬆x~�V=#k�������/�$���W{�e7L�׌8gM]j�vP�1*'�U���)�v+T�a�SN�N���{��d:&X�.��n��7�c���3�v߹�3�_�4l�~M�3���k��^q`�b��n�Ub�O��NSj�3��:�i����J;5�f�&?��:�ic��i\�`o���"��їV�9DGc_2�ꎱ�7~�:��5��'c@0:$\2�Yа����KA��c0��fj���π����	�Ġ�I+��x����Z����d4N��؝���R$���.��p��c��4S���:�1s�O��c��硙[X�c�y7J�1�ڠ�R�+2����-~A~���y/�f�Ɛ�#���O���Q�����\�/�h�^4C�Ȕ��Ä���G?�n��/��v�>�D�IMa��BczP��Z7�U|W/
�ʛ	�^�x���`+��$Q��?���I1]4f[by����И��85�x�G�߯�"2
z�3T<���q���k�#�|D�BR!q_TҢ�����-:���̧�n�=}#2i.F����X���5��g
��Xh����@$����`Į�P��ȑo��oJ�o��&�b�_��m4��U�'\"W G��C�|A� Ӄk���Qh��x}��+Mƍ��9l]>\�`
�{��a��I)�qb���t�&$�*����=Ld��r�ܤo Ge�я�6,��[JX�_P7K�gU	�I��}-�p
�'CB�{�q��/h�!)ւ�!xG��[��|W�����QӚ��Zֲ�X�~�w�٫��5�'N���x�CI9��ż
��/@C�<1=}��?!�M�U#�H�bH���}=�2�l�Js���.�؝��q�:�yتÖ������֛�]�n'.�!ZڍR�Y}��MV ��-VN������ �C���R�3��(���4�����I�*=��p�g������}�J0����v����.u�>X-\�b�P�]�N��e�42\��hb�H���R��#��e�?���x�Q:�೮��u�oh��B��y��㸴��t�ކ,Oi�bQەѝA�/s��6��C��T%��/y����0�q�u8W6��K�H
4Wn�W�<N̴Qm�E��8;���?�B��B~�A��8u4��g���Va(��(H���v7j]���S�%�ȅx��>���#�Z
�V�v��i	= �jH���F�P@}���˼����ô���Ӂ}��(^��ML)h�آ�X��¶悰0�g5QW��sc4a�n��w��]�(�N�i�'q�#�p�q��%nÕP_o�#�x�`eh��gc�VDVx���D��Nc�v]W���x�)�7�F�Q�2���iP�!;}��1��f�A�l"L
�B5%��]��u�p�T�b�5�:j��"��vc\y帕.U���_�
~�j&IK���j�Kf���&��,� �ME��`R�l�&�p�P��z�g�]�T p��Tݴ`7�ʤnrRI���ҧ��@j?��pl9Ӏ��c�9��G`q�=&�s�GE-��%�e��d�����:�أx���ؘ7.�~4,���	mjy���*U���l��¹��-�P��� R�!f^��������z�cU~п
��"�U�6�����ؕ���p���zVcHw7z/�����[�1�Set����-�A�]���~�z�xoO�\�"3�sB(B4�vX������̥� #$vI)V�ѝ�p�������O��L�V�9ߛ9���9�W���:^͉�hU��g����L�(0�'9���SA!6�U]�'k��&�Wl�:��s�x�ߘ{���8�>�Y��EZ	��?�����������w�7����L-�t[�mT?�g��c���uR���m�d�i�b�z��u�&9`-W�!}����M�rZ�a�]=]�^`?W�����0��g�>�YE ��9��P�p�3ǲ��R���u�Oڳ �jO/�1�����	����/�3�>k�ci2	��/W��E�"쵶Ԋf��t��ήW�oo����a�"B�Y�������m��l����%��e��3Z[J���R�X����dK[9Ĝ�:8al�F�L��!|�2�&�O̿�ta�p��:d��z��u�CxA�$l=��C�G��bU��E��a �e���	_e�+����Es6P>,bD��'	H��p̣>�jW����f��1ȫY��c��v.w�N��'�Ob�GWɑ����"XK��oiEx5~����* oO���N��E��w$���эދ��Ǯ��R
�-�W�8(�8����h�Ƈl�-uل��՘P�MgQa�/�>��m`��X���r+�U)��'N(�����q��)��ݴ�#\2E(+�##ƦZ��>ZNeL��0�T�OK䏝�r5�� �ְ�2R���Jrc�fi�<=�_jO���L�I5<�l�fx��w"T�r�[���~��b�	&��Uϓn�dk~uT�k�V��`ث�b��k2��W#��y��5b�(s��h�d_B�$����h�����g8XL=�k�����}���0����i�Y����B#Z�e�������o����&C������5�<Ъ<���i��dB�2>�3��j����İdo�E� ���!�E~�*N������k�sxm���#�v���jE�{~�b�(�v"}�{��m�3�q/ab%!��������{��$��uY���D���pS�����BY����Xw�V�����$�US�k6���w}N:��z��B���܍U�FE����}�(����=�3�k�{ە��^VfTE�Mɛf�+
H��2߅(����ݵ#&	�[?������/b�s˿�n2�L%t�ֵ�3��
���r˕��ˇmNZ�1v��nQɻ����UCף�ʨrN-o�[�-��rfu�v�E���l#%S�ᶙ/�;�=�y!�!��Bv���i��J轢��l_j�T��\�2�1���Uw{�ul�ɼeh9�����&��Zr;��
����d#f�-%�J'��iGR�����v�ې�--:�;`�����[��ڃU�۴��YC���sM��I:�D������^U���&�
�n�gA���>�(;�U f��~�i9[n�S�8�IC�5�L��o��(/e�a�� �G,�Q�QRl5��z�)��s�q�V8�U��;�b
����FN�+yO�/�Rtgz���w��pg��[?���D��A�u�#DmX[0g4?�sY,������H�����Z��������ۊ���إ�+�0���N&�z�����Vxa�O�@1��4��y<O�f*�����I��&���h������=�K�
=6�+k����\hU��;Ձ6���
Ԥ��xPyK�.�ǖqЗ����ڇ<j�+�]��� �`�:�b�6��ba��XlP����]ׄ��y����o��IG
q�v`NԨ��~6�3�dHW�8��Ywu���Z�U���W�����>[V��?�l�<'PY8qnn9&�5|�Ex��Y���t<:LqN�)�kO����/��ѓ�y!�K�CS���j�k*r*'�#<�EMٲ�����`7��wF���O�dq�0&�^��c�"�
t{�{�o���{��-s���q^�9̴���xD��lS��M�:x�y=��찜��No'���X_��	�m8�B�E�B����A�,�#�����Z֭��1���y��u�I���!I�-�Y��"�w6�i��O4�jk_G���v���U�Nj�)�SQ���w"�\8�$������z�G���l4�S��uت��9�G�
%�(�eC� �)����`������(f٤��=�	H���'U��X�SxT;��w�(~�t��@��Ї{_~����Y,a�UN��G�lo�R�Q	I8L��S,��v���~��ˉ�N��k��E�+&)�.{m[��xh(Z�s��S~?T���Z�Y�F�Y�	6'��p��S܄tV�g���pu���Z|���zC�	���Dg��y�F�Ch<���W�ɳ顟�>_�V�9��X���s��I��Y��z�K�^?;z���3zm����1k���;.��e�;�t6g�آ��̎ݩ���D��]S�o+[�#+rCK���O��C*�Uv�k'�a��+�=����<	�#������� t��u�ݱ�d�M`rS�_1]�b��)]c��4HT�͢l2.�p��3��_�6�Wb���pGT���n�W��*��t��)�D�ĥ�$7.����m����     ��B�;Tt ����LN���g�    YZ