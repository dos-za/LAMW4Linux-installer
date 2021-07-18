#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="666062496"
MD5="b5801e8f5efff0c8e53ccc962b25ffa2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22584"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Sun Jul 18 01:32:47 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X���W�] �}��1Dd]����P�t�FЯRQ���y����6�(��a�E�*b�]<�9*�6B��%q>�s�ff��F�E:P��5�5lH��Q�,���� "�{��!%��gH�r,�p_
��Ҏ˳�c��I����N�˒��#�X��&�U��{|rgsR���0w��E���8�z^��\)!9@|�*򤐮?`�m�T
N�9a�G;L�.h�� �[���j��Kٯ��3��{��=E2���T8w��C�ֆ�~��O���dj�.��;=��I�a2	b���h�zO��9[�H:��Os�w$����|�p��6Q_$����p8��A-�,���Z:����#*7c�����e"�������l�b0A\�����^ڎ��|K��уm%/�RUf!�0Q��$nxiKe����):(���W�Oca���T��Jjl����("�Q!TI,�k 幃5 �lnoS���.�!���S�8Nu1����vĄ{4�������+�vē�l/�VN۱����[���D�����}�������	/�-����j�-~GOpX�V�G}�S�a4��@☘|$��[j�h-#���6�ec�Z�P[�ĩӗ��L9	���<�	s@݇�? �4�nV�mRҡ�%۩��0�����.�|f~�RMYȳ3,�0��4f�:��+��V������=�嶋�͉�[
x#�sG|��.+����?��H�t���D��bw��<v�7��m]\�?9g0����{7��}��*�K�ZZ'�m�H�'����.��j�wެ�-4j���$���,2P=�ڤ>����-4=�\�� Gj̲1)˽@ϩm6@�ZW�����������}�(���W,�>s��v��7�X�t�����K�(/���
{�z�b\��cn	v����σ���.��P�%�����T^E�0��}H�ut�Hȴy౧���rD�P���^�{�5��L����Ĝ�7����]��!'��i�T��/		B\�4�zW��%e��o���y�U����Ȋ��b��*���>�B�;֢`H�����LaJ��{`rPI�	�
Cv�Ƞ��N���)��	s��@�.��$���c��G��B_Bu�O�`�X*i���P|�E ��0����ю�Z�0I����n�Yr8FK���E��B[,�B�|�/*$K3�B�=�9H�6�1Lb������&(9d,b�5I۔_�۫w�M��kH�qB��x$W�������~��ih��D��:�%��K|�H�=mdT����yJ��1JP;71� �(m�������i���ڥұ)�8����R^M�+�A]g#+U��H�k��Ղ����D)�0Ŕ9>S-�>�%�5P���?)��(�@�W��u�d<O�6E��ա�s�Mtz״O�K�T+�ЗH�LZ}��}.z�$Q�ݐ�t��҂Y{�~���ncKx��Bl��\t���l���Y��~O�ɵ����Tz��[�ߵ��3H3�/��s%jZ���ɦ��7�X%ba���RY�T��}�Äw81�/���q���{79&=�_'1#�mo��Z��������mۄ1��֛�y�tlD��Uk�Gۅ�����-O	�t�Q��b�%����Ug���E��h؊&���Oh:���1dD��g]��T��d��fSM��vǤ�r�|��UeJ~c�-�T�pb�<�?
��Vi�M�OՄo�9̣������sZ���û����Ĕ�Ne����*r���6��Rc�:�1�W�e�pJ^���H��i*��M��u�м(2��z�]tϊ�շ	�Z��Wo��dJ]����Ŏw��g�wj��L�Q�Í�D���OW��"�W$�Fy0fB$����w�$�Cz�n�qY�-�'5��@��)�{�G����o�v�sMh��G�;���2.^۴�[[ �镝H˃�=�$=�[鐳ǆ�[M��V$X�2[�����U��x
������������!�s�j�œ� ��־#{$7����t�wUy]�:���5e٥# �P�\�@F��<�,=�]�5�1y��P.h��J��I�0 ?.rp`�?XȀ Jf��Wbk~��a5�=��cz���zo���-��R��4#�V�mIfKϰp���j���SR[���@*{,������c�e���~����,e�0�������\�Fq1��,:�xTu%�A�vm?�7yA �R�E�FD���/)`�Hhf��m�/2k_5㿤��H�l�ad�ʹ�oǥ��yƉ�{���AE��B a���:�zQ�TE�Z[�sW��:-����lf�X'U���X�Ѥ�n�ߕ��yۻ�^ V>�C�Z����ͅ�x?	��c�S�	j��^!,�z�tQa=k=�2!�fqZ���$i:���1���r%�m�nm�C�`9�T�:n@�ǧ1����.���Q�� ]�NH���V���c 4�:3�hAN�y+��2k���<�������d��w�Ad��&8`��a%��9�_�?K���]W,{y��0�dR�9��U����^�����z�c"I�Z����9��j���TqLz�kǻZ��FK��`Bq���*?>ڶ�����$ @��s��K���v����r��j�/TD�C$��W��D��GsDi"����o9��(o=����{*�U�3�.	�$���k�3�!��:!�
ζg���J�2�C�a���h�uu���ņ7�BN�~�?�*��.�89 ��ѭ*��:x����U��Ep�j)w��·x�Z��^���Iu��q���l �@p��;{X�R�|5�0"&��%E�0S�ty&��܋��j�GkgK����[x��u��%�	�e��қ*�����Y~/��L�TRʉ�a�.�:�T~�'�o�/+4MF�E��M��Z�,��P��[�r����#� �h�%m5W��u	̊�Ʊ�umU��]?퉩� f���Ca��?�N���C��،����f�nUc >�C���z�V�����W覊1S��24/����Q�UPxP�]�h�@�`�K���� }IDb�?��r�H9�CD'CHs�vў��գ�2�ј���NRd��Le�k�'��_&
Wap���#W:I��|��L�b�(p��m�J2c��E~�D���E[f�<�FƗx��~w_eUI�fm��\76��-H����ڨ��J��*@�<�.^�-����[����2Y�ŭ+x:��{/~.�)��ݹ��2?R�[DY@߽�c{��������X� �Y��1x��ФqP�OAp^|��,~���`�<.=���w���/�p�����~��Y������#!Ňt��^k�hx�kL��s��0�w��X��,�Xż����?9��'!auf��V#{F��Xa�=����֨
�����aHG���2Wh��	|��Ν��^0������B~#0��dۀڙx��>��M����Ȫ���u���7(�6j�l�!��`c����5��=K.8��t�V\��n��8JM�>o�l`XM>�>lo�QM�*P��Ӆ)+��ZqVH	��_E9�?d���0�Fبx�����ڬ���:Pw���#-Q���0��SB���c�C�/J��:�ŀ)�?��H&�9�!�|p���7�~"���/�\,(JFV0KW�v�-��g��>r&!- �F�3d���Ĭ%F&E3YE"�*�K�a�M�j=@U��*c3�{p�q3-D��K�*�͍��i*�X	��w��Ա\hMn_��r�~�k�F4Z�`���j¡�+�َ<�vŠ�Y,dG��/�Z�*R EG����R<�(U�nL�#�	t��]��M�6J����a� �'7ނ�H*ը[&���<ki�3�J����f���������;čL�#��wHus>�j~Jp(��J�WZg��I����U1�#��~pJ���dPH���E�b�E�͵X����hr�TA�S��;B<��[s����%k��M|��(�n�d������L�m�y�x>e�9���f��0�ݥ2�_z�]�؎�y���9܎EqT���X������:�M������W�F�J0�B_�, ��f('�=>���9�!/;�K�4�'��ݨ�`��L���MT�]Ig�I\���O7��	pT�~K�#��
��n�?=�NX�5�'����	�
�6�;�����]P�r(�$�Z�(U�W�F��r���@��N$�$��'�G��m*`��������g_u��*.��)璾�zW�M���3rf�����~e�Ђ��$<���*���m��r��;M?K���R�f���2����#߁�����L�]�B��w�����tܵ�[�nM8!�.U"˴���Һ{ ���x��lO6�kd6�$96�peQ��%�=z�	��;t�p���/E�U�����/٥7� �0Vl�]cB�i����
�*�4�^s_Tj��*)��>�EN����H:�������8v�Zc�bo�2�6����/�ެO3���2��i(�"�6PqQ�w��G�K'&~w�c�� R�e�BݧIgh�;�U�)��'�����w4���;���-Z&��9=9R�&u�v��Ɖ���"r��< |k�m�@c�϶k�z�bA�*D���d�&�_����)��z�?�,�[F�*5y�a��A�$m���[��w�X1�{���F�y
1t�M+^K�>�K�CdWv���)��� [~�%[���E�u�cj���x�8���#��n����L� C�^�}x������w���ܧ���8�%Aź�ӼϞ�����xq�3gD;��V�X�����_z Fy$H|��H�7(u�<���6߉OA+˰���l�c�s�� B�e�Ϊi��;�4��E���n�6'��i�?�/��:v����6��'c�����wH6u숝�V��(H�&i��	 ?ӳ�;���h�=�D��_OHUt��*�X��Ǥ�mW݅[�!,�Mw�r���V�)���K���2�3)RD~��1h���k�>����%K����y��&0_EF �9q�}q���1���󛳁P��]�5�fL��a�?����X��
f�[\m4�mvy~��3��.����͑� ���(��۩y��s��,�e��ʔ�v�Gx���#���T����}7u{�ԥ����!���J���/���y�Q0<2Z�.�ñsg�<�D�_!��e7<��d�ʡ�~��/�؀x	9PseQ�"f�Ȗee����2*�W}8���Tc
���|�}Q���!�n�=<�9OĳJ7!���F0��h����!ď6S��
ċon��-�,�Co��2N:o4'0vL
|I�iQH��I��?��g��ɫ����2_��SRX�D���U�wsWgT�Q�6ￕ~E�����L�5K? �19�i���|��>�U#���SC�mxM��q�.�PLV�r6�Y�UZn��>1��9���}�|���Mv_�D,�
h�)\�1񄠗S/3�����&�J�WU��J,���"#&(�"\DhJ�\���y��3�G�z	.#x�*L���J�)G���G��WC6ʺ��6{��)Bk2lli�֒� �a��zk�(Q}ҹ�{ɊM�ʌ�y��='�:�
tQ�)�+�l�t M���pޒL�<'r�� 7Wj���Tq<��	Ϟ�9Φg#F�O�������6�`�}�,�/uҋ��(���oh��-KS)s? ����*l��&��W;�^6���X5H�����s��N�FQ���.�W�ߺf����k�$*�A�t5r�@vo+�(�U�,(���
���8��c�����Xbo�,�I>.�AG��]���Yg.Q"Sd_Jꋯy�?�W�&'�Z�C@�q���o8����͋�L��H�ߏ�"����Z��J����C�g?`X����:,]�:xySs�;.�<��1ó2"@G��L}{��x�\�ڝF��a��(7�n�ПAk�H#6n˞��W|��ѕ�́�"�ERwT }K��`�E@�ܸs�^��m]!��ǃ�}`\А�e۞,Dq�'�ﺓ�ݩOM��7W󘤛)�����%-"��P$���b4��A���`w��^�v\�K�{k����~����I�[��n��������F�";�꬯���v� �� 
�-�|�"&p-�)h�;߄�z���0�\cb"�w��}U��8yqܘ�T���� {#s����Sh\�g,�ؒ��v��d���w��#�7��{�穳vzn�;;Ѱ����ɹ>S���٭� �̣W�`�˻�����Af�3�ɾ�'�ڢ3�'�0:{��o��D'���4D�7�0Q�o��Ee��KǯZ�&�a����Rfp��V;e�V�V��@�Sa�O�oӟ��ac89���W=-o���2�����j)��aT(��V�
�ff�� ����ش�"�l��c��]x*��G( /0B:ޢ�?�޷���Gym��O~H��@㸖��J�F[kܲ$�8�-U�OW/eb�
�2��-���&)�;6��
��Y�n@�v�;2%@H�S���������
��SN+lP�9z�ڳ��/`�p�-^��3Ε��h顉����1ʊܽK:��~��a�%'qW�J�Wb���1�lƎ[���l���G��<��V'��K�Yy�G��&] ���U^��~.�,����ij�����[���6-��w�&I{���{��Y�v݁aj֗ϵk�c��nUTX��9'1�<�,�^���>>I��aV��$�k[����x�=7�W��Ӡ̙�ӣ�}�\��t�G|�bUE����U�ﾌ�H�`�;�l��|XG��Z,M���	0->J��Jv�cL���T���}U/���/"O�.8@:'��+yV=��/��)u,_?&O�!�  �~��;����6 ���v	2�L ۵�+ �T�b�ԝ4����\Jt�GT��h���B �XF��ݯ����Jh&� ��������8�ϛz`%(��~������6�tC@R	��i��
'�8��HR���=i�TZ�?@]���Rl821xl7��AWڃN�rX�YeN����C ��ݣQ���ܑ���h��	���L��M#j����v);1�Y�Beƴ�_����{�jj�j�2E5(qG0�4̘6i���O��i�i'%���-�1����B�knjP���!��v�����̻��%i=���v?uٯ6����Y+�}���ei��� �^�xM�?u���-C�7�8_LH�D�Kq+t��gFʙL��KQ^��bDQL�=J#�T�P���<���3}�u���7��2�D7Q�$�s��s�
��df�R��z��΄��`�������smG�r~�k�ڀV��mq��OL�T5N�E��&f��;PLB��N�Uf�k�Nl�fT��Κ-�VC�F��m��݋�)���.�H[�s�:(��>��μĞ��jp0sR�}�y"m�t(�
��8k���Z���CP�Sh�DG̉4�b��a����o�b7Ģ�bv��L��5'̀�+�4֜^�>^�ZX��'���v��̰���!x��}����r����g�*lUf��[��L�0O�\�Ã���G���F��h�n� fq�׍f�6�k��1�lZ���mI�4��ٰ�NT� C3��� t���`o�Y�٤0`���|L�ŧ|H��Yg�.�P5Y9��fa�K��Td|_tB��9�d�i7�'F;#�J�!ZN�R\<��s��
�3(�ϭ������}g��Z����$��/��fR�]hހ3�I�"H]}΀,��u2�l؇��c�����v?4t��Fo�	���͉�w�K-�a����p)���O�5mĊ1&�f��Œ�
�2�:�p9Tئ�s�剩@}RXW�f����U�!+C�ȍ���i���=����q�Ы�N0E-������<hu2��$���ܟ5�Pޭ��mH����F�,���\q��
V��H���@�_2\������� �5B>Gjx�	��{#G�p�4��Z�ԝ$j�w��x����N)Q�'��$�7Ų�b��7�y�Ro��m��5l�p��~l�K)�����x�@��U4�a�9ȉ}�{��;�z<&��eD2t�5��R�m�M>6��{���5��᧼s0��x�_\�	���L\��&5~vZr<�������M����`���������e��%�h��8��7\�D�%�Q3��)W��z�`Ԇr�]$��N&�Ri��o:NuU4���вhRit��-?`2J'����~�.	N$Ai�*��,6�\�RI�H����dR�g�W%1����E{� n=��˛�F��vP�����n��l���w�#�lS�%(���v>�� h�U�j�ƛ�V<�=�%H0�=�D�3]C�����aw5��N����P{CE0�p_FʅV`�+Ax�Ym���2%���)�bO!F|s޴6�ѫ>�D��ca���G��w�'�z�"f^X���\�0o��+h���u����r�[y�M���L#�u-1��U��N2�Gz��c��{x��5J�b�9lqD4[~��k���_d3��g+����p��J��,)���� (@�m{i��������ݒ������u r7���)�O��{E�$��U>�D��;�8/�r����H3�ڴAm�3�#��A}a��V�j�*в�
��q�O���J�9(�Ұ���%�-v� o����!Ts�}�V�L=ɒ㼲u9��s����;�T]�p�BbTJVa-rI�=+.m%wi���9Djb).=.����X�񖴞Os��}*��� �)e�V������J���A겉��i �`<ƅYI�˖�O2U!��E�LTu�
)U`gt�s���m8��fW���H�%ƫ�:�4���'���r0��֠����6Q�'�t��F�����V��YO��U����l#j.�5:��!Z�Gr�_�E�k�� ui�I��r�����A�3����t��5���.�m�N�0#< cu|^�Y��q�b�g �Ӱ-���^�2��/���B5����(˛�m2}*Yl�b'[*k��t*@-ىi����b��n�D T��G9�x�|�h�����"��-kǌ{U�b�1�ڹ�R�յ���G~��{ӕ�É��X}��I��>k����l��H� 9`Hd�0���K��/�l8g���D:�q\YҪ�$W]PiH��o:$�a����[T(�*�7|�^�ͯ�R���(#/�����WTڒ1�Q�6>��sC|�m�>P�V��b����WO�
Q��K��;[7��aBQ���,11uAQ�`Q=�� X�%ִ�&S��ܱ�Vu'XnZ\�l�t�O��s97��U�M	���$f�b���ޗ�G���H6X_[ ع*˨10��N�;��B�;�|h�t� �LI?�NL�e-��ud�w����(s�f� ���]%t���9��_�lg�w:�Y����{���8����y�s�M�����F�UJ����W�����MH�b�&���Ϻ�B\����ld�@C��d��K��S⾛���A�G ���d�Ò�d�ŅD"g|�]ˈ!L�u���
$���o����%�X).O�%t,�pߤ�x�'��*Iq��6;�(�*vo��?��d,��\u��AB����!!��<*�l����R�Bh�#�7�5̛�_��O��o����|��\��50NV���s���R������y5+y����6Ο7��UbO��#�;V�=��%Qcp��[��R��*��[0��`��-)���{���*��>ȱu�/ަ�{{�4��|k��q�$���\;.�>�G�0�G�q`��	Z�{=�!��fJ06�rg�S!?����N������J���<�E�'��T�?:Lǯ�Jc�$��e���{�|��8��I�<��"��%y���Z �4�� ,+�M��_Tv������oD���p�O�]`����X��%(]}�%�kQ�G��̆��q*Xչ�н*��s�E<��E纐���M�t$�
�O��WR��l�,7l�d)#����Q	Om�a�8u��-7hv�VB� T_&S�'�v����&|��+�u_����jy{b�wmq��|�U�bG���{�Y���6ݖ�?wu6�R���ҧrHR� �1m��5d�6e
���ݤ�߭��%FE�)EGܯ}i�:��ẽ����p�z��*��� ��t�����dX����(߁к������W����2"��O�Ѱ��)K �f��n�ؚdEX3�z 0v�*��!Y�!���b��P��=�(=Ƕ户� n55���������^���v7�4�-�n�a�z�:���}{�wo	���!��*9)��R��v�#�:
�0q�p�$3�s�y��_��W�9@i�	<W(�E��y��.l	�ON6]7s�� ��-f��?�KT�F���t`����8�����T�%HV�:޷�]�E���2��1��5<�jgOV���民B�(�@�:Ź���4���92���p���0C�n���_̐�3�+Ԛ���k-��E����v#k���o�C�"�g�7�e�zt,�V�:�E�m� E-�U��\��p����Zu
>�g�_Bp�1 v�rF�$�ّ�˿	� �3>�s��ך��p�o�A���NK�G��^�
"}5��&͹ L�N%)����-��>�2إ��p�[v��-J'��|���wwO�z��/�M���_{C4F�_1�������/����=R4#����IƎȣ��F�̜6�ɬY7����CG�O����i��B��|c[�'�mc�*���IX����Oh�Uh&]�8����Y�x�����&~��v�[h�+ĕo�{G�e�(Ȳ��+g��C�ެ�����P̎/8�FIr&��'�a����.䗅� ���0�jt��\�j�)�s͂���QR�/����S���Ĝ��Ӕa��ޛ���㮍S
-��L�Hf_�����y�=	Cg�WzJ6xDm�#��q_�o0TH�I���mN3�S�ɽ�V36k}RnXĀHe�7�dj@��vN.���F�8�c�T���g��)�R��L���Y}]
�
��ub@�=X�IC�����pd�^S[�0����i�/�8%��^wTO}x^;�,�1`�1����x�\*H.��}�W �O���[а0+��:���qȵw�AͶƼzЦ�|�s�Ukv��}#�̶���o>�,YD��}��B����DXŢz��`Ҩ?H����K���w��m��&��1�$���������,ese�f��Q�f����F
�'0p���9Zs�;1�b���鄜L�׌�yFݯ��zVP���"������dw�#k�mʅ_6��(H������zNg&�j������M��`60p-f79�" �N-�s��y2�C�8�"aޒ����);d}�����������?�ح0q@��Nc��u��NX��=�{�B��¦!�hJ��8���zH�qRu-�4����!�(���/C�3l?:��)�zn��)����Հ��':��=��#�*������!
�3N?o���K�t�{
�6�7�O�+�k?p�Ǎ5�6˓��s��������!���ήR	��(Z���&=�C�(�E�+Q�FY�@�����ayW��MY^ԺqE97}d���H��dC>_^����Ų��RM��|m����W=��QDx�F��'kԢݗ�� ����IvH�F�T�/?57g4f�e�w�(܍����;��W����<�e�c�_�@c��t"�{y�ǒ����bt~�J�>+���Y�9w�]$�ת՟x՝N����SFNk�:.["�Xe�L�����Ϻ����?QD��p��p����B��q bp������U0�Fd��[���Ie\�%f�|��w�"7���p��!ϜmҺ�C4�����ELDs�>[�u��� Γ�-�|���Q�,�U��r-!�H�-0�AGifå�k��Գ,}�Ҵ�����������ݏ�Xn��6���O	C�����.z�� bA�'��b3����V����*o�Bx��*(�>#s�q�)Ç3��!J[�fS���r�w/�Jz3�S���#�rw�y�
,�'���$)�Gߍݽ�8 Ht��O�{�Ք.�s+��K��C'B{S��b��vr������SZ:<�j*�P�v�r�&���r�c��0��R���cm,HH�'_��퀋�"p���l�@�1	ōР8�X�z��85�cI��HCֺ ����ˌ4Kh�m�E�'�7�I�;4ԛ��î��|q{�D}L�7� ����4[Ve��ݐG`\��<r�o��Թ1�1z�|�_v_;_���l�B��@�%�nx�O�9�Q��o �mZ�Z��Pc�$�-sz�G{���(�:�U���� �NH�{9����P%쾕Q�*z�/~|>�PT�������"Qjs���B{�63�Kx�ښQ��G�����P��o�?a��0|���+�IP>���e�hGU��{��)V@�����?���H21lϼ\�*�2#Wo5��������	�]�q��h�o�t�B��g
���������s��Z�[T��x{�ei9C�0t�Y�tA&uQV��GY��(Y�_�m�l���f���ɿW<d��N�)n<
�QY���o����T��Y��X�,%s�(w��'略�6��q��G؍�jx܍�np�ei�6!��nQNGB�'d����J�����l��4�>B4�����Pn9ئP/��u<����/���8ŋ����}jO�<o��m�H|p�#���J����-�\�O�)N�;?>��O�f��eNoxhQ�P����?���l�1g݁�L�h�.w�y�'1dF�
KO`�4K�G5b����2j_yn�m��W~U�P�N鯑mf"���M)��r���X��LtFR��SU`�Nt*�lG'͙`D��є��G\�.��HPC�`<�|8�N?"����o(�et>f�t���nk?Ii��h�N�\�4>礊�κ�8n>�ziۛ�XeBri��0�V��u�)�*C���.x�|�9:��ݰ�P�&�+]�h�e�}%z4�$��21@b�ʪ
�.�oaB}0$	���wcJ1�� O|�O��T&�D��.'���a�)�jvw7$�:�4��$���o��}}�m�YXǱ��jX`��%�7��F(�~<jvJ���7�`@���U�d�mg���"	H��K%&LR���1�A҄�n�o�|X����!��T�+*" ����J�i��*K4�I�%�G�΄��(�W���;jZV�lt忈���(���T�!	MZ� ��B]��i�m�x�r���S���)QqyE��=���[A�����p����j\@%��/�AƤk-S�i ��$����S�l��M	mԚ�-��3}�(2��ǥ��<kF���R��Ʈ����et��E�o�m������9��5�u"��#*/��Lh�O�С	�/A:w'2Iy���+�UmP�����H���&B*K4۹ �/n0���iy�G�]`c�l,��S�)�UW&����sHMJ)/f���Ƣ~�\>ʃ��A,�&U7Y�"�����Vu̥��d`&����\%3�ʬ���y6A��e�J���P�����Wx��Bhh8��ޙ @Qv�n��zʼ3�6s�2�=n��'f��)��#E���o������u�R9�ҟ��mt�4���h��E��V�Ц3aI�A�:��ד���G���#qn��=	�rܶܰ����^��>��
#��.�q�q9�>>�߮�!!�5!�A��n/��uY�F��*�OiOE����oT0&fs�[ rX�.U['a�C�<xrN�Qc���
3�ʺ��Qvp���1��ԉR�I
��&������bo�%�h'E
5z����sP���Җ����i�7��[����!��������Kt�� ,G��-l?������؈(FG������� ~��m���c"�:�2F��@�`�c�&-J�?��bŢKb�3��R��;&[���b�v�4���Ŵ[L�_��w�G�<i��!�=VRϰr���g�F]��"od��>��d�ZF���(� �J�Cn�h�?�b	�Ѯ�-4%��A��*"�܂O��G�<r����O�=@�.�K?d����M�dYr��T�L��[S���;
�%�/Bɝ��<n�L��C��H�ˈ���BZ<oQS�\��X�T`@e8��q�X܋lK��½�Tٞl�a�DP�3/�5�3�dV��G�|��#!��ٷ4��宺��]r!h�$h"U��r��]�^���?�W����-�]:m���'��Z�*U��{z.��yωѓ�QN�
RO�z����<b��[^F��MCQ�����`�=JU�i����vP�8g,�<���3���jF������v����a����qDV�j�
�58��=Z^F��}�8zb[6d���T���}5�Ն�nVC�Y<��	/����؇��F�qBD=�>6�v�<E+Nc��3A�L���<u�}�G7m+z\Էud�CP-k���1������W֕�cnL-,e����T�x�>c�:�\�y�������P1p�# R�f6!}t�K%7V�LiN�)&�=�o:-��Ԅ�!���=P�od�9�W�/0ܧk�1{*3D"m������Ts1:�M���&�K�m3Ӝ�-�s ���i�	�q��S��*r&�ų�p �}�dEk,�� �� ��R]��(i��ٵzA���t H�Yn��>�r��J���}p�C1,Uf��.a�o�(�#xjЬ
���?c;��K>ua�E�h�;��%
��!���β�\��_�#����d�1ި&�8�;�I<���,���3�q�3�%3�_LN��o)P_-\0c]�����&y��ݬ��͋*[�ڋ�e�2��#\�|�����+o��Z�`D�?^�Y,rB^���	��f'Xs�ljH�&^�r􋮵�����O|F�{�{O��NS��"��ɻuW��ܠZo?8jUw��	Xò�671D'A�GG��,t���
�zy{�����Ѣ��Q�O�����3V�p�H�}��8�{S@����}���E:9����@��GmEƙ���A(�*b��J��@A��.���o��������˻���G7�F�b�w5u����r�S��z>g��!LQ�P[b�r�/q^�e��!�M��L�:m�x�_�Y�H�AsʪͲ�E��	�o�W�{Y�����E����&��H�5�ˏ���	s�Y�t!�b W���m���Ư�,��ؤ(A����>fC�2�M�U0��h�Mz�Ms��=P,X��J���p���b��Fgi�T�b���A*�����P���q���6��fm�� ���#���ol��྄n�����ϴ1�ݻ��nM�4�T��U9,��*��fUaz[�
�ő�Z�c��h��ͷ�;�N���Z�0^r	|Or������o�]�[B����oq�<�=+;1Vh��A%�&�W�F���t�>(Q�]�
�[==[�we��y&]�I��A��
�~/)�/��ǅ�Ս���G�t������V�����,���u�+��������b��%:խ�u�N�{ ���1�m�����޷ �+o}}92{��������#��Ӽ�1�b��+�.��9A�O0:E�%̇���xAY��(�{4��6���3ڷ��Y���A=��+���l����ѺnEx������O�P�$@�֯�m�=f\��/�mk'L��?qv>F�v��^��J�r�
%�J���A\��ݕ;���~jYsK�n:�m�ݕ�b�S��h gw۔m'n#��&�/���K�}E	7���K�����ܼ33�$Ж�&���ۉ�shg����[[���*oiN�<-��^�tQ�5�h2��.J.��c�<,���u<�AC��O`*�t�׸i)�Ԓ_݇-���q�1b�C�[$��\�]���YFط���sS=7��*��ߪ�O�3����D��?�z���?F��z�]�ٱ�8SLa�N(���#�����8�T�L�n����WN��cG�qk r&���f{hK�\EU �`D.��Ϗ��QzY�'�����?��������U�
�H�-A��)[��_��Mp������b4�������Pe����1��b{�y�� l��+�1�ǽ��ڒ��ڣp��
1ֆ��J�1`y��'�a��^M�j� RNhE'�	����r1��e�=��2�v0�+g_^�iwr̵��ш�J�D���3��E�4�gp|��h���Ƶicy�4*��p=+.���<#���E��8�o!D��i�����u\�lD�iz�Hy/��]��H
���]3���E+�VBx�o�?�PGR%*�VH�B�,�n؞�nj@b�	�}h�l��������OĻ����R9�����ᅥ�qc �0%������i�̱�=k�NAo�J{�3��o�ZS�m�bA���)���O#Űj�`�+5��ke�����Q�Dׂ׳�9�E_<�ꍆ�X�]�AuS�<I��AG��\W�����k*nh�1�%�h�{J�u�;[�N��e�
��)V/IHbwN:��vQހ�w7(�g	����i8�5�{�����X�a�O����?3RA�Q�QnbsC�\��+�"��a�����b%�Q����}QhbX��njq5\''z)듉�����c���r��˰�f*/�Ȏ�݁�m�p�P�����`q�oR��$�I[�~u S�k��k���a�-6���˧��J��@���a-C��I�ǝ1ج�˝�N3G@u)L
�	3/k޼SQqB�Ռ��<m
���{�
�|奻-�T�P��:���kЭt'z[$��V��/^T(�8W�Tp�5��tmǓ��|�u"��	��(DR�8����J�.���e��Ȩ>�i�$�Z�$1�@x
R��W�W.$$#��"��g(��1�@څ��@F���^l��5h<@����d?���eV�rQ<�$XoU�t����Z6kFv�jJ)|iv���#�nFI��F�D���)KV�5Л�&���4�G��U�t:�<|/� l>�z_B��(7͂~��Y���տ�ZIS��ʆ6M�����3��Hƺ�`y8hQ��B��q\�J۬� ���)͙����k����e���k�?�!d�n+5�ٖ�_�������r��F����8#u�(aZ����G���W�Q��f1u�A3����+9���M��^�ӕ8ܝb�����6u������Ʒ��*�A/W�����j&U�8�%�`[�	?i��&��&��qH������ ��R0� ,74�cb�ٍp����#�2}	�E�f�9\���q�wW�{7e��v�9��
�qT�Q�k
�m��{$BG�l��R�+:](^�=f� �ߪ�o���iS�5�â��ݞy�H�F-��(��w�AUN��R'��)��ܙ����uj�CQ!������f�dur�մ�'h���9��}7O�ݲ#U�#]�˭qSU��QV{��=��a m#���~A��+�/G�j�]DS�͙e� �P=�a�U�P�eI���4�yk��G�}�9�c�)�n<K�B�p������҆s,����oa����?�0�f3��;�\�������~���~r#j�+͐֡58�؆�ȕ2!V
���;rg�R��������ޤN�I���;�s���.]�̠��������d�9�zeU:��*�P~ɤ���}�,��C��ӈ�ѧ�4)�x.���΂�S��1'�b���#��7�DF��y�'V���q`4�%�کT/�ZW�KF��2{�s5��Sf����uI%�i�!.wb"��"G��`����Ǹ.R��N� wJ�y�������$�/�9��aS!��x :���Z���h��N/Ct�Xd�@�j�i�GS��m����k"�P��$��T*
"�p	f�~vř���l$6j*���kI���I�1��,�QIߗM��s�:�!|7�\��?�-���󆀒4;�����;�jI���D��� [��P�3���>[��DC�x�d?��ʜ���7΢������K�u�Hh<��������T$�
WѝRaA��n���K�ɗ���7����c�,��$��<���oX͚N���Dx@=�;�N�w~��?�	�,b���(���A�;*y��5J��[ͧ��7y�x��.�=���·��y)��4�s?���BnFɾ��g��Ú��;�bF����y4ڇ8nX6`�5���6<��ICx�55Wl7=�������Hr�T�9������`g��'3ͫ���S����� g��|N��{��kG�9��. < MZ���ED�1us:8�f����ݦ�����SQ�?3��5)Fa>�fe���O\?P��Y_|���P���❢ʜ�gsd�s�G�[E �-���V"#8�`��9���0�W�8�S��[Vч�i�:��Rj�W�;��"��HB�s~�ĕ�w���\���qM����	<g �3��H}HhsH�c�d��fG=f��sq���<�d �3�����+$�￩L}��,'�'���@��&�7��,�L7����I�l���E"����Hp�����#�)�:�YHU��^R�EdU�Z+�V�\�Ճ
��+#�t��\�Z>>�I����+�X��	�8��iu�,��bʂ��~���(�	+)��gC�O��E�#"�����x��L��B��xs�-O1Q����Æ�`u�#� hK?X��HA�(����쓍6|ԅm��������(�m��Yu��]����-2�'f�H�����$����"��K�k(�_hz��I�~�Mc�}"t*U�|_)����k��|�lE7jE��-�l� �,�=>��5�!2�j���^�
Y���nk��2U 4ĳ�����,�!�R�����%m�����������//`|  �b<��r�=�"C���W�Dܴ\����\�ۉ�;|�;���2�?b�.P8z�9g'���̦��]d�j(f�qwg-�;C���>�tl�"������,��F���xV�-"��B�B���*B\#b�&φo�Q�RF|�26�p#��yN�F���������	�/D:(���bʆa ��Q�M�e�VnL�LR�N_��m�t}�I�Ў��ŵ�7���z������=����z!������������ })�Ҹ:����ߪK�3�D���� n���Oߤ�A�n�Ny�f�91g2+�
���p̴\Q�Ƅ��s��4�Z�~_��SȅT|ۮ%�]��jJ�C�b7���*��(��n}��BJt��,���h�;\���*��?�vS9���A��l$b6<s|'���G� \c��t�V9��ª�L���K�J�ց伒��+��F�d�w��+6�:�X�8��Ԧ������L��7���Ǖ�e���_ȻU)!�U�����]�=!�ufw_/�:�����c:�0)�k�O�
���w��ُBg��W4d�p�q0aQ��Ƚ>������쑶PqcWG��Iz��p��W�C��1���Dģ���^z�:Io�{��:��Z)�ǥސ+��ҋ��U���)2��y9V��^+-`����\���0�;��t�.o�|3>CزTd��j-"Xt\�HO~�[s,\w�(m�+`8�Ӳvέwi�/t*8 ��	��i�*r��D�G�:c�!Թ�A�t�'2�D���˲l|cd�ti�����c��W�wk�,�n"��}�9^З3���l��,��
�V��\z��+>
�}B�O�b���*�b�z	t�!��c�Wi�o�=��q��"l�7$[�-.�Ԫ�����5�@а�LI�`�@lv��jgu�UL63�\���͂\6:���>�����"Is�Q΅,!�v�)�y䭏׶�z��������/v�!��>�Iw8��*>�k���rټ��Z_����eǍRΗh�A��is(�aLqzh||�@�S���M���6uڕ�m&�7�ȑ�/R5����.ٴ<4/hΰx��ca�I�����ҮT-�o�XGsy�Z��S��h���.�+�A>�v��� $tcf�|����n-Rc\�]���t�%�\X�S��s-�O�0��/�4f��~6'%3K�����qh�i�B4�=�v$�">1&��o��ɉL7��t�43Q2��X�GL�3�շ�`�f���w{\O�nʃJ'O����w�`n�w�+�bPg�"f�)㵬$/Bբ'�qw.��5'�|�1�Ȣ��h9;��x8�0X�D�r9g�10Vd�I5�6�8c��[���.�����t����|�&% ��#�^[�*n����E�Y��ª}���� Izr3�p�C����
A�Z�H�	@�FCב��8�*/���.��W�7__LGH�yq2��~��3�����ֳ���j�m�M�@s3b�6e$1�F��+���N�)�Qb|{��{�! ����'�����/)�+,¶��q��[J���ns����:���%�q1o��>�����)�b�.��Χ.G�)j�5���W��3��mS�t�!c�h��[*2�e�2�J�Jy���-�n{!�]6D�������f�qO�����^�Q5a��-�q~̠����8��Ӝ��D90�������W�={��Ex��$łLˌ�
6Y��B�@p�F�x� �W�׼V�.�r�bl���v-����;���5t��Wy³��=��X���M1���qRW��7��%� ���}�0W�P����8�c�0y�:fo���Z�jY��������|��yԹ�b�8����ʖ0���'\�,bT��� ��l��9۰����|i.�pi����w�P[����.�n1D��q�ZYT�eہ�Q(�f��RLc�Ӽ5�Պ%�kԂ�#�o�%�1|e� mo_欓�8�q�Hy��=&(n8��I;�b���dCa�A���\1�b7C|�_K6<}�w:~S�(� w�L$�cn[�8[y�'�ϊ�W~���5}Q��|���՚�_��g�����G0���^L�l4� b;I����#�����0!���]F1ѹV�V�M���A�*�L����=>�!ٛ�X�'�5H��- �ץ=��h�(���$c44s���*����#ցB��!���M?�����
����̦09d�lV�p�Ш���;^+���Z�4��%�:a�Q�S�Dħ*��h�?uZZN$�3�@�������nI�hEyE9�_R;���&J($�����F�i�Dt�e=/_�춹R�(�������F���o���^<��x샂oD6<�����JV�R�r�����J�]���*��2a����o��QCH�p���P�æ?�D��8zw�k����F;aP�\�M�fB�cVF	6����<U�bŐ�6��R�]�8�ehW�T;v�Vh�}�[R5VVM��w�(n�ǀc��տA&�f��d���ǰB9�K7��!�\W�3�|�eR���N���A�� �ֿO�Ns�'�E��������i�.��J� !����ǃ?�#@"��΄/�����m��R�c{Bו��Z�S4N}u�H՞ZD�Pe�@,
5G���d�k6��9g�(�%<H��(q�jCu��u$G(������
M�=(�~�g,�+�?���#2]���Z�Z�&�k��#��B�ۼ��[�#����I�p� ��jN�Z�W9d"?Ú�����'��~�D��\�`��f��@K�Ϊ�$R��[��sY�'XF�������v�j*�A���D��H�jV��GP�F}���V�>b�~�[�^e<M�����9��ں}P2	�o�?�V����9J�s����1��a�G������,�t�e;��$���$վ���_|���     J��Ői� �����Sj'��g�    YZ