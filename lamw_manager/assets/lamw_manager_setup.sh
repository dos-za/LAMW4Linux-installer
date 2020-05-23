#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="759879465"
MD5="1077d006270ac47b4096a18b99ebbef7"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21268"
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
	echo Uncompressed size: 144 KB
	echo Compression: xz
	echo Date of packaging: Tue May 19 21:50:41 -03 2020
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
	echo OLDUSIZE=144
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
	MS_Printf "About to extract 144 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 144; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (144 KB)" >&2
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
�7zXZ  �ִF !   �X���R�] �}��JF���.���_j�����������CPm���q��o� ݗ;�R$�qN)�~��1��$�Rm�\o\�f�P)�b���_Fŷ��o�0(-��Ʀ�	���O��M�D��r���ډ�:�l��G��T��Al;�O��W��U��/�.}�
�M��X�R��3��ulqV�-�u �c�(����'S&J���V�4>�0�@��"� p=��K���c���4�fu7��7���K?�J}YoyM%�7xF#���2>z�4��^&��{�Ɛrk�W��!(g�v�?c��	�Y�]�.�!dy��*����\�Ë�L2�h��~�8�߇�L��o�� �����agIVq�ɔN�q�Py�B�Kz9Ҁ1�ҍ�7�`���x��Ξ���^m��L&Cs����c)&�e� t8�)��ۭ�i4�N�}h	 ��E#��ҍض��E��}�,zmIҦ�b>D:a��D�o��s����?^D����ل�E��~U�5�[ڲ���
H Q��ȳ�	�Q^;|�����I�fCu�'�xAe�i��{�˞�������_C�تX��S�c�������1˨jՊ�d#.I$%wh�]Cs����=&V�#�Yi�
�V��$i�+mb�D���݇����^�\Dg�	|���r�_:%Gv㽸O�"�#j�je��R��B,O�S:�G1|	àno�=$�+���4^�{7�=p!�=�[#l���@J�q�ǴET\��VQ�`o����>mL(�a�B,�a�w�vqA�w�"j�m���$��(�;�[�`'0�aU{}^!�2s�̈́�:?�S~H�kx��~jo>+i$��13=&u~j�X�F��A}��&��C�o�A&�LK������Y��@���>�gv��J��|��%b�A���<���s��t�9J}�"�&*��>*���y��(!a���ٌhpodDh-X��!�p��I4�gpY�NLz%3C�k���q~�,Z�K����������E����67�j����<*!W����(�A~`X2-��m��ұ���������_"�P�U��Ghf9h=���� �.�R�gjD!�nYr��#vK�Ԟ}�b�[as�3:��fj�����!��5;��w����0������|�7�R֜�#J)��U
�lr?ȭ�6۹�|U���A�G���}�h���;y�`
��6����w{�/��01z9�w+�l��	VO�\��-FD�k\����ry+sl��0�%�<�G�(��baԀ�B't��U�4�2���_

(+9;���*�����10bߡ�m���+��ĬxQ�eR��x�+��4��kS�Y-�E��۩���}ˋ��Z�@�L-(�
+���#<\��\O�6���Z)gǪ�O��H�?�e���E���1�Q�<�h��I���zo|E��Yק����6��PFPoX$�Z��`hatd��z��4N�9^&���}qK�?��~�BIj⨱�})<��99��.����|��Q� ��=�uVi.��aHY�������u�D:X��]Q���`ٹ��x�xkD���b��ŭ�L��_@�c�TQ-`�S5�^�N&F��k���@kmK2��E��K�Q�ID���I�n���Y��П�#K�iW���j�Nm8���U��iN坦ڳ���$�:ni�#��)J��sր/�t���^��Ֆ�6�y���hj_�Z$]ǯy�uF�(���NQtIM��?��b����^0��~9oӋ�Au�:�^0����a�m�MN:�6�"�J6����U�l�o�"�.t2 �I^�p��d�&iÇ1�̪�Ѥ�8=/W�V�
��laX0,De�����[@0<|�@Qi�,�K�,Gه�r���T��XF1N<6*��;fP��^bg(R��ћ��-N�P���m��e����b�%[��=�R�^$���2~cO�\Ǿ/�}3Pi����k�E�R� �Ǌ�2��\X��/T�N�~�'ƅ_�v�Z���:��_�I6�y[u퀔:���g��P"Y�
�l}N����g��l+�;��6i��ƞ�ߣ�Գ��Rn~��v7i��_$9�Ik���:܏�� ���N�A�}�I��*��W>�.N���!�pƨKU�@�����TwC;����|N;�+� /�U����	����ई`�MM#���:L�fo����ɆL��gգ��#�_s�=�n �2�$�Ӆʩ�Їas��hu�vԧ������w��1;)a,��(�b��=�j��mQ8�XXRv�}��� s�V��F�v��ּ���;.1�(0w���������Fj�*�a�T��(�,+L��a���#�X���4}|�𕋨w�lUb]���o*��@J��k��u@)�F��v~��֦�!%/3�?�g�%�ص��O]ʭ��#��r����6)���l+��	"�)>N[� bŨ�GV-��(��"�6�
��Y�T��ݽ���e`���1^1����2ANz�t�*~�����ߴ�p����h��`���M�W$����n�K�o^�k����򫈄�����*N��7�iu�w���	�[��2
�Շ�ܽ�a�q���"���mr���ߤ�_+��vJ�^��av.���!�}d{h�D{�G� ����I��'(��(�\Y�X��Q٥M��G��gr0�Aw��}�b}f�#�W�����%��ŵ�i����NvI�����š}l���گ���׷>�`3�gW��`L�n���
Ng Ӱ�}�BO��mt$�҅ m�N4�����=��^N��o�K@�k�����n8&�3��@%��]�m7�t�ꤘ������J�;~=��d�����8�,(Mǥ����L�t��5�a�;}�R	��u������h�{'!��
���u�ǅ�."��$�(�L�;� t]R��x�J{� `[_�c)#���PC����$�����o�8w�?ӈ�*�Z�S�c!J�����ROB%-�$[!ra����Qф�� �e����������B�V"fh`q������b�"�,����F�φ��ij�ؓG�D{n�����j��-IQ �&�#_;��8���*�����;,A4��B�~?��8�羄(�H7��d��2�.��ku|o�,Y)�n�+�>��m��6�F}x:qδ��:!��,V���j� #�؋���4Y�RrT�r��:��q��h|i>�	<WE�h_q�N�\�F`Jd�eW�	o���=�j̢����P]f�(t�l;K�|���ԕu����
e�tZ�\]RdF��K.�5/�ʎ����l�~ep�/tZ��H���>n���F?�(��W�9a��N�,��0:�j-]R�n���ѣj�K��wF�z�e;?j���f7"�㫆E������P��~d�5��Huej���*X*8�niO��u��g��6tH���K�\t�Ӵ�p:�/�}�U5A�A;0;�]�Q��?f��=�D��	�^8�)O�#�m

