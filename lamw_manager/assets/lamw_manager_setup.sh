#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="310929576"
MD5="3d6909b0bdc14fd269e7fe3b327fd2f8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24988"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Wed Nov 24 13:35:50 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
�7zXZ  �ִF !   �X����aZ] �}��1Dd]����P�t�F�?�ʮ!��C�d�O�,����މR�r?���E^����o�:�b�/���}��;�lV곮�̡�W{�5c�N~�vС�.���0�v_~�^[&�����m�5�y�Y���X�����"����a�R�
�X������i �?��c� Y	��[�ʏ޶?��3���$���Ա�</PC�g�L�q ra�:ᝬ�I���Ec�<g�OE[V�������D��M�$������ х��.�c�O;��^�V�by%�.++:�7�$]����!�H7G�t�ݝ����7����9\���W�"��,}ტ�,�pzCWD�
-��KQȉ�����I=N-U�z���9Lŵ�O���� �h(q�|j>s^ )3e�� 0�ܽ;P�&�eSLO�G϶��ե�r���N��:� q��u#��?e��\
L��+d�B�j����ۄ�-������G70��zA�EmV-�3������X
��T�+qCOe�#�8��<<�%��o�َD_X1�i@��� 01�@�zPLD��S�p	�PQq��	�z*+���������K�<����]uQOd��z��K��K�z�i�ה������v��E�?\�%T:3��ؽ1	��`~]�'4G��� tbC�&_�,��s��!yƣ*%
�F����Mz�=Tk�)��tj�td�J����a��'[biP^�ɝBwe�	��~�̄�k�p�u�1�[$=���׉�)�^!nᵄ�5X�}�x�y9[���W˶F��ԓ�/�D����uyâ��J,���I�.(߱���Q���p�^��0ˁ�Je������M}��2�$��Ѹ�B�	_z�a�;�'K���.��M�&��+�v��I�9u���H�&hPF;[�v��ER1C��}_QM��X�v�243U��,�Խ��ȉ���5���^QwiTUm��c	�c�bG���1�P`/Rh˪�I��%ey�X��C�Tx����xg��^��}!�i䳗؛\�rQ�#��_p�x�hj];�Gi�fT-��8@OW\�ۋ��J���v���e���"b(��k9�ٓFDe,�F8U�R�BͶL˵���+ �KEp�`��yW�e�)k��3=vr]�#��&�W�"yHP	�H0�F~`N%f�a��Ov�
�K`V�l9���y53
R8��f��H��ׅ1[hH���1��yɏ���)ش�ؑ|�c]�`��DĴ�G�����]����/L�_:hրട
�y�
J����sqY0|+�tk��.x*gsӳOɀ~)����Z�1���U����*��a̯��'����&$��A0���4��2��8�s����1���}k�1�������ro����Kv�KUmc��9:AΎ9̈0	 ����eu<F�9h��`z]jD���э�0����F/�Oh��v���29�T�>`�v��g��1�/�Rϥ����ܔ���H��1�g�m�J�L�/I�we�㻒]M"�g} I�`�@�^�P�+���>NX��v�Lg]�������m�)�#��ă.&�9�7�jwn� ��@��J"(x~K�[ -��=�f�Z71cG�{��wk`���%%� 9q��|?j�Q�o:�Ӿ**�+'C[5Uy%8�n���_y��[잲��aZ/GH��q���j?�Ys~�<*?�宊��F�>#��V�KFo\�.���ghʲ>3�����Z�2��W��;��p�B.U�� ���t����(�f��ern�˹ [�)P�#Dd�z�#Hx�`��,��O��{����\�i��v�B���2=:jfY�^;�b���� G\�����-��
QEe�[�:�mOy/��-<�A0EP�9K���W�E�i	���ߪ#b:����?I<(@�X#���/�'K}�"���.���3)�e��l�Ξ�!�1	!��� ��W��Kf�_!�����3�5/�/焬�_Z��R�����^�  z�����,�A��Y���v�C�A��Nﶯ���"I�N
X�\x�w�t������E=K�3
6$�z�]�q��
�v�5P�|�Dx�p����`�\���b��Ak��� rC�$D��|6˴�����m �i�| x��"�͖I&��_�6�K����01,+��ED�l ԃ����ڹ�O���vHL����0 �ˬ�z/�h�b�����R�u"�=D}9�T,	���j�d�1�a�u�x#�WW	�W� [����фZ�b��i�=r���Z�*�=���(��=
�S:�\b��ӆi��6}@�����f�������|��^-�Ȉ�)�X���I�l�����y�+�v6�E���nr���s�#�r?+p �_y���o�L���k�j��\}bA�,�{4rGO�`��Ċ���	~�o�+���t�����ƫ�	Y~�<��K �Ts>�x�H�u/>���{�a��l�ڡ��:�8�l9�'Y�Z�q�B����!PU�-n"f��<�3	�f(��J���'�G���Ad�k/��Z��k�8����������ahq'�UN ���W�1m7?������u���藤��@ut���
��zK�.�
ȵ�3���ZR\�m��Q�K��Y���)$c&U�gG��z���rU"��G\�rަ�:���Үh�*}�o/�?fG4&4���땇*D�8����m=��^K����!'(�7���?]���|�y0b��z�Q�;���(�pH�Ţw��fl�&�HӠ���0�����і�J�@��`&�7pc%d�0A�Y}Ko���"?�$��\Ok�;����M�'ȗ�q)� ��>}h!�Jl�������}�(���cN*K�iG����}n�j�;iP(5�-ZW��%%�P��ԍK1�Kq��R�F���&�M��&�(Υ���kIq3��`�8��*P��<�,��Np�y��	�)�B9�����F;���b���c>�,i,��Ŭޔ|�E끶QS7��W2�R�����2iѩ�EKI�p�0&'ȏر� y-z���i����v�u%g\�� y���#�{�d�:�ҥ�FvF�6��eĩO%���M�7p[b]\ �y*0F"Vb�.��\�z2��E�ȓ�Ϗ����qK˧]%�U��g5 �wmT���,Rb���OO����bͥ��'Ls�D�E��D���a0�TC�҃@B��z���gf �t���+���Hԡ@�#DS�%�.4,|D�U#���ż�Τ�d��g?����`�[���u��s�&i��Q��pu�Fe"�"'a]�9�Vw7��lO���a"&1�X���˚CZ_0�����ƕi E���h�e�V��8&U�f���/.4F7/���g��Q2�s�l�����Rݷ�Kii���\�cy��!b�������&y�`[�Z���#��M/��"�	�g��²�jɶ��8�)7��;9s���P��1my(����ޔ�Gp���@ai�}��o�ԓ\�>?�?rg3��~hLI���,S�h�������W��'�������Ws�i�|U>�,�
;�����J�(�:��&L���я%�����tv�m<%��@x���� �W���c�s�BrA��fgkFӺ�Z�g?$M�dX�d�k�?�#��N����z��c��*Vl���h�M�W*���Q�n!�TO����-n�p|>�EݤR�$I�K2�+���hP��@3�����a���+�`��Z��V���7����~���.g:v��n,E�ňĬ�2�<����n>��Hu��Kiߴ:A,�h�́J#�Cs,'%(��W�ֺT�'qQ0�{��_6����/���L�: ���I3#��TJ\�����ux��W6�~ �1� �qP$��;��M���o��;�a7���X���s� �0l��h���kvd�l�dB��X�6�����,ˆ����������!�t��1�����m�&�ս�!.xS��DW��v�UvDp���}�G</������^^����~�4�# ]�y�%mO�F}Ն��R:ʹ}-w����6�a�|f�0ۧ �*;�с>E�>��@�$�^�Q{�Z^�텗�Huh������\,K�X��\��Ҿ�l^M0�k�Ӓ`V�	u��`3�1?6(sN�����*����Gb�p�V�/\A�\ݞ��)M�~��� i_�����5�y@|KQ����dOۀ���K��8#فs��XWD#U��y��b�]��
�>N����;�/�ob��&ND�f��^�9c����@�pڗ2��?.���A���Cn�IZhԃ�jdg�"@oO�9��)�ٓ��P��zǶ��]���E�6���H�K��Ԣ�~���(�dz��������[wB���O������H !�a�!V���n�VD"�E��W3�Q���o���ޯ*&	b�q>�H��V�y͂L����T�2?(4����[g��9\����p�������9�%� ��"�uMF���^�;�_��(�M觲kM$U���5����R����aC��4ʍeu��b:Kws�|�v����ؒ��y��#`����ʰ�	��E���#�䢄0F���9�L?�0t[�`ض�-<�'�4�����A-��V܃�qc����6��b�|�B�!I|:�gKZ�1�L����"�2IP��G��f!���v����: ޯ\Ĩ�A]f���@�m�A�+������f��jﲴ��>�)&L�2(��������Ϩ�Q��u��r��d@4����
���dFq�1�A����cil��q�l���9%�l�imQ �P-T�ĻtV�ܛ�!*
�G�&e��<!7�mq������=��H[��ڧɰ�'���j��z�a(kPh�c�	��Hʷڴ�Hܙx���TEu�-�~R:I�rS���C���ʭ��h�s��s���w���P��g�C�ݰ�$Z�s�NWX%U9���Ų��	C� ]�}:"��pA9Y4CƱ����#,Y�\�Ā:%]f���Kْnꌝq���N.��١�<T��X4#K�+ƅG�JR�b���PQ�YQ�8��3�H��ʳ��ߍ��Ҕ��nb�����_����(�iF� a'Q>�71��h�YM�P'[X;9��ߝ�����q5��Et]<���xZ~�߹��&-���A�r� ���M<��`'�ݓE \B�PM�=��~�ܔog���p�ߥ�>;��k�푩$���B5(Q���'�Ep��E�Se=��/����-��r�*�n-t�z]���V���%����j+k���<Q	 �x7��h�F��vS0��U����c��_.<k�q�2�DoX��Lh�F��oa�ӡ�7��g�D���>VM� �q�e��H�%�.ʄ��Rrr)<1�'�y��,_������q]5�r���l���#���ԣC��tc?�W����U`�
v3)����K�^:k[wD9ŧ�Q~8�t����)�
X��Z���P�͙_���؂��0[�x(�F��W+j�t	�N��쪽���o~��$�d��p,��'�T�7<�>��MCy6�0o�Pؐ$�Ѯ�#(��%E�/<pA���q��a�� *[Ҕ�Y�5�UA�V�c��[B�5n�+��/���t���\6��QH�Dp�U�1sIg�q�Y�"�e�����T����!,��A���WI�gT�� w�!�<����=�X	�n��P ���?�iy�r|���w�k��?w�:u.%0LHƼ<Ȱ侮*�4�K`r�:��c��S������֢���d!����[�k��aF�����]hԊ����^�9
{oњ�C|���ā1�XL� P���
E�`�Z���)$��sƻޯTb�A���񁦨|��v�H[�y��2�>���^���W���j���x2�1����*��`�Ԩ��"}u��G�7����Tp7ƾ#���pow7�E�M���+�W�$"��Q��ӿ=����o�L]>���Pݡ�z#o^t?gk&�:��Ug�������b �(d#!{&G�pvt {܊|64mʽ����t��@��fT��
�&_,;�*%���I7&&�o���	�	)����A��Ѷ��YĖq��ɂK�#���E����!�O��f��r�����g_�EЇ�2Q��`�X�8k�4�Ө�BPx�j�;�9ۘ)�c%��M���3��'!��(���6���~u��t)=ʎ��
�.f��*��I��Ǚ"�]D#�/E	�s�
Aias�+֎�k�(p��L���	ޱ9�gk�&N�j�x����=��=��V�m�$;dn�$����}�Lb�� �7�_Zɺ�����IКd�טj,k��,����oU��;W������'_#E�ퟢU� �Ұ� i?��|��]H��f���xPpaM��4v{;l�)��������աjg�eT53H�"���U'k���c��E���+�b;���R��4�Z�0�� ˍL�B��d�e"P�]lO�7p�F�槦����z�O�4�(]qW\d�VԳ�̊�v�ӓ=q]8F^����w?�a��t_;�l�+�q*��O�R	X{"h�q�y^����,,�Ԗ���-"�[��%xP�\�yH3&K_�A;��R���+���V��{����v�L�{g�Qތ9+$fe���]���C���,�Kx�:z�����s�l�]�Ў�	��5a�Ɨ�C
�[(;�`m��u���ؘ�(�	������ܽ#�g�o~�i=��o���[�F9��(��X��l̛�@�\?D�돿4c|i���Z2��mp�-����ǂ���r�F���j�n�h��$�}20�<�p���_D���y*�	$
����=D�z�'h͈5�ҤY���A�<:�3��l��p�̄R������,�d����6|3"�|a�&8��K�`Ƚ����݁�����c�GX:3��W���5]n����X�΢i!����BXn�����EJ���"s�uXE%���i%>n&ᾁmJ��9a���I�E!��yt�N��|��&��3tcZ��'�m���^�1����t��8oү������  �'�E�n/����Nf=�K���s0���@�F/����&]��0Vp?����3�=�g�MoY��#|N1F%��-{{��Şp�
uH���r�Pf.afeo�$�L�I�V�#{PHu{��0/�P-��YR6��ob������#���!(��?v��T��h�c�I���io�7��Y*9�'F�uYD3��$�s�TX��d�Ka<��K��(�+L�!-���`|��+'��.Ň`�e���}񸚖�f�+s�Z���(I�k�lE1b����"���t��\p[�V�dț-g�b�E���,˞���\�qp���%K��P6Z�����E�*9�="O_��Mt��KČl�k('ݼ�����h[�����G��(�7������1�dNS����E�B�A�	ԝG��x�mV�;v��?�>��>���R��H��z�I\I�5����	ɐ����Ɓ�@����4@ԟ��?}�"�18gj�e��.����'ܓ������Â��%���2���S^���/�
!Բ};��Ҩo,s�m��Ml��}������CL�Om}���Ԍo`	��P�q/��w����D��a�F�T��oT�{�����j?A�+�ʴq��zH�h В����~{w*s!�-�乾�M��>z��瓑�C�^V��[LGV�פ�EY�Y�O��<��	�lgvg��~a$�(H��Cn����Ҿʈ�۪��8	θDk_Hk�H^슜DR�F���������l��0N�#����wP���֑^��o�Z:|�ewA�Ƭ}��O�Y�%N	�'�M^iʮ-�&�{���/M��V��ږei�`]�^,-�F��U�Y��6e�ye(�ƻWz�q#[}M�o�c>�+�tc�q�9��$�:�ސ�Eh.�I�`�ĕ��
�B}#S�M����vZ�d���)vk�%ȉ�e:��-�����U�
����\��X�Z�1�jb4ObL~U���Ve���\ְ55��i�-!t���E_o�UyZ�D��~�����FX��AP��*��g�)�׀�����TY���u�tk`<g�R��T�LVH�Ut^׳G��J�.!粮(3�$�j��SB��+�S��T���W���� �����x�<*�
v�;�Ż;��*�K!Q����e���Y� � �J��C^s�x��A��:��MB��7W��pc��)�G�i��8�ڈ�׆��%���dl�qp��MgD�W��R,	�\u~K"��y��VNz:�t�8�`ޓ��>c��e_�8 3'�)����Vs<�Ow��9AAž�e���¹���{%T�`<�/����L�i�H;fۭȧ�ߥ���D�o�|�h��M����� ONRdiFb�����L�:LB�<_�� ���׹Q�ͭ S4�_�� Jf�d5�X1!^?˴=4;�pӈ���g�������"��S1g�>\R�e��>
�1�_5���-Bq�˞=�46VQ�}�<P��2��T0(ʦ�ß�+6kbj,��RR�@�ﲿ�s��K��&�4_e�`� r��$��t9����<Y?.�����ݴ0�}c/�`/�/���W��b'��|g _툱,7��4�)k��U.��)�c�p@�h��i�P~j�����@��� �S�ߙ�,��}sc�b�׺�$ߋh����ۛ���܇��P�A�i�҈�h��u:V�m��e[&R̑����3���
��uԂe��*@��DZl�e�0�4�FSѮ��_\P�p�R��~�6!�-Ae]�l����ތ@f�,��Ui�C��`��A���Ւ�
ݚ�yTM[�"\�VC���	I<փ���+4P��־���8���}���������&�U ������b[����wϬ������I��žih�E�
q�ǅw�}<\�5����60)-��b3�lC�� u��@�����`���( �a3�dE���6�JMU�@��0�@;%b����0��a7 Fj�t9O�`ǞV��6��c�Q�Á���s(_]�CF�)�5�F��/U�t ���b���\2]<_`v���r�7���#���*R=�)T��0)*�э�&�!�G���7|��4�Q�9�MO�mJB��2,;�a�.u��ǚ>vD[F$V��J�7| ��*�ib.�$����|
2�uC$v�s��w��y��B����w��6��|P(���!�Ո���X�*�t���<"G��#��V���L�����km�2�$�)�$?��#Z�Xr������;[KwTy�$/'�d�OV=P5	������e�c�K�LI�G��ny�%�{,�5��S;���/j��G[^���(�v� ��i�O��ص�2zYߍk�j��w:2�"�g�<m���4%�Ӯ-q�A��]34����.��6C2-B��]:�yK�Y��T;k%��4s<�C�m/C�H�WztR-}.ͱ��"�ee�k��$KP��Xͻ���G�i�ݶ��?�u+,
+�1��{�߻[��	$�q$��tY�G��Aq���cU1�R�u)�{�{�}-�BA�-P�۝,�@�HɝX��d��V�G��1C%���84Q��V.i��9��cEZE����&��I@�����9���]Bk3v��s����������l1a*�J�2���`UTio��SU�QE��Q�����G��3�?E��v��BqV�@�<$,���p{������}�0b4:4$�K�O� E��?tP�B��ا��iz!L)�d�w�du�����f��+ׄ�6�=Oח��F�ȝ�:E�_^�O�ui�h{�X�����{�իp�o�g�\7���/�.���s�+}XQj���݅�="훥\�S0%C�`����C����$jS�	��A���]��r�<�n�sT����S�\��lp�dGd�0��:�����;���6Ji-j�/lL,��wDDI�VL���4%�>i�NE��4����M9`�����J�C�rW�"�t��/��`W-�Q����p�5�Υ�@�d�"G /@p��d�!ǹ�u���(<�����R�Ǎ���5L��9?]�rB.��J%*N���&~�!�ؑ���mX���\J}&c�Q��r<��uI?dź_#9�u|y}���̔���'X��{u�&<�V���rbҕ��>? �Xq� �e�C.�O#EĆ<h�g_���g���#�-�!�~��|Wwd��Rl)���3�7�r�k-���xn9�� ׃�U�Tz'4��w��;�4c?���n�[E���j�x�����pN!3��#�n�C�!�g����O��F�V\WS���X�@��n����ߘkT"�$0Mج&fx�h���s��Vc Տ�@w�Z=�࠮<�s/X�k%6F���5o�X��9��A0��t��̀����#֣�Ŗ��y�� 28��[�":
�"z��$ �����[�����NMKʻq���.�� ���H�:���� �]�fE��5әS��E��*�-^�X�>B�{��s;��Q���B���\Mȟ���v!�Z��Z;��n�Y��+�_`��E{�����k�C2*�����<tPV�%J��Ғn������#����Ne]��%����!ϕ����S.���n��dZs��cK&|���"��\��%R֥��8�5��P�>���?��*��4�D����M�$��.*�Ҿ���L��Z�\Dq�PR��V�?�E[�J�6� W�M�hR�l� ��Qm a�J_oh'�]Έ�:?(�R��nv%��WՂ�H�-|) 'T���FK����k��=-�gN2M��xr��[�oV�+A�|NMtk��I�'<�PN͐S����J��{���P��u7?�K^=��s�i�����N�T�C�9˛���	E� �T`�P� �`�TPK��p_({v�!H?���;5�%U�q��$%7�f�/n
2���|KtҒ��k��o�<�z�&�5H��C³��jHU����x����=�;!�<U��;�9ԥf(T�!�\�2K��
�MT�@"%h}튰��d��&v����/T�i٥��.)���W	���I�HGO;U0�L�z���-�����������Ă�:6l�>k��M�h�,�3���	f��I��Y�|���U֊�2ߐ����1�����}�O��,��"5ҹ/��5U�%��Ӽ�����Js��A����{�o��m�i7��R�w�րB(�L�?t&O$��Q�_(I�R��ၑ=�O������e��9�� F[Q�\4]�o����g�d/�ۓm)QX�D���+T��`&���'\����w��">N�슴����T���+j=��YK?|�ܕ��cnF��ߤ����:[1�VI/��,j�9��&���82���!��7�܃jU��^�v_hOW��1wf�u+v�U0�����k"�������U�雗�ѬڐmE��k�(����rq���FL�a���{ ~�@z�[�,xt�G�q�<�V�@�[ވ���56<V
�Bv5�w�e{1M`F�P(�~���E�f���E&�lF����s"�bc�������g�^��pu�!�k7�fwG�H.�B�����lv;�(P�r���j\��ˠ��Hy*�w��Qg�#�=�
1(_=F(�5~BKP~q+i���{ܔ�֞ꐥ.!_]�â(�'T�W� ��4�r�0AW�W��Kj�ڙ���u�v<M�����8�N��F��a]�Bx�&�c�d�ꫳ�{��?�2����:]*E��,�����W��ړc���|�o���v�b���2ј��z),D��<��,����m�� �4��ͿM�o�K�2y�n:I�'����'&N��1�#���yG�w]c��J��R/
7Y�d��u��Gy¶Vh>�ŜZJ�y�E*#�Q_�ص�F��m-Ӯ6�[�d�:�zW��Z�:)HT�:g�?D�_�=k1�>�A5B�5�����D|��E�.:�1Z��}��63;F���B���ۿ�8�h/n7��+�:��w���9����\�o��9��x�*
�*��ϰ|�Q�*�kVag8�Cg��y�ʡ�� &cy�#`���Ke<v�n�Q%�.io��O�8���XPY9��A�����K*q�%(͵a�!���XX�EY��� �), إ�}����AEu�Fm|<t�sc^�܃�l664�z�ya�4��=l�!�hDܖ:R�u�+��1b�&��Q��E�ſW�ӠM�:�
�����Е�Zk���b��qS:Ev�����h!�轨FOt|H��C�"/=),T��z���c�����Gön�*]K[7(��Qђ�Mj��B�9F�i�l\Y��S�o�?���/C��V&u���sX�'�םL���t�)�fhI�)�A.pg��;�-���O��r|��A��=m��wI\���^עj��t��6f�_����Ϛ!�i��kZ�"�*�����(?���!�1붧�vC�w���D������ghn�J
��̅�ٓ�E�蕹8��<*��@�XG����(H��#=̠��5*2�˩n�yì�ZjF�bM�Jl��|
�]�)s�C��X������W��;�+jHR����Y+�{���8�=�j2O%�J�# \�T���p���9;i��0.9t�Ah��%S}�����Ȗ����ŗ���!:�N�JGN{��l���0^��T�Jr!G�G�~�4<3D8Bב��X&�{�]U��B���:G-T�����9=6 u,[W������i����� �B��M���"��L�|\�Ӆe%��@����#��46C%�Z�g��Cg�J4c����r����IN5����ީ.���|BJ��#m��5DGcx��b<Cgc.�U��|k�gq��3�"zv>��}�������̓�[;��i=u�,���T��0؃-ڇ��Z۫�����Ҥ�2-bYR��5���#ƙ���%�,Z�;�q��K*��w_��-�%�H�D}��8��Rq A��%55L0�6{ӥ�!\9HZ�T�o�S@Y(��8i"d3%�(S���S��w̩���f&>��a!1����TMK�+ _Re��*rw�C�A���YD-=3`�_,L��y����T�����+VLj⍟�RBF��n/K�z����iĪ{���U5�h��J���Fy�?�d@	���ŖS;�|��d ���Z�Й2,�7]�Ig��#�U���5�"�$@$�qTU� ��s}���4-�}�Jζ�Ǻ6&�;����/S!������84;�I����q*mg<�HbS�2��tG�#��S^&r'��&�d�-����#��H���\h�����1L�T���yfӇf�mfuJO"T��r��| F2�^ɰ�6Pu���<�=��]�Aj���o;΄QY�)�\�#�(G��lB]��	�����`uGmF���^���@��^o�����+�a��$L��N(�B8�	�j���SՐ�("7L�yUq0�ߢe�F�8wa����fQ��d��n����x7vΕn)�g������8�Uj6z8/���1{��y�z�@ȭHyt��Á ��f0O�;l�quն�~A�0�jS��z�m��Ť�&��z�:�����7۬)�#�9�?�B�Xk�+^e�yʻ�@X�8wY|U=���ʖ+J���֙���M�
�_�y��1�]C�8�,����:{�N�V�����B__��)���љ*Ǿ4B�-ZY��|e>ĕ5m&e	`�������Shm���O���[����/%�h?`�IFm) ]�^����~��%��|E���]�)���w�ͩU���h� 2���0*\^
5|3q�<�FS��L�$^p��$AJr�z���ؓ�s���N�o�6]���q�d/����^�2�:X���8��r���پV^ytrܹPDv<��w���lH�tj��P1v,I>� �����߯��׼I�����������}T�ɸE�+� "?>P�����bڅЈ�M5�#�h遥�/&�U�1�9��"������5���^$�D��n��V� �<[8mFF��S��Djֿ�83����iYK�Or���.�mC$�s�[�0�/�-��O��)|�4�8z#
W���CY�C0�T#�#�w��Xy��Q��X���._�Djd��CE�V�p�X�0��Z�O\�C.w�o����Zq�� ��#2�e�>�𬅌���F+�t�x5>���+���; L:�Q��:u�
��~�B��=�o��{n���?m���d$�����uʩ�H����� e�3F�x�Zъ��^5�gsļG!�55{�\O?�Rm��F[�6�Md��k����T��5�V�X�x��',�����$�WH�}�'2�X�cP)��<��ܐ�Y\ۼ�8TCǩ�j#�d�iǡ�Od�K�V���6���V���(�V�я����VrGC�!�����>,N���O��v�*A�	?wO�vG�QbQu���?9��K�L��Ǯ��iUv꙳#(4
��F|]��LQ;����cͷ�C�Ij���R&+$V� �h��o��M�nmę��.s3N�(������AR��(�lG�ۨ�J����֋t��K8.s�?�^�	�j%�r@�u�לg�^���������S��C��pcKb���%�(�8]��l�5���6UoGL���S��5;�Q�L�+�N�@ޤ��}��=}�ט��b9�2�aZK�X}�Ո��t,(E���K�{�{�4��0� �Y�:Q���m��]:��i�!�S����>M�i� G��w���P��T�9t�Vצ~�	M�
t��Z�R�7��H_#ڐ�p�?o|�:�o���������L���LC_����j��n3�axs��V^�U�B��a�laRdO�������tˉC��O'	���J|�aw���8מN���:H���BB��[M��*4c�vW�X7/��i)�}@uօ�wW����}��dA���k��t\�Gȓ��qK	Ӷ+�_����O�y;M��GK���ť�@��s�?i��"�|�1��m6����<�O��G(�����?�[��t���5p٦L0Q�a)y[j`Dw�(>�̆3*�+p'�?j���x�)d��\���hV���V�sc݋S��ƃ�˅[����k�J<*@��-�f�A|��8��egd��tFi�b��顲�|_����s�sF��p*	�Z�����[�#����Cy�K��j��)�1C(Ƕ�Gq
�[�&�߬��)5�gu��L�S�{��qyQ��R��-���sd@ˮfǕ�#��zx*3�Mqsu�dUr1O8ݹ��n�ݖ�!}R~����w��N5��-�z�Lۙ<[�'+�g�P{������� ��9*ql�+ت��Cfn3���0�t÷QЀ�XzC?3+��r>�M��()8��_����hi��e+���������+�!�V�삏$�i%�S$Q�QŤ~_ځ�#t��3u�n/�etTBl4Y3(����/F�Y4�^���%�ݻn��s&���V%o�OZ�0V`������b\W
�������Ȇ� �~��-R.�+X��D|�H �Ax�;�}=�X�+o�#<)V������vޣ�]�����8ݭ��:B������kZ\H�3�[�Kx*�fXP%�1q^x[͂Q.�����38�җ�pzS�,��~T6Iž��$s�Q����]vR�g���Q�𸘞���S��0��e�~h�t/�Z�?m�"ײ�c������,n�K���;������XY��n�����7��Dv�d^�^�b�1#���Ḡg��wW�����#2 n&��K�>�lp�n;�\)�W�T�-$�Iݦ���qc ɻ�2�(E���E���mD��Ie��WA� ��/�W�&*��MѾ#
*4�!�MpK�s�̼���kN�|����En\��<��n�{�_�`$J֖j�oS\��ɩ��U�v�U�$5�!`J���Z����`����wa�
#�=}�m���?q^��Yj/�w�؟'Ǆ��[�2��e����-�\�:�
K.K���V��^�VX�0\W-�`4��fj��e�	UEO4�`�v��џ�N������7��wǇ$9l{p0=�"�B �7|~S��;l
E/���9t84��o� �s]§0�>v�Z�OA�:TU����'��%[ij�m�����LaL����x�����G�oDssj7�5�4y��`BuL���7��Ԏ���&"Y�Ư��+[�W]��v��Y���u;���,��ԧ$�32�n�>a�
��m �,�X��mS�)�S T/�٥��Ps/��pؠ�#�͓���_p8 +�����r䫶O)���euD�(�5zF}GzTή�Ȓg����@k�^���i�|'1T���ɇ�+�n�
Ixp���y�� ��+v��� un����ﶇ�X��K�ߎuz{�����b����_��a4���Y�<Q��,Ӷ|p`�X�)G�L eUn��R�ar���C9�,���О�`�ԉ�wUW�V�co�eAV+�f;��Y�����Cb9.�|�a�E-6�'�୞�q�LCj7_LJ;���"ܸ~wH�{X��]�����Ԓ�GQ�(s��2Aܗ�-�uZ��2t�.rork �cP�Gqh
o��[Uvw����mx�&ο���'�+2.ϘB��u�Y�S�h����[�������5�.�����U����j��e�LM<)�:c�]mv��4ʻ�Z~G�E�q���p�i�9���m>B`tɳ��&�Fa�����O���8���W�K��du�)o����J�{�0t�]�f�+���/���oZ��mC��ʍ%�l��Y�Y9�$D�Z!�0�G��Գjԫ��Q�2V͔�b�]�C�S��p�p�]|��3��XF`�M��o�L� �`����W%���\���y��s�Gu+�N�#AoǏR���
d��m,�{j>*��.X֌�(�Oc��|�Dp� �0����[��&�ӹ�1�ÎFN�}�ա�J�� c&ƒ�LE'�^N�/�J��m�o���H{��a��U+.�đ؋��΂.�ႜ��A^��s��,?��}�/`�h�];��	Y��س��)c��Y-��a���NS��@��G!����p0�*j����j�c�J�pja�m�p�C��/��FM�v9bt�}sт_�XS��9����̃իn߈U���0�Zh�'�&���\� ����M˚��U�#xK��� ���������3d%��o�:���(�DGB��pO�2, �h��:�Ak깦�LX�>� �t�%5�r�ܐ��9J��wRl��8?�����_�
���䛕���M$��3��cn{>1�B��ε�k7E0.���fl������K\��85��Z�w�))��ӡ" ����&��h�wzG)9�9O_Ĵ���#0%�T���P�&W�{���N�.�gr>^+�Ĉ�EE�.���΁�u�K��H�*t����˛=�ow�
RB<�nL�c�<2����X�����+�wYj�\z�1��T�x,vRҔ�ӱ����~��b��^�f28���6#I�������׽��<c���3��Im��ڭ g����@�F֫��P7��?�&n�Z�/Wы3�J��T��:!_r��L3[G
U�0�& �V_� �y�:"��b? ��&tؼC�����=1��A���K�.){�=t�Bx8A���鼻�UN��x��A�)b��T�WQ���E�:	->cf��`B���@���u��"���]���'ڲ�����j;��Z�)d�Z�Od|���FJ��o���	צ����U��x!�A�w��}"��	�|?���3vg�$�H|�,��K	�x#�����s\�ׂ���`��l,%D`u��$���=���x-kZ�4��k<�}\@����L�H�7�ȁ?zh�"��5c=�k�V�>�!PKN�M��
>ڱ�6�1C1�$ѵsHs��S�yo�o�6�G�� /Y�4cC�p�%0��u��y�������11�b�WI�W��J���g�Vt�-[0u2�g[Ѥ�#������,��?_�(~�����_�-��ڢ;f]��P�Tދ�>.�xn����Y��Ի[�͊�k&"��Y?�9}�%d&L9g��=8�S�e����A��U� �/�/~��i���p���/������8�Ӣ]p��}�Rlg �Z/ݏ`]n�Ult����ar���6#w0��.�����j֠��7���E5�f �Gp��|-V��"�@x.՛rT�7ȉKZ�x σ��04s��`n�A�/�̋��ӡ����`���f'�K�t�)i�x`'�yOV�	���x=��J��J���\�R���y :w�HQ�k�e�d���	�cmn	u��g�fpR��.Q�8���c����Yw�rP��1�c�,��%o6�3m=w��FM�_0g7���v�1J�����a��m+ؠ��O�L�֔����:/7-�-MW����ϝ�/8�A���4���W�*��������K���]M�D�\�o?5��N
Z�y>��B�=�Z����Se�p��N/pNp����Ak>�<�!�>�Uβ�%��ê���'Y���]�@��>]*�o�8���{�U$��X��h�D/�U~��R��#�"4�-l�����&�1Z���?�T�"�Rb���2��M`"~F1Q�����0JCU`�I]&3��:j)� �nh���5���G��	[��B�q��v�U�jï< \�Zp�`����k�Ƅz7��r�!V9o*(Ci�d"�U��$�^����I��@� ��h���Į���s�Ԣ�����%'�|7WqB���kx���m��h>VW�$N0���>�4:�؟w`y�s�]! E]�y�'z\��'�z3��J4o�+o>��36��8���CnI)�U!��c�V����4r���[�pX��k���i��S�ܧ�4���]n5����_Z�/�h��N|��[��2-(lX����˚�&M���-#��5� m٠�5�/kI�C��{a���vY���P/
=�=6,Y��}���=I�L@��=Ѽ�?��Ҩo�7Ê-`$�w����ƒ��m��YiO�����(5�ϔ� |Pw�M�1�"3�Fb��L|z�ے�7��f�n^�¥I��6Pg�e{� d8�n?��Yw���*�l�,�U��؆`�f]��y��QZAB"i��y��:��9�}R++I�A)heS�g��B��	Q	�k?X�6�`��V,�r͵���Z8Kˇ��+��P]��'�STuZ���v�ŕ��� �&=q�]jZ#tN���x�R�|�fX��i��U�%��]���U1���[���o4_ƾ.K@|0��$��j�/:�i��%e3����E3(��� 5|�9���/��b�Qè��[wj�<W��������#a�f��� ����/ۊ�$�anT�~�4'�;�`�E�B�"�yb�*���=��H�ĵ���}3�����`5A˹|PdE[�S;mi�	Vi�H!Gzea�9�)�G{R�t;� �$�5���9����|לm[��$�O �b��,
������{�Q�
���F� �䮷z�������E�p/�F�Xh'#������$��bvbw����K�SG��z���`��v�M_�8pT��WM�:�8�C���y�?k?�aN�Q�������ƛ�u�#�Z��C�>� O��OrA.O���X�����h�Vg��S�R}�UvzBp��E�쒻v���X�VC�y	3]��1�\�j�`��hh��W���a��+H#Z}��g���Ȕ�	�� Ew���d��]�@����q1��ö6����E��_�>V�']v}�Տ�S�Az�U��O�x���gژ*k���a�zT1i�p@�lZ�/?��Yh�!�눶�@G�K�W��9�!��=jō���UH韋���F{��y���>n'�q��
�.�-*��`��Ԙ��U��|A��+]��<����ȵ���+�u`g
f���D |�#t��w����n�& yH���[�y�9�x1[V�3i�Z�$R�~���R-_0 }�{���J~�\������etO���k�m�5ub�f�Xz���smI5��<��EQN@:����Lx�
^���؏�=<��`Y���q�<wxgB8����CA,[��40Մ���}��.S��^4L�b�� �Z��wV��<��Ͻ����\�=����C�" �
�hw�/���1�?6�"�4�]El+$��H7��D��(t�J�)Qr�{�ɥ��q����v�;i��i9|��S�!�<1�M��N��@j�	Y�mG���L� �Js���9(H(ag��q�p�;!(#1�5��G�W�:q���3�yR��&�J#�=/�	��
@Xe�،�p����I��|�B��`c����M���;k����̕�!$��s��/%���k�e�e
T�<�8J�(��bߊb�� (�H f�s�Gԋ0�(lc��i����f�,z�S̳V%,F0[�\��(�%b�3�>Y�sG� T�k����ҽr��������eF:�33�!�Xdd���Tzs�a��ˎ��m NNlj��'�|�<N��@��4�%b�3�$�w�'�	�Ϥ�ic{��Y�Z�yo�R癫a��Q�8�.?ĦN6�{�I/�&s�tq������_ aj�Ntc�v��0p�b�kp�w�9�H�K9l&A�ˤ�T|�$�Ը�R��Xx"��@(k<�b��:�c�4`�#�q]�頿'*$����[���ea��!��0RC�����F�����q��UՂ~����K�@���  ����v?+�v�O���.h����?���9�z��q���毫X��"�U+d6D�CӍI�%���h'�)���fj{wƂh�,�*�dG
�w�܃ޏ2{����vM��dPvX�k����y���(�rK�N��sB��=q�~L\�.(���{9�V[VtK�����"5Ｓ,��,S���nI;���8�V�ι��%l���,@ܪ:S`=�<�4G3.A�1�A޶4/���s�.���G��[11�
D�������!�>O��t�A������G,O�#��G*��%���AFH5$���AߛӜ���K ��.�u7��(�-#kK��S,}[��uFh�y�}h�bɊH����� �����
c,q^���{ϫ~	6�%�{	���d9��;`�=�E���[��>}P1m'��+�׌�\
"�IՔc���=I�#Q0y���������׫��6����E{��AƊ���dN�agW�-�S�aҒ������x����/�w\��V��X�I<M�X�w[)�a`>��w�-)We�#5� ����|�9�A�a+x&?���w��k:Ƹ��Y�{2ë��S�R��B2�o�\�P�.���OEOx|h���lI�lL: ����D;�6*C���Ю��tBL!��P��눼Ynٶ-UIYW���7�Zճҝ�n���c��QK��Z��t-mS�g��4;2���$g�[12�����a�Ӌ�c�'��?j��6��[�q�T��3�������)�KN�HŚ�Ez.�����St���y����j��Xm6G���*R2A�mmd��]�{B6V��Ҫ��p߱=�A��eIr��Ym����u����)�Y���M���ڶ�Ag�p흤gwKr�8�]Ѓ�d7���ծ����<�(�Xd�m�h/O��Pʾ~ڛ�Y�\6����$��7%Kl$$[�������.��=/u�hxxq��?�Ց$.�M�R2��5� ����]�U$8��lFUҐ��}C��!qg�c@�x�M�LчplI��{��NO�F4���ß�VU��݃v��
W}'\�*g2���M�R r߭��9��u��ǳY�*Yˏ)!B,@c�w���3�SL���V��Ɍ�(B6̍R�`2�P�Q"��zf�A��v�� �?&�6'�������,'�Bʮ�'���&�f�I;V����Wk�R����x��B�sbb�D��1��M�F�
B�A�o�#P�Х��+T ����K�5{^Z!�1�e��*}OX�Ua@D��_��A���(e�ќ�$��j��ܣ�����f�
���KSk����E��t�c�F�[Mh�0&��֖uNF�&�o����<,�֟r��b?��w�Z�ÃC���,��:�h�c1U1�2y�b%�֘q���;) ��y�I��D���"�)��~}�'����*S���H�����;
-To�0'UF��7d��T���J EW�"�����+��aܔsR��#��ud��R���=b�:���ߍ��S�چ&6��'b^������Ӏ�q������=�:�2�h����Ww�,�SP�$u,_��h><5����Z&���""|;뉤;��n��ۇ��KXih-�-��6@�ɇ�{�Y0�(�:Ao9���w��6�i4��]bO�E~a�I�����c�0:�aC����?$��1�Hf�T�"NE:G6x]���E�:sݵ��d�*�PDF��I)��`�Ylv�}��#Q:�+������O�n�߃`W���d�ERf=����m��&(��6Ӣ��D�uW�/-�B���k�<���EPɏ���Y���p!x��nںF�n�n����,�,!@���xю/7�M���Z�z��N+�0���b���B��^�&-A�_^����tz�~Կҵ|����K�a�d�0�MV�l��_�1�/����_׷Hh?�m�����9= �I����[]'-�-�M�oL�4�I2�l^�8Q|Mkx@9�8o���d�DP���z�/r��M��'p����Y�5𝞺���ܖaDbڎ���,���E�z&��&�4r� ������{�]��q��δ��~\;�,��2�V��r=���ݍ1�q��<�(E�l1UbW	=�x��n�����[�5�;��A���5y�~&x)G�۽�G齦����gm���P��^p����<���S!��U����Iw���d��_� w�YOU�
�uW���bBv`��u�m��g������� d��@2��<u����d���m"�N �=�F0 @�,��r��X�e<gx����f�-���|e�Rh�m���܇i
`0���H��Ι�ڇ0�u�n��e�a�E��
�qr�L�JB�R�+8�	ta4��J�ޫ��/�
��l�Âb�wO��;�Np��8��CF�bt��)�;t� /�����j���g~kHA���� �6��xn-Q��-g��4��~��fg;�.���dER���`W��N��J<��#R�w`{ٷnw��h��T~|��F>~�9�4�w���@}|A���
�ْ���/3����%��6��es!�^F�p�C8����U������q��� �k��>��E����Y��3�O��o�5h���K�P�i��`�����ς$eD�s�-T'eo>-6{�g`��!.d�BG;��m�mB�j�sP$m�H߰!�����I�d�Id�p	��3�{`2���&	�e��E�����l���4��-�67C�/���Z��û������@V�<0^�Ā�,��H�{��'��'m=�XP[��Ӟ����d���m%;|R�hF�2���$I������H'i}��C�-&T'�ۦ����a�nc�VX��BJysS�(ө��"��FxO��|�4�|��B��^܃�^{�H� ��^̻���"a�d����Q������3�g���~��U�Ϧ)M�S����Zb(o��oPm�jr�J/5s�OS6�ڹHG������v& �+I�e�QQR�7��s�����Pwqh�V=]*��V�)٨M������,r��*r�yM �*���j������獚5k�k�(�n��DHF�n�۳O�̕�'��K%~a�8j����rJ����c�|H>U ϐ
�`����j�W��j+F��jгLK���񾕹�0����j��E��Sq{�
B�l�t��������T:�3�ML:�I��}�4� �Gz�.�a�@
����M!�/x��%6���r�x-/�V�dqǉ=�n#��3��;y\}Tz���ȳ��������¢�X��;���,�9�j�U?���3-mo�A~݌��T`��Ŗc�   �1�,�~�� ����j�\���g�    YZ