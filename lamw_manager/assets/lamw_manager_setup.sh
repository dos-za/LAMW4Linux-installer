#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1985568614"
MD5="546e3f581f1b40e45f0f1e1020220b00"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20756"
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
	echo Date of packaging: Sun Jul 19 02:35:41 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j��~7�^}�T��U�TLg����d��"��P)��`)�%IvZ���JK 3�����f�+Н	�~��iLݳP�b��I�mq�f*׿��a�����n1�Gq�����I�b����
� �[F�8�J%m�If��=���{��dG�W|$,c�I�uzCg;�7@�Қ��	w)��`�eʚ��
�{%&l�^[�Q�M��F�ҭe 5f뼋��n|�$��zU�-�E �2��&2��d~t/��gqGҤ���_���I[�<jw�aj����Ă��)Y�����Ct�~�d�e҈�W9��CWJ���z����PWNIV��GQ)����GNm�
�i��+��2���@�r�3��mڑ~.yJ���}#��~%7��'$3��ᄌ���>��AY��<s�C/fL��F9�	{s�f��{ݧ\��nّ�@�� Hq��Y���U���?���d�~a���S�@| �i�u��\k�@"Q<�Yo�R#��ͺ��J��P<Q�3Ě�)a�Ȥ�zH�>�&<�[JOfpI��=�ͬDu4R��D����]����Pt��Y ?��г<+���V!S<���;�%;*#` L]���Ě�lJ?L�PD�J�G�s�#��
�q��N'���1����u�`$��[{��pk�T͙σ���:�-Q�
e���[r��{���6ߤp��V��Gf'0=���;�~�zKq��c����0%L���f͕:)���r�#ĥ���!֗V8K~�yR��
��̚U5}ƭ�hw��SO#�n�_�1%�f��9�ו�D�� D6�B_���M����jG,䲠m���'���$�ZSr��#��X4V��^��R����(h���C2���Z�o��ӆ�ohޕK��L����ob���`[v���{I�3�,�T;_W
�ʝT`�+�,��t����ө}{�
��F˖�߯xy(���� ����$���q#��T)�[r���3�ό�����K��SYRո��$���� ��A����:6L�4 a����
�D��whg\���xK�.��1|ww�*,
��B`^S�����I�2��`�)�+�����|�1���n'�L��s�6�����Ja�1���� xkr鯇u�����B��O�0��g��t�����N���c�=�i�b*a0���=�!p��e�SkF�n�6�.��7M>Hz��s'�Q���G4'n��}�Z �Q4�H��YW���������ՖwN7�������=klZ(�z����e��ϱ��E�hA�"�NY�sH�&O��[�v=�8�	�B�LL�`�9�p�R����z�R�����J0LK��Cn��k�G��b��Z�Ie{�*�&���R�J�h��OV7�!�c���2�Q����Q�-� qV$X4�:��Û&�R���I�)�� ��,V/����M7�<�}�of&2�}<)�2+8'�+y�Ut���!h��_TAEn#��N�h4
H��S��u������E"�����j�v����H�}�|�j�\��(Hg+x��m�>��W�_dh��goomm$��i�A�q����}=�j�ۇea?��"�|6����owa��E`����g�������;�(�@�:��"L�H�P�pPy�mL��3������"X!��%no���p�i4�}ʃl;�	���'�:N�!�������U�����턐�����w�^D&�*)&I9x�0:�Mw]��N����n�P��[`�s��S��V��n�b��M2��C���"��:"���1��,��F_��{I*𲉑#�{��U�h;�0�R}�"��hp b�!]���P'e;�;��jԼ����хK7���7��:��9_���k�R�������w�n�?:��ӗ��ΑS���8�_?�Y�ہ���Km�a�w��&��gx��G^�8*��ķ��T��9�v�ͫzqG�8;�g�(��sa�,��F	u��M���x3"�-�9�g�����ɛ���C|����2��	����S��ݪi�RǾ�P-Kx�,�WV?N��`���{�+�'�4\���E�ι��7q�5(r�XH�8�(�Y���6k1��8$_����-�?怋�yt5!��P�����wv����)���� �/,�����]�0E�:��F:���	"�?����0b+�E��&�5}`0{j�CP'a��J{�s�z��6�ɣ����s�
Z�󎞃��0?l�L��i*O�"$�g�jAB����Ξ�lAw4uv � '����A��)�%A��Jk1�u�����|��a����� ����y�8F�����%L��x������%�;�W�^^+����( ,���(���XT���n�#U��l4����<
߬�;Y�1,�p�l���OM=(��Fr6�ٗ����qaˈ�YĐ�qOV���z��S�
ks��aB�G&�/i��`����3���na��#�e����gFù������X��}��0J)Zk�u�_!��[T�y��'q,KQ�u�R���IYRmr�ʣ�����019t,+{���[��I�=B3����^�̮ߺ9���^O	����I�"��Ȑ�Wԝt�V������ar+=�ؼ�7��>?1�"_��$.i"7�� o]�<ڧ�;,OzN;���ƧCm�����%~"���>ރd��V�g��%}Ic���fw	pj�j�pe� �;�DW�����l�.* l���7w��R��|��G�fY����s�ƒ)[n���t�`:�";�y��Q?�%�L4�	��]g��_�wH���k]�xm�cl:�S���F�0�go6_6�jZ���PV;+�f���gqOP��C��_@#w��{�Z��P�[W�|WBbk��l��n�Z�����82:mʢ�
My���!�'��`=MZ��~�����?��m`%yt���ڙ��'�w%Y����df)H�UΏG�g�8���ֻ��h��VzF7��CkvO�����2�9�κ���\���F���I$�p䠸vm��A��x!Rj^3w?�5"����x�P���g%|D�]N�Ù;��w��.4۠+�e���5���q�ȸ�3�\�lɀ���p���0��}�ǫYd�2%��+x���܃�x�l#7���j|YC_�j�_�}.by��u�V�Cǫ�v�t]��,��+�Lj��IІG���FW6�vf�J˛E�6Sۖ~-G�����"�d�;�M}D!����,��a�d�D�`�^+5�B
�O`��&(�5=�o���<h�N���Q3�
dt�q}b�F�����EB��nz{�-(����G���i�����[bR-i �a��]/&��ͪZ ����`�nUH*F���..J�N��������V� ���hM��`��*	ݖ%��.V/P�/�4�m5�z�A/v���w��������e�n���ͩaL�ưt*��4�s7r���Џ)h��Ģ�|=��b�����r��UB���u�O*W��Z_�X�+-�J����V}��獳�����t\εPwr�wJo(����}9xj^@|ɛ�F��+��$USx�zZ6	��/*N%�L�y��ǀ'�nJ�\��{Н.-�n�^ p�(�{"�g����.e��z)(Cl����>�3�<8'It�^��]��Ы�IE�HZ��(	j4��n�}�L��C�R�w���������F�b�珄�+7�S8����Pȸ��Ѵ?�ǤH���Q|�$�b�C��#�x�9��j�?k��]*�;��>��~���AV_>��Ŕi�ǂ��Oi~��+��]8[�-[�EH5._v5V��M
���[�������-:(�C|�,5��ņ
P�P�,k���Ni�v=d�Y������+�B-��.�&6�w��������VګF�jR�Cb�oSf}G���ĉ�|�`}K�ў��� ��&��F-�㼇���}��p�'�<b됚�e���[ԫ����N�fn�D�Q�b����Nzsޔ�'��,b��<,�_�p;�]��Mi_wio�s��m�L��W�!K�&G��y��M�BR~V��R���c�>���d�S��7���<״@��+�ּ1Zw�2�f�3��U��ټ�Lq�oY�{�jԄ2�MH-j��o}�]��a����j_��5��,ο��O�l.x'����B8����!��q�N��9w���I����}1{%j�L�Vǧ�Ζ`�x�+}Ks�S_]�C��dV�=
[0?9�^��b����7u�h�>j��X�����Wc��q�AZ�Z�2�9̏����?s�ji��W���&>q��n�������?i{���{�)y�J@3�l#I�0�6@h�c��g캬��E��_�M�e������G|�J������'�ڌ%s�;G���B?��f�C9O��$>�V�y������R[�M�A`qc� �ͫ�M��������4���lTd5x��<o�J���܈��I/�_uዻ�F��F1�-}l���+�iAϐ�\9�NЛ1Rw�#p~ȢW���(�e;�5�O�6���������\'�9����*\�C�����6wx��v�T3�(�h��G��oT��\*��ͩ��Y�Cǯ�¼?�L�Ѽ慛�*�b�i�[���/8&u�����,4{�b�I�c� �8u�=�����u�����E��0uE����|�LG�P
��%~����n�[4�gB]	"=u	�"���%ˤ)���"�c%^
�)-�w��$B�1NZ1��rB��x4�!��-����If��ґ�j7��"�nSK�y�ؓE���<�?��|�Ԡ�ꩉ����P U�����a��
��"Q��Z��+��q���Գ�r���$��m�blah8O�Y�U=���E�Al��䪁J\a���u3���`V8Z�1�B�n�r�zXu��-1)O�;���3�+��ZA�`n�`�?�ʞ�	�Run���hq��~A7��j�Ww��a�*����}�K����q�����`H�8l���_�
&�̏�����/
];��m�r�@�
�.�Be+��満�v�^����8���w�!F�5)f��~���`�}w��'���hdT�!�K˅��!�$�/��"v`p-]I��c_�*W>�.Jm�s{�$�o<���q�����.*ü�r�;�C�-Ec|4�?���y$O��Y�:u��m���T�y�;���$̲���2���[���%�'��`d�̝��Y�5cC�Q`�C����"�.@J7ֶ�c���>V �
�3��πO�>���MÖ4K�zm�X����+m�@j�ޤ����>�+\EI��*Z�{6MG�,@��oYҸ����8�
�,	�qb`A��������<ޒ?�>.ۜ�uZ-\�_�5���*�DN��H���^2;��Λ���$]Ė51��ಆ�6[=��5��"ٷF&��U^f{l\�^-B
��Ǽ��'�@����f���3���/>�`2p�!��+y�tY���˕b��Zi��p��U0�e���^2%А��ڙ���a���Jಾ���tS_�t<ґp������$[�j��E�iW�?ʹw?�@=���!/�"q�N�X-�[�fUyW �餜(�s�HJl8*{�$w3�o�������[;�?f�� ��/^��!@���5c�]����R���cSi5�s�+@@���J�l����q�
���٭+��r�s�xl'כ8�ɹ���f���x2,�iƊ�w�t7��gZ$P�Q���1氳9,乂c]%�A+G����b@��]���i���W6^�q˪U�<�}u7��:J�d�^S�\Ψ����G÷}���E[��%��,1������>���><�r֤�Z��5����I��j�v�X��a�;L��ƍ�ɚ@w�9d�,�]���dԩ�,�?�j~G)�>��@Ϙ�J2�J��J\;�轾o�	��~ȝ��b ������ۭ`������]XsC�-�qSNJ��,����b{�n�\�G�Ϡ��B����X Fy8I��6��-`	���1�2�s;�ւ7sVū�!D�g�C-$��6iocx���� �%7�r��j�)D-����^��Ā�ؚ$�o�tR?����X���w���1���~��L�Y_9K�����E�M��}g�'6a!V�EP��d��Z.!Ę����1��TGI(hv>�|d9Bkx'[-d�<ea"�wq��|���(1q��e�6�����?�N�Ji���f�����F����$A�� 5�YRL*�� QJ�V�p7����I�*3=%�`�/Ѓˮl��v(��`��9瓯O�@���2A6����0��?�\��_�ʦV��J3�M�4
��d�;B�FE*�3~�����*ޓ��������1�0�/�	
>\��36i�n�o�Q����.�,���U�ڶ�ߴ�<�1�<?���q��0�in'l�AO U T�$)0�B����z�7���&�����"��C���P���ϼ	�gF$<d�ءD�O	� �����F
<F�Cc֑m]�Vx�4\�+�+�����iWܯ�<.�B�\P�G����⺀G�
��P:��ck]`�I��`DoX˶�F�l�N�����7��D�=Dݓ7��BJtn��3�0�Y��P��{�
g"���\E{>],���e#!��w?c�#�jDȅ�\�"��O��X�&�� T����P�i�5�����p���t�;r!��}�� ;i�>P{i�h��T�m���H���u�1OJr ��Z0�B�3p�؊6l��T��c�*Mj3W?���޽�@H�)
z<�J�|�*Gh�W�D�Ir�����]|�jM�Q-��t��E���g��o�N?߃2;>s�Tq�d����	� ��2xq�5U�V0R�V�T�o�Yr;<�#@�~1��J9l錢�R��Y>9n�.�zf�52��Pٻ�n�S�rL���t�3�yhf���zW�fU ��~���Q��_.�!T���Y5��H��uMJ҃�-<���L���kI;���-���"�Ȗ�RZQ�A|��-��ml�d�sazB���I*Ȱ��,�j��דD._w�rVw�}��:]d�������+�!��~�x�F�<�q��F���@&*�սHD�B�v�����B��Kx4��B+.�V���J��,nk�]�EuV�&��A�~]�!t|.j�^ c�����I �?Gz��-\p83�km-��0���5��K���'�dw`�'瞌�Q��N:0X�de��,.��B�A�@��D�U:J���h�NU��2�=��E J$�EL�jʘ�m�9��uQl 鬙N�|Ѓ����c{2 ~�W�Y�tb6N��Dda�0@.�Ul�Q�����Ma�������r
�
!��_�#�?��&v]����t�ꀏ��zc�� 1����A�V��L�`��J�M�{�1%���kq���n�z���~�+<�ӳowTLz@\�����x�I"?�T{,����WO(�����E���D�>,�[߭K��}��3�-ͭ������,���^i��}l/��ME/�^�;J�������5|��T�*���hi�9���_�t�PTh/�q�����CU�B��<<��Z�L�-�+|$�:�Xf��в-?��&bX����K�p��i����/\.ڳ/9C�P��������i)��;�R�x��ks���9(0�%��S�f�z��� �=%4�SGU��AE�i�Gz�^َ*[M��T0iAz�<���'t���%�#ڐ��(������+{�nf��D�G���FP���N�����~�h��=֋��q4���@TD	L�#g��jk�OJde+^� gp��gA���<�1'+�]i�kDȢ��D���^f��:L�ca��kj��}e�Đ/��	���K��ӣv���P�����uE
��ք�I{ <He\:�7U]�>���W��n��ϣEY=< w@�Q9��G��JϚ���z ��0�<ME8�?��nt�giv��@�U����bi5)L�覤U�4��\����+Dǿ�ΪG=�*����
0lzŲ�� �f7�)��q!��N>G�?�e�EFrn�����¿��c��`Lc�X�R��/��8��BQ���T!8K�#��B��� �
U�l� h@Hq=F�\�nz��_S`Q�3S{��-�Z;�ِ��琕�� �J��=SMr2�>|9[F�����i{��tR/��3a����dd�����v�HtE�܄�[["�;#�2dH�[��5� �1���6dL�ĪAݫ������S�*&���4Eō7k�neZ]��>�Wc�X!�m\��濵����o��v��:S��Q��B�@<vJ=�
��Uz��VZ~o
0�Л8gH�bU�.�y�_R���8��xڟ9ַ��j�³�?�٥�<ҭE��`�FP���U+���j��g΁���U��Z�L
��~e�_ ƃ���Yz��м���ϷyW�}� �����ˋ�P�T��"n�s$y,�"Vt.��B���2>x�ִUі.'����qo�PD��-�^�3� �CK��e�t�;���9,��HՁ����֬W�;����u�R�K1����Z�wϋB�����~(~���J����BC)�k�=���h�
V�UG>�����_dV�܁��S���I�-j����Ꙅt�A|	��A�yg�Cd/i���$~	����bK���(X|�JA�+@\����Ͼ�H�Bq����-ܥ?��y��%���.9řj���ܹ?�ߎ ��ԁ�|�,�b�$	�e5��JI���v���Z��E!�f5zZ�O����
t��P-㞅����Ʉ�s�;	總��U�D�mК}���+?#�$�Yt��S��Tt� cZ��d��`�R5O�?n�:E�E��
;\)�HܹEp�#lp��q�} �����E�ĳ�'��c�6'ko��;�������(/��B�Biw��9�y2�| �����s�*>M�gD�h_:��	�Uha��]~b�+���@$�ו���\���T\J5	.b�{&�P6���\�':��q�k]�V�Dg�ku���@$�ԩ��UU #brU��i*|gx~�� V��[�)m-Y�nh0Y��
�4�D}�q����[����D��Ծ����!�R���AX,���4�\�E�#H�;os⤝����������a9��55v03�Ʃ�D�R�Ɔ��m8�ʞC5��H�
��W%'	$l��o�(K�~�/�.�E��59�9�0�d���4����D�7j�o.����<@G��u��6�U����D`��V&���q�y�
=jGt9gr�0oM�R�OF��*9T���8N7'av6y/S4�ӑ���J������^��!���Ac�����k@�S(km��ݝ���J�ŗ�t����Pd�.��f�>Ｋ!,���<?Ɨ�����O��$4�ҮF��+��9G�(��
��O/���vD��Y���$�2���E�U '����A.P&E%d�jB���pF!�5"u�;o8����� v�ZW2�_؎�ߒW�I���T�?�m�|� *&�YM���[�O��0&^�߸����i����E����,IXSf�����M�\�"��`�ӐVYN
�z?K9J+����`��ǻ(��p=(=n׃�M2��ޝ���M;����Tا=*1*����e�7"J�&�Ÿ�}��zm}"���WҎ�d��LJF�߼hn*�w�<#���5��\�%��4���z����Dm4�l��0�|n�_ ��^ʋ{��|1w�wi]ĥ�<Dŷ�V|1j�oZ�Ζ_5�ԝ�_)���E}��uR�~�m����9O�d"�p���|K�+/�v)��%x�fӌ�l�w7?kBV��~�s>&����tpR�'CM!���w��!�0� tp-,�Z>sZ�'���q;�@0�4��C�9y���[k��&�Qf���9��6^b�S�pa�;�yS*�KHug:�L����	xMŻQ�5�Á8R+���W�(55�o����(��0�/��f�{ɠ�^�<�&�ЄF[��6�G�z�gO���>ǥ���v,��
��h�yB>0��=�{O�e%��G�ڶ'֪����مe���>`���{.�����X���G�0��o��h:r��
��Γ���_��!8x��n<��S��y���>g\%�5=�p�nl����78zWۀ�%Ü���{�ǁ׼��k~9i�^�̳r2ؑ�����o�MWÏ*Ak�g.���5U��9�n3��ю���Xj[�mYP��m����v�$*�\��!T�߉��Z���(%m,7ŉxw�XU�X��,!>	�~�F�C���w�@�0����/Ph�@3x%�/�s���r��.�	g�"kGP��m��Ԍ�y�tJ�X�$�)Cx�:M�n�������HK'O�;��z����Q���/��Udk�^e�|(!�%u���~��C�h4�H��ä�|d�� "}�9Xj�J�����m�[ot�����X�y�2�(�/.vPb3bD��[��a�	)H�<�VbP�}�X�m0m�G7����k~=���Š]d��.��'�8<H�k/e�?N-�0��Ȃq���Ƣ���̋�?����]uP�x��M��ѷ�NǺ�L̴7�.b͙�~�,=�Gq-	��?6G}p1g�a/-hؤ8�v��Wu�H���IBrPU���=�����KZ���>j7Hϖchɭ-t�n��<0V.����W%(u:��칄�M�s9���P��g)'���=uyT��+�.,�WE*.��%ӹ��*5p/���7}A`mPD��P|z?�ħ4&�ґ:Kyb���*������N#�|Hs��q�|���KMK�*G	��B�� 5�[���t��5���U�DQ���se�&O���]z�13n�HBK�7B����
��7�L&�-�t[鱬c�g{'������G���#�� <�#PyӴ	�k�'�E���H*�kk$)�ݵ>υ�6t�UF'�I�+i���.�/���\΃M�u[�w�Ʃ�L�r��B7N�ЄP�]G�Q�p��?g��T!i?]5�ʗRq����m��ӷ���q[�&:��ի��V�X52��m���yip䛒�lo`>h�x��(Y�؈�X"��_#�W�Xޏ�ە�06On��ynw�a���i�.NäF��D��%�� ����J�}ߴ�i�g'���+��*v����0�i./�q\�z?���S�DK�[��.������e�;u�r�i�	q@�#���f��SH"��K��WEy�䐝"i`���b[5�D�P_[���z��d��Ev�?��<�^I�S��{.�d��PkW���������C��s����� )
V�Uי�:���&�V���W�J�6l���;.��2k_����X���	�&[��}��w[�a�DQU5����=����#��_Vv��mBQd)��Hh�V��q&g�_B���W�>q�~���QB�mJ�bՕ�*^W;�h�$)�7��>*dh��!E}6ڑw�Ii�b�DIITK��� 6��7~!r��ii�����+�Yz�f.�����w�_�m�4��_����NP���M|p�T���h6���%��u~�ɍ��[�MM�bz�$����.a����&N���'@Cg��q�����Q�j��9��%�_�]�.3�G�+l1n˘6j�JSb���Q�q�����X�,2�P9��GV��VK�������@���B)e��� ����h�C�$�!� J]2v4�O�+(.�S Bط%Y��H�W]�<����<��d�߯���ơ��R5L�^P7|�����lU
?@�D.�q~��6� /K�sI�x��Rr$���D�ȼ'۟�����e�5W�����'o6)7�W�aN��Z��;c�GhI�]���+�pˇ���RVhP�'�Gb�7�g�;�Kg�����{�����@r��Y
�Q	��3�|��R�@��� �l{�7���>O�\�g�r���h?��)���cݶ�u��k�/������D*7��H�9y�fQP�8/����d�YFҫ'"%%��e �����Kc��6��H�	��TaU�>u�/2K���E��j5\���?ct}����fb؝)��t5�䡚���0M�$�}�ߴ�KR@�� ��/n�:�-��-uس�R���Q%�~_ʉd��	Z�B�G�s([��^��?���HD�-�a[��mD��Y:(ve�Řy-� �ڣ.J��I��Ї^�r��_H�]��	'Pb_�����=��������~�<⺁�	H�^�N��8\�$���T�8�~�-N?�)��1���$�pLH|W�eL��li����"��:Gx��i#��J��1����s��[�6��	�Z�*?e�_���8 �O����/�Y��0���]p-��X�P�M���6��kĈx�����ɧ����z���$�Ώe$����6򽇀2��V�9�R�����y�-Ó�����?\6�j��Jj�<�?�v��Q'yP��IFJ^͠�ߦ~��`�jؚW�|�D�ҩ���Uȇ���Q��o�+�+Nܳܪ�rp{�H;7�c��B�8d�Oh���������37!N�;�w��WK�9�Z�7���/�|�qU��~ʇR>�I6���+��o�
�زi���LH� ��w�mh��י��.h��>g���6�]��aJջ�����%:�u��wGlv�݄*ٻ|�z,T�m{�ŉ�>O#�߸|�6ɠ� T ���񘐪a�I�N+$�>�`ad��ӓ�sKa���Z���3I�.��J�<NO�E��2�*]c*�v43G�1{l���i(�����k��V3����/!�h�ޕ��k�4��w`�A��[�*��"��`�%���t���)��*Ss�=�}A'�c>�6D��^^�ľID'�K�Sj����e�U��*���a�x6�j��n����K4S3g�؎|�?��ek}W��*�XRq���F�� +=dǾ���Ҭ�Wxk���:&�݊�N*�/�<[�ꃣc���&ܘSA�5ead�~�d+�/gu�ŕ9j����g>
b+�[���C\�+	�&�(O'S�pG9v���Cm���!�k�4x��j�:��&��'���'��&|�G��D9���G�Wv�i�˪�t	��d4�M��L��(?���O��vG�X1�L�!�Ћ)�TXW��`�{�+���m1rA�C���X�p�}*�����U��� b�	2?���VD~Ux��Z(���5/�aܿ���r��Ƃ����ޮ��X�`^�����f޽�P��6�mM�@#�Z2�iq
�o��ã�w��[f�_B�b���@;�Q���*w�|(��U�-��v������q���BQ�����A�zRa��-���ˡ�6<��UĎ��������aP3�-� �.�hӂX����O�� �1�>�ų�L-3c����`�9z�e���S�*�A�U�>h�+��*%�4V��$J�8XoW�d.�쬒X�E�t�n։R&�b<[A�́��@a;\
/a�DG(�,��R=�M�3����xtL���J��ò����%��]z���2�=�`�*�vW���x�47�؞J{����e/�pK6䛳K6��¿��q��=�� ;�Ĳ�D�⌙���=ek�J�h$"8�H���|)K�	����yVi�$'�R23��>O}	8�^@���#���o�����"9�k��q����Y\8S�^(߂4�[��YV ^=!�����/�s�H9�9�5p��~]�+���r>J����N4��z�19�.F���eK]6a}�L�%�^Uz�����1�`s'8���o�&4�����L��qp�MPL����6��fwA'ŌdG�x�`�Q"`<�ɶ|�����2&Ȫ���%o�jm� t���5�.V�� ѹ�.�%L��+n�]y�9Mw��Pϛs.��x�}# ]+�X�t�I�n��Q����;9�����n5H�=�+�'k��f�{r����l�,B	1af;�[c��T�ܹ�G��q��rv�5�*� T�j���*S�i/��&�7�e�&����?4/�Po��^������8"u���� �!}*ls�͵��)��ն���h�������y��>��좺3m��O잕��*�����hk#d�4�GOV�+}�����d����]�f����hi�k>������vi|���v����ώ��\1[�}g�L:Yo�)h�#��YEgG���	LlQ8�>�m���N��S�{ەy!Kpɴ�&���Wލ��)����|�O0&�v�r�U��fAY��n��{�i2Ӵ/C�������{�+{ �u�t]�8�x���A0�2�V��Ԯ�.�B4g�Y�xeQ^�&Fx���P8h����m�~#����ܖ���V��@�5����yci�]K+F4jR*W�䞍 ��o���� ?)�}\�,�Ϻ���Ŵ�����!����T3de�e�o&<��?�e�Q�%m}[/=�'VAp�y�1g��(�v�OGISmL7�?�[�8�W�b��.>�hͲ�t��t�������h���g��Y*���!��� ����L�Net�]܁�����{H�gYt`c|ܲ�X�3���y��Yv
U��qBD�Tq�I^��F�"����B.�#��$7ə���e���J8�����ߕ�G��d}�-rq��f�#��q�P��H7P��h�Q��B��Ԙ��j��Kb���=9���߅�Am:�ʥ���.���4��B���}1����0w��O@�Ke6����*8�&�`�.l��u6M�]}_-*^��F��V���&P`9�8i/�ͽ��~��uk�w��hW�w���Lv��4�u�J*�:1{@���U��P��+�,܀��%,�ٹ6��{`��C�֕�����o�.w���bH���_����}��߅
�L�C�_�f�dTUg�ݬ��Q"�!�߆+e�װ8��Y|��C1�Rq��|��-����aڰ���ɩ�,��Y³��cK���J��=LGIlO�&�o��x��N��U��"o;�>D�Ԁh���:y:��/nSN�m���Y�����[ul���׼m�Ph��$��,�L<����{�#��S"�ܮ?��+(u���W���~g�6SO���������'�l_�Ǐ6�$2�f���3<�.��{5py}���=�Orz�KrԸ�D����/�$I��U���'����Y[�l.IzgI�: �/�fο�T?dÇ���RAT\E-)�&�W������#�h�_$Ң*h���`�I%`n�Y�h�޸F}�e$���U��U�މ�o��h�����5�<)�P�.�	d�r]����+���_���6���ԒW""mШ ��Sl%���v���Tg�*)pA�]n|�,��D�@T���G3ppj~z���'�h�dM�f�ź��Ej� ����Kד\2p�K
�;�S���6�{�v�9�B�K�3��$�eJ$Y�����9�#��=�r��h~�3/����ˬ�>rDb?�q�H�!��^�����"�i��Y	=����eAs����Cv�n�i]�꼾�ffjA��$��	�DK@��z5��ea-��҃?{�S�`a^�����T�g�rdQ�'��/m��zH_��y��-e&v��_�ᛓU�.Q�`��V�U���To�窐X��	i�������Cv�QA�Ai��&�o5�E�X �A�!˔�_.�������]�(s��IG���<��2ȊZ{(�w����9�Hy)��l��{�SPCm�]���nG���u)�=��;!�F��8�Y8�5���{׆h�,�| 7����JDϤgܭk��<(�x	Q/(n��y5������f�i�lo�_Cl�@�����˲�d�o��%dEkf�=��ՙ�x����	�%獅���(#Ԓ3�V����o���+<i�gwR�'ר�J��|�wO.�'���y�Ժa	؄�W��b�"���+q;x��u$R[���r���y�Z���N�X�����#��^�TL�MƬ����^���|���vb"U�,����r)��I���|OyϦ�E����(����m��l����#h3'�/�9m� ��=P�i�[���C�o6�U|jp������ik��q�(��q�c$x��=��������e<�w0cBϔĹ��t�)�	����A���$UL|l��ԗ��|:�b�X&:�
y�+J^�L��σ�UK��y&2r���!Dm��Kt���^S�^�se����u����F���+x�}��K�EH��iA�e���,|3�R��Xt�ԅ��`��N��� �`��T�lhpE��|s
IuF����T�ׁE侷��݊y���4�������?�W.�)X$p��ՈZ���	�8��<�}�bqk<��J�֣����z�kT�
���zJ~�WYYxb9=�?�]B�J]N֐ ������< ﾪ{Y��m�۞@�t!=��q��îVQ�
��y�Ю!m�$��VO;��<E��m��1���Qr�6���-/f*��wVπʃ�A2�����iT�e�T��^9j�?��o�¸�,K��fV4c	��#r�">�[��[�<M ;��e ;�@h<�BC��������h
�G[I�s����xs�Z g�Y��0c��fDcN�;;׻�,˅��K��.�����K>O�*t�%>��0!�d�n	��Qŋ�1j�Ta��~���ϭX�4�=#��&�x��,�����Ȅv���]8v��3r
Z7(��.�nɼ$�7jo�']QX�Mmҵ��������?	��:�	���D��hn�5��#��0����@��U��.�[���>%� ~��6JE��F����:��޺#B�:hߚ$��k�Z����׺��hƽU?5Jl��Ϳ0(F䶏���k�&oXU� ��5��|�{f�\�ARC��{��5�2^1HC�h�D�|�͎o� �HZn� �@����'J����{ϳ�L���z0�>����AySZQ��)�ە	MrB��Æ�Q�Ϲ7flRXG��	��i���BAn�o�|�c'�d��2 �g��"m����?�D��BV`���DO�/g�ul�R�I%d��J�F�{�M$2�S���ǰD>��qiۈ�,u��nĴ�"g��XV�D��rzS5���n����D�RG+� 4�G���9q�/�"����C�������7��Pm^�	
}td-�w�������{(\y�����6�0'{vH�8aw+��o�v��R�C�S��	�@B��N�xG��Law�/�t�uP�c�Z;kd�9����z�WВ��<:ʤ)\3*�4a�����<)���:��˿9��%܀�% 2VU�4�(�t@{cN�ݶ)'��욟n>���H��˙B��`4S41��6��W-i�اCA�Wѫ��  �?*ꌇI��m���j�������?rQ��-��r.�9�G��|��3�Fw����F��|�4�H���H3���9�_�%�=�*m33���8���ĞW���oPW�6�jZY��s�@��U�?���/�`vΜi8���5ʙʕZ�O�O�1�V�r��&�8��a�r�����VFП!�h����NT�lWr@�jQ�Nh%_��I�8��]֙�,�� ���數�	x9��)I7���]�����(y�}��/�/{�֞���+���J��|��(�=l\�@��tNփ�\�`�P� ��1�Q�<X�]ov�)�;�Ä��W,�|�֨���AL�W���2"�a�%�k��_�-���k�I��+�^�d�m݂ySB#�Hfa�i-wI-���J:bxS⩐�d�c�D��g�� ����Y2+.]Zku:�-�1=�R�N�ƙV�Fţ��J膈��6��.3t�v9#�!0Q�MȖ��i
��͠>������T� �7x�W# ��Ĳ����ߍ.h��S�����1>�1z��`BV"����S\K�M�X��4�9]7�Q
����k�VW�ʦ��r��(�!1?V��$��tL���\���pDЇ����b��]a��Ԓ�m��L�G%�^C�j���ʡ�XQ�5H�/y�8������=�w~��T��%�K�_���^.���>s������	 r���)�S]Ʒ�:I��=v �z<�Y�)]$����ɇ#X�T��5n� �`�Tǲ�ㅿb$�����a�$;�_Έ����[�f�+Ç�����rD���~E�rd�ʍ��џ\C	�D
*�酥K@c%l���J�.ݢT��d�>	�%��wC��3��o�(�����Ҫ�@hW��!�����>˫gI�i� �������B��������ivb���c���l�@n, ���T��9��v�s�h ��F(���R�u�Tv�|�2>2s�ւ��%��]��珟����`FNv>J�cFӕ�쪘�U�7�.�T�Svݕ ��O���B��Ϯ��Wg�p����� �
�F*��.<hr�`B����p2Z�Nlr�,�}��8IEg��t��%����*�	U��;[
�"��,� HW,�8�N�m��y̫ᬫ�)<�t����*n
.��-���_WBE�R�$��o���%<�b�y�[IЀzM<kU�r@�̲|��Y�o�M��M��c�n�خ�M�Zß��d�m����w9�_�3M�r����U�C�=85��cw?��Aa�3���IQ��ħ�$@R�1�e[���4^v{4��xx�jQpF�w ֝������m۸`�r���۠�*_���̄;� �H��O�QTZA^V�ė�E�jZ
.�E��-.8�^����R���{�݈���4��Mҝn�n3EE�Û;��pD��̴����Y��f�2ƻ�+�.��ǖ�$؛t��]��p2B_Y:��B���sƼΩÖ[���
��&�á�}/��i�z��<�H��Z-�����tG\4+�CmJ8p�Z�wm��u��I�1���k�}pD{~q��^a6�v�!��o�8��Y�C]��
�OJ�J�b�I9SB�Q陃=X]�n�2'��|����ԃ��9�Zg̮E�L�hQ(�.�t��7�Q׈S5_R�w1�f��O�bU1IraxY�K��2���K?u�EK����չ���t�\�Q�\�p�t�j��S$d��b
<�4�K�R��J�!8dX�}Ɲ�aE��`s;�>qD�t�@6����M��j�������,t��?A�8Ks���3�3��f5��C�W/p�C^38�"�h ���O��U�<�����8��3��y*=�>�g�h}s|��*M�#�Dx���Eি�!L̽�y��\A���	I���7���g'�?F�k���q��( qm�+"$�5�����%�_��,���ݸ˘!�&ɨhjh��P�����#�`����.�	���ř�}�Gg�=����i����^����3h3kE`c��I{���Bb;u�<��"���,�#�G��2g�䰦�U��8[�?voG�����$]���=@�����Gӽ��uw���WrW:�WǗ�Z�G&O���i�=�l��7-�?�ٕ.-s����k.�=j;��M���*�u�Л��B|v��a
�_�ͷ� �X�D*���Z����I!bs�����{�a�I�eLE�]��#���E����QS��-̕��^�Хu�6�3�BZV��?�
Y9�yrGF)�����(�Һ��^W�-vp��j�y��[��ҟҁ'-���|�m^�l�&Q��Rr	�n�u(iI5f0aZ�	{cq��Ѯ�r��?5Jg����ls+	&7	�/��|>}P0���������`�#��B*8��,}�=��[�n�����(��A�l��`���uC>r&�4F��R�OV�zGU�?�q���� �����U>S���kH�s����ӭ�W_��<�b��9N��3��|���}��h��/��'~�f�N����0�ihD���nX��@C����-��R�!ArC*��� ����;�`��o�c &Uz��Ԫ�)�Qa�㺘1��Z��!.l���[��a�)='�#�s���5e��ՙ*�"�	�Z�Z����Ժ�b6��sUt   �d��;
� ������w��g�    YZ