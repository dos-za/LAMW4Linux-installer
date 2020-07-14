#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4009224776"
MD5="b1412c0e8a4dd23bddb40f8952a231b8"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21300"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 14 17:56:08 -03 2020
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 140; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
�7zXZ  �ִF !   �X���R�] �}��JF���.���_j��7�-�i����8�>�H�o����w�%^kf��s���\����掸mXK��Ua���
��J���e�5e�ȡ=�Q�Ru`���KM��X�u
j�z�{�s���.l���4&�7������������Z_&�9�����
��v1���?צc7��;����C�f����;����%!
y�g�/����Q��4�0s)p˰)����b�Rk[�P�����k/�(����P��+X�;����ρMu��/���7�*y{�pe�����f�湓�r�#�*M ��ic�6���ǂ�p?>SS::�r0Ti�6P� �
�;�$&��g���;e(]1����=���P�g�b�U���	����Y�`��,�VFi�I���(@�џ�D�����*6g�z��1c�-��7,-V_���yt^�T��'>*Dq��>�AB��?�;/�����s~�5_�\��v��6h��
�������k-ɑ���]�<���_�)5����X.'@!{�K��4��F*V�x�4���3Hf��8A�?65��~*��'d�q��@��6���g��}�$G�{��m�ue.՗�s�"V���-<��haP&��.>�aVS]��F�W��^���Ǽ0��.~�����YOܐ5T���p,z-��c����#7?k!xDD#�S7x��B�9�dh[��/���UQU�7�r��X�X�H�-}��t�������̨�n�XH����[���.^�#w��Y�k��v���xɐ�@�zG �{ю'G���w�����kR��㞚b�!e�G8{����gB&��xSCO/*�1��~�p�2���Ծ*��ۊ�l4�K�*�9�� ��?�i U�f�aʬ�e&jL�m�C7��1QW�H2�7�2ͣ_)��^t����W��L�]�} Z/�@�?�x��~��Z��Z0�T3KH�����&񗈙�U���I��ݷ�����3�Փ�u��+�Q�i��X��i�n�cl6����`#Xf�ʔ���w�ؤ��Z@'�o�t5zo>��Z�����h=�04�Gݮ�s'5�*�U�B�����"U֢��`���YABO�ANo�D��Y�r�� Vg�o�8������"�o�µh�1QTҌ&y����`7�-��#f���M�n[�\ס�js�+�Y����V�tڍ�=���R�4q4-��?������,r�n���vYl��(�ڐ�鋷5}��ѻo}P�I�/ݫ�f\�����U�>�TÎW��ӊ�QRo�h 9���}O�UE��ר��Ő5�Ҭ�ڨz�O���3[�����z��f)�;�/p}Lx�� ������y����(ݎR]UG�J�҅��R���[�iz��l-_�/�6��.����ض��ÌB�U�ɗJT��T�U,ϯ���D���4D�������d��)�܊��O�j�Q�7P�巉e6.�C�مa�M���?�j�>��W��#�Ѫ�����i��ia�K��6ߑ��>U5`HaSO��y�7�tj'�l��p0� `Mj�}���N�g��l� � S�q0��ٰ��Zu36�s��i��G�����4=8ﲡr=a�pj&����n��0��
Eه���g�p���>h2%���9j�vASSշ����"j5T����1��El�̸�R��,=�EZM$@E��`�ܘh/',�eR��7օXπ�w���(���+�Pݾ�b0U�:�mY̰t,�	��¤���ΧM��6�J�j=q��b���|�O��^��!ܸ9�0(i��{&`+��t)��`c
\61�ǌ�M��ql�|Lq�i!j��QN�&z���<\�Sj��g���GO�]����YA��Cs��s�FQq9�CN���C��~	�ч}Z���?��:I�h�]�����͉�É�D#`7���#�E�&|���&����tS���BY����F��Ôb�X3m��T�+�vg�H�Y}'�v��`{e�ז�eh�?��M��~=үV�C/"��P�m�����w�+q�^l��y��U�IO�3o�T��ԙD}�����A	��
U����Z3צH���)�wm����MIIL+��a������y�0�uzpm�^?5�V\%���J	9�+zj�A�L)�L��6(Q}������xZTy��6�!��g�����Ƌ��RX)�*	&4�����]�W֧�b{�W�!�G�v��`�@mA�S��{R�,n�(u|����0����ŋ�N��OM �뛆�t�~bD���R8��R����`���%̾_��8�I7m�$#x���·��Ν�&/���0 ����H"0R<�� K�b.-֛����i�lK�����eruu{��/�� ���io
^��bM\�J0�?:U�����\F���*`�NU�ĀJ9�ݹ�sr:�M��_��]��zj�J�h�28o����y�AV�$
ȉ�eDH�����#�"���a�'�H?��ЀBz��� |8�L�n؆ԝ���w��"��S�͇��g
�@c���=O{$4�a~�4r��i�:{�Aa��qM��/Tm�?�_7�#�0����HC���[�T�f��;�9Ԗ���L		�M�)�J���,KǼ&��;*�0��al�^}�U��͛����b�A��eY� bܴH�ej��i}Mf+9']4���/ ��-I��G׷Fu3������Y�틔X(��3܈Cq���!k/쟉����̉ҿ-�w�[��q3��(@AX�?��J*
ߧEŷ3����n�ࣄK%Z�'��p�mE~NM7���ֈj. ��5=J��'��vb{sv�a|x eHׂZ�f\�rL��N���Va����"���faԕJ�4Ux�ʹ� �e��*3Ă<m�Wf���������$Fqq��{(�l-����
����!�LUGAuE�;��2�XZ��������O �a.	�E;�!���LHO�j�NC͙���>��b¬�Ѣ���q�t� /3/���"�z�I���Z$��JN�*̉��P��Z�k-�/9�ygf�,n�)k�E�:�a�ի���A���i1=wp�-)N#��X��7-��2�2]?3_�W��7��v��!}��B���c	|o>Q@�vc�^~\6|�Q�2�3�|�'c#k������Ԇ�"9E�k�ك?U{��fW>X�N �'P�(�u{�-i��(*A����,%WSu�k@{ܐ9_N-�]�Mlz`��X��� tV�w�o�����Ȩgߦ�HRUC�ȡoܲ�A4�%�0%�͓<�٦6H�NS����	r�?�^q0��'����~�\�K�?����؏�zW�x.��d���f3��L��HdC�7���<ƪz��jm��@V� lpш&�\��,Òk;GƜ_nb�.�ʃ�#�Uw[C�+�U�=��bG��8�0�R��U�L����?\����o�Jn��p/1�H��G���[�'u	��z�qJ|�Y�3�^�*���6T����f��qD
���{�ݹ�~�콆�Cy!��������j˜u�[c��lQ�O�r�Jw��ԭ	��� �#���n%����� ������8tۿ�v��9b�c��|���0�j�d�2d���!q�cצ�Q	w؇L ���D���0�eA�ٜ�*��dq���h�ܣ�Q®��D��S���sS�j�uaO��_{9;"�LL�(��W�;$�V\�&�t4	ZV�j-%a�$�5 ��."����`1�B�:5D!�F���泛�_Ģ�)�SeD�ɩ���,�� =���%T�گ�9�AP�dz�-�ҽ<���s��O{���DN9�:!ſ���(��Q|�b_ױ�./���I���Fӳl�����Z��vf��z �:�-	;�D=y���+z��l�yױ��͠8�hrv>��?*+M��P� 8@F@9=J���A��ޏ5�Qf&�s���0	�'�ب~���svڛ5��P����+�����/���h��?0(�IkGE���3�dnvj��|��k����D�����E�>��Br�A�~N+#n�D���i���z:��wt׋[b�hi?¤|�.�Ut���v��<�j�N0>҉~}�l�}�O�3������̿�0`�јk�[X��vF�A|<zܠd*Ss5#�ժ��W��ƑҘ�I�;�[[ ����M��%M�e��=�1��JuϏ��/X{KD��k�Fj��hYB���I5�+�� \�
��,Eu;��BBT���]n}�<��d�Z6L�%�����4����:�����v@+���4`�����P��.��Q�����xvt�����I5R)F�t�e���� ���l��������p�E-�A���o�=O"zf-�Em;��;��&�j6v���G�:ҒQ�7%��T2�Rݯ4r���\����ҫ��Cw��!\�U��Dy#��O߅ǌSw@z.ι�&�B��� �*��A��9 �m�wc.#.0*{+�	����b�A������>�-\i��7�6 S��?�@�����#
�Q$j\�D,������ް�hs�@�6���IJb�r7.}x�K��R�h�6����A������_u�ٽz�,�C'R��k-�"�I ��(R�Vn��IQ�Z#�$�/`��nAf�
�$�(SI�&P�]�?=�T�����?�7)�Ҽ? �6���y.�T�D+?���rt�Z&	��֊�hW����MV�p�cR	ۆW���_`��@���eo�rJ���[��׈�ں=�ٯY��#O'�h��� V�Nf�Ջ�p��k=���)R)��G�h
�ȹ�m3�#�j�Ca��Gu�]7R?�L��%�mcY�,����]��tbr�А"	*<8��pZA㟖��R��+��EZ�'��������k��i�È�k������?��7�(�����b'E*2<�������a���ժ�1�#(7Z�QT2$�a�F����k8�i8��RN'O��ٲ��
�(���d(��üg XѬ���z�)�� l�0�Z&�X@�nX���%t����B4�7�(\q���Ph��f!F�9c�S�7�킹��A�Ω�/�d@��ۄ�r,��bJ�)��(	0�Ϧ���>�p����c��o-�׿��к�89�UR�*�F<8�>c����I��8�6� m"`�6��t� �U�m�@�5�)��wN���)b�Li�ΓK*��YT�B��v��̴��,'G5����"�89��CH��Hwi�e���L97�AD%6v������{㖭���on��zlͫS���j?i�-9�sɋ� �Yϭ<u\|W�	�L.ou��L���	:C�kQ*�^g�i3c.��ۅ���&��"����>��#�	���dE���E`��"|�\c|
�V"��[��9����v,�<���@��Ye�A�
r��ؗC~4�O�/���c9�@��OZ]َ�m\��_%��2�@�Jp�O�w޻%�Y5����p���yo��`�q�L��~,�D|�K���Z���Lڭ��z�/��.,k���i����t��$��O��<B���.�ϭ�V	���\W;�-���t�5�V���������D\w��=���~n���
F�x�g6esc!�\��s4n�0��?���Ѝ]��ځZJ7���W�Ğ*c@(ڕ��aԸ�]%��� ����T�N��pZ���
,����i�����ĥL(�F��ZB��L��]��YT�P�����7��
Q��5�T]e��筚/1��
��X1~��C3�s3�!����'ih>�@�4�c���D��i�uI�6�8B����W�R�A�Ĉ���='��z�q�|�k �5WX�X �o�|��H���A�e�i��#�#�O��Ӻ߆��*�iOBR�ޟ� �Ω��'�,kȡN��I����Bu�,� �
 Iq��Ox���"��Ԭ�F���V�՗��.U:0Ka��X{�}'�y[C�f�L@.�v{ъ	XF�\��`v-QlCQ�dŶX+�`@�zcC��+2�P9/��v���-�Yd���.ncÃ�勝��q��s�lӡ��P���~��oL`D/W��3��~I���b��^P`�nČ�L)
"=Ͳ��i'.q�lsh�o�O,&�����L�����wZN��d��N���L �Ё_D�-����UJi
�����`a���b>DxH\�B�:�:Vdoe:��5.	����}�y�' �_��x+���mY�-�Ԥ|6�b����dV/��HI,��_k��b���j镜Zt!���}���s����������Z� m�6 �e�<&)�}39�ed���%,<��-���!�/;h�����%	��b��B<@ m���e��d�b^MO��A��l�\I9�}�;7���,yR_���7*�R���fϫ����:z8Sm� ��O�"v��ix���g���@��xA5
P>m��K�+�]�7��#�N�}I�f�vԞsL�TH�?�dֶ�5.�V\��v>�%?D�I����uf���T�x$f��\@ǐ�O΁��5�ź�:$��捦&\k��4��(nwL�ĕD�7�}'��;�2jWsۺdUr��Fbr�I<iWk����R^�����?-�|SD@�.�V6�]��8A�	���`�>U���F�&��I!��}�MV過&{���'1"1��	[���5́�u����;+GƬ�-�Anv��J2�4bͦ����H���CVs�'�Aqe&Z#5�V��]v̏v>�b��4$}VX;i,���R�a60��vK��AE�m��Qc7�E~�OT7�$Z]�(S[YU�̠�Ņ]�6���M�#�4�c��P ���~�)"�Uiʧ;E��s�$@R�n �����6�%��;��xl�go#�N�����ݍ�D� �h���8�obÛl����x��U�7�t�Ч�����Op7*�͌4)�����\0.gܳ
����+O{dnE�����𴎏",���TcG"v��".�u��P�H���D���9�/��V+9V�vj����RY����ĆU�p�pEV=��ܥ�it)s�U��a�����[C >x��f~y�/lI�9�С_W�q2���T"T�p��Yͤ�v����g"�� t��O؁��%������2�ع�@�z�+K��K��p�%=�����אn�n��G����I�Be�7���C�#,���~����C�Ԗ�.���u���+��~Ϫd�_�3�Ip�i?�bH\��q��X>�f�&�n��.<ys*�X[v,*F)L��m�}���&�[�**����v�G�:[��%*���m���dc�Aj�c��-^f�6�*b��0�����h;���Zܨܭc`m�%���{wF�x� �X	-Z��	�j�d`\a�0�.=��M��E�P���#tAF�p2�BE��݉I8�`6�R���+��d4o��������i�@7�K�$�z-)�g-}������ ��
�p��gV6m��?���D�h"x��)4��t��$'�����С�=�|�g]֪�Km�r�z�I�_����ѫNM���[Rs@(%�9��59~GuH��~E]��ɩs0rA�c��[��o��UJ��qW��T�5W��.Hy?aA���g�6�A!�*����T��%�9�y��ֶl9�o-ٶ��~�!�iD)��캲�m���xl�Zg�+�*th�L%
��_`�%F����Ɯ��z?��p#9�9�J�u{����2���p��jMY���b��!o��
͵�����[+�<��z�%���Oj��������	��S'=	t$�ط�?rX����vp�azF�9����ޗ�I���
�-*߮�
��0-�i����s���/>��t6n����vD���`E��7��ެ�z�?|�0~�h-,�D4?#��;�|�F�W���W�cf'1��]�����߹iH�,�8+��.#\�̠��U��q���8�{�0a��"aR�sU'�hJ�B�֋�7��U�Պ�,�i/�������*~=��\x�C�]��Le�k�F����T �J}ݰ/>�?����JM�s�bl�&�>�e�'&�hֺ�qݲ���%9Q���D��������yb��u�e���N�雖#���
�@�T�9-ca��c_�n�읲����8��g�8!ʠa�A�6�MHQz��p���^~�y�s��yȖ�s�=fxz�?��%��������٥h�o,��*K˞�&�T0�����k㰗�X:��z�d����Q�H_�ԝ��6�G�X�O�C�5;Q�/5���hF���rV���G�9l5Ly��7/X�g�_��4� �=lz�Z�VP�A����S���K�?��l_l'�2=|���C�Vt�Pk7p���g��"��ϫ,���Co�U�}�]��I�PgI�(��%<�4����P⾾ �#�N�R^�⋽��z#^��Qr�4�i�M��륏�h�F�F <�jؤ�}��
�׵P�M�+$�>:o^��h��;�7�[=?���m�%���T���!�}�rZ� Z�k�e�*�T��DeV���`zΛ��o�Cշ<�=�}�������I�P�"Ũ@�I�p��1�Z �j��`����{3s�����=�8 �w�v~��i���Z|g�]��i�N�[yJ�#��I�Ϭ����׭�oF7<:#�QO�u���#��s�Zq��f��m���Ђ��AS�jߠ�v�س�˚F��78;H'�]�Pbq�����*����c$M�S�,b]���Ҟ�hWt��!@Ҵ���ﾐ$,��2ϋ�.��T�����C8+�zO I�-�ЗT�H����g��5��,����D�IQ�ì�ϓ���9s��ĕ�o�N�	���X�O�\KQcܓ~C�aϕ�z	Q�L5���Fv�W�{�î��d�D���ϻ划	�\�����^n{<������a�\ҧ��IyA��n��&���}2�_�wɹˀz�[�~8��S"3)�i������a�:�%�@$�٬@��ҳ��c��_��?{�o��߆0nc�˜L��@����F��3!6�R&��Cѭ2z�o
��y��~�?�B�h�U4��It ;eIˏ"�kBe��R���%2��"�p����hU���峘5���ͷ~����R[��ұ�q��/�@���vs�{Vz G����y��?��9c�-2^��mOz�N�?���g�����P����ƺ���X�j���­��bI9�'9�����UJU>k�d;r���ȫ��K_/��&�&��D�V4E��:��;��q�-O_�#o�7��ڃmQFɰa��u�Kx�6�?&������}V�_w��Uz�}��xQ=~��]�h �K!��y#��U^���ؐB ��
��T���L��*w��PK �ZF�N]��"�,(�h�=��_H�)��lw�%���v���V1��K�s�LT+��wĈ�5�KC�f���嶠2���J �Tn�?�l�iI��Jև�Ki �;Q��v�~Y`_���m¸���6��nc�=��}��#��˺_*�~���pz�0��o��	 !]�ka��{�-1���Ȥ3P��?rEq`���� B�dX#��8��+0�mpQ����^S�Q�H��ͦG��rV�&ǹ��7��v�f�j?��G�;�����#��	��Q�h@ �wD��o/�F�E�9e��5�#�2���߇P2����~8�8о�/ձm#/�-?�kC��l�96i8e���n\�G�Y�(˜/���y]v|F��O�a�?'�c����f��Y�A>S@^'�'��� '�1���<]oz��s��S,��"�B֛�P0Mg��@9v�-v��_��1�zSkE�
��!�ʹ0�2O��>�����ݞب�O�K�#�0��7 �1	���[���𛡚"�E�u{=��C���Bt�J�x>BRr��~�:�)�� ���:Go��nQ|:���k i<�؁3)�a���`ڍC�ִqL 6(�2��13��Q��F��"�_$÷��(5j
����M����Cz30�z����2%E���p)��ұmр[k�E��6�톁�p9�5�2�:���䡄s�ƒ��pS��a���A���.�O�O�6Kj{CEF�x@��޵`A��̻t^*�u	�(#>Y�M?]}Ly����c�����L�����TMDȈ)��%�Y�ſ����I@{|�vֽÆ~�eQ�*bu�i��G����t#�V.�T)�{mu% ۰����if����z��n5NǶ�T%��.��<�掓3��j�� �K�	j��X�4�bR��bq��jQ��J&7߻)V��S\�Ă'MiI^޻e-��b�bq_p��D�{0�ۋ�΢��ag��\��8�)$W�KkG�jyr��GT�H�A�H^d������[<�F)�^�4���/oz�S���m�.#;	�T
�q���a	��$j�����TL���f��O�Q{�ց��wƴ�*�L�}!��Y3�9���zK��y�\��� ���,_�Q�����(1a�D�ɥ������%�F@�����_Sa��B��]�`.�4x ���\6�z��X�LϮ�b���(�J�����=�In˰��I�c;FWSʁ� #�X{+5�h��
�M�gb���U<�9=�!Gx��7wH_a�?�L:��/��~��T	���5kbA/^��o����t .�-�;�o�+u���)�0_|AF2�<F��=+LJU� T��d��;��R�^��x;�;�������=�r����a�^����9������|�8�Ymɦ���w����V)�M{	f�XZқ0�-'�"8 A��۹R@b��y~l�4�����l�/����6yg�6"Ew��mx�"��:*����Ip`���h�
^�D��im7�&?1�]�
=�E֩�
����<���%�����G|�HP��ȼ�'���կ��d�~�˹�୓�BJ��o������^��4qU����8�F�uBc�Vk����k�b>��~�U�D*l��&J?���'���c����;�3�`}��ޚ�Z�Ϊ-b��LJ
5^`���c*�S�} [��3*
�\�O�N�NқHϘ�\j^!��J�?T.���Y�lo�Q3<#��zXhHէ�v�N<��x�7g�'�1��>��{�9�ļ� �P/p�mUW=��VeTs,�fv�^�k��m�\�蕝����񡸌|� V�Y%���y�rnr8����L���5��h��6�FI���1)�D=M�z#��рn3Q��C��T<Q�j#œB` �&M�L�	??p��~��t��<�|�f����/#j>)^��p��0�+�&����"��*`�)N���3M��]Y?%`#��=��������L'4c˨��9B^�T�%��2�7�j�F�ӎ�g�:퓩��FQe�E�F�_����B�h�U�7���,�E�Ms��;�"��u�L��
v�:/6?����jLjT	��҈!=N�hur8��זHf�p�$� �R��sա�&�u�=5��E�2ZX�|}#���f� o��Qb��0�6)�2�b�R��̰��@�C4��ϯ��2=&v��׉VnH��h��<����˦B	�����/8������۬*��7Ѳ���
�y�gm� ��S?՞D ,�Dj/;!�GkE��,�md�XGIxaj��u7����	�f(���MbzA�w��Q���qOD��^h
\��zw���<�� �s��c��k��h.�R��`iV��?�eD���U�:�3��&�*�:�٬"7���7}�N~wE]M����.SPG@��P���7n���as��!)�Vsh��q�0�uj�>��8}�A!p�w+EK�gz��+5��E��-�&L���O+J�� �n�-�
4��j��Q+x=u�E�L����@�|Q�/��e@i7�4�g:��0������/"���%�ᖠ;������ߣ�N�Jm�Լh�,�IxpPQ�s1�w�]B'�mNfX�6e������H�[V���V+�kXuY��zP��A�^4����N�p,�m�Tҝ�$��({�AYy�{/RU 6Q
����A|��	�@:/#swoti�\ڑHvخfDY�?9"�%?D����6�,'M�i�\���;�a�,�3
�Ie�|'	�j�'��/]	�-{)E�u��Xb�!�h����[������6�X��j��<����ƨ�!Z��>�xG&�jʂϋ_�^��������-��FG�+�rj�������/�ׇ�eÆ̴
	}��ݼw	����8��f=��:�\W�>T��6��\w�
M��lU����Ͱ����sߜf�B�`�C�G�j�L��M�?��S{�4c���h��v��Հ�.���2Z (}x7)-3!YS?A����z>���Nک���0��d�^�m�Kt�_7R��`8��!��-�Wn=~a\|4��9	�` ������ ��~
d�}{�3���{�p��FM��C}�ޙ`|4f�-��*t'�ݍ��њW�
�g$��$�QSVH�WY@��[!�*x�As�{�U/h�L���d
�Kj�O� ��@���]\g@.t���j�r��%�<+����KP?�jڙ�>�[m-��J���]�N�z/�����tww������1��e!i�*�T.���*��KP���΅2V��&ӭ��*D�(�fM)
P�t���qE,���	��}�v��#E�8n�A.���= ��O��ѣ�Ƒp:��!|'��,�(\�FT7@-��5З�_s�TxK�Q~����	'���U�uɖ.��]H��f-N �͛�ό���s)\UVE
0��*������-���i�U���"����24m��e�#����RvAg:+[�~�^�f~A��>�T��������,P����{���##+��Ƒ���jǖ3	{���!o숳,X�n�v��$�k鼼�Ee��I���T,l�/$��ʧ ��	�1� �Ѫ��#Ig�w2�3R���{��(~cg���z�0�����Q���<�Y?n���q��|2��HX�\1��ׅ��I��e���?���,��|%�K��Ӷ��%����6y��G��ߟ�eI۪�CgE���lء;�n��1�'��?�r��t�O�A�:��o�黩��YC�N��K�&[Wl���~��.�d�Ҽd��+~Ф�U�^�ۭ�ڀYZ+������9m��V��u����NS��	�����}d\�^˒����~:���"oX�,y�~���Ӱ˸��0s��3j4�Դ�z��cI�����r4�e�̇��'���8S�,�m3%��c<���9x��G��~�NX޷c�����b4���'�(�7[<xz�A�f�#\��[j�m�8m��W�/����e��t�G�-Ӽ�P�)۱�ۆb�W[�aS_U���N{���=�� �pA�oK����=V^ �b�7����mR�)ZTjr��Q�tX�Łϰi�Vn��m��\�kk���##��~L:��!�����Zg�g�Q�d�%�%���`�G�9@�FrL��T�l�ٵ+zZ�<�&ϐq4���i�̎�Bf�[F�Mqp�ǔ�wܿ�S<�&��_��SQ���k�{/�������3(A��)j�N�I��Xây��r��n�)�
����dl8W�L��`��K=ڨ�i0�+Ƞ :��A�����)�cSO<~'�z�{�!{5�1=`4�w *p0��_>�pG���Z��*�Y6l7ʑ���N��^�I��0H��}���;jR3Ǉ�����[�y� ���Q�@Ḳ�O�B� P��Nh�P�Bܐa �o���@���Z?�a�fKb�I'�!�=58��R���W�����~�<��r(ض{�x�͆�C�c�e`���<FP����}rj�|&���)5Gj��O���=��Œ�hK���-�[p�ɒw���K��!����$��%�C�'N_��:���qkdO/gI���NCKr<��=�8���+.Z�ؚ�v<H��Up�1�r���g�iE
��?�"�ls����g�*� 
;wEv���� ѐceШ~�Gc�].|U��g��)�w�^�@r�?��ff#W�9��0����2^����w���$b���}'Gx�fڒ@恭�Z�H�;�G��oLcO�Uw�OdI+e�3D5�Sc�!�����-J����p#E��N�@g(k���羽ނ�����'���!�й��^��Z���t��LdCl�h��3��|��S!�f�`��Л���}Oos6d�*���瑖���}�h|��P/LT&-��s��^n`ǅ�|	��#~���yV����M&c�B���`��E~-G6
� �9�yE �a�K��j\2��?�w0������\ՔY;��!��0�Bz�)�A<@h����.i��4!z�^3M/6.;ÿ�N���w�(�Qc�3�*�N	�?%�y�ٟ�0N��)JOJ�����7c� ?[drT}1m5� A��n��[!���MB�Z�{�k��;�
L� dC��pa
R�{۬���gn�����Z7[[!������������J�'�0�3�J|���J���~����L�>�L	�NR�*i&���;M�?�prFGv;���� �4m�j�`�_b}���d��5�'o���F���.D�S(<Z`�ooѥ��rOs(��>W�
�@=d�������X%_;���.���^�R�l*�{��ܹ�����Z�,�P�I>�r׉Z���}- �V7G̥����YD�l�z�����=w.��0_!`�h0S��&��Uy[4o� F���w��n��x���`��\��t44F�/�2�ř���ܒ;��k(.)���{�M�JL;e���"�)	 �U�5�qq�����?��0ߩ#��s��i6��2�J����hy@�J|�$iJ�����v$U�<����J bP�v�~N�J�YŔ��}��i����8$�Uc�]yi��6$OwD_n��3}rư�Z��`�,L����Q�	{���#r`�U>9>��@%u͸����l�l�F�k�z�&�Mk���y(�Ė��wd���ĺ��W��X�NI\������J�s.D|Ao�:vPQ��5�%���j����(�7|�i�>�<��z�;��:�f�5�]�f��W�7�?hU�	�z��J��r�i�{����=�h��e��q4U-�l/>!X����,��U��yw+��U1u��]��T�&A���l=����;�s�_�V9I��Swڀ��g�-�Y%�E�ⶣ)�6�B9	��miޠ@1�iS� �PP�I��^w�^.n����h(�)+n��@>J��s�,t�Sg���PhX�P�ȑ,��2��"��,��]ۊ�ų��]n2/�wXv)��� N�5���b�_���}�0��
`���!�"������};�B���'UǤdRv���X��͙��o�(�}�d��;�J�c��ޮ�(	8ݖ(r=/mz=�h¬��R�#����r�A@�Ft�����jHݒ̧{
v���GP�:[]�J��̔m!
���?�8��to���T���� �[u��}��[1&G._�Z�U�"�]u6T�����޻���ǝ{����4u���0jW�#R�D/�*���-N�J��%�ߋtŶ��o-�D(��gJ4��G"~���L��g�_v/Ŗ2�dc/�� �y�'�MI���s�<q��پ��}�A�S�Jݴ���Fp�n*�"�%o:$c'�R�#�-'і�/�R�-�P�\Uj@F� �0�1 �uQ(٧�gĬHl�1�P��f#�>�P�'������`-5�&�{h<h�{��W��-1���pR�nt�KdO�^!�*C��,�x��<�?��L@��z%�֗�<p�v_0�c9L����B̶�p�y���t	��c�o�a9��bNdm�䡨�����Ad#xL�\o��.����"������N�W�����H�����-�W
���c���M[5ơQV�lƛ%c�3D�O[��:��PPJ�(�w�y���8'��	l!��w02��G���ǲnzu�����Gi�e�9N�a�qҳ	��qN�r�9,ʼ�di$`()|`�Q��ί����pw)�nQ|�f<��Gv�(�;���@46j"b�Kq�b�Zn��ʽ��� �)��q\�퉎���»�ci���2/Mk����W�g*�WI�_�-�����u�B]t�x�[bE�,�W�=��H�XS�RT*�cjw�.�N@%L�F,���B�ʶl�����K��ShNLPY]��T<����"�[[�D%^�O�Li��E���� =	C�[�2��_}2Ge��=�zu!�u��w�f��'EZo<�n�fW>?�a�߿?�ٰ�6��Wpg��{��c��h�7��Y�}�s[�8L��)�o��jXpN�F��]��@��70����b]�x{Z�H��!�ҏ�M|bݏ�O]q���0�Cy��}4���ʈ����oqk����_�K�8u� �;<ly̓��r�s�F?^<&:q�����Rk�Yy�,��#�ـe2BL�ݗZ�4Ib����m	7SeH�����m^V	�FX�<z�Z�"�Q����l�۰"l��t(��ew�l�]�Q�7(%c�J�]�����n�s�}g_�>���<����NָF����~I����,
�����)l�Dx���m�;]s��8�o�Tz:<2���2�wr�[��ʠ�b^�eMyϺc�(Ң�^M���B�D�UŅqlJxY��:1���Ac�T8A|�vN�n2��?��P�f�޻Gh��\DuQX�I�+Y=�Ip{-������O�	o��ϑ�|¥�Q��*�N�U����c�T�>�?��VF����j�i�������>��w��*2���t+ʂ�����$?����~�� ��(�EZ�b���S~�^(+f�e%O<�~Vʽ-	�$�|E��d᎓��������E+���l����A�ű+�����K��4!=�2պ
�~�(�#�L�����8�T��S��b�	;ɡ��bS�dYq:��4���Jϋ�#������J��wۄ��N��j�clv��Ķ�핧܈Rh}촰��'�
C��C9�ׯ��Pv^�;������D�~e�����`���9� �~�N\�)����� Cm>�>�b�) ����MQ���Wp����Մ�g�4
����Ҩ��B���= �13Q�L�R'yßk�e������ �F9��_���0����g86�h,����&x�f�Ƭ�hj��A8lR:k�z��^��N�E;?m�u$U4�2���xf��x٩�����#p�c%2|8Ї-P�+~����_V��nӾM�i��ol*�aqa��A~�cf��j��" �8��l���E��K�L&�&]C��Q�[0*�����c����.x�X"����z��+rQ�$%�,sA�!�H,�BT���J���]�lK"�O�%��ۃh9����t�Of`���u륈��k�؂�X7��<�^
��Dey�q���0P�Bٓ����]{�P�Rcu�Bl���+�5�����P�ϙul�3+�qC����B{�$w\P��É+ ���>�Y��姼��0{�?�!�Tc�M��⁗c���o"(V�ԛ�A=&^E
9[����n���ԑ�� �:�i�NGY������LT���m�vx��G��֫����T��8���?34�ah�Cw�����˵��?ƨ3��dQ�5�X ��*�����3ͱb!���
Ck���*ֶ;� ��8� �3�ݱy�/7`D6���7���n����ν_��A=[�D�!�+Ȅ��@WI��X��v=���TX��FljܸG�2;y@����U�oJ��q��e$|�e8���P����|/�����m�Q��s,<]v7r�y�ܸʵx2FW��0��o����*�xw@g�F���Q�9?<�Y 7%��	���7_gX@D�o,b�A{��,w�s�jw�1V�/�3�.l��$��m��)=#��7���T�k�-�q�{IhR E�>1/�
�E�>�\(0�j�Ve�u�6�`k,>Ӄ<#�;��2�?lx*(_�H9�U.�f�X|�"g�*poP��yJ�Y��fr&)H�LjU�Q�,��1E�w�;Oe��!5_ov��p�`q,�7��t�"� �)w��lMI�ێ����SE��V�]s83�ԴA�T�F�֟0��Q���F��ž͓N�o!N)����݅ۺ5�q������HE5�����e���(��AVo�(��i=w<��#7Yۖ9�e��pMV�L��3��$�ϒ����:��a�V\@ߔ¼z��>�?��
�D��������8ؖyn�S(���E�`f�[̃MJO���g���F�	����o�:�����E���>݋Ժ�j�0�>���V������'��iZ� ��ϑ�����} �ѷ��KEMl���c�kĝ0AuZ)�!ʄ�	��H�%�Q�A�����{E�%�LB���/�An�c��%)I_L��; �:}n�4D�y�m>�N�imE@� ��tJ�j	b.�=�mqN�U\��3��N��M�x��-���4��K�Vv�@I�����mpw�>VǙ_S�̞�l�>I28�@m�M��	��:'���q;���(.CY.��nf�ziЍ�S�h��YL����f��M��X��rh�g�:լ}X�Q��˨w��mE�v�f͈8��l~p���?�ȫa�Qu�w$�������j<%8�垴ޅ�9?.��A�/LЅ,rP4�Y?�j�S�+y����9۔���[p�ھ��0�U୶L%�|Q*�j�yX֟��զ��y����"M��W��B��a��sp�E<V�/�S�7�̷�6��X�6���Kl�����&�q5�xu�O_=L$)6Dp���*�#�7u��o�,W��	�Y��D�9=�y��Ju)��d��;�����P��$$.��i��M�R���p��5� ��e��S9抹��Z�7_ͯ��
��P�(��~X�A=pbp�����vޢ�@ݗ9��ԃQ�O2�B	��*0M��[9�$��\tI%TP�_�YҖ68Ѝ7!�Of�a͠g�����)�u+Z������l͓W�d��&�6	����c|.N�E�3�?�<�S��C������ht{�nm��B�{�`���G}�
�>�*s�<A�c�A!�š�� �7�h�A+ZQ��2��~�S�SZ�*����K�����L�O����EtF�4�����-*��
j3
4=�3*P S�� �*�;.�Ō u@v�q+�)��*���\��Z����z�Az�}U�r�X��Ƕ7�7o^��"�՜l+Β�R>�Z/����
�!��!m�{ȸc8
K����;��7�Q�1�0�w�z>H���O�F�k�\��:���\���z��0Cv��-�߳>��9��u�K7Jw6��|�V��0�XS�=8Q�V�Z��R[b@"�a~����U�j!d�y�e[���~I>C�W�w��a�&��c�W��\.�?}����8gN$z��'T#ȁ���K����Z]�i6����5��.����>���
�������U:�}���p���$��O��ĥ���T�ʄ3l��C3ti0[�_��鴂]�/����6���/�Dբ+vL��[�`�H�����
`LW�H;]�$�O�ü%�
d�״wH&W잨�����)������a8H�Y�"Y�{�*�����a��������V�0�nU���h�gl���h}�F���E��&}��Y����<h��Ώ��|�T�0��H��ra�y�55ޜp~�^�m�vk�Re�j��"T�J§憧 ���V�^2��o��I�;��(�S�I/�Sǹ�t���RC7�w�H&�1�WLmX�&���H ,!H�xo�Gc+�\e_����q1]��Y�w��˴0]�����3�|�"�}������a,^{k
�D���%%4��VR�yD{c�[�ؓ��ǲ�>�D_$�?=o�.E�<��'^�t��p`�jyk�6|�bj�	s;�ɠ��&shL7�%���\#{oH�?�a�vʺ9�<�3��/8�S�˷�o�S�y���o�I�V��#��+ڗ���R�0������
�	��6��Oa ���5��N��b|U��+;��P��gƔH�����B�	��4W!��� �t�JM�-�u�ū�MA���Z�K��aX�W�d���4�c�QDئ\f���o���F2���C�: 0��Eokp���K���(s&i�0Y��FGS0s�T�]��Q?��c�\�����#��O��)�#�z�dg:�0��|�T`�䒑WU��v'�1�v������o�@���{�^ f[4�T�3O*f�$�:
e��0ei�E^~h)�����B�>��c��͚Q������j4�o롻�~q�.3 ��_�D9��&����]��d2�Wb�?;��oC���KL�(�V*r�d״����oa�t�̊�������P-���a��|Hz2��I�M��5����4K������$�R��0忕p`>4�˗�r4f��0�������������m��g�E�' �&D?��@u3l3�]ޘ���?�y�aV�u��`���� R��c~}��e��'fU�8�j��F����鄨��|�ی��W��򊍋�M�prg5Ji�^w7�T�@ic�]x�7&9S^���@�q����>  Dp�� u�� ����Ő���g�    YZ