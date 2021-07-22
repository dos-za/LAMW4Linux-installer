#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1845376220"
MD5="c8ddc927c0e0aeec5976c1aedd341bc6"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22716"
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
	echo Date of packaging: Thu Jul 22 18:25:18 -03 2021
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
�7zXZ  �ִF !   �X���X{] �}��1Dd]����P�t�FЯ[T^��-6�۪��gGKsa��A�U���F�8
���?p�Ơ2Cl+#�#���6F +�+׻j�h��D�or���L�ϐe����'��I�;�m�g��G���^rx$�weꂦ,��Y9�}e������_�2�څ�Lk��}�:�OVe���}�}�\}���X$�q-����pr�~:��?����؀{]u�q2��"���	,1�IP:�FyP��k"�2_�׽�:��N��|pM�a�����zM5��D�.W�}���ه׷������ef���m46#����Ú �>˂����d�1������������C�F��;aMd �RK���N�or%��K��+��<�_��[��#�'O�BXZ/=�U�<w����΢�2ZW��^�ǔV�|B�gؓ���'�{u��{��)�[宀��ƙ�� a7�MHYE<	� ��/ۺqO���U]=_%��IXn7k�~z����� �ZE��91cƚ.���F`a�2�X�9y9vM���?@aƟo?0��Ǵ ��=7?����h��N'�L6=ޜH���ȼw�`�|d6W#��Z���(���A�o�#��0~g4 N"MbL8���Iq-3���bU�ν�+Z�t=AZ�s����<��+\t����iGc-^ϰ�vC쓟Z�'��Z� �A�t�׀�lq�m���AÛH�Z� �F��o�U�:�ONif��hX[��O�s2JR-�E�%{����E4�~"B���I!�g2��Nߠ��e�D�K����5y5I.�)|M�g�>f�X�C�?�Ds�5��\g�n ������4�ے�����82��[�J\�mX�r�op��V�{�^7L�ۋ!\�-���r�)�!��p��@OG���Q
���֍||ą��-W�S��W��U�C���&6QO�10ղ aQ���x�"�	��&hvT�Dd��Eum�Z�a�=��·Ƞ���c�u8A%
��)�ui����l��k�+�O���5
S.`���(��YN}��LO�?����h�=B&��^��$��ϡ�L�6���o��J�3f�ӻ��_i�d�趆l��[���e?]	Vi���b|�pҴ�Ч�ej��x	|���X9��8��9g�:�F�����i�'�.*/"�-�ׄJ���#�w�c�{K��7�`C��ǆsK��PFF
��2�+�=p4S�W�b= ��%�m�
���[PqS��Y��n����������#2���Y��N���ܕX�e'�^1�0G�]l m��	].���eH+��M�&"����+�?�%ٽm�]�G(-�WP!#u4�J���A����?��5B��;FI��oCby^��0��R��9���5m��+eͮ�#Q�{GP�ƫ7_GN�/(������
V���qhy���SԜdH�CzX?3���XI��;#Bg[�f������وu_�i�|o��f/�J��Btw5ioP&�Ha�����/y|!�WT~�i*�0!��כ�9��_4^���&��%�.�c�׋��l��-3���z��Q�� Y�ge�p��)�����s��k��V�D]�z�1�f'�JI�����3�QT�L��Luԋp�_�Gm!�oVm������<��Ɩ���Q�q�8�mw$5W�	i@N¯����6���_u�~<ׅ�l�m����O�& (�8�! �T��4F��z�c%v�.����T��pϋ ֈ�s�ß-����?��2�f���k!�q�,�ӎ�G�_�a�'f�9�s��P��y�A�ud�k	�����i�����_3SW>mo�s����i�d:����g�Ͱ���g�F-���SS͜����BnV����c�����0����o��r=�7Ǟ ��J����<�6���f�-�� �ć'��3��ټ�{�Ǜ�0���fx}>��4��� ��� -��e`)�T$%�atP�Qì;J��$���2,e�ZW��u,,L��s�Z�Q��Z�C���*��[��5�h�5]~�E<g�ED�b��yJn�β����~�6y;^����I�L� �m0�������w�_t�\Y��h���0�ecN���֜��'���Q�������"\�J���+#�Q:ʲ��ls�
]I(�Y���d6��l4��yǙ�_�% �J���C��t@G�`XR^y�,&
;�<�BS�@eC�*g+�����(��X�PO�����p���D����7Jh�.��]���,�SY�/����G���׋<�8��q@a�^>�Z�p��)�$��c-���a�X ny����e��D%�C ����!N5�Y�yHm
L՟>"�d-����q���ʍ�ч�����6�NaeE�c��!E���A��A/J��O]����V��(�er��K����$*DXQ׍`����S*������b��\>�Y� .�P��V���RA��&�+�ʱ��6W'��{�/C����eZ�:̷O��B��|���hZr��?�fhm<j��l��G�>!Dt�i�F|Rh���h�0ͼ)�
ʙ+BX�Y��W�jC�y�ANs�wA�b�J����U��	Qk.j:���5��"1c�$8��ňٸ�����v�gI*Gܔd�"XI(�ŅG�AE��ͭt/���>����$f�P�j��ӿ�6�o�@��c�9u�i��G���Kd�ʌ5����4���	�u9�g� �I����U���m����km�גP��F���S��L�Z�ӝXA�̦�Oy��iL��1��e��(�"F�ף��+k���y?v�F�1�:Qt�2�9G|�&�]��A^kCЭ �I��ǵGP��Au�l';�����R$�-u"�����'��8���>l#l�e�~Zr�����g�YA�Z@ �Fj��ۧ��BWx���hV�Q����#i:G��xr�vKػ�B&�������s�ɬ���r��#Ś�ڳt6���U�"�ɉg�%{3L�iި?a��J�w�X�;�������X��W�m-���cb��' :�rPճQ���_8�s�ʖ���Uć�P �\*T~(����W���b^�����H�h}�:^I:���� ĿwE�ņ_�r$�cc5�܇�L�ܮq:%?�Z2������V�Oa��vS���?��a�&S�`��6<J����VTQ��m5�����t�6̓n8��q(*��z"�)���h��m�W[�]�d|�ZQ�"���&e;Ha^x���`�#ձ&z'ʴO22g�Yd P�;�$J�;���'�?N�Ri��e0�����;��q_��I*�3��|��9
#�C��~�Q�]w�'�@0������1��IV2�E��XY]�k�%{N[2��Cum=w^�%�rm��~��~� 9W���`�atWr͜i�{a��%�N�jLk�႑xwCs�RD�x� y�O`_�H���}��ѽ(�b@O�e^�d�)�e�T'E��ң�g��IK*vU�a�T�l����^L5�f�뭦��W��{��ՎX�����$�a�;k:��SѶ�e.E�@W��� ��:+Zká�呖Z-+�����A�\�G��vV��~axh��$�2���CM�=7a����=�qI�0��o�]��,�ic�r���gPEx�F��ZB\&��M���c̍���QJj�>�<�5�Α�h2q{��GoL2�!~�u�2l3H����'��������rRJ�i?�{
���ojhN+\��#^�2k���搁/�ߕ�<�dZ����b����m�!}��nQC�FC�G$����w�S�iJ��5�3�䂋�}-���6Ƀ^߽v�G̏%=9�b�)�ԥ���k ��]�~�����H"� @ �w�8n��qզ�CS:;X�y� �%������y�#C��mBBBj�ȳaY�s��1E����X�e��:�TO�/x�� 3����D)_$�)$X�o�������!A�G��|��3v��^�c;���ʌ���
�jx�V��0eQ�Y"����rND=^����|�{�~)n��ͬ���2�=��b�������GUUK�;�Pw>KF�a^AyeΎ�.j�`0{{?��m
�4*_��q-�¿�W���#|�rm��+tL#c}^�3�)�B�v��Q�U90��I�p�*o���X��>��\-��z��0w�0�8e�Ih�|?��wA)}O�xݼ��	c.@�)\�O��Z�=M�=�|��&k����Xr��F�I���35m��t�A4EV��^���� rLv�`�y����N��e�)���/SV���I*�9�e��	3�s����![��3�Q���O�,Baϯ�U��5���Q�\g"{uM#Z�I6Ab�E�f�@ue��2�LO,OO~%Z/f�#���	N8��z[_�����[�p.��|��YOQ�J�0E��y����Qף&��n䏷i��e�Z�>|l1�����
��*2 ?҃�=����~Bs�`��S�i�	@?_F	b
M�L�'����$��@��3�F�7,�*Ӻ�Կ�\�s��7��8S%B��?�,"	�~y�;��0p��dV�1��娷����W'��g�9��ə�Ew�o�O{���Z���g����� �=ڇ��N��&zM�v�
!,+����j��Ff�w�S�xp��#���O���42�=�z�Q4�2��a�" �x�#al�-�#V=��x�%��=�3�v���8��!@[D>��� +m��,�V3j�ޭb��,�t��n�� ,TL�U����Ҹ��O�ȓ"M"����O%����b���ۭ0����<K�h!����1(F!�.��<ƨ��������8�_�ƪo�i�/�d@�6�f9�-"�=�9�DَҐ�R�s�5S�����\gk���U�sX��(�Sk�Ģ�34�������������YAW�ݭ�熹���w�?��z;�2�Q!��zb�pr���^b�(#��ӼF>,L��lR*;��xT�Tq�߃I�g?�c���!�˦���ݸP%�&=�y���`��O���P?G��%�2����;�(U��T��if��l�?�B{)!����'�lI��.%�"���@n	�±�ܩ����%�X=�͊]��9|bx����#F�V����eW������Z��h�gf�n��ww��$�ѺpJ]�#�H�V�SI#���|��ml��r��Qb�������L|�u�7�Kp���K�˅u}NR|'�M�6>8�F����ٝ� �t9#�w7ա���|�a�m�D�Y0x�B}�ʌ�����X��p�Y�R��H��ޣ{���T����:3c��sXP�=��5�8(�D���H�o�8�*^��Y�ܾ��Z7}�~@ٞO���H;�tS�_!վ�)�2y2%^����qv�}�DnŔ�s: �Yb����x�>D����%@��+w]��&�x�d��-�"�l�[�u;�1sG�Lm��%Jvn��;r�E�ڽ��v,�����&"���I~f{,5���k�Y0�pB�m<���+��J�b�������S����Ƃ��!Oƒ/��_G\PeliI�	��d�i_���[�u8���)���.�m��E���ԝ��^ ����B�o�d}�tZ痤nG�lvI���XqX_���𸌿[�n�_z�{�
��V�C��k�}!:��L�炗���Ӏ�a	/�DX�כ]��
��"@pX@5R��j����R�L��.B� �6Lw�}���F	�����e��
��VG�氷E�Ė��M�BΗ%(Q�����v)�������e���crY�IK�s@�B�����҈��j��l�~���|�K@a9/p�;F�1Q�it�?=������o=o|���0b����M>^Nl�^�qrLo�0��ֱ,��������H������z�R�$�k��P��Y�eSVG"nڷ̲q5�v��~U�Z�CF�s���7י��02KƐa`��V�@B�Cg��0��~���T�)B�H�c5�	��I ��<*할,;A-���%;ti�>=q��)*�æ��^;6 e�h��]��9�0͚�.X�Y��(��o�Hͽ��
��,kɓU�V_��z����ɲ���T���U��Q�=,�t�����R'��t�o+q��F�.nƹ�X�gl�j\���>��]^ �CkZ4M�����ȵٹ9��^3��fi����B#H��z��x���Ck�B� ��. �pٙ�#��
�RūA&x�A�c�S�7K��^c(��)��,�qP��^;����|Fش�K���f�"o��ɷQ��KD3��:�k!��r�5x>)CQn���n�'�Z.��b2f;ʏ0%���3,&�ȓ����U�L��8T�:�����(�(�GȪ\~b?����I|oRJ�O�qb���[RF)���[i#b�+'�ᅉ�G�)� �����	��z	��\>�߮�&d1,G�׻�1�xxx��
DNX����0E1,�g���f���c��J�d����A/�{���~�:�����@����iǫ�����v�9�y�ZِR�g�#I�� ��|��P��*֩^ٻ.iBM,OZ�|�Q<�B�'���k�5����IRT�I����xup��t��[�˲�GM�JU�D �֕�:�P�w`}�)I�/��V�iOb�?e���ׇ? �/#��i��Y	��0��A׻[�x}�g}a�yp�po	-{���^Tt��>�C�w$�=�Z���x�9A��2�����L[����ü��"��b�|ڼ�h��_ N/.�Yu�uL�t���������N[ l��WUC���?,I�ǳ��~�̄eAl��+Y��}zSVƓ�;+�b�����M�6t�(�{ҭP�P���bP�� M�Jd[�`v�����>�\��7�i�"y�����Ѵ�A�c�{
�t�����b�5��-y��p������Ծx �׽��Ӳ6�n�^	�?}%�mpꟄC���s��Fm�5ɉ�$�aa_�ʨ�����5SH�fV$��a�e���e�Y�O�l7D��}�"p'��[C�� ΃C��W1�,���D:
�t/���Q�k�E2�Ŵ�ԫ����$���4�����J�R�4ٯ���#�p���j��}�%{;˃��}\��r��:���$��B�.L�ɓFQ�rј���`�/��s %[*[0��
�yI^��� 
GN�l��N^�n�G9�Or[��P���E%�s%���f^/Ecs��۟A���/��t�$�[��6['�����'-�G���n�7���!3ԛC%N��kC�T��:
Ԟ��U��*PpZ�Chu�ɨ��#7mݼ����δ�Q�FdWT���)g���\�6�Rŋ��h�����.�qΉ6c5@�Cj<YS6S�a�8���x�{D�w5�Xv��,a�����^-݀���b�7���P�(;��Z��h���O��B�s��j�{��^�8��� ^W�oF� �=��9�t��r{e�UYab�G���jF�W��J���8���k��14v� �w�A���Ä� Fр���b�h�ΪW��/�A�{J`s,O9U��q�Ȕ���7$�+�$m��Y��'��� ����u�N�)L7$��4���ߝ`;��K �˴^�Χ)��ū5�O��Y���_0�`����g'!�3{�P�'+
s�y2L�A��C�b�9�t�_��a�MU�^['eq���z9����h(儰G�Mr��]HW��*�P��`(i�,��%`ISd|�'Fd�h?&X��n�T<��d�Va�K��|;�ij�i�}�NQ��i��\D�5��S2X����78?r��=�H[����;Z�3��vP�~���]g�G��������+��=�^k�J"�Oe�g���x�v#�r��i�`��l徺�����s?�K1�}�T�X6C����F���r�ЋK���2�NJ��b�gȩ��G�-�!�]?�i-�����[`�.d�?du����|"^�X[�!��v��<��ra<\M��(�N<�ttX���c�V��*
,����%�S<�D�k��I�:H�`�/��E�2'��Y_l�m�� o>�������d�B�?�:ķ-�Y-<X��}�f ���P����Q��B���u�k�z��9�s.;~�Ŕ!����W��X��^���wP�a�>^�$�n.֏���
Jo��a�m5�#�a6��{"�`�o�/?�2�P+=�D(�{��M��^��z����Qt��ɶ�o�"��gp 6f,���MM(,"�[<��s����y?�ȈV�T���\R��kAq���t�`$�oO"�Ԡ�&.�%��� ľuܒ�x�x�@@���.{�`�\d4��:��Է}IÁB$�٨DÝͣ�C��h�|�s���qǹ!ﵠ-ަ���)���'����W;�/��i�ˆ`T�X�X�~�&���Ͱ��i��~[XZpC��j��s1�STt`�k�bys�ol�&�/E��莀�-@�L�N�"�#�'�%��S6�oBC9X�PɫH�����#Z��Gv���n�W`FU��vs�4Ao��[�y>�k��?���:l�D�(d�!�m�v:g�a4�`^�  ;���+\���*ϴJ� �$̳�-,$w<���HN� Ӌ�I�E�|�7�;�B��N���Va(�7�X,�k.<���8��5A�ȸݜB��""8�5�t8~�Z k�e��{�$�����5*5��|��]>yC�x��cq���
A���q���Ö'R� �����Pz}$z#��8��/#�*����� ������^�O�^1�C���4or�=���2��IZmC0<
���d�G�>C4�ӿ��#��>��P��7^��Qó�Rh��Cd�I�)o�}�dT�L}#����D12YjF�WJ��E
C)����M	�,d2��b���$��[��M��ZY�m�Њ]ohȀy]S�}0͗l�������;��t'u��&�Ob�EwJH��7�if*���|C�bm T��<\���-Q�Y!�:߃q��Y�Ky+B�P��/*l����K�˭DZT��K��˓L����}��f,�+��6��T�k^���Gc�IVe�WsT��
#��t���ph�yc�6�Ӧ1k�X��.z�na�)���̡�xY������I����M6v=���ʒr��rm�7H'C����={�}*:��8��k�5�Ow�;z�Æ��	���!�,W��<�1-����w����d��������,ɶ��]�j��͵����������Yr��Q�����P�����?JcT���ɦ�ّj�@?;�I=�X�@�4��B��l>��Ƥ�:Y�/֔�"8�-��VK�B�C�G��$3u�	���x��}�sߖ@��a�������`�5��� �R����p��ϚX�p��PѦZֈW��5���qb!����q��Ck��]d%���1Z0�����6�MJؾB��وP�ݞ���_}��B�"���c3 %%I�J�e�il���c�0S�i"2
=�䎖��z��V���b|(�Oc[z%�`�1��T��	�j�T-�Ӛ#��u\�R3�I9����z�g唎���M�i�x0Fg�C�w���J���e�B5�ɵ���(ݲU�	2��1��)C���H����^P!�
.ݙ�޲�\�P��������ΏEy��_�SS�RA��j�aĵ�%?H���~�/s�����Yʾ�g&�)��#�>�Y�p���D����&���gKN.�{�1�Ѱ.�^���}��p�	2̓﹑�[�>�	����l����-7�Ho�Ò�Q-OAG�1yG�(��e�E�� �0�}�w��l��^]LWJЌ��8T��xxQ�5�X��0nQ�t�xM��g$f�(��_�|��=J}t�<0�ij�O*�҂�J����C�����n̕P��sz6L/����=|�x��Q���k:������B��#��mH@2�i�,�X��<���۶t9[&��A=���Lo���}rn�GSI�5��Ǿ��D��!�sx]������$c5��������R��O	a�lcp�Q�ךi�^+�m����
2��|7�9�ڀ%Π����w[@�S�<C\א)1Y��ܫ��5L�B�"��t�=>���W��~1v�B��P�� ��К5��}"m���IJ�B�ieu��=@�)�V%�?��
=�&��nv=���Y��V���b����ۏ��	�N<r!r��9���!~E;�?@[p���x?L�g���WRS4n:�j���f�<�2��!V�Ĺ)*�'���s��5������Uj�Y�2O�kS�N; 6�����+�D���%���F�/�TG��D��х�$ﰨ�f�J2�ʛ��2ŗI�Mz���D:�z<�NZ�����Pl`I፦&_��O�]���� @B�_�Nzy���� ��vƎ;�T=�qw,bi2���a_W���뼾K�^��劌�MTy#O���S�?�M�w�ut�&�+�;��
ܹDPqu���C^l�Wڄ�[�
�v� ��<0�M�):�|&�i��_{�f�����Mӽ�j��@{��w����3cJ,��Ӈ1���RPv������M3������zQGG$�'���󤄗2�e-�q�	c�N�)B<�<�K�Jǽ��td��~eU�s�޹�c]���[���pk��}�-fF!
,C6��G�����@�v+��7H8����<�I�uE�c=X��K*������0�����������/��\ {�&Aڝ�:U�(� �!y����O.�{
-vāF�I�A'E|B ��A�q�!���n���Ц�K��ކ�U ��?��zT-JD��W�l�?�DXQ���X���U�0f�n[Q��e� �ށF�!�5Owv]�J�[��WWX���- s���%*d�
Y��E�FU�{�%w�Xя)��z�+����A�L��d��))��ce�N�>�
i�-cx#����(@������ ��P�[�����ט����Ԅ��8ghpG�֕L�d��}E���Nݹ���൮K�TQ�l�������q_���5�4�]ݒL���o�OJa�w1����;g�W����Z�u��/�1��h�$�����8%0�N��`�K�&jk�.H�-���6D.��p��ŋR��$s	5�`��/~�q:N#{\5�Oz�Љ`V��*;����1N��������t���ې�x���F{Ԃ/b,f�l@��Ӡ(��&P:�	@��:_2ã
����
D�
��=p�z�-�kv�r���c�"�J�ڄ Z��ݼ�k�����ީZI���;�q���uU�{�Bzvg��[��q��5�%U� ���2�#�{�"�ׁ�Z.*�L>�
�x)6󼓈n[�
��Ea/��=8�;i��(��~g!qE���b�3��k���{7o?4�O���F����ٴ!����RD�em���2���6�
ȅ4��6Q�X@l��\_W��5�{G�]���u�kx�1�n�7IflJ���_�k���L�����)x��m�Z���mKy ��Zk�Av���Dji�3U-�i�zd�2��r���5u<�pX�	/#��fu��Z��0R��i�o�N!��i���媵v����?;��$F�uGi1G5�X$�'a�lx�R��n��dhU0�F>��7Լ�2*��
U��Ă���p�9n��*ۊ��^������&�/�3-�p;�5@\��%��_��KN]a}k,�Ŋ�m�p���#����AfⲐ�bq�$��y��`�y���J���Ƃ�xFۆ����獝�0c���~�l�x��	�!N.��#Mz�@-��Q�߀�' Ufb�w��[ʘjE�)��;hO���Y�8��i�5��B��x`Bd�[�m@�Zɼj��A� �'�[���ub��p�T.�N�|'^�*�J���R�bRҐ'�U@i�.��	�����~uK����^��Δ{��$>x VCW9�Q�3�B΄�W#���+S��v�����.ϖ�68+ޡ�< �S��rQ�W�:���~>�1xI��C5Gi��h[�gӻ��R��AI�w|��g�����w�4^��>K��TS��@�7��� �s�|*�����P;���UQ{�@/�`d��tW'��q��f~ҭ�tn8P�����p ��/<8���G�oԸ�)!i����dϣ�\�m=��j��L�1�LW|s�K!�.�W驘~��O]²��of���=�U/�Qy݀��M?j�3*�e¼_H(p
\��k�Z��(��ŷ񤨸rZ���<D�x���>��L!��Zt˨m9ݝs�
�m�����î�D2�/�^w�Y�8~��3�Ha�#�!ޮ����T������C ���D�߯6�#��#]��V7�}҉{E����k4��%�^��m��ak�6#�sZ:{��݅��_߫Sd�*��T�_�b!Rp�A/{:��`���H2��=�J|��҈�gT�*��3�)R�{�9�6������9�ݝ��n��#���\
Än#~8�
M�վn )&;ԏ
K>ܿ�;�O%A"R��q8gx��y�O��~eH�*5D?qڏ~{�L@���B�(g-�p�8tb5�M��	�?ڝj���]�� &װ95�F�,���)�OD�m�`�������H��p�X�l���s��d1"�I��e�c�ȟjBV�}�^�rLƱ�;��6X�$.�)�_�)��>(���+�j���C�C�i�L�uC�d��#ˋ�T�O![�j��#֓n�ۓ@&��2w��)��,�Fs:`�K%��iv�����48���x���p)j�u,K��!��hX�\h�Ɂ�o���q[�����o?�"��A#�S~D�k������P �.�#\^Y��oV�Iߢ���JaAkW��<g�Dɛ���Tc�4��;�m��p }l�-\q�Rj�%�#4ȥ���n賙2�9�{sp�7g��ju�.�6Z�����l��PZ��%~��|���`}�Ξ�k���Q�ϰ�g>~r&�U��L$f'Ђ۸���нe+�GZ�Ε�A��-(����ұ��i
$���|��La����Y,ք�=�B���~�*V>+kf}�"�=1�U�o��JQ�O
�����m��ͺ�%�ɏq�<��UN�6?�9��u���|��Mj��m.]�㴏j��S� ~��N+���(�Oj��B���W�w^`D��ԯ��"������R�u�]��sҵ��&��âZDyY<�{��h㍎���Y(J��>cO���q���;efK�Y?��I�P6zT�̍�Q!A�IJ����S���Mg	�8Y�!��Qg���l��VC'����1a���A�Z�P���j%�Y��	�k�2E��
���VTd��:��k�� ���I�D�I{[�O$р�B��#�`��4]O
ki\RDc`��҃=r��Q�L$�/�a���i5��>�n�Lv��Gh�TX�\O�D�'��7WEs�Ad�(Ν�db�x���
H9xtν��/�{�ɮ������{4���P��5~&O�kè=�H9��t11�$c��.Ù��ؚ����v�s
�puE>"ߌ��K�C�s�VM��O
\l
1�������EUr�l��J0����˺ �ll�r򕺄�0@���/^u4!D�֞_9�J�\�C����\�w�yLC�ד'�Ms��*���$�����L)1Fz�o��۾����*1���z%꼬 ��������� �GY�{z��x�/`��L��!.A2�`V��VW/8.��.�Ȟ�M�0�Xo�?�*�"z��s�ü�����թ�����U}���|��k���d
�ۺ*cUO;WW=�b��CT�o�kΝ܍��u�5QF+]�{�y���i��7w�t�Т�� �L6N+������&Qx4���A}l������B��ԢP+�\�:�� ��'�k~-�ZGa�gЕG3'��"�e6�%]bѽ�[yĐ��Y?i���_���Yd?�X�t2}>�0H�5���W jL�O�y|�6�N��>:�"0������(u�##��3��RB��)	�e5�+��}��_��w�ƹ��>P�H��@/��B
�K�P3�Q�aM9��{W뿬�P�LIZ@BAD�A�i��ҫ`N���g>��m�P��I3D���<����n�p�a�ѻ�&��ewΨ�r>�����"��>�:l�1տ���RaF���s����h���s�#�-����a�#���f���m0b�:s�(�+٭12wFEC'y ��{0�Ҩ)�-+�'o܊p��k�p�BA5����dM�A
��ӗm,b�ˬ��=�Ց�D�%�N�f���������I�h��$�˭=j��W������2����Մ�Ks�ux�Ua����D��s�;.3�<*����o'he\������c�]�����	߷V�X عq&H�2"S��`]�˝=oYr�1kQQ���U�ÉZX������B�	 �;��餃�]�:�ô�;I�1Ro�x;.0��><�Msu9�G�q|'~Wo� ���b��z�>t�L:ȯ[����Am�R�����$���"��ά���}Y��9�6��ך�k�{
�@duىuҾel�����:�l��(AP���|K4V�����4����%9�Qby�No���E����|��M�5��	�!��H�|���ڳ���A}����'d��z��(w%ٷ�$8,8���0a�"Y{��]h��~��_
9��X�:tI	 �d��#뜄H�̃ڿ2����;���-O�"۵>��q#K��`Q����h@R$���:�~�D� ~ut���f>�����Q������,���`�������bgm�����rH����|���]bj����Җ����bϺ��\���8�̮��-QJ���6m��	[�QXo-�t:GtY����x�e��ש�q��ܟ�����;9z{e�7�Sw��MT�(�3	TP��@&�i+�����#Z�G����}�rf��x�.��V܏9 ����y�+��CKW2�qk�c�c^/N]�t-;�6�*W?����ˀ*���֜iL��r!�,e��'�����$��X��/tn�ݽg���еBR!�W���+ɫ�ga<��fx�������)��A����[E��@�'i������"��3-SbN[���D��CP�����=���t���sU}+CO�C�^d�o�&��t�vL����L�##)"�iu����9�q����m�k�a��MZ�%�2���>�Ҍ�������0Ws��f!@�U�m@ܯ7~,D��AN�}ݶ)PY���zA�X����-����	׾>-���m؎��+�����\|ݓ5d���%{<�C���x_���³Ă����EEϤj�g�sF`��R5p�'��e��M��8�$p����/u�����v��� �҉��v��n����)L����.�Ŵ�EAޔ�����m�w�k��&r�x��v"'�}��h�a͑�[�~�ng�B����R�v�+���+��$�eͩÞTѥr�m9��CAn�9���M?�&��t���������%��cRa-�ap�Dc�]VH��!��>���F'����[	X !�������$\��`����`�?A�tm�UL���*�϶��?�J�ڌ��
� B�O�~�|&�b��{
T�إE�1�~��fǓ��5r���l����6Q-j�_3�>���[%�s<[\>#c�4��*<iWc�1YNC����&-���#�B�n+N �h5l^c߈'�U�ci�� ���:��d�hJ��0:Hm^��'��ٷ��$��̫�k�hq�?u�d��y/AEz�إ��iC�۲�Kk��Ly�H�<"���u5Mڪ�<K��B��h�.��춍#mC������X4/+QUh�0�?u0�<gV��Z��4^��o{������L���+h���vf�#zgȈ�V����l|��J�
��6)]�R��S����l�`a������oA�����XE�i�� ��\��������F$��V��u�]b�� ���:}BT�w�'G�Id���Y�l"���X�l}<5�E���A�Nkc2.����`�)�uW���u�{Q�ilv�Ա��s���T�"�tw1�o��K(^�5�=�юx(�l%*Q_�2Bڷ\��7������Q(1)do���������4b굿F$$���	
�]w8�B�	�A��U�c�3��m��_d��3\�=n�uF��w��*��a�ꀨ%y�T�hM�XM.%T���R=9<�g`��3+��\R%e>3���-�c[Ū��߶'Q'�h����[����P��-����X�B� ���9��t��>^�7��@*c�&����\S ����,�6��T��Wu�ݹ0{��de���3���-�s���~�_.]�sf���� �����;�׉�q��$��?�Y.^��P�� m�=���Õ�2��oĠ;��{��LK��:N��Y���П��'��7̸-T{��LK��A*���jA����K9w(�� 	��V���D��=�����*�r����r燏��ۜ���B����ܷ�m�lE.�������\(܊+z��.���ͻ��Xk����`>�)`u��7���_t�\m }�Y/Zq��A���aDg�P����W5�{��^�*j�����:zӶ,��ܔOs���l��Z����؀����~��r����θ��i8�VP�S>R#b��P��U���nX�}R�{x�+�V�eR5�0��$���/��?V�:��z��V?���蚙��6A/q"^1I[<��OY<&%~�޵��[g,9D����hG
��<O�-6,���J5���Ӯ *����w�8$�8�QI����(���|G�k��	)qI8�1$�8;��r��2SL��C.�@���c�$������l��E���h���Y���Z�J�1�fͽ+����VgޑCդ�*��ۯT������4�u���u�2���h���z�Ĭ�)���ٙ
��4J�s�(hv�Q2 <O��>�V���1j�:�7�@4L�(�d2Nusݛ$>�)eҨ��i��;�i���]�f]���[��mٚ�U�.��z����[,aS"���R�\1{%S?��������o�W[��հ��(�J`�"6j�q�H����R��UGR����C�N��������L8V׷}� 5�i$?�%#/�]@�3��et]5V���J�Hg��?��2�&D������\��,�����b�*����
Uy���GY?���5�J����=�K��LɚEjk�!�h%��m�5��]ȯ�c�i���Π�r)wB�#�q��ٗ'���ppJ��urT��px��,;��	�blp?����sK��1�Ҙ�'�	Nm��l=>�f)R޳�aB�\˻��1�
�
PB�	��-���d6#���=͵+-�2�~ox�@b\i�x�xd�?HV�X�C�Z�q�j��CS�Z�iT���G̪���#nK���%>=���V�����I{�� ���>�tJsҘ��
�uݟ(�&XA����0k��h^��R���ju�N���u+4L?��T�ķ�1|K�N�q��ӆhJ�aR��Y�#	��Kr	?B����w~< ^wYnu]���" TM���=�w�m}iu����/���׸z(��B�e�kZ3�tl��ƴT�(w��+޾N�!I��5.���-=�u ��ɤ�ۏޠ=/c�PQc�g��{����WOm�<i�������Lk_������b�]��-�Z
�G��C�#W���j���w�[�o���3bk�4�������iL}���[;�R��c��vI�?��T��\��F��~򘣘�����
z����ׂ;�9?Wc�`�O��j�lXF��T�
����G��(���|SCJ�O��8��81�*��@����`�~i�������irYf���q:a]؊��q���7is��(�U��Z���[��z����\��M"�a��g��g�J�n"gX�{3�;^�y���z$6����b��\/,Ғ�p���NG��2Q�#rez"�R�[��	��:� �{jȣ_a
��<�y/1_eʸ(�:�*��,�&S侓�{*�E����������

؅�^��24���CS4��W��@ݵw	5d�UɊ\����)��p�Ϳ#�D��2\C��҇�<��b>;��H�y\k���R�p�l���n�q�0������|��~f@S
Sv��}=Ea1	����d���BJ�^����)��( l =:[K&�/�"� �騛���7���Gõ���"0�I~6d{�Ɵ/�U��l4�s�#�Xs�X�5���U��Ð+�H�2�[/�0Ț����ԇ=F.}?,�3rbZ�o������"@#ά�:1��z�5�x����d��oZ��O��z�!�H=�bM߯�G��y�˅��k�E�|r����(�K'쐣h|�ڵ�ϡ�]~��2<�X2�X�&2	�W�*���﮼�Xٮ��*&_r�e�2���V9��g��1����x<�`Ξ
�s�6m�ť��*�0��f�0c��1>�ţ��&��Um��f�e�P�:�ˤZ+�3Af�K�O���� f7a��Ղ����[�H29��QAK#���GY��u�$-�C�,�_��Zn�'������ނOu��F�¢��������G���ī�]��M��ߖ9t�/�v~�ͩi( 눆y��͚��?d�Oo��D��4�t���7�~�(�|��t�_a �݋�9�l��Q�t2}3 �q$�H�FY'4�����w� �<K��[x�}�[����ףO�?����]�PЈ��ͧ0����z�oه>{:E�Ux�w�x�	��0"�Z��� �O�!W�錃Z?��dވ�&�ƂwB����D{ tI��b�:dڦI���O41&[O���O�8�g�����5s� , �CE9��I����Au�E"�9nY�˽xI���*��H+���,MT�̄9`�фi\�3 os���<��؃¹̠5�*z��2+�?,�]�����+�?�ݺ-���8F:87`^,��� BA:��^&�����r��H5������GO����oт�i�]xڄSA��X>E���I�p/a#X����ُ�.0ʷ`�ۚ^��B���&,���9��ҶK�@v2a���]�L>9[��}v��>���"�Řx[�va����$��>�.����v`�`;�O{⚽"�"� ��XX�O���ť֗�+��$���%�0��53{u��d(b��]etb�!������`TDl	�_��JP��ฝ|y>���d��rQ�uj-0$n\P�,�٧�������zA(��k��֡?��6Ig��G��������0���;�*j�(v\Q�!�	�o���]� �B���6Ƹp(U��w\y�辯��+:�S��i'���~�&����5b͸��IO~�6�y���]Y�\-��[@�i��_���YB��%�U>�n��ސ�`��?-Nٕ��b���&� ���Jj�Pt�y��Ҋ��4 3�4���ۘn_+]�r���ulJ���sK^x58'����H.{�}>ފ �h[��)�y�Ft��+Tɬ?��zz�O��>U��6���M>U���PJhHU��u��ԇ��pm�<]�$&�@�fc��h|w^��M�JmjK���}������<��������TM�蹱�tn$q��F��ت9����=�v��~��P9��@[�M���w��U~��r�B;���|W~[��^Q�h�F;�7<�+��S�����E�+wb�`���2?Ň��_�R���!�T٧=n��d�d�E�@�rY���^�~~����Zxޯ?G�X濆4ŞC� �R'.����8��׀VO ���{�
K1����!(=J��^�ۍ�����[�rK��AI5dr5�7M�ʐ����=T�@/𖚘ۆ��ID�����
r���:�!{�-33���A��CG� �]�k�PQaȳt��.1
���D̐qkz�=�
��'����ft��:&%������"/`���< �����oQ����W˕�<��dSG�a�p��.uC@�g&�'Sc<��/��ߗ'�S� ԠN~=!]��^�X�K�4�(N)D �41�y��x���ۧI�	���l�|3R���ё��F��AF��%÷7�i�E�n=dw�)�(���A�	�0����	ݮ5.�	��-$U�	�	a�����f��2����9��s������T�(
�3I��gf]/Vۄ���t�z��&���g����8L~�rP5䶲�|�B�]o$cG0���o��8��G����-p���(�?%q�I7�6���sm���y�wm������F�g�m������K�As�'�>��#���!���F��dX��AGh����u��a�0&:�0����$�udc�(�ot2鎑�cZ�n�� Ӱ������F#��9L>��n���)zΦ5Y���s{������z|F�I�*������ʘ0U}�n�y3_Cs�p��c�_��<�TNe�לl޴_�J/V^�i D�2���5)�/;jgKU����Q���3.���E� �
���L��T[EMF�#��i�c��>�̡2u�Z"[e�_�y4!�x�ױJ釨�x�Iވ��rh݋�K��,��Oŗ۹�É���j��&Q:y�fƤ��BM�Eŉz�\��&�%b<�Ⰴ��5��6�Z��_� 3	�1��~���٨D!��F���)3Lb8����a���|n� G�آ���"�_�c�<+gJDl�y��9��U:�<8S%���K��*~񆦚�O�C8��y]2j�����o;�l�I�U:��:��覽��[아�F�9%�S+t��/���4�CVW�ޠ���S��Q{�6MD��4����-e�eRs��+�V�N�e:���c���z�2y�PLb:}=C�7�.���/�_���<T��F��cQ��jEG��rT�������B*��>{�{DA}{-;�����9��ʮ�MD5` �Bnx��"Yr�i������
5ŏ�R�oka��5��pc4�{�lN�� ���+P�gß�8�%�H�w[/��S�W�͜���oۄ���Q^u�pc�&Z�V����y��m>E�zS8�?!O/g�c�}�N���;����	�]��5��˻$�%�+Ӡ-;� gޥʖb����O�j�-���3W���0!��L����>(\3a���Ȫ��D?H���Ko�×E�
+�\�$����8#Vl�P;V���b��5�[�����}�;�/��]�f�|�����'�X��re`K�ڒd�D����'߸!n~`6Mٻ��`�	��ap|Ī|�.|
���k�L4��dd~��7"��?���� sI�,�ט�@��Poq��/��p�h���}�-��W�ͨ,�8��3��c?����`�E̥�ϩ���s䑸-��9�N��wn�̉�k7C#:H���:�z u�9$:���E#�^d����2&����Y`�rU�]nD(0��NN�ѕ�eH ���\������(Y�hV�����C���o5A@"b8�J�o\Y����z�*$Yr�ۍ\��=�?��v1�j5Ҷ5?̭��f[�g!y�I�Kyn��6s�6��,�������yE��%yH_˯�i��o���]�;��9�P:vrFy��ߠ��?�@��Q��A!���r�E/-�:1)3O�IT�0U����NP���h����iEw��9�¶�vms���ˢ�Y",������{����2oZu��*5f���t�_�j�c��Dr�x���7� Z a��� c2r<=���s/3���x�5n�'CP��!�U�uI��&�Ni0��H|9f������|��R��l,�_�^��2èkp�n@�B�F�]���v�^6ss4]�F���6�h�[b�V�R�[�����+P&�}:lQ����$����+޳-vl��1$?��Q��tv�諼7]kF�   ��U�l	� �������J��g�    YZ