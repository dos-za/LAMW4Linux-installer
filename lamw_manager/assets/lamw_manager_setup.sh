#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3576195583"
MD5="00c43c917ba67ec54bce32b4f245ea10"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="16944"
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
	echo Uncompressed size: 100 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec  3 14:42:35 -03 2019
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
	echo OLDUSIZE=100
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
	MS_Printf "About to extract 100 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 100; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (100 KB)" >&2
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
�7zXZ  �ִF !   �X��?�A�] �}��JF���.���_jg\/�`PҴٮTi���D	�R�T��S������%�G�D��U�����>{`��_@�����,K��$+% LaO��|*������Y��3V;���=~��q��(�t�Ƽ�L��t��C�'��S?D��~B�~��?�_���^�8��|�%���T�wm���n���G���P�ٜPH�!�}I~��ɟ0醈q�<"Rչ�J$�N>d�)l^Jb>��	�D�d\�@x�%��4�D��]+5/��Q�*!Cjܐ�H����,��M��r
f�҈�'�� �{8��5�t�g��k�ş���/�%��Q��U�������9^]���ʎ/�|h5'�rc"g�p�#��7�!�Hםn���X�^����}o� �S�-%�H������:�_��f?,�ޖh�tu�}!�WI�<f�"��K�,T7�X�1	&��f�U����&�M���1�mq���p��+���b�$���ϊ���>���s�a��!T�/=_��h>r����k�"��\�2� ���݅���������.��l���U�	���0�ʒ��8��e���+�����ҋ�^����9K�P��s���j�<ysy����U+�a��	T�S/��H������[���rQ(��+�n>�G,d^�M+���d���ڣ;�l!gw�U�B�$93+�ĜV:��Ѿ(q��>Ez;5l<��V�;�{v!�@�t�H��1t�!�o��ڰh��/�GIa/����m�P�J�}шMG��������ʼ��@\ v�2��]��mɫ�w��n�����T�����ǚf(�~��I��cH����Y뭄�呙�8u�a�����|:jB�)^*]��&L�N[G]W�f}`H�ժp~Y�!,�[���f�����z0jas��������ϱ'��K����~]��ֶ+*$����ڰ���= ��ex��F}��p�M���鯷��Qm��,�,_���q�'��ß�}3#�h�O����:_eR��s��r�Zg&ԉ����g#����1#Pj�/�ݏT����?���ɢ&��1d{,v�>��§���J7�^�}��l�r��q�t6�\�������vO�`g�\�BvNZ~%� �0��!�2!�@��=����c��Վ��ߊ��N�	ٍ}p��>r>U���M��/�̉y 9��ԓG�A��{Ο{8���������m�OS�a�ӑE�1�o��K�H�+ם�e�Vg_`�3�\ߓ�%+���!]��F�����7��a����Y���rî�b.E��7w�:A���v�z� ���qm�C:�!ȣe�=��u�Ln?ChG%=�#r�G��V5]G�/�Hr�}ǯ�S|7��*Y\�
����0��2��3�yZ��<�9����Ja�WV|��rqyuş*vS�������Y��`PL�e����<"�fJg�Ar�?l���~�w��(��]K��Kd7�iQ�Q��#|q�K��Ys�݊�̞'nwI�h� _��n7�����Y�����S��r%����/��� i��~vd9��8\�#�:^��}�X��nfA���Pm��-s^p2��tG�NEof:�qY��Q��4�xo�e��M�/�u�XǺ`N�<Tl�h���Xύ�4�{E ���D��j���mIV�V�9�m�F��, �G���U����ʷ�\U���Fu�*rި��2���ͭ�+:j�ω��ձHV,�;賉!�Z����R��]���n��(��Ӭ!L�ڂo4`�[���e���c���Z��F�".�|�q�G␞��U�P.{!Ʉ�pYjK�N�z#�Q��@l
��ĳ�&4
qYjɚ�F��
PA#�W)�:�'��G��}����&�ӄ:�٠8�]0VY���9)Q�Rb�$b{O�<�#���V�;����?�d���+4�#_ȩ��fN��Ɓ���Hg{ƅke�����Փ�&��0�ʟcǰ�}�5Oy2��nE��Xf8����'dFz���B_Kj�%�J7��{��
%�_���a��"'�3�<Vz%TWZ��=�~.�>~��j�+�(���ܫ���7��,��$_�q��(X�"̔�F����~7�0�!��ۅ�r���V�E�s��M�
h�j�,��#یR��a+(�>��!��:��sdP)�Z� I�Au�����2ӦH�WV�P�3�t��$O:����Ҕbd~��qbn�T�3���=M*�G�6�A�b�L5��-��ڊ�ׇ���?ӱ��IT��aT��r���M��Kʅ,�+�w��-e�̷N�L�d����7-.��A�	e8�L�>O>D�v����L)��
���<	(��a�/c�
��Ԧ�s�@$�һy���ͳy����o3	6���cʺ�� c��T.6"�b��yy�~\�~���r'�v̩��Y���@��:����Ǽ.�ߤqS_Y�6U.�U�	�Ē4�'|1�.T��#�Yh�pZ�z��A�l�fVۄ0���l1l~g�(J'��y#!�'������b�VXi�����Ä�&����Ӧ��z�����C�%蚑�eRV�4�2e��m֬Fa<3�!�=��4<~�o��U�k�ec0���x��
D��`��KW���{�ڝ���h�x���NKv��%�Q9�r��]�N9�*�⛀��M����&��d��2����ɾ�~~@]tq}?�I/Z� �J�/��:��g��)��Ud�w�K�h�՝��-���y�g~�;%_HbA5ߟ�>����.u;�}M�(�3�h`��<h'g���F��>0=}4�W�)���\{T*ߪ�CɎx�o��|��x(|��k"�b��ק9"rƷ�e����4g��X�����V����I=�`�<��J��*+�� F�r-���AJ���
�l:�(0?F�d�6��ۑ�;�3ʓ�'�H�jv�ۍ�0J�E\[Y	��Ȕpr{�s� �vV?�"�e���D>�Z���Q\��X\#���ź��}/�,:�{ ��q��D�BiX�p5�a��ڍ�@�!��3�?��O`��5OR�Z����@�����x=2���{����j�h�KW�"�F���A��U�+20�I������| <�o^����K�&����sK�R���׃ǋ��t��A�fS�Y�[#R�a��
����${)�í4���f+@�컧����\�{.;Nz{��C���$=�6���JԎkμO#�Ż��{��)�OE������H����b�x��}��w���md��q���Nz4���'@�,�d����B��n��:dJ����ϴP���M|��}}���8�8�7������\y�(?��D���LN��6W!�s���/�Os�~x#PƓ��B�syK�^�Y�!Hv��F�K����!�bV�S#���`��E�}��s�)QY�s�����aGYz"�Wb���X8��O֣JJ<�����r����B�0�\ ����F����/Ĳh�g$�c�c��lf�v�����ѻ�������W��Y��8�Q�"8�#��v�|x����{�^���L�䚈V7��,_,���AJy��Y����YZ~U���	�d�M���lX�jG�����0�P;',�DE��N�	5wAzz(�N��_u�=�����8Kj��A�h,mw������D��=����ݡǑ�k��$Ɣ�@s}�h�/�����<
1B�P�*G��c��Gc�4���k�[�#�����o'	x-
<aݛ����(�RU:��(m<��#�}:%����I�4���\��Ư���Fwv >�	���4��	Ȩ�Wҙ(&����o�wRt�f��$`�����u�ޜs�\��ޟ�rF��M��'+r����p��"�'E���;=�V<�A}���6���08Bi ���+i�d������'N�q��´Oj��t�,�E���@�W� ��<�ƹy��}5h���0[�y��<�A�58L(�u�^�}�s;T,0��b�WX�'��̲$�1Y���Ч��*�Ĵ�W&��;�����J�2<;����ޗ{�.������*]S`��|]�+ܳΝ�Q}�ָ|�� �D~����}��t	e/�v��B&3|h�4�쵲 2	�����X:��h�����5�]�&����|��E��n���\��MX��e���q]E�ve:P|��d��l0���L��c,����K䢳[6<_8����V�-��㿌ez����m���N�ʆ��j�zGm��{�2�ŷ����v��lUbvWhe��4Z�P���M�Ĕ�����h�};0�E��~)�IR޾�|�&�h,3�t v���_s�TL@�����6q��CBQ.ϋE_�ϸL��#4�e� ���7��s��#4f�"gF����[�P�k�io�Fڄ���S��/]�́s�P�;��@�Jz����^$�D��܀^�X��顚N��|B�^�ˆGu9D�|�w`'ȥ�#'���	<v��<�	��O�Q� �i�u�!d҃LL{l/��`��b�&Y=͖�/��!�q�FXJ[7�xorf9\���U�H��5���P$����Ý�$B�آ��&���б��'�i!�Bu�c9��85����B�#�JJ��rS�3�ٴ���o���Q���U���<m�GV<��&�&�Dq�3��F����ӕ��Ʈ�U�z+cX��*��z�<�^@���~9��i�1�$>����)�pv��&Z`(n	��Q݂F�;� �b�y}誉�L���K�[���ď�@���X�/�������&���O�3�1{6�Q���+�*r.3[�ĺf�*�7z����>=<J���#��F������X�&~�)�_� (!��`8w�rɟ���_�]h��F�H��d��]��!-��;`��U�BSQ��'ToH�o�j�U����$�i�Μ]��Y�2�mx}��
{��a�Jԓ�i�@��{�e�w��7�11OP����S������*��ܢ�:�a� W�l��u 3� ���Wi�v��p4/���+��IR�@�>�y-C�Go$�2>��Նi���}q��� oRE[�<N��T�D�Z�,�ŉ]�FD�y�"*p���S�*��^	
�@Q���tɿZp���!�8a��D���N��s�X'N�v��y��.�#�+\�e����cm�X���KZĺWb�t�݌ì(>�>W;(�(����d��Іs!z%��7�g��/5q�����%܁��?�.��40*��~�&�q�u����r��y��p$��҉�<�Ly��)W�4H�B�2�/%	K�S[4:�o�M� *5lンv��I�s��n�/N�(Dx Т����K��S�͆��;ft�
�#s���⼖�M��K�]�Cd��!�q�T�n���7\ks6���g����;�")�y��^I��/8�	Ƕ8l������r�ۥ\��VҐfڙg����(�/T�y1[wz�a6�F�0��I���n,��9���S !��ڜ�H�G8ϒ���ey*�l���x��1�["O����κ�K����ω�X�Ur���A"	ͽ�5��1У5����6�M�Q�;���E��".'P{�\���Po%�5N��A��]�4��Aq��w��?51����Dx	��_�o�5�y�G��pDvv}K�K��r#�D�����]��Q���@��}tTj[|}y9Q�K���9�v7�JT:'����.��>��@��/n�d��=��$�*��	��V�"�<0*��@?E��Y��]�TI�Y�����ӬuN��a�`�P�.�_@��͡a?���wK;�����_R���#���N��٩�A�I��֚$�e׌
�VT�e<��J�����$~�_x�) �P��\�ach��4�ڜ��u�a�w2OÐ�W� 7����N��c��9�C��ɭt~�-,i�^GtQ�i�A�AY ��������I��YȌ���h�f'��^X���f�#�'*\��L�5鋞 3<e�FO�AM?���w�!�xc�Pj�AՊl��r��Z�9	���F���e:�c-�P6D0�*�d"Kj�q�7������ tZ��[�&�~�E�d�Js�q@��!��D����m[#CA~Q�岣'�W�V}�"ڴ�����?�..D�	%�\`�X0�jK��Q�J��cPgbQ��u<tG��T� .�c�6�Q�ă�Rx�����x��[N]�k��j0?�DmL���ˉ���&��k����zS�20�a����^�^A��O��\���.���XS;�Hܬ�#�z
�7yD�^���Q��҄���華�D��{ �yC�o[�w�-�ߔ�!��� &��ߌ=��e���y�(�E�P�r���<'�.gMMN�x�����o|�'�9��P��x�� ����]܊��;�9m=��� ��Y,/ƄeY��=��_
��H�Fe���Ti��`I�º�@�{l�5����B�䵎ϊw�WI����b��	g��%�Fw�^��72�{]�ڵ���K��)������|/�^{%<^2��`"�@˅��hed^&�J�"�<=���U{^��0k���!��E3�C"
����z�&����O����}SAR-�!�'6)5�g=�p3a�1D�RMX��V_���t���P�髯XN
��Gx#��G���� ip��P�w2O�D���	�s_�)z�	Q�/%ڮ�x-c\xL��683�Uv��7��p7N��E�T�b��n��n�(�υ:q�o�����g|z��+,��Z{�e�el�$�9����v2%ꏙMi����i�w2-fdE��ߎ�7�)!~����p#��i�es�a_�֭J��|�ZY��`p����n�[�(��,NL)�(�
�0K/E��Bl[����n8��D���Re�	��6�TLr�(�^k>��P�
�A�ߡ*�VL��RT�NYF������H�.
�BK䨭�1<�މ�	�a���BPr#�&=xL9�>�8O+>:FLJH����T{�|�ՠ�	��u/�,��-4"M��18��DV[Z��M �v�s�Չb'��8�3�l�v��%�#,1̿"���.����&�O��A��$�s&�Q�/��M����i��j(���JS�[n���f�FU��]-�Q�_��t��vjJ�p�%y�3�������n~�d����>�q��"$�ЂXX����2�z<�4>LN�RĖ�7�5�UJ��º�fݵ[��������lB��JZ�3��� `�[��^R��1��zW�䍠'g�JGv�J�����ިDmA
�t�&*��]��u���#��D�����f���+���g�k+��[<I�!N�, ��F��*��<I���[�q��l]�h�A�	2Z0M��ͺk�Fc��J�X�vlA0V�eʞI-��.�fQ�Q_���&T�>>��ۿ�7�'��>�c�'���G{C�N�:��zٕZ�zSr
���e���D`2#�m.��k�<�|���-��K�'�k�K&Q��^�x�Xa�]o
{��H�:Ȏ��ܵ�_۸����7���9�Ev�M6p�\���cKAC%.�?�����ACs�R( ��Z�_�_�3��[,T�8��u��,��T5�7��B	�]#���� �G*\�� j|���P=�l?1L�����%�dDCw������7�q�GK��l��K������(�ފ���K�O�4Ղ���] \���/Y�E�o5���+���Q�d�6<!�PJD�D�V�MV�����l�V��h^�`H���Μ��FgްK�*W�:�sr�Oj�)�ȟ�ۛm�T[�Y��Ů�8��| ��f|���<��y����Av�!�H�Q�Wd��~�Zsb��b1d���d��h�ny����h�E�c�Ep��1];e�?bV��l,a��[;�2���`N_K��� ��j���J��ҥ���w�粠���ur^>��h`�?rY�*���ZLi�d���3'�\�\ I�P@Cz>� �V��(=d{i��)Jx����)Y�{Ɉ��K�>K .74��֮�Ϛ�xy����
ֲ��2� T5l�ѱf0��POzh��.�p��������rH�����F�.�Np4Q�̵���B�yW;+���%Ti� ɲn��E��x�֧��Y�L�S�����CMP�Ȑ����㲏��q����Iï+�9��T�p@"b]Oܔ9.�`Cf۲:�^�Iq��O�8�M�������S�����a�Τ�.���H��PUȉ�&�V�&�N!��Gk�@���,o��N�/�n�M����\�p]f3[��V��?UU�h�c$,�Ѹ�r#��HgϫL�쎛�c� ��ߨ\$�hbL.|9�M:�
pl#�a�\�߻j&�d��	�ão��h�<�'�EBn�'�&䕟!+WA��qN�pm����L��\~SP#2��B�����9;�h\U��a������3=�&�j�0�1^�w{��[�H�7�4MD���\��*�guBE�%�YT�&Z�zާQ%^r�UOg�B �j�zb���!#��x�9�-03�y7r	j�8����8�#���+���c)o@�o�s�=	o���D�|��Ғ�ކ0����	�N�Z�x�Ȋ��g�x���@�^�?.&Q�Ļ�!���n[}��Ո��>��_5��{c��L'��̸jF1xJ�T�9��by�1�'�?�FJv�D�L1@�FM�TF��^��2᣻��)F�*S��_cY��rvWe)�������7��L�� E�P(�c9E�tf�˓7��w��n��֜$b�j /�[�t�6_`rf1��a5R�Θ]��C�����+��ģ��:�n��*���;vfMW/��(��b�V��2�m}����[x���������x�I�\�H��z�� o:72�� <2Q����^�V\"�!��|�otQ����.�d��j�x�onD����3!,���bHP1�#皯#����G�]#���ma���[c9���3N�#H��}|�t'즎�_N=g7/m�n��� u|8G��V���W�����l_��/3����Ja�=˥��ץH�Y{�?���I�0:�(�e�A�!̛�,�z>W& `4�>i�JST$��/�c�����^�l�_cp�Xh���F��]b��}���x�7�;��f�1/��=	( d��L��{*���k[ogI���� |�n�ƈ���֛����裁�x ��r5����~����������`��Ń�!~�%�X��5�{�H�dv�b�g@�"�y�oIȣy��&-<Vb>� ]��ߐ˭C����v}υ�߯��
���߿�*�Y-�j�۲�Oû:�����&@t4�K���|xD�Q��q��QWy�C��%���%3�hQ�-��Iտ�g,�|p���G��*q����L����e[�ns�(_�~��s<��TB�6�&��(�����-L�v1Hj���� jg�Vs�����FZS#t&����4�����[$�A�l}�菁�P��#s�W�S �1Ϛr�7j�!&�a�(,.����k$UV��E��Ǖ��0�:�<6�������n�jP������|�W�Tff�
K�SS��g
�ݓB;�8�SZԠi�.cM��-n|�x�N��o�M��n��~��þjW�K�+���v��ǆ��u+z�+������o��Xd*'�;oy�d�&X* �H���R����d��1�=߆�v�*���"M�����V�f�^8��a:t��Ș�"o	93�̫�������oEK>�!�+I�����)���O]����5���8��5�ܯۘ��y	��[,�2�/��GM����p�k��؟��Z0�Y�4��,p/�L{��z����`9�>@��Pئ���k5�C�xXY��2�d�,1[AT�١�!���`�m�����c5_�>�~��똺����8j����D��n���A�]uø*�Td�Y�W��&���R/B�v��t߱
K�К�T" �3��h�M�� �\OKh/�W�B&)`(�@�@[ɯ��j*����>����{������_7.̅�=�'�i����H:�������o�ަC�Ƀ�9�d��_=0%�n3�&���fWF��D��� ��u{�%�p���FM�X��o�p	tTڍ����5v`�TNf�
�m1�|���Arƿ�.���k���m�}s�PB�Bט�Ɛ�N	��>}��w��dK'��+І����*b �h�]�xr�M7�i[B�32����Pnm�Q�?I�^�Ϲ�s_c%�o:?
�H!`��E'���e�z)No�D��^�y+�VL�%fn�dMc"����5��ԣ�\������w����NQ�՚Bj(kn���7��'�R�j!r7A��.�Hk�0H��)�E?q�bc�/4��� y�
��XM�~9K=��O%>�KF�Rz$,�V���ɦFo��5�������®�Iǻ�rM��M�N����s���]�j�gq�n�GM�\B���z�4.���N"B�Ң��X��kp��"]�����`���1��糡�d�Nۍ?r�f���g�@%'ӌ����xqIi�Tf����<������gѪ��k������f�����Z�G�1�#��79˾��c�#�R�#&zn��;�� +��3u~5�QX�!sF�.�=��Bc\��� 2[�!
�%��
�4�;��D]2�X *q���hԘO��O'�G_Yk�Z('sd�'���rO��a̵s	e A��ٸ�?�B��}[��T�PQ|LO8Y�#�$l�(��Xh��ё_$(n�+�����P�鵅g�2`�XkM9����
y�ƾ�5��G���d*�*f�Yñ�����Z�!A0�����d��ֻ����zi��Ӄ����P������mk�Ғ G�RY����bl�ZFy�h@+6Q���Ӱ�r�1�V>D�Z��g��=�<�쎈C][����B�|�r�����ߑ�DX����i�8�˛/1 ��P���'.NV��Y���is��n�Зn��B��O�q#��|Y�4B\�љ�f�_��p�xG�����)#�b��X��&��؆:n�[Ɗ�8?�n-�p������um�+4*�<䬍'7�X�72af�����Y\Т��+��R~r�oF9������Y��kb��xa����ׁF�1Z�BY�LH��)�Á�FY����AKr��	,���os�p~������>��>k�s�n��K������^�H�*mp`ѓ�=���/�b�z�:;�g��T��n��D[��*�EI�״5ʾ8)�R�8�;�=f@�(9�-�R���"Exno��.,�/��R]m��X�bW즼���F1Cmۻ({�G��+
t'lI�p�*d���\(cT6^E꩙��|�c���	V��) }��cW&�)�}��Qf�Ez|&ʹxw��h=F���.��[����h>��0Q������/���W�J#7�C�yMyl�N��� ��uW���e�y�g�^�?�5�VB�Y��x�Ѩa0�O�k��!��ӊ6�("�c��}���@�Vq����[�I��}���O�6�Δ��O�2J�
-D�u�EP���\��pd�6Vlj��b5������`aHV�;&�u[�v���SX?��G���n+�'�j�Y	��;.E��%|����yn�h+�*��;̘�K�F*79y����Fd���#�h�]����z�p�K�2\�2���?&wq�����cy�XU��13�n������|��q��=���U2��ᩌBʣ;�h�Ōs�,˜*p2 ��k�P�ą��3K����r�'أ��������o��(i���P���J��Y/h�����ᄯ�PH����N��H�]F	�TN�ӏdt�I�d���|���!����ʘG3�CKv��5�:�2'}Wƴb����=o�0`�\^��2Gw&��Z�c;qf�w���,,�%
{?�����Fd�s������k���P��Nн*TQ��cH%DT"9�C�{R	ߙ��ї�.K��?)\9�����>��R2�7ჳ�v���AnY"x�7~�:F{87��꧈1�6�d�-'��جވ^y�db�g�:d�+���b'	�*��\��畁(Vs�^;��8r�HN�����a���/;P��p�����]c(�O@��B\-�+��˟�g@�j),cpQ�"w���js�����~�L�il��d��)��P0/�-�;>��v�.v+�����3+����s�$Փ�J9$[�p����d��C�r�@'n��7� ��4+�Tl���18���ս'N�أ�͟gD����&~�kv���02<��&�����4�_��6�j�bR$j�E[������U�M*W��h݅��2��ˢ�5����\���5�m����`2���e�k�"����(9�E��u���lm�a��� �Ů]9��|y�ښ[e�ʏ~��'��a�	�|��-o�f��]l���Y P[�UˆEi�a����l��''Y����;�#	�|0���c��ꗏ���_��s��ڑF�:���կ@t��X,���޸w�mr���@�v�/H�y39X F�}��.hq�i�<m��A��o?6o[�4r ��= #�BUk*˫����'ѹ*i��F�HWX@��+��T�~W�O���$ѭ�n��'s�.��[�b��wv9A��36��*�����)*,!��+"�S��c��UcZ�g����ί ������S՝C����߇��}D�]�g@|��Z.���o~���A�f|�]ƹ��'|K���_-��&����M��:_7�C��T��A�lM�Z������gC�$���&D�I`�~U&��?�H~$K�Z�v9��N&.'-˽b^d���^��=�&�d?l�������M?�zh4G'/�}��^>3F����p�YTz�H��cK�G<���������&����`|h�Ҋg������)��z��1�� B�����x���I.���9j�����L�f�ɛ��y��DhQݾ�!�=���̡�@B���8�d��{�å�.���Ŝx���@�f1��6�Y��m�/��4)�c���2�_�O6����n4c��J�Hx\|�A5T�y�L�S4�3>�`�����0'�Sێ<�l��V�͓O��L2 �I1���`�/w�i0wʳ������K��a^����U}`�^6���P��mfX�q�D�x2ꍙ΁���|�S,�� h�ػw�|E�
��6� s:C4h[*�C�9���o����7��׶z�)'*8De����-('��b!���Y��L��_&�)g���?h/<�Io��r�?��`Z�� H�է� �݂a��w��<��Ћ�Z!χ�H��T�������H�K���`~g�}�q�71*����e�AS�"�eX}t8�$�~ܓ"Z�XAk�6|I3q�_S;cL�����I/<�wi�;轰�M�tf��~�>�Ė\*���^o��D��,�b�!���a��v[���0�*��1ɘ����1����h�jl5[4�"A�,��K�m]k�k��g?��4���
}OZIm6 �j�ͽ!(W�q͙�5�[��UO.�\�.�to�u���0�@�/Pù���}:9��7�.j��[;��	���Q݃8��Y�"�327�k�QԺ��������0��b'��0��ket�<�#J5?�>i�����)��5�{O�7h�1���X�o�b8�_�n��6��`�{�8��\�Y�����AM/OD`�ɇ�],:�EH��>f�5#0�/>�{x�M�E��n<��ַ����U�3�<>Ru�tߢo�KW�m
�au6�xX
@]ŀ�[&�	�Q�D�->Q�
�u�����J��,������+���-��o�� �ļ�7 ���RkTΥ�z��r��e*5��J�v(��@@��Sؼ� �ڰˣ1+��֌V��e#�ѕ������BW�����\������CZy��F:�1��n�zQ�Ŀ��P|fK(�6Upr9�����MrY�=S�o��j��)�UV4h���U�O4Ń�7��*�A��ƾ94���q � �����JԐjd�{���y�����`��\���
w�KQu���T�9q>���yFi��5z��r+��y�m-��S��6����-�>D2f�2 �>�}&?��x�٣�2f"����隺���B]��������m�l�uj�/O���̤��K\ !���U1]�z��~��C�D���(J�Y�c�w4H;f�����2L�]����\�t7X�>{ߏ���M���+�q��Fg�IV:���̐���?mծ�U�Y*�)�c
s�۶<�1�X�i��+�n���Ơ!��'����	�6h$ߓ�S�����z2A-���J�f&�|�j�$C F��8<E�#:��G��i����U�Ep2'��E)4.K&K�k�����}�w<y��Ƴ}n|�q��Q���Tٹhۡ�>,!�j;�֕fLj��A��굩,���	�b��_L��̟D�\�R��´p#)
yƱBx�&aqx>���<'p��!=�!��UR`WqFB��my�Ztʩ����&]��T�0�����F밪��Ɋ�O�("����*1�AY�;�4y�C�̡�O��Q�M��9K���
4�KDx)w�M��#+'ᅧQڬ����[�,��!�oP��N�3�����?0�u+���t��҃�>=�G�H�T�TkW��01Ex�fS�9�,�+��~#8��4��Q7t,&���/jz�YuMlOv�0�c���Tt��F��;J�����0qQ���W��t��*\L��,s���ʄT����#@NLB��sP+�ñ~���;����m�d/K7�N����W�]�_�6(�ʓ?G�Մ��X\M=�	�L�H�?pQܡ>\0Pef{]T�{Z���
浄�Q�肤&1��-����h��-�0��C%^�y���Y��V��r��5şM����
�>���^�5|ė�D>᫓���^���ma�Y��x��q��d��M���<'�* J=$5��kY�w����ȑ�J�p��!0'��F��n0i��='�dB�:wC�c���U�#��!��D00zK���Ī�<��h)��2`b�«�۝C����iY�s+��jy$~�6�mM9f�\��Yon}�{
����Ѡ�"��Z��k�xv����C��R	[�]s":m���p��A{5�C_S����OҒ�*��x����E7�����~9p�ׄ�8�������A�lq�? �[���?���q{B��Q7�c��B������=u��w? �}�����߶�go�f�>1X����s�F5�]`g}���ؐbѧZ�w���l4��ŚB_rA���샭۶������W+m� ;k$J�Qk]��[R<��{���oC=�Ն/
|F�̺�F�Qʯ;��Ɠ��N1�2 ���y�����j��ߵ#}��I�Oz�5��k��|��]������ ��J��$Ͼ�ȝ�]�F��^��'0;!�٪����[t���͆�ס�O�E�eQ&z�� ��kz!IM˹��=�1}zl[܉�]VX��o *��֖����\�г"����c����v+�ƗǑ�$+gF(��M��y��(�~˶$r��h���-����PINo��.�=�� ̈[;��b��b�΅��}�?IA,�!$����-z%x��/�@Cys��\��0���J��U�=���J��cx��Γ]Jse$́�ꭼd�U; �v+�{k���^�ȹc9QYq <t�X���0T�f�èVh���;�W��`���\7�C|�~ i<��{�,���(o��VR��Z	�欽_���\���*�jC�$}�=�T�}zU��Z����GHqh73�e5�*�z����(�Hڠ進6?���b����Xb�H���j1�G��$�K�To�'������M}-E�xٔ���m�B?�������Z �Qɠ�A10���Z����G�߅5�"�mϳ�J3���hB܎ɑ�` f�{>�j������ّ&�3)��J�`�Kh�ޣ�}��/ }��rO�Y8���2cT�c�z�Lz������o۸��-xL(\�O��d*
ȷ�\q۶)E��SՍp�/�|�'w{$���N6q$/�|��
]��vQ&  q�Y�<���Y���o�>?}0����e;��=;�WǉxoCQ�ry0SjIY��Z7�P~
�UN��H������a�]��p����Ps���z8g��*2�����A��0ad�ӳޔ:~`,�51��l��_�@̓;��`�c��?-G�����G��������6W�e��Y��,UJ�b��ܑ3�X�Ԅ�3�2e�Ťj�    7<5̻� �����x*��g�    YZ