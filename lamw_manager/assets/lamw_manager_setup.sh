#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3553240463"
MD5="a5db82ee3d9733e1ea8c79d47c71d064"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23648"
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
	echo Date of packaging: Fri Oct  1 17:39:49 -03 2021
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
�7zXZ  �ִF !   �X����\] �}��1Dd]����P�t�D��_�)�O{���|�HX>CSڨ#.����f��IM�}�'�+����=�T��W��4�� 9�A����;�낽@0��������Q������Z��� 0�	}~��X�&����p�t��ǶC�U��I��w�י�.ʯ���OU���_B�Z�]r�؎�|P������F��N����®����̄���ߵ˔'q�WD)�MwiH&�������P|E;�7�j)0,r��!�Լ7{��*�J÷�U:2�&gѢ�����&�����Q�- �Y�u�)�����a�������751t��"{�����S+��mdf�{V6�ܑ2����L:�cE)pY`�/�ܩ(礡�ޟJ�*�^-G?ۉ_vJ���AV�$ryg�4d�$:�	�r�~3��x�|/t����]]�'J���ζa��{�u�N�Z��7�8�0����I+zHS���6�3ȫJ���B"���)M-D{��VF��D<��E�ne��2�%��&
̮�)���K��H��]\�\R��b̤�@HIo@�'�}>���<q�Vd!�4م;[לo~�9�F�Na�A
�2� ��I�I�EfqD�}�8�v�\�	:E|��!��}�|�:���Nű��`�JVq�+ɍA}��C�c 6�7;�Q 74[mpVQ�ϺL�>��uŐp�����T�s1%:q6Vz�1�&��������nW����\���s%�mOjG�D2����e�]�;�M�({W����h�o�=��X����м�ߕVJ\�λ,�����/����a�\_��|�σs�nNL�,�b�ۋ	��p�}��q![wn@ӧd�?;<��uu�K���R	��8^�`Pk��Xj^��\�id����Ӌlr]_"]�������Tx9e2�����,6�9�f�ZR8 ���qR�gN�|Qz�#����q�$r+}�"<��3k=i�/�*��B���be�<�c�n�Yt"$IFc4�0��9%�����D'����)ǖ�)cSH�~��3Q�F}P���ؒ�h�������q��K��>1����N���؋�.'y��ZJced��:u�݋��l�h9������6�A�)��ԉ�*Q�2��i�6�x� B1��%sNWS[�Z����焓@!�닦K�?B˛dNI���%43Ů{A������?G4�y\ږ\�20l�*�D�
�,<a��޵O��ZX�g $�!YUa�'�TFH�����'�_PMڻC[�n�"������*�d�S�;J,H��-�J�W�x���7���I��`�(���s�?�S�@+ʍ�`�n2y�mGiKX��<��%V�k�~�)YS�m�:�va�ZL�pҀ�(gq�+�h�\I̦���́ѱq�)���Ug��G��2;~���������MD�C��跁ɦ�	?�,�=BeO�.�>����oF���B�ؘ������!�����YdK�p~Y���*�x�5�U�q��Ȓ�&�%9���ؽ�/g�C*@09[�~��bw�uo�ը����?<��PQ�����l����asF:�r5@���ϣi��l`Xl�ȝ�?}Gv�!�n�� ��0�|��"�5`h��o�h�_[8��jJAN�a?<i���c4>�g�YѦ����F��K��:
��o�����	���`���k�Q���
W�{���#{f�}���^���k���\a@ �Ɠ��O����]�á������wO����)]�9���4䦔 �D�s��;�����QO����ӱ�#Hk>�7������7)AXYk�B�>ijmFakEu��Wё�!�f�8U~�LL�ʠ)��	��=��dK�v4]��6P��s�� ��Q���60�l؈ʍ-j�A��*�J�&�;USv�AHS9@���#���%g�� 1JX�q����o�`F��������S����[�>?X���`���㑷,�#ՙ2��aY������?�n�ɸ����[��D�A4����X�$�/�ʦ���}!4��'.!����P`�-��Ho�$�|��� xf��u�~zp��U
Q^�X�i�������ڹ�R�K1�dy��"�-��5=�d��(_$8!Yن�j3c"ObV8Z~���h�k�-@�B5Q/۝Ҭ5�jnW�b=�mu[������j~m�Q'M�A0]�+�Gb%��Mr�oi�f��wt �{u��\O�U}e%e�/s9������n�x�D�$�pުo�����5�m�k��Qm��5��6g�Y&���v���\-d������l�Ჲ��6qb�FU�w�)�!GS�kn�Ŕ0GFѬV� �s:���RP�'%0�E��(���Q��V�8����߮cf���q�)[���FE��SqUK��p�ۗ` �{yp�ͅ�K�R뤢N@�P<1򠆴�y
���3O�MA�'3_!��C
��Q��x����t�{����'-�Lǚ�s��s+f~���d��.n�)�)�uov��)��
#c����գ�x�`��b��-J���-�'�?]*�J\Duv��#�?M���W��"��%+�]i�'x�|�(̄�6c��k���V�c�o���E�!���n)s��3 ����#{��EW�#.auT�@��_�R��e�C���t淵�z��N��Ei��HJ:,����}^wR�k�1�1j-���*%Ncn	p�\�s�;2`����/p���us�c�'n�1�EڏI�߽��yx8�7j#�&��s'�(S��Լ�}���8z����R�t����.���^��N���+�OJ���� �5�p��⽄\I���ү�1ӓ�Y����`�}�@K(��F����	�>�l�H7��(#6�ڱ!��[�L� �I+7��Y�D��������tϊ��e���ƣO��J���y�����U���3z�Ed���4�ry^�1!a�S�����D�G�Fອu���c��l�|{ ���%z����(뫈f.�5��p&KV/�|��
x�͉J�p)2�__�L��'Tv*�AS���Ćr ���Qd5԰N�"<���T�E(XO�� 2�'��t�i�,k���^�Z�^�Do�bJ	�ou����Wk�*��Ez������È��̟����j���B޵:��/J�b��N�W%.ώ��Ҝ�����k6aN$���I�8���yjb��m�1���1���Iˆޱ�GY��\�j�$�~����[���B���I�߈"0@&n6�Y�����t��/�&Ie������!�|������y�?��1k� 8q��F�`�L5��"9o�87�x���V�U�ib A�h���W�"���cӪG�}��H�3���d�w�����$`=24�dg�"m�������c�̇VJlkH�Cx|��z2k[ �ۅ7��CF�Js����ꓔ��}XH�>�"q${�����dCB\�_���.���^H@n�ݦ�ޖ.��Y�۬S�Z
�{��P��7�Ԧ�1g�E$��G����3m����EkM�y�p��͑8�c���c�D�շ���zTv�cj���i*�j����U��U�[Ȃ�p�pI�襴j�{�v��H�������Y4|nFp�c���O9��v"�A�`�!��#ZX�Ed���������[e�N���s���)P�BǜY�=t�m�ن��
``Cu��"��5]Ȕ_q��jLD\�m�ְ3��̃�A
<�����gU��}�F���?���g�o�
߱�6�
� eȒ�Z��3�$Go2�+�2���E���I\[f`�ߑ'!g32y���>>s�B��8�j��Y�o`7d�vm����&��2��jЏɾY��`d�)~b�m���ˇZfnv��&Bں���b��8�D���rĽy�ȉ���N~�b+��<�$[��Π����L�' w22�{�f�cq���β�\�"1��3��;f���@�xb�>b�M���y�ؗD���B��]��mea���z�1��MPjɁF� گ �}4@|�}$��\�@���/� ɛmJ5�[����I�gt��Y�^��	Jt��XA��6K	��kl⶗R�	��g�f7��C�̢���t��5OH�r�:(HY[��־û�����^X�N4��VZ�][�
9��.]�1�� K�� 7Wd�1kW��4��e�6�R֑������!�ΪT�kj�~�q_X�%8 �e!4����\Tݝ@Fu��V�6yU�O�S�2�==^V�	���a�+TO������K�����N�7Ɔ�!�F�c�Hn��J@�}*�*e��;�L��{�hɵV�(�ע�k@�� �����3�-��AΧ���Ē��]�P�qa�TE�\t�����������[����ٚ:���T��7�D<����� �IZ��1��
N����8������R�G��i?$�;�.����߿�`�~���:D+�������o��P��D�G�W[��^v��n�>��Σp
�Q�� �	5wB�Ү0�C�j���Z��Y��m�H��f�� �ܓ+;�Nn!�b�F���qt��S�8��ԏ�Y�B@J�љ�ы+P�'1mT ����������g'�;��6Q���{�,	N��n����i <g�-& �����똉��9'����b|��q��ѻءoVf��E���ا�� _��>O�7����A@���G����:b~退�~�]�Ϡ�J�B<Ek�E� ��9��(�@У)֊|�]FX �qEϭ��Q�~��j��Gdb#١0��d��@i?�q��O&N��m]~Q ��0	��1n���3����x5�ڶ|�z	w����p���'`�M��Jd:�� �[GV���H{��3�C`�K�c2���^�*ɒ*aȯ*��e�ߍ�fv��$�@���(���>?�x���������\ �ڙ@���B�3��Ɏ<�F�ji���}��ֳe�5!�$5&y�c��(�U�!n��Z7�[��g�U�3:� ��s�bw=3L=��?��jPN
�����|��܉$�v5�܈�_q��1�wޗsqv��mP��"/W�Z���
O�BV4��y{�զ!������`"-��H�&��$��GN���9Yg#r�[ő�+�\�ej<1h������`��$���F`�>�e�$xw5��=+�K��57�]�2C��
��UY��t���η��2�@�C3:b.YVe��f���f�6AV�s��(*��14��}�2ޣ�j�Ŕ�m"��C����!����x젃�ſL�b�ᙏ��e��[ۏS6��D-�ݟ���������K�T;��9��!>�NB"���J�*�#��rI��>>��Blrz,G�G
&���z���q���O�$�XDZ�u:���� WT#/��ͫ!K�r�+��x��֎ꝯ��t�6�*԰�&��Y�;ؘ�{���	�&e�8j����2	�vՀ�kZk���(g6����'�/����+#%����p�E�Áe����h6TlV3���ϧ] LR��uy 䁏 �iz�{��fc�Ҍ�cp@^"��`���6K�ܗ�����>f�����s�����'�`�� Mg��O�ĭ��V���fb���JfY����-P�֧�$9Ā�9�x�R*v����zz �<���ˊ��Z~����v�cA
���T�X��W�5\��-c�B���N*���e͝�B"'hu
��	�-J�|�P�����>1��a��\i��4���`�W��d7��D���t���W%L�n�D|Bh�d�S��M�A7�ɶDO=���m�aZG{�k��6i�Թ_ۉ�D�*�'��>p$O��2��	�P�w��@ڭQoY񮕦YO~X���P5�x{N0���T�#t�th����x �h�5���DTD�ʗ�O�Y���th^|5;[/o�5���)�ޡƞ��3~9�$���TϐY�A�ww��D��
���,/
�'
.O�����{���v�%�S0�JB�ۂ�mF�TrlJ���B�ψ� 9�Q8k�������uY���'j'��d8�ge�%�?����j��2�`0Z\Q\O;L8�P���U�Pnr���uwb@�B������?;�n����z�� �&(OM�+'Eu�g��w��6�C=�M�%o�+�賓`aa@O�%&�����C�<5`y���)8�gO�Ļ���eʛ��jQ_f�8n�%�GE�T�I�F�S��-̿=�Vk���QP*�X��9�ȶ?)�ٞ�?���(���&n�����[�#����Yt����z��8�Ho_3���CՍ�V?
ô� �*�te�s��X�C�f�Ҭ`�Ԏz�3��g�BW�y=�(֣�T���"k.�O���s�8��kl�</\<+<Ҩ0C��^��F�5@_�+��g;M���fNwq�ͫ�+yX����O�}$"���C���	�� �Gl��� c?����1Z"�ޗTKBV_�8��7#�t�6D $%�x�9�W�hgT�0k�V��U~>Xl���2<����&��ȥ[�NoZ�?��l	�W"8�+�%kX$m���o�`�?��9J�&�
�A��+ ���W흷���pc&�gh�X"���K.|_�pS#=.�i݂�z>�M���'q��;�wY�2�N6��}4��(����6��ׂ�X�F��L�r0i=+>��>[�h�̘�S�JAˌT����ݺ��%��'P>oY��3�0��)`�l�Sꢣ�`��it&gݧ
��;���`�׋8F�*�1]5���f]P���)"���<�`g6�nYr	<s����_�[�/
̌�S�03�Y_�Q��Y=�p#��}4ë��5Uw�o�+l�������!η!��s��t�`�g*Ѯ���L�����^X=B%����&ǚ7���l�7oRO%��q�����dc4+$b��ޟ|�oZ�`�/� a�'K�e�S��ИF|�D��Tg�x�%	��E]Lkr�9gu��%�sG�V�&��)����qa�N�ɃZ��Z��{�����E���-�Z��y"r��E�QPl�%�#Hl�!3V,���#̾���h�G�����<J4�܍~gC��8�2�(&���d5ɿ�GL삫�4��� Ą�����Md6���.b*�|#[��q�U�ҔHa}��5B�����ENP�6p��4oe��=h��~z�(t��`��$K�d ����ǝ��(���ܟ���P_I���|Fѻ���Ù����m@Q|�g6lʽOg��vڮ���" ~��o�XdP�ʏ$�Bu2:���4]�\m_�E��HhL�hEP7�E�s�Mn������,��~mK��\̺��P�{�v�xՅ�3��}��T��7�엎���]�^U���LT���O�Ib���mk("�	�۴�e7��I��4��p�k��~+�W�jd�~�#���tj̀�P<��[Pn� ���K��)H�-[���2���dx�H ۙR9[hj�D454��3[���(�щ�]=��6%_ѥYc���׺C���`\d��ypl�R��ܳ�?�f��	4�$��kW�j�]�zoT���Wu�^�����<����w�	��^���.�7;5:�5���o[��g�E��_=}���&�� ��=��Kt`~m�+R�f�����~*!����e�]�KID����@���"G��4�!Lb�<�*����wm0��|ӓU�|��\Q,�M9
�F��ƪ��v41��
;��>�gC�!����`����3�&3��x�n���2����ALKZ���0W��~���!c����~O�!�M,��^_1�e~g�4+��I�V̢Sg��(t&ރW�-�B�D�@~��s��)�3�a���O�����w61'�h�O����D"|�~�wR�*����6yP*#������.��hû�e�ٚAb���f��+@)c���V~Pja�X�u��,Jo��(�ݢ+�r��*Kh_�w=��rd�-�D�(i�#3�~��[�Mԩ��ް�G^<�x��/*e��>(�,�}zS�7�Ӽ$W����g�	���-{�ƉX���^�@@����[�$=d�?,uR�}u�~S���JԸ����z�4X=DFֿ��׷ѳ��ڇ��X������K�!��4I�#�<��������s���K���5��m�v��l�E<�g������)�4SBj�8o*}�Od�\%�\�Q�w��SB��G��X-�c��?��n�-zR���)	]�2�(���i�o)x&��ĭ�q�!HJ���n�ɞ`|��r~ʱ�'��կ��\�l�WQD�?�U; Ka����wT���B�c����sH�@j�R�lf:�`��?[�A.z����[g�|�X�@��#�a������h�Q�5�� 8r���w2c&��w�Z������������+��� H����o'L��h��B!(z/nx�-���-�+�%���~>�����7���e9W��@>��+��x�E5��VG���Ľ8P�eYqd�/f��(Bi��\!�&Q[�P_��g#��������*kM;�~��z��?q�%iM�㫔å���r�Wl�TR�����	ج^6ۋx�Uګ3�>����D>��6C��C��U:i�]z��A�q$��2����uq�J����g��'
�3zE����#i:d ���Ӕ]�Y�C���D�ncqRȃ��4L��WX<~�cw������>V�2(�$
D�  �U6��X�2��^��D��e���^� hG9�����5���'Pi��I1�N����[B+�kS���@.�G���2�o�@L
2 :P��jl�;��&�7���D?��fi[`T{_�ZS�Fi�#%rB�lbST=q{1�H�c'N7v���J�*%r�Bѡ�AG����:�t?v�,Q3��B��4�;Ա`LfuJif?���b(i ���};+�G�UM2�OI(]tq`qs��%�vHm�O�e���X!���T��W.�) �C@r��8����8$�W��i�6��nP�61`�lf���$���IY�F�[�>=��>�r�	$��=G䰸eѼO-�z��_Cw�������p��WFn�~���{%u� �	���N�]��Yv�EY�Wb���<H�1`ʻT���ŉxY���S�	�+f�2�F�o�8�d+�? �_Q�0I��K�B`�
�{H0����h*2c-�t���T�S�'V-���f���$tp~b�Ȳ2ɹ^4H��%_�Uoޘ����.�M��WO[<�m��8�ؕJz�p���9��I�
����T��R�2A݈~XN{Y>�.�O+�
$������>�\"] �/=��@���Jl�h1��FQx��b��8�Ŗ��y�x&��H�z��p��k���𯒄�v�@e�9�=�ϝE�r(�ӷx�W*0��n�նc���9��~�<��Np*⒌v>�z*ԝ��D������*�r�:F�h�*�����Ȭ�' [�O��Ob4��s��C^�!x4�������:56j&b=�a�Z�D�H/�yFl��|�T[���"������7n�O������U�,�+s���k���gfo͚18Q4v�RE�ss� ��W�M�g���������w2�������g�,���"��K�;�X�������p�*�!��H0�d�u<jɊ#0B$�T��R�W`Uyi���GkIf�gLW?Xl�[TgR@�����ۄ��|��0�d���q�D���y�8UF�!��f{���0�oK>���#�`X�p2e%2V�"��3x�0Hd��5C��P��M�-W\�T��5�b�< ��	O��S�+���	k���^����.#���
o�2��j*KIK(U�T�p�(�G]��N��Ar5s��"a��B�ʝ��9\O��Oqc�<Ob��eO��hcI�
�]5�Y�����J���br{l8Zj��{�x��l��U�!�)n�9Z�ω��1�dw���m�����ğ-��OV�� ��Qc�ø��秊�!j9��c9W�oȳ�S��v�G��.@��� e�=�a�FFP���E�sOѐ{g��EJ��r C�
?6F���K`��zSmJp�9�ȶ�m�"���r��!�P��I\_v��r��J�̓��aw��:�c��Rĩ�['�֊C��/�􎚧�zӜ̊4Cσ)v��/S����aSK8�m��^�y��P/{�	0� X����2�%
7�KƩ&��4.u���P N��3q�����5�z�ҍH�.��ɇ��J�r"x0Pr PJ���DPvE����v�'
�$�+����wY� ��HE�%	���GJ�ŤmX�T�'��m�)j �Tؿ�IP,\�Rw�Og�11�F�}p-q�\�ӄ�8(�vyi��¿�CE�����&,�Q���pS0�Uq��rg�ՕZuXQW���;����-"$��.���+�0��_*:x����Q�(���*���Hz>8-�K�AA��##�S�K�tV����ɑs�CS{ç�b�������kŨ���A�7�G�3;M������8�	DGi���d����Z���q�i����v�T|z��;�µ!}K,b���'��% _�����J����$�C����p/V[�K�z�򔄔�w���\��(Ԥ 3��@�4���+|o8Y�j�{Ua���tfw�c�6J�aR���>�:�:Y��l�{�t×<�������a@��\6h��[3������8f^2\��sph Ie_�Z=���
�i�v
��xV`�5�d#�$����R!���Ĵn��G0s��y̫��sA�ӳo�S߾~����<0L0��-����/��ѱ�k�N$����=Q�����bd���]/�D�)xA�xXc\��Qkr�F�� VG��������d`����� m�p||l��~D����z.]�~��b����fM�@�f`U)\�[&���0�i�Kr-���g�д��nm�.V�q;��c2v��P��뱁5Y���!,s6
�L�<xܠ8G
 L���=��X�&t�$��&����*�[�n�t$��bY�x"_V~c�>��nXOva�D�3}Y�0��A�f�/xq!�u��s[�kD51�;V�-{���]x,�dI(�I�!����YO�mŨ��3�h�`}R!&���y�E �)�����#��]�ڊ���hb���u3�f�%so�y�Q��.F�d7�D1ʳ=���]�]\�E6+> aP/�:jp��I9�{00�@zhZZ��p��g:j���.I��5�)�����Gg�,J������jQ�J�/�br]���r��Q��7�½K] ���԰ܯs�םQ.\�h���=���S�:ک���}\j�h��TM���M"�l����s��lj�^Y�gj,��p����ڛ1��"B�݄��}e�v����>�;琸�7MG��K����ol�W�2m�o��u��`�|����)��AG������X[٦��WP�q9�I�=E�Ĺ��ȸ��	���2�~��VNȇރ�B�,���*�a�ߑ3����H~,�|s�Y��j��W,���2�S���ʼ��0[@�k8n ׶`��j1�~�����{Rvv�G������ �\�@8�qNF�5_z�\:'Cm\�Dv�[[�V<�Mw�|mw���$m�3���mhP�MX� :�W�RE'Vѹ	y{�����@re��-���e�f0{���h�؇$E$��M�kI"?Q��pq,�E���ѿ�(Ӯl3�x��LcOX�P��Lm��`���hH����iv���UU̧*�0�ğ��@����ƾbԞ�C�O�l"	9W�{Q��ޘ>����í����<��Q:y! ���A�\6%�v��<�^a�7��]Լ�O]�j���D�Ր�9b؞2ຑ�N�ˮ>``jV�g�/iX�.�^�<_LQ��nw�S&4�u�r[�7�n�F�9+�A67�˙\�Tb�xh��3�$Ţ@�K>\o�����+��G#�Q0=���~o+��$�g��Ø�D��S�`�8��r2��^&1܈�~�kp��^���Y!�ŽG!ϊ��b30`�i�����i��5���<|V�p,�~�\yNX��ӃF��$)�����t*l�-`�'�Vn��� ��M�9GV�m��uٕ�#���b5�ď�N1
�5g�3�#}�����1�)�;w�[�oT��t�o̻Q�8��b����ҀNG9��9��c��3�A�5�B���1H��,�MZq~���-�.����	wՇ�"7�X����K�%;�P.s�[Y_M.��PYv۲*�a�	���z踃E���"�(�y�4���}��̘�T)�7��z�]
 �Y5�G)�l���i�2̅�L��t�}�v -��k]2�ɏ�Y��\�h$��4�ǿ@�
)��*�� �`��Yr� �f��-�����5 �޾�?/ ��My�.ipR�0�,�\��Fo^[�d��
�Q~�P������1�bX������4����R|u�_�XL���I5򌉖5���.��y Bn~�'�~�q$�_@�M�"8���p�\�ߏ_�O$Ȝ����1�����C��R9�gB́�5:�ٔ<������ ���"k�@v�L�͸�a�	��Q�f��N�����T�u�V�?�H���&x��z ���徜�+Ե~���Uk�rS�h=���т���z�1�̬������11ף_K�3��]AU�~�P��Iia�
�N�����%��]zi�¯q�-2dLY��[,�e�b��.� J�H*����ɪK�Wl��Bdzq�[�ڤUD�@V!T|�w�K�v��!�l�Y�V����nP�����/�q,���5L�ڜ��K��4�8KOPR]��w4i*szk�
=n� �!,�{}�
MJd�y���:oE�9�Gu�{n]�Q���q�75,{O?u�^*����[�Fdۅc����i��hS��rj�:1�u~|��;ÞE7��P�\���\ -m �U{L����t��5܋�Ev~�htVmb�J��qο��+|MP�K�f�L(f�ą�Z�h��ƃ<�O�+������޻~�e}1�.e��΅|��Ǡ+Lz�{D�9O��6 ��F��.ѼR��ħ�0g��s���\�yj�l Z@-����",
] n���p �'|ҙpD����y�/�����8�?�S�d5�U(p��l����/t@��c��Ӭ[K���)�%��[l��Kٞڱ"cA_�L+a��v��_���ޘ�Џ�\�B÷�DM!��.#�D�O�7l���2������¯j�!�jnbro�X��y�F �eo$K�n�b���n z�6=��@j���.�1�mW�SOY�;���x��������=ڑ)㔕v0��̫��<^���P��,S�t@��A±y�$��;7wXI�ؚ�U�r ��2
�ɜ��gO�oY�KW���
�z�@�0y&��ƯW[+ٍ�d�
��P��	O�F�ՔS�T���!�����;���d4@�{��3j��� ������.P�Q��y�Z�L�`�5yy�����/�ž�L%y���m��I�b�TS�$��fy4v��ՓynH:��v�E�Hz
ݡ��b�
]�c?$�&w �������F<2�U�0.>o�D�hn&aZ�*���<4���,n�-�B�Os���*��0�6F���zNd���FM�?�ʹ�:��H*lC}GH�Z��=����uk���&���Q9��z�2�Ph�X���!��E�k�V��T�VkB��Lmx��x�'�Ͻ7�W��2�o��.����W��ΑѽTY�2))��ՐT뜞��{aZ�v.����Z^B�Ajy���
=!ך_��d+�7_U�7�^�ZNþ�2Q�g�w�����"<�(��t�H!?8����Ǝr�|��PP�bF.�CJ��||�h�N���id�����Gb<�L��Γ��pޅ�S!��YI�ToUQE2I�<E�L��z(��v�T�r*OMg�3LD�Z꟮��yC;�l	X��Ԕte�Pi5�+F$��Yj\�k�DU7�`����a{Q�_5�4�YY���+S�0f�ó�@\g������إV�y�
���KUs�=�x լh]�XF�����""�8�pH�* �A� K��J6	L��Ö��X�w`-]�~<�X	n��P`�@"죦�H2z�ђ���v��nQ�<���(?:UϡI����u!V
2�/�Y+�/�������m�FY˽�!���N�i���$���R�RՙH~��s���������D��J5`�=6���fp��y<�^�g��v�����%��^a���9��>��^o�#���T(];h�g�]���S��ϖ$��n�����.�����E�iJ��4vm��8�P�Q�����O����/��rU4���/�*~H9�|�)�S��_��
P23?c9�/f�1�z����9����v��u��:�m�/�w��?nΥ<�RP�4��W�,	5��D�(��'�i��_��J1䌭Is0��-pm���b��"�4���9���Aޓ�l}3)P���w._O����@�P`#�.����p�$��*n�x���@��\j��yY�5=���Q'�Ɏ0}Rzd"��!�ݪ��v/q�I���G��w�4�&�"��)Ў��@��͹���#<,X6�MGy���V�l5�H�q8��O���%FM��o�D��ޣ%���ʠ�/.�CO�&�`Fh�L��@Qq���t8���ÿ0�; �{�/�]��8)��K�
�KrEN���|�V�Ő'?�e�����
���������,l�1�z�X�٧#V�nE�gZ��GW��B�ӝ�j�m߈K��?�������n�J?�S{��|L���]>��`%��?�NS:�j�=���YM�2aOtn����iK�֛^m�j_�Z�#��^��������eb��=�"]W�\_�������34n:��'�@k�Z"~S���
C}�i��$����C�h(B�֒vƘ�A��?�N��D�Ay�ݲ����I���b��z5r��Yu#�̨����E��=��!V�t�7-�����p�>$��h�/{���������cD�|>٫G�H����@w�� �@�j�',1���6��3w��d}�d�
���$dBK\��յ�p6ihф�=vk@h0��[����L%�c�z���y��إ2���!+q�w5��)G�L�6į���B؎PL���E�n ��17�ؖ��X�K�-}��y0��7V���õ�5S/t����P(-D �a]��K}gI~&�w���J����0a�=vߤ?� �:�}��gRX�CV�ye�"���=�ю.�n��> s���^�*�7j���������Nʲ�1����<؆���q��J�h[Xl��Χ��O�@oY��Q����b(rj9��|0i�N��Hɴ��I�3≦��I�Ƈ����(�l	������-k=��8$[�*~�,@Y�:���'�[j�+f����I"62��)��D�Wb�M��䔣ѐ��8<h;"�ѕmxN�Ԇ��^�U�MY�o�%b��l�Ι��G��!sl833�H�vy��I(�PQ�]X��1P���+��s�Ȝ��� �GL\�}rv�v��b���'�y�7�2i�ԩ2=�#��U"����fIF�qh�ymQ� p��7^F����ے�q�am(����F���볊w���T�`��6㩗mQ���#ux����ѯ���f���( �S�l�Ao�#9���=��+��m�����]�:�<r{�ұ^l������{l>�5f
��X� AK\��W�q*_/M����4����D�؈(��1�H ��9�M|��Mc�ԀY��h�Pb�
�*�q7�3�?����@nf-�2�]Z�nm�~Ʌy�|�c���fXU]ė%�����j?��(6�Z��eP�\NC���6��7/l��_g�Rx��ƤF㸏�f�⣾|��o�7;�E�<
��(�9�R8���b�:D��e»M��ɘ�r���
����"�c�-�p��K՘��%@������� ��5�������	�:�Ds5����i�Kw��ު�����|�Iv8�������6wq�����ȇ��O�������+��(�s��t:.��
u���h
��X�OI:����̽��`��{�? ��c��̳��/����\�1��<q��X���?ˎ�/#�8�=8��~��x�!Gє�}�[�y�dB���N@�M��Y�ԅO��b�m�mp���)���\[�@�8:���4C�;g�;�����io�U�k�8t�ih�;5�%M��>A%�&�r��\��!=��
�tt��S��I-µ��閬�#�saB�0�t���Vh,7��eU8�P���x����Mv�b���R:J����.�����3��,�����օ���ڮ\j�1{v�d�������VJ9�5?<c�w"�"$;�j���PNJ2���X�$3tZ�Q?�����P�������2��b���=R���1�d@�hN�<Z��.�5n~�ô@�)L݈��撿MZ@���{.$xNs`!.wuy`��K+\��װt����a�8�Ѱ��\߄��I�g.�G�s���y"�T�$�X�/��ƠZ��r��k���z���p(K�W�u����T_��W���>@��	�"�_��8�K����[�<�2M'1sUXX���������Q���uXh#+����vZ������p�Q�،�9 �M����S�*]ۭ�Q'5u�V��+�q�,kz�}�_�h�4֜���z����.pw�0�8�#O�����CZa�q��J�T>J"�)}�� ��UM^L�@,X3D�������FZ��VMv'��!�/�7���|�T�
�����(jB�qi�����@D�0&�i�|y-�z
̳�:���$��,Ϫ�|���8V�Q��L��YrF��v�5p\�,3�gu�;g��I�*ʗ�#ґ9W�A��5��Ei?g�9yE��8��v����t�7]~�?�汬��7�K]�ĪR��EI�[y�X���>v3O�M�׀��S��f�ehU��ږ��Y$����u�˧���Ex�z����ɦ�^|By����9M=�@�!��4��5J�~8�,H�. ��Wb�c��*'�B���O��\f���cѣ�2��LG�UI��@��]{/D`��]�)�i<O��
�'�����_��FP��C;�:z��	�.�d���.OaG�\H�Z
w��1��t���G��ɀ�G��1��J�·ܞg�oD(#�u�=qut�%��GC���(x���� ��>�@J��=����	-�4L?ح��<O\C��K=�0�;������3+7$�DT]���͍{�}��k�h�(�dYG��c�|�h�1r3Ȕ�YZ%R���I�l�|��+����4l���s��H$|ؿ��{ݳ�W�EKli�D�
��M��uU��ɉ&���L�jr,�z�zXE�����T���,	ԑ����,�8��mra����r�I��s`$F�r��*�]_��~��A�m�a7?ӵLo1&�q�)���t�p�}9�g�q]�4ne4�����u��++�Զ7%��	ʂ���R�&{�̪<���,1��չ�A��j�Vh�Ę8�a��~b�����T�ѥ�VZ��N�¿v�	��՝�����P`~���HT��� d����o���80GG@�#�DKI �Q'&e��]�&Qa�}�9j���������� �tIA�U�gm_�uI;�(v����֭X[���L�=�+�#U�����?���W�L,��fn!�hB�ʂ�h�D=�.n˃K=ws6iE��83fQ�h�H�H�#*���N�kJ^��=,�xqï0i��.֏!��u���T�(*|+�c�ڼ�JA�p=Tэ\���)�(-��j��Y���Js���Q\�0�˔zu4+��`�عs$F�瑭匐(��\,�Go��^�~%����2�ד�&[� $��'� 㷘A�>�B��}����2�.I�i-4z�wqm��2@�}��(j+�Z�gf@:̯��ٻ�ԨS�C0EK,C���	a3iGCϓU�:��)]���rA^@U	h:x��lu�~4vi:��F��˲(M�~+�峩�<!�L�c=GR�*; "BZ
�Őx��!l�ĥ`��A��J�<"S_$�cR� c��ַ~���ڕJ��F�eo���O�M8�a���~�r�z5}c��Y]a� ���������ew��/؇ �E듹1��蹽�IA��wNb��<xk�S���i�I���Y@�Ⲗ􎣠[�Gy�`�d����f00��)>�i�f:g
��EB��xa� �4���9:/�{�>�"JmY��z�F���:��B�5���d6�F���Yێ:+���TC߃v,� ��r7�y(N%%��z4v��q�'��_b`q]!-� Fv����G��>6ÿ��|F�/���;��>X0��<{t��7=�Kz����j�$a������ G��r���u�yKų�4#?�l��`Y���������8���4�=���p|�+�A�Rvmc�y�g^f�_i�*͂���7�H.ʴW��X@\I��8������8��/M>'��v�$��Bw��t�A��(	��N��z��X�X�P-�ܸ�K쵤��R�j[W5_����ݻ���ί��2�8~���ۈ�r�팃���ȠB���0�=Z��+VS�{����
i��� F�3�l"�WS}�z���L��a�d�x�Y� (�ILē�������Y2D���������1�z��:y���Ѧ�p3����z�҇�ah��މ2����8�����H#�Sճ��5@�"%��ϔ��Y&:��3+'�ڟ�ӧ̏�P�*}ł��kL��)��P3�_���V]"P�Q������Xn���FZ��D�j00��l
��,�r%�QG���>)@2�a���
ѡp$7�5�4G�&S����(�����Rp�4�ZS�d��W�U~K�Ĳ<���jL�ؑ�˖n�\��pr:�U�����I%����]��s:�b�U��X�pX���(�GL��e(�n*@��vύŖi����L����È��*�<��ftc]�j!�ܿ=2X��ؽȷ��9�������,�]�0g���pC�=�G&��mT��ygw\e�#�fj�0d��Vߔ[�Y˗��9��hs�����D�t��1�$�D�:U���7(y��&�q��t���tJں�k��nC�7�u�o쇭pTd�h����ȇ��7����U9�~�r���@�w}���bb�ɻ��H(3"u'^	�{dk,I2V�Cz>�n$�]�l@��o��[V�b�\���麂\��ߧ:�nO>�.�����)���̳��&<[�'��_�U11&h�O��ҝp��A�t(A��4�x�
PziV�!��W�ڈ�1zUc�;�I��G5@�r���U}�!x�dDT���Q�^��9�<T	����zi����S- ���{�A$���ѣ]C	�	q.�u;A�п����r��p ֭�Y��8������1F��t����N�v~}5�q���s��C�����=W�z�U\�5#�綤�(�dr#V���Vk�<�ހ��]Bkx�6&�ab�$�!r0����>�V����K�ΈY����ԫ}qh�i�
$U����)��(?���Í��+����)����-<9��#;��Zӓ7P܀�k����\�De��ɓ�'v��N�?\�s{�yE���t�V	��&��!aZ����>]%���I[�^+7��9�jf�v�͚�5�Þr�5X�jM��}뗆7��y��Jߘ�$��(�Z�dAEH�,��ˍ�v_]�j�:R���`ӌ�>C!����Ly�٢v1��3@�\�gI�����)����ڴ4ү���-0ঠ9�mw��z��'�g��)kU_��{�
�qY.��Թϗ0
߀��K�ۊ0 �����\r�gB\���Q����"m϶d���5��db���߃>��2%�
�qP����1�P�T;k��e�[7R[h�}�����8ƙ��n` ;'f �sr�&������b�dG��c�$n��>��A����>p�8���:���N5�G�;vwu5����]�M�bSWi#���ߩn�i���A�
?��Vz��ED^H*���T�6?K$�K�4U��Ո�3Յ��JZ�H��Go��޵������ORd��>�LSƳ��mK(�����f:s1�*��S� 	F>ȼ��4�#41�yȱT*Av.��a������ͩj\�|�݋�y�g�隽L$@q���k�(���H;V���X��=��
۳��*^�>��#�Ir�&�����x)I���W��.5�W
�P����5���έ�` T���Pz$��4�(?�|���k9����y�L�c�W}A�͈��/��[s2��nkH��(��Z��2�5�x6P\�g?ah�0�C^8ߍ鵢���b��ϰC)��!�ǻY�S��f o�krXl���NѦU��Uxow<��N��Q<�c�P.���! >��mǶ�K�f>�A��f) �5��1�Y�$��'D���]��	�v�	�L��k0����C��k�M::D �a�x�]�z�R�������ѧ���4�>��Ӫ1�M"��ZgI1)ę����N��34o�����!Q)}��� �,BLB��&+���`��������r���*�['�}��V���4��j�|���A�M

wr�ԫ�HrA[���a�gS�Q�?��k���%��5����|�W!.U$q���RG�H�BJy�)�c*�`���DM�~�M
>��H@"JڛD��h��1^�1b �뜅�ԕp���|�,ZU1��`��Z��Ňr�-^�'\�����P�l�F�@Q�'��5�+s�����"��״�Е�q�,$��=�L����(u�H��л$������K��L&ani)���^Yi���BZ�+p�+-��ډ�	Ճ��ϗ�cG��Fb�ٶ���YhG�SU$ޖs�gE��#�e�ִ�?;��xJ��J�j��_�d�(k�8�S�E �3SE�*�]`��?A||'�"CWi5i�d�l��^Y7e[�ܲ-�}T0���\��� ��R��{��E$?�����NxԻ����3���kJ��ꕚ�!��s�	�+��:�վ�(ȴ�1���V
j|�.-�s�=@/�v�W��b��m�,���,�vu/)��6�L��9��^�ғ�y��1�E�f�^X$��ںY��w�"��aO訾z)��H�8C�!�s廿��#K?Va󓲢Y�K�7d���ğ)����\�Kġ�J��wE��� q���Xl�������s���m�:��T����+9�e����m*�q�t�Ej��Y�ߦ�Ir~�U��ri��Ki�g�{OhwEx|G{���E&�#�	����r�y��g�'�##�!h�
��K+�8��n�?N�!�GߪzA�t�&ѲH��{q�̙8q\�����٘zGf3k�3��?����'�g�Қ1�X&��h���	3f%
[һo��2ƒ��	�ر��yQ�~e��71��S~l3_�q_{(*�-�gy��W�y�r}�J�.ynM�u��}�U��'P�F��Et���b>|�N�Cآ;�\"� ���}�N���Ʈ�-���Ǚ&q�7�����2�R_1����*��?f7���9Ks�3j*�>�,��������I�A�M�-|�H�sm���,T,�+��WV��4�j�p[M���iỎ#����Dӄ��"H�ޘI���~M���7mD�`�m�nʫB~X�*ʾ�Ŧ�'F�j�L��<�9�v���Yt��חԿ��t��{c����>H�%6��*0��KGke�����5�xk�*|H2�)�l����ٌV�N�3��������-��-�����։�0�bX>��}�XA�����3{`�)�'PSj��'�Qk�IP	2���J���ڮ'�����$g��6kq��'I�8�+O�Ut�?�OW5�YL! �a�`|��'4l~���ש�2��>�Ⱊ`���k���gE` �B�"$���S7�-����lgۆ��k6ⴷy8�" ٩��̾��\������2�D==��+�i�e�t�sZԝ¯.DHr%�FX�ތ�L�ر͜��䫣eۓ�p?$�4���{4�8&��U�����~=p��׭�ڒ&�Si͒�E靇�!�9f������Hz��ͧמ��E���"�03��mЅ����B@+�7`4���lϴ�������$�]����	��ʠ�g�g�삜֕�5j��?�/.f�+$s��<�)Q�P˹�����
�������Y�r����Ҵ��)eV�`2�3e����R&���1��d��?�Nw�u�O��������M�/ 
hHW��aˈ9�W\s�y��`vh�ĵ_�� _���Ke���05C#\p� �!�[��������'����N�b���1%�;�B��h��j� �j�j� �0��%�{����ZO�c��!E�՛���U���,�i-
M(���ET�[�q�i��>
)B�n؉��~jC���	����4���LƂ���#u�'���4r��~�i�GX^��Q�ұ%"���ƫ��a8KWA[K$�!�5��!O#>�_�&���)A���`T'��$��E�k�6L��G̎���ഊU� c��m��?Kr�H���J�K�D;��*��,v@m@�<Tb2��%a�%�����	m�յPI��J��i/�~�i[�M]H�읱G[��NFP���+���&���K���aD������T�DŨ�3�^��{�|�bT+�fM�[�����TڵC��\�)<��	�>��a�5oF@����|����_��p��=�gͼm�����44[.�B�4b�Od8tW��ݙ�!�[o��d�<���b��F   ʟ�S��I �����J����g�    YZ