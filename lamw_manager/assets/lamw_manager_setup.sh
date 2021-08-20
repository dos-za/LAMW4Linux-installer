#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3576771465"
MD5="9f47444f717d424833e605c0138664b5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23572"
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
	echo Date of packaging: Fri Aug 20 03:58:24 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�aq�����
�� �T�LZnB��Y�� ه{�'���@�F�&G�hp�#�+������l�{���N���:*��4�����5���Q�c>���T�!�o�l����ढ��肋�>?S#�C,�i��k-^ϴ�n��JA��La�{E���v�øP�N�@�4>�������d���m���(.�D�ho���+k`�;S��bI���m�En�l�� 1���9��}�;�)���Gxa�O^n�Ş�H){���9B��v�6ާ����� �E)�5D�_�ow���!����_�9���U[2�L����>�_4��NAa��c?a�]K����[ިCe��x@��hb�U9�/vBiW�|\3��r����	�x����\�6�$��J)���3C?_N�Z�CX8�������I���c�ss�:Mi
�MN��/���8I���O�,�(���Ӕ�o���K��bt��A��CfI�gP���Ԝ"i��M$&*䲦b�3�Zg�O݊K c���>�4���,��=Xx1�G�'D�f�;5�Y�N��1���ݧ8��N��*�4{w�%[�����ۑ!K��T�pP ���#&F���7�7�~�&3�`B�#r��?�a��!䧓";$��|��wͿĂD�ʱ�R�y�3?`2*�ң2�>'�R�P�uYuT㊎F�¾�y���U����/�(W7����XVZ=g`v~
{{�Y+Q����,o3�)���`u����Iv�5��3;N�٭7~��Gc�Jq�g�������+e�&i�?��~:`>Ȍ�i�~%��AEM��S(�� ��n�\�`sR��5�ةZ��%��K�6�]+2�e�i0/
OO�u��q�(�g��zy��UN��]{��Ⱦ��e��nnX�'������0����7g�ǝ8�C�߉+�ֵ�l�� ��f6%2�5�ۜ@�$���<���g��6���!�iG���KJ�T�j�Ù�1.�N����Ni���'n�U;JMR�V_b㊊����"N+x�X}-P�y�NXߝ��˃n%�(s�8�>s��2�����1{xD��-��X(�]*���HGܱɀk�XI���!I�a����#��g���p-E�2?��*^0���vA+�r?Ń�`���*��W`�>�PW�a��yNX����`�^>hw�.#�FG���p��0��TC�ŇhWB�R^��_wnš�Ug��X�=�Z���J΀����(�r�4�Ŏ0�,E����h�eu;�hɭ��n�ٹ�෶�Y�F�m��>����ң�b�H�����n]�)j�?z9����aT�aIG��WK
�҂�<��V�P�?mnw��Ʋu����C;@	BZ;�2?�ƬX���c6��f���!����E)R���2B!h��cE���4��܂7�Q�+�Y��E������	���\3�\L��j�M!�+)S�a]�J�
Ih���'����ƒ-޴���Jc�픵�sMn�݁s��w��v���n�cC�����-��Bni�H��| @.�V()�%۪��-�F"z��Es,j]��L��ڪ�p=��[P�Br��w��rW�{,ܮ�Зh�μ��of�o��g��`��@I�6^~&��ؤ�O������4����+9�jO�f�v&��rS�|�d�0˛�q�X&;�}l����As>���Qʏ�4��>��F�����oF���Y�I��տB�����F*p�/΢/X;���ȉ�e񈼝����c�7/��̉�?K��KA���aA5Xq ��[K�� ��O�l���{)1��ʑ"�����5��$��ׄav��,#������N�����?�A�{PwA��2��`ŀ�[T��ɢ������)��S��t���Uտ�;�eh��qt1���>5�pD��f��Ie��0{Yc��������G�S�)/�N0��N$rY�F����~��R���1����3�?�x�@��Yp]W�A7��Uw\��p��SZ�g54�L��=�a��9ӎy^�Q���O�k��Cf]�]���i�Ŏ|�=�p��!������Δ��t�A��
<߯�r�ø�?�����1ZD ��vfvM�P�6Z�O�Ŋ�J�Ju�2�AȬ�rI�����Y�;�ޯ��+,����}�N���+��� "_Bk$�R��K�#�����$�Ò_�G�*�@�]:��S��N'�br���͸���I)!��G�`EO�����X�L[]��[�9��*\
� �g��	��j����G����d����P��|�:��]���w�����v3,�~���wj
�&y!���̶��FUP~/�hǁ�˅���Rd�A�Le�͆���B����� 3�h�D���
dFP)��ύ}.(���O�y��OH"Xp�%�MKD݇�.'#�L��Q�q9vt?A�9��'"l�0���Ҽ�����U�ݿ�L��%��v�7�
�\�@{�8)�%�x���u7Zd@�ֺ2Q7��8w�Kv֍qv��u���!�6�ku�
}�i�7�}.a�T|[9?t�<n�ndJ����;����9��ȵ~NJ,����L]���@̾�9`�g��A8���d[80Gk��8�"��ʞ^>�A<�g�ʤ܇$*���+��M�t>��~62��cS&�����0�����xYj붲Lۏ%��-�l�ƀ�L7W����0��Z��I��Z��"��qݵoX�lG�]Ŷ�o,8��z�ƏVg�b��H����IU�a�Jx���J=n��;�)᷎*>#u�K�h`�m�j]�`Т9���'vם Jh�DW;�~�>��@!��#�#]�@��N�8&N��}0�q�;��@�AA��!�"�63����{E�ka�=�ס�Ig(4?崯C2.��(�Y[}�3r,�=XB9��@�&��7�(v�����%����Ƃ/��>�`铻��6��Hmŏ��,��FC ŉa�R��в�:m7��逋MC_�{�]_U�?�d!}�I}��L�z��BKq��d��¹2�t��-����6cTU%v.g�[�Lz=������~��<m(2�1.����3�HJ��Rhלx �X��Pƥ�׎IЄ�;(&��:�i��4R�XJ|L^�!;TG8
�i��TO�zKfF6X�e�D�IX�	��l�Z�^������ɾW���M�����Z�=�����9g�Z4N�:�I��~d׀���y���~y����G��4Ğ�v�8�gVh�W ?��؍ÝO��D 6��|9�y���96�k�^rj�r<�l��ɕ���4(ch���s� @k+�xD����#gz�f	��u�]U4g����SK\��_�b�7��?�h��s��F!<ќ)��	g&+���17���ɱ����:c\j����;�����{�y�,�
��
�g��H<��T"���g2�ZEƘ䝙����f`�XW���Sm�p� ��[�.�5�[�����S։�����M�ߍ1�J�~M(��,�}P3�\��������4e^�.N����6!J��GZȏ/Jō4ң-�RDh.���EZSΝ�5F���^V���vQ��S�mE�yK ��	�Ah��vM��(5qO�'@��|!S�f���b�ئ����C�1J4v�!4bE3��4�8��}��k�~5]��<��)؟q����p�{����h�ٺk���gɪ�j�oUo�k��Ȥǐ\qJ��^�y����N#�a+���͜�@����� �q�Wl�7Vηd7=��u ���5K>1L�u��][�K�ڋb��G��	��G�鲶���G��q�!��.C��)JV�Z�~��y)� �)I<kP���YMzpĤ��Z49�dۺ��h+�8C�Rw�3Z�����z����a%i�'���u�$��PK�<��y���a>��_�OfɞӓJOb?����!ܥ��[���(�(di�)KB�t��8�>~��1��It������f���,��r�p���ss��y���k�ݥWo5��i�4|9���iU�Ǐi@w�����Q�k�-�\᪷x�5gl�������L�j[��Y
�W��E�����H�nդB	�q�c�\MB�E����sŔ�@)[io]�م����[�g\@^���G�L)T���I>@�Pߔ�q�����b�C���0m���6�[����\(M)��5c�	��
��
��$7�A�	�����r��}��%�_N�Q��sb}?7�!��F�N�.����b�3z�T�ӂr��R�4�g�ƻ���8u�1��He�,��-�qY 9q�5�W�Z!V듫�!��x�K�F�ߥ+ rQ�����_9l�:�Өd,ԝk�����K��lV7�R��{yܺQFq��߂}���vV!� Cxᔝ3nLǥ��>�E�l�tr�|����V�(И����N��ė���S�����Κ��?��&���jL�"���Z	�1;]�g�"=H�Ȋ/�Xn�f�ac�(I���T�|1�@�xWp���⾺�@2�O���{\Y7S��}Qm�'��!=��и�sZ�NgD���7c�O���5�����/vJSZܮflg�����sh��Y�y�b=пI�;	y= ɪ�(y^�-l��5Kl�5I�e�(�lƘ~�9�0�����3�����!��Ry����������d��A�&�R�?�/���E�n�U� ߰e�i�\�8�C+�`��Q%d)bE����ς92uQ�~T��Qb5�������{��za1,��fr�^�R��-�Ok���k�7C�s!��g��������e�Bs�4�K���np��_���|��Z)AQ�q<�~Ǌ�@pΘ���K��o��Ғ�_?7F�*ji�1i7�_�p��R�ht ��ԣ�;��Rw�9��f
^I��KE���X� ׼u���El���"^"���T�Z�AJ����o��H�Ƥ5��ŝ�}[���q�����V�E�:�FPYod8�,+����$сVF`|��O�A6W>8ă�}Wf�Ц�H�FT����/h/�u�4���"M�F?�0E���̺2Z��C�:iJL�zeh��$��lxG3ן`�H�TW@����>�Ȓ9�Y0'��O��2R�����n����:�u�cq�F/^�u�*(�C�3B
�~9f�9O����
U̵���������|�i~��٩� E"Xry9��D�m��nu�ٺ�֜�&#�֑M�ds�ō[I��a5\��r�+z{�o�ȋ�D)���8����uKE��A8:ى��˹��`w����<	WPR�w�ꟼ��.�=������W)d���;���f�8M=�A<�,!�oQ�ztm��%3t�	�������PR= 8�V�k�*ݮeE���r�\�-��=�>IM�ɑ��W3^��dS�n��[s�vw0B$���S���¸r��EИ�=��)�Iˇ`�6���V��$��.����t)�oUA����D���Kr��J�*90'o��1Y��⅚7�1�C�/9��{���>=�m��9�E�~��S�gї�+_u�C��+ e</���*Zf���2���J��q��E�
o��ū��-ݕ�����.�#�c���_
�oT�h�,�٠n#ԝ�:x#��.���]�#U�;�ށ��A/ց�N���r+��_�Ym��,�ޔY�\%	F�U��>�4%��hĎv{�گ�Fn��+��W�pG�:���HqGc͐��H>�f5Z͢A�θ���7�a1�\6U��'�q�fX�Go����*3ʇ�tg(��&䙏��aZ�)Az?�'0�\Lr�l8����9Gn��\�.z��=�z�X)�{�;��K�I�N'!-o��Յ����F�㶡^���)��̪��,yFҧX�ē��$�v&��
���$�(�M���S�pQ
���ލɥ!�q�6�٪�5�����}�E
<x)C�o"N�����M[���hG��Za��
yap�Ā}�q'�ÙXj���aܠ"I�`Tה)�f\����n,�Oe�Ab�c�Y��:�j6������W�H|��H���0�G�Z�Y�������l���p"��)32�3/Q'y^r1���1,[�
�X�mcF��h!�^��ô.:�~H!b�.,�Zs��<�xd���'���iHǸBDTu�����4w���"�>�3��Y��MSQ2����h��"ʏ��<��m,�>.�c�z�.u\�縤N��@�w���/pDE�*�@�dp�޶���	����V�q38�ah�B�����FB�@��8��S��Π[G��3&Ff0k��l��lH�o������-�����N�P\"���u���3�����}�o��=��%D�'ʒ0,��T�G	�><lc�uY((�`�у�C�O%��k{KX�<�)��k��dmU�F�Ο��#s.š�&�P�w	2���bO�<��`�@�PC�"��c��
X�����#�h�'��%��z�� pc�7�y������x	Z
�X�&���߱�?�IT�R����2�{���8�F�'�M.�7]#��
��(��O�I�R�bΕ�Fo��+����s�%ep|�\�~a��C�QXΜ/�߂�7�&�ů�Q4�ވ�i�f���a�T�߰e"�b.�8Q9�� ���Tdn�|�|����ȫF��Ϻ�gQeg�Jh�����,��p�����~�Љ>��D�1p�g���j�<S��*��9��+�P`���#�����b���'\�v��q�ט���iv�c�����ʄ3߈��<;��']wO��d�����u(��p��P�N i�o�)�Ҵ��b^�)40ˤK�HˀF\����z*M�I-ɔ��67�Ts�v���=�5�m��!i�����p<�ɴ��Q�i%A>������I��y�L$G���1�D����F�ri�G[Z
��۠��Ǎu�wLB��LQ� �O������E����O�O�kYW��i$��.������\@'*��'�PN����X3��D�~f��'5ma)�+���B�s�����*���]���{�,Y c�3�������ʮ�d��ۘ0i�zHLp�?��pk�z~����%�f�+)��b
O m�9���Z���-�X1���W+�X<�����K�R��z4�p�p%A��V��6.��>���x�X�s�qTߎ�ӷ��^L-s)	�r[LQX̅^*��� $令���?0���C��2���i�_a�Jt�O�ϟ2�l���Ο��٘T�4�`.~U�$1����4mY��*q��@�e�!nj �e�eհ���"1�PD{9C�X�����6�M6���ԉ�U��5����]$?G2.�?��ѓ�.��l�J��24+Ú¤{��{���-2t�	��0N��wJ~A�̌�l��/s�E+�Aހzƭ%"�Ѕ�X��P���q�9��^̨��'&R���Ϗ�36�0��:��~�ږH���ًf����y�,��~5��q9��+\���P�Uwp��$�q�tN���S���,�,p�k�[%.�)u���y�`X�(�P��=�*\����>ke��m�+D�+���I�t�v���g����oC��0�B��}�;1�����%1��e�]5�������x|l��{%3��8J��M�:(9�I�[��n��vmq���H�St'��7q�ĩ�e��9M�k�^�[�c(�g�n�@�M�}�pu_c2��T���aC\���, @)��d.K�F�O[�t7�X��R�z70ݔ���K�I0�,��By�����/g=[�(���x!�KL���hk����/���O�?;�J	xbd<$��.�K�<�����e�Yi=n��L�h$�S@ / �Q���OGM<�n1�l����z�`�	���>(�����t�B�TסH8�YH�-P����gLLo�­�мy&�)��~Q��4} |vz���`�c�yԩ�BA��4��>��B�.n�	�z~�I���r̒l:SQ���뫊������H�;g�j$��S�����~>ܡ^s��N�`=��T���հQ������B馆9-���\���!�j�P'�D�2P��}�z��c���Y�t�&�	�:��]�C<N�u5�պ�ٞqi!ߠY����U�I9*Ŷ��.R>N��А�0�ԥg�Y�}�6��:���*K���v�v�р}��}��Y+T��{�>���z���U�<���ls!�D2��b�������
����~%���b#�ą�uX'� �w�V��T��~g�=z2e�u�e�w�Z�� Xև�ѵȏ	���#YZ�+OՅ�5׹۫'�:Xmr� �H�n��V����e�����p2r�5"�����"hb0(r����\�-�v��
`q���D�sX�+�噷�ۧcU~n'n:]�u�Qm��9�/�)y��&��)�q�cQ�ϡ%X]�H��hu���4�~e`�מ]A�#�Z(�F�.%ڗ�oAt�6B��M(X�v�ܒ��
���̵����Q���S�+Q�ӳ�c{��?��l�`Ш��:8����ۨ�%�m�I�_�+�5���x4}�vC��n�>����2�۲I�m�u�I�D��R�>QMLYI���O8����`�0�=f��WpJǬKy<��h;�q����D�t�*�b�!u�0=i���5Ȱ����'��XJ��m6�{�R��[>ԭ���wyj���rOp�q]�@z�Q ǧrn@�.h<64��>A��
dK�SC����L�G�� ��e�d!���u���>��*�������ܤ�$
��r�/.a���wě���;�]�>������vw��k��9�r��Q��}�.eƉ�M�#�*�m��2K~ʘ:�,������y i$�T�����V=(��Օ�W_� rƪ^��jY��-�ջ�O��AJoo@�$���1��8 ��=*$Gw6�T!����zO)���������^&����8ZYե��L�Y,�ސ�T���]X:��$�D���(� �0�e�����yx9��by�_*1�YB����`���k�����9�3��{̀4 �
 ���%�	����by�1mR��J@���a����ݠmm�o�Y�[C)�~�Px)����0`TC�u��P$E5�W!"ҘYG8�� ! �-��{mH�ɨ8��e���!�F�5��<��B�����v��Qߏ���uq&���4E��ty��-�=��recpnjo�ɥԩ�+��mՅAj���0�������F����Z]D�`o���o��9���S�O:��Okxm�������e1i!�_t�7���P��ʖ�V�T��� �0�]���i��]p
