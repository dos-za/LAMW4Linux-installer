#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3592227226"
MD5="f906758c00c7a6abe06807e7576d2712"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20464"
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
	echo Uncompressed size: 156 KB
	echo Compression: xz
	echo Date of packaging: Thu Jul 16 14:53:37 -03 2020
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
	echo OLDUSIZE=156
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
	MS_Printf "About to extract 156 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 156; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (156 KB)" >&2
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
�7zXZ  �ִF !   �X���O�] �}��JF���.���_j��j��{5Ӈ7"�b�X!�n�/�+eB����jЁ����{��E"����%cՋ��h�d�at�����곜P��v�����CW
Q�3BW�_IF�-ӱ�	�_.�U�`�g�+k�b3t�J.4�Q5�ױ1鬛�w��~�e�limL<4)�jy'���E�y�r�8}?��k�`>����|��0���m����3B@���.;c0a�C�$��}�z�Sgˤ}9�@��g�E��.�T�S����	<<��x[Z��\EWT_77?D���5)�zE�2�)������	#����}U��ge�>H�7:Ы7�R�+��K鸪�Gǔڃ?7�{�
�h���xe�n�F!���Fa<�{������ �N����MDwZ���~4��)�N�/��B0��q	��&K�2p��vYBu��}@�}��S����^��ʤ�Ġ@���3�_Ʋ�|���[�o �_od�	Y�s��ެX* g�(�N5�*۱�P��v'�=��j��|>�ɳ�+���b�)��Lx����!�8q> ��.�2nG:
��4"����t�l�>�1m擱E<s�!/Ӳ�P�s�x�#�ٟ�~j��6�Ď܍LE���?��8����]6�y����E�)5�z.��J��S�������JBs{�t��T4,�"��]�=��Q��
W�]+���s~��0v3@�]�z��M��1�e����$�N�|�LD?�G�z��J�.��Uo►�>)K��<t�k����x��Y�ָ,ֆ��I5�ݖ�4E�_�y�&���wC�[h����+�Л��A^���t�aM��-={Zw��ɏ�wnV5������S�O����U���W�Y ���_,Gw ��E�v�R�v%6��k���h?���.�jT骲��C�WNu�M����ė���N5�J��Q�&��� ��i�k/x�&�p�2����Kz�Z2� ��8��ά� ���D��H/��U�`�L��	S��;�a�n�W.]�h�#)\�_/1M��0f�� u���ݏ: ���#9>�D���|��P{�܏�끙�z`a�˹��Þ�@�2�A�]r��<f4�0�{Ӌ솢��F�����x�F�A�.�����A�|���C�!J�x�7�?���,=BwuR��+>��:��V%2z�˩y=?,?)n;�����
��|}�;�f�OA�[����22�$�|Bh|&a�?��$r�Yb��Z��5��(o�Z�aR_��>���9��"���u�����Pt��=�\�M]�[�np�hw��O�Db?q�H�0]#K��,��%�j�չ��E�َ�e?��xyUc�M��|x�����l�9�m�"S�=�g{�r�_A�U��?3H�>u�JD��<�0�댴r�d�@�u?IRr3�����F�6�A3�Ѹ���n�P��+eL��!D͖{��X�|�m���Z&���/��F�*��R���j_R�f�>]l��ޢ��,��y)�!P�>���O5�fV�I�?��Y��}#�X�-vo�@z;b�5+��Kկ���(�����"�gǃz���9�4�h%��EpL�=Mp��@.
QL��Nw��u�OVDx�朚����(�a�s�؋b疦��{��7l�v+�����_�ׅ��d��W�I�UI�F^P��
% ?�Ð�������L�@��&���&W��^Y���T]�3��e{*��j[Մ�|�f�UHb���:��9��N�|5���ı�"x��[����Y�F=z>[Il�#�Gp.�2��<,ac5����'��c�R(E�:�"�SΝp�G{؄��S�^�>xg|{���w��@~�"���lYP*����f#��b��Dʽb�>�[s%�s��!P�'�6�y�����q��6�����D��#R�����L�/���k=��+{Fraȇ}|�Z�:w2T�7�\�+��=Y�6���A�o6� BΆ�������]8���5+#]
�!��t񭴵:�]KRt����q��6�lⱪ#l�hp<(tN"ו���+�χ�62�'C';������(� �F�������N�n�7W�x8G�D�@ن*���5r��:��J�ZnX��\����r�k5V7՜5�f���l���]��k�j��?Z�����g�2ԇ&��'��ZD�h��#�~�|�*�e�q����3�z�!�1���$T6��mv�����Cֶ<�]d1E�9�$�Ym.� Dfr�&7�Hg#�X
����{��4N��jOR�@�i�w�6�}��B~�G��j0�����>���۶��U����՚�Ȏ@�~�ܸ8;ث�	�Vܮ�$LRKR$K.Չ���A��d5�4���)5SP��z��h	�>�<�5d��'Z_�O͚'9e��;�����Y��!��u���k�� ��x�O�w�DR�)��ݤ�QΔ[�\�*�|���y����|T�)��>w�W)�����B��m����+�I�i�e�X,��~(��^��f��R0e��ζ�ֶ|���(��s�Ha��ݑ�r:ɺi���YӪLw��� W�N Ñ؇�����2�'���n��4D�I������Cb]	��\.�#=�ݧ���͹&�CH��8P\�it�3��'W!�c�|��^_)�{l���[�� �w�F��@��X�X[(�֔�^@y�,��n�|N<�dVа��4N���<�NyB�0�P~���{���"�Y��8�Z�� ��E���3�þOI�W��E3�V|������+��ϋf�<24��/�t�[Ž�%�/�����y������)P'����lpI����.(�}Uk5�y���/�h!x�pK)��&��]h�T���Uu귊�
t�: {�[����X/\��_�x��I��)����{�d:�A.,���{A�LU�Kp�f������A����A\�0CmqNʄ�@F�����,6l�U�����|�*�Փ����ݴ,��L������J}�>#LB��ƺ��X�xs����?PrN�b��%_>�tC�v��`I�p������=f�y�[�}��E��g�ن�D���5�bB[�.�F�U��bN��D��A(���\ac�b
ϺĒ��^t|�́#<ϭ��N���~�䘂��Ї>\'��G�33V���iƇ���S6t�����G���aY��L�]ۯE��Wb�/���Z���~I\�!�h���'k�P7W���+���A���i�
��A.j�-}B����/���3&�m%���E������t	t�ɉ�"L��EFV���V%�h���[wmů���U���U
��H� t��K���k�˹	�{�+� ��0&Bt����w�_-還�(5�h\��v<~��� }v{':�	������c�Hetg����Y��]4H�OS���!�u� ���z��]�9�~�^r �GE*t�]�"O=�|�i�g��۞&�rv��a�	��+�׿�q���q����O.��!ʠ�U��i�������}��-*�v� �3n{D�5Q�[j3�����Nf�;����Q��;����D�J7%��0J��v=�4b��<b��J]Ҳ����h.:-�;�Ž- �e~Er���.�ogN�G�0��̉1͋�``m��Z�� p�����&
b�Q�/���pC5�s�[_��Y,��'�N���<!���ׇK)�Sq���n+u��,��^���e��<�/���Q�#����j���:�̲�Hw�8�m���MR����J��L3�UzW���!?�-Ȅ�r�[�9�D�,ٮ�w"����>��߮��.��r�j��b�؍�u��9�]D��3���%�^�P~�o$Ƹ`�Ζeb��0۟rn�,�������4Cu���Ѥm�`d�Jy��z��U�GEh>�s��PP�׮�41��Df�3Z���?��[RW#�;h���ц�/J�K�b��l�+;ew����Ĝ�۰l�祱j����i޹�c�}G�2�=����`��r�כ�V4s���rdk�oB$F$��풩�T"ç��n�����z������8�B�'�(a���̶2@�I���9g�Y3���+=+�4�s㚜C���$Ip-8�b�L�!K1]�4m4�ywcJ.�˦���7��Ԯ����:�b\K
�q�8o���p�]y�&W5[��1&�.��;�,?X	[���;[�?Қ!�b� ��m�<�.jz���Hyb
��Te9[�P�e��߅lj����5�dr'��D�"�߉X�EB�V��N�3g+59P42f[@T�ޔ�`�I��˗���� �[1�L;48���ir< [�����wW*�.]!e1mqfg������\>��tu@G��;��Q��r}r�{�������_�$>X��+
�l�	#�3�xe���yB��]Y1ؐ�oY��u�~���-xd�����_�+������xrׅ<��u!�׍�� ��QR��8^�����=E�L�k�b�j#��}z|ʎM�j��B�''-�����\�.0��)����ި�X��I.����ڥW�U6ʜ�nRT���Mc��V4�X-4bƣSC<;�������f1Ł	{_�V����c�d���\�,u
����k����t�%]�Z��y���K��k�uLB]X0h�,Mwo��@$�&��^\,�����r��_�b�q�T0�#�4b� K�ĺd��B?�=��|�Hg��+F�.M,�֪Dx���/����
X&���ڊ35�W�c4[b:ݟh.�\��������㻲rQ�(�m  �[	�fw�<��G��O��͙��)������i�K�aw��;��S9��I��'�~V�&���Jvy�X����n�\�6���d1�C%�g�`�ݤ��s�:�@,����d�O���������#���n��Ͷ�[؈"����->gGoy?H�B���|��{��,8�� �:T_��I�VOYn� w^����� �.�r-[ڪ�;I��NΨ�8�0B�یP��┓6��l��KF@��ރ���K�#X:�,�P���A�â�y1O��Co�f��Y|0 ��Lu�j��&F?}cV%o�k� ��v��)��/�P�#���Y_��s�-	��N7�7\L#bm�s���z6.˦�R�^�{�������=	��c	��+:�p	��S\7G��ҩ�e8ьE��&�a��w�}�{B��zi#�8�:��M�\�ZE��fSe��X5����΀(&E����숱7;{4<���?h@Ew.9����o[�ޘ��v�~�Vi���0lb-͓Kϊ3[*���Ό�ů�������$r��TT?д��vʚ��Js+p"hd'!]=�gl��$�a� ;6J�S��YYEk�>�s�a�Ae��YPw�8�����o�lG�*� p���h�e����V� ���la$~|=��C�3��� < `��hS��O�p{Sꢤlg8���*�/�������>J%��X,Ş�*�;[��ݧ�{Ǎ|$GLP�溍z	�~��S�Y��3ז���5Y{�-����`'Y3�4nR�|&o[�B�Lb��Ck��0+�S��՘��LEL�3���?̈I��̇'�N��d�u��b��y�����G�Li���߭<-��81���P���#ɢEH���u�ۑ��wИyx��oS`�Zu%�0|oZ�X��}��p��6�zfj���Wi�mh���A��;��t�I+�o�Z�5�b����b�*�,L�*�$7�p�=����+�/�i��|�s�]A�l���?�+��oeR����G��������,a��{2b</���f���UP�8���q���{�_��sg<��N�D�;G}�)!��>�s�HH�q�Io-�� y����2�\�[����U N{� <Q��D2)�N��UL�_�F��|��Q�hg4ց����o��:~�P�^�/��M�tE�Y��-��w3�bJ���dvF��
8�3L[Ecs�bM8ΙnS(II��-�8�	����񮂎������~ue��f�g��M�"�.~�����H��z�b�/��o�Q`�b�a��TC�V	��Flh�����)^�er|G�M�y��%@�Ƌw)e�}�n��>�d���I�G���j��/B�gJ@����Z�ޡߍ��%��²
�^I�l-��>lŵ��os]�
��"0���A��+�$���6��C�1����VE-䝧����όS�
=� ZR#����r�a�`��3�<|0���R��u����_;��,Aa �Ǽ�M�I��h{޿ϓ�_���9܎��\G㩂쿲N��L�C4�a#���a�w_���6�Yj�Ш�c�A��F4�t����{����"���Gs݀�줊H��6J3�r|�0�<89>3�̹C�M))fՌpۀe,�}����)��s�j�7C��
N>�ƍ<."�����Ub�)|�� i�FS'�1f�R��E�6��0h�H�c�~�P���X�;*O`�!9,͚��R���.'оw��5;.��˸]F��Q�ʐ$��'[	o�����Cg�'�?�@>�ɐ(@g��$��1�8b���G[9}��4l%9�?�8��d��^h�7��@��z3E,N�_f�1\�'�E�t��Ǎ%����#�^P:R C����/U�6CM�%
�v��Ũ�8c�%F�%�9\_��E�E��%N25����7��!_��_Ƥ��ߦ��*dz"'?<�n�>"4��#�������&�o�%���F���!U�T񏝒�| �IhLP���]��A{-����Y�*�Vܰ[������+�[�'�N.�#����2���uc���;�h*b/�\4�y���,P3�j�x�.�~ga	sRCk�'>�A79�����~��@�X����
#&Pñ���㺷�
1}��?
���+N�u���ScӉ��n`Z���7nˊ����}c��x���*%ϏG=ǡl������u�9�^S��묈c��
�cjW���A�(%��)��2M��V���H�	�V��~{ ��O)f���f��<����c/�ԛaZ� �u$Mc ��c�Q�{��p4w.��z�;�r1�YQ"��A�5��cE�]*3j��?�U�w9O��l+�a����hv[e��~�c[�#A�9g�3)L�9����}��^Sw-C�^>6B��lW�<��6m���x�ʼf�߇=��L&�,�o�]칥<��FL�-��r�����3�ϋ���y��3x�8~.����X�i�����[�VZ�j��c�k�����!������u��J�}
:�����<�����<T ��<u��y��"��@��`���(֨A�bPx/�ߛ�o�^{b��eo�,Y˂�I�� (.V���2�{���7
'ӁKP��l�
���Z6���~�u�Pe�2��@���M�d2|o�-*#��7�4���v[�U��&����u8��&+ة��ZRBj{��(9���|W!���u���$��u5��SkC��;��R ~�s@�Җ��j�n�zP|"�>�ߎ�2�Xp�����̼���37��_���,��m6iޛ<��1�b��Lg��l@�
m6�|Fy=-�׿����,'E�J��q� U�7�v_x�k���GX�&2;5{�T����kx[����N��I�x�oι���}�kX�^~b8��,K`�Q���1��o��HH���s�y;
��B�߈u@�S?�8��W�]����<2��8�N��N�E����9/���%:��٦���5i7���	���)�� ��izb���Q,�
=ϼ��iT9R������)�I.Uj(c7��-�--S�1�a}��}g�/��v�x�����S"���D���A�z�WMu�MK_K���qr���~(p7-DE�]�{i�Dϱ#|j�,�3oy܀����U�;=y[�88O[ȶm:L��$8�`��)��	�8m����Y\y-� {( H�S�//�/M4�Do��P�֠�MOr@���Ġ���np[�ǵ���A߇Pn�\���/!u;n�M2a�[υo;!�[�J,���]w0�q�_�L	�Q�KJX������1-�,�?���Q�WQ��y�zc�u������A�>�ﲭ*n��p-���B����qX��-��'�IR�G��~�d,7���od��Kd��}�ɷ���Rx�I���c��|As~��\4%�M�:��v&ZmyGBM��PK'(mN%U5DH��g��N��5�)P�@UQR0]ڇ�rI+�l�f�M�*�i��Tr�sC�gcmrnzY*��*h�A��Kx��0j�7�I\`c����
�-ئW�D#vT�|�����r����)r�2��k!ۉ�����3�4}��Q��9<[�]J�Ə�t�%�~�����t�X�����ݮ�' ��S�������� m�ܟ��O`��hl1�Ʋw� ��X�'#Z,j~����j���3�JcJ�eb�l��`��a�l#i�ا{S����g��o��xc֣�GOZ P���o���KNm����s6��E֟=�����dH�\Q&u�3P�O9w =j�j*��.�??&�����~t'�<4	:V�!���>�������+��D�bh��� go*4R�����DJVm����t�ݭd� ~��$!�Y�f��#j�����V5$n]���~2�@��)�qQ�HK���c���POչ����	5��ֻ�n���g7�"LӲk�n�J;2����*��ڎ��@�����y!��D�X�,TU:�7���*;"�e��aܦ��vu�Ϭ��ʉ��V�z}���Ų��1Q-��WD��u}A�r�0�M�"]Bv��DJ}�ڭ�-5��[>dO�u�@v_�OC'�.!�Fhy6} �N*�E���<���G���F�O��#�����0�<Sd�c� �{�0�*��	@�r�.�j/�9���b3	����Y�j��i���������q�,�V^H
B7������1���֠���3��5���||�4����XO���m8�Ñ2���:ʮ߮�(�[сQ�af��Z�
ѧ^-�f'~}�²�v}�4"����
�aΆ&�j��^�UP�t?G�� >rj�\߬R��^J|�x�Y��pC�c����a�t�$Ƽvp�g�Y?�ȂV������EC	� �'���e­Lk�J���j@G��F[�{���Tp�-�n��/R���D�o�i�,�̨*n�/Wu�A���I��~��S�F�|4r�����B��0U�9]�6���T�Gf��| Z�wt����);X�ňp�.��������u'����Mf�I^x���8�b��	x�Ncŭ�~/�_ڭ?vpF�ߐ��p�xs�M|ֶ^�U�JV��#�<����h:�$�+ܖ��߽$-�|��"�`�:-��S-��!�k�݈�ֿ�k�S���xGNr����V.2�v�{G�_h��aƏ5!b�M��Y�N�7l�pD�ɹ�兩K�4tC��3�����D �J�jc��嫬��2�����^�0׶ �Ml*��GT̂�ª���*����X����b&*9(���K�ȟ��i�$H��b��«y��F�K���u���º0H��� -VNL�Ѣ��[�B&뢷��A�Ҿ��`�;��x���﻽:�N���)\>m4ٲ�N!}��"�<��"�xk(��F-�{t/���Śe�'R���v��W-Ǥ�ڸ*1jm�zcV���f�ց�J�pPA�j���
��(
wN���+]s���m�7�*{�L�+�ݴW�L�aO�3"�	:�أ�u�J���1^����
~r���(-���~7��_t�<���<�)�gb>>~g�x�+Ϝ^&�7����	�Aw��c8*�4G���b�;�+��Y����>����v)u`6��͝�G�K��緹�v�5��������Q��yM���m7'+q����c��� ��s�4�ύ�HƪE��䔦~}��Eu_b�Ց�t���,?vH��p�})f��9Y��̏oN�4e�'�#�e���Y��L'��-.�LÈ��-��=���������&�1Ƕ�X ���K�4����P�<>H���	nJôp��X������)�$�����`A�]�Y5��� m�9�Ϸ���q���3y�?��x�f�X�D܄B�^xdT�.�Y��@^��h��Å��@�N��O�ʕ��R�_��Ȫ\�e{ H��t��<n�r�]�5'=t4�Ǎz�c����GһiYgk�ZݙzM��C(�;��4����芝��A��M�Y�t�#0����F]Pn���xz�����̻���ET��1;L)w*��"#B���Cn&�������[�����1��ߟ+��������c)fSQ#�bB�޹y�w��J1�)A�.N��v��jU�������K��(J�]��+���[zw 5U��^��+o�L�Ya���*��|rs=@xmB0D{ [AD�7�ݽ{�.[M� �"p��F�?��:W���n.�<�����-T�a�E�ҁdo��!W/M���ϴ���vl&D#��`�ѻ�W�4-��#��ta����"Lt��}�	X'�]�A��5�x�K��]�T�!ܺN/�ə��:PoѶ*�[���ɟa@W\�>�����7�@��H�/[�p�ˡ��y�6s�Eo��J9Ex���:N�Ki�1��``R��I�ﺏ%�� T�(���4��n%�ꝷ0��*��m:�i�Ί���+���rښ��?�_�j��.��jF\\X��YYW�;ܭ����I�@���| �V�@riX�a�!�gH*OHn��-�$���m��Cl�Փ�O��s�{��ɡո��S�r��f+3C�j
?�������B�q\��tf'�yv�u��#�@���ɧ�0�Ӵ1��{�j���I[Ɩ#��K���z�RG�������5�ˎQ�-�!1�� ���+D!��d��TtE��A�q��iL�ʺ��8�=�b]8�h+)է+�r�[����>��td�J��YI�:H8|�-�R Yg����**o彯��ܷ���i�d�L���V3d�k�qK�U͒�W�5��~�-#�Q��4 �B��1����U#��(�v��-O^�${��}yQ�cq-vT�0��`���4g�v\�������2Q��k2/"?J4��sEoxf�o�ZM�ۀ���>�����JxP����ŻԾ��l�����@��,�t5��Z	�v(��g�>���&P�����1E��\���a|�@ů �t%o2Ә���mߌ��ew6��C!�_�u����Ӆ� �Fo���:$9�J4R=)�_j����D~�3����]LCI�߈z��;�g�?�\���X�Ci���Ql��	�|�������)�%����Z��I^@T�*w`3��T�.���0�鋚^Z��3�/a��r�4ԗ5^�y<ʐ�ĳ�,l2���*�ۥ�_A��N��/�z��(\-��@�
P�S}3h���}�عoஈ|���Ve������+Xs���'h�NL�.땔|aP�A?�:F�"�]i�N���ٽ9s4��\5�c���&��P�~�/���.��!���	W�m��5<�ƬMI�$E_��TՐw�@�n����'bo]&�F��ҋ=�'{�hBs)I�v�,%Y�$Ɠ#��2VM(l��T_���&p�^�A�D�s��H��7�����ާu ��-�_�1t���e���~* ��9�\ȝ��vʉF�ޙ+��b�pq^e��Y�sN��2��=�X,�f��#Gq�n�Ӄ���R��
hRʋl��U������A ��/T
������Z�'�|��1���W�ʧ��ɢ16|T-�ﰋ�~G!�������,�H�"�/0J���XN�f��X�U/:�����Ź�@��<�<d�ȄR���Oe��d�Y�M��d=�}�Q V&���n��2`�U�!<�6�`@[ �����(���B��G��ih���
�k7_��Mn�(�ي��RdQ�0���Ѩ-����B��� V�0ۢ����,]QG �5L�ZW�@������� MD����ݟ<H0���G��È_*s
��.�4�A���r�^��\Pq4̛�5q镗֟���76����-+�눷�[�j"��������{���I�X��Ѽx�]/��\N��H-�g���/6Z�?_�XcP�"
c@B�$+�ٌ)YC�༩F(>�v���o=BQ�)����"kL@M$g�Ţ<��n�@��.<U��u�6̺+R]�� ?����ֶ��u ����0�O�{�Jp�j-9-�f�k�=yue��r�Ʋy]4��d�"V���2�?�e���
�=b�\����
Wi5:���|�M#%�`6 ���"�	sJ������9Z=�>6D"��Kf��N\�ۏ�}W�� �o]>x���Am�m�(B�����v��+ҼU�g���6��DX����ڵ[񩝯�H��I�����Ӈ�H*��=v���R煟%��Y�;�p6���4�K�	;�!�'��3W�K�Ф����=k�C3[��.ș���v����Ѩ�qW<�A�|�y��s���������sR����]=!�s�JQ�ɩ�%wC^�kc67�s� %o�h.��I���BA0drp:���e���(ċœ��Mn��&9S�eI�QL���|��L�{g��_Np��H4F�U�˻Dۊ�a�7ż��	��x���<a�E�����rQ�|�� ��������o��Z'�Z��|�7��k޹�S��:�����R�u�L5�O[塶���B���vҽf��.ږ7���%�0�G�9Q��?�`��+�KZ@Ua�w-N��G��k���}�|�O�k)$�bSɧΓV��bw|�i$�Ǽ��x��g�l�z�R#P�GRd+���*G)&��p؋�]�`E ������|�0���$��کeO��ݩ.��/���XOm X�����i7}YJ^W��wYm���{�[Y7�oZ �J�g������z���6�@z�L��r)K�N� ſ�\MM4�էm�s,3H������~�<@��J�ȅ_]�{�(	�W��qT���?����.����vj%���G��q@3���Q�����d��R�vF�2�h�8D�U_̧���e���eB��g���G�aÏ�~q|��bR����?
�Q��nG�I���S��LI���w����v�� f�<�:e��n����6W��Ĕ��e8��۴�7
����8734ٝ9~�ቘ�Lty	����
���?�9���P�Ɇ�gC�9m�֭��śݝcp�$�R{�޷Y�"h�x!&[��-�7� "_����MJ�c�i�j%��r�+FB���l��!�dP���ԗ�3��\
h)���09��^�7y�m�mz|�,�iϾ�l�:�E�c���� M���N��(תR���vƌ��>�.J�++bIy_){Ϫ=�oN	7�:�H�T#o���=7�F�w8��o�S?!�z(��s��l�M-���ӷ��^u`.{�<���P��i�HH�c��k)�
�"3�\��Ё�g=���6U2���Vh��K�W#�F�ƋR#�fk��f�h������A��N�Q*�q�ޥ��͍�g��]����z�;f'���j>�h��5��'�[_����+�����eh��eB������C��>4_�1�{3;u_���+}	�[\G}+��.��i��wK�(ˆ9�,�ryj���̮��.���E#Z�^e�o`��b*��t�.��Ӊ�K�>T�����1��[�#J7+9?&�����9z׿o�h8��ʟ$'�q3\�P��U��#���'��j
{�Fa�-c�g��1��h���}{�Y2�[)?��h���4�%�x3s>��g��T�\v�8f[{�%�U����2�Xn/���Ͱ�91���%6���8<���o��y\����a��׆�y���X⎳Z&��5��J�Vv**�B0�
�n��ᛂf���܋e��XrJ2~bBc�ߐ6� "��g�
'��B�gZ}��gHaY�c�C�\���R�8���ō��jG�x��D+��9d+��iߝ ��ܯ��6�%	1O�|-<
�&�ь\�&z��Y�`���Ek\.�m�����������-we�ٍA���������f\KY��pW냍/���o��h�C�j��i��6�~����@{\~*��Id�L�&H�*}�L��8ok���or���n���֥
� �
���|� �)����%�=Z݂.��32��w�������z8���ۆ�h4�9��ǝ���-מ�@mt�����s�8��]�}�L�A���	z�v�B����}'�5�"@�	��M=j�����f�.����(�~�0�8w�@C0���L�\C���E�Ύ}��#+iG�)�KEg�@������A,�#D����j��X}Q�QJ+��.i{�n1�3�ߊE���`�
�4s�����W ����2�y��8�m*"w`�:����@<��ZA�����d:��[���O��r������s��� U�����̣��1<P�\Kj�q+� �Be#WT�>�ԏ�2Cz^֓��o��Ϙ�0��JeB�c�P�?�����8�bU.i�K�[���A���!�b�S���^���N��p�Y��X��e�����r�6��q�%XQ�}�e%�P�2ug�e�.�Τ۱q���?��ۼ��9`^�'�@�w8����4S,qq��Ɗ���
��wX�	��n�6��L�����&���OQmZ>�}����*[C���j��D�q�����5_ԃ,���;#�!�]��b�/�U��8� ҳ��6ń.֒�y���$�c����)���#� �5k����>���d�RJq��N��z��ZMS��KO_�N���z�Ҁ�a�I���hu�W\o&t���O�����n2q�o"�/��F`GH���z�p�ر��ӣ�)�Hϝ�KH�V��q��E5E?ix5� �R�WbLp�x7�G�i������r�f�*�g������e�.����I-0?�ɽ4�``��7�0&�Ǆ�@~��_��|\k*�7k�`�Q 4��WQd&rP$�vL��c�;��qaMk�'%����E$�*ԏ��XG}��:��#Y?��15C�>ͨk,�Nܸ��/�9��p��ܭ���k��~�Wana���\�	h��bXi#�����Fz�y��1�μ�ƽR���8��d�8�I`$��\�;�aO#�SX�h�ڼ[D����Z��N7TI��̢���f�ჶ�ǀԉ�#:;J�h�H?9%�O���_��솢��W��,��~5\���=�I�D��>���~����m�K�w���H�u�Z�`�;����W����
�s,�W��!��2$6n����g獴����h�⺔YK��#�z�vho���=���Wo�A~���A���&�w�n��z;��֮m�N1�y��>�g�E��0����K}h�IX��
6ܜY\�	c��=c�K:��[0�zj3���ZפM�E=���S�+dP!L�=3Q��Y�VF��(�n+�޷|'S�f��Rq�V�Q;!g���]������e޳���F�پ|l�R[O�ӵ>Frm}�Ρ���c��H��,�/�ݦ��2�<�:�=��%Sl){�;2"��׈5/�ؚ�~��\�P�Dj��K�kjF�A'x�{ȸ�����t�8�ûC���pc���H�& �r�k/�R�g{Q�[,]۩8��	n�B��j�S&E/R�<�Ќ���h��,5��8�%�	B?e���}��m괒�V�p��fa+�=���bɶ��c���Pgo.#A�&�R7V<�� �����������4\������Aǐ9oe�?%���T(�{%�?[�L�;06�RLI��{�P�&v��u�5�&,�?a�z'�UVH�,f���"��4?q�_\)H1j�߷Q���T� Njp��9�_PfY3�y��y����6iX
�ȭ�(E@nnIL稯&Fl�k�C��P�����\v0���k{��'q���Q+(K�Ɛ,��{Sv�Ep��'�u�7�I���5�YH��q�1�'�.]�m�|�M!L���s"���'�Ki�ﾮ!���gX3��]m9�������n�/���;��A�Ʀ��A��}�><��6�5-	۔G�̓ˑ��)i��v�c{s��?�i�V�2����`;|�E���r=�lZ	ݽ����F���a�]��_�-���$%����Ng�q�~VL`6f���g��&��>k�J��Z5w䣾���?+%�$�QA��7���9��@m��2����
�.zvjܣ/��y�t"�cKx��fRWJ�d޹����.�$-Zţ����nX���������u���3����!�(��Ao��䫗��G���1Da_C���Lܷ�3�M���M���~���Of
,L4PW��f�;�u����D���f�D�j-t�{,��6w�t�~��*7�a?n ^�
!�R��&��*%EN�y�~}�ŢZ|W�!;0ٿvNΤ�X�q�.~���¦�(�XcZޕ7tT䮣x������K3�uY	ye�캚��O��ҊW�ߚ���m���CJ�g��sVY��p4�?�p?�ݺ����4g�9��F�0�p��>��H�vn�ֶ���?{��~���j�
�k�+B�I���kn�	�@}Z�6�����W(�|f>�%�d��2D� ������l�-�CC����f��A��6Y���爕�V���	Ge����{�Q)��Xj94ʊ�&��{R��	�:���M��^�J]2�U�����8��	S���y��|�!T�����F�`����u^��Ȝ~� ��;�A@M��L �i8c��0��P�����:ޥ����:#m�P�H�|�D���z��At_�����[��VLB&{�=�%��a0E������Z��S��ҁL��i�
��J۴���R�=��0dSFC�
sz�D���<����s��/��P���f�Yj�����+��8�K׆�#���J���Ա��IU���B�m��kP���t~e?B�!�Q�ٟ���s����F����/d��OU�|�h2M�>W	֔Lt��N2�S'��mc����7�;e˰i�Bg;Ο��␄���E'1Db�=��4��ܜ�^%�Y���D��*�]��н��e�w�Q�����}A^�b;9������F�/�B��4,�}��I�CN�⮸|�rI��K��΃�k�*����C�A�)XoQq��:�2(��nȺ��HNf!i��6�>Ugw��^|<��	�ϋ��^��%4Ѫ�1�E����u�V�J���YD:��M5���ց��m�;O����<���)�B7��4MBZ�e�^Ob�Z����)�nU�oX�)4����]�ۅ��:�}�k/�r	�$A�h:�B��U�����k�`r�ED�F�e�Q�$^������"��ǥ�ߔ5�c��'��M�C�gb*�-��=�+V8�<��x��.�ɾjO��w�Ѷ�lY�.<�ׄ�4 vZXC�d���^�#3lD٫�z��n�<���Å۪�ot9�<ﱓ�o+1�U��Y�����u�� ΐ2�$i�2(Jk�C	+z�dEM7�/�w�V�x��k(*F���8�H�a<;��(eu�oLʥ�T:�.��q��^O�Ψg�惥����F��r���lʖ�1tb�@~.�f'D�N���ֆ��Akލ?�x��5�~�]d�~é��*� �o��s�r{[�%� �#�ήנ��^�ף������R�J���Vlq����m��O�'�a"�`U%iߦ�<�B&�����C�������q^qbq���څ�l+���q���**ϳ��L�g����瞰�Q�鷚X
Sʡ�u��Z��w4���{[*�Af9��?���c,ވ$��R��6k(�WPF��xa���^A,c*dX/�ث�I����O2~[@Q�P�SPk>����o�����_���v2�tǣ((��4|������GW ��x��V��u��Uys¨���Ū������烞4������ȴAyƌ����T�T0J��&�V ��8�r��Z+S�Q��C�:a�
�]v�����ŝ���8# F�La䜜OAk��	V�-$9�-�E�߈�IE���ݗ��B\ѩ��1P���g�
N�W *I�ND�i������C�Z�&�+Q�.���X�f��ns�t\���J��D��$����?�#{795�>2|d��o.2/��_��7��{�"c�J�	Mz	�
�O��=R���T֮X#�#>�Lr���4Ⱦ�?��:�XQ���y�R�]�ݵ]����C?��-8\�S�����;�	�Z�bSi��� �~l+S��ӂo�P���ز7���U��}�^~d�5�P7f�0n�p��n����l�Q�ܽ�M�{t �ܼ\)�Pqt��	ܤ*X��_b�
m���@�[G����$�2ā7��Ԧ�'����� lQ�ñ�fVZOYc��u�9�h�d��s�".K�zư�gf		sz`C�r;T{�P�˱���{Q�qpy7�]v�����w��>�����鋤Fj̐M�X�݊I����&�������n���ǽײ��mS�����q�[��{o OZ5����+�v��Rk]u���p�-
0�$*��=�WH����|�G��Y���wd$�,`#�^K�>�'U)����tK��aU���
�<�5N�>�C��GQ.r}{���&5Yv��:d��XW9�/[R�	�K�l��Ǒ~Y~bDyPv�yV�~[%��0�.;�c���1 ���7 1z).E�É��W�����{�?X�&5��@J�>|!}mY������u����<KA:�+9g�ژ
�� 7���5t��n��ݥ^i9T� ��hN�G�A��![h�;�ɏC�8� ?<�%S1dd�4�LE� ؿYnD{���ȕzuI�@��?"ܽ�WݶYYz�։N��]܎C��[DM:d�M���}c�.P��/�<�H܁E�R��X~��^9�<88�hT-HJ7D���s�4�Y�8�P4%b)5�(��ON0*Rf���3��?+X���Q�ii��� g��YǕ���s�R�:ޗVK�֝☣�O�{�E��[�/b��g����� �]-��>�Z�w�Ի��5�΋��D�Ӹ�*C7�2�p/%$�eBy�D^~�GM��l��N�֛�Yy	嵱���Ѹ����x�6��������}������
�g�m�Zr0��x+�������IY���.��ё�I��)[0W�&r��y��=��B��{��TAd��S� a_�7�RQ%*6n�ѥF����==���_�qwVmo��d�����~��#;��+�!|�uA�,�
	$릱8s���M!��y����0}sv���\�D2i2��q���щ����V��lXz/��M��aJ�3���?���!=�3��J~�~1~'&)���X�����W� x��߮M�����vн�ժ�9�ر�����0��u�b�6Gƾ|�������O� *ƥV� PV���煠QQo��CCK���h�\��_�@�����xVq-iOɭbLBz�lJ�f��'�!ŞZ�ljOK���m
��;�=G[��].�	����L�p�`c�d�����=�pX)M���U0�s�~�6���,�a����2�G�m�����^pR�\JP0�&�=P����^�(e�š��8M[J0��+�t�d��qhߘ�qe~B��߼+��D�`#�q	�ok��j�j1ИE��k�#��V����*�A��?x���F��YI�9|rh7��p��Q������e0�����[����  ��Kt�� ̟�������g�    YZ