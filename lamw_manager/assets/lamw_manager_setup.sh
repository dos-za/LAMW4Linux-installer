#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="618544940"
MD5="be576f100478d40aa52d35025b276be6"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26020"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:24:58 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
�7zXZ  �ִF !   �X���ec] �}��1Dd]����P�t�D�#��I��a)H���A�,�Vیn��=� �&�X8��$�I��*��T�N���u�X]��6�b2)ԴL���ĀQ��6q0c|r��O�I���A�o�!T5���ҵ��"F��^/	�������$o~L��sm�����V���2��QM|�c@5�xHM�*~���ss��G�����J5t��TYi�Ou=�s��c{�D5)AU^
4��m�Q�c�� ���]U>�'��[�IWm��N�2��3��3D�Td��bgxխe
�7!�E��#�5�OSH������ʑc��p��7���c<Lч�����i�'�w.�$O��T.�qʩ�ުK-�Sc��!�(#�%n���%�`�d�L�(�N���z�̗�1zȠ�Hd��`1�n�n�Ws9���j��?}�Kbv���DR~�B{ �(}��SH6��ۥ�A�H=�ۘ�r#���i�\��ř�y��_u���JW��P�Ã�L���9��-P(���A�a/f��H�6�&/]x��(K�2?D�U��h���ښO�tm��s�/�(��w�gL�˩�MJ����&4��Q�N�d�Q\��g���a7�}(�#=�?�q�Dde�ҧ��O��"����'�G���΀�|�ch�ae��Y��=�W�YS�]"���|O��I7�?�Y|�Nr�����^����I�8�$M(���EV'��sl+�{���Q��%^6R,D����q,El/�Q��F��X3AVj>XRH>zU�/e��ųO��MP8w;��=����J
!o�i}��Hy�	�Z\|_�^@_���/�vS�֣x�n�@0�b�����{�k�!OA�y�d̟A��d����h� C��(3�vϭ�h����'�$a���?$����%�r���	��=�9W��a{y��[�|u��\� �b[J6FO�F��0Y����Wk�^�K`�jZ�U,�ݲC�����n;hxQY����+���ô�9��/ȡ���]䩢�S%�utTn�����8��-8ŪH�"�]�	vC��V�G��ű�T]%�:�@�R�_t&���]?I|c�}1S,�;ov���'��=S�+X��/Z7��춠�S�)"�Sīe�frFIù�	<�L�7��aP`��X��D"��S����$ؿ>X�E�bC�w�����;�q��}Mi�5ǒ�����Pf*����oGs�OD>� �{86�W�3q3�7��9���	�,��]���MG3���~E���q�]��زv�%�=KSK��������e2�Ύp�lsm�A9�����LI��$��W�NJW��n���.N x��w-��V7v2}�r��a�:O�U[[K���f����kB*�Ӓ/b/�k�åM�8XS�GytC	3@��n2<�.ԅ��T	{�����|¼M��\atQ�IʔO��`.��Y,�8��`���i"�P����Xϝ�q��FA���mx����Nh�%��~�G#έ��s�Qe���&����+s�$����k&	jt�5*O�:l��0��}�=p��9S�H��9��֬�Z�2�����g���o�[���B��ѿ���S��Z`1�r�s����ʂ� ��6jl���Ӌ�Ki����A�*��5M>���b�b༪�;Z5ي1�׹=o83�,ʛS�\�/�6�Cѽ��0�4(K�\�
�.�tm����+$�����f�5O��o�"��g9�0�2z��#h�X��C���r���fH�1�����0���b��]]�B�t����q��X`kWC � -y�C[=�k{�7x�xR�̧�~ ��=$�=��KaTC��R�f��'x���l�ۖ�.LC�i�+�F���)��ʹ�>����`�!��Vi=wѠ?lp1S���O�ap-���Z'��=���f��0L5�b�a����k��:�%ƅ?��U�0���hG�P��Y< z�a�ڍ�6�F��/�� |� �Mӹ>���ܴ	W	�e�W�m!�7�F��	��҉�= �t��Ľ5�^-��^9���x%)�<�o�=��(�&��͉��>�:5�����̖u*��w{�o
���^&ʜk5Q[��7Y�xJ�J���I���"E�TK��m����|�[?R� ?�ӑ�3��S� ���k����G��J���(�q���1G�_����S��QK)]�F	��܄(�R�	<Z<��2%���E��������&���m�C��d}P[Ǟ������ތ؛U5�;pt�f��ސ�+��y�M�%Ya� ���?�%�B��d0K4�վ�h�g��>�5�AXp�ϰi٪{���O�
ٗ4�iM�R�&˽�}Qo'?�XY�@#�z+ˬ�	E(��wt�wټ�v�1|�/�)�e]���-�PwL>���?���}G p��+ȕ �-����#�-g���@M�I	�|M6�<�d�Z�&�]:]����`/3�b�O�����֚��[���i�#Ǔ-%5��/������/�?���w��D����sx�άʜhx��1 �m~<��,��3��/����I�j��E��f���&��3�1$	=���k��Dꗽ3$[O��p\b'#��C@;���;�j5���M8��M*�7�j��di 6k̎�w3�x�H��@�����v��OG~X2h�9t
�N�7��O�їM���j�%���p�G�s�C�F�,����+{�����&�����
�������e,�"KV�K�0]���!`�a�+�o��R�zBG\*B1%D��>�w����)�o�+��Z]��}͗T���_�C�=�H���i�޹e��itd����_{.��	2�8&�Rxf5{�"�=n�mEab�ޣ���j���LP$v,�t#���s�/�!uW���
�yC��o�N�G^�WTH��0y)�֚k��Q�DR���d���#$�C0��ZA��n�6��&�v�:�`E7��v�vH_���g�%_I�x�l���p	A�`���QP��F��.��9��mTu�(��[���b|�O�_]�gʥ��f�(4eY2h X�F���[���L�K��{ ��æ����QT[=���,h:p��r$�/""���0�	��j<�Ē���	�������B!�Jr�+��Sd��n��PQ�O��Дy�c��V�Ԍ�&�U9�B������Uy��`�����������M�J�b��FDo7G�i_1zDYh$��꼰韽�����;��E_�ݤ~n�p3�^��&��=n����3|�̤ۓH��V6U����A/K���&��
��sXkԦHFT7���{����L�"]�����"^[mB�?�C��XOD���EV�)��)����y���]M��BI��N ��,�L������%���即��~��2���Қ�Ba�؃��|w~8Z=�"�15���_4=90o���d��xƄc�V���8kԮ�7�:��+�(��8'o���)~=�Q~7���1>&��1V�[�����S"vu�&�N�Ƙ�iq����K�n�k��|?����Aȼ�(�R�ۧ滼����� �x�>N[fU䃺u7x\�7��N�����;��V�Ea?�=@��7�\� s��Yu�RBQf����-��O�|�
�7e<W$�g�|�y��!����h=n;�@FJYp��c����)臕�,8����7�_�B,I��7�^Ue�zGEH�`��#�=�ԯǂ� ��:m���SY�T�6����{q}�p���ֈP�ј��Xv��-��o"��w�K? ��+���͹��A��6и��K'LE0؋UxL�zp7t(�$\Lfa`Dg�H~�ߎ3l�7�Ί}��?��)�up<�28�ٞ�j�rݾ�@m�9��9�'�GlV�k`�MG=��7*p�tCE���D̅�4�T�2�FD�(m���i����d���e>o�}-M��E�F�aV�<��g�&�P����l�m`Y�l,V@+�xRXۏ�%�k�#�������I���X��/d������p l"*9�b��	)[ȃ`��2���OPD	�(�H�_��P����5&X�L��)c��ph�������o�F�re���������P�"��=(�nd�:�r5��M��QgWj����p��Yg-M%�GU>������uRD�{�C����}������;��pGx�tw�ܭ�6� ����������w��5h>.���^�2���!��W��Y�	\�!C�'<C��[�BX�):�䰋�&�S��t&��*��u�/h�Q����;��[�*��M��&�G�����a���|�~M)�e��%
��,����L>���T�≣r�|�QS�U��Kѭ�!"��������_���2���~��R엝Cn���c�D�q<���?���>ׄZ!���So���,4
��i/>~Y���6;��悚j��<�HL��u=���;���U���#+�%�>t�L��J��63n��٠ȐlɖKL0W�c\��i�����)B�1to�T�>�%�B�!y2L�*����e�A.����4�-pd��v������[�;Є�ilzb,�Ψ�2��z<�c9�]G���A�G�GsWN��.v���0��(��O���ۮ�������*�����F�c9 /6�� d[���U}BmɝU�_���ӄ��m�]B�����[tv��!�&�m�)��8Z�wv#[�2�HyQ���]�)��.g)PW��bM�}'�|� �b�߀qr3�i��m�� ���|
�`��Ox��h?�l%Ʋ�:�(B�3L�,{����6eC��=��d�0��r,��%ꭴ�vC�FP\5$��;£�j7��B⺉	��j^�X��8.��<�]���#�xSr����7{��B�і~��w���v�II���Q�&��@�s��'1
�����\����5��HC�%��\��ڳ[�d�	$�>�E�S�S��,r�U�~UO��f5h<��3p�{�y���u�#�RC�?C,��^�8��E��6*�h���
�i@:"]aZ)�q�����*Pe~I�A��x��,��k����[B�pVB2z˥z��LF�FrP��%����sh����P��������΀-{ުJG�8�si��$�~śm�ζ��w��%���:Z��?�<�{�g	�I��F����7>n���	�]��Mݨ��܌����m��6,M����_m�V�m�PF&�eu��}Z�xZ蕆�r��Z��CY{��%��I�)`�_��-��8|�Y�sR�p7�������-�P8�7��RZ�����-�/{W�i����	���c뽳C�b���oq���Ū�u����"��c�HeDXѯ�}� ��jq�힌��±̇��km�j��z�o��
�p@CN�����;�~<Ȩ�"l��?'
��m!W�N9q_�ƅ�
�BX�GX�L�n�#�֜�I���z?<��	l1#3��# "�<H�rg�{�(�XI%����ƱJ������xҫ|~�;�����X'��K��|f=�υ!h�u�`�����Ejduj[����U���k����5���=�3.x9�Y1�*�݊��n_��]���`�j����1k�>�/��'ui|�)�4L}�c�E����y�_�����>S�/�1*���So;g�z��9P�nkOC�yx���-�M����21��"����{�y{o�(t^�����ؽ��k#������D�]Zc�CK�}��95S��_�wۭ1L�P8}ܻ �'9���\��_,ifC��ZT<��
����Õ�Q��
���A�\@�1�s�azF���̴aD �������)*%ݻ�ʺ���1*��?I'm��HRg ��o�<��xv��P��OhV�R]��h��-�la���A�O᫡T�^Xz�p��P�wD�
%ͩU�R����kk(��hr
ѓL%5h���Z�AٕL�D����`^���_.��ݻ�}�nm��O�r|B���"h ���/a:���=��˞K}dl��YM8�e�xM)�,�3)��5���K0ݏ���gW�L�r2�O����Tm���񠉬w�!����0N+���aᨪ����f0s�����R|׶�JjS,�!��σx$fe�!���k l�1P�����?�BW�����R
�=�������vW���D��gv9on�0�8��huB�[K��F�sU�14j��߳���E�
c�����?�ν�xYq=�u�|�����R�����AX���ЪEs~)��KRHq�J}TrW��P8MB����d�c{���!�@OG������O,�Y%�A��=2�z���qa�J�����Ɵ'y�����O�	�οOx	��z[k/#�����3�wF��K]Ľ�Ye!�vk��pS�^ �DE5�4bM@���u��փ̇)����?&+Ӯ�3�+������{<�7�
9�r�4��n�`��5�U-�����Q�oO8�S�
�1�yc�B�jM���$r�>%���5½^�������JN'�w�-�oM�����e��x��U4�|�ޟ����Q��qo��H��u�x&��r��/c����ܸ�ױ������v��e�;��&.YB,��$[񙌣I�k�@��C��ں!HY������"�c��h[T3�� �y���"��zb/�H� 9��������ųt+[�3���!���Q;L��.�W��	�I�̶�����\T�L�R~DȠ�����ж�����l]�i��9
Cd�"i�=W����@`�[���G��YN����'�Ro����ÍUԋ����Ԓ�%]0���g�&�ۂ�V�n7��ÅaN^��+D��?�����GPV���q��P'�eq�7� �@�|��^�D!�H|.|	�	Nԗ�ԫ���8�d�y�?ؚ�1��M�A��!�{+�$��*�c��}���6���N��f�P�R_'*�/QAU��C�5���+[N��	�D�5ԛ�3]�P��aM@��y�qx�%�a�[,�3�c5)�Ť���NH�M\[g
���G�ɊCw�v :�&�8�R�A6Z9��ɼN��ز������qP7�$m�e-�3Pȭ���;*��3~O p�$���f帚�\�^2'�R�3GTDyp�{m�0d�U_[Y-&�Ez5̈́���{��2��A�#��	GK?��h$\m�ih��D[®�	�Pҩ��;�"C�E�@��Ϗ�$�x���[������{1@���S�&��r9�=���\}����.���.L���xItM<�00��>�l�?36�.�l-a��4��rZ�k�*��뀀 8=|M�?m5/$��O���-H�4�(	�J9����tF�@�"�bI�\��(�]9���FU�����XZ�i�+6��J��%v�Y���']A�%�;���B[���=����T�/�E��k�U�ԕ�t���q�*A���G��µOx�.iƏ0�I��DI7 ^��FT�"����	:��{M��w8�o�ӌ�f�*ic
�(9�<�0�g�:���:o����21�b[&M����D��1H-��s����F ւ;>���b�Qn������tsԏ�y`6i�Kɲ����@d�׽Ԑ�Â��Eza��cuWtu]*��^�/ϱ�j��W��AT�v9&vV(��6?,��p���Ѱ�)������ѫ�,ca��$����Kq����+�^b���`�YEk��N;�b:;�a�ZO�4��ms8��lEZm�*:���m�Y�KL�i^���]��0{��e�2���L�umJQ|ŧ��Bbf%@͖�b���mY�}��m)���t���&>b]5'#����ʆqUI&�x�*���mo>�i�շ����)��O�[�?�����A��+��j���t5Wf���,r�o��o�H{(}ʃ�q���¥��^$6z4�i��_Eߧ�
���z �-ש<���o�P�6�hm�|�����p��O`b���ad��K����6�)���E���(5�6i����,�QE���,���5�4q`L���/$B�F�ymnF�$h>@BF�i�3�h��8�d��yr��k���3#m7��3/���o�����TfSWy���L�{ihм���iB{��]�]�wM��"�Ά�V�G�8>����9T���Bh�O�:ڡS&��v�վ�B�����@)q�n����Jq��d-����Xl�=��3�Jhw�����dg���+_ϼ
�5����\����5��:O7u-X�Q��.�8�sVǯ��D绳��ޥ1�'�FB�WIJ�M����cw$��Ѡ���p!���E��S�t�P1	"��ҳ���f�E[fDܸ*��v��8-Hr�
4��7Y��7�#t����l#�@�x],�RvVȘ��H��	�k����hQ�A�p^�W|�l3����*�iM��>] �ҔF��A�j�As)?�V�%�	.?��F��ҝ�H��ުf��`����X����Y��*Y��F�������
s��%6˞�_�>�Q�yJզm��O)�k�0ȯ̂�r� p�N���AV3�*�o�� �PB�C����J4ɹ7�ˆ��fV�,��h�}Q���I?��ѧ��u�e��!������P�M��6sb�� 1�3����s� �㠫v��N(R�}R�b4;W��#!��M4Sn�)�s�(��T��e�D�ϻ��K�'�P���V���H>�=��I-���	��k�)/>�z�=��*�(Yhx���7����s26�b�9�!����7�s�e�ױm��炩)��n
)����s̷��aH�8�Za;��?��D���M�X�\�N_0�H�o�Ю H�M���.�A�*���S����.I�p�1��0,��,�a�w$ � �2�� � (0�3���`�KJu)����ni����_�՞(�ŝ�:�$���_d%4r~���Q�Y��{��`4k4��q�l3�/�Ee��驅���s��w�Bb�`�&.�#�e��~$n!H��yt	�mۖx��R�!P��]����m�'�?ϔgˣ�� ���Y�*ua�h̗@Í酪�[D�E��V`:�$�t�`ǡѢ��<L#	�; ����*
��awe.�*���8mez����c��>�l&i�̟
�|b�u{fV\�"���u���ZFI�Ȱ�,#`'���}�d�9��9#���Р��r�~�U�F�T�P���82ki���X�CY?�e�v� ޓbO�WB�͡�L���|�'�&=k�(��L�u���_9������cE�3>;��H��`��X�?�(Ϥ�{��'H7�����/����Z1��/1j+G3��u�a�o��r&�9��;�K57T�S.����'#n;�����L��x}|�^�O��THe��T<��$�]��#�\����ͫ��Cg��/���+�nJڤ��K@������)��&��ؿZ�(���L����M���C| c�:�x���PD*t }���pR���x�L�Y ,��a��@m�'q�c�G���E_�����
LSF�	��G��/6��W��r�.߰�,Uǿo�� {${CR[B��V����_���Аke#��� 	1|�£]#�|�(��O�c�+	���XmZ�:ٕ��u;��g$���(t6U�l^!�rRŗy�,ɥʳH��b�c�rID�ds�M�^�w-���˪{�<� 1]n���	}R`�gpD�v$v���R����X}����wT��έ�,$��Y�}=^j�m5�U1r��^Ef��z�����6�v<P�u�(�#i�� ��f1����t�(�����E���hZ���	�48)0hA��i�љ�l�F�H�h�!V�6�~��n�TN��\��'�qt�5q`�{:��v�5�k3T,�b(�T���O�DZ�XN5�b�4#s�tl�)~�S�+�Č�����9H-�}Hϑ|��/��d��	t%z�)O���4,g�Jף7}��1T��t߯���a�#��fS�<��4꽴�S�ç��Β�������W�)�(a~\��3,̢Z����1��$IB2�.v�p`����$Ł�vD��o&��#��T��7s ��R�ɛn��8��Y�a`�v�\�U�!����&���}��cykS.^�d������!Q�����.�Q�3��R���D��k`�tw�g6�s|Z�b=C�s��*�DlcȌ:���	��`�V�_�b��Sǥ�,@,�(�y% �J�X�q*E�k�V�ƣ�s��.M���!��p+|�T��#�a-g���q�� 	1��U�}l"i,��Ϡ`�5�s��I@��� ����bQ�5��演]oN"��\N��M[�H�}s�M)Q֊���K UW��;
�0�'YN$����)��o\�0U;'f���2��C%�H�*�ˡ��옉P	��gp3�i���'��˅��2j!#���T��x��.=��c���mN��Q�4U�/>]<Fz�>��4��~��49���bMR�3 �(ko��[�DJ%�^
q�DB��B���1Ĩ�	EC����{4�ݵa���J����s�c�\N�1DBHw���A���_{Q�{�X㨘�i��ŘJ��+�f�p�� �'�:k6����>V.h+3�S�/��E��%�`�;QzG[%�.K��HJ����j����q�^l�g�;7*�
�Vn>l���ȍ���Ě��u,֭}��B��٘��:N�֊f�T��ЂC�b?��4C�:P�=�LV�f��n�*,E�!�H�,��Dȑ"7m̀5��Y�DR;�Y1��h���!s%m�C����N����҃��(/Q��t>�L2��J�"|"ZeOF4+�S.4���z�;��:I�E�e�o
[�C���\Nͷ��(t���Ya��<��,S��%���Yk���4U�ɡG��\j���^�+U�Pj���4_]U����:��۴N�k�.�����&�Ӵ�q��Z���)����~�E��螅��}o�7��\X�UG�J[*�[��ԃ
���\o��,/KM��b�͌�{�tn�eh̉�}����ԼF܄9��~�(�R��������K���fH�$���b��+�<tj)L��`�[�H	d�;�r�-�R�4c����O"�e�~��?�{�����`���MA��,C��gX��^X��pa���)2��ٙ��lE�Nä��,2P� K%���[����ƭs���ĩ�$��{?�H�u�t:cZ�7)�>kO�Lt��,o�.r���OR4#���@�����I8n.Sr�����jȭ����C�r<d��4ebX���]Z�������[v�{�����^=���;������1u�n�)�bRU�tY�ʷ��*�%nE�����t���~�&rL2V�,P�ݵ�)���,�qYRZwF�&����$��Y�11����R�R����)H�'����p�<�bG3�ԭ�rL�)�/�"����>^+�s����M�h�2�R��E�V���> L���zJ����j[J	5?79jf4 �s&J�
\���0��EAE'�(�'�+ZV� ��z��ZG��{��s��(��-{>4���M}���QF�>�%��a�9�4b�p���]�=�&�bJ����>K���	GqX��F�kC�Zp�t3�T'R"g�e�'U'��!�	uV|���O��i���\�N�{�~��AT\�IR��)��u����-@�U�-�O3��C�·�IOy�I;Yo"\��ڔݰ>rd5350ؼ*��sv��gr'��3m�1���"�-�wi��8)��M��iR����d�Q�th��ɯF�PZ~
�F����YK�UB}��8"�e��c"Fۻ�Z:/z�z����=d�5d�'O;\�-I�Nﳹ0��/�N	/+c2�J�k%'"��cfBi�x˖.�~�xu�ߓ��2�'Y:� ����#�o�]P�Y&�d��/ڊ�_�ׁ�1D�$��[u~�6ǲH�.����t)=3��(k��?��1�T�w.�
�$��Y�S>b���0�/O�����j�h ��D��GT�]�I��:��*�q��k�b%s&],���3֖� �^ z�1�MW�|��|���F����t Ec�-��G�s��S=3�m�d����+r�]^i5ft6U��]�K�Z~�3�ȚuܰCpR*����x�Y�v�SPH���&S"?�����1>8��^\��!YrfS�2��:yiN�+K춍�Ȍ�]�{+�`qs�Dq��JKcC_ǬU�kB��0VP=ư��������Tܿ��p��3�Y���a��̾?��A�8�h&i`Y�i�|�C⯽j�v�˩ r{{�9���1)J�9%�g���.z��¨��Q���qm&�t��n9\Y���Y� ��-������ "DV�C��s%'A��-{��N����հ���k��ps�N�i���t�,�J_���
���qŰ�b;;wR 2+C{��D���\@%�,�5<Kg��tV~��9��^�jh�T�ny>+0����|���L���" �P�"ϗ�gq[���S#���"��Dq�)by��G7��0U�9���ǲ�`TxG
#�tJ�
�UI��x�?��ot"[��8:D���9�H��0[�0z4e���������Q�>�j�:�YD�7"���sZ��$`��K�ߥ��d,�ߙ8t�v8�%��9� 6�{� ���R��py��g��*�(��/�:9g<�S��{����C�$�,?����WF=X?
UN���!.�$�PX�����TY�4��ϪTu:!FK09��~A���=]C�l�)zmX�����A]�G�O�r�����6��Zyd�v8T�⮵F��x1�� �/�5�ꫯ����̖��r!��M.k����e;�R��q-P���������Hf9;T��G�Q�Uw��69w�p-�ޭ%�#�s�;�(�%�ͥ�"�h(��^��9�S����B���5��%\�q?��C\Tr:���`����h�㰈�VkB�@	5���3�I�����Fc}W1��V��=G�C���gݗ�����MdL�s����$�V�D�ˍ�<ͱ�(����
����*��;�E�@�wM���z�q��@yO��o�\�q�����'{�?��C��_I2�q|�;�f��}�9�i���Z���^�K�Y�j�������rh���WtbD�%��Is�<_0J��eTi9�wXPz	q�D�,�@�v3�t�o�-��,�m�͡0y��l]"X�=7Y�g��$�Tѐ2�\���6%Ƶ���kKW�b
�푴R�/�,M����H��AX�0DztV��L�t�}��/�o�g<�*���ZK!�
�L��Ά��_<��Ip~2�k�:>�"�!�.~q Ǥ]�t���[��F���>}<����N���O����_HRhb�!�.��EV�J9�lO*�R�Z9	"��bM�A���(���UL�׶�ꋈ��b!�v����
}���!� N�@�<|R4Q��=�;���|n��Pu6�~!����HQǕy��-���g���S؜m�N9+��R
�O1A���7�b2�uo�����T��O� �ظ)]z7�ݾ�&m���?H��b�	^8�E 4�IX�	;2:�7�&Q��/���l�#���hL�K\^���|Qn-�Jj)CSd�<bɻ�l��:�ψ�C��Q�V���k���A�[7�p'��Q��T���'�2�7�[�z�D=��F����ɱJo�	^��pQ�ޫ89/F"���]*�;�k�;;w��<�%B3V_�״a�H�i2dJm���)Y�yԯA����`�>�e	��;�y9I�4�2���E�d7j�?��~���ǧI�*�œgA��}\��t���؍���ɳ�* &1?����6m�I8��S��W�GM��l�C���Gg9�)�u��ќ_�g�&3D��ʏ�%���Γjc'�c�n��[�#��X�>@֊s���M�E��/}�	]��.	������d���r���?�@�ޭ&p����<��omb�j�P��1)*j��"�p.؆��B�1�X��5�	�,<�>{�g��T#��9%��`���7VR$-;��}*���&��-*������?m�v�l�`���~��kg����!!��������)iw@��@X	hAW׀(5I�Xl\VF(:�2�u�"v�X���;����n�H�=@��˽���֫*��?@d�6*9�Z6DN �-�k '���l�-�0�p��gD�$,h�Ҩ)��"� ��V Yd}d��gm>��C38�K�V���]�YO�PXft[�fm:_�x83�T&�u��3��S�Q�B��w��Q��cP��{���;��3΅�@@W��f�\y�/�\��1�ŭ��by��[��f���$Ȇ��5c�9*(�̽U�0� �>�O- `88��Y��+�|�q8^�c1�����^j��ӦKҬ�W�M#֎-Ndꂴ�Z���oW��7③�"��a\�J�Sq��1f^��v34�Տ�	�������7=2P~�F/�ؠ���pD���e}u��(V�A�
w�S�)ڡ���v�!�a߃E�^,�O�~�����/��=k���MqB�H��G�X��8�P��M�l�݁���[b`��r��	���C��0.*��g*5Sx�S[s��_�9��w�F��n�}���*ɒ��׼i3�q��|�|+�! )_Xr(�aW��������Т���R�Ҙ���Wy�U���GRE¬���.k��fI��  ��u���N�*�����'B��6
Ʒ�.RMX�������U��mrH�~kTmWpC��
��+��@k�~�QVw������MkYA�E~�]��Tl0B��� o�Kdy;�煃�h��\�k=��3���7�5:��5�Ӹ��|�* �N
�͡��	4�_;BnX�+'ؘ0G
��t������AF!#G_�6�kǾ;��
|�2=<,�	ʕ^0uߠ�Z���c���1<�x���ğ�R�|x"�ۢ�y��f]'��©ƅ�&���q5�j!h���iE/c��"V�?_.���E!�u�6��9n?�t��Uf]��W��A�?��}�5E�x%Vp�*���H��|�Xz��*Fbp����|�l� �"��������l����2E��C(
&4ރ��Y��Ю=�����;�я�[����o.�*.���~E�J���ua�ֳUMδd�}�V�P�|w�[��8}X
������S�&��V�o�K���5!�k~p5"�O���*��KjcKpwq7{����T���0c)����^a�ʩ��'�n7��sJHֱ%PN@?f�'O��r�oD��с�.�z�_�y)��v[�^P�1��������\�,9x<?ċފ�δ�e<ҭU٢w�ٿ�B��Ƴ8K�,=�%^����G���Qd�gJ���p���c��|��oָ�^�������rD��H�B5L����������c�5*����ٳ�;��D��?����u^73|~�	����*���w�6��yp�rqQ����e����і�>�W:�j��\���i�;u�K�_7�9�1����>̯h��f3/e}
[�N�[&��E�H(u�3X�;�|m�"3�Z���la����gC��� �r��2bOL\f�Mf����N�:a���?	D�/#��	�P����T�rg$g�X�X��t�W��k��{�tb%�F?�U���df�X�S�Q�M~�eLT:������
r��$ҙ8��0�Şu�UU2�s��.H(�ᠧi����G���^p���2-Z���� b�����Qn*�ޜ�p.�o&��dő.�������Tp� tAқ?��G�&��z���S�)2ɓ��tS��s����Eb�sF�{2�<���ٕa0���nfɹ�&���Ņ;^���LZKo@��'?�Ǯ��b'h���g@�?^)3��'4ژI�w�6
Է���^\��CA7���y��>�\ޭ�����]�\��n*I�\"� �͓Y.��C�;�3���EMN��h���Ӭ�}:�? ��4�,q)���
���E,I�{?x'�c6!��<�-]r�{����IP�hP��"�O=�7s:�[�m
���Lh�1gD��s8�l��!e�T�����m�R�R��An��&E�����ZT����kW�����˼�?� ĳ�w�OC���I|����eˏ/�n��z�B�l��p-�6q.
�g���Ι�Q)\x��[��J�1���f��]��R�P��%�����.���۝Z�\�k��)eR�t4����(��*�����^O;(a���b�v!�kǒ�:l<�"�O����
sDIx��h�@_t!t��>���a��B�ւQ�i��:�M�>��]fܓU�B<|��`_,�����$Hգ�:�K�(z�7���+V����m���#����W��R�����|'���bx=�V.j豴�Rذ�@��ʶy\w;=����v���h��w�'�l �@s�;v38��1�H���S��I��Z�k1�*VÜ����SE-a���"q�z��W��������\�l���ѳ gA���'��Fg��]q�$��{@�s~�!L�Fb��y�e2
����~��qC��{M��\%�rs7���cCuo=��7�[w�K�T'��א�\�,�+�p/� ��K�r��'qO�
�����`���~Q�v�+���׎�+���J����.�ձ�i���'�n�}��ҩއ@[#�gfo�L���0>ȷ�LN�Z"w��Z��ܕ-Gؼ72���c�C�ݭ)���]��V'��<M�S6 �/�d��R��g�0�m����_��Vc�Fx�  ���c@�"��
=sE:,!��ɡ9��X�չ�c��@�Lk�}�L�?����yd�sk'��������Y��WFhx~���Q% �h���:���-��܊ˤA�f#^�ȿ9
ۮ�$�I,ְq�N��t� YX�}�ym�~I{.#�eYyU���t�TLLė�c�I�Q����4�L��Mk)fKƳ{��-є]�Af�@^�|�01��N` �0�T��vѽ�#�� �u{�Z�I3v?�)G3
�I�r}'*ğ�L��b��)���������k/���F$�?�eN/:pB!O�v~e�Y�l�5U�t��)@:�1�ȩ����C^���ٛ�u�h��Ѝ�&��9.N�(e���3��y&�p�V�F���!�;*ʊ�?V�M���炋/G��N�b�֖�p�����'w2T�J��f���C��@�A@> .�!��6��p,�ltV�K���~����)ʓ�C��y_M�R
����w]ɚTF}��*�Z����%'��,���x������-�"o7���$��(Dq���\p}8C�ꚞ�$�_=��9Y��5�,֋x޺��]fr6��������XE���=�ӊLG��ޒ��ѧc����b8]d*w����诨�p1��\7n�ZPL��~��f�\�|35#���t;d�T_���(��9ݗQ߈d���ɼFܓ7�3�����5k��}{�,\�S�IBc�ƽ��H��6���~>Øm&��p�Ǔ	b�-��V#�0�jSQ��)�uhJ ��8���$IB���*��"�>q��&�R`��	�Q�ao,���Z�h���;��j�Q��س��(�}`��z�
Z��x3AH>�J^��C%�Y)J�=�wd]`ɑQ['��3�ۼߘ��R���n�s!� Տ]�"�\��Vx�ɭ�9l��0��p
Ԑ"�>���H����-nI�/ȧ-�&kǷ�h��4�ËL�iVw#Bb�<`\��ղf���$��]��@U�2ύ�
�ϟ/�Y�g����1��PI��`#��ѩ�d>�L���a�8/)D�p���s1_
u�"��*��<c����h��x��#����>v���K!����ic�%����}!6)�5[x"���r�#�2����6Z�_^V\��G�EdWFڙ��f��Aј��$�M�C0^�s$Wk��mv�x��Tz��NP�Uv��x��-/�j�����>_U��Ԣc4��[@۪��|�T2;2��T�%a�0ҫ�bǚ��B҈�ཱུ�٘�	��&^�
��rt4g�v��t��e���X���@޽Z 1h�K��m���%��==�~�@��RF��g�)d盄m��9��]���Ն��9�
�XJ���ޱ�r��E$t
�`U\Ww_�����<=A��AU%]�<V���#��h�6�6GRޟQm��v%�R�j6;���.u�-�@F��V%�H#�p���^�5CER<l�w���� �:b�=�[�N�.^Fi�f����a�ݻ�kY��N�Y�~��}�R�*����nmI��eAm03	����D"AS�x����T185�ms�����wk�'J%��Y��F�̓P>Ei��I�l�1���q��S։�m��n6%�OQs�np�=5ˡ�Cm�XGDcH"�7���kw�3��(�X�a�o8J�F���Ud�KS�eb?�@*�xTǜ������u��#�3�h�vl+����5jT]hQ�`C�~gL��+v	��sx:/�\\!����<��&�_�ܡ�Si�����g2O�����Y��T$���
6@1�/V	��Z w��x:Lg��5��~cQ���)n��f�]��%��AkJoHO5�dO��T���wmW���O�ǜ����YZ��縥}�nh�� O���~��n�9=d�aT��Sf���$Ah=���$t

������pz���)��d+"��$1���o-Y^p�^C��u�G��w��-��3xzJF�C�`�.�ƂO|���Xvn6y��Lnd;P}��s��P�s��zW�FNv�N���[¢�n����ߗ�
�y�k�p/�;���~Ej3^��~�I�n&͟�]y4�j����!��"=8v��}M���Q.�
�q4@��?��m�Sx�e0~g�`�ݐ� �x��p]��c3�l���SO�LKd<�W]���l�����Xp�XT��˸]�#aQM�/��:��N~P�O�Ö/C߀��Ǟ��	�l�I�+��a��K�j��\"P�ƄiF�_ϝWRh"�N��d�r3�kP�jR�-t��U�9�d�nx}�{���V���L�cٟ�N� 4��ք5�_�1x�-��	��1>��%L�rG�`)>#���LOc�줉FU���s.�y�� ��zޠ$������+�	��*��q���Rl��� �����������r7�ӣ�J�5�Y�T�+-� �X G�ۄ{�}ۍ�N�Ա�z�s��^>��w�M�Z���&h��o{�O[��<��D BD� /�`�?�f}ސ!OWH����Z������Aq�R�Rm��Ab%Sv�"R,���h�����	U1�˼�ri�m��$Y�}s��QK?����D֙��$˦����_i�w�d����c�C�v?�H�d�ㅠ~����`���ks��ǵ�N#J�O���F���j�{�e|*�wOY�d��Q� y�ҫ����p�SnZN�JQI�Lo�#4�I�e�&pm^:K%�ju7[����3%3�ߤ7��&���Lr���4D���trfEVaw"�<F�+·GT����ȳa�1ۈ]�=��� �* ?��bc}<�۪qy��>�k�� �NG���XᲷ�'=���׵���6q�nyT���룹�����p,@���O�d3�	�>Y�<���T��j7|���gڇ���kѿ_`�.��(pg�])�t�	�����iV���`��Y�#���(AP�'ƿv���=��p�l�5׳�U��r{l�gΟ_1�eV��6's�u�f�H9�o�,��
u_P9��a��l!���I�Zt���gf��z�^�?DG��D$WѭH�>��^��;�~�*[��sa%����"#pd�6�e���3��ũ+0�wQE�<����4�a,}1FMk�|X"�M��P����F���s@��uB!�3�w�y�p�P�]����w�����y����o�ɭݲ��o�y(֖���}U���/���b��������'O>R%L�sAYޱ�w�Ua*o��u��j�[�ů��>8�j��)¦uO�]�Al-~0~ӂ�?��
�u�9\�����^[�0�׺�˫M(�� �L'�.�<wX��E�~�����_���g,�1��Y���$��i��%i]�L.���+�����	U"�K`���ϐ�9[�^(,J_��R`��(F̏{�&��G)�x����6I��o�4�a��/��B�6�y�L��/E�y=�J����N�"y�
�2�iTɼ��3_uXMWB��%[�e��͌��>sC`�C��#�����[����ÔN�����t~T��^��;���y�Y4�E9��ճ���#���(梄L��V�k�k<R)���)
�޳��4C,��h2��T�cWv	2�&�� +�T
���LDPXp��Yuʹ��B�,�N���J���%\p��K���b\�U�	��/<F�`ob�<�
��<�Y�Ʃ��
I�-�ʛSP�ϔ������7Y�;n'l����S`C)�Dw>�R��J�/�`ؘ��U�i��Tc��O����g'�J%��LG;.BӁ�GLB��y���.��eq���i��2+g���~�=iQ�1\��~��E�W-�)���֧�5og�R�@��ͤr��� �E�ج$��J��} jW����3��u��~7���t���|;[#oh�[@u@�����\ �UL�A5��+���1��l��&�X���D[����5W�,�]`:�S*�4&VF8d���IO6�rO!U��|ҧJVv�;��:Wڲ)� ��۬q����yI�����B��c���D��2�����"��ի��R.en�qc/:G���s��`OH�S��1qvG;�Z��w�U{VSsI������3������E啨��6��tҷ�v�F��u��ѻh���ǆ,�$���V&�T�������'��yb�Z���zHK�/�5;B͉�����H����n`Y�vn0�g��ox6���>8���Fi�����ʅ�!��o񅚗����6~��9��7�k����+m1W����W,
��}`)�n��=�b��JF���>�N�ቝ�=y]{�����Sʷ|�2���xW�E��8��� ��B#6��a�U�+K�Z����sM�f!�{f��L�I P!>´��Ɔe���m��F ��M��|z��?��N����"�
=��U�.*lwS��êAG�i��|�kǍ��H��js�{�$.�ϲ"P����p.��"!�f�6���]��w��#*�E��%eH3����ęB0b��<��Ȩ�X|��%�1*�����ۤ] ��l$��@u ^cR(j��������@�&�$H���m5=�M�U��W���n*��cA0�c�����	33��2�HPa��	��~�`v�t2� ���	-����r8�.����Q���N�W���)���bze٤��_���B5�/t�e�2QP��覹��"��!�C����~b���������p�}��.��`a���).��P$0t��h�a���)ɗ���I|�� ׆/ ��hڄo�"!�Cr�8���������}Q��.s�Q�����d�6ƙ���� y���ߓkE�JHl}K�ث/OD�fCPj�,�I�Aa�^�v?��+�AH��(�M�9,U7�,9�Bk�H��4�=Re�xLks(�����i�t���i�	�h�U��M��yh4�H[�x�������e���;x�Ξ���m�wK�5QY�6�-�`_�p[�V̺x���@K���c��O�2Ӭ�%��d�l���)��TÄ]
*���g�$
�[��u"yM���?q��z����ݑy�m66��
!/��5�(@ʥ�D:�uu��Zy�AB�4�ÿ�#�9��C��g�|�e��]�=>����M�� w�AC�T���N"(]qK/.��O_Ni�Y��^�Ĭo��0[��#����\\�458Fw�b�����g5�Brk�Ux�Ȟ�� CWJٝz*�z�s!��K����)�3�9R�㹴�$�mcrFE$ݾy���m|o*�����KO��Hը	�^eע?�����}��9Ď�ܐ�-^�oW�
p�1}�!���S�8��OF��l����D����4h�T:�w�#�$���P�cj���qK�v�-�G�3�O���]�@[�[$|g��>�����7���^z��&'=�e 	����#t�������[so��:��[-�u�(y鴽��ߛ����ё�~'��2�=�o����A$1��Pv!�b>�n ��N��.�Ee��_�~A��v�g���J3X������/�O� J��7�ī���ȧ����a�� r��F�6&6J�V_�?�\6���Z�Y�����m��%^�䋾Gq�Vy �1�:����k���D���ZM���@uWw4h0��Zg]�{��!9�� ��Q��*B%��Ci͏��H:�������Mp I��#>�C��g�h�}B��x��%��@��<���ٛoN�LG��7�U��B;I���y��+��fʻ����?��3$���饣B��9^D!�4i��0XGv��oc\�l�jAs3���Y3\�>{)B�3������¯^�ԩ�c������A���u�o1��.��N!�;�7�/ByDfN1��ݺ�Mp��O���&����U5J�gz��l�J���~FI��H÷�3WY��H(���4���E3�����%�%�~$��{�mLu�si�!2�4��a�ƪ1�s[�sj�:�X�"���>0��z��w����5�]����5��1@�W�����L�9G^��%���N7Q8L
o�������3\� t�������q�-��Z��!lk�RDS,�E^~*��_��N������,2�&��^��,�lKB�)���v�m
�oF)���oj��XA��~�^b}*�0���a��|�;��g��"| �+q�"삮�c�y��A����}E��|�Ѐ��=��zj =M��;~���jW>;f��+���s2D�*\��z�y��]�����I^�5N�\6��P7ݶ�5�J����%��m�Lr�w���C��⻖��z��g�^�j9_t���b]�|	(E�o
Dneqs:��je�����z��&�r���c����*T+40�-��F=6|b,,9�{N<,O����?�VV��LC�?�)�;8�@�aNl��i����6��>`\;i��}�������j�ehhV������j+�h��a��!ԩ\�iF�&�_�gYY��0/����H�*��;7ҡ �w<f�J��?==>ګ�pJۛ��P)=�S��֒�V��J@Q����5g��z_/Q��b�.Cqg�9��*����vH�j���T�l���W!��g@���V���)�XN�bO��0�V0��o�l��2��|y8���D��+�Oʅ�D@"�J���c5�~)����c|H(�Mz(�t H/bϴ���}�I1�����5�Uw�I����ޟ"�πt�M<�����h�P������B��嵩�u�Gj���uD�Z�i6���g{}Ke���1ޏ���{9��0gW2D�_���bء�7e��|��c�K��	
����w<�cè�
�e��z�wy�ho<?�d��0��sjHc�$e�n��Rڄ�>�`sH�e}����"�D����"J��.Z�޴Q$xD\M�/\WR�j�<�U���ǖY��A�����2�Ў4X���xTi�#����\zVH}���=s�Ȝ21ņvy�ϥ�8ch Zwk�&�f0jn���Ӌ��u��l���ÐZ�6�����Q��k@L5("O9��ڣ!�خ�_'�����b�`~���Q�v<m�:M�'Hށ��`���<�B�x>=���yU���������R"��$ݷ��o�%�-�6\C=˥߃�d�ତ�h<������av dJِ�\?�e�{%�g�:n;�gs�f0�'�6 ��1!9z�<�!3�M��T��V^P)�")�?U��m�1V�Nq� Ĕ�M(=jJ�����eԕ/z>o��d	��������5ZP��+I�6�c���6�����D��8�k$� 6�[B��f��]ě��rIr`�ځա���^בx�>e�Yy�G�)�d��C؅ճBk��=^'�'vW�w��:w^V����2Tm����Lܙu:M����C䷍���Y�����vݡ��M�L���ڔ�`�*m�R&�K�a�2� 7�D�t������Ų�1Hj�Y
+-������3����5k	�h�@�<|�	 ���v�����H�p�}�n)�(��;��5�:hXZ�ZQGI����k�;�)����A� ��Y���=��"�o�ʋ�|
����͡���zm��qz�<C�����8x����I���l����2�Ϣ�
��A������ߖ�x6�䫉ǲ�1�dh�>tlv�E���[N�_@��m��9(ÞXF9���3I�_������I�R]�pa�c�Ȉx+5��w�:(���D192�8B��Na�K�기	'�;��,1=�<��s�F(V��*ԇ'����f�c-�c\���5r�\˿��$�/�N��#Q�f���2J�w،����)�^C�J%ʇ���6W��Ge��|Δ|����n��Ҩv$��_�[����U-��5���?����Ϫ9�`a/��!�-N����ֲJ�j�@�2>�r�rZ췠&0�53_��l���I*͂2�!R�J�FXQ(��s�_Ԭ��
6�=�����_v<v[�t��t��QbԶU��^
��b��P�^�W]RW�6��ׯx^�H�:����s-�"��u�!l"IjtcATm���є��]�^pZF
OV�םL���*U��I!��%h������}Ʉ���Y�*�r����팬����:�f������E���0���8���$h	١��Z1ǩ/��d�u�4ԋR�E�h��!��H�bC&�����Y�c@< ���Ȍ��G��؆	֩�2 R/�fMt����0�P3�hg
y*��qQѦ��u܌Չ+��H�m3����"���y�_1{K2��WY�l�ӌ���N��E��b*�\q�B�;Rv5��C���C�,��}QP�"M���v�-s���q��5��=��M�ȧ��Am���f��+�Q]b��Հ�Z�g�:���}tΓo��3��\ 	�׀�x��H�yp�H�񓹭�l\1wm�ͬ�m�a.Ì �^��>�݈�= ����	R_6��mvhu��.��H��"���v$!m���^�=���Yw��l�Н��he�����ܒ	�d��s�   `�O�D��! ������'���g�    YZ