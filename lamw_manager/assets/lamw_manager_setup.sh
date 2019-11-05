#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1323574573"
MD5="2daa26799f9039e531d98364a468c6af"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19589"
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
	echo Uncompressed size: 112 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov  5 02:17:12 -03 2019
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=112
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 112 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 112; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (112 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� ��]�<�r�ƒ~%���Ēc�"ɖc����(�D)�IljHID ���l�>fkN��}�W��v�`p�MRb��b�-�s�����4T*?��
~vw������J���<�n?}V٪l�nc{��U�} O��gF, x0`��a͸����~J�����ӻ�Z�y��������&Vߛ�/��{�?>�����[y �������r�v�=�����?E�x��3���8���|<f��/=ب;F-<�Ԋ��4���m��9죔N�K+�&@��*��ҶV<�a?��H�����w�{n�l7���F��CzHq��#h֏���.� X0�N��%�����(������EifϘ�������K��<����s�1�j&�F���&��6}%�,�:k�%Tz"�d��llVp�>ҽ?��<?
��~��i����66�v�t��7��A��xܧ��׺V��+G�U1� �t�D�� ��c��K�C��&c>r�4�� 9o��-�x�h2fb���V����-W��5�j`>���a�1w�BvC`lF�� քٵ���雀{.<�.T���֮��1�8������m���N3J廯"�u���3AQI���������c���;o������������7z������J������j�\}Z�~�����E�34#�0g��g.�K\�E����Z�}ʒg��T���)ݓ��h�и����܁���<��op�E;
j��� ��(�pG�L]���4���0pY�l�B�OA �F|�~����.���'p6�	��]�8����#~`�y����+i���VuxX]���]&���>i/ VԆ��	9��������a�q�N~i�Q�P�o���.��������"���q�f����7��x<�� "�c� }AѨҶi�Y��alI:t��bⶀZ1"�Nݾ0�ʉ n�zSw qT���Wm"��a�:�0x��I��h	��$Ӎ�Ş86��J-M'�Vx�33'vnjA�Q��=��x$2 �'4Ք�4h
��g̙r"x��$)��껠$��=A )��/���l�i�*��^�06��cGH{0�A��mS����q��!��t�T<a��CDT�(��|3G�X$w)`I�K��$]}�0����Dk��^��N5��\~W.��f*���F��)
{{��S(
D�1X��_ap�2�c���b~��~�WIF��,�|�K`��:��l`�%7�J7��[�_�(%@��C֏��W�E+�n��<Tl�ؤf\j7��n�cu�ͣ��ƁU�t�Ԙ3b�`Tʜy�@⼱a�*{��y����MBW��X�{��Q3��we��JtlB�P��i�ԁ��X�$�J�.H˘�H��6����>�m���)�eF'q,Z��b	LIXȖ��6�� �jE*a��8:ː�~��֐��PJ@�� �
mٷ�r�)�Q�K�'���JwEz_3���xgH�X���P�Yٝ:N2T��T�ʐ��
��%��T���HOZ)�4�PvHr`P�h@�'�cn\U�c�/�pU�0�	l���!��{��e.����-$�N�X~�A?ԣ6�&��"�d�����oIy����je�b����C�JJ�c������U·�t'��#6�����ج \��
ac��_;ia��KR$iӭ;���Ϳs����M�� ź�sRj!G�2:Z)Z�RC\��;#?"2RӲ�Mݼ�XJ���X��0BB��o䜊��&k��·�jв�4���5����l�����hpGy��D8�#G�a��S��a�9�w:!dô�^֌����Uٿޢj�x�'tp�鿜Ȟ0<ֹc�x����Ԟy���1\�)�B[m�>�:_���?0��h3AP�`���`�I��l`���2�&s��j5� �hs�V���y�"�]76.��؛"Z
��x/0-�!�ր�OzC���i�p=�;�,ڶb#���'�qF�K�A��.\�������f��߹<n�~�J%���Br�OqfVh��=������5���F�~��s��?}J����� ;>w��߳��|�o��������;��$��jy�2�<��t�̓���R���`	��&	`�n'��`$��"��n�w�g�P�z���ӳ�� ���=e	�� ����< q�ӿ{�v�~p/s؀����>��8a�����lN~ ؤ�����
�a{��}�0@�n����\S�G���S^ryD7Iq�D�S����Yo�FS�>/�2��/��e�,:pM� ˉB�����z�.��}T���L��HЩ�hl�*�J�Y�i�k���gnip���>sJ^0��2ү�QX����mU�����P���K�]?�����aPv�M���a����0�!1j��p4��h6��FM_���F�{�:��[�Ze#3SO�N v>#�vn����[ڡ[�42L�q����:&nj͑;]�W&�8�� ݉
�%���5��R�-A�R(�]	g�׮'��{ĢO�D]���9����B�
�!�'�O�t�~|>&`�i��l���k7�8��r�O轊�qF��K�{?3���t��K��F�"a�?&jO�QU�,�4盛�R�	�k!�S�\�T�m���F����DH�k���:��3��	�i���H��)͢#@�bPV)�J��\O�Y�㌫����3_�@�tO��f<���6�E�/�4�N�~�(I*��Ɛ��0@Nf w_���_]C�d��R��%ԝ�裾dw��,]>���ō^/���ݏep)<�	�
֗�n�)�rjč���5���iJ���h�,'q)�"�	����B{IM��ԃ�8$�ݽ��F%�`�Ȍ%�
v��Zc��-C�4�A��~��:�w^5Nk�U�}Z���BMZݤ_�=��iu�rྏ�^�����>l���A	_��8<��F�)H*�vc��zqK�"�\AF[g����hF��)�bJ٘l2T>ھ"��nKYIx����g���L�0{5���D��u}����Cf�of�Ǹ:iu���k.?�lq�����R����UF ����p�B��<Tv-�Z�mCgE����v���m���d�s�eb�%����sv������ݎ��@#�1ES9��Tn&ƗV�R�x7��7��6�CY�\�<۹�{T���(�b")�J���Q
��<�jd~|��|_ܥ�uh�������L[&�|ج��[d��'��с��Gլ��̗6WE���
��V�i��M
e�E��A'g�������s���0c��r��#�V�R�6럳?��_֌�������qD��}t-{�=��<E�����
��s7�������������������g������[&���V�ǀ��q:�;�O�{:�ف���=e��~�}���� ɪN���7rgK��y�@�n�=q9��G��z<-��!ْ�2V�5-w���J��O:T����B��dY0�T*��Z���`(���f��z�k������ƒ�}	R�%i��-�j	 Y����N��.�}v��={�_X$^Lp���‣���9��2s���K��'��z��K��x��H`��e(��Jn��2��J���x�\Q)��3�j�Gb�Gi�Ǐ�������	���+�a��m>F#>M�#���/t(ݾ+��H�q����+R�Iɒ�� �@\V��{��w���WgGR�U!��B�\8%�є���3N��tq�=��]��VԐ|�ǧ�D��^@w�T��P�̴b��E|Y� d,��ī �|�FU������N��ɛv{ru��`~d"7�+�=�u�^%�@���Vhɺ+
�t[�r�Z� B��4AC[Vu��ʣ�M�'�T�ZP���\�Ť8_e��������1��JݩO� X+���2uzD9�ޅ �үĕ�{�G��>Ж)]F�����S?h�ۈj���/��l<AbX�����/����-���187���3ـ��/��G��ĕ�EUy�h�G/2�F��sQFJ���	LCa�ew�:w\�*�n�`�u�8��5Ok�jh�vuP�z?�A�:��(n�p��Pz��c�QZyyE>b �j�P^h��|�kEf+[��/]�4���h�A_�mU��|al!��Q���+p���)ɀ��G^p.ռg;v��!������ߤĹ��ʝ�.�prwrkdD�q�yr<�gL&�i��(���$)]�)��mH5���8�e=V��kKk����Tj��g�:s�v��bHuH�.?�4�M3������O�`��9�E��JnVqb�I�*g/���;c'v;�o��]�i��z��ߙ�ь�-FV�����-Mȣ�;�� J��l�D5!1���@��-|�-��.K��Z���So�X4V��˸�l�%�p�����[����.l�G�CF�����Mw��m����@���N!E����̡���"6�v#��������2��u�t+86w��s�u]ݫ�Ò�c �+��/|ѫO�x�4��n$P2���e´��=����`��P��p���C��yA�.�%G4q:k����a���l�pB|x0�����#�$������|w�R��uN��}H�,'IZ��[0*@jf"�����lt?hK
+��g�N�!�AؔH݇7(,x�XU� ��4ޡ�R��vdE��i0b\�Y�k���qY�(#�J��r{nX湰�N�N<�{�Oh۵���UjLxx��vԖ_1��+��Ε�^Mʼ����Ve1݆��~�M�D�nz���6:���9M:���u����E�ll�0��&������C�V2&��_���:��:���_5:���ڼN��q��چx��G*�i,܋��42'���E�@&cM!*g]��e�^2����O[�f7AN��.Jz����~,�co�����t_��-F�ٰ��N��	�L��,Q�Df��Z�o �D�5�¨fdi��&nawJy��\Kѭ���y:�7�Q��y����/�~��/*�}��>9�.�����<�����sK��L�%�[͸�����E��*>���l��s�h�q�mtsj�"%� b�傶F�V�fz�# ���h2���b�P�S��^��\��_1w��$YrT������J��UTW|ţl��r���o����k��
�
����*��uݔVg.�)z�wa��ve��H��ʪr� ������|�ժVG�+�|��)G��*��Қ��eK�巛�lU�,��¬@=Q_GǵP?5�.��s������잓�;VH�߰`BiF�C�?�[�U*GU�@]�����8�\�RQB^��e�4n�QU3z�G�fMުY�ξ�<�eEB5��2�&#�'L�	D�L,B&���_DIϚ�o�E��� ��A�:����4��@0����j�Z4.�=ّ%�C���x.��+)�Q}3�WRjA�
���6ruP.!��-�b�^�py9�L�:��?u]���V�e�����JV��e@��܅k�Z(�Ǹ/����3[A���M�Y*Y7MRI��[-���`g�>�	%k����-7��F7� �H�?{���
��1�6����o�n�H�ݯ¯h��#��$EJ��dzF�h��rD*N���HHFL ��8���p^f?�yL�ة����� )���̈Y� ��^U]�ՠ[oG�N�
�����RC��@�h��u4!;���aC'a[DST�c���$��)c(x���x���{�U�-��y��}5�Ղi ��nP�_��@Ig�DaZ�@!f�F��Q�W� ҹ���qIM��p��膳��R����:"x���6@5�#H�,�'p��T)�t��%���-Gh��[�B>�פM�iDD�FT1��*�Q�f(�Y�j�0Q�k]q 09�"�L�(.�i(_Y�vi;$����|�Z�S�K,�.��%�*du���h�&`d�3�zFMv�	L�d6E[�|��J��s�$	�5[��5�7K��l�S45rQ�xE��Vk8�W� <|�G��vs���iCWyl]�K��֥|>U�8��SVVo.Z�{��-�V���M�81԰�1$N	�5�ee�?��9��U�{��Pe��A��#�d[����x�a�`��������x$I��_ه%�{�f��d�)�Q���t[/��u�n_�'L���Μ�vlN�|�qt��{�9��6-V��t�)�L���g��s�<Iy�k��i��-;?Y>AW��s���/-�ﹰn�Z.�~^=՗{�.��Z�N�?X�%HIvR�xx&�=���Pe����A�[~w��g�0,-���B	�x��������k�,ӎb+��	&���ܔ�6����/��/���V.Ô��ju�z�c� rs	��zN_�n��h.�Y�ʅD��Ԟ���.�2�'�(!8'O}Ѭ��ןN}�B\V�U�y�%�n�� ǌ0�0\����Zp�_�䯴]08�j�����c[�4%���GÜ���UZM�����7���v�/�vq'˯`�p�¢>�:����=�9�Tw^�0V�JT�U̼"
W�s#ۗ8K&(\�����oe]�����`�9�xsW[��gΜ��Yx�U)w������E� �dĊt@�͹t���V�ԟ��|Uf+4,%���
P�fǛ9�uB*��"uE���y	4jX���UsuW����,"�Ԕc7?��'����wS�yu�ަil�
�E�=�V$�"3n��i%��Z��ޖg��bU[��9/��[[z�[��˸hМ��s�;�.��:k]�>B�3X~B/8b�y^���%�	UYL��$�"	��%�Q��I-,�5�Y�����B跮~�V�'k)�L"n�v,;�J�D�v��[����cC`0�O4�v�Ȫǥ\��D��P;i�f1��j2 �km�Ą��0�t�iHa�����(�y��-�a��|E)��$���>�6�&%��!��i� V��K��8l��
K�o����4%��A�>XL�a*�$
�'UL���
�F@.:�:��(���y��ޅ#)��HP�E��U�� ��s�GQH2��Q������� ���w�P +H,s"���r��z�+��%;*Q^a����5zc��3�ʘ�Ȁ��إ�@��.c@���@L(Yn�����&}>�)2 ��]J�ͳ�P
� ��0!p�`@&x�x]����L@B�x�j��8%��tNY���H�ga��Η� A�����DR0���=��#"�)�χu��[x�	��f�8�`a����5znR�}�,s�I9��3e�=߬T ߘ�&Q�7u�Ԭ��+�iZ��v��lYu�be�$W�J_��T'X5�T��y��0.Y,���-��%W���ݫw!:�
�>nc`���*smEX=�Iv�?/�3�Gl+��
i%ꌯ�vq猨��	��O��R��l)��(�5o�4Sq���`C�.�)߿��N�a&��ړ�*��u����2���b��a�xK�qÙݽ'Y|2ߑ�m$q�^���q"�����02[�����b�P����̚qxtS}c����H%:N1&��j\���XbÓ��i�n�!������L���Rt�%wk}��@�Y$�3���j��_��I��}�W�HG}^�� ͐��wj��ǋ�e%G��ʎ]zH}�-�䘝�+Wn�.�1o.1�s��b3�ō�Q������_":�#_��g�q H@5�����rE�)�?͖{��u%dt�rF�x�з(]r}��HX9F�%�h)��QnQ����� �pA�ժ*=���0��t}]�1L�*�c��E�i���}ڃ<���{m`�+��A��0欱8@�f~ 	��(�KXJv�_�čy]�*�Y;1�`8h�	����h�4��1oV�\���K--�/�qM��9�?�� ;'N�x��W8ۊ������s� K��
��P:��h��DS�"���cw���!���t�n�;�Z�3�4����r��T��'�G���+�������+�����΍���<����������z�Q��ݸw��y��� �s �= (y ����8����Q���	�I@��=P�r�M P7'/H}&l��X�{W��ǜ��Q�d���&��MR��{z�\��,�ƀr]�V��zi5�ͲiN�<�����vsC���t�O�z������-ScVU-�U�]
W�ku&���f�*L}EZ���A_,���ԿSd�p�I_��B�-[��Z��P"�wE��H�@�X&T�j÷\b����!����xe&6���[J���J!�u!3�
!0���M���7��R��g1L��$��M�~޺�zg�V�Ā���B��t/��G��UW���x�P�2\@՜cu|gY��⼋�{T����/Ţa�Y$*5�����,Ew�Wf��/'u����B^�M�{[ё�vY&۫R��՟�5��c1�O�;�e\��].b8�	�s+@���2��fr�t^d�-�bf��*ܓT�9�-6|Z��jG-D�7&8�]UR]�Wr�O��<�_��B�nc:����d(�Z�Wnb举����D����kQ�F+�~�nsK'4�K��q�h������Z�5��1� 	����K&�js(It�Z�	�B��	)�ʔ�,hh���ߥ�W�*�y��@��Y R�y�R�BV��0���G�+�^�0�6����?Wx,	i���݀����gH�~��Y~{�hu���8w �����b8�u�AB"��W��d� H�N��jH�]w��s"�1
��5W?�aW����τ���N�����l��L����o�$Tk�.�٧�:���K�Z����h��k[$������I	/���d;�t��M�j�������X�>L���<<���)����?�s���&y_��V�dn�Kξ������-̱hg�:��h�P��ڍd��,��!�j�	VQ:G �Q�n�+�v0�AQ��'B�#<h��Cf��;@R3^���]�+�||!�����pH���by~�>r�+)i�ķ��]&��ޯml���]�;J}��-/���ʙ���v����;����z+�:4m^�k��4�j������@~�߇s���ۃ����m:�َظ)"�IFh����D�N���1�!�j��n����yo���<y���0�f�l��ղ$�ix>��`6A�9^����!�
w��[��0,�R�sgh&]BPB%�&�Ƚ e�j5�0��.͉�Ś������S���^?K"�W���Na3�D!������s�Ծ�3�骀v�e�έ�t�un���q�3˝�|륙N]�O�ky�XtV�sΨ03&�un�ʜ�Z�}�k�
m�Z.D��6B���(�~�]y�YZ[m��mQ������N�Y�P�jJ���D0&ĥ�Q[qj/��b�	GS���%뇖n4��;�"�;�w��� ������F��0ҁ|	��_���(�:�߶
���ݻ�us���{�3ƫ�j0���[~�#h�}�r�A�a:��x$�(C�N��u�*s�h���׹�T ��&�ĵ�ɓ��^{���g����z���w�͐|�Ϗ�k�?�0R��7�߿/ϏO�Z�t4��|���C5�,~Mf(VIf��a�^C����A�H3�<����l7�eg��R���|:�˜�:5_��uVt-H���yV2X9!i���gո�3]̈́ ��X��V�z�{T
���t�"��+�g{�gL���������>��|��W᠗�}?�������08��"��H���ߺ���Q4��Q�e��l^��pTKc_j���=+o$ށ�r���V��i�����N�}���Z����G�Lu`�������e��)�w��&�Fk|�`Yu�����)Ϛ�LA�
m�(�KM	uQ�ڲ3󐮛�$R:���+p�XVQ"�պ�0��U�`k����f�A�F�i��5Є(�t$�k�򅑗`�Q��Ҽ��A؊��V��[�
�HZ���`��5���_i�8�֠w�"�N����'�`�{\^�hŋ��S�
C��vX����w���h[md�P��]�,(�D�+X����W=~�Xiߛ�h��2�?^��kt���QU��5s��{n6��;216��NθV�t1�F�
aHB^�8�qJ�:��8S±@��N��YD���;-��i-b�UVg�����g�,@S��M�Ńx&q�]�������W�~��Mª�5a�~�W��
1&���7�Q�%E��}~爝��U��]�K������e�{�6���9n���E@j�"2.&�@�?�]mZ�:��j��Cst[q/^�˒/,F�,9˷���!d�3�anYW]Mz	�x��� q�ۗY��ݶ���E���-Ҧfh?A���ġe��!����e�E�BF���'N%ڰ�v�]��u&�L��m��ɯ۶�F�3�9��^��G_�=�}���I� ���1��~`��az:�H�ƹIy�BU�|��[��P��Q�������Z�DrN����P��,���C�Okc� �3��=9B�@�9���#I����m��.���^��:�C�VY�N�,:���@��{�#ץ�)���;�4�Y�r;p/4O's&!�g �f�9x:)��yؒ��<|���'�Y+%ҿ�9Ʈ�5nU�F��*/�	J�}tP�,f�p2c����,g��*En�t��S� )Z��s��@So��%d�}@ !�&L�2(H�	�Yj�/[0�+[���h�ōx���^:��g�����,�������g֞d��k>x��V>�:	����U*���T�Cgd�8H.����r���Ø��yV�� ��H+q�*��Yfƃ�����R�e؏�6j���Btg�Z��-��r�v�����ѳ��\aJ�)�ВS=��޷;�O:�����?�M������ M��އ��jeᇬ�z-�Qޡ7K�����a��m�ZF�l~IBgF|29?������P�(���6��]f����|爷{�Y��γ�;;f'�:JP�!�������^�z@�v����&_���?�Y"����YتM�L�}���Tdj[݋�
�%���a��J}�@�8���탓~��ޗ�'�B!ys��̕��� �{1���\Q��3����_H$�9�p�x�Y��@��a^��K���K�bC\=g#�7T3�*�0mc�@Mjo��[��[���n�s�}���	V�J�� �ߌ-��J*:$O}��W��F�믲�7�PA�C�,$K��u��b.�!J�m�_�%O�a�-�1�N�"��\.@�l���d�X�dy��"��'��XEuh92�V�]�$f��m_I�|7&��.G�҇p0�ʮ�(�|xU�d�����ǊQ�b^�Xw���T�%�����w!�hp�Lx�64$�Ӿ��@;w O	��4��X�t��*�E��������A�$a��RID�F��Yo4���ּ�����<���B��-�G�R:a�hӨ������5J�{�K�&J�=�{�/���](�wJ}�ّ�y�|�ky�Y>�7Z��x0� x�q�f�Ԋ�=�sfU��	�V�%=�T���ݖ~I��8�H1>�.����l4�L�b���uì�<t&�9)"�5�W���#qC�ڐ)H�5��<�]HV�uOkM�Zݿq�`i��9�LZ[���C&��s��iŢ'Ռ]�t�8�-� ņ��:υ	���c^�b��o�����rzĎ]Ǐ5X|>��U��w�3��5�]����f�C���PY
J���8��i�-є��t��"�d�f|1��*����%\�ڰ&������ٙ����Ħ�"�3���Y�X�Ꮏ���"c�c�G����;�`>��֛@Ww�T���%(Q��̄��s���w�O�m� �ê[[N�JZT	�����L���V��H�si(7"EK�e�a*�������YgW��ӣDAV���,�V:����}b�
���7���6���&\�`ܫe�/��¯:Շ~i�\)�^ٝ��Ռju6A'hF�,�k4�\%�U�ʕ�+�D��y+�k��WX����p�iQJ��3��ԗ��fP085�/��'�zbjD��w������V��o�9#E����Q{��m?�l��r͂�=�N�P�xZ��p�F=&�#s�y�ь�~��N��x����?R�J����4����A\ˆ��y���o��xF~�M>�{OQ�d���>�j�$�(���P��Xg ,if�֒�G�	�O���������Q���L3�QEƼ��[�C25�.�#Xp�i�_p�K���Ҁ�C��7�F�w�y�`��6���럾Gڣ(t�6��Q��#
��#��Cz�����0!�ӏD�Г�e�Ad?��?�M��o6�i:��w6�������D��;o��,����2`�1M
�)I��û�IDͦZ�A�"i@S���(���><��#�D��6���9����0�%��@6��R�JZy2��o��6��F�1w>��=�:�+y��Yk}��Ŕ&�+���&qjJ�E.E�;x�_s�iu� J�(�Z}�NЩ�NNMM</Jo�+�uFp/��t��*��V�qJ��������P�E�+W)`�Q����45/���ha���z�H�ˢ��a�iP�&J1��C7�X����C�7^c	.��	.�j4�u^eɲFC�,�0/�.�$�@1�"I��t�w 8��Y:k`�2�X����Eq>+��x��o���#���=|a�W�TW�dD���-K~1�tAC��n�0��qft�|M͵$S�Ǘh�(�0E�N�7�S�`O(Z�4��ȵ޸��0�����;�wr�
+��m>m
1`�c�Y�yJ\LLg�+#M����U«`�������ysg�.��TK�M4��`�>�۾z>�5yhM���%-QW��stʵ2B/�׿����-`>!t ����|T�c�;-�α�a*#3����o-wD�x�8"�v�����;%Ms�9 ��*�j]���o��l9�.y�O�.AU��u��/�<�w3�ܡ�o���h�x_�1p�v�"����ș��q�^'w$ܖɝH���}�z�z/�j�h��ɽ�U��pV\�� �A ^+-��`=���t��p-ew�/��8�������Ϩ��"����i�m�z�����a��C�R�1_]�U��R�<�T�yS�E��b:���C��$k�ϠB��Dv���g�����O�$�z�et�f'�q����zW����eֲEcY�V�0�����e?���m&�3!���S�_[d�z��ܸ��i�����{���5����>R.��o)������hg}7���	�����z9�����L�Ο��yy�f�e��ӽB�G�j�
�V��Y�8]*�I�]�N�.��"��ڎ���ڂ��u/CV�L����1i�Ii�tEժR�R磢[˲ �\0�	�0be ��\,I�<���6�܏M��Ť33-z�3q�ye�\�V��R,	�	D���م4�;�4�]�~?����e������I�p��y�����k����Ҩ��7���w��M�p�m��4�Z�e+�"�fd	�9|?�=�!�Xg۫y��\�P%t��kZ���ϻ�e�f�(�|��M٬��h�^NM�p�$�6%Y��-�o�<B ��5�b��ʶ�׵i��T�`?�����:੉���.�W\}�1T�ؕo;;� ʉ�E�r=�΍��L4d�ê̂im���OkNUŒ�'�6c���	q�p�s�N����w:���O(͔֯~���#��'-���������5�� =�<j�9	*� 8�	��ۛ��u���	��.�_��V���}����>��PeU�E����
bȣ�hN�n���j��/���\�[�.a9�s��H�jG�5��̍!���t�K5Z�]@MՎf���W�:��`o٘���������0߅ɺ��θ�g�1'C}ɗ%C�fi���U�����݁�`�5py���ȗ�:���e�k$%��Z�4?�z���)��k����GZ/_5�Ɂ�<,�%#oQdT�rOJ�ʁ\q0�mP�KG���������4I�T�7=��Ez���o�S�l��e���l<hܿo�n�ۼ��y��m����S�ɮ��-C9�	��=��!��ׁ��B�ƣ8AxOpߵ��ڭյ��Ucg�9^�������<h�6����3�����-�Y`�����CY��yR�-#��_O^�����YT>{9�Z��\C���I�!�5r�ڽH��Y���j���mt�}f���GI�ݲ��g8!��@k�6��eUY�L�� y�s��������EKb�qg����_��!�ݓN�����3a�I=Ƿ����������no���9�4|[#���y��D(�i�[�����ˊ��4{��}��R��w�fN�#s���Q�>L�(�&Q8b�#�¢$`@��PDf�	{�'�݃���C����OV��>9~��bh��q��WX���n[�J��I��?#��(C(K-��-���7Կ��mxm%���:PEq����wx������G=-C�ҫ��"�I����6;g��$���t�6͇���j)�*=�m�
L���M���_v�۵�%�mR�#�pT���Q�z,��@��)�+/q!�F*��[����x�����Z��)�y��$W�^��O��k�ZC�k��ϭ}WϺ���.1�����л_yhsA��E�i��K�6���B�ä>�6�ʋ({3;�~�qo%��hƷ[xQ�vk����~��O���hXRE�B��	/���*�'��^�<���f�\�sq�`XEek@>x��_��g��T�t�R�^�S{Q7�лP�l��P�|�Y�/)hڛ�L�*L��=O��?�WTc�$v�τ`V�*'O2$���)�P����?���ȿ�Ϗki�::������Y��.0�SQ�8��f������i[�^[�;� SwEe���v��F��v��F�\X��I�<	CnqG-�OR���i��j�|�=[��щ�j�8׮�F�.nU��!�$5d�4��wV��j�޺#��4̠Q{X���a�Â�p'pxQM���>�Ɖ��&��`�ېш?H-pԊ�����k�U�aW�	]V:��C.���晏� ����N��>����q�Y�{B�_�L��wVn��+���WR��L��*��\��Ū�`8�pWly\�3��Q:;��O�K����o����\���<�?W��k��V��d}!Q_���K����x>�)�=�?g�P9n?oϾ�=��������}�����'��w��ыN��ރs���G����:���#v{y<L�xi}�t�����F�r��E�v(���4�p6;�>�(�����E��C?di&���r�fP�%��p1�e��}�=4�峢��$j�!2Ao��0b��I�g�M��I�0Ias�7���!����M�s'��3������+L�6T�	1Ї�Lp%�X��!���If�7U��!R����I<�bk}�Y5M�+Cآ_�z�xҢ�1��1�09܊فw�E�m5u�PV��%�<�[�:6��d��m�j��P�������3��2�L_��mI����J�v��x�<�I
٩�m����r�"��:��N6�5�������b�x�uߊ��8�M���*���}qq*Yy���8K36�")$)9b�m�yA�)azeR�wA4"�\���T�׆���h��p�OB��m���#��R�1���ݣ�Z�l�0<f���9i�_�ỳF�3=�}{q�q-���7�{��N���a��ྸ���vA�eօ���漏IG��jD,-6�����?i�k5��Q+�Pc⺋Nl�ָ_k��P�$6A�-q�eh�i����=���N���1�> 2���o�6�W;%�a�(���!|͸;\r�q
��[���;�c,H�P�RON���X���{x�ɖ�����h�K�i��^U�D���m@n�ӡ`x���f�t��"h�,-8�9���<�~��St�&^G][�D�Hk_�Ira3��FտT�4�r}���:3�0%� 4?KD�:;� �&r҅�ܢlK��T�����L˭����2 �����=_a9�%�����,�ՊH~�!�e��4�	�w�ح����.�,�����BЋ^��h|��J��?n~���a<H�_���xp�^���,��Fc���{7�_k������_p���6�6<�ƿل�r���~w����Y:������ۍu���B۝]��CVLS�׸v�܀L��IȬ����;w�d��G�Ǟ`j�^��d�|6��]Uu��<�B���ãn��� �+)��_=J�$�\<悒Gu��:B�y��Ү���)�UG�h�qf��]�Q���ùs@N��,k���ݧ��s��Ϙ��Z�A<�� �d2$���S���$	fY���\�]fyq&!��`�\.B�V�0,P�>	��K��O��O�%f\�����"B�`���$˗`�穒�貨�Y3eiKi�Ƽ(
@�>�f���R�㖥����<�_
B�gjr�M)7�g�H�����O�l鑵��Wbֽ���W"��F�Ґ�
kӺ��,y�h��P�VU����,>s7R�觺��Ge*:���Ǔ�����;I��M	�.@�,�G.�\2R��1����M��q��7�A<�d,@_�3��Y/�r]�Ge=������diK�.m�ȶd�Bd1I;\�V�'�ι��@#׀���a�1r �pA#/��x)�KX���x������9<�BE���{̻�����x�k��7��W}������lX��|p��}��?���Aތ�#�����19�����@��FvS�)Qܖd�|����!��g����H6�3ks���Z��?�����kz��c
���b$gA"a+	�_iRE��Z�VO�	Y�©c�{N��5���N�~��;�'�>'�c�?��o`~���=���ʊ�ͼ�Ȣ�=�+��$88�~j`e����˨(��ТC�q˸	-�S9��j�0���֩��\~N�_VI��X�4"�� ��w��髤�i�u,�k��|Z�%�Hq����u���7�Jୁ��k]�F]�1��Jj���wu�����(^@��F��g�������~g� �b��wC�[��1L4�A~.%?���:`���������5�7��_���f���г��o�0	qLY�#��ʣ��1�-��-��h�xl�Ð�=��h��&�#�m�ܶ�!�,1�[��;>��<E�Q-��_0��m:֥K��Ҍ{o}�7Ix�4⻜��կ�{��[&��Q|��ԏۻ{�m���c)������Q=x����G���d�lJ�V�ڣ:�D4M��P:�FQ&ܡ�
s5r[%T=P�PN��1��=��$@�~F�i��LxN��_��}�vuE�CQkdiuGa������
�2��nd��wf]�@�lި�+s��엿ٞ�8OD}�DMB$QQmrHh�?L��������n���D��BRݍ"�KQmc�N��"�4��������[�<\��S]�	t���T��ku���4*W�^�G�*ğ.O��i81ī�jj�<S:4��
�N(�dH���H�;E��[�L�2!г�ؼ�B��n���?	��J��'���Xp�onnܳ�?�(��9����o��|0ڀ<� ѐ��@�0!�Y<��$|��� ���I[��삑\��ޑ�>���A���]R#�P9��b�<h��j+�f#�Cu&�q8�APi��f��Q8~�sZ}�f�Z��QB��nw8��I��X����N0��Scg�{�9n��#�	�?�����ə�&��Mh�1�N� 8C)ZY/<�|��+�]�5e�B�K[��۝] A���5z�/!�چ�R�C��F���̚]���4WYf\�Q��C<�1yO���͌h��ݗ��y��s�G:T8Ԕ�DH�������s��RCb��ҤS:�#�7*��	�Ɓ��Q-�F��.�hC�k(ds�j��׏��FTyT&��_�Ι����U%������u1�WK�9���i�$�{������yR{�c�[���b��3�&9V�$ƌ����ަ~��5���=��$`;�j���rͅ����56����T8!�Uj�A~�a��V'x���چ{��~�xhw��,C^qD$��b����Sn���+d:�R�r���N{C����]�-{����e����7��W���}��r�71ۯ�F�h���H_�'
��n��yn�K�����0��~,�y[�*�:�џ��<��-N�����;췿���ψ�������RY`�ܖث<��
���w�$�r'{G/��v[4�z��c2(����1V7�>�0��;�"Õw��Qq/%SfE��A��7!���x�L�9>���Ic��g�S�r�<rl�Ρʢ����o��[4f\EP>�Ysƣ'�3u�.|'�n�CoI<�J�ZJ&�yn�Y}��Of���@joi(�芫8�j*��(��N�%<� ���x���@�x|M��զ'�c����e]�U�w��]!UL#�Fkn�#���U��O�"�g�/S�'��E�����\�����&�>�R��0{��������3�:��zfU�K�;jc�A�h�n���u���#L�Ոi���E�zG-*}ͯ����#��
ٷQ�K���QFeN߆�'��^�{�b��֪x`��k�N�������.㌝��^�LS`-R�UƵX.��rW��_ʣB��F��j?��Z*f)AD�,Y��J>�4ȗ�UY�7y�9�V�(*KX���Q�:)���8ά��[�W������f�V;_.f3���>��q�}�#�
Z�ފ�B����Um`��?����0��� ������fs˖������H�/�4����)�����>˸2�$�w�����j���\�R�3���f�,�Eߓ��DA*���d6�*zq³j����h�~1�aD}�����\�	�&GC�g����o3y�-�բ��u�
/�t�����a������D��	�F�����̈�	�gj��0�C�S⳪�3B�ͮ�5����#az8�e�/��Ϲ��h6m���[n�����Z��=��J��28�~A�����b��%�V^� �i��R��]ZFwƾY�7������w����n~7������w����n~���� E� h 