#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1536686250"
MD5="79c82b08c1beaa231565fa3082b1e72d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26292"
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
	echo Date of packaging: Thu Feb 10 18:10:37 -03 2022
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
�7zXZ  �ִF !   �X���fq] �}��1Dd]����P�t�D��f-I
�/n\V��.��U�y���|p0,�lхh��P?cҽ�s}FMr��PЙ>�?��Ɠ^��^��:Hk:@8��t�?�^U�<[%���S[����F-�K�����s��k��a�y�D@���O`�ZV�;�9U���+��C\P�O��l�� _�t��VqϢ���T?�i�S�b��#��}_/2�C;�s"�r���cD���[z�h$|�������MY���<��j+���\39��d=�M==F���r�8M�o�^;a��=?�C�qeu�cq�z1��,�X�����jTd"��NS����/���q����{�1y	b��#\�.���gh,�J3qU���ƥ��18		�~��"��|�@㒷���'h�]t�{z�*W���KԈ~�_���TX���R��F��r�ۘ29Z͸��A1�W'�^3T�9�q��G��iJ� 3M�a|�*=)B��Fzw�x�.#����0��CVSa�Fw�q�'@.�qu���`-1Z�����4�BX��Y5'��(���"��l+l�k��_�@���^���K�g*�����N�d �Xw�C�M���!)�EQ,|�d�:�F���Q��޵V��;=��Њ��r�v�֤!����M�x���5 xm����k��
����X81�[呎:��:q��Q�H��6Cir��	�C�)�l��&p*��>�HN��hv��/}� �cVa�x�����%'���HAy��`K�o�~ӌ�(��[5�g�G}�?x��s�,���Т6oHZ���{�$�r�J�aG����~ ���f���8�W���l��%J~�:_�f�[ˑ��l�M��7Da3�V��!�		\r8��&�c���c����:2�*�\�'�#�pz3�?Z�k?ԋtj��}',��Ԡ�>"��f��������.�	޷Oa��"�b3]l����@[�lY��uc��+H6�������w
�ݺ�4mm��0�/,�z����:�c-��w�d����ń16���2B�{ [yT�m���8��1 ̚��T���Q�t��B/�'h��}'o7�4ܮ)�t�G���#�dA="�U����j9����<����3�0"j2�#SWA����S�1����۽�9z{/]4ݰJlK&�"N-�=����2<z��tU��`��,Roc���p�n>�(����"����Vs��Bu�wx��d�!_g�Br}�9!�	�0�*05emCL�~��x�+��c]�-�
�H�p.~�4WFe�@[�0^�UQֽ�e�����j��(_	ۍ�`P��d
_�뫪�p�s��
��)�aXϛ���./��W��=DW?���`��d�vZ���3�����X�͓c�G�H�<n�E�ҍ	\A|������>{G������RǊ��IE�:o���+ue�;W �T�s��m뇏�%�>�2�]�9�q�S�I�q7|�g#4��%��o�&��(�cĨ���Ęc�Y�U!��m�r�US���p�Ql��UuB�ºҲL�<Q3����D8(���ZYشfF<Dɠ��2�V��[ϐ����X�9L��2/�JW�����/�+3h�cO��J�!5hۏ�E��������2��	~��	�� �	"�/���1у�h	�kkt�e>�٩�ߪ��7�9M�_�Hj7�x�� ���t#xM��H��`}uG��t�������S���@ � �-�Q�M�N�TU���м_���7:V�w)��٫��
m������L�*"|��RR�H�t2A9^��;�,�zЫI9H(�:�{d�!EWG���zɨ�^5 \����)K����_���G��$	>�d`��ɬ��0��\:�ؑ��w�iK�F�D�T���TC�ɾ���P-6�}�F�H�%Jݚ=��sZ��T�ó�F+L/N#\�dJH'�����]jmR;�E�Y'�S���
U���bSh���se�"��4UJ��Hg{���ٹں�/�$�����A�$:��L��$�*{ȿ{�_@VE�>��t�Y��Nu<P�ڹr��b�iu3+�Q�4��w,ȼ�1����aH��_�gc�=�Ů��qRt?g~�@�α���N�V�%�V�9�`�U���)�T��!j���r�\���\K��+�����\yFY����A�?oz� ���a,R�Y&�՗��
��`����0��Mo��h�+�TVo�ܰ\T�]����c⧆��$2Y�;~v56'0*O��0����K�I2a��>F/x�H�zS�l!�W���yQ�i�Mp|
��������-1+�.I�����{��]��c�pWf *!�	�m/�^��ړ>f����p���9�ń�N(й��e���ם��%}h�
C�w@,�:n�]�r������v�Ӕ���~����;�	T��3��x��͌K��$��
�y�6 e�����ϧ|��p��,:�JV/��]��5�<�����-����D��I3H{����[g�WeK< x!�xT?]����6V~E�/�"<[Y�q���}����Ւ4�`��IU��pR��z���<�Q��\����!�E���U��H_���˺���3��o��u��/*�����ud�Xly��,�Yc��´6w`���n�G�<D���PNYL@��:����rc w��\�aSG����ЍK���x�j����^hMe�x��C�%��{���+=�pnSY���{�2�,�km����*Q�����q,�KO�Όk��� 9aZ9!��hѿ븾9t��ґ�:����;1ep�-wW>)k:U~셤�)�kXa;�O��J.��З�\tKڗ�l�+	�ڨ�v��'�W������0�`�T���`����A}n"���訜�}�y�P�y�����D���-�9L|[����.i_VTvɧ�Q/�O������+�bn�^�%({�)�8Cc�䆎�	�ٰ��J��bO�W���H�j�0�d�'|.I�E�]_���#�ڙogԘ�߾<�p~&��XG�/jpW�����:�)��@�`������ɣ��4���9]��*���5���)iNZo��'=�C�A�]��$�+�I�eC���0Hmـ&{fN�U��|�)��HN�Oan���
�y�Bto5!c�k2E�r+������鏽6�4��>��ټ<�:�h�G�������l�����o@h�j��9����ױ96���[���EK���9�pB�L�Ԃd'U����@��7�j� ��xE29,v����e�׋�z�_�vE�ӗ�X��4�s��a�ȧ2Z ET2s$R�K3g/���vˉ��:�u\����L��X�V��]&�ϒZ
x�c�)Mf�O���v����z���4�3�D���I}�p8����pM����_BIHgo�>g8�����ډb7�@>�e�y�V�Z�pZ�Śb�4��D7qz5��>��ӆ����
�'�#��Ojt]Hg��q��G���e���Q΁�me��#|�:���jE/"�yϙ�d�h�j[�ᷤ���c�� �U�ݴ�7ztڄ*�)w��f��֕=&﫧\mj�<+�6�sD����v>���`�~���<v1Jf�K�\��,{p�z�>�(y��*��&qQBtK��X��5�\"� �=˴H/��QK^�ϯ��=>t�_�����J�&ذ��!�h�<<�YռS����R���{@�&��૲eٙ����ʮ����	���7 4t������uH�E�w���2͚�������%�.8B�I���&�'��	TY6j�P��f�L�U�P�������?z��A0j��x5���^�&Jl����Xt�Y~���;*l|�����e�q?8��>rc�v�K����uN�L��W�2,�]��u�ȗ��\�@-�|0��pष�Ͼ'!��/�.z49!�'2�#j��}I-k��мds�����P�'��
5	ՠ�U�<�4E�v��5;��%s#�~8��G�s��v�]���q����5A�ǲ��dh%�1r�#�n��)�;�*���ލ��cD�#������/�>��&�� 4J�1�7���B��8��GJI�.��n�)S8�2���A΄���;>x���1ԝ��L9ԓ�?X1&����K�����`D��ߕy��grb��T{YI�y�d��
�KH+�9I�Tא�zCׁ\��᜹m%(a��z�Td&�sG&�+��~��1�^w��#6?�vn��1׻�+��?��H��W�EU��jq4:��*`X��MM#���?�(��\��[6�ȟ^!�0W��^�X�yk�.��S�~ �=ƿt��>�8�m��B���DF�QD��Uj`����xe ��!�1e���Yz��Rs��g޾�_[tp����s
�����'30��GOa�[�7���%$RY<����a��|��:���W�z9����74O���	qT��Ѫ�t�-$�F:���r^<O�M��4��?ב ʧqf�1����`��lQ�f'�Ú�Y��r0�<X�>]��]�{�Z:��G�������N8��c���e�r�����Fl��28G)I��D�Q�	eO5�s�9��u��B[{׆T���T0�U@Y�b��#4�!pc��]�~��G�6`p+�w�n͓�K~V�z���`�{D; �N�^��+_����v���l�##��|E�3Ơ���Q7ey�P�^��@x�O��DY׽4��; ũ\x]���*�R(Zg�b2X �k,P�)T(Z��"�U�S�����"��6W�go���3̝|u����>`�~����G�A`�\y��R��c���u�Y5��-mo���MK��QnE�`�R�w�\�7�	 M��jW��a�v�āˍ64����U�^-"��<FK�F���:�K�]�U�'J�҉5�hd
��f/S f��~˨ٟ����4��͢�j/�$�Ӿ`���*��0���^�l)���s�,V�%���u�h&s������1(&4���%�2!���� (W�2�H�Y���)����9g9��[�dq]��n1:�ۡy(qü����<,��$چ��s��%� qa�v����1�q�锞��0 4o퍦6�~�HцpG��.�Ѽ$���Ż8_{�a.�,��yV�$����g0���h'1��q��C�K[�P`��^}R���Q������>���m�b��rv�`޵o±����b�����M<�X�R�X�������Ќ��x��dl�Y���������8$A��HU%:�cx �Ѱ�>��i��A��{լZW0��K��6l/�,����WD�bTO��r5��,6|>��uN���n���=�Aٴ�0^}�9�NsCc�y���y�1�vցo�A�;JK��FǨ��
�����	;�Y��=�_�1����vG�p���`T�8Ť���v	}�a��e+Xt�8�Y��$FtZ'�m�}�4(��#�M�ah�z@{�@\(�.�v�E��4�^<�Ť<c��M��M��6ǿ�{�Jg����"d��D'�����%t������&�aս�tH~uI"��䙈5U����/m�c�3������`�N-�"�j۬4�M+d�s�;#�h����%���\��8!�KLVÀ����ӆhm�D)��G���vW�O��H��93)ʣz��?�ۨ��X�&��p�~��yh�������� 2	�JЀ�J�h�k)�N]�H��x��z�����=󅣛�,��#�g��}��v��om'�A"����HLl�m��i(��#"���]Pa�O"D�Q,�w����	�)פ�.��ɚ��Y���]�ꌸ}���w^�u�6>��E��l7��u8 6�D1ف�j�*>	|;�2��4B�:x'��#��B��p��� 8�Қ����ʺ�+�i/UR�&�0�Cz��U�"��]!�~!8�N�9��~3��-g�c�'*���i�ǐK��`�%Y�,�g���9Ү��?.3~���K�!�Cm�b��������$E��7��K���P�*>NL���" ���v�������Vp/�S�G�/Xi�� )���Q�|�|��m�x�CyMiN�3Ă�'�p���,�>�z�_$�UK����'>��Z�)R�9d��S��ZB��[s�}�[���a~�ڣO~깉�@�p��w�sK������롂0�P�k�(�<���T ��9��\�X�t�H��(���[7D7�x{��7����4�<�39d��
�:x ��bT7W/+�w%�cIZ�����ڂ�=2�V�O�i��ZZ��g��If�ճ]6��t�;m�,}s�z$c�A-�?�]`̠�y�s��V]��&@�A�|ht(��#7�:�}7Haɏ+)��4C%g�y���z�W<9t��C�q78w��r�;&a�xm�[�o��g�a"X
���W����$��}�����yd��n��B���Ї��]szϞ$�Ǯm���t"�ė5����!���-�pH�ռ�z�횼�����ҘT���S��`$�ҩ���@C�>I�M-T�pF��Q��<��4A�.>=�����Eʮ烽�\���{�{�J�o����Y�֔�<I�{��5]�b���N�-Z���E�W�ِ󬗚`rL:_�Ʉ�	97��N���N.1�h�I������7E�p����W�F"�(#�ܞ\��`6�A��v�
�݈Q�|a�tݝ�Ia��K����E�T,̋�����N�i�b1�
���|}��9Bs��ED �mX)t�������\5�-�k?����[L0⢒G�d1Ҁ��WI�|�2��Bv|���e�t�ANO:��
�����d����/�e ���Ϛ	�w�%���ҙ�h8�G���?���۰H-��KM���e������L�P��jA�=��G��mn��d�Gq��|��G�p�d��@f:!'�s����'�>q�>q;H�����K�XO=O��M��[�.7M���/]\�{r�&��\�L'jv�����4o�����L���B�`D5o^�i�S��b���EQ�F��J0���(昑>-�j7P0 ʒƻy��7?Cr���+h����(����ߙj��-!ѷlZ)$1o\��ѮoV��N#�'(�����UZy-O��K�_HW��6D��ޜ�a� �se>����{�Y+a�m����z4��z���x����ʥ��$���1e��i��]����	�p�S��#��j0@(|O��8f�ކ^||�F.|��<���ksT��z�	'I_��r� >2�ᦖ��JO���ѡ�������w���F�3�����TG�vq���~����f������+4(5�`�_�3#vGm_����q�0��S���� �T�nSC�<�����N�It( dj��z���k�R� V]�DU���6UT�r�8_����FA	�A��(3b}������̈́�ٸv9(�8���fE�z�zq�F�ǫ�A5>6tq �h�����nR,��m����%���y	 �$���V���&��s�	�ׂ[Z��&�ԝ��k���ǰ
�'��T��7�Rǵ�F-��"��:�m�"��<�#�.h�_�y�����U�a|�
	H�o��F0$���g�X/��6���{O	@�3W�@��3Vං�P� ^�h�� ��B,FuE�eh��β���+�~7 <{И�I#�#��*�F�:��O�3Q1��.���O�c%����{�S�&��X̪��i�Fع�Ȼ�(BR�����H��'�#���_t�t��^�+&9c��>Ii������y������l=�_?�X��$���K�Na�8Z�J��`����r�Ψ��������t�a��]�&�R)��:��������]��8 ����O�^T��9+�\�a�S0��le'Qew,Hj�2��{���+�O�Ϭ��0n��F�� ġu��`/����1�>�qx}�5�$L�VC�d!��(M8�,��v[��f%ł8��9m�����W����u7������TN��b�wN���t����%�tʶ�p'�k�Pl���T2$�H��H�5Lw7,qǇ�m�U$��J�kK���g�{ܖHc��،y��(Y�aQŮ�.����%[�Z��PCFӝ��`���>{�yR[މ����� 1��C�:h�D�(��؉�x^��'jTz�h�u��o3m�P˙����v3z�o	��S�eWWd9d��j�k]����)�ȿh����md��y�ų����l�(���, 8�i e@?}ǔ�[+���v�%���޵���_'̥�n���ӕ���B��e��^�:��@?�H�E�QV�`~nwd��1�=���M��	F�s�ONʭ5�g=--6�0�����#�f+?�E��������U0$����y|G0��v�|I7�<cF��8!Q�%��	��\�w0Nֿ?�g��jL��n�՛ݚ��9U] �@C6��}�'�F���,|fj�e�a�ڀ�/+CÊ�� �Arf��
��I���h��>`@��|�����<�\y3�Z|m89�f�f�c��8O��FV���S����K���;[��3	(~�Z��鿈M*��Z�b4��f��҉�2D��J�Xsy��m�+�F���o��G�'����a`UȪx������:�Pe��+"b��2:/�yq�@�H��\S�{�HSDܻ<Yg�$������:�5��G�X��0��yl�Ahu�5�T;�֋�=Ӷ�YO�8l���Q��ȭT���.��;"���g�sHć;B5
8Q��)I,D�(2��>�~;b�ZQ`�͉u����6jH1�T����h���5X��b���M�67�:Ћy��u�j�`�A�^��	��E2e"��{�������C��
S&i���u=��\q� �~��Ab�	�3U�X�Jw{�]�c�����P,����<�k�9ڹgt�H�;�<�9q�]w�9��˘�����z~�� �4��^u����C6N@���#�t�s��~��� ����
�s�\/4q�t&��b�4�wW��}�ܟ�P�國��������n����3K�'f&�~n�������'{8K�?Hx��K:�d����BʘR��S�M���E\�Md�{��̊@�AnoWq����N��۞.?[�ݧwĿ���=���?]l4�V��n��lk%~HzO�G���g�`@�@�c:q�yfj�;� [BD�R�u) ��+��q��(����4�z��}b�\9FӺ�Ag�%�~��;1���-�+#4��Q��j����G�Nb5>��S
��01x)�]/1PC���<2��G�I���#���Z_��+K��P>���j+��2w�};�m$ޭz�U�����v{=;�83`�g��"�p�b"ogw�*�P����T�J������ y�K��H[����㢃�����y�2�$&Ea�,��5ąDv��Ԫ~[�Ltg�R�ף������~�qF��=RƝ&�ғXy�kN�˞�D�Nu�~�v!
��T��'����9�a�z��/~.�r>����bXWO3�}@�gm4$�j���Ĳ`Ṵ ����`$��iYz�]��n��#jR#J��k%!3�G��EU1TIc�����V�`������{#� LUH���uK�CGrL��cW:2��h�P� ���-	�:�^�+^,��$`W^zpACR�vzMUh���B��ŕ�� "(.�x6K=���ju͗����I��k`E���8*��*���$�Ǘ�gA�:6��O1��ˋssj�_�����j���<À�����t�U<�9�&Q�'��Ld�/����/������iՕR>b@N��
��V�$�٢냲�TͰ���K�څ*T�WOE�����D5HuJ\�����u��o�ܚ3_1���

�;n$�6)� b�{��f9B#�j|��:�3ʸZ� �G�.j�d������w�}�
 B�/�&A3���poY�(9_��ݙ�*���6�&TYa��qꦊ�%��%/[z�a��g�M(^%2S��N\X�\ (-��ɿ��֎�V���Ȗ`��-���U?�� ���N��LL�����A�����~[Is�ֺ��mŃ~�'@�鴝�g9J2��~���>w z����lӯ[ơAuy��!jsq��Lmxd�?F_K�ǘ�Z�����Nʙ
������$�.)n EEVOz�v���{A�C�5� 
�4�����t~7�/=�g��?���r�cf��,��l`�N*�A9C�dc���cj|`[t���X�퓎��Ε 짺��%�t�ԤB܄��k/u�� �5K�����"�U	�F���N�������-|@��{7�����m#��YP
�!C�������Y��,���?��u����z�:�F���F�LSIF�/bii��l}3�YS��%&D)(��F��jC
�!�E�FS~̜M4�nT�A_vr���h+qw�0�tg6��j�~w�f!^r3�93E]'pe7]��F����.{��)��1\K, n\�K�ɘ��c��cW[��Z���[��M�- ����Cl_X���<Zc����~�C̜�	4�Hw�O�`t��DPZ
��%U/g(4�"?{�`�#-[��$�/W�#*m��(PX�����a�����0m�nn:�d���t�}�Op]�� (X݆��d1�@��ȧt��(1XF�A��A�H%2�p�4�˘�Lߒ�+���\�Cá*��pU
��ˎ1W�J��!TJ�?�VB����, �Vٮc�K��3��·�?�QS�����P^�YA���V�R[�Z$~��_D$et�^���T�	�׮����T������䔟m��3iȐ.H[�O���T�j���;I�-���i��R ����'�4�X ��+�� ,�nT&�����2�ՙ7���T�j��[!�q�;���ܒ��U3���>�혭���y��N�R��,ظ5Ի/���T�{��0�:T�oY1���tg=�a�C�[Ӫ��}����S�������I�v�<x���Z�$;[�~>O��	�K�D�׮+Hs�7�}�vҲCm�~�? V�a�(�}���C���
���e������r���r�R�HtU��@Zŉ@,=��,O����܇RKC��;?"M���d��l�v��Y��Jʂ�.3(3!Þ�
	�9bx)o��~
�Ĺ㩄����\( ��4-ϯ�`Ta&}�
l�����9���V�?���8U%�+y���E�v��-�Qpbn��
d I��=L�Q���e[bJ�>����9b4g���5��#���a(_;��-Π#��ުO|)xy֔W�_G� 3��'F)F3�~�v��|�l>�T��tQOa>�����m�BJE���hv~���0~z��E�9�����*�F�A$�*���虽��MS�4T��ܥX�qYGW����p����CڧV
�8��3$��u��@�a���\{�V���i2P}���d�Bǡ���1,/$c�Do�D.:������ވ��Ku�����[2���n����s����ԥ��ZK�Z�s��xs[*B��r�PTP������S��ǡmg	3.����UU�܅�j��̅4�L�b|�^϶�q� ����0�H���C���*���X幇B��\������8p���N�Q�`*y��9�L��`O��4�pw@b�K<J/= �qXF-�Vbh&tcW'�/�'�t��ٟ�.�>xCE�8�l����oᑑԡ���kЮ�i3�`aJ?��� B�W���59�4�p���L���.�cŦ�@Ӷ#&�Bl�G�b{\�1J���t~ՠ�nT`b�\m>άd�/�*9����'�Gd�9��~{LTF�vB�jj�m����@1�����X ��W Q�m�2E~!ŭ��R+�Z��r�F�OVi�����\��/�XlLf�wGO��+�\lT��]HM�O�c���)��0�6-���� r�Is[���X�U��v*B�䤃���j?����OER'��i\ C��ל"��`��)y��YH�a@S�_�����Q׻1!�����(���$�A:���%�T֥�&�'�7^VE@�^N��gh͎c���xxRk}����N� Nr�֝��y`o'm��� ����q�r��Z{�}�������W��r�����r0�^g��ՇT� ܏ͦ����@��1��fi�N����4�;!�a�xTa"�Hy	�V�l����y�	��ʠe�NQ$�ߤu3x9P��sm��a_ +W劊�5���0o��pb/���T�H�y�8>�'qXK�?�#��b���j���I޹ʝ��lи�ϡj*��1�H��ZS�<l���t>8Vdf��]Ǧ��X1Et|?O�l�/���noF�;�� !M�h�5�k�����)Z�_��k�U\�"#�m���$|��2{K�L�eqF:0�O�������X��]{�D���ub��u�����GHF��էՏE-�jo�]s<�6-��Хf�D�{J;>5ʋ�0�ԑ����^G�.N��%���R���@.��&��_"�OT~�Sd�C���\4q��Auw;~�B�坪/4r�p���eX[CQ#}	�^|SeG3HbJ�B��"��z�gYbBe4շ���Gϟ�L$&����D�r1c��� �R�	�9��
�ꇏ��9�am�j�2�l�<�=�F"�5���=	T�>�c�r���.���;�.iW���Y*�$�v�A�j9��	k��2?�0J�أ=���	�f��C�&8(��^�}6�^�.�����Y,V�˕'�+����I�Ke��u�I��^J��f!�`ewe1�>�у��`�T~J��F����"�>۵B
B�����7��N��,c������#U�x��گn,d�i�NM��lՄkO^t�� )�^�)�<`���=5��{~���.� ў�\���o�Չ�z�UmH����>0���s�~ �{,�o-ךf�z���}��%]�U��[���}H	��Y��uK��?:v�5������g�/��ʍ'Ev)��iaG� OvA��;��+��g�%��%�7(�6I����8e��6�x��J�t�F�k�G���;�ȗ���nFT����:?�W�B�C�H)d��~�w�
���y9��
k�O�q;Q�!���DwsТ�{"�Ld �E��]�0t���/�S��.U�	�ɶ�"XG&tfl�]e;[���F�gJ����3^p�MW\G���ٷwʉ����4H��8n�����v܄�ٷ��/�_�|@E�
f-Wl��P貟�JWCVj��:A�V����P9��F������A t*(�r_$j1�/#|Do�I��:�(��]�x}
º��.����mWs���2�e����kZ[�*E�\�)�5і7�ۛD
�F�nm���Ɓ$�,��/�G�.��` ��C<24�3A����,K�E�F�s%��-��	ǏM�,0t-���Ѿ,���@,�@f3��3�Z|_�$��Ciރ��;HH�P�̯,�՝�m&����er��A���j��y����5�@�*!y�H�n}�L�}l���7A:B���01��f�9�O(�ʊ�#�Wq�[eO\���qn�˜��c>��ww���_����r�$_g�
ߣ�7��c���(T����f��7T~+=}�L�}�.�g�V���}� �-SKM{�_S�-�է(��+&��:��髫�����;���;`�;�ԇ(���Q���ΰU�V�Th�u����Ch����L��}ݗ�r<12lr�Jlme�_�nvPE�ځs�g�K����_}����u���7��k�/ŭ�}`�G@ç����P���G��X{^�dٛDJc-���)t�6V�`o������E���1����B��w�3��� �
��j��A:��9�G���cELGB�f>�_M����?{��Z@U�LL�h�"�d��F��uǬf���A�h#�jg���6轩6�2S�0�����9�u��\O[#��t�ST54^6y����u�D;�X|d���������!�=��]�<e����ߥ�z���z.q�E'sq��˞��>j᯦ 0"u�����hՔ����A.�"i���P^�@����q�5���!���]���t���Qzo�Xbc%-����FF���HG�������*�+�uR�7���f��uÇ��g.��[�p3q�X�Yv\����!�j��!�Ow�����G�́ln���gb\ϦDsz�I���
\g��A��/�{c�°r�1����È���]��CMu�&�Ǳg	�Y���ך>���D�)}ݖRY����|�Ŭvz����ܔ�1�J����	
T�RYە���`��E4ƶ�R?k���>n��D,����|@�?���5�ǈ�d���G���0᱂�W���k�@ػ��K��AQ���x��R��3��Y��8e�;E�V"kKo��P��F/���{r�&����;@��޼���XK���Q[H���݊l+��/��uo��U-��z�4�����ƥA�M�"�Kӭ3G'�9�ժ�u�J{��|6��:i���ϙ5I����d`��aM�!n��X�β�H��|EK�`��>��?������a��D-��Q��G_R�y��jQ����b��F���2E��
-�'���U��Ar�W'���R+��[�X�I-i)�F��N�}o�>D�L�$�"v��H���{��@��&sV�����Z�U����y�Z��WUrTn�V�����1�3[��<�$��j�g�?���(���-��H���Ս�O�+x{^�oD[���@~�Q"j(��׷~�z]ڕ�e��?�F��34Ö�����jJ��H����؃��0�z�c�	m�E�uT�ҭ���#�#m��Y^���"4V�ٖ]N�A7FZ�	��!е���.&����c�	1h�o���g.Z�D�)L��.}^��c��> �*�(�FgW"{��z�W��Ќ�]JQJ�=�h�����o)Vތ/���B����[p�jc$��$��b���g�� ��g���xP��#���i[�ظ����v���Uķ�~�\��4�is}����1���qd�!�Sjh��?V�t��o�q�A.A>"��B5�++f�L�=��w�ZS'���7�`��;�,t�"�]gw�ُq	��;VǠ�N�{�+������0�\�Ϝ~��A���/OKFUQ���ʊk��� H�������Cl ��s:;�J���mI��y�áי�gF�[�T,/��B�,��g�Zy����T��9@5|��:�V�ƨ!L�/�U��H.I�'\Q@��z���__"!1]I%��Q�'��C�z�AA��au�oL���G2&2	D�Yp�����*��mpp����~���.-B �6ˮ�V8P�ʭ�3=�<؏ t��K뎸�w��蒃��B���50�,x8�|i�I���(��Ϩ*gWJ��xtA`
B;�8��4I���ȋ��2uYԄ�^iV9�N�%W?0��,�,X�$̦{�3B����8N������i��9k�ϊG�4Od�,,Q���Ru�D��x�yg��6��1j�!�z�mB޳�.��|ֿ�;Bg�|�$�$�"��Ղ�ѡT�맑�L��w-V�*5�`4�3ڌ�N�.�؉сTDG��I���<]%���`:G����6@D�)x�#t �K�b) �Aˮ�s2��ɤ�$_������_iꎾ�3�\�$<�S��w�Ї&ei<$�r�)iz��m;wJ?K+P�a�7����4T#<ջ����� "�w!i�,_1RW���V\���+��ܽ��~��ڛ� ����]T%ǵ�`�й$��;�p��������y���y��ŗ�pR��,�¨+	3L���&J�9�����6,K��ҿ!W���:�>|C���>���<-���o���1]7T#�;o�ρ>�vȁ#dq�r˽�T2�l�q�:�
m�,��QL��W����rT�I�m�~�7�}�����R�K������"��,W������W�m`��1��	r�CEKx�~ ��/<����i~e±ʩ6P.�5g[0W��]��}�(��m�`�#L�9����L��n��Gq�W5�r����.S]�R�5�Y�g�L�3��F[��u� ���]���ۊgLm��0i��b�'�޻�S.��ܐ�N\ y��D땧hGte�/�Oh��vt?ס�~h�m.�U:�S�����_�dZ�h=�'�F�r2�w�Z ���94�z7�
'wl�"�����i$�e�@k);Zk���0Qj�(:~����)!)�^wҺ�;�K�4�! ��3u{Zm9�\u��x��Q�//����Hj��U����`���nA�mG�.jV+7�U~�y�����Zv���������k9��m�i�P���7u��x-���
AT��6�ݺ���ߝô�����d-fv?���'䷝�ȇ�ÿ#0�wa��6��[�0�P�)�V;޵y'E{D1�����5�n7��x�-�$Ыc�aN�����o�VyGJ)	�?2���;���j��?{�.�º�.ONb��iy R��.�/�Yu�̣�&�*��A~p����8G{ΟZ,y��-O��y�_��2��A�3DX-���1���ħԿ]�cUN��qH��JPvo{8�K��Jz5>��v�?�0lX�fg7�9�ϼNz�#�:FBiȌV鹆���Q����T�p��Y��[�Wp�<��ܟS1mA�'�Y>�:�\>�~�TA84q��f�oA������ODr⼝V'%�ZG��OO;$D_��,.+�,��\Y,j��_�؎3���j��1�Ng�҈���H����l����И�O�� �
�2I�Ψ8�,�%�Gݝ�4��x>�B�>S�hע��W3L��mw�79�s v����y��%��w\���j� �ͮQ|F�\��բ�|7�ϓ���ȸ�Z�z�@I��D��r�i4#衩Q�x��D���	�Ǿr����'q�9�6*D��������~������,�x��Z+�����N����Yw�CaЙŁ�;��eDId�×���Q��ƌ�	$�}&$�v�����Ү	�K����aΥ\:F��I��8�3eLP��\�l&��G��meھm5��Ǿt�(�`t�w^m�}�N�����O��C�pvLj���7#v�/ݩdYz�m��#	r �0S`p��D��pUI_;����9�B����ͩ_�&}/�k�cj���ߛ]�m�a�װI�M�N6Y�tVv���נsz��5�ϡ��0:�١+<�~Q�t�XH��s�h�N5e̗82���� Wm��ˊ�y����Ш�h�
/e6UQR��U]�Y���~�X�~*��(�x^���i{fr�e>x�X|'��kR�d=�?b��I�,�چX�k���y�حy.��6��� ��61>ti �ʤ��Wa�@s�(�6�f�L��$�)��0��rRj�����0���1-����|߽B����'�t����}�¡�*��lK0��c~^ʁ�j���EPN<7%)C��=�t󀅴�M�!K���Q}1�j���t�Ͱi ����^�|8l������rm>�o�􎁃Yڒj���&���ay�O��6��/6���֢`<�<��SSo��H��/��	{ŽG�X�e�~�.�'�Ѷ���1&a��8^�Ք�?�o�!!ԯ��=F(0�x(�C/��7�X��%)3&�:B���u&/M�_��r��H5B�i�Kl��iwhU��\��]
���_�@����
C=ږ����R}�#{�xw�p}.�v�{��80-��f�h��ͥ����^[�٨1ξ�����1]J?.suw�MtmG'�Ǧ�=�g��p),÷����O(�pK��B*+��p!�8���g�U�t��� ��0�H��U(j
ա�s)����Gw௰}��>O���8Y��~��un_�tF:���� FH:jxa���nE��$`%Ƥ'�1#O��X��"�n��\���G8�x]f����['Jqg2�a^�՛Qr�/�5���&r~��z(��� ,�O@�{��o�X��ko��;#�����B�f�mG����1C�g��ϼ�!L�ny�����$K��� nlK��<s1���M?���}�W�����DW3��0c�B�&��>7 ��P�y-�Mr��W�@������3�n`D����):��S��+��3�뽰u0��{Lʇ�֫DH�����C�GO�.�6�>Y5, ���"9m�by�3�P�>Y	1'�A]���:�����HJk�l���uSم����L���>���dd�;+����f�S�G@ɒ(>�U���U�+ �+�5���֩Z�sX¹YV�N��6� .�NǤ+5T�&���"
b�ӈ���+����̈�� QA�vO�	�w���l�z���w ���_��v�mB�q�&$�����C�tp��
V�-c���j�Q['x�r�5R�+�G�``��c;�@��E�/�~�1%��(�=I�B��.k�5N�j=a�f٩
���<e��a�.�	ԙN~H��\��Nb��Kh/'����0ҽe� �atT��������� �6\��%����h�he�U�|���)˺�1�f[�:�LEҋ5�1�*�����&��P��b�m�3�W��n�*���eB�T�p�Pt2�	�S�-JX7-�i�'�W�s̾5���6�ڡ���3 Ml�H��!hB��luf&¼�s,O��S �~pT�L�iU8�+�V����46׀�fIKOcS���.kI�)ۄy����;T$�?���r�(&}�}��]�4K���9�_�$�q�/6XJ��1<�7��.��;o�5��I�p�?������5������!P�_�C\���%����x������jY�{i=RLp�R��^#Wn��|j�ǌ���1P�E�����T��P뿌üLT���g >�(�D6g	��L�';uUm&���;�[���yy�	 ��oyy����[���� �H(��u�PS�X��p�Ώ�o�x��f��m��H���B�(�V��EyX@�c0^n� ^iP��PX�ma*G�����e�M��Ǩ8ʈ�Qu�J��B�z�;W����>��+D�R���Ͱ"�e}�F�G�ijdR`�7M�V�o��j�������t�hy�f�o�Ѥ|��z�:z(@�˚t�[<G�F:E���T�O��"/ی@���R���_�č�`C�����(l݂ ��뢢~v7����X�w�
���B�-C��#�	׫��_��/��d����jz�,q�E�Hr"@�;�J����sxk6m�vi#-��Kt���eM�z�u��I�w��p1�����3-Nf��z��[��m�j֮~2X�K0;$���E�wl;DC��4.xU�DXscEFT����ؔ��j�j��Tg�+W��o�2C~�ְF��i��&!��k.�9�Z��Z]�Gy͋��'��m��Шi�0׋Y�q�OdV��x�|�Gڢ���m�X��b�T�ca�2��w܍�7���݁���Hȯ&4��<�[�J�޷�Č�'g*��7�,�llJ��<.4̆z��|*��%�6�?�+i>����0A�F	%T�>�.(}���V�Y�ә�m��h����`Z��D�h���Ԥ�W.F���6gUl,o�K�F�yܳz��~]	ȏu;\��R�y��U=�~�"`�#�h��u������==�`רGW
̃��̮=*�xoy�����;U�=��)��H��=����(R������C=�%E�w��	^bv,"�m�>�6�����_mp�'�Ri���O���r��c
@Q�[�JF��%Fa.}E`�7��S�*7���k=V��Qh�
��<��~�]��P�N���ə�����ꙧ�S�e�l+��
[qC���D��IP!�S�U�rq�����n9Yi-�U���ں?8����6r���� &�XX.v�����ʁcȕ�\�tHO5�b��5�q�47*<m ����b�<v��b}�vkS���b���j�K�nG��=�j��WUgMN�y�@-��=�}�����T�y�{gcjq�MD��K�ctu�9-�*��Ns���4����1@���@XVXK��0S,��Es�ٻ5���C����A͊`��o��p����� ���9����2��>��-x��+�z�Zu	�������Jd,˕�D/��w���('�8�TYuC�ޘ���3W�����/�D����hNc�X��0R�n��T��\��o��C0�f�����y�U_K l�C��Iu��o���T��Ė�˼�Z���f@Irwi�{h��u0��21'���X��	sc�W�ЗŪ+�WsO��VҲ��G��:�����.L��7�q��a�Z8���,�mp8B;�ѳ��F.2	-3
^Ko�=�2�w��t�2�L�	�be�����4����l�Y(s@��$�T3J޼�u�a{�Lz�;�bP7����q���3� �k���:a��7������*��!6@�
�W�+Ӱ������;�`r��oW0A:<��F��B��f6e�ϭd=��$�K|l����y,����RUǋ���=��������!�L�ٰce��c�=O��s���\��%�ʷZ���HJ���n�E,���w>�n�{y�����p5��
k(:4�����/N����2|��3A��[�\���`Zz���L)��X]�'����[������m؆/���P#=��;r��^OZ"moO��ja	xijZ�������ot���}� #y�g�T�l��e4��4��%$�^���E��z ����;��z����8�{�-���Jg���T�Aa{j�� ��(/X/���P����ϥҾ{�$N�t�+p�4�@��j�gI��nְTѸ�B� &L�Y����D���'R�r����b������;ѾA���nRN��u�3Upn�E�<:�N����:�|�Cp��-�����0Yi{h�m2/�]I,��x4�q�,�9k��L4�T6b����Ԙ�l,v��I]����?�v<V(2�N��xҔ9��.�T��W��#'��p��w���T��ˀ�����Ɗ�H�5A��+]�~n��ړX�Yi����tRU0�J���g�_�{fm�렲u�P�� �wʳd$U[@<{(��#�h���&VT�*�5�A�9P���[��u����	�h���������5)>�/�8�.������D���T|��B���a�g����S�P�X�p�I�Ff
�O&.��e��qO�ҟj��UN��mD�|���}��A����d�J� �h9��%&���A��a�s���g�S�)�u���얬i줮?&f(�OqA�;~�ː�B��M��x�^Ǘ`������~�%�{�'�X`ѓ�k[D�F�n��@���CLO���4�����}=��̿_m���6:龲7�ec~X�Y�S>D.2a�v4L�{
A"��^2�	��q��݂����@��ד���G������u�{`���L��v�����4�͋i�a,����=Yq}��3W�=��o-��AG��UXW+������i�~G�ʆ3&=@��
�z��	R��>T9��,}tQO)�f���`y_-ݡ6[24�>E��D]=B(�7S6y\ts��12�}��*��⣬��B>sQ}���K�*����Ȓ�8���8wc퓗@p��8�''��^}��@���ҳ�$W."`e�"�q��(G�1�z4	jM�1"�im M}��Yn�R1�B�a+J^�c���-;�B޴����r(��O���F9j�ù6V�y��-(k�B㎜��G�Cy�LjG0T�d�+��#XG�6��xS��ǆ�~ 6�����rY�mv���G@�ȉ��/��v�J�Ax�ZӀ��ǚU.:�����Gt�K����:6�d��{�����gp�i6E
���eL=�njn��ЇԌ�ҕn�[����N����g�~	�@%����m�k��cav���yP��.�]�XL���$ ��!�����wo�P��Z���&V�k�.�@l�kd�̕D�����	�?3�c�]R��R=�_��,xu�)��һԤ%@�&/3Ե@�jԟ�������R�0b-L���)w�c�n��z�P�l�,�2q��g�#�W�㘻ֶ����=Te�K�t�LY?�
$��H�Guߨ��v�-�K���n�b����R��S�\��0�t4��,>"�l�q(B�-;Y&�� �G��7�~8�Mx���K�s�<i�3�۝&������>�����a�7a��ɮVL=DF�9+��R��$�\3�G��N `�r9�N�>e��yK��!ĕ޸���͆�)�O�U�E�":9Z�	x��:��m`ڢ!�Mݚ�I� 1��:*�^-��rF�>'�2ku��9y|���y�#��*gl�!HErh��Wxp��c�i��� "���F<t�GwXV=`r3��#Y&I1}���u���[
���I�5�P\r=WUE��t������*<`7�w�Әws+����4��z}E+(|T�T0�r�!���rc�d'��݌p�Ͱ"l+�Y~T�� ���K센�J�g�}m9��{NdRgݤÌ2�ڵ^������M��"m'�{����_�i��ֆ�^`�� ى��?eu�� ��N�%��K�j�/�W��P��n��ݟJ�z�قήU��0W�� 
�P�m��^��L�0�d��9�ޜ�V��FN���ݎ#�~JI4 ��l�MtM�|���t�Wk����Ð�s�
ʽZW�i�=p�* ����C�,p)��/zMV��k�7TҼ߫eC���X��Ie�&�i��������OC�|�xzm�F����,G�o�@�Emj��6����mѹk�JF�C
5rq�?�Y=���#��^���Ҝ���J�kmt���y6۾��Y��n��fX��Z��43����R���O,�)����F��y��U�!���\��!%��J.Z��f?�ӣ���\>p�F.C���z��w�|��iT�\B�<K���f��
F3"���FXZO�Iw�zR��ʾx��Z�^��>��X�ڑ
)zH��㮌�[Rx�S�X}'W��[X�*�l{�9:8l�ǆ��/ ���|�
2!f�S����\Z���S؁�t��u����Ģ��/�b���C��+(���ːo�Ef��a��gM��4���E)�����p:kس"��N/����+�aC���f�!�LG�9��pO����c���H.�!yܿ��B�o|�H�� �n˵[gk%1U$��T����#�	�5s� Y#�ڀ�-�#��&�C!'_��׸3�gv��Y��X��ښ�ަ�œ�n����7�t�������jK8g�4�?��Ԍc�O��k���~EV�o-�Yz�c0bo�E���`��m�]!-��N�����DX)�\������J�G;Y�bc�"L)1�`y��wQ&�L�b�Vo涡�3TYq����+)�wW��v"5���*�S� �<3.tZ��x.2F��MT?AO�|�o��#呋Y��j9@x�»>���jB9v�c��a�NaXON�^}��?�\پo.���O�S^�1�0�!�Y˗��D���_�	�ٔ�P����v��ei�R�z%�g��h����z��==��J�`%�h�5Y�J(�{��[�n��̼yj��e2}�v�ͼ�J)}h�_w���85Qp��}��P����<���j�/�>�%1j�^�ؑo�n�Aj�l(�f|@m���m�LSwYI�UubR���=�6��
_�N�&���� ���F�0m*��{��� e����k���B�i���bxN���6G��t�
`��`*�s+y��R?D��8lF�HN3�;�uG!&$�),����3-�!���k��1��Q��7u�i�G#a�q���+1j�>��9���:�瀟��9�a����_��+טf�T��'ʹ@�-q����>���~�I���w�;Mݎ��z����W��/M�?�	|G7w`IW�H@��%|h�d�OF�Nx��f+߻�_�ܢeH9S�:"x�y=��$f2�"�׽F&��#c�?��܀��vD�������Z���'J���ϝp���8��%{��MPS��o��ǲ�@��49!B�-���������t@ܞ�S��Z�8�AR_����$3b��1����E�&��J�B���uAB8�;�cI/=Ů��w����f�������,-�S���'ȶ�z��C�y��`��w��0=6c�a+�Jr���h��s٪���J���Z�����w�ч���l*�IG�����ŧ� 1Fꀜ�1A��##O�Ж��V�r��i����
i���X�O\�H��1Ft4�\����#��ږ#�<�V�!�p��jD��to�b<�O��5&Q�5���	مMF[�S��,XCV����DH����M�R���i�� �g�����G�45M.{b-z����u�|YI�uPq{=��2��\�"�<Tz/O'�R�C�oA���S�;��+���\�\��v픛I���R�g&��V'�����*'X��4\5�~@�M����Zs�9|�<k�R��*ڐʥƅ�[6�)Y(����ꙡ����ۺ��x���d�"bo}_:�$�7ֆ�k�<[,m���T��\�}��ƱΠݴH֏@��������������w.&|o�ق��&R}ox��0T�P�8tog�ki{x�0L`+���r$���qv0t;�]��R�Z��<O���Ȑ���D�+
��6���$p�s���4�4j��FRI7�̉CE���1p2�Ьn���u�G������@Ig]�8�T���cT��J$��!�k
k�<�o��6uL<�z��E������+|^�K o�[���&�U�0���aI�+�2X_�\_�\hR�Zۨ���p�WA�K�����|�m�,��|{�1^�]�E��;�8��pZ��pF�o�]W����Ja�m�*���.h�[�Z��\�Bm�~,��%����P�ֱ����Ŧ
�3"�	E ��9���
;PWк ��h64`ۼ��L~��@"���w(�-޼�(|�@}t���=<���͸M,�u,��%�A@P� ���0F�!X���|~B��H몍��{��%�I��&�����b5�/0��&#���8l����?���
��kM����h%ʋ�3�oQ��PS)pх��SU���#8��Z���
���ۦ�
���v�����H�z ���.,A�7f�����@&����
G����^F7l4�X_zݱ�����e�ݩ�!�l((Q|V^�a�-�G;a�L<��8�&�>��k���������d9�׋r>�RoXi���&S�!6�o��
�o�6۴9|�l$����W��w�|;��M����Z~`�����q�,�v���.��i_�ƒ6B��dEUahB�l������,�XRb���x�����d7i�(|��ŧ��Mihͤ��� �m��PXN�뫳����c	l9��gh+��)Ñ؍@     l�P��� ����|��V��g�    YZ