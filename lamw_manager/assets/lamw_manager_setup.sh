#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="929256112"
MD5="cdbea4c1c175728723240d3c64b187a3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20572"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Sat Feb 29 16:54:43 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���P] �}��JF���.���_j�َ��0�<M�������ʘ�1�=��؎�l���N�F���pl�𬿊�L�.�����LI���܋״�Aɏ*䊣�-z�����=��q�H����	�b&�C�����1�Z��\�DZq_u�����m�����eyžJ�Ť2�X
�E>&J���Ǯ�շ�;�͂M�ȷ�Ъnϐ�����;���i��#�� ��Vx͟�^/���,;��ﾧ��#���B�y�'��e�LI�D���/Etr����E�0pxf
	�΀�8��Ձ�K�V3�n��p0��5J����F��$��C�c��+י�3BS���o����w��:j�D�K��i1'`r�b�]�����H@��/��!
x��X���K��qMc��7�Б�I�q򭀆w�8ThL�V�*�4/���H��+�;/�`��y�J���=dSg
㐥4�3��r��|}@C�jU���� �E��R�A�}�1��6��ɖҁ��1��j����JNT�.l/QZIr�ww�O��nI��c��%Wh^��Ҙ���.R�}�������i,d��>�L[�*�p�2��������m]N�Zd Q2aŎ�e)�G�E���������|q���&ĒJ&e6�^�G0݆�	���w�n�'x�<��],7�ra�&Im�}(�EZ!o�G�mۡs��dc ZJ�W�Ia��9'~�}� r���R�&�O	�S�$3�[І�9�&�S�~�y�vA�[�j�&�]s���]��ue�u��߰���ɫ��I�;��w6j9�y�N5ʶ�_�SB�6
��6[:u�׃�2��)���a'[0�1��&����̴����&��z9�%��|"* s�ц��p�@�t�8��O���$�����1(U�ee����34�bGcUR��2�>W;���~y��V���Aؒ�����U�H^,by����C��iR/~��e	N�5������X�`��aL��2H8��1T[��|�.#�b��P����f�����|�i�����aO�����Ol���~���k-�h䀅g(�S�9o��Pn�1� OXc��Ǣh�#�wA�+(�
\�OT�~w����`�@Z����b*�Z)�z�1n_l�%�7�?����R@P��`�AK���{�F��G��x��0�*�uK���O����v�`m�×���sn�J����1/D0��[���Rp
��Ŝ��C�nm-{���4�B7�����@+�D��T�W�+E���E	�u��Y �:���m}=7M"�e���&�2��a#�nZD��,B'g�=e��t��
V~�4M]0�ψ�A����gp7��a]|o+�ͭ�5o��&6*{�E꼽��e�=<&ak�d|[��f��yb�@��Z�+�d�e��Y1��N�1n.)�	��%'� �h�	7��}����f��<zR].���Q�Xf�F�`M�u�G�2j�a C8��jfsym��z`�%�!���V�,W���,�ia����S�uI��qZ+�^�ӣ����9���ՑqXCi?�)�?u7Wh�!�B瀨I�H �c���쎚(M!\�n���K��"�>{�[���N�����Nx�dw��� `���%�}~%TO'��<*(�ӣ�Z1��+�lE���� ?�v'�k�	锓ݥSU��%b�ʖ�t.�6�x�y(�]�˭uɿ��^OC#iP��(Z�B[���zIk?J�T�}�{�w3��
p,׃$���AY�tġ�gζ0w�Ø
p[@��y+�ї��1æ@8XS�����$Dw7ڰ�=����B�j���!`���G-vd��Q�
Wd���W��+͇Y��h��$V��%���.�ҬK��WX϶�\�٧�d�ˀ�����\�+�O���%Rw�}{�L�#J(���Ox�&-A��a	�?N��:���pASˤd�]?�
]�����a�����y��A�\��s������:SOˤ%$ħ�A^�5Hdx�0A|���OwX�=%3I�CRg���MgmA�J��O�c֊з�)�O�kzG
���VuZ��F,J[y-�w����]nr�n����c�q�F�JQ��NB��$R_w�K +y�9뉔�\Tǂo�
2w<���b3e�b�0��9�	Y��xu�ԥ�*H� ���r��a�%4��t+�z�t�9�+nI(SݤB+�&�	���5b�ى��7� ��R���Jh\z����Q92��^�K��}�7�k�x���|�1ȓ�z����`�l�ڎ���F~΢'��6[<�%5��}���������f�M��#缑pAd���t�$�.Z0��ͱ.��X�ϧ~=��Q�2h'7��	�l�g�kw優�#*$r,^�u�w��م�b�D���ߕ4��-���y�eC M��^�'y0���zf�yB;���s��lqH=�Ao��dc|�i��M|L��>IrzwN�͚W9�� ��B�q#��9�u f�&F�'��ܓ��wZ�C}�ŕ�c~���_rw���P�]y�%
��hl���K��B��-�~�uϿ*��e��JZ�GMND��!�m���e'.s\�}�	�C���^�+�c�Hv~]UfZ�FT��l.ݼ�^3u��3J�w.��/;��.3/�jwx�8�kh���/}gY��z��7�0o��^SH��Ԋ�!���4E���/�`��9?�K���]@�z�g���i�ƴ�`�C-� ��fW6�g�H%�K��b�_�F��i�H��M�����ȔJR�=�s$2s���u��~�d�fG����A��`�}���g���b�\���:o��eH�W�\���{t����;�@����\��P���>��g&�o����Bw��|���Z4�\�g��e���h/��սH��E@��i��Bu��|9��C,��2�3|�CTAjQ��&}�a��,�<�2F��4�S�ٴ0I�/kͶ�@t���n�\�iS߬P���j�z�fŢ�H�bQ����S�T[��\TavV����M �4��sz'f���zA�c*�(�a�h��J�O2�ǰs>���8��l=��A�\���]�2%��A�����2KC\�P��˸����dO����lhgV�*P�a�簎��r�ֵD��p�6�ao�^7����z=|�i��)�*�����bs��+����S{C��V�j���Ìb��qPD�-���$�_��X��P`��,9��'�H�}꾑l���5�v�S�K6ۄ��z	�2+�-�㒄��"@<k�iw	`jfV��_�y�?���j��Ej�O�`C��1���3He܈}?�{��#�A]n�D.;�9��I�3�	��uB��À`�~�Z��Ƭà�cd]��Hz��6���6S{����!}l��&z�ˢ�Jp�Xĺ���5�r�L�7
��od߼�]��ag�_���������*{4�~�0��������BK���d?]8u�{��8��u�skU >��~�/���_�7��V��}m���3_��O�z��e���}�A�^��'�`L�x� Q���o���G��l��i���z�bwuQ�G9
	+*f��s��y�3݃���2� W)��+4]/4�-E����S�['8�R�j��
c,<��f�H9Hx�`�aY�Q
��ng�b����a���9 �����Ayta91�&N�!�~8��Q��
�')ͻ�^��&K�8�� ��T�T�2�E������χ��Ŧ�*#�v�6X	��=��g4M�d�0�2+$�=�#�͈��G����l�v�ƒ/g�:'=vRP"cGR)��)l�A1L�o^�}�0�w�
�5�$�}�
�/!ܭW��0�e�RZ0g%����2q�\��ŋ!��t}�
�u�܍�).d��ps�O ����1ʻ�{���ˬ���EB)'�.��Y���o2�B���y�����Y��0"���q��m� 帡��=hW)��R��k��M����g?�BFd��T#p�>���젺�Ձ六�5��+�R�W0_>�UQ�,���Kt"����x(��>z�;R���>�Z��b�ʉmVpv0�l~*Rɵ�؇/H��}d�fF��������� d`�T�]�`LM���.ב:R�ᔥ�rׁ�ym�{��;��R���c\t��L�gh��v@���p!'o��IT��[iCI��sv}FF�a����_�96*���9����eq�|��,!;�F'ֶ��J�3�1�h*	�Ǆu���Sf"�W�L���4\���#�;ءzs�.$�.(ƥ�@�5�c|�d�����c=l�I���9��1'�f�d��G��@��n�5E gf��X/��`�W�]��.?�\��أ@Xhej��h���
M<�o@��z���]�*��.>���٘`��#ٖ(��S~XG!<��v�"Z&�I;��?͜���3^2n!P�p{[�z��Er��dt� �V?���q�Gu�*Z0�*�'�Q~ǶŊ|y<wI��ܬ�����2w�h,��7E����Ra�ļ%�1 �}$KV���-�B)������'��8��1������:�ãJ�@V�]|�H�6j� X�b�oWǬ8t�d���Rjħ?��=_��� 2נM��oIЬ0ʤI�B]� [�	+�m��%W��ܷ�J}+�؞�T��/��)"��iV
�1w�4�+�݆&�gOq�h<�IT�p04��Du�����xI"�) 6���z�i�F�}\�9a��Zt��S(�j��ToA�����u�3�(��`q]�8���1�1��mI���Ƭ�d�� N�I4�@�]-��i0hj�ov���y48�O�����PlZ�gtr�n����73���|$7��
��R�#٦�Ȱ�O��#��du�t�x[�-B	����H�����>+{q�x�Hu�� !UKN%w	����5'����v���Ơ�	@�/Gէ���A[�4�DB��p^dm3��㼝z@ӬI�}8��0s� ��>�D XY!��W�&T�T�	�t1��2������kԗ*����F�1�T������Zӫ �UN�ĳt�Y�V}��Bb�)X邓-�Sc���x�ۖ�Ou��}+�վ�ޢy����(;1�F�R���9_u��V��y�bh��3��e�BÄ����fN��&�S:������^/��Ȳdq�x�/�F�b�=i16��	�[H/���Z�0�������a^��7� >-^�	k�؅����2��_\4��zr\Ĳ&rb	��pB^��E����0ǣ.O�4���'��f}�{-$Q^�׋J��
T��l�܊\�]"K5"'p0D~r�1��Z�*�~5�����c�=E�x�9�F_e�l%7]|���eG�,��5��za��.�^Hw���Q����[9]
%�@�"Y��P�t�t_�U�?b�����c�f������	Pŵr�����q
7��W����&��Й�x�K3�~sM��E^V�ɯ���3 ����h+p!���}��#��Ȅv79q&��ي%EP*%���9V.,�c�Q���ʮ��:5Y	�^���|����X��Q���X+=O����'Z���t*�[C�c�Z��eKF/Y��r09�*�&Ag����w���j����V�WVu�Z5M:6˭��V	��E^6�Y4���.�3p`���GT�A�%^��ޥ}�Agq�+j�k�$օ��̠�1�lT��{$k;C�<�.���p����!�}A��+�$CB����fš�e��rg�9�)ƚ�4�4��♞��s�d7�.ʏBeF�A�y��sd��xhIw�G��_N�_.��3��b�,d.g�U�+��7��ALV�N��ʈ�C�1���<�[�D�^LVҙT��.�6�.�zjP�c%��ꄞ?X\�@�s��c��RF
�ƺӕ�}B��9�[�ڄ}��ee`��%��MK�Tͥ�|�X�5�\@�F�%1��"��9��H�ݼ��H�*)j�J]ܱ*2�De��b��,p�l�^��K�~��A)�rs2f�JHt�5�
mڍa�~� U���I:�aX]kZ7`���S��k��A�ڥ�\��yRK;�ҝ�/�tg��A$��k�iоS��g�����6=��ݴ;̬Kn��Pp�yxJ���`�ޡB=PAHPW���B���z��b����JD���;S3�1����X��3��L
~�t</��u��xQ�$!(0؄R�B�'��mh41��͂S Y�s0��~�~a����O��>�ߧq��3�g�;v��
o��z��Ɯ���t�z���U�Ō���l;��	��}��`}ɺ'(�ֶ�����!�4�lx�rBb�5����c�9�!�h�>Eq�?���p5y<����B'��l�*\.l���y��?�*�'-ğ��ܛ�ME�R-8����mXd�|0���ly�6�_��n����Ds��Y_�x��*j#�Jk�gzU�5�+ ������b5Җ.ސ���QW�g����fB-H�_j����I*�O�94��C����^��B|�m�	���8om����8�*�'����qD�NC5s�/|�
�����9l)���+n�Er��P�Nh!���tZy���Q�o� �MZnT��֓�|���EV�xf_�Q��Ƃק��p4���[�(t	��*�  5���e���8d]z{�2
�{�)�@JE�]��ޣH�/����4JWU��qvF��r���X�[�Vأ�u�`����A�U0�" 
��l�ZIFI�Z�B��R�J0��]��Z.���{�c���j$cow\��7���/0/k�CE?}�[��E��wC%���8�y�G��˨�c�1p�����<�9R
�$<K��G7���F�zh��2�z u���U��E<�]�=%$�aa�?U���6dwT�ͳ=������N�8���f�/E����=��r�`�5�`*��P$�?m�N�!S�%P�o�h����0��=k�������b�,i���Jh���3\��&L�X�^�}S%��"ry�0���O�Z��<н��5��ޏ���ҨC:i��zu���T{�g�����^������;�z12�d1UFs�!`��L��>��U�8�_D+��~�?`=�.��Ӎ�C��@���ׂ��}�X�}�ŬЇ\O�
s����;tQT�U�d�s�Ԓ�܀rZKZ�O�\F����*B��L�og�ڂ9��A�uy}��Sw%ޅՃҨ����Cg�]ڲ�X�F\^�^_$��0�IFU��擽�G�6F�W@3������XP��|W�=_����(��7�u32^,�6X )<�8bG` ���@�O�|��D<L]	���Y��5��UZ�\ȡ�GGxIƝ8oUv�to��qx7���xz�HL�Q�G���Ӑ�����S�
����y
j=����m]5��n�I6�1#�;����<���q.��i��=J��g��2 `8��tfHto=ɖ�-o��2�{�p��P���4^�s�3������E]����H�Y�(����q(qD���KA��ɣ���O�a�ǝ�;�{����o.��n�w�\���B��Ni����03O�����a�沙�_�)�5�W<P�O�����Aŵ(\>�}t�T��|KϚ[�/LP�~dC��	B�P���zwy$�����Cd=�	4#9����v����]{F@��_�����N
��߃��-�,?��L�,�����*�꼯U�:�H�
S�����n�K��B8������/�-��9����)Tv����EY�m���U�`O�:S+�ޠl��E���k@�z�T��N��Y��,S7%_���Ż�"��~v�͵�6���lE�z�t��J�w�rJ��Q�_h�2$0�Te���
 (?�4!7�0b`�f��q�L��@.�kl�,5�&�(Lfz�tYHا���q/h=���	�,���x0���p`��<%�$��HX�Nz`�\�g������O6� JM���d����[~Fk������P C"�[B�I(�i/�"C�ُ� Ȧ�����
�.E���g=�"���O�>�z���c�"�km�W�����:n{?#V���<��\���.\����A�d�MF!0� f�v�����t?����UYo��^ƀ+�H�s��U^rZtT���W,~ZI5Y1���{��M�֣���ܬ�^����F;!iF�7�����(���s�	�#]}y0E���>�;9�rgV'�L�����?�'M�A�T�Y��]m��Y Z)eJ����XΟ��XDk赹�H͢�.��^TY���c��,����\�^�7�Gj�[J��-z��ԍC}$�bK������ Gkf�a�qr� �_��t�����I1�Yԫ	���S%L-�����B�]�lӎD�I@zAJ��u}_ˮ林��2+Y�>��0Orv��sZ�+OT�lt�B�D��H�5/��eo	K�v������Ⱥ�ME��rRP����:���Mv�si���%m$_�bA����C�2uV��d��Pe�ݳ?��x�E��s�FY��C�b�[L)&��>�'br9J&���z�	�]�Y]�yOz���w��wZe`���7�}!�[���>���L�(�+my�A�_~NF�9��
��i!G�up��,ؓG+J�t�S�\�5"����V���o�BT���E����M�I�y���%�W��(�U1��;\e|�w�OO�M3��Me����[P�ƜZ1�\��l��qm�a�H�a��<E�z��/G�~H�~�D�zp�i�@��|n��}�X����f��c�P���-=�(_2t�d�М���=E*�)>_�]2ofM:�m����oT�^D ����~�*3��vp�����V)��9ʿ>�Fg��f2|}+D�=,K�A>wv<O5~��m�Ɂ@]8�����9��*����1��)�Y!�E$ƍ?��T���X�	�3/U�R���7�Y	�w������~�^Q.{Ġ�nE�B7uPl�i��XuP2��^��xF;۷xL���֠|�����T�:��3H������X~�N��g��G�Q���N�R��fə�9����CĿ`C;h��6������Y�@$���%�"��E�\=��2D���#���M]N@��+���-�k�H�l�b��d6��U}j�E��*�ҵZ����:"�Q�?���E�d�x�6TA u��}���̄��А�z��;*C�^GMgC�.��S�pE\@=�U[g=J�(�(��
��q�f�x ��u����n�gzfל=7-�*��O}9*3%��.�97 Cp�U����I�Ǥ�'�Ť�1ˆwTj_<���Qk�LI�kȡ4����@�_w��=���r�Jbh�G���d���?f�,�Us�v�x�
���B��-U}���s��>X����:�)տ����ឃ����>C�Hm9�|vC�Ǎ�4�0�X�y��$KK�tZ!����B;�a�L> 
�;��+�b���)>iή=q	zGWbDiM��;+��|Z!-\ӡ�]pZ?-;!р�ε������3�j�j������9`)�t��n��R�>�(�2�ٿ9�AHy��
r�q�-��6%ċ��8���&�m�|�I�s��í<[�
J�r�h4��9���������@��1�ڶ�k�@ڙ�S�f/Qg,>{�,N�ڮ�s'��F��5���}F��=�J"�/��v�9�9,��ß��N6#s�M���f K
4��?E-�XLd)��.*�����ץd�VG�b�b.���w� f���?ß���3d�y�(���Dg���Ι��D��L�ڭ
����5���(V*�h�w���K��v��5�_���*�'�|nDܜ���-k�ßN|��u��Ӑ*�|T���[�+�7�)?:{�q�W�I�⫋�U��&����x%*��-�>Y44��X8��6�a��n`��S��u��׿��5��[\n9*�ԟ/����p�1O�P�@#H��[�����}\���y0>p3��1��9��^�� �ܤ��Z��HQX�]~ϭ�8�R�!��j����[ev�.9��f5ԑ�f�G2@�o�4�F0�7jG鏰��O��,6��+�����
�7u�{���_����W�lę԰>y�F�1q����0�vӳ�ab�ڿ�ז'����|�9,�h�&������;Y�[����^�!��:G���Z����M�����Bo@�b;�i�Yi-l�G���D@�oNW]�?������x�S�`�Z��������+����&��j%�LK���	���gA��hqL�J�S
�]�#�����ft7��vy�l����&3Լ���yS�Y��ޏ���'�+��J6��}�l�տ�v��Q�N�DKS.E�m�Y�![+���)N)��zf����e�zk_�c�l�T!��l�^�9�d�c,��A�vBH���n��$ۑ�ݐ��&h�T�T��6uY&U�����(�f*�'���5��{�̟��{JP7$v�H��a��\����豢��S�B�n4������D�K�<�f��O�_�0���d ��Y����Ō�+��/k��OPC�����0� �I��f,�`w��J����_*ʁ��Y�ݢ
�h�L�@A{�����+#?�ͩ�d���Ӿ�OKL?�A�3��Û��\�[�t�"�T��j-ʚ�� ����`�#<�[��v�>^_6{�+R��b2w'0�*ۣx�/kj�e�W1�!kb�P7�^��Ah������оn�@@ت�'׶0
���#��_	�NDbU�m�;����s��\�8U�W��YY���~�;�<��Z��]ٚ:/$�aL�-�`F�\�1=�!(�(���mg� ��rFR${3!r�/�������"�~�~�o(�c�"S$�`W��RpUzh���k����|r٫	O��R�q���ɉ�2<�n�6�u!��������E����s�I, �m�w3H��U��6�1�Sg���K⫱�����ݕ��`9� ���hM�#a��'O
��s��'��C�I�9��߻��0���k(ʓ�;�o:�e�~���=�ˏd���D�ά��8��[@�O�=R^I1��G��N�z����v����6�)5�#w̱��k�38}�^Z���!���]	"��I�6��Bx�֣[f˂�,7_\�^�#�3A �(��ݽ��b���4^=ʅ��5��hlw՞���b/j�@K�nWY�vZ׻oq���*��m�0����9wZ��l~��TYvͳ�6Z2ɣ��eX�mŻ��ɛ�e�F�No�T�yE��}���8Qn�r��T��t�N!�	R4~�@�^֡��9+�;�����C����cTW'D�1������u�O�V�<�: c�3x5^up�V0���q���gޗC�;���w�P��t���h� Z�VZ�X��{r��x�e�f.Ow� �S;���gG��#b����G2,�Z�z��H�,�c;(p�v��L�"�s/(Ώ�ƣ�8ޏr�n�B���-GX �^2��pDᬗ�p�3� a����������,)%.��(�D��+�E��\4[F��uS�>W��5+�����i��7b�}��{��ؠ����{_WC\4�w�k"z;�F�J{5��RF��A庀����~I9�Q��cr��W/<�8M|�Z�&s�i�p��)BSk ���陧JW����}��z�5 ��µ��r{G ���ѐ�Q8�������E��B,�Mݳ$�%���x:ˁ�42}҇Yњ�ϛ��F`KaTB�(Z�&�}y�����`��D2pv������\]��h墺�yN��]����?NX/mVM�t�4��ѥ�!G�o�e�H5S��cb����S2B2X��>�S��2��d��<��a
�V�U�5��ؚ���qM���g����P�8���|�X��~s��*�>�)�綼?�C�q�.c���{tub���-�e�[lN���F�;]2$էA��C���b�������`OX|�HS&JW�@ذ�J�!R��Hz�٪NGʒ6��գ��G�Bl������w;�Vl!��O<�L�n���+��3��xqj������C}z�cq�9t��&��`�2�sw, ��8?��已�"���g
ω�a��W�g�~0�pEoF�y5,��;Y�3^�c��������^AށY1�4CT���ٻ�ϟ�����Sh=�p�0��D[8�����vB2�#��?���������~}(��IJ&�<&��NT��+d*�}ﳆ�����nqݛ?�!���r�,Z�.�B�����!,#k̩~�K�NqK�=����H�}Y�k�:�)�Ե/�x��]�	�T�^H�R��Q�AK�����nՍ��3Q,<�doo�����q� ���y
X�4>C��<�m����݊?�&������*AŻ`^�H�Ȉ Ր���y�2��Iځ�-���ʘ`�9�l��:Ӈ�ۅ��u)���)��D'"�e��ᙫ\���':{){ŭ�g^U��<��KiC��@pu>�Nh\�o�u�U�ɶu)o�<��I��`FԄِ�����^c(h���U��h���0�j���cz�*&�����6X��}�QX���W�7����,����<�z/�S'���ʍB�ղ~\�ߏ����C�qp���Vd�u48��	�X�����Ko�1���ƀ0ye�����^u�ƻ�����
͎�%�d^7���sɮ~���ك�����b�牖��i�:�}5���.�T��>��-
W�LoU�VJ�w#$�eE�p�����)b�S�(	4)�@�V^����t(��͌>s�&����(fa��9*�}�����|i��1�>N���c���4�M���/���Da�-i5Kj5��2KB)�UB��*�S��	")���C�ӻ9���xp��:^\.��*�a2�[��17<�I��{�|ߨ�I.��K�M�RI-�~Z�s�H��Sm�����b{,SC|��1g(@��+ފN����Z�g��a��8�CEx��O6��@~K^�s�䮹k䌏M�2lK5�)���`A�� ���&��Pm�Z@6d?" ݜ��JQ$��u��3|q�#����V��	t�z򧆀L~-�,t�>���Jy��ܵ�ci�*��t�,t�Z���|��Նp��*��阝�M��'�^O��Bm�5���ZUwB>�FR@ "/ (,~D�G����G�ReǤF����Rs9��&��%w��:gddQ�^6������dx
%�ka�8��탻�2\���KeU��nFߙ�6�N��Ĩ��z�uI	]��?p��0�� �i���H��j糡 ���6�u����y�N�\o���Y �w9�edl����ݛ=ys�g#����݂/f���Ef͍�%	mPS:Ey�p���u��x��T+Z(Ӡ�D#�؄�o��۰�JV0�����'�ξm�K�׭1��Q�$�]	���-�UGh�����s��@�^�u��2��9��#�?�Ғ�D(�S�,q���>���ۗ	֤����8Hz�����
ɨ���h��{�8N7���🵩JЧ+Ib��`�!R� �w���ߙ��[�a�8�9�W�0��/s�S�j��̔Ų������˞w�4�r����Y��j��Z�q^m;�0�wH��+�ꂉ*G�,���-�|C�ګ<f[é��Tg�&�$�&��;�E	�փ�x�[[~����=y�4 �۱EM��H�%l��mv�i}Ju�޴O�GOz˅�4=�>RӚ�V����R�������%y��Sp�F�8`��N� -� 8p�����[��Z)<�)6��4#�2�.hv,�+r.8ث�u�N��q8�9g;)Q�0��@ٿ�AIq(�� �:uj����w�2�FD�e���r�;�>�7������=�!ƌI{�]+�A6��(XF�j=*Y��~e�a���k�Y@}.��v��z��L����6@=���$�U�s 	�������w��{/�}$��vt��;��ReDޖZɅ�#�)d�!�+�xR�C��1!�c����耎Rjz��z�,��ӗ�5a�^����]**?�qy��v31�c��E����ҪȦ��hk�����6@�D�@"NζZ�/��f�E[#�W�eY��M�:e�Յ��9��I���,����df�wڛ�e˶M��Gy��^����:��Zx�9���uf(�{]H���5�[�^)d���� S<�.bCF����*���C�_8����+P�c�������_�1�ߚ���V�Y|��);ɿ�X�����>����#�d$\��7u4�,���dؑ���E y���a�Ї�*��\tT)�ʾ\.(������l;@�m��k65�����{`X>�9-$�����zrh�D��.;���8�������d���9h&��|�I<l�<��gy�  �w�	�3�2�+ G9����~�V \���3/}�}�l{l�Я�s���؄*|��Z�pփ]2h�V���k��bFfk�N��#.w[J�AH�HQ�ZeSS�wc��*� T���!���9w��h�bȮ'�B�7�|/�9�*3��I;�H�TT1��������<ԫ�OC��~�/m�FmL�<��ܼ������?>�},:�s�*�/�E���Y������ο���KS��P��js�s=oJ֝�q����}<1���G��
����W�	�������J	E��>��B�2�i�L��qֿBx�n3ք��nZ���/���-ֲ�_��Y*�m�A�����jT� 0�gh7M7������&���H��>�*��)7i�����_x��/R&|���	r��OIC1Ls!r�)4jZy�+���R#��_���D;O�/#�vg�e�/��rt��@���^���%x��l0��2�r�:�����,����.�Mf��E���Qt6rk侀�A�NYa�JdN>4�>��r	`�%ph�c2�V!N�c�W��������Ӄ2y`��]fߐ1�vn����v��a�h(Rh)����}Q�6���!B.��6��ϿL" �׼[[��$1�WE<�~{>�c𕛺M����j�u�2�x��o�R��1�͘]�P��<��EA�y�뵞-cޞ��|3�H�AG�)�h�qn�%�C�ة����U%蓥���wy�9U�Q��Ki�I@�=B�/�h�-��'5�[���5�<����6b��꾠��M_(xx�0��տ��>KM�ln
�I0FsޞW��Y��"�Tq�,<���9�3:/�_��od�"H�M�^�	��B%�+�SǌO\�����O�b����1���2��!��1�郷�-�t���o.Ŀj��_�;O�rS�ަz��'�K��P`��y��D�B�w �;����6W�e�����KD�9~`��B�HP��44J]�M"` =B��_�@N�ȳV��<-kV��F�i_-}�d˺txyxG�cD�dC����V���Kv�c�6Ռ��q�tP��a8��mǮ{�y��Z$E��Fk7�	���\,���C�(��ä?}���å���������g:mw'���}&Yw�\v7�ly(-Ř;�p���KI*S`�m����.Rxx�lhu/��RX j(�a@�4����u����v�������: R�e��+��-�m��N�'�y��jX�	�:Wve�� NwyH9����C�B����$}�k�ϟ��!��Ϻ�QD`�����(u��������a�zn��Z��3JрX!зQ�%К�&����lW�K]�Z��<lE=g��3��C8���3���QitPl�Z�J�z����u��-x�d��|����I��$:���<���6���W�f�7����Ð��*D�z��h�z�=7|�k'73��@A����9�߲ƽ�_L�_�d_�MX�3 d�e's�dog�	_ce�=7�b�M����0��?� u?�-F�u���Z��_����1�_����(��R���ڣ�;{����1��!��L��m��l�^K����~���X*Q��$�o�$	=W���ąn�eM+�W~IY�M�̰ ��quo���>2�BEݕ'�9�%��0�8k�Z�"���#{嫚R|�N�{ToB�3X��1h\k��VK9�����&L� +����ٹ��~�@�tT��R[��R�x2�vER 
 0N�����z>f�aSsI��QaV���C�C�_)�*h�)�i2�.|W@���a^y�1���2K��R<�[�x��ɝ6�HZ��S��k͡�J�[�])L�dU36�]�Jt�aF��RKZ���Mʟ��@l�_�U��}�G��8�޵�@�?5V{~P�bT���&�P&����lG͓�vm��\��t�z��qP]ӽ\RA�g��I5��n�`�@Z^�W���b^qcB���E
�H����LpL�I��d��L�Z�Ӹ�'qk��8����VwĿ����iW�K��w9��%����t鶴y���QД�j� 2�`�S�P�]%-_5Dt����UB�!��!o\��r���dwA�$��,/���7��l����-?�=f�mV��"N�* 9�Bjw�ᒮoE:�h9{�9�){t���yK�t]!*�ǖ�%}���]��߂wG�Sy���cM�~�OU���}����/���S�a�]���-z�cӣZ�bzIxpk���o�&�Y�@�n�7U ȁ/���ߪ%	��AJJ�u���+	��A]%;��G��<���Z�q}7�.9�h�i������Ҩ {�����f|�â���i!�����Qpc��8�C�GSeuS�ǝp�|L�,��Q=��@4�#�4��U�S\��?�+o[zf�?����wŋ�^���6��y��L=C�� p����#�B������{���ʃ��d��Ԇ���o���c`
�e�7�w�b|����9IU5�g��u3�5��3(���58�	>/�j���`# ���ȁ$��q$��t]1O��t��n����`Z����zތ�=v	��$@���iǮĽ�}��D��!�S�</f���h�F��h�0�T��_��j��`r{�aZ�i3��'^�U�j�F����)Ӷ{G�@��q��r�Dvb�Q�E�|�r��,�j�~�J[9�ч�JH�L��C���8ݼӨ�����m3�[6���8�p2^=?i����U��YE!IIh���=�ܭ��;���G�_6��NGM�G����>��r ��O0�fH�!3�����mIo�|�ϑ����p�Zl,�s�<�9��r�����Vm4���5e���&���34W�Z^pw�ʍ��l��i���vR63ˆ7�JZ�����.�|�q�z+���RgLM�p$"L�j�ͬ<"�/��u��)td&��+���k����͂�&�E:B]����*�X��Rc����rѼ�q$ÙP���1�)���o�`p�Q9%��0Q~���R�~Y��h �Hԙ���a�O�y$���YT@�p}:!O�Y�^�4����3
�b�ҡ�%#�ں�MP�9>��ӑ)W^_uK@���g�r51G�P���m|��3�ͭ���p(�We{�� /��=�(XuU�7���{*8��'�n�p�����3*�����O�%��\�.2"��Jn�D�?�1Л�@L�ؒ��t^��Q@V5R� O��UT*�Y��8*M��na����2�
��I��1X�*1;8I��x���&�p	��k:�1Xu� ��	�{y|����`����h���`��)��i?F�	�e6$����y5�����{�s��.�D70x��83���ԋ���x���~�G��;�R1hB��0ӈ�0v�!S�@GU�ogX<�ɚ��︺CǼ�ճ���I��[m�ޤ�
�\XuN�j�|ڱ_'��X���UNqt5j*��9�?�U��~�o�eG��ɶ��\�V20̵���iBRr@v[j�ユE̞l�!��O0�oy�Xu|UF��]BN���x����^�r3i/k��{��ooIN�D��n� �D.F��6\+�jf d��]۪/�Bqt�i|�Rm��q�8�I6�wT����:X�Y��)V��$jP?$�+�Ķ�6#3F�e;*����)}&����ّW%r� `�����<	��p���Ai�����"F��^�&�P��2¹y{�c��d�7����c����s	&?��ɳ�S��P�:���s9�&j��c�\|tD%��9ʜ��AuN�IGq��E9�ʲ z㼀���>�-:�ׅ��Q7n�CY*����K�GKY��om�ҟ�g�mz��@Z���Hм!�K�N���`s"�a�Қ64�>��%��=叐EW����?v��n;��7ǔٓ��Gd�ᨃ�@�g5&f}�Gl���f��!���n,��Y�R��gsT�Dx��G�xr^ȋ�C�p�"��`c����W�h�y�%z�U�����$�u�͖�Ϭ���׊��Rws��rx(���ay]"��v� ���z���H�Q�6I�����|Jq�J���!��җ�H�Z�3*VH�e��#;��K�v��*6$ �`�s"Ũ��H�w��zK��{��~C=�:L�s�}R��2$}.�Wڂ�k&����.�B &�~�g�����\K���V�=!0��ѧ���F(#ۀ���$�[�����hN�7f��r��/�,���w� ��9��.J��cA�֞�NG_Uʟ`0i�?�fȅ\����-.jʇc�����[]��N�tE^ʀ��UmQەn=���*U�L�gBQ���<��k�v�dW:�#%5>QЮ����1)�%�犿�6��V�����=�<.�f�f[�I<�b'-n<H�Q�[w��᪦9o�`�;9����n����ʴӍ��OB�*�G-�э&i�p��{B�V�W��ċ�������E�&��!˭g�
�He%��Uޒ���ۇa�tB�b���{";�ڋŻ��$��[)z�'Hf/���,s~1�� ��1RF���B�4tQȨW�)b�+V@B�5���kn�O]����v���Z��8�E�mC�P�:$f�~��Hv����_�g,R����zٖ;c}� �L4�H�o-�K��GP$�E��6m�Q#���z
�'�-���R�3�����=$]+.�L�ixa.�q�a�CB$q@����4�f��AT����S�.�֭� ���C��Kՙ ogg!��&S�єO��п��|2�`)j4�{���||��
�a=����z2/*gP"���ߡ�+F�d-�"�Z�[���٘��ҝ�N&�A��'��lQ^FLޗ\��y�u�����}���1��V;گs�m�
Ĝ@~�K$aZ�l6Dg8�0�#�h�A��U��Թ8�w�en�ǽ��8�ED�5�FX.����
�3��v��̲��Fp��I�fK�N��LK�PQ@7�OIx)�罅ӊ�}���1{�N;R�zaue�3c�����Γ�@�m��6���+�?�PǊ�E�I(q�g��'��D��x�\W�g��RE�Zc�*���gj4��7�&�cd	��A�!�x�؊fv��u���ZpE�;�NX�������/?�Hl%�f)�����Is�eIT^$�54\*����2lN�\�RÛb1�I���fz~+Q0Wp�����K�e��a���vF��-פ�Vy�@{������j�0j� �ޗ�?\{>qc��=Gc+}�q@?�0�.f�)��=��9���:��G���ƈ�z'��,Ҫ��J�{
� ��h]���Srd���?��]�;Q�v�a�:�CJ��Lk�3߁�<�_�UUu�x���B ƹE/ fD��� �9��Ou Ë^wT:-m�)�H]j�1�si��ԂDG�2�l���L����kt��Fú��;���ӑM�Rq����+��x�-,��R��m T�{�:�o�v�9L��w۩yB������ͶQ�db��:�&f�F��	Pe)
k�]�����Q�b��lk�vc�&�u��-���\�
���nQ�s�Ȱ�g㶽��k m-�l�� ����j�[��g�    YZ