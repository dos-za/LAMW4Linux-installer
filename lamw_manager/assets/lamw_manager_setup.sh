#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="465891706"
MD5="68f1faff28b4e9064529f900b40d2640"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21316"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 14 01:23:16 -03 2020
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 140; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
�7zXZ  �ִF !   �X���S] �}��JF���.���_j��7.B&t*\!F� �V�� ͡�;P�(�h�)�+#���A���Bxƥ?�Y0Y��|sό��4��1�~�?6����! �'��� �_�*%�*��A�� ���1��-LP�/����e�����-H���a�-�m w�F�UL�0]�ۀ�G{�y���������s���[RNW��*�jҳ��|��:���T��cK���+8`å��.x��7G^`f-��2�"XB§h_�}�j7��� Lc����]�ն�X}<�)T��D�d�����&nH�n�[$�<���fH��y^��k��U�r�	s�Zj�L�ǖ|Sk@I8nFD���Z��=Y���QUc�J��T,(��	\y�ܯq�/�D&�V�O��@�xHz��=��
49 ��ŉuy�ׅZ1{�S��=��(1q`�6r%-�_���t�bķ?ٝs��T-�F�f),l-�R���[��|��Bc+�����������y�Ӫ����\g��q"8��t�^�x\� jD��5g����G�����&��2ZB�yN쏹vV�bZ>���[����]��t��oH]Ҝ45:�'��zʌ�*(
b��i���A�#�JP�G���c7O��d�	��.
��|��Ɓb@}�=����X��Fxnq>��Ҥ���*"@���[|�,�	�����ڄ$uf���#�U���'�5���S�6��l6�t�A>z��%�63�}��v��A���/ n,52m�Ƈ�T�n
��_�	���Q%/�ap����k�?���,�����`��$H;�zP��ք�Ƅ�"�ՠ:��;? ���j�J�?����{��Eǆ@0ɧ`����d���Ó�|[N*�dd�OX�0��s! ��i+!Q��<����������8�)�W��G�~��-3��u<����"���W�<��m�f�*�%+~�X�O���N �Yd��>�tl�K핗����M�$����^����m���99&�؍��f
�-��(%C��q���2�6��]?av��ս���o$�,�������7�Iߣ̨�Q
i�
U݂�R�.8!� �kE��(�>[?��Nm�A�v#Gٖ�N��v�ҵ>��g¢Hf/|�W�������� Hh�s^��������Wr��S:���FkͶpEs�Ae(/�Y[2_-�G�O�J������F��~�!ވ��f�Sg+����mװlUn����eJ���r����y�k��#LH��2���t�FR���
)0�e�a
�p��N�~�3�{�$Fׄ���	�DˀN3`d$�5b�	���T���5�}Bࠓ���KiB�r��TڵL�)��֐�t�P���?.7|bʆ����B:8��i;7�>
�..�A���7 C��_.'�ULi���I�\Ës�;���[�4���0iES��c-pK�k�`3�FM��70g{su�&�A,ۧ$+�Z�EWA�������^j�#K'�\����-���o=�D�&�`h��;XPr�L8}BX?���Z�DL�"��T	n�����$�V%6�dRv ո)��H͏���������6��I%�����2��簰����Ȋv9���Ll-Q�+�࠹�������IZr ,x�R�T^�t�im��u���Y�p"�G�+K#�A�r�;�4���S�9��e�h�Y]L�m������Z��Ӟ�Pdo̷j�P�5�܆����1`;����J�hE;�^B���3C.��ݏ�i�]Oy�0v8$X�@�cc�48hn~���?圝��O�F�]��'���)�)xb̳��qt�A���=mg�3�$��7�,�1���'�<Bk(�*� �H}�R��h�+r�W'pS�7ōX}K���n�{�Q�v�o'�� �D��xaJ	�g��q�[J�?+lP�I,�u�e�9}�^����'|�VX�Mh�H8nӍ���ٶ&|&V8��a���!�� aK^&|�G�� �#9M�ʺ�w,�+..��ŐK����	6�ȝ��T����A2H8��n��������칧����ëE��\A0|$��L:"��xL
�w�f�W�W0Ǣ"e�-FN�n>G6N�9{�`�P����QS��x��p����U�R� \�M�=��:�ѡ����A&�����@���/b��Ė�7�<ì5� י��=���}y�y��-�f!Ҁ������S���8XP#���#M��`o�̆�� pJ�:k��u���!�ٓ�7pBG[L 	`�v\9�oK/s�i�ۓv���Y1F���N!���,Cm�ׅA�@?D�)����YΫ�z.�) ;�O��K܆�k�ﳑ�f���Ւ�a�4�J�V�%��UȂW��ψd�8r�#᫛� �M	�zZ��]%G!.���X�^7�BP�ͨپ�@e$�jB68ߥ�W�M�+�L28�s���|�)��uw�q
���1^<�eil�c3rJ����Z�_�չ����-*��WA���!W+"���5ߞs�B��3�#U�P�`�ɶt����B�[�bkUQ���!�ZFp�C'Ht<�d�爂�d��'�%M��W�\��v"����ы`�3�b� ��uq
�'\W�4 X�o�͓/����c�סXT�E
�G��Z�(�p}�
X�}MA���l>��B�TBzIsј�qV^"�J<�X���A��q�]Z�ک�j�5��{x#�V|׫�R�ÊL�-����?������^W6�=�,Zf��C^�|�z��'�'r����s|�<����2����z[-�$\9��FO��޺�邪��g�b�����n��
f���eR;'W��@;I�C��BP�K<d^�[�� n�\�39O"U�U���iȎ�A7��HlN��!k��O���7H�r{bҽ�6Ŧ���ca����y+:<��l�kk�bn)fJy�����cuw��4�Y�RA�`O�ц`�y�����6AAa/4I͝�N���B�ΘT�Y�9��[W�{�+�$rF�I'���[��>�k���ځص�n��N�rY֮6=��$ɺ�Dƥ ed�2�Z�C�cv�)�9�;�T��������9�QC���-���qJ�̈́z=ߏ�-�U���q�ܬ�>W��ɉ�\�ל&!���ȵ`��Qs05�ך��r���Ӓ�NV�ROܒ�����n۪�*�\���9X�{΋d=ޓ�%��E��b�f��C��,�B?�
&�רW���̸`�u�^M_������\�d�s���|p(�<�F%�F;߁"���{��>���г[��5I)��jL2�Kf_��uIeA��hl�+ah�W��y+�l/w�g��W:�yƾ�$Y�H,WFѕkE��l("�qA%�[�%��-u3�S�]�9��:�& &[,Rhm�k���vG�&��>�$X�r|�e���Z�0�ڒ1�8��I:V"�mJs�i�v��m���>
��3rqź/J�/��ۮ�x\�/4���6 �J���Uu˼2�f :.$�5�����nC�'wj-��'n~�w�?rf,�_��[.F���>��N�O-"Ն�w���.���x�߇�!#Re�	{[�3�.�'�Ϣi� a�2D��1{�\;9t���3�ä2n�h�9)�G}��/�7b�g�ɡ?:���"����k�R06u��}"&t�̖�^�M<��m�t��4T�&;���_P�K7�߹E�?\�L[X~��
��4�r`��t�������9Xy��,������B���O���]�i��������]��Ԏ�4�S�~�M�������G��N]�F�a�2"�]��"\���%w�~�r�U��/���,���`ZUhx$m;� ��@\j�����#_Q�7������O����˾�shS��]Ϲq�hT�.l#IV��B�H�~z��s��ނ���ct}y���apQ���EϮ!�i���C�)p=�jMjv}�e~�4q��lM޲�ք���x��	�Њ���0���b0e)C�}�Ǐ�7�+�J>.�cQ�؍�Կo�Y���`�yZ����xyo0�$����t`�{?�";	���+�}n<���ۡEi"c��'c��AH��1��M�Ժ�K��RJG`E� "~��q�v��y#a8��9�~�^G3G$���� �o�	L�At4�]/^ݒ��^�'��O*$N�X�i$>��'�X3h;�"�x�v����3�)� �2I��ɸ��'�q��s��Y��C���M�Ġw�&\K7Q��f���i� S�95z����J��#Xץ]��*���c(߷
#�h��4s?8��9�9_;r���@����aG�Z.���ھ��S����4����q�F5��SM�Ҁ�8��٠}�W�dzj|l�(/ӌ��q�S	3[�[e��S��#vFl�ٻh���G?� l���b�:��M�g��B���>��S6o�:�F�2����!�f�맣����zg���!E�܄��p�~DI��=�	���`		<TGc����rѵ�).�����j���p�S}Q��틜��A��`3������}MJꜪ�<�qz�Mytݤ+�<�o�7�r|N��Ѣ�o(�R��rZA��rL��4&w�R�V��;7͑�2�|���
݋[��4ayM���]�V�l�Ԝ��r�>z�gx}�'S�	��=[�����v�j�\1�u�ugA�ׅ�5�$��'-�Q�2C�q�3N��͘�X�����l��b"���3�u��_҇��4�&�bd��PEL�!�zŷ�J�g��<�R�~����ۤ&.W�'�����c�� ���vh��Qݦ�S��ְ�$�]J���(��l?��O����4��+{J�������YU������]�����>7-�|ݴ!4pag�L���5Cҁr�*)�N>*�t��31�2 yL)v�1�'(3}ҥ�8hQ�N��ԡ�B� ̳*�KI� ���� �Z�Oi�)z�r�>���b���1�U�!Hq�����ߛ�\6\y�M('��;�1M���dv�����iqL����E���|�Xm"���G'�_�w5q�|g�!�����,.�^eIo.�������~؝��Kn@b�-���#f��_UHވ�R��D\t�ɯ-����4>@��L&U~#�@n	}�H ��c�ov��J'��"�ڹx]�!~]s����V~��6Z������{�e��/���+�b̞�F�ǭ�Q�ȁ�������n��h�xx��j���,E��[�)�C����� y�t\�!�2f�D�׳-/�ّ�z��?m>�4#������ͬ[���ɩ厭	֡� R<��
l	�L�Z�K�I��w�	E�����i�x����@daU���12�պ���9K&bWlO�+_�k/��D��{<�u��#]p����\��:�^l�vȖ�������)����Qt�=�
��4��6T^6��P��;�7&��vP��r;�F��D���F��q�n���D&�͜l87���Ag�8�qV�y��~�� N��&����f�C
q�0;?��"*ϥ�C	�+����9�����j��73��I�t]غV �R ��"}c���C�{����̹W-Z�OC3ۍ.����`S�h�E;^��OT�>��.QVv���T<}���=���;�rf�w�O�~������������q_�-2�>��-Ѩ��z��O�9�&?oT��j[�7Ձ ��¦D��[���ir�ϒS�DD��S�w�mL��r@e9
K��Zz�X�7��َ�S2��q�5p#tr���ՙ���+tX��D� f�K���DAͫ�u.v���5�WI��}ƕh!�O���zR*���vF0�uz(�3l�ydnm Ced��U�����*��K�֨�+%�&n֕"�G[<�~�\�v_U����,ol^�Z�Zo>t��!��N.u�Swm%�ux����K]��������i��IE���F�Oɗ��gq���������ωe�T�8�~�^��q�S�P�WS"_��;{���K͵_�S��5��l�PZ)�v-pGҸ]č	��E�w�0��E�$G�ׄ3�z�S�SjU6J��荓�����G|����{J�����EN��)>/�KV`����{`��JR�3��H���}�`�n�+-Oڀ-�qyJ��w��yP%D&R����FB�/����:���T*�.������+����*����Ԁn�֑�8&O�� ������z(���K0_�.���\��O	B����*e��HQ�8�w���>!�,�A:�y
��L�f��n2��'��tCK�Y�m��BD�P�I�,F%�.޻�� O�:�Q��SG������]�f��p��>%^�"��_�?�L���s�Ŕ!��bE�Ɯ�\�4zw���m�x<hR��$>�Y�z�OV:�V���@8U���E��t=Ã8�i̫��ߥΨ#ޗ��G΃TV��!���ԋ��-�x.�ذ��|&]�7t������8���t1]@��17�������3?�)k��C^q_J��M�NȟU7F�Jz�l�t\l�#C��ɘ<���o��s��f܁���f�-s&����ݴNo:8A96�v��zp>��ߌ�qV_�g�Ǥ�Cd�BuօlO$��͂��=�Q/�uX�(��V!)W���ľ&y3�:��ק��ms�o��i�h e @���$�� �٢kIa�~�B�]�9�
_���D+Ez9.�k5�SbT�=��-��;�J<���l����x�㑁n��X�X7��ٸ۩�2f�1�YûM>��C�R)f��'/������KQ��(l��j����m��Ѭ���1q9��hq�6�ĨF ��}[�ɘq�`}��Q��t�7݂Tf[w;'����$d�]��6������o�l���*CC+��_�aD��ߍ����/�F�Q���?/$v�7�3��ұ�U�R����DӉ�o�/���6�1I7��-[�	]��6E�g���"����-l�"W� -Y8m�`ve�j��]�iuF�����Da�K���=�b|$�m�<����b��S�[���T�:�k�D��(<�Cס(�*�\��(���q�w��Y,��w
u�mL��.����4���J�z��͒�P��!�y1h([ dh��w�)6A�Q?���+�.ei��B���0,����t��8	;&%l�,GoLR�)PuK�ű���m�!1|fy�I7��u f�y6]���2����E[T�<�Y��6�ܹ����;6+��"�иp�~d1!�o@��1�LyGd�΋j
` ;���Sr�7gFN��mJ	��-���JK�S9�;�;ä�l��깇4���B� ����Q��y=���:�dՋD۽�}E�!$�5�o3w�O�	�i�)�y� ۈ$u,:{m<2%�SM��[�o�5\?���]/ߒ��~z#�	T#���>��S����6=X���_��S g�����>oR�p���](�|��&n��.�K�]��e�B�J��-/5I�,�װ�8�A�S���_a��"��ن��Y�B�!ɒ��7�r���m[ג�BG��/ʝ��ʨ/�4'ew�C3HOK�暍�f�a���0���!"���>gx3�Y!�C�&p6$u
'���B��#���I>c�0�%g4�䰮/J?�0��>	�8E���%9| �q�/b�b��t�܃�u@4�$|�uA��9�P{m��ˤ���s���p�=��1[T��A6��ȩ+3���i$��s��9�JT��1�P�<��\�C���[�wi�Dg�H%$Ay��-��`kĔ�o�ߞr��I4r�Q6"��0��t�s1����q<-:db��.m͍�p垚�i�2��4�}ҷ�#
w����-X�>��f��]ʎ�Th:��օϛb��&l;\Z t�*��\m��&x�=����>�]_+�l	L�v��)S���')Ss=���Bm~����c���E@�U�'��l���[n�����z��<�ޚz�R�H��Wdg�Q�;
���:hd�	.ʻ뀛�aE��6~&�YH4�˛�Q���kI�h�M�sp�h�QZS7 ]�	Q��=\��'},�KB��x���M'z�}�YV��qś��I���B�_�f�2ߗ��7��+�̫K�-����>As
��g0�;��!��V ۵����4۴���@M䟛����)_�$�O�G� \yי���I�X)���̳���<�-5�e����LM�;5������'|V?�:Kf��{���uS\	�������t�Kx|R�?���^����GDh9�-�׍��S����N|�/�S),;Qƍuֿ�~?.䡈�4a���v3*ǁ�9����8q�K����E$J|ن�y�{EƓb(dXʾv/�F$-"�P^CK�6uq�p���a�F�Jc�u���6����g&�/�Ct����X�����aR�!�L���8n����n�kF�.�'~��-�I*0l�5����G����	�����o��6�9G޹�fO?KaH<_A��u��������l��9���m���n�r�9i1�mh��g��D�<��6��EQ|Ơ*y�(�	���A�����/��T|!'�B�+��|X6�9�?�ލ}��,��ay�W�Y�	�x#|�Ūs� �����E0��av����r�5���t��zʂdU	r��?���)��5�>7��YU�ݚ�����r�|%��(D��PfbTݏ$<o����M��y>;'��0c�=#$׫HBtd5��
��E �8js϶�n�ږ��je0X�"в�Y���d� @y*�k�+�GN��g�/��/�*uU�ݒ��'8�w*�0���=O� �?�,4ޣ����V؆���M�0t�(E�K�V�&-h*i�o�4�ţ�*V��1�*mZR���.F]M~��eRQ�YJr1�/kv�VB=��������C<��OTi�V�|8����_�z��|Duʓ)9��~>���^�]7��c4�z����ŉ@���ܴ��yp4����=�o��h��"��hHWi��;G���8�C���;�|gd�5/�D|��W�}�=� Z��2��zQ��N&���o����vT�jÂl�8�R�G���_�[B�*j��o��
* �]�F!K _�>��ap��M�<�4�����q[>uU�qd�
s�uaZ�܇S�=��:���i���ǒ�i;��\����w��E�/X
�������n�:��߸��9@��NV(D�e���^�)�t𾾲��i٢��4�N�%Z��S(�zM�.��	[��t���g����5�|�:I��c�V� ���#�Y�ĢE}uI��+գ7�'��6��_5�v�5����-l[`�|�G'�}9ۙ����{�"#���De1�k�	h�4�	"��?٭`���Ҏ���u�r����BI�ؽ�K[0���)'�{�����1X:��� )m�����CڸFB�o�J�W��|o,��gJ8~J�V7�z
��<�dw�ȸY=�t�KW�h<�oѣ���F�xR�P0�o ��v��:�a7jF��;�U(�(,��iq4�P১#�ݐ�	rs��l㱚�/�����eE�3���C��z�X�x
�%/p ���e�A���1C��/Jeb�B��X���t]t"�,S��l!���Ī�õ'�TeD��1-ˑ�����0~]4 ~��G��Ъ8�� n��cp��\��Gd�4���<��u���4.a��O���h���4�̣M���2=w6���L����3tk4�/�#6�N�6F������6�z�٩�}�%�5i$��9j�zYx<PD��?���-/�ސB�͑�	�~/��25A${UM���/���j��z#2�`��L��5���ڍr�h�uAu\�v�������E�Ň��~S����ØnҘ+��
�a�s��nY���L38n��� z�n����AKۚN��N�͝D�d1`�s˪ S�Z*.B�_^y����1�0�zf!U�Ĺ�ڸ}B���Q�|�צh-�h߭/IJ#0������o�kp�]�C2��ae@�}�R|��<Ř4�8�(�a����4���C��u�{�
�=��UQ�mb2e�nH�u��»�(��0�i$]�&������Km֎(c�>@�`.d�څ��`���sΎ��(q��	{��aw��8��V�KI��U�K�v����l�v���It�X+3Ёf^)�$��������/|9lO��)�*��d�$���8l.j�%Bʋ#���v:
��� qm����������\̛��M�W�����3��f t��{տ9�X\�&�S3q�O�+��Q/#<��}��ipl��MJ�	R�u̬�?L�h�ӯX�y*0�:.�*�Y�m�	p'��/e��a��O�U5M�4(�� ~��Ps1݈a��s������qGɧ��"�6��e�U��IML�|aD!�VĹx%��yѾr�$�%Y�f{��!��w�>�~��\[�,��sLLE��L��x�~�?fI�y��c?n������s�����������
¹�O��Z���X��u�>�D��/6J�����	nj����п��K�J�Q���Ѹ��C�t����`�x��E�>n����􇄰'�9�ז��%߷�X� �-�P_�����o\s�t�����aT��he�O	����P �b��d�Ò`&����L����4Vd��7�>�zE��b�L�ll��
 �p��Y�����/dX��
�b��^5�1|���[��vH#��q�Ȼܟ�}�>j�4�T:wRß����+�}T|�����9#����H{��m����H;�H��9a�G� ��#&k+�K�l��9F�2E;��9��޳��1_���_cA�k�w��yh�\�)���c���u�bfx�k�äuܺ�{ f�F�j���Z�(��v{�B�=�&�M����k�{����؃�I�� n{ǐ=I�0ٗ�Q�%��2 �+]=�*NYgNl8�pRH`d+�A>�DR���ޭ&Ԝ���0���s�|̘l��0�@^GA�����%��	X1覭q�XZ.���-���5���kْ5s�jB	v�/9�^>�ñ��	��G|��-�s-��G��.ZV��߉�s�qU��hMc0N��|��X)9�&�� ��(׭��׃v��T��s!��j7H�f�\�/�cz[lR�r"�f�ZT�"B���x3c� 7���J_������O5��\�e%4���$�&�]2t��)�BϥAE9
G
��	D�̀��s�p�IR�Z�B����/$X?Zw�2CO,��gI�-�W�l�_ë�l��[�i'2�΃�&E�u�y��L�^C,��f�D�'�Y^���÷���^U��O�I嗓��ҍ����e�vyh��1|6!��~A#L��ɄD~�Uu�������/���YCй�E������]^��%����b�~�DC|3r
�0}��X��\���͗�q
��(��)๹�KY��U9:�䧂zl�5�arRK��A:1����,���a��R���� ��.\�B#�|��92&3��$�k��e�Ni�����<b������^XnK��8v��Ɓ����-�O]�`����9?8Q~|i\qe�ŋ�4:0};��5buD\ly�9�{0Y�.K�մ���\����-;��w���#�:q/��G��sE��&��:�14Z�S��AڪZ`Y[/�4�%��0/�z�݃��c�)Z4��ߓ�.m��}�Y�$�A�3��*�م����k������5Z29��?55n�Ҩc����[Z�䆌�����'K|�F�N�-^���o;$w������*��%��o&oiBh2��ax������לj7"3r���B��w��r?GN�.9	c%��D`�� ��s�������#��$'�[���_�^��G�H6����N�����l1�Dm��/�f��^��j[ -v�ɛ-�r�r���d�8�`����U���\���{@�*��T��W�f�A��
И�<l��[u��4��g���4^�Ү�F��a��:��ٙȳ�f֔Z8 ��O��^o�Ox�߃���;5�%}L���~3��ZҾ�"�>{l}]n�eS�N|#S��K�B��q��@yDD��n��ߊ#jq��<.9S�.2$s�ۼ�I���������?�K��ս���K2�#�Nq�b;�uǘ�������^�M,��a�� ��E>�TP�	�&O�E:����,�O�uvs؞��Gӓ���l"�l7��*��T5[>�S�p�h��������[V]S��-����&�2j�'�:�1(�0(�%싰ס�f�t}@����BV�m�#�4�Z�3���d<�yK��-� H5�h���]x�-��)擱:DP�ѳ��� ���Jl���w�ř)�Ŏ]#��ֆ׃�E�5Z��>n���c�$VSI�4e,.����y��h���w]�=����^S�{�6rp��z� ��ǎ=�"�]=+�P��- .� Z�40J�������I�T�xϋ2�o��a�[Z헲�ܨ��Q�&U�H�
�nuNIRB������v����+�*�����`�Y�{��b��ő�q�r盌T*h�xt�n�E���y�w�7����h�`����ɐ�Cr�"��*��O2!�����������DK��Dbg�!��~�31
�Y�'XN�b�>� �N�`�#�	��\���������n3�#\h��{�g��Kl���ƸDt��R�L����^�d�p��9���B��[�"�C��w���H�U�Q��UP=/�o(`�)4�<��5��i�C���M�=�0���(y��81��O����C�<,4���R�ɴg���_-A�V�W�&`�'�>��.Mf�NJ��5�h���	%�ac �v��a�ܑ;�A~Y;��m���̅���L�����t�"��M��;�P�[�<G{�i�__>R�"�=��`�UՎ��)�$��_��cM�y�n��H�8馭Ҡ��ڽ⸱��MV��w|;*[���#����e�\�h�6��ă��XΣL-<OeB(&�����1zbB�n�7��q8��6�2*�L��=T=��u���s���}̳�;��d\N��b1���V�w�i�e=�<��\e��4�Q�2bܩ�VQ	u�X��m����6w�Q1?0 �8�Ƣ `�b/a�}Vk���?�d_� ���NmO9��!�#p)��x��
����̎U^T��8?$��Jf��C6�ɻ������8�������X�z�,���+��Սd��/[�pbZ4���tͽ ����r�))�]�����޶������~��������KO*P���Ha7%��q(���O�,���/Xۮ�8-�:�׆����7�k{[�9;�?t@��b��W��T��1);�tA\�s���;wG�V�0B$x���))�_v�i��cІߺ���#tJ.�#��81tI%_���l�
.�@Pf[�\�6ς��C���v3]A�;�*:+�}���MB��-�h��ȃw��?x�3&�?n�c־�«���8��i���n�#��؞�NF�x:�2��"���>��"����#֒�Jn�)���+K��s)I�`�wq�^�y;$��[��A8/�����%Ʈ��v���'+��J}���H@!K�}@B:���\EaLs�ʃ�6Z�1x�ߨë��N�{�Q�9b:q�v���-��}p'l�LБD8�V'W�O��Bj*���#Y�3���f��Q}�b���Y_Ѥ�t��Ȉb|\D�_��k3�/�o�3�iz��e
���7��q��`����M�� 1��PB �+I�Y���%�>�ɤ���]�B���n
i�����"�er�1�ֿ�ZzF��5��R������?A�K��83�]��{�7�|}-���*Ϙ�F��u;�{���� �.T`8�������9����MQ3�.��yO�ga�gջ�/�{�����s�mN��f�����+d��4�_�M+�pF+c��@(%'�]D�!����>h��)P��2�s�r@���U��sM��,���W�x�R,(�dA�'��MhЖ$��#�&�� 4z�,1�B����8���s��dk����U!e�賈��1�l�E�C�K�	(Q��IUJ1�4���Mm@UF����4F���W��(7ѣ��G>��3�k�ĥ�ih�On��t��MQݑ؟�ǥ3����+�]F���k���}Q��� ]�x�E�!]��^k7M	�L� �X���k��b���T�<����LԋP���p���ɱ&�hExc��L�����]��e$JpɈ\�q<�'[�mDTx�=��_&w���չP���H�K՞o�!(��/o1��E����>�M>z�ף]�!����j�=] I
q���~)�A�u$�տ��y��4��6�i�N���R��l㢐����_m��,B�
3��D�
]s'ҿ���6R���%��Ǡ!�YOӁ�- %N�5!�I���Q�ʄI2��%��ɲh�YZ��l�.�f�ɃC�qm\4�ِ��#[qC�h����S�_��}R��?�����0ΓQ!G9Ē�1E����u�D�����9�v����@P�iVZ��sҞ��?�@�m���ewGa^w��No�DP���9�#��!��j\�c�TY=�V��ꂣaS�΀�o��
�����K��eR��F��3 nƙ'T�-��T\�ד8D�*�ܽ��>�X���ͩx�<�d�	�:�׬���6z�Z��>�7pO.�v��a��+;�T%���]��]]����~�Џ���o @������K��1"��,�N��^��ϗ��
a��e�Jm�n,=O��|X`U�-`�C:��^	�;0uW���0Ɲ3>��� ��%$��gB��t;���f{/��k�+#��|�m)Z8TQ�� ٸ�O?���"�q�0�3�ED����PbÏH�Dq�2�P�M^r�vq����r�`�d6��ڬ���]ё��P�?�/@]�����Z�@������dyz�����'e^��	&�i?�@\X.;��f5.2�g;�wS���/���=�V{^�6�E���`/���#Of�7��HnNt�|��F-_�v6���:��ɯBb���]t7.��=A�5�a���O���� 8NW��@̓$n���*G�^��zW�H�&����=J��O�-��W�(|��R���Z�5L �&�<z��+�U��b9Kg�m�P(P�B�9�)Q��,5��n�Q�N����_[�r��@�#�Q�@\KC4G�}��̂��mC�&�C�E�˅r"�!�5�牥U�J>�-^��Dc�����`qL�铖jM��(۰5c��.�K#2l�L���G�κk�WxXN���)9J�����V���A�hL� ���O��9�nxG�����S��:�ߚ˳թ�,`�PY����cK>���a��)���ヿ��;wߥ&�j��A��b����ƿ|��|�I	�@��AC8l=��`zH��J����:M����O��k|4h�?�_d\y��)C޸0^��G�nʂ�}̇����]"�5M��9�x� �ؔ�\r�+}ۍ��>�������w�U��<`�v�?XO|�ajG�Q��PTy�͆ �K�=��U�~E��?;B�K��J.�9#>�O��K�����~�Ƽٴɭ�� �QA�ڜ�P�!�G�Sȉ�R@����߿|�
BT�k�G�ֲė��Br�F���V��v��-�S��P-b�P��Z�ʒ�#�/�x%�|�
��e䅶3o��6�'lN���&�l��7��a`>��N�آ�����v0�+>N�����b8�b���� ŉ�"6"���c(�k���[M^R51��@"�� x��� �������rz ���G��f�LD%�dG96*΁כb]p��!Z<�4����T�����N5���n�Ha��Sӓ��G����/u��$�W���l{P����ie��R�F�r5�p#�]�ِ���.A嬹et�_A9i�L�Җ.2yhޞ����m�1��Z��O����
��Y���(VQ4�e4��v���]ы0FQjS�ܯ�!)��HឨFT|����.�c�='�OӶ�<�&���rґ:f|)�>d\���ZX����P�Zi��o�i�༵us?�b���w���^b:h���N'Yk�O�h��O��~�[L�>�R�.��Ȳ^
;BO�.�o�禋�03Ѣ�FA�|o1`�2����1�"�O�cH!e盁@���V*�Rև��I2ݫ, �g9�P{�L���t�i��nīb� c,:Y�TFy��"ܟ������#�^}K�ߚ��,T�;4��c��<��a��!ܪAe��Vo�&�l$F����N0Qe	��s���^Y���Lޭ�J�煌jXS�C�p�M1���*��&��B�J�8�<���̠J�X�Y�(�;s�u���3|o���� �:#�< ��H��,	�g�q�!���;���ȧ�~Iu�Uܸ�B����Pn��A���,�Z|�~�^Х�Q��P��z�U 2*�w�f��:������|A�OYև,�q����:Vk����7*�'��F�mM�8Р�/�>�����5����ț�)��N��K��/����X�����,�MV=K�ɦ�!�o����������g�i6�]�� ��r�+�o��h����%%�qy=Q�0e��]��Gg'B!*��}�/q���2/(s-�|<�Wj���,C̴m-�+���'�Y��{��|)��Li���0��[��.BR����@� ��)��Ɔt}IԒBn����u=Ԉ��/k�Yk2 ���^e�y]�Q�y2R%s�C�8|Ђ�uv=����S�LA4��#ʸ"ې*e��8�cQ���7��L�6�PmʻҰ��B�dV�"��ᐩ�	+Ь6�4!�fU�vC��������HK���Y�v������24�iJ޾� ��/l�$��Z��I�<4�N�SEzZY�l��dq�C��Κe2�nM�W��K�vp0�8�/��	�{ѐ )���h��kqsU l�(�/,�s����t�/�����0���y�� <К�=�kh	kS��0��L&S�aL�;�u0��G���Dp5C �V�pV�s��ø�ԅ�:����%'�Y�?d"mI�7�j߭�Q"C<��x��:�X*��F(�Xj:ƃ8�98��>�P�A�L2�P7I�`��v���
�3�3��26CeT���W-��r l�㋀��� �X96$�'�FG�+qS��a�44��m9��@ {�Iס��.*��3�0f$������3&��l�Uj�\�`�?L�oo��bT��į��N��>L���PF���;�^'�C���l�K|�}k�j�K��3� no�E��Za+��/�YMGՃ���I�邻�IM���w���T��r&�1��|���#�:��6h�;�d
�ʲ�P�����Xv�����M 5eY��1}!�J��@���Y��3��a��Y���F��`��wL�A�&lt�$J�Q���y?�"�M ��R��U�}���{�#������}M�H�+��� ���{`+�� �D��2���O��RE��؇,��,T*�<�Ol�l�:�N�O�4������b� �4�Dr�l��d;a�}( �2d����q
O�_3�І�Z�eۍc|�k	`�V�Q�~s�H@�,�F�]� ^h�
��}��A��[�?��f4���â�L�#>�'WWޙi�����Z�E�p��jj"ޱ��%*>�)��A���i������q��ͽ/jto?
s��>��V���OOB�����>��ݢ��u���Pv��N�pn	P�0]�U�J���(򬱇���U+�=�	4&eϠQy~w2+K�C#=]I�.���q�?
�)Sjk�Pq.]9�륇�9[;(�Q������O�t⫖���H��,��u�zR���3e{������,�_`�[�ckvJ�ǫ������hJ&ޗ5{�c2�щ,m�A(�r��CB2D��s���(���Rt<N_6j{7�p��[����a�F���c���v$H���@)�?_x�9��j,�'��
�]��~41(���E����[	�t4[���V!��!*�ŕ���z�bI+�y�
B�yy�a#V�Cd�&�k�}��᪓T��#�&-��i,�������q�E��Q�̞��Il��z�?t�S��H�w좄T��US&��7�e=hgba���Vf��l*��A���,Jy�V]~_�#66`b��ձ�q	pb)5ZK�E�i8>&�ٻ�Z�N���U��_��.P�zc�(�˄6�g���~��]����"�sμ8;*��5rs�b(�:1^!���>�6�����R M��:ݿo�f�VIt�J�<�K6�>�4۾C�y^�Qy5视�B��4z3�)�]�^U���V�+�8q��&���C��K��On������L1�0��9�&R�0^�����w����Х�F;�Ԉs�Ϭ`���IcQ*�A%:ӆ�$�2s��h߇�_��~�g'���l?%J��s[5�]�j=�rB�%py��S�߇݈�#����D\E)���W��<����Q}2@[J�"S��c��]�{q=�E��D�٧(�,$)��N�ۣs �I4�c����ї;_S	�vF�!���c�c4���N�g~V��j�M⃀]��m%j�Б�'�Щ�ߠ;��3�t�[A�%���;[��x��C(Q�i��m��|R�o�+Ȋ�t��˴p�G�����2DJ�4�� m�ආ��^郉�Q�+�n��2�+���Ǿ�z-����&�|'$�
%�*���F�.ń�
3��l�H:L��G7�"k0���
:>�Ö��:u5�);y��^���*Gm��� 0�j;�{g�5I�g��¢ۋ��H�_�F�Q��:�w><汛6��xn9�($5q��#vLo͆�FbV��A�?�V9h�(�����E�/�!6�8A>���B���[H8	� ��;���h�"7(٬���`��r+i���5��qS#gT|�e�m�Ap�mI�A��vI�m@`��<�aeKR����D��9��˨!:�a�v_�/��$���R����c���%8x�� �z�С[~Y�c|%]����\8��-}�z)�x�9�fc���NG��c�.������ʬ�H���M����;ayz?��J<����ɒ ��Pǫ6mim�b�G�\�����^rJ!�b�V�گ�
�}R���w\�"&�Y�M���!�d\�9	�X;%ɼ�E"��$1E!x�l��F1U7@�F���BΫ<HT~��ʠp�w�>�4?��}e+�.3ѡHo#;H�ܴ���ցQ� k�Yیp�	�
�e�V�r� b��mv/�`�EA�_�LM����3��Jҧ�G�Be��9���u�.�mb�u�e���{^�U���,���QnG���xa}���_̃$.���0v<��� 	�v�Ђ��]Y��H��*�P��2��.�=�%Z)T�Q1Ij���"���iD5>��'�DG�����άZ<8B��*�5պYf���ݦ� �n��p�3�h�����SW�Ǯn��X�xʈ��`���Uir��P�{��X�Y*���@�o'�k$PB!��4�4'p!�����f텽q%.�{�&��W�.��R�|B��ڼ��P����5J��y�_=��C9�\5�����q��� m%x���Ӆ-m���US������&|S���$� ��W�F��-p�$D̆^�]�.����B�����yM��Gd��s�ȁ
�׬8��:�����f���X��g�H���~�S	���񺖚��?;�aV:��_C���Ͼ]��Ve�<��Er�|��TB@�&����6o�����]��3Px�B��E$��DJ�#�Cu��{h?D��8�i�\��+��9'&Q*��mB��j��.�����F���o�[��Z+�����T%Ü���t��4?�--,%��o��W��'yn���J��a=�� V�����c"u���!���uMI'�Y�t��N�E��<�����c�m��H�> Y	]�������r���B��Ɩ�}SO�~��Vk��	gD5������hX\6�{q�6S��j��ӎ�P�zz��O۴�$m�ĸ�Nm��k���G�ž2��Ȏ�:gD���VЃ��^��}_�	q��],�G�T�I�`�J�<~Q��lgfנ���Gɶ�L�\�cJwkĐGiH�3��Y�"��c�?�$�*�����;�gy�[io"�e�vw��^�o�R�%u��d� �;ʪ�Z�!	V��j�-�X�������P�h�D�����N�&Z-/g�C�(�R�s ���z�x��ڶ��r�.?vm�d��-z���v��##~z�t:k#�aE��12�e��0��lc��5oS��p[�,0��j�������hY���Q�Պ5��}��^� ,]�W	�L�}nHtdQ�:�]i[o�+^a�ǭ����P�R�����a�~b0��L(��_tt�e���ު��OS,9�Ը3V����)P����d���-��:�	I����߇��S���J��U��lF��VT���&m���>��r��֝V������5L��,�+>�s���pW�X���  s?����F ����"Tt��g�    YZ