#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4098664639"
MD5="787c11e91efa1bef19d855d6cce11cd9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23948"
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
	echo Date of packaging: Thu Sep 30 18:38:11 -03 2021
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
�7zXZ  �ִF !   �X����]K] �}��1Dd]����P�t�D�|�$QLO�j>�3���b'��3�R����g7�����X�V)�@�c[a��o����/N��}��Fq�_c^�~�z$i>?���tQ6��(�I��{
��vO�@n�v��7Mp{SF�6�(���j�P2_p�N��J�����Q���c2�V�˾�h���P��4����$��1����Mk������;����d�}9�����R;�B�O��:���_��i�"�ێ�41iU m�V�q
x���0��������E}@�`s��"��Ju�%f�T~��y�"\��`U�!l���ߥ�{
{�e��������S̷�'L �3�����9=E��$�a���=9��>�Y֩"x/vO<��%��>��SP��;V: �j��������4�yB����2W-��9�����$��J;��e ��V�1ӥ`��_k��8p���cj?�ś�X��Ǜ�3+��� Ⱥ�/�9�) �2޲r�\:����l,e�5:��9nV!��A�?̰8fy	�-bl�9:h��@ŮFK��(hh�����O�{�Ĳ&�}-�ۧW1�O�9��ʏga�{:m��W�Y8�/i{ =�8̚&�X���S(���}? >���\#���L`j��ېܭײ���H�� -�p#b�H��.O� �;G�s�-`��7JAmr�m<��[^��x�5y��X�~ ��	xJz�Ԑ
��ɯ91Q�~�#�خ;S�����m�"�)�S�EN�/eଇ/�X
�-RB�[�*�5�X�pb�(�Hl2��C%���zJJ�n4%=:.�I�֟t�/�B_dW�E�6���d`�"t�3�sOr�=`�]�!�Yab�BK6|.�]3\EF2��+$D	�TL���	����i>,�	�+,�*��@4� ��t�AS���v�֡n�fQ�!�43G��sk�]{m�hNM��5B�a�P�YJ�p������#�F��O#����l>N�7��$��qqK%��T0Ɇ^�䲃
�	�@��������o2F�TJ�gq�תּ�Z�g���]N�o�Na�>��FYoI�;4�?�����Od-:���ʼ���-ٰ�D6��"�,�6ᷧ�n�C�.�D�n��	�b/�x�+T2����8��\ �Gb��fq����u��b�k���!q�D�6Ԃ��!C��[�Fd/Qs(�s^�&��'��oS3,#�U;�S�����x�
ĮK��l`�{�����L�6K"ʰg�|���9��/I�r�B�_�r0(�S���]PS�,WJQp/��vh�}���+�J粞�+f�`O��0��:cn������F�e��aM>��'	��P �My��I���G��z��[�,�;�ʢ.��0l�6+~�z~ə��#4�Jfh���d���a�����#������������6�����&PM@ʺɥ:�K���ugB�﹖���9��HMY�_�jq�6��W��fd0�NI%��Ⱦ�@��
C�U.������Vg]�R:�P֢����u�U�i8)���~�b�U\�;	�o�R�ϥ���<�0Sw��d�s�b��!U��h���_�1�O���-e4`|����y>�[�o?RH:�)Gj�QF��
RtO����z���E�zPe u~�����y�Ė�?��[�{�'���	}S�,ڴ�9ح��|{Ƹ�v�.�X� P�	�!��QoՂ�[��@$�_�^%���6VHq5ݏҝA�zm�7���voy4�l���ӑ�%`��1��Ƌ���@��P�����gHv�l2.=+�jUtS�kb4�9��gڊ�vR��P��甎�
Q���x}M�M�:�?~�m<���
`�u}�� ���s�`�#bێWq����.đ��q�!�,��MM��%��� �#F��qj���|+����Y����Y�G�K�Ҫ��y��c��d���x��X7��H�B02B>�%f4h�xo\F�`[Ս�~�^Z�ׄ�#k�^ج`��'���!���r�2d�jƖ���m!-�U���?(gɤGI�3u� k)� H�	Z��D~U���"�0�~��/a6��|I5�B�-�"��&�gpڱo��#i���V־[��h�1k#��q�S0��h[�H)�^23qݏ�>7�*޹�y]f��:����p���M{�<H����~�^�k��,����#��KOnk�-o(���3'�簰�h���E ȵԥ���h+d�ݙr��j�P1^�5��Bh�Y0p����%/������2�}r]�wʂ�j���㐺���q�Apށ��>8Ӿ*m���$��N�,�4s ��K����fM����&pe�!��S���@������99�&��d1$wѩ�h/f�>�����h�Mӛ�W�Sy`殤�W_4��v�!fs!���A����CU������[�g���9^VE�9� ���U'р
�]2�!]���ص��D��o^��
�����L(̶:x�c��`�~'ۗX;�M�(��l9�K��s�ps��ύL��u����x6M�Ǯ���s��y�z���ן�#�썐�l�%q��tA{{���a^w�,���	�L6��F��&�����Ӹ�zDq~t�f����>�6Ji��S��{-<�M��C��p���� 5~ D%_ֻM�z$��^�ɞ�!-���]�6��c��v���:�������p1S1n݆����}���K����W�&��fр���q�g��Zko�X��(��=GC�����ʻ���t>��򉻍xJ���j9	O;A�F5ܜ,T�]�Uy��p�2\�T��ȄU|h*�++:A�"��� �I�=E� �<q�J�z�6ݎ��g��4I��/u4�}Ŷ�o�Y��"8�o��+;� �9=��K�Ɏ����C3�@��D����S�8�٦*�F5ۮQ��%�Ŀ*�s�]��òS�b"`�j$������+���?u>nhG6T��?Y���;��A��G�T��
}w��bx4�]�e&�:Q�K��B�^;�yk��x��v����xn��{F��v=���:�]NOW�nsD���_�uE2�4q�*E�RE�N�Iܢ�1e��3���T=i�$7�`D�͸��:�������p� �4�k���7�;��f�Y�a-��@���ܑ���[U����k��.,⛓$�a_Vqe*��av��:;��r8�l~�/�O�^�'Fa�Ȯ�Y�2a_�_��iU�罖�0{��%�ں��?(`'Di^:�*�.�6ߕ"�ÿ���q~�woZ��[�t֝V�����/�B:N<��_�x矸U�o7sd�8^ٖ���$V' ����g7��tin,����L�i���c`�3���ro�pBƨ)���tl�V�I���K���hR�3�G���E�DxU�
v:<�0PD��B{2���+4���5�K�^�H��g}�;�����QD�͍��R�vنO�x�q��$ ��zᑌ�a�F���K�&� u��G�fr���ٛ,ȅe��Q�!�g�yB�膖�v����v}�}W�K���U%Z��,�Zp��sI�|H��	8_s�̈́9�t+K%�N����;׭ ��I�4�����me�w������pe�ȹ4A=2'������(�"���.�Uf�h��9/slT�4�8&���vs��v͚��x���d�v�BM�[�N����+�
�n��9�f����~$ �P��U�L��r�@��|�0��י�g��
�.�`��,�?ڇr�tO��%�H��Ȣ�P����r+��m ��U��J�8CcȸI3Ms~�cC�.��5�8.��8quV��A��sψ/I+��J<�p�ca��U�9��g8y��C�$[j��X	�o�c����/
s�^�ܫL Vzc��i�:c��eD�I�k)���#Ъ"�C�y���"	EF s��������&\_�@=;T�M���{�H��3�5OO���b��JP�[�+�l< tw����[����+���WI_��S�3r��%"��V���+���a����Nǽ\�ؓ�Vt��T=u�����I�)�щa��U�p�}�p'��i񙅰�p~+����|��r�!����������Į�}i��=b9)�5��(�0k(�i~xs����{�72�;g�70���%�Z���W0r>���,�s���hw&.�{��|6������=�%���e�GD������Ȩ`n}H�c6����!�O��Q'�,����8,Rs���� �-QD)ϑ���m�N�J{Y/̌^>�2���| z�u<��q�T�pF~�Rz���n@���>OW�6�!!�6	�tkMT/0�,/�m�&&C�t���L�'gM�T���B*uգ\�"�A�e���!�;\m�&���֑5iٓ^���W�耻-�j������v�&Q�^@	c�w�g5;��k�F� �<7�Q;�����qR� ��'}�ܓβ�G�x����efI: �e<��؊�^s��[�Nf0]�7�c��s�ykJ��I���x��3��	�� m�6;>�"��n�������X�	�*����m�[�=�O�kZ��K��o�?8�A���ۮA���o$�]y�qTĺ�+b�`��'�`��M�/����=��M"�]��.yy�nצ+��1ަ��|B�
Ք �3������3c����4�����&vU��3�������#i�S�_`���p�˖����̄� bn�.�G�`�̹���@�_��v������pl��֯Q&|y�od��l�d����y :��'��XZ�����LFn �@7�oFO����t��R<�t�zvc5�A�͂s�̀���6v����L��y�$�	8�ǒF1F�dU�2��2xq!޻��X)��_t�
8��-�k�L��z'�G!��l1�>�3.�P����M%�c��ą���m�Y� ���A��8ꓤ58Z۱kٍ�P0#��	6x���/�&]�]�P�E ��^��7������M��3�OWĠ���$������Fɱ{%K�D���N/�x����x�~1��AEگ(\B̜�rev�N�DR
:�J��5*���41�e^��Y�� "����c`}��h}�7w<��N������0E�e<E��Э��?�S��8X�.��4��V�����ݿU�y�*���}W�]X�&�0�W]x��
8W�2��Q_cS��(�e}D�|s);�?l����v�=�g���D��s���U�X�:��i� ��Y`�b��J%���PS-���J�(X�s<{ٗ�j�ޣn�}��3,��@�!@�TR��&#�	ֻ�;19�����|��]��J�1��g�%	�Yl�__�=��נ�y餠�\�.�p�Z�ں�uNP�,D|���C�4�%G����'��w_?��C &*n&1�����f̩��ޙ�x�구�o+wJ���ttA��nP�	!��k*>l�XX�N��
8�
�ÚGT����ם�!�V���/�S4�'����k�s2�L�S���Y��c��8Xk��:N#�$-���緃Ӟ� �gg��bD����_�+\̀ք��OV�\�T�����Kܐ���CuT�:V+�`�9����c��ӆ��\cr ���KԂ�4���T��o��0�X����K��v�&X�5�N�>��(Nk�u�Qs�4O;��bT���<�̉�+1ⷅl��-��YP1[��Z�K8���,� ����`�CZ���U�XK��E׿��Y�~��Ql��,B9�G\ś���x�����oC��A��:�̽'V����1i�@ڰ����=6�	��{�q���gM�_i?߬g��<�f��4�0'l�t�Ē�z�*W�,x�����Gx#;51���	΋C���}�`S8�~Y&U�
�L��>�Z����L@���z�Z�g���G����*�����ܑ�19U

�nƹ�6���R .�'���a2߭�r�k�n�؛�d<��vf��!��UʌS��7�>���w����)�
�.�+Ij|,��E���z#�8u0���c��
� U��h�@eV@kɖk`���I���DP�R�ޕ����52��ڍNܮC�K��Qڏ��7����
��D]��jiv�����aA�#6�<�%���X)}�[t�T	Mʎ��y\����e�h"�e͍G1�|V�y�I)�@����E��{���S(���f3����I~EK$)�tT�Ϻ�ztc�ܥY�{Q��(?ۺ�t����V�.?1C ���,_7�����	�͡��r�����$�X�]�q(��!��1�R#Hl��J���w�5�:����4�8��L'�ݕ�S����Lb-fj��8����\Է��X��!V>P�&I-���������8�����*5�{#����p�K?'GW�X�� �}*FV~�^����D���c��l��8����\zS�iw�c|�T�'����@����x��#7�"�Z-:�{E#�*��;��W���Rֲ��"|wE�`������h]��@T�_n����S1VP��1�~��R�z�)�\H`�]����og������E57��8-�} /	�X-�����b$����)����_�>Z���$ʧ
�:UGO�pD]ob�!���>(>���}�d�&x�0��4�+@g��q��XJ�"ޠos:��b)�o�����G?$f�a�����ITh�"�����j8c��n��Y�/����=ʻ��5����!� �9�Z�gh"���s\�������Q�?8ՖO�a�����L�����3R�E��^M�j�A��n�-���n��[��:��&��PV��&. ��x�����94��z���?{t85���=�ju뼭+���X��BE������u����+��1'ѥ6p�^����D����Gfv��=��x���)�������!N��Z���[l�b�̅%�Xѭ�3�[�;�݂��^���^���ϕ��*��2��5�a��W�y �J)��Q����5��ݘ�sֵ�{#,u�P�H��S:oXo�7�����:������.3g��I|��A}��&�	�J��A�W�e�D`�"�#_5MۄR��p��1� n`Q�"��o��ހZ6�X@�S#���"�nSw	�|uaC��J���iv|�/w�`ZV�oO4%By����,k���ÞSj w^D�nv�&��&t�J$eD:�*�WT�f���O*��A?�'ݹg�J5��vg��YB�4�s�x:BI���߁�/jݸ]d�E���YW��N;���3u-ф��4e@��i��k;+�!���]<x��w�K��v�1�]�U���f�d����`_bʳx%�� �#��4�r+s�`|Ny/n��K �s�߮�I��y�[������+�4rNf[;` 
u�����<�;�����f`�ǹ�?��ny:L�g�&�L�9���/1�>ƭ����H�{[�p��phQ-;>;� g|0��'�	����4z�����O4"��:Mz;|3[�\�qo|5�$٢���l�AK�z�]'��h�!ާ�{�����r��O��]��Q,~&q9n%�{� ��%9��{;�+�2?-�qk�wc�\UQ� %����ɰ���(�����_B��M ��Ed�_�5�@�9m�(y��g$��:�
7sucz�tMG�Ը`\���E�8��AG�1s��:�5{,^J�� ���vȌ����p$�Z�e��� ���
���
z��S}�÷��Ґ�aH�!Qz�b:<�D]�o�Z
�xF��]R��x����Ѯ��t�'I�r��\
1@��C8B��q�|����kmr���o��
7ۥk�9y�w�i$���٣���F/����%�!+��3!�t��^��55�jM85�ȕ�m�H�L�.B򽶃������dL�E]j�6�:V�UV>�c�m���\���y��J�)gS��A��a�r���q�|Q )T�Ⱥ�H�G̮�]M�� 8�C�HW0�M�<�+!hm,�Db�ݩBr�����N r���Ћ�$#jB{?��r�t��i�XҺ9���o x��4��0$�n�6����	�J�Q�4�!�#���8`*V�Ж.O�;�ޝ��4� ���)��������}�)"�G�I&O��H$�͆ڸI�	W�Bc�f�Y[C�ױ�c~r�#��2�F��<:ظ��Л�D�zY�=��x)�9*��EjmR�"�{�Nb�2�_;�� ݹ8S"�\*�����Q���j��3Px8�p�J1��a�81��-�� j��3��na<�s�����]ހ􆢻�<w+��g�p��Te c�e�[��3�䆰���ע��l��j`10�퍰�\h%����a<�.�9���ag�J͂^���"D[��վ��-�g2����;|��r��cυ[;�K�K+�_�Z�4�	/j��"����L�h�mvm�ƂQs�I�I�R��߷.� �7�6k?a���A8�2����O&٤E�����:�{b$��
<R�9�*ς��q��|�x4�3�mJ1���;�?�̸�M����P����SCHJ����hB�������%G��S���-�B�P���.#��_��	�Zy�FOJ�u5V�ws��M5h��f�L�U��G���{�2��҂N:��)��J�'���[�mf�k�
��pi���duK4�݁;�U�cb��Vg晳Y��)�]T
�﫹t28<u�f��t��2e)�se�wh�TŃC�`6�A0����([�����y���(����S��q��O� ����(�Mf�a���$�$�L���f�<ԛ����א�זS��g4n�Q!)r�(b͛#���hU稫N hB�Z�T[�#+2.B��"�lU�"�����M��^b���զ����2E��
/�0Cr�k섛�U���t��F�a��-��6޻���u�O����x�ˉQ�#W��{�\lF|2m�w�# ��Ċp���c�,�A��H��n��4�h���~�v���.� �t�����������y#�������������ɀ�;��h��~��M܈��\�vJ%i�N/�`5)�Y�M�~}�@�m���&�e�<#@ȓS!"6���/+�gR�$MS���t���s�8�GT2/\t��o��Jh��f\�,���oG
��e�q4c�װ���+(��3����t|���x%�Lϧ�bTC�j$�>��E �oȖ���c�h���u�x63���pMN4O�k�5Bt�@'��@D@YD
���R�}s�)=+�Y����t,%�ݟJ��B�"ǵ�X��M�
��M��M��~Ybu���:|��_ӿ�잂���4�{ޛñPB���b���CĲ#�Ǡ]��tn�mNt(�z�$2�����Z���k�ŭ&����^��H ��ppY�R����Z����5�e�� "�ȵ��>t�oU�t�q��ܥ����n�s��wI��$,M�ۑ�xG�Pرn� �y�!��S�A&�ݞ}l_�%����d(�+}�R�gku��A"���ܻV0|��KQ�
��2q��E�)u�0�/��eDQ�����Ry���+��u��US%��j>�d�@A ߞ긅����>@�)��r!�py1�_Ǚ�Q���O��Fh�'�������C�E�0���Z�N�����H�����$݇�Qpq�o��$���	�n o�[�-���\�Ai�T�M}{A�H��6�?\�
4��&
�W�抄9����j���L�K5[��@��%��d�R�՗i�R�#WK�J6�Yͼ_B �0qa{�d��5>��[������/�H��$���Q�m��F��q�;2l��\bA�WmX�=ܨ�t|Y��o�i�t�1�Ո�`$v^g&yf*�l�HXoW��#Q�?���z�];V�	�\�[P<�zG�*g����5Аm�W�SO���}���j<5�{�eM�ZU����qpO?AC��,���U7�3 	�;vQ��K��-�������J�'���{�	����b��_v�/��W:���S�ci�{�&O����E�i��Ѣ�q���]"l̦.���o0/@ܽy\o~~�]c�9��&i�\��1И�����'���5�)u�/���l�=�W���T�J<��}#$Y��րQ�*����C�]f�������� #�_9S�I��}�ꋌ�Ӏ�us�52]��������ٽY�h�QSm�m����Á�����zm/��~-ds���=AL�Al9�&X�Se��@�}�K���S�E�b��&��H X�mS�ϧr���y#��>C>G8��"R��Q)Brs(�H_�LW����)�̐\Wf����)ɇ}5*�7�1���q�>���t�4��䋹O�Ty*��7I(R�����4��`ض,��T����)o�%��c�v]��Gpi�0BL3W��Hj�6����1��1ų���w������@5)=m'�����-��uRr���,J�n�R����4�d�3���d������si[�t��Q�!}5;��364���b��f��J��2��r��4EN�M;���Pҫ�*��B�m�_r�D�Tl ��Y�L��qU���x����-���!�|�{^����}��甴���E��d��fޛl.��]�	�
� F���N?=8	�{v�>6�#:��Le�o�9��f�tnddc�ɕ����
?C�eI���D`��*j��{�j���X�s��9"�)��i|�_��.v>�gN;�ΰ�*w�ff0j�=6����E���ى���T9sn�2S[73��gV��_��r��/Y]��hrM"����g�`Uf\�(����C�G�����M�Iy:��B����Ϸ@��ȩ�x�|�w��$�E�=g �jI���j���(�mcj�q�)�9�y�"f6��6����I�9�@\␐�U0���Zj4�8�d�-�e#t�<d;��ԯ i�����σ���pu�V����˼-��(�������j'X�����Ｇb�s(� �28�����-�Ӫ�}gP��xRo�>?�7��''f}xa.�*U�Tp䫗\T��Nݺr��g��\��Ǜ���n��~�TCR�^u��p݀HV��$�jI.�f�x�Z�|&!A�O#]�5-N6�;��o`�k�J�����r��a��o�����6�;%�x���k:mz��l[�v��v����(d�͕o��˽OO���A����#�3�	�aY�-R�SS���n�K���Z�vwF��&��r�¡�b^�M
��d4gxK�����û=p��t��]�Ė]G�L.�ح0.���K�f��5�K@��N�BH�?�ՌZ��lY�3n�<
O���1�g��B�^[��MP�	��ԧ��F]%���D.# ��ݔ�r�)G5~�N�q�������L����V�K�wQ���}�lA�%�m��Y�������((�ҹ���ظ�ȪA�SL��K�1���KZ���q�Lȿ���ۉ!��L��N	aA,�_�֖����)���77(���!�����EB���G���G�-r/�<]g�ױ��f����j�����@Jϯm����z���-a�q"g����k<h��t�����8T�����Gwn�e��E��d4F�E҉��sWo#~B�N|���I���8�Ks��ЀR��0�<ZAt��Ȇ�^=^Q�����q�3hW��B\���+E� Ac�J���|�J�����[Ķ�(MfTf	|]x_bm�4%Ud�$�sp�~���=uI�hy�b�%5;݊�=}KLVm��4]����SV�R�v�B{�~p^�M�����A=�U�
�����ʅl�rWԮ���ǽᥜHM&n��goN�4J�m���<-lv����(�U!��͢�0��}Z^��i�F�x�顇�=�Y����h�BJ7%ӛ\@���?� �I�H��e��Y�3�w�cɂ�-d�f��Hs�S -�!�=�+���B�[�I�Ɖݮ�H�]Mٙʘ�~9(<�޳��St3���Jڷ�����F���*��[�P��`�qB{�C��}]-<Y��<gX/�#K���?�n�-���u��	h~�?}��>��<�%QڪRނ���[� 3&h�S����e�K�>/���*�G�P`(���՟z��L́�(=�ԩ���r�������5x��!,k)B���`�DF4��}7�Z������i2\��0嚕�Y�n�]����s9@�힞�0� ����B/��Ŭh	<D�_�X4�㙽���>r����{�5j�П<?}8�C��14��dD����༓D(�m�#dK�Mk�n�_ik7t9�z�W��ҝ�
X֍\S3����A�����R�%˲���8�g�7�5�J��"�r-����]�T0T�us��:!a߰
���i,��V�f���fO���H�rğ����{}E���"4�@�(�K�sαp��FW��M�Y���x��~f<e�vo��-�~S��v�Ԯ�(L�;A��)�|���,�R�I���W)D(D����-#.8S�u�J���ʉO�u:t�)��E`����5�]7��"y&-�E`���)�x�*�Yoŧ5��S�"nE�.�7�W�H³�Hx
]�x�́�>k�.�7>D`�_]+��^Qb�����g�M&�P�:�k��IH��,�o��5[F<�V���:�Kl��y��f�9B�N<�呂0�}�E!g���<ak�A�̧ p��hA{��C!ΐĦG�
tՕ�@~Y%�\��ww�c�^�$�Maެ�A9�%��[W��{T<��*��2X�S�4o�$s���f���d9��Rm����UDr��:�r�F9�����p�>[Ɲat�94�l�6�-�?]i����hX�Z���#xD��7r�&�V�3��>kY��}�+��b)Yl_OK�;}]1��'���(����mO�-��rf����*I�8��W�%Jx=4C�f<_�Qg���m�赓�Ȥ�P������zc�W&��R�ZS�H�����P�u���8�v�����Ft��n��?'?0�Yxex�QɽF�]�ܜf������F�'5�l�n�yu��x����u����A�LK��`���Z�dM�1��esR�p�9��s*VJ���۳#/�Dw�ݪ�0��q4�*�b��U+��T+x��&[L�e;Yb�.������<$��C{��ª�M�w�{4��,���J ����S�T�F����qiwO���,n@ȵ˺���xξ)�M�>�P�A/�%t���O��Ծ�&���0����W�}p%�x'3-���)��s�D^X�"@�'aҧ�n(仫�aв�p���jd��WqԌ���K���W�C�qT%�=Ugb���U������ ����`�W�?�Ru�w��M��'DNC�52K�h�Ύ�`�t���~��M�eO��?�n���g����g�����Y${������x������g�|K�s� %[�SX���2��I��z)���w�1(+��Җ0�>́�ݬ��	��G����>�)�D�2��?�͔o�z2�E0��S�7�{�J��)��	��EՂ�)��%ֺ�Йu�y�]U���ϑ�X���=>U}/��*�G�i�2�x� :� �}��u�U &ܝ=.ȼ3�]�f��,�6��Pd��[OQM�����jon���[ή��[�����ZV,�X�~L�w5JM.w���Mܮ	L-���m���h<qnׁ@�@uD�R�/tH�F�ӱ*���M7�|�5f��a)2B��	Gu1
�����X̹�O3�|�@w��v��K��ȳ����Q�v��^�Yb�ڤ'��S�+��"������������Ǫ7���[��s�	���"�u����v\��?xM~�9�{#�*�c�Q�g�d�_ �n��-�G'�jR���9����P�J�m�!A��or�K��"W�T@�Xk^�A����y�DB�n�kn�:q�yj�$��}�hh����v!���j �;@l��.\�`Z�kAH?�43=gFwf�dkk~���~A�(Aj�M���ѪMh���������ThR>���m;b����i�[�*��L5"�ۚ��zL?;�;�:������GO/D5��Z;á�ƈ�gB�����ˊ�<�wO��oi��w�����l�cʐ�X��1��M��he@���{��<K��]X��#iY�<��a��0�[]I��V�  io��ZY�����Ы��p�� �]kx|�m����L��v�e[�c��������#��0l詹pl�>�O����?�u}��M��yk�x��(���V��0��(�tƞ��m�eo�OdNP��췂4H��b6Bvg+��ЀH���x��Y�{��"�`��\|OP�2tD�泦w�e�8��1�Z �W�#���c�v�t���YP=i�>2g���|��F�x�Ĉ��44��;��UM��l���L}������|��E/ �G�h��ӄnOx��f�/gaM�u�7����;��ݞ�/y!W����4/e�^p��V$I�%+��� ^�/���3A�{}�9]�I5$�]�v��3��=D�[�IM�Z��r��ڳ���!��m>.�?��*�i8PJ�0,$�}Ѕ���+�(ꋚ�o�BH�xg�ajS��(�e����d'�2��h۵9i�U�7kj�KG�'����/ݲ���e!�F���6Y.h ���
�5�L�Rמ�	i�(N�'�=�|1���[�Xq�#��U����zA�AVQχb+0�q0H f�)�95���� &kC7Di����H �Z�J�8���7+0Ѡ�� 8ۮ嚲BbI0�����3���V��+���b������b`ebZRA�}SS�i]w�6�P���;\���a��hEݒ2v��U�8�ۡ������j��o��3<Dq~x��^ANˇ�	t��5��P�,��#r3G�ƴ�koy�E�:w��0I��o�HN{�h��� �@��JQT��1�
���C\]¯�J�Tvڶ�����������΍sV+� ����a7��38�T���N�m6.q�����wր,�&�b�ώZ��722n/S����3�-�L�Q����j�_M��ʓfιEO��T������O7hQN1W$_y�	w�M� �<#~'^�,���`�s��c4�J�">%�9r$�Y/�%'h�pS�����L�Q;�,��𑏀��Q$��T3��iR�l�G���H�8LKw����zUT�|����,��)ue�k'�B �
KY��sɽ\Z��w�$Ƽ+��}�����Ȗe4!`�b�~����?�O�pY���e�k�-K�K����9��X�7���N��<a&��}ܣ�r����;rY$eվ%��C���q2{�V�p�'��Js.X����u|R���)�)9�7]	Q��/jew���H��k���@�0)��M�9���Nv��//T�r��^#�k�	~IH"?��c-(��8&�nS\*�����c�|SS�,U���R���������Y	'=�J?+ZM}:��vE4�t�Q8yd�O��	5a���]誘���u�iG����;���9	���ɨ���q��!�
ud/ ��Y� �<��+0�h��R��+��鸀'�����I@�ݱ@�뼷�(�B#��rK���v��/�rNJ��YA]�w�@zF^���@�5����ۜcGE#����3`2/BRlYc�����b�;핵����Ġ�.d8'k�(>SW�H2��h�XD%�򶥺$�P��PFe�yK��Dߕ��iI��[�s3C�|4U����jF[�I��ؖl)߁ȇ�)�[��!�����c���>ȹn�Ԉ>;��~�4�x�|d��b K�#�m�z�A`����Z�~Nۃ�3p�ضz��ߨr��t�iA��_���v�<'�k@�����W�v}�U��R)��
JJ�4;!��w'%Nf��E�Z4;}��pI� H�4��1���������U��I��Z�J9;�)�ֆ���3q-֙~Ϡ�W֠�DY��u�ب�z�ʐޱ�/�+�q�E��Xy�#<�4���/'���𻰁ӈ�3��D�_�.��#6�s,�t�H\?k���ofb�[H�_S�[��u� ��c�!�>�| J���p�ҪB�H|�V������p馊���}�l��(W+N��]�(�u��}���%�կ����]��HM��lo���u�
T8�C!s�Zs6j#�1޼3+!��hh�d8gI���>J&Ӎ[2{��;�+�LM.������s8H���-�]� ��IX��h����˜!�6�T��+�re3�f��X���'���A���-nQb5q.��Ka�9 ���&@�J����������� Px��a�F��5h��,:�w���M`��W4zNS�x�_R#;W�RƵ9��zE��ܗ���Qf�c�i/����r�8�`}�ξ	���/���{C���p�!F�
K��{j;�Y�OC<�Э��L�E>p���IE9 ���@x�b!�>�m8�	�WvK��l}��arɞ\�]��w�Y���^6�4�#`����ց�+\KTF��������ڵ��|����FT�#�=�Z��re�=`��l9G���|��ay�mi=���:?~��#�B�^��S����,sTf��[T?)A��G_�jf�|�OUÀݳ��G��p@'��*�1�&��=[�Za�8g
�i8���I#~\;���z�b��W��ӿn8�9��9~��#�^�}ɲ�_�8ڭ�����Qޞ�mIL-�O$�t"�)�����}�A,)�3��h	ƶ7�f]@5��I��3�g�!P�1~D�6����UP�*!�Bl4d�~�!Bw���VE��jY!N��-��q�"-����EO	:�})�/ϡWVm��	#�b��+���/��$�%�
�G�JP&�7�pC1Z\��(8�s���$/�a��/�*PP�u@����cZD��\x��)�G���W��]��u~�A?���S(�*�.�l�@!�V�8(DP�VV�T�*'<�/���z#��Ua�:�(`�P{���9fh�Đ�a�����ܳ��?`�tvYM�s��(${2D���;i��@.&�6��[Z��4���c+%����y����%�y��ߔ<���.�x��j�1-��5�W��m�r4L7'���������y���h�����H:�퀙����
�Լ1*۰Z���Ksd�b��z���u%z+��^�Gr|X�,�Q�5P>�����T�y�&�͈�|����W޾.Wvx��d=��d�
w���@�y����NX�Sc�^�5Vza�D�}�P���7��CS�sK��4���=|����%�<�i�����*�w��y[���~e�#&T�H,l1��fO��	����twVO��I�h���bha$T&a,;�x)9)f2Sj����J�{;��bB���S���c�Cj�q� 6�3?�v�X7 ���R$�D��4�k!+zp�Yt7��rf9�9Cj��v�̜�u��ת��Z�\:{<�E�3�n,G0L੊��I�7ލ�Ę*��&��1K�l�6!:8�M��Ay���<?��c}����������	�q��ɟ��u�-.=(׊�^Kui���b-:�wo+ޏb�4�0�Mzl�I=�Ԩ��Wy����a�U�F�<D��@��#Zw��5)�ˀG�O����i
 x5�r��ؒKц��R^�n�6�?��jE����4�gţ����Y����O\įk)�v^��f�%D�{�92x%/��]�q���sh�HZ�;y�aR�ݳ��i��M�4SjC<���_EKP����.��{��
q�޲ ��&]�����
`�������%�"=��r����$,S�(	`�qڑ�q&�^�O5��;S���%�yC�̍�ͧt����E{A��4��N�c���"��z���Q�EF!�T�=��Z1I#�Z왙��ۉ�$t�������;x��߶Xf�&��"��P�\8�@PH��6X���=d$����4�h�(<����A1�i�`e�����t*��,����i��:�;W�¹<N�j�>�����W��Z1���D�)�,�q���Hc�^Oku���PKy@,��2^H���ǌh����ܳ���<�@�st��c]���:��}��e@H�̄��{l�����"�%
�/\9�������4�:E���c�������߅٣�alX����Z&Rs���u� �r#3C��"����� �UaR��=�M�/��^ۿ�yU2�O�Iw5ӥ=W�8*K"�%�Ó|�!�cWs�dL�w��LYX����%��I(/�D�9�P����Pu�9�����{�Lf��#'���Xg��A!�7)�v�+���L���� +>*u�آ�P/GJ���7e��5g��A��{f���x�8�dT�j1r�y�Ko�kb�8RY�G���v3��>/l��E9߹����#ޙV��M�6���ϖ�1\�W�W^t���wX��I�풦�����̓=;��R$�\A��/Biε��M!�A�4qD��>Ȍ��`^��mөb���~:e%G:��Y��/��9�@UyFݢ��<�h�ˀ1�{DH��d���F��;Wk���Y^�4�h5h��%J8m��)��:�o_���#q�Ȯ�<�>��� e�c�#�E�K�gN����V���Q-�Q�¬o2�Ɵ���b��m���B�H��Y�m�*.L�ʠ��%X^�t��q�=#y_d��c܍w��(ڶ8�b�CA~�e�������g���V��$phg��8��@͔ȃOÌ��ĳ�����{�����W ����Rp���NϨ��ELsQ���+�0f=1�x5��?o}a��P�J
�;tz���[Z.�HrӶ���v|FE5��NN,i�y!���l��s4�yyN��H���۷`�ZU@��U9ډR!볝�΢pĀ3ϐ,g���d���Qjz(�����
�<qKG�����,o�)�_H�N���RZq�)�8�'��	�E�r4��uډ���9��S۲� yЗ�K8��l��ò�[��x��T���FA"
���;�B��т���3�y{Ɨ�pi+Y�>�u�ρj=��]:�y�.�׮�n��t|u�ź�i���>�����A�s��	�Ӌb�)�h~�ӛ���<Qz3��}����[�F>��/���kF��`,n��f��jH���kK+/�T&�N;��Rn�꽓�&;�=��|}��cZT���Ȧ�න��D�x���t�Z�����@<����Qd���O��d��qx�ĕ&���-`��?(:�3�V�v���d�T���j��
������\������v(�{U`��i���4��La��@�q��f�Ow�0��	7�EK�Wȸ�ځ��r ;@p�V�דN�w�I��J屚ë.t�BNBPٛvڠ_A���O>�C���xy�vėd����P[�J��>�"�8�������(7p@ʏ�ҧJi���[L���i1��5]X�@Rg��H��Z��ϔ���>Sd)�z�}:��	!OR()rt���u�n-N�
������� ߑ.1���M�3��ɷ��p��A�>�Y~�P�A7&�ԥ00Xc�V����mdUIk��^�A��N�@v8�Љ�d�l��AYE���xL ��f�k�\_(�A�q�/��kB.ߣ�k�r��0�Q`v�	��՗�V5~3��1��Yl�^J���&zzk$Db��V��`W$�e�fԂ/��N2��wX���Z�ϵx�����[�'L����|�R�TUÒ~�la�ܞW28�~t��B!Rd�����v&4�6��փe���9y�5?�U�k�0o��1NM��ҷ����]ڏԪ�mʄ�q��=OL6;�/�� 57�u�v�ў�Ocy�Ф�̩r�vS���hP��Yk8�k�8'������ �v��8�AyB��{�fpۈ�go��Ձ�T�����_�7C�#�>�>�E�*GO6����S/Ғ� 
i:��i�g�e��_̜���D�İ5��<�;יU�r����d���n$g��;�D�&�0�eq`韦4����t�+�Ӿ�� YWJ�Yq�(��xx\�%m��������.Inkf��V̩��iR+kQ)���0�k"�_F$��Ջ��.� �b"N^��n�p����T3����4Y@���EdL�U�m_�az��̺d���z�)æ頎D��Y<�������A5�3���D�V�����R|���^2qlH�?Z*M�D0�������Ň�o��Ù����)I�P��A���V]԰�m��;�_�C)H|F%@�`8�2�f\N:^�K��6�qD�1Z��\�z̀�.�IA���?CŤ0�_���BM��c��d�?#����'���$cb��M=�����K~L1V��ЋL���se;�f~1l%���YT�UO)��O"u�("zV����t����]i)�ous����ᘪ�	xnBlA��ٛ�8��v�� Eɟ�Ȕ\)�
�����ZP�/9��T(F���w��f`o���-�V�����
`�j��a/Rs��P9�#ণ�@aXM��O윮Z���qF����E
	�d'�ڪ��5B��/�Ge�w0ǻ��?�'�o�K{>3�8W�����9$%���V����5�W�w&���>;hu���&HY��E�d������ꙧwۋ��!�q���Y"�=� ��*L���!zY`m7_�9}M����C��ߋ^�++"���9�*N��ga:w�:R�^5����Eq%7b���$L ~��t�?�U1��,z�(��;�-1n�;.�>G�P���ue�d�����~>� d��d� �Q��Gm�r�`\�O,���4��D�4[_���V��YhC���0o@��x���j�>��.inʦ��q��!���%xs��Cp*O��d޽z�58��*�U�sn3�\C}�V�C��'1ÂM�q�p��$��cV�.IԬs�Z�昑-14��6�e�2"���/B��0%�!Sʒ%{��N�����0�c_D����.Q��#�Sy�ܭuͷg��P�KI�dGn��0J)��b��%]Y/�s3#���&ڵ�O�o%�����w�_h�褸�9����R*�-cWvVĽ����c��}?����8p�l����8�l�k���}���W�}�J{]�]�;��mbz�X!ӟ����r�۫�=)���~᥮}#����I���X�:�8ٱW���k	�����r鋩61I��u������ʭ�9�F8F�q�/o�����T��$a�j���+_��.���UL��#����ռ�f���|�?ޚ$��g���kI��.�J�	���r,��uq�a�@3g�P�_Ҭ��_���:l���.S���uPh���	��*��CR�󋬖DD��	[dp��@���"V.x?�����Y3��0�Z�H���p��8�3�5�5&XYV ����bm�bP�'�I&�m(�ϳ�V�)��H���w��<�U}$���0�+�B#� .z�Ш\M���e��������I��ީ?������)�7y�)DwtNl�"D�����u��^r�,�x�/3X-�'�G����K�)��!H�YA�㥙�"�/mF��*hk�&�ī!Ԭ?Q�������0\�(o�U�NԺ460�޿M��v�d�Ң�ϲu�
U#d ^�O8�FE ޻��1����-�Y�wE��6�W�'SD��##jW���>�ʹ և�X��or1�S#�.@�6F�i)�"��J3j�v+N��G�nOAx8�e�_i����\<w��@O�$���w^��3�+��=-)�5���z�������Q��7��n�f�����4<�oM{!�&���9L)z5�+�W�Z��@"vK*'_ȇF����s�{*���x-`Ju���o��k�]�z�6������M�#I��q	��kg��	�������t%�?33�؁|�E�T�MnPQc����L�
�]���?�U/?�i��c���>y���s[�|#l��t+��\g�f0��T"�<�� �~n'���gtƯN\J�_���ki>���vQ���˶7�D�o!qML0y,��L�
'���&ȁW݈����atF��J�CQ2z�����՘0�z� �+A�ք��x�ǖ�����o8iS ��֘I�\�J���&��(MQ���]��hB'}�H�J.��$��0ās󰺲�ڗ�w0�4�����a�H��������z�uAl�۰���(]�j��yv�T���Tpn���pi��]I3���9�45;�Uq�5F3f�����34_ơ�/^�XSl�60u�'��oU�|%W��.	�!�QY���ud7!=��3*��veCѱ{�S�brH�{+م��Mp�=�qL)���nm��ݩ&~?�2��*�
�8�*@QMO� U�7���1P�ҟ&�1Y$�
ȮBE�ıġ�sI\����+6���D��#fe!٩C�˾6oi���0\qA��g��O�J^|�������돷�ǎ��MZ��)����Y�_�x��N��8^��lT�.)a�*F�P�d��Dzo���v<
��I���w�������h�'E���T����؆���R>h7F��R��e�F]7��okȡ/M�j|-�ޓ S���Kp}˩&�1��:����h�P!�(�b�A�G��T$���M��\����$�)BkЍ@��&�_��oٙ4]��oy��H�k�Y�S6?��uh�H�kB�����~ܹ�r<+��9x�ŷY	�?�x������v�R�N�ap�*w�j�UW�!�������O�HnƢ���۴��`��d�Ͻ�j��l�m�Z��������������W�K3+"8o!���h�y���;Ug�Ϛf��Z�Y �����Uzbl�oP�i�Y�� oFܮO8]2B�d� �Y��}u�O?��������4I��D��g27�*��s0u1{%��ǧ�o����<�n���I�1L�cZ&
(8V1�[���韔MWs�^a�d4�)!�ǙkR��$þ�q#p��!/��,�lD�G��~Ĺ�6z�ROZ��C��<�x����s�d�ȁ����F�2m��+�+������N�7|��U٢["��g����j���7���*|��%1گI���y/�P��^ٚ�DUG��׉F��%"q�4�,��0�s�ώ���~%��2��|p�o .��>t�?�W���B��;���QTY���"�yq�A���ID�y��  ъѧ�g� ���Z�t���g�    YZ