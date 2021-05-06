#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3025759550"
MD5="11d8b6d719a50dbb06fe7c175b201ea1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21164"
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
	echo Date of packaging: Thu May  6 20:40:49 -03 2021
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
�7zXZ  �ִF !   �X���Rk] �}��1Dd]����P�t�D�l<ǖ��p����
f�Pz�щ�V���&�P._��`��_�:��b��N���uDx������ ��q��I���*��2���	����D�%��.Ý2���V���\-M����%�����Ӄ�V�Z3q���GT]]2�a�k��Cg6��c�1>�ݨ��� ��"8&KQ�n�b����͊��)X�W\{$3��R�� �P̳?<-���,n��2��|�5<���wX+���J
l~e+G]V^nϥ�Y�� 7=	kզ��wCM#��I�����KѰ�ξF#cp
�_�q�� DGz'��L %���'��nM.�O�/��S�hb���I�&P�.D���H�>(�d,V2F 8C��M¹�E;�k�K=��*�+/.ŗb�=�|������E��3��EE�9r���;���\CU��Ѧپ�*>�.[خ6�5�P_��,�,�f�ݴ������n�#�x��<�X=�S�Q� +,��p����\�"���L�g7"���G�"w��!}E�>��B���,6�
�b�SI��� �ll���g�M,1�{�Rp<�%�����W�tܛ���U0uﭞ@*��/k��(0z}��	��n�*p������*F%��f*�k���㏰�ƌ���Al�/�Y�|�Ņ��Zb�MT+t�
rdd��I��c|���sM���mI!���Br]8��eFy �_u�;�A��)���k?�+�붦�fX��`p2OF#��ѱ�����ٷ��#w�S
�C�c8d��R�J>V2f��51�my�R��{�Ɩ����m��I^�
���h �0�� Az���ְ���a��l��P ݨ!X�e��:��X��-ۿg��o��~�޳�S��8˿O�'���rC�`�M*�53B1�TT�W�4{
м�Y3�)]�qn�3堶j'�0�6Y�S���S��v>�e)^�����?dfͫ?�c/�1@���*��֜@��J���ۆ?6xwS������c{�hה�/~J6�p��
8�w�9��2�?S��V���F#	.��B��� (�Q�J�bp�B�J\iǹ��$*26���d���+ޣz�����"Y�1�//B��Y��x��+G��!բG,A�h@���Y)R+�C���~HoR�!,P�����m�n.�s��k�M9���-.gL��ޢH���QK��w�<m}���� �v 03�r������7>k�@�%�8!^�F�Չ5�%���DuS*�.���d|Q���h�k�E�-!�������:dr���\�0�תjcy�������Sa�uV�`4+�,� -���� m�!�����9g­0��&������W%� dɄ���y+��^��t�� ��VVn�1.��NάR�x�9#��֎Q�L9������/_;�F*#�I���M1���XF�b�����Kr{:�D{�$�獡�9�'oM��,X�����y$+|�J�傇�ǚs�M�_p)_�6���B�ق`vӯ�ӌE�g}���`tO��P�ǦW7��K�}�'-�l���v���qi�/����xC*V�܌�m�&0�	I�[fm�5���a(C'|��Zۋ|s^;f��3��I�V"	�^�\:�Pv�In>���<�̾3*<	�N%���G�I�r��7-�~��B���oj���$�w�$@�-�7��w̷��X�}م�����A>��2p��6�Y����Bu��c5"[���7d����1��mG���#Ʒ ut�HA��i�����]��x�Kɫ������[�3z�	
*�Sv1u=�-�?�����7ޒ����������<�)鼰����j�?&c�eb���ȸ;�͈�Z�6�(W�d���uzj|6Y�*.RBYx�@����j��$t}�x��-�_��K@���N���/Q�q�&�@�'�s���~zm��`d�є֘���^
~I�
�˕m���@;��;�3Z��m�)�B�9aA����9�Kur�w��'a�?�}
ߢE��3\[�����ȏz4v��~zu�'o�_�~�rx	5�U���VH� �Ծ�� ;5*�k�6:yK^�~�.=ߴj�H.,��2�@<q���M"F�8[��z�C����.c��D�ɀ2b���I��D�_S�(S��W��aK�:��rG.6(�SLg�|����e:��$���L�//�W���>�P��]�5��~Z���Xr(� ��{bNP�`D�E��V��mw��&� YK'�a/�ɏ7�0D�����9gÇ�Pё�&(��@�<�豟��6r>n��
v9��v�r�t{F>�7b��������ӋL�hl��������(�rH���>�oW�P�f��< ���d�lJ�g�c�O�ۂs����M�&~�
<�cE���Y!^���0�������"To� ������`�i/����/1Qh'���U�e���1��bv=��H�&B�M����4�*\F�_��Us	7:�F�'U�6܂%㨚+��C��I����j�q�e�ߪ�����`�G���bE��3A��$��~�-Y��]�F���G�LN���	8	r��s�(^�cz;,D��wJ_�<����:RsI⩪f]l�@�Z�o61�C�y��Ca�AX���D�'4��N�����ͼ=i���o���P���U�ڋ�M��1[N�h��aLK�U=�l|2d�gJ�ޖYh� ��D~k�	�p8�,��:�����UGHC�Z�">�� ���J�<u���ܤ��g��6���ް	�N�2�3~���R���do��:��h��vY`�����GLY~S뉆�����A�C�C[��쒗ȳڔs[�r*u�s���;��#��aQ�GlrYڈ0��ǁ��
���}����kyr�Ls�I���:VF'W�ք䡝d�ƀ`�Śv�޲ ���%�,���F�a��OJ�=��B�~ը.�̸��ʘ��8de�CO�*fε!s�dDq$:�@~��kW?�-�kw��+W�#e��u_P�4,
M�rg�K��K0m�r�,e��NO)�z��2�Epm�a:U���F֔�Y14LF���p��޼<���|�+KS�(3���z���ַId��y��-����`Jv�5	�M�,�FEEx̡�/�f�LnP9v�o��;��)�;K�^�5כ��]��^#������t*�Ps�8ol�	Ǻn��*�@8�����4��ݛ�𭜆����>���Ye~�q�wO�5n��/�� ^��p�������3n������=錳����2��!s���*� �V{dW�:i�%�����T�:z��~]l�?�-cw���|3�e�^J��V�![c_�����kd�}�lU�C�[��l��؅����r_���Wa������o�M|v�l6"�^`Y�����A���Obk��B���	 UځyX���� ���SM���4g;["���	5LO"�cݟ�װ�k�]g���<�qhRc����ã����Y�#D6e�&�%G����ն&�,��m�=_�[ZQ
(��`7�G�O (̑�����Z��	�⚔��-�nq�s#OþC�b��DQ!�v$�
fz��j�ٍ������(r��4��O�咅��$��1OU�R��X˞n3�_0���i�	��9�DM޿�}쬩��3E�N^����U�}z��Έ���4�7�܏Yֆү{�Ɠ̸����A���NW��jA���H���e�{4��]�jO��ڻ��Q�N�Ό!x����l�7�>N���dn"}`F��/H�)��ST��s���ৼq	��80����4��M"���.�?��n5�N��V��S6�G,)����-�v�ء_���v�G�_ao��ͩ���� 1<����-�~��,/Z���9��C��%6��C�|(|C^�w�A�"�����ͥ|7�ӿ)n��`я��/���Z� �"��\�lY������ե���;��{|����z� �&��q��M��?'��@ݯ��O����A�/��#��*��,�u�U���Q���NS?7P�R��s(k�5��	���Q�6�n6�1j>�Q�!�MD�L�HҾ� �S��<�&��ީ)�%���W٣n��Gc�e�0�H�&C�ڦ�Jpϡo��Y��+�t��qWȄ���Nt����0yF�g~[�qne�ѧ;�̅��@Ib6ߟ�Y�d���R�L�2�$ߛ�j=,�/�`��bn�K�l��X��ߢ+��A�j^֔�$ō�4A����N��M�7'��^t��M�0��ѭ^.	H�x$�LOf���,��@zt��S~�L�ʨ�Hd���i�/����~=�"�>����r�O��os3謹�y�� ���v�c�rj*T;i��Y �PP��E�_WȻ����c$,ZqHxW���K|af/����=�ni�����=����m��d�\h��.N��e2�mƁs�Z2M?�L��z�ʤҾ}�P�Ir4o�_��� ���c�M1��nF_�f�dT�霞�ꦊU�B�"�����6����Qh��l�F�m����2�3�xƣ�5.h�ѹ}c��_^h��.ҁp����T79$m��gvJ����."�@F�]���{����Yfg3t~@K^���Su���� 0P)�p~�2���'"P�R�Q*��ș�y����J��ӎs�:e���[#q�<����&�ي6Jr�$֘.�=�W�I6S��F�b���et
����OqI*�U�A����d��n "����7$H�zuGVE����Ք��1�2:v�����Eh::�	@w�nJG!�I�0���}O�L�y�1�[Y�TF��$:{��M���^xs����KU�A1�J�i��j��#��`x�}@#���S�8�lԾ��^�g�Q�%#�kR�s�{� 5�����A�^�R��)��,��-t�r�E�x-�ͺ$��H�Gn�+�,���hW
�nQ���(8<�RMƼ�'�	ɋ����<��2�0O��u��ը����> ����(��C��;%`�i�y ���c���~��cǃ�+��Q^��vx���ڂ)���0ߦ�Q�o�ŋ�7�H��䦅�*�}'�<!��`�ilz�GS��]}:N��՜(�#2��^>����+m���U��(
�������F���p1 I��m�k�� 3�x���S����%|��i��w��JLmN۠��Bd�%�W�8��E�Bd�ghuz}��<�Xvi����Ÿ]zJ�mw ��A�%L�H�֫�O�AG�/�g����N�N�m�AQU;��I���K�R�z�������V?��hCX��#7fb�?Ç�� Oc�Y;�E6<-�N�d��l�0��>]wM珸]�zt4� �Ki�f��>8/���Tl*�B��+6��r�RJ���d��PA㕂��&qy��J*�n$�.��l8������s�W����z�WM���y���h��P|{����k�e��	�Ǒ�D�,�?e�(���|��3���";�nW��R\c�츖�x�Qu�9Y��_ԋl����5d2�&dD}6�k C]�	Qj4��u�i�����K�w*�����
��O<B(B����PǚHX��7r%�c.;�X��J$o&+.���sm��O�֥@q٘B��������;�Is�4���|��Z5�<�{��$��x��@6�CAT칥w�sξ���z��v��D��Fm��;2�֦'a���"R*�
�]�k8^�.(��M.zc�E6j5�lTp�����}C�� 8@.�ÞH�y8��������sW~�eu�͓j���`���}_�׷���*����j���$9�����UdD��[����2烜��32�ǚ8���o�9{��$OLU��ipv�x��0K�,�PЏ͇�����A^d�(��ݐ�B�,֘� �5g��q�!�f����b�L�F㓋�Bڥ ��k���0᧡�V�7���`�v��l�<~��$!�kxߍ����Ҁ0���G��w�D��i�o��
��~�zi�"�/o��U�\��э�S7��e�V�Y�^�<�"�a������hn�b��t}4�uӉ�g黬��`�?E�I
z�v"�P�b�)L
A�.����r�V��'��A�.�U'�h����sc=���w�ei���t�4���N]�I�`7��+����g���a�gd���O��
e����r�;��_G�Fv@&<{<��m�*\�K18��f�[�U��[�袬��#OI�:�Ŭ�z��e��R_���ș$hK&���T_�4oIU��L�ge�<[u�;��W)��x���o(ɎU��J�{�c��5�#��q�kϨ�W�������v�����g��_�R�l��uk�����ŭG��F�������ƭ�<Q"�!�|k��~�Nq���+�&Be���B�0'mps[gR�����0/y��V	��eG�NÊ[7��]��PЙ��$?n�i�m��Caun�_�屺��|���09&�V��΋��|~����eQ�0����<��(�h"a����A@]�2�i�<�6��)���~����J5�|Q��U
'�	g�����I RS�E@�%�9�3�X�X<�ɺc粝�!G�������R?U���n.<�2-,�Mtg,t�R����pK	h�2#@���_��}T�t�F`�K�7b�-�Q��
J�� ��jY�_{&/�	�NP�s�~\<m�g�ʕ�[�	7(�l��{fA" D3#壷�z'>���Bu� ]4x<�H��5�F�n9vt��^j&�x�+�l֥M ���'��o�p��� ����y��!��n��(;qO�Ƀ��� ���~�J-�Ӫ���HƆ�}���Ih�X~<�l�Cp2d��$.EZZ��HQ%{7p�]������~�e��]�`rIrtC��3�����NC�b�&!��Am��5�o��������ja�A�q�9::�z8I��"X9�)Y�O��1�Z29\�GZ�"���km��>�Yl�Ô5��;[�	�|��1�!N����;���B� _ �d�C�T�+��t)M���vU!M{��*�
��!j�,�M5����q=z���|�����C~�r鈢ޤ��!l�/��_Y?A�a�b�VV:� �L�l�믑�C@�Z_ܫ��<�@�+�f��T&���� �`ض��tSZ�B���M&��b������_
�9m޲�U�jV�B�ˬH}KbA�:����U����Y�z#?*���3�sN�K��&�t�����{z��@�4�I���]�s��F��o�4
�*i.>p��(;�U�J�MT`�&P�g#��O�K_E
����(��i�U~����fjƝ��VE{�+�b?��$�p�i���� �FTTKk�C6�Ơ��"2�&���JB����޻�d�	�J��63��:\�����`gF�c�|��6%���[�d�P�Y��r��+�����'�b��硧u�iR��1�gՑm�������x?s�]X,"���|@�{v뤐1����,��*�'�?z%+�:#V�6S ?<�]t5�׹��/���ሏ�҈$`ր�ł����?�V�p���ɩ�MZB��ֆ��齨`��6)͢w�T�m�PX1Yѝ�q�˔�3�����?+�CFFj�?�_*��fAu�k�@k n�2�U�H��wp��M�J�!q���D��2�?���o&��p���w�{^���(!��S��,/�x/�����L�֎|M�s������v#�,t��	�.�C��%�3d��^��l�@�%i|�[�n�9��&�j�/q-��ueMV�e����������55��0	�L�ŧEʵA�H�����j��H%ZL5�n����-��˓��Y<sCW����lU�XL} �[���yD>�+[��
����:4����	g/y�%���P}?��X����66#�1A��pˊ��#[���u^����5�ҶKa�*��OO%c�;߶��d���}�h@}ļ���⒚�{�����s��%��5z��p۱�(���J\��N�-�b�W!�c ���_�)6����o�Ĵz�>��������UY����C�t>�s\�nb/n��`��R>հ���16�PFJ&d�߷ܑ�^�i��p�A7¦�/��V|Is)o%r�Ͼ��h�%�[b)��EJr^G=�S>.��@J�}e۪O�o�y�q�ޝO����<��N�K� K�&��4��s�ܩ��/�bK�M��Q�/A�s6 �S�z6`g?���M
��5��.R�'���{�X�r�Jf�D���@��8��E�ݔ0(�p�I
�]b���|����	g�'p;9Q�!`E1�1|��v�p�UŹ�b�E��ځ�,�<k�����h�I��t��STqy���� WL�~ئ�y�r�Hv���q]�5� ���X��o�������v췦�f��A(  Aho��B��o8�9���=s�$�g�6�]�A���?&�ã	an�%8�#y��^[�v�����p�.ؔʸV����s��f�`��5���E����������N�3E+�l�I�אz
s��s~#�fF�(����Ч���g5�5�a9���p�cHq��`��I���굝��ҹ�L��"O&#>,�����w�9}��2z<A�9�4n/8b�^�s8/�� V4,��SS`����N{c�w�z֢v/�2�+�x�+�f�
���h3m�?C�q��{����Eـ�y��ژ�!p��/�*��Rɑ�@��k-��5�&�б�/>�h
qCE��J�?��;���[��X�4�=��V��K��#�a6�����#l��]{l�:Pr,��w9W�j�A���]#��3�P��R4��r0���� �ř�}0݄\I�]����~��y�n��̍�E �,�=A�K��E��M�A�%���8z�k 2mv�����نPhLsVK�ԑ�
#L��n�y.��N���\T�⩴���� �>���5]EuiԈ��h.�ӅN[�W�pS��T�h�]}l��!�v�7����0���)�D��ǡ�^ُ�\X�=o��I��N=	�LbQ��4��������Ot�o�'�P�p��'��>'���E2����ޭO�RG�e�5-H�,�6�������iYҠhSFְ��c��S	��ђ�C%�ڶ;�:)��y�R��iA��˙�{����������a�&�$�}��Ki�I�D�l�~��u�n�r��&)te�v���F*��F6ǠЌu�+����贷b�h�3t���C�W.������2u��g��HRd��t�.N�r`/�VG79�D���E.���t�2���b�wVP.f�4Qm�Z6Q�ێ��1yw�3��s��E)���7�C�ȥ���
ls�ZXVS"OK�,��bE�-K�p�`C���0�4���5�w�0����w�s��Y�2�j�!ŝ49��g��W����JƆB��@�ސb��g�����(vBJ�9��M���tQ��I�]�%����"����1otp��bx��=��ȅ�:1�*��}�E%��o���l��o=�v�h�1ˌ<7�����x�����q���k\<y����gi��S��_S������Ǡr�ɶ��p Dܮ�eq|��(�z{LΞۤ	�&�9�u�O���nJ�z-�`���P�4z5F�U"���AF�H�hnv�L��:� ��$�}SD>�w����4�_�eL�^�nU�v��ä��!h�����4�ǆ������}�	���!cD���8�,���k�6�^0G��,p�QcH_?���$(�q5]���d�\0�&x�j�
��_�@~�f���w��Y{j	����a::i��c���OqȀ�_�Z�l��o���~�7ǵ5.C:�#�b��m�J������]Rg�F�ƽ����x�
��v��bo��I!�Q�I��z�T!D�p��5QL�8#䴇����ֹE9�
,.Om ���3��Mֈ�l]���� }9��+w%>���2��P�� �����G5Dra("бf7��n���!��a3$*F��Ϫ�XD�1,�ƘyK~jtEL$R_ig؈(!������xUBש�l�����#Ɨ�lgxNv�/��v��z���\���H�~V����8Q�x���x�l'�n���N`��A˨^�1��ҦD�B��!2���i���o1��.���/�]�H7��mGk>��xdN���Nx���Ȋ�r��y��E��
��������*
<��$�Z��ac7o�k�̊��!�����D�S�e��ʄ!"\���Ԯ��Wb�:��;qk���o9�|���F=�I��y�S��z��=O���D��M���{ujVuP	��>ЮV��>ю�9�y�.=��Ap�f`ç%+��(�߱�d��V�`�t�	��ԛ�?�;"v#u�����BL�Lw�Ƨ�Q���]�uH���(v�0�������3�,�_LT6��q�&�2ĲzR�t��A�bQ4F�[���$�sZ��?oD�S�θ�� ��c@�l���;u�m�����8̝s%g�Q4���a�#�w�1��/�}��sz×H��ۭ���bQCcb�1qRcRw|.4�!tm�u���+Y�ʙS�sj�p��T�ej���&����E�Y�����Sk�+9��v����󡖅d9��➓�a�L\��4�%O��߬�u| ���&�{�M�)�5jeڂL/
y��V5,�c�����0'�}N��K	�;e$��S;�#�ѭ�8��ZN�m�}6<�ː�7?��]�0Y��TiD�F� �plE���!.WWL-���l	l�R0HЪ���I�#hB�QY ��ed��J���
<�1��ev�zE"��*(x�#l�yQ&h��I�9h���49ԩ��Q�m�:c#RU��S�q~�eM'���!�%�����0�|����:=ѓ_>WR�ձ���.*�ֈ#K����@#Ӽ�o_v쑾���|�(�ׁoW�z��OD,���}����V���g�{�Tk晣�M���}�N2���I�>�����%�Ӈ���5������0&�MA	�m"�����Y��_A}�N�q��h%x�(I�G֟����8w��* �W����DMFF�����Z�P/����G���;V��Fl�yXn�?�I�����֨O�w޶M�d�R�Q��}��t �M�<�i�{�@�MC����I�0�h�iF���M`�]��@y��f@��T�M�o�o7/F8}��6�l�����<��q;&�=^��ǲ���<|�J�n��n��9�{�}	�>8� E��w˹UVX�O�-�ḻ�G��o�%�ƻ$Cߣ!yfzE�fܨ�  $�e.����ܚ�1g.��"eY�w����deK1`�خ��o�"��qjUQ�+�\a��͇f$��	�ࢦ!�!�0�[������8���=�%�J��C�Md�a��hLH��w 0��?@N�6��O�t9�DO���B��<�C^ �F~��Y8�!�t3)^n0�� -�z��Rk�7`����J	�Ė�8֗)N�-����>�i=ͦ҇e��w+r�mM�EnwQ�`nL�H*v��^ڰp*����x���s\�h��I��ԩ�<3a�%3+Ħ�Wg�FƹP��L�k8_v���*��9ՠ����j��d;�C����	�̡��0��u:i��/y؉������F��
�$Ƕ�SN�[�}|�aST�z ��-�����]ڈ�@q�l-s1���3m#����3?�DX�kZ�rP4��F�L�;�:&��ohA]�W��^"��"�^b�R*N$"�e��d������f��Z
?Z�-Ϻ��'?�şZN+��e�n��Ū��@؞�� ̪1��v?G���ե.�{�ᱤa3-AE}2̋�5��[ӯl����%��\*�#�0� U��-ј�K�<[u��岱�"�� ����T�/VExKs�.=��n"���)�V+1H�n�f'�1lP�IY���b�CS�}�T4�u�}q�O� �;г1��~�2��^�[z")b�.�.[�E�0�wGQ%��{�+�]�Sz=)�A�-ٴ��xZ��ڑ�2��,��-�����v�#I���ea���HC?�y��bE ������":���Pep�%��7�b���+.?�&-�ȂykƤ�%t&�4[ ���׬�	�Ҡ��&�p���+��`�����d���E#g����/�̂��W�/�҄��F�3�?q��@�4n�)H.!L���""�����Nh�����J�j��C���39�]��
Yd�X���cl����l ��l�B��hM4O�A���zV?8�#�����R:5���I���g�|nN"���&1�Z9�J�G����(:�8���uw�on��eށÍ��m�R3׿}Wɀ0��J�`�+οa[T
ND��?r|cau�Z�>�
�kk�v�t�E[2GY���ļ'�íBσ��)3=������H�Xj�j+dB��U�n̸���>m�d9��7�S6�&*����o������l���)|���P�D~gj�Sƈ�jr��n$P%C����]Ӭ���FT݉���m���G��X��@`�����^Y���;6��Y+��ofJ�5y�R����r�,D���u��I���%�D�eA�m��Uɭ@r��7�_����\��-��歓V���͢Pw[��6���}��=�0�\��� F-������N��-�X�W���ToY�&�����$S����h�ɼB�i%^r�1﷗YQ�r#Oa����<��&M$��P#w3MOI6��;ϒ�Y5l ���w9'�s�xp�M{�#�pA0"X�G�QPs(�6�\�Z�A�\���֓���"��T�������P���]����E5kI2f��@P�e�r�o~U���^u��Ys ���=쪩��ٟG�3������Q�L��d����5������6D9�O,�|E�%@�m��i�v	�Y��S�[���o��_#s�� �ݾ��3\�dK����R���F@�Kr�pdi���g��eB�c׶��'�p�R]aQTñ]�-ѕ_�������fZ�����8�<dY�1џ�H9nB��*��Nx�虨2��x6���AcYE��X禙�!�����[�T�4��`�]g���^�)XWp-�g��c9��V��2,]���jTA��"�f��0h��U:��P0�Y��tڹ\��ӓ�b&�?*i�B^K�����#L���5�߻��.ʍN�=!��Gb9$9�wׯ��w����.C�q�o!$�{z� �)ҿ�V��r����h���jz�OkQ���R���N��F���`&�|���8~��>�pNv��1/���g����]6�ؤw!���ŰMHֳ��ZW�`���Ƒ��F�A#�kb�85�<r�$�M>�i�A���i���h�^r�KyC�Z�1ͳ�$�����9��x�V����C��P��U*�D���᪻�8�r����|�0����Q�zB����R���s���߃>Q�<�1��E�䩓�I�5C���N�J�X��7k�T?����?�Ubalx]x6Gϧ�Q�]�D��b�J��v��wa��/\&�ֆ�B���ߐ@O���d�1���Q/ٱ�h���|f�Ra��*��R˂ $�l!/nPc�5.�>OW%��_�E1�&�=H�%�`�Z>m�C�JE��ҶLj�5;{���e��K�N����z4ut7b���IA]����GZ�2�.����{�f�L��c�ή��~��;=*�CS���2��@��Z�����tEi2�K��/Y�F.[�sw�m�\"vW�������r��ցL@di~�@�o��S�,����~0�cr����[��]�Y�H@�狎|F���-�I�]�R�8$P㢔�d���"���@��+�
����%w��<��l}���l�u�Zu�h��3��t�7�N��������N���{��E07_k|��q�'�BU���ȼ&A@�T+{SHt(u�m�%U,���xI��ϼ��t�h	�R>Yx�N���o o#
~(�꺫�v�͌�Q?��:�7:��E�uTGn�q:B��j���������f������ۜ>k>k��8���/&M�(�b���g��(���z�R������_5�"X����-�����6��1*^䁃�hi������6"qL�R��f�m>�	��!+��Ɍ�l��XOr��
�2����bZ�}���&��y���D5��?]jL[`��D9z�3�L�0�� /���%�y{�V�,U:�V�n#�=7qr~�~�(N�����(����mŠ6�0\6��}�5�
�H��>GX��1�׆[�gJ�͢Z(�H�B�k��sY��7kl�d�� �������i�k�ى!.�����#N:�ڒ��\Ӹ|-��5aq�߇�o���<�,���'��.�{���΂X�3�ݭ����Y���TĔ���ݘܲ�������]&����0׶v�bbF�~��JP�[��>B�^��t�ľ�@�ջ/�@eP��}ZP�v��������LB��BM-�f-��%<�UZ�R[��mO%�U�=�Y��~{�<Gb�"v����+�?S1�(����O�-H稁P,G;�% 9�G� �����x����d��h��.����;O%���|�$倪��E�>d�h�|6��iZ�;WN<n���iK��\\_|bۣ4���)s"�������,����n�)b:�
�7��$>^sۚm�ya�%=�����p��j�B�bG�@�w����.%����R����*v$��b����t���A�k���h�Y���?�kKc�U0$��7��4q�l6#>>����;�Q����k���L����������*Q�	K��M�,U�sc�G^�1���G�̓ �G��Q�ͦH��۹�ؚ��5�7���:���5|�׉�6a��n�|�m���n��wo����n���;��"u���5k�M�����(�"�Ie'���M�q��%��"F�Z߻%Y�uʟ�f�?�/>X�.��0���2��)�S���C��f2��.O������]a���iy�d_ϥ8�1x �s $���6��~���i��s��ZS-$�(%ϧ>J�8�N<@Ud��Z�췻fE���6k�P$,sN�K����8þ��ذɓ-[��|=u=9�qm���܍Y�$�^����U
r�- ��=��,;���z�;1��Gp��(϶,�&��NYk��]8�����͹�-m��+�Z2�F��c�k���p� �,SMޮ����fCS~���N�ߔ`�$�#�^�/"�@]��K��ko�>"�p�����C���Nƍ�����o�N��y��R�vp��/L���ZA����݁R��@<:�{OE����oFf`w����L,�U^��M�Hp�q�q ���?J�����������=�0��-0�s�)����Z��$F�;�t�ys��N��!��˰|��Ӟ�Ig?7u���3��1$X` �)��	\�NČN�{�6��.��\��//iӁ�P=��
��2j^r��
��I��8@i���bg`ViScv�T�XcZ��.օ���F�6v�*�����X�;c���9��y<�����0���^�|��H��e��N+|���?_�kB��e%^U ��?���Je`z,�q�\�& R��q`~ykOE��}LT�$�c�a2K�.J�e�:�r�35�H�l���+.�ُ��$�09��b#3Cu����ml8R$�V�줒��1UN�d�v�4z�j�Ɗ�ӏ�����?���Mi�ޝ�ީr))�Y�{�z���VI$�X�}�Ώ���7�;���l�˖����8 !�� �G=Y$CuT���@�n?��z�++3/��<&�M��3�h��)#rwa��m�����n>h���^���3lԚ��k�Q���(1��[�B��ZL�A�u��W�ќX{n�knC�`&d��1��E��!��3ձeJݼqe� ���F�a�/�Wc�� ���e�_"q�+����D�J�>ą��毠�TY+h�e�^�B8�U�Lx�(�j���.�����7�k�H�%U���Qg)	�$HV$��3��M��ڙ?�`?��v�w�p���qܸ�7�x�	C����Z��r�|.v�(A')���po�K�[Yb@y;�xJj['��%��ɢ���L��Q&B��M���#͔<��qP��8l�s��V_��G`_��o��#��.�$<��=o�����p)�@���{
.�M&Sa�����i��6,�mq�=_!%ɦ�x%o4�R�k���+Έg=M��˨�|��}����~h`Adա��:��jO����N���m>��vl�ܖ� _��U��	b�Q�.s^_z�dS�}A}r+�{�-D_��.>�D��Xf��,5|�n���'�#û|�T���ylV߹i/�MX ��$3�>��@���w��f�#0���K*�4گV��n.XaF��a�ok�j�*O[p;J��^OMP�o;�L��~5\9��v��lC[�C6_�7�b�ޑ�S_#�6��B��Z�0Sy��=���� t$�^�0������^�햨����[]^��!2��Ѹa�O�4 2�7Y��Z�'��?݊�$�>(�]�����r{���(F&`p�tS gj>M���Ge��
��y�c��ze�a�S����b^x-e�H[��ɹ��c~X����0o��|��O��$<��@L���yR���6��{��xah��"T��I��)@�0I"ԑ�-���Y�d�p�B$z�sP
\%/Nm�+h���q��ZׇL���L��%#|�y	z�=)�jY�Ф0�(8-$<����	J���voYw\�&�FnJM��}��T�ţy��3!}@])�Ϗ0M���el�e%�{\8�L¢,ݠ�����6��&h��r��i�;��,�'�!���i���s���@'�RfJ�N�\h�����I��o������8T%���}6���Q�H+�؍&38�>B ��1�֊�����$����}��Y
#!�"��MIZ�jYb��j�ی4�K7�"�F���y=J���.� y,���J������^缾��M���6	+��T�-;+v�"���zD��c	B}�A�������!��7CF�1����%b�]��8O�oCч
d��V�S��Ր�]�ݐ�X���O�y��'&ՠ��Ƥ�e�k	��l�"�`ʥ��R.K}���z��c����n����yͻ�?p*���5[�o��X���	f)�fi�c^�͵�C���Ȗ>�F�J�<)��L)l3���}e��B� �	�?��8^��g�����Q�X��~f�E��I
y=~d�����#,P��T��}�<Y�X�=�#���F� mm`�%�A��p�#��W������d������"�c�zT^���бr���3��4 ���*���Q"q�{��Y_c�i�	���Mm�)EaR�2���\����}N��U�����3���sVѵ��
��Ź��W;�5��5�5�mm��zqΠ8���Ҭ��D��N�H���T3�j�U�X�ap}����J��J̖�p��gf�=*:d�"�<T� ba}F-V��2oZ��k�vQUG�Z����g��yx�<�0��x�éXZ]J� Wĳ��c�YB ��?�|�>f)_
R߶�,�{��7��:`G ���*���<�@ā� �U~��Y��(i�r�}�2�p�p����4�Qb���)�pp��\�򸬗�#M�=��9<��ڣ ����]�Cp�#�˰P� 6O8�~�l��@l,P�Q^A!�?)�7?�:=4M���W�~Mza�*�Y��5�ΏڕJ���l��	�IXA�g+ā
�T��,�$��3��*�"{���AGW=܅r�s���
��C{��	�� j`���Fkuy1?�U�?��KTDW����ʟ�
��^h�������T��*���6�3T��X~��-E��h����Q?A?�˯r�����"���K��UͲ���s�g\D��yϳa{�s�(��"�}�JbP�-����C��V>�&�u!���F�5�gi��l��];����z�}G�\���{��g����Xss�࠿��%S&k�v;�C?�^��ͱ�W[r���چ[׃�IB�I���=	�>qk{f��0hJ��Ӄ1�0xX߰�}i#��\�d�ZEL����J������ėk��U�n⨟(�b��v(|��h�[��Sj0���W{����t��z~}�nF�!�({'E-O��ͦ�e�[u��~�Nk�3zi|L�_������`�5�g��t���FI��{`l���>�(��]���Fd֟&�f·qo�"�ؤ�_Fs�d�5LQ$5����9��"3NܲC�d}b�d2�B1 �L��&�֘��2MN��5Ȣ����g3��vhC���|�����N��o�`,������\y�Y�6����=���4FUuEük�@-E;���c��-�<ݱ�W^�\Q���)�a ir#l�BZ�C�]7x�Q���T����}<���@YϪ���o���R���7��x�EǗP�
�Q�'�+�B,�R�Msϛ�6�"��i|���q�Rh�����R���I��Y�{��ܜ_11��c�ߓ�\����Nn�r-�>�E���BA`V���[���'��b��˵ۻ��AqZ�`(���u�'S���Gx��kw\�yv����9x�+y�~gs	Ta����M��ރ�Ѡ2K�u'��R��JY=����x�kE�L,m��%%ZbZe�*�<�tnp�xp���B{FO�*�qfif@���3)�3�Z��euO��vgO�\�b)>���9-7�ڊCv�$@O)�q.�JrzV��7�z5�]��<X?��os���W�\�]=� ���(v��%D��h�s��52d��L�c�o�쁹�</A�4���X��������z�:�	5z�d��5� �Q�e�(�D�`w�+r��C`�HP^9݂�@�/Q�&�|q�9�Ct��
K�@�5��J��xU�Z��Z0�&o����'��4���r%O]K�a�ۆp������Y�Aq��>�|����j�$�H|LR�͌�i��#3��H�d�#��I�)�����Q:�B�h
����a����'R�H��`8 ԍ}]	$ZW+55�~@����V��U-a����dĮ�Sjb��xF�2�l�*�d �N�k|��H[)�y�û��j����Z�B�52�5���z��ouE'Z� `���?�K[?mve;tav��˘8z"Ӕ�\d(���FFșo�1IU]�� ����?)D��5ل����2_��e�n��.J��	5{������n�h��ʽ�3�3�?�?eP���s	2�0�Z��~o?�<p�V&ę9����ҽWh�����L4����(Dռ}�w�
�QK��W `<Z/�W���Y���ߣ��j�LŹ k��;������h�?��k�w�]�$��h"]�F�5�U�Y���R�RБ�6��8>/*>����j%4�ץ���+P��l��j#!�^��S��4"��gN��|��)#8i���y+�o��z#ڟ<͑�iΉTY;K�3w+��\��!��W�Ȯy����jy��Le��Wz����)"xP��M��3�� /�����M�x�X�@�ˬ�pw^>e�<�lþ�%p�� l�F�{�(��݂O��y�}(���,*�����Gd�����a���*�B线x��8��0t��� �6L���ܕ.�i�7���o�"#6�|��"<j�j#��܋Y�.�|'4���2�F��[6��@Q5E��_(�C�@���Hl��he�P	���� ��)8��Sj�xRQ�cp|����?/�Їo�/�[�J�>b���j���+\/�U<NN� ��� �A�%!�L%�'=����'@�K�P�#^f�V�Ժ��@|G����\��bo�Q���b� �U�A��3�U���Ej�FH�@�.F��I�(2��C���U�`_�{�K�d�,�N��˄"I< Z�f$���#��M���k��_���N���`#�)�ˇ��	F�x�F��ӭ�u+���������E�gZ�ܨd5�J,��^	���N���~�C���P�frK��J�����ߺ�4�x�� �E�s<Ą���m�q�����Z�%w�45P!Ň���|���} �k*B�[�5���;5�d������R�Zзy�����%�^�M@:J޾=J@`&��7ث��K���m�����=��T�Ùv������������HG���yZ�qd��qd��"��`6� 0މ���oع�T�a6喐º�dVZO(��Л�rPfMǂMtͰ >5�`lJF�;�� %�PH�G����v�taG�R���2�GGV��#��#kWnJy���xL���=b�'��!�F��奭��7\�)et+�r�cõ̕hK��p���ɝ�Z\��/Q�V�D���sh���2��ϸ���a#�1Ul����
���C��`�m�   ䷅E^�� ����6�qܱ�g�    YZ