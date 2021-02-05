#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2942159292"
MD5="955448bade2dbe892569dedb223412c0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20896"
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
	echo Date of packaging: Fri Feb  5 03:00:54 -03 2021
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
�7zXZ  �ִF !   �X���Q_] �}��1Dd]����P�t�F��ip�����M����b��S�RI,7���{�Fޔ�V�Ne�t [�&�n9E�[\x�i��_gYH�O�"j�����};@��T5k�%�gM(�m@��<sf��S`�u����[��@(]���$�Z�.: (�Zi�D`�}�4#��%.�v�����c���_�NGc��k�{j)�UU����	n˘��^��o��$�� �*Kw���V��:��|Z���a������B���ys�pHq�\JUh�V�ʪoT����^�l�A��O���:Ѻ��<E`�p��A��I[,V;Դ�x�e�z�Ffs8��S+
�<e@�X��䪘�;n.�[���:I�t����F7؟y�T,�.$���|�B��N�a�}2��ي����{��={�
�&��؂�_G���[lj��BF���0��<J^����t]Ě2��l��`#�=Q�\V�=Тd�<�h��+9G�38���$��Lݜ�S]����ʛ��F��)��ie1nR]�� B�� X�'/�l]B�z���W��bnxb�d�Y@j���W�0�L�ƥ����<X8���Q5~�m���)�@�!GR�T�-py�=��d�y�~���:\��7�lV�g������%n�2+�L�)�����b�dȁ�g�1f2��}���&�7�4y�s(֐��M�A���;��m���A�$Ǝ��˪���Ȝ�bJ�i�x3�*��1������b�����-e��Sj�/9:�q�S�j��� 7-6E
�q��R��-�=�T��B�xbǹ�g�>�"�BʴwW �O*e
��1���[ݵ&����F6��ɠ�@U�o��\Cy.@�A��sxe�p:հ������cxLlo�Of֔���]h����.׵�?���W���喱)ɻÁ�*�_VEE�ҦJ�ߴ���.T0K��H����U2"�g��+��W8��PH>�����e3�^$lq�ǙG��%�6#�<�?K��-:!���k�X۝}_.$q�F�
h(����jٿ��{���o?�-3�f����~�.��^�[/%�
j[}���ͿH-�1�T�T���?|XzCt.G!�?��B�����M�Oi��yʤ/̵���.9������!����c&TuN�����"_����>pxЩ�>Pv��M-��0.G��\���+IY;�H�}u����	Ê��,	�ײ	�dH*n�Il��y]B�����z	8BQF_�5�VK�o�B��.t�)�­�i"Ŏ�˦��7^:���ϻIb�[5�H0�u�Z��?9&ѯ�>/�m��i�O�l-YQ�t�9�s�I�ʩGKw�'�&	�p��=wrc:2j�8 �������U4?]|ԩ�әj��q�6�Z���z��c��Y���`�8��z3/�3�9{�@���;���'�o�|%������X�֒�9;���ދ6\��-�wB�[�w�>���h�W���N�]�=���f�j�[fY�Q��	��y��E�0�Uk���?�S��Y����`��S�h�0��-#�9�n(�0�7��i8�lw9gx%u%;�����O�{�<F��R =����w�u�� �r\=�
�w�a��.�)����Q���0ZE���q��=�?�v�O�[�L��%᫾!k�k���e�j�G�8�
��D*��;��f}�n�%n������l)3@"������\8��%��]��y��cd8xM�����n�x�;Oa��\#�c$���c�Z1Mp4��
t�\�������n��~^�jo��a;j[�m��;�g�N����d1@9ܗ��1ﾣ���I8y�9���D�V�\h K��b'�0��G��!ƛ���Y��1�}��-�\f�� -�$�5w�m�R0����|�}�l��	Q�n�(�=�y7���t[+D���k۬�E�� ���[J`7}�i�����똙{X�x�x��F��!�<PYh:t�܌Ŵ�V��j_Sg%��ܺ�k�8Y�+P�*y�h/;��ϵf�w����P�A���"�X���ז�L��')�7S�o!Š�9��I�������w�/h��,�g=M��|�8=`�/��J^�Q���7ˊ�@ył�°�n�2�����[� -�-�4R����~�l�0q����ɥo'���7���8�d�$ 0�Ӱ��`8�K���Ҫ�9�	��2��
��:�ʞ\nk�%Y�F�Gnj�΍�{�˒�h݇���.zn�����5���)C'ڦ�7aŲ��ɏЉ��a��X�dt��e����-V��rNdH����:Y�\���k�C�����S'���u���R�s�]f�K-�7���f��m��ڱ�x��'�1p�ǊR�3����j��ղ�,L0?��~2���#�T�?�9���P�(s���U֞5&�����Y!dZx�MS̓n�$|<��`m����;x���*�
.�5�ˏ@�=�XO�AKm�LPA�e�K&���[Ŝ�X��a�j�\0$S�c},x���x�ݣ�7�/�}s�*��*�Ӽ�����B&:����7 ! �1���~uP2�W]~�)�Q��?�F?��b��Oz��h�U�L�^�c*��u�p��Qk~N��t�|%�~8\��2�!�X(�R��� ��KD%g\I��`t���%S)JR^ B��}P��5�bU�T�����Zd�����8��;��	!��@ƙ5M�Evb�xC����$��!�c ��%�g&���¡��𒌾��"{�K⤼v��ݻ*r|�$�ډR�p@L6ϸ!]�q�#y�6tڃ�}��n��&�A�y"z)�(��T��;����I��Ыz v�]2��0;ˮ''�1.gO L���=0�F����e�,jZ�,>������(=[��F �Q[_�0*��P��B.� �8"�Vx��|d~�1h�)��w�0�Y"�W*��fe(��Nj�˻pCU�}���Y��'�}�ݬ��?��2��Mg�QX0�	�K��(b����?S� �d�F8"�'�M��� 5�AJ�5S>�w��K�����Ə��M�qm,vp+Z��B5F�V�~!� �Ub�D�:
�T��3?�� ,�A�ξ�%2�g=�>�j�O�)}��4�̲�EF)蟿�:>)��R�J����T>v*h(�ɮ�umj]{h��|ѭ�K�;��>��g����l
F�D�H�������o�%����R�X��C
�bA/�����j8ΣE���د#�h�߈[t�[;w�T��>�$�O���ș�V�l����gf� ��E�9Dz����\us7��(����--}+�иd2UhP��@'n�5:�q�n�ZG�U���P�����.*��I���g`��X�.b�<$�o��;�y�$F�^����%�?��`�A�%<GD) 9
��<�{в���K��*����A���l�|h���}��/�W�X��X�,&�,��C�+�v�AKV7�\�=ua4hc��+w#��~'�L��g�V@��)���9��@��U�Z��!��g#ć�%�ڕ��� P�)W����mo�$���v`�<�e����ֿ��M�"w
}'~����v3_N���>b��I3���S�?@��k����q)�2���y!{@�!c�W Z ��*�>��	藼�3n_��#`j&���/c�
#[bn��t����ص0O=���hz9��7�ZJd��'%���?y�>O�u��Y>��Q@ʈk�gꗣ����W�����Kɺ�udy�I~N|�*��ʱ�ړ�������\�8R�\��� ���zH�k'�`���aI�����H��ULX���EҾW�<
8~AE�Ҭ��d�d���|�ZM��_�>.=�횥�[b��#5�"���a�M�w����P'�k&�'����S�w
HVѼ��>����B@�hCң2L�<�/"���oG=-�����y��p� $ �$kvm���R7l���j &��$n]l���3*A��\M�*�$�,%+݄szms'h��>�����"ư�d��t7@�����<�;��Yfa6�&�q�.���O� �[�·���mgEF�(�@f�zz����c��|ok��s��4U�Nʈ$ ��؍���k���������Y>���÷T6=N,�2����E��f��D�3?�F+z������9N���;B5ÿ"��8x�Y���Τ�X0�c�.��Q
�ay� �f�(K�F��FK �ƒ	� "���TI�) ��r�с���D��gpL�k��m��~�%�j��V�Y �/g���7�%�,��$��J9 '���gq���뿗�MK�FWS����Jӊo��������/���X��R\���_*~�1��9Rn��_Q���qot�$p��dYO��ҝ5������e̔�����ä`t��@��F�x�y��E%�_�p;{�Qfki������![�(��NZV���H�WN������<G�ڨ��]�궦��6&I��oMczMM�"V�O��$�YĖ�-,@�	`�WK̺Nd�r4�.�4��|p��ڪ\|r׾�E ��]pIC�`x��`6�e���w��)w,(y9����I��s���a�-!��$l)s�,#��RBrrĹ�M%踙�",o �q�?�8�S$j5��y�4�Ձ<��"��Lp�N:�}�&��ǐ�x|��)ijn� 1�#�#�u�a�!{E�̍����#>8���(��d3��%�܁/f,�V�$ʟ�tUN��)���g�����&W����5��+Mˍ	f���!����s��nT��D䀽������@J��PY����l']r�U8#��r��${��=�ZO�d�e��V|�Z
��^D�U=&T$,vG�a!�I8jιU�������:!���C��u���H��|t��<<�_E[�h&I� ��"Iz�'B�Lo�s0
O��@Sv��(%�塅�:�bg$���(������G��d0���b�%;���@[�^�|�Mi���[������ �����o+����H�&��h�C�
���'Ԉ�EA��4�'u�D��9g���jT' �dpPm�;����X�\G��,^+/�G������&�O�d3h�)g�$1	,�Q�.�g�d�e��'�V�:��:Lۯ쟍s��é�ջEL�1}��t3�j��h����>��(�(��ۄXɀ�);�hIL��I�l���N[��Di�DH�S����H�����k�8����hf�Jj��u̴u�+���V�6���{�뇍x�C������K��*~ʵmO��2����4j�Z��d�p�������rCb�2���:�Ń(��Z�I7���Kc贀'z�5`Lr[�A^���ʒ�ߦ����1gWǫ�\>LP)bɅ����TL���4m/�x��6����N��J]�*��]��bE�S[?�
���D�%��pY�I��5Pܼ�+o� � ��?��G~��ń,!�HG9�&��I�<>qs>�����+nt�`��e����[ :��sC[��K6�W���5Ҫ7j�k��s�d.yv�7/u�o��M7�V����.{4�ID���W*��J���Gp_��?�Ma�sd��Kг��{��� �µ9U�skwz��[����(B��?na��7�?�j� S(�	�w�������q�<}���E�W$�Ƞ�%u�E��#�=L1�=,w�B�Җ7�.g���fK�9r�r���<�ǿ�I�&@.l��=��E�Jq�d��U�r�\�����{P-�;[
hK� �K�tɧ�pU���A���Xofq��\����H�P|pȜ㿂�-��C:i92����8�����'�e&� �$��,�/���ɂ�Ux�9<��N�>%�[$x��o��8��y�c0�Ԉ.i�����	��A��D�Q��x�d�y�p0����F�R��D�T���=��֢l:8��IP����z�lq����Ӥ�pf�v�r#�y�!�t�`r
R����J�C��aYk5���n`��D
4�=O���nB��+q�n�A�H��~2���>������!��F=k��j��.	��lE�d���OF��)�x,y�.����6: �'���1�؁kK/��l��N�,Xp�j�wU,�g�uV��pK`�S������&0�ƫ+	��H�w%��F�uP���L���������4��Ȼș��T�7(j}��}5�Qby&�=.pH�q�Q� q�C�tB4/�j���� %9ث�&�6|�"�)�&��Vdؼ�X��(!L�VZ ��@�_^
w�l�)���X�	�c�&7F�zxU4_0^V��c���ɜ�ʚ��н��f�ڗl]䐼Z��	��P�{k^Q�:�;���A�����}l
��8Ҫ���2q��-�n��	i�4W(��+1�A�1�]s��L�_�RGs]��A�G�8�M�0��=��k�^Y�J���:��-�k��F
�D���$N+��$K{�����e�H�k��_�gDV��O��#�O��[ZG�#��g�T l�y"�Qg��z�8�ow(6�̉�*��{�y�7�B��m�Eۯ��T��]��H�y_�j��P�x�K�*�͵�:a-��L��zd?P���4n�-pv�̕�Xt�Vs'�~v/��Q1]8��/�Ԁِ����i󽳋I�H���M�PJ<P ���~և��p+8�û& S5��v��1ԉmf cݞ� �ʛ($&�*vH�$I:���7�l�40B
{���Ɲ/":*�s1��|on�t9�\�Jݐi�V�/�;�G�ǘȲ�E�It�t��Kɴ	�6{8(S�0Aki	���F�i�ˌ�T	�;&bzX�>qß	��+�M�B��Eg��p�>vH҇����x��3~�\:&�ce��MWH�oe$�%�o���� >��5�ԩ�@�FE�x�q��|���EK�����k-e�@�AP%
�Wٹ������>(6��=�xU)��*%S�S��w���o-��sW48��\�xױ_̿�V�K��nO�vG{*��H&�R�Q̉/\�g��_�B���a<ƥ��&���h���<\��V*�A�@I5˼��ܳ�WM9����`oL���v���Pz����{�)�6��6C�͗Q ��'����6V�|1g� W��!�;�iF޲ã!���jeA���p�/��Q���Ǣ��d�:�8kz?MI�dC�0+J�?a�`~��f^F�- ��.t+�F��Rw�1��D�b^����N�8))B`.�hS�{yL���U�Է�������+#|
8C!�N��H�Sf�K�|�f�|�)�%����#���p����)�:;�wm1̫����ONŐ
��0������9�J����U|��ڎ3��x��;�[�\K% ��'�%:��Eӻ�!�!��H�y'���p7X��&��]�tl�|8s
��_
ׇ��#��
�Ԡ��A�3+	~��6�r'�t����8��eu�@��K��_o���i*����jG֒e�BU�Q/�@��D��1a�8�����+��q-�	1p�����{�e8 @,�F��uu���q1����I%!�#�+ʘd+���`Җ���CD &��!�5�������{�P�5��T��L�J=|E�%uD(m��A�]��������>�\��ke��ȡ31���ʶ����I�����e��$~�����ܫ�	��F�J���gO� � �#�_��1k��U�VQʟ3|�g4���l�,l��(��6	��S�S��il�)�e �#ӽ>}J7�����HƼ?u~>��[��iٲ%X�':�Lv.'4�Z|���}[�p"AZh��� �4�ޚ�K�)Œ�	�S�{Q��R�v�}S�{��Cr��P)����ϓL����qUy���)M�ۢKщ񦔚�tpW$*�I#0�vQ�Y�f��W2_�����p�%Ύ}��0�:|���@o��Vk�i!�q������m�OB�:�Rzq�8G���M	���7v-��M�K]��* �yYm���Ǚ�K��)���˻�w�����-qSݓꦬ^;Ǫw�f}�6�4KH�خ��ˡr>X��t���4���2_n�s�GM�|X�q�K����D�;-�j����B� i�(����j�ņ�����
�.,$� _Nsf֞p��v��o0��||�$��[;�E%P���2"�u�/�$1�Q����KE��fe��{�g�TZ	=��/Ch$�lۧܦ4k��N���V>t�x�T*�#���Z>�2����� �׵
��婹<��Kuakb�����~�k�@v��X�U��r��MB�Tq�P��]����R���5y���A���7l@��6'KD�.�8�v ���>P%�.�UŬ��yO¨r�C>S`i�߷Y�4Ur�z%�m�f��%���$j��Y���Oq���]�|I�x��C�����.��h� �W`�۵��lr��U-��a�+��rop��yf�FCV�Ks`�����'p��"�j�n�F�>��t�Z�Q�(�r��:<g����P�#�u���Z��oS��kyD��a�zT��4�*?�M�K�Y�:�
�h��[.�N��`�(�؇�Tb������]�I�V�N�t[���[� ��\�)\�WY�0X��w��D��/C����'Zw�7�����eh{YzS����@�yH6XV|�"x��1!-+W�Be��(Vh*Q+�i�R���^J�Q�	��~u`#�TH!]Ȫ��ީ]l�hF�4��R��zܗ�_� E��FD5d�^�Sǰ�����KR.,�	Q��}�J|tf"%q��콗�1�U�h>/�i�x�b�+�u��в�>�?������&���Z���=Q|f>a���Z�\�,���Kª�ic*��ZK�$^�su�m��N��*�Kh7rA�F�]��[v�;�%)+b#O�E��\#FY��<\��r�����s�q�	�5�]��I�����(x~9,o�i�1�8�� N�{�)+8��(^��T�i�ӵ�FC�D��� ����~ꆾ���&�E"��PB��=�����~^*xwN7U��L	�@ �>S�����
��$���Yc*mH�셽|�.�746��e,�T'�J���wB<��ޡ����<7�	Q�:/�v1��ֱl-q��40�e�E�)���c��#W��۹��m01v����8�7)?� 4�hyQ���� E�mG�G5ۘ�#`�|��ߑF���N-�2�`���=xճ��CT"C�)��\K���ӣ��;�� ��pW��`8)�դ� Pi���K�� ����.p���H���1�ԋ��� ���F�|�nbO0�Pg+*#q���G/97,9���G�x1�um=B�.�Ѱ
}�\>_������n���������0m��5y!	2��}R^Q�M�Å^�����53�����٨�;�����L��S��1)�|���@���T^�M������
������C��)eŵb܄�j��&��9(�K�t�w!I��x�[:7�,.܃`ct#�H�k"��JR���Oˋ� ��^J���ӭ=����5�}PE���]^؋2�/���3R�-\��9v�md�Y{De�ǁ�Phυ�t�%"�~pt���I�-:&a"Q�4d�Ö��h���# k�Ŧ�:� �Ā��_���xe�l!���C3	�M:�#�~�uݗjф���Pٯ�����2A_.~�=4G0�y	u4���=��^�E$�[=iǛ��:��=�����Փ�f��x���]$�侑��ec�/^�f��YN��д��Je�m��:�Є��f�M�j��4X�T�'��O,���1�6�٣X�K|)��-aЭ��Ѳ%�R�����QCrIN��������6hQ�A�0�*M��#I$��)4�h5c��l�1@U9+k5�����X `�X|�����d~��Q$H��x�A�gM͹��DNK��v7�3�B�x���4�D�5O(ą�83�Łư��H����9�&@��'ρ��8ޫ������{W����	���{������:N�3ˤ�a�A9̴��?� ���1�tN%���Ġ�i���E�5�FG���?2�!k���,�ˡ�2��ؐ6����$�4��pK��W�V$�#�{��zW���&��G'O!+�_o��������4�7��^1�����u)����O��Khx�״�b�5��>�i�[��z��h�S�cE�K
!Ґ?-)I��J��i��&.T����.�R�8��'U��;Ql����LdYF3����	�WT��X��l�n{�ĤiA�f��Pa�Y��l��wsƘ����<"j�Z,���q���\��6�d&�k�{���̉im�)�p���'�t��5|5�]e;����BZU	E��F�W!Ԓ���<"�-��
����� ���.94��qKx���@zV�	U��1�kA�����t��G.�~��}�*J�4铈PY5:���J%)z��aQeE��P���j�M&	�s}E"� %��p�� 1�$VX�L�*D�"U'xVm���b�,���ލ��BtSd�D07؛%�b�<�g�X��:Һ��'�;��?I#�� :�FG�����>ov�	Q���4���}a��j���1�����L�BL�j�]��0���{,��)s+�l�"�����e���?���}����~�ַ�{,r�N2z��S�
��rX�������K��,��" ^6\\���c}�3>�w7�"�@٨�%۶��K[�*c����gD�Q�����5
�T���w/��&��R"ӡG-v�\������l�%�����x��W36�= �B�2( l�N�d�	l�Q�%�}�����㛶�����ʛ�L��7#�e8/�5+V�c����K��N`�(+Ո�i$u1B�
�E]���5U͸���/ʙUŐ�t����BKΥ��$v��$��n>����v3�6!�Ӟ�&�l6��\���TWr��^���d?��@V�E�˸�v`�↛���4�c���/A��C����V���V��-.�-�]Hާ��W��=F���hs�i������`0�������(a���ғ$�QI��P�����>0����C����@����
�dj^D��"m�C�V�c�����sG� s�޴�w�џ���ҷ�ҼBh� 8ԩ)�lf�"�]�2[�7�(5�'�UG�q�\�`�5�^U���V&lB�|��ј%
��-�\гW�������Iz�h1����1r��|tܛ�,�zŲA�Ͼܛ���n2��;��HО���2|!���q���il���&�Qy�((W��)>��71#U��iY(��1��g��r��Zֺ����Ur�6��z��`��ĳ�����j�B�W]L4�W�nW:L(f;{aA�cK~��D�x�A%�:�hw_=L �-�kx��Գ~��K���H��G���Aɒ)���F%�޵�H�ׯm���x��f�/1��	�����\���[�U�wT^[��l'A9�X��F푰��Ʒ�Ԯ:i�_�8�Y�l�gI�[�u����~!�SKՄq�_����m
����Og�*+�ۚ����"kt�W�&�������@�}u�+k�z0��-��'�1�C��9��rz0�D.���Ggy�d�䆺
0*H a6'������ۮ�tR���/5oY�O�����w�M���Lmr��F����M}�j<��Ioks��P���̲wJ�d�<Y�Y��o���Kn�0�7��@����7Ү��Q��q��#����7
�ݹ�#m���LA����!}�uR;��"K$��?e���.��Q|������ʙ0�so�5Ibcc5�][���P����CI�TT��Q�%�Pz�J��%��
0���A�Z��{}X"�n�,�CF:��$��NrA"��m��#6y%[i"�U,_d�;X��V݇-4IoӲ**��nq8fP�0s{\�E��Z��K���j�t<#f@S�>��ǯ�{؟��������?, �����k�#�+½iy9e���:6��j��a���5G.��
U���s�Z����^�@lӡT"�;u%o�Χ�NݹDo�p��A���[��1i�aC��AF�!XpK$��Z�J]�{�zc�R�����wY�zo z�>��1��Վ*�{�r�+O
L�>
�0s�h�;���v�u'�<yX�6(��A<��\�DeE������F�Oly�z�_Dd�ЌJ�DIޟw�A�����&v���4��94*� �,z�b{�v@�d�#�Ù)OL�.���y�-4d؅"_��f�������6�`�Ƣ\M�zK�sG{^?ۜ�D��|�S-w�<����@<L���قz�/�˻�d���$}��} b%��#���)"� Ҫt�B`ZApHġw*>V(��	���p-�⢊C�߄��~�S������Đ1�'�Y�
�pA���z�,E�F�D=��q���)��&�(�Ϣ�E �H�/P�x_`C)��K:�͝\:�Y��u.�~O°3X��R��L�0�9*���H�V���4���?u�P�O��qY�fӣ(�oʶǑ���!)pV���gS#�n3.�kA�����<��R��7m����2���	�)���2�'"�3���e�cYWh`�-��ι�J�ɿ����Z�R���c+8�]�%���n���f����o"d�tD���r̌~���.!ŕg5PS���$�<��bZ��	�����}�erWH�r�l��o��,,}��_��F��4�p!S�g�-`��s%bN���4V��5;�:�'��Jl�7�o�T�F�n^��0��C��c�1?v�J���F��s�`��������R�6yC��͞h��u��A�XܮQHi3�_���I���W3z�}t��ҍ㑋�Z��ݝ����#̹�kA�����V���K(���5-�֠T!��%��l/F^��6��yP<�E�L��c�}l`��,k�`J���Z	�$bM� �B��W��N��r��B��ms�� �L!gHP8�^�����Z�m8�͌�Q ��?&���&CmBdV[�k��1��EO<j�IVY�i�%�'^�/�%����LDfd�x�~��e,�k��7�`�H�dB��o��$�"���Z���څ&��Ek>Yw��Cӎ��A
���UO��;���D(��r�G��I� ��ts8�.����$��F��Cb�2K�����&h���Kf�h�s��' j�|�Ϧ5������z�|ͨ��>ə(�X~p�b�>�=��=��53>�2?����?��AU���#a�jm����A%I�vpf?󛳦��?Λ��(<=�?ģ�勪S>��F��;�6rh�Y�c��8��8�� 
 D���5R�츣"��ő�����L>�8�R|#����P�DF�)���Q���.�￱��BGh�V�E�������JBl��W�8f��S�T)1���
l����Wedɉ
���{������k:�I���R"�bAF����B'�����!B~�3ქ���VѭT`K���/f�Rk0GD��~뎳0����l�$���"�Nce{O�{�	�I�q��7����.RSp�c=�d�ugp x֣�\���|�_����s\���{P�d�9�E�sP���ky%J�h��m�r�U�����lj�v��T���+��1j��WĻ1d�Qm�7bX�l�U[����a�`kLy�S�,a��h5�s��*�̢'�y����Ӓ1�b��.��n��93�W�q��D���/	��|�U
���#�E��u� ���EM�P� ���"¼9̄�$)S	׊I"�>e�0"����#�;��h��]��T����+w�M��k4�u� ���v�!�`��[�,���a(�%p��O�8�"�+�T�/e�z0�]�Ͱ����*˚Q�k�}���K�N��{_�0�tχ���O Wm%9�̊u�X���l�:ME�ƫ7��/?L�A�4RN�;���0>�eh�Mux}�/N�L���k� niỈ��P��R/ÛdXl�R��V'�A�#/�r��1��}A��e�wK|d������C{]<�?���%�\�:Qh��쒾�,��]?'Re�i��`��
	u�B���U@����Q������Cj�R�8*nLr�^���,�ϫ�72N��Il��7#M���+V-�ٶ�.B��^�iְ=�e��Z_Z
TgHn���f�d^ �y���H}5Rz��$��%}���8�O.o�~�W{n{�1��%�d�vC7�dL�Ζ����ؽ�r��u��u�q��5���y�r����&�-}�l��^�8�2k��r����dM=s�g�"�����	I�c�@����A-��	�i�2̲�ڕӞz��I�]=���PA��Q�Kjn�z�G��pw�����L`�y�t���N.�	j
6��ȷ���/Ų X���M���'�݃Ћ0���	=n��ψ�-%�����w�g�� �%nr��A��)������q��Ԉ�n.�A|p�lq�߫uС�T����w��%7xk�h85ō�^���S�b��c󵱫{6��`R��
�b^U�bLbCǗ���"IOH�v#���yQ��A~��s�9�d���#��	 !~�����)&���N�G��"��0&��)� �M�ԓH��ٰ%{��x�\�da��b���+1t�9p��;=l�4�����.Ā�$���4�D^D�>˞��`Y�9l/r#��R�3��-?V�;��JV����|V�nK�%	�
zQ6���M�ϔ#BDr!�F���VY�lu:������-+;�N0�-<O�f�s
��Vۥ�S'���D@)��m��qpOTM�#�%`a�O��_(��gɃ;��C�5�^�#������d�	j@��͠�����-F���g��@3���،�y�nD�o�p�P�Oj.��M��� k��N��D���N�IU{�����I�+b_ݱ��r���u����qf�*�O٠�e��_�0!Y���>�Z,b��-���y�G(8s�AUY��u���Pؠ��ꅻ�N�#,[G�ZW�EA�Hfp#w� �I^�3�@01�����يF�&�M#A����`����,.��
���#���8��y�Y��y�������~.~��L�8b������ǩ��y>��xq:�:�Q�E�Z�K��8�m�;��i�Ǹjw,
����^Q� c\�񘎝)��bhSv��;a�"��Ӵ����l���"���fI8�k�j�8/0�g���ae�q�iso!�R߱��CN� ��y�y�T���B+(�a���jr��I�c�G��;g���<�߉��<��ذf��Op���i��$?~�1ڹf��Ĩ?�H
̺u%���d��|���J+��3�tU�G�:���j�:G
�"��^��x��������
Be�<H LT�03!��
��
����d��VF�;_�a��g����u2�p��=�	8��p��;�`���3\Π��t�w��h�)��7���D�_!�C�Y������	D���O�@�e��D�Pڠ0�ŝ����'�|-y���q:�V����<2�ޛ+5�.���4uEē���~��a�?hҞ�!A5�)2'�`@��r��v�9�〶|�E���2�H���@|�g.�M��EH��,Y���w����1�����0/.�q���H�PU/Ls��[���Y�~��;��"F�P>�R�q��H�Fd�Z�ub19��'>hЄ�G��l��rZ��/E�6"%�'ԇw|5K�Z������]��3H&3��u2�8uv�H}�D���-�k�ij���0��U<���z��/��i��
���$���9le���$rS��ۈW���������k��Vu�3"˕b|h�.ť��f�/��E��œ���Z�~$���#V����씖��a��6|5��ⓘ� 4�if��tv����>c��PV��4�� ��$����8�������� �|E�e��&>~�t������'���ڟ˭@r٨R�S���L&��D�R�ާ�/<-�`�'�:b�� ��L��\��tn�ec"��E}���Bc���;yջo̥S�{ǉ{��=���ѽ
����4����g����O]��L�y�߀�Rf(�P-1�BAj�}�%�e�Sa�&�}{a#�/�DL�*3��^.ª4�ztv�W��x�E���Mt �+�š�­+��cq���8ǎ�Y�-��Õ2;��{p�RQADP�|����k6���������%��W��$o;U_��j�����"�A%�-�t� /F�u��;!�ywʟ��v��e&�(��H1���,z�ص.�_� ����!rU�e��'�Q*h�4�p"U� ����G����^���_)i��E��?%���p�YI�f]�������9����؃F!��+�Z�
�?�Ol�z��L��4>��ɏ��x����.u2.��p�y���y�� �A�t��� ��,�xH1xTN����D������ ��Ձ��{�%��r�|	�j8�@l_:>�գ�E����z�����yץ{xJj����/�Ӣ4U�Qq����w3Q�x�:��Rk���ij�@cpt�2�wn�b�X*rWBF����βnh_�`C�-1V9R[d���*�2�0���zڏTYQ��#�~��i���í"�5"�ǝ�����	�W`�Od������ �S�vV���w.ԍH��(����=���&;{�w*�U��B7?����u�ԟ���Nbbg��f �듽�A?~���	c�|8ϭ:��Эz�r��}�'劓v)}'s>}��\��Enb��'Fd�I�Ӈ�H�q/�uA?�����zy��e�eA�Ц��+>t�w��0CL�`��"Aer)x��_�J�uDO\ 22w����~C��:o��1����-�����[ZJh�­�Į����mq9���:#5x�t 7��6Xߧ�Th��9,4�F�5��o}��������V���%D%~B= ���L�]K��b�8�@��LSzte���s7,�����Ic`�k�G��w7�rA-��kJSU�L��5N>G�ꏟF����֎b0���+wk5�_j�$�K��K�_^|%uw��Ҡ!є��q
�im�`z�m���B��6c3`yz}��T:��]]�]q��B���3�/*�
/s�:��V\�9�m����s���d�@@�N�t�d���i�B'�?�&I?Q�����.S�e2��Z�|8T]���M�wJP���W��Ɇ4�xc�)��@���'�S�F����7�����{QX���i��D�$5f��T�����q�W3~�&]� ���5�M���Jf�`ӣ--���J�<�o,��"�1Yc��+\ެ���5��4K-����M�VP����d����F�#n�<~�I *�oE�l�R4�n!NَJt9���L˦�ٜ���V#K\��Del�0Djy���%��\�D�2VϊC7U���J�|Uv���:q�}�R�ݞ�}��6��en[���z���9;AW�ޝZ���ri�K [�
��iV�RD.v���5�,�6"?P4."BOp��D�����*,�	���(�E(�[����)z�?=$t�P*H��ID���Ȝ����ǳ�@7��Q`�����a�w��������U.?�vA��>�9�'�w�\Ǳ!�KD)��H���q�ܪ�������"�$j�,�ɶ87h�4<��hb���%�פ�eD�ۅ7�ǎ�SN #P��s��P�BZ�h1Jl,ƍZZ�a"������
X�1��-&����:b&��~��d���&=���}� &�"�HkٿzqL��ѭ���s˸z��l���p��wNnvj6�������*cG����n��7dM�a�����Zར[�t��q���T?D��v�-��zz�EU�a$C��I4J�L@8\�	�;������� �ÿnd�ZS�4�p�Z�������� $�]?�͓�%�!t_�v���/F���#W��4!�"��4����Q�p�b���ʗ�l�3u}�ۺS�<lL�Yo�
oU��'15�l�d��v���Rג��i���
E}�5(����0���p�`�K8R�Y���C'�~!~i	��u�Ys`����.x�'b�~+-2�sRR��������}�6=�'>�%��GVJ�T��w�gE�����u�0-�:��=ff�.P�N2of7�W����/��6Tw�$�w'j�6��7@���*OSu_b��L)g�vi��y @�+ަg�_�%A���ji6C�W�N�{|���=-��5������km> ��"�L����K;�n�pM��
����@�����~b��N�I�%�\~�g�y���P��ύiU[���	t��,f":JC%�&��D�> xg��$w=rˇ���D%!�m��N��t�^�s��o����/Q����c�y[�}�q�Gˀ
y�����ˈl���[���q?0q�L9�,p�J��3�;���t����x5�Bp]\���	s��K���hO��J�rL:L�����{d|�QMc�'��Vn�*?ˠN�!��!�H��SץSo�` &�0,��e�����Z���P�i�m>�f��V7@g�~���&� �����85У���Ms�ܸ���̵��:vc͑>��J=p�h�0�.�5�b���Y(b� ��s��(�5*��]�0������dFW|� C�e�{'-
���e��!c��V.�@Q���B[�䉖����4�1�|�m�Owd7�ѡ��7���� -�V�T�,�3�g��}uXx�c!�5-��y궏��/���z2��USm��r�-�|���:�?��>�
ݣ3;[>"�/���W�G�rP�OS�xeϻAu6f+�r6����"��UI/�6B�e2�TU�]B��'����d)Ad��y��Q�=ghO�`TٯIv�kA�I�k�0H^���[e_j��V�0.*��גl�)����/�=i�e�`�ĩ0">8
���d���bya�ϲ9� �rO��3�On�a�,!O/�?�{�J2���,?�F�&I�.�[9f2���]"�Ě��K�+*1lR��L>.� �p֓U��QT*��"T��j#ap,�Ce�����l������ݴ`ҍNN���P4�Q^֑��}�m�ɱc�B�^�P��fFs�E��%&�I.�!��tǖɐN�pN�"�����~{�V��
����������Q��,�iG���Z�W%��C�~F1;��~K�1�I-Oj�1D����ZVD�xv���:"=��|\cl�\g��Gl	%}�ˤ+Z_�+��̕@�'��)��%�c=�@"�����8C����5B_��8��9�_RD\�l¾0�w C��F��"JW�A��$P�`I:P̠
�q<�a�	�~��R�=Y�K���iQ3��nO����R������h\'���!<׊�׉�{�yKJ�_�+E��~�_�0���3�H��o�(�7L�ADr+���l,�q)�t�� ��-���:�ƀ9�7������P ��ƙ�V�F��u�Vt'��� �ui{i�)Oʄ`������ߨrP���+�,4]ʳ\��:�-؇FyE�x#���`��L(���N������.��si>Ƅ�g��eã��[�bɄ��m�n�b[�&i'Uϛ�Bg��	���5~��� 
�@9������E?V�&=R��?N�[���pYd�Mw�e��>]�g\{ �C��X1Q�u�H���~I�v�?(i ����,�{�M)�NeH[G��D�3����
2�#�֥��K�!���Q��Vq�I��_n���lZ �)���{�&b����)�����|0f@�!�Pr��$ �A��E�=�����4̼���T����I��.�[�䃀+�󴁴.���@�Ǳ�9Iu��7�iM#�M��f����~FK�ߏ&��<"�O<YLN˪k�7����c ���Bp�}��3z�����+�	#�B�
E�ru6?e�}��C���X:��������N�Tz��c���,*��Z�=�q��:�6�O���RG�0���}�`$�2dnvи��V�{R!�i7��s��V���U2�E�� ��$��!#({�RH�k7�/���&�Cf1z����ax�m�ѭ��lv9ݿ)I�]�=����}4dy|@"���F����(�b6ϧ+��!hC�|.K��������?�G���6!�;��  �W�⻧ �����ɱ��g�    YZ