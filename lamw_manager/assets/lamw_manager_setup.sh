#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3750117793"
MD5="cf2d9d37d381182ab901c49d09e55de8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20812"
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
	echo Date of packaging: Mon Nov 23 02:31:05 -03 2020
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
�7zXZ  �ִF !   �X���Q] �}��1Dd]����P�t�AՇ8[K�S�53N�,��{��=�1-4BC�(�ii�l��
e�J�E�u;j�AhĄ���=%����~�》z�(� ����f旬���c�J�R��%���r��}�����
�ʡ�푉�,�#�u�S޹,Ԝl�L�@,5�q�I��l\P��;�3�a�H���7�?F��<��t��r���:����rd��*�
$5(0db�_S��z���KzZ��e�9?K�d����z��6_a"�GAi�1/�?1�3_ʧG�Gt>%�@�42�cG��*�m.c���Ob���Af���W���I����U��$G�d�h�)�=
�� }�$���"�i�jp�0\|~�싐ǩ$&6�_�ڪ������C�G|���a걖���u?��1~�$f=3�\.0ω{�Ռw�ex��޸�ҹA�2�0J������:�����Y�6=�]9;I:����%�� �on�b:T�u��U���}"\�Pi������Y9�E�f�>��@���W�ztE�1�%{�n������XqkVU�Ҫ��͚�q_���D�c�f�^��e7��^�L�W'c�%Ń�Z����
��H+�M�Gko�7&�����3�_o�\�n;ԍ،�WK:i�n������ච���AyA����E�~�c��ng�I��|�v5��qJ�y��>==��vi嚹"����[_���(�k�c��b@��:
����qB� ��,�#4!�5t����և�0�K2�}�Q��b�P)
� Z~�9Z���	�wcLK:
��ś��S��Ŏ�����j�@�����5��^Z���
���v�>��W�+33��/#�Ye�,�2�H����z������}ݹ[�pR��{y��ډ�
KF�eU��)�9$��5�'3��j)�F�Yv�No������Gkc���D�Sh������a����Xv ���0_ M�(=��Li��Lm�5v���I��k�r����S^�`RT�4�x'��Ԍg�?�&��������X��4�
k'-"�'V�}Y����B�V�j� )�+n�U�uF�� #�&��'��T�N�� ��M��j��<z3 C�<����Nݞr�/4�є�K����
���ɲ��?%ٚ�����^���+���W�GҸ�����ܠ#�]�l`+"��\Y�������咹!􇶜2i k�RD�&����7��v��ʓ�j~K�r�0�ȓ4�_�v�?h��\5k���`j&�i�:���<C�I�f��:P۸�۱���Ovձ�O�'O�?7ad`�O��,�0T7X+�:�=Ւ�[=(�1h�0���r��^�,$�olh����.!8<h,^�J�g-���,���X"��i�����%,��]|Q�Q���y}wD�_�Q��)X�Z�p�b�ꬌ�N'!�+m����'�F�R��F)	;��Z XS�s+�5O�6ZS��[��:7ɮ){;�: \����j�?T'���~Ѩ�u�	���&'����2�:�|�;Tk�C�m�l���T8��D�M7r�����M�O�5o[�P�u̴\D\�ﲔ�/?�<�����sb0.,5,�޷�b^��_<%��]�\><6Pj�l.�⠐��D����u4FR��TJ���pO��4��
s�p��P�j&���|�Cx�t�Qo��n���� ���KD3�YH�vΑ�W\�¢ѷDO�D}�?l��e� �TKSE�RhM	I��+�:QB@ �S�ϻ����v�D%PڅX��HE�e���Lz:dL�a�+��4�Թ�ħ�05�B��<æ-��f�M�_�_A-f3�t�*9� '�~Gn�'�Ќ�u�
6}qG��H�laRt;Ӗ��n�.�v��Z��.\��<�3vLR��:>h�R۟�)��3|b�f2���o�C`)��⨜��:��Z��fDnԵo��f��/9F�Ä�9v'���`A�H��.Ք�wJme�m*���܇�t���<�{�5�n�"=,��O����FB�q$�4DdU��Ȫ�{��%��9����zqkE���*��U@�$X���\�Q4��9rGTHkÑ!�vb��X�,[��&o4I��l���n�����ZY��M9�h�>
CJ���zM2y�/=��h�!���Zn�dxC|�h�M���4:_���f�P�C��4u�g�p���z�$|�sM��Q#t1�Jo�L�i� ��@�������)P�ZY�{���t0�b 9eytL��r>�!K�Ԥf_���)} �j*��!�)G�V�wAo�Bm�gұ5�6���kA\E2�v5�jwU����$p����vm	_C#�S\5�m�B�5c8�����:��"XTmK�C�RB?T� b�_��.��O��]�y��s�4���pJ'�+���\j2Q���=���
m$�{v���a������7s��[ā�*�"q�#���)O��:�C?�N��Db�(�
U-�c��G�?N�� CU����9۝�;O�ȇ�d�Iaa.[�[���h�Ո�>�M�0#Vt���� 8��4Qy~)d	K4�J[96j,C��f6���{�}}�"k?M̺�kD�4ʥA�v�KT�r� �%����댃����W ���oEc&��IЉ�z"z�8�U@�eI��HKGr�;G4�.���@�� qI��PJȏ��~��k��ޢ�y�n�Jѓ�����Fΰ�+�+q�wz
�#`T*���72�p�ol��ȯy9(n�rP�-�Uk��h���g�^�,�<����~�@Cb~�]�a$WF��������=���s_).��F�{W��x(���mۗW�O��ތ�Z��{ŉ��j�Ey�/��^�7oC,�����z���6_�݉����OQ �{Lɽx���Rm����3U�,'�����!.��Q�'EA�M���"�_����Ժ8�L)�jU#�����J��7<G a�� u���ñ�U���0�K����,��t���o��Yi-�>�wy��^�>�F�~HŇ*������U�n$�봭%�K��
��cA=
�>�88��m�|�l�_������))Z�Q��B�eP,���;	����W�7��7���k��}��%lX�Q��n�@�b�Eg ^�"1j?,�C:3Sє��}��5ˀb�7ɃyY� b������ً�s�nc���̞K����W&GC${�����h�@�;�#�p�_��Xo�>�޻8�+��������[��Wx�<0�#�tWo�C��O ��*2��� ۋJ���l��A���&}�G���zp�����4\����(&~=o�� �IW'��ŕ���j1K;�d�Q�����<7��0���qX��A����	� }�RGaC���������µ�Nt��Z�����ͮq��B���xèZ'r/N������d4�z�J[Bc�N�?�����B׃�$
�X�B��C:�xHP�^^
�,�� V����?�Q�Pu��Z5*4*�rs�~#Bׁ4�F5��!]$��N�J4f�z<o$�q�?o�S�߈1�{f�} ���Y����Y��p�'ݘո�9�l}V���;}CC?��0z#��ף�3�3;{��C��pV������*B�?��nr{k�ZpsJ�=j���u�rt�����L�`��277�k�-㹼����5^9��j����MeE�P?pn�0�xX0��L��@�+@y����j+���Rx�b <��$�y�	�+]�`5k��˫D�8�]��G��Z�(ڬ��2�d����T�".S0��re@��Ei�ʇk\(�UY�����=7�#Kb�q���)-�75A]A�8��,JJsi�ң�a��
E�z�+��#G⴨Z"l�j�F�|}d�[>YE��F��tLҘ���U8�bP=�����8�����k��A�>-Qb������8�y���)F1h~ˤ�T���ϥ��Oѳ���J�,���Z�����/nꠖ�g���,���3��P� �U���Y<�IN~�:�j�0^�WěL�)����t���)����Byy�b}н��9�v��h�+L��^&�et�lgA��'��pn��?�`�(�Ő�|]I��{�9��=K �Y�F�֭�n՟,��IЖ~����4s�3��� ����9�^��X����{\�E� �㆏�9��b��B6�#��zlݖi^V�f�N�.3������_E#Q��v�>%�D���2:�m{��yqaJ"�qNpnz!GR7�
��&L��w�v|��GSFPA���stC��+3�ID˳A4x\�����$:�聽~t�Q!����F�':f��:U�f�����F�#ix����ބnF��aY��Tz�A�Cw����%zP��c�Z���4�s,�X�HǊZT��h-I��|g��-O ��^�O�]�6�$�mu�x��p([51Rp����a�w�o=�N��~X�wϹa M�=����XB�j�φ' �e�����Z�*��{���jNa�	��/��ޑ늂�{v�O��W��8��1������� zLs���4d��f ���/~+�i�ܱ�_Ӯu��5Z�P#�uMEe�}��*e���S�I\m��p<kY�0�)����t��vP,D�3�X��LsqŅjQh$����E���G���o�DJ��
ӍW�c �\��:��=�$�&���u�5�FN���6Ⲵ��H���5�oJA�(v@2��R�xH�Ng �!�;���\� ��FV��@�AA媿�T����9�5�2IHߘ�������q�{\�̫{RO8TV\����߻�SHO�6�^p=���/v� ��%�g;��-JA��5��.vV����.�
��C�x���p�[�E���g������ǧ��ͥKh��>�e���UN���� ,{�7�7����z��y,~�(K1sV��C��u�P��ҙn�~��o-%��w|`XJ��}{}�҆��w�m��5���QA�E�^�ͮjR�h;��<R;5{�.wZ0P�%&��ܠ�9J	���7�[m|:�����b��a���N�����4������t�B�+�r4+�����x{���6�y:�c���4I�ȲT��5@�[��##����=���A|�.t8�l�y% �:���o�Y#9����g+���z]���;0Z�k��EΤm
pVb���H�&MÂ��k'�̞���R���Dڏ���\[l6�V ��)��垖/8�lt��?�әozDNaY��L�3m�%&����n�!mZ:1�&�t3����d�Po����-l˪;��ȱ=�eh/P��ᚷf1~�z]��Y�n0+l�`�b�k>�Ivgݚ'kB��C&�Cݐ�ʡ�S}�(�_�8p����Ts޺���~}��0K;4ϻ��+�+��1Q� �4F��_J�aU�5�t5(�{��u8��~F��d�v1�
�NK���c��ptZȑ
z	��D}.��I�E�Λ��� ���2��3�4�;, 8G�� ]@��d��:M����%���R^?�����S�3�@$i8�fި��[XJ��>��սDp����$�Nu�>2��׼�G[���鎬�0��W���Ǚ�2)P�J/5��p0��Fu�<�]pҀY���,l�~��ۜ�f�g�v�p9���Cְ�����T3��L�V���Th�ΡT8o3
��y�ϫ�emoDv��noۯ�)��ފg��Ѝ�IM�-��c}���� �a��P��wD)�m-*�ߴ����	t�Yq��rڅ�"�PΝ�����^a��?}��
�� k#���)~��$3�J��@�����_<�Cj0N�����׎8���� *�6�(�$s�=��I�G�l.x�.>0�]�\�A�R�]�����Ѳ���$.P+c�:�S]�)������C��vчs�m��Ρ`�dW����](Tx���vF���1q��+h0���Ժ��cZsIE��)ߩ�����iJ�9A�{�o���ϭS�%Yd6��>��r:Lz�L��\8��N?H�[m���<7�|_�萜����9>)��h�n]����m��t�`Fz������L�����5���K:���&i�~���suYD�NO F���ϗ1��,�z���@2�v%S��a�$����N<��O�&�r��pp��#y��zD�HECW�"�Ӫ�r��fA�q�2��*����r �ANm��$��e�D=�>*�xt!|_O�`;FQ�X��N1{� ����7���D���@ {���J{/nR���FU��$����}��"&��{<��ò|��`2w�h�w��䐅���t�g"����Gꃂyx��ރ����#�]���?P�״B���l�,nx�Gi��)B�-�}��l�c�b����,��!ϥ��I��U� /�9�8�L���$�!ϳ(=y��ܽ�7�zR���B�3�YJN��.l��QꖎՒ9;},�l�m������K�� �<�zt1:����O?��]n=�=�Ê�Θo��,��դ�\�b�k�S� �QKeRi��Ca�k\3��(,�T��Jsg���	��!zI��J���+��x�� Nf�<~@�Z��u���s
	�KZ��|ݐ�J;��n�= �azP�W�杉$G$�ѿ���>0M	��˲�E���]0�>�SB�jA)N�3�c� 5`���1Q�u�YU�PT�%ˑc]�lm2�j��/�A4N��̝�6�9��Q�xZ81�,\��d�E�t��)=
�
3��s�;>�5k]L����8�[Mrt��AG ��U��Z���Y���+Bx���i#��TX���N0�W���=��K}��s6S���F���8�����W�Z�]S��1�XZ�����|j�a��Eu筭�B���Q�7�	T�ݗ�C��_,�f���ZW�q����^���8Qy��6brsa޳�5)��z�'�4�l���.r�CaD�p�ʟ@aS�^�}�N?E䝾�/�|Ak폓J��'H�!.����6���ϊ~Ę�Y�c*�R�9V\ϛN�8�L83wJ~L��=`g�P,S��o^����_�kj�o"��0R3���ԃ ���|Z����MA6R(�W�-����u���f����G4˱(�m6���d��
@ad��a�asn�p�5��N��̯�-��d�~4?�c*��Y_�YKP;|U"�t�m�f)��+R�zW��*��s��n��m��y�
�����ơ��l("���kM��*'/�##���ۚ/e�d�I	/E}�}v����BnQʰ�U�2R��I������.s'�T9�4Rb�I�ZQ5��̵��r��D/��3��~�g�t|��-Q[_�ԸX�).G��aC��i���`��X�9��$�ʎ��;	�M��T���-Z+��nA��	�ϋ/R�ꛊѪ��wlq���oq�M��ߥ�=�Y�l��bO�����xl�t��dw�F5H���h��z�!a�#xB���%Ų��S�P,	 q�F2���H��4"L/$8&+&!f_�J�!�[��?R��P~D{1��Xd(���JRȻ���	��,�M�zO�d��jM�;²�g�RT˗ ��+z��՝w�����1�k`_���䣺�� �đ����+�p��0f�T�8U.�%֙vɦ�.n�����ȥwm�D�h�n�	�y����AU���w�������?�ŉ*T���	����)F����`5CU��W�Z��!�/*C*�<��{�<����o�@Xv8G`��r�Q^��d@9�S���ZL�?-{�r��HPю�D�8b�z�(�"s��jH��
ݗq�"ا���h���"u��×nKG����	����T�w-��P}����� �E~�b��S���{_s����X%i�X���4@���}�_E�&|���:��Y�����B|�o�O�����4Bo�X�duꂧ����~+�+�:w��4���OJ�5[��c��m|�]}�OQ�ឳ�(W���1�V�f��`BNXI�W��(;�`(�f(��ȖȞ��R[\�zK�]��D���#v���E� CB��u��=����^��Sl�P���^�����L���wf��g���#�2y���ӣ��o�v��ce6`��q�8-PI��>Fl�j-m��L�[�1~��`���B'͊-�pi���?==fkۚ����V����G���0�Z�49J�.p[FT��;Vb��օ�2���(�INl�(���<b��6oњ�d�����@�L�m�L*E����{lSQ���4+���9RU��EN��m�V~�H3��J�Y*��g�fζ�=L�n�:���q�Ն��o>{��˱�����5p{I�ᤚ5k�_7fX��m^��X�$�i<��l��I��SA�uH�J�K����z�QG�S�=�}u/�6��B��f��Z�*��۔6��GK�h�P:��vz�u ��*��u�ƻ��F���FQ��0�]�JJ
�m�o�L��/"D���}���{��T�����˿�b�,�6mSl����}�jO�aI�.,s�8߰���j��HS��UxgT�A_�
?}�ǚL�xlWk����{�:CC���d���.�n�!�l�Z����&ҩ؅��H~�v$���w�s�.���Hy��Z=��d�O����}�g�˚
k2[~2Z|���6;�#�뷲i���t��� 	����^�R���@{J�(�u�L>A�g+^Of=h�,�n�������_JM�LXO+*�o�==d���� ��l�8#���P�5�y.+�8�x�qT!5q��R{M�N|��خ����M��T�!�6��0����+--�ﷹ �&K���,��"�4��JKD���g�Gs�Ʉ$������+��^��W`��z�i�`�K�&������;��{*"G��|�LѼI��fb2����ɞ�>o ���	a5uu����Z>��� W�^/ܘ?��}+�+�Rp{��[Zt}gc���\{q���}Υ�6(�&ҙ��y�'�vA�R�ꝩr�ߎ�=2�e}C�,�ے��b�#و���ę3���=*����K�d�E��)��ͣ1�G�h���Ժ,�Nh��pQ�)`G><�kbmoo?I�Yv��D�̡kU�/��n��6~���o=sT�׉khA}���0p�-�3�vd�>�R��ayX��n�B�*oؐ�H����e{�-���0���M�'n3y�h�:�1O���M�4j�D/O�i頧�V������N�l�ݩQ#;��s
VFSC�*X�-G]	����r��b�#Q=	��ތV�{A���"��L/bSE>�"-��ap</�`�n0��	����<�U�	���{��iV�u����m��	:���'�<�h_��IY�C��'SB4�io	l]��0c�E~�V���]	���a���aw3��z�&�n]��o]P�Qw��]��'ъ�g�7Ǔ��[��%XLF�˜'Y$�e�f��>,E�a�y���2�	���2����]�� �鈔������p�������7�xo���3��\"
�i��Z9.���W�tcf��`�w���V��T�����q���zY�.0��G(��>�tbn��^%ODo,k���������[�Y�&�߻����@��t�v����4&t�K�:����":�B��
��ٴ�`�FfM�a1�p> �t�4�AB��5��&�_��d᨞�e���Z\�;�ݚ��:~@�S�Re/ �/�K�z����e~%������t{�lU��9a��x\rkk�`��T���{��hZcQ��	Ւ@«�:�2�1�{1����R�/�mL#7�ț��L$�Z�P��1��tƜK
+@L���L!,�_ɇKO��2�ۼ�̀�U��	�ӆ���ϟ�➥d��4��̜�����l�=g���ɱ��׃�S�2�������a&.��[�!���W7�b�.x3��-l��px(X�B5�&A�Ր:Q����Bx�ج�#w�gՂ����<*.?�C��� Ҽ$(a�i�Ng��H�ӒQ�:�Ʋ�N������Q�2V��*|Ii|��&/.7c}��V��6@ʸ�djm�,�h @��hn%���rl�,��^��ƻ���zc5z�ܝϾ�{�s�p��e�f*��)���h�,Q}l;�Ԓfjp�!�	�O[�xM^�6Z��p<�6�V�j�B=[�9"�h)v�bW���
4ߒ��!ԖB�t=��Ss���xߠ��2��~��*$����J|��9�?aH���/̉E��mrᨴ�R�{DsI� ~������KW*l+�`��G�6����Ô�}	�_~�(N��%կ���P6]<1D2LȲն����x��*�U"@h����o0����������!����2�4b���_l!�ҋ����DC<JvwC i5�8�a����_�~-���V?���O6��; ���u�����6˄#ä^�&�Ĺo /F�> �	/"Nk�DU�e;~��	�h��V4x=�Ѽ�ɴ����(�Mƹ@��~�|���{~4��z-���}{��5���;6Py��.��cW��k,�����ꖦ�\�'L�|�bw:IfgS�t�T%�O��Rr�%ԧ7B��7q��5kβ������"����U�Ɵ�h5D빚�(Ĺ��3(�0)q �߬��)�������\a,<A\���a�+�ޟ�n��80AsA�pùT��\�O�a�����B�Qe '���W7�ęY��=��U�� {b)�^KJ����K6� �0�����������\A�-f ��|�K�y.Ћu^�̴�ޕ��!��{��%����l�bP��?�w�����;����ɴp�]���1$+���V�֑\�=%*�����Л���́josE����5���~F�*O�:�v� ������s��`����'A,��F*�#�z0�"����<�%jjSS��Z1#��<�O�[nP��.O//I����Ʌ�/|�c�ʟͻ����F,�!?a��=��V����f`���Ɨa����ń��ŧ��@��5���C��(��W|�� ��������Ͷ��N��Fb���	���iO��@G��#��W�5	��Xhբ��ɖ��Y�j�;����J��s��i	S`9�)��2c��}�u��Cma�Nܪ�Y.?�\iQN7��k:�Xn��$)\ֿ���w�Z����2T�qֿ&4�A}VZ2��	j᳄�[�[���*����<��r�m���N�B�5�6�&f���M�f����G@�K�󺐀��[�;K�ӾP���h��\[4�0l��"�rO
�s8qL�me���^��H��iЙ_
�[YM�Ee�}��@q���H4pI;�6_?��{l�i'ZJ�D;��0�'�t�)r��d	�By��R@�Ź��݁��o%�^3��o�= H��?��p������6HI'k�xIw�R�������]�����$"K ���]��DҞ�{��~����<T�K��L?U9^�I��
_��ߡ��x�1�g�(�^	px�����^v"ĮNI��9�w�x!�"a�v �!	p����#��l�T��v�T/�E_i��	n���A�3�BMb��ܰ]�T[n��9�L��6H ����3C`Z��i}�߄���Pn�4h�4��1N<@�Hڟ�A99���yl�@#4�	��5�Mk�8�y��"�
��6��QU�<�����JJT�v'bga'�QeϨ:l�n)��Cy���a_o���$:�2k�X;���������O˹G��<?�%���p��qO���bʆA*���c��^;g��_M��qS�w�Fkzy�?R�� Q�>J&_�Ii?����A���@�?��'�i����Z~"�Y&<GX޳E�a��B����A|*�;5�29f s���
�4�XxB�����ޟ�	���U{�x�{��b�� ��o�i?B*�r�����~<Ј]b�pQt��UY�T��P������}�7K��݀�xd�E'fqH�E�t��y��_�!>���-�O�\���(f�^Uf���m���ub�����/a��R�ͅx�R+�`&NAy.�4���I��������Y�B�_���͓���!��A��v"�7��Yg�.�߻Z�w/��V!�I�*S��ށX�tN��uRof49��������lOl�A�4�I����o�A�)<S|�s,$.�L?˥K��|�i��H��Q9���ᅏ2�u�&}*���|Tg���K��j�A �y�H7g����4�?�W9f��h�7�Kc:P���6���ǂ�9��]8>>���%���[��K���ʱ��٦-�<M}%Ί;8 ��T�A2ᜣ�mQ�����Nh�H�d&"���۠�[p���xYެi)��Ka���uqUE�^~t�����SF��'V��QR��`P�Sz�E��l��AR��׳��S)�p��?Vf�1�"��{zogot��m̂��k�X4=�)��9Q[�["B�tS�ɞk��W�W7&Q����yĔU�ٻ�q���!����^�W�
5o��թmt���8\���a���xyM`j ԝ��);L�T�Uv�JX�=yvk��s�o�ק��P�"��v��>�����c�����M�o�]�C�+�\�G�#�$C]�f\	��F����j����Ay�rց]ՠ��S�ǃ�)G?@?���䄭*�oP�"nN�5NL9��I`b�Z�6��&��\5����a����[�>�� ^l�i��E��[�5��2<�;�'׳*G@cv�?N��z��rQ���ס�XO��JM�vb����M)m�;f:
����$�˱V���~1(`�3�\*�m@B�ȇ c{O5{r)xL4+M�艹П l5"{�v��k\���s�?Y#�xx��&���Y�C�>1�4�	��Y����%Ջѫ��54���)��o^����`芢�d^=�L��0E+�yВ��Mq�3�\?Laxk�CĒ>C"Ƿ�>��;��X�*��D�����d^�q�5��c��.�Ȫm(P(a�4{�Et���KF˺���"B.��� v(X����H�0��y(Cϟ7Ǐ�X����H�=�^O#x�������U4�225h���Y�q����4��h\�v�*
k{���1l��h(�}=�G� �L��fK�u��4�m�nw�)��M�9�
�>�W�'�L��gE�
�4��	����g�*��m��&�k"��Z2��O���]���h�Z�`C��c�GP���?��A~z����� ICH$VG)���S+';X��Fڎ��I5гy����|��0�b�Μ���5ix���^ߜ��>�	*�ϧ�n�,ɾf�:��X���N4N6����K���/�5�N^d��J���Q�u^>JXe�k"JzQ5s�L�6
�C��p�e#����-��=[^Nj�q�X*̿�U!�ǃN�����8����1���|B����Ҋs�Y�����;��n�j�x���	�L6��J���R�˃�w�7J���g��e����4��41�P�z?=ilI�oƏ�B����w���PV���j╼.Zw�s�i�7�U��uy����^C����ٯu�qZ��ù�]l=~gxg�7�ڋ���-��ʛ����7���vF�@��-3&�>@�u�j$T�|���^�b�A+{�i�~��9
�M�ԃ�oe+4bF�R"K��ݷW���f���N.��4I@:��2��m����/[GH��o%����6�'��ε�@�t0ő4f,�C��n��^D����Je'���7�Xm�]$F���kK�p/�~�-V�'�F���{��KHOL����|=O͕/!�9"��9�d?�a�'=��I�B�X�2"�L]{#]W)��(�)�����?0���'��WO�wsv6n�Ռ�j�~�@Q��fb���r���~ҹ��(�x����t������aC�E`��@�\$�"Ce�"Io�r��-�Ak#!"�NQ_��I�tM���1,!�L���:��y�x{��]g��Vg\3�!�Ce��]�ʐ%�3��\}o|�����aGۤc_�m}0������\(b�>*SАvD��t�=�r��,�����G�a[&������V��������]᭞Y�<h�J�Y���z��t�4��`a��>��[M<r�~?=�����}(�:o儷�2��pNN0WS���x�Pqige)02�=&��ݛ' �^
^hL�KY9;k?D�v�ͯ�; ����=�#��� ��+���{�E!O�fn_B����T-��#zA�V.���*�����%a4����g�dN�G�g���C$vI��g�?V��#�R6�k<��cy	P��?:�<ߒǕ��3XT�t�/�5��L��d�U�E[��D~��/Y�dh�c�'��m&��Tɺ�J���9m?��p���h��Ur�B9�lv�J�*�����j���I���,�(�`s�M���o�ᧂs�ViN�L�a�r�~b/O���[�� �}�mTV	/���YsΎ�<� �%�Ɇ�w��:3msi��3���eb��(�6Zr-+c ����L�w(����K�E=�;aF�SC���J&�'�}�bbV��A���=V.���V��6g�vl�{�{J���_��9I_7�RǼ�r�t�d	Au�UE�"أ���g�C>��V�&��Q��ZW{�X�N�@�V,��C<#��5v��ł���ǉ0�5�E����R�,�%��;��Z.����)>��9$�sd�^Fx�@P3\7מ����5n9�V��5ہQ�{�q�+�:oR!�v<qO������������JBk�!��]���e4��,��y��#��h�:о�M/��Ea�"��ߤ�]�˳���RZ�[��P�i9��L�_9?�������s�q4��0h�t����gi�!%�2� 5�ffpil�f
!�1C����Q��Pv%����rH1<P:�D�\��WCEr[�d��J�*���O)	�;�EXY����~+�˩�����lч�$F�m1�X�M 2����#�=�.>!�Y�{Ҥ�kF��')(�#yS�����>{W�Ƙ��vc�n�����ѓv��:���~�M�(��쮣�W����� �Uwi6�l�0�K��&!����O����:a����#(���R�m���	(�cKb��t�M,�k!^�K�Å�����`����r�L�E�{$<���(%����CL/h ���{��%���ǘ3����2�����+d�i��1�>p�6�9�n;5ʤ�N9��3M�5��tcU�0a	C�T�j�k�T�i1��:9��k�k�i+��i L���.M��-��NuzK(�n\ ב{sP�����qg�_Ķ��"1��+`g^ob�Q�҄n��Lc��"ӵ8�M�_E0Hf�k�ݚW�VTAb���R���l�讨K�jbWR������U����*���X�U�t�Eu�x��+�il<��Y�!PHz�Oq�N�Ћ��S�П� G���%j^���c�H� �B���2TY���!���<E�o#�K_��8d���-hP��˞.�y� ��]Ć7r��fz�����7��*���_�߈(`Z��i���b*��a��|e�ǡ	�bC��1N=꣉�׿3�?[���J~��J:�=|�9R�ݨ���YO��U��\��$3V�={2���|yl��$R!��],㜿�L0)9��|��z�(��_��U	��UƜ͍?�]"���螬\�)Ӹ�
-	f�5�q"�؏Z�r��y�1�^c7,��v��+���r���k'ps	��kJ�AN@V�m
�?����9$a�PͲ�n�����$�*[f��g���.��������q��9�9������bR<�, AD�c�խY-�X���'<�F�w���{�sF�/���7{�-�ا�7/�ȉT��+��4�,#���Sn�30@%�*<a8�B7KsB�#!pLX 6n\%���SHO�ۚ�����C� %T��q���~L�r�+q������ܛ0:�.|Ԏ& _Qi���
�h�����H�ǘB�"��,a�G�s�s=�*�
#��B��^���2_���69\$l|&�t��z@�5X �����o���������qQ���Ҭ�w��6vx�t�t=^d�b�K<���8�s�T�p��2�:�� ���? ^$z媷�t��?>_1����{?��l)�ܲk/�0���]����"R��x�cO��04{�S��N7�K�ܐ�G2�!o%@���%P�����0<��/��Hµ�2L���BI����O��d	1�$�x`�Zg�J$OS�;&l���A�����@��A^&�Q|���v�9�Қ�O1ߝ�YP�N���&�l�մe1@*ӭb���C�@DG�����Q�Lp��Z&Z��E�C2͹�xTI3M D���UA%���>D�.`�����?=�-�`G�}�����}��wH������P� 0j=�\B0�;�*�H�L���Y���Fe�U����M~���\�����mi_�>V|�9L�g{�'*�&�B(��V�~����t�����~�H�I�ʶ�M�DA���R���Ö��K���+K�BjT�M5( *�#�5�_�6�� gK��"���g�a^'�WQvjl�r��f�A.�}r�G�m���!G6�p~T�C\�B�
�#�u�([��&%��+�ot,9�N�y�2�}��W?~+ݫY�������hO���7w4e�8��؍�ޗ,�ɻ�JP5�A ��ub�o���A_	�
�,�'��o6�3Z�#{yoNM����o�I����ϟ&K�'�%<	ň�_�mS�$G�o{*�d��GL��(5����\������2��P��s��AN"�����|�HXM�,-uH>=�!�K��82w��T���`N�*`+-8��$��j�_��ٙt1(�Ĉ���,b�U5<s�����
���*������wäKr�L*LE�wb��L����	�JL����^���{ �	��ߴ��u;�`�Np��w���\���5�ȇ��T������u=�W�$���Q"��~��'���yQ�U2������_?)�C�~B���묯iP&р�-�y�p���u�խ��.���2wWbr`5|(��Z��V��='�95'J;/�O%�]�- �{�aV{�3���:��C~�$5wd�� tҘ�3 e}0չ��wl���e~=\<�Q�������8d��fU�¬��%����\M���u{:m!�w6=U�^������WH���%Z@ܛJe�OƯ�@փ,�6����82��/ټ}����B���nA���d᠌�"yj��W�u���߳���Q�N���f���@��ȱRf"�������Տ��	�Ev!��W(; �Βc��1�8���$R~ݘ,،��@�˟Vۊ%haT�H��$F[n�ՐEm�0ÿw��˶��S�_����r���^D�#Z�[��֎��\CS��CN�r3AFu�2}���;w9IP�
�D�d�hڂ6����+4�rk��C4����*d�bP��/���&ѹN>�Va�gYF�=Թs�0�8���=���R[�n�wa��#�ŷ�6̏,�P9FB�=�^���g�`mi!f���ݍ�g�פ�����Y�-�`�c;jR� �*x�����On-[4�A
��3���E�|	��S�%��2��]��]t��Ss�]� )ŕMH�����Ra}�*H�t�� �R�Fv`��kp~��D��6�Q�ii^e�o�Wv�E^��k0\�S�I�#���Gǒ69�y.��.՛�C����?�v������� ��_���u��^��������c75����o�g	��I�Fh����΃��D��k&����;���s�x��rG���j��%�d�����yc7�����j�����nLϖ����ϒ��
QQ��؜����ߖ������ة�Q(��6~�)�*jg	1�I�� jسv�xWn�G)&vJ,��f����a�ؒ��f��V����P}] �ۘ'� �~!�0�� �7�M]'�du�3H �)z���bˮ/��a�d� �@�q�����xD�����u#�{R¡2#�@E��a.D���F����ab3�*��O.АQ�OA��&<�� ����!21���������KZ�X��(�����f���ǎ��kS��'ec��X��^�&JGV��\�bZ	�4F+r��n�$���4���\�z��9Y�������l��Dj�|���^3���K﹬���A���	����SfsG&3w� ��G�g���+(TiŎ�l0Aj#��e9V��܏C������8��]�8b�%<�c�)0���7qz�?��:�����!�Ӯ��V%�/|��|�'_��8bK[�Ĩ�(��|�ó�s�W	Y �z�ԙ�!���"��*�4�c�Џ��*'�
�RO�5�Q%�NR�	�;f�-C�aL)�)Ow��h|����y���FߩO6F¡(z�׳���|����/?�f�t�Ļ��Z	����}-���3hp#���yd������A ��N ��(F�%L&W�Q+
|2=+��ɑ�p�a�0�1��k�6�_�`����f�@�#8�xO͜2U*K���V�']j�x$)}��mR�t=���')k?�1�7D�ki���5�]@�VS�7�������$�E[�����+�!u���~<���6aN���C �`��8.%���=��'�����E�
�K@���̄�H���hd$��t�R�˰�Ό��M�2p���5fhSE��u��Ċ�"���Pf�V�E�q~[����?5W� e�o\E�	x4��ի��&�r)g�
P�����s��PJ׆��$��K
ɕ I\i(K8��<���K/q��A^{��m9�g;��Z5F�,��"̝gȩh������ �e��T�]��l����4"0ѓ��Nx����	b^�t��C0���J�Jt��&7�NZ�W;@ä5���6� ��<�����0t�.�j7��j�پ��H����dFMEX��}�fV���TOw��^H;	Q�4{�Shھ��WٖM�5 �-��� ���ݱ��JU�_sڷ��A�N��w���zw�(_#+*Z�5Pl<eI�\��>�B��C�B���E�Py��c����(����*�v$��D�Nw��@��f����j�Ħb|��u8J@a�{��T��
��"]Li��@xK�'��V���-Rnuw%�>11VM�T��nY��٦/�~�<�İ����-�/����w�[E	z
u@�d^Y8��3�jyѝ�E��U\�-#|������ xfg��مTf�n�1�����;��
zf&�]�%ZX�Z)>�Ő(�(u��\�4��\߰s�}�_����[�LBB�ҧe�4�
���`�����[ ���W�P��g��mׂwyb�9/���=˛9S��v�~Y��]�Jm�*��='k0���N���?��2��}s�㴽N0���n�\bs��&/2�k���Hl ,���j�����N�$t��:�mb��\M�U����b�#	��h7�IɣM�씿޾,I~�",���b��(� �]+6��z ��3*g�5:SS�S�`��J��$Ic�Z�4��Ļ��X&������h�p( s��0�Dj}�Fd,C�$,i�\�	�^�3�T�`j"^��]�Rx�IcU0xؚ����ɒ�F3c������R���WQ\p���� OG��zD �Uk"#U�.��/�n�_Q���up��s�iU�sR�ҙW��e���3�tBbld�Z�q�3�]��J�R��Ği�O,���:<K��]�M(���^��/�v�����A'T��!ۤ������g���N��&J��b��
U�ݧA?&�.q~�F�4�+�7`��+2:�n��`�=��r�]�$����lg�Rń7�=E��+���rh dK�N@�2'ٗl�P$?p�#�_R�=��!��h� AXr��/��%(o��Iñ�&uB��먒a�uHìՉc��46.�f�Hq����-~��&q@\� �xUu��<�I2�5�O��kL��]�/njqQW1���é�%[���Ȇݕ��}���	m�i�9L�R%>�ӫf��,��6�\���	�E�e̷�_.�8��P�3H?\���;�^m�h?�A�e���\� ���T��	 ����ų����g�    YZ