#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="492718015"
MD5="4026717fa4ad31797054c83c88af1215"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23424"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sat Jul 31 16:22:13 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����[=] �}��1Dd]����P�t�D�`�'�t"1؄�HIǟ-}v���!s2��3���^+��K"�)��Tm��W�_*ڣXp��H�S�1�r<�T�\��k	�HUz�/p�����Ss�O��~ �*,��[�`������������G��9�J�IS��I�}�̉�e����n�{9j���$ֽ�7��2��`o)0�}W�$e/�T�0�,�|�Ҿ�a����9K��G����.�/9��7%t�~i"+P��n
8l������{?T$��Z8P�]���	�KiJ=����5�O��Ϻ�9xB?/�v �;�oFͫ��P��g^�t\ʨ{���}�2�}��s|�<?�	�
QO,����oJ+y���M8I㺮y�!|+�B�vA	��7�ދ����D�&}�� }-��UL�˵8�s���H�pn�U'�z��3�P���lsr��� ���k: }.��^���yn ӉP���q���w�"I����J��a�̵��������#?P�W�2����4_�����h������H���H����j�����s��0���:���3�Ӟ#��K���$���⵾���&Ҟ0�	�y���%�i6��=�֫��s�#��h����!�]�T��Y�-�V�MC��]�x	�7 c��p�9_��ؒIz"����x�< <]m��C_��#���cS�}��<y@)Z?'#ð86�zn��o��׆�6+�b#�"��Y|Q{$��P��4~k' ?��^o�����;y�<g�2�Sw1�?T��u�D��
0�T�Y"�n����8K���S:v��4���m��fx����:P�MpTZ��_?=�j��t��ĔJ��@�k{4��~�+�{ �[���Ô��Ƶ��ͩJ�t�:bb��",9��}�*I����"ӏ
�o(/�C�u2�N��qF�'�|�+ ���I���~��i���������O�_]��Iq��2�ig�?��7��#�י�y�(I�L��mc��f�68��� �|%��(���+= �w�N�������.��{��Q����A?��"�EĢ��,�L���Aq��%P�r���M�ۄ�[A�=�j�i�oG��1��і��_�򁖠��4W �W� �v��>�Ut!0��a:���j�Q�#��_�N��@pM�B�o9iU�s���8F�(�f��x�(N/�����������m����x��~=�}#s������=�G6N�N����f�;�;�A�`L��|Po���8�����+j��;����=���C�~S��%�QIީ�����27KR�����4�"��q��a~��q���K�N�o��bS��&䠃uf���{J�+�d���zd�[h�B�%�\��O�Me������>�n�_�Wݤ41žy�"�~˖ �*m�!&�R�'��a�ҥ��ȶ�T��4���%�`�iY╴��-�G-��+H�Z�aU�nRl~/Ⴝv�$�eNiSg��G�y�;��'��2[���m�_���GaP8f��Yxf�
���k}����w4k�p���o�;g*���n��\�����&}���KF&v�3Ү�4M��,k�y-��h��N���x'M��K@:�Q�����I���Z�R5$}�`��
�{�t�[���}��U���(7��Z��BF�֫��D���4�����\�l4(�e\��p�V���6�0s#J�#!��˔T�V�(<�	ē.���vz>px��K�ͬ� �=g���n%=���{��d6 h�w��V�B������"�}+�����?V_s��x����������6����2d��->��щ����{�/�:�Mcq�G������k�<���5nu�.�m?��6��Z��<��8�=�WKtzU�!��XK����XPi����K���N�{t��l3wq
2sHϿ|��@��<˴�<Ud��r	ݛ�	Ԝ��يzk��2�Y~uQ����ُf�ӨDt]�a��s�nk�݆�~Y�� ���(�h��t}��"Ԏh�*��M9�~��o"�,�� �UH�*��ӸSż�~��&'fo�횞�(��n��m��"��r*�C�i ˸zވV�ĈX��[�48^��>WM��:�3�����*T��m����AF[r��O�2�����L� �%���j.�1Q��n<�E/s�a�������&
)ʡm��"vx{�h�jX�x�4���OT����|��$��4Qe%S�������x�ޔ_%��T�49�ZH��[0}��X�r?%Y��ᔤ�>�S�-�S֙`j�}�@Ve��d��Z:OZ���U!t��K�L�L�}����	�����X;h̎�	;�H cP'�1@Ԧ��n�T����c���H�w�zN�j]�r�����������0���[�,T�UX=�r�b�r8ˉe2���8	"*�|�\`�>8��?���ѳkU�D>��,�l��f�/ӻs\�O�P�����YOU*�[�5��Y��X75N�:����`�=*����4B��"/�f�k�-^x3v�&~�++^�^ת�A�y�Gcxz�wi�~��)8����P����3��s��n�iا�c��MyDړ��N�8S@���R��&�q���g:��镯�_�6E2o��|-L	V��D8	0��r���U��P�!d����}��#��~N_��8/~O�+��"�B~};�[Qf��4� l9�7,��VPt���[o�s����Y��ԡ~1�W���}͎+6�M,��w/�2�w:�������q۳�N@3�OJ�Ãi_�w�'-�	Ԅ1��߾g��������f��渂m��`94&���q�`E4s��X�55U�-�of�?� �¤C[,Z�ްI�tŹ���^:����ZjS%���i�"�U1��fP���
#�Y�|��!un�a�Xv� '�	�.v<�#�eM�C{=�3�gF�[��iT��k�Vp4�w���vu{�����^���(ș:<��@�@�"Nc$aV�j\�a�P�V��>H�!�;��n�Pc���&���gBP;UD��ܓ���Y�>Gd��]���>A�gUQ���+�l��܉�U�zr_�iYR�~����5�&ǿU�ݥm� �kػ��n�"ڞ��;���4���(o�R�p=Y�f�C��%c�Η���F�A$�y�m�'��D��h�������g���.h��Lϰ�PC�.W�.���	��w)�@l52:}�tMU�2��y��m��Xh��?9d��;��K� 7MGc�o��ɃnfRY��:@��zF�<�%4'S&�k��$gklƂ�c��.PȨ�4��Hο�"ҿ7GuAe��7����UU�k��yD|�*���W(��s�ل�Vy`�h �k<up�q�2Y�i����פl�����;AG�$<�v�WB!����q�Ad#��jǋ������r�igy�(�E�w���2K��DYʓ��R�[��8���w#��)Zd�N;�lP�7F���{j4�����M�.�6���9� �Oh�D����tO�*R&�R����6�{�.ZP'�7�W���$$��w�]V ���m�+8��)��a����>����v��y��R�t�3�??������d�N��l�3�@kҔ>�h�	
&�]M`�}Q�R݃�p˟ @\ȁ��!I>i�>2��C<�`F�ֳ�Q��C��]��V�zA;���������®�lN�o�@>3�3GK��9hUYy. �}%���*�:
�k:�q1�l�Y��EK<�I����඾�U�<��NF�u0�sPL+g����(�Sm8��!��`�D��*�L}E(�C��GLOѱ!<A��w!+�-�2 ���P��X�K�b���x�c�H��e�S�02Sp׳�*t7���?h����;��mG�U
����m<��� !
�z8:U�#%;��q���
�(�70GVs*0��z�{���x�~��7�⡤E��#��@b)���v�u�=��e�iP֠"3���r�����!���7�����?f���+d �S�1]�7��5��Ԓ�]́I�q[U
	u���biK��Y�s���Y������z}��p��p���-�����۰��,�0,q��6����Ss�ϕm[���qO���!d��{B��Dw�N4%�b�?{
��0��#A��I��䳬c��[���V�;�J62�2�Շ��	���ˠ���?�[�F����+���
�C��`��T�>ա))d)W4��ik���� �\bZ�x�u1�Հr��1Ƞ�@�EEnz.�>v .�g�YL����RA�)��[�&T���`�#ΊZ
�4������Ƥ/63J���1�(D��f�Q͏�Z����[� \]��B�7"`��s������*:���b���C�J�c7�t��pt<\$S��� ��Z��+��8�;K�61f�խy�����'�쑔q�q��$R$h�H=i��§��3���<WԾ6�*�g��t����!�w�[[��p	���s���6 ?�c�¢���@�����x�:2�Nh�����Q���쮍l�-�t�f��N=ǟ`�(g)�z�ҡ����! � �|�k/�sӴ;oG����VG��oS�jAN5Q��\衬���Y�p��a�8Cɕ}�^R���@u@l=���|�?r��e��Ž�[��1�@G�ٔC�."��������m����%�v�ҋ��0Tz��W"ڧ�����B5?Ʉ��q^p'HsG#2���>�s��ty�<�+9�h2�ʭ����V �����5_�8�����ȍ�-�>��(�4I
�ÖSm�,OI���B�����я2�`�6�������H�c%U�OaHY8n*�Sb�ꈎ
Zx�ЬBo�l	A�um�'�4z���w�H<�[�*�V=N�Nӂ��+��)Q���_�{'�l����I��ow��@�;���D�����ەl��@b�T~��7񡸯�G�~Mu*x�N�t�-w(�D\U'��/���I͖s�x�����֯Z����BE�0���� zQ��Ke!�����߆�'�Ý�N뵶���Qn�Buf����M��ԡ���fP� }�*}�C���AGJe��|~%�ґ����a��1G7��:4*��B�������Fm��J;��4_?@a����9o��dYL�%����2j*�@��X7��!|k��`}=2���9Y�+�:�O�6
!{QU��A��(����Ǎ�u
T��^v^V��	6�\d������3����T���t�a��8&Z�$o)�X<��
�.=G��θ�p̈́C���Z��p�F*����XdlY�?MT/�d��h��r��1��ր��q�p�/h�����]�J�8B�C�b���a��C��������h��lB��i�&��3�j�J�z"k�ѺҦ	�����Phi_��� 6�k��d��\�0��iލ|ˎ���_�d#���u]��ْ�3j���.������>�Դt_
�-��������ܘ�Q�	�Zo��q5�W%����jS��~��ݜ�JW(V��DQ�CZL�Wͩ^J����a�)|����� �&[
`�u���Б��l-^.��A����3&�?��E��IF��@6��y��u��5�A��l����g�o7�(��� &TF��N���C�dPQ�(�^ ��O�mF4� �E����P"V[��
^;F���!W[�P#�ۇ�'?И����:�O.�� ���8��'&��e��9�ʿ���ݹy�T��|�/�[�*�cu��Aw&$ ���B"�?��=�̊��r
��R�|�:d�54Y���w�}FU_ע	�&�}` X/�Ӡ�?NFNs���&�uN�E9¾��N1�O�[Ɲ_T�'h*5i�+�"Xs�Y������A����~�2��[�Í�bDa��;K���@��ڜ��M��~��x ��kX|t�5sK�k���X�;�����7,���r%o��YKQ�<	��0%�'���{J������%*s�N7K�|�%���6��͆O��3�[�������X�H��y=nJ�[����ef��pk%�%_|P��dL�RV��6���L8��"�D�����FTL�������5�� f`����a��&�Nz�L1��=*����G�։dd��q&���#�0�)�Nu��`�{�o��:.��H��C/e���}��t'��KD������d-��uj")ْ�C�p�@���J̫IX�qx�����rNho���'��8��a7K��y̱[��F�oX�`쫊B ���G�e�k�����U��UT�:B�9&�{��{a+@��p$����m�<��jB��M�8��X����V}Sc�3G���Po)�u��OV��=S&G�;��߀U�Sv�>�T�GW>k�`��Mu�c��)�!Ф�2����ᘬ����h��)Mj��j�[���s���,b���{��<���?����k�թ��v�c
�|CA�=-8W�U�Z5^�Q�g�O_�GB����_�^4}�0e��rę���K����s��Z-�˙�::������N�d�����rt�혲�uſ��뮢�Ǳ�s��d�	Z�b�*�ӫ���c���9$�fGօG�5d�
�v�/�
���bF��3y�җ�I'� 	�'���j΋�r���v��L`@���J{B97��|���*�ȳ���P�k}+�)��"�����|.���O� �9AR������x�:~��{��Z��bx�;N`ц�-:��m=]ϱ�B��,B�!�RJ%�7����9<�$)��X"��ܑ���>��زhw������:�Y�&J�ZR���e�<+;��ŀ��2��O���M*��<�9�M�Cl����ϟ�9���Ch�Z֊9��u�T$��t�N�m&v^��.n+���*��`6��1�c�|+.�L%m���="z��t2��u<3J�e(�z��l��������h�0�׆!8��I^�����AZ�k�e��L�`�T�W�(e�x��3��$<V#��E��=l!���,h��_sD��J��h�6LxC{��_��ڃ��x���6�����u�B=V*zM$��@�mOn��iD*�P�	��tӔ�K���o5�7�.���RY����� �&���h��d *I�{�f�a#�����6	�	q!3�(pS����I�90>�������LN��p���(	��`�o��U���␃i��fW���E��ξHN~����<��Aڲ��1\��L:X�,6�'6�z;1�Fc��ޏ�n�M�����a�rฏ�{�_E���]f��XP�f?Na�j��k��T"Q���k������0�̺.��3�w1����ʹ'�[D��ܕ�VgW�C������Y��č~�~�4TR�E�� D4d*��ڜCf��>"�x��sl�<D�&8o��$�����3_�����?��Ļ��@ ��J�R��`2����=�jW�0���>�m�5n��������'�7����I��Q�joT�	�9���A�q�{<�*�W����h� �[ �G����qC�YR�<
?˄�,b�v����P_�_�����3B�I�k��X!�\����GH�� ����4P2q0�"�?��t��%���Afɴ�R���2'��#Y����<ْ�_j�⻹�t-�>���s�d�9Ϻx�u�N[��$F8�4�J�T�R�m BO��5��\I��J��h����L>��r��蟀�I:_��4$;-X3/'k��%�7�mc4�C��&�1��qIv�$���4Q֤���v�}ݶ���ݷ�<ȟiHa���<rm�s���&a8hai�Ϛ�X�7�.��Ы� ����5�VskSc�}z��Z_z?آ3�AMh��$$���G��x@yڣ�
i�j"l�b�
�2��5n��uȞ$�㑱>�;	����CT�� $�(����[��ȱ�D�>����= Y.���r�"'ā���6�I�I���B����ZX��-��u~R�����3��!������K�^�F7/�Ć7���O���� t�x
���e���wm9`۪ð��k��z�/�hA�L��
�B'�E�0�y���<�%�RS7����WM���%W�^���v%M#F�x��+^�����Wa
�?'����\��(Bێ�(��� e4���a�\}�O��4e�s"�Y�+9�,W�g�M�S�
B��k']�q��%�����yYBqrW��g#��SdM��ܴ�'�7�3o���lt/�h���]g��s�"�T4�BE/?i�P�a���IDW���@�����za�u�	H�l�'[�����UV~Y�yd����:u$�@!�>�vS�"$&=|[m�v�[*���<n��p�F[9Xb�A3��R�|�����9��a Y��]�< 캽4��ھ��UGd���(����%� �u�O��]}�L�띘��j��#�6f<!��WU�VZb��Uޑ�$zWُ���ʐ��)��f{�i�4T�]�b�ńjq�`}߇ϛ�`���@��� �e�X�B�F?m]Is�r~�=�!��5��5��ϰD�P�M�mR��c��2��.��!o
���E �����R�^���jc�c�LD�
rP�Y�#�hw�2 ��FSd�^,������r>Sy-���/�Mq����4�q�
0�\���n�w���/YK#�ʹ�O%I";����7qH��M{�>�^~ѿ����`V&ú�|:�\�Ί0c�B����E�/�&�G����~Eݰ�]�L4p�qo~�?��^x���ʯ@zP�W�lD�Q�+���է�F6r�G^���IQRv�Y?o�ьls<~a��p,�|V/�K�a��C�^dL���k��ZT��Z �w�b�]:;u�k��Cf�<��mm��(��,�C ���E�-t��+o 2���qF��L�]��/��'��Q�������$5��U�b@�m���Z ď�j��A���]����1��"]��̊6.��~A2�5�M*��ն�Ř�ER�/9>�"��i�k$��.���Xcy��>G�$%�,�s+���F�Q��E&���ڕ�{O�h���*�(4K�h7 WL�C˩
���Z\�v,�9yL�P35|�6��	G�=��c}>����rM�w��iy� �ά���zJ�x�K��8��Fq��p-� ��Úw�sϢ�#��x֪��J#Y��)���X�de��p��2.���ls��v[�Ul�=E�R�
��0q���zLu���3�U]�;��%=�'��|�@1_��RQ�y��YA�l�z��"�,�It�� 楝���Mu�Fp�h�מ[P�i���9��6��r��L�W���ɮLZYݺn6vi^��h?�_(�uR�Ǡk,1��qء��& ף<22i��Z�#٬t3x�%��ErCm�.$�F�G�[��}y�qٔK�J���z�'��-?�_����͞�0G�8!���©�]7
��l�r�?=^_O����;���j��8��,��  �lS�u��1H�L���i�I��+��dvb�{y%�M���+(��.����P}��V��owٚ�'��҈sI�(�A�L��~c�F���F�� D˸�*ol������E�
g�Fӳ4E ��,V����P.l#���ڂ7e��-E���('�	)�)~tDbo'V��c��[�sFE��T��Vq���w��o���m	zP��/�ƥhѨ�4��e��v�K�G�A�*��ڏ�f<G����_����r��Mu�:����ו�$�.����nf2��ʦ'X�R�$��buƬզ-�/'
��O���T#e�,u.��~ӎ.�m}�z.��Z�A9����i�\R������,ws���tR�`�t6_��$5��;蝚�<���D=�o�Q ��A��MjEx	�?�Y��!�N�~�zNi������j[�?H�\��=�ܹ���@�w�Px�i��K�o��a�2�Ǳ�����а���	�M|rF`�[����S�={ ��{��U�W��+���ژg���1+St"�T]�w�Ǵ��U������z�,H,�c
|@�?��;}�M �p9p;IAr�x'�X2"�aY1+ODX/��ڵ��0��,�}K�0��c��-ǲ|x�"��_	���8�A�6 ��ק�b��ŵ�ц\��QR3�j�~�*���,������ؐO=����z#�i7�a������9Y����jD��n�b]a��c`�6�X\���q��HP��n̼��v��#:��K�}��4&+���:�с�}�s\g�MTද�HA@�0�������T�C�ɰ9l��e�8���_}�����9a*ꠄ!u��nnL�U�a�i ڏ��
+���b0���\�d�Li��
{g/��k*��KN��>a��@5�	�4�wDY4��q^�(`�uCE+�RPsA����1�|o�b�����1���Ӛ����5�f�h4K���w=��7{>V9����!��X�Bި6�L\T�-#��L��J�'\��Q?�yW �����9��t��\�:S�U��۞�=\!,ÕJ���KW7�w�I�A��r~�G^]�ȓ��~�PF+w�&+_ŉ׿2�N��J���(^��s�^Kv�a�1{h���&����_���B��~
�]�$��2��-|�\��V���Iy|���!~9��g���&���ʉj����I�z��n��x�s/_�6f����h�_�d��}(��8]^�f��� �<r�d�w�R�������P��Z v����5TA��,�>hu[��9j�II�U��y�C�k_ə!����mjK*JY�IT����qq3�\���d�7�&+yr��Ȕ�ˡlŧ�hi��Q7)�Pj\���񺣽Lx|��IT,�.�0<Q��>)E����f!j���qs��Tx�I��&�)+���b+�t��in}lu��.���4e�-Oq�MC����JܑV�0+V�ij����)��T �.�r#��q����>��G41!�ȧ2k��ȱ�p�#(9[l*8��v�z��.�Rsa~�<3Պ#�<U��sp����Eׯ����$�s ��jhV#�=Q�A���%W�Bc�p��7�`ͼz����Zu!�A���z��Γw���l�T��U�*_Ϭ���qm��/�{�4��^�C&�{8ț�~�ҕ`-�Lhm�F�P���0�w����C�EY�l7m�G�B(�"��ݵ]�@0�h	���#YE{�{�K��!V���1�p�ik��v��b���P{�^o ����R��֓���JB��{O��Z���Ӥ�0!���+cQ0�j�=>��m&�ôXЖ��������Ŗ�3kj� � �"�0����MH���iv�]k�~!�X]��<#���q��`�8�hEhOMߋ%�WI���6��� ���o�\�J���Ә3�>:�g����m�AKa�I@,��i၀x�SJ���̾�ޚ�hdj�����H�4_e�($�>�X��-ƭ7㰉β�m%����#��,~�}/Ītn�'⊚N�f�w<��f���xnMQi������U3�ɞP�E���'}���H��V��A1ֹ	ko>����	��e!h�#m(X?;]��)?,-�q����b�ցg��mQ�������N.�� ��[��Y�������=5L�D�-��W�	%\�^��|���^8�<���;K��x�#�9����L���Z���g�3�_�iis󻈷��Y@ވ�(�Z^L~�������t˼�&��'������-A���Π�.����u�9�Ƅ��<�U��*�{�:R�1E9�±l���	l��zz��@u��F3�M�}�*�I�\��VIs��]�{!�]x:�
������/�$l⮱a�P��Q�;��+x��O ������P��1a�$n�D����X{#��[f��y����)��b$2��S�K<1Vj�A;^)���� �X���fR�p�QDutr)���,��FWt�흴q�*J\�p�+��Z2H�:UO���M�
x��C�e��>�[��(�ԧ����(�� �[�l�_F�<ͦj3"�X�7mI���:��ddW�>�"�ǢbΡ(�6v>�P/�=��f�?��	X2��4��������e�D�6^WTi��O1c��Dܳn���E� �/��	T��Ѣ����S���3c&`9,"}Z��6{s򄽲!���13Pgw��v�����X�>j�I>��f�Z�1O�;U6�z]�P�+��o=��6}юVcT1�+�ǯ�7���A�"Ab׼�@7xܻ�������p���˒��X���a�{W �Xk_$;牰����s���T{]-�gñmC��K��'��'�+!bз%�u�/)�㢽�42��%�w� :E�N/�ٺo���[�*�ſݙ_l��[O9��5w��Dn�n��&�Z*�ɴ��_G�계���Y1��}*d�껸�x
���(fI1Px�Yv�BQ<��,�h.c:�uR�仴΁�q���_(��N(\i��u�Q��Щ�Xߛͺ�⵳{�E�L�f=r��zϕ#ق|6w�x�s�%�Lu����N���K0�d�u���`'g�I��$��}G�`5��Q*;�W��͟�w/J/VXZ���}�  �7���o�!��0����΄ �ugSq�>�.!ˬ+�_%�ɰ����ŧ��f!�ǔa �:�E�y-��?�C4�:�r�f�6�7�K���+��D�y�УAF��7�9�#j�$>���p*�,j����H%��	2c��|����,pz����&�
|�w���WM�JؼA�"�uK�[��2�ZCu�.�15�AlXj�_��������4�����V���4��#Ib�:������Q�/�|�a����i|�uw[����?��f=��@0;�r�BR�
d��Y��\ܞ�y�&�X/%��]_����m��e��g��"n)3sר龀���V2��Fy�%�uVj����$`K�"dM�������| �!��y��i�a�&]u���P5m}m�3��tYu�^���
e5�ˁv�>j�'�٭~E.̪����G��S6z�2^�$d5���{sZ#VP�e�B$UZ�v;Sx��A���/2'�����C(�ɾs�$�'V�f�!��jH��e�E�f��E1�"АuŪ�gß����lOI/
v(оrc1P�v�C�r�ɔ��@zHާa
t�o�5�n�B�]���EY�;����
�"���k�8魧�(D��*pWjɋ�rKf�1�h�����x�h�}.��o �{�`l0���`�&3Wf����{���O��Y���s~2��!�$H���H�8����]:�z� #�~�dj��������fs%�X?�<ڱz�X���%���w&}�m���:��P{f��1���S?�E�;�1�\�,Kɿ3��&E|��5�pK�|\x,˗5:O�����q�]:�́��`<�%�O���E2����8��?+�l�"��:.�����4dOi:0�s�*65����%����c�2���8�f�j�P�����|ǆ��"�ڹ4鯚��E����gH�h��p$��dW�Hh�jB4{���^�y^�1~x	�@�9}��S
鵉H����o�f|���=���>�$�F���=qyF�]/��f-������2�@��ڡ|R*��ql�]gu�kdP-��J!d�z�T���q�o����d1���ʻ�L�'1Q,|�ez��<B �G��,%�.r�����ƣ��b8͂]�7�.l�On�F���s�q�/��\�����*�`�z�3m�]�X��^����8|�_��:�Tm�t��9'��P)��}Z=&��7Cm����R�ȴZ
2�d���%�mǏ6�xI���=�-r�⬗���o��ē���-�����; n��b� Fvv�l���Ld7T{�̩[34��f2��
I�|l����rօIڨ$`A�i��o9D�
�q��䨱�H�v�ө�&�S��'��&'&�l�BG��1����@]9��s�
�N;������^�Y;T�ߌ����|q�`nH{v���J9vo(��ś���taW�fR�SD��$v�Q
B�4LwF��Gro���ݝ�ќJ��1���������jԔ.?2�2�����"o���C#m[� ��Đ�D6�(�j�s�=+��$�%2gf�ȍ��l\6�<D�� ��Э�1�R���ڴ��p�F��p���n����Ț����J�]M�w:���0�VO_��B�5���+�������~M�s�C(�=�E�9�72J8�9���{(9k� C��M*�������o��8�Q�JU"��J��ǎe�#���	��8M��������=�1ƾ�	Z����,�0L��t38F*�-�?�^5db@�W����J~E���c.g�C�7M
�-d��E��^�1����C������5_�Ju�B9��-���	���Ex�����_��3��r"8��h���IZV��u;��RF�O�����f-&�(z�;q��fA"��핌g�GBL3�xKW���R���h�K���p�u�a+��጑��ـ������+0�p�?�>�E�v��Z:;�F��0 ��9L��e��맹�����}�Ţ��yp*�f �0
� ��l�.q���}*t�@�v�06��_P�m�ۜ=X\W���������" �D��*(����9X|ôM��9f���$�l8����`4d�u..����VQ�P�I���*\���nh=$���{l,h�ed���7䋇�'�C}��\zl����.�]��%�^F|j�K���5�>r�v�g��8�R�!㒨i�LǊג
�d�4�H���
6��"��U�nL���ሼ���o_����k>�O+:�U�#Y}$.�@��,W;{tH�����	�=�Fw(���<�+�Y��,J A�V�i!���^Ӧ��?(�{�"Wd�������2D�0%�f�x�"@E͢�9��n���N`��1��^-T���ݖ5&�%�դL1�;y,|d5��=���G�?Vߏ�d��]KP�]F��TQ� �,C{��):�^���Y��yN��Jw %,O(��o7�T���"��T��_�{�t�O�v�$��:�[��W��=~�Y[Wr��&g���?��Ř|4�<�����[��G�#�Xm���2���n�:����S�5:�։j�NEG՜�>1�6Z�z�ةd��_�m�շ"��[o"�'#��QG²�w��.�ޙ0j����;�\�̓��N���G�:����>�)Q��6���������ܦ�֣X��eu7�����^o
��������mQ'�݋��mE��:i��������7�ϣ�oٱ:�`9�4��tk���9�e?��y�]�K�X��� �gKR����?W#���Zs�E�ݭ�cV��Ƒ*��-�ſ�h�|I4>�	��vl�80\�Y!�q~��W`�k�g�6��+���7�p#&�B�8��6Q)�m�Pո���v��
á@s��u u��D'_��`�(ɧm�����sp\42�#�<L��3���nuc�gݐ�6-��Y�U0|���1\�Tmݳu	��ާsF�b�]��O�*T��B���8�(4�*��ś����d�ұ]1?x������p�YAȠ�
F�A�a-�ԓ�o�\�CBz@����@����Lfs���>jx�x��\>���(�D�+['�6�>ʃ�t�`�g�������e�0��M$�sy�P:�p'�D%N�E������aN�5�X�?d�U�r8d�����f����K���x*�����dc$+�u�{m�(<�_��[�O���[��h��b����t�hQJ�����
e�%�9Co!������F0�\`Gd���#!�y��SS����z���'��.X�˱Χ̪ �䏝�|��ܯ���B�78�z�m�Us,���u[sc��
H�
!0�ZIb�J�B3���-u����<�6_���^��*SJH�|��r���d`n�q�I,+méy���R?G��Q���F���x�n�QTi��z<�, U�\�&�{ -��m���z��_�-��{HK���W����9;n�2	���!H����e�	n~6�yk�����]��4�������v��6�˸>t�_
(�������H\o�vg�WlX7�i����%ӶF.��l�w都�480-���ɶ[�<p�YO�J!5����ǎ�;h+��#D;����G^\0��/ŗz�7#�olZ��]���A�8����v������nT���$!��|�����*w�����n�RG�%��*z�+	5-���~[�Gf9� Ȝ����������*Y/��i���	�������*џ�K�|cZ�3$�j��+q��x>�cF
�����zD'����ۻ�;��˥���:���ګ��Mv��_o\T�B�+ Ue�܍-��|�]�=D�>���p
8
Xn�S����u/�H��d�c(���5ut��WQ����/�ZS���� ̳����[�<�x>|P$��Ld梫ȳ%H�L�
�=���]��f�L�-�:2��&8�9�h<�}�}$��Gt��ێ[���Ĥ�3��@`��Z�﫭���X� ܭ�,aEJ�zg��/9\̌��C�k�E^OFжߍ�Y K���6}8��y��S�ݧ�:��9}2���7����.�%.bh�
y�&>\�����l�D�U��7�RC�
5��_^9����&f�<���9�2+��� ��I`�c����	U���-���}N���/]�̙2E'�k�3���0���VT�
����s9/?	;�ތ�n�6	��j��Fw�JE���]ƴe��;Ro1f� =����{x��^�~�*R�fT ����6���G�.b�Բ<�����Hd�>YV�!D��D60�#�/��1������/���_�i`����yX_�+O�h�g��5.R o2��N��pRv��<1yO���츛(��Ŵo;^J�l���E`ס�����r�؆X�E�\��!��;���i���Q�b�{;͘�=I����	)C�~q���!0�2�	關����Ѻ����*���!�
�(^�����>./���Q;DP
�Kûٻ�ݓsh�[�&7��CJ�YE�n�:�/��).����A�F<���+��x������-��a>������*����yp&q��Ѫ�qr�����I��#4!cHc�I� 'ԇ\���,�q;a_�W�S� �?��v�	J�L����m�-�f0�xw��t4-�v�P����"L�����n��T!S�â������n��V��� �u�D^"�rZ� ���L ��k{�	�:�R�-��]v15m���)xc��%��t�E͌�F������I�c��������J����'����?���C{�^q��ڃ
XK`˜>�Uܽ?�5�q<>)���"av���IǢ�vIq0���ۥK~vM�{q	��8�P�v|��vw�aK�n�^B�3Z��FZ���h-Y���Slla-���i�t�5v��xJ���jI������3L
;'BL����� e�_b��������x���u��(����K�cvL�����&��&�5\Jc����z��T\�)��莝g��ª��פd|�ܸ"&�͓M��d�Z���R����g�3i:���ћ*����3�,�qk�}��-�Qgc~X$ƶ��'	<e�B)$]���wLu8�c��{
 PO�%��m�� ��A�	ޚ%�@	���︃̹Ǜx��Vq��vY�"�8g��Aw)$�Z��[�M,��|'���i,�gM�� ����s�(&��I�g�TfZ��6��A���1��Y��
7h$Ul�B0�P�,�^��OPD�b�X���o ����Z�(wjϻ��).������l=�:dc�ϡ���cR����Na�7��&PNc�:R���j��W|I\���Q-v���5�FKԁ�7�T��� <��E6� 3Z��˞��@cʔ6��%1�~�m%ux-��3b_��	�S	�Wp��,|V_�U0�?X` ��a����z��!a�{�{3'�+���� .��.�g��X:;/��\R�/a��$(`O%��U}��>��0��r���&�\@_Ø��
�ӹh6�*Y��$�wg�H�O�n�k��*e�r!�gEW���7�A������\��1�;�1X[�{s�\�0H�f��"�<��,#� ��1�D[d���������np�6�� �b)����M�e=���1��x���1�l�?��H����������j��Z\Ϸ���"a�-`pUҶ�)���Y59��Ǌ��ἅFm7�m�'M�6�ц��l���]���HJ^]`9��/�b�&���A�'ɫT���~{;���Lcj)+�"�����LxB��dy;���N!�t���͕����a�`���Q�v�g
9(n|������e��xܙX
⌏j��41������0e�����R��-Q���(%�Ƃ�!`�"�Հ��J��6.���k@�5]s�8�h�̪l�5�:���Æ�\1�o�U�����L�U0���L���+��f����!?a�J���"o�(4�IR��7D,���$mC���f���B��*3��	)���=�B*u~�YtS*��X�������Y6l�
0��`��Q1�}^5��cQ]T�l;���ʀ���r���s�c/~'y�z[;���e��J.~2��;Gr$�\g�0~��&3(��ӧ(]h*�P�����V�P��TO���:����AO���S���5���$��xV���1��gNP`����C��_`���w�.Х��bW���|��:,M�҅_֍ݠz� ��g�����'	�V`���v���Z���2�H'�)�$u��0=�I�LK°9Y���e��j��Q��m�;ޕ"zJ4���(R�0b�5����g)���&��W�l��1����&(���X�m�<X*�@+~�3�tś�(��Z�Kͭ��V����?��s����� ��c�z�"���Ϣ�#%���$[�瘧���o#E�%�K����bp�[����0��E�������<�5�(����KO�ݚq��R]��(E�������J2!3��G�|��$)�Q��QO]�HJ�A�MȎ����Y�ߐq����U#!����\P��QL�p��\�P��/J�v2_�\$�_0F[�R.�=�x����o7ϻp!�{��s���]Eתdx��B�� �����j��N����0�zYϻ��_��ԟ����d����Sj̞�#@�F{X�n�s�Z��4��=������j�5B,�F����%�w��.r?)zb�r	d�S���e4N�N!�f }B��}Є�m�\%��x!a�s�.��ç���bs�7V {�@����0�MM������ZId&���F�f	�0Y7�y���b���R�KأrO�&)���2z�?�EMH��X�1j7�~�Z�q��<0߀�-P~$�I�%!v��Qų�7J&�{�>���լ�V���$9<��������&�W6����#����ǭU>E޳&X��u���֎E�2#�<���Yp�ɒ���LS_u���`�M��w�����z�X=�|�c���(��.�'^J�hνl�F��Ey^b>b|����n�:���Fz��]TF#RL�n��M�\ɲ�!@��+
��p�]��a	y֡�����j�a��_?�D��Z3�K/'@E�(vh���zا������F��_�l�zXT��I	[�*�2û�]w�\��y�5�l���Bq��a�n^�s�_�����i������t���2����;������-�@Ծ�����nrB�H��w�2����p.8W3l�P���r�\��	?Cɣk�@����2t4J��n�5+w���-�9m�hK}����?��؝e��� h�	��3�Zh����DڧG_��2�g+�fu�3��m�d�]��� �(��`�W����2���{��s��I��냡m�l��E�~Sb���b��O���]��!-B���l��d��������u�c�_�KG��#���Tm�j�mc�q��Ǩp��&4@�\
D�dp����P��!b��j��l2F��\IX�$��Ɖ��3`]���s;w�5~�}i��<~k	C�J+�ʙu�:a.�O�61�^q�Φ�6���nc�鴹x����c5n g�"���bi���+�
�Xq�r`�hS��r����I�O�ԧR�Zc/s,$�p�2hd�7t�d}>F]�(u]o�u�)�NB�������s�=BL��qQ�C7��՗�cUy�W����EѴ�7凾!C�4���L�[j�~��Il���ϡv�A�r��@�|}� �4��/���������T�D�6�m���QgJ���蛎��~�6��ߣȧ
��7-��{4f��ZZ�j��3\㭽�cA�y���d�5��OVT�Z��-x�J�W��J*���psu)�#Y�UF̵��7"|��p��lIE��v�#F+_�<�}�W��/;n�j}�E�i;������h�{�P3�/�.�$����Qi�H:�KO�f�9�&lI�2��-�[�@>̀c	�ో��Ҷ��	�|��2���*�x
��a:7��Z�EǮK����
O~�E�|�r���C<��"[�I�@o�����g?�4��u�����Z� �N�!IX�Ru�w��n&F�VZ��G�3��G�i$$!GhRe���3=t\(zV� �xb HkR�u�.=c�/:��"&��6)��\���k$Ù��A�2���$�Ug�-V���%=S�f�����L����H�&3��H��4"�G�7z/���>��>� ,�~M�a��({�B]�vspVy�xm�uAm`3܂h���?[���H�CO��#���Z/#h�%�!�a�ZX������qN�Y����_�/|Iht�?]���	Xoۻ>!�����+A�q(�n�=U����l.ꚨ/�3������oإ�0̓mN~`���q�Oi�N����o^^���PG�t�v>3zD|_]���L ��[\�.R��c`O���B�In��'��ZsRq[�'��wh�ѯp�dR�n��'��w�/���y���%��s���Oo�6�SCl���\����	��j���̩Lwbc�W%F�(`֐�@d��r`��*�"��H��/_��/���>c��pf�[�py>r��.P�f�'�� ���it����60nt� N5�!�_K���3�<���(ڏy�	�|��¶@`D�"����0��"&�|6��+����~�"�~�@MF9UK	R6�a �'��5���4!���FUTd����5S�-6��I,:�bO0�>xa�C��&�O����--mޙ=�5rsi#���
��iX(zȿ�3��.��ꘀrM���4q氿I˱3�XS{�_���oz�t���_g�l��"��z���@�uR�����S��R=����b�56_�Ԁ�#�2�K�/m����s��,�xB�ƌ�ՆƑ�	��Iɺ�x6v�k���^s��L�~�q��4��R�������A��6ݞM����8w��(�S5�$�2ACꊔo?�P����w�~+������{�r�S����9ؤ@(.����qM�' ���Fh�t��}T8��N�9��Go�x����:w�o�M&CفA�Q�'�j &>�5!@�+kzqQ}������Os�Z��=�Ǆ���w��ں�X��FmIX�I�W����j�D�a��[΢tn�}qS�`���{�(-:���Zhb��F�����s�.w��{�<�׳��$��e�o�z��!��ѝC��cB������2D�&�H���BYƢ��8��LPR�RY};��aC ��({h<��]��YM�
1&�u�\���<�#��嫬��X��q���8<<��s�[V���"��F<���J�b7dd5�q�+�n{0j�x�p�c�桶���{��F���Q�[pZ�{mn��.�tk����AX?�l�(����Ub#ʵ/��jr�\+�fܨT�ˑ<;���"ks�DZ���3hRs�=@xPd�-s���a�ĉ+3���/�[1#�q,ff�c�������g�����.�? 2�wQ�1������cO�r0�!�#�T2lB�|$�5�0���#f2�������FP�R�湳�@�`�n :Ǻ�rs.̣�=�M���� ����F�;���l�\�<���2�#AΩ��S�N�,#�����\���@�a�y�1Jΐ���d����k�d�l+�y>�][n?���ݜMc\�p�X�M����U��j�ئ{8�<&���<Vp�u��Ţ�__t���c�	����,FkuUF���8t��Eu��G�[v�b�Zh�y�R�=�@��8y2umU_D*�{�ie�u_��VD
ov ��KҨJ�pBѬ^[��ƣ�W�V�2��9l;�=#m�j�~��iN�i��J�3�S8�E_v]�w�7k·r��A�`��<�X�W�t�N`�����pG{�a$�4���zD5,�2�f� f3�g�X5��IN{��4}���x
.+,��
dO��mD#@`��B���?�*��^�iU�ւ�Z?����ĵQ$�4{�[֩�x�ײ]�Ǖ����W&�`g�<O�.+�����t���];N�����l�Vv�m�I� ���Lp\r7� �:ӱ#�%"AR     ��hB��} ٶ���Z�e��g�    YZ