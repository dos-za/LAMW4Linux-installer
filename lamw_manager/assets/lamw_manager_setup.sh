#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1605594340"
MD5="3edd4834985272fa90a57453410d7379"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23108"
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
	echo Date of packaging: Sat Jul 31 16:47:23 -03 2021
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
�7zXZ  �ִF !   �X����Z] �}��1Dd]����P�t�D�`�'��
-�;
�v�j!�BRJlBv�˃�J �gE���	ʒ4�j��p��{9��$R������I��}�e�ď`*��(�!�\8�SL]B��T��X���Y�ƶ
=��|�kJ��Ýڃ���R�'E'�8b�_���ݎ̣+��HD�'��Y���w,�-c��yi��o��H�9�a�����z�d��|���$g�Yo礀xTܺpd�+h�-�ԉ�*�,bM$���@�&\��T������Lj�wN�ҫ�]�Y��Ķ�]��;��e�^=$y�~.�F�t�#�`2\,3NCRAЪ/9�كɪ7��{�1,5"�W���թ��dŚqdP(�T��8���2�h���IOi	�9/��\�E�̴ʖ[��'J���Ս�>F��g�Ej.Z��ò����slАOQ5�����䕼��Ϩ�A�H�8���ݵ"ý#�~��"��)�&�_����7ƌAX�H��{b���n_��0��g�k��B�yH��Cb��������>.��!��u����t;7�5f6ss_��+�KQ�>��[�ݫ@�s���h��@ɩM�s[����9�?�J<��33U�K����$JUD��W��$��Y2t���e��<g`ל����b:� �Ę�yc+H;�{;�@�ٌ�ު���)���S�g��F.�	���o����4Ţ�Ah�Z
gS3 W��O؎��=kJ�nJ�3q ��!��^�b��b����5p m��u�;��F��K�ޢG�
�������Ĳ����'�$S�����K��&�J��������7 ���e1S�B����V���@�[����}�L��U���7>V�:[�pq�0��N6�/
�) ��.���궉���V��@�>*<���[tV�x��R���6���vP�9S7a���AD�;�5Q�6_91���G�h�x�a�`���_�ixR+�쟾�<��s��sO'no( ��47�k�B��wSFf?J69�n�	tT������1����W#Rjl�M%8x�,de��y��w�B�����عa�j�!���#�w�2H4���f�{�LѬl�x>&���wJ}Ko�KT�[ag/3����z��X]�~НC��6�,:���Ju���3z����"+}�{qW�l�1(��َgl.��q4�}�X?��<	��	�.��Bf�m�Àq��8a��6�_�K��-�.S@�"nը�w�1����� �c�����X���큟&jW�y����<jGZ��!cX�������Q�и��o��)٭�͗��g��Z�@w1-`��)0<ǒu� k=Q1�-D��11��X���r���jX�Y�5æ�%uS�Օf�{Ɯ���I�.)o6���
�VoQ$�t�H����Dp�L#ϵ��Dnjw)�jH�uNᡚ>ə��Qu;Oj��z���Ƿؾ#�F����ߚY��+H�t�~����."��]I^�r��j)�yRڨ86ꖶ�YI?q��@}9�HV�F
R�i��[3�ي_�Q�|��b�r���}�f?)s���v�{�g�p�ŵ�`�A>tM
З�#�2ߛ��g���O�Ϳ�mp��p�-V�ʮ/^�$a�v@Ō9)t瓞�!撔zj,�2����W�q���{[ Z\�9��%F�j�������� C�#P��D�� ��n{`�]���>'�ō%��J+���7hǺ�Wj�$���/o?�p�^�A�舨pu�ǌm�;��g��sGxm k���Vԭ�ѺM��ȱ�*ܵ��.#ҿ� �~o�2�<Kj̳�,����ZsZ0_8�)���u���㘢@|i��k�C�S4B�.K�b@q��D�(2��P�ep�D@�%�N88�`�����ת~�������Q���6,����_���(6஌�/#2}�����Ԥ.�(/�CY&(��P������R���
����K��٥׼n���ɻe��1%s֞��`[��7��oT��H���n)խX5*R�hv�8��:ʿ}��~���}�
�;�H�%�2f���"5�\H[��;�yx3M���0HY��6��5b
�7��G����Tl����4~�p|*pS���f�YU"�
^��#�x"�Wf·�{,hQ�&��־)aa%Ѹ3��r %�
&�p�<��;��m-�˲y��;�xA��Dވ1��+F�*�^ڿ�Y2�Q�����#�]/��L|)��[����8
y��V�I̩J~�9��ۑ��}��'��A��B��n"XJ�R�y��4�:����̙�L�*ݛ�Y)(K����y�s��u^���KB�� RPI�IRãc�P��)�F���AǃTx�z �D����'�0	L����xA�����h�βA��`@�
���@oNd~�Xcy�Z]���oᬍ/q�����Ll%���T�鷑z���"����c�of�%u���f3�]���;��&eer�/N]=7լP!/d�X�J��5<O��&��2y%��!��l���r'.i���O�5���VJ��b��EQ�'���:YB =@���TR��=]����O����X ��z�!	yع�8v�����K���b+	:����c�@�<Dl���ug?�3F b�}��C�'[�$6��^D�V��JY�Y@�U#���I!�Z�����%y�5]���d�Y��G�$��zד�~c~E��k8��<��,6���E��`���z8B�c�O�^6��;R�e���eC'X��X؟�y��X��܇Vs�d}D!Z��Qd߹�9z�\�~3G��7�Y�L\8q�C7���Á��t�hs�Cz����
L$Q���I���y�A��k���Qų��VV����qć8�v�k�+X�WSW��\�������Wf�����&�9Ч�d�Gd���iC�YQ��}��At%�<r�홽=�������KC'f�߶�i��9֕^&��/1XT�#��9V�Y�$��
�ޔɿ�Y�
�ǀ�;�j	�N���Hp���6���a�;E	�N)�sm"�~r����Sr��ݱA�u�`�aI�I �ST�L)��ly(�.
�O:����"�.��+ѐ6ё�G��h.J��`n?��y��+��B'9j�Ia���G~ꮯ@DS�l}����O^4������w������E�.��i�J��R~�⍘� ��y��9���V�Y��DOcx��w��d%��`��񧟡��qr���+��fs��`f�V�e��d�B�@e�Y �����YlVʧű�|� �k�s�6�M�g���!ѷ"	�O�|`���m~�����G��y��r�Tv�~��=P	��u��8&
.�u��:'. �g��ߩVe=i� @>�šlԚ>�J��ד��������;�(q�F��(�I̶r3�q���b�U�M��JF窻Yp��47��҄3�Ќ�e��05L!�S[@X�]&[�����)���0�_�)ˁ
�L=�[u,bO�İN$Q�Ȳ47����	�Ҡ��\g;��	�$�o��#{z�hh���[1`��ڭ_y�0ͺ	�1��o�ty�����J���&M��i;���@ڭ?g�۪|��������/3�ӷ���)7bm��@6�NT
*�z�/|�y[�	_T(��Z�^�����-8+��X��"�w���w�V�'�A+֭�RA�.�6����T�������4�94c��M8G�q��c<��q���:����8����^�M�HE��j��	u�0&�Ti�lq4L�o�j;��`�b�^"�k�����B����t���r�r-�h�WY� :^/��Vz�2�P���L�U�O��-�!��Ч��|�?�h��EŅ��ui�"^@<����KuBj�RAu�/V�\j9�l�s�ļ@?��Wf�jj��@�e�^fB0��y���<�"�[�;Mb�o�%���2s%C]��L�L�HPu煴K@��og�,�~]��\������F�nx�^/	򜐵�F���ogFޫ����w���RK�+P
"�+��9c\�{bR�(�����|x���M|>lYQr�Ӥ�+�Q�d����H`�}�0bga�"�U���@lR��T�s�ڶ0&��Ntzw%B�5rFc� �7u��=����fĂ�|nG'�CX�;�乚3Ig=�	�)uà�n��a߬�In�P2+�~�;�����p�u��#�@�Y�L�����."-�gX���F4�����?{��4y*w�vr�@���@%�;,����^�X:f['�z��?�o�-�c�; �P�����~(=F�y-�O�@���ec�\j�8��p��B �LF2~qĚ�Č�2w��-0s�T�:V�~`�3T沋柡M�$�k�K>#�n�X��J�I�(�?���@*���\y��}+(��b����_����_��'��cxG�GQ�*ĽT=H���-'N��"\�!!ඨI�}�"���BE�#X�i�I�N�-�$���S箿�	�;�Lݓ���5���ٶ�y{^q�P��D�zDubT���EU`=-N �^XHs~I�;��J�5dD.`��)^Y��#2A�p6���U:���H�H�N����wM��C����j|?���\���5��*�W���Q �/��D`���>}�x~���}�������OzzE�4�j�9�F�k����㊨[8��,�&|&4�J�Z�9ag�>�Չ=��Y;�(>j��x��M]�^c
�O�O���� �,� P��:+[Ծ�l�b�2�ȨK|u�<'`c':�R���BjA�V��׭�K{�m�W)����W\�Oȗ�ʌ�������x�'�uOϿ���(Mq16{<�:��O�J�QE��Ac�4��}WRY!���`��0��x�W�`�0��0�V��6k-�b=�T$�|8eb���#�D�>���ݬ�>��\�S���c>�+�I�O
S�6i�8+�����Q����WL)�|�Zc��t-�1���)���&
9��T_﷚�������{��������m���p~�ҥӥ��:���J�L��c/qش�����L��2֗ďK�����A1�A�z�s0�����0�!�pLX~։�<�m�(s��+�z��z��Y%�K��1�� ��d%9`GK��E�.vK}��`*���!�:�- �x�XwtPIz�fi:������R�w0|��4����3I@dqfZ�]Fc�����eQs�vS�y�Vۈ���_h@6�좡3&\j���l�#����z\��&�[^!�=)���*�ն@���#1�$󒪴��K1�I�h�8feWCj�Z⪓�N�y<�q��6��}�Òf�]�H��m��:�' 9�mB�����L��Hal�|��n�?:�
M���lip+x����N��ǎ����Iia*ܣ[���S��v�U���YbH�������1�H�k[x�l"�m�	3!O[��u��Dۗq�Lsn��	.�����s�gZ@Y�b�?�Pb������)@`vH�~�q�i�f�l�	�TN��[J�}���С������{�O�*���a��w}�l��NK�A�c��u�+���H�:�����.�z'��N���8/��_��x�@%W�Ɲ���T&�~�Gό��[g�6�L�QF� �Ts�|9�?��_�����(�ˊA����w��N��H:��j����sD(@����c�shz22Y/�W?J��_X��X�SS���L���1T����/>��]Q��IV`Z��f�cnJ���̬�����!qa�'bbBa�]袷��v�'%qh� R�[^�5���Y�X�pI��D�9SBƏ.�f�MW9�6�7��S��_T�N�
wz������%3I2|�;�i��ѷ��iF
���|��=��&|b�1����_�᎓��ρBV�v�6pz7�z���E�̦���L����!W���꥙��X�ԩ\�?��"�7K?�+��g4�2\N�
�0WI|�&._�_��{L�"X�'Ѯ�����߫6�+�.α��l�M*��m��������]:�]�A]�%ƽ��gθZ0'��iN�[V	޾��������s�b��h>��2��xĦ��U	�-r��X��ڻ���KŚ�Ae��>H�� D�G�r4�0�k�-����y�F$Rm-n�<Kc��7q�f��m��T���t��Ѹ^��8xc�>PK4)g�POq�4�zJ��w�UB���)�۔�(�0T��uٹ�q���ì VJr�r��Y�5�2�C$*�޹>�/��̬	"����[8����� ��~�����j{����q����/!m��B��k���&qOM�T;��v*����u�q����H��(���43� �ҳ5���[� u5(:2��D���_8t0�m�@�Z#��1���_���Z���F,��*&�0$��5�����}T*��?`>�EQ����K���x���]n�ń7g7�ޤ�_ ��M�$�5k���=FG��j�9���H���p�9rc"6,��F�hP�]�>��x��Ӄ���
��uHZ�Q��Ϯ\�������é��+-���7��w[\�:�7�i�zBmD6��(h�2��c(F���(h>?�����o�9l�xXHJ�G�i��ctñ]QQ����)�d�u4! (�\�H���������`�
�iӢ��{`�S�t�8I+a{x�f��GQ	��>uaذ+�hJljДD$�vi�I�]"�Q����`���lU���8�?��/����%{J]�hRw�IZ�����U�F��~u̜�EV;�F�d>\o�ߐe���A��Ȁ&��a�.�'���K���f�Sd7��zw�<�OZ�I�<Z�A�̯6v9~]�mC'q��il�����\a
=��Q��Y��נ���z�L}��l<�{��
Kg����g.����[!~��0�H�L����*�^�9��e����*k��:�Щ�I�us��*�z��}4I�� ��\��"�MW����F�z��A[�h����>R�E�|�l��[��}R���w$c�Y�5�eV.��ק��Z\k��}˰>]��(��U�#d-Ղ�oqr&�EhxT�*ݐ>��("�@��oÀ��ᏯN�P��W�# 5V�F�A���6�)\�͜���hU@ 6��U*CȲ�~s��{�)����53���y�}��U}��\�:x/����������p��g�o�	���8�5�h�!Q<o��L�~h�`��w^'��j(%�j��yŖ�����(X�ZsE 1:POY�?���%�������=_@��{֊L묄w�������b�{��l�,%�!~O��X�X�vS�2M��`s�����.���i���IC3�Q�f�p
�a�����$�b~��9��RXc[%[ll��<���"�3�*��Lg�����@��]+K*mB	"�������x�o:�A4*�l��A0�ޖ�n�6��q�������(�M����k�F^�A?U��όXm�������w2�%s( �w��ʧ�/e?(;)Up�M*H��h�./�74��`���Ŏ�]��J��t��r�`��_��#,d̻6}�8'�P������᪷��cggFB��o����R�K/x�kZ��)|��M�	;b=����4�6��K��2�)M�hS�qޯ{N�p��E��{4b��V��9���u�����<S��;m����$G��0G�&�D.ժĳ��kJ�� /��?��	�
c�RI_J�#�	ك����nz��W��p<e|���#a�m�I����gB7CwyWhE_��)�N��[�^k�,"�_l_�{���-�F��	����iŸm�c���zx1��堲~�?2��>)�A�ݒ�5��π!ұM�ȗ����{��&+s�����P;.9ۧB*�9²DpN�{� ��@����M�~�N�X��z�lש ,�6��`@�e��K����d�PrZN�Oo��ɶvie�OeI���x�ͤ�8&��߲9�r��S��ߡ~�y-k�	d�?Yl��.<��� o*H�c�D�6
8+갽�%VK�v��1�h�j�ɠA�m���������
жD=�ˆ����Ẃ��w�-�p=�t�alW����M* �����9b&���h4.���S� e�u�b����T֤Ʀ4l��aC'+�M�R�V��Hp7�3@_�����w8��߉o��4��x8ګ}�k��
��J)}ԓ�WH ���)���')���O�_U[�P4\�؞f1ħ")�"&�(k�J:Æԃ�w��G ;���\��稂0��Y�F�t7�>d?��
�wG+`�Y���9��_L�CdΈ9`ϗ��ʺjB��� !A��6�3��VI�Da["�s�����*�J���5!�4u��2,��4�ĿJB�rM��j�]�f4��DJ�㼟4�$������m���9���Sy���'��E�6�{�1�u����/|MK�d�œ2��r��Sw��W_	K?8�7������S���	2p��f|<�if�lXT�q�x�A/�F��fp�!���
V�T����bN���(�����+�5 ���[���c���� 4�i+[N�+��[,�F!<�{U)�2� �/�[J
��͇`,qF��w2~dF����(����0����,IV$��u�x�ԝ�h<�qu\Ꮜ��}A�cZ�a���1 ��+JK�������u��\�O�w��\ܵ�;�����O�ټb�N	y�$Ls�TI����w�����FB*����\��}Er����ח���c�H>�b��iĂ���h��ʰ(�!J�����,�tb���]mB� ��O�g�j��PS��5�aI`�Ӄ2Ƶ�\�w�Vwy�d=՝�Ev��M������o�{����Wzȴ���&��& Qv�]�����$��^H$�J�)7w�+l!&�m+h	6�W��eV]���!������w�V��I��z)upw���'MA5 �W��'}�+������/Q�+h��U�+�`�E�M[���1w�x�ٿ�I=|�>�R0��D�M̈́FP�R�g9�Egc�FZp���OѲ/*�ɳ�&ߘ�j�q�m(�σ���-�pF$oc�G8Q�� �"Bpn�;:)����I*T|̋'�M�<!�aJ�Ɵ�`�3S�`.������xZ�ԺZK����9�Fk�J}�x�0WN
eEf��^��S?��=��4{ySU+���?&�9�v�P�F�"�awBζ$ا%�6;Ь4\�a����;<m8G�H����q���T�M����0rƩ
X���+�����U-��n,�:@�����k���C�E���w̔LĒ]-��� k��9Xˑ���IfP��]f�RT�(�rbH����?���.�(,Uv�3� 7X+�h1��.'��t�)M��sݞ�T��ݶ����!���'����K�k�oW�S�@&�3U���� ߎ�ݬ	�~�`v�c	�1SJ�ŷ�{�]+����y�:�{�:c�pΆiE2>!0W_�p�
˺��bbJ�0I1tr�5�
�I��\�eȖ9����1qi�Dۆ�Ͻ���r��m�ZpL2=j�:����J'?�uz]�!��1Q[��RHb�˖��B��}�f����h���@��ή��
7v���l�8� /��k�_Jm��3>�/��<�XA�[�p�q��-�-�]V�"1E	����F[:1�5�zT��o�xl��,����re2+(Q�����8��Ձ�9m�+���5����ri�ؙ`�o�XL|����*"��C.��6���"Q[$�:'s7A�T�%y>:��!�v��a�#]��v��2T�TZ����XY���j�l*r���pq,����r��I2��$���Mo8ʿ�&�v�u}B6�/�*�`����ܺDF����Q��m��;l�*6?����c��yV&ח�1���Y���Q�D�k{EK����e���R����ȃ�-z����{P&vg����>T��h�h~�%L7T�z���]�>���H� !�j
J��G��x\ɘ>3�UϨ	�p��/VA��6�%��[)�تX*���?U�����9$�[�C��:Y�7�ړZ����Y� �2�O�O�i�Å�5$w 
���x�Ԏ ��㳔�Hw�L,M�u��u�iΕ�.l�y"�i�7�[^�5�������zX�����zo��I�D<����ɽ>�k�W���.Hzb?��V�T��S�>t�Q�R��wNph�����@ Ah�cer�q��G�LomjS�@�������}��gg0 L(�;�("�J��p�����x�nt ���'DwY�4/���}��b/s�m�9�1P�F�h�S^s���A\g.w�3���1�}(홴���~�"�w+�;���2ޱx�dF��bPrJM�V��T������3�	 ��ʆ����f��cgе�����,J-Z����Lu�p�P(kl�!�nbq�PB��(���$�.����`�Q[!��j\�/҃bb�i/c�6O.���9�٣���|J�9���N=}䫜���!�c���gڣa��*�[���l��e��;�[n<d������]�����(��i�p?Б�&�ӳ�e�U�s�c�..�hV:��}�r��21#'<�.YwʺH7�JG�s�(=N]���/E���w�o���������^���]��i�֭`IP�B{9���޴�eU���I.�%����M��0�"�45h�F$k~�ԥ��5}����&x�s�Q���&��V.������^E������gOQ�Yk����3EĪ1f�\�S{�m�1"�2�:�-M M��|���#bϦ�^�(���.sY�q)м���ᳶ��8eI�-�Q����OS���;�����{,
z��Pn�G�$S�B׍9�N��g�9�r����� 7���U_��R�J�^˼��;��7�U[P!뽡��c�]����1 ͺ�>�*ϖM�D�ϙ.���P@���]��t�o�B��`Y`Ëk&���Α�pO*\��(����s/H�̫��6M����7����?>s���K-?�*=���iW'�2	��=�2���b�?{��޷AQ��<��Q�)$A�m�5͉����4�O�1��9���;A�)�IC�C���v��9\]��1����o uT����N%��g�V�o�>Q��T#K[��f�UJ۰�X`��a����5�bl�}�;����LӨ���H~�}��|�û����Pa:�$�Z����&�m�$��P��& �&͡�3֮PX�����$�^�O�oq}n�e�#AjIV���=U�[��$��
��Oyv^))�zV6�D�E99G�|`�D�4'���ewRm�e�k�f�w&��,����3� }�g3c��p�.�=q@ނi����5l~�ub}Z�-3�e]����$E�d��*7B$�!%�I�M�Ff�F�5}���w��u�]�����[�����o��2�sp�y�����"GQ[n�@�f������e�VA�K�P�0+<�)T�5K2#������_L�[|��Q��"a�k����)�>𛂴�LS��\��%��\B-�۬ؐ��:��:Y3���s�"��jn�:���܂Sb�pa]$�Py���֫g�.��ss�q�	�<�M��2���ܚ2| ��'L�$�ӌ���6ۆ���3��-�jCL�,FR�}4��cᷞUZ_	0ō}m�"�y��7��[�,خ���^	��'����*��AU�	�s���� (ip%�hx�N���1�(\]8��p�D�I�t��˂���x��k r��P�,�=lE�&��م	s�_��[���2S��u4����\s	�K�</�&�<ɿ?͖:�K������ϠGC֍>��$�e��]����'|��VUr���8���_+�R���LW	H����e��~3ۉ"@9 ��l�xlT����wh�6��d#�B�Ic;?��K�f�� d����x�^�����7��7P�b��D�Q��n:�:E7�"Bfc�z4�\YK��	�$·�b��DS*fg�S�?��"58����r��ֶF
C��*�\���;�x�x�u(l������W��A�V���3�Uaf����G��0[�}�E�qK=��w<r� �ٓ`@}���^�1�!��Bh(��`=�60n��&B�DC\O+�ē[��39�<Nz!%Ixe��p���'��f�P����l�Ȫ7�ƨ7�����>�,1[��FW	G�<ٙ�����h2�t�/�L�ᡜrլRJ�B��>��86",�
��)�ƌ���s�~�~���5�["�$"��[���"�i)���PȔ�T����s�����,�ﳃ�Jm���1�f��O���x�V4 ҺI�QA����VT�~T��H����?m%���/�7��a����$y��.�vL]�g\��+a��E�`�.�;޺pz�W��ŷz�h!쀢��|��׫y�1�����g����h���61��=ҁ�2嬛q�,M�o.��MFk��?�|�l��p�k!���2RF�-N�aZ�.,�m�	��^�V02�+���Q��ѤD��b<9vS���	�G!X|���f��"!%e	����o#�x��0���9↖���3������gլ&�H�5�%yO�5��=�y]������W:A�c���D��(H�,�t�m7f\9}ۨ��\w��x��im��[^���80�z��s��N�"�Ҫ�.�}�Xihm�y��T���A��;�C�"����?Q�uz��N~�dț���6���5��Da?K�u�mv�n��W������QИ]��9��fg�N�A������9x��z��0$y������j`����Z6>L��^ڜ>^.�|-~����ش�#���_h�5�	T�&(��5J6{z��;n�>��kYU,P8W~��82K��|��g�*��~�4f�7�HE�T�T�/�=k�fI�p{�V/��1�2^,/r�,�k��00�N�T�S�ꥠc�"��,�3�n�NK!p��ݒ��,#�X2���\�g?���Ջ���+���OQ�	`�bN�3��(6}������d��,=�Za"��V�L��y����!3,���.I�˜�8q9P��@��������>m̃�m��Ļv�T%+�S��c��IA��LM���@��{���)�OYF�R+�w]�$;_0٧�������~���tBPI��ө��v�m@Urb0�h���ॽ��l+��!7(C�O���וm=U$�~�C-��D������a��[��`��g}a*-�����1�8������~kn�:N�_��0;x��z����? ��* �����������%��\\���8�wE H��1M��b��M�����U���̧$�s�����3��9� �UW�t��/B���^�lP�X�=�f;n+�4����']�\~��/����C���/�(h��و�2��!q�Q���I=ꑯ��w�.�q�0{��L(;H���?V�������B����b8M%�w�-x��`Uǰ;��%��e����	`�+B;�!DP Z�. �_��A���bq��黚<�ޮXSIZue�l�lr��.�1By5�e�OϿD<C��&���Y�5S�K����4�rݩw��b
ٔ���;:'��27'�� �qde����4�=� \��܂�*[�g�@�D��P#��B�\�T�R�F�[����0 /����7��0C�����oX����S���d&]K"�y1�^�
Ƀ����֑���q����%hY��>H�}`�B�E:�%Z�p:v��c%E����p�sw���;�� ��\��0Nə��a�׃Ee5@?)έ�vw��G�"�<M�����!0�In�u��(�:]����(�E�R"@[
�Y� *H/��C j�<���Y���~,f>��;~�p��osB �`o�8�_\�(���R����:�?U�f-��6��M� ��؉块,�W��Gw�����L�T1'%W{Z�}�ў~�\�
�� �Y�+w��:vb$�7//}�ٝ��6`��;�
/�|1�P��=[��N^�h��G��O�n���ll�bZ���y���N���&��U��8�,&"T�H���ݍ�X�I`�x�xQ�������?"{�1��S�"��"�>/H�K�V�S
%�N����r�2}� D���v�V�|�+�f=�DJ�E5@����f����\��E�1�8_{aE�����L�_�1$�
�N`��7�Y��ͷ�o�ބ�R�""��L�2�AL@*?R�8����W2.�o��z�=A��sw�gkc�K`���ƭ�3��3_��=ӭV���J��Sզ{]�`�͖#��v�b=�.�I17Ѳ�LfӠ�Da�[��K�b��Rc�b����E`B��l��x_�xrD���D����|V�j�.��,����6S�~)c�vYlG�٠����2 O��d� �Ė���$D���H6Î����7C�0�*!�_����<qm�z��2o��� IL+����$Q.�l|[b�� ��ń���X�Q1�D�0��y��{(�����邹�<��Ϟ	$R���Kd��C�������{�UdI8��6;��0R~/hՍ���%���`s@�dk`���o�&�ֲ�C��Iվ�NX7z4����M�{$�6�mi�py�S���D��$Z�$��R/Ǘ�qd�>d3M@�Ui���5��D2��QT3O��t�JAn�� }H���*�ѣȴ��b�ܻ,km��f+Y�4���1��2����MY�d(V�;:���"Dc4U���/6y�@UϮ�r�&��S�n���Y���+*J(T8��s�hI������e�eD$dN���!+��%��E_ٌ��U�4Ʀ�.���@�Ó�/��O���U7��I����O&6j�32u��\��O�U�{H���j~�[w���8���e�nFQۂ�x�&�k!��nO˯�]ب��LğdC[e��#WN�e_oPp(��Y{����2�H��7�9�;�fv��K�k��ȱ洂s%鹐�׻H����18_'�K�8W8����cT�!�Ry�΀����($���)($�����,M�����']�� ���F������)'nd��fƬ�;���< 5�e�)V��ъ�%�e����\ȟMyX��u%�q���PkfX�q����P������Zuٚ��5'�jZ$6T�&��û͙�t�֛����~�31e�Ӵ���T\Z�	�E*la���f����~ԂI�3��5fx��k0���̏팼��͏��'U�֩@�ڤ�1p�<o�QaԠLjT�%��1��KE��y�Ѭ��o��W�D��/���+�;g����O)��I������>2w��%�&VZ��z"K�P��X��%��ut����4L iy��4k:�>�Jw��g5��Ͱ
�XQ���:�P�Z�,�������� �嚒�LL�l�XF�h�x8Hn4�����n��\��O:��'�C{w�[����lziz[~ϟ�f�Jp+��{�01�QT����F�NHst�!�t��j��ۤ�+�c�	���ZM|�u���Ԏ��n��d*���E�(v�{1�Q���'�>>�4�l��AϢ�+�^Px]�:�k��\]m:s?��K���l�(�F��ԭ���q?�M��ʔ���.�	����������H��о�QUۿ
�B��B�x������3�0��l�����v�&^��5���a`b��H�!������E=Ka����1Y�Y��$���yz��3Ĳ�����̐K*@��gJ~��Q����T�X�S�HeL�=rv4��Z#P�sRo���g �N�.w�>zrF_��n)��$e4�%t��&�M7d���6%�Q��0�ٛ��p"3�	5����qp' "�M�P��>5��l�2��c���Ql=�;���ډ�X` T�F:��r����нk��K�*	'�ӱ3P��e��_�qJ�B��-A�T�����D�f�>u���� ^W��^Q`
 ֚�����)�Ӎ�y�ix��@sH�J�����K7	Њ)K�-���a$��R�����@Y���0ؿ��t���W�+p0L'�R�Y�Ϩ��J�>t�z���j���9�O�{35Wtx�9�fC��ە��M.���E졬v{��r�����u����:�,�m5�zz�~LP(�"{<
5h�J�pDFC�T2��4�>�����Q>'��ŀ�3|i(2�����CD�MT޿��:v2ާL��'JZ��I����+*�D�B��=;л�:���|�q���0�.Oi�n� � ���e^�����r劬��±5�toܶ�P�.���n�9����E�0��^+��'|z�΀�җ�~��c�%��Zc`�^zq	Y��<s^����������R�d�*�
๊�c��a4�HYE<�]-��]J�ئ�|�*����H�y�!J7��NL��B���O܀�:6=���E�X��-4C��)U�����U�!4�)F����H\BT䘟�ŉ~�Z�-Dyn�X>�i+QQ��a���a���ʯ�H6T�d�v�!  ��%z��@�od���$���k�T.�V��r��_
f5��d8��H�u����2�����x@�-���)�=kF���-��/���gФE�B�y��9��.�2"��<�:�??ؘʷ?����a`���rٶbVrabz��ӂG�fP����Z������F8\9i�lf��ՙ(m퉊�o-'c@���pMe�烈�FH��5�3�2:8� ��������6�����fI��}�� Z1Q��Ӆv�b�hu����Q�Z��@��Z�J�{Ac���+���'@od2�r�]���=�Ϸ.ݫ�l֊�ȴSUU��(���-}�Ivu��
sz��a@�.*�4}�T�!���)7��������q�_(���;l���n�R�� �����-RQ5 /g�����l��C�]I���8�v�z�)�Gw\�:�kٖ���a�5����_�ěO��u�n�LvN��I��bM(	8%�rb4��cL�&|�%7���u��u�9\�_���ʼ�J^˙On8?b��3�|�����n:ǆ�X��p,���AL���E�B�^NIp䊫vE��?�Xh8c�f�ژV���kZ��L"]k���3[$T|@�>L����
����(��n���ת"�m��T� �9�4d�m/��X����p ������K&�t�MK�(@߼��e����CϷ%)wi���(��u���l\���s7�c�b�ӥfQ8(���+���-�����@$��9�"s�"�҈P���uZ9+�d/�d~�$7�o"���չ
Rf�� ���C�qQj�<����B�a)��C�ъ�ߚ~n7o�:�- �~�
�3'�A2,�y�����h���F]�����p�?�+G�I.�g����E��D�[�L���U5�l�t�sڽR�_ۈOR���8���<
����=\ik+�uNZ�d�gd
�!��MpUߋ��+iEF	��UÍ���*(z�P,z�����E>�E���k�~��xC� �C{(�G�%�pr����oi�J�:q��Y�~�zw��|��@�D�A4aa���G?	rI���ȵ�;��2`�������D��}q��(�
�����tT�Pl�!���z���&��9�μ1���I��g�f��ZQ�or�ˆՀF�����#y6XK`�>�U�.0+n|bN��jefh�c������P~ҔT����(�j�x��� 'pA��|���Ԭ�z[z*`X�fJ���������T������r�IVC&-&7���E	�?N��%R,�[���_��|���C�j�wsF-�4�cMO(d������K�r@y��t5Hj�Wsޛ��T��5���g ��ێ1��>��Y�W�d���V�\2"0���]�IЈ� �=t&R�r�qF��k��
nf�R��*?!8�8��Ϻ�|��3D���Ԥ��P��@/H�b��sbٸ0����'6=����F6ڲ_1߱�M��pb2�@K�PVW�C�e8٬ݯ��)*���ULІ��ɫ��@�l^S�(_��].��/�J����=TV��obd�~1&x B�=_ia�
�uF�b�?����]��ej�MKHW����<�;�ڍ�(�0�פ"�,�jӆ)s}-G�/$Cb��b�wQ�,�C��hhC2��if�߁>��^V[($(hWhg��O*J�p�rHiw�m��;��z��a{�Ai�[����cd�h}�=9��n⼔�y92{������<��2&jWK]���=�ڂD+St�b����j�Z+wEVQ�&�.���L�|�ֻH��}��j��&R)ٳ2�X[�k��@���PDYЁt�+�ڜ�[�s|�X��C�F+��������Ka��`�%�:�r�'ړ@^�E��A�H�1���D*���z��C��o�%��H�%��^��*��Z�:OK�Ћ=Ft.��{���^*��$'���)�b�X*���c�-s�(i���.�v�!v��(Z��lѶ��_VG�9�� ��g�C��cJiI �HV�^��<>�I4ᑶB|$Q��2�C��Tvl�7��]��V�@'�����Et�3R���%�4���K�p��\g�p��мYi�'5_'mǑ����{��'�岵�*V�f�G'�➘UJ�<��v�ڑP��7an5��To�[��u^Y��0a�X���޵��쓈xC�5����k}����UL0U}��z�R�gkb�Vm�9���6$�.�(!!΄�$� ���t6�v�����(krk�R50wЉ�)8�Oh��쪎w�*����T�ћ<]���k(�W3��*gN
D�#��c������g��.�T����9��it��5/c� ��.
���
�C��]��TOu4��x�/h%^������n�^!�Z��G���߬=�>>�A�>xCn�@��AɉQcw�!n�|IW���n�
o5֒p��(8~OAE��b���s�f�6�Y��S�����ַ�Xŭ�>�}�㫋9�r�<Oc]qR�	Jj�0����|��ʸș�han�˲ld�� RP���	-��A`��=� �+��|�mĄ&��\����v�=�1$�.���ې�{0p��g���_x����c"(�,���j��]L!�t��2C�u�s1�ܖiW`���U
����ȥoR�,)�0Ib�I%ah��N8 Z���+qhz#0�Qi�#ĵi���͚���8�Ϧ��%�
�+�K?�G�3 e�����&��:H���0$���gUFC����P�Ч��L�P��J�{>(�$Tuk�i��{j[lӔ8��{�
5�]p�� A:r��a�LJ��:��g�sƏOuX��=��{~���Q����U�Cܼ�I4�o��L�%��+��^Y}8��6�X9/{��Iy�}�C7�5B�_^�̾��{;x�iR��-n)��Bu�2+QN�1�^�[S�?��P�� B��ۛjtЫ+�Mn���w�0�D�0�����9xU�D�:GN>�yoW���ݦ �AU�1�q�j�޲�,���<w�;K�`c)V9�8uMxX0�ӯ`�LҴЉ�'7n�1{YCi��.�sp���0<|�x����V�d/5F�#��C��Pf�xʖ��Q06��b��ޚ�F�OÏS��L,�����`�^Y	yx�#����8}j�4�s:�6*�����K;������lyz��%��� X�>ٸb���U~h�G��	��
i��1��-��C-ђ,sr��'�qb���)k�M1�a`Q�7	j?��z 4U��av$p�Ry=V=OE�cC��uP���'�lm�լ�GK���}QnJ�l�v�h������x�'za$��X;�Ͳ>t� ��{�� � r��(B}�OA!���+�Zhule�ǼN���d~�ș�Vܻr�Jg���F)_e��:uKj�KvM�X&g�W��چ|;?���7O���4��*-�0����Ģ���8Wg��+���\���	�ܙ�lo�Ӽ�S��������Wr�	�M�0A����-��O��.�8%��$�6G�#V'��H�M��B�Z������2�I��gThL?X^(�C�C[K\m��V����� !A��ˆB)oH�Uuyq�A���!����z箃G%��6#����z/47nr�m�-�
H�"zro�9l/�ǹ[�%�KOA<,\�H��jwۑS�%y�~L��atU\JB�v+���鹹�Qh�-ް}�6,�g�`l�$��_�Cܪͮυ}� �Yy1�=}�C�٨@;רu�/���vI�˃�V(�_^��jjv|����Q��5���)�O�L�b#�h2u���K���/�)<��[��_x������ˍ�FPߵ�|�%���e�h�`ye���g_���e* �?M�����,nU��\q@r��҉�*m'*��:���>�V4Ʉ��c`��Ay��&��J�q��	�Q8�/Y$PF�J4���4����@���.)2a�:���I�.$J=��[_��w��<k�v�.����~���d|��n�]�`�lH��cD���.2�v9%y�x���(~��i�7��j����s���
Kл�R�<�v��`���~���1!�g��� r�p�+��Q�)Xå����X��r(]KY/u�RȒ	Hry���\\Pb~���^p7�F�e�¼�.�X�lb�x~��Ӭ3�N�JH�
m�`�RK�'{FV2g��!�bY�&Y4���Bĝ5�3��? 
��ǋ}��I��/P�I�R�����X�*?L<���:s�B���nw_��Et�΀�d��0���fΒA��3�����㈩�~�O�>֡w�2�sX_�k㣏��TZ2�A��j�/@���1'D�Nۇi���v�J�Y��Q��al`�׌D�^j�2�6��CZ�+��*ʓ��!��v���p�,ѭ�Ф�֝�rs�,t�8�>����鳜�p9D��X*	]�2,���"^�N���R�8,��I���piFb��R�&,!q|�7�7J���Z� 3TK�*���L�8!�)��m�Q�/`�
۪��D'�5:V�%e%�qxA����<A�/I��z/�*��P�����d`v�OVm-R���ۍ1�8���0���ki���W��T�����tb�=��������8n��j,�9 ]��q��A�˰�ev~|#��Y�즥{���ڶG���W�`� b0�j�p\����@l!�5A>r��um(� ixCm+���a�	,H�P9�T̹����p����bNl�V��Rl�r�-��m6��ч�Hș����m�3�j>s#{#`��Y��0��|g~���D廨y6$,��������~�r�άU�u�,�����i�k�ղ���}/ �9K%��j~���&:6�^D��a�-����{� Z�����hc�(�G�hAզ���<�x�O�`�)��R��~�G\�9t��YO`%,�&y�R�A-h4��	��J-	]YZ�����]��$��h��"|ӂ9��|2R�ב���W�0B�1���������[��P�^b��^�2x�����E��CА�z����?�%�H��G3�>%#$kJ:��f�Z�v˛&����AQ��{]N�I?��r7��v1�:b�6������֐@#��C�0��*̬�`��h��R�ș;��,�!�>��Z3O�x*��(8�T^q0ږ�s��~�n������$S�o��M��z�t'�⪠�Q�\��%���3�Z0\p"ʗ ��҂r���g�}%{��zz�r��|�tvJM��M�b,�Z���/>AR��6�pY��>U��E>�]�(�o��4@�]ѹ��s*�N%����V���b;��K��Х�'������i��5���lF9�Yp
�'�˜���-��Ab��h9�;އ7뮉�LO��.ɦ%�bO��'?�@gV��#Mۜ]��g5K��Ow�Y��{�=O��:����x۱LO%�*�Ȑ���a���W���t��ל��p��sW�'��\��i�T�Y�̎a3=o���q��gD���W�qZ���׈@Y/p��Qn�d���O�-�__eB���q�ͱ۰�J3��]��ƀȄ6���&G��I�V�׻�on縍K�ݫT\�:��6�;�7��0���I�E�@�����9���0[����3�TD���� (<b����B��� ��s���5[�/���\�(��p���I��f�\3�ҍ!��;�2�R�˩�+'c��WX��T��{��t��*.y>kT~[M76v����ÑpF���gI%!.1Y���2弃[�뙚�81O���qR��i�.���"�uv� ��~	�mi2_��l 4�t��]����p��N.
N     �}�eږU �����A����g�    YZ