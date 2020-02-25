#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4060017608"
MD5="9971d06e45e853e319a2025d38a7ed09"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20440"
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
	echo Date of packaging: Tue Feb 25 02:12:34 -03 2020
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
�7zXZ  �ִF !   �X���O�] �}��JF���.���_j��`/�<�rS*}�7)�1��7 �^l'�.�*&@��5
��n���Z�@]�*�gC?���gġ��x?j�t�rs�?���ϡ�M��*�Έ�2h�W�|,�ycX��5���l�1��k�zu(��)���yU�œ��˗C��+�şn�s�Q�Ԣ�d�ю��|I�38��]KG�7�\;@z6p�fIy�iF�͙ҹ{�b����(k5���S-o�G�9��5+��^�;�'����I�oF�w+��SG!����O��=���):f&�:R���1nR�r�k���'�>"��t�̺�)ꩿ�H�V���P��vǭ��q�y�Ò }� <S�d�2��3�@��`l�����ݳ8T.�'&mz�����F�}_s�#J��nO�́F��
v�$)/E1�+�uG�r//uui6�z����~L�S�k��ԬL���>�?��z��V�ɮ̡W������6��b���={��m��v��P:����$-4CU0ǜ@ҥ4˓d����wuX����#:��z~���,;{nd�7aR�dкJ�[�͜�$Z���:F^T��(hf:#RY���J�~�#j�<	 �1�W��KY���1��x�����P'%�!��e��T������῝	e��wi�Nub"+M&W�m��������u��5��c�]h��p�QZ},!��7z�-�~�4g$Ø��`���Ő��e�e_���mç]��~{�T:�]D蹙�=���tŎ����DI��ۻ�K¹���f��Ձ%$��F��KUE���4���<,(�L�-W%
�nO@-���0�|�W^�X�o�����3�w4Y�4V�8�#�HH2�jE5�l�7�)�:
���E;�cP�qÇ�y�k)�c��Յ'+F����_y��N4���$Ac���:��ϣ�+�O��(���" 'Cjm��=�����M��=+��$2GXw䌮���ܾ7qP�.���rT^K��n�c��	�;�
�w�<�(�v��|�i�/Q�k���V���{<sm9��X5�R��V�F9\s�ث��W�8	A"K�ӳ.K%���;�U����pZ��;��t��
a��]sOf�l�m��͟�
 �ff��l6���hDP9u/ZeA�O��_���
ܗ��,)�w�#�d�-	�g�kV�e�1T�tD[�|=4>v���e�WV3����':��Ӡ]J̤}\�aֆ4�2��8/��YpD����UH��x��9xX7��9�j��U^(j@ =�á�A���k`'/��|����n w��nx@��@���k�_ ��n��v��@L��z���浥!6��C��5bQ4q��r������b�o{:C2�,�$�"�䫺P:`X�� l�m7��]:΋��[9�<(e��ᯌy02�n�P������c����ɴ��Z�x��k9�Ӫ�iM�3O��5 ���70)b�O�����D�N�S�h�L�&��yHQ�R�{]	��Sp���-��N�����	k6o5@�5E���A�f��$�d��z���j�E���k����D���4V�8����od��Rܰ,����@/aMN��oSk�G�t�������}�8���� wVn����1�4Nl��Ȼ���t�Ǹd�vtVN�:��g��^ȃ���Ľ/fv��Z;w�>.K�|�&���CZF����M(���W��m1$[�����SZk�*9U/��Y��F	��a�$���2�$a��~�!�א#K�a�;1ҹ�8A�A�͹Q�`����,�X�x�i6�[T<��ϛ��x���<曅H<���x�,"����К���$�!M@���?J�V��<��з�c=�q^R{e�)�m!��R��L����CP�1�p{���$U'���L鄕Ϧj"/z��N�0s�3a�ΨQrw��a��A�p��ET�Я� ��2�'w�ʛ����FD����n�[�q���������Q�����>�oŉX��ۯI��<!��ݘ����`�a���#��V�%�畳�eU�*�s�ػIՏ,�o#���&��~'��h����Ck��x�@�~��\��\J�K ���	,ys^� F�ҕ�j��c�E^����H�2��H��5���n��*��ٲ�+ᗕd�w�kIU����Չ �?`�����k̲µq{�cmti�U����7W �C���'�diU���XL#���l���;�7I��`���K��L�0y������S
�<5l���mKPÉUגv�:���r�PUKE��+�;<k���"��M��	6�����$�X��j�4����������n�J����e�-�W����1�ZOUҳ��'��4�s� ��es!l���[�6�2
�?���P�k�K�sE�_Q�����j`e���^���j�/��<�?L<?��+c�x¦�Ȅ U6�i=#	�f�� Z~���*4;��9l��/���G1P�[W'U	P�v������w÷��0�g�[�*�a�ߊ�ZDJ����#�VZ6�X#���M꿷{d����,�H�����A�4�M�d-�49�������O�c"-�J��%D�]��[�)	��u��̖=���9)�~�^�g�Z�shf49�DB�\�{��;�a��v��@�Y���.s�;8ﳙc��%^Cuyܭ\�}[N}c�LL��#+-����6��W�B-�u_��8t���#�+�����G����bs��n�����x VCGq��������?fI����+��y*%�b���F�Ɔ��r������v���	��G�(�������Mv���]nN����H��N���'J�Zq����
�0y��\��U����7���.6i'�H
/����cـ�K��d��rQ�����4w����#*�#�>Kڨ*־j�'b.Zݧ#�ΛC��?L6��g�#I�vcc(4�*!�����->)�v�oYa�"�Z�8v��n�ŋV,�G��>*�j�a���,�������FM�T���z,�����߰T�����4��51(�R=��
����fsx)����t��a��� ��&IѬ��?�4�τŌ���m��O���Y����Ѧt4;�#�g~�4% ���#RzUm:E�f�w7�������no(���������~���Yn��Z�D�V���Wx'�.A�$oF��}>)dγ����"��"��Y�ꌧ������Jb���?�~Ð�s��65D#�>%}^����|DH�f��*M��;�%C�(�NyxN"�1xhU���kO����:�T��+���39��߅�3:�]+���l	U?�l�/uc$�Ʋ]�_T[�= zN���Zt� ����P|d������P���h?��$�y�NP�,�h�7� t�@��xM�����Ls�G���������?��g��?��0���>JdfB�>͕��R��s�����'�ri<K{G�;;0���~��<)7e�I(S�����F� :�h�)��X�Q�H~	.@���[+K�e� �ØrkX���L���Q���ϖ��G �o���Yj)�o���MrH� �XE�9����?��U�,ɿ�s��X�3�!�BG�V������qm�-`�@�rB2��h~8+)��E[/�ǯ�����5ܝ�6,��g���������[ �:�Y�z�~�t����2C7��p|I��AW���w�N�i��qvݾz��&����ޛ�<�mbN'B�(����,�7�̎u�m'?;+��g���eo���Γ����F7����.!�_��}�37
r��������SʰUI��+,��'8��E���j#Гѯމ�`��ر����£��`�زv�n*(0!��_��iTcE������b����B}�'�I�ޮM���	Ϟ8<5 ��d@m����^;\>�Q�$�&��������:M�d�o��o��'�\�I���q�Q��C��Źl�;��b�o[�&T�[8XݦӸ,��%�4EnВv����m݅���ס�Q���ސȺ����F�4��6�	�G�����>%-{���Tۜѱ#��9��?y)1�������n�A�����iipN��I��j]�A"Z���*Ӕ&޼�9��b��n�y�m�[B?n��&�ș$E�}�L��C�8P�{�NJ*W؍��߬�Z_N=�z���!n|)o��*�D���� xB���Soİ���= ��-OlB�-�U_^Z��7����rˣF� U���pBv�
Liٿ���l�r!��98tx,���EJ���I,7��Xr�!�j=(y�����ٕ?d��=����,���_�%f�*l� ��^�`!��u��)��I
�%Z@A=�\Ҹ�{���Y���WD���ڠ宾��_8��|�D_�o����l2��o�o~jAd���d�V9��H����~�]�ZR7z�w���G
]��8���<[��N�N �n�==�Y39�ʮ�n���te�P?����n�9G6��͆Ii�L3��$q���k��޻*5��}�=)��!��QJ��հ?S���#F�bXjt���C���sΫye�.��̡�q���+���~�E֬uL�е�1о���娢ыOo��B�a$�2���E�v+Xk�_*C4s��s���jӏ�.E@���;\��O'_�P(��9�6o�S��,)�-�F1 �C>oi��o��˙e���C���y�K��|�B-X���
XU�]�:'��g�[.��^&h]��K�����rtg����f*n�&l��JmP௜�h�е�!������oi����'��s��ٕs9P�ȶP�#�w']7��������;a���x�3Jw(�1�fc�[��`Zn�%?1I[˙-�}c��$�i*��A��]��S]>U[�,떬��q��{擁�d��9m7�* ��r�l7���cuř��1�puoq:OF�9�4��sKp^6�n��ЧZ<h�5�z���E�aiΙ�L��?��^�d�֍��ng(X2>kN�
ءtZ�I�@ѩ ��iO�����?N����/l�c�	;>�1����(��?���Vx�m�x?XE|�)�Ӆ���Q������������x⟘f1 ���vo��$��ƟH���>�h�:<��	_��f�/w�P�>�Ma-�CUsd�`LJ��|�m��R�`I\�!?x�嚡�b�#��}*@�DQ��һ����?`~�"�VUjJ-I�w4>�Mׂ<���2�K�I�Ml(}��A�G��ɵ����b���^YG�m�u�j7f�Ӑ�J�m�J�K�i�R#+��#b���1�o�h��"�եB���f���nV�k~Y0�[2fo�?��SJ�I!&��P,��l[~*�Zy�'�A|�`��=y�hA �o=G���vFޗ9� UO�!����#�pքq���A !�klC8�|�-v�����rQ��g=cM�
�VI4L�J��gj�ì���0�/�ŕ���2h�e���Y�"�Ew_�BOT.ݫ�*��h�M��hO+/���i7��7�M���B䷼-1��G��Ԟ��P���%)�~G��;���e�(P����BӐV�5m<f�7�0�t�=Ӽf�k���a���s�b�P��e���M�|޷�� �[�}�^���j�p9�/�*�p��r��C��AW��
�u�b��8��u1�Ҭ(:�	%����?V����f(���w	�*ҟ�(����~1���N��"(�r�O�lD�us�,�Ǡ�Z�����/�|T�̓4���o���*��9B�	'���A)v�F,3���BE�+KA��c)9���L�
go���0��;!��:�P@�*e��zN�-������/����k\���*z��[X�=`���s��!�z5׀���A"����h9�����}�:�DU���,~b�>��Bg����#���:�%3i[$���4����&��?m�����5C}�W	�&�^�Yh��y(�	� w�IIxC�O,�h��z�WmT��0��GA���X��Du�/��n���~@~�sn&�e�A�(%���t)_:pL
8cR!!cP��`ǁ��ZUM��W,E����.�]�R(��=��g�/�h�u�Q�_�E���԰��"8�f���q�l�S�V��2!���u�x�U}��_�k�1OP��0����H5��=<۪]F��Π�^2'�z��laU��r��N�x��\�U(��5�CH3�S�3���mz@��8�0���&�(%�F���Z�[�r����W`��h�u�rϊnJn�Rψ�#3�%�{$U�xk}�`J_!����c$��T*A�$d�)����d�g��FJ���I�A��5*UP?��cҥ�[�����#=h������^i��U�?t�[���J4�=�_G�6�V�����&�y$�%ŕ�Q���>�����G>��=6�x�-פ�s�?q6�M�#ij�h|�)$|,ЄEi���t�
.�W��h7-�35��a�n�~�ja��f�����5��}�l���I�u^�XʎfJ9z�u������ƈ��� ��$��$�܀?��RP��:= �Y��u�Bv����"�)��5�5F/JR�U���GG ���!(�#�@�ǆ��� ��3���a��J���T�rA�J�4�}`�)�,ù��j�Gly6��x9aV��d���eyE�Gs�[[ܡ�v��[��ԅHf��2 r;��	- �d}.$�"S!�δ�K�d�Ճ�f�����u5�S�D�>3��@L�n�o� *L+r פ�[�l����4wV���&<]+�ٍH` f�~�� ��8��kf��L��?�܂��fs�PL[ڬ�9�=>F�Hй"��7��/9��GF�AK/�9�5&��{�=���&U��C�z��@�q��e.���(�+���}��&�4������q�d��B�����C`��g�rN����(=�����q�Ar���?��T�\���LV%F�	�n���g��)���[��E��p]Q�r07�����NjQ�X�;�nC�[��Ve� �c$�ĘQ�J��>܅���mL46�8�V��u�������ɯ�:p<�=��x�,�f�Y�ڷ�0F;���ךt�숎�Z�K�w�e?h����2D6�_�ċ!kl������Y�7� B
��b�KV/!I�V9�ԭ������Wa1-�?���B��[���^�_��YQp�>P���Q����Վ�d(ŏ25�e�k�R���=Z׭��^'e4�QK�B]�b�0$8;&��ٞOS���QՊkC����;Z���g�N�'X��N����(ky���v�lӛ��H7wa	]Ca�[H]_'�n�|����*�[����'-|)C�Wv�J����Y�J��F�ZquD��������4m�^iWT�ԇp˹�|GA�õO?�F����9w�=$�+�J {6��Ȏ�hv�W�|<��K�����XH^~�h�:�.�-{k�uS��`~Pu8��Q6��i�[���Zz�WG����1,�\&�O�֢T�>�U��� D
.���'�:3Q<��P|��EE/GS-'�z,<�ؐ�	%uc����	ݢ�x?��%ߩ��?ݵ>�U�����uG�� d@�������Cm#!� ���?"�Hdu�z������LҒ��N���O<4�V=MO�[�3��N|؃a�9���=ҙ���>f�S#�.v��"�3�\d���l,:��8<n�vn���N�&��a�ԩ)!]B��b�����tç*W<+?u�DxB�������^�bw��jd��W�h�5|2��`;�V�S��uOi��k(?8sc�,�	Q���uk;"��ѽQ��'^C'�SxxVw-��I��5�����f�!qX�[U�%WC'�r=P�ٛA��J�6��(m:�"���pd}ϑRN�A�U�?��Zu��}�/�d�����ĳJ����}�ndTx�b�����
��V��T*�<�F Nճ��;��$��.W�@�1��3A1�ĠW#,��6�>IR	Gp_�I0nڴ��3�JB�6��M)Q������d<.����~�[���P<~'x�����3ʃ0V��	pi,(A�a�
�8Ii[;��ޚ�ַc�6/�o���ݿ|�����웕J���or5�o9WӣZة/0�+�7o톮��V�w��Ӎ�3p!��2����0|	���_���N����U�1���]�"�����<�;qʒf��T��z�7��� x�ֽ�ώ�pw�{����-2h^%����� >:W,�&(�-�'!R���&�XO?��n���@���J5��Pm�nJ_�雀�=Wx�W��1��5X�w{�&{�D�t��z�"i��N�`y]3aG�Xw��j"����dSu��g%��GEmd��D#�#�B����>�mw� w�M�)��+��Fq���K�-�v���Xý��`���������_&�"�d�'<ƔJA��Q����W���>S`v���w����q��Ľݐax����^Z�)�R����?�nC���YpRF��.	�����,h��Uc,qk�y�1@J�=�U��k2䔍)�'"s%c{mB[Of�6�� Z(+����L�\��^���A����\�<����ab��*LM �"��R[Xc����aT��\)�wvB0x��W���]��@��i���k���
�2�9���1��{7Ma��h��D��UTHXc��!��b�b��2ۏk��H_s?��t�gJ$�"a�-E9;�����jP_E�e0�@�шˢ�!t�B��F��)�vg�Gq/��ȥ�jm]� ��v#k�.*�o�����U�%�HdqD(�(IG��^�u,`�4T(Z0��'�D��j��~M��z+�]^v^���6<&������Ķc����DB0����c��� ����ɳk��N��u�px�#��2?:�ҳn�N̌@krC�''ү�D9:�Z�n�T��Mc�WKo%X~Wy���E�����6!P_�Dt�Qx�󗹽����rk1�h��Bi�9�zG���{�ܶ�i+Ę��&�%9�Tv"�R�rF6j��>R��\[r�|I9Ovä<��6$:D��6��&U��|���j��?.P��-��K_~�fP\��cZ�?`�P�6����%��upn���7�)�X��f�#�E����r����hD	l�,��4�.�~|� ?z"��U�/�������� ��ls?Bxi�o�aF�m�䵊�au7� ��s�Ĭ�̧b����Q�N����x�P���i�y��F��[A;Q���||���,R�Њ��:�"�1FQ�ѿSi}����$v�#�c0�I�@6ʝ|�9e��s�@S&#���>�5�ybs������h^����R��Aº�d>}0�sDO�Pe�A:� u�O}���=h?]b �\hhq�����^�8�'9�]����݂}0�\15�:���OX��8��z��گN�����n�Dq�̅�7��FϫDbY��(
,�[�k�:[Z\|���e�kR/"[;w�%X=̪�η)�+L��m��<��ŨV�55���9+O���Q��0�H� U΂̦���8�j��'�Y7q��L
B�������9Y��b�\�bo-����xM�Wtmq���.�C�(�i����AT���L$yk�W�D���Ή�T�
%��� �Ѐp�1 ):PYX2#�P;����8$�-�ԯ����!�˪�xD:��%�6���F�����b;7�W"�"�7�䈝�G�@U�����6� >��`�n�jj��5E�roT�9Ѕ
i*�e.�p�����Y���`U�"&U�Ƴť�+������)�������
p�׺�g����j�Z�hz ��]Z����V.wٽ�t����с��;ѱ�:㬽��r�|r���	g���h��9��(X��,
ɮ�I�-���Y*��4�q(.E����Ʀ�b�Ee'y*lՇBl�8� ��.��G��`מ�ՐfO�O\s�:�?hG<며j��0��i�����47�J�V���V�Q#)��,`���@J���X(-����ϵ�V=��(�2˺*�w'�뾠�yЪ� �O�g�
Пc��0����OSj�w&�oL�?6�?����B<�����AS��q�*jm�˕t�+�&�����M�u
��l@�:��R��}K�~�hF	.Q.ļ�����`.\�K����l82�v�(+�w����F#)�H������J���k�!��?|��! 7k���&M���8�谧0���{��{E���l݃����u׃5�$JӞ� Z�26A��|�T�&�����e+�T�T��@���V8�j�hU�̉��S��Mo���k�g���=>�.";{@Z1���z1Q��M��6��H��N�ٗV�I���+�'�tz�O��o���'2e ���)#=�� �/z#V�jj껩�q��.���}x�4�f�V+q��|��4��i2}@ன!�pE]�B�u{K��uv>b�56�˗٭�����-�dW�z
�-�aE9��xc!Z�tր�Y)��<_Oz�>�$ia��$]���P�9���?�"�v���+c�o:��T�@����<�Ĩ�ڲT����_�:o�F����Ÿ+KC�TK�
�wAB��B��	�9<��V�%����%�w�����'�0�`D�/d%1�F�$dj�2y];A��F>'��>+CҨ� t]0�fIx�w�Ys0����Һ�/!4wb%��B��*�*��"��Ь��s��RM*�4zvtd�辊0p�ia�=����ד��m�v&y�F����^�ӕp[���G����ʳ�մ���٫�����_+(�!E^�J�� Q!b,<�mʣX.��r�E¡�&��^.�a�s��R�(r5Գ�*�~*�Lc�� �" d��/�3��B�RYKFM��V������~�<\�KE���`<�,��ٖ$�Iҳ�T��?�i2%A���<�9�UJ>��t$���pEAt��6j^ٓ>��}���B:�Ł��m�F���v��?!Q{ة#�,ZT��]�<��X�����E��f���^�.���ýEXE�0�����O>Uڎf����A?�@�3ܑZ����I��7V2���4�%��SI�H��}�n�K�B�TC-�&����y%��{-V��+>���4��<*�;�D:N��[b����0���i� j?٭�d����99�D;) �|mq�U�:������4��Si���K�t_F�%T#�r�Ι���Gz��5Ey������������{�D�l�PŻ`e���T�.J���e��0d���vP+�UE�ڧX�=�J8��ꫬ\稖�=��Oo����FG�u��u��C��m��֥���@�
E߈4����ww�H���x5�x��������
���[�+��1��Y��1 �cۓ����ֲ� ��C5�Z��/[|�aD]ƨ5��d��Xϸ|��B2B�|���C|�D��k���C���B����o҄=��wj#ӈ��W�?�38n�9!� �c�Jd�=[b��#Zco#�����;M~�II�]��=����ӫ/K(����*�2㋈�ܽذ�'����f	{��9��a��~����8�4�j��Ns�ڬܷ?v�����N���]i��Hf�0 �߸Z������`>��LՋ�s\�3j���������%Ä�]�Wq(�Q譭N��Xu�fR���~�G��L	��]Y���V��T^�~�*�RT3�Ǟ杍Ĭ��3005�Y���ٽ�����u�����TO���SY�j�R�ľ��8_{�:�(��q%|���2��H����f��t��iJ�ҽd(�� 0<P��y��m6|À����%��V�
Ͼ��fߓo�� ~� abc�h���>P}��>���䀚yʇ"�.���p䞣<PZ�M�k�^�)z� ����:Y/�Ag���\��4�Q��\j��խ�W%y�_�;#�\���s�0S���6wQ��	�Y��0����t�#Ǘ��D�[q7>I�w�![�)[N��:z5��F^�(3�m��e��2vZ��ѣ�c-x�E��>�tD�z�`�L:O��cQ'G�����Nvu��I��iQ2���d�8	�+O���I&0ð� Y�X�ˠ�U�v!{1���C!1��(v�a�M}������=�a��F�RDdAf�z�i(O8	��Ff��#Ǳ�Sx)��S�?p*C�v�����L@d�#G1����n��QE��d�2J������|r��'a�n�*+3,=Q�E���o��R�wY�4���Vkg���:��� u�"��ۙ׋r��\
D�	�����_���#�/q�>�>����xj@)�����y~�u�B@6bC��:�o�"����UkDJl�����
��NZ6w���c������4�O�h��W|�̿�e� �Ե�'%}���鑆@E��D��ԡ+$�؀��K�=,.����ᕂ���?u�Ѷ���6�S*��P�u�z�M�V�Y�]�=v,��<� �NƵyH�b��i���g����{e\DNY~�#)iG�6�4$6U�b���_�������E^�������5$j7 	>_(�tp�Xs<r��C�P�]����T��~��(I��!����V��3��D��NK��`��d��Iz$��àj�G�� �n�gz�*J<���7�'�ZC���h	Fg��: " �/��J�������Pݯ�	̹��R9��و�E|sǣ��y�<������M`�%g�q��&{>��2R�@��.��~f�_������?����5?.?�-*~T���������"V�)հp`u�K��J�o��>���:��'1<@;� o��cݜ՝��;x�����S���,?�n�g�onk �	��t]�l/����$>� �{@���c�fy�����
k�Zd,=]R;�ozV�s��3'���
��n1��5j��lxI���/Z̈́��9 �+[%/�a�=��af���<��K��u�W��T�t+��ؑ���L��� `���x��������Q��G��)è�ewoY��Y���۪6i�Wa�W�f���0�xl3��O����z.�o���hsq/�a|����`�*�%��2���	�hOQ�'=G�v�����tX��r��.g�����-,S5Z"��������H�!���!�ezCĻf�"�����R�N)�:A�>
�m���A7�1��)ݰ0CΑ֡�^�\\�Ѳ�)�̭�!6#%O�u��Ǩ�d= �u��+�K�� Bo PC��&&�7l`�!f���|3��Y�ͶG'��XDʠK�*�p �cOs�ϗ|g1��Z_�5�����4#a��y�Ol�1��89[��<�s1(׵�M�)I�kf�M%h��LDe_!	S]"N�afyk�S��2�E�2��Q��������H�0���b�5=D�[�p�y	z�)f�	��S�iW� <)���Y���*^(s�4DBx�Ʈ;Z� g��x��	�fZC�ϳ����F�}:Y����iU���M��Ƚ	w?��Vh��u#�N�l�)F�jV ��b���Qի(nHDo,�=�C�_�-&K��j�ux�5�F��\���s��ᬌ�f��*(�~n~Q�[Y�2.���Ӹws�c�Vq����`ܜ��i9Q��dB�qK*�_\~�9�;gA)��@F��r�)!��迆D�����Y\�_zk� .JTW�P�X�l��8i�n����w):�˔cq��=�v+��w�V��s��
`���2�I��-��s ��l�6-A5^��Z+�80��-�`�������;Q+:O�{r���づq�ii�V%���7B���*^����AйRà�^�ţ��Te���7���$'��v!l��1f�K竍�y�������q�f��ߢ0|(D�T�U���M����ϸY8�5C���l�GM}c3{��X]���8��D�%F|�`�R���ݢ9���+G�Eup������H#�b���P��r�)iW1]�ߜJТP~ɚ��ꨓ���tel�����56'!'Э�M��E�̑�R������#]�@�����=�xe����k��K��8�xW�ymw')�����d:��Kh���HT���Ѯz	1
�r��sL�#�����"�65�b��ht����QD����u�@��ir,�K_� ,G���{O!G,j]���+�ԍ��4@�犀�8=�����b����6��n��-�-*���w���~����^�G='�`/�QA#���T	�J۳I�j��E���4$�GZ�Vd;$��ܦ��� �6�j�n��g7����V�c��Wꨙ��-����sP�h>�S��E{����X�WR��֡{j�A���oI�S�L�����&*<9�s�:�?��׍�n*ֹ��6??������٣4:��7?�"�����X�����5�]͙'Փg���9�X�oy�IH��Z��n;z�c犧Y#H!�物�����ҭ>9"Z�m��������`�5:L
�C9�ӈ0��Z���8-O�����M�x͟�0�
�e�(�?�-��la�kٸ�e�%�%����I`�`��c��\yPn_HcO�r���ƌ��F�E*�<��|�3	�=�~��	]E�R*����j'���s���ݾΚ{-u��|�������"�v�I:`��ȢËS/�of�㗫��H��0�'��v����adg@���14H,�Z199���d��	�Do�%�� i��}���;(�!!��!� ]�|j�̙�
�^0{��HD�������MCs��&m��qV�`�����CNTeWY��	Ր�>3=�!f�U"�iT�ܯ-�SC`�X8x.h�B%~�uN��&}�V@�{+!�pIE��Ҝi�'J�O��3
H���%�)�W�J��L����܁(G��!�H��_�H�+Zf�����+�����q���̻1�S���U@ �A�Wۆ=�f�F��.�P�p���f_��ٸ����vh�(��Iю�|��Iv�Lx8R&��f9r�-�B7,����t��Su?����9�^!���</��6����2�9��}XY�O�C{�����R-؎K��p�Rz0�M�A����F��a��C/�X��/�C��t[l�+��o_��)Z?��paw�}$��N�q�C�Z	z޹Z;�!�C�x��I��73*���=�71v�Ck�0�1��_�!&|V3`�K�>�,+K���' �k볫��~�/��
E��)�c}��5�"X�J����.��d�I����s��𫩬>�/ƀ�c8Q�I�k�y�d�>#e��q++E��$b�Ky��Z��P*/f��i��D9�uI��!y�C�x��y�4�w�cڒ��w]h�����I�T�9�|>F�.xg���P��U1����A����������.��T�d*��ž�<�(K�򨹥�}Xam�� ���OE��)�N$<ӹ�S�wr�K��θ���-d4B�..!�8yGo�Q�ol>R��]����kRovH��9檶�C�rۆ�J��7vZ�ڕ�x�۰����u�����  4�O��d�b��[W3�p��	�ݎ
ׁ�@�T�}�c��-�)Wd��:�t�����	'"_q!�	qwc���tv�u��zm��)]���=k��>E�J9 N���o����O�S����J�yL���ͽA���6Ђ���<ex�F���_:��+.�(��v�'�+��~fu�(��rF�k�rѬ
�pl*��R�����]��7��ky�@���CO�|�vq���}���e�������jh4I��%�Lϳ�:�J�b\pb�L!*��ɡ�Ѡ�7\L��,Y�͞�{Dwx�{�A��c���~����ݒ=U�e#�=!��)#I`K>�U����������ȳ��.�OG�M�I�� �)�C�� �V�Ȟ���]�A ��e��]�:��!u�_
��s���LI�bKteYƑ�b�[2:沍�E���]x>F�@�Uhbtz��%��+�|aN*ZE����(���y�F$��7A��m~0�Z 1�i)��������{�}�P�/�-^�����:��`|W�ϐ\�'��8Y��'i7����f�����a�aI�fy�� �)�a�������Hj�wRq��u3I �(�UL�.�qC��	5C1N2�L�l��~�W�p�c�F��0��-L O�OT���{\=#3�g@��xl �Ѧ���Kz_��GS�4��~�8��o$�'����Ƒ�6U��M�+|�m��I�=�e�
���[P��J2�O`�S��M�$ƫ4�O� ��U�|qu�\�@s�nY&͚\��ÀQ�s�d�3�aWԚ�"T�驟 ����}�����'#��K]`
��3��ߐ�T���ț��%ܤ$�Ґ3t*�sWuWtݞ m@M?ӵMӧ���6�8O��Ϙ��D��;48������6�41�":�^��+Xy=)���`#���%��CA��[�X�C*�X��-i�1����]�ծ�4g�Rm��Q��GՋ)%�ͯR�9���0�8�S�[V�-����#��Po낻t3��g��g>�N�jyOG��Z�:~H���'GlgL�vD�ŗj�����x�l�H���"j�3�Ęʸ��&��D}����fi�I���c:��T|����OE^xd��MDƵ�v��l�������E�O�蘭�3�4eŔ�S���qQ�y9���Oly�ɜ��/�cԅ*o7��K
�x����]�^]*�'F��]�)Y� E��s���/����8	�*��7;�Ȕ�!�����g'_I���=�*���&��h>Ey8��HD҄�TѤMX�����8�ϽG����] b���v��ٻ3�,tM��s=a��cg���4�b����*`��1--�H.��K�6�9$��\'����/) {��m؊�H(t[���h��y�� � ��Rv�⢸��d��"�v�5OG������`�~��k-{r#�t| Cmƾ �cOࠎ��т���Hˣ�*�0Pe��X��^V!��7��^���rD0# ��Դ\�@䦘�1��4�vZ�| �$=��r�Wю�u�/�3�S��YU�O9�i����>$�-d�DI���}{�V�&={�/?�:b'g9��j�$̀Q�7���T���p���~���0何�$h>�Z<Fܯ�T�ZA�������^�sl�Q,�t{݅�������9���wt�����HU�Ӗ��S���%(;9��\�Haa ݻ�g-��v����Z�8�L��s��g*��&�Y} Hr&����&Q��ea�lO�>Ʊ�b��C�a�	��	5bu�n1�Mw�1��wbg~6�
�?W&�_6�q�~��+Z�ݘġ�<���!Jt��w���/��ͧ��#�wӗ�WU��eFD@�+w2�2�d�[�^�ɭ7���fY3���y091�Ig��&�<jEĿ�3�� ��x�oël 2�M"��#�c1�v���X9y!ycRu��ʩ�O��Ak���}���z�􅇥�Â.R'��d�O�z�ҵ~�@�%��M��˸}�D�N��G�52)���9e�ĿB��0����B�Q ���.88]B8Z��J�B��m�s+��8�.��lܲ����@��)/�1|�Hߪn�B/`��ku���D:&��HA@/3��i&mZ�M��ؚfK<��OG=��`R��[mT�|'w���+B	�X����N��$@� L�^�b��J�ƈ�2���،��JU�GnT������O��Av�
�07�=��*���O��<� ��w�1��Q7�>� �c��P���� ���DM������8��d�μ([����D���ǉ!�i����AW �w�˽��P��"F(1�x;�{��O��N-�c��S&� �y�5 ��]^V��Lk�S9���~��q{}C/R��S A#�m�W���H�9�����´���Pxg�[� Sv��3�Ƥ�����4nA:o����b�c,̖_��
�b��0����exY[*4ӛ�!��&t�CYU[d�hcU�H)ŏȹ�{I��8��U�I5�#MZa"���ަ�VO:C`Ls���S  �a��<s�<�D�T��X�YΟ����s&7~�9�x�7��|�7��H�+�7;��v�I� ��x�-�(i��3��Hgb�C�PQ��W1�kO� ��Y�ǵ9*��TpE�OJ�Z]�����HG�n+�	-�Ϧ�EG1�>�\w���.�o�E�_���;�>�L�\z�7������˦�h�F`�~��.v��2C7�g�s�þ���6��{��T���'��-4�a �X-��o_f#�ȥ4�~Yxa��.�����m[�a�Ï�������"������*�1ʮ1�/z�z��zm���ݪ�Hd xͫ�&�R)m�V�f<H��C�/�s������Kи'S	�����A)���M~I�sbl�N��Do{s���{~���9�;E��rXi gY/%3)����<�q���%�0I�e�8w�/ڗS�����)a�8?5�jFע]�b���w%eKWbk�v�&�G�:�)J���/�����SuIV�\�G����[9���!&؀��em�)�<�0��`���D��@ٿ_T2���pOW2>	Y�M�2�V�)Р1��/V���5
Q�i�&[ݦ$(M��32m�jw���dZ~wG��h�e�T7ԕt�R6���\��ZF���>p#�?`�S萻!��$mZ�E>�l?���-�b�*�g@�um�*��k����]%cǥWjs:�.�à��c��O$:,���/���S�<�L����y�̧r>)xw΄%E�{+�[�f~x�- �Jm�����9)ɞ���v���1��1=��
	㪏VQ#p8��GŚ`�1۾���#�Uc|�6%��cJ���т�j㴥9CN0u�0�eXu���iz���!b��ɐ�t+4S�zP�����j�>a'�)����TF|*�Ŕ�-�O���!m�c�?�[�o�-BA��z�����7#�%X��� �[�e״�J��R�AC��8�Hg�H-���"0�����=h���JIq!#K�ȶ&}uz�J��D��o�z��^�I�ܟ}��?f9�&Q	�JHo9�н���*����˰50�J��o����u
1����yt�⽵	��3���~\M.��	b���LL��G��v���l��'4�0�t�?[p��ӓ��D= /š�����5`��b��]���'��T/�j��!կ�)`S��sm>7��=.�4�7@�	b|\_�!C#N��Y�B��������Ilr��zX�j�B:�HN`m��}A�YN��#�kj�Y�tR�]�y�V���X�r�T�:�1���P�����!�Ʃr�˘�ӷvޤ?f��w������8�v��*S��H���#OrGH8Y����7N�6�Iĉ�����ү��%̓e��P\
r�a-�s�P�$�r:���W9��Q���cD9J�hܙ�ߤ�r!����麭l\�R*k;}�S��,�����@�gv���;]?�3��b23ɩ]fK�~�����aAu��+1���	��J���L��c�u�"Y�T�b�"p�Ա�e�:�-.3wEWSl���J�)�3o%@����}�i;?(#��}��
DS�` �0�F t�����f�	AՉhg����MyVY��˅���Nd���U�N{�23�tW�a����  ��R�ƀ: �����`���g�    YZ