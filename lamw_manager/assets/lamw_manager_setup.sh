#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="694619747"
MD5="8b32dcfd9a89854d5c7e50d7d2cfdfe5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26044"
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
	echo Date of packaging: Mon Feb  7 05:39:13 -03 2022
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
�7zXZ  �ִF !   �X���e{] �}��1Dd]����P�t�D��y����4S.�0�m]Y���&c�q� ئUGI�*��}׏���z3���"};���Q��@q�c	��	;6��hZ�'�x2>�y=�Ց��l,˺�:l��5���~خt�R��L��ses�L<�Q��(��2�%�p~��Q~�ʨ�b8S�@zE5�1?��4Q����%|?�Q�e�P�텐?���/�3�1��7}�#z�ǉ����lJ(l>��ؑ�'���.,��Y;mAkǫ1�V���������᥃?v�W�VU�z�\2"Q��$2KY�{�i�*��qq�@�zN(�������˘�1��������5én&]Ȁ�>=��{�/~�r'�T�~�a�_L���c�_�b.�_�^�a��_uC������w{oDs�i~�I��7���5d�äg[�����=�\��B�i �S�.�|�T�ގ�"#���(#K.�PM���u��d��2�J���e�s���0��a�%%.]�+ n2	vb@�CCtST�W�9��d;�\<�ej�4F}�(�Ի��^X#�%�XA��>yת�FGx�h3��;�o"�d��sk
�!����3ѵ�u�܀�r�������d��\��*i���MC������G�y�HP7�A�XQ�Ϩ<�#�-.-��]>󢿘��rT��u$Ei���h�Y��a�sa��)�FrZ��A���z��|�8���[-��:$+<��G���߳M�W�<ִ<J��
�����f�J,zUM6�$�dM���k(�]w�O���H�:�	������ݓ���>��N��@	���\�{D����S���_�c��@��@�һ�Q�ז�w��j��y6��4Y���`
Y����Y�\ų�)F��]<�0�X��ʩ�F;�6�9��ׂ�)\���X��C+�9=���%��z�I6���-�R�#խ�q�^����s��?8XE���#�1#�_�4�8�+������ʴu�� ����/������w�*�`W���אC�w�^�_�iNn\ˣ��V��}b�1T����<��o�q'm���6@g����{6�NUT�6�ϔ�������k1�r��E���-�N�,�>���X�%z�F�֑6|�r��� P�< ��.h�?�>ܧ~��~`M��W�9v�$ү��?e;	�!,�3�Y��U"qX'�z��ӇBͶ�� )q��s�(�d>��;hr�
DeEݚ��?�rjj���LOA�M�ځw�;�z=���(~�F��׭��އ�<���.���z����7רM���r
�=.I'Bp��<��S��	<pZ��i��ƝTm`�||���W:���������V9ֶ&t�a������N'���fj�\_\4��x�*��DLS6�������+��X~���c�I�xB�|�,�~��D��F����zj�v�R�b-��=d���	>n��F7h���K��C
?�O�sA@�+e�-�Q�� Z7I�P�Yxܜ�+��دE@��[���VNX>W6�P��^r�����Z�ߘ�Hr{��]^�i�s��YB�?|�h{���1�e�#\z�oN��ՙ@rP���j������-�����Pn�~���gN�|��uKR5S�+]���ЯW���s2�+����_+{sm�O}{ZyD`K���}j ���z�WX���}8���t��R]��՟�	�'�pγ/�����f��sR���~M���l��e�׫*��J܃;��L�Of�p�	�m[p��r~��&�w�'!UZ_��0W5��`v<V���J|k����JI"�.��4]�b�Ke�(5[�.��u4.m���� �
�:�$q�
��eH��]�؆5�D�+��ិ�Z|>U���{�2V������l��� ����
�+�aގ)���+d���c)� ��(:�փ�c��c��n�wtDǝ��պF��IK��"ϸX~��f���YJ�Jk^��#Lh9�a
���WqW�RR�<�z��6�HO6�9����!�2�
��n#�/eY$9�	8�҄��"Ӡ0�C����K�ꖹ��A�ޱ��sg�0J6<�)�{����7�v�٠���!��sO��ͻ&�z1ڮ��RH�����/+�z��`#�	q9SvI���@af| �+�8���Bmd�I|�T����Cwa��߲�X��B�7ڝ�FP�3��#I�:ر-pd���^��&|�/\>&G�P~*�!۪W�;Ap==E.�@�MC}P`c`��i%��?E`kl�\
�/ˈ�cp�Ge���$�;l`�kA����K:Vǅ[�]�A
�u�>^��e1W����K�f�c]l��Zq�;r�ny&$��wRl��W���%Z�N�"���p��2���4`n�`J�N����OF��e�����π�ċ�K�-�����%�S�_n=&{����
y,Ws�!:k��w?DŰ�GH'�}�\�s$c�x�'���P�7��'�#m��F��
ZHR��B����}i4X�Eb�Jg����b*%e�c����Gj-��7������:�3GdX@�-=F"�F;Z*2��B;��?�o�0�Q��ڌgۓ@Yỷ���*S�	�;���R�-To��4)�F���Gw�мc̧>q��Js��`A�rm����EL;�B�E����铳�d���K���M#���q�\dɢ�z���_�N�2�ղ�A� .�� ���a 2:ϝV�Q�s�5��/k9��L�	ɥ�u2���7�͹��ɲl�-��VI��xq��:�LɿoK,���r)�А��+��Z��D�Ά�\q��-����|�Ą h��m4�^�C���HY�M����)�򯎁Et@�ޫJ�����2�ҋ�AD�ZurP-ԶVF<�	@݈�t! ��nM���%������� �+��J��y�7�`�P�_��&ՅP�~�%�;&�.�S^�Y��]O~�� m�Z�m5q7E�E�F�܇�3�w���;�I�'�j 󪿙
����ۼvJ?O�V~�tg������vt�"��-E�ͫ����f��S����f�k��e6`_1*n�lw�|<~߉N�G����@!��h831A�Y�?��������ky���=���B�L�n��8��C��D���Aֆ��E�o����8�\ÂC�|<4.�wԓ��y��w�74�P�o$rm�4��@b��h�ƽ�Ư�|�T���5� �hU�ן_�9xC���,��Fy_@�jj�`�zrB��=�|���"�zo�R�z~�@��JS���o�Ԝ)�d��e@���Ɽ������`v߉ǎ�a��o��j�����=W=kK\h?�Ӝ
���y�/���)�Ӊ��%�Yڽ0Z���AI8!��� �@����h�*���~r4��*����G�Z�;4\��0y�E�!��]����A��y�;�7-��pl���3`��:l���!�b1� �%� y��7��P�#Ě#N��7}�gi���0s�ߑ|g�=1���텛��$���!ihⷹky��z�&���b���wU�h��5
\�6i�����1��;DһԢ"�-��9�j�<-�3oB�c�%�	`س��j����X��}�IWfy�| � �/7!ٗW$^�?7L$����1/��V��f;���=4��v�xe� ����$'>��1�K�6B�	�=�� ����m,��Ŗ�+&����(
��~-�s�,W_�gFc%�k���%;����	Lj�?MK���f��RIg���\L��Cwpk��a��|��3m�b
eHG�4-z�ӂO��.W1Yh����g�d�.m�Oy��N��f!&�*�KC����0z��"%pY�B�8*��y��O}߶��v��"�����Z)���ƯT���k.�zU ^g�P�����pK�>b�k����8P-�ЖVf��U%'�*��ZU6��n���B&%�%��'���hk�``Ħˋ�?)<�4�����,���X��}�D�����C˨��z��lO =h�^�?�:a�٬�J���i˜�5�8|S�e��@�[��aN��?���n rlٽv����L�	3+�x^=� �~K������ۙ�(�N��ԝ*��偷�����o�x�OO��z.2��wVs�"�IG�Ά����v	=��Oς���T�=b�k0o�[���zT}I�U�»Z�Uu+��;���V�FT ���qR��p��!��4ԭX'��*�����5{����-�S��*@1�8+��f���ĳ�wO�7U0�sH/�-y�DB<�UW	N�ji�Bq�Y˰-�x:׋3��b%�_"O�]ߙ��=�ޣ\%��H��{�Θ5���7t$�B���[��%6B��2��<�#T�g]��N������]�H��T �o�k�Л�M���}�;�-�n���Z]��a%�1������^�-�/�$�E9"��}j��̋F�4�x�] �@��@ks#�.���%�NA���(�0����T�\���	��<��	
M�e��<r�#��/�d/�C@�T�c������a�,��L<�����8H����b���J����[�{6�l{���tyf��X��4`���%)�W�~�*t\;%ֿPM�s7�5�?Ve�HY�����2�N�-�|+`'��X /�D'�N3��=��o�-T\�3�F0T8����f�[��/X�o���*�y��xccV�����L���Ց�#�oI� �"�sh���:���n�V����c�c�Q �L���ѓ�~�N���.�aQE_�Rd�N�:�$����~�3D���5�v������ف��_���Q򩡒����Q��}�@����n}��?����<��ڀG%��Yqɸ�S�T�8�nt�Cyh*3��fu���4R���Iy��)7Jz��@�s�n��}��r`	n+��.�zߖ����K��@�꒯V ��ftX�J�n��5: ��*��
�IUl�/���eU���'�w�ÕHZ��@tE-jZU�],�='����3��vRGx��oA<� ��DP�"�m}�Zo�m�&4� �d�bEAļ���Ϛ�����M�|4�l!vY�1hGU�F�v�`�Ͻ+�:�#2�:�4~g㹣X�r��I;���H5�HS�	�H#��	�=��p&|�+�uyxN�}a�,�?�ɓ�#�%�D��f�҇EꢌE�I߁�k�}��͈|Ԉ{�M�i�yw-1)��$�. rPK���ŗ�n�}T��	��� u��e0�(fya�46� [��
�aJ�x`���,�[g�x�:�hU[�f��17cZ����a8d��Yg�8e���Y5�vb�25U����������GV�����P%�b9k��F�k��L���n~������}=̊I܄�ɭh"��_k��DԘ���'g}����:$��,4a��Z�<Ο���wj�@�Q<�OPG���T>������$2 ��	-����s�R��G�����;LB�w�{U�(	���D ���J�C��G�����lx �t����y�Hҍ3�M��v���/�*���e{�����O]<*�Ӥ�.ܬFvg$-TOg1�`��X*��®5g�l=/�=Ec/d5�<=����Z�RB�Ϳ��9Аp$F����A4��i�1�zз��D(���-�~<!�g���o(�)�	���k1���&A�E��3�3�9MOAfd[bJP���1�婳@�p�{�ـ_�X�"�ٝ�X/��V����I@��{�o��������)�9�)Է+?���?+�ø!�4i�;>:U��{�A���3Cs�!�V��HJɊ6��BPB���Iٿ������,s�'D�l`,�a�@������0��ͪj�BX��m�S*ǿ.W�5j7�|R0y�A��8���B�Ӯ���jd�Բ���j�#u�Ŧ����9{�GL�2z�Mb�,}���Q0�b��h�6�@Z`ʗM���|폂��Á��8�M�Q&��co�b+�m��DG�?-�� �RT�1���dU����ȍ"�Vp��8�E�w�J���J̲E �t�d�]Y�6����aͩ�5t�]s(�� x7���o��d̚���OE1�\E� ��`/�5r���
sk{nӢ��ޯ�V�-��\{���)�OrGU�j1*7Úz� �gi�.�����v������y4�5���j}G��m����<]���y�B����r����չ�VJ���.��t`%V��'}�C� amsW�D�EFN�	!����\n�s����O�;�f>i]�:������H���P����@�7�:��ĭ�3~���"46�
Zo8u�@/j�M
�喟�%Lt5�/�sO����'�~]�4==�8��))�ΝSl�h�k��@y��D��CBF�}umk{7�%�}����>*nƩ�6���
�;�a-)1��_�t9?7��.q����:�jF� E�����:oɑ��aS���C�Q�қ;$ᔱZ�հ�3#l������wʣ�.@�żd�|)��~�Q@,�9�4�}���ޔ���p�/���q+�8Qe~�X�]S�p���"٤t�ӕ!8��f3�٭F'�+UW�(��+�MZL,�����mGUIq�;Ȍ-n��@��[��|<��)�^��4��[�4�q>=���ǫ���t��|�;?JK�[�ˎ���(M�#BF\U�h�=���esB
af.���9��j�$�6Z�R�"�
���{�6mͺ�+����(`�M�r�!wuK����$t�5n8rk�b��D#����;���f�%\W*�ͣ�^�'�O��q��oヤ��6]n�_�u9�~u�T�6��?����u�eEHF��89)_i~�E��Ssf���W�>��;�{}Gm�`��ʤ����]���S��d�`�avޔ&ׯBU�!�G]��@���>x�|�bB���&)������4�=�������Ӽ(�|ع���������9���x�"VR��0��V�Z����|���FW�]/�q�>Z����o"��^ʇs�R�
�8���pb\�����"�U�[�0��[I)�K��aL�U[%>�)j8.=Ј�.s�Y��|ndZۋ�dGyk�L��%
v�mK"(�p� ����`��21u�w��:�{�B��F�92 �-�"l\��y%���n��z����0�R�Z7�����w=�"r5��� ����?�0�|edZU9-:,�CO:�m��vT�.1#rmj�j2���9�l�Z�=o%���ս/�vqg�9fC"��>�3�F#��{rD:((�
�j#�s�����Oz��u�UMO�6�Lu����,R��	]�+���- @}�q�%���ci�zy�0y��'vF��������~`q�Բ]�݂�M���v�E�w".�#֔�b7!�+M<���`}
�8��B���l�Hg.��D���^�bP�������-�����,���܆3�t��#��v�f� ��9���:lVo���$קw����4]L��)�`��j;y�|�9x��>. a+>I)3祽'�gf{jy����6���_k<��H����(��vI�MX�t�W|M� � ��-�]�E)��e�QƓ���Β�����?{T��s�L����XW笺�$�2�ةC�]C,��|���ֈp��
�[�F��#	�IeDd�f�S�^�� Ch�ƏW��S�<<�<X����r��$Z�p�A��9﵋��=nj�Q�Z�S��xMG����J��@o�8q't���>�}��+���\�A��)�,v�<I�$�"o��0�a�
Q9x�6PQL�c��vI
{�\�����4$�s_��?�7-�w��8B����B��W�&4����,�xxT�0edȥ|��̊s� ��-	����S.i]���3��1V��sFR�H�1�|z3�E�$Y��S ��6��U��SB����A�iBOi�r���E�_��w��`��������L[����Vp	S()f�:�����=6��G���Xg��Ta���x��i�%N��k����q�1���\c�S$?=%����X��Ђ+��~���,P�h\��P�P*��~p�6��n��<��ƺ��Uq�Oq��+78i�<�H��L!�`�F�h$(Ǣ�BE�`�y��q����x���]�>�<�S7_�°�th>�vh���C!-/�J/3}�Ag�ALb�z��
�n��,���}�'?S��6<�Fcn�� ~�K�}0�Z�0CP�G�P�HK$����V�.���c�ݛ`A�k�u�6��g���_���!�6i?��`�n���.U�� �S�1���|9v���&�z��G�g��v���X�P�\� U��Ո��b�"��F�����ve��;�f�#H���(���RW�T��'I��zP}U',�9�w'{Y�"A,7v�Vt�IK�S��?,�mc������^B>�(F7Q��>��g3:F�L���V*oߓ�t9:y�8��Z�7�ka�� k7� 	�.�W�Z�S4�h�Ȳ<"��D�O����e�q�����1G[���Z����_��ZL��>�Ѡb�lك�"�'�N��a��xn!�ۣ\��-WE<Ν��kiT������>ݍu�T�Гa)t�2�O =���^�7�l�;ɪ� >��s6�Y>rD�,xu8�$�%#�"sv@�3��Ft\馩y� �@P�?���e�S>��
�#���G3��ݢb*̲��e�֯yt���߹������k�����c��`�b	`z��
���a\�n"!���(�&�[l�aE���jB	x荋�e�8+���v}�R
��P�� X�^��˱��e��>�g
���>�{V�3�H����A�(��mz���Q�G&i��V�n�k1�l����R��<B���P]�
�3��(e:��JV`q���y �Z�=�PJj� �)��ѻ���^�Ә=˩��H�� vޒ��^Q��	a���@ v�Z�j���ׁ[8^\�}�e�:8��IY�=�;?;IԘ��!Ĉ�1r[`]��WA�#�pLX�C����"�ݢ���Ν����A0�,�-��+�kK��0^S��8J���cg���[��&	u��++��Ȣ}�xV��)0�ߡ�
��a4Twmv�ln�'�Bd�U�K���EB#V��8=�&*���]��g���R�����zv�"1]����#pB\.�׽"-o
��������52c4lY �m���,�������_��x]#�+N�� K�L��`��dHs�t�w����hq��-�_8GG���� Fvq�����7T��j�j� ��Ҡ��8Ѝ�T
�o����^�q3�c1z�+E,�ag�Tۘ9C	:"�z����O���c>��6�?���BT�+a(�_]Ewgi���db0�?d�w�8\�l�x��8�vwWÛb�T�I���c��|Ɩ]xq~QI�l?�u�x��7p>6�r��(�r�{����W�h5���u�E�o�`��4�)G���rrbJ�����Xv���0���y��񘸨0Lx^��~d(n*���b�lIy���Ga[FE��[#ٽ[Cۻ>�1r��{Ds��bz2'�ԫ�,2V�8� �DB6W_dT �mI�뗌':ES�2Z���LB޺܈�s4�%J>����3_����d��O:��"ӐC�?,��T�/r��R�M�xH�?/�+U�t��<8k����u�j�x�?��S%$HS��J"xZj�nge覟 ��X�mJ�y�"ר�&��������-a~�d�Ն�,3<'I����!��xN������z\ܘ����Hw�D4�IK!���.=h��P�T��@�>�<E_h���Pk�6�M;�9n��8]��]Z�k� Up�0���`Q$80� ]!�,< �dY�Ⰿ��>��{�D2Й��oI��y� M�����'�/S����5,�O�0��9���\8{�=N`�_�ES�'������BR�'\KP��r��%��l���CT�SqLљ>a�
�38=���պ�<攫W^,��=�����dTTY�O�̳b~@'x9_~B����,Ks��3&���|���Y��Vv83���K�W5�'�N����3w��=h�t;���# ��O8��0�P�:Z�y$�Œ͐qԲj ��z���ة��T#������"��rj��A<5�r�
W�<: z�`�`�ʑ�@���#Zms�L��c�g"8)�h�������l�Bh%� �X�y�x���L��C� �/��J��Ů�h��Z��v���c�n<�N�Ga�ɳ)�N� �Dk�ykNs�axnm���T�$�VR�z�=-����Ů;dL��$����S�q$h>��_�c���Y�N�%ĳB�̏�^5wxa��5m���ܣ+D$��j����P&�e����IqV�����J'jL�H4��%�f��DL����������֌?�����cm+�u���#7��S�/��E����_.���^ߒ>'(k'�z'�����kz��@O���c��x����%�k*����Y�������$�75����6C�*�'Sq�U�t�H�lOn�M� {?ѵ��5Q���z*�q'�:j@xLދ���hL�AZ�X�K�K���#Qs ���z���2,m�L��������)�7c<T��S��Vt�\�C��*��a��P�ɋ�e0���2��[�q�8�T����6�w������$gL�{@���Gۂ����N�O��n����͔����*p�&L������v؍X��[\�TQuZ��e9�0}[��cN����*��A���sR��eͶ�?|m~Y<�Py�k���I�0��W�-7ظ��˼:Ý�ZR�\��<�����Cd|�!�~(m��7��1��a��q��&��C�P��
��oʄ�� k�pٰ��ߚxYF��x�Df��-�֏h�2�ܔ�q�9c�ʭ�9 c�J�Lb@�'պ�A�q��Hu���W[����������):�/��5)�#z���L���i�ME�ʿn��R���fʓ9}��UY� y��RLe�7�3L����c66�Y�x�$}��Uꎭ/��q�2��i�p��F7��;��A��u�����i$�T�.!�2��j���=�?�p��$�g��7���Z�d�_*HO�3�#��=����r��٘�R�Nd��Cu��dk�Q4JF�[M�ӝ��CtAfy��lƝí$�X��>I?`gŗ�p��=k��6|P&=����r+������uR�'s��j=�ëN�-P�7hm���r�Xnd˒��"B�wR==�B�
vs�(0)�X�#�N�Ѽb���Ǫ�q� fB��}A�O�f���ڎ��
z�Q�������Ĭ7�}��Q�@"O�p�s�հ]z�g�wS��[��-n=�[��Y�F<"
s��	�̝>��su9��@����U�q�!a�x9L�8m�!u�X�g�K��f`�C�!���J�ʆcKD��GG҆D3����+����&���A``l[�9n�{u���NX$	c�f0�����䅬&�"�0p�cB��0	�>� s��
@5�k�Q�M���a_O{�@/&f=�j˚ZL��|�����}v~N���uR�R��!c��,�l��H�����f�ԪG�����K�d�OF�����t!�Q�םA�����c]�����t�-\��v���^�����@�5)�@�g���p��3W�[&>i_����	�T�-/��~���ī���EI������Fң�n�m$\��ٸQT�B�.-������zk}��3�z���ux�@���^�q4�ȈƓ����A�!�l��n�M�
��'$�����ZQ�Z�������[�c{2����9w�{t��_�X�F��N�'���GC>��w'�	��9�KܘP5o#1e�W�����$����#@��Ҍ���g�U�ۙ���]s%�3�7�6��Z�M�!z�8b���*RY�m���Ome��UqŴ�����WJ�<:���bX	 z0�s�y�Y�H%s�sS�wh��h1~�=%�����Cן�Of&؋��}�mh���r��^>e���x�Rk� Y[��g��f"h��{��O�_�!�����1��*��+R�;��.�2X���[0iԒ�0,���S�iYg��5|W��h����c��=yhj�U��T�쮰7{����[�isg��Q�3K!��Rə|��|��i�a���}�a��ۯD���c+� ��W88ZRI�{,��1X(g'v��S��;���S���3�a��gU�kA�v�@��`9��7j(�n�ݡ���i�I�&I�"��F1!����� �J��gͪ�O�5��K)�{4�LZ�������׮W~,۬��I���}t�b� 5y���zHIRܗl��|�͂c0�c�jSB��4}��/�2����TDs��J�f�w!��x��龍.�]p�m֧��߮t�Hb����M��~�+4�M9y�D��^,碶�s<�Do�ekꢾ����C]js�{±+)�_�Ҍ�j{u��Pm�&��ױh:KΞ������lW	�M��$$G��~�Y��C��/�����%�0U���;�©��J���KF�k۰f�ܟft��f,1�1��u����M�T��0+s��G4�B�a��攤$u�u?A�EtG�s�K�������c�@?c��(��U���� �O!�P1���9Љ7?8����Lu�%�.�����~�!'L���dªB���n�8�װ�-Vi�
0dc��]!��%�H��8�aT�va����`���mn���-P�g~ų�!>������"n��7qXTw���H/8��D�C��@M;�u��w��Q�����̬����b�auQIKx���{�v�ހ�{�>1�G�n����'�^$���C�v���Sr�k|����ށ�mnj�)7���%#����~����.nf��W�K�����6B���Њ0�ƻ,�Kk�64?�8Y�J�U��.s�B�/�i������\�B�h��,bK��Y�`+�ǥ���O���s��@ώp��JX=���OwʴJ�� {��/rA��^�G���"O5�Joꦮx��Ko��R�:i�W����X�̦ʎ>*���<⦡UW��}�yU	�j����>e��Pd�:lo�^�R�m�ǥ�5�IP�ԁQ�E�Vԕ�>L�D���F�`ĭ������L�F�m�^��3��S��-�Л��e|[�n�y��}�4$O�����ھW`���J��O�Y՜EoL��3&���S���g���j�7����h�ɨ�gx	j��e]KP�އC����H��1���ߦ��=:�G5�*��ʿٸ �韋��5/��b{o����t�iU�'Ĺ���~z;v��5DEi$W�;���)����v�7�����|���ˬ3��b�\�zfQ��5�٠��!Q���,&�5��3����˫?���y�c�i��NAt��FQJ�|&$�l���2h��y6!_U�����EV��� �P7��:yAh���`��(s˒�Z�ʷ$āi���@�O�K�英������+�y	�#n{�T��C`�;:3���9�=캡����,pfP1$z�o�!&K��gm�`��*����\��f��ov��u��R ������#t�S?`K:�5�7��/9�<��������sJx���#�	5�z�4���/�	X� "�/�9Q�Ulm���1��t�=�'��$,^�Gm�(�>�_��ZOu|�ꑪW��4
e������s�)AJCU呹;�1��b`�@�^�J%}�ǴLn�:��cGȎϞ�^O^���;���3O�6�5�b� /r}o��Q����&�N>��i)z7Q��Y~m�\���(&���ů��2�˚&�kȑ�9��Y��O���.�we8�_Ȥ�Q�VM�5�3��bo�ʳ��:w2�&�@c�7ᬎ���_��a��Y�7��� j&��4s.��6)@U��YqI۩��t���uJ��i2�k֏2{�a��j�|��O]l����`�пnK��ԍ�����.2�����W8�>R��J���%��d�����߹T����T%�-���\��#�1���c��VU�~�[6�5`/�2S=�^��0w��h��9�J�4�ʞh�x#��̹���K%I1N�(���W�,�#�{�����V���b��d���D��XU`����4B���A���i_`���]@����]sIpX�s�+�Ϸ%�������}S�l	��(���qb���G�e�$U@��#<,d��c(���V���.B8
E&������n��s�j\��eh a���z��Ol�g�������Gϫ�H6��x��5�6���!0��mXquHS��f���B+�G�-Suo|��B'oڍ�`�E�m�~LCrOk�8n<V��ȥ4&]X ѭh�P'�l��3gB�*�P��Sd�����ڵ�(�[k�()<l��J��k��."ʮ��~&�|*r��J�S�ul_�/��j�KC���p���U��z?A���%˂�3"�nW�CQ��&��<�ǅ��l�PQ*@��5�j1x�k���T�sq��Z��{������͞�W����X)ې����rC�<z�c	`P���_P3��a
O�|�K[!��H)�����׈�\<�\� �F<��v�,4��j]W�`�:�ƙ7���.���X�~�� З��H���+@�[_�A��{p�^b乡l���1v��8�T��&�4O�6ʣ.+�
!.A��~O+�C�_8e�
Ik&H�)��pp=��K��+4�[���4��fF?+�w����Ӯ�9w�T�7)��̹cQoY�
�¸f�j�4��SήO�}��3�V(���dr�2p������S&̊�^B���PDE	��R��~�B�vmX��������3q��g~�M�;z!�>�ReY�{�@��,SaL��������(Xf�<oh�Q��%��2�ߐ�lD�ϝ�Y�u"@�S���f��.S�{.S�猛@�]Z��6^.�y,�f�����`�d���z����"� ��"�ݷ`�����-)�e�^�(�Q�f�����������; �=�K���#m$�dɃ���7��D�=��O/{�+5~qEC�p)�����3�S�|�;*k�R��4j��s
�a����Z���l�Q�E%�LG�)9�ȆX����,��T���?{7�1�-���)�fr	�=ҹ�%��@w���_��n���QQ-"�����>~�w-&�PC�Ӛѫ]�A��;��練��s��Kj�Urʰ��lrM�x�N�ϰW�f$���,�U��PIp��Yv]\@)
�R������n�#�]�ҚI͹K�� ��LI�([�q*It��)|@L*�!�Nj���^����C%�$Dt�$���Ĕ�DE-����:�}qq�Q;���@�6�q��j0���/`�0�������Տ��69s=!ȄcwA�'�w2=���@�!mgG�Rl��
�n}nB�.SM�O�2�3o�"EoY6�>�d�7�\��Fu*J���N�M� ������.͸i�
�����R7C*uݨ0/_N�����K�-'�O�������)��Vv���&�Л�9:c1��T�S��X&�hʹ �?�nt["����'�������{[ֹC�C#�&��{��C#J���ۗ@:��@V!}WqTvW���GCM�F�A��{��W���Ϣ��ߏ�*:`:�>��#]�ӷ���xt����Z�ai�s��}1Ooz����7<�x����#$��|u����R���q&��	����4,�/��䦄���.UnHc��`�W��Y`?O^�$���c�P�8�Y���7��Q�n�H�^\���/�P�Y'��6�C��9�g~�7q�::"i�c���G���f���a�`o���0ɣ�z\�W�N���Aq�c#�E���홯�"�xx�>�� ��āf�-4<��L���.���?�����f/$H��.>����4|d����J�j%��3t*/q�H��y�q�
��S��$S�ɏ���j"���/�K�>Es�&��j��(l�^1M�V�FF����Q9�pv�� �����rP]��6mq��Utg,t�6(��.�^���}_{�h�}��6*щ[>�)�؛�J!�&��E�.�'̾�~ae|���C^�� ��?��y�(���s�s�z�j`:��z%��Yn(��B+q T��GI�j$0W�H��G��"y����>E�P�N��v�w�֝E`�C�;c,�#)����U�Yπ*C�%�Ӵ�N.�Yx�� ��m���w��U�ư�q����
����7z�Fu%-�LX��Sj���]K�����x-�m�y`����U����rB����_�Fv����19=�z.څ�kVζ��[�FnpN�ըמ�C����Y�_G�§��F?=����H���p�=5�*�m���dC�ot�pח��QnHN�]N�V�@��[ C����w L_�v�RF��a�AC:�#���k;�)~����)�,��8�*U'O�݁&��2��K��U���r�H�?�prs�.d�~[�M���v���E�]7���+y��g�X8�o]�B���>?�� �dJ}u���9xt! $3Z[W�w:b���h�W�'�6�`�/�����~Xo?��!�65c�q'p�V��F�8��-T|�_&��ܰ�h~��}jҶUu�7��$�����r 
/�?��xs6Xe0���I� �sWG�tXB���f��]II��2k!S�@�^�Γ&��~1�D2��je����ȼi�~%�<޽:_� ��^ʸ^K&ཿ�����'%yV��WV���`*gk@~�k�m�㬐�l�c�t�>�;�m�T�[q��=��@���j兲�m��v����a�HhLK�n� �5R��θG��J�����L?'��#��%�WTuV�|�i6uVq���?��Ed6wbg�ad��:�����[�N|�4d�0�\'�&e_�AcQ$�΂t��Lb�%Å7/Xo��f�&��x�[�䨙�����xQ�&H'6�P�Y�ɴ$j��LA����x�9u^W�e��*�98eF�K�����S|�pU�j!�_�6sz���<P����$�H��6|я2�/��oG̛���0�wۆ;>�/ ��3� ?�9������F�z�=�<`X��,�>��׬u���;��"Pz�.v��	| +$��b��x���U�缦̤�o�d�%Ә��+XI�9�{��s��6m!�v�;-��-�\J�4�.0�n a�UKؤ�9Qk�Zĳ����.O�6��E�>Θy�b�hwp̤�1R�\}�	v/�� B*)#��F��0)�EL֮\�K:4$�5�s3������z/`-:�"}����E�����cPs\��e �Z�j(�y|"���5q�K��I_@r�jo�Z"�	�6�b����{T(��K�3uHf���B����}��m����^�$����.����q��	@#�*��<��8٭�R��/L��5��2�X��K��Ur������
_�J�T�L�b�r���^�]�ŵ��{���U�破_Lyge� Byyw��0�[�mF�q��u�񌈖�\�C%�"f@x��wɌs�rqCڃɑF�	�@�vق��OӓK&�~
6��Ԧ��ךT@�ɚ�9�I�9�=��eUHt��ũ��a��Į�-�8�ؔ���y��r���������7D瓔b�B���b�n�`�dXqF��%:����Y�^�����]߷�������>�W�X�GUaf�g�4a@�ѕ<e�v(,̟�na�gu��k�w����,��o|5���AV<�^ϤP�?���62Pn_�`��cؗ�h����
J������`b����f�H��p}��{�͘휈K���#aW(vO����ܢz#�s"���*R��@T��(P��\^�!dö�� �;�jRE(��!�������E��u�3|'�ێX�.Kc�d
��<����$��/�MB�B�s����O�l�to-��������U�������0�I��SFי�B�/�)s~&w�|�@.�gVn���O�w≲'f1=<	y
����M��4�j�>J�^�A�$�V�B��|yV��k5K�<������#��(�f���	�"�Z�3b���2`E��]9߽"9j$ا��#�l�Y����b���8|�>GA��q�g�x�]���QV��w"�֑�� �z�歭g8��"F8�<F}7�.�k�^>�a��rc����D
�(Z���J�/�aG�&�g@���)v��{��]����Qg]�=Ye��m<��V'�:�%Z���Z<���S(�s�L|Q�sW�(Bd�ڸ�E��yC�MyQ�?���8/��Ƚ���/�_4Uly�cz}*������N�(:�{�$��
�	>RR���`;Ys��c���Fjw=�ec�L�� 	h��n�|ڑ����ɬ��8k	���wZ�f�f��r���J��8W���L��q9��Z����=n]���æK9���!��D���¿L���u���S�2L���#�Z?
��DǦ�E�v~� ��R/]+�  )J�u�4��@�#*��Gi� +¬�v9���XO�գ�(_�F��qq�y�+/����XK�-刡���H�$��M�d[W!��Bp���Xj9�jQ��cfG�)"b	��p��pF�J�+O`�H*G��O���;�T�Q�P�`�iҰ��CÎ��"�L��Q�����8z���$���Q+�c ^��a��q+���!���(���kز.�Б]�B�*y�o �zcW�0'�2�J6x���f6�}!RN�ȑ�� �v����Pc{v��"kk�J�Kiz�i���#~���Ң��9�I�vY�=ZO����gC�W�l7�Hc��*Gw����u��n6���d��>��ې-,��>��P�N)3�c���5�=*���d!?M�� W
���{Un��@$��=b������ߋs�hO&sf�z&���TBJ�x��t�=������~����;�2��Ź��+��0QN-��}�A�%�� ��5�@�$�o�_6���t�9�1�Lnw��m/Hn%��"���\T+ZA)V~�ݬWӞ|�̓�2�У@��]5�~�Ţӯ��+�����Nh���t�zU����z�K�컲��ZR�������KgL����J0��x��:+�dr�����"@`2�P~� Oh�v����d�t+�򲍔M�A�=".K��j��p�| q���˅E�L"���3���$�
�2�Wn�%6̂�'.�����|�ҿ��	����^���2&ߵ�^��}�5�5��f�r�x�w�#	�i%�E���Np�����]n�Z�D�u�h���ߥͥ�pn[.{��@�����������y��-��W~�/J��Ԧ��;���'"򴓻���6�$Ld~����掮Yt�ʄWв���d�W@k/�'V��{[��?*&
ơ<�؜HmP]�e0�T��a��c6��3	���o�}��M$C����#�xE-�|��v���x�Ҝ,*��f@��@����<�¾D�gԸ���	�}q�PH�=� ��lN��%,$M�����!7k1�3y���V�3:�oG�r�=�%I��3�B�� �<=U-K�U�(K�!v�m�n��J(�O�9��
����x�黬����n㹩e�cŔ[��bd�$q*�$.`'��q�ء��mh��`�I0�D����;w���|��)�J�''�p��y��l�����������h
.��Gm��`K"�����v?�M�I��I�FR"F�%�ذ�~��=�[J��<�v����KsQ==-ExP���f�v����P���7����quBτ�i�����q�Fr���8�M����$P��^}O#3��pV���U�B]��rlaj���24���&�\N�$�8lGW_F3�m��[6>�0kC�]�A��+��wǳ�D��S�Z�5�N�����ID�j��)_��c?"^]�\K������Û�����ukklp[�g�r���)��"Pn*	��\��0v��R��Q}�)Xi(�I>D���+���� ��0�T�`�-Gq9ܨ�~X��#--2�Q}@(�%dH�݆� �}�q�?�#'���t8��Z�]ё�r��Ěƺ�M�v⡨�:���ډʉ�x�eN~�;�l������_=�;|*̶�Pu��^�����ne�Z�@�4�:On�qU,e�u_պĈ�B3�B�l���Қ!1
�-�ƭ���r؟bb߃
�A��͖e��Q��kޫ����t����L{�3����~.�Ԡg5~����K��8�zVxW�'Ҋ;w��uvf�/9J#;'����Ja)q�l2Es}pFe*.'�ը�'�NPEڇ`�����$��;j�8;i����K���Sz����րk=�-Bh�G3�D�Z�s�gh�O�(���K�I���#���Q�b��(��#�G"6a�=-�k�7U���\��xɻ&��ݱr�Uv�gu�y��c�kW=iCZ��o	��v'�*w�C_/h�F��K��,�=bK�/Y;�� p&:�|h\�(��~��	�V�[Q�\a����_�ß��H���!��q-���P���`�ƢLΞ�KY�@��nȰwqr�5�� ��-�4%z�V�!�^~��y��0�ꪔ�m����/�����$�����]�bL��Hz61G���"��ʄLA�C�%��Ո昛w���w�
��U0�1@<b�4$VA��
��e�S���i9����k�J�4��0߫79����E����Υ���.Qf�!����k.@�ߊ�$u/��"a0v���뻀�J�w�\�[_2i@��V�H_t5|�V/@#׺!t�`i[I��K�|�j�峯�<$ ���2
�_��̡����@){�`#��86 yQ8
�U(#4��g,rN֥ػ��o�N����ml���M38'QER���N��f��Ha���h��v���*V���{�y�眩�ԏ��t_��[O�s{K�2���D��ð���6*F[���6? ��i����@�k>bU�(��FR^�Sb3;������!��n7��~u)���V�W������*E��%䩬�R�tVg��M _�����b����,���-5+�<�b�C`ak�s5�~yw�C�~rƝ���%,g��ཋ1lt���̲���ɘϵu:��(��[Q�B�Z|Wi	#��ΐ�rhB�E���\z�4��,�]�}9�M���2%b$A8/�r5�p<�Y���R��)�Z���Ο����@�	�t���Lr\��g�����@�l����֐6_��ꕬ�:!�b�"4-����\²�9�?{��=S�fZ���扦�v%��ώ�b�'�Z���_�yab����yك����1���'�; %��sy�ƔI���.����U[�o���M[�2�-��y(C��uwz�Q���u���8AvQ�j�
���z&����Zw	��K�? ����S�U}tP(��n�~h���-9�W�U	j��/2��%4/~ym��y<���r�DH�sn"���_^vw2����S27�?gC �X��f1�ٚ3)�H�j�,��==�sˋMw*�եOG���6�������u��Љ�Zg�y?�X��̒��n��9'@�u�����O1�ɭ��0=��"�}��S�"(^j 5���z������e}��6�2��F7�E���'�Wk^*�~����t㒤N�G�T��3o>	l�¹	��n�����p�����NQ�0�łN�{��@f��Yi%E��L��,�NA�>���t����4�#��у����􆱨s0�s���T��C	�ͦ%��%WK_.y��G�x&�!ߛ�	LH$��������3�fܐ�tg�0�@9\�\�����n��� -^]6)�P�z�M=ȶ���&��H6m�B�#S_�� ��;H���5b�e| �k]>�|1:�t,+�c�P���Zw)���Y��s?{n�/��/�\�6L���;��Qe"�(��S�V�_��d���>�ǯᘺƹ���o��ov�;y4��-��xR�e��u�J�;� �MI0=�y���������j�_��g��eyN�4�:AC���8t�m�6k�������>�s�w��x�&79��R����Ux���WN��S.#���m�y�K��_Xf+�z'��Efx�����Δʏ�����iSKC�� ����oKp�@;\z�YF�q������>>���A[8�E�7�?D:����;;r`�l����W�kŅ���4+��>�=+��fB�	�P�ɓG��D�򩸖��4�0����5B}*q������*�Jk�%מ:�����l�?$)u�r:�G�yD��@+�]e��=��X���	"M�=9k�;݄��MH'#�Wis��X]_�J ��Sa*�	�&�'�:��X�JlC�Gyؔ��-Z�s����T��AƆx�T�a4�<N���6c϶��2	f-�߫�J�"mi�B�+l6 ����
�=�ߴ���.a��]<�a��"�w�F�2�wn�:-��@�c��wTt����dL˰�:?���&�&Bq8`�� 	�j�&?�]�s��[�^�h`j�꙯:��	QY<�_�i�<"fW��"7��~�M6e�D�~d,@K1JU��A�(f��{칵+s>*_JtrZч'���ҬD3=���&^�VYE���5��/x.���!�w�ڂ���nS��	���<��MR��1����X�&�lY�i���1� �*#+a^��p�Ր�W�w��n����w�ngG�Ň��ćx�z��崥x약��Y�'< ���`ٟ���{S#Y��VU��ل;�fB����C=�v~=j����[R�{��
N��qx�A?�K���%�k���@FS�z����l�!���f��0��NI4q7�����˺h,����hu����5�oM
%;ۮ���Z@W��/�R-��l���`4����3�x˩��"�?�$�CĤ����Y���[�oݺ��q�*͒\B�y���Y'S�&�.��3�|ek=b�f���LW
����L8�1~��,]{�t�E�3H%r0�$.D��Ԁ���&���,�?%'�:�v5
���\�)[���2�o�_�/Թ@����K)Q��{|0T�t� ��$8O3"QI��g��vR��gW`�
�A\m>|*�K6�0�R��=#�D�?�ř�߸t�����_%T�[����3�/v�*����䲔Z�Q08���ʠn�����Y'�g9��7٢c�u0���̳or)�x}۔�
��`qw�q�ʈ���<��?���Kص8����[k�BT�������F�F Ͳwqh��>k���=F����.@���r
���A}=,���5�6e��}�B�a�FEL���� �y�g��ڔJv����u|-@��m;�b�T~�a�ĺ��cP�UC� )c|����:�QI_/v=`�hj�%�C����IU��U���|Q�C��cIw���m
"���	�ꡪn�Hw&+Qc՝�g1_��D��E�%\�d�|Z�����87B��Uɤw@i��j���1��+���Qm�DjH��N��͐F�&�ӔWm����.	���������4��@Z���`q�|sa�b��]���I���٫#Y�F)U��M���������)�qy
]�W��"�B�N���v��C��%���g��,�����~ Tu�����'G�!r-�p��'HP�/�Ѵ��K��\��� ��iኋL2�d�؜M�$���/Yw�z$���{��L���A��9MY�j�5h?�#�����@��оa���?��c�T^*br"����#�-�"�
,P͐���K��f�f�M�ҩ�*�d3h��K��O�\y�?f��B.͠	�
Q�N;�veBe�~�*qm�a ;	�w��o��~D��g�T��RM�\c,����G��2k-�'V�������~�\�+��@J��
��L[ �YG��er�9hCv믹���U�1=��%o�"�8����5<v��c��d	���U�`_��8:�\ ���'A������&\ko�p;"��_��s�#��]V�܆�)<p��Q��/c���Tw��l�<(b���Ё�w%�{�,d�B�y����joo�7�²�I���Z�&����TKt��l�wǘ��J�-�q�4��?��z#�-.���p�T�-׹��S|1^/�2f\�+8�	Tn�Ӟ��e�N�t��e��:��ENo���$�Z�Z�L�⿹�"P��k�x ������RS��eܦ�u���	�]�,���r���ۮ-��/����;2k!�'5���Eo#�I��a��/���ӵ# �+����N�ǟeқU�3~�b���U"��lӓ��4N��Y�[�q���� �?K���	��N�:���2���)Ә Y�����o]��L�r��3�c�շ*�j�(�>���8�3��V.K՛��;cX�h�v3;{в�'.6F�N�D�A3ܲY�c]�$���q)r����-��^G$�NK	$.>����:YK��Tt��ٯ3�5hv�E���4�d}iX��h�ݶJ����1�	2ޯI�w2^��e�,��[|���v�Q�}���$�f.���v���,a*{�8�Q��Z�_��X9'��l���Q��𐇎OmGl�j@��̦+�H�~3����d'�Lm����`�����2Z��_ؓs�X'�3�h۴-4�KG@X'�-��1q>���墯�j�x���*�L��G`�s���ӊ�'R�"��T��4�:0����2;�:���r;���J���O����h)�8l1��3���m���N���H�T�/)qB4W�k�m�(��m��bE6�Q-n��a)u�ܥ���N�\h�T��׮��!�A)�B�tGW��^�^}J�*�=dA��se�(r�ך{��7��S9����&�?��sF�ݢfl튠�7B��vZ�H�x9=�",t'�8k ��=,��c�r#��1Q�rQ �9���a}ٓg�#[�.���L������t���%��]�ɍ�-�y
�~�k��q��Z��#�o��!o�_D�)Yx,4I|q>F�����SRlAOpH_���NF�+���T�����+` Z
���Rt������E�ʆwW��#Ԙ�m��;�����������:�*F�����>"e��j���L��eߎh��3� }GP>�S���	���s�\���U]�ñA@R���a��P��hٹ�p��=X�-�ȳ�7��ڭ��Y�4��i�:�  m�����& ����!U�{��g�    YZ