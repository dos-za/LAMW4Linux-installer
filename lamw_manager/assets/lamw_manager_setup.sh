#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2949505509"
MD5="1927b64734254138d23151bac4e9c97c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23944"
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
	echo Date of packaging: Mon Dec 13 18:42:21 -03 2021
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
�7zXZ  �ִF !   �X����]E] �}��1Dd]����P�t�D�"ێ�΁G뷳���>��Es�q���,b�8�&ij ��W+��E��A9,��J>����>ί���W;P��?5�RM��_ǆYʠ���@���>�;lê�qg��Ȝ�x,FB[Dmټ�Wh�G�T�}7�2ꐛe���'��]�Ԣ>4�g|R3�8ɬ-TVi���>�nIa�g�\�?�j2�:|P�ꡚ0`�"/�/?�D�Bч�w��?�������v����5󁑄 i`�6,��C��E�ЩGd�x��h��PO�4��T��U���12).�`l���j�Rv��2�AW���[]���ǫz��'�S�
,���/�4�i)e��;`�Lf���w�����I��ְn���Iq���ve��
���]YsH�{�Vm�E�DOi�af#��ti�F(i-������e��PB���ʭ[#���sF��,c!긔f��WW���f�ܩ�X`9tA}�.��fwQݩ���YW��\�=�I���=��$����3����U뙯�6�������e���ŧ��6B� �UjN\��M�.&U��̜��.��|Uo!P�U(�ܾqVd�v�`�����ᇳ���
�Ri���qeCj�Y	���� �Ӂ��U!P�%�
ELVl�"� *k	j��A�����E��H;��D�����<G���P��C��;;�ۓ_+ݧ�;%O���N�ds>	�V=V�fG��fA�3c��������Խl�뫱����"���c�2��:���,�L�ߙ�[z��%�H�f�мW��Y%ߌ'c��&��H$������u3�7�فv�T�i'��n (8([Ď8���d+⠚I�%��f;A�G�eQy� �Ec�a� .��Z���)��S SX	���������gP_u^UӶ��`f��<�e5T�_�W�<��oO	�6��_T�$�6xǘ�?�
��C~Cd�N	j�^�u2���W��{��2���#%�AL�����c�Ey�z7Mk���uLyo���M[�kj�*ǒ��Ŝʕ��F�=;�%��~�����b&��"�}�Ʃ+T���2�F�.�f��|!L��l�x�_��7R-uo՛�|HO�HQ-O%s[i� �V�s�F�)[WA�r�~�ԫΗ3/�:��3��ɼ�}DǶ�?����;��^<l�ۼS�=?6���^e�<�{Og��Ib���X���_o�F6����(�[�G������ݾKeI�aF�2׭�]��#�Z}܊"p�\�?����z�N�h���ސY���:'o�*���;�ܱ�X%�I�쁛���<�	�6�_e&����2�ԡ�qQ�~���rn ��5�<<T�P~!:�̦�36<�:Q$�|��9�H�K7-�]�ES�'+p�Mٷ����N�t	%�?V
Ne�Jd���U�
��;?�b��1Q-pHwG K�~k����x�������.�!2!�P�ɻ�ʅM���^��ó=�u{���*x0{���F/����㺵�z!f�K�6�K��\�&�\�q>��=k�V�����P���$�?��D���s�1�+��x�/M��@'����C�H�s�s������z�U[F1PN��y��l�n������n��b�)p����	�c��+�p�B�����X��8�w���eH��"�.�SA��].��\kpE�����h���%ܨ���,��f�%�6�A[�!fc�e}����P*퐥&��J�y���^��$ZŖĩ��%0�`V55��M��:������QgE#4t�&8 (yr�{�d�֖���������J\!�%@���Y5C�$��@�m�		R�NB!����-K���J�s ���o���ͽ!�X�G�h��@�c@ajɍ%i���V��b�Upʴ�AW��>(��f��(�*��GG���u��p~��]IpKr ���N©/�]}�T�M�=�5y]�mM�ጅ�b�HG�-���: ��R���΂3��bf�W
��s��:?"��,�3:V���Q�2��a��uD���h�'s��4�����R� �3���2�/T����<�ZܕSq1	�n_�}%Ь��ݱ�Y�ɜ�=q��M�ט���#�)��D�>#�*�h"#߭�$;�����p������M&��a�&�H"�a%�/����ϓO��X���~�H��ъ�ܤ�i�����u�|iTk�e�Rq*�Ur��`�I1�����p�Թoa_�R%2��ܙ�_?�2����g |�Wj��lى{�������i킧��n��!5���Io���jx����{t�&ƶ�P��#�P���#]��}������as�� �M�ܻ�j�@�r ��\Q�q�)Cg�Q߇D
�Ң�H���_Z4���j�Q�u����GJ��K!C�p>��\���Bn���k�ߌ��2���eaZȺZgm�����NS�njz������������ס}74T�U�\6�%2��`h�YX�iz2	�'H�z�,=��x ��L��}��.��/���)fGb��~���Q�v�i������#��~t�?vs��'�k?�!���?�r�R�;N�q��eh7��������7L���IG��r����[�Fc&&��gZ
fJ#�H�m�I7�嚉e�����et�(rFA ��s8,?���7ӹ��Z9@����%�Rg��>ʇ�h+u��)pde�?��'�zXyh�qxz���!33�v���.��J۫|	�fׯ~%C�#�`��=�΃�TȰ�.�.��:|��G������rro�N��u�AǄ��|�8��M�E,sS���'��!��Z�ʺv�J�2����N���[�H��^P~Z.�z���v��I�Y����*2'}:����h���.�$�+BYe�+���X�y�%�[�X�02[�®�r����CƠ��ū,x>T���0�WB�[��Iݘ�o0��x�֩�ϫ��r�&�m�ȝN�OR��������*/��8�^�s"�S���Gy�smY�HR���U¿5�{�V_k|��Y��%�*9|]q&�6����2�����ŽX������9��}�kT1��o�ٶ��}�@8Ϻ�sUfvWZ �}�|���5w�p�aL�ϯ�?���-O/�m���D�c���$�^[��>p�#e;�=�,WP�� 8��O��0X��S�tW�Q�q�=>�ߚ�@�N����m���k " ɵQ����LqR������\���E��b������8+͵#�Ls��i�����צ���:��32
#���y�m���b��*V30F��Hg�X�e���G��S��CCd�@G-��]�՞E8{1����n/S��o��{`0-�Ra�	<�;Zr�F_�b)ǀ�e��v�Oj2*׸�丏H�6�1J9];J`�}�֋�w�U���8alh�g�`�[ş�-K��2s��2B��|>G'�0��O�|�$Jz�3 ��2-&��K�;�;��̬ĒhȮ3�pE��vD��c>[;���r����a��v��%~�8K����-������Z���e��ME�)�>e��-���N�g�՘K!���pW��WV��uUh�����Yj2��[ǨVV$`�𴖴4	 Ш�/��֊9X�0S������_
���t(��W�!��`�x}�T�"ˠ���;�^�z^x��TD�)�[�
�a	�Z�Z��k�gd��f�h�����fM�g\���8{�e,�A�#G�c�H~��7>���Y"���+�����
�[�o���qa���l�~�䝧~JtJA���Y����
�SE^����I��J���(7��}�jұ��݇f�O�m�SrZx��gՂ�ēL�Oo�/����3o�����&���Mx�}̕�%�&}���=1��z��ͺ`g��+Quj!�!j	Oh�ꥉ$�h]����ښ&��4��(t>h���k��)����74���L!t���7�׀�C�|�����{�\O'>�S����F������_'φq�t��`MSP3��}�E`�EKV�T�zG�(�J'{K	$ԥl�������>�ܵb���No\���"~F.4{P|z�χ��� q� ��f���yщ��&��n�^| A��!���{Izh@	<�S�{�n,Ť�~���_�gy�°t=��5��7��n8�t9�L5�>�����Lr)N����8ŕ:k��C2ZV���]�waT�˩��Apx�%-Py:Y�X�E������B#ĭ��&�nX�yb���M3ox����1/0�ڼN*΁�/���wE@:�.����'s�~jR�T��k���l�����]��ђ�]7�!k�8=����p��w��	�:��8�;����*[X�,	��Ki��b�[��SG0ߩ7�%GO�*E��t��h����+�c�%�}	���awk�|�B���l��;�,A~A��ԐP��p��\ᠴ�$����{ e�K�`'_��%bfǘN&߬,asGA5ި�K@D�����%˶5�j{u�/r����ܣ�����7c^�#	̧
%�x�w�"�(��f����7�ͮ�[!hNV-���:���'���@}�F=���۷��7|�����/Xm�`ew4�
��I�������YDj��}�e_�tW�NʺO{�i^9��C�5����"��M��o��HdK�0�q�$��t�����!39��UT�r�iW���4��=sL��QeG�p�#)y�`��w���f�k�U�0?k;y(
lP%v�K��T8d/\��o������AL�R�{�Y�0��<b9b�h|^n=�cj�s���aV����oaM��"4-�W��|?Z���a��y���td��p{<����B����J��,���@���l��aUrfxY`�d��7�o�&d*h�E��Uv�i��|���k�E��6\L�4�7���zW���!.z<̟p]���)t$D�y���f��<�x�)�le������lE�(>%�����g;�4�`�:k��~­Q
)���ؒf3v@2�H�
���l*�cC�ܢ!�zRJv��"&8���4���6�i�D�����P	� C��N�����'k���G�S�>q����f,��;��wC�}�*\�H}��G2�[��c�گP�Ue���g�uiDo���{��M��P���18a���P`��t�[*��x�SIʾ��Z�8)l�/��T"�i�:⃏�;��#�ȑ�@"��[���U4ag���F��FH�8�d�������!��!��
 N����^�:��+q�l�c��3��ܧð}	�c|k�%�����΃O\F�op�
�P5���)���V}���s	9-3Kx3饙J+�<�3򧱑��Mҕ��w���1 ����HO�i@w�cn�D�|ag�����4u#��R���A�KfGп�eJ7��:���w�ޜ�}�mk�!K=Ӌ@#�'x��>��<������9��v|��������x	���%W���`��#*�9�հ�%Vj��Q,�d�]0]���R��!4o���1pJ��Z�5 =m2ם�d�����}ѧ�1� Ci�
�f�P1�m���f�lU�Z'}|6�03#ץYm�n$��0�2y��Q!�z�\`T�0?�IV鷂�'��J��|7��]{���Y���ty3���RFo�8�V�`���[%�u�4�	����R��ͩ�g��~ iV�n�T���k@��ő��0���b34��&]��
�S��ǥG���ux4���l7R�f��Ӻ�L96�����>��Gȡ4�[�HU��#2�A�ʧƏv|MR��.xx̎����@�� 	;g��ײ)k}�`���1��TU:��K�� �eM$�~���`3�P�v9�W���-�s�(��X1�%zp�0&P{�#�
J�TR�N�B��*A�!�H�	�M���^]2��ڝ�鱂(�}��������n/#N���]�s�D���W�7aC0���@�u(+^K�K�c���&f='H n�|u_�{��X�86�����'BR���UN�}�5���ʐ/3[g���+���9��ON��m�����h�A���^Y����&�/J�2��^��=f�}cNx�s�Ӥ�U2 4Ԫ��h��CF�P��ÅHar".O��yH��N���<K:�w�?=�l��H����|��;�]{M��nP��o�8 ��5>P n��q��=Fg{�>Z�ٛ��x�|ڞ6S@8hq��2�c/x�4ȜBDΓZ��j9�<x�b����$�h�?��2����'%�;=��[���g2xv�����G�['��M=\��	��v���dg�v�q���5x�,O���{ vѢ*�?�* �c�Od����J��Kg�4`p"dz��$.��(v%�r�l�)N��GSd��u�z�X\�v�Q�pXpU
o�R���?u��Df�8r��Cn"s���T��;t(�/�f�*��J&I&W-�u���7GF�DD@��[��u	E�y��6�}Vu�sk���MM��G���o�4C���I�;A[@f���b�E'����Ơh,#����_?� v���Ȅ�%Nt�~�
LBr�o��8�N�z��
(�+�F#��g^�
��tؾ�ơ�: ��f5>a"_OuY��7N�f�Z*�5�vf`)~���-K�E��)���݁�9���n���S����I9ش�aL��{} �л,n.�L_	�DW�P��#J=�b�K�I�Ϥ��^��U��{�/�|����u���,҆��Z���ae��Kr,�~%�P;!	F�ra����N�����G�1��2'U�����ӵ�R9	�{8���6�����=���+�8�B���
b�Z�k��M3Z�j��_4��oJ���b%�ˈ��L��.qĉʛih�8��K���}�	��R+5I
]���p��-w�U�l.�%�};tn�X��ڤ�x/����ݼ� ۤk�=�VӴP5�A��{�KL�Cg�颮���d�ឋ� i��_���7ee�#K��2�R,X���N�9'12����u�[��!�9}i˺Y?�����[��v:�?7.�8qkmpi.�w��rߝ��f��Ι�L�\���n�����MOA��F��ǡ@�.H��z������9��{�����c���G�^����� ܩ�eBÙ��H5��Y{e�eb-h�N��iAr!8� jx�5�6�c�_�X�5�o0�4y}��ې=� ���B�ЬJܑ�H��G ��	j�y߬��Nu�G��(��Q�L�dX�Zn٤Bo�������
��I��KwԴ�?�����5��E�{����ϐL�T�Q��Jd��#�uP1rC�.b �>�\��/9Ę�L�/c5���y�B��qIXhA�Ogq�ϩnFX�6x�����~ZXab���
	�-=�5�m۹R���m�D��I������o�T�&�b�� ��l�ìW��otW a�lU��#_E��;v:=u1ԽT{krl�b9�����T*a�vtcS(3��6��'%}���*'��Ch�e�"Ƣ�9�,M���x�Ud,�&6����D	|,d��*e�Ҷ'ME������Be��)CEzk9=�;}_�y�� ����<�)�_]1{G�/و�3#qa@�> �#����s��A\�nr�4����&��.�%c�\�s �ϸ�|0��/��zS���&��V�����p:�%�5V|�R<ֲp;�gI?0g1Di�}ќ ��U�c.�u��b��'�M���0 ��ocWCu��>�̴rR�A��udJ�����G� &�粢�\[*D�4Lb� ��Ϝ �J�s$�YyâAC�#��LC�k�WTڟ��Π�Ή�1�����-�8��x�`��/��3^���9"���=	-(�*BL 5��������O~�3���>�?ݥ-���Z���Ц���G]�����u���\�������X�5_�����������̯)K8 ��.$u-Q�\BZ����.��3P+q��Dc$��3�H��V	��!z��g��>�ś���&�e��DٷЭ7l�Z�mVkwUsy��+��3b Α��Ɂ^��X��u+>�0������O	[�����j:�9��7�a�_h�MwÈ���*���9}±�j�"驒��~W���(�*�[��ph���儞������ԁ�T�W6~��Ťu�Ʀ	�K�\tx_�\̠�F�F��5�k��f�T�=K{\ʿڕR�7[�&cu�-@��w��t��L��R57��DT����)�s�;f%�[�P+*d�˭5^�B;�"�Z�A�4kΙ��)c�q��7���q��WIQ}�^�\�d��	1Y*K�mE=�Bv�+��!�<�,w�2дa������8���櫝�!���/{^=Epi�܆[5D ���C�Q2����S7X�aR��g�;�'_��Ill�˥�C4w f�%!f �	ٙ����3���}���r��<j�J�O�0٨����oѶ����<������,���5.��~CJB��V�.�!�}J�	q/���X���r8��+�tq��t�=g�Ǝ��(ҫ�[��/�;;|�;���.�u�o&�	�C�!�{3�E�we��_$�I8έ�r
kb�����n2u�M$�h�]�"Z--]x���jb�B1���	���?NluEϩEL`R�8��!���g���;8t_��A����Q�w��Y(R�)*Da����u�Cz�嘝c��m���I]s�C>����k�L�2�rh8�q)Yf� �%ьـ�$5rg<7;ד���������C��嚢��dG6�U��!	�- �@%���c��A�mRsJ_�'���0�O�� �i���%�_���^ʱ���|,B@_2�:�4^��R+�o<��g6��Rt�@&2��� �nB�#R�X���h��+!����!�@��;�ڬM�D/GC��,b����k�ïu~�?t)X� ~G^�U��r�A=De
j��1s�tC�A"��Ʋl��Ŀ���e�8W��E���$bxp�F��W��m:T\�х�3I�E�8�h�(c�.j���v�^Ҕ�
��lH#Y��`�$������S:���׏#�F�����LdAR4�ŏ39+��"
ws|�{���\⢳2O�5���zG���+��#�F��V��3n�D�W��	mPqGl�B��g��t�D:C�a�^�Ʌ�ؖW�/�A����^��K�.�ʿ_|�b�)�F�^�v�ݷV������G������$2�D9G����g�����5�j&�6&h̓����_�5�u�c�%�X�4��7÷<w;�|[����6�$�� ��9���$MD��0�D��/I�>z���%�� �cV"^
���0H��"?&fp�.�9��߮��� ���LQ0��GXң{��hqj��.G
����yrƁ�3	��e��v�^�IQ�p,�	,*���ޙ!|�V$�q�j#g��x��"�(&wP4%#H�o���Z$�g�c����wm�9��')�ƴ�v��"��{p�Ţp�eTw�K2�~�).t��0���/��c`ozҫ�a�F��S�����Q����vA��q�����L���Jy�`(T��u{E4b�����|cy�Q=��I�����h�ߍ�V^*�B����Ҡ���SZ��l8v̈́�e݉l[�M M�W1.��Q�w���[�Cь�X��������l�ϔ���/SK��b^�*�W�N�8x�$�~=��˱�M��G�z%�c��_��R`p�!��{R
Cd��	�8����Ϡi���x��\H�>��w�A�����U��|ą�:�D�^�f��T\/�>� ��¬@����*�G� 5X;G�	:�O<w�:��^Uu�_uӔ!g��}0"����tc�~!,���
�	�xBW�Kt�J5{�k��a"_���|'�҆��>��E���I�6��7U~��5:�o8�) �{������W+QQ�[���`�p�$R�uc�{�I�]��+Bl�^I��S��{i�����	mMZ�k�ݥ +�%���:P�L�H��6��w��ŭ���뭚����Z���S�i��w�,S|��<�!G{Z�%��U�+�V&`o`-�.��-O��n���z�p�T�E������H̽R��Bkr'`݆P
���ٞL�	u�}�vo��  qO�G�)$������p�R��O�Q
?~5:����GP�C���w5��D 
��/��w���oߧYչ���lea-�bTOQm�zz1x�?S�j6���6�w08&�h)|$D�����}��Gz�}!YX�cU�z���k�t����S�W��z����;lߋ�[����7��L�BR��^X��yn�F��X$���=� ��NE�M��>����(.���)�L<��2Ȫ�s�>�jrW��� Yg��=��M�Y�R;�ڕ�a�w96u��,���_*�SPy�5D|�5�/#�O5WB��Qȩ'�Ȟ:� A�,��Ɏr��
�|t��"ӛ����q��¹�%2�F�
�
���2���s��Gl;�����c���p����$S�c�ɂ�T\�2���ẳ/�ID�˓D�2��ʹ6�ؤ5C/�}�n��{ =��@sѹE֪���Ez����F���zn�1���L(h됥j���% ��gA��fH᱾i	7D5H�J4%�)�^�
|��U}!����P�	�Uw]J�>H8_gRc���46��U��u��ƙ[�<!��Th�&^�&��8�H�Mw��Û�<���h\eļ �M���*�b�b��xP�����t�?Y�D��)H�)6Y��7&^�\��K{N�wi�pĢ�o�ק/cPGNh*���ڊҧ^��j�qN~6")�+�t��I��^�|���{�'�Jm�Y* ���5ҏ��:Dѿfs�2RB����/�NFZ��^�1�tݍ\���٩�7[�vJO�#��6i6�9�JC2��.����z�P�*����zXq�E�Y>��{DJ�\����~ݜ��gz��v�;�����-�]��N�9�V�s�%�'n�4͖&X+�r^�k""�԰��5����NX�C�;��"XP��%1<� R('*F>.e�%���]�G_����h�I��෦s$$��ԱW!���剫G��+]�Ϥ�g���%����c�i�-��`�^c�e��V(�4B�UՔ`�n{��39��J�n"T������7u4}İ��C�^��@n��/~W��"?��^T$�w���k8�Z�mBˍ�p�N�^G�b*vCP3�����@Y�m#��
6!,#h/�"�q��>�	����{��0��#�l]mC'��ڜZc��ڌ%�s����SM�V����L��+�C�>���ׁ<Z�U�������/<)��T���n�5g�Ĩ��j��
lDZX9N�&�Q�՘hmGj�p����r���Ք��qx����)���/�]�H����9��)�ޛ��ԙb��E& y��v}'Ӹ`: �ڤ�&�謽s�x<�>OQ�	�o!UR
4(W�^�+��\f�O�i?V^i����&<���)|�/C�Ǒ�8H��vbv���+�fE7E�,l\Q�P����#�<ŜŹ��Q��'��p:����o�T��R+�k��8o7�KٺB�~��*8���	<7���6��1[�.�r�o�A�qơW3��)��"c�^`Oi\�њ����@���e��󰅁!�o�ۂ-
��{Z�;r_����Y���i鉛�\Km�#�Mʪ�^�N����2�P����)���1}l.U6E��Ϝ���޺6.��rg�F�ڧ���(����3��|MN� |ڹ��ΰ�./�*��6���|V &竕}�_a!V=M-���:�y6�I�
�?|A~~�x��>o�Uc������'D��E=4��T�\�
��f=K,�6�#��m,���V�PAg#s�5ZC+��m�C�A]|�5�����ɼ�3��b��vlF��)�������L�r�MB}o�X8��8�y﨓�ɺ���V��":��\�,�+��z6�w}�W��٩���m�|;]dvϒ�H;0J���>[n2��Qf�FU�����Gv���}�m�4wRN�;�<�[`��q��F�m��X�����N������l�U!�������NEl������T�Xl>����6\��P�貉Ę�+�[�k�M�J[(�87}N��,��meӟ>���2ޅ�@��:���Jn�(�q^��{T)�=�'��J��yU�[���-�-�(��A�h̏:��R.���*j��d7���}¨P*��m>]�o����~K�`d���P�^�W�b�,=����b��]�D�c��׋��Z�7s�덲���]lc:������>�t(Q	u9�w�wZ��+<�[��ҥ�+������(oN>�N�//<�cU��	�n�Aĳꪎ�8���aǂm���qKM�b�P�L�)e��/��䶅
��ߒ~���b���^W~&�����W�VY�(�N�x���P��)Bs��Cy�E�\ꄁ�`d��kz�c�* T�\��(�	׷G���\�C��Ee�҇,}�ar@j�s>�WD�Q.�ǆ�n$��w���SRB*t(J���twD�;n>���f�o��!�<6�W��������o�"���-��.OV��.��mU)߲������q/{O_�Ud�dX��U��so5�U����b���t���֟��]��.�M��^7F&�(�*��<NL�%_D�0��4�2�m�k>���� � U�*������+]Y��3�(�|� �����6��|�ՂO�n��_zHc��o��McA��V*��y�eS���O�ur�għ��� ���T_��79�nT�u�/y�vXY%��dwv������d��Ŝ̙���?�Ĉ읤h�I�Q:/*h.2B�	g�Y��B���Ց�:z:���4 ���e8���8�k����n
��z>hr-�� z� ����9f�%�D|KV�XS�($�/rp*�Gm�����b�ܶ}�}fM���L%��w���TbZ���}��"#��+�@>���r��0t=�Kj�7�)t��NҐ�>M�<�y�ᬻ���j�� fX���J��,z��/�����79��C��P�4�ڗo�G�����/sw�Q��*d�Uވ�_�-M��8{~�Z�8�1�I���ꏻ��љ]̪箯�y�Ӗs�!��ɕQ��E(�jIG\���_�V���������l���>�B�w��<C��ViL�������?��o�k���'�uݰ0%�=p��� ��w�sB����1E_�sZ�*��3I?�"i���eL� ޛ�X~wȽY� G�u������#g�����7�Aw�GOF�Rp�����\�j���FS�Y���˱��}��Fg�I���DWyfu�~ޱ}F�;?��r�ԌL���u_O���Z��@ٜ|[�������.4#W�
���G�[�7QV�7ƍ*���X��@���߃7���/�/��|p���͝M|.)��N�G�^GR���4�9%�C��"����YOO<[-,2߫Zua�U�Uq��h��
�y������e�჎��&?"��(R����l���Pewu�ͺ#�
��u�f��n�	遮�C� �e�bmG�*��E3�#c5,��	e�*^�bh��t�C�y���?}j1��q�L������e����WL^B�{j��_#�A
J�� w��|�Q8kƇ�$f����݋��	��ß�GUv	��^L|�`����zP%��q�?=�T���5�����9j�	�
b*fXP�ke�>t��~�M˖t���� �`=
��9���� �Ҧ��(#Y[%�nA�����L��py
t,Wx�����:i����B���)=�����,7�+$0�������¡J�%��)�X�۲��L_�?��+����BxO�����[����im�T�k�x�"�k��!�Ս3���L���+d��	@���\�?�+���Kݻ����K�ЖS����#S��"��8����)A���9���@B��*RLi�[q�L�8���9H�j.=�̿ޓ���p*�C�OG��ovB����?w��w!� �C��H�"3�/m�ʇ�	�X�0H���ÆFC�\y��
���Js�"�aH�G{�R���W�z��.K[5e��盓n�E��U��۷�6� �>�v��ngb��[%��{�?a;�� �:�.��R�� �b�����2
����D��	�p�̿3:�`j��5�����Ox��t4�1���s�����3�/ʟi��z�?�4QD��ݱ�qw�����Ʈ����)*�5���roO����'�q=�ǜ^'�D�~��O���.=����gb�3����H�����ϕ��)3�$h��D
�|��gxo���O	�tq�h��t��(��ׁ��Z�����p{�>^�̵C���LYHb�V��
�l7�Y�g����qv�:������y����C�2MU��7'��Aa���?�(����BdM�0�5���>�gL����v�����A�4g4X�~�
�EN�@�-TK�ar^����4�b��t����G�E࠽�(&!����9�t�p��1�R����'��&��a��j�K�M!a�ނbj��t;�l�{�H)^��T���bֆ$>>��a�	�$���~�rY���e����)ٿ����zυ`}(HqR0�<1�J�ӠHֽ�?�"0�2��suv�V��5�L�EaPQBϴ?�k���r�U�]�e������|��z�����e��qJYy�l�O�0��A�}n�c+�8}����a��Z�T��|Yt*��������B���!VF�}��$����J��d�%�w�
�99�*/�Ҳ(Kv�_�����!~�"vfV�@��ՙ��c���)��o~�ϫ� ͈D��r͝�$�	�/�},�h�g��Qo��|��U���jZ*�k4Ad`t�j�YZ�	w�V�|je�z��_�g��Ț��[���%vF�H^����'��"�^� :�N�� �����ϊ��~INo�i;C��"X�r�;�R�T��}�t����ϰ;>�p�9>|q�F�<Y��!C�-�!��.5��5�����!�y��aq����I�H��]��+�ut�pχ�H̕�ؤ��}�	�v�d�}�@4�`A4��73LA(p�i錶&�(9��D_3��p�6$>�:	�3)�
�ӊ��I�"u1P�������W�%,���z#�lME�/�S�{�ֿ*]���q�N��,��(~{h����@Dƞ���n2*����B�X" �fg{xA!24KP�j2(�A��rR�9��������l=`�*��oO�6�2Qͨ��А~�AU~���dj_#�� �ų�:�L7G���ɦW}�"��=z�n�h%�s���1�I��{m��g�^zd2���9<������\}jlևPh�1BPw 	!��0���xh@7� ���M�a7�H�Ƅc���ԝ��IN�U�	uX� %�������]nA��8�����F
pvñ�$�|"�\bЩ�0�Z��W) _���,G�S���&#5��T���ͯl�1oj�YjF�I104�q5�zpy.���:�
�Ϊu� 2� ��]h*�9��L^�6���aO&�P��'�;����Y��2�q��ET���MGQL�Eg��AHGI���x�]u!~r�f��zݽ+N�wy�:�/����H����.K�'cV.���w�c�3R� �  ��
��O����f&<����X���/r�f��#��n����
����ʪ�A�gTR�b�_�Q���#���:^{���q�ڍ���I"�s��@��
��ȟ�W�ˁ��!L��w��j�XI06�Ȭ󆼦J�n,�^�E2̭L�oo�lEU�/�����ݿ�(R�il���b�g�6�����[D)�(?����˞���bv)���z��;oGG5����?���|9v�80)t�(_=�@��;>l��Z=k_au�M}������5hvČ��.ȇ5�L!]��,@C8u3��醠�v�F+�ϩ6Z�&
J�G<FP7���9�xƭw.����37a�ܛ��!���u��܅���N[��G�6P��x>�O���fH4���bÈ3��ˎi�d�Iyw(0F�����`�5�?xV�HU�������u�7K�as�g@@�0~�1t'���U�@�RKT��1���<{c�=�I;Ѭ�B�ƨ�q̺I���E�������"���\��;�T�{2�9LQ��U�������87	͹���ذ��S��c.�<	,R��@N�6��O�h_�O�7�[��]$^��V6�}���S�΂�&Ud�Rk�Y���ZI��#~GKO!�� �<�^ŬB���<8qȎ�������E�U�>���8����a��u�� ?��ߤ�eZdޖ/��.+Qn)|�ϣ-������ݣ�;��{췳
�h����0Ōt�ʀl\�y�݈�UΣ�xq�n7��~�TF�:�r��W������p��W�����et�v鷭�ߓ�<�}�-�ך���T
"E���b1�!��=z�+6�=�DR�` >���%����+��w��	Ne��zC�;���B�B9� ���G3g���m��eB���i��%�?̈p���a�X���[�;���%	]�hkН
@��0�4YZ�"�Vz���&�%�+cQ�M�85CWY�Vx��^���w(�=IdS4p�/�H���2\�YN8x7Q��������ң�m� �(<z��Q'e� ��wEi�Ty� '���/P1Y�BBo��j�4|9�ٮ�ه��a��ay=���jP�u��l��rU�"qZ��~�ڴۜ�Q.���V��\o����W��n�5�^y� }[�����6m����XC��M�E��W�K¤̔��x����apr��o��Gz��(��H ՒBS�(�1T�nGHȊ|Ml:�̦��/Wc4�\jJ�bk����SA�o6����\�|�7�6,h��]D	�����~�Z$]�/U㗈�NK���~x���h�;�F>QK�|��oF��\��\wޝB�.�Uњ��%�����0�����G�m�A�.p��~�

�T!�;}���X�!8պD|�l]+�-��b�QDw�M��b:1��;�Ej�[�Jޛ�_���&���!t���=���F���&��p�w�e��r2Ȕ-����5)T�dU;�Ŝ�ja.D*�x��v�ne�C�9a���#���Am�TZ�W��$L��B�U��N?�lT��ZT��{����;�~�k�F��UC��ԹAK�koW#��k_��@�O�5�ҥ�}I8�RN(�nQ+���_:7(���b��a�@Z�АX�AҊѫ�(�א"�g0-U+���C�^�a�o��65		�~��p�E@$&ɑ�l�֗�6���Y<=��!zYu��듸y�N+#˨�\�
��O�f��TK�(�w�/���-y�����>��:��z}��0���Z5�/�GW��x���
TPH�Ln&�/+�]���� ��Soo�]F�AԵe[����)q�trѝ��u�Vb�B���K��F��I��A@,�qW�?������#�J7{_>�,�k��*�F/mE���в����Q�עT�ة	�.��&�9R��W�Cv�V��:c(^KZ�:%�mb���n�})�Zs�W����Qˡu/&m��J�w��(� � ^1i���7��G����v������Q`�񑝏��?�ޙQut�����&�)C�J�S�`���43�����t'��z��!y��2�^7�8֯��˽����C=�íq�8!�*.x%���5�c�#��qƈ7�b冷�h3�U]$q��v?���'�¹<����եs�y��v_]'��#��sh��e��;)�g6��ګu*0��� ��8sxN!��t�]j��-x�/l$��|j�V���H��,�Ő�~ܰ�=�eCM3�f�w�-(f��)?=IEZ��[�D���m.u�J6>�L��黛�㴮f{K.��� S<�>4�̛�N��!-����m�0R��D-�/GgD9�م0�z!��S`�v�S7}�F)
I���~�;�F�2��?}%υ��h�w�{�5e��!�Sa}ߚ�������?�]D�Ws�ڌ_��|ho~C�KCߜ�X3��c B�#���<,��q��j�w���K]�V�zûB�\��O�?�'BA�D_;��xg�z��k�W1���kMN�*�{hVo>eVu�����`I��`L�	�f꺝�D���Ψ�E��0���Ɩ���\#!k{4���uQ9�L��-04mK�1�AY����&÷8��?��u_D�Q��@��ym���7R �U-b����d�5�k�bl��v?�L��ߔ��q���;��¹�T~k ����c�۰.#k�É񍈧��������hT����W�C�$�f>�n��J�2�q˚�ߢO�3��b̟�'䙳�`�z살���j�D:M��j��99��?Wcs��}Dvta����܄�����j6X	h��)���M��Nc6"��U��� J�o�j&@���L�WH�M|Ƒ�����1��DM�0�6O�0���:���w]����pi��"?|���=n�������si[�3%0&�1/zV��=R��]fݢ�N>��W*m�G�T�<@�W�ԝbj�{!�:���w�����c���vW���i����N���|������ss�I���Yf�����u����o��u4~W�4*s&����J�lk��'R�Ν��Xk��qw�FV���O'Ao��L�G�A��8����L�1���^�~n�Z�����A���Dn�<���@�ix/��1:R��w^2Ma��D��Jf@BhU�{�ԫ�-���-�W#67����Ok']��#h�K��j�@:�(�M+(mb[?k?��GB݅���p6����K��Ғ�D���[AX��Rn���M�����/�s�'ü������{����i��A�%:��г1�~�%U�+mU\���#�A�{�� ��+�NF��vf��9�+��b���VGp��el��4���"���ր��+�b�J�Ƀ��[;���oi֠�y��-��X��7��	�{:&#l�ةV��A�F�-�L���W	6����=�4o�F*�ͯx���l�-�,�Q�vp�	�@��؜C�5�Ј�];*2L��TlD��X�'��T��v<H�%��dg;��?�S��Z�TW\=B�Nd2�-�h�� �H�B��E���n&�|?���<��� kϵ*Z�z�m��T�4A�/?�.*�d �*ES�?^�6���a'�EA�:1FNC^?b���r�D�!E�Ŏh�"_��2Ͷ���P�~����ٹ�,�m������?�m��5�~�f*7�'u��$�Kc6rJ��`��= ;n3kO�;\���[x�^ǘ洓��X#�C��v�1"���2~��$����/у�!���z3~]�tn�\F��I��y8�Y���R�UM�蘏]�ɚ�.��̚���I���D�2t��n�d��y �霃ph ����j>YwI Ui�����9i&�-Vi�U��l�o�K�Әb`D��5���	�z�A�AqM9^^�3r �D�8r��힘���7��1k���-y�N�28m�E3z ��Fܨy&�)0�����F����2�\��֙���^?s�hj�h�y��J`%���Y�
,��=�I���ݤ���3OEU��z��S���W��@�:w[�x����c�ҏ�.e���̷�:�C�SB�����*�(���P��l*����R�qw�T_����4��'���6�y]�	������U�9�6g���Z��bEi����\�F�jҜ/�i)An?�~�\i�7���s
�����G��]�-���tL�����<a>AdUG�����7�������=�
�"����-�&��J�J�a�������� �G4�u,,��/!a�~	���;<����pd�m��g�}
��ۇ�I/+jm�k/��3M��*z�JյAE��,�(�%�Q�M"�C,�3���3���FE�.��C�mڴBJ�r�e��=>%�H�]����#�)������}}O\�w],Tq�]���]��:ߤ&t�@7Y,��'N�'�8�"lvTn�� ����)��\3$oS�9�_'�}����a�Xn��u9�Pu��Q��֌0�'��D*Ӏ�}�3�2��O����{b���?e�.K4�lX_�ZK�$\=	 �/]�YT�8R�s�ީAk��*�ʉ�k���i+�Z�3G��98
�� ������d<�.�:�n���Z^||P��W��3Z4.�W)�,X2z��Yr�1.���s#� �S�L�Эp���ߟf��4�Pل���Lid�uȾ���j�&T�S�7�Cp��oC��$l>xF �]^�(��J��O�b�ou��Rw���ԺV�ۂ^S�إB��؋T9@�ջ��Qΐ�w]θ@�E�}Uf YtrM�(�L���C�Z�@�a,gk�*��^�}�/��`se�C���ұ�(mp�����nNF҂�3�Q��[
��A���"H#�z�W�] ��b�Cֈj��T�u�w铃5&��;?�:pM�k�j� �t¥���%_A�;d$6(.=�����}3��M\~��Xd�x�r�!�e,پ���$��JHé�P�gQ�s�v��~e�W��`���dU�,9�2�1��
�n�-��h�\HW���:�f~n�>��͡���P�7��Tԋ�y������Ŕ���
��ְ?sH	��$�aDq��=����fӆ{S�Q�4J��(���RM&����Ru��8^׮���kF��#��%x�ت��F �����\)o�pS>o��Q�|�'t�v�UeIAռ�����4ItDe֮f��M+_���BS�Y���\�	�ϳZl����n�MI�̞v�#�ń�y&L��),p�d%�SK�����~#:Ќ�q1zi� ����q�`o�V�ϸ��~���7AЂ�9i4&�3��kG������?Yb����b�Q��qg"�cEEi"�S��g��)�M�;H**\��s�F�ϳ��2��ez�2�x��As���V�ec�R���"{�Z	!j��`ʕ�:���'�5�G?��x{�	���!`�\�!81畘���k֚it-.�r4��'�ި�y,�{E��GF�M���pەG11��t�-�W]�	ܩ ����� �(v�DS�.DԻӍ���G��VZ��SC$lgv��1���wZ���Ϧ�I:d0)�9�^ŝ�P*�������7��k�[��uW]��֘h���6�k+M�t�K?1�$3��JQ�� 0aoB��_���_���{A�]�	k%S|�"q�ɐA�`� F�v$�%�ݍ��w=�_e�����qYIGc��/M��F��m^�|����w*["�q�\]!�V��(;1�#B��wvn5�Qe�fdu������,F�0#� u�	��������)G�\H�������(,��HNt�`����QE�rT�"�u4Z���O"֣��.�{��H�B��Ե��Ӟ9����ri�z�7���#���-L>6	�	��w��I�0�P�>�e�����o���ڸ'��*+'����yB��CD$`߀���Oa&�1���nô����wc�	"+�1���0=�o���ǉ�|݁�,�ç�v��1#m��R;ƚ���A#��XH�^�J��3g~Zk	@GT��!?����x�p�~��%!�7����$��b�n@��_�rO�9)k��&�~�8�Z��ڂE���)���T��Ort���\�����ȉ;��!���H�j�-�c�����C����v��5��}�P����!���@J�b�6(�'q`�Qf�?�o���$qg��cB7%W��Aq�v7T����}�w	9U���+_2�V�w-z�Z(\�&�~"���,��j?:ߏ�:7��iW�/�k���z&�޿%�Eq�9�`(l�G�)V�\�7��.����� ���OâT��BĊ�~5��d�bh�S�t����Qk�+ �U��<oN���aC$�ʨ��ԫ�h�e3A�K�t��4����nz�(�|���\��GYYl� ��Mq�y�6J��gM���+����)�8J�+C�������� � ��~(����0��?]�3to�vU �'q�?�J�;���.V�B������V�q����x�'�^R=�.	�E]��X,�a+�p!ǀb��(����z�4��:��y��]�dB�z�r�n��˧�|���C�J#J���+��,��M��r�_;t✭Ț!�&�7WV�@�d�5��B6�AƔ����Z��.'��-aJ`����&�*im���)��a�����mЯB����I�����Oq���O4�#���jE����F��Mvu����8�M���yr##�[1j��r�ۖ�/� O�ر=���c�jw����\�¦TI*z��2�:j�sy�]W���@�@��E�*V欖K�6#&��V�WbL�<�ce��dڨ��&�M�����[���߇�T�ND��3��U?��0,�o<oW=>�mB�_�Ŏs�.���ɥ�Z��L4BH�".Zg.����T�E_�uD�˾*�,xQEB���"���X�ʮ~�u�'2� �G��ڶ[=(^�'J�Zn�p�hZз$r�?kW{;�0�J��6YϿz.�j�$5�g��uk���Qb��A�`&�m��#�KCdp #�fp��g����Tf�4�|�(�������cf�Et�{�vN�4Sl���{�ŝSP=?E�$^��Ś�@�$~�Vc�����:���ܒ��.4�KKN˓y�X�Ic�7&��<W�Q.�����|ҝ8�	���_/_��3��kz�D�Vx����~OT`'�,�0(�񭈧�`k�e���l1��g:��� �㜥��ڈ����u�/���[t��g/.j�y
�B���جNO1,.j�������~��<D�[�e���O����e���vm�Sª�f\����O�')�d����3�M�m���:}�6�MQ\K-�$#���+��&�R_((@-J�S���d��&0,/��$p�z�Nk��YgM��ݞ     �
y=��� ���G2-H��g�    YZ