�ǽ���-#{���9�p�	�_���a�C	h	sXs�����mD��5G�op&0�{��|�U�㩊�!��'�(�����D��r�e�Κc0�w������h�FxDB����iD�J�_��6�Jr�o�_]�l߃
-0��^��K(����~OR�f�T#r���}�����uB����¸��<�L�	�=�.axcs���Ef�`��a^�;A�u��l&�dMG_�W���$\Yv��i�j������%w����x���'x5��KY�|po���f����˓�/b��t����v��{��ω�P��D���	�K�K����#��*v5��C���9+�Lf���%�Gy��+��&΃5>��|�?��.=5��-8�Z؁YD��1iE��^J�M5q
#}��K�$�&[��,���1��4���l���x�y�jDqĚ'�R�b���|O�6L�;�w���:�G�����4"U���xs���Ey�*��- in��T$pAF����/g���y�H(���Ny ��Ki�R��@'5�QKt�]֬��������hl\�4��UE?�W�_�K�?�G�7�3�D�����"6��h��  D\��x��Ӕ��{��s����Ǧ�Hmd�z&>:���I&g�f/��Y��� Pϗ�"�x~�!RLk�U1��	�тC�I������.��u}�G���af�h��ÿ�ǈ�J�;��ƻ��@�A�Ӿ�݁UɆ�K%��e������R�)E���)ʊ�h!x�����>���9O��O"zȑM~��I�!�
ʺ��rR�v}$��y��yCeao�xC��@�߼P�&m6dC��au����S����z���������N�d��v����n��t���4���L[����APc?�D�UD��i�.ji眗~�Pr�d��~q�Yvؠ�;J5��'�hT����R�؟��K�Y.�����f�4���8e#b���f�Z刨�S�Q�gڂ����͚Y���G}���E%�^�ZTp�k�}����̦7�o|6v7=LB��X�\�z�B=����8�t��5�JSPo}�?}���@��P�d�eރd�
�k�r87%����w���-�a�ԢU��X����b�)�
)q DOu��kw��Ǉ,r	�BQD,�� �hR��X������>nM��0ڛ��?��j�����k�-v�Y?]�S`J�1A����χT�#�m��?���h��P�V��R��U�. �J��,�����I��7m��O�5�k�����Zx~~;��kԢ\Q7fdI���ކ�.�����7X^,�V����z�N.�.��2��OT��IC�)�_bhŐ�⽂� \��tm�'b�C��A��q�t��s9*�Hڡ��x���b�w7g��n��������.��
�X�h9M�e�^%��E�*���蝥-I�Kt� ���[�i��L�4��i������~�Ae��=�����g�ӑ����t�;`9p�H� d��M��h��L\I�H�!�0���)��xǯL	<1ֱX�5M�KV����k����jt��5��n�Q�琋<��.��wb��׸cU�z����a/�P��9�^������i�W98Z��?�c
�����m���p��j�=���#(�S��O'�:���w�ꄫ��M�lqaLϼB�|��۸RrYB	�A��kK38�p<����M��E^�P�4��.楘Y�[1�=گ\T��h�8�bgH�b�9������n�T�L?0�hɭN�@a�p#Pf�5*�U�վ��������(YL���c�pvЇ��(6C<�����OH��oʴ��F�\�HQ
k���bc�b8$��c��є��Lx(���C���UO��N�^��G�~�)U��G Ql�æ�[	�PW����X8����A��I��s�9�Ln���2��Q��/��,}╖:���3s��b���X)�v�y���uX�|v;>&�C|Ѻl�G&�&�%��"�:��.<�T����p��jr!���檬�9��\I�'q&�]��X�Dpqy�Y��-/g��P��l���A�f;)�8�L8���~��m�(5����+��p`+5�jˤ8�(P<C[�>�dmw3��JjZ��g_3��������I��IIT�g�"RQ+U����(r3��3�;���b;��U����br��>�Y� Q��,lI���'|��6S;�=�緑�tT.&���]�y�k>�n!%�h��6���uq~cG�eߐh^�5!�{�ͫ���p������	�OЗH��"� ҳ�nd]t�E+�
Ҷ�<I�P5�;�0��Ǖ/:QɿG���,�q�K��͊G	቙��$z�4�P�@�T����'trG,�%/��)�w��TA��A/���G�g�X[�Y>v�g;������f�����܏Qꦄ�����e����o�'�?�D�!��R�a�گs]8J̴��S��2r�^k��a���ݙ~��i\�^U.�v��!=wܱ-楨¸ �,	<I�s`��pl/H�,b�ݛ?:O��Qso��dy��u�f�3��GU�P���g]�r�1��C�b��o�R��;lG"�#NY��&�2W4t�d⫷4�Vee�7���nu�d�YlU��ׯ�D	]��r�鋯�٠)��p�X��`SL_�?Q0�x���T�l9v�����(��t��9FU,\�~�8SOh	��jMNXg�/�W���2۰�m[�ʓ�\�'N�-�ᙺ	J&{�<h��N�v)YR˶���@P���}��f��ր�i�0�3V���"�Z�����]X�>��N�6��1�dm��Walx��-FH�V؎ր�5���XԶQ?�~�렲�Q7BXP��e�m��g�T��̚��5�~It�=4Sp�#{%V;(���2���O8Gs͟�,� ���1��10m!'(Jq��7x��a>m6I���)Ωz����iBͤ���&^v�O�HA�>�&�}uP�?Ɂ*�=�w�*Q�3��Z��t��2��[��N\�I��.fY�z��D��S����jM����>���r����)ձ�H/����l2e�J��V�m}��ßm~[d��
y�iמ}'�8��U!������a����X�E���%��)�+A>c�k���Z�����,�>��Y�{s��K�r���p������ܦ�ģ���<�MQo���L|Q9x�_�@��n=a�3[��)���l$Dj^�\�# ����Y��v~� ���h��w�Ӯg����@C4줛�k���-���awD��1g�ų,�̴�!�7���K"06���G����n���-��̫2*OTVv���9M�.,$�YD/e	.����@�'=��: (�Cx���r�����TPS͸rom_���4L)�͜�X�y��2�A)��o��*ٮH���</����
��b��H-!����k)F=f̥~�S���q
	�h���8ad���*}��{'����+(O�P(���XF"�j@D����N�P��L�Iy�*�-�>�&�a ���������i�V�0l`��C�R,ČŅFÈ�+Qc/��e�s��#.~j��
�v��.�+t����[�bd�gO�D�zh{�Y��Լ�?�d4�f��� ���� w�U�IwE:7�Z�x��ڠGvo�@�Ge��O!�OE�"�-�`�zg�g^�~Jh�Ml�W%cI])���?�`��d8:�/-�E\���{_�I�K6���Df͉rqsv��K�V�: G�� �Y�u�6]�	������$��i>ɫ����R���J��5:&���v#�$_��)��bhk��v�v�鳊N����OMh�<�]�*���-Q���*���&���T�gp��&��#땇���N��D�o��R4�R+�a��!��tZvhp���v@�&r�`K?�h��c�4`g����Gm�:��7�y���r��&�$���Fjr�U��؄5���QM�5�`���F>d3�6ƶC�D���5�KϴL���ԯ��y@H�'����I:R�š��7g�oݪ� :2���		�G�Ҳ�7�V�⠡�����l�
 `�*{� �����c�W�nq/[�rv��n�-`J�5K��G�g�*��"q�N��n��<Ph?����������O�M�`�3�;���Y =�d��x6�!k)~�ԥ�ַ���a�������|���hB'4|�p�L�S3(kOG!�P'�j�:!�s�e��rx�ˍ.,AF4�G}�
��:�4{i?v��Ap�[��ק�P�^2(ҺK�Mi��d��W�9��a�i[�s���`��E����C�cmڨ"	�P��a�-� �(f.f^S�c$=yD�]̽G8qs��\%y.���ȸ�ё͋=bNeB�@��A��ΐj=�:8�Q��,��1��,�u5s�]���D�qM?3(�܀/���.(����^4�2a�S�'�0(��.� 0Z�C�^�e��Ԋ�{��+ �h�R9���]�(���l:~6 �^a��һs�$��M�-��ا���\9�����
&,>�axs<�SJ5�j���u��D�!:���>�3����$n;e�i�l��;U�z��LΞ̐�&( }&2jZ2��eAs��ZO9�"1��P.�έ<
�r�.�i��&��7a'2Iz�	oD��ή�ʌ:`�P#�EGg��\P]��S�:��h�c�c���V\��KDw�F��s-t�Z�=���S�r\į�����sY�j[`�I���d�;qɚ^�3f�Z }g�����F�Sz�*������wG��Ʃ$���M�a,%�d�� �:*��MWN:C��#-!�4R��!�/�s���e�S*�U���r�w{U������{��Y�bn)i&9�p�/$�*8��8\��j��� �"1f�������)V��F��h�j�`-��q)6�kׯ�uNVT�����3pgϿm��#sf/,�U����׮�7F?4���4b�����e#��u�%�F�*�`%��P������?�Wʵi8|<3��wxS <���� �1�)��6e���)`O��-�m^���묦��8qn�b3>���ef$!1ȃ$���zz��.@��z�rP��/�A�,Ab{���i�m���&�U([н��"ֶ�d�fؒG�~���YL"����
m��"���!�L���Y�N��i�#��\$5���D���J������m�R�s7O��B�%�~�bD��Ƴ(_�9�7ׅ��.�t������}��H��q�*>A�ۖ�8��"h-�^A��6F�s�=�l��� �E.��{UZ?1b?w��A�r�\�l�"(1� ]?݆��=�]4i>��ɔ�F��
"MHdV�h�mG�ձ��V����B�Ns"֡Ʒ�G�0�g����P�-�b$ť,��G�$�i�C��M��W��)��n]�*'N� o��*��W�E���،��:�6��Z�*(��ߟ��n_�:M��V�'B������܁��P�/�N0��t�ٕ��B���g��;mܳ��l�%�=|���#븟95Ρc��:pZ�������Y��՞a���z!$�^�g��n�`ʸ7����
��H��J�g��I�A�8�M��l��˹��TW��$fܥPYEHRt���,��o̘�[a$���נ����]!�u��������v
��v����O�^�G��M�Y�t��2��R����|��b�t*��q�����޷刵U�F4�Ч2��$~�f<�,�!Ն���k�6�Ê��LvC�>���7�,Xl�ᣒ����_nA�Gt�>B���}�u�?F
�׹[bTS#3��m���2�C��*�U�>�[|XOz'&A)迏k�l����|?���|	��`��@����؇�+��--2Y�BC�>q	e_n��F\E�ʙ&R9.������?nmĐ�c*�/����������L�<�7�hs>X�l�|b���p {;�L��u�9*`w����ÂA��n��}�s��)��&�v�����A���6k~<Ĵ�+�>S_#�f���.j�l����a�G�:�aa�H֋�w㝑�<ep(�[�R��	m2�����Og�{*oC�x	��i�D�#EF�~lOE�O~�*]|���8IQ���7�@��(3���Μ�F�����$�	��*@��H�����k($6Q�+(�m�	s�AM�؉��th<[՞K)CdRu_���Z�%%c�x�H�!	Uܿ��d��4�#���ES�'���OL�3�#\͘T����9g���f��y�[٣���k>gЌ�!S\3#93�V���^+�֭�ٯ�����>b����c~��(�A���i��q���r�QMƎ���d=Sk@�!��m	�4�7M����`�W]��.o�V�zm�,�A���Q�cVL�M:�C�r����^����u+�7�6l``����D>T<I�z��R=�3�,(��w��Ŀ9�9w8���*�Ξ�H�ދf���H�:�'W�l�5̒���^^b��oI�̳۱�%������p)��n�Q�Ө��J����f|���=ܚ�o�G��~`" ���q���*��N%Θ.y!ٵr�����<����\,�a�̢������BNʋ�n ~�w�m!�ȇ��	3̳��u���}�r����$�E3�L���줁��ʡn���0�\g�-oa��m�p^����@�.9iH�[m��&��3�bぼ�`�݌��i�'�UaH�VS>[Ա= �.���<�=��m9���Q]t���8���)�L�&6�d(d$Q6Ix��EBZ�9��Z�L���8n&As�M9o�f�I�(я,�R��G��j��,U�0�B������=��X���o,���7w����Y�GW���( �|8�V�b����1K�9�^0WvC���f7�RO-/�9��E�f^�� ��l�M��-߻�ٔ9�����`�N���N��'����5��؇�0M��z�.ݎ���4�=w�����RÎ�ٝ�$f�w[3@� �x~~}6�~F)��;Ɓ����,���~��C t�eI���:�u��x��G��d��ԺxE��}{�_z�C�x^.�hw�%w�q�������d�����xb��s���dwP�x+8:�a��[j�n��@���n-L�D��o

��f�-�B4�R����f�A1�^�<�3)�L��)x�/"��=LV^oK��-���n"�d�(�ҵ����m�T|@�$7Z��:��ocC�=� ?��=�.���)�RV�����a�B�����n�Ǉ���EO�l��S����kFx�x`�}!��^�2�xGչ���~���×�Nu��pۮLP��g�=FSb5y���q�Zrk=�z��޲�qI���޾ۓ�u��J���c�m#yЗJ�MQ���SL%�[��B�$c�/�-w���O��n�,[���_����� �g�D%��T%���٫<�_���M@"+���[k��r�p2�-�/��+�M��n3�a��6�h�l92��O\\�����]����IV�μQ� �hc���'�>e~A]D�ۛ���Xy#	�APL�a�E$չ�L�"�]��E�ZT�"�-���U�|X7�х��Mpݡ���)�2�C �zAӕbN� ��UU��yg���+1����#��H�ޝ�r���R��1;L'@�e����ZG��VnK�L܉�389\��I����V��ۓ�VN����Y	��vs�����eAE���K±�+�w�}F�n�:�� �E�#��g�#�����?#DzO�X�
˞���Y_�o�J`q��$B��QxB8�~�AD<��T�.������<x2�A���p5�@1tG,hM �Pl��֘1���<��d�����nUI�w��X���=<�5��B�#�K��NM��K���+D0LS���0��k�v1z�M�f��P�/:�����w�"_�q����``����*缔uJ��E��^�xfC��kԸ�4ld>w.Ҥ��5�s���	�s��dB0��]0�/��يR�9*ii5q!����|�]'i3: �g�H��=SD� o���z[����}���&��k��l�����}�,�%kr��]aVnѫC�k�k�Ād����<캶Уr΀���^�]PXR��FllۣH*�t߆�N�
����%���t�E���%tHH��Dd+f���-�;��\��wiK�dIj4з�ݿQ��g��6����]�B�y!�Q�sM1�h.�4DM��+�b�cu�{oS[��J�9{�9�a�NW=�P�>�ʤ��E�Li����K	%�+q�Vh:7}���K�z�
�.*�(��?,��G����m��^T��ˏwZ���Fs���y*�I�[ϲ񤫗�[����r�B��9;r�k%Fg��ݳ,�T��Rl��2NW/�s��Wa�U��͸Yc'$"��;����	a�ַO�em�|���ӛ���'X����k��w���D���9�v�O]�I�#�Aя/,��R��b�q�����صJ2�ml ̚K Ǐ��5�B��.��ǉ�a,�S��Г���7'_l�T�����B��U^�@N�X��I��>L��v�K}SO͸;�<#�$��z�ִ�t��!I߮2�@��w��Xͨ	���ᣪ�)a�;���,�@h`��B�B�<�"����E�R���L] ��Xj�#ا����۾�=k4����^�*�m��S|,�Iidy,t�E�T��ZٍjŊ��5�d�����
͏~l^��)�S�m�����_e	|�GӼy1o����O�Nl�#�`��!�x6�g'�_n� �����#Ҟ���}Ȏ4��e%�Oߣ۫*������֦n����cC�d�Ի��*;���l������H��`S��Z�Tz��ʮ��Ts�7uΜW�N�1�}���pE�و�o�{�:X,9B��Z���\I�.��[�6�DgG5{h>�6s��`�В�+�� >b�73=�EQW���Q̬)���f����:�m�El�H��a�œI���x��Yr���OX����c3z�����l�y�=��.	�,�m�y,Zδ��q�4u�
�A!�UٿP�&��'�sur�{�0��mj��Ҏ!�{A��� ��q���4��g b�wA�o��Ia��O����P�$T�̳ ,e��YV�Ş�I�B�8�����Kl��Gh��A�~���� }mu!�I�z΅�;�Np�������GV�d�q�x��l�s6��8�|ɛ(K�G4�q�?�p�T�q��bF�a�� *P�!a�GBͪE��+:�\�T���|�"��p�v7v��m���'FQ1��=|�J1S߹��D@��'{7�QRU3��m�����J�H�(;��k�T�0���������I)|wL�4D~R��L����-=�YEcEue:�;�/�u�)?C�^�:B���-������D!�q��o����_���	� ��-�a��x�wߵ��N�+mn�qZ0"��j(������TU�@p�1/�F��q��y�OV�F�h��{	[��\��OYz{�:���E}�4j�*ر1-ʈ��f���,�{Ň�3���GG�����_Gol����Y�%��f�n��[mW,�1 c�M3�5z(�~}|���yī��9�]2tf�q��scJ��p��5-Ll��5����b�}z�\�+���7����!$��EЃ�>�(-��_3b�>�!��i�R��=&�v&lI���⏉nK(j�8*��7t$��������FfYHI�rO�B�h��T��)�Ҧ&W�%!��nz�I��8��Zd����1�&/�L�`8�����8�g������w蟼�,3~V�=���	�V����h3>Mm��~�e�lMIf��p��G	qC�M�I侀˼�
���H���O*�Ca�7����L�(�G I\<\�����jzt{m�:myC��#��z���Q�|��:%@�'���7'��˾k$�Y	��YO����&��7��d�9�@�-��C�b[�Bo�Iߪ�k�z�܄������cL�E�6��1y�=f��(ލK�\��*�f��+�#�G��~�����ӯ�2�X��0N����V��(ޥ�������P:)�D�Ӽ�f�A;�Z�>�'�2�^h�����5ˀ������.KI�7:F#�p���ZD��C1*�Bn��e�4��z(���~YH~���W��ܤ�&6(�bҩ� �mh�7�"�H�Ѧ�r����hnGv YO-H��!BՓ��x�������[��v�ۻ���o����W�������h}	tVto�ЯT7�6\�'�Ya|4�U)�X��yQ����h�+�)�d����ǂ�㫋q|�}��a�H�.�i�d@xq�۠&��X�H�˅��=C��jO�y��0������E�[)��{���g���D�r6S���0!V�q]+'�vWz���^v����Ot��>h�lb
��%�7�'O�L����j�a$�U�1�����a8$dP�}��[?��X�v�gU�sA�(�%�ϭ�� ��+t��PV|Ky?q9�($��o_A�8��;e�:�"��Q�m4�����,v%����]�a+�R���1O��7c0"(�"��ݻd;�C��دw�zE�8�-b�(��1˩�2�u���З��5��G�7�5?�bW��� F;\mh�3�k��g?�o�d�~���e��֝��I��OoK�Ah��d7u��CW�f�9vE~��-W.UՌ`x���-��E9f��P�:�(Yn�{/�b�iG����Z`���ȭ���RVȱl ��v^��)����p�K-MN.��{x�q�z���1�.G�����	�`m|����u�w6g�6nĒÈ��?��<t讘;��V�:�J�5ږ+@�'|��w}�u<���U�%GTj~/�g��!�ր��9, zVV]Q!��g�G���U��iW�އ2��Gq�n_�%�z#A8�?/B'/\��7M�����+�$�3������ֆ˫��a7ן���̚���n��/�p}U��a�&*�Y��L�n2�H�PvF;���5�$엂�N�~��?[��,��V~�[E�j��|���/ƿ},.`w+ԏ:12.̥��O:�?p_����7%cD��	{���P���=��4��Ŭ�X�]j���Ix폙�Ӕa��-s`|���.V��*٠7���"���\1��V>n����J�^r،�r��:��N�Ai�ž�S3����J�Y9E�-<9R�r]!>7^��b8��D�Y�B��/蛛�T��)޿1�y�Ĵ*q}[6(����ۺ��9r����	��!����=`AnM�I�Xm1f�͖�ڶ���P���Y����sj-[��� !X���t���DH	|sN0����)$�]����8Z�]�,��vHWir@?�τ����<��UQA�?�x�F�qw�+��|����I����21vm7�%����
�[4������z��`�Ѯ��t�P�=����X�Tx�p��Z ��pJY���n���O MJ,Ͱ~T��X�jx�`�wc�<ub�=�BG�ڙP^U+H�? #��>Z���(=�c	���I\��Եv�)&���qr�^&wJ���NZ���|��G��]�jj����^�{ ���B{�g�@�M������ε!��ADq[5]�����M��<D8����x�c��3�>�D��i����]�i��w�^��C��?6�Q�O������V�^��lv�?����o���������}/�H�?����kd2Kʁ3���R�����PS1 �1�7$%�I��Zu�,��Xs�\IY�3-V���>�
 Wj����$�>P�R��FQ��v��I�����l�|� �K��s$�\������T�9#����[�%M/E��R��A��N�H8�.r�y=��W~!Qy���^�a3�����p�z9�5󕛎L�oεVqQ?C�M*��-0=S���
{�y��a�K�$�I�Ѵwz��l��U��-��K[��5J��O���J�O��D�!*� /��`Y�V��;2��n8ˮ��A�����m�e�Ӧ�l�*��W�f�\�1�Ж�_'�_Q~�~�^l'����d4��-b+��.�/-��J7&�"�F��-DǶ{�JV�]�(��D?L��R��K�؍*@j��`�Xcs�oH?J`�wӦ'�V3*���^0�1�md��AU
�&�$}=RT���OT/�Y8���U�Z�D���mt_�J�W|�N��'�h�T�}��˿��nL���2S8�#RFԾC��1�[6(��%͌QU��W�9�����bt���XݵЩ�,P<D�>���8h����؏��#8ٻ���S��r�P
By��\��e��@>��2��tQ��e��%��{=�@�U�kO�v���E�ڶr|(�[7�F�ǐz\�jhc�70��蔧�*-d�D���rm��`��	�X!1V���UX��75��iR�\y?O�+�\?����UJx�k^��q_J@v���o\��?�Ѧ�*�*o�~X`v�ߐ�^�&A� ��ɺxs����s�xC��EAĺzSt��cЄn�|g�����+1Z"6E-�s-]�tD�Ĭ�${�(o[��ȓ y��=,�2�Y������\�� }�g��F�?��Q� s4��G���X"j�R�ƕZP��$�h哥
"� ��'�v7�f���S�o^��q?��qx5b�#������X}D4_���.�@Q�IIYBO8�tZܷ�A����T�4q	�N��iZ�v���n�����w�m�\�m#�ʍس��o��%�N!��s�xcK�������t�0DK>�����-(�$L������4lGW���ʖ��K\y>`��Ab`�<_�����9'���_��ى��,8f��n�&��"	�l�J���8�X���Ao
&=	o:pW���?�i�}��{4iRH	CqY�y.4�٤����W�«U�l�}Jv��[	[�ۚ�Z�A�8t��RCj�ߝ8,��7���cf�>������:1��k҇<�,�G�u�O��`MY��������]���Nh%/�/�Ā�e4�m�4�Q����i{��%��`��/�*�f����y�.ur�712 �'%Մ��=M�oI �7�ڋI�v[���Ӭ9V��NJӇ�q!񜺨�)D�T��ܧoAJ������/�Ɂ(�ת%�xOI�sǲ�2r��K]���|���A1�)��A���2-�5��Fב2����0����d1����W#lB�����$R�/NeP�~?,Е(بh&b�k<������A?�\t�ur�TS���/u��m<2K�2�m#��m�k�S�I���M��@��i�&�/p͜����
$���&�`?�<������	$n;��e�H$�'${8����UT�Q������aJ�!�l��vy��roa�`�T�j����;Ш�8���`�C��ʋd�������E�[�h�����IU��o��3����.���JX��e���������*�_��\y]�(����k�)F���& +���K��^d>�]���  S���<
Wz ���������g�    YZ