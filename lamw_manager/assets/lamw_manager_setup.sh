#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2362708613"
MD5="4e9637b9872bcda02cf950333f7a241c"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19100"
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
	echo Uncompressed size: 104 KB
	echo Compression: gzip
	echo Date of packaging: Sat Oct 19 23:12:30 -03 2019
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=104
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 104 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 104; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (104 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� �«]�<�r�H��_�9m�� EY����̰%ʭh�b�R�gl�H%�@���l�>fc{���^���̬*<HPO۱3�-�P����ʪb���6����S��|�t#��|4�<}��|���|�`������<}�>�8�W����������l|~�?����M��U�_N�u_L/��p:�e=>������o5Q%`��?����1��HħV��ܟ�U=�sŞ+\	��H���"	�e�qkm*�EF�Vu'�G�|��'�����9���?�0x�'�'VuW��ț%�vt�Š��8�1D�<��$�@�;~?�n��5N���N�S$qݪ����i�������E��;����:�����Ecp*}�Q�9b��v8�o�x������ٲ�l�SE�0�gm�������y�H�C8Kb��sx��wzݿ��֭
�lٵ+j�>�����=����
�\��irܲ�3p��=�(�H�21!f(1Ǚ�\��C�ӷXgQx������(۲*�޼���z�8���;؆�TV%O�ֈ'2 �5 քٵ����u@�+�L�Q Ve�Y��F�8	��b)���>¹׈z����1f��?����ƤƟ��?��Z��U�����_���c�?%���7�����oԛ��q�hn4�O��o���	���pR��a�ߋ �%� z�7�D����wƓ碉2@
؂�4�/���S�e�\c�x&w(|O�2��/�D�G��"B�<�o\��y����eU�.�E@ Ӆ �e�@�>N���]"W^��I���x7�k|*���Er������+���6mx�ۆ���W�To�]�^A���Kj�������7�J��ҋ�����a�{]z	4�	]9��ϫK�O�(7/��|���������[@�#xqa,�֚D6u��H�<j���$����Ͱ��&�\�y0f�k� I��$�.`��j��Ğ�/NZ|0Ð�G�_u���2�����B	�G����ZK�)�Uܐ�͍ā5�0���h��J���� �)O-0k4���s��%1���T���W�9���M1�E��3�˨�[E^������jk���%�{���j<ڣq݊�+�!�m٨-���e�]8�YV�o�Y`�VI@*�ҽ�V��k����V�xM����餵+|l4�6p��i/7S�7�L�R�ަs�J���qg��W8����C�������u��F�0�GQ_�É����1������"V���U�JO��N�^� �x"c1��C"���U��Ã��x������Qgw����!�Z2<��	g�9�:��y��m�y�����	]��<��(��U[j��6����x�N���}[7e�"��{RR���
��R�"����ojٳ"#��G�H.�;�c���1%e!_�N���C��ԕa��$˘���=��DF�*%���`�J[E�=ɤ�C�Tkn��SF��ZU�"�o՞���2�66X�#4\y�澟vU8�I��1e�}p�!�7O��v�g�<�R
=%��.LP�~,�kZ�Ǣ�g�Ә����N0p졇@L%��W�)zH'�B��β�84�6�&̛������Eil�d����f��4����!`��J��͛���U���|'�1Cl�	ؿ�ڭ T\�g��cL��q��(�K�k3���
�o�O"�l����g3IF�zD6������u5Ʃ.�s�Ù��O�h����Ra�ϫ%��R^X��L.t?]3�v15��2�,_B�d�����q �������O3a�Q��������(��
!��U���U[K���T�׵㭚�i�4a�����'�T�.8�'��Ͻ��,1F�K� �W諽�7FU�K�>�;�<��X	��j��#�QU��C��y:F�hV��5�x#��a�������i(��:gK�&�3�U\������Eo,�&xu6O�7�~4��6��DQ� ����5b�Dt4��KN1.��8�E~"�A�[h��z�T��l"��_^3�r�z<��_E�8q%�ie�5"������S���=��[ o��=�j.��6���}�����OZ�k667+�G�9�&�d��;��a�&X���$F�vrn�o'j9̅��vS�p��n�w~|��@;p��s�P�Ъ���'I�5��3��iI�/\��z;�R��-���y�ܓ@LG(�DZȯX��vh�W�*.��!9���55d2nxq<��@&���k%����<��G� �C󻺭���v��4�ל;�$�z��]ڀ��Y����#�f�����xRߨo���C$�e�ݿ�<�O")q<~=�N����k$�$nDҗx�d�1ܰs�ʰ��ð�>��e7�q���^�\�������8�Z}<9Y��t;�A�e�8�ϝ�`��UK�x'���H;�:�����u'��n$i�v��0%��gC�1ީuN��]i�\eu@��e�%�pM��z)��^�	̮8���[G�w"���@[��������B�
� ������^� DSp�°\E�~@���_|=Ȗ�K�^�^]Q��T�6�7g�9H?��t~�(�Ƨ���������|�L�1E�FȋuVM��moX���++�`"}f-���p�SvL`��ǯ~����(Z����F�Y�pF����p�_�j��wo������G�nWw��~ע�����R����
�!��8BI� ~~u�~y͎�d��z��u�������TiJ�Ou�j���h(�����0!B$T)�.a�RS�̉ז) D�7�Cz4��������.�RU��	;��pRa�@M;����)/��`�P%-(���Ve*�0�AoL�R}�ih��T����G����QK��:��l�%X�b�k�� }�������{���������Ol0���w��i�d*�U&W3�����Dr���:�w:��9�_���!�ڢb���1������ؽ�ҕT������3S�~��淆P��i?^�	�zY��`�����Ԯ^���k�6?KH,Q|;�A(�~{��2"p>\�OV���5�=��R�U90�6�,8���h|�l�T}��wJ����V��%�ZT��������_&~��&�E`���L�5�ۙ�M��\��O|��-�#"
(�+�Ϸ��6�w���~��d�wp�$M~C�j3��$f3�K���;�G����;��\�y��~9�;$�~��?��j=����w�����l�0[%��J�!7��`c<8�
:��ߗ����#h���o2����˖�Ve�G5zb|&N$p����l��dULv�������m�ޓ�B�g8�e�|LP[�>��|��|c����ӯ�����[�7 �� �+��~��B�O9�����g���ś�?S͏�|���4<h�j��������@��6nzy��������1�:+��)�b�D��w�p��Nc4V��{W�\_�U�H�ü�c�����y�c�-��:� �7�B_E��=&a��C\ �j&vJ�Sq�i�
-��N:�uHA���!�FPG�����H[)]�+�j�[^�ۻ�%��f��;��n-��}�4�ml{Jm:�r�̉�ߍt�D-L�j𳲎��ܪ���֔g��W�i/l�]I��]�x�1�Mq�:��-�����Q[�P�K}0i ':/�ɝ��mS��ǧr|��B������T���N?��jTC-n�Ӌ��<o�WͶl.��4��z��Q�o;;�����L�"պX�9I���`Kg��̧9�I��F��_|�<ϕj��U��&P-3�|�cmݺw��~�XR��*z	iʷ-R^��FO!�?�!y�r��:���^��tmXV"����ьy�(c׃,�fhd�\ڝ,�o�����`����ہ"��J2�Tr|[��p*5m:�V���yS,�,����0Q6�	���P��	��/5#JKU)����2k�����Ȑ�mR��%�B٢Z�i�����&�Db*/��
����������HW�}�9B��)΂��u�
0���������f��t�Q׵�L�&�UW��!��.��� u�Jy�=�����J���_��fgt�c�9��hժ�`�Vs�*�q����J��������Npgg'��F����mN�.6W�$�;������is�x�&;?Z)=8�c�����Q��h
@� ���*݇o�;'�M,�_�]�!�w�5W�<��Z���J}t�&�9�cI1��tx�=��U��#9�Q����S�鮱�ŉl>�%2����t�{c/����lx�,������?�w��#R�Ձ�	(2z���K0"۹�Iqf"�w�;��Ӛ��u��������u{�b���p�/O3E�����1y��X]r�yԱ��TvE^�R����E ���>۩,�S��I]�����)�L$d��/g�΢w�N�;&͵Z��j�sJŶ��d��M��>�f�Q�U�2W�YP{�)�>/�۬����G鲮��tw0HQ��?Ǵ
^������YK=���߂9M񬾱ݣ���?(�ݺ��������������uD�{Rmp���lo+\z7�Hj_�>�5�1,���,�?ø���������a>�iܶ��DwRw�����T� v��.7�=�4��Rmj��h*r���X���Ú��x��d�s�`Т9��Y�.7�3}���\�*�_7��~noc�`��3y�eP���2�r4#�׷i0Z�2}e{��v��k<�ߣ�V3���r���͆��瞕;+u�E��� 9!�0�Dg�:s���4�+�t!�-�Y�@�8���-u�+}m��5!��Wx�ծ�5�Y�W��:�$5�w^C�W��/����ü�-Vf�ƿ
PP�BUQ�s�(��i�����ʷ�B��ڟ������β{+_qI]Qz�,B���a�lEZRA�:�s�S�:/�hQ7�=-'f�n0�}�GIޘ��ԉ�������ס����h�~��J����D{?8>��Cs��,�`�]8��'�����ΗS?��?�>���������'O�������?���o��w���)�� (��[@_�d7.N��S&9;����ݣw�5!��b'������~\�s%�K��q�����1���q4.���ؖU(�.�R����9�F�t顗�T�*��Dږ�s�"*�[.����T y.Ń�b�U	 U�["3�S�х��.
����2�4��[�v��x˫�8*a�˦"��'�1�K=J�,x\��!�Q�x�1{�J���]������~TD$p�����'}������Mߌ²�u��)�W�+&�u�,��l��L�)gI
�ygze�sE����ܐ�6e��q�=oy:ػz.�z ]\�T|��@o�w�?����D���QDw/钲O���L��D�]����Y�?fJʵ��ٯ�7��?�B=��~g�b�8(
�p��^��%�@����6���5�9[dv��`Y]Ч1=u��|7�|+��)̜S����^)UL�x�<���L���\og��W�r�����3�XU��vʣ��9@iA>�i����G����b����ȗ�*�3\l�|�1i�M���{q�����>U���4O�F��݊M�� إ�]> �B�F�و�F�Tbi�('���+��t8���I�{d��dV����m�m�Ȣ�U�
4��g��e;����Vb'�N|9���v�m�;��);�L��u^g?�y���SU� AJv;��3V��%( �PU�K8
��oXv�F�u}�
aC��H����2ji�U��[���c%|��9�s����.:���Zx��ܗƀ�I�w����O�4J���w�����z�qT�������x��|v�jo������>�D�f�>�q��w��'�����(q�t����'�S��8:�g������,X%���dH2?���n?�L	8H"�z�����mF��2$�"K�8$���!W[�'4'�����2$I�f�8+��z�Š��OzI4������R:!�|��e7���߷��EZL�. �?� px}Sʄ/�������֎n-J�0��ʳbLcG��	0
6�z��{Z�S˕�eK'wAJǔ*��J35��d蹲�Ȓ��j��_��)�m���mH������Ko>���$�M7E׷ C�s�C4.?���������Ԁ���Ʈ�$�sӬrl	�ᏜZ���[i!��r��k�+��(]8	O��#q�=�p�W.�X*F�#��ye�-$��*��=��)�'��n�(E�9��Ջ�\���� ��h�ַj4H��6�OLh���VCY��l`���=�v�3�S�22���ӯL��w Re=Z�g��S��mU�۩��݄�+��h������A�1�����u����2�D	�1a�����ۣ^y�$�2R0���b�= a:NZ5��k�-x�b߮�bt]������[�GB�wE�@� ԫ^j��� ʋ��̓Y�ڟ}���Op��w��"�+���[�^f��g�h���y�J��M���~��~�mK�#���B+Yd�L�B ���@2��q�}���Ʂ\��������/�w�7��g�O|�U���GTe!k��,�(��t�aΘ7-�f^��٩�F��ʪ&�XJ�U��;F7����y&ty��tQ�Ll�[�l�^�)F�.���r�p�BD�
����6�j�kBt��X
�6�����l8;����!���י�~M�x���l��XF�}���J��)ks�V�z~��!a��[;//U�m*-ܪ�>"b3�A��b�f�u����r� |��8����@3bQКз�و\=%�/\>y��%��Ѡ�t�N�`ǎ���A��Kcp&�Z���Q4	\�K ꮦj9��5�g>
.C��a�@%y��^5ܰ���h�M��N���c3�O�=7ѷ���k�+�R�V���a\������^`L�pZ���ZTI��+^�7��uz%[�AB�ژ�oH5I�`�'ɂ-�����(7�`f��&�b�4��#A����h�7�/@a�"t�v�!�6�ˌ�~}��
���2��9�B��V,�uyy��?�aaS�,�X7 ���ga7�K��Yo��z��B�|��p\Г/��� �iEֺ�#�^��j����oM~�x�s��f>HY�R�'�_K����-�h�o�}j��Q�z2m�UXP�@6+����)v�(�i�]��$ XܧG���,f�06P��r��($'�e4������|Ll�R�w�-Ȫ4��ϝz"�Ak��:�_�	,��|���m�9��Xm�W������?��NY�W9���)����Ub����g3v��@-s{��]M��ᤜ�t��Ұ�|sݱ���Л�����&Y�j�d�S�s��X]�G�Bz�ez�����2hRH�ܻyscc���{�8��K����R���#Y���*��l�a}��е2Δ��e}�S��Q�+n?�D6�׶A��o%ҹ���'C�s-YCRe���v�b��_M��bq��:7:L��T7�Yv}�t�֌�k2����,��TYW����ϻ�p���zy�k��1(��$,�{� x��y���p˯Y������9�ȵ�͇��/�H��_����2�ȏ�+�R�;�w��D@*�:�;�� fa���@���@Y"\¨��K�mfR�uֹ�9_� �\NF�O�cǮV����cWX�e/)DU1LJBō�0��1#7�{?GX�������|g�׿���jD��`4LE*M�)~'!�&���ک����^-��1�k���\E~���\R�z5�XQ-�Pe�bʚ�]q��^�,Y!w�S�����̓�$%n��^L��1̈́����g95�l�o9�G��P^���[���_	Q��-ۇ뜄*+�JC4�	X���x��'d�+b;U*F8��
7,�|����������7�p�����������,%G��.���fD� �* ��{Vd�$f�X\2s��e��F�QE:]�z)����oN\
���G*���� �v�t�Y�q�}tߗ����aLFW"�Y�b�Xs��~VTEOr�ّ4�_s:�͂I2�d���I�I�3[�	͐_�,���	���e�Ӯ�=�~��ɸ�h*­�+�\X�@�1�`n�!��c�����SR�֧���b>��4����g�"��{�촄N��T��$��=l�OJ�i��:��S}�\i���W5j���2��ا�S3s��1�L�V�A>Vd`]A ��g0XeU=�eOC����`$u�<���gcb:=�Pȫ�ѣh$�� �("cy�d�Gl��;uȇ$�91�9�s�Բ&ĕ�L�-�(��������Йe���>�mD�ė���d�(��J�[ͦuf�B�,����t)i�8B^Q�]�03؉T@>yP�F��VU�JDf @����fΠ���܍��f�[�n��Sȗ� c(+�#��+e�����E���`���?��ӿ�w~��'�!�W��O`���>007	`I+����9J�d�͢���-�
q���=&S�u�ڬ
�I;�yZ���z}���嚝ٔR�j}QJ�eEɶ�7[V����|t��D6b��S�����y*DgS����ˉv�'�m���g�Z�����g�R�<b*������`�ŝ��n'B{9=h��L����QF9֜��e��dO�_łA������@iU������l��[��<��6��O"�ŁJ| h�ǥ��<������&��Mt^�B�&�y0à��Cy�������-n��S�	碚�`��� x�u���,�<�uA�_�'��_�T|�'�hs��{��2,�3�Ey7x��fY���;��n�72b���Z-����>����[\�bR�A���2�\]H�mC�Rf��c��͌x���qț���%�� ��R�ȗ8��1b���p�*�G"�b�@��2�]j�R��C�ɇ��y���L� �b�գ8��(E�2�teuI<���^We�I3���+mO�ӻZ��4ڏ�\4h.Q�� #!�������a߸K��V�BV�N��lJ���3����h�,��C�T��L3���Z�(�nZ4>���v�e�A:ٓ/w��!�NAd��T3�8�j�Ua� �WyN�tD�d����~Y�k�8@��Զ=�^bD�$:Zʒө��e?���^�,(3�JW�a'2�e�h��o1�S>;�׉��hc#��ᣵ�w���u������Gc�6���韄��-�ra�A<�&����
(Cu7�OI�Eri�/q��ubfh�0�D聕���ޏ���^�����k���O��{4�}��O����9�>�wt�k�=���G�-w:��\�x�I�g�<�l�C66�gk�a��ÂlF��8 O�i
�4����R��2m[S�i��ʒ�Uu1��E#_`�fސ��	HmQ�
ۋrJ��h'p�`�+�ߨ_?�<�����c #�\�I�	�՟�8<jw��#��S�	:�����ca(�+�OBO�~9Ҝ�&�6����n�Dx Q"F�y߇�z�Rmw2��*�L8��Nm��И�����O��H�\��x/���?"fzx�$�'����X�v���ԙ%�>K��:/���U=Rbf2�#)�I �VSI]Py��|2a�gb)���z��I�ZE��k]s&nUpW��l$_��$��O����iO����ܚH����["�/��f���Z����������BI)�RHk�X=�ik�H�Fi�+��V ;�|�N�?σ�#�1.���E��5x���m�r����~����A��j3k�5b��I%R��~�	�x��g�+Ľ	F�f��=���"���;���S�c���]
�ȸ�A��>Y�f$'�]T�
M4E ��\F1�HN��ř� �uj�tR�OB�Dtb�韤�9��V=�E�Y�N�㹏.��3�\D� �sI~ �S� �M�W��^���������LAД�n�
�Ԁ����a���3���n���:2������s�]��޿�Ӽn���5/�y�v�e6�N@yT��C��Q��UC�͋,��xIU_،0�Zr���V�>��͔u��u�ݤ�0�N�Q#~���x�2;�m; i,߄�����:�����JWmQ���T�pc���F=��4�S�6�N�7Sc���,�"��TS��%0�=C-]�U 0�����w�~����Ʀ���%y3������	w�6�M��U�f�y���t��z) ���o*�wɬ�Q��Tjմ��0�ҦS���imb� &: �@��C�-�*YD.�IZ��[�{�gU
���K\���­���DIxv�����:f��l�������T�n�ʳ%@z�ux<)Y��e������I�L�-���̓W[�1��Z��7ǠJ<�*���#K\��mꒈ��ɜ������ʞ=x�^��c-h'Hß����b͸ODN������``����Hq�a�m���-��q8"^lu�_��@3=�I4%�/��?���lw�̮�	ߥ}���p�fu�cpڲf�ŀ��؟]y\~�xe�y�Iu
*�	L�<3/��9���,��!��e"�A4C���^?��W��u���Ꮾ�A��N��X�Ĳ�v҄,���v��V�J�5^�_o�:� B�s82�9��1ͧo�^��8�q�o�`��[I�1i|��0���+������D��Q �Of�_1և�F�`�����ȿ�|\!�-��>��@����	G�6�ζ���g��0�����{����S��ݏI@i����߽d&�����yЪO}���3Yz���v"�mɅ�a`�b�{�YN�����Ѡ��ݓ�%��A=E|����V^O�/0�9�[J�"�b�NܳVGt���a�1����'P�b��CX׍�
�<����a���d�	�� �`�� ��1j��>��HGT����	��\�P�8]��i�Z�o>*�[��*�־y�����)��ٜG�RԾ�ߡ�R�s�9��,@��٤޶�V:�T� u����'��;
�"��	�K.F�Z�;��qa-`�s�ǕY&�Eu2Y�9�~/�ոu�U��/�?�{����x�'�Ű�����d� '�0r5���E��/�����Z�N��~���t?���8��� 2f)ݴ����\��c�l�����U����'�4���l�X�*����~2��n��\���R��S��ٰQ(�s0f�ɸ��çk��~p)��r*���~�Vm�Ba�D��~0�K!8^���@����H��0Qy4�ߡH�p���>�7�|��Y&ΔI��!S�ӯ��q+'r���A��^K���<�Y�8L�����|4h&�L�e3N�zA�Z2r"�1� u�G��Ǉ���&k��	f>���d~.E��Cm4=D�<��L��*��ƕ��rmm����T�<0\%�L����.�p�W�Lֲ��������fǵ���H�t�a�<��ڇ���)䪙kA�kD�+��D�lPQ�֘�m��\�4j���%�RL�~�� �G��~�aN��)M�i�(�y53Pb��x~"�ny�p3���V�^�#�5��W�Te�q��$������XOF�����,_>�B�-���̴K�B���e�/!y�UbJe����R0��?O���
�75�z�Z5�!�� �<�`Y���<na~�ܳv�
 +��>�I,�睏����j#����A�YU%�����ߢV�Y���~!��<80n#�����c��L��.�j���'%��ʂ����]OE-X���M��wNEc�q�6}��1\�ZT;b��4�E�Dr���yś�s�\4�����ji��G��X6lc��<@ɌY�77<��5�k�}i�� ��*g�^�D9$�h���/t����e���**)m�S�	~�Md�`��{���-[W7[���j�4+K���4��^x�X=n�}b|�O�(�q��Ή��6��c�h�+Gݦ~�����4��,�խ9ʀ�`�l�* �+�Sf��t.�[�[�5{��RV��,�u~��o�J���L���He�d[���V�1�8���0a$�{�J)ZjC���fy@��I�Ͷ0[K9<n��8}\fɣa-�����jV92N<"V���L�X�+ct���-{�}�3u�@�՞ipay����|��� ���%1cc�,Si5�q?���]`%/&����Pe���ׂ 
ˢ*+�`��*_6������Y�0�8���3�4S'f����s�X/�8����uq� R3�8b�꓿�h�S^���%�\%����W���S�-7�qua�]�BwQ-7��Z�I���hՙ�� �=�2ͮ8�ݹ��t�ǋ���j��?쾰-zK	$���&L�3y��w���6?��~���F��B���AT�|��?!�_��:3r���=ϝ�SJ�J��R��Л��)GZZ���)h��7����2ЉU�Y��7��B������K��qC��X�����0�7�K��K�}�6-/��\���rr�0���`dB!����;��CP.��n����+.�.ui�k��-�g��+s���79'9�[�Rt/̀L���ʕ�Glg-�������ƍ�Fm�3�m4�񢹊!�U���y�_�z�|Y?>�_ދ�t�3|��_���8�e�����;��x��pWy�ݬ&���a]�}�|!�C�ȗ�@��V�)�n�7���|��m���A��[ ��s�~]-���p��������=/�w�4���G��:�+LĪ6�`i��a��+�3�K�0ټk��Y�ejd�뎣\c�[G� ���O�3�ʴ�-oZ��1�J�kڄ��Z��ZBda助pL!oBV�D���@�6�A���#�ГR���.���8�����:ʇ�آ��M��0���_e�ғ��ʈ8��|X��N�Q�8��>�����7o~d�樻K�F���,������	�ҦǬ��E��N~٘7$����������V-}�BΠs�e*��n���׺W����y���ra�~��L`VJT ڪ�K� .S%�F�*��o�^����=�++����B�-4O�������@na*H�"B�<5�?tW��7XB SC�k{[6D�8-ZM`����*2	�KM�`�X������U��G���t���H �&�%WVk7n�K!�\�L���?�6S������ ƍ���ܣ�K���g+X�o@�^y�;�g��(NM�/�$~*�G�!������@�l�5�ݞT��_��3������?�"��>mX:�o�6�0x��,Z�ЯY�� �q���u�%���3�6W̴�w�����K�hNG hȣ���I�޿�phG3�u����0�-k啸
Y�w>�݃��>����U�CYW�� �W�����V 6��ԅ��u{`�����9��R
�h�Ii~�p�c?�\����⸍��#n�O��@N�˒�7�0�E���/OL�M�t�{�Ɵ�M(�E��0��;����<r�_%���o�x]8�n���������L�����kw���u���Gc��yx��K��ɕ�d���{��C8�d��23���<=�`w_'�5�"E3�u���nwg�U[9~jno��W��^���怿Z�w���s8οm���M�x�U��U�iq�DL5cy70`R�M�`�OGo���9OG&�	���l$cn��E�|f�3�W�]?�z-��K?�ŵ;�E�-�1̃�cF3:gq�S�Ў'���Һ!V���=<������xq�sU������y7C��j����9��{�������a�,U=��uv�B�SN�;�;�~{����Z���q��A�a��X#����3/��y�� �^,����q�6a�as�zRD�bր'�"p�at̆�j��'a0b# a��gp���SA�R��������e� �m��˯+_u����1j���T$oў����9yHF	��Ӫ(u�2�������so�o�6n���Q,��s�H�P�����:����య�=AZ.��I�t���g�~2K��>����Gy\��Ån��Q���ď)f�k�΢�H��ᣗ�pT�UaS�U��4s+n$�iQ�a7766��f�V�E�k@]��ۀ����N>*�;[To֛��?u[ni�{:��'��=�f��j�������B�����o�^�����a�~~Bx�yre����.��EVG�'�u�2#�t4[N9����p�%f�|��V��<ec����Z�:Ŧ����������ŧ��u�ˍŴG�a����j$�{M�(T&���@3Q�\�X�g5}����'��{����Su���v�܃���]�@(�0D�I�L��qA�-x�2B��/)\Ԭ����L29TI؟�J�y�EA��Yx2�X�1I��6���ڋ�	�cJ!U4�L��rl�'s��*Q_��_�6m|1��͂��E���#i��H��XK�¡|v�������8׮Q<�-��u�`�Ր�i�P�;]뮳j���� ��'u�(���}���{���M<7��
�sr;���/���D���H��/a2J�7�:��o_�(�E������2�vw_v~�(�+ �i]����-�7~��T�
���������3#�ma���P��a���� ��&���T<�O�>�~���8k��L@$���,~����u�K�*DBy8�ԯ�U�NGj	h���L��������nIF�q�v�9��C�G��S���N���������^��`�Wy�^?-��1��@x���0.?|=O> �R��{��O�g��S?�E���󨙾��ĉ��'�7��O=���y��~��3�E�|U�\�#�Ft蹜�?���!`|��&Ir7�ql>�����6�~��	�1f�x�/c�C`�)- r���'�?��3<,b�)U�3������	!��y!~f��pp��{O�cՊTJp��I4�p� �a�[����)5�pʞ�H�O�<�ٗ�M�����N���Aj((��kd�C,k4���&��q�K�����9�8�>K���|r��ߥ9�I����'q��.#ڧ��b ��nI�?-`��6Q��h.O�}�S8�����d#�!�^{j��5ѝO��Qj=~���� �E��#��<NT�.j6��u��B��B %R���?�I,,Nع��{3� )G4�38p��bI���Oø��.Q�lvVb���<#Vqr�̥�[�0`s�9�m�[�{�EVa�}tɰ�1FG�||fP�&.��rZ0�/,��}�$�`�Cf�2���n��Zi��Z�������v�{5���Q ;3�c�ڛ�l��|To��P�$69��cُlC�͇�����+9��|�t>�>��1=��ty�A��A��B�Ҭ����i�.C�p��� ��o$��+�a)����J�N���ب��)�����?O�3ڡ$8^J�3yW�V+�|�ݥ��!�,��i��x\c��.t�ۻ%���r�!��HZL�L+_Qf�ED��F���z3�R+���:}ghe
4�}2�1t/���G`�7P���k�3��������V�Ni��^t 2ci�Z����^r�֟d_r���nE!w�	в՚�:�z����c,��.#m��u���7��i���m�����?蓱�h6�8{xg���ة�x����gms�������?zxg��5>�����$�n������*�Р����������5������2Y�������}������3GH1O��R?�ǔ��r�)�*�a#����a��[ܐ)����z'�hr��kF�6��w����M/}U�ڍ뱴��:��h�����̾�ҳm4�� �&��!��Vf�vv{/�9c�c,A��0!���'�!_�`~ !�� �?O"�=���LW�:(MO!ԬǄ�����H����4_r|Q,��g�:���"Y�����e^(���|*�Y)˨W
�"�� 7l,S��4��Ǯ<+�d[ü�w9-��^΄����T�隲Q�i��j��'�	���f��Obս��_~@�C�uT��Bҫ���NG+���z����dO)!��z�et=
�@"K���W��b��|��!��)
�,�fs�3�O����FgY�ߣ��(�)�i4�$��\��st�Y-Xr=��"�.B�Зі,Iy�����
�E��v�Z0��'�����G�#��Q
!��q���	���m�� ��[D�z������YM��s'�)���ɀ7��o���_y����5�cm����͍�;���������f��RM���)Q=a�&��,��E%mIa�u�o
n�y�fXE�a�ٛ��2����s���u��O���o�����/d-#X$,�����WXU��W��1?!�O8wl<OyT����随���d"�6�S�A�A���
�:|�JŐf.�����A%CW��'Ǌg�*���@.��22�V̘2,[$Mhu�|�	�Z%�C��!3����~V�_vI���94b��`��s����qh�	�l���|Y�-�Xq�x�}�e��z-��@[ֽ.�i�/֒fo%��C�ع>[��_�/���n#~�ɲ����`���>J�~8B��U�3����#X4�ȃ�\LI(o�:`��}�q��{������*��� !2CSϺ����,@*��Cz��ӓ�34T�3�t�Ќ���=g�h]��s�H������`шaR˖�q�g��(|v�v0<ˁ����ѱ.�߱U('<��S���gV� N�$�#Q���V��8�5NF�	�> s���w�vaٻϤ��?RZ���h�s�� ���)��֟6`$b@���I8
�.�v�m�[��O�!H<*k�n���������H ��`����'��[��^�$K�38
g�8c+,�W�i�W֣����Fk]	�׿�_�j�=�q���"�:�EE;�!1��?���rE2(dT�&ϡ���t �Cx��A�Z
�pkw���P����#t
S"&.Uo	�p���u�'���?����\�t�S���F4�]!��xM�DÅ!~껦�v�Ke4�.���T�C�ɱ=��)j�~��T�+,�{(�k�?��:�gQq0��»mK���*{������_��7��._��C�/H5��^h�ə�6	.�Y�'s �DbO�猌��sA.��c�It����֘���r�mO�ب<��$��L��p~��O���m�����.i@��O����x�S��p(�i��;��R�mbdb�2�I���&ʑ��?��#0��"�sE&i��0�.ȳ�L� 8A-Z^v~��)@C�|MY{B��*����sdȚ��1�$@��騐�rU4pj(Pd�b���V�R�re���R?Fs��KbF��of�CP8�=yk�֡,���L�qƀ��I�CMiM�拯�L�}��	\jJ2�����dbs_�a�}�q S�pT���:��3��f��
`�Q/V����X �e�z�GNIJ3�������㆘��Ճ�,��n0ؤ�{�����w��VG�g��b��3u�*�cE_I �	��D��Jw)�ڑL�Sp�c1�olkafhϿb�5m%,��H�F]�4�'�l2 uB�h>����g{!Л�,r��eũ�
~�`o���#S١��+d�v�$#��U���������[��osc3���?jn��_���׉��������M�;'.�U��Z	��� pi���W�3.�v1���+�w[�.�>g��8���;T�5�uVma\��0����Oc����v�ۖ��J��R��S}@�U���a�g���;|�ӨeǢ%��w�A���Z��V�����:y�3��p�(��-wb
�2ij�GA��}@S��213����x��1��gZ��Py�?s0���_�N?��b�
�eO�Ҙ�08����9�Ʀ�x��|ͧ2D,U�9�g�1.��h�X��h�`1�U~٩<���ˑ�s�Hx�̀�:�� ������p2l������{Õ}qk��kC��f���\��i4��gV�Y}�h��1�`�g@�B�TO^kV�x��Z���<H��vz����T����	�mXSߙ'�}bkxGm�9�M�=q��@�v:����ϵl��}���=_�ca��
+`�Ä��?�	�9�|NY0�`;���������~�ך�><K����Off3([���� Z�Ы�[�P�HLg�3FH��G���|sf�8b�X�"�d�&u*�J�� �&��j������մ�C�Y
!{��/�V'�}ލ�$s|:�t'��m��z���l�0���ϴLJg�����Tt���ph*j�Ĳ;6�����2d�� ������\����Z��������M�Mm�5�9�W���>O�1��]=`'�M�U�8�g2<!�;���qRυ������p�B*����|�T�*�g��k�Q8����������L�	�&��
���m1y�-��è�u�
'�t���a|��S"�D�Q�p���Ή�	 3uv�1�������,���!�~G��&�ų^1R��z�1�����om}=�������;��5>ߢAk޶g˩4�,���$���N�1=r�bl�5�Y��-@F��ŭ��6����s����}�>w������s����}�>w������s����}�>w���?����< h 