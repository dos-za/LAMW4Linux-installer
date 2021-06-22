#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2704418260"
MD5="e22bb8c070fa370f23ad085c7b994f98"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23012"
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
	echo Date of packaging: Tue Jun 22 19:09:20 -03 2021
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
�7zXZ  �ִF !   �X����Y�] �}��1Dd]����P�t�D�r	A=h:����Jg(�b�t�׆*W`� nZ~	y��ֲ(� �qt�b����.����~���a�(Np�l�����P��"ҋ�2ʾh�I[�>>Y��4���t�8`: ��h��yQ�-��ʭ�y�n���k{l��!�jҬ��N���ğ�Fi��L�L൶nb�6O�08Z�ӽ��"&w�x�3ه@�p'����cI%>�b�@\����V`��~<��#�	�����]���
��(������r�T���BZ�؂T���JR���8����ۦk�o�M���I*��آ�+�m��#C���J�̰��7�x�#��6�m�����Iʳ^��r���G.�q�
���5�w� {�%O
�g����bj;0,�u����ٌ݀7���
�曄���Wߵ}c�"ǵ�j뇁&Y�h��������&�������^��'���5��p��֢8�ΐ=�|'�%���97	 �1,p���ۈ㯾�����Ѝ�3��~�ݫ>�$=�^����M#ZP�,�B�VQ�¨a��| �T<�@�ztլ�[�k�<�+��|C?.��)g�ӃީI�F�����e	ٶ�����VB҈΋��z:}���F���̫��v @��@�6K(h#�t�ee�\a
FE�il�i+Wyϭ���ƌ�Is��:�+��g�I뻣y��5дd�,_�(��1a��H����Q��p>r�i�@N/��w�� �>�ᣠlZR�(���)���R6�G*�a���q�|���܁�~�"�@H�s,ݺL���e�h�Y���`���ǀ~4*n\������$>��_��gI§�JK�_��A\f��i�b	���wu���am��؆*�]�ߢ����B�����[˩~&��[��j�!���+�)=��_ҹn�a�#
ǁ�:�|a��Ν�7?߹��^�ӗ,�5��8r4���㐟��%�T�&���_s�}��Giw��C�dyIT�6���)ǅ(���6��۩D%�'�S!+r-�-��j6��L~�͊�mZ�uW���;U#C��T�~ӶFv8�nVm����a_��!�kzIj�����l�4�k,�-
Ŏ�.�y�/�h���ܤ���lf#����S^��Oۯ�P�Y�?�Xx���~��@fi�:��L�k�TD�K�?ȃ��3��;�f��?�|'�j}ط�6�;�� ؊�����v���o�>H�f��ԩ��9T�|Y@�`{�F"侼�r��_f���<?
Rs�w�\�ىZy����\�W)4�����WO[������ȩ� G��C���z��s����I��FS��D�䋲5Eķ�	l�űhp]���p�׭!wV�:��m���)�(���I��o&/�[�Sw>&	�zľE/����d�j[���¨�~@9�*�O�?�Z����U����W�����Ƿ���*%�e��8�kƿ��$���4�75]�'�@���:G�>h8[g*X�t]#�oS�9��x�t����^$�5��w"8`�2+P�;Ow&�Y$Q�m z���R��9�)v�[xx�@��R�n:�!�0�ANmtL8(h���S�@���,��PH$�Oq m�D�׌fk���-�k?M��Jɲ��Z�̇��T�b�/�oJWPĚ$��j{T��wy�ܭ�����S�&��34I
A+�����j�����r�����G��y�0���[��Te���}�̡xĺ�z�r�7���^����l�2��^]q��!5�&�@�tfD|:Vt���Zw�!��B.Pi�u�Pݢ�A��e2�� ��Ǹ�*�5-_K��~��.�ѱ�hƨ]��G/sb2$8S�	�[�7l��a�4��+�� ��LТ��o[�U%=T���VV�n���N��])D����sd��ݷcH�$i"�j�����hm�yXycu��$���O+~7���O�@8D�Q����0��7C0�@�7G5:����m���(C(Ʒ4x��6�������5��T�v����9@g��![�e�Y`c#���&`�3  �l�}���>?T ���i#���w��4�g�����BG�g����\��`��S��c��S9�>�m�[���78�o�DF�	e����禣��f�h���p��(Ф&ɔS��~�[*ud�#�L��i�6����e�_���Z�t橕5Ü(u�����s˧Xе��du��]�Y`P��4�j�Z��ܒ�&	����I���z��;��j ROnA<z���	���'Ɇ��l��w���~�T*��l�.�U�w�ÈZ�0)	)P\,Mv�*3HJ�D�����s�>���"�!�:t)��	��W�6o2��$0�����=�7�^TP5s���[�(�E�T�R$��+���u�Kv:�K:\����X�6Z@<~h�w�!Ul&�bpf*��JϨ��6_ܭ�ϭ"�A�pM�S����E�Ř㛘�#���/�ߏ�m>�MK�a[q!�`ǍN�ȪC�>���i��֚#.K`|MMu���b�4`�=�ͣY����/�L�;!�\R��v.<�,��Dl�EU<��~q�5.�g��l#�my��}�`3'�s;'�����ϳ����~�Y��6�su oY�@<���������a�K�6(f��l��A�	t���M;��-%'v*[��k�0���E�I��g)2y�bm��`j����0>���A�@��ESC
kR��Q��i�t�����Cpb���E[�tj����>����RF{7�!��l��q9�1 �͞��	�	>�D��՟��q����hg�s����?����EG}곳kHް�3Ӹ���s������:�P�m��Z���r�n��.i|��y��8�4���;��h�5��Z�@W��-��K�ZV"��Z��:_�*V��7 ��D&�Z9*�@y�;��qT�gÂ�V�R��kj��� ?c�V�8&-А���3Rr��
Қzyö��SR�zXJx��BW��M�I A <����-�@ �����f\-�C|���p��ނ؆���� ��ʓi,���>��uR�`���(E���w�L��>{��Cp˭���@�AR���I���6nMq����TS�A���	�5W�؜H�d�_Q�2�s����ܝl�U��������J6�gJ�-��I�ħ��W��l:����>�L*څW�AU�Ϝ�����#e<ǅ�A��\��孝��@��\���B�ɘA˴������^��I� <����"��+�G!��<��M��sn��;0�
�<����M/=�T�;�y}�!�)F���S,F��j1y�;-�P�}�B��:��l�^�3�� ��ɡ���/�e�P�cԏV���z2C�K����"q��SF�D
T��3�����l��1%���sX����6:Q�Yߥ���Q�x2�b|�kov��sV�S��ǈ�e_"P�\M��&�?�`�D`��a��V,Y{���ך�W�,`-=�$h�^���]��˾�ȋ�9u���D�B��iYiI�z�����z4�$y��	�O���~���a��Q�V��W�.Nm�Y��賵��5׺��'� �_����D`��#_��s�I�:�ww��?�{���8W|e(.pꔋ��� �Pm�8}�;�1QD�~gl��R����_\2���΢8&���A��.&��'EF�DAq�/~'�B2\$�pl�mh:��=��3�raJ���+Z�}(7�-�eTn�Są��sޖ"H��.�`�~�v���}��(/�l�0�;	�ﾼ��9IH����r��� ��C��B��2�����
"Ҩ|���wc1KG2��Ճ���9~L���N���O"	�;�P�<A,��_��o���6�Ᏸ;'M���T�g�1wo���/��0Sl�!�s����f��:E{^�AG8����V�Jo3:Rv��zξ)���.��L�KSÎIXs�8�V����l�
i4�ȴ૲鈆A�nd,��%޿�.4\�:!\k�m��[J�!a������3"*n�!|p�����^���e��އ�ԍ�d膮�p�;�����0�W;�r�����̥�/�Mӧm�)��v=�Iz)����_�?��.������k��kP�s�j�R�O��W�.W���ĩ{\��Fx�w�6�4[��aⰱ���N���,�����~����I��ٛ0�l�Գ�z,g[\�Q��S�,B�;Ԃ�u��?��-W>�r$3ӷ�'>�n��P��DL��~Z[G��Hs��b��m����׌4��W��$��O����\3(ܙ�R)+0��j��]+�q��(8�"�mcqF���<I���Ќ��^�����w��r<@泊D�Ē�5@���\U��,L�(*Nk)�԰G�xT5U�٧QI��m�?�YJ<�xuoz������q�G��B���ļ)]��""la4�T%�l4���ҙ�]+=JP3��$!Ƅwo���bV�x��EW�0f\bqF��GTj��H�L���ݽ�����[���X
:d�=�Rﳥ����҂�{��$o�A�yC}Pd�R�k��S��}:&���=�jKW+݃	d�}�A�����6����R����"� ҭr�VJ����~^�Yy�u�L�����Vz?8'�:�/۾o��ջ�(eG>����(�TS��U
���悦����qnwO�ċ��:��,��d�X;-��c>ZǛ���e��h2s��U�&wz�o'l�޾A�g���lJP���Y�h��!�����JNVgq?���d����	7q��w��9߷���&/b��޾mՐ1�|$,/E*����*A��_qm� �������| �,��˼�1[���L]����C6�>�OoN찪��5\�Mo�Z2.^��tc����@�P���S4�4���Y%�Vj��>D�^�0�������ћ:Ƌ.�.��ـ.f�iP�z�p���x��L�ө�|=�Q�{	o���ư�
��"�Vv���6��Za~.N�{݇��'�si33�pBO�6c�~O�1�|r��2���w��MTU��G�|	F�=( ��p��ga��W�� �sd�#���N��@���}��f�g��| ����噐��á�`�+��`�TeA6c>z6��9\3�*	((���@����c�������%i��Ĉ^��!���tK񦑸�<�y�����^C�� Â�͝Qj8��Fj�bY<��up��m�Q6��	����hZ�@S�=�>���Z	#�N�B�]�;�`���{/�.XE����XsY �h�j4�R��$�����z�N��L�4t��b��:!�
�?�,�gbMv ��b�+K��}�S�!ѣh0�Y�<�^\:a�~(��>h�3#@ΐ�{�b�3��"s�����ҵ.��K��ˎ��-��ld�+�� ��L7�`э=O�yE �ע��Zϯג�dՉ0������/o+J��W�	�Z�3�ݑ7<:�)_]�3�EW��|}������ұ���vQ���U��`�R��$�$GG�ָ���ӷ;���r2��LӇ��!��t{b����dM�"��[���I�T ����?ˮ��ʈ����Z)�2K�-�����àv�H� "J$��}V��x^X��×f�����	v�kޜ9�$О_��c=+:��W�@`ax�&��ŕ����L�eB ���L�3A���Y!�6�H n�0v�������x�h/6��������
΃ը����bhǛ�;3��L���7ѣw	v9�/��A�#K����e_g&�x��A��*[Y�M;�L0-�\6�5�l�We��~�d��t��QZ8�4~�%�={d��+w��3���5o�i������%�+��c�zQփd����")u�HX�'�	��%O����ϻiT�WU��M�.?Al4X��\�`�}�>[j?
V��������~�;S�L��y�F���u�0m�(����`���c�9èPl��o��u�D���U2b�=[�C2��T�Q.�����|um�C��*�g�]����ϧ����ctW�y�hX�Co��<C��D�u��@�A����Q�a�%�w=�����#h/J�6�8�F̍�?G��$��
黳���K���z+IU���2�����y�W������Q6���Yh�&�o%�o�X僰��n:rQr.I��?�Z_�E��R墜�O��ס��?�O��W�<p,{�؎�ze1�A2����������us�q2��������;KK��xw��S�tpMxg'��P�DH�� D�%���Cd},�b��o�K(;��0A�͐�9*R-~�q�>�&��>����ѼZ�xZ�J�<S�/���c��ů��l�X�eB����ͼ퍱9�;G:����� �����3B�y�k�8�ٰ�4GawA�q��P!k����-��Ⱦ-{?��-��}#�o���QxUo=���p�J�|���6d����W���]"�4�W��?�����XaUrZE��LT�z*d_�.���k*�~<#��wJ�Z.��n�g5�@I�l�����0M���0��l�Ȅ�w�ϽSf�LF7's������W�}S�z+Z�1{׸0.ỽs7�=��d$�����i���������C�_�����a� 0�t��)���)#�:�%k����p��<h���r���{a<��OUD�R�B��1&h_�!sXb9���6�Dڭ����5:�J���zYȠ�NЩ�=P�襑������APf=R�Ayh��3���&��L��H@d�*�~����a-9����y�����/p����3LGN2�N�~�	m i��in�a��Y�i��I���c��X6�о0�O�ZE)�ا�4`�z�!�ӵن�V����U"�H.�ܴS�.(HerV�Ase�Ι�� DG��e jc��?Rx��Gk#�})/zrf�iE���(�Nܘ���z5o���[CUh���E&�⡕�*���j�Q�	JX���X���E�Qibps.����wg��֔��Oh�.Z]U�S3>I���?��C�\�!^�3��]M+rHM����S<!�ڥ',7!�Ml�J����|N=5���$�Lo���8�����-�����{H
6��������40t�A���M��VY�$������̓���5�=��9��\��O���"rVl��(WмL������M��U"��ґ�6s��yrv�-��70�4����~��]'jX�����}�En&"�5c��51��cN�ڰ�
P6N(J5��s=�Q�9���sz4�$&į"\]���Hp<��Ԓm�sb�X?�{����[ݍHv�6� �l��&�b�]���P uhB��`�^�D��<�o��l0̲�U���:��}��/H�PT�њ�b�K�,F&�a�rx�^�2qgq;�*�{q}��I�V���th��΀�ל
�,I�4��)�Z�P��A1
?Xj81��Pk H�!Y�,s���@b��~�"o\%
������[�6g��!F�g�ڲD��G��G�,tZ�F��&��~�&�T�Q�r�A�j�j򻣄�
Ģ2�:Q��Vz��e�D��=G7��_��9�@.E
\���cg��κ�T� OZEz��mH�x#PvM/+�O�]���;�'��AYv��dB�mJ�C|�qdM�͡Q�d�LP���C��V�=Z����6�#HP����HŚ�qfB�F%d�Q`ʐb^����rn���zp��Z�LN��rb��(W�4J{Q|�V��
�J�Ҏ�V��/��lKW��"J"|^��dv@i���Xcg���(�L�z����.R���R!zt��$o��/�|!�� �" e�CP���y�=��z��}�g��eT�[I��5c�\꣇��t �#d�j�0��Áb�8pQ��8��� t��.#?�P�9
�߮�wOe�
ru5��똷����x��)�������"�N��:R��Hn�ކ��LF���x���IU�/���S3�b%:�F�u��0h�P�U�<o��8e��+�T�:���*���F`?����@�-?:����b�Oޠ8���ͷ�7���YR���&�	��9{��!y��_�cj�〘P
��v(]cU���_����G��ঈ��sr5q1I���֎���r��p���[����gO�tk�0׌�����L�B���nuVb����c�~>����r#@��/	Kۚ<C�W!���*�u�L%��Y~�f����4ŀ�OvD�rY��l��s�V���#g�O���|2�M����nc@������m�m�l�V��6�Bu���n�<a�<CoN���Z)�0�V�LO����<�cX}����\dG��=�=��g�R��������i�����&d9�B���OI5����; %�K�t�*r�0�ª��ڱf:� V������ޫne�@���P�;n1���\��k�c'1�h:��*�X�=��w�U���^��փ�`�eZ��O 9��$��X��~|i�M�:;9��I}�������]�z���R<��^��D�z>}O�)��&� 
u�&�rK�PQen�>�)��U�"$���r�=���8H�"��d��[�N���ΐ꺣c��<E� �|b�\zq�.Ӹ������3!`�2��߇s4]F)%�s!�}��E$�Ӥ#g�.�)�kN�X~iM���);~xHV]�,}�V"_|݆�c�-q��c��T0��_.*���!R��� Œ��Qhw��R�9�����_f�|�ۅ%g��d/���,����"�V�l�,0���jaQ|���2��tYe5F�}���G�Xir�A胥��q3�p�X7l���Ћ�C]�y:7����c`9ã$b�ߓ�˧o�f��o�*pC�v�Б&�!�i���X$�ga��\[a�">�D2�E�>��N-U�K����,�=u����	�q�:,����������Sv[�v�@ϓ�R[�9�Y!p[Đ�$GL)��M�lr\̎���G��6��vv;�:�߁�����"D����(zl������$և	�%�RV��V���8��f b�!	���#<%C���mЦG�nv��L�n�4�B�Q��YR�c�X�z�{o��߽4旐E����'?Q<"��*��>d�6��W�<���|5�\Oky-�����^�oQ�D��Ȑ�|`ې'�[�o�ߵ�=��� 7�}���43�Ȁ��d�� �!�,��;|B�o[�ڄmcGS�n{��W��g"��fK�ʹ�Q�RYi��u��V��m����S������^��{4(�d˖:6oI:����[=G�X�E�������1o9�`]��x㱥q;A��&�tο��/�P��poe��p\�X��$ӨT/<H��;|l��V��!Ujn�H�h;��_�{�8�jޕ��*o������������p��)���z����6������|� �xl>�*����N�� �c?��O����� �i��������R�̯F���G�݅�R�jXU����K�I�5"o���uT��I��݅�A���Q����,O�8@P���C��ߛ5�@x{�*�J ��[� �~m���b	C���h�j��~�f{�]���q�"W@���n��a��7��6V1Ho�k%M��^��f,;�#>lz����+&H(��Z�?�;
^���U�#XiN����u�&��r-��s<F�5ױ��|���%'���
�L�c�n�����Ge�h�hr��=<&}x���<���b����o����{S�JhL���]�7"	MW�I.ū7C�r�)��9I�eߜ�j�ƪo+���P'��s�^�ˎ�ԡu-��ΔH�Mm^�n�|%�����p��@(^�HHf� �a@�z1�Iueoa}��k�����.����5�l��춞�[O��Ϯ�3��~�7��!��(U�����>�;R�jc����H~�$��豛���,<���$5n���[oi���è\�L��>�<����������^�0)��I	����T\Փ���_`��NJ���o5��֔����x�&G��h0��������2����7&� ��Y��^J�-u�O��;�2JiR��!�`u�ź��6���L]�Vul�j���X ��n���!���.�f�
��-��
y�����[���v��8w�%�6��4#X���]�y;�F������ �PF�R؁��[��Mq,���-�׳��*9Kي���7
��/���L�!�����^/r�D���� ��Wy�K��Ӷ�U��,�w�W	W��G�B�cl�G��X�>5���.|��͕�&�w����ib/�k!�ycs����:���jk�g���&+&�D��of!г�+�)�/|!C.�Iti� ��+S�d����sp&�.���B꘹2����ȹ��w�g)=XĜ$Xeo�e#���B�/u�./d��>}P$]-�Rm�U	��c��~kNQ��K��`!AU�K]}�p��p]<�.oUׂK%AX	��&?�T�nr��5���'ˢ$���d?��G�}�`����?�<���#SP�@���Jr�<<:%�u���e�S&O��;�%ҫ��x=#)��n���D		�/��x�mL�"���L6����ٜ~�H>�r=U�ĵ��A�@��;��W?;l�:�6>�30a߄5���G{]����@k�?(�\L����;�6N������n0Y���5�F�I��V�&<y��(v����<PzN���E�o�p�g��O%�8��D�(�~DCf��2�(HKi��?3�-ν��4�M����+^Jum�ʂ_Qy��ݭ�'em�II�,V�ID�C+c����c�������˘���������$Cd��D+�䛑���S��́��gV��{L�Z��o��W��mik�k
�XQzj���6��ş����XՅ���T��iNωnOEa�A�b���t۾M�{�Z{�I���r�O�M�*(����´Q+���t��{���vKV�H��RK�3ܵ�R�7���Rd��ʂyJ|����6n(��d��;�p�촌l?�]�bo�F��_�[چ �tNP�� N�5�����Tk�y4��@tI����Jj�HH}�EB�,�;o�4�x�!�Hbk���_�x�e��)�e.�s|�<Il4LY���
v�I�	eMޝJ��z	���`�}m&1�~/�l@��@D�v��2���؆����1�\8��Cd�0Պk�8����G uWb�&��9V�Q�"|2���!��r]�k!��4����d�_{3���9�LJ�p���R:�A?�k)�ZZf�P;K3��%��Dd������B;"��X����*!�{*���6Jo����O�0 L��3�F\����Z�U@�I�'�ui6�=z�3i�$U�K���Ntᆸ���^-�O�[�J[�N�|�[��r6���ŚK��@�q��y!4��^���	-r��"Php<3BB��:\�AV�q�P�s��d��=�zoZ�x;O1ς[�M@�|�>,Hbujw�ت9z�I-L�)�YcoĔ�G�H��gN���b���~UO��0�j�$�>o �`�Rw[�6��9���%iG���}�������ZӤ��잗���8ٝ��f����	��]n�PL�:�z�`���FI�/��� �D� �'���v�R�h�'),o^�V�38=���ﯩ�G�dM�(R6N$L^��!�!����qIyƿ�6��w��%
{Z��{�j I� ��DA	��
?��=\�o�pL��ﯰK�$�3������dC���~	���d��f�| �E�B�OCKG���v�N\bؤN��>��w����aC�a�_=�ȷR��mJ<��׻XH�B �K��^�"����sȮ��7�����)��rK��<>��>�=ٓ���߫�.�q���w@�������9+Y'KV�+A��aڞ��?�	$��S����g 2A�0'p���b�����$���&����`f%=�3�k�k�(���yET�����<���Xg���k^7�@���.�YCpmx�W_D҇�0"Zgz;'m�����ž)����OǬ��`�͞�J�`�Pk)���Ё4⇞���lk���O�j��X,���I�_��vS���
?)�+�ȝ���%]�����C���O��^48�hi"���*��ɺU�C�yjz���y� �K��do�y�4݉sBt�@�	<���^��)���o��fت�N)�.n-��/޶tt�pޛ[*}%��Jz	/��b�=� �T��u������ѡD|�����@�nn�>a�N��3�K�B�W1��Dn�;6�ܰ���ʙ5B��BF�[a�6��y1X����)e�iޢ��ȓh��#_,��XFt;���ʦd���ӻw}#Vy��j�(����@~���;A@����5Q`�V�z�1�v]Bb�n�"%�:������ �S��O峽a\{m��3BFh�u��F�C���akR�� Y=U�EqY���*Ic���k��@�o�`�u�Jo'�5.̪|�\s:��5WT( �k:�,��4���=�vڷ�Bt������<��	²�gUt2%^K�8e�?�~_=���E��y��Y�R�'�zUrPѢ���Ư� �cF���y�,C������wrt-��D�M�ԭ5�+���
ُK�Gs��恬A�'�K�u����\�UY����������A���l�g�$�,��*	-ؒt&�l��N�s����됣�x_���je�������mlH��:��{C���G�Px& (��H2-���S�|�o�-ULlܘ�r���;���JFD��K��y����w�%3#ܻz}/<t��#���!�4����:�I��v�,�Q�e6�Acȕ��4�sB����O�=��?��L<��"�:{1)�J��D�x7��a.��;y'�$�k�r�"�>��"����^�˒�JA1�OL�4�N�Q��	�x�d�'�,�v&V��ۺ����| x,nm�v����,���|�푙���-��C��U%ݴ�A�audF�ȇ�9��g�q,�R��a���a��~�����kت�
�\�:Ч�|%$�� �{!������6�$�9��4�ţX���%h���a<pX^�u`���.�)/f��{�c�﷔��|l_0��� j#V��y
�ϖ��H��<�SY����Oct��^�a�L��_��"�3F`^0-��ԙfY{����$�(,Zߌ�_3��(��g����f�)�9.�"�"�n���m��1`}����	ƕ�t3�.��o����rWG��EXM
�)Zq&��Q�"�Ld�v��ۣl�ꙑ2R�c�bP2/>ɔ��0M��C���m'�p���B�%0����ܶ���>�A�#ʁ~α�0�.޶�bn��i���<'�����#=GC�=��`��j/;�O�n�����ͥ�Q��N��禎v�Ɍ�k�D��=q�+�AڄɊp�Y�H���+}A%���.��̙ d�;��b1�0�g�+A�u]ؒ����c��q�  �M�LS޻HV?�Pڔ�{/ؔ��N7��.�qz2��O�k ��G�۴۠er��0{jG�:��IG�[ѯ0������=�ԕ�c���A�L!bo �܉Fٓ�M�����D�$!��0(�sc���A�.�83z�e푨I�~N�?n�x�3�N�c�$H����1�G�����pĒ��è������7' T�J@��
��g���AZJ�`%�:��5�)�M;��ނ�A��!����'�v%�k�1-mr�a��q芕�B��Gq������Έ�ZX#L�R���d)�sǻ0�2�շ�q��D��e,hR�K)'~�[�3���;˄x6m�*$�~˓�_�?�n������A�_~�&A�����wl��>��@a����%�c����m��N��mJ)�L��x%/?%��Y
�T�U�]����J�@Ul@�[.}�l�q2�5v!A�(�U�ˑ 2�fv5<F��E����n%a�M��>�g�����!�u�T�c��X�@�T1����|~�:6����.�ꟗx2�!-�R����O�_�H;$8V/ɺe�V��Y�Z�4cU���|���Q ^�D�w��,xw5���e�9G������1+ҹC��D���TZ���"}S��(�p�eI?�H�-���|�n���ze�
F���ro�\������G���=��r25o�r����t��A�a�-�@���߷��O�&��īRI&�1�ܚ��HY����h�g˹[��9�O����{S�A�udL�e	�$������f[���[^�Sp�@��4����q�����Bq��3���[Ǽ�4�:�\��NBM�)���T=���'Vp��n��o�13��2VOߌcNc�y�g�<��uek<zYV���\y�%���^��`�&���F����$�wD�#'���ι�&H�_�*J�	p���%�n����0��wt����]QI{�Z%��4��,@J�1�x}0Ӵs�ψ��:/ݫ���ڭ ��nP����K���K2|�ޅ�T����&������0�c.� WÑ�
��;b@��)�"��S��"Ӗ��L*��F�����˛f�%p��
oSp���JhM�϶��%�*nD��Q��􋀷�y��g�,>���R�	U�d;QÆj�%?+�JU���RS^��blm:�x���^	���� jЎ�N�۶�rS�el������>��|��M���$ԏ�6�>\��$��oG��Xڬ5��Q`���V	�|67���i�^�ET��u��}Ԋ����oZ\3�)��P]�~9��>�\�����%��UQ1���kR1e�w��TL�q[X�	D��7�aS�t�\�.>�"K��uS�M~�9��
�)\�*@�s *�]�Z�Fx�N(����X��_�"�:�5vEt�po>.7*Ƌ#�w����M|ji��O)����\�s<��S@��=A��S��y����Q�D�R~�*�o"�d�Qr��^4t����*U8A^��6\o�Se{76��5�����ǌ�cg�@o����L�E
ǱO�A1ނ�@^�Q�Q.��Wס�xW!�5�;-4��蔹:AN[�f���fXl�9�!Vy�@?^<�/���55�;�X�e��T~/���Z| ��$c!��������6���-�S�J*�YamB��8��ȊV���c��DAϯ�o�",r,��а�q� ҫ~��~�ڋ��5���]�*�ŉ��͍D�ڥ1�ʀЅ�r�sB2c�z��E���ç�����&[b��w�\�|-�J�y��g�|Tuw$��ط?ȹd�.������eW�Q�LB�X��ٻE�`hsHU�BT�9x�dx��G�- ^)���攻�Nj7�,@�s![xy�R���V� �q87�'!�y�=�����R�B\�P�|�4������d�K���W�b!O
N� �۲�d	e���<㽁��f�D��К���Ɯ̨�0��ʩ�ބ�-d�Q���w�XҿzǱ�q�k�4S�����+m
`��6�:b�)gO��NC�-E#��xGW�0W��O�xo�ɜ���Onn>Y?+��b�L������eO�
g�1"��:R�SD^�"�k[�x�A������nw�]�F�l��-�3��ٍ
j"��Ԇx��'gW�9���6��"{�yPkvo��'��{ &l�O�o�$f�|�n8mU��{����ktǬ�:�9���Բ����v���a?��C�<A�DڡGi�H��cu5�� �-�9>��0fsbM��|����TE��k��s]�i6OZ�SM�:����6�4#F�	���	��l��#I%ro��4E!�|r_�	����̶!Ȗ.��=u�zﮉ��IҲ�wK��J���⿌v~P��(���+bP��ۨbl����_b#�UY�B~���&�N����ܮYt_����)|���#w��U���1Jj1ډ��x4lqpW5��6���+��T�[,���7�]�H�="�c`��^�d�fAs���O#��;�g��A���<fS�$|^#�#��+�4�D!��1���4퇪
��a���@.��5`X�j��Po#5LJP����Z�I��+dR�`����:�tQ�:0��R�t#6�"��'���Z�E�RS�+8 �B�E|xW`m��/+������<`�7�I�s�Nt��N�w1���U��]��]3��>^-_q�()�1Fe����9	f��������@�"l�%��d��۞�����:!�� ɔUS\���Uka���E��Ÿ���%� ��dODli�{+�ޙ��渝�󌅢�/��a����Y��ǒ!�')
��H7��}g+�ǥ���ܴV�I����/Z|vJP�I��q>���>��A�#���1K��C�X�0@���œh���1&�2*�ˮ�P��H��럅H��..|��wv�SG,Z>������	���<�5�X���6���F� LÌ�x�Ao���%�|g�7�E60 r����_��G	h�  qn�;;W��\+��Ӻ�f�f^r�D�q�Mi�۳F�g�5�[8��"(L�����_{@'��Dv�e�S�d������M}l���`�т�L�� ��R$���/R�/���R)\�IKȒ�6J,>��B�j��+q��iǜq�`Yr���S�ή���,!�g ��\��)t� ���4�WTq�Ԛ�p�H������j��!!*��*]ٷ�]�H#鴨`����g��qx =+��>+���	:��R=�jy�vl�o���Y��fB�l��>(�*��oh� ����|�j�R�R�Z���!��k3�� �`�֦��Fj�h%��to,�ܧh��M�U��[������$V���>Q����C?0TX���g��ڨ5ci�o�aN�T����������:�5v��W����ouF��F_���V�Ñ����#�-�K*�P�)w����@ZA��ke�xA����e����*B}_1�l��E?�Q��M���:��۳s��R+D�c��T�޺��(�q6S��5�8h��&L^˥Q�Ǝ��I;p��5<�Baʜ��i�{�Wm	:#iy��l���G�Ù�
(�aKS1z�{ h֟W�@)|�[L��2I������vd2qA�-"d�"�V$�}�cQ<�dW��Ii�ѣ�kn�E7��/;30� F���B���O ?�_W����� 	Cy�8b�_d���yƄj�
K��A�R��Ƙ ���8R�=���sM-�c�Dj����e�.��°����x/
�܈���_Ƥ�+R`�����Ʒq��L�3��� 8m�\e�H�6	�ǑY\�$/w���}9��k��9��ƕ]O]���̜*��8�ll>@����).P �@2�
>��.��O8�=��3�/Jȿww���]LT��=�:��-n�"=�ͮ���S\�_,�� ��D��W��b���zD'��P� �t*oH�ܒH�1�܏z9�x��e��R�ejdU�q���L/��]\</6�JR���o�R���Il�O�h�Is�,�3!V[��υ?wȆ�6����ʁ�j)QFQ%���T���}��xI�]?��vJ��v�]���W�f�O�F�^�M�Ծ���$�[c�46�F��e�;�j����5��f��=��q��錛��ޤ�A?�K��1����b'�唖��T�}�D��B̟�LHHD�^��צGv�ڢ�Wh��n��Q&%�J
�e�\Q�f��^u 	i��"���IE��T@�Ku�:WƳ������	~\8o<�6��Ӡ��'�d-A[�~A�X:ی=��h�4*�%���3����G��s&�����+d�gN�y���Y��������X�D���3�#��}̭�6�Z�Z���l�#�X /�5���A=�*� J��Fg�cq�&��w�܉�pghC�"��JP���|\}`M�%�B�;KU#X�ְ&��+Gy�Z�L�c�2�E=�'�m�mB¼[i\��런�V�R��OI�^*͛�_AR��c�L�p�>l��DEP������M���u��讱O��
_�`?z��7n��Χ��Hԯ6���m��b������ݼEu�
�6+����^N�l������`��|�)��#�w��3���L�#��"���o~B�!��$:���y��� '��ь���C�h4��3���R'�]]��˻Vw
����H`dNV
8��#�q�l%���Y@�l�tj����Ø�q<��'g��ln52KG��LW��d�ʕ�e�Qq�&`�~����S��A]�aY�M?��\e��Q�X�{���m*�Lx�v�Ǎ���ѢԐ�?�R����,�6��A�Kk�'����>(r=L$�+����>���0�ʍ/mT;^��txXˢ�#ʲ��-�2�
��sk��O �1ҷAҽ�`���~��rK)�gI�Ib�M�D�ȫ�}�͋�n�A��D��v�/YU�"�Ñ�9G�M0vir�;���e1$��vM��:�q ��a���L%��d�[�+}	=��+�!�~�1:_�Rx�C���:=�:�-�q�����c����%4�q�)\KX��d�T6�챪�9���3̺i��}!�?h�{/e3ʹ��X}�H7�9|��qŌ���Y~��Y���/q�ԝ�e�J���4���s��ط����Ϩ�0��KS��L��5�@t�mY�RP8�����c���?�|[7̕�(��������ET:I�OG��� c39�0t���8����Ɵ����N��%���8SφNw�ڤ)�UG�#!ڸj����f���fj�1"��U��'�Qd+��`N�%|.y�`�#���Md��r���,�R��Zj���F�=�QH�?��h�y�ʡm���%h���P/J�0���{m{��� ��,H%��M�jD/��p??"/��'�����i��^�	c
Z��:o8pM����B�{�����b*��ŭj�Dk�f���f��>��;�ضv���|(��E�)�l$� �[��I�\�� ����MQ�bNzS hO[���P>CJEZ��{�׽v?ͯ���o� ��3O���j���qa �?=�����)U؀��m���$�&tF	tE�V��TGSLAz:��.�	�CϞ���UҢE�
<���Ow��ؘKC��T�E���/�� �sj�P�a����$gV�IWTj9�|��`���{��7�>\]��$^L�Q���C�K ^-20Gx���J���Uد��mTV�珓�������
9�:�>�(��+��|��E��y����5�LY�n	#hOO9ƹ����w�:��L��&o�;R����l�Ych�޺~�a #G}�'�f{�|�7�_04���ߛc��Q�j`&��6bI-�܌I�D�e�G�Er��h����ޢ��vb[H9�@��
=���.�9HV�栱7�bgiB���7�u� ���	qt��^�©u�H�����i�dA�êKs�I���6��mv��.q�M6�����.H|7��"q���+: '�m�Zr0�M�ʻG�H}��G�7�y⫾�5��J�`[�ȎdB���_)L��٨Z��z�O���O�6U�>~�-��W.��kD�y���ICz��{��:Y�@y�W�J���Q�g��$�/�cfڒσ�|��WyBd�0�7=9T�qjx�T�`��"���/+`U�+������r
j��W����r��u� �:�!���?<��7��{|��zW+
���� F���7��(&�񞫊|����4�Z�Bx���y��^^�(K~4Y"�3��$��,�(�o�9b˔6Xj6�2�@ޯ��b �O}B�"��3�\�2���ʚsG�-Z���l%��{����ے0{���y�̺*}z�5�����	"�ִ=�CFm1�|ژ�8L.�C��?/�D<m�.����ՈS���Z�8��[-ߔ��?۴��STu?b������^:�F+���,Nyk&-�r=[g�D}m��[l���R��V���m.�(� �n�3��-��A[��>�)��
et�j�=��x���>s�^!�D�Y�"�Gs�G��t�=��okگ_���.�%�z���"�d�$%�$C�&�)�x!ڹ���C+j���5�S���ؖϫڼ�{NhA�d���c{5%i�o&QP����	��FJ)��7!v��xo�Ǚ��8���y����6%(�9���Q��⬁���r�^�()�dQ|���ٷ	�P�x�b�f�x�D�E8>��;�om�V���(\����tbc�5��}���,,�0�6�➏P=�g��V��1�Zm����P�4'#�,��D�7��<C��S��0�^`��F>g�����˩=N��G��tS��ȟ5P�s[���-��2���i��B����t�S��	���7@ؗ��P���셭EN��� �0�E	�kf��=O�܋�Ean�8�>M0�l0wI�L�O����,�碳7��$y*�������G�/=l��:Mޱ}�3��J,���Ӿ�l�-�v��K�X �����h�dŌ[�;�$�-N���Yx���)����,��>�7�����7������8ࠦ�ǧ��d�)����_�����T#)���cT���t?��TT�J-��rx�u��E��;�U�|�/���w;����{~�g6VHE���Y�����:C�I�������}���h�����T���f'����D�������*N˅��&���7�Ơ��2_2�����" ����$���`�H/C�5='��y^c��D~Qu뵇����s��tc���\��OW)������� N�T�)�F�3�l�����5��?���Ssn�[��g�"r�-�:x�q?�]f<���U*vy��\	u�/�`��Z����R�mlKZ[�zqݔڥ��~���p/�=96IfdE��ջ~H�������+���ه�	j�)�]�� ֱO�J��{G��W�l�肍��r�,��)���|�`Ģ��w}m)y�Q�1��%y���$kM1��[����&���i�
��n��+^
|�Gj9z�3V/i�"��4�&x
3_^����u(���ne�Po� 3�w�4�14/�����όY��tu�zy~��[�����uS*a���Q.¿�����K�P�G�4'�/,�Ļ�o�6�{�[K��<���GlUY�B7�ny���VC�J��h��MK��QѢ�$�0{d�µ���/.�N�h��I�Z	�R��� >/�Y!�А�k}�O�s� X�>&d�g�� =���u변��80]����I+С[�#��_SL��l�a�S!tD4��3K���fX�&��D�l���S>�?U ����(�2�.��{N��|ޥ[d?v�i�iv�h�i{�i.ASk/W�@ң,pB[D+�B�k�?�蔅�{&v!�`��/V�E&�xL�úҶ��#��`ɉ2���R�*V�.���8�[Z�AP1ߙ�~@�xV\�QX�M$LU�%��#�1��{x�>u���=P�,�������(E�H���P�H�l�bl�A+�Rti�d�W����-2����N^�� J�yd�m���H)�Q��Ӗ_E,�O5��=E�q�H���`���d�/���ν;Cc�@�T9�Yd��]�i}1�����V�'����H�J������Ȅ�H�GbL����!�K�݆��f:��0w�{{���c��vK�u��s}� ���jf�s�i��aR�m�;��P��x����^4,mڴPAmP��������Ҽs�wXN�|���1j��f��7#i��v�~]����e;@-���ǣN�޵���9�;�&'��i�$�o�QG���4Yи� ҄��7�m�j�|�f���ߖ,s�R/�t�G����p��S���4x��,0��W��g# �z1�|S^�?��L�w���$Nk)�5H�O�ĻY��B�m��u0wn;��E(Xo���(��V���7
I�zYN�	^�'�{����^K5���T�n����<�����>�>�-�����" ��G���­�>�����Hl*��S��p�XX������K�U�Ę��V��|�����)i&�z][���)�AP�|#���R�d��i��7a������|22��4}L�w���q��� �����sƦ�'��B:��jQ'zpV�����d������0'�P?�ܝ%wT��@��A01Ydk�ɜ�&w�a�=��-�*>CP}��~T�]�D��Zb��~�;@̼�oK̸��%��Y���}�	�a�[�g�����gvѬliv�10�=��r}dOf*�� ��1i?�̈?k�.8S;&	A;fK̞ i��+��f ������͉��g�    YZ