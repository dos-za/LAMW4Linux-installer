#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1971418583"
MD5="d44838b08a710acf2994a1c2aef303b9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23120"
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
	echo Date of packaging: Sat Jul 31 04:02:07 -03 2021
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
�7zXZ  �ִF !   �X����Z] �}��1Dd]����P�t�D�`���u�����R4ה�u����|(���䴘B~�m�9�b&�����R<͖�[�\�rf�w���ާ�s%G�YN�k	��5Pp'��^��K߿MC���T��B~�����)"��X#��a1���#��>��[�'f�O���)��s��JEjq�(p���S�f��aճ9�P���X�BB�J�V����e�Ur�!�|ϧ�=� .S�"�����Ř�V����x�çfʾIj�=�vUA�E����� :4��O�Tj�6���~�/���d�_���3��&��ʝ���k���~.�o��Ě��X]f2�R�W���i<�}�Yx'�p+����x���u�Eq�E��i���aN�̣��b1�y�.z����	�_0�q>5x_�B6�z���_%�%ׁƽ�;h"S��o�T��Ƿ�t�vx����9��s��Ԩ�j���n��f���Ғ)L#���"�$6ĉ�|y(�<_'��%�Z4i��X.���<SC������S@���{I�����r������ �ě�!&8��dR<ʶ�iB���\�7K
W6��o���l��]Y�Yg�?�*T�I++O���s��X�J��j���jF2yMp�Yb�w�SI'�^���
>4�˜��
����o�-�&UJ�8 ���&�sf$"��&��SyvOe'X��%5��,���[}�Jj�8\�'+*`��
�QH{0sJY�Wǔc+^�3Og{K�?4}�7�~�J�v��n������T���4&�^�z�:�����轤��%���~3J��՝�Fb2��hY�d���~�/��'1�W�y�߲ms��8�~� =oe�h!������<�%��f��G����}�粣������dM�ND�i�]Ыq��/��n�a�mL��8ZO;�
*�c��A�5`�^�,��|G���Y�kx��m�b��Zz
p���>��^7�����)l�����r̄�%���4+���;(��zע�*�������p12��|�(��{E
��<���k�9$hE" ˙A=J���4�S֬�H(O`P��qvL�['�!K�NB\�_S7c�A��Z~8��J��˹H��PL��L
X�ח��PJ��n�4򘴙(����4�VRO�0�[~S;�V�u����ƥ#m#�xfc�/C?D�w�Zw�������	�����N�\��qw� ��ij�:�܍���)G�n�$���8����7���m�i���?|a��U�@�� cc��ȷ>Ş�������D�Ү�
N���Ǟ�o�g�l��7�v�k[���@�b.��P6��J2l&vC���֝3^����t9���i���P|m�P��`�V���'�n/%|;Uq�!Z� e�D��%�TМ���O�L�+�p��ߩ�Y�g�I���{�x��m�c<�@V��g�n,x�J��+SC����t� ��Q�ǁ2v�[����! ¸�Y}�� �L�7��O��nP�����'5�/�.:~��������%g\1�{c:SL�hE�D�x�ף�?`��
�O���N�~x��h�����I�qq۸TX�7k�2��,���'C��i���\��"����sLd��.��m*���x���@�;[[�K�?� ��E�:n���D߄U��PS=�+gl��2?qY�H`��>�ڪ<��TJO	����`p}��rOQ��@$�F���1���z0���i��ronY�x��Zc��W�n�\@֥���'ː�Zh�Q����� ���C�Y=��c��6&��� �zgpeg�_R�ą��c&�! &���foFÎ�����L�;ͭ�_���o�R�[=���gx�<Jq�|�*�ڍ
��FF{�JǺ���[�e")�?�ge���c�6~��`a뙜�'�>�]��
���K	���$��*��q�s�Z48&0������ƥ�G����}��S�9�A3m�K룾���k�l�]B��Bb�:_�\	�4���۰}���7�6fjQP�ç>R�����J�:e�J�8����Ă��F�_tƅ��n+kkb]]�M��:��e��"Ւv=��<�Ĉ�&�<2�Q�����c��F��ڕ�<�^����q�J��y?�v�.�j�䷕:��_���I�	�,�#Cp��[BA�����\�=
j�R&q;P��(�Q�u~#�{����U�RP�v���ƛx��1���8]�Wzjv�&���j����͊���^�I~�Z���-ai�g�*%w��Mn��;���[\��tB>)�6��Fs�\rښ�/1����G��@!񣮉����B����,����+�ߐ��B�f�lW����8�)�r���i){0t�|O�p F����i�=��ᆌ�3����.UA4��$rA��Z���S���%{�S1�؛)����2"���^���8۟i��k̀�U����ۄ�_.�Oi���$����M�/�����)�!|���Ly�*��9T�5qhIV��-�]k���� [��=�51������%�����w�P���U&"qj��b��L5�S/w����暻q��T�O���� rf{L<`�ʺ)�ʹ/*3/|��g�'��S`@�<;r�]��H����c;���Q�����Vڨ:u6ݹPn�20�2c<J 1*��F_�P�R<K� #��*��&�֮�c�:��Uq�]���O�������ґ��"m��.U���p��5{�����[o���n�!�|��&J�ӛ���%)��F�{;��z��9�X�t&W�S_�۷`F�ŏ�2[T�W��[q���
1�����Kp��h��XZ ����
��]n�H������b���	y���� �4�����QJ��jH��W6s?e����^���I1��(}��z^[gn�}�S�ۮ�j}!(��.�n~9�n`�u-U��'^���*j�b�+�:祒4*,�=%�Ƃ����wY|p�N�eC���N��%f�xW�zxG� �c��3��;m/�ql���[�q1�BjO$������s���g=n�xv����\�b��@q(kV�)-3P�g�K�oCr��Z�a�c�	����`���<!*���p煮��ߕ�a�f9�J�`��gQPҡ_�
C�(��� �Z�D9ɮ�.�W�FV�.��F�}ކ��i�H����lڨ�����W�T?���
��������P�z�7��s���,���z�쟨
NA���Au���׮�6��e���Wdi�������JG��6>��_n!r����=�Ѝ�4��^�fѡ���P\���Ɵ��O�p�) �.ٷrYV���	T��eF��A�PP+��T�w���c�g��|�B�g���n�H��⍆���B��� ���$K��r1�[� ���3�<�4�f���N����`�f�B�t��H�m�4j#(w{lO/O.$ 9'�i�|2����vs���w�dE�D��w!,~/	��̠P%~��w� 
}lߟet�s�6��S�^��E�RB��3����L�
;4<ʑ�uu�2�' ͣ�*���qO{��c�An�F�\�u�t�	��ё��p8ˇ�y�0i�y��^Z�c	�)1,�i�+���)Q﫸��sT,���mfߠ�������R��)vjQ���-�ׅxSfs��C�bﴂ T�;	����׶ ��q��;�h[���a�T��w~�K�AP"�V~R&o�}R+ք����D��+�3��vk�lгa��2d��W7�]8��FO��������d[�_�c\5q���;Q|�q�_蚔��+��+�á��c |v�bh[H rZ��z�L]a��
������?�h��K�A=�e�	ɩ�@oX���!W�~<�8ǭ~�L�>::�p��v���^�s���h�oo�	�$\p�G2a�ۍ*S��$����P5�;і�������O���l�4��ǿ��5 ���=W<�\���G}�Xg�|l�L��/��/�I�=��l2���*s�l�.(�s�m���vH�������*C�5���/7ƅ��ѣQ���h��<ڂ�Q�Ȫ���N��ڢsh3;(��Z^���dd������=�>�z��O�	1z(=����i-��ek���gs3,Pq����؝U�)��"?F&�y~��T=;#R�����ei%�(P�Y�W�`$��3�-b��2��$F*�b���� ({�i�@�k|�>��U�/�a��^���ld6��2./y��k�Fx�~ǰMY���wag)��14�lj{7W`c���	�?Y��9��V�)��'E�tfh��U�����T���r�\9F��(뉌܃��� �[���F-����<M{<��v����(����VޱVզ�S���J��H+�z4�?�_Ԇ�4����{6b<K��0�Si��$B�]t59�G��� 4�,�}��Hy�K	����Yv$�h�H�f�3����^!0aO��!��,i��S-�c����N�i<L�8��$���R��K��˂r����x� �G�O����8���ũj?��w�Kc��7�%S�l��1��_��o�����ǐK�����q?L>hx�h�T[w�f���S�b��˛�2l<_�(]0YI�^1��v�؝!���*%t
�B&�|�'�t0KK�`cA�6ʒ�7J�i^5�B*b�n	�3��;�x�Á����(�0D"��GQ`q4����NnV�q����_�)�m�߭H��xpB*�Oѝ��bKtzt����%Ē�v����*�����|�������8�I�W%l�D���(ڊeR&!`�{82��|����!7�z�Pӕ�h�	)���daA��Y��z[�xq�D�Ǆs!��4J����ik>*Z=�����t���-��s�vd�/?g�2 !��+OV�]@��Z��j�'�=�:_6����$��nh�*�YS ���w]�D�S�u7� �Z�jV8�;�c����hl$Z��/� VE��"��]�h@Ml�s��X�.[0d�ޙ�L��iкMpߑ)&0�`#�5yGtl�My c(��ĻN�J%�nI)pɠ'��/���U�a#�C":�U����V|���D��/�@�GS�sj&L�SF�S'�ʫBE���w�+������YF^�~�r�G��ߕ�s�~eީ�ι=bd�:�]C?A���Ӿ�j��ɲ�0��U��H��0	�2'{-,�9��h�w�o&/��D`���q�QԿ�*����:J�AC���*7Ed�i��ā8=�����PK��Y�Q��=
MVQhJ�!�Ͳ��8�5j@T3#F����7ͩdo�N#@��zm��G��4�7*Kt'��7����W�������e���#�q�d	����y�C?|�0�|�I*��Ȇ��9y�K�i�j�"���t������1�&t�A'��;(�$�z�÷4�ǎ4w�����Z�G���/���0��6�"a�3�P�,�>�sƮ���|�2LC���!s�x����ųOO�q�c���iDp��r��\Oz��C�s���Q� �������d�����,�B��ϰ]�����XQo.n؆֔F;���`%Y�Р�q��Y#ޟ5hEZx=o��n븈_"V�+؜�ې�@�~��J��ɖkV�l�G *�Ɛc�l |�l~�=Ti����d4��h3C���\�FDsi��<j����7�i�"�B4s�U�|�9��Zf�lq��v�.�?q��9�i>^�fK[A���↹��
�G�B4X^�>4/5Q*���uݍ�����ި,��V�.��_G8���gשH�x%��*����,�ӻض���.-Tس24u8w�-{�sͶq�;r#�TU{�w�əB�F8�k?���팓�rw�Daex��.R���O/���wK��Χ�=���2SY���9��Q�;N2���֖B�0�%c�}�Ԩ�j�I�[�����y��܉gDAy��ld�c�,;�l]s�M�X���R�P�̩�GE 錘DS�`m,�U�®�r��#��{!ϔj���Dg>R����\z�r���j0^�F8k:Qv8l�ƪ1��l �q��X�+\i�ʖƭ�gl����c�l�*�о�q�y��Ja��p�����0��ES�u;�+ޭ�7" { �4#�0�'g;�@���5�N��I�j׉���%���,�S8"[97�$'�<S
h��ҷ.H<}�v��9d�ٖ�e;��"0��!n�����*�9�w�iUO Q��n��6�PM_'��_���A/R9� R�6A��2���9W�?����� �Ƅ~�Є���d�Wm~C��;
�><�)���^��I�tl˗쉷|Oٞ��L �@2�^�%(�|�O�QB'B]E񡶪�7:Ǫ�?2cyޑ�*��@cW���G�dO��1dƷ�Vb5��t�S�p�s�n��,�	�,Ӳ���0�Y/G����\�\e�K�Fa��NP9G����g���H�_#��n�������q���<*�<pk�K�J*�n �A�C��.s�آ�Z�����G�{�B���d�zufqҬ�h�9ΆS����f|����*�jD5�+����Mk��''��@C���k����X��+`Ӈ~m��딆k~ôO����/��^�p�"�,�W���7����mta��]���S���Y�d�N�~uo�v-�s���z.X�Ʌka'�G(���R�V�X���Vj���B�}�C>�b6+E�)6TO��H9�S��pJ��4}�
���.j��끖]e5����ӔH$�b�VC"+nosq8G�����5�Z���$2��$ȧG~t=Uϊ���r�u�.������-��Dŧ03�آKg�΋��ҹ�X�}%ES��]�8kZj�G����ްZ�Ԓn�9p"
�ٰ��
�T*ɳv%�752������4�4`X�9�,�mkgZ����~R�ǚ_�L�{}�B|o�� "�Q`8�A�~!I;�fj�pՏZ2a��c�t��^Q���!������Hem���h����o�}� �'�&��+�$=A�J�T�����4��,yu�޵�l���N��b˭�S�P�.6č�y�������f���������8�E\��A`숥�N?���)���/��R	AC�7�҃�N=z݃XGd����>�4=b��yV��W�b�+Y3��[L�����Z͉^Ji���3��XDtj�H�5����z�f@��$�שUO����i��M2G�Oemw���b_G�9>f^��t���h�! &��BOnEƓB�&A<���.O��ͦoC����!�|M��t�p��|
��cP�ұ]<2��h q*n,2	���|h��'$:}��"��?��l�����%JTw��ZS�\vw����h�T3�Dw6�߷�߽�5;���R&���� /ه�'��}UwR�8�Sҏ��m|ɮ�^u���Dj�I��QVnX �VԟO�"��.�����r %��S��bl�2tᅏ�*���*����ej��}��*d�Jpı6�:&��F�:3Nn�_#aŐ���s�V��p�f��pr�����/TH��A���4����m��i�s��4Ϝ��ef���/�v=�Wia]�9q�k@Eĝ����0��Ԣ�y�Q�*Mnn\
U�ö���i"N�&ƌ�=�Y�ً�v��I�>r����a��@c�m��i���)c�t|f?h���G�L�������=e�� *=�f�ڜ�+�,���� y��F�)DwGQ)�����.U��0�ھ�\��e.�W�%���Y���}�p����1ڒ�6d1(9�&�=�dz(�$Gj�6��g}dI���B���E��c�x�q��N>i�����<��q��(��� 4�A���U�h����uG������x��@�f�>>��D�HGSۍtM-J|����U91�8(���(����Q��0]O���Խ5�~n_���{ĉU��[�/o�G����f���#��K�c0�~1lm�4r|�)h�]��[<�Rzf�.�PӸd�527���� cl(;�h�І�Ķ�h�\{����֛e�)���|��蛞P��قm˷�4#/ T'p�W�掙E��F���"��U��n�״���h=s7Z4p���^��u�**��IEJ�=���2X�;�$
9֢]�����.��ިXʨ�Ѻ��Z�<���N�{�㣻`��©�k���$���c=�̙�z��s7����{%�M!TR2�ij�{�~k�P���3�!J܉��ZD'@�7һJ/���G�>�,��a��̪�� �~�<����FkU��P�ѱ�WE#���9�G�z��m'W�(t�Y�4S�H��365�WV��0�d�%�9���gz���T�f�q&���k�I�$O�a%D`�RY`��da����`�=юMD�W����L���}L#����`7>��1&�#s�F�ӻ�6{����v�ʽir�S7��[T�y���@2��0��.X���������/q���O(2����~ѯU��va�Q�����7u���d��$�!p��pE߻Y�O�@+�<��i�R����OC����	���~�,K�I@J5%�}��a(�'U_�	��t}L�a�i;A|����}�-�c:�P����.p._��B&�f��
�n�iT=���F�����V�-�5�	�c�aTy�%2�?�VÌ� �����0�>��]�@�K�E�)�تqb;�8<�,���Y�X����ɽd1�Rq��\e�1kWVИ�pXu9�F�S�ɼ�J����ǲy��QB����K�2��it�%9���]�9)�ƞB���ĳ����1��4:^��D.�,�i�@l_|7n�S�w�I��'�LW��(u��G�s��J��˨�i��`�Xn[t��v�Xͬ��~S&��C�ch?o.��M�~C���,J�`�.#C��*H�y�?N�g��^�5��*:N=W �U{ֶ���v�=<i��B�`�D{�/�����:.��7��&,�(Ӊ5�N����p�c:�/E�^˱R����mgl9;
�<��p���:��FT]�Ug��h1>�^ɛMS,zX���\�a��/�Xݓ�b�c�DGn�c1�����]dY-��]g���J�Pg���r��S�Ly�ԓ��t�Vr-�L�������V��:�46�S�e��Iޱ ��*a˅�ϲ���_��*	Y��v�YA�{�T��=/��)���x���6S/��/�g<4��5��>y#B�d��L8-�����Jj��p�6ӵ���H�<�z��s�R�	����G�i�ƛM���;������I�O�۪�O��8΅�N&'σ%*P"iO� 7�AJ����,i}׊�죶SC��������S����aU*M�V[��������Z3_��.sSp��ռU,c<$ꌚ��"�V�Y=鳭@�ic��ϣ���<��Yi�7*�(��^-.ݼ�R��m�ž���/�_�D���
^�A:�� :�\(����ڑi��/�S�ݔr�j{G�6�ۿ&pPzЇ"�i�#�g��'��D�:�m*_n�q�R�ek/�}[�E )����� �׶}w� e�!�l퓦�J�bd2I 8X|?�������G������n��~C�cn;��(�_�F��S���]��}�Øϕr�Fi\�Z�sa<5�6��P׾s�\�܍?EORM2��x-�QC�������0�<iӻ�}��َ�x��z��
�Yx֟�=U2u-t��91(������5"�8]cW�tar��jn�T�Gq$�Bk��@�i�����W�T�B|�IiQ�M�SM�����?�(��lJ	�d�%���=��~b�ɲ�e\�<_��6�H:w����R�v��J���a"�ƭmZŖ/݊�u��h2A�	�.�!�~ �B�<Kͷ���S�_�S�H���R����T1�49X
���a��S��7(��M��o��ڋ1ሐ�h��ߧ����`!����`�V���5��o�����1��A�� `�S	@h�s�}6��?��:"s�M�ь��*6T;,B.��!�."�+�S/�m]�J�YE���WOtX�omh���а$tm�������.�Keq�,��M�5C��E���B�{�����)�T�(c ���ɺPk�I�u��.�9�K66���(*�E
e1������n%<�F޹�Q��Uqd~� �m�Ʋ�0�!��߁m1��(w��4�ҷ�|�D�0YA��6�h�Nq�?��3/��:)NH� W5�-{Y�c�V[	�A�,��?B�h���o�B���d�VO%��G�kl@���b4�R�����YǢP�t���L���� ������(f瞂�������"]障��u=a����~����Y9[Mwֹ�â�_���`�s��6���S0�8x4��c���g�.�Hd��}Sn�l��j��Q빞.��#iZ*Z����9��x��m�$]�U�dt��6�>���2l!�̙����0�$o�T�hC-���M�!k���������gb�(�'���J.��<U~�A�O��|~(
���������v�\
�0KC�+�%���L�}���`�C�b��+T��Ɲtx�3%{kN�	\�.��}���RC
6��p߄e%°F��UZmZ^8
��3�:����)C�#f�'��0.��
���Sw�C���*��j��.Vv<��*�X1̰���W���xb�b�|Z#��l��kiO�t�JSh����)�[*nr5����d2�j�����{����?;W-��.Ժ�����2��7�ڍw��V>mŘ˹0���F/�a���j�x�Ah�S����Y�Y�	���)I>��=�V�jW�f�ŷ����ɲg�m�tl�W *ŝ���ф=��y� �`�h9%��_=��}�|ȍ�������eXU�$lľ�Im�j����Z�dF�'��$N*y���.\y�_1N���� z��C�٘͢=G}���=���3tVZo}|��4�F?FO�U� 5s`5�y�6;�y������3����PP�̩�}��a1k�� 4�lW<�0ç�dUD�\���꣥y�7#�R�u/Ob�)���[N��ڭ�+���$�W�}9�M�*���S��~S�6iXj�L�sav#P����R�^kZtej&����Y6q��,�B>1� ��!�C��h(�x0��(�Š�̄���>he�x��O� lfdn�����X�Ɜ�%�C9b��N?u��M"I4��78���T�#�IW�M�����,�~e֋XB��Ý�\��dm���6��������i�ۭC����*�"��.^[J�=G�(��o{B�}E~,�q�L��g�W߅�s�b��B�>	�ŖG�}�~��X�ܞ�(Ct�<3�;ѱ�M�`��+�o��뱷�ި�ƗZ�HOi���;+�(�������EIz��G�F|ޢ>��*z+�z1�}y�!��b���3�;^����#Qg�M���{T*T�i�&��B���Y�И�u���w[1��蚏�oe��$��	�249�!0a�֒��[W����P�yɟ�rxPCe����-g�S����p'���dq��FlYu�pX����5��	�����w���9��3�����p���Q/���{e��<?����[>�?��J���u
��
����V�.v$1���5�#C����Ma�N*��6����Y�+\\ 'u�t0$���%W����"A3��`��Lnw��\wg��4#���zI�����>��2~����h�a���KE���1��o�E��`D���L��K�w�3��aI�����Th_����5�*r��SQ�.��M�f���vM�����偆�W_ݪ.�L�4"m��P�BQ�L��\� ���A����������J���ֲ��#L3����q�E(�E�'O���ߺ��Sg&�"��	kAEԐ[�m�>9Yλ*bנL?���~�jK�O���jEާ�]I�~������)�#��oХ��,�g3�D��`����&��s,�"�<>� �r��OMZ�'4���[d�:�����+�s�����б��(y6GS��7*� �~����U�=�?�O�C/t7_��d`��.�g��$gF���Dڅ��rvR����fPd$�y/��K!�d1�$
����=c�pt��4p�Y�����L.85D�o��{���k*�~�q��q�O6�~��ު|�pa�o�ar��ANQof����6$���`�t�H3{��ǰ�i�frΞW�Þ;���ƿ���D�F�ޜ�il<h��s����Dq x#Uzyp"�&ED;+���7M�ynE�? 2�!��8)�3ЪM=��~��6(����l|����+|gH�9|���b������dJfN(4Ӭ�!	���
�^��W�M�~�p�=��TA��*'(.Rr}�{'�1~��=!;��������r��	�m�>H����fZe����q�_���b�";�ă��AQ�I��h���5���.���Wb�e���v{O������p<�ɃP�` �<LF�xt�7�ױv�۟��GSG�8��y�s�Q/�]�:�:?�/EjG�� #.�h6R�X$Gt'ښ ��ȱ��MU�/�2�z'ǳF|S����9���^I ۺ����X�ۂ{"����u|��=�r�_(������	z�i�^h���:���?o�)`%:_��~b�莚l����7.�����;6��;�Ҩc���M\,$B~��Z6��X���J+�Tw���aq��,ϟ��gYg����gh�8 ;E� |a
؂���N�`����{���kj�{���?}��e�o,F��O��D��J��M!��父P��戊�G��s?�>���ڂ9%)_�R�%)��uֺݞ���)�n4?‐���:�p�-��R=&�h��	������n����2Zi[���D]'R�J�x�/e&�V�Np0�ٳ���5��;��vO����U�["3/���ć!;.Lz��O���-�&FpI��$����bA,�-�~�)�����p*��W���g���7������6�|��z&�NѮ������ IxW�@���
�6�� �[�x��u�'zF��5�ĩmȑ�=��J�K�\�!�ppx��V0�zA����Y�pi����}��:����{Eۓ����%%ޣ��wN�M�E�Q`k�G�zݪ#s���kq��~�JmXr�G����9����>yG�VK�;���)�}��'�	p߬#����;��[�F�L�K�,F2i}vn{��RXg��8��3A�L=�R,�b:�h4u&���<���"���LEs���~����IwD���ԅAG(�М}���O�S���@.c�{v��[�y)��~�����$�¡?I��"�m?�[w��b�ȭ�: w�719�]@����џ������h��8~�I1����!Z3%�؜�y2y.(1�N%��x���Jh�e��Nt��QcZ�> �W1�S�A�桼H|����C�D�F�Ō\�h�D�m)�F��٩*H���9s=<,����
��w�Ǝ �׸����j!�x�l�;�e��e��RJp[ �l��þ�X��C5m��n8� �Sn���h���懍:���-���8��!�G�b��8/�~���NIލ?���Z�gTy#�8�]��ah�^4
��P!o���{�a���+Ct�J�p�ХG=l<�� n���'A�j!z7za(f�����e�v�й1��Us�I�x4x��R�r��� a��)f�8�=Ԓ��Ci�;����қz6 ���	�p�dNdT�͞��4�4�~~��Е��� u�/N����3�y1�w����9b�ozxh�X�G���KQ��X#p�L��;� ��f�����m��	���+MdU'+���A?��^h���긑A� V�`_���^�u�h�k�C�@H�7,>xpS�Q���[=�-Hg�� u��c�7*��AѬ�H�2��>��x��+ :�	�B�b��%@e�n�}UR���BŃU����r���裰��=�xkכ�����n|�p�����i�D�,��,UHw�ͱN��L%l!&��9퇻`[�5���g�w�v�M�T����x�26�F�m��N��F>��*����MM�J<�+dAC�:���� W�g�/��x�48w��W�b�۠�?2��Rڙ�M�5��&ԕo�"�[]Zn
�\\� �+�Q��
3����fYAT%��õv��Us��H
%���^���g�2[����5M�$=2��hh@q���r��ێGK�t,;Cd齖�ñ�E�W�dB�5�3��i�>�#
ˏ�}�YQ�ń��v�BN�t$��!0��Nfs�x2Hp�a w��h��EV[����5�>��L�=��4/�7��z�ٷG���-�Q��E6@z���W�Ig���YS�ش\��.�vhN�-�r���}>b�9�����������n/B���Vұ������Y�K�1�*1�z��~7�Jd]�M��;��\\ƞ���~0���w�B�X�zo�ٌ��B�_�{��q٢����q}T�*N�n�Awҋp�?�hM�<R�"�B��0]��QrЉ�mt=��D4�� ;y�R�|���}o��'ŜM�RdZ��u�ߞ�cH��m۸}�j=f�B����Z��d�Z�Zǧ�ĊC�նy�eaw���KAA)�N�)�#������"2��XU��������-`���=C��߳Ƚ=�p���m+�56���L�,-;DC�57 �z��4�B�H��JK���4�+�F���tB�
O�0��_L3-u����v�~��쵨/�7�M;I�J�P������.��E������WZ�tz�)֪O-B����0)����˻7D�ұ���h@�ۉ����zT��Z���2��n �ڭF��$4\���:�J�g0O��P����I��,�l��ʂ��;�@��M��,�v\T�~�ǘ�F�v:�A�z����@)�
��)QȦ���y)8ۢ�@W�h��X'J)1O#��/�)(!ql�=��:`��Y
�8���4�y|�5����2#��}����f>/����jV➭��@�9��Yeב��V��2�H}������`� z��{zK~�*p�,C�~B�LX���&�ܛ�)+�Xӂ��2Q�Z�2/*OE��0�(ҁ��\hR�PRM������h��{����P:ch�P�5�W�)tKL�	��t��7�^ �4aUlYd
k�Y�� ���C��/s7���>5�,˜��!_ Kmܓ/Q'�/��z"R)�d�˒�tö�(�Mx�~8���TN���0�h%e��-+h��
p_�I��*-�*gh���L�(�L�c�W``��ً��~J@I��8�����cw7l%�h6��d<<�����C�j�,o�X�K�3�2:g�WS5,��77 U�1Uס16��53^��K<���z�"���.]��5�[�J�iI?�;e����=���\V1�=j�u��本�����ѹ*���N#�6���"��̗�@�:L)s=mE�y�&RG��ߵ����L�Y�U?� ��Z�{�N�$a�a�n��m�/}�h ��J�t,�X��B��3�E�ѝ�[,H�"�-��e$�D��R���g`��INhT|6��'3)��S*?�'A�G�����;�q4�����u��O}�q�Kr�U�J_� <&;���NͅA���a�ۼEӧf	�8�#�!���}e2>��%.������i�:��,ů:a+�,�l�Pg�[L��#�_�.+�+�LIM;�e�4~���FJ>T��;	I��\��z�v3�;_�NU���3��4�u,�|�v"� �Ҟgq��&,:^��A���u��Tq֡��vS��I�+���oø�^�7��mE��-�dm��b�4����ĺ�$��p;���D�k6&L�`��.*����{�O��wU�j���a�Y�;|��5��Y��Q�zjG��yIF2Iz����iS��s;3T\�S4�'y~��(R2���t������4.Bƨ���µ6�.�� �'�������1�G���3���	��Y7FR��Xy��3�} �ː��w��\���ƍ���\5��#�>�h���z��"d(:;��2
9g|ƠL�%��[[��K����g�RD�:�f �7�����OTIh���z��zC�)!��,>���u����8�"�V����t+�(���LA��[�m��8'���lk�N��"P�,�A�l^V�3	o�7�rF��B W�"&���r�e�!�pѼ��	��8H�_=�����Q�Wlj��/��J��rF����8���(S��Uː;��(��M�jD%�^gGg���~V(U�a�=$�t<��v�_*����q�W��P���9�ȘUhvW����.�X�
5��<좦��š\;��!�G��)�wH\��L�y�h�U��5s��ջ%9�N��_�XN��dc����i��349,x(�wX�zi+J�������n�N/�K��S��DU�.Xu������ߍ�	ۗ�sI�R�w!p;ڗ�γ�g:4"?$�@��hR6�Vy���3�}�^L�lx^ D��v�EҢCk*������zJSQ�h�.�1T�&$�ʹ�����y�<z��{�X'���C_����1.��ߩ��~��mM���U)\m�h�(�=�tS������2�`�^�)%E�!x�9ڨ�0�nߔ��O|�c��:_|.9B����Gl���z@�S�ѝ�]9�a0h\I0gH�A�
��m�=�ɒ��X*cu3�Te���O��6|;9�[����_�#?���B@��%2��'��N�@�2�4Q��1�k���ف>©{jl�n�,�Z�'��h���t`��ԠH-O��Vj勑t���H�KK�+�G��m �����ײYv�i>y~��i��.��qkK���:c�(]N��2��,%@�e�W�!4e�,KjN�Mߤ�N�|�1��@гW��Zs�ͱO�h���?t����3S?I�� ��Z�"s�y@"�q������_�Psw�a˟�����ϽD`���ӎ�Q{Jj]�lD��/K��<��=��"a_^
8�l�%Or�L[��4�3ov Gzy��5*���*`m��]�Z�Þg���R+�i��h?|�
{�`ގ�b��W�g� !.RE�
��dA�mB�K'��iS�$ MO�%������`��e�i�H7r��!N�gDP���cY���%$��$b��,���t=_c�����Ъ7��+/�����]�>�Ԥ���T(�8��[5A��9}u��xzs�Xrf�A1�?�4�a�q �j���ީXM-]z���u�I�2D��`�\3�*�~)�1�Dx�,�`]��Ƣ�'�{2�>��yv�j9���9�=����#F:J����ms+_OG�����p���� �
˽p�)�b�������m[�1�+,���.ݞ�l�Cy�:���2����� =b2]�4��F�|��2�TI��
~:�K�빪��'uHU���H���ͬ�FS��,W�_�û���p7�Uإ��Y � �tRGL�a� ~��]�x����_��v�:����yǈ*���{87Bs�6���S�2�=V�1�����~��LDf��tOa(�XZ͍Wp]�
���j������q�F�i����J,l�Gzj<�-��zϪp��V~�\�-%Jn5@�	���{' ��B�eH+�:� ~6���\��,�5�d�F��\�ɥ��<5�§�R>a���W?KZ�TCv���z�s�����7�@�'�J��Yϖ^�e��V��\�l	"�֮Ayi�o�����d������˸%�}�ஐj'i��}i�Ħ\�S����}d�ɽ���JM�>Է���(j�B5l����G�I��#=���P��F��Xڰj5:�T�0*�㻞��v�Pp�~�.�:6D��1��-{��N�$BI�c���L��ϓ��N�%'��]L�P��Bv�Р�_��4O�w����y�4��4x�:�;�Lp���s�8���cP�(����X��2��d�E���<0i�P1K��r�^hs��jC���Ȗ��4�-S��JXF��n�����[�_Ŭ 0[�	T�Ov��s����Z��zz� /�E�9ݣ��KKX�X�QI:U�#@������Tԣ`B���`���Y�Q����]�ԄU��&v?^�K�M�>��jQ�+jk�U�Xs�脸��=��4?>b���!؞��:r7ۉY9d{����z&6*�����о��s��؃s���|�FCOT���^��I�0���M#'�7㨑������b�� Ww��14�A���l����z�����G��b�W��A����'����Oi%A���r|{�TM���B�ٿC)�@���n���v�ƴ�ƃ#f�r����LV�*s��[�Y���x����:��.�������3����&����L��v��C�4~itO�� ��N?�ÊG�N�ǼR�!溉��~&˶�tǸ�ǒI���;��+�t�q9U>��[V�|7� �{Sf�9����u�5���3�h*V���6cM��ר�eg2w��9���4I @+������*�J�F���S�X7l��������+�����b�^�n_Ş����m��da�'e��]�8�C�`a6D���|�V���/�~L	�7I�3�|^�v�:۔�WT�\�����<U��$.t~G��ԡFG&��z�z��d�
�s3øg�M&�%F]i2�<�^����%j�K��G��Ρr��#I��(0qAY{�]��`��L�ǣS�fQ���MH�� ���p�&�����CY[_i؝'Y�Z�$����S�3!�e&!�������6�K������o��k'|j�`L��&�Z?���4��V�lN�v���Nr�$"/�5v��#�5�ڊҎ���=gn���
�I<��2
/�ҩ6�`L��j��R����҆��Z��v/�v$(�v��:Ҏ!��]׋kh�|��d��L���	���3rD�@�����ݭ�j�;�6�Xw��"w��e�/����W�bQ�W&-�m;��N�j��-�I��h�b#n�D4���)|+x��N�Ѷ,�5s�Ww<�'W M�,
!Whz?�7O;Z�2U����=�F���I"��6;1��A;��~֬�5�Ⱥ%?$��������{�ĳ'��m��)w]���_i�����]X�0Q�8� &5�.t�4�@菿U��%����נ7���XB�<M��e���4�H���~���t��B#^��=�k���[����R���Y#'��P�!�`n�E�&	��/y	����?���IH�P�Z8ß� g���Ͷl����3���8�"�m^Β�r�gU���? ��L?�`_�z��¬O�b�iE������LRUD%Q�ڐ����w��ӭ7���B�"�Q��	iŏ���:����:!��1t0Ə�±���x{CƼp6! ��
�b�����z9i����Ȥ�4��r��Zb����ް�r���U����7nP����Pd�Q��y�}s>}�eY݌eV��U(�Exs���uE�x+?~/����%�:�=@<U�@*(wU%��}ϔ;0���Zd	�j.e/����E(���*yaꎝN�C�I%�p�H�c�����}��;�'��1�Pd�/��$k�B�G��9��ү��9~R�����'(仪���O��3�R���-����kc{Z��to�ƍ9�<����!ҫ~��7��$�E�M���]|������l�I6�J,� �#P5�z\!#w'�Ù&�Qsb.�c(�n� �o��f�?؊�=�!@��Ѝslfy�.�����XL�K�s"�뫏�4�zvoǁ�i��K�upC�g�c$���F�E�U�F�b�B[�:��������3��s�'��Ł�L�Q���F=�	9r��XO.P�I����Ω�+�y�jH"��'�E'hcv���A��<X�F�j�w�7=�0�NY�JQ��y�X�����ќ�t�_N\k���J�N�K�iI�/�.,�(.@_���H�1c�㟽�B��E��� �7zml�.G2�$ֻiY��j�iB6��
�� �~w�l�>-�� ����m��-pp29��AU�lއ�M�SG�M
�2&�]��O��_�'�W{�;��j�*p����R�]���#�e��(�{7Sq�O�E�j��S~k�mJFEN[��by��>�M�8UUS����?X�2��v{�Uv<;%�Ш����
YG�߁:�1:�&�'���f�;/�����.�B>C�1����Q�����Y~�s/JL�؆Qh���aX.��:����m0�����U�0�Qj�׮��m;b�I/6�jL�y�-�Մ�O ;����	O���Z�[ͩJ��P�K��٤�ޡ�p�&��"���&�2z��U�Nb��xe��fy�d�Wi�̰QՃ`0��V�?@~-�p����pb1�PI72Zk�#63';���f_���Cw��eP���$�:�ƺ@R9�ٶ;������SȨ�Q�LU�=U��N��љm[�s>��˽!"3��It�+d6[*p����'U�]&ذq=��ǂ�Ѭ��T��kT��s�ڲ��L���R�xm^�rSp�2�r��L�3Fк"Hc�_�S��
�Yj���N�l�"�`l��������0���;,����	�Cm��H+BQ9��Z�H0D+j�_>���z��)���ĵE3��� [N�w�`�� ä.�d�h�AeM�͂5��F���ǒ�T՟�L�Ѕ m���O�;%s0B��><$@��,��
ԍ�f�`@W��z/z w�_�7�Jꄟ����S������}c���ڇ� qX��k�2���O��]����3�!�Eh���SC�d���"+�6=��vErny�-[8�H����$�K6�.��6T+�-�΢�@�u�=��:�,+C�#w��q7&F�ȞHT!o�{�mC�O�y�,u"?�]�vR����m�w`��ګ��~[][�U8�R1�W]k���:֞*%����7���T�aKY@���� h�ڼ�h ��u{qՋ�w�eh�YΙW��5{�ԲZ����fb��Q�x����`��󇴚ػ�ۜ �RB����� +o�Q�q����@/�\$����J��)p�,Ld�Z���42�����+��syuECe���,��+�qE��li���h���O�$���B�d�ZJ_s�"����<}�D/�n���E�&ͭ&�2�J��/Gĸ�:����6�+D�ȡ2^�,XF_PWUB��>1*���c��u�`{c��1�PK5���¤x٤����9�$��_�A#u��h=�	�x9���	!� f,��3~��B�E�}�\t*r�}�=��
�R�h�[�j��;:��)P�b�e�ZB��t���;>���%ǔB�\П��KKε���j��u���'q.d��!�Ǣ��rN���m��i1��j�t\`�ys�/Rj1�5�L&�[So�Gƽ;TwD�U;c��$`	�{S��:���x���,�1v�a�w���j�P��K�K�,8nR��0�W��2�,����j��W��g��M�
<4���|����<���$��^H�j������&�қ����g���n�~ю�:h��9T���J=˂e97Ev����)�"əN�R'�-�n�+��|����1���3�I$���FU���4 YuXџ*�\���5m��x��$3z~#^z�\���>gN��эֳq~a��*��S)%ط�i����¡�^��a��3h��)��>R�ZAT�W](SƂ#� NF�c������J}�5L1��>��g4S��iCƇ��=e���>��rXE�h����gM�z�i���.��x�:;3�d��Ȳ��%El�M�Lg;�1g�
 �A�/�^$�-eS��a49l0\��w���ͺ���e���>ڍ�4A�F�U�(`G�^f㞚�[2�tf�>��ۺ�h�A�'�e��H.>����pq����[}�
��]��Kv�pGT@p٬\im��> ��d�wdX�ɔ������D&Ŏkw�Z���F���@�û�O�t��y�&D�L �����&|�A�h��-�0�3[��}Kl"v�ԙ��#����4�V�\�"�,�, ��5ڇ�.�(��zV&٘:�����^�ҩ�S�d�6E�#�� Q7�5`�:N�
��}�jӻv+icm ��&g�ARG~6��p-!�d��~�>�>�o=0d�X/��y��&�ҙ�xj�=y0��ʆ������J��bI�^�ј(�~q�A���Eg�EK��^�-�Q��*H�%�ik�U����z�b�-���'Z>���Y���m���H#~m����+5 f P
��C�E�   �7��ӎ;� ����,��Y��g�    YZ