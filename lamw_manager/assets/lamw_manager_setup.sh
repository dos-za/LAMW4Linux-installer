#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="153654526"
MD5="3fc10df0bf61bc42b44cd6c6309affc9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23360"
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
	echo Date of packaging: Tue Sep 14 14:39:56 -03 2021
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D� zno����.�I��hĸ��5���jA6���^�B�V�{+�����@�T�v�m3��~O �7���Ma՞�rk��)}Z΢1�btD'	��.�d��"șK�Ո����%g�J|���	}w�f�;�a�J.W�� �f��F��ʭm�%�̄�j3H��Nv�*���J@��嫖��vL'��"�Q�=:c)������`Ek�����)S�nҬ�b4�����!t���t<��E�C}m'�R&���p;���[kIe�@��d�K�^� U��p�-za�������o15�O�^�YE̩�~5��l�y������d�6�F	,O��x��-����X���Tpq�����+���Ap��ý!��r���0�匠ő��l��y[����Adకe�@UDs��u��h�C���(��!"�[��ѾFG}��,u�pe�S�So� ԊI�d���.>*�W&ԃSN�������e��������r70�w�ڰ�i,_���HGrR�>|͏��(�mq	�4�J������ђjb	b���Z�c_&nkͥ���5pk\�/��L_e�#e^��N�o�鉧Tq�N2����e���\�ϲb���v��\��E��)�t�P����H��l�+�y�D��c5�vk$bkЦ��~�����ݭ`!s�(�!�SI�CҺ�>:�^|�E�&��|M�O$�����Ll�c���7�R�
�1�T�"k���c����n+G3�	X4�U�R*�0!�S";u�:K���	��PN�7i��<�~�}ؓ����w�M�/`�!�X���,�H����E���u��� ���l�
ƌ�JY�u��ܛ͕1N�-oY}�r��J�L��5�$^�vJ��9)݃�	X��7RR��� �� ��?���$�;ʗ�E�F�;C��B���Z��=�;�ͣ��GL�s�QV
��m'#Ǧ8:���}�Ķp�0O��;-ҳ�l�܁�3�l�q��m�RIQ��j�i�b�v�]�V�� H�� ��ĺ� �K<�i�-.�A�4�d
8{w�Ӕ�R���o�?������!>�}��/��t������~�>����U�Y�_>=#9�D`������~�-ƙ��T��+��Տ���UӃyx�p���F��/�߿��/Ny�l
=���\�x:7D����fRXnč���̯8��U�N�M�6��e��ʘz��;�q(�"��ɑ�/�%�v�ZX��4���+õ;#�����L� �ѾQZbݻ�s�s���w���-�܆����(t��Q���z�Bvݥp�׹ФN]���m��
i��p�/h՘&>ܡ����pF�dŦ�4�e�G*�ǚ���${>7�G(��I�a�y�c@| a�g_Ǒ���P��|9ek��>���6�`�W��,���3CA�?�?�囋-�¾+��߱����)�⢀��h�:8���-���fǈ#�0���.�8k�~���/�Us�~^	���UӤ^�ݪ�/���� ��P�K4�$p"d��yr�����{�W�qR�]���C6�&�W�l���+s�@e�ϧX�΁	�:\��?�C��݉8j5\G�����&��5a��?'��\��l�v�P�y7�jeǀq�=A@cT�%x|La�<�����]��h�U��)�~�5%�~���! �X.;K�9��^�k2 }��nq�D�(��oW��ǹr��S+=���Y�!��kg�FFb&�#b���$���7���0-��_b�He�j�
�i���u�^�(�3�� L�V>��lWř�2��F���&x�� [�$&�Mk4%��/9C*��p�zcJ��н��2 �N�ڞL	4�YLmp�2Ĺ%6<$+�2،�N�x�R����Aw��r�#v�jKu4��YY���v����Br�*���+���A`��^K�euY ��D��a�;��R�>�.	�����Y��^(�6�����*!�`d9!�%�o`DP����3�_k�CO�C� �@y��Vwo��[H*�"�P�ٞ�X����w����|��w�X���F��X�����[���.��H�D�� �R��G��;1%�7-���\�$nϲs�Ќd�!�'�h��������f<J&��&Mot��9�A�܀���j�TzF��8��0׿	�q>�ii	
�����sns �u
a�O/̽�)u�`?W*���]�����M�����(�p���q,�	���;j�Eo}{�M¦Jם_ttxEI�x0Y�&~N���:���ZJ��|��2S���:�%�[zK��&�GG&�ՇC;+��l�}�tt�~-E�m�|*��]��Cɵ������D<b�[���t�_�_���u��j�V���R/� �5�*��>�EG'<���R�ĉ�+�A�7fRϧe,�xz&�/Z���ƛb��ݓ�w�`�}�C��H�?b��R��A}73�/��9>���[��9�8�1��Y�}�&4��o�,�O֭y˪?��R�~�kP��aWS	�4�����ւ�lR���������Hg���hw�����}�����q��o����Z,�,(@�W)@K5���q? ���X�۷U���@�N�x:��|�r�M�������������(+�' [-o�Z���C�-ޫG�|d ֆ��3�@�Ph[b�a�k��+ą�Z&����_�w���QY�}�q
=���PO�}/v�	:�u���S��Y��n>���JgY}�,�>�F2�͑� �u�6���&dH���8�&�����Kh���;ֲ���ȿ��Ȱ?Y�p����E�lϸm�w���X~B����;���k�B�N�Ck�y� p����wf�"�T�`2~���]|uxh��:�3�aM_ai ��K���1������SÇ���^��Z�1&�:.}��Q}���A��z�F
gz��!{���V��Tv���dD�l���ӫk�����P����$��z5�Ǽ
��v��	��������@��I7�'"c���fnx�-�d�p|��<)�����݋yE6t}�f����O�iBh��dd�7�6v�(
�m��|��3G�1�W���	e��k��u,=��h��Q�:������l�W�1)�Ӆ�.j� ���""��:�?6i[�ܱA�2�g�}��O���:nGx̭��s������n��9����=Ƀ��f�KAK��;�L�<����7ӂ��p����Rp������0u�����_�אl(������a[]�9��i���HG���:̀��Է�f�Y�k�C|aBw��o��7�,�`��B����F	L�����/+=[7�vr�=bA��h��͍,S&4��Y^(�}Qk�O��D"o�N��^����x�q��>�poޤ���G��*J؀�㒒��C�Ժ��.-�1H���O(�9>%1������w/Ism�a�H|�̜���p�W�E�πD@��-Xrl9����2�x X�S�?h#�$�Y�E��^�u=rs�
 Œ2SW �*Z�ݾ����Eo�	�q!�C��dj(������ m,u����,0{��e�s!��>�G�Ҹ�Ｘ1f�v��ސ'�����R���
��#�!CĀvL���R���ޏ#E�D ���`
L���x޷�]?VGyT�><J0�>����B�4(��vDu6�I_EJ���U�KZ�k6��N������X2�|�R��"<̎Fڂ�{ֿ���4�؁x����N\F%>G;�%�=:�M��;����˞����0�|ŤSA��CL���������-�k��QL+�ʗU�p��#���h�ַ�:��n�/!�h�h��B#����S\U?Љ���@}=���J`V���0�"б1BqH�?���(���~��	jt�q5p׽�J�Q��	�>{�g4?���mؘ�q;ſ/�=��u�9���j��}�rӸ���b5<�)%Nn�go�=}��0QA��p�0+HR�赾�5G���13P���-$5��'��&./�.��Ǯ��@�X��M�Z%��]\*�ť�.:�[�(֘���0��n�}sh�*��r,��7���ع���_��>qKl�&���R����j�Tύ5��Z� �\���[�hE�(�fVO�Ͷ��M��^G��-HTұA�ޠ#AOa�.���%�aw�`y{drP.�R\p*q�s_
0�pvwm[��N�.��#F/(_#bz�6�m$
�q�i����I�	����@bN�8�`��ML@ϝ����N���|`;L��<�qb%�?G�E�2)��p��M1-�9��2'��`��	���1'Y�i��\z�':�fև/+$;,�u�@p�!1������Zr�S�K���m�Y]�O���["٩�m��e1������>V���m�,�e�3#��$�-��4�hj�� �X����.&���R��� ��2���.���."Le)w��
A�������>`�<cp:��>�.=)����b*�ڀ��z(��^Áp��`�;cz*ƀ�<��0\��=}U����sfఢ߉�{k��<����m�~��j\F���!m�2Rխ7�-���g����7Ll�p��.k3p�R��5�������o0CM"��1l�����)�kZ�A���`�p�l'5ˏ�3b	V̾�H:1k�]�MR�����gws��q�#2�8��Ğ���p[���9س\��������kz���T�Ԯ����������[�	��>� ��V�hT��X�;.��a�� D'�u��.�q6L�"V��9�T0�A����4��B8����-�����@J�Q_ߒ��FY����=	W�z���J���I�_�:�biV�2鍉B݂�t�I@6���M+A浚�-C�nۜ_��`aSZ`:�l��-��s%�|��Н��dU:��>���G�#��?)XШ\*��+�M]IWW%UW���~al8q�<��1ba�X���nJ1c�I��(��ޫQ�L�����'k��V�\���M��u)6r!��cԧw]4�.x��F&~s�iE�mھ��T�:"� ��u�9������eܳ��R��=��J{�XZ�<�����ҺR ueet�e|��DO�z`7l5)FM��z}��e�W��O9T׬��U����g[�Ȼ�tj{ﵬ� 7C8�Á;w���鋼�rm�"�·��9۩c����4���V����.ўI�wE�}�?<@�S�?�� �U���v�0޼�B���>|>���Ox��}�%]���7Z聼c���Z��ڱۘZ��V�B����%��E6%3�2�
�O�2{���q��������d	r�b����HY���0L7w��<]�p0
���1Z)�����՝�Q�dki�	;�"́aj�QO~_x���z����	���~�K2��'��w|>��ps+c�B�5,��oóV��gw�61Y@���+�/q��h=�����'�z6 �tv�]��e�>�2��5�,	�}����6��Њ��v�s며��ۤ�.���=%x雃�vP���o�i@�0 ȉ�$�!�R���mD�Y/�G�v6N�>.���J�P�8?���{_�<�ALØQ�.��2��,��vxۻ�2��V�x�
m9�vH���=?~Z�4�C��^����0p�t��W�`���������u�`��l�=[��2p`Q�n�G��K�_f�~#�!1'Xp�bN�4LU�~V�֙�!m`#���'Y>�!���K#Z_o�W9Y�,�)Mu�"%ڨNXOm{�N`�&���LF��@1䵄���sm�|�c�G	����X�������A�������u��l���?���w�C1t�{��v@Õ �A�4�2U�i8�+婿�R�%�-�v�(�"6n��p���O���wU�*���}K �;*���h8���{n�ATF���j}m�f�V�-8�?#���M�k�����x��Vx�����\�E��\ߤ�(�2�} 4U��jo-����Q���X��S�@_'���9�6�a �Q6�j��G8Ϛfq���@���EY�`����{vs�)@0���G9x�������#w{o[l�������|��mD7t�y�V��f����%�߄�=����y.CWm2ϻ������1V$G�א��v3P@�;�4��h�.s���]��BW?��P� ��ǧ}���3P�6��Y�,�a�ڏ�]�� �vx��L�\#v��/j;��o����;����("�){u Q���h�=?�1#����G�|x(�TEȝ�3GC��c��-U����	�'"Ǩ�xܢb�"�T�����wα
�E8����9��:���������Y�kQv�u���5�◹x��^	�?�T�
�-����}�4j�4�"�P������}K���u��K�ԥ�E�4#�Ui
�W@�0>�x��x�1G�'V��'�i0�'mf�Ў$���;���n.�/稑%B��tf��6� ��`��!ʝ�?�o�s��f����!�v8뀩�*І��A ����⎋�g-�ԯS��������8z�ˬ/3��nN+�a�|�,j@}MК\�dxʘK:'������RF`̴=Bi��X*w�W�k�5�9���(�kӐx9���U>e�ז:��4��o�� ��Vܫwڻ
�,�&qgQ�t^����ʔ���~�$���&O.�Z�j'Q��7ZCk�����Ӥ&�[�����V��v|�N���h���r@}�K�[�y&�ך���`ʖ�OE�3N�{Eb�i*��Z�Rѝ��8��9t˜��#��ET�?1{UX�u%!u)'�����B��,#j�/�ю����5���!,Î��[#��}�� ��s�K�)�7o	޺,�e�}Az��� bx5HW)C�g�^�	�(�q*��Т]�UL���0�i����ߴx*h��R��(h0��=�.�^MD�����xy��5씦�l����S?(O.�j��A�%_v���VwH�b�`����j�Sa6��'�FR���s%�|�&�@��N�,a�Vpw�i�߸I�C�J6	����ET|)� ��s��#s^J���7�x�뚕��Z������<TZ ��`�TaP��.j!�x�:�R&7�+۹�)��19�%!:#��ur���/�s�c���u@�
B�ov���]��x� S��	9cB?����DUL� �x��6�J.u�N�;��Q1q�-M!D�>`�'���u���q�D��~���x��C+Y�2&��,A�F6U�cI�be��b0��q�:*�b���M���rq*�������0�����!�w����{��N�'+�!�u_�� ��sS��L%�H/�T2	�E���\!��c����GF��y����7 U{Q�S��1/�^4����-~0�_��e���yܴ�d��FsD6M�N�_b2W�;ρ�9���%�PT���q�PoFj��*Y��©���6d�z��W�K��i�kM����Z��Q���^N�XE��1�M��t#r2�;�&	@B������L.�TR���@�KA9ga�;SS�o	�/A(����9�g� U@�Z�&Jߊ�5���"&!L:�I�J��QP��w{ޑ��#�z���("A[<33���H�%����o�*�x"�M*����˟��n���⛦�Z��Š:���"z+(�][>�£�5����_��]P���n��
H���ioyv+�0 \ �g��4��w��U�N1��	@?\%��1\�#�t�}�����7�yFAhF��+�������6�b�u\�����Kv��D�����^���h�v!H�+��|i��zf�J��U`�e���ު@QE��)�o]��ס&�;�c��V,Gʒy$�����4�aJ{v�TD��4c3��M���"�@�+���uX��\{U �<@�:@�l�9�5���u��H�9��޿�<�MFc*��yB��s)"� �o*|�bO����D����\������XY���4fv}��� �֗d2=��6t8閤��@�o����I�������������'��x"!'Dp�Om�4?c�Ͷtт����2�J

