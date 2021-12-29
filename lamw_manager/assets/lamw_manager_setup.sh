#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3293518868"
MD5="ac1d6ac9cb0d6ed82731d64343989bd5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25484"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec 28 21:48:41 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���cJ] �}��1Dd]����P�t�D�#�E�>��pҕ��Dn�v��2WI}��or������'Yܙu���n���+� �ա��5UL���c��z���9�;�������u��$lx�1@�0| 㵖&:~vk"��l'���Q�﹆!�����&�f��M�WE��c�y�.�7�R�ֻ�P�&�ܩ�j$�md�D�F���-��z�}��v���9�3+E�F����B�6��¸v?�N�+�i�W��~F�N,,��]1�;2V{k��r���Ox`"e츦l��is���*�l�P����=��1iC�g>U�)�4-Uq�"���E2���Yi�T̓(	�,�W���z��F�j��83�a����)��,?�6O������Y�ԫ��]�
S.,�c(�Nv�"jo�u<�췀���9���O���]ajGSC�%^��n3m�`�R�4�2�m�����H�u۲-��G�f�ӗ��Ǘ��]�`�@�ǧ��wVv�ĺtOIg�fd�x��FT����<"�����c\5��;΄�?H�Z>����z����AC�B�� I���Di=�]� �[����l|�z�_�p����Cr�P��۬���\2!�8&��^��֮���	�5�JGS�j`ZvS�&?��uM��϶u��\�qI�Wb�Rq;�ճq����ش�6���(�a/�}������hJ$��%�+�¶����S2˴u�}�����v�:��є��g�:�=#��"^o�u��2� �����O�B��HOpϻ��Q}��5l��;s��ap-9l:��D��?Ǎ�]�6t��doL<#3ު��V5���4G�Z?{}E;W�Y�ڂ�I���6�Z���Gl}ّ8:��=>J�ޔ�Q��`�]W�EE4jsW�g;���B�=����r��+�o��=;�ح�_��f>��_���;��H��I^�̚G��eXS)Î�,�7F�I9���SyZ�7,��p����
$\)��翨Ź;*>�B.�4�l�(R�"�D�w���]0�_��]��/��p@pBZ]��~�G4�����l�E�)��p�L��=��ݘ�-�2����`��Kł����plN��NPN$��W�k�<��ޏ��(�=w���
�oB@י/d�Y��j�y��A$�R"��Ge!;C�B�������@T}��7�j�ww���W�$؎.E�;���LH�	7��K4�P�5m��D W�Z( �_��,�%���H�9+zM�By�z�r�� -M��z��5����,���H����U!��$�,(�tz��i���|~D�]C�EO�j�j�`n+�gt�lѬ�8�q� �_���>?�M�B�������nx.M�uk1��}�[b����)��!�E�=ި���6�DF������])���8���H���]yi<���'|�eC-L e��Z�d1�1���@�U�Q�(��8�y7ܽQ��z�%���b܈�~ ���`�%&0���^P�<���O �YM���m��lи��Ȝ��[�)��A�cAXH�_�[N��Af(���e)"�������OM˷��גhJ�Rˏ�bB�yE�����-�[=]�nUl(̦�Ń������*C�����g=�0�x��#�M�Ji�uh�t߮��u\���?u�Y���0_�Em��T@������u��L������/��H0��%�L�1�^)� ����L"��*��N�����*7^�-ps?�o�S�PT/{�`���뷹�(�PW�Le'�ڤKޠ�G2}�T�q�C�|N��r ߜg���Se��X�`l�B(�\��L׳嫐��H�#��5�~r�t%A6E��c�X�('�O�æ����_��G��B�ՍW�A
aZ�ٕ�r�^ϸJ$gz�b�A��ùӥ�Brx��}U�,�܉f�8Q��^�9� Y��̿Ί,T8
��)"�@JE:���3i]7Y~sm�Y
�+�/!�c���<��:h��[_�*es����/�(�L�0m��y�s�5�~"X��������'����sM�7:�oں�Rlc����U<�Ax����'^�0P-�,i7lu��PZ���o�?�h����� ���2�y��㖋*���I^㬱T,�#dʱ��h ���j�Z��vk�_2��!v	�^A��ߥk��f��>����$������o�m�_1l7[��V�)ӌ�"���V@��{�1 ��W�֔��uv��ɉ�.�'��Yn�
�ɒh{3�>NR��w��d�H�đ<ۄ��di$���@	*�:w��G��^��h�� �31���ZF��$fc�.����i�M����R���	1s���O�e����g�֊���4�V��5�L
n,�f S3���bR�|$=�	� ��~Ve:�0%�6���˭�b���NJ9���Y����Z�n��q-O-3�<�:0�{B�]�C-gKjȨp��vX�gscj��"d�I~��3[u��~��M�0���`Y��h��.��"��
��p.{�Eq�m_�Q�Y:��T4�ŉch�xA��ޔvO��q3�2>J`�[e�*|3�>֪t�ԛf���/ex���s����R�y�ʃz,�0	�Pנ�0��MM��������u|��������01�7�-)l��8�JO���"��HoBg�}?����4V�������Z���`���;A�a�k�敨� �Jϭ�.��\*��%�_8��R��3Y�2��]�z���	�H����Ni-�r?L�^��j��>rI�vkW�/y�ȱ�L@	O�˺��q	�)��w3�d*GC���:̛�U:)1��?j0�����y<�o��ͩ[/@ �nM�)����U,P����S�������
���$�E�7h�;�����h�2����~��鴮V����0F�W�k�gz��ܽ��"�%��b!]��VHR�$��+;�D*��|�o�����1�B����xL�r?�n���#���gTO�J�V8iH�Q�$z<��Ne:���]���:�d潌zl����9I/��r�2 A�V9���3����I�̪������n��C��{^���S����As̉�/�&�:T����w|��d�~��G�ѩ��8����W>P�,����<U���j�g~�{�J涙e�@�=���dAS�T}�O�m�.@p%��l�B�i,��p���v�D$@	��-5�<g-�t�HX}�;W���j[v���B=�_�K�Ϳ$�moJ�ʞ�1�LG��Љ���
�5h��v����8�Չ���cr��i�M1P�;�
����g���9D\�}�C��Gf�s�Ng�����>�'�p��81o�2�v �o�|c����&"��- N0�a�@9i�a�JNOV�����N�A�&��b�p-'�YXFv�>�����M
�1cr9��K�~�87��eM��E������g�?�0eI�(ZYB|i¢�����q��@ܱk�H~��1������i3*��:`����˝�j�5m��"��a8bt+)�2�H�dp�@s����x~٠���$�R�~`8{Z�$oЧnu����e���3`�3�o��,�y^E-(�҆��8B�v�����d�6�y~ePm���C&W�+X;���n�r�$��>f]��6\�[�j�Ͳ)�	RU��p^��M"�a _�	a������P��-�N������՗p3	e��^(���ݼ����CW�e�<,�_g��ohރ��J��}���juRy�ё��1�j��G���%k�n����w/Q��`���$��v]*�͍߸�c����c۟����d¿�k�����T�3��iGQ�C�	�:�����_�����X!��(B�$�����4�_\^$|-�hj�	kЬ���=����4�^�H��ςו�-(�$�k�p�Җ{�
b%׬��0�0.Bt&l*��m���s"���¸ӋGB_;��p|�����g4I���� ���-�IxS_��%��ܒ��*���є�2�$���M�2�.)�wV���-�X8��M����9괡&�|�����F$d?9��A]�F��F9��ND��y?O��>Ѡ^��61��X=�y%�+s�Ie��Tmh���xM�0�t�>8���x���"XF{X���(Rsc�h�C;��%JK��-�5�Q{�r���w���O��a&�,.�bS�}ܸZ�O�}�<KNؑG����*8m�q�r�a��Tn[UMHO�R��麛T}$�p�էP�R_�(L��,�(�fEM�&��I�M6��c����
�z���QՆ�=u�<E�U��3A�N	���@08ݠ�.F���7���������&�"�|Qma/8oW]�kM��׵r���g�F�����{��Z��c������Ό9h��;u1���.B�8��I�����*Y��맜nD�\����z�[p/%�q�Z�����3�O�]�ȍ�D�iG���ϻp�WiO$���<���f�����y����k��;d=� O�j��:���	�9��
�eS�@��-r��W��]�+��0ռU�Ϧ4��U��Yu]]#q"�3>\t���r����U�4������CWuwƿ�_�z�N���Pt&.�8�x�tb�t�Dor��aT"uܪ�coV��ի��-�����Yꖚ}1�U�+x�+ݰnZ+vi�	����>�q�	�$�"g��@��CA����%u��{ڛ;�{�u#*M���������%#/�<� ���h~���1ځ�>�KJ|^�����9������"$���""G�b��U���68���J�m�F 1�w�$�]��9�]zB��y��2�	�5xI�r��FqM&+�t����!���z��鐻9t��-/a�R2=���Θ ��4�UW���6n.�I��W�($�`J�z�M�@D+ֽ+I��տ��P�t�ДQ;/�co�_@�tB&)@PYK���-&���eQ*hT�P��?zI�4�[��7�;�V�R��"��1�xG+3vw�'{������0��1�춮l1�����b�+u%)Vj��ǅ�`����-���#��v�U��F�=PFț� ~@d���T�ɶ�=7�zFBV�� ��H��#�T��7��<i����4��51,��5����%�Vq�;��t>��~���0����N��\�s*e�����B�������Sl�/H�Z1��u���N�@z"�W���3 ��\?�`Jg8�r_�rw���Ģ:]7��`�R�u;|`� ԫ�qP𗅐�V��x\��D�Y=�ø��,�Wa`�͜)g������~���"�*���
�#�[���h���,��\3v�0���&�#��$_��z'^܇����Q����/~6�O$��~��nIE��Y�SF5�G��V�/���0�)�^����Ua�[/�gisgQ�g�\">� D���H�t��R�X#�|�ԥ@){4�L�8��.N�S�}?�>orY�����F�&J��+�Mg:nHZ�A�d/�>��1<�2B\�fjڻ�o�*�:CX6�ls�1�& ��P�eC\�C8�@<7+��6�/���[�ZlL��fhw�:ɷ��kA7��ܾ�0v��m��\�R�N��bS^���c��0��M�?|W�o��m&:�k91�KZP)�N	�ሮ�4��q\��ʒ=��%��q�y/�֢]X#�qi?�����n��p�f2����$(��s��=[f�� 
Y��c�1���v��� ��o���?9���m
TC��*�t޹�6�:�@lD���j�E-hK�㻰�g&�R�� uq�J~��T����M��	�|�q)L��_�?Uw��S�'�럄;\si�x�`�ϙ��֧qz~U���I��t9� ��|������N�3�^�<*�Ϻ�;�$�7~���,C�{Y��-�#F��þxdv�VƱ��Ը�(ri�pc������R1��ZT���>J/�t�u�fd���M�l��)���f�S��� ט�K���\(����U������$0�>�zL����~�->��;}��ev�h,�0b8�P{���j}�*�=�z�}j\�#$f%���OeF -��p�������Q-�M�x��K�QR.02^�6���� ��֛�q��{ݱ��bdNs�"+$۲�����s�$�W��ž�q��,��O��O��c���k�9��ޑ�A�
����ؼ{5�p��;�$����q�4&W�>n��Ϸy��?X9.w�v��j�,q6�s��i�م�GwPk2K_YD����b.%�����V���#�Y�yA �rY!4���z���c�r����%<.�i|І�:�����r<�/B�~0�E]�($�]�Z�=���N5Ə0��a�s^f�U�`���}%���xQH��b��ڹ����s�.G�L�۾v�d�w�Pp��Enl�o�~��˰�	��~�����P�8�fÅ-�bg^U��%In1_�ܪ��2�&��e;ly�J���aOt��.V�]��V�rj������#�_�5�J�pk����+�
���8h:s�#,%��(��C@��e?��eGK�F���H�C���aX�X��!6�?\��T�l��X0v �/C�� )�+C���a�>Fy1��@J�ui,�#q��EA{�
36{����x@X�:e[�P�����c��"O�* h*�1>ߥt� Đ{ļg�D�oF���z�_��.�g�2d#��TKf/��_�o�ioR��i��>su��*�t��6C�)�tF�!o����Cڔ�Y�`�v-9럂;��%���VP��i�֥�|T��F��q��[��b��W
v��d��6���JY8�ف�M����J\�:��Ө\x�b���n�g���w�v����r��W8\��j��{�pЊ����͵���).9(d?��? ����_�k���7��W �_n�$1U�z��s�O8[#���\� �����ɍe
���g�Y/5�`V$�λ���N;Нr���/"4��i�<R�љUN��B��� 1���[vEʷ��}�ՔQ�g-�����@�s���3�ZQ2� o��z�,Ѥ�A��i�G���E�]~>���d�Xv	�(#d��;������q��0t����#���֭��-b�� �*A��uC@�w��9��Uy�)��"����#I�p��A��ђ� <�S��־���P��rrwb�{T�5Y禨�D�aα��2\��������e�Dj+�nW�D2�d���L�9r�l3�;\�*Z�{�a�ʩ�d�s��U�/i�b2W��ևsQ�n�;]Vh��^�TsNj���s��E��P�ڟ�$�����F�i�J�ד됵q��2�r�B6,�����aԞY�3�k���糳��������_ضzl�=S�n�K����uB
��P<���C�K{^,7,A��'�Ni?�FkT�+�D =��׬��x�+��P�]����꾭�	�bO�ܙ33���>�a�~��r��qh��c��RA\�K�ڇ�g!��)�{
i������[l�˩P჉�+�~:y�D7���^�,lC~#��=h���Y��C����t�X-�힡$�d�O]T����� ۉ�����W������#�!�W�з�P�w�n�&o��jͻ�8�#�}X�)*eӵ��?��"C�N���&8��e���������@�!�̲Ά��-Vf�Xz�����_!�$��Yw�E�]�7�h‡�b>��4O��si�eĳc@%�-z�&}T��]zG���Jd�0��j�2"-���W?�ɢct��J0��ݺ��q&zIV��ܔd��,���b�4�ʥ�E���Ą��) �RB곎gB�f,��e��Xg`����9��D�.5�528�2@Ͼ���9�:޼٣��h_�u�&��1�3�zf���=i}eK�ڋ�g��WM��]D�_��TG7�לe ��A�:���WE�RV��[��.���w��cA��E��a�~w����q���C�0b�E��z �i���V
A���4E��SM�wdx,�$�f�6��� �VyZK*MߟE���(�x��h�O�/!9l��a,�M�¦��ӏ�ɧ��g2a:�!���k�Ayth�5y���eK/�j;�U������\�`h�A��2zϕ.�΅RB5R�}�Q�퉑�+>�5z���7�3����Cg~�̊�j�
Z��U��x�E��'9��!6�Ch�<�z۷��N�L��h��^9��K{���F���6}\�,�^r��8�ū{�.��T�����;9�3�8����}Cg���#f[������V!�[�E�䣠�#�(��������=�ë�C��ET@��M��q�0��������UL4�x���Q%�-��ЕP�)�M/؝��Y�;#�qɠ���k3��v?�Ԁ��c�o�Yy<�&�7Sf�⃒t;,8�M��=���S�ݯk��*�"�4��ye�E�/j��-2p��XH׸�4a��mJ��|/�{�YlJ������>p��s��!��Uĭz�Jv��3���Ñ��"�F�uM%D1�C=���CE�*u쿽*"7H�*�B�]�:�N���zy"��JqN����1O�������(�T�Q�K k�6��im�!��s�n�� oHl�Ġq`j���]_1#�fȎ���Ji��%WCB��MJ�^߈r~jbԠR�mbCp**b��8=�z���8����Ҡ�e	�}qP�
Ⱦ�5ܝH�'I>���[�*B"�o�&�gz��`�4�� �
�'G��c�̎}��x0� �8G���*���Nr�7�N~����0�yS�5|%(���Z:�s��	T� ���$���/6j���Ǝݬ$Wj��Lcd�B]��mc���㜬�Çg����M2!��,"D0[;��_߭�V�iT��'�gq�x��iq�n�!`k�K�m_��~a1Y�xG�UӶݚr���δ���Jw������9���݊�x�,%�ę�ӡ�����M
�_'��r�6vL�VQ���c3�h�k��$�Ш��h����Ӥ.شT|ß����t��e���s��1R���"�u?��\T-;��i��^���:]���yv��{�N
&bƁimj�<t�q�K+%{c�K�5:���~*��޻�?ĜN$/2R��h�a�M��.�[3 ������l�զ����i����BX��4˄(�t��pz<%���lt�����������!�U��]���폾TnI�ҫ�3r��U�]#7"��nv��9 ������1�Pb�5�g���P��V�EU'I��;4͖��SR5�ԑ��޿���V�Usl����.�������Հ=���b�Z�����Vu�3ê9��<8VVmw�7�ED��p�?70Zs_]=C��>����8�C#��n��>r<���d!9��&5\c���,U�`���[vl̰���tE����J&��|ޥi!�;'�kB
\w
��4+`��� �:�!��'f��X�J%�@��}�&H�:�~)6-K�Ec�xo,��CR��&&q��iXm�,��9W�������4$C=����;R�d�S$$�~Kj�qݖ+�T!ּO)��V��W�8�ONK\h W&v�/h�d�r��w.�Z 0$���ͼ!��%���{{L/�a^CQyI�{�����v��v_b��YC�P�jep���ԘI;X�*���, 8@O�.Q�� +3�����*R��� uG�����00:���1Y$\-�ѧ��֏ј:�[�����υ�0}AR��	;�þچPu��6�ox��.�QވL��騯{�&��c�Xs�!N)�V3��W����^m����^�U���yP�R����FHC��ͻ]D���f�:
�;Fy �����V��RA�����C��+�K��`��A2̜1#@5t�ai�h�w-u�1�y;!�`�U+3nr؅fe��u��e�:�ا��g[��r��ha�m�'3[�E<c�ϙ�e8���=�!5�u�	:�HKH����^�x���Y�W�U�Z�A~�fP�����/��]���p����c����D7�(��bUx�z^t Hh����v�X<���R2�v��� Tǚ�W��d�E�zf��|�����U�8���h����!m��'d/�p�%պZ�B��e�(���h�Rȱ1�����B�h����q;�f��C	cgڿD��G��iHp�M!I���|����岇W*���X�kRФ޹xWV@��N���e��Hx�� ��HYϝ]��ղzU�CJ���E�!�G8�Qo�;)����~���Nk5"\nc�2���Vo(�)bGB�0�e�?���>��N�{S�~�g߷�]Pţ�ң���'�z:����	�w�"��:��/ s���G�Q��\ͩ֞������tK��
V��_�^5��~,��J���=� ٌ/"��n�Mi�!v�_�=!�mG�b��頠�c��41Sr��#Ae"���(9�r�!{.���v�Gsbep�E�vFTA�L�c���2!Vk�(�ؚ�Eۨ��k�Y;�}�]�,=^�j�(��ث_ʅ�U�������&^e�"��$�;�M\as��iG��ND6�.��+D뤐'r���5�&4%]|м(l]��`k�Nu0Vh���5��_�c"��"1���Y�%��䇟=���<$t�����N�L�K�1�&��4b{}���������~ii{yK/�a�� _�1��L@n�"Q�Hl�x�x�g�W&ë:��3:�q���U:3���iV/�pVל�S���T��u3@O ��b�6b�}����m_���������+P��ݞq<�4؊U��(��d���wa�j]�'�q]N�{5-�@����y3 <*�+��#EA�LrW�l"i�����K���{�^���ɤ�ffN�}��W��]���b�'���k���C�?�g"�M�7�;����������29�Y5sXs�̌'Ζ`C���j���Pk�3�ZAGM��1����fsȔ� E�J`������
�2��W4�9��hȾ��a��kaD"J�lYw��3:��_�ƴ�H�/0+�ԅ�������to��6H��+��#%@��5�B���3�R���gR�+��{��p[�[�wV�A/T�y��Q�9� ���fw0���98�[afc���3�}$�o,vڧ���7����yr�-�^:�E���^�^����������>�
���T�i҉7È~�f��:��)6����y�~�ܶH6K3����-K���'_��@���̭u0��:��I�~�;3�S�����Ok>Y��Z�u�9�YRn�:�F{������1�>�y�d��Ѿ��**��4�A���Q�[u���$��Q#�@���u��"��=N���B�=E�jI_d����m���K�3�;��;]����(v[&U����x��vq��,�+wQ���%�h�����)}y�(��؄�A�R�A��^�_�z�nۗ˅>Ѯ�Z���M"���[���8<�)�0c$����i������cK�@~y��ݚ=�_S%6g������T�^(Ǆ���t%hZ��~�z����m q�ܡ�Ƶ���~�-sҨ|���73|�j�G�AaJ��-{J�oj�ޔ�Ѫ@l�����%�?�ؠ��s�T�/�hV�)��k0����%1B�9���%��'�Lf�\k�-0/�/6���l@���Xm��F��n� ���������↕#g2����~+����ى�	��5q��$z�C>�	b����k��O[8��{}d~	p딭K)a���!���X��-ab�иm���G8B<zY-��]a,]�(�?�n�N B3��`����Z�?_����yle���'-��*� 9@���(se�+P��Em�ε��((�������, -ydOj[Att'�'th;�Zc�F�&�\Sj�~�NZd"ڽ��X6+bZbnl\Fi���tj<=�y;�.�����q��;x������H"wAv��߼��8T&$e��E� �i�F��KiRD���F��ɖ)����h��F��93Ԅ�{�Uc��A�)��Jb�p��48[��񧐳ϛ��g����ߢ��@~���h��Ｈ�J$�`�8oNюX
L$\0�xq��fX"�9����O�����;�7~�O~{�>��-Z�tvc\$�%-c�����:�B��;�$��s�'U�	mN$nzWԹ���q���I1��%U6�hB�I��g��6��%
�U]�
$�{�?�hו&���x"�}�E��������ѫO�M�@�p�3yr�d��K�B�pRN�YAM��*f����C5��F�	��<x`�9-����텛b#df"�F��d��71��>�����S�A_i/ ��z-�:�:����E��k�U}���}3�ͯ2Hm��M�g\�dy_�?����"�7,��a�猢9?�#F�@��U��*�0��"aGn4���+�1�����')
d���o:$�/ !��WDB#�vY��D��FX�q�h?��C���P ����ڹ Z>�v�*��u��A���vnp��Q[-m�k��F'�1�P7�7��o�۵(�r�
���m��x��\�5�1w���&���-�=zw���/j�r�]�IN���~���C4�ڰ@�������T�?���Kq{�y�H�������As/bíڮe���^�v&P�.ZE��bd�E���� H�ϳ?�MD�X�Y-&�& t�L���M��t��ͨ���;�W�/�WʢW�����-�Z	L�.}��H����=T��%�sx �b�Ǉn��W���H z�A](�W��³�L��J"�X���>9碵���	x+��iwp������D9�/�-�?��N���X�àI%�Q�ig�2Sx	�4'��@脗��5�7�Ϫ93t���C&���x���v��/��^�2%O� /d<n�[�G�܅D���?�S�TI]_������T�;1�@R^Q��S?�z�!9�F[4C����9c�?��D�HO�́1�m����ܟ�pؕhGں!`g�%�|9���V���mUt����[���ۮf�����쯊���_{�џ�:L#��#�A�~A������5��`�^9��Iw�m'�Z�%�]|�>A���q��k�YNH}�>�[0�{�ƨF��5l�8G�iڔD��c��ѳI�V``���Uh�f�"�g�gJO�Ju�\J�D�{�^��)�gjȋ�R�i`.�&���p��+Y!	��&�\C�!��p��^E���ih�N��G��������,�� o�$u�y+��߽�� el��!m^>��A}�ѵ,����� AK+�;��ӧ"���[K�������r`Y�*��s��I��kU#X�=�L�8��׏�����7;�I�yx�Yjq��u����+dw�������Dg�^!z �529O��+��p-/c������`�1!�c��}Cg�]�Q�\��*�OGH�M1=�>�&�B/F�Ap�>��oI�H��Iw)^Lݽ�3#t���F��ޅڏX�ȋq�R�.�<CFv��:��R��Q�����ԝ�Ѐ��f�ȳ)�b������e@����/H�=�`����B�y���
��@W���A<*0�*I\�	�HA��	\B��![���
&?HX�G/��L�V��N|����	�N/�UPg|g��VD�U�̦���I����繸�� �,���K^��RT��n��a������"������Jw���@m�"Fd�
�[)(�[u=?��1e)���n���7T����7Y�Lp�
DmQQ[�#}��8S�B��=�a�H�l��L0�������&�(��$�C��s��d�Z�^R�C��Rf:�{�i��F�p���޴R2�4�"����CË|�Cb�`��8q���MӖ>c�]i/�ʫ��}L`�:�z��:T�$#����ĝ�4������4�׷��֏���Q�{_jgP����A/�qH��9���j�W}�ެ�wK�
���6�5����X��4Dݑa�O43Y�m�S�n���,2p2�w	:�u�0�t���P=��\P�����÷׃u.�¼Ǳ\n�l|a�?��g�A,��u������+3�{��H\�v�0}5m������k �m���T�;�*!J��U�׃�C�T&!��d8w��vB�m�:���V��ۚ�2z�l�/�&�Tj�Y	7J�H�-KbJ�F����������V� '7��|4@q�OSM�/�W=���i80ٷ���?� �dAr#D�r�Н�,�2�֧?��b���ϒ�]@/5;{��ܛ�`+%G��R��*�Ia�@��߳N�E9\���@RZ�Zg-_�B\��s�E���: S3�_���T/�XL`FFe��G�uۭ, �&΢dO�3��X.�]g܇�������S�E�c�d�M�_$��뿮�1����aρ��K
f1�K"��4n�XBu��}�clq#x����{æ��?a)O@o����������P�De�w�5��W�=�Q��B��=K�2|�'K*��D ��;�̸!3L"8�/*'_[l��vaXf%1��on� �PD��9m���n�}t�֔�}���ݬ9�$�b�Қ��c�sM��)��
*Wm�$<0b�Qw졜qw���x�K��"J}���v�ԤՌ��D� ė�3�v%o�ob��U�W����˧�z���O}�8$x�D�EP��a�a�WH���-K��c��/.��b�o�Cq�� �s[ė�Ϊ�ŉ9��M{P Iؒ�M1F������@�*��;�U��S��՟)A&߈�]������ϵ�m=��SP��RXF��W��'S��s2�b]ש����,.�hs�J<Om�C�s�F��m��F��~x����R��>��9r��~�{��])��E�f��I��㆘B��i.1���Zj�|"�Cc�"QT1��fF���Ž��ZV�kn��ߜ�DS?+HjfhZyۃпKuhM�{����kE��<�(��"0�o�Be0o� �K���S��^H��3I�~,���J�H��a��#�ko�o��"'���-��]�g��҃D��
���+�sݾU�=��t�����g�L,�B�[:��K�4.�����w.PL� ٸ�M]q��k/uY�i�%�+����G{�p��L�`V��5�Vʡx 4E,��?�V���S�O�ZX�m5HF��t�g�|,�k�1�+���S�~�ӓ���T7��Ѐi�*�������˕Q�\ަ��$�A3'��-T@�"��sJ�Q�b�(hE���&d}}dX��::��*��^ � ~��Z"@(��59`+�;�8tCn+�Uan7}_㒔k�/�Z.������J�y4���?N$K�R���eJ%FR�+a�A�N/F#7���I�����wb�����2D���m9üy�ka�WB����\�E�As��!��b�8����ﱜ�s_�C3��.&���z��h��қJ�K�]8��qIP�l(}	�v��R�		|h�w8��a_�@:��VǬ��F�5����3�ʅ@��(v�U2�OSe��-����L����F6砏̗����J�k^��F����ɨ��P��ْ]󡲴�K*���H�P�vYꣷ�m��&Ps��"�靎m��דܕ`t"2��۲Ȥ�2y%�Z�Yս_�y@�2�k�l��4�X.T�r�?���<mh���|9�H��7���zPm�ٝ��S����|���f{�����L��:v$� �}.����#d�9і�5e?9&(��M��9ví�����s��l���j5���j�ΐ��K����x0k�HР�ŧ3����ňC�
$"���f�Ԥ�}tU��S�|G��ZsМ��Ѽ��pٙ����)@�����/�ǵ��{��A���CB��NTJ���Ⱥ|�D�x�#xZW?|�r'�y7�8���/C����K"��U;/m��lM��ܢ�7�*�L�;����FGR��ޙ�_�����7_Q�mG�߆)���/���t��)���|�/�jFL�	Q%�1�H�J/�Ff�� �^��=��WV�콟٭<���}�2�݊:�h��Z��<�-X'�c�����R.p�X(�سBA	d�|�˫YEA)f�E�⃽��t�J��r�A�O	d������<~T�˖qq��y�Ӏ2���k+V�v�r(�Y���or��L��#��)�������F�r���:Y�J�K�g�[P��:�_�L���4|�����t�l��%_�m��ۤ��&̮s��^��ȯ�@rټ����%�b�!�{ ��׺��+b���<��bZ59Y\Tk�gT��m���m6U�Xk#aD$�;]�CO��a�����B~�C���\�s9�]���[�W�B�H6'�à��8�u`+���)��B�N�ߩ^6١@t�Ӂ5��T6#W���\g��I�X������������N*�#����T��.����o������'z/Y,�ќ����(%�'֥�w����e,�Ŏ7`/�.��� f ��#�{�_0�Lx�T����%�����~�iI.z�/����ƶt�� �Nm����E�Zdw����s�{2h�gglm�[F��QF��L!z�y*�~���L.Ε;N����yhW�9�5�^0�	֪�<_9��z-�Z���Gؿ�dv�?���:��%��䣗'��V��IA���p�\�@?~�<ͨ�7��E�����[ON@쀔���`޳�D�&��#�𭇆kc�rG)A�i�l �P6O�8I��"�ϽW�c~dO���S ����ۂe�ω���1)�����7J"9�~o�s�	��\��w5�a�M�gL�l[�o���L�u��"��.m5|������"�%�T(��x��߀[]	��o��k�ۘI����3�`�%�ع��:oJ�ſF���α�U���Hi��/�70+I��`q�0�xX\ �.�
��Kg��Ţ~��ݫʿe0�@���o<
��q����h��+]I�,���`7��!�����uǦ���4B2�T�tB�ϡw1J�����tc�JI!Bx���!�k9й�Fܥ��6q�b���I�C�?uѶ5~5�yn�+zl$��Ip���Ӊ��LKIL�6�|<�X�㛇�Q��ٛ��:�g�>ڵ�&m�W�rdᤥ&�k��������ف�=��_��IK�G����//YLC�r�HN�M�������@I�5I��rL4/�"0�-���h�VK��ۚRlJ��WA�X)FQ�P����v��)>��y��7����a�='��>3�5��8���n+Q�S
&�.~ؐQ!7����0�(d�l7����B���S�q�H��KU�β�tR�������qi����է�\�=G�H7�B�����v��*\7�ϖY5�uV����,� �,z���t'���}}9�����OZ3�'cg\K�$�@_r������'fI�TR��C�%rA~ڵ�O�m�m�:~��Y�8p�h��QP�6A���}*�Ѱ�X2���M����r�svQ��H' T��L�ӽ�4⬍]j�����J�c���"��D�K=�GF�����J��4��.�Pk����<nLޠDu��zX�QH��+��)�fZw<��l���4�����<�!<}�60u�����4��ו���C�'ӕ�?�Ǳ�Q�gA�e'������r6i�����~�%�}� ���U��zJ�`%S���F5�|?ر;p�G,x��~'*�i �5��4: ��� ��ݲ���4fV����/˫x��{q��#�p9��Wf�Zt�W�; �5ŝ�9��P�$���AR&Y#�hL�w~�b�%�c�̓���c wָQ�����֫�/5���Fx �1��l���W�d(�-��R-W{m{��U��ر��<����/4(���ԍ�)ttܐV ���G��\;S� ̴��ǀ�p���֗Q|ܣ0���>`����z0����A}�"Fm�"���KP$Օ/)䅄�����!�ɞ���]�6U
7(��N^��;ܷ�H�J{K�D�����R7��uN��ވ틣^��O�XxnF�\L:��'�>���!0��
yc�
nl�5J�k	#l���qba�ԍ*�e�Ń���^�`��48r;*&�C�4�")%n%.�x�s! �BRo�<�ǩ��lѺ��b��e��"���Y;�"W�"�A�q�?�������[0$0S�+�F��JX ;
�;m� ����|8͏h�y�[܄��#��e'�I��o-#fu�76�N��
z	�o3���������{���
�U[�޳�ܩ�D4�~����fv��!L��W�Gd��=���@�]1�N]b����Y�L)5ykŞ�PbX����>�D���B�b�Rc��~��O����yR�9>�'�� �8�I��N��o�r.�;�h��r�\�#:/��Z�=�A��a�˸1w��_!���o��*�fΙ�O����KvG�UxJ�.�����GM���j7�HƊ !��?�T�V��ˤ��!T�tR�g��qK��)�]}/ט�����=h�cb��Մ4�i�bӜR= �^0� ����ò�W�X�g��7���|y�^�Ƌ9qֈ���f�	^��hN�MF��O�C��L��t����7v�1����5G�|�4�s50Q+\{7�$F�R���),Ma�oWj����� :�J�]d���=��h_��n>��^;���󲔾���p<�7��ah�"�c�Tm�oHQ���㗺�%F�������Kq�.C�^a��";*qkz��	BĐ07=�cg��r��w�G�{���Ǔ&�!\0]"۔`��v�O�s���A��a����|R7Q�ǵ�2	�A~��\r���K��-�3��lia�?Z�YTn�%�s(����(�o����b��&_}a�ev� )mV�����Gȼ%C.m�Ժe���:��a`F���/{�)L�,r򂕑Օ��0|
t���yeVe"l�������c�l9���R�!�>\2$�h�����L�w�6Xz9�>U�O�^m��I��s�N3��v��C1M�)o*�?���gR���( ����n��'���h�Fg�9�úך�x[n����n!�Yu�mު�Oz��sȵ�H�����Z�?.�b��T0w�>���l@2i�ڻ���͆A�X�t�s׭�ߥ\��Ud,o�$f/���Y�Ok��f���W��BBi�F��Y�UF$�oE�0V�;䧖�/��RD�S\x,9��� u��^����V�j�_�tF��gp<@�v�7l��R��4Ki�'"v�2Z:B7|s-8.�+�����ٻ7y���R��IMc��B�n]^oiG�4��*�+���X��oй�rQ�[�-����$X#1zi}�ꈠ?�c�Z�|Z��U5U�%}4�7	8<�'$�ZdBI��( (����܈��y���F�/��]T�NqD|�k�z���c����Ń �u.�c�!*���3�*��xΉJT� ƝI�U�S:)���q���kh�;��W�Y��e�l�͓�P	�;�~�̆{��h��P���f?�!�^���z��Х�����6�|��1���@]���F��;[ ݪ�>���)n��*U��s4e.��|?���;�mvյ!��"��I�$Pj�u-
�z�O�T�U[<�A����ˬA�Zw�<|�;���m���I4(�b ���}�����dV�K@�j��藚�{��;A'X�)��(~�({�r�4v�؇���w"ti���>�l��лuP�I����7��&Sa�J�Kq�t%gg��{��r>�"'�1:����NǸ��9�tC�3��#���5����s2ğ>�f�@���ᑳ�7�ɔ�q���n�q�QXZO���c$v.-8Dk��ضIsK��Ӿ��A��%���$>Z�JF%Z�q�`��7�8G&_�ǀ��;p7���@Ny3���4p{��[<w�'�ѝ���G�f�����[:�������c��$��\~z�o��� ^��̓���Ě�i����Z]l���QR�F�9{'kH�q���'/�Ûi�<��H�3���g	�OD 2�U~�ϐnW�.Ν�o�_�����yt[;Pg}H1����1�aM`6�F �Swκ��<��-�e� ��ӱ8K�c��x*�o|]'����K���O��|��G�˿X��yIx�w�v?�}����,�r���g䲲�⹫�l5@=��o:)��?q5���Iđ��˦B���3/b��C�bg����u��ayɨ}d`R/0:5�umzq��z�.Aٍ΋��M�SA�b��n�Pm�����C��'d��/�ܵ�!.%���pj��N>49_{a���XO�I6ކa��̇_��2J&F�bu���)rƦ��\5�����ET4쫡ԤӜ���h��ex֨{�[�p��~gˬ��>8rE(�k��V����p��A`��f��,!3� &\,y��3z6�� ��u|uֳaRc?Y]�c������{|�(���ޭ�9;��r��@���|�����&B]T|�#��mu�
5�+�S.H���{>���S��e)֬/4�mΆ^���
+̓	hS�}z�V��6=��t��R.��u�ڡ�3�����pq��u���^I�&�宗�{ᛧ%Y��w�+K��{���e�.twN�:���
Cy.�~ڐr�x�{C�%񜨷�Ve��X- ��n�t�:m���>&ҿ����3��^sT��1�4��o�W�oY��������	�i;�cHm�����	������e���I���ʉ[~vA�i���U1fC ���s�^�BF��r#�?o�:{�NV�~U`X"����ρ1�^0�f�}���3��	��$�P�?�~o����>0H�g�i�t��"�d�X{E�g
����X�׫Mn��_[���RQ<�:�\�2q��O��W'p�`����9�	wÒ�W�K:*�W��_�c;UC�C��W�r���>R˃ixT��3�΍q���Z��F ~��Au#����<G&7��&�3�����Z��T�g�N���'�z�'5ܷЦ繋�����qI\+�ə0��l7�)OXSw���(�]��e))'�]�k�,Yо�m��3T�1��(���F]��.����	���W*�đ~�(,�֥	q��b#ڥ���m�� ����V�v�N7ve�}��}8<��G��U� �B�����&���(��3^�����;�>xjCI�W�W�@�v�W�&���]?�WFQx<C�_f�L(�|K.�̦���C#du]�$����$�F����%�	E�*o��	#�)�[5��e-5'�q9n��n������U�3�"]�pN�����g��N aPͺ=���r�)�4���F�XQҐ��z.]ʺht�뾱��Ѡv��w��}S�m�F�u�\��DR��|^��L��W�+�.L�2(HA�)���F���J����0��i�8������ڍw��7r�OP�Sؔ]�����_;�̅
Tu�	k�"t��W�a�M��-آ�Y�5&�� ���J$h�8��8O��BB{��/Ʀg_jX	��<:>Sv"D��������>UP������="����A����vx(�*�i��;*��2:1$~��"�ɐ�Fx����uh@��������gby�mvkS?��#��
�`:�����."�z^�k=�=���c�0۲R�"�S�~�د6������O|�z��gw�o��c��8���k3���TU���q�#
P�pp �{$�)�笹��H����;%xn*�����_#�^��*|���g��!�aB������ʲ��XE�>�tT�����PZlS9�j~<�����G����쳇�{��C���<��Y����BiX"���%+�������C�%�D�(������C@�ce�Jxw�ł�M��ݬW����F�.���9q@R��yv�F�&�8�vO��g���	G���׫��5;��m�R��*�PDF�}d��r�2~I1ُ��ɿ�JSh���/7��U�ؘ�}���r,���Ȥ����n|�-�i6L�0� ��,*V!�apl�aU�my�w��G��՞���/��'Z�Tʷ,�o;(�˔\V i:��z��3g�O��<Ǌ���������{��h���H�p��jO�Xҥ��ߖ����ԤHY�iN?	CC%l	e]��db�n��o�s�ߥ
� �WT/s�;�������0hP�:?�ZB��O<�p �Ū�ɠ=L�͎��Z&���˙�9�ۂ�z�֙>��U��a�}z�h��q��N1ez�+���
��}����C@�mՑAU�R���;�
l-��2��{,���g��P�~�ޡ�pӿ��q�"��w�ύq��]���:����ɨ�7TEA��>�zlz��o�i��q�� >�
�Ү�*:�H��)Έ/�>M<,��ƁJ��69l��g�(a�/�¹���~
��F�:��)�`�d����t�mq?�t�=ʋJ�[!�"����*����SY�`$�"&)fUR^8���G��sӒ��~f^8����O�[����P��}��e��m�r]a�����h��s�\�nR)��="�����]�'�L�Mj��{V���yP+~;@��(>��^� M�Q��m]�*�d�e�:���! *X���{e��̄�;l=#r�)'5P`,2��(h��I��#��E4'r���Щ�è'�Q�m�3M?�\?dp�_��&$�@?�N� ��..m<4L�c����?�����I~;�^���>W/F��S颈ʂ�k`�)Q�� Փo��k4����Ӊ�P��p�t�ġ���v��kd� o+ܙ{)�p��'���������(�����e!d�*jxK���4M2~v�0�#���)|��DR��쵑���[nϦ�Cs>O��
.�7y��A��v[;�B��釱9� �p��=k��ÀYg��ʝ0������tLO��3C�"I|���rF���>aG/*���V�Iu54b�Kr3����������M�(�rji�t�B�tՍ�@?ń�;h�;�cQ��t)_�]~���]_m�omX�u���r��3�~�I�A	��i8�m�K7�u�wf#��6���6Ɠ�d���b������u�����6LI�!n�b�����0l
cΖ9�x�����w[(���j�\T�$��n9��b�*�<�����'C�M�9];���/�@�<�+��L�3�N��';�X���݀��U�F�s�������n� ӡ��șn��������0�6�oԪ��(�0zL �C�]�9mk���p��
���_Dl��G�L����0�������h�<v^�z���Q��Ǩ��e��}n�FOI�"n��x���Z��7`��MV�-�pH��t�,- ��?�J�h/ԌhR��*B:/����\��6�4��]_�����w��0_���1S�y{O�%*Tz#T���U?��E$�����&*/��S�K�ƺA;%��E� ��K�[m��e���&NM�	�f�N>d��!G����Ð<��B�G#e0(q��|��T*m]\,�ˡ-{�/F{����ג�봀��q�r�+2�4��G�͐i�w�`�����.*�J[���wM�O��3�.��Je5���C����a�k�A:�Tawn0�M
�`�+�v��6�2�8N����G��~~!­�����z&��T"�G�r�R��.5��sڔ������*������e�����*F-ŷ<E�ҥ����Mɍ~s�|c���ۈ�/w T��(N��qLmI״�dN��Z�
^ȠJ�9��p��O0g�X�h������@������&���A�TZ7�}�� ��K��t��QF������R�i���t����rL����fB6@~e��=�Ub�P}~'�����}��5��o9�c�z�)���yH�!�/k���[��sŷ@6���F�R�ֲT�k�R�R�	�q�.�O�j���j�$vK�Ba�t浢3_�n�; ���F�"�)ˠg�cNGLe��Ry9"�<���Cc;v�dx��l�\2�����؞3K���9Q7�T� �i�Т~Vi}� n��~G�� �IC��S�J*�ﻟs���F/m�OګU�d*����^jr�.NGڊ�k�P2�KvOjY�e(kG8�yĴ+���a9y,q����B�ޔ�v�������kZ͎��H�Ho�>J�x������)�P��%S��=�*v{I�[��!Ҷh/-��S,�u0��'��@$��7����1�����5��k���b^߉f99�U�'(��ؙ�+�#WD7P.�R=g��T=����8:ݰ�װs�����:8�`0'ɋ���q�$Xa�rs��R�O���#�n\f��_����*L=>ũeO��pK���:�͊�=\�ì����3�I��Q���kނ91�EP4L6m�l'8v��G��f�X��Ǡ9���ÂPv������h�W�o5c����n��Fc ���$�2���b0Ŷ_����1I	�X�"�z�a" IT՚�5Л�=	H���>`�7T�j�_�;B�v����3hM�GE���]%��c^D]����2X�����"���w��� Q,��-�W�R=O��Y�}H��W���n�C���?��㔑ߓ1�8�>�?M�T�r5w�    N�_��� �����OC��g�    YZ