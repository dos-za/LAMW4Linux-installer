#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2850748747"
MD5="7fefaa4fa558f75be8a3e6d030010f7d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22800"
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
	echo Date of packaging: Fri Jun 18 15:40:56 -03 2021
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
�7zXZ  �ִF !   �X���X�] �}��1Dd]����P�t�D�r좌~�D�]:�1"A�I����B���Я:̱f��^0�J18���e[���~���C0���)扺���u���~����v�=�W�߉�(���ׁ�W��ݙ����7@�CyO",W���k8�����&]粿7��MY�+vzb2��̬ї5B05Jj��}�M"F�ӣ+�;�R͠���k��ޢ�IbZ� ���>��W��;�+a����I��`ˈ�Φ�^�U��*+�͘w�}���Gd�b������4�鼪�����d�W�z34nx+�1�]"ș��L񾎺�CX�ƛ��_�h2�;A�$ٕ��Wی @�\M7�CZ]�l8��_6x�M���P�$a�mBۢ�
�T�Xx�Ύ��;�(�͛�6҈�r��S�v^U���j&H�δx�����ӏp��$�e�lN����Нq¾���s�>�q�9X0��sFh�(��Ev��/J�D�2���7\{(��� cb�@967G�m��Hm0���f�UVN���?bR>���2��Y���d`�`��)��{��k�TR�"�*���fF�&��;`�����Lɿ�����q^���Rd��.+nl��+aJ��jM� m��O+���K�J�zu�x��k�-ϒ{w>�*4������LO����
�>�&�{7�Oq���V�{t���wK���P�/c|-"��]U�x�� a+I��+LA�j9�J�b4��<ht>\o�L&��M��@��[�.�&�?�f��Vŕ�@���k�ݵ=O`rR���S�1���z�N3"$�
g�[�+m��"?3rS!�R��,}D/=�F���i���eX�l��e7 ���k���9R/��S̳�fz�dN�4�2u�:�\K?�&�a�O��vB��j0�`k��Z�麂����"�q*d)y��I4�Ώ���pk��2e�_�hO���i*y&^�'[���v}-m<���gL�{�צN�$�-	�:.(�^�a;�(W-`�1�E��"}pq҂�_����-q{q�`j��s��o��g�G��(��b�m��3|	�)�+�!J�m*}`wa���U9��Iq�Q���1*�HWwj�f����ږ�݇�[/�A�Nŉ҅A�|��Q�	���֡mp(���x�H��{ G�ʹ���1(bb�]r�ֆ��3%o-���|k�u�1��%��WCR甝Ў�fz��Io����ya���'�"�^mi�nU]��mj��4���~]���UQ�i������Y+��،�R�K#`ok��ު�c�ȼv(�V9Aw���<��I��cL���k�g/��*bn�[=�XZ~�Z�X!�������(\r���W���禭)+w���'�<B=�IXKJH��e~j���G̉G��ѻ��+Yl��À������%�8�A
�\�L�`�v=d��`�=�0р�2u�F�N�-����B��P���?�SA��9�4�"����t�v����+a�Mk�'�K�C����;΄�h�i`�b�j6�K�g��vMU��ڲ 	���Fv�m��:��{l�����?�c5f�yG}	^^"m�� b#�+�9-�=���5�S�ՌG�W�@�[���y��ޖd1�ƺ�k;�y�����%�̘�4���v��D�@�����?F~lL�E�pN�n��ێ��R��jYa&=� ��U�z�TM�n�����O�aP��x"}K��5�L��u	i��h��{�}��SN�J	H��1 P�K�s���JWǎ7��`��4�U��@3�^���|�0�:i��?����T���C�0�e���Z���SL�КA^'��X@\�x�{�Im+(eE��ބ+���FIS#cTj���T��{p���F��q�K�iɘ߀ r��p����b{�Au;��TG�m�yU�s�\��6ʗ#��.� ﺾ�&����S�k��-�N��& 9���m>Y���O!�֏�m���)Ц�N���\")�X��{E��yFZ=܊�c�?�W�a{Wp$�2/Q������8xjw�,���е�ޏ^<���[�Zm,������f�0��P��B���S̳2��	��e�Z�j:�-6�A�]B =��W�5��3��	�<����0	�T��g¡�r�@*��zl�k0�$��ZJ��\�Alѹp�5̇deY�̠�d&����~B��Q�`/����j&��Q�K5MʓN)�k��3�h�S����t�!n8�\*ʉ�n�	��d�'9���Lc���^�;V��c�nX�<&��`�����YB�Eye^Q�:k��Z�Q�}=��K��Ah��J�������_W��R�N`�W���a�A,�*���і�B�,Y���� �|Y���w�b�\�i��À'K��j���g��%#*M�m�#5����4H�0��!3��k�}F�'o��L������\�m��05�)����`!@���H.C8���U1�"�����#e�3�OLӇ[j��B���Ӣ��9))�n|wS�E�a�Xj�?x"��\>� )���h�����'h��Χ�5O�TdS�8����'Q'`�gx]a���8 ��A5��p� x��u^E�q�9=��%��� ��빔,�J��8�n�Q��qf��صGm������r3�i�so4ذ�+�K́�!��s ;*���	0�jT5���&�8c�ƀ������I���끗�����Kk�� l�/�mU(�X���Z�F�.L�T[��!��J΅,%��4j@�;��pşj�pJ\'<"�4Sת=i������g�W�\9�/*#(i�b�k>�����g2D�c	�&�	���Ւ�u����X����������)���8n9 �Jp���s}q����r�1�g�Y�/I�ߕ�OT���X+v�ѫ�����&��tc������\)�Wc�ة�!yp:�ؚ�rԯ�!�{�x��>���:!I�U�u$:I\-+n��ݻp���x�R<�"�z����1���k�����8�i��c��IW��[�7���6���V�6d�G���[_�'9Nl��-��ݳ61n���@O�v�!�#�?aEq��#��εȷHD�7�����9�R}����1^�j�M`xXr'~��%0q(F���q6'�ސ�M�c��K�wR��h���"��S@�v����*������`����= C
�~��ӻ�>�(�(;�"_��F�	�`ZI��A�d�	���\ �E<m"�W=w�uЬc��r3�L���@|�H�������륹�ԒTD! X����`U~R[�K�gk��0μ�*O�z��ڗ����#��o(��oL��ָ]}����j#�2�1�~r@� $�$OFQ
�UO쎯�ʪ̭���L��H&MG{�P�+}=��Q'C̶6�x�Q�E�E�OWvRX���_�ϝ���{�?��7�q�Q僑U"�w�o�@K����wnx��KS�:��lXr1d�i�h�lOg����ʛ(;ގ�~����ñ�Z<����D�9R~Ưָ���ٌ�������Sixڲ��zah��^�1��{޾6E2��~���)�lP������5]�.�c�]*�3��f2[�WL�xw0\�j9E@Y��3�HŎ�`�sK_��������R�P���n�9J��*�a�ᠦp�������$�7L��?�]��EK�������lU9غ�F�G��.!2Mq	>k�0f��+�;\��4;�
�mk&F����l�燽&��m��z���7IW��Sq5~9R�)^��9�>�q��w���@�Rl ���Kn�q���ߝ{I���Yp�E��'��mk-R*���@6֎dx�q����!�ԙa�*��`��`B��%�T̋օlo��-�M/r<1T˺�?{�a���
1�����|
�F�����Z\��>(��M�	�@z|u(7.�`7�v�͊X�}��&
���ޥ��ڮ�����=�D"g�Eަ��>)�7�J��w�m���VD���N���0r�p���Z���S��w�y�!�5����P�2�G�a����Tf:z�\�,f��I�����|���(B��'ג��#���P�Ũ���@�
C{���q��)���j(�M���=�(A���lk���KJYU��9�_�YhT~[Ǝ�궘�*�Z(P�=|��2�����o_��5��t�\��̏���I�PZ�j������t�;��QAy���79�f�4��x����m��f*X1�o�/7n�u��)���: k��;�8�r�'���g*9*�&���/��i��ٻ_���8�CEɿ2��c�]қ?@)Pq3��y��C�T������~"]R��Hţ9��}_�ɋ#����7���ܨܙ�HtY���E%5�Kᛒ��3]�
#��_3��O��U�«��f�99��G~������J 5K'y�6�i���ޥF�98 �<����� ��jݚ�D�G��D��D�OV�L�8�j �`�맊���o����<�#�,�Yq��҆mLЌW�Ͼ3tdyg�e6f�[Y��|�~����Vr�v,�E���a�:��\�$�d�S��d+��/>m��Q?H
3���W��.v�尴RLy���K�Lf��RbR�S
y��P��Q<W\�l���E��	����?���7��Z��=���*I���!ë���C��X���X�nz��&87�T��(=��J�Oa����x|��eG�L��؏'L" P���^l�H��@�h�tG�?�PP!p���K�R�p��goiS�$K���
�ĩ�r��g�V������ABk-j�:�{p�N@��'v����&���eE\�x�B��/F�2�Qk!]���(Ot��dhGϯ3ߢ͈(���H���SuO���D=�E�6YBB\�G��1xq%_#A9��&�'&�M{�-��=(�Oꈡ�f8HBV����.W?�V��	5	��nl�Υ��38�е�Jx�?�q����]�YW�����4ON
|D��˴d$�K��8�o��د̞�5��$�U���]TW�g�|X�>�xJ���7#	_ta�I�Z�I���S��FL$�XV ���+o��Ś\�0@�٩Sѭ�r�U��j맟���N{ع�s�Y���� �|So]�|a���Y����B�N�������H-�o!��8���p�!^ �<L�ݞ6f;t hU���B�F�fl����OA�3��;[��#�{Obu{�"� �"�*�x�U���|<S��=��ֲI�A�0u�
g��c��B��&�[�����y��q��;���IFm�V��;'=j�L���5�����}o)��AO�I9Z���R�͑�(�"N:QL,�����c+務�j���0u�-0,�9�k���M�$ c����Sf�p7����.3�H��|��ӕJ���� �M-���s1rۦ��qM9uN�ew�F������?��8�F�V�(ͩ���XIEV�o��}c�'��
�����,I�5n�����.Iޫ���,�[ŃRù��3[�����e"淐iҦ}{G~{�!�L��}��Y��ى��֪�ȑ��N���"�Y�'����O_)�	�:�%�N�������B]K%W���1��M���\�q�n�QY��d��4�Nq��r�/Y���K���g� ���D�ZC���F�v��<����ct���.7��z؞�^���V\�V��>��HD��V{��ډ2e-v��þ�4�*��b�8���W2 �ܾ �/l)F��3zH{iԁ��A��zz�xh���c��	 Z��Sf#��B��E�T:�*oԩ����CG�~e#�'�%��n*��|�}�4q}D>�o�`5��3v��B�)GVUV��'��N9kV�BZ�1�XQ��X�N�9�7<����;��ܬ�	��#��12��td0H_6�u�ꄢ�m����A�.ltǶ��\��C������V8{a�o�#P�{�jKۉ$�]��~ʵfI��lr�_K�t
b�-� m������!�NZA�P|RLf|LO�J�Ř4V����g2S.�z9�pE���-�ZU>Ӎ���U.^�%]$d�l+�sy>� ��c�8��ۿK��[�N� �n6u�37���O�d�=�\��7;�f�V�\Xw�"����_�r�*h��۞j��Pv���f~��h��K�
�ʐ���Ry6�$��A�!���|`���%_o�|�CDx��P������v�8�YK�fQZ^3�2�'ѫ�U���a{Q�boU���"|��(����p��Gs�˛#rKr�$ǃ�[t��|�|?���$,t��i"����� K�
�la���ݗ��$��^S��fW�H�GQ�-��J{��L���6O��Ԯ4FiuW�W�eG��K�?M�]��
RC�O�'�1R���$�����U�0*v�!J�"f6E��l΅d���(m���_"��]���M1��l��`{(u�r�5����J���@� ��_~��f����W) J��Вx��Q9�ѥ򱘜��8>׆��Z�	�I�ed0���|#�d^!�+�]�t� `}�����R%f�]<�	�V:[P�SG�� �i�)z|�D>�z�}\E۬h�2�:`���=D�+�������}�_��e�l�;y4f��2�Ã׉!9�V�����#ɢ�N�gz	PN!2�I�Q��̍�%��q\sM����"H��5	�VP���)�C���q�F�*1��YjO����,���_ϥA�m#�X�Yֿ������hۏlfj�$������ą3Ђ>�Z��+)���O��'��?:,/�?�Xs�Q�w�^^�F"��k��T��TM~�@���"I' 2�%N�["iKdN^�P�Ixv�8X������,]��ިN�W4��������)�Nl�p�!��e�X�h	ږQW���+{�����1����,�[��R��7�0,�L�u:ZBjN|��b�7ؒ#Ҁ*<��}�.��0�v�p���z��X����}�}|���d�2,��y���)���U�F���2�v||�||b����k�$���HE� ��j��N��H���뱥�9~Dv@���8�P�+���z��}P�)���O`Z��Цw��t�}1�_��d�s�`���2\����M<��0��&4|����2LY���6�h���pb�=�^	�Z�A��q=���V±ğ� ����5dlҲ��zR
5:�H��)���졟�ˑ�I�ЈJ�A�KK����Ɩ�e�Of��[�vbA6��4�Le�X\i"�ī�}�Wx�B�7	wǫ���\e��3��%Yx�7��H�R�7��s̻��q��`櫦~��-��ʈ�I���\����qr��@���`�yT��B��w���~!�A97qFr&����Oχ`�u��M�,J�a��X�}
�b�N)��	����K������Zr�rD�S�q��kF�����TE;��>;b2��\����h���7��Y�#ڕ�}0<� q����nձ�'hQҩj���b�ĨKJ<e�b�\������p�oz���54L���,r�0��{|�.{����UO�����h@��w��	��	w �̈́+� ܴ�5m��T)Fg�b�l��`d\��fC�-+F��L�khTЪ�	f0k�����<�lצ��]���?R�+��ak+J�f�t���'�v����]N	7lL�~�nrЄe��e��q[�ˊ:UZ��n��ѹ���B�fU� &�|#�D��Kw�$�z�����k�5o�ܗ�EPM=�}�О�R#� �������|�Bj�2|��eJ����`��h.��®�������U�TlK�ܫBa%�(L�W}�(��B�|�,v�.�h�]�r AH7���ih"��R�c=_�]*5�ic��m�OΟ ���?"�Y���vtĐ�ǟH=��R���8���l�7͡ΐ���V���Qii
�Ue�]/�h�֝Z�{�Hb$��
3�a1"��=���b�*ܣ�R���SڂY��T>�s]��1~փ4��X�t��\Y
,�h�y��ܼ;�����p%$�ԞP	�c�5���U���oJ��@���i�����.�M���N�٦*s E�$Pp̖�IHnRVt��0�d�~M�9����O(e�J}U̎Fý�E"�������z���{����$*lt���4��&w��U�`��8���;��
��LT��Z�!�?�jg� ?	���.5�.q��~�`�����w{k9��?9��*�؋�F��׉��{�`��� Yml�/�SA�$,� �� �H�س�*�K����e�A�5�pN�ڝ�G��
��,���'�Ⳕ�M�l�s.�8�~�d�1{2��Sd�B�~9"���In�������Wi4梁]��El �yc�3 �3T��=9.c�YPO�gL����Xb�L��1�N��7n�TC���*C焨�#�'��[!g���Y���1fYH�\kMWyH�P�g���� �����@,5I,=�#w�1���^W3I	�c
���_q�p��~t�;�����?�\2+�w/�=�[i�@��'�4'��S�fbCUYj�>���3�D�c#�w=��V(c��w8�q^Z��	�	��Y��-�DB!�5��2�K�.͟���*�
��Fa>�m���E�V2�42�ld�Б"�ɠ�1�K��!��0D�J�m1X�ZX�B���i8J�jRerI��b��~jD�b�����t���HF=����4,R�#�4`�QMa�#���P(���@�M~4�O����j>)"xpہxGR�E���=�3���w%u-�X��6�.T$B������9i��� � s<���+:�׌��G$�2,��L��S{��2�g*1~֕�֎����ND�D�T%ɬx��3$
I&��JS��n��`�\��I�
!�����Ʌ�� �=LC�A$VI�m�h`#Tz����(�����Ik����WBpq��R�M����5%ִ���}�	���G%z��.���)�S˯g6
�y�ԃ#L��\��E���:�4���f~Ȉ+����lSDҊ�\���ٿ6~v��)���V�+�Q�����������IR�ncnhO���w4�FO�'�O@��+4�R�<	�35�x�(j�=��j��	���G-�&&��pAw�▙��Э⊖A6Ǝ-�85MmB�u�����K�埝�{�B�W���ܮ���M��^RL�$��Go'��<&*�RP�Fƪ|M�m{��8s7�쀹��F�v#y��>��L��<��Ժ�GH� cegA䴎�@ R[�|!Z]C���J�0nc��d,��z��ĳx1k���������(�9Ve�s���ͣ�
����@��ðe����;�o"$�r5�1����!�~l9%B}gi��>a�C��-��ޙ��v��j�P��z/��%�$ۛ%�Nު���jaW���y�u� �Aӭ�s� �����9�V��Q��Y�K��_Z~�)�佼?�U���5R��9�l����^Y�v�Y	ާOׄ�e�|��c����ZD=��{�x�j�X�N���f��`�+���ì�D��
T^
mi��D��!��ə
4�G��6��4���^�\�u�L�Y]��c�6����j=5l�/��
��N�dc�A�5�$`��h�b���픋į (�8��:c~!D�]Ԍ�-�@9�I.�(��h�!�_QX�Ak�w�0��tL��%�;~2����$�D
�;QNi����:���K�a��v1`�>H������)����h�f����Čp��eb���, ]��t�VL������g���� Qq7�M���M'�/ۨ!�3�FzWw���&��[�"�8ơʺ+xQ_'b&�?�v�e9���|q���g{nc�=f�^���4C@Ⰽ6��k�"a{���e��p�D�Wg@�9����Yۯ�Y=�E����1��h-�8u�e*��F|n�˹�+�Y�YJ�'��(��k*��_���&�-��N�UV���!�,�+I��_y�q��'�o�z��7�Fq��ؔ�_�Zƈͪ�u��$-�Y�Lg_�<���9��/�&��Bi�gQ��ۊ+�����d6�����Y��ZǳG���޾�j�$i�Q$�>����L��#��@�1�k=b�rл7�Oʤ��&�7�B�[�)�%l��t��]��}�}�`��}�X���\f���"inz�l����Ïe�aV�9O���Gu���7J/�;�1L�ڒ!(�P�m��0�`�՝1��:���Q��2�@}�⑧Kbli5C��YJ��,�#b�ȑH�����Ó���v"�k,!��3��k4:��}-�U�(Z(��Pɶ�$��;��s�j��{��2���Uw�=��,ܱ
U �3��y*��]
j����I��Fi� �pz��Q�����COV� �������c���|91~���w~�\%�B�)��y7����t�s� 5�!��T���wƕ�q�#b��"�\/�33�n�MZ�﹌�&5�
Bl�[�J���Rre��A�ҴDd��)�<�g�����[9:Z9K���w��_��+!KRS���T��_?}�ܡ��vhV��U	RۛΡ�Z�	s�g�g
�4V���CfK:X3��x��>J�^ı���\=Ly�ڻ�L�P�yS��7��)e�5M�F:j^cS[���,|cu������J,4��Pڈ7��Qi�&&�ȋt�-�@�ƛ�6�2�Y��V�?���N}��I�v��}�D��p�M>���
����}�c�����"�3��gh��8P3:�8,��2�����{�ڲ`'Dg����������dq��lk�P������f�	�U�Jq�y�W��M�r���xQ�?����ݐ�ɍ(���Y�k�4Vv�ă���_�	J7늘YY����N{%��
F���tpnj8�-GYe�JF���8��$ғR23����Z��5<��?��y|}8Ĉ@{�3�ȅ{�7y��y���a�)��ߖ舳%l��v���@��N7̒�.�=�M��\�҆�R%i���W�y��NE^�`O����������/��O���1T�J���V�Ր8�y� B���P���['	K�@I� ��48��-?)�9�2��)��rّ?|��E�(u}6���h��p���hs)]���'�A_��e��'�X��S��?����P��E�3wP��-�y��28]F�U
�͸h9k�m�[�[�i4����z���egVQ!GM�sW�b{ܺ���/����\]�kSV� �yN�z3GQ�֦����x�7��Z%~:�:$z!�r+�;�D���ul�9�=}�+�/$Qtт���y��as�A��M�V�˭풄s����r��,�pԇ���}�S�÷��~���݇X�_@1Ӻ:a�u�B��S�h� 1ę5ҙy	�Cdj���>PtMJ �i�c��C���?����k��mɖ#�y���ڳ�dD�=zT�Z�=X�ޔo�"��g,�+���A^6���/��'��%�e�ҝ>��>v�,�z������3%:�W�>��q����̀��#_��5�_M�2E��(���gx��_�M �`���CE�H�_<�i1�=`�Y5��7}oΨ%�&�:����{ˌ%��ds.�&�uL�GiD�ҭ6%�<������v�K0�<��o�;�񫾦����r��@�ܹ+o�(�_`�J]���Q���<��f9c7n��	��f���V_�y��c�ܚfU�]؁3pV
�M�_�˂�q5Z���B��S| +<�L�����@���~uw�Ox�׎v������qo^���	�/�o����q��UcI�2�I�4M͌���a����n?��g��ی��i��s�3=E,	�� d]e$���ɤ�@R�Dw$���h��Ϸ�V�aQ���W�O7��=����x���W���5��8�eC��0�8�}m�o�&���c��<[#�Vi���7��2�8ܖ�l� J�%	/�m�����n�j��?;���\�x��u̽����~��_8n�K���h*�OWZ��A ��$Z#h���􃜶� p���2 0�� w�G��9��|����4`D�ůd�w��D!�5����4p��)� ��K@rQ
�n�MQo	��D����^� m	� ���s�&�p�������e�K������0$N[�]Y��:��h�߂���&�������K���rw&�-��U1��&�U�%�B���V�|���k�!	@J[!0�#P�2��� �޻8U��?0)-�2&���H�Q�l��� "����ŭ�\�!�jH;�f����{��I�3M��l���)�F��O�jCHC���-D�0C����;�a{�P;��~I�I;�7{�\hsr$@���E��������X��f�'�����cU��q7��}��t�%F%�l�>�1\O¤4��+�d�M���H�uJ�87i�G�L�z��yj��XJ�Q8�w����I�/�G��)E?u����&9{T��W���Vt��,�\�ٲl�^pٞ7yM�?�6��}�]�D.%���b��΃��׳R�����x¥ ��H5F�4E7ir� �'�b`%���GR����Է�_�R��,��Sқ���������z�X ?�)dJG�Q�Ӡ+�|�m�_��C��W�ii���y�U�%Q�t�%tO�)2�B�]�ñ'�_����xf�\+�b��~�����1�*���s�䑖���U�-0�U���,$cN��ޑ촊�6�D�.#�t� q�f KV�Z9D�
����dz�]۳��`�n������>��%�� �N8uX�O�!J:&e��Ѯ//��ٞy��*��}C�; ()p�[!W;AI�2%T$
x��i��l^�9N��\c��~p�
]ɥ�oyK0���8.�|�F�&j��u=�����m�-!4�n���������nZں�Br��_^v�MT1�?Q%��ei��W��v�#@���ȝj��h32?甁�O�A�tk�I���U�����D�zy$�����C)$S�r�?��{l�<��\�7��lC�o�3��+xU9�b���j�.>��	 8ʓ(���g�K��q�4�Z-���n��Śh�(5�w<B?6�Z����G�Zo���4�.0܏:�V�P�yY}��-�Q>�;:0�/���TH��߉t�{`ď�Lt�!��#���_�W4����kN�n�(�̃��� h�(��,�mf�wN�g��֨�7T	�������}'��cY�m���/�0@��}�&���<�n��{K~�\0jT������>�f�V�Zȋ�0�BŁ3v�M%����	{��Sx!����^��A���ꇦ�`��๎*��� �zϯKa/��X�N��� i�V��;�*9?@-��u�G,�6.���Y�d8-�c0�c6����3oa�ؔ�k���{a!v0h��LR[]�D�H'���_�1+���o�	0լ`��m��O|@�)�n�9����n�y�|�:��n*A�ܝ�2Qֳ&�3�6"Xá�'�%�c��2?�醟�t�=��jod�/?�+˱���E��G�Q9�MI��u!��\�o|2ގb�;�������a~�����љ��-M�"�;�F3Sʵ��y˛�0�� ��l|u��z
��{��Ͽ��� K?E��T�)��6���%�hH�(��"�Li��`���M��du��;2��n�߾�e.;�v������1�����YDo�2V|�/���F�oCR)N	0U��¥�ojo2�0�w���{ο�J��w=)�iS��zk�+"�r.k����y��T6^:��kJ�Q�C9�ḌUFCE�f#$?=����,�XWJx>��fl�WMF:zMJ�7��AJ{�!).�P��q4�KA�H+�y�Yե��Uf7 [��`�nhK�J��("K�嵸؞*z������4;��)`w���A�J��[@��ş=�O�%��Dn�Uk��� ̫�y�z̀J;��ސuϠ�ch���=�:XVV�A\VPrRT#��Pdzab"�Г?�����ے���,5��,��|T,���H��|��dt7�d�K��L�d�H��5C2 k-�,��"���.�
��	� f�:G��U��A����S-u��U�ٸA��I!<��P$�x@������&8�f<d!���P0/��(�I�MK�J��̒�
@Jܴv��64��	АrҫSB�9V�ir�S���5�*�B"�#���%�Z ����ו�o��L��#:���'��&Wl�t*�%о����ȅ�B{3�������� ����$L�"�!"��Z�ܿUDT�/:��;��-��_ ?�v��ƭY���}}ӡ"C1߱J����54=��������a���&2�8���I��C�;*��WAf�<��]�������euZu�,_|6��3�b����Hs�`�I����j�y�I�G)�F &3��[�S�k�2��<e_����qm'�Կ���/
�#�O��1S� %|�*	�:6���-�G��Y����2�p~��`<�]���0���ں0�M�0y�^��[^B�oX����~̃q�oOK��M.CENE&G}9;4��m�{o>t�����.p���M�����Kݨ\�<�	���n�xO��Si��F���];�j�#�G���r?qLG�6��'ʟ(x��ǃW3�y	)X��Џ���H����J��AW��Tu�E��#�l�=�ƀ�*>'��ã�0؏�0��_0�o����:,V�i�;J�V��Eg[�� ��J�l+7c��[�Wnp��>�pi�{�ORH,̿�����vM�4<i�;�;C]$��;ȿ���=�k����`�1|�l������	���y��sW�~0q�S�=��a�ј���M�9`�ͰsY�k9Ĉ�
���}�cW̬9[V���s���ʚ�k,\�ŴqF�=�`�n)EЌ.7�x�e�@���Ӧ�Jk�j���n8zvEB�(����I@�A60!Z8U�����wJ��&��bAx�)76��^����#Di��,S\=2��1�f����D� �J�S:Dm3K~ֿ  z�c��l�K�[(��s��Auﯳ����/�*$��i�u[���[�<{|m+���	��N�������8VD��9[���M�� 5�kK c�AS��ݺ�|Sf�%x��d��%�4$M&�dGx ����o�K�B�\ɏ�V�:� j��U�?Ca��x�<�t~M l�!�1�XA��_���{+eM{O%c�����k�]��>N�#��[��2��9d��"gZ@��ⴈ @xH�1�mM����GY�Þ�?��wS�������8�Q��bV��t��z7E|�ο� EpG?G����Ԣ]���Ty�f��H�>Po�����o��d[Z`G:�(羉�.'��X��X�&�q�*3�� ��ҊTP����+6���B�)�,���,�EG%0yy��k������7��4^5̜���[h�a�!����s����U��D �f�S���y>z�=r{^g�;�a�d��ϩ�:	�s&�Ʀj��@��ώ�?��<���f{1 �Y�['JC|?P�a'���V�V��+Qo/�E�R���﹅�L��P��}R-��k�7��K�]����LX��1�@˒�xV��`�T������S��������-:.A3v�,�UP������T�����ԙT��^�5w�����u�JY�����(�a�c���,a�0�2��ߒ,���q��d\��l�ؿ����Hg%,�v|�a�A����4��Ǭkk��Y[�
��5�x�AK�hO���4�)y��2Dc%�q�
�ʲ����O�x�Kl�����CR�޵Oo���?6.�@2ܿ��I�zۭ9DE�%$	I���4����ӰJ|B�%��p�I}C5ۮ.��C�0��
u��O\:E�9�#H�Qi.�+&\�iV��Ҫ�;�'�VʳhH��ݫa�@��)��j�i�m	~C�u�GR����F�/�Jb`|��e����p���`���$vx`X����O]MV).��)ӡ�69	np�����腳���^<=��dJc ؚ@��l5\�X�*�ƨ�NxH����U�q�	A�@_����S't(��ff[�&vW���=Ɩ��m�ȉ���2������G=%�{��|�����"N��Y��oB^���
 )B��CF�kV��P��CH�AP�<s�p�$���1'Wt���'���Q4�l�W��rb����l0�����ryfd��F�l���S�u���ϑX񩬪ԣ�1�����zh.����"�ʥ�:#e��7�e�T��A6����Po (�v�����Dj�e�_��1�|Oz�I0)H��Km��{L�c��jլ��-dGA�L� �L.��DxB�*��R���u9�3�������K<o>����O���«c�AWL�l�0�ߦ�����Mpn}|ޱ�pn��c\�1CP���2�9K��9fD�'*�5O��?CQީ�m$�����'���Xr'W��":���q���t���c]��9��5���u��k.f��j�)�x��8⊐;�_g�S���9��" Y�~^P�KM˞\j��o\L1A�@����q�^���U\��|�k�4��in��:�n�P�ߓAĔ���JMI���=��Z�^���w��S����c�c�~��r����x�G��^g�y� oݙm���W��3kg�/�� �HeDg��P��d�L�C�z?��Vh���S��m_��+�@fX���R�j
�X8,���E�o[��/�x'$r��7��ȂW�Jgc� ��fђ-�t�, !���Y�f<΍�d�����w>�{�R�������[�Vy[��A�Ct����]��SE�P����P������T�>Q�� A��a\`nq�d3���}_u7B	u�Ҹ��?�R�GJù��'[*6���w��t���J�Q�y������C`�D�h�P���VE�R��V�d�ɔ���Ϛ�b�����{p����pswM�K����	=[��:-��u������d��[�@<��ZzU��vh���ٟ��� "����*�k[Q�7�M���:m�Z�[�f���r�k9��:�44�՗�v�+�K�/��;�P��V9�P$�r�D9�P:Ӝ�Ը�mK���9�r���QU{���d��%�!�3��<;K����(�yA���* _�|
��X=�
G�t��1H�̅'u�9��ik�a�1$�^���_ctn>�+��<c��BW��^R���#�cstW���G�}����/�.�[�L��X��q_��K^8d��Q����V'9�w-=�VV�tF���έ[����l<��w=}�,�۸ԙ����G�M�Q�0��@L�L��i�;�N;d���T��~��)�3���_),�"��g{�Q�Z!����~m��_#>���q�f���I����Uŗɞ�(�[(�N�O*?[7Ma��a�cˋ��rL�X�xvŬ��kA�,\�#͒9�E�Yx�w`���O�|R�l��i<��ʆǓ�|�C�¨@�͎��ʂ]�/b�.]�/�fi�MU��u[�3��4�2dђ�U�ߨ:n� �Z��5C0�쨅����֌���������(��A��ɣ�ե7g_�M�u8n�,DAI��,�|ኤ(��^�������#�&���(t��r�w��F�iKCgU�l��8#��I�Z ]	����	X5.¤�UT�oZ&�\k�Aڇ��ʟ�����;#���\79�j��|�p{N��:;�_g\��$Q�<ceԭ`D��/�b�� f<@��m|�)����%��%��WSv]XЖ�&+Cu�Vbn�)f.ýX�U� 4�x��ǎ\gD���g�<�x���X�3Q.GK��D�N��h��?�M���GB^Z�>�|U\^�	��v|���dqE}����8kp�6\��^���19>¸J��6oن�
ųM%+�Z�c��=�l㓱��Fg��zȤ
�C�Ss<;��m�$2F9���N��4�l��>�Z����c W��3i~��hL��u�)���֍!���G�^ä��w�f�71h�?��"�px������.¨��VLPJ�H%[�6�$��O���	*��.���Lwkd�c/&K��HmN������[Sk
�j�Zf���}.j�Piz�S�Б�8cc��{�4Xa�":1�yI�7X�e�,�ί�i��7U>Cq��+M�;k�i�=7
�U}3�^Ӝu�o���L�A'/uDT�� `�^.:%c./�;� |v�E�n �5���-Hm���D�M����kc�����]��~���0�hՐ�\q�IoZt�VI�7=2����|?͔������X�ܿ��w��ˢ�B��}.��V�o��'��u�Q� �Ƨr�2�˥�������p�D�b|R rE�.$�z�ߐK�z7�G-�ק�$Z|4�2�E�Κ$�¡D�#L��Ŀ4F��β�k#Jk�a.{�:���j�N��@�EL�]����X�Z�{P�֘�;J�?u�!_)�j�Yb����W��z�����19Spq�,�cuA�	��	�6[�����q� l۱|��y�[������?�߂{p |����-��+�yM�i'Sۚq<�&la��Vo�̻��^��QH^���r8���zfb�)�ђh�~ ��p���x�VUT�J~�%�磔ѷ'_��|��GM��"i`t�{�s�O�'����t��M1�Ş>~g��e���s��P���q����/�̅$�I����L��!�d�v���$�+��8?DOj��_��gJ�������*��n�{&e���0����Y��>��*�5�����ʼ�2/fWJ�hV`�/��=Q8��5b���]�6}ϣh�:��Ai�x�q��5݂.&4$Pw�!�;��
�E�c�Du��l�t$��R�[I�8�nmH��"`��Nk?T�`L��;3fӼ��1�V6��U���ܪ��u�Uv!�^]�2���+G�U�,E����0�s��<VQY����铩��5�ق��s�����k��|8�6Lk/��ۘ�"f��3���ޝ��r%�r"�u"(ޢ��	�T�.��He��.l��	@��<p����c��X�<K[���pq{y2*~NO�)�'����īw^��p�Y���{bp��[go�2��\�ڔ�1l�MMDH��gf��c��2��<�JA��"~�z��/�����z����^�Myvu�M�^��54���gQ�X��r���׈�"BA=�2݊hõ�{�6O�d#f'7>����p��Ф�[��t�����.^<�Z��MSO��]fq¦��!T���5r5�y��C_B6��c��%ksЬ�aQ#�0h�.������ �:�j�L	U�X�j�C�򿦗^�_����GU噧�Y�����bU&-��D�m�j��?�T7��ʵ�$��y��Y)�R��6��Ԫ���?�s���bjK:>�}�DL���]��q��,Y�2�B�|X�+~ze-�<��޹��^����U�+g|�+[I*9��� �h�`<���*���S<���)���{J�L�ٹ�"~��:�L�_sz�6ķ/�H|�KO�Lq2�'���גˆG�h��}����JV2��(�P{/
f�IґɁ�RR�[��u���f1�(���H��l0�T��2n��?2�]Y��~��T<<&��E�n�� *^���Fm|m���s/���Lb�����c�S#�9������O��y/�E�����ǎr����N��O���׹G+�n��1�.ǁ~%0�$K�*��@��� �>�1��Ӱ᠐� �#�a @z��%mE�v���f(���;���?[e�1�1�k8���ꪈ��3G,H0m^v���J��4�D���Zz��$�O]#B)27�Gٍ!W�[�$��� w����䌐����(�����"��TR��q^SδȰƆr��"���[N]S�ºZ���.0?Tt�n�hIm�y�ܨ.�?��z׬��Y�C4��S+�DͿC#F�K�'$7�"�����(�n��<X�i�km/dKL���h��%u�L԰�A&>ŗ7����q�n��R_�X�f�ܪCp�J�����>e�PnС��<�]g�(��eX�%�&U�}�8nN�-���՟�n�\-Õe����C8,��*�{)ui�vrl��6w�V�s�ԻE�׮�i�X�Z���p����uL�������{{�kJq3Q��n2N���\�K z��o��gN ��j�_C�� 7�)���T�䫌"�`�yݧC#|?�r%�=�A�XM��-���VAa����R����4�|������^j������촥j�w���)����ݏ�_� ��,L�{>�O�{�]�r��.V\�H�����jZY�7;���#V�xP�8��I�׌9�狫�����<�yD���d��܈U��A�Eˬ�uh�tITJS��!Q�,@��ύ�"�<�ٶ ��TDq<�$���^I�$*������}O��],����A���tr�m��L���%�Kp�a�����X��]�*+3k�P�7s^�^l�	���0^@��9�j�h�41���Wd�ضX�s���
΀����7~� ��ֿt�v�yJ�m;�ok�������?҅�Q�b�@��+�e����dX�Ц%s��h�h�jJi	��������h$
픯*=X��d4j��u��z=�R+DU���`{�RLTEf�"Y=��
��h	��c�b�4Sh	,�$���&$>�Vp"��o=�{eᑼ�������=6�2�c��e��&��*�������oq����6�m���7��[�� ��3h l*tD�n��{�+ YP�����Q��<E����s��5Ԭ�N[��'�mg��t��K�{M$�P��e�g�c�0\�F���-f�f2�k�e�
D�	�;CQƝ�Yl��@|#O5��۠��n)�!CC0G�|x b�S�c������c !{����yV�b3����,�D�_�*ZŊ�h� ]���"�T���\G�U��_���y��{��/Dq�^Ji�۹�����-n��?DVj�=�)n��FHQncg�>�;��l���R��E�w�ғN �F�5j��~L�X�$��E��H�S��L��՜�<���V��1}���5���Z�ڭJ"�G�AJz�.�r$�/9�m۠�2��yL^��[o���e��n"��pX�����)���N$0P���>�{�,x��.���u��5������o�eG����r������y�����pQ�㵊��]�I3��Ğ�T�
�I&��aQ��09��^�VL�|O�2�	�ܦ\��ڍ�"��s7
:�\��Ǌ_ɻ,sG�f�|�����H�G(5��������a84֏?4���F���I3{nUsn�KЇF�3�D��@�jF�6�nQ��	Y����O�E�G�\���TL�%�w۵��Y�,g`���_��\�7�z�,����<�^9c�:@g���p��\��mc ���¢6�rC�K2o��v����9f�.)Uݻ�d֮r5I|R�Tn�����Y��/@�9��Aq:��'�#��g�r`dj�u8"���vAY�U����;M�d�w)1U(�ǰ�ۚ=Y^,�HAƠZe|("ş�_j,Ș�mSu�^��C=)��6����M�4�b�Ųp6^*��q���5�0��\���\�8�j�>%����d�	�j�E�%7Qi�JLb� �q��:A�9���=�^y�V�ߧ����/Ѩ��N3o�#%�)�k���)k��� ;�'b��^S�n�s����T��P
���[U ��H��/\�'"��=X�&;�A� ��#�8u<@� pk��wR��@	����u���bS?�N�@��k�M̐2���Y������ڮt z�k�U �GD#�D�=�s��d�撅�j����H�T�9���ػ��Oؐ��f�Q:��`�y�q������w\m����d�  �y�[��^pn{[��8��$�Љ�v���6{�;�W��s=P~7��S.�   )�]��v ���U&'6��g�    YZ