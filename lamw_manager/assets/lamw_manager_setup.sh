#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3384685528"
MD5="f06aec75a2eac04867b99e20342c80d6"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20704"
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
	echo Date of packaging: Fri Jul 17 16:06:34 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j��}fMHV�V����#����e_��ev'NK
�-	�����vV~/!ɹ:#"~!�u/啼�f������2n��Y�Z�/>${��䋗)�6���:d��n��z�?0����� $������K%KL�E�����X�"�!�?��1�Ӵ��_�u�I,��2�N����q��UJ���G�0*�u$7.PϴB88�t�Ȝ�+~?�kA׎�d��}���2Tf;����j�a��C4�����¤O�R�Ьڈi,[�"�b�[����њ�5��s�}�,^󝂵kmW��m�����*�7k��|�ʐ��1��o?��b�)�夐�H���� L0|�;�v4�� ��%��pP���j��Oq�&�6ؤ���Bf\���Z�vi����b}۩n��#��F�� �i�k��/3[+�2���o�T�1�D@�4��+o�7�
�?E�Q]!A�R��h�9l���E#F?��! ��9(�S��a�p)ս�Y���NN�0�`�Y��q�-d�f���CO�Ȩpߴ�'������<���
���	ֆ�&W-�X�BK��
�pP�y����1�Z�h�ԿP�2����Vg׸uh�����Z��V�M�#p�|=2`��g�Y�3��to����7��2����?=���d�X:pψ�� `�U��ڤ� 3�*��O��b��6ը�'�" ֭P�3��~�j��k����̈́l#at#h�C��ӑ4��.���x�+�6C�k����W�������>>'<e5I�&�e �w>�9�o�H{=ku��U
�ȵ�挐��/����%���Ӄ��vR8!�=�O���=~A�KP�?�~�a�>�Yk�[��$�p�"���GӠ�/�T&�E�cvՑ�4�*�TSx�)B�G82��~�F�z>�_�7g|�� YRGn�im�YY������USEwJ�R��gr�lY�N�	iKhɯo��9\�ӀP���<��x瀓Z�<y_'����t�iˮ��C� �	�brAU�!y�<�[(�+IhB�S��$��е)�i<��t�`֠���J��4�H�ao5��Z����낆��s�V�^���g�ɸe�F��e�E��wG�*�ӭSG�F!���i?Oo�2	�샞��o�`�SS�JF�MR��u(M2���0� *��=(����#}�g�L)�Bi��㮩(P��;ݗ�����JX�qbD�1�&�.��Y�*:���U�]��꼥�F��B��$./ʦx,Vu���rJ� ����l�_T���;r�otm蘯�Vb�:?=���x�ɆE�&=�QΚD�	��Kr6I����<�S�ei���^l-T�ҏ�c}�O�C�muo'!�>��e�8D��L
|q<,yo���67]�q�XDGq2eo�*��7�¢3T���Te��-�BFs��#�eȃ=,bM�R/��rx��%�u I�7����0�=���@i�u������u�6��.���G<�#Vڗ��׃�����	E�]�H�㈌d��Je7����6j=�d�7�Aj�gdAD�ߍ�ukU��½v3�>O�.+�|I�Se1��U�>��0�f�bTE�WY�Gn�)��gϗ��/�&� ���A�#2[�E��^*E �P�`���r<DT�6�v4l�ʮ�X�	�����z�����������c��~��s���OY������Y��������T�;ϻ���%���ΧA�%�����jBQ-�f3�%8'/�����+�ܵ6UPjԩB/ىӏ2b[獭�8�Lt�R��g����	��8������q��w=Ȓf���lJ��0�����ņd�tX �M�D`�1UuS�̺R'$ ��~x��R9]�7���&!5�P�TY�좒��}�m��?�DM7�:���^�Am�A��3Lqu$��QC��S�O�igu�L�k�*U��2��E르���:ٗ9������7^[ڎ��J�d�V�>'�j��{���wŶu��G�c5(9r��^2ء6�L9#���f�=��&�U�WRAǃx���"T�E�{�w2���^�M��U7 :�+Y��{���F9Z�����R�z`Rܑ��xv�����X|�;p�#�1�É"1c}��wZ^���Lʰ��a�	������떡$=3
���[���QϬ�{���=8u�V�����+GG��N��L?Q��w��"<�F��$E�>���Tz(�;G�q/ߴ�{���2��@����Ƶ@~�f����N@��xl�'!>���l<�HO�܈�:b�!2�}:��@"x��B����Vo�wv	���	E�� ���������ʞm���7����彏��?*6��w���詹&�c���τZ5�΀y��
��b���
����]�mi>�纓��F�����w� �U�q��kB��W<�!�W��Uhw�-��N�:�*�g�q�W9��S��|Kp�y����g�E�<kn[�j�4�/_�9��#�ӓ)&�AV�m9~ ���F%I�SI,e��J_�nTҺ�����8Kw�����+\	m���O`{�K#��&"%�w{���������?i��6��l��IE��F��P'X��`�fG~��;Y|����C;�q���$΃;I�7ĕ"�hڏ�ȱ��)Ĭ[�&�E�_ U�{���)~4��^,j��ژgm���C�Ĺ��ҩ�R��A[���c������IF�8�R}1�a���[ԄJ:��o�P�Ѥx��~U��!�,�(�z-��A�p)�Td���T���h�����!��G�|�g<�=��>�.���?V��!2�`�ř�y��tG[p�t�k�����P�aMɔ���7�i`sM���6y�9�������Kd*t���b7AW�rF^��>V���;�1��{�?z�Gi��3;��ir�m����àh i%� ���I�I��BB�H�9�ꢊ��3�t�Ȇ�����p�Xo�`>��w�sJXOw%��$�,��i�F5��E��*t"�����Jߒ�E�ư|�aRj譟�v��/UwytLN���&+xw[����R���=�5���'H۽�[��Ҿ�8Ed��dH�YK����wq��V�uV35L��+�Ye�����Jw�g�4�G�t�20DM������	�5Iޜ����ih�d����j��7��ʹ�d��py-�)�P���o}䪱HY;�:�������̧`�IF�Z���
11��/hʹ��,a�n�	���|."�~Wؕ�3�\7k���IDWP�^۷��(�D�K�O�,�?����QO�:�]6�*�ȵ������6�S��t�$sw��k9X�o~��{`+��w�r�{-ސA�t,��Ҁ������Fx��ד�g��o	���´;�׿d ��y(C$��������B͎�e���-H��O�E�ꐹS@��A� ����d���稀7T2ֽN�	xY�u�������'��>bc ��s��y���u.>�FsT\��4�2*�]��]��#���T�l�5E���خ�s����B�" �Ee����+�\�lC�9bYq^��e>��Tm��Sз��*����B�(}�?I����Q�,gI��.�'h;�d����w�/Ӵ*Έm.��}�X�|�V��c�&�S�)1�2g���!M� X�V&�
ɴb��]���<z%��gԾy���͸XӒ�5싵��|�c-)���B9��b���+<�}[5�,V����F�ѽ{~�8�횰�Fr�&��������|I�X�0�1
�FJvW��¥��w������,4�4���{n�bQYB�h���'êx>7<<k�q8�d~��Fl4Xx��� 2[
��G-�=4tqޞۮOF��n �FӚ9��p|����E��R�(����`��؅�9����j�O�ng����I��r�5py>�Kbh��1���G�j��L�$�'�s6�Э�bg�ь�����b�Q�]��2]d�XYKC	�T@C�-u<xV����9D�. ��<~���C*��近tLoHw�i�a�$��|����=����k�a@)���L?��Q�Q��� B����<��2X`����S̫��&W�WZIS�3]�׼l/��yq��F1�ai�bXcRvv�XY:4i� EP�
��d����V�t�,IU��`��&	�C|R��#�#P�����T�F�>������$(Nc���}_���~ew���~���?s�l$�mo����<y�R�v~s|�uz�l������O�L��갖�yb�_K����#ﳲ,uL�>8�t���T̝��=�D�YF�Bo�al�Scfj5{����~w��z_]ߨ�J��6:�qM�
�����&�:Lc#��y֮�ɳg"Snmt���~�34�Q�JaŴ��)6k�8�.�W>�qTg�>�k�8*�O�;z?j�_Y���x�-�aQ�^/,W@*#άP�j�Y��攦��)"�����zh�}�F�����bW�ޯ�.���Wot�7��|�c����}���{�ݿ����.���q�)�v�Q(�a��+gURL�l��v��������[�
��C# ����oV���
��Rw���m�ا���,��D���:��.�Ex==�
@�VZ?y�V;F�|���[�����9=}.:�h��.Ç���:�PSo�Wl��n�'T�%����V=hU�:�yK�75�dN�6�(X�wH�K����dyk��q-oؤo�饅�6�D-m�p���0N�-�緮ָ�ȱ���T��8�w��청�L��F�E�/���
ǩ��q��q /�X��O��C(��E[�B�L[-�����߾�Yʄ�s�P�����\�j����8@�mD[�B�&m�T��i�g���±�����C
'�GJ{i@ЈuD6û]�r	�#�JE\�^��tc߹.��}�4A)-=2�ge"u��!#O������q�*�myt9�����xZi��o��A!=h�x^��x��*Ё`>� 0>D�Ij2�1:���?���ϙjɥw�]�|k�^2['��r8I�j&���l��,�S���[��Uy�˵����G��G��:E*і������ё��r�ɂX�M#����*A��b�s���A_s�g'��@��^A3m95G���C  �,�-�Y�ҿ>�@�"?�t�/��Yg�<�L|�����T=��*�����a�R��v ���i���E� ��x/ܔ{��4cM�3e4�fӼ� �=D��[�Hn񬺢ə�������U߅�H���7q!)�KÑ�j�
�~c#�Q���QBo ��n̌����Gk1O�B�U���:��/+paʘ$׶��tN:T:��D�B��0(�!���Y�ޖ���@���?'�?&#,��0�A������{�j+Mwl������T�<zb�A�
���Q\�ՠ�o}����@>�n�#B����9���0���bu�B�&Ā��+w��G#A<��ܸT�>�qkRm��'��*�S��;��d��\-��o�[ϩ�0���U�˧wD�n&'xϩE+_��Xሖ� ��>�ҕ%���/6_.�E� ���A�P�!��x�ci٠�{VPJ$3�}�JqpԢ�p�H���=pĉ�%2Q,&	`�`�O��|ӏk�r�`D �cp4��k�Qg�	U�w^O=�\�C� �?n#u\�G��� �y7K�A���/(�(2~B�r��<"��=�� �(����}��i��qO=]����w��,VtEL*
+��x-L��s3�#A'țOKOe�T����`��Лͩ�ד��q�/�����`2!s˰M8dŤ鶝'� G 5�E��^fY-=,Y14L>=�4�X�b�4�0RE�+�$��@RZg}[�ME�F�i����	�O�A���YUՋ_*�<��s��DRE��%!O��6(S6�!^����D"�_��Z4^�*���m𚴤H���ȉhuG�M�?�[R�(�)������	H�.��8>Aq����F��I��8�j�R�!w�O��]�o�E֕�A.G����_+>������E���7��W��͚�)O���dB��*ie��:K��\H��Z�y�8�|��x�[t�5~q_D�X�'�jv�4�|eD��&#o��ߪX�Hܧ�Z4�'����.�n�"ᳪy7�=�(c�lh<Y��e:l��1��\d�|�2C#-�~��U�%+�P���΂������滉e�2c����!�65m�R�2��%�Ҍ�Y]dM%�LJ�00���F�wm���A)��p%��f!���z���o���;�B��@A�b��	�$���UrϏ	/B"�A�{{Z�\8�>���O�X��S���iGX:��ҳ�.��P<+~DT��[H������2?Zx���I�ɮ h�c�EA�7^S�G3����@�V�r#N�u��J���j���d�~��l����n�Ψm^]B����Cso�0��Jq�y�!����^y@��xT)���� C:��+�/F�)��'�	Ǐ)$L�x`�=��W�lj��qX�p�����U�}��N�@�Zw��x3��.&@qvp�g�ʮe{1����[�呡F3�r����Q0r!4l�KZ������z���薠����pzI����VD*sX���<S�|�d��ۜ,$xj�Jݗy��ؾ�:�T
�v
W1��m�7A�1�7���'f]+N}ܽ��zf��#�.�\J���>l};���R����Q����B�"�H{���8�ޖ,�WM�s*�KK���f��̅D5XK�N?Am�'���*]u�C�3W���i�d����s���T!�ﱹc �P�J���SOp�]��%�h��X/~��N�P߼�N�4qK"�0���Cb���IS=a1�9�e9̂ރ��Y��
CV�X�(�?�ڌV�B��H�ϵ��f��64"��5A�>��&�I|DģhWp�wd��򈺧g��l�ՙ$���(��G�2f���ټ��`���ęL�_�Z��r2X}V�k2���3��ab�z5}����x&�"�){}?�8��s&A��ƥ���`��1=�GĔp�����v<v47�>�T��F/�� ���Tb,o���7�ļ< �}T������]����%-�`[Fk��6�ʳeyϰ�r��9�����p���tW�[���?����*��7�~FN�-,��ql�������	7h�|3�Z�_jl��D�ۉf�E��?{���V�_�.1,�2�}�|L�]$�y�/ϕ>��ͼZP��w��ᱽ7���!�z(�I���堎u��:������R�Qas����B����k*��L��&OŴ�2�h�hM58:���=�Aoq��ᢴ�ŕdx�0s`� �2s�}42Ⓘ�	5b	����q�{ˎs��A0��q�)�� !������/�φ���G^�b�7lׂ��v>���E1C*#6[Xf��u�=�8`QU~��fM�#��dMH�L�@i"���2�xd��pHE��[�D��Hd����?�f��}}ʣ�,�L�*"��v
֫8c�ļٱ~�,P�6��������=)��ص����-���o-�;�'�'�wCb#�2&l���h�Idt�'����  $��{7lH�M�gX��+?O_�Dw"D��_fd,�0:׆Rzֈ�C��.�mC ��a�+<g݋�*o/�y�3�=�<�ɪ ��ӗ�<{@;���?.oK�~��l�A�$o�EN���>�B.g�5�5?s䇯���v����GcM�����#l6 ����/G�T�(�c�Dׁ��g��BS�� }�/�C�1
F�����o+��(�Qw��{���59_�^�&O�V觱�|��z%ͦo��k�Y�N��c�ˆ�`�.75�u�ӿz����@w$<.s�h������@��$�/\ƿ# p[T@p+������T| ɮ[�#����=��#�o�ʙ��d��W��G�rWhɹu��=}�������L�������}��B�$g�#�h��S�������0�����OK�b����K���h��T�͚�����z]l��7�����vά��ϵ$,n��D��ԟCU�[�	�D�m��2]ыFf&��O��*�k'&s������!�=�y�� ��T�@�QTRr���%��V���ʺ��jU�Z���Fk۾�]�1����E�G�B嗢|��h��)�9�"�7VѶH�6`�U�̠֢�i�i�m�b�m�G$d�̸y/�3fp���-�ίW���0�0W?	������?�l#288��C_�g��bR0�?űYQ$ewl��h-x�@96_,�L�4wףW��F%�5�_u�08�8u�^�$���\֕c�iu(�������!h�&���ו�q��v����<��j��z��)��Wq�3�z�6��� L#�N���}�ރ� Z#�e��9�C?m�����-U"�"��D�K�J�{�G;|%h��i�V[�Ǖ �J�i�O����x~�W~�d= l{f����g��=a��p���[�KBe��{���0D�)�˔��]gN%�1*ݡ`�!� '
�����1����:�9���\~kO�S�s�A��?�M)v��н�&�ȶ����C�y���~a>,Ϡ4��*��凯JD&DW��%8 ���e���WY|�:3ʁg	���|�\�#ꖺmoD�efL1�&�ӖQ�JE��*}��?�F�z��=�=�z���8�?_ږֶ�KBL��{��>$
7�|��&���O�Q����{�9B��̈́A�6{�L�+g����>�]��]@.q���������`��n�~��]�a�����}����5�[@W�dY�}�F�.SM6?�߷_"�,��6�wQ>�28j ��~����Z�$�q��P+����R��R���g;ʲȴ�֓oY��w7Eh*ޛ��Y�=[4nY�8�#�ϕ�`�3ZzH�P�G/p_(ɚ�x
E���/�H�r<��Ҙ����v��h�^n����u���8w��4ss��Y��?�b���>��Q�]�]v��.�,���n��Ӧ?���0!V� �$�;�pS[�le�ˉ?�z>E�J>iC-�Uo!��	�=���ΐ�
�	3Q^���?��S f�&�B
lE�t0^6�m�0x�D���Fbio�.�+��D!�e{7# �HA��-/�Č,��Ҋ�As�_X�V!�T�vP=)	�~�r��A����XA���!�66����O��D��-�t�:�l�O�͘��2��O�!��y~��Py@�^�u.9ǝH+�������̇|��Y<�iO����m/�M���Y�f�x,���-�˝
V�+mz}�/4��*$��1���a���Bs�`�H��;R�y���h�V/:�L�eHW*�W�+k� $����0�F�<�S�nC�ݞ$��-�ϸ�~����bo���9fl(l���Ë܀W�/%��@p	�Ib?��r"��'u�A�G��$M �ws��I����Z�t�q@rj?��p' `I���K�����\��p�&��EKZ�3�.��Bf�E\;w�<�Q	�J��oE�� ��o���[dؗ��2Z|>��::sƝZcG���m��j�a5�
{�`���7��r��lDpR�c{��tҧ
en�!��R"��ġ�Xw^��Q<ba�L��W�D�,ȹ.�����y���t/yR�2C�s�e�7̜�
j����%��/c`C��-��?�H蔨dؚ�}��˽�P&��.2秋��m�5�����ߌ-�i���͞�?[�>I[OM�~<�+Xan��%�x����B>=����cp(��w����YN<�d�{�$k�Ŧ!�\}��)fޡִ<L�x3�N�ȋ+��.�6�	��Sʸ?��Z|#�pM����1P��>9&�^51�x��ќ)ݱ�I� ��
��jBv�J��@��e�̳�S��Yqa��g������<����ϣ\'���|l�Zޣ�L���E`��2����9r?,�h�u�X��]f�O������.���|[��yw�,~�P���z�1W��TЈ'��Ƃ�U���2����T��`~\�Ӊ�0�O�Cmq�E�I�g�N��I�������Mcp�*.7���U�DȁBf>�"��c�0����������(Ɩ�[���>�\���v,�0�|b��Ȝ%Ͷ6ٙD(�k���|��.�┭�G�r��NS� �a�g߈�v1o "=��q���p�oɾ	��"����l�E�U��/u3�*�`�g��@~�N_ <6�v��b�n����-�A;�$-9S(�4��q�/��p�
/��؍#���B.��\��Wg��<��W��1��*�&H�TkeHM�����iȈJ���䎸��m�����O驰F� ��%~�W��Y�����C.N��L٘�m����͵�8"q��"Oɹ��(�c23Xc��y>�?#;�\n@�ICC�[x���If�/6܏�@c��Nf��'���ZN�^qQ�z(#��o˹����~�]�g���gJs��#������q��T2#lR�@�y�������Z8c�3����㭘����9��P!���K�{�GN�i�tC����gX�vRA�9�������3�L�z!�? ���pתo���H�u�I���GRN�m�|7�Va�m#s>Hs�mj����e�ȯ��7��Y]5.az�xX:5:��:e���UG�>BM����X^�Xu\a\�Q�e��;5j:c�m�`�,����=гImw�Vc�`����Hz,% �FM����EG�*`��G5\&�U�l����N����qGXt9����;�0���%�
�3sk��� �ţu��&���l�ABC{r�C�;�)�o��PE'D��ɖQ���G!�~ȱ2�,��:����aHW�����6�̂0��
l����E�� �	C����G�b{���}m�g\V�3	��1K��&#����?xX����U>S��rK��S稬���4���I�Ǉ�����c�؆O�ĉPO����U*�F�8�e/��ó>�,�2�9�&E��v��K����EY֪OzƫDa䚿�s����%��1lT���n�A�:IQX&�˩��3���N���F�M��m�u�㦖��c.�P��񟋰J�R_�)�oh��b��.y�u�k�����c�ݾ�Ð��Ͽ��W:��5XL� ��3/ p)Ч�y�8����/%��_^H=JE�'��lK�WZF�ix`_�>F���\YE֙����f�ƿ?��&�u�QK'�X:@%,p�_j&�a �+ܙ�/Vn;�Q-�G�o��E��{OjK��Fj���e`��ʓrtf�+ݎ0��Xz�9T"�;N *�^+Y��R�ܑA�"��8K�,	��������Կ��#CÝMgfD�?.�_�s��t B)�Y�Y�&?t�J�E@V��}��k��Ȥd�!@�K���R4�j������?��Q�}�@7;��̮�� @����V���zېȜ"l��/�N��s^<<�v��PWu����LM�5���Ѫy�s�^��mo��$��4c��Qː�����SՎ���������]�{�d�C��� ܹ�XD�d$��ȱ�?��Fq2+NLe�������oS���w�u_l���DiB����<��n"�a���tgw�q�)rՖ]��3�)��8��ۚV��׳����6���K��))t�A�%M��R����ۏ�{M�kN9�o3nTLx��녀�!����Q��0&~-J�Ο��I�X;Q���6�5�������
�i)��σ5�8*�5Z�0M�����$���h-84Gՙ6��Rx�N���]�b:dz�ﷺԑN�u�dE1wS��I&ǰ���Y��� �(0�a�M�K��!C����A�Ýs"�ԅ�'�����>7V'�=mf���:�bB���8wou��,�99{���/����ve`&23E ��9��t�u�%Yy�6i݃�'�7�l� �~�p4\��[��(�Vh���t:�Y0�������H�="^┵)ܟ�06;����_�!���o�ln?(ϑ��H��#�j�"���'S;
9�M�\�J�A�7g!������=_W�g^�'k3o
p���xLs�.A����J�� 1T��������r@C[@f^N�R�y�"^?���$�%x�wA����`�1��� ��jR{�s���2�pڽ��uhy8�_M�i	q���^�U�KO�������XEX��tp���p�V
� u�/f7b*iW��l}ן�Y��lk[������X���sF̼�~zP�D^AS�z-j���T:A6�s%0��E�[,����g������8m�"_�D�I��6��(d�M�"�8{m���z#!in�u�%^	`�!'�Pt��B�i�eS;}r>��\W��E�˛���1�F�!6���&��D���a�t
X4�QV޺a����u��W=��Yp��-�7�^��fE]�4�!��;�<��B?I����^�l���9�W/a�{ݬ���,fg�~�y��lWl=�B�7�v@�8�,>�$ܐ�\�\|V�η.B��`��ۘǯiJ�a�fG�A�P����r�z�t���Ey�5"�#;��9�mS��/�kY%X��l��z�pM��І/��o�Bv��MW=��X��7�֏R�҄]�-4�⛋�����]$
0����}X�6�.��)������R�B9E��p8�%`�p��#����еckn�g�����?�6=%�#*�; �7��D�#���^]�` ��o���~;e���%� ��k���V���b=�D�(�Uߋ���3����?�)�H$Z'X!�A$!`�%`2y��YT�Z2��|���M�R��5(I�o���������Y[\�r�ù3�G�hn8��Ҙ����IN��sJ�=�)��)"����{����1����������2�"�kz�҄��{���hkEo���4��o���~�"ů�|���B�����q2/��i�}jPe�*Ƒ�z~����aut7$���F!X*���rGt&�"*+BO�{/�Ns��������R
8�`,g��O�WV�N����yn:I���dp�% �P�C����ڹw�͐���ݹ����Eؗ0ĩ��/�u�66��>��гO���Tv)�&�K�m�^\��� �K�;����Q[�u�T%Bj��ΐg��c�����!bKؑ��\M�yd0�i�g�l3�"E�ɸ�}.:��R�[,p�ϝrJ����,��7c�k��}��2@FN2H�-�xClK��!7.z�@�����z7�#�G�}�ZL܋�����k��qP�$@G�ۤ��m�쵹��	�p��[��F�*z���oO4Q������0�~+�cJ̫�չ��P �볭�i�^SC�`e$w*vK��*Z�́@�~�\�DJg���)y#F��"bG����oB��B`��v����T@+�Y��}��ԁ�l�Y~٣dh}�y	+I�0P2��]���ɗ��;��j�++${�(���i}KyZ/w5ꐞJ�u�,X����ª{7�n{�jؓ�9�.{&r�g��_9��qT��M>*����	A0�s:r��������K����ġ�cXѴFؐ�m�|":�1�!g������[��l�ֻ�"�U:k��h�-^��M(���Iw�͢��r�����:7�vuI~8��	x������6NtA�7�r矤�Ґ# �����R�
C)%G�>)�+������v/�r�����I���O�&�غ��nX�������!��WǶC��1mk�63�+�u��Mh<��g�7��kL���.EQ��;��-La4��.�!�ډ�8pWW�]�"5Dv�3��ݡL�f�U��V�L��~'��9U�+I{�׎�=���zB�5�Z��v�G�}:�0�a�5��7�x/I��#��tC�݀��(�JЉ��\��ļ��l�
�|}Q���>Űx{���;�%HtC�Z�����
�լ�4^��ֹ|-��.P�+�2C����&�q!~���yN�T����pıA(��_�B��+��j	��An�:��tT�TP����t]����z�U�"���9���w���t�[�5pd@�4��5�$ll�	�2�MGL�t�q���}��0�ӹ�!{7_��+V���!���7�tn�@,���M�"i��m�l�1�x�����w��0@$�`Jw>���m//��T~���j"Z>|��8�T�9�sҴ3W}Zj����	/����VfDr[ʛ�}�ߵ|/˔���Gx��rd_S���iI�j��A�{c[�N^��YD9����Cb����d!�e)��j��Ɣe��������j5����Pe۫���J1�՟x��y������Os�$x,_��<ͺKY4������㍈=F�
���v�?zZ�?"�N���Er�~�Hl��qQ�%��-۝[�Z�LY�s��a���T�?��l����/�c��Sp(�Y�
����K�z#0������3�?�m��Z�a�����9)cRy���z����ߔ���4.+�6ߡ�4�G zM�r-���6��m�P�`����J�^4���1������Mp�`jO��{�<ݫ�I(DR�3o�X���Z����h�R	�
t�cݗ����M�����Y7y��3�Fur�$��=x���ư�$���h�4߆��ƻ	�Os;nZ�M���~��'gH�?�Zpix����%T:��M�_&�QN����c�o��7�+�7rz�.D[
Tfj�]�k'�=�g������Ή���kJ�-���<�`��6Y��H�m)P�E�3b����Vd�;%�9�v^9v��%��Qw�V7�ܯ���s��P��.�Ԓ��� �'f�4�ٱQysIT�{ř[F�	��=:�_�7�[�}��}w�nu����v��'�=�Ԍ�]�����A�s��ʶ�IO�+퀗�z��ޛ�]��[��H�;x�����O�o���
}�"�f�0K�& �o� ����5`H�E�x�����0e���,_@LB�X����2��
�,��(*�g�0*��҇_#eO�j([��FW#J���D��eI�F��:�p�9g�Δ3���tGEwp����h�z�M-3�y�e(m
CX��on�eFCp�5d�mr*r4n����Z� ��:��i���.]z�����3v��K�P�}(ȹ�`�#3K�*ŜՈ�-�4�K�a�.b�Yۣfa��(��~kL�2�$&r8t�O�V��E��7�&�"�o�Sp�2�%���"E�ڪ;b���Z�<�4��u�x=\8r��n��I�cD�$cq�ҙ�9 �R>��� '���A�5�I��҄D��n�V��v���}��Loʾ�W�pUMxb�����l���j�Ml�`u�m�:KB��rD6��q�p:M �3=���?�zE8����Y��my�h�)����-#EL�3JVw�ӫ�[�)�&�"�����Fl�}ޑ�����#Q���v��(�'�q.�q���'w#!eʍX�C�߃�fT2�>�	ҽ���4��w(�F�X5X�k��)7[y��6\�L�7�B0�Sm0;�Ӌ0��
�8���h�5	�;ho���ȉʂ��0}O���/�_����"'E���!W�ݐg�/^��I�P�.�t;���U�4����I��:�C��pzi�01��y!�sD�2J;g���S8�U�n��sY8us�N:d

