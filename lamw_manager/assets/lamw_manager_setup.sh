#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="140931668"
MD5="97df49b0e338c771cfe41fa11b17973a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20312"
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
	echo Date of packaging: Sun Nov 24 03:11:52 -03 2019
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
� (�]�<�v�F�~%��2G��nN� �IɌ)�KR�3�H4)X��%Ϳ�ه��y�W��Vu�NP���3�+>�Dwuuuuݻ����6��lw��v7����Ic{woo��l��[�[O��	Y���<1tǹ��c��K?u����;����������-����������_�S�F���:�ٹTU���*U����4t��95��[~��K�}�1��7-[��oHՖ����̤Ό��k{!tI՗��u��f}��-U�0b�46�Ʈ����Z(��� ���9+�21�t? ��;s}��{͓W0=���9�	48@'W��y�'s�'2��:����Ug��W�D�=howώ����9<ir�7�b&'��I�t4n�z�ɂ�"x�?�hr�~6�L/:�;�t���3�������8mn�,����&�\%(j4��F ,U�)Po�t��M���>��9yCط��U[��"�w�s�T)'����+ j��:ns������;"�Mi5�k��%�K��� ȷf�ڶ�(��P�-�7���M�2	�����L����["Ub^���y���u��+d��� ��;��uNg0�`߇B�Yh�Ħ�6G� g��]6�v�@���4���=�W��'�E����j�K�	-+���'�F6�݄�T�Ů!Uu|�#K_0>�C��O|:�̡�ߐ~���ն`�g�.���"�b���r��ii׹�-~�j�V�#U ���$pxȈ;�3�7X=����R������4EZ��ԩu���d
8�4RM�,�a-�M�k9�m:y���v�t��V�!H3�aީ�$�O.Q���D��:_���Y�e�6�01#<_��ӻ��tF�sI��Ѡ��U�E?�����y�C[��|>}�����lE�ra�|�P�v��k3 �z]>�n$~��Й�B���q�|�����p�\��R%��XR5)��X67��d[ycD���NB��O��.C=�nPp�R%��H`�H��}��X��y~��1�I팄���R%ka�|XߊZfcɓ�����p`:2�88�F=��@�����2���zV������<��_��ܽB�2��I�R�A�x>�-x��U~I��]ŏ|��ܰa�;���SK1 �����I^
���_M�� ��r�#�ckk���;��G�����W�d��;"G�^��7Dm��渋ۯ��?=��;m2��GI0����p�q� ��Ga���d
Ϻ�$�>>�]Ü���@0���)%�˂z�,���{��DT�U�	�W�CG�f�D>Q1ڠ�i�2
�t�\m��2j͉�/B$�����`@�ѭ�����yxl_U�au�U�NQAJ�٬��V�|���#˯=�a<�=�c&0^E��>�͙�B��P�L��U�~���:�"�~�=Z�i�y��߬��h�=�����ϰ�LC�2�_g�_1����Y��[���c��3��uk{U��(�<�	3�	tH}GшgZ8��dA������E<*hO.��4�����4�wM�+9v�jЀ�b܁���%so�q���%��z��e���M�Ҥ�X��S^��-�;W����pML�����T�M�BZwh���a���X��O�i�!i�P��`R����ġW��L������3��@E?>|$e�LJ�i�dl�7�y<g����qD�.��ܧ�Ac�]�M*pQ�S}jQ@<ٞlN6�&�2�u'����&�!�U˜�@Ù���c0�!�(���l�(�vz�樣��N��3u��Z�����2#��b���΃��s���x�?�M@�,e�K�J
�U. 1��+/j��O!��:���R,�C��.%�c�w�=��O�(� 
8z�S��6�/3��Z���sW��(~n��XQ���_��rאK����b�1U�6�7��L'/P]:�;`v����9r۾ UQ��6�J�\���Fdy��s��ʪ�6�Ö��p��H/Uyƛ�'pO�E�]Z!��2� �
8Y�n<<;}AC>�QX�ϱ�em���L�5�	�d�v����[��]ut���;��Lwz�ӳד���v�Ct
�c>HG����y|ǍcɌw��^�A����%�X:}"����+��G�\��P������-5�INCmyHh�!�!�*�G4+�7& B1��t�M-�s��-Ny�ugA�s�����"%��.U��Af`��������G\[&���d�wƚ�?k�b . �ӓI�􋈊����H �<�z��I�������Lb�;G���LEp�ʗ1�+�4�Z��w2��?�:��/r`��Vl4~!~3��%�` d%�{ϛ]�qYv��m�8\���=��逋t|�����e��W��S�=�O��;��eB�Y��%�����J�_��������|%T%^_��e��}�e\άV�2��"\����.4����N�><Đ�lwf��:��D�����hI�˨�O�V��x�<MJ��GS��R��M�(3��M�T.U?m���l."Gr���˝��F��6�;�xQAVnaf����u�Q��W�� ��"�R��[���U��^�xr�G��<m���$���,Na��57[��jP�cgS���9��<</��З�$����<�a� �ƥʈ���م����;Gͳ��Qj[/��tz�/��a ��"��M�������ʘÏU���/�f��M�P�W��������b�7_���k<���\�����薭���_�\ W����`=xH��:̜Z��v9B<��]lT�c�u��^W�׿�qG����=3�%w�x��s�6:;�:wN4M�T��4���i�����w�����i�?��N��&o������I�g��+�u��+����o��i��j��%
r�	i`Կ�+�H|^2�Y̊���w�bM����.JK����������}�*|�7�sԲYx6��Wz�b�(������8��y�������o�"��C,e�LQ�LVH�',�u�I�v�`�$��r��Q�DSǏQL,�^��3���&է�uY�a�?��ī�q�z��j�L���ڨ�6T�&0�����aՙ���vw��][��D��T=�b���[d�Q	�RYS������KaP��1�[@,4X������֚�%P��\��!Ii͵ �$
�I4o#�>�O�*��׍��P��K��d����;���'*Q7�LRo�e{0�h��p2����Ņ�3&�XPx�^O��E�&����YN�����D�P'����h�0@��s,p������ O�DGT�R8޴�R�?�����3m���J�ikq�����~�x�l�:9��������%����\�N���3�D�!��<EF��n˵,��s��轉���ng�:�+^� Ŝ2~3"��N��}���?�r�h2�Բ��H>��lw���AQ������}/n�K��\JS)laB��v����fA���'.#�!�8�s�I��0�q���}��Ϗ���b�j?K�^��C��UpM���I�Y�>�U�IT��W���������p�c�DW��K_��mFʊ�6�ʉ���LD)مFDX��-���eخaɕ���G�N��ێ�n�F�B�a�#�q����"�*�f�iJu��7���h-+z9��
)�G��m��o�?F�+tb`��1�OI� �P������S�aΛ������ r�;4��`滻l��3B���$�pylT���XB��� o.�D&��%ގ�z�+3.�M䬵l���e�%D�C)�bR�2@i����B��ˤ�����J��u��>�,J��˄I?�r���31�U�b�p'��jm�\1�B��������u���[4g�8�~����j�B���t��8��;#�I���`�9��{�j����3�q�ޙ�xP�lj�Ca#2�59D��LFg�A8��%Y�$�MM�~m�6�#����{��dab���qs~)�c���BA����X*ν�'G�zEr('���d�r��E+��u�Aљ
 �'e"��Y-i�e���������߳��MW�����:�eP��<~����ӦNH0�����@[Zy�=�F�=�J��'�bu���|�paaC��9����aA�1�aC;c_� �x�X8�Rl�6U=QC`�~ش��bޜm7(�\�Gᩑ�ͤ�/3���|��TK�DN܁9+v>�ڹ���Q���$���Ed]
O^�� >y�*��x���c%ug���p0�^5���H����1�C#7��m:���u�0�t�Q���[ĆHʂ�(�\oP�l���";�x������6���pM���e��}���
�u�^+�N���u߃+���>��j� +�����""Uڈ%��|��5(Lj�7b�/���i��y0�@��F���w�Lz������k�E����R.i�:��=�w����(���7�ԭ�ju`|����
�u
�*m_��b����g�,rm%Nkr�9=�tǝ��(P�S��CXO��&e��+�i��p!��;�������wfꢚ��y��9����qm��:�ȵ�nX@m�?(��4(j��B	�U�K!ѶB�_?l���&�-U'a���E�k��$KeT|v��c����H�FlNG���g�����5NHW��f���]�L��Ä��`���O��}���@��*��e�8A�D�eL��V�?��%�Q4��?K�C)X�'��er�^��, *�jy�eV�,f�{�R��[����4�_�*v*����s�D�Q��N�7.�6 n%�6���aO�����,�m�nk�L�H{��'V��qF����;��P����#�x�	J�@$��J�~��V�_Os��]��N ,��ll�*����2H��=|�ΝKrk�y�Yn��@���\d�[����H�6���(�^��73�D ��j ��0�XJ���Y�
�_�`��1�>Zh��&�#��$0"�å����e:����s��2�(�
0�!��Z,�.bkK��@�1�ѯ#-{� BpmM0o�fp�a��!Cˊ��C�$��%�@ۊ�� :���Y긅�D|�h��~��|?��i��sZm7���:v�s���}��zx��im�K$�Py��)�_M4C!�L�w-s��g(�;��B�J-�\<��ؙ�ŗgW�/Eh레`.s:)��?+q"��F�8r?�ܭ�\�jDlָ����˄e�xC��KY�,��)U��R+��QP���/�.aN������(�a̭��uN�:<���YW����ݴ��(�� �S��l���|�o+ y�=����vr�ƅ�����6�d�����fHj� �ˈ��P",s�[ ��ӁhM�- ��(���9��2�0��?�y����@���̒�u��[VV�Z����༁�ɰ��%���U�s�c�J�ִ\N�KzT	��9b�	b`��F��K�R]gq��,�G����gZ���(��z��s�=��:���Kwc��*�;�忌&�k��.����Q�n�l�IgOT�"�߫_v��S-�
�*�ެ~�a����(35�~i�\93�l����F�6�5�E�9i��۫Be.��rmT��ό�t7��?`է?6�˅D�rbC�9�*�k|=�Z��YWNu���iLz�k���K:�������,����5����;�̑ނ���+əx��o�f��������wa/S��t�í�S
Ou���d��t�U@�V|���p���1H��A?a ����_��q}ҿ��~tq�����7�R[��?a�G�~��7�L@����U��?%��� s��Nr?�I��ҷ�BK-�3K����N�O��s��w\Br.[�	.�Xv����@�Ipֻ:O�U��bտc,���	��4�/�.������FD��O��'����	|.�BY-����'be�KEN'�C?�x̏a�{��¯q?ӿ��t(�h��'��������$�T���9v1Ҥ�����G\e_2�dlPH�M-$/�'�Sf��><��""Y�ŉ��i���sS���f���^0�}�e����ޣ��K#[P
�t2�]�܅r+R����z��wh�_��T*�K���0_�N%���C<����yM��:/�rc�Rǩ���ڪxr��.*��T�4�[�wIW��F�yJ�
5~��H%���zY��M*Xxfjj��*�S��U�4Ń�br�)����q�d�vA�� ��(�$쫣o���"Muz�R�@�A�N	�F �
f1 �pس�i��n��|�F*�s(�TY �N�o����\S���S�q�+P��mX����YS�R@n���h� �w緈��Yv�ۺW'�̃!)�X�(��$+��R���ёO0����Ţ��K��x<I�|8���2
g׬��2�)-��˓��\)��ww�R{���~B1�;	,��L�;�VB(rD�qDte��!?��6!���_�!/&��tы��lՍJ��w<#P�u�{q]��j�l�49����)�����a��S<{�Y8�ܐ~s�i!}�;+�|W����Gs�0�J�_�;3�xp-�r�+ϫ�[�0�O6]��F�(-a.�`eNճ���g�<4\3�>23��ĴÓ�	�/
��T�b����5�:K�|�������nyJ�+�"�Ʀi����s$�n\4D�LX���A�h���-S��9[�G��
����qڨ!U�K�PWi1릻D2p߄���d�m1�0�*�K��R���2��m+u7�RyK)�=��:���<����d��[�vN�g���&S�4�i͑r]�~�HA[f�լN;�3����&�gY�e����+��ng��0o�s�ō�hm�_��7�y� g5����S��9��9�H�X�RnUǠ�h�/ݾ�+��sJ����xR~2%6�!ƹmv�
�D᧔���Q7V֘;5�
߷�!J��H��LH�9^	h#��9���^��RM��a��YNm�V�8R�jS����lU���y`z޻Ƶ���t�>�vkZ�RŶ7Ty��H��uq�ڹeB�Ƚ�lw�������,�����A_��.�X�J���r.����(��Y���� L99ݨ�E�d����6�,���|�}��2��d`�o�-��cα�`d?�t͈d��D^�_U��\��:���_���"*���y�IJ�K�/�є��QUE�/���e�*S�*�ǘ��LU��Y��L��,�+��*+�pte���/����ʾ�o��|���}�d����j��?��^����?�^�GWQ��4��@BR�����זằ&���x���4�Ҝ�����/˒"D"�(����=+����h#E�hȾ��^�Frktj��Y�1̢����y�'��u��_X?o]�&��>[�VW�Ud��R8'���}��]%`\�t�fg���N�+0.߆ɪ��*���Jsv�ރ�j�|��|%X��:|�X//��Р&dlܴ�U�<f�gdNQO�9�ʽ�r�?�v���)��e�2�Z�^��F��hLd�a�,�x��օ{j�- �t�,��'��6�؅�?��
F���$�I��(��P~��PY�s�����/��������������=��\����m�޴���o���C�L��n�.����t���$�]�\]�]v�/�ރ�ʛi�j��[�����=��vg��\��x'hb��T��촷�˧�����pY�����9j�ֳ���+`0�����|�~��=�Y�Yr$��q���2)ن�p�/'{���,��fe3!�K��*Ф�ܑ�{� ��X�ѿ�Co-����w��2���!��e�rާ���*/����k2�<Gu2?$w���#|��!F#
B@���3[y�6bk�[:ka�����X��X���8L������V��"$�y��
I*^�	Tk���[���&�)�A@���f�4˩,QT��L���`�"���"NDS`��
�@�Gm�؂��Ã���f6��j�Cϑ�{����D�e9!c5�mڱ��8>(XD1K��$&?���
�$x%H.S�����DI����w�6Q��e����V�+]�V�_�� U���U/�Q����S0[�P���u�VV]����� �x��֒'u��G�*�9K~�	�+�~��F���VMz����c�%�(�Ta~T> b�%w�CP�y�����6\�Qǀ����8\�D0��'�G3ߪ��u��#TF�N�@�����AZ���i�t��v���;��Ng��X��F�N~s0_סd��.�3U�=��@k�\0�Ч��a)�i�&�:TҢ�$Ip��T�D�΅U��'Z���9�2hS;�YIf�������JnaQKq��^���A�T�W���)�����q��v��!y��RiQ
t�塅W�O������º���M�[�`XQY(�V��:T�h*�-X˔M%u\䄎�5���Z/�M+e�;O
�F�L��z���h~��5=N#��|Ly���4��칐7G:w��0�	�	Z���46L�a��99�^&v2��qlZ&$��Fms��\ou�$�cLm9_��H��3��ߝ�r[�H>�E���O�Y�
�l� �)q��t�tt��'@�YqZ��ǅ�J�V��+)T|���!�He3%̺z�i�=������SB��"�ܑS�����j�J��H�Wl����(`��v4��|��DpB���`�i9#d��MS�nfcl�*=bu�x����#�]�U�P�ǞU2�r� ����J)�Φ� �����ML7��Dެ�������$����=�3(j]��_����-X��z���߷�\��3�.ԗr�����ɝN�!�i{M�����Iu����;_��xc���w�q�u/����{������:zx�|�Z�|eA��C?��Ƴ���[�� \�1���%�cdGn�H�3_=��>o�D3{�,��$����{�u��eb9�q8��\/x�Ƹ��Zr��r\��kE�(�lu�&A�ň�Q�\���8	��lV�-�2�`&����R������J�^�^f�͂�4ݲ�
vdf}�~��Y��<&O�h�t�q}Hi�7�hŏ�	�5 ���@��J�.gw�?�@Y]>mѣ�x��D������R�-��i@f$3�Ǆg4��Ȟo��֋ifW*S�v�^���$�LSFC&��lc��x�*x
=�|�%	��[�/�y��fup�{s��+^�(1ɦbj-5�zrCS��ƌC�5����p�6��������L�p��2C�qpQ�"�D�_��Q]��]��@T��b��祸�=నN�$!�)r���xR�!�`�hZQCt�U��!�c��jK������l˾
�4��H���~�~��ޒ�ݭ
SN~2h�\/=���ZP� �G�����]�.~PJ4��4�2dv"�{���=+4n��;�ǻ߶��"��h&��/���C{��
�{?�*�њ�F��U��z�1�l��:�5��2�'�|�R��D8���X��!�P������&w����k�A�gQ }_k��џv����{/C��$��j�p-�����|�>�b����ԩ.��	�ߗ������Գv�-���4�S�S4���NB��[��ɹUU{�]E#6�:aS9�#��/��-N�h����?�y��}�{ A���#U�\��7謠�'��g��b8�g���ڰ�j�b3삣dǾ�S��T��ݼ���(�-�g� �\?�ɵ@H���%�u6'��G����ia��.�����q0�f��f�Y�O�э{���c>@o��z����(�1;��8��<�p��D0�K�ӣ����o�_�+�����[�v��k.���8�lك�S���&i�R�	R����e���j���6��d��MN��i?$e�����A@�gA��!_�ҥU0y��Q�G>����+	W��1=�gȼ|�ʰq�ץ6�ʕ�G�#8|�U�����_��1؇J}�$�y��	+h>Y�sEm�Ժ�*�0��;��c���K��k�H+߀yG�����lA�W�d�vY��t WK�9���#`5��K14
6^�xPV�j3�ǩ'�(8G�G�sN�No&���r���/�t�v�nboe��̦����w����_�|�W~��M~h�C�� 3�*I0��^#�@�ի�m��	V�Dj����s��ݑ$w�!8��>�ɐn�'��ؓڹ����E)�����^�s�h$&�&,�QMV8?��2�F�z>�����:��sK��V�15o��&���BfD��D�d��Uba����� g�6{���<˘;�<�W��rhI��F6�A��6���'�g�R)x��ʼ�>Ԇ������R��������\[O��ս�W]u	'$�7l��q��y<G�וY�!o��+���`�7�[Uò!����J[����<k3� dj�Qtla?F �a8I����'��ro���K��UC=���u��|�m�~�u����2���:&CFݚ|���ޖ��m=���[�R�=٥17�A���������ߴ;���;0Ν��6\���g��������w��y�>����0lRv�G`���s�:�ݓ��v	���H%?L�@�cs؂�\����LaU&���w���U��(�Q�Q��_��(�Wĉ��(�B�"�S�%I:���б6��D��e_B�OJ��I'ײPN��c�X̼� yNz(}�Jg;�$��]�ԣ���\��n}�\�1�8��sm�8�f������A�ݵ�L)&���6c��O��L>���v���~��i1��d`�+A��&p�=��Mr�ݯ�Ϻvg/cͬ*q͛pb>�k�6�㳻���\���zK�p%D���	��M�S/�k/2:��iﵷ��F��>$��F�ew�wI9w�c�dQ;C
�(�4�u�$���,md%T�O�ys`?O?�.џEǙ��	�j����_�E��K{�$�w���7�D�+��0�#<��"H0ʁ�6C8PӋ��	+J-Ql�Rt0����T�u&'�����v;�{{ߔ<D��}D�ϙN���xDr9)hNd(W��<3*�;{�E��:����:=_��_�!�+�m��]F�*
"�V��A<B�z�e_�&f���aqU)���� �K2�����yn���u]Z<�_��E"���pjj_��+�:���<k�9D��`௪{-�_���Q�W2������д�-ު0h�ӧOE�sUB#S�e-��h^&%�q��|�ޮQ7i��=މ�㓷=�'ѥ�(�S�ȋ�o��DF���P�����<�+��1�*Ja�����U�K봪�h�"��D�	�@��5��4
�ނ
�P�(�Q�<�╋�L��{�/LD_;4Ey��ov_w��vv��o���@��0A���aB��a6���z��ߓ(F�`.�]#��!�L�`�ڣI<x-����[ �y�,}�6��|
];��N��8�����C,��N����p[�Ԫ���"O�O5HY�I���4�%����ٛNڵȐ��Wr���h���Na�ڬ�e������5�9�L/�哨%*]����b�YB�����G����E]��AK��G4�&��d՜S�M�=r�Pƴ*�����1��~��V)�����s�����r���b�E�Q۱��C�E��B�YT9��{���:>�/���37�L$S`�h6f�� ��{�9�����1q��_|�x:o:b�`6�d5��}�{pg
?<�~�K���&�_�Rvva#<���5���5�G�h��0hI�!R$��*�?ƳW�ʣ-�IU�hb�Y3��E��
�b!ռ��`_�xK�SHJ�9��)-K?i=���}W"�P��,��c�����Y��,�aW�0�Β��[~y���1�9����H s�j%�ʦFH۴�d�X�S�����g���q�V#W�5R�ȇe�q"@"9�ݧu�G>�n�N�UBo�:La�����!����DX:�V�yI����6h)��|2p�G���h�H�"P��ԗ�*).B 5��Rf^J��2	؃u�dx+ �6O���bY�l����5/��sSC�F�rÖ�f����b_M7L����3�j���l|�Q�N��1׸���N�Ζ����Kc��Q!#?�5�$k8ߒȝ�3�:��oG��(���L�uZ0C�j��ߣr��.q��-�{�����F8�ֳ�"&+I��Lٯ�U5G��3�(��-'� ����Ѿ��h�FxKvn�_K�4'��~t�2�a8u���uF��I�m�F�!\�a�$zn�M#�FBX1�s�S�B�<&Qa��7qVo�gi)Z*M�L�rI)H
�ݢ��(�5�$wT�b�n�7P�s����;��pZ�Ki;��4Eژ����u��܅j-��"� a;�e��d�-��1O�Y G*�mʒ��-����0%Χ	z(���G	�^U�rˊ��>���/$g�Jw�|�a����v���x��}�Z���s������]��~��$�I/^���[<��[�>���ȺS�O���!�S��L|� 	����HnL��}��� Al�٪�Us���wp���w�^"�4%ӏ���1���U�0	crP�7k�P��D�o�����/]��ˊ��DBb� t�
bO$�O�*�kg�4�IG^��Ay�a�:ج ֗�
B��ΙΨ)�W�^ZL��ш����T�F�ѯ�]�/!�a�I����GB ���9�T����#��R�i�X��A��+�C.7�g=�Vb���<6d���.an�#���&�@��4�	��s�sHPChdPR���:�=	:VF��^f�kǘ�2�J�p�̠,oQ2�-yφ����{��hi��	�)����GG!LO� ���� ^�I�^�S2�@:=HB����{k��6A��s�
4'ks�
��fm�ȵ再�PR]�Q�L9fΨvV�2��-��&{U�HUb��5O��3���D�WA�� ��q�S:'����9�}?)��:#>���\�Ą(�{gz��q�3��
(�Iw:�m���B�霾U	u���o8#M�$���}I/-�B��"���"�)R�@'��]�;��T��KY#m：�'�����hH���_2�1��ߏ�XteOUY�g�tȘ%��=���H��G�l�w�u5o�vi�F�pth:����͙�{P���9A�>,^�����o��1e�ά�����+�g�JNnP��[���T��w>V����g%+��do/=��b�.9�g�ߕ��,��A,%�f�@N�5�#�7-�4�'Y[Y8Ӥs53�I����9N�q��qq��VwE�>�}����s����B���,�:v),�H���jQ5����Z�竢����`|V�j�*4}�K�L]�tF�M�2���v_���_�N���N��� �� p<��Z���?��
�u�װ��˛z��S��,�J|�N, ��~��s���$3�: ǖ���rHdGn_ki���,��l�?�U��Q���Z��򖐹 t�
�^]	��6Η�T��I��J����̮�a�X�k�_��$Y�^��a�����r1"d�C�x̔zy��d�/��jI2�RD���VJP~<�V�	c]�]Q��	eI�Y9�A�du��/ps�30o�E�zs���>��椓�HJ�g�9�+a��I�Ğ����OGq:y-]�p���o����O��	&�΃���{��q	�7~o���=�������)�w���s'�7O��F�̒��)9��{��_<7L/�W�U�:)d��%�>\�]t�W��j�"ˎG5ho\�^����3�z��ڳ�*�$�8�q^�x<�c����Q�}��g��(����w��������B�9KS����k5������Z-	��A�[�q��R?��o	��Ւ+�H\��T,�Gh�'��%jŏ���!�4��+A�;�[�����V���Vc�*�Q�p��}%�H*���s�n��޸y-�G�3c��ކ�&���h�=Yo�?l���������8~���l�/��y�X'��H��N�����H���ƕ75�Ks�]�����U����͵g��sQ�N2X*�����[�i��)��}��������e�q��� c��ْ�������9���v��mO�1�GVϔt�����M9��~�Mog�xM��[>B�7ҷA>�O:�e@A<aD��S4����E~��{��X�`襻�O��u���������Q�>L�`'E�@`GI�(?��[��,��Qݧ��X��NoW4���6��q��,�Z�0�!�J�C�%�W�C�$;[���g�h���oaV���*���Pr�֚�eo��D�]���oPx����/ �/_�ϗ�.|uJ���Y��+4X�oh�A��7ǇG�,?�/��Jj(a������q����h����A�(��ϧA}z1� S�%5��֛�g�q�,�	�������T6 zu���� ����m���?���S"�̘����tL��s+i>;3sݬ-ʒaDh�F��d�><{�{�Qh��6��t�U��N�'�f��{9���4��l=�2H�Uo&N��hQǉ�PXjے��P]F���3������`&�	I�������X����{ٲM�t�ݝ�J5���)0S�J�$��U.Wv�D��;���GI�Sx>A���.y�����<4� [��̶Z\��~�ष{�޷һO�F0Ʒ3R�H����`���0��Չ�Q���v�|�Z��eϰ�(I�m�����D�-���=�uM��9�PN�;Dr0`%�4k��J����=��LL�봷��T�$�z�Ita� #�2��eiJ%�ٔ'Ŝ���ƓC �`ќx��a�q[�U�^V_�?�Go�������9��z��IT��
���	��J���8��ez��=��<��g�ZD#`�'p�!z�0���2�z5�_$a8 π�
A���$�L����y9��|ϲx�$����:V����~1���-��i�̀f��Xu��GK������Jh֟�)��ٺ��P+;��no����7�Y&�d��F� ��Pޯ�N�e�j|v�/��HLX�O�_g��|�=y�Z�֓������?괿��~o�p�6��靍[�m�_�P�J�tg�@�ԯ���Ω-����kc~ƞ	����</a�\�e�����`�� _�a�\����� \�7J,��x�>���j�����[5�s��(JcM�S�~���xq>�S����=1�q�t�o�ߋo�;��{t=�N�b+|��D�.��G{����X0�m�S�iOl�6��*'�g���1@��h��>4��~x�����lV���������<�$n�_�F.�f�a�N�w0yg�\�=����ܸL'����^�y����E:=�bI��B��5����1%A"���A�L\�q5�o�U��艶��`EB;D �kB��s��2}ёjU��x1�G5�/������?��y�:Un�}vy1�E����wa�}��{��B�;z��/��3밯3a���$���/�s�)\^O'��L��C@xp鏙q(	$wڟ~�ǹ(� �|�Bq:����d	�z�*f�I� �Ua_)� ����Z�}�f�OY�5��LG�"Z�,��_��,VV�q,~����F�^(��B�=(�F�cH�VepD�_��X���[COv�)�a�;��w�Q��O�e�t��д/N�~*��˫P�f����tB�cz>_��z\Fs�a�b:t����s��a�y�<ϭ�|[Da�������ׇ�c#�|l��'��ڝ�bM|s��Yh��pI^�7�ԛ�2�ʎ�NGY_�	֡�����յ���-ǋ�+��ç)�K�G"��=Q*�y9�N��<F��3����Ͽ��Lق�]��i�{
Vj.wR�S=cyu���]�>������u�%5�p2���U�	R'��08�j�?4�I��2z���(�(yJ]�{r�'�����t��D�}�.�����.��9פ�/xORb�W��ϫN����j�gDf�T|ְ0��J
���Y���"�} &{/څ�ܯW�P��ۯ�c{�-��l)>T�\��0k�7ڞ����V�Y>��	���:�eR7 ��r�i�d�%X�����	k6-��'���r���b�U��<Χ6d|$�|L�����\�a�e='Hu��BX�X\,(��#�֐ک�k��[��O6�_�܍X��5��U�ך=J�l���U��W�2�Fּ��������YƗ��D͟VA�s}�^��^�g��ϭ���~; V�O%Z�U8�Ǩ�)��U��#�FSR=�"����&�A�r�G��:�͊�X����������Y���"ЙB<���C�#�H�m'�f����Ö��>>�/���<�J�
�J�b������L������l�X	���T��
����y�V58��.*kB���ri�Ҥ��3$m��k.De�B�VCڍ< �=�0�� ����Z� B�p�����9ج5MCWi\z���k���~�`a�Z�U3�_����z]�i�}��%Wv���J�p-F�"S��b�G���i�%���tk��^�mPA�( |U�{p���Sg��Mu�t�y������ 2$'�9�N�͔��P���YQ7���.����F}\��eȄ[З��\��x�x^V�󪂟0�Of���і	頊����?<�36�R�p�n����T�~^��W#QK/�ƴ9/H�.CTHD�ll���C���p�"��a���M1<xb���>B��vp:	&q��qL	�o9U��7ւ���)e�8nr���A�
|�+SY�-UhK'��6'U&0��)��w�\��{kݢ��g.�����0�f��3Um$q<��鶟B�h�W�����ۓ��`)��75��snn3���˜�G���r��FT>N�2�������B5y�SP_�`3k�KIH��� �q���~@�8��yNӠ��OC��݁~����87������R���oi�#,
e���SnܙV�,qQ��@{�`B�r[�8��BLY]��`�j�L��M�A�F�q�M�	
 �$7;$�TE�X1�x�#�/�S��DS�O� ^�>Y�#h`�S~����4��,�0�:�K��I�e{.���(?�A1����:ڮ���.Z=�m�u'Evb+(��e����	6Q�����i�^cX��~���'c."<�\��Շ�fK����w��|6>.|<���P�'�����)ҫ��ޥ�A2���o�)-�s���k�u�j@�>Z���<���]-D���~��_��~=�(�֖����9�_�������d��2�`��س\ыjKT7D�Iށw�N�]��'��0�NT�E	=0]Lt���;	F�@AJb�(���G��}��0�[��&�N�F[_�l3�asX_�eRM��"�S9��n���2ۜ�e&d ����X��2����E#�D�~�D%WO5��iL�n���L~/un����s;�{vsӁ�$�-R[.."�9mf �����;	�yFO��Jȝ�|ٓ�X�|yY�#����"���Bw��nO�ϼ��ޘiv_�HWX,�s l{e�.Xx���/� ���R�f-�$������?"Z���K�W�
�Q¦)�,�z�I��*䔤��|��^��Q�T�DuU�XTq�}R�i��ވ5��;�FÎ� �b�,f��?�����[�����i��1��r�?�������?_j��`o������������o�m}��__[o��כ����/2��>>r�Q��-�H��k����YUlO/E�/���n>�*Ր��ջ_�����g��ꤓ8��JY���G�ݮg��,������+��^t~��p���.������9�p��&���O� �V�U߲t�Nk��C�I�³��l\L�p�"�� �v��ם]j�g������[?�F��� z���G8�\4īR^��~�fq����1m&3�:kZ�����HC|��۱���^�^Br�B*ܾ�Ē�^��B,���"Sݚ�Ig�f��y%qUEJ�$/�`3�5d��D�����y�r�����/r������Mc��"�=C%���_�	~�IiX#^ۣ�F�`�`��
�*��5��Z�M��"��rZ�')�8h��6�;��B*�kA�R�[�+��\��S�"��d�W��P�*x�\�
��j�3��Z��:�]o�UO �`���I�L�=LJB^�&6�D��b�ʤ@�霈]��E�V���ׇ/�߱ҧ�^�k���xW�Z��z�������H��r�-L�����Z[�Z+�����_F�����<hi�z��F�����F�"P2g�t"F�{q҇�S��Cҩ�{�)�?���ó0y$H/��_�_zK/�I�._���>ѐ� |:��/�D/w�-�?=GAg@�i�/�\��/-�;�X��z��Eb^4� Yζ񺍬.�ߥSt��®�[fj��jJ�+��^N���G�Ii�̪�R.��@���L�[מ����;�SX�$q |D�Z�Q/D#E��v�op?B#�˼m=F��R�ڤ��h�0�8�`;Mtd�'4��Y�x�j�A������ࢁ,Q���7�J����̆���*_���̕�աȚG�ƿ���?N1�#����e����ӥ��` (5�=�i���MhP2�<����PQ
#�ؐ�'�߾���Xy��J�[`��(u��y�ӻ8�McDo=�P�
�b�l��W�Lj��B���1qfd ����ٿzڐ�}�|P�#�9�Zf__^��}t�s��M�n�(0��4��[fh�ц�֌���@j�́v�3���ӰSvI$���r�����~p,�1�
'��Gm�Zm�����	1װ����݆+���R��>�X�-�}'#}4�КS��.<��X2�j!����w��-��m�?}���Z����/�����Gg�x�����4W9P�?Q�S���W*��"E���=��C#�n�H��8	��g_�g�U*������q~E94�H���݃�.z��1��b�,jfm��'��Z�f4ǈ�Ǎ��SGQ�7��HI	�$�]�׊���!�GL�ݥ�3' ���׈@U�0n��+9!,��w9*�I�x��7Ӕ[g��)��7�h͋"�B&�-+�15�D�Ķ�$��43ĸB�pДQ��RY�X-���x����p��ͮ)Ѭ�1��$�͢�X8K�W�I�����v����Ho-@6E��Hv>���YuQf�Hp��g���2��(;���Ⱥ�'�s��_I�ݳe�L����[���ɺ�F�VI���9��Ž�[��1q�q<�
���:0��o�=Ϳ�?n���R���	�>z8���4L�QM**�>~��D�4�9*���x�Ð��E<���@i�,�-(
�br=��]_]�f��W�v+�ih�UH�N�>�/�6	/�xͼ��Z���ȶ����7���}�̤�io��a��/�6�Az�{�^��w|q�GP�u�xm�_K��hM�YpG+����:��L@�aA2B��
R�?o�;F1���8�i�gb��:��Fi����Ō(���������j�V�(�:b�W��-�����ϿYŞ�@D�Y�$Dq��Ā�AO��$8�� ��]'�5�-6OT:$��Ĥ"zE4��(z��w'˩u��� �1���x�� �OM��V��7mS7P(����I�ӕ�/|~����r&=7�z�2H=�B�� \p�'P�(1Q�L}`�u�B�I�W��[(�Wq�>|�w�w�w�w�w�w�w�w�w�������6z� h 