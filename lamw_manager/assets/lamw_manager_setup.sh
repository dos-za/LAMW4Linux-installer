#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1163843148"
MD5="5c608ba51968345d8e58948abfe7a353"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24296"
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
	echo Uncompressed size: 172 KB
	echo Compression: xz
	echo Date of packaging: Sun Jan  9 21:12:58 -03 2022
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
	echo OLDUSIZE=172
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
	MS_Printf "About to extract 172 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 172; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (172 KB)" >&2
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
�7zXZ  �ִF !   �X����^�] �}��1Dd]����P�t�D�%����2�4��0ݯ
�J���v�ve.������t�H�~��C�<���iq��`.d���|ޔ� ��y���2/��L�/�OW\��o���q���~�\��iU�LQ��-h�
g��l���B��j&c����q��Ω>x��1 M�߅�"���HS�
��)�a�?�l�MÞ␏M�`��J We���� �˸���ۼn�ݴm����m�"�"AE�k����	�����t��uF B6"/+]F�jYqY�jٝI����G{���rH�����5�g�S�������jq��cNqQϲW�)��u ��/�F�bҞk��֙s��u��=����9����{���z&�H��:ޏ�"盆��N���Q��(y��n�̲tom	':��;� � ����JrI�t�:�q���~���WP�$�p��+9h��Ҧ^f�����_o{�D�����&I(�%7М�Q��Ⅼ���d�4�!\.�j�iN&#x�����U+�P�f̹]Ö�Ϟ�]Y�0�U�܊:T�q�M���B��A><�l`M����������jL��� �n�1�)�{ntYf! �~g�ˮ��^.�ݮlW����|��9o�+&�~m�l�R����3zl�G��s�a��:�EՀ�iF��ӌ�xl��1����23�ï5��:,(�i���&����I���q��/~v���R���Yۧ$�>J�۹�X�d땹eM���Օ������m�l���#P�l=�3}e�j~���5."Y����ڽ';��	�O�$�;s/�8��}}�ʀ��Z�j`�Of�W���6O���G���U;S�)Y[S���2�Jd�F�` ,�ɧ�Ń��I<Ɇ���-�I,��\^�jp�E�X���l�]m6F̝2$���^�����2�Iǚ�z�Thח�~3cMs�%}�����vR�R��,K�FMϋYx/����.�~����Ԧ�t)����I�M�N�E�3��e!�o\N�A���(_���ɺ���.Х���� jR7�z�qjZ��O�h}ytG.2i�e���BB��:�'��SJb���s�W��x5ʃ̠����&;�@t*�������7b��;�e�$$��<�hS���1�$��޻X�X{]�`$�$r�����X�-Q}Xzy�
����*5�A>��AWKR�95�R����y���;���M��t���;~�N�%��>�P������i��{�}^t���T�u;��#�������Wj��i�lL$G�L�j~)�#��_y!���I!1�xOO�6o��&H�'j�^�z	���\�H�#5��4�S^]����7ƌ�f#9�������1��=C��/�t_�5��?�
h8���۝����ӛ�� �k x�t�sС�C)k}�A�Y;��@/.����ú��1Xѓ���{�*B�$M��3P� �y>5�>��}�<�����tUaN5�}��Ӿ���(-z\hicI���h���<o[FQ�U`�Q,J&[��x��#\)fJ���O31�C�qڅ���e%�����y�9c�wAig9�9UX8�?���^h�;?\c�tP �/���5����9ܼ�?�@�&5ht,��������xS)�_��HsW!��ޅ��Ϫ �z��}��ie�j��q�1��z,�4~a�# ����(
��f�/�뎓��1`�!����؜���w�����;����Ɉ^�&^�n���kSm�N,��XZ��t9�ʿLW��� \��<P��v]^�@��9K�3��,fÿY�����k(_�'�zVK��1��*�����0��V0���ຼ�n9��뮶%,�� 쨇�E����H�S�L;�mA��N��N����[�1��s�Fe������������Y�.�>��ؾ`�m��P�ȑu"�D +
QeDW���'�w�q����`�5:Qu_ ����^�C�~����ڂ�$v��x�I�&M��eB��Ê}EӞe=�լZ뗄0��1Q6b�>�~� ��v5V��tsi+�����R�-��3Y�
�$Bln	;7��s⷇s���8G$,#㓫�t����l�����{��u݁��� S᲋0Oz�c��l���*��C2�����WY�t�I�tCj��,�q }%�� ���>�b-iҬ�րJ��tU�	�"���w	)��/ĹHOe�8$Aҁ��v�E��4�����3��'�*?��
,*e��-5�/M�.ˢ��jYS�RbK�c��R�3 u���*�׍��Uuxa/G*Z��*O�g�	7�	��(E"�i�э�c>>Ŵ;��~�$
? .L��Qe?����D���H���q�c�9��<�KH"�oH0lQK�����f�y\��,Yr���(�l�f���+S�=4�0v�#y�F1��:��V����H��9'�FP�����np�a�%�����'!�"ÑR��t��t�/��A>�@���xk��	�c�	�{<_'{��8�1E5��s��H����C�)rG�\�1vY;`���M���]Z��/���BD4��ʥ�����k(6&s���]��@y�b��9H�u ����N%���ê�W�LB�ׂ���F�ہ��s� ��(~<z�I��L���A-�W�����n����D-��0{S�e��Us.�O}��h��b�^�Ԕ��9�{n)��ӫ����Õ�d[xxg;��R�eP�C0�'���gW�5�4�P�[|���۽s�H�����ulZ��j|nG��y���tN�VEe�X�X���	��������2lM��6"����DOf�|	/9))>�F5d��|(2H}���|�)6���m;f��+����`c�,����B� b��w0?��}A��r7�{Cl��΂�$L
E�O����m��j�{�+a��<�����lpL3:�H �J�n8V'*c`�w6t��:��,xP��uB]�Q/���H_A�Z����ȅ��^5�n���XfLB�r_8�C �z���jUI�H�(	��@x�|29��W�K�m4ˠr�Ҟm����":�?Bv)�_�7h��63VN��5��>uve%�e1����`i۳s�]@I�\�,K[/]z��G�I����F|yb�!h/& Ŏ�sX۫�1��/��@��Ñ�������ݲ��3�3B���˓t�n'��B	ϸ��>u���C�M/΅���w
x�0��n�6~�GE��<V��`,䵯��C$��3�
�sυ~x'w~��_��JQ��^R�`_��/r�]�m�h�Wň�͛k��.�^VG��B�+��Eh,�;N� R��x�[i寷���n.�d45��qҀ�g��#.�3r$���θ0e}�u9��H9&|�&���#�?|,���~
�r'<)�]��Yf�~�d�Ur�@�X�H*銐��Qӕ0Ң�\OI~����/o��r�?�3�ԷO��D$g��GɌߥTh��|����b->��S���=�.;\g�8ل�C�[�T�h�!���>��M{�P$C�4G�-��;������,t�Tآ,xXrB��Z���$�3�����,��H[��v�N�/���u�5����YU���}[��Sa�`��G�v�����A�1�$����9�����RQ��B�ޢřp#r�!�υ�5,���k�ʳ���G�>��A۠f􃈆Q��s�x�L� �, Wbr@_����}��m~\E�c�(~P���t--&E]�)֛��w�%}�x�:jTl.����{���ŝ�Woʯ�쑔�k5�v��6�<�B~T��_e���^P�h�����.�M�yO��\Nm5$�'5pGS��UL�O�pwga �Rʔ�=�Ɉ���ژi	xf � ;JY%�2a�d��/�"���x���|C�����+c!^����{:��>��Z���L-�ę�C���Sm�l��Y4�]�v��G��RuE������AE�4��%� A�E G_�o���|�`]_�&s��	�����rw��	�7�gPL�� �Σ�fR־�k�}�[���-���7X4�q���[���]�T!�|4:3�?��I��|� �R��Xj:��:��y�4,M\��M.)Yձ�i�y�1\;��ʣ]9�0RSv6�Y9�Cπ��6+ʤ6���W��SR��	"�y���]M��W?U`|'f�K豣��_,��Bm���=a��l~�C/��g�X<Q���R�aD9Q��?�Y��U�&�ׇ�`�g�2��L`�=�ل� �ёKգz�3m(c7*����%W)8��2?' �u�l	�[]%��J#ߖxQ�okFQ��(}��{nqtQ�oq��'���̧QPA�t��(�9K�6��%R/��>P0�E6l�ݖ��m����.o*T$C�\�kS���NQ������q�y��#��&�B���[:��%y?��а
/��!��򓮖�e8)<������Ò�L�+#Ga��)°/O��{Uk��
@�B���P�ډ�&�F��� d��]Ҥ����~�yi"��í���c]�ׅ@C?��M����b�¯{��̖��0&���D��<���N�������/%jk�N��& Um�ׇ����l�f:	�$�F�E,NC�'v
��&8������5�:_j�1��9��:��p�����+��碛�p���	��$*�����ގx���ċ�ƹ��C	�[K�P
�]��Šɭh�rx(j�-��L�'����	U-����Au>�
��?�˭����i�O������|B��!�
	pXU�4}�&����g-d!c�D@Ѻ|Th,�ͅ��^���=noGڶ�+���~T]��>ov�<����^��O���F��u{6���ӷKO����h�@6]� +U�k�����ύ֭�=����wb�_��:��E򦣢x�F�D��f�1L�Пy.�J�jԲ�as�g&-��oi�g�l'�B��e�}����[��QJQ�p���o̮"9�ч�{��@���4���!���zЏ������#rkv,|�v�&1�;h�&|�^����M���.lضֻ>��?o��0�&�n�F��8-q^G�SrX��������5�� ��}!�f���Y��\m�4��g�OXK��F�Il��wk[����� S��d�O�%��JfD��A;�����43�\���o h��9V��h_֏ϣ{q�:�x��o�������o'*�
}�Vb��?��%�kA�B)��F+4o��-��N3�s�����$/�]T$�h #^˼����M��xčP	��B��:�v�� W ������E�����N+��_�����H�v�C�ܾ�}�$Hܬ\F's�a��Z�մi~���r�ɉPM�v���L��k) ������K�鵓�Z���hn�n��K�V���ʼˋ�as���R{��l���)����������iČ1�Ç휗^���Յ&��S+΢�U��)�2F��/䛳���~[EKN�N���_%���N�W;�A����v�?�j�I�K��Q�]n�߬����A�y(Y>L��
h^ r��W��#Ň�h��#i�ҟI@�i�������z%��ȼ��9�A"<b0P8�Ic�P�����eB�sK�N���~�\u ��&N�%��0o���0��=�(�\�QV��s���^�M���?�Z�ۼ�s�@}ځ��Z�x�	2h4�2\K	G�Kg�<�c!<0�,r�O[̯A���:d��&��A���"Uk��*}��_P��6;*�[?�J�2�k�׵琉�h�Y���[e����=�?��gw�Vm�!����gR ���3�7�rb���^8�j���b�<�aY��vR�t�Q��p/��O�S�!��� .C�����&�NJ�4�C�`r(��COz��Yk�kUxM�j�9)v��#N��SM����`v������~�8B�u:���T!��0��v/u��FC�E������ӿ��܋L�N����T�Ѝ��.�3LݤǺ�ɖ���iD!E.���C��min���x#LT����H��vʬY��!��T@#�k�~��|�α�5$zcMD�O�������!��:CGʇ�I﹔�Y�HPK���\q��ޟ�<�&AյW�A#9��\���٪�I�������+��U �{�	� '�H�<�)���jP=f�Y�U�)�n���2�>G���[Ȣ����C�y�^̎q�4�V��zu+&�2�qě �G�O��V4�6E0�U�0��"���%'�����V�1w?!����sҪ�E��b�8����֔�r��/ҟ�X��_*�퇹&�o�.�wۋv�����l�{�k��i�)\~�u����0��ً� /�w,�vphu�Q	�B֗s:~�xD�` �7_�/���ն�n��8�4>)|]C��~eV�Mm��_�"�#W���x���qm�a�+&�a&�y=A�ο=B�U���?wk܂�$8�q�A�:e�$tK���im�͚���$
֧u(�D�9
��X+����J$��Y���t�v�Xq{ �׍�4����S���Xϝ�8�]��nh��O��J�
����&�sV:�7#�5���2'�r���k ��/*Z$����x��@!��D���T𽣤�X*��)µ���B͛6��Ƀ����ڨ�K"4��KK$!2�
ڞ�NBkшW���U�q�o�:�>��yhF�d�OԼ�
�M��:-�gk�ڝ������'�a���{����P�U\_h�S���aT�~;�t�[��$��%d_�0[�&;��թ�F7}�lp�ġ_�Ȼ�B�>��H	-1��~���4om�Ӝ��4��
�����"��e�U��T�?Z (�Dlqy��]))�p�ϝ�����bX��M�7�8OC��l����ѐz�W�$+BtvďN�mg�ǦԄl�#c��q��������+����vN����%��� ����><di���
�].�z���y_
X��n�P�.׸q�ɩV�wD��q�0�M�ýȍh�Ǿ���,�8gוx/�ڞ�i�Tp���j�nÄ#�����)�HSBFog�:�o�ٺ�C��^lTc�iZVR�.(7�5�M�e�XQlyX������D����<��oSj�x/�Y�mC�=q)��Àc%X��9�$����c�hڿ�Kr�2q���0uHK��Zu_�68��=k�f����r%B�h��1�2^�N���^Z�T��|
f("�S=?�sh�(@�j)��ͼMXO3�$S]��-z��c�H�Y O�TE8?u���4�����gh��ѧ�cU�2t��/���PC��a�)q������D8�-������*o�`��U���~8v�<N�(s�Z����	(L�"r�&�6<�_�G9p���u\���OoQ���J�p:<�ɰI���7�/s�r����ݲ���=rQURC��}q%�,�3��r}�zysC˝s.D�o�"�A>_����qF�NuNV�5�=���y�#��� �+oW����Fa[�@=�PwE�Qp �v��>�r�������U��������ަQ�WO�������ڏ �}X�b��/�����,B{U&q�(� B�g�Ġ=:���4��u$�z�SK�pA)]z�gR�Xz�~���m��y�8��i�<�;��e�4�o��F��͓F���#���w3��>��v� ҏ�V,��6q�Ex���a�OSp���~�_54ÌC���&�<�K�x����I�B���gwڷ���Lo�}����_�*�����ծ���fR���~̛l������+.��O���M��-Sn������S�����$ �$�x���f�u���$�5��r�K�O9�$S�7���/���6l�~�v7�Qg�#�]$�8����	MR�-�����p�{Z�'xO�'����g����)j�q�H�>�5��Q=�}-eo{b��8�Uu�N�`�A����[e$g�،�-V6YH&��O�=�i�:p8(���A@������ k�۾�!�,BgK��ۣ��H9[�|�����L|���0Ov��ch��.�Y�)wqC���;��[J}[KMå7u����1�.������pí7o�uX��n�w oG\h�``wY��7V��v\�wm\ln����<E�%��>T�٫�OXL����N1{- ���|Z.͇�o�����h'���G?eG�aO�����w=u@��`.�/���������al���XQ�i���ʜ��.�W��s��9MP<A�c+G��8Y��Ƀ��O�Rb�P�A�/��ٹ���?c%�H��?�+���#W���3�(ڏ0�[��L�XM|�
��.R���o+���\1�Q�$s�fx)��Dz���i��FO2)�G��B��wј�7�.�$T<I���w�%O�#VA�0�&QA%�ǻA�C�X�^�I�M�}n��8;.O�j��*>�&xzgD��O�@�Ogb�3G��3(��|�a�}�]=Ӫ>��[Y����I&�G��
ޛ�/BL���xy�%�fA�
�!!�$�6�@k���Ȱpt���Ȧ3�{�O9�ɶЍζ��3��o�� ����m���}�mx�j�zU�����R]��-� �d:����kY'�N����K�#�5���D=�����)� g>G����I�f�v��迨�Dx�u�̑ Wݦ�sʛ6��!jx�����*h���!�a�fQ���|�C�Gy���[��D��_�c!絛������g��9P�Ś:�GX�T' B�M�{ }%H�-{��e��W`f�K��-�wSl��7��ΏN��P�С�&��wj�_��pHդ�`L�
M�s�^��a��J���ۥ.�Ջ@;кhjV��C�(�$��r=�ڍDnc�J�Zԉm��nى��<F�h�sLP r�x����׍[瀹�#7{D�,��҈%)�K��(,�4H"��p5{����'�kP���W�nM��k_̝���7̯��(\���VR��9����hLH�9͞�C�� �6�.,C�Fm�:�@�FK�:�Ջ1*cf6�K[h�,X&귚�rC��(�#���a�!�1B�®�s�ǯ��1[%�}5�w�����
X�1x��n�MM�$ç�+� -^����������B91��Iy9nL���ꭨu}�yIJ+�h;|�p�֤�E����{�@f�oh?p��m��S��%�ġNN%��O��٥p-�c��-��U�%ʢ�Л�Ɲ����k����������_��"�b[<���� \L?�Я�Pр�"�q�1�YL������@ᓴ�Xt<��3�9�l��?���1-R�y!���L��e�b�Kw6J9��=��_��p�Z��u�8����F��Rϊ�� �R�6������	B�%��4Nt�S[�>p�2�e����|H���'�򖬙Wt[���N�"���,3�x:��@�<��lS��PR���q��|"I�z��s�ʽiFlo����`GnH��r'^DKwI�RTj{h�P������`�)��16�XK���k����);sm����`XE���‏:�Tk���^X62Ax����������5��o'pT��0�B�MV��k݁�4�V@N%_�څ;$W/���Y�[�RPx�~�br�R�Fȩ5�F?gE^�NR2�Cj�~��\=��,����3�����t�/�QŒ}E��:T����f��JdnF�+hPAm\`�QF�S���X	n-��� �[�edi��[�]ȶnh�+0x���(3��c.Wi�c3Ϝ�1�3;r�Z3�ݘu�]����<�Ũ779�T�⺯cv~���R��N��U&3*�"|�L�ՃJͳ� ���gq�"��+�ʾ}3d��[�	T�'KǱ́� ar�=j&��G�5�w��d��wd�c�6���[f]hn�$�&ԕ��-�=�i�zgum�� �̣D:����,
�?�m};ѻ�f��op^i>���Rc���ڰB��V*LQ�&����Y�86�����03G�*+i��w�` �v�����p�ѢLZ�Gʓ�}]&��|�έ���Y�CHP匘݅�7�Ä��g1S��,bp�>�f�R�z?_�K��
�Ct�A ���Ў�Ӟ��2
�Ǟy*B�]���Ut�ĳ�ӻ�֠S*�+!@y����O׿J��L�T�azd�<��"	;��xr�)�X~�(q}w����@�v� SWa�/!_��U;{&�W׻�¿�lch���|�g$��ӌ�t��\�Q���(��XD:���T�����C�k�𧍃��d�^�V�����d�g���w�#40%Þ�ط�YY�K�R?>�V�-�Br��K�_��0c�bPO0�З��w`��}UGj$�T�m?����m���|�0��ҭ�����t%�&��[*���ө}:��4��fޱʢD�������㻽�]Z�Qo�����]`�X�4^�b����Pi��<�7�4��u�4ho�	��Ϊ>�) |��d�}��7��[�l�B��F��сjuY��_��"xEr6#�U�˼pXo<�%C�uD$̗x _E���r���"Ϗh�lfd9i���1�.8����M/����������2���56���T�,��]��"A%g`��+���V1��և	iG5憞�����c]}th6��)����.~kL���DU{�i.BC�K���� ��`bT�	��9k]8�}��!��O���D�A8H���=��
����g��q���v�}`��4S��Y�8�f�:�C��ڍ�����U�yu�E&�ֻ��rE0��;��TԳ��l���@�鰊�D��������DM^v�S�1o�Y�:��M��:Ӵ�AkiV��\�7n������<9��|U��J.4�ڞ�=]�%�����?�������e}��h�r��S=��x��N��
���𐺦�P���_2o6w�,��8��Gq����n��k(���D��>�A*���+P���
�2d5�@��_�+.u��t؀�����1YL-��DIה�%��������î�Q���6�����Oo�(B��N��FIO]hs��i^��Kվ�pz�.d]��I.��c�:���!�6o{�J_s�j��,��	���&	wn�p5R�I���S��4�=�@����~�DO޴Y�C����,�8����mK?| �����^Fh���w��������H�"N�be�p��`�)r�Mi5u�N�]aQ#g���)%�Yy����]Uv���m�a0�Y�*lwVt.�3����>�,�ۛ2��S��`O$yv��: �)��]�d��(�(U����7$l�?TSD��e�]P�LM�<�C����ʅ�Pf��I�K]c1��̕T��R�zta5�����������L������{�<�p�u�Z,xƅ�*g���v���7I6K;�wOq��'�C��	�wuث�p�Z��^5���b"�X��eB��Xa�WJu����ѯ�N;Hv���I>�6�Y��`D���u�eO�4F	�tJ0!t��e�E'�=�vkC�Vl*��������%���]:��^j�DC�<��<������l'�$�c�R�͝�^R@���47`�i�($�z"�P!�e̚�YBw�U��u���&0��䝥����Ә�>��"U2s�Moy�`�#Հ�V���
 ��&MƳIf+a�L0a���'�E���D�X ����ǻg這�,��Փ���А�~ F=�

_j,�g�!�^�������j��Z��j�-ޢ�F�c�wu��5�C�ޙ�l����,��]e�1�&-�%��8.��VCP�Rnp�W(S���E�(�-{Jp�����p+�N1��շgr ���=PzźPG���H���=Y��|G�]��l�����P�eܱ�Q��x�Yҝ�p�#+ɮDW���Y��7`du$�@3xh��"y2���5�w��Q��t��'���D�C�<�BX$:\����jOϔ����Q% Sg��b��Sd^�̧Ƿ�ɣMYsB\�.��!��P��t}�g��=�pv'!��D���:�[W�v��<	O�i)d�Vl�l�C�it����2���-�E o�h8odi��^#�� ����y��4f ���U���"X!գJ��0�L����+�1N����ʄ�0�T��6W�-5G�Ծx�QD߲a��^1hP���П��6 �a��Tpd�1ʢ-:~��Ci��ǆ��+��A�� *ГT�#<��s�|+��`�I�H]֑L�%Z��AP7Thv-���(sm_��p��4�;�ܖ�qC��C
�[��ʕHֲEY�^�ڼP�����=�	[��W~8s 5�^������ez8���8��҆�AQ.�����T��]ҭ���|���F�����.p_$-%�9z�T� *�&��/����S+n�u�!�KćU�U��D�EPH\�,#���Wޔ`k!�F�����,��?
�5#<�EQ"�x�o����8�mM��i̘>���/�~�F!�ws�a�i�kM�q�h��~�$G�s#�2q�7���x��#gW'���8U^>E�����۵�8PO�s�dYJ��@ج�Z��� �.DP?�#�|_��J��g�%�D�>P`6"hD�Q_�'��ou0�s��+�����'�o`���y,�o*�	�ՐaLC��Z㯆}K�÷�B�g�UXE�Z�@�$���6��luQ��]���u]*��甩9�M<u=��@7�����X���t���u;A��E�L�xDRe)���[A�R,N�.Y���\�ur�g�K��h|׈ɽ"���g͆ɔi�۱T�fl�+Y��&���;�λ>��e��d���c�����r&�L� �w%�E��^�Q5,/A]���a�]K�X��N
|�Q��wy��K�p5���T?K�xU��n-�M���y�D���1�3�+&:��70��e+9,���:�ʞ�q��A#�J\ؑ�N�1*�5�+�2O`�Σި."��z�p~GB�we�`ɌI���Z�6|-�
���y�Zؔ�q� Ђz��:��E�,
H��k�� MD>�
p��&�,�4�E4a��Nrۖ�#96#sSQO��w�n��"���	���t�p�6�o{���M�th�s0�z�KF/�(�_ ���4�O�oC�I8���ç��N��f+6�����[�H
=>鰶_6|�Y�cY�&�o���hrуkg��ˁ�K]�:o'/:���]E{"�z{G��t�B7��fq��ԯ�_Q-��I����#T�Pڅ8*�d���n����YUR�6���ne/*Uɱ��w��7�>m���݇��)���}g�s@�)�|����&{��4�U��hJ�Y�^�Եu�<�$��B�3�'��\P�U�����C2����QӬ>�\�T������urNΔ&MԀf�q텋�"o�P��lUK��A`��k�0����O�}t��x����~�U8f��ng�k�lH��W5��ۿ��S�H���dc{&��>)wE�`��Gi׽� �0�5=��{)��ʠ� ���Y����Gym��(�D��r�� ����8�zhXr�&_rI�P!�Ag���x�As�ɡ.�����>#���"�7U���)]��[y�vOC�7�P��U����@��۶���Ȯo9�s%�ȗ§t{�8{��Rvj�Q�7�J񐻝[[�n���I&�v��J��'`#����Y�k0���@�B+�.d�lhFD鍠��d��ò8��W��v��k�t&MO"#���F]��UD�窘*��.��ǿ�i��"�p�ڃ#�m��{��a�{ڰرD�Ӻ�a�;ޡ�˫����'�l���b%��2�Ώ���w	2����4����މ?��A1��p'��]�I��;�f�,�h�?�l��J�o_���ٛDsM�3�����c~E�z/
��п��ѳT����LF�]�qҫ3F
ȭ�@9���շ���8I�vƫ���2�h�rl�,�{�B�;Z�i@��X5b/Ӑ��Kfu�٩�G�ѐ�T��6�]������h��d~F�^�d��iE#i�U�M�<p��P�ҢhI��HDx�?�wc�/?�^p�<�;#�пAWC:��#�ݡ�-�:��ݼ�Zd�T�J�p�YO���M������A�J�}��*��+4�1�	���82H-Ml�G��Y6uQ�[_s	��Q� �I�O�*�j� t�P�6�h��p�L��h�����(��,����L���%7!����D���C+��b4�Pg������B_�OQ��{	�Rzl9�O���}��&��jA]�Q"���F���l�g�bE$F�K����r+��`AD�)�-�wl'�Sу��[b��Y�ېު6�� z�~�Z���LQ\?�2~��֎ ����c,����7�k�gư?,�jv�Y�ZP0���e�� �
��<Y#�EH��c��0&���v��|�Xd�ML7O��࡞"&��k�P��35 �Vo�>0h�K�+<bͦeX�(Z=�%��Ht��{+_�����n$���j4� �ͼ���K�]=�� � wk�ܮ�$�*-f����Η�4b���F�^%I%��&* ���t�sA�뵈xO�|ͼB��4�3h���|�՞~9TZo���CF2)M<,�U�)FQ3x��B�Y�.<��w��<�+�:�8X�b��LA����A���Ztf���l ��?�(P:Y��[L ���9�@'�B�x�e�T�F�\��PW�n��-$Z��dy��!�5�mnZ-㝒.L)n���Ι`���:�Y��OD�P,ۧ��;_enXEm���"ڹ���G�)d�1B
r��f���O�F�d�C$0�l3H<�&92�˗�E f���Y�L���'�<V���K�[	���|�@ck�����D�8�[�����x�=@W��2����>L�c��T.��|[Q�a��e}�@������J[̈́�Т'�?��7�]�Uq��8�E�J���,s�K�Vӓ�n�5�����g�+��Z�'�tT"٘q�S����1�]m���)
��q|-��2�G8�Ǎ>��^s7g-������	d�U!@c�[�f�d�wQG-1[Q�}9��%Z�e����|�8T��D����p��*C/<;������g�2���_�c�J�;�kj!/SS�!�[�U��J��'����)-x��g��>dr�p-�*ކY�����S*��dي���B�fJ~��F���D�->��K0o�ȭ.=���A���_�h�lv(ʋ]�j��_�y�3&��wo۾�T�ī2�3����qD�0�Y�?W�Ɵ Ar��sw��Ӫ0��
���Pܒv�VT
�JF(�)!�ޤ���M�*���Wr�N�
��H��@\́R=qַ���͊�C�Ƥ�S���������9�Y@E7;t���G}#
v���)�0�<Ls0sG��n\ 5:Jȑ��T��Spg~�V��?'8*��f%����O9�@�%��T�~x9<��&_UH�߇%�T!��MU8U)y��I�qJS�D�EH�-��yd2�jZZ��d��p�밯̔���^LO�B|�E�qt4�p�ˮ�!��Ag��>#�I �|��3?&���ˍ��S�@�gm�)�h�j���rz��o��
�ƃ��z.3T2L2�ƭh�>]�2pX��e�"���d&̥E�������>�i�����;��^�M����w�� �@!�#hT  Kp#�at���6�Ů7q���|��mT�?�U4_�{
�S�������E�ur�D����/3=aɊ�.�gqMz���Cg*k�E��@.:��R	�qS�OP|G+킁�˘��#�ΟL*}�*F�E�j���F]o3Ǜ�2dN||ʌP�~?.`]V�4�Y����Bz2�ҝ�f���p�Pg�Kk�t��ta'�^#=�~.���_�N�hr�z�8��X9*���S���<̈́A��Q�.�0��u��q��"샚4& ��4x2�آ�VC?�/XX�O�M|�2���'dS6��b�W/��5V§�%��*}bd�1���B
�����^e��N�t̏������H�{λHUt���I�Y#��m�XE���H5�s&3)�/���&j�|�|�Y�4+Y�(o&�K|hs7�7�ON^�h�tj2�r]_�7�_n�D��_��H��ڈ�����)a�Ug5�|=!O!ʚxx�O��\?���U����Y�G��V���R��ן�kXsw�WG��}�3���D/�h����ǖX�N�6�����C��
Zկ�.�V���@N���t/1���ŇSS�
�]��.I�����tk.��/�|��X��;|���]W�@�h�c��.{5�7��Q{K��S ��%G��]���F�0��7�U�go�pE���El��)�1�J�`X���^�Mr�r�x�_4��1�*_`�ps����v?/t� ǵz2��E3����UV���;�S��oӷ��"�������Ç�q{�A+�Ǜ�CB�Z�pM��ƶ��%�j�Q�(�;4,�����=���2��j7un�?2V ����`3���'�"�#�A���z���n��]��� Hiu��l�Ɠ��I,YPGj��������u�������h[���-pҚA��kһ�BF��~�@;޲z^.���'��ӆ�f��j�	�|�1gU�R�"�4���\,�U}�۹h85Jr��4�TW����p���IqU��]�[?]���e�:��߉{��K�dmG�xt��!�HOA��p-A�D���x�9�x�NޡVe>G�/�񪓦轃������H��,�d&.�,+*��n����H���G�6��5��;�e�Ӆ�{!N�����*Ҹ3)�,~�-�Qe���_sgIt}"�������x�6 ���'V-�][s[K�]��my�X\J�>eR�m���u��vƽJ���b�z�Zc�q�(C��J�Y(v�2����ǘ�_W��:A�����w88T��y��<��U�|K���t��5Y�1�~\�N:��{,���Om��L2��6z��Љ�# aB�)��>�d��o����Ԭ\�BoW}k�|4ר_�;���yy�{�>�*hg:���qV��H6�"8-c�n���0q͸K������o�~E��b���$
![V��c��3��1�u������W�;9_�_;U�?�H���ѥ�Y���t���%��G���0.+\�/�&iT��z>^b(�,	*Bv�Z��b�N�h�}q�0V�`N��'ݺ�
�����o�sҁ�rc���w���>^�H��<�E�%�4n�
��)0� ϱy$7#ǉ�B�0a动��,O��A~̬s5uX)�א���ұ��xH�P���*;.Ѧ)�"�`i �h dx;��':D��#���do�̣���9��y��(��3VH�~Up�cEg�C kcf��e&d�U)��C���8�d@]�-U��6 넄�}�LΣ�9ʣ2y��� �oD̛����t��v i[|�����jUmZM�����Ӯ?�פڃ'����6bđ��\s��{�M��t|7y����@�ǈa��핵��d�7>����9���^���G�gFJ�����M�-3��!�b��ĵ��b8td�_Yh}r7�����iq~*��-e*�$p��B���������tĚ��IB�}&�,X��ؙ��
*��c�Ld��
f�TH�,i�������c�tճ?֌��Gے⻜����%�𭨐_
Zՙ�/���u�]rc(������f�b\/��4!��כ�2��'���5�ĎJ�91-~�gT�C�v_˗���W�Y�rB5��Z� {h���ޞX�R�t����ަ[�6d�����D���K~�6KC8%P��V`�/�z:O�e�,~o�X	#"}C��*�rCx&�S��*��a���Zw�~d��
.R�sWW�'#�1���Q޸�O��Z���J7��Q) 2�h;�&Ru�-Ĩҟe�酾/�ٔ�_0������V�ZJ�Aon��KXչ�����������O����+,��]���u�[й�)FH��8e�����������Ȭg]��0,1�fB-bt2; �B�����cx+��B1��k,����>=)�j��7n�8�ld����a�C�����-�ѿS��w<�<����M����a�,\��(���?�Q�|�������V���s5����;@���u� �ɤ�����N"���O�.�;��U�v+=�������^�S{�Ր����_2������H��!��<*��%^7�����l�H�Ky�Q�G� �?�{'S�y�5�}Rp������h����ΌS����S�A����t�+�H���ft�w��*�!��@e�����%��Y��$#� k�z�Ç��|�Nc���r��1�7��>Gm�4i�H5�(sZ����sO�6WHv��F<�R`��Gl>(������1V�[�Sl�x�.N��ξi/A�I�W�n+C��7��߹��Ge2,�M`ޕ�g�	�c$唁�e-v�#��(��V����M����C���0f(¯F>װ������N}ĕ0����V���+9}v	�f��Do�yD�ld#��{�A%�\���H���W���Jec���=h�Ͳ�3��8,��
^k���5{x��&��1J�В8��ak3�ɶ)�<Qӿ�f���DVG�����"��`�9����mT9��v��\H=�\�����u_�!O�����OALu�V�]��Tً7d����CK{ v�y<��A���)ꬦ^s�DF�[��d�M!�D^#&Y�Gi�o�쿭�k�5�T���� d��\.�d�
_ė`D����q�2�¯t��8E��I��'�g�OR�?�L�E�Ǝ�i
�xu3�땠dga��a�f߅��K�νPF�J�1f��q��;���uǍ�253�T���r�d��(Ic4!iî��o�9����Ž�M1��x����d���2w���t�K��<��g��� ]޷S��n��7/��9���Z�EV=��A��u���� KMYY�f��<�G~<Zw��ʉ��x��������t7��6(����r���a֔,���^Y���H)@�F�%׺[kݥ�6����:)��-c��kҚ�8�s&����O�ط-*�7B�Ƶ���vz�}f��.�=S��r�n[�"ԌNoZ��p����*��2L4ɾ�T��-eˈշ`�)M9��[�r.��[T�j����ϑ�7�N
�~��Nے�=LJ�d���ïo�};��h!c�$�Z��/�<�������+�.��ӣ~ġ6/jz��A��''�/�wy��9�OcT�ul��Kd��7���a�p���� �2�c�x&����;�>�}_�$���&>}�������!��~�s*.%'��_��uؗ�=���1��	�^�Xv}%p��0�� ͎�o�D�0Yc�J���������_o��$�Y:v�eh����7�m�	G�rE54}��%�%Y�8���B=�"0�� ��U'!s�WͧmĤp��pE%�8��j��ηe�e���A&�H�]#t���*u��w�S0'ۨ�������fF��!s)W]V�_W�$!���|�	b����1T	L�"6��M�[P��3��Q�*Nb]<�F��bs�l��}�q? �@�*�Sng�^2���vR[��H��џ.E8������;��-j]���5�p�]j_��8�/��d��x����w�ze�H��v;8h���r��@0�N���G��װ>�R�2x�Y��k��b��l@l�oqJ��
U��"/�4p}�}�����P���O7t��yp�t�dꣳ3V�h9��0܆܋imF�a��GL��/S(}�Η2�����cXL�}���x�[��aD��C��ؓ�1�%ٽ~Ck6���6/�ߪ�l8)�W�̀`Y��tm��U%u��ČVV�c<���|���iWV37Wd쑓p�<�K�L�E�_�/�IM�py��z]�m��;�J�/�\r�ճ�2T �� �VPw�v^=`��,N�-�Ν�J\�_�8
�5Ĳ�v�l'�޶�������K,���5�X6�	��碿�C����u�Nn[%z�9��-$%"���D��m�IgɽC�X+����6�{�8!-���5�j��+�%�w��Ն�I1��)#Y�'��\�����c�C�UU�>J�X?�=�/ŗ�#�@ ?Wy��ȣ��wSq`��r��TRF�C����Rv������V�Plog�AwU��`�=2�j8�tW����m�vɬ��c��C	����u�e(%�L�UR4c�G��c͛��YUc<��H�%�
yX�$�/�qU"��Z��)d�v0�	9�ٞ�$\~mZ3��u�S6D|�Q����$h�=��Wl�����ƀ3�1��+:������JN-��4x���Êt�Y~�~A�ń���w=����lR�!�)��!�JK�z���;cb��/ЀK�t'rd�0c/t��?��ˍ�����V��G��ǖ��N7E��ქx\�_j�>P(|nT����
$&�ޅt8@��I��@��0�L䁔M�/�*J���U��L����|�:���Y��Zu�1Y�&�6�Zq٧W�2�W�[[�l���%�6�W�w��#��V�h�����d���E�:գn{��������'�/�ַ+��a<)�,�9�NGqB��+v��e��yC�@��"�Z�ͩ��X� lD�ғ����A�������c
�V��E�"J�	m1� �j���������8:��/5&wi2?���)��`�BW��%u�M����Ta�'�R{2Z˓y���,��D�e7�w��*��Il**K���KY�3�+�n�$V$P[@���b컛]9R���p�#�����l�����=�� �����1�� |�c��*�O�!�"��GM8O��d���i#�wk	Q�ΰ".��}���q&9F�JQXYB��s���:�}<~Y�g�x�a����
�
��0��#�M�$T4�����I5��͗�9���e��H́�˶N�� 0��UU���j˵�]ݽ�d#�Rf*��x*�(�A@��hTce���7Em���!`e�f�s���p�מx_��tJ�X�u�#,Fw�)+�h�Rp�� ��8�I��v��>�f) 'R��M���]}��B����N>���_wO$o�m�e	�t'IJԮ�gaCI�jkϾ8`��1'�q�9�A�(�Mć:��e��+���IyO�N.��k�Σ����?�U�+�t����L���N�y���<�j!��\cP��t¿�o�`˪�?�H��� s\�������z��A4y��L��$��RW����f1}���<8G��r�T�dy�>�?�nuO�G�22���+:{�@Z&y��I!�s��$#}5p%��"bw�l�����|��(ݟ˩e�l�[�xc�����r X������܏Op�� ���^��$v̴�J�*�U�dY�FN��9�������T�h+P������<Hl�ȯ��o� ���,�����^ی�\���3wi?=S�z�:�SB�H���R�Pܛl����*�:�hz��s?? �O�]���֏�����%
uh�qQ�U������s����"��c����M�#�o�vP�!7M,K�.C��Y&��ƘG���j
�Z�t�/X^�y���e�h=(�Bw��'b��]WΔ�I�G,�v��f0�\�-Urzb�&nlu�'��8wr���A�k���rn��P欏5�o2��mnT�Eh�W���nu0a���$#t�̮��qo��γ�����p�y����kz+���>l��k�Fc�����w�� �u(\�s�k��G��4>���*Ũ%]kX��]%Uz[��>�'��"�}��Z3�%1*e�rc}��Q�#�kz��g��
�����^�����uY�ެZ(UPdP�\�d�_�!�#����8� IPlM����e�`���㗮�g�-��V�僅	��aV���%���
$|�Y0@�ݭ��C)M������d����\�O!��'�0���'��eu�h&*��>Xm��A0J^8
��bi���Y�_�q����nE������k	�{HBM9 �xzU3Xzak^�[҇fMw=���N�.q5Dޱ�Q�F��:'�2��nl��_�[wҮey�|��t�.2
Ȝ��3���3Ը_���������B�oL0s�P��19+LI��o�;5%7p:���S(�n|^���v��۵�
����O��$��%�7����R�(�J���>�gxn���Ǌ��HE*\,����u�p$���Ϟ�[��S�#Ӈs�:������Ga�.���.��lI �&�-	���u�X`x��4κ���S~��>{)�G�����sD2󥿴�L�WHz�m)�)܄�_@[f����?|���XH�c+�<�~Z�/|����%��c �$i8V � ��\,���g��BX5��0����.��*D���gNdXܝ����B4�,;�G�d�=���w���ҍ8�D����H�76�#�0#�ż�����Z��Fh#�|��n�Ę�t$��/-X���Be�'����qZ��={���G5ۅK'b�%F<2����u�󖤧��ny��l�l�6�p��	�)��9Ѻ��B"�.T+��7mG��SQ���
3J�S`cl<I�Ĥ�����"�*���,�Y��$�sO����43�
�����k;�]�6>m�Ӡ��T�9�8��x�@[gyWA�A/�������k�d��5%M+����iF�����hF��I������t�o�PM~r[�&ʥ>���ď"},,�>����œxO�do����:��I���2�#�������:Elg�z��|�B8+�˸�,!��'�ZIȌ���i�o\..�7�P�Gy�Vg����I�W(!��l�QO����D)}�?ߤ��/����v�i�s9�F�¬1wd,3W�D���ؐ�P]�(&w��V+�D"Dq��mw��e��,�����S�qnr=�������Y�h����p�M�;�雃Kɗd1ʵо�$X�hQ�+��ea^�Rh�5f��"��6���r\�#�(���R���4/�@�]��.0����\����]7]!���׋�%;��\�����4���;Ԉ�L�6*ݭ�Ϩa���頎���/��>���RJ�*ˀ��F�=Njmp>��Awd%Mk�` q��;l�v�>��9�|���J�:�Ye��2Ѫ�3-��G�&�ܴG��Aa���|T˺:�K�O�x�D���z�b�F�Sډ��;N(���ʉ^�RQSP��þ�"}��<�ޭQ+i'���"�͙�Y�C�X?���YAs��ߌ� �,�D*���t�^�+�]}�(EL� �}rU��^?˧k�Ѕ:��ς)���/\�+�)�
�X9Aojӳ�<��.kmIH��~bCM�'����Ͼ�F�pD�~<q̠M0y�Z��=��yd�W�G�eG���A_t0���/�Ѕ��M\�l����&ӈ�ց�sX2�$���/W~�$bpk��T���܎Y_
Rщ�����N�,��Ԕ���L�zsY���}^Y`��N��   W4j��g�R ý��jJi���g�    YZ