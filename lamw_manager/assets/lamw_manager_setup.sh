#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1728604334"
MD5="66204b07a1bba3f172c54783a278df87"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20640"
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
	echo Date of packaging: Mon Mar  2 08:43:32 -03 2020
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
�7zXZ  �ִF !   �X���P`] �}��JF���.���_j�����9\��i��/�n����j=~���.�Cr��w�3��*k4���\�:k�,}���3�7�𞰾���	+Ļ!�k�ʱV���#�k�	+��u[݌��۲�?����q��K��\�[c�����>+^T�������l����;!c�?�-S���-��T���X�U�r#D��*����c8|wVr!E�H"s~��r9�[~� ��׆��ɭ����р˘�H�e��]�D�V���x��7�$�\#�$�z�*�lO�?�}�<���$�XF�ݍr7�:��9�W�M_��{]�����Z� �X7���FU��^Z��G{����%W��(8�Oh����m��+V�����>1�s��D�5&V.E'ٲ��w)��oMUR"�N���d~�ՇI�g(����H�����<Va�-�}��x�_���m�Z���n�h���0"&���z�t�3�7��YM�b�;������HHǴ��N5O�Y4��9���~�~'�8B���Mz�@���T�_�!�=�LV.1��'nx me�7ϿP�҃���A���8<���X��q��\q.�QJ�
�r�s`Z�Ԁ�kW�v���Y,��-)_Nǅ��`������~l�s.� )�45f#������s%Fma/·�;��PM�����-��)Gb��̷9��,u����C� ��,M�Hz���|r�� ���rCZ�:|��7�����y:����R�TD �My�����.s�&��ѝ���Jt�XV!�3��`JlJmқ�9ڤ0��]�f�����qe&�~�1ӻ�Oݛ1��JO;��f���f��d�EW`b=�4լr�� �޽k�|��������<�i�O*%��Q��͵ķ���'|�/$E(��g��|wc����F�'�&M60�°֎��{���Oa�f��'��U4Ovc���?�M��B8��+��z09t�����^W-սO�^��,�h���8�v��2ĴX���h���`���z��3)~��9�FH-�
 �BZ������S�/[ ���ϧ�|&��lN��z�Z��(ٗ����D�s��(�'�h%4]5X���'8xà�	���m���رb̻�J�tb��W�oȎ���ڛ&�����C�+��K7i3��� ��ӯv4�ͥ��c}��@B����
��F������W}.T��8x"a��;�w�Y��<y<�$�b�AD�U�zV��*+xg�ɴi��i't��q��e����Z@S�m������@�9(�d�u�#����}��j,���Y����q����i�����h��� 4�.
�VC�A���m�ݛ9���A)R�Uȝ-+t�O3v9s�]bz���+=CvC(rHVb�;8�M ����I�$���e֖� M�(_���R����٥]�?�p������p
Y�K�͞6Ԛ����WY�Փ#�G��C��ʕ-�⸵]�M�����W�b3B�i{�B��>y(�!B�␊y��#�h���GI}d� }��A-�b��eZ���̍������5i�o5�V�Q���X ��p/��o�PH_E��)�#��Q)��rWf�DK� �7����f��0��0�7��2pUX���`��z�����m��}�~Oc���MG��x+|�>U�$�gƔf\��ԫQ�~�s��l��z9�[��_�����Xp���Jt�rJ�@��ܪ��,Z�o!ޚGp)��N��x�{���'�I�E�Ld�u$�o������z��-Fm�/�����{YQ.FZd/T�R�i+�AFq����
�H(<�����U���f�nQM�Ð�"eֵ{3�v��d�� QJ�΀F��8b�(Ⱦ�l��J�c������EV4>]����]�@�Nj� ����4��i�0���Ԟ�7Kx�>=�_��{�@������IP�\R��c�P��Y 1�~��r�`���0���S`�E���f��9`y�Ѯ���0�}��HDy�ӴQz�#AZ{��i��%6k��/O�R�[9��ۃ=�

�C�e�QT�W<�VY��c�U����9�F?��d��.�g���PDa �����GU׵
��Xk?abePb�����=&�����9�b)�{�[#�-��a��k�Ѽ�Yu��8�(G������d�N�;��q1���O��|��ȱ����nH�nqO�w��� �_e[��K��Ӕ+����Y;�'�{>����n0.q% �с��_U��C7�6H�݂Uz@O�x��|�������P�2�3I��~f���^D����W=I����5O�)�Z�W\����ʃ#[6�ߢ�a�kh�*1+�I�>-���T�K ���`Ɖ�l3-ǜ�5��3N��2�p������÷�:��ω��w��U*R!��y��\]�;��>�V�%�**F@��F�ϸ3��|�8��t��A�iS���	b[�Zg��n͕�C���~2���Ub�Y~uq�9��~n�v�n��7����d���	�F�X�{�5�~䤂Ox@7��F�Fy��S�^�1ȡ-��F���ei#���Z
�ߊ��i��XЅ����9���N7&3ض��3K���?d��@�m���䥭|5;�,���D(=>#;\��Up����A�л��}�{'���GS��0�z�'�Ε�$�m��"��$��݃���5۬������kF����������p��B�Wn�G"�d�e�x����<⡢�����o�^덢��b��a�}�(�f&�d��H��~��ƅo���P
�`�۬^$v��ݟxU��ݣ�'��ȂQ��~�4᷵�F�^Z���`��uF�
KP��<Cz��^<����4���̩��}����f�o��D��͓�����ka���Ih�H�%j�m�%�蠖�^y��5u
_��;�x�U��#X�����$LA?��^�����J�[�&"o)���͔�_ƙsl�{r��b��9���_1�B�c[�>8E�)����Sl8�^O~�c[�Qoߴ��"�#>��hs�A��:^����.�ʎľ�f�şjl(Ig�r��z�k�Է#�'�4Y����$u�	�V���2�̈́��ȕ'D��&���J�&K&hR�,6��/�?r�&1Q�͊.0��!b��\@sG��\��PJ�rwV��k��0���|,xl�A)N�+2שz{<�aE��yn�+䏚9�{�\��L7��#š�n^
�
��kd��AK�*C����~�X�����-y�"��D���́$-����qŃ{r��Q�2�EA*���f�6�B�_� 鸞Y4��f
_2���O6B'3��ya����Ǚ�+��L��ڲ�8�
5�xP�N�1�q�馛�q�@��ƹ9���QeIӛK6-M�ݴ�����zM�9�XP��pBo��x��;rk@8d�c�~���Ā���M-�_��4�]$@h����`?��p��&�Yz����]b�)�}���u���!C��dg:�;��(8�E(� &H��i@6�C�M�m�;F�Yaa�70�Bmj+"��0F����6 ��n���d?�@����3C�ĸ��������'ۻʣV��|�jFU���n17��/"
�6�6 W��5�Vӏ���F�l�nJ�n�A��Ү�Ԕ�do-{3�I�׍�s��Ík�V˴ΛG@PK�K0�"2�p�d^��V���Kf�q��7�+��5��,1��^1��t��F��g
���hb���p4`�D���Q���#
f�2��2�H���8x4�!����ŻY�.S�����k�����h��§��4W��ݏ��b;]��4PC�?����{��2P-@B%I��x%������ӼU%n�͕<�F�~g%Nw��TEBzZ�<!Rv� �S�_?9c�Ǔ�u�[]n�;ۿ�B����
�xny׷8���t��c���`g�~�C��q�����%�:�9�~}@̛j�>b)��ڥ%�z�	�f�d[�zi�� �=�Zך��D۴q��ى.\��%rO�O	m��֕V4�A�����q��ݽ��W�RO<e^KX�a.-�9��\r��s�f��Y��jA5��%W��eN0�+(i�����'�<�j/�͟�-�1f_`ݲD �&�չ����O��ߙ�i$�n�3����P�&�
(��Di��+��:>r5�0� ��E�<�`�#`�sR��w,�Ե��sE��0&�Z�e�솟�D�,D@o_ۘ�=m�t�c�r���@L7���sR�)윭�N��>&�;e�q��k���`j�/�n��*�@��JE���U=o���E�c�rxl�4�����,j1�oa2~�?��F�RN
�:��Y|#j]�i�M�����V�:lr�<h���ʔ��9�?�����t�]��"

��i�w�B�� +���7��+p^��Y�Rh� }��
��0��X�G���AK*+��%�Z�r�Ru�_1&~�g���CX;!د<�r2P?{�8���*���L�k"�����H�ƘWWm���'@n��5��6��abF�ùwЈ8$iPh���
6*�]]s*���D(e���0��m�yV
2K��&ѡS�����2��O]"���~��?�3��� �����A�/v�ʪ��<T����$W9��~{퉩�"��)9LR �"r�^�:vz<_q����$��w�4�����g��v�� �c���al���c�!���r�F^E�Ėg��q$����J��g���I���,�K3�Y[�qWV�9����)�ʃ��ˍ�c�UXyJ�	Q:u�(���}$�ޞJڐ&�Ȯi��w9u���������V���9�y�Nb�m�K"��0VK���1� �)L�4{Jc=�'l�|����ۇ���Uh8<� �B=o�R�CT|ENHY����	����c����T��(�Cgs�G�j,��/]`�j:�&0aq�#��Xy�4Ч��hM���@+�"G8�H�5�D�-��迸���Io�r�\�1N�]�9�>��Z���_�����1�?�	�o��V�?v^�����:��)�S�i��^��	�|�'[��\�J� ;�F��$m��w0�P�c�h�����������
fBy[�<��Y��h@�-�l�Ϥ�7����)>ʷ�$s����a����q�ʕ�!W�A�?�x�ƞ݊��v��m zx]ׄ��X����[����$��^䂂1qt:7:�$F��̝��M�9���%':V|�'����S��j-.
�����.C4�X�AC�2K��-��*_�g +��/!u����W݁x*�aEt�F:��xo�8'��)O- �����,��k�}�ˮ�a��*^��]���O ,ȕH)������z^�E+dTx��%�9_� ����E����Jt���	����c�A�ၓ"֐�>�z��O o��ByC]�܋UR�ܕ�Ӗ�ף��		��[7Xm�A� =3��Q;�4P�٧�-�����P!@� qU20R7Ț�r��E�x3���̶���a���K���%�-�˛մ[vW�������(X����5��:P�X�Ϭ�����Ԩ�(W	Jlh����$b9U{I�=*�18�	��zK�o��F~z�>���T�a�����&H���+ȆA��w���'u�����+Kc��5η���ј�j�VýAO�h�	�wT��i��F�\�g ���%�|�D*8JZ��r븺��y�Þ��m�u=-�L;���<w��\� ��}�b} Y����pC�ʛ�;�����	����&8|K�S�n�0���T����ۓLz�ղLx9{��ߦk��DZ��
*ᶸ�[�d�<!�>���]��o�������J9ta�+վ�Rƾ�Q��a2krX9-K�K�.x����Q��L�����.5�=L����ǩ��������s��p�\n�Xyq޲����h��*uە���NӇ�#���խQ�t��mϴ�)���6�K}5 :,d(��ئ���;q��We�'	W�(0rӽ����k����S�O&S%pF�g}��8j>�T���ʀ�֬���~ 1w�M蘻ߙ�������-ð��b;�e�W#��Fh�4Vn�H ���ϱ�Dc�'
���}Vñ�|C������.�J}��R�/,���ɐ}r��t���| N��>�u�|yenZK�L���6E�s	�@�t�	A@����- �N:�c�?�!��V��T��-L�7k�C#��B�r�0o��Ҁi�3v*-�k�J��;�a�@21
MDg�zhֹ�<�i�5P,��\�,��U�,��sHF��#=ᶡ�����f���AQ_�ɀ[�[ص&F�گ��诔��='BUb�
͕���a�U��,pZ?��A�u|���zoG>g��!�w�;.�Ke�E&no#e1�)c!��D\syUO^`��/�+�!@e��T�?������oa�E4�f��e��r�_�=��dK#��+|��}��m}��������ph�[�@>���Aʎ׮��O�)w�Aw�=��ߛ������l�aY*u7�(�`z7C� �{�D�i$1vzs���UU���K��Hb	a������cv'��h�Z�bk�t����\ө7�|��O�������|�e2�&�i�� �*�4_s6�oIH+�8�]��V�~��8�pU���:R![�i]�I�q"ő�,�!�����Ag��#�4�������RО���M�n��P`��I���40�����[8����jk~�}���㰞$�T��϶b���`/�K�Ql7��_?��h�������]�L�G�1��F���-���'�]�Do	��B���.Q������<?�Z�e6x֮���xa���ib���|�!y/F��9Xg�k�6���LVI�TH��-���A��lֱV�y�d��`]L�;E�����4$��.�)�����6�f�2^�y�uI�v8�x �����7��d�^J��к�y�5C�Z=*�ST����Լj�5Obӳ��y�ݑD���J�S��s�N��_J�	Z0ך��z6�]y�:%��
c�u7� XicAȓ�3s���TV�CY뀹��ø�׀��Ͼfc>Pw�׈Oqz��~/��p�v]���_�ɸ$*$|��Z�lPՆ��4� ,�����(V&"�R�֮j��}L��#_a!j#)��|�|���=�5<SQ��RSDi�sp����U��B��r��Y��k*)�9K>^lr:a�����e|� H�}����h߂]o��̫�܍���@c>�����K�y��mN��5�(�"Ӳ����|�X�J�NsP3���޼p�vBߝqϊ�c���(�T�w����?R�-�DS�]�(�(Q� FGW*�$�w��=��2��шB�a92:��Rg���!;y@�T�[ܗ�l\��f�3ޒ��������;����c3��Vc�V�Z{���1	��W����}�#2��~:���SA>�D�x1CKW���8Qgj9d�
rA���j1��e��R(�s&U�4\�:bO�iඤ=���ZĻ-�T�O��GܳK����=G�Ҁ�`��Α����7Ǻ
QE3�N�"e�
hLN^�OvA����@!�Ł�"鋇��B)�ǻ ��t��i�W��H����^����e}J�c plӠ�������˴�����3Nm�l�~�HՒ���'��e�7�&�Rq���b6����j�7�5���]��>�u'�Fי�))�s^ܦc�l~BzC�R�w�Vf����[ӝ��*� ����J~Ŭr��¬���ej:�n�z]��t�D��]T���ũ�Rގ�60�g?���.��C���pOSa�E�*��I}���fS�+��j�ަF���ܦ �ZVnz�!�_�+��c���B|��!�!db�_=|�7(��<H(��������n���32Mֺ̎w�&.���Lp�=A+���X�R9%����2:|ZB������\�~2����QK�Cu[��MWC�p�o�y�N���R�ȣ��}^���_sh��eSZ�j�^��~���¦��*��ǻh8��VMX�یM�u����z%����/���ԍ���Sf�;�;�݋�������y�\�q��n�M�X�-'��]�������WV�1B��� �NB�I��Ͼ����|�� ��;w���}Qd#<.����w�t>ev��~��`��ށ<��o�{�oo��)���o:X�M��%�,3Mvt���<�d�	���_�[��A<�)PI�����Ik��ŘEV7#��c5�胥�2+9���Ia�3�q�y�KEA��R-�"�,��{�:��T�m��F�G�G��
W'y�f�Y����<�m�q1Q�D0fŃ�§�ץܷdX�/��(�w�_[g��#EG�i�� �,gD�����BnjB;dJZ�6�(�;��x���������j�E�N��dM�Ƴ�F�����R4Iׄ���$4�p�>�9V|��$ɩqkK%(�"C��?��_�����9��+�Qo�)4dcEU��;��2{�����L�)r~BD��0��h�5�;�����#�.�D�C6��ůn�O���=�e�g����{��r{or\Q�e*�Կ o�A2��-��i����"�v�UD��d���G��$VPk��L����0����u�
�{˸.	]>��$eQm���y}L V��Ψ�z�]�C~)BF�֪M+�`�*��L^|�T��k(E�����.��m����MN����x#rPH�ƲL-��?o"�ޜ�t��b.�Wdߞ�ѷ~�3s�s�N�����e��8�l+ ��3�~W�a��a��"#'KT":���Ŏ������"��9�'� �ؼ��q&'�uy�늈_�4�s'��{�![`��顩ӵ��
��]y8M��,�r����Q+ks���$�����S'|�n��B��bf ��Sd���x�6�c�[4�ƪ�PթH[n��Y�̘�y�1�<��+�R!M<��(w+���톍m���_�ɦ�)k/*�V��A}�-ls�k�o�#� ���d3��Ƽ�s)�~��n�]��>���@ljf� �u %�� w�o\���1�70�p�o��4�z������� �N ���`�SN�7ݾY;<9�ү���.�=4�L��8�I\�Mr��C���.�_D�Y�&6�O�R�$F�S������>Y�R�H�`�GÎ88ݔ��9A�P�2*��F�E�Zk����*[�Dhn���ZDP����v;{T�%�a>=}ۋVKC%��#�\AiG�C�t��d�:���І�XR�{�ݺ��$��%ݤ>g+n�F�(hb=؅	@���E�3/�)D�Z���-�����v����������i�x��H~��5�9rt2�k&�c�;PM-��N�}�"�ꦬ�jХ.voۥR/3��:s�G�u�<-s�P��w�"G}-����Jdx6
�*���a~т��]��&���+�m1���W/~hu����]7������L�� �8���d�8VC��R$�u ��GϮJ�ʇ=�d�֤�$�5	����ftӂip*�X����Э(��G$ۗh����3�m��^��wk!�j	}�g0������'2�1H���_q�tۺ�GF���� �����O��ez�UaM��fH��':�s�5U3��SK�s�S`� SG}��s{wV�Die�}3����>��cvLz_q�[ӂ�`����aO��1���1z>��T]������ҋ��
���dpt�|饺t�U�ޫK����ٗ��4�]d��N[��cG�4{���h^��y2V��7#=��q+�/� *�%!R%}�������ק�ӥ �d�������$��\��cG?�2�-�F�����B8�-4;�$p�f��'Z1a��}e7b�
�A6��o��%#������M=36�h ^ #�-~��^>�sxSR�!bW���~vh8֮��@6P��?%n=��]X}��K��,�8�1��>��"	�L�B&� �՜�>O�\�u>b��.D  �VW��}�kyV�|��]�LK��d^e=��m��(�Y=���V7����p� �h,�H�/�c�,X�n8Jv�Jr�gH�$�_Pe�.J��_��_�L���;�c�c��[�Rr8�O�Q�m�ę�ڨ�o�W���m@�p=�j>i�`�SI6�?�l��<�jdQFu!z�Xj�%�����Qn�����1�~"�!��l�H����x����g*d�����S:�6؇�+������b.t^���5��L���
鑾�$@zy�јRғ�04�\�_:���u��,^�޽���&.#Hx����ׁ~U=;��d�G��M!����d�c���(��]h�;ơ�i���cy��P`�	Y�'������S�ߙ�]h�Q��+|c9��׮UTζBRn�@2���L�?y\�F���%����HFU/?���X������Ab�ME!/���� ��e��˦���{Lp�&��W������Rj��I�T��<K��>Ex�5Q���~Z�d�D��b�q������ȃU8�C!~��<���HJ���P�2�=Qq!}:�U����zv��/g!hk�)�+/%��������5/�����NB�
�@�)��ٔ�-4�V56�	w�_(�&%�#r�iS����+��	��Z����)��#��I�B� J� ��@�z�csҩοZ�q���B�r��t6n/h1�]�O�s/9ż$y	�Т}���ö�rl�i��$�	�9ὲm�xh�7[��#$�PG`��bj��,}Hі�i|C�e�Ⱦ+J7~�YK�QN�Dv���3�����-~�� Ձ1�p�tKS��j�ܠ/�B�6�`@��up*���/�T����6��ك����=�e&5�+g2��g{���;'-g��z-,�t���k���8�����5x�=�P7�aձ�P���r�b%�r��Dr�5 I��Dn|�`@���|�U���Y9��Y|�i�E�׃��7$�{��>��'���x�[� b�A���v(���q@!z[�ݯ㛗`ɂ�I�*B���\�H]�G�������;�L�{һi������@t�!��3�����N�ݒ	u�N�Ko�0��Ê���2a�NR+?u��П;����l��7�_������9$�d�C-)��M����5g��R�����6�SY՘��ù�� QU�Q��������@G�J�a��R�]1��9I:�H�G`���RZ�b��"�Y��LvX��&r&��e�1Xt��z ԇ�V��?T棬�O&p���[��>B��&81��8��M�G��/�G�xZ���T�AâT�D�޳�b��7��Pu�tz��/�<�rx?������:3���K�Y� �\��"2u!)��]M��nB�!��U�U��T.nW��|*�UT�3まF뗉��2���9G�3����a'�Z��	x���=�+㲏�6��}0����$�^#U��<�0��S rH��4��J�<9���1l��7�?�g�3�!9	qWM^}#8�#$q�d�}�"H�`�wO�c��$ȶJ;>�xp�l���=jLxL(����E[��~�*wהZ,$�����F��`	P74!�0���(���g�8a,dpP��R��|ut}��af�i���'�f��"����	��1BS1�="��dR���_I�ՠ�z�t�Q P���<+���~��m�[q��xx� ��r�=�u�l����;o��7��KK�2=��)� ��0�*����:l��H3j�B�N��JJ�3�VLt���$�ڶ����AjbJ�6�U.X.�;G$츕�#}&WH#�јE ����kʰ��BE�іP;H�&����N&�@��������Z��t3�>x:����לr�2��S>-��t%-�N��D�G�_4��!U���cW¾ԩab9Ƈ�S��n;%��8���[�XH��G��e�hLB�O�Mj�Ҥ�ZCt( ?�~jw�b(�[$��JlP�+�Z����d{rR ����4�Z�q?_-�.�\�࠶��C��_�z;'%�.��F��r�h#���Dԡ�i����}nk�~?��*T���y�(�#�<�Ĺ<m�!���\	��o�Y+H���� �	2/F�����7p����������X�)�>�vya�?Q2vnbƌ���HĒ`\M���O�c��sKAT��T�*I�Rp��Z�jo�_$�3.YX�Lb�a@	])b��{^Ms��������r@�.�_(��>� �q/j{�.>��1w��jÔ�_Х ]>`w��&Kd����1Q������y!�#G�Sg��̵-��M�؝�:��&q0)s*��!��)S��	]	��~t5�Fk��N@�݀R��(���**T�� 3/R�^	�E�������v�oXa�� <k~W�ߴ�-���{�]��DX���dP5l�Ѫ�n)3�r�b~�|Ѳ]��ݹ;[8�b`�Q�!On�˽@R�/?�����}����� �R�����j}�}mĚ��u�Ӱ�B�7u�1��PĜq�0��Ww�F>�D�~���|g	���5����_#����@;�O�C�^��R �|��wJH�X9q̵o�TAٰ�1~�I�mߒ �Ր�$ӎH��F>}�X�5��n�>�n��ef����`������FˊW7�5�w&k�k�p<T��dN^8k�,3�źY#(�5o(q��Q]��#����:5�s�� V����H5�+$��#?J�Ne YϠYR�7+GyG��{X�4�����Q9eo�{�jP���:0�#�|���;{��܌~=��FoF�FTn���ZtU�I%L�q��@?�k����	��_�0f�A��eћ�#�Mʁ�Q�g�\f�u�r�yiKD&}�x =���w ig��d�D�xn���ӑ��
+y戵J��ДG~6 �����t��� I���pi�bi�d���fn352��	 ��?,!2ł)-�-�[!Q)R������y�Z�N�����x��Y��\v���7w�?[_��
���
'�RM������xF���s9�#uTMt
�~��c7^u�70d�6r���-���QJ��6b�G���M�O�\8�*s�UV</<�G�b���
�b߽�v.�4D��L`%$�2�S��{W�W�r#)���Q`?o�V���8⫇-W��ԉ��P}q�%�i���x����7ɰGY�
@{
h<TR����"��T��n��xR�[؝���C��#�� Ï���	6 �����4Xf��� fr��^�D����u�N�[�r�ĺr��Y�����>�i�.Y�3��]�4���A���U���M�__%գ}���zc��o��%�����q~���U*��8��Zƪ*J������:���V��RP��->t��L�з#�n�Lqu����7N��n��#���~�����`޿�D�7�B~r�k��@��<^���w��|������"�{�[R��,J���V\<���Jy����;�C�Y�����aY���M��Vϑm\���Eܮ��3�o/�\�0�Y9@+9N�5 ��C��ߟ�z�zA�9I;���#��.ز\����n���e���i�g��OԓM�K��&ex���E�@���-��� ���ޞ����S��K�<�2
A��{f�$J����I�V9��d!]���|f��]P�*9N}m�*|�|��{$��Y��#m�����a.hN��M��[cv�{�WHe�y4�;��!t���k}�G�F��F6x���v�Tr������*zL��g7?`�va��b��~Wb�'�2j'���t�]�l4���*�ح�K^v���L�����7ps^/䋴C~nxը*VӶ��x}|�C1F�؜�ޗ3Tc�TQ���j�t?��gg�>[8����˱W�(?]�	��KXX�.-OY�ݡ	��6��ʵ������˧���U!K�[��^�9J ~I��!�,��4*?[xT$�vw��uE�t���[�@G�ҭ,ݼ2(�& �������%nin~��j��^
��� �]����L0�i!�R�˩ȉ���G&����{���O(�pDVՀ��C������xC���e�)_�rw��j���c5����7��#�m��t�g ���`6aE7R���hCx펳���m8�h=��|Gwe�쏐�)�Qq^����,W�-"	��f��nTc��%�$�X!�����Ќ@�ϱ���>@^l΂�~N\[Tgq�Om>L���KP5��5غ�"�ˀ�4J�U�8�]c?_K'��tl��AM ���7!�9�z>y�h����}�`j�t���Q Q�N�g��{[���I��+� �FZ5�ep"�r�M1!��E���L@�N�>dOç�7�郠g�Y̐[�79<#+Y�y���b�����{�W�>;�r��5�L��^
Q�z�3�������.Ñ���f�\��_/���⍚ȩ��n���}�sO �p��]i͗�����7},��[':v�=��$^ױ�NA�3_��M2rWA��8��B-������[��yK���孋����S� 6q��d�|*�G�Am�Õp%�;��kV�1��8s֠BJO�g�uo��I>׼�����t����_�aT���l��u�#�ih}^SDX�J��}\�v�#��+�j\`�XO�-w�hh^�U`O���b_u�K��>�?TWu�|������M���]�y�h�4�wR�;j�d�}YE����?��͙��)����/��w$�|�`�f����rc���up�}DtbS�VV��U�o��`r�F$��w64�����v�p�.��g�`���o�ߢ]��I#���<���u�=!������s��~���\��2t��I��]5������릹k(�f�/Y<|<��W���ֹ>��7������Q;y��b��J���]���R���x��=�Э�zV�22 ����8�3w����mD�	7?+7�[ٮ:�I��Z�#J��Sأ,��UT��S����h�;�?�����(��3��NV�����u��QOڥ��
v�'c�z����+�{�(a)۲�W;�k�Ѩ�}���f��ΊICL|��7>��n[<�4������,�o���:@(Q�6��A�OX�X`%�+���O�zh����;�?��>f�"�73�@b7^ܧ��;���_��C�l�#�F�&E��!���� �CZ/y5M6g�x��L��!ŖGZ���М{�Ua*!48�F'{����E��)m5eK(ǾA��Q���������\��@Hg���ܣ��L���7N�Wa�sOS�Q,�s�@��yhڡ<���N/^�ְ���$<MH���l�FA�w���J�Z�0L���
�F��my���t~�T�BhU4&-O�������b��MZ�u�N؈-`�ߒ(���ehԲED�H����������L�0�0')�	��8�KO]�9���tXLG�̎�K����B������/Xa'�>'Y��s~i2����<g6북�éSu�hۤ��yq�����Ξ-K�YX߹���g�-����bM�����^��Qa�|��А��|��ҩ�2����KF��h�q��q�+��{�7j��<8V����⯧ �V���"i<58�{�ghQ�`.��'��	R$b���6�%/:��EA�rOv���/*�)�N���%���ă�Q�5STHY]��Ï��ۈ��`K���dt��[2�v���K��9��v�^�l�G+�GuY�
8���#+技h實_	K��&���A�==���TE'-����I�S�^/�q�e6�6k�7�xP@!�RL'R4"v(B�uU�S�u}���4K���x�N�Z&�5�l}�.�;o��o��Vd����R�⭱4�d����>x�x[
ny�s�M"xz�[f�����ɿA>;�yB�TS5�u����7��3��@���TZ$�x� o�Q|wU�T�y���f)H��"	��Z��+�"�I�|$�֐m]�������s�!��Ҥ��Q*�⾩f5P�Q3Gi���٢�4�xa��F�~��A �n����
��II�ZO�k%��{4�m��;⎌[lɰj��^q�d�s��
�f�z��9�UU"����;���{���qg^�<Y�Ψ#̭х1-נ>\Pฑ������ :W�t��y0	��׶)�Ʀ�E�Y��֦U��sB?=���ѺF*�*�l&
i���$����M	�e!�!i$�"�i���м(�t F�
�"D�ߵ�w)01�)|濄�ת�I��0l���Y�+k^��u9�j��L����(��o�o�zH4k����A�8=��3�(I9[�z�g���X��G���cÉ IJ;u�~���jQD�h�ݹ'����#�	u�$�X��H��B#����&��"����.��9��]��G`��p˄����V� ��E�Vu�H��YخVȾ�r׳���לV�y�24Q�%y�v�V�慖��۽���tݭ��u`�{�E���}��Ks!%��JM߀��V���'��0'�D��˟��Ko"��2�� $���IU�D󙫄E�ftJ�%�X�驞#���O��H�kA��[�������� �b�����}]�<Z��F\P�,��'�F�+���@�k��e�%����%���w�G��<�`�Ҫ��ǽ�#v�LH��"� ���	�[�}e��-?޳�l~�
�{���V[%�g���z}�t5?���F�7Mm]{9�L;ua���g.SfW��s�$��
��_��%����)��2��}��$"j�&�L{����5F� ,�_k���L�I�@L��
o� ���} ����opt+�ȩ�Lc����*$���Y��<qv�;g��f!;����{Nf[
�:�X�Ĥ*�j�
t�)�4�8��`��{��T��{�H�(�����sw;���כ�]�:����oy��q���d��L��g�a�pc�"bX{��T�~�,D�a�[o[�v�/&���.�􎚾�O{������j�W�J�zi3k��%X�d����̣U����jF�B�\���U�n��q��^���~Ϛ�����X"�`���bHa?�|,,$Rӹ�.�vT�W����¶[�]*�)��r��S?�Py�>�`]�K�ͣ����ִr�*��%����Bӥ�ٮj� ��1�����a�4�xf�^�+��0�v+��&��红מ� �%7Y=���x,��<�f������'] �'��P��;��3�f�6;|uc̚�fIW��c.[1)��;Gw�����4���dc�?�3�n��`ԧ�����šT�+X��ݧ�7[�}�,$�ޮ�}:d���﷜��i��=��Q����N�b;�;���Pw9y�ۇ�G���3-=����T��ǡX�`nƶ�Ä"2�Ty�1V�Άþ !���J���ܜ���}��ߒؕ+,Z^s���2�y'�<P&=>��I�fώ��m�R��Q�]e�[��`�������Ȓ�G�_��t֞�tBf_!�$��c�%o}Cg~14G��_>ǒ��Y ��nM�ԯ3���x�����ۯ����BO5&�IV��~.�_�c�T��+��������22�«J��_��D]�]�
ʔSYO8� ��qX@�	����$!�n���d�*�ڗFVȿ��GcࢹJm��KL��
�0�S��7�~]�7쑮P����O
��o*�U���Z[�O�'�Q��6���g�,��R����캡`Z�Zb������P��P����en �>:����k�YT>�1k�½�4�h��;@�� �y7P�׳�	zI��z
t\���\�_/?�8��Ż��� �DT~�2R��*�42a����$6�T8ѝ���В%ES�����JЖ�<ܸ7E�!�s_�B�����w�������,�A�m���ؕ�K8*m��S�B|��3���2��.�Y�Q���%��z���+�ʅf���k�����.���1��F�ʜ/_�	Q^_�����4M�M.p�Hd�Qĭ?k!2�ӟ#lѭ���ɞw��k�����Dt���<$�O�ԁ�!b�cuu�j���iM$Q�Ft���a��j4ڠ��/TQ�葞�+c�/�8*�3.ML;>�5؁�&�ZSc���W��~�P�����g�	���]C/0�P?i~�:ǐ�2|U^F�p�� �����#t=��f.��ť��pD"z�h!�)<R�
��i{"?�ei���azq����T,e��~o���;��Nb���G��|���'q��9 ���>�xT��a-H�ogl[�vI���da���e�R-�t];�bc�@�S���8��*�	Z��r��k1Bp�A��E�����h�_�1�zϲ�by�t���͡i�&Ař�$Ah�[�B�o����_����IS*�}U
�B��BK1�n�"�):ۂ��A�5_i?%�0/��k��ʆ�>�.g�E�C�W�Sy4R��p�S��2����v�9AF+r�/�ꉉ�wᠼ��q-���D�����;������E��9V6��IM��V�m���7g�j��e�Y<��N,���r���2X���
#d�,r!����J��o� +��_�u+^�t��#{����9V^�V���Nv� )��,�����>�5����_E�����/�]�$m��3؏��-=)��G4I�;ٱTy�-�2��Kw������7�<@,���e�[�+�.?Ќ7��#�bf��qo��A����sr��q���<���5��讄�Z�H^xy/*l�����<+�P>��^v.������8��h�?�7�ͭ,Pgz��'�
����	�g����SvW�q�F��u�B\Z-��ޭM��[6�2Q�
��O��qW-�����u�tQ���r$t㙺}�5��y}<a���:4���V���8I�9^A\a�+�q�0sן��?���n|y���T��n�,i]Ҵ�B�x�B4Zk��٨�;��рw���h�lJ�V�&�'9���Qd��$ݸ�?�Vp����M��`Mnش5�'������4Z����')���&������"9��*�l;U���,���3�52a��֋��E��@����+��������v�J~�h.н�VQ���>.	�D�Wi[��;���T�F~�Z*PS#h��^����ݳc�
w��U��$�>n�<�P�I2�\��Y�E���
�$�k9(�O}=�h�{���9���,σ�a�����eٴR5q����Yj'��z����.��2R|h[;MWXs� �J%r%dW9�I\eh!�i�N�2|�U�	�J"���2��:Nޕ��֮�b���,8ȇ65�
j��]V�v�9#w cq�OO<q�m�E0��>�hޖ�d�K��Se1y��o�y'��q1���)��
�B�lw5���I<t�������]����j��F��(%�R ����7�(*5��e�0�	��!b���v�Sb.P���-�F��kǑ.���r{�xv�G��zf�j�*dV�)��_�q�U�hW�m2��bi|�j��|��+���L[�a���]7y[�v��n�ٝ<�k9��w�����@������\��:=�"�Sy��+))/��|]#������lWX��Z *�ѻ\� ��F	��-_,f9��
b�)ӛV�J�zd�"�M��?�܎5�ݝ�9)㥹;�Uxv��{ȇs��m���*n�r�o�kg���ï�
�ݵ�]��G���Q����s��Վ�����
z-j���M|��ڭ�I� �'�z��0m��O���3g��92���izO��+��A>���6�'�b���IT(����$]��,o���&�x����K"�r�q��S� �KT�ѓ![��VJ�/؇�
��J,!E���!v<oC^�d���ܓ�����c��p�o!'L	���/=i�f-]�)s��ո]�Tt���Aф���w��,���6��KY���ð��~�^�C��3h
�����}��W7o �������7j#e���m�Y��Ax+ ����_��mЧ~!-�1��  �ʐ���. ������ϱ�g�    YZ