#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1461941396"
MD5="fe8122586b262fad5301779bf912be94"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23740"
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
	echo Date of packaging: Thu Aug  5 14:33:52 -03 2021
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
�7zXZ  �ִF !   �X����\z] �}��1Dd]����P�t�D�辄:���NE�S)���*�����#�z@�#!
���ꄝ"l���c�����JNĿ�+��P�qf��������ߧB��Q�g-T1�(���qiSQ�S�â���Ƈ�6��fwe��dmHfYij�a6BM�K��i�h2��ʆ\��a>H:}�_8D��Ŀ��$�L�@s�ԘhE�m��.���{m����J�sF��m_d?�s�_BN����i�������jP��f�n���Uk�,e�Z����k��F��x��S����N�l"�T7�+��A�#X�}Yl��.�gB���;=1.�<k
�\���������`|���&���6��tqvْ�9����Κ��J�I>>��ۿ}ǐ]ǇP�Up�Eq��Փ�6����
@�?&���F8�<��w���;���ܯ��Ц�,�6q����,S0�����:u�O���u�9k��٪�x4���ú������R�
�1��[1��hU%p*u����}H��֘o=�=�2��2�7��wZ	�5���Bi�$��N*5�O\MƆ6����}�o?�ruT!洁�&��OO�̞,s �%~���=�F}��!O*�ʝVCc�����.��9��7gH�~y��^���(b���;�ǟ7�Wl݂H��x~����0~�C�7�nU�?-�Eۊ����aa�g��q�Ƃܕ��ncP�s�O�<�0�EO�:���Tf[:c��3]���2��7=�x�s��x�W�9������C�;n�U5�:4�B�+ҥ��ݑ7�������8�Mu�4?���zbE	��K���R���kh�U��m��!"�����Ay0ӛ�0ܤ�MD�Qc��'����������A&��,�+h7��b�gs�	 �����ڥ�r:P�B�4����7�P�M��)��k�ݥ ��h��n	�p,�)�6�:52< ��TO�]FC�"� ��[DF<R?uX��_ߐC�b;��id�m�]�����D�7�|���A�h:�6��"����{�o�|�4��,-^zxx�M0��9���}ǊƱ� ���ⴏ���D�����W�*�JL}�Pv�\�?�p��挓�P)Z#a�0~%�X��\[pEև��U��29i@b'wrw(��j��pT���j2�m}������!\P�f�W�+�ɮ��ʷ49Z��!�x���ǚ�y�&j���O0fI<Ul�<FR{��N��֭��2��`��M6E���D�p�o_�c�i���~ig�$c�Vխ��m@C���噆�ť���[��� ��dll3�9��eU{v\]��N��H�����9�n�4�����#+�-�=ӕ��FF�~��B�!~�T]���.'��(�|�,��Gw�#=ɶ�q���$1��F%,���kphΣ�>y�k.�KS˵��)(�i�=�EǚJ�V�?�d�|ȷ��ͽS�_�/+&�#>RC��߾��ҡ��������6�qN�֡�Q����u�UT��Ij��  }Sk~�	�cY�ߣ˥�]~�ι#�JF!���ň$a��k"�T�qkc��<xK	P���y��vP��X"1x`��d��cAj�V+���$��K!%�m��.�g�N#�����a6��`}������kT��{y��>-xK��#��@4;:���i�ۻl�"_���^��F���o;�@��y�7-��z}�7�Pe\:����YٕsG�����K3��^�t�����"�E�pc3���l0?�Ie�x���,�&]��UӋ�*����}��A5{����`��u	c�p���̔���h/�y��9���c8�d�נ�����-R�����^�hUU�%�9ʹ39�c/��4EH��a��~(���Bz��G�Su
''�y`��[��!��f�=s��(����'���=u�	�+����󂥶�b��v�����ə�%x!�|.��	g�֋Rd�6�Fg���*��v�x ���Q�� ������o� FW���*��Y���B�\B�y"?��n��\=�+"�!�~�;@�>P�P1K�R��<&wV׽�_�&�2��ͽ\j�
N�f�K�[����ȟ��g3
(���i-)vG�H��j�?Mt� j�ų�WI�I笞��-e�&��lu3c�M��l� 
Jk �{������ ��L�M�M��;�񫇆�[��l+��*3�k�P�����2�RM(K�/)|x�W�=����2�֊�r�����]��<�,�m!�vА�%�O�$餱�ة�؅`,A�̐f9I��~F
�2��D\!)�$�jdҾW]*QG�L�u�1`l��� 3bh���]��?���
g����E	i�[�����T,��� k�
������	��B���=�rj�1��N�I��f���V�����Kh)52���6�GvV�	�&����s�L�^�` �5#䙼���x�1�Y��7�D�|�0��J�^���0<���FV�,��u^H'�	�w^�'S�\6��rkuE}Y	��&�6<	�W��ڿ:�P'\(R-�T��Um_�
6�X�wfh��Q������&�������P�[�駅pCӺ���2��5Q��6#��(�W�MotkY� ��5Sr�:�b��H�L1;z/���-/NjN"bֆ����L�wZ�q�� 6p֋?���f�>8�D���u]�=�ӟ�3����/I�`���8� ��.�A�����Z�}K]�
CB��c���?~��{ �A#��z�A��ץ�O˲�1澭�ȝB�pz��BE����X�`�öe��#����KW�ܳ��1�yO~��;f�L�|=Po�{>�Χ6�ݫ$0�� �6�q�r5UM�جK3�6�T����>Khiz��Nt�N��Q��f��Э�W�e���Q�/���Kk*$aWF��h~f?�"����>|�V�@=ߌ�Q#4��]Ag~7u�̜eq����p-Ӧ��#�+�v������%�'���O��6� k\AH�D�]Fbۣ���I\W��:D
Ǡ�f[d��i���N�>nz��í)Aغ��B�@�&��Aˇ�K���N������k��uVmㅉ��vEn�@\��5� �q*U˃�]CV� B<m��*<�@7U�,� #Rʚn)6P�.�Yo��}p<��	E���||H�C졓]v�:��+�vY���+�JX�S�?��2����-[�M��g��x/�+Z��!���Sd*D�f@�*Lrj���/�gR�>MlIG�Z�*��>}-��y~*?����@pc�t����*ʪS���)�n�~�_���]j{�BY�@�rh����A�5�)z;j�����t3��luN_EW��-��n�X :����L�:�=�]=��
W����>%i�yb�����ۖh��+/GQ0R��@Y��~���i�S+�( ���*Z�o2�nD��.�@����kK�S�\�|�RI愹3�^��LG���s�=�C�1���u���wt�#FD3��4��2�����C�v�����D�k4cm�q�=��M����o������s�F%䥂Ԭda���0TPɖ�����GiQ��dkn�9Cn+�� o�Hgt��_ri�IgqD�z�7/<J���ԝf���h�!G)0c��
0�vZ*Q5�E;,�`�l)�T_j׾�������I�?�
�4�8%R��ؿ��+��C���2�����H@C��vX}	vnZ��&E`r�}�L�y/`�>}.�j1sS�$���1l���/OW`&�Z�%W�9�&m@�(��y���^�0��u}Q���uu�ciq�l�����l�ZɈb�S*'�Wtu	c�cc-�GC4����N��֌�FfN����	.z!c6���c�$�}��:�����5D�~ Pޛ-�C��&�C�z���2�gR�~�}R,��P�z]��J�uذ��:�F�����}*�W�ǳJj� 9K���0o�~ e�ch�e�������VܖAX>��A����6��x��������E�8ClG�.^P��x_�C)v��ݗX��P~_[��rH�m�ΣJ>�~&�L������`{l�J��M^H�9 lB�����B�8"��2�p�W9�tAK�p�2=�*Y���%K�����*�:���a:�vҀv�9.�/i�!t8o��������0 ��+E���6Qw����s$�v��T�۰K�tLI�%����9�6�Do�ra��c����v��e�=��V��_�=]A��ӎ06��975cM-����
�x����`Zʽ�J�H���I���b5����7�m1ޤ���R����b"��^&5gT��ձ����._����k�x�U5�?�|��*���q����{�CX��禗H]e���xN�VGi�O4S�l�!�㭈�#҈��vg�n�����~��h�`�J���rZO�fU��^-��P�YJP�(p����j�VI	1G]��3���@&�kk�I< �>r��Mz�=dU�H�� !�5	-�z�U˰�����uң7r�*��6�:P��E��M첻��4���`X���WU�Ug��i?�C;K�䑷O�F�B�p��}�~�:$\����f��ؙD��0c;=@|H���T�uxq�xe���#4"s���L��k۴;���]P�n�&1x!���*%!�V
Ee�0����̬Zk�t��@oJ@B��������	c�;K�mpS/��؄�_8Q��K��G�#m�R(36ru@�\Eh`B���kw��~'ḙ��Fe�	���`L�<"H�[�7l�H9.�/�=�k���mx�J��F{G�'Y'�+l���G6N]�`k};˿QPg��8Ex�Ӣ�+���a:�L`���yvo���t�����7M�>
�_0y�}`ֽ��D;����T���k��G�#�[?���]�qY  .X��_�Swh�e@Z&h�'�(y3�3ְeEwOϜQL��*�1h�QV2i�gm�4 cm�Ai�}�p�� R���8�����[V�Y��׆�8��2`����m>[AcqU�j� ���|���	�쇒]��)K����vSt��+S�Nx���T��|&G�ÅD�p]����� J�-�ըҼ����sO�NK��.Cc� Ղٙ�޼EnC�E�ho��>Dܞ�8r��<G*�Wl[$¤�D�S����өSJ}}=�t���(	��x��@��/	^�;�;���B#����+��Y𕼱�w��K�	�ί�Y:X�KB�����JƓ�2���ڸ@U���׼m�3�K���4�~}�񆢸8�9vT����E�"TA�f=0DUU�։�i��B)}�/q�[ǁ�ѧ���и�it"�dr��q�k�3�6�_��*��C��ZLa��b`�kɸt>z�.�MzD��B�B�Sqh��;�_���
RĎ-�z[|����P����3C�t7;���*�ki��<x�ᜋ���,���ĐS%�M�(%V�В��ρQ��I4���`��,�AR�-��y���H�9�R^�ddJQ��*�s��	w�� ������@����(��Y(����������=�Z�E�|S�E��wGE�g�l-�ۍ���i�U�tJ֨�ң��S|K�*��2��s;2;�
�ߏ׉��D����3\=0f�w+;`�q)�|���Y�6L��Tq"���-6t��ɯ
�8(�a3�Y:mZ-~163k�E�8M.W!��&�?�!x�߅�Dۤ��I�j��������#�F dm���3�T�`����a��8&��O�1,�i<�z�����)��0Q�}A���̸���*��<������`X[¹|g���1�K_E��ۖ���B�& >��!K���/�|�g�dL`ҕ�\0�`���Rj���CK��p�_w�^z��#n � 6Sӆ����z�$���~��X.I�Ӗ���Ae���h�˾�3�vc�ʭ��C�đ#���d����G �r���޺�z�À�f`f</�8J���`3�}	P?;���L���X����м֝೤�o%	��]kk��X+7帤�m1��v�/�H�F|:>��'$�2�G��l��mݘ�04�!�c�]�Q^��ᱬ��m)��ctq��=Q���'كԠ�ԑ�t#�t:���v5�Vt�U��G�a�Zɼ�*�3��{#w8T����z�oF�dq�jIk�i�e3;�G`A����W���=�N�aݤ�{lT�hBb|Mԉ�o��1���D#�he�"��t����x_Y�=���!q��40�3��jo�ɨ�Z>�T.��?�=�:-SR�:�!�Qƾ�+[F�3����:9���T�w��1���P�9q�Y1�K\ΐCN����^,ր���3�k�'���M;���n�9N��F��"�s�~U�um}d@�Y�oS�@��[ٖ:�7h�Hcz�v��L2��u�K�Nq�ݯC�B-%݋N&�����\�;��&F=�x�7��I@H���.��VY����k���hk`0�^���幭���� ����`����7��fXp(�ɤ+4M/�k:2:Ԓ���0��M��v:�e�q9�K�6!�y%�}\S�c\�?p��UM�4\�$�'s�QlC�`ސn�?G^�'�H����U��}d@����ι����k���V��W�&v�K�p��m��*§��s�8�ٮ֜���R�ʌ�koV$�.��˄�~U����ur�CjW��MY�St����J췬��yH�ݮ#:?�e2���'��gw�i�)�����C�1��ҫR��;-=�u����UI���WIQ"��^�CR�Y�ǣ�=#�я��ٲx@�멕�#��U�D�+�8qa-�c�C:{bn+	������L?�ɩ9�b���.��� V &ा�8���7У��s�M��n���dD܊޲�5�dK�:R]c=^v^��D�]�_�yW]Ӗn㼱&��fظL�Ǟ��'��p���Q�y���-i��p?�]�M<6�s�5���cL}��B� l=l����6��ɨ(Ԩ�Z�2X6�GU�����3g��c�k?wO�x�J�ȋr��I�yhKu������:$	�3�&��>6���p�� E�>�x��;9b��M}h�n���)������
S�xa%�|���IWϣ����G}�aĬ~���pzp��`��rtu�\�c�X�xW�q+�'�����6��Q���,�U�y'�c�P1A�8R��_u���#�r��S����O$%=��/f�`�������)��<[:��s�%$ᗵ�}�[��w'%>�L�P�������o��q��jp�L4l#��m'����e��5)���O�n�$�iBPD<pu�~Y��*��%�$��:�0�hLh����|�	ϗ8��h��R����]����^�݈+ b,�d ����PR��uel����zZ�=)�]'~dA�D��Q<���Ϣw2�Ĕ��+/�S8v�v��y)?V�}��u��c)`��i"We�t�y#f\IMr�����v�(XX�3e{��A/E%;p�jɄe�?�����gS�#?b)"�s qB1�1l͟o������ѬF�-T+��^�v%5�{ϵ�ꏦ#3���lN[9�@�&p"W;�vN�?�&o��~�
,���6�c^K�	Lt.K������7{*k|Z �Ô3��.Z�4�E�*�u�0�O���z1�Y�BX��i�7`'�L�5��M
̀� �����*@��ǎ�ܧ�I8�j}��e?Gg=��7G�;I�e����^����j�)Z�sڗ����e�C������[6��-��8�[��S�2ڏK��B�R�NO�����O�0�� U�2�V�B��{���O=�m�ס�!�:-���"�%��a�?�I��ő�jQ�]��;3R7�7�[@%���LR�_�)\��@�Þ���G�
;���A/�b/����n�ǹ�e"~�ja|]L�r��3���6��NT&��K�h�i�#}��3�Ag�\1�v0�����}��h'7En^��l���Z<7�]���h�R��%�Tz��a�b�xne�(�`�pla{���/���g�o�f-�������m	���Q�`G����A�ʆ��9�.*yr��N��Rb����n*��	�ߪ�v[�S�I麿�/(�RhE�͑Z' !��c�`�$�y�{Mx_\�I�9��[���f0����Jw�D/���·�ŵ�p1	�����7`�˄�'� w`4E�ƋǇ;S/���}�C�tP�y�x�*؏6b�l#��+���T������զ�NO�[ݙ�a����΢�
1\��{"A��J*��k.�J�D ���SOV��X�C�I�Ȋ̢6I�.6��1����LgOe�S�P^b����۠�Ia �!���/`�����a�p.CR<
��حNxУ�u;��4l?�	����l�:��\��jP�F(��L,C���5����ZxN��e��`Px����o,l�g85V�.��B�qح��h�0/����t���&�F󊫙���&Υ�5A'.V�U�!��Ǘ�
|�\D�3_�g�$��J���2/�D:(�G�����Q_�C��PEA�5�s��]����m�=������ɻ$P����Q/��Յ��b�#�������F��i�T6��˜�@,`�Ď�_6D�{�G�+��!�촸�C��c��ĳ6�9���U����u�Xes]$����%0Ӧ�޸�g�8�5���$�l��Jo��h5=5�)��c�$� 98��A�p?I�A��J ���!�4 ��P�����E�l��z.0N����V[;�;�$G?s�^b^��7�b*����Y1�k-�M@�q�����" ��U���>�+Ȝ}} %��2����jnue�y:�e$��2�Ur5y`{���Rp������;�?�
h���^+׫��p%z6]� p��>:YpZK#�?����M�&祵����Le!丧�:�fdf<ߣ�nIu��ɦs� i�T �Kd-6�"L�c>�rf�_gL5L���LW�~~�,pZ�HY�¹�1?6o�A�Ч�W3g���\����t�^�U�^Y<�*�Iss������e�zDR>�L��ߎĤ���ㆲߦ�y�Mw��­�P�ߏ�?�hW&�įeg �����Q�,_����E�'��3l%������?�J�cJ���
�5k�dS�2Y�2-\���L;�a�IaF"��E3�������[r]J�R�~mK���!zK�E��%m7T3z�Y|"���:�{���(�Zc�"�-7���w�d-�QB�C�Nw�0\�JB������^N��s�H¯#��Y�;ǡo.����a<�1f��0;�ɦ�_���E����+��N�*��7�9�����p[�Gw	�7%;:(@ɧ�$�"��ALJ8�Eb@8kG�R&{������,�&c]%Ȭ��s0�7�ˈ Zܣ^B=ҹe�����[��S+^"�+��2�5M����h{��$�?��(U� ���W��hx_��� �����]���R���JZ76�p��?y���<{��e8Gͷ(W"�rx9�Nv�t�9�ƙk�ǕC���W��K�.��w���;w��3����<,�J�O	iGj����j���sab��� �4��@o8���$3�s�t�z�
���PU���M,)���K�}\��/��jlP��}��8)j�n� ��G9F�S2AX�/c�
O���+'>�џ��B�q��vZ��9��)��5S?u���� P��|��晆���:݌�b�?���Ze�;��]\�E3TZ���2��&��͒�~K�yb�#L�Y�W���r��6R�����Z_}F�'I`�}�Ȏ�K�mFo����A��y�����Q�*�k�z��RÎB35G������f���A~�D�WC�X�/v(�'�O��ыɏ��w.i�un8jߠ�,�݋�+$ܒ����;�Z��نKY��P[7��f�lO���P��6�j���<fN� Z/�?=m��}^�����WK7j���x��zdjȳ�p���п�<�M�t�d���4�}�_S�9^�@y��P�՘o�
�y�P*ݵ�V_��;Ѧ��߶��qy_�i��b%���O��$z��/ֶ�K�����a���ύB:���������z5�*6X��H�|U�_���/���ݥJ+g��u��W-cU�����#����E���?�@4=�H�<_���q����l�}L{����Y�.zm�<��u�|;82�����࣫_�i�s���#�Wx�3�h؊�fږױ6^9�"z]�/i��%���~.�\�
e�=ƓW�OGK�T�������\8��ǀ=0X��/ļ�� 
�%is��r�D�n�q�P�k:���5X
wЅ
P-��=�EΟO���IJ���ہE?	^f��\N����.����ĵF���)�n��zx�ƣ�Q�g��x�	f	ך8 ��#�z�(�۵6�i��m�c)
H%�Is�ͱ7)�Ǜ#}[�M�\��n�����;�<b���p0k��6��x���!�����,���c�H�F<z�'絆���y��
ZT����p�X`9"��_.�^�`�Q�͔�V�8�?���h踹rl����.\U
��l��i�ٿ��|y��J��6;8a��W�,W��Q*�b�V��;���W�!��R�H%��u>�@K5E��/ʫ&Ef�&��?�[��(�H̱4��� ��HL� �FXo�m݉T��ڞdd4@�ù�LY��(�M�rY��(=��&8q�(P��}*���R�^�H���!F�����W�|4�p# �(�����q�+x�������)W8�oi��ԩ�-�0�&E��"��!��%F�R�i���ü�X�ܑ���{
03�;f1y(N��:r�O���9��6]��uv�M�=��o��ҨE���_6��ݪ��G9kfRl�8zIIAG�3&P䭀,�k9+ۂ�j�|v��������W?]���v�ĝ����	)��Ι��2�=����w��.��e�끔�h����S����O��t�?��+L�����^�k|EGQ����ˉ^R�xS�o�
��Ż,�/j�ZC�XZĞ��X�8Sd��d2��UM�9^j���K��5��C��u�@v_�J�F���"Χ����L���n�z��&a��i��=�"˦5K\&� W���L,��mgQ�q�|5�[`Y]vv�<%��B�?RרtEd��Y��un]���oХ���*�Ϣ]E��.��h�J$��g�dR�0g� �Mm y�w3Z{�`�H���L�M"��^HW�o�(W���������#�% (���c{>��V�?萯�pzg�5NNn/N����4�#�C6nE!�l��B�DJ]x�MN��F�F�Cq��><�þ�0������O���\J=^Ws���&�ɉQ�K�pI��-�dM2��Vws���y��y�F-��He�9��@~�ʜY�= �K�ڈzm�"��T(Rn�K�k�����N2#� ���,�^J<f�؛��;����w`|��N���E��Ȟ�T�%��
�{~�)֯�"Z1�d����L��*Y����N�����UGj��fD�>�Q�TsR`����;���ޮ�C:�i�@�0�$�8�6�п�����4 ��_0Bk��|�/���nU0`��3 _2��ք�>+��7C�6WFD'ow=���mխ(�Rv��Eil�Y�@�2d�#L)�N��K�������W�{{Ek\8��a�m�-����@��rҗY߼���H�iy�}��O*T�=���㔉�G�a��k�\4�Ec|n@w�y@��M��븄Cp�4����"�">�����x�o�|bf��q�u��p�[�iN�kz;(���8��2�����z��(nNS��R*!J�qV�L�J@�L�br��G�����L5�w�!M��yc5���tr���3��g�y��Ar�k�Q��ofT�l@�r�B��W��[up�S�y�4�`�1"�U�/~�o��=F񫜆�XQ�r�B3y?E��	�̤px���  o���5ԩK��#9��R��5��j5�&K��sBL9'�ژ�L�&�rx���5�L�?�kl�ցuq�L}򥊯b�Y�Y!�(m?믌�1�<��#�3-��1�t�pO��"��K׍�/F����]�Z~�ޗ�\��\=�E���6EۻK��ӎq������h�S�gPt������9gs�|������61[�����]�f=�rC��dhۿlU�s$�Oo�&A�\�]�@v��|ʇl{�(/�}B�s�u[�U7bp�cA1 �G���j�����S��LŢ�[a0�Hr�S�X^�=Q��>{�_Y�QI���B_��?$^�x��{�iI$��?�{Ȅ��H�H��sU�d��O6G*>���6��c�#�B�>D,�t�&�L����E�$jc&�K�x/�D1i���Vfb�A�3�u#�;�s��+�a� �vGqх����o���q@�Y�$B��9ݻ�|[���k�b�J� ��kѽK�6�Bf�C�5��
����.]7������XS����wMm�� �z{?�Q+����MK��V]�GP0��F,�-���S�dB���M�n��xA��^S8�}��e�����>jE�9 O��	�9�!���U5E�fz��Qܽ(Y"�:����=���ܸ��Ǡop�'���+f�BՕ�0m)�C�;�kz �� �CǻY�ֺ����:��H�p���W�)�SL�,B,�}����!\���5�e�M�겮rD�q���kn�\e+�~�P
�'$��H[U^���W0O��>0��=�d���X&l��j%�w>kJ���M������0?�>�g�Q*j��|k0�q֠���=�����wܥ�w +��xu��do0��T-�0������6=�

�&�O�ъɢ�<�Y{~ҫ�R��{Es�9�ؐ���K#b�ݚ�BV�I�J�]d��i_F9]'`h���a�=��'!���x�=�2ۙL��'-��Mg�Xr���Jv���H������ҋ1�7h+���Ι��Ôk�&h�Jy2\��ʏ9�2q��G��I�U�`\2"zB&3��C>��G����~��M�	�e����T���Z�W�p39�?��%���{�ki���~��璚Ű� �f���"�$��u>2�M�]&��#r	�����A[N�:�2��}�S0@0�Iz� �%�(^�����.B�Q���r�(H\2�bИ���.w�!~��o��y��+%�x0�ɯI�K��	>���]fkx:�E}U?g6��z����By���{�+��g�ˆ�ԇ�l��ee��'l�d�
l��~�b�����J�qB�s������H�ʐ5�֥�
܉׼C�t�c�3����.w�I��AOI���_�g��M�庐�Pm�Z>`��P�j/@��z��f�w�ۅQ(ބW!��A��(%��<·$�c2���o�G���Jwp���'��q����f�5��lz�W��]��A3�*r��U�����`��
O�X���X�S�ؚ�ڭ^wA�cD�[����e��[	�������Cג�_�tb���;bp��}�n���<�U�?�" )��,��r'йXͰ5;���:ƿ�ۉ�_O�V�1	���)*1�2� �	}�U�[&���靃�b/��g�M��p�AZ���śf�7+Uy�)�)'����]�y�oTJ��
oN�q�S�ZF��o��zݷkr 2V}��Y�Ta��g����]���/�&���v׃��R��%�:��d��g�������Yα�^���r;�y���`�y>^2�WT �J�l%��,PM��j�w��e�����}+j� ��P� �%���&�VJY��J�T̀���wl3u�[�������'E���{�œ޽[�M���>+E���irZ�ƨ���9�J�/6������0��7���Y?�\�t��v�E[�2�#���#���'��z�xh��)8l j���$��GT�/���N�����I��7�\��a�3	i��[�)�q-+�%,Bv��7W�	��<dC~%�7�+�s���۶��:O��ϯ'U�b���yt3d��׆:�`�8�}�u_|�,�5t�g`�����4%Q�
�[nPԎ��L�����j��ǳ��G�,��y~�~#
�\Yh����.����{j�ͥ�j�)[Ӧ9%���3��{W�\,��Zgu��ڑ��2$R�>,��z�+�\�Sz���-�u)���Y& �^�ؚ�'���C�^��������7�����f��XYH4�V�oo@Hx��>'�1ى�ȧL%
DUz�y���m��`��HG67�F=kQ8xP�w��V����L�,������w	Á��u<I���d�{�](�������
 ^q1��:�G?�Gg�p����D9hs��Xe/M#�1�V��u��F ����3�υ]U K�uD	�����b�I�>�9�#��P �f�9~�Fi����?3����Yw���S�M��N��!��AVmz�C4��Ŗ)����r�@]B~{,�m�hq����)U"�}j˖����Af�Q�>��
%H�ч�ٚ�LK���{|.�ǅ
QM�I��G"�������Q�cx��h���M�����������ۃ�
}��S���_%d�zb����O���]��Gɺ���Y����9�N��A���������A���l\���u��LmO����rʷ!�cq�8���S�8��y�5�Ea���yZ�i�3���le �Vy[�&c�U����K{��ՍU��H��'g�D����a���\yb��/��u��W��Hy4+oۿS�F�R�}����Ħ�+�bds�W"@E&�L̦^�gP��ɒ	�0����3��[�%OWګ,���5�<A��7o'���л�-�N+]�C%T��$��2��D�>2�b�܊��՞V�c�г�}
�o�6t��	�o��n|���3���+�e�5-h�p�^�KF��Ɵ$��v�U߸�$����Gi3�������a-ķ����e?�B������g��C�� ���F�Fo�=��i6o�:��9��ڰ�2LQ�M��+k7���FO����Pof\M�B�z�mk��!�Ta�pb��SL���9�$�X8?�"F�m&H���Yh�l|� �n���|q{[=���wL�׷����{}��F�?c׹��3��]�K)z4����Vi"9O�TqGl�p��P�?���egxU[b��F�����!�N��d���xQ��+~��yX��c�-���P�����t�����Ǒ�b�,)���jIUJi�c�N���Զ_�2�~�Af��W�L]2g7����}$c��a)"����,P1W�.P�W_[a���R�����-� 6�_혯a���o�C=���j�D�.����楻G{��xS�&�;B�c�pSJ�xk�r�,dfz3��j|'�q���8�	a�,v"��\.��1Bt��W�FM��`_��sdÙܞ���!�xL���/�M2�%���w�%t5�l��;aU5��ܒ���k3�2���n�8�Q�k��;Q>��t3	�x��q#�tXRVDu^9������p��n�a��Y%�;�3">ڻ�r�K��k�~��t�P���}U= ��GC)D�����K�W��l�RH6_3����~����nC>VJ����O�yg�	�~�H�(Z<�����Ę�q���o`!��*�x ? , ��X/���g�_��������>ƚ�s�Z�w"�l.�2<̚*�\Z,=d�R�$�*�l�Щ�+�uF���x�@���,�����=Fn9���;;��G=4��U��{�S�Rz=�h
$��m�����#��~sj��g[���J����y�K6G��,O��n���x3�n��g	p5=�Rm��j����
�[�HH�i
aҧ�핏�_�|�μ��Y��cW&��zk<��9�	o{PA��Ff�p"13C�;�� ���#�1h�\��s�i?�i"u�#���]���v���2��\�≣��i�j�'�r��%'��J���)����F.��b�RD�5� �8�2?s?SʝY��u��cC.�|���9af���xzWձ�: ;����k�m�gtD˟m���7�mxq�.RGXʈ� @��z�>c�W�w����lpR��f����c�o��:duȘJ���Ԉ�A����F�Z�	?p}��d�+���O�h����s�4�s1o��l{���\��f��yH�B��\��x��6�$��YY<��}īo�;.8��_(ǐ��@A��`���PF���}h��p�4f�٤�g�����뢈?4x��Ø�6 0��7��Þ?4�Dw��o2@��s,���pY���<���	%\ߖ�������C��V�/
�dx����9h��q��R�]�8�mP� b�֑�Qa���P�A@u@k�e�%��B%!�xU��T���N��"����c��ⴢ�E� ���R�A�"�]YЫx�%�� �E&z1���ǁ#�+X�A���3��������E���CLc��a#KљG��p�0����G���*�=��[y�/�Z���R:��������K8-����ɂ����dyY���<�+~�lN�ݤ/~v��
M"ΕE�ʌ�i-��h�amq=o�0�� [^���
{�w#z.G�
eڊ�-qE��8
��vx�2�")�OL8��F�Yz�+�ܕ�ݏ�
p ��(�] �i
��tb��4Եc�p�|(ұ�bҠ-dOY�n���5Z��EMk[�d�t����E�%0�a�ۑ"\-�c��לFq��4�0Y���=K�W��t��ΗX�6�@�u:�p��\=����G���=O�����ؖ�8M����'���W�l\W&y����K��q�@���Z�Ք�N ���r��ST�b'�g�Mv��fL.7��ܞ�a���+��2H>�w�<[�'q�Lb�D�!�\�N�hR��V���{ж{Z�� y�a���P�ګB��γ�g�B�~+S!�c4���=F�Q���C��#t�>���Ο)�a��*MQ�ǲ���=�t�*E���6��]�+�*���gB�ƿ������`��-,߁�g6��I>���JX�{�ݣZ�/7��9������JLi��[��ޗ�Bte	@�������"����
~1o�J�4�[%��E�W�Ѥ�2^Sq�+�\!���[�8:�L}�A�U?���Z��i�Z�o�m7�-��v����J=��i��r����0�R^�R��� �CR^�ԧ��bP�A4"H��P��J�D�y�-w�=�,_�f��������1P��2��H�͏�,U�<���v�CH�:X��'��)���0��<E���B4�VRA���TN֗��[U�y�ծ�;j{��z�:zk��W�ud�����J�e×�!�#z���e!Ĺ������pr݀iWx�Ib�S���ɫ^���n�؅Қ��V�N�Z)v�f�{S��o�'�|��jSD�¥B�(%g�u�8�Opm{<L�<�0;�p/:̍Om����o�����iB��:֦�m~��8����w���8,7S�R���@�mSJV�5޲`�`@��]^�Q��jz��3zb�T1+x<�5V8��	���&��Ύ����Z\.T"@����t ���2��cpb`�f�[�&�����0�S_8�+i{��AI�mw�g�qjT�}�%�Rqt��:�Y�g�&JO�~%6��Ǖ$�v��/K��M+no�k�h*��?0�!2�o�D����T]��,Wc[��I���@^ן?�'=`X步?��|\�̈́���N>Ə�ꟐL�@�(�E�RI2?��������(���ڸ�HO�����f��C����@�S?5��~��-q�e���HiވQbCq`�S���>R���F�դt�ӻD��y�C��6| ��o'b�gM�ET�Ex�Q�l9Q���AaҝD�Y�b���ږP���J?M�<��x1T�-�-;2j2IbQ�ٛ�^Zw�u�MѬ2�4�qҿ�7[��]��,��3K�ɺ�\�_�f��`A=B���o߲ɹ7�cl8�b�K�ã�f�4N9�9Ȝ�|������U��i⥔d\�!���7�@g)�Wnx�K`YO�8]�s�#/DBfzx��;JFL�񩌧]�_��촔��T�,�.��3+�P#�u�о����Y��q��<m�"�;7���5u .�j�xr�4��^{����;��\
���	ij<�Ty�=S�
2��7m�����aIK[��'��,>	��i�&n��L2E#1�!��Բ�:(O��ڑe�aO=!�o^�r���s��m���/��	�,8b�X�t[��[��psU �1D��*�	0�A�F�.Y��|�`k���QeN�co����8�%��8�����1�ku�~�	�q.�}$�h%y1P�S�E � �M���Tr�4hN4�ˈĜk�/���'��svs�
�@D�L� ���������|��)�4��:�^�zbܔOW1�:�J鯙�:���0��`wpF8��e�'�7��٢Ծ.M�50X�zA���.<s8y�M��K��v���j��R�϶3��*=�l�����J�+��zƑ*@KhE�C�]'����fA� �LIc�����@�`�k�`71JVn�J�A���*��f��T�Lx�,n=#\�i�<���c%ik����҉b�����n�/�_��7r2<���a��.td�Nz�T�*��8�~�~ܗ����mm�Vs���#q��֛w��'G(�{{H�1'e�d�G��\ߘ��3��K9���՚a���"��@(�]������~{��^+�NP����a�_�J;�^=w�g8am���~,Z��)�1�~��vB<����{�>��6XK�g��C]ka�Al�Mv��\��.Q.���ߎ��͆���?�1k-�����˰*]���	�����r�z0a��}K����lDV���A��� �2	Fz��zo|�O�+б1v�*%%�*�w�`�F�P�q���?�Ω��]�2o���fO����G���[gE���u�dm�zb�^,_o�a�\�BDT�b�$N��5�~�³���
5�Ľ|����^�u,�����>*N7�����>�0��I��q��$�6޿Gg�*�+"�oh<��]vAN��',GC��`�l�����7�2���z�
պz7۴��-�q�^�*�)�(�_ӱ�]�ȋ�h�+�B�+�R|�� 
�2�l@@F�^�I�19��'�}�� ���U�:�����������!n���~P0�J/���v�h�3�AR��"���
G׆"�nn�����Ea����+ұ/K{���1k�`�2~h�����X�8?$}�v��R����?��ޟm���&���ԙ_��L�V4�R?�%&
��^[=ㅫ+dScRe`� <�L���ZC��]ybi�����;��qV(U.�X�� J����T�����E��G/B��]�1d|����D�� ʑ�1Q�YAEBY�^K�)��8M�cl���w�r��^J˧���`�I[C�Xt��<�M!D�j�Q�q���5�C-��4�n����Or�ɍB�?4�5���)����d3��F�pߛ���~�IMU]^�������;��X²��YJ��C�ʣ�m��2~��s|��@B�#)���s�M��\=#0�-�����@�{�2�9d�P3��s��;tVy(�(N��Ǧ�}ɍ-�6��������?�u E�2�Sۘ^~��4:L��q�IЃ���Xx&�Ӝ�>qN�fQ6y_U���CT
=�
�z�Bȫ<��*�ۋ &}kyh��\��s�{5}��)�%���nX�G�,_r^�:1�h#�^Ok�V���@0[���9�`-c+k� ���L��h\Ɨ7�]{���c�`��Ͳ���6��!T��j۔��q࿖Œ�ԣ�ml*�����Vf4 �l[���Ņ����ȋ���-��7ӳ�%�Xu��2��~4�������ƍ��c��@�JC]�y٭�	�EH;���8kr����z��x��V�7I�*��#?�)���yi	�{���&��P�LS ��ж�����"��x
:�?j�=����s6����m��<,:�BX�ĥ�4&��9�>�s�-E�"�V�:͖�&7TSI�;�v��:h0&t��I^h��jS#�Fe�����$�VX�͚u�fY `N��"2	G.�b��Qx(7����#(��#�,P3Da�jпs:��̯�t)��]��n���vԅ�^��eMX�i4�L:~Ra���.�@J��$? ��HxgGg&Z:�%��O7���}��R�l���E�bc��yO�h�=�-�fC��a����~At]�>$�i-�,S�$��I����p�ϐ��(C��xG�~� ��*F�D?�Ny���B�d��(M)AV�X?zKS��f]T�#��
����&�(�hr�kU� $�wu��g|*��d"x#��������j�˝��i���;d��°w@���.ڀf�,{Q�'��re��®�E�I��T���/���^��x�W+N�ٔ2����'�bU�r�lS�i�~�
�nI�A`�j��6S��{_��j��E�����0)��k:����F��xY��3Z��܂��|���,�>fT��s�^f�bL��6���K���;����Bti8W�?��wz�S��Z�GL�)�3��Ά'�W��7�(�����z[_��5�x��� �J��Z�I��z�J�F-�x������ɏ�6�r�z�}s�
��2�.���&�a��8�*G�Q���X�N\xZ\���������^���G,���*�͕�d�2x�:��Ç�Í���jÅ$�,�'���{�[��*c�������w�,��;����"s�"�N|9)J��fr��h�D��<�
X�1��7����~IsC;�d;ȠLD+��q~��,A�ZM#֊� �}����̗�9*��PF�H����ʩkh�:j�Yw��_�T�(7��Gnlg[�^�1�
M�H� ̞�v�&_����En��z�W�9H3|q�A)ϱlȪ����56�S�#,�fw���"j�U\�
�1j~��m
ދ ���m�%1m�P����&'���b2����+�7Kn�Bs�~"�yX&/d�n.��������uh���quq�檸o� �1A���i33����i� 'l{��S6�>�2^�tb' s�+&�uA���YDEy��]X["��6�
�1U����53XexE$k`Zi��ܳ��\�����$����2��Z(�H[|_�1�}Λ�<+�=Dm�0f�	�Ldp������^�7��R�PLݮ��g��O��O��Z\E����~����� �?�ד$�DP�hG���41�t�F�͏�!����u�|�x�b�������q�N���h⢝�tS�0O<whۚ����5��ٙi�2B6�E8�Q���!~�xC�:i#'H�A�҃0/kS=���,vc�{�� �X*��}��B�!�V�2��.�D��/�n�|�zMu�(���ѡ4'���0��Z0u��"�B��YT�,lD�����b�蟿��_i!o�? 4*C������W4�����|�M�R�;�Ŝ�fm�7tb���Be/��N�����nE�����`�;�n�^�Cƣ@��7T'|����S�>��nNo�EL��迮6I^�-���ۇp,�hW��Ϯ���ܞ����\lw+�����O� ��6�]���=����P^���ku<�_$K�["�,}t`)$����`�g]#�Q��ы��֍M}`(�&{��ZjJ�B�|@m�(1L� �9��<�>Z �k�yT���i~#S��~	����a��)?�>�ϗ�PxW{⚂����=�G�ĭ�f���:JXġ�=(���;Y�@Ƣ�H��;ҕ�Yy�8 �I�4�Hs��aKv�y�'���<
Ø�j���Jނb����n�rM��u�Ȕ���5,"��ws0෬�_i��	�f����r�%�S�m��,h����O'}~�=�7�@̪��ӝ)��R���Y���g���6��_q�ϼ��[+>p�pշ�ƹ�Z;Š���5��]�1�������L�H'�_T(xn�15��~����E=�g��`W�C/��.Ep��A1w�v����5�b��i�x·�﮿�|�z��-�9^��$���v[��F��Fa~�$ ���� ��	���R5@�������Ҟ����\wua�;=�,H�EgL=�G��,$��CW'jJ"鷢|��'�����WŴ����1���Q��8�v�٦{���M\���Lz��ϥ��ɸ�o�{�J�W���*ʲIɇ�����{Ū*�����g6�.l�Gﷵ�z�q��O�WGg�<C+�
�[�v$�5��;��]P״��Z�u0è�+u�h�C ���;"�����$���!���Y�y^H�eq�hG-I%�	��z������oZeg�N�y<�'�}N�k_��$��]X�1��}��+� %�w)��3_|Q�O˰{A�0��,����{��R��!g�m��2���ӵ�5e�H兌4��\�%��"+w#�6ƨ��m.Qd�|*m�Z%RX�8��mCT�B�_dL!���޶-A�����Ù���b�ܒo�u�N�L<���ԯ��P!���d����c��}A��?��*�]sJ�K2�ٺ�RK/�"EUK_i5���Hz�m�M�#}���	��^?��y3 ���#���+��t���_~�9����� �:e y�`K*1r,=�
��KOp0S�'�Yg@�d���5wBNt���:P�k}���?��U�x\DB���q�TRU���c)E��-��8 ��f;��l�:��$��}��M8��3'Pxk�j8���/Tt�AO��Pܴ'���i��,��    :~x�ɘP �����u���g�    YZ