#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="223492387"
MD5="3ed79370be65298e0c0242ee2583e39c"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20820"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Thu Aug  6 20:58:47 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 160; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
�7zXZ  �ִF !   �X���Q] �}��JF���.���_k �ץT�4|M`=}��kIۅ���L¦ U<覺D3p���׳�Ɓ���� �b*p	D�]��@;F�W�Ho�c�g����a����9u���R�'>��;��j�ќ��S/����0Պ/#�L"���o�*~�,o�!���%��a$�O�O8`me�
Fk�l����#��~��h^����~T%э�X4�z����p��B� �z	���'gmI��%�������&��B�x��t=����o6�ƹK�P�����g�SR��A���0T�gOd�Ijlk�Ɋ�.�-	����
[�>��̒�2����g?��N������ O���* ��FPrH˧'�*A�s<7�;���a)�hG��B+����\�h���#�Sݦ��W�8E�
y��� !��-�;��<%=��k��-��Tl���[O-)mJOJ���8e�/'�u�#�����Y]%SU�4�r��z��<�� 5s%��˜�ߨ���5g��XC�R�p�M���m@P{���U�y��ry�f*S�J�����s?������ٲ���K�0�xd���C���T��͸p���v؜��9d��LeA����(FZ��o��i.o�
�Iu�YEϐ�e�4�Y�n��b�^�"ϒ#"���J�5�0����Z��ÃpiI��,����J[�3����oU ��9&0���[���	�f����CG���~I"D��xH���qCw51�C��-��X�&� �V��К�{��-�O��������|�K��ݧ�_��Q��$�V6p���7�i#�@s�����iԤ ��vN�OE|��jL������)���ckE+�[%��3���$̪�F�cw��s �؅�%��SR�j����vf���~ �(M���$x|<�/��ӕֲs�hKf]Pے��YqȟS�4U	���r�M_磧��u��*z֥�O��_ք8oU����}��x��FT�r��tq��>��+ˣs����1fN	Yk�3��� f�le��¯��5�W����Aڶ��N�l���|����r�J����S�H��K9)��<��>װ~��5�� ����F��*������j��	�z�2��s$Thu�\�Z���]�؊3��}�j���uV�	�9��]ͽ#�����+�6����gd"��l�q���zd���8$��:d�-Y��i�.�㲘��ڸ�oG�_�+�e}���y�C�-����D���_�ܛGI��F�3��7�G����_
�~=W�5�׿`p-;к��*�쾔�v�l"�ڦ4��(�V��dI^Gya#�� ������f����=��p�jh�PQ�S��NG��xQb��o5N׃�[x�wP��������J�S��rO)��z�d��(�}��vb~D�'�:2�s��i�5���)�UE�u!��>Fn�g�~�]<� �'��fiLx���i��RBw/����<���yV�%@=�iJ�~`�H�� p������1S�9�c�I�_�~Z|=�2��*I.�[��s_'�����9�qU�����88~���w��i���H��s�
�Q��i�}��(5����a��G|ߛT:@e��@�}�4�r�"�`I�S��ίR��΃9��V���RG�_�A�6G���>~"�n���i�ݍXt��)L�8�����pV��tr.�t{^������;c	%�`hg�g�<����Q9�l޽&�k�''8���iZU��-����?���BⳫpvM���?L��,�B�H�L�&�Kj�P"؝b!�6�|����/�4����Ȍ�[�iP"KN��3�9)�����}iD��*}�z
�nT��=�>(p�P�����i��D�A9���@u �Ȉ�Yd-���N-Ӛۼ%^I�ʎ��O����p�볽}9O¥��+�>u��my��ٰ�BBS�oH5��G�o�).1�!�������M�d��� =����=��a����vq�k�mK3`�dPL� �\�l ʧ��Ai����3]�ӓqق��a�E�3�(s�\��Z���+�:�(G'#i�Y0�.װ@��H벓� @]#����Bn��5gl=G��Zc�,Z�6�!�"I@gD#l���!^ej�01��PՑV��(��o��5��$�~*�����螇����!0��H_�Xa��ٟ����UA<�����b\g�-
�I�Cq���̴���O�נ�S"R滃ad?�E��"��4_���6X�n��8'��ԕS�Ǻ��K���(���P�3�oC
ŏ�7+��j�]���8p#���߰����`� RK�:�zO��#R��_g,ΛZgZޙl�b[ �eO���ל�����Q[�|��
�Q�mִi~���(m:^tfC@��3R�s�4��W�+v��7Xwo
I�AR�zV��n�Ǣ�Gɗ�p���쬁%���V{U&i��d5��h2�B��h�ν̤�|�ޱUX����~�11эg��YxIѶu�X5�A��6y�؟�H��X����~# ( �p�L��m�1%��b�9U��y��t�)�ő.�5� �+�r�������H�J�CGK<c8��P�%��{�j7���k��Ё��G'y>��X�T���wG��>7�����6�끕?���q�`O�b]�x�f�?K�
_Ϻ�EwJӱ���@����������nY�����\��[��1�5%��!Py�i��_~`�G3Q��-�1��^q@�9����6��6���?�Y�s�Ą-��YH�����/H��T1$�G��_����yDD�ފ�u+RP���ʔ>�H1GU�]t�EL����!�*Vl�r�n����k;�Rr�n7�����7���qT�����7 ~�6���G��B�^"��0����;k^�<�ޥ��k`��E<:?�t���gdie���@%�x'DPm� ;v���2�I�A�o伇�&�|��"!�9m/��Q���>r�C0u�,^s�99���ɠ�����8�#E�+�ч4"Կc����ls}Ԝ/F�(�������B��A���-9�	R�o(����-LI�b��{�T���3@��+�m΍]>+YA\���vY��/:A�6m2�y�52�X��7�(H��q�7�
�7.9�2��S�
�RN|����e-!h�Z��e����X��>��7��>`�yj���NB�q屺'��d�ɍ����8�
�6q�/t��� �Ƹ� ��u},+�So�FjR��j*,~R�\%/����T�h[��,���Q�xU���ӿ	�?>	�����|�M������ �p�]ੋ������^�W9�YU��6�!��
M+�����%��M�hQo@VV�J�w��JQ�
��\��f�5������qYj��&���}ZR���J8-M-.���E�=KO���*4_uY��xl��/���3��HܷN^�B�{�*��+ķբ�k��FP�@�k`RxH�Z�ω�"Qp�ƌ;@�p)�d�o�cMN�%�Ô<y�ڰ)T���5�G7e快L�8̶���D�[�f�V�%:�s�#� n��+:ˏ�ꛄ�i�.g��e8�,�F����S-'��'և�z��h>���*��?=Đ["	Ӧ\`i�
IElحi��S:��Ҷe���)��K+0���;1����\m������nAp`*����Cl�*���gB܎�`�I�<����9M`�W�.=�b{X���ϛP�UѸ>�����v�mK�`)�
A+�g���p� gb!��`I��xW�X��~�y��A����B��	�]%�ܕ�R:醢��(�	��RđV�(W��R� i����!UH	�M	;�0�����QL�P��X��̂)��*.J�óW{�V�R�
Y	ͯ�z�����%:X�h�#��)A�������g���	��f&���K�zv�U�&R�Ҩ�)�j�����`��o�g��$�7-B'��)�yN][3x����%�.��__o��־�x��%�z_S����bu.I�I�Y�]bI����*���r2�0�U��?��8< ��  ��A"x0B}]˻n�o�UΆg�L�R��P�?�d:������������+�l�!DG��M���a䋜}q������7}y;��Cȷ5��rkS�I�����O�à1cH��Ԉ��\b���W��mp�u94�-��m+�H'���'3&��ܾES"�V�x=��z�!�x~�[;mŗL�h�7�Q�=4����r�N�zj)�\�fhyU- �Je	����jO�ؐW?���KI��V�ǽ#6�@��-��B6H��H-�x��$��f&�0�eS�9�I-Ӗ��n������ /��bh_9������7��ԃ��.\s�O����DU��F?��`��x���{����\m
�E�D�w�*�O�r6�Es��*ZE
t�/�-8Fv�����0�����3v�!��D.�y�B�4� �Ͻ�)VՂ��8n�樲r�n}��z&*�,]� ��W�~���^@�AYVY@+G�Kc�W�zBd��g��J��↝��ĝ�Z@Kj���y!��I��׀w���I�R����]�q�!kY�����+hD[i��W��&��ܷ���8�;�4��j�EZ5�g�otr��q���%�o�j9O�q��6��)��8T�4=�R�50��S���e\�b�	������<�ƭk_�{T�o��(�.��Q;��8��Z�r0�w��4�'�{�B�c�cd��V��͸�_�"�^3?��g�=�c,�މ���\�)\�i��߂�&D�[�L*p�
\M�p�q5�hʳ��Q,�GhI|#K�>�/��՞�zia����l`�Z�Pɺ|�'bu������L$a*�z�5���F��u7�7ݦ:�Ze4�_豠<.�㟺n�`�G�ɔbn�ƥ��t�q�^����5&�Ǡ!��	��s��W���PO@&p��Rθ��ᩥ�q2O8���?J��K�CD���=կ���w
�� ��a`����>���V����f҃�U)b�Q�y)�3��sL��|q��Q_�g�d|&�v��-�Swrl5V����V��P�j�5��K��y��-���ٟ��ɓ�G�3?��c����G���1_#u�Q�Uˡo<�D0��k
�j3�}�b~k�c�8�������Bv(*Z���$�}z�[A(�E�l���eT~s���y�N<}�sV$���+�oҕ��=������m;#���V)I���tȉ������*������(X��<+��(�&q�& �DM��s&�kR��g�ZJd��P*��Ho�'{E`>�ƅY�ެ�>:r[ x*�l�y{g�/s�gݹ�y���_S�MŅ!���Ʀ�CD��%�w�� Cc�{�.���B��Ed_	'��d��ÿ����a[]�)�kI�'�Wgjߐ�T��/O����0Ļ��������xgC�͘/��<���t�h��{3_yh4.�>F���G�eј�-��G�}}���d������H�b=�/w�����t��iz����g�)G�����;�T���U���;Γ4Eh��t�40���3���%�E�t|�)C�i��,dO��H�6H��>)�y1�u�n�{؛*e�M���e�1o�Y'������@���n�z`;C�.�h�����`T���)�Cڶ�f���,��Ý�`K��?�H��WS�����Z�@��Awt��|]�ɩp�5��m���7���"7&2�3 i�Bd�C�����Fwܐ�k���kʿ\!����:�\���!6��#�9ɿ���7�}��5����]u�o���p����:�I �(���>��%�'{�#*�yh��Q,��2"�BW����o��`���K�[+"�u�����%��e�P`8�E��Z=�����L�H���0���X���h)>�[p~ M`�D�g��1�2��/�� ���H��+��(��^��\}t"Vf��GgT>p̆�O�#�F�����5ܗK~ő\�Su�c�����{]������) }�p�������oˠ>�`��t�)�t�b:��ê����	��=��s�+�{��t�_rz��ooX4�x�B��p�I�4��Տ/�zݴ�h��y��vt��ܘ�y�o�j�c#��:�f�]���z:��Qx�
����ߜ���Plt5��*`7Jӊ�+q��\.$ؑ)�6��%9��Ɵ��6�r�J��2��v`o�.���`�cNuA'7ƶ��<Y!��?����C ���sԭyEގ��RI^>����8�)x�1�7����1G�9���jG��{� y��g��v	� �!�+V�� 8�Fu���i��Kn���E��= \�`(	�t �D!~4�7���5�H��;<f�o5H�[u��#*ؤ鋆�5<ws������L���2w�]h�_�~6�l���8�Ƃ��A�A���Y�gm=���6�������S�[2�D�@�g�"4�Y	�7�pX��R[���X�go�L5H
Q�y+��JM��a�7t0��G8h_��fuBU9_�2׏���i��:�ƣ%^�^m7��Y�`Ԩ�n��	�M�ս*
���'��^Y<F���?����K�Fg���K� ���$`����{�v��ݛ��:6����L+�(�`6149.��Ӝb<������W����G�F�X�p����yǥ���n�	��*���=b^Կ~�|S���&Z욽�B����Rc���e 8����jf���AfI�ʥ�:�8�O!���2rs��u�a�r��Ȃ���mZ�E�G�.l(I_�#p%��5o��p)��T�l�/C���<��
��RS�D�9GyJ=��m|��ڝ�Ͽ?'��-ԇ��7�p��L�58#jPU�R��fW
vQ6�-r��	`ŵ� _���i�H�qil��m�v��%��I;v�bVÝ[���D��?�x�Z�W���U�}pΰf0���|��z��a�-��=�b0hz�ȧ,g⓭���,ʡz��no.�QC���j��:=�O���8�M�	���}���&D���*�{.�.o����������Gj����R8� |�t�ta��jK\��͖�t�9o����Q�����M�"票�VC�*hAsx�J�BM�x��M"���(�2 � S,HH����C�k�$r�D�keV��E�4h��;OM���7��Q��y:��ۓ&8pyc"�,ȼ*���s�聘�#hmx�Ej �#�3�Udݼ#�����Lw�NΗ�N��J�Ж�ۖwQ��9�#�w/�>�n���T�y��璈�;��zN�.B���υ5�����O{��w��"y�j[�C�TĂ�kY�q���uLX?x��:`2�<S��v��
ju����nH����sGl���#�1��b�	�}I��	kE��E���K��#���?�������^����!���&��bH�x��R���u�[����^舔>��?��\g�/Ws;���v�܈��d���l���!�7�*�/�y�$�e+�/���ӓ���9��M*U�4 U�=�1�ܩ�y�2�y9SƱ�"��B%�QE�p2p���(:mG7�z��{�n�'�Y���7��3��]�
�Ɣ�|,eּ�Z�\�9Cx[��X}�ٰ����B���@諣�QB�8���%%'г�zE01�yf/�����M��Ӭ��HV��*i�]����Փ���	��/p���x�K4<oeۆC_��*�M��F
�
�v�/*=�4zc��*�����	o�T���B&�aH\.5�Uxr/��ѽ�`�yʪ���a��0�r�Nˇ�-v�I[��&���P�=c8)�ɕd���a��G>iNE�k���^��'�饗�KGm�Si����9�CT�H�MP��G�l�@T�E7V�o<��a��7|�"����yݮ�J�����ҁ�M��]�q-���sk�sڢ�(}Q-gZ w�ס��yg��~��0/K��3�^���VIi�h!Ň(#�w�-��P�
æ�7kXӳ>���x��AQ�k^1�%!��Eh���2���Cj��a����8�{��kli���q����L����l�L�sC']��1H>�n��*�fZ��?�@�x�8��}/��r:c~�5��'��;G��	�^6�
���T���ǝC�� �s�f����u6 C�i����HTuD�H=av�����O��KN��b�9y��gY���TH�z���-���	���p�&^�x�_�ɵ ��63����Ń��W�����&d�A��]��y/�u���"BQ�TV�P�!8ԕy�
�������s8c���i�����9cKr6O����&W�\�b��(���6��A����.1�m�'�7]�����	�^��֬�r^�&��(~c��� ��uo@�ZT �,s���Ut�oERU��@P�J%>~��D���fo&��[8�ǜ�Aⱓ�bK$<	ǵ��]|��W�5��iy��ZGW�K��D�j�W�ѫ�5'�6��Fo�z��RVbŕ�2��
�t��Wy�9j�Or��Wm�o	3Ic�"�2m8h�`J�j&4�p��A�;�$RbD�D>p��\�F��b�9�ʛ�>*WH
f�,W�u�����Qt�O#�� T��J��1����[Ѻ��o�&�ҽ���8�
��{TB��'D+ 3�xz9�C��(6B��?������]�L� ّEE�����R�a�}7X�Q�\$�H��������:s/�?�щ�c7�������s�� oby��[c�K(���l� LI�x{~@9��p���	�c2����[:n���3��e�6
��ԁ�<�����3B��a�����4���CeRc�d/jn�����2�i��TǾ��H��+����K�I����I|GՏ�򭇊v�7Q���2���������B�{��U�IG��,����"E�:խ51Ŝ�2�ɬ�{�Y�����w�R)�g�D�x����C�p ��=�y8�X�_�]Z��~S�l
�<�hN�\�u&Q�O�29�z���0+���g�Ȼ$�@�k��X;�>D��E��-����tU�k�*tf�2i����q���Y�jS��� >�^�9�ݾ�"��B�v<�M�Q�KP�uU��ᆼR'f]�i�t�n�.�1,�(X�ʘ���	^M�G���H'�B=k�����e����u����()�i��w��Z��������0��� h(P�7��MvҰP��Fv��
�j��E���N�pX,�j���u�9�f����R�{֏���$��"v��v�� �Jcq�����"35̠z�m&T�ź�ȱ���ɊkǃK�~�5=�4��0%eK����+���A����Yn�t7mlS���HOD�S4ڈ�����ˬL�i��؛��M΂u�<�>�մ�e�rW�٧�"�(J�p�9�D�-���I_!f&���}{SO6k�Ɣ�fFu��5H�"g}t��W���(*��i`�)�h�Oo��Qn��f
�Q�#�� =�*@��2��)W�]f�����ؿ�sX�79{�@��D�#��|(W^)�2�U�4�+�|�cy�g@�/C߭Gڞ���<~��;ע�"��c�{�#;m�YS�S�bKD�l���N��,{RI�W�U�'#+Џs��J��_&��f̟N�Q�T	�7~��b�k�{27yntF�N���	�{�>�{�R���V��o�m~dq��/c�U��|�����xi�Ra��dHv�el��P�u�R���U�eB�j��n�gc!���D�����%��p����~0蜼�G+#U���NǠ)�OH'f-B��9�XLs?��ӫn��i�
�����"�F+�TM!0uOe�jyWR���B��q��E�k���Y#��V m��Տ��-�\1]W���@'��bڳsEԙ��KD����{\��3����#�e�~?����8��pᖼm�RV�<���;���؋?����~����v^��
���#p@8�����0�{���1�q�{�{� ��
�o�0h��[�^�ߤEŒ�Y����$h?=�[a�AE]���+�5��Ul�^���1zmH����w�
_�N�R�ɒ�x9���c��9�5�s�m����px�O���g�R�e�� 9P���q��}d6V�D��ޅ�Ԇ$K1�N��6�M����g�	�~$�B��'�����]��y�Pz0�M�	�Z�I���!d�%4�{n�G�WeAK�#�B��p�?�|oRr@
g(��+�x&�D�VU�a»d����V�%��!��|�3=�zqN�׶�f�X�mwRŵ����5@���n�Y8�'o����'�^���&���Q��M8��=��j�q��U
Z'�S����>~##)�z�m}Y#��I���P��A�'��Du�2���M�u�:�w:B�<TR^h�ͳ�-�)�=ee�J�K��x��^Q�g��S�ΞZ�`���ॕ�Xz�޶�	Ǔ*��@��?�וF�tP����5d6Kxr�A!�\�(�\�O��	����H]��=͟�ٝ��U�w���0�,�47`�RO`�Y�""�b��A��g�_�f�MǼ>���������W1�+�9 / ̧��u���z{��ԟ'-t)�8{½�֢��X�Oz|(���R�W�Ϙ����2!��ge A�����#�����\��B�SzZg���������g�!�g��|;����4��DJ>��,7���య�Y��%0@@>��h��}���_��܁8c/!a4�8o���n��Wh7z��{�Ԯ�q+�ֹ{�T=��ӃRc�r�^�8�pܼ�o�+�z(m���J� e��2��#��!�D��b	���?�19^�Wd�!�iXnPx6ҽWz��0"%(L�9\df8������wƹ1K�Qk�R2�<�r�4q)[�����Cp�����F��@>��1�:
�9 
��%���I�o-6�i��R�YC��Y���v�o�Ndui'�f�U�1��K���M͚~R)&�!��s���cSzy��bݣPc��NSY�*t�,e*�s<�-�,�d#���UX�)�Y���1v�C�2���G��f�0�w��g\���z����o��<kü�i�l��f�.�F��(Z�'q�-	e߿^��&E��Dᵪ�M����'��':��7<[��Ԅ�~Nn��ި��AU���G��F���OJ�g���%��8?f��>��E�S��<��{qmu*��3�a�*?��Ic�P �f���{��d/$��s�r��'���������z��%��\����Zx��	i]�+X:����-4 ��{�3nZ�a�e]A� �e��W.[���zS�D���G�����b�޼�𭽁WMI͌v��9��:���M~9�n�Z	��ϦS��N(�a«�9��-�ѥ�S[\<�e?������"�p�0��9�cQQ��*��mg�bR�#9���g�?A���ٔ�:�����g90�i�b��C���4*5苔���v	��,Y�<�-9w�b<W�b=2.��7�%Е���XA�O�ĝ]V���e�KQ����C�W��m0��n��ˀ�%�5��9��z��2���<���5�Ni�)B�~ŭ�I��֠��[=$.t�����)��9h���Ϗ�/�p.������"�`�Ϗ�mO�6�fyQ.�}��l�&��^ݐ�skw�uj��K�I�	2c�7�� �G\j:S��b:f�t#������@��	V���� ��ֽ~ޅ�P�@,�Eb�W�u��D���M��"!:m\�����L�#�#gT���&6q6W?8"`jP/�L���f���gDxR���ȊgQd�Ɲx!8���:����]��JD2,º!f^�㦞�r%��=q�
W��倁^/��h��y��3���P��e��j8�$	��O�T�p|�������lp������Hot�s��q&�r+�;�ۂZ����zן�V`�Q�JQިh����|hz-X2��n�N��8օqw�93�PGԐ
}I&���I�da#6)������	Xs���\ i��;��/	�唞������	�RWf~x���t��1;�;�s����:0vy�ع;����@��w�Th�Lx3�X��9��<�#+g�~��Z�aK���"v�uť����Q���(�S�~~� �#��>N՝f����7���B��zUN�Ӫ��W_�q�RL���\�kt
������r.��'3�/h-S̓�O0�g�뗊Z�t�7�����ݡ𱉱���t���k�CzPT�w�9�a�k%�G]�bsYr�@:�sx����\����v�HP�k�]JnA-�N�(9E)`j0_q�
Ӭ��$�O
,;.�Z�c�o�Pܥ�[d9sb0p��<���8�\/{���'	�t�6�C�55 ��0�A~l��n��P�ZA���%��܇!�8��0�ʎ�N%� ��P��HZ68 *�TV�.�\�a�E�|�1��:��g -��C�_� �S^0�C`��L�����~3#�߳q����md�^jgtI���F��f�d�/����h'	[�q�a/��a\r-��4�v��Q�|M��da��mD|@�o	�l�� Y����w7�u�A���"N�O\��,ak��0��}a�W�Bi�o�N��]���`M��)��5�����h�B̬�e2g���;�-�ewI�ù��9�.��2��j�՚����W���P*@���Ţ�Ҕ!�P�̗u6H|"+6,R �q��p.��-(�*%�]Q�²[zU.,^�{Az.������x�n�+�"��fĺ�2����̭I���<q����A�&j����V���X���CD�k0��$B�q��1p�(O5���I �f*�_���HpeH��S�U��������W(���]`a�ق�z`̽�iocIA�ABZ�sS�'>� ���q��W�msB�U<B�������O��ַL3 ��
e���f�ĸ6�7���@1�7fY��M[�G
�N#L�b�|h�N���G,���l�")��@|p��PZ���G;�x����oQ�d-���Ek{�ƦN�O�6]'�M�Y'���)\"�&֕h�:j
�2�]M������kT�۴2����r'��DY�!�x*��M�����0��^��|{��b�*r*z�_kD��Sͺ9�^����e�tT�m#���xQg��C�Yd݅���Q��� Q��A�jD�{�x��N�G�ws��D��L5�r���G�-��Sm�r���%��2j�7P�����'�uИ����9�u`ь����i��%���-"=%2%��#�[��SYQ�"TOB��J�dg��o��~Ȥ?`խM�
���}���Au#�������S��G"�&E`����͒ʉۄ	f_�,qj�WO���{��;����(F��i��؏5
�e+��OCy�w�m2=��J�+���I�[��I!r�3k�m�2hMq�?[94n:�M#��X{�<��L�3榸T�9�X�k��'h1�߲ĻU�F0�5�H����SN��-�8��-ݜ�n�|i��kK��G){
1	�jc�VN-��UjkV���eӤcN5.��7L;�c���"�~<[BM�����uy�ղ�N#Qs�큅Y7;��������5Y,�?��9�ά4�͙�g����w=�������ل�t��D�GΕ��f(�"[�\'�~�hr7�8]��g�&M�-�|'�)�S�d�`|�hg��������U��s�Q�u�ĜO����F��\�u>1�G���Ѫ�VYE9&�|�_�葒�l�N��A����w�B��7,R8��G��I=#|o����^6��[0 !�E����x�.�JI,�
A���W�F�;��酗<LU}m���m�>���m��uMl�jRU�玩3KK@U�& >C���}6C�D����Q���gF���+�ѫi7t��sa�<�d�{i$"F�:"��q4�Y��U�o�I<Ս��uǌ���PllZO�r*>����u�@�l�8rN3� p瘰��}��
�9�P��Æ�^�)U|"/��#�wC�ޱD���@6^��I��@&�Y�}]�Do��t��0.%�NW�p����� ���
 Do���=�{���uG)���9|�Zx2&������w��Ѻ��Zƍ;I#S�%ۚ���&�F�樍�Q3�	�����x�MwN?�,�):��'�mƭi�.�ܠ�
��@ᢼ�38y�0"��>YXn��΁�t�������$��-���mb���ɩ���	��mۼ�cH� ?<z��ɒX(�����!71�&���k����D�K�I���JCűed�g�
mIǘkT�Eڝ�5�P�lJ�����R��h��@P�f^-�f�Jt؊�w;Dm��b��#����0���,��8�wʞ^���6E�+T�<�;�./��~*3A��o�cl�l>� X���hV��$(�w�)S-hs�B�4f8���P�,�p~�E��G�v�N��b+H[E	��\�J�:%�{��o���:�=^����5�3v�,s���[*�~���y�[�]u���9J������$�P�`a,~N��n����f���ەU���ðm��s����������T��s���@0���� #a�-"�NHO�q����m+'���m)���M�B��T�-��E�^#6_V����,�����@p��:�1i�&���H�Yr+N��~��\+�)�]".	�5�}�u��w)�Q2�F:���>-��⃷��*-�<�1}S*����'k��*��_�@{ED�=�`�!c �QK��1f��Ť���vWl�Q_E�\��Z���\�ؾj@���6���T���In�<���s7B���&�e���ʘ�mw]q�h�����������UT$�(}q����ǎ�y�^j���YЅ�Qy,�M&^z}w��hJ�H����M�k}��S��s���Q\O�lwr��Ӌ��Q�Ԣ6(��#:O���a��~�6a�~��=q�&�;X6���@=�����
��&pd��6�$>?��I�4�dO� ���]b�+��h��F�ϳ�(8�S|L'�%2rH�FVd�*�M���0(e?g�߉�R�N�ׄ�2�*�g<c��^����_U{g�sr����%]�r���0"�_@�H7�`@'�n����KJ�7�&q>w����n����",�]�~d��G�FG��k�>��'�h���v"��,q�qGP��5^�S&J�&�*h����R$�?����� w�g1D�(��]c�p��������v{]��/��Գ�4��)-֑���d1�3����{�5�\y:���t)�i�{�Y�%I��q�є&J�[FJ��X��c��i�u�w ��)��*B��v�SCJ�{��N�bV?�#o��v\�W[~<�`4�"Qc�,��q�}%�N���m�Q^|��{
Ƶv�lB�!?S-�ɑcB�w�g3�5ܧ�dh��{�b��R�n�����}gz�* 4z_��a�z?w���oχ~ҟ�P��}%����ǪS�����E5u
��Us�@�m�t#6��#(��������`���b�*����6�����yf����A A��.�1f`��ˬ��QZ�2�|�PՐvfuS���4���@���!�����3�~)m�����k�����Z�E�����M飃���Ov�8��>t�B��"R��!���j#�����M���T%�=���^+ơ�7�%FL�J��և�=�@P��SӨ���l\m=~~��6��x� 3�����Vc)��T�r
����jQ�x"��M�.tz��^j��'��J%D�L�*g�O	V�y�Uf��S~2t��K'46��6ۥ���m���^T�����#��n�J��s�(Yt�oU׋�uШ�St泥���w!��ݷѯ6 T7QkcF����ӵ�-:�y�F���E�F�09�i��bp��}�g�!���xJq�n-�g���<�¼5��LCN�Zs�3N����KwJ_=î��t �tt&=c��6���:b˲�Nk�7(�B��i���"��f���ipx��$[��6���t�މG'���#U��%W�`�8f+;����*�.�ї��3�S����W��#�8ku~�s�-�{�ˋ�J�ȉJ���H�Ƃ��i�A�;pd=I�xj��B��_ս�e�o҅n����?\n+�^.���	<�,^�?����@ ;q��:�3�>I�=6��,�o����#W���k�������ƩeI���K Ǝ���|Ts��GJ�#k�<&�R�+L#�	�*�/� �&�Hd	�Ijt���k}ݰ�NYHh=� ����%�o�l�Mk�&75�s�5�uSv�Z�Y��X��u��_"��Xy�v{0��[�O�.�\M?�DВ~���B��B�F����%oP�u*�u��m���]~��Ⱦ����܉��N6W�{ő~s�'�R�?�8U���gR�� ���+C��U��ߟ�8�r^V4;�1�O~>�$���t=Qܙ���>«�0ϫQ��U�1ȍr�-bPC��J��7��Ӽ#Z�ӈJ���c�-ܨei�K �t�*f��T'��?/��Qj@�����"�)6_����YO1�'��NX��=�0��xM�r"�dϞ�5�wus�X�}/��Ȁ���`ʬ%����#���y�y��I�J@=��"�A
�.�h�y+���?�5_u�K�emQ�����tv:6����_���NEϢ͊�/�3���G��_���5U>3�!�k�{�y���%�ɥ�5�\)x�J�6G�PEiS��\��c�4�\ZR�}���ĸ�+�Z]��w�=����ߛ�A�cG9FN�i����E5c���|e���ֈ����s<�C^5'2��1�܍SH�|.�;L�����w,���lz��K��v�u����� ���X/���G�!���S���r�e�w�H)�8p�?9��%pW5(�e!F��B�Y~2?5�d�wun�I�>�!lu�T�����=o9�	�4C�����gyrT�P:�%�Ήr���PՐ������œq2d�S��1����%�'�~;��P!��_���'�}
|oY͇lliY2����&�8�Z������}�����v yJ��ΰZ�����Yy���b��.�Aw�0����uog�C[`-�>��3�{��p?[�����yG��q%n�8o˧7:v#�sl6f�O�i�f�T���6�v_8�j�<�9* �L����FPoa!,���2߱���q�h@1�M���X.�R0]��=�Ö�<hX�Yݘ����V��S|Ud����Q��)�ڒ�;�W%0k�����������0�X�]>0R��	�沿��`�F��^m�&������K
��!	߾D-��u�v���g�A a��
$4J������qibJ���#}���;��BEGs}a�k�J��m�����q�9W�c�wi%~�S���;�F �[�g�&��_չ�b4�c�6C Z	#�-�A3���	_�!��Ƕ��;�xەG�
�t�����r��xh�L�� �lGc*�u�a[Λ6j�S=Q�v=!,�F��r���!����L�X��G��wp:nM��8��o@��
��J����>���'�B��c,��)�Y/�����w�h.y��()/��֙n+��LZ���WG��-lҟ�T�>�Q}|��vBy"�V!>J�tc'�S�0Z:�T�.w?�,�`���e�Y{�z{��q�
,�v'+�Y�ci����m��&�P�7�˫.��V��J�]ా[Z+j�~�7ngN�H���0v��'�N.����ě�U9#����@q���)���~�@%��ѫ=v҂a��e���%Y&���/7�ސ����eE��9k�"���Zz+C9p�O�	p`����.C����[4D��7Q@��v��]-��Й��7��62�����g"��fM,`�ҁjG<l�%aLEvEr��ڍ�i���g��h��O���}	W3����R�G�U����w X)G�����=�E4A��^��X��4�ru�;M���/9=c�� Rh�p�;���3�!��:Kt�ʁ{ྀ�,y�5�O����@Q��RSҸ�ߟ�vB">�iT��G���b&m��2���en���"�1��X���ؾ�r��2��?y�ft�#����P�Lڢǣ�V����M��ë-��	���?���z���Rsv��V�}��pO:��P�	4�!���ü�2�N�[p;_9a<�������5�
�2k�+�ݢ�:�wY�G�)��p;���*b��Ū��\4R`�7hl�b���=''%zRdR�)_;�-�L��{7�-.šC:D���Wƶ�W���)ڗU�h�O�Wn��J%^
���&s��y�D���N�;h���.��W��^��|,~K��Ȧ%�b���=�9+�v�<`� ���o�����q(߰F�D
V�:>���8�"P��;��x�6L��#u7@���7 �v?	���;\|����yq3�	�'W]�L$K���{����pD�:.�i��ٯ-I��w���)������?}��td���|Ϥ@j%19�w?��ӭL���=�T&�9���5�.s�)1�6�|w���E����;�wڮ�頒�k(�d���*�v���u4r�����e�m̰;;KZ_�^���-f�ҥ[�@�Z��M�m�{D��4���DAךsD7Rx�G[6j{?.�WJ -q�2������RZ�y9�@y�*+�ٖ&Ņ���A�2!M
Ny�Xp_q
�E�R.���8�ب�/���8����/�Bl��H��P��� l�Lu��0R^�!$��򃨲ϒ]Q�^�C��H��E�ѓM2�4L5m�U��9��1@�ł�m�����a5�LYPaqh����$S<��k�lD� \�������Y������F2$����/H�}'Z��|F�l��)�K^�*�[Q��,��`o�,;7�*�'�*�m�!�?c�a�<嘫�O\��J��$�kZ��Lk�1�I��'�8b�`�~ur��U��7�:/qXQ �õ4H� /��c��Z�����X4}�-+һ���h��E�����[�+ZI����'�JX��hأ"[L"��d�l��T��a;4��9����R��5lm+�jI-�mU��v0/�~���B�,���l+Z�)���
�uC�z�n���ǫ5�'���FЮ���O���0��	ߋ��p1��u���(��4�|��i��c�R}C�!PU"��������`�9;�U��M�a7�6ca^�ս?��y�z�Ұ�L�iL�g;�4B��s!87�:�ޥX�Ъ��������ٸ��]�䌆���r֗Ʊ�$FZ&Ms��f��'#�P,f7&��.���V����^��O��:~Xvh>hӱ�Ej�A[�	e�>G��@��1�p8�y�e�����Y������+ˆsD%n��P徑���:�@Ϝ�|
C�ߑbu�^ŋ�
)#��l����tsiã{E�P�<��_�i�,�	f�� ��3�Y��x�_�k ��,a8�\�A����
/Ȩ�קn��-.�(�I�"I�;%�VNR�����e�v9r�m�&�� V��7 -$���G�HU��@����D��jF��1V�":%B�K<zᒳfi7��������qtyIY����w�O��P��=�[;�����+ l����pa�J�f�/��2�_#��r��ږ 9��1ҳ�wRd��"_{7�0qʳ�Z5e��R�!~�[>���]�~T>焼k%�.���O� ��:t�>᫠8�V��JI�k�����=E+���V8=@%m��C���i�FV�Ka�1?���#���+VnK&&ǐ�-�\Ҟ���ML�����Lx�%�`gY�9tJnA�YN>6뜝Z��\���+��(����Rҗ%������k�:3{��Vk%d�Q������p��y�Լ�/V���Ϥ�sxF>��M����������eh�F'`��؄���݄'u���r�3� ��'8
s��Vh9� ML�S���,�����.��߳b�S��H�]9 ��rW��6�+�,wW�07���jR2�j��Z����.�E���o:�C>JT)d�+�^���������4�x"6h%   0}���R �����I���g�    YZ