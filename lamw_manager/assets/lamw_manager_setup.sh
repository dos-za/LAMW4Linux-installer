#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3138486767"
MD5="07923084b2085b024760dbba5d74e518"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23324"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Wed Jul 28 13:50:52 -03 2021
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D�����0�2-�=-����3�B��z�᠇f��Gy��&������Q���꛰�v�]6)�ډÆGt����\Br�[��P�fJ�q�����|1�E3hzm���"��]�9���~^_ݔ���q>��r�S�ۦ��_�k��Dq�	��,gU�' �[�b�@?�����٦މ{bj9u?�_Oۃ6�g�l5�1D'��N���m����
�=�b2�CU`"�D�п�i�W���Z���s��>jR��.qb�J�Kh`�+��`Uǚ&��;2{$s�U�d@7�>	��DW/Nu�:�t������H��N̞���U[�С��+ZċGT�(*�b�8�o�J[z��<��z=b���r!���גn(:�L}/W��Ä4��c`1>R��Mz�W�ǲ,5M�Om*1�ɩ�}�P�l�u]�}���,�JuKZ}�$�ӏ���O�5�R�&�{>��8��� :����]�=v�M�9���x�nf�	aW����bq�R��l�^�l������а�r����!�FA�P�W���U�}���HʨkXd�Uv ��1������<]J���+9��Y��t�Drj�
ܹz�n)ܢx����˝V/��x��w�"���Y��u�_*xo	���*��hV�!��� |�tkΘ�Aj������)��~�W=+>\YW�pb��$�1L��E�5�� w�a:�>e)�O�l��R!ζ'8��<�&�� ��R��ç�*$b��'ݓ\Z�@�����l	�F_/�~�����2�8��6�9�n�;���ӹ-�Ř�s5�'Ʌ���6��(��o@��c.��:x��f�=�	f����P��7GN��<�	���W�M*A����pU���i3��`a�#R� }�mbb�rf	�\��	�7���l� ��Kq�\�C�U��w1�\�T+�^��D��06.n�D����"H�1�U3��ɧ��+:��}��O�t��]�Q�U'"U[%m����a��+}i��y�ջ��d�w���6�3�W��s�'DS� 3x����*'������6ݦ0Ϙ��J`*Qm�N#�ُ���8.�k�3�ǨoHG���zNQ��Z���N�k��u�A͵4��y���.��|k���ۈ�d����.���7��ICF����|ܫ聶Ly�'��\^P�� ����{:��IHK�#n
�wW�[➊`�d݇k���Sk��X\n,Ii�GP��EQ�9r�+�~oo�𳧣q|_�M7�e��湰]�ɗ[�����Yl���I���2{�[�ڭ���"R�&C��s"�y�7�0(�}3��ʯ�N�Ǫ�I��ŕ�gh�(�w��%�e���j��yH[�	7�sŸ�;�@�Xi`��%��0�c�s�"��m�T��,��y����3�d���K6����Q�,�l*N�m��	Yꑍw�����i�s��j�8�) 4lr����d��T@
��:������ �{*#X���Bl=�XxS�\���R6��3�Ǵ��""��QҊ�1l��E��	���m;.)� ����e�Ԁ`�S�:k�����XPt�m��X�X������#�A2��/����/e��yd������(��"����>ȡ����k�/�Fz���$����qￏ�
�)l��=Ĝ�|#c��YĽm�:
[n��$}����̂G���x4��˜O�ډ�g���^�	���������f��6W1�)+���	��FF��RR�({ܷ�������oo���&��cd����d8˸j�G��V���]<m,g��S숤�r�
J���+I��y�h�&Y%�Z�������c��X=�8���"��29\�O/��ә�uDBC&�>SWE���Iq�
��T؛ʜU��S��Gm�>18�Z�����o�AܜyK��b�C�鱫�]F�G�?�߫�J�y��{G��f�ʈ4~y�'�)h�`�%q�S^^Qċ]���ˋue��ϰ�"eO���-EDA��m)�#��'�d��AQ�6�����,n^��Y8z[�>T\��.��ɬmK]��D�C���*�% @vl�y�����B��uo|4?c:�#�ԟ@E+&%�]G�<G�	�����z�uy�*[���e \2���Iϳԡ��BK�~���r�$=m�"͸u2*L��Um`�ٻN�<ԑ�8���!8��9pb�D�7�O���C�;&L��0h�?>�/#G��O��hL�;�Z>^��qk�}s�tV����n���}5:���ѹf�Q$�G� �O�L���=��L�>��a�G6$��	v{��L�'C��è�9�xAA�}�/�5���`���!o��|)t���Z��֍����f�����0�*����:��D�TA�n���~�U���?-�E�(R��4��j=K9
����V��b\��MuC�.1Y#y�@��	�t���ˊ^a���	�֝�=Z�8�r@X롅F0�)nH�M�e��9�g�'�����gg����w3�Y���e��q�;๶zi(0�����,g���[na��O�QՕ��@�k{��O6�-c����B΁	S��b�?]�"���p��#�8���V4d����a�.�q�j#<�b�%o+��O�tf���"������s��P��Դ��ܹp������dYs�n��b���*�����gQf
"�����%^>��}Oc�s�`w�`�f�����F�PP|����]���<�r��h��������SE5�kԷ��w��%Q��lAN�v�;�7MT�g Q"�Pt��í�b���+z�5-p�2h���f.��/����Ì��J��A7����nzmuW^�@��B�|5�ziL��X&Qa����t�-,5�U��^@���i*#���[.4�pIh!7����2�M'k�*ݐ�ԇ��;����QQ��_�i�޶���D8�,�A���v׋L�\�g�Fu��i�R�
,�`�f�H�:q�]��(U��g3DU2v�/�D/�l*(uC����rֿ�iR%I�S�!{�/�����l){�L�o���E	��+���d�*>`�F�!Ņ[����B�JD½����,��D$��^=`��0�A(����ا� ���ƿ:v�K|�vU`ԷXzh0�q>�埸�#z����0 mF|��Z���k�	ov�)��;_xG` ��@��Y��po�'�����M�BT��|���F�*G��~J�����Y�WV�Щ��xA4�c�RX���QT]Db�Kl9�J��Dig�$�5p��蔩"iI�"{U��e8���������J���W�r*�s*��>Ãq�ڱp�O�]�x�n>��G���)9>��^�o���n�\���4ߎ��9����a9��!U%�����L����G1�����C���`?aSv�r�)>f|��y������h���O�Ͱw#"������
�S��L��0��
w�_5�9=�׃��$Od�E_k��-��ԑZh־�7b>`����zTKu�,�][U`%��|�<ѯ��8f��%�l�\1L�G�3���	�ʯ2�j�T�\�����]�d"�����������(��Z�|7X*I%/{r����x����a�
�s�P)�vpSG��'��)�19㢜�S����f�>�\�0}��X��=@	mH8�d/� #�az�0��>�"L�}��8��0�+n��}*� ���T^6!Lk�Ha�������Dj���i���C#3Ѵ�-R��,ʯ΋㝏ͭ�/�/��f5�Œ6<�'[�ixS��~�[��6$󘀤b��0M�'�e;�Q͚��xJ{Y3�|g�r�����T���Aڧ�`ލ[ڰ�ƾ�!�R+��|<l����$Q{����/r@��C����X�.	^�@��к|D/VtY�u�ԛ$z�P6DU�;��P�_�o^���� ��A��u�s� {��U���;�����%fg>W~��[\s�rJJ���k�] U�c;�����8�� h�J����į�	N���P�7�����8�W�믓�Â?�D�*d�6���딖�pe���uM����}������p۽/.�;Eo�/��`p����{]��|0u�&�EP�%Q^[��Y:g�U�Z��o[�5��*�d8��n�g�X.8����ȹM��,�K��R�f��v
sqTɗ罵:� �J$i���ܲ'|�ƃ��L���d�&7&��ހ�j,��L�����K���_f�%�,`�-���Ǝ�4W��ŋ|8���w.�Ű0�8�ZObd�)'�r��߂�T����Q�p��O��/
^=q5�V�;�DFM����X�X�»6��Q�y��SO�Z���� 7���K�oI���E�J�-�
>M~YF�u�S�`���I ܷlt^�?�?,{�&�3ɷ+�	��_:y�F�Um�>��ғ�r�
���e{�FYY1�����2����-w6jSi<?�b�M���#�>�jO��ҝbuاπx�
�]aN\.Ѯb7&�p�e���y6�_�ֺ����!&&�^r���h�_
��`����k~<L�X�0�B{� ӎ���7�Խ�
4�3?�m˺�7D_٫��i��8C^�ms�������T�%|�f��؀@���C�_|��rF�Y�/ؚ��oLt�&4�<�_^8J�ڥ�Q���x|,�fs;g�]9Y����������&�7*$���
�d,y���)�t"�$�����d���f��wX-�W#fW��`��D�`�@��t]8�,c*� �a~��N
]���uU�}ï�z,}ۢcte�K����;gR���n�#j�OD����k'��j���  ��'ɯ�w� ������"�^CW#Mn���x�,��#g�������ER�n5�ysV�v$^�m�؀��*��sP���'�aCʒ��&&��	���������o���`S�`�|>S�&�Bt%��q *���`���
�m�Ù�g����8V8�ɫ\Fu���h�
�uK�K�5���C�.�2�ʧN��cUĄM-;�i~��n]�a��Է�*���-�P9T�m�d��w��~�1��{����T�i�!Y=�(���!`s# ͞f�c�������+���a(�|�{���8����?��n:�tt>���A���<FlƐ�Q^��ш.��*Y;p2��(Ct��VQ�2��D���2q	g��E
5�!���,���
=`�:k:ʩ������߬�����|O���#�(�9�0%o*�t����E�GX���srH��[�ʉ��5�Em�6#V��fӸ���F��,e}�����p&�8QX����-�������瀈�ԅ�v��°�m[k�~�x�XxB�b��Hkrt�)��̟�@������p�q����z��ms|f=��r��bQa�W~vcɟ�p�SZ�a+:��g��mA�	Tо�?�v�Rk�`ޯk���FP��`5oc�EuE�|��I��u����Gѓ�p�P� �h�K�}�w�X;J�<��V�aڊ���η-p��<׾^7��T�����D;����qa?�U���V���c�E��)T��{���LLs}?5)���D%0�o�0�H15W�ߜ��AUW^�r�E�z��݅B:x�7a��U�|;�I�����x�>"H�5�j�|S��X�q�iF���l��ۆ1)Y�����ށl�a���k��f��]>L�+�>^� ��.T?���ԉ{�L2^ ��}N�y�cl�G��S�4���|N�$�N���ܣ��7����J���B�	$�x�V�?N[ �7���{��\�J,����q����2�E>�勆������|{f>^8�G��l�}���gx.v�Q)�������ye&�����ʥ$*�:w�R���{m<�YLE�n�t�R����е!C��ѽ�?��8l��&�f_T�	�~F���U��-,Bv�����(�8yp�!���T���x�`8#�%�� R�<|���*1�	{��խ ��[�d�>twկ�����0-Y�:�^���]�����↽������{[r��+����yg2�/3;�*�U�+�^~-�J��煜��;Q:\��"{#��w�_�����[�)���>��]Ѭ���s��Ć,;�I��� �HD]k��N��xu�Z�kY���K�A�*v��R��;��U��<]nc��.Q.�Y�⧛a�������s���da>
m���
v���[����V����{#��pM{�.�x��[8�	�6eXDyr�yo�j�&N�A&(/��p�x����q����o��Pd[�g֝y���!�4J5��y&���I�;G(R�U��^EiK���7G}<�bmH�X��3p�EՄ�><��e��I����(��n�}r�d��0w$�(ZVї]��9*� >ox)k_A��-�c�J�T�L�U��7gbJ;�����G�NW�#�����(�5.B}�onѭ��d(����L ��k�E�љ͟�ȁ�j���QO6�+F:,����j�ۑa^�o�ف:BcE ����9w�x�ׯa+=�?3���(@'�|5�É����
"�H���L����s�(NI���+8�+C�NFא(Q~E�@n���.�?�
�"��%��8�!I��@��=����V����*���]��p �)�gAShUz��Y:�'5%A��Ppb�ِXoGM�Ry�����k\����.%�b���%8��d�c���ь
����j�ћn���F1<ɚ��6�dזxM��}(Ǵ��¡4�G%f�<�1��=�?|9���T?[�a����ty� �-��A�͆t��?�d����P��n��_��*h�e�c�p��W&pv�:�/�T:��a�y��T��1��A�����Œ���7�9Ӡ��6��A���1^�t�1Dͧ��W��7�U�Z���Xy��}�r��%\�[����7΋�A���&�<��Ht��?0���Q�m���dz�X��nS
���E
ZK�����<��������9A��*H�ZF��,x���A6��r�(��_N.MN�PJY)�l37j�^���t!ԣ��2f
���9��ÕJ����3�#z������XX�Ȩ�x���|��ȍ�y�aoh�py<���-R��y@P����touS�
���o��`�L��0: +�Z�`�-����zW~��Sw��6b��N�$Hj�ߣ��nIɖ���ډ�V�h\٦��ޜu�`M3���L�l,��y[�3∥�juha�F���Wq_uyu%��V9�:�X�sy�_^��	�GU�l.ꬆ���T沮k�)|�B���3!��C�a���1*�bf���R�<@}������`���e�"O=�{�Ϙ!��}mƶ�<&���wB����6B�_�ϒ���9z"_�/��o�N�������R�V(�-������*���Q��t�{؎M�����/���q��00X���B=�?p��ޮ��)�U?��Ngwb8�1+�W;�9z�;�TW$�\�Q�D��$x+��z2��L��� �~?/�8��o-��5r�ӈ�����ky�x�P�VQg瑩��)j�¬��O�
Z�?zEP!S�2G��%�M��:��r7��w�&��}����h�zZ�x�7�3.�(�>��:C �[�U�>���]�l���q˦5�agU����3[�]�B9�$���\��;ɣ�#-Et%)��m�Ú�ҥn$��y�� �m#U���֣���u���� �/����;S������B�u�5����@�������{��b���<ޒ-FX�>a���a��f�	7����-惞8*��yy ��6�5d�=�|�R�rO+���']ͳ��*�7��k�bj-9_&֍͎~��4#��*���A}w�\eZ9}ƭ�t�M�_μ��nm���r*mm&�/:����L��.R*��C����e(��
S�H�Ŧ�;I���Y�US�Xg%�2�"�f8#��#1��w�ւ8x��(S��lܴJ�'��~�<O�X�|�$�p�a;3]0�5A �(�5� Ɋ} ����`�fRNn�x!�HPm!��J�/Bk�����է�����9�fE$�*=qR���u�u����GEy�P��U/�c�+3���.V��;]���lA[ݿ�`m9�c*��ȟ��K��Z���Q.P;ԓk�j�
��k�-�u|_�O�Aau-��޹�QT0i$�m7��F��lgv+�Mx3�)�y��w�0%�$C��x���&�+����b+���O���aM�T2�Y��&q%8�ڑ�]�3�+UM0��(��v!�[���O@P�3+O	�ז�����{;�Vl"�b�p��{�I�e�
��2ԙW�⶟����5cҷ�8�c9�z��X i������s�rܱ��GNc���t�v�g���|f�(ُ *�ě�!欇���AG��?�IZA�F�r�U7��V.��Z�r��\��[��Uu�E��Sz�S���J�����l�ҳʢ�Z'g\��}�L�9����s���Z��%.�_2i�j�
��8��Z�*��D��w��3��%`�O��к�W�,>J�UT�>��UW�������2-�ΰ�:�q8
#��z��.�i�c��O`�+h&C�Y���%��&znV���"�e(-&K�Aϐ����u݈w�H����:R�Ѥ���&(��C�Hȫ_&�.�6{�!j��f/����z���=Rr2�Eb��TBe6�c�3���c���Ț��s�pD��lg��ٷ=W? � �b�Q�g��v�zsi	���X��tK�g
�}'�G��M�G3/)CW,���+�+��k��z�vª������|i�w�*\�w��;����y�"�Rw�A���rT
9�lA�ќ��~��묈���A��	e���j���&Y�=�	7W�HCj�vii	�\}"�O�vO�G5>r�%���'7Ee���L_{i=8�븱,�*�>�x�+�9-. �\�`��.)��I�T��&q�� ѿ��6Ҽ�_�"�4�u�h,̱:�B��u�"}�����/I���ص��΀���i��{/��P;��o�_ir\�:kD���S����l)���B]�L]�?��Ȯ-'
�1L�oV��l�ax��Z;Y�.�"5*���n{ZX��
_�}j:�����t5X�4�����K?Kt[W5�z8G��b2k���~;��C��#��,Ƞ4ʶ��:�9*�k��+1{��5E �n�\x�Y�Av`5D�E��b��+fBu��%|���x�(M���Y�U�E.D��	X�P�:s��F^x,�AKc}��jI����������6HU/U;��)��pͼnm8]F�z��j܏���F�� ��n2G�ٵs�7��n���
з�����N/MO�4������;��މgse����k�#-�ن�֗��y{�w�?����ǥ�"��Q�/��2��d�0.��f��<.j>729�`��U�K���[���'�?��4]�3G<��%�oS��'�7�>n��&��G�[Z9Dr[<�3�m<X8�,5��l��� �6�5K�S�����P���@�X��8b�_�,TKY^Ԑ�Ȉ˴�d��U�([N<�'�3Mz��(�߮��}�K����*�+��0�P�[<5��	p��ʖ�d��]?�W=;~6\���r�t�/��0��h	�p�+o��y7a�(54A��[G2�2�����_��^
��ns��a�eBo��9 ф��nO�dX;�a1c(K�_3r�H{���r-ߢ�MD�9�Zg���Mh�^s�;q
-D4���ۥ�N��@�
�0�4ھ}�4'p<����):T�a��mB8̹S��H��yfB(
5�} ~SR%�����~L��x�Jd��?�Zgo�|�0a�c�&�Pc���
����^��)�Wu$խy�p�k����s�/��&��kc���z3!�����q��f��i	�b��*����%W�k�f)�F3�P9�7��P�!��XP�g26E�n�f>�X�C7|J7��\�.��*�?�e:�ay��T(� ��D���Fh���-�l�ܞ����h��Wc/27�L�Dʖ�.�9|�f����m�����a�#���R�q���[�NR^��u=��k�P�L�a|{�-V_�Do��~�޲�J�z�/�>A��T�
v��Ԡ��t>۩ѓ@��{�~b�'c��g��2���K�S|-g�S�3ٸ%���D�=��Hd)�{x&�Vljj\�/���['��<�2�Hˏ�
L�{B�c��0C?JDG�e�8�etz���,+;��lV^���q���0���Ȟ�tu{�n��{r#4s�/;.K�,���}��k�L5�)ޟ]�o,(�v_B=����G&l�MC�&h$Z�(U#�.���>�ǖz>�!�<�X����EQv��Ly*��h@籎(n%�Pkhjt�҃�s�uU�=[�T�2,(q|��8��/�X(;Lڎ�( Fbf�.E�J����3�m(,Q����Jc�����}��<ɞ��Z�>C�+"o,���Pu��Oø�(�'C�GZ�B>#e-����S�:�u��88eZq�;�OXt�@᰼at@*��#OR!|�?�'Lq�X@�B{��ɷ1I3=�&�'��E`Ì�Ɖ�$��VR�RT(Ó�'�A��>wJ���F�]-�#����D߇Ϻ����s�S�1���"c�F3.�y@B���;�KShJ�q0�������D1�S��D��7�����GtՋ+g$�Z�/V5:,�u�nʓ(�Q�궪��,��j�Ul� �=$a����b�t�:�EB���p����vwaC��ɬ�PH�;��Pw�J�r�rq�
]��U�OZ�L�y�B o�H�vz�� <o�QC�J{�l�s.��'5Ui�c�6�=��>�-dQB�t��x�b�ϭL�O��y��[@PY�h�a�\8<���#��%���?���S��Um�\q�-�H�� ����&�?��3�gĜ
v-��P0��g!��KU���Kҧ��W�4��\pL��!j6/y��-��wN�� {Ņn"iަ��x��$��6w�sěy�w��I����K"9P�?{	4�+�1��5��<�_����{�@�ٷ���V��񷦊�2ο����F�^!s'��K��&�A긅],G3��U� 载��8�ӝp\�1���e(�v�5�,Cl����a��85E5�Z@`c/Μ?0�`�Մ�@��Ș-���U�4��:}�9����ڰbPu����O�dF�~ܩl"{�*X�f�Ws���qv�~���>��F��>u@�c��k���o�XP��E����^o��z^��[�����%����3d�c���V���۠�q|���,|[�67Kʣ�a~���H]�y���!n�V�B1\̍}��J]���E�7?��~y-$�+��"��`��ъp�W�:��^#��#�Tj2�ee_C�7��D�9�Ց�N^�(1���/xz�v+�{�zLd�qҟ���d�x�)��v��al츲dZ�,w6�sK�r�X�L���*��/����0��M�(�(	CW1 �ȼ�H�6f^��ų�06e!&��*i.�x�m*��Mk�"�/���sG/�_���5�˦� ��xl���o��g�w4 7���7oxx���|��7�.*�Md��V1��dm����@?-=��	9���VE��U����3�g~����vjA�n�@�3�"��7��;�'�>����R�t��͢�*��>}*S^�Κ����F����ȵ�
�?-����Õu�Q��L'��7�S�����7,��#�WK��]
��gL3S�/gn]���e���'O��h�9���;z�3�mԮ|.���6��L� �*�b����e��@�^��-^��&���@��|!����˺�̬L��*�KIH�7:����6�{9�떀mH���:�*����s�&0��ɕ�%�=��ҠQ�8��hT��M*g�IG��_����ߐn�l|���li}dO�
'G�s��q�%�$t��6�M,�^�J0%��DSJ�-C��n�z�1�.¸�J L �{G����0C�6,�̓'��l*>d���oqze�_���zCd���Վ��s�8Kz�\HHGB��ngr�&���ً:$��R��i[^v����4��� ��8�<���0���G1+ݣ��39µp��uF���E��(_����t�o(o�edo��J˦�1k��Cs����}�Y� ��[]��.5r|��������#�rn+�����A6
$��Dx$u��#�E������_���o��r�0m���V��L	7�S�60O*~��G�+H��H��fo�i�'�uT�n�vu������3_��	ם��b��B�w��U$G�����2>�;��v�/���T���f�B$��b=�j®�hѱ����f�׌���,��[�ytG�����K-���*	ң-A�ã�
3�V���j��Ud�勞�-�J`֟[ʮ���͊�fOrLX9nF=�e�lΈ�WI���6�+4�������w�w���I�ʇ�o��#����h�u�-� 8���+��[�҈\?
#&�]�S�!#��0=���S��!��0/!!F4:��Q�*]o�J�_�f[�b�0&F�U����x &�g(�a��EM�'?*��sZ�mY�*�5A,��22hIQ���S��A[q�ʟ���EϷ$�37�Mο�i�SlϿ_&BVw��;��KW#,��U��� H]����A�І=.B��NV�bן�}�N��M}2�_��BI	���W"C��5��F��S�;��)�`;=��X2\����ZJ��I��,��O�i��5���g�9||61.�Z&�����(�M|n$�̶
i�K�]��
�%������t���K�*\��8\~V����j�f��R�����@f�r���a���sH�*�[�tb06��Q�l6._ Y;��8]�jl0��ïD'�T��t��CΘ�9���SI��.�:�ڸ�WqVSL��G:�!���oA�ܹ�;D�Ը1�H�q!nL|�~����P�Mm��)���[(mn��t��ٸ�Nv"�%�F�~���~��mM�)�G#b]P^�-;Zβ�(��2�~I\�H;�>���MN�R(�����m}�ј���-�ĳ����USRW�,?� ),�~�b��!0?���.�rH��,�$|M���V�s��@����>։KP��Xc7����A�>=�նE7?'����?�A:����I�t|�g��Fש�{�$��0��(�L�"�%\�IZyA�_6���%�k�]�?M�J��+~EQ�B!>�������q���� ݉A?Ȃ����9	#��p��nQg�D�: �dKa
nq��:߱3�����Z3i����R��w3�edW�� �w:_5Z�^�u��5}�gP�7��uP���\c�mgª�ڭ���Gi�Z����id ��N���	����vK �L*bT�v�dz��}��G{k6�^/؞�&l��� H�rx����Ew���:�z��A�gPW��n��#�W��H,�R���^��6	O��RS��H�!������0����d�����X_��R��m� mݾ�w�u).#"��I� s2qZi�������n�sr��.��[��J�\�$h�X�*�h�)@��Z)��}d�V���1���n������`�Jz��2���i�����p4x�r>��=�1�.U�	��Ԇ(�c���`����%|C*�PJ��r9#~��?{O�٤9e,���)�agE�M�)�E��S�����}-��.<K����x�]Z��Y���7q縒 �	�x=��͜���6��;JE��Ͳz�.��1�m���S������Td!2^2���YP�܌��F�~H��t�N{�}E�<��g4H��f؇�`ΰ莪��z�ھs�`,6�)��^��3�tC�V� �B|��$`�O$'�'��*�ߧ����h��Z��.��]�qʑ�N+D��M�,�$�-p���ˌ����xlh��݀9Y�L����v�u�>����lx��B�rC8��3_��&#7�u�ݝ���W�΃���:rc��Wj��Y�%Or����8�e��ct�a�~.�I��*���x3먖��u¿�%�"
4��lԦdR�u�9���$�:��?��S���J��TK��S�����B���SG���_Qw�*��������_��z9���@u"�#�0�G��\����݂�@��%�k�p(�('4�8C�Рr,F� �#{�����_�gA͑������ަ!V!9&1��dog�N�J�UO"?�O�F�,�����o�͚��2�N�}�Q��7�[W��/�b����m�^Cv�@�Q0����r<�t�X�k�ل��0O�"��˗Ƣ"gh�
��2)�ī+e���:��X�@�]�<�|N{�Ѵ�+b���	ȥu:W2؞ �u����`�2��v�䉨�sq��l�k^| 8֫�-�!��Ϩ<��t�/eW��K0�1����h�%������.�&j$�3�+�*���}�]�w���P]��g����a�s��F���.����|٦�D�3������*Q�9fN���l�+�"x�|X�i����ツ4�~��v2��n����l�+_[��Ԧ���y�Rm��A� fb�v�ߌ4 ���	��l��E�)ҫ_g�C	鿇Q�w�8}T+--���>���n�~�~4�L�<�����O:$(lϓEb� �yu%���8��04T��VNb��6�T2C蝣������&�5(�(v�k~�y��
�Q&���v��*��C�|���e*w��������k�gϮ�m�z5HXZ��a��x[������
%�d^�^���Y:�PT�	A�%�0?`e�4iͥ(e���Npbـ.����fڢ�,�~�K�|Ϸ{"��\^����9}����7���J���8��I8��.��1���/o�3��\��fԩlKW�,6��T������b��f�[/��9�mu���Y�C%���oI��g(�!��8�5S��i�c����&����ƅ�x�<���[F���,-1ī/ݍ�"�*��d��v�C�N�#Iz�B�c0�!����n�A��d���s�#��۴�*�\6{z��������d1L�=�ٴx�7w������O@C���;�r[?ߛo)��Tm��sK��E�S�6��lmY<:j���6�m�E4���3�Y|J����+��/�h��Sl�^ �nV�̃�Qב�wa�\�� ]�� ��ek�ۙ�{�h������m���2u�|��<.F��������R��Jm�h,�A����N��V41��nwH#�l��h�������	՛��?l�#�S�����-�B4���L�=f�N�)_-�8�����)�!�(�~=9�X#�{2[�Q7$�Ųe���%�J9!J�>ۇ�:p��s��b�\{����63�?(8k�>���S�W%�U0\�M�!2$������ᐳ} ~�"�U=ҵIto���}(�\m�*�3�D����E7�g�B�G(ĝ�fg=�%�Q<�f�[�D	%��vGE���P��,��r�C����
�ٚ���<��ſ*�X��Hr���\���!�WA쭕�(�gJ�M��!⿵B�j��lE�'iz~Ux��~T�t�a�lAW�%�j�|/���Z�k4��4U����ƽw��n��*t #����C�(�$�*�z������HY�G��m�(�C۱u&�k!��iþ,L]Μ���)�ڜ
'W�*�`H��y�cҖ$�+���^�RY��gqvż��i��ULôuc}x�9��_�bB��;�
���#�ͪ~#�-����cy	��6�K7TD�_R����<ƛF���0�Q
��ǯ��	�<�h��A�\��t0-�ʓ��E��A���(?R����mR!���- �<���S�3K�Nw����C�O��m�P���������~΄�'5a�9�V�n�1
0��m1��جBJ� �\��U#��+�$����.d<T�`|ȒO6�}�p�w/�+�ZX�7�4�v�Y�X(�2�7���;�#�������Q잳8gְc�$Ӛ�y0�n���V�*S\Ԙ%�|M�=��z-�m�ŉ}?��:~�@��;k7f.|�c-�u���Oz���*�_ �^�H����ON;�;�@{���`(ޙ�,�:�T`�"�u�@m:Y�*����奆�q��:jI�cL�3M �l��Oɚv�r��gB�c{5��u3�zt��[��n}�^��t9��U�?̖+���;������>[F�x������'e�Ԫ�+�E�Ώ�� �]�h�rM؛%����F���ᚍ�8�+4�c�'�!#9Ń��V]P�9�FD��G�U�:"~eQ�A���tq6���E��AH�&��,��\�6lC�Na��
IJ�5��2��4�k�tȠ���M$���p�}ڲ~�a�'"�LrW(��ЂU,ƕ��iI�&��;�Uu�m��Q�iP��/���md��t`۟}�iL�j���ƽIX�w&ԛ���~�MK���,�5���/[�R��i���������: ��[�5�Z��m��>ۓ��`,�H@�wL��^���"��2yu�-��{ݠ�5��V�.{RT����b����9$Iӫ�>������pV�@��F&���n��T�A�li��0����v�3������b�7��{?�Pu�;YȥsX[���,1"y�븸�wj��Җ�m*���܎��������[_F��!�d��j�8��?��p�����4��E�.z(*b�Tav\��.����k��R�E�]H���Z� ��>Z����d��Lĝbܸ��7��%*�����=F�<����NS ��($ai����`ɜZ���#
22S�29g`�L�!1_�.�!?T�y��v���t0%�5�h��S�-U[5G��D�E�΃�+G��$,��,Aȫ������e겖�Ƞ�i͇Y��eŔ5R��kni��L� �i�s� l���1�X�n.w�����]�D���9!�5��z\��gN����@�8ӓ��.J�?�D*��u�$.����&#��cY	�^��/B� ���EH��u��Rz�>���s��n����MN�����z���j�u�x�)��K�A��H��S3%ѯp�rѿ�,<޲2�ץ�my�W�%���mWW�8�,6��ޟ��>`1:#\P&N#c�qN��W�@	r�k)5���7�O�7�Y��"�S���i6F���xk�E�G��+)�nu����U~��\<޸�g�1]��#��>��`>m�$0�54{V&�0&I��H����Pgb<-{}M[�ǥ��329v�8�#x�D諅���1��ns��r����?g�t͈lr%z0Wz`Y�1dQ�ivS��H&K:9��)e��	%��\|L^��|���ڲ��k�]lK�rņ�!�TG����P�_�cU�58�o��D:Su�W�w
1t�f	�W�:� ���DQ��f+eD��ݯSr�c#>nU��Ȟ>�}����I�����`"�>0�]ks�hk�#MO���y�7Y*![7���0�%����ۤɞ����A�,�Ub����luAQ/Г(	�лt��x�B�d��wJ�&�~C�3��v�T�8hEݹ놵�&_����O�$�8�����x��*Ù��8�l$'���B<� 3u�J�F�=�&Ҫt�x�U�?�z<�	h1M,�!��R��#�-�Ϲ��X�Dؔ���!�.��e����h�"�2K��r��rތB�Tаʛ��:�?2���H:�M���J���z�*����~_~�@B?@ޏ��%oAL(9�(���L8�k>iey�eͻn���ş7���6:�E�2��Z^��M�q4�����l=��ʝ�O�83�q���(0{&e���SM�����W���7�%��쫈���mzr�X�E��E���(��Q��^V�BB���&Z�h��>����-w'��7�E �s�(lo�f�EO|�#��S\@7q���?�oܠ��Z{�#1c�u`M�rԲ��k�H�m�,��<kKm�Ӵ��Y�����G�y������ �#��n�W��Z��R�S���{*�|^����c��c:z��q_A��^YT��H��_s3T�6�n�H8Zx����D�������ќ�l=.̒�mq���P��@�F�*�2wu=A|G�-Yk�P�k���-9����y���B���e�^�;?|�$�ש$$�PQ��9���!�u�(���eG|7g/hk�����ęL��R�fxD�d�YhL�����G+��($��84Pm�_;�7&�@�&^_)E�(@e��]β��.d��5±����{4�W��K��o��*)%���h^0[��OI��T��%CA��w�DK�6�6��~#�Mp�	���E6gHS	.��Z�� �u�N��h2�O�9 ��S;A_��c"�I����V���~�]�gY��TE�@�+���򐃓ӓ��Ѱ��K��\�)/S�������T��<�k���I�(3֢| ��o�]]��m�����s!��x�Fc<�.pj��i�G俚�c�:N�=D���'��O9(�~�PC�5�IIl*�x-Fm <&�����
)��Fp���>����g2j{x��˾^V�Z;���X��/,����}*+����lE`	���1�A�����W��U!��5=�2�)���h p�z�C��t�l}s���|;�  �'4\�:+<���gKӲ���p0ܵ���7����6�z�J�ϔ)��Ƨ/�(�o�2���+�M}���/��"��|��R�-���?>cܿD�Qfk�}�L�|޵$U�=����+Ljft��|��n��=*P��Zs�z-XG�"��dت�5u���a�F��I�S1Z�b�:�d:<����mt?7�KV�:�-����4��'�����\6�GW���@u4�$�A�?�ђD�f��.qU�_K�����v^��`cI vs8	T��)�MhC]�3	W�"��9���	�ٺ ��5�Y}�P
0�e�sO�7B�ox5k� z�o6��6�4�H�u-��AFS��8x��?���ޥ>�c�8�!~���Q��#�'{%�
�*ءm�1�b�ء�@/д {x��.��u˥4���
0��O\j������Y�znq7j���:�<Wnv��W��	!ŝ�n�y:u��㹖!�3F����1(��k�^)����!0'���+��:�<&�[�e����E��b�dA|�)�j��5��*�/��)6	�!gM���[J�A�#�[7��-���ܕ�ɪ��[�K&n�@Y�}H/� h
��
h8⺟���Eח�z�c�4�P&��5b���U
3�T49�a�� ���(���8��Z&�IԱ��vQ��U�څ�x=�+��'���0D`e�ga�v��ɦ�1��PJ?k5�C3���~rĨ#�8v��neڹ�޿mD�y@��; ��#���mj��>qWHSa��-L\F�<q��p�l��b�IP�0bG��s�[������$ܪB��9�ܔ�Ū�9>m"4p*8�d%^���Fv�K��G�6so��0������:W(����hTa�djk�Zo��?�!�p�q`����sq~��n�Z�R����7�#���YK7�����Ƃ=p�P3f�Њ�U3��������$���g�ٕ�Af�p��H�C�-�M.�_Y˸���1�/�eآL R�Vf���=�����O��u�k��pc
��*M��蛇������LJC3��*8���}���c�n�z�PN�ϩ8����뮜8?v�j9����O+�����aE�aϾ���C���F��H�x!���F���5��;��'����a����B��7�m`�S�ercJ��ek�AP ;��󔭌��c�0���/R2�j#-q2t���#��76Ij� Q23��|ZF@� [���� n��0�^V�}���U�3:Ц,��b_��#r��h~�P�X����	���z��f�ĭ�W��=�c�P�q���?��^B�-�:�Ӛ��������]�A��+�������w�_�ϕKD{�9T�tvRG���ӿ������H���z@�p�0�F�]���pU$�)�(�ik��P�"�%�Va� ��(�*I�E��&��@.�rIr&��Qj��B��E�O���(1 gB8�����̭����o�V;�v��l���J6#J%jh+n�j�
��cɇ�c�a8%�gkt~�r+�D�W���8��MMU�K����E��]�D=��
���T�TF�=jL��w�n�Fv�	�KW0TSt���b�T�V`i�w��e'���J�tLpYN�HR��
]忆�1�|�Ie�Th�t���
�"���v=�V�"=t2}P�3^灬����{��+7�����(':P88�RFz��_�1'�E�Q�I�n�vH��t��Ӊ�<L�_�x����6�e ��h�t�W���W��Q�X&sx�>Լ,D	����*����Ci�Z�ʷC��t%3����/�1L�9����c��p��#�Ҋ"dJz�2�u�/O%��:o�Y�r���v�� ���o��]���߱���Bw��0G%8C�aa�:RN�������Brs�,`u�������BC�-�����I (-|m �t�/�8&��L��W?�tO�d1C���vj���f�UA=�$����b nX��F�8��_��E���5/SR�f�J�����aL-Hl�?wtS=!���j%�ꮫ����"ZZm0�[�����Z��/�9h�_��G���Q��1���?�(t�IWK�){It��6�L�R�N9	L��Mr��,Զ�2y�"@k�n\�Ы�<\��aS��?'����hC��H���p�"��%m�c�)���[H:/%=�5^[�M���ql��i|��zr�4:�P`��8�C���Ǣ���;3u�){(Zq1g|�mCoa�j����'�)�;aؔg���Լ#a��s����]�n�;A�0�BB��� U.�`á�����.{n�A�k�� ����Y������U��M"/�N����T�o�n�`"����`�9�ժO����U��T��#�ǘF�4֖�Q�#R�#�B��[�1���j,+�7�)7j���&��abq�VM��5a#Z?�����(pg�ae�
 U����[���6�s���-��+�﹧��R?���_�n�����A��҅?��L=;wN��,G�!��O�*��Z���A����v�h�E���?�|��0�騂�J�`��&��y���頜�f��k��R��G��װ�;��-7AJ0�	�.[d�x<b�U���y?��BF���Z<��7M�ܿ�s	�	ɯ{ΰe��::��B��*���f%w:q:�{Es��!'tQw��X�ݽ70���~�	�>�VBN/�չ���҇�a;�b�X ��7@}���j�di˂*JICG���o��?3[:�������d$�)U|;�s��w��">���^N[Տ �A.�_bi��5��PZR�xh�f�9�^j��Kl'�N���݊ADR�!Z�s�7[��L�#Dv��fcC,��T���"0u���5���R����g�Gm/��|�Z��vo�c�5[)���FS�1�x�Yn늅��,�[� "#G�Ζ�����r
�*e�u��{?_?�n��
�:�ǆi��a�9��;K��ݧ���Q�t&���r|�L?Df�[�![U�����1���Qz���)�l�j���x�7��d��J���x��ťP�i����e�N�v�n�'�w�^�6Y@�u��{�;J��;�o��|T���Mu�3sAl��bѨ������Io
�"�Z�'cQ�kY浝#���=e��t�Aa���7k̷�a8��M{�� x�F!��à��Y�w�-�H��A��#�[i���>Ë�g��x�R����������!� L�MZ�w>Ɛx�-�d9�j�yx�~|sA���un�QI�ɵ=!��8pE�?(zɹ��.L���:�+7������r9�X��X/�:.N�Xc&:�_���j~�o��Vt#���
���e�+ܙ�+�d���8�����Fv�쭸�؏#��;g{�o-����Gz[�B�%��vEB81�X?s�-�'J�����ڽ\,Ya[���!^��e����B�8�ձ�A`��مG����zPb����F�Rw�g��8��1g%ߘ�*	�O�LkW&N����tB?��[��|�%�T0ٸ�����m.�ӟG�o/dh������=�o��f���J�W�'�;�2מ��� �M�U�]�ޫ��ti �W��{�%������qlO��tg��Vz$�H�WB'�D>��� �Ձ�@�J�P4��U����_��\�甮�G�E�p@P����b"�Y��AFH�Gtyw����V)����cVX(�IP���+�W
^��Jc�H�	;:�0��6��~����zDx�j�H��\
��D\��7��T�{/���� 3'�")ݝ\����;.)o�o*T~��"��aa�.��p����\Uo�y��O�m��W����*��B$>M�V5>���B�0��BH)    ��n3� �������Ա�g�    YZ