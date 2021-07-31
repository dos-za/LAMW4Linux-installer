#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4079360945"
MD5="0835714cd60bf244d568329861648f89"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23440"
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
	echo Date of packaging: Sat Jul 31 16:30:50 -03 2021
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
�7zXZ  �ִF !   �X����[N] �}��1Dd]����P�t�D�`�'�����c��Y @%��֭/�F��&�8)��B_���W<�"ϋR�B:+�����F��3v�QU}^�b�b�9V�X�.ڏ{^����(�3}P��U���_�֔�}
��(ِ�����(
�մ� �� ��Q�(a��5���Ђ
"]����8�\���2ejtJċљI�V�f]�ƺ屡T���?rQ�Q�P�������]�X�;>y-���4�>^��B�8>���{c�ShX�Ʊ�BtG�;����A���&��Z����;'<��0���Mh5M����}��֒؈����M,5ī�isR�-�������ӏ�Xz&G������T����^�̔J�
�ah�D�ywE6���]��x�|�B�M�2 �����Ѽ��O� �=ػ���)�I{/'��h�WxDl��f�����|��N�i!�4I���í�h{5UI_����4�\d���K��kDZ�+�"8�����4+�p�#rW�H�Z@pS!��E^�\xEL��ࡠ�6��5���\<'g�8Є:�5��񗸅�W�&���(�r�s�W�d�K㍌�:g<0�F1�n�^`�%��2�b�ں�t2�:�RZ٤2��b�?j�^.�~p�9����N�Mں�a�~P�m	��T�� x��7�3'��obQ�P�"Ў��Uq� ���6zR�*��.����w$�� �Z�ά]><րH 6�����Z�a�� �}��_���q#&�a����@��o�x@O�@`x �F
�|\��Ϙ�݄I��ΫI>(r�?S>���l�w4,2��!{�\�!�m�w�=��Y��wO!&�-u?C(�Yݹ�ح�����h���sv�D>�t=�\��B(��f��h���K_,��s~��Lw�� }ҹ��T5/'X����mr��G�K&wE��ùj8�y�:�p^�C	0N�.Ǔ�0�D�V?Z������xU�Z�Xs�Y�+��.�J�)h�vo����3� u� |�J���N�`V$�w4��7r�w�_�Sl��F�$��m������~�!Qp��W);W�0��(&j$y��i�~�}6c�"�2���+��-���'���qv����v�\�t���4u�i�u���c�z&'h^��+5�u��rΕ;��TFHs��ӆ{ū�T�H�܄���&��<����~d��%�H��ڴ*��i�]�goY �eRRC䩌Ґg�!@oF\lI,����uΝv�3���Eb��]L����SD�՜����`f)���|D�9%�ߢg�J�_�q�/9�٩�N�W(�kG��;j�����bs�B�;QxQ�����	�u�K/�l9}�pP�W�ؑ�Q�he���'��%��R��mzq«;��=������G\ݴ�N����a�S�y�b?o�G \&�,�}vbR2�s��Ћ�/5t��� ?����(+�I(g�I��'��&x݇�fY�#�N�A�`���O)�����`M@��as�9פ�ǺS� �Z��!e8�$�GF�drsq$Nԝ2��)�L@)�_}�����H�ar���\V���Eț�^tv]�tԘڵ��>��LO >,w3�3y>�-L�>��c�q��H�[�-Hg𶭌>$m�>!��X'S�ۀ�f����֨�3#������O��F��n�����v�
WrHr�5���r��!���>=f�0L�R�䏧０^9�lm/�<�hy��g3i��L��"_J�a��v�sV����c+_/b����C4Rv�9P�'���:�4g2K �T�Q��@-qs���LG^Nn�eRLh�OY��M��t }�0�ۿ����52���p�;
�x���kv���}/ql6���
G�3�X�9\8(�����${LE�����9�K���nː�,L�!����M{�|�<��ֿ|k����i�R�C���:��N�,t�'&ծ��"p�Ty�le`
��;�j��qwp�-İ���lU�����V.*b�6��(!�(�ku�æ~���9��H26�|�j �d�7o����L������'g102��į�LZG���j�a�G�;5�R\**F�ʁ�@N5��uj������
(�0f�q ;����v0�����)X���X[���)��Y�j�M����"�$�p5,����/'QEc�۪d��#rP"5e_�K�Wc`|�:jzS���O�}޿>�ų=*��|F@���>�\�~e�o�ʀe�i@�uU�75�z� ���s���4���=�U�
�3`2ܛ�� ����%�?�i;�gH��I%̣K���]���f�)�7Qlǥ�^�����y�x��\��F��]���b����́	�ʧ��L�h@���H^����D}!��� ��
=ʖ`�-d�Z9E��>���bk��ږ��bg-��/�:@�~PA�g*�T܋��u��T�SQ�a���DC������#����U��+�!���_������%��((|��c��!.4�ѻ�1�H6�zX��Y�W����@Rr@11X@k�TMGK�^�B�S�ҵ��)�U�ytW���;�#` �Q}�W{`yi��:�Uȓ:�J�&�W��=�Eel>�j���(�@����ם�u~�3�J��Gf띑��Hd��A`���U"��t� ���*��6������6I+ᔶ�P1�8��^q"s�r0�'���9��f�I�*�)L���K���rc�c�{'�JԤv���J�8YN����W-����-!��ZM��#	yH�W�dZ7��3����^uBl-����I�u�۫yX�L�^fk��hDzIu����$i���?;HP�f299dug�U�9E�`{!�P�<\Ȳ���#��F잚(��&�@�',߄�t"t-`*vJ4����]~F�	s�E�!�/�q������ĵ
̖�ǉ�r�	�PC	M��ZR
q3i|�U�n�����M�#��:���j��:�c��)�)��;.��򥜻�#�$�����/�����Q�dOpPGa�����6�",��U�y|�oB�7{Y�џ�>^}���N�Vɦw�~�HҚ�C�E%�T�@3b��ol"�$?�� �xG��(�Tm���I��5�x�A0��L(������5V|y5}V.+�C��cw�\8��$$�pl��v��d��9]��U��%� �C�bh׎��e���&�|����L�jx�H�p��\�DsjV�4^�s#V�荖! �{��<s<�U'�#��%�l����d*���йJ#C@���Sb�8^߄cĴ���Ʒ� r�\ 4������r��V�WU
�q�ZP�	N��S*K�|�7��Q�\�b����^J"8I��(k�v*��=��|N�䨅�`��s2)tnJE2�)��/wOn�Ji���`)�Y+m��b�؞��KrϻX�5ر�q���1��l(hn[L�����������"hmy�������!ߗoxD4�u��� ����+ї,��YY'���|h~�&�V{��}��r�����;u�j��bh��Y�{���L�3�&0�%�v��%ۊ���H���,mo�[\����u���$-G�����{�׉Ab��%��=͈�n��E` �
aAx
�n,�O2u_<w�S��yT^&��n�f���ሻ�1������x���lB�ë�Sƣ��ap�����u������"�����!�.�`��	K�.?��`k������Z��;���
x��n�ہp�YDn���!�k��}�x�w�ȱ�!Z7�k�6 $%���Ym�6��ak9Rʑk�$�z�Ӂ��[�Xsh�M�����A٤E�g����iLm��@�T��'��|�@� X�"����(��Ϗ|X�}6��C��.2�Ț*L��ѰNΧ@��q�ѵ����)�طe���W���4\#�)pq$�ϓ`Vi�u7�����ēy�t��/��Z�}9�4����v�@����e߿���D���c3;և����� :t�ŞN/$�35A !}@�	��Q�.t&�-�&�񊐶�@�k���N�`_��f��glC�*�����(��@e"_5��@)"�\a�#cX������!��ajX?�y/��"Jݒ�Rv"^��%
.�IX;�?�4O5�R[̧��?K�w�� -SŅ�x�(�,�f�6y��!�~�#
_!ڵ��q(j����¾*uu�Cݨ�t�x����1
���&8�0U?�Z��.h��PL	'�x%�^+@P�S�R�"S�&<JО+���DJ�_a��,U��Ϡ��o�@^�K<����ʓv��8j�E�wt�8�#H���N�v�g�P��=8��j}��Ų�/)��󏞟)"3�S;���;��YD �}z�V���m#a�TF��7P�5�j�F KD��ł���*�����	(ie( ��m����}^"k���\R����v&��1_�.�.�.��
.���/��y�_�|��?_*�{��'e���ҙ(�tƮ	�Ӌ_U����)�(��|!���4�OB��X?�R��ܧ����c�uR������JkZ�Q�Y�!GƗ�x�Y�{GL�vd�V��|>H���UX���'$k�� �� �� �W-����̬m)�םy�=��m�D=��4g�S�1���V���$&�i�({��,�?��{�(��+-���}h�m�T�K3[�t��X�.��3��v�]b�k�>']QaS�2U<RS�Ὅ�M	x�F���`
�7�'��v��F-����Rԧ�B�i<�)6v�� !&A�m	�\��.C+����n
��6im��y������K%M����Ԓ��』������7+O�1�����=�8�#���qi`W�i!6� oNgw>+�w�6�IW�#�d�� ��2���XVވ��t[p�=��ApΠ݅�錴�����v����@�;C��"`�A�/�ȢH��)Q��۹���vq �3�����h:���r������s��,�y(��] 8�aDY!ö:G:��I����ɑ�-���ujY%S����0�|��i௨ۇ?S���e}�[�	4矵�g=7�$��p���Ԡ��cZɿ��j"���X+Q�@t�������C��k���y4|�h�F����ĸ�I�n��n��CМ�I)�<����{����0��6�_�_�#����E ]N����P���o�����4`��B=/��X��c���~��zO����}Id�*r%G.�\���&�vk@��d��7��6>$ �B�F�5-nfW|}IΘ�<v�Z#�����hag�4�`x��r�2v���1�f�r� �Y�<�P:����K��� S���55Z�j5���ܕ���/���7�^ؑ�Y-N�Z���"�fC�0�� w��#�,�X$F}4���JC���h_��QN^S��j0n1�p	UˌR��M�z�աR�b���o��¾l���$�F������IIC�Ԑ���N����e`�%[(Ɍ�{N^�AMk����Ȁ2ees��\��II�
՟t���2��F��Lq{���Ǐ�7�O�OD^���5o�ZZ��DeEy�T��ɖ#�P'���;�1��,c�Ϩ\ӌ{�Y���-�[z{S.j��J-_�wT08�FB*K[�2��S�zG�ʼ��>\?�j�=G�Jd�$���c��W5덯����b�F��&˲�������]��H�ͻ��0�O�5 &_��t�vQ�� EZ������
?���P��TXk�z�y�֝�K<H���
�Nυ����O����[;S�y� J��GЙ��PE��Z4%�<k��������Ѝw8N����Ϥ�o�*=.��j��ж���ߊ�d�o ���s�@Gaf�,��&���u����{FMy���&h-Y�3��0+wP��\�b�a3�"t{Ay��$�DAY�8�> �Ո"ZH���EԹ� Ƥz�B^u�o1�g����s�Ag= ?�+m_�;z��x���.���?rim���af�|%#���3�v�Y<�"l�^ɢ��������l�'�Y��!dB ��^�b8ĲD&��ɬ��%hi�V�p�����5�k�	�㮬�?���!�&�{�!�g �3E����5�r���{0h���$V�r�Yl)�Ecab�F�d�ѣ�I��e�as�4� �|9�ʂ�_͂m�����;���0IU����e���o�_ ���WC��/��GGQ���MId���8t���N��9����Ʒ�t�[�?�������ϖh�<�{g�~/這Y���]� !�-�5`>ۘ_�X�������aԤ����t(x�$�󥫌�ZS�����Q�{�&b%c�g�$̀�z��N!->ɻ�a�\��I�>�o+{�`�B1�6z�+ۓ�gE#�����4uQ���D�G4s�f�H �	�b8���{�o��:��b���J�S//��Hr��)qz��;G�6�;]����A�,��g�	&&��0������$��Y��+�9U�O�����H�u��Yu�Y�C�oMW�p� �_�N۳U[	8���0���O���;N8~Y�$I�ٽ���Q2C��N��_��+ɚ���2�������H�m��p߻1�nt/I�u�n��{��G��M(�S���?���$����g(�=�96�#�Dm	[{���7���<��Ă3@�s��_�����<hE3�db2VK��p[eX	��%�^a�Vz�?6x�5��	Vpn����"��%�0�[_\��@�t]c��(F\@�}�z�^�[P���lo����i���8�/9čJ��xZ#(�%��U�ޫ�g���=T8��Vi`�����侪��"���X`g���%�G,r�8ϛA��ё���`Ē��T=;�BT��5URMі� F簉�-6�ޤy儦��̄6ч�� ��N|�S�������Qۏ�ւ���Ջ��I$CKXKy��%p��j36��Hr�I��M�
ڦM�W�j���J�����,y=��̉7/Y���0�v��@脰��F�>�/��npy^?�(��ޥ�tH:�rd�=�D��o�O�xb$����@.eǍ+�*]�����°����.˳�1հ� �nq(y���N�Ic+�~~+�e��"��Fj(,�+�na��Y@��(�Q��|r�9YK�<p��
=[Z|;�f�o)�E�Jj�v4�o.�fK����.:�(�O1HA�� ;�z��`~��f��M�3��#�̇-�o�#�����QsW(r��|����%`v��<�s8C`��Z��ś��0��J�������g���QŢ�F���k(�S_�!��60�y���{��/�_>�U6'�V	'�6G�&��A���J�����]@}$-b�o����')������!��a[e�O�ׄ�&��eL鉘�X�F�zʔ�÷�ވ�h�&��� �Sԛ�M�f���է��H��2�ѵ38<%{�KWޑ �����8�mlo�sљ��hD���	R�#`IV��_sZ*m���r�f0C�܆˹�����0Xbҍ����ѳm���]&�I<-�v������4�o���o�:��Q*NH��2Ã���e�.�9zm���nxd��V]U�X�Wan?���"Md�����g�w��E�&�Ɩ� v���s"g
%oΜ�5�.��缀����<S9��5g���v�BCBDz�b4TQ�|+:��\Zo�dd	��t��3�����y�ᴢ���O���_! UJ�:���1?"����ޅ�ĳk���	��.�-ك�	�7�%�u�uL��9��(U�!�/�)�x�Q�J��������)�����P�O�E���)�op����x}:,����S���Y������i��AJ�tQ1 �:��f�G��%��(н3����6��W������:\�N�(�Fh�y��s�� l������GF�x�L���i��t5B%�G�i�]��A>V����^(���x:@K�,�D��m��=^��z�@9`i:��{�yF�|g�	�ڨ.>�����7�y�^*DF�0�|۞ۓ�/���7co�;�^���±#��L�oos�QȚ�Yt��^�m�`�FKϕ�
@/�(!_2������.�#�dt˚+�Pq�'6#<� �܅s��#n;��ƌ-��?H�1[`O$"#uC��*�uw�� Y�����*������nL����&j��qⷅ���ןl��]���"��*uk��u oZ�2��iDnΞ�n,��⺸��1$�w�i��5�-Y�_o�:�odB����p&%����+RY|C{Q9��\�&A�BN9R�ċ"X7֕��{W��ǇFHrq��(�������#,�(Jۄ�y���������H�e=��+Z�}^�� w?�p:� H|KP���Jrx�*�O��Z��&��ֶy2�����C�\E����Oow�Y����"v�D����D0@��e�.dx'O�/q%(mt+[�AY_�V����oyhk���/���EC"�F��Ŭ�$�����e��*�X^C�ѵ��w���]��5q��u���w�F-����Q���#SB�!��첖��0iϽ����3¯��	{��!�4��D�7�n�N���.�?����|����vg|�UWP���p� �|s�F�ـ�B_�t^qe�~�n/���=خ�'z�B�ݯ�D����ȷ���m��I��1B9zB���:i+)��v��z���|�6[ËYQ�j�d/�햿gl=�yή�ɱ"4�S��M�&]�������w6�Q�Zp�¦�ck���>���7�K�r	ܦ`S��T zh���L�Y��Y-��2�羗Ҥ&�G��l����5�Y;�B�/�nM	յ*>�vq.�碻]�!BL�?F�L,Q�[�@���=���]����O���< ����q��*k�H�IuR��������޸�@K'3��l6�� �P]���$�E�|P7>����h%��c��p�5��x� 9!PSL�,�os&2粴1Pi���Wa�IF8o��-A|�q�A1��!�IMԜ{����:��~T�v��AG}�e�\�tv�Vl=g�k0?�=��R��z�E�y!�J�y�r��V������wL����i�b	,&����x����'>h4V�(^�r\=���d��B=P���W�ި��L�)3jkSs�������s��al}!
y�E�E��<8�y#��k��$n{��2Ra�~Y�aX���e��f������m��srF�ٯd��R�Sn���fF�Bڬ/bDyC}O��
�<�j�&�b�ӫn��ހjnRw���0��)��eb�z�5`��@����D���吼�(6����������ha���+O>�N�>tܧ`�Y��F�D	|��k''�V#"D ��D,�4�dg��N�&e��N\"�����@��9u����ǱQ�T�_�(����A������(s@����X���`t3Fm

Z�!)V�R�o6	��!���8ƊZA���H��yc�ĩ��b�[)$�*8e9'��Z�1��x0J٩c��~
����5�4�8sr�鑆�x�(��_n��8\Р7!�Y,������ǣ\9��J�})V�[�5�Y?�t�uŚ��ztR
w�1�q�J�y}q;�������B���׆6A ��wGD"�a�S� �u	��A��������C��O�&���J�
����(-?���-< �Ì!e~�#gƁж\�Z���`�|p�(�$+-��ov�/�$4�1զa��jw_�MU�e�N��󾔠���R��/q�]n���T3���
�`�t�o_G;�3h.��~ϻ,1m>'��\Cqm��vӀ32C?�ZNA�4���wڎH�$��TT�kF�]V�(��y���3JXk�w|�>U2:C����M�!�ʹ���-4�'�����K�Rlb'aw2|%��X�
�#M �G����1E�v4�c.�,ۚ�=Efp^�v���G����M���|�ux�:�>z�*�P<Qr�@ cd4�����i^��#M��'�Z��3�';�E�im�F����H'ph���+_�<��i�>�N�߂f�PR-_�tP@��k�āt>�7;fhbע�9H-"c��{�#��Up�V+l����[65Ļd�¤Ǔ�⥡�׽*���h��Dr9�Ax�:4j��[ڸX�?�b�8;�+����Iڼy꾽����] )`V���{0���U�C��6��T�H,�^2��S/�Z�Ua�L�x�G�bo�o�^%�Q���D�Z�v�f��z/8H�)��󚧋�)X��Y����&[�j	-~߾����j�.��ļ2x�O��4�.��DP�ؾA����sp�$�84ؔL����f��Z/,V�]ݔ���,�� �/�8+�8����Sz��/JD��vɣq?�gs��.��YS���JƉqfq� g��:�X���S��e��ןlN�Fg��J<����?�;l�D]��\�)��ڿ���wF
f���E�Y'���CZ$M��r
�E�3�j�Z%�n�lI ��Ahx� ��ż�6o�\;|�l�ǘ5uC,�Qp���a$8G�~û��`��&T�~U����/�F?"�Fv�*K!2�j.�E4)�]w���W�U���t�� U|ā�R�H�V�vR77����UF��3>���F�x�}�:��#��a3��Ͳ��(f�ޓEd�9�*sdP?8ez3'����ÿ,��zo=�U�1+5�e���X��N�S	Od�;S] �n���s}�G���	�2�~�Ѡ7�E�����&P:S�����ԣ2nD�|P�!�	�#��U�fs׎��������n�Cun�`=�c�Br+����d)�|� Ƹ#���SؤB��:`_����I��ҟ��Ϭ�㩓��H����K-f����m�ӭׅ׾�O�ﴃ�<i{�n�X��b�y�x���S~�b��� ��dz��pZ|)��Fc��a�n�<:G��j�` "��L��V��{���֥��H��W�S)�^nl 9�@��Hl�S�����3i���k�,�T�	��X���>���`E�����4a�M��ؠ�I$���R��xS��%}�G�z,RI�/\�*+��f|�`"CXc�-��O��9?�,��N	� x��(@��*(��P���r 5�d���Ӧ����2Zu;�����	��U������I��*�|Vǀ�Ջ����Ty���Q�8���>>����?q�*�w�8S�= �,�8����P#'s-��}q\���gq���8O>����@;��*�uǆ�`��`�ʶ���i���@o������@��ǭ�`�.,��+��N�R���<@�0+�0t�?�Uo��=�ۦ!2�Q���{w4�\�o�E����,D]�
M���y+����9Pe��N�.�n>�&�j���t.��A$�N��)PtX+2��K�!��-���0��А�́�~=R̄NE=�i�d��|����P�M򂨃�;����,����,Α�~hgj,�R*0,W�]��hg�0�	����<�@%o������e#�i<<�,�x�2��r�e���[�5���ECL�88�3A�0c[��r~{�F	�R�:��w$���rod��-�]�)U���9��\=�t}��ɸ��P @ww9�+�F �h����i$�~m9a�M��j��q��4�`�=�(��o>y{�%�hE���U�`������g�c�4������{�A!��?^h��s�r����"Ι�sD��(.����[��Wd-��#��ajA;���0�H�BW�h��?@5"7M2
'e��>��˶��2S��U���LRe�!K��]�.�����6�Фxm}!�v��bʷ�J��}�==�-��c��tC���ܾK�L�o+�O���>:qY�k�x��Ǭ�s�,��`�ՃII]:�VHW�	�/[
�iH��1]?��{؞Oש�.�r�Pz'��M���wy֫��U��'r֟�q�g.�`Pa�a��sש �f]��O��"��zX���	l`��ʚ���ݻ��q����U1lUH�Εv�.ߒ�$�a����};��ZoZ���	�q�7of�hJ�nT?�e�j��0���6�vO����!�.�T� �չ�Dw��L�F�R�w��^`��$E�"#f^s�<��=n������r�����_c"����ی,�M_�|bCQ�r����)4�����̀ŵe�Lܟw���y�v�����]"!6�J�U�v�.Qڐ'I�Y��ԂHi�`��!	nv�*W�9ۊ;_#UKG�x3CMN"t�umN�c<��5�Ƶ)�pf�Z/ �	PЏ�׵Y-�G><�`TPs�#�`.I��"�gA��^�D�D��D�s@6���_��0�	$�l��AbߺL�Q�%���Y�G
��@tB_{� ���0E�s�>�p/�����A2HAV����y'������lN/�΃f4�t
޴6V�٥�5_縨"�1�=i0bЭ
�{#M��<��DJ��e�Ԣ+1��Yo)�N�ʇ���Q[+�����bM�.	��"�>��z 
����_pb1u��I{�*��ߟZ�'*u�PEFc�=ڽD�{���}����K JHvK����Ʋ�6�y���ă�MV��`j��^�� \�P�%.U�:��(��db
guh�+fB����M�'̹�)�`as��x������N�BĻzg-�`nV"��\J%}GO�<J,ﳄq1�+6yE㊶	h7�R��J�����ẼW�Q`��:h�W�1�X�J���<X\���v�� �=�6������a����5���acu0�LL8�(pS;-V�,�!��z�iA�`���_�LH=4����i�]�?��_e@�ܲ�-���Uq��&���1W,z�y�3>	�=��ς�u��|P�Y�黤8_��|{>�#,�T �E�B��ς�[E���Ɍ�,�bݽ�x��k��Ay��qp�l������$�3�v�����#_� �q���v6
{5ľ��s9Jgd_��f۩Vc:
L��^4���mC캂�ꗊSӝ�!���	0��&���>��חwC�}���ZF���I^�7���ӛ@����3�z�t��1�z�:�4��ۥRp�0}ʻe�i��c�����d��c���J�}:��N"�� p9�!^��yH�#S�(B���U9�Nf�)�i�%ڊ`��M�'�S����҆Y��/!�SNɥ����:��ϒ֖dЪ����%9���j�{�sՂ��?\���X=���v/�mW�H��_��Y3�1�^5�<�2'�������l�/��6�#�	�*�]������Oή�-.HV��E���%=��C�����`�����X�&�����W�� '�<h�I>�D����0&�������n�	��'p8x*�:�&�����g~�������vq�r�3�8�b4��F�,�\DJi$:!�\���aD���"<e��]~�h���_��=R���=�9��.�5h�ұރ��hw��1WBd�5#�p��-������������<���E!x앺��B�mo��UV�����v��M�k��b�� �)���6����@�F�B_�e�G�f���6����6J�Q(�ӧY����R���K���{�p��7�ԏ��9�Ӟ��+o�
����82�����X&��uC�Ż`tfm�6�ic���wb�\m��0`n�KoD��b"���^� l�=���N_���<��x�%<25����|�J�A�aE�<ތO���Cܾ �@�\��F�nT�#F��THHS��(�-� h��6ʇ�$̇l���]��� ��Ku:��$�v�k]��:;Ȋ�����(����B[C�;T�e���-�Zl��I0s�0��ZЧs?��:U[ ������)�8sߣ����H���Žo��Z�)6�1d��	����1�k 5L������J�2#� �H��{kS4��X$cN������-rΟA�K�*��6�/K���U)���P�*<%}�Rmo3��+��E���w��n邽�{�2tR��)��*�Vk�,	P'�Y������������_W��\"�x'1
�ʞ�"%X����_nt(�'{�=6A�[mfН!2�0��p�,p-���ns��iY$	��6>���_=���E��E0d�-W^\���\	N"_�����f,[L�~�D�x�G����K��P��fF��}K�ݑC���qXk*���"�i�E�%ǽ8��^"��V�s�b�#(�L�x� 7F��u�m�cr����MB����|����e����z�U�Se�l����B�d�'�'ڨ��H�҇�(~QzǪ�����jc!�cK%��zXg��+�%e��C��zBS	F�k,�p8��ۄ4��!/`=g�[��|}&�E�[|C�rE#�����%���� òPP�r�:)�S-u�*w5�M/����Y�E� ����.!�v���b��	�cSk��p���K���'y3z+�������'�q���U�e�7��<uc�o�+7h�(��$�\i碗b�-���
��v;$l^!0��[�����
�B���<W��ES��к������V��NVW���GbP�����ңl�*nc-��QI*��B�dh�I̧˴7��9���^�����or,Xk�����}�yJ��0�n����3����WU�B/��Q��S�ɫ!�fV�A@�"�����#���Z�A�c�؆YI	D�8]�
'[��a�ħm?�8kF����5�ZJ�	�&R;桀�:��-,g9�]ʝjv��K?_G_���]��\ʕJ/wPV�����Q.Z���H5�1��s�n-p{����6x�߾���w��Ȝ��� ���r}��G	豄_$�d	[�"���/3������L	��p����7ųh�$"F6=��[QYe����x�{mJh*$�y�it�vH��
8V����Y��|}&Q�t����p�s9)���/�4�y;�og�^k�tp�0��=���#��V�q�`/	'�>]|�:���T:�:�9M������͌����b1�P�-rI>-�g�&w8a�-3e$�[��+N^7T(�~���X��,J{W���r{U��*�N���4�L�&Kp�mlV���Y7��-��C�#,r��>ߦ���9�̎�K*Sy�q���FpP�>�r=���|N�FƵ����cq�'��E�Ӭ��c6=�/�/��D�t�{��_l���u��1u�]������v�x<��	sv[���Q�]ء����?�}���%�X�RoBQ�^������Q���+&��9�~�P�x@e���$JEu�Ē�&&*31m��!��*o4� �aQ�4RY����oM��J�A�LN��_���~�d
|����r&����T0o-hm�xT�`Uk�"Gڪ��ދ�L�<t<JS���s����}
J�F�VN�8��׈z�����V�^R\���]kA<�R���`���z�PӳBկp!��t�f�SiC&J�Ov�O�4?���/f*�v�U�s%�����C�d�@�p&.����R���7 ԧ���5eaF�=�u׊f������	VD�W�虜�6Y��\m�z�� �C��ƈ���(���]�m6�[KY��C���,�v�HVB��/�VFF����R�-��O�(�T9Ո��#z���{��~���o0#L7��U�D�N��j4B��=	&��t��Y�jw��X�9��`���{ߠc�i��;z�:��x?�����GC2�{v�tvzK\���Rt4�������2T��v��v��$w~��
��Su���tu�wm��l��fB�yX�q�J,XiI�W� �/�~��-?}��;g,4�	�cCKG��H�������Wp ٔo�����OtX%�v�_�@ZQ�n�} ��9�l4��y�L���<H#Q�b�2�_P�Z���4��M&�����u��	Kq;�	�5	 �ˤ��
�ߠ������聬3�x����ȟ{��R��W��)Qڕ��+3���ݮ�#�Ճ��n�7�q�5����&�L��I�7��Ts�w����,�m�,y~�\Ob ��ya\��>���q�^T]v��ٖ0w����jS#���
����=l��\�Dsڣ\ޱ�#cQh����=6x��D���!|��R䶩z��G-yiJ�2U`ޏ․ᖫ@$�m�ERС�%vU��C��r��T�;ac�Q}�L���
�q�g"#^hA1�Z���8S{��exy�0��S����cn8�Q�+��P�t�ivޖ5$��"x���\���'����ef���qzeֳxhB�ń����l�<u�0��b΅C0���q��Z���t��/q��"�0&x�ٜ�����L�M�\����,����|�P�(��;DV��?T3�)�`.r1�F|}��Y�d�YY/������� s��P����A�)�2�ga�#�2�׿�|��7����I�?�^�]�,7#!�
'JF�n���욛���k��Q�6p���̕I<����S
��ӆ.�^��-�V�Q���՚Sm��k^Gl�Z׻�(J�S�Y=�+Wy�^�t�gk`A�wL��L�ҳ�O2:@���(!�#����ޯ��٨M���f"�f6|z/���� �]��#��ᓏ�!�P��" `�l�OH�%Fp\a�������_��9����̺�M	���Δ�v��n^�0(����&5��p��|by ��_�rsb��p�T�X��b>o��r9���2�'Sy3���\8�[�������e�N���uw,zF�:���KY�7��$�J���D��U*ή���9��;ۣ��\iJE�\�����.���D�(\��A��D��W����k��+Ͷ0
�Hf�I�ve�Q�錋�<S��+[�����d]���ĆL
6���3���o�4�J�0##Xh��KߣA�����$G��[	��J�[�����^�("�_oi<g/�������`�G�Y�1dʾ���r>���3�1V���� ��U���He3��:(Q&�\Ϝ「�p������q�gI���6uL�����Q��L��8�������Y�݂�B��V�xL���)�`����Y�]�w� aG��I�B�?�%j2��xj���N��}���!���
7��7L���+�6힫'1x<���V7�?ۓ���Q�*��wl��%�V�l�Rl/�c��CW�V���'����>%�&�R(�)�����͠3�'&���j���
Y�mr>Zo0�uO�b����RMTV;�����C{�~�	��y�b� �!�s��h�� Wg�Y�����Ï �U[�]]}Dn�H=R�):�@����qU�q��*m1Au�Q�`�+MdǺ2�`8h��4�㍢����Tq�� ��R}Jc=>���4�����Ag�:/�b�1$ѓC��]��o���!ؙ1��Sշ� O�4~I�� �`�v���R��C�mX����`G�'gXu�b(�^J�������5vM�;��\�A�����Z�F�`چ,��%к�/|l�0�v�#϶���,��S�on5Xha�i�%�X��S�u�H�\���������+d,wDm.����.���N#���D`�k:Λa�` ����RҞbݦp�c�4�eN�R5���hV���*dQK��P��D�z#nI�AI3O�F4���I��|�g\h�,u#dyw�M'G�G�x�OL�2�1��]�V^��-J'1 �@����|��I�D*dVH�F�����<�(0-�M��`BR�����wGc�}<J�;F��W�XS?�kA>e�vk�aKG���F��T��wR�F9�B��g�(��e���	7N����P��p����*��:��brA<W��X�9�^�U��F09�TV��]��v�פo��"F)���J�˄x7mr�(�E�f%����R�}����bO_GN_��15���"�)�RG��PAj���}1���Y��������j 6�H�o/迿���219���";�̺2����0�8~l�0�[�4:�|�<#��9���Ƕ�ޢ�uajt�Z�P��z��a���l؆V��R��~�|���*��>%�l[d���re"� �8#*�_ ��M�L���4��2�H���O5W�i�1*��;v��1~Zc�l4��uڟ4��i"�bG�y+=�������5O {��1m��w�7"}����p e'H5h�)(
�U����A��?,C_�Q����ͽ�?�*M6�5m���= �t+ֹ�F��cPWWE�!�o3��Xk�&�4�Z��O2��!c��s��BX�[�=G]!�Z9��Eի�.5ʃ(���8�'L
=3~��x��L�f���R�[#�����Ϫ{h<����+8��u�4�I��֕���oo��?�J!O��P�nt(���h3r��1�~�F�'s'���`Z�$&tqWZuS)��y�}�
.� W=ǃ�Y ��[��/B��w��?�k���А����0x+�߅h�xm��'��;Q����|R�~�k��Ή�Q�3�/�Hf5+{k>�#5��2af3:��� �ϡ\ݟ)6gQ�Mڑ��W��=zU{+\n*:Zsא���g�h��1s
<Z�p��� ��ܺ���pHUpmbM~��!����N3�u��,����^�[ռ3�B�o+.��2�8�S���͏햳Y�<9u�;Z'q�+��q�WS>��aT��^��E4�+�vD���E�u#��a��b�o�=��"�'��=��y��uL;҇[���T�{׊�_��9�������MP諃QK��=k��m�K�r&Յ�e���/� �x�S�#V�n�{����n����7�M�{cC#}ڀ�Y�A�,
�i+�5S�	�R#~O�D|��eC���;� e���V�}��G�u�]���r�Ē�|���_���ϕ����D 3�#;�Sҷ&�&���b`$l2�j��XIKi�x����w�`���'L��O;f��V0�gHW5�M�������d��A��.�q���/��b:��0�1R2��Pg����fע}X�[�Nm�`�O����Kh�����p�o�"���2���a���cr��P�2����}��54��3���d����/%��6��'��h�Pf�Ct��]+p�&u�p�����"�r���S������h�!m��G��$sj�ި\���sd&����<c�I2����4,��f��|- ��Xj��*�KwVY�a�g̝��kHI*^�E�]rC �n1�Edʟ��]�E1����"79�י�my��m�A^������D��ٯ'!��;J@���:ʤiǆ�D���P���
jWK�E���A�H�����PU�]𓉹߁MZ[�b"��y��e��s$�����C���>dʯ&?�������>ڛ����	k��EE�e��M|���P�L��B����DK���y{�(�;M��\�U����w,��9��6�ck��΢`"�L�>����#E�S��IP�'��=������T�*Ƌx#�ځ�\��Q��wD�"�ј�M�cy	���K-�J1�,7���=Z���?���l�hP�ͫxl� �<�\t�P�P?k��*�����������ݥ��jC�W�f�1�0m�h�S�[��ooXeq���^aj�%9�a{^�0;~nf��LaP�ʸ���XP^ �~�n1����C z�k�%�&��6ռ���Hq�X�&�a�m�=�զ����#��ë�^�E��Pb"���C�i���dL �@WL�b}�鿭��Ɖ�*��6�L��b6��c���C^�ꉆekr��rk�����	��?��� $�NY�Eܚ?�3��k�����x����\`ki!6#�q�h�6�)�(G?�s�NFH�*�L��
���+��6"�����YB3&�$4��-�e�`u�������a@D ��I�|.8�2����Uw$;��X͡�j)��4��
b�"�2�ΑHo�������>4�j�i���h����?"��td8�U���r`�g�ԠkR{��~@�+��2AW��|�iq�a�j���E2�>~�?n8����!9���ze�1c~$h��9�����ئR��xC�C�X�͸�U���gXP�+�)��r�PQ�N;�4�Y���i���[t397xd�Y£�Y΋���W��|޷3����E�ЄbnKv�789w�W%��;s	|�n�S����"�J��!ѿ�ǵ�g��7��3Ӛ�q�t���g��})��a��`�i+HDqM�s<�閘n:%��ƽ��Ơ8��>�֞8�w�s�b��ܲ������;��8��O3��W�>
�_`17�Mv�@��;V ����&Y����*����1l�� 
Lu�N���v{)՘:t\���)�Kɸ��k�4��P>^��1���]
���>�l(�{��-�zx����1�b�Y�������N���'=bzeiMb��2�8�-Y�.A� q��Z�Z��U$�^g~�"�M{�|��?$�4΍���!��Qpڑ���/4Pl٠�CQ�
	��9��p)Y��kl-�I�2#�X����7>�`��g-z���XXt	�N���S���%q�Q/���߽���Ñ�*}��fe��O�����U�"wkk��>4I�����}�g�]�:�sj�[�A������SWƛ�xo�|�>HK���z�f.k���}䱷��/;��3��	�G50S��'�UE�cX`�n�����`��� ��N�ώntΚ?�h	{~1���$��㗜������dW�T�cL
��wzH�!��2��;����`��v�,�Ll������*��<��6n=���]�G�>f������>��~Z�'H5>ݦ�&�l��M��	\~}"�ޘ�B.�O���J�
�"/lv�*�Vkl���G%Z�N��)���z��H���1Mߔ�i�לu�ֹS���HBRs �J�rWH3#�����f�����o�k�`S�;�v���,���G�*�ͪ#�Q���A]
��>~��آ�煮[�'^ړ'(�\��{⤊��.(���r>2���x��:���g��x�;�3�!���� p�/o���D�A�B���mJ�1���z�4"�F�r�>HF`�j�J*R�������<�]��ƭHy��tc�P�bMY��T6}3���p'I�O���XJS�dn��PN���'�A���>���F�{Á��օ:^7��D$hk,�|&<�`-��A�7��n�߱U��8=����2�gh�3��ӎ/�����p׋gf�j#̆��qJ�pۍ���O�.��cV���-|	�E+K�FL�L#"�HR,�Y�U!v��B�wn'�B�Nf#9Ʈ�kW���D.���N��?ps5o0m���э�Q���t���@�fԛK>9�����OD����Jy���PB�"���ȵǜ*d�>Ol]�v�0��O2����5�D�SRߒ�k�6GةL8�I�	�O3�,����/���Op42?V��4��մDZq���J�4�P�M�M2�y�-���ӑ��럒��N��q,܃L�~�Y�eL��"����Qf���M�aO0ӮF���ĵ���]t I�zZ�~<����"��٥�^}[zcIȪ����b	�#<��ч���Cw
SY�P�r���,z�8[��d�K��7���ZRE��j:p��NG[����.���z��ۑ
x�n	{�ë�滭����@�ڞyW���j�A���@Č|�p��>�ORz7U����U�A�,�#���n<������[=ءkn���ȇĚ�ͪ�W�k��ʃ>L0���W.F��hP�KL����T�n&b@��t6�����:��P������rÔ���ŋʢ�5�Z�)�}�3�oo�sU��m�6]�wb␬	��p݊�e�x<�{e��xShYh���؊B;�8�.8��یnS"��������&.�Y��c;���w�т����Pu���a���ӻ\E�aRnH��3�&LJ;j��ؐ4|W�J`JYl�h!�v��m�s9�h��l�,ZR����R*��Aeg��� 9�_�艢U��Ջψ&��� %���T�k�&M$n�&#	�"�S��Q�ia�̧L1���b�H����Gy�~ aD���Y�{N&\4��u�=��%ٳ�zv#��:�g�꨺��o�͢4=��|d�r�jC`��v������[_V���6%�#� Lr�S��W�0��	B>��D��-D<E�b���@/�`��Y��{�(���Z�^��ʶ�:3y�v���Г��A#i.�̅V�	k<�A��q�&E��/� ޝq��+Bu�ǯұ�h���~'`G�_���i��A|��'Rh��P��^Pc��`@,�R��Y����OC�S;�!sπ�$%(�����{��e�/���lS�Y��L�BDAa<���-ۜ������u�FF��k������b���ğv|J�/#�l�_4M@�_W87s��v�P���JW�&��&�t�Ɯ[�8�@��Ds������^�l*C�c])�1a�dOb���]�_Wd�r@�f�W�0�q+Ǧ���5��wP�$sH�#���?I�$�B�=	?�g�X� ��֌�c?6*5�+�ų���唒��:9uR��[]So��2]:�Kʾ�|�O%�.d#w�p����I�&�Z�Iv�i����e8Lk�DP�{�O�W�_��vZ���   y	�!�&+6 ����/��g�    YZ