ւL��!Ҝ��������Ĝh�å�u����0ښ���e!��Df�Ra�/:g�3��!��ߐ(O�Ep��ց\�˶V�x,�&1�Ҟt�������F?�gk�cȣ��YZƘd�E�J��紌��,ۧ��l��WCtC}2���3r���O.S��)�_�p"� ��ʜV/�w����9 ;Ϯ�\:��@BB�Du��5UģQ��N��Y���y����¯�.C�~�IH��Wd�T�O�q6L3��}9�:��I�l��)�PS���v�����.QH���zD2�u-B�ܸ�x���'>���[��j������k&��zɿ�� ��V�����Ԑ7	p�� ]z��:�/{M�h��iD�v��ف�[��FJ�@��5�,��K��mWF+�j��h8�|q}�B�Oۢ%5EFp�j�*uo��ū�QZ`�o��;9A�����z�.���	&�)]+��L-{J�y�G9<rE�H�'Кv�d�)8���=6�����.s���d��&&T¶�D��59�*� ExT��� G�Kl��x��t��n�S���>6ԶA��_�c�|��� ��`sF���R�#�Ok�tx{{�����8w@��+�L@�k-�Q&A���5�JN��i1]���XWSý��K��2��"*+�ۀ;0�BP�엏��o$Pe��)v �:s��� ��C�!`G�|^����I}c��;\�z�FA7~�`Ǩ]{:]�5�N]���_�>9-ÔFg���LA���&O$`��QM�89����FI�@`��a��L?��F�Z�-D��>���:�O���fs& 9�l��Q�+/���_=]�UT����u�|ڸr�$_��L�Z��D#��Mɠ;�S�wy�
 �G���}������&���
