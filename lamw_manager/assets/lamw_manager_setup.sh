#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="579433630"
MD5="2c0b64acde20a54152e2512de3845780"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23312"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sat Jul 31 16:52:13 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D�`�'�܂~�8_��	H��ݪ�"��k#Q�#���i�t'���� ���i�	��q�6�u�S7��k�В�v�'�h���ɬ5�B� ��Lz�/����w���x����b2=����P�I{O�v��2���f�<c�J!Ϳd����E��r�%��ʖ����'J�*h�.[ ��� ]�!)��5޻�ʢ.��&w(�)V8v�{�B�Ӓ��$0-H�vȒ�O#L�#��g�`e,E���/C����H8�%��) �[mB�0�h�l\�!˰�V�����c��еpۂ�&���H����|b�i�@R�bהΤwY���Rư8���ʓu8�X�+�7<�� E$����BIF5�{ �I삒�} �m�F�g�CI�#H%�S-�Й���Ju��5>5Z�T���_ַk!w��PƓ��:r^�OO�G���1��	��yՒ�NW��8(���SI/�oIC��sZ۵J�'��/\���#�*����%���K�d�}�@o#Y�q �?�J��ϬC	s���賫QwQQ&y18�;C5Hv��,h�|�����͏3�)������b3z��O�q4�u��ʳ��X�ڌwF�ރo��S��
���:���t2q�4y����Bz��:YM��{�d�? {˰�d��xc�zվ�	�`QM�M�f߶o񮣢����3S�G��9S�MЛa;ѹ��w��Ki��5?w�Puv�"���l�p�oR����F�C�q����՜�G\��}%�i�R���i8,�����&�1���&*�WY����ʁL��e'1V���a��d��n��v�d�[�?u�U<�+k�W{�$��-�����8cM�Y1���tX8\���J�xXϙ�_��߆�'��Y+��vUwx�h���6b����=<][.�	N:�^ffx����Fv���l/+��Å.�)İW�G���opNV�6�q�#�������%��(iI���;�[���3YYU�5�`��ښ�GNb��*�]�场L��r�?�����9���뭿�u�-o#nh,����]x�	��[\��'�u����������`�dH]#]$�;K�"�$;誾��"_��^�o���` �����x�K9���H�a�q��(%�^�S�2����ɻ/���[�A�H���"�^")Y����Tw�rT��^��m����`��'�r"�,���ZJ�������<�݋}�6̏�7�#��0��)2�J�h`ɗ'Z���f��M A'q{�"l��Y�r�z-�?�YW�����A��Q�i���|��Ig={ؘ���y���4fN��q.�2&/R�{�|�/ \�9Ǩ֗nZ�c:,����b����*YE�a�g�٨�BZ�"�9���N3�?�#�,�����	�6�E����Ӿ�����g�)I�@lu��!�ۛ0�\z{��C���u�V�p8!�Q��a��-�ge��h<7tB$<���7C�yTS�����3v�����7��q�����F�QB!�mw�F��a�ew�w���l"���Ȓu��7��ϙQ2��3��|�Y��~���/�5Ӆj7����'��;��^��d;����	G�V��<=���u���������_'�)�i	�w�9�4�֛6y�ݦ��Q&wE�E6Il���+��H0����P�K��1�����m�8�Ñz@� �#![������N��R���5i�ڭ����>���u�>�N���7Z^��$��1�,l�g(�֧(j�������&/p����M�SL[ 1mϘ�����d���X� |1~?2�cp��{��L�u��o�f��On�+��Z����?%�]� ��4o�]}������Yk�ґ:Ż^]�'tɔ�H��/K$�j�,��:���c�=�k'r2L��L/��ɖ��A9�4�$v�s���Bտ�}ew,����#�=�͌ţ���\i�z�RQu�,ڝ_�Dnf�j��϶�A��X�*V2ҕ����q���s�\�A ����(���%�$�����C^~-:�~���e������c��Q<Sq[!<��ekgۧ�݋�V���=�{�u&���N2�\�EG�lൺ'j<�8/��!�P`=`�x�D�����0v��$�"'v�w`��Þ����JQ�@���۠P�7�j�T
���Xs;�®Nb,zjJ�\��(*B`�i����h
���CO��k��5x�U���.�jI�]�((Z��Cr��ܓ�(�!��7h3�3p*]�DZ�J
�ٴ��,2M�}��ٕ���CB�����V�N3K�+5�8v4�0���G���?����v����������
���B��ݻ0�a�j����Al ��7�u��j�p⭻���1y���qbC�C��������J����c��՜�t�	��w��s�?Ǿ��n��l�F�hV�%��S2a��iWz�$V^�iA���oQNݎ��	(��ns�q�� oS�ŎQ;�q^@݅=P-٭�=��b�x�4�Q��."5�l^�j��]��:ٿ���'�m��p���#�JV��W��KF�çՀ�v\=�]NmF:ݻ�@13+ _M���'=�NTh6@���0�P���R��-��(}Ί�R���6D�H�E�N�� I���Lĺ���0>Բ	؍Y�����W%�G�漜�j45�2�BGbZ����1SkR�1D�NǆR/�c�z��c�g�)�	 ҏe���R�䬟��I+`���eY�׻�H�w6n�6���Af���gD!$�|��6��B�S��o�5y���z�]f��k��cU�&�I�_�tQ�����m�]r�� zՑ���E��'Ms�.Om��hcB�'C$��?LI�[GB$\���K��(C��p��v�Z�;��d���� ڇc�#��:�iW�"�1wN�驜��xt�+���poo��e댴=n'�+�q%o/!�_T���hR����ؽi�P�Ur��[�Z�42� Sr8�M	ĬE�T���I�0�w��/� \ѯ��넗�5�zʳU�Z��eМ�W��Op)?a?q%щ�	����ҹ����]���)[r}�y�w��/���ݓ�VR:1/y�w�$
�����K�芊A����1S2��%Z�sR"�נ�s��؃�>�pX���4��J��X�w��#����Vk�v��Qo��RDvԵ8¥^PWcۯ�k�_(���@�4�H�8Ig0y-�v4�kB�-\�z��ÂI;�uFz�ܴT\ o� �y�-\�d��߁�`Êǖ�`+ ����	~x$��niq�;.��Z{����'�K��>nˣ�+�ηmuS���G�*@�;30U������ ��9q����_�w�앆"�߰�>G��]�S���0*H/��bC��D���*"�����)�D�#�=� �J�8� ���F����k^�8����h��������G�#nB���k�'�$}��C�w�՝���`�*=�>b����'�������5�ݩp�e����œ�Y7�k9 �q��:}�1�����2Q�Q�4�ȍY�ae�%�&�^+���j �a遀[�k�)�1a�jgBr��?��.����n���B=O.2R�A�vu����_;ՒYH��'ާ���ԋ$zA~R�V8�m�  ��� ��T��)��O���&��_Qe�U�g��l�j�eq��Ɇ�&X�z�ɻ3@�/�E��@�8�0, ���������6!�Ӌk��?�ᒙ]oϟi4����!�^.�o���s�;K�P<�1��L�h��WRi4\�*���� (���Y�nYj�Q��z�;`�<�9��m�r�/լ���"��&%�ha�U�	���.�<_�K���d Վ-���MK��"�`+4V!n����oy�q՟s�j,Ա���P/=�H	���a��3�����.{�0jw1���r*�<��#�3UڣӀ7�ۊ����q3cHNM��+;�85�:n���8�̡I6ȵƲ���e�]��l�oBW�m��&1 'l���qf��k������wHM=���k��H(Y�b�\��;"1d��l�uC�i����g��Q��^�l-��tri��r�]�	�mT�gzj#�J��v���Itq��i!���<'�ep�-��^� �%�zѼY�DG��Y���<�����%��T
{ /&�ǰ)f�;ܙŃbYA�L��S��'�ovNo�CN{��Z/6P��5�2�55�I�]��^2e!���p�m�n!9H�;� 0��-�R�p?'d�a]���sz�;�y�1>�-ny �ӂA�6�c(EF�K5�u���nBsm����:�rQƴ�B�����׬���a��^(��Y�gԹ�L�$No�f���m�\R�d�����#3Y��"$����IŢ�vpw�/~�;�p�%"���j��4�4a�+�{��w`�G悻ǻ�T2^e}�LԤ�:5~P�,<������D͙�]�E��'r�q�ɕG�0<�=�º:[�|�dŨ$��wp%�4&��O>�+C2���}�<� �~�@���o�U&�Zo�/̴��⎺^��;ѫ�����k�21�	�"�雼�3�8�O�L-���w�}��{��8�6��*��M���Ei�#ۉx,B%-�@dO�Xd��V�m�XcznLb�[����M덀f�5�;�;dP���&�h�j�E���槌8������#=ȉ7¼ڠ6�#]���Țl��:qx2:Ox#fō��~��HpW�x�~�ڂDP�����Uf����(�AQ�D\�Y@މ�q���'S�d,Jm���h�q����}ڹ"]߄g1=3�ǡ���i�'L7�W��N���BE���_��#�*\�9�3�v�}Ov��$��=�
.,�N���ӕj0��$�œ�J�S���-nN�Dw��!7ݜڷ����$"+ov� ����ѥ8�8x�`W�c!ʄ�߻���5�R�@K �y�~��{��b�'�Q�V���8FQU|��.�B3�C��<�S�yG�LfBn+/�;�R��*��SO�1����Wb}i�m4�Em�
� ���ؑ�D��E��/����=wA�Z���J����G2�����h�+���9�P�?�}+tk��c��<`�>�����Jv�j��G�C�?拦�~a�Z�&-��BJ��[�W�<rZ�hL�NC����B���w��k��달M�O��{�Y�rA�F�X���8��Akn�hk�S��Ǫ��\uK���j�s3Oo�;���B���a�N�_��ye�5Sl{��8�N�ы��|@�WwK��5DU)9Ź��n<̥�r�����\��ŜV��_aV�d�B&4S^�>�*�����a��IW���,K@5T)�\��į�}~����loA��h�Y���8fZP�\F�`���fs�:�C��.�z�z-n#�B�ЄS�N��L+"����XH"5�~�IX�<ʓ\9�|ե_��>���؁D˶���4{����1���o#�'�M8z{\�n�?�dm��=�^�l���CW�^
O�~+�/���SB)���C8'E%㒎m}�&';��SC������J�Q}�ߨ�,���	����w'u/vu�2�G�>�o`���7�r�."8���0�S�j�
�$x7>N�I=�y���eN��T-�W��"UQ:��!��<5�Ͷ�����)ə{��~e���KN�Ɯ����#��rnXCh�h>� �1�Ɣ�����f����W3R�J�L��A& �N�*dF����9���,Bd2�'=_��E��-��N��=9�:����E�.�oϡ�m���2k>h!@󭒮2(��Kk�S,��FKDP0���ꗿZx��8��M��`
�`�2]�E��`141�v����ql���ۼ�&����-Vm�����jR$�2(.u���B�I&�	�6�� �7�́"2Y�����.�z<��e#��g�3*Q3�R{�=�+j�+��&�����M-�Ԏ&4�U*�&ӌ�ېf�0�엔�G�y����OT=DpO�.WHInX%Cv+�Lx���H�6f7��^�d���3��<��[�t���7���.��m��Ƴ�!zHAz���N��Qƴh���K��lpY%�F�a9��)4�W����X6nN{A��`��E�ͨ�Fw����H���31��3q�Y�45wJ���H���,��
 �'�y�$�~����lV˚�(Kt���ѻ�&�G�Nb���W�E�k�)��,X�{֛�:�����B���'�=�9;�@��P�N�BW�H���h�ڪQ�LZ�K~���_��@ꩅ��ׂ����5��B���\ ��O����=���FЦ�6xBϠ."$��`	�U�b �B�%�����Z�yĈNmڳ»9�}���r�N�l��\-���i���5]���t��(���V���>��f��#��)4��]���K��$���.��}�wym�����W��Q�O0�Pv�����%�>��'_ti��Lϯ֠��fͅ:N-�&xY��L���$D�+�yơ�?m��'n�W]3��H�k <��i$�,dS��(@���M��BJ�Ɉ��o:��Ϸ:�k�>;3�l�0�x)3��v#U>̱G7�q�y����{C��0�����C�?�؅���t��O�P��'v�S� KbM64F�>��T��Vg���e��y��q�*>�50^�;�
�~�I*�'������}�xw�F�l�N_��z
g���w�	O��ͰQ�4<�n�5.j[n��S�DU�1�Rt��R"�t�^�5�����b;�:nw� ����M��+LdUn��9VB�H���8���댌=��[&�F�2M�����b�'ì���ఴ�ڧ0laC���!�3����FeY]{�9� �#��dY�r��Hh�7;F������ ����z��ۇ�n�|�ł�"K���0m������p�{�G|���a�/�d�%����b�p�{U� �������$��!iﱋFP�?|2�+���Y�/��@P�|B �>�A��G��q
'8[�?빛��[}�5�V�k%�� ��&ȵ�҃QI�r|����'�\/��l8�p�Э	Ė;P}y�13�x)�\�������Nj�W�t҃I미X����ʧW42Qܲ)�%�,\�m�����W$�r
mRwK����!!�����Wu�.��ҥ�w�"��S<��!Ȁt��^Q�������}���u�@��'`~��H��mF�pS3=H3γ<�t����݈�N��aH��8���䡤���,��<�RxHt��CO�vk(��Hј�2��o�`}a�c�wU����H������|�e�#��k4J{�(:ח�RԨ�*���p~#@,)x���?%=W	��@�͊��r�?LG�����c��k���;%�h��M��tNb��'�*�_-VS��G�/���b>ZJ�V{�a<x�X*��<g�𪬖t/��"4bZ�$�O J��?��2�%L��KĆl�
��~�͝	*�Fsh��\���Lz�Hfsቸ�6;�#f�aS�=t�y��Z_逌1A\-�B���-x�j�<TQF�?=�f���Q�f�]Uǧ`_��SɟQ>y৏IE,���5�<d.	3<
���ZÝ>Y�C�����C���E �A����"�h<��F��~<�꣆�a�y2g����M�V-�����x#�5Qb ,�3�[��=_���aF�������,�|��wf���XBK�����ZW;�YM,����(7Dζm_Cֲ���s�9q݁��=HNm�F�l���E5H�����L��9�_�����Z��J��6�໯����HJ��>9��Lj1A�� ����m�ΓϬ:?�4���#�� �Z2+V�e���d�;�C͜J�ye���4���2S�F�da'�Dk�hM�E>_4$���SCf��E��?_$�=�tV�AMxͧacx�Qj�p#X�ɼL|E�Q�a^��k
G�o�����I���U�\�ng�a��%>�7M;��R}R!��gF���F�@+;XqX���l^�u7��6���ľe�6<�b�������Ȏ ����	��x�W���^ьNr}O�����,�T��_6�_p��d�bd��Xf�<ʁ�5�Vܪ�n����T���X���K��]t;��#v��YOE��%�g�7:�+2�w<�[�}��ޙ�>�Q3\�읎��O�:u��A\5L��B�F��
�_�^g��qx��~��s�*�p����8���"�w���頠km��ѰYj��g�JcС�;�!����T��8����V����+<6�P&u�
��A�1]�b�ba��FI�r����@�Ԡ�Y��� �8���c����u>K,u���@K��5������5X.�ΖPg��2�̩C����9�Y���!ם�[:<�]�O�p��Ԉ)0��`
-� ,�/J��T^�b*e|���@e���uS�)#��+���8NM��(�$�;�Ox�r�&����]�7�\,�����Gdk��D�Uq#�E�z�B�Y��Dh`c.JrǸ��r{,=��W���k_Z�#U�c���S� H��y6�a��\��"��el:nt �?2�W�u-�֗wɎ!f9I��\~���c�W��6���6�S�d��{xzI�Βػ,e�y��I�C���\o��^"��_>�N(��V8T[�.���z����V5GsX>˱��`7�n�V�Y�s�-]��]G+��"�_Geݝ^`	�H��o��B՚�[dUj�j� Ԭ�>3#�t��������_�#;�����Ǡ��z����]��kB׷B�1����PAv�����)ƯK�L�=~�ЁU�C�����%��,'�{��:�ٜ����q�^����&τ�o�����њ N`衂�:�X�a�a.��a���b��&;��y��ŏ��B�������@��IC�J�.���f�F�S�0�QNO�n�)��Ǫ���UX��b����G'[�۳�6K  ��> ��rR:�����;D�̀��i�r�Ϥ��m��j�\�|A$�e�4�O1�a�H�og�=4aT��!D���lb�
��N��ˡ�������<>`����=a�U�iX�\n�����a���x$)BӥU�i97�1/:�އ�#�ϪE�0�x����E�oA-縰p��]b;�񈂅��Ew�,ύ�	�Y#�z�b[.;�}ȷ�N#�UTE�2]x>�
�MəA�����WT1t�@5���<͞�$����N�5]1 �/��v��uP�?�M���(2/�l�sŞ�|�&��I�&�X��������-'��k��z-����$�I�*��*�.�N��=V",���@�,�fcN��Lŏ8������G��[[�q����r��^B�+��@�))��"ce�M���S�Lȁ���=�3�JS��T��4�^M�q�gq!{�{��4���"�6�U �3�%���N���b���y���0V�/Y��a�b����i�>0�?=�n
� #=�� �	�}�0����֖yV�w&��;(���@�,��E!��7�C��*g������Ҙ��$98���U5?R���&~�u�,N�����$�����2��HP�w��ܦ�t�l%(���pHQ�u���T�_���M,����-p�E�R�oDdtX+�	^��o���L9	�	t��S�ڴ��h[��Hc>�;L�=��_l���a�1�k��Q�y��T��;l�$oh=�]y+���3־��u���1W��$/�_�:13���~�O)m��a<�#������q��ك��Չ�/:����Qߍ�!]oF�ub2;P�*��!_�e�C�9��<�lŗQ��+���u
�8f����w�)�U��/��]�J�vs�	��G��G�D�����N�#����l�R���X$ȉ���~��[�޶_�I�J휁���U�rk�W�z�.T����s����I���`��x�:���g!C�ǂ�����G�o ��N8f&��� C��;�	��ܘ`�V`�&"����b�v�7@o1��r� �+o�%S��G�?
�#��i�~���?ץ'���T�v|8O(h�Cr�M)�ة�l_�~�'[����q"!��!�'�Z����ctf�/t�/Ƈ���!�'�P�Ku�I'��/�c����
�Շ?B5��.���;�
M���tުЮ�D�����#R��qV�>'��s�I�����o4��o������;K�4L�4�u�|��2�7��L�����\�1(�"�?͠�+�p��l�'�9}
��-%D70F��k�;��
k+2��"���̋���]�~}�+r��^�7�<��\��3K���Hŕ�j�a��R��Ci���[��G���R�eCl#-�1ɏ��*,m���+�#�[wP,�C�1�CD)��3�6��L!$����s��eI�=o5f��M54n�žYͻ��Jb��0���+W��G!�X��I�ZRM���
>�!V���E�<�M������u���
�OA�ir ����Mg�d�����CU�TG�#.*�)Z��\��by�-7F�S��`Rq{@(�������4;^D����� ������M�j�4*s��$�Uc)*����#�!C��S�����p����rZ���]@���׿
E1���Z�}�
!��'��I�ѩߡ�+�3k���~i��勪I��� ����6`.�.fW��}���8�1��#*m��:hJ=��n�E?�����A�R7�I|'U^?Q	}�!�Z<sL�]���2@�L&��ni:�x+Z[��h����a�t��-��!�Y�6���!�*��pk!�{�6&�T�[�����k**O?���k��3���,�m�����M�SR���w�l���
���I�`���o�귔������,�h�=�(��M8��-,)�@��k�e)\�Qp� `��Y�~�5mx�#�I9i���$;��z�<����o�ҨŌc+�e����Y�c�\�=jD_���Ix��v=��Y�a����@$LO/Kj �,->�����̴[�3z;��H��״7cN���e9��7�a�f��i^i�k�R|7?��6�ҡ�X��D�}�ޅ���1�q�>�z�/�ti��s4٬7a�l�Z������&&��k<uV�2j�����f@��m��+f��yC���Z��9,�{����O��9�e؎��,}k5r�����J4n�TC�4N	S���6�c�P��N��n?�&3�.,�>H�P�������+�4�!����m`��}&����=�KF���X|΁�ݔ�m���B�r�;X{�@��� 7�����6�^v�t�y�-Z�`HM���A�֞'-���r�LF���+� ~Bt�Y�v?|���ؓ���{@�� l���`�E����^(�M�v��ή�����%�ebIH�X��d���@����n�OQWᐮ�RӘ�8��[�ͯ�:(��2M񿄭�'a�[`͐��z�D��}鱗�6��n�t�7���ڴ���zl7s�Z\�V��f��������`	�t�q�3A��wd�Sz_�˫1��;��xg�d,/�=%�X�17p�+�{�5D�Y��u8��=�!���-)�^@�s)m@�	�n#	"\vZ-�LP��Z���9������I����,�⡗���� ��.��C\��MfW���;d+b��z�^��T�"�#�	�����]�2袕AX/�#|���^y���So�6�9��� ��Ă�#MPȣe����6�4mc�Y���G0:e��g߆(�mv���5����F��©�hB�=-�Z�xX�!! ~v�M���4Qʖ"�i�5'���˞t	��f�Ӓ���h0z��s��g���x8pp0�����5��Qy�=-T,��u'f@w���&m�)ɚ
P�i�n�� ��Hr�Y�P�X�rO0?b���C۾�D/��+S%���	A��*�w_��u�u��/D�o�x���s8��!Z��fR�~�{W��y�xb�FqmNXQ�_Mv�S�����wTk;}�p�6�RF�NqM��b��A8�WU<l���y�r�^h��ķ�X�Ɂ�d�ʯŏ^���nY�F�%o)�]��A�zP��i���4��U=O��aj�=��S_ǝ�dy�!DkF=w�Yd��\�4��-V1�����3fN��X�<<5�׎^U�#T�d�-Z��E�0l����F�N�����DT�	�xl.�-����c��������l�n�e���uƿ�������6}�{h��uz��ۇ���Fe!��p+7�� ���H'��m=ݠ�J�~4쑪xb�Q�0�(\�:5��o�I_8���I�����g3��^ ܓC��0�� ��ܭ����ڏ������i-R�]�=���"�Oo����A��skͶH��S�����ɥ��"���>����$��o:��19�7P����cX���{a��)!T���0�]D����m�.RJ,���06�ņ=�r�}bA��? F�𻈔��49�UR��]x4�~?vh;�y�~��Y�7�Y\��y��8�*���)�/���W�hXub1����s�	um{)�����'(2���& �Xf�|9��<�nfǞ�p{].�٤hH�#���)���)�"��5�3�h50��,�se�j,�%��0�*34�(|�@�b�o��+o�ԙ��Q���-<e��y����	�0�<��ͣ���U�`�fM�7�-�o(m�!��7E��=Y-B)i���;m����G�_��? }�T�n�o�Nz�BY-��|�1
F����,�a��%7:�C��~���|;���*D���&L�w�'Ҡq9�3�@�{�!����~5�����ys��m�]�42�.n�������"�C����VuB�F���<5��W���S
��i��Sa�����L�i8����աu��@��T`�h3��=�ΨX�ͽC�V�?��t&k�"WZ.&q��R�Nb�е7pq���ef؃FY�!X/���hҭ�?J����Sz�16��v�j�'Y�i^��I��h'� '��Z��$�a�-��[tR?r���$o-��k�>`R���m�
�������̸{\T�6ع����M�F���)FC)^�v���7nå{��E���,�f��� r8�������Ȟ���$+�p�C����d )���k��X>b��r�Vȑ&�.0^ �W���_�x������!����
��	�RG�� U���<�?δz��HA�]!���CYK½G#hVM����t�n �Y���Us�OJ���*�o���2��e��D���.C㹜�O����F���φ��۪���Q3��MY�-�v�R�Wy:����28�ç<v�� ���v�W��R〮o��r���J�f�(�m���������f�䦱�����g|m���B�u^�����_��:>�uK%c�(>��V���_`-z;������@"���5�|�Vw����}N�O��+�?�΅J���F@����H��t�J녹1Y�MZ�Sh����F���5����H��s�Eѩ�Xl'b����:ѐ��mf���3�[���dT5�TH�;��Ό9L�d �o�r��M��K����-�:c=S�o7/�����=m��z�jgqݪ�+~�pp\x��	o&bJNHb`�,�#x+������Fx���W%L��P�
�2����\T��1���I���ƭ)Nmݬ7�qE�u��<ؿd��S�ߨ�]�=���7~S'� }�6����5�N`Ky�_XDa�HQ�NS���+DTf3&D	���ώGDl�-�;��C�R�zB����`hu��E�d �.U�\.��S�8	,`�Yl�#VƳǚC�����w��R[�H�JbL����F�x������F�Y?QQ6zz���ExN�+h�UB�.��(�E���W��T��O�p�o�x��'���Y��]�q�-S�B`�x޼�W� TBZH|�ns����e�%�>6���Ө?�/Q�V;"<�A����F�f�tEvUY��q�k�E�4�����ռ���>��$QZ$��,=�����Oj�Uk�bU?/,7��&�f�{���]:�*$�S���<s@#~�LI�"vr3�Q=H�˲��|�p7��!N+�:�e�p:L(q�1
��v�NMi	q���?�fy;)b��'�2�̕K�)��،;pnT�0
(X����%3l���u��fQ�`_t��Z�P�O&���1g����^a����o�$������5��E����C�*^e@TUb|��ӈ�u�	�[�$�4Do�Ń1�ݨ(��?��E���Y���~��y��_	���o5욱��:$��I8�ɤĤa���&�E�l'ݼ8����B�Ӕ��l��zt1M�ѾL&JY���A5.Ve��+���rQj��G�i�Q-�J	�X��o�g�#V$a�>*`��@c����}��Ui�R �ڄ�\�,VEg���~b�P���JՒX���/��gM`{�ϱ��8��‌[Ү��TG�s�N�B/�t�v���1���a�����,XT�g�0���V a��Z0lW]�D����z�/����͢**����ɂhW8?�[v�Ρ��fvɔɕڪ4�\�~WߴK6��󜛆Q�\����F�H���?XFl�������<c�%���@�[��il$�c�C��;>��9W%��%`�V;����Fq�!j�X�����&���|��g���f|<?_3�FD l��}�X���h|J:�'��A�G��H�ވ~��-�D�; 1���x���St�"���F�R,��}����:M,c���#ba?S�FEl�8�Í�M���Ӵ��\7%�'�e�	Xu�3���7��
�q���dq<�%���~C
U�S�Λ%d6XQʦc�vs�K�@��A~�G�͒x�>��_�_Z���������6�#�9X>����ȕ�t�9ۄ���l{K���buz?���@s��l�����5Yr-�#g�l�oM*�P���'�h	6��u�Ѹ�<5c}%�4�	�݋�D%|�t�M\�.M��
�V�\B��x�͜�Аʅ�ҡ��}�!�-�NU�����r��km\QWp���*�^M�y��Rj�c�D�dwG{P���4h߽�=��)��7�U�p�zח�A�C��P�iV�y�k�(-Q��V�|5p���2�]#ua�@KB�rtʞ�=�T�`z��~���&��ϰ5��g���YɄ$m��:���y�Z*f)�u�:`o5���V0{Rw� s5|V�L�	���_S�1� ҉�h �t씕>L��^+(k���
r3{
�A�fa�{���K�P�)Z�4}�܎3t߬�]gO͛D�*�4�-  ��̼ȕW1\����/h��e
����µJs|���l9#R��u�j���f����U~.��@�4�'=��R�M1��7��@	۝��y��?o����]���j������2qJ'�l�����2N�s8c��jFg/Y]w�ai;0٭�~1�W�&=�Xn�Q��ۜ�0�Q2۠f��c��6	�?����ܯץ�� oS=��A`��NWvZ�&\x�7�Nx�B�R3��픴P6A�ĺ%��\f��ù���.�F�;Y�l�(��/�`���1��x��#��9��^�� ���/|�+&�́m�����F��3c�������`�[Mĉ��H|9� &�[��S��C~��.�����^�\�E���_U�'򮝙� e��Gfl49���5RׇןP��0�c��H��KuRe����%�_WEwE[�������P�`��q�*2CuF�(7-��0�ynʔ��'�6��E�ɛl�3����J���Ub�}4��q��`��[�����R��S������YSR�W3c�����Sƍ�zI$x?ydogcKkN,X�/5 C��eDMk`��6����x�h��x뽒��3�7��v�i�l�;�J�NA�n+-�T7��rx~�c�8˦%����4CqLPȊ�� ��"i�`O��j����K<
����#u[���$*]*��kU�6����b��K)Ȩ1HZ��8�s*{�Fx��1ͳ�ٺ�̻� iBĞR��'Ua���c����{������ We��u�x��4��7����x�^��^#�a$q����!D.S_b�]�,c��T���q���z�<&yr��	�pW嬩����As˜ߕ,������x�J���u�ڸ0�߅b�^�%}�C����t�)9X�,`_������tr�����<JD/�EBU{��+^�S�����>d0l�%����3<�hgn�����l�7;KE�G�эG�Xn�~6!K#.z����E ��'0�O�d����z�綜����=P*�Ή��X�t�gB`e�^�#��eu9��`�0�޲�R�i��Q,�f��.�V;�C�$�76|���T��$�
� I4m����'�:r�y3\mw���
��w�?6�5Y��B2�0�S��mC�[�o#d1h+漍����& ��ˡ�Y_3�(�30YȣP����©��:��ˡ���^��T(�َ3&������Kq�U�X o�f�띛ͳEr�h�����
�����.�>����	�B�_����.5��L���x� e$��p����ί�V���Z9s�ܟ���P�z��(�F
<&�	kwؘN��kxC7+pR�wv�cj����E��:�b��00�U�&{,dX�8�gV=�q�ʸ��5?h�8��D��!�KXͶۊ��(�^���XQ��
CM��͖��I��1tR°�Y�$��Pљ��CM�[e#����5Ƃ�V	�}3ѱ�Dq%�R��W�|�"IE�����2;S�#1�1�ib=!%YW��έ`���%��_�]l��˨��M���u7�� �tj��g���V��E�`Ŗ���뤼l��tc�-%���^TT��re��&bX��j��c�0_��eg	<�A�p��!�t�؁�w�����ung5��.5�q䛛��"�r�o�c��Jɓ?LQ \�<f�T3�� �+��/R
B���?L�@�����7�%���{?�ܮ�2�ۊ���#3�Od��H��>R훚��+ƿ�q��y�o�ס�V�����:^}Ir�s'�:My@�| ���G��/�b����6�m�j���A��~'�����IYy �Y�*#�M8�vS%��=���i<�}T�Yw� �\9��-T:VD��Ww
�E̋�˰2����K=�2�'�f���������C@����pĻ�x�ϱ�*��v���z�n./Z���k&!#�"�s�> ��d����DP_4޼s�L�'("Yֈ��U��EGU���y7ߒ��[����8K2"��D�i�"�P6<L�.�y�tP	�<��Q�ʰ�wn)������ėV�*Le^&�Ĩ�?#]�w!P���'ҵ���_�������J�ٽ�OEU�~�k�98���I8qzǥ��wC�s�����uQw��Mi<0��񗴊����i Gg�¿�,��s��-���(�)50{�^VG�V�A<�@��q��S���@j��l[Q�����G�~|.$P� ��J�gkֹ�R���x��xt���������L�����{�"�⺪�|�/c����[ck�5�q���6^�u��5/]�h���Ot�E9>�P���m�%ޚ��.M}Mn�2~����Ӽ^t��-������FQ`5����jvs�H�;RN�6+H��@�w1D���kfs	{)�|����;b���׀RO�3���;����k���Orrm��<��Jr�j��������DG����N�뫵ưq�T�'���Hb�$��Jd�i�
j��k��оr.\4�n2/��[�았y��*0�u�V�j+��X;o?�~�1�{�a%�D)$���/5wе����Cr`c��|�bI���O�xX@j���f Cj����8��^�B�͂&̥�ϥS�4��yw�|���n��u�Γ�v�轘��7s(�&�E�Բ���[УU���Y��1`j�s�fޟ�T��GAd���3(��+��ՉPr!q������q}]�����C"؀�I�4�{�
ڶ�,������f5���J6z��4��Rz�␢�Z #�&����vM k�1�7L�r��	/T�$J��%�������Bg×2�*�;�\���k$�H�f�P�t!��p�NQ�mf:�"�c����a�r�U>���ʿ�_�0q
��Ĕ�k\�ʝ�r��yI�q`@�a%��X.������ɞz*�wq@��ia�W����lTQ�R�nw�0��.[l�H�}F?�y�^o닽����	�����b��:�Y$Vd��O�����h�>7�d֧̿-����o��8�8 ��:�4Dq�jL�D@F.X8�^���Ҟ��߰��މK>�o˩���A"�r�U}��T�u^M��,�l�{ӑ��������~G�{�
����#n���u�V��׾��e��&�S-���8���E37��kN���K<ʉԉR�~a��mA���*���nT�7�vG��rx9����V����FS��+������1��r�n��O7R;��A�O�đɕ�E�� &L��ϯ�7*D�(�E�]���Nie�y���7�D�XF�~C\ ���厂%r���g�I�ĭD�_2y2�HOAq�t�uȀ�f�WB�x����c�QJaB
�Y�r�	,�[�����&�9�+A��
�`��1�Ⲗ�I�ҚWD�z�e��M2��r ��k$٘���};�k�~�$��eŚL�\�BK��8TP������S��W��ضB,r���Ye�%u�
<|���X�n�
� z��N�ɭW̭���3�8��Ť$��Z-���_�t~y��S�V�ze�|�d�2���Ub����Ul������T�N���IL��q���鷦O�'���w9}n��"V"�i>������j����Dn;9h͞8s�*�4�\�ӣ�-�]d�1 I�B���`/B�r��(�9�a�-6��ǰ�1�Pⱇ[L5����6�ׂ��2K0ݪk�tf�UXif�IGJ��_����[l�ĂUV/�x�X�Tv{ �릧��Z;peB=����ɛ�eSA`���@m��w�(�ʂ��w]�qzQ�r�oR��M����@�o�ֆ��Wrm������O�8T�i�"�R��}�I7�m%��قQ�ao�lO���a���<	j�*c������ݔze|v�����}B@fk��'j:�$K�<�<b�ؕz��򳄃�����'�Q;�>���@Yk)�tؾG�-�X���>=�Sv�]f��1F�`ѐj
Ep.� �I*���h�h�'�H��h���IǊ
erͯ��>3��x8;�j���� �C2>��P���aIN!����ӤJ������t�C9��j���5��O��v����� ����f�eVz�㸈�^�q�rL�k�t���!!�1�ضG��kD�'�������s$}.�K�j�K��SV�����w*�`�Y���߮�B ��U_�/"lㅢB9����~O��(s���s�������}�CP��C�_K�.�I¶����Zy!.((j�����,*�P_�3S4n}�.F'�h��'�6�r�5��%�V�����d�&U�z*�����b��ܟG��}5R��#/_1d��l���W �z��U��"��r�(�[w��	C�&#�{]�]�"-��/�r�@}�{V��sHsV#<�,dE=��w-�l{�Ȅ�!J��Q8H��Ofj�h`b��3*��`J�71р�sG��h�eD&'�wƉdA�t�D	��E�(4�}���f�[`�G9<X�C!�>����_U��͒u7bm�.o�E�Ȯ���G�����}�;w"`���CO�1P�:����N������AӱG�Z��Ą�A�&�aB�Q�a	���BT�����mF�f,�?u���4�oFy�E&�I�5�,2(�	�����,by����9�Z�;��T1,2~��ѐIgW�V>FlXi-q�$I�º��9|�5�*��K��[��"�OB��2��R�����ظ�CF�iY�5Yk�U���F�3X�ڊ�7%E���"��6+|��G�)YXϲ[�Y"%�Uu��J���t�����ݻD�x(p����N�A�Up���i��*f$\�퉩��;��S�^]��e�:8��*g��e�
'+�v+�`��k�-���)K:Gd��y�pe��x�����)���t��J�	��b�yհ���ڙ��a��#�&��6&��?�A�p}�����@��?k�0:e+��)PL������d=���܎\0��VJN�v��-��u�f�Ƕ�v�aN_�\s���1@���SHI�9���3)G�%<l|�f���9&"�k-��|�p>VN�M�5�?pOg�K�R~�T�ϐ�|�<� *�Ֆ@:��FXc�3݊lv�����A3$��$I�E���M�(�e6AM�b����zw]E���Wzn�p�Y�VG����<�A�Ɉ1�����]r醁'^�a�_�g�h����5��K����eȕ�37�#t�[b�����]�|�C�3��h�}�S(���{�`�:)���Zf!�o�>�p`�q�k���P%���Mt�w�j�$���%��E�*��m[2ў|�f	�mY��b��������uTH�u+�?W|J|�7� Oa�|���-��B�l`fj��^������L� �#�m�ZPŎ`'�;�=r՜�f�j���v�	�Xx౷�	��4:�t��dG����v2)8`T��N�?i����昘S]w۞m�|5a>�E�HO�o�c�ɢ�o�ȅv�����+J�E�z맒��Y ��e�� KO��ũ�mK�����9P3���7��;��!lg�x�YMi�AýK,Ej�<�]��!��Ê{n,)(F|y�r�@~^��?# |�������Ƌ�ʬN�
`Rg�Yi��uhȊ䧍2;?�{�A2-&303��@=��d�z��Sr,��`Se����_|TY� �}��Ym���]�0<�6��F'=�V�G_��&�6g����FSAݥM�e�����@�?ۇ7� �aރ{�5������8M�AI��[+���t���n��7	�
GxU�L�T}w�������!�=i���,��F���@fI�z+ʝ�s�u1q��\P����ELL��2�.�\j�\����nw��~������G��S>.���5�2�s4Q��f+D�ׄ�������.��h��͐�e����UA2��h�w�Ǿ����Ve��$n,�!���3��ָ	 �M��A+�>Qr1��(�\d1e�|��a"��H�v�G�}U�����L{c��s�y7�����I='��vc	% ������ω\{����.� PY�˿pus�9HyUR�A���/X��=�yv�B�kE���1Aߢ� j��q����	��)���(B�r2�=V�\�.�I'�v��-�����_~ktF�b�C..��B{�"j���s4ˆ7���Uci&���/��nL	��Qk��7
���=���i��
��P�Kn�Q�eX��g��C09��gN"{jo#x3/F	hP���=b��(̊��nn'g,��vyT���W�|�y��,�ta�n�+��Va���ܤ���D�ZC�Ǥ����D;��#!�5���2ǩh�[��cL�~�C@�ȂBo��y�Q W4�pb�EG�B����m�u~��	�*g��$vZ��N���gr'z�A�����g�:9�k\����ӟ@'~1�e*����J���Uko\e;9\���ݒ�5	;c�p7�k��p�<��"[�ԓL����8{:�a/�,0�ɑ��U���#�~ :���rg^?��ە3aX ��V ܄�}� BU�Z��|+:��B���U�i��+����r�{HT))0��Zl���8���iV�6����b�D�d	!�d[�ڠ�5��>�N�Wѳ��*㌚uX\>��1���̓Zq@1���;|<�G١���A�L���(�Jf4�����͒����P�$#�f��iASӒ�Vtc�N�;��c5����/��[F�F��fޞLE�wV�,!�ȳ�tUB��MV�Wf�Ǒuw
bpm��tA���c��.��MBB'��U0��Ɛ�w�X~"�ܚ'D��^����oa7��}zQ��;�V�`�)9���>LW�R+2]���B�C�6:�O:9����^�����(���\��6��	�)3�ҥ8R��on��>�U�!21����R{_L=�t���F�5[ڣ�
�xiK�ٕz�<���+E�t����0e��ꯜCB9����[�����u�o�~\�9N�Vo��w� �I�{%���>oΫ3�gX��M3:���E����6�h�� �'�u-<�+F��-1c@I�Y[� ��!|�)Д���R%t,�X�K�B�'��0����O�pC
�(W�/l=�����ھ�P��K�@��lS�k-��KN�����O�Y�pI3���eo��,dps+��l@:��f
l�^jӶI�#��o�Pڛ3�}���#�@�P����1���F��Q�;�%���r�B�*    R<2�� ���UU����g�    YZ