o��hS��nc&{�j^��[x�y0X���LV�y��٨�8��u��2AÒȳ�)������ٌ����ػ�"��ޱ>�i��о/\hJ:�$24!̍%0|v�\��`e\�+����ݠ��w�M��ݮY����X��y���
��S���m�
���+�n���GG��4l�́Lf��J��n�X���������D���4j>�Y~��Z^+�L�>(�h���o�,���;m	����� ���83���UW�[��y�3Q��JS����\p�y��J�4f�A(ַL�q������J[�� ������O��v�էL�m|��7�Q���#���BW{׀u�a(���2T��F	�"��;�]�c=P�.��8�Q&�o�O��Gܻk����%�%���畣���p�7�?:��y�gT��弶Π�Ab,��2g�Y:?3�-M���	m�'F܁����l���zW����JRu� ��s��_B�yoqr�R��C(<�"֤�A��6f��nf�2.� 	�z�펱��u���������]Lm�\�b���u��~�E���e�{���t�.i`I��/�3�8���b��M�T.rI$�T�!� �a/���hE�W.8,�'ٞ.����Ҫ�i�A��y���M�@�`��� ̏�u�k
5�CQ��dg?|��`�"�2Iq�����gu)���*�˜���/�8����\"6J��,�����U��~)����U
VHd}L_p�2��u�Ɣ?��'�'���=��TE;n�v\w�M�w^�l�%|=�8���;ږ�������*g���FM�U��ϕ-Is�tw���1����_T`�rlivT�8uc'xHn���7?W.I�|�.=|� ���zo���Z��y������O��i���S���Z4��t�:i-PG���(�н��O~��\��d1 �&w)�}�����%*ܽF��Ua�	��3�@CiLed�i�P4S��_Y�]�T�a�+�f��4�W�&U\ن9��cp�g3y��{�=-�0g��|���0�������x��$(���y~R
�b�	��ʊ@���ƼF��Z39ᐊ�Ħpa&_�V>�g��v���«��ru�����S��$��C�D.��b�EAq[�0�E]��-��,}�����ّ0T��A� �=,��$����$ �m����� `�}I�5�F�bou$�$�U.�S2�ި8WZ��Q4ns5Xj�&2)t	��!hUX;%�Y�������Ӕ=�.�4�[�D��{�/
gT�HU�έ��1�����Qyrq�df����J�!(��.ޤ3�7� �'��A�Y��>��������G��^@`�;�؂ӛ3�Jr�S��4tj�_��4DKZ%*>?���CeP�}i��!�"'u1�8)Jr2��܁�ٱԌ�d̙Ha�ZJ����&=�⊲�tu߅��o�0+An�N��vt��a��<9I�ʠ���.��R}i''r��O*v�@��ӥб�Ns��aۚ%���(w2+�H���$���I�/��>�(����;�d*�ɔ�	ֳ����]h�"-����'�y����SΙ��Bp�\!�b� C���j�ܕմ���7���J��M]��]0¦�\�Yx���a��~��Q�'��������sɱ���h�a�I�u;(�i�m))
;x���GD:jI_9�	�(��:�FY�_��@�Es��(�p��KN���j,����Xz�n��:bR�>���:����������u�mJ��Bj)5�Bs�qŘ��-��w�Z
E&�q�72�JyN)i�DߕG��(Q��hB�6���9�r�gO��B��!o)m���}Q�E���]�E�h��u5M��֓|e|�������	��@��g̾����@r���Bt{����o�:���Y��k(�t���Z�[�`���=W:�3�t��p{LU��LW`��O8�5ƀB�k�����x���k�zvO43 ���,e�1y���w������{����+���"`2:�}&�y�ݐf�=BLz3��#���쾋E����vf�`������k��4���	h�H"<e���-�R� �"c`�+���HTA�ᡒ��'���;s��,
��4�	�:����a�8��0C7��V�Wf�l�!��l}B
U�O1_0% ��wE���{I�4-���<5e{07[�� .+-zw'LĆ3$��=����A��Bg���������Վ�*ns+� ���>��c�#�,�2���6^^5�}4J��u��t��.�m����n��w�c}p;	¥�����yb����Pihs�ϕd�ϳK[�}@�]��zub�=�I����s��~�%�	�u{�[=G�,�7�E�`J��?m�����2���%3:��EL&(�DMN�ka�gy�99B-b%�]ƚ���)y	�-2�������CS�7���3U��Y�Vg'�^Qu"�Uz�H~��1��a��k�;�m�tq�Q�zusL7 �E`@��ju=G����N���j�U��q������X��#�Ǻ_1��v�0
U8� ��w2$}Qc��v�=�2��6�,�x�ߋy�C0v��ṆB:�[b����
��1�b�4�|8%�-I����̹�O]�!D3��5μqS�����L���[	�E��쏒�;�� +�R�Hp���/ۯ�R�R�/7����>��H��o���BVd���S�ЗpeF�	h�Y��/b��,�����>zuO�~́�..�h;���G���j��qM�|%�]���A��X[7�Q��������ɥ�`� 
��g����=:�/�:��(o�3����� 0�[�Ȉ��W(�n�|����Q8�����F�r���
���pb�+�$Ԇ��Y$�I��ĝ)-O��U�!�UO
E����5� ,�FR�&tR�k�ÖhCPW!�*~�%Ndd��Y5b�nqcJ%c�+�B�ڑ�?SU�T/���s�� ��R�]N��� ��� ��8NV3��L���H���0�e,6re4x.�ɜѨ�]K�
x��W����Z :��7��vR��r83h[F�����;8�! �sޱ3|�M�o���`μ���FY4����l"�Z��фF���`���:3���NH���4W�ꖨf�{C��l����-�#<ߣ�\Y�²35���S$�"�9�dN�ɥX�3"��z��1v����Y��H���i��%���o�ԓ�GF��hI�:���UH� �*��������TԹ����Ǵ.9�sk�&z/�H�ΰIW�4�}�l:Q��?_�8�й���t��nA�
��7A��U�+��<�W�Pm�o4=����m����_M�H1��cfǢP�k�AQ�XJ�1k*�ի�$���w�_ީ�3��>65!H����46�^���o���@؀>��9Ó��a?�z�n��Y�˙��ۜ�z��������	���O	��ٰ*�����1�wQ�6S�5y�-�ȍX�]i��2hT���"`���)T�9��G��"�-5ǈ�B)d/���7��"��Y'��@��-�=O\����o�EY��DS>1�*�k!,�SJ�d���@v��������n%)�v�]q���8�٩��@��o�BgX{�]�Ɉ�z�Z-8�y������1�l��&�6$�ۃ/3F8R\�R�ẉ	[y�?�b��gfvU���������n4��"����5}��f�6mZB*�,<O�	V9l��5�EyY�����HQ'��O�Qk��B�t�8Y���x���(��<���}�h1���0�K��Y�4
�̧4��^�l|���I]G�{k2B�Lo(�k�<6>�	[���}h��e'WЇ�p�?�f^P=�xs�f��>� �v�\�.�.��abë6s����2�M���GUF3?z����Ì�g�C�����_2�=�??�m"��;�?:4��Y�Y�r�t�S��;���x7.�p6:���Pn;9v�hFIؑ��5���M�ELk:7������Ɓ/�
.\��Y��/Ϙ��_�vG[h���깤��	/���U$�'w���;K��D��s{G�o������x�/+�Q�	&.�R��±S/)?*^�P"N��d���	�A�ho��H�_,��!x��,`��N�x�����H��>[/ƾ���5�[�&��Y4%FEa��}BJ-���I/�;ֽ���9+T_<�!�4/�#���H���!�k�9��䁞�/<7񞲜>DR�,�"c��%��&��l<ߝ��9b2uF��C��Gb�WAI%���(��,v«���Ԭj�d���_���l�n�I,�_ꮞ�~��P���'[�J\ԩ{f���X+;�a���Qo��|��� :B���4,�.tp��
jr�D	o]�@ �e��l�J�%�ę��Q�
��_k�:������i�C�0����,�M9.��fw�VX�#+Gc�( 47��O��{���d�-ĉ�PԊ��`�i��a��h ���5�|,l��Q�����%U�=����߻r��:12BJad3pi�7e�ߜ�?���4�˚_�"�*;x(g|�TV�p��ȎQU؃��̫�9�]��PjL���B]CX5�O�Ó-��Iz<�����D�^Nj��Dc��#��l7����%��OV�J	�<���>��U:����J�a��<��`,���N��v�f�r/>���ˣ�{[���?v����$h�0*�f��+���Q�E�"��k(lK�NɃ�+q���^����kQ���{Ͻ_q_�\>0��3���}��/�S�B�MJ^�H�5W4`�����R~=�?!v�䡰�|�,su��A�k���������)��/UόnA��� ��0���ҖF|�ˆ�#.��l�/�'��ӬP�B�U߼���2ҭ3�l�,MΡ�DvX�/H��zt�8��F�9bZu�UcR�7aòPZ��``�F���Dv�Co$L�����cu�F��j��K�����Nʾݸ�-��x��0ը퐳6��IP/�L2��S�P&��0�:��S ����-Et�Q���L��YF�SY[{į/�O@3�j5mX��D�#!�f�0��$�����}�ۯ@��w���P�/�:]�	2&/<��?0�}~V+�bG�.p���x�9;FSkA�_���y���qcYB�ұ���X�f��	�0��Z��)�^����x����`�@��z���U¿=�`!DK7��K���[]`Z�Yh$m���]�et9E�Q���S0��P�Wiwl�8���lh[$�M;<��eGo���W��D_��Z�=?�GT��'9k3���j>��������sA�k���/�UaZN|�-�kSAN�W�
�Y��xbW����Hg%��cĦj��4=��
aN��U"j��~��ˈ�$D0������"wAB���Vk-ڼ@�<69p���]K<��}�)>��0��5F^W���#�u�۾7���D�rv����IN���1S�};�=,'�-��v�ñ&�������X�1hd6�C<,�[��3����+9��������r(�g�d��z]�fKnN�A�(��R=���u�R�>n���\֙�W�`y�IH=QҎ��\���)�e��"z*�r��#v"7=+F���`Q���|+#�Z�-��Px%�!���+��� ��͗	`5ס1?��z"y3���}!���@�h>}@��uZ�2�q��gƭi��E��r�S��8(Aq�

`н3��g�y
DTd^���7 B4�^�\ M��A-��LnPy��P�LkkX����o�t
[ZdjA�.��M&�Ѳ��=ڌ�R�q�d~ ��h��߂�ywPB����'rm�
� �������hI���5WL�!������u@���!�O�Ť7�@��7~��W�V�M8�4���]�"��������#�	4�-�=����͞q����Б�-���ѻ��ko�Â��bl�h��H���YFT:�x�0�>1��s�p������T��:�z=���+�G�İ��&���6�� rL�e�n]���O�E���y�}�,�(�q���5�t���>�@��>{������@5����Q���嚹zEkUdYOV_� I�ށ��-M`C,Q�T'P��O��<��w�w��5'�$�GX�:Z.����BU(�i/Dz?��Mf���FՌ�[]P �l�������k�ۂ����Z�T��y\+�-����L1��ﯩ���o��6����ɕ�=h�1�M'�5R	�flB�����j�t�� �rG3�	\�q"�=PJc�����j�<���.�M�R^Q����|��%�X ȫbdk`�V��7�� ���?�N��E�d��.����q�]�;=sJG�3�V��lF�Ce�T���#�Thz�@|� i-��k���>E���GAK #�t�ś��W ��D�p��t,�s}Q6��:���.�%��R�]_ok��M����r(�oo
;�0���+2������R�>Vz䣼��E�C=ͧ2��*������0uk�'��$���/D���n�5gQE۞�3:���A�����Z}�?���0$L�폪������Y�Q�Kh2��E�٭��*αC�p����g����{���ڮ+���H$�Г��U��bNyT~'%*�����z�m���<
������R�r@#�7U{#C�(���0�Nws�����P&&K�7��]�� a��R"	�I��y���{>�FTo�R���3vѽ�����[d+�Gg�z �g��~7,�D�0k�v���.���!YX��-��s���͏x�j/;t0]�����@�D����c�6���e���$+޷;����\c����v@�_0 �r���nd�w]^�^1 :��*�&�%�y����F��T��?�U�{�����@�]�2d�MԌ��N�r\�M�#r�x3'F��ϩ�n[����4�����Tb�e�@�����hr�Ke#��u��l3g(c!U?�����l{�{�ϖ11h���<*� B������SV=�pZL����ZzM�PQ�x�F.<���y���6�%?�ؗ�Wb��9v{����;�J�Z0d�n�1F7���89����r3�L�Ak$������#=Ҙ]�L��g�f��x#�� |vO�����F�IÁ���@�5���#^��u5с�����T�L�0��J����J�TE�b]Fdf
`�E��kNa�<���9O�~��/]�`m�����{ �u��54z��'���3�Bc�.��S�`�z\_�qb^Qc˦괈P�JD�)G`���ȟy棕ЃEM�r%Z�UH�u��4�]+Ah��2ɒ�A$���T֑�-�^��D�E����4x�B�4*�j��#�D9C4N7Ȥ�6�pg�-*���j@�G��(�ZU�`���r�h�c�����ۉ�{?I�g����%l�效�����b��r1_�'7=�q��^�;�K��O��z��`�i�Һ�έ����q�8�n���)�;��<,'�e哳	����4���W���$�����s\kD.�t<u���!O��F@;7�VK�Cd��gPT�G-��/6������g�I>O������qA���,Φ8{�as�bS��J�9g��M&}�:���e�)�H޽�����ӏW`b�J���*K k�:�/��H�k�����{>R���@S2�� 
PÉ��Qg��h+G�	��XqElLL�#p�c�>P�>���A|2�ȹ;�r\#���X�D?�EB�M�z��ؾ���nBV�'�;�\F��K��\I<ZO:sxC+�~	�I�y���]��9Lj�#Evu�%�)�R
.���G<ސy`�2t�(�5��K�T��M��:X�"�
�p8�s�.�=�D%��c�xe� ���7��R5�b�2t<Qp�^�w�̜7�M���M�<�n/�bb��A�?}�LJn���m �]LD�=�ɰ�O���o�i3w�"|h99pUįA�]1�M�q���%"ڿ��)`����#dR�!Da��Zl-��)�O�읳�
mt/+���:��L������p�F�|�  �J���B�AaX�*��<�D�&C�<����a�[ ˁN������3w'X����OD� ;Ĝ�	d�\\@�KmP����%�Nf3f&ђ0l���B[��ZّҪ�|��Ç���!hd�I� �ڙdW*�ƁR�@���K�_���������&�f�Cól��<�|�H3�4�bb$�[>zN5 y�e\T?I��t���~�+G�Eƿ������:	�ż{;g�`�9�r�)6N��K�gmDt���xim������_k�u�v��/����#��I���Ja�nh.A�]��N������\~\��{�ۇjl�G�D,�l���$���|��>��
@��S����d��:'faN\qOe�CrC��֝6׆�6=��cE��z(����N��5�?F2�">�� �2���y�(��<@�E���⚒x<�o�cSP�k-�a�36�`��=kT���\�5	ٟQ �5���"E�wX�]�20JnY�$	�V_C��<��b^>�iQ���黜V�x?�+�XET���#5�"5L�E�{�����^��]K�����'l�%m�CD��O���5�����*��Q[J��W��0Y��F���@O� ca�)��<�� �j*�l��r����~gB�K�"��q#y �2~p�[�Qq1:���w�cl{=�-��j"
���c���c�
F�t�����LZ���?�Q���|�^A/����`s<�}�㾶��^CuQ���5�����
�۾E��\��+�ccoV��@`;���evF�:=E��0ҿi�t��V���8��� �΄dn�J��w�;��0�4�3�K'P�19|�����=:z}��֗q�\uK�?Bo� � .�T�Wp��y���_ZJ��4j�%��g��l�7!%X(�$����ԡ���+��fj�q����1̣
%�PU/���#mk cxlx��T"��˧��J�?�>A�m��H�N�_�`��p/���Ҡ�V��x�:��6�s �KS����Gpi���?R�F�v[�R=�^L��9<��\�Ib��D���V�a\r,�d<r6
=�?w|"ѓ}9P(�FY!k�O�&;���E�iP�s3�����D���;�P2x��&p�(�[���XX�օB�7$��-��.�J�W9L��󳄺4}�}�y�Zb����X������#�(��6,�����)��ud�kBf S��� B1�$�!dm���Ȗ�a�CI��<p�1bWI}��R����\(\�m���c���rjI���N����V=)�$��ٯY�
*�k��e�5���8|8��*����n�~�{��1��0�@�6ڙW��
H�<UI�ɰ{Ki���b���Op]Lc����\޷{gN'Y������v�U�U��~oxI�1<��a�)�luu�Z�`������%��g��5�A�f�*s������?�Y��9�
�vz�\��P�{���l=�^TԢ��S��fF�1"����խ!*	\E��&�z��*�O�da/����&P+eI(��J��9�DE:p'r�!Р#jG�����Q�/��<�wz	�O�݋#����ߡ:?���F�h��[6�}��6!�ay"V Q�����Zzc�N�w�J���ĕ�وvؿ�oD�P�����K7N%�M��T��u�;���N���L�A1��ysʻ��f�3R����{�tz}�����癒�o7����NsP_G)*Ш��]*�t��"�Eն=K�߈�fʴiȬ�ް�G��&���R̟����z����TK��Yq=���SP�s��S�8ٹa�su���/҂�f�357��I)8L	�J�����F��b0�M�gp������bM�3!�e{A��L\!�=gu�� \;�Ol�&�mfo��G�d^�h����ϙR��?�kɤd߈�~�@���l��$���@ �Ǉ��
:�w�Ӂ��_�XP
Ƭ�;�D���ʇ=[Ϙ:q������W�
�ӎ�rA*�+7s��	�LI��N��/�����YE�w��г�:k �T��&0v���T��$�\!��)�䊾��Q1G�/W�UW��է\�"5�~v��˲J�$C����j/a,���Xb6��|�v��8�j�+�m���
�%�>�z�
�G�2�1Dw����/hr���a� ���y�Kts�X���U���#y�Ӌp���EbO��x�Ho���lQ���	�
��n|#����U����B/�	�EyvFݜ��n���m0�y,���fb�ۏ3>s$i���<LJD	����v��%�5�v�(�F�;��.�ɥ����2�����T�����"�w��,�w�_�QE�]K�|j��W�`��Rk6�ϩy��)$������+���8J��L���j�^�������n��� ��@��o��2�;�E)\B�6���E�߹�g�P�n�����&tra�OqhA]yJ����x"��-E��t�+�}���g�@�e�c�e�\�S����{�2�a>��%}�O�
 }nS�R�� ߎ9�a|����	G�1�J��p}�=��Y�/˛$��~�.��Ka���Z,)���������4l�2������q���N��#�������Ոt��X��F3��*�Hw�l�V��Ë��n$C@���=G�HV��r]��Q�K+��GQ�%�Ec�6S)O�NL+N�:�6wb{v`ԝ�ԸY�����U+Є�2�źY�����[zK��~L���eˑ9b�d�@�x8�������b�ҙ0c*M�Ӛ��R�������c�'��}�xA[�����C�Ly�� ��Τ�����#D�J�*! U�|^�2��e�·��
c�9��RZ�j�b�a��%��k����Y�,:Y�:�R�2�
ޱ�	z����Ø
x�W�^�@�'���~T��U��s����[���c�~6��9�*b<�x2opcU��qc��1��?�(k�u�ܲL��k������i��X1�?\�N�'�5׽� 4���B�n����c�H8�&B���YO�p�D���ګ��tT^Z�W��A�_c�uf��l�C]{1'�l�dgk<�0�\w�j՛�~U��{;pp�i�oHSv.��J��R_�;�3e��t��9�F=����ט��CXf͟�(k����*@����Isc��.y�|��u�:>��.�t�l�E���m�G�3��q3�]l�ѸuI�\��.?�9����u������9�>�K��NB�{,\���=f�a��o��@~|����~�g�-��EG�A&�~_���K��T��3�R�,�F�W�yz�S$-9�-4{�n��2qy��h�H1e�P��-�8���?�Ey0���w��z�=�Vif<�R�C�<�C ����D{��R%�������O���Ϲ��(���ׄ�LR� �pQ�bյOK�h����������)���z����/vo%�/K톞��#�V�T��g��6zG�x������� �C"Ls9�[� ������#�����d�xT�u^G�W�~R�w���Jx�bn�ϭ���3w��f��d�� ��8�ti�BA�z�(Ng�OX�{�g2(h�Ō���s\&���������y�z�°�Gxg�I���@x�C�Xu1[��Z�18�L�EZ޾��!��,�ʂj�r|FS��t>��>����S��k�� 0o��Q�VHtn���]ƙ4�+fe�����`�֌j�mv��WW������ʸl����UF�J<{Ʊh�ϖez/�Ĝ*�d 2��V����#Lķg�ȓ��	w���bZ�9�@n����Ų�keh�-=�K�M���6?sb��y�1*��*�S���]�=���ٛ4�uX�oI)����X�z�����/�Fͥ"��j*�|X&ua�bY�E/' �@�Ht��+/r�Ѝ�C�Ϗ�97yy��v�@��Uz��o#���l����4�E�P�N��'}R���F�o����v�g�6&�c}�lKm����\� YӣT�ts�>v�& ����������=�����3�؛ʦ�����<O��k$�-Dr0���X泺��W8��A��vpïiZN�ޠYjg���U}�nE��_�a��Gq�{����
M�_=�d�/5qm���ę!-9��O��C}9�i�eB�܍�$������V�Q��\�Ğ먤���ɻ�RiȐ!��f�@V-�r�����*-^�)�n�|���PYL��>��
�&��\*�f�N�O��)Q�4HD�����>ҏ-j��!�3C='g��v奬��J����ʐ�/Iu�tz�Ԃ�f�� $z�/mq��ZQ0H�� �6:����<�`�6<��{{W�E��n�w��`p�w�u�:��3_��x�[�fS�z�2�u��¥6�L��J#A9��~�~���o@:gU�0\;È~��{-e��P�h��d������-I����KAV�}�A��Ѝ�
��o�ֽ>�P������i����%SZ"	3E-��Q0�y[I�҂?r����<w<%�x����e^i��^6*;�$��0&��Chc"~�4�FN��fT������+��ҏʘ����1�L�{\}W��1���Pc26l(ZbU^O��7��;���D0D����ů#ZRm��ʌ�F�����OD�C+ �#i�t�	��z Jn�Z)�e"-H!�mٌ0��9!|���z/�F=�}�R�u-�P�-l0.�ת���Iy�o�B�@�=E���jl�̭>���W,zC�9l1���tؚkjb�&�0�b�<�5�g��DOB3�%b9�D2�&�;�B2R�][Xf��%�c�M����[t����i��@I�8��O��`����N�2,�+����BZ�rzI'(M�v�a~�D{�|g�lffw�U�P��������+��m�X�q,�<H��d�m{$io�Tٺ����.Qv˽]�dNIQ���۽��>9/��ۚV�2�x��z��&N�.�[/ODՂ�"ǇcS�#
���	:�qx�j���Dc���^'p�:��}�����c�2.Izt	�[HjX��f���ث�c�'ן��w�Cc��S�P	f�ޒ�
R}e=�LY��I)Ʀu��t%�	��?��-Ǫ� x�I�Io��6g4���%��%@2�)�R��uo�I�_	 fkQ^�x�'�5n�pea�^?\D]8����9Wr�9�Χ��Na�8�i��t]���!VF�w:N�gR�-t�Ѿ�ݼ� ����5�7�Xh��x�Neu��u�cI8���F*��*�<Vԃ�"�Y��yu��-a�<�xk�(��p�M�FDq3Òy#���yhǘ�k�FS���>M��{d�?�]�sp��Q?���Ee��-��j�%�W����-MH�ܕ�Tcg2��n-��%�هLj74��=R�N���o	(Zh�#�x��ssO���ٮ�  ���'*��T�V�K����j/�{��V�W��p.�t�E��"���v��A�l:�Q))�%aNQ�ѡW��Y���GV�<��4I�)�d��7���_�C ��2:�����T}�}�~fb}��#�U������=1u"�dz�k�.�!B�H���H�&���J@`�L�-R!$+}���mj�]��mU�����m]����F��&Ŗ��6$�c�퐱�`N�K=�y�Dq��B�\g&�	��@�(�}<�]-萀Y/~��VAQ���?�r�����:����p���1)ډ���(5Ã�M���cg6�3���7��*9\�Sz1�()]�����*lFW\v��@���n3���(uh��s��LN�jw�g>�d�:T6eo�"�#�6�2����rEI,ք�ja�D�"��Z4qt\/�j3B�&A?���p����p��F0�p�r �~��|�QU�L!���W��z=U.#r"�ζ"	�S�nP,(��xB W��ﭮ��'�qR���ȔIvb�³����vY��谿>l�Q����Wq��;0��ڼ�dn���e��8�f��ZQ�+J�~Z�$U�c�a��lă�m�.�`��bC�u��r���P�Y�yi�v��=SV�\��� :��s�$�F�m <l�!ZڒN�=g�5�'�+Ƴmp�1�]Ƣ&I�B��&]�&\���:	�]쭆�׫v����.�RJ��z�"&���<������e��ƗpʷjŨ����!9K��&�SHg��.���oTd�O����⳱i���֎TA�u�l�h�	�^p:=ktK���a�)��6m2ٳ��S��|�.����Z�
P�^֮��U�Xz~e����[v���!���R䴞��+e4�*�[$O�Q�����uto�Y���r�<r�ن�CY{_ݢ<��4[EQ#	�v7D�����m��M1G��9?^��(�Gy�ߺfU!L�G�ȼ��C���kI��@����v+��'����n��c�މ�p���x�    b��e|��� �����P�j��g�    YZ