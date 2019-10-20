#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="264861614"
MD5="8ae92d8b25fb45e44e5dbfbce4ebd6e2"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19435"
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
	echo Uncompressed size: 108 KB
	echo Compression: gzip
	echo Date of packaging: Sun Oct 20 16:17:47 -03 2019
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
	echo OLDUSIZE=108
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
	MS_Printf "About to extract 108 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 108; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (108 KB)" >&2
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
� ۲�]�<�v�F�~%��2���H��X�����yH�Nb��4�&�p P���c��Þ}ا9�������.$����Ŝ�E6���^���(W|�O?��O�om�i5�WԶ�>ݮ����Tkխ��x��|a��6��7������O�2�^���z��j;�_���_v��b8�gs����/*���$������~��g�VF�W���(Z��S4�'�s΃б��a�m0���|x�a��FÝ1j���Ql�� �ϡ?v�7��D-]�#��� ��s�����Fq�����G�mp� ���"�x!�"r<��@�;��B�q�'�ؔ���bƽ(,��<?��y��R���(�;��woqY���QP��1��O��Zr6�-"_��=��-�~P|>�P��L�4L��؄+���c��x�<���ϣ�(4;G�^������i�a�,]Q��u���#�6���k�(�ȵ=���C��e!� ��g
%��G����%fY�����}���<�/��`���s?��4��3�7o�t��^C��cx�� :�QH����{`�Ě0�6��	Hs!��"�j&�q�lT��`�:�B���#�{�(W�?�������jHj�Y�����5�����e���_���_�?#�o1�7�����W�5��8�9Ԫ���J��~���݈?�x��p(�3�%��!z�3
X��
�gړ���4@
��i�_�Ӈ���й���y���yh����n��|� ��H=��+�,<����8�_x,B1	���߇�a�p��M��K>~g6�Џ��&�Q`�O�7��N�Ǒ��ؼ��ö́�u0MH9k����)������WZ����-��5���'�t�(|h·��.�j�]9��ϋr�O�(7�;p\�qp�n����	 �<�0
0K5"��@�Eh�-ɇ~P�@���(F�\��7nW@�����l����$~+x{&.��1�`��돎;ǭG9<˲�,m�>)P��<0���p�oۧS#q`��-H4j���{&�	��c�:`�h5���]pbx��$+�����$��3� +�0.���ney�&��^�(m��!�D*�����F�	�Ӻ��"��o�2�."�YU�o�]b�RI@*,�{1��i�-Gŭ&��cV$��IKW��Ry[���f����z���Ȕ
��=����S(
DK����w�|o���a�V�~�{��ҫ&#�q�E9L�%0w�6��l���4��J�حǯP� ��!�$�%�ЋG�?fsj1DlV/]���'�Vo��������5~%�J2b�T"�e�@꼱�ԫ{�_���w���Tg1I��Q/�4�o+H�ZtB�P�쾭��午�=)��DI�a�x����BT�7��$#��FHK.�;�c��eK`J�B��<0��(RW�f�!��c���ޣnMx@��
�8 »��Q|ۉ�@}ȘJ���wl�hQI�Wd���vܪ(C�*3����+��u���ihS��g
\�&�H������J�����]��n�@r>�K�j��#b�E����iL�`
$~N0��C_<6�"�༜��Cb8���o!�C#jCm¼)BI��	^ǖD6[)o���nN�_N ]�Z*���y��zI_%|'�wrs�&�����Tn� ��(?��1>FG���~IڀdmB���O!���I������|�ɨ��M��h�j%F]qj�����HK'J4t�~j)1��j)R�1/2��Ur:���iW����Nyi�/�h���n&H��i<����a&�#�p1���2��{��iZ�-.륍�9.X5�|S9ޢn��H8��_n��.�S�xb����9��Hc��R~��ڙ8cTu���c���a��+�r�Q��}$1*2�c�e���0�j�B"����dV��#� �Yڸ8�����R��I��".Rqi�\���7�gbu���7�4����o�<���k�ЙzDt���N1.ʡ8�E>��[���-��r�L*��o��]��X3	/d���O���ads��H�kD􃯟/��3�5Z8.���. �V�{�S[��m=�Z����s�����W�lU�+��S�ˊn�{�u@��@�\,C�n� F�vrn�o S����vS�wt�h4z͟��X����w�/T%4�6.��E@����)�L�c@Z"�2�a��nWj���p��_��;�� ��%q��n��}�`c|����ZS�G��^�xD;I�V���Z�c�d��Ծ/����/��U����Z�C7
E=J��mڀ�#�YP���#E�"F����]���Y8'��I��z�/<�ʓ�s\��[��)5U���M�J�]������j� !�a��Ű��T7+�0��Έ�^�T���Kݍx�],�Zy<�.��ڭF�U7o��U��?���wB�RJ�4���?�K;w"i�F�vh0�c2.�6D;���[����E��1@{��l�&l]���^
�)�Wm�+L����Q�LY��hK�q�� ���aZHY���l��3V��`V��������#����t���ث*���J�&�M�n
���d.�_Zuʄ��)q{v��b��%5�� ]b�Ѽ�2G�uS�j�҆��7B�f��a"}f����p�SvL`���!v�EK�D��Ql����w��+]��}��z|�}x�4�m���.�E).��O~R�T1<e�C"ya��LA�:4^^G�3�u9��2�Ny��̡.V���c�Z%�:
��t0&D��,�9�[iʢ�8��*����jH��t�o��U��*B����H*��Ԥl���"qi�V�҂��)Olf�S��)����i��:� ���p��l��U�;���M��VۄN?~.�h�:���؜c�W����W�W�&h���Z���I2Ʌ� W1@�1R-���j)u���-�є�/s`͐JiY��Q�D|���5K�nW�J,��||�L�3]�~�����P��i?u���,?@�aJ�V�|JWǝ�Q�}m���g�9�o&;��o� ��瓵�
q�@��XkeL�*N�n#�>��U߻��餄s�eb�E�*�O+ʙ��M��?w���ˈ��h�ٚ�����&|_.�'>B�����%��;w�y��;��B~\�d��8s�/|���\m&��\��u�L�4T{3Ֆ�:�/��q���^�p���Z�I��K�����l�xk+Ɔ,\�&�����S��8|���F �/AaX��|�F6Ůn��5
}qT���gl�A�ώg��z�G���3(]ͱG��$�Ѷ�=i��y��_��'�	*����k�;�Օ��ݯ�����[�7 �� AT �T������tx�@�wן�ʞoN�{�;��ȗ���Lã�q�e�7<�쟴[}�f����j�o�����1�*�&�)�b�D�w�t��NcV��{W�,\_�Uhq����cW����i�c�,�#�`���+#Hh�#�w�!.�%��?���:cx(CK�����:��_���a"��<C:�hB�
q+�+f�P������~�E	�n�i�s[�f�ž;
j�6�=�6�gY�}f��G�D"&e9�Y^Gl�5
�����%���U3��ć6�c�6]<H��&;XXK�����zK<�[���K}0i +8�>I��	ږ\��O����G��y#1�P���:�X�(Q5�5O��b[���eS�$���󎾪<�g&�A���eYB'K�*V����x}���^y�S��$��F���}`�"��r�֖��-A�\fŵ��M��9�R���bNGT�sH��m���|��%�FR��:�X�\���N-�W�2]效
��ZkcJʄ�A*3ԋ	�eQڝ��o��F�?D��h� ����1����ԟ�LM����`��@�d�$˨�3U�F�G"Аx�~�������~�xLf��TxrJrdH�6)Qw"x!mQ��ȴ��݉�M0	،_��d�a��/N��HW�q��X�g�^��	���� yXs]���c�L�\:�Q)��b
��]���*MT��>���6���0��f]�ޏX�H/�N�(�^�_��&gtc�9 ѪU��ҭ�nU��Hy|�w���/�l�v�=?���j�沷>	��\� �B�Ł!���8���زIΏr��!-$qïY�a�x�P$���d��Ç��
՝�&f���/�.s��ػÆ�G��\�@7S�>:a�!���z�;t���O���}�g�9
�{q�1�ն�<����.GF�R�;��]g�D��6��͚�Ң������`�h�#R�Ղ�	H2�b�.�aD6SǓ��Dj�ڕw:m�5���I��G����� B����@��z�.������������cM1/��9^L��g���%|�b;X!n�PPt{&y=�63Ƹ2�����3'tf��^L�	���Պ�1�}����u�$} �&���O=�8h���i�cJ�΋�9�+*E&򑺬���[�&)
8��V����y�A9kn��6��Ч)���;���@������J�V�l��Zc_�b��p����
{[�:л�0F\��a��)�a���$��ƕ�׿v3��RW��YM�U�m�I��䊪�SՃ�C��ܘ;t����J;Pz�|DS���L�����H�b
$��C�'W�-�#\+���r�?Wǉ����`*1��Fw�Ͻ=�̅�|�ؤ���23�7@=2}}��UKӗ�'����|��;8�+5S�M/'+b�Y�U{���|�`�5�z?�H��P�3u]p)��8�ˣt)�-ᙇ@�8����u�k}m���!\|_�y׻^��5i�Qk�&�)��5�zt��<9R��X��x+@F���UYN�>���t:�~}kG�[]�Nt��JDL�|������ʗ]R�!��>s�([��Xв�1�\�T�.�Z�����
�n0�}E���1eq�_�5�I��07!��D�Q/�h\(��g��C��>�r�X*�V�pW�D�?v�;]N�,�Z�{��nu�����Z�������?��7��M����4s�� �oZ��Nv��=<e��i�l�=j�Zr�-vr��ߵ��e��bΑ9Q`eS�����0���guL��vWfɾ�A%:^���,^z�%4��aY�D�������*­(���� �\���ث@�Z�Bf'�҅��.����*���[��QN�b�+�8*fa�K�"��'3�	�Wz�@Y:�
d�C�8q.Ca�5*YЗ��\͌�/]�y���#T���Qr���՛�	�yg��c��9��9�Lī�[^����}��RΜR��u�+§������.;g��H�Ŗ����眮��E���1�����������?
��%]Rv�Q������룐:`3>ū�tI�T���J�� ���M�I��$��yd�4t(�����h�,����w����_��Xn�EzW/}V��4�CG��տ�-�Bf{J��
����#���`����W���$ئ(�u�}��ʔ��@=�/��U�\�Ny�y���S��j�O���wPty�@���DC}�Kػ�U��T�Xv�0J�(qE�Oֱ�#����/�[�i�~� ��;A��c���3o6�V-Y�X�0J�}��ڽ%�tx��<�w{���6�$���@S�u��$Kv.cG�Qb'���r,�ӽq>}�D;�%QKRNܙ�����>�y��c��p!@���8��Y���I( �P(ԅ��4}��(H.�cG�%!���+,D�q�"y��˨�q`^T-^N\l5.<�����{��_�(E�#�]4<��w��>�ջ/�g����ޅG�4J��ȴ �x��k���,sW�B\��j�Yt�ho�ax^�c�>�@�f�>�q�����Oj�z�Q��'h�/��_��x��a�П	�K��'���B:	�ɐ��䎇�J��42%� �D���?���MF��c@�E�rHH-?\l��dP��#K7��Dh��R�ީu*	0�ɤ���)IJ�.%"��+��0C���SG�Z��T��z#r�ח1��L�$�*(���Mm�ּ$	%���+��4v�˖�� �`ïW����8�\h_6ur��M���4SBL��=W�Yқ��Y���4����:��p� ��cm6���$ �M
7E
�7 ]�sY�\~v�t)GE9ҳ����{R�]�A<�Y��|ß8���7RCa�&-WBW�qQ�`��Cq�����+��/�5�C��Y̼2�&��j��\J��^w��(�E�����\�����@v�Ѩ�6�k�I%�6��LLh���ZCY��l`���]]w�+3�S�22����ӯL��7 Ryk4��.i����$�S!1�	��Ϩ�������)�<Վ�qx�0F��K�èL�)�����Q�j�I�#d�`8�m|c<�>�a:N�U�F2�$���ԕR��J��k��H�������z �������@y6��y0���Oz#�>�^�ś����(�E�{W<ps�+�����|�8��ǹV:ίw^l�uI�7]60�8h��O��IV<��� �ɑ,$�L���]�"p���"�dv�v���-_4ښ�6�W~�Q���%+�Y�^8�&��|D�6-�f^���Y�/&�n�ѕUU��(<�W��nݨ#�^�3!�3�*(fb���d`;��N1j5y.���3��f"BV�U%��U ]�[��R�7�͌�����̜���'gf��y��x�U�Ѝz�����J��)�p�Vjz~��&a$�%����*�2��.Um��	���z�{���z���Y�����1��Dz gXՈIAsB_zf%r���>w��A��A�M���p�
;v����v�`΂�Gǡ�=w0
'�+m	DGݕT,�R >G`��F�� FuبCH�7�W7�045�E���z�XM��J�*��QX|p��U�Q�ե��=�=~���/
0�_8�Ìuf�+$�V�O��5�*���� �HmL�7$��$D0;�d�`�n�lW���F03�t�&�`�T��CB����h�7h/@n�B4�z��6�ʌ�v}���#��6`��s�{-[�4��Ǐ5V��Ll�����^�q�'��Ԛ��j�a��eΧ_	�-��r���Vd����9İZ�E��WO5�#I�,_E�*ȳp���W|.�TF=@����/��S��iZ�.�d�L#&�0�ʁlV.��;������.��P' �ܦG/5//F�0P��r��($'�e4������lL�,�.R�w�%�*�4��ǍzB�Nk�Q�݃�`8�M�a�L4�XK����"���V8�g�_�)�Z�*C55�32+�Z�B���-���lʮ��fn�3���T5���'+	+�7��̠���j�m:�Ӂ(C�����9+�k|K�CH7�Lk�[C��CU�1�n^_[[{��Gh�,6��d%,����r�H�&m�r���[���-���Gu~��8u�%����=Ox`C{mdr�VR {}01��%U&On:mL�Z�곩t_,.R\�Z������>��O�NЪ1TbN�>r����
���r�y�.��~\�Z���%	s�(5��y��w�[~͊ܧ�0-.���"W�6:�?�!9v���
��#�.tJM�W�`�Z8R��`�Y��c�Voh$���%�K���!}˻͌Bj��:�"gK� �2'��#�Wt� \��ˉ+4@�����&��ʉ�����+뽟!�9{�5j�%r�4ۙ����ǿǾ�����#������FHy�I���vj̹v�K�`�t�¢Qv�+���KjX�f+*%��ULY�+����K��tJ�U|���y�#I�Y�>��wEjL5af%�}�4$��Â���%g����Ӗ5���8j��e��I�Ң_���&R�,�j"ބ��	i�
�NKK�;��7,�|����������um��*����+�����YJ�~7M,k����A6�Cv��4X�ђ�q`1���җ��ׂ�*��:�Ki�֖�9ip��V����O=�tF����r�[���T���ek2���H��Ě�����"z��̊�����,��I�Cd\��Y[I_2K�	L�_�,���	���y��n)���;��q��7�GV;,���r2G�� sCt4$Su��$~�O���b>��4����g� �8<����a	�tE� ����{}l�OJ�i�8;�^���l�4�Y̪���o�ʊ�q��M��!����P%R�UpBPÄ�)X/�	 @�#���d���!LQم?�2N�Ax�X��N�
y%Uz��"�Ed,���xq�&ȾS�<XAb�#�S:�S-�B���
���6�z��6�:���؇��(�x�����zbB�z+ٰ�̝k��2�{��B��f��=���׏f;
�#�A8�`V��DD�xx�j��qJ�)��(.�V����,�1�|�Ї��?2S���I�f�R�%�Cd5%������ԇ��c/�u���{����ć)	�<�{�WX�x�&=nΔn�U��[o��1�����fhN���ʠ-Wk�z�-Wl̺<U���dhPT�l�z�eŊ0.Y��@7�Od%�\q
29����B�7�T}출(a'/q��V��~��u�
Y�p��b�S!������.�u�8����@���drg��
0ʱ�,�VV*Ov����/��/8�~�V9�Qn�y슭�������#�W�Gײ�ft�q?��8P�s��m\:[ϓ�x�_p�=AB��^�g�~�H�d>f(Tq|(�T��ژ�e��Rq�`¹���(�%�4]o�:���c���W�0��?�����=Z_Y�=pr�
ۙ�����m0�YV����������r5�V�0}{���`k�W�؅��M���m��*W�e[�����z�X�b3�߆�CaqGl�>lz�h�@$F��>�-�cCp_t�Q\��=ő�ȸ���Wgz��.UB��Wj���]�^��zX���
�uv���^
��/E�2Vuau�?.��ZS��Iӣ�:Wھ.��7�Г/�+�h/f���@s���3�yPb����c�w�B5����U¾��M���0B����J���e�Rރ���s�Z+��M���#=����;H'������"$�)�l��x�JFg�
�`x*�)�h��LS%����!u�*��"r:��v����h��BJY�;U����[�u���e�_��?�D:��m�������1[n��_�q������v����������Rщ����4|r_ Ƀ��o��U�"�ё������bu����\k��eBg�s��z�'�B�Z��=~����-L^W���o-�./U5������;�~�ZXO���H�L���F2�r�'��C�dB�r\?�F��K�tD�	�%=�lsDq�]& ��օ]Y��2�}ASV����P?�y�3e��G!�n�ȏ3�vv��m���=���;��Α���R����v�(�����֫�V����9���u�j�H|�]2j��ce`]Z�D����5��'�I��!�a�Ԛt^�����9	\�s~��!�_�-o�#�?D�H��QFg�q$����t�z/�a������=9�da
�r#[P{��j_-�����W_ ~�\���
�� �E){0�ϓp
������D5������x���t�z]U4���8��`��g��ޏҬ�듵f�cq�����=*�V�[f4�O*�u�Kt�l��|����S{ ��X՛���FZ�����[O��"_+N����d�ۃg��X1��f�ʳ y?�?��>0^��"ڶrr���h�(�ȓݺ��6s�n�6�f>���5.Z�(#a�q���	~�(T֛����D��[pR��)w���4\�����%W������ew{︷s��k�S�{F�
C�h��D��f�e�����j��u��"��w�4�4J� y>UV��3�D�5P����ny^�/�����s<��®,m��CU���?�X�1I��2Θ��d͆; o"U4�ۮtC�◹K��J�W���ܢ�/&�����^�z�d�F�Ś��C��:Y�$��fƾv��g���)�_���!���=��n]-�Y�THC ���:rgʾa�`�r�].�Dr�&��c`{`�Q�s;_<�r�Б�[�C��4�om��mA�i_A{,���5����:��aM(�o�.��^x�3 ��T|�_z�>�����`�E�5.��q����=��|S;��,^�\�õ�-ۋNڅB�p�No��6�Fj
hϽ�G&Ѐ������O��$]�ys�3�Q��@��9����9:�ނs�����^��`_Vx��Q�K�����O�fm�_ ��?K΁B�7������T�8��(l�7X#ga3M��ĉ|��s-����&k½�l4K��'��:�;ʶ;�'3�{E��/�r�b��!~}T¹m߸��ly��{�ܯ7���o�猝��޻W�wf�)&B��N��ą�LRL7��?���<_�g�pR�λX��n P�oߩ#j���~-��O6�D��� �n��0��A�rT�Bl|9I�O��]o�2�8#�$�o�y��G^D�w�N;Ɂ������$^AZ�8p*uC���f�i�?����=�W8�2���$�%�j=�Za��*g�Ǐ2B���_�W�E<+��(dfq�n��4d�=r9�bT���|ruz^0B�(ƪ���2�57����:�l�Q��q��j9�,�UD��,a�P\��4*�^Y7�*��ƽ���U4gv��>�h�D�Y�k�>_*9)���[xںc�w]&�.�������]L���w�of�j썧#Vf�%�ĵW��z�Q�)+Cɒ��~ɾ�	֡�Į��7��RY���6B�~��38~��@�T����]B3e_n,�M_�������l�sA1o�Z��zqZ�(��J��N��g�N8y���	�jw�Æ�x������]��=^���z,�Jb���~ ��?6����3z�O�Zx�.�H3�J�=>@	�~�yؽ!��}�.���y]��s�L˷xf�`<�V�ߍ�5���?)��jh�E׆ǹ�t�ޏ���=���'`���`�f�l�a8O��y�Eq��yڶ��B0�̚@*�mWk{��rv��֓lbކe�@��Tmv��r�1f[���H��_�~���?�uf�͞�?�;�Y���pum����x��q�N�����U?j�h��d�G��Qܣe�/���)0�d(�v�P������*u�8ÈZgq��E2:d<�������_�Gۻ�;����9::�B�>��������g�F'zw�ѣG���p����NG�3���2C=���f�SͰ���æd���	� �6f��������z���
���g�B�����8���e��Fv��u3��Ϊ*ZEW��iQ�^hո5g�!��㓼�k8}�\tNVsF7А|���0>Vx�4�O�̌/a!28=�@V�}e�%p��cp�o�+��?�^L�����z��˃�����C�p`��E�ˑ�"{ls�] �u[ J�H0��y8�ǡ+Ͷ��V��+ �r����G�$p�Nb���O��\�q�e�d��G	���K7�G��LB�|ds� �KM�hq㝌�	C���H5�R�H�u�1�)hV�[N	�Z\���'�����kT�V�LQ�%B�e��x0<�.WX	{It7`S��q��s���C	��HMf���<.?���_�˖3�&|ǩ��ٙ �J`'����|�M��,�(*p/��h��r�ۮ����Z;Mc����jĸL]�fN%\�Lsٳg����_e�% s`�FGo���X�&��x��!2nb��Mּ�
�I�6�	KD�@���0c�H����Ş3�uJŴS��)����,
�D�f�W�g@Q>(׹�x�l��L.�A8�J�v��bt�������M^�I¥I�� ]���U��b`��� �R\�G�?e����+�+8H���E,��C�yU.���裺#�?]р���h@��A����#�j�}�ab��nW]�ICf��xA�[�p���,&O��}��VS�ԧ�����]1k-�f��mN�Wa+�[FV����=([E����G0�/W���2��ؕ�`C��q�z�Xpgrn�_��Ri#K`T:S:���R#��n-62:�LO�3�a3=�pW�ƾI0���Y�R�bM[���PbF�j�S���m5��2�Z�U�w?�p
r:��M��wG��=I�d�|$i>�pCި��?+�౷��5���H%\�!��IpzY��y_q̀��6�'���fjS���,����ÓI�$��dR�ߜ�'��	��-8����W�1��Zi���15�M��P�N8��
�5ݧR2���C~N�.
{v�[j�m��Q�m�9w�3��W4�`AE0��/�"���h�$6�r,Z1wټ`����o=��ba��2H��Я��_J��n��l{�D����=o���p����'ЮZTį���Iu
*�+'i��\��g�ە�*B��`�5ȹmၢ�Z������ˇ����N:,��/`"��چU��)ZoBm��Zqʡ�xu����@hp[�&��ا����:N1uF������Ƨ��ܤ�L���ooO&(Q��22�g�K�[�c��b�s3e}�t�]�^��_!�m.�<��@��|_��ɱ�i"��AN�(��������vm�"�oJ|rH�.���M"������v}�q�?׎ɺ���x������r�}TYt��bˎ��c��Pv᠜�"~������5��g-�\���������"��ɛnTǩ�1�r{C�׍�����v6�>�����Z��Q���lL�V���xTG:�ږ.'N���"�����J�F�֩vx�P��� TQ����ȫ�6��6����������ݤ�����r�\������TCͱ���Μ�]�n{c�qs[A�H�la��'#V5�}���f��9���̓o�ڙ,���ޅ'�ո}�U���&֞Ԥb�7�	��5S�Pz�JAkOa�>�V�}L�q���b����}aH�E7���k^��{������&�MFŌ#�����|�W��0��_F6��Sx�����*����
��� �"?bi�$W���l7���ΥiO-1C����
���c6瞌K�hx�I�h�Þ�Q��q*������Z��9�=���))��l�ϑ�fB� �<�)�h�����t�����y�L��9l2U9�Zg�۹#����w��K(���E1����~���F�ě�cY�I\�O�-qFN�=&e�-�l��󁸁k���wd6u�,��3ym?�z�ET�}�+G
=�po8����,͐Eݜh�\�0�j�.k����բ�����"�j��W2��z����&�:,>`K�u��y�B���ԸF$�R �O,�**a���dG �0��A?j�])���ȃO��<���6s
�MJҦs+.o�63Pb�?�Ԥ�����0v0g��{��X�iϿ"T�+2�8�{�X���F	�'��}���궕&����^f�%�B���eޯyc^B����\�N�zT�� >xl��x!pSc�U�W;�4�K;�j5)��������(��z�6���r��+ \�mò��<�	�V;�}8���Z��V�VQ~P���j60��j`�� ���`�X��r�Pc���V2�J������l��V��5�n��*J�$�^��3���,�n,7N�b�'���\�y%�!֒J_����A���^!��)׹��e`�#�%[6lg��|��ɌY�77<���k�}i�\��
;�}�r��yuAҍzJ�5E2�m<(@�V�� �v��x�F1�#R͊��� ���~�z2<�����4}�M�36[�d��@�Q�d��R�.���$�&���/�Q�3��h�y�G��	m��9���i�f�h�*�0�UO�9�h Z�3�MGh�X�&��@�D^�w1�=z�e��c��)�"!�$�}������#�QT:>���xDi���pH���� �R<} &��d�,Q�t��?��q��Oӡ?����l,�h��G.�O�8���OQ���H��� ��iR�L�b��ȚL5�J�5�������=�")�?��`8"$bL3��1�� 0���<	14���T�VZL�|1�ѧ�7��MF�1�N�ў�:�+y��Vo�����mQN�r�qR�#�MɽȦt���k�lY]����+�ܘ��s"O''������#�nޔt{תO9�h���o�;J)��^�_�J�B9P])��!!D])��ؤ�qU0)��X�yX�.���P�4�t���(��T��Kp�By�"�FCW?�,X�h�Օ����w� �����R,��L��3����L�Ƭ���y�0��ïY�&�ey
iϗ��֪�<2-��sdj��u�LF�=ߢ��7cM�tĘ�
��t�̎���X��_X�a,����[��D�dqG=�H�H#��VWE�G�c�R\ܮ�lm�
+
��
�6�0�1�l~���Úi3H�d��*M�M0�������Y{�Wv��2d�O�����,3E+dִ�-]��ς�k _qx7��`:!tO�庐|T�sf)-*G��0�L�C���g��ix��^,�lT#c��_K$���&,DL fZf&f��e��&�	��r���@�8��u�[v�HH��{�l�]#���B9��)GZZ�p�)h�ׁ���"ЉU�^��n��n�\�曶���^5�M��A] ha �U��	Y�^��uZ��
�����s0��u�����#�boȗ2C[�fd��hg�U�ǰL=��1O]��T��RN�ũm��ٚ:\�$� �?I��=(�����l�Ó�7N�^N���8CAY#�f�n�!n������a��kؼ1�ik��JK�rC؛��͚���L�5�|i���V�W��^��0bu��᮲����Ʈ���#�׍��|��:}A�#'�c�.��+�'�l��g�l�`�q���͘������
1�M.�ꆩ`fq�t�&�w�:8��H��w�~�K,��s��m���#��L���űhj��tEժ°�s��[�@�-tC�1EX�!ZX,��<��gm�y���
�Cҙ�����]��Q��Ŋa�*ƚ��@�T�
;�q�K�q�g�cG��t�Pg�s|���9�y�y���5ʎ��Ө��3���V�a��WL�sYf�.?t]6�+3�f���9|?������F5M]&����� rY��s��۾W����I�Qh�0o?�D&0�%"m�˩I )�jcP�z>_.���i������qg+��^�R�a�K`��ؗK�2�-Dp�D��]��K6�`��4v��榬� qZ4���=��7���P� �֗?���lUU,Xbk3V�n7Q\	�6�$�ȅ�ڍ�4��':���O(͔֭n����A ��N��������Oϖ1'_����t{rD��w�SL����F���&'n������D��!�3������7��"��>mX�)O��8�ТG�Ϊ��)D���J��E�Km�#mk����25v�8�� r�E�{�����1l�֌t���
�À���ҽ06N��`$~�wi���J�����ʚ�\��\A�rZ.S ֊�Ԅ��U[`���*�Ɨ�R�)kI8�S���i~��$u�>�����JՏ�Q�j>k�9yX.f^�̨Be��fT��<0�6	����oE���PN��[a��;���7�<r�w>>���A���u�������_��g����_��;���5�coR����]]_{�83�����w�_o�w���M��tS�Ww�u���?2t��:�3�|��e���P���"Y����������6<=�>s����i��3c0��~3X���  ��V����?��t�Wd�!(L���>�8��=�Q�6��4e� S�iRim�.�Ғ*��-YD���i<z��7z��K8;T��w+3\[���;�s��Ϙ�Kҏ1^�Id(�0
�}�98z��ě%!�΅yx�2^|)ꈊ���S3s�����SEh�%�J���y�}��b�W<r����P�fXKb�,^Cv��</T�=�L9��LY$�J!@c^�#���!�)`��2��=xN!$��y~�E�y�&��CSF��#�-R[)��d���,x+fݻ��� ���Z�s�3�c
�2'M�1]�(�Rə��/��"�K)!��z�-�EHd)�x~��ݜ��㘯q�EQ0E^3�hF8r��Q`_��4��{�{�1�#��I�<��y6Ci�J���rav
E�Z��=)/]��`�Bf1Iw�SuMU�gJ� ����2r!T8����a���؏q���}���YCw3������ow����q�uw�����W�m����Z33���w����)EK#� �ԏ�7OTO��]�b����c�N[��:���n����̰�<�9fk���e�V'��9+srz��^;��X�9��S>�5�`�0O��_aQŢ�V��N���¹c�{ʣ�5���Na��+�;�L�����<� ��8�`C~���Ғq��H���*��Ipp�xn`i��C++�˨��C�f�-:Mhe�x���R%���ƙa�f��ge�e�$K��]#�?F_|G���J��&�P�b�6�Χ5_r��F�o؆濩�P�T�a]뒙6�b�i�Vr��1䍝��Ŝ��L����6⇝,|oHza����a2��QhĊs�����C�4Qm�y.&'�7x0G��Z}�����V���[����"34�������HcVqH.���=�@űoJT��5�}N{N��(��A$"�hO ��#�NM���KOG��}����A��<ߣm]�?d+�)N�kϧ{��iQ�����H���I"GG�FJ[��j?j�Ga�> 3jnw�v�aڻϤ��RR���l�2�4 �ų)�>�O��!�KF���D�ˢf��*�0�fw��l��|���:�#�40��ԟ������#o�V� �户��N�p̤��'5��	��d���u�=��VCB��o췿`�c�'��ȢF>��'}H��q�'_�2�ž�}��;:m��� Rb<�KAl`�d96Dzq�#֏.o�X�J��O�e�7����\k�<���j��W����%15N񪯚�Z5/U��tB���ȡFC2L��-G�����3UBJ���y�|����\���!*�{�x7�	0g�_[[}�������n��������<`D������4ob�z���Y�&�Gv�{��'����Q���\PdVVc��$�c�ˊ����ro�MW��Xz:I
�3���� 7
�jS�7�`O��3��Ճs�lZ��?m@�N�0*��j$隄�����ubdb�2��x�O��Q��'ZY�U�ə"���t�γ��Oa#��/w~��*@C6QhJ��Ǉ��ږ��ufgȐ5�xl�u@��ꨐ��\_7pjP�uk=�e"���(G ���~	g8&�a�Cr̈� ;�]yk��!/����r�%"hSR!��3&�E�+| ��_a��Cc
2�:R�J�{y�� �ja���;?�MmD�=� ��bEo���L�&���))@��j�4�s�{�!��j�6K9}��d~/^�]?�ѓIv�#�3��1H�9P��C_z�1f�էb���m�)�!9B=��?�~ �<���6Va�v�K�\�f��S��o�h@x�a��g����{� �i>�"�3K�8���ď�5�|bʭ�Z�t�,R�ALg��$(Oi�ظ����ٵߢ��k�Y���X�;��6���T�V"�W`��<g�W��Џ����;�W��Cv�3{�ŏV���b�u�?j��8�FN�'.�`�e:�-�jı�|� �X���A�u��p�>�]F�-��|�N���8�3�9~�&�t��t���]o�����
��6]�G���:��۹&�6g���?��X+��qw�w�#$������{G���w���h�{��~�vq^)��w!�Sy�C���m�Q���I����jT�}Ѽ�ٛ�Š~2E�樮%|6��ՠ���0m��j�4�ᱻX&#�(x8y���88�G���BC8��'����1چ3��W2�����u���o�bQ�Ma���?8G�U
�JӞKc~�q(�1��v�.|'�N4s"ogQ8�J�&*&�9�lP2b�N�b���i�|S�/G�7��#�Aa��^��"���`2lW[��Xŵ�ʶ�U�ŵ��� UM3�Fk���4
l��Hw�I8�Ƙ�h20P���5��x�~���V�s�'�a9����|�|�`ڹeXUϬ&�TbmxGm�9h�=q��@�N:X�ϵ,��}���5_�Sa��Z�g?	��σ�ꜞ����'lk�{��K�*���Zs�������.��f�U>��E�0�:���� !?��Ձ���UH���7g��=���Y�k��d�"u�ҙ �A�L2�հɻͭrհ�G�X���Z��5k'�u~�����YJW������f��:W.f3��o�^�<)�qH������@� 5�CCQ��ݱ�%���!�ox ��q!��l�ֳ����kw��?%���S��O,��ػd����Y�|�x����U�U�8R�$~�����s9N�� ���H$H�-��h6q*z�óZ���ؤc����M��M�E��G�J�HH6�?PNɁŰ;��*b�,V���*����s5����=G��z! �$���i�08���80Sg'5��0�WqjNFM��;�|���w��H���ɧ�������V+k����a�����{Th���l8KMR���3:�����Q�t�����,�cfLd� � ��ovevky������~w������w������~w������w������~_���֛� h 