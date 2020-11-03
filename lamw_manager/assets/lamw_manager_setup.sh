#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1402243797"
MD5="0a93bc706f9dd7f96514fbf64309c6ad"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20676"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov  2 21:46:18 -03 2020
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X���P�] �}��1Dd]����P�t�A�ep�Ġ�;�}��h�9��A x�A	kh�p	�܊�;�`P8M��0҉vʠG5���_J�?  ����^Tr�6)ql|kb�TUO��i{�4�6H��g)�^�
+}ۺ5ή5m���p+����5���0�x&΀q%Im�j"��Ш�}?����2�y��ː�K�}7FmM�0Ksn�N�e#ap�[ �Tbiį	?]��5X�b(|���T=�W�Λ��;�h����_m��[�;XY���+��;��Ԧ#4'7���iUb5c�h�/]X�C�D����1]��}T.£:�Е��.7�$���5����!���N_���b�"��8b��W(Ӵ��@�aƚ���eA�%��Da��&#�ԮEXOu��Md����Cщ���\q��/ǔ��[Б��>/�N�3pW)M�H{6�(��`p@���}�㫆�;S0ݝ{�'G�
��F3Ǽ{�d*�p9*l ��,vh� ;ě��~X2��� �Ӱ`���al߰,���Q��o���
��)�w�'��$RR�A�+f�M�dfwV�?�yp"%�'2�Io=��-��I�L��S�S�:�#��r��zp?F�:D�lk�`�2�>��=���Hȷ����9.bi��K��ߚ^/�+/�,�O÷L�!+EZʢH�T��o�E���0g����g�m���5/[��C������ьn��<��c�L���d�CYV�sT�,�[AHuZ�R�՛2n����"Ϣޙ�&�B��)��81 .���ƃ� �~n���`����K�q��˄i3	`w�?��}e=Mn�b����,*+IÕlvz�8����V0-�u<^�jH([�]�2�D����S:�w�@���7�<�mԊ�/AH4���a�y^�6~'��I��x[�,�|\��ĭ?�q��WNt	��m�ܐk,��5_�H�Fߡe'f���w�9j�	a�^�a�+���|���V�0��!���pB H"Ϋam+C�cl&b�e�_-IP�Z�/��QD߯���j�Ϟ�_��m�e2.oj$��ߑ��"�>Ŧ��Abp.�6���4�`��=�>������Kk��0^&�Xo\p}]~�+99�#0�:	�ˍ�k����ܱQ���~c~�=}p�}?�֯���(T7��[�4ϼ#^��uF�K��g�W�x-MF���9�r�6���UlW��A��¯Ƣ:��n�b�%~����j�m�B���:��L�d%���'��K��A1
VA�C.5��k�{�s�gQB�s�f�~�T������vB0��]4)��o5����Sͳ���9��l�B�N�g,{�ij0/%��Wc�9��VaH�N�'2���|�,v�0!M6O[�JQ�=y廢؅�Xu��`�Ѩޢ��kt�8�\�Y��K#����^����Z$��kfO�>�����wH�bhʓT;�H�ōx1��j�,aI�#\p�O��� e�`�)�+����Á�V���+x�c=ԛT˭F�L�
�-��Am�ޝ*�s:�������D���/�u���n��|�][|���X��^]�0~��l��U��_[�0�E������8)6���ym�yM��a�B����I��w�Sg���-@�|tH]�3�n��"	 ��E}�ֲ�� *��>j�O�!3�i#˯��ܩ�jb� �mr�Fr��ĮW[�*K��#Nq���R����Sc��X���Y m�O�VņW9��qWְm: �m �	�j�8�H�T�p�Ư����\�+��t�zfz=D�lF �g���`O ���]7~WvCF~�q��;s� E�~|�Z&W��-h��X�Ms�d��������D���qՊ���C���l����>T34q�q	�m|�-���#d:Jѡ�/�o�=)^A	0`�e����=[Zx�#4+2����E�k�s��Ͷ��Q�����B����{kV�a<�5*<ˑ�%�v�����h=A0P2������sn��	zަ��Ͽ6j����Ib��X�Ut�a|�����uvH!N#ҿ��e�k�K����)k������tO*#v�������kǾ�����f�P��Q09�2��j,���${�_�Ѹ/(Pz>�˟�ė}6-@,��:Z<+�~7��b�Cc�<��ch��[#N��U]�������Tv�������>p��@ ��-�����[r��֞�����8.��j��>����!BF-ZB �G_�ܻ�'�Tcv��n��f�bqx��|7Eԡ/��dy���#) Mtu��!C����=>������P��4���\�j���ke�C� ��M��k��Njh���1�_C�K�����<"�G��A�������ihC��������n� _��#b)Q�*y9c��{:��^���X;e��:y����Q^;��C`8D����?T�"���R���VT7��Ѳ0餂�u )��{'tt��8�W�j=P��\Ijhu�wW�&�Y7k��)�q����D(��K�������ʀ��֜����u�:���eIQ�)޷��H����5*W�$��6�U�Ù֞!,��"q4޽�$_��	���f��&Ev���S��<��\�4���!��[�p����@'�*�ɕ�r�>�~M��C�~c�R��f���J1�zd�Ե�"=��jV��/�w��o*�K�dW��L�3�}|�WJN+\d�!x�['��y@B&A+���c8&��^m?g���a��&Z4�8�Q��֍�������	�:+�5vȉcvDL�CU>� c$`��ʔ���7$��k�8����	�R�������/��I�MBά���t�/���}����yY'��1�(]�����珲�	K������{�G��{N`��wxPz���&
��o��N����sW�o�Gt�wl�
�o�K�sQO�fè��桋�����q`3�o�,�1��Qm#����N<^}հ��S��Z���T?������~3��U.	��s/�V�)�K��R*���b���
��5�>����%<��$T���]5���e(1�.��I��Y����Xg�!FMZ�L��&$],f��	��RA�a:��wp�i�E�7(���S�U�8A�b������`(�X8o���
A�Bx�U��F�ӯ1>���)�����=BN�����ʁC[��u~g�w�n�!zV���"_JJ�	�v��Vc:n�ןZ����S�ħ�w� ��1VGڀe�]���xBC�l�RhN��G�,�	w��5(� � �=-o��Y��Z�f��]��J�1��m8��,_ �ɮ9.qC]	f6���f�[N��֔�?�~������/Q�wc�b�ȋ�H��-�76t�U�t�AQ	�&�y�sXW5��m����˿ډ�ͨx0���1��J5�L1�_ǯ�L�ʃd����C��Uf�4��*�3.���9�ׇM�.��G����6%|���o��U�9�X?7������Oo.3fC���r�H�lXl)�)��>���	���C��i3�?�f�;��ї���C�b�bs��M�p3���Du��v͖ϏJ��.p0�!�Uv����c��>2�O��O]�7�Yy3pIr:g�S�C��^C
�=vڝ��B���1�t�ҕr�	��ä/D&������Q�Y���Cד�6�8lJ#�Q�p��2��ş��~�i��R���UZ���䶜\�a�t�����W@��Ž�>�M包%֏�Y=�7��i��q2��B u�܃���"�߽�	!�g�Z�����9�����V��B7�/5X� �J����;��P�e
n_dU,�����te��)���J�SK4� �'e����OH��ׯқ��?U�����D^SB���AWL���rq��y�LG:���U���p�,���me��H��������\g3�x��=�����j�F�Md��H>���q�
)hl,C*A{D��-7.�oNZ
U5��i;3)�F�Nf�O�]X8���b�����c�%�)�pH�̕�6K�7�L��F&���7Q��� KTd��(i����	��p�,�[m\��3l�]����&��mL츪9���O,-��Tٶ�/�� N?S!���ز��&��������e[l���IK����'����/'���g6�ͼ�Y;����2;�R7����(�aw$BJ�����/�<��p��P�6���_�_�E�^��u�P���^��C.d�W߭�>=���49{�)��BR�r��Oq�n7�d���ӜXG��ٕr[m�HND rP�N�:�˼VA�=pD�W���*
^z�k�0�������ߟ�YR �p?s��-�Ӡ� ���j�-������bvR���'��a�-����,,O��88ƚ"�o���݅)4#U����>�:o$���@6���G�l�:�\r���"� ��Ƃ��k��+�,\�n�omٟ��=��qb�̡�-��zlk�^E�k�X7:���}�V�H6�&��E��1�2� j)�u�`����4���Ë��y���Y]���a8�PU]N����ῶ�)p�8�������?�ΚFh�
VB��{*{�"q������mm����  L��%������['9�?�4��hZ'U����E�}�0���Y���hٚ���RxNkI��s�6�;�/ �~8/f]��+��(�=�L��~Q�_%��+��LR���?�s�LR�ڿ��Vu3b��;��~ExOTU�ʆ�:O�x�)������h�Nv�A�i���ebG`�Bp8�ѣE��v�&2'�qÖ_e6��h3��D�ǣV��6�Rbڷ�~h�Ӎ��X��������"R@mh\�'IkRf���m^���r«���;�5��|���!^-T�;ǳ7���K{^kR���k�yL@Z������ ������0;�Mjޠ��K�#i`b�$�j�������m�����ޤc�7��)�p��!f<���s��Q���L^�҉�{7���3�v��O�6m�{���s���ۋ\�œ⯼MMT�5����^&5�	�q��z�c�Pr���L�O��V������}�@����%Mtt�UF��\Ȕ�]��dy��\x�z�z�=L����<=Ͱ�K������^zϻ�u�"[�P�~0�47!�)ƤR5_����h�_v@aIqrkLޗD��FHQ���	�YK���(L�W������(��H��g���R� ��w<YΟ���[>B�R�+�Y8��nٽ��!�w�d$� "|J����L���)12D�9HO#fsj
�\DT���.��1��{���ȁ	Y?��"u�v\�`���jy���IU��s� �˼������f+�s�Fg�
�?��HөD�ש��D)~�Q��g���-OnZV�!h����3Q�nx\~��=�]�",���{�\ż�������C�|3��c�{F��?����4�H3��`�r��k�z|�/(W
?�{T!�r�fVu��h~����j V8�~���d���;������Ķ�����9#��_{�7KA.c�)����0�ߑm��Ŗ��Xmd�/�${�α���KOc��;̜���L���Ҁ���C6�֠��@���`?dL���!�vq�\.��vc�%B�5�y'�R�I>�d1i7;M�z鵂�jz�����C�� ��J:/����c���b��OT؈�1Yi{�(R�`����N��a�gv	0����fi�<=(�Dd�q�5�4���B)��bKy+��hZE���e�m'�"�X�bp���p���]��0- �W��i���>㥷�w�`�K��fp'��#���U%��1U��pX�H]O�ZRy��X�������_� 3���}�2lk<���u�	�m��������8���?6��Mt��?�p��P# w1ՈgfA������!u�3x`i�U�dE��DV<�t�off;��t~�뫡�H��r���i�7��ͱ���� �'�+Q7�.��KixA���ZP�k(=_�BvF����|�ޭH�p��`q�A]����{)��R�Wօ�[�UV!g�z(�HJ+����Aꀣf�WL����P�5vz&D��8d�5h���$�X��G���b��x��ChFI�K�}��,�4�"��)��P������
l�bZh��?%�(�q��u!�v�M�1F��lQ��j�*��2R��J��bR�&�Ko���[����u��l�X�~��6�fiK}�s^���JOjo e���%����f�٥���6� ڥ�hD�6k>��j���@3��$ W��?<S=ھ��vJ!M�ԅq_0��������U$�d�0�3В�#�`�Tr��7ŶkqQ��T�t�F�Snӊ�l��lj/3,7�æ��g��x]�Vk�X�� oƗ`�i�eϺ�l26�X�M.���夋2��o��[�ʟU*@H^�?�ו� �;V=#�H�p�s���Tq%D�氢|�����t����B���;�:��B �Ÿ���c�����+'�|��f�r�z�<+���N"�Z/�~�c~<�%E�ǒ~�ŷ�U�J$��7�G0��e`�,�տ�=�6�&�`�^m	��Ѫ �J�F���0��P�|�W!�f����B0-��?�\oK���b��VC8~��6e�JD�J[o���iu��|�����\I���b9�f��&�Hc�V|�3誴;�cG�sý�?�K�ݱ!75W˂��Q|d캃�?Ow����9Y�H��Oؽ}��#��/D�.")�|J�2.7�Fi~I_�#��<ս���n���u�M�>q��jSג1�b�;�b&��Ib��n������.޻�~$> ����)̀��H��u�"��<��^����G1��*v��/�,3}�a�e�'Gd�@b���n w�RJv`�7�d��K��?�J�����7(!��{e��w�-���}b���wǔ��7��X�b� �S��P�1�wѩ�
oω�����ߞ��zћ�ܭ�M�l��]�|L [ׁ��rN8m�����Q�*UR�q��������#38�d��v\<2d2����N8��ֺ�lX���������H�06�:�$�0_�݇�夰��
�%��ߗ�@cH���KA8YO�z`j֋E���<�I�L����6�d���c��dM�irE �zy�L��b�`t
�Lyk��yCɕ�4�nB{�W0=���lV6�y�
�,Q)Qg*=���:���;ء�mR�/KՒ�aj"\�@f�����*8O��f�g$�i�ac��.kmd&��:�Q��ej�Z���� 6gjK��9�ӟ���}L&�Fn��C]p��E���.kN��y��JF�$��Rs�sBB�y8��4z�r��4:�K���"=�D҇��6�G�<��.Şu�F�}�k�C3.󿲼�EaN���h��L��r9��X�5g�����$�����P�6c3�l�8�#�b-(���d9��2�C�p��Z*�Y�A��WOЇ��D��g�;�^��,���j�$��������ԧ�|ޚ0��:�t��%�շ1��2���LN0�r��mMW-ka� �#�'��n�1��R���z	��;|&Y<|r���"��p�ލ=㝖�����l6������o��d�����ym. nC+D��}�G=�^W��\�86Z/��,���+�6i�b�`8� �7X"��h��(ܱ%��Yk���ƕ����#�Ҧ�g��ƀj�����~�y͗w�
:���C>�2��(A����N�
[�VOnȴl�]��l�eh4o�]�H�QwKHcm�;ڢ�SD�8�)sH��]��=9X�4�`}��w��+������|�Q_y]3���x��<����\������8���1{W�V���&��2�$	N��>� ,���j�Cw�"Li['�cg�A�����G!�<>Ф��(���W�<���^��^��FnVŐ��E~Ow����i�4����t&W!�S��Ʒ���=q�c�zli�P�P��o� ��Pg�M�IߏP��i�C���K:�'��Ƽ�_���F�0�oz4��WA����jm�lw��(�P��.? �M"��E�� ���J���ʡ�k��X+�bq�-�ߔ��y^��`9B�����a��4Y`
�滳E��7�̀����K�zO3q����>�U=���B��Ȧ�	D;{��mɫkU	"%m����h��Ʊ�M�+�:Fb��)h'��(�s���iڛ�-Z�[��FB�V��7��z}��q7D��ې�=T�c"��J���[�z�}H\8*����-�]��r�o�
w��
`m���Ѳ�Qz�ŅuTZ��HF]6c�)\U�	��jb�JS?��c��3Pė�V��|��j��CO�����Rtj���E�2���D����/x���B���H�6{L<E���Dw>\C�:��k���2s��g~���V����u�k���C�٧�@�a�&��v�@)��"��;b�'�"��^Z�v�տ�����Y+b�x��֍pɾ��\��.���'&��G�V��Mw]MR��nWNIƋ��Р]L���w8�"�V�= ��
��/�cp7�	��L<o��Z �Ni)^�
�UȭI�!"�>�������@���Tb-4�)d^&��ӡ�]���9�&yĈ4+xp���]gu��Z'��
��H�Xp\�-8AJ� _l��$B/�������_�& (�י�� 1Kc>��p_�/\#��	��E'(��~w�_Y[ٙ�WnJ���SYV����#%jg��«����4���ߨ�dE�,I\~�Ж���ǋ�zdq��a��?����,qywc����jt�>�����ݱIWs�]v���9��� �_I�|- 2�����u5�e��x,����o})� �op�~rbm`�{vers#�M2�^�2,�ŹX��\O�ɴ�6�&�F�U�¹���"�}yN�C������]��m��vTs�@���ZB!?�5��$yvVC��Y؜l����c�H�����i���GڳF�@�9:�ӲCHH�6�Йw���"����z�)]�+Xt�1�,M-.����LT	���,�������ľԼ�T\��}�,j���~�nwʍ��ü��K>S�A�4����@(0��+_,��� R����n�5��St��1g��'%��ca�y�*8�.��k�ox"�ܖ�[N0��丮9��}�\H��l�~�։�7����.S��Y�^l|S�n��4��]g�d�6��ޅ�K�GV��]���J�MXؑ���7ǒ4�T���e1������U�//�f�y��j慢
,vf��۞Ї{��VT��j�H�a���<��[M���5V��k��i��XLL	;��|$#QQR_z���ы�5c���~��ƥ��z��^/�U�f��JbBӕ��W|���=��]p/����� ���Kd��B��Tk�&�a��#���]#I����7�Չg�i����|]$8���~���S�lY��]uj����l���q�d�5mC�ͧ���^�tM��N�#���@`c�+� B	�O��e	E��b�wܰ,���=����T���U�0�n�B�,��w_�=):pȓ"S n�#����P̥�)�}�����^/�y���c L�k�s��X���@��ɢ��Z]r%˰ڋ��)��X]]���E�ǫFQJ����."����}�y����oi��c3m���1�|�N��B�� ��nǊ��\IF��Ю̵g����#٪�i�a7EEc^3� �ʐ,���k�����h7⤻�{�e�ǆ��T�҆3p(�J$���j���E���av���M�}+{)��;� �R�,5qg| 9�dd0��g��ڍ]J	v|����F�`�젩�wA�@���c��W�ѧ�qDZ<=�yG���'�CfЗUThë��������J��
Ń��ςm�R�Z�����w�� 3��1������\�����8ޣ(�8��˗��V��5æ�]E� ���(��0��9_R�Dn�L�R�g��w	+��콸�Y�J%��4��%��A ��x��W�T�?����}'I���dj�j�P��\��GX2�3L��jZ'� ]�3&�kr��#�+B�/��0ʆ't2��׀1w��c;�uL���=�����A��n9���ߡO*�Q�3�o#��
�������=�:���ml+��r�*F��
�,��'�ٞN�O�O�><��z�s�[����_�)U2E��L�IEp��g>�S�m�! �~�u�M=Q���/v=1P0Ta|�m���{�M��!UAv�B�U��_I�u�r�e��V��U������˜����c�ˋ����fV�E�3�O�AB���Gf��Hv�r�xM.�H;z���Z�}��X�?�B�H�V�����қr��ݮ����4��9�X��<i�4?~�T��M$5�0�iu�҄¼E��J��x�2M%%L��CZ��MQw��+Xl���SW��;m��s*x�$�,�����%��<��ɭ�7v�H��T�F�_i�C��������h
˦-Ep�,tf�aO���j1�h�!�\�W��_�\�b�tD������l�?q�Y��o1z5@���vT�"��~a!]��F��ٱf ��J��zF�b�h���+��qqH���u|T��6J�,�(%�7�wRƨ��!��*�$�Աu7+�2�h_�d�ooCT��L�g�h=�	\�R���7&AP$�A���! זO�-�w�^��X��[�f̀�� �r|
�wU�Fd��֢CPw��j��l�a�r��.�9�g�����ߛ$�b�m,Dt&"$s�&�����&�6#a	��_݀�Sh%8%�Z#�ǖ����~�V�8,���ë��m@T���~����[b[�C�k񆸓�g38�аR�"T��w���	��OB���h�e��_��ؔ�����u�^tǟp4>/˲Tu���"FhҮ��_3(��������&�o�
�œ����ბ@��t4)�
��K���I�z�B�2��]������V���x�n���x�d��F�vE��Qf��
�	��򫵗���rQ�dw��&0�d��~�.w�pּA�,5���)5�Ha����9M��$�=7M�K��(�1�p�֚,P�<�΂�ƴ�A�}����,F��e������l�6gt��G5��1��^�=e	��z�#�Qr�H��ݳg��NF��]�y]&=�� �In?1�g��4������=��2w�e�m r�"������h��0�O�/{4z��c,��=�Y��hR���VN,��)�����pn)j��A���T�0��Ԕ[������}�P�����;ץ��К��X�B������1)����}��y�E+�Y������yDx� L@6��>=:25W��d:mh���l'fo�p^�P�������d�x�������0e�������FK��-�v��{�;��t�Y^�o	�Hk�};'��Z�|�et�L� �y@�kB\�[�/&!���H��	*Q��8����^�����g��#��Ɩ�2��v!����+D�)<��B����3{H�:�XVwS�NO]�U��+�=�IGc��VF�5����gPv�b�c*,
\�.hF}�	N�.�H�Ɓ�k*5^g �I-̉�08Kr��Y�r����5�A�+��D�7*�9�GF醰*�k�L�ǳ��kz������K��S�~u������H��~�i���ĩ����-�"��<�z�d�#�p�܀�r,9�7���,�l�R�SX�%����h@r���yg�6�(Շ���Gõ������J:;WW�f��@��PY����R��n>���i�⁦��'ȉ�y�����
�!�un�=AQrm�-�
���s�=��t=�W�/�r����N�-���ܢ{j��g��(u:�@�6� аs�l^b;	�xŁ��;c����Fo��k��a���.?�m2�L^�����aB(�uzrRC���^�"b�<΋���Wb�'��O���.`f�l��@�"+�0���NR�b`K��#�yTҽy�l��-�i6
�e�T��b@0���L�E�����
P��L����ƚ���P�Q{s|0��!A�f��YI �$�r�ڈI���r!�}}��3�n�5/�myKO�p�ǹM����G���Q&v�2��W~#藕$�0��M���o+ػ���+�#�M��-��IR��(U?�X66\L|up�"s�~*�(4�4��!l�I�s�O�M�(��-�4�|�SOp���}��'�,���F�<����?��i
��N�U
�7s�Ce��[�d�f}!�sB����En��޼�n�I���[F|`_�b�Y���L0��mV���/r��"�D�1�R3��:�ط%�D�_%v�h����g3��c�]mZ���E�����)ĝ�N_��H��J�][v��x��\e",r#�O�4:f��N'�v����YV�g\�_z�O8N��������r��h�Y}�V>\괾�q���Bip�����ڃ���N���H�H8���v�[�E��ƺ}�Aq/7he֥�Fʲ�5���8	�	:��
�5 ��F�����߮!�K��ap2��!��[>��\.8@��S��h}A�@F��	��WXB����
�7��-)��zQ`�%��t#j����*cѳ[V������.=v�+e�R�P'o�V4�)5����V�VL<�W�'�e��h�[�B���/��DHn,�!?�O��y/�@�`��ѽ\�Ae�m��3]�s�6����c���?� �UR`CtL�dR&x��Ak��7�Hw����6䐾
����j���� WC�%����C�^�����A�u��q %w��5��ȑ�ug��Z��7>I��g> �=R�"���4� L�|�E��	o��_���&Ks����[�>�}{�on�����IY��.��C�4�;x!�W�͕�Hn������:��܋� D@:Y�e%��	Ȑ�U7䤫�&�[�@Yiǘ@9��;Xj����X�����4|T��^��JؤÍ3(o�������D���O�j��u�d�W<�8T�||����fDHŴ��.��w�;�뎲;P~H�d��ࢗ�(jU����[�n��lG�DQIWxߓ��R=��Vg@@]�0�7Ы��K��Ќ�  y��d�x��}���K싾ICe�,a��u�Mϩ�B�KQtWA}�'��1c�N����0�"������vz�Z��˖?44Z-Z�[3�X�e���y����v(��>��`��}���4��B"���e���]Aeq�D�C�^���t�9R}����(��Q��ro~�D�����
�3l�Jc����V���b �|�l��Sw�c�c���':8ܚ���[�C"����<���ҡ�H�Уz��(R�K��Rv��l?�^q ��s@�ٛ\(��x�')4 �ޥ����y���v(�)�#�{�%��I���t����%>]Zl�k4�g��&�Tyh�Zv����ݢĵ�A=�K,�E�U��q�E(��2�������C
��a��oDf��D�&�#iI[}áH�3�9��,ͱ-vv��h�{�I��XA@���/Q�9e����-��
-�Ɗ��3�xa���?�E%��6o�1�J�hJ��^���>O��C���X�٠�6q���xN���y���!���m�KS������	�vк�	JD��M�{Ҡi|�%�j[�.��?5�N����p���[����*J��R�����3�Z\�&���2մ'����>땨���{A�\����:"
�C��-V@J��^V�e���4�N��I��e����=
��F=��LJ��<�����A������)|K�N��x�������?�T��v��F��M�a�J���Tg
 4��k���(�/,�7�ݐ��i#�t�N�����Ц�>�� TJ�GȬ*l����A�58n;�|6ވ�i����a����z���go[���t���d9���q��4�O�Iq,q7`��o��{ޅ~~��-��/��[N�����Tp�9\��#��ކ`��F�OV��G޴���U����ƻ�����O�,�EŰR��H�ld^Ъ�fH �)S9K��3WS>����Z�>o�r,�(CێhȰ^%��m}�>\���*(��u����y�Q�Q2�l�Xs�rH*V��"޼�4�3�P�#�[�A�i�����@�gq��+2(S�(�	��u�8���i��?,p<|���0(e�
�.�Vα�+%x������AMD���B`��Z�8qÕ!��o�c���C\�}ӆ��O{����\��Ƣ��aJ����2���w�M|�>�s�͡snHuP���V��7������/S�YP��I5�E��Z2��!M�s�}U��m�5�Qy웂��8��h	����ѯ���TT�������@�
1'
n28ڎ�*���N��%��z�M+��t:l�U����!c��o~�+o�~�&��@~c�e�$�1���]]K	����:��_b)�w��I��V��rPN���Q�n��ֺ����b "��H�-��9�倔P��b��p�tl�&|R����=n�z7�[��j`9���l��QѤ>h���4'�V��т�UR={c�̛}0 ���\����_J3	�91��`��p�^������6����8GP��Ǔ�>��D3��{�Ū5I�(I*֢�x��`!)x��qI�V4KQ�;�6���Mi��\�%�?pzd������_%o�tv���]V�m�����˱�_kq^���%%;7��6ˆDF��f�����H.��JqbTjM�x��'Z/�}�+:���MsG����J`������ҋLo"1���u� �}�#��9�z���n���K�����V����h$B��kγ�M-*XЎݒ��̑���w��)��p�,���;�e.]!�9s�C�ZN�O�ŷ;ɨ䀥���y�.Q�n�j�&2��j���%�۲�A&Q5��N}v�tE�-�T�	��n�9FQ���D��'�g�bG�j%Z|�z���a�>�E,#������ք�]*� ~XO�͋��)#�?)�5V��P�3N���%��� �ι�݌����8X���S����9ߵ)�SP�T���<�$kd �GƎ���9�)�'j.��U�=~z��O��9ǩ.埿X�˟¯��-Gk�����X	�n"�Nl��
�ǩ�e��R�#��>��t������{)�L��n8@K�.�B���վ��ж��t\��.@��H4���aٍ;���'i{)4kH����P���>-�љ7g�S�l�,m��o``㷄bBI���	O�
g_Z�Ȇ1܂M�7��إɞ>M9�L;����Ő����S�+l~N?J�0�U����h,}� 	����N�uC��A$��м�����!~���z����L�4ޱ��|�;/�3��Xr���d4���TZ��M�%�:p�oסDЃ�s��=�^S�6嫵�2)= (*J����x���A�:TZ������D�?cL��C$��9m���j��R6Ϙs�n�8ww>0.X��٤�a���� PX��x����Iݜ��VU�.�m�#�`��"�O<�X��t��z�S066<��PG!W��Gj�m�;�uY��/��F+���;_lt�',�/��l�^�jQ�����qֽ#�)�
t{�sï�L����j�Ù*Nؤa����k���*�0��3�i���2����B��@���r���9{P���v*�fAUa�6͚�fk� ��/�"��-��>���P���v��o'"�kMB��da�7���$M9I�Ц>c��P_�VU���u?�fH;�%�4!R�0������������M�dK�x%��XWt�c�Ћ����k���u����ܗ����ŦNo�+����Q'3
�3��� �o�/W��o��E@v�=\Y�D%W� 3��h��k��f�a\��ƻ��1�r��ZQO��Y�\7�\����Qr��p�l�Bh���qc�Zc�𮤖�g�<2��T�o�m*+�a�y�+�����<�#����a}��C����rl��RM��d݋�d.�}�qΑ���]*�O���r.�ph�)������b��X��SdB�!'^���$n�d�n�Hublf��v2�:���`�i��L�jŕ��hC��In�fnz�)���#��yL�~т��_5�����pg�uy�_f��i�����M���}/��pNx>5g�=�)z=P����u���>��v��ޗ���ܫ����Bh�aX��Gavv�&gת�ɯ>Ɓ#+�������jB��!�fx~b�< ~.G֪}���?��C��z�G�3N��}�� �S�Ųf[�J�T�-��{����<��8yd}x�h�qw4!�m�^�>ϖ���2-5�(�;Ƀ���PU�d��\=g/25������/�qjk��(�y�{��i�z�c�g��a6�+��� r�4m�Ͷ�t�����_sX��eRW����<T�ு YB����@O�.�濉���o_29�},�p1��M ��K�|VuxkSPl�D�s|M+�q�#��y�x�����X�:cy	dQ<aVd����ɀ�m5���iD�cc3�� �����*]@ÙB4�
9?;ﰞY}0����&"�Y������|�M*�����+խ|��/l_l����Dq������W��F��!��W�z�$t~}�f~��U�ۀEڪo9�k�� X��aԙ?O~��d�J��)#QQ7�r���A-�$�վ�L�����5��5}��j{#�L.�æfi�dі���"��WrC�+�8S��I����� �K���(#/w(�scr�ry�>�]�x��nɜ:��)$X:v:�� Ju���3��ng��1
�s�?��
q� E�vsb�L/y�F�g�{+����� ١�p@zm����b׾?�Sa䓍����v��FA�"�.|�8��[����]-�vH8CgdA�f��*؁�
�ՠ�?�>�qN�f��6��4g)�$W���kq
SP �uk��m�JC�]K��^8�#�y��n�ǳ�	�M�.�1-������#P��: ���L�>�v�\�FM��Xqj�zc92u�UF�SS��Y��(�X��%y����f�6��.rt�G�:���VO�`�D��F�J�^>�^����п��}���|c��L,5�2���~�Y��=2\�Ҽ�]釂4��ϯ~���Β�����m"%(?����)n�����)z�!�Ro�m��q�r����Jo�0�+|�Ô�b���䧱ǅa}�t��I���8E�3�?䤂��O(�ֳ�7bQ�,2
��U���jmx�}��^��`zw;ϻ�|;%�&re�?UA'm^r���ofQ	Dd�k�|��s"'�7���?�]��U�T��AQ�g���%rR��f~Nt �Z��p\h�fC�.�xFL�$�v�WG� �ۭ;{#�0[�W�$L��	��b�^y��'G�c!��FM�4g���	;v���gm��Q�G�Q3Jl+#���r[+�X�=���P�7��E�:�`L�k��M�6;�ueB�:-X��9 �`2�P^����4����`ⷍgɘ�%��qwV�< C=�ZpM�:\ԡ��)��_ȼ`���l�Ye�9y��+�!篢&Tz�rx�TtjD'��6m)z�X�TI|�A��l��dKF`?�9w7�*!syƓ��H��R�:�7�Q=\�~�eg��Tjz;!)��ԍ������x����>�0�_���@��'�d��mڋ)��X�Y�
��{=�h�	GbA�U��Y��E�jT9:*[�t/)1E`��{��Ts8��"~@v��#c������x��46/:LU��U������
���Y�`T�:���=�03�Kc-����)x{/NC,�J#��ۧ�lX˙�&T\�PZC�ԣ��k��I�S�-�yds������n�+�@�3aY�c�|!�e�Jx���U�O�����Z@6Y��:�}���=w��~���\2�zb�����~4��!���ʠ2�E���iE��?8�~]���������p�U{ųV��°��),��J����_�v��63ә��1����[��VI�n(7��V���¬n�{mm����K�Z0�?g�1}JBִ͒� �j����p�t-*^T��{ǹ#���pې�~�c�?]{�K	�y��1�ң�h�J����Р��"���f�q������&[�i-��K�d��箫����90h�������<���^���L�>��l�}g^��+�2o���,�E�����Y}�\cu�ym3�޶k❊���Kav���b?no�-��W���NGo�����p㞘��aB�+]7MR}@�1 u���equޛ¼�`�Q@zx�>bD�䗧�Lf~�cG�f�T�l�V���������2&KWm���
�!�b���x�df�"�܃:B��!ʭ��-���V=vZ!�:��YƬ2�Êz���Ģ؍��'�e#va>��#��}���L�}4�F�q�'�[��tr����Rka2	l�E1���`fw0���5�[�w�ũ��{;eF������5w��a�_d,�7�����O��i1[()[x9�><a:Ѻ�>~B4N[�*��n}�N��D-�8^�����	�}V��n��.-��S)B����dװ�Y��g���TZ���f$�C���x���N�C���k����Yf�D-@�C�.;��S;��d���;Z��.f�SYH�Ѓn��9�s��TI�+ ����4��ӳ�~��8�����)�;r������\4��_R�1�,�T
h� �$�oY��
}ǻ��k21���
�n��S�q**�����U��{�O�����Kg��������J�9h��E91�xqk���g���~�9�nCײ�e��g:���s�t���Ϙ=O��EIm�^�Wȑ��T(����c�5m�@���z���͠u<T���^`eVA�I��G������u e��^D�xgf����4A�`Ūr�/1�wx���oׄp���LP{��+W��r[r |d�yQ���?��UQ�\UK��y�Ҹ�4��6"�\����Ҷ⛍�.��l!�Ҽ9E�l`AzJ��D�̽�V��������_������&#b�P�av��_���D))W��R��:3�S��0�:�S��Ƀ�3���4���d�f�?L�IL��Ʃ�]s^��¡]��4�n�vLm�1!F�����w���}�Ag�c� �P3��6S�PW��W O.c�|s��k�UHgH��V�\�{�d�B�>�T*��7��[ЌE�7x��M���X���qF�$����ݎ�?������; �+�J��N>QYVp��Q��\.���Ofw8����E�,N F
��BCִ+�I�ik%$��w��&����8"�{��)z({�����a4�I�bhc�\����tת t�&�L���T}ǒԽzV׶9BIc�O���\�onO8����:�fT���6�>� Mo�����^в���咿ˠ*�+lQUD�'O1�#��3|���m5X����~p(�Ć,�� 7
l�H�V

:���|�n�*t޷D��|�`�+�~�f�pT�h�8�3�Y-��1{�gĐf�q�����qf.��M�	}���i ���prh8�*e��OQ#xe%�4�i���D�R��9��8>��p���0��]p��Ԋ�����5�rMgWo!�Lg!�v�*
"�jT���hd��y�i%#@�qw︆���V0Q�Gi����rx�l�MXY2�E]����|���茂�1 ݖtb�� 3���-��r�g)�-Q�^
�����Q"�.z�ۛ��"�7�'-5��j�'�B6�/fC���y�,�@���?0XbƗ�eQ�b�n6jk��,�cn��'Iޫ<�l^7.˸]�GBf.�q�M���l��j�g�蛟�Dk�#V|����H    9u��X	ո �����p����g�    YZ