#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3359045978"
MD5="a74b8ed1f7cbc686122968fc8001448c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23976"
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
	echo Date of packaging: Thu Dec 23 19:29:25 -03 2021
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
�7zXZ  �ִF !   �X����]g] �}��1Dd]����P�t�D�#����c��K�_Зؙހ�������h�V2{<�M0fY���Xȹ]�̙2�2,������z#�s<������y�>,;����<UJ��{�l,w���#e��xBJ���_G��_پ�|���y��Kx����푺�d(?�[��iV�)���9��*�]�!��i0)쏅1@~������Y�J1�^�/�?D�=�,ҚiN*�a�]D��FR�7�cb���f�i.�~S?�rq��*E?��!�:��$�����*���ڞٸ�%,6�-+������hS~
;�0�K&.��kPv�mI�~��d?˧y�v����(�X��f
E�G��T�f��џL�ƭ��T���8(��vs7�9iz_�{�U�.#ZK9�(��|����ĳ��Iؒ�������!���
�$�L	�1>%+�x�RԹ�]�{���	�A_sZxQ �����鈄	b�>�L�{x
ۺ�3��6�Zc�$?C��-�0⿵�^�Q�52��[�s1���3ɰ"��xM�-��������)��6@!�Ljc�1�c
Q�W�s*��W#\Y�wwt/!-5Ad�2~&��^@���E�{zU��ǅ���K������#�2�$ܚOc*Y[�n`�40e*�v��C�Ia;�fuQ4�@F�:`gs6.{ZH򒔗q=�P�Â�!��{�������?_���mU�Q�Q&����ΏՓx:���:�d	X
���ٯ=D�!��h�[�t���ĤQ�͟)�C��N��K��1��P�4�AM�P�_,��X�\���VXB3MB��X{�>�F�Ǝ�#��r���M���_������y;|��հ<��Ӣ���IB��Y�5�L��Y�_�<9�x]���g�'=Y���Qu���ā
����
��/�L�YꋖtX4r�
���|���Ư��s�t�K��:zd�/a��{r��3�Z����U���K����FeDZQ����gb�k!^��p������An%Z{NQ�Ҧ�����8"p�n�y��7�T��B�e�(�{�%��a������A��Z���s�c���M�*R�Ò�����,�e�8��i&�88�),�x
�g�[�#���"�I�9�I�I*�A�O�(\���7!�K�٦�8���.ƿx�����"E
�0���Tr����6��9�lDOjA�3�1)��.��}�ڊ���G�1�b޴����Â�'��q�	ի�p��	��W������z�]��5od�6mFh�i�ߗL�l|�̠��@�`b37�0�؟;T�-)Y����%{�M0��3f���ktg����p,[�-HKL� �%ЄEX��Av��s8�$�#�~������c���͕�3T�t&�j��ixX:ʲa���	��޶e_"��Cu2 7��a��vEj�t����>� �45���M����\g���ѿ	���� z;�$U[7�37����>�%v'R�4�����"���e^�k-p�7-�Sѕ��s�+���a�yk<�5��e�1�m��?ʹ�M��\�^2V2G��4Q;��~F���G
қ���a�����1��\91H$�"�#�G0�kH`���WO����5��D��q�A^�R�Et22�.3��oE�<o�'���ƌȾ��r~��w�Y��u�I�79_)��ڗ��F���#ݟ��D�"�Ɋ|#�a>�l�q�B�k;���lh�@r���j�u�gQ���F�>x��!u�����h��i�����u`�e��f��9ùZ_��U���7P�5���̦�;%�T�ąRæ�(��\�`�q�y�bs�>u�fe��4&o,�`��7�t��Y�P�V�3��f�M��W�����g�S���SRs0^x��ں�^Rm��J���D���`��\��#?E]$Q�oP�ȞK�2���[lTk�����Ƙ��ӛQo!R�}�㎣��7�:C���0���H:_S��&�t��.$�3C��שsR�*0���(s��}��d�?��윅+�CG�����ޅ�M��H�c��ŉc x�ُ̭��"S�En��*S~��An<�1(,Sʇ��P|z�)��ՍÄ<pԒ4��ˈ��(����g� �����FD��=%�	�����D�E0��2L��`�.��r#=N��y"/���'b�{^���-ߕ�[�)L������<[��4]^��l�^��P�ڋI���bA 0�WR���*|���7�CBD+�&H�PϦfb�_V���'�H���;��4ŕ�<��$� %_:L
<ܩ��R�A����#�%������˳*�p}DOK/�^�l�Ł�)rŗ�U����NL�`;�^�F�<"� �2@9��;��l�pS�p<����&4K��1 ��7�R �򴵘���31~�B���"
s��S�]K_��2:��ǆ�A��B�O��]�Zd���%L��Fǽ7Tn5��h�:����/���|�`�nj������{���80Q����\�G;�˧ȇ\J��w �Y)@�9��,'mgᚄ��/MG�;���vF�n�
$/�e'{'�)l�xJ�6Ct��5��uRV.�~�,�@n�ԏ��_�v��Q�8P�}#�~5{�%r���E� �){�Yk�V��������c-�?)Pd�� i�2"���2`��o���0�vBk���G�Qܺ� ����#<R/ELn㣥Y�¯R	_��L��k$\0���5��R ����sb���C�x۷Ș����-..���3�?������G�U�~��¶����	 ��R���%2���l�3�7�u����ܭ���"lU1:
�$�ʝT1�6�_#�݇�@s������楧��I_�@��b�Ng��EV�e�7��^ɼ�_׻�T2A0T8��i��H7q���:r�3��1n�*�R�J��������?e|���=�[õh�~���y��}0&)�z������y|Ѡ��,��C�~?>vf�[vS]5��ٍ�[B:���JEzx�� �?\��c���=�y�Y
�@�8t��"�#P�u��ߗ9;4�`���B�N��!9���Lh�:��P�@��Z�Tu����d)Pbk��5h�)=��x�l	�Yb�_�icfA^��UfM3˖7���B�;�v��N�t�ѱ	H5�E��;%^�x�6ŧr��O�c��Z�m�zH,av�ב¢��O�����B3�O�q�)\$��n����������c:��I	<�UYIe��!�t���(�w$D/5��:�}"AJ��|�6`�.��`]c�[w���D�;s�@-������=�_�8�N��~��@ꎰ�"z�B���z̃��h�^��QG`P�i��ĵ`�a���:ꇥ(w|,�<e��ϸ㖐fWŉ��$l%nY0D&$S�J����.� ۆ�S�rwa\�q��L��@�#��9�$�$�C�38�k�L��R�OCt��t���>��-�Ħ�s���(�P�:^6k��M��|@߮6��5��:[�o�SW�����O����2��
�J~%�*�LsX߭��k϶ ���ڦ�n��[7V��IٔH~�>	���G�M#7��;7�̌���P�0&��l#3=�`7�����^.x�&���:�4FJg�D��Œ�`�<[ק(��J;�`	�5���q�ڨ�f���7�D�A���8Ҩ4B����'%H��	p0��#�4���r��~m,�V�?��Gb����x-b��	���r�j%�v�K�X[!����0s}��m�-��Qw����v{D@�贠��J�Z����ܓ6[�u��?�mA��}Mn��C�����<��ti�~�Wj�D����?aB|:7�ߡenH_�@���.C ı0���:p������n�w���j/5�D�eU:��4��LᾎM�P��
�>J�l�tB�Ar�O�`�H!����y���l��0�rMV [)AI�a�`����\�r�Yzd,C{��hƄi��?�V���w_d����i?�z���s�ڠ�F��[���z��B8�x��O- �^�M��]i��L�U�=�I3�B����Bs��
90�C�HC��2C���`�������p�v�aW�!p��3I�z���RL��9�B��r�_��^�.*��0��˝��^k�wX�}B0h�/h�xA��[���`��'��]lSX�@<��Mw ����i/վ��})!�ZR�;����� �i��r1�ۖ����A4L�D��^^8�$��i�kRXc����4�,�5�Ϩ�l/�=X��b�h{
b�Mދҗ�7�mH�ݐ��rpX���������O��x�l�Q�['��(	�4�%#' ]m#T�e��K~�"��_�շ�����0��TL���;�~B�pH��	����;�]7�$��g���Ät%)���s���#J�G�_R� $'N�־��C����@J�ZuX��9����M�?ই�e�H_>�������~[ւ ��'���>�Q&V�g"!COr��֖o@vN'��Oum����NԷ��~�'���OE� Q������`g�_�����9�D,�=Ξ���@�=����@u\ ���t(mK4��:UZ0u��I�����6���Ot~G��;���\�o'�X��!GI;8�f�Ed��<����)�o;��m�,w8�R�P)�EelDe'��r�[�c��^JG$�2t��.����rG־rB�Uz����\�m�S�V��y{�;�Ȉ�/�z&�Ub���LKy�!����ןr�=(��F��r������d�񫝻��p�M���x����\_���8�D�{�U�u!�������yjA�yl��L=V�b��'�� �����5�5k��Cakh<��E�FV��T"�h<��:���^�8�W�M�Fl�Q��t��~`XjC;�rVu<�~S�I��]���u���Z�h�gܓ�4R+�c��H�0�
���*r�%a7�KQ����9`�*���Do��3S��QS7�h��
7v~�D�%���X�5ܔ�f^nV�k��4���B��v�~�^1ݧ��&W���YO�)��	��55���w��]5lzH��0�(��Q��z�5��4���FRWM[g�y݂
�Jٍe^��Q�����m|�#e�O:��W[Q���=ҟ�����:zcA咁�#���S�P�G���:����t�.���g@����H���n2�s�p ��J�3I��� [�ց�����-}������`�fƤ�-g,�"+-9�~fvM7�0�K kۢ��pS�[S�Zf�xѲx�����c���~��O:S;ϥЍ���gU�Ar�w+Ȱ�NOS�dp�ļ��ݟx7����i�\o ~��M?�i.<DLe⋋���_�ݛ������6�����{���O��
����
�)���P��+�>�%:$����+�uǫ�%M!��8C�/���6D ^y�^u��%Fq�
�%�O���vtFi@�.�0���Պs�u{�:�W�$�'��AqH�b?��4�5A������:�5`ɴٺx�2S&��Ō
;lm-~Tj]Vs)��92)Zj\v��߉�N'Պ
{f�ީ�=�ˈ F_S~�����:~`1d`�T<����N�N֢��⋡m�*H�����o��|BUv��je���#x��Ă㯢V�@�l����ڏ���#j9���zsH2�Z4a���`���<">�|��,��s�A�Ϻ���ա�M�.I������Eh��a��������1�ۿ'9������ �Ȭ��?K�(�2(tN:�\�9PV94w��B1b���Q"��j�zi�����e[�!���U_.��9nW�'x�#��_����]�C�ДŃ%���l�QR�TF(���E���,�뀣��"��Q1��_	�����z��d~ͥ#�.}M��=�̇�#���X�{r��~����.�W�V!����&M��oa|��,�0C�o+�ok�eT,@�&��L�L��A.�O�15 j��N�����6-SY��mq<�E�GA-9 �lwr)����d�JLU|�'�6��a�FN3���f��5�!��A*��x���:�"hb ��j��z@�e
K՜��P8)��c0�
Ħ|ǱD�A���7$aJ�e�y�/5��DF��}�{��<��vÜx�v�r�$�	_ZuzF$�GK���trH$��7�D]�;2�]�UR��A��kP�r�ؔ�L�����#�oY]�+
S� �UOo}'V��0�z�E�{S��i=YEn�+�!��/������آ������X�A��z�'M~ר��.�xy�iکJ�裒$��'���$�7��2f1����Rf�=F�K�=u�?Y���[�X��;��W=Km�͙C��+�({�Оn
�B��sw��Cɞm��A��㓎2�z+��>�KW��}i�[J_{G��P?���Bc<Y�����%D����YAi��.�	�l|/tuС2�үR��nd��0���-�J=�����������3b狝���|���zlG���s/�a�x�0��e���*I��+҃=�����R˩
?����'��Yf�~�g\�/��4b��S*M󶮩8�����A��O�W�ݯ�˳Z�Z���R��&t����۩2�@U��d�G0�:yv�E�ty@��wd����(��6p�.]��d���r8Ҩ���;��<�i�$2#Zݿgj^��U������N��0���)��D���4-��LASE����gwÓ�w�'�뙴7n�m��V@������E��>P�qe
�i)-��}a]Q��B&I��-������DNBl�|���t/��%h�b�d���ATz,f�!ܨ/(�KWO��x������o�dE�2gƌ�|���l����l*�����Vdh8������*�4�`�6��z<�;��*2eElw>J[�Sk�|�9I0ӟ�\K�n�#TO�9IG]-O���Z����2��h��W����T��&�F!wm6��y䙎u�)��.�"(v��V��k2�����+s��2hH�9���'ẃw�̫���'��j�SU0���M�,���tB�ga������xp~�E<����{5`!�C�c�ì����0����9Qٲ;I/�糉*n��@��^%~k�R�Ԭ^y�$ڂ!o���rj!Nݺ� |����d��^�|�|�e�W�z�=u��ߞ�)f�p|/5���N��NV�q`P�����N��s���pK��N�m�g��n�k�Ỷ���Z�&4`Z]_�ߑł�T��N�h30���RT�ո�~e��"������9�v
���!ó_r��Z;��X��,C��:�T�6�,��eJa(d���V3��f��M�}~�u��'l�W��0���U�Tg���*;�B��~�{	sڙ�|�T;���� �e���F�v�$��晋Y�ػ�&ӗ'k���v�,{l���%����	O������J���A��l$��N��y��":���ց�T���Փ���@���"����0t�5&}T7���+���������s�|�6'��oKߞi��{�?lGK"k��ZP8����A*��8�r��g+��oժ�$�S�ȗt��*0a�j�� ���ET��oV[}��@��R^�74�O��ݮ���"=�тɥ�Y����s��#H�*�`iݍ��y���N?��Ivr%�e&Y[�����ay 7�˲�������W2�p�����Qm����P=(�Z�b@Bws_�Gf`�gc(�N��z�Ho&������K�E��̘�Ζh�|K�^=���͠2S�në^�'VWf1~��wlZm���D�Q�k9����	 [b��qL� �I>z�K�+��q�!�V��H陲ؿ�c�}>���O3��U."�<h �1�T�<��.�M��F���[�o�b��:�P���%�zq�Gr���3�J�N���y�:ـz�(�1���/;y�14:��8Z�>\
�F��c��Z�k�	~ͭ+�C,j�s����e��ָ�1?���1/�d�� B�������I� p_���v�����Ø��Nʀm0�S�$ԩ���V���ѝ�2ӀT��lLS�)(���쭄ܖ�O�3n��rb_|l��X(�G�e�� ��z�>�֚���ㅼ@��˫+6���0��*�UX'GC� ~�Ls�J$�����zĶ���A�fX�vU���W��o6*:�zYox9����>�3ҕ@�@�(Y�~1�S�Y�ޢM����)�WC�#�X��{�պR_�Yiy�C�o
�L7'Є�r��2T�zxl�B�j�ϽLi1d-UZ5.Ա��MV�����xją"�-��|��)U �3l�"Y���;��cF���&�e��b�-tL+ü ��]y��)�
��~Kv�|}-:A$.e7�3Y��������K�n�e�����@���R½�12��ƒ�l�yY�^��^6m]��AB�G�U�?A��53�y��fN#�_՚�0oA��X��Ӆ���c{��Ł��ȼ"���Z-��¡�Hv�/)���0���@ ��I�_D�S�p�[k��|�g��@�GˣnYk,n(�o\+��1[f�D��N��z���z��4��x-��cFX]a�>e�a��>�U��t�9$y~��'�Uy� ��y��8Hz%��1|��p/���4�u�yyD���D�O��xw�P+�?����'J�X;M+�5���/3�Y5s�\	cM�E_�� �9�Xw4�s�?� � �޿�l'�F3�3��o�*{+aw�	(Q���M��1���	�ަV&�gi�*��b'�U�eE*����n��Ho�_�e��M���6�Wd4��:U�A���9q2d<5V{�^*�_����hm���3���UA8;W�~)k۬���0=^��2�m�]�L�é6��u��/���r��s]��6�̹́������3��E�?K���^�aۼ9�\8Ǎ��~��aQ���Fy���+$���+P�������Ѯ��y�SGe+�K���Y"�tmK�s{�y�_p7&�@@8o�Y�xA'�DuCQ�T�V���|��V���2���n���OzGٲ;<}���T4�����'X�Hxu��s���������GW.���5(�ewn��§�9�8��c����MkD5!e\g)g��Z�d3�����)`���D�\�tF�6�~D�m'4#<���O�-w��AU��¹�cl�7���mF�v�g��vyP���ْ	�91����}���gT�o��F�m�h��x�6R�+I�\�Y���Ib;m�ˇ�3I`(`i<N=�<��]��<��m9�'���s�Q��~:��w�ͻ�s����N�@�֫�r�'H,2KY����a˄��dBs�?����ֽ�חa�f6T8�Ч��p�:!ɉ������9�2U8t���WM��AJ����ӪgLX}�v�Gv�2����I���ѝ@��G���bJ�74�G��T�V��,��B��/Z.�>�ɑ����p�����Z��-&I�(N��ۻ�[�N�m��o�]+�dy����#�3���Rz�W�'� 6G�HD"���ޞ��zB�Yl� Z2ͬ7�v�<p�bɯi��ƾ�+	I�8��p�k���i���~�;����@�D�jI.���R����=�B�IX_���G~$)�1��JM(d��]�>- �ڻ�}��yV~�%uF��ĭ.3oTwS��ė�m|��%���~A��b�LHhK�ݡl����bI�Qf��+4���R��Dʹ��a3�Hm(.�B4�����������r��9]bJf)��ƫ�
�h)Ea�߳���+��C!�#����� �Ī$�S���@��B!a-N���p\�m�^�"��#��F����<?Ëa �k������ys!���Y���m����μ���ygѤ����.#���-�q{�K�+�>˒����l�odB��`��a���ɇ¼j�3���+7�B�h�5��WK��w�/�4�RzD�8�$���z,̲��m
��&������y�CY�Ev�� ^v��4D���kn�n�K�P����̧+F��i�n�U_�%�Q�U����Ub`m��$�bS3,���cE�O��}��g�(�vP<F@�|��v����]#�UF�z�`�GD��4���-�	M�(I���&��LD5E>[�|�!�$��"-��AI �{:�f�*�?������KO�x��<Xa%�r�	
 ���hP7O��)��-�Var��tb�4���"=��L������w���"yn�m���F��G~��x�P��'sy����GE>֓�w���\��t�Ɨ���1Dw�O;��y��N!�,�#9ѯ��5Jj�I4��%x��Dg$��٭^�ݹ��fc���0W�(^���+���s),���BZ;tWz�0���_�̣:w��yz��Ɲ�J��F�y�OP}�Z׆j�B1Wz��K�=6�̚D��[&tH,�=;���U�@rD��U_tw��0�>�؅�E����}ꄗ���VO-!?8b�/l_
	�jL��`�9����u�-W�tq�0
PN�X���!\�?6�v�i#� y���5W�C������Jm���G�ݦV�0��帵�V�W��a�WC_�ѵ�)J�);��|�8�ˎ�Q]�� ��2Ijb�r�I��]��~�C�`<2��C�ı�@El��y:I�x�ˬ�+  ��{M CCj4:w~�sq�`�������v�i�z�A�nKcp�jU���	��>�f�L��BdT��3�IEzK�Kw��
���|a
� ����t5sq��)Z������E'���?E6!u��m"B��Y�-�h�dV?b�z�R�4��"�d�Yxδ�	����r�oP�;��n����|���-��bP�:U�^-����E:S�Y�h*��Cb�.����'�T�������wj�X�O��PHZA�:���Uds�:M��sz#0>6�Z�L�'�	�0���_��h��H�t���Hϊ�ӠB\�&�Px�P�͏���vǋ��Ʀ������r�ɖQ����̓�t�&�L)�7���K��d���v/�2_Tё{�����"eU�*%ȩU�l��M3�C��?oIF�~8�M���8bE� `�ު.[[Ҫ�)��6�-3_�6�;�yfU�VuN�6���F�q&���Tb�k(Mt]�@o�P��I;���SZ�;��2�e˵4��r1��ͨB���ٶ ˵�m���D&w��s�X�M��S2����r�;>`�}B�:ұ�r�W6��䔂	�_Us��G�̆/=on��>���y۽���ތM�M�,�^8	sf�e��h�{X���v��ݬ������۪��h���}�'X5��;�窬�{q���l�I�6Br�#��qkz��V�DH'B��|�,m'mu��#r���|�O酅,�&�8���L�Bc��+t��(����:�r"�8�Ϟ�2ˍ��Fްw����w��>��-��t����:q���Us]�U��[���b��~�f����H�I|�f������8PAF��2��g��}��5琧�պ�"������(f��.�%��t@��Q_��A�VF<���9�LU6��unJ&_�)��)45?B%�ע�V�g�h��:�D�E@,
�f����ۇ,�?�z�%�H?������P&�! �X��/]">�w<���� ꓐn��s�DZ�Z��,��cr�~�B�^�7N*=�lrDe����KaQs��=��T�%�p|i�hP`���`�H���+3nv�H���Ts|X�����2Y��)@_5r���hJ^d.���ꭱ2�wH0��k]��'KP�oJ���o�a<ǁy�1ܑ���E����pM�"4��[q?��@<"����l����M�f��SiV�\8t�p��9�p���������?����R����;�R�&bq���b�XJϨ�=�9T��Ij�K��Z�� ������� �T3���2��ӓN��s�ˋv��Q\�v�,z̲pI��1܎�#S�5�K�zk�+��B
�C}M~D���x"V�aY�9���P`�Ԗ&��>��0=��g��@�MW�Ù��u����!l'�����]�l%PM���ؐ53W["��E�-�o��C������g�<З�>��������g� �p(�:�h-�\���lF&a�F�����{Ql�Ū�'V���7�LfY9���M/�H����}�����Ů�8���,d�	z`?Xv��8E�U���ށtA�+�k�����<�C2�H�!�w�r�m�k��MZo��,�R�KS��z<���7@R���Z�݃��~��N�x8������u=6Άh4L0���Ӕ�^������  ��h�e� iT-��G�g~)S��X��	p�����nb"$�-�]x)���kx%!��p�����}��p��2�
�]�+j&�{bg�ݏ��jw�(��U�4��m,b�,������so�E����>�~+�%�{��x��;�/qqXg&�������5�_������!����t����y�wD���I����.P��?�7s@2ũ+�k6�������^�J�3��`�,�
�]8����%�Y�"�wW�@��W����)��ތ��P�� X�|En��(��L?:���UU��D��^�Ī{�)ElJz^���J0��X�t��k20��P)��VC؋Y�*Ț̓B�ԛo���03��:���);1�z�W���Z��aZ�����}��_�q�h����(?�Li3��L�)^���%�\��0m��;�a+q�����C;�?��K2�G�-�oXe�N�`C�@��C#nV"�l�;0�7�9(����i����O�M��l�7X� �+k�G^�����E/L�q���\��I���D�~Т�r꩓�1���73z%�\�i&�X���G{�����@U��1R5�^���'�x���nII�?�XF� �̚��(����SE:�I���@�9��l\���QԿ8.���b����WԚ����E*��U��¥�A����4�:�Q�t�]c�Ry��C�h�����!���d�!�qY����)���j�I�l[��}u�st���QY��<�Ǵ#��7&�ڦ��t2������%-Ct����=p���������.�'�ej�-��������n�2��l�����ݺ*� I�&963�>Q�2�8���خMu<�CM��Yۏ��бE�H��c�!�D��Dd��Qs�O�D|�����/��d�Vn��Q;����h����K2k��	q�_Xb�`�m�Q�l<Wµ\�^����[�h��F��s�N1Y��������I/�I�'�+��!�RR�ܡ��6�)��M�/�~-r�����
�H��#�b\i����˫Gm}rߐXu�[c?�4'�|?�J6����C�K�b�������if2b�N)Emñ��e}��4l��7(b���`��l>2���[��fn;^lΘ���W8rS�l�Y���|����$t= Jxcc'j��t*a�����}�(���d��k.��D}��O�?_�eu�]����9���`��fSE�������K�Uew"�W�y{���n#�4G5��	_5�Y	��1�k�E�A�`h����e;'�38?Z��OhLWDa��K&��B!]�Ě�ڣ�vO`���W�Sl�3G]J{ӺGp 3��L@��_�\��5y06���q��t����^F�Q���6ϊ�j�ʡϮ��z ]kcp����M�+f�E�*�M�(�M����(�)e:��|�}��2.f�稜1'���_r�,�Hg����*R`P��=i�c0�������h������t
���4���(���ȕ���p٨3qm��s2�OU��,k9a����t���a,t+10�l��[����n��ck�O�Μ|����$��y�¼p1_2�Y!����k�Jq��ɏK�1��H˺�RvB�V��C��X�CٽP�����|�!�(�x3~�f02x��ͤ����~6��d1)o���^Z�:�:�.@B�N��%�N#�nf�ߺ����<b�t��j��vzŴ��4Rݴ�H���`}MZQg��+�5L��8 g�d\�U�_���f��>��#�Òь���Lu�x%�SL�D�[mSI�Y�P�ql��+�6}��pnlk߆�`�'�0>����E�ֻ�HY�(�����#�»+�}l��p��B��'�iv?�+���͍�83s1�bT�e�NL{)0�<���=�5�kٸ)�
e�qy���RCexy�5 �g��)Kym@z��R���1i�xG��](�T�Y-'� �b��G�T�T��veW��b�M}�7�t��BZ6�� 	�����1^J�ۣNz�I����V[0�!]�}�.t[�P�ʯ~y8�D���gKa�ڈ��,��%�	�,B%@���<��d|�������mj(���v ڸꉭ�{`����!ךq�p6��°�kN�l���0��CS2A	a�.�#�6�����4��؞��כę�7c1l�4�&�U]�ۂzm��չ����U��(�ʞ|��9� ����ɏ���y��syb� ۣ6I�zQk�K2�5���waR1��^�⚌bڽS;�ب��;w1f��׳ߵt��@��IZ� �NC;�Kwq����fq|�P{��pF�o��c�k��{�hI�=��"Ş��g�Ƞ�]�o,��3^�8k�A���C��4��l.���tFgJ]B�~����FU���KA�!ٴ �W�^O�����ۀ��BTXƎ�-����2��s�X�-��f��"S���s��O��prQ�op�ֻf9U����$,5u��9���b�䰋��EP���YU�j�{{��WJu4E��t��?S
i*>�J1�j.���&�rb�R�Fh�g?)�˹��$%���
�^8�V�kl%0��-��p��ҁA���ktuK1��s .\�^��G��R@�;�31��	�)^d�������Q���L����T�P�;�)��?�+���rÁ�	�G�4C��y~��a?PlU��z��~��+�L[�����I �J*af��V�4���`��H�j��7��bF�p�ے���,C��(kp�H/?����rd�X7=D���R۶E�;�8\���B��}�A�����G����0wK+�e��J�4F����0���>�^u9���'S�4w�U���B�\��'gg9L�Jj!9����̡gל/�������d���[V-Y�UI�G�����|-3e5`N�n �<�����@c��m͔�y�p3�:�`НgG�Ɉy���u��O>J)�Vn7w�����&�G��?+ �DuEfy�.]9GPk݃N�N]P���?,B�۬�a{�v�\i9_�iV�VY'���/��?(CAL�:^}$<�P�_�r0"����gq2������o
�J*X��C9�ɘ�K��P����]�
���D�:�a$.��:Wm�Ks#��^���!E,����X^����}��%��D��s�F�����MY�E/Llk�^�T�p.Ib%�E�ƪ���ו�4��(vl�)U�����������h�TT�d���ե����_��,��9��4ڕ/���"�����DF*!�K�.��LL!;3�+QQJq�}��謵���$���ӲD[-w�\�U*�Wݎ�W�Cs�$�|ꡰ.��ڨ/4<4���m��6}2nC�$�p�~	�7sZ#�r��^�W!� �z�a�$��18 N���?jzܯGs�3�S��ޏx��ڠ4aT�m�M��ʪD����40+O{����6'S�Z����N�E��Zg�?��f�������|^-��*&���H]�ݠ��]"FS��DQ1�-��2��Ua��)yٱU�>��a3vŐ̓�U���ͯ��v�3y5�2���Y|q�<�s�F1�/�䓗Je���p��AF�ޘ��o�O�;��Fe]��pM�j�U����B�X@�5��t[����YE�b����C��M���ߤ�;2��Ĵs`�x�@���H�t��Ge�p��UwP����rۤk�,���1�?E#K�E���w�r���t'\|�Qh�<�I�������Z胧��Z<o2Լ�f�pQ�԰���d1��e�ŚD ?�i�⮬��\{�: >&��&:�{�^*���L����	�(����{'ܪ��g��y��Q���O��
,��	xv1�9=�<���G	�S��}��:�Z8ؑu��Q& ���A�&�ڥW�ܯZ�t��5ӭ{A�%L����F��%{O��3�I�p ���{�_�o�řcrb})UYS���VO���Y�ʆ���wbC���x#�/�U��ѵ'0=���G�xC�zِ�3��8N)�l���]�C�2"��f��J�G��+hug
��,__k�F�������3����)��C�nΠ�t���Lo���l�M9X����5�����ڲa#}�Ac����Q���h4�꺀ќ�O�童��i�*Ӷm��ȸ�������\��N���Θ��:Ϯ8�/��/h���&!���s��Դ�.Y�#}	�ZyT���8�J�?�4��5d��sఓ��6K�W,�v"�	oEHjs�G؈����J\P�Ǘ��A���n�u@ؗ�]�OAE�E����QP���e8n
�L�rc�̦�Pҽ�<�5&4M�6�^�|yJ��2�w��vB�K����A+������,�%���co2[&�;��(ؼקS_�u��Q� "[!b��������LR˹�Ou�n��@f;������.���	uH[Ն� `��%ܾ�A���ƺ�
��O��mK���	�޲���;{g�]����jӦj�e=�L���+M�)�l�@B�^3��6�G)q�~��p��Lk����p��z� �(}D���e��X���|[vl�h&[c��S�h�9�1\I6�����0B�Cg�Q��0h*<��I"g�z
�S���Vm �4nl���ή:��sn�#�
��
w��Df�H�R���&'��#}inx��8Qnt���XϼCUxD���>
)��j���c}g��6��Pw�[�Tb$j�oe�Q�ް�{Z��_#��]���{q,�PètSb��a8k���ѷ��1{�+��=f��.�q�*�%����gh��H��r\/3���6���$�?:JM~{�Nn'
�5��M��������z�7Ap��q�&��3�Me��D~PL��ɥ�O���@�/� �Ak����ŷ�MO��#q.��k�\@v��fb,��5X����g��{NToJ�~�A�����r 'n����:��+���6�K1��7�w�h�N�M?�Axm�{R�������No���]��*ޭ�D����7�O*�FzOuz�I�K麖ơ��jI���*�����p�px�t�E%���i��I�̮ݛ7ʌ"�S<.�2$^��?�fҢh������5#hk7�r�S��AҎ�9�S��V�V�P��.*0%@}c�%%�ߧ��o��Z$<Y��7q�nO��8@���I{�G�`�_T���2J�d;�L�Q��j��"B��''H�e�*�Y��D�qB��x�����pM�68'���D��=>[G:�߾^�V�P�5��O��:n!��-=�@'�}a�u:�q�m$�2y �p6.X?a��V$�0BQ/%,L�Tʰ�c�S�@�����
]��f u����1��&�P��l�CK�Vb�f�,��,K�Y�n�o�wd���ϩ���U�p�+4#�Ҁ�ÿ����t�ؖ�ڠ�R�ƶ`�	���O8q�	�d����C ������k�i���W�`���}���v��.o�vkEE2֫7
.E,������=J�X�$��w�v��������H�޺o��$PVO}|7�+�����Չ7gL0V:2��dsr�A-0Nl9N����l�{uU�|�y���
1eq	�;��I����Zj�oŃ�4-�����T G��&.v@{�p0�u���~��.�n�})���qg�mL�	0�u�9��;F�����7�CxTb�#��Y�@bpN �}!�0m�]�#/���O�ˊ��3_?P�SaD�7�W��d�����c���O�!�F�;�E���ԉ][�̠e�n�̲���&n4����ÏF��������ьc�Q�J�4��عW�T���?q�mTU�U%+���0��z��� �C���$�,�+B�����5.[�aT4CI��ڍ��/��y)�e�@��'��Z[����l$��1LeM��3���Jү����׵$��d���d� ��+趖]�nS�m�Ck�8
ח�e�mP��#q4�h+Zc[-� f��ú;��V���#I���"hМ�_����`ƀk��~��ϩ�~.7Z�	��2A��������0���՝��!Ǵ������Z`8�-���b�u9�Ь�s;A~&�����UKTi���W:1�t6�}i��l߄_4��i5�)˻��� R~��#�_m�W����#�{�ʉ�n'3�����j(���
w��a6,���5w:V����7�%I���b�$���!�'��,{����fAf�����a�8�\>trz����tZ]����]�ʢfQ���l4 ��:�
��ΫW�q��;;�����A5�j�����8k���?!F��~X�G���H�3`�S�]����)x�@�:�Q5��"���ЫÅ!�X#��y����Q7N��w�ੜ�T���^���D%r��P�]P����>˪��u't"����o����������V�UZO��*>8�g*�Ap�f���	Z.�g���UbpR0�P�J�s��_'���4pO ]�R��Zn��Z���ִ�����e�bG(�Pt���
�@�]Q��z}C/N8U�����,I-y4iy3O�>Z.��,ա�/���c�~�>�5��=��z��+�nOB�|Uf΋�%���%��$��)7�N�/Ԁ��D��5$6e���B��$b���зs��(x�q!.q7�-ka�k�1�Yb���8���w�¯Ջ�gad|}�g��\b*$��bl����j�tCe��jN�~-^֤��Շ��i�؀��[j\����|G��C 8-~SO��yC�6�_W�Jk{���1��@n+F�`i2�cWn��)��s�x��%��������x֜fν�j��Ê~·�y.]��Q��x�,�v�|�ן'�g�SI"=��Ӄ^W�.	}��JK���k@�k����!�$���3�;\���<q\�2���8���O�k'M�5�^3��#�1������C^��Keg�e�El.�ƹ�E��E�\[�F� �1Sw�'C�[�&#1�Ġ�j?2 :�m��LJ 1���R�J�� ����y�>�Ƅ�6CCӭ���p�`aMǳ,xZE�s��̛k��-&�n��oh`��T_�~?�s���H�Ǥ�?�On�+u�Q���P/iX�,���)�0|�����p�yb^;��Zקֻ6Q[��^�$��L�S~�����*��^ϴ�o��֒;�, ńP�5����CG�+?�!��^dYԤ��zn�Z4S ��P��B/�߂��L��
�vy�c�,�`�a�搻�E�SpX���T�
Q8w�c��stU&PY(:@K!�I��ґ�p�w���Hh4��Ǜ���7����^�i��ư+)~$������[���Ë��1#��9Y�V��E��Mcu�xU&���?ؽ���.]�K�i�x�E;ШGy������%_>Z���セwWMC󻇄���lE/�lY{w�7���-�,,(��'>?}��LM�� �,x]����%չ�P���(����]�F�B#������:ٖ)��*9��˶(�ddŢ����sHA��?o/�	��3�Zap�E�prt-&�(�����K���y�\փ�"�˯��x��
�m!zG\\$� ��UAȹm��މu,��@�BU�/�fҋC���aH�*|�ӣ�A+ ��4	l��[��^x���?��D�����i��`�p��v�S�� 3F����²X*�<v�,� ?���W���Ym���-g��SZo눯t[u�����4�*�D�|���,��B!݂4
������M���Zj��p�@駄|�%�'�ۺ���*r29�Р� ��IP��g6/ǀy<����I��h�0ڛe&�l��fT(��#����E��%~�۟�~��E�� Q��˓'h���o�K7B�#]�J�Bd�6M��Sn	罪$��X2��2s�X:պ���}6���zt�@��V�~%��ށ7���e��c����w����B��(Up\�bl9�����@R�*��w��s?��V�?���C�]L�K;�6˸6��l$-[$�j��&�M�iN�����.���H��(YW�l������)q��%��Eg�^��'����	�ޣ�?�=�M�c4]m��H��}e�2_u��X��ֲr��l{E�ƍ<�ż��G�W|?����&(�X~�*�c�����n�}�gjVVd��gcvRP$�h?�Q��y�fn��û#o�[>���G��\�1��2?�� 5�.@g��G�ՁٌZ�	����������ŗ���\���NYp7g:������	�dpu�p���?U*?����S�-Q �p��j�.�=h}�(@�Ր�x�d?�ǐH�]��n�^wE�
����4j=�>*{ʲ�N���:-����T��=3Q��qM�oM����Ш?��ƅe(��6�Ŗ:��r�Hj�������ȿ�N�*�k'�C�����Ξ+������ �����}��v��D�ȚI�7�K�-+1oQNg�婸{��/ :p��=��kh%���O�Tt�Eл��ׅtK�D�0Nw��?{#X�S����5Ԁ��7�}��Ӝ�"��	�u��G_=5�w.�`�)]���y���[{��<�D�G����bb�/�������{:J�3��uI����m�R��%�i�#ٟ��������hH,��GЅ��n�t}c�&&]����NR���8�Y`��WEѶ��&N5�)"�
~sP�g�v2B�n����8��<z�uF�p4��0��5_�Z�:��pǹ~(9-�.?X�V�T��t^�`U�&�j_
��\�:�f��"$5~	��9���zo	t�����b�W��^�@=�$N��߫��S�8�a��qa܌,aA�B���:'���x�Q�=���/��eQ����I٠�
�
U�.�:f� ��~��wݫ��"�a��D־$��2mF��RC�-���B�N��+�����q�d��1e1��nm�cb��~�^[L,�9|��ood�}4��8L����Q���Л�9�P�O�iu3V��׀e�%�~2{��(ے8Vfa���Bi�0�����1�|���3X�w���Ni���ĖoΩ@�	�o6�v�[̧�$R�T�_,�C�]��Phǲ"V�r2��Ђ�u���$�|��1>�}Q\r3/�o���r�E���0I��;�`==Q��M�A]�Ϗ>Y�}�����z]�^�~o��l3��:�)ev:���V�������%���q�N��-2xmB:d�z��L8=!(����� tDlR�p��%��4�e m��'�E�⮱p���h�e|����v�hj�8�A��(f��j\��Z�G��sx,-��p��F�6�M�?��bX�0����]���f��:�����֟ߜ�3�t�D_��P�%����h�@��gi�����3a.2t��3ZA.�+\I<eR��oiL6� ɹP6�%N��?�1��B�q��1�G���(F��K��iJSzh-��+�?ꙍ<�gq�ȱ{��o~:�����]�Iz)S�9ڒ0w�9[��6{�$R~IS�%��L��R��ҡ��-�y�� �a�.���U�#�z�f�t���~y�ms�sݖ���R?��<<�{���bmQv��ܵ]?}��,s�:�"Q�2�|9@�(���Oe�f�k�Z�AB�Ӏmʜ�0->jj�Ƀ���VC��C��MP[���� �H�J��6�h͔"c�9�[=�>�-��ڻt`Q��u9Q�[�, ���k��.�hǬ���C��Z��9Lƅ.�R�1|��|L'�w|���}�vC�Om=���?,5Y�3�kb�;��&LE(�̅^`�d�|xa*�2wv��τ�C.��}L������GR%�%?��e�+�	���s�Y���-dwˈw7�4h���}*^�97AQm��2�z��>NM�?��b%��=�{��ufz!�8%�f��9���1�+��du�(R��i��K�|�B ��smy^���F5ov��&�8��8��H)�G��E���PR?g���v����Ϳ�VI�*�����d7fuо"�!��M��A��� 1JLH��� G���r�^!#�!E�o�>�e4�}p�v7*��\�&5��
۞%�����K.z��*�S	-�M��@Fx/b|�q9��L;l�L��V�Mq����ee�!Ӥ��ī92�
�xeYZV����$����
�A�T�^y������f	P��b�_A��MT��C�Ju�x�C3�����ą;3_|[�d�]9��6�>��擫(��IW�Q�B�Z����(�̝G׳u�\��f��g5�l�@���@��0O/Q����.v|]r�\��/of�(WPV�ln���/�Bq�b�`�q�p��Tݱ��X�����X�ʷz��0$ �$��:�#�1���O�
�M��4��8L:�5U�A���6�xK����9TtwT]g��rG����Ś��JK9:
!����5 t?D�y�o��bjW�32�23|�zjy�jqS���-�S�1./֌O0C�=�kxU�U�b������S�2��ȳ���is(^bfp�ho��� �d�����~��������~�Q�N�sBw�k��G��ñվ�v������䏮��`�\�reC�`��/ɏ��]�	�Y2f]��R�F	��oK���&�І�L�B�rkV��6
.|�]z�\\����>�����z�
h=z���#��u�a0U��!� ��Cd��$�XL�5=��KM~�bz
���O��͓�<�h⣉q<��s�Tv]�Gh��@?7���c���fW:a�����H�^@^��Nv�ҸM�<	��C�Q�Ë�K�3��j��t�O���RS��+w\h�)����1�Y^�M-6��f� z�f���2Qѝe�b%D��A��dZGςNz���ݙ9��4��	�@�F@(r�F/�o��{�
��XJ!�݂�� ��Yoc/g�R���PD�]�5�D�j��   ���O���T ������q0��g�    YZ