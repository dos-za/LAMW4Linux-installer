#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3538122710"
MD5="7c2e64070ba580b994682193139a2668"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22300"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Mon Jun 14 23:46:26 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X���V�] �}��1Dd]����P�t�D�r\:�[7�r�
�Z��tȈ;�dab�}�U�D�M6�l�t�f�
Of���S���C�rl,A�l�B�,Ո��j�|�F��j���z�W�}�O}���@a�qʔ�f(�wg޺�ͻc��A�g[� ����T�<���p|�e���$t��N���@�>�l!���ձ�UU�Ы��y[��T�4�10�$���h�g����!��B�7��I�pMF�`E�j�оKm�j��G�_ L��y�ߎ�Mm2���0yTZ�웇5Z�k����2N��D��ܠ	��F]�@<�z^~E�>8������V-0��)�%W	��܅J��b�����)QO���&��5%/;�c\�� ���(~4
e|l��Ƈ�C�#��$���Ȑ�Y�E˫�$4η�N�,j���7�ճ�fBJ�C��j��+�#IG����8_�@B��7W�R5;��,{�W�X�:��MO��:��(�(�$R�$��k�IƧ�;!��j���	�#=�PG�.�rI����~�;\�ʷN��Q� �4�IlCAMj���G=��^=��L{b�B��n5�II���M��#���i���yRf�[|V_	Z����DT4h�T?������|���3y�B��p��A��渾F�J���m=�����˃�̀JX�1l�JxU�S��)d�i��m�0���܅��R�V�v�h2U��؂oo$y�. |�Pl%p��E
�˳��?L�+���50��4�<<)=Ve-�M_)b\հ�-"o���*W;dZ�(��΢4,Jħ���%�^��@L��z=G�y����u��7�q�2a�X2�U5t����pS��MB�B�e�j1��	����E�jG,ې`ڶw�a�8C&Tx�1����n6��s?nx���CJ�9���}Ry7��_&��r�Z�rZ�̟��� �$�m9I�=&���z�2h6@�Yo~i��
8�i9/���J��PSʲy�0�.h��gӲz]�����Q?���J��P��^�O�L�ci�A�e���xB�DnQm�a��]�|���
����`��ֱ�O�5H*l�\O�F͡�B3jZ}ˮ[��!}��<��
wuec�U��}�ѐ��#u�ۤ	�}�D��C�FM��ЉȔ�1� �TA�ݘ*LF(���N����M��(��FP��NLl�Bx}�����_=�Bu]9��0��4RH�B�è0����~D���[�Xe>�dR�bM��Y���e���S?U%T55�x�3�^΂�d�2������r����)�n�f�,�R�	��=-����f6e�9��.���	Z��|�bmu+�Y�I�#��#���$vȒ��x��1Ln���ց�B�v��,N�j~{ԙE�s����E�UrOt�(&��vȜ
��O�:��Blcm$~�b
5�G�RS����7�b�@����e#��������L���RO���/I*�,>�S�qή<�Ў��<�p�{|ԗ�?uG5^*��B~t�c�yѶ���p����[0�F� (\1��.����D	�A-np�k���tP��aC�l�y�Ӿ�X���H=Y�!i���w#��G�T�a�2��<��n&�F,�Od;�M���K7�B?���k*P<('C �����G�-��s@����/
���k5���Z7��T/����� m[�B6��^#���%(�hZv�B���~��6\n�~��Ú,ئ�ޢ�d�$�T�.��B,s�D��zS��5�\&rV��v:��r� �P��op�+;�5�f�7c�@�k������~���RP$#�Zik��@��~&���U\kxk��Q��� ��4��}�c��?���{P�dEB?-˚����g؃��x���dJGMDw�ѿj���}���;- Ƒ��M_;�/��0��+݈�6.�F�9��,ܾ�sQ4�jNk�E�\�n9��P�
���IaQ�Q�c%:2$�����g���'<]��^i͎u����vJW���*��@�S7�*�� �q%���5u"���6�:��&�=�0���/�	��i��}"۾0^S%o�#?��<��l�hl�0��א��*��ݰ�O�o������ G��e`�u���j�F C���n������U��Xӵ���z�M �i�1�h��72������p��ƛ#̐_��8���� `���a�ئ���O&�����M�������8�ˊ7��WP�է\$��~�;��2��/�E}�})/b�7���/���mId��\~vk'�z��C.c�e8��+�8�i�Gl���/�����U_�p!g��zt{ �C�؇��M�1_.��ɶ ��Ӧc�I�5�{�=�F�{���23���;k�x�^
�%!�A"��V~)KK$��Y ��(�Mۀ+;΁�KP:���S�����~�|7u�J�� ��$h�-��:)p���:��F^uU!>9%���/%�w���s.V=�����؍��7������8�!����`���[^�5� ��M�dB�W��5�ͪ��>!�cPȥ�!�����YBP���Wq�Д��j
�(cBʼ�{�3�:�֝�7����Nz,� �wHU��^��`�XGxP/���"�d:9�t��cr%�ڭ$�)�k��;���ݫ��>�;DO/��O�}��mgiK Լ�ƍ��UW��e�`�H#I��8��_i�,;��A�5��9��M���k�m�&�&}�7�\��Ⱨ�-�Esf�dz@!dR"������Ź靟ףNQ�6�%�#�+��P[I �~�� Z�������i�sb='�Ub��g,q�%��2��@X�'�بx����w�ʎ�e�з'��*;0�'E�+i�ǐ�	�ꊭW�P�A^6p��D��A����3�"���;7���ڨ=:��O��pb���k�X�WY˫��]S�<Z3�S���w�q���`SH?�X�H.��5˵UP� A� � �bD�f%�ȶ�CT2�Ï���kg�t��C��x��j�XbNCe�iVRo��l�u�qG���C�Er%�%׿r+$�3���_Nt����1B,�I��a���z��:<�������)��BŲ���q,����T�P؏��`��vV%�e�Ģ��){�ED���!��nL>p"j��*�)�Q;N$�FɴζL���(ˊ��>�M}�|���l��tq���
0}��'�aO	��}�W����o�������<�3����}s~~�F�I)w���X6�(Ј"*yM��$��żG�4��=X�.J�>��{SUJ{mm3���@�qw2�TJg��5�\���,.����أ�
3�<
 ��_�<���pNVw��$WX�1+��Z����	$��կ E�Q7��>�鐹�>'�-UY����
��}� �'��g��ooP�&X@-���,�^���6JI�FO����r��Un٪�/a��d��!�}� dGQ���٭Dx�9k{��{���8�L�R�x/�v��o�4.�Y�=���F��������
��5lE�1;Ϋ%�L�t~�-;s@a�ٺg��R�>פ}�@w��:�fa��u�7-��Σs��n*t$�5Փ�uP�ܷJ�d�%vbWx��D`V[i��K��^���l�RX���/'GǍ{�"�B�@c��������(Z��6f���s�3,���UCR�{��o>o p}h2�i-��_y��$�y��$��s ����#ϗX�����D��v!Sq�u*WQ޻]���8ڡ,��1$)4����.@�Q������Y1ɧx�OI٨&��:`.���l��T�U��R��F�28>��Z<8�lacF!3�r�PW.������x�u��r�Ϋ#��X�����̩8o�|���22��18q��DY��V%�V�iLY���}�y_
�K�qώl����2�_��I��bJ��Mc&�>��!�"x��r�b�V�GsBM��t�j�$8��<���%���>V���L{u���v��@��̆m�0d�~8J�)տ!5Ƚ��0��LXh�;���u�IJc��CƦ��-!v�Fp]B��Zv���k���a�A�'b$�]^�����@���&u`���bՓ� �f�YF�m����;�"�?����+�!Y�9{ci�9��^�Еmm:Z7���pM�L���-���ЃGj�����Y�F�������*�Ѡ}yp�TN�3�,b���	$�u���-���1=5bia�7�"�t���:@�r�pS�_h�ZA
�ӿq�=�h��6��bz��8�$�;0��~N�n?����ĺ�~� (Y3ӤkR�9%������}����ͷ�����$a�)�����,��m���G�w'�+��N���s�|�	���r�(��86A���Pʎ/��鴨�F��{iJc� ���y�3Е=P�� ���,��#F�V�S�(deJq�����v�<޾�]Q=2�S�yd��є/lnC���6kW����S���^��o�,ы�&,b�w@�z{l�R��'��@Ftaa�M;^�������y�hNPM��(�קe�,za��(�H�۷�/3ݛ4�i��_zle��=OZA:_8�C���rԌ���ż6��!�j�i*(H���K��+���Nm|-�PX�.X��.Vw�犝\���Z޾�������&���k�I����g�Y��d5�
�UK��\����p��(.�}Ty�%�(</^���¬Y��� M��͆2:��`/�ї�z ��pi�)Z�*���yp�cB�iKh������oP��q�����cH?P���>^�3Rs�.���:䊉JWڪ]�?w�i�R�t���b��rB���8DH?�HM��t$d���`��4|��~USz�P83���܈�}H�9^(�Q �ʿVg��Y�g ����]gGy�� �#�?C�[����ɧ�B*34o�BݰdR�C���˄�B�V�~�C���=�c��DؒS�(��.懒��y�<�p�U�-�nѷM%{���طGnDcO�K�ˌ�7����ZP�����IPP�) �ƣH���J0�ASo�U"�L0`�8�E�	6Q�c����ңr��;�ŇH���ϡ�?��	� h����v{;��v��\&׹�
��	���w���6^��ڦ�e����D���ni.�T!�P��@%�r�=W�K���rV$2�COz����ID����5$�,���m-ھ^r����]����%沠��
��e��Ӄ�Spf��	��������:e�X����լܪk����(�bQ(\ba��'�X�aGҗ�,u4�"U>��S������2��K���P��ꩧ���$����-�[��/�����ȅ~1v���Չ�3Y��L��A;�6HzIh�Տ��'�TQ�ǣ�d��z篼)�N��[\"��g�.e���R�l;<'ٕްU!�>Y&#������0J�	�t���/ny�w�c�=����ߚ;<@��yI��w�'��}'�ԇ#��K5���'��h�8�8鐑�$�o�x�0����jޥ��p�=�M��*�h�$���k)�g��K�݆��
�h�,Hٺra��K{�OI�QU� ��o�+L��P-1�;��*<��Y��p��H�� �59 �eq�X�Œ�����a9!��F�9h�t�R �),p�1���U�`��L4M��q^T��l�ޥW�&�Z�]Ȥ��H�Xm�J�KvS���P��Ҵ��v�w2>�P�#P��B��ɇ�B��i)�8�������^c`��M\͏h�����g��~Bf�g3l/��������ۆ/��n��2n���/�g���2¶�������p'w/����02�}u��z����б~@I����0�{C�K}?,xF�ɥ�z�L�[�����J!����t�����l#f4.���ؽ��f7E���p��0�4m�\:ϡ�#�*�K�&<��ʲ�Y�D�t�`�y��f�(�^�ՀE��|�hn��\�Vy�/���<�4��0y*_K�6������i�m�R�{��VB���±��9�WhT��'NxQZ�EB��/�G�}�P�N�	^e�_?3~V�⋭���ҙԸ�$�Z�#��W�P�ٲ�h�X�w�|���Bd�{;�O>�:y߽�-�<pR�����YH�^�Nh�}�+F�4Y�����rw��Oc 'm�ϙ��e�y��Y�8��Qss���4��>={����L"�}�X������>��0hr"4� v����J�r�7����m�%���7'��XM�
a� �`~{ђC��Mǐ�\<x�=1��-=�o�rNu�8t?3A����TW���K.}�_��*YW�=۶H �������@bL�Õf�:O\��˶L7\����5�,�hK ��t�$��ҹ[l�S���E��*�z�x��H�"����/陥`��\電����m���&�"�_��`��<�۠�����"�ޜ�TC��6M�}j�ݛťC*��2�J����e�-�pGHn�CDg:�����c|<6�Qȹ##�[�s�
�O]"�o&��5; �:4듘޽ǭS���M깹�V@|	�a?�#��+	�8?��;`CTb,�lg�����@�.�Rf�oq$cA���+��&�x_Al����0�H�	5�زؤ�n!�l��N^4z.��"�y��Λ�O�S��m��A��K�("��;o������[���u�.e�1XiEDIp�����!��G�s���i�j��D;�#���ZN/q�J9��,jUxD�Pi�Z�sqR�`u��eqC�-�'!R-�z��A�%	�-�*�����/�M�7n�o�Qq,�2��W;c��5d5��KGas��:i[C�{1����"�9~v�����O#�����p��wF"H����D/:�RҴ3h�0/,�U�H��\i�M���o9\����2ۆ�ã9��z�N� J�2W�HU�x]M�8��Uh]I��9&ݔ�S�X�7�K,r�Թ�^ɎQ>t*��,i��}$���'j2�|��1�%���7R�K��C�rd���ފ���R����r\�'rT;�������u�͗ç8��b�pL���:&�70��#��O�[r��.u�<��z�����������Kx�d�uY0���@Wz���1�*.G��1��S�&�h�0�٤�
�G� z`y�j��⑱x��}��ё�ˤ��:��W~�����$��^���8c��/���\�]����zf�r�)�;��	V6���X�v̪#cB���E2%7__�]u"���o�KE�Z�=:���Rb⬞^́���r�nDo[�%.2��H.~��%S�P-k�|�I�,~(%����m`�<�����yW�~	�e��h,��dd���ߕqW��ˉ�j�ƺ�R�?��&`�t!��D[�݋�~1j��|F��_y�����ޞ�,�����
!z�k�ˑ�k��<G ���'��s`�RH��5n�d�M��8߉\e<�@�D �Eb�_�ҿ������wR���Ƥj �m��Y;�Z�q��n8��H2�V�^r��
Ugs�b�#�x�}�U7�E�&�PK�w��חU5�IA�Dzlp\A�K���g�۰�HlR'��r�;R+EYW����~_37�k^�3 \H��yu9�H/��#�����u�!AK��##��Ƀ����pO�^b�B��D��F*�͊�Q�a�b�H����7؛�~jz2�27��{��6EP��?c�bd���3�o��_~�7%[�_�����f��%5֋��'o(�a5�Sg L�#U֯L��`������>���B�qB͔����j����[%W�ͪ����KD�p�$�E�:�C����n�:��с�x�3?@a��%OR�o��শ\�~�������oE�M��<o[�aV�'	/�����3�6e���cjW����[d����.Ľ�d���.1�<yTRR~�{�i!�1$��~}z��0�Do�>�/ד�'<ˉ8_��Z�|b�r�h�ǳWbd���n�|]�|d�HY�_���v�SF3�b�c��� o����O�ê���;�/ǧ��R"�\<KH����i �f}jǛ��.�3�~H����P�F'M����e�Gu�7���^��.�Ǝ� �W3\��Ɖ?�;EK	+D�&��������K�Ѓ�4g�]��P�Q�7�}��%s��Z���35IdRe�����^Q������K�H��AE��S�x���/�39�2�������U�n<r͇�7[�l�8?@K���
LZ���ҽ�"b�Us�?�Λ�t"���dV`��د�j���IZ�2�!"�o{F��F��i,K�[����e%����|s�M�Ż}؞g��'����gXUn�Ԕ��ON3ŭԒ��8��u !=��H��UK�qn/�4n��4{�i���"u@B)��ʟ�-��
K�M�ɿO'����3���W+�rv^����sK�R�ƥo�ީ"i3�[�bh�h�!�A��>X{y����vAG|_\���2{t:\5x���Q��Gb/
x� �Lް�u�O������h1(j���X�LV�C!��4������Y\�Byl�����I��;⋘Y`w�U�gNb�G�Dp~���l����4'�{���LӁ^��JMeq
�E`��7���sw�$	ݮ0�IP�û�`�����$l<�������	<BWUkk:�gÄy`�U�!��je��@�Ɯ��ٕ*��,E�(��RR���a��!�2R�>qlي �p�h��2� ?�xH�n��O;z��Ty!�����/��Բ!螓�'�{䢐����a�w�l���I4�t�S!�͏��0��n
��Ly��2��:�r?3���B�����2��!� $�)}���3���O]�~����Βg{��L�vI��J�e|�HI�zU�/�
OG��"�3�<�l�_\%
y��<��ed��
�x��\��hU�\۲ꊢ,`���ۭQ�@3�K�]g�x�Ŷ��'�Ҡ��g�Ő�7"'*4���o��xA�@����;1ᚨ4�:7E��%X��Vh�V�$c%"!I�����6S���r)bՑ�Q<ŴϘ��/�%�`=j�<�@ۈ�J��/k�D����r�����Gd�>>�N�Bݴ2�T�D�S�)�@�:�D5���D��lB^�@h1"�ڴ;'1�J_���=��'8Mh��NF�=��
NQG߁�u�~��Z�����L�";����Qz|j�g�%��n��@M/��l�$q �}����?>�É�#C_<�h��]I����/I����,rke�,Ƃ.��
-e�p���_t<s�&р����X��蟣�O��.���5�}� �N :��a*�������=Ԡa<���n����	wK�{-���L���Ґ@J����i��ފ⨵�A�d�'��\0^�)h%U��B���j�ɀn��D��q ����{��ك�L��O�~t��y��e�)���ݷ7_J�xe\��0ϥ~f��Pg璋1��R=�i���H�PPup>��a��ϯ�B�[,&Bndv�#���*v!���2����)��=ޓ�I�C��|��I�*%���L�E1���ݱ7h��#��@It�/��v��!�z
��@ݵ��?@J �x�¿+�h�"�7�܌+���� ��.�'��i����%l���}E�֠OX#��i@A��u�a0�,�t@��X"ϴ�g����X��`!z�L����ɦ��~�P��� щ�A/K�p��={��9�`����_?�Mߺ,C$7��ޟk���cS�����$����"�����uv�����?}�:V�"W���!+Se��%�

6�J�Ϯ��Y�
D{)C,\�W�?,�Ql���!�M��Ո��3h��X�
>�،����^,M��g-q\����0�Vt�%!�דKVG�2טf�q3� .�B�p��!�UB�A}I�П�+��'�K��|�i$ �s����9$�*���T?Z�ގ��yq�޶b���!�n�}PA/�N)m�O@i����P+�������Gd�lf��Qff�Ĭ<B��F�{�{�"9�}��?y4(p���F����G±�sx�^�Vu��̧
c�{i�'^d\���=�d�LFo�BY��sI�M¨Xq��g'��e*�r����h��|}�5�}���"���pJ=�::R����wP����/c�y>+��z��.���c�ǃL�YMV��7d�5�1G����_�/Ŭ}y/.��R�$f��t�D��17lȜ�B�9�*��5-�����/V�M��0k�S�I�p�1��t>Њ� X��qų���p/���bb�\6��1�M��c�|�,���/�,�^�6��\>}t@ώnKR7����%�6�B3>��7!9,���X�|����!	s� �1�S~9�.�0��C�@WT3��tE��9���p%s}yap�����VA�� EqZ�|�Ѐ}����>��ڐ��n	f�it����<�N愰Ͳ�V������u�`� 5�H]E �b�}a���}n~�K2�"��q,��G|�'�_�7$p�E��T3@�f�W��I⍶�y�l�0����Wܖ�zP�����X�w���>-,��`��܄-V �G��*�CԱ�(+=*�d�ջ�Ц]��w���$Q�Gs����yx�.�E�	�>�@2V7��u�~�)��t�na��}5_(y-�F��y\J�~S����ӕ����R�_�F�Ƶ�2^�k��?F��)Ɍ̂�4����{ܷ+��_{%�3!I�[�@qC��^2�E�,4(RӢ^������������$xc��{��F��З`LdR2�t~�B_Ū�;#W_�a2�i��p(}�a��ߜ5�Z�5��Zʤ��F@r�()��Kߝ�1�?�/+���H�`>��'D�BJ�l�����m~��z�_���U�s���Z��}	�c�g�¨%a�(N�� 'dE�?NU4L]Y��L�0N��F�)� �xX_�L�6A.t��n�O��U��z���>���/yz�=�⌗��k���z�uKK+X*����}�,gJ�գ3P�������E��V��R8��A����(D.�mf�oVb�$��]��w��|BDX!�q��-�͉�hrՕ_���rR�!���M)h@$;eq����,�%�r�h���#�5jN��\�&%����z��"�����u.x�.���`�?"8����0p&�ڏ�Tc����m���8�l��,
�=/ �B3�G/�u������/_삪��M�Jy�f*�⑾��ʺWR[� ��\o*��Vs8C���>��xD�N����6%��(�z���<����kՒsD�V^��H�6��-E28���u���G��Ɏ��cJ����X�#k���XoL��%.��u{!-�Ko);��|HG��e�Zu-�w���;�������e���ܭ*�������h�O@�H�ƃ�
�N��w�#9�_�[��0�#U��_3�%�/�*�Jhs<��,2��<֡I�U�� ����F�ـJ"����n�D�����k��J%򮾸l
�~��[b�k������[���@�V��=Gr<�U�S
����w����F�iV
��2;�dC�Oø�e.�ٝxK���l�J�f�8�@=����lyT�%��~KuC��������g��k��>*2�>��kRRI��+SZ�rL�-�U�Y]��e`O$Ɖ��YXV�u�8�a6�y��j܍���nP�
�g?hg�7�zbT30(-�Rʡ��P˭PN� �1sZ�@��{��E�AߘV��EZ��_xz�2z���`�����8���G"�[������K���
�~>�-�*l�r��aZ��5J�������M���@�\!el��^0�nZ�zzd�fR�qk��)��1�>џ0����Ѓ��٨Z{�'�X�>]ɭ��/d��W�ֶ7��=�ˢ?��B1k���Mh��a:�0"��HAy�'t0d��~JيPOj3늌�x�dk�SsP��,W'���J�^q16Y��F��k<�D��t-z���n�o0�/��^b���pK���������%�ӧ��F����j�� ��(}���-�k�<�}��)�Ȳ?)"�
��5_���uG �:-2�s���KU��ɯ�-o4�@�h���
\��d<ƌ$���O*�f��r��y�6N����}-�����~]�A��u��]�ĸ��#�H��e߮��r�r��d/-����>K6��
���	�C�O��6?D������������1N��'�J�'a[�w�G�I� N����c�zCiE���2I���T�0�XaTc|���K�b�p* ^݇�݄#�K	蟽'�v������ŘkQ�fD�X��Ȫ2�� j9ğ�<�('Nk��rk6�S�V}�n�?S���(q?9��P
�>@y��(Z�N�p�R�㚝��a�!Y�y���L�W+5F7�*��2^�V���4(��P����gd@��&�oX�%*�Q�W6Te=&v���r轨�㢧��~�:�cQ�F�ЅRR�O��A؞{�X�8�g�iM�p<��wG;��T>�R���#�gt�I����M�^G|R|q]M���?��;m�#&�ѕ�͑�iq���w=��-ܬ�p
�"~c�Md�6��Z�z�lə�e��������,�(��mc��*��H�9o�S��"�̸d$��9�&v��nop ��#��-�b=�Uyg���0.�	�Kҁ) 	;!��D����e�d@�^+b�?��[�{V1�=Ug�z��&g�7.���y�/A;�Q���_���ݾ2�;�d���P�u�cK��k<�;�����)D�w��t�}2��$B'W�%��w��x�\���4����|����:�Ƨ�/#����n�E&�����W������'G<Ŕ����ak��!;�Qs[ź�:�W W?U&4[_hl���P�&]R��%�p9�w�b}�����:�`EM9Uq��	�4�b(G����`��0��k����; F*����l�G�nwJq����p��ü�E�sR��Ok1Gt��fj��sȘ�Q2"����(%��PL]��نa�� �2o`ֿ&S���AJ�;j�k%a��Ǖ:A�w�]��
��2��Z5�_�Q�� ?"Rn��z��'�1��^�鲃l��R.p�;�!����X{Y+3mR�a@[�
��9㙣�\м��>~�V�g�,}�"���Ęp�Nކ��vZd�C.�%;�{���*�����ǝ�g�2ۥG���WH�Hy8G��jӊ�Tcg%N~E�zB<C �����U����^�X��#��(��Є֓df�����@p��}G���ӚI��R�&�W7����m��4	����� ����25}��qLLw���N�yg(��6x�?�5���l9���(Zt�NY��y����F�c���X�7�4��a�k�HXC���N�X΁B DK��B8*Ik���V�aȾ�"P�s���#�q�k�A��n�d�[P}P�̑
�L�S���9�u�|���qT�y�]R=#2�����W���o����A�]��=?���]0��C`�&�(��с�8��y�ȼ[|��;��MoVwYb�'
F���LW�������
�k��=��Z:�u��sdzxQ}uL�*��cK��P�U�mqw�����es��5�-�d��>��Χl��̈́���A^WO3�f��~��dC�8bw��<�P�y=ϭ/��s�;��%���sp�`�4��:�% �u���όZNr{�g�a��X��o�E�nv�j�uph­+=�8Qא���]É��p<����kP�#=L1�(,S�Z�z�n��M�s��7�2�Se�a�8vgM�)���@�/�\x�7�tz��p3J L� ���*�����3��M�S��U,Yq1*_��3��)0L���'_��D�8��ќق!��\%^�F���m4���2������|z�4k��PG�W�;�E �,�5��!�QE�(�!���pIi����C�����d�����a\�@�46�&��Z�:ݤ�%q�������e�j�"�f�������uB���mt� �&]�!ܕ���s�7B�'g՛WFW�/��_�{y�'>`���:/��W�3.�4��:<�3����1��k��5�ℏe�T*M�FfT�����O;��DC3ԹЭ��K2�@ݸ*����O�%�*�eJ]�t���}t�,��]��)�֘����2;�}J�A������O�$�P�r}|���$���"$��be�<o��X��oce#)Ʀx8�_�uN���F��J�	34r�N��� �tU�~��U-�9�ê��	�n��ݕR0.(���{e�xc�8�O�l\����aL d�ٱ�Χ��G:�G��e�c3D3�5�1�������K7ƙsS#sV �m��@-��_C����d�Gֳ�!J:�5.
�=gX8ݷM���.փ��K��}��3S�%U�(j��<��!��:y�zbRX8��FmV�!4G���Ç�W���h�xC˲������?�+�b`z�p��.��s��gJ�;�7�{#�����-/ӻ���u|�_	��u��j�9T �F8�x�~<�:U��x��F$�t�N��K&���EE���rf���稾��WFPz����fN�6���*v�1��D��=�|8�w]/�`�F�����jۮ� -ۣ�k�?�M/�O�C�S�Q�ò���5��O2j�-�QK��n��::[����P�@�7<�Q�|�5G{�W�������.�ۍ��
w1�;�'*?�mU%X�!5�w�B0by�GE��e�lbj\�2X1������."�)͘��I/�1�T�w>���H��U����?��-o;}fWϳ^�O�/�ע�cz�$Ҿ[" ��w��Ĺ-����e�˽��C"�I����V��3����� �
�ӶsE��u�bew�&D�Ȫ������W4Q-ܖ13�:���Zf��Vp�W��mf���19�����'���t��oMb��L�dޖՙ��~�W̵��E][��z�~�d��^�2f���g:�H]�4���249����Ʒ�d��щq�U̾��\O`;�p}�^`�IM��N�Y�Kk��8i��uN�X��a�\q_c��m�����m���z]���g��)s�xgLG�/�#Y�2�7����� ϻ+�Q ��>�4Z�r��NҨ�˒'1�3�OnE	��n�� �����U%��PA'�Ovg85<J,}����V��-�XB�Ǩt��#D�La����;�iQ˖rn��{��mGt���M��piz%8�L��f`a>�.�9�Ka��~��k�"a�g��
7�𕼙�8��v���rn��<0����Aɧ̤^�C�w^��IN9~�b�N��tB�@�1�ʣH���>޵�?٫��fp��/, �U���8Eag�M$��o��5-��M�sXh���;���!.�ؔ<w<9Θ5Ћv�̸�FWܽ,V�����ߑ�+1��谞Sg^��eQ
-�߅ϩ&� �As��\a����(�r�	NrHV�=-���}7�2��a1��!�CE���B�a+T^�p���ͪ��a�֙NЄ�tJ��b{�}��7�׃Y߿�u�����L�__�� Ŏϫ��#O�Giw�*	l}��y��Ȣ�v����!m�,�%�f8(�qc���d�v)�f��a�>�}�ϫ�1�[mӵ���7�3f�Z=�(\`ڱ�%�^�0�Q�}��⧶��ʆ��n)�vuX?��>�0_.�C�M<9��\�+w�Ы�Bt��4b��b��@��Vĉ>�+�9�iw�!Pw6�%�}��y{v�t�dyhq��C����2lO�q����t̟���9QFfMtZ��Ku�(�~�_��5nA"��Mz�DD��_�_{M�<�A{$�=7��źSJ��Ti��*p��i���{k2�y���=��v
�0�%��TG�^�'�\�E��݆T�@����]%D,܀Fj� ��<B~��*��v�ΰ��Y��x�biK��qj��d)!���}���(R{6��)�Ab���8�%+���JǨyi ����K1�	sU:���7��- ,��5��s2�)�0����o�����d�.���9r,O��>� ��}�7I�f�H��^;���X�W��RL�)��&�&��� ���@ϧ��o���@%��ˏz$Ttӌ������X����v�4��7�Y�kg��>3iI�InS��B����t��b(����E=E,"��T��E������(lx.���b59���E��6-}�����_���n,q�R���4rhH�~�~�ԯ�Y��Gu��Q0��\;T)��T�^�8�ە�͛�_�� �XI��P���d7iÀ���;���E��԰�t��؂���aJ�>Q�N�����P<(6O�rͨ�j�5;��Iz�_�C�����װ�n��|������FAc�!"�!���mdQ7�y���J�f��q��L�-�����s��:�Ц�O�����y�Z[@�\�пҥ�<"s~'���'j~=O���R�)�T�d�L����!e��fqzͬ�?��})������ϡ^v��GM�Y�G��Z���-��3����>Ah�g(��\�	%uR����Ut2:�<��̃�Ҍ�d�W���LKX]F�k����J��]W�X�5���\�������}���Ѳ���!�oN�.��!@oe�4����*y�X���;�n^������<:�U͖n��:Y�T��Rc�1�9o�5e�z����k2R@V[:�W_����I�~i�U�x�=Ҙ:�ѼDdII8���멾���x1���Ʃ�p��ޗP��!jC��BL�*�� `u�t�w�1h�*悆��	�n�c1&�a"������f�L_�SM��)$����7E��k%�HI7,��<LL�D�<�j0����C���ȩ1�7O]6ql���h��Ñ��ƕf�P�����
�A�f�<~��}���h����E_��{�x�&�7
1�w���n�2�'�?�q�4�}�0a~8���ݖn�QJ���Q���j2�����ŷ�����P�n���#�c_U�/�0eV�4W�����\Z4Hh����-ѱ_���MZ�=�N#�GA=�n�1N��L����ϫ �m���7=TA��4J����*��"�rtï=���4�WL�-�tp�c�>��K.\o}ccr��Q*S'�yѝ�׮��{�ڰ��A��J8y�uiL����>
��\e|�M�F[��M]����-�¦Ћ�MV�Oj�]!n���n��
��Ǯ�WW�I'�U��j��8��oG��~T�-Ϊ�lG�ćwG�i�&�Fs�����%�U���7Yk=Qͭ��Q��PK_�ϸ�o� �H���اr��)����M�������;$ߩ�;4��WY}��\�U�&���<�CY�B��^��op�uD.�f�������9�Š!'���[���&u����`E�v#��?� \����ѫ|nO��7������w���膲16�d��sBD��n��5v�����h�d������v���p����`��FD����1�Wp�x_�����9],R�S)��^�j�p�rU+�~x[���Y0	�@~�]�S��X�mp�X�n��)ܩ��'�]��d��!O�W�g��!��I����5�S^�
Eð�(n�6��ϔ&��6v�[�$=T��R��?��u�74�־�f�3���4�o��N��IS$rlu��)G���FY{(��@�md�F֋�%��	���(�ѣ�u��P�v��=O݃��aPoP?�&�J�N�P�U�-��H8qq��P�x+G'P*�����q�@���6[�t6+��{�l�U8�c�~[�p(����rNN�s6�����0n�z��R/���*2�I��1��Q�4�N�푢8B*�<��YӔ+l �^چ�]m�2�G�e�[�R�R�uա:�%��%��$	[w��Nӹ����6�y��*��q�r'1"U�X\a�9W�����;-�V��
��^rj���8g���T���g\�bn�+pe��T��V)0�6ND?X�b�u�˯0sg�#�C����3Zj��P�D���HRAW�Q/��ɾC�p(�V1VJ\N���iZ���T�`����8�	��4�4��d���<��U��;�����5f�V ��Y�_��5g���Ė�?��$ ΰ$��-N�؄ȳwX n}�ήε#w�O}��;b���T7��W((�*����]��o+��Fz�s�'#N�4k����\�-h��BN�8�D�3������*A̦���ي%�Ro'��*�}����~1[����qݦYͭF�Yݸ�ֵ��L��T5<Ed82-�xz;q�Ā�L�Ⱥ>/?�3�c�96F-�Ee�������:��lc
��g��fz��a����%��E��,��?"c�VQ�'�Mw ��'����¼�ǚp�@v�8�J������<=mg�*�h��G�z��Y� �R7�R�}����x��j{�F,�eJ"\�NjVƑ�_�uXٸj]�fz�f�&��k"L�3+�6m��;h�݂���5<{L��9f��DI{`5�p='p8qI1S6ew���-嬒���nα�P�ȸ=_�]�:9[@����r; ��@;�7��䜕LT͞Տx]72��VtIRu>/DB�(������7�̜Rұ��ϤMz����:�E®%|6��c5�4��{��JP:�KRz2�ć�:%Qav�+<�J7��[�j�����1`��d���Vo@�b���>�;��e�VX|���jl?�`�B�
�J.0����H�D��p��� ���f'R�;�Ћ�����X�E�l�Q����ŚV�����FI4\�@x>`{�}�O���<oe8���-�ǟK�5#��[?���Ae��\e.{��
]��^)����D��*Hit��\`(.�}�cfA�7)�V	pG�d߹DLO!H�==�W���a�{�4�0Q�ޫ���W>� i�,�3����e�cG���#A.��ҹ&9ʼ�G�\l�<3i�h�h~o��[�	9��~�b���]x�zkgT��H3���!a�;�}�S����������8vn�S/�E^�U��^�m,�B$#�L�s�1)�{�B%�˧��e��̕\lDE"�:�%����@-ׇ<�|C(����c[m��^^<�-"Q��l�f�s���}��b �H�����Q�/v��=ٝ��������w�`/s�j����<7T�-��М�
MO��ܴ�b��%����El���c�~�}���Nk�s��
��fD�T�䉶Y�a�zQ���/�;xb���[�ِ������1UB�΋��� u�qߤ�ވ��[�v!���>��]S1��@4Dt*۷��/��Ֆ�����y��w�#���7������L��jj����<�i�%!��Jw�'��UD���u��yc22�'v-:��n$ݯ�xH�͟/��v�'s�!�ȃS��_�eX�3�Ѐҕ�;G����h.Փi��k��d&�
����~�#�+��;U��n۔��+>T.����w���"�"�8���LH:Y_�k���"'^�i� �4����f�.is�Z�#?4�����cQJ�M.n/�&xj��
��sR]!��B�2E8��+qe�))z�fKua�:@A�����sk��u�e�k�ղt_\��F䇶_��� ��b��Y44TNmJ���M#�mф=)%H�j ���$��7T~h�BR߭:-�Ĝz� J�\%Sᚒ�c��g"X�q��O��c��r�?���������.�Ф��(rͻQV��iV���-W����Q�$�f&Q�ELd�JC�/�1�R,K�nQ!<����b�G�ٯt>~e��XV��x�RVL �fZ�w��	�Z^��t�[�0�^�S%L����`�?PuWT��_��7�_�r8(�iC
L f�BS�]�!t\��(�Ve��(gXI��rr�}fH�
��C����$+��e�	�v*g�P�㌿RQc��Za!���7�@�� A�B� D�w򭩷d�~�a*:��).���e��n��H��x3z�#(�d݅dy���:���g�m��E���5�{mڥ���4�@m�Ds�\L���|]o�5
�z����fV����?53����K:�Z�\���A]h)@��~H���v,^Ա�S��k.?z1ǳ���S�QjS����t��sF���'�e�Oj���gq!O{cJE}�1�{Lΰ�{�I����P���05��p����4Z���<Ke��M��'���UK{O��D@D���������y�G�q����6N�vb�fWjPz��-a�����r����Y�ėI������{�Δ�e8l]	�
�����M�\�}�K/Vkb>kq�p�aQ��~�|o���Y�S˵j�P5Lb�2¾���5�\�[j�-1K6ΔLfOB��
׫��xD���V.=��ɏ^'��,�#$P� =[����Ӓ�\�d�aU�ϼy��T��X �#g���PPze7D�?�"E���s�9�$B@V��&.7��}57����{9��q܄`�E�����(Q"�[98�,Ѫ���/e�a�"j�M|�q�ǆ⽆p�劸6ӧw-QH4���F��{�B�A/��z��F掐e�}@@؜���5���:K&�@��3�4���6UBQ⠲����v힃;���V(L�ld���Y����L�X!�w���⪫WQ��5h����^�&e��侻	i�FQ*p`�O�K�z�:LCV>��&b�]��ҏŬ˝D��ā8��չT����L4����Μ���r���cm�O{٦Y�=zk�-��y@|��Pй(�L��>�������kX�VNh������
���񊬤�%	X����
�y&S�r�����5$�(&+�C_�G�)�d��ZKM���鍎8�V0,��;���	�hZ~������A��ua�����U�V�'Q����1�����M2��t㵣0-x����IC{� q�Jx����k"T���m�y �18d��*�[&�R=Աс�1��<RL����n2���%n��L�ZY'��%�XXn����n���ܬ�Ӻ�X����~d ���2���i�`��Q�#_��P[�L�&�������	�e�� ��$���$3���4��R)�}q%D��^v�d.?��&�����SE�O�(��~�������M0�����}�O�!-�b�V�ȭ����#9�s��!��(Ĥ��ԑl؄�LWzp�L+����Zg�o,�bȾ�Zh(ܓ����s�U�%�I��1�_�tDq��L�Y�3���f�M_8��̒�3|�|�O4��^Ƒ9��ۂDM����'4OT��*O�V�����\��ơ�ktO��ge���U7�T0`���q�ȋ�����+˰�y��
�Zs�'�w̎Rdd�y�i���U&�J������5��z�@kÕ�b�K�����6�g�B��J��\���*��O=��."D���-e;U"��Vk����~ykj�_  q������] �����,u��g�    YZ