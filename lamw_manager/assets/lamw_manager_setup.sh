#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2500752553"
MD5="4de8ddcc164a00322e68826ae11a0792"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22780"
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
	echo Date of packaging: Sun Jul 18 02:36:08 -03 2021
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
�7zXZ  �ִF !   �X���X�] �}��1Dd]����P�t�FЯRQى��"h�t���M����vf��b��n`�*~�\�
��UW�CMc��tV\gLy*���#�\��[�:q�D�4�V`�7��G����̅�qJ|�F�9���B�א��npdM�&��H_P���V�E9e����%0�� 
�+ZFIk��)cܫE�N����?P��D�E��s�(�%����Dn:8�1�D��i�%�֨0�oÆ������X�'�3	�R-t��� �Y!�0P� b�¢ǂ� 7'��O|�m��>g���˗�� �2ҽ4 ���;^�-R��%b��w�{g�~�I�����)X�PR�΄]�KG��f��R�%�o�<C����軽n�;�����Na3X��/�Oߧ98H�r���V6{(��9�MY� ����sz����f�eu��G�P6�s������$%	C��5�T�r<u�G�'9ϣ$����u�9�*�I��T�ML'b��f�(<��>{���Fzo��y7}�#�Y�4YGI�|,�����Ȣ*9��QA�����Bb�7�<�^Z:E���u«�l��O�z��{�NG^�#��\�_����{P#�{��d~�=�	Q�v�6�� ��e�ῑ��D���c��-ygV�0_�r�oğ7�Y��߷��(..+[b) �)��ی��u��6�6Xυ ��}�^\cJ*K8BDϊ^0�����Ku�0ffM�ޮ�zzU�	¥J3���>�H��?��]}S�l*���U���3�e
*��L�_k���NT�2p�P��꜖�,V��1D�b��5F�
�/m8�X�4��S���n�EX�t~��҆����@��{���%
������T*��._:�E�d�=_Hid��х[�!�����y?*�E�y6(�J���ݤ�����I�Ff�Q���Ka�P�$e9N�Ro0�H&i��7�2|�s��]�,�
Aá�����K��F�0t���M� M@`�!jš��P��q�TK�p$�$hEw�`�Iq1�;���o�I)V�P�Dٵx�n[���M�tF3H���	�)η�����|�|8�V�B�'�G��L=�K7���'!���'����n�\���=�k��Y_dL���(��,�\��:6yF]�e����8��Nr�"I�W�c���4歛ݰ���0!HN��E���e8�;�E9�}�	��lr_$��h��P��(�f�%�$ Ja
�Q�(�Ӆ�t�5B��b��p�wAM%�ejMI�FL��-�/�cs���(|+��f���o{�㻌h���f�hb��YsG��3�(o��� d���A��Z�*n��Q�y���ҧyo3S+���ƅ_䜴Uӊ
cX�p��#A�.&�D��b�`����!X{g���>�0!�����B�缍�=�
�g����BK|�6�i�	��Fʅ��4�2�{�Ю�E*�v��P�@�,2��I���#-�@*&-$a���y���d��ah6�ֳ�q<���eFunj�<	��?"�yR�W2�w�BJ/�jZ�ϐ)6XS��D"zz�^r@X��e�6'�(�7*9k�	�q�yD>&Z��0/ ��(N0��#�L�1J<��J�t&�(�*��v-�8���_K��O\�sB�xTт��a�?���f����M���x�-cw�	�(qN�ٶ��O%��x+tH "��s��u\�6��h>U��9�^��kk^�RDrvB�8�������&�ʛ�y��o}ȵ�ߢ�U�p_�AU�\}���3\}�v�#�l(5J.[i�&�s�9B������e��f�� ^� �\Z�c�~��g"��8��'F�ڏ}��X���N�V�j(\ҧV<a:���F��.�Oj���*6�t��L{9����M� 2/�q�A�'��
$�Qw�mޤ$a����K����|ĺ����W§22�z�M�J��y��i�gg�8x��V�[J��9_'�����lc�D��b'�>�o�q��*+X��0n'ɢ >ƫs8�}���K�Վ�@Dk	������6�\�5�+ ��;>7h�xB�Lʾ�ؔ�hL��Ħ����U��Κ�S��
+��������ޠ]�i߅���͡�f7)��=�¬�����uyd�󂫜�X��X�w�]��1�Uz�oԹ���a��X�.k��ڵW������V8n����Ԑ����EH:��j,p-VD����%��-��#�o�{���
����L��	�4U���Kv g�����<�c@�:�p9��ѕ*�Ta87;2WqM����-���ʓq�Q�4�؝��٩��\USn��"f*�V=!8�߂�Ha!^�{��6����C��
&��琇��
̣�DLf��}���xu*gI�*�2���z�����M���lp���g���ڑc����T��=�dj�ǧ�U1}JJ�7��%�7ݤ�e&�;�\����aX�13�}�v��d��f��?>Z(����znjh]}B��� N���k��z@p8ε�T� Q���C)R��G��A?g���y�� �v��c}`wTr���U]'c�l,���S�dl�u�~���?�#o���f��?2�9W4���]�0�ECM�F牸 =N<��ر��� �J����jһ-ܱ�c)ľ~̷/v�^�'(��5����O�03��/	
r�D�š�������)��N��y�:#h��_�~!�i�&^"川�tZ �V�*p�/��?��+�Y�~�(�y�g:+?�=1���wT[�%��7����H`M�UG)���)��nsْ�8D9�PXW�3Bg}��0O�{!m���y���m?�5�fT��)�.�CW���'Ɋ�sC{����h촰�`��,�DdR�'X/���p���Y�|���/m�ȑ����}G�h	Z3:[��6a	~��a�Y�]�,D�DO
���,����XGe[�0B����z���i=�dDFoՍ2Պ;�	p\y�{����k�9�$"Di��L������ W���/F��ms3��S����Hz�I-�U���a�k�����Lkz�R��4�ANl]S::y�a1ߺK�A#�G=�Z-v*��C/��젎Yo�x�o<dqup8��zAu��m�ݳ��n�����eZ�:[5����s�պ���S\�s��;�a0=$�	:�a��s�2���TaG��5	���Ƴ��7(^;-�o�e5`���P�3�2�z^�wG����P�б+������[o��?8O$$��fT8��_4�r^�d����ͣR�����i���,<Mp����j�S�'H߁�S#����H<ap��hk�X�᐀������-_����O)enm��l�\�\�p��\�:�>H�U�Q1#<��$q��W��t���bz�b�ڎ�,]9,�[�ʐ�X��8\����k��a���b���I�:1,)����5�^�ì�މl�xT�%�6`�,ӹ��gL4��^��|�^���+&Z���������̆j�aMs'���1AM����e�#��Hʋ�f���!�/
ca_0yD1�U�&�׺/��Ox��+>����md�oO,*�xy�N(�e�9�G;�_��t�+�cX����m�vg&e�I�x��qf oM�W�j�q�s׷9�^�OVZ�()_��~��57v�e).�ϸ�;J=��Vve�J���ꣶ�n64�Qo�U�f���5�(���8`.�M��BV�@J��;�G�si��~�B�A����ޚT�J���4}me���֓{.s�dКE��D0F�?�u�� ���|�xd9�Ϻ���4�
��K͊G�� b�B`�~p�*z��,��YR�c�D�V�n�w�p�/���]��H�_�&�#�j��4��yN����0�cRH$����ǫzQB��o������F0iYi^}�6d����#��_�d�Ģ	L��ܳ&�R�3ۅe�{�T9bAi���l	�f-����9xԸF�'=�� zReI�S�c��J��+(�R.	�PJ����}�9q] rK=y�gE��x/��SG��&�:_*\�I��V܋,��~��'HQ�$!^Gx��u��w�,Z_����ݗ��9�
�Q�Nvf��qP�g~�����/�ʓ�7EY�4z'[�\B2�܇G����u���&��]�:��s�V`5'��f�����l#����s"�{�^p�V��2ȋ(;��јp�aya�Z�|��&�:�;_|��U�������"B�<�;��C}�7��M�W|w*��o�4CX���I8|�\���ZA)�J�
u�c��������!�;�����i���-�F�H�g�v��(�V��8��p,�P��wv�5�>>a�.�]���Q��b��
��r��ܢ���s�6z�Y;�)�����ʬ�`ք�1�ҭ���wOUvq`{jW��ޗ��k��6_���go*�	���;B�j�(_�{����}8o� �6�GN�Ι0��{����UMt捞Z���&�
��gxB
V^����jp������"`�w�WI�͈��N~�J�ʥt?F7B�q�rKg������E�����1�9�n	H��WyE4̌ec�x66/�'O�=�oyGY�Q�{�h�4��픱w�m���GE�x=5�#�c�$���U�M/n��_���`)�}� ���?w�J��-*��zX&�O�(�[��@J�t�f	V�j�G��J6˯^?�I��.go�9�|4�.�0K��E��Fb��#�4�ȿ�Oa�1F�'
�$�ׅ������'"F��З�������M4�Q�.�1���M��^[�0�Jʳ�g6C�c�� [q���s|��ǩ_�Z�o끽#������Mw��/���P�{�g���ؠ��=͉rZ��������Qr0[�@c�����30�?%a"��+��e3������4}<gJ� �:��ڤ��"p�N^�V��[��/^3g���G_y���fQ�S��cu�s���X����������DWͷat�Ⱦ {��]���8����������� oN�+����C�ڢ@��+R��|7׍6��mQ:+U��2_F��2�kS�~lL�h}��m �Ed[�q��)�Dp�RZ�B2�Y�m�<gl̟�B��B]��x���3@�t3491C��
	uֹ����;:9v���	�
�}2����JI*��@0�鰖;�/�&���A�:��ߏ��10<����p���݈R'bD1r��K�T�Jb΂���6�`��y�� �{�ϸ���R�����n���mY���vrxH�/T~Ž;Z���(�}��,\!mi���U{N�F��K8��0Ҳ^LD�ud��z��L�1s|����I�Ѧ��~��=}ϒ��vP�]���,�?Z�ә�IOe!�=��� )�:r���w�*[��-Z=x(�r:��*:WĊ#U��0�q)���s�x=䥫�?w�m�\R\�ڸ��8��JvD��S����X j�6E�`����Fg4KG�B(���D���w�&;Qu�m��D�^S~�H㞌/sk�I��:e~�W���o1x~�C�b�A+�#�-=5� ����MO��s������IdGU���C��PS�90��ϵ�÷�G��0/�D�a�#䳴Q��R�I��J������K�'k�9\���uwl?��[�m��J�_E�[S|��ˌ�em��zYv'�Z��Ç)s��\�k�g#����I~^�L�fd'���jbk�V~�x͉d:��}ⴕ�w>�~�5�����K�>�0��Ǖ���y!>�+�Y7���р�aW����n���&�QYڡ���{~�k�)�K�{j�Y��F�Ԫ��M�k���j1��J�g���i��T��v:B��^���l�`T
������1kS��s}�Qġi_��m�	f�2\j�"�oj���MU)���&w�4�d�ڻM��﹟�~4K<��e�v�PB���"�sI����hR�a�>�s�b���z4��X"���eE�P���N����~=��=8��4�C>՛U��w( �c:Ҡ ��L�G�U�L���"x��Q��$��v��Q��i������(�QX�q.�8]�ެ��ڪ,�����W-�Ͽ��-�H&3'e+¨���D��Eٍ>Χ	.�.O7��Jd�fU���B �C���s�E.:OH���e��ey]��iG� ���r�����Q�P.o�\�tF���K��{M��x�˪����ɕ�����%�}��D�;坁!��!�a[��i��@���K�t�1gu[vdC�/O�h�����Ւ�;ZZT-軥R�jh�=�e�,e�Sؑo�h;�P}o�Ca^�:I��n��~�-��Q
���Έ����[�e�ž���`N�q�µw���F�M���85��f{�@L:�_���v�] Bk�%��j�/��^gi0o���Y��,��եW��:��c[ޘ4�X_�m���/r���Vc�,ݙ�ٟfb�K!�>��gA����D�S�wXK���ZȨ��G6�>���fF��1��7�y#W�:�]U�?����Eyk�ڡAUb���(��?�.�4���l�����4F?)l �xX���?[!�S�/c��E|Z��vU���o\-�3J�|p�J?�����T����*�n�^&(��Ǹ��ʿ:ID��o��kO�6��N������ϘPKHߞz��CHǧԧ�oc��9h�2*��e^x�3�J��+�>Û�����ҷ��j�\�;�)�������?��c�:\(�M�7��k�.~��,\s�x�tU���S���)/D�x�_���OV�669�ʿ����w�������O��F/ؠ�0�א}���>����x����3�Ju�/'�	��
�NqC��#gYFk��Jy6�K��;��3�[������C�r7ƍ����^��ܻ'��K=�' ���-"�-f�K�ԸJ��'cVr�.���`*0���S���I5���w��5w�S+�-[+���+5gǤ�b˯�#u�T.vG�	)�i�c���u��8^�8Mn[�5T"�4���3�W����-hS���Җ��Kj��>�qK�:�)�:���CطLWn��R
.�G�5K؛�Z!|����;���w;�F/&M��!P.�\�.���6te��tR�s�*i8bƷ�t���1=����k�<��;;3ش�b��ӊ^`	j�ܬ�m�����vYZ,w���E%�A,5�m�3�c����®vy�.� �y�Ѐ�`�`Izǒ�Px���8��Q��f���p���� �)G��o�O��U�D�1�j �7���w��p#�
.�PС�ntHj�&�>��u��;����u�u=���~���)�b��oh�,�W�����f)��h�5y�v������ =�b]N�Q���Cq����:�M�eK:.��� ��q����4�>L����q��7yۦn�������_?���Gb���z*܆��'� ���1%�JeQX	+}I��J���y	��w��ڟ�p��#��{�U��ڴ?���׀�E�d���M��x��~N藸�����bO�P4O5)db�!hK��Z��$�V8���� z/��~�׎b����490����݆����9߈zT��f;7�~�v�e'�W�h�X�Gf�!d�Ev#b!�B~r��Bo@K��;e�IE��R2�jeM�f�I0K�(��}� W+h�t8���9&�����wYs��O�E���4���d���4�U��Y���g���>��t�_��:^ŭ3�w�ϒ��}�n��A3����m���_9S�ƭ��;�S�.vh*x�+ORJ%�0���Ԃ)����s|9�@GP}�.������}V?Fb�-�C�Ukݹv9�c�&�YI��nv��t���WwH	C9�~�RB���"�"m�i��>�@O�v�"�P<8i��N�eX�;}� �0��@��Q�huT ������1b�_�`�ZrZo��K�0���+�V����x��+�2zKh�-<%�#���WA�O�D��Tu�vr6��G��d�x>8�]��z�de��~PHw��K2���-:�l!Խ,�l/6��x`6֮մ9ct�L�z5��4 ������c�1Ѵ�E��%�r��~��3�F���wC1��!��~?":j��hCE�K9���c��	7�GS�� }�9.]�;<�B	E��R`���w�L��'�2�V� "0���*7�"��� �A���-���*.�H�*;�]|qu�UK��C��`��&}���}� ���Խ3�%�_h��x�T<CyHr�t]��@�\�}w�z����y��	��jx�yr�����9#�Xxu����ƶ��/����-�OmM�@Lp������6t�`��tI�����VV)uѻ�V������|Q ^=%8��C���d�5�~Utu�NC j�Ĝ�!^��
�c���m��v�������O@�#8��N��Cp�����e�9D�!�'��%�h�п��D�(��ʱ���g�f]��E[UZ������5zk�N���1��[e 2D��i_��u�/%$�(^]ˠ��2�Ě<v�P�{F#=�<���l{Xb��Ȑ7��h�$u�ic��r(���7�L|~�fɓ��`�����1q�/��db���[�y��A�1֍�d�N�������Qq=B�}�72��[>L/3\=60S��^�?q�,������D?Q����W�6Nti7a�� �������|�z!@�����v�mHۣ"�j <|1 ��n��:I�&�^%�dt4+�p�P�s�&)���Y=���ܛ�AM�����/ã����z^\����%�t@�o�)�ݖL��F?��
�#$�d�).!Ufsu��+L�z����. teI����V�y���g���D�����҇�(�0ik�u����"����V�n$ap��9�Y�A�ڧꭸ7��$�ojQf	�5nF�HMl�ď]>��`��R�G��J���AB��	d?"��ˁi\^"�!NA�����]�L���Z�o�1�I=���-�<�dX�15�ىiE���d��Q�e0�?�mY�Yߘ��A/68O���!�
\i�𨠥�XV�F~�[��(Vhj�����+J>s�-�h{իY����:�*5#S�I�ە|	v+;/~W�g����6��Z��%����0z/�`Y�7��cs�,@�R�~�C:�� Y�#�B�3�\y�;�[߆
>(bPg�� �W�������&�B2*CqB����P�����˘��}�} �\b���'�d�jS�S�I��K�J���Ì���I���u��+)�J��}[E��T�Bw/j+ɞ�������.��o�.lpuxWذK]9M-�YG(��;!����E<�|&L�♣-�ԙs6O6��<9�V[0m�ʳ�K;l��_b�xH,[�����w�̰ټH=7/� H�9�>�ޖ����5��A���ｐiY�7�1�q �����塒!�M�z.wlg���X�6��?w��ײ��$?<�l��;�x*��_�s�/q�y�0.���(�M���gM8�8�(N��t��Oz��Nj�|,�d�U�#�T�5]@��Vl�� x�����	�Dg�J�kg�Gӥ���(o��̶ *�H$��h�Sf�\C�\�����w�L�Iō�r���8/��������^����6��	��|����e��Dv F� hH��)G��+�8�:��D.-���/�غk�ӏ�N{���E�����@��e��MV�<�fr|r�mM�m�*��^�u�Z��b���=�-)��pY--3�CV���wp�%�uР^�7�:1_�#7��7�A|w�
cě���U���HUԀ�[��G�,Z$�cڠ��/�,�3�rfQ�r����xK� �K���l�}."���y���R���J]��]�"gn2�C�m��s9�{�3��H�	)X]k�v�2I�B�9rڥ�Av=����L`D��et(��9��s��=j���=l����z/��hL��P4cN���@23�D
��n]���'�Xn�X�'h	�L&���l�L�o]�z�ƟW�z�����!��&-	�@��2s���S�R�@ �ݩ+�7��E�f:gL��(�Z���q�:[��(�q��a���ɖ��=S�bwU�k\`�F���-�-�֯���2Z�����c�tdUK��Ș�ዌ����s<���[������r�
�j����<ls�6�X��H�i���^z=T�Lk�oH�M�?��g���09��#4�3�]O-ikw����QS��!���D��e�פ"�Cߏ"ԉ�B��L�Gf���<�#/r�C���}JJ6{�nh��Wt�YD�8#��� Y�g8�^�}��o1ވ�}3���u�J�'
���R:��a��!%����TD �^��/����D��]����b���[��e$շ�X���m�;�ޒ�;!�1��z�g��\�	h�Q��̫Y�>�xt����*�5��8��oo�����\��͞ƴ737B�ql�7פT�4.
p�Yu|ĤD���D��X�V&&�6x��B>�1:cQ�l�`ai����]���tRL��7�4�
0}Ix6��~	�YN5]����D)b\����ᕻ�?�ũ�iֻQ�#�C)�	).���:�Rg�����������69X!��,.}�yLGy�ǧ�k"��Q���f�7��3"���o`f���9!{hY����/]��k�X���pJ$��lհ��(��R��OX�}��e�Җπ��Z��k�Y\��|��(;@���z� ��1Y��lG׹�"���	�>�P��]�GY�C�Q<�'x;#e�!���Ah�F��`��v<$ފ�Sz�*d%�g�Հxq�@�wN��\�R�|�Y���@Ey+5�]��?3�K��o��!��2//�z�\�{����[���"�z�wMik����k&*����B�(���M��sdf�*�)�j]c�Y��$�-`�O� �ܺU�AV,d�@����|���%��k�%���jo��'#,�����OЉY�L�h��� Q�jʧ"|�]8k�p�a�~� 	T\W��Zև����5w7D���S������u�<����y���~w��)�<�ـ������������ۃFv�J����*��Z,iX����[G�ؙ�E��g����e�la��Jƫ�䄋�,��>yy�hmQHrV��/��9�u��$c��Hb�����Hd�I�U|T�H��r�6E#,��.a�H}3�Ej��U�zg��>�W�)�C#�C�"���&H'?E�G-wȅ�q)p�������gf"���wȦ�}��=� ~��8�h�����ܜ��am�S�tC���L`��@KHOj�FwNJ��?��h!�k��|�+��:| 5Ό,�b"Sh�PQ�L�j'r~50�'��*4÷��:TiE�M�W��rc�^n5p/d~�#�-��rS�PhQ;�̘��e>nI�� �q^�Trp3%�8�Z`����4c�X���Zn4�Ƨ���W}���$1�}3ǣ���	]����*Ϣ.� ��)U���EI���<�������bq>-��w��M�P/8��M���ɫ��׼9:�� ���C6�s.e3��Ď��o�U�����ʀ�JG^乯]���_��3�>����s���33��F��HϞ+��U��މ2��~�W���2�&�kh��4L�� �3���I+���y�K�g�(?4g���S�I�B���#��<%�֭C��;!	"��W6`�UbVo���t��Aް}{��Ӵ%�#�MeJ/'�@�{a�f^�aL\*�;��e=>���3���=��i���T�Z����w�΂��<��U�d�1$���E,|$ä�p t$o�!:��1�L3�0��5�C��_B��N���S�`�`��!O�Y���4��¦�������s�h��=���	y��|oM�X�Ә�w��)ڪ�Ѳe�A���9�	}��[�)wסU^I�j��A���h�vY�� ��7�8������PƤ�j:O))ѫ,!��e%ڮ��Vg����ͼ�R��&�,�)�q>Pۻ~������Ĺ1]]��@���Y[�ƿxV�ݠ� ���A]����ZyA�	���E�	\|ked�#�Kz�&�Z.�I�2<|�*���_3ӌ>�3 `j(��aM��ume��Db��l_�[9��}t��+�m���?&��ón-Q��/d��+��[��%�}?�&D����S^��� N�O�[n�|O�`6����\����quը�e~l\#�aGƇ��&��lm��|f���5� ��S��ߵ�I!��i7vV�a��*����������>�Ua��o� _�g���I���W�1� ^3��[: pZn�G�:��.�%*���P�}�Xװ���v���M��� c�G�%L���q�dE��Q����RT}��_2I=t� L{��9X��v����媀��w�+ )*�1��DNHp��Y�	r�-ݵ������(~j>3����[|ljג[9
AF���>�z��F!��/#��ț:��[�(��}��Abq��UF���8�`[�� (�0�����h�@#�E�'�jg���LR�V�#C�ƪ�t ��I�������6Ӽ � Y����nZV<��g���,��t)ÙJz�R!1������ �,�	$Bn��I%�vCgI+%�-G��� �؈�On�9	CN�KB��eT���3��3�Їְ��tE�E��X�4�ḏA�H �T�o1OK���&�r��+J,�83���$���p,ͬ������0J���	�@�J�� F��,Yη�CcA�8�\t��� ^}�'}%��@�'�
���?���'��l
����.�ޕ�3�o���d��Q4d%�MZ��y�Ά���/���BG;���ʈ��L@ݳ[��{����j��JB�!��(�u ΉGF�Tkrm���_ߚ���Wߐ�F2��ݲ
�<ș�?�W�VS�w&�����P{�U����4��<Ŋ���'�,�L���g �I���+��N�}ADw0�T95lSb����TBm��g����/v��w�_��Ip3ŋ(�����a.z�t�����G{�	�+.�?ù8M��>��=�����m�pg��Ͻ�& L;}En��y�+yT��ӿR]�m�ˤ��r���{[`��O��V,�S}g�����z>E�r���m��6�C����vP�Y�fRɶ�awI����IY�w�b���
��X���٥|�P��V/=�~%��ǌ��ÍU��j�;u;E
��u�3�d�p�(ZF��5�a"~ ���nƎX1�3r�������BG'�c�0%�8o�K-�M��Ȫ-�m�U#]�A	���zQb�Ā�+�%I|��\�<Y^������V?~��j,��*K���Q���G)(y�	� ��E&/
¢il&���u\����ok���yj��B�%�|�~?��°~��p��]fH|(�,�x�4r����:��8��jRB��3���~(Q��Îh�e����l4K�T��-U��FG��pvmm#�"��C��;eʬ�doz�|��L�*��f������X��O�>�((B��e�j��2O澲�Z륤��.�Q�U�&!�)��x��ݛ�7����T5�k�e�9v��:caa���gǢ^�>*LG����W�hk���'B(Z�Ѓ��� ����|W�Z�_�ͫk|�벯���ʘ)L@x>���u�ݗ ��5#�Y�-�����_ɤh%W� pM
Mj}�P��=<a\fN�>�I@�+��#�-)��j0�t��ۋ����q@1?�Ò$w;���7M���pfNFH�ǈ�m/�U�ܷн`��؛�`�"�y�z5��&�"�v�K��s��0�G?�'^	���Xe[N��QeA�'����{JX����_E����^�
�lZuΐ�h���h����g[�ɾ<��q)yb�߰ǲ���2׊�*+�=�L��Ey��@��6�8�(��c���߁9���M���ͽb'^`bd�n-�n�0��D:�I)+�e�8-N#�X����-0���J|�>F�-ꪵSq�5j�v���5�ރ@��F����*�?o�4�s���;U)��k	z���	�V��r�]���q���#?�a;AmO���]ޮcE��f5����=��_�5V#��c�q!��<ӓ�L�b�]���K[��I31#��$� 
3���
��M��n!�?����lT�>3��pS�C���N}����o�b�:��T��(�Z�*�EE;�e�c���7���h{	�]��zu����nVJlN��׆o0�����Q���Ɔ�O��Q4D����i:��/����;�dߛ�6��24����o��0����#[�{O+O�'mg��,� ���B�flM�������$��,�&�x�wfk`Zo�s���G
�sH�_�w���r���&W�5�����'��/��D��M�/ap�� -��ӓ������V@�����L��j��#!�|��)��r�N���p'��+x9$#�f����������u��Z6NA5 ?�"W���6��m��s!�d1'�4v�
�J��w�R��ݧ�J�`	���D*���L��{?8?kx��yV���7�ԾE�e(̓�Td�|�L�Sb���T ���Lh"�K�%���t���<�X�p^�%���}���P�ClIQ�OϷ*�S��9[|6��V����?\lr�)���6��m/��C����2[/�1Zn��{�Oc��$�){�z"�х�,�s���}�ȗr�5��u�t�K-c��ur"��q��G��S��������s}��*��g͓�3[��^���~��!ď�ɂ^ֺ������O<7K��J����ZI�����2X;G�1`���QѴ�Q+�-,���'�F�����|t}���6� {��M�����
3%�kx�#1V��ٝȱ��F$����\�.�P�֐�(�J1��u'Q�'6BD)��R�9��̡x�i��������ŋ��<E���eڒ�:N����Xv1RS�6h�Zֵ������!d�2��,_1��Trs�E7�t��0�������1YIt7��%�(]֭���n�ۻ��nkC���"���Ȧ��G/	�+K@πL,_�Oȏ�O$��ӻ�����j뚿B���LN$���SKP.Րaň����4�y<���ٕ:��b������;$0�mGT��� %!��h� 	�|����X�M���~|���������5����Uբ]qR�����Vh'�(��B���?�5���H�!01��.��� �hS�I��&��O���P��)�F:�9�ޗE2�HR�r�ak+L*��c%���T�rfX+kG�A���Y)�|L������}�9q �"��R��ʿ!۪���'�_	��"p�å8z�\�4�&`Y΄��V@�~��W@�99�]��ձ��~p!�7=����E�끫74�Da�C����� ����#�$ܸ���jw�u+��ϱ�E�c�����Z'�Yeוh{����a�"g��=�1;o�	z\a�%(4�pY޾���K��*�Se_�fPm�!i�w(܌�5�����dT̿��A�ڞA�8$�e��<x2Z��BP�u+�����B1Y&|�� � �3$�֜}(}��5q�@�h��ю����٧H�Ĕ�i�IY7�� :+.�{���|x�aÆ�?���5��$:�^{�S����O7%:�E�P�Cy"
���Nu�}1��}���~O yn�*�z=Yy&Rʟ3G_ސ�ZϓtoK%*Xi�o@�+�������bN�0��8%��M4iV���]�3�����H �1�_z���h�w�A�} ��O�>��)pu]S����!�ۀ���}��D��o[	oM�+a��A����Y7h��	�.���f ,J0L��E� j�Qr����1�H��1�5YOH��w�G�nY�;�؅�qg�an���]�tE���f-��-W��	��&���F���1
���K65BF��G��Á꿐 ��V�M�͔��FM�'��R�<֝���$�K�Ӣ��/�#ȗ��i}��*Ph_G��Q*Q�Ut��I��lp��;����d����]��c*��`̀X}�5z�s;HY�T�[$�v�9���5b�i�BMY�}�%����<G:�\f���K w�F0���!0X�O�U�������8]#!ґQ�{[�J�V��̓��Y�h��ScX65�N��8�c'���.;I��Tα�k��&������3����0�P�rr�"��'3�cE�W�#�H�D9�*�j���x�?�$3Y�,/s�~�>:��|c���,�k��ͪe�����@�C9�(w�5br���#O���j��a�]�p�W��ӂV>��w׬={v��a6_f[�P���F�|EL�V}��W ��p�65��rO��
ya<Tkg��#1���	�p��W��E��Ae̓p�8[� S�QHc��-�'��0l.]	��>���|=����pHW�>���?sw��殬?��C�z>�BR)�,�Z����Q>a�y(B��Xd�&���?�y{��8��;��C�ۻj��Y�~�?��s��E��uk\���n����f�e�������Т��'��W�����!3��H���|��X5�������̯���}�]����,V�����̤���pJRsE��9�[jLB�?�0~�!�;Z�a�Ə�� /:"G|&B�~k�����h���G+E�&"-�m��'Ԗ�M�l���#�|Y���~��+i@V�&�dQӼ�a���۷�6���&��V��������4���5���#= 敆��S����GY-#]j{���'���� ܟwH>�.@z�iqc`U'�tvҘ�[���WfH?]���o'�������H|,�����ބ��>=[���f��y�YS���^���4�N9�W"!�.>�ݳ2���� ;��D��T����X�z��γ�o?���Å�g����h�Ȁ���^Cg<:����V�+a��~I��!d5<{
��H�ԣ�<�|]���h�IQ1�+U+<[�vaZ{�X㷵��>�o���LJe�����a�_���q`|���'&�i��|���2]Z��ۨ|�l�_!J�!�ߊ�t��Ы�(z�;!r�3�H�z@vB6�*r�	1��*力{�!4cDf����F�+��zX������%�^�rX�%ny�De
O<Aܖ��_���Fx{�y_���&��"K�8����X�^ש�jk�D�MH�z����ׇ�k��s
έH0e���TWu$��4K8r��Ȁ��dЪ�o�kqLKM���3'�M}�蚽X��6!���T�0���zY
�QP]�s�����9�\��p:��$��m��@�[b� wCo�8攘v��i�=]Hc�-���^FƆ�SGi�?��%yObZ.V����:$�4��ĀN�b�R�]�ďl�0j����牆��Jq�����QQ�}7I#W�(|a�Zh��,��T'��4�'V�&wJ��U�������BI��z���_��_�o�q��&�4��x�p�r�3R����r��M��f�l1�C��M���7e�m;�,��-בcR=E{���?f5�G���h�Dxt�^b��o��b�1����`�5�:0+%u
�jx�BW��9Z�eI���g�K`%�������nlq�K�x�f���L�.�ߤaV�e��Y��8��u���/\[ne�oÒ���v�SL�뤨�!�T(ƙR��@m��ȟN��Y���pۨ����$G6bڒK�מ�ڬ��� �Y��oW��u�D��9���������s��A���j�t���R���ίI���5'󋨂�d�.�x�s�7��F�A/5�e^��4kq82ݎТ��`,�TwCX�����0��C���q7E3���.�v>-���6��0(�Qױ�TkW'�(�B۫���A�����m��9ʵ���8o��_��zQXu��@�Vm��ʠA��_K�� �<t6�By���H~]���;x�8.�k����(�b�������.�_Kv�v�n�V����@�c�[~7���z,,���fx�%6�"x��ݵe���{�	Ho����;]��V^[���˲Q۷�ђ����T<��������n#�Ɏ��\U&��Y�s�`Z݌�忇��������#��5?�.g��|��}f�,]R�v����)̰����h[o+�*R�j� |�����4�GX�b����F�rQ!8�W$��r�^�J�bw:��bxƗu�~��Wʘ|��kw�ri��B��|�}�{�������@{/��[4��S�5O���=�������fTǹ]��H5,��JZx��uPj����$�7M�yy��}X�"��9������y�le��5 :OW�Re���5QX�QA��n^}�����L�E��9��|��i��n���V��[5�<��f�خjg�@]�10$�oHR\�EL�|���Kt����^#���ş��
�W��J*f�X�7e'�(�f���f��]�0��t�0�?)��U����7���4�^}�Õ��Y[���G�K�|R���jz�$�=LЭ�Fc��߰�9W�J�-�v{�y�lYX�!H�3ɲ���C�B��l�Ų3��I�Ow�*�5YZ���IX�5��Ս2z���r�vݴ7ʿ�c���g13뻱�f�Z�|�P3�_D�^h�[�ț�<��W�3�_u���H/F�rBvy4,���|$����Rӎߧ�"��'8}hɡт͒�1�=�����u�����CA���?�h>Xr��\Y॥�B����nן�g��?F��.��1�B�3b�qg���)�_{��}B���Z�� �Q3ta\.࢘�d/�XA�^'�~�*T3l�����Ĳ��ܰco[ĝ!��HC9��NO��!�v`c�HI?�����͘���B{�S��������o���řy�Du����O���X��bc��o@�v������ΆX&��� d�+	�*д4.�^O�}b����F�岾����	˫s9���[\O�v�B+6�S����8ӂ���}�ZH2�\�AJ�7k��?�qS�+��S�iܞ��k&_�M��4}V�>�V3��M��GO����/Bn�e�U�1 Z�6h��L�k�i��m�;��>W8�*RGu�Eh�H�Y$d���u���u[���a�%q��v}�����db��I*��bs��>���o�w�^��8#�U`�j5�}�iɛsq�y*�]OL��D�J�[�kȋ#4��^)��WK��K7����o�����a_����X��Jc�|�㠩�"πc�0�;.����8�7Km��X�W�B��/�bUD�Y!b����g��M,�s��0��Y/�=�&fsJ~z�y�mҚ��N��ynu"Ζ_QE���+�)��������J�5�����z��"���_�ڻ�#'�똢eR�L�����F��b2��n��.�E�|��ԙ���i��+���M�lՎIm	/�-5K��(�p�\��A1 t\���JK1rA����P�01`�U&ݨ E�GOZ���B�"�6��߼�dO���\xj'�T��UVܤ�l|����Ck���%uJ�# ��T��@�~���?�g��G?�yx9�`��� �F�*'fk��A㷒��-0o���meĹ��a��gV�z����$�c�F�>��e�v(X�W֢������6U��9f���t�-�R�,ㅔ��I���V�Z��RvhO�k�-^��F<���I�#��q*����G[����	�իΐ�I�J�5-`�N慦��54�U/6ů�b[��6�@G�-���B�v)#���6�'��qbf6ɿ��;��.8Y�8<�5~i"��D�:e~����wod��:��G�?�YN�$�.t}�+�_0�E�:�"����<2�#H�Vbط�}�	&,���Pt��i(1ôz��y�a��%�K�5�7ᆸ_h١윻��f�r#��d�����o��u�sZ��H����k-�g����+L�bS �_���L^� ]"��鳋�! �{`7��� 7���#�Wծ�A�P����'�&xc�
�]��V�*����
Y�	*������P�~�=���&�l�u��V0�+�x��vt�7���W� 1j��E���W_�$0���p����r���G�l�������f"��G��^֊ܢ��YLcV��2���'�3��&�D�?��{\��v��<0��J�Р���o��~z����Un�W�K�(�&f{�H�b�K>�D&����*ـޠt�;����wW��Hwj&O�Q)�$f��E/��!�X.����w����+|`�{�m�d�N�n�/h#�o�`�j�R�m#���_�nl�?tO�w�,{~�c���z3�Rƭ$�,�x�5t�GcW�F���J�q]��'���lM�S1@���óXe =V�M9yשwg���d�Ci �O���_�qv���4�0� �d��d^?g$�{-O�w�qBly�[c�8�6�"u�c����T�8��R�c�����I�s���0��	�s6'������m��P6���*0"����-!�����񢍰c�.L���.�L��B#g��GrP�~��6�Ơ��&s��O:�b����z�T����1� �ѫnٶ�F�w�׭��$��?��-���9Xw�أ�q[*!T>c���0��=F�z��Ǹ6z��Xnf��
8�sA�!@���;����m$p%�C����ev�Z@$5j�U���Y@ȩ�ɢ>��:����2��%f��Ϯ��Rm^�x�/�;�0r��%2y�8I\�0��T�H鑃ﴵAE�:
d|��.-����8?�;Pg�eA�[r��xj/�#>3��<���n
_����ciԲ{�C�y!�l��f*����D�#�1���H�Į��lC~M�#}����ˑX��©1z�#j��k��/��u��U��鉏�DvW/��-��Ӿ�J�>�}Y;?�ik�Å�x@?,�\��^��
i���1ڋa����l�k��۠6V=G1��2�p�C��f<a,�xV��?쇼B�a�^�N1�>ڢ7�yO���ih�aUԋ��@�����iL{������]M9�"|��6>���vG��]S7d��?���`(��r0"��*���"�EK=�8�!�'BA+��j�Xo��*�>S�P�L-��ȁ,��İ��O��s��P�!��D��t ��C����`�`���%~����� h�ӛKN��KMj�B��qS�����|�o/��x� {�	�'Ub����!�c��wڶB��ٷl��Ģ��W�q��l�"ʍ\��Z��W0:����I���b�Ѡ��@3}�D���ƑyĻ\��I�
tM/v$�P�
;�Iu�J�h�3\V��97Vk�p��*�T#����,�oTf���S�� ��n|�ÛOw:;���%4i2��H�>����f.}W8:�)Hm�}:�:.N�{���B �v\?w����fE�s�=Jٱ�U���Ȉ[�4 N�Q��0_
M�N�Q4FY�!o�R��?jO�r,%��+OƄ���aZT���4�t��t=��8Y0�z���<�[#啍�3,�[���
X�K�l���/	@:�B���E���+?��&0�	"$�LZ��q�U��8�=����
n.�%*	J�*�=9�|��h�d@�%4e�AbR�a�������DE�7�C�#VB�Lx�ei�0�%���B+5f+%����2o�2a��u3[j-���cW�C��C뿆r���E�*�t��Z��VW�vEs't�R��89G�~�ҭ�M��2N�0��t��R��Ll���ޘC�Ȩm�7�B�����_@��"'��>sO��H��v��s�l�4)r��[>4����Z+�@t�M��^ S���2B���A�'Ff�	\A�8&{^����������0d�R���[���J齪k�&'I���l���a\�p��T����j�̌�K�v��&d��.x�1�z|���l�E��W��w)�B4�-5���   �"�~e r ֱ��&2Î��g�    YZ