#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4224347370"
MD5="fd48117833f5d82d5e1584e58a729a63"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20584"
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
	echo Date of packaging: Sat Feb 29 01:27:57 -03 2020
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
�7zXZ  �ִF !   �X���P(] �}��JF���.���_j�٠v��^��{}A���nFNۮΤ����!lI�[�Ǩ��]I���u[�,Q@�r����,I�~�إ_T%ٜ���qVR�m�aYi�=���پ�f��b%Be��K���M��u�;}vN�AN3�.�����a��� �#�\�n����t�&{���Qh��/Z�d��}I��qΞ'��\1�.��0i�$��v��o��<nG5wT�))5�T���WM�a&}/�(�I����"RE�by��D�4wѲ�w�V:�����UCeEgXv��.��SI�C@�_,�CʹAo��8i2^�i�J�E���/t9�&�*k>��HTO{0�dO�,?���%���m+�QIW�l�D˩�S��D?伯���%��oȆ��7��=�M�b(�r�·s��=�=i�����gsjԪ8j2�������[�]��R�}��U;��JD*)�f�7.�V�7h���B�[�t�ځ#��3,匦���u��z����G�gC?�*{u4_����#v�e/���n���њ+e�(�j+vs$E%H�措0OrB��z�i�S�c]�s�$X��Z��0�RfFw0�d��IɄ��(u�!o�k��U5x ���E��ZC0��6?R�l����9�#����?��@o���8���V18��O;�����RC��ԙ�9��o�R�X�t���J�|ƹ�LO�נ��#6��7�zIY���K_��C�}BL�ɂ����k?="�Uם�=�#�i�epyT��D%F0U������ ��ʳ�}�����1/�N:��LF����V�M�� �Nv|�Q6!�l�_��zE�նf#e��SLW����E�������K�# �Hʎ�mRH�f��������fVs�7ߞ�!�~�j�he�7�	���1��N��^����ĵ����r���u:&o��8��_q�aTj3`2�V\]mR�IBt:���kf�m�*}��Ω�r�'͔��|�L�PJD�9>R�>�ǋ��tӟ��Y��H��z$�!~ݠm�33^Ո,��F�Y ��E8�� i�E0��T���k�-��v��/Qj��`��.�,o_���;��S�5�mâm�'V�U��̢�x^�����
�⊊r���[ r�{�u�)l�<���(������0���I�S���e�� ��������q_�6�5�*��9ŀ!�u��I��+�4�/�˘�N�gN9��'���Q͢�T
8�쯲���� �Iɭ�<�|cU={�ОߋT�]�*F�`E�}ݕ�`vb��9�}w�͐o�]j��!�xw�y}p=?�V%�L|�Y+�E��FK�y{J�tz�MO�ɥ�)�p6�äj��4�u�֎�9~��o�)����ց�)S��Z5��\�X|��0��'Pq�/t#�ن(��N��d(�Y;�3�T�Ͱc��闐^IQ��͒�9f�^ �ՙ*E�pm��#
�o¦���	T�1��S��9>��� `�,t�vr�^�R/�=����Q���p/fd��Pi�^����3㹽Mi@A��g��n�u�`W{�R�S���H�[`�����~k��Ԁxp1���Հ�����\���`ZD>D��>���	�����O\�tE����z|Ci���"������<��wV=oAy_�4V`�~���2�{O@�:;j���Ѣ��$������,�F���)��;�)/�h�
,��]���;<�\c��g��h�?3,2��I���f��9�M�y�v���,ab!�x��<�ׁB�a`m�eT�a@\O��C�
���I;�����;�*�h����P�{,��
��.�H�8��	�T1���'�$�#�5W�}05����r�^J��'�z�Q�I���%�����v)��8<J�.�x��T��!S�'���:+�r�`,D�H)��ַr�%S���^��4�����y��=�_����->���"������� U��A' ����ל�=�|��c�p�=PJUk���Go���@�,z�Y��W �So��c#X��M�N)cQŒ�.Z�`z�ͤ�>w{��?���q9��t���2M���p��/�檢���&`��!�p8�bAk�Oԛ��&��U0f�����d�l��/��>����b��l��I��N�, �*��n�G)oY��5[/�
`.��>�V���UK�m�G�%��⯚ם�8T����-k�v��.�Z?�jK~n.Ph1g�4�.��Z'J����LKנ�f���ڼN]ٰ�2�Kbr�#�=�?J:,��d���:��%�XO�>�M�3]�O#ݤ4��qv	�e!�8�iV0ҟ�V���=�O�>����e��������-w����Ј{�DPpL��^�}�l����p��V!��W��r�����̱��Y��ge��Ú��3*=k�=	xR�QE�7e� �iG�x1iM�leZ0�	?d�h������v7�R)+����/���`dta�7#�nGlK��X �����f$��F,^'KV��pf����Q�_uBO����ƕ�"�I���	俟S}�s�jeh����sٝAP��jyLX�����T���9�fݾ�yKK;;~��`�X�i>u��}W�����l�=�%��bY�e��R{����_M.D������t�׋���m%]��E��'c��T�n�ϛ�A�~��2����d�A�U��A�?GG�&����֯pW�O^�?t�u��5�O�!Cmp�?5�C�c�r���TH��X�\[�s�[4_yHϱq���l�U2®��65ƛ� 	�܏�>taj4�m�آgq���d~R�ivN��|�\JP�P��LĨx�������\�j�c{�2$Hb���_�E�h���Z�(8��ӭ��>/��C{���d���_+f�� �®uRkaՈm"ax5�/�`�$���]�w��q�T�D�A;��$�q�42]���R�u���(��V�^1�Y�~���9�e��?"�$��`a�-�6Y�F�a����"r������>2�q4x���5ݑ�[y5�Z(6��'�J�bl�$��at莼=�aqtˎM_ox��BD߷�v�LNL���.v�k�` ��~�L���Gq(�"u�tvܚAn�d����c�F�����D�)��-ٗw�C9�i1��m�]�ʩl��ɦ�k��V���P�纚�۾V�\-o�7d���� ��}R���Ҹ�E���Lb�]6�b_R�vrߵU���u����LR�����*ڽ����q�Z?�:!�����<�]a��1�i�1҇N!h��2.��{�I�to�z�v�V�h�xbK\�B��	g6��o]�3�XZ��T��R��4�t94�V+}:��Ο�_����W�H�z������_3�e~�L<ǉ���d)UF�Q9�� Hs����P^��sg���=���mؔk���.W��C;��py��多{K�RJ��y���
y�cG���J�e��D��+¾{.�V�xnLr%���?����.P���P�����r�ϵ�kQ��e��3���@��P�I�ME0o���1]����P��W��]CrSb�i�ٿwP�e��V�x���Śe8V��J_y)i%���:�C4�oѸ�Qv4Y:W��C�K������_6�t$�R���w觡6���������y�@�m"��;��7\�)�%�����jJ��y1jr�t��-�� 4p����J�7yx�KG`�q.�|Q��J�og�K�n-��]I�nx�0�pZ�Ъ�a�qN���sb*�� �p��J�3|SBT)ݺe���2�!�5�W~whC�"?�K�|}�����n��h�!�4��d�x���֩�h70wlJPV:��B��cb���k���6��o'�H���݋U����	��#?��3�G�)�Ꮹ���@L�Jj���S����B�Dҙ�G���D]v���aw53����񧝻�\g�s�l�<\�B�%�����P�m����2�TΪO����U)p��P'R��k
�ңQX,9�]�l��F��N�|��&�?E ��*B9#w��iC^����Z^*�
�޼��d1^���G���E,k6�8G�$����d)Ep��E~E^q_ݠ�}K!�*�ॉ@���=jʎ����4�NM-r��d��S嬔�&nUa�6$��Q�/(��k�n�����}�X,f������=�AKa;�/�`�]�Q�G�"��,���Zn�eTkQ�^�.��W[f�z8�&}���R�th����R� S��U(���gK��`�Bt�Am�����	<���8Op�|8�K	Q'2�E����,<tk�'$-)
Ō�n\�w�q�/���/8G����qx]TTIu������2�ֹ�	��_d�<����1��~�pb�2�d#bL�EH@�P���^9�(�4~/�{�
�^�B��Z�-hf&_�
�K�T��T�'̩X�W�~3Fzv���d����K��T���;�K��/�`3��4�@��)��=��z�U5pd`�u�-�Du�
o�T ��KLNZ0��Ͼz{O��ӫ�b�0J��;��=��%��S����~��B=d|�g��F.����E���hJ��z'�s�$�获��)aB�eO��ՏQ~QZB���<(>fs���4�5q
/�'��W�lFf��@���8�k��v��]^�����q�da�V&"KU ��|���L�9H��^3�����k�My*gsGՙ�_eoR��O�g4��+9����?L���j�G'���Ay5��X�l��hY�&�j�U�ŧ42�=���_���B�k�����8ϡ1�H�1`~�V�]�P��P2��y�Y Ǒ�M �p6v�C=�/,dMu���'hX�g&�򃎋�g��� �'��߼����O��R���(�`�����X:K�xO�`c�ͬq�9;�a����	�e�1�Ҙ����ZǷ������w��J�};t+�LVR7x��
�������*jr�%�o��<�i|R"�W����6U��[)�����_l��o��S����CW}K�]�Gs�w�Iؚ> N_�[�b�R�����EAI��j�$��1G�P�!2YM��V�W��^*����u�=%$�F��`y�nzMQQI�s�*@��aA�R���K����$ư�<�̿o�N���y�ÀR"�ж,�T�S6z~��U��KV.��h6>���^̓p�sg(�^T�}N�yp�-)e����������#�4�@'�Tj�健%��mͫ�	)p�n�hw�L�BԽ�_�Y�G?�v�2�,�����xu������1��	5�E��ߠ;!8
�<�۫	
����t���`�*�c%p��Сݞ�)���='D�*��BԺ
���������CZ�i��v���itt��c
3���9��?��sz)���|x_\,	B�t�Ǟl��:Xt�{yZ�{`��������಻��Z�8���Q ����=K�m�l����l$T�/ˬ�/9�TY��n�!�l�-xԽqf��x�!���<J<��!�& ��-pwi~�l����l��� ̉ܡZ:b�����0�v���X�<�+d�w��)$Q!���+�:�R�m����J�E��uS�W9H��PT�)�S	��¢)��5-��:����/��yV須V,C�Yt�پ��Ț܎�M�'[�	S��d�T��@2V�~/���`΍�A)Ui��5��s�Jv	�7��2����v{�UI�؞6Ԥ6m�l wA�V	{��
�%:%\!g��B2�ԊD▗�8'�p\���V_��7u�E�<E��J� �u=|ܣ��1z Vo}4�&�-���?�b�Ի|�&������/�z;�b���M��w���%7�J8�'w�p�2�ʗ�/L�[7H���_&��lym\�a�����p������K��(�`dq o/��^X �,�^ZmYAM��CW�v��@O8h��!�+�3�f�y�-i��E�F�#�1X�E��5�t�]�:Xut_��<潼�Ċ�﹅ȟ�P�74X����-q BrG�����8���q����ڷ���o�߸�g� 
@��X)�oc�93k^�i�1ڹG�σ��Ɗ4�1M2�+�e͐�Fl�;�	��Me��q�Ր�@����QP5ι��33>��/���b+�u0ļ��1xY��ND�2�)�K�X�G�
��y��j��sf�������3�� ���$�iz�1L�/���hB�Ć����w��l�0ʯ�눺L{��{%��]�cSQ&�=�UTU�F�^h@�?n_ke/��w3��;6n�z?�Q�2�X�����l洙A�Z)۳S3�]�ч+�mD��_eǾa���쿔Ƥ���	>e��Y� I� @��%�4	����d�9`�¸��5Wt�-'�SA�8~��VO��b'��)72�����X�4Չ�'6�X�)��3����3���`B9�Y��g3�ӌv�����ؠ�z �Vh	� MR
���R"�+��as=��/7i���;��� ���	���3�{۫�x���B\Q3�H��bO�\�����Y~A&]0Z�P-i�1�J�	�y�6 �;t;��d�&ڜ�����0�P� �~g��	���hV����j��8r�vh����u�0�����ʃb�^�b� �.���1�2
{��I���8WO�8<,��:g�$]6eZ醼E��S�W����j�����>ͻQ�w�Ϗ���QW�@�ȸ'̌�;�B��x�5ioV^q�[VR��E��J���z)3zQ*y����U���ҏ��@�<�z5���Kݵ����	�=&���j����I�Mң;KB����_�'q��[��$��ir�2��11��̈�x�<���-Wv�nb��p��u��*����ym���ó�[-i׺����`ه��������4b�Ք��*鈣|��we���*�~OW�K-#�B����sb�u\x�~,e�-�.|H����Zg* �Ja�#I
+�hit��\SL+�ȿu�DC�����ј�ݔm��|`����� ��PT3,��y����<�xh"�uO�!l����KC❁�=I�><?�s�uŢk3,@n�_j"ÀtCR9�p����UW�X��BV�7V9z.�T�U4�R�7�/|g�jZ�8i��\h:�	�K��(X�WYϫ�$�[� ��Յ�{w�b����"��Z}�-������o��f�yq@X�o=r;.��w���IgHG��S�%�C�h�k�7?O��5 �� |ş��흳6 /n"����tW<�P���z������R�y�G?�c½�*:׽D�>��27J�0�ܯ��w;�����_*̞���=��V'�f��"���ZmԒZr��� y���"pj%� ���S����8����*�L8B��c��L�N���N�i��Ol+K>$��!��g*�'���w����'r40�|���*	S��2	��fv���߅�P���=�J�N��Ȧ�� �vkJ��߈4N�d���DvnĮ�š$�g�:�ekF�Z������R���r��J�K�t�R�k�1%C��0v�Ƌ<i��o��Kݖ�7S�<��F���`��>�r0�rE�]T�'���[5��a�� ���e��j��5FM@��[��^{��Eq�R��!��Z���v&�-�#�;�V��S�$W�\��e�;�����Vk�mooE�֢'�>�$.�7UA����(��)��Q���)��`K��5�5h���϶���l�\L�n����Z�X��� 2ٱ������� ;�J�:���r,S`ո�-Rx^�i������7��_���6U0M!d��GϚ@�Q>�Շа�OP>�pl��{T�c�M6���C�T9bk���͢i�f���v���y|خ[�+�1֑���B��������?r��
�ސ�f<m��k�߿�0DK��cb���=��>��M��4f7��@���@2�xrL��"���"@��E�=nQ.rC�q����P��h���[>R�@���K@k$X��㕥z;������xG�?�7��ro�lS�k����#�u��!qkZ�
-����)Z
�^9�t�v\F��N��5�����4�v�O�8{l���k&�ؚ�=N�?� �Х[����b��y�#����u���"��nfoIi�>��S���<\k�c�D��T��(��|ݣ٭�ZbRSz�2��x����Vvp;����V!�<���
�{��;3�d����� ��2H-���������q�������{x�Y}�9�s�Ur�6�pc�s�T{<U�F��)`s��R�P�'���>���J&��tV:��@%��>u�Ts���DJ��mxѨUc�H�$"�,��v���i�`�( ��������N�J���
�Ő�1� Վɼ�x��#�TF2�|ۣ.�=u���>
�B�L0�C�\��]��{1O�O&��g�jd)��lA���s��i�q�ow���i�ĺ����A6ݦ�{�V�@���!�E�7�edA����,�S��\;:I<�q�������n�?��S���q؁�7#�p�xF�LJ���bzC�$�0vC|�2h��;&AQ&h1���F��G�&U��DK�	�;hN��I%��o�T��y�I����-
�1����5S	�f�*c�P��\��]u/Xy�T�K����jAF)�Dv�ް�#�^U�4>�����Ji�|[�CUM�
�:�y���VK�ɞW�y�}���Z߃�^j�j�D�-�F��yҗ�|0����Y!���A�O�%&��b�4_��`�N)�69�ߟ��.�t��ρ'
����cG���� �=���F'e�/Ŀ��+�1ɼ���z+\�(�K�o�:��x�\7��;��0{'۫g&�� ����#�ߠ�1���_m��g~�~<#�{[O�w�f�-���}�Ig�./��M\��+qŪν�����X�������-�S~��.k{"vf���e��6%0�j���ךQ�����PwQ�.�-�W��ESo.)��,i��d	�;Q�b�>kq�\�?��r�-�>9-�
x%��2�}!#��jr@��>>o/x*���z��17~(��SQ{�1�ϫ�T��LU����;_0�*����yo]��	
�2��,�z|'vc6pDsB)�o�u(kX���\.�p�RumKޤ>:��جה���W�"�2��+�D���������/)\(��W�*\V�d�\3�y� ���=��"	�)E{b��6LJ\���}�����9�)3�Sh����p��zqV���<�xq�"��[%��j�['��ƪ�-W����ZFi=�yS����~��$�C��S��d�\�S><p�prM���B0�2�����'��P�GJ"�6[#g����㻭��������x,F���jǚ�����p�la+��3���Y��2)У�{ 4��aT�q�R�� W�D�J�(��c����xV7�-R<��O�l�~��bh?ûD�&��ňp�������Y�YfK ��0�����Z�<��;QK�<�fJdc�L�m�6�Ŕ���@�6p�jfA���< �m�Gv;u��淊h�T�7�Si�'��F�Q�uAQ��Z�R�gsܞg����b�R��XlӳuD�f�ȯ��!�y�����^��?���fz;ǃ�Qa}C�4�䷤7=.�NW�Ξ\��[�%H�,O�-+��x��7���ae�7`�,*�׵>5�=����,)�:Ij��i6z����Q^;ֿ���D���l�>"��\�hD%Ϡ����WзỚ]\�	����]����y�"�k;	����ٹz��O;v�?^�
�~��)�U߀�Nr�aӈiL3D���}����I�����M8�X�����U�����`�5�I�뷒�	��SZh!1���]tuM��)�N|��p~��མ�&�ݸ�ߊ��+�U�6v�l-g�_����� ����,��6~���Y��y?G	�8ʛ��&20���>M����S�nu�=֏?�c���K�5��l�񓭆7���L���� z��;X��6�/K�U�L�t2O2Xi�`F�(kQ�D�b8xI�Ы^ `<]���̌�&���M;��T�O;�PT��#XδQ{��i���m��[!�A���Zm���*�֡G���.u>8�D����(8a�L�����l>!�H5/y��6b������2(|-dz�68�;�N�Z�|6��������*��J߂�Ϧ�B`[�i���#�0��#�V���Կ��o֝q��g�����ꫧ��w�Akh=;�D�d�0���5͟�����%GC����.�'n��)�ƺg���0@�s�ֶ?(��ɨ!!5{]��&�̽��L�����u��7�k��53q%�$^�-179�-Lͥ,��B 3�G-n��I��jwv�p��n�g��rW�}P�W��/�;�kJF�8QW�$���L](_UJ����P���� -5|���<���T�����7�O��u���FK�h�=�?��ۓ���3I�knA���@$�m��Њ��RI������>��"El8�ҀI���+�v�P�H�§���ǐ����&l�=(��\�@�7;+zh@ S��|����]�G������ntuQ30@c�6���"2���D�gW ��J����?�����4�\�[ן&~��H�
����]�C��<?.���.7�li�+�ϼ[}w=1�?����g���X/�s)}�^>-9����o��S#�B�K��y8qIB.;�Q��	�O^��	����?���.�l�����Ԁ���(�,}"PU�b�q'*�ز��-�(Oo,?c�n$NFT�w�w�������+��?�1�}/ J��6fg�G�z����q3u+u/�Rt:��"H�t.�L"�+C�l�G�.��®sO%)S�wP�7�n̓�zRos=.r�C[����@Q9<���q�8�7��P���N�x��/������S �M\Պ0M,����{m��` ,�n�z=U�N ޳���O�nMR��р�h]<�<h��b�Jr�Z�SѬ�z�bBL�ӊ�����+��,�J�G���37�7�QH3"�� �J}Õ�8(e�Δ�r�g��r�c�ɒ-�"qM;m�q����M��F�/Z�������d�t:����r���	S�nu� �KB"�ԟ�ir�grƐ,�pjf�҉G�x��(a��"����欭P��R�?�m%bu��,9�,���]��V"����f�����u�pw̖(S3Ԛ�CB@6���.��%������v���f+���*����C���7�<�7�+��[���"��B�a��g
��"�o����j>�(f�N�@V���T.�n�s.����/mR���^	�ϳ&MaN�D�쬂�i�e���M%8/7�2�����4W�c]�[��{� 
ӟ���Exl��$�PS��>�XAz�H(ȣ�Nָk{��=�bՔX졫�Oն�{��;R�!k��g��8����T�( �����7�0���Ɲ��^��Y�l�_lYk�4�g��(qSQj���)C�9ױ�:29ߙsɽ)�tz����+�T�9yH�9ąjh<�ۢFQ�O�Ε٭�ԛ7��U*c|%[��LY��gy����R����>������F��E.�p��\xf��VG�iH~�J]V�v���� T�d_�g�a���4%,2h[�CfS�����n�D�Â���;�CD5�&��"9rg�8���<N��}�G����3����V������W	���\�D�y��U��yC7�y��nAƅ*���R)V	��I�����WXӌH�?r��,A緡'�feLKk��hD"3���GK�2�N�NĐŠQ�v8@:D�猪0�Wm򤡗��q;����a�z������0y ֲTJN.T���{��C�/�nz�mh���h�a�Hʀ�VcX�y���f�c�&�ù���19�q���z�R�"B$��;i�.��뒎��h��*�҂LR �Z�8��5S�=��^;eނ	K��׺�� u�."�,�dy�0^b)�*9��?�
;����QO�l1���� ����M���U�Y�ꑞ��@�ۓ8|3�tVi�R�8���k��h1�)}B$b����-|��0���A�Ei.G������^�Xi��_`�[0����I�,�Y7Ҁ�Ŀ B����~5V;X{w�qMZϗ*28j����q?`a3��Y��Ta�(V��?���#�	��1	dq۬_b&s�:�7YHG��Ʋ����\n��9 |<wl}�������a"To��i��f���V�C��(s�q8~)RMc�1��<����u�ܾjY^<�`g�<���ܝ��X���1>��Zw�V��X^��C�;�z[��Li�'���-Z���}�C��P��EV)oT���Y���l���*t����=�2����y#��CN�mB�(�V�]&>��`{l�Ƴ�̧:�=R-�Ӓ1���)�|��K+(�lk0=D=��<(�A���Q87�PPl�J�-��CX�_��9�YK��F�
�˒�ރGT'��<Qm^x��Y0������� ���k�|�����Ôt���Vڞ\3��1�u���^�{�+rC��H�kk�/�2���d*J��NZ։���9�p�8�O�B�1�h�����Ar��і�c�\($���[,�1�c�@������?x�ځ/|C��@j��Y(j�bů��8���[G��*u �k�%k��Qs�(��� �#�F�oc��dXr�@6d�f �qw�)��*��(�k��~e����8���|�@�Tz��Vm�B��r��U���[B�����qL�̊�:�*ҥ .�5c�Ϣ����ܓV�W"���!���2r�����p�R1�*��'@�d�
a�_��~�Z��n�nY��G���ޖ.$uO`e�P��`��Q����fi㍽�c��;w&xv�Ҡ�Ĝ̍� և������S#����У���v��˛�@�*5���wxz��f�|H���~X����[�=���I�,���<Du��
�7�0gʗz��K�]��ص�]�/L��T�D^�7���W����s{� ����(�gaإ!�p�����1Np��j��KBP�p�N?���~��8�=*<4���?e��T�|�z������m�)Qҧ�[�ò1��b֤�����d�HQ���c���w��H�2d��~q�F�M�l6����l�r�i࿄�V ��c�5�3�=��0Q�I咧%s��݌	,��t�b��`��#�|��˲����
`2tC�kN1&��~E�|��3ʷkӉ��!/���C���e�ߤ��R������|v�x���~ɷ�Wx,YTs���j?���1*��ř�n��h��|�q�G��=n��hj�����Z\�9^�{l��׏�do+��>�������yDf��-Z���I�� C�ⷙ�S�s��#�3%HY�n�M��Q�y���`6V93���Z=�f0�iI�Dm�������H���Y�>���u�H}�w��p�k&��V�`_q*cg�z�,.�ug�<�K�f�'��+"��s��U7��aZ�T�ae`�]�^ƞє��"��Jwz'��G|l������J�@^����R��(j�_� 8�׶P����|E�d��j|r�Y�g��p�S���a��٧]�s	�c{0�E�C���
:�E�(�KɁ1��Es��k^��F�FN��g����X-G���3���U	m�@fr��,����߷�a������#�z���x�Z�����{�'K�$s0'^�+��?|�����V���dΗw]|&��!d���8�R'�V�*�&�h���%[���`�_�抙��G�V���&Y�x:�p���z7��}����h�P�ןNN;�L	��m���N��VL/��L�h�u�qZ�X/�D{O�V~�H���ћj�k��NP.�~��!N�3�M����1n�����C&���i�$�J(@������2em&JMK���i�,�$!Z����a�C�z���_��ɮ!�;%�$.lZf�ͽ* ��֕p�2�G�������9U ��Y217�ّ30��'|����N7n*�`�@ײOrZl��_�����S/��G��h�ǟ��|{lA>��5B��!O���S*���*��l�R���7�4rbD�Ʋ��{�~("J=K�M�O���@5�X#�7|��}<��sot��og�TǿSh�gSy�W�����Ω�j[��̲��nTH�u"��R�c��<9���l1�S�+&o9������8�g��r�N���탖��S0[�✕�h� ÑN��d/���;)�5V�_��t7�_�~B[��������c#[�/�Z��,��TY�da�#�s_�����_Ϳ��u�4p�b���Z7`�V#���}R�5������s�s��ɳ�ny�<�����)RI���kQt�H���UPG����'5�uL�{)�>�Y�2��V�������f�ӹ�.E�ƅ���0�na�퍉�96�eԪ�2��+�Ƴ��-���p����%ڟ!_�%f`a�upx>�����r���|H�}�d���`�M���u�����2��_+ck�2�!��wy��2�v� C�����U�ի����K�;�aj0�����B�ˌ���x��<�Sz��t��L}���L%�	���<��TR��ݾ+���{��;*����,�Q�/aId�F�h��ש�pQ��=/kZ/FS��6P��Dq����A�K����O�W��
��wγ�=-��^�F5_y_��d�R��6�v[�=���b��V,l�{�I�p�8qOX)����p�������ǆ'��6��ɘ��p��ݥ��e�b�>�:a0��'�I����Ѷ�$;�b����bMoD4	�0X�˫>J �F�^�>�ݰ�9��Cd�ep�O֠�6��Y�����qD�����c1`z��T����^�H�o�`C_k��C��;R���I��9	�D8V)��
�9�S����
�.��+�`�����+<��W�Х��V��nÀ��B���~C���]��Y�@>.]��pl6�V�k�����]�j��[7��]�����4��� �E�'/��g�ٗ�V� �@�v2��S�y�{���_>��*��>�	�^�����B����CoчFn58�{��.��d�V���ݲ�
�^t�ϸ�5�ך��ƺ4�^`����Z[����&��h̨G�~JQ�[~2��ܺ _��J�|tGs�3����iZ\�|����2}Y_�Žtl�ά�-_x����Y�g���7�����;h1�`h_j�'8����gn�5и=���C��W^Z���2�qY/ꭽ�F���_����w��;�x��E���4�� R��$�ܜ��e������O�_�͜����� �\j��Tn�5�D�Q�+^���k+4����P�u�|r�0PPA��	�A�G'���؏�ė#T�G��jЌ7�<Sۤ�]b���n����؋r硄�2,ί�ܫu"q֔S�e�Pwʹ7ʩ]?��w�sOv�꺟n��V���q?Kh5�]� *���DNl痋�"�y���)C
엺��{ϯ3647���)��17.���v��˒�ݔ��^y��7���'bb.�!]X7%]E g
�E�L�pIm�w^ ����v50��"�G|G_a ��m@�����x�B�/Xi"��*�g����n�����쯻Q�А,ץVjW��Ɗ�`��a�I�`�C�6V��^�`�A��������g˽_' Y�[�Ȭq���j�Ԯ�� |�u�9D
��y���M�|y��y�`������a�9Sk�� ���辪!�*p��Kʆ("m��C���ҁ�M�Vzw�^R�F��g���lG�������J��?�K�.^�	��`�
��X��ڗ�G/e"��s�F��T�ٹ�z%e���/��~U��c�fO���������dD�� ���e �� ��W�m��T�Q���h�bΏk���%�.>U�Q�&�]FnW��;��:l�@�.�`�:�E��߱RM�2	���o��ю��j�"������� �3��5�ee*0�?e���1�a D� ��vx�����H����-<´{}``�}�S�±8�VE
���_�.�ݩ4&��B|�����3�����Ur�(��3�������O�ɸ��<}��$���iӅ�N+	���bʏ)���_�B/�\���~���H�	�� [?iF���nnDo�63<R�_֗hs�@ �@������:wme,��L#O�׾��&YƔ�C��o0Uc��I��f�u��ho>}�+�����Rv~��C���Y=��	��ρ�s���=�/E��������U>i`�KgA���T���E(�q���d���LKN����uE�oF����
d���At����F�ո\�=us/����x���!>QY!���q'S�?�.p�J �|���|0���=E�)�{A�D��Mƅ8j�8��W��n�:�C�w'k�7�W��Z�Ǐ���ykg^>+v{���:���˄s�v)��S�'�"L�O�q�B��ԌD�f`o�7�OB�i�]�;}�Z�x�g5An�VI�L��N�!ch�������Dڱu�����u�r�_�LZ����1�q2�8������	� [8\K�K�n��5�5=}e-�ⳓ��X&"
<I�n��]�t��(��9�)��n�m�W݊x�AJҀ���V2C�m�썢nnJAQ�5��v��=��%��6,���L+��Gc*j��ӆ0���|��}�QhaU?v��Y�X�����s�4�~f~^�%Ig`΂�=�?w��F��[��q�֨�����`Q�)�"ΐ���N��q�lk���\�|m'�$L.0��Q��ک�s�\����W���|�,9Ǭjo�J�`����;��I�b�t������d�V܈.s�����˛]�ȕ#�4��1C8U)
���"@c�if�\n���v� �-���:�8�`�ơ%t��W�vz����� ��"���&�\�g�Q�&b�Ja֕�K��7���ZG�j�Π}�\K�:��e�����o�(e,�u�{���a-��A��(q{�C.DWB���0�u9z�/�3��h��9l@�շ:��~�|�|�s�#���ԯ4ӳHˁ�E�}f�M��_�E�2W��~SيX���Ne18a,�'������V
�{~_��ф��f���ި]�P@ȱ<z9+c+��@wb�hE\]�W����?�[*��7�A��V��,���Î:'P�l�7�llvj�ʘ���F���?��W7=��?q�=���s� H�2(pT�P똾���X#�!j���Y�S�k�^��d�R���yV�/�n�q�y5�����+r��޾a�,�K��S)+��n�߽�?h�9�&[�/lx.B��7��m��V��ȶWS�\�� k ]��Y��+��.��`�.��Е����޶n�@l��N0�!:=���Q�Ȱ�i���Y�r�B�7b�%�'.x����'M����x�l��bb`��s�6'�Wʆ���|V6=�$��F���~���r]�����7�|�-��H�{
�X����c��*i���%�����A��Ѻ�� ���u8]%��>��G�	�aRZL�wj��{��ٙ��.�����A�]����&���-�;s���jYdUMC#0D;�:�P��--�W#y�L�l8=RjJ���L�V�OO0U	N Iv�x]ԂGkղ��P�v���	�F�k��1]'\A���e�tLE�����Yuz�Po����rnBX�#^�WڞC�{00�rp��:TK����N�ܨ�X�ıf�ܐ�{W�+�1b�[@&W �h���W�e�&��>�u�_��ߟ�1`;ݲ�����	R}t�]��eso�3D�ʚ�φ6]�-��u"�G�:���+"/_�'tſ��u���
ά���gM�A��܇_�A:xV�1> 4C�f�j��㦝�5�ɻh��i�?�h6��!�"Be2���3-��P^?F"[ϡ]Ӱb��+l&Q'�7�YS��*�)�c�]���g�k�J�8�����v�'8Qg����f��y�q����\EA�ZH��pL�[����,Ֆ�Y� {�:Q/w�
�E�2(3=.�2#��GU�lD4�aܦh%��S0��e)� zeH���9�����RnԢd��ZX/p�����{�kX_W�� V�d��k��:d���M���0!~�!����u��"d�"~�Ӊ�q��a�6���j��~q[��Sgu��Iۨ�9�u�Wt�dy�O�<�ƨ�Ƭ�����	RІ��M䀯� "�1|j~����P�$�P"/��[���-�d��'M�������-h��I��J�q_�p�VK�"}�{�y���Ma���JcЀ���h�ӻ�c������sf��Q�ζ-14���=J	Z�4�P�V�a9��}l2�sX(��L9�z�mpc�pk̃������U9"����opeC� \VJ���#N��!w�A�1�5v,ú5:�1�� �m�/�?�����lg���9��m4�Lד��Ae&5�+���k&Vw�i���zT�}9�B������6@���t��x���ϠʵbGw,,�m5?�1�>흦:l,�/΃�""��R�56�pG.'�B�/|���� ��mۄx$�q��S^^*H�]���R�E���Ty���_x+[Z+��)plۯ���%��[�VT�;M֪�̜���>�}Č}ʯ�6��Pǵ^� ��R1zQ�U�1�Ȇ�e�Ή��=N�ܻ�uF�ħ*U#�,ߩ)�ԛ�n�.��
	�2 s�U�_�P}����~���s�I�ϟ�gbd�J��͹0uZ@zk��;r�'��O�T���QR-`�K;2D�0�*���z~�>o����X8�c��P9'͜���E@����/҃T�_¸��'AΚ�q�F�Pu�a�Mt�弢sr�2JXoc��3��}ӎ
p����|�d
���d`)ܒ�8��;I� -�'�=�O_�N`E�j�������KH�q�m�>�DU���)���)�"��,��$��xQ?�OI���7��!�z��1��CE�N�nf�U���n��I��"5������傋y�K�y�=G�1�D*�0���K�`��s��p
��[7L��;`f��x���AM��a�Z�����ySwv�D��(F�#��':� �3��ýH�6�`ev� ��^�M�zR,2f	��.1B�졌t���?��h�>u��T��.��f��r��T�xy��?�E��|_gXgm p�]+7�HL�:j�s�qW	$��������>w$��b)� �kE^�9�!�;诗I�R�x�3����a���w��0�9Y��.x�]�*ԥd�ާ4�k����}k!+���S�~8z`&��T4����I]�kR`��d��[5�J'	)aڢ�D��J)��Ai�g,�k2�y�+�bv
{I���8p���K��p�[]V���~5�?x�!���5��<ԍ;������L�4���@h@�ٗa���}ڰ��c����f[Z��g�C�RB	����Ȑ�3��%2���((��q��_k�Y��o�l�;�/m�z�x6D�D�k�A�\|�<��X�1�O��O��׎����>8/ap�ǭ� Z%��9_�������'J��b�k�O��(�������1�MRԦ4�Pl��v���+Ȓ|؎ɍ�ņBΰ�h�q����EF|ܖ���8��b���Q$�-��)�����˟��eA����`��׺�)W�]���"S�$�Z��(�:r�g�ƹ}�dwˠ�`��I��R��:	��[�|�]T�w�i{�B�x��~Ql��k�����;NP�I�~����>x�4%� f�q��fʙ�H��%��]����-:j�ﯔ�큖��f܍�.�`�)@��.ZC��y�L ��o�?V Ġ���r�'��g�    YZ