#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="21938011"
MD5="72c7ed583a1c705aef3989a2aee00719"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23324"
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
	echo Date of packaging: Sun Sep 12 22:28:21 -03 2021
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
�7zXZ  �ִF !   �X���Z�] �}��1Dd]����P�t�D�of��ʒ����R0(S3��;�x�P-�{�d~�*~RV�~L���	�uGۺ{��+V�@J��B[�X�掙�Z���c� 1:tQ^�%а!sL��[��i����I�}0����s'p�Q�(̤�J
�����|ThZZ,J���(oݯԯ��ib��s���G�O/�V��������Z ����~�gUcW&�\ayZ�ڌ�9�n�1��!Z��1�|*Wt`|�S1\����ԓ�/"����:��ܫ�x`Wt��|o�,0��17�sCwx� 6s%
62��� �a��,"�U�U�a�R��@��𧰯ڹ(��� ������=�d�Dl͍q���ϿC�B0Ô9{�ֺ�`i���jׅWV� ba!�97�R�-��*U�߅ET4�G{"������gul\oe��&�^"�-��
0��6���ۼ�d�( �����1:�]d�R9���+;g�a�3{�`�B�-G�2��o�u�_�O|�Z5��2��-��m���Ίb�����yweO|I(f�)U�>)P%<j}�j��DRˎ�>{�ȟ�t��y�կ��K�ߘ�}·kΎ��R� #t2a�-�:��g�T��f��pWJ������o+{q�hx2Vh�0��SH\FdL*��Qz`���o��T&L����ul��ʠ�,�����c�Ü����C$5�tS׏	�s7���j ��{M`��N��J:��%�GV�xT����{�x8�,[ �b����6�j.�ҋ�Ti~o�p�"*��p�Z~U�W����jdi����6��i�ι��_��Fj���g:�?�7x��	� �cvn5�<�O�:��O�-1����;�a9��M!F�3_-v�^;_��� s"�M�Y�L!7���S?�"Y��O�X����ޢm��I|�ka��Y�-�ʤ����8��@�m9�ٟ����|%j���!���({l�_��4�Q;�@{f'_I{q�{��	S�f�]/��s�G�h��ғ'q��A�F���"�.C^�;�_������̌����	�dֶ�W2K�b�'ӹ��h�F�����Z�S>�?�X���4��ŭ^.������nyQ6[8�c뼤H�`��R�d��s��JK�"o�� `�G�|%$��#�\{AmU���h�։.�x��yԺh~��*cV������5��������(S׸9��Ր�2�olu�;���c��3�rX� ��`C��E���u��-��W�#SoLz��ژϪ#��Y<�I��Q����X;6*������ֈ�V \�����%�>H���Z���_��=���5C���ɿ���0���i���FV#}�6���kc�dn��{*��֤��/�\����Q5��T����Ӑz��"��?ƅ��h��4��f��n��5��$���ʒ�9wW������X�c������H^��:3�m��x�D�J���$d���Un���@���]ɼ�ׂ�|'�2�+
����#�I�L���Mԣ�+���*z�3V_���C��ed��+�<y
Fl��B5�=�s�0���PP<�+� <��it�D����
=�ҷ&��Ք���\�[_��=4v���/@0#fnWl�?OV���c~;�i�����Kj�'���'�e@��T������\����e'V��?m��أ٘�
|ռsIЫ�'�eFnX8ڛ�KC-��͵�\� .���K�t�=���+����XG�����Y�˩��J�6���= �B���\�e�&aX<�;ڣ�ʽ}/���D+�L$y�@2B�/>�B`%�ͣT捏�����a\F3(�H:�5i�IVHS��$�\� ��-Vk�|X��Y�|���!��Q<|��ͪ��ڡ�h����Q ���7G��ѓ� p\JYGXc�ϷD�o���J�My�>G�p&QB/��l�R[>�����ک.Q�N�̣�ֽ�u�J|�z�&�y��z�N�+)�v}eHg��e�Ӯ�pѐ{��/ �[�=e���՛Zz���+�~�����Zf??�H�@��-:\~�/y�l��8��*�X(fU�nk��=kNz�]M��
 �􌉺�\:r�\��3\���ٓ?Y6,E��B���N=�;M*���K��@�Gr�%rf�ɫT��Yo����<��+�@`4����Q|�i��W� �^ޝ̺<}��������I�8� �����b��Śd�s�XO%_s|���W�� ع���罙^A���k ye{d��35yu�&��t*W�м7�c��Ӿ90n9M#a-</�k^',�� ���`��p��&��( vv�nt� �G�iAψ���+��6e�0�k��������t�>�{~�AE@�m�]�r�*v�[;�´480|ym�c�D�d���׎��7�9���Wf1�a�@��r�����w��˪��b���ޚ&�[T>X�����E���;�o�@	�4��7l�)8���DG�z�hm��J�t�	�!i-7��\+~=W%�v�C���A�kќ��h�tƙY���	��쏔j-�ME�-��W~��v���I�x�xA�c����Z�+�9�"��-3vn|(��ɋ3��q�r[ FI����v��F5��o�����N&�љ�Ku��EloQ)�!���= �>+�
 �P&C`�V�g{��lf����T��(3]�H3�q�E�P�n!{k�W����L4(%y��D�aI�Ϊ��1~�7]��[^����[p{d��Rfȋ~%gՍ���:�f�A�Z'�qNK���3gй^���S� 6pb]�H(��قL��\$U��Dg���|��B�'5>�_X�j�6p����0�7D�C�JW]�� �dz���h�VW�FQ�Ppr��ש1���00ū����yBќYT��@�)�y�VK�@���>�g���-�Q������c[��{p�Cz@�W۶���/VN��J|蕢E��mJ?���J~�̍���_��ur��uzD��$�]��W��,�#��F�X'�]��dWfS�@B�S	&R<L\��o��Z�2�{S5C#�]�V,o�oզp0:��n�l�-�R�u�{Ê՞|�����5޸O���Y�O �h��dȞ5�3����3�3��O���Z�"^D�Z�5;�-���)Lz��c���BU&:�h;����7x_oY���!��6��4������M��Ҹ<ݮK3�r�%���3oq+�R��փ�2��_`8Z�wN�Մ�DuZ�Q�)��ma��Y<R�gT����Js�̭$8嬔v��s��|���XF��d����q�p@Vk��m�Y�����O���sŀ���5��s����y�yz�Tʺ���j���|\/�r���P��Ö�K��=���Q6	'\k&��UژB��<H�����Q�.�Tk�[kkY���k�6�n�8�b�9x8iS�ļ�B��� X��B�e��Cc�	7D����s~v������G)h��q�Mhԕ���=�b���M>�(�oK'�G�����v7E���&wO=G	x(�t���ǣ� (�����^{�΄���:�v�\�wB��`�3��Q'X�CB�*3<�#ҏ��X����
]R��f���>Ii 0(>b^!	�όI'Z�9�k�YYP�d��V�;��+�Z�_E��{�D�>��w�*����j/�
in.�Rw�=���B^�%W�+��3����ޓ$�V@��d��5��ZJ�-�O7c����S���t �i�K������ �fꚥ2݅��(����º�<?:�"�_�Ux%	{�S�Hf��
��et��Y�=�|k�(�xG5��kw�՜��f���#��g6�~��*<q�d�b��aMk�GVQ�U�::o����8F����LR�a+B��n|D��e��n�rq��"�o�NL��\O�8���_�nj��lINPLY���zhT�����E&��I�p��� ��.=�����=��w�^��*�ٯ����Mg�ɣ��2�l=�AFxY8$X��PF��Ai���ـ���{uŶכJ�ظ,��O	 �f�/�,@��UEr�Ώ]8�Uh��tN��E�/�����h�m��'y�LޗC�����q��w��X�R����z�`�ƫ2���Fl��DG�T���o�2�څ8T�j���aa�� E�yŴo6���Ѱ�Pm}`6��F� �8A���e��v�s�5�B��ܮ�@��EN=x�)�!���"�/jQdo��h�XW��l#&I��q67�v�{S!$2��#BB;�-©�Cd
]�aR�	�El8gu���8e��d���f5�9]���������[���smO�[�["X��|���-�����?�]wM[0�2BCD���<B���+}�<8Fo�A��VKw�
�K��Q���[6h|:DY*��0��N5��ڵ�8�t��;w�V�u:z�y�@O|�0|���EB��?�^�����O���b�f0q��[�-M�Dۄ���K桥��"��cˠ��(���1������U6�8���V�d;��<|]�3�wO`?3��)��uۯ�B�!��� �[	�7�I8�O� O���b��S���&�IMZ�t�,\���Q��� �;w;n�I��'�>�����cK}��֌9}�96�
�}�>g�h�_��4,;����:-�b��Y�32�rZ���ƒ�=���@Tf)��3�C��A$~��ͯ	��QkP�l�.��c� H��W,����W������03��ި�n!�<����J�,�D��v
"|'O5m�"M,.�^�}�l����<9��ߩI	�x8�f� ?AeK:u=J�k2ˏ6�̔�V�r��O�.���)�*��Ŗ�	��'7�t�0 [�������w,1�.O��q*a��{�����5D zKr�2��G����a�e��o㍰��'��^�#�YNj��4j�q(�����2]���u-���m@�SI]%���dn��K�*���9�H��Ru��m�U$M�;V�a���i��ן��ۖ�㉈�Ԯ-Q���Hһ��S�ie�1*R���ԉ?h$�{�O8��?�}!c9�B��.0���^c
O��Z����&�(�wZt��U�>hr��Xÿ���W-�W����6�G��c|�}�>��d�3�5LYz��`�m�b�͌B&�����ڳ�.�J�\�����NPr�	��0�OK ��]MŖ�C�*���,���b�)"������猋]z@�FnHKR�';5��ۍ��SG�eBhJ���Y9�t'�����K��Q���!W)"�6^b��9����j5L��I� :YF�{��9�P��XR���>���1�e�T����T4x�.s��hUg���O�7�*�@�rC��ZIsܶ��l�tD�^���/~��v�b	�6Wc�Y`3�?&�����U�Օ�F݇��|�����!b*�	`�T���F3n#X�t��4��-K҄���t1���n�g�UO�ΛA���!�?Y��3=l�뛡[Ja��.~��Y��Q�F�N�)�Ġ��c��gD�-u��7j��!\:^�KI���tN�$fe��$��u��t���a}�U�cz��]��Qy�[Kyy�e��ę�eb1��ʣ�"]0g���N5nC�o�g�V�R�����;�0Sr	k z�l1������V�:�0#ض�͇�:^�}���Q)P���u��1=[�d2ݶa��@(Q{����B

X��Gs��Z�3N����c�F�)f�'���Ԟ�9A[�.`"%�ѣ��H̪�{L���x���S�Ţٙٙ�Yߕ泌�!ў��-�iR|�+���
�ɪ�X}d3^��6[7�=�>x~f��1
:��3\����g��2���Uu���}����#:]�����C�{oҰ�Q��S��1�Y��G�8{�J���2�#?h1��W���LX��+��h�鷜��/��x�����&o�+�w���~ GJk|6��\����T^8hޥ�-���t��،���dQ�X�/.C�� f��A�qH�}�\����nk��# tj��5�=5EkЯ�d���y,m�L���$�8m�3��K�M���3b�>p_�0�X�䎗�d�Q��G�yE,��M9/z�_?�9�مT!8N5� �x/;���>x�?T���\�)����/c��ܹ͟?�$R�tE5�d%W�K8C�͟��&0��,�#����lz/���i�ʗ�c��"wH��̂"����;�ӌx���?�fh=�g�S
_?��B��e���;�=Q����{r��V[}�C��-2v^�癋\���]9i�g=�V�[��%�5t���\Ne��g�H����!������_�J��=f�Q ��9fLv���5�$ORt��0�T�t}G$U�4`�Ol��4J�q�!�>V����=hءل�@�|���P�,�K6��갽h���ί��I���EB�<�è�Ū��_��m�1A[�k"��ۄ��ix�U=9�v G�Xo-�3�4W�wH�%����أ'��	��I��>cC5��	�d&q����f� ;w��'�D��RCx�+�tF�f�N�ĥO�3�,��d��!R����2[j�CV�-4�������sy� ���>"�e���������Vc�d�a$46_���4�lW�������� GiU<Ԗ�')��h���u��c�e�L���*�@�*�H�$Zm����0/��P�-�\�M9����S�U�
�����!U9-��y4��+�7�UL��-���J��$�V��T�z�����ީ��|�Zq�Θ8���`�Rc��ڑ:.�Ò~U�T�[\Ǩ�p���R�*d����*~uI n���9����� �Г&Nb�eI��������.���Q�O�;f�N@�n������mt��ċ0�\�	�?�X�3fARQC`�Q����Ծװ8��W�t�C���.$�%���z�L&�*0�q�7�n�w7�ԙ�o�T/��rr��:G���^Ꭸ��c;ɘ�����7NAa��nj�@��f4�'S������Q�2b�$8����s�X)���b��L�ֳ�N]��bz����O���|<���߈���?`�/��FĎB�a���<����Z�yD�Ϳ�Q��9w�Seө*�OyG��K+	M�X��/�vd�5߫��g���>��z�� %p����$�����x�?ɬ"�k��H�!=R+] �8` #Q����[��rt���>x�	����	*� j���/�����le�-ar�F��"N �>A��P$�1a�r�\\�=�����J���R"ˠby�e(��'0���)=]��P�z7���#�>!�w��^�)q	�Q`G������ � ܬt�����6�Z�����Cy��O����z�+ܨ-��R��hq������-o\�[���J������]Y��խ"�Y:���Ê�D�e/��_ϛx�Tb ��^z������x��,Ǵ�N�#ߕQ�`��.5U�;T|6�k�p2�c�?Wgs
+� x��8Ϊ������J�3>�}~ϕ�fpf�**��?[1C<\pC[��G���I��h��N�Z�z���ׯ��wBp0����vt7�@T��wCy��k�0q�R񀛢���7o�.qWeC`�����m��S�fۢ�|����R^#;Uq���)��s�9�(�� P�yܿ�"�HXF(
>��Y]�'�yS֒���@D��8	�R"U@,R ���Zo�N�";�9a ˚��h>+�G=9~#8&NzEԟy�.�<f"ͫ`i��+=�����5�� ��w���ti��O��/�V^l7è�.-�����t ����oq�RcI�\+I��qf�i�w���M^������I&�)T�8P�o��EK��R@}#iF�;�R��{9�?BQI?�X��讨���3y�j�9n%�D��>�4�Hŧ�\��v�А����/d6׍H�36k�=���3o��M)��2�S�X��8�E��r"UN��c<U�]��.��ME���A�[6�x���Da�3�\��um�x�?��6�MߞB�C+�Rh")G��'��I�2�:��Ze���c�C�'������˟;�%kN����c��IEH	�����_[��X������?E����� 
��Z����Z<=[9�b�R�����fMdU͓����ɍX��S�P�����t�K�ø��+�0�S��vh'�V|�L�������)u�z�&��n�G����\��s�9�m�w�Lm��Re��eӘ,��h>�gPb4�߼5}�`�4 \�P�S0��ba���[�=v�
\*��@�����j6�#���"��	E�IO��eX�Z��W�UWh:�s�{s��ɽ����9#��^q�N�%c�jdp��C�7�1~l���L��h���Q���������1���,yt=��9���#D���%������n�U�wy�-r�J.�C(hp+��*�O��+������fc�s���Τ���f�I�C�=�at)�%7�֒�����ż�~?�N3ǔ�M�̍��%�X�EC��4KZ�E��W��
�t� �ES�a�~�a'�+C���N/`���������(�`i�}g�~�䬦�92�~�'�7��B%}cj��;�B��L^xf��?Y�PG�E��Γ�u���k�G�ބ@�VX��У�Ғ
x^��^6���0�� ��޾g���y��o3�\g��95�ַ�3��<���S�O�Ÿ��1v�H�'��N�b��s4_Cs�j�蟡�.��u؊�#�A%$#�e7�����/*��R�?�	 �S}�5�#�=�l�����H���QA���.��߅@B$�z�%m����_���Y�������a��� ��ql��Ҍ8f�H���V����IdP#�d81bt�	 �c�����qّ�Q�}�����ά
�>w_)fYٰ����tH����P�#Me��=�^s�͡5����`wl���U_�A*�yͻS�V�h�JZ�M��b�PW3��i�3����h 2��"� ؂�^�97�W�E'�.�t�"\	G�A�mJ� ���H818�F�=�����%}�9��+3��*���X8�]�#D���CϿ�O����+K�e2����9��`�"W��������t�;q�Gz�|�q�X�0��^���3��_3�����r~���*� .��@�ztu��
h祋~XB`GG�E���`�+���&+�{��7��HFh�;�� ��2���	m�0.�?����oaG��P��=�������_Ϩ�.fu��_�\���[sۙZ[���A͌ iє��JQ��s�;�U��$�'J�Ϛt�~�&kZm�z�٪Ob��ω�����ZL��hך��4��1�i{Ś��n	X�3�i��}���]���^�X6��Bn�h���Q;�O��Ef�0T��z��;\R.��f�k���� ����b"F�C r�D/	�)�>\ÎYZO���k�y/�{�N�`���2�T,l��,p�y\��c��Ώ�e�5_�z�l��X+SxMM�ɚ�/A'k�c!�|D�5o�,�4)7%�r�-�{�L8�+�P��臔!��ڢ����L�zͬGYԻ��\��܇�_��xCm��Z�~����F!�&��O������?y�г�uI5������$IJ��%�q���<����;�m��ZR�P���^��U�ݱ�v/��/�Ɍ�0w�\[�+{��9j4��d��,��"���tL��z��$A��6��'�x�$�o/ R�K/��.�C�(���o�u�KLq���St�rQ�|�Ps�)*F�:P���@nb?OVq�O*39*�a���XRV�;�v�{G��2��?�b(�V(w?3A�6+㰐K���:�x�ij�Q����8V��w��=A,�����n>9˨^!�Q������zס4�?m�k��O��<�H͢w9�mu�?�Ȝ������t}?4�cGQ�#AM��>����w��A�Ƈ"HiZ�|at�͢��)3K2�*��q|�e�@�60�{ƅ�u?�d5թƪ+���ۨ�$34)�m�e)��K_HԸ���D�����>Tȶ���
l�9н��K������W�� <��z�r�>�d�I���{��L�oX}\��y�ع趲�6W���&��qc?e���'3�2ZnF�����;�Od��E}�0��_Y
���7_Y�ϥ�NeR���4TkL�,d�ਙ}���]�D X��I���`c#�;z�����/�u������ve	蔚(�����m���D�Ǻ�Q�}O�V���ǆkE��T��~��*���ޑ�J���S���I$�0��Ɍk�@���W��yZ(��r]`�p>������"��p�vag����:o��RHU"��ó	�+o�q�ܳyaf�<�R�q�!�����+&*�O&<����%�	xa9��:��Q�AcVC�-I���'�)J̗��,�{�=U�#%��H�А��6�IRs�7���X�����s���ʯm���9��l��sU�J=�CS���H���U��&�i��N1*Mj��|+:e�D��΃܄���P��{ڈĆ�_���A�u-�g�Bve��L���B����⦻JatC�Zo���v�7'�֒Mk�h:h�`9����?�5��a�f�`�`����QT�3�ɼ#pV�]�9@�VU��p8G<�D5���������U�$��]�lm���������p@���}|��BoF�r���L�4���c�`�d�J�r�5C�SE�(:�P-Tsm��PB�t�f�����^8���]���	�+ "	SR9{��(�]��xH7U��]��gu�½l⃚�B�
�[כ�6�0�S���	���,k"%��k��%��z�������e�p��|�����p0��Y�N�����c��� z+���c��_]痾6��ӣ�޲�&_=R��1�xF0JX���5�Mu�E�Nʠ�o}<y�gq��8�$�+-KZ�N"�b��|a���҇%}�2�]R2�e�`�m�Dlbs�F^?�@r�FY�+��&OԂS��sk��Ys�i��{���&��j`9����Q�傋�!�#9M�(��?c�Wyַ&�?e9�0�W؃�La(<�B�JDP������ �቉�t^� s��t7ذ�o4z���%L�y���o[�n�[�E�V�HIS��oBL���v�Mv߫�%�\���B� m��~`�*Xj�-�l��X3��,*��C��G� z�p�4�N��Kw�]ā�f�D�~ajX��O;ۮ�q18�⊋m�����$�0(S�$��lv�iQ��w��B�%g���'�͘. "ZT����K�B��M��?�����{�%�o�ȑ"vpR�Tn̻����*���P7�V����/�E8��g��uJj��ߣ�9N?����!Q;k"�Bu�x��s;��')kr}w\vRr�=�6�g�N�:v�3pl�S�A�����5�a�C�z�Pr�"zk?P@��aP��hX���Y���>��4�!�CTߕ@��x��'Lva�*n�g����֤1,^+�͚���r}FN
,�Y}�������j퀤������D�+%U���(^��B� ԁ�^�'�N��j�s�C��3¤7�|���y��H���� >H����Y�?V\�u#C����BY*L����߳ ���nX���oC��p�C{�XγפC�Z��o�G{?��k]^��Z��\�1B����~ .�&)�L(��	"��gy5Hhtn]ϧOT����|U:���j�|Y{@�1�Œw{�d"a�Y�6>D�P]@E��F�Q���Ze줞,���J}�y�j��c$���4���a��m�h〙MW<�
*"3���m(~���{А��6����.�pU��rh����� ��k]����:�?��F50�M��i��wr.vuSX�I$���=����wK>�\�Rd��j/S�������~���j��IC:�lNN���bC4ڈ�$��*�ÿG"T+�W������`��'���Df�������V��O��^����m��UΦ��F����q̽^��E����,�ݵ�w4PGA~��+J#.I�doa����$a`�R?�o@B�ѭ-�\u�b3^�6ɬ�ݭ!���}� ��Y?��6�U�~RQ�@c'��%��yВG�G��u��Ucr��)�Ư�i��7��yj���P�X{UmL	)A�O����n��ᛵ	
�S�@�����jh+*���}u��Y�Ac��zF�3�{��{���)(٥�f����߰k���ĈO�4��t���F彶�Q�����bl�|��
��2�7�������2V���j�@)�p�C�KmU���|��}8��Q���&�N4�;�w�'q�6�b���k�L�Z10�J���$yH�pͱ��K7RWɳB��Ơ>������[��kPf� ����xv�G-|�XV�Is�R�'��2HQ�ש��lʿ\ˉ��M�88�������[o9h,&�n`�f������ v��4��Ǧ�P���М���w)Ыk������񠯦(dj�O�x�Mc�e�h\�.y��
z�1i3��C��L�*��,� �F z,2��W�0 %�v��`>
	����$|f<���_�{�[�%��Pp��C��*�b]1��?일�6���}8[F��f�����K�r6A����"C���v?�덝�ܜ�2�i�d�T!`�=9�����"��+�<L6n,N{�i|��"�� ,�Y>ZP-Ga���x�vR���Ö�a���(t��]����CF�bQX6��f�h����p��}�V����<��Fe���3�6�`���H�8>�~B����\��3�����݈%����D쏲U_���3GI!�i0ξ;&��%r2Կ��Am���-���U���aqm}3�˖�xCD�;;[H}�2°i�U,�zWV?�$@_�Nw�������D!����:Ն'�Wh��.S���l"x0T�?\�Z�ֿ8��iBX|U�a#4 ���)�e��XU3��*ŧ�Q�/]'K=���6�\�Pu�L!P��-����|�'�ʉeo��v��DHS�6��R~�B��Q���)�^Q�C��&��x�,0��#L2D	6Z�p�b�,��7s�ʸZG��,$��D�ҁ<�{Uw��)��5���J �h�L���F6r�Po�/Ю<���=����-?�4)u�H'�ȿ�X��{��t��ݑ�ff���kZ��̭Lv:.��B:-��2�4��W��6Od����M�x(��?��E6T�܈�-��� ZLI�`r��yqU���!Nj,�+���AM�h�����l����D+�,�����;.Uֆ^���35�[7���/��-j1��h��l"����e�.����H����/? h�pF��=X�n'�.�PrX,�B���Y	r��:%��շ��lg�dv���<�p��0��z�E,BT�����xo�(�<�K6sU(����4�E�&"9ډ��f,Juk��ɫ��pP����/��I�x��]�R;�K'Q�6��c�y��kR�+����/֚���G�
��b���X��7���Q��Mv�Y~V�/<�_�nQ���!x��E�`Ŀ�Ѩ�s(!���g3�x6���6�>Su(���'t+�v��ަ�P��A�@��t�x��$��B}e���zZ���s��)n%���B5��BsBu� �"_�QoGb��U�Z��̮��1A� �#��l���Ts���Ge��q}-����>�~u�&�-�Ԛ3��XѮ���4�^��@�d���bJ�a�6����z��=y
n�V�a����ț$_��X�����qC��9y���H�*Z��{�r�Y��Z(^S�	e0��mի�`z�ӻ痊��s�����-ϼ�{}�Ks�{�F=n�q���o��T��z�Ml��; \]��T���6�\�(���rS�x���w�f(�N�U{G�z^��E� �\g���N������Q�I'HsY���!��男4�/�Tc� ��Qp���FlҼz�"�1���[nɴ�IO���x�Ǜ7��O�P�����R���UEɦ��"��:ἦ��܊z��OU/wl�\�)N)�E�D$Y4��i�Gݫ߸q&'�;y��I`.~f[+��dyVV����V�d��4�E�_�8�y�KN#�4\f�����r~q�T"żg��0�h�?���Q�zmm�8�ar����ܨejπ��9�9��ǲ�#�����>5�5z��6��2��	�N�G@%E����اɁ�u�I@o����Y,�P�c��t��)�kH`�~X�pQ���䜌��*hރ���Xh��+���1y���Ɛ���OǏ@�p�E(����`HCAO�q��`O2��?	Q2��sZ~!<in�3ii	����@�͝�CȠ�P޺��j
�]�,�u�^�̀(tu1�;��J�}3b44��9:��7�
�L�KL�=��9�P����T���X\ W�h��#�u����WK?�J�]��D����ݸ���;���bn���$����쥾���"J_%b�Ii��/u��U��%3��yꎷ�A���M�T�hMHy <Ѝ_��Ռ�.h���'����gg�9�E?2��*Qd�zNgY˛|*�)��ԟ�U�ۄa��5�(~���c���Τ��yٯ��� ������䡴BG�pTS�#�k܀!H�KteJg��O�Mލ�v��b6i�JJ�Ķ���G�?߅�(_-(u���(��}!&_�3���yhі$��,��Y�B}[p>L�xԈ���f��������^'�@�<e�~��Z{st늅2(�>?B����}�B�T�����^!l+�হoB5�0<Ïa��t�z�"�r�E�	H0�hڲ�v��TZ&��w����'gQ��2���b��[�Z���ae�RR�Y���ӑ�5;[�jy��� 9��I?���՜���7wB�L���3��)9���6�҂Y�C3~^,/fn�'��9�ƛʊG$��	{O�=X���{;=�D�ΐ+ٕL��%�ۧ,K����	T��z����P}�#Vu|�u��M��SB���_l�_o��u�8 ��j1'�Sl���������tYF��>Pz�f��S%�a�&
��>KU��F��`fPz�6�q�P�)8V{�A�xT9$ļ�c��ˎ$���F�U�)%���jk$m�6=ܶR���J�S���.o�_ъ��I,h]�ȅ�5 ��3<�`DN+�@�#Ѩ>*G�7X�a�1�Q�Zv? H�@';/����F�i�+L���{�Nʴ�T�N�cE1j7j�❜�OEv���]&)Um���g#(�ʿ�h0�Y�R��%`M;�VQ��U��p��6 8�����EL֜c��y����T�YB+>��
9SZt��N�c�$'e�4l�ţ�P��J+T�?�ho�Ӧ��@��8MŊ�e�>�^�����"�J��4�����&�����1�[DR3˷73�7����T��4d��t6b�U��1�ι^��HeS��_?�tϐ��	��?F$���!��e���B!���%�lY~~��4&��A��`���|@�����)�6J����t�ʂ�kQ�%����25��x�W�DGŰj+��<�=��s =zq��	eDm��j�=329�`=���U�K	��#�|����z8r�DG�����	��wth+AW�\!���v��]B�X�G՞1�OaT���9��J�\�����"L����/�_�h�����0�*�U�.Kk4WIexa�,ڍim���O��xk�3�Ob()����/Ң�>4�~0���< #6H�[�oP�>w��o��pbb��r�Hcoa�ߩ'��8Ր����L��ljʈ56!YZO��r�S�
�MQF+,��	�2+��_4���mTR�uu.� x$:x��ֶ��GF��ɉ1ȋ*&���ҽ�����r.��R|�0�6�j�g^m��Q34�UAP&�8���/��Z��O��&z�D%i`W+����b츍�r)�ȹakq�7�0i� �����GQ�T���Z��V��ؕP�-(�6��f��I��:Sլ6�ݨ��\\�d�=K���X���?-������_�}�'���q�5���c��hxU��Z�03̉�,��[+� t�3��ЯKT�C���4�b��eK��y:�S�"�/h���Hj�����^���Ow,������P��A��u�	6�������E����?�6����e�;
.�B�u2�Im�SbGА���;<32��J��S�P�N��>bΕ���TA�"8\s�� �E�C��&1;��a��8��slf�^c�7� SПNhA�PGfײ����.qw�������ۯ_�R^�e5��Ĭ�g�d'�KQ�V%},?��&�@/���Afs4D|�Loy�fo�a�j}����!Y.�ґ]'ϒ&/���s} |D��־��r�9�v	vQPFDg�g�<��<Q�k��q�h��C����B$Zv�h���v��&Y������i'W��R�g�����vp�|.����&XJ�S\�j*�<k���\"�.�ͽ�-���i�H'�C���x�ɛ��M�q��~���É�.I-�0�bR�]�~�mŃ��tz ���*�頃 �b]�r"𥾅��p��c�"Â��i�=���gjuq�fN[O�{*2�l[�1���q F4h��9*7ǸYL��m�'Ey�V��~�2b�����q$L�*�@/��.kZ�[�xp����ڙXK�9�;��}�WuPD���H��YN�Uc���T��@#�D��\%㏃/�L�`ӕn�PJ��؝��8���cʂ��{ܯ�1!v���q���1hPx� �G���q3���n��I�ħf�@���^�`l�w����E:�]���xoV"4�����J_orr�^�QV-�<<EϭDF�(���W`�b�=/#~}p�0�O(���35'B�T< �{
"4m����Цb��a�:���:�c`n���g�u�.E?/�m�ڻ�Q�/���	��1d��޺G}a��P�)#;8I/��9�{�V��	�l�җ��뇲FVg����?b)�$�qϝ���_pҵS/�B>C:R���?y7��ܺ��"�1j�ǉ�y�'�qca�F@����򗃪���;b��e��o�'/[`���z�փe8ܔ�Fңº��%
���#.�'�f󚤎Jٹ�߸��`��+�dڐ�|������)���Tg<���U����LG`�8������L��h	.���Ig�S��D��;Xte�q=�e����-�J��2<`
��(SP�0���`T����λW�ߕ�������P�������Rg0�̊^�U�"�GWL�ɴ`�d�#��:�Y[lm@�C��F���4@뫹}�����}yٷ:)X(�}P����S���U�	~v0���zi�ǭ�L������z��|Vo�$HL �ZW ܇��&gtzC
�����+�Ԏ�dC�q|*<͊�{�/w��$��ڄ܅�`bo>{:�#��,pHyU�e_��5.��g�	���dUK��TOu�FZ5�U��F˘���Oc����_Y�q�CN�xxڊAm��R�v`��) ���Ȥ������=��I���:��`�〫˲f�o;��ώod�吿�!:�)�
c!��Ʃ����(u�F0,�I�X
z=+ǣ�3m���������8��S��˫�jAEH�q��^ɍ�¤���kj7<[K�����w8�(��&���纾�R-�q*��5U��a����W����*S��`A<�}����-�1��su?�t�ZI��XGԧ��0��<��ՙ�$W��;�su��BC�QVE8�N���`N<]N}Tsbp ��D�6@��+�a'�v�m��9쓣9����'�S�jcl;���oJ����TƁ��"�b������l]�-���?Vt):{�%Ď�Ff��A5��2����8���"�����0(�@}�+-�3,�e[��+b<#�_�£���9 1��mC.����L���托�:���ݫC?�N���˙&2�%�o���@�ʏ;���ɊY�]	@l;��Gu*!�����X�%X8�[��ʮ~Ygp�]�bB*���=���	�%0>q���=���w5��]�h��Х1�lF��	ލg��b�l��W��Ζ��I�BHun���Ԑx��'����su���
�
7}��D�w�J��pě���D�#6��S� v�`!���a*0{P���{hA�U����u�8f��lt*�:(Kj���S��Zt!K� �\�F��߿4��Y���%F����{����e;����6���X�����;�Lm��6���q�BϮF��3���;S��+���ӠrK��v1`�P���E@��x#x���O\�H�C����V�?I��5��y:�.�~u�����+ڴ5�{8̄nS:���6��k��r;�����a��]��Q8�z<��6�H��BM�v��ō�#���{�~e6jb�Gr����^�K�{G�!1V0mkf���
����Xd�f�}Xn�g��9��YD�m���+�u?�0���Fxy�:��7��(~8�j<k�D�6|��m7���q/��Ӑ���!����Cކ�.�E�o-��;H��6$�i�D�=Tk��#b#}(C����:�V���2�y��Jh_���j4� ���Kn�u���l2Er�Q����1ɪ�w���z/4�	5ҟ�b�Yu�i��i7%� +�n�&���j�7��V�]N����S�D�-�-���Ho���=}LK�ׅ��r ��$�x�������s��%~��&�^��_\��A�'ݧ��]�G,C�U>Fv�2b�a���1&����~
y5�.|o�rU$��'Xʤ͙P�ig��l�x4{0���ϩܝ��o���no!o~���Į����OE���K�^�>����!r	~ 7y�G��D��VEc^c�����$x�%E~�
�3r�׽���7%Քv����>B��i��=���� %����,]|I��:��"��夈(��@�F�������b��1 /g��id��zPP ��tc�^���>Q�9@{�5@Tz�/�Z�G�!��-�=�wE�~@6�/�I�g$uE�N�!�/�Ȭ�����t����@�����t��	s1��O�z䡄�[0�n9�@+d��rgJ����������1��H�4�,6N��'��nX��)*�@�|`�g�~f����7h��h���=O� ��Y��[�ň犢# ��32�i��ȯvc��̪���It:ˁYm*�|V�WJ��ёm�2��ȟ���*�A�B�|P�����XV�i��������Q�|�ie����Ga��u��؜wݜɧ���^�t�@Z{v�F)Υ�~m��ų��t���� D&��uS�����7�G�*�z��b>]��a=�"��g(��%h��ĭ�3��A���C!����

^dY��w�����}�R鶆�r�	��iA�u6�G�8H$~)Z��6H��[Unч�/r���qC���!��{L������7(�Hn#t�f�:�3X����"9�P�^Rk��JŲ�R��\2��s� �i�4�|.I2.g�+�,W��Wk�~RR��-x��hO;�m�Z��Y���5��x7�p��R=�3���aqՕ:�ǆ��"\��\���Ki���k-��l�8(�k5��6}g��!�q�`}0ƲL���۝Ir��4*��F�B����O�C�hF�ʭ禒P��˗�_ح�(k�����+\Bk0|&���(L�i���G����r� Co��I�̔[GQ�8n�p�ٷ� Y��Z��;�����o��T�_��=�fX��equ�Spxb�+��3�����W�¥���*�vOY����K�*L5���bj�t/�&��`;���h�������CP?ғ&��� Y-�p���)�x�S�x�m�(Bצ�l;,�S�I�$��&e�7)�2Mkg��r�u7a��F|�����4�І=��H@��,���妛�d�\���r���MURZ�b
n#E����tbB`F2�MJ.���K�<JKe�E��K��R��-����%7"��`5�hA>&
�`0��v�Oh7�����*����眛���4 p��L��b�ӵ�.ս�VA<ٹ�O�������{�OYWy�����Zx]���Y:���vOu��1�vD�V[�����F�Ծ����U?��<x<tf�ҝ�?�����YPٌ��I9� �ȹ�0���/O��W_�D��� i��^禍mE E�J@������J��u�
m�=Iv�m�尴��A���@$f!�m�������n=8���5���>YL���MV!T́S��m�5������8��<��}R�U�2f���N���Q7����{5�q��xɎ�5���|�s��X����v��6��J��A-k瘞t���d�4�Z�d6��b����=C�{Є	5�y5ě$�S�����?��֊1=#CG��1)b������x��:�/�,�i���k��[���3��rB�Oz�)$�bD���Mo���T s���/K�z���R��nMf8Ggܣ����F����]���y���O|p&r͒������S��a��ٰsؑT�ĹR��4]#F��5HaI�/�H!hn6�����4Т �ѧ�d�*�F0XY��o����#�X���9���P^NL �>V2C�������#�g�\FŽ���~/�rm����H�8�_�Y� �U��\7	Da'X��}��҃��J��G��?�8xNHo�Qzix���b��:�ڙ�P���@�f�ov9�8���{4�ӮD���LaI`�'�M֫Ȃv�-(������&�]�Jrvra(k��C<06)�oL�<ܯYE�R��rAr�
xT�s%Ԉ�׬��{�bȸ����?-�ܯ��W�р��;��SM	�H�v�h��F�߀vԁ��X5�;�L�ics��j���]��-�����5&��J�l��Tu2�]7�
��SIَ���a�9��wp��܉����)�,5u�]�@��U@�|zBD�>fw���KN��a�E߼i�f����Hm��k��AA�{V�J�1�;x�B>'���\{ud �+�垺�h�����qb�.�{����J uq��t=�1���]�9�-��t.�e۵��UV�i7�}6�n>2�Å-���{O`}`��ly*�ʜScg!�eb��я�s�{�DCI���_�7�χ�lǐT�>U�;�D	%�$�
P���0K�(��Wa���>���wҊ>�*��ā�����X���y�.�=F�֕��w�"�t=�4����Q죒�U�Ȣ'�g�T�B�����W�҄���	e�ծ�M�ة�T�#�� ��u,�E�[`p2t8��nA��;ZE/2�d2�G-����1n��vrmn���d-�9�ύ);�ҫ��>���ؤ�?Ѧ�I0�MZ�:�v��2Ó�/ٶ�(�M�0�����LS'�cڞE=�_���r+�b�&�R�l9�/�$��
+�ߊ�M´�~��T���;9��{S�B����U�2�a��8�P^��/guQ��yqpt�8/�e�s���z����V8n·�a`�ts�c�������$�aDse w�bo�=�E��h��S�wK��G�$�����=3�]�`mۀ���[�c�ۓ���2L�t]�����;[�lr�+�eu���R�HF�,# ���)+O<�羌U�*g�<�":e:�c~L�,���t�x/�" N��A��;;,�tl�CWє������*K��@���ftP�hӳ�^�����N �K���i.�Ʌ)�?�Ld	V��0�n�h��U�싒�]�����z�K��ɨ�A&)�u<̲����[�$s�-��Z�����ܱq܈�h���W����,��^%�f=ra�z>ދ�����v�$l�os8UQn��yT�V��J���^��"`�IYk#dH��7z��?|����m�m>���a[�dg8��Jf�,��kC^�ٝ9 �dݿU��~�����m@�q�O�D"�|�&L�iPw��͎��ѽ9�_¸mL���ɧ������0I������|
a�x���i�|N��.�b���r����.r]�~�r���I<A����/�B� Ŵ�QB\�-h���p�{�%������|��r�sqO�C���/NZ�bb�%�8K���㪡��Kn=��#(Th�o�����]�.L*����w��ƛ.���ƍ~�pl�����ۺ���_�+�7��"`�"l��uc�`��Yg���G��n�{ʝ'���-��/n�]e��Ȩ�
8��vJ��X�"�]��+2mn�z�OqīS ߵ.�l�K9�]%�Zd�m�S��N�r��?Y�}� �$�ERnlk@��Rz"�u�gƏcdʚ��sr����9�E�b�A�C�-�ӭ4D!��,�V8�w3Y�7�d%v'ޥ;䵡S��ӹ���XZ��*i8�Y�7��eۛ��}��x�K��	x>@��~��&k=X]Х�� � ��Z-�u,����D�X���U��m}N�ebK��oB{;�J[�A�dA�,�yr#I����^�Z���|Zʪ�)n����"��]'c7����Ǌ6�Ϲ�f!I�x�ˡQ����    �1w��K|. ����Б�|��g�    YZ