�a��	�&���a��E(�����-ӳ\�`&~�v'� ���k���%8Ҵ@MPr�-��m�hn|����}��/:`;����.Ko���!,��?O����b�,���=n����l�U�_�D��P�8���Ds(��\#��#q�4bk|����"U�9�<�۬(,��@�(�%%6:�ҭ�3_��+���9��Yc�f0~��1��q:_jB�����g�n��gMH0��� </���b	��3�gx���.��l�;�n�6ĝhĞ��)��N�� �n_�RC�\}�-�)�7���܎�������&�oC��Q"A߇̾|�h���m�uG���N�]��B[�qu���i*==ۖc�3>����=��`�7��&#���Z�߹,]�[����y	Gj��aY˯�YB��:��^���|Fy"Q�B�gbE8oj�.�Nj��#�y�P��Jy�ti��v�P^oJ	j?-�X�[j�*��Ys�bY}�-ׯ �D�_&��J��?�L�4󮙑�U�3֟�7J�bO���}��� Ȯ��ӛ2׆�:?��+q�_"��K�qM�pj�)qHM�A��g���˘��Ն�i�8K�E$ÓC����x�B�ZNr �f*���|��:�ٗW�a�黈�:\n'��ܰ�5���9�]�XL�	�P� A��c,;��]��6��Opb��cϏu��z}��Dx�r���x�pC��;�΂�zW8lb��yM���"1��[<%S�{��x�4,vӕ�)�'��� f]s�}�'��Q�$���,j>��sq�Sx����k|�I2-����!�m ���!�i�@V\G�$�.�/?[Kƿ
���9��Q�R�n�|<o�o/��FP�������[��lg���͝����BM�vI�i\��C.̏�]�����<�~����1�bcm�����R�p�����u�O�4�v�Vb7xˉ��5,�^ɼ�
"lDk���M-ũ���9�V+���azuN��^���{?�,�#��^Z}]�G�L�C�6��*���C�ڷ�u�$�\��x��s�����Om;�o
� ��N�2j�R��Z�ۤ6 <@$����T��r@�5��|&.�q(���|��ć9{���ׄ�S���055��|wb`��Y�2�ˤ����V�=��KWj�@�S������e`K�ԧC���O�h�F\Nըq"������c$d�P�n��?�.�?�-E���no�1%AH��!�^�H.-C\m��UAYs��8fOV0��K�"������V�7��WX�T���K���j����t�x�]��u	��Y��FI�2R�l���o��>鿯�r��"�C�~o/�QR�J�2�&>Ӳ�����0�9���3y��RY�]�r�p��*�c1af�2`���=7��]�X��)���uE܀��.��S�����xѫ�r$z��� �F�-�>�f�Jr�;�[�G�~&ύN��M�w�����|4�V���9��*�F���<�v��Ҳrz��xZX]f��نh�Ym`�U�I�_j����n�����V�o/a+�1���~f��/���;�,nヺ�h���<ge(��lx8���d�T��~d-�^_{;sY8�[��<��^��5*Oȕ�h��@~ɤ�٣�ޗ\)��@x�b��J-��.�f>3��GB��W�Q�]x�i�,7�ۍ((�l%&B���:��6j(OU�ϗ��}�f���JWP�[p�^���R}�{���Z-?VI���"*�����DMk�a�N��N�2��ǆ��F��t�&kV�[�)�i�B�d6Ly	vXLn����������������E�&��[U�
���לl���Ю3}��G?-�Z-�!�v㿾��B�Ӳ�ܑ�ؗ��z�E٩�XΝ��P�af�z��? ӿq�V<B���z�]%�&�B�RF����ł���2�∀b��܊�������c'��j6�f8YiѦ>�®�[kʗ@�#�T�;��^��I�'r��E���ra���<��'K-���؊�o��ө�Gk�������6��󔟹����{mmB��a��O:��U��3����l��鴶-VgI�i)yHG+ڬ��ƌ�CuD��1X̸$�� ���"�-\l���뭷"`�������h���*��`�3�K9�r��]�����J�]U��6y�"o�1d��~)��3���w�ˉ�C�v��G���3�Kf�7w`S_G���Zx`?3��ؒ2�R��ߑQ=:�:�^�%H?j���7����o�ph��\������T�#^�1��62�$�F��0���I3�l���dv��yD�����ĮUֈ@o��1��C��+���Z��.{k���f�j�wf�S�n��+�����x-�1X�9A���&�os�pc�q��ȡ�ã@����É��zbמ�Џ�о�K_�2�H,�,��^�)�)��g w��Ĕ%�7|j��\�u��J���/�~�8���p��7���rmT��x;�%�C=�n'c�ݾ������v�C�u�뼐q���J�B��2�}���q/pՎ��%�� ?�)���(�'C�hv�qh�(5{e��lV���0o���{�>$6�QP��G��.��
���2b�N~�uc}�y��0%3�a,��/I��硇uI�q`<.V���U1"Ð\��4�������ήQ���K
�Oܿ8��q͢G<ʳ@7�q`��s��7�^= ��Y 5wN��~`&�h)�Ŵ�GEK�D�0�)�'N9d�-�=k0(*�z6�S-�C�]�z��(���9�\��)�mM3H�����K�+K��a�[�h��'QOX�Y,�?��(V{�.3�~�<W�{�����ɏ��QV�:�T;�@�Y���"�d�Ѫ��Pl������r���a�p��P�ȣ/I�W����iSy�<�Ëʤ��E��sfyb�#.>�c��l����%�
�{�4EݜwW-)y�ѵZ�h�{�uC��kU��a�Qh沉��E5cemO�V8O�g��;�d	�����h�(<g^[ovɮ�gCenu��Ž��X��ӏyi��?��e���"!Zu�u*9xͭ�-�͟9�>y�N��������w՟��Kq��,>�Ai�Y�sZ�D�������iaYǊ�.�S�.h���:S�����ș�r�E:St��~�F�f)�S���^�
f��̲e��YÒ�c-��J�}E���&�-��@��z�2MN��e:�x����l6z�����w�i��ܼ:9-I��At��?.�Y�s�T��������2�壋|9����m��涠�w���ľ�����_Qw�$h"a+�e�����33OP�-��jX��`���R ��p<*J��S��)�CP%J.���end�~Xm*�JV��Լ@�fv����$��}�kW��(<gW�J�g�����n@�c��:���B�����I�[�Q�X8] GjA~�C���*�j0��7x@2�Q
��k��gO����	S���y����W2�4��^�?��{��/ii�l�E��kYo������M烩�����Ά�1�[���C���&I��h7;q�p.A���9~�_I�+Iz�e�@�q��+mk:�.��os��R��@�7F��0�����a��l��w���#�0�U�Wܛ�\	�6�Y��ER�G���a5����1��5"1�R�����;������5�F�P��L���J��>2��2�z�jV/�$�
����A6�o�7�Q�kaС����.�gpI3<¹��пC1���H�m�Y�OpL�LS��Ćھ؅��Co{����@}�J��3W�֟�xZ�F��.7�y���LD���=���X��^0�[>�w7�:�>�L������q�P�
��.	�S����g��H��K�&��^�l��^x����3'@ء�J����͡F�ɖ�+��G�8���j/�5�����</x�M��a|�۟����W�.�.�nS������=��`N�vx��!7���L�d�3��$_� �*�U�g���J�T�.{�ʫ��:�;}Z���z����kn�\`�(��P��/-wѪ��FG�� [�$S�Ão*��1
{��:v�3�$-����̯�i~�o�/���E-���׽�fL!����>����(ۇ�R����#Ǐ � 8��YLy�<P�C�ht�1L[�@O0�C����d������W�Z%C�׊3��z��C{�mmHP�RN<�=��j� ��=؜���/p~O��=�Hp2���L��{�a������BC?CJ�hy��OmcA��,�sӷ{@3�%�b%���i(E�\gk/���?ȥv�C���*�+�ms��eD�C2�F)A�2_�]۹�Q��;[A���5��^����p=>�E��i�b�k1��u��Wn3i-�/rc|��٧�[Hx蔟1����ǁ�o\��M����]����}s,�@he<�hC�_* )����('�khpvP�>>��e<�  ���y�X"W ����t����g�    YZ