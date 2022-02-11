#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3145815886"
MD5="5864ac93a819c5a28f21a11b4c674935"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26500"
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
	echo Date of packaging: Fri Feb 11 06:36:37 -03 2022
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
�7zXZ  �ִF !   �X���gB] �}��1Dd]����P�t�D���aaxހ�����]�=@�f2�e�)�� d�#���h4��6�����\3]˅�"���id\|��ۈ�����D;��{r�|c&&o1Y�FX}-�`Q1^��_Ah[���!�񄛩S�J�O��`�_+��������w��ܬ��"k���6��.�4�>����
G� Y��`���+Ϥ�vL��٥��e���C=Ё3��ף�Y�1��c��G��8aT@�U��)#�W��ej��nt���,��B��j־nt�{�d��T-p _V8��E���[+&��_2�l��qyg�V��"�$P}�0���W�SK�8@D!���oʓ(%�!)o�S�`�B�4��Fm����-�m��A��!��z�@��[q�k�RF�GW	HĘc��/��F����ם�4jb�,bq�����*L����4?�&D~a1���(�q��>�oH���0q� �L�A�����6`GT�0���|g>w����t�[�lO7�]k�k��9{��50���X*@u��憧��u[�l�K҅z���c�y�G�ҽ������#�ue�6Ɛ�m08t>�Nh5�h~�7��y����2�1LY˻Y�(�!'��QIL��]8�pf�����@9p*P�YA#���n���nH�P� מ�� S�\���Ɵ���t�����W���x��F��dL�X��;�.�������2l#�ޢ2��/��c�������S��R��1�2Jn�V[������P�6a��r�6<'��qȲ+�
>��$X����q.>ҝ+ss��N\��'�F�Z�@E���c��}�Xc�c�OU���W��r����Wà���g�� ��j��b�|�\��3��;��.��)���V�b8�z�m�8W8g�	�E�(}���2��W����V�-���ۣ���G��X/��R����D~u�k���[�H� �@>U�3w���X�c{��p�X)&��܎��тW����*[9��	JkV�ɺAf#"9�;�KsN�1[�h���]�Zֻ����	�7������y�3@�橳`Z?��$ H�2�뒾���N	&�ѕ�nT\Hg����"����ՠOI	�/�a�m�����
w��9?f(R�*��[��	ʝ��$׾�Pj.��rt}�g[�f��r�9w��r=�l�T9D|,�p�:m���x��\��H�d�fD̖��������. ���)������r^CM���;	ȼ��᳁6x�V�q){�[jZ��ukX@�fSXG�����:Q�75�v�n�r�ǿ�ź�h1���D�0B��O@��~�Er�p(~r�P�h���?���u���
	�&?��mER���� X�y�r�@��U�� ��>����{aHk[&s%�t���"�������ąm2��KX�ގ��n���agFN��j� � {��sV5��H��BF���L����s,��]I�Y9�tey�����_�3��}�M����cQ�َ�9"���0N�Qm��֖C���ElC�������kv�gO�����ٜ�rz`�� �hW�_�Iwv���wG��8H��k�v�n�A3�5N1�/RϿ;~q9�
�Z<�ʓ2-�aQx��ɲ�k�Yvnu*�T}���>IM=�'�����0\.� ����}����9<�B 9��N~�L��a$�ܾ�c��o�%S�4��9wS+$!�h�O�	`�u	f�
�)6,������ie
�{$-�%��jNð[�������pV�IMa�$�����D�,��u:9���̄Ǭ���o��݀��>��}��]�_���nn.���+ND9�p��g�p�ph�˺�����;��'1͖[f�$<~J^+C�jG4�R�1i{m�_L������۟5�,��#���dk�.�S��F�U��v 2A��V>U(!Sf�]e��v���]?uVw�1�5� �����+F�d%w<�� �ö��E ?�[���F�6ю��l����p�����lݿഔ� ���k���H� ]d����-���玦M.���zib�	5m�zs�X g!7�q�4�@��E��M�C�"���Vf��ytI2��cw/�S�{���ǲ�����p�V8kЛ��j�/�$�[����� !R�#{G�{�<e�y�VS�:E`w�Ej ���qK����f[�g�JQÆ���盛�\>^�1�~%!׀�Ge�M�}�BV�.�X�0Б�d�ꩅ�@:�O�QeMh@�������~�|1�;v�(���o��v��9��C�����c����L��Z��*�ӫ��os<�+�X���'jqI����t�Db�?�x�Pk>qz}��3a�cv�LHC�c Πp���ēp1�.�m�6N��>����|6�)�a3���T����T�+x�B�!� ��3,�mN����h��?�Ry����3���������e?�lҏy	IL�^�UT�r���LlDl����(w���]$�R���q�m�I�=Qy�Tz��cY��%��s��k �9�)��'V�S�E[�ɶ��A�����nWx~��%����ߴ���i�Gq��?�t���y��/L��*&�@%~��%G�hW���A�ʐ�k$��m�W���6����U��洤�MG&�J}β�����J�Y8��@�L�N�l�2ά#��B����<W'����&��Tr�9N��l�-'����4�UꏿzhQ� �����ǂb
e���9}�������.E�����xiA���'��<�B���G}V��Yc���N�y���2�LŦ�?��l�a���|��Ա�b!��V~Z@�q�O��\����;=�҇�R�^��
�sO���� ��qt\��O\�[����"��ɑs�|�Ϯ=3�R+sJ`�\H�{9"�,b�C�U?aQaM�Ő��͂2[ֱ�$�g��v��qi��0jX�k��#�0�f�dܨ鿶E�l�����񂬑1 �8<v��Qe���s>/M���:n�@#~�u�֏N1�����'���D��ȁ$刔<���벋���4���`�9��������D���}4���[c,s��)pj�@��-A�����n�d�8eN�>���e'���?	��c�u[�\��H�%n�fv�9)���2#Z=�f7ؗ29�%b\��u���ĉC����g����Ā�M{MF��ۖ%�zU���N�����M�B	�Yip1xd�.||9�ő���O�"]ZO�:&l�~��YQ-j`�	a!ߕ����Z�LF������͆�j�v�d X�)|�1RߴBDww��u�ֈd:��J%9�Y���a�����Y:#x�-�ј@G��w!�������6�x=�]���-�X�>�<��4Iΐܜ]��́��|
^���f8�c9L�6<�m���w�ćq�!��}�0���atb5� ,ӊ����ϒzϞu5��;_��_|]�DSQ�����@����B;���?�e���������2#�񪈌�Ŕa��zd���l��f�/��PB���@W��?Z�V�ݸ�`{7�Z��WR��싮$j���6�H��ON�{����#�+�-Dq�P.�F���AV|S����7��㕎5{B7�P
t�v{�"��$V	:?;���;a�%��B����J!�� ��KVCq2�3����+��l�� k�3�c���,?�?����O�Y��^�v���VJ$qÒm5��ۙ<R���y�m9J���r�c�*J�:��2y�g�u�ɬ�`�<H���е��f��ňrG\��q!�40������Q6/�W数��3q���B�k�)W�����C���{Z#���;Q�חE'���	!��(�0b�D	p�YC)�A"���:�<�C����z��2@�#��5^v�����,��<��O��YE��S�C�NǛ�	��R�<X�>3qrp=Kڽ:a:���8�XǾ�}f�Q?�Gv����r��b�д�:H<^�ѹ�v��LY�ְ�fy
���,�V�^��%�C�
m�_c�R��D|��=�������11�3�߈���-�����(�U3P\Ρm����OI�c�Ƚ����������6E�7���ӎ,��j�����DL�MŲ3d�Tǭ	z��P�S���4s�O3ڇQ`�����ypf�c��a��Nu3�l�a���$���E쯟��.����v<y�D�� �Qn�"�[����ey��r���$Q��9�0N=��L��c�����op��2���[��Gh�J���UԌ�c =$0��,K���L`�'�Rf&����U��T��<��w[1*R�mv�lEȪ�uR9
1�^�6��٬���15<f9���rJ<�I�ը��w,4����C�T�k֘���b/�����G�����,�P�P�|�x+�:���?F�jaR���8��9UϺ���M1����Pwġ9��mP��qHV��eS����Zr�#�D�[0��D�y��z[`o�5�"�*%�ܦ'�j���#(�*v˜�r�#�p����2֓[������i��5�Ϙ� ΃�Q�
��	�m �`h-��nT<u[\KZ'��^�T	�4��1T�(t$zj�8�o��/��:K�D�A���ɿ�o݄��1��?�f	z�,'˾�J�v���~*�IG�-��ط2IB�Rj�ލ#$�x�A��q�GN�댟�(�y�w6!��P��j|��X�̵���;�~��y{�3Ɍ�lɚ;*�ʟ�&^���w��U-��U��:ϸ���_�P4`����50�r+��55	��n� u�r�`������;�%hr�j�����|�j�M�`+�m���M��5�'���_ҌxZd!�<Q�vn��{��k��=�.,_�L�!�|�P�B(��?����%�@c23�/�`��ik�Q���K<_��o��I�
T@zy3���p�ބ�O�5���q�Fɧ�g6K���6�t\�3�[�H��H63���Q���+��L��Z��y�\��������&ҷ[K>
6��^����H�`X����r�ݝ�%XF12��<�+ѽ�b�ʬ����L����N��_�F�.Q&��py�4�y]���	��$�p�ty�P��J#��G}��]�-�d5�s-�xΩ��ˆ�>$����Hk���,���R���&C�QD�hq�n�*�u��>�ra<�A���ZhH"P�(�z�#�eg�B��p�S�4�M�����m��Y+ �EeD���\�'�t#Z.���	Lp)(��^�2!�R�ogW*=�ce��J6�,�4)�#C#��{⦷��Z����/�_��=��K&'��
��R��r���Fm�ܥ�Ib<��-��kF��%�+'N� %.���<����,i9C�O�!��(
ӷ����8g���I�3�� u�w�S�ʟ:)�������&�0��e��[���;i�ݾZ �cσ���$t[)s"-�SD�2���:������{�{��m5���i*ʽ�t�y��}hb���x}�3�J��x.�Viu�FR����ʊi�I2����h�	�
��R�B9F���Q���5Yg����Me��d������ۮ(sSt�SS�-m
c���i�'�]QO���u8ft"5M��x+3I�៑�5{�t��X.�t>%cbsR[�!a�[�g঩j	�1AF�H���3c��@o�[���b����m����5eb��]���9;�Q�1I�e�8��!�IE���X~�*�Ը����_�k1C�fi76Ĝ�P`�X}��I���| ��y �ɿ�������Q�,^7�}�]�$���>��E❌��~w �tQ��h���u�;  ��ʻ}:J�.�i�Dy��M�ÅP�a�h�m�|F�ƀ�b;�Cp�D��۠L�1`j�9!�ֈ��[%�����/�{m�Z��P�#I��/���x�vc-���q����0�Wfj��氣_q�@�v�t�|�*��0��'=Lg��t����+[EC��I��빣��d��l*���W3��Y�mu�b4�"��J�O��k&�AG�LŲ��_�'2�B?֩mr��(��N��:�i	��c�6�`�^���Ax�=:|�#��!�6������=�Q�@�-(�dՙ��ū��E}� xE��~u`[��^޺��ɼϧ/��
,d�z �<���t?�pڅ�*�J�+��4T<�ILZ�d��wӬ�jk����>�I�5�nc�J�W�qjk�D{y&eA��0+Ɩl2�+V� V���-��"RŰʏ���Ox%�O����}�}n,�0S���ֶ&��腚�kJ[��PJ.`�*�c5��&�PܢXz�@�u�[>]����$I�|�صy�7��?I�߿n�v|L�ZZ�Ɨ�b��7���&T���^����Kn+�1\�O���ĝ��ų�!)�%����h|�=᪄Be�e�=�\�Ď�(��]D-[I���n��������p��.���J�t�D��(ۡ��>YLW �T�=�-����	���hz�ӊT���s�����M \j=�T+�]�d�d0��5��	�ă+�XO�b�p�6 e�
�w�'J�P����0l�Gv`�'����M�k��T��+!ȉ�ګ՟��]�O���o#�����L�ﳆZ��Z�xÿ���y��[�갟_"�7"�5!�S^-Nrh@���SՓ��^��#H��2��7�ڛh�K�[��g����?�?�o�PwK	����/C!(�����0xf�����/��A
n5I ��*�ff�P�HM8ʖFm���G�<��O�bM��\*e������]�o혔�Z�@�׈���˸��7��3%"|�f�W.����ߨ�T[}5P��B4����������)~ݻXʈy8d�m�e\�I��HM[^��\D��8���1���7���U�ϱ�����	�3��?@Lm2=�َ`�Z�<q&�$��oG��+��[��pS��{Ύr��[�����q���P����OA���ᣝ�Օ����Ȣ��,^q?���4/�qf�r`�f�0W p��%�!�����r�HJ��v�r��H�$�u��=�}�8�������(\�o�ޝM� �� �t�lX#Rd�Ge��� ���H�t�~���
샘�oi��u�W�o�bW���eq�¾�K�G��=����g"�����kֻ��:���T8V@ykm�r�Jm ; '����vv�NF�_��1�E��
C=����N��X*k��p�ۓ%L�g+��#б�q���-�o���#8�<
���uLz>��8oċ�=�#�dͿ'g膳��籝�*��{l��m�㊻Ⱦ����~un�ur ���A�����02Ձ!��BƆ�Le��H>�&�֩��6��+S+�E�ϵ��c�4���2�E�x���@}����S�y����ٹ^h���z�Pk\r��.P�])���3^���#����	m�Xu_!P�w���2B���6y�k^)
�x��p�{��{APc?�L���XYi��Z$Z�\)i�-t;�g�J�D'�*nz�Z�Ae�oc>m���-�	dJ�����^��"�
Z�P��j��"�X,�Gd�	_r]���bXX�,�Ս�d7w��Ͽe6zL�T���M��Z)\�>;1M	��S+Q�z

��0s<��?�O��ݩ�_ָ���L��e�����kK�������PGP��U����4R�u�	�������Ie��r��IR�ƌ��RF�E"z�2���3k�m��3ߔ�P�Պ�˺Ud���S�@�Qb֗����˻�ӷz��]�=���u"N�G;@�Avt�,�s�
�	SfE#M�[`�k�P��Z1p��	dJ9
���+D��V��u�/��o�ڰ��9�qI�W9����ꢼ��A�A�S켊�0��e��&������Ͷ�5�@=&7��n	=���C1�!�&���d��ㆹ�G�s���-/s�hz|�k{N�Gc\�Aι)������	�6k�9d�R��	L�.Ni������+��܍|!�����(-�`D���o�*QFSq1�A��TJ2���&�S�c� �U����x'U=�!T!ʍ:e�l�YЂ)�}�咟Q͋�xKHo��:5�xeT�V}�� ��*��h����3Y�eEFTT��s�d�R��� �N+�$��@���l��7���e]�L�%Dad�������/* �3�������+��c-R�i��m�b���c���3Q�m����*�e�X���A��fع�O���D�𛩿\쓀��誄���l�ҍ�_���P��i���/(���ר��v`�Q�V%�FOh��^^�$+04n±.�J*/��u0B��}��f�>?|Eq#7����n.��կ�z��X�~qt��_Ι�jW��p����c`���$�9�<��g|>F�Bq�^2���r�LD�-3M3���J~�g&E�A�����G�$
��{ט��k��N6'1�Y�����a��U1F�4�j������Z�8z�l�����q�y���h��]�Eڗ?� G<>h����u±6`�y�U�Ү��+�<�v`���^5���T8���-=	D��j��}����pV!*�V[;^y2f$�Ǖ�7bu�Ԋ{������^t#I���W_��V#Ԥad39]��-����k?�t|��5��V��ޏ��u�N>���D�L7����ۿg@]�]~���lC�-��?�>�����<?�R���Hk�<�r�v���� Y^�*��N��N�0CC4<DT��Pe�6�b��[�b�X��H�⏥ێ����M��Ϧ����^ՋV�L��5�S����r"�U�d{bl8C� �;ҕE�(#~�mOT�.}�aQ�H�(Խ�9H{��L�=s|nx%��$nٳ��)]
��zE�hx��성k�"���9~�˹�./��j;�nZ�/W��ѩ���LF-9�i�=�k�4�Ca Nȷ8pIs�ǘG
h Ia�KB����,o*|xr��a�(����n����R�E���c�l�R��0á���b��1����<��O�cGH�jh�O؊~����=~.�֦Q�r�ϞLs���E:��T�@3���ޜ��Y�1a�Ȟ�|��5v�9s���p�$\G���#�R��#n�u�"@u'��G��F����N9j�◬��f�}�F����}V�'��
�Å7F@x���C2E��#.�a��[��ON����ȉ�-.�S���M7!����T�٘�/�^k�3��1Ջ$��"���֗�Gz��O�x�('��HY�edϼ3�dsg��R�Q���\��Hz�Va��+� �F� N8y�q9�~6lb|(C��;����n����Np�0��>l$a���r��U�0��JP����ik���p��Rs�+�}����.Y��A���j�}D�ʥ�~!z�|(�Q5��O�W��,�F�t΋������b̒yՙ ����[�ЇkS���URU��(����kT�W5�V���OٽdΧ���g��pH�nJ���G~�	u��R"	��ۜ�U6�F��dGZ}y2r:�B	�`�q���!���|=�RzX��h���fs=��,�h��P8��ϣ��⇬-l��ł�6�	K0Z�䇎�yw��Ra�.��ûg��P�n�Z��Ɨ�hẖ�7!<X��S�/��%��	n6 ���3ɩ��07E6�4Hr=S�z`R3���cNӽ%i�5���2*��m�����2�!̀��M���W�<[�y���j]T+�D��Й����M�l���Z0�@�(?�%'�޻E�^`�Qν��T�k"m�(�CR�W�{�W�e�<)���ky<و���a0��#�>�+������B �.l�H-,��Q=9�Z;�r;�<�lI�#<��E{���f|],H��qIaK]F����"�҈���8B4���i��D� @>��+������f�R���%��r�̀�-6@��B�|f�S��a��@Vyvߣ�w��A���W����:��O^�d L����]邛�q]��1Udf�{>\
&�S�[��x�eV��!�u���V�ֹ��kƎ4�e/�ʏ��g|�WD^;lg;:��K���,��ݽ��A�.lZѯ˕N�	�ߚ�{�A`�9�S�6x"�=)��1��op	��5c��&�4�UY�B�: �D�#��am�bo�2�j}�-��6JI�,~����E��|<Fz�:@D҂A�G�ě�Ub�@���Ὄ5��,DD^ :��P���G��p`��� ���r�Y�^;�{��bJ&݃>��铠'���Nkf8|Hr���+ˏ{ /Q4����5����_���?26���̓S�׃ )�c5��C�#mZ�NktM�����Sԉr]gO�w�;9ejm����JU|����Z"c�Ṛ_��׷r�FΗsj4�^��e��j��į8�<ꗂ",	��ݛw9�<��Zp�tWݦS4�>O�6����;U|`��/0X`?�YvVa�|�϶u��o��Ò��\�2�O7��(��_�����O�������Ȝ�F�JD2��@��%��/�;)���to
�O[��:u��
{$�G���<�Ww�k��}�X;.�	}��a!�^�-:t,Bp�N᷃�wK�yXx�����N�}�D�
9�/,Շ�r�^H^��9C~�7C�q#p��5�O��@ap�	<�9����7-�vu�݉�n����r�E��B`K��s5c[��B�Ps�S����=+s�d�n��O��7ɪL�'ڍ�8���-Pו�U�K����o^v��fc��m��A��;W���G_
��f
7hcӌ{ޞ���^n��f��H��H(ˠ��*B& ��^�ͯ�<"25Za*|.W'd��]I ��1��P��镞]��T�4�X���v&C]�X'�|8I����``0�dL����KE��[��+;��ҙ\��{��m�Ei�ˑb��!m��|�p�(b�)&�{����r|� ��^��:�X��_9�`�Ή�# Nj��S�PEZ���}�a8J��1p�Yv��U� i�f��:�g39gIK�r�q�=G�T���z��h9淺|O8�vR�'���:��5b�P�q������x~�0��5��]J�4S�����~`��r �/Ҟ&���Db����
�Ƌ�m	a�}h���O�~�����~U_L�V��f)�.m��ɍr�xⲤi̶�o����0i#���/S��@�F2�O���t�c JFwÔ�Ks���%�����$�g1^��H���#�8�y@��K��}�`qXg��'=�Zz������^@�[a{�)�Y�w��KoX�(�9���TSa��)�#�M�����յ��ng�|�Kt��!��ٲ0�tv�:&?��ɨ*�6�tR��	��bO JɅuB�x�p��W�V�2������'u͋��I2i��--��+�1���ٮ����쪅�����G*�����W��u#o�P�i��'/˨+ �U]�e�W�E�DmG�����?+�tUR3���PrA����B�����s�6��X�+�\��_f�v:A�&��;�vz/̩5
�j��e]�,�e����mkq�^��G�w�Az΁W}�aB�M�$ٍ=�7�+��F�˾���X+T�j��-��t%�7"��مt�����E��1�C8`�kA!«�BڬQ4��Z�s���$����VϽ}kΒ,ZB1��"[�|⇾�C�L�hatLq��#�q���h������^��]?�g���nb�,�����#R߰b�-$�&�˫9�:���ſ�%�=w�Ae���..tp̫�'ք�����NAD)0 	-	�\�9]vP��ioM���
��'��}�0�S���3>)
���uې����L7H�o�VI��i�i���뻍PloY��_g�j���{@�����S1�C���,�p�/�(�o$�]���#)GD�w4.,/8B>tI*#
W��.r�ϱM�ds<�ɸU�\Wn��Ų��L�ӌ{�E�����^R�[��/�n3>e-��I]WHlN���y�wy.�=�8�UP��PB�#���@�����t=6�Z��ۃ����?�O�z�d�`%^��w`�W'��p6}�٪�ء
�@$?��e��Iz� �!�8+���}��ͪQ�N��X7|����2@*���ۼ�J���޽���1 K����l�����Es�Ӷ��2;��9��'4GauI�����yzRrʆC0�c�h�|?�i k1VYy-e}�]�{�c����5��h�4]J��h�2�ѓ+������W��(Y�����а�xB��U�����b
���t�x?"���b�6�
�A_�F����}���RDĺ��ThOY
k������/�ؼcH��M����WТð��o��#�v�CK��<0�b)D1��I�ٵ �-0ض��$�o����' Su��M�p��rs�F<�p�qގGn�@5y'jy�=�;��{��B��U����2]kY�L-��	e��x��J����g$���vl�:����L	� ��Mf��w��H��	p%��ɼdoZN���A�~�C�M[~��� ��y��:ֽ%}���x�ȚɴMM���v�m��2Y�l]�I���r_5��¤�
	�K����ܱ;�WU �_���ܙ�Ol#��D"Q/U�l!&F�:|#�[�t�&��Rb�ʓ����o㹘�b�|����i3P��W�m��W:|�z�\����h�,٫J�<�WҙJ��l�7�1����']�g�!��VZ�Cc*-��40PQ�W\=�E��~�J)�Q������뭭R� i�*hY�v��b%q���*hud5"fɹ��T���q)������$�����p�BW�a���  �0������gd��k�ңZ�k;$n2�������*�6U�UT/O�<r�i�(��{�:n�� ��!Ň�ܶ��ם��mrW�sk���!���z�,�R{|�h�����ߗ.�r�����D3�O��F� �a�eq���������4���U'�Ew�&��$�@����E���J��[Uqn��Z���b���|?�{TS�[U���j^w���.5iR/�?�Iu�v��a&�[���pO�u:��Q��O"מ�3
Ѫ�� �hAw�h�Ax�?���I�'i U:�U�I���>�/N�%
sB!nB�(�D��w�jLai�
4_��:.�Ʊ@:���X�q�.�(	� �]t����-��s��=i/��c/&!b&9:�^V�HґQ�`�����<��^��U�+8�$�WˍT��ؐ�Xj.�.e�p3�3������o����Yh��GO]�D����&}�f��M�q����[��-�0W`9L
7�0�v�1W '��^��2}�gD/yD*�=RP�׋3�K+�oA[k{�s�Ǽ7+�V��/P.M%�*%Zx�'����=3r�
���w)�� �TU4a��Rݒ{w#zs�4���	�y7v�Tr4�i?h8' Ű���OE�$8-ضy #Vq��-d�F��y��<Y�U&�iQ,�!~]���/ժcL�#���uGT":{N��q]���XT����BNK]Xw|H����.�$���'��u_��b�~�Q���|"�۷f�O����	�B׀8c*��n�����U$aʈX�	�K,8�u�R��y%@{�~9O.�zOۡ�i��U�Cּ��o��q�ܸnZH�1 �9T[^}"� Ĝwe��m��`�L7U$4��
�E=��|� 0j6!Jɴ6CS%�C�m��9��YB\�w��Ԡ�I"�=x�'��i�2J����m��8�)��''��Jq�hMT��I�+R��g�S���ۺ�$��ՒΜy9���MJ&j
����/A]d4�N�MZ�|�$wD:�� p~0�^I�+嚌�����* ���ޛ������I-|�u�)�����e��`wMFK�BG���)nZlD	s����~v�����)�3��e�7c�V�#7��f��o�q]�����?^���2����a��	_
�>ԦN�+@�B�G^�x4�n�;]���֠n&���~�����9��
�^ *�<!�@¥�j�z��R/�se�#�������6��Ժ�L��?�s��0 x�#W$Uz�"�ڭۇ���U|7��!YQZP�{����N��yG���M8��+BJ�l0 W���H�|��fo0�]Tg�`u�6�j��Zh\XE/U^�j�Ɠ�у=����%~{�6�G�l�(��i/���;�������Zb�}F�N¡�|{l�#�/O���XǺ5U,2n¹"(�V�p4D)�P�&;8�m��ۢ�[W�6��W�:��n,�TW'p����Ը\����
]7����鐩3�<<ќ��X�o	yLc�����Xi��@N9LV��	�S(����״�,��]�.&aAF�1t��>wq�	����
D������:��#�?���`��oX��h@Xr��a���YA��j���h0�g�"�WR��Jp�j;�Kj�S�s��/�jw
�*�v<t,��('M���^�$~XAKCi��s���"Ntp}.6�'>��D��BK��S�{�a/�?:ytE=Y6��̩`�m��d�������1|��܆:f��$�OH�xh���TC�^`,/��\�@���$S;��;S�L�>�)e��M��-K&�)6�r8��E��0��-*TK��j	��a*ᾐ"(<�!b�R%�L��;��7ƫ7������b���yʤN	���W�s۟}/�S��Z7����;R�g���Ǭ�Ƚ���$�&��x�5��e�'vs���r6����#�4Tg�Fl��<-�O��^.���ùG��
��&4W��T�����IoP�'O�-����ͥzƥGƵ�b&\� ���"6���+�[(M��ˈ�~f�ɈM?�H�Ǻ��Б�}H���F��`Nx�����^�C��ؑl�-��&Sד��L ��6�z�4�;�q-}�S�^i2�樘��̏�ay�\�܉��)�*�����g��[[��r#O(;��nq��iJ� (�G��n�� cT�=�75¥�̆�/g�G#��U��J�#�9��*���`����$�@� �OwX���4�[���ӪL��%�"�6��^�=ly�9ͅ�S��"�����ujtis:��	\�<��C�s���Hx=#/���~�l�y�1��C�
LMz*;�҄)	6c�� "Z��L�X�W��Cjb<辺� �iah:f��D���C�sĚ�x\����~I�@�=MO�e��#� ����1���-F��Q���^ ?l��C?6�o��\x�}f��&[~���=Z�Q3?CO�C�QPU�{2�{㿊1ގ��T���o��
Ovփ����<l�D&G �j�n���.X��!��B�_��ݜ��zYi'��a=6���9����+���>���h�Qۂ&,�=�̷��tV���{�6E)�����%˜���S��2�7$3��^�����b�57#ׄ�U���r)[ r���T��Β�s�Q�A1m+�L3�(��ޜ�1h���˰
�#T�b�HĆ�́���!����=�/w��o�]��t��Q�m���e�~c׵q���kj끢{y�!�(��^�����K;]�._I��4���!@檦[HD��I�?�?�?�S�Y2:Y���Wf-�q�:8�[��.�����,�#93����q�Tk�C0b���%����fc�)=����49���cG� ��3�Ci<
�GD�ي�{�����=�cMu+c���2�Q��#ώ��i�`z6o��Mm����4w�)QX��
>
��>R�0&!�(��~w:M��F���@���}8��:�U�K�����CZ�8���)�C��H�W`����o��E�bň���'�e�����Zcf���	@��,���r��S��r�X���AiH*��R��fb��'N͍�ۓ�:�9]�� �IqD���Љ�L>���<��wn@ʓ�ɓ������O�N�[MD�@:~�+P�c�q4f�Z&��f8:��'���׹� $CU}w�"0�ܡ�Xf�U#tvhT��ܕԖ� ��3f��l��7�)��`�(�6_*�d���&�֤E:0g�ۋ�p�����8͇�O[���:�O�L�d����ډ`�mq�������⾥�惃qXl1����6�|kÄbSP�bn�r6���LȊ~���h> ��U�k����֎6~�H�v�!���ܑ��V�䂄|7#�9��@��z�aP	���*S�C8������\�a��A���"���ʿ��"d@�4�!�
�6�*�b��� ƕgu����XmЯ'���餆�.��+���e��=(�jf�������W&|8u+�[��R"	��2�&����(G�.pS.���s��X��b&���� H�r ���_	��9��Ԏ�ꑵP5ϝDhS�_�l���9��\�A���rN�zH�?�1��x�W���EB'<�4	;:�\!�|���[�?� $7�Wv�h`:�XeK d��P&q���sv��C��6PPQ]}�7Z���w^Xڞ:G�b�Wē�OxA	�n���')�3'~C�p����K��=��˼�7ȎeL�*1�Uy���0ߔ�$���9V�F�,�Sh�L�l�7[�s���G�v\S�F�w쿸_���M�oZ	7<�-2$}H�T}�ч�T�k}��n�ԃ��*�l����OD!ɖ��l����B��o9&����V�M���9�{T�%W6�0�E�:������z��^e�7jfQ�9��j�s�_�2�k�x$��.=�E�e��_D�X�)h�S��gיֻ�3�W=�(��0����<�(.mAM9Q��"�A�]i�3O��j��jmF
�Q����`���G4k:����t�c�C���3�6�~]�+�P�V�#Gɼ��~ �F�@p�[A���J<l�[���/�$B�ʮ��Q�p��S�lA	��(6܌�D�2����t�O���\�T,F!}2 �"��[p:ߏ,�:28fYZѶ��e5��>	<X�C�GyZ�<��}=渜
�O��I@�pqk/TM,��ۯ\^�VT�.�;24�H��G���g�Ї�	e*�x
��̌C���u�-�,H�Ϋ���s�=a���I��5p�/N�3�����o�
TC@��M#e=�!��]����&��vĕ�[�@��JQm��ak���&DB��7�(���օ�7�H{n��1��`���o�ϊ�l��|�X�ӻ���~e��I���P%���i���c�ʼ�A��O�:zs�����鶹6�$vg����4��������^ϵ[�FL�o��Vi�Rdn��nI�I�*��=:f���˭�8Дm�|����wB��H@�� �M��ɛ{��7g���JK>;ܺ���Lv_H݇
�J���Q���������w&��%<���;f�Od�C��.���;�]�E+y��ɍ�3�T?�K�$��!׶�����C�d��0���lA-��ٷic/����[�#o��S�&�0p�����),H�6�Ӌn{��t������ԍN�e�Z�f��`��P��H������8�j�f`)�Y����?KG�����&�?�<�k���~��@�d.�>�̡iHD����RΓ�,��-V�h���bT���2�V	� �[�����J����pWOͰw$Q{XbQ��P�\�(U�!$��-�1gגd�� �{�(P���dZ�C�	b5��eML��02$���?& ���c��dO���4�l�	�ﺯ����NDx�B6��%3�0�^lC����7k�8^4W�9Rgv6'�7.ݦHL���� �<�Os��餃;+fF ��Ju��L�"g�Z�4��&����9f��7ZE6�I�.��,�Kh�,良	q艳�������T���Ek~��d��w�Is��/�\d����̶��>@���V�+�7�	:�iR�
��bP�K�����Pu�[��Xꥧ��kzG�*�g�s쥄��$Q�h�
�Obd������^��Lc[�-a��8���^���l��9B���L����0:�	TO�	�e��C}�k�cg���R,	JC�4�)Rps`��1Y�s,1ߟ��p���V��I'1��H[�����Y����;�a�}��X^�D�J�^���Y`T��޺�O ~��h7� �d�ys�b�i2���=�j�o�3�_K�!׀�n���;Qz> �o��@�~��6��f���?L���Z4]��E��VG�v]2Yg&�JR��Ѣ���9�S1��]���<��E��&���m!|�*U�>4��B�+L�Vxw~Ӽ�7�{N�ʬ�~�V�=U/�n�/O���'+�
o�ۘ�)[g4�7kx�P�p�N[�~��sl���#Z�/i�ҏL*aQ]��*�e�D��m� `Rg[�#�7u�G��e�P�V�@��]#�@��$�gm�Ć�Wu��Z�lE���������I�����`��H�1�FJ�[�&�b����f(��F)X-�e-P�{!K��\�J��	ۨ��<^q�V҂���=\��Y�,,fQ��fs��~#�}��c��ˢ�dt����0���s�F���qU������u0�\$X�	5�c��̤�����S�?z��;��+����lXt��S�7^��/!�ș�_"۶G�p�i���3�Q�@ft�$"�h<Rm�NV��I�p����+��<C=���.O�F��Ai����_��Tx�z�CQ%-ՋČ*o�Ħy�2���KB֣_�i�ίu3���n}Fѯ����5IF�R�Z)U=<0m���pv�8�m�1m�v�1憥s�k�Kt*��OB#�R���ʯѣ�1@��'��vܥ�T�|+h���g]a�_Mv��?8�Povy ���ٮ����:Wߢ��Y�X�%��caD.��"���B�PxLB�pK�ϸ$���>���"�d�;t�=���.������դ!��:�x���q���L�m�S�)�Q�|^b�}>P=�Ⱦ^���;��ߐʮ��ĝ��H�˭u�Ϳ�x��7����i��<�f!Iq�~"��ڝ?a�d�/��I��9���-Ȭi�?T��gC�'�ɘ�N������Sԇ�� ]з�h�x�����r�4a�I��ikN߮�a1��দ�����3���"<��1"�m�? 9+���rW-�BP�6���Uy"�H��B[�)�s�#���Qe��.���E:B�"܌��
 􈶺�(���t��FlA�������-���ܚY���-2$ko�I'��
�_����~�Wo*��������R �����j���[_��!��l�ϵ(1Ǥ�;936fx���=^��o�;����F�u��2�hU��7���Vb��˩�y�bh��S�!�*W1�( �%Ţ��̌0�q!�6�B�v�H����~!��$�֌<��zG��,0,ز�jm����~�6X;�����;r��
ڮP�D���������.vJm���
��R��0.`������ۢ�����킐���!5�#P��K����^:]�)P�H����Pe��	��[�W}	������U5���x�\������#F����z�XvEX�t������A��0�Y�K޿Y�h�����M��H-v�gQ��g@/�:z:;m�лj#G����>Q.��Z�m�iҺ�{UxJf@ը;br[�
;�(n�@�����px5c*X�>��D���& -R֣���z��<y��W�=��):P�����Q(YfKiK�8�1��G���a����-P��-�sic�q�m#�nvDxKg̓�2$�=~;QëR(7g���Pa�/Ȩ�f;�s����+���&>
�G�s�G���˰�[�a	q�[P�wv��@f��hn���~�0��mg�R����oF��t
h�!�;L_��ќ�*�XO]�@kr�Be�uo�:DO������+d�_5Q`ʃ�rA���&��
��1Xg8����&A�f˝�>�%�ۍg�'����_�r��K��a���C݆sT%p��Q!z|�k�,�	�ɜ�6/���d���?�z�uM�:���~Wve��7� ң�E�AH`ck����穡��}�g{�Dp���c��i�t��)��JސCN�U�F���S����Cf�DJZ��`���>1�a}��F�l��8��ޏ�9&���r+����r.R9�M�m�����Q� �t�Y�X�/����y���bw���g�����ݐ�~��{tt		[*�Q�̷Qۓ+���o���������)��ԕ7�af$��/	�F��U��6%8NV̈́4���	(�Ԥ2:�0"��a5� E�8���t �6�YK4�[�u�!Я�[̡�L]�Am�#�%j�`o�?f���ZD�9)4*��ρ��n��0@C|�O]���5��5�T$Qe0휮�S���ys��H�������:P���mvXgdI}�� gOWz�!����Nh?�t��F	���Ē���"��UWYGH�&��L���	�7=��޻�K��N�[���Z�]&k�Pw`a?�<�{���ewo�S;%�� y5��cl�hd-AF�Q0!�V^� e�,��1	���MhS�*}YG%��7��X��y��*~����
D���k��{�VxBQ�	����,5�!��Ť��Ff�"}����¶�LO4d`��^k�~�9C�,��d�� cQZ 9��o���%-��-�^��|�vc��cI\9�����؈^����6�y��[��2���_���4n�DS�n#���o���U;�̭��z�`&΢J]����qW���=�*�Eޒ|:gp]������k ����:�=1�d�
�'�=w��bS~0��P-�������t�d���j�~��.h�����aa#Ti���Pޠ��s�u�E����N�&����^��4�ި�A�߁X/�r5cX��KD��p�΁͉� �`����{�!:�x�+T2(M����Aٻ��giZ�JYɋ���Xa�	 ��7�.��A"y��{��U��uN��Q)�=s8m kyy��X|�Տ�0�Y��+`��ޝi�okx8�QF��NoQx���{μ�9%����,f��dcͩ�s�]���K���_��l��?q h������T6 d�Yq���p���R$jt�
]�c'��0�D�������� �����R��N�l]g�v@��R�RT�L7rxx��>�/�#x��f�o� aeO<C�<
��`��+H�ׅH�o  �ٙ�{VG��Wa�����x�n�!����N�8��!P{�Z�j��=�b�Y5��<���^�T��D"�7���Ewrq�b[m�F�EӕUp���lL괆<c��V�����"���������2��M�کH$#{��c٧=��,0�)ց5�L�u�-(0�oy��ʰZ߆�N����wБ�4�8s�����d�N��1��l�]6���Ь8�t{��uo����tY���!wWW�SՔ��+�,���X�E����� ������Yi�E��l�f���l1xҫ��Z��1�>���~��/��VR�PVsG��s���,�rzP^p�=�l/����$��A\��G?'������9��ӱ�L�!u"/�G���y�q�BҤ�}�����{㗯4�D�M_��5N����aߵ!�$ �[P!�Φ��>)�M�R�	�w'�`�$���fsSk���	ىb\>@����:QI�қ�A�,4[�KTK>	�.�eDyG	t�� k"��(0��: _f�bWiy��0�7�3�ퟟ�<ƧW�蕂�T��z�3�#^��C��{��f޹4S��S���$p{�r+��m�)���s����� k�	E7�f$ ��0B���w�7�l�f�ũ��"�#�r����G,o����I�4�����D'rAe�)�T��0�8�;�o<�U��,W�����dC|G_�����1aC����	�SQ�`�2����>��78������
 6�~<ƪ�>�eK��VXb�����������T.ػ�Kh��(�m!-c�`a��3OkJ�_��k�F���:t,�= ^�rGMO#�z��Ho6'�i��h�s�h���OR5�O��9����3道��gb�j�o���\�MbZ�D���D>��y�ڷ踼eu�������ȅ`3@�7LA��|�*��o��C ���,+%>K�c�)�+,�&��[0 | n�=~�����~*�t@s����'��I
���o�Y�γR�e�/�PN���|yX
d�QMtו����G�%/BS��l���cm7� ��N�l�v!�w��[]��/�#�YE	�;	hI�^�,����k{ȶ�fP:-����s���C�e��r���kR�:��oȖ<���U�����5���k�[h�3�t:3��!���
�;�T������B�K�IO�-e�`&0�&�pn���ޅ9�1wwI1<��b�(��Wrn⍧���S߯�%l)���T�d:�F�����Q�
~v�.��������I�C���m5�!��o�z��}b���k�鮵֛�Q��S��U�}���5���+��7*^��
�+�L@ۜ�q�m�͑ 2k)���:6�m�_�?��j�ح����N���N�Ǘ��Jd�ĤJ�bz�y�� ������v�F���-W)ٌ�����ć&J?m�@sA>�`+l�e�n]�C<N�4^�-�7�)������RD�>a��+�u����5Ƀ�yG��M/���5fsNM����/��:��/�4��EpO���"��[e�* ne�������)�7)4Z�*�?�
�E��;�4%�+Ze�%\|��w+  �^?�tN�����S��d�T"��䓴��4�Nˮc�!Fxd������UC��k�/��� Um�?&NS촵 Np��=3��Bhτ���_�2QM`�S��d1�G��*P��k=���@}����猡u�w�݃����.z�C��`lŲ�����n)ǋ�U/w������&R�n!C�32�D�b4�����#�z���0W�M" y+��[uf�9���2��$�荖�����]���C:�㪴���<��U�Ow��͇tc��s���8T�ZmZg�/��������o"��{������@��۵ɣ
��S���;.�aJW�9k�TFb�YR�����:��r�{�SK{W=`E��G�<̹x�����1��੤ck~�����8���x٧,�)3j�M�>�yUGJJ�>���|�@�X�=�}XFa���6���47�.�u�9����C7��#�~Ƙ1���{d`����	mA`��{��Sڠy�J�!���f��]��X������(���U��U����5�X�Sht �ن����{Uw}qVdg��ǫ�?yP�ԗ�c��t�+'k�$}��}���w�Z*`U���iدL��[u��a�&�zK�+!Mez�B���wd6�أ�A[�OmZ��x��qEm�.s�Lg��(Oۏ/�ol&wJ�Hi>爞z�rր�N䊥�����(J{�"Gr�R@��	�D!@|1<�1k}�b�䷪���y���-ծkh��Ot4��6�]�%���.C6J{s$vז��Ӻ��bC���/�Th�.����k�����I�G�j��?�_r]E6�#�@���>����)�k�a)��ݞ3�
(��&�6lC
�ٱ��.�O}����� �?�&3̱%��课a��w�a��sV(Q#���ڎ'�9nWj�7.�P8���O�F���b�z3UP ��i~%����#m/�e[ S���L���>,>N*�� ��Λ�wG�&3w;9���hl���MoO� yg�������\F)B�{n.���Ba�R�NT�f�1��g��.�[�.�K��@�&O�SG����w��T{����w��C�I1BYō���AC�nOݼK����:�B�}�H�^� ݤ��Tg����s��h�1�����[�=k�k���1�*��כ�pD�.�Z�p|${I�����$�W��>��/&J�S��P�Ld�<\����+h������I�ۃ�^Y-�����zN��l��G�'�V����	�{(S� �wS�3�RZ`�ƀ&l�j�(z@�L�l#��\��3��铋�K��1;A�e�F��9�!��F�.�	�-z�����I�{�1�XØ;�@�£Bf������w�(�"\������"z�n��Q���пo`�w�g�����h��Y�n����7���gu��|[]r������U��>�V��,��Y��W��	L�c�t�(�t2�̶>�Q
��5B���WG�T!���'|%�xL^XO�p#����g�69��>���I7E����_d-K(e ��"����� ӓ0:�=Nep�W
��o��*�'UW�#Z�Ƃ9��]1���p2+504cg`�N�W�k�2���S�#�Ͷ2�����%����W�&�_d]&�]���-���0#��d���h��uT��%�%l��V��O^I����ZK�Ҍ}|�_�N�AR���V��	-�	!�t=+�&��Б*�	�h0M�����iڛϞ>�]��y�ż߅6"�s���
��,~@\ߡ��!M�Ņj�J8m��S��
F�۽@�&�'r^W8� ����<�Ꭲ>/��V��`'�Ԁ_<�(�$l'��Ϗj�+͝��P���;�9��Wh�b�3C#��v�r�p� ����Ûeyv$�`�����!� �X���\�[0�M��r:?W��wq��]�t�^�Y>>��*�:��?]��E�O7KiP�3/ǖKVQ��֧�Al�C����Φ'��=�@F��_
�/@xBaF>h�}<���YF�O�l�n��Пk)n��`��L���R���]��>�"G���
'i�&׵��KӠ�]�
R����y%�k�"-����$H
��2�4z�%�g�$��˒\�Ѐ� No'���P�U��<�PSw�8ߍ-���k����[jV������悮p��ϧ��8ʯ�E�v=�>R2�����[�:����@�0C�_G�}�k�y�yc��Yd.�U�{.t�kcO��J�3�g���o����J���n;�e��O|s��M]�(�V����6��$����E$��J*@��7��Q8]h�G�d�ck�o	s54��7�"�z@���}�ժ���L��ω�P�<l�{��V�c��ƽ�ĉ��{�`d0�%��J/�!����r�ئF�w���@�{[(?��T䵞Fo���^���Y�ب�nwj���C���9�Ym�8��K͐[���M>30������X���R
Nh�<�b�P�ƔN�g����J�M�s>�6:;_.�`%�O����tiM�B��>�s-�sz]p����z9��w��¤�	��"u?���Q��Y++$<��;n��q~�C�s��+�!�?J�r���z����\&=���?��u"^>����nb��HQ���y�/��vR��m�=��y2�� I��p��� �Xs�R�O�Z }`��z�i�������j������â$�!^UT����"�׌	#�� �F�Ɖ(+�5���-����R���3�e   D��ۢsp ������W���g�    YZ