�\M'�I얝ހ��
.Cx��{��D���Y<���rκ2q�%X��oɏ^ϩ2� py+�C�R�@�M�X}^L
N��8l�s����@���ꆍ>p+�Td�w�)�a ����6 "�Q-j �qC�U61��3�����jb�&^Z_�^K	�D�X�p?Un�*@%�is�o_!Ʉ!? K��+�p@wj����Q�`'�����`I��Ғ�	b>���=� M%�}ry���:�?֜*�v�lŞ��]<[5%�a��H��`�;�>7��X-��*���Q�d+[�C��k7kk�o���l�F�G�Τ�����0���L��<�8�e�-���-עU#��n,����A��<]��]�b�)���G��g��]��h`��L���I���[�!�q�W�D�zz����c�" ��Ox���'�g���^Ǫwh#_X̱��F�ߔ�-�iBtQ�LZ׸,i����pfM{���@Rf��,[E�iW��/uWO�.�������~�n"M��h�?�p�Ëo���oQ�p��0�·�s�X������ju!�I�V��ղ��\z��܈�^�:2�c�M ��7��7�����Ky�>Y��rԖ2ȶ��uQɃ���\�=��O�Ϙ��9�r�S?�y�\ξ����j���WSq�z�B�4��A������;���
X����
���{p|�j�-�En.��#wꌓZo6���o��vqF��k!LK�k_I�Y�����c^mF4~�H��{N\�NV�5��<t+�Lx8��,��u��Ut�W�ѿ�W�퀎z��t�,�0 �i7�5k��	3�%�e��p��m��@��l�u�tt�Ԗm�]ӶO���tC�]��eE�>��jI�/<���=�qe�������]Y��]�	1`%���ư�H8�H�
�O?�$�v��4+g�S�s{�
�а���\��N��,y'm�h�@����<�w�XA,m�����vm��DO�*��1���]v�ꐦ�y|`��=ڞ��*������4��h���LgK��ޗ���>c��c`��o(�6 ���V?N^ggq�L�g�&�fsx�.�
2$ʸ_�"yB����9^f$[�ϼ�)�1"���VR
Φ���K���u(i�
2���x��
'�>E�eB��Y?'���������-�%w����tW��|Jl��-L��2��︚����E��j���Q'�|]7����3��g��&��U�8�c���� �P�g���Y���+�@.[�����? ^��b�?ȲL��:Q
آ�9l4iy�����^�O���!m��K|<���uxq^><�f��]�i=���]���g�х���L�Nu�vz˛�� �iaz���LԬFVf�v9���Gz��ݑ|�	�r��G%����ó�
\�� D��X���d���& ��o���*�%������M?J�3�_LE='�=3,?UV�*5E�ކ���l;��'Ҟ���L�'Q;��n����̮�۽�09���?�}�z����K���y�	+賋kY�O�7�K';B޶b]ݍ瀢���uM/��,�^)=L��5K�WĎ�4��{��=����)^��;�)���"[��-ᴞ|�v&ʱ{��̦�I\�#���2�gD0�3 ~3B"�S����R����F��IO��#�4�$�d�nkM��I0"&�h������y�� �@��ā4c����{v{�w�WM�i����J���|q�nA�`���,#7�2�n[��a��#���5�J���D�����\0�ӛ�7=���/{������bW�A|��`�F�[��VO��q��KR0K��ٔ�����q������N&� �x�"�i�����/�Z�Y	ę�9�C��#d�8;.�Y���>սrd�5)&��X��2���՗��x-�3d%�c�?�o.�4i <ٓ,6�!:ڥ�{kٜ$s�,9��@rA��<'�>� �Ie��F�pXʌ�s�,�r���QV*�
����6*�,;e��i{�ٷ�Y*�宽�!�U�P(M�T�֊PR��P�O�x�g0��a��%'�&�a���ny��#�KL��7د[����cH4�L��)�
lB�<��욦��Ra7b��!E�SS�E٭�w�{&�  ���_N{C�=T.�L���<�Lg9��V�
:uK���c��4,t^� �� �+������LZ�G[X��ȩ���ν����u�k!|
�y��=��	%��LTJ��i8��X��9B:�n�Z��X9�F��epp�(d�u/�j��o?vn��}h�"}������}C�u���*خ�1xawt2X�<���⥇+�;�})��Q��Sa���o%J���#}��m�rxFU�ӎ�[ӂh����4/�^q�G�L�!�%'��Dy?�������Q��Vd�(poT[��(��@�Y�?����Y@7(ƴF7�!�T�!�a��H8&A�f�[��q�c�<�ώ�kK%	3�E���� D�tD�^J��THDg�����SJ����vI���%����г+���kP9�p�a��������<�	�K�.��(������,�(Þ$��(g����a�"�ѐ�>=����	}*��Xr�QI�Z��WY��΢e�|�$��~����ې��|� ����x�4�[��ҠMe��"���iý��2c޽(�
S�˜��s�	4>�V�o�PI����(b�"o}���hN��&�/y������J����M�蛁�b�]���'���y5�D	J���n �|ǏA���(j��7
%����6ʧ�+����#��c��~�넪0�<��m`�����BI�P����d����H��"�ɽr�,�ԏy4���*k0EL��@�����!��*����KW)nϸKz(]���i�M(�k�f��q�TQ��������j�� L2�T�W�H��欝�h�����_)��Yc�6��׮�67ܨ`�� ��7�$X�>< ΂�Ί}�ۛ2m}�:×/}zk�گ~�=\�d��ı�arӿl2v\I�����!�[bVwK*D�tKd������ۜ�LZ�b��A���LO�Qt��'�p�@T��ı5��<��j��k�Dq���C?Д���Yt��5Da���u�jqnLr:�u�֟�p�B�_v<�!G>�j-M�OĪ6�͗����%��o���/����Ac�\̑�o�\L\���7��a�����24��J.���7��H���#�]�ٍ�qa�,`�X�k�ļ�`t0��������w��>:�<�f`�m4�J*a|��`Q���Y�ŵ?���e��+�2����1��؁P��L1�n٣~����ϒ������8kM����#拏�m�z��߃q����PV=跪E�u%��^���͕�����и�r�h�h�:�_���]��X�P�LM�A�wUc@�\=+ [�Ĵ�h>��;��_�V��(�R�m4&�`�;HAJ�6�)��>?)���3�K�C%8z04�����#uOUJ8��Ŷ�=A��\�채�V;
F$�'ˢ0؈;�Y���$�cF�h��Ӫ7j���*qNO8��s�u��_A����|����x%��P���cq�y�ߝ�$Iʺ �O�y���&xĕ��I��H����#O����j�VN�]4�l�i���c���&�,\�%��褣YW�b���S<�A��1nO*�0T%�F}�	\��e@�vL�D��:�͍>���O܂O�#�	t���DF�Rmh7�}q�]K�wd[m�r�3P��TY�E�q��Z�S�q�bmwb1A
�j&�sDOh��n®�Q���/��jN����;�&��a+fDs6���v����J8th#W��^ |C����H$���`��z���i�a���rf�Q���Y�`#	"@F�q�:�s"�>2���K��~}�:�W�Hέ!����Oж_��x�AD(����og:��NuE�>��3n+{��hNmÝ���6�Y:E�xK0���X�� �x;�����9b�Q՞�?ş�$k��nQq.7���f���.,��&]��a�?�^�fa�7<��H%Z�i�7����-k��y>�������}=2O�\J��,>�>��5dH�VJ���@��`l�&&X1��o��tB����f���GS5�aV]�����q{�!#~��޶E'o}�)޽J�?���1������|����v�M ���Y�7�C�)G�b̂�����r����w��A7�T�/^]N���ytl���F%�)�H�m��lvW���֨�[�[�O@z�V����s{:�ZE��J]_��o>x�5��*_H!c�b �W�#��e<=���:�L�	B� ��㢯���O�-�A�oc�G��ᴪF�ūExTS
yVv�j���d���g;�b����%���Q��cЧ���ɥ�邎��Khu2�)�t��?�ƉL[P4�wu��ɤ��Q2=�F ��u� ���QnϨ�I��}%����*%�DM��8�{�$b���\�]����tv|8����~J`��il��k�Q����cF�ߙQ=\��^���?C����ю��B8�D�h���w��9j,d$o���T�H�x�]�K�H?k���e���n�m7�~L���Ąl����ǟ\,S&1tX�-�߱aMw�Ʌ�3]�TF��J֦~y�j�i��s���E+L����M��"БgaI�Χ���7�۷p��;>*�����Y���;���6m�h&/����CX���J�v�g(�#_l����"vU��x������u'�g�{���F�>Jt��e씄Ä�0(x�2W� ��"�-�]G7&���}�{�@z��a���3����mo#|���8�P��5a��a^�W=]��M��Bp:����ʬ�M�n���3`��Lt�!7[rvU������	 ���Ձj;�����-x~�QoRb��$��M���8�U���-�T��~^����\Z�`��  �xĘǫ1�ű��3T�_)�Ky+yf��Q�L�
��:!�(/`�w��Mb���WTĩ�sŉB�!��x��J��~�qM��O���x'�*���뚩r�� �������9e��?&}�O��<��3&�}�����\��B7�ၘ�E��.��1���q�HBPn��6d�O�il��H�XG�o�� |�����f���yg����_�~MA~^��oA��Bxn�k��;���`8����w��J�8���k2�˞g�4��v�y��+⎫�L#7
�W �yE�)O�Wb�5��]�4��^�|��vwc�X,��ch����g�-g�c��,�<z�Kj��M���=��j��N©�p}B ���1f/���,q�Ct��I.5��B��ZW1��X}+��Y�/��{vچ�h	p�Cvl���"�.�Y���qL��s?�p$�C�5~�!�7����C��hc,i����.�(�o�<1S\F�G��d9��5�	!��������l����@��Ty�����8�b�>�o'u7����_�"�0� �*�
��9	΀�Q�C�t�	�D��DLvM�J�7���$�Ph���7�H6�)����P�(I�G��G�E8Y؆������G!���ROj�?��z2UD
�0�3S:ڵ�+�k܅��{��XMqN�Kw���N�M�_r�������*v�Y����
��v���i{�<^㟉���i%LI�۔$���A�����4Z����xdO��~v�F\�V����ʂ푄M���蘽��uH��jC�w� t�:���%;�^G�bGeo���NF�K\���T�a5i��Ѿ/��hS9�+�M�!̇�9^7Q�Ճ�FF��˄,&r����#*�;��?ڟ�@L��S�&V���LS�g�΍�5ƒ��N4�,���>�R�ʜtץ�h"�T����&�e��*�"!k���&bH{&.xd�y�k0�H���Z`aBgcF� 	����|i�����1�T4Q>��Jd;gf�~vu`$�({
sT.�z��'�n�~�:�)w�I�'�J��0�啎�gv����(��������F�u�x��B����B�zD^J��-r��>B��_%].�s�¥�Xj��`���T�G�3o\��i�N-����6k�֎�驎�
 I"�i��W�'a��E����̽f��3�LG�YOt��>��������>�ܸl�1r��"�75_��i6�VIE$��b�����ѹ�q��0�T�*I�޽�.�}�Vrr���O�����9�Iy�_{#A�Ϗ}/����A]�.�_T3s���&����w�ɓ�Kv@
KO,<>�i���w��aRHL_���eN�u,V��Fl�gM!���igC�hrm��Tj �����;��o����DP>��+恇sL��s:6
6p�Z�H�l��💑�A�������N��{�z���3>�/a� O�0�M,@_��+� �0��:g��o�剢���6�s��"���Y2�Dlm�㻒�O����c�O� W�X��G@�������U�G����f� ��-��E\R�x�7�R��>W�r��N��u߅�*�o��m�a9j	��������	0�����p^���~�����}�M�|�`x{�1b�?tv�T4�?\c��΋�����i��G��/j�e	�ɆG��r�>#l�{�Hpl5�R+@�Xh ��^|����7�tVp�*x��!�"��f�Hl'ͨ�Hn�B֞^���*T`,�H��H�6'���$������ʖ"�U��X݁IL���U����P4�l���A��V�]+
�eR�[Jb���,E��^��ZR����� ���F��"+Lw\	�L^̳G7U�km�t����è�=��.�> ɚ�
�\�e��g�Hc!��M�_L]ȭ/=y�G�r�o��<|���if
}�y##=�oT��a���S�J�?�ޓ4����mz=���0�Vh�˩�s�c�I���h��_��uޝ��Kh+�~�e0�z�����v]�?0��,�9꟞_8�T�|���i�*�}�#bAtZ����?&�A��#&���'d'2�7�ͳ���:�ehŉl�����[Y 0�J1b�n{��Wd�s�>������?��c�$�[����YM҆�L�e{{�n���cx����q��.��]���&t$�
��˟++������%g�j�A���.z�+'�'�aD,p�*�����y��Q^����V��ٞ�߫����^#y
EoR��������6�O�R#�h)��-��v�n�C�����v��>v _�D��^��]����['�L;dZ���T�rѸ��-���\G�X)~��uerK�S��G��+Z�JIb�on���� 1�� �H�P?�#dV�؅3����+�Ku���͘��
��j ������CF9ǭ���g4fG�h�jG��������zOr���.���� �J�(
~Ǎ���\��������h����
`������*�+d~;#B~D Ą���.���#�0���������;�d|���D��*
��.�=�d�&��د�Km�l��/�ܖ�H�^�|3���Ŕ
{ �0Bq2��&�Ҙ*�>����Z˾�^� ~��7٣ؿ��1$��D�Ah�+w����a�*"�8tK���^�w����7�+L�O�L����Eo#�b͈Gzg��X������>s�=~޽ɓu��fP����ʬ>JxJ�U���=��w����E��Z7�7���5
�̤h�4!yv�ф���x0t�&B5$5Rp���{��hBr��%15���
�ϧ�w�h���NB�d�HZ�B#a�[R蟦���_���sn|��	i6���H�e�����Ȝ��i�6μf��L�2�/�DS��*o������r-N�'�+Ͱ㨿�'���9 ,%-.Lm>������ʱ����c�I�<�<�ڿ���㓇�U�6r�6���/�i�%nxR�D ��'#e6�-#+d�=�c�&C%�:;	��4p�li{��[��`���G���1�6l�{
l��7e��'�$E٣�mהVM�x�r�%�4�n�C��!�AZSbU�A�[�Z6�V�E���32h;�'�((��MhCd�O=��:h�Y��Q��UD�D����^��&���Υ:>��	��N��@Nk�D�fΙ�/9����l�F��]��;��3Nթ�nhĹ3?�z��c�ɒSX'��UB�믥�B�.9��ҩ�)�T]��c����?���'Zt?���})o�#o�ki�lZ����fx��jX3n����4�+����y���Lf��ά���mV٨���L��_��x��X��� z�����\d.�,<̤sS�����4
~��+B ���\}���Q���Ա�0Ф�>��'��� ���� a2�N,�
�ԝ���Qk.OrR��  ��R�%������.P�S��}� :��;��1�����{�Qu����Ӻp��Y!G����Ak�P2f��6y���,S0ˇ���D�]�N��'�H9JOD���pu\���A�?�f����E�2�-�ǂ����|^�0��;@P�ay�U�HYR)��)4�f��~NBKܚ�	3~F��v�z���]oWF�d_g���l�CO,*�:�ܻ��!��H��f��l�1���h�%��Pg�彝7cT��B���{��쮼b?Ob!q���-��"8$��c�Bg�. t�2 Ğ�L/<T2T������W~���Lí�8as;�ʃ���a�,��
���'�SR�T�ZRI�[aoЪ����:8�ΰX��� 9�+X��G�� ����qPx,b:U�� �:/irn���q7lX�<ɤ��H�h��$�f���.p�l^3�焻�6���q/����m��e)!�f�^� �`���EpAŸ�lTk5K�<!<���9���������\*�kl���ɶ��gi�1Փ]���Q����j�=��63C$~t�CR���IX|2d�3��~J���<�7ܯt�����˜��ߔ�:��)G��C���B+,�pq|�F��G�+;�����o�E�aK5�H2ܢE1�#��ّN�R_G�N�G�� A9�J�V��qw��5���'fڱ�O�ad[-3��H���u�)X�b�n�/��K�����s�\"}��7v����*��>2�6�"�v@���~�� '"G�opH�q�Z���z� z��d���rRb�������n1�hv<d��᡿��M2w���i�����$<p(A�qQq��ę�U6�)�����U+7^3��F"�$��i�p�`/��[r
��,���\:�%A_�@�<cE%�wSe&�lN8V4�^��hH�j�<=J����t
g��u�9�Hbk'=�ֶU/\O��c�߶�`���:�ڪ��2w�q�<�,��2* ���Q̽X���'��.���u�Ԁv�jB���g��W�pl�ډ��Mv<X����U�YQZ�1&y��)� ��ƿv������#����+�f[X��42���~ؗ�B��$�/f)�XS�n��x
6W�9<��'������v�[�a�Vd=W���$���e�'�ۓ�J�-?>�TNJ��yX�e�s���'��S�V�?�R���䈻h%>N���R�e�+"7�R���p*g(i�nU(k���
9�ʓu�)}���BX�6���»}&S�F_�o�*���S��Y�R�C]�ۙY��� ����ϭ`J�4��q��ݸ� �A�D"tLQ���O�Q�k��L�rA�H���`aU���%u�`� �׊�k=�4n5]_�S�3{M�)g8x&�����'>�6cq��E�Wâ?d����!{/���k�k)t�U��6L�S(�&�6����替��eR�Y)N��Fa�k�|S���7�r�9����qʛfc�I���v�?0�����j)[�����z4y>�]� �ۻG���]�'��{�]9o���Sh�S-�����]ԗ�Tȱn�	����tB��m�����b������$:R����ѹI�cx��ú:�R}m,��c45ۊ!��r-Ph���ё����(G�X�)�"�#M:"���~�Vd�/|��޺�ħ�Б��}����t���|%��J?kP�F_/�yiV@=�q{7Yn�>�I����|���t�ǀ'��Yř�i�
l�+0hԻjI���B��Ѹ�>tS����-5�=�≍x�m������PԵ)�@$�B4�����ỗ֔چ�7���P��B�Io��˕�IA'w�a�-��3����Xb]T[[hg?ô�5Y�䎑wP�z?ڧFf�]Q)�֜@���[�'�'9�w�s��Fz�(j���8] ��� d�f�!!�U,U(�ܺ� *�ֲC.��%]��D!ZZ�`*n��޹GR��pKw=�͒Pf:=�2E�7䁦�ﲻ���?�Z�LU���hM��\w��pO���m�o���̞u�!h�T�*���p�2�����ƺa*� @�=��}�TPQ�k���[Ci����)�=TnJ��v�1���^E��RaӜ8����^�{Dei�����b�~]��-�m(O��)�SᏕA��M�0Zqqj{���p=�᦭�������懊0kDC�%=Ň������H��1(b�7����g��(��.��b�.�,>�؏_ >H�F���$	��dZC������^%�d�1��p��Z
R�{Boe�ȍ�uz*_?9�(WN^����($dJ����a�}rVbG��-��1,3WuF�Ը1�C��l����'��<����.�}���@2����^���|�s�RN�b{��}��c9����-T�Ź��˱E�-΅��]r'?���+���һ�g�mX���эА�+��K͝��Ⱌ{���/,EŋQ9�K��g�*��e4��
9`�n���elba�pT&)`��o�s�/�{R��q����;�R8&@��_�@V�EZ^/	�G'g�u��`g�+AHȢ�-�L�_��M�������U�DnmB��~c�i����GC��x�����-=s;��"M}_���[:� ^��we
y<���JʖZZW�9\}��/�Sc�Ѯ	�Ed�y�;E��Q�E+}�C�#u�ք�d/���)������l��EK��^�r��92/xhb/	���S7+d��$�Q�K#�~��y:Teڹ䣦���)@|���Б��;��W����� ���;QGF��*�.�lȾ��)��˜���̓s���0�8ގ�0J1�ls��ā~m8��3���ǒqe��o|g�I��"Ւ������'hG4�y���m6�.��/g'vԺym.>��s]݉�ӁE�x�'����7�?	�#-d�m�Vi;Ϭ�P��lN����O����3j��8l!��O㡈�f�&�������X�H�� A#yЉ�u?X��%�X�c5"�}Z��~\�c�Qn�r�Q���SZwg�j�䥙8��C�Z(a�N�� l58��-I]b�s7{�|&�?�Q}�G�p��(�SzoY�s��8%&��X�����d���F3�#�Qk�z"���>�[K<�ɖ���v���rMFYGɂ�B��ˉ�0�6�c���S�V��&��	�����Wմ��a� �m��*d�uAs5�����[�ik��%��M��!�~~�H��E)���@=Û0kkF��t�zJ�R�� y�O>b|�l��e�%֜U�m'����Z9ġ�3}XK1��ah@�n�4�!�pf� #����Ɩ߈m�
b��Anun�_m"��(2��,c�ULH��G���Eh���}��M��b�T�}����+��s[��[�V,����Osx{�pӓ�7�N�|.Ś���EN3B��K�(���͗��ճmp����5O�6���`$9QԷ�W�� 3����9�pfS��RY�=�>��7����+��/��6J|�e��!K��v�� �Y������L�x*By�����^4��LϜ��S�v%��#�0�����*��=��\ٵm��1(E��Ѳ1x8�=�/I�w��"!��"h��~'��Ms��Ywڋ�!��pP����;��G�Z��/
1��'�޺�qjp1�^���8*�IR���n������i��Ͽ^dV��˼����[Vߑ!<�aj�}���G�}y�м᮸�>Z��,�ޯ��̚��D�M��^�%ĭK}gꭡ��������������$�,i,����;�H	���b��M>F�B%$�̟��d%�p����y3���}*���p�������� >w���kA܆x���+)�j��'��������Β.�@X�u�t:H�c�e6��JH:�m}=l��j<�5y���bpj];a1��>t��t�LtC�
���J�J�G��x��&�0���~.�忋-��_�v�v������l����z�V&(�����!�A�\���me��1<a`B���b���ӪO��'�����@��O"/x����5����w�Su�s�q����Dt)����֒��,병�_3ȁ�\�gXv�S��{����,;Yu��C  ���l�0�o:�ax\�W���쉌ڍF��%Z�X�)T{���u���i���.��?�z��l�qJ3�a�m�H<l*Y�6Ե�`�À��J�M�_�i��L��>�Tg�S�}ಉ�drz��3���I����S�;1��)^Յ��8-n1fn�y9U��A�Wfȩ,ԶK�L#pi�B19����<��aޟ<��F4�����1��L���e�`0��9�/$t�B1~<�j.i#��x�G����m�ǵS��fcS��G }�[Y 7�e���m�ƴ9?m5�:YB��W.�G�Q���:�B1V��3>��
h���#�@jyA��;3�6ڤ��%�\L3r{�v}P��$�
��-U�N�As�S�z�#+��U��R��X ��$�j���V�̠ǁ����VƏf�����v��\H���JBA�+h�o��#&�c�s�W�VV�d���Lw�x(�r�Z�����K�)#mĤ%���'n�)\ל2g�j�^�`wz-��{���S��)�Ռkn�+{�w�)���9S�;�ؗ�O�d1>z���{�B� T���js�;���������4��^ra�V����E�:/L^ E��AӶ�߅�S�X��P�����e����{���H�5�Ds��B$��q�v7!?uO�)!��5z�(�5�d���y-5:A�֜MP��gX(�6��g�)p��xB8lSUU�Ws8�ϋ���uo��~^YĚS޿����{�yq�[W|�c�A�T�#��ΰ�YG&��E�-@��ӨU�C�Y%���ɶ}B�w��I�Ɇl��j⦎w�����l ��iè&z�ݔI���T7.�Q�֔��gD}������ظA�n����Ҧ����12W���~�K��S�x��'�9[f1�@ؓSJC��N*_�s���5$�����5
��~�xr��o�Q�lb�G�1��*�D� �U;��evn��i�N�C8���T���n0���m-�b��U��H�,z����1+�e�&q�;h�	c��԰�qHCw��^��^n�c�3�e�9h�O}Fn�襚�.MbA� /�Ɨa@%���,�1'01��pX�+�s1����؀ϪJAh,��t,
�4�wl��=�9}�Q�_1"�� �&�ͣO�7Ӄ$�bR���.���1�O�aj�Uyz�?���������pÁA�<2���ӊU~�|~�yxB��v�|W�!�[88������,v@)�Z��l۶8D�˽S�⎋�%0  Ș�l�S ���=�z�Х��ӄ��|/Ҡ�z��D0F0��;o1����X�:b�f���1���$�?�v6v�U��݅�q�u�ºlk/E�`��Q{W�ݳl��p�Z#-����(��Ɣz۵��Y�O&s7&�(&���ɷ]K�i�{V�d�]R+O��6���s;�!�S�v�㖰��g	�e�/��������v|>��|5H�/E�%x���h�޴F (�Wh��ͤXy^pv���u���k��(R�M���|����:�/��T+�r��oI�����]G�j{/��r�E�b�DGy|
��%T���X?e|/����J����L`$��o
E��o��_��U�~�����d���a#��0��\`6��E��]I\W�70�I�����*Y���|��*��$�A#_^c�7�,xIL�C�O��q�1:s�S���m�f�fE$Y'G�'��[�'q�7Ɖl�V		�9��ӄONl�ln��d�bV��h�EV��*�|H��l	&[��!�z�F�i(Vx�&�) ���On]uC�'��k��IU��O'*d��{��x ��X]H��>�&��:n��ܝ�ު��X�پ%�[/u�-Hh\�N�$�^z��5D�)�q�'2�l������"��P �)(�/`�dlf
]3�;4T�Ќ�!�j�lV

