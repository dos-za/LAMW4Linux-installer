#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2525715306"
MD5="41fb988faae30408c02b4217a0307c16"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20752"
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
	echo Date of packaging: Sun Jul 19 03:37:36 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j��k�}���F���j�n��S��:�c�~�^�22D^������	�'
�e��i?i���6�B{�S������`�k�U�bD	'��̡E���d�E��Rs��s�	�ɻ���J�KN��-BN/'�3l�@�	ԓ�s�OF�A|%h�t��3`1EI��k[{�;�/ �QC$E��66sbB$7 �v�bU]s�Lǧ?`���^�,�� ��R�E�R�=D�Z�=/bdX���[6�9~�Uq�u��w��T;�#>��q-8(�:���ʹ&�_M&������rʫb�=+x=�\&.���<9�W��Xڹ�y�H��*),F��J%"Y�������,�w��6Vv	�w1J/+���0/'�(Oy�\�by��pg5��h�qr̄Eذ��i
s�53�l�L�¤�%�]�[���Nb(@[�ݺ���PZ��<�9��5صl���2�]�r�> �e��:ܓ�,�D��SP/���J�J�wľe6�f�F>'��c1�J�j�z}��ݻ�[�_���	J��H��Z���x�^�"|�j6�s L���U��(��?L�[��Lҟ�����7�-ޜ �dȄ_=��U�nO��Ja�1w �<�����-�d�9r��_� �	�3~���.��нW�G��� l��n��un9b	?,���`Z�O&``㶎WX����2߁��OǯG{�t�*��Z���Ѕ��v�)v��Ӈ�?+�"��f )i*u!"f��!X�(���R�V�D�U�c�W!];��C~k^��P������d���G��S���zI��|�d*�J&��.�$Pin�L <m��خ(&���	M��/�5p�	Sq�osG�b�����89��._]������N�e�;`���Z%2�4�.��:�	q����CSd�=�K�W�]U������j�v2�roT#���O��fyb^���6�{�8�N��9���Y���(ny�
6����&oO�ʊ6)�-ǜ���SVā;4���Sx��qo�B��ܽ!�k���ڷ���> �s����e|<�� ���jvbS��t��$�~ ��ͱFZ��_K]�*.�Z}�~��ޛh9O�2�e�P�C	�	2n�#�����	���`̕���&hm}�gZ�>w��9ڪA⭵Y��\�]��KR��=�0f�>���(?�YY�#-Qbbi&ߡ=�	I�=r��c�Ȣ��b�pl[	i~�=��!f4]49�?v�7HF�ھ�a�� ���L@MW$?(��������D�?6H�R���J�ל�_�06��ZpӰ5;Ѝ��z�=��A(EZw�.M�a��㓪EG�L����'#)���,�jtd�;���_�]3�ʮt�y�45�,�ԇ�E]�t��E�ti��`!�T��V~�f�� MM�t}m�Y��l�)�u
G^��Q���@���u��[QU*�\�p>��lBG��f���4��=�[
?��ݾqm0��u�ܤA���d��0c���.��������4޸����utj@J/�L�I��*�a/^6��{�����X��A;��e8����i?l�4ה�
Ƿ�p0�l��1�}qb��ܹ�N*޲�z*=KJ&�&�Ž�G�9���D1Z����ؿA�G��_2ȸí�T�#x�7������8��)iR�*�G�+�>��.�4t�h���%d����V�Q41�-.�@�m#�&!�Ci�zYH���ׇ{�եo��OT�m@�"�E�r�&�q���Iq�N�@2��r�Ɔ��7��ACi.����0�cW&�ep�u���R�6Gj~z�&�]���|��Wc����@�mW���<~��M�;SB��s������'!�D����ZإK2~RGw���͘��Pp�l�D#�K��a�����V7�~�Qm�~����Ey8<V�ψ5�1|t�wk۾O7��+�"⥻�x����NP�7N�	�r�
Vi����t8���[�鯓�ڱ���I�]��GGq�.�7�ӭ��w�^)mQ��� dT;0����W"O��=�͊��5vn�:�څ�5E�9�y���a�Q��Ӓ���K�<��J���-^������In,���S�x����<(t"ZF �ߧ���jT�+v� �'KnNv��5O����w�r�' V�`M�m���[y��ӿ�˗8��z��/��	ߡH%'{�Ӧdt7��m�a�Pژ4��I����p�Z��
�Nl������̤��V[Ԡ�l�����(�P�BQ��1��@J��ݎ��[r+��>f6��
]:r�Ӻ��1����7�` n%֎Yw~}Rz�����6�5��Ru�8����^�ꏜ�`���Z�K��.+Wf��E�!Ã#4�J%�2Zx��f�	K�6<=<Y'O�HIӔ��"��$���BḀ4�)���@<z���c=AX�@��z�;s0��ʏ�CӞe�%�^zň�C4��xk�(/�m{W.0�C�_���͂�Υ�8��hC0<[(�;��E���y��7�qP9����a����yѵtRPX�n@d�&7�|�ta���	��d��7�f���sr
�ȫ&�}fԗ��-��j�Up�i��X�0�0���-�M�}���������9��v6����$z"u��l��+�D���Tx?��G]�̐T��gc�&�1�y�JJf��U�]{,\���\����j"��֫%),W��k�^���Z�q��t��w��]a��@>3�0�B4����@��(�ɀ},|?H����.�$���sT�,&&q�#����$Ɨ��ܥ�f���ߋ�)�i�v9�n��dm�%L�j��/+�;�T�xx�8�fFj[������
�/|WUē�h8��DH;A۝a��y<���U���l���O+��~�������'�Q��Η��%j�b!��|�S�haD�Z��$��픩�����w]ٳ�۰ղ����L�@ۿ�{��T,�""*{�@�l��Bi ���˜���	���uL�;b�I�:_�Cs����eN�5����\L��Ϫ�?��yh������lL� ,�Y#�C���_Q~p�|F挡:`�7z�Y"p��~A��ߛY�����6��;nQ	����CC?�'�0[}Q^d�q��62�8c����<����5ߓ�;1��O��ԓ���C�	�dl�mܞN�z-'3i�z�YTw��� �-�)�ܽ�%�)jx�c0�N��*�nG�͟a����.Ny�(j��c��)7n�mݔ1!fJ �c�3C��ם���T��v��`�5+k�e�B�?!I�5�ak����Y���D����|f�+�v�ڳe��*�4�w�z��-s+dў���(!�=+�9��ޫ������`���0�3�36c����奣�J�Ta�t�C���Fy��~�U��"�����/y��JG����ߺk*=�84�8��DX���I��2@�����Ő����t�;Lۚ����eĂ�I�j����ſ�̛��;ΨǙӷ�J�/៚�d	�O��^A���kM�=���L-+�2����j�V6��pG@������ �Y���OݧiAE�$刡���Y��Z2�xv���ܻɟ�=����[G-�l)���p�BQ�4��&�y�E��Bp��T\�j��� U��z��[����p5��s��I��	����o�����x�����b��ܚ�T�������xgВ'3���s�9�`��
Ϯ]��l�������*�4&,���r&a�!��=X���Q��b�R�)>��Q�(�gyolC��G�%B��F'����fO� ���������`[&<ޚ�C.i>����8ʘ�O��E��Yg�������pV�=�=�D�p,�?��ḟ^�%�ir��`��6�I�*q�(�A)/�6���d}�<�u�o�3����Qo�� w-�c�w��
A���v�c��c�w��5���/ߪ%��h�c���_J�d����������=��-��ڵ����od�;�,I�2��z�	�j�E&���	�e�!����\�=�7�T�oł盠��7��[�C�����  ^>}O�\|�<�I�vN�@6�\ܜc�y��`�-m��w�7������	���V��T �gkp�Ђ�7�mS����}��`���Ƶ�Y$�{tC��*зQ��8Jl�
�;�fۼ ���H�xCIP�	J�_+��7f�1L�*����fkf,�1�bϝ ��+m��(��i9��S��A^_od(҆��̒������O����=�2��1�����b�~�G)�{����2����NQ)w���[�%��Jv��e��vr�=�Y���T��Fr����b��?���m%��"�WDSkP" 9g
U�bB������e�1�tK��B��h!��s��<NAE����CZ͈^����!����]��H��p�
�	(���~�N�p�c'��Z����Yٕnh�F�
�x7�k���F��y�OՉ���m�L����Y��v�E�ʝR�**��KQ>�5(�&'��ݫX��Dl��M_�Mq�O��B�i���(�-�������_��d�Ԗl�6a�}��tJ��������t�,H��<°	�WCB5�6�zf��kB?>R���xӓ��$��],^�m�z�9�m�Fg~�s��� mB�B��b>�������LUPP$:<p��%����Ъ_�-��~��({�e2��^4Sm�Šی��J���e���\�E������6���<A-O�e�M�P���p���?�sș�\i�Mn�Tv��(�뢟vE�����ʮ�t��l�@���k��}7��GOrw����U ��=׸�V�Ub���d����H�C���ħC�y��h����~.���o�� =~�%�488Q�5�FDm�ǯ�ٓUK�N���2߰xDP�g9�]�{�p�3�W!��)�f[�k����~�(��F�Md�7�;� 9ha%})�1�7���Q����x���w�l*��3@aX?Ĩ�m�*�Y��z��o�+AO�h���ԎCh����Cf�v�t����Rg����m��:g*�&������j����05Gq8�}��z���{�\.<�'#���eS���(�:z�Z��9�-������:�id$U%���Ľ4�Qu� ?��?З1����5���6&��LLP�Vޟ��7t}l��W�`ZP��m��7d�g�91���tƲ3-5M�t��ߏݸ;�.u��Ͱ�v�\`�HZ��뀄9�g�]�d�,�yy���^ͯ��U~�I6��X|��%�b��FfW��Ѯ�+�-�?��I�$Z{�Se�_�������j�5�j�UcwU�T����9����ʔ����M�f�)�ʾ֫�K��Wգ�'_��-<��`�;�����f�`�g�Ý�Q__%�I-)e�$(��j����_��a��B
�$X��`"M�o`�dX��7�Lg9o���y�֒�d���4I�l�C�<bǍȏ�ax��m���xN��=�kf�F��o|��,\Um�Z���!�B$��B"���W@E�(�
b�ж�+�g�v>o�wj(�j��y2LcH��	��Y����z�w�$v�f�<�,T�Ϙ^	N1�ݏ�a�bA?�	�>6��hܮ����dC�M]�(�lIQ�!�����7���F�����cº& C���X7�jt>��K�j"Q/��A�x�����>���1�W��6��[�5O���r�g*��^��^I�?	�޻ �bMZ 3�/+�>�
��}��JdϑR��Ɩ�_���P�ϳ�b�X�8ӿ�P��_D^1$�8i��]��߻X�g���2�j� ʉ, ������ύ��BA��.�O�����<_���N�Rٯ�w�t�7.k� X<���FjJ��ӑ�o���!^IqZ�f��7������?�.a��|�.7�k�+l]�Kf\Id���7���_��d�����[.n�	e��8���˺��ŋ�D�#��R���H_�L�P��3.��d�"C� ���5|5�W7>��@5{�zc������y(	
���'�U�Dc&#��b��0����) ���>��� znuH���I��g�N��~=��OxrǢP����E��8�'6i�Y��+X���fzh��|����Ӭ�.�텋�4C���]_��Zg�_����t���A� �W���o|*��+��_�^�i�Ȅm3S����=%�B�$:�\0��B����0��� ��j$.��o2b���Z^I�ӿ�sV:��\)�3���.O���G�w$�����J��E�����3w��,���"g~ 0~�/��U�������,G�vq8�CI��s��o�6�_^'7fF���㈢2f������"�ĴC��4�`sV�x�i]�]�a�@��;އ�^v�
(�l�J��1���ȭ�e��3E���=�_�����
��<��0)_�c�r�Z��>&�N:&���ق�_P���AD��&W~*��%.1��n.K�f�W'ASxf�i�8���A!�4X��%~����0T��W���`?��]��3�^O�	��J}���[��j|<{�s�V��)��;j먰�����K���'k�p���͍��C!P�@e{��<�0C1�T]��7[� �R#���R�zÞO���{A�ҹ5���S��{�F�r��hȤd�����5��,J�ə�J��v���J<�4&��9�)��H0<T�
{�v��c���.�%�T	b:sw�9�z1�X6�0c� �,=�T�6�gq����b��� �$TWHj?1�aiZU��=T�Nel|6�R)�j��]/lK0�c�ތ�MĮ2�[��J��T���blq:�oy�4Tͽ�)��Qb�m��yxUd�)���2~�
��q �]"�KȔ@���ԕ=f �0�f��u��e�6�
)��r������R��W��%6���x�Qz�h-��R��-7:p��-��5��`�nMPTEZ��+Q�}���\¸�p��� �Ǧl �����Fᘵ�]޿��q�v�S{��2yF[8P��St�I̘�>�d���_M�>�)�^�CBs�r(���!��q�O��O%����R�_��[�Y�\Ͽr�pbɸ�i��?�Nn�ʫ��Y����w,�zԑ<X��w���搼��9����Z��Eԫ�C8)y�t��m��#K�9�|���1�,&�p�4O�Z��$������4���S��'O�}�^]���W�j���;�^k�E��&�+���T	p�.�2f�:Mo�PǓ��12�|+�F9�M)�6<MvU��5��W�]����K�,:��ԡ�����q���=^�u ��qI脀 &(�`䔁h�*���t6 e9��yqޓP�̚��� ��4��d��?i����������Q"`�&���e�1�lrNvʸ����H��6�>�X�	Y]����%f��:ϼ�C���Jj�6��|錶}����#�������:�u�6�&�@mp֭��L�ޥa#�hɊ���:����͋����R�ݢ� ��|V��p���q��%�}:EņȖ��g7}*�G�Vf�*�&vэ댰fA N܂b�'=/������±��]������+P8Ѧ[+7��L�5���/��F����	8^H�1���>���݅��>$�S>B-&x�SwͅV�#�r����Q�!���Q���msX�GR�6�����a�cr2���0��������[���}��DY�gP�,�d8���y?����t��c���\DB���V$��rg��OW��M�@�,r� ZН��;d�lJ�8J����1�_dd]��5Av�R,1����T8�u�lb����+�J5#յ��e��r�#��<K�ھ,�?�R�qR!����Q]S�K>a�<6��*}E������e����UH����|�6����-R�Q�5&��Xz`@���� q�K�*{y���mY��O�}�^���;��ܻ�q����Z ��|�~q(Wj��,i�E��er���>���I�D�agX!Z!��8�QLt�!R gUk`�}���&(�ѧWM�������1�2�W����pxV��x��I�|[4��M-U��}[�b��$[�w�N'O�{�T7u�~�&�>�M�F,@�02�!S��%�Y�}�c�m��}�M����9�����h�z����kw$����0�&�L�b�����v�F��vk�N�#�B�����F*���TC��oeX/Ӌ�C�K������^��42��5�u�9�b1�O��w[r�jNf�y�S$:��2�j�Uo���m��I�^�z8AJHb�����w%]H�N	]���[�����}<��/'���f������?_y<kC�Ty�l	���������4Ee�W�!W����ŏ{	��>�4�Z�O��CR��z�������W�y��n:O�t�����R4->�F�����н�si�~@W|@�����3��<Ϝ�)ָM���.��?��Wd+#�M�d�Z�&����{��c��;	��_���L�?bF��}����[��N:�͍�d�݂�3�o@�^Z���'�"��D#t�5涖�Hʸ����0(�M]�=+�#�Q؆0"��oF�f��u�ǀ������}\����m��j���e�X�*���<�Y��ybe����"�#�w{1�B\���s�$�,d�g�����\���S��>�Z�O�V�5>���T�2�J�E��غo�� ���q_�]ϒ־I���d�hz������2m-��o�_o�L�PS���h&��+�d�RdZЫ��$$�^�޲)y�W���܊�?�$ԧL�W�8�u|D7�l�����u�q|�i��Զ�u�~)<nI!��~ {�AL腐��A���u�&��)��f���sM|�KS}(	��#��x"|o�F.Q��N��G� w{gJ烹c��?G�k�5�l V[���������#���y�UB�WL�����<:�kDN�2Ԝ�:^<��Ӻ�ƄKR렌�F5S�_�q�ly��U��)R�������z��Hh;����,R O1O\���ӏ��ͪU������0c�1�$�ȸn���,$<�B�Z���Ů��ߞ�4�o1v����Iy+ّ�V��*���Q�� ��+kU�MM����H'��r�Z�0���}�
�q��
4�ec>$�M��*q/y���9��vw$��?������^��C���_�*!�.V�f��,��W�	��[���U�Nn�F�YZ��������'o�>����� [rs(�U��r���w@ʟ �*����M=.v�Mǿ4������fx�@`���`�K#e��J�eo9+��${B���c��F��"�
�7�w���\�Udr��_��lB7�Њ��01�pt�nS�yҤ�9�ކ��v���8g�P���l?��@�Έ��p�B�A�����a�|,at28l+rh ��\l����ug�ۚ�/s��HFzsnЍhw�f�� ��v3���ݰ�V�KfiAi����
`��i���:g��Z��O�\����+z�"����'���*t��AE�IJ���K:=�V	p��"�Bm{M��(Uu�X���*|D����sw�_.R�K�����IV�R�N�/�9���&����Ԇj��F�Cczǖ�u'�n{ �9�>���Gگ{A
Q�3�䳏�Ӿ�����۾���nJ�GSR_���l�x��%�>	��oGhxϬL9�2�Q�6��(Xx[�2Z�t?�Y^eb��ə���S�9XR؃ht~��j��'"���jA�++!k�u�ꝅP���H�Ob6��U��u�n�Z0��@������Z4�`oQ���W�X�7�=��wߑ�O�&r��{{ֳ�B���'��{A��.C5T��>A�(o�N�~��j:�>ܶ4�g7s#���sP�ârk2�W�S�����ho�Z0�/5���yP����9Ҍ�����y�
�w�㩹��ZG�2��Ml�Wu9l�EwA��P��:~�O=4Η�g�t6N�!.����\Ad��jb��h,�u�;�<+��]��rdF6�c��?�L�6US5��L>�_r�����pª��}���4��`�.A�t#[�Xo����Y���p�9�i]�[�)4Ks7�J�xT]��<�mSe�Z@�#�4Xss3���'ҭpŋS��ڠm٨�"�,��<�n�GQ������\��Bk+2�P��Y��E�-�Ʈm��mf��}W9�Z)��<?W��"M��nѴFzX��qJ��Ak�F���� ����y���4lX���
��O�e,��\p8�����R���M��ĳ�|�@���IlVk��H��H�йTXx�`��e͙3hx�	�i�vd7�.(q%4�.�Լ�5t%�0{�ԇz�����#�
�zv��Ok�Qy�s�I�꣚�]O/MC��� {��'�׆o�v�2�PO��'i� �a/����"�}^�K��iGb���d�c��	��QĎů�8L5:�ة	Z��1�m�D�oؙ�@z;XpDт ��f�0Kf�`�,��/�!<cpӿ֮����m�Kk�C�њ	��}:�fG��q�BC���Q��Щ"%���5U��_��~���2Bm�8bC�+�j�x-~�u�	�F+�si�����1��׎{����8���Z����Hl��H��X`��مDÌ(s�~����U��|��e),����uk�!���O�=d#w�A'xO|ے3e�|���T�KWw��xA�,3@��Z�a�����X����im�p��t/n����2�.���P��):է)�͖�cE����YR�.g��q�Z����.<���"u?�M�MG��Npx9?!oW�Nw��"⃇�`�,��*���:ܵ��4�#�>�C����2�/�;�y�����'qj1��K�����#��e8^Z�����������������J�Hz��w���U�`�A��v6z�m؊��m���k��Pƾ����t�5M�d�2��8s� ��/:����9�~�+��%�|�~55��ؖ1|�H���l�N�An���Kz ��~=�a�ZTn��s2{��'`��U��3P�V�\\��a]��*��и7�^��$׈��-y�Y���jK415ڨ�+�~�,u�:���&z����S@r2�:�������=o��2��8��הњ��ب~K�¸2*_�w����$�v�-�J>zI5�^e�ܩ鮸w�(c�F�'�{b}q%��_Y���-��Ú��3\k��y��֐R;}ia��K6q���Zx�}R(�TX�Q]�
�oD��8��M�F]�� Թ�h��H_/��"t�rVA�yj�o����qg˃�S/�U��h�1�������#׮�bHG��Lҫ�D|-�iU��m��x���96���E���8�h�'3��d�
M��{NS��a�/�ٞd��k1Z�A*Zd~��Vg��܇�~�NI�lf���۾�H��xn����
��٨^��g����
7eǟ�Z����F�a��0�v��\�Q>�1���y褁R0�.� �ࢥ���{�.�V3�}t����
 ���-^˰@�l�f���	��am��� �X❸���O4���/$ | ���C��D�ť
��%���"���1�g-�H�1'�{���`����<��S�C�=z�����
���{P����n>n�W]��ÊWmh�c�b4F��;�U�l�bO�';�B_�<7�b�9������+��#�bh� ���5�v���S��Gl[��UC��:���?���"��r�e��R 4�X�ݮ��Mϛx�2ͧ;�.ڿ�}H.�I�Lʭ�ֽK�Zv�K-��a�`�Oʐ����H.J���L�7��(�݈GY�����c��֦�
sp�9�(8���W�f3�l��������9j�MUU��ӑV�ۍ2_i$M������ń���O2�"�]w
>�B�=d��Bu��~MC%�D����#�E�:59S8Nŀ!��K�${l"��H��M���,�H<�Щ@,C�����Z@0�5cG����R�b�v�Z�d�����Li�6E
� �q��gȬ[ ������,�q�6���.$�/�[>�"!����1��ٯ|�ƥ�~}`�`Q|/�����2s����[��U�Å^,5Y؈���7@ATƄn��!�t@��
M[������>L���;��-�j�3L��$[�5D�%'9�dj�M�����T[X���ɤu�
� �Fj{�Ȓ4��IS+
\���[hA����1L(�G����0j�E���}�q���O)���3�h�$�S�+���K����>�S�ni�	0����y͚�.&b����u��+���
�R�a��J+B��	�h�NYx�j����(&4<��h���Ϻ*Yֺ�r~�����rz�g ߗ/��RZ�)��8�����$
}\R��Hs,B�U9��|�6�<-�3Q?J�q��L=Q7i�?����:U�s�}����Od�Q'"5�7x
�
˃�T���Y�p@�{B�*\��^i�6��uvЭ�*���#�Y�R�iۻ΋x�^��l�Z��#N���+s��Z�T���ؚ����c��oY�	�.~3��N��?M��^.�n�e+�д���U��/4tb���6}���1�B�.���1�ަ`��0�F7�wh���V5J���"�bY�M��ԕr�>*˦���=tYǏ�I {�[<T5J�u���T���;pP�e]����~,�ل!�E�,駍���{�E!�9�}9e��NC�Y�-m鷤�"h�y���֮�����Iq�ZO*f�8�P��8[gř%F���S���-:��x�Z�`��S�M�#��4�� n'�0�v�+	�>��A�\I��B"��Ez��a"��-���P�XųB�B�\�D����`L�jm���W�zr�"�(�=x�{Ĳ`�ώ(����˛�<��� ���W�t��ˍ>=�T�:�Y4���Y>��V��T���$��(��,ॏ��쫷�S�k�[�|���U
9���h�n�̷d>�Uake�~eӦ�b��]%/�R��@��/g���x�um9d(5�F\�n�-�!�D�x���zo���AB]�!�y�I�<�[�ˆ���P�Jn��� �)U���7�7�q��IeK���a�<d/p��[���kB5���E91����wܸ���3�.>�Xji�n僺wh��mJ��\�xSz�$��Og/զ����y:8/%Cl��;����~���єQ
��J+�)��>�������x��t���^)6 ����2!��
����S�K�=�%��o&M4���=�^�Ol��P�nކ[�+����c��>��o
C����]�B�5��<�_Qw�S���F��cF�_��Z�q�[�w�N�n/�������Vp3�`?����Ԕ�?7�lyT0 ���SBO�_�V=�� ����s	Q�Z�%ΰ�4��ܔ�����S6���rsiu����h頠�Dۭ�T[�'�C���r� �k�(kB:gL���{��e�b�w^��ʅ�7�BǨ�����~��a�����eup�L�n�
�I��EZ��>-�����ڐO���&,'&��yP>��\����W�,���)jd¹Oe������[�S<�E�����ы����F,����-ADa�[ ���d�)Y�C�9R%�v��
d�x6��'���PT�ݙ׸U�eq�l�O���",0,���HO쑻aa�'6�����o<��:s{�V�|N��\�{:���j�2}lV8��W�6���E�a�p^����)�K���x��b�_C���]^���4�$7p�8�$
��w��|�D*SL��d&$n�&c4DW���;-�_����?���?��Dj�G��n[��aC:NL���vn�;�S�)�F@���8 ���"���<�69��~߄%.]��J��|�	��%q�G�=�_e���9��t��uF�VéJs;�R��Q�ӕ�;Ga��c�FF�xOF������,!��	=*GRnvk;*���PGSz�����떙(LD���!V8�۞wId5+Nq"w�T�k����M�K�ƅP�LD�Ͼ�X�G�ˆ�%�&c/�R�8 �Q�k��\Gus�hI��N$�ޞ���ҿ�Y
���3�������FvN='���R��
��|�~m1s�{gɾ�a�~K~s��帼� �/��1��Z(�q����x�,H�(I��С>RI/�E�3��\���8/�ԅ�p�؂��j��v\�C����s��c�ne�8{�` �l9$n)8�e�m�6�s��[˸��4�S�n�K��opz�Mrb�[�N\��(D������o���PCM������u+q:���i��pa ��Jͳ�PAEj�
�o�!�Ύ�m�3�]"��C�9x{�)����8��/�z�Q2��Cz�j1H�P�=�{\^� ��\��%C�ar����Lc�͵�[v��؏3����<Y%z#�?"{)�ǋA�ō��%f�g��������HTD��{;����w�X�}l��k�no6�2�S �:�Ǻ@Y=ȱ倰!�&�bG���zT����۝��"
�����Ѵ�MN�u��S�s@8P\b��B�*^�(.c��T�9�@5�\�RJ�ҫ1��������h	�$I&�r�V�ͫPJ�	g7�|��T�hrx�T�f�~�_$�F�q����̾�����F�v�Fj>ͣS��Z[G=����r����'����[z���w�5R���
�J2,�7��	��hP��:~�����{���D����^��m�!�}T�`5,ăeY�%b!+ ��v2��U�2�H�4�m?�oD9Ô��P6�X�>V7�y���:)i����q?s�-���9/���;c���������;խ�5jM��HH:��> �s�#VX����JÉ�҄]Jf�-��!�	�&U�^\bf��F��pˑ�!�P�D��5�s}`n��V�VI`Z1������C�q(I��o����o�l�y{��p���B$&�-���K���6z��̬^���_���4r�whO>�����-d��8��1Bi��m�0`�B��r~ ?�w6�0���6��J��;��aZKR�
4$��УY�����֫��Vj#��*~xX}6���W�+��sLF�UO��ȢĮ��T�|�(�?�wo2�$���xGp,x�d�f�����6�?^۸�=E;�]��H�۫��0X�*�-yFR�a>;�jlw��\oN���U%D�@=�������u�Ow��FaW�G?��f���F���I咫��3M޳z7TvݠA�ؖmP^��&�����rIzG�]Ow�@�)Y�o"%�]���l��#<u�� �I]�&nREl�f�Ү%,�k�� ����}��<o�O	)��|�cٰ���`?oy�@���Z\��^�����o��l��RxF�d����GDx���ة�{7Zk�V\�Bkp%����99F+�����4�$�x�R/;)O^�-d��j��&hdf7�6Y�\��Yn+�0��ڋI��N${�7��YPh.
M�ʘD�4��Ep��?���R���\������vTɿr�L�~bIK���o���2�YRu6�2�!3��e��C$��٬�GɊL��ˎ�e�6eW�����Z�ڍ��G��=����NJy�Ŷ$�Qt0.o|���`S@+jI�٢;uV�u̷@V�H��<'��� 5���]m��%�`~�w�M�\��t
�� 9g���nO�rȰp�Y���]>ާmLT�&��aºY�q��(M�oJg: �!6���o��s�: rĢ�Π���#D���V�P%�%����QL�HOǣ��~f�i�>y`e�N4������u:�8����Z�zp1S8MP��.ұ�@�a�E��X���˽�X��������C�=�N�.��צ�î�l���5
ӝ�zLc.�������%�T}��@Y�37�c�.~���ȍ8DrQM8�he�zq8��hƻW�ش�l�p�`�n���%l���Kբ�('x�$���R׆WI�Bd�R�� �?�(Tl��|�jj��&��DD�h���Sn��S�`A�xq�A��x�cn5*�t��'��D�:~a��hL-��D�����$���N��:�D����rA��Inx<�9L8��g-�v�}�	������]����N�t�Z%Y\��Ȥ��Gc��{�����Vs$�N0�����X]���IQb�����/��� ���D��rk`Խ��S���(Cޫ�����9�hjjk�N�^D'��Uv���l!z��-,�
��nZf_R)�2���]`j8�q��bg��V�f^�0���1W�jwg�{Ǵ�UR���4@�0ojA��/8|��tj��D�l�I��G��q���8��<L
���E���� �l��-7���w���=ZA���t�����KnzIqL���bE��ap]����'��<�^���}��ؒ�4��c���s��Z�U��	�?�'�
�*�%�@�Gu���U�A{8���d�Q��&Ie��Z7�c�:�I'�L�X#H�N�Z��O)s�8~����}Ф��)1j�s�����Q������춡��s"h��;�:��m������iJ��3ۏ鉔<�k�y�O��Pٛjń���>$`�τ���@�J�����5r�my�]#]V���R�E��+�+ �.ɬ{\����	���F����1��T�Bɧp-��6��J;�_����T���7)OT�sMVi^�SG���Q�Bw��NGŌ�)Z��Q�HP�BLS�P�m�F �����(y����Ą��+ۯ�#��0
�zz��H�����f�����I��M��uj�*��ނ����s8���'���,bޏ�%#�Yll!�'M�S�wW���Fo��8tSP�R'E&Y�[���,֧�G�T��CɁ�
�)`c˿
��w~�3Q}�a�x�@�?P���O�g歉�Sp*��=�?������^�ƻ���u����t�ԃ6�%F���1gz��`*�̜��G�gEJ5���:sx���f�D���M�	6��a�@��)8)T*c�ܾ[��p���0���XQ�av�����2C�y��Q-���qs�sO4�P����3+��zE�e�tx�����gU/d�wg�X��p
p$�n�͐_S�6�toc~�㈮�9yg�w�7;5_����;�����(1WL�hT����݉��|w��Q��'���o��$����=��`���͹F��f���m��;�]F�TAGK��( ��\qW������w��R4��q��h @�����r��g����Aۨ�6|��ht$��af���n�1����,#�^�F�XY;@9�W��]CJlZba��{�ޯ��#I�&V�`�=��!�N�GϺ k������%�X���vz�6��eg�.�c��*�z�$����s>�W����������J%u���e�g_�-;9d 1N1��Ȭa�W�$��-rf��c���yܭ2���������5G-t-�5���Xj'�JT}N�$M�o�u[�6�%*����>:�f�OC��l�4�WӘ-]_.�`����7w��O�)K�J�������/ytx�S"v)��rÔ/Zx��v���B�aM�s�zXI`6R��g��\
%���QK{��ج�¬q�V�r1�w�@V�W�-����D���w��U�i���Ex��Ig#棔Z,%�$Hv�@��s�|(��J�5���X˪m)���#�|?��.O��y F6����H���������������/:����dZ��
.Wy�i�߮�d�aC�ǜ�.�Vc7��xe[?G�aMD���u�a�l�w%��NYh\U�K���0�ĳ�d�sf��;�:��~(������u\�^q*���F�ޙ�_ʽu�% &�Q��4u�.HX��S@,܆C�dۦ޾�W�>ҭ�����o�15�D2�B	�o;�n�����˸�`	T��q������a��&���8 �>@=|�)��0N\��WE��AZ'�P����1c�E�N��M��0���ZE��rI���g��W���"��V��I�%nҷ���x���
X�u�&�K���O�[(g؇����A�`��J�P�L�[gw�?�K|��nO٬5��x�dr|�`1Wv	)�Қ�Ҭ3�B,c^(�
�Q5[w.� !�y�& ���I/��A��4Ul/сC�\���t�����21�_��w4RP�k�7��6��S�"l0�d~�g��F�;j�>՛����,�-�K����V��B�� L틊'������a�O�Y�P�U�2 �W��E�@ids��i|��X}C*~}�����>�hh`����6�ҟ��/��qv�r�>��[��`sL�ٜ�;3.���� ����>�O~Kr�,1�!�F���- .{ѭ�dKv��ȡ�T���V�78�0i�i�퓂]m��K������ ' ����f5��_s��A��WX�&0D��h����i�^�{_�vy=1����R(�V2��7𒔿!5I�ה��(t�1P�>MED�+��G�;�_gY*��\8�J�j������˖E7禄ZW֍�K��z&:�x5љ6̞�@'c�*�k;h-�k��q��<4�|hy���N���	�k�ӄ��D���R�O�*0�н�Z�D�}�$UZ��Q�'���Ԯl���S�u����ǉ��Hl�S��Y��o�T�IQ��9q'=]���43���#QM޼V|hu�#���A�}�.:AS��ҏ`Al� ɇ͛.Ƒ�Fa{�Nn�Ӊ�q]�S{f�Xk�=(V(��Ֆg����I��z@o�VL4���Ͻ��J�#
-k�j&O���Dt�f�^/�@N��6�,�����H���\ڏ�I�S��t��{�$�����'��`j�B"�D��^����ղ�\�J��x��zZ,��wr�>��[��H������.W0�HA?�(�F��;��=046y���:�s: ���y�Lb�/=
h���b��|ƅ���%qSWѢ@��
 �[�$a���+�L���"�e�95�aBx�V�NV�Qs� *�,Q�����i��{�l��j�v��<Wb�M��ҟg����jw�nco]�#ߜԗ�E��@}�F.�
���e�5Z����|b��w�E��lQ��˺������(H'��������9Z�:}��wȇ�p�u\K\�{"�]9^ꯍ�"}�3q�o��D�yЈ��^'�q����*�4�s�v}�Ts-W�����%�!^L�q��|�٫��E��#Mr�X��W�������ڂ��1Mb�� Ti<�V����{S>vx���u1��_�F��h]�y: nh�t{�;஖���2NJ"�w��Þ�A~���?�+��]����a\3�������^�m���&ݖ�2;�
�0^|<�e��|���C`r�Vp�Nf��j�7�Mu ��Pd���=�s���
tg�S�&�9,J�(n{JB�f��S�3!O��=��&_ZO�C�2���c �KWA]�V�N�n�� ��*�qD&�� �cp��6j�T��eӦ/�R���my�3�8�uHϨ\����ਝ�s�:\}�n@ŗDL��)y3�%c~��Z� �1;��A!L���g�=�ަeNۺ����qGJŧ�дwy�_?
6����Y���ʫ�pM�S��n� ���m���9pP�����G�w�)ݎʃ:N����R?ص�%EĲ�{%o�Mox�s���ۉ�;'88w�O���^�9�O`�a��%!]5	1�jE����H${Ҫw���bL�?2�~�����,�
EN:�=mDT��~x�o1���N�&��Y��.�MH��o�aT5��^:p1�
M��'���m%�k���8W'�P®��ub�r�n+����=Wv���A��j]�L��8K�/����|��/��(?�W����q��_H)�m��t<~���;b܈���;$���j���Vw@�N SN�7f�H ���;�y��g�    YZ