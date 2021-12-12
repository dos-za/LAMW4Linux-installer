#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1855329073"
MD5="451e5e1b60418d7aca13334b626afc45"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25496"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Sun Dec 12 10:46:22 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���cV] �}��1Dd]����P�t�D�"��'�뙪��lǙS2�_J��vc~>��sf�߸ݮ:�c�dR�y��!Lv'A(J2>F�QSW��8@mk4emG�٭�O�� �B�:��E����Ϳ��b�&|N')(캆�4�8��Z
E�VF��c/,�����A���Խ��ۯ_L�)ӽ��d���C�A���$v׮G�݀�lh�?�{��d�{X�j�no�+��"���lW@Q���P}U�i؏������1Tm����0��ֲ�ս��N�-3~7չ)o���W�EX�Z��n�Ĵ�͎ۙD]Yx	i�|��X�Kh�Z`�n	�|p��+B,�*�y[,�v�̉�!OP��p�D�㼜�gyE~*�>���u������HϨ9��m�Sҡ .�î�>]�6�R��Iq�,�(؇<P��6�7^�y�w������o�|�ɾX�'R���ڀ }�)K��
��AL^�i��~w��]�9���Q�R|��T�xY�4'ʂi�&=<��PX���Z�_���Z�Q��E�h��N}�u�R�s�a�[񴲁c�Ɲ�	=�$�{}�[��^����m��d�͉����)�	�3[��Ku)�#�������&�t�ڰR���-w���\dᾥeF����)�U�v̟	&q1��1���e,�lƳ-ƣ��%ϵ
�el̈V��`3�іVo�y��?Gx�0`�d�Q-yU24�:�'��2�D��'�!8A�n]]*2:"(��^M4j��ҍ�ی�6�#������0]PY^ j1�7��9�Q;Z�"v]2�膛�Q.����U�Pg1F��Z�嫱ez�l�)�e��+�|^�r�� �&��Z���'�5�m�Tͱ��<��}�b+�j�X~nô����9�I���F��Ƶ�]�"��6ǔ�/��&�6���_�{��E�-��9ɳ�����⼯\|��9�~fQ��G
(o��.3f��؈�U����1T� 6	Z�D��U��5嘐5������cx�7/d��&��hg���x��k�Q���]C��~@H�����& @e����e�_�E�ֽs4�M��:P���d�Т�
��/27� 8��OLV	��-�]L����9~�,g,��K�Ek|6o���[�����e��Y#���Gw�`Z�'R�� �<^�L�����3�$�$��kv��ѠP����p��M��:����N��t�Z�{d��U�����6���,�� je��a���w�5�?��<��!�
�)�ŗ�E���-=��z��o*^��\:W��?^཭c"w1cedM��O������k]!��]Ji�{����Ԅ��q��(M�=̼\LmR]_n�	��h԰�z4��`ޘ �TX2ɮ`�$���5��5��&k4t��r\ߒ���筱�o�z��"�����9.RE��fЉݍn�* �E�^/�%SGh:�4la�9�3x\ zu�6?������친�BN�5����Ks ���KuW��*�;p�D�/��T�X��S��Ke%�W42[k*v���$L<�z��?�q��v��a���@ͩ����4���� �k<�Tj���c���r3��8L�6.6�R�k���
@�<�$E�u���M�bw�;r�ޜ�?���=T�Ʊx
XS�mU��ReV��P-9	�T��z|�;�heJ�&e9<��{߇��k��c�MvC���=U`��$�Ls�>h����Aȑ&R�g}C������6㙔O �Ћ�>�w_��2�w����a�\�ԓ����5U�X�Z��E�A��؍�:�w���/��0��g���:�T2ӑ�&Ԡ�}`�pR�q�����y޻M?�F���1X���R ��Y���ͿAU�E�(�$��S��q�ڪ����f}i\Kj����$�Я��e&B�k�G[�����Z��s4��!b��� x����*�)#F�f ��`��<d6-�h��Ḁ]�I� �zB����
W�jx�6���N�U���9�¯R<���p�{�ך�8�����[#�]jz9\�6��˴��+q`�@f�H}���w՚γ$���F%�?��� <#� �&��܉j2*!~�a�Z���:�����<1�}
Ayz|~0�Bc��u?!@��%KHE��:sl;l�=�=�ő7G|9���䷷W/���!~��C_�CV���g�!u���E����c�d�����Դ*yCmc�J��ܩySTǤ�Z��<��c3݋��R�(Ǳ�8~"�iT;� ���9��W}�N����C�g�1Y�R�}'�H��j�E�U�ߦ]7yG��?R�e��m��Բ` ���E���	��@|�%ǳ�q0ݽ=��Bq�m���K{�������;\�X�N�o��~�fw�/��`U9��=�W�9w�Y&gZ�&����"����y�i��'u:�'Lz����(+�5�@3!ȃ`���X��0�Rȶ��-��6,Ր�S֜u� �%�5Q"�p:?:�;��6J�X�e��n�ܞ�~z����$�Y8�K@���<
����̬�Q��sq�,Z�L�mV��4��Z@�x�'%4�Vq�N����94��%��uz��}r��wZ�z��@
�s���2ƪ�ޢ��7�hN{{�3h؁�y�����nYQ*��n�x`8
����by���n�&Fѹv�?@2N�;*Ueo��T��m�Z�:v���L�q{��<�Xhͥ�
(�����Isn-_V�Ȣ�N�'^�����E�m¡�kk>���E^����[�50��}��_�)9;��^A~�#yէL�,��M|O����hDP�{����-������C��&�c���������'��ӣ��Z�4" ���ӞH�⁁�t�$���&��fc�:��Wڱ�ʱt����qJF�3ilk4��lf�W�V�m��f�C�)á��o��Wk����Vt�b]�߬,I'��q -II�}5�,�(��ژꊣ_h0���T؈�	�q��hS���B�GG�m���*'��d�a�/�X��dsqQD�Q���δ5�[?!�Z�	���.o���TH[L���-��n�	�w�zH5��m����@�M�^4��p��a�Xk�![K��!�k��'�]�^���Ӣ./�E��@lMQ��/d�.$PЯ���Ip�Q���S��P__�swmg����Ѳ�$|��p�O��e�Q2��0��e9|����i:N��R֯ ?���/��lg+BǾ܉_��Ҋ���'�"����h���<��u�@��G^�x���b�NP�`�3?[���ʝs��NЦh-S�8`ť%��]�
����MP�p�,��"Ħ�G�t�},��AhY�@�n#3\J�l3�W��)�'n��O�a
�+Bb�$T��٤l����g��2Bf�;f��{�S��p��]90��t}���\��"O��Q9��.6�UK���mmYw�6_;:f�� <T��.ܵ43=��ي��s,������~	WÅ���?s���S�d��_I��2=�`�s��4���L�}�dR�ޜ4	"c����v"����*��5	6�	��� ڼ_N���M�LA)0�]���@��Q�E�F�7[!2�|o�j��ީx���N5�w���A���.�����[��=�ܹD��a(�k�Q���5����~�3�ޙ]�)����{�V̑Epc�\���+���)[��d�ق�o�o�Ґ��(����ru�յ��UT����'��BCb[(|�`�=fU��l	�~f5�](-C�0Q���s3F��TS[��(�026���c�p�{�$��'%t�cf9�H��Qı]<qؿh��Vf���>R doe@��S��7��ȧ(�Q+>N�9 ��!{?�tP�{Sm�5ވl��JP�.�tX�HǋPg���Tq*�c����[?���r[0�����J��o&ݽW�B���mp���n��` M=}��@�]*6���r 5� J)['��	�% �&z]6�� "��S��P#��1�E� 'n��e9$��l��>�z��5͈bfF��mc��GV@;L�O}P��e���9~�{JٿC$~so���5*��DO���<�;��p��b�U��������`cx�.?̲c>`b�U��7�V	�e�5��:��I�|���)��Y#U��iye���m���:�8�Ծ��tۖ��ᓵ��@���Y�x~�DR�k^exq�0�J:O2�W����Wֿ?�LE�J-Ϝ�v܆�w7S _d��k�2v��?t�r7�WƼ�?&V�,��������x2�\,p���ϱf�VZ��$
+��]��o���E�U�䰘�����EIy{󴓗Zu�b[�i�_R�(F�����iy�0?����a��1�&k�[���z�w����x��|Ax���4҈Oq"�,'���
�������ú�g!+�	�T{��v�p����.���rJa�O2C��v'5/.0EG���^U$Ű��8Q7�	È��EO��f"ܑ�S���4䆇��X_�b��<E�,t��c#v�'A�*�L٬��^�v	��/jі�a=r������P�p��+�J��k���*�|��/�l��<��Q�@�����'����k��={��HݻΦHL��i�b���l��]8��Q���7�g�����-���a�`���*ŊM�"ʏs5�Jz#��d��������p��*p��4�-t����i{z���k��-˟l��=)G��v�VW(mc!�m|�G{�ݑ~��v!�+	 �����©5T��1��{�2���*��wϖ�v ۴3.�+o�K�~K����&}��d����z�sy��b"��l�4�8K�oz�Ο;{&3*��<R|�"x�U��$'|��r�M<�Q��7և-���������6-�����ru��M�M�e���hx�ٗ|� ��3���kW��c��Y�����{�Ņ���5�l1L�m������:Wt[�N�����;$=e
�-hm�%�訂��J�g�b������q��hB�_�_~��������M/H���~Է�rOj���tB
�ڽ"f���[ь4�E��3�*��F�"Ű����H��9�x�2p1����:*�\�D�O�N1_(��[�u���v�z�m{w.��� ����3��l�3)�";a���A(����#�/��(�6Y<�y�@[����`+kYgF!��:P���_����b�yK�0�9��g�-��i�>�O��k�v�y�@*-������L���(�ZZ2<)��`�x����zl�M�d/wWa�/t�Z�+	L���Es�C�G����WD�*l�Ό�;��\Id�n+�O°Vo�;��c�kj�^���fh�GXf���]��S�g�I�%X�CF����Җ�ȵa��U\�J ��P~�M��L8� �RK��`�A�K�o.����Z�LOdz�Y8��S�eo��nղb.�Z���c!�y�~�8W�L��=�(�qܣ%ڠ7�!�(�޹�Bն�Dht�t�4����B�X��F\Հf�N�9�O��]55f�%��� ,���iw庲�v3D�����P�:0.,�_��(soI��L��܁q�߉�W�f:���`<�q�ܚV2��������Ҫ7L+��9�:����5�7ӎ��*0��?Z�*T�Y� r0��c
^�zĻ���b��Ë����`��lv���Ծ�VZ�����v�	S�I4�=8�3���NޜWΊ����;�axe��NGv	YhpK�^�U}o�ޏ�>�O�����{�XH}���~ b�[,KVEO��D4	��M�u�*`���\����y0�ɷ���" 	kw@^�Tsi7�5��4g,�����uF.�
dD����HH4�6��5�l�_	`b���|%qP}g#/������з�}�,q�
���1o�Ł�n�0����rU�p�'���-��M���IG�4�	�mZ/�������^�i�6�^��B	o�A�Js��wݳ*�݆� �>\�TI��
�)��zٝ �L�q^����Ki��S��h¯z-Y�%w ���?ky�4p'SW��]M;MS�����ʿJ� ���ũ�6��/�)ʴdJ\�����Ο����հ�@Q[[ ���c�E���g��gۮ�� IH�_o��
xv-�^&��(K���|[h�A-�7�6�����:Ү����!�Ħ7���vl��T/�?�N�y��l����+����T��(�j�4�4�`=~�D��5J��=l}W\#�wˠ�ߦ�����<Qw�K�;#(��8G
�� ��)/�C��9�zrI�Z�����>𣷺��SI�`��.����V���7s�NM-�"?�e7�����+��nt� ��W����[��%�Hs״a��(B:gӓS�;�4J�v�9����ˊ�ivV?�:�ҥ��o?��%~�MTE�~ur�JW\�蕋R��En�k�9����R��v5��� �Z���'[�O�Tى>�ے<2~I1�#�'[|��b!�����"6G��8ڃC ��������?i��'`עj�(R�n댛P���^��m�w˩�8袩1�W�>��3P�ԪxD\�O�۷6:����a,��?�@8����=[r�d|X{��a5����c�����;�N�� ���:�Ní��"<�ٳ��2>�ަ�栵����C`����p��˧a��}+����Y6�(��d�/Ė�F�rꤕ���z����t�Šd�;�٩\�I!�y7�D�󁕜�丰%�<������"Iz��9��m�qVKF]7O��(���� Bh�iE65ӛ�x6JD�6����P�Y�7xٹ���n��� ��N��Q�����3W��il�;pr��Jvѵ��Iތҫ�?���amD��w�2�c�i�-�bj�䏑���v�c�[���u���k��š!�y/5�!w`\��ѣC�h���� !�T1��<>3��v�k�E"ޕdI���7k�r��O�g1!�[�P�a`�(-	�E���z[�}�2�ly	���l���;�k���vF̈́�`7m}�dDN���9�ԇQ���s8Q�pwnO�}�~)�m�FO��,so��ݿ��O�tfS�ֆG[ra� �h�]fT���)����ܙ�T�����񼳳��Τ�@|E���'
��^}����[!z�J��1��K}��D�<D)����"�����Vi�?�o
��fD��@�j���wݜ��s:�f(N�?ID�s��\l�:']��ʂyPY��R��>��	��p�芌��'.��.�  p��W�ùk�j��qvY��y&!|�ٵ7\�n�x�)��E��e؈x�9&��j$J�Is/���iuP-�	|SN��I�`RȧS.���\�Lqrr)���[cv�A.��q&����%{ߌJU-�V gB	�XY���_���7��;�ȍ��?�rhe�qr猠Z��l;d���i ���rX�^��i��сH�$��U!W2sB����1�م\���@o��%�h��ڨVu��gG)7�9麫�/e��p�@�e��֢-Ҋ׏p>�fO��Y��%v��Λ���K��dou�����+���8�
_����Np�x���	<�R��xED�%����#�8Y�&_E�>F`��H��'<x7zHv�1A�l�XCId�7*��@ ��u}}�6��2�A��n{���HC��收�[��%�ެ��~���8��s��ׁ���v��u?����3{'���/}})g�&(H`Ye���ݟ�����luҠ���_�H;��`��c���aXLT��=�Y�Ѳ�\��ٜ��>B4� �[�L f�;��e�#�v����0���ðe�xʲ���D���LG�B������_^hl[�0��E6���U�e-[Fכh�� ��"q��bU�u�B)!�v�⮶�a[K!*���0NPݬO{�)�?��'P?�(�v��T�B���R���	|W/h�)����W��z @��W!��n|�@�hK\�$�nH�5��)gCb������;� N((�^��U�a�����f؈�w��Q&D:2���=�\�����P��_��-�ͭa��(�H#��&��J�(쳞ys^f:�Ά��5�n��%	&��[�J�6�*�Ԇajs�S��h��u�	��=R̝+��-�P	�]�o6�<A�N$.��6C�謳ǖ^�am���uph̓���[`,JUQ�	�iNӔ��b([Мn(�&i�v�Ä�ȩ=`��}n�^��S*�)������z�J6q^��I��h��|&�e�Nּ�3�A�����`@��o:X�%Hev�ս�u��ѸNyD:y�~�_�|WZ��w�Ǳ���c�sT���i��G�4xXK���"}�	�d�pc�KR�V�[�GN��:��;�����vA(O|w��6�b�xAi,B�����Uwщ��:(�*d�*��wf����A�yn#Fۨ���	�bb $����±��\����B����Y��Љ��M˔Э눸Zc4��'gY���wE9l�àB��j HbNž�򦹥c5�q�Q��Zn
1%2cknN^S�ٸ,��<��^���} �?�ćb<�E̢�x�������6LAɞD�,��o=!�z�(���|n�U1��;�w�*]��<V[7 ��'H��V�
"}2�6S���2�i���wRCec��oM�0s���
?��"����|u�@�Yw����`�9]�z��]�����x�r.p}�P�N����.t�O�U��G�@L�F��l���CBs��2B�u�	���9��τ�*m�'����8�)��<c�ZRD\�4��!�U�]%D��f��y
���Z�J�(>���mo���3��F��`�k7����G}�~DB�Y#���zi���U
-�kĤ��� �:D �˓��m�e��Vj�,X��W+5P쥥x5��P�y��x>�pp�)f��3�SO�v0��
��_���3����6�}5����:,�e�@l�CH�u��3�Y�]n�OG�>/8$�(�¡s�����3��i=Ԭd���LC�|`�LH��wǑܰ��1�"�$	��e8�e�q��*�Bd�#�U�WL��Z�ߐG��R��k�	� Ԃ�O�ʛ	�7�����c/#SI�KAuoQ8f�[�9�Q�'�қ���o�ID{�
,s�E����Gg$��"M藺�Q�4,��i.J��ٲ��뢦��nݭ��.p�[�Ίx��[�f�64>4�V�|~���Ќ>�_x������T	Ҡ�ql���F����O���|t%<�s|3�������o��E��~!�#X�L@���Tŷ�LK�ͪ`r�l���N/=<BM�]s��F}{ z����i�������b�|&J-lp��f%�k�:��0�,�W�s��S�4�:��G��@�">[ix��ü���l9��~�D�ܚ���D��^�v�d��^,��B89�Fv���W?Cv��
0Z,���34r�*�V鮏�;K�3i{<'�&�\ �N�?L��ڳ�:m
��$�	M����N���ߧY�_@߳���?}���CҔ���f� �������?8GK<N�=��}T�{�6i��$f�n��G�>��m�|�$M�܂w�1���� �l�N� �y��5L|�˸�%��Cn��Shfke�10�^_�E��"����Q�`�<�W�[��:�x$G��'��d��*��H �잹R��'��Ԥ��E�sO�P��E��ZԨ�_4޲u����B �hrj�@��0&�V7�o6���̓� ee1R��
&�ѓ�P��ܳ�5�;�[^LF��� �Yv��c�"󼹃ށ���|�`�^;C2@lTct��M=F{s�9GVa�z{� �/(��sxI[(ݧ�cϔX�|�!��,W|O���l#/hz�#d/Y�uD��m&���]M*\��Er�=�0���Xn�[2tK�	��)�Tw�� hj J|��ӗ5�)�E�>͐�c�9�;��)B�����xX
���U����^�K�E�)�Dg���E8�+�H���_�5���_�4��}*|���%�����s<���Ǹ�r	�[K��fa"u��<����E$��)oˏ�ւ[3���I��c�"�[��͙Ӷ氒���|�7��3�B`x1���Si�*T�%�h��w����$�2��Rnô�BL�A��L�\~�s�6we�AQy�6|::�K��E�vﳴ��o�Gꜿ�W��ⴱr�Z*�5��0�5�l�NQQ��ٻʢ{�����od�r֦NO0�����a}��.q���$�$�d~�D��ry0��J�^G�&�M����ܱ�Ei��/8�M�[���e>m{�D3LBh�m�E.ϭ)�ndb�6.icA��|ߦ�~Kv�_�ʌK�m���R#؜��Z�q>�Z����ٳ�jC}Tj��3�c��Hy�wW����"�9�$J����k��;�R̐
�BV���j&������#���Û�!�Z�c<3����B;r Hn��~$=�Mc���J��5j�5�N0h/�`��v�0X�O2o�!<d0v����i ����ĕ�9u�ƛ�P�1F2ˠ,�����<̮��d�D%�Kӵ����$�s�^=R
N�^�u�º�n�'lհ�{��T/�,FǶ9ګܻ,\��d��*��[�q��Ny�PM�%w�%g`ins�ї(�GF�?���7��HP�E+������)��/;�_��M�|6����(��mIxr�ºO��7�/��Ť��z����Z��#\|�.��FEZ!����Xg7[b��>M^6���N����ibi-�͋|Ŭ�q����2���.�.:��8�*6+v�[��6���m�>ג�������vI���	����⤈����Ԯ��ng���1^س0�܀c&��P������=�a -���
h:��R^�jx�@�H�e�C="���YΉ9�X�sO�S��Eea�u�%�����ꕡ*���ݎ}��Sj^>퓼��
Z�THəZ1mo6~�[<z����s�J�5��d���'��9O[�m4���=��'�VS2+"?�T��y���`�${H��"��[���E��5k��q)���*)o��O_����]�o,e"$'��**�ߝC�ZI̴��0"�czQ/�5|W*�`(�VR�)��S���8-'�fm�NԶ)���Yo���On�lvL3��+P���\'���z����=2�/@3��=�mn�N�)�w�T,uiJ�G���_+��1����r�
B~a��ŀ~�����\4��ܘ�j�� ]Uw��>��ιV�/�;n�����p�ۡ[zq�藚�u�����c�C�w{ u[��A����ᐛI��w7I�e�-an�ݷ���fJ��}"��D���
�Ե	��9���=a[����4����fj�w���F4��Q��'#�c6O�Z[�c�\ZG�x��8���J�+�~�Aou�	���[�F�����ܔ��*57S.���Wt�!�������h�������jh�;&*d.�{��3I���q@A�^���!����*'��,'9�G(!S��ŋ0��j&]���,�����)_�����ZRHO5��Un��Uh-#����3����$��\�δ��p��I��n���<�Qpբ��٢��2P��3�j�y�є�2U* ��ao�j�p�Q��һHn].b?-B1�%�vdʤ�-@1K��pv����#�κ.Ug�մ�'��j-��a,�bR�.�2	9����}�[}IU�߿�Ȇ�|*B��7�G�����V�YMd3�(Zh�Y��l�.@�JW�A2$E&1#�>�x��
 C��/Q9���G�(-�7��i���>�d=�Wh� p�Iq�������?��=��>g�UAIe?O��%��۟�H��,=w��NMkQ>�|4ʼ�!�f!���������.����A;��	t]i����p4�U��¿��IQ!�`��![�ӎX@z*�Q�����^�'�����z�K�ANݏ=��Y�$S�&��f��=��	9S�CX���g_�]F�4)�ٶ�،l��?�K��1!��a�� ���FQN1ͩ
��>�H8V�]��"t
Sv�#)�Ϙ��2)�E^w�<+�k����������y�:Ly�A�$� x�cC�������N'wz��)���S	/����%m�L����Έ�"���ߨ-9)i�D ���o[ZhW�����B�)YQSl�T$t�x����d�{�t��i�-n�9d~�ě3��?�!��/�FQ�"��,���HQR��x@'�zUEܼ$T���Hx��ˇT ,�W^)�֎��6�5���oz.�о�@=4���OpoV6�4�Q� �����b~?��A>w�M�������ʲ�>���J<
�v(ϐ�t�F�]nv��^Z���X%�yv�DG���VYCx\��#��~�9�PīA������Y%����=���f��������1,��C�dz �T�	3����f��r%o
,'
uA�{��(�ѩҎ^"�db�J-D��a`~ϫn8`��8����W�l㽂��s��ܧ�j~[w�3�
�]���\3�!�ؐ�E-;�^Ã�wJ�_훢�A��/{x�=*%Ѯ������K��t��F$������ � t��@��,��C���� ,^�%����[v0V3��^ /���q�7�2�a�z���t����ȱq�,*���-n���0�K��D(��F|{�mm�Fʞ�k���H��2���E$���ˎ��mԶg���i(�?
�<��T*������*
Qcf��tv�\q|�iX$^���~tX
? ŀ�EWk�h6E 'j��Ǖ�;L�`��ޯ�e��j`��E~���}����^��%��,�eE/}R���3n�o��}y��%J4"|-z���9��πߦ_�s9l' ��b��_���=+7��.JϽ���|����?x,?[�2��LL���NoZ?L�}�x-�2r�LW�W?�%{11�qF�U��s'poJN(bO�!��.�c����I���p}�D�C�r��/{�h��'���	y��oR�qf�H`���i�0G~H��˹x�I�V���Su�I��V��N�0�����@:H��9j#@T�_�5�R��)��I�`\	���M�7�'�h��p�`~��"����9�X�y*m�v�c��2�j�K�B ?r�ʞ�����!�� �¸-�-8($�M�����қ��:���1�N$���#?�Cm���&����}��߿���n����B��*��9�%�l����D�kߒ|�Fa�K���U�|~C ���́�_�Ok�7K�f��c6A����ɥk��}���Q�@e�1|�H9�J�㢨J I +���M�+��$왧���+Mz�e�M��m�����N4�9.h7��Gx�,I'bU7&�߲u�z�rAvR��Z���D]���ۺ`���^����/$*jeA8JCK� &������p;�x�+�UB����h�jT[��Ew��`������uq��#1�8χ�vu��z��P�8X�3/.
�qR��>�Ǫ��c���n�l�O� HN����ʃ��vE���߸sm�u��L�j�������!38��&��p:_`�)��� /�CB��Z����tF+���䗓xw��qm\�k�
.�Eq�����N�8aR˱���'-ħ8(�s�b�1a�+�]�s~೽�UA*q��yi���쇜�Ȩ~�N�2�U(Y�*d(T�v�$̷��NLA(��$���y��t��2��� ���Y	Q.h`c�-��n�txX�J�*(k��ݢ#`֪��(8l���˝��&.�ډ.��ͦ�2p�̦�A��`��Ã�4,(��(U`Ӹը� �n@W��w��}wu.2t>�/���Ků��g�J[y��<#R�R�6�/���Q�[t�y]�Oe��#���{�/e��	��݄��q|{�����c�WԻ�So5��f�_Tpr[�$�|�䓮d콍�X֩&!�6Ԏ���4!�\���K�G�����,�������:� ��}T�ȯw���*o�i��������E�m��&[����C,���Z>�j�Bnp,� �_���:v����������sO����Q�C�B�!��<�;Ӆ\3_OA�r�V8�{{t�E�<��DN�{庇2��0c���-�*Q� LP�%��Ѡ��$�u@��3|�,�r�?�/�(o̓�V�0��7�M�~y���"���N��_�bZA�6L����6�� ��[�d�E�đ���uIݦj)='(�#%4ai�Fb�|6v|�W�l�sަa۽i��Y�������Y��˘�C3�#FP����~/�~�ŭt^���V�v��b]F�u6���֏��R>͊$����zۧ����E(~ͣ l���V�
��-����+����ǿ��["����qLD&i$�A���������z.��l;����ja��0ExAx��NQ~_�|,��<=����w�Z��:�_RI�c(J�x���qR1�YFg�QF�<��At�4�Ǎf�F�8Lx�a����	-����k��Вf����k<�;�-��=t��W�]u��;A�U:����1	�!'# AZ�Pn?�﨟\���6�[O� dx~fF=W����(Ŀ�5����3K��7JOw��+�;E�g�<��Cu��r��I>�tL蝂�ձ����~��& i��e��'�k��`>���,r}dn>^ |pN�w��6��԰63���p>k)xe�wo	���^�4�a �;Q\��ܢA��N���)씇�;��QvNܙa`������j�Z�qG}~�Yv��L�W�f���87��)��_I����i'��A��Ec�����ɱ�U!����=%ǚN�O:뇪l'�h5����(8|�v����׏n7�r+��iNG�bl�[�/6rx��uk��o���+o�5vuo�M��c��~�� ���	���g�\�D�S��H���n͟�Tb���"�P�V�ϫ2;�8H�*��|���풽����4��N`���	֤�@�Rѩc/�C�Gvݔ��۾qKx;{ݾ�p�;\.5(5���[��LŦh�٧.Ҁ�;a�B�.���t%�Ș�!�XI�VADл���t�M��6������C1 ̲Z�%.|��`�l���NɃd\��_˲�ަ)4�!����R.Ҿh������˫��3���V	�ih�%uʟp� ���b=y�R��������S,fE-#�"�n���8��d�q a���"�ϑVW`7(?��7�V�9ת��)�g}��/�����!��Ck�D�/&�1�vi�<���gϨ"S����2]��h!�=�"�H9��*&"�P��<z}I�^�Lf�:�%5<�������AĦ�Z�H7�H��^k��P�>��]��t�a�YXo�"
@��(��^��66�g4�[!ܐ7��Pa�A�_`�����_"W�01X��Hk����Wg�U�"�Eͭ��6e҆���W��OT���"+�~1��(
�N4��oK�"�B�7]&��_�M���I��(�OakJl%��P�nʾk �NZ:|pC�q����Vb��&�/��)������ŋuj��R���fE/0��؄\���Գ:�;��N����c��3bR����E��+����ی�!4nY{A�6al�R���:I��?TMp <�K�-���B¥`�����SR:�ۭ5�[��.�c����__����Q����R�{<*�%(S`���l�l#)x�� ����z����qQ����Z���9��	��p�/G �iC�$�Ջ�t���ͅv��b����s:���×*"���oSp��#�|qϻ�������Z���0����!���0��õ�_a�V��
Z���<�TE=���C��KM�}��$��-n}��ܵ�9�����UݚkLI����w�"�j���bƑ�ͥ
9r��Q��cT|~��E���y@^�O���?wv�0�]�����5��iޝ2�������<A)��ĩ��~�׽q�U`U����]�n�;����6)��3�X�7p��}����	�V�K��KC�wzcC��?�&��n�fVZ��B��_:�|���`���Nw����s����{hg
�z�VU w~��d+�7��!�uXVX����p�|y1�a簇�R}���W��Z����5�yT���2�	����sUI*�w蒚���|L�]2M���7���
.��p�Y��Eu�n��*4���+4j��m�=:s���q���͍Bz0�����W2�h�#��� �?��(h� �Ø���wd���|zE�a_R��P�=�N�8:L�����Ous��?^��Q��f��VR�i�!���)j]"9����?9�����?�,q.��G�k���'�����j��^�|� |��[���c�M!���C�g��(�}KfOL�>��0ꈠ��?ZG��'�y�yqG� [u�M��F��8�E~jZ����i<}o�˰�+C�f��'�7gX�Ͽ�w��aB����w��ߛ�ZRC��;S�:l:,�#JIg�E��e�����>�g�����ɝ*T�M��&��~�o�_�u$�w�SqO�:${�]sx�8�kn��p��7��kd��3Fj�(��1V;�
���U��	Ԡ�K��v�Q�˼�!�����fT E��vk,�zfg��G���ꪎB�!5 ��|��B'M��Vb+���zp?�0�;�C�c��f=D�_�p������8�"{,Q)NK��aAG��h�\�M��#D��3	����'�1�����m�^���S�b�7�` ��n�KJ�\�܈l{̒��v�M��
�������yU���� �I#��0ƪq���1]��!V,\`��7dHȧ�r<��'1�q_��0����%տ!�b)o��p��@��W����:�4�ke[��~Y�ܤ�I��l�J*��e��!� =�2)h��UgI�-ϥ,q~�sԋY|�]��/j�H�W�ݳ�R�g��D�@�	����W���.n����Ѧ�����������̝LҺ�_�@*��
��b"vo�s�	����
|�b����OuEe��&{�{��{;P�[;�r��\�vI���"���gQ�C%��o:V�n�Ŕ�O8Җ��K�pPe%L�e�ߥ���_���n�x��=.!"ߙm�Z���۱[�zk���E@�#��>~�úȔF��%
��Et�Zq{�77R�@�歘��Ğc�իٸ S}jk�W�ng���Y� +��
N&�C��Ź:�;��M�J�Cc�(	�pUY�l�B��R.�h����{�?�ȦM���)c
R)�JM}E��"`^�}]eM'�׮���g��3C ��o���!t�܄�(�*�W!(��F/H���#Y�!k�b��?��3�@�[XL�����EH񋙽��6��T)��Y=��b�c4�~�%�c7��=�
K�����������x��2�Ҕqm-1H
4��G�U2����&�"�1����ǌ�D�q����*�&Ĕ�G��_ ��t�'�o���G�М-T�D�U_�8ph<9;�Jy�=E`M��Q�-k֌�b�H���D	�v)Ɲ-�N;��Q��R���E�|2"@����yPז ]�����������\���%K�ޱ/����^�z���0�vI�7�� �Y���A���T�v����L���t�3����|ZcQ}�3g=��f���ֽ���\H�<��'URg��|F.����4�T��29�
{g\���k_$Ǉ���� Z���?� Q{qy�yc���Ii��K.S�yd_|�S4~�%�sC� e�XԐ�?,ۆ[K]1[3��)�K6w}5�������tOC�X`���.�\���#BO������8�@x�&�@�Ӱ �7�o �+�@����;��Y���T/�+f�4F���/]	�������C�ߪ�e���bޔ;[R?�|���K���1'z�n�)�FK����f� 9}/�ٍ�Z�W�#xG�C�(lI[����nz����V�p���.T��TG���9�[��@����;Y� k+�w�t�O�ݎi�А����h)\L���%H\
��A���b���G�׽���h=�2�<5�	�|���s�8\�����S�%���׿�C>�Il�U�'.>���Si6V��i}�d+�MN�z��C���n��|VF�$\b}��E*��νl��e8�Y��Ժp��#4���������T2�[�w��R��0�Oi����ݕ��� �I_�ؑz�m�x�T�SƂ�5.}��K�����)'��£�am����g+�LwH�S�N*��6��[�����q�h�(��/�Y��[o���ɂ2��R��B�EܺN�!qՀK�th|�

�[67x|�w��&� ���:W]��v��]C�x��\��"��l��?�~ER�s9���1�(�+�<m.���1qi`}e��z�DK��Z�t���Gs$'�?JC��êF��Oba�@1��r��>��,-�P��T�n�)��l9�#�
`�A��R�7��O��*�IQ��g1eש�wk�{�2�.G��>=��2���N�=}�P!R��� ��T6(/��F���9&����P�Nh�b�@1c��ؖ�䥇g=�S�����v9ͫ��Mt4�T�����58� oa�d�����#�BdۖRn���ݥ�������W��8�JD�=���������>�q���
 ���[�k�����rx��Sp�_�}jL�Vͩ�!-�L�����PBJF�s�.�C%�ᖁ��UqY��]�u"������*�37��5�LG��2��^�f�:�ۀ����!n��?0	1���߿ϟ�R��Y_��?����,d���A1'`�l�m��u�qI�R�W���h�C@��O�}��h�$�@K(׻�Q�%D��w��Tc|\�C��L�ތ^r���3���f^[0=�%��G���aP� jaнSkt6�R�P��uL�ln�Ԕ]�;��@8�9�O��»]j�#,:l���'f�W��Î����Jj /Ŀ����>��\�݈s�;�.@D��S�U�_<�����!�-�
4ݵo����C|I�n����>N -���6��z���V���C�;3�W�W��GU�fZk.��R�I�T�?s)��=��	�C%�_�ފ��:�~���]�D�_��r*H��a_���tr�QI�z�o^�*s_���_ʦ)I�/�VmA��nX�JEY}BkJ�2H���c;s\0o�f�Ԫ�v�G��qG��GԔ�e�e��@�;�*IG��>����e�����.:�-��a�#�z�����l)����D!̷�D�J��ə]I���8��\+�Ef� ���,5���)h�&��4̥�-("���b����[(;�ǔ.�p-U�N�ۏ���؛�V�=*5�B�+ �9@]��:�M�N�8�-�NkW��+�凍�d��}��Sr�g��7�}�I��=����>�Q�>42�%�V`�
��j����I۟O�`��p��h�F)Z��w���k7i�󿘃�ԗ�!kŨZ�"���^{�
=c��7��3�d����f�Zz�b��z7
��*��[�k-�(�r�J�m�8����3bɐ�ǡSQV��}%_�?����ިj��2�%Ӟp���v<7+���_� ǐ��T��e�yU�P��ԓ�F��͟�/�J�.*�;v=�S��-8ǘq�*��I��P�yo��T�;��b<�n�� ����	r����-1l�C�p��Hݬ�pPK�['��J���i��e��wW�N��#8��6��~�r�G:	��Y��� ��Q��-4��
	j�Ē��4���ADB0���i��1�E�_��?������i��q,J�3c��)�2G�����sL��ty��	HC�u�˗Ѫw��T�MF�9(��肪�!Q�����H.X�7�J`�M�A�E��K��eERS��U&Ǽ9�Py���w�c�S��T��r��g�Yp"z;�i��~I�Ŷ6w�����	���1�<�k X��;K��%Þ�<�]Nu`����x��� �l\f��J̦�H�I�!X]݂�p��ֈO�@O�!��vj�TZr�V{K�Q�I&Y��1E��+�8��A��<��R<�5�`*�b}�I[#���~�[�b*��jÂ��C�Œ��"�C�l�b�u[Qjv5��f[�NX���k|芳�k�Ŧ���B��L���GkQ� R�ҁ��AYL��(�b]~E��t0bǃQ�������5�7�1��['�j�T�I�}�y��MQ���y?x��(o��g����#F�&lR	�n�s#\���>�,�^��0�����)N-s�7U�Qi��Ͽ���~E ih�L3�M�Dm����Z�f��{���uM��@���v��(o�.�)�D!�w�֐�C��J����!���",�`؋QU���G>K;��W1{&p
��S\]i�O�&�ak鹩���}(���$Q)5�y��v�/�5�?m�,/��4�n��J�����"$��@�,�i���e�birZ��>�~�5Ӌ�,�u�f�ܫ��4��`e�I���8Es,;�	���Y3t���w�#��#G��\*��`En2&��;���G�$mB6O���c�7'}`e<��W��km<;�%�g�u��^ ��0�Ⱦ�Y
..+��d����o�� _&胥v3V��)�D1�~lwJ�,��7*L!��R7���}��E�i0v��iB��Z��E3)���{�g���Q!r�oqQ��F*	��������َ=�;
��D��I�B������B΅k2	66�ꣽ��Z����fsl7��h����K^e�d�XMβ�ƽ*�s�����Ͽ�6mPU^Op�S�S�e3�d�|�rq�p��vƭXh�ox4X*�M���R�ru5rQ,��t�5�5�4J���r�8T;���n^�
ܱ*��~KĐ�w�*U輸@zQ��O�M+(���J/�9�۝t��<���L���x���"^�r�h!�M�R��
�s`L�Ή�-!!���ba��O�n��V�8$���8�
�e��O><�oZ���o�h!46���my����{#�X1ʲ��?sh���F@k�#GT�-��� ���V��5�,�f4/�$Y�A�؆��W@W���铷X�q��J�g�}yy���]��eŌ�X�طab��k�(��i|h����H0R.2co�c�Y���0>UC�Ħ~��q�vr-^�z}7��8qq�X#�sz%h?��� �dC�q.M����L:��~Dd⣊�$� %��D���j��)���c�C}�@�QΙu"(�P� c� X�TO��+�*�q��d�t)<,�D��^�9Jl�_����V�g~:��5��bF��g�����ʍ|�b��U�5�ՉZ���9��#ٻ�ݻ1�~���B�����/e2�~iH�YԳ�5||�?-�5�G��>xb��~�{a)4�rV>��A�
P��̩�LggYT�� i�`AWb1NԚ'K�+���ʽ&{S �)[l8pD��y�oHkI���/�G�������cDԣU��eր�!��D�-�cyE����������zҵnv����4WG#ay�`m�������J�cp bh$t�Hbb쭈��5d�U��el[>��4��Q�܅;���?̶3�S\"��sU�T��s�GVM���� 
�ͮ�S?�[<O=w<zrJQ�-�>��,��*s]9,j�Bv�����3jW��%��I��{x/u9�c���'?��߾P_�}�c $�R,�8�|�[�Mv�D�$ђ�iw����/BU��}=����wh�v�.��+��U��<ˇS��;S�����E(qOE�{���U���;����4�H�Q���d�,tS(���BbyH��q
�R`����;�}4B��?��E!�Ek����&3�ү%y[�Pd�y��4�M��=�[i;h:G����̬�PCTHKRD����'�T��iF���'y�����](7�1u
`�$'EK3"�I��U�J�~�/5�3�x�f�cA;Vw�:z�`�}#$���2´i��Үx�V!����=q�����b�}��,���W��=S�p�X ڋ����ǹ-��������7e��p!
�mm��ɵw>�Jik�Z�ܦK?eƿИOV���2�h��r���F2�����p�+t���"N�4p���N' o�������k�V�$�a!���A��*
��*?����dZdF]sg>�����?$tf�,��Y���8yF�WWEj�x�N"'1��0�Ǥ7}JC��'�a��~���G�O�#� �$	��8����q~ve"@����{�e��T�Y��oMXtWS�^�qS�2_�0jQ����F�J��ܦ�(k�eZO�hKtX��\3o��@�k��?}�-54^5᪲�g�O�a�o�i�c0��� Ǆ�M,�w�*�i�y���G*�`����<�`�)i��D>Sh���Lҕ�ܔ���=����'�4� ���O ilP��V
f�*w��W1��ʫY]�hf9��K8�%��[%b����(�H���r%̶�`��p.7U�TC�q�mr�s��o�2-4X�͗�s��M���Ή򱽤B�zq�4~��K�ɴ^ �P�\%7Ŀs5z#�wS����M�!2�	�~.1�7��v��=N��8�
��O��������7,���W�XRt�3l�1KV9sM��0B�+�[�g�{��c�~^>�p�q�5��9IC%���8b��j%��iC��xҦ��2���1�s{�d�r������b�� �������������pw��"Os���{L�~kotnpV�6"��aJ.��x��\���9e�|�P���%�����8��s����w��%t��n��̚�kR���zN��CX�>�������?X_Y|8�a���]'��:�Ot"�e�9tYT���@�n=�=4z!���`�7����C��M6쭶�U�q�f��a�I������l�?��<��"D���|�=���"ş��&�*?�q(�x�C��:�U�a:�� `/��_�?�7����Tg��D��͎�E7�e�x��QC~n`*���b��*�<U� r���a�m��청�{���&7��N� QߍR�k%}Q�N�]~��N@y��s�mMBl,)~����[�I�2����6�Kn
Q��)��=�:ED�,>��7j"h-��.��J�]*Hq�\����s8,��,��O��g�ٰ�oP7����o|Vy��	\v⓸n��wٝB0�@�-K�~��*��艹4��] ���:�3���ͨ���|4PO��1�c�1"�~y�l>AvE�*g\[=|��6!�lp��-�ߐ�襦|�S��D���s ��:���~Ө{[㏠�͏Y~��+�8ǳQ+$�v�Nj��ӥ��_�ٿD�����gk���;!�5D�iU����?枃�ӄ'�MQM�탞񽄬~��Jo����vkK�������|�b���j%�Ym��^p?Ys4BP��"�0G�P1-��i.pN�%���@��b0����xD�:�AU� �.(��eں�S)U�"}1��= ��1Э��N0����l7�^���o(C�%��5k���˜�ym�y?��Y��ņ� #�h��L)O�O���J-�gR&W�k]��nu�<L���{�W�}N�1"�k7k*,�w�Ǹ@90v;�m��T`
��joy�d�zH i�얥�3�/��M"�-J̧��n���M����T����*�"�E�Ê}8+⚓���hW(]8V���^��	���C�qI�Bs�_��^f�Jm�U��jҋ�g/�o<��)����]�˿���|�S�id��&���)!�I]�WODt�ήn?�+V����ف��6BT��ѶDzF�R��3M�u��0��:Z���m��)�K�\X9��"͎m���gq��3y����.����{���⽦I�/L��E��3��6�#�U�����QJ��Z)㾜_�;��]�Cr��쓟�U��4.7�(���!��X�M��/M8��X�5f���Rs@�4������cQ�}�P" �cUО6Л�y�9zs�ӂ�&��"�I��~�>3�B�s�A.0M�t�L�bs,t����M?��~�n!�ʇ����oW�䥐�HW³x\)��^}�V��E����ݎ
��ş������f���A���˭�IL��n��m�!I*�*.	g���`^׭��gc^#-�RNj�H@F�����_VJ8�o[�e7�cD��n{�iFk��� <O��rMi��-/����LĤ�?���Q��P��;�u��k��3���
�A1'�����3�D7�)9��xG�i9q�r/6�f� ����	����κ���'���W\,t�x��� }�����g��/��Y�oH��F��bh͒hݯӲj�Y�t�Eҥ�Lä��7���/��(��3�Q��zj��3�(Ĉ��W推ݼ������ie-K �qB���ИX���!���i�SI�B�Z�o��ĭ"J�ZSE�q	������i��-B@�S7>��L̻¼�hD�j��f��"@>8p��Q0��[�NS�p�����S}"%w��y̱�H����f�}����;,�U6a_���b�gF0�����R&�~�H*0�l�|D�k7�:�:	����}7���D�"P��ۯ�(6n����I 
a   �|k6�K�C ����yI۱�g�    YZ