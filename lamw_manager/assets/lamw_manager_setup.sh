#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4037521974"
MD5="9a02ce4be3eddcc4e8e6f1abae28ac1a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20192"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec  6 17:52:43 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���N�] �}��JF���.���_jg\`�Ƿ� �G�۷��#�D���s֎��݇�0�8[w�I��|���J��.����\�gY��������յ�4��%�e�\��Id�FK�qΝMU�_�2����H���E�3Ҫ�{��
Wjcȵ� o?���<��x$q�:7�G���8�-�<*mV�ƹ��Y�ؤJ�J�$ނ��D��޶���Wv�<����&�W�M���yIo^�p��5Y���ְ,��qɤWd�8����G��	ʊ�HN�ic�m�E�A�]+ŉ!T��WS���P�V�dO� ��bR��e+�Es�s��Q��o�vC$Z��#݅z����d\,4j�&��	odv��y+?59������&��;��@� OR�rItL�p��Ms���.9L�ok֙bh�jC?j�+>����`��#�K��K�B��������(�yH����p���tq8�)�1��(uګ�l�X͓xZ�M)z�[Cf¥�fʅΗ����`oFMg��U�J��pAl��%�5$�p�Ґoe��MS�5�36���<K{��)j���o\*g	�cCy�FE*{�`�
7P����L:��M������vٙ�nG���OTE�^'uXc�5��,S�~���"�9��>�㑺JSj
���9!e�K9�GoK�5Aj6�1�D��NB�&iX�_�Dw�D��hv]��!Y��Y]�--���A���%-l4�,&��g����\,*[�s�Y[���V,M�܋�u�o��S�$�vǷHS�`��E��7=e��5sz��;��2���x��PNg}��L�g��(yt,*��	�xmK�Zbԍ;#�x�*� ��N��'���mT9j���6� .+C���k0;�v�$��Ur'���/o/���cmBnJ{t'LɅ��=g�l�h�?�5��j�1����A��ҧ�lg{ple�nwJ	����a��3R(N!������������dV�<t0���Ѽ�J_�]�?&_�nUn.�?��KZRĮ��5f[j�|��l�#󂫎�V)���)0�pA
Tm�b}E�~� �����$'x����X#�W>0ʤ�v!Q~;�y���$5T� aɱ��z�Ӵ#���>��g"���}lX�;:��`7�b�93;J��(<�n_!����x�f�$I�iOє�{�}5���Y�o��hc��?���/9L��z���@c���.G1��)ף�ѓU�����������,��.�@
SL�&H�Bc������=�I2��I�G����(����>���(�\�"=�͡	1Ő�i֌=9"�YÙ�I�\�=��!yvah�Vj�7��?(�^���Q�"��?p��R������sI�H�YP2&�T�~%��w��D� �|�T����$9���*�1�3����冈F��>:�Jv���ܫ��DO8��_ լ��j���SIE*��J��2ۢP�w����yP�(��(td�� �S����^�~!c'=�~�ɋPѩ�6�~+!�����R
�A���cN����z�~��Z7	�
�����H����*����BbH�:���4sP3�f���8B��|�ɹOr��)�S�^ĉ~Qf5c7����X��ÿ<R(x'h"S#J�2�e��Q�F�r������`���0�'�J�����a��-x��>N�s��l���{A ��ޣ�������c'5����*��"�Ȅ.eZ��O'(/p�OgכL}.�":�4h�I�=Q����%}���&�ӎ�476��O���9sn�m�A�$K\���u��^�F.,��'���Cj��N��P��ZW��Ҥi��k���{r���fU����
�fN~%ϣ8t<����F�!�o$�����\j�W��`}@�|z[3E���z�Q�e�eu-�P�Rt�Z|�y�t6ʵG�0x�,d7H�Ny�w���g��w%��_p��Y�
|�{䚖L�3�7��vU)N��q	w�ε��;l�%/"%�bŗ`{p�F��9�H�B�Lw���
��}��o�A��L���x�������^C ���	��i�9�P�{�f0�����y �R���o���Ę�qGyL�(��PZ���1S0b$A�V����'i��Qa���ȶ�����V$����D�<Z�j�S�R�>�9:[��T��������;��ZM���g�q{��Iτ�:��b>��I�?�����nd����Sx3�.�"���m��iY9���n�-��� "69��΄�a�	Rn
&�*Ð��Uh���5�k(i��萏��x�^�S�f{�\\�==ǨQT* �!�Gj�|	'c�F�k�U�KH�L�~S�\t�A4�)�g����	v�c"�)v<W��\'E�]Q��ms��P{���x���~ӓ���9��z�����^%�/�9*�4�M�z�_�����|�{�`�=�@f	$}�:��L ��nC�v����	�܇އ�����ZO�6��-��
���Ba��E�ʔ����b��S�Pᦋ����~ߟ����
�-��ŏ�����_���H�[܉1+��@�߄E<���z. 2�p~/�S_�>���a$�<�49ŉ�+������`��EP����@?İ.c��-2���D������	N1.�S+yh�b�IKV7��j1��[O\mL��~�����h{6���z�[��׏}��p�읲�D/�n�~����Dif�㽤�qW��ytL�����u�3T*m�[�x�.�os��Hy0����l�+1��K�J^\��s������o%A�5;���BL1ؤ-C��Z0�>���DxJ�C���H*JL�}����	�a��3p�]U�q�po��J� �[	}�[�`���%��M����G��~�J��X���&�LT�XJ7Rr?u;c�uP�2қ�CFҩ]*��6R,:"!�V�5��2]I`.��+[�����-���f;�G��m��Z:A'��uZ���]ۛ���A�{�q��2�`���E���t�/����ng�a��-��b��3ž��l��ۿ�t��dp�U�qu��pL5��v~G��J��i)�<���ͺUG�?�}��kFD�%�\=9b�<Qd����B(�S^Bx/�C��cK�&)�!����=�-����\.Y��ƪ���Q�*�Y.�!�<ۻ2�U�a_�mIN�>O;�s<g���v+?��XQ������+�\ף[4dP�y c�. ��§��KqT���$�s���b�!I���R����QG��P�=VW��'�u���}�d{4t�������rsu���I��ǲE��9=��o���6F�o�V�(�vld�?{�z�$�K,�d8w<Fr�,|��qg38R!��x-�Ҁ�a�Je��L�O2�������oM���/S \[��3.<X��Q!D�3�A�[䟇�<�;>Ó�3ݜÅ� ��Kr�ym�y}�����N���ky�s�j}�W��ޘ��`�[������~!��Y\��x�~�p���|�(dJ"����8�R͐nm�B���٣K��'�q�R���{��E��Ů<��}�L�W��_��1��C�Z�Ф�)9�"Y��?�S����
��wKjX�����)��I2��~����ٟ����W9��eL��E��8�l�+q���a7]�im�������v%���Q������f��R�9���^��a^� ��z���}d����S1�Y}�ŅT	���b!p�a��S�l*n��cw�2t��� Z��������I������Qy��,�V���r�r+�z5#|�apn��a�Z���HRܞFB�fu�竾�!�ۗ�tm�W	��N;z�6�!�pET��(ے���0�<�� ΋A�M�N��������G��<��	7`���u�9�@,c�_nι�{�7-)l�s��A#C�/���&����V�G�lp�s1aCQi<%i1O0�]¬�oi&���/g�Q���3��	��\���͖o����5��A�Y�����u�./� &����Z��Ƀ\m�����G��9� �������Ӵ��
O;�z&X�h���/u`� ��
�����W'�q�[TPL����l0�g`	,�g�(HQ)��X��[�E+�HM��Q����'�̨}��(�9kжx/!ͥ��0���nP1�v���F䱘�ĳ�t�Y��_�,<4ӾIƞ ˜�糯�o4`s���%��lP.��M�4qz;d*�oZ�܏'awq'�Ut�$�V5��n�4� /�Q5�����]HLoj82A-�m� O�]����s��)��}��������_�5{����������1c��"Q$!!V%�3ԵV��;��*D8m�;�����Y�l�K� �A�@�����k6�\ڀ1"c��Ġ1�j�f�ҫ��-����RJ��۬Y)bJ�P�2�u/�慠w�Y1:�e���<$�������0�������Ŋ1��BG�gT��8h߱��\��e�<.)`d�ǚ�����������dJA�h�¾9�W&Z����\rM��a����P�f6����IE���Q��炋}>��6������NV����A1=&�P�ۆGFr��o<~�~$ ŀnU���A�c�c:����p)s2���R={�̣�Ү2��ǯ|�(���Dm��Q�y��rj�ؼ�O������(���Ӏ��M�a���t�=���Xf+�D�2�S�%�%5|m}U��Әذ�MX�KU�?�{���;��ہ�N��;S��j�v��ھە��lE�����uiwd�����#���vQG8�Hݜ7ѫ-��nʗ�s�B�+���./8�i��޽�?(��~O-��@ۢ�o���3\��j��jg�������,�u� $u�?�>p{����R覣1Z��})�x�8�5o<��Ll:=����.@bC�S��L�����QV�7�����7��s��S�����gXdz�)���x95̅#�uz��L5�} Tљ���d��b� ����Fb>�N�r������"p7�;�星q��~=�_�ǣ�(N����P�^�>��ys]I2�Q��E�0Td��EI�PbOFs�U�E]'1]#*�1ŋ��g�0���G�0n��j��3��:��my��)����q�ë|��h���[/�zւ?P�ƃx�] o�<���H�0Fפ*H2�R�#\��Y��h8ggRZ�y����PpBzS.�ߛQ��(ao1�k��	�H��&�/l	EX�o2Z~�=z���Q���D�}y:3�,��@߈ X��^�伄l��}��wp�|W�v�ϭ�&%`,�!��)�) ���*�Q�ZA�U̬�R
�%B��D�#(P�ۣ���(��;�7�Ŷ�������K�Y���u2Q��$]n�t_'������s�6�a����v�[%I�.?�	��a���`�Z�m����{�3n[��ѓ�B��5HH_��\�١��(�>n��]j!<a�M�t�x��JUo5�9�t��{��-+���� ����+ͳ;�4���&V�O���(/�t���r،d��N��BNJ��i`*��H���A�S�ak4 ���m�:�vM$�M�J�ΘΨޥ�z�ǣs>�#��b�&C���>��*�4.�`bg[3�_w����M^ײ���덥`'�Al�ső�]dϗH�i����\�f�XD��/���O�tbmR�������^�d���.��S����*5t��][��#�Tx�ڌ8��qET�M_��UO�8. ��z�e
H��=��8�J��Ŧ�F샣e���ߞq�m �K�^V����@���_<}F-�v��pn~<�/�nRR`����㚪�y�p���=i|@'����Ԗuk�u���.p֭�cǙ��d�e�G�$�Z1&r� װ#g�*6�~�V�䰬;�TfQ�	h�Y���":������$���2�N֜���
8��ݟ���P��@���J�G�ѩ��)��+��kpw*~�x�I�W쌛8#?+^w��@z�Rb�?QVω\:߀������jї�$!���u��}�����������}q�B�T˴�gs�~c��J�D�U��C�	f;H�x�L�-�fX�D�'I.��n������3�jĻZ�Ys��0��286�)��Î\�X���Ō�Q������q�3�A�c>���!�F�[w���E[^��2H��6�N��"i;����B=�k��)~��;y3]��;�\B]pI�&8E,�l�a051��F�����k�& YS��nNI �j�Xc�܋�ݕ�{%¿\Kev�V?�MC�qH2��F�2�N℆�`�.`61\+�����DdazQ�Q8] ~_Dy�͵�������ŐO�1�����veTJ�<iƯ^���ӌ����=T��)x�����1)%ø�{e��l�����s.��y}xZۍ����1/ud�����4�����Z�����>�]�n��*; E�T�ɳl�����܊o�K�];�?B�y�C�D��
�,@�ƣO�rV�h�ej�x�� �#Q}�58��_g��{P� ������9G͘�p��h1�i��>�3C�f5���1pd��V��!im��+��w� ����a��H�=kʆ��}��N{R�V�O��J��Ex��8��$�wE�7�S�'���Ŏ!�\�� ��{<X����%�:�	�[=�'_ě�O1d���=,��]Zk?�����SH>
��N�hЯǜ�Wb��8$	�R�1�#0�%p�Y���o�]ĉ��Q/�Ĕ�{4_���ưy:3{=�i�s/��M{
��՟T�VXj<ʊ4��?E��������xf' i�s�}�k�&�LO���
¤×����o77��s,<%$=����'�)ďf��Q�c�@�x�1���CT�21�@C�1N� �XG�"�9_8������*H_�K��:�}�b��S��y[�q�P��6E_��=�5x���6��~�`������Y�n)
�_��������C�^M�mx��%*�~����U��ī�1�%�5N�W���9�O?(�A%T�akE���'ބx����``�"d%%�׌�����ݢS|#�AN����ˎ�V��Iyy\s�h�	ϯ�7J�oc���I������+,�V�^��v�(а���a0��8_Z��!�xҐ!���-z�S,坝�U��Alw�9�{�a��%���GH�y�=��)�nS)k��{�E2�{b�	Ƈ�by}W6�K���p�3���� 	��3�����
GC��_����S�X���ܽ�@ZѢCTbG�w.�I�B��W�2�FQ�3��}?�n��b���ʝ �~Z�k����p1/6%)ww�srׂu�?���]zJ��{�6�V{+�v"A���F�� }a$I�PZ��A�ӱ�)U�.Cn�
	�5�>]��EJj�FDhY:fHC��	����8N�5��`-���k�2D��%��D����d�a; sQb�.��&l�bq����)ﭧ�X���#iG�x�s`��@|�i�����;vO��)% ��0&�C����ٺ���e��j�/�rt��M��7�P9K�^(�w2Q�D��
L22f�U@E�
G~���[FR"t�)U�0&���?sJ��ʮVҺ.��L�pe��p�Ǟ2n����꫱^�Y&���2�C��WY8ԩ��a&����X��0�Y���l���"r��h���~ϵ���q���88�ê�I�so��R���)��9��~��@X����cy��RtYv(YO��O>R ����Q5y/�T ˃�Q�00�K��L�l���f��\��v qq�+�9�NM<,{H��S8q����5ʣ=ӇS(�a^��!�����;��F�fm�=��+��1���dH��;��PHl?��	�a��152<d�S���m
��.�%� ��u'��QY�U O�e���*,MT�eL��#���W�������l���tF4YP"��Ѹ][the�X1�ͺ��{A���$���^@����^!���d�/��J�y�d �H�SAA	�'�PqFJu���t�*�ݟ	���%nbG��N?�؆>��m�$
�!J��pV��8�ȸ���{����*7�����:vO���.�\E7���=��dR�H�|ۮ��r�b�N�@��a���e:�D'S��SaĄ�v�꺐�y��S�z��<g���K���-�uW�Ѳ{�@nOxG�jY��lc��҈��㥂���f�41OeY�^��X�p�7f�')2,�K%>�0^��ڄ.�k$؛�RN�1#���s�侱X�m�v �@�qS5��x�������.����y�s�Ϡ�!!.��;D#�X�����RfD�l�ȵ��jS����j��!��GM���wv�\T��lu|�E���*a|������/���8Q�Ieؓ�΄�b'�=���:�}�L2�1YYEv?p~�e��q�x��L�VJЗ�i���D?d�"��O*/���NQ�&d%+���L�H6T'�O1�w﫯�ϛK�l�Ms�UG-�">�B�,�@�#�z .�2G�d���m2�[��MBV��nqLB��ga 5p��G�� �Iu� y�<�sW����ͺ+Uvy���9�|x�ܯ�Mk��D��S�aLD�B�W
��;�!��$�EL����dX�RJ˹j���8\�a{��qć2���Jiz��G{�V�F����4(��`Xp����뫥Hx�9�����K჈?_$�nߘl=_kvҧ��	� o'�\�O�q�!� G@�0O}*=��F�m@ec�Q&��b�G_Ё"��Ky�Mه�h�2B�-G�wZc�嶉O�����cA��	_�~z,{{$c� �/�X��X_���u�
f�{�·AY�H�r�l#��Lճx+|`kЂ��z�=��uv���,�r��D	!1�U����<� %�L��� �����-'-�<~ChK4u�l�"���J�����eJ��l�fEe�W�(�� �ݺ��.�%��x�0����Ђ&��fNI����ѯuE�H��>��NgF���4��A��=B]���z^%�	LBDt��bJ�|X�#r�-����h�Y��Y34O�=v������E���̜- A@LC�?pũ���{?��%�/���U�W�1��(c*�w��Oao+�:�[��>:�¯q�:��IFfEfc���� Ӽ%���PB�F�5�f�rʽwOn\0t�bѯ��du7@x�HbI�$d���ߟ8
^�  ���\��G��,,z����X��+�w�b��n�{De�M$C��k ACҚ!)�u7�	�7C=۹0ױ���"�vt\�2�{N:��pÖz���k������J	�5X*x*���'"���ݐT�M��	�����D��K;�����E��+�X��*y�����kY��xx�X��-(�/�^���+�Χ��J�"9_*����0{"Қ|P�0%��+�a=J�M�=<�N��q���F��e[Z��z�:�?�0v���@�2�^��<���e�2�&�`\_B&�ȅ_5����*_A׈$}�Uf��20۝�*���C��<��M�B���pWs�z5"1�}��7��%��a3NB�1 .C�N���C�+[b�x�LTY-G<��ٿ��b4�E�������60������i8V�*��D�a�����U�p5`*6����3�pt9Ȥ���X��O��$h���8g��u`Ϟ�a8ZM��ܶ���xN�_��ޘ��oFkn.���F�7�uҼ�ʮlɩ��8��Ks�ri�������uN���W�eD4nD�r���f��qXy@և
�g�dv�X�[C7�{��BK㋹�պ������DڣG" �0ǉW������D|�H왻l�����C��b6�[�TU%��/�߇��-n2�j\?�� �w⿉]�FN"�R��@0��a��l�g%��_�%]�v�պ��Ĝ��=�nb��	)�=�/p$���>�[��:3�0�.�>M�TVE
Y_kbȨ�����������x0m$�=2��%���E���4J��|F���x5w'���r�6$�d�n�S���1/D艢R��mYTw�#O�ގ��<<��|>!��P@��^���,��WL��&�B�}a�5�B6�u�d `�J	q�	V�~��ei;��aǆ�b6,�M���/jrO�5�e��W���U!��t��6t�C�M�O'T��G�P#��rc5�
���T���H��|�k~���d�T���pHVht,:x�u�m:8~���"��8�9B4F+L��ۄs�{�ؔ�}�嬗�j�
��X\��B��
y�wO�����3a�w��1o�Ǆ5�(����U
nć�2����o���yu��=X6io�e�8�b�=����W.k��/j&K)�'�s�K� �my?�;�T�h�-�����"��^�Cz'��~V�?���Ů/���A�pz�a�����i���u��4�h��Eh�N�͖s��-�r`�~lXy�����k�O��D�w�V������ac,FZ�
�u��J86:*���aI�Ѱ �:��~Go��|�LO��={+�V��@(]@A��9Z����.��@�fM�9�(e6c�<�[UJYR-�`�#���y�nDq�T�Hf�� l�T"�,�� ���=�s�,I�C������5-t�y1?��3�i��M��������Ʒ�����t&�.��QjzO7x,o+���M'���bT��p��h�Q�k�?7������:m�R��|f����ܣk<�e%i�Ю�o�:�j��2O�a��+@�
�y%��*5�<6������l泌kѭ��!{��a��Ź������<�X2�Z��� �aǔ��6�>DR�*[�m��D�t��Pwq���@Uր��Qd��qj:(J(���F�b����벚^�����F;e�y񮴯�wȪ��-����)�>�!�㬼X+�}L"a%;qQj�k*��	?�hn��*W౸�D��{i
�n�*O SF}j3R"��M?��z;���Ӵ�,LI׶na�"��ih��P��&�������o�����FPy�I�:e 7y�X�g�Lf�E�
E��A���(��F�����)9��w ! 8���"� _"�s5���)z�q�#��Q�1�T4�j|.�|�_�@����t6/G��B�d%�GL���r��<8���fK� ��K��A����2���'��E��IVr�f�v�b�p��%[��a�^~�?�*�J���a"���h�(�[����&�t���IxN.m�f�۲�:+(N�4��ښ��Vzt�=��ɢ��7f+����4_Õf`�+�R-�sE��0H3������ּ�J�,]��d�5&���+�ہ��U�>�!��u������[ż�b{0 Nk�>5� ��,��$Efm����b ɒ�Bz-2	1���`���%(.a9��(�T�LʇՏ��7��Km)5���*���\�u�hҲ٫�����������6�c9=��P6�����"�?s#�ɾ�.�_������Ղ�O�o�95�9v׍�4ē����}N�� ���?V7�؃)�Z��Όl�?���GV�cG�ET(����}l'Ĝ��EB���-~q�Ϗ�q����f�'@�E�N%_lpeu=�#I��Zx�`&t�C�{(�P�3����3�smB��)�c�� ś�3��`��F�l���|) �j����W�P�-5���RYxD�C��K�T��1f	A{ם2}���+:Y�л�lR3&��Y�>/c,���*�
�x�&���jL#/醚�0�;��}�#��Er���ru3��LWi �l?� ����Tfj���~��O�YȰ��E�`�K���?�V||k�Ȗn9�k6[�<�*�&�r�6c~�*�-�n*�
�q^[�ʽ+a�K��������>D:��Fl����A/�V�����y�vF���*��pK�� ����5s!�u$l
o�Ha;�����Y�ۋ�bλ�,�Mt6�9��{����/oZ�t���~E�S�{�H�5��5�L�����k��T��~��,T#�Ն�V�k�RR-��Ҁ��&�q��kir[t"�z��Ѫ���2�m4LR���,]d<$o�R�<��y�я�uFQ�����F1� ���Xt3�6��0���k�R�8B���L��P(|�Nk�Vцe-v ����i<)�v�Ӽ�������N�U� 3`8ιEe|~S�@<"޸(ȹ�ѿ9o�e�/�3��;NuĬm��(��'���6�?8O���F��*�}�m���1�H��u�O��W���aM��[q��:C�<�ݸ��FZ!F����>��ف��e.@f_�B�Q2�q�����usk�I[Eb��T&{(A�KK��E^����\�NhANcM��9���*�^5��	�#��os�+*3s?�	k(s�4+��س�d�aq��d\H�g����^q�X!l�!���ĥ�`��*��/�;U��'&q��a��'��������Ժy	��.�/�,#�A�<q����m�=�N&��e�E�j�	l����W+Z��P�����tٵ�V:�}^��<(-�{1S1d{K��;H��È�훺^��k�0�� �Ң���ȁY�O`9׫f�;&$��|�YB��;e�������-%5��՝�Vo�e\K��v�( 5�y:H����W�ԁĆ��SU\mQ��G�$	�k�v�z����+n)�J�Ȩ�3���w0T)a��SG0+�A/��r��S�jnX�q��G����}��Ƚ�ӗ�ϴ�vH���	��U��r�_�>8ߤ���o^�/��G2Z�z�bEi&�9A��ܛ�5�(�2yXT�B�����g&��dn��?J�t3����$+����'P�ڙˤ�� ^��ZީmhP
��X���{/s�\�g��ԣ�+�$ �������l!ʿ�}�M..;x|��f��F�f&��|�OH��E�ac�r��@S���0�6���Jf�M����x;X�#�8�2t&<<u����yp�'��aQ��1_��z���?��|��|g�k��֓�wG�f��q��7�o�J/'w`��} o�<��P,�lw��Yن�@4	�.�{�J��Wz{�����5?��/L1�A��\~�H7���9.l�8Ma�ߢD�-����]�0\i��%��0��jb��g���o�_���yU����ʓ�j
+m_m���E�\�ñ���JGA=�α�$M^+�=oy_a�OCv%t`H岠�-��6$���j��ΈoM�~��z���͂����p"�e��٤�J�)E�sc�<PS� ���i�^��g�4�F�oc%�j� ���05�Ȗ��P1�^R�YR��^=5)L_
��{�jB� ���g/Ur�Q@�SG���^�=bYC6�������� 1�H��:��t�k<�7]�5u����_��7�K������k�|��S/mNR0�-��É-�F�F<���bͭ!Vyq��vC{4��EQu� }4mɖKѲU�	���=�d]@���&lb���]dVL�����A}f݌���-pVX�E�,R@-X �Se�����ҽ_~�U�"�=��MvN̒#��>�̳�Y	�H�fO����"�S� W#4~�.Ɔ��A[��r/��f��ؕ�u�GA�����+bk���-D=��k�C#�[e3�(�0/��9�E3R���ʈ]�Կ~t�6e,@&��qߴ}��┉w��X�¥�n�^�J7|0�^�?qC��s_d:Q����������ݤhUk�e	��{7ߌ�Izy�K{g���KW�t�f�T6���iŤ�*Æȅd����U�3y�ئ�%1j�@x�E��z s����%4.�.$���K# �9QS�nz���L��&��7EEP4D�
j���Ш:w��S���aTo������zi�-�H����It0�f\@c���S�٣f���(�L�����a���1�g�E-��!����ir�7��u\z�w�rXg��OR�!�)ط��w�@��$�������<	:��$�l�(j�J�4���w��q���	�?NY��*`�$g�ʭc� ���������;i�e��N݃B+�q!�"ȎG����7�ەKP=��e7��\)5<`�׎ǝmj��q?>m�m {���9���ȩ����8���V'�X�*y��e����y;,P������h�	r���P�F�Q���� �|��P����tN"Yݽp�]�Lx��Z٠++�n�58��l�E�Y��6��W�Q!�(�c͒��� ��G癣�ؓ�Y5$ĈT6*})h�b�_�'c�R�j"J���c	${�O���>6�A,0;|*W�#e�N-M�b���K.O)�4y�K]�`���W	c��ׂ��/d؊f�[c�P�s[ۻ�G�4֢MAS�U@n0s�D�h)�9����dp��∊"�Y,LKڨ;F��X����b��u.�'|~	\�+�Ɩȥ��(��@B�'v�m?��g!�� �>W���Vc>�E(��4�}`l�ҩ��@���S�&�	N.M+��>������𭊉����f!������#ɸFB<�m���s�-�\�]���2�/�Q:��zϔ|T�\K"6<g��=�&�~*�F{l����|B,C�A ��%��r�H#VHeD�9�<���aY�O���٭��KBG^���yðR�!p`��(8�4�A7L�w����9��@ͻژB��I�!�|~{�S���e>�Eވ<�K�_K�2�H|B�sj�F"8^�ۛ���_��Xɋ�r�� "���FC$	��f�p��Jw���vY`=����|���A]+�U-~�
��(G��y��3��er��㨙������M�ҙ	�}�1t��
�f�9��o��D�P�}��I�J����{׭#���8w�fP�SD~��d��% E�W�H�[wv3�9�v���y�!�Z��L��u��R�����r] Qn҉�)�!x!.�	�Ysr�	 5�d�qC����Wm�J*}���ᓦUնw���C� �u��a[�횼Obb̴h'"��(DO��:���K���'�<�F<�(�\>���ٛ�*������t���j��+�"�����S�zP��F���
]w���f��~���G1@x���0P?�;��y52��?x�0�)��LDm�����'Y>z�U_�;�<���k�ި���x�D���_���3�i��p���g�'��^�d����H��W
����T���Xe� ��m��P���YC��;��-ҷi�u��hQ�8��;}�d�l8�"l-���)�F�p�O%y�)6"�'h(�Y�����ߊ�Y�=�]vLsT�Y��`�^�[���܇�D=��f{i戣��~���p��#N�5��r���N�,Vϔ{�@&��B
	yg��Ʒ��\���u˛8WZ>��H�>�V" �(��A����<��j�xDҾS��~�D���*-Dx�4�j0j��t4K����ԙǩ��	��^��R���?"�&�|S�KB���{h\\�5лa�#���ݸ�み�v2"c�#�CQ���F��9��F��@=j�������C ����G�B�!K͗����Ҝ�`��%O������d|���B]浕�j�POs�j����J�s%�r� ׸[B��=��C@c,˸%h�y��.���tq�ǾG�7�WY�j��W�%�q����m����]D�%�`��u8����(fu�����!Z������/�bn�����,��i@���qӼ�W��0�8l$6;��|�Q�6	�6��않5��z�N��|Ǭ��ܤJa�;wCE�̭�+��'�5T�-(_�@��Ʀ�b����=��`�D�l��v�V����jeB�Q�R}����yd�V�T�Z���p�f�I7���a8٬aCt�?�"�-9��1A4��ԙ4���*���.�[Jd|�x���0��B�_����-�~���#� 9����R���ʄ������Cv�}}�"�u�ʐG�a��H�T�ŉ�'��K����+�? �Q�C�
r�X����G4�,v�b� 
(�����~�%�0_2/�� D��&pŁ�Y�؛�j7�ve��hD]�2�/�D����un٢�ʰ��T��<��d�={j�woת�
�"�{T���u��а���BŻ],�i�|_yX~\��,��i�W�n�r�u�Oj��@Kjg�o�ҪwP&�L�r�O�?��)_;֖�i��>�7Ƣ��<F>d�c��X6ٵ@"\%��}����+E?.(��p(f��V5�S�Ρ�z���Z��FF:LG_MK,rh��9-��w� ���3�V���f��͖l���6Z��ǈy�z�d�Vn�8�2��E�$�.�Λ�p5��z6Q�3�k]�Iy��s�n�,c�/�S�@L�=���`�p��kS�nQ�X�C�擶��:ݼ�ӓ%�������#�#�Z���*@�!�n��%co�bp���̪pϞO	��GLK ��5$�S���l�i��(-h�r;o?��gA�>(c��.��REOLF���[ʙ���m�Ru�3ɨ��?*@��q���T���օ�3~�}��yn�|=�}մ����*7a�V=~f�	�g�中�T�����Cqn���K��V�����b�/{�W.F��}%����3�(igj6�}�) 6�q�8�|ρv��n�b��/4S�֡Q����XNѝ �N�㷨
�n�WJ�3D�/2�#���Si�SY���5*HM�?~��C��O���@�SW�,l)D��/�\(l��M����?�`�(ʕ[��(��
@�	�h��ҋ4��{�TUë^�%m}0_����Ҹ�.����M�����pn�"��?��#�3���/ZU���F'�쏞�\/{��[wM�x���a�)q�C�Jr�۲��2�'�T)+URc��s�ןՓ�Y�c�1�H��ILdeA�`"8�tj�����;j���reb�7��B�pi5w�k���g�����:Ź�ڬ�����`��ʘ�:(���+"��Z�K�#O҄�{��6�W,�?Ik�#��ZI�Q[�ǳs����~yq�{[�w�d6�����U��\�Xa۳��j���ͷ�f�;��|�<�md��o�1�5�8������'<Ǘ�b�7]9��Q��<D����r���	��$rVKs�����M��(�G����{X���@:�P+B�w����3�ꥠ��-�]���1���mA;��<�2S"�Ζ�^uΒ�b�,�ez�c9f�����U���R�ݰ}ڮ��ҩ�3���;}Ü5��>y4u�����8Q�����ϖl�	l�8��2a�h&�Nh$Q���(M#>��"��r�aB��X_�]���W��Sg�a������>:li�������E��ܑC'�i�s.��|HB%����f�0p>�<�y�g�~�
��(����\c�w��u�t7�q�>0w4Bw�%�����3u�
j�A�>��q�p�T��(���!��p�ѕ*��oN";��y��K#���%���d�(-A�^�0j�o����2�Rk�ݢd��4T��������!�Ĩ��,�#X�s��/�j~$�0�����P�H2O?;�HY�-\=����+,��+�A��~�Q0�*��:�h���z>�K�<�bE棶��Z���S�1eX�#mȖ\�f�ߪ�M�,��N5�ۧ�E���~�f��c3����=��q�����U��GM@.VU��|M�C=��A�[GY|XO���.�轸�@)k�#���"��W'8�׷̮�11�_f�(-�����'zNQx~�K�{��o���QI/HT���4�����}'���x2���7�}��k^"Z'6��g�邺�݌+���Q���k�t�W��}�����`K�Jsc��#�;oDI}�x�\b�q�Rx��GXe;34͙C��'�R��C
�Ư*U�w�Lj{
V
V�QD!�\�8����3��:s���l��/�1&�T1kl:O��.ܡW�����)��f������$�����VS�C����@�"Yo.���2)5����͔��޺h)-�ה�K�	6"J����_��(S�	R��;:�2͓J<Mi�tK�0H✲%�%���_�
�д�P��Yo݄��?�4�C�$*pv@d��,�NHQ#�x�
Q�<g�W�<9����T�p@`�7���Ð�Ԫ ��	��l�����K1�VW5ٙ��X�Ƃ��xr+�d�P�k�@C�#(K@m{�cHpp�D��i�`9Q͑����Ԛ�H�+?��s���:��U���<�ɖ]m���Ϳ4�	�5�����V���I����d|�}�2�,�����Tx���`-�܊M�뗞2�/��>E2v��n֕��C�Ӭi'ɂ�W��.��+�z($]��/�#������s�����Ǩ�6nr��@��I�qo�)��gaO��[P��H�k�w�5��*4��B0��5��7.g?��׼)|�T�uT�jb ����p<��F]��C��*h��G�-J3����ZR�^QܛM��:%����i�B�,�MM|=_�;t�1��_tz�����(ЈT Ce�Y�@��5��)��X��3 �w ���	�д���*Zy�J����Y9C��ge�,�+��䒢4��ֹ�a؄ϧ3�.��S�;P�h�qO�4���]!�ؽJb��o��pD��k�D��[$�vC���@�q�F�:�z�߆ł�(/��'��RK�Sg��q��P-S4.�{ny�}���}1=���K�����%��Z;j�a �U{ET�*�C���j�Z/���1"P�c$�#�@Rz6J`*�˕��~�L�ޠ?�́�1�Il�m����K�����A!R��.��?B0گQN\�v2�5��vTr�����P�~���Rr�qم��]x	���� n����z��[f��ؘ�R6��J?Ec�֠h�K�3Sg������7�ܖz?n����DJ<�����Xא6�kKsB{�Ą� �lN�y�xd��@&�9��s��4�pw7��@'Jؖ%�_��(��E��yB9��afX(��c�IQ���;�D�DC`.s9�)]���{6��c`�-wM��;[2Ŏw�O����&wY���r����+ĈJ��2��Ч�/D��Bp��CZŔ���"�2����}���?;�R�>6���d�5�΅%PK�B{�z����Z��w�����=ͥ����'H-��O�����'`y�p�8m��;�D;-`�̋t,��^��s��~">���&�<��"J:&E�A��B!8���m��,���B-�PK8��q�L-�q��Pߚ.+�e��ʐO��l}���K_����K��_�u�����6������ɭ����)�z{��~��B��x�o�+�,����76�*��9å��hӐ�:�����^Е�ɍ��8w%�'�ٮ���m� A.�������Yas=�ʜ�1{}M*HOt�I|9��g��˕�R�@��Q����yhj�`�bh*�O_1���n���U������~4��d�9%���K�dr.�<�tH�JȦ�>�2��7�K��Ŕ6��$��     sܬ��+[� ������ɱ�g�    YZ