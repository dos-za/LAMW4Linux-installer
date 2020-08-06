#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3790902363"
MD5="40a03c6c264d023ea09d291ab59d694c"
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
	echo Date of packaging: Thu Aug  6 19:19:13 -03 2020
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
�7zXZ  �ִF !   �X���Q] �}��JF���.���_k ��܍��O�cW�����B H5�dJ%ȍ"�&S�w	r1�{�9���&=GE�4���K���,�t��gʌ��N�`&15��$6�U�9\ТhpzQxq�3S�*Ӣ��<S��$�"T�S!6�VCk�C�x$�h/6��0��Ͱǔ�2�̌<�V���^�;R��<���Đ��ԅ$E��� o���s�u_+Q�14]?s*�%%B��q#���c�AқZz9�2*������5w\��|"`�x���*��͹��X���Q���d�f:���[^\
�:�kғA�DX��@���0�Z�.���K^�C�s��2��F��NAO$��9���m��s���
�M�?4�<�O�n��܉���m�4d�G��j��_`B��@sa��hY�*�!���{��
g^-W�o�	4O�|�h�8
�J�O&�x�Z��>��O��:Z]}�,�5C��#WNA�����Y��J�G�΄n��D8��v,�:���`VtJ[�s�o-��<??���i-�J�?�Tj�d�mݛYr�2�U�\����
����ܬ�%����{�̫�W�B��I�'=-��#��iJ��Ns[G�����`D���웉ö��?o�Y�F����Eׇ��o���K��J����n�XR�W�9��&�!�UYWZ:�yP��6gEpU�	�W�1���K�8>Lߕ�I��+T4���L%��5�x��7S�ςSwۯT�����������
g���~{�]��H�r�%8�aM���J�
*�r�P��+*xm�v���@�:��?J��T*�W
@�(�� �ն)�g���I�B��<�G�72�����͕ǐӠ�(�����u�`��a��:Ѝo"P��CZH4���T�!٧�4�R\��4��,���rn��߳���J�Cɡ��WӃ��I����Rj�tz/Q�B�D�ц6?�Ρ:�1Ƿ�0�^㋫���H쯗�n�sB%�O��ٗWf���G3տڔ.Y
lƫ&�4�e�ɏCfa�!���>���5-R�V1��h�?�?���oׅ���=<'>O�.hҩt���7�#�rsb}��M%E����,t�O�&*���������(��%��3�_ h(��%��
G��(לX�v�h���d�p�9�T�t��%}�8��?����tGe�g��Lo�
�g���~M��0�^�E�� �F}Ω?/$����}����:�����U�;�`��r���8,�W�&B��gDܝ����},QSӴ��-T�������NJ�v�UZ*���Ǿ��Y����ba8Yqfȗ�d�����j��(�|Pe~JF��ո�<�vޝ)����_ř���z�?=���e�,�������-�A
�q�0f!Ԭ�xq[xA�:�̶C�(���ۀ�'h~����4�0ꑦoV+�;�$�*��'�*��d�}��a1ۈ��p533�U�V/�2(-�vQ�Q��,�FܳI	������*�T<=���NɛO�!,�6�@���I-�	���گ��
@p�5
6�MH�/���}��V~���`,��NB�3B��%o�� iMŴy8C�P|F6��M�^vw��_�\+�
x_��,�$�)�j@ϛ�|_��KLB?ς�Q����I��EB���$볻���!��՗8�;8� ���onB�"�����J-�=�� �R�s�(�p vc�uN
f���Rº-c`�f���+n��;#��3bJl9&�_�L]͕������H�@�j�w��>������F����1ѭ��P��	���cj��tJY�t9� �u �e6�^O��dAB6�ݖ��C~���sl��Z���_�ɑ�~s� ��|�(���G�!0	�$$W�r?i�E�|V�����|W��\��7f���e�O>oe�p�J�dֹ�f�7�����zΡd��@�}��[��ב5c�&�M`l��~K��2a��B;%e�ky�k����D�C�EL�]��Uk����7l�搯n�DxU�W�v���ϰ��{$M�o���3ֆUV���lg��+�~�B���î��O�R�"�JGr�bBU�hI�刕?@�z��Y%J�i�/y�JDm&�G��#u�ЗKu���ޣ�?�Ȍ+$#�7`V�E�H1��(��x��%: '�lRE_o��ɤ7K�u}�K&�H��
�^X�xȒ=%F�2j#�dB���4��C�}>����&'ס��i��Pt(Rl��������\�ɚ����'�ThϝX�O�Us[�B�n�Q�mu�n��^��<f����}	Ӻ��?l�V��O�MF����|X�C+0�<���5�lv�lm]�2s�����2�Ĝ6�~�L���Vj�)�&8��'��^��'FBd��n��ஹ���9RS�31 !��
 �_�<��ɋ�^�ԭ)ȹ��8��D��O[�ƽ�������&Κ��	���7@`܌�8�nD�����u�&=�\��F���(Eg������R��þ.����&� A^Tb����v�V��n���Ҷ�i�HS�Y�y�J��R�+hz9'�Fb�}w�Z��E�I����M�u�TZ�	
���"0���D�A��n�G��,�y|��]:� ��;w�UK����ނ��u�#�R��Y.���^;Y���o2�9�򽗺^�"k�KT�DoU2�9_΃�;����͡�V�%����}$����G���C�\-��E��߭1�f�V��Ҹ4o�-,��O��uҖU�qPՙH�d��1o��vӐ�Lֹ�h_���B�s�ɛ�`�}����q-����=ʠ���%C�P�K�J��_�0��w�OA91���'@�ɶR�"='��(�ZJ��[ۙ�;8EWzuH�<�����zt�k�`PcP"�c<��ą/�#$���(!~�6�HƎDh�J��R����}	r�D:v�j��,���<�+q!0��R�=�ԁ�Uq�|8�.j�L��"�Kɼ��W]��ލd�����qn���xar���w�.
ޭ!�(����B�v�_B��Vcz�9��RTA��"*��ڶ��%�el�Ma��$o�^����F|��I^H0�����hԐ��M�wvC0��) ��s�:��a�����U�����ǘLb?}R8�	ʥqC�������è�;�Ft��!��Ė��Qi��V;�5�ԗF�3�F1�Lf7������{��'%�@��'d�7�fZv̿�����?�G�1l�f��)��ָ�Xt0� ���'���FJ���T�z�@2/3=�������<Ou5 #�u8�ճ!�1v�m�w�x�X%��h���m\�lԛ�-zF�.j���N'M�K=��-G�Zu���e��Y(����G����z������� ��v��}�KV.Ɓ3�~�%�+w�=X)���$�H��6=�w����J��y�ѓt}fz*S��ȓ�j�@��z�
m_����^�X�b�#_��IJ7��(G=+	�C�"=�6����j<���w��mR�o���<�ۗ��� v�]�Kh��,KN1�̡��c��An-��L�������f�]%/1]^��^�>؛`��H���p���b�*���S��֡6���I�����*��{0p��.H|N�GK��y!�y#���v��T߾gr�d$���oН�BOl7`L�s���z�_��t��Q:� 
GHȇ��Pwkj�" o���?|wӚx�I��?c:*�̨�]bT�R�[ ҫ�]EZ��wR1lT~'�e�ǩ����'D\�,��Ꞵ�?m5�9%#�ho��K:����4p!A�F	��x�����L�u-�Ep�b�Ͻ黑[$=c	e}�]�jg�+�����B���
�tZ�(��OGe�Ei`<l���V	U�{r�ni/1W�.˯�B4F�F$-�[��¾�eO��N2cl8F���E�����	�Y|��T�P��f�<K�e��1�G���nڅ'�'4<��@�_���2�I���vg��X��<������f��b����*�%��4�F��>��>\������d�����;���[*���'ֹ~�?P�ez�5�y�h�۟�y5a^:/�!��H,���q��@����b͊�%�k�ֱ�������x����"XR���������X�Nj�]�'�N����TU�6%� �]Zs���Y"2�Y��f�!xO���@�ә�<�{R]�ȟ2v����Ƹ�
�����\Q��d<_�N'��e���Y�b����_��prH�iS�Pe�2�2Nz	�����?� ��&�����I7����,ɝt���:�qs����_��R�d�)�Dm!�c�0X"�,��x�n��w�������5���eA<�ZƮ9;�bKa~'�7�z9�
h�[#0�KFãA߈��'e]�߽�o�� Q��Bm�c<R��X�tG"�w��$X���%o,<
��|��A�4�-��Gc<�*DB��i9��jc�i��q�ڝg�c�8z�#���;1h�z��	N�$e��F).8��8О�Q�_�$h���}73�LQTv��iм��c�2
l�I����S����f�29A%B\������}4)�IZC�������I'R+�R[.`|�G ����z�	��Ǥr��n���L��e��,ܬ�{��g�\=Z��>vp`:���M�Q�.r,d|E��N��Y\ȇ���PN�'��٨��.AW���%w�w �V?hYAgt"3���/�wF�����h��OӇ*�̢Mw[C�Ѳ�K�s�c���S.�Z��������;�+Q�z��=�$Li���B�̊�E턨���4[w[�s����^�	���d�7�E'��[_'�)�d!B�P��%�dFX����ȋ�S���k��~�P�L���:��I�]~�詿��d|6�1�'��*�3��P� n}zӁ
M���Z��#���7�;��2NH���3�e6"`������Q�^2� ���"����2q|�
"XKt9�d\�"�:F�z x���I8^p=����f�<�k�I���}T9@S�Y��a�D!֫��r�W������]����&�������}7������ľ�H�M��ĥ6���S�2-!N+2}�Q�B�jDD.v��*����ؓ�u�d|Qg���ᩙ�I9�uA^�|�3|2�r�Hk��9y�[�re�I<��5	k�au��vܧ��JT��ƞ{G�t��«r�t[�����r���:�S9c	��	�����)b�m�;N�?����D!��M�~r0�����VO�d ��/)޾�Ӫ��;�Mz��t�n��>���|x��֩��N�UQ(?����Q��4� �;��ïk��O���U�)�fb�IE�a�����'�%�9��_��Zq�bm��	�U�(�YhRm��8�&��\%ԯ���_Fu��ͣ;�qQ}
Q�!n�R]�߃Jn����Mn���}�*��B�`�u�腯�C���:��l���v痢�y�A�bOC�׊ޔ8����.r�
�����ŧ��\|䚊�Ln�e���D�c�?�QFL�]�=޼5�K}Es@�h��\k���@F��}<3����p�����;�!@8���A/Ylꌷ�]s�ߠ�H�Ǔ��x�7.i���?�.��0JWZ3uj�Ȁ{�$��HQ���GQ�J��usK���(�}��j�5��\P���ڔ��@�JLe��A��7��1��X���<ñ)�h�x%Z�?��f�,�����k���T
9>$�r ���☚ {��:j��;,���%�U
a`1���OGn��I�Xۮ���mj�.����ێ��1��5Dg(P��8{XϹ��Ow��)��~�����W�~	�ϋ#b��~����6K�7����	xv?�Dӯ�yb鶊Gj{��r���bi���m�3NY�L��������&�9��XkE#w���@@��ZP1▂v������1���jO�Z�����6k��5����#���^~V���B�y�:7�X_9E��:����/�J���F�ٹJ��� ��u��$;s�1�cT$�q渶��fP�S�CȚw&�'��k KYҘ��.�dT<ku��r���?A&���� �T�����[�˂VP�3�xy��,z��E��C��30���4u��L��De��i(�x@­��, ��"sg�c�� @������ҥͣb@�e�������#[5��8�\uJ]�Pڡ���kK�H�<4`|�_����LFƕ��Vj��F����ŰU������-'W5��\�Ϛ��n<zW���\�C�L��d��5�����
�U���Ȁk����C���b��]�"�W˕���څ�R��K�'��i#%�|�֢Ʃök���1h��r�ၨO�������3��*�R�L�8[�'9&>��ܛ4-%f"����@����X�Qs��_?A٨F�k������
���.Q��G��G�ٷC��rNGCQv�X��]F�1�@p�������E^:>����Qn�NZ6�}%��2{�u��9捠�{�h�ɬ��˭m��@��t��,b�(��`��u�̬/�J�?E��(��N ���F���yx�c{i�z���b?���J�mL����[�]�{����s�{�-�i:w�_���h���՞_�e�ĉ�I����������);�8�A�Ӯ~��A��[e��l/p�&�)�>	h���0�`8'q�> 3����%|~�)��
S��i^���J�u	!��[R�E<|ʶ�3h}R�J�7̖gh�XP�+Z���M#�6��V�QD=��^�y<����՝�n�]��9�&�(?1�����z�%�>�����۩��[�UO�A�#Ӂd��ƪ�M>hg)��0�B�"#�>5P���� '�a<�NQC����:O��-=�/!�ֺ������-79c��������x�� ��q��BjQ���UN�&���j~�'?��%e ��FE�~�,w�v�7��Gh�_�t�ae��M���i�$gO��h�tv��o��\��)#�����#�o9G�I��(8o#�:]y68�=��q`�)#��(��m=uБ���mA��Ȟ10oIO午��cF�4���ùB��Y�c�9��b���<��j鑿|��6����O�51y�\6�k��>�_{�j���ߦ��B�;3_�H�uy�h�y~�"�޿蒸�㓐���bn� �-��M����s��w↑!�p�+Ki�ɜ԰-,�:7ISG}KGҍ��mx㘺Ia��Fx	���0�9����\n�sןH��\��?�B������&��(0.�<S����s�6�[]m�	�za� ���KT�t��rg
�9X�g�����Wɋ��t���j�H�5�ZF��GL�PN��%ޱf����؍�L�%�R��#LC�TApl��pi��"�����ylB��!�u?<N艮��Q�V�Fs�u�E��.Y�"h��):x>�l)S��3PzM�+V4u��r,���tD�m]j�N���x�yi,n��5�X&�9�ɠ��w�-���h?k�8��@K��U�k��=RPc3�XY��#�-�)�%,=�w�Jl~b���Ր�`F�E{T�\��
��>�=F�+�*�2�c���V|�����ƆF����؏䃡rQƅ�'��د�R�C���AUZTl�������n�pR�+粅�dk��zn��6��9@{�ӎ���
�p:��\���hҒ��XW�n���1���>��cP�(��
�-�G����ò^�A�����d�`�<-�3\i�|��OL����||�*��;G-�eE�;T�̚��X�[_B��靔!�*1ZWT�CPҖhO��ܬ�c�e�θL�����k��S�ƹ���>)3��|~:��Sm���������!��P��ˡ��9E��T�E� ��<��x�V�YB��O���	�7'�s�J[*��y��˴��~�R�!E/��Tv!�}g��vE�{� $r��f��tq��b��ޞ�ܰ2˻KB�i&Yϑ��"굫�y�=�r15S�0�Úen�4i�:RQ�q���qBw�����9Vj�;l��y�c,�O�r����GI���󟍫Y������o���k��ޛX��������@9�{+�����4�8w�)TQE�;�ko�i�J5��ʆ/��>U]�����&t��sU��c�Ȍ�'���
x2�;��n?��wlI@:D���S���7>��[�k����3��t�X[K1��ZK�yejl� �����l�✵Q��>��;)#f�1vv�Jzp��#3Ј�$zז���h���V��a4�>���Y<�B�xH@�J�~��W?���v�<_#��c���O��s�g,3j3�w��~�qI}Bm/��u�єq�R+����#m���s@&{,�Z�$Z�4�GR!#be_���Jx�A���A�eW�'�����HV��Nr$��ч���q�@��y4!�!ۀ=�sńs��,~s��RK)�{gɚ��_ss@�&o#=϶>^��P��r�~���W=�ܳ�J2t~H+d7.���_�郫Ų	s��9,���"�S`Lَ�խ��{o!X~ZNg�h��Hd�2:p���K�Ȁˤ��D���y�P��R���0:���"j#��d�A6�uV��餟`�o�݄�'q(50-fYX�P�A��lv���U9���.Z �b'���2���.�3|�6�C[��TS�]�a�򪼕ŁҠ�3�;�3E�La�����I� ˚4tGN{��K�)!��FN�H$������X'�8�t5�����V,W��O�p�]�Lz�;DZ=�˟�̢Z\5���$��"$��v��J��x&�R�2V�jp�a�n,w��{�%F�nŖ�Rp3�ղCR�"�4�얃PB���BY�١�]6VGտ�<VY��96�,�0W�us&
An;�0�SQ������G!r�BJ�������^ �]�l�˧;i���;Z�WY����huJ��a��~-;#Ӵ���eNXm�~R{'�Şg�jH4kX�R�r��إX~_I���:��G�(e�;JDJ'5�M�ףVC�D�M<u��>�i||�9�GlF#��
��]�Ц��U!��]c�Н\6��DMa��z���w`�R{�QБ��%?\��FM���z�Oa��Y5�be�Ll�[}�Ŵ����
�aW�@�ϙ#���cčɶu��S*'��ȫ���Ŝ�[;�JƄiz�)ǃ�%NJ�pB�1�V��`Q78{��n��[8�P�,ı� B�����w�ξ��@׋c�y\o��S�������e~��IIpb/U�FCrs��̣���EK��Q̰М>�T�/T��J��:���@T��B�b�<9B��6䟑4���]5�ۿ�b}۳"�ʱpfD؃"�#)N��D`}�0�5]g4H6�]��~���#aލJ����� ��U��2lX؍����1^�o���˨��n���y�G��������ꃞ�m<Ñ�ɯ$^Xp���="nVޕ!.�}�~��n1�J����Z�ک_�nB��_�E���$��Yœ��j����k�����( ��wj�ktվ�'�C,��ȿ(4n�/���
�1�C��^��g���p�{\���UD�,0T|�P���2C�Df��z0��E�^;��{�/�g��79U*l�n���zة_Vr��}��i Cm�peЧ�5�[�H��LݒFc	��,��U��p`\���Y����1�?N	`����Nh�򂈟B��,��\<�����K+FÇ"���2��ǟA����+v+�K��߆���°
����y�)�d��Q�� �J�Tt+��CMb<U�����N�9�ݧ��>kD_q#�Z!:!��zɰ��}8 �p]�%Fy�ĕuJ��y��ɜ��m�8U�}�4�TI��x��Uv��A+m	�:��:�%�Ѐ��KkPW���v8?�oPF�kT�)��_�\e��2EXP[e^XJ�Z�4�ݟ7���F�MNH�	X��6ע��B%��&�YΕ&�3l��f�$�h�"�x�)�!.�7��������S��E�ӎ��w�M�*@�)�:Z��.��M.#d����
��Ȏ�T�z�)�m-`F��!=���>=_�u�f<s�^���+c{X�"�b�l U�)�.�a=Y`����jF��4�ݪ�A�N��u���
�8�]�%��tX�����z~����*Kq&Z��w��������������;SOr�����@��Y'�\�L��a��ET$���V��#pi�L-1������1���a,�K��*\���W���RCs-�xc���i�Ep�G�a�*��Nhee����/���V�.����o`O��\�<��S_��d4�/��-F��7����jߦr<�n��ʬ�k�p?3@�ނ����$�{m��"(Ƭ҄�����{��;���ڊ`� ��f)<�F�ӿ����ѥ��#><��;��q ��{�o4�__��>�ƑȆ+�ഠ�\>~��k����J�`��)�SE��
�P����DE���l S\�^$�?�.�j�S�^��A��~�.��9&v�Q)��#�*�-�Q� �x�O³��恖<��o	�+�|f5�8)�6Љ_BH�͂�
~$�BWё�)�:�C��[���E�I��Wunw{1*,��?J��y؝r���x�Ȃ�� �h+8��H)4�������z� ��;�v�z��o�"4�X��_i۠s�]�������~�m��C���c4�C�:}��!ص�\L��8Rэ��+�#�èd�����<Y�d�"߻b�T��q�s���X�y��WH=�'��G1����>����1벆��auF~YJF·��!��+
��ӌƫ;�Ѧ#CgŶ�}Wd��/Q6 �A���wa���s�h��{�|����G��j\�G����as*�\�k��54!�O�Y�DQuh��&�@���2
F�)++��݂��B�_�T�m�p��7<g;B,��$S���SKm�pɄXۉ���n� =�Ad@,�w$�8^p61K�l�pM�9�٦�٢6�v�L����p��t�f���k��Y��Ĕ-R���OrqE���|<��v������'Ai�ٷ�&�!�A�5d��2d(�$�hw穛����ֺk��z[���W���;�eǼ�iC/���.㏢.�bQ�����㏚�k���d�Md�)����Qh�q���oS0~DBh:�QÏ���F_
�yFMt��8��k��"�ǐo��&+²|�*�#V��ә N)����mv|E��\��)'U���A�ȟp_{+���1&{
4�MR�H��dƁWMeŭ0���c��\7����@�&K���1�Lk����2�J\����_[�q��H�Qz�@���9�z��A^fS��n쇌��b��Mf��o�S>ƃ2"��{�\)U�/j�z�Z���͞kN�0('����P�Z�D�����y;eu���U�p8�U�<�O���X�r�:�N��N Ӽ^Ќ<G*F3 ���� =|��v���lEF�KE�]=�_�gt�fm5	�1�q=l>�6⣳�
=)\{�2�`����&^�Md���$�o+�m�JZ��ee�pD� 7��!N�1^���0c��ȹl��MR�ڽ�!zh���
;C�v���:ś7�n"N#Qi���i[Ҏ��<�.��BfwxE���Q�aNk�Nc�Y��`wmsO�����
��?˥3%d�Za���Q�]n��X\�_��f�F��
����	،1�D">��^Ď��֦�Ƃ!=�jT5�u>Q�J�k���7�lR�32H�?������ �����c�4��̘��m�
��Ɛ������/�O��8�	�ߗZ�v��<\��nL�%�L��>:P��nW1ΒT�"��n�P[��%����[o^<�
�3�6����o��F���U�rym�۹�$�$F㌻`��X��w^埓��]|S����ux=�<W$��:&n2�0cΥot~x�zc�e����wt��8��l?ױ�O�/��bH�M�Aݚ�5{o5!��b<��=C.�� B���*�u_��A�j�8�y}�4L�`am���b�.5�xWNԦj�{0m1�n��
a/~\74]0��q�*���'r���Я��HWF(㭆�i���5�`�(�ԬPpF�?p�^@;r�X���s�����6E�ʸ<���o����� �'�
@1�L���T�� ǓW��<�x+�X�#$/�ʫ�B�1��恙�"�ｴ�!v��O�wqA8��8�e�t7�n�`��Ά�"�����������썟&}�w. ;�|5��OJ_�����}%\��Ǐ���ߏ�0���,Iʮ�C�{�/����:�q�lb1M>���0lq���4Yƚ�F���K��/J���Nݞ��q��@���N2��?!�a�A)l�.Y/����w ~��#�	�qn�����n�6|=;�8<~��	�� ��"�f��D��|�j��+ᗍ·}�h�Fqn�l�u`��������7��Wi��U�!���g�Z���_�kp����]�u�4^/��h���S�%������`���>h�rY�@ޗ�ׅ���mum��9�����zg�|Vd�RL��� �QTk�F�!g�FAn<�ƛ����UXE�x�_5�8��Z�mA�u�S�����W�0���Ik|N�"�����X5Ei��;���Hɥ0��jta�O\p�"qPO^�mB�FU��b2���]��y��{����r��(���|��2o�ܒ����.�� �=s��՚�
".��To;������7R ����wܲ�B�"g��J��.�)��ˊlW�U��L��ْ��A����k����:q���Sz��N�N^|���;�Jp��r�k�Ao�m��4����/�6?	�z!}�+�S�iv;k�$W~3Y[IA"�UH-��lZ3��"m�����lrk!G�߽<�[�O�ACv����M���]t�,�l��zCV��-�P �xS��׈o����<�(K��)vs�^1%Mcpa�-SO�}���6�}|㨡��[Z'h,�~�k�8���^iǓm���eӇ7�R0������-�Xj�o�J�d�:���a$�ȃ/�vS�y{�w�뵕B�T�䌋A�
헷ѡ��o��`{�����g }���kV�D�z
�t�(|��C��R7�@���:DQe�p�>��Y�S�L��ّ�����-
��p��(�.�¯!S��~�]�-��vj�W�h�]�U�ʌbЊW7g�a���IU�}���P���R�*O��J:����w�mRow�{ s(m�n��d�c��x��"�/<5}�[��l�EC7q2����
��o�4p�6=����_���w2�av�ð����rz���'3�d}���Մ-�8{0�Lz�i�i0ل�!�v��0�����Ӧ�5��� 6m)����U(n�.�z,@�ti�snPԤ])�ʰ	h�Ǜ�:(���Zɋ:w
��Bq�V�����݁fh5A�b���	�ؖb�fjm�n���I_�l��5��K�(�>�I��,��u/O�����3���������`^����h�_�%6�6�xn	%B��!`�a;u^������n!mq��ALh)nկ��K����a�*"B0��E՞1x�T;��<�p>y����T{��-��1��8JFgqrP���l8(A*�(�O䐏jP�2�_ybp�+$�X~���e�2�C�^
6�8�� G8\���u�+R	�����f���M��=��):�$�V�Ֆ�\��;M�>�o�IL.��Y�\�ZA��������`�BZ�l"��Q)�\�?��pe�C�.���!�U�� L7IC��*M�\��a��SvD����?F������%@�+:rr��@���sP���˥��J�@O�����	I����
)�顿ܴo��d���J�B=�oŭj�L.ڂ���t�9-ä�*������{��~�r�( ��1���asd� ���\����&N �w��h�҄��!m1^[]���6$ʕ��g�T�co>-�EТ��!6�q���_��%?������x$�Z��p���N,$ns��=��wwy`M�A�(Ec����h��_�Xr� ��'�a�MU,W}���u�|9��=ߒ�Z%,8����B��n�Qr���$�� �8�uP����̀����/�� |�~�J�� ^E㼺����`�*rӒ�S��&q,1��	�vb�&_;{�`� ���W��V6|ƶ�u!�,j/����Bh���~\jh�.�Y*�o ��*��U;:5������җ�]��GZ,��S�mvy��b:4r�c��[
|�2aH��TA �_h�>�7��i�ɋ�m�i�]�:[1	?/�t��2Z^��}I J=���`ȡ��XB8ƴe4]K����ϓ��Ұ�a�"~�;�P�&u
G!{�Vg�]��aAM�^8������5�5��3�߳&,��bLL��b��ٛ��9`ʂ�Zӛ'��&�%�^p�t��f��f�6�RS�QE%EV.. E��18�$���ܜ�$�����քN%�?㲻�JV�H�fj�����fs��k >���A�w1�������H�֟P��h�eR��q��*�A��ޗ��wVqv��^�b�Ǡ�zSh�L�RN%h�7ڞ�;�0t��		V����|o�����"�r����l'��)B�_Z� c�{�����{�o_I����A�W�I�X��UO?�
ꗹ���$'z�I�	"Ͱ����ĚG��m���2h�r��юl�+�Ҍ4wA��g*�_qU� ���,�1�C�U ߀`
7:����fu�S�3���Cׇ$	�S�c�pSy��1�Qv�F��g��Z���<�w��FV)J�Ѻ�F%��ٌH;Dk,��?|Z����P:���'�=��|�":��ڶ����\*'l6��}� \ ���@���e��8Xo�Ӆm�w3�WP-��5�u8	��L-�t*+i("��<�7�RQӵH�EGD84o�^��d��z��01��7�*�0�"�H2�A�B.���йF�.+�r���8L;�Z��6�])nDS����i>���#�|��qN��Kj�^E�u�y���k�]CvR�V���y���<}⑘�2;"�ԀT���`����|{�\m������!��}�=�2�$)�m�h HKK�/l�:�]MdeE֤7��nPf���i5	�h�pA���%������O0���Q;Go����,���܁���`%c��Wm�6.��u�e�l��,��9tƼ-�frRp+!n\⪤Q}6��7�vT�[�yYE%������#r���-w�ȥ�D��/Q(���@�S,�p^��#���Y���J�� 3���
DOD�|=�5i
PÙ�m��;8�^�&U{�7
��:��'����@��mJ�1���	O����I.�A�n�c3B�R��YE�D��ZE�?i!<)�|0N�{�n�#����=�:��"��P�|=�o��,�[�/BL3cU�Nњ����ʔ��̑�=�Ր��(t�K���^�ǌb�Ђ���LE\��;�H�m¯�}���@٥���B7�� �q�M�����x/E+����r��F�<���>�l�%��l��[�a��_l�q����.I�x8���Pz�rS-| ݾ�]O���#���� �w�_�LL��Y�(��X����}ZE����ցIf��Wc6�c^��aW$2��hIx���[�Gܴ^�Ts��8�x��� ݠ�f$ϡ�9ʹ�&����ĉ��]���u�+�����xhN��8J�{S�r��4g�eiK��+�J)�"u묪Gg�.H�����,�7���I�@J�3>-�,~t��3"��GIPn�>���v�7�\{�AD�*F�z�гt��:�SC�v�W�S��sP�6dݶ<�����ݠ�m�-ѳ��-��(�4'~��.р�
 ��6ԙ�{S��-��F�ϣ�?ܹ�ѻ��q4��x�\��b�xi�Aܩ˞3%����P���qH�v�^@ٽik��J׉7�����s�����?�%���+����D�v� m9���.����P�X�E5"�t�UD]Pl.�YY�S�������XeV�H$3)S����o(����6����f�2jI(�@:͜f����
�o��,�	<���������.`Ο��ڂD�j�=��y��ޙh H��v��τ��^;.�#z4z�o09x��J��Z_�����Y,�&q��QiC���|���f.��o'>>�t�����i���Ө�)������-����@fhȱ�b� vkC���>�>�잧g�'�"Z�$�>�/̗k�G���d�Ô�h�n��,���8�i��Z>�����0�yI�s>co3j�8��t ���:��&��bZT��@CM��q��fi�[g����d���,�q���(%��� �!�!4&:��}���=+�4�7Ҍ���3��C��p&����ex0ڰ�ϗ�z�o��#��S�5�q&qig�=ʽ�G���L�-����-Ÿ�$�Vj
�d wfjf���h��C�����b�H�T�_Җ�,\u�v\ge��V2��������N���sFwu���%˩?E������@�� P�2t��w���l+aH�WS�lo���ɧ9��@�v]���+�ۯks����Uë�Za��ȵi��t�L3y��܏��Hu�H~1-��z��P�6m� Y��_��C4�C�w\��DGҝ���>�B�����~��ͨ��m��A�ƋE�vR�v�t����m���hZr�	I��J?��]�6�ط�
cge�廼YR>������v���M�$�D��?�6�]�}�~�SI�>ukd�5�~�:���0���^�?�!�y
m.T�eĞ�:�5�y���[�"� �P��]�.����b��G<��2^fp�ZeL!*���}��WKq�[dN�2�l����^2r��jK�?�{���5��Q�~�+����d�'�;'��+of֣Z�0��*<f�~c�j��6GBϻ���������f;c�G,2.��yxM�(�>*X��m�A�ې�����7�����/[3��k:�΀��s�{i�o�N�i;���.���%��ϥ�⸦�u�}�@�f�0#g%B�}o�|kA�Q0����V��B�S6��B:pz.���y��]T������߸J9�{�&:�+:�.�Ǡ٠|�!QW&�6��^�+G���J�mEA!8s��w��
�a  �U}�-_[�LEM�勋��G��nQ�Ԏh�I�o�[#*��_]���2�͗(�ʠMZ��U;��Ul�N�d�M� '�>U�W2MV��ǩ��U)�8> '��J�'O��.\E��&jψN_�c��ڼ5G��n�-�W����-0K9�E�sRV�	�e�p���k����.��~�ِ���z£��k��߅#3��5���Zl���_�?T�ڒ5����P�\�[�����DȪ�+����*/tZ�1�s�L?y�v�� �	
(/�2%ߊL��
��XGl�9"�Iz'�@a�� IB.0�����#�Tm�2���˹��p���;�nv�(��O��/�%9y���������3�>B�Wd�c��[�̫�������Bt{+���6\��D��H�+�/��) 6xE�mzt8-�����;�7a٩䄛��$@++���y�"���q�B$ɝb6�+���u�H�p^9ƱB�����@�}yV��o���ƕ9pe���E�
�S/�|7/�wb���s�(��k�E���#��kI��[�7�!)���%�.�ؼ�i�>�*GV�е�J��"�yBfR%��4�X��i��u���LR�(^Ũ��:0b�����8spłc�aD���@��}�+!�[u���gس#���;E���<+�Ft���>�e���`=��=6��o1@y�].v8�n�ʙ����zI�t&�L��%�]�u��:��E@:k}�YHk��U���~��D��<�+�Yl͋����җDڿ����t���G 0����b�+i���N��\� ��	�-f�Q`���a���J�}'K�y�k�L� ����4�@�`�	�J	�U�����{�!�	<�² ޣ�#H�k�IXgf���ܦ�������d���񪔷�@��?�K������A���,H�"����\��F��I��a/-�iܔ5f�$(�LRV���bt��꤮��f;�㎣VI���ȢY*�!(���}t�Z\�̵��ڂ�8�E���k�7oA)sc�������*q����&Ʊ��8��o���Tvh|Z���c˦���q3��9�ֶ+mM�DLڸ'n����m_�� ��"�15tխ���hj|�}q�e��v�p[0�B��f��j����;Z�|�e���Ȟ�+\׈�$�Ȉ3�WǉE�=c���l)p�:e����a�\�:V��ã�9�5q���8Gj�|~9q(Hi�l_�G]mO$����CӍ��S�1q����3�|g�E�ټH�hbŪ��]�X��<4���r*�}9'���!i��Ӟd9����j�m���L!��me�_���H;�a���_��lZ��L
A3Z��s+��nAY�U,SL�?k!P>��ؔ��a�B�?���BI�1��k����a�����J7����8����9�9�وg2u4���ۗ�u%�b0���/����ܵe���R��P�d�wDR����oC�zb��4��atn�Ϊ�]���Օ�?� UE晔�+�#�dW����T�S���Y�S��V�5G�����a�C�`��������x�%os ���Bz�&K�ޗȮ�[}�h$*�y���~x?]e�u ܗpǋt�e+^P��&.X͖9������6�͚��*\@)�!���7�G�≧Q�����ζ՛(R���+#Gǌ|����.}q��n�n0r�D��Jā�;� ��:m0n�r�}��f�</���tB�<��k.�,�D�|���R��t�TʗȨ�Pv��LʯS�9��|�y(|�4�ZxwY� (�i��2J>��FfCJ��W��W�U˘cvc�	e�!�a�W@m�+~�[��N�ִ�U���*Z�|��4ZP�hC�JPȟ�(�ȡ�Qh��*�Vڝ�]���Ⴕ}��� ���Y�|�/��w��bF��&e�MR��;9��0���C�� ��r�MlT�湧/G�ϱn�й�o|G��tn�1Օ�`��(�����������7f���?�,~�^=���ЏN����]Z��Z=���)�Zo�Xop.��'�IXaڽ�v�2GΣ�5$�: `9�d�(��H��H0Ftag�[ՎH�%��b��j4�ip�h��N�b�I�k�s~���@�{��_W��4Q��	�~�@�X�_��vw1#��w�⃖8��x۪�n��*f/y��vv˺$�wv["�K9�b�"���Gy"�aؤ`mm���q���
�%1Պ�yQ�.�����I�O��%�O5�R_]G��v�A�޼�X"/���Eޗ�����5��K���I�p\D��4�2��f�A�ƻ��4������Ts��Z��-A��N�o#d��; �% JR��c�{ e	v�E��+
�0fr�*�7f"���A�`��|rd�g�wg(�p�MZ��|��@m��f�K��qjȝĴ&Hc/��NqFTA�1k�7]�M[^χBtF:��	�+���ٴ��x�u�Y�}i�`�k�
dz!04ē�q�K��|fbΟ��'o�P�$g��9o�r�̻/�&y{.	�3^���f�(o��s�Z�*JWke�u��}��ہTv8�%(��B.ߚu��ީ�Vrpٰ/)
V�c7��AA�����w���Y��xI)Z��:Ja=:�<ºc	�I�,f����9�7��j��%v5���ڪZ]�Y(s��N1)ܩ9l��K�ϑ�S�c���wV�,I&����'��K"�"�ȸ�v��X�e�z�0ޱ�p���ٟ�_�"�H�������#� G(\��L�>�����\k�X�q�ƝU�en�4����4�f�#s���2zխ��?�)vP,
l���F�)��i	�ewo(R5Q-/��q�,f��n£�6��_�a��;ɖ}�ҎJs�,��5B��Y	?0��L����	�fbՋHY�����(    �Mu�d� ����"�r��g�    YZ