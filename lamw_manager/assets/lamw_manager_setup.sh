#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1808185758"
MD5="ebb38758c2a18e05fd4e8c2deea711b8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25024"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Thu Dec  9 01:02:06 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
�7zXZ  �ִF !   �X����a}] �}��1Dd]����P�t�D�!T�Y�pΞ�`ΘJc�ꪘ|0���:8���{�o%��x^�j:��ǔ�֦xKgV�Q��9�\ъ�$)o�<��+Q�c{�8��Y��$�|4��C��4 �<F�}P�DPE���u��:��b3O�(�)U��΁���v<�����y�t�� �G7<MI��I��N�x9���J��·������IY/�+��2ϑ!~(����A��}٢����$�V�әtP�8ֵ7�ک��ѩ?vZN�u��qx�i�uܽc~��X`�����@k�d�e����V����@�=�B+�/VXpw������^i�ף!�K��vB-�U������b�>)��<�5�>�����5�]�ӿ��{�*)Aް�2(ͤɥˬ��=�hw�|Wig�e7���6��Q�:��;�m�n�>gV5dހ����@�@�1K�S��5r����%ʭ�#_��W�Ѧ$���� SI��ʮO�I��]�\f�#��_���n���L�~� �� ��x�e�A��=2�s�q��a�	=�33�����X�[G����.yH�\U�hZr�ţ��A�:3������^�����,��&�azZ�Ϡ���3KV�J��Z�L��ԉ�J~�3�:s��Ӱ'���tM�T��/�M7dJ�L�]|qO�r���!��Ba���􄹗,B��Rssޗu�z]s҅:oR���� �-J��J���0���02�9�T�ݶ��dP�))���{��ʐf��w)���a�R% ʦ���#�-�A��P�\���u����'�=c`m!Ew��i`խE};���)M:7�QcၖF�Do��8��pYuZ��z�G����m�W���_��_�h�e�v��V�@����X��:��T+�ձ�j��r
T&�Ǡϥ*-�d)LJ�����m��!�Ѱs2.J��:��gG֩��_�V�R,i�l��H�!&搩ԑ�@��i����C6�2�/Zb=:T���J1ڣ��e��h�3��0n�mq4M	�Tr�5���TI̼Mί.}|�m烹��#��}jfR�[K>t���|�j��pc������e���/��7��]���@G8|m�;�t��'�ԧ׮�$�j��ۥ�.���̓���P�ê�>z����� g��Ď��q,*���E,"<Y=��+t=��ahJ�j�\l�Ϩdl�!#���2����F0e��^�ky3�w�텩��ڊ�M���^� ��`�DbԜ�:�^!�+��ob1ӗ2%d�
��(�խUe{�j�eQ?�_�gԠ�e����e�o{�8�4'��ŦX>z������iy����u9���Y����3��RE��t����Pb&�����N����Vj>=)�����_5ł6ڇ��г�u�rհ3���т��%鲚��p^��o����6���7���h�,�k��"�;��]l��E�U�"�M�����uo�Շ8Yrinl�]/����6�Ȓ:���,� ���e��K�7ư�8��{fθv�,�V����C������7�3|�s�@}�u�6�dw��+4�CR{�J��vE�HS.��<�)��$O����|�hJ�����g��[�q�>����D�	Κ�q]���0K	 iq���<r�SdJ��ҏ��;�X]2/�)8K�^��ct���ጜ6����:*��u�3�[z�?c=Z�{�H�g| ��:*q�7�D������c|o^䰌~���V1B��(H��wv�)�(�����#a 멶TWxh�p
h�$�������Y���m�8&��z���z21w�ȑt4��Z��YG����a�|`��ʤ$13���ϝ$��' R�.��W��|�����d�19u��@�T�a��qҞ��R��� �6������l�VKQ�1e;k��_�5\R��8����:��^�[c��bi1�X����V�El(��fHE�nW�BN��r+�>\74�+��T���	��߭�V�̫*���{M~�b�9�Q���!�2����^N�PiOƱ&mmCR�R6�F�cs�x !��z�+Qt)��w�@��}�z<��
��.S�q\XΤ�uLy2>�-���*uȤr>�a���":���ݍS(��Lq�fo6��%�Mf��q���(�dXP���	�g��X����cic���9���1"2D����҅u.Tv������ƽ��1���Ie�� P_Ro����Gߌ�L�pl�nJ[�ɾ�A7,aު� m�#�#R
+�y ~�HC�'i�)G0�3ji�%ݳ����c���[�.�u�X,lW"ǁ|pK*� ���'c�G��2��?�#��e�����\�(�J���Oٜ2��ǩ@�t�ѵ�k�ak��F�R���0����ŶMEg�^����	�R'�*��`Q������uAQA�oWHz
��P��Ew&&ză���O�����^=�P\,�n8=m����yſ��YZK���*|eg�)	S=�f)��:a�[�|����\S��f����1V�	�2_L����r\�����}��W$FG_����K�~g�*����YגtP*�h-2����zn���gQơ߆�I��_���6u]C�7��k����9�v��R�/3�M�g%�D����\�Ǆ�2&���*�Vx�� ���������I�m~r��~�3R"�ʆ��9 �q�?X=��]�|#��4S�)����hx�t����0S�~(�����Dz�kV�T������$*y	Ϡ��^P����#�β���!M~�]�#���j��:"V����E~yE"õ5�'�@��!��^+��@R��0C��y����;�+���
j���e52^�7���`�_��'�EG�����k	v�U%^�Ԯ�xoo0ھ ��6;=�d��xrC�X����Ag�f��8�Z4A$��n� �	��KEJ��"��$�!������6h��F�Y���x-�_�.BЇN�b�>ף�2f�Y�������i���G�V0�L�������x$~J0�l^�~���[�t�(�9�X�$Ț������Ǌ�7��Mo���~�Z��TG��.�M�������{�;C�?v��G� jC��l�n���L��T}��)\�^S�b����Å�������v֌=j�5���?{=I,�K�řY��M	6�e@-{e�U	+%��EZWZ���� Hg�V6�K�����#؎�<s�l�[WdZ�P,a�s�ߌ�R�}��RD�������X� U��Z�	���@0�f�;�]�7%��C}�i �s?4>8�lL#@�ɢ"iuc�+V憯B&��n�:U�'���!���y�V��(V�/�dܣ��Yg�@���ؾ��*|*�S�86�z���īT:�l��5�`��QŚTmO��p�n|����Cr�gA!�b̙����Wp��i+��:��~��{)�i�%e�}F���m�(ܧ6>dչXgg�c�t^��S��������ׄ�δ&NA�]�5�����E.�vk��𯞗l�F�M4<|~�h+d$�����V��᢬akU,
Jb���S~��[�ċ�������u��X�!�{B(�^���k�0��˚����sy�+숈C�
8]B�e��m��t �p��ZH%")���h�3]#&ѥ5vȶ��}���[�{ϡ(�58����So���JBU
�����ЊW"��޽��:3�qcOsd���H��_-���0�|[1xw���60((�������y���r�@{N	̋�v�2:�Z�f�!���K�Ϫ |�e��v�ɍ7�����3C���v�j�e~�3����㢊zs���sv�0jK�u���]�T��X��D�]u���$�`��-@��G�ɿ���U������7�6Y�C�ﰻH�i~��l�z/(��4�4��Te��t�*+�-s�.��o9�O+�]���U�,��,��6�1��u�N
�Y_ԑ�В��w��������6<��=����>��2g?�u6�c����]�4�KW�{�w�AP��NY|����� �)$�ʳ�k-���E��ѥ#b��`Xu���8}��|1����Jd�f����=�i��+mF�.x�-�J���赽�
16r�G4w�׶���Q��X$�SXY&�(W�E?6�u?��Y̞8���	T��:{�8�zU���fx� m�[�2��y��V3-c�yY��z�'}3��9�&��^���],kw[[s26�+�a.e���9H�N���]��{ɠ�h���z�5x!A��&o6c�³�jp�~��6���{<���4|������l��,7��*a۟�CoG�e�$ey~=��V��>�XfF�I�y��pT���˜!HT�����C>�ro�c(����H�|93iD����ļ8J@��`gaT7��ܑ�2V0Ў[�R!��x�sc�Sbyc�Ɉ��2�G��*�$j�dR��f7�3�N��޻,n�anm|uP�*C9���M�O4�S���y�����uA��W�9��p2��1��d� ��Je�M �0|a��j�dhdX� 7����{D1[��|�8X�\�n��O��D64�;_��z_}��D�L����\�� SX�D�9�L5�����
���TP҅A������C^��g1E���~����H|�Pr�Iȧ�ȧPu��P>W �9��i>�@rM�	�J���/��Uz�:��7?n���p�i�$�.QT��ˤ%נZBW�E={j3ɦ�@`��.8 &fu��'6���􊵨��0#|�|�(6���q$<NJkU�EP�t��]o	۹0S�����b���b��&�"��/�Q���1|�>}�X�+�zYs�m� �BK�W�����i�7/2��E"g�?���O���I��^�������2���}O?:�í��F��({��,5�s^ �g�I��Q<l@��$XLiH�f�7augÑ��gѿ�|��w_fD�֛MI�#X�&�Ѓ�O��;P��>�S�G��v=3!ë�\M �[C�fFDlA��LGlT��0.U�AI��� ���N�tT"?$���L9�A� r�j�}�<�Z�?2�y�[C�3�*����U.�w7��2.�{~'Ǝs+d��R����.�D�	��L�6m=��iv��L�:<�q�
s<3J�����;*����0�b9v��j�m�aAd)�%46&.���-�~��� �ʌ/i�Gܸh��k&�(����"��ܱD<���I~�}4+���m�˝v"��D�:��������T���[m���0�M����^��e��h_�5��Z�:�(ܠ�mzܳX�A�jc"
i�#A�w����{
!�y�<����H�C�M�
F!�a�EH�$]Q�M�g���.=�Z��973�$b����8�gT���=/�����J���;�#��?+�1����5��Sz�����Qu���#��0�Q�psL��jN��G|L�<��1J��)�2!��/{����+p9Fȟզ���|�rR~����q6X�'Q����(��>� |N>�.��kd�Gn-aq_Fɰ�ɺ�����E�1詥b�R�z����#��x8�B};���@�D��*�����)��Y��Rcv���ϝ��N�º`�A�?\����{ޚf7Blz��xX11���JL�A-T��;c�_w�(REa�wb�4�#LN�^`J1Ƴ%=��䯰���3��#�	�Y,6�r$���-�i!��QGO>�yZ��b���{���(�����u�x�z�p�nm��s7(�t�=�x�MnD-��^���r���S��S�1��m_i����9�m$&�
E�B��M�N�f�+��)X�T��P��Sh�K��L��՝Pޚ�װ/�)u���CyW6�L)�?�`�"�%��A%���L�Nd����5<�$�HQ	å<k�����s�Sz�����^:�xc��ږ�kl���l��YN1Rz�ۄ��?�#���UwH���wȩoz�R����Z	��cU��f�d� /Í<��CSEUBy��X�s���ң�R�ܘ�Ke2F4�
"��FA��I͹z���!�q2��A��*5�vE��+�'�?48Dä16?�0��ׂx5:�J�)*�X���~ ���g|�$���k��Ex.2�`��e�؉���c߄/�ߑ��3T[�l���Y6�7�ir��=c@���₌4�[�
�%G@�7,�'�~�Nx ?1K
{+�G-��v���8���;���;<�ܪD�[�P���g��Z��ڭU�B(K8[)��bY���@苦��r��WҰ�<H#)�3�ϋ�?�#�Lx�È2��n/��N���0���l&3� G;;���%(�Lt�o�dm�]��?�f.�N^Y�^V	��ΆV���%ʼ�Y2lp��tB�,�K�I��]d��d/�������S���� �����u�_�$vY�ߟB�.[���`�-1m����� �M$�QY��]O�v��a�Y_X��J7/������B���
$���+S,����v����u�ˁA�g��PM3õ4�v��l���CR�/V����3�ŧ�$��u[�~!�Lw��� H���Vs�=��&�/��p���#cs�<������`���x������3etW�6Jo��\^ᢜ�з��D��N�<K:�i6�2he��J�\��+f��g�����7�J�=O�%xŕ0	ͅ��0���̧= �0�a8���|!���:��}�脦4|���z�2^u��.cTZqz�B���q�"�e�����E�&��zj�r��\�1O��%��͜H���o׊H)7�����;�fd����TT�#�)��ʨ58�����
՚RQ�k��I���K~
��O�`H��~$92�fN�B̜�u��:`�3l���I*|w�mGw��^G
"�m�	�����Pb"������׌����*�k�`�Y^�?�_�{om]��/�F� ��M�̨������J����D5%�b�&��c-����IRe���b��[��]G�5�Q5�J��Fs��=A�O��e
W��F�{�\�B;f�]��.�2R�i���y�~�J
��{�]1�d�������c�̓��O'q�j4�����95� B_���s	���K�%͇���)�OU5��[�Á�d���g3}c�Xs����/<(<�r��7�c����r�`�!��d0c�J%���mۂMj[n���H[R �>~Ɂ��!�>��>?&q�42�<�:?��B���Ⱥ�F�4P��0K��9Q�\]��R�pH.=CW��it��ã��o��4D=������[����t�'E4ʳ��rV �WT�m��~@�wt,��DGC&� �m�T}����X��c¡�k��`5Ӿ=mr��c3����x��I)xL�/5v����g1�+�Q��k_âyRl֪� P��'�������]��=�����EѿG��M�� L~�k\��0e��1 wv!��PGz�!XQ�Uk���~������QN��+^c�`s�.r����L�Y������ [�˱]Ew�_�qh�Ja�K�SZ�,���H�Y�ο�d�&�N~�U]
ǰ���4��;�ā�N�D�]�3�Yǡ���r@��aS�4,�#3��5Y�>CϠ�"�]G�6�D�c5=$�^��F����#,�^��%��	 �6&.X�tV��m�Z'���Q�=�ٲhWC��O��G��ɟ�M��#d�lE����1�l�ڿ$����<��J�n��q��@: M��u��:?��-�=�N�S�v֋XO��`�cw��J�������G^s9�f���Ym[�)Dg=�Ֆ<�!����<X�b�\���#� ���e�
I����)�o��R|�'6+9���:G[E4�LJ$��?5� ����������4��[���$�6�����6��Ҝ.'��A-I}[�-^��D����sQ�*J����4�]�@ad`1��	ͮ�&6�I8��?�S+�ܨ�4j������ezd������"z�h[�e�M,/��a����.c�IY-��D�D�@�Q�_�^�ה( Jџ̫Ą����Ə��CM[����4-��Mw�L��~i�/���)��8�c:)�H:ރ��<����Zx+a�ɂ���X��AGͯ$����M��3�B8#�D��B`�����B��v�R*A�nMn�աVhq�T��tۄ%k1]}��)�[���N�K�x�1�������*M�(�3f�z�;ʼqJ������R��E_i1鹥�!�%�caROЂ�7�P5<��^�'��a���հ����.�*���A���S��2^��wv�bWUZ�)'��1�H�=�l7�5.t��)[�h�F�Q������m�σ�8��l/nG�b��%G��w"���Q��A�N�XVΐj�N�Ko(fM���現�*ad�X��Kԉv=��Rq@�JYc�KF	��k�� ��C�a��+��1��_��\s�c}����&������Σ$ۣ7۠�Tw+mA͊caR�tojF��DlEwE��-E��5kA)<4�|s;���]|U��uن�3��ĽR����lS�+L����f^8F�Hz^I����:�7a��u�ܑdL'S�2D��r7c�� �E�=��8�S*�����7"�a�O����Q��Џ��m#�5B�|S ��澌߬�͆� �5�]�#_�����\�c�u�Q](�U�x[<��*���Gj�8^���9���L.C$��U8]��f�=L����ϖK'lDx���[f��!�?�(�a�q��s����k�8/r&:�J�J_�(�v5������� �œ����*���Lwi�#�)K���C-��qv۔��&�9=<���Jq��NN3w��>����{@��#�u".+�!�*���M���7}�����g���#a�>������r��K�^ٍvƵk�ʌ��3� �P�aI�<[�e	a�5*����;���˱i�}����<�������E����2?��77bZ��i)����7�\R.#Ľ�<��#R�c���.R4�� qE�L��2|}þ��^+Iw:i���ׂWh��( e�^O�w����sp�ʀ��������GC����Z'�8T�>q񣏹�����K�~	Q��qZ:~J<����?��yW�_!$��( P�:E�f؟�"b:�Q�z��Rz�$d��"��>��2��]��58,�z~�lg�������0aԖ@.>�S�*=@�`[�!�(_��Y�קa*�|����O�R�we��ݵz�n@Eq��J<)]a���!�&��~�6�4�o��k)��~O����(��d:DL�r-l#��R�dB���L ݗa�]k�lV��b?O��A���`�w����Y\��5>��BR �L��*X^�>+,�VO�_{0�	� �&����sy~�*K���3%8�)ce=��t�Й������L�Kē�V޷w�n�z怟:�̏Ӳ��"���()x{/T2��he�ˏ_��T�nqgD6۳����w؞S����á	�u���Rȅ�:�i�]����)nr���($��1m$t���[���W������LLx"��]�<;�j
�/�����*W=���ܪ�1J:z:���mR���D�������;
��>�j�J�c�k��A���'��3"v�C�-ҬkRpj(/��n��9L�8\8��^�$��>lp[�ב�
��k�%Ӈ4�KH9��qh�jp@��ڕ���P!�]�j��t�����i��q��D�ߔ5ʊ �ML�yoM�NF��͓�<�����d��C�L�ﶓ��x(^n��w��0��B��S�U� �D�($��b�^��t�*����8� rϫ�޹I��lбuy��^�;%����������:Ttx���3@�������n����z<��j&�^<)8q��-:���d����4��M����$����/�����هT�Ĕ�(��%���lַh�+-�h�P5�%���5V4;�.���=H�i��Ӻ-�7���=O��f��(���shE����@>M\���H#8H=?@��'y��D�H��)8`Sw3�s�it��ބ�a�5��i�و�Ո�8�$�O	��ƉD��=;?�:�K��\K#��-smex��',[`�#� |Էg��z�J�`a%��e�Oi��!mI/ࡲʗ���0b�O�"���/�wM�� ҂ǥ�vjp�cU�l+'��H�08�N5���u�a[��\��ڞ�*�9��
p��Y]��]q��|�+����9�Z���'��'����s
r���^�]<A�n�LM;�,>b��բ8����Ab��ǹ dNڼD���5���>�EX/NV������Ô�:�,��D���|�+ �|K��[��3�A���-���8�=�����w��׊ϑy
��B�G��I�	%���B���ٸȔwDY�ʺA �Ԁ�1ⅶ�~�r��`������E��H�~pt�+0. G�6�#FR@���P�Q����"�*!~�8���E��痌L�i;��[e�����ЮC.h�"��
��Q�_k5zP����p˒~�u�E'|J���
V��F�?��s �9Pё��"C8����m|�=-�[���j��iZB�(�������ང�Db�11�&�y ��,)��'s%�ly���4#��;aCg�8%����&�=�7t�J�c<�Χ� �����?5ĉ^�4ɂ�:cl��i-�-f�I��Ҟ�� ��&��=����5~h���bd��c�؉*��6���Ls�`i0聯g���F`�T��В�)v�#n�%�F2��8�SWNe�e�����o�G=�I��P����v+�(�����Ð��v�>��!�<dR2�D�_7�;�$WQ�\�Oik�z06��9��pGl���#���ٖ�M�b^�OI6�B-�d���bÿ��lX��wJ��+�%>����W_j'2���~]b���uZ��Ǣ�ؾ;}��P�__�R3�$����������aokT�Xܚ���	��u��e-*F�0L��2<���v�k���$���M�si��Z�q(����I�/./�&WB�4z�h�DDI�DI#Vo=QS��[w%4�NN�x��ñ���p!xuz�����n�
&>�~/S.�
��P��=Wu����ɔ����[n������g^��������4���!:<�YVB	]C�uHH�ouh�q
�qü��4fʴ"6)���� �n	�0d�$h;�avߝx��� ��ix�F�1�d�C���h.`w�����݃B1�ˣ�&0,������pt�j�sRH��j��;tQ�ys�`�hz�LD����-�r����l�<���IH}��������v��̫dn�A�=�v��|EH:'���!�^V�u�����*��Q�i�9̀$
�;�-'�CX������;$C���A#���+G��R�:B{��w����Ca�t�A��`Ƀ��PQ�n��dY��QW�|�-N��8�/�C��"���bqqZ
	(��S+mO�w���d���/o�����?�y��h�G~�#�َd��gpɧ�he.�8�&n$	���3C��� 5�V(A5�'���Tϊ� �<H쥈�t$C����Ю��Ȅ�25	��y6�v���Üy\���-i� �)6�V0��������jN�P��ΰ\�+H��L;7 ��6�&:�C���0�d��-�=r&�2:�m��pK�G�I����//�\��1�
:�.�����n0���o�n�2Տ� ��鑹{�����ҭꡭv�~���&�d���fc��'!j���zW����
�d�'F��D���13�R�Iι��!�1l�;����gI@�)�Yh&�FU\Cw��a��w�S�}
��T��~����9��*���%_|�A�����T0�#/�j��!��K�>�����z��wU�����*����]��?�*^s�쨞3&�x ���-����`��*P"HE���0�*c�^�4��� �����%�;|:�i#OA:�&�Y��m��ر���w	-5�	�0G6�-H��i�c�!��c<�����{@�����D�45�g�
!߷1�4X�fUA���v=(@;�����,��m�9��w"��Ϸ�5�߮��(��XY�o����R�նI�	��О����w��:�꽆�v�s�Dp�q��
�V�x��j��p��$�� ����`���̢;Ne9���sEt'qhT�'򓥌�_�������̭w$gPJ����_�>T~���	��#�8/��TPrCYF��w�ָZq�`/���Ȧ���0;��*�4��4ƚq�K&��p�����s��#�A�N$�Y�;0���Ѓ��x�LynE�dNo�Nا��$±�����lN���v��c�#�pB�Ql���yQxT�)0y,�^kN��}�������ɖ���Wg����&N��	�wS��OL����/����K?��e����x�*nۗh	דJ����;2���:�L7���"?���H��j��:�:��[�f̑�N~�vd����.2��?����f�Y���e��=)�暳�=@��������:ٜ�R�른µ�Ϲʭ
W�"-�-!&fS,<]]��>��l�78��{�oo�Q�Pڂ������_��u�{�ߘ����@��/Y�E�u�L�ҩ0�k��{�
u�W�3i�/��+���cs@@��9{u!���P�b���t��ov+�Aa�-��%X��tP#Hϖ�)'Lˤ��p@��ͣ��_���.4!4zMDD�k[D�P6`�,�h�� �Qv��cF�e�:$P�*+��C�PX��4��ڽ&�H7�5#�.�B����-��9�;>�Y���8�I��|lꆽ�f��/�����N �sR�W�JQ&fz���t���͖ꈳ���ۇ�2���jZ�����]BL;�η]�y�x�ܒ#1G�-� G"3
n�M�5V8d�� ��}����{���D��Qp�,�hH�W���&�t�dǫ��a1'�Ц$:�Z��\	K���fA�5��l����v�$|D-�	���(s�>:�S��dtp}�>s�a.F8�ѩn�x�J?d�o�*��^:+lU
zd%����ݫ��0�u�(�#T" &ɣ����1���)&M$�'�A`n�B��r�&��?�D-,7�]�3ma.J?���PK�C��Sʰ��w<��c`��.Ŗ�y{	��_k�k"u�w'�WU?)^AG�"π������=Z�E^H%W\8!�W.
��lZ�2��E�(�|j�f�(�VYWj�Vd��|n�*�&�V��W02�JT���C*]`W��-���Y-�V���$���Z���T��Nb��05�'Ʈ���+l��ɡN�P�.����,�@٠L�ÚVi�_Vs=�}QT��Y�)W��;F��3�� ���[#��"C\������˱�Q���>�>D�	�B>�&�M�xߒz�"�vk-�3��J�K���.WK<9�K}OxND�:�ѳ�C��yɠ�?�O����QQ<~�[���E�Z��t�R�%�K��>� ��ľ�1��CX���\TꞘ�G|�P��ſ���@N�����	l`�f%PSn��#���nB��X��ů����L-�f�:'񧉋#����;0K�ԁ-.������[�ז���Pc��=��D��z�����Ӊ)[��7i�~�b���}U]�,w5��������x"�,}�}�<�?��D�aߝ���&)��������E� s��b����Y 0�LqԊ��q:h�#�¦� L���OsO`u�	{no Wl*�`�RzA�ݰf.X�t���L��ܴ�����%�^i����M ��Pr,+)
���'I�o�j`������=�0!�;�z��^p�V}�Eܣ�t�]�kC�����Cb�F�#m���6�q3����[q#�P������*_h8kB�HN06}$��� 1�����ѷO܇r.�6���T������D9���G�ǿLos���ܲ0#��V���l��B��M��s��~�ϸ�4D��D!���!gx�`�	퍸�	�L{���ZV�9	g�&P�$�T�-Y|t���0�0A[����l����_6�v�A��T1h�a�\��'y7�k6���mo޼��g������.	Ų߼$���V�3�0[�'��r}a,�d�43�s>+�� �c��JF�R��ڑwX��j�ZI<�1[yR����W��]"΄r�X`kWz������qT�	�q@�o�L.��K8�;�^�Y�Q!�6x���Õ�%{�rY�gM`
�L��J��-s��gã9�b��֨޴x�����+O�!�X&Lv���]�U������B|t�ӹ��E=�>��a�ա��gL��F1�]�MR�6mR /7妘aX�'bߴ<o�̔x����ݐ�����ff��a~@���p��� ��t<�skwJ�i1�.5��j4����zEx����PW}�(,TB4��A?P'R;:���������+aTX�����p�Hޖ�%>�' �����6��f� �]��v����eG&���I�8��8e�p�:��Y���B�� 3��o:E��0��!�4��M�I���x�YS��f'�	�0\}��(KB�;�R�@z�.�k�����u���8�h�Ή�9䖡$��P|p��#`��h��G���m��g� z`'xB���Yx��a���Z$k�
�g Jt�ϛz���he����q���゘�'}�ʑ�WT8�ă��W`B���^���~���f��>T�dAD���|��@�d<x���#!�w����+�"JW�ɷ�<��L�#�x{�nhj�n}]��V;�/��#���ύ�Ve���O�$����b��U��j��hS{"[&R�(��a�I����e���E�e�[g	��j�P��3��Q���
��|NA�; p�z�=V���Y��a�+��B��ֲ�q�4���O��t=�~��"2�P���'�:p��	S�,q�_�E˓�e]������a嵗:� �����B`�3���4m]�v�RI��HV�ƽT� 0m���ǻA0�҈o�
��!�6�fm*��p�(Kdav�m�Þ�4���l��c\%��x��`��;	d���L\�pq5<T��|���%[�C\�{u<Yo
}��U��G�7�q}$�4#��r|�6��c��-����1�<F!Al�B�;�q!�	L�5x`D�M���r�t�w���ű��:�7g���n�,`̗vBF�E����]�rn �P)��Q��¿Uyg5��܏f���TR��
}��)]�>0m��(�x]BU��z~	j*�/��}u��S���־�
�I�B���W�'{)etgU��lJ�^Y��-�B'[W$nk����~���W�=�F��7Y^L������
�:����Cw��`_t)�ܑ���\�fz�g�C \2.>��|`Ao$�$�b�-U�^��qU����t($!��oKg�/��%�P�&0�q���~��+��K�sn�[�j�	[9G)V"��_��l&���z����c�s�J�+�������n����J���aj7�b��;[׋8�_��s��/H?R9�H�~D|=��>���F�.vyG�_X[P��ո�*����4wؚ�LӲq�4�l�!��*���&tr��s2��F���ґ:�}Z0a��f�8q}ۚ��֫a-�G���LFJ��ɨ��2
��"���_0Cj�)�)���ʹ�ުZ���M�.fF3���7�{.�+X#�"B��^m�����ܻ�z �MN�_|�n��:�A��@�6!�K����A�0s�P�^�]�B�X�-,2��{)_�{�������X;�!*�́'��oO9p��������N�"� 	�t�[�Dd���p'0Y^��e��������\�����xO�F6�&�dQ0o��wbЋ/�Q3��^E���J�y���(�~+�: �������+�j�����
jjD6(��81�H����Lr������r1g8��'�"}*���/VR�Tp��#Ѻr��uƑ���X��
{�T@�=�H[ށۼ?1;H��G��'4��P��5�^G�$J��<	��?�:t���~uu�
������SL��y��n�g ̭��t�C�D1�3;��4����������nxϝHQV��3j��ϐ6���M��Л͒
;X?��<cʯdxfb臔����V�!�O(||﫣������i� 1/R�m�f��)DQ���e�TKG!s�ݝ�8A>�t�i�7O��?^xj[Ԫ��i�%1I��oz��J˽A�[}�S�����߱��hRog��}i�l�+F2AӠ7�\���֟�߈�G����)ڜ�%}��ڑ�U �**SH�80��^[^���^d������
�)�a+w������wX�� 8f�"޶���|&��,[Z��x���J>� �.�S�Q�s5Dgk��nBT�H3��f�A~٪�g�9�#��@�E��Q����׿ @�j���wu�
�����\�	Vö��"�{.<@�5��l�2uz;��b�4@D6u��}
2i�?�m|ߟO�B���XaQ>�b)e�cB����8�����25��~4���Lc��}Wb�p�7��S��f���V��f7����"�3dN�5���<	���c�v�R��e��9�)��L�ʮ�p6���+�o�	��jZKü�M`-`*TS�
@�ض���7��@�sH{]����a~�D<�Rt,��N�$'��5�+�� ��i��D:P�+ixnl9��x�]��B��s��A���{h��]M�y�iip�sM�:t�G�]�
>ط22������>נ���Jᘹ,��������
 e����#����,V��$2SD7�õ�\�kQ�D���.�@1�� �\�%�Q���c�K[���9��0O� H�&���:J_;����~��k�0H���~�[Fkʏs<��f`���q�+��R�
���b9�&���դ�a��� {.?DuN���y`{�9[LXa�(��E5%V�_M�SŕK��\
������U0�����R�В����G%�O���,kd�����㊂�i�Y�G���y�Ա��q^ޙ�ڻ7�/�:�il�Q��Ǎ��/�J0�@ǌ����!z�A�t,S,�~�r���eO�2��q���Jw^�x���l="^�ɝ=|_Y��
4��Άŝ���S��]���_�t���5�V횋���K����� ��-~,��m�;�Gî^$��=Cd����^�U�����S�V�t����K5� ����=`ve���ue��I��x��aawT/���d?³���q�՟""zr��y��m����J�V���.ɯ8������ć"�z�.�I>�A�I�8y�}���D �׫�jߕ��n�C�,��P�	�S����ٞ�����4䐸p&�JJ�x�E�!ƽ-^@-1�9��x��@ +�f���T�b3���Y����}j��`1}����<�s�B/I�D�d0`�ʻo��S	>��4�lP���G`R���{0�bh|������ 2Zi�� ��$�=��ʛ"Y�y�=3�g�ݖ��ZǤi�t��e/�]�AR��1;����ZsfZ���SXc޻�O��X�S��ˊ���=��u|�+y�q��_�bЛ.ǂ���]�J^i���'�\i<�	�yn�!��k���dZ@��%eݕ�[QU��FL�al����q�AP��0������
�MN2���潛0N)Gebw~�Vp0@&�㿁kAU�~-4��/"���G�����[�(~>@������˻F�{�5���>��:֦N�!�ɩ���)��@��A��y�][�P`�'�B�B����������;�dU��e�,n�Gt&P�z����ى%�Umr��&�q:�k5&�: �Z�!���G�sǺ#�ߜ�yOn2��ZH��郉���,pf]e���')�ߛ,X���X����Cc82 ���3XQc˚\�����$��Z��neN}��:'�s�Sf�$�Ù6MZZ�M�]~�ňW�3L���M�[� 9��������8�v� �z
����F4�� �-�x�sE-���ۨ����ӓʪN���hL�Cic����Tc������@Cl;��N�kϐ�۳+{T*Bn��xq�T)�S�r����#D��k#�$�q��0bޫ��֢urr���0��1��|l�]B�UR�/B(Z��s��>F�Ө�Y���j�ި_U�������m�7�	]G[vڐ�jj��9�����O|��]��ҺCb��
+x�/�ڧ��bMQ��A�f��Iw���zk�Cxསvv�x��L➥�����c//Q���%Z�~��o^�  g��oy���0�cc�h�x�7� �����V��r�H��L��h��&��;yvZ��(��U�"S�z��-��,��k�6cJ`������1�x&ĩ`��/�"�+��S��a���ج6�?�  ������f�x�~��s�E.Dv��} � �=����@|Ĝ��t�	f��2�DI'.|����:��>ީ8Oyy-S��o01�L�!Ж,rw��ʮc�鬖�D9�ƨ�&���V/'EW�&���P�^��p�K�U���o�EZ �������M��q|���ec����{��Jݳ�X���a3N[o��+	�6V�yGD�N+M�6������c�$�N���h�f���X@�b	�ײp敼5h��P���<+XF�$��Ie-O�k4�Y��8,x�`]
ط�M�E^�*v��[�kK�}�eT8���c0i��.�Fd�~���s^�nh�	��[5}o&��y�JH�eO��G����.�N	nQXgJ���HP��`�,/��m?
vt#G�#�ʊy؀ �_?�(�wA��ڥ�1��,�l8�:Q�%��9eF�6��'��>��X��-�Y�~�(��%��"����u�R�P��L��|{�߰�|�bJ <�������WĈ{R�0�;�G�ՠ�w0U�|�,QNAPpP�c�	��~������1<{�K�^H@K� ��e��:פ�� �p�؏�y����p]��;�~w)��p_w�j��+�0J��U�t8�Nt|�|h8Dl���+E�AY�}����λGx?�IW�!>Hw.إ��^��}@��\D̪�?7ԫ��Kk�%���RvK�C�7=�.����)�����o/�|o��=�߷$�����S֔:�P�Iq�\�YΉ%�;�u��,���g|}�K��;z�� Ja�|�$��z�i�q��}@�CG.���r�wלa;7"�#w�u`�-�q�^���y
�k��_�A���a�~�o��xo���`8��2������"�)��Ϟ�C��y&����.��ȥOz�R��cb���	���b��笱x�ۂ}ԙxZu��D�6�כ�48M[p�gq��t�xt�"���An�Vc.}�gX�{ y�KpҬ��]j���i���و�#��9��5 +�N.��;�6��X�u����}fnZތ�P�죵?v�h��td`K)�r���+�J�BN]R��>,ma�*"r��Y��:$�&��,�D�µv�����4V6�=��1��D�qc�=��'�D����5��3d��>|������]���0q�ܟwz�\��c!kN�/u4u��Z��YP����(�l^B[�u��f�����)��ę�dv3�1z`�8S�R4Fl�P���-��[�e��ș�{�d�ON���O�\��va��aH�#T���zp
�/�6�V�O��HI�yh����[��h4R�ްϊ�4�n��_�;�k�r �B�k���2Jyxc����3�����q�L�l���8���ݱN�������Vs.�!uŞ��3?�?�:�y)��X��1<�.��(��V�pN�H{9����J��ZJ��c�K��Q0
����a�A����!�������Z�D�+IG�G�Mdj�1qf$��%l.���l���D�f����uji�ƶR#�
��53��G}m����אlfQs>v�����0�D�����>�-��k!�<�_�h����_�
�5�extR�A> o��u��#W�T#�� ̂	�86LMSw�����2J������J� ����&ޚ��q���qք�a�W(;ƘE�\s���t��$��.��ۛ�$m2%�Ki�)</�8B�GZ �g�4\�=�
\��JW��q�&[i�6�~��*�WZ�Ч�B!$MZv.q%ҵ&�t6R ����.�7�g�q2��G��=%}�\^�J ^��n��O�z���5~�y��u �)�!Nw��D=���z��d�M�!��gvc���3��΋�9%͡�9�T��%�)v4
$I���Zt��Ư�+��Z�MwԂ[�pَ���+p�
j���{�4�Sȫ�r;�s���T��z����NMV�ZD+����a�yZG�+���N��3�?��P:B�s_��e�E�r�=�G��i���E��ሂ��m:5^q�W���:�a�F��KAHQDkaD������u[� ����2+�/{^Oq4�eR��\��1PU����yv
�����"������9)��?��	D�@~�~�P�"i��_*[���Wk�g٣�S�c(�#���!�Bqۙ�(l���
�j�l�d�*��kp��/5g�>B�b�Ҿc��$�t ��=�m��Ų��"�/�\�q��+<���#L1te}`J*{�V7��*�_5T��>��v?��xVd�^�����T��xј@=���8�W�:3�W�";�5�]5����J/12�Hܑ����'8F �m�:oy
Iv��%O�4E�i�]�/Eǖ��'�OC��c���#���aA/S,Se�A�)w6�K0̹��3�(Gq7�����X�+�*��G:'m��w�f}>|+��`�O����p�������O�?�u�݄�jU�)q� Pe!7��'9Cj.�rVr=���4���e aD��l�ۋ����D����l���M}�c�4}Y�y�0�9i�M���L!�>�)�Oy'W <e�/T���_��Az��}!����[ˬ��<yMĥ|�f����\`Oocj/gv_��,r�n�����h���k�*�!=$��-�
*����Ew�)�?\C�Dk�L�<đꐿ�/���C����2��Q@Ƴ��N�}i�^1�Ќ<o���WӉ�QE�5�l�A�0����b�ۄ�dco�I6 ��k���I�H�2��}L�c�zE��2H��z&f~�7MF�z�I����苫��o�%���[9ɒ��M�����Q�$�RfѢ�8�>�a��6_p�a����@{���a�u���ǈ�=6�����g��z	M��էW�I��L`�x�m�¼
	�%��c�����]S޲�
����\ΥK��}y��j����f���^s�.'���t�b6Wձ�#���Ϲ��W=��qdG���j�:���|z,ƫ�#dq�vl�E�.?�I�9;Q�Վ�'��m'���,��xS�E4�pɲ�^�D����嬠F��Ȑg������mr�@�$�j}����	�`�>�M��z'�~0u;���Z}�qF�.fD��Jj)��o�.C(M��̌:��\�A�{�����ۃ8��wE�qfGbs���<2 o8��F���B+�ά��)���|�#{��Gτ�o*�����W����`��d�=�R��}j1=��ͅ�@��?s���B4Ul�
4�+9>7���X�������畨-?���C�/�X���EZxw��G�aWXW�ky���O.�K�:B`�y����ueo��#yW�����i$l0��8v� 
:���2}WoJ2�[`j�n�J�s`_Q�J9�������zÙ7M��]xe�u8a$�N�5��{8�/����q��S�/ǱNu��"~QSr\�+�-�:W�� -�d� ��К�b�(�l��K�f���E�V�D��]��co�G{��������B3�>�A�@�ė�s��4�gY���!��@ʽi9,eNA���'�Rr�CP�0֛Tb�e�K	���_Ι� q;��q�Қ�L��iٲ2.BJ�B;_>d`�/j�������P(��.i�RXz�0�)5�W��a��'�0��'�41]�ϵD�A�1�0ZJNpq��!(�����O����;�5zؗ?�������[�QT`\��n~���ҸpΡ��;u�R~3�	f�i�L��� @tZª� �O�#������@_q��ŷI��򰼄��d��R;�c�gj�.4��y��)��\Q�o�7��P��toZ���(���x�l��eX �\qҭ~9�S v������n(�/�i�h�%먌j�X��Z�cX��%��$�2���v�>3{���[hͶ�ixz�ӻ8e�_�|�6J�:���a������qt�!���W�����:��
WMa���V�{�"�v>!$d1��D����T�rb����ɐ��F�}u�����4_�	�P����=]�2���;�j=�� ��q-b��ΰL�����$&�\����_Z�+��F{5�l�Gb�pJx��ٜi�^�"�؝�,�p5�{���@�t��
�-��+\��$qr�%:����V���S�����4ʲ�{ʊ⓳�F}�)p~�nI��{�Sa�����&I�U5�B����&3�T�i�u�؋�@��v�����[��tW
�����t&��|G�0��AK���}U�Tn�ZO�	cd�	���Gܓ7�!I!�*�<~_�խ�G�gʦ����i_�SE�����g���7��nJ������mi��D7i�:���=��f:*w���PS��j��Y�#��:���<��l�� �(;�]�ә;g��4��i]�bw~r���z$�7r���Itb���69���N�S�=FK�`m�`�
H���ack/��� ��r�6<\��:{;�)T����7��E�B����>#��Z e�L)1+;��LH�2�^ʍ�u`��cX��n�%�k�ʷ�hP�MzH�l6'�46�DNc>�i��Uƞz��ظ�6�i	�P^�{6��f�e2��!t�[5̴������}ק�2b[7��@��|a)����j�y~�e�z��tj0��P���(��x����Bؿ׆�)�ؚK���!�^P��L���`&�KE}��t�=Z�ca|��̼Z�FöI��Y�$���s��>���i�|+�-^�K<�͆���(�ăc^�����c�~Ѓ̔��s�׶����˩���� ���p�b���Pp�#�r��_8���^��D��pz�1��Y�`s�$��iF蒗�C�
��K�XL�L lTʈ��]#HCu�g�+�XtsG��K�fZ�7\��0	����� �<5q�$"c������8�f"��5����tw�;�tU�ք�'>yŔhǂ�L�J`�$���X�3�Hc~���^mRyKs�4G֌� X�ǫ��?���Yظ����K���1v��$;��79�]���W,��0 ��Z��Q��w�C\�G����|U��lfOH���%<m)�d�ʊ�Ո�+��V@�B=�_#��r�Q{��������<Z��a`�'0V+'�}��{W0�1٤��!�4�-�@B���;�N� ��s�.����=�����R�4��9�?�?����J�vLܓ��G���+�@�@�*�')Vk,%�� *�ӄ������:w��~��]`��p�8�?��3h��0��[P���s���5�:�S 5���BF�jy�g�jG�x�3БZ\?��D��Ѥ󠪒U��Eס'tXƣ��M�8���)�^��2��[��K��j{i��M���s{�/��m�/B�׋>,z��Q�1x)�>mIL1e!C�[��\����>�R��q�	��c(j���G��'��]�\�z$['�<��TS�P���a6]�a��$!D֣ؖ��4&0�ҵ��j@�u�Gգ�� ES�+
�+�0��AJo�PC4&��o�_�"y\9�_�s���_ġ��}�H��V�1�j��S	S�!K���	-jB	/~�_�4�����c�q��BҌ�W]��|��+�K{�*�#�
�<wsY�Y:a\������A!��+A㧮���+�n�e����o�Xp���Qf�*��C�wZ�*Gl��
��S�\T�T�Z
���D�A	�.l�Ӯ2@�ϟt�r��      ٣0ꏹ ����U?�[��g�    YZ