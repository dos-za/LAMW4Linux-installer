#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1521492991"
MD5="34debe6c7044855b896900f0aef70c10"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20310"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 02:04:14 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=128
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� N�]�<�v�F�~%��2G��nN� �IɌ)�KR�3�H4)X��%Ϳ�ه��y�W��Vu�NP���3�+>�Dwuuuuݻ����6��lw��v7����Ic{woo�{O6�[�;O��	Y���<1tǹ��c��K?u����;����������-����������_�S�F���:�ٹTU���*U����4t��95��[~��K�}�1��7-[��oHՖ����̤Ό��k{!tI՗��u��f}��-U�0b�46�Ʈ����Z(��� ���9+�21�t? ��;s}��{͓W0=���9�	48@'W��y�'s�'2��:����Ug��W�D�=howώ����9<ir�7�b&'��I�t4n�z�ɂ�"x�?�hr�~6�L/:�;�t���3�������8mn�,����&�\%(j4��F ,U�)Po�t��M���>��9yCط��U[��"�w�s�T)'����+ j��:ns������;"�Mi5�k��%�K��� ȷf�ڶ�(��P�-�7���M�2	�����L����["Ub^���y���u��+d��� ��;��uNg0�`߇B�Yh�Ħ�6G� g��]6�v�@���4���=�W��'�E����j�K�	-+���'�F6�݄�T�Ů!Uu|�#K_0>�C��O|:�̡�ߐ~���ն`�g�.���"�b���r��ii׹�-~�j�V�#U ���$pxȈ;�3�7X=����R������4EZ��ԩu���d
8�4RM�,�a-�M�k9�m:y���v�t��V�!H3�aީ�$�O.Q���D��:_���Y�e�6�01#<_��ӻ��tF�sI��Ѡ��U�E?�����y�C[��|>}�����lE�ra�|�P�v��k3 �z]>�n$~��Й�B���q�|�����p�\��R%��XR5)��X67��d[ycD���NB��O��.C=�nPp�R%��H`�H��}��X��y~��1�I팄���R%ka�|XߊZfcɓ�����p`:2�88�F=��@�����2���zV������=��_��ܽB�2��I�R�A�x>�-x��U~I��]ŏ|��ܰa�;���SK1 �����I^
���_M�� ��r�#�ckk���;��G�����W�d��;"G�^��7Dm��渋ۯ��?=��;m2��GI0����p�q� ��Ga���d
Ϻ�$�>>�]Ü���@0���)%�˂z�,���{��DT�U�	�W�CG�f�D>Q1ڠ�i�2
�t�\m��2j͉�/B$�����`@�ѭ�����yxl_U�au�U�NQAJ�٬��V�|���#˯=�a<�=�c&0^E��>�͙�B��P�L��U�~���:�"�~�=Z�i�y��߬��h�=�����ϰ�LC�2�_g�_1����Y��[���c��3��uk{U��(�<�	3�	tH}GшgZ8��dA������E<*hO.��4�����4�wM�+9v�jЀ�b܁���%so�q���%��z��e���M�Ҥ�X��S^��-�;W����pML�����T�M�BZwh���a���X��O�i�!i�P��`R����ġW��L������3��@E?>|$e�LJ�i�dl�7�y<g����qD�.��ܧ�Ac�]�M*pQ�S}jQ@<ٞlN6�&�2�u'����&�!�U˜�@Ù���c0�!�(���l�(�vz�樣��N��3u��Z�����2#��b���΃��s���x�?�M@�,e�K�J
�U. 1��+/j��O!��:���R,�C��.%�c�w�=��O�(� 
8z�S��6�/3��Z���sW��(~n��XQ���_��rאK����b�1U�6�7��L'/P]:�;`v����9r۾ UQ��6�J�\���Fdy��s��ʪ�6�Ö��p��H/Uyƛ�'pO�E�]Z!��2� �
8Y�n<<;}AC>�QX�ϱ�em���L�5�	�d�v����[��]ut���;��Lwz�ӳד���v�Ct
�c>HG����y|ǍcɌw��^�A����%�X:}"����+��G�\��P������-5�INCmyHh�!�!�*�G4+�7& B1��t�M-�s��-Ny�ugA�s�����"%��.U��Af`��������G\[&���d�wƚ�?k�b . �ӓI�􋈊����H �<�z��I�������Lb�;G���LEp�ʗ1�+�4�Z��w2��?�:��/r`��Vl4~!~3��%�` d%�{ϛ]�qYv��m�8\���=��逋t|�����e��W��S�=�O��;��eB�Y��%�����J�_��������|%T%^_��e��}�e\άV�2��"\����.4����N�><Đ�lwf��:��D�����hI�˨�O�V��x�<MJ��GS��R��M�(3��M�T.U?m���l."Gr���˝��F��6�;�xQAVnaf����u�Q��W�� ��"�R��[���U��^�xr�G��<m���$���,Na��57[��jP�cgS���9��<</��З�$����<�a� �ƥʈ���م����;Gͳ��Qj[/��tz�/��a ��"��M�������ʘÏU���/�f��M�P�W��������n?�+�w��������_K��n��X�%�p%:o,��փ��y��̩Eym�#ă���FU<�^'*+�u�z�+�wt ��>�3�^rA��N0'k���ѯ�q�D��M��Is<ޚ�K���?�윶�ß����h����<�g��{V� ��[g���Bx@�(��x��q����P� �Λ�F�K����%� �Ŭ���|7(��t�/�y颴$,���l���o�����~�9G-��g��|��(����k��c��G��x��x�F,��=��R����d5�0���_[G��j��N"�-g� ��M4%�p�������8Îj_�nR}j*Q��U���	J���g�����Z���IaC�mR c̞M~V���!jlp�kA���ZN�N�G��)�^�*�EF�`*�5�(�o��E3`��rA��O�>��1~`��]��Ʌ����\�H���TA��6���� �B��q��5�4[���@F��l��A},^x�u��$��Z�3�FZ'3̹�\P\�0<cB�����T�Q�nB@�H��D�{L�L�u2!Ia8��6l :�w�hh�	�DKtD�/��Mk�*���3)��x j1�6�x@�D����x��׎��v�#��ȭ��ؼ ��_Bzh���D|?=CJ4����x�P$`$-�\˲@�<'K�ޛ(,��vf�s��5	R�)�7#�l��j�'���3!+�!�&�M-�Z��#8�v'K%1(k��������F�I�ȥ4��&�l�(/��k�H:�x�2���S<G��
���������Z ��;��H�-.F��C�4���?d��.Q�t��ܐ�/Б�)�cXؐDլ�P�iY�[x{~�:�MtUXA��U�f��PM`c����J�D�B�]hD�5�����\���\���~���j��������l�/�:��I�J*��"�9k���T��z=/�ֲ��)���GyT܆ =��c��B7!�������	�;0 1����m�?�n��y������` 7��5#^��O�! �61"Y�X��� �t.��%��%ގHz�+3~ �H䁵l8�ɵ�%D��)Rs1)��4���cqKD([R�NN��Zy�]�:sw7J�>n������\��������?|1����E=�3k��q!f��O��`��:��-�3Gg��N�x�Z�AL|:NW�y��Ƥ?��A0����Q
���OۙC�����&�e65�P���d-AQ$&���`���{DI;�eSA;�_[ǯ�8�;폻G�NF��N�70�7��:(�+�t?	����;� }r�W$�rr&^�M�0.wT]��`���[�!���}R&�o����=P�`�����9�X�(�=��YJq�9�W,��_�kͣ��I�,�#m��el\���	���m����DT���v}�Ug����/v#CXB�OΩ�=��
Ҍ�
��{���=�b۴��� ���æ͍�挻A�E�z<�N����h&|E��Z�SݦZ�%r��Y�����5��x@E֦( ����("�RxJR����)�4���\Ǝ�ԝ�_���D�zՄ.��'?d��P��|ܘ����6�A�DӍG�f�oZ )5h�8�r=�u �,Cd�s�����.��\ �s�5�ޫ���3Vd�	l''+�ׁz���j�)Z0�}2��W���Lk�� 6�[|Z�H�Ti#6.�=3נ0��߈U��7`k��
��@�9t�S=�W;�9�3����7�����r
K�����;ޥ���� �=��R�B�Ձi��"np*�.)P��]|W�u�߉�",���59霞M���I���f�����I�8��J;`�9\�'���Ÿ?৶ �Ý����t��}sN-��p\����r��P[��"4��3���P`�R��������۪��IhK�I��dsC�ڶ>�Ey�~�Xx$�(����џ`���{0�mx��Pqb����i��H�/�ZDe`A���sl :P"�J;pY ΅3��k����䏻dy�ce���P
E�IEn�����,(�ʽZf��ā� ��^����i���������J�?��!rT6�S�@8�E�\ɧ2�ؓ7r�s%�q[����9���ǻ;R����R�"���R�%KG���<�H�!���6���
���8A%&����'� X
�)�� U��?���0���v�$�������橇,5{8�����%х$���]4����G>D�D����A&9�Wᬄ1���}�h�ʴP ��Y�@�����I\�D�B���|���_09L8��b�S�υ��0�<+����j�d�D��-%�qr`�G�������5��]���%"�-+b3���pDm+ʶ��x��g��f3�Att�m�#�Ő���S��"Nj���jF��ؽ�Ν������5����O���C�
��/4���3�޵��4���+n��
�+�hr��;cg�_�]��Ul��"����\��ĉ\�9�t��rwQs�Ӫ�Y�G�o-/��o⽃�/e%��*�TY�J1���FA��o�?"��9Ж�w�g� �1����Y8����~f])
�V[t�"J�~��O5��],jC��῭ �	_�8׳'���޷5�q$k�W��(50CR+ H]F5�a�c� mϘD�hRmhl7@��h�Ή}ؗ�؇y���KUuUw5 Ҕ�g���ը{eݲ�2�ԏe4)�xE?��y%��:>��K������(�'2d��i��.�����s�T����V��3�����1Y��&oP��t��-�Ql�-�]��{	u�%�����8�Uv��M�X�]�3�3P1��^٘�Ξ�PE��W�>�?�Z�m�U��Y1�z��#�Q fj���>�rfTٞ��ՍZm:B�*s�Z]�W	��\0I�ڨ�U��-�n,7N��Ol�����Ć8sj����y(u#_��꬏�Ӄ��7rSY�4s���3�MUY2%�k��wx�#m��kW�3ܚ�߸̬��nYq!3��^�f�y���[7�����ɐ��x��t���'����9��c�⿃~����Ǒ'6��J���������"�5�o�����9~���j��oHE��WF)+��JB��A�p���~֓�'BUn���W�g�F4��:I?��︄�\��\���.��	����?��wu���n��>��XIF��Oi<�)4�]80>e��w����(�(��O�7����\��Z0-��O��З��N�,~<����~��_�~8����P~�,�O��/ �����I<���b��s�b2�I�3%Iq��ʾd��ؠ��ZH^�OƧ̒�}x�DD����Ӝ���`��(+�F�`X�&�I��G�F��)�d�����V�Z�������в�(M���</�a�J�J.���x(�k5��J�u^���U�Sug9�$��(+]TN��@g�����z�j��ݑ��������T��(�.��e�Uȧ�U��^�}���cSv����|�A\8Q�I�WG���E�8��|�������@��0b@�g�����Z��ڍTF�P��@�*��TAe�\m%�n�~W�9۰X-�)>4��ԥ��(w�|A���o5�� �ͮN��BRԱ�Q�IV��������#5�`��%'�E���{�x�n�pT��eήYUe6SZ*�'#�R>w�NR��_��b(m4?�tw�!F&<�������=6�C ~��mB{;n5�9^L��i���Y��,Y�xF�
jl��$��Ֆ��ir6�Y���u�H��$x�ֳpz�!���/#�BZ�wV�1���U�=�i��na���L�ufd��Z ��W�W���a4N�l����� �QZ�\��ʜga��yh�f�}d���i�'0_S;��Y�,�!!Pj�͕������݃7��W00����vE9k�FF�ݸh^�*�Ӄ��ĕ�[*�Z�s������i�Q-�4�x���b�Mw�d��	�!���aU�����,(e5��n���O�{*u>5��y�J���VK��+����d���rh(Ԛ#庂�ʑ����Y�v�g~���M ϲY�>W=�W���v�a�v�6k�����0��Cor�R@�j������ṣsf�$x�ȥܪ�A�:�_�}?fV~m�n��c��dJl�C�s���BE)����n��1w:j��oGC�䅑(A���p�(ƛ�s$g1�����X��&A3��ڮ�\q��զX+#�1�תk�p�w-�V��+���}������mE��<'�����ªs˄t�{;����9+X]ϫY,VS!�N��~s]6�%������\���%��l��%��rr�Q��d�^k)�m
Y̗�o�"B�ۥe�a��T߲[%�ǜcI��~�	��6�	�����~/�h�)t��S�67UET�;�J��v�F_��);2
飪�F_���O�NU��U(�1k�����q�@�'���YW��UV���bۗ_�5����߬��p8����l�'�_՞�|I�|��,�h���$�i�!A���=�-CkcM�S��6�yiH�9%�5?!�K_�%E�D�Q0uYe{V��E��F�zѐ}��<�����<��c.�E�(=/��lO|W�H��0�~�f�M:@q}����(��.>ץpN�3n�$�Jp�����d��VW`\��UiUP9K���,�_��Z��Jiu�B�^^@ɡAM�
ظi�>Vy���Ȝ���s<�����I����S���e�R����5�ј����Y0�%F��Դ[ D�YNqO��mR�'<�����IN��sQ�����g�<����ou���/��������������=��\����m�޴���o���C�L��n�.����t�צ$���\]��w�/�ރ�J�i�j��[�����=��vg1	�\��x'h���T��촷�˧�����pY�����9j�ֳ���+`E�����|�~��=�Y�Yr$��q���2)ن�p�/'{���,��fe3!�K��+���ܑ�{� ��[�ѿ�Co-���0���7���!=�e�rާ����*/����k2�<G�2T$w���#|�!F#
B@���3�z�6b��[�k��*�e�=.����/�q��|���@�E$Hd#���i<�?� +
����j�MBV4,��Ӂ�i�SY���5�&#�8�i�E<�E���� ��ځ�!����[���e�l���V1�.#�B���U��rB�j��*�cou�6|P���b�d_I�L~���r$H�J�\��I	tU����!0d���P��Bs˦%l-��m�TW��� g_��j����^*�Xw�`�P��!�m���&���#��Ee��ӭ%O�ڋ�
U�s��ZWZ����i�!>���2�!�%$�2K�Qf��|j�K>�����v�/k�?l��j���!��q�?�`0�58"��f�UYT���G����䁄堅���g%]2������wz۝����T92��*���`��C���]Ng��{�Ձv'� �&@�J��&�,ѝ�Lj[I��C�$�5NR5�8V	ҟh�Sr��tʠM5��nd%�R#g��Y*��E-�ɂ{��}�OP�^�ҧg�.C�A����5b���J�E)����`>�z6z�N�ڪ67�o��aEe�|Z�ߪ��P�3��\�`-�7��q�:R�@�5k	D�6��1�<<)d6!3���u 4����K��8�D\GC3��^�O�mƳ�B�1�܁z�`;$'h'�� 0=�1 ���z��ʀkǱi��]���I�s���2c�1�^�|��#���Ϡ�~w��m I�K���>�fe*䲍���l����ѭ���6� ~��iA�!�;*�Z٢��Pu��Z�8#��d�0��ͦe�P��FFkZ	M��sGN�B7�kj�ͳ�*��#�޻͇򻢀��������W�	�z��ɦ�̕)�7e�L-��5�A���Չ�"��Pxq0�V�[B5x{Vހ�y'
����O(�x;�N�obF65�ߤ�y�zOWDBB�˓d:"�h�8Π�ItC~���6\�`}��u�B/�r����D�P_�!br2B'w:�X��5�ӿJ�'�����|��㍵����ǭ�{�߽��;��+-f�,_���k���r�+���0`��g��.(�����/$�,�1#;rc�E�s8[����|ˍ5�Yne��e&9w��wY���P�-�Y����A_ȇ}i�#u�]eՒ����+ZQ1����5	�oKD�B��I��|g�rlq��3	��d}��$�d����P���5�|h@l���UU�83��;l�
���{
�8�}�����CJ˿�G+~�L`�yP���5��r�gY�t9���x�z��h�5�K�'Z�p��5m4��l�XvO#�2#��S&<��D�|sW�}p<�^L3�R��x���2�t'�d�2p2��e�M��T�S@����.I��܂�}�e�#[7����ޛ�]^�2F�I6Sk9��֓���0�r�\�+�� ����/��g�%Ȁ�Mu�����s�����%���l���J��R���\��>/�u��EuP	��L�+�=Ɠ��]G#���̨ʜ��'}OW[2�|嘇.f[�U��LG"d��;�[���,�oU�r� �x�鷀*�z��8��߆���t���P�����!��K���Y�q{��9�>������}F39��|Y �z��`���Vi�֤7z���;�/�����d��p��)RA�K��$�y�$ƚM1���N����6��of�_�b'<���Z�p���󍐝�{��$��V���������y��ϼ�NuQ�.H���|n��T�}���Sna�$�)���|��uF���l�έ�
�;�*���	s��9�d��n0�qZG��L\��gȫ���+� o�Em��ECg�>��>�����>{��׆]U�l%;�5��ԧ�����-�F�pkiG<�����8N��g&x/ѯ�9qG?J��O����Y<����! 0��0;��}Z�����^��a jx���{�ܖNG��iOLO�!��H��%z��h^�@�4�D�|���_A�&Nn��c�\s�ȭ�D�e |ܘxuo0I��r&H��Zm<M.C�v�P{�����|H'��m�p�N�� )�E0L<R<��B��.�����>��g�_I��u��?���+T���.�P|��DJz�ᛥ�2�'��G��L��>T��'a�C��HXA��b�+j{��=PI��OG�I<�(UXJ'_���@Z��;⟶��f[��%ӵ�$��Zb͑�����U]��Q�i��ƃ��i���~8N=�c'D�9�>Ҝv�3����\�xY���w{+��g6������ߐ�o��_�c��kNn�C
��!TI�)���z��^�o�tM�Rd�!Rg��O׺�vG��m��3�����&C�)��cOj�Ң"KH�lº�>0�JxAε���@��DGq4Y������ ����Fp��6���2�-Er[1�ԼQ�ޚ���.�5�V�����w2g]�����>"�,c�|��D^�R�ˡQ8$�5�8���t�
� $��K�L���+�"�PF���Kp7K�F>.��sm=�nW�v_u�%�0[߰�g�u; ��u_Wf��}����k��=�߬;nUaˆ�#�SD{n�O*�͜����F�9���!��$�S2�:�po˽��[/��T=g���~֕��I��#�^��S&�1��guk�YN:{[���ʮoK�+�td��܄������6D��>�~���^���8w���pI�J���`S#����v�M��VZB�I�u��s�����dwO�A�%pF�6��8 �0Iݎ�a�sq����2�U�DU��=0�V�j��GNUqFu	���^Qڊ.�Ei�TNі$�,B.B��|:�j�q|9�?=(��'�\�B9�j�E�b1��]8���Q*���w=R�V>�r�+�9��Kp%7��\6ε��\�9�{����v�Z60���{�'ڌIV>�V3����VnG���ʒ�Z���F��M� 244ɱv�v?�ڝ�h�5���5o���-����;�s	�sDT|�-)<�#'�*7UXN�ٽ��T4�{�����u��h�+������%�����E�S,��Ө�AВtvw�D���PU?I���<�|�Dg�z'��F��	A_�/�Y.���qtn��<����ø�@FPj�� �@(W���@M/�>$�(�D��J��X�2h�R5֙�����g����|S�!�?�EГg:Q�R��1䤠9�M�\j�̨|��)yG�'��|��t�E$����_:Cw�S)��Z�����y[�}A��Yb�J��aT����G�.�do ��3t�9tB��ui�~���X�W�©�}�����?��^��t\����������X~���GI_ɼ_|��s�B�b�x���*O�>��U	�LU�y�p.�y���I��Uz�FݤUR�x'�O��hr�D���\N�#/"��ËqE@ �Nr �ë򄮈:�h�(����WY/�ӪRo�9�P��&t��gR�<f�p(�z*�C	� FE�t�W.��3�f��0�o|�&���o��}}��>�=�i��&*�*�%Z"�	���PWo���/O��?���w��� H0�1j�&��(��2{l\B�-��!�H��)tJ����Z8�� v�K��8�:���G�meR�~�R�ދ<-?� e}$�?��4��K�sdo:i�"CB��?\]���6����;I�k��V��v�H7�dl��2�E�O���tq�K#��f	!`NH����At9
-����LǓUsN�6�e���BӪ<�kL�K�d:�9[�hʚ#����+7����7�m�Gm�V`d���
�gQ�Pj�A!k���������l3�L�u�٘ś���'�A���6$��ɒ~�-���m�٤��Dw����1�)����y 0.-��J��K�م�� ��h�F֔A���X�%ņH�oOd�����^y�*߷&UI���g���ar*t��T�Jk��B�i,5vL!)��H���,����ު?�]��C�?�����andB4f9z�<h��p;K�o��r��\l�Pf�#��]���$+�!mӊ�mcN���"K3��/���[�\��H�c �1�Ɖ ��w��E���Q:�W	���0������l��a�[!���%}ַZ۠�\�^����B����#-�@�S_v���!פrJ�Ex)���$`���Mୀ��<�r�v�e����W�[Լ��M5he�![⛵ov��}56�z>��C��A�{��=�F�;�A�\��~�;�;[�fd�/,�Y�G���X�����|K"�'�\��˿ͪ��&?3q��i��7��*������	,�x�;��ol���[���$Ik3eD�VT�����,�����\��FG��J�}T�-U�
~-Ҝ��ѹN�@��������2&E��!g�p����蹽6�H	U`����N�
�\D��_��Ym�����h�4-3��%� )�w�N8�v��T�QI�ͻ��@}���n>6��V`hje.��P2�ic"�ƻ���r.��x�P �}�8�u8\�)�Ԋ�<)g�I�̷)KNg����Ô8�&��DO�-%dzU}�-+.Jz�һW����*���i,�������#��y�)j��n��W�SH"wm��}Z̓X(w�x־p���n����b#�Na>����O�3U�ق$���"�1�q����U\f��V�a~j��E���z�ӔL?�����yC�V��$��A͓�d�aX@�[����߫�b"�t�/+�
J	�����*�}�P@>=Ȫ��Ә'mxE�叇�`�X_r+P:g:��`^�{i1�nG#�lz�S�]Gt]d^�l�fDs$)�~p�	�[0�~�S�V
>���Ki0��b��iw��9��О�x�[�"$����2zu������|A���P&���)N�!A��AI�Jk���9�X�?z���c�ʘ*��=3���J���=��_�^�-�c8���>&���f�YT�0=� �B�3lxi'-{O5�l(�!	���[���r�YW�-*М�1�	+����e#ז6fC]Hu�F�3]5�9��Y���6�����Ue�"U�}��<����j�;�_�&����QO��,3Ї�$r����������JrE������3ĵ΄�*�d&��Lp�I�o
��s�V%�e
�^�4���+�:���
�k��V����HU�@�w�S��/e����j���+�!5��^|��� ��:|?
`ѕ=Ue���!czh��2G�b#i�)]���1�ռ1�e�����!���^�N4g�/�k�������x�'�K�^0ǔa;�V�n���d��*9-�AEN�n�+K{P���XmJH��w����h��ͺ�p��W�n�PJ��ԛ�9������L����dle�L��q��t<y'��8=l������Z�y��g��^������6:��3�P|�إ�h"Ir{ԪE�P$�J�j͟��b�G����xX�g�ś���mD.}3u�.�a6���?��}�{��~}�:q��;m��Wأ�T��̗ky��~�7+�F��J\�R2.o�ivN�k�H(*�Y;��h8n�	��1��8���[*�?�!��}����r��O�9��V.8D%Ck[�[B��!*t�+t%���8_�Re�&Q���iSS�Z2�~솝bɮy~}�[�d9z}�A4�6[�ň��Y�1S��Y���J��/�%� K��PlZ)A��\|Z%'�u	vEf'�$Q�f5��k���"L���-8����Uv��9���Nt��N�#)���C�8��ap�&�{��j�?���t�[8�]������u��E�� �,���>~\�����kO����o��]���܉���}�Q�%�$��rJ�����Ӌ�UtĬN
��gI�W�F��ո��Ȳ�Q�״�� �B���|�^~����
-I;�u��W"O��y}��i���<�A$Jr1���ag��}��o�Pb��5FxĂ��Z�3F�!C/�VKB4v��ւ`!p���!��@�!d��2�|Z����Ilm��C�ot��.�JP���ep���dv�՘���$\(j_�2�
3|���7n^�Q�������!��$���ZkO�[��������n�?��-}6���<I��
o$�I�_��kvE$�GZ�ʛ�%���.�
��P��*@@���Z�3�Ǎ����(I'�,��`s���-��Y֔UϾqC��
_T�b���������|�1��l�Y�l��E����W���6����\�#�gJ:L�qR�L���~�󦷳}��&E�-!��� 	��'��2� �0"}�)�i��"�k�FZ�xK0��]�'{�:ej�pW�����(~&I���p ���$@��J�z��u������C	��J�'��+�O�kb�[�x��`��}����ҡ	�����!L���-�r��3T��{��0+]S�
���F�9xk�̲��J��.P��7(�n�΅�ۗ/���f
�:����,e�,�74� c����#X����n%5�0��Uo��wxtl4�B��� cN��Ӡ>�N�)ΒXy���3ρ�g�܄��FK��i* �:�m��`��J���6��ן��	ۋ)�gf̉vmkg:&g깕4����n�e�0"�H��O�q�=�=�(����n�Y[:�*�m��ߓz�������L�vMb��q@$ڪ7'lf����DN(,�mI`�l�.������O�q|I0؄$lr�É�OR�c�n�I�=�lـ&v���N[���{	����)xWK�|��*������U��ʝ��Nͣ$�)<���JE�<JI�qp�}�-Laf[-.�e�}p��=n�[�ݧ^#��)K�FQu`0�Mb�N��DϨ�zsD;\>�n-s��gX�[��$�6�~g~X���ҞZ��&�[��@�� ��"9� ��o��@�y%h
���Hu&��u��{T*oV=�$�0	G�JOɲ4���lʓbΈQOi�ɡ W�hN<n��8�-ܪl/��՟䣷|���^�휍�i���$*lh��n�HB�O�~����2=����~���3tU-�0��Q��_��sCkT��/�0�g@D���ljc\��|sa���C��gY����|}I��}XQ��ME�T��Zf@��S�:J�#�%�`RI�A%4���s��l]`L����n�����̛y�,Z2kx�b }h(��G'Ҳp5����|M$&��'Ư���W�螼B�X����i���u�_�~����e�AM����-�6Ư[�}%���u��|��jlo���o���1?cχ�R�S�n���sN.�2�CzXT}0~G���0H�k��Yc��%�r� O�ek�]5Y��Rq���9ۋ^�����H�~Sm�8�)`|��8V:�7��ŷ۝]�=���]�g�>�X�	�k�ݣ�����,��6�Տ�'6N�i�v��tt� �p�Dg��Z?�~��r�6+�x�q��lza�Q��/X#�q3��0I'�;��3b.ߞ�TMxn\�����}/ü���h� �"��]��N�w����탁@TƆ��� �����&.�?���طܪ�r�D�HE��"�"�ٵ�B�9m�F���H�*H���ţ�ח�����
�M��~��R�*�捾���"�JHǻ0ž��=�j��=��R���u�י���h|x���9�.���|X&x�! <����8��;�O?��\W�e>I�8�\��v�Y3��zѪ���c����?T-�>q�ͧ��ut�#m�
-R�Ͽͯ�x+��8?MӉ�L�j/�V�X!��s��1�S�2�
�ʯ�{������'�ٔ��0S��ֻԨ��'��Z:�zh��x?����U�Y3U�pgu:��1=���o=.�9Ӱ�N1:���a�E��釼V���J�-����~T�����Z>��胓�W�N~���9��,�d��\�$�՛O�MUJ
e�F���/���us�����Zی��������˅�Ӕ^w��%�#�Ǟ(ڼB'lv�E�����?P��������l� m�����=+5�;)ȩ�����U�rMx�P�C�:���G8�o�ͪ�)��Gl�E����$�S=�erBC����.�=9W|݆fv�w�\"˾]�zbws^͋�k���'�1ނ����U'it�K��3"�K*>kX�s%�z�,	F�o�Վ> ����Ba�W�+y(������屆�Ֆ�k�*C�bd���m�VXGh��,Y�Biv�d�2�gk���N2����
Q{��5��ȅ�_A|�Q�@����R�S2>�V>�]�|�R��0粞�:{s!���	,.k�y[kH��ߵ�����'�/p�F,����G��k��E�zY|������nU#k^�W�}Q�O�,�����O������^��^�g��ϭ���~; V�O%Z�U8�Ǩ�)��U��#�FSR=�"����&�A�r�G��:�͊�X����������Y���"ЙB<���C�#�H�m'�f����Ö��>>�/���<�J�
�J�b������L������l�X	���T��
����y�V58��.*kB���ri�Ҥ��3$m��k.De�B�VCڍ< �=�0�� ����Z� B�p�����9ج5MCWi\z���k���~�`a�Z�U3�_����z]�i�}��%Wv���J�p-F�"S��b�G���i�%���tk��^�mPA�( |U�{p���Sg��Mu�t�y������ 2$'�9�N�͔��P���YQ7���.����F}\��eȄ[З��\��x�x^V�󪂟0�Of���і	頊����?<�36�R�p�n����T�~^��W#QK/�ƴ9/H�.CTHD�ll���C���p�"��a���M1<xb���>B��vp:	&q��qL	�o9U��7ւ���)e�8nr���A�
|�+SY�-UhK'��6'U&0��)��w�\��{kݢ��g.�����0�f��3Um$q<��鶟B�h�W�����ۓ��`)��75��snn3���˜�G���r��FT>N�2�������B5y�SP_�`3k�KIH��� �q���~@�8��yNӠ��OC��݁~����87������R���oi�#,
e���SnܙV�,qQ��@{�`B�r[�8��BLY]��`�j�L��M�A�F�q�M�	
 �$7;$�TE�X1�x�#�/�S��DS�O� ^�>Y�#h`�S~����4��,�0�:�K��I�e{.���(?�A1����:ڮ���.Z=�m�u'Evb+(��e����	6Q�����i�^cX��~���'c."<�\��Շ�fK����w��|6>.|<���P�'�����)ҫ��ޥ�A2���o�)-�s���k�u�j@�>Z���<���]-D���~��_��~=�(�֖����9�_�������d��2�`��س\ыjKT7D�Iށw�N�]��'��0�NT�E	=0]Lt���;	F�@AJb�(���G��}��0�[��&�N�F[_�l3�asX_�eRM��"�S9��n���2ۜ�e&d ����X��2����E#�D�~�D%WO5��iL�n���L~/un����s;�{vsӁ�$�-R[.."�9mf �����;	�yFO��Jȝ�|ٓ�X�|yY�#����"���Bw��nO�ϼ��ޘiv_�HWX,�s l{e�.Xx���/� ���R�f-�$������?"Z���K�W�
�Q¦)�,�z�I��*䔤��|��^��Q�T�DuU�XTq�}R�i��ވ5��;�FÎ� �b�,f��?�����[�����i��1��r�?�操�����������-�����������T���㿾��̿��77���������9F�z��X#��mH�g��gU�=��g� �s����3�TC�;^��W�~-��۞�x��N✒*e��uw��ݚ��3PP0���Xftz���~��?��s/��J�L��R�\4.?yZYV}�ҭ:��2KXa&�
�nZV�q1��I�����iw_wv���e��o� �{�G��](����X r��Jy-�G�ћ�iX��2ƴ�̜�iY��~�'#��oǆJ�z9z	���p��K�{9R
���C�Luk'�䚭;l��T)풼��d֐a�Mo3��P���������R�D��6���l������A&�Q�&�a�xil���[0�u�U8�Z(T�Sפ"�k�:4�k�h�i�KN��<�2�@���G���Y�K�on��0V�rpO�j�Я��_��C���s�++�-Δvke>�v�]V=1<��)jV&Y3Q,P�0)	y��<)��](���s"Rt1Zm'�_v�<~�J�zq���o�	\	h��y�q����#��e
L�0��_�km�Ik������?~�?Ȫ��@��E�����*��@���Ӊ���ELHO�3`I���yW����Nx��� �<��1~�-�H'I<�|y�����EC���� ���b��ŷ����U����s�"����`c������yрd9���6��h~�N�	{�*n�����)��|�{9�O��'�u3��~H��j�[c0�n]{jFJW�Oa�|��IkMF�h������SB���.��,E
J�k�fT�������؂q�4ё}8��h�ge�9�5N:{3����D�?�bޠ?(��V62.3/�|a��3W"V�"k��f�?# �8�x��@
<r<�M�63O��n���8�����7�@���ܧ3?CE)��bC���~��b bbu��*o�eJB��y�G�9O��6����B1+ԊU�}<"_i3���
i��ę����k���vg��iC����Am�|��k�|}y��+�ѩ�e��7-�������Ӏ.n��eGZZ3��S�Mt6�5Δ��O�BL�%]�\w��y��k0B��5���LXx*����1h���>6l�&�\�B��w���JH�&��b���W�A����$@kN;���x��c�Ъ�����5׷0�����i��k��������Ç����M��&���\�@a�D1O��_�D��d��>���Q�_�AH#��$�?�}=�!fTe4�ޗ>T����И�"Iޢv������,F�a�����:��rj���#Z7fd>NE�ޘ�"%%� w	(_+v+7\���1�w��Ϝ ���_#U}�¸�3�|䄰$���$'��5��LS"l�YPn�,��PZ�5/��
�l�� ��Tx%۲�\s����
��ASF�rKe�b�d�[�ݛ�V�-6��D�F���6��b�,^�3&�n����Jn<k#�� Y�D��A"���SBg�E�1#�˟�S��4*��<Z"벞��]�%�v�V�q3�o.薒n)�'��q[%y7T*[���Rn���@H�}��Lk(��������4����u���K�'��h��T���0!G5�����Y�q�������y7C^��`�ǋn�E�4ض�(,���8��w}uu>D�_	�U���u�W!Q:	��7���$�p�5�bWk��z#�rj���8�gp��2�F����߆i�T��]�E#xIj���EtAי�%�}-Mr�A4�f��0W'�댚2Q�,�h���*H���u�ŨB���p���o��m��P��n�"3�����ڳ�_��[E���^]2�[�lt6�J��?�?�f{B�^dѓYt�a�}<A��j�DVvy�����<Q� �G���Q�\���9�ޝ,�֑��4pH�0$r��MBh<5��ZUD���l�M�@���FL&�OWJ���&FW˙��h�Uc� ��
�Kp�I�@"�H�D�3��%��
9&a_Yjn�<_������������������������ÿ�56 h 