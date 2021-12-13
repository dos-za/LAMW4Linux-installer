#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1568673997"
MD5="bf8a7714db472dc59ce616b38d3b6ea2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25536"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 14:16:24 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���c] �}��1Dd]����P�t�D�"�cJ�G�!� n5�1���dlz�@�墚uI�殅)���� �cϗ�>K�Q-ձ�{[(�BuM���!����?�0���\�{��:��z��ŮB�WS�/2�#}Lcq��J�223MӋ���B'�#�moK=� r#!(�y=���_!���9V�r],yh+$��Í'�$#��w� �V�T��B+)p�Ehhʂ�pfE!� "��,&�?�p��:���u��@�*ۧW��)�`�[�"< �&�ѭ��FƼf>S!-r(o��#cj˖ E��MZ���R8����n@�`Ĭ��ŪcG�%TPR�R'��m�����*��{J���"}�K)�N_ܰa�iwN�1��F|�9�$���*���DӴ�ȣ��,U��;#��Z�29����}r��TL� �ɡ�}N^�y@�V��һ��ɴ��(�R[�杷n��ۆߌ	�
OG��D�l]��f�ԙ�����"���ٚݍ�V��NfrX�s���i�SހD��,i���m��v�=�Ϗf�v��_��s����7�I��%Jߞ��F�?7 	��
u�j�-��ڂ<6��Hs���C�����P*:^S��4����&gi���jCb2���{�f��Nj�}�DZ�m� u���Y�U30�e���l��p��ہ���]٬g4�>mY��N�"�0H��ZD�}�*��Eƃ��)װ��W�#�2 ��"�@�^4��������j�����Cδa�JX��z�b��ܶ�����6_"�x赳�B�l�KR��Y��q���Cߌ�!�~@� �B]�_<������E�n���m$V�y��y�J����%L8�����<-��WS��D6.SeRΔ�)�c�x0��}�w�k�l����fI��R��&<Św��?"�d���T�'�n��A�ve-�eNmh�?vM�r���{���r1�@�ߙК&x�
B���YS�n ��8�uj�f�k��]�3��䡑}� �H���FuA'Iɱ�1=��ԉrN�`�+���9�p]����N�����W��l)g��A_*�Xr������F|xc��9p�I��M*��q�n��RL'u�'�4������������c� -z
�g��Z��D9��������I��\�*�5nԵ�b�	��-@4Z�� r=�XCG4)j���M�1&����v��]M�������ä��5��&ʄ�=>!�lK
Y�"�Ǹ�:�g����!���/K}|����B��B�Fe_	{(Ф��@�pr�5�K�8�ѓ��� �RY��(1�+s��~
l�r2��* >ŧ�1lB�N&.h�^z��C���Wq4Z33���hH ͫ�� �x�/����f��[����1��yإ{h&��.i�6�6��p0��ɷ�mg��^�c�9;W��Yɶ�� ��U{ZI��9����R�>?�7M6����4������� �o]O�ߵ�kn]����غ�_	 ���g�����oy����>q��������
��}X�
6�/�$�^4�+� ��vL&.�vD��t���ɯ��'y�IT����=��dk�<�GI��O� �T���C�<[.yg�]���m�RB .�D�gT�?�dO���Pÿ�7�h�1X��ҍ��:�Gzs>yEY��F�y!���r F���w�$�"]|wOM��R����c6�GE�b�[��~�Q���q������I|C���̮4�����^�&�)V�󦇓���c�s㎫��>T)y�0&a1\n˽lUbH�c]�g��#@�����$�#���un��+����amX�ߗ�V�}`������<������٢Ӵ� u��Y7sy��(!F? r�P�uQ�i�aȓ�I.��
�����\�7	*>sC���x�N�����}�n��V?��h���Ry��ר�l�� �Iu��r�H�IT�v��(��#�C���9�n�
��<���2!�P�O�}5�|����f��Xm9�y�p'�&sO�{f5�Lw_=�*�8	�����}[�ӻ��hC��ވ��H5*PM�Б�̯0��i&�~��8��-"�'_/p��_�����Ja�������:�I��*��i/ݝ����T/���v��Y˟)�rT���:�����8�����`Ex՞*>�"��(�x����,`,z��V���>9�)�t �A�	W���ʴ�}Q ���	J�
��93���z(�Tvd�<��l�����S�q��KV@`��A�l�#�l6�7)���/�3C�'���%��k�I���o�{2�}�$m��:7j �S�٬�٧�B�}�Hm��7�Gu;���ߗى���>�Q�%�@wpI7}�I�q�2+C����;���TNC��]Bf���<������܋��ӗD���`�B=���'����n-���T��h�J���;�E !cz�*�Ӡ��h<�fx>�R�ּF1�����[c�����{�\Wn�)^����J�Zl�Fq/u�<�By
��� g&5�ג�^��('`���h����4 :>fjJz��L������]U��7���C� K}!��-"�]���'I���1$�ro[H�UAS7��"�c'z��N����5���=ķI7��(;�=��q*��r���R#suC�f�)����)>�5Ym�m>!��7��+N��g fQ ?N3F�sO��t!�Zɏ�%I�d�A��ߒ�|���N{Jz-.�ݥ�U0ᢾ�K�Wz}h��m[e:�����- J=�T�[��b����k(*k��[�L2'��p��תK�����1S��kWw�T�O���_�����)�5o
��Vl,���t�6��W^C�g.9���v�:�׍��<*�I\�����0����!<ٓ��LS4޼�8DA�_��c�F,����n;���q�7��l��E-�.�)2�sO�+K��N1��L�\������*��)��9��'P��x�����p"�
�@q�bf�P���ӊu��΍ʾ�Ə��)4@5�������$\_��v�zIt��}�ۏ"i�4�e3 ��,����'%�}�VD)����v!\�����jM��_M��AJ#�F�R�\��	�}}A�cF��]�]�lq�Xk~���H,r����^�4��U�*�̖jTp�׮�	�y(�T�5Wf��e�z�ε~7U�YTN�*cǀ}&+�9���B�
7����F+���Jީx�-��G�Pw+�����X`ZOL�R}Vm?ȉ\WB��t&�ܶ"E$6�e��A�� K��+�L�>�Z�]�^��)I�@�_f����[���F�
qۭ�	!�}��L1�!�/X���^��q����#�q��mS��]�� ��|%]�s?wo�ʜB�3뙉/KV�|`��ot��.@'b0�=}��C ��0/߈ln�+&#N�-a* �3<��2PIQ�����U�x�X:�c����r�ZU�tw���}���D��8�D��2�C�<{�G-PSh4���15�0b�xm:	�>��"k�Xvi+��y�҄�kN
Tր��[O�� 2�-�ٺ.� �O�i�@��E*)���L�c�5(;�.�1�h)情Iyv���_�;ʫӨr��-Tů{T�_��]�e�~�$G
��B���2^��!Vw����G2� �;]4{���N��Xzv�bƳǆ� ����g�
��Ұw<c�Om��B�}!z��X��f%��\ax{^����ƞ�Q�Jr����B2���E�"W	���W]kv��a��{��6/�pQX�|cax]�XA~�b�/�%����@K��j�?y��Ċ?�m�h�H[;u��A�x�ދp O��ZK�;]�,8���&hAtgP��O�*���P�
�����p�V��^_��4�1@C��n��VW4{N�e0T��q�Vc�L�tY���Q��L4ϗ�q�cD#CqZh,�M=	��ɬFq!��$�b���!�x�<�����Pў��B~C��O4�c��x��E���\V�h�W��u�(�d�e+�iR����;k�kh*w1	a0�Z�ͨ���v��{��o�6G��h~����M�u�U��'��`��&�K�Y-KD�T��T^�&�/{D�\\��)*�wLk	���"ő���|!�a0��{��T�U8Q`�%�3�Ճ�-�Q1���[9b�xf|���kh.����2!s�p�1k�z��� �'�&l{5C�}�
���o[Ϋ�UP��&(Qn����-�< bKr��E9�oՋ��!�\c�}3��8��X֣��p����KC�	]ūc�d�9)o�z���qX���]f��3�3N[�t�����t}���f���u�:��RvS��M;;֯ ���
�=P��B���a
�o�>��C�-c�D��Gq%�qo��+�.��"g��b�s
��q�exޝ�$���N_��J�>�3�����s�5(��Y�U��[�=�v~9XS�dP��ZRȈ�>�����u��� ^�����T����`F������R�C9���<�4W;W_.P�*���������(J��v5$#��ZQ-Bލ�xDj��G�q��@'��ALy	�u�2Sֈ$y����D�l�a�����FI8�e�ٶe�_6�����2֌��,o�?��-��V�r�ND��]�d�Řs�����.�Y�<��+㆘̻7����θWe�ΝdNI[*h�]\��1CM�>�6cP��wا�
crF'�{%��t_Xy��&u6�]�޸�D&­]+HuE���~��@=~Z�8	d�}��_�IB���"#��Ј�C��EI�#1��G7`UE�T$�3�]J,V�������]^?������e�V��4̢�C���i��HC����R�)}*��D@����[��183�ʎ���è0YM1u:�(gx�$Ƀ�<ќ|?��j6>%`{.<�������f�[i�l�(<��xx���+�"�J�"]1��0�������j->�J#���%'�=�Fh��[��V�J\ʝ��MI�K�S�h9}��v�A��r~qM%_]�bwդv��`+Q����3��l:�c��P��(�,�4�q� ��q��H1�a��HB˶Y��sOz�W,�y(�I�.��-��Z#cmkU�KF2l���:ጇ
߱����Ezsn�4d�pd��)PV��ڋ�'ovqьy��t��x}MDGg�;w�Y��)i�����i���ž�9ұ�=����$�{ұ�P o"t��ϰI�u�70Y �~g�#�r�y���'�����O)qv�X ��_��}��P�R̓�rVO���`�{��ȯ�:l�tx�/GI�y���r��+NuQ	o##�T�R|�.�䈹T5`�,�����D�>�X��f�EU$mf��,��8��?E���r���>���p�;����YBZ>S` ¹E0�y]�i��gq���Z�X��GG�]�n_� Q3��M�����C��x��G22�,���|�\g�W��Z5�}�zT�Yx���=K�BO�  q���c�|7�}ƺ��C�D���[�����0S��h�Ǒ@v�R�vuB�!}93�;�7K�s���#�l�T#޲x�}$$�M������jpQ1�� ����x��Ʊ���%�d�8��@E?��`�@��9�wYI�x	��j`Ź��E5	�X��1<�d�O��Po�y8]/s��悦��XQ�� ��ԉ��c��.�9"��xrĲ����ؙ�S����q�70���wKK��܂4 ����з ��ec7HA�ua�O�Q��A8�%WI�^��'J<�J�|0�6�2��~��O&�k���@�V�0�d9_npO,$���+B��	B��;�峌�k��W�o \(I�4�.�ێ�"@w�|�0	o
�AxX�O�.�i�;A���A �$���`�ƞ�:�\C�c�V��pM���'�Z@0���1Z�6�y��ұ�H�̸!^,�
�˂Z��9E�\��I$;E)�����c����A�'��S��%l8��O��	[�\2Y��k����;���0'��]����t&��3z�+&��GB���6b��
i�*��߃IɡXp��e`�<e�'����"���6����u�:$鸺.Ep�M{�ln�ī!�Z����O��Rj��b�&{�j�5�	j�3}E瑏 
��A����^��5��;�����*���>^�7ih Y1NB3}%���tJz�POx�35H��*զׄK|�f -�KP;�bDOA�K���nh�R�o�f��0�~���
́몎�����I����󉣲����]�%VE��g���/g�M�A��}V��a)yq���B�"XǏ�S�N(K2)�P)���2��,�X��q�����FV��J�v����=����s�h��&ȇ��^5��(m�'wPnX��	Ox�	��W%j�h��R�Af$�������Ug��l��lE�F��s\�y��D�>q�׮~�CUW�Ϯ���R=�i���Ő��|��G8t$b��sd�Qv<L֚1{��l��timy�Y!��DphN�xxi��;v���H��΃�P	���Q�� �*^�)%����Z����n1�S�.��Lp2]ۃ ��
>)M�X�M(���zܣ�-sv��]�
M����
�� ��S^V�<e��<����P�z���3�_��Jf�@�ޜ��[���H��|K���/S�ON]U�b}D�w�	࿓�q\� 9%�U�@�;�
5�;�n�q��(P8]f9B6h�%V�[F>�e~�)��h�E��g�<r���7�����IZLM�_-�k��;;2��Ms?�Ƕ!r� �^�\�
4_1�nz��-��u����J��&%��;�~A+M=l@�#po��ʖC�O�ѽ�im���Y�GD��L�o����G���T��=Mxn)�v3���
��(4~�B6��T��)���#���f�f�5C	�a	���]��h���z7�T�مw7J��oy \-���!�E#�E
6�u���B�����T1�^wm]�&������3p�Â�Wqs�3*pdR1�g�c8�䣡>nY1�>:�d� �;��V���C��3ߴ�D��Y�̘(��o��"0������<�����1����<�=���a�
?����E�6'7�}Q>�l�L����`l�P/���gd�n�Ȧ�<Ţ�t����.hЄV���]��:��㖫�k�ۇ�R�px�H���0�@�۫z�$�Q_�/e�]C�ܯ��\��'�tx<p`�}����n�
�&;�P��jځ�=p�L�~C��n]��ǺWf0�y��l��}l���2�b�+��i(�Z���3qEל�K�3��Ӕ[Xǅ@���#�3A�yB�j`*}4	�YK�4(���S^l�_"[�g�Ʒbf���Hv��k��u��E�L�:�۴��z.2�W�DF&S�K�x4��������8*s�N���^���9ji#���-9�*ͮ^�4�:Fa��.��	�0�%wwf��qc+)�_|~lJ$m�'�ꆦZ��<S�X3vڅ�%x4�l���٧؜�[(5���	��{�9(�h��'!���VNY3
vj���M=����2^e����[/�Pӿ��W�#���s+K�+>�W�|���@���~��Q����>a/犠Q2��7�+���9�5v�簕b��������Fa3�<Pl�� �w2�6����)�YeR�{#&Q{s�T�<��!�h���BEl���I�m9(�'a!�y�VA����<�1Jy�;'Ў�y�*�2����v�)v�_��G1��u����~�2������T��4��k�*WC�l K)7�S�ק��m]�+&N(c.�`/.u�5�]�-�^���$ά��QF�z�{<\� Z7�kx�_/X�)ܢZ�|O�b**m�N��Ţ��O����eGV�s��e�CZ�������g�n��@Nq슗u��a��6��򩰩�O��K��oV���%��%@;��6�l�@�������A���������ON�s��6�x�Qަ��ir���Hה�=�"��o�����I��;+��ŁߺT�mx��sR��Z@wDj�=Tw���Q�%{:G�F��2�W;2����4���v�>�O�[�?�����i�0A'PWe*��,�sץF�Ǣ��o�'a��/î��l䊑��
���ky�9���&�_�M^�9)���kٶ.d�
��$uJ@�Lh
���y��?^1./T�n�-����8���ܷ����P�!���CT߄
�	��E?K|#�@&���V�&���I�@υ%K�?n�q�p��5~��n�^W� 7AR=>%]�<֨U'1>��gJ������9�Vێ�� ���o�on���Mp(��q��
�w
��?��Gu]bS����Cz�O�}c�+��E�=���T��0QCC7�k��ܚ��HBS�E���]�����J^�����&���Y��#.��5���H�C;��Zp��#�u��2��7@�f�!���
Qc��X��`_�A]�!� �����?�T��¿_c���3&���%���/���s� ]�ǹB1q��هN^١���	&��L���A1�V�~7��>9w��OdW-�$�ţ��D��J�+bF^5���V��~��zN� �7�O�%�fm���z���8ƞ4�"�=HP�ʻ,��,�ЬJ��8[b��y���H�cC����́.��Y+Y�R�č�*�}�2��-���^�?נ����)~�C����3����Qf�O4p�˳09�4���H�{��ܸj�*tlQ�v������4Bf�:�"� /�0��*���דmg�_����Ocv����}b���u���(��ټZ[��!��SE���|44m��lTg�8��^c1��=/�d�����΁���!�*����S��=Ž���f�y�j�����Wa���=�H�g%���deJ8�A}��xk��.طF#'Z���Ğb���R�s4�x�aF��Y��[�X���{B��ۏd�p�&7�1�|�^�/*W>9��a��LH.NA#��t�% ���PI��q�a>p�F�Q;$b���P�PW=I�c��b[�@���?�Ցe*T���7��_�/֪VW���Q�Dy\r��b���t#�p*ѕ�cڜ�g)Ă�s����B)��:�{qK?9����$�w�`͂�4�+1�
,��4B �_6K���L��|�:���P��o�iY�U�F��5�ۦ^4k:��P�ގ`ML b��!m�.�&ZW�۱��_C��u	������	S0g��rR2(�`��=�2-&�`�V�v�G���qw��8wI���#����#Y  -�TF܌j(�1�p=�@[��%W���A���7N�u,YR��]�ZL|av����pl��v��T\F�ګ�FJ=ZUhհ�,�e��y@��8���}1���/��7�Ƿ�W)wM~y��eYL�>��Lg$X�o#�x� M��d���G��Nl�� 3��N'ND�NvD��8��e<[�x[m?(��D���5]k�D�j�yIH4�+I9o��Yf� .�'@�Q�X��֫��N�cW�U�҉/��趈�v����%A6�I*sG��u�%�3�4.i@�Y�n��d�E��$].s�˻k ���8���d� ��s\�O��K���"E��w1T�[}�!=�j�F�Չ�X{�]-��~:s}Z^����I	DÃ�ax����9SL�ɢ�Y���PL���;d���7��e�9��7���y*�޲I��ۀ���>f�p�ٰF!8:��!�\�A	x�`���zm!4��E���-8W����'Q��a����$�i��T���Vf>�z�;>h�7���_�2��^XMuv���=s���(E��r��S�2�8��)BSn�ߎ��5�&w�)��p�@���H���h����$�NK���ē/D�r#��!��؝��'��b��i��A���h|�4�.�^�%���O묯�{0������������$ۏu�	�.[0G�� X�E���0�^���T�i~�lݒ1Wa[��m86�	"LYF��1�:G�0��ۦ�{�LN��Tz X�>�H����ܐ8��.@O�5��U,l�ӎ_��u_V�����K�")�ah������U�O��7XT��E��[�LF~�W���o7GS[*on���t�E*<Շ�������m|��ԯ���#���f!�4kkg���-G̀@���fl9r����8��v�{]Fb������`
�7�d��_o`@,.t��͓�;�^�%S��F,��0��Ϟ�n�N;�
��6���O��85�' ���=�7�"7�I��Z�6�X��u�@w�+��D����>�:@@��LNQP��r�z�;���N�;j�2�X\�G�V��L��'��$4Ԍا��<QR�-�KXh�s��G����DQ��D�9TN[Ms�<����^�d�h�x�q� N��0�����E� VI�_7:Q��V�-S�+q߰�g�P�Ʋ� ��|��S2:��4�����S�9��|�w�2e��_,j��[P��܉�y���.���Uh�}����}��Z��wԷ;���ۀ�������9M������ބDA��l���=���ړ؂���ͭ�ᚱ'�� ���7�[X�}��,���2���O{�i-�D�� �'�`v�ޙz.�;[��s�#$*����� 4�\k�C8܈tɣ�ݼ���8�/d���A�@"�)��ܽ:��F��@��4��; ?.=��z_h�tg7G����` Q��u�.Y{�A�[#�n.��D����L�¬)h����p	��M��¤䊰��B�/7�����}26��H�_b�Q�	Y�7Fn%Z8�bHZ�`�7��A}��CW_)Q���+���q>_��C�İ����%�-G���E����4@v��A�,��XdO��c=Κ]��K����[ K�/�D��?<��3`
1պ!Db��1C7�����e$�ce�Gh��u�~�XdD���ڣRߝ>�q�Q�����[q�ܴ\U�/�U���)�l�SX���&����٧�Bab�C�����It��3����x뚇�ü@�u#��!�gCI�Rp�ζ�ݽH�#ݝg|~w>��6�e!Lc+�����c.�r}�vWw<,�7$V?NN��Y���xtu�.͆����?
׈	Ǹ.����Ĩ���&J��T�c_�F�If������z���.��F�( ��`��U&xZ?J�O^���,[�q\w�l#+�*�����T�{�����Yr�&�+�K`&-���4/�r@���(2�>�����p+Uv��@���q����Υ�*��p��Ct��`��R��n?���K����P��	�g��P�i�#4�����x��>@d�~�6�����.��Sql��b��1� a�:��ƭ��Z]�����ۆ2�WN�Y~_��!��V|D��]��H�r����t��ƭ+�E�IƮ�^8��X��1�Ⲡ�# �'�XQ�>#�����y*��m@�����P�-Ѽ�ɦ6h�k��B�O2\$�������><y~��[λ�w����?���6���i�d��Y��2� �@��o��u���Y�C�'7���3�[!*�+�U��ꘖ�cޗ���|YL�նNC��c����Y.����-g_+k�q5n8l�ho���Y����S���7G�c"L�z,���N'�*(Cev&�Lx� ~�)���lR(�-�=��ݴP2��O�9�Ot��5uq���P��Vs׋�{a^%��'J��N�spq�S�L�����wt�W�,�x?Oс9a\�H�_�O�AW�?�^W= �n�\I� ��dc��ڒs ��eqV��|.ă_��y��!f�A����̄M�z�r��'�/c/�p��ƛ^�;?�"��-����mK�m
wd�Y��+������"�UҨ9=��� Ԩ���w��h������x�{����Oܚ����q _�͝ӻ:{��`6"��k-ʝ��T"�I >�pf�����9��j��V�����O���0��#��tt��T�@��}�:��i���Ӗ�����"�H*�m�T@iꠓ���t�>/��۔��(�12a�����]�挧�kL����H��QDy#xQ҈T3�{ a,�<����
0^h�����G6��aiT,R��7��yF��td�_ȉO\#�5��\�t�� �� �����T�p�ˤGV��@�oJ����H�.ۢ��r�?L��?%hz�".6u�����J�c�2#��^���BP��D,�}-�*��� �@CK�2r���R?A���_�f�k͆��A����eT���0���:��4�gFfZ��c�����Q��ȍ�K:�z޵�0���ΰ�V]��:|�x�qnryڿ���~�U/1���1V�ε�|��˛I�I>��߅���U��Q�B"U�r�1]�f�G}��HzL�B��=�����,�$&GJh,���y+�W�
r��lC�k��vH6�����>r@�M������l�ӏD�b�ś�oc=�Y|v�����O}�M���'�zs_l����������یHX��M����#�k�U��}yo�T�qX@����Nx�gEֱ�66pK�&�@(&�[��(�������4�Sp��ʹ�X@(�R�kDzztQ
��|��v����8-
�c�:)�ADS��|%�[����k�8�q�#o�j�/���S��&������WiI����|��ͧ���`��5K��I�x���I�O���>��u\6�64^��Fj���/墴��L�\/��t5��fJ$�2�V=ýH��������V�a�w�m}��Y~�����h�@�Iؿ@`�v��k�!P���&P��w�!���owP�m[���}��$ߛ�5�%>���S��Kk&���
��hS8�S��6A���8�����	( �cO5�4/�Y2�|��9�g^�:q�_��I�=�̬���L�����I��\!�������ߙ���R���=�|y�	�!%A��7���RK�t\�7������:�=�F|� �,�D�`H]%����]�"��97��N�UnB3�����U죱e�hZ '+�m׏�&!�Gݍg4$�vm=CW�e�g���Soy�2��+�e��q� cLǤ	Zy��s���f����\��������'�ZNm��h���/&��\W��
3���c�<1ӿ��Ĉ	�Gd�۫�c��a�%XF�Y���mc1��
�+���% �܎������[=�_�����V����|㵤��h��R�4��m�1��r�8ud"���g�h"������o��iF���!Ӗ⥓!	U�ݒ)ꚣl�ɞX��~}�A��/�3����E���;��R�
C����Vc��l��'j� :���05�Iˍ�Ͱx��(U=ƛQ��e��em�@|�G�;�F:-�@MB�5��KI�:��,?/��e&*�U�IC+�Y}Pz�r/f����`t�3��`K�d&Q��J�T�\*�����PIxA/�H��Y�4���	G���{�NR*g�mMю��of�V�*a�Ur�*�'L�l _��hI�_���Y^t1�8Q;g�hU۱�H�.�V�����n��(�O�׆�)��47��(p#��߻~y
)�n S������K�(���h��+��e�s"����~�m)��� �J|��*ЩGүv;�g	A;��	=0�r��E��AV; ��'�4��l�B�'���bHڍ���9���qc�
��w8����I�(�yz�*M S%�L�H�/�m	����0B`�+,�4�<V��/��)�[����ץM����&��* #S��S���%�LN���Z�[����E�\��H��I����T�3��2�낾����fA�Xc�)�	�j�d�:$t�M�,7�{o��"c�m�6�ug��)�=un�I�4������,~�tÈ���;��ܩ��r�ڞ6�x��5��A���Pd�c�7�M+�v`l�A���<�0�xa��l0��DZ}"�k��qV�M�~���۾s��T�_�~2�
��a�B�Fu(U ��<n���ɯrŶy����~���)y8��\�i��B�®���g7��9��L_���t�}L������K�W�	C��sV�5^75�6��H�� ���?e�B� �Ϳ���ߢ��H��C{�M�;DE~32]�<����MSNkذ���~���C�*���>0�ș+�(��� �����>���$%��-��w�Evr�=��FZp��-e�<W`�-��C�Ě����Ѐc���0D:8*�Ƙ�J���l��i�����2�-�l����욅5a��07�����:=]�D�?&��/BP�B�@/X��cG��	_�Ҙz�� ]�ޮ��(8�8�<��L>mO���[g�o�s�4g���gp��w�i��D��i�,�Cb�$-�z!sL�*5����]�^��r2�3Da�/g�`�jPP�|*��M��G'Ŷ�����Щ5�Hѱ�W1�[b�w�Y�^�b�7�S�`��x@��*�FYt�ifg�Z����
@�h��F�Bl�T�Ŕ<��][��"T/.HFZD�MξAc&�P�:�sW����>y��{
����1|��D��HU���`��W���RZ�ȗ�ot��Jc�'x�X��6���Fr���+���2�犈m�`�_ʬ�]���J jůsxegS�&��.�A�kh||Ő^�]p{nDϾ@�v�?`h�,є�T9��-Q#�/a�=��eE����7��;��?pwy0��nd>S�K1�k19�t~��|v[��L�Ğ�1�&���*	�t�nJ��򍕟��j��#��JJ"E|��Y��l�aC��v��-����;?-��(���C���xA8`�����0Q����|���sϋ����9��NL'ـ���:�1�йT6�9��s��r���m���ٴ� ��+�cH.�i�EM��y0���I�2䶨�^ʗ�����#T�<�=���5�ҕ1�*;ë&U�<c+���Կ��7�#���L(�
*Ą�]�k>����_ ���`+:H��p��zs�>�Ӫ���
,!CH�-�l��q�a��7A��OM�0uW���ᾍ��mM���!��-�ͳ�y�I�YH�頹��ߦ�K�Py�G����	��sE��Xf���~�Fv�r�;�p�н\Q��,�2&�K��u2C�	wjw��_��{�L�`���h��Cǒ��/��E��q���P���BM���{�?�F����^�n�_ͥ&u�(f�AFj�0�Ϋf�(�4���U.4�#���ez*�	��ˋ�*Ĕ[�#$����5�B.��1��|Ɠ��H�B^���-�}60�)�B����4�ʼ��Q�$�:��.�`����jr�-%��J�mֻ�pB=�|�sb��2;ۓ��~D��#m�����N�Ui�ؿ��zr����ٗ�ɿ�vB+�eR��� mQ������M��ɑ������]�~�7||�͏BL)��(H�Ͷ��}�VER૰{�do�"/\�9�㈾4�p����z؄ ���
{�:�C�:	��P���:r~S�Z������.؞=ե�|����

�)�\�s�� ������#��W3~�L|yS�e�X����b=Vµ�ԫ�ir����-9x�Ei�/����3�a^��Fn�����4�c:&1�b��gI�ϒ-�th\��ڙTA�s��tXzر] ��9oS:����(��nFL&�mh��q��H	޳��(�|T9������@��-~�r�!�#��ǈ�~��)Nk�޻\��pKs�Ȳ�P/]�믻 ��eݑH\6��ؼal;�:��.��R����3�W��*��|Z]d�@��V���v�g|5��D���]Hd�^��6JNK�CbRo�[�p�����i̕�s��x�I�R�A�����=J�=�.��ު���a�X���yU��9^C��lM�����1�*?���bC��NS�U"Ϥ��}�Ѽ��ŷ�F+l'Ӵ����s�o�{p�z���>Wf�{�%~�TL�F5���W��%ƈ'�Sƭgm��`��<3q�ւ�����S�w���*!�1�蘯G�c�(�J]���fl$��Zq4<y��i1�!A����3b�M�Z�JQ\�obw�3Q��}PnA6�V���ȍ:�X�ϔ ��WYC%W��J�3�2��t�7$�	��R\fq�psz{��H�E#�/iˌ����g�bN�m�Xs7��z���KiEL��?����5���}�ݥ4�FVkS�_�/�-���A�5JU��O/��������6���+0�ʨ@m9]���[�tn_O���$K��o��e�F�T��5ω����D�?\�yސ�GEʄ���:��7t�t���ӝ����hT�\5fۿz�OaqC�����>>L[[�@����At���&��-,95`�#y��\�ZF`��P	­� ��VHҊPX��Gh"�{����6"h������m�N��/X1�<������Y[S�Vψ����BO���=cs����������+f)�MM�n|b�X鰭��$�9��J�eŻ1�����K0�p�\��ghD���Tn�e�;v��"�ǳu<�p�5Ҝ�Xqv~�g�M�����@�AOB��T��VNl�����S��W��q���;�&
��g�y�:Љj��k�{;��O���B�q������&9�|	O]>�cb&{~��x��$�J��5�Ŭq����m6@��ח���T��^g���*D���b�.�aX]�u�>���T]�r�kk�%�-_��F�R��%��	D �G2&:]��򗧼��@��3�I�����LT���)�V �F��w���߹3��@�)#�G�� >�Ç�C�q�UzK���z�@��u=SV�m$0Z4/��|�����W��ВH�F��+Q/��4�������T�1�7F@6j�l�+�ى���8]�������K�ud���?X�ϥ1�^���\ەn��[��&�G1V����[��0l����t�*�U�iL2��h�;vy�b���C)����դ��?(`鮕���1�`��l86���9U{s�0֧x[Fl�+�H.��<���a���?�noy�ƌ � ��=���6
�H�mra�:�ذfi���^���[���,Ӧ��-������X�Ln} �6��\}~i������w~�L�ʸ���F��Z��C�^��H#�Q`b��ӵ��cK�('OK���o�H!�2�n�@N����aIt�T�2��@��+��Q��]б8#Rg��c���:$!�*�ql�9ߦ��s�D^��h�s�s�/��ɸ�2��#�ē��͏H����f���C�(`�I`��8=�D�Ka~sBw�=����c`�v`q���D�>M�}�vyM�-Yn��~I{Ȩ�4Do����$*���/�1��Cs���[��?�/�n˙'}��f!CP(i��'�%ŒϢ�]���	S�s*r�mD�v����".S�Rb�!җ\$K�<��^�oS�M�� �u뤘?�8A1���[s�E�N��^�FEY�btRX��.���$�6A��%x�#��X��F�E°�P�;�"��3&��F�aﻐ�y+��:Rgi�/�!�M�d34�r��l~[��ڛ��ru߻:j��l��_N�g��@#��n8
\nLs7C ԏ`t���K��^ru?�Ł �J�
܆�g�pX�:���4 �AFd���(�qo3yLi??k�aJʦy�HaD[����;��;����]�"@CN��LdL�j�UtQ �Ӄ$��~Ƨ�w����
O;�02=TV{k�C�L�g|����������e1�C��	��>A�G��fvP�C8���kH��T��B$�_��C���Cʍ�JU3�C�%]�E��@s>�J,�T#Y<��b�OE��ؽ�ȝ���p�P}���q��r��mg�ID�t!~.S�~
�O-���
�ܵ�c��nb�a @׿�����v�PO�ެ �F	�E"��W�G�[��+,�a����� ��G�P�#s�<[�h�� ���3���r�iD�j�dq/l
n�g���	��b���1�)އ��f5�)�|�~�u�]J6�44|-L�M��ۥ�;���9i��fAnȥ��^_��얤7Z�4?���x�	�t�=N�� �v����f@0�]k���$�������E��l��H�)��1�skYk�� ��?��o���:��vk&N%�ԫ���U���V�7Hj2b��P���	��$�@�SN��'m�z�C�v�|��&E+��(��kPK�K����ȗ��u�Z��(:y�3���M5�;������]��@ �AO�_�� 啤X�[���A��eܩX[��}�����i��$��=�d7�l��m�}Vpw����9#�9UKL�>��;*xl����}r�U�hAf�����1V�
�qfK��w�"����JͿ�Z�dh���.�d�I���@&]MF��[M��5x����naԕB����T(Is=@>�����j �u��a��úK���7ʀ�ɚ���������q�0�>D��"3k� ��]�v�#韓o}�a���]^� ���\o;�C�G}E����<��碉�\ùj���!��$-�qJM�B\8z6�-��Ƴ�>��1���a�-<w�J}�1r�,	`a��
E��V��Wx�}�ʖ�aȨXo�hX7�Y�5BJRv�<c��	f�M��G�����y�#55c�o]F�z�3 �Y�x)&
[�rᆍ�s�*?i/��� �6;n���0}�<UA�?*�����,#�*T���Pt�{�^�yGh��3���	��Ac�^��]R1X��VK��P9��ڿ#�:��}l�����;א�ˢ�}��6W��c�o�k��D�#\�!ڊ;��Q��Jv6��1W�n��e��K�m
喯_[���B����38k�b�_���d���\��w��,���L���
�iφI8�7'a�GH/��E��ı&������x��du1:��+U�4���r�"q׍���ɻ)�5���>�Ii��Kb��)��ű :��+rF_��D�Ҕ�� �����%��M2�,DI��@�8���]�J����7�����ڵ>�t�l��EI�h|�}r�J���M���|q^�Ϙ�Wd��r�TyX��ꭴ���j`�8����1����0���wH8I�ߒ0�i4�e���e��Z���܆gA�����0��Pk�:��@ֈ	�.Ci.|g�������=j�
Ʊ�6=���a^�u�$�&c#3�����CQ�ж��J�(�"@#�����R�U2��eP0k�j��m�'�����l���&��^�S�HC^!^\�����_��)�sy�QU�1R�����������#�v3V��N�*u7�$'o)��¼�����&K&,~z��).�6�?�ov6�����߀pƦ|p�l�O�F��� �/r��P�k�ݸF�c�K��:F!�D�@|�Hc����' ;?���p�Y%n��:)׵����#�8�\���ծ%L�
���*�x�i3���~ХM����B����f�`��-�9�Yϻ@#���.B�����+���p��?������_�.���%��K܀�����)T���������"�g__k|���� ���l)�ڢT��2�U�[��ؕ\�Z*W���K��󀹤Vf��Tc3Uٸ[Yk�ݬq|ӈrN�\�M21���7�W0� P�d7�(�=�-�$��� ��"�m�X��ֵ���W$��<�~���P��}�I�GP�l��}�����,�À��⬨��I�_ ��*��Z�A�r�U:<����p�B,2sk�����Np��\П%�����7�r��I�Ր�L�.�� 1e�p����}J6�&�k��.��6m��Ũ��m9��^����eǀ͙��	�jkzL�a?xΎ��2%��x6s((���^>{���SB9#�9�<Q�oԿ� ���&9Kt>?�B˾��z�q��1cˏ��T=o\����vs-2o��J����*����3������ɮR��lܨ&�ף%Ҩ��ā�;��'��R�(�#.��@�Q�e(�gg��4oV���Za�s�}j�Y�(|4X�x��^�<y�l�ɺ&��	So��Ҍ9L|n���d�:���7|A�$�i9p(���
��ѧʒ}Z���xQ�W���[�UL*�q�iB�^�hA۝#Gnj+������.vS��4��]�d���̨�U(�"|���l�-dw���b���'G�* �N�N�~|���"HO�*�,�=}Ba���f��`��p�/ 	V�]�H(��8��	�E�����6�(���qQ�E��=�%Lr���#�G(��#���ȀB������n*Z'�|^V���(}�J�r;G��5�xL!U�`n/� U��ܽ$�mu������ήݦ����|oz�u��YL��x`��Z�Ƙr:/B|�UIh|�Q�dD�������)A8X�S gQ�����ᓮ��̏��F�Y����M#,&��x��37t"���l;��t��%p���\&x�.�7�5$�pl{m��j���ӱ���/%�\-^���������i�m7vz�W�ђϕ����%z��Xo��E�mp����������W�ԫat�������,|���5�w�h�̭�9)0����Jȵ���D��mx�,�f�\�l��ȔC�ၨ�	=�%�5������Ѯ/O�j��Syx+�qt��d.��q@�@Q�N�A��c�ըV��	�t�17�L~�:�,����۪(Z�@C���I��<y2�l�ѫ��=;I�\g����εz�anG�O�p�Ko�rˇf��M�&t`�[qf���s: a��n� |��V\p�I5����/5~&~�?�Ι�cb��4��篚D���S���p�Ƅ�S��,�HFx)�Vqs�F{��BDa��eD�{��q��\r�<e{��~��6�*������ɐ�)}`�qq�W�9x;�����կ��x*|_��yWp��ؒӡ}" @_Z��t�R��R�F�v�Re��Z�L�Ԭn���LḐ�5�9��IPw�|Ϻ����"\N���LN�>���
�����[�b��z��f%uZv����gZ`��7�f�m	="�'��I"r(3~>�)��©9���ؑ�P�1��z�[�])��� �ӏ� ����F��<�Z���<s<=��N?u���"z�{�"�niz6��2�AU '���ip��`ha���?��A~�k��}�l�`E!�8S̍�k�(��P���Ⳉ"���֖�7!}��DA�
h¶�Dx��|�A�@*�/Tk�d��wGz�����\}���}���7�爿�7_�+��C����#mS(��T���c�SQ-WX��o3k�r���W���<vYbT���t++8���Mc95"lR�U:4T�y"�u'6��G���u��;�������c;6�ya)!g*I��tz���v����uր�_ ��u-Ð�N4r�%ê��v3�+}�J%|6�L���G%������٠��&V�=��A08� �<H��b�~x��C/ϗ�Tn�C�-k=y���#��
E<��MNb���="��_�KT�����0x�>�Kڵv{��	�޻���DhU�2��1�uZI\�6�G���q���`��n�=_<R��Y4�L�����mtea�5v{ ��V�C�ac�� ��7�R���JUqV��l��6̈́0�.^�i�f�V���>�p��sףz�v9Z����#^��g��/�Q�z��y���drVV^G*Ɍc��C}��m���HPu8�ի9 �,����F�+���Z����[����Bc��^���LÂJ�7|-bQɢȔ+��)�SB�boK����r�Vc�cGc�X���7.�C�eo(���:$�f�xk`�<k��E���S|�����p�ʑ�4�-��㜕d	;@�*?�
.|�+���j���T��U�&;�������@=�w��-�l4u�T��O8@-�r�g�Ǎ��p="9�'X"ѥ���3o���y7�-��.yj��IW��ae�,j
iR-�	%"ɸ�V[Ga�tN_/�M����q-7�ѕu�k
0a�xsK��&���	j�7��F�F�'>�̜��Y��� �A���t!!W�T�(2o59:�~��v��#�2ўw�{Zk���#����|�%rU٩+M�A���mm�����6Q�QW�������m���'�l%���'����ځ/@�D9%�O��휯����ZW:�|��J��R��2�C���� ����	85l�W/�+BS#__ױ��� sRT|n�8�j�7Y�H��d�̵o�����ƫ���cG{�ɟr:=�S�~�s�9���y*�^�h���������5ڇ �%��IPP��E���h�B���M`����y��Jn	ia����*��V�Z;H�c��0V��|���D@��\e�Mx���"���k��ѓ��������J�1ї�nH-��?g����Z`ց�m.iψG^��U�^�-v���!�t���&��n��FG����M��ѡ�5ް�pZl����b�04��fT��^Y�S*r���]��[��.���:P�y�@{{:H`�w����3��R
q�&1V�О〈���{n��7Φ���*$G�ÎG�a�[ڋ8G��,w*I	E�zU-�vN�_�S�ly����&�Յ�A�@c� �0��[o����Wg���oN���?��pH� t9���FV.�P����981�Y�|��p��iw�ހ(���m8B`�9��������XLG����#�KT�m�P.Xc�é'��D�p)D�S�c����wfQ��>q��2�
&���[�x]`â;�A�=ܺ���%q�v#*ɑKu!�����K!�I%(��1O�Na�ncOxRu���X~�d�;�Vl����,Q���j#s��ȉ���0�e�Q���^CW�{���V�{�|Fx��By!e�Z��^���o�i_�6�n	�����=Js�w(��2D����1�J|~���y8n���m�W1'������s��S�Ϲ*c\c-5���֭LU:[i��p\̸8�q��h�&��N�Csм*��~�(_���$��1]0�nV��ɞV�9Q��F9R�\��Z�ױJ�m��_L�k�@�S��,��04]��r���ܸT,^��pHc�1��^�kw㭐�0�:)T��P|e�z����L�J�H�JG̣gD@{���)J�y ��`�dŧ
7�A�\u@k|��A�	��Y��Hg�]��/`�{-���F�:�e�ɸ����R���#i�X2��ygRU���(�'���Z]]��
�9Nw���dTQ֐�=�v�[�(N��7���!��~�ʅ�t�v���\
<Es�xz�����I�;?���!�h���)�بS�����������wT��1b���kڔ��������2�@��K�3��� m]E]�G�M���U�}U��6�-^�E�{����['M	�˫���ܾy`5î�ݽ}y<�(e�>�u�����#�W��{C������̝w**T��>Ki�l�&c"P\��bV�E��xV@~��M���b���~�t�~N��pfw�E���~�7Ƚ0������o����(0��D�&Pj�KK�(�G�1�&��h[{Z.x��>�U��&��m�"�i�S���̂�����C��� �"��p�G�o��r����^,�;���
�BaƦL��CpB"ׁ�����a�No�y}�_��Jef�GY�^P�4��V�e�t��������!���>y��\'jU 2��j�Y�!Ql^N�f�=�|1|o�ܛ����������k7�2����G���A����pU	��w+>�t\��v��D� �C�����2�tĦ��>��[��z�$Va%��%aX�M�ݿ��������:^9&���m�����O0bR�^eHX��3>����(��5(�^&\�3�v.ܥoo!�f��m����~�m���=yV��84�|"8��K	b�؞(�.���l�����9��X�HT�������Ghw��:��V�/||��8�����@���\�+��q�,F2�_ q�T�|k�Lx���t2���w4�"�jH��y��1]���5I��1F+����S�g1�WU�MEϜO�$BV�,�����׃T�̆���n����E?��4���V��V�q���J���z)f�j��C��mr'�MM�͊o�ϩ@x��O9t0-?�n<���#�X	~=C-A���:8zF�&�}���Hs��{�(���5v�y=������D��1ד	DW�p�xVא�F�ɭY�d�_�t)��w%4��(���>*Zl瓻�A�c]-3�`]Tl���Qh�P�[�p����Ұ��O=�)UP��[����'�A�f��S������oZ�{�q�S�ƞ�,��VU��]&׮���G�3�H^w�/M�
�Wk�C-9���ղ�� P���TA�#����
���z.�t�X��<䱒���&��Ұ��fVD6E�fR�6�����Ϳ�3b�X���щ�B�3+TD~IrMl*�\���Of�mW��ļ8�/?Zi3�   ���8�;g ����[x�ɱ�g�    YZ