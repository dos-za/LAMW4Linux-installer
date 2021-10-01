#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2566641643"
MD5="a3029bbedb02b20ac5d73f27ede0c206"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23576"
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
	echo Date of packaging: Thu Sep 30 21:24:05 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�|��!�J(ܚ��J�սA�|SD�dBh��NO���gLi�"�w�z���	�c�7���l�~lx�Y�A-���-�W��8xg��j8���E�N̩��G�����&�?�e�7���E�Z6'���+���/UU�>u�O(IL��N��]W���y�xi�	��د�
OA>=�������ϣ2�t\
��aqr�9��*�k8��ģ(;Q3�=(@����]w`?h����6�7 g ��#Y��a#�����BW��& ~T���cj1
P�����éѱ��7_wY��o��$|Մ��9�m��v��[�o'Va���|v��R�hH^�%��$�)槃!?�aC�|�`��?�NnQ�z���P�o�~h���41������v�Ӿ�Rql��f�Ml�2Ǥ��-V�|���G�C�D��P_���o8�.{�U�����2SX!�@U��O�QaI2�kC��߅���~q�!�6�|�֘zH��*�&��@s�I޿&� ńa����3���@W�j(Y���p}�ʢۆ��6p����z��K�ռ�ucuӻ3�Kb�enF�"6h[���� c���r����7&�t���+�A��:�V^���󜗩�ӫZ�h$�)�^��"=��5���n6����	��9����m<��&-ZJ��D6�ˍ籽�;���M_�×���ǻ֚i&k֭"��&b�� �#'�1�K�T����D*���Oh%SJ� �e���`���EY���^������y��n��_�����-�E�Q��lԮp�A$L#���M���{�b!Zؔ�-bm9�_Q$�z,ln��/"]��z�(PS�Vm�s����q �E��aĝ�\��A���݊��b���WH�d�'D�mƽ��Ȥ`���#B�x۶CC.R`4s5:!���A����~�J�R9��Z˖̵9��l�4��FyG��<j9.���91t�zM����;������sB�t���S��Ԫ?/ �רv���`��|UZ$��@x�Z�$0��k�J��5h�Ѧ�2$�,Y�+��wd��/ǹ�)�.{�Sg�d�)�Q{�ӽˀ
�[/:cw����9�&I�����j�=C�k�N7�K)u�g%}��|�!�d���1�L���e�~x�r �IJ�>5sP߁~��1���n�Qyk��=d,$W���{A�oky�P�r��	f�v��g&��NFT鯂���B<D2<Oz��YW
1� VId��^y��
�1˟��a{�ٷ0H�#N�b+,L�$��Ll�<�T�{�)��;KS�hd{b�E&}������Љ&�[2��\	ݸ�����@���ԏ�7xͩ�T�7kH@��׎��ta��N�i�oݷ��n�u&1�T���(kW���]��m$�8Wc��k$��ț�'yH �3֯)�g�Vk�𛫮	
��p��<åH�R����Э�- �.�U��-�뼔\|3�pa�4���������z���d�b�<�^]�i�!�Xe4;�$0e�������m�@;F����^�;ٷW֏C�5?u�Jo!�hˀ�e���ǰC��V�/����i0 �)�8�w��������W�Uu�'�X�A�D�)�'���Oc;6#�a���{h�I����۴''"�On�s�׭��M��8v��(�k6��K-��!�����C��rvt���z����'�a���~�1����[���=κ�(p��l󝺗}�U*������k{!��/1�BU����&��\ɩL�����;��'�m1 �ǔ�H6�";%�цj�U�' ����K� ꛎ`%V_�S�VQ�ܱ6@�P�Ք:P��!��X�����o�{�#�S��hib���ZxG)Pc�S�y�X4519HH�O�䘏2��5��a��?[�_+�ȴ�>��^p}�~��޴S�b�ݘ�.���Z�e� l#�P�&v��!�tei�_��W� ��5���P�����ԢFs�C�gz6�h��W�L�lK��h	?7��tw��x{�12:e�LۻMl�S�#���N\d �����V�%?�P�����/�;9��I^���^]F#��̛�wN��L�Am�(١pU�I�2�~]����ъ6/�F�m_����G��8ᄯ�X�xv@$j�.@�̺.� Q_,O�g�+sʏ�B)�T���z�w4���+��BRl��7Ԧ|�8*�1����S�u^�B�SK�-M�NB(�i4J�&]F��$��{�^�V���D�r���~ jO*������T�/�Ns,M��J�"o2Fv74���>n���z�Hz� Ӷ^4[��B]�/,�<]!%�,A�B]@c<C��4�;�R�}P�ؘ��W��C4��b�౗CBԚ�I<�WQ�拽��a���W���	���VSC�{<����&xEl-��P���A/��h��d��1Nv֫#A�h����t��,g?��^��8d��:?7`I�3�Bu��ǻ�<�H��ۗYWl�����A�_X�g���e߄�y$�4��T ��^D��	Sk�҄�b�{���{NW�Wѣ9L�c��Rv7e'v;i�y�s6je=_GQXí*cO�Y���x�����j>�?W)}����%n�˦-�r��)��34*�S��;sq~�����k��t<���ovS�����m�ρZ� ��{)Qm@���ti̥Ŝ^�wEˣ���ďڷ��г�S ���i���)
LT��$���|�dw��=��
Jm|F<DL>}7��qx=�/��a������o�a�n��a7?��4�h\ ��jHnd=����:m��]O��-Ӭ�O��un�o2���u�go���P0^���ۈԚүbW���2�+��]��9B�7|��H�@�13iYCΦ*�6����Ε�.P�I�J���.ۺ����e
��z��N�@�ji�xA�ҔP&�|��
κ����@�6� .���eo����$�?�	�T�}�Il�%�l��x��� �"^Z�,)^�� ���8�'�>d�>@��J7֠r�{ؔ'�o�㹔��d��>�}8=� �]���q#r}[V�u :�4��	����Ѫ�N���EV��,E�y
����0���6u��-)����dO�d�S�W�-�8N�gׯ/[W^��=�6�ݦ*ʀ�Qa��a,�٨삓����o��e�_��L0	r����lD��|��t�$�wt��2r�'v�j�Ċ܃��W�=n�B3��<����3s�� ���ꥷ��6mmH��3�����[Z����,����fW�sa��ʔ�e���a��j�,�鍁�!��}x�M��;U�:��1Z;[����t����[cl�Qe0�֭�G�Ut��!�?�:�<x��Xwpnu�����^�ѽp\p.��K��s��ж]t��_xAsh-�y㤜�±���Bp�ԝ������v�dt�{�L�mf[܂(NⲔ��g7�Ƿ_�7�&�Vw�H�5��7BM��C]�i�C1o��z��~���f� ���X;�v��Z)DEi��ټD+)С�z&;��$͞#���k�������؁;��j��vhԳ�z��fS���$���;�q݈��
�� �{��武����#�N:���p4��^�/��N����la\.6��^WY�& vnq�d�}*Sp����Z�D}��K��ӣ�����^�R'�ov��_'ˠ٥����נ.P�̭�N���I�R��(�wfsv���hYJ,_)g�Q����p��NY3�\9!^�oL��v5�SkOi!=���W-&�ڞ����hYf%( ���L
u���Oy��S��Vo��L����lߊ&(Gа}�p/Ƚ}�>���g�:c g�i�*�v�okO�0.��@(���F��&��2�1b�U�hٿ���^�V)�`9�T@l��ɫ�l��M�Cu4��Y3T����i��g*77����������	�7�1n�đ_Iﺻ�����G!S����y7�#�p�a�+��v��5��e2ץ#QG��$��#}̠�5�[i�қ#��a2U��b�Ų^��;CT�N8z�<��Vؽ�'�-$.m�J�@ؚ�\��har��7*J�wB�;^��>�� q�ݫ�9+����I)��߿�T�<���ě̋��jB��c��o&����ȖH�Mv���U����C[��)qq�2l�f��w�[>�bS�#��4�����?�3��t��U���h2T�9�I����+
i��FO��J	[7>�4\�V@��-1O��X6��tC6��e�n�]�b��I��bɋ�����4S�IH����]�(\ �vﻐ�C)�+[Py��ݭID*[�)�T �I6� _	�62���E���f�
::����=�M�M���°g����5w�?��� <E�N�k4MUu��$��H�9�R�w�ٲr/R�7@6T���E/�b\��p�췭W-BPh���	`����W����E0f�[C�RfF�mM,^����ɌY��X�{�n�rU	!�UPk���/���酱WD�5A�6�2��~l�a�9���.�M_��9����M>6�t���bV*FKik|��A����»jp�5�Z���-���V�v�;P7�1N�_��R�=T��@�D�,d�V;�1�<�U.͌S�̾>��s ���H����N(�Nh�H�J9޸=�>}�C��̉WF��Yq�������J#�!^Z�x�]�iE4��+��&��i��%CƵ �� �D[�l���:p�*Q��8 
Nw��vRy� x����d:���և��H�o��6R��}��Z����T�D5���Ѩ����f��{U�x���}�1+Q���)ߕ�(�8s!�\臉�}�}�G^m�TΑB7fDj��5s	_6ϫ\�h���ٕ��#sk� ߴH��4�p�)�hݖ����A�[yA�GE�哗��e]��ω�����U�|��5�,�F�cL���k��YCM����F��~�$�����X��2�a��H�$� ݣ%�Ww%�R],�>?�
b;���uZ��zp�sR��[Iɉ�7�VʌB�>�_��u��c��=�(6��OA1wܰ}A����H�Q�Z��ҕ���v�zLW�7�}���
���
��J��-��`�e9"��o����Ƈ�P�J��i�sx'�~�R��q'��pTLlÃ�ߞ����'�쑚Fk!�0ǈ*W�j}�;wl=X��w�1AO͐�C�����D�~�g�����n]��<�3&Y�g0�J�3ʵ���T����p.Y�q����fPb�\:%.�S8L�6K�v�M2<�Y�ƕ��-[�.3�ſk�H�}u��/Zv��j��v�V�#A���H0ӟ��mz핊�VcG��=4
Χj�ݔ�R����7vgZ�JzL���G�v�'����6~͜���e@�B@P@��F�'��0h	�-�i��0=#h~s��v�����~!��X�g_���BEf܈x�q1B%�J�?bD~��;U3��BS]��Fv2s�)y��ݫ�yg?`H8��s�?�{�syL@��G8�_Ej��D��#FT�|F��e��r����R�E_Li�'�\�M�~�XU��^�����C���0�"��Vu	*���[~dV+`*v�v���L���b��� �a(r����7��KV�����Uvi���>V�JIi�T��%�),G�S�Vx��<�#��������޿ёh�+�"(DD��6~�|h��:c�+Dքo�m+�]Y4e�$� �О'h�୰����#b%�+��`��̭�Xtw�c���ؕ���@���@}��c�X
RT]P�0;%�swx�g]���d)7Ϩۊ%:T,��p\q�`2ހ=��K��!���v[��^C>ÅPRN�����!��U��h����ID�k� L��&,w�X�;%}d��5#�A����T�'V��)�#b��|�z�z�%:����N�X����=��5I*5FE��;��e��@!?�t0.s4�%+�w:LJ��`���TY!P��2�#%�j�h���k�ȖƔ4����?;Tz�PY�F���C HV
&a@�_v�(�=bI\D���F	Y $�����q������5|�X�A^b�c܁�5�x%��n�_���H�*�V�,�r$·W��#-��������a��xIµoh�3����ZGӄ��x��Jn��)�yіϏ(e%Za�'�u^b���GQ��b�E:���~�]�EE�z �v�P���"9���yD�o�{N�1|��oJ��
�jS�E�Ga6CpL���:�@�n,��W���&sI�ۗ\�X�ո�W��.&ܷkƧ祔�d<xi�!����>��HpLsz��P�?	���g�-ya�f@@�Y*�^{�c���i�a^._k~�7�{P�AU?�.L��>�6�=)�ｗ����W�H�f��C7��|�u�?Bsn)[[?~f��� �ET��G���A'b������0lԄ�ÿ�럍7^ҿ�܃����� ����;�i&9�Tv��� Q�S��I0�;@��(�KS�? +�����t^�; ~%i~
��������B޼<��.A�p�����o���{%��|)�1�	�͉:.H7[za�"�sĴ� +�@n^�ݻ��r�M,i ��YW�K����W�1�u���H,E����]��{TWy�|��((���;�ժ��G�.��Z� c��RXL6�$��Opߘ��[���~fˎi=Kĥ�g}�f~��nB��^Y?���;�i�D(�EI�򷅤�"b'@�G�����9�R���Pm��J��[���R,[�X:�̅#�N�c�Y�W�&�l�}o��ь�a��=w�/M��y�\��/%��#���CN���G�%g���3��d}�A��n,� B�_h�K`�\S�vM�v-�|/��w@o���զ��It�,7:��=�M�vzgD�O���)��&`�K��FU^�j�(�K_�~Xf&�	������,����0x�1�"���S�+.9�4��(�ɥԚ���Y�"̋;]F��>���5	�SF����MHjf��N���\��X�c�&W�#*�X� ˓�$���3�m���@��>jY�%�M�	���Xؠy;d�QB]���_���8A�`o.��;r�S ��[׿������v �Pش��p-��*+���.�'pE6"�i;�:5�O���W��:��쑂�M2v�l����9�Vʯ�?���?:�an��ԡ�)����Rbޚ���)�S��݌������=8�+�k�WO	A��VP�\�ꪱ�L��	v���mc�=I��1ǖp�6�~����R��0% �39�����A�5��=h}���23Y��R��ffb}��f���vB���I�V��Eԗ��#]f�/ba���1���q-��#_���F����j�2�y`%����N�@;�F�C���d1���9������|j�����y�\���J�@��b�����\*�`�k JmY��~g�q�{�=�v��2�oE��i?�)ߋ"�:���.�Q��ȢZ�vO�P*�ช���|���V�S^$=����<Q�M�Wl�S�� {l����Y����A��೤B.����sy5��}5s4�;��iy�6U��_^�3�����!c�i��Y�q�E`#3>p���c�c����KYm�R��뮁�M��z��4+��J�SѿD��xճ'�Ʀ��g����O��_> K3�%;()s�/��+Ŏ���(wv�E<e&��j�^�k��ר�Q~�m�ϐ�x�'�^�j)�v�}t
�q�!��Z�#�{%-Jt7Us��D�2�DZ�z,q �%l2_�fV�vXё��\����n�^+1�ް{��E�GYx���tv��W9��@rʄ��v	��1h�K�\&{�.lՁ��?�H;����� ��Y;)���qV%7�^�L$�s�a������i���އ�יM�ϼ-���;?E-ď��z��U�c��2��K}V"Ed߈��,�b�a�������rыG5��	}'>���=8=/���?E.6�!�0 E9$�?-Z�f�r ���z�k��<����s�ܕ&�U���&H���e�����}���<t>l0��/^@#�si~�s:��1�rXN_^ƍ�:)l�í�5��k<�Z�p]Oh:�ʱY����ord`4���,�4±J׵�J��/{�k�bH�Ʌ
�(�t�f�a�*�Z�v�َ��6l*J�=C�s�J��y�]{ﭝ�շʫ�1�5�N����~�n_u�3T�ߗ��4܈wp#�up�o���C��
8����٤��=^ ��٘m3�A�U����]��o��F��V�VY�F����r5}l�iݦ�3:��þ]��[�3&<	G'@�Z̄l��DT�0��$׭J�{�
*�bco�;��=��+Ht�9���i����p����$��5+����sD���,ؼ��mX�X4��̟��OQ�0N�i1�p�\iC��DD���#+Jt;�p{�Gb�>�v�}3=�Qd��f��J���j8�@�+�$4��I�b���z{b��V<Ւ��+X`}���Y�g0��R
���������pl�?-e<r��T\YH��(��q�?�2��}?v!�m��b��N"F�����
�6�F����͑�s��������:�S���<���9z���,��%j��Ot��x tx�ww�t��bTS��3>�O�a��/��H�Re��� �C3r1G�U���������c<���^�&�''��K��[W962SUٳu ?8�p���6�0hS
KU�=0�ձd�yE����9�¯��X��������L��DB)G��[�m5���qӄ��%{�(s�����].�I�AO���Y�`ݐy���t/��xIE!a�]�gc�R��e�����T4"H�f�Я����� q��92ʧ(�'=��ʋ�6x�C�tgi�q����aVlH�dO���Z�ײ� ����փ��<���4����D� �M�`�sX��G������b]y��<aK�mR�p�����j�����O%ޡ�),�h:��k���'w�<y-�3���u�#��s��ld�}����c}g�ї9���:J��:
�p�V�j`�S�� �(P	8���9�>lO�LT��]ĵd�� �ʹ��:kjq���h"�|�������W+�n1~���� 3����n�u�M��5�J���µ�H|�~'h��i�G�i��,��Zϋd��L��EL�;��FD�N&�KL�żEUњQ��_�*���^jͻ�11�@��+C�������O�U�<�|(3\�SO���l�O�Ul��~�bkSq�5D�ݫ�ڴ�nC&=C\���ӷ���B�G�S���Jk��i�pۊ�,���u���R  ��Q8?l"(a���;��0Wyt~s�[,ڂh[�F��@p��}b/�$�P�~�I�طم�s��;x�Ȣ��z��Y~���ñ�~�b&��ו���8����n��q��I��!SS'���+���H���:�	
�p<}~���-O��e���J(hu�Cy+j��X*���*�X�s/�G}O}��8Œ��Q.ޝ?�5c�6���<?,SC?".�.c�ߺ`�3�O����$�R����Wo{¿dL�r��m/h�>#K�Kw6i�%�PX6��f8,У:����3��D@')�/�(ɕk�x�\����,����1-�1Y�Y�T#����Ma�AB�tL��7餴l-�H0���i��h��>f�w:�o��5B}��#M�O��gj�5nH�ۗľx�J�[�H���&�3�n�]s�oȩ�c?h�+��"��K�ee��(���"���U�_IK�W�����)�p[b<Vl�T��7>^,QU8#�M���n��sx��\�RM�l�F*J�4���/ڒ�{@Ҽ�x���=�S\F�:��WL_?��t�SųĄ�UD�[���?SN�}��|��/w
<_�b�+|��ïL�~3�cі
gsL�Զ���ە%�G,����g��Ь�]"����(w�ȖP�k�ϙ���uL^r/�?cOZT;�\RND��B2�6����0)q=��a�Gy�0������Xn��M]������;uXj�Li�g��ݲk��z�zڮ*��7*��� D��1`�9������_
d6?�I��\�E"��pPljv��/ĩ�.��Y(��bpҽ��{�lC9���;��E{]X{��'�FN˟��xH�n�U��4����^��ٟ��4)�j��o��o�����ӊ7�v(i1j���}T�J�����bہ�`_�i|'ȑ�:|UZ��� 1�8^W���y,�+��KM���q����As��B$�Z��L =ߦH�59���qj}2�>�E+[��v������������,�[7���#�ڲW�%~I�G��?�E������wY5R�� �{Wu���!�gg%�EĊwX	"����z	��ŕ�  
���� &�����~�iH�?!>o�&�t����$�d�Y��2Q&�;8�W� �=��U��� �����]��'_r'î��5�N��� 'R�����[�9!p�N[��4�Ӧ/�Ҟ�l&�8EkqQ�r��$XKE\%��n�g�oAq�آ�T�c(�f�y�#='61��i)��L=@ח[�Y7-��������A���}W�?Y�������V������&��޻�o6G�v�,s�n����kz�E�i�-�t^GbXm!�藧-�.�ԗGf4�a�G��LT:;_$�:j��"I2�v�.��2����^ِ�pJ��U*�"�6��D%�G-h��0�}��e���/0C��l��p�>� �|�X�^�Ԯa���N�� Df��_q)MݟZΈ�)fQ��=��Y��px��#�:���U<�\f��
���O��?�Z��ǎ�m�������''�.���Ļ�"��$g?緂�4$�,��[-'/�%g�����x\�h�ߕ
���q��jZO�B�u�N�0�@��6����wx?�Ů�	�	�9���F��"�Ip�^2�1���,ߘ]�U��pPֳ��b��:h[ڛ^A��{�~3v�nG�x~���	I<�Eg�����B>�:v"�e�\O)v#?V��w��!�(�*}������B\w͛���Z��=��/>3-9�W�$.~|bg5F����l��R����NfRc.�3�Q�����$Zk��0sdpH!=�46�Zѐ��)�ДO�әϛ���e{�XC咼���%<���d11�8ђ�ͰI�w���� ��������Vk͇?�d�9��1ه�I��j۳tRO���*�
TS���iq6.8tYOE�ו��Z��!���<�0n�Fq<���2����E(=\;����1DE����y����(��M�rK�@R/��s�vJ�.��!Y�����p�-6%�" �Aq��74Z������Du*v�ŝ������FN��ԴK��S5��r;Ԟ��7��^/6́�نӼR*�͍�����R���/z���k��oq�H��%aMňy:�����B��d�YUֶz�5��/��{ԐS$��m p�Ѡ�&�����*�������%sle���K����̇˶�<Ģ�^	&"1*	a�!�;/ ��y��<v�@��YVf��<1�)o�D,�n*��Kz��W� r{��&v��2�-Z{1"._�G-�gO�B���r�� R���8`PZ�X�Ov?��8�fs��:�M�迏�V��p27�.4�z�(L����$a���5��{��z�����^���Ƕ���Wۆ�ۗ��P���0+�l[T�tX�d�>�9�xJ�x��I�+�s��6�L,_�)'Kr��Q���Ax���&�ic�&a�ع�E����F��A��G.ˍ��?�c�"�h�0��g��y�!C�N�d��;�]�Y���~d� I�2�,��k�1�������=O��' �-�D2B(nI��(f�f�t�k�v���J���w&5��{����5H�R-d����v�~�[ͻ�({��/�{��6ް�Y��B�C=t]&k(�E�)�\E>'��������.^�ī����N�\���ڙ���+h=�9�������1�����W��9��Me�l�
�F�g�#����a�Y���Ȣr_f�� b��>�O��@,�ro#�l�C����u�ON\3/D��:t8�Xo�\�4+F�#�;�q�1;�z1� �E�]����U�tcCFAE�(N�ק&ɲ��p�Kі4���_��e~�$��Ai;c�?�;��Sa���2���헄���]`���T>Ee-�d�̔�����: �"��O1��IFW������c��4������ {�n�m.�0&$+i��S��6��l0��EE3��*����T��M�z�dj�B2&�/G��I�z;f�j��~=ff�!5-(��J ��G@��B6BxIY�V�i��RO�G�r�B{i�����4�դgRY��qɁ3m�����QxP��D��L\��Lc��|�\:m�1 ���#L��u9+�F�M i�ȱP�>H���Ȼr�v��"�6�-�f���p������O;(��Y���I��HALo]�9+C����;|�==�sZw1@<���=����|'�U�����M��e�xC�6��Z��i��5�OY�G<�Evk�CȎ7hA�?J��e�KS�.�;�W
���ǌ�lK$���N��D������C�c>������a�N7¯��QhE�u5�D����FB�EK���s<-!P��ͳ�'
� ����*MӳT���v3I.=��wѻm���c�{|��f��ޫ?�x<u�ˤfC�ޯ��Ғ� 4)��yK,�����Y3=(��\�V9�W6�2m��`�뎋����+@8��"�ZK��
c@�c�4�GT�ʉ0�D͎���;q ��kL)����g�9+*N�U)��4o� ~2�gM�E����.��*��uwŏW�W@�B�b�^*f�\�7L�g�	�J 5�����S����l���c���	s�>V�U��!�����k����	�kO �=�@�za��������틒���D�cl�]!�k�_��%��:�!�E�/�*��r>��T��m��CWy��ҦD�7��U!urhֵ��M�2�\�m�W���?�>XQ��3;�:fw��Gq�2���?�k
�zB����
n9H��ld|O��h�;~�{ۨw6`���/5�ˆYZ�:�jn����_8�������SFO�}��<-k�ԢEB}��9Q��k�1��F���Ri�PKTp������x���V��J�Y�=HyC��"�٦+Dd�Y�\Y�	�����N�6��FS������X���_D7N9%��l�:b�L�{�r�l�}��Qc�*��Jӽ3+��h&�Q��D2�^�H:X c毳�e����f)U4���wlf'r��l�� ��k �#{y "E����T*����(�k�*�*��̛҈Ԙw�$�#g�_ءGݗD�{KeU�H8"�Kӗ��$�9cr�hB�9�̛��W!(�O8	P#�G��(���D�t �N�W��Ѫ�,\(�����:��"�Q.
�iWv3�����ŭ��T����U����5?��LG��螃mtz*a�k�C�l�e�|�0k7�և�I��#���xHo �7�mm
}�H�j�-����k�@�i�ad$�����T���K�iR��m_���ǒH��#z0�׾6��x/�gp���>9�v:���O��M�Ę?4�A����X�$�#�<R��
�vB��bOC��Lqi(z8, 
ڃU�b섦���PA�kGr_�o CK�h����q[hd����6&��F�]����^>Li=��*;�_p��gBl�I�I��YP�|�؈�vTa{F@�?D��`Jq�-��c�u�ےq��'�H�4#�s>��W�JGUj�܇����B_d$�q%��rG�+�Ę�Ґ-���(�C51�dD~��@��9�f�)�W�o�j!v��	U�����}�rе����m�@hQxz�����WK� ���2��K��]Q��Mj�?��0���ɽr��,Iu�(8w�1��Cv,��{u����	Az1�kFy�d��*���45�h��݃�.c����+�&΂��&����ƙ_C�,^��h��+�������O[J�w�,���cNH�+�\���gA��'uj�2�p�	��o��v�48�ѻyDD&�� |�p�Ed���~�pan~Οa��?����/�[��$T���-�Zcj���q�y�9 ��U) �������W\�uN��CҤ�F�65��5��9�P��=�O&FD��I�E���8I��(���'Z~�It�Q�z]�lG�Br;�7H�L �_^�uTbup
%���,f:���]�<i�Y�b_�*���f�]<V��J���1��N��c�`x3�Y�,H}+�н���a�2����HY���p_"�yq�����h�H�Z�f�2ȗ#��y5o$\�߱$�����O�O)�e��b��z��t?�$΄���O�!נ]����$;�8�L�d>K��
�`��������s��j�+��:Y2=��B��A�i��"T	�9<+B� ��DNRq�q�HV-�d�Z�/�"ֻ4�4 /��+�^;��5���Ի�R"ZtT�T~=�
���X��=?�����z��Y���<�:jM���(۪��Ȕ���.s�Ur��7����:F��ҥ�=��pR�[��:Tnϫ���U=���/����=@;Aƥ�o~��)�t�o(H�^�o�og�?,'�\c�<�p~�yS��j��ְ�0V��t̀�K6�gJ�U��h��ԥt�G�_CG��'����Z��jb���w�mgx M��й����K�]�T��l�6-5�(Q7w�i�u����A��z�հ���+AvO�^.aj��@)���D�=�;u4�a�z����@�oT�m2��+���$C� צ�sɢұ(�-���e�~�y@�����,��UXi��s�!?%I�<m�l��*�6��r?����4rrX�ǀb�.��q�k`��B9rIT�18��FnO�=��n@O�(.�4��F������D���:�`W��N����N��"��)�/U��ܬ�f*u*��7��F���������ux/�bH��Z�:&��8���f�nLQ�#�C�q_B�q.D�rxz�;��/:���Ռ��.��H��_/kcKh^)�Z�Opa�>98�N&h�-�������CLB���b���	�>���eݒ��~c�ݵ	� g��-��m\�L1	tȱ���4m��ʥL˻��άڌ�Z"-�֒��E����~�z[� r��zt��t�~E��w{��IOTo����j��x��R>�5[d:L*Cr���e`�׆K�j����O���6��5m�H�� �.
��4��Z�VY`JN7��TmT�,�SfV����\Y�IF��fFT�@1���G6���r��}^�g3����{S���Vojy���K8�)�4F���� �����`�962���Mߛd��.�j>^,�elS|��E@� ��@��p���]��U[��=�Q�%���k��,J�#�L���;��9��&,�����7j]�+�*�����4�ḥ3HBwv4�Oڧ�P{Dm�jx>B�P��p��(i�����k_���ʸm�)��k��F `�N6��|ИXUh�Cy�Ō�*f�����_�����?"���P ��#p��W����W
s���� ���y SS��^S��>B7�$��ee~����w�)$�����3�{��tK��soWt��oA�V���<pe}�:S�#��\�K�����Q�h���˕z(Ꮶ�����O\�%���4�Rي���Lϻb�.v^� %��u�q8O�n+�1�G����O�ĎI�YΟ<ro<� WmY���b�BR&��S��YF�UѰ�!tY�!��
�w-���Mː�]/z�G��Cl7��%^���s9��t�u_II��΀��Ο������Mʩ�rt2�x>.��+]
i���~��u-v;<:sU��`�۝P_�Am�yۤ+/���%[^P�b��xc���Y�g��{5�0&H�3UL��1��i�6q33����i'W��~CړT#��!���w��K�Q�[+�2���]9֔j�QC6byus��:B����m�!��4=�*�J@��=%��4,�~��\-�,gG;l���|��16^DT�̊?n���W7h=���	�j�(�1�Fj>�VU�4�c��a�z�2��πdP]nNq#K���=u�b�� ��-E��d5��Ƃ�:{X��y� 5]��N�	F��X>�*�>�)lX!+��?�K�Լ�󇡛	�<l�-ǟi�
`�����*��Q���s����U�C��֍���7�q��Ֆ2i�$G�nk�x}Po �PE�E�Y�U��;0(2h�/k�Q��O�#୍���dB��0��g�U���G�F��lO_K/&a
�f{��FF�� ��a+;47_���w�׋�<]�K�Р����k_y#����ݔ�~��4�}�2�s�����5IVO?L-'0�w�F��?��4.I�T⠆�AQH ���g��uM��<��R��\�Z@Ql���x���%q.Eə���:ʿ-,�7��T��ww�{D|�;z n�8������p�F�zX��a����*ùw�f�.�N�¿��]^?})_8?��:5��/2�=Jn����wF��E٬�ȅ�KoTʎ1z���f$���4�D��aVCw���3I��d$�B/r��i0\#��z�2ɹ�I�8��7	c�3~Yޥ!L!�� )�)N�@A'/�|�H�)�(9�n��>4���x��	X��,�3C��s�n�CP
z���発����������j<���I�.�-|d@3r�*cV�m�0�<��!�VTPz�O�X��	�+�Q9�?���� �� ��eB9����'�B���<�{R׷ӣrdj�A�^�= �B��<�!�
c��з�}���x,�C�����E�R���c���r�2�Rp�Β���j�,�	?���tA-m�%�2�a��%��y�C��=[��~+g�WC�6��m�6�г�	a��k%�������f�8e)5��.^c�w0Es�X<<���?�7b�3`�<;�Q���~�� *�9��[ˑ���[A�#�e�-�Z��y7>uM��#�L��t5k�\!�H×p�b���% v�Ͼ��Y�$w(s!Ҵ$!}.l��%�OT�E�8!q��$i���I/�haC[�K&�2�J*Z7;�P�j�+Lɭ��jy����B�����s7ll#3�)��2�������mwd�q�P̡k0���5�V.ݐaB�%���-u���tWtᛟH̋+Ҫ�o��MI.�����T3�=ly���9��#�hT�b︛�D��9�[F���+����� ��W�+�@�>q��}��r3�k�a$Jf�x��`��R
 �`��i��,`��L9B�*����D�o?:����� ��Q��c}��o�BO]i����8�mݶ�.�N4���7|�����PX�L*��:�!X����	�+�m=�.�نNe�y�B�� �%���-_�*܀��Bؖ^ƖKe ��,`���]K�������
���V ���i���\�A�&Z��e�`���H�m�9
m9�|c[��AԿ���f4��W�)�(�-��V���_�wf�pr�0��`v�Prxa_>3Sc���l�%�O]�;�< �.���8��� +�R���$<D̴�f�=��\D��J�P��q\.r��Qa(+)�.�N��iX6Ip|�w�R�����Opʓ���?�tZs��MP՗�Rhv���9��Q*yT����q�E}�JH�����������m�w�E"Ζ��>B���)�S���!^�l�ZJ��Z�l&%��:>�~��pJ0,چ<3��G�G�����u���Jr�|�x!��U򑬴3��!�@�ݻP�Z1W�������=�1U�6dWt~���BD��0}��}n�����9th��U�]T"����sfxc�ɼ��]vp�%3���aO��B�T�h�������2Ǻ3��������ݘ���gw��>9V8eR��G�5%|�m`xc���uM+�~��dh01v�&��	v1r�L�^8�!©����X��G+���N?s�e��!�������-�2��}*��g�A.���mE��e�W��Zx��%*ڴ�6�C2�\$����+���i��n���|)�\�;6��`��-�Q�������`��n1�!��U�w����޹��rX�^�ظ�~�j����g�ňU\��"��h�Ny\���!�q���D`�S3J����ncq1v�� J��j�I#ϢF7�<�uy���8�>�~��%�<��4�UҟZ�P]E׫����@Q��q�D�GQ�7|�a������F2�+6\Y��B��)�U�8O���CsQ�m@�hZ}Ki� ��Z�,$����1x*��lEK�f+(���@��W���t����R�^q�D`.l"�N�0�!�~�}͕��yF�nӢ2�}�^�����;�=�dw���tS��ye��z�����Ko�MA�� 3p�$u{�,���A�m�5yy�$ч�t���G��_I 8� ]&N�X��p��9��.ZB\���7������:��b;:&۲=ʐ��PW���{�n�dZ���}��6���i)59�L�8^X�4�9S����&�Đ�.��qb���ɓ[zD�$f]A��9�!���=��a[K${�[)���j[�- �}Ze��`�-n�>�9�~�J{�fM�14gI~X9��6C붖Po���aЮ�ߎ�W�������23<��y1;�f�	m�C��S$6����m������6p�A��1@����"H?R?ԏ�m>%�̗ScX�T]P�s{c�����W+�m���=qq��B/�ˬ��ڑ��A�ǩK��I��u>�t�Y��#�꺌Y�M�ky���Y|�Aj9�(�Z���%������]�X}�_&Y'𶔪{ë��H��g�7=�X%궬GPIi2 ��-yNm����4�+h#��^�^I��r��C(��`/�1���O��g,[��sjG�V�h ��s����D���v�a��㻏𖉒��!,ι��N�d�6����U�c��M���=Qu �+ï�Cq�rӎ�p�,�7D�Kb�H5�:���X�A$Q[pDۻ�٢]C�s�ic�[1�X%�Py��C�%-[�}�q����N�,�������tKJܨV�{�9]'���Y�5>�'������	��IvO����=;�n��[�kį�#�`����ӎ^	qm�	�X�y+�;����S+Bo�l��6L'ԡ�f����;�����%��=��8�N�>�憾5�qh۹C�3>e����U�${4S�K����P<M��Q!�5U�
����+P�%V��"�(��;����`6��N���T��ajm}[��,�z���Ρ�b�D�|�E@Yia����X�J��Ar����ö�%�����b�l�R8݅ �Hw�_�h��Rs(���ԯ�wړh�r4]z�V{Y�R%�o�\����͘BӋ-��
A+��%M[��H8�� �D����uӠ;QS�&���ᢵ�&mRM����H�v>�>l�,=�冏���@k-�3MO���/�v��~r��������=W��Z �lt V�qo��5�KE�3�m��;9����RZU�˵� ����6� �C���t�:�����b^�W���q��9&�BP������& �*���szJJ�]N�j��w��:�W�g&a[��;-X�z��i�,A���ky5���	��b����������%�*���F�J��@ǲ[Mr�O|Ax�)�m�M�����́nVw��$��!�T��X�ޚ�:�Ⱥb�V��[[=�3�2�p�n���^��R(�t[�՘�v�n��â�))�ђ��.�~�m$��n��F=�j�z�fc�����m��u7i���^��/^=n�r4U��]!�MӐ��hi����'��By�P��v�R �Ĳ-�(�y��V��a� N�V*<�����~p`�k>�>���m��J5Q.���9�J'Qsm�p������y�4:��z�H�2�k�0��f\�O������81�ٗ���#�� ����X��.7ѵ:���Q��*��o� {#��|�<��@���^�<�c�B9�Q�qz�b$���>O�X�.���a�_�4NL\�y��U r�3�{l�trۙ^�8o��������ҝ2<�u��yun�Au(��\�3R�QW��d�p}��۰���[C.�kuu��k(��R��p˽?7Dd0�E
�-���[u���#�se�(,I	PL�E-v�	��s�A4F��`��W����Ʊ���ݮ)M���Ԓ�`A�Q�l,�4j�����R�XK8v���i]���W�[Rߪ�N]�{�NMU@ ��x@*�4O!1�ä����8��*,@����~Z���$�Һ���c$F�il�ca��FV����?����K�NB���1h�P#F\�mM�$u[酹e�a����H������+���|�oX�S��K	
v�1,Sʹ�v��Z�:"��<�f:�Y��X��i��؜��5��_u�H���:"�{7O��;�Q�kv�����5L4�^�Z�(���q�m!|��w��Z�z�5���4��y����g�ȧ�6�j���&�RV�"M��,���[ݻ)	n +��i������� n՗g�s�m�>}<��؅��}1''��H��KR�vPԔP���XAr�|���͙�`�8�p![�dEoA �n�~Q[W�N���O�r��+��v�(,�HO�p(N�
ٗ�+B���˫@��+Z��ݍY��Bc��X� ڭ���И,�5Rp�Ҽ� ��c�q�����|�)�g�롗:�(L��e7�z�Xi��5�EO,��z��+����cW����x�;kS�x����/��/�-�)�|l������Z9�黰�#ELG���r��xmG̥���N�u,xC���C�?l!���� �x!��bvPN�a��R��=s$����V�:ϟ�/]\��X9l&��l��wd�<S)��*�\��g����ZN$�2�S�w�Ͱg��Nv6"}����|�*��֕E�9Mh��b�����+S�D�'ou��.�?������QZ!��S���&��CKH.�L�n��Ul���eQ#R?��a�Ԧޤw]����U��\�/��ꛤbHD�~dS����J;�)ܹWyow:�� L~ҫ[��;os�:46[I3w�]����B5�3k<�+��^�P�#��Q}����a��g��°���lH�q�+݈����`������M��7�m�l$W��63.�}��4ϞuJ� �ѸT��Yx�/��1�^��� D�^�����:Kx��L!񮄇����
�PT���UE�o�	��S
ۤ,��m5*r�#LuN�)�_R~�$����d�VΟ��։��aj�*|�|s���jڪ|<��1%�ѐ�kҠts��+�;'U�w^�jlu� �q<BL21�j�P\MN wW¨�����o<� �Yx��o(��'?��������+�N~�˞~��*��7�WR��ыr{Ս�2A�2�]�9K�\����S��[�ɕ��ee��G3x)Ph��:
@Z�j\gICmb.�n�o�[LoU�����%%�%YU��X2�rxH��n�\Z ��Y�..��;� �M7>����*� x!G�en�񉻵;$o&�����D 	��=w;��MgO���e�؁�
�X�50?`x{���9K�B響���A׳�����|�$V�w��y���u&	b=���aw�Pc	{x{�D��y�Oj-�Q��j�:���<��6��C3�Y���~z�b������:]^<c��͉?e�!w ����Y0��X�<V��p�3?nH`���q���M�S�>��0e���ɼL�)���Z�v�z{��6wz=Un�3�*���Y6d%/���k �Κ����	�#����#�!� D�چ�0��_�n�/[Wq�V�u��v���m��:|��>?��a�6�?�Hu6��C��*(v�醝�L���<��w]�����1h�O�6�A�⽗�[�/���|��J�V�K���%��
n��{$��F`�H�Q��l=ғN6��m���rm�w���W�R=ȍs�����]�4�dO����o>o7�bK<��+����Q�	��/��{�ҍ$�*�7BQ�����j�*ꪎDq`���xp��*4|4���T7t��oJxy��Y�[r����}>j���l1��jf��L������|�L@H�Ç��S.J
��Ԅu�Љ0�Sl	ɵ�^s���«�8gIC��f��g��~�ab�9��{����w^ZW9u��b�~��t+��/��>x�Eɐ�#����H��]�!�,	Ư+��� }���j?�N�C�� �|F�{+�f7H��C��=Ǽ�	͖E�3B�`m�^t�y���
��:�ʜ�i+�@�_XTf�����jO�^Ҷ2aW&��(v�~�֫\�%���IB��+@�8�K7]���/	������5L��!��� {[�.S�	�]�M��
>�� $l�l�H�$�Luq�,N�a?�i,���T�LP��Q������gE�h�����ъ'��R����ȉ�����N���hb�&\�7QmF7��-U)N <5Imn:" �����e���g�    YZ