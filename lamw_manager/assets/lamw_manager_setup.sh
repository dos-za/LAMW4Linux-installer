#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3628286903"
MD5="3500344965af508ed4ef6a032bf8b664"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23928"
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
	echo Date of packaging: Thu Sep 30 18:39:34 -03 2021
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
�7zXZ  �ִF !   �X����]7] �}��1Dd]����P�t�D�|�$[�E�E�sۤ�l�U�r����o6�{�����Ȏ��\����%����J��jp�d�r	�r�6�kA���Iq�*a�w�'R�Î5�&����T
�oY]?쒺3��R��3���C�[�l.�ٚ������;�����Lˬ���0u�� 0Qڜ�5����C����E$7�LEݱn��2�|*�U�&T���~����vu?��\��y�\t�`LjR?H1&�b�$�L�g�5����y�����hA4������e�6��mcA!�n7!�%4=S�jh��Ӓ�ử����X׋x`F�>�i��]Y�#���CJ��w��ۇYR�xd�j)w��ejr�uc�(�=? s�"m������g]�|�sD���(����O�«C�(��n�����W]�xx�6�Z'5��*2ʨ*=��wH:�'��;;�����9�K܀s�LI�*�[�Tq�v������U7p�M�~}��!�>�%�-w���>?n!�S�I�/�R.x*�#�(R�Dt�pNU^xΈNc*�;pЙ���e�ԠO /���@�G5���C�W��|�[;tu�`�aL��U��\vj'̻枑����*�<W~����2	opA`�1��&�A�tIW3h�f��������d!�i<�T̟��~#�Bg�c��01kQ��p&���;�K����x+����_V>������z�9mm2�R��m���$A\Ƀ4he,�p�i�1���2�Z��ǡ�#!�~�KN�rh�o����{����jH��o�&�tWG�Qv,�|H�.�}/�B2�����'+�5���Ϣ'򳍗�Sm���R�7bzc��X2�.�s�W�Z����Ӫ��3{}Ig�hF ����	�)�V�7[�Htw_��X�X��)w7�1��ֆϑ�q(���癃�a_��U�k	�x{�����R �(u#�j!^��/�������u0T��}��<d�?V㣝Cvg�iFkl,c-2�ӛ��HL�hs��:	(��� ^�,~Lw�nڝ�s�b�O����r�C��~9�~�9d�X?�K�&C�񐛟��.\��6�e_O(��{�]8>�x���L|�L�g7pSZ����Hn�㖄)�U!368\ݯ2���2ˁ�Ꮥ���D�|���r<w3�s�A�
���V������$-$����V8<B1�Z4�B+�ι{mel�\�&pd��܂z�Bxd�[J8Jv`��
�On��nI��i^,���#P4��^����G��9�۸P�/�Vv��ç &��9#�,ҏ�f�r����"D��O��,�{�^�Y��k�ջ���F��:=fnpyO�Es�/��C�L�-Li-��D?�>�I��r��Y�Oi�Fy1��
���M �4yQ���=���Ԯ���D%y7Å��D6�|y�%���VuM�s7�]�xiNq�E���ʟqr��q�����ԮT�ăm�B�c)��h�5��1���dy@U~���JQ���7�
�㵢�_��)�������鈾՝8 Zߦg~`�q�mR]����n��>_���k��g�$�8o�燸nX|I�"��:���s>x�m|��,i-���
���5W@�-��⃲.����q������w�^��"l�}�e��zJ �/�.;���*��3��\��n���Qa��:�(Z
�~��#��s�K^�ǲ�
��{c۠O~�]A=9�3���	��1P 0w�K����cS��t��
7��r�����ƹ;�jU��H�nkS��
^8�8nq�5����+�u+��`Y���!������#��\W�Z��|O�B������7���Hv���e��z${a�mJ�z���P�9\��U����&��2�T�7ٮN��[��E
��ӕ��N�`L7s�V�>�c��5Â��-��"�?���.��8� �cc�Sxl%�/{��hE}�D���DErE}��k�\,����b�G�@�[�<(Z���y7F��%s�Ūb�.�����45�6W��'���Z^0#{z�n���2��b��C�P�p��e�d)�T���h��&T��O8ԣ����й"�|�s�ԛ�;_���G%:Y*@�Wĭ�q�ʒb�<O���z���4�ĴlL���m��x�;s|C����*�,��Y4��k#L�q���ޝf��8�1�xч^�����.[)z�X��>�grЁ}!hf�n���T��*�MFQم�Е7���!�����b��EL�eP�y��|�Ex��T1+�WG�� E�� `m�=*�~����T�,��OK��Zye�7ґ���� ��(�9ȑ=��R�����Bb�i�|���	����$gaڠwOzEa-��m"���z�-U�]4Ѡ����b�rx1�OT"$eP�+�A����ٔ`�Q�7F�y��ecM�6����G����Q��r�lR��K�p*�&��h	��Sq�{�)1���čם=9�aㅧ��_�h�|0M%�(��$3"��]��	��d�~�mˁ����?�s���i:�6�wi��4���uAIܚJ��B@c�Sm���9sM��6c���>49��fJ�h��8bN����I��[x�"�@3�֌ �A�h���gΘ�c.���.a���yc�Њ�pc�噰kb�#f�#+�Zݳ�w4S�uA\�1�q>�E]֝|d�Z ��$y��>tr�IO��`�?����p�2�}$���3��X� &�\��t�����ƍ�K�mIÃ۳*e����!CT�{DoI�-䀥p6�B�3���������i��BT#�Sϊ�, �C�D)�)��a.b[e<�w,���EI:F�Nڻ�S�S���U7=�*.�h%�/���N�-��Fy��}5��y04���Q�;S[`��n~�B��diKc*#���I�?b��eLn���j=�'YjQ�U���(o:�O�`��S�m#��%@�K��jH����������jཱ��-��o�&c��	��B|d4G��b�im[vC�d%��e�U�&��è�;]=����*yژ�A%F�y�8�N���ϲ��f��/����۸^ p����ȳ��#�բ��{���P&�@�=J�p�P�	|�z��4�([9��	H��.fF2��ґ��kэ�p%ܭ3NOV�>0�*���rKjX}6�֬����5�.� 9A4
*ST���Z��Ñ�<W'�U7��w+���|'D����H���q�m�Crj�:�K�	�~M[�ϫ���*Vw�ޗAX.#m�4�_gg%���Ǌr�C��4�!�{�샯�[;~_(�4��!���][�*^h oj{^>�n)�ګ�u3��>i>�H���L���yB��~(y&�r^W�ļ&�cu1Sd���֥�Z�+*{��ņ��=0���&�i��y���KydUȹ�}@
Ƽ_є�j*���������W}���֡���} 5����^��Y��	�ܦ�d�TH��~�pL4LW�%��{B�Ϣ�������
�D|ȳ���ۖ?�<R/�L�y",�uՌ�=�N���Bo��3j(rP�$�7�j1����	��Hv�ם��)Հ�T�����ˣF�u�~��"�O�@K����v^G��Q�:J�Gb)��1
�ɳ��bt����+�Kz�h>j\�!��R"dϷ��L��� �M/l�[ٔo%�E�f@����eĺ/h(R&x�Nє�g��G�J%�8��9���IW�X�{�tM��z��|]}��>^K��1Ab�]�;�xTQ�g�X��tXm�� ���c˙��ʇ	�=�'{	%��uj��0N4&�Sj�Ѹr䤉m#�|��Fz&����7"�@��E�@��i������;�ig�h�4����oR9�홞��I���?<�e �����^�%'/w�y�)�(�P�[T��||]��x�Em(*P�j�|D�7��S_0=��ݢy(H}y�E	�W�5oD���+��v&8�9��y,>�2�!���m9�f�����{=�������\��@��a
�a�3�C�F�ݝkD�p($2&�����'Dݦ�[�^��A�>93 ��%� �7���q�������]u�V�tWk��0:�2yzF�_s @�p��}��q�3x�re�����d����v��H��"� _{��.�K�.��=4�Y�M�6��y�De�݈�z�,���H�� V�!60�j&��,�}�)�J�4Tuxt�xޖ\w������Mk��5�PH��_��'t���<��ϧTmf[1��Q>����r	{��s��ꍴD�0�Fy)���=����0����H�����C@�b����\�x�Xz
���>Y��6+�n�<PZ�L(��1��,0�k5�� Yl��(ˏHߩC���3������+=��8ն-H{A��=�[��Y^�u���љbN����^QF��|h��ȁG�t�t��6�,��!Q�����LI�>4c�.)O��g���h-S sMq���4"����b�R��Si�����1s����,�[0DpA03ZE������y�?�ɮ2�E�?`�2�GYr�Ȥёl��Y���׋|��ݴU�
�_��>;�fdA"SK�i�w�8�������̃M�W�8	�n�����a��SC`Z�����I�ɨY��c���O\�[T'�:���_�TN�����a�_-$���ٳk�}�����x��Ս+�3.!6�I���<�7$B�\���)�}M��}�݋��^�l�Ęg��8��n����Qm+j'��M�;�U2�M�9�iW��䖔8����ت��gcRP���!����ZU����8�_�!@�yܫ�е?�)D>ɉI�W���tM~��<��c���~�|3!㳺�¹�J��F2��Ꝛ�]r�E�N�����p��s�"�L��}|������H>4O��lã�	�R�`����KMDZds-NLH}�K��,bDv��2�N^��)�O]�'h��2��}>�u�������ۋ��Fl
`�y�jSз���S��qz�5b�L��|�=�|J��-v"����"�?�8=)ǝ���#JW��c�q���{��u�l&S��Wk���4S|�MQY�����E��æ M�!�z��1hH)�6R���AD=%w��31���~�+9}��}y7Z*}\�(��r=�?�&-�w��ܣOr^��Q���4h����1�����[��T�ɨ�����3��We8P	�A'�5�F'~L^��򰹺�X�R^�� LA�2ң�����q���ے�f��`�Y��
.2&�"�_�r�Ӡ����l��Pc!�6m�?>ì��9��B
�v}��֌����m{g�Q��f��jr�l��N},ڑ�"u�U��`Lj�T�<l�܊�и��D$�/�
	�$���>�QR��}i�C�X���_���@���p�a��}O7qZ��:	�x��5��zC�$�f���Y|$
^��o��ۡ7�=�]��S�}k;�rm�>�"�q��6f2��A.�94f*?	r6_Ȅ���kY��å�gsi�G�~��H�Z?�4`���	�|S��.�����dk�ЎQ�Uu��k��Vz=
<�oi��ne����<��&�������I[�N�B����u���'*�����D��$�j\�ݠ�pzҔS�wI���(x��(�,Rf�2���8hRjA���'pʬD�bF�J�U����!���^IF.h��Ϲ(Ŷ�I۞���^���MӘ�����s7VƆ/�lö+��K�ه�4&
� S7?��2��>�l�_%#��h��Wٱ�	�����d���4|vWRp},����x����@.|�~r!zd_��D8u :�6��3@co��(;�lüG
Ÿ����-��"� 6f����nr�XV3���t�K�x��Hh�'���*Ɲr�ݨ�V���#^��J2ُ�+�Ed�
=t`���G�Ջ�'3�X1�cdA�G�3ߺ� z�#��acH�F_����L���ΥM�?��q�H����&���Ro��[=1*��6�]������Y!O��0��i~�"DC����WNr;�wj��]SWϙ�b��nB��w]1�!w+Vg�#MPu���nY�񼪉�Ekێ��Y�o7eq>]�~�)��f�P�8��Z���{��c�� _ˤ���^�e���-�uw���|��H�K�!�K.Fb�S�ˑ4�<��cX�G��(O��*=4�0��yHA��j�Bz^]�L߂
&���ek�n�A^��E�l:aL��Q����6��håo_�2�L�Nq�r;�#�eIJ,�VӾ�(��$H�������]�qcϱh�(����A�7�5�3r�#�%��-���]�đ2ޟC)��>X�VZ�?�QnG��Y��|7��y�����G�r=ȱ��ql} �ې���}K��O�Ȇ{���x��]��aSw_%���Ϩ��i�҈�s�#/�?�������H���:�?���wJ�
4�(���
�n4z��k�lkЅ�Rޅ�Wm֔�<79C0bo}�$o�p|�:e��f<�s����*$:����ei��?  �rw���f��#��Q ��6k:���͘��lW��f�$�rmc]h<;i�f��4��.z��E�����&l�	!͚�a��C����q��[��#}���ۮ��P �	�� ����.��&����nX?rk�A��nqH|���u�Pp�ޙ����gu�M�n�YځXk`�@��v���o�j�|mɣA׊E[)���t���ĆO_B��	�,�!f0ڙ�'��2�ԣ�(��f�6�����
�D�Z�_��_��w"�+dV��RGGo�#<HT2�ɤ�
����3J\��=m��A=&>��Nv��w7��kHs"�c���,A�4#7�ɾ���vr9�{I�-�6��z��!�~yя<�xU� �<��$QI�����Sߊ�
�D5��TWp��ǄՀ���r�պ�f���3B��
?�W�ݣ�]C9,|�2�ŧyE�sVH;��Dի ����?FT�U~�\7����.;�������F9dMӃi�B�YB��l�Z��x; I Y!���C�F��ѤjP<�	v��lkD�1����D�5�<�bj��?z�F�c�A��>D�y�f�v�f��r{mVjf�"�g�#������f�8� |��p��ya�s��\��E���?v��;	S��G^`\��v���ت�Bqt����qW�#k����b[Hc#���o ��O��P�>&�L����z��3qrh��⾕�t֬�3�'�V���n��w8�4@���|R�V�Y��슊X�(-���|�P�Ŕ�Q�j����g�p�g��ul�ס* :�E���Xh�6���\����O��s�ՍR[�-wڍ������F�o`zcq����RZ��3(9ra�d��?�yBi��-�"�*�E��x��R��+��K<��ɸm���A4-7b���+�4=ME�իƕ����%	�������Ue�$�9#�_��o
���@�8�%��	G�>�;�����i���mE�����#V�h�n2�͸�+�^枫-b~Z�9�۟i�R�(�+�T����ĝ
���A�l�p5�͐�m��7[a����/1�c��@~-uw� �^����V�y�c����[ŗN��@X8K���n��>˩��)��%*U3�=iZL���$!����R�c:�C�1"Q�����(:E��kr���M��/�J��lػ�Q��-S�f! �AQ^��rv_�O	~4}T<ws#�H��):�p#�}���k�J��3LJ�mO���ľ���vZ~���3<"�RI`�����,�(�D]Tw�W*!�� ��\�_�Pᔢ���-x�	��eC
�5J��w�'kj��t*�V�eX��d��ly]��uBE��v12��{��o�Ԝ�(B7_���0�yV
ZɗF��Ckn�xx���ch�FC����v�?2+��:#��U�oը���h���|=X�`��ؗ�E��Z4���`$l���M=��QM�DȜ�/TU�S�NP`~�J�b+x�����gh/N�������hjgr!QƟ�D|`sc"�r��$�4V֫Ͱ���u���8���cq�(�9�RY�B�&�K�R`Q�	������Fz����b��V=L6>��d��y��~'_W�?�l8R�z�b����V�-���1F�*�p
⤼A���eT(�A�u���ǵ���B���%����
,�D��ʖr��Z�������~��� uY�SS�Xh-�ap4��H�1� �G�։�m������C�����T��;�ĦZMp�:y)�w/��5�4�ZcByU!�4;[�˳�
��D�~a���2ܪ*F��zqcs��; B����7����?��x�s���F��3d�W��� �;���ܥ�6��x��ǈ.�&�������,4E�fH�����  ��%m�ۀ^�9>����dSm�d�>�m�����;�!,*�^��>�q7�u�W��loc��A��
�?X�t޵?
bX	~��@k�J�!]�5/$h��j{��)��yM-U}�̛��:xJ��"�߈���.
��W�t�h����4P��!Z������fW;�tx�gT�Y�� ���y�G����[ 	s�� *����,�p�������u���s6��i�o\�#���̢O6�N&�[v�1�����ф��B��x�N=�Y7��hB��i�<��@�{���R0��8b��\i�t����>�M��@0�p>�CL�_��f\'�����}x��]�]8����U�s}��gD�{4�sd%Bu��A�7Eu��eL
�z��N�,�j�Y��cǼL]���mN�B��4�qL�Ş�X���X�,���
f�$�&*B���NY0�la�g��7��*(�:�%u���A�_��%�Cy�Ed���)V�;����e6~)>�s�uʬxƋ�a˙�ov�X�=P�(�H8r(�{�?����t�����󬎘�R�6i\���V]��73�4ߏ��W�ݡ��7lW'R�6;V��6G��.��d�>�_�3��B���6��T��քM����믞������-i���y�Dp��z� ��WJ��w�ji.�u��T�LE��0@��;���s"⛁Y�S�5�~���|���5�����HA�c�P� S���a�NXw��/-{L�b�S%�C��ra*.�� �!D!��y
�p_)�7���"���o}�͂�j�|���<k1��5�U��t�(�o��EP���|5i�۾���#��T��x�~�n��l��[+�%�,���v�����U��}��>H]ڣ�W� BVD�e�'��`��TMA��LPD��^?���1~��ϵ>�,A3Y��v���7l_�o2j�+�D#b��8�,������p�����)�W�4��	�nѴ���}e�������M����jk����<���(�]��q�?�:M�G�����/��i��	�{�����e�oÜ]6�C�9�%�����z8���9���b4u]��/��؉ß^�|�������/8;�P1�y����'��Jg�E�1v,���"��@G�Lh�P�q�w���۹���0�_�@Ё����8��'m��p�����Q�F��c1��}�ӦU���8X�ۢ�1w���C���'� �����\���?�T1Sg���\�W7O��^>�l��Ųb�p�N��1��gF���1R�9�'k�gL����,a:��a�%�G�nj8U���92czŃK��a�/ �( ���b^g�c	Ia2'Hy9|�yK���DDE=UO�^D�c���HT�0�<�Ļ8�9-�4�i-Z�|��:a�����^QJ��Lo�ۻ�^��(�$i�3@��԰�3Z�@o�h~"��{���>�G�l������{XKlJY�� �\8�#�q�f깿b'_�n��GLo~B&�36��+Rzgȥ��Z�n�T�����oO:�G��iY��%؈����#�.��o�P;;5�17��"��`<g�9��!�C��v�C��`j���Ў��s�S
9�U��PE�fƺB����\|�qn�Z"�.����c?�{1�6N P�,6ۉ��B,�%o$v�Ȧ/�E��b.\�=J򧔢�??���L��KiffD�ua��+��9��xe|�C�yG����(`H�T\h�v,�&e- �i�i��p����@��)%� >��|ɗHN���%9�P�Y�]�#�p�_�쨯�W�t��>+WtΫ��AK}sB+�}1o���>IR�.�e��l�k�ŀG
�����00C��eEs
�`��%��_�U�'����#6�=0�:E)ǤS+�´@������9��c/���/�~ea�i��yW�jn�;h�`an]��m-{0U�W8J+O��R��V��n�I��-;�}����Ȩ�e&��!Ԣ� AG{/,�J�ԍ����(YɠM�����ǂga��<k�1��ri��Vl�j�6�J�MX��\��N�Yt~,4�S��LF�>y/Ҁ#�E�j�I�wI����6F�I�𪎄�?�{�
�������<�=�Cf�
679߀�ճF&A+.7��M��%
���4�	fN�4��r|l�$��<��=�˪<����n�+�[Ҙ��G�����(��D����l�a����%�xD�-q	�Fa�
l@�Cç�sP��%d� �`��w]b~��]�X�B���c���節IL3\?�5_X��u��p`�T���٘t��m�z6\���8����������өͦ�#NZv���<̄�{\��-����i��H�̀\-S�i�X	���LԽ�:�B$�KO11bM�~����'K�a�%lC���{���N�мw��U�La̯<tr�ۼ�Wr#N�)Zװ�`L��U�t�l�?`A�ӵ#V��*�����Ģz�N�H��2�~�D�۟���>ޤ�]�>��"fr���}]���6�'�[�t��J)�w_�TM�)�����N-�%�8M ���j��w�cٕ�����k<fQ� +��ٜ%/��_ю�xXu���=��4O�$0�2+iⴓu���\�h.�a@��HTl��6V�!q�V:��5q6�/f� �إ�����{����z�M��!�����l+����\�FM{���i�ly���j�7g����w�W!��!ٌW�:�P��x+e��:PF�~��m�2B�o�x�l�>0/��FנT�:��������xNf���̡���6���}�i�`�<H��q�(����rC
<b�OXf��v(�\#ͳ�$>.~J��'�}IUW�OW�����﷓�`�{T� !�č����;�5·�S��S7|��I�$�,R躂�J�'����ӓ?��l�W�I:����Xxs��e�'Ai�s�<g9!���ywg�V�쭵�����Mg<ԕ�F��A�y������U�	WlB�A��0?��H�u~����T��wx�j0��ra;���cjH��:�s������ް���k2�<j�c��)�mռ�������֦�_+����u��o@��)�.� ��M����f/Px~��t)KU,:~��
F��e���Zߠ��8���C3}^n�s�·ƝW��[yxi2�������w�X�A5Ơ�bx��O����|���Gb�����޵�^m���Ⱦ.���'߭��X'�� ǟ�&�����h�(���U�a��UE绔V`L{��{J1��r�}7'�7�B���@kmi%$��<Q�٩c�Q�פ�I7��TC >���ܞ�Ԙ .�{�}�������ޡ�n��སjkV�����5��Z"x�E9¤:����XCN��a8e���:j��xt{:�����<�Ȩ;q'- ���~��ڴ�l��Ƒ]ͣ���cA�u���h�h,���$���>w�#`�_k+C�?��K����˴8�-�ǝ�W�tB� "*#5�]��e��x����[�~�r&�\���d}\+�B���-Ut^[Դ���E�r�����&�䱾�$ٶ�(�n��h��#�o���)��]7!��kC�ΒZ4�����ڿ�\�0��]��{3�%br���I�~���i<��W�1\l`����'�	�9���5�9Z��8�n�w�J�*��w�gF-0�w�����ד��5vQ���s�����D)!� QB'�PJ]+�/����h�H�r�PX��c�	>�s*�Z0	�;b�8I�ƗL�~�ӓ���$1��l��� =�Yiw�'U��=��x�g����*`����Z{3����� Z�=&��^Į����a�tb?A��"㩎_��QO�qc�(��bpU�퀠�yS�o)g��>�v �0���ؔ+>KG��TKھ3�{���U�0�f@o��#�	~�)����P���)�)RʹL��Ⱥ/%��\-��1{�ۿd ��%⧫v;���)�ΐ��� j��G��l�Uy��maJ^��B��ZY
�.+vq�(��m�������Y�(`b�'�c��z�giϷ��X�t���4Cȵ�jy|�|�Ds�>�^���5کQ��|�S�eQl��\ab�$�r�7�ٍ��4c5=�)F�Z��9�f{�[�����9�ͽ@~X>��12h��֢I���B9A!��B��Տ�h5��D��ܟ~I��χ�͝@��nw����K��Ǜ�����>����"_����s>>Ӫ���UzU4�dBw�؏6qWgˆۚ�N��S�����q�X���f�Kh��B�L��7�����fFA�֧U,lx8P�s��U��6���e?��4w�_�M������2mJ_��%NPތ�۸0��)@�E���*l?�>��%ÎE	�e8�s�|v�����k,�f7'��u��3?F(���tM0ףL��R�?�kXo'~�?���
���~�21���3.�&�;S�p���^�ta"�KLg�Y��m�F�`�ߢg�6/��։:yu 4d��W	�ާ��\�$i���?��c���g��h��=�W�L���G\��/~�w]�KC_�wH�n�O�a�4n�,����3�����(V!�I}`v,��<$���Y��~��nw�͡���7P�dAnؤ{��܌-ESVH+���YZF����h��׭�sN��v�����:�e�5ɍ;TK�+�`����n�x�r}��5�LGv�C�A�}�7� ���t�\���{�Z����"k*S�h�<R���j�Y"'R�ph)��*�J�a��5��l��w�D}H�6�"�-uJ�K��&�:j}UEmk\a)!q-jK:�[�۷����_$����\�~@R���W�=�<X$5��XL�ڦh�\��{�+֙�1;y��8��GIoʩ�)ۮ�����8�×zq��{��m;b'�@J��D���*�*�W{C��(��`���:���N~�G�m��bNs�h�P�k��+hn��7�5߉,j4Q�jХƠ�+��_���ėn
�Զ�7����f��vl��A*mߎ6���`vWs�nMP��O�.?㝢M!�j��0��-�����?���?
��FV�&����4��)8���J�¯<ڃSg_�4�I��ñ�e�Wh�Y�f�{�	X*sK�J�0|�W.��s�[d��ix��HL��.vi#H=���k�h�Z2��UB�=�eB�kL��w'����Ѓ>%mOv&;��J��~�`��=��.0=<6�c�	0t���;_+!�!&��2�HUJ�*[����� �@k3Nw��NW����}
c����i|��(I�k�5���Kl�[/۬U���g	��yR�- �xkC_Գ�Q"�4���Wc)��`�ٱm>SإsY��9۠�>���`�(�y�F�Kxz�k:e�mZ��n�s��E�}٤�78��D���?�^�K^Q��H^�֗)�ƿ��gt��?��*R �����9���'�ͣ��%�"t�q󅌏u\"4B;�=�����;u	���r�W�Vu�М	��"����ի�Y�D�{D��%���)ȉ�?#6��tkz7 �}�q.[���-!P�J
a��E�b�&�:�b�� K��y� WU-�3>Lq��i���^�I�g�-M�o\Нj����N4�n20�v�s��Ĝ�>�>��ES�LV)o(dN�o�<F�.��5o���z���6��H��{�2������Ͽh���O�O� ��N� �ZқڵF�xe����-و���J ��G�/�c��l��OucqeU�O��'����s6�*|�PR����ސ;��8=/T��9��<[ntL���eV�;QCW�SP�-��ѥ��,J������ ��خ�	ҟ������w��0;:g���Uּu�r��?a�8ӡ�z}?�KyJ'��]�B:��{f�
Uc �;�\��aSv�3ñ~=��_#IA�8ҫZ[@X��S��2;1n�`>�ȵ�/���Z~\�*͛tGitx*�� ���*���?��$��s����S�%����'�����O3�Ȼ���0߃$8��b!��1n�m������F�"z�����0ߘ���2��Lk�4��%e�Td������E��@+S��	�˚���';�&�����<� R�&Ƹ��k���'�L�y��^Mm����cu��1��PȦ�Br�@�]6Y��#��G�����0��D�ֻ����bVY���]��C\�`W(�۾R�zt�5�Fv�=B�7S�Џ�����>���m���B^-����%U��w���g�XEMo�x��.A�Ҏv.\�y��R�w�w:��y_j����>K!
h'��.���6/+�h�t��������Ʉ�-oׯ�������y���.��7�y.�)}���H�d"ȖMM>�m�T�Y�w��]{�-���a�̺0e#=8k�t��tx|�L���Ą�%w�zX�a�~n���A�����+O�(D�F�]6�ЈJr��{s�/[c����h��?�U��;�.Z1�S,��ßS,N�E��H�� f6mP��x�(�Fr����@ ��Mq�~�yZ�4����X؃2�Ǘ&0��G����aG ��P*�y1���{�\�R�mt�6/��e��6��!�U��q�����	QpS����S&^����}s��
�#_W?�]�q�3��6�y-��祃�����nO�'�AF�f����C^Ț�<Ӆ�i��zei� ki��jg��s8|��.�m� BRٮ��µ�lC��1�-Rs�xA�����/��4�9nO�r�Ӹ�.Do�n5�+`Y��\�g�o�q$�Sj�-���V�-�XF-�r�F
{�p}V}�M���;b&s4i�y|������z�n��(xӾ�xJ����*-��e�"��<H��Ksg��y�xn:!��+j&I�v�S�jt��{��0A4��^��Gņ��5�~�-��KѨ����]J�`��fewvU/��v�xI�7{�H����z �6V�Qt߱[d&��%6��18R�D��o4W��-�U�>��	Q#l��w�!4�ͣ��#����̅0���k��0ϥ%*�Dnӕ���� Ma�ͯ=�ҽ&�:٤��z��g5���r]׺�ݦ��~��]�lC�-���{C��7T��2,+��vf�X�P֍�M?X3lr�$'�9���W�����	��}J8Y��z	H��ʱ�:�x Y\��k�tQ�DU��
W ��}�~�O���jvG��!��Lͯ�o@��D���<�).�G�
��Q�by�1V �-��}���qi	���������fb�F���F��ZlGM��^����1f;�Q���F�x��j��TԵʈl�v���z����7gr��꘽��nT�,-Q�I���w������;�⧍�%�ć��sC.�X �a�H]�T��`Pǆ�R@�akt��RD��^2���]~AN��t/�۱��o��H�y�M_?���Sc\���m"�
��O��Skv;��t8��*���iU9���0`l�WY�����k�]$骣r��w��c9��$�Ġ?1��N��tԍ��Ҽ[��pN�%/����'i}_'�L�J���tGxT��e�J����2��G߈־:	-��%~��d�6���2���r�e�r�jl����^ף���=6�)wtP�f��}5--�:ಸ�8a2s����ǫ)�'C��"{���T���ڰ�a�_gv~S`�����  q����5{�Y��8�e~1�@�,��ÿr�Qm��ƪ�&�l�U�lj��M��O[ZQ/���٦i��� yU~��l���HiP��5�ˌU �U���|��%Li��q�]�����b1�{��x�}����؛<L�%>����6��.��+O$!!��QUz�1��j�\���׃:��۳�p����M� ~ �r�.IA_��L1)s��^B��q�#g��Bj������
��)J�J�6��p�?�l�R��N��Ч� 孼f���}���b�f�4D_c�׀a�K��(-X����R��x���}���L��Yf�:-��a|���E��=������˺�ԝ&���;�h�Eǿ��Zl�PP�Ӵ������y9�߽!g��8��{�7ey�G1���
�K� �����H��d��Z�KN��-�]�+��YB,
��M��t���鍊��X���DA���{�˗����V��ps�2��9V�R�O��<a�>66�'k�^񢯩̗$-ǩ���kb.>H�J�r�j'�E���y|(yߟ��S����RsD/L�w]6�/lt!�/h�/����(��c�X�|A�����W@RZ�|�eGH�.H�#Pz��@�<��c$����l��Q��杙�^�9�Wcޙ�3�����|!n�b:XW1	s_�Ui���O��YQ�(���Kw�a`��B$k�wGD�f}]�SS�����E�m�<p|g-;�'��n<��)���Q�g�Zn?\��F�躰MT&մ���;��M���@ ]٪�3���gBS/}Lq�W�>^3IK��v�R�f�ɠ���8z�鬘�P=�9����z/3�	�^���,�L��6�I���>���~�� n;	�4>Q�� X�?���R�A����*�/ŭdD�t,02Jo�$_U%��^���� \̥2��-��bU{jv)���zB���S
�<�@(@b��wV���<^v��d��W|W|���)R�9�������g���ݝ�d@��]}��]�m�Z4�YY��]&D�ЀL_�I�l't|A��mqL6R��ϫ�Ƿ2�u�>��ɞҺ\#O���K���ێ�*亮�����.�v��̻q`+�}��g�����G�4����s�.c���g�N�ȉi����aW<4BgE���zQ�e�+�u�=m���s��D�'X7(���ǲ��<n���]��5���H� E�G�:"yba���!?}�F��7�4{�S�kfT>}m%�8�Ti��O]O<CE�{�1R�o��P��7|QTB#��¤���F�
����*?M*�!�P8.0�����8�/Z������;�9���KBA�'���,�X�t'�&���6��}�t��>b��A���e�_��F�_ѝ+]����xl�n��e	�B��2���ӕ(%u�!r^,I/A\,zZ���v�3^��Cu򐕄D�Q�C�6(j��]��Ry��w9G��/�|��!�A�(?w>X�7���b&ߛn��;�pS@q�y9c^=�A�jPR)�je�ڛY��'_$&Rx�d*�vn�j����R��w����$���;���k;nV�Bw���&���ۣ�� �o�Jh��
�gS0[	p�
7+�t��A��f�3#�� ��8A��QҐ���?�[�}��j�Ȇƒ%��+� �yTS!!�U�!"ߒ̆BdRb�NI�\d�Ab�	f+ҭޓ�KUxm6�S��ɲ$����~3߫�*��B���>\�i_�i'�;L�e:�#g�9}��m�}n���3o�	�IO���+3S��y�@^1�9>o�E�q��WoT_a&♿�;I�VRl��Yq����U
�沨�NLdP�i��Tr���{��t�j"�K�$��EP��QF�I���Ci�ћ^C{��Z����,Y���>?�k!�(�ͅi6����,7�S$�.�{�^�X�<w(���Up؂fı�A]������ŧ���R��9g�0\Y�O�y��:*C�G7����h���18b�{�K�
�6i��y����TA��;���h��dj>�=z��"�MN�!��e-�<8����xG�*��} Y7�ŧ���B��6��,9nbtX�T ƫ���}2�0_��d�@/S���"��#$0��rׂ\�n7��!�'Q	� )耜�3�����9��b%�ߩi��w�?��4\�^���_�n- J�rl�Z��m�M�8�؜-ns�}�i�A>j"����#°>�G�u,�i}�I�/1\��![L�z��An�鬻�m�ݵ�.�X�aϏ�,��\�?&��t��L0HwA�b5K7R%,D�crP�0��T�F�t�Ƅ�S��/�5�n�G*_:^�����3��U�7��c���O̞>&��i[��V���3 A��ʭq�	��mas�tjD��Ƥ�r[����SO�Z�e��:
 )�,25͗USQ\��������ͦ���+����9dY����,]�̮�(���nH��u��T�Ze��8�^�dF�bgb�����j�_	�x�F&�"h��9Sm���~�B+�6(����,l!b |�-�Vu!6ғXfHW Z�3��?��b�Cw��0�Q�Fj�8O�M����s���M3&V.w1�9����Z�g�j��Q�KK��J7D���9��X7srh�ᵂ��d[#�������� Fpa�YA{�54�3��l�0?�,1?
doP��rL��j��64���,4�<������>�Fy�ҵ�#q�V��zv/"IP��4`�Fx}C���	�-����v� �^ ��iU�;~�'0���%���X�ͷ2���D�O$v��+Tj˥@<#�k?���A枒S���³�r�^��W)�@��}����J���L�7���J0��pd=�����X�f��65�0����O�4�ɘ�ܑۿ���B�=������.��E�<�3���k��g�f��%��Wbm�HL�\ד\��9x/I��;���^��P��y�n�?������M^6J�j����	nU<+>��}��N���Hƅ���&�lڈ�=�?�nD�]0�h@��Xd؟F�$��� #綇�Y��j��|,vi	��Ui�/�v"�$���Mk�Ì/��?��B�$��_���2tuBk�ߟPl�W1q�	�F�d�������ڑJ��U�a�&�ԟٮ���l�{�X�cSƤv��y-)��E�W+��¨�rEQ
}��5�щ�Kĳ����@i���AP��v+�j����v27��e+��b�P~n�Pz�t~��qr���R���� ��P����H}����cKU�IY���'~y���)��!�L|�0��JsbL�Qw�"c�J �*tI"����P(��9*��Ĩ���z���}�xw�m�SA6�d�SC@ٲ�Q7O�������\��;%5C��� d�"�T*�*(��kmd�����)�;�3ct"��G W�}��L����FL]�XH����Q�Yl�szg/���1�9���^�i����t�H�ô�QyD�*_�*�d�U���C'���)j'�0\��[���%a�,e�6�w�a%/��D�ŗg��޷B���w�������p��TS�N�x�:;*4(7��~2�#t��<��ܵ�E�diͮ^�n�Ύ�����o�r�������p��T��
A2{\D"��g���D�Cj�
�҄E�/@_���B���_�:�n&�I��r%�[����wy��*�H���;ܛ��i�]�O\�5|7�R�T����|v U���E�'���3	Q���{3�u^S���h��ȇz��5�΃[V�*&�/b��ٱ��5���<���dt\�[`I*8J�	[&PnAk�d�Q:?t��w�H��κ8q�2�H���
K����#��v��u��0�;��,G?Ɍ��;o(+�c��΁���&j�|9+o+范��0��h'�~��]��5`�-F��,�,����4!�d��І8OK[0�D� �z�hi3�]x�q\N�v`"lc,.E���a��0yx�֢ch\g70n�+Ϙʀ�n1ȾaM��_mFz�sުǈ�lq\y��F�p�H��\�Y�CM&v[C
B4�#q�h��k��٘�L���O�<��?����﻾Ę�Տ��4�x����z�-S��
����@�U�<;L��OħT�~ۯ�9zR@r�?˜�-Y}v�r�S9�$��������zD[N�X]��.���pz�x��6d>X3�ZƎl.�e��j�R~��T)��#�����%w9��{���@�jx{O 22��X��k��C|��j���\�Yɡ���� %���)ȓѽ�5E��B��ķ�T��k����>[@��t���)�"_���b�t=�qC�}|�+{@�V��G��u$e�"��طը�+^�iUH�Ηe�Ʉ�类�j��@0?S]fc�?9la[bQTx�.�EV�OG��BI����>��I2��ͼ#�
?&'�n����s85��7�&�i������������Ѩ��K�&�} ����ȹ��/���]�7l�4},���Zo+��X
َ�	���=��vY�y��Jc /����â�H°�fA\1R?�:���Na`��j�m�Z���d�g5 ��Mg�
�c��V��=� �ކU���J�=�}Q�đ�Fs9��'���Tvs;p�]�'�%@�|T��I�Se��,]��p��@,L*�ư�x�m��R�,q�O�r:���K�n�>WE����>YAT�jԌ���뻸��:^�iZ����/�杤\PY��6�(��o�e!Ͳ����.q,�*�9��i2	����V��#�'t~�ڱI *MDmsk�1 �p�����*
�o�'�6�Cjv���S�3��7�2��8G���W�������Љ>療� �u��$��`sLp���3zy0����[����C��,����ӑ�<����qpo�����qI�o 0(�VsE�$[P��G\��N� \��Eq#@�`QȬ�18:+뒞R2Q609�2)꣮�R���֠���{s�ƮN��������'�T��y0ˮ���ۮd�^���0�@�K� GzT��J��%�j0e	@����g�I%U�0���X�=
����}��^y�הJg]��v6Fsm���{x�r�h�sl ��R��ޜ�J�\��0!����'ޛz��V����4P�"����#��A�*�4�7#Rg�//���K��5.ܴ��F�'��
�Z)�]����/�B���d��Bຐ�~�0�0Q��t�7���|�[�����(�j�����p�N$��T��=�E��ePF�m���l�&���D��YQ
R&�[��U4��(�xaK2���߇^D�ޤ��(]ceXYջ �k_v��3������n�a�΋W��o90��?/L�Ɛ��m�WQ/�9��ڒ,@�k�'��d���˄�N�.�ȞT�̞goYE{�Jj�ES��圶S:M��*���R��f�>2���8I"�������C���zbZY@��`�)�����H���0���:#v�d%	�Fp�
��9��Hu�Qqin�Y��W���5K�NM�" ���T��p���?#(S��y�~���&��%w��X�sQ�@�J�3߀#����H³Mc��4#�(�CZ��+�#��?>�|��m�gi�
�mnH2��?K��*�I4��8�E��~o�� �r�e�I�{�7���Ă����)�M2s���<:�d��.��jk��;�eT���а�y2��]�U8�᭕ʾ؁���*7�h=�1pJ�� ����M)�s!�b�.�]A䳋%�J�Y��=��8��y�n�7g6�ew�d�vnλ�Jx��K1�,룁�;�˳%e �]�p��<Q�u���}zo�s����xI�p��Ɔ��<o�T"dȇ����d���/�aa8��5?�F�F�r�fD��Qk6�s�Y��>9+�e������,���%�Z[L�����vEI��E.(= Zr���`��i����:������}�����ǌ$3.T�����q�Tb��#�;���H��F��X���9N?�|(��6Y�e���<�L	#mT��T����� � ����}='j���_��3^"���r��㛣&�.O��#I��+�����ɘ�ߜ>,����5�¦Y%Fy���_ �h�w���H�p]�0ǰe��w=���N�e9XY���KvF*c����/�"X���fɂ��jd�/Q3�/���p���v����Y� ��������cmj4��l.B���a>+^#%�� !E;d��� �O_��rb����#s�-������:�Y�
�WE�Dg½0/+�i���)T��� R��-������L�~Y�َo��{�t���|:��s����9�\q®���A<�)���NT�>󰸞K��s�it���E���j��[*�Y�:۸K��0���ϖ�a����j��}^���uR��U�����51D���莴�}�t���Է�P���$<���}-�	�x�b[���]f3b'��\����p
igEo��u���X�>y	#J�Q�����)��XM�Y\��*�k�r���8+K�bn��y	<2uJ
�)�?����^��[�;���C��AҖ�]��_7e��b��ПiO'1lp���v�F�Z������4�� ������W`~K�/h�,�[0:C7A�a$�T'r	AQPS��z^�)��S% �ON6٢�ֲ�k��̾~�/��wR�N~%�綄��І�_$9��KK黧 ��BL��ٞ�X����M�D�}�C>�t�ɘ��~��Z���z��][��SR�ƃK�B�w��H���@ӟ��k���s�0��b8�=��%���F�h����魤�o���`%�(E�|�hO�xFS������DvT	(�ps�O���c]��:�d�ʷ�2|uI�l�J�%^���l�/<l���"������J	�����=���%� hz�n�vΓa'�o7(�d;��c��GȖ/y_H�w��{��-�܌Z�m��$ ��a�\EY��J~f�`����w3=9�:�v�N[�|   lV0���� Ӻ��ᔟ��g�    YZ