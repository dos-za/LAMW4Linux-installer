#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1805360694"
MD5="78e23c14e9b4141c1a2fb98859bc181b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26012"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:26:10 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
�7zXZ  �ִF !   �X���e[] �}��1Dd]����P�t�D�#��I�`�hζ�HTqq��Q�GC�(��r�J�+�$�!74*Pς�n�nx�����F@�8�[�|ri�������Rj%8;Eh���h @r��c[Ύ�K�f��fA��^3m�Q5��-���=���<�쎣��f�oh�7�	U���`̓yY��BE����T��@N玀�����P�AW��E�i�c9W_�s*͹�s����
��(�ͬm��:�-��Uh��}G:X���>nʯ
f?���;�Y�2�J_c�˝*hl��Օ2���8�<�&,|�r,�a<D��P�5V�5{=���W����O�uEfyaBB�Qi���Q����&mi�)� z�e�	���ɌL�����vM�-�%��Sp��Xv&9jNM�D����>��K�qu=mԨ709�W��a�Y��9(V�X�;����O�j�(���;>Z�:oe��tY�sM28���j�(�{?[GI`c� ��OGT��X!g�d����(fY~êG�&��i����+/��VAq�����hx�[g�������h��jA��Cڑ�t�Wu)����1��܌K��	�K����˕˒���>�H^��_;�զ�y�/���M��idF���pw3ط�m�;8�%p�2���m�g�p��g�R}�^:�=h	�.d������J��,�2�*�$�J���ƅݔ�I?�����A���A$3���|����_q�rT-�~&��`��{���{(�	C�n�B�Bd!�"-t���h�^}t���j^�4I?�: ���2�0J�_�s�С�-���ґb����:����g�Cx�lq����}��Ԃ���U(Cv��J�`�˰��Q(�KMz�GbO�%檟=�Y��*��U��2K�_1�i��
�!��h���U<�o@J��}�bٛ�/i}�rtG�,��eAyR���D�)�3-��$�3G�W�(��-]Մ��<[�P�Ճ8�e��M�I�ML��줯%���e�c]�k�aC��%q/�H�.1�S�Sm�ݬѶ����!Hz����DPw����@}-'p�][��m(����g�Q�re�thUv
y���l�t-�嬴S�T6���~��&jTZ�G�ſ�C�dĽ�|4Ą
>��,��u�O?�t
�K�0J;��7a�Z�za���Yg�2l�8�d�@2x�u��T��w͓��ݎB��:�:��w��j5�� �ً�C�u�ez�u!���)�O`��PI`H����ѕ���[���$u���Z\�$pt�O$u<�S+�LuA��R��v�Cٳ|�=64��o"��୽�>�{A-�1!�zM�v�(���������d~�=�b�$kz\V��7�H`��p��b�����T?a[�7�]Oџ��ʬ�:(*��I�*~��D�|*0 5��� ���t��9���"�6|[ ���b��k6P�]#9��mq�J� �����)���[5k��s?�؞�=�t)L�w�i��� ����'G]wc�9�~���&
���];�=`��fo������&��\o��p|8���G������8�L=��Rf�����}͵�B6-Π����H~��d%�9!_�tf���nH�6�AoxG�T<<,��H��rn��~V�Ή�5zD6 8�6�E�`�_��U9Ai�ѮQa����[�sgeT3�@&f�&zs�
������o.��&y:��Db�A���k���N`��m}Ԩp��$��GF��GH7+�af��D�[_zS3ʟ�[5U���Qa�&�]l+^j����H���S�T�5�FP2��X�\��T��ֿi��~�r?Z�X|:UN�5��ܪ��ꕎD�����ІBЈlvxm7� �E9�b���Gp�.X�:VK3���� ��%��~�+arL�X⳩��ݿvK�ar�H�细c�VǸr����V݋9WS���$�ִ:'Yqtݡ�j���q�
Cb�Ȃz�V�P�����V+1�����7���رc�R���a�m�h�Yؾb8(��Α˩7C��ok���3��
[7���7��e|���	7(�����ڛ�ixƎ�yT��1@�إ�=�^6�1�5 ?���/o�k1��6�P��k���4zͧN
+Ya��Sэ���kTϨ�&�EU��+�=��-L�af�t0>�56�C+��z�f�>,�
�(�i'�~�2�އ�6Q������L(�'*s�0'�m�&k ����%��S��M���B��J�=ЋL}U|+����$a��w4R�)��G�	�D8Ke�F ��`!��F<���/�"N�0�=�M�\3̔���)���'�]��r(��A9���9j6���Zk�9��,���*�ݩ���ǂ�2I4_�-��^������$���*��/0��(q{9�V��f����kJ�m�$�PO%�p��]��$�:=O�}Y�f�����ӌ�8��r@G�j[��~��)��H�}��,�Ȩa���y����n���LK7}SWzd���N���_3y0#��֯�$���pyuUV�a�?u������h�:�h�3�[I������ �о� %B�<A��L �2MX��X|0���!��s'��ԡ����CW ��JU�F��״��G#*������$��P�5�v7;���K���~�m�|vDLw�2��50���[-���&���+®���;�����������U�b(�^�����^�fikm��Ԍ��]�ȍ���H�c���i2��ɚ�r�k�o�X��|��D9	{L�g�|҈ŨX�%�s�2NkdN�����3ZXl�[&q�e`?$�Ȫ�mMq��}%��c��mO� �7�2��8P6���5�0�FCu	�X� +ه��FM[kɛ{�>������$�"��;��\�N�����VzAcVu �� �W1�ؓ���Ҭ�q���YH���*#��> ���9?[6��X��s7���6s>��������?[x�wNŖ���_?0;JO�ď��Z7|�)����c��U ��{=����?�nҙ�� J�éDaх�� �������T.��U*h'"�:R�]�h��t,�S��h� �o
 *�[UmH��p�_N<xd�ܐ�oչ��t�|{=�?>:�]�w;t��6�l�ND��w5��s��l���ط0��&77����<�������쾔�9$�$�/[Q([9r�k���Pޗ�t�xr���S��޳u��|d\��#ܙ\��7��G5i�������7��as�Gx.����.Cs������X�њ�3���/�P)@����s���"�n~0U!�8n��^7D�cv�{R��#	��r'��m|�ֆx��o�p��c�3&N�H���4��j3����B|F*�{4A�����0��4�Τ
R�Ϯޜ�=(�?8f$C� 8�p��
��e���v�R^��ѾE������7�,�S��_�M�0p��HF�>]�~�qX��d�p@����}N�������H���k��,�z����M�>�����l��2ƣG���Ɣ�-$�������l8,���XM7E�����8j�5����b���H�ȐN\P,��O����(�1�{�T��u�qD�#&ax~d�;�(�H�� 	�9�G�:�_y��S#7��Ю�"�a:��'�>�$�@L���G��QL7#㴆��l�(x�ՐS�柊#<���Z} �s`3�P������0���lA�xM��?���
���v%�2wտ��T��w��bP��Od�	
���إ(�P�s{d�L&
, �_�o��su�I��81mD��^<rg�V�_���^���~�M ��|��(@�{Mȑ�n.�^�f3���O`e_캞�,�R�h����vײ����ȳ%��v#SI�E'*�g>�J����`�=+�~h�p���
Ł�wީ��F��$��!��s��y����@��8w�f�C�s�0�}fG�\f���>*~��8��E.X��^��$hC�?��暄��Tyo?�)�e0���/���!4#��z�*B&۹>H�خ\�X�C#��j�CW�k�N��T"B�$!C��ǜ��
/���Ӎ+;�@�I�?8zH6����unW¢"��pKj "��a�)#��CP������Ȉ��b��w������-Q*/q[��4 �Iw-��?��jn� .�	�[�D�jz|�*���/�e�<�!g���JJN�^[}�����q��@�d�3�r��bп�!hIM�.U���s[)oq���:�P���(Fdh3�=
[ �&!�U>1�y�^����4��J���'���M _�.����i:Y�옆y�	��";�������iфW����*�R��L?(<��N� e���K�ܒz�s#^I�?���������q��疕��)4o.�z���j�^�rZ��瓐k�J��!\(�A�M�qN�_ӣ���x{�[�y���g(<]����Oxwhj��z�N�M]�7��Pp��$_�F?�\�Z�GQ��:Nw����ʢ��
7��Reo,	�h�j�	��%kw�Y��8O��_��5�f��zw<���4	l������8���8nV����D���-�����d��@g�S?�K��XܱS�v� �(�"��b�*Μ���K�l��1ݿ J��cl��G�&�U�ö0����vw���g���z��Q��;ro��'��fK�\�:�"��LVW� �
����z5V�ukܚ�iKn�$ǯ�)��M�I�a�p��vv�;����~�?m��a�}��FQ�6��+�o�(D����kEY����-����$��!^�!�{�1�I`����D}�<rp�pm�0�.>Q���u��#/�%y���.�a�5�˥�]��Jr>��0��0���s}
d&/��e�9D�Z2�W�)��hL�i�����E:�˒E�I��>���5+u0iN��v}#W�k�w�O�	��y���ɗ4#j9�ZlY�\O1^P�WPH�/�"����Q@����8�{�B"��ʪ�}d�:����8�� \Ýw�n`���<him���/J�;���d�rE�j���m�!#S��)-10�T���d>�'`�<��c��n��_��cF�6�R�ߊH�8uL��ڄ��UKV(�+g��E$b97<��M*#b-�L��Vm	5u���]dN'��%pl��[�r�vL�ٰ*�� �K�	*�IYG_a� !0V�1֔G�>Q(���xn�f ��4��f���Y�v�C! *ܥH{8r�hۚ�B=��H$9�{�1�_��.O4̺uc�D��m���~�H��iĔ��� ����&�@Oo�Rr��w�A~�b�7Γ��꘎LB��ňi-"N��cӉ?U/;QV���n�O�]�2gt�2d{�,{6��7��rB��\h���]���1`g�n�5FcfMDWM�ў��݅��ˡ0�"pb����IE��UB��+l��C��ʢ��O���Q�f�s��f��{>>�5�.c�s5��5<eԛcԐ`�;�s����y�������K)0�i�%�O��L�T�Y�7���	ml�mU� 7�� �,Got���)N@��T��H�6��T�����ڮ�I'�ҷ��j��3?�?2��ڤ=ݑI�؟(�9���[E���_~���t-Eb^�5�!FW�az`�GU̲Ј��lC&��\����T��+�>i�[�
[V�޹G1�����������B[^�\R��������yn�W/�[/����y��.F=H�\,�
���1���q-��o· ���G��<�];�Y7���A���_y��]�*��$�Ҿ�B}H�;F���V ��)_,�X$�k:�5Q�M8��y�%K���4'���I>,H �Q{uT�AK����O���$Nh�\5f΁Նs�A|��`�gy�AU��Y_Oˁ�w�\
�^��������{����S���\n�	��i@�7"��/�8ǢP�kY����g�mdd���9:��Y�VJ������X�x,�q�#ўi���-�c9i��ɹH��Mf��[·�S'�M� �}\��G���6~��Td�P�芀
�N1��,�IT�.��XVo$�k��p�q�����Y��l���R�a!T\��ة̽������yǶ��R��ye������ޓ)�Z�cQL�q�����0�7��e(�����)�I�b_q�7�
�4I��l3艍�$e���������9�+�9"'�\�(���c7�m�%5I����������]���͞^�Q�޻��K{A���jO� �xhX�AZ�ox��&-������r�BB����_����Q�P�=�f(��/9F�y��v�:)v�(��ɾ� ����.�9ƣ���Ҳ/���0g�dp7C&�߇����]-�^ǰ�զpC��o>��lA��Nu�g�]C�%�q����1~u�S�e$��҅��6�&����UM!đ��㽊�O&Ԧ��޿oI��d�}?�$��O8"�N��C���o�t�*(�V�aXՋRMl�N%�+�8��>(`P��:����!�e��"Wq�:�dO3���$`�&uB���,�g�0���O]���k�ȇi�1��?x?d�u�G��sA����W�Q���B߼�.ߺ��Fu�O�%{�-�Ɠ�������\^�p�OZ�`ً�7}܃D��j�pq�]Y�6<�{��tՁM��},�i��>��C��)�'���U;v��ӥ�Rq8R~FP�`}e�%��u�@0�]Ч�?^{y�����|S�	��s�����D5�h��6^�����@f�v&`	9ަQ=���:0����0޶�Xs�F�L$��YgS��/���2��36k��ϽT#W�� u���}%���p�P��	�d6�\�;��$�Q D��R~`��=f��%����}M��j�����d��$k.��?���s�}���kO�wI�n>�+;v�,v>M�]U�s�>�g�lu��{���������
p�18WYd��A�r�eQ�Z-�j
RZ���D�rH5����M��O����2X�軹�C����m��}��AyMű���t�$�\N��qEp�w�ٮ V��VRW�!S��Dϔ7a��Q-Q����-�1i���:�.�/���~��Q��H��M��{�׵ɏzM�L����!�8N�Ow���|T`Ƒ	�0�'��8�a�(��l6q�*��
N��%��_��~� �#��h@9Үs���F���-�f����g=;
�ˉsAL�"̡+���I����[V0�� g"�͹_��B�'�I���#����)�3$�`{��Fv&�ʎp����c��K�X�>:*��ce�׷9=�9���ǃ�J�|��C�p�c�}���x�����n&
*6��Ӈb'\���Et����'7%�یi �@��6Ԛ�G�2�|����c����Y�ݟ��[[��=zF'�(�</w�@Wyk[���ww��Z!T�ܨ��-��B'ʝ�O�V����*�?/�4���B㺴����B��m^?c���]��\J`��tx�n�t]���}uѿN.L9�ؠL���#,D�X�$km��p�ج-8� �C�������䮉%Y�@V��|g:����m�uN9M��Y�UtN��0�*ԴC��cW���K3�eG�"Sj���-]J����	�mпkS%&��B⫆�^�~	0��F��呙3dcp����nXp�6/��8U5�I8���'��0�D�vckNf`!]��g�d� ���꣦^��3=��0�^����1��TE)n�R���}�Q���. �u��?��ۣ�R��0�|o|�Eg���fO�r��2B��)��;嘱aY�A�\�V�*�s�=PG�of_R�R��ү�tH�I$�}��5̇��>�Jb)�K�qB��z2-�GF�[��Ŋ�3�B9=��Gוn�Ĝ�iH��+{����kq���b�Aӿ�u#��]Y��5�{Ɖ�%kB�g<<J�)��2��Z�=�H�D�?-X�n*9��"������HFF�U3n�E�oF��z�D��-��nBAJ�B'I�_Q�x�#S��L�����#�4�<�Aӫ��u�L<5��x-{`�-�s�p�U�B�,-���P��<
ErQL��������������`O�5$ }G�����6��� M�m|X�g�t��M���O�/+�;?��7en����ԩ:�'�裗8��Z�� �v}A$�OC��=h�`?v��rAC������K������0�����{�v�)�r
B�c���}n�ʷxb�,�m�Щ���)m Q��}x�@�.��}d`�U������' ����Ę:_3*�<<�\A��cFd;&���F�g��]���|θ�e�Ťu�f `���-�K^TI(�P�ҡG�y ֋�i��"��x-��������'��+�2^�@Ѹ���㩔�[<�0I`��(`�y1\��/��\s�&U��ݖ��ǐ�H�67�9Xm��j@Ny���_�d�߱=,)��i�}�%[�~��=ݍ�������N�ū�/h����H���V�Q��_a��<ѷ�A _P���><]%{@N��c�^R:��a��b�,fއ�y g�W��rS���~�!@�I�^�'�A�Pz[�˦;�n�	��4G�W�A��
�5=?b���^�Q��=�
��!p6X�@�;~��ꪲá"�ya��n��Y���>�T��}��y{{�����Q�C�d��m������VMq�>Q<�,��ai�Ե9�uu�c.�聊F_ ��E�9�U��[6��8�0,� 1���V��NلxtT���y$��<$r��΃�R�����|H�hJ5S�.���f��ȶE�Z�^꬛�U�u��z���i��!N�v����zk�����Vӫ�Ogn��Tz�	�vϐ��4�ȅ#�(����P���Pi'f�E����6j�<�{��ٖc;���!��t�Bo���r��l�6���H�ə,�y����Q�A]j(kSV�f��-ڂ}��#"���p�;�T��'7|�_������{p��@�$	�]��B�J���\e�C4�%�;��a'ɇk�_�>�(}8C:��Gw7�L^ ���X�I�>1��c��D�w��ݮc��ҦI��6���l:�Z��̍$�E��Ks��F��^ ��(I�/M|9�Y��l8�3�u^��[�[|�W�zR���/��m�:��9��k��et�̘��.���0}� �q�w��1�ۚ��/;��X���	��-�˵DZܮ�q�=�\�e_�� �0�ݶ�\j��9J&[8mHB�b�l�-�/�E�g�,��w��O�6�S���P�$,}0�2��߳erbv���������?�G,�ө>�4c�{\�;a�ά˃���ifc�>�9R4��Y�I���Z���\%c�V֫����q���&��8���]��6�(��)��{���}�f`8� �ü���ņ��~-ɔ�5��E���?�'o%�Wl���7�嬍O�%�(��3��3�N��_I�K�O��`�:O�����"C��v�%��_Ao��ZS�y�/��ދ(]�"��Z�����'�,�z���}y0�{����0~s�&2Զ|��Ʊ��`�v�'=F���"1��ސ���9�$��=ʉ��wW#/�8uԊ)R��j��DU�����#qb�w]���9�M�$~TK��̱�pXv��e��KA�s�����腫ty��Ӗ��8�J�6b$�嚇�ȓ7�ب�� Z���֐�J#����E��k ۩��7��G�k!����j=�@�R�i��"	�F �~�. ��M>���QDUMwO�; m�)Af��0�9�G:�$<��~�����U�w'��'���pu��Q���^MH��=:�T(W�0��Ƹ"�}�t�t�ř/�̎���5y>� 1++�6�ɯ?|\H,�/�D8nv��u m%/&�R\:@�繐W4�*�*,�M�W�0��Hُ:h�a�����|R޸SbO>"�
��b�m�Y}��ܔ�y�\/��^{2*�_�@P��i���y�Lv�I�^Vf-H*B�0�\����	�|�S�6�%o�9J�����]������#�	�c�W{Lm�=��!W���;�t���`/��8�e��+���F)Rg"���Պ�$�H�9��p�s�T3�#�����=�[l�&�1��U&I!.7y�X�����M��pR�Hm����9Sި#	�1�h^  �NYucM�oOyʃM=�����	��������l}��X.��-�z�+]�S�S-�G��������p|���g������z*��	���}RE�	�M��n����L|3�q�0��"|	�����~���:z���o$$��-
���eё�f<i���]��jZ���lB�� }��2q5At8�=E�K��f}����uޝc-�'R��l�л��Z�J���
tW��
X䊝�LMP�U��������� ��&]�Zrڢ�?�|�����EM�<�w�F��E�ROРŬq���f�B������}�J�۪8��P �ӯ�K���`���~�4@Z�##�m�U5o�z�|�)�j�h�5��1A�Y��^��v}�z5�X-��"�]G�����z�������]��>Rx�����k���
�����kZ[ڱG$#�%㳍�d�?0�!s��^�f2����95�0�.Z�|�r��j�ŒX!4�_�}s^r݇��R�t������م��?'<*�[;LV�:z��nNvs�d@K�(��ڮ*�z��JB���]��A���N���i���@�d8_��G�5zN����9���9�,�����'QJ󍨃�k�I�r�e��?�W��P���
vs,��gHN��d���Y ���{��#5G`��v����c���B�U��|x��9�ph��m1�=�c��	A����Wf̈́2�i/��sĎ{�+�ZM2-Sʺ/E������Z��:Cʢ%L4����Qo(r]�$�o(�6)��Cx䥳���B-����<|��9�`�= ~��z�_C��z�3�*�gI�h�����ST6���%;�w�v���eV΂��mJ�32�õRZ1<��N��ZE(u����E�����ΎH�Q�s#-�o>���U]i����A�`���I�*�^;j�>�Z��QX���ujD$tE�f2�/K�׆ӓ�`��>�<�����=���C(�Q�{���@Y�ou~�Fs d���,X90Y\���2j�H�����*T��7�� ��EGU���f�a���"ݲE�Q�����EG��X����J跈��3R�������n�𠽂�F�Lm�x�T�����rI�7tY�f��Ỹ�'����dn�ap���̨�<t����P[&���;	�8��s}+m�p>e��y��5׭ʇ�zgd��e��&��Z��5��\W�J��-��}эM��E�x-�}�����/��Ӥ@��}��=�ڣ�@ +�MT�;ڀҽ&,׆���x���FAO�J����/UM��e�	F�SB2�U��wg�Cb@�b���w�=�����OJ߫�8�ӭO��b�Gc��_�Q��F$��D�rE�q�������*p�������w�k�^��!$�|B�Z.?��D�}_��.ё.��\�>&��^��A�����&�l�;|��Дk����֎b�0qHZ���s�߆拙J�M�t� ��RQ���d���Vȥ�^�\Ӷ�r�gS��S�d�f��E��H@��p�x+ʅ�U��t\��I,��"���d�\�j�ѯ�ȣ��=����fQ'���K8pS�L�8x��=5#7-
�������5���o`�/��P�-ݣ�)-��G%��e�ɫl�� (�ĪdۈA���H�{��Rx_i��7A���ՖO�����+�0QŰ� d�l)ܱ�lk�@�zqD=��ֺ�K2�~����s�܇Sw��D���!C4��̫�G�W}L���6}��XOm�%��m���z�G|B?����^��)������� ��3���Y����*��쏁�H�%�{�jQvy �)qy_�;���1�TqJ�dZD�E�5����
M��%ސ\���5 �RB&�q��bR�7�r<���5�A~�v��љ&�3=����!,��s�4U7f����V����[�����Q^+%tMAw?��q%�j?��ݣ���M�b��c�[~��c���Ի�C��u:kc�@�e<:�L>H4����!���Ǖ)� �fT������s�=&Cm8��-)��S����*F!tC-��k0�`�)V	���6���-��Z�\Yw`�����dbX4$��}�Ew�Q��.�9�>���{�.p�$�ع�˒��y,Mxƪ�<�oB� ��S�L�?����9P`L>N�N�>�@/E�.W��K�!q���S�_f~��>&���.ٰl�\B5�pM�lM?sO�毷�J����v�������>+!4�;�;!Al���A0�G�|�l�e�����y1ӭ̗��F�i�{�(���l�|Րe������>�D�j�!S�<ND`G��^̙�[yKR�=)s�` �,}�C�^ ����Vmz%�A��B�x����C�ӑ;J���A��ޝ���/g�h����h����3��s���_�b�I*۶|����{뭑ɍ���E��vh恋P"9�$�qv���sm��1�k� 5'mآte��&X�ݕ��Bx� huH����Xxx,�)������Q��kU��h����K1H9j�����=)^��#U��aZp=��$�#;e�&Ar��ϩzz�d��zr��7����Ŧ�2���~�r  ����f��p���-~n!d�ؽ�uǁɉ�v�*`/�o������[K���V#Ya�'0o�Gg��@��+J���a���P�I�F�� ��Nd�
�D��-nm��e��|<��E=�س"pF�_4Q� ��IGT������R�Bə����2l�[ݽB]Q�fQ�����!)�N�QZ&���l� |>�;*B�b��P�p�yJ99͜=+�C��?��d/1�Z��e����
n�4W
ZRl�,��H9�W�����mq�����(�,V�ȑn�t"rUs�M��u��m*b��W�~M�Z
��#K��°�TaKݮ�ˀ�u����t�ߋXݽ�m2��Gs�L������OE)U�{��06�qbs���;�+�≲`ء�n�˻����2�G��(�ݳ�H�xρ0��|
�_������/mҪӹ�:ǡ�XlG���i�C��L��$Ǵ�nR�Rj�U��4hۭ�e��@ꔥ�X��)&�8����F?���� m��3mU����Q��]mT�|1}O �K@M����m�Z߁��	����*�l�Д�{��<�!l)c�����)�j�*��v'�F�D�: 	��N�:x���ƷC���\&v�i���o �&�&شokw��9�>m��$`�L^u����R?�9�N��� ���B�biF9F!T��O����!͐��3P~����Hb9��N4���'�r^㟂��L&�L!2�&{G�A�L`�G.�C���sC���H{G�����*_�K�d��f+�C�Y�wC�*@�L�t�B�NS�(��wt9jd���_vgnV):������_��A܂���T�9fH����9���v����'S�s\d�PjW��K~"1V΁Z<�W�U��bp�m���98���;�(��lƫ�%�i���G�OM���B^�ߺ��4����X��KB��_��$�d���o�-��o�|&zc�q�~������������������_�������oo85"�4~]�K�th�U�ll��P��Cא8�Zv��㫳�p�ڷ�}�h"��S�a�*���O�Ջ�Q_൵?4�V�_�j��i��OG�1%7U��jy�@��*�b��ڤ=3�ۗ�����-b��B�M0t��̊ܶ�,� ��;�<��ވ���
�m��i���t�k�G�wn���*\z%�;3�kn3�F; ���`G�����⎃��e�4�P���tZ�/d�+�Q�T-'�kf�.����?��D=�Q����:0�y\O��w����F�PE\g�}�3��X �>VRX�m%����L�_�ߟ�CI]�&��2��T�!��9��5?�LԪ���I_I �eW�>���<:y�P��f�q�'��#������;ˁ\�\yy�Gu���9�9�����Ѳ���#�hA'���n<�ۈ�A� u�֨5AҦ�+�H��"epQ�Np���3 @�TKMGQSH�^赑}��і����D%��l��ݒ���Wý|2��G��7���B��42*��$AE�����2Q�@6A��� ����̯�QR����h��&�׍֘ضsm�!�g[��H]��R���M�ۂ$��k�pR�"J�(}��A4��j��f�&lO�������^ɤ�����d�)5Z���E�q"_?i~c�).��D�W�)$j���ɬ�Z0�,>�,8�!�M���_��ɒQҒ&֥*b��o��n-�]Q|�=�D��&�w��l�%&.��WF������j�Q�!�#���v�o�=��w +X(�0px1�I�7Y�V��QZ����x@xb�-��N(�lɧ�/�A4	��h-�l�н�ZZ�N����������i���<�v�)�d%����o�Z�����K���ٍ WT��e�y�^��%�9y$�+@l��q:���A�8��5�xTU�N�MH��G���i�4͢o�|�v2�hY'{�;�@�$�����zA�z�0R�_o_>�.���Q����&��w�!��Uc��-t�:m��!�3�X^#yT~�/j���`͊���S;;+����@�Y��yv�nā�L�/���eW°u�w��:��*�$���vą{��*���E�oJ8��p%G Υ	�Z9k~�H��l�e�1 �%���}dL�B��p4�(K�W �XZm�g�ǍU�v�]�T���7�y	�a^��Ƨ9@UO�	����а��VԜ�G�!������1�+ڜڭ�,�r�RXD�]���q v�3��p��I��_L@=v�/�����UM�y�KZ~x���pwy��8�F	THoG��ڷ����~̹�%�*�($��H͠�	�G_,пڄD���"�5 ���Fm 	���*/%��dt�‧F����ۼj�q��or"���۝��1 Df&��x@n�y$����x�< �� ]�C��v(�4D�H�I�ߜ���.:oa-�3�]	��X+RG_������9`�&���\jN�������a>/���e\>�1'T[,������8sH���q���q���I�/a$����N[u-3��>�h�&���8������I�@wT�r���H)����K:jpTQ�V���F9�t.��𑕛�}p��;�o�	r+����ЫJ2�/�C�����z2��a�r��ˌtM�"���"�@����$��C<�1m�r�ͦ'=�{ʷ�d�0K�)�Г6:���@ġ�1K�C����ւV4
������Kd��s�����
��%m{���C�#��t���6gu�T����5��w)���1,��p2����M;y��,K<C�sU�y� &@��@�ԯ���w=����;��fp��ń[)�!���TNa� �Jy|*d{ȝ�JE�����LƵ�}<���doY�6�G:c� 9ɵ��k��J��gLP- ,-��4N�*�w�ªI��Ns�pJ;��Kn��	_O2pd�6+�{�N�L�)�)F۰A���K��@�Z$!����%�`��K1й������_�O�px�p��p�U��X�Rb��>�A�p�Yߐ�����2`��/��s�?_��K��b9����䤶/��c�ܥ�6;P�� -�ٓ,^j3aӲ����Z׃mȎ������Bo�n��(�_���)���֌�/���Μ_�(yX=���S	�!��e/�n��:�_x�-�JV�K�Peh0QVS
g�/�K��j���n��z����3 ��ӷ�=�Z���Hβv ���p�$���ˠ!|�h�4Xy;�?�O��^�ֻ��^�}(E5��L.���� X�<�o���k�m�o�ؘ�kJ#}�YؽĆ�(�[���|�'` ��P����[�Mb�s�H�鹿|���{$r(mN:�T	���1��(�=f����Ex�$�ӫ酚�ʺ�aq�"w��8
yUK�okXS���$�u>�ﻚ��]+��{�nW�*^����6�����6��. |��Za>ʸ)����:�8I�$��S1%���9��E�~��͡m��Z*ͅs�e��/O画�%'{�&wD�6GZ�A]n][}��NnQ�*=���A(��z�rbH� B?�*"0��,�ı��WT�)��V�[���d�J��:��3S�ݙ�ni!��/�Od~X��֜�88%:�������c��)$�d�����^�);���Ȇ_A?���h�x�t��$�_?=��;�3�/ob@L��
�������|�LH�_M�;��+�Jk��ɠ}V����7Ñ���K�Jn��Qx��I�4�������i�yS�N�Ӓm�a
��%�`�`6F
|�?������$�F����z��
�m�5�f�|�$
���1thh�@	�+E�$փC�箏�� ��m�D0_�ct{��0��}�PH���3�a�n��[�7OWo ��1���ƒ�Y�V+���8�Ӱ�C�	:nȍF�4֥���,�85h!�����K��;5T9�]����T��D����cΗ��
:��V�&���MI���P�V;a���p��k���H�X�II��AR�;!�s�I��]FT�1(1��٨h���n!\7�f,21��[G����D����7��
veY	�S���7�X�_�-WǄjP9.A|;�_!|�e�%�"�Ǹa�V�@���ؾ�I���pK��>�R��w�FlJk�N��e:X�?n0KFM=�j#��(����X� k��GB ���s6I�#<t�S6[@���6��sx���%�����Wb�"��GU�r���5<1�i�qX���G�r�)�/k��'�@����b���H4O��x�MKרy� (��Nv�ݷ����05���FI��~w�(o��RB3АL�w����d��e"楡�,�^�'Z��t^�������'v��g�r�Fxj����wh��e@��e4���R$�(�9�׻Sׁ���V� ���gF�C{�VR�� 0jz�^��� 8V(ri!��P5ڞ�c�;���ɽ�㗁��#�<-=}��YI&����c���C���@Jw��	3:�c�=p3���3�w*��#��l�]�iZl�HR����(���agTkH����]7���a��O7)��H��Z��Ӂ���t������WR���;۱���ȩѲ�xC}M��'����25�v ��y�#n�<&.�[�ѷ�#X�V��z�ÏdvX?�����EC=K�R3���_pxڙ��+��K�^cM���\����yK1�-RĎ�kpc��I���9X���hxR8��4u��j"0�h��I���=%��u�Oƅ-��H���,�����5��,Dm���(�qw:���<�3���΁���Hk�c�Fqs 1e�1W�߸�*s����
�j�wJj*�w�;����=�4qXw��`�)�f���-Vq!�&{rSU��h#�J��꡸W1�{��vc�dE��'��gY_��hם#�#����I�y�W����m`���������5c9g��j���]��-� ����+��k�m��hU��f�'HO��
q�t�{lqIqGNg���9)��ţ�i
�S��q�@���­�?�^sJ���$�|L�㪀��{������!Q�ij,+RM�A�b9wd2u���X	EX�p�ǵ��'Q��/�8]��*�?F������'>�E#7�n�O�a���Sd�G�@"j{r��ϻ��$�����Ε��ҭ�k*2eq���ݏ�d�{�K�N����p��A�7�h����:���7 {�)?,/֣ �>��:�*��i��$3�<���^��΢{�tF׺����
G����ip�]FtZc���*��؄���x�O�L�\��p�0%�v�z��S5l�}�kI��w�hN��+���^q\�F�c�_
��£���7�(Jێ��0r+������?�P������X��J4$V���<��ixR�'q�ۡN��B�@	Ä�� '���h��I%.�@pc؃-��r'��y;�*j�ehdc�#��o��)Ntf�D����Uӭ5�J�ѳt�<z��m֗�d�/��j��+���\bSc��ʌ6{��� @"۞Ag:^��l�A$ܔ+�ܰ���A>_�݅�oT�Xx5E���+���=xC%Z2=FRn�I�������,�s�����	>86�e9]^���h�I�ah�)��e�q1�mI����|�����K��-��K��ʰ��Qe۱�m.C�N�xm=�(u썆�ю���C�)l����T�v���Jj�}�B�ט�[���u�	�l�7�2����]<0&<j�Ɗ���7�Qy�1��ivx=�����!��+�v��>Jy�aKoꧢ�LY�����i���`��,�oH�1��8 AgŤ��#��,�
v+̸�lmn3�0>M�8I�p��#� ��@߉U�ȱ���?v���/bRyl-����V���E_����e/N��Oj��σ�	|F�r=����XS�1��0AW��¼ې�}B֦fڏ.rW~DL�S��鍢m~^8g�������y��-����"��5�va�>z��������Hg#��d�M� b�kT���Q�q�|HXW�����j��壍�OÐfS���"���7�)�lE6�l$������M�u��2:���f�V��Քf�2[#���o)��_�+y��-����Z�Iw���`,����_��Ʈ=�B~��r�b�������U��+GӦ�6��M�)n�B�a]ʵz?cd <~������HP����:SDa�
���=��ct=y��
OMً�s.��3*a�+�x�rfNb����1�X����/(��+h,w�qEP�W��tV��~Cz5Ss�}_� fm�g�j���AǏdO`��-Ǖ�?x��{L˼f�e�ټP�S��r�94�Vu��a�����1�5�qR���K7���v��U��.�6v����h��S�X�R/brU���Ñs	9M�Q��:�8�E�k+�D���](�Yǻ>�-?e� l�A����T�+@D9l=W�AS���H��D?x��5w�g�p�~ON���|��Fv���E_�.R���G/�2�%��ƼJ�r��a�G@��x�|��B���p�{c��ب?���l�����i�p
��u���1<���A*��D�Ċv\��u�D��;��)$�I/D�b{���lX�8h *�v}g�\�pVOJ[ǀ�y4�yQ�^��[ �^���4!��:5�b��Q:8��:/������X�J���3S	SP�
�d<*@=p�����r1��F�&�����Qq+M�x1�P��6��K��fX~�
�ͬ��Y8����xc�H?�!2��M�ً w�+�F��>η�T��b�ѹ���?G�~���|��Y�Qn�u���[W���F�嫠�6'�D�
	o�L��=��g�_�����L ~�v�k����%Re^Z��)�����/v�c����5L��7�`�U�	��+�#�N����|$�2� <�Z\�{��=���C�0�����^>n�ϗQ�ē6��=����EA�[�*�H�8��TH��P����0''�\b��h��)2?P�p�Y��#F�g���>���^�9I�l��Jn�6�`!jJܮ}*��w����h��6�&Se�Mb����??v7]��Ժ���!��OP6<���Ѡ�� �SL��~��M2��Wex뙶Awȱ�����lʑ�_�	�h���-*/򿀧�Ki~����}z�ØC^x�Y�Ǳ��e�* U/��~4+Z���ﶊ��3�l�����V�%��5�%����t��
$�:U�A���ƹO�ڱ��Q����(��M�GZ�f��Kpx�z�\��s��;ZF&M���\T	��,�2bP��2�]��p5����w��lK�#�rj��cg)FFA�!�bk�Y�	���E�M�%�\�"�E�5��!C�(T,���NU�\!t�]�B�������_D�Ze�HFHw2���΅\ӶM�>[�!��=|<W�а�u��bC�k�&�� 0.h�����ԥ��J�}������0����RV��m���J\V�@Z'�N<0�H-���[gs�$]�b��9����3ɞ����s��j���O���)D\j��&�ݟ]%���������"G�n��W��d�v��2j��6c�9/���d Rۼ�O��
m4��
��)<�#K�������[H�k�)+�X��Y�v�a*4.I�3J�N���#Ld�*���/*�������X-�Fr���
��S�?)�$q�j�4Ti��ȝ���G��_p;�
�5��C��?��bz�m��n��p���Br��g7K��I�"�,�

