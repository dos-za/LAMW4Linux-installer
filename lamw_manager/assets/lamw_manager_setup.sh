#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="474319272"
MD5="0c50bc114f19b517b4aa3db668c6487a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26572"
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
	echo Date of packaging: Fri Feb 18 03:31:26 -03 2022
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D�������q�6JR%�����?��jJ�Q���x!�7��X�B.M>I�># Ђ��[�(A�=[${݈�vТ9��tA��쇇 x]85Ђ]=
����~�/XW��ݜ6~ʓ�W��䘓�PFD8�+DN�1��;��T	�gf�R�hH�Eߪi;KG���@������=����:\��1��Gdj:�S�OAm)���V���45C��"jª� l�ϔM��<�S���կF�n����L(��=�;(�t�������bp�h�2�����Q���G&��g'D<>mE��^�7�E8ڮ�L�9_+�L��>��\��]�ā�3+�k������}�� (����L;̦��*Y-5�W}��ҬO��Yk_��nF(��!R�>aTչ��dX�B�A�3%St�uj'}���</
:���oY�Z��S]�"� ���l�����OmA+�쇠����w�)�?:4�p3|�Bf�i�˙X�5�!+K�u'������>ٯb�!p'}Pvˢl�.��q��ty���N�Yiz��:Q�W�!5><W�8OڻϗoǢg�aP:̑(ɓ>���6��r�5T�Y�;ٺ"e}t^�:3�[[�x�U:� �ō��fpd ��/��;���ҥ���;�ZC\��]C�/yJ�+���ם2�j�Ү�������4|���M'��K�fv��,���aSg3�XU�nN�f�uO)�Q�j�&�@��h��<I�$���4�ѱK�O"�ט�˵;�Ӷ]e��->��	��� ����W�8j9������b��H�8n��2�e0���vY�*�𹿑&����;Fgz9ˠJ���d[�yEH*�je��]���-�Ǯ[Z�����yׯT&� -Ie2�ʽ튔,0s`��/���y�v9����&8� �0G34�|��H�J�*��ھ�+fxRn������^)�=�����a�?F���*(/B�fZ�(mve]��^��q%�-'����B�Կ�xsS�\9"�����EW���!����#b����断��;��d���ӛ��� d��3]m����GC�{�5�B����7�N��,�P�θ����w����X��P�̑p��N+����/f���4����ћU�#�(S̀��l��*L�_,4H.¹Q)�O݇�"���bȅ���l�x�d���%��N�C�l�13L.��	w�QiP��|�����t��}�;7��D���Q
@�]�J�A\�1��Ndn�U\�^�o~��PHMo
���a��� ��X�D�M^�Z ���������?����D7g�CF9������YȎN"���9�D
� ���G��M�mCK%�����Ɍ{*P|,�!����W��܃�*����X�Y<�P-_�eɤo���v�PK�������{t8�� [/7j8C%�V�i��b<g��f��q4U-u�P��ƿ�,�!�����kTk���I�����3糴�m�
�bP7�;�T���Z���R�<��������f�g)�T�f��Jf/|>8���`2e&�8�ѩ��:�Q~�"�mWe* #�����9.�q+�f�MN�yH����I�kH"A������AXF�Q_~8W� ��Y�I"������DG� ���C{��i�b����_|$��*STK!�[R2���e2`���:+xi�V��n�m-Q�D�;f�&���_��7z��6��渷��u��5a�V���k9�+V�����:M��;��A����uG��$�d� O��F�xV�-������Z�#%j��fC��DP�x���K�y�k��{W7�Kou���{��9H�y
}��=)frPK�J@��>��Ȋ��g�Gs��,�&�g�{�$�6�H<� �2�E.x�E�9���YK�t���
x�i@�.Ӗ����'��/��+j�È+o��!��D�5rxu!�����6Ϡ"lKrvM�����e>�K�ݯ�_�#�Ol�}YJ�]�i6@Y���#��M�/<*s-������H���V<�������8���]�=�����%������LЎ��M�Ax�qF׉X��.�PB�5| \���\�� T04j�N���/���h]���.JՋ	�?Ƨo��/��U��ly�䰄S��)�c�L}�������ZW��Q�h.z�f`����vr���������ߣ�}���6���A�����m�6������Uը�@��5[B�Qb:�=D!�+�,TR +��:�Ɍ�|�̫�Ԙ��a
��9���o��7�����]:[�z��q�##��u�;c���%�ϿmQ�t��m}�7����!=ya(�%Ij����^&&$��&#�\��X�^ːI|"lw?ju���j�O�	�XXV�'�b*m�  ��I�G
p%�ٿ�6�'6)��}%ϩ3���d1��[���^!��6�p�D?�	^����hٌ��
�m~���ĩu�����XsR�y���8��'C����a3�+�_ޯ�Iɓ�~���z�b~�G�EsXgc`,U���]b����y��K�f���ds�9�O�T��"�Jx��o���;Vhj�/�3V'2f��w�d����6Q4�Y� 6�x�LAUܟJG�c�I�A���w�ߊ/y�ňL���;��B�9�䠟�n��m=�w9�h��igx�������[���`S��J�yO�]�OKu�|�/(�_R�=�1@6����v��g�aH�Pv��,��q��<4�P��ا����&W�i�8иy��2��R��&M�
�T���뜿|:Y�z�2+Jw�J݆���81�����MU�}0�5�p�cZ��I�5�k��6b<U�}��D]���X��o�0��	� �k�ŭn6դ���S梡���
�bJ}m�Ok��ӽx�U�&���Q"ٓ�jה�X>d��\_���ήс�y��R���=@�}'�b��`$a���;k��x��	�s|�p�)�r��&wFp�����[3��;��̃�K|p�<�T� V_�$��'�v��`\�ٮ�	�1�P�U\,3D/",N��%A� ���Қ���H lql#�d��zg�^�7�&Vg$zt+�Qv}������u�(2��TyK�Ta���B�;E�?���<�gj�oP=��I��B��@��)�n-k��ɬh�&���G�����?����o���/ݯȒ1I�9�e<��1o��ʂ��G�r<E�]��\,�S9��kp��$��gX)�+���:1�2�h�[p��~R_�+�F`{����T�zە�5��!�uF@�3�4�OJb��X��i�n���+š��b[S�Fu\Z���!ŵC�(d��v����DX.D�l��{1M�rn>���gAW�]�R R�ܐ� 
��Q�ۀk�w���
�E��y�F��0
P���+!��d���Mq�d��#��j�/���w�����fjڨ5�����I�q�D��")%��q���*9.��?�]Mx�-�A���@�ka6_S��Z�iVM��}8��#���WB����f�&(�`گb��r�X� ���"��&v'�]4�K���G��ˎ?�!P/���YL�T�	1'�{+ĉ��`m�Ϣ^����g���n��Nl�&�N��;�C#�I4�$	^h���x��f��)Lq�D�Q	�Ѯ�}�υ�go�z�{?����i�Y'
G��dB��5(Q�G�B�@ۗ��)��j᭢���B���>X���;ڑo�ʤ�F���3Jm�8AE^u&���×�ދ�l�p3�"�I_�	��c�-*�
PS	�oHA��¤I� ~�7�0
��D*�,y{CS���)�e�Ztp�LA�-���/�xl�[ȉ�� ��8�#�{����zL�jo�Y!{�B{�%��M�E�WSɝ�w�g
	#wAFv�'IW�B�J'��yLN�TX
�E�Z��O���A��:2L�<�\����܃����� ˙�z*>�3��i�MDz���޲���'-��,��j�E�e�Nx�������T��fl�N�Us�sq߈��	��;�y�fU���$V�j�c�~��ѡ����}�b�ǍM�S�A�I�ܯe�JQ��K��z���� 㼷�o�e�,k� #�)���D�<4���R"GG��32�!��'iX����M2��6oi�k�;Q�=0�����S޾x�a�g)�G����B���^���݋�|�`�A�hn�)�,�Ё!b��^�mMI�O#��BYb�bvԋ�����_�����T �����I6)w	n��C���O'1�/�[E��~��|=b�E���7�_2�U�'�\d�d?Lm.'M�C�V�o�\�U+��� ���d��(��R	a$d2pw�������ܩ��Q? <ݟL��H[�Î6��yGc; }q�T<1~)�=� E
`�!C�6m,T�»�l�^�7���+�z��?�:��rL�c�4�� ����1CU�
6�����7��S�bћf0�������U�yIFSF��N-l�й:J��?�� �}f�Qљ��=��Q
�*qG`'5��y!��}{j��C1���\1�;)��|�t��6��a3����ռԀ����J&���V��ɒ{��<���:T`*���R��5J��Rȓ�3�S\�A@��u�w��c��RW�)E�gF!����?�l,�[?�WUd�k�9h�&�O���q�̄6�뵫I�).�����;Ba���듞+tC��:�%��Q�0.��/��tp�9����iN� 3����d�L8�N���ܣUZ�|\ẇ	t,Y
܉M�#�a΀YU��~���9J?r20��uv�� �X�<��?A��'�X7Źޭ�!d����,5�(��Q��լCL��*'�d:�2���R��J4r\��م��r������hh/d�@�܅�`���4m�=f[�1j��J��T��ң{�H�|/p4�
Rs�3���-k��s�3�H����AϿ��>�8M>-ל~�n^�Yq��>�M鎡(71q�)�H�XX=c�r�Rӵ$��_��i|Z30����!��QGݺcf2Tu<�����N��B.+8ꪂ�K��{��6�]9��>c�s���r�P(;BA�i�x�ߖ���!��v[K`�����:RE�r:o+btj�[��HK�$�d�F�n�.Z��\��,�E��g7I���b��~��A��'6L��*p��O�����t0�Uq�������ya�ڍ7-$.C���GH��#fd��j�jy����nT��Ja��RHvC�"	�y�L��y�=uAA��dh��AY2t$�ۙ�ܗ�Dd��*3�
�o��W'���A�B!�LAEO�X�$c.6늤3=���v+�R����V��^�)y#����k]�,��u��P����3Y	π"ʀ�S��mԝoV��CZ�v�Ȇ�7���ζtH�-"B�m��H��;��܈|����	�4_lX���L��U�y��-h���.�n����D�����2W0:l%�#S�Es��b�hE�b��ɲ 8��B{�ࡾztdI2Pԫ0��Pԑ�~�,�L��^����ٷ5?zW���%�Ѽ�4��ߴ\.�����x�L���ƧN��޺�\����mN��''u�^˿�H���![�0ɝ�w�	����lP��~D����Π~�P�e�z�����X��&�Ì�j�A�[��apy~��[8皿)bVDzԢ�~�����/�ԑ��6�p�(R��$��c\�Ѭ�s3����/�h�ڊ�V�NcS6���+(�\{;g���EG�t~5�[��Qu��.uv�qV��;K��z�4��&M3|+Ȣ��m�gk��t-@��ks�^9Z.���@�\�æ�f�ǸUo`1�z12#�lܫ�Y>��8�{a��lקХ��������	�~n��T�P&U���ʤ�B�w�B@@�W��k/kSg!+9�/x�f2�HX��nUۍa.��I~��\*�t�������B��*��c��B��[��i���x���o��If`��A:r� �c�=t�o��\9�zQ�jt7hpdY��cOV|6��;sa�$3su���<kiﮣ����*ݜ	�1c�D[��+�\��p��3,̫���'1eiVki��)Qp�4ﶙb85����ŢQ�FV�.u�0���E�T�'��t����&-D������]�wL.�^�B��7�>?[eǐ� �0��\�J�|�?7?�G���m��-�]�1B���S�&f*�MT�G-�>"U����}
�|	(*�R�Yʎ�9��I�X�o�,�5!8����%�Ar-�A�\���c����8��訳�8��]r[�?�����g^��wQ4`8�8����B�G��R����*�r�[B��f\ff�:�+���Ԝ����@�z>uտ0&��+�/�-��O�k����	�;�\ <(Z��QYY$'���'d- N�@o�`ul�\��@kU)�6Y%�E%��Ѱ���AKHx����#�E�e�>,��.�Dd=Az�F2������9���E2�t�ӆ~�_)�������ٹ7iSq )�@�uarz��4,�궒O�	�#l�б�y���*i��<��Q<:�V�̧��IuR�m[��p	�v7��W�g�2:�d��j�����;x�o���w,i!fi	zM���eВ�q@�� �<�S�?���Q����AU����_���@�q��ߢ�S��꓆U�����Z��p�tQ'�h�瑭}�{)��9�B��r	�j�.pۦ\��>@K�e胈,1�ݥ+}s_�
3'?��G2�s�G�m��$�u�5|�.��:�G�s���*��)#��ř<ˣc�<azßg��#����@/b��1��%^�1<��_�5������b��|:����l�$���֫�V��a`Vy-̧q��]�H��O��7��Fa�����%�URS`Pg����A�|�V��N2^G������gұ��� �������W�0.�訉�f�Sn���s_^Z��R�=M]��� �Y_5��-�P9wқˊ�6Dl�)��H
�E�Ѥ'��n����}q�:!��ܜ��|�>]m����;[@�Pc*ˡB�����g ��^����.{��xR���;����Vf�5|��o� �^Bm6�+�6���X՛�>�!�%��p�a�.��er.��U��@���^G����o�L�p-У~�j�J�Xi�LQ˷졒�23���C}�꽝b� �o� >,]uҢ]���'V���9ظ�I����Zw�����!�k�R_q���u3d|)��x��`"�s��k�u�q��D�kU�6N���f(Ӱ{�B�s`aW}������H�Ң��Q�������T�4�i�"2+�Mtnoh~!2q��JP���7�Xq���nS�9)�6П'GM5��e���4��@p=Z�VJk����e�<v! �(�t�#4�1t��w?t�_�ud��.����@V�=��c��[_�_:���AЦ�;��u�vC��@ea�j<��-;1�IYʁ���e`�6y� �~O�@�&�a��@[�Ӱ��f�}����(=�)ª:dB�yTÏԩo$
9\I��En�:�5X���!�E�ՕԜO:�;a]z[��?��1�2��%&�����$ �f��a��^t��\�J��1�5�LH�"+$�䕄���fnH���RZq�Ly
�+e����ǌ1�oh�:�,l;6etp�\�o �����{�g��{Sbɺ��/�k/ cIۮ��cnmu�$<��tx���h�A��r�1��&7�8߆���.˯�Z%a��������?dFT�Jp���-�����V��K�̑UrB�U�7Ɔ����̫�WGQ��$���6�F���[���X��Ñ��nhnr��-�Hȝ/$��L�M8��\�m��@�08�E=Q8§z��su�:昏�r�r���6����	KBl��^�0���n���K��7����k�|�����X� �Ҋ;m�ST��l����[s����j�q�?`,&�k�_No��w,��Ņ����꘵�)aI�z.݅&׶���M�MpS��N=��ž�~�-�c��� ��<gZ9��;t�\-�Kzx$�c��g_L{Դfc� ��Ո>�d�5e�sgZ�Pp�RfUʙ��ݟ!�>����Iu�UZ�!��e�لzs;u���N���9�4\}��6;u_t��٣5E܍)S]~5���v���Łtg4y��3��a3H��$ø$¸s�O��/�;⚥�dފ}4�"@�EԢ�l֜j�g��&G��_�49%��>�@�h��]4��.O{.y;�����6�;���U���3�c�9M�p����G��>5?�k�3}R_Z�W:q�ַB��u��U��':��Ίt��L=����pIEX�uu`i��P�/w�D}@��b�6���1
|.(+���δ�*�Ԗg*S�,�*��xa���]2��L��=��Y��.���,*��U�q�W�/��h�|
B�<U�t�Ya8�)���L������n;��OHD8��d��i�J{���v��k�I���o
6���sV~6��&���u�i��G���Yj����/ �:3V�i_p/=�+���իRqq}�s��k�z�T�u �ey[k��<�B�����	c6|��B�:+bΑG���7�r���o{(Y��0��dW}�{۹Rhq�r`�禃w�~6he�)&��^��vo��]��&>o�4=�{�#�z��r�)Qykt� ���7e��`!��wl���h��#���WՋ�DhK#:R$ih��G�9��vQ��S�^>A:4���9B�
�;y���d%߁�!���F��ؚL �`����[��y[~/�@k���d��^yms�������%�O�n�*�@�"�Z_�$�:�.7���y�+���5�kl�p�j����mG�#��>����J�zsrHru;�)�O��4$�K5�۪���P�ʖ��"��-�O\k�)t��+^80���`������V=Qg���*IITI���߶o�(�Q�~������OOβ���K~%�������^+��C�\m�.��<�;�ӛ��$"$���,���^�ۊ:ڸM�O<���̉>���tJ%x�~t޶Y��I
9Fr�v���k������.�_� � m�l��p�VMMc����M�L�zT����.ɱ�"b�`��}%&o�����*��Y��ݠ��&(�d0�̷.)z�TaZ�xeՐa�I���jf�J��z���G�杭�/>D(U%��=s�f3'v|��!x��>M�����}&�5��k@oq�ʟ�4��.���U9���Fl��ZC�Lo�?�-g)�H�OB�:؄�*(��X��yɟ�1L�?R�((�+V��O9})u�q1����Zt�a>�d!�'�����O�Ö�KvzPyjҜA��C��Q@��6<\2^��Y����T=���6�sU�TџFbS�-�$��d���&tܢ�_8�7�\
gW�H��ҲI�eS��A�z��(J>: ��Q�Gl�?���5_J<ީM��T{o�4'J�K\�'d���
]�S�$��c@��׷8'���x��`��'R���M�^A}��|��I�g�ˊ�q/�~�s�Q*8��!�3 ��� �a".���dek0�A�tB@F��h6k_шjcF����7�k��Ö���A)��yJ������5����<���[�&����U�����{�?��5���l���G�6���_��\}�!�K6�����W�h��T���W��X�؍�Ӝ�{aw[�d�b� �1��lDV*��^�����!���'�������p�8�F�w�B�XNZLY q��6b,�ɩ�u4�	֑��7ł5O�3K�hrC�LOm^8U:M�#�M��w{*��	04�~-��Kҥ@��	t��VIz�)v��
������w�A>�8�հ	أ�������8ዣF7�4^M;��2��u�w�8��nv�����'6
�	<��3�/��9��w�^#�<v�J3��/�Tђ�Cr��mpMJ��G,�>��䛒�W'� ��i��R#�863|�r���s9ː$��J�W���L��B���Tt��K.�$"��.X?�`d�"�kϩ�?_s�r�mT�O�$���7h�̑�\��z\���/��i��!Ĵ�L�:˷[G�ՇǷ��>D��9C�i�y#� "i�D;T,>2��SaSi���W~b������! {g�hv1��0.�軐�J]S� .|1��uU�Yup_�F�%�,�<@~�(4$��	�����D���	�#���(�3�D��Tgz�6�
�#)jü��1ɀ��R� ]���*O�^�T�����һ5��$HK�I����s����M����%� ~���2��n�������^�Ӎ�����yzK(��"�`o�`���E�gV�����oB{yF�p|��]�(,P�a��&3�+�F`��M��Ϯ�RJ��,Y̤"����k_>���\[�n��^�/����(!s>Utb�#���.2�S�N�s��)x^8#��Z\�'�}��ǒ�LWL�-e��i�-���R���?g�ӹ� �jكy�V�k�y�R'�7��	�r3|�&�b����˹�$Ț{==�OKU�����\SH�r)��zWmx5w�p�Ƭ�QЮ�ů��Y���0��圔.��7�ʾ{��.�Y���P
aJ��֖�=��W����Χ	���I�#wՄ�c[\���e�������cx,+�5e#V��r�L���	�/�7��2ڢ2���_�9�3�:���r�1Rk,�U��SoKs���"��
��l�td��X��-@��o���Sr�/Hg@�3Ω�����Cyk���!��,��iz���*�:�$H����?�ߑb�=+A@�G�͏x�^�|_P9����` �@���ax�K�J�'�P@im�M�c��N_�cpWJ(��h'V�)k1w�b &���>���bGIrK��g#j��bIc���d�����o�����!ګr�����;�1 �H�$r��n�����Q�#��t�gԿ��o�Z|YNy���AϹE~J�TV�$�R���l-095q��0 &��:��՚�~[�����ݑ8��-)eڴ����0�}���ߙ�I^_�J�`>n��0�H���u�bv���)��c4TQL�]��["�A�T��2r�;��x��<*�:����aGQ�ʆ	pb{���~���OJ�ҁf�J}�"����Nu�04�3��T�'�=�*���1�� ��ƴ������z��JeY=8��p>V�IP��}���Y˟�m4�^�F�t��!!R��&�%�q��Uˮ�fH��n����c[�y�f>���Yv��^KF�]D+���Ӝ�ޖ�C�-8�]Bܪ6�-�}F�瓅����OHKP��n�ۛy��]���§$Xx�����U+�f}�ާ����77lɬJ`�$��gHw���D����x�{y�W�;�KS6���=b��qg��8��i#���l�#��SI��#/�K���!j�mZ7�Jw��HŹ���ԐU����)�����x����l�b�s�b�$���RD])�����s�(��2���Ɛ���Q�Y�`ȕMo�,���]ޭ���Ρ�7E��@��
q�$i�5
���q���j��u�8:�zE܉Z�:�<�:�]�C�*@��$t��!?b�S�R?6B�rQz��$�w	'�s��H���|n��s4f��.R��4_�6bY��$%���ȼ�8��v�p�Yh Fd��	MQ)Zʰ��0X�[)˻ī?�s�x�:z�B;*����a�½��|u�:m��(���ڞ*3��ZҖ��8��}ƹ��k���������1�_V<=���v��2�Ѣ����a����?�d��}L�\}�1^$@e%l�5�Y�F٫�Z,S/���)���n5ļ"�{�d+�<E��q;b���<�e*;�#�3zS�JUDW�~CQk�p
7:�>�]�=�\й\����%G��\�'��Pꌓ��!�Y��8�t, S�b����V��3�G��RL�T����z�U8�m<�p˞�*�sP�s�b̽�*ąS�'���0ʼ�br9��#�L�z ��z���!
�[�N�.�N�s��ۧ��3j�<��&-?o:T69x�� u2�Q���ȶ{����ٕ�������uK
N��˰E�1�/��]�P^�}����UQ�P������7S9s)�TQ2���Ь�D��u�P����_�������1�ஜߵ�'��C'����L�Cqѩ�̟A�QoV�z������4u���~��N�T���.�i>R��F>��hʀ�!�"���|��F����=4�;o�*�Ъ��I�� 7 )�Ꙇ�F����0$�M9U�� ��8�����Vp����Q�9�}��@IHO������`���t-}/��#.���ܯ�W�v�cCg؇p�t`�M�(Ŭ����c�%�����<�/�c�y}F���۬ "yV?����jD��~<W���+�k����v����wJ�Ò$��:��F��M&���k��wi�lr���l���Fۢu�Q�-��s�p��#�;V����D�IiJ:V�wV8�69s�7��\����m\2������/kC�5��}�#KT���^���}�eǿ�(���\��F
Cze.���g��&09FY�"�\�܈}��;{E�W��LM��#����МS�9I��!�����U��X��_}\����ŧ��_�d�3Ԗ���$N�o��C7]�n�V6'���y[{��y��o�%@z�aZ@¥?Z��k���c���Y�B9�VuUz_t�1�����r����dl���X��މ���[d��tA���?W��7�'-@0Z�#��/t�R,�k�->�y�,�Ϟq���_3�)�Ǖ�B]���J�t�O<!}d��_���4DD
���>��EVH�a�5���0�'�nĀ�KO.�|[4�>-4ǋ*J~��2[��"����4X���
��˴�K��5З�rZ F{0�>��eK+	���$�s�s�PDָw�)��0���m֤4��F�-�	J.h�%��<7��l�hC?�R��O"3{�*��_Y�\@s������M�:A�edi\�x��I���H��1�u9����`Vͻ��G̗�)ņ��1̈́��F�`�=���uF�f�K���;��bl��1Q'���'�ƔA���z�篭M�B�S�|����WL"������Z[{�:"��k'4;��Q¥{S�"ة���Yf�|Ey"�By�l�g���R�(���u�|@Sm�C�,�Z�^�$&͹�5�X����Nc��ӔU&��q���/CI���%쫂XebQb�:�`e�׶��i~�:�(��D1���:��3�Y�E<�\J��0���>�^6C��K)b)�6R�ʔ��:9�.��@�%�7Y�����6�w�QB�ln��7'�#<��<Q)�d��4��_[`�-g4O�]��yJ��Y�%���_�&}��m��x�d�������6J��DĠ �����&$�z�ɣ�����	��e�O�����6�S����|��{�o?�0}x��n�Z"��R�XϘ�Z6,������%�Q�+��Z���-n%)�g��1�)2A&|?�icL��l�4�a��eg
^��PW��Qf�Xv͊En�{���~��{u�TV^�A��%�� ;)�>��3�����S{]�RP�B�g����	���+����x��!��
6�P�IP6��d�]3I1�e`�o?P�}�T��g"��&���\
�O՘|�Ӎ@.�0�2Sia/� �c��v�;�\H>������0hs��s�ƚ`c�5��]u��b_�Rav6��&��)���zX~�6����\�Cհ=<�{��ک%�eF0�i$��-�Z@��4\���9�0l�(i����wNJq���k��^��'��䘖A�'��Di1�+�[�#S�q4c"�h�P��MKН�=<����qz?�o��e*��{��k�sY�d�ʥ!��	>̩�r�$�@�j��l+K�7��5�"�s��mE&�_A������F�	2�W]����C�<�Qtjy�^��Q�v:�T=6�����{���ō7M������&���g�L�wT��n�3�/K\�%kz�d@f�{h���5ݙ�'�"+��΢�K� d�TƜoԏ����t�z�鋡E .}�8;�;w��*�?s�['{�z���X֙���#�%T�+ZP,��S��EP8gޯ�ƀ�mXfD@��~��3f�u�)^甋�WM��<�Z��6��wϛ2���`�d��-�h͓=wL���0��mf�1CyD�udlo��a�V�:j߹����m	$.,"w���H!&����g��>��m�-~��lHB+��h�@�k�B�o6G�
B˞Mw{��B��V�~u�ڬ#�%��t>M�B5C4�g!�^̘kUk��S뤀*��wK��Z&��#g�=|�|I��ڊFc�I�8O�c�u�;e���7�yiNK�	@�,
�t��Ɲr�.G����Pzo�SI"����I���dC��yghv>�����ޖS�4nOs�� �0�� &�L=��LYY�<�Z1E\ ;$�p�w���9��dX�'�1!�5��vÖ�}*��s�,������a�Ǵ [��t#�8�����c>>m�F�D/H������D�Y��xG��2M-�ؗ�I9�v��L3�«ۉF��dIT����l�<5�H��.?/�t��L�YU_�֬�x����+5����*͟���L�?5���6y�4I�&�!`�!�|�Ԭ�(�z(���w���]�Bu�6�܄�(Jc{�t�m�"�=�0��ʒ6��_��|sWnf}���N�MS&y��58�ϵkÃ�=���g�G�]�ҲjJ3�sAq霻-NG N�3�I��qo���@f6P��w�_��ߐ�pG
��5G��J_?k}������*���b���ذ(OK$���0��:wQ��{��U/&S��!+�ZMy3�W�g��]Zy?7y��_Tq�x��%"my""и U*���?�bA��#�ܵ냪�p4�Ó� ���G����r�.��
e-1Y~�Us/d�0�B���җ���H8�o~��>��kǝ�t�.��>�@���7�����
��#� e�6��??����4�v�=Y�E��CIWa���+�Vq4�uM1�_�삺L�L����"�>�K�g�����5V��}46��"u8�:×.��|�Qz ��X�A������%pe���l�n/��}����R�~�:��ɗ��QD&WV�sE7��H�6(�ڣBd���IRt^���)���La��;����J{�/�|$Y�o�@Ev,��I��l�u숆�1-¯��lg�����jИ�D�Ӭ��O��cnd��c"��KG�E#	|��a�Ԇ��rJ�$���}�#�{Љ�B=�VzqR'E���q(VD��VX�IfS��� p�.M?�`�`jY�G�IE:�8}�Kl��_����f�|5D�Y^8�@;ey�eC���[��h�j��I�s��r�>e,Fn��螠�����ˠo,�i��F�cGW5E����i3tK�x9>�O���1FBjC&H]�סi��X�N�?���W�;�XZ�G=����<�g
��N��p�@�a�*(���k�x����m�Q^�@!�cVb� ���	V"�R[DJ�n0�\+��ߋG�:�rPt����i�f�f;��B��-�fӽ�c���ɝ�]2�	�L󻶢/B��Di�Z��9�����Yb����;�"�f�<e6 ��ƣg�6���'f������B�tx�0�2(��}�;������g�+����$ �=�~>Z	�����ϙ�����%5�*�s�=�W�vu�����^8�'n\K|�yX=9V(��3��luX��ޒ�-&��'N�����`A�g��Ss��K��'� Z*��8:ՓS�����SO�k�C�1{'�R�ѝ��^N����[��)�AU=�)�T3ĝ���o��/>�F�X�����T�/���V�x����5R��g;�`�7�\mla�%a��v�����������볥E���a��7��ܗ�KeT1V�a��pMw�9K�K�'�����ߏ�_���K=�$qpzN4�/&���k��^����D��ulr0�
(.�O�Т���f# �5��s�Ec>xJ��5���w�~�k��c������|����_P^�<K�YU	��"��vG����đ�D��4�<NX(�%쮗nNg(���5����:�1|&�P��Qf��uGK�ܫ<��VMO�����Hލ����E�O(��gt�2>��v�l��2�QJ�qDk��k5C2U�'��?�u����\� �8�jv|}���<�h�@݀Ϻ�qT!lc����D�&�ң⹯:�5�|e.,5A�=����x��NV!�opx��P�~wo���V�8Fu�Z�#�LV�������VT��#��ڤ�cwS�H������z�:���e7�e붙�,1�V���`-����a���,��m�"�:�E��Y����K)ޒw������-Ղ�aG?�;�I��h��w�⤡�@WZc�h��	7	OB���ӟH(qr�=���r�����u���XMB`E�p�eW������)��%O��t6F�trT���WYpw�'����J�f��}4޷06�y`�в�p�rz4�BJ=��&�n�̨7��UNL��a^Ta�_}��ϦEwm�-:�%[��m�+t�1�B���C�0��Zjg���C��8L��B�a�M�5���О�!�0<r����x7o��l3�����<�]�7s��&� |���<*��<EQ$��"C�׸8�H�*t>�����UA˯��qBl�Did����hD@�\-��P1M^0����i��`Nս������9 ����]�L2TT�5�}Yr�k]Q��źLD��S�.3*C}�7��h0�(GYW�%/쑺\AӽT3�
��+��]{X������cI~�r�TW�*�v$���z�:�����)�Q��x9	�J�| �0�t+���ںFp�q�r-£�<�W+?Q
�˹|��m?o��ˣ��0N5^<݉ m�w�Č�_�|���3vu >S%�~�ߪE;g]儔�h+H��~e�am��P)M���:m@�|�x��2lώ� �}���Omh,�2�I��f!���8�[E�є!�S������JZg���nѭm�S��n�]p�)-��mN��i�
m����"e0��>���-'���C\��T�8eT�:m̦ �HHm鋡�������+5,d��ok��6��O�}����f� ��Q+ʥ�D�+�G��zTPO������UE]���u|��=0���Ά%c��l^���S���t㏧��MQ��S�?g�H��ζ�2�(�8L�$撁1}�.�R��$�M�1}6���xK���]��D����$10H��J�j�k h]2Tc�U�+��,S�q��Az9�6�k�VCR���I��jc!L�ZD"%�} 7��<?HI�HI7���'����C��B�]�By<��m�B
�
��c�� �<(����M�p@}�'�*3���S<S"Z�4�Iҡ@�����ֻ����z����{��HwÜ!�W�g�4oy�Y�)�)��F�W%�q?-1�y+������2R���5��=�>/p�����8�!#!>t��)�-�?��XJ@�9���_#�洌������}r���Y�16�yb����w�y� 0e(鋳U��;C�a�M�daҦ�Y-�o&-�q��%��%��B��O��z��A��-[~$��K���ud
��/�����Tgˑ��o`�Krf:��"|�r9�i,׫YtqU�ِ#��J^��VỤ�+�D�&W0A%ˉ��1�������3�)(8������]���c�XD�_S�#K�����n�,;l̑���S)����. ��R7h�$��l��%�b���bx|?��O� �)��2�F��b��8V��4���֐�h�ĠvkO��^�%��l`�0A���6�@��,�:n�$�����;���씓K�纷��vT8���F��%���:�^���d���A��ru���isɆ<��$nO�>>V7 fe�ɫ���
�H^��v�;!�$���5�Ь�d����j�����Ϗ�X4[��i"� {�Q�Fh���~@�49G����
/�߽���5l>�el��1&�L�Y�V�-E00�X��ةQ��/8��)PG����x���5��|�ޫ6/�V�F�c~ǒ������#��c�ϰ�?暱�(%  `[a��D���}��}��DK�)�hC���n~!X��ӷ�"����
2SȞ8hOË}���ƙ�M�5�KC�S~V� �VcB�Ꙃ]7p����0�Tˉ?}x-������?j�q�e�S����{畈��30��͵t�My����R;�QM�gZ��ؒ3heW���s-�&F<�t�_��,���#��c'B��FZ��(�!�'u��q��F���Ȓ3��.�p�G+���dR0s�s���ndL.�򫤯���KhՕj.*��>�ut# �zX��%�й#i���x��v�Z����Wn��r{|���T����F��fyS%4P]��}(*���D}%cn#|��C�:�j�{ㅠ�S�;&HG p���IYTJ,II���n�ہ�8장(i�M��C2�զ�}?�5�t�h�Rg�wR�ݎ1�OC�m�<m��i��]����.��(N�&�f��=�z�� �gv����D����	X>��=[G]��~H������x�(�Ua�g�R�4��],�;��C��\ u�t�]*.�I8�D��/7�o�lݷ7��v^�)n��c��I%G)]>�XO%��J�
qٳ�c|��+&_�����M�Ar��oڱ�P��H+�䋲�x��>���
����4� GJ�����H���reu1~w��5��b�[s��І�p����bHb�PZKRw�NV�����|N�o@!C2DZ=*{~�:!B��y�������G��(���A5#���]��Gn��2����`eW}F�[D�V� @_?�A�\�tv�LGt1�z:��zZގ4�n�b�c��K���wZ��>�;rQ�[��'�:��ҁ��Yمʟl_l�.���|����@����îx�<{y6�Hf}�F���mBR�'��GŐ�����\��21dk�;9L�o�H�CUh��]s��#ӓ\��^(��6�;\;�͔���A���X��	�؅hr v����"�p�ǌ��,ޤp��Jo_t���g-I^S(0/O�)h=�F	�L.���(��I:� ����+ɾ;D��x$���r�Һ(���ì����0(W�wDoc�����H��W��z�ʪ�������c�2_굕�9ì��HL�@'׉�Ez�X85fYǳ�h*��O�+H��]$��K�2�!LD�Ч\;�P&M���qr�4��nj�3�X@����G����Ŀߺ�R��UɳΤ���2�N�HJy�W1��dj^�lCTB陨���se��U���4����@��d$f8������Am�	!F�׮(�Z�_�.aNp����n�nv�;�R8��$�7,ڡަ�8�`�� ��:��� -]������`X<n�>��u(Blrј6�p)x XF�i�`&�:�	��d0G��ΐ��m���ٞ�ͬ�6��� �)e��7G�c�8Q����ƻ~����n׎>�u�֡��Rd��]u�X�ι^��hLE�?����o�"'.�������cO+o��⊣/�N�HBZ���t�r�m �@òQ�)$y	S���'%bAϴUu`�p`7�"�����#��j�qYdak�mL���	5<�s�d�	x$x�NL�7\�����6�����o�1{�K����4̿�l��*�%���Yz�LIDL��2��5�����)ڟ.c�8�������������3Y<*H�v�䮿�'>�%V �)����ˤ�z��m�&�̛��2b\��ԙ� ���X����Jm��Bu��(�L�ʧ�q��fzh��
*x��fn�L���81�N7v����M��83�j��oZ�"��Q�RhB�� q]E�~['|��Qc��wm�������e�^�*폹�׾}�pjk\q��c��Ƣ���T��%��5��&��z�-����UWg���Z/�aysX�Q��g��ݟ0{�h>��$_ŉr��"ܯj��AXC��),{�j�����f�u���7y?�V>ڜ�~�`�����M��z�O��z����y�cD[UR4�;-`��P��*�;�!��LIHp�#7���Z�g��
��a
T��[�7L���<3�T���R�b�� n��=�wF�=;3�ޣɛm��*'N�c`fJH��H��X�Et8��D��x�ʧ)���k�K�,����8#�����I�-)�$�G��c�jb2�������Pb&�
F���݆��e!�1����ϕyY��Cc^���{�3 �!��/ܙ	vv����H���
/��
1ŹF�lo�����`�"2����'5&�	үH44���*��.Pbٺo4'���B%��'�|(�Y�5w'���V.`Lnm��ʕ�>R�̾�TG��� �D����]mm��*�Ѯ�.0�څ4A>��������	������n�i����+#f]HN/�-����t�7�v�r�ŉ�"%Y.�+O����T(��Ip5�9�Ҩ{�I��|��I}��/NF_�&�+�53�p�$������o<�� �#�$ļx�wt2�%�6c�p����k�"�n�n� ����P���� ű,NP�ե�e�+�}c�	���c��cAF)�A2�fT�|�ik�0��^��I��Zmpc;���O�P�9��������9H �m�Y�Rh�*^v8�@��^ ���Z~WjAHۜM��]�W"�9�X'�?�_����G�&��ţf�5Z�N���:ySQ��'�-a|����J4�G����2-�/_��w	�v��mu�ߝ�s�l���EQ�I���Q��(T��̀ ����j{Z�'�3�4@���������/D/��}m����i���rȭ��k"�?��jd�N=���	�@��Na�Y?��wƁl��\�-��c�G�+ZS�P2/A�q��G�)�)3���R�~�Ay�S����,Q(�0�d)�N �ͨ&Sk$p�rs\���'�ҥ�E�{[R^��"7H��`5����]��ofjѶ�[����FY�P���5�$ �Fvo��
0����Vx��\�J�+�5E��
~H����P]���t)P�V�F#]`hN��L8�]�ȳO]��v:��3�n�����/�Bͬ������Ϡ�i�!�Eдju@����s�fC���19�=eYIv�c��g {�ɳ����Q2I���&n���)P1����]��	��Rݵ]㈉|�o�$3�Q�Gd�o�o���p_���a"������(�E*A��_���޻���k�]g(����Q��~�Q6Gi�<BXm���X�< �������E��5�,��V��}C_�]�*yԩ����Ǭ�f|�_�� �
�&6�Ab�h���G渦����~ǣD��-d��� ��{���Yrє^�(R��o�}�bH�QCc�&�T�G��F���`��Dr��m���$�"�آBa�V���h�����Lv�ש�(�_��|���6S�U52���[�� �#�vzH�]�.���¸��}dlmJ�p�P �B�,'��ȗI��g똗��JRD���4���c!�2��V����B�7��z�h���g)D+�c�>}ƾ_Gg�wR���~�<�Y��+�_g$�E������n[�M0���I����Z�G#A�܌�ަ#�_ ;���+��G ��*�R����/�����O���7�E�ܟ����~;5<��SO@�g��'��V�(�d�gy��V��rLu�6�Y ���]�C3y�~4�<��x��uEi�n�����3[	O�|LCLz��0o����$G���Į'TB?�:uߎ�q�ck�zc�(�i-LhKʠ�t �0�I�|���I��Xs�=Ģ=��>!:qS*�)�G$Z���`�!�q_�m�6��N�� ��C���}U�Ǽo�K� �9��\hr��7�cB�fԟ2t�����v����)ϙ����.7�_X�t���N�<𲟌u˸�lC�ς��;G�a�o�-":�̒̚�4>�@���w��*�l/xX`h�:��1�|֎�J�F/�LAE��Im�~Μ/�ʑ�B�_p�������G�g8�\'��}�K�yk�$ӊ+�s%r��l,���S�[��z�d�#�	�U�*.�M�BU]�U��̷_:~x�����7pO1��>��Y�q����뢌�n-����gQJ�>O�:�"� �)k8���ıI��UX//-	R�a�x�ԅ�w.0e,�� ���0�mqM���H�i�t��<ه�Y��a
�9�����{�3�X��9�hD�`]�3���C!C�x�2�:ζ������Q�v8pp���s���F_��6%�)�}�3��]��n5KZ�\ΆR���29�g� Q��
�:�d�*�rҬd�M��"� �[{O{I�]���B���	?�[����[5�����K�t>�\\:���{<����s	X[(���_���</���DW�I�/����gn��%y>-~����d�Ӝ/��h��{G�:@�9pt̠p���)6�ƛ��:҂߇,BR e�O.��T[×��P�e��T�A�*�QU�
����{®��*���y�e�>�=7vض4�=&YU���V����[��y�9����r���K�����N�/;�{�NO>����KDlY�<{~�^
�7m&��Q�(;B�=�c�=�C�x	��H�Б�E#8��~H�Տ ��c6�iC��HoћY��v"�^�l�|`ʥ'�̨�����1�Ud��VsG}�7�omM���BrB���-ARz^&���>/��9�HQ�־1����q�J�����:�?�t�8�́����W���ȹ��0�s=0 A��S�]�bw�߭8֯fA�6����o![�@�����K���G����:�%��"��B|��ΊH�O�f�\�x�v6�2i{�w�Fp�_�9Qn%�@D�M8���!���:'����1�:X^$ۓ��?�.�������v=��w�w��;�H�3$f/�^��I�}A�u�jIC���\�������w��QQ��r�̧��2blj�s��V���W,s�x����J�n�l��S�����9��x5�>v|�z�	�����~M��q�ncL.�+�Vf�_g>����'-���C�΀��n��C��p��C0�o�P?@���3_ň,����씧�Lx�k;��ו&���C��[�-Z�=�WG9������f��?���vg51ծ�b�� �w�+��bf"GA0�t$�V̕:��Z�e$�����4��	f$�T�����=����/�i�zȦ9��C��Pk"O6��dY��,���� Xv`k������P�|�����ʓ�$�@a����q]��~�,�A�����ET��Ҙy�t;A�뮑2�a�S�de��m�]�R�G�h����&�ߌ+R3�AP�ٕ�l�n��d�-�	�.-a�1*�U���<�2"��Lb_M���;��g�+g.!P�B6���'Y�^9[f����g������%Uv�WI+e�����|0j�+Wl2jhZLg(�O�)8i��x |E�M�(a���W��-� *��U�n��;�`<V-���g�A ׸͖�CYi�˸��m>nd���=V6��8M8&�f�֠�F3��*P��
?M45�������{̎E���g�6*����������e�j֖b����d9�<�c�h�э��ݍ+5�?<k�Z��_0C�Ү�����C�9N�7��n��u-V��#�����EW=·�'�"v.��J$��Y%&����
�Ae�� I�]{x�ȗ�!�@Y�*B
]X�~)�w�� t�P!Z�q�Db�5�$���k���n�2�$y�fN�al�5��j��dEE�ӟ�ZZ�Ԗ��ۛT��p���\��+\�uD��2
��^�+�vG�{���:��*ٖ�s�Pc�ykK `���:6$����1`'!���8e��K��?�S�sy�`Ni�}���ma����n�I� v����×L��7�t �9���&������(����S����Z�tyA$�>��|�V���J���e�E�[�{hU����#��H�Ȼ��C�F(r;�C���iA@�ߤ��F@����2	׳�l��d�JL��ƙ�Uss�,'����w�4ɠ+v�������G�y��&��l��6�p�:�]��|SDu�4K��'����D�S��+��־[b��G\��/f�W"/f]�׍�E>��i�������z
w~ݽsRa(��T��,��t��U����;=B��a�E�
<`��E���*In� r��)<�$��C�ah��;���;�O��1ɭ�e�l��7�:��Zd?��B���+�f�rj�\���\Ԇ�j����Hw2 K-�AS��.�i�K���;m"0��AͩG��`�����)�= ࢂyͽ��<�X�J��2�O�;�O�֫ƟI$���ʊAX��t��>́��3�
Д��ة#�q:bT�b(ܦ�g&1m��\P_�)��0G��i��0+�^{%������� )�gWP@�=�Q�������B���^PQ�	3��$[�X�'0�)��:����_ ��x�zc�- ��%�4�����:\����^jPp� �I��UEb��f�� e��ᘵl굓�o����tgOf��Ԟ%N���OM��i>A�ccY)"L&z�&����&���P1���c|��-�8�n�垯9`�u<bN,aլ�8�c�G�tC�������K��jX�ҔH�s�Uy���@��SLS����x�/Ĥgl���e/��B��y�ҙ�VL6������_�:��څP|�5����B���H�qyq2�DmI1��	����H��(�o<V9�^�2gƎr<��^Jt0|r_H=�Y�C�8%�{�<�i�L�����R� L��x]������(VFG���]�A��8�B��ug �/�tb���I�og2&��� F0��S���`ѳ�����CU���N��h��I�3�	��f�WcC�옪Ġ���&?��.���$����(�"`�����{�VI����W�K.@��sc�S�i����'���㒫�AW�d����.��L�W�>$9?�9���y������X�g�+��_@������0Iml�]��b���[:��9��L+��d_�P����'���i`��#�@��=�Bc�7q�9��L����y���J%�p�P<��^2#���N�~�e�Zz0d�g}*��# \��1�Sj�#� ��퐙��JB��i����I���)�v�
�TaV�6�P��>���L?4>��EU�>)��.2�{��k�'�2P,GѨMR��"$��`%�T����d^��	�F� ��� B���sȂB��;]�`�'H琳��'*r�sG�X��4�l`��h����SoyS\e8,(a��^ڛ��Kf/ty�=�p��J]n"˄�rP�ׄ 1?*;|c�G �����FL{��g�    YZ