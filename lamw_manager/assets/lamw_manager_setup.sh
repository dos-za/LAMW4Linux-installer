#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1924741344"
MD5="85faba3ae4a58f3bbccabaec1f7fea10"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20988"
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
	echo Date of packaging: Sun Feb 21 18:56:32 -03 2021
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
�7zXZ  �ִF !   �X���Q�] �}��1Dd]����P�t�D�� ��t��Ű=�r#�lhX�v�; �;V�?�Iu�?fn�����BC)���yjA�!xm�P�{��j� T�h����h�{�<XuY�E�X�� =�8����*E�}9s�6��c!6�T��Ӧ���$�vq1$���ujH�$�Ɨ�C\(1+�� �v}a�Ȼ
���H$`�98�#�H�*�|���}�e�H���E�#@a&$g�hc݂�w"���S�f(!��(n�z�9݄��KY4���_M���/Xs
ΤAc*@����mx��фЌ>sS����觕�u*ӉB�����\Vw�L�U F�;���!�������G(>������)�� �c�t��R��4�w����Z�$���/�;"�\1�6�/ē�^Q��{q2�����n�C����TǗ�/�c���_�-�����U螭��H��^7���#i������� �z�L%��C�"f�"����D�P�͉�Q�RC5����8�Ex����xC[U��rY[��5q�3����sC7[�����f"�@�To�/�XԐU�iV����t���L�Q�#�V:�wTۦ�a��Ƥ�U��[�w ��ۢ}��T���fPlǲ�wz���,A��6Q�h~���}���H��f+�:���Tw�L�|��a�_ŒpR��щ��b�zQ����=�@t\� �<���	���Q��Z*����v}4{�Ѻ��{�Rq�\Y���(i����E·A�6��%���׷� �v�g9į���;I�2����K��GF�L����=5��[J�t�Yq�Tv�K��xe܂�1q���ɝ��������T���1��'A��?/@`h��$��t����
Roh k^����'���2d4l�Wk��f��IR*g>}#,�2J}I���ydr���VSy�0Z�%G'�qI�e���� �+��1�I�͊��J]^��\�M0R�Zs������=X*���d�D�����ў�}��HZ���v�'˳ r7�SZ�9
�\��9��As	� ��i?e��a|�N��K2#����Oz8��g���Д���A:ų����p�=�(�1������Ҝmȋ�+���6aٞltՊo�R#��y�\��`#̢h��t; 6'��y3�����^꾏���45���Vm����d��vS�D��tVb���ӗ���3>�ټg
�� �-D�e1Gn�Lnr�N��5('a�����H{}�|�����hqգ�nRR����$=�������Hm!k��P�����FT��$��L��Z�>��ѯ&D

�-r�Ϳi���S�{:C%|���{@���)Z|��� ��s]��v/�M�q���I�=k�\Y�i��)eLt�gu��FA��I��؍5�V�W��^�&�m��98d�*��펍�E_�v�%X��������Ab��v!RT Xk�S�<`R��˦A1A�d��j�X ���?52l�|��,��)�qג'�{��ـA����\C����\��ԧ��oqR!�����Vm��:V+Y�i�sx/Lp�L��O��o� *V$�#9\8h��M�O#�U��u!��)�*��AJ$��sFѬa��Y]h����V@�s�2l��Śq���jG�ݣ����&�Z+�0c \^��;��Q����({{���T�h7��]��sE�Pk(<~qF��>qb�g�е��.~��@ $�iK�PX�s��=�ѽ��������mMe��=�CXƸl�"q�GRry�]�1�wД�wWy���K�B�.z�F���YԈ(�_"�ɒ׆�A]�xM�0bS��9qi�O��@8�«�����ҕ���kV*?�ȶ�g�	��bc��
u�q4�_�Z
|O\�x��gw{:��O@
��F�ZtzBLr��� z־?� �+�9��l~�ma����`&�B�
�By!��
E̸��c���8�y.�VcN?��a;�g��ѕ�P����(���xfpK������ʌ��0��M�6�f|�t� ���(��(ؤX�E��Qt����u(���Ĕ��!��Cr6���Nޱ��i�"�6b�VZ����f1X�F��J�/Â=|�}��Y�s��pԶ��>�o۔��� �`R)���}K45Yb�k�A{��=-j�;�ed��Sy����ơ!_����$��v�R;�����%��`�1Y�+��#Q�|��BLӔ�>�����{^��F[��tNp��W3�.�5ڐ�a��҈��xULR9��r2���D�a}_�fY���WZ�iT��׷w�΃WɛT(���օ*��-pj�
�w�5mQ�66����4b���3 ��0c�Z��#C����8�Y�:Q��e.��U�䟊�T��:X������@�s7ۼa}Vqp���o������y���<��G0n��o�x,�"�8�$p�P��$(&�D��ͬ�x�˥)�Hq�,Gl��%n
Ѧ�����aC��1�w�����ǭ�I�Ŭ �M���Osgl��?�����/b��j6���tGZ�����/N��g�Ŧ��W#�"��O�������;E��"���N=k�b�wT��� B��^鏩n�J�A��z�����2�2���/�`.K��
Z�W��m�!l�j����"s9�b��w{�ᤪ;��݋��K�N7�X��|�Nf�K��/�/�<{��a}si�������G�P�?'l���K𜱗���=L@�%WbU$Zm7|d���`�2ܡ'}���g�t�]���@cn0I�.%���I���26�=�'�0�_�yA�8Ǚ� K���Ǚ�<���@����� )����a���y��H'�,݁�KFW��M�@����݄�K|b}ŏT\�+�
�ө��o*� ���1�j��#D�/�@�_�Xh���Tp���}Ұ�]�I��lz�Tϴ�eq1�P�j^�0£�he��֤�8�;�X�\2�9�7T\����� ��!��'��ɰm��'Y�e�`��N����֋��������/oZt��7%
��s���%�OK��jd���F@��8r�%+�s�Vy��	��-Rs�U"���l���׌��U��V0� J��|I 	�tS�B��uc�U�s����s�3_�&��i��A!`��-���f��_~��O`B��u��A�!S��L�R���Jf� 7E�8,m?C8��KFҰ�Gr�"���&��=p�Wbm���xT�W+�s?+�lm����X	��}Ϟ�t!��Q�,w!���[U� ���ϵ�Zkݫ>���[�7����6��קW���[x�2Y�����·��<�wW��l\^���U˿��Y���j `���n�_`%��D[A��Y�Z7.+�e�L�֖t� ��G�#�BL�j�"
�&)K���oH� �M1��H�*�ԟ����%�v�C�p�	my���jvo�OZJq�~���#68»��]��eK���9���*��%BG��#aI~ҀS?���1��ϻ������N�L�4�E�F�Kl�>�>�d�>$5*�0Ȭˍa������@���3r�+�Sc���V�x��*QO\�ڬ�3ʑ��Hq*�5*�e�3 N��9ﰵ��+��U��c��Jԏ��8	bԣu�MB�hŀG�D��+�5;���~�6��B��'��ł=�f���i��ӥ�ldg!̂*��m#�CS��B���}V�a0[L�]���j\ہ|L�<W�n�{��D��V㜈�xC�i���dH�;=�D;��!�C�XrjP�P6Fo�谰b�q�?Bi� �OH�tBw}���g����̞$��fEeum�5G��S�G�-V��� Z�W�V��瞊L�u�T�F~uJÕ������$�R���4��]��/=U&(5V���=g�Z=	Vp��0�lй+�Z/�hJ` G�R�.i+�Sf���A���(D+�඲��QO�"�\
�'�(��zp?�ş�V���2�c[��B������@ђv�{�2�+��Р���Q$�C���c�$�TA�P��,���3eY�:|9Z_��T�b��}F�Gg4�z\]-�6�M`���=݆M`T�b����,�%n1�/WJFOz-��,�7����l��b���zA>;�Fi}�,!��?�H�0�=X��Q.E�«��5᳓�p��n.;�w�"�BE�7kk��㰮�*p��#BC����Yk�+'ԸsU��@U0m�v��Oie�(^����ij�R�Ehl�u[��!������w�FoT��1�@O,�mA��Y�X-%m�%)�Y%)��c��y��H�<�����N��z���| �� {x�&7Ul�>�G��o%�J<V��]r0�T�����(�ێXVi��ѻ\���k�}x���:�9*�%�뎘1Q���I�bP�K[J�Լ��C���!�7�i��M�wd����� \G�@�P��w�$�wG�c�`7��;J�(9��hQgY��P�40= �?��ϸ�D_�+�wx1�ڀ�+���h[�ĐeӉS��P��{�m�;�Z|��=[>F|�J�0ȍ+δ�\B�L8�r��/������U�ҝ�i:��@�+���/����n��!Y�A���e`�:�Z�1�Sw�AbE�����$� o�7\ O��ɼ{�s{>���k���"6,��v�	m�%���i]�^A�j��r���3e��s��n�'���J6q�?f���)d�	҉X�V|��g����쥶�%$�Ŷ22��{�X���)�ᦽ�C�".�/���{|mUº���/4�0�<ka�ӫ��Ȃ_�#��b��E��!�ⱭD��z��3��fu�W���c]H�7q~�Ɂ|�5q�L��E&�'��H�Jɀ�u�Y�Cq�{)�7�~��N�3��Nh�Y8�EO�ӛ�K��K-�Ԋ�Y��r�r��~��=� l%�N��)Ȋ녩v�XG�f�\��I�WmY0N������[c����elɏ,���_|{�υ�,b��&s8!�C��a(y�|��ʭ�U����Zl3�ܢ��E��aym�L�P�y�q����A�'HvN��pYp^�M�ѥ������u�5`ؽ'��[�ˮZ��lEy����/K�q�^��	aup8v%�9�q�k��F�&� 9[�'ކ��,��+ذ�3���)ofi����~؃!m�:=�=:I� ��/Rc������Og��������+I�w��tA�^IxBu����BpJ�Ӈ&/4�QE�'�V��������n�!�iFzϗ��n8���v�"e��+&�܃�ȁ
N6T�s92�-��g�n.���d��D�9���ݜ>b�����W߲qP�r%!�h���2i;>�_bQy����e����w)B�]���y��I�_�5��7{<,�<� n'����z�e��*�81��J�
�d��aB6���uiWL�=��	R=,%�����ZG���XӚa>�H$�������E5{���5�x��e�L����ۮ�G�+� M�}�a��g�u��^�Ǜ�h�v��������9Z�|79/9�<F
w��.D�vE裣��cv)x)ϋ{�׎��y��)�py5���&���d[�/��%g� =K�+4 4[#ݐ�/2�x�L��i�C�A���Lk�0�68,��3C	�i&v9�4Vzj�B sn�Q�Z��O_�X��i�*���3m3�d�ڗ���uP��HNe�N��[������J�|����Ϋ�{OI��]�@�抡��%�m ��M>&��D8
&��ꃞ��ɐ�GDr�VSIxm��HZ��M��u�"�f�ֵZ��ֱh|!���Xd�<c�kO���j��n�ţ<rD��o�-�JJ6#���z�XF�qۦn�]c"]�Qe�k}ŀ���a�Ϙ2�X:_i�K�2�! �91�跧�ӽ�s�K�O�Ⱦ�U�k]�8�GǛL�fp����fG q�7�Պ�9&ä,���s���,�q���CqCk�jil�ϻ����a(ҟ��+k�f6�"��p&��wu��C= �. bn�K����Jf�r5G��i݂� ,YYH�x�|}P��X�ܗa��V>9��9��R1�(ul#ll[�0c��M��,r�����]v�]%WH_�Ծ�&�u��E�������d���39N�N�wir�̓#w��zsX����jY�[3�����$/)A3���Y<�gJط|a���~f��aU� �P�q_�q
�1�a�,%s��v��FNAm?a1����Hq�,�o>����9]b�EҼ�b}Y���^��3�<bI���`��s@��jSSE����2 �R�'�r����ij�.��W�교���l�71*K��PR"���R�h'#c0�i�&D*��\�}@d�v�V���g/BI�?H��d�NPu���YOcξβ�M�!n "M�r�ǿ�$����}gpJ�_X��k~�8������ڷZ@�~q��{˸N.�2.h}YaC��D�r!UlDZ����bu��Z�'�����f�V�{	)V���wm��N#�s,rb������b����lƪ�~�ߐ�ti&-JO��A��s��4JC��+΋$/gG���=y�P��o���������II�cf��T��
.lP�,�0�6]��F��:�p^���;?��v����V��^S���)�2kX�@�8"�t���BV� c�Zp�:�{��nW����1���ϓ��]�Ɣ	�tt&�J.9�l�<���X1����XFT��g2�K�i����t;�5ۚ��y�T�[or[�NX�^ԤWv��.��5���S�ϴ�b�����~�754 σ�{ص�1� �.@ђFи�\�`f֜w������v	ѱ�5Z�B�xn<i�R��ǁ���3��&��^����m��-FW�R�M������0T�Nn�S܂\ `����c�A=)�`�����=��)�u/a$WdO���܋��t�?iH^
��V���~�ɬ�>a_��i�:��C�;��a�h3�6��{�\AE,�)I�g׋��i
z`ܙ���z�4��f1��8*4.WDb+����MU+��̌�%�Wu�5�݂$��1^{��}2Ğ_�=|;�b�΅4"�T�2T�5�W�ȸ�WHH��T7��z/`?�R�9�T5�A��D��{̣�
&@��(<�J-�0�w���Z�0�_�:�&Y�I�)�r��*�׉%䃾�,�)?�u�O^q��pE�Q����Ғ���쟖�,��=n�8�E ݟ�d��R��b!	����-� �ҍ�Xe:�P�_��#�t�1h�GT:]����4�UG�vԡ�`�8�ꦿB��Ԍüߗ��}ٮ�ƕ�&��8!��=e��hM>�XN޸:[z���=QO�ܙL���L�M���b��'�A7H����;��f�;=G`�dO��
�fqp/[��o�u�|�L[W �ɏ]T��?�Qݮ��P���kʹ_V;�ȷ��i���ѡr��3'i�PS�!jzzý�A���u��H.L�Z��_��������0s�GWa�?c��J�0-�Ě���b�]�n���c�2�+:2Z��i�,I0�:��`\�xQݳ�?���Z
G]��6J���)5r�,W�cv�Io�p�l����P��_�2SϦj:b��%�Q�65�E;�P����Z�"D�f�f����t��Y�A0+�ԇ,�q�~���'SO�ΝrkTJ�|��>Fh<��b��* :-�^L��R�u/�F�j�f�~�re�W>^�6��FC�jOџ�d'3b���_�� 4C1X	-	���d�b�R�9o3k�b���6Ylh�V��tݻ�_�ׁ�[]�c�'�J�$����g�+SO���&�t���I�L�t������+��!aď{���kS�z�x�Y�"���x�,@���mMx���s&T_�2*��6� 4TH#���U��b�>�m9GL��j�@�������<䊡��	��b&��}M�Rׯ`�3�t��D�ݓ�F�֡#4�q�/�ww9a�ܺ�.V4˂t\�ofg-Q��כ�IN/�*�*vӔ�ܼY����C%��"ƺ���R�d����R<ta	.�R���&������1��x�Xz�+gVA�T!P�UϿt���v�C�w#�)�Ȅ���B��s��af���6�'W|��CfKa�>���N%�	N��s���f�<�ߤ���s�T�&$*����:��c�����BjH#Hw�M��X�K���×CY^�#s:L�	%�
��C���H��/9JU�����b�~�������Bޕ^��J��.��hL��Ѽ���dZ;�V��X�KL�
�(�-�\U�w�hY��	�j1��v�봦���hy���U��l���ʵ��c��.�Z~;����<����|���m�&��9)���Tݔf�`
@�ǱNu�H���Ep��no��g-�w�%�����!*ప-��ޛ�qI�!�o�~		��M3T���T1���;&ۃ�M�g�3/%Cz�Q����<�xțm����|�ܱKw���X� �B����~�+�N�.�_��8yz&g���&���tRȅ�d�ɹcb��D#��P�B��g�&W��}Zښ�yL�x�0	ٽ���A-8����KO��p��l�$�?1��??�j�:�hĊ���`�^�'��ml���Yt������%a/a�fV��g����$�&j��ڏ��q��Ϟ��R�����*�d�����ƛ^8�����H���A����u'G�xb�Q���C���jy]{Yb'lG�t�4�k�\��o�Dks_���Y$Co�?ol��x�P��JE��� ��s���z�¿���3���d��������̽���8yn���mfH��)d���L�-[s_Q�w�]��O:���ҩt���n���i�4�89-��i��:�(,�M>�S�B�C�狞�v��$I�I5�^A��X��w�ҚO����L���,.\L���AAK׃g*f�;��W��*b~�H��߮d��Yµ��M:��M�^6����U�4�s*p�~�In���e�'0�+c�>�O�q�H6��P�[�s��WϪ���|m;���h�^INq��٤�`� e�t7 ��,S�NY��g�Oz[^}p��nF�>�cK �W��s@-h��+�S����2�n)��	Q�C�! ��H�4�ٷ�A�aDᏺcһ�=��PC�P ZQS�A��es� ʉ�S���4^H*��-5���3ˏZY�����'fo��/T)�7L,�����BMz���,q�fW����b"2�D*|`%�{���0�8�8���q��p��L�bx�#���+���9Qi?��Hǯs!F��"h��H�m�:�>[�bߪd~8����]�y��4��z'�����������7
<.k���Op���mi&�j>w��5��gCB��'��,I����g����ԅ��6���z�%og���Ss�8	Vݫ�J���p.�O6%#*:K��a��"��1�xmrr� e�%T��=�	�����x����R�T��g�^�Q+����j���=z��+�� ���
hW9�e2ʆ@��OQL�$�1���5�r:EX~_��./��]8;�a=_�-Neq�A[5�3����)a��-����s8�(�F}��S�n��AEϵ�/c<N�G9�9@�L��v�6���P���V�,�B�V0J��
Y;���0IA����FoX���T��ˠ���r��n@߄Բ���`��¶�Z�j�����J솶�A��hB)����8ce>|�0um�3��6�>��2P�%�}R,�C�`
d,�f�7d���� �)Ȅ�_2�&���U�4]�of�4�4і֭���/�����r]��{o븞��X���:��܃�x�@�ֈ\e�����)bJ��0����q��:����g�N����%H��-coL3j�%�<�4w���p���]�p�GD���p'R���h�z�|,s����E�3����*-��[#�L<��+�/�pd��x	�j��ҹ�Q�����bL���q�#���ǹ��½�yC�-��-�\�ciaA4�:v��)p'�����r�]t\V[0e)���m����Hyڣ�wj�>IUŨD��kg'�����.��B����1eY�x�j�����&N�=��{b�B�h�����7t�W��S	�q�R��y��t�>Iu��q�Ok&iߖ�N�sř�ƪR��D���Υ��Wo[�$&�P�$���d_�ʞ�ĬܥB�A/�
�Sǫ�;V��������C��(G����dϲD��<�9��⠫��Sa�S���U�R�}����q^�)3;5�gvm�+��5�ɧ_�Ɯ_�����H�^���q�ݬ�r�l��ZS��TbԨl���īh/�ӝ������vt
1��[��Lަ`��������s�3|w��cH������MԦ,]L���3������k�~���/�oq�KسX��HByGŰ��)��=�	����w_ �DR��/*�T�CSiA�a���:@�6�=D��ȮuA|�+���K¾_R�:��c���vuZn���k2*k'}c��V��u.+KU}M��p�ǖ��˗h�ȅ�N���$z�W��-�Ė��&#�JA�}�D>Yb&������K��`�:>�Xc�m��mp��">y���O�ro�u]Yw�)�q��v����	�&��BI���%�YT\��u\\",#S�$�UK�r��y\E�����Fb�j<�lB����V��6g��dh�N�k9#J�3?�c�0e/���0�(^D�RrԢ����N����(I��h0C��)�׀f��$f�e��U�a�����k璌|G���-��*۝ʄ�R�G1;����8���+Ezӯ�;�B��d����+%����ċ[�5.��j�8'W̠�3�����d��з2D!���>�wl!S�d_z�ԭ�]�d�ד��.�`e8�0�q5��wٰ�_���m�bx�]�wD�,�a�|h���*�+��������ư�L4�^�ɪ�G�^3��R��	 ��2�\}�?����h������Q���C;��':�f��bs��?�h�I��C��Ԩ*��s��	��K����b����6T���?�߃o��,��^u���r���%*3�!W�����F8��.9Gl��2����惀��١�0|��q:�&A����	}��e_Yen$��#~�8	Z+	q��Ȉ}~C-Y��f6���z��/��������ӱ��z��aX��?p��O��q���e��@.e����MD)���oj�+�:���p�3�J$׍K�xMש�LK?�R�b�	�%b�J�\m����k�JLUK�42�<��9�vҴc.�� Y���T�ܲ��Q��8�,�e�ܕ#�����K�U]}�Yu6DN���#���M�{�����B[K��0�2W�/o}�,����l�e��E�����o�J�cj��
��.��o͚N��i<�,:օ�ő������lG� ���yr���/nIS�&�M6o�{_��)Bƈ�q2����I. 8,��p#dL�j�
YD��~��'��F�F\�jM��5ը�[����;h�hM*�!�R��ǪmO�9,q�L���rwNR�h�l ��˲�D���>
�Qם�!��1�Q.1��$������[���a4�]|���M�M�*�`#h^��q��/&�dA�Eq; v��n�ț%�O�Q�&{;��qF�jk�q�h��5��t��Z���s��Jai#���*�u��5U��f��_qHX��?�������租��m�Lި~���Ҿ��/n~�eQ�6K�#)��X��._*�P��?�ʪ2�S��p!~�Z'[�D���A��k�lɕ���9�6�\pr�[�V�_�阌gZ!�af应̈́�d܈�'F��{M�0K�6��niOM�{<�P�}[�(���Mv*`KfZ.F7z:��tP���s������q1?V���A�H�."`D��<qR�@����³��+�e��������<i��Ʒ�۵�!������)����=�)j�	���u�T���P���R�����<��;��Q��c�P��/o�`�;�D�h��-�wkCAW'��As��f�X}��Y?�:�I}^0��T޲а�*'F�p���2��͂�i��h}S0+�Dհ��
�]S�J�G�D�(E�5��l�>�^�mj�޺�܋�����d��J��~�F����i��(�����>����r�rʡR\��BOg�i����������z�|�A���3�fR0���׫n�%�u���o�N�@P���n��SJ�5�~�_��?����.��M����-&�'v%�x�^F���,>�H~��l�"�鬣���Ž�l����X^D�祼���Cܟ�9�AA�?;�����N	ͦ�t谡+�v7�6�=� |��8��s���������(3�P�*�e��כW��)�Z�Q}�(�qo��Hxإpj��v��N���� �&�2Rs�u��@������si|?`t`t@��%�N
/zc<���������ˁ�&��= ����s��7�,�Bt�;���R�@�|>)�\�(�� ������4��S� �ncݾ6�.�V|�?�����?�"��[�6�=��_H��8��9�:��WO��Q&$:�9��[�|R�G��W5���!�B���U�듎sQNt'�u�W��Vc��
L����K�'g�f�����HIT�ӧ�����/��f�~�$I.�iWbX��b�D�����7P�;^�Wq 	�"I\Cu��G��k�D��&۷����3��`r�>&�xo�/�����岻LQ�U}��m�fv�}��*�{=7�g���08!UrM9�陸|�`�����s�����
��!�0٨�k�Ǒ)V��b��R�b�?*�[� yf����
݅%[.�#G(e�m�p���쇢%���.�!Q�_ro���H%͋!v��,j��_5 p��r�`�J����h�����<[����q�Зe����5$�IR5���T��M����9wv���^27��Yu����N�m���Å`q+��Q9�����H@�g�1A�52��3��>ܫ�Y)r8����Zo�P1SH6$�Dᯎ���t�g[��*���@sa�xZψ"Q��"��旲��z�u����CQ!n�������A�F:cN:� ajBJNg�/����=��23����qT4�5l���"ۭ�ZVcL/J[(�i5�v��~�z(���#����Y�>��^�g�f-"�%;Q�x�cQ������K6����z��wA@»V4�H�-�����}䏴+�R�Jh��+JO�;�*�/��87/"\D9��'���DN���^�z�/���g���&��$^�]{[^��F-h�k��Cp�����Y�=�J6��uT����vQ;Z$wuj���Z�Ng7�QQ�Ws5j��"��?5�`�N�ET��kЇ�M�W\�G�x;p:c� �9��~{�'E�T)�е����	�k1�m��K䆥�9��S:�ó�E��)	���o����f�I�%=ي*�]D����QJ���K0>*�鏱���ņ�/���{RM��L%����y�/vg�j=1�Fg�O�@q�2�J��f�#�2�6��G����{�[W 4��W<|(�,��5���]�d��ޱֺ����CD�ې	3dw�����)�o�.�4H�,�]��vc|3�k~c�M������/���fC�f���j{1�� ���`����D����%$��ȇ�^Fu�V ��<
�t^��ex�g��x�����)`�R-��H��f͊g���3�o��סF�[d9L���q��Τ)~�][��A�&"W���0�
�R�<�6ˆݛ�~� �t��!�R��T �h"�y*���]f�>���i� D{��&?������CU��bc�,ɡme n��cyꞾI����m��wɜ�x�6���0�6�y&�|�N�{�~�<d<���LKN�H��v�ȩl�`l1�jM����ߝ�@N,�a�qy�J72و�0�E���\��P�i�~�{����ݧ�]a����導�P0XS�K�]�I\+.�_<5�߳�5����$j�@��v2��o��K�1���3_�(���	�B���������Y�Ҹ�u�-�<Zû��~>�{f�(�D X�?9D2R�:�&T����d��U���eUu�z�����G#ŢK��@]3w��k%o}T� ���'T�T��]&�0RL��C��)p�"�O�S��5Lu3���:��~;1w3��-��	�T!���N^�Ƥ���/��]����&��.P>����tƅP�r~�PS�6\��X7%�
��_�I�uw�.�tl�3�( J�f8br>Rr㏜����*zQY�f�57����x�)�jz��3�{(�$B�c笔XV&5!��K2=y(�άa�_�3X*�n�vp�ᓠ�o��;5ﺛ���t�	���}�s)��P"m�iH��S��.�{����cB��b���FE�!��@�f6<�ѭU�F�f����6�Ď�rۼ^7��h7�ܬ���f ���֑p����s8�{E��!�`��Z�h���8H�ЮI������o���U��<��8p��m���QG<��jc�%�(��<��UrC��Z�d��R��OU]�\�(�3өf�}�^=�����AA]b��S�~�8i���)���)š��p*ԶU�/�}_�韴3vo�=;�u�S�Ͽ��Y�E~���]IAZ|�T"�l�w-��7Z�h��	o�E{Yo�fi7vK��M*=�������?H[��"����3�25M[,ƕ���Gg�Y��-u���f=�-�N�P�V��}���=�� �u/�[x����ǟ��Y$4L밺d���F�WH�ӢBR^E�?�I~��_�+��{,DI�O�c�xVK̀�S�9���N��~�qz5��L�u�P����i-rj����F��I�)�O3�� q-Ag�67�,-�t$��L���~��:�����cr�j_��*T�y����woI�J�ZB*����{���W!Z�|�_���V�
�Ҥ/�]"����&M�N�/�l'\�Ʉ�Rph�3��\�\�L�߀0�l�S��{s�o�T�r�z��:v��t��U�|N�{a����J��KN<��I������@JR��ZW�F���׵ Jw�ߺNЪe���X��ߓ�`P_�r���l�&u��5�&�%��j5�ɸD��yG��|ߓ�����4m����z�%]�}M=��=��=��Sx��D�SGt��jӞ|o��	�w:)�`�P�W�?m��ˡ�O���)]xڹWЃ����D#5uފ'�3��e�d��{�/�������.0r.��هx�F�>l%:t�'Rg\�,Hz頙�H���8��v$A���2�*�o���Z�DzP똒Q�H�Y�/���"��2�;}m�t� v!��Z�)��!�*�\9(���HXA���t�*FA�������+]F��$��z�t+������� }�-�T"ﭪ�R/�2�����������Jk%�V#����0�����`�A��O�z>�0"=/�~��#@�[����O��Y���?_<p���-�D�z�7���ڬ��F���:h�<�y#$!~Ka�p�
���\��
����e�~e�/��kvY���>��C�P�O�ǹ�i������q.��e��cQօ����A�/���!�%#B��%hs>�����F�T�$�O��=nқ|g�A�۫@=�ܝ�@��VlQm9]ϟ��{��3�p���[
���l�@����&�r�N��eL��:��q|��]M�W���ףsMK>�@6�x���T�`�F�h3���7Ԥ�*o�Ds�'��3���B���d����?��a�a��R�,�!k��?�(�A/ w�v���Gf��ʣ2'�>ʸ(p �g[-<��]<ҕa����jDY������h��W���Z͈٨~�#���I"+�I�fen98U~4`y�kiߠ�S�+�۴�D|�_Ǿ<V��%w�$$p�PJ���#� @\����<��9�����'�?+G��S���וO���P���+k[�[VGju��%��V�����o�*�P��.��vA� �f@_%c�ڷ���R^h�!�u3P�m�=��B�T��يC�6�I��*"J}V��#�_}`N$n��<0��^��5���(�+����.%S%L~!0&j�'˧J��fv�8���T�Z����_��=񇺍��>�D�6���a$xɐ�Fу�o�z�$u���PV�������p�G��!�Cb�Ld���;��ţ�����6މ�����nm��{Ml��	��<*y�Q������<��R�&JTm�9GU$���+��m��?d��z䲅/�s�o�V�յ��c2��N�묰ExZ���%ņ�.�W%"�/�8�U���Iʵ��ռqK�Ƃ�o�؇�kB.�_8;~kۢ��З]�[D��	=��0>W�gB<�T0�#��Q����@�T���4�$={�_v8c�a��$���x�g��/A�N9�^��(��P�R��ΰ��XC�׃1��lC��!��H�̻]#'��d�����:��"8�0M�SW�_ܩF����a��X6|���ݮ*º�=?�F��L4Ԫ���@M�T�8Y �v�R�ɥ+�%%�7�CKCLM�o���v�K
wx53�Vΐ���P�G4'�rs��������,��]�N�!�]����6M5�� c_G��� ��w�\��+�kߛ�I��E���vO��4�=<�zս38
��غ�3��Y�e@T��ӑ	04
���q[��=Ka�Frg������38Q%�Ȱ�*���/�m��ǅ��2���"d����I���UcU\-�s����Qd!��ǣ����6*؏�g]^���X++�lu�Seۢh��ం49v� L�̅��?)E��h�Ľ��vE�����.����ٿ��y?�l>r���@0��?�ō1�C�R�̖���0�#s�P���_��������J�H�p|�?HvE.�3��c�x�Wͥ������c��;�=p���i�,����ǉ�9]+� ��s�������[%�]���yUM;[��t='L����m	ՠ�Ow�D�� �~�s����YØrqH�����uL�IhM�	1	�"�/X����b4t:��+�N����6���\75~c�۠��k=:FBK���uR���^�AI�RD��rl��jn��no#���S
ßL^�e܍�M��X~{�7Q�:sl��!����Z��^;�2��[P��M�(���a�iR�?z��!z��P���[�ӥ��f����D�a��QpB���� ^ہ�a�O�
ɠ���#E5�!�~��Ѝ������}P��=�^�{�;�G�~�St	��ЌW���_$~� K�17Z�Ó�2lހ���ckU.gp	*��a[)N���[f�|w��>h�dao��G���	́��@a����B��b%`����� �pt�Y\L��!��=k�|,�\�6�n8��z|.,�<���4�F��ԣR�x����kG�f_��d*=M59x%?�pT��c���б
�<4Ĝ~Tڥ��S�=4�r�
\���O.|��%���b�1t%}��P��Q;8 �Z�A>F%ؕ�&�_��o�h^�!��i4*���Eڅ	B���?s�	2�,$�qV/X70��+��)��SYzz���,0��.��0��x���u�6�K'��};�UxV��U��[ZM�B������0/�I�ۯ7r/]�tB1����߃��D�"!‿�\�@�F�'؍/��v��}ڣ�>�!3���
��-t�p�}֙�F	�'BB���z4#K N�;^���V��"�zha���Xc��Cv�Ud@Z��Z�
:��੻I���̉񴵁<H�����/-��)�a.�}�{K�|�X�@�ltJ�᫐Ġ��ge�]��+�6k�zslEƼ���<#������;��u� �Z��m.Ru6�S�J���y��Tp�+.;h�Ǎ.d\��>xu�kZ.S���*y��!��T8y%uXи���>AW�`6H�O�D{g+գ�(�`���:��W��F�6�>�O�%�wG��&���`��:�B� ��UU������������W*�9�}�b�)�֨����Y�d�NS�Z,���m����Io����5͗�woZ[���8	�"域�%�w�s�J�[^D��M�@�ɗ�A{�-x��җf�3L���l�W$��!DB�2X@��P,��}�3q���&8���:��>�$�$-y�W��r,Y�$L��*��r ��v���e8��pn��֨����g�!+��v�`EP�n��e-r�Τ���Fm���*Fx^�W&�d�|�̃�'F��f�C�B���HDi����=��Y����л�>w��>����^����%Yl݄�T���H���M$r�R%B���݊���KԾ{[�����5�o�=Y����Y�:�� �����U�p^ȗ�h�ध铳�b�����V̰w��!D����mK���K��jftT9g/Ɓ�}�}:�|OO���XV���!n����4���\%��+��̌������t�JH#(uTI�q5x_퓗��|�+�l!�~�dq���o�*�Md����a�L,A�^R���	Ν��`A� ?�O˿h�!�Q�`�����YN�2lU���M����1v�c�uP���OAЩLvqu}�X�O\�8Q�����Ĕ1��Oե!:\"�"�$��j+X:X�6�B.#mlɭ^�S�3���x��nf��k��ր�!'�h�'���"��%/V�� P3Hu���	�����^�\�"{8�OH�O��g������h�|D�|,	(Q#�L8s����v��y��3��j@��#3>:�֓��Q�η�XQ�h�C�B���� ��f�N�d�Ȏ��;����6����]=��
��8KM'���=��?lc��>ė�t(\�j����!w���+줹��&��c��Lvz�3�H芧���;aV��R���8;�a�/ ֤>�n%\�Cc c�6�3
�|��&ø��C��� ��DK����.'�X��ú��<�8�aeG]L��5��4���w4�����ĢK�P�=���Q>��U��������z����+�q@+*���}b��GVQ��b�EQ��ō���=��n[/����g0���u�S��k3<�_J����#s�9Xؕ���͗�o.��ܱ㤉���w�� ��P�4�d|l��<غ��	(_���P�!M���v��gG�Ӧr�֍O :�7�5��n
cޚ�2�J�����??��C�\�\mK�n,`��@�+_�:��0�@YĤ]ieQ�b~}J�k[0�0% n�f�PC>Q�W��shU�"/Lx�~�1��6rMM�Ixb7�u��0V��o&n9X���T4��&�6/���+����Rg�����0qyD����.�/�'l� �iT��D>gl>l�CQ�۽�l��>��#�'�|�:�5@�նNZ#-�č�K�H�#��hSP����R�L���Еb�J37����L�m�&�[,�jjڹ{Ϙ��e'����q͎���/�(V����A������ke�E)p{����˅�i�����XcG�}`97Q���T�,\��Q8y�X�f���88���m���:&��
��AB�|@>3~��d�0�v��1�!/㑟��Ic��N,��+.+�F����e�4��M���Q����wMD/J/n��eS�Fa�r�T[P{a]#�)���K�G�;�Q���b�,w����X�ޯK�vy���ab
��4��<B��΢0��/xJ
�s^O8�H�X�=m ���ǡ��J��q/S
S �C>+<M$;��Uwb]��#����Y��(��e�Z�K��p0�1�3"'��;K�?�a�_�n��I����a�WGyY�����
$ȍO�D�k�B�H6��ʨ'I�)��7�5l� *젱�3\��_�����7��Ñ =d�!u���c�Q��%��?�h�����5�\z�ٍ�F�c%>�#pT�{�	���T����	�5�?\��׬�͇�b�'�3͹��e.N�v��Q�F�dgTa�J�quݾø$oM���<�u�e�V�_�J�Y��ߑ:��T�x���n���%����H�qb�JޛҔ쥁;��A(+������]ߍ��.+��!<`Z���a�Ĳ��Lv"G�(�X���V[P�ճ�^�1LF�R���
;��e������:�.�$�.��i���[��8�w,��@�O��r8������t�|-���/�-�7�?.�����Ҿ��!>#RL3    O�{Duk�� ֣����㔱�g�    YZ