/�8ƕ���koR�n5fS��U�����@��W<�&
�v��Ib��Q�{@��ͮ��o�C��]qM���g��������?�((��{�$eV�&�ꆁ�6�G$1�`���b���P���_tX��Y�9�z��@�傹 ��{|��G1 ԯ��/��C�^Є}��Y<>D���������ઙ�g%ˤR�.�2,}��Q���(���ҼvF
{CH����Љ9��7��հ�2�Ş�|h3䂼m�N�!-�㖄,��E�)���]��	�@a�%�u�����2+����AO��d�Kc?d�^�٨��Θ��{���uMJ#�.�O$�!21$��
Rb��Hp�;ش���֦~��=ޠ{W�y�'�=�[��ǸK�|�ڢp� JI��r9u�N���t*C5}{=e����~�Uv�/:H�.yp�vF�섂��Mh���x� �0\�C�yo6t�?�~"h���,�L4��B��&�[���	�i��6
�J�� �*>�_L�KQC���4������U6�ͫ����L��ԝ����x��v�`��Y��Y=$��]�[��Fu��}u�:^���ʅ�7�|�vi"�۵3�8�HW"�B��U'e�*ԪTRu8P:X�G�� ȿ��Ec����4�$%̀���Z��TC�"�I�pn|�gy�t�@h�V/��3�L�?u���_���	C.+oVHӓ pp�֎/���E����q�5�[����o���r��7!M�{��9�z���"���VVqjF���ӡf6_(zgҫ��Msm+!�v�ñK��5��L�N���/��k��w(6K�D���ѧ�*rͼ��n��	��a�ס}p������&tl�&�ښʾ�jΐk��$�5~�$X��E27���mq�W-,�ם�K�19=���XsϨ��a��+z.'m!M����ּ'Q�+�ZP��P�'n����W/���H'c�F7��P��%<M-�_��}	s4��ynӾ��v��w�e��7�I[*�'�?�>�DH�Jhb�=__c�]T���ظ��_obo(�!oѝ��ROyTֽZ�����~ �n*\�>�>.PSߐ�%��K-�yB wQA7u1��y���@���S&��r$�;l�f �ʈ����K]�o���h_��f���.1�O�հ�;���fЌj�(&�Q�c����mC�q�r��@��?쎲͔�ӛ���j�� =�S�~�*���c���D�l�)�ΐ
��*"'�OM�NVl6x׺�k+@�q��j��|�T`TkX�3�IO���hI	n��6�LلФ��/6��p7�����w�ߝD0��?��س����_�';ߨT���5F�r����m\JD����ݩS%�K��� ��:���-�����B�+<��?��N�cpaV62��'��`�o&���T~�M뙕�/ ]�1yh7�Z6F�Ҷ�:��+3ܽd��a}�R��Z����M
W ��/��w	��'�.^y��Cw�R��:�C$#)ĊЀ޾O��E�i]}\Y�t:u-ex.b�~��]�^z��a}k��`(0��8d�E�@c��T�Y5��9=8I�5�I��iB�[����y�:��E�k��9~~�_&��C��5�P��/h���H�@�l\є�1��妜�������e��Z�9���-�>�����p�}{�����7�#)��\���9ZF������*�q՛�w,�I\���ˣ8�-�l����k'#7j&�Ƃ����e��L�˗�q�z��J�3�	�^JP�|�x�safJjs�0[:�(2���_����݌�O�^<a{�E�V|kԵ�K��u�6ECMM[�hx�x�?T��\���K��z,��!��k1Fo���/o`���;�ͱ݆�Ӏ�!I��+E������/̐�~����s9h����Uf������E�y/��b)&�É��8'�Ԩ��1[Lg �F��m�w�.n���j�+i���(�i��g�t
�v��	 <���߆N��B���+��/�!6v�99�njht�ŎY���p[{1������\k�S;u�����)e�FNw��'vT�)��x���م{�+�ƋS���X�嵐c���K��ܑ��g4\å��{^]���ĆP��&���i����.�t�6��/�3���:� 	���V�Y��3M�m9�bu�t;O�>X�I�pe�Q�\�Ԭ�!��H
֠��&Z��W^�P4�-r��h�+d�I"��E��՞V�2���#���Q�+췣~
0ZD��{�Ȱ	��x4��%Lp��Wj���`1LI���r�dg��pV�¥��8^�K��b��<A���qN�/ew�%!��;G����*R�~K�7�:f�ӊT���Tȉ��pD>I�*z�g�������^�?�
AT���Z���G�c��|����P�
n���|�r�����1:|ݹ���^Q�>� ��|:.�����m�*`�8K߁B�%�����~�cL�
{a�,m"�K`��A��`���eÆ�a�௏� ��6��ñ!o��@ސ�`<������/=.��Q*��/�������&���A��=�)YRK}D��CY��Ν�O4�|���cN��jw�_�<2T�~�h 2������>�ؾ$���9�e?ўĶ�O<���@�Sϱ�(p
��اE�fW��TÑ����rW����Q���׍MZ,_"�1��)��)r�D׀��;;O��g5KF��r$�G�><��"X�l���@�*�b���޼�Q�9M��M�?Ձ�L�ՏF�X#�! YƬ̲�ֶ�4I6^R��c{��:� �=e2Pq �|az��}@w�U��#������w-y�E�TB 'b�Á7�Mc!^h�+�:~]���aC��!M�SS�t�_#�Uk����ߗH&��x�l3�ҫ�;Akn2f�hp�M�$@n]|�maq��D��#6���R��2UJqD�[�k⾚�.l����	i��x����*p[ྈ��xk��]�V����υ6�����o�� GиE�XJ0�q?�A��dΰMKD�[خL�Ur��/����z �a��֝��C$�2�a蕋W[�����ӻX�@>�n�V��+�u�m���j�q:����� �g9m>�]!;�S1̈`�@	��Սi�biζ�+{ֲ�t("��s�'��(�H|���P���,X����
�O�\�":;��9��:S+�^������!	8�ԂOs+�Z�i��ʩ5'�~�D���-��";w���b�J|v�,Go��m��\Ȱ8�R�q�)N����u��t�l嘮��u�l��rK3|��13i[��u�-��"��f�WG�LH�nG�� C�!��s^�7�5�%ٴ�*w ��ܿ&oL^�t�1J\3��Yg���q�OKI�;0L|�� M;���S푔N �Tk�b�vxe��D;�?w���᱉pl62�g�c|��پ 8(--8-��=!c�EJ�,�)�z٣�ߡ�i�\6�hs��"d��18�!
�i.��p�Ǆ�F�d}f1Eh�D���$I����iC�1����c��XZ����|5���ZT
w����������_�_��/XB$-����t]�6���X�}���6U�r���� G��:��o��n���|�$�o�#���W��R��	���j���^hr{� �Pq�z�cg��hB�m���I�-� 5!
G�"b���a�:m�?(�	���M�d3�K�[y�uZ}Z���!ݲU�A~�1w�M�� 5��}7F^�}fA�|���JWSd ��UFH������ը��]h��G�r�}n�8��$��@=��Z����#^ �s�.>GD-Ɉ��;��_;
-y�Y�'(��&�5Ex݁�M~㲡�Z���k(��X�:@�wl���߇����%{���?�
�G�#��?���]���Z�[e�I��e]�����p/�����O��h<��2��@+L�x������������T���I�lc�k�Mi�Z�cf�Medk����sOk�ʉt[]���KD$d˛��RF=���m{*�GE*!Y+(�}�`�	`[��h�
/��(2�m��^���lbGK'sOr�G���;�4���_I�k:������g�zV��2\���kb$�w'�F�'*�N��`��4�NY.�N�Т<����y��2�a�C��hzt*�k�2�����]��j�$",2]y1ȉl�E���+L�݄����N�ܫ�1f�,���u}���[+l�Ã�fj��F�Z�F�-�{Z<�iC���HZ$��[��P��+>J��A6WN����$�gp���eE"(T�[�v��|�J>P���f��i����������V���+IM��q���;e���l��n��_u�}c��=c����N9��k�0�D�,�0�?��ZXyu���2	&:N78rt��ω@�~t�N��c6�}������X�����M�i��܆��6rBޗ�d��*\��`<���x���d)���m��%�b(���5:��^%�2CXC�Ӹ+   ���ңg|� �����stN��g�    YZ