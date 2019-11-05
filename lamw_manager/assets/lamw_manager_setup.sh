#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2806461575"
MD5="24df1a0a4e4aad35a874de39b02a33b4"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19608"
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
	echo Uncompressed size: 112 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov  5 01:55:35 -03 2019
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
	echo OLDUSIZE=112
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
	MS_Printf "About to extract 112 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 112; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (112 KB)" >&2
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
� � �]�<�r�ƒ~%���Ēc�"ɖc����(�D)�IljHID ���l�>fkN��}�W��v�`p�MRb��b�-�s�����4T*?��
~vw������J���<�n?}V٪T�+�*��V��x��>�0b��s�k������S*�����<��ޅ�����W��#�K�\X}o�;������3���ʳg���_�S|X��n��±V4�����\{ƃ���!��9���,��U���ug¨��Zqߛ!ݾ��>�}��)vi���s_@��]�֊<����ӱ��}ύ��x��vyC/ )��}���\�e# F�	w���;|�bE~��\���(���۝^�pz��v���c�8�\�d��S�=�D|=Ӧ���BgM��JO䞬��M��
��G�������G�V�o�;�v��ƦV�Κn\Q����9������Z�
4s��*���n�H�4��y�~	x�#��d�G���� �MB�������M��LL�� ]�
�޾�
q��Z����=�A4�V�n�����`�Ě0��X<}pυ�G����V��5�1&�V���a�iF�|�U�����s&(�!�����vvV���v���W�����O�����Z�?K��TE���^@�R�>-W�[����"��o����H�3�%��"z��X��
�>e�3�D����˔��҇c�eh\C��g��b��Bj�7����G�wX��}��#z�.��G�V�]�,B6�}!�'� ~#>A�� Z�m�_��8��خh�Z��?�ޏ�����4�h}�:<���C�X�.��^x��+j�GZx��[��0�d'���(|��7�o�Q�vU|BS����yB΂���|��C���G�<�O �1�Q���hTi�4�,B�0�$�Q@1q[���p�n_�]�D �D���; �8�@M⫶��g�Q�F���u�x��fy����bO����~����+<����;7� Ѩ��r�\<	���j�a4�j�3�L9���T��HW�]P�Ϟ�����Q�H��DCm�m]߱#�=� C̶)D��¸K�{k:J� *����!"�Y�o��#b,������%����>j�JZu�5�G/KB'�W�X.�+��z3�^�L#�����
��=��X�)�Ɔ,v��0
�o���n�^1��{��ܫ�#�q�E>��%0�G�`6�����X�PحƯP� ��!��A�+��x��|*6DlR3��?���Y�ѱ�����i���w:��j�1M0*eμq q�ذk�=�{��g��&�+�Y,�=MרM��2�i%:6�S(Jr�4L�@l�h,�R%�r$�eL�d�������H��6RHY��2��8-_^��$,d����P�"�0�	z�eHF��ek�r�U(% �A������N��ɨ�%�F�J[��"���Ik�3�i�Ba�(���N'*q�Q��Re�|pK��U[��^n�'-��xr(;$90�t4 ��17���1�]�*x�6�@��]��=��	~��l��	'W,�ޠ�QJ�M�H2U{C��ķ����X{��2s1����!`%�R�������s�*��y�����h��zzlV 
�������1�ï��0K�%��������߹j�˦�L�b��9)��#�	��T��!.������i�@��n�M,%f],�D
!�E��7rN�Bw�5ej�CQ5hYD��KȚt�U6S
dp�s4����e"�#��0��)�0���;��aZ�M/k�F�l̪�ߌoQ�N<�:8��_NdO��1C<���}j�<���.ă_����vE�/@���~�� (�J0mxd�w�$FE6���zL�9�C��d�H�9C�����H�خc�M�M-�M���Gk@₧�!�����4b���hm[��^��Յ8#��ȥ͠BS.�h�~QN�y3d������P�K����l!��83	+4���E��s�рӚZz\�M?������>%^���v��;xS���Nu>����k����ϝ���_��U�� ���s��N�I��v��|N��o�0J��q�0��a��^7�;ǳ](C�����َ	uwx�����Zq���~D�8���=r;C����9l��_C{Oj���0��o��f6'? l�CD\Cz����OǾ�V�����d��̣~��)/�<���8W�Ʃ\�c��7u�)T��t�����n��I��b��D��G���c�Ipp�>���~��Y$�TS4�K�R%�Ӵp�5]���3�48�sp�9%/QS�W��(,���ڶ*VE�@B(V��ծ��T���0(;v�&�Q�̰��Wj����R8��i4�n���]�u��=j���-�
������T';��J;�����-��-`&۸|��B7��ȝ.�+	��BPb��D�ڒNT��|)䖠Q)�	���3�k��z�=bѧ�.�����j`��a!E��ړާ:v?>� 0�ܴLF� �K����_�|w9H���^E�8�x��⽉���@:��ԥ�k�F����'�*fZ���MR)�͵��)j�Z*ζ�]#�j�x"�ϵ�qt��E���sv�$���f� G1(�[���C�'ì�q��B��ޙ��s��N���f3��QϢ�w�G'g�Z�$L�cH�^ '3���ON믮�![��u)K��Ni�Q_��Dh�.�����F��@C���2�D��L�KH�ДG95����ؚ�S�4�urx�f�����U�HLDP����}�F��D���`a��[�dd�k�	;���1yJ����{� C`�}f��;��5�֪�>���`!����n�/��ﴺ]9p��Q�w�`�_�_o렄��i�Z#�$�b�1�Rh��%Q�L� #����~CR4���X1�l�6���m_�Do���$�����3��T��a&_��B�B��Ժ>d�c�!�3�7��c\��:�����K��D���a���{�*# ���l�rT!�A*��H����!����[��g;K��6vg	w2̹��2��A��O�¹�u�_�~�n��y��嘢��s*7�K��]�T���XG�ȡ�x.q���
�=�w��Lv\1�d%�q�(	^z]52?�Lb�/���:�GӀFjq�~�-�u>l�_Y�-�q���N������j�Hf�K�����j��j+��4\�&�����Ϡ�3��}��@�_�9B�aq��M
����W+tE�F���و���mw�/kƏZAEg`\�8"|k�>����rq������b�������O���\�o{g��5��5��Y��g���������1��r��������ov��|O���p�*���(@�j�Sl����Ē#��3�����[cO�F�{D��!��@iaH�d���tM���-�����'�:��w6�GLC(�J"e��}9,3�@x�>�Y���9�Z�恅~�e���n_�kI,l˸ZHV�,l3��/��`�"q�^��\��j�8��F�y�p����b�R���	7���a�(s�E �š}
e��ۦ��襒i��/9�(WT�"�Ō���X�QZ���b�G��eg�|B,���cX.�E��Áǈ�E��H���J��J�8A3�s�<=는yR�$")H'�����"�]'-��ّT��GUH�&NI�E4e�����0]\c@�>r���5$����?QhC���;�8�(3�{y_V> � �3�*��?��Q��}�5z2���y����\�%1����
Dr��@]�WI,ll������C���"]Ŗ���/��6M�ЖU껪�(d�	0�T�>�%E1� �W%��b01v���Rw�0֊r�L�Q±w!H��+q���Q���eJ���F��:k����6��f �K8�=O��|��|����D8n}~K�������&�L6 mꋴ�Q�8q�iQU^�a��ы̹Q��\�ф=>x�PXs�]�����'�i4�g�Ӛ���]Eԭ���dР�:�.��'�q9�����a�V^^���Z=�Z1|+_�Z�����K(D�8�(uЗ�F[U*(_[Ȫe�ca��\�6}J2 q��х�K5�َ}x��p(:}��7)q�m�rg`�K(�ܝܚ�q�~���Ir�D�!�e�$IJWt��tAR�+�0NaY�աy������f,/������ܤ]l�R��$�t�!��9��?��gNnQ᳒�U���hҪ��K.��؉��ěqz�p�^��w�c4�p����ca�cK���N�9���!�:�FMH��,<�-�D�Ec�8D���5�V+���[(���2.&�qI1r�䩾�67�@8�[�5�n|�~a�ݺx�A���;�4P��ũSHQ..**s(�{��M�߹���}2{�;7��,~]%�
��]9�\]W�*�d�@��)s�_��S(^7���	��+1{�0-�F�p��**.p?��/�*?�+s^��K{�M�Κ�7�;qX64[%�L?����H�$�hz3ynF,9ߝ�Լs�ӧy�1�I�����
���Hrǻ0�.b� #�ڒ�Jw���k�x�0'6%�G��
� V�e���G�wh�����Y��9a�Ws��ZD'�hG�?�H��=����_ǆy.�������v�>:��G����W�?犱�s%ƹW�2����UYL�a�;�_�/ѩ�^j���Fx��;�iuN���)g����yQ.[/�m�Ie*���s�Ф��	��� 8��xf���'�W���|�6�S?n�����!^n��t�bi0��I0�}�7��XS���Yy{ٰ��|yv����V���C�峋R�^}@�c��_FK�؛lap�6��#r��k6�㣓�z+�t=KT0�Y$����>�`��0�YZ纉[؝R�z7�Rt+&�:Bކ���t�2G�7rx��B�,��
v��@�0�O���`n�f�9�,���ે0��/.�p��V3���*�1�bQt����z>�k��<�o�tݜڠHI"��b����������4Gj6��|w��_,���şר&f�W��]l�&	E�����Euw��dtF�_�(���\(ū���'�/�B���|``��ʡn]7�}���]#��]��(Rg���\" &��q28_x�j�Ց�
8�)~�Q;-�J)��fjEyْq���![A�$���0+P�C���q-��A͹���\��(/�@�#������7,�P���P�υ����Q(P�%1�E�'N"ץT��W�r5��nTՌ���Q��Y��jV��o5O~Y�P�����Ƴ���H�	x.������Qҳf��g��:Ƞk��·tpy� ��E4��$�Z��KjOGvd��PmC�;����JJmT�L�Z�2��3u���\�K$w˲X��,\^#���b�OG�濠h�*駫�Bp{�7?w!�Z���1�vww���VP,{cye�J�M�T�a)�V�C�.X�ٲ�aB���k�E~ˍ�����* $Rb�Ş�'���d愍���o�n�H�ݯ¯h��#��$E]l�dzF�h��rD*N���HHFL ��8���p^f?�yL�ة����� )���̈Y� ��^U]�U���������`y�e���P�)��n�F��#Fcx��I����f�*%I<|�� �c��}^ ��^z��E˭n޿_��`��&��ס;P�$Q��y P�Y�Qk�ն�D:�~�>.�ɗ�Y�pvֺ�=�ǲ������CMz��)�I \�&Uʺ$��s��2|�o�����������5)F�fQ�U$�
A|��Jfֹ7L��ZW L�H0S͋�pZ��WV�]�ɷ�Y{(_���l�����0�_h	�
Yݠ�� �r��ރ�:��&p2��-c�LD���>r�ښ-O����:�)���Y��O+����+D�ܣ�w}���iCWylU�K��֥|>U�8��SVVo.Z�{��M�V���M�81԰�1$N	�5�ce�?��9��U�-wm�2|ȠH�s�͍���|P�0q�ώ��Jm�Y�\<�����Ò���zm�wE2Δ���y}��v��:U�'�&\P]g�d;6#A>�8:�`�=ĜKN�+Na:�L�j���i�X��<͍S�4�����,����P�9Y������\X7k-�u?���˃�o�x-�?������;)i<:�[tɍ�r��N�E���-��E�3`�����P�6:�?�"r���0����
.t�I%(07�M>�#!�, �˭����0e?�Z]C�^�X"���\B���ӗ�۴4��eֺr!�C��#2�g�(�����0J��S_4�$��ͧS_�����vUy��bɵ[�0H�#&��|;ż��7(�+mLκ^�f����V1MI)F,��� g��y�VS|F�0�j�孮��s�]���+3\���Ϻ�)$�wOuN%՝W3�����}3�������%΂	
W:3z��z�[Z�8r�.-9X}����Vc�3�z��dC�]�8|��d�< 7�"�y3� �8z����8�g��u��*3��
��^Ye	(V��͜�:!�pa���S_��5,�|�Ъ��������uu��jʱ�����ϋr�v����:�l�4�M��"��GKn�� ��$��K-�Ho����K�����������-����e\4h�uՅ�9�jHG�{�r�,?���<������,�IyH���P���(�֊���4I�qփi!�[�?j+铵�x&�vP;���e�D"o;�~�-�G��!0�ǚ�p;d����MW"s�D��t���� 5���6IbBAF_��4�����lA��<�����D^��
o��^B�k@��� g�$H+�e��LU6U�o�����D�da���w?@�,&�0�QΆ�*&��Hk{	m# i�Ut�R�_�<Ea��P�89f$#��d�G,��\�QR�L*vmcEmghn?Hc6F�*�
˜Ⴎ��j�^��bzɎJ�W�D0��jM��X��L�2f&2 �6v�8�����d�0�)J�[��B0�I��a��"�B��f�,��Y�$Hg3L\�%�	^?D0�b�8Ђ�!޿���)N���SV��7��Yc���:@e�f��o9�L?�vK�鈈jJ��a������^�$�>
2XG�j������0%���u��9oRg�Tr�6+�7&��I��M]05�@u��p�V��]�.�V]�Y�M�U���a:�	V�.U/vV�2�K� *�E�,�d�� �s�*�]�Φ����%��$��\[�V�~�]��J������#�BZ�:��]�9#�zq� t��!ĳ��ar[�G%=�{�[2��T�����!�С��y��藺�b��#�������� t��{���{���D��xq�%�Qn�pfw�i��K�u��$������CN�!W|�~&@f��T5�O�
U�?�Y3�n�o��Y��D�)ƄSQ�k�QKlx� ] ��-8��sB���	=�_��C����l�.�(9���z浘]��k�6�T���
��K�r5�N�0�xq���h��ٱK�ϱ���v���m�9��$f�p.k\lf ��1<J�{�7�a�KD�"{�K�#_�L0	�����T\��3�'��r\�����N�~n��m�e�Kn��	� ��-e�7�!J�-��V�ta�@.��^U�'7F񕮯4��U�y��l?kw{�Ϻ�Go�p�t%�=:HƜ5h����#�6"%vKIc�����6�Y%>a'f� ����Q9��R��T�y�����6
��6�=��Gvd��)�>�
g[QҔ@>x.�b��\�=V��C�J����h�XD��r쮶r<dU����mwXKt�f�R�8�*6���(r�z��`��W>��4�yţ�u0ܺڹ���G���pk�������5��O��q��y��9�s � �< YS}AP��ߨSq���$�Pڞ�

(Q9�&�������>�f~,���+��cNI�(W2J�{��&��H�=�J��qDIc@�.Z+D�A���P�fѴ�Q�W����;�!R�y��'�I=x�Sz?E���1+�����.�����:�JAJ3�a�5��"���Ԡ/��?D]׿Sd�p�A_��B�M[��Z�?W">pE��I�@�X&T�j÷\b�������xm&6���[J���J!�u!3�
!0��f��I���R���1L��$��M�~޼�|o�V�Ā���B��t/��G��UW���x�P�2\@՜cu|gY��⼋�{T����/ŢA�Y$*5���œ,Ew��f��/'u����B^�M�{[ё�vY&��R��՟�5��c1�O�;�e\��\.b8�	�s'@���2��fr�t^d�-�bf��*ܓT�9�M6|Z��jG-D�7&8�]UR]�Wr�O��<�_�C�nc:����d(�Z�Wnb举���G����kQ�FK�~�nsK'4�K��q�h������Z�5��1� 	����&�js(It�Z�	�B��	)�ʔ�,h�h���ߥ�W�*�y��@��Y R�y�R�BV��0���G�+�^�0�6����?Wx,	i���݀����g@�~��Y~{�hu���8w �����b8�s�AB"��W��d� H�N��jH�]w��s"�1
�V5W?�aW��O�τ֋�v�����l&�L���o�$Tk�.�٧�:���K�Z����h��k[$������I	/���d;�t����r�����mwY�>H���<<���)����?��s���&y_��V�dn�Kξ������-̱hg�:���h�P��ƍd��,��!�j�	VQ:G �Q�n�+�v0�AQ��'B�#<h��Af��{@R3^���]�+�||!����gpH���by~�>r�+)i�ķ��}&��>��m����}�;J}��-/���ʙ���V���;����z+�:4m^�kw4�j������@~�?�s����ü���]w`1��qCDB��Є�1�D�N���1�!��:[�d�l�6�326�y�>��&a��`����eI^;��|:$q�t�Ls�*sqC<�=�q���a X�������T����JzM��{ʔ�jna��]�;�5'D��0
1,3��6Ts�y�D/QC���f�B�%WK%�j�}�g��U���i�[m�^��l���g�;o��K3��F�:7�1����QafLn���G�9����H��m�$5]��m�jC5&Qz�.��䳴*�"�d3ۢ��9H��W�X-� 1�ZՔ�5c�`L�K1t����&^U�|'�*36=�9J�-�h�3wFEh�Ǘ��� ������F��0ҁ|	��_���(�:��6>����n����������G�����_��u��u�q�N� &6	7�P����z����"�\>�i��un�, �u��-q�s��C���o6�iz��g�����h�b3$�����Z{��O �Tf���ˋ�Ó��?N/ _�t��P�(�_�)�U�)6uP�jH`�}�:i��G vx���B�����lQ]��?�O����U��s��Ί��R�����!Ϫ+'$��Rw��t�+¡��ac+�ߪ[�ʢB��~�Z�p��|���	R�׿=;:�=�矔o^�*���������gQU?j��;�=>�#�f�q ������Kxki�K�{��g��;�U@n�ݕڬ��>IB��S���I�o_ZZ�>������LP���x@��\;E���$�p��,��s�z^�=�Y��)�S�%|�)�.�^[�cf�u��DJ'��rE ��*J���ZW|FQ�*lR ���,�1�ר0�ߝ��p�/��}�^�0�,6
|\�W�=[���,؝r�Rac �I�������b\�#���
�P�a��I��i�t��a��k�xQ��x
^aH�S��@�پ����;Mc���j��ˑE�Hv�_`���'O+�{3�7����'��p��^�8�j�X�a��x�̆�qG&�f����*�.fZhW!I�+Q �� NɠpLG gb�B8�H��I9:�HRx�ex�#�El����v���4��`�>��e܏�B�'�e�A~)^��zE�$����_��yEpj��c�(yS�^J+\�Qt���w�ؙ��\Ǿݕ���zx��\��hc~���v\���^�&("�bb� ���զ��a!�C�&~N;4G���;�,��b���s�|{�]JBvf1�1f�u�դ�0������w�}��[�m{�i,^�+�n�R!mj���;�LMZ��(AZ&��ԑ)ddh�x�T�j�؅�Yw`���<�&X���m��`T8C�s
�U(z���񷝣�g�<�Ċ�N?,����f8��c��l����-T��Ax�ݼ���U��NQ���˅O� 焚���B�p�>���60�=#1Az��#tԜ1�|>�4�x o/��?���88춟�ߡ�=dn��8΢�j
���g:r]�B������JS��,�c �B��t<c��|�m暃���	��-8������{B��R"��c�J\�VE�g4��b����t�G��b6
�S�l~���{��[�R�K�ΐz0����:��>4����QBI��o��>���@��&���s��k<�Fa]܈�N��SK}6�A����	����z�f�q�\����(l�᫓ ��A]�����Nu>tF���ʙ�*���:��>�g�+������B�>�ef<(�]� (�Z��8An�)]7Dw6��y��⟮&as71��`�\=����w���b-9��S��~���}]@/��c�4���6����}H�V~����R�z����\��Q�ƫeD���$tf�'��#��ޙ!���+��o�+�ei���w�x;���'a(^�<�έcv��u�������j��!	l�M>~���%���]0����$��t�W��KA��ս�0�rM�������㪷�:8鵻�}){r�)7����\� x�@�ǰ�ʭ�uyp93�q?
��D�3	������1�!�� �u=�B,�*�T/�� ��s6�{C5���Q��6�Ԥ�6k�Ũ��ˉ��jp1�ڇ��Z{�`�tx
P���Y���C����ye�pn���*;�r�u��t�B�t.\'a.悎�T���uQ��@�����~�(�;������M����O�Kg�>��8�*�Cˑ����%1�6��J2���nWU���`4 ��:g�$�h���"�x� ��X����ǊQra^�Xt��qT�%��ˣ��38�q&܈K��i�?��?�w�{���ud��t,G�Kg�2���\��_?N�0ay�$W��Ѭ7�yhLk�RGDO�M����B!]�p��\�q/��i��A�^(��]E����Z�������p�7Fp������xM����0Q�۵������-P��nP��83Nj�ɞ�!�,�_�Ts����۩�a�NS���4�Y�eWHop�p:�n&�L�l	��:a�\t&.9)"5RVӘ�#q=�\�)H�բ�<�^H>������]-���8R���ʑ�p&��\[�!���9w��d�jƮh�+Жg�2�Ã��������E���7��t�^91bǮ��,>����u�i�R������/Y33��NL2�,��#ķm�BŴ݌,�hJif�AU��DA�<ᖘ�v�t�L�.�^nXP���k��L��reb�E̙���,����p�_e�W��F1^� ����f0��h�m��:hz��􃒒��`fbN�9����e�SDH�KH��j�V��ӕ�U�A�Mf�*� jj��*G,
�\ʭ�H�zY�4n�{m��sVƙA�����Q�����0>��҃^+y}s�جB1���a��M�p�	W6�z���B.��������D��_�&WʼWvg%u5�Z�����+s�M7W	|�rM�
��aޒj�J��5}��>X)D��+�L���e�,��M�i鉆��!|�AytvD�]������;��H˥x���^3�F��,�k�ܰ�BbO@�*H-���9ܺQ�ɼ��F��FFb��g?�^�M4�����	�m%��GPZs��˴ײ�9D����t"���\��}�l�'�n2X�RR=�j�8�(���P��L��hf�֒�G�	MO�ӻ������Q���L3�QEļ��;�C�5�.&CXp�I�_p�K��.�i@ϡl�[l��;��H0�xL㱈��O߅C�Q:z<،�g��m���=U˿B^�0!�ӏD�Г�f�Ad?��?:M��o���dN��t0�'�%����	:Xw��	JX���U��&&#�8S�w���ID�&Z�A�"i@S���(���><�C�D2�6l��9���0�%$�@6��R�Zy2�o ���F�1�<��=�:�+y��Qk��Ŕ��K���%qjJ�E.-�{x��q�iu� J:/�J}�BЩ�NNM5</J��+�uFX/���7*��f�qJ������4�P�E�K�)`�Q����15+���ha��hz�H�����a�iM�&J��C7�X����C�7^c	.�Ȓ.�j8�u^e����,�0�-���$�@1�"I���`�w�8��Yzj`�2�Xw���Eq>+��x���o���C���=|n�W�T��dD���-J~1�tNC��n87��qft�|Mǵ$S��h�(�0��N�7�S\_O%Z�4���U޸����V���;wr�
+s�m>m
1`�c�Y�Y\LLg�+#M����U«`��ݛ���ymg�.��TK�M4��`�>ū�z>�5y�gM���%-~KW��stʍ2B�7� �7��`>!t�ي�|T�c�;-α�a*#3����o-wA�x�8"�v�����{%Ms�9���*�^]���o��k9�.��O�.�T��r��/;�w3�ܛ�o���h�x_�1p�v�"����ș��q��$w$�ɝH���}�z�zϥj�h��ɽ�U�oV\�� �A �(-��`=���t�8w-dt�/��(��6á���Ϩ��"�fY��i�iu����a��EwR7�]]�UگR�,sT�yS0D��V:9��A��8k�ϠB��Dv.��g�����O��z�e��f'�q�Ý�z�3��me��EKY�Pְ��f���d?���m#�S!���S�_�g�z��ܲ��i������z���5����>R.��o)��챚�hg}�7���	�v���j9�������͟ݺyq�f�_��ӽB�G�j�
�&��Y�8](�I�]�N�.��"��ێ���ڂ9��u/�V�L����1i�Fi�tMժR�Rs磢[˲�\0��0be��\,I�<����܉M��Ť33)��3A�ye�\�V��R,	�	���Wم��;�2P]�~?����a�����I�p��~�����k����Ҩ��+���w͂A�p�mZ��4�Z�e+�"�fd	�9|?�=�!�Xg��y�
\OQ%t��+Z���/:d�b�(4}�M٬��h�^NM�p�$�6%��-�o�<B���b��ʶ�׵i��Q�0?����:੉���*ߗ\}�1T�ؕo;;� ʉ�E�r=�΍��L4d�ò̂im��O+NUŒ�'�6c��v�	q�pAs�N���K��_y�'�fJ�W�Q[�@׊㋦�}^}����
������r����b �ďb>΍MN�:Jg��U�R@�?B�'>�J\R���Q��*ۢT��uG1�q]4��B���Qm5R�I�sD��-`���M�9C`�]�#ۚ�X斐�cr2�П!-�-@�jG3���(y�a����N�E�����]���d�_Ze��39ǘ�����˒!�zi�پ�U����ׁ�`�5p����ȑ�*���_�k$%��J�4?�z���)��+���GZ/_5�Ɂ�<,�#oRdT�rOJ��{\q0�mP�Gߚ_��E�o�r��_���=��Ez��[�o9������˘���x�x�������ؼ�����6���Mݿ)�d7����(���D��gv�u`=��g�0N� �L�w��Vsy�4|���X�Ȁ������C�ayX��)����a��,��Enyt����q���<)ڦq��'/U��w�,�	���V�g#�$Q�a�$� �S�j����<�`r����6��>��3��Σ$��XA�3JS��|벪�z�Nޑ\B�\�_�Ɓ��)	qђ�p�Y�x��W�wc���:����L>GRO���m{�/4;� ~���������;M��֨i�a�҇�9�|Z�V��p����4;�^�Ctl�Ԫd���Ȝ>�s������q����(	�#?��Yv�^�i{�������`��U�/�O�_�Z*k̼j��Vmk��Ҿ��z��M	�7��RK�DA�䯮��E�pk^Aa	&����T�K�ku���z�G���QW�P7�j��H�df��4�M�GY�,ɣ�f]͍��#OU5�M��ݶa�zX���{�/����ݒ�6���a0�]���0�E=�WAu ��%�W��H#"�͍���|@��Ny_/������p�+E��J�'�j�ZC�k���Ϭ}G�z�� ]b>�ם��w����9�b|D���g��y�Գ��s���ۼ+/��������i�'�E�.l�Eqۭ隚n�v<e��t�aI-�
�O�'�h������z���n�	r-ύā�a����9̖�~�w��SW��K%�yNFݢC�Be^���B]��g��`��io�j0Ϊ0��j[<�J�D���Da*��5�	��"�OgH�S,�
A5�j~��E�ӟ�Rut&�}�3]`��"��q�My��=I��2�|�6}w4<8��&�\S	��{k�M;X�%jk�bpaѦ���y���Z���i=.�:9=�r��{�.����q�]#�`�ݪ��C�5Hj��i�a�,ݵ�{�����0�F�Q�����m��|��e/���a��C�8���$W�L~!2����8[_��M�-9�7��Juu�����<���K>�����a�3I����'��`ʴ�a|g����X�~%�qxˤ^�r��U�a��Z	w���8ա���Ŀ�0��p��ZpY���,�3�sUY����U�K����.8���搜�����s��w&���֋�����6n�{u�3�Q�l |¿|���lw��=X0ǻ@a-�}�~Z��O�<b����Ԉ��M��?:��hT�/<^d�`�Ro@=N�g�s�c?��x]����y�,��s���B.����$<.��l#�ﾇ��|V4}B�D?'���C�`8�"��c�1�7	&)lN��3v1 ڙ�� ��"d�İw��t �~�	߆�3!��	�k<?�y|8�ì����1D��~7�36��Ul�/2��I�se[���oOZt8�v7�&�[1;����(���u�"�ad�<O�֢�M��Y�a��ڵ�.�9��4�����,:�7�{[��>��o,^>O|�Bv*t[��y�ܼ����f��fꄅ} +��,��$^kݷbi��"��c���J1�/�_���_V^7f?NӌM'H@
IJ��w��^PnJ�^����2���������ڐ�����I���-�?w�WV�1FQ��{�^I�����t��!'��9�Ј�a�Ƕ�ί=��9���6~�0�)"�Z?��Z���6�.��̺�����Ӝ�1�h5_�g���~V�������c{���h2aejbL\w�����jY��D����O�� ΰ�3-6����Wr�iz>���C���m�ަ�j��0L��2U8��w�K�0�B�cpG��/g�s�ɂ!��]��i��՗{�2�2��Qp��I0i�׫j�ӷ�(89BZ�E�5u:lo���2c�:�S͔�2gߴ��ǝ�"�v�.�ěhl��i�+2I.xWר������C�RR�U�a��D���gI�H�@gG���@N���[�m)B����3TS�i�uptm"W�S�����+,����?�9�e�"�����U����z����C��.��Z���(a�Q!�e��l4��u�����ߍ�� ��/Zjy<��*�������hln�ۺ���Z��Um4���_����Y������q���5~�����Y:������U���B۝^��#VLS�׸v�܀L�IȬ����{��d��Ǔ'�`j�^��d�|6��]Uu��<�B:�ãN�3� �+)��_?N�$_<႒�u��&B:y���n���)�UG�h�qf��]�Q���ùs@N��,k��Z�g�m�s��Ϙ��Z�~<�� �d2$���w�Su��$	�Y���\�}fyq&!��`�\.B�V��-P�>	��+��O��O�f\�����"B�`���$��`�癒�貨�Y3eiKi�Ƽ(
@�D�f���R�㖥����<�_
B��jr�M)7�g�H��Ւ�O�lᑵ���bֽ����"�7F�ҐkӺ��,y�h��P�VU����,>37R�觺��Ge*:����ӓ����;I��M	�.@�,�G._1R��1����K�q��7�~<g,@_�S4�Y-�r�Ge=;�����diKf�.m�ȶd�Bd1I�\�V�(�ι��@;׀�����1r �pA#���x)�KX���x����t�9<�BE���{̻�����x��n���<��J��㿱�Ѱ�s��-��u���GBy3�~�������1_c}F���U��$��{��77�<�Ng0f�D�a�Y�3��,����)'eNϏ�Ы g�S0��<#9�	�XI�8�J�*]��z�O��N�s���Q?�w����@�i<��9����<~���Y�Ŗ�n�=E��Y]�Ќ��%��q�3PKs�-��\FEY<��2�[�Mhi�x���T3�Y��ϰJf0��s��J����Ȧi��/�#}M_%E�M�D�c�ޘ|�Ӛ/9E�C%�7��g����Po��\뒘6��i�VR��0����Ŝ��D����6��=��;�������8��W�[��ߊ��aҠ!�s)�����s���km�ok}��������Ì�zv�m&!�)�x$Yz|�<A��Բ�S���Q��<����v��M#����:d��C�~k�~ۇץ����!��p�y�KǺtq�V!R�qﭏ�6	ϝfA|������|o�~�ä~6�π��<��qkwo���"����r<�O��@���AW,�N�jP{\�����2Jg�0ʄG4Za�Fn���g�ʉ�:fu��5@����ψ=-�	��I8��޷�خ��w(j�,���(L���TU�_&4�W�,s�άC���ue������w#ۓ牨/��I�$*�M� ������A$#�87��d�D���=���E����REۘ�����H/�!8B'0$b�r�0W"�T�(�A0���Z�$�#��ՠ��!�
��S�bN񪯚�Z5ϕM>�B�S
5�a{=�NQ3��>S�L��46�����[��_��OB`�Ұ7Ɖ��5��k[��g�����8��#���F�G�$R�H&#!8�����ydS�<i�=�^0ҁ�y�%��*;�g�Y��'5�39i!�ʃ֫�v���x:�;T{�>���o����':���j:��o�!D��v�����%�0���==5v�)�ל��X9� �C��j���m���?~�u�	g(E+����[{%ݰK��lwLziKvq��$��Ao# &�R[ӻB
s�T��SC�"���#W$�>�U�Wk�c�OqL�1¤}3#��~��m����\3���5%5�/>c,�<�\��АX��4��������
ao�q���pT�Q���#��F��
�ܥZ����#�� U�	e旼sf$ hU���{���.��z�4G:}�6����l��0Ek��^�������$�̭I��5�1��?%������v�3�>&_O�G2����G�=w\saFh?�b�5m&,<NH�FU�An��x�d��	^��&ƞ�G��4ٝ�;͐W���a⧘��+����*���
Y����x�����ޒq����b�~���mnl�������-��U����M�����%��b'*�W��B����_.��:y���0��|�7�u�_Kk�f�ʼ�v�g�Ǻ1�*}K�Ӫ,�%;�u{�����3B����v�i�8�T+�%�*/B������9	����ѫ����ͱ�����'�ag�嵲�����}��'��p�]�l$vT�K	ʔYih�FA��mHC��42q΃O�p4A�����׭*�|[���(;���۰���T�O{b�F���(�	�L��	�����a�EO'����g��V����t8�N���q��rCMe?����GY��y/������ϣ񠹼�	�˸6|YYF��5rWH�ȿњ[���u�m��H��Y<�Ɣ�0�	lc<î'�5��~� ~�����"̞�rz����{��L��e���YU8"�����XsP)���"|Ճ(��S`5bZ~�cQ.�S�J_��*-���B�m����]�Q��wᇰ���%�kw�^���\�{~���·��ݼ~�k�����K�i�E
�ʸ�E��U��B��+yTH�H7[��SK�,%�H��%��[�g���2�*��&o6^W�JEe	KB���7�V;�u~Ǚu|zK�J���j���l�0�ۧ�<N��x�WA�[ҷ@h U�CC��,�%�g��5��� @���R�������w���[��_��_�o��vS�S6
��!�}�qe,xI��3xG�~�:�ѹ�'�tg�V;�jXh��''���T4%��t�U�$�g�*O=��]c0�Ĉ�r�(J���1�M��
�,��1<�f�N[&�Eq��0^�?�T�{=�x˱�?L������*�)�ӟ�B���i�a2��&�gU=f�6��]�k��/�G.F��pP�>d_`��q����n��n<�ܺ�����Th-��l{KR���q�6��ԍ�dt�[y�4�e"K	�(Cti��va��n�������w�����n�������w���}���1�t h 