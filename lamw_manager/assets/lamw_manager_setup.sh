#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="542801537"
MD5="afdc1ab15e26992a62a4a0e66a8b26f0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23576"
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
	echo Date of packaging: Thu Sep 30 22:17:09 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�|�B�"RF��M"<�6c��|���13��lW��7Xx�va|�7��O�Iz@凋+N��,��1���f�yj-�R��>;�q�fgì[�:.)>$m�U@@A�ЯI�/$p�a	G�qz��ER�a�|\1S8��{�h�3gkה"W���%��;�b' ��|�M��c��ǅ@�H��������h��c� �~=YAKԎ!Q�D�I����"O͒q�8.ģ�"�Nۦ3��$`�p���PU}�{�/�[}%��S�g��UT��2�OCa#�q!.�n���r{���gv�@j�4����r��`�B����Z �Lz_{�@��`�.O5�ȱ/�I4�T��w�>��c^ 8�Zñ���r���Fh+,�~�?��#x=-��̶�܀���m��(0�)c����p�Eq�K��8h���Lf����=T���R#����E�3��\�H5�(� �@�F���%�����I�i �����Q�΁H|UN���)����.}��o�ľd���De��Y���vJ�A���o������Y؞Z�5��oѡ޵ȡ������bKw{����$,	,��[�q܈8���{@�������D�� � �X���VKq=�ײgZ\��!��d��~���{�6t��q��365i������_�*m˃7a�j�~�P��a`��㟒����4=�����0E��wp����_�P�z���B C����U$
�ä9�(��1��| ������'ܐ�oH��}�*�d}SL�,��3>џ��@��L�$�*v�$w7�K�W���m��
�F�Y�=yֽhr��c?A��fxPW�e���!��$f��,�.�4^:�`�K����C�3̺�G�yx��HS�+D�#ߨ�a	��8�0X��Z�~>��y�t��i��FJ��d$*�%oH���K�����=����1��ms��ZMsq����O� ~��eA�P�Ҁ�����R�e���r�pn(裺u}��;����[���`jh���M���Fk_�N��Ƶ����U���-2e�և�HOqу�D칗B��ZAoe>ێC޸k\�a�2k�E���ˈ@�BZ>�P�Ơ83,�%e�9}��x����)�ǣ�nY�t�����yhN�c���݃w���x�u���Bu�q���:L|�����x�fJ�E��˦�Ѕ79u4t[��1�)g���S�'F|]��R�V#؛��oD{�y��ƫRpG���K|���Eܔ��=��$��ܗM��ɩ��"��dM)�\^a��ç���+T냻��}f}�S�����C��6���q:M��: $2W["j+a^�\B��I��GF��=��4]�0����v3'��ZT|���՟���2R�%�0cp��Q1B���lݘ��S���I��[��n$���j����)|C[��)�������=�ǌ262�M��Iǝ���$Q�,��:�'%e�����d�R�5��q��
R0z{�U2@�sRO�@N������A�އg�Bk��%��I~Zs.�s#���� ����; ω��Z�q�7 �a`ш����g-�NrZ����ݚ�o��HhlhhQ���J�$��F�f-�N��LN��ҿ��׍����HkM��Lm'�Q��pd�4�i[�_�C���U�RvYG.�j>S�a�p��t���������D���$�z�
/�u^ж���e&�W��HA���wր9켠k�S�buV[f��@�w�ߥ2���,~]9J;��N���c��#Ha�4XY�����:m�?m�|��~�"B-J�kuu�,�c¼�S�/s>:#>�eBx5D�Vt����\U3"I��S	�UL螩���4��mK��d�xS����dI�dN��N4��~��vo��O̸��'o��	��R �[�;$��e �KGs�v���2�8�#P�3Ra�#�`f@�Bj�s������]9�!H�q����u��:����(5G
�����*@ͨ�2a���ʧ�Nl��Z�y�@�aiʨ�,"@����f�/5�e2�Z��{�E`��)��a�?�AK�|>��}8��ו�!��b>�j�d��K�% {���,_.���e�Ͱ�W9})n}�hɲ�P|Uɲ�>���h�:R�ի�d�O��.�x��g��~<孲����-��3�t�*ퟢ�_?>4k���9�*��W�R��ү�\ov*�6z��8�pq\~�S�3ܶ��srH�W�׭��:S.�k����M2�.���6� X*��T�'U{��w�a�Ѭ�
��_r�_�8���ܒ��<C�!=���f6s	dt��'�L c���_�,WDW���zC�4�@5���<}L�8/U�A��i*�#睙{s�$d�7��r���u���.B^N�t��+�(���n�S�[L��	���M�L�~�M;ؗ( �����Ռ�nnt^�$���U����y�`�֜�B�6ω��Kڐ���/V/��4s�:�)e���K�l��f�nc1bJ��ܚG$$U�9��χ�`$�S��]��u9.a˫�֥�l�B\>o���&��eљ�/�����Ox��](h��2h���O��i�xGJ��;x0����ţ�6t��-}F�*$]U�Ji7���c�I��]n�WG�QHh�p ���K���h����Ԋ?;�dd�e���M��5��he����<��?�5�Ө��'�ζ�?�c��I6@Jy2��j�G��N���$�.�uy�KOCPz3��`�K�#~p8��m�_�v.b�r��&BR�M>���m)C
1�����K��Ĉ�ƥ)�I�54s�v&,��8��~���Q��K����Z��eƚD����E�������?Ϸ��x��=&��D� A���YW�˺z��_W�K�w�[�ڜ7F��]��,�!�j̳D�~�� ��f��� �W��%�4P2Ѷ��Jl`:�$ɠ����e�Vy��P=��L��Fz�?�m���:�\��N<��W%N{�K����H�����w
3a蒅�-	P�e�d��!'�Ri+����V��y�Ŝ �cYq26�6�=*SͿ����C�0F�~�(��:��)����J�w���#�M!Esl��r/�~Ni��$$1H���p �F���0��9���E�E��F4T����@�!��c��,���}i�j[i����`?@)h\�y��ky^�k��,˴M��l�L�����5q'ZW�I:N�K�������~���O; E���_Sc�Eh鼗Pׅ��\R��+/��-�zW:~%x�B�3joƦ�����z6�b
L��U������&p�2
��Rޙ̦~u��5o� ��x��-�f�Mx����$�JL�Ќ��K�p
�ߑ��1#W?�\�~P��~=^�
p�ʃb݀F�ݻxI�,"�D����m�R��^�*���YI%��dv�ʿ��v��D�|τ��@���N��9�X�e{��:��B���54�y>��8������X=�}[zV�10�e
�a��9�ڍi޼��30�\�(�H�y��S\�H\S
X����_�h�nqc{�<6��	{5S�N��4,}i�/�l��G��ߡg�Z�#���:5��`��#��!�� >���@XDه'���v�u\fn��j��ɹ�TU0��x���h�C�"��u��D���"U҈�kݬ�F�3@������餖4K����_	��[�n|>݀?���*��B��c�|P$%N�W��p��qNK8��=�A����=O�&�^��;u�V��td%����Wм �Q�ʚ8�����ڦd%��{�-p�:����Ev��?,���h!�`��I�ON�TfB�U �Kcqǲo&[���0��W;^]������B/�Y�)�,R��=AN�6�$J\�q���F�fjn'�d� Z�*�ʗE4�8+<4iY����d��4��+$�c��7|:�W�;_��,=� �ʮp`������z��/�?���V%9��%t�MP9�.��ւ͏�w�ke���ON���~���E��'�a���G�����)�Ǖ¾(��]�NUuXP�G	�s�*q�=�G`���>��tL�m%�g�d�U��
��EF�]����wQ2�]�*Ϙt#ݵ�/�+�:�kArݢ�z���xNg�v\o��b�5">�7����z�w������'��ג���Zܺ[����+��Y���Ū���Rs�s�@n�N2k�s�ϱ�2m�����$�l�@�r_(�������u����e�㡺Z�j�� �W��� �nhP��<R��R#��rc.�:k�0V
��c)�v:���t�1���W���3%a؛�_�������>Z��Ǿ�3/��L�\�>����O�Q��*n����%Y�%��|R�n���0����<}���8��?�����N��ɫ\����B�	�՞	�6�G9���ݍl������]��(�k�%��p�g�Ed���/N�:��o�,/Z��	�dol��գ+�DX!�	��ҳl���T��o�`��g�C��e���A�&����gC(�h-����s)�c���h����\��p-��.�=�7���	k��H[le��>�ܬz����&����kV���6�K��ؗ�<;�Ϫ"��I
��f���$��&�"�i})OF�a��+�1v(@�|śӋa����r��WO6A����JA���h�/l�0ْ��/}����ŌS��0��m�u[yt(�!�5�l���o��Oi�Cن�C'�
����$v�+2�U9o+�a��g��p��`u���'�,(����#�7�k�S+���6ynNH������Mc�
�9ѹ���3���� K��| �~hC���8]��}��o������p����¨����9C�=���R�3n+s5H?hά���4��j������U�7ЃaT|��ݜ�g:F��H��e��:h[�t�|;� ۆy���t��v�3�C�����'C��q}M�QU��5j���Hk	)miS��x����[�+�FXi�m.�kH���h�R<�*�6�e|��K
Î"��ln�	��v�Ǧ�8��$ŧ6�� �ib��υ1�f�[|r���4߄�� ��-F�phv�5�H�e���pưKM�5Sz�Ԭbuq&t�SQS�׈�~Pv�Z*".v^iR�s�ew�o�BP:���P.S��F�x��<���3݉Ll�xU��M�̓�½&l.Z7�&�Or5Z�2S����t\
q��V�U�����?��^���
v5VaKV�&3�w��H����M��qE�������d�'P6;�
hx#��GM�<_I��|� ��e��)��s�_���
�j$��ԁ�IFW�������^���/c;�$�.z~4غa���H�uD�Ue���� ���؜��dW�\f8G������i5_$�-���V�KC����}���ƿ���)����M�&�@
g��u������Xa�L��*ޙ�8�V�v<"��VU�ü3�$��<�y0���Scy�C����ֺ �L���8��Q9� n$�p� ��Czc�>�p�ȈTPj&�Ϸ���_{]��O�Q��]���M��`a�۳��f��Q��7�$�n(˰�$b�ݩ���1��+	�k<�2)w�YT��I����}Z#uI�kL;	�02l���e��O�nQ;��_ܾ;��e>LzW�5�C���coQ�*ad)����u�}����
z4�����&��E�)g�-����ý?t4�9�Fèن���u%�YMXd+(�J��^"�jR���/<����"� t���:9Q�u��ǡQq[d��ey�ð'֞�@
1d8b���Ta72s	Z�w8�QZ0��=�j ��J��N9���O*�$��왫�
/=Ǭ;d�����9'������#ټ�@�����7~d����,xA�t[�����Q�A�+�j�o�wU�~��O�#�����x�0�qC{�E��Z~"2��S�p��8�ſ� :�OO�b:No�k�:?o*@4��>���	�hыgB�(�Wf���K*��#�x(O6�nje��\�wV�N~�\��Ku�,��ovMFS�'뵵ނ�=��i��;8�j`Ҋ*��5��z�hayn��½���|��trI%s�`k���8՟^�=�$$�YP��_ly�|�`���~Ϩ,o���ɷ��w��nA� ��ذ����)�z�y��5_{}�N�*أ#YF+�h���K|�@��GO�ڏV�Ą�YE�I`�c�����9̃����#�i) ����q����HJ����ܭ��`��oz\�V������ٽ+TQ�i}���k�i}�w3�g�/Վ-)t�2D?��~�ԑZ��c;�C����m��C��k�.� ʊ��U�-ș�q6�}�f֭ʻ�A��}�;=��_7Ij���,h��X���9sW�����kRV�b�՟3E����h��"��غ'}���"8��k�
	�羛�}����P����^��'��3|`+e������-��=M��Z�)�b��q����U�T+y���\��� �����bR����YU��`t�4�N���k���4K�Y�qԹ���߇Q6�]|�o ��p�h�	��hPz�������CFJ�DڢLQ�I�Ǐ*'{=Kݏ��J�g#�*z�$�v�$��q�ȍ�8����W�!%&��3n�wE0��j��{���}�Z(��#��6�a��m�T�������H�5W�����ovV���!}%t���2�:��}�y���M�2��v��|S�5Kf|�̬���	2�Z�h�5��5
l���'�R=���x�����~����4��YX�T\��Z�q#�Ot�����Ю�����	:�Xh|T,q��켂�٭�<,��:�1</��N��9f�h1�Q�q���L�������3Ş�m���3W��X��>?�(�H�D�(�#W�_��Xd'%������x�Y��S�j��0���յ�pƷY���=f�4[O��v����@,k�����]N��ՈD��62=�O�. ��}�ճ%�c�g-s��R����NB��zʟN�K(Y
����x~,
l߻�-F�/fV;u����:������	f ��HLc�������&~�BL`� 'a���7�Y)3AjCV�<3J	�������AI�7���z�s�5A�+�(5pEjC{��{ג��]�wT�r���S���v��4��B|6:���1�� }�>�СR((��-x7�qN֬Y�"D���W�В� �>�Is��ފ�fFwJw�z�0�R[է 4т�r<ݘ�<Z�YQK�^cx����r��6W=*����Gb��,��ܜD`%��튏��$18�wZ'b�q���L^��"���s��d	b��v��1��:�[j7x�R���~�5����Z��Vo�A��8�e�
X�b|aOƻ_���9� �#޾�+�s_��ETe8U�l� (86Q;��<�=2 ���U�F��*ά��!�����}E|��[������p.�qO����V��w���6����uE�ѥj��w�~��հ`vߋ@P�/?M�Q�n�;w�/�2�v��l�at	�t�S�dpQ�kx�Z`�2�6��$ � R��R~���r�p�8�~V�;�ʪh% ���:����l)q�5�^I��׏��D�M�#���1[���Y���]��%-ȥC���W���G�L�#h>�O��lno�BP���<� �͜Ȥ�V�3�o�	RZ� r���$��Y6�:"x5��O��p�?�V��R���5e�V�ը�r���X�UA]�
�tb�]=��/ʇ���P�
ZY��$�@�ֲ)�����)mX�&#��rl��_K�Pu�,Z��ơ�zs6� 5�3�����惦8^�"�O�B{Q �	^5|t��+#��I� ~`ҥN���uJ�	3\�	'����:A��D�bR�$:����r��u4ӿ�</&���F�����<��>ۂ�*T)�LLE�����D�&Gޕ^G@x�17&���L(��I3v���4xsy?#͆��0�W�,�1�VC��;v�|�Mz���Lku��з�`���1����	% \j�*s�+�oY���z8pO~5��A]��QZ4��n�Y;:�S��4t[�Z&��dDܒ�"��Hʰ��}Ub���	�[��e�fw����]=S׳��1A}<�<⸖J1`�f�Sά2�5<�-z�Z�)����x��{�.��ۈ.C���X6yܔ���Փ%�� �0���U\�x+p�i����qҌU����dXuI����_>%�Ӣ��'����-��SnQ��5h���Y|zu�VL$�ߙ}E�v�����&�d_�we��@2Kݘ�I^����\��Z!�7MQ5b&;�(��_x0]6����8��^�bVAʘ��@�������q���A<�xq$�]��r�}���ZrZ(����+��O�$EQ�(���'����V>G��Í�K:K�v�����A6/
?��vݡ���1�q�ژ�y��xq�?[���_��V������� Q�(f�1�w�]_�b��נ�v�/��`��V�V�h�}t1oH�=N�jF���`ݸ���Ro����S�/:��{y�~�0
��t��뀩8ld��^�j�R����qe���.���}~�k�fb���%5�Ũt�&2��P��D~��;��^8��2L̪fBH��7�7�S�E N�ms!Gѫ8�U�uE�.9�?��o��@Z�6m�h��xԺG,g��]�5/��9�`��|H�,�Rkl��2:�b���u:
�8Q���41EN�l�S�߈`WJ�7n��ݙ��a��7�������0����� |ہ�����D<I4���*V��F�m�f++R������YE<y��v���D��@���N�|�_ӋKIq�\OCvo�%p}:Ȣ��3�%h_>�	0�x�)S[�~�h�a�p��E5~�b<���,V굶-bG�w5�Z,��m�fiQj�����|-����W�	�ϕ��)R�Ea�?!��F��������`C���'���$T���1ۗ�����-���FN�ps�6"B(�(��?���������� C=�d����g���[���O�������qo�n�|��X$��i[�p�����5���������M�����"���w<k�݀�.�������.N���uu�l�J}����F���aA�\ހ��!�l�-�J�ʑ9��"=}r,�k)��JX%�̣+=��޺���G���x.�bkt�W/*����7�`����7FDġ�&#��ڡ&��Ka�ŏ.Ca�b��G����U��� ��!&���9���������G���HgE��|�%���I��~,�ٿ���`�H��Ճ��oUZ;��sн����D�.G>��h��Q�rڬc3X�B[�����|V�:��yV*�b@�V2Z��ZfG;c���[����oq�)r^�����M��I�=�~l�}�}dO�_��۲E����{�nW�s��O�w�R����b3?��*�>�)m��X�
�$S[�;��2tj�2�Z���X�CEˣ���@���f7����(뼬RЅ��F/DtY�ՠ�@H��Z�x�����}t�N���
#��4|F�����_~L�v��y�)����O���l���|�"~����ii�ZjA���Oxx2�������a�fA�jʅ ��XB�>�uX� ���<��c�)��j��Η�08_0��s|�~�o�=�.�^aR��>GEc�W~��g��@�CiA�o.0������'����v@*yV�%y�'�a�%ݯ���H���I�L��d^
�#6�b��K�
6'G81^R��%Q�U������i*�/ԉ$8����*�!jx=�CܘC�ܝ����V�E"x@�r��`�eLI�g�ub��6�f�ӡ�;f�U�`W𿋄�ث?TQ��p"����&\�Y�\���3}"L'��P�a5`�[�}���+3���:�4
`�[&��}�Xgv�4S���{-��(W�U�����&���յ�r�G���.'�(��ho��Xd��-\��|R;��R�ZQ�ߨ�] ����]�`�8��(࿝]&�6y���C��	#�X$sDU��n�t0&�}2^<��O:kKr��z"�q%���O��| (+oX�~d�ky{�v�9��;=�|5�Fa��j��TQk
�mrc�Qejm�~K{$�L
�:��<�5�����/�F���lUa����m���gob$�$�v�dn�����!�0]FjV��6,+R��y*�S��~�$�B�z�x��C�e8�?��!��l(�����=���?$����:�C��$�0��5\hB�)!X��o�XD��Ɍ,�^vy���|8�)zzFx�'nu��|ꌹcfX���bF���k������;�9
���f�J�0"]ƻ"(�3�p�(���A5X�k|i�Љ�@ڋ�N���e*�;�.,����1�i�/<-�%�	����F�ƽ��o�d>K���� C��F��c��~ߺ�H�d� dD�x']��GO�6��z��֬M$(����J�[#��Ê�͹���{	�Y�n0`q���oG!�"��B#4JL�M�W��3|����m��w����D|�}GT�����~�6�$9}eT�;�;u����zh1�����r.��s4:M��T��=e&���<�A��鯑�a+���2x:���һ�i��H�(��T��܏-uA �U��5HH�9K�l��2V2��ɟ@$p�
�{7��JW��Z��'{�Zci��o.Q�e��k�U�V��OR3���;��N����߿�F�zf�B߬��)&L�m2J��=�L7(�o��r�f�Z��
O�LV"��`�;:Wu�rQ���sh��p�	�:P�M�X:'��dyOg��%~L<a/g:QZ��]�I�)�U
-�X�43�k�~W-��;��9�v0/-��7���~�h/[aB]��'x$�)��K\+�;�^�e�w�l'a5�M�L�A6l��	n�+m��Q^������n�7�ޝ������^��ׇ|�d�NE:;6�+
l�K��n~�n��-S �_����aU��Fz�"��z3րVG�S`��4\�|�
�Ÿ�ꎼ��G����*'�#_�7���/�{
ѓY���u����0t�W*���S,N����D2�Ŏ u�{��n��6~^�+D�� �4%���0��NF���#��Pq@�)F݂��I6e�\��ef��N���A��L\G&S꬟(�s�ٖf��8�i>�H�ke������C������[I-yڕb:%��t�S���D*�2�K�]e��g;��OH�X��]^�.�ix\���!fB>Ru'1�� ]hD�{�LW5ơ~=�-��L��"��>�����P�7�	�L����{�k�@|��Y�T#JT�0���I7�R����0;��A���Ē�;0.C��.r�}$n*�v���S���͙�T�T`�[����W��B�%2s���]�����3�Y��@��8�'<�#� B�Eh� �K���|N���� w�/�UX֡��������js"���-��?Lɧg1X���GX���ނ�w���pKC��,s.��K�z��|f@XF�5�X�i��n���'��bL��jq�lU]�v-(�@"�~?v�dv�V�iG�"�$�LZ�M>E�[��r��}��tE�E�'�e��`�zZ_V�;�	E:�NMYO��+Bq��W4���ۛ�Y���69�bGP�þ	��a,b6����������oy@ޔT�/�4"�"P��hZU7VT�&	�X*!`S�U\2��������t�<��|sQ��<^F��H�j�	��Ǖ1�4G~��Irl�����dk �w�_�6���k�i"P^HH��:'	#;�b�
*5��"Ń� �[*EߞལaJɂ6Ӿ&�8����E�[qY� %ާ��ߙ�����DIH8��e�� ~M�hn�:,�����W���peK�8Y�*��z�앧�W�$�BC�tn!���<�k��m٠���-8�U�z��aj(��4R���^DA
�#&��z���c��UV�j��f4�<sBL�,�YxeV�b1�w]*LMU��(�L�~J'����݀���R^�&�?
�t	��2�*p��X�(M�7aG.U��B�r�j��f�Dt	g��k��-�
O6�4���g���nj�HQa�胴C	6��?u�c�u߁`�w�]���1S��WG]�ƹ�a�$��xo�躊u�0Z�������?��ϧ�l2�O���0Z�?��XC&�D��i��V4��oI�<��a'�U^&�f Bx+{���L�BB��_�?�*��ζ��=���21>���M�O"��5h%���z5����=�W���xR��yN�d��=2�h�pH`r��sCo�y�7��<^;� Mg/U�]�U�_��o�W�0utp���Eu��O�]��Y���gN�;�	o�w�~E5@�����}�g�I��Dz/)a^��*L2�/������q�%�P����6�p����/I�^����^��(aD{:�O[Àq�U�W�0��§ؗP��D��e��6&�A4��K������)�24�u�2�Ќ��'KS67q$����
eyC�׉�AaO=���J �ўnB��� �J�/��:�Uxƍ\��������I�����M��0���G��K���H�����BՅXs#iw<�K�[���-�p�Y��  Т��Fz>+�]�팵S���F)D�W��^H��lS�8ݲ:� ԋ��@�i�t9�c!��hyw��Qp�˹�#D�5ZY�@��F�&I��%���=DS�C�����d~� '=(�/2�����WZ�Ut͓=eKpGv�(��E�η����>:,2��lߤ�n�:�Qc}OeZ-���s��8Z$Q�D�v�G�[Q��"���#��g��=E%�W���D�i�����P%%TD1k��&4>�p���x,���uL��pǨ?q���l��{5(�Oɰ=����Y�%%�:h�jvKM������ 0���c㈭"0y�#���	8ߍxa����"��6jn"�qW0Ь�ª.k���I��͖v�%>�>��ޛ2Y�s�����{$�S��Ԑ�������5�,����;��W�U,���lx����b�7�����x���������	����)�C+�/�X�m���س>�ajռ2��ڢG�ƣ}v.@��S�	x߼R�>�Z���l�,�H�S�cX�M�q�ZQ���+�6蜚�0	Bۋ�z�_�ޞ)FW�@dD���l�M��Ǿ|�����������l�q� �b��t*�˥����K�a��A*웛!���aʷ��U	�����g��8JԨ!/�'�u��:�m���^��QVVC~/�'�.:ʘ�h˨
�X��8�f��X`2=���j�L�{�#�#��^z����IޤM�߉mc�Ը��W�:XV��V��g�in��S��4/m���2TS�#�`dl�dD<K��<#����L�{�&�n/���
1�,*�.�E�}�S��r }F'ܣ9	�[�jN��r�x2*��*AX����O��#�D��L��r�ڽ����I\s]�;#�>`����3��2�KgV) �pk���i�����zV����a���F�����;ƧO�h�/JZ�SDiK�Ξ�q�z����b�W�6~�#��7 �AaJ����k�=s^x������S���,7FwewG�]i@sOad. 7���p�l�$D�^T.�	c�i�fe�n����]���.?��.pT���͚J�?#�G��o}E��!�����LY#������¦-OT�x*�N���%�P��Js��sF�L3Y���袷�i���L�WT�8љ�s�z,o�d�|@��D�oRی�1��ĕ/����IN�G�:]V����U>c.��r��|��K�iF���rՈ�	V�b_��_����G�8([=�������I)�������\�"����\Th�)��ւ����@�%T�M�Ӱ��E�7�=͙z�C�u.cX����ۄ��1LȈ��
��,䫢C�g��e�^�,�CY��̮'ŮQ�
��ݛ�nA���bhJ�+l�8A7�<S��ͽ�[�VP��48:'����K����9�ה_��ge��Knu�y��!��D9�1j�ĩ�	"����Ey�Q�&M�og\����&)��@>=4���+�
�;�8|j�	�E�q+O�ͩ2�Sd{���bDMfsFx����\�����?";"�{
���t-���������^�gk��;@5�G^"6L?-B�Zؽ�,|�碚8��󱅶�Jt��j���� ܷk "vC0Oq�z�h���J���Qk���1���z`ͻ �ԛ�����4���9mI�+{^r�\��!o����Q�Μ~(�?/4�A�f�g��m�.ޔ�v�`����'�N<�fqP�����;1o.9\���і(ۨ��f%/���C �	z��k��[Z~1����`ivBB��m֪�,�	k��h���I'G�K^˺��:��މ-�^�A$8��-��'��~y��ŷ�Ǥ�ME�B��$�Ɏl$vTN��}�Xч1J!������K:�	�
�wǓ\+>o)�}gk����'^a.�/�hcO)������~n�o{	X�wͫ�e���>$��D��,�;��t�&�7����6�ᕩ����f�����՜����^�"З`�Й;	�|�ރ���Ȕ��Ơz>�q�֏��Ÿu���O�
��v[D��y% ��L�������@l� �{�A%�W�soe9�ƿ ���/�sb�t�5�����2���Y�%jB��NbUTK^����5:}2����Q�E�sa�+�ծ	,�z�����>
���]Um�ɘ��̭���z����}����S����L��N�cM�$��h�_�/�-��&ؠhF�K#�Z����-�!������"ks�}��h�*�� ˇ�:"��J-\����T�Z'���8*ݳ�4��5耀�1�8^@�[�_�m����`z �FƀC�ӫ�Gv��.?`3A�\�	�/^����P�J�ު���A�zMMp�~���c&����R��&�s#��:C<+�l*kZ[�C`�+�W��3箹o����T50}9�[�H����R�I|P�ܶ�պf�cyD���v��|߂��
�6ba����Ҿg���\0�wc� ۘ�!�?K��w����6���
k�D�l��O]y
�C+��r� �0}��˻
�H[U�<�ú�Є�a��ߌs8Q�8��/g��=��`=���e�}c�?�����V�Gn��u�vBW\�(����/"������c$K��ڥM�8����~9+ｋN-�y�w`�SC���Á�U���(W)�m��e�A�]�5��s�m� �;K�=����-�gJF�ך�g鰕xlq�)�X��0fB΄��Y��mIӺmd�p@�Y�z3�l��/�����"��mB@0{����;w-[�y[O7��<5\�㙽� ���&7���,\ؽn��O�e�l�^`�
dȚHk,C��,�p�5�t�;}:�z���� �p��K�ݕGЮ�c�0+�Æb��s�<3�}� �iO.��@iH�d|`�nl�4MSY��(��8������7K����k��u7�����a3I�)�����v��I�0�b�wU�QP�e6�A�ʛDg�r�i8���EF7���Ѓ�"��o���� h�T���,р����Sk��MX�/�I��T����8���uP�n��lxR'�����\^^���2�B������2����g��f�6��i$KU3���\��T�{�C���C�kZ0��.g�̃%q�u~�E�oU���_���Y'�i ��j�υ>4�`��P~��`[���F�=��&�`�����F����!�S��O��ۈ�L8�ŷ<qs�mb�EɈwޞ�'�75��[�*�1�����lڢ�e;������5�U�o3��L5���C�<�I3���u�{�+~��
��.�3��bW8"�ίg�5���r��Xgٌx'��R���JP�$���&���i�]���
vY���ޞ��&��u��V𫊩�	3M<I#֑��S�:V����Mq:�ʽ��5� uX�Vøӂ�%O{�(i��
Z�#��\k�(�������b�x�
ek݀�� �#�k]lis�f�����������gu��Y2?�4��{�V��}TKqH�>�;����^�>�,�e�p��"g���3�I�@*�uj�s^[�H�Q3Z�$	~�Զ� �'��M���8�ѯ������b�M+������i��]�2S�����Z˕Ӹ��b���[�����(!��rdB�!z�.�E���L�j�N[EbK<�E�5�?"�E�}�l	x2G�_U��#��6&E#oe�'���	,	pnG�"Ut�8KL���l8�]�@u�q�_ʃ���]��X�:�����q�ר颙g��}��E���2���vl�`oT~�����I:��܁CJs��c_n��/i�"��l�9�
�HE�Ƕ]l�,��� wL�T�)6����}`�%:=V���h,�֊�ٗ�(�YI+�@a�jz�}Dt:ND�d7 �j��-�:5�&k�F�k����X�h�A��ن>ٙ��J��;ՠ,�u{�#�kN��2����������5^z�p� �
��&���Z��&N�Պ����+E�ŝ?O~.a\�ўQd��R�`((L�e���ǰwRq��?���d�k�SR�l�mf:�4�`4t��v�������U\��/JqS��5�Z�FDF�[ai� ��9�WY#���k�Nc�=kJA�AZn>}!�P���,YF��wN����[��y\����PAүS�켭���4-�FGl��FͧG�G�]�<ad<4>������`w|^.r�f-s>y�Q �N'��ә��؉�	}'�:w~���X�),_p�Q8u�J�"e#'�8����Hȶ����ŏa�@NӲ	�]�(Zt@!x��,�kΔ'R*{�'H�*�5ܒ���2��[�l�CL�k,��A*���z5��3[��2m�tSѝ=QA�'���{�y*|]��w}�m���,va����(���� ��r��h#qk���m�`R�ٹ��#P��%c��}ц�q+,�erS�}U�b
�a�6�oU=�u�����fS(�W�v�j�q����R�}����J��N[R��&cY#$�̨7��~9���nK�bH`�7��Dlk����C�Y!�(��R��bi��.���8R��)������EJH������i�IF%�Ͷ@~0�����a�@�ws�x�l�<TO`�F�N�S"��5,�8��
�lɍ2���+c�f�?���cS(����sr���I`�ٳ���pYޏׂ�J�,X�[Ղ�i���5bGY���M'���hF��(߇O4�G�^����`��.d(�	��9�o��eU��;}1D�6��������1����A��jb��:'3�9~>��?��0A ���ҐD	�����IC�ӧv$dl�w���1�gJn;r��VS�C���Ng��uP+���-2Aiټh&lԽq�}���J��5V�g�G�(�������E�ƚݤ�����5-�[Ǫ�+�T%�"�
X��e����ݷw�y\�j����RʎrE���*2(�NCg CL�
6+�3/�m66̃u�˺*ci��V���:ʪP���$�����ꤐm�Dܐ�;Z��9�k�@�j��/G���F�K�,���Q��$�x�&؉�jK%p���ۂ�U�Ak#���lh��z�T�>.T��p`��(�]k�2X�w�/��F_;O�w�e'F�x'�Gd���;i}Fݣ6Y��-e2[��t D9�GW�j��[P��n%�'P;N�R���_��K�{,q�i:�s0�
/�:�y�2����8%G<#a]���(rqAq��|�ʘ���t{0Ϗ���%�m���r�t<���.��U
���Y����l�O���a�c��jN����Й�;?���;��h�t�賦�9c�=�-��7�L����(#�PZ�g!��&�f0�׃��ʹ�W͂{�<A��1 g��C��DQ�1������S�:�
7�|�JO9�/Su� �Y��H%# y�G�O�9@˧��0R��U���g&���A���z/%����_�5�̼n�D�o��t�?E�D�/d�!��_e��]�[��j���υ�a�g�D�L�U��^����Ehjc鱓TD��c:)�M��7Wk�;]bNIfL[}sR�sF�h����0[л���q!�V�;4g��Z|�h4z�n�79�°�K�@{J���=�g�2d�m�o9���2��:|�����m�cva����]9��w5�٭�d������V�9ݢ,KUxf�th�JCo����h��Ԯ��(m5#b`uc�,*�����ǝ�z�ƛҘ���b	�{P�je�0]	��m���O,�À�R��G�bx.�o=.�`:�Y�,0����}��ҵ��dR�,K�:�#H�Y=�j�z�{�mT�W�=������grqq�aC��J�y�l�Y��gM�
�$HU?�V�QP$�!�Vg��Q�if�D����PgjU:����F
e|��y����-��Wԟ[九�$\ҧB�����H ���N�e��[*�+ş�R�s�F�t�BI�]�rS�t6��@����<LޘA�(����5�x�<�_rM��1�!�����_��pz�̭��L�,�p�?����Ǐvh$��>����=vp�`��n�y����3��Eq_Lu��
'�*����ߋ!����8u!A<2�����`�\�hl�yT|ѨM�\��~-��8���q���Gͯ�[�ytn]���{���׊�|�}Ov0N�/\z�ꂧ��Ky�{�l�#�q�Q��'�b��1��^����X��O/���%�(+�_��WY.���Q(�Z�V��h�5+���'�BXlA����B-����Af6��'yJm���;d��#w��l�������b�=I���LSh����l���H�6p:kb���"=��Yۼ`�r�v���_�����A�������`]���/�� ��%6���iS?$B���:>��^�Er������KZ%�
��%���"��@�-uYYFSd�ܐ�`Wo�'�oh��6�i�������9Zp�i��/��������r�x�O�R�Y��Z'����~�2�y�
ڈ,�2,�"F4��d�^m32k3�x�m�u��&Z�З�x /777��i~��ą�K�9�U7��J�dХMkSm�m����a"-=�w@v/yH���GN��y�XP�x�t�8b�3T�(�-:�9��0�-�J�뉜�CDJd����o�SP+����Z��q�Щ�v�s��$f'� ��~�?��a���<c��O��Q����=�%��W�6�����[N�+��eOk��;W����q��ݕ�u��F���連1�=jo���><��3&��^��I0&靡� iϨ���%��X��:���ý�/��(�p���ViQzI�� ��Δ��T���W�Bk�u�n��u�.�i�+��` ��q������py�M����TB����0]S��Fq��]�X�,e_e���|a�'��ź-�"�]��fr���j`p�e��z����w�	ʱ9�?���q�8���y&�/S!��X ���[%��݈������FW���¹��ߧ����o���!R%1�,ig��/w��Q]</b!7�F�|��[j�k֧����2C���������e�����?�H����2�HO�i�'�oUg�t�vB��Њ)��,�J���s:,	�mX0�Z>prs�6u�Ơ�2ҿbp���|�y7��9C���쌾��2�����PLu��4�щ�Ö��#�vB9�GS��;�P�N�ɠ���kqA�sf��bjwP��m�q���MƤ��c"d��Z=ϏX�R\���I�5f/>���N u9ف}�=�@��'�����M��8�����x�=��[�%���3�*���rV���E B/���D�-�Ă�� �CjNSY�l�s�ￚm�6�����F��qF�}5�j#YS/�\���g�!gVP��M��@:�v��y���~�i�h��9�$e#�@hԒ(����i�^��z1�X�4�P�-�}G"(�P�2G�;�4��xño�����n/ݾt�!�飛���~��W�>�O��m>dX�	�{��L����6���V���ԝg}	|� ��E�u/c�����r�����w~�Ts���[?�y��ȗ���;,ȋc��՚k�;|�ֱ�i�)�~�a�)�iY%�Dl�m iŀ��u�����.#:�)%�����v�{�JC}����՝���l������  {{��Ƴ�|��\7%�@��ƉԱ���|>)$��4n��nQ��h+�9�=���q�kQ㞁4{:sA�k�A�������88��T���<�n��{7E�u�}Gä�@f��{�@|~QP�/�æ��Y��+U���N�u3���]��d��i����g��D5ӑ�B8�O��=���|+�r�䛠�I�����g��z��,���@*:�Z��w��J��F4�b�"�+p(��;G��DEї�btdi�#�AJ�&�?��Wf-y��-�o�p��T�0Z��*#�T�v�+:*NVd��odXXWn1/��z�t�x����o���������0:ԹU�4��^on\��ѯ`��|^2?����I���< k��-���?З�o
9Q��a�OUO�@���)��],O#�^��gNDښCG
g>�$��d�Atq��0^6��&ĉ�����c��/�:U64�A��<�<�����|Қ�dj-n��ii')��<AaS�(u\����"R��R��=S��q��/�2��Gk-���+�Jq�����8�%z��t��Oxr^#,���7���*�*�4�!R�)=��aΐNNj$緘���J��No�շ�zu6�9��@~U��%/ހh;��m��M�G�Z��=�B�o���B]aGBN��.�
w� _y��t1v�)��ha[EIO�Նo`�?�:"2%[��O��ۤe��7%���t�T���p˲�n�P��j�I4�"!�={�~�L�kᎈ�d���^�����\B�죠�
@oC�uH����sP�Ӫ������ܾ��GδJ�]_D9O��%�������M|�)T,&��a�P�bU<��A[���:�����&xT�P_���-\��'���a,��:ʠ�]?��|%�dH�а+���8A����D�oN�d���c��J��kEwsѐ�]ԝ1�C�nv_��Y����ȿ��J��N��F(��Hb�ûr���f�:���l����ܜ���]}>���U���*�B��g��K)`^v�@?�|S�R��ˈ���`ɓs��[/�p�o��ܕD�� ���Q[]]"���V��sߜ�+� P%�u�`��?���\�ae�Lh�,6�mhr�2f�}-���T�5�q#�g�I,��7Q�24,3n�r�G6��@J��5�t�8s��s�����]cC:�Z�K-~��</,��Q�n�P�o��݃h�_-�Th�c�ӣE�ɄT�ŒNׂ���&Lb�7�����U�YD;����Z
�4���nB!��,��C=K��"j�W��w�qH%а��Y�ho-��߀�ᳰ�ϵM�.�]G��`ѹ6��}���^Z�_ǟR��L���Q�<p!X��o�W�8fr�5v���u�ю�g]~,3uah�I�����Jz�{ E�,�QhF~���aWfF5�8��ך,��q��,�6.�y��ɦ�&na6�l�N�G_��� r�j�q2Pg��Q�ܬ=�b��%��u��1��y%]����]�'����Yp-Q�]�3���
n�7T�e?i����IS ��G��]MՊ@¹R�E�z�oEE\Y,��ݙ�q�K�
�o��ɥGV`�{�{��NPb�8@J�*�BI�3���AS�,͛M��_��PPu$@�J]�YYx�V!�]��<�Wi�n�:������B��Q��6�tx��২��鑱ugG����(��'U����i^��u�2�msk�{��3����#b�N�,ce�������E���j��F���a�#�V�F�CX�4h��?���S��by[�.����\�m�,+�ڞ"҃�5�|��~�:x�Qe\�+��?9����&hy�|��1��`A3���8��!i��-��v]��s���	�8u�q��\�/�  {i8S^�<#r`�����ㇽL�7�'k�tf֙���콚CFt��!OZ�� �(�W�_��I�����N�F�2h%��!ae,9ϵ�=�^�0���S�N���WZ<��k����Л��d��ZK��O����o�G�c�� �\�\P�e�h�[d(��k؈������п���-C�!ā�ԟ^	��z���l��|�G�s�i <{yBF|ՠ�:7��d��zةS�d�mL4�����zB���W9�pU�8�j�rFM�(X430�:�l���D�v.���"5���Oe`BZg��[B�*�\���ґ1.����	Y�B�< ^��fդ��PZ ���6:�g���QG����#o�J��,K��fֿehr�f�$��x�v�I���?����L��.T+}r�Uz�?�{*'�a#L���,#�諛�ۘH*��d��p�dR�4��=FD*�6O��=��R���#�u]��7:GU�i��J�p	K���ʥ��   ��-�E�� ���Æ�5��g�    YZ