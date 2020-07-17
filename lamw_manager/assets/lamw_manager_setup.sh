#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3900580203"
MD5="ef2a89b424216b2f45eff60f38806787"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20716"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Fri Jul 17 15:55:18 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 160; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j��}fK���nU��ϟ���hZ�cagO��҂6cm�[�(Հ���kdh[eS����ej��3Q� ��_�9.�|���A�M�B�EY�g%}ND�*��*���%f���1��V��VZ1aӯ�%�;�� M�^��Tъ��䥝&��I䰸3nQ�^-f���t��W�چ`H0��TNp$0��@
:J����"w�9�Ϳ�bÂ1[� 2�M����d��B断H�el��{���'�+{*`����˶2�x�i��̈~ ��S�'� Yබ��i���2�zðH��$����Ã�B,�Bh	i����ZP~�'�����h�'��& �Fqɍ��Y''9�GcХ	+tX�ź�HE��uO8ib|D��<�����cu��P�����T�5f}l�g��R�h7-DP\�Y���Q�GD�܇O� ���r����R����xðt��
�����P����^;*�$@q��v� ������M�h��f&��֭��@��Px����f,CN�:(��q���S]oyoΤ${��G,v���L|�6I�w�R��w{���f��E(��sN�$����U�,1P�Ʃ�;�.����՞���l��-���Ii�)̆� �F�ȭ�w,�����\�3.n��˱��4�̕H�⪩�{z�狥���Ax
ץ%�[Wty1T���ˇ�y�\ߞ�R��eu���hQߟ�%���Ad�c�~JӉ��	����+���
���W�k�}�^~�(@Rt�6��y��~
�����hZo-Rh0l7*@�9n9U=3�T9��C(��u�����i�؝�0u2C7�)՚-L��٫� s�N~��F�AC�j��XĞd�-�@�O��O��cC7�sw��!	Pl�=�L�3����WH�]C���N��[�Y�M�`��*��_��'�P��0�'`���X��gh�E oQ@���YؙAF�ʒ{@MC!Um��ĉa�����P$��9�������*�jఒ�+���DlήF�*(#O�.w�����傞������4O��V1��
"��/E�������pn�s� 	��	�A�֯m�M�l�/�T{�>	����B�n:��^m5�����Z�Q���B�������}��Xo����Vm;B�n[�V�d�"N��7�_���;#f\!E��¼[c]�\�&6�E�Ph]������(�ћ��0܀5:7͈�D����׋���n�щ����H�U��[��j__!�7��;�w�X������ڽ�N��^�Ke�D:L�#������q����M�����ja
k�������V�h�Uw�܃+>�	����O�aV7���߃�A;���|b����{x�h��0T��;Y9�w�M��aq�wb��a��D[�P��C�@XB�*i o3Xޔ��
�]�2������Ѳ`J�D-��ew���<O�s҇
UǓ���Q��c9O8٣E�����1�����W1����1X��a�9�Prt��Y��n���>?#�˧����l�D:���1��s�t�ϑY��8�5���ή���u�)�i����)G	�� �0�����Q��T����,B!y�c�����q������O�����ܥd��Ӆ�����4������2cF�R�\ҖՀ}҇I*<�аm��TiN�zp{���\�	
�w����eim}U�}��Ւ�>q��{}��<%��%�Ep;+,��^d��c���':BZ�FJ{7_��^?�ŲÎ���$��,�lsı�zt��8��3���-���O�Mb��_��#l5O"[o��ֽa�l�I=����J�~�ޟ��~��b����N ]�d��F�l�-	K�{����̫߇����@P�P�$̂2�X���'�N�����Rn��ϗY/i���no�E9�߇�ttw��O.Yc���9\)%����h�#ĉ;��9L�ε��_"[���B����}�s%�\$N�  4���W^�D=q-��ݐ�(�HS!d/�c����k�t�*�{�
܂~J�>(煻lo��dL�6=��
f��_JK+
1�--�^L��g�)o�&Ns�?~-~����Z�'����Z0��"o�a�z[����3���V�V�p�j/���xj�iM��%�ib��HP|������ea!�.�j�b�@�D��jU�[&�� Ct�^��j{T���B�<	^d����A�nm�	�YCH��&V����� \[���}���_��	�N�e�ؠ�9
���U�[Т
e�f,f��H� UNjC�/���17�>�n\.�vr�S�v@A��%Uũn�Rb�xG��ެ�~c�ׅ��0A��<���	���m���q�1���ߚ;@C��ԛSa[��1��M��Q�B����h9�v,�����cnyW���a4EYrj2�C���Ro6�]��Ǭߍ�-.uTV7��e�W���kEf9mʕW�0��n�� _M�o3xCY9��Γ�$&�=gwJn�S�|sԙ!$�k��ߋ0����ˊ�7޽b~�{�J]Ӧ��������&Q�(�.�D���fD����`Ѵ�zw���L�7�� ��D)���B����p5/�bE���X!�q�ο�����6��gn���HL�k3Y�.�{�+�X|Iy��G���j0|���i�E�{ֆb���{�=?7�̌�4Ǩj�g��ݙ�*�%�Nu��zE�g�d��C0U|�U٬��f���4/U2��`��V�\:�`�N�9���aj+���u��}#��� �ߴ����LLIH���
�9\y����
$���k�kC��O�6=�}��{�8��"f%�Ϯ�	T�9�~�Uo��B**u"v�&���,�CJ:u:���0Y�[�})�gȱ�y(e��"نQ@�i}��Py���Fx�q��鄮��>�5t���Z��	m�F��0�Ke.����Kyh3 o�t�D����&�@�o���~�ԟ�-iV���:��Ѥ7Jk�e�*�oB��Ԓ�|"SNB�5��H�3���p�5B�m���-pذ^��{���4R!R�~�4E�������b	"Gv�s�c�]�L5�ۂn�Q�� J�2Τ�8R��Z����O�ذA��5;Qj��>�_X�G�1l�|fLU��T2Q�� V3��	d^"!)[�I>sI���D�8	����?@Sv�*�%��K'���&\�gQU�ƣ*��A1���d8��H�zwX��.F�U�_�������ZST=�����" `B����&������5�������8yKkO�n�D��);�T����hXJn(F'�M{���'|u4r?������71R��P	5!8��U�9��u�,��VDC
���}��B%�dL$h0������p�v�$�0s@��k+).	�^~�Y�A�����X��wӴ^�:Y~)�)�%[�܉-8�F�wB�Z�N���]��5cy[E��U�su+����=���͵��'�����QiVCH��j
�9�~�2�Cױ�?;��K=�V�+b)����5k|`������|�h�p"e6���*aRx������p"�O|�.(��Hm�`}o��J62j@p70�w)������<6q�S��%�B����=P{-��0J5k��8�$j�@����M�6��!�̫��=���@�� ���&.���յ��3�����1�UmU�B���2F}�9W�
���]Ԭ.pտU����Q��3�@��4?�U�]�0���N����卩U� ӗ=&t��g�N��{C}6u�O��}��	�`�ՙv��񘂱��'9W��텉S`�������*�2=��p0�[���|U�p��D�$رp�O���+�Z��4b�u��J[���}C�V���X������Q�Ïx�D�&��Ra+�р�|5�s�w_��?����Q}�;�Ի����Moղ��e[b���
\Z���rWp�ٙ�/5�S r�-�p������D�t��I:�,[A��6X�C�����GU�R�k`U��`�Z0�1�.�q��m�;���e��RL�,^Koٙ��7�������$WG�C��<뒡��W&����0��\�Ҳt.����ão�ٖRh&���G�P������ydŖ]>�tZ}_����wl���z5�?�	nPn w�D�n�~�,U�o��L��03R�qF�T�`H��8l���d���6\��R�>'
��iz�,LR�L۶!:k��	�"�}_Q%���u������v�<��
�pS��Ia�h�h��B�7��.����Z��-2#��d���PcI��*!uA�����T�&����u�9�Ⱦk�{�\#(F��B`o�Ŕ�c�y���ܷ��8�6>S	r[|�^�}�KO�1���)��N�&������'P�-��m�L�'P:*�YSQ�r���Lyz҃c�@��
�2�'�.=V)q�}�'����� �#��ѵ8�KyK�3g@X��H���f���a��t�4/IW���)Ff������ �$X#/W�X��h?�,8�0�����&X����Q�Y�Q{Z��o"$(?�TO�Ĳ�?���澜��y,c�/�T�ߨ�m�FGȾ�Hgs���w�n/ڀ�_b����WBT|M��S�C����v���4]��=�9��I�}��6�(�ّ.���E��(��ۺ^��'��K�gY02�k&}������+�t��c�������R;�۹��/$E��t���2��4�Pr�+c�����τQN.��=$Ve���dZʑ����	ZA������;ő�l#~�c��vё�d@�I���.
��S�>��:�/f�����;�Tϼ���g*֡���)�Å�y V�'N�#�d�o|X�2��� �P��9u�c��Q6	.q�ߊ.�>�L�
��_������J.�[��5�RG[�$im쁬x��]՝�ni�� �L������^5���%��-#��k�û�Gk�#�.I�z�D��(}��b�l=v���W�',[* .PE�G��׍��;�#�4D�<(u��F�&#Y��K!u'Æu�KW}��	u� ���y��X���ֿej�\U�&R�KB�݉!T����� �`��]���>��1��˕�yu��s~�n��i��sw�Nt��qi�p�9�U۱���m*�	HS�����E�d���Ν8��eź���M�_�����U����D�;� ��D.�[&���7o�C] ��͕����EX�d*��]y=�V�Cm���:�;����V��w:ϔ��4�#	 �16���j�(Oy�X�.e�y9�K�O�O�~�� �
���av(\�q��I( 5&ȟ��:��Uz���-a�p<�8���������K��.o ���U�hnw�8�z;�M?�o�������1�j(��)V2�k�'�i�P�)�Ze��{���l+���dUv�}��1��!rA��b�hw�A΂Q����Q >s��ub廣��4�0���G�B�8�l�,U�U%��Wc��4���mN����5\-ܩ�b�"U���@����Ӑ2��38�T�����Pˆ8��A.|(T�ŎC�4ȝ�)�	����}d����O���9ju�qx��el�6t7�,��w��^�'a[�`��H��~:򬟘2IEcҙ��l�#�e\<w��sR��,Q5I��~�VX���0���7�4�Z�cV��� SP�����;y�L�Χ��Y��H��o�ۄ��giZd<�Ƽ����+�@Jg����6��F�\�o�G�"d���ᮤQF��B��V�o%��b/��^H������
�LG?u⊎;�8v�||�a�x8���y��I]���+��7s�B�p���@M����d�ΰޫ6H�ȧ=������o?�/���o�T�������4ˠ�=�%q�����Fy7��k7�z�Ƶ�\�hD�]����tz|+l3�*��|��[�9��x��o�i��T��"��7~o��TJ�[��H��;�GGu-�=%�$��\d��J��d������r8�X'YP����tEQ�sx��[�4D��ү�ݓ��a/V���$�OI�/NTkl�����z$Q�^_e�\�DkX@���x���*�e�-9�f�wE�ݪ.
�-���A��A�ywR�VJ֒n�S�;�",��!��`[qO��
�_ΰ�<��
Q�@2�
��i��P���nP�8�ӺXf$��DY�k���ɀhC*�Y�?�CD��kΆYL��r�F]�� ��0��K�TJ�V�~��,�B�o�B��\|J����[��|.�\�8�a�)6�լ�`����U[T�� O��FH���<<�&�U��e��I )��������
�̇���{
���V=aε(���'x��,wTɽ�Rc�����������S�-��_�D� �]bpH�1U��O,m 5��pЬ~��ҲL�a����|�W4��˕�7�H��<�t�X��&��I,��/B���@��2��c�����-D�N�NLժ�RA1���P�a7�h<.�?�A��U�K��iԉB��q��#�ͧ�;hi����� ����%�0��U�}�9����B@����������k�"90��(��㚛o���uQ��f����[�}��-��	�׆�n� ������P�x�2�&���}Cs,t�^��=��[���q��R��d1)��%�Q�0m�An3�C���|�D[`:�4�� ��AKo�ʱ�K�3�4���6��Y��/k����zKc	j�q�$-�p�#�����Z|��|z�����#\�Y�bD��S�Ġ�(1���s��d�o�n�I!�~7�U'b���soY	b|�q�4�^"',�b����#>,��I�؆�	��;������N�R܂���-�k��[h��(f�B�d5`|�1���������:x?�g4z|�t�+�����g�v��E�
���S��5T�Ԝh���χ7�g�L���/�?���o ���(����ͻI����"�,imh7�kNmm�P༇ب�u�l*f��ںz�����= ���^���[3�2"y
g.Μ,V�G�')�4�l �2,���E�a�������+bL�>�l!�y`a*`�'㟊��~��B
+^'e32;1���q^��.�Y=q���i�T�{�����(��峓��g�= ���z����#/����X��%�k�u���9A���KߥE<��s�˩b�hb �+ň�]	�6��;t�$�&@1D7��o{��Tsʪ�Z���Ŝ�o���᭠�m΄���$b��?��f0#D��7@|]�@��2Q'�5J<��ަ�}���Pv��e�����K?;N�
;,�Z5`�b���Hj٠�X�������Z���.�73o��q$#��d<xa� }{��FqM��O=���w�\t�ؠ�7GY�`=�w�TP�8Ul>�a�F��9�	jo�Y�v�A5׍�GƮ��6�wg����ڃ,Ü���N����l$�;�!�V[Y3 ڰP9�nb_��Z׬��h�!�hl%#�� �[����j<��
ܽI	⚱f���VE5��!|��or���Ro.J�$=*� �S���H2(�?_�e9B|0�
��/%wD��nX_N&�R�>�����4��a��!�p35�|J�?@���*�s��|"�z�Ƕ7#t�L�l��Ɖ��k�kP`����Q��8MQ�ߪ�Ǒuˤ͋�&�ࢆ�o=�d��� ����c�˽�'�Cx��w�t��C�)om��WD]H��$p�M�0�nD�Q?ꖂ��������$�t�[�a�|����_���]3��p��L`���9�t)�m��v˲��K_)C�����[��f����W�{**�����jV9V!o��8��f`;�%(�;��C,&~ sF'Q���Y�S�湍GFL��,����a��r�~�l�q��;��\�Yf��/�^}#�d�έ��q�a�	&j]i*���Vt�!�(��֡F.�I�JhH2���a�-B=���I**�=r��-̓�x7d2sὗ�tȢ)	=M�X'|�0���w�\���`>�M���]�c|V��4c�gǁQ���]jQ�Ub%���]�~���I²;	8=��8*]7]p3%���̏+���b�œP�c����L�Gô����	�OJ���n�q�������������5�� ��n%��j�r���;xB�yw�]j|PwR�i����H�4|�+�����ҥ���o��z�So�_=�:@+?*uU�j�|9�gv���t����6S�l�U����$��~h���W��q�Q�$C��B\�
Y�����'��IdN8����U �es�-���Wоh漒{�B)
Y'pK&u�+��a��nZ���I2?��U�"6�T{gcpC��^OXp��2)W�N�q���~o��#+˷1*_*\+�Q��mW���>�!����hП���T:��讨��RN%
��C�6A=\���݆�vS߭�\x�u��"���k1B�k�h_0��� _o�����(K_]�"W�F`�{��𝼋��P�����M���߲���P8[�z.XN`#QuY���-�TZ�)�*,Sv��H�o���ˇ��hA� � �$����Kbƍ��ՃǪ�|�Y�O��]X}�У7O$��ʪ�x���@�/�1hq�kU�ǘ���s�-$�G���]z�	8 �PKnjbj"�N�r�$ l[��ۆ$��f���,o��Y8���P|F�Nԓ�!#cSìm+:���]dx���7sI:s�1v�Q��^zO-.�^\�#�+ȵ�أ�c�7x��?+�5���7�{gK|�m�g�;_���Z�Erj[�AE�^�*Ӣx/.T��p��G��G�[bo�+�up]�Mv$*ao�~����s囁��v���=�г�Ӏ��Ĭ�j��^#)����d�++ga���iaKF�V�ƈ�ѡ��81��9��	��8<?"Js��3;�P�I�p���g`�<��*��,}Z���G.��nǞW�^>�g�-�ӏ=1q\�� ��"k
��獄~b�ߤ4Q���7^K���0'F���]�D[�;mfg��ENKPO�+,�
+@μ�fr U���yH����P#l��|OVG��;���&58v_����z��:�	m+���U���
⑁��d����!���e|[4����E���o{G<s]��"�9�t��(���4	������	�8��7�C��>�Vħ����ҿR�55+��]
哻Jإ{E�Gv�u�(�t��ҿO��l�8"�T���ʄ��8-+��	>�^�6��;:�ᵁ����AGA�T���Cb��q8�dahJ�x�&L��w�Zw � +��"��3(W(fF=��ި�p�o��~�@�.�9 ��k�E[��n[c�C��$�M.�.؈0�YZ�A+�I:��
S���Þج���/���<�AmHH�%��
�vBltjr�~-�X�����u��*����P[�y�r����EC�����[�9��^|��K�={^��<,����� �GT��Ӻ�k��`<r����p��[ Y���l6.ԕ��W�|p�|}Y��9v<�*���N��
�>��r�k�Y�B�T�p:j8;�0��ѽ!T�;�ѹ�j�lu=�A@,�*�߱VP��¬��w�O����u�3�u�
}��	G���5��Z���#}��XQ:�Px֞�&��N����ګFY�5�����r�6[�Bԑ˃�I��j�V���*]���&��*��BH/��w���SsD�˛.�D����W��΂�T���<��j�9�[~+>s��q��)�ȋ����'�$��\8����J
EC����8�� Ծ�sN4�P�޼I�[�KW���:�<<�<)�@�t�����a��[&�+��ZQ���@��#���}�@]��aa2����i�$�{m���8����`��G�x�|�:I�\߷#�|3E�%�P^������7���Mo����}G��{)�3$�E�w��y�󈭞�ޏe�4m\z�F@o��=����w�5��PAA���xҲ�O�k����:u�[k��I{#S]0��4�*�Vex��^�s��aM�;� _��aix&�%��ڪX��^�����Q}1�Z��ӍSs�w�
��ۄ��VR�tIs�yղ� �|	�w�on5D�C����q{�xֆ�U����MN>b�u���$��gЈJ۲E���]��J��r0�¹&�) g�G����W�ڙ��x���J��2��ί�:`" ��7@m��Dګ�Ŧ�ڍd �Nx�oשAy�OG��S~�0��3m��ϛ�שj�-���C��|��m��=�r��`��d>�E�R9�Z�����|"�FZ63d�:�%��)�+a����=�I�ϻ늃.���B���l��%	{G����Kk��&f�o�^2]�-���-�ة�P���~�x�� -���x#LJ�`�������v������d}3���ǫÍ_]�~~;��zZ8���'������*ن�۝�B�<�ڙM�G��>��9�w��+1Vj����MXo:��u2��$�.s�3��Շ���� ��ô|�L�[`�N�i48��ѷ_�  ��=͛�[|]m��YUwѴ�% ��7�;/@.Ӟ���[�s�q5O��ʊ��z6Ⰲ�/�B��]�m�6��pt\G�����W�ٴ��52́�$���yc�+������X?�mz-��+��Q��;�wq���>�۟�?�<��䦤]�@��̑T������a������hrJ<t/�n�:(� [��L@�g7������~O���Z��E�q�L0���{Fp{L"��	�ƛ̑��z��"G`)"�B]�6M?�i+m�K�|�U���j�HSF/ͲT���e�ngl7�^���*sT��q��?�L��P\NҖfX]w�t�Ϥ���i>��ِ?�t��uԓȺ1�<tb-�l�p*�7�Hx���k��r�.o=�����vθ�� �?� iEX��3�*k�{Jr�NS�f��&Ќ�T.����8����l���:"���!�f�5:�5Ny2�y�r�ɶ�V��1�zp�$N�@c��L��=�9��Ņ���8z	zmf��~�:*��!P��wdD�~'f�딗�-[�
�s���0n�6�v.��a�Ļ<ÌV��eO�6�ң�{ᗠL$:�=�W~��F'�3A_(�>����Q�c���HZ.{I_��f/����7��#�cS���5!�4CV-� �F���4v�7��`K�����4S��8p��$���%r8�xk}�P�
�n�:V����GP����G�����e��"�}d��![�ߓ�|��t&��J�������J'@/S�ܐ�B�$�^�Sh��"H�����c8��+����|��WPn�)�uZS��wAJ1X����oh>߹K���7�H7�s�A�����u(�'g���.<��`�c�	��ǥ@hW�-������$,���
��<YÑE��J�&1�k�I�����+�w����"É�[�\ʙ�rc�� c����17� ��a��1-��6�}Y"(�k�AS{���X<Ṳ������ݶ��|Jʟ�|v�LL�w<`�PՎ�u��h���1�H��v���+�Q_�nEj'`S��V���;��5��Ց"�b;�� ��8�[p���BW�w\$i��$*�%aJ��Ρ����!���p��͠=jP�ك'�U8�rEM{o�G ͂}{0���w=\J.�XdR�r7Q��
n/ɠ[��*=п:TW}��|�;4U�O�Y�E�)BZ�.�Q͹�PS�F�8;=��w�-��=����i�;���,���1��2���'h����smo��l���:b*�2�����HIP%9'^�,��珿�U}��F�V74]ES�X�2g��{�x�e�˹\=���`�֋m��K e{��.jr"���=��� ^�_߰�I752U��+#1r]X�r�
��t��S<�x�
f��8�XhWJ������v�On�zc�����i&�v�Ϝ3:�u�+�l���T��'Ub����
�f���{�
�yH�Z��C�usz�ە#/��R/����vk�?b��-��D8�%~ض��"̨����� ��Xީ>s�ۙ:,� X�R~&}� Ǹ7�g���}�����b��Q�o_#v<b���оߘ���(:n��D��L�|Ci���?��;�M���'��}x�c[�~y�hc���\��o�ћ�m�ؕ�୛�B�,��4�iע�3���N��E�G�l�-v)�x�8qZ�o����y36��8�y�	v' ���q��|0�L)�'�c���]��0q�k�{g$!(lK�=���O�?y5*�B���wr�Au�y������?%�0��LR�$�
>K�I�/����L�J�1��n�lu�����[[��)Wת�4w��+�1���\���:_����%m뎠z���N����u���>�%�����T6�Y߸�P>�e��#~�i�ZS��K�U�xS~)�L��W�ëVu�3��z�"5w�fc	�Q:��=uY�{&S(�[2�8��5;�ɺ[ze�n\�q���+��A�84j���tR;���D+�)��wѥB.�	�g�V3�X�\��ѹw��9�n6��[HU�H����"�[&}o�S�N�RҶ����M���b,�h�B��Q; ��Bמ����c��;�5X�(�
"lq�G��%M%1��M�^�ʿtr^�)Ў�� \lfvt�1��4�"�`���_��y�%v�2��/��.
�WeNpE�$��$�g�Q�\�i�{V:�H�o�������iel��q�2���Ӂu'���F�*���ה +g�����E�T0���1���4�9��U�Q��@����K
)�U����6���?<�;���@���}�������Up�Ӧ�8�8��[nt'�ZX�����T�H>J����]J́��.b��9�W�hCWk�}5]�GX�T���j�cM��-��pv Է�ٻ�ߍ��T��!IF�j�� .�W}F���dR�*�p��%����C�sТ]�L�[}���S �f�n����Se�5-�#�~�6"c��%=�����Gxo~���ר,h���f�ɘ����=���������8ϊvl�muVOz�cqT�H��ǉ�O[E�7�7a��A6ec�@�n^-vIXei��<�j=��1d��<�T-�qeY�1��^�+nm�t�e���Vf#�%Pc6�7E�i0����}W�n��4K��5y�kaF���!��6�)��"�$�k����kfS�gܻjO ������%�m0B#�R�tWdL�d��iPe�fњ<������@"��%�R�͌,�7�[KSC�HlCH�a~�]�θ�Ez��:{�'r��_B�z��p)���EbI�[�wVP?H00h�^�)f;\?U׿�����ʙ#�[a���(����w�ъ�9y)���^����9�b��)5ʊk��?D� նk�g�BLYC��О~7�x`Є|�>k١��6̲��Ŷvs�]U5X��C7�iT�88N�=�a�J���L��R&8��H���Z|<Ɩt�2�b�,���F%ޒq=9�P��U��:3�e[�m8��m���k[��,��]D�$�s��M��/37�=@h;��V^�U����LA� xf�!VXE�`���]�M֏m����n���['��Q�AN�Z) ��@/Z�D@c�1��'ƒr�,�V��7�&�]������g_�����:M��K��.7��Т�_}�&���ObN�}u�Q��J��O�`�nQ'����w�֠�emY�*�F�)�Py)jR��:1��V%�t�lB�Z˷�ͭؒ��/*j6⭹�۱�]yͲ"a�{gP�I��xA=V��2��o߄�FZ��V��qu/�~t ����װ+DG��0&�4f��Ȅ�٬#���u,#�uם�5SJ���i�����V�w��3	|�W�l�`�zB���x-tqd��D:�D(��u���j%�^���j�+��
㎸�{_���N�ǵBF��?���N�+��̧I(,#N�d��R�b�^A�0��|g(H[�s~U!�:��q�P�t#H �Q�k=D��88H�*l��,����[s!qE�U����w�(?��s.�S�ǋfHav(c�ș�+�خ,-����3���Y zN������%R�ofkKD+����Ad�؁�D.s>��n���\P�A�������E3�=l���������4���6Yp���Aվ>l�U ���[|�zk��<�Ƴw��+�W -��ue��A�	'��At�G�8�B������C���"~D���#���%�t�폆q�d�����JD��C{鶯���:J3�u�?K�@T��σ�3˚������"ء�ܮ.Q\�����r�|SM*�;6)�J�M���WI��x<��T�AZ`�L��~bڞjgxؘ�V�P�^�$�.M��x��[�L[;i�?1�ר�?�pnU�?V�4sye\��(�`�l�/�GB��Ne�R����װ��+��3x��?�p��@u�b���"A����hsz���ä�Iʣ��5��Sz �F�����:H�BW�so��j�c�^�����w��j]�kU�`��n�A�yӼ`�PظNu��Pj9�\�Z��ȩ���.���98��E%�ة�\�\�+T��in�x�!cZ��.��ߺ�ی��M�"�y �9b�g9�_Vc���T�8�ց{i�F�K�R�����ܟ���,�X����!�	�#&��A��{�w�.{Z
�=��:��VK0t
@]�hp��X��a:��k]0�ﮦ�_m�JN}�����"��E�h�p��3�WK�D�jr�)"�A?����լ����'�g�:�ڲq�WN"�����xK=�no�.�LV&>�Dz��V�D��PF4t���$�R�dʣ�:��y_ d�glB�`�h��7����s(Í����ԥ�Wi���^���ME��鎝��b�>;����0��.z�',\f ��4U�U�Âl�� ���c1X�{5��� �c��δ��NuoA9��AŃ������������u��Cj~�G�|��ɃQڿ�k�6���21-���(W����حF|�j�l�������a�O�!�3�|��H��V�Oݭ����}��Hm�T��\��,��^z�9;�[b���Q��R�|h@r�n����8�����{��6�ލ�6R/yϖ��Ŋ��'$ c������c��l�H���W�#"�#�ub�W���E"���m��b�VBثek�!�4�#�l	@{	�����Ǯz:�}>�����cHq�(t1�.���o_�u��<hc�e���q��0�YQ����I� ��Na�4��a�ķ��w��()U���s���x�&����د�u�E�Wؾ�������f��[��
�E�O"qbW���M������}D���ܬZs��Q�d�5����s�T	f�;����煨�sɩ�޴J����o.�`�1T��Ӷx���
3/�S�F���ٝ�����ҭ4 k;yM�w�gP9g����h�Ěp��+����Y�J�����u���2��Ӎ{��N-N�o��m����w�-�QG$�vu!=�g����DtG^�H���.ddQ��-���`q�B!�������ޒ��!x&>?jVR�P�8|Z P��]�勜顂�U���!H����\�O�Mܚ~�%,���A7T���1>��,��֬��9۳~��׻?���K�fͱ���0�yi����jU�Lw�^��Q5U��A[��t��=����J/W����}�Ӽ�	C�prq7�bM�)lvAN��a��t �+������J3�@��9�	 ]�U�?� l�}(� 0c	�S�����!x�f�44k��E�tЫT��b�h5X��pe�3��?�!Dgh�I�i�����ۘ�&>�|W��l��@	��KV�*�>BGT��x��	�u���������1܍`l�����eu��Dq���O��8 �:1�7kJ:�?a"l�������#]��X%T1U���� QS�l���-�n8|u�&��&�GKS{I�}^�dW��G(rl�w��q{-j6laznaf�eX���kC�f3J�֡��$����)�晑��ܸ�4�4m�X6���Vo�-����G�3!���R�G*���^���6����|��>���=���~�!���C��H2��拤���m�z��Ku�oAc��׌����j�t�N�(�e��mV��	w��JH~����^D�
�<*&�p���	�r%�]ŋ��Ң���͌���O�5O�ux���n�o�榇��R]����pE���^,&�cTo�8����CZ�(�Z�8.���n�f�N��Di��Ũ�Q� z��@�8�2m�YB&Faf԰J����4�}��+�S�Ք|��DSz�ּ����ź.X @C.Sk��z���@�Ű)Lt*3/���c���� �x��B���*���y\��������?�s���U��8�K�L���ɧa�xG�=���sk�Ë��2Z/�PR�� �1���x�{a���I_�j��w��Z^���˗�'Y����6aS.�"�y���~��R8v�T�pT�@�<�ܲʵL�}m�lZL���v.
G��g�,����դخ�#k�?���:g #��8�V�!�3����Dka"OY[˨Ƃbؠ�Y�3�(a���W��e�'!�]A�䲖�P��~�����f�����Dʴf'��T�-���䷌dSQh������>�^&�9ds���Ӫ�V5��#H�U��X���;t�NSl�"��'��-f�ai�i�" ��Vl��}��~��v���q�V�<~0�m�}L�Q/ä�ڝc�j���	��ޜs��Xɶ�N�@�'2̫�Ibk&w�����!x��*
�aŸG*k��Gp�>���ӃJE���{tS��w�>sh�lټ��;�$���H��Z>D����F�{Mҳ�N��g��_�,b-��*3��O��)ܻ�ԐU� +R}GF�j�Z�z�ʄ�?^NF=����%���3 ���\!�̳z�Ս'1�\f���0)������k��\��W
�2Gl��7@X��"�
d��T8˕�n��ÿ_VmC��<�1U�gEr~��ڛ�Y�~����x3c�"	tS����ۇb9�,���Z����P%J ��:lFhOpKۢF;��k>�큸��<m�h�$�{/\���)�{R/�Z�r���l�Ó:2;����.fh�o"���Җۆ{�A)���ĥ���o�ai�d�N����8�'���\
a�ܓ���ea;��p�:<�B�C�Jn�D)#�5kW���e��ldmI*�T�^}�UK2]T��r��|���vI@��y�mo� �����|��\EVX�2%Q�g���p���#kJ|��,Qg3�[f`�Y��y�+�.*�^���F�c�� �{����\�y�`���T��Ӧ�Ɓ��/$K����"N1'� v�P�M�M��l3�&������<��>�{k)V���Pu�����wʱӣ�>�=s��]K�
�l�t��O}��x����|ǖ43̠�H��X�$ʀ��?e��Qzۦ@�e!&���^R�j�cU<g�Zg橽 ������S��G���������D3z�C3�S+lV�6��x~�h��P�@��.��dj�K�E�p����&�O���t�.t�����떕��-n�ա]��t�.0�Kt�D�!���o���wZ����,lz���8�uPWf�d9:Șq8�un�iO\/T�PCG�i`J�-;m�k-���L����U�e�=FD��y���GY��9׋�'z�o�eƚ@�[�a8e�}m�#�������s�C/z�����S,i=��>�X>ӝ$}~���~8��Cy`�H���
yʥKVUK4v��� �=�� ������B���t�3�RIN�!f�=���d�����'��#8�Gՠ�O�g�5�|-�a[Z�"��t���X-�T����w|�9������]=[��-"��=��	,��q`.�Z����
#�d��*�
H����}�Q:��
ۣ�a,jV��m`�'��pleH0��>K7���3CI7�<B��0W}35�-.����|�ǌ�7��zE��ֈ�Uw���7d6}��k��%ۘ�͑(�OY�}c�w%���
��Z�k�-:��Fw�/i�C5K��k[7��P��:��&|�֙�jW?�.ĄN6O���}Dm�����Q?nأ���7u6��-�l~��:҉���w�ś�3>�WZ@d�Bӊx�}��>Uʷ�4��h:W�m��a��sx�Ypj����O�$��w�G��[h�$9C���7FɈ�U�=F�6������T��5�e1;�e�D�Ҭ���l_Ҥ�+)���*ʶX0�$+�� M4$��ь��G�	!8J\H��D�˕�Vo���U��70"�2��M�������t����iN61I��CE1xҬ�S�[ �Г�kkK�3�:ٶH�C�]��}���O�SWs�I��@>j���=�\֤��6��������^A����_W�a�@}y���R&��{L�gۼ���	����0y��_�n������p��s9�_4�p�ZA�Mq��`��G�*\����O���v��Z/Dy֕W�P��d��]�\4�R��;4pۚE�9D��=����4#WT&��RS�VV�t��F�@��ɥW�h�{�m� [֏$�//�h�:���<̨D�)��\bD�Z�i~6}H�5.QK���n"*�%MhЧqZ�@�	�7!�Qt��0n?I�kÀc�NղV�������nܫK�߾YЮ�(��9�He��B8��=� �x�&wK1DEbc���\�O�����Զ}��&�IFŔQv<��_h�	�R��F)����7б�G��Je��\7�/��Q����)��jB�RЂ�BF�&�Rutg���ud�o�}��mU�1��?ǁx�WM䫐	��&6���1�0Lh9���ըw��43�c��P������2.o�q����N���I�w�����^J���7��u6�����h�n��U�G%BBƈ����s���w��[z��z���p��n��Q�tq��祈x�i�A��W�1�H0��F���V�^k�@\ENY�]�x� �nl>'r�#�㑃b�5�lrfb텄�nݻ����p� Ժg5�4��A�~rN�dHyDVO�&%�M�XV��d��Tt=u�)���_���Y �cƳ��tN�;X1�fS�c����|�h�>۴b���x ��/&: V3�$,\������v����4�����l���=�,��vY\w`i@�*y��&p9pi\�PJ��ࢯ1��Kƈ���6tݙ��X�J�����ZWߜ��Y��iw����t�v��f������D��td��*=K�I-�l�^g�>&��2�C�(x'b?Fv�&���C��C��݃�)���d?J����{�����$L�N2	]���j���ʒp֒�-|`/���x���g���2`-)q�^Aq�]��AM��ˢ32 �)O�Z8[�o{8��Bh�R�"2�J�������Y߆��[`_`u��"Q(�\ރD����^�%CjO����dNq����78,���dY�G��<b�,��V�U�*�ǊL���uVt��:�Ds/"r�[����ӑ
!h5#^5(T��'���SF��'m5J�ƾg	D��[�9��t���#���"�D������x�iJ>�gd�a:�Q2;��b�h7����D�<}Տ�_
�'e�<�T�g.@s�4�U��~~����Oٞů�$\-����Ċ�o���5��ұ������i��UK�ý��c�rA5m���|�}ЦN�$�1�W5_��hb�'�v���}
�$
��K�5,��6�bq�G%�Rs�1y=��١�m�6�`���嘥�:�4l�K<2u�����bX=������]<�6<7���8�j����X,�j&ld��LiGo\���X��,"_w�q���    V�\�� š��ň�ѱ�g�    YZ