~j�'ۄ�͕5��� ��<���A3 ��c���JT��A8�b��xVl�a�@�%�䨧ə	aZ��������y�~��ovP��Y�+��3z6u��L'��h���t|;
��*��#� +��v�� �w��uLAL[���\�(W�8��#3Y���5��)�i��������<U}����'2V/P�cG�4� jL~Y���=y�;h�<U�� ��p5'Z`�NT�v�ݘ���P�,�U�WT��� ���P
tL_ǉLQ3r�8����2���%�^SeAwQ�C��f�ΩW'��%(G4l�����A���"�������(�4#|�ڴG�]/ɛ_�w����޻�c�W}��6
=˼<��%o�He��կ��)K�E�f��0��D��I"�U�8]c��1��u1ob��g޺ߖ�5J����t#Vs��N�y),���c�y��
����H6H�l	��Y��v;e�6-��QI�[P����= v�����1�]`�X�eb�|&�U�1�K��]�@�O��@ł?)B9Y3{\��i���-J��qv�˗�M��(ZQz�24���4BH`��n�3%�H��̄����y�I35ڸ�M�`�k�l����|D5؅�Dd�f��?�.c�C��*��?� LZ��$>�d�����F *�	p��=�}Wޠ9ǜ�o��+ò�`�\��X��D�	�%0k͠��?)�X6��E�ݥ��Kcb���7c�s��`�iX��4�=�5U�:S�{�Eib6q��o�P^>J"d���GuZ��Y^D;,rn��A�=�ֽY1L�������i��Ǔh;F�����)�YON+���Sx����u�"�m��I����4�2�R��_���kI��i�ܾAz���$k�ȱ"Z��S1�=����M�S'4��� \g���|ޯC5I�,�T�dͿ�� ݒ�� 3eYCW@_T7�6�	���9��y��n��ٸ"�פ�Î8}��Pf���d�qku�>{{AL�F"Q9Y��i$d%�;�s����7	ǫm��`�$���UT^�؊<q"u�,� y���7H�:���3�`y^����&��qY $��o��Cb&[6��GY˯�qc ޘlt�� �0Ab��l��L�P4���H���N��̋g��V��,*J�R�ݟp[JTv�8��a>��Q�����3������JF�Z0��5$�y��#�{�O�@F����{���cXj���@ݘ�Gm�C�]�Ӟo 3��קo���X�I{�L��nB9�"�kҩ�WE�����u�ϖ�|��7���\�k_�ܓAdu�}���N��=zFKa�T���5��p���8��2Q����:�D'E�&KQ!CU��dO�˷��a؅;��%{H�o�᜸ ����^s/�Q(61ŘM|��zk���uD�Q0gyŭe���!�ɱY�NL�I������k9�A��v�9�kN����nӼ��2<^ŵ5�2���N)x�C��S��мc���ul#p���|�	�^�m$W=�
FܮĹj�
T Khpq�)A]��/Xbly�xF������	���c9S��:�w��|4����K!�=&f=wjU�Vح�j0�k�.�pkw�,�^�l�-;ASܱ7�H�g`�(�V��>��cZ9[b5�`���
�4%�.�,篺<D`VcR6j���MGF)�?��;������6Ӵ��`��U(Xx�ن�� ��xR�\s�)���V�����(�[<��]ɔ%S��LJ�nv�Z ���f�����	KuN�8��6p@�,�,n�V�  jY�}�M� ���U�8��g�    YZ