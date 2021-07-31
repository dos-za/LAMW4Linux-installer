#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3891988386"
MD5="68419a8fce3206ce84d1d4d1ff40eb0a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23440"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sat Jul 31 15:37:05 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����[P] �}��1Dd]����P�t�D�`�* W������畹 ��Q�V�٥����]��8��tvj�3Jp]�o����0ڮ���EN`�ָ�.=&��Mq詢�VI�1�Y�گ���(�w�G��bb�����Vd����^e:�<�/�0D9D����\P:~Q��黫�I�f�qT�Q�k�A!+ƙ`aF��$�B1�M]7dHm��������yP�ŝ��G3�#��Xc��HpH,��\�G�~8��%c���8�13����(	�Sji�{E \�ωڑB�(�{�B�y�$��lʄN��G�R���]x͎vCr�gq���b	��ddf��&D���q.�t������I�t-k�����_ Jm�����Ӽ@����^������(a'�$�Up�J�BUC��b�2�p�>W�P�Q�i�(>~�i����aA��	Rѣ�v�S��(.HFs�a�I��.<�Y�����P�_=k�X�< �z��
����5Ҧ�iG��� C��
�[�C4���-�P�;M�9�{l-�gqb8��N��#�9�꯼��I��*s�.�M4&�G�����/���6�yJ�y>�ɞ�%�X�kƎ�����v�=/ ��L�sH͂�u�!�ӄs��F�n�y)������ԅg� ���ޝc�w�����p;"�����/!I#��g*��ǑF@q��b|�\��a��Kg!"��$$T��V�N�&�	Ax�M-B����d|zr��֩	�B��M6�5A�0v�5���*��j�ZB��^� |���C>lU�˿�9sEf����ɕp�ˋp�ܖ�Ԝ8���@	��D�G��4��'ROP������CT��E|Y���6+��g�>᭾lN�r�pc���Z0�Q�֥���=�8�	���Rj$7�Mf��6���~*X��M�9Ҽ�34@A�й5�Z�<�+�8� `��\Ꙃ�U%.������@�b��L�{����-�px8�0��ڜ�>�^؜]"�f��O�Ng�a6Mw��Gļ;��ǳˡuP�(��T�ƞ���R�C�{S�|'����ԟ�'�M`�*�mWK�l;�����c#��鈋�D�CIܽϾsȏ�R(��n�����e�U���F詔^�9ct��?Bs�O�pkq�����i��~�~"/�԰���� X�-&-��	��ŉ���Ҟwr�.�`�8�Ǳ�q!�Qg�:��|c�+�6l�OOw�L�
ۄN����U�>����ɐ�PG:�Z�\r�԰�M���B�?��=B��>	}�m��my������;�p
m���vQ�M����ŰnZ���"�A�<ejEq�>O��s�7���"f�$F�J�I~�g�d�t���z:V�zn��G-$��rs"q��խ�] ���y[�)���r�1�$��n)��b���~��P�m�(S�����)��;�V���'^6FtS���������4b������LX�8~�k��׿���<"��}���?�M��3�e��@ߔ��L��/��%��а��D?Y׈��V ��B-Zɂn� �٫2z�/���ۦ��Bja�� �-Y�LN���	�6aRr�p`�:۸�&��Qr	�$"g���EzWg���p��c ���r#�e�����͎.�>@�^N)C6�j��M�]9BD,�8���(�*&���f�b73h�����y}�٭�B�F�4��Q6^E��N���p��m�V������2ݔ����b�X�AJ%i�Qv����O����6��8�ێ� ��YC�-�[�q�q�n-x�:����*ͳ|l}`��J���|-r||l�.[Ɛ�a���e�l���d;�.Gcfd�>a΋�@��8�dX�S�c<Q
���ڈ�G^9�������K����.��['4���~^w�4�U5��o-Z'�B��d-L�m3[&	~��ǥH�66	: F��{
MT�� �6���u���Q\����~�9���h�(b�}EV��vOe����+��§81[�2_w��L��� Y� ��gp~��U�@&y˕̳��w�^�]mx�]Ў2\.�'9���!�>?����T�/�X�j }����!P��(.�ꬸ���oD��A�hy��ˡ�F���r{4K���`'��?����`D?m��<Mn�]ڑ���P�hD�����4N[p�/]`� �7A�������]����}ۻѷ�#�BGoj"�0������N�0]_�'CLom�)r+�p���/�ף��3����U�X�˹w��:���b��u�%'�:��b/U�9���3"7qx��3c�9���O�0	�yL� Y?qj�z�(|�L�˫%^||>��n;0C���["�S�E�<.���&��'�~���7�)�ap�~2|�,p���'7r��Y��&��s�n�8���n_�j�Ȕ��<6ύ�)�ne<q���e�]���m&1������T�4�d w�G��hz���
뻰���(Z��z�˛Ʊޓ`���n�J+�����$��5��=D��ZP�\��-�YvM#����e:e�e�u_h#����U���%����x����`�N���/{(��:�p��j=٩����
]�q���;W�\���d��b3s�&�hkSc=��]p��a�ɒc���j1��ʒ���&d�9�I���xa���g�;��0�v��D�TWˇ�d_�pF�� eRF�(W|��l0��?�ߨR[)�\�� �V����_���4O :.��y�MvM� ��|�"äPg/;�U]2�:���:w�|%����A�\3㝠���Aثe�rl�
���t�f�'o~U�Z3+m4�+ 3�����Fu:�4�}=��V���&���cP(�< �L�>�2�i�c�mB�t����6w�\8�N�0�D�!���e>�iѐ�X	2��[�.ݜE��G7K:�g���V��w�y��ba���y;�6��終<�=�L6�q�>�%�����@�`vd݄;�wo�1��`l�*�|=�ο!K�v���RAJ`�����CoeiSX�#�[SCV��f����esei9���uYd��8n{?����L�^Sm(��,=/��U�:�15�����[�t��XQ���&g���1^z�I�7��	 �GC]�|2��DE�O��T��y�����,O/"v���NjŜ�<��&H�w��5WR ��@�M�aU��e8VB=�o�yx����s��:��O��YZ�F�R��,����\��$����;�h]qDI7Zp���S"pn�v]i�k%���o3�+��n�L��N��6j��V�+��B
�n���_��6���o�R(�D�WN��ѿ�8Mbw"��z�=����o������C�i5�QU�%��4"�ȡ�,|�l�M�\w��?5����GST��{J0R���י/B8����:r+D�e\������˓l$X�� ��!��2ʥ�Ra���y���o�~}jt��T&.�)�ES�@���/��GN�Oe^��8��f-��(֍̒�Mσ9��g\�wa�=`�h��h�]�GQ܉��* � �3^�G���IV����LG2� �Ρ���ޔ	���i=�ƯЇ?��Ɗ�������v�U�Ø
�(��?��8��.;��upK}3�3�����Z��`��(Ӷc|S�m�9
����0��h���W��Ab�j���i\�d!�r;y hs�e�4�Ѭq!;�[D
>V<
c+�����~���g$+�drS���T���;Ԝ�u��W��K�-��a:c=���Z�������,I��a���oE�}����$N�y^N�,�J�.��0�����n#�I킮����j_���B&��$�T,�l��=���h�Hd�U�vxۈ*�au�������5]��{���7	�.C��O��!�P���p,9!p�M�B,�('��Rv���bƐ�մ����\R0���`^(m����td��5�~��-7t�1���+J,��{�1	���Ḍ/�֥�'���=�O�	��p��� 폔�{�[��-lȑ��]���C�Z�M��Lm�]�Ξ)��Fruu��uP�HOs�˺6�7£	�&g�ze-�(�v�JM���Wh9'q-Fzg|��8����/�6���f�}�+Τ�@.�4���D��U$���p���_(R���g�N\��+�N�����_�mM_v�����MEu4^(-�5e��NC�s��E��ǈy���U�r��
uZ��eozSi��B�c�T�h�:k�f������E��V�v�4�׽�`�v�Z�1=jfݶ�'z�?��։˙8��8�
�f�>�	��И�Δ��2ЍqE��ǆtڦ�x�-���Rs�z�.X��#����D���/g�O�S��f�Κ���^��Z����p�Ww� #�E��(Y��X[h�ե��U�[b#�Ϸ�^������5¼}9iW�cO�̱DA���َ�i�.�Y�Y��$�h^C����g���B��w]G�7>��H�.:��ߦ9�y����u4��=���1cVrAwE�=��ɼ�r�^��!'�ς�� Ⱦ���n+�������E�[ �)Kô��ыJ�����k��,�FDN�����@���x�6pF�׺��ۯ��w1���h�+1E�'c�,���׬�~��kVCP���۹��Q�|�W��F����p2#QM����n�M����F�FA�aƋ�kjPuRO�l�.I�w�BD��l�������j�3��$z�:��}���)���x���|�r���&5�?��M���e�q�7�����%j@���T���VC�9,;�ِ:p�̓z�r��.	�c�R;�����@ʃ���+s~�|�^ ��Jw*+���P�����	
��:�0e���n�lF���7=0�x4�}S��?� �
f�CY)x�p�q�:�d"�~���+v �}xUSOX�	?�y��`��7�6lH�������"}��B=����db��Z�����Zl!P� �aITCP@������3�&ò��`KBn�9yђ�Wej5r,ֲ]�e��p�#BűurA���e���[+���<�>q�Q/�v��߹��qi��v����
��L,b�O�un�
_�9��F�u�=rP�i.�����<r��:�ڪ�s�Ez0Vg�N Ak7o��%m[�xs��3�qXf�я�74��I]��{'����(�i��0�HM�{��{�)�x��)l��G���K.Z���4����-��"n���b�@J(h�,�z��8#�l����/mG) R�`���Iꉊ���eb)�����A0ұV���-�F.���?_d��_A���n㺊KV�x��l
����v`�d�Ş��X�g������jю϶j��o�8-^4����F��ܿ2=�%����C&}w"�私I5ѷ�������m�N��:7i]�gʅ���粢��|�|�/�:���e\����]�ͷv\������;[Z�M�,�� �s�f��.'��O+�ut��z�BE��Ӷ�$�R\�nw�}�:��V�SN��՜�5�\�Y�3�&���a�1!����6w���Ɋ��$�� ��1Ӽ�'�����9�s�Q��Ϻپ
��<�#�T�ª���9n�8����;��J:��������!�e(�{���ݏ�X~���g�7���!�S�i������e��O('V��u#>3i�Z��?e@Ǳ��KS��t/����dkVřb�o�ݬ�x++��ha�a�ÓD./<9qk)�lȑR�5���lɲc�𣏲1�>��P�\������lS�O��"���!�iX#��~U��+�=^���s��aO�Ǖ�нg0��'�:�2_��kd��� T�<��)�6ө�����LZ�+_��u�U�q���Ы$=h0r��	,�*N�EڌL;:�w��)[�2j$�#X`]�Z!D��_߻�*<�O�8gP{Yt���S�\���g��j�ϋ�����-�cu���t�(�a$��6r���q�������|��.�v�����1�2���J`���
��E�%�	��[ZJ-����CG?j�%���qE�چ�@��5*�}0ף��Q�0LN.��ޗ���t��(�c�)T����IMd[�ـ}|���g�x�̫�����y��4�آ����r�E��f�Q���E̯���d���	"���S.������s��r��m��
@%a����H����K|����$Sz�1�y{�����Oo�ɥʟQ���P����p+��L�ʻ��X���F����l��RJ��/]������z����@@{U@�w�ͪ�V�$�o�!��*���G�4��<c=�e/g˿��G��0��R�[:��f�����C0[�d��/q�ѽ���=�)�C��{,��_8�ŷ�<��Ath'2t6�\�+{�긼e@ՙXF>�\X�'��E%;H�!D��S��t���w1�0���oZ�-���Un�8����x������v*�N�e�GJ뜳���A<�"y�AY�\�����~�o�%okT��d!L�	�JE@�;�5�b�~�4n	�ڒ�d� u�v#S
:ll����X�U���t�w��{-�!����g��Cr��(����y���*wv����\L�X��^����w�٤X|hҒ�D���:y�{2�0��4��=�Y�e1Wk�W�a�(_5���̇yҌ���Հy7�fc���?�nJ���'e�l�}�N��[�������,��'��x���<��� �w��7=��A!�t����,���Y.���E�e$)�^6��z��4��\�/'�=R�J�e�Z�ǞvK~(�[f.�.	�7�r�c#�������J�����ݢ��f�z�|[����y�L��6��:?���6����-��̪ڔ7L��"d!�@��X)�|�+����t��-�O F�26(
���7᜛����J�������O�������2�*Y4��!����N��I�0�b���r.s'0���t��<�?\6� _8���؝�K�H�ڊ�Os����hJJ�)��ENځ$*�6�+�������k�d�9���y�!��DS���J�����i*��m�䕎|�^�>.�T�θ��`"���|��������]� ��6�h��XF�2 ���R*c 	� ��:�W���ͫ+K9���9R}zj�Ty��X�K����t�a�f���c{�O�Cc���Co3�.�?U<�<Uߥ��L!��Lo��<��*�nf��RYh��0�l4��'�Ѫ�	_[C]��J��Y��T��H��k��pQƾ�8������+)Pj��f�'U�<tս�钕w�8Ե]����X�i���Y���8`Ր>�8G�1pD}~����5�vz��I4c�-��M�G&��t�Ћ N�}7p�Ssy�ى��&=)J�ٗ�4���!$Cy�
�r����&5�$s/u���i�)!Mo��-�d�_�����>��M�{��u5�>b�8H��-.�Qn)���ӫ�1�������(���
f�W2���^ Tt��҃$	�(�	rW��޶�KcB�/Jv�v��?��$Mu��1F{��`(����6et�yOԑW�Lݼ��g�]'Z���N������6��q3�3w$@8�hW�Ě���|���˦Va>��S\�8S����贱T֓��W(Ng���{�v⏅��X�<�v�UQD8�V#=2�G�����c���2.UU��3����k��?׎��[sl⧇?�E1�ᮉ�1QȭZڒQ���$b0^����t5��S�C�'�OY�ʌ�+w>����Eg-�0�Z�dz,\L�wuyȳ]d�ֱVNV��Xs{*�<O�ǢD��̯����\�{�G��3ڜ?W\7��g<C��ﵜ��{��. ��U&(
��
.u��vTzu��g���59�T+�l�&Io
fr��scX6�����AnuL���*j�ޜ�󈥢��.�
��,+��o z�my�h���9P��8A�]e��#Eċ���T"���@.Ͳ��pxU�����\9�(�=��N@1	$�Ɔ����ь2�_����ǰ>���&������_6�鳔�����IRzư�:�nq�C_ɳ_�v�@�Q��%?�$媃L�@G��(P�����RD6|G�����K���+̕�,�l��1VN[x�z��l,�ZW��6�`uk�|�����5��v��gZnl|�µюz� '��zt�Ŀ�¤l=��b���5~��� �r@)U	��$4sd�e�%IPd�`l m�wk
��J��L�e��6�r_��h�Hz�s\_����?�҆$[�z��=
�:��Ov)����\x���(y��cJ&��Y��UlWQ�m�˩��� ���ߑ�"e}@00��e ��-����'m�s���+��a�}��k�X[1x������5	y�^`B ����`�x2Df��n�>&���q3lHl�^��{����Q0C��;��
4�@~�V�A�|w�ѰP�Ni�����ߌ��Ž�J
�Tud̝�95t"@
6��åk5'��	#:T+�F-���z�Њ�� jE����ɐ�}[h���(y��y�k�N"h���oC3L�T��9��!�I���<����h&"K�bnJ,���1zl�p)���W/�&�̂jj)fy���g�Eg���s���C ̈́ߞ'F��b�h�c���Z�����x����%ey����Of����������7��I�~S�d7�1	�����*@��~���� �i RW	��R�	=.�`b����RbcB�����	}h�O�]UL��]c|�(AF��:��-��;�)��B�>#d�A-�C��j|�4̞�������B#��(JE�t�H���E��T��kPpS=���f9��,���tݒ2�q�p�uzD�E��{�4>��%��.USs���oЄ����C���,A��#�p��:i���.P�u:�4�h]�8D[c�Z��o�L0�MO����/U�`��Y|�[C�Ci����-���9�Ǆ\96N��������
)�*Y�W�����#�����,	���;�MHTj���T�Nra�߼� 7��������q�]7�������k��"`�ܭ�sʈ�l���(�35m�k��wN�%�~�swumi:�����!��yCYDb^��H|��h�!i�KY�N���P����%�Z�FGrdư/��(S���3~V�*a-����J�jH_�*�LP�0+��^y/P6�̺%��0#��.$s=�g=YDG����i漥�O��/G�|o_q��{��v�]�2~�w� B�^�����W�Yv~
�lڐ.|f+߄U%�=�:N��Eۮ��r�o^am vx/2���!�G�V�l�K�4╡r�6;#��k��
�|21�߄��u_�Bo<z��Ʀ�������K#6�tI��6��Ό3#����`?��"��(&݃�rA�yS���8�?)�pS�fz�E����1̋_�*�=:��	����d�S�C�s~���q�����?_��[Ώ[�Wd�ڛtR80���N�����dy�)1��T�z_�{Bc6gU��"i {̏A�� ���=��Hf
�g�`-�o�>}O(D�8�.$�l��O(*$���n�C�<������N�P��!|��c[�Jk6���Cޒ�s9���;d�n��Z�|�6�;Ck���������N�yiJ�җ�k8r�|����"�k��Q�Vc��F��硿5h]=����Nq�l��gAhV�_����H�CTxu�Մ�=(i;�֐Ԣ��y�Ŝ������7V=J�=� �)�1ƳNIJ�4�x_�"� Ǧ��Ù���.��`»*��#xx�B�ȸ"�H�X� �p�LPP��J�+AnfDƛ́R�|�8���^G�dY9��}t��[hDQL�ͤ�>[��)B$x�R�<���C$�t;I�.Q�E�n�Q��|��8���J0a^���X��Z� ��䅠 kK���p5�?�����}񯷁��ʒ�/��ia��Y���e������:7;O\���;oK����U�^>�н�#�w�l�<T���<8/�{��w�񖖪���_t=���Lz;�T"-h��7�Qv���:fOBZ>v�I\D���a����u)[�#��(W��O�?-��wZt6�/����Mo��cz���Wd��1�3�}���w!+��/�o1]X�"�k:A�$�������:���'��YOǠ� ��Y8\�r�%&�w�r'f���x��7�-�-�Ε-+R5��gw��M^Z?�$a��?�7�Ī�!	:���K�xx�o�K#\ީ��IFLM+o���Å�Z�x$��O�I��$m.!�1/�7��r2Z��FN�T����a���� ͕"��I A6����F����O�H�n������[f�&{h;�2����Ɠ��<5��ƽ��wP�vrj�̷-A*n�Xb���=��I��+�1� vWS�+�ެ��r<�o�K�J�)�eTT�%sflov�Q$�[W����P�%�K��v�)�������tn�?�\`g�÷��2͸d,��ߑ�A�f0�WלnOPt��I��1@�K���q�3�`CY?����M�����/c���v$��D���De����@짣

f���[��}F�7��_�o��#=dA����X�x�-)����\��#]I^��t=	�>5F�AV��I� �[�ם�\"��MJ�i˝�v��oZ5~�~wד�Q��/�\�TG2�c��<)I���]4q<�.V��ٙ���t��?�{�<��>F&�����a�G�����Oh�C;�t	����kL�&?���R�qu��0�_�q�$t�ӳ�ݬ�i@�
;��,�б�j�B��N%j�4�M2w7�ݺ:R��`��J(��"En L�.�g�v:�>�V�!M��;+��
�' ;3�+ �[�%�c|��f���G+��%���)>${��`m*��𫸛;��K���T��h��	"]LGY��I�x�n��5�2vyV/<r��A/
>@ch���[�&�7s�>L,�'\
��7LA�p>7!��f�a��Si��d,���K(�0�-�|4h��*�'W&hg[��c��]4�ͣ���}<N�Ü�c���Xn�;�]P)$�tD�5��$�aB?6y�
C�%�E�w�͜F��˜������*���Z���A�����2��kg"�&�a���Zq��^�,�i6�]H�{֡��Q���b�T��{޲����Wf���9[;��{{	�NcP3K�LH�?Q�s���l\�H�'��N���c�B�柧�����F@3Q�<�nA-�׻�X&d]��o`<�3űь\�D��_�{��{�xZ|��k��X��.�;��e�8�=ɡ0h���x(��~q�� ,�
�3ߵP��RTC���$��J �	�F�A������P�.Z�N�NM�S�����9�y�H���&�Q�p����e�"�L���H�r�˄p��*3�����d�7��M���'��-��g�u��>�Z6����NB����"p��4|UT��[��S���a�ѓ'��H�a�̄2�c	O��Qms�9O�c�*F���^��F�NV�k ���\Dd��Ć:�v���k4����E�%[C%i_l�^@'D_�ll�e"�?/.���Iס�ov��� ��a�y �_�L�oˋ�A�B��Y���N���:VV��QmRF �1��K%���i�$�
�_�ʬw�l6N���A=8g~Cj�={[�!�؛у!��Y��Sb�%�#�)! ��/�r7�
,��c�ך�\Ebٌ�=B��1]�D	�`��4ؔ籞��8��C����E�տ�}7_��ER�G�o�����?Z���	ʺ�d��]����dZ��:�L��,;����� �-p^I]��'�6���v�d���c`Ey�g8e���>��p-�ѷ��Eԫڟ/�-����O�^����M�#�t{g��Ú���y:�VZ�=�1K��r�Nư�S�C�p�>s�����-[}Q���O��@���2�ŏ�3�b���8t9G��� >�A�����S���5[a�XV&=<�8d@vo{��+ă�~�?��z�V��IAL�+_��G=�C|�O�44O&��f �쏉s�W8�La� �Ĺ���$8vƯ ��8�E���ZEئW�n�#˃q�Nk��H�6���e��O`��C
a_�.����� ��@�Z}�>�xPA5ZDk�����X����h`�)�`��,��������U'�)P�g�+�N�D�F@j3��xGvv�si���k��\�pl��xW�@k��+�7�C��\2�w���eN��� ����I
�PH;
����)j\���*Qɲ�����Qx���渷���~�m���XC��<LJ�r�ݧ߶�;� �� K�_��^�%IW�h<N1!�wGͶ�Q��b������Ϗ��Я�m*��ϴ�}��2���&�.<Iq�J3��w�" qT+��Klʂ��?-��Oj��E%��n�!���G;��v2�ηy�șYQ�Xv�>V���f�4
��W8�.}�`��\�kIU^��?l:�h�ҹťm\��!�y�:���%��t����A�����b�;�[j��_1>�s��rw��W/�{�2�gv`
�Wsl�8r���u�?u��`��,���(�3eP������$��K�3�^�����Dg����J�hZ`����n��'Wt{�ၚQ���(ןKI�bI2��c�V9�Zd~��[>��>UIk_��C���CG�;�
RJa���8���)J'�BL���<�/�B��w��cc��^����<}]���s|�L,<��G�ahb>ځ��k����>�R���k��Q!n�J���������@��/� ���9S�����_aB^��w[:���PM3y)��/���E6K����!ఆa��O���@�?��oQf�:0ڹ��cd|`;�@����7� +f�*u��a�<E�YZ���6M�G�o�ȴ�4.���@ɣ[m�!��|'6娆N����R�n����ux���Į� ^6*m�sTp��m�d�؋��>�z��)��O3N������{�қ�d�d�!QT
��ۡ�i���:�JoO_N�UWh
XWQO���x�6��p���m-
�/Y��{$�C3�`�{+�-0TO%��0��Ė��X�R�].QU�	(�Oy�(�ӑX�l�tӭ�����F`į�3Fw��
6;;v��_ʂ�H���JW�}�.����yWǚIH�V�8�~sEO³h���DL��|u��|��.m�%Ԗ�Ժ�&�T�s��c	�/�gh˝���'vbtz3D,�~Z"	R�yr2i�u�,���a�P�Z8Kl<�������3�f���O?�\��<E��ti�e!=@�ɪ���'`|�h暆iQC��n�f����a�	�m�{$#�zIL'���.���"~	���5U�h��\�24�������~�!���s��tۋa9�Y�늮��P�oɉ�%Pp1뿽�wj�`XE ��6��u�U�������Ԍ@҅�#���|h_�-�"��T�=���3�v�տp�7���tm{A�<���,�a_u��XҬ��DW��/�f��g��'?r���-mf�����Fz�"�K��t�R`�
��u�w}f�o��Kn�.�3��\��t[��
��٭#�����nk�Ӵ�N��SGL����A)Z���'�6^����g��0���_F��2ڐ&*�z}V���TSf��-}��̴��A��H	_N���N>d�@�2Il���4�u	d��%�uf�`4�uR0R�Q��k����d~F�i�j� 8���i,��O��@�.�4Pm�&�u?	R��������ɟj�Q�ع0(-3	F�~1Xs�v�6�uI�"}�:S
GQ��k�3V�}��U�Y%q,�ƅ��h����Z�=T:{7�X�뽠���p!�=����H���	��D$��GN�`-�U_޿	�S��#{%k�*?Xn�Db@�\)xɍ����0�nU@)��ԩg<��)�+B;v�.�I��p}�'tn�}g?�ϓhB�8�)J��-�4�6IÁ � {� �;���S)��l����`r�P�b���b^�({7��I��2��HD�ʹ1�r�yQZ�qW��ovښ��z�P=e�#���s�aV�țÞJ�i?_�߼��	��(3?ě�|]7F�Qr�u���ٽk�h�@�4�}Lvz��؂���Ê���]_xP}T
�dx �=�>D�[��ep�#��^�\�wN�[��L�sN���7�����#.h"a �f+m��F��13��X©�PX
��1%V��h�H�)�������x|-fچE���A�S��T�)-��s�@2]1�qY'����;���_D��{I�=��%qQ��A�
���|%r�GVh	�[U�ao�*�'Fl����l�y�m�gk�Bm[!��(#;y���p���ݘc<�֮��6�e������C��v�Zj;vo���}�n�A<��ϭҲd���S��7���FHH����1�Q[[!��<��Z5���(�+�|�L�5�G��������A�">���.0��;"�蒺�S��O1������h�6��\S~��7�)��.p��3'mO�D�>��|�x��@��Ȟ%Lu���?�@_�����!Z�Y�:�����N�a�HOt���jk6��2]��DUɐJ�!�ad9\rY��`zX�,��_lg�s"�����V^��B}wa
7b��f[5�a���V͇D-�:�3`L�������
��`�е�N�f�Ű�-���26p�����5��΄-�x�$y�B�ooE}���<7-L�S�S�"�E����������w8-t��ڔ�Y��;��
�7��=��zi�0�ĺ"�u{.}{a4@��@;���l�#��-dWS1Fl8u�Jޏ��˶���L�2��.��h-�1e3|���Ka��'F�0�n�7U��O�R=m�V�/��z^���g0��y!B���'lp�٪J"58�f��B�@��S�+�ܽY� |��r(#�D���T�k�
w}���q�YJ����+j%��w�zu����_�u�w<��
�.D�ѩ_�|��:D'��z��@���kT�k6	�.���+e[1��YNh�1�'��T�a���p��;��w���iU\W���d���?��AP,�%�����9����-�;�!��&p�j�tE������L� 4a���z2R������Ft/a��IL�D sC�út�P1+��{�.+
 �eҏ'�y���3\ݩ�4��)l?��lN������z"�J�����ސ/U���wH���Y�����m]�G���L�7$M�#�6�4��)9�\�=���9ͪI7�1E�YQ
>����H��Σ��f��X`;�*�S��%�Lȹd�L�\�͈��Y\��`�?j��=�!�cY���~�����R�D�j�-<�P�����>�-�1����iΒ}�}�gbb���;t���u:� Wc���σyO�E9�"f�3I��I��z�ŇS��O�[[�|���po���T�VXc�
R�����$�c!ʭ�As���̐"�����N~ܻ�R(��A�.6VC+�Aփz��c�G�����t�XX��)��d{��b}V��L�7g#R�B+ݧ���[B�qZjScF�٢�Cal|z��:��1��)��쇉Y����d�[��$>��%�RC�NH�&�FA=�O:Lñ�ӛ�Vl��֕���Kۛ}	��ݿ�V���BQl~j-��  
4>?�N���H��L��������Ϛ;[H\���?�}I|����� t|���tr�BFd��,����)#��c]��s�2��]U}��I��H�*a�y��g-t�fbC鞡�X��kh;� ���Z�-&�,��Qҝ���V���;�o���p>v�V�
�&��֔�?�_B�.���9��z �ף*�t����wF��?���n^����|��3Ha+f'���a��X|\�ۜus\�\�	��.l�伺V���U�b~�zç	5�|��%���)}?d�x�S����(jn:I�@�������$XI�mջ���JGcE/��0i;�@ʽ�C�Y�a�[����'eb���pv�w���|�Y�|��0(^)+�C���fܻ�_\"R�	qԈ���T#bI���;ca��a-� K(�,'(�>��x����(�g��Υ*Ԉ��5�T}�L��Ϩ�$�WRl>{�"$��AjNRқ˗6�b�!{5��w��$o�кV}��A���s<KHg�T*��6����!��Om%2*��d+�M԰K��Cv�L�0�/�m���b7Zp��U�V��Kg$�F!#IE����K�q+�-΂)m�p���(����TaŕSK&�ד���,��N���R�}]\��%Fz�c�@P�`���R�������H��z#b������/��Ă=1�>у]����v�A\�i�B���{0̓���N4���(�J��3�y܁�I�f[��<�v�6�v��7��r���a1�����WpVm�DS��u�_N��)_�wƛO���5޴�P��RԞ:��& ��-r�G*��p`h�=�̝�S�vΈ@ó��M��qD��P���jx���ѵkt�X�2'S>$��H�`�%��1e�&�nE�ӯ�9���v��8<G%�GD܍�i�=:��#���+l�n�W����	�{Z�4���cX���P�2�����~��?��li�KZ�7km`�
�k�k �Ѭ�\!g�C#<�Ħ���bX,�Eؑ*�FaI*��ݾHj��L�YV�Ab^,�&˔����⸷��������΀��6�x�PX*�:��Pz���T����~����XK�1 ���o�^7)��35]�!@[b��-+�M�[k�!^��� �+nq0����I�&����\��pD�{����l���^6Ty�'z�n�����=�DQ,���C���GHĘ����*���TT�2��9�y4���v8�hN���vঞ6y#i�E�;p4��V��&�}��W�ߗ��2b[���D\p�\!-��%�*�&��l�z.������YHW�ⷴS�Af�(�̡ 0�Jt���`�p6��nTؓ�`���3��!k}h�)M4���d.`n�2����Kt���m3��I���Q,?�S8�Ў������	[[�d!Y�y ѯ���j̅�#	}S9<��TO��"��Nh�����)��nvK���:�(:���Ҳ�E�J��R�!��SnF�H��KCU��@�_C¶�-�x�� ����\���f���^� W���**�Dyn�R�}ɇ駂��6q�)�
i�k8�X�lm#Xwin��c�a�v�MV`'*1��m����N���võ�gB��?�����Cʅ���qa2�K�z�a�0����|�Uj�k�ʁ@W�=�F�IR:q �>Жcg�=�����hF��k���S�x��(�öމ�g�_T"�Ҽ0��6.e:p{n���j�5�t�rݼ`������#>���c��\gڍc �|���P$i?6�$�7���G4�g�$#���i%{�������4O���q�q�B�����g򹮯y��X��x�o6�ʻ@$[���z��.��O����"}3�)���r��7�������F�
�QFZA�y�e��h��mX�@���m���p�������Ib�A�{���M5��`!�^zLV��YVyE��8$�x�Ꙋ����=UP��o!mП�C�F�gY��K�	7�7K����Q�"�U�<���.��y]��H��"yvf?-�g!�X:<��l��S���Mr��tp�I*�Y�Uܡeom����|C���?K���M5�g���E�a������l�dF�F�"�����6���a���������ӲLj'#�ʃ"++�>#�7=C���i{#�G��W<����k�C/��l,���7Z�2�~Q�EsԴ�K���֥�͢�8>���#���mN�{���Ve�/��Х�T��nԪ�VE����Z��+��vDHn�r����y�
����R�����T�|Ю�M����t��`.��>�L���8�L�'�_RR��G�b=ʈc�bX��{R�����{%B� :��* 8�&�����ۗ
+̜�k	���O2�^ڋ��^1h�vh�v"4lil�4S��)��u�`�Oq�k�ldYvZ���{>o�'��&cl���O0J�aN/�0�Y�z�)0�B���hi�.*�<�i�Ď����D.6�I��-��'��d,���[BM�B����m���I���1����].���ig[��4�����g�؜�f�w;����}�V�7��t���� ���/��W6�m���zz�o�P�Es��_.�� �Ζ�7#<�fd89N��ٜ֢�����%�e���!a+��T#�H
�XF��T�zj��<۹�Wz��E,�@
Ľ���e�����u�G08�I���_����|�p��@W�j[�	Da2�~�4�|;�^yU�"p,Ж( �-�82�/v&7�����T���BƏ'{��q��=`�VT*ζ� -��l?�&�J�Q��KxN���*3�ؿQ��؉��B����U�/>��[���}�#U�����)��P��|�{ڌ��1	1���욃sx�t�M��>}d��)�F���C#�/ u���V�c*����n��"ꪡ���9�R�TQ�������J����gcl5�&8Vuڂtx��+hb�O��=̙��or	�>Q\��I+����Չ�bJ��:�
����>�KP�7�ʖ�r/K#Kkj�t�sV'��Dw�1��A䙏���ZW������f�ђޒ�{�{Ƽ)`+�F���Yn董_��K���c�P�&��vآ�b�|6є���d���|%���kq�V0�0riu{0�L�6�W��M-R(P��hJ��Wd[ȿ��Y��W�a�rC1L�j�������� �� ڵ���:�*����jY��9(z� �
�Ϋ���	ƣ^0��� o>�`ڨU��a�)=h���+���u��l|�?�L
4܅I2�]�~��ͅ`ũL�FJU����R��:s��ЬÌ	�}�_��;����10*n��� �Fotټ��^O��R$�.�"�1�$L1���_C��Mp�î����}��dC�b���S����tS������B�J�U㔃�x�?`��p�h�Z{�*�&"Cp0ǻ���b�l�/d��\���+ƿD�o�h��O��]#Nh�{�'t��9�7��'*�R�5 ����=���&�T�@���s�%���m�1��Ga8o��7���nR
���^X�?e|<��3�9�(�#��_�f�u��V�s�ֹ=���T�u_���o���;����˸]!�H�࿩���..G�{������z����m�ٱ�Ű}�C��&�Ku(Vw����3Hs/)+��4mz*ٌ[�j&����S��X+�̔���{`���cΦ]�!��kq��z�AM]�������G�w�9��O�ov��7��{���z�U�,�ޠSMD������)񒙊g0o�y��p�;�#pr�4���RbI,��/;�um�'�����e�Q;�cR���+^�W+A�2uc�S�U��Y�xesq.���.���JM�:�x�!ۓ��c�'�
oV���e�H�A����K�|r�-;���#;SlM�����I�g/�c�C�h	)�:]V5X�F�;.w�˳!v�0B(�6���g�C�n�[||�+i�M��X� :�~�|�OP�	�a�?Y~Hgn\�u�wiT�:ۿ��w�\z��8e�a� ��{SM�5��{Vg*�?�]m�xXxZ:��;@���;<�|<�r�TEV�W$��)%Y4��#t�F��ӄ�^�H�-d ?׷]�c�X>�3���[��7t�7��'J�ҥ���ҌD�n����um��A����q�c�
Jm]���'6]�4�fL������o+�UK*@��;qy�/���6�R#	���U�e��8���\��y��H"@����D�C9�I�MK#�p}�1�(ԶLr�Ɯ5�R�6¬L�=��!\f�n-;t�vŪ�E��Ǔ�[���(��'C�{ܤ|���������Y�U�
c'�H.�1S�W�_4:��/�3�#��2h��A44ڽ�Q�y�˘
k�t^�
���X�j�ԓ�����$Nm�����!0d=]f��}����]a��� 0��k[��Kw�?0�(L��*���ğ����5 �� :�K�$�ߦ��i�iE桡�:��G4����bE���E����T�9��Q3�����<�����c�A���D��dk���N 3���!��)2���Spc��R��g3H8/�l'�ͮ_�n؈ ��TT�;��Ǿ������ǉF���YϿqPC:oq��X���t4*y!dG��v�\�ۢ%��'�7BM�����WC��ݴ��?�a%mX)�`p1$ ~뜢����'9��[�z�/�ޠ7|���Ps�0�I;
4*�E�����_UK���\�E�B$b
�	%�ì| �D�36f���QZl{B���7���E�pN�;^�ݪS��am����س Š�1�Cv6����S$�W����Pxh[��.��6�k�2�k��C��L{���W�C�xH�Ļ��z�����^�h��I'�ޒӁ�}��F5[��la�Tn*��@ .�<���)3�����zb$Gp���>ϯ��܈\�A��]*�=��]��6��t3}��\g�QTp�>	Q�����[q�c���7'�̝1_@�U��V: �{%OĖ���\��_�Ͻ�im���F��T.�����9�G��%�
n�� A5
^ 0�W�uZMCkO��K�h�P�D??:�����W�����9�,��R�%�Z�Q\*5�
����&�B��O��^F�_�^�7�]�k֣���b�LAK?P��EaOʞB{T����!���>��ߍ���1�C^���7�nu����2j�=��Һm~��ֆ%1�j>��m�p�'��^V_`7a�(��d��uHN�s���L�`@<ۣ�\������*޺����\�J�x�N�
|"�j���q��5�V¹ ������0�T���	&A�t�Bɐ�z4��&;�|Cn���@L��5������2d��$JMLZ`���"7v{~�x�%c���!1,�S�����Ȃ!�J�M��:�"D�"{�A,ܯ_�(cH��V�������c^�$��ƭ��A���h�6��4���EF]`L����Q�ɺ��$�H��Jy,��Ӎ�q�{72+���S�뻜��U��8"�v0Ý�п7~6��/4R��摆[m8L�Q8dh�)l��v��;AOsC���ح|�S�	 �c|���3i�,�*����N�㴩8�x50b��wi�2c���>c+04S���/��1\�YܪL�w�*q�<�&G&F��?(�f�_''��J��HK�x��88�٣������I`��`�W�/���^!/T�%+AkX�܅��y�2�^M�"�����_�%D_)[G
��dt�oѤ��Z���S�r0�?~�t��cY�`*��mڊ��Q�k8�����[Ց��^��=�t)^W��k�A���7�߻-_��
WS��Y���<��"��2
g�Vdޤ�J�4��'����孽9	� 7z��D�����.�а�9V�+c*�U0t=T���-JFLr�!8�A�/��1 \U�կ��e��)U��I5t�W@a� ��2Y����R�U���4д��JH�:�d@,9��<ip��8�z��0�r[+)���jöG-{
*l�ۂ��B�Q8��"�%Hx>�@�O��xZ����u�1�?���{Ĥ���T�(Krj]u��>�S�Zפ�b3���y�$�k�%�=�-xWr���\�NDdG�?��h��NM�)�_'��K,���rN�z|G(�}���
��.�=������>���e�\��E���6����|W��˩�+ǀ�����V3{?*��D�v����ZV��_���w����&��������o�g���yS�^�m,E�L���2 �G��
,�r��E/`�!c�R�5�T=�A��Ź� ���k��WA;:~F�$��#i�Zx�a�������� �'�K3���'�����x���D`���7�z�Y{g6���֣ib�`��*��`8̓#��oxs��X2:�g<��a 8?���P���$��X���_O�-�stJu���=t;/.��?�c��W��>I7Mk��|���Qv^���F���3N�$�جR�z<C[��^���ۈ�("혪��~o��g�$4��N�`��72�!�x�LV�f����?̳��A����Yj���ꩇ��:h�0b|���⃟��ܑk؂�)��;ƞ�h3�vA�q_��@q��*d���
(L�g~Iom�f�9ߡ�w�e����n���B/�:�)��sVA�e�JW���Ex8�8u>0�]c��En'1�������g�}���^�'`��BCk4��IWOF��$Es���d��e��<��]$�t/G� \�T���Op�M�z�I��T�C�<�(�)2w;����H�N�=l<�x�����S[3���d���T��+�f�J��=����*׽7끳�Q��}�����OäƏ� x��g�(U�'�-�Ld!#� \f����� �����C1��g�    YZ