#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2195808441"
MD5="2c414bdeeec20af20cb1882a71f1d1b2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23072"
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
	echo Date of packaging: Tue Aug  3 17:42:57 -03 2021
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
�7zXZ  �ִF !   �X����Y�] �}��1Dd]����P�t�D����Z��c�"F�Z&X=��ъ�YȊ��i�Qo�"� %\��H� ��P��FaQ�\�vp:�W+`�Ŧ�EC+�Q�V�ǫ^J@�����(�z�&�0������pK�����/�v�W�7��9��/@Q��B��Qp2�LJ���jpO�\���k�~W�Ѫ�pǹ���c��bX��z���?�p�/�f��b	�K��R�d��G�=�ǉ,��E\��D1�g1���S/��{��uY��e��|�%�Ms&��b꣫�e���lJ�'O�{㕆�9;��!�2.#�!Kx����oJ�ۖlQawбRi��&T~z�JϗO�,���L�+�J;&ǘ@��}.wd�9���D��x�)̘���׳!&��n<'��}>9�d�O3T
0��Q	Lނ��o�B�Y��ZB��Q�4�F��zP��_q��V�&��sR*���LlA���V��m�|���	@`�֘G0Бޭۚ�PC�H���Nxi���z�����:�b�N�����s_����QNA�z�Tm��\����������򔉁���?��`T�^o���(��z�'x���Ei)~>�S ��:+k�8��ZJ�sݷ+$�,��U���>��cT�UA򄉹��(��3u^l�����^��h`��(��MiWeY�'(�O�����3yȃ��w"�L�����m:�*��~�~��t�ap��ʘi ��C:���f��= d�^����R��s%H�1�x�S�l�� ��វ��h|����,���G, ���<X��������VҖo�����_:����X�v���o�7�@��K��y�7�B���z�<��t�ׅ|�ͯ"za��N�63x:�\u
l�C�.c�q��[tD�l�Z��
�`�/�9FJE� ����iP�wK�_	���?&��&�^_y�֖�:K���z����GW��*Z
�O��eR��+fml���,��S[?���=���X�d݋bVP�G��'�E�K=���î�;�����rm��.Q���΋4f��F>P/qX�繩�0V�]� ׿)��i�]��������B���]�R..�5!���ڻ:/Ir�;T0vh�:ӿE��C\ِ�\�/��ޏJٟ�H�z��z�~Q1qa.�2u�G��w
1�o��`�ET�B_���l�傿�'h�/� 
���`P`{ٚb��-������*��r��I���n[��q�t�%�����<�p���s��$O{c
��	� ����V�Uk�0Hn�Jh#��T�� $����B�������zG�1>�^��$����"�SRe�rP���%Gd�@v=��n�1Q��3��z"g;g���!2�ޠ0�r*礰��� hU]�^k���T|qf�Y]�$��~�.���i[�C�L�JO���(�#<�<��a�������ިD�\�
�����eSz7C�\#�r�\��7����:^#u%_�(P^�/$_J�*EQ�0J�j��e;B�?�����/k�8�s� ć8�O�/ε'�j�h/Ŕ�� �[����v1;j�B� ���m��|�a(�4n,�>x�/��E��_�w�p�LU���S\����ӴH*�d[4ײW8��g#���f ~6=i����ײ��H\������������)^+�&�|�n*d��*�k�(���?�G�&J�3nE[H����\:��~�V�^4�]�V���Ϛ�7��������q�7��v\�Z[�א#|X[�O�l�,t
����>�҆�yI��^3��]���.�c!�G�K�6��g؜_��uo��׶$��^�^�Ň���$,� ��|���g]��z��o�2d㶎5\Ҁ-�⦠��;FxJc2�v7D��`̐dK���ɾ~g���Ku�F����?�G�u�e�]%˲�Jm�<�]��E��CYbo�j���<�����M��b�%*����ч��[s=��7�D���Q+B*�S����jp��A`��7� V����J{���1�mt�k&]�h���I��ms��ߔ�!/R��&��':�˟.l�����Z�wl���2/��B7�6A*�U�mmBN�K�1󓞊��#"ѥ5��~�����K'�����[�Ɏ�r��:�Jw�R$�B���Ա����%���<�*hl�#к�S�8Q������$�r�#�:R�s�|��ʓy���iA��h�a!g3�}�3�t?0L ۻ=3�>��p (�t0p��8�	�jH*�R�
W" �2��O/Ss
�s���gwX&�lX����(�R� Is›cZʄ�P���S#Tܚn����|z��+�d����ӂO&c�$bN�EAf����*�����{�3�LPP�r`���CX��G��!�J�m;&�}�p�fw�޾�*=�������e��^��5s��aj�m-�Wv�8����o�.���Ӓ�QR�^�����2*��Tc7EO����53��$�}��Y����[?�<��|�歛L��uN'�p�E�0Z��Tm!{G�����A������;���:���(�ê�/��[EAk�������AP�eI
�(�Zr������ţ�:� 4��U���RR?�Hߨ�U�]2��oc�^����z�� F���0/�{��&�j�t�	�������!��Z
U�����I�D#ds�أ�XH�g���S0 d�{�i�Ц[ ���<����r�=�#U��gb��R��~���U��� ft�Td���o%���̓���d�!y9��.����"�L���=�o��T�ƫV �5�3(ȯd$��`w].�V��b�Z���h�8qE)�QMn�k_�k��C�ǌ��Ԭ�+d2,�z�0����ˋ����D���Q.J�HLL�)༽��X���ř��~������̒>��YI:��"4f'��͡��M��2W�a	\{�GƲ>R�="�xy��5Z~���H�&*tA��I���~I��+��)�� ��HZUtU|^�<�TT�Է4�l���U���XL�̫�X��yR�tmz���־�+�c�R��~��eǄ�J�q�P�䲳��B&~nS��Hn�ls)ܗ<xEW� �3�%�,���fO�;έ �;;)�,��=�~�U�%� ͯ,QUs`�vw ?�:%��5!�G����6�/�UH�P�q�ter58�~:D���k�����ړ�
�Ca7rbaګ6�+�\f��@e�	���g��љ�=t��W}�+�[���)e�<�~Ը��Fʨ�zE��Σ[NO��f�1ߧn�Ri���Y�IeE�,���x�!�K0y��`�-�� �[���6�S�n��p����v�u�;ʲTHdXM��ok�6��r�|2N��m�X��3�۵7e�csX�>b�a����k?�؞m~�׺^�U���8���t��]�9 �K8�7vYk�?4�M��ǙI������?�߮]�-߷�,����O
�`��y�Gr�P!�D}:�O�o���er?g1��@�m�2"��m)όܑg/��U�O+�o�ߊυK��v�:D�)�3�UK��<]2��������z��`��6�(����Lh�-��GR,��C��y
D�1���v����$�?���n��u�ች^�
�ׯ���bvk	l봪N5}I\����̓��im��w���kI��� X��}�J]R �fd8�ѳ�٬!g�\u
�;���J@h�Ei~��C�ʁ��K�pN{�GG��Ძ(�0G��X�v�>X�M:�
��I�{VK�v���tWIő�p�4��
Рҁa�é�rPY���Ҍ�JHV�]i}�#�a�l��$8	�tg���̲��C�oZ'r��K�X|�H#�#͉i�4�!']
�����(�{%��୭7�j�9�lhB��Ba?�V���-	���ȭ�O>V��+���Ꙥ�dO��cH�9j���Hta�'u�`׃���ٜz٥�EڿD�u��&Ns)���K�M<����k�s�1F�V>��N�����#�c�GԜ@� �a��]JLY��o���9gES���!�Y������}C��=�>���T����˙b�Wj�e��V! ?2y���&AU{E��s�}	���hAb���O�e_�z����?��1]��n3n���c���!��3�;;2��Q���������e�Z�^P��rq�k��I��4.�K����A�)�,��U��i��|(=8��}h$��y�}QTl�Ni�B�0�^��.���b�Z����v��_�x�P���@dI �'S�"�3��NZ���ԕ�}@h��tfaEo˾o�JP���k�٬��c����b �X�}`���/�g� �x3�����l%�D�i�<!��*�$�9�1&<�uH2�\A�ar���<G۸y����6o%ydF�������'� �x��_S��ߋr��jF5^* �Lk""QP�V.K��N�������7Cv\��
��a��E�oSi�Xo���nL	�����~�p��ܩp�B�S�ZQ7�$�#vP�D;���d�޵ڠ���G9�L������̢1-�������)�W�H�k5��܇a���μ\z�QWo��*e��C�IR���h��Y�ΈM��Ž�����?�i��=��C`�2���=h^ć�B��%�D@#�P���=�iZYM�.aH�7���V�3¸�W��(@ϲA�`���}Ch�`%󤔼��)~�o�8w��k��ů»���i>��)�Q-�q/��ٷZ�%����Ly �X��O���ƜC�gn������XCzHz0V1�m�%�}��3c��M��>�-������i��'F�;�� E���'5bz���~(��� eQ`�L%�0��%��uBR�,n`�-�2$?�!g6��
Q��Z����j'l��m�=��r�m�=O��W�[gU`�5]����w�OM.��1A�\����Q=�t �MJ'�N�ݰ����g��gy�o�Ϳp4JRn���U�F	xHfA�7�>�q�s��Cw)����i�级Wh�̅#o�A23��g"׻�8t�^�2Q߄�ū����2w��އ��eP�ST�9��9!)��UX0x��7F��l)��P��
�C��]*ғ�G��J�9�q?_rg6j��P�F��?�-�m��-+D�	@�`����'�V��%즤4�L�3{I���i��һ��_W_F�hcQG�beϵ����ֶ��D=���W�&��3*:�R�kK^Cx�?�]�# X7��v}�GC�#��W���"�@�!$��H�08ت�T���9}�=W�'$��0���-�'�V��Lac#�3I�#5	������#{٩ʍ��#m6��ߡ.hَ�"���Jc�|��j�˩"�Ne���E^��|pX�n���u��(��dL3Y��|�_�/��U�a𻲰���0=tU�ӊZrؘ��E����ۡo^�m���̶�LAThbgZ�̕���^\�5�����DB�teb�*�����_�9S�%���yk�t��Z��;������@gӕ��MH��L��G��ծ�i"L�>ȗ�L��b��k:�<l̵�bE%��c9 �ny��#?��w紗w�f˗0��-ydk=���>�ӧ���U�����p�?���H*��p�N�(0F����Q_oa����
���<�
��`�^5�~����5�e^v���h�k2ꢀ�ai��`�b�xB�0�|���vz�'DjB	�{����?�6��ﮀH3�	4~�:|޻Y?��CO�}f���ueH�&Tk�|�K��w`O�cv�V&2�_Ϙ�l��2��0��β>M"�N ���3�m�0�T�g��ņ��;Mju�h�qI��8��(���ۡ����')�vn��=3�^�;�
�Z85��=ɓsǤ���6��6�K5Y��P#��ST0�"�c5�IxAF��+w 3��d�	�6�[)O��>]�~P�J�ܴ|2����ʜ�]����:�c\l��7}6~�ׄF��ݺ�fO��H%�E�ѣ�-�eQ9wϣ�<Y�����Wcky����I�N:�D5��k�M��|�{M�Ein��R��+���V��+p����v2@k���3Z�a/��s�+�3Hc�G��-[b���Yn�G��_-�5+��3dY7�P�/���ݭ2D>/��7��In�2�����2,)�0~�&������9�G�=M�de�IK=�H�Ϸ�� &��ȇ���0ANI@�g�,D�UoL�i�bS�'נ`�[&q�M <�@���4�^/k���+��uߡJ�[��orY�%�����:��gQ%ݤtA	�`Z�|��<|4����A(k(kc��O��uq>���aa�{�*
W���L��W�CrJZ~�{�B�0�OԳ!E�(�c?��^���߷�����F�uRr�5����[Q�Zd���'��~�D�nJ��5-����:�Ch��_Bb����aK)�9m�U[$� �`P���i І��⢶	�g�g����]c�i��p\>���5�.�H��Y�����Β�*�.9��@��Q���R��F�U�%�m�K4U\<$��չ�zsD��~�sܸQ4'����	�U���۽	�<f<�I[mF?��))�KfO|�Zklb������PIW���F�,F߅78��J�Zj,����P�rd6h�E��+P�6�R��d�� o�|ƫ�~��.�gf�&rV)�O&�W��+�U�&ӽ���l*f�bLH�J����/�/j��n��Ċ2�xǆ�bh'��f��BO(����2���;Ar뷸g�K�����y�e?����	f�3ٍ��w]�Hy�.��J�D�/��^�.lb�s�S^y��g�U����Ɉx�u����]��� d���c�:aTd�o��2>)� KI�i�0�!]D<�]^��W�ě)���PT[Q�J�c���,�x�inˡ���T]*�_�_�p*ܶB���[  �VN;?���h�j&M�(�?L��4���٨���IH5�1��[�TTFT����ב���k����A�~V�^����%|J�^ZB�JzLY�}6�]p��"�f��ZB�>U�Nd�s��y�(i�嵓��j*�SGP�Qs�~L��M��J�%1�QeΆ����e�I��uG�f�3m�ֺ������ r�P�D u|}�s>s���ePf`U�rw�%.%�J�S�s%�dQ�X�f�S��#%��H#Ʈ��[��s2��ss_�@��sY���5���fV��0ܩ�.��Le�ף�R>�����r��u.ʸM���n���y.=�b�}A�����.��9���[r�}{R��N������'v�0߻(�5C�n �ո�P���&fB?I4l���I��H/�����v��3#e�m��z�1O�&�0M�VBb�f���q�.�.���׫W��!Vw�~������0M��R���sxCͶ1����"��(�Ȩ�+�~�cL5������V����*A�f~8�i1�Ԣt1<S	BN)������6k�UY��^<�@Z)KA�ڳ�3�g��h>������z�Ѓ��5��ɟu�����o� N,�
g�
x�<�5=��&���'X����e�03&��я@vzd^�R �Nz|�?&�%Ӛ�����{2��q�en�oeu��e}~�;�"��-#�w	j�"���<�go*;�^�Oz�}>��ߪ%|����H.i��ry�ݲ<,���WĉM�	@-gBş�H����\z��c���z9E��(p鲸O(h�֔We�9�ɹ��Ű�5�ְ���F=���KR6���4�����4_Ӗ{�g��A#���YR�5��O�Z�\,?���EJ���q�+4��w�~�&+5���P]��b5 �8�3f�Vv�������ev�����0'L�ߤ/�ϰ��\��m�DQ�(*;UX�-�)�����c��5�,M3I�Q�W�]�X��,B['�ξ.r0�%m�3��ol6�6kH�5�!�;��ז��R�S�4ۆ�Hr��L�T-�j.�����������jK�)�j֋�u��T^��Rt�Ƞ�"�[#F9�٣��a�|y#~�A��Y�dP�C}�m�6ԥ��G@��GdD��!�4g�bx���졷��E�bYo{w���d|��J�v��uXca�L�mv�u��̢"��A�V�ńA�$e�=�ޱ�F>^RFqN� ��?Vm�F�2�:��� �R��2Jl+< �p��{i����j@u�h��d�v$|^KD@�/�f��g ��]R�M�4��"��|��Y{�?�cj:z� �Uޢ-�����I��g�b0�
��~h%��M��kVc������o�Ў1�I���vw`��3+}G!�*���[*
_�&Q|�
G����dX�IkB�NB8x����щ�l���s���1?l27�8�;.w�ܥ:�.{1���~D��y.� F�e�aAj��|k�Kfz&�A'��;�7n��|��hJu��w���Fb���6��t�C&��N�^���k���V.�j��M�������19=��K�kME���? ���I$:4;��X.�p�t��ɡ��n^�
�/^pG��g�RM5��Uf/LV���L����<��_����O��mX	��}�l��b�B��n>?a������?Y+"DY����xڧ�����"���̊���$~j���m��S��1���e��%�8N�B�i�ZX����^�]ԯ�O��"w����)����1���2@
�qnǚ_��~��
��)I����Ȣ>��|,	H���ö���B%��Ӊ�!����k�����@!6��{�o�ˮ8c�u�a���g��M�ʧTm�k,ٺsɞg'��x���.��G��.��bu���w�z�n+~�"�#et�1#~cs)ج	5�3 ��U@>_�D�}�H�6j]�n釆H�2.�R�\��#!�v�Z�p���k�11�����?\�$�Ƒ�T����٪�%�в�G �9��3VŻL�%�wu ;G��[zv������۝��46�,f@'�֛��G�`^@x�/�.�FЈ�	��Ј��Hl�*�����`Y���u�9XJ\1z�X��1���I��)v�}��h5�|g�r��d���<O�\�x���%l�g+�e�ڔL;цR�	=$#���0h��]c�h>$�ZY�[4d/T<�zԛ���;f04��H�V``���+T��ޞ�a|
Dy��ij��B�`
O$pY�bS����ݛE�i~X�k����g��-��]�cM)�M����\V�t�>��
��w�B� v?A� ��3��.+M.7�? 	�
�$!(�U_*��
�B��U�Q�b�n�2�+��ّ���Z>��FP2U���S8�jv��3�90aj�07�.�{KQ�->>��}n�����f)�h�����JEp�����@�<p��D��1�;�Y&@�qb�z!�������ي��9U�Mͫz�	�|�L$�|�h�VT|��J�e��*ٔ�����Ѓ|��J��vb�5�C/g�
[m�M�b��H�:�h� *�6$�rd�gj��\/��^��B*>+�J(��[1Q�lEW��,�M�w4*f�����O8 �xܭ���nfvf����[�!eIǃ���Vy�{�Vɂ�t?Z	��XL�.�����R��`13W}��[\ �W#�EFab�&s��8��L�8���du\���ov��A��˛>�z$\i�*7�X�2��܅G�n5�M_\�ˍ
����<N M&���yQ�D�Ͱ��o~+Yų
f��^�-6��CᝯڢriV����i��m���s3{�+H^^p�܇��
���u �_�n��{�����_jݜS�8&�{i�犣0$>p�2|��P����>��, i�~а���I���>-�
t�5�Nyz{��f��N��\���f�H��xɮ>-68���*�&�d�E�l�D0����WǇ8"���l�0[�s����	'���z�uv��}U��>R���DwQmC���q���$���=�g��������F��"{L����G�|�m�h�ᖮa��q���t���.�F�	��d��~:⳰�F��=Xpa[fS6�Rs�=�����"�� ,Nb,�T����7��5_'�w��3�Tt5݄���dp>�zކt�p:���}�a���e@��`\z	���9�HS��LT.��nz��=v|\�`�D��n+�>�0]��lJR�)а�k�f�c%������$��$ib�-�2]Y�>1{AL^AB�s�i���]�6���������˔Ps�C���Y\���,x�M������S.��=:T�y���rv U�[��Q��m�~�4p���ߡ���u=i��&��m(�,���ل.��؞ �p+���W���[Z3pU��{I_`-jh�W��PM���A�f�9Ӝ���I ��Q�(5Cѯ���|��i��m����ShU���+��]�;��`е:4�A�|��H��f��R��1`����w�%�=>�j�aB^?�G���V�.���w3����ke�F�� �(�d�og�����@�߮XsS���0F��y���Jq^�����_�g�=�e��Z�G�fj��L#3�~E�?�5yX��c�q�[��	��Hb�x:{S�[qY��i��a��������*��l(�G#%��S�,N�j K���"j����j�޺A�LN5��۴5��X
^���i�gcI5�;Z��]k�P�:K *�`�Uqטr�>#]���T��?��RT�G��&��O���HQ����8J�TQfЬg���ٛԡ/Z���!�'-�� ����4�($���[���#�x���pL�|c����)_��ȯՓ�,ڣ �D��q�
�њ/v4T�_q��Ǧ� A��z�V5�'%D��C���Tm'=����#\�}�X2��Z�Zp��W0�q��!X}*��ںg��Y��^�'a���(�g_Vj[��pcp$�k=_	��ɶ9��"��3BW�DWߚ��7�������Fb�xYj��W/l�#k��|��'x 7����]ňܽ<&#�L��R H]2[��j+"}�������OXi����Ln�̇@����$N�ܮ�ʾ��z�������P��<ܛ|)o���`����s^�&M�*�d�O�,\O�{q:��_�ՊS�)�r�6}�^s��ً�;�%��ْ}�*jn�}O��#�����#�9���A�]Tu,��q
��~<�~�(�-�*����V�0�0���U!���*����^WHDsQa���/�t�J��(����2-ttȎ���]�t'X#�J1[�3�>��f�,g��I'���R�R����E�HK�%�8�	-�P, �A��D岞���Mc[�F��,�4� t.�y&F2TRL�Y���l�J���� s����Xd��_���Ӹ��;*㺚�c��:��,�c�a3�G�}nwJ��I?7�
�{L7�(��Y�H��,;�l.���Y���Z')�z��Y��7;3c)˔!W�+��!V��>���.:ٽ	1����⠭��s�7N!�8@����g���$�j�_+tC�}�Q���<dhC��@���ڽ��`~ {h�̃qǬ�-�q�3���j,�f��ƵP�k�.þ�� ���nl���Ѡ�pR���G<��L� �u����A���NBfv6�%�Nɰ��KoE?�q]"��M�����}�^C`�pc!��\Ս�����g�7��uE y�2�x:�Z��Y�YSv�j$������ĥ׆�b��YhTL��X�1�5rdB�s� &�}����U����^@�'x_9��4Fߧ�U�'�1o2��Jd�[j�8�;��-&E�����b��A\���A����\vq]�{�����Vh}c3�v��]�_ȵ��1�wgO�'��|+Al�
f=Vk����ӠE�8?])夥���s�E��GAB%@R�_���k��\��%�z���:�xƲdIL)�p���+%��̏�%~�އ�y�%�U�mvi=O�>]�v�d��~��(�Z_,G��Ʋڑ��Z�yt��V�k�D�(�Ep��S`~r��Y�*��7�?c��MoǓz���+<�j��W\�~G�Wko�����:����&�o.��`������HաR��2OM�=��[�n/@ G���q��{ZG8tA�A4,~Eח��?{�P�?��d��svÓ���W������� %ЈT��Mg*�%"��H�Ā�Y�d�S��;�%�%�ۏs��P4o�!�bW�rr[�O�@��"�
��f�7�I1�YKɢ�Rb`!*�pA���^L[zѯ�e�Z_�(p�!-?Ʃ��Œ��%�xI~.a��f��~�ݐ�k_!�N���_D�n��5�O����)7�9��'	ot'��\K-B�FZɋC��1&b���~��1\��`K���]�zѕ�����,�ߔq��U�M)�+F]�B)a���h��ʴk�ٝڒb��2�D�5�*�۴�[	ks<3�
��3ٞ�����=�u�)`�\�\����Q�B��ZQ?���i��l~��&���g�f���v1�BW�pz��ȩ��$�N��!t\3�%h�ln�7I�3��@c�yA�{#���9KEz�+�B�uW��\��^V�����_��b=gǷ%��Zc��P�����<6K}�^H��E��e�g�s��#��]�!i��BN�m�,��s:$#���w���]�zU�b�w�͛z�$QD�E�$��Ӫ��=��슻r���ؙ���_8&D������l ~��ȣB~g�*t?��S|<��[f�v������C�?m�Ĩ��C#*���p$Pe�BL�b	U!����q�o ��?�d�ߺ"� /NP]� n�l
�k�Y�p b{��G6Yc�M���X��,��6����8���}/X�ǐ�C��[�<�h�H?��[%�n3���6���	4n��Z�p��c��(�t91�R	�!�m��X��b@�X��_A�N�x��>>;�d���0Ӈ$���M~n��r��H#r���bo"�km�;���@B�g~�1��<B�@��Q$D
㸒a�ak1���x�}�o�e[^���B\�N���eb؞�NGdM	�ߍ���BC�)��O��ʞ�`ƃH���9��ٜ*��C��n����k�N*��(Q�AM�w He�ڛͬ�"<ߠ1��ڒ��Dn>_��tn��o]�\�uA�y�H�QuD��e6�_��r����0��-:8j��{H~Ψ�f���.ߑ3���"�=�#�J���J-k�-ֱ�]�&䓫���ƙ	�:BA��x�RZs���@�$�ȸ��׀���4G� ��a��] d,��G��(�2a^��TVNԕ,�\�,[�D|X��h:I��I/��cV2,}���(E�����t)�a?�n�E��"ؗ{�?t!��/�D���4 ����ZV� ſlv;aaY�L�ooM
��l�8�1�f������g�V�� ���������$T�%��F�.�3�&b�3�j���`�m��,�����I���g`�5��ܿ�����$�`u�>��z�Y��y�.��*	�1\6p��n�#��FG�T���zd�c��h|��]̗D!º�(����=g��Y\�	2��ik�� ��Q��&�8��(e���@j��j�2v�ue�̃���u�ۂ.��14�7�PWw�t�ܨ��6t#��ů��V3=��Z]�[Y�eI��u��z�	L&�1�����eih���]��[�XH�?|2My@��N�P��ȳ�yS�ȷ�Ui�u��`��gX�����ZT�p�����Ϛ�:��wE1�
�>�	֡,���ͭx��LZ�U�	�d^�s�)x�Q㳬�Ւ$Z�ǒ��ˍw!�ŜB�Y}?{yV�8n�3Ή��d�-Dq���r�uO 0.���i4���F�����ip��p9L����Ҟ��:�0	����T�`�B*^�IZ���sd*gٌ��IVG1L�8����둓�D�+���P�J��������t݁JC�m �4w��dY)�"�xi����Y���\�mm�C�]rc��933b+ku1h�]G5Z���@�k�G�Q��S]�|� �j��)��'zr��qLk_I�*pR����8-�Sn�J�_��P�K����I��Y�0�ᄆ�c��w�]+Hp0��-��Flx=��6����oo�Er��np`�Y�>1ب����sI�mB;�1B�&�YBP�+�M9?Ж�3��\�����K���``�b~nh��t���FS�$s��ag畠�#λ;l*;�f]�`<��z�f'�%i�NB�o-@\��n��M����Sp1�XS_��0ȅb�t�kUV�1Cy�g�*�FovG�ʶJ�����2zaG���Sw���e@���A|��1P�v�r4\�­���������-JwG}@��i��+��@�m������Q���;�8�-0ݳ��X���h�϶fv�2x�H�v����yjئ��V��[�v[���b7jj3�J)�O�� �
�D":E��/��J.�i)xM�w����Hi��%F�v�0�L�W���"�n��E#5�b67z�Ͱ��- �lE8p����%La��-q���N�J@c�i�ax]^�J�c^�P�x�Ⳏ��ylLR�O�:ߪA�����Փ@b��CV�9I+ٚ��P���h��b1��8�j�/�d�PA{1��2~l8�cqnԳ�#�c�c������.����!�'cQ@�KXFᑩ����? ��Ih^���Nu��Ia)���b7��DcA�*tn�P�]s�������60:���k�.��>pk�z�WC��to*EjI�Os�=��5����8�*D)���h;KM:{��M";F�� �k�TU�9�BSG�]�������gŞ���I���	�l?愶�4@'�c�b�}Fa�� ��e����ϯ�!��W�2�fSC>��U]Ba,Z7��:M]�^7�J�pϩ�p� ��M[%T��>Ntb�/�C�V*v�"��C�b������e�k��(u�����+ r���.�*��r>���Nev�B%�/ ����r}��S��N�
�f���k�E���~*�U��?�}dkK�W�-c�����<���<�G�� U@eG�XL���R��[���3�u,�$~�:��v~�$��o�����D/g���G����l�L}��t�$(���ˇ�N0P�	=�'D�{�Yuu6��L�?Q��I�D�O6I�,yv����C��U#���y�o-��"3�Ez�/���,&�l/��bbàf���\*�u�z*�,���l�rY��v���E"�S�� _2Z����C�'t���@L<�#|���x�����'ȶ�<t7���2+J��!���p���M�o�½?Y�Y�WN№f6�r4#ɀ����O��~�u�����SW)a�>b~�|��Db��9����=,���U�ysNSB��5���������0�el9]F-���`��_�H��}䅜lv�7�� :��KP�Sv+P�«�P�4`gȩ!�͊*!+�k.##``��x|��p�#��;no��'O��l!FO� �Q*K�H]���O3�n��S�`����j(cc�)������N8p]�4-�T��]��+���9���cA�Q���nn�!KW�R��L�W��d�e�;�S]�^�pP�-3Ouh�?F�d����z� W�2En=�尗1����(�.��iE�D�tKe�Iw��Ck�A������v�XG�O��_�V;믩+fj���Z��c�m2��?��M�z�0��;��kj��ZmKb�B��K)8�mGes-��1!Gæ3���l/�S6��3�����{X��)�z�Z�ʍ�e&�Q=�U�e���1��m��9�{#?�	����<r��7����%A]��o�h%������1����-FɅ_+����%��A�aVm�AB��ڮ�9c=���s-�]-�(�\�����j�,2�6���[Hy.Z)���m����k�������Ă䏑SK2K�?���)���ѭ��4XDe��s��n��~D ��%��nix���KD9����\�8���TQ]U\��M#@b��������bKt�0���T"����^��P�{1=.Ns7{��� �(쩎�����b��(T^���UE!e���c�an�A_D�c95�o	�`��w�vY~	���_�?��aQ�(��F��9�O��xW�Z��r�)*��ށ{G6Ｐ�̇+~?]����A%(�	��O��2�0���̭r �SC�J��c�F�Ok[�c�s9��(Mû��0��d���Y�ï�OUZ/�_c�"
�π%�+��Ru4JyI��k���&M�"H7ŵ��%
7M�)�E�ao>][������Jf�!�\u"��r�+b�G}b���{�?�'��yq�b���G����ؔ�P��J�ۛ��ϗ���W�?6$nE�*�f����ϳK����*	��^��������b����=X��8 �<��Zq����{~\7���9C�����b����ZD55~rA�w�5Բ%�BY)�t�E��J�y0�Y*PlI�V���v2d���ÍGkO�*�I��j��'+��>#+Qce
�Lѽ�¦Ğ�i�ܓ'��‿u�#������A)��RD�k-����-������*�К�)�����r!Y�pc ����9dI�U'�[�Kz�)Č�(+���]ԓi�Oʌ�=H����ٍ$�P���e��:g��U�`)�t�W�}�V�7���~��u\)63�X6��Hƍ�{o�O9ڰ��+K_.�(���خȖIs�y������:�4����
������� �̸����[�0���~l�ٮ4�6�\�P����'�����i,��X{�~���/���e(�/&ڗeuz
�z��BG�����~�w2�U	�b��ܷ3f���ڷy���h����{s�����&�@4Lc���r�g׵ʗR|nOo��9�u#y��q@���Yd#�?mtU���40�֥`�� ��x���Z��7~�`��/[{!�S~�F�1�	��Dچ�7� B�K��tA�T�nZ��~,�ƺ��r]I�����4�������"�X	�=%��B�0�g6���*�-J�v\:�r�(�|�*�^��=0���Ӵ��E�������1��4�N*<*�����,X݄�F��
�r����n_u��O,cy�9Ĺ���0j}Z����lqp�!�q"6kjB^�aG���a�"�qm@�׀�},+�w���N��c�0�a�$烕@$��٨+V2�g��J ]��ҙ�ۓ
�3���u�VG��~�!D��{�.�.SC9{ȑ�Ӹ�m���?\O�6�)P���!eA���R��A^���yC/�E��c*�<^p?@fO*\�9U�4"?�)��~�����0Y��4�㙧8�4+�F�6�f�_n���P�I���������fຼ�S��5��g�#�~��I-�#�����Y���6�X���T;n�		@A��0������p�@Խw/U��|�2rY��/`W#�_>�*�t{��v�x��Qd6!�m���ÕÇ��F���rld�tML��Bf�RR�/���b��'6�#�p��{e>6?�[�b�Em�Ys���0�0R�v�.�);�cv���z	�/C��a��M/SK��l@BW�/�)��
T ��Ŷ�Zc�O�^�¤*�D6<\�ץoJ�a��������(�{�0�q�&ig��K�O��@�)JW��ͼ�8~�N�<X��!9�ֲ�%QR�y��U��r�+ؓ� 
7|�W(l�őrxY0&�|�ː�D�b�6�]��Nj���5��x��
���2`I�y���4��X-�'sht�˲еgO��T:�a����r�wWߌ�N"�`�S�\�M���u��4 �1 `.z*�h�4*
dY+S�&�L��+����sT�q�%�DN�[��(�i�?$��fמ�y��Xmڿ�� <�m9��4�zl\V	i����J�E�5���Ê6ϩ	d I��D���0�42�!|��=�^��#�2Z2����5|~���l��мƀ��0�R�=y�����Fc�������:H��;�W��1���g6�d�^�E70aЍ�x��10�@�43d�������K#x ����a�����(Ϙ��V���1PE�5/���T�L����n\�x���O�`�k>��l���Wh��q�q��!:\�q=�6]+�3��d9�	�p�h��d�.���P�6 ��6���	P�Lۗ���Ȇ��_%&�k�K��U�^��'y���eI׆`1<��p���T?����AM��Z<�=.٠� �3v�z����X+x#m��0��s#��)9^ndC�X���n�O'�<��A�Xu����L�}��{��4E�%�al��s`bx��#4��N�
bF�[ם��%��D�T��q3)q��c��Ehx�8�z�Ff���� R����O ����j>���&���**�#�q�c�5�����c��6�p�AY���,�	'�1�B ԡ�DC��J�:�c���SQb��/��Rp(B��B�l������cO!����b�Iu]����H����v�J+=��sceh�nػ*����4�I��5n�A%{�9�zkv���7E��>j$;k� mP�S��"��݈����ax�B�C���	=�nJq��U_�p�-Ĳ�Q�iD�=>L���w1�)�aז���9��l�޻�&�!1�神"`�+�F�"v̚��4�I�Ӻ$̴<ޜ�Oد\�F]�I���%������k�r��v~z>�߶+�M��B!��{���Ӝ�|�JP�D���5�~0�𿒏e	9q��	�}0�{�Hɉ�-���P>�4���Z#�$��4<�}����� I )ͻy��mp�'�j4m�W}D��&��[/Hg6����w��Ą��M���,m4e��"��)�Y�m���yۖ��,%�� ���!H@tÒk��?���1ї���+��w%X�M��P�bq�T��q�_N�FZb�L�i�L*�̵o�S�g'��p���CZ-�u��܌��v�ih��!��IlT@����!H+ىQ��.��`�
�X��UI�i��XT8�ˢ�N��g�i��8j��������	�T��3�H��L�X�peD}KB��t�],�Y瓳Y6�p}wx�M�g��R!�ȭ�eS=m�ʷ9H����������E*���`�k���a�O�
�E=��&F�J�b�������e�4�V>�Y�Y���mN"��@*��Z$!�|Uz�H!�s֎b��-	�hA����Κ�jE0/�s��Ԓ�n�:��K��!��ڇNVM_�jA��3��$*/�VG�����E�U�I��Xy��� w�0���^�Ԗ�Iq��̬�yy�z���_YpMB�:i���kaO{(��R���`V&P$�S���)v%��,��(v`Fa�b�t���r��!��𽄒.ѥ��i�]���!n�;/��Y�)�]w�-�h��1XM�֨�(�����mrC��^_�}�\�+*��A�|�ɠtf(��U�sLG��sٯ^��a��N��/�%��e���+�rpA�b-Zn��"�b<b�?��_~�u��*��v�p��1`EŖ1�.�E��d.�������Q4=���*�(f�J�5(���*���g����	�K�6|�Cun����2��͇���)���lm�mp��M��N���f�'��p�JU~Z?��I �y��*�L�e�ę�Pѩ�0�s��o{���9���r��O&���K� g����V���[���q5@@{���j�1��YM�>��
}����ڞi�3-f�tզW�^n�_���l?�pz�K	�L�b*��
e,�_k�����k�
�����ȨV�m�Y�i�����5(�S��.X^B��S�&5#���.��ę���t�
յs|��:%_�bc�; DgK���t��� 1z�dI���Vʐ�����22.
�fmD��R.�M:�BL}��i�숡-t�|K�a ��>)��1���!�W�siv�cW�� +��ɰ wAҺ��sz8��%u��+h+G_8&qym�}j�| 8lV�k�lAjd�-ޜ�6�zߎ�H\EI��r�H��EN"w���B8�eU��w��$�79�៸O`f��߆d�,;�Fx�D��bcMBvh�!��_M����q��s��5ë���oq��気��D-D�B��(��;K$*o�q��uNHF��Ԯߐ�/N6���4ɜ�
��͡�	S���ݸG�1����$�u�v6� !��B��=�s{�_1�Dܐ�]���.)���(աCϛ�:R1�y�{�?۵FJ���=����G�;w�����uJ�:�G�	^G����!�p!��A:HH/�iݾ*�n:��]�p�^�},H���=���.����zb������-TX)֨�*7�7��8L. �b�����<���6:T7����S�}�^�k"dxE�ΕU"`��G������i:q�P<���우S͟���m�t1���֛#ߍ��Up���z�2WP�N,5���H�}��2P7M��� xQ����,{�a��4����5����FV|)��4K�e	�±�qa��	A��j���m�PPR�S�R]�c���4�K泡F�L^��qn���=	����Ql>$Ľ}�%�3�Q�6�3�u��÷��~u�%���%�j�,M&/��H��~G #d���%v��Tu�p����V�e��]��SK �C�G�=r�	�@!�*u��CX/�Z*k���ݎDݣ6$�&À����5�{�펶rL/v�L���j����עzCDߨ�1d"*�3��X�� &8�ք��U��(v��w���v�$G�"�]�%5��hK

��������Y�8���J$���a�w�%���ӡ큺h�s8q�ڬa_ѹ�ǻ6�L�2�=��n`/�dDN��D�$���ŧ`��0��u6�����V��V �3�<�/�����j�����R�Cd0f9���p�f��}�İ�푗\��(*���Ė ���t���JÕp2Z)�iN=+o%XX8F�Y�eFbہq�\�j�������6�>��v� Å
=�}����C��18�&/V�z��!��&��Lx��<Z:��8UY���ID�~�=E�������&!c0g��>mHa�՚����-���S�^�}!آ��?�8�A�0�U�M��k;H/��$�x-�2}B�ߗ�Ԫ�чǎ��:�j�G���)�=����V	�b����e�/�����F�/�A�M�א��\��9h���f4�!c퉳�o�D ��D>��gx�.�K��;}g�f�jӭ(�{f+���E7T�7i��C�o�t3tz��T����GW�W��2��p{�E�sܳ����΀kfB�~}:SR+��2���G|�U��\�NOнc�1�~��a���΀��ؿ���=��N��(����ѥU��!����B�=�����CtN!�����`���I�ԅޗ=����|�B�u�ګ�+�Dֳh��y:�]�zh����M��!�音����F��k1�R��u�k^@a:���V��w��(F��F1H ̓�{,2�C�3�V��.n��%�)����z�Ի�B5w;�Ֆ�Q>P��������@S�b���rv8�	����Ts{������ �C�/o���V	��}trKh �*I��p����δb�d
M+,Lݐ
���1�Y����@�pոI�G�r����7j����Z��^�$	��e�f?�n+���\>\�H*OV�QZ�q��(U�o�}� �����$[�Q�?̛z<�7�pl͙D��ʶ��Zt����ɘ��@�a��QL�||c��n��K_*��&k����U�@ٻ�ݖZ�2\����|
�>W=Y���2�LV��XwſB��J@s��\��t�����e��2 +d&��z�-�?�ͪ�:�ꕍ1Gb���eף�?�����^�I��a7�67'��g�8"��d��������P�^���h����&N�$�*Ǘkt
J� �Y�'b�b��=u$��X'��5��-�6�Slr����N{���FNe��mC��}�~�,�KD(#wUk?��n�G^�Q�eFj���2��2�kX��?&�
-��[~��o�P�N�2�|����_��� H�K~�(v aΚ���ݠ��e �0��Y�
Sv
�xA/��y���_7�C���x��vX��=6
oVE"�X��):R �2�
��R㺢.QG�/J�+:����è
~�Ki��(���ms�L  s"��j ����sAu���g�    YZ