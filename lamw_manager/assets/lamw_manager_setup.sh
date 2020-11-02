#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1077817045"
MD5="75529a00158a23537ff4ad69873b3cf4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20324"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov  2 05:08:46 -03 2020
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X���O#] �}��1Dd]����P�t�?�B��<�3WJ�c���kD���#63�QK�LR8�{����@��6�)�� ���������@��za�?Ӭ�D#hw-�7!�.��B�_ݤBI��Q�ϭ!�d�� �+��$���[��S�����T�.,�����;X���������V�vx;��0Ε�_� ܝa ���*��^q� ���>�N���{=u@��0�]h��@_���';��J;we��5�a�ZbvƬ�L��Uo����sB�]����`5�5�1g,��s��~�@tN�F3�cH������ya/L%BG�x��'8]h$s���|���s�&��4�/8ˀ����;���[���m_��u��]�r���<Q��Q���B�&��t/��;�d�G�U��E� C�g��6q�Y��+�H�e>�>�]k):I�&��K�/����3_Vc�1��wţ�!׍$��Ov/T`_��5�ׁ�e�슆�|Cu��KwD���+q����_fF��h[c�2���h���@����@�n��[�� J�=7�(d�w�&L�G�+�̲��|�J���^-F0Ɇ��95%��)����0�n|oV��FM�Rňn����������|�i�|0�7��ԣu���Cu��L|K�\q�U�T�	Hw@4��^�=�����E�H�F��c6����\�6�w�g���u��.�?��6�8�=�L�1c��g�0��v�]M%U4�C�$v���ì�%g�/����k�w�'-m��誡h1�%o��)#Vp��9��w$,��I<~�&�~�W��]j$�y@�`4�.�E��v�����
f|��+���B�ql������ͅ�A{�R������#c��1)��E�x>��}HT��#�3%}f[�0�kU��'t� .�v�L3�#�
n"�IK����o�֋����:%��+l�3Ɂ��*w�@���~
r�ϑ�.�5���+�f#|���JNC���y�������>�CR6M�y�D"w������F������}�@��M�?�P�ZZ�lR��EL_�|-��"�bl�⩔v� 6�Rmd%�>��(A��o<���0{x�o?O����t]����?Ù����x�y%2���в��54A:���|�g;�Z�� ��2�U����`��)��^�a�%�'#��*�)���{������l�O�0��>j-J��:�n��@���{OXο�l��.@�5~t��JeOS*���gh����.�lM�e�%߈2z�F�\P���[�g�7��LYC�N��/>o�Y�a�P�b���l ���i�4�=t*��B]`�6�u����?
�O]�Q��7u�Vi�)���x|�����&hY�/$wԷ(�Ի7�����zK#���O�\����fn`N.e�/y�NG�y����L�#�I�8��=Ҙ*�y��{EU[��e�;F)�p白�Afq j"���Hr9J��pUq���ɒ�`0p0��"K;��ux�Χ~e!�q����L�����!z�ǯ�B�R��PF~-#Wr,��C�X��[������0�S���ѹ��i�Bi���-��%c�]`c��H�m�_�ԞI�ކ�*�QL��#��"Q,D,��9�Ϸ��~�/mhT]�*�|}Uxt�� ��. �7H���C�pl�8��k0�͓�kUu��zS]�������-�ɗ1F�`�m&����L�K�U#�B `}��0^Md�z	�l`>J9�gި�ب�@�9��%��������ˠ��;ت�#���Z���,a���`�B�\�b�h�A��|K̟����b<I��t]��sG��F�#�vm�3�}+�c%�80�>H��U�N�G$�a^�+k�,��{��会�.�N�����o�4��T�X]�BN��_���'�!O��.�d�Y��V&=ݭ��Vc��� ��X���Oͣ���?!I�ϗ�<�#ص�K�g��2%�h�z����4�^k�|y�`��a�4/���ŧj�x:@���8J�������Ύ�����[�{S+P��2í�u�	7����1�`%��}9�h7��U�
H����e�;�<�y��^��7��}�w�,�˥�f�4ޝRQ]�RLE|��O��Gx$:_8¯UL�lh�@�s��!~Zqז)����jg�@yjy��ٯ|5p�^Y�NX���������1]�![�+VY�_�o�}�v#��� �~�o����Sj|e�h��f�a��_`�g����V�f�O�i���3��(�����n@�GW�����x��Nҹ@��/l"�l�|6�����W�C$M��K��TFD`鲦1�"@�.z�L��P����8�7��!�`*x� �&Lbn��_w|���;�_��K�-q��Q�i�?��.!��Ƞ�����]<�>���cb�����.�,=�tV_���jE�=�b�w���x�F�q,v!��R)��``%[��Ju��X,s2p��l���w.��+^�mᦱܷ:5	�L���I����Dx�"���r�ڟ�����Ӥ'�.���;�+9@/��o��4h��$#��,P~�^M��}i���UT`��>�;�c���J6E$w�a���&tF����Y�bj�-0QKa9�ܙBHĝAO_	�dސ�v����G�����8�vw���r� }/C�'�M$�W&/���S/��V�=�) ZS����ڀ �|9�	hP�kx�oIl�y��7X(�}ԯ6j�$�/��6u��)}��v�����^�8�t��f(ť1�3�@��c�bf�$�� >{|+Ƶ�������WE��\�o{(
Y&
�&�Ov�ђq�����$���D+3i��+Y�s\;����ᵯg��4�X��������;oQ�ũ�@Io�U\���O���M�~`X��;1���e%8}�q��Ur�,�p��i�W�.c�I7��7���a>�_@������y�W���G���ΐ"}N���Dm�e��(��N?��C�\�6�*,�1 �6��=X��(w�@G�΋�m��P���@�N�����pҴ����w�Q
:�q��k*��0G�ӻ��O�?&ׯ=�P�>��n28�����}�t
�!������J�Y�V�G�w��Ԭ�ߑh���g��.�Y��M�'�\�3�y@M<`I�Ɛ}�W�¶�2,d��1X_����i	��к�&H�����y0��?�˯|��䄨G�+Kc�Bg$���v�9����$!?6����dTr�2V5�^0v����|]k���>ԝ�.���A�6$7"3���Mf $�3�\��Z��A)�_|>.cd�Py��sKjV�b.��#</���9��pg�n��������I�oй����[]�lb�~>�����M�O�1l�����^빩C��dw���XX��8 y�¾V��C��wٖ��v�8B�ޚ{^q/�F�ki��JE��>l��j���*��c�/��7>��}ƏM�����|�Y[.�@p~'�)٬�m�3�{���Ś����,KX��~�&1n$
/U{�Ʃ�Ķ��d�UT�ca:�Jx+3C�2��kec�~|�w����� -���{B@�vNϭ¤U����n����b��`�+�������Ȣ�7	|�oj����JCs�i	�iylyٳW �h��?�]�~�����K�bx��O�Y��XBZw!��|�dh�R`�U1b��P�+�}�lh@�����"X*s��,�&H:���[�O<�u6�g}�/�'r��@��y�tc�ҫ?��~\�%Qhq����:R�W���қ�?f�E�H�4i�NŃkfs;��o:�,\�!Xt�`t˙E�����i����ᒃ�P��M�=�LC�b^o�@�ˠ�P-<#����[X��]u�
���kF6[��>�s,�N���h`� �;�u �� ����GqB`�2FcQ��?�oaQQ&F�-&2wU@�Z5�3|�;���J����b*O��=��=&�9�󑗺ړ[Y��b�w8,��g[rZ�e��-�ZX�]�b�"g:��O$�X�hC�[�1m��yE�e�D{Z��E�2/F�~"T{N�����e��&e�O���P�*�*��ӛ��I69�=�A��]�lD��qx?XIB����>o.�z%f����`_�2��?�c�g��:��%�C��n���IfC׀��r�n�t?nr�;��{ீ�˯EV�����n.S,`�ӄLm�� M@S&�v�[7���%Q	���% \�|5���=��1�B�T���l�s�r�g�s;��,ٱD��sv�U�8�Frxē�Db{����!��t������-�ꉐ����v�P�*��� (����1W
�]ӊ�=���	�&S�`��\p (�5-�j��\"{x3[)R���'��S����h�]�9�B��֯��g_O|A��8&��f*W[�C{��н�������Q���(�O����TMekl��ȗk0spa���!kF�6i�Ey\�u��A����}�! m�uip�\�1 �1ÆF��.���a���T@	��)�G��!��<0����t{i/�[�,�Lrc*�v�_.
2'�����Bؽg��z��J�~�=">�������0���n���&1��'�4%A8�7�h����w>8�o���*M�¶�� �/��}��iU���7g�����OS��V=:u�7� ��e~��l������,��&��z�ۊ�~<��ue�z�g&$�\��Pq9]�����n���@D�%��g������
��;���g�zM��P�L���m��~4b�����뎧N�t.�" ��$�X�{���-���,6�L���C� �$02�?�a�Q<��w�
�璽����ב�#�ax[����F"���\�æ�h�� �����F%����fJC]��Y���s&7�"�m45�hL�:B�|��m���эs�>����p���]!+ۨt��1���R>�G�f{��cEA4��C��"���t�t�;��g��1��ol^#����X����;��"�.C��`�a�F���6�{d�?�N�!q
�#�5��t#�����Ѡ�)�+��~������ ��$=�;',I�y���	z�7�|��W�n���U�@��H�rX�EStb�M�$���8���J�O�b��X~�	�ǽ�/�ז�Tqoz99[�$��?*pQ�����X�:���(�O��Kb�mV;��?ߑ��񸻉��P�|m,�A�E�b�\�T�g?m�p�7��B�Ʈ�X�&�?�EA�A3�h��K7������9U������X�ej��p�Nf�}�m������$�u�E X�:���f��b������Tm̸m�[�^��R�GM�p���r�Hb��1ߋ2p�ȧ�����.�z�aL�kU��+lgK��>�O20mh�9GU��o����"�{�j���0k1�X�k��WS������[-�6BJ���ZD�3[4�����w�QG��������o�b�^��B�=_ڰH�:�l�����'D�d ��3���V����K~q<ւ��3�l)��'2�M��� �J�,�:�(^�7��8w�m05���bl���g�VVؾ6;~Ԯl/Y�VU�e��ãe��	� ��u>�s]�,r߬�4�����DiG��Cޗ��#���i���|���vN�1�y��w(�͒�ªp"ΐ�u���޻͙����L&FI�[Gm{$g��Q�K��0L.�jN2�DJ�bߦ)A,Ī;;��Ie#$�ȇ(0A�gX��1�:GuD�VwR0��#�
����%���7--�n��yI9]�P�l�)����g�?:����w\4��}LunL@��S�T�/=ѫ՚��VQR�6L#��Kt�)��_�ե��=:�S�b��R(���ǁ���^d&�� #
5 ��_堟Bq��=�Z�����h%��/�\�Ξ�7����'�g��74ʬ�:U���NLF����K��D�oI���F��S}f�P��(%�>1���Ȯ`�������}��n�D,4�*8u�t���G��F\����\�Q���O����vXE��Z�J��w{�d'�n|�ނ9�L�F^yg��<:G��K�f����lO[�&�\{�e�?k���k[ʆ��q`{N�x3�@���M�H�#�'WW�>|j�,X�SIf���8 �j���B��DS�;�x R.:5�	S��w�Ka�K�X3���Fs��:mij�*��=S(���}���8�~0���Mo;eF�y�� e��V�c�3q�1A~/��Wh�oO�vW�cD�]�����x��J},�����^>��A)38��i�c�JDhcX0�Mj���s�c��ͮ�J�~o���C9*5�a�����_>Ա3RJd&bd�=a*�(�?�+Ez�2��r��ŭAv.���v��؃��*p���a��m��V�����m�_(����3�	�Ou�MV n�]Z�<���U�u�����O>HIX}Α�_R[����`�u��$�k��ԃ]��	k�
�eZ9�`	���U5m\�^��8q~�ry��X?N�zg@f�[��2�uo:���������t����E�^9�C��"w&.A�	�%����O8^M�8�]��곅Ky@=��h���ZY���@��^d�x����[��,�&�k!�o������r,4�_X${�X��|q�9��:"�/���Q\��ڱ��i�{X.��]I�(�\U��#�I`��?�h���
:�9�v�yOMe��I�s�42�����> �Lm��K�y8���j�� ~�#rK�I]�/*�\;��OH��^S@���:�ы�>n��*�w��}��k�;��*3\����g�z V���h9M�"�4�.��~��e�����
C�q�n�l��6�6�_�=�DD^��p\�-�79}�;j��T��KG�`y6���vk�b�q�13��}�uÂ���>i�n �_E'f���u8����{�rSOu�+�2l�ޟ9�g4�:H��j��=/�S�
ÉS�����tWx��\,i��f��6|/aɔ� ڸ���|Y%�%rr�"�URy
۟�5�;�dڜ���N�N@��
!���o���Y�c��ȚqHs�}iY��#�U�q���!A?v��K�)����U?,4I�Y�h�ua�+�����y&\� ߰��^�kn~�E�ȑ�:���膾&k�@��jk#ژ/"�'$ҵZ��[3�W���z�Pmsj����3�)l����ck^����Ҝ�1����N<�_ Qя�i�:���=Q�2��ޝ8�G.pƴVަ���7�<o�Ɵ\��l�Bw����<�J���Ze�,q�g�)��ѩf����k��#�`_��b���/�A ~�Jf��nn��# bN��/��*�=>�n���L�Mc�L��f� �^�*��kf LL���*d98�@�,ܩbs"?�!Z��۩��q�B?h���o�[���d�@�i+I��
�O��+Y*�VPӗ~��Cf����y�+�Z\`9��3�V��+T;��X�Ѡ�L,�)��c[M�^Wg����f9�u�i��C2����/u<o����B1� 	�V�[|������w_i��`*@��v��Y�VF8�_�? _R\9�S��iE �2/�b���ۙ��l_�G+E]^�~�($�Or�ck��_g�׶pI�?�t	�Dgr�ƠH�EF�� �Ɠ	u}2N��?�%�y�w�j���T�I��i�{�4��ߪK>�ڽr��a�%���K<<X�����V0��M��3�y�g�x�򬅬%?b��%Q�b��H��+{o���_gC#a�u�o�׆n���_��4{B-it?�\Lu���x)J|��Gb�ٻ�U�n��Y�:^"�T_Vt(~!��5 ���7�h��^c��8�\@�ᳩGH��"���&+��g)D��U�2:� ���Z0��^�ˮ�6^�˧<�݁sRS�%���Եq�*��B/%�U�:��`Z�n����|���{y�P�7��ύ8RL������q&�	��u�V��&~Հ��!����������>,o�O=���w�b|M2���<��y����>��X|Qy8��Ux�8	͢� U伫��DA�X��ٜ�y�h���=�A_QA�NKT�)�B�L-��3<��z�g31��	�v�הǜƁ�^�2`���/2�smԾC6_� ���5�^9�gu���^�J��͍9n��l�g����~������(�׏5|���T�ו(�Tw�tR�ƌTA�s���ˡ�7�:��ڡ���	r� �yO�*�Ї�3\,�Y��6^���ĥ�.=����� 3�*�RI�%�-L�(�w?�&����S�h�	�gU>�����j=B�>^:�ojj�x��.�S1L(��e����P���,�%x>�s��Z�jŰ枵�L髡��,UNl�TΧRp������)-�l"�~Q�= �g�9��L�d���T�_a��-4G����x'�c,@#��f�T�i���ܛQiz�V� 	45�����S=�I��t��9�8����On�o,z��]���o�@b�|��׷=�b���hF���¡�%"��$I�km��� $��iNe	J��~W9M�F���$�q�n�k��i���t�_l��UffZ��p�~���!��\��0��k ?�'p��v��eo��|�RP���y3�BK�{T���4��<b��v��x �R]}d=��͕:zhT"�͚�~p[�Q��B�[�ԅ�F-���k��jX@^~�8��Gm0$�� ,!l����gռgO�+¡Hz�c�-T��L�%#�.9���_����d
 `O4@��<��ٳ ZX� D^���@��[���t`�2H�s� ������7�r~O��� �OW��`Aa���V���O?�r`�2y�)g�b0�aN��Nʆ榽��r��-T*���B�H��M�CR���eZB�a>������8�� �V�yݢg���1E�38�#ݛ�%W�7��]B>��(GJ��n�x*�7͙�=���:5T��DN��R�6�� G��z~�X�͒KP�qO>��pe���ޔ_eo�?fc�~4&��x�X~e���P��0��sb��C��2�M=e�D���~V����~��֬���i�"�Js-1ཆY�$�v >��+��
���&ćF�&�(9n��:Q������+�B�9�Z����5��2xqɊG���B)�?Sv�v�,��S�~�Ǔ֋R���T�3~�w��$�����8A*f�h�Py������gn�VD�� x�3}�?t��]���S�^N�m#��2}��ȡ; �,�)=��g5��1��?���Y��Ȩ��Wt�����P¾��qh$�C�����7y��y5r��c�z��Q(\ķ��5�����`��QY=�1h��Ԃ�?c曬R��&e��6P���������N
=a���ZO�}��̗����TA��A �W��Vr(����8��P�%W�L��7��,�Q0�;�&���G�)���>8"R��|0/%,�YɌ�{��园�����q� Av�o���E����3��?0��Ȃ�2�5w�U�Yl�җ#+N��WDl�N,�/
���}Ko�\�C��s m\�9$��үO����u ���df'&X�����S&����Op�r�/� 3B<a�4��y,!�P)g�%���IO�PѾ:C����NNOgL�4�C���P�(.��75_k�7��_��APZ��(�S��IM��A �([���]=&h�����Jx��^�R�EC9�� �!�a��&���++�e�U�QM�<�k�q˶{��[��Уw��=*lK�'8��P�w�GQσ=��$������c ��uW���>&D;�fzǝE�o`��+dc�ؠ�>~��:�BF����K0:��i>f_�;,�vS��:��>��6l��`�/>w���O+���,豸Q����_"�	<�F-yH;��%�
�͕�:�h3߷�W���P�w����$O�.#}����5)]Y�j��"l���*��dE�k��)
�*�ݶf*=�s�߷�sfr(m*'�Zq�Y ����N�U�(h/��F6Q �W�V��4I�}�rY�m`Op�,u���	C�k���99��& �����Y���<v�'5���?`�h��( �<R�
��g~�Z�,��)Z�Lu@����r�$N8���?G��TR9�R	tjp�dh�jG�A�2Å��0~-�⺯O����'�_��揑�����k���,�ïy�缺~x6,d��{=h���M-�Qc2�w�����K�}�SG&�L =C�Y"]\yhN 2�wgݶ<>i!!'�ꗑL��ш)&I�OQ�K#���)e�a}��,��h�o�%��.�o��A�hu��%v�!�|^zvHސ�����x����3�����M'�"bY����Bʖ�����d8���$���{�s��|�b�C�9\����a��G~��&�mА9�=�y�<b̈czB�W�K���.F�ۘ��>���ğ�<��i��;�'	WI����YǰŖ����E��q�aX���f��X�4Ӫ���m����BC~Y!ya�Ty�8=8�C]�F��6j*v�2 ֿรt�?��W�{K*�I&�=�܈�~��+T)aU��3u�D��)�&�C"M_��*�QxM*X�⑾P
(/!b�s<�#��0/�٢l+M�B�3�E~�����f�]�ٍ�'ҁgx����p9����p:�\�h~��v\�N��XŰl$��!!<�JI�����M��D��7[S�u ��־טձ�%��R��(GL��G�2
X*m��\0���9@��B�&�\нZN/�`�����d�h�6%F��Z�s:8�N��Mz����,B���uRL+�\�4e%p�W�-q�G58'�3Fm��S�����V�JT%?a/�f
��?�p>�7r�u�;�k樓�!��&,���K�罟 �L��1��P���i�����e[�۩Ab|6�*bp���H3Â�u�*��j�
~�X�x�6'�G������=`��9�^eS��@�j�ߢ���-#I4[ì�62��T%��ͅ�&�idEc��<Vy�e�:���
Pa�"�&�q�>���o<J� �1OD/��&.�=�T�_��n�X'�( aJ���Q��#��#F�Z��!��+$�izz�>u��t��]�D�{t�
r�46�Pzub#SR�_������:-����y��й�( �c��A�R��*�rNXzG�/)�#|���"�?�p4'����$��F��H��Wf�Z0].����������A����$�xDc���B��'Y;�aģDZRL4<�B�A�0��.����A&*mfT��D��`_�S�]��Z��������mL��{LV����&�Lг\pV�c4y%�K|�Ȑh�_z�[�Lz8Wת�������J��0��a��2	�,�\�O^	db1M��!���>7<�ķ����"�� ��Q#I@&AAv�c3�z�Oω7?g2>8�$��l���)6A��YܱU>��5�/4�5�v.�6��g�����NH���񯍔k=���P�Z&
!�|au�����8GD�p�<�m�XƳH[�YK������B%c|S]*��.v0���m \.ِ��*�p
�m��̒�X��N��#@�&)�����pYל���[g�z�z��7P��5c��SB�Q 3�7�?Jy	ˉ/fr���;]���؅}�?=��}G1i�(+41H�o��*��pޕ�$t�Mh���֍&\��v����+�=�o�uq�ׯF�[���lb����T�L�3�6֗L�e���Y{�����2���@E@	w�H��0S��A�� D�X̵Mu���7�&��{���%B�Li4Iy��V��Bu���S�Tp�c�RfHs6p`+�zuZ.^H���5+��}���g���ݢ|�{���^cy*�f�t*u���Jp�󵽝�t�Kԫ<nP�&�(l��͇�s�����7��J�Z���EL��r�~�����՚�f�#�޳-�A?����nKJ}�A;��B�~;r!�M!�e��q��5�g<IN@OJx�h݌��^&�����휉z��:3w�fWl+�q���)0�m��H	(	�����`�@��wӌ��ɧ�~����E&�(;.`5�Z��xr��;m.F�f�'�s|���a���W�|MZ ��E�rEaP�zQC+�OQ5��БNsn:��/1P�㶄)%Xh�4ypG��(��8�7�
���9Om�Ae={��^��ꃒ�����!o�J~�@����� �!��r�B��L;Wy�Ƌ��.�}��w�a��'�G��"�n��G1Ec��?��j�˕{ͬ���qW|rDz�vE���2-�Ց���y�c�NFe&48����r���tQG��]V��>��f;��~��*�:�K_��5��1y��*�8��!��j� <�t��;����@�\~�u��G�8{&�:!ԥ���s�n�C���U��N[$YJ�7��u���E^&���&��)\i�����)�/s(wGE���:w���li�W�bg;"���{����m��$��u6������Gww �Ę�9o�e{�O����s+)�J�s5��5y=o_c����;E+m)\�2[-k�rM�7Q���"C÷���@��R�Zĩ��%��+%�V����5��*��zJ%?��D�Dx!m˜��R�*1�|Ôᨓ�AF*a�z?��)�]yJ�<���k��A!iE����}!>nQ�����L��ْ����C}-��x����~j��(�:�w��iYv�=�p�0=��˼�f*(�gሗ��X�T�ʃ�(�Xԑ�-aw���1��P�BrYr�a��g3���cݧ���inl��X�L&�bI�x&�r�	ǒ[k$r��y�uU��{�#
xIG$#*��KP�D��$�v�R"����R��b�sYKŇ�� ���a�)�0�ˬ����FGĞ$�Ԝ�MoZDu��PAo�hu��s���6A�闵��s�;����Dg��,�G�p�88�Sӄc�����̓��/8Q��'$3�W~��+�T�~м���m5�$K��s��L]�E%+��5A���&ܤu�� �X�ڽ.�bS��r��Dڬќ��f��5�D�;*��QJ�UM;Fi�I:>�2���p(}�4A�,9k�_��Va���E�(�A�F,�T�/��[/�ރf�Ӑl�SRĕJǤɟ�ʹ>�VXHEV��23P��fڅRG>���X`4ͼ�#a�J.[��6q5�C`����^5/�FT�X�;:2�(�),l��K8?(�j~�}U�ʌx �/��-��W�ѱ�9�Q&w�J�uA$>YxL�I;  ��ᐶU��m�~����I��2�HE���g�4 �kN�))��8^�9ݭ)h���L	��l��@�3+l�c��
n�_�a�n�w�=�^�Oy��{��U��U��r�@��2����¢8wo�$OX;�L>�s����y���鲯��������x�S9�\;��k�
���8+y����<Q�`��ح^/�ik|�'+��,�;l�}����5f)�ӳ*�Ǣt���"�dXNl.9KVU(f�����rn'����&�{�<�nqKJ�]�6�w�	Q���R?'��1�ǮYs2��>�������i�}۽�WM�7q�c�K_~W�[WHV �{p���S����4�Z����&���\����=�1��uS&2����#fY<Z
���U��/'G�b�\?5��1ǡ��8�ov��8E�4B���3��2J��Tc��Đ�������l��C��6�4mB@�^Cc�RvYI�v����ҹsL��"��ҁ
l��Z;F�_9B�^�_vJ�@��<~��xm����$�X��צ���<ܳ�.�$~�{, ����*�����i��h�M�!�A&�|���!�)��e,/�@��-/��˯p��s-�x�������`�"�~�Q����dP���-f� �ӻ��A�Z#Y�?���ʬ?C%����㬋�;�n:K`��G���*��e�n^���~�3�2�۽��o2)�{��!'�^Rbְ���ChR�֗&���a)~̩�.��m����"�|�v�Y{����U�\��fH.1�mǉ�{�������I�˛��d|��@in�o�FGO�N���Jl�;�x�@�.�Q"��h���*�01�CN��*\��������|x{���� �`���=��8�����	�m柽��(a��!l��$��c���W:��8jG�Dt�sn���Ј]�2����q {+�����i���K�JM��s������7jRk��$�lM�=��`��I��%E��Q�k����Ӊ�q�OI�c��ƬF��Jp��|]"#\ ���Ck���MH���~M~�:�pƶ��;�f��*`@�{1��2D1��ݻ��ږ�B�^��B;�~s"DD��i����֟1�eQZ��.�E^����t�[=���x��e�Z��;�["�[z�-^ZX�F��*0���y�~��l$	�'�Fí\de.0���-g�R$4S./�i��4|��N@�<���HD��K^C��8:�<�O�{�d�ȋ>y3�]n�'���7a�)gfP|��x�)������|P�W'S3Vӗ8���_f���C�|AM�;�9��,�{�`AJ���4�� =�<-lnH��kS��ìJ��֢W5��45�	1H �QZ�N�����x��]��EI>6���V�sL�� �?r��[��iNF��Y:�
1z�V)O򽦿iG���3%�����w�-?�ݞL����}a��;_�yAW���[l��U�b9H�'ޝ&�c� u����2�q�;��D�v����
��80�h0�S*4�ĥٻ�s�8�6H�n
�����/��Yt�$G���ϓ�@:(֭����"�]Z��ٝS�.LW!�PS,]D а�%����||��C����7�k,M�89�úh�2��/Y����&��6�􅱺,Q�|2k��<e��W�җ�~�Y��D�t�,�|p mY�ೖ�p��gO7����!����O�l��_��W���%��'�Q"���N�{�4>7ag�VA}؊}�SL@k|��9!��gɁ�:Е�y.���!Q�B�^���{�P� ��p�^3M:�"��H9@
����1�n��ӫLr�0+���A#��Ƴ��I��&s�c���<��b7������)D��(!ЁI��R�|S�}`�#�^�O[�q�AV���|�̷&(��	�+�3�"�/��.���䅬��6�y['��H�g��X*�ڞ(��*j鰉�R7[�txJ��>��M �����}�X�Q��qp�VaE>���#�7LKӾ�U�4��k[�-�Åk0����F���Yie�T�f>��~C]�����������<,DkwDk�_G�� y��:sN��7��N��)�0+����^��~��3aQ9�0�+��F?�����ٹ��A8��kaE�+>�em!8���Kv�!���ikb���D�`'�khZ���I�g)�)�Kj�=�Mǁ�IY��J�>ͰY�^��b����^F��⋠ϩ�[� �r��x_�}�^07"�(|��=�m���v5��s�ԏ�'�K��8n���f��;(5�dVi?��1�.w��Ì
�=��5�8��;'3Pڻn� ��z�co�"��ߪmV�J���"��++�;�h@f�EΌeZ3���s�k�7������ozoB��0���6�{:H�((��C7��lЧid�:{@�)����AU�q��~T5�e�34�2BO5!�Ǘ��I��ե�K�G������O���^�<�sP�?<�N�B�2��#NBD�� �ɗ�.R����5[^�I�`�Ѽ�iN�~����N�0��?�����j'_M���"���N���p�5��0c>��uC���� �^��?H.hQ��lޢ0i̵��*+d1�V��<92��}
����g�I���4�R����
��
��Λ�͎C�!�h`<�Bs3��D�16
�[��A�+{��o�@�lPW�6y �kM��ET���pH._Q�x���������y��#c�5	�`�:9�1�jc�}�{K9̜��}�� D�6w�r���h�}�ܕ&~�0(���K�ݷM	���ɵ�L�4�f���NcR��U£Պ?L�E��J0�`�D����+���bw���A�L}4�r��d��"�/W�G�y��Lɧ��\��5�Ui�]�:A{wI��o���n2�#��▤�53�2���%�����Xb�9	�&:��s�->hq�0�Va*U.Z
���u�t��ٮ[���\27��j�(����Z���R����R�}N�J5h7���:یV��nd���0q�rA�,f������R����e���rC�������	ٺK�#ЦMAG� �m���C^���������5]"��]���V-�8�0E���CӜ�OrO�7KT���ɀ��.e�����.�3uiv��<L�2rǑ��ʕo����޹�����
T�m<�蠑./=�{qsب�Xs�`YI[&6Y��D���`���D���A��ى'+��[ϽY�!\Z0ڧ?=�F�9����y��X@�{��sy)#�9jl��2�=J�w�����6�! ���1�^���?��@�{�m����ki�f�0�L1�Q.ӏ���PeZ���!���K�_y�o�X�N�)��px�kV�����څ�*���Ż�S qJ�vp�V�"�����6b@�?ꖪ�M��ѩ�	5��5y�L��c�3�B�m\#-y�Fbx�����?��DK����?���D`�C�f]��#�������`{]�>G��]Ix{��ۉ��E�x�t�TS�s�l�zx��r�`!:���a���0��I��f| v�ep[� �\�A.e��]]���q���&12w��th���z��;Ƭ�͜�� �ř�D���6�l�a��������է�����,'ұ� �Iv��H�Q�lVd�.�.h�^����� (�%�٬Љ�@g@6��^h �MeQ{�SՏ��K�}�)%9��/!���m��Û��Ɗ��+	������1M|���J�oG�������z�ժ.��-,vJ)5���v�x�����-Q��N�3�8o�7�b���{w鄊���(������I]��G����S+wM+S#+��Lh[^�P�LH�:��O<x���cI.ZhRПԟ4�N�ģ�6�KYj=��9���������%c�Tm �/���V�{�Í2���濢@��U�t<ęX�� (����D�sya�^�P����e5�&:#��Kc� �t�2H�ȕ3�:g.�i7�(oi��2���;������˭\��0ؖ�kj����/����6>��d�U�O[]���߈�w����Q#�+��4��l��n$�z%�Q�;�h(H�^�g�
 �ђ�H�u�~qD��3E��.v�8Y��p�>Q�4���mB���y�;l���oDZe�$<&��mω>dK*M"���2�l	F��ָ���,Oԟ���^i*|�Þ��<��bJJ+��ge&]�Dᮧ���7�a6���L�<�j�ޘ8cM�4p�
Ȳӛ�V�@�b����G�1ET��i�U.������D��D��#;`Uk&Z�ByF�E!0��ds��L1���<�~6B@D�5�|��n�'�1K37�l���4�����ex�2UH�"�R���DFe�I���tv�U��N��^2��ۛ��Սdb\ӄ5%�
b��$�P#���$��"y��7{��!�ci��t��u�Dk�,޷�HIӊ�׍n�z[D��U%���=.n59�6A��7������;��l�p�3�R��R�/m)���b��._��5�Ԛę������S�Oѝ��^��,�/uEZ}:��+�WU?ceP�sRI~J7����K�<��d�)� G>�Ci�a�c��*��W����=�2�)��7�b��~XW<�8M�+~Un �L*��2`ӤE�[ʗ�hu���>bzO�|	�[�M�81鮕@t$�v����Qe�؄!���E�Ĩ���D��~�p^[�YEֽT�y�E�����?���3=z8���� ΝqI�� �g�?���;uFuVӖU���,5P��0%-H�C�7^�C�=V����6�#"\���r��� !B��	�~5A�X��>)��g��&�@ڹݠ�t�w�:~�,���+�&��[������KԱ�bٶf-�a_����d�Ϙ���1]�;J����`1��@�W�7ե�f����-
�Kp<�|B��֠R��-��?s���._c!�C�>�J�缗�l�����Q���T0�w����T�2���^,���^ց�u.�j�8{���{W��w�)b�>Q)�E�|/ok��I�dlIjvN��f�wz��U��5N�:AɼV��w�|lT9���K(ਙ�>��K���Bfr�2��r�m�s��8ػ�Y�����X���QO�{��fͻ��m!��j^�2F��+9��Q�}`H`�	=3*Mb� � ;�D(��~)h���(�L�]�G�y��XO?u<�������y������ $���.�]�PKƣ��x��k��u+1)$�~ ��t����w�>M��zB'����)`��J���qD��vJ��\Q�z3Z-��Y��ie�?
J"IN$�|�{ۚ�[���5�lg�h`'ެ���PI	`���?��4�V��W���۵6,��&�E4�?%�ր�=��b�>�X;����ҥ�j6�"���Kq�{&���΋G٪�m?3�����B�ښ��.�02&���
j��_��֛��䋻T�>���`�w�<a�$0P4�fG�G�"�x >d	��bCK˘�T��vۘ�f�Ȗ�s;���vkk8+xf��Ė����˽R���?�̖�4zf�[kң ��{����#�k`L޼�2�V��$3y�Y�4�+xh�R�\��ٴ-|$�W��S���=�1��2�bw����=|_��y�L��%�<��F�� ��t���?���`�݀/@/ǟe��OP�p���]�*c9�ݛc�Ya�sxu���� l����V��=nK�i3׹�|DuW	���Ӂ�d�r�{w��9���(��P�&�* O�@V?־P=�ϊB�E33�H�"�WRG� vD��6�Lن�@W#}�U�<����K֠uJ����ݍ�I�Qc���g��<�k2����@^k{z1�ޕJ������P�x]�=5�׶�Mi��z&�=BD� �t�?%�A��&�Y3�5'9*>1�;�{��o�>���(/�����.^�����S<4G�)��E�[�$����q�\r׿.'#����M�*��R'����5q���3�ԟ��(��ޓM�",�=������K�*3Y2Qk�(�)�	�.jߧ��P�+3}�]���>���#�7���w�� �}�AaW"h�U��X�/_5Q�����$�C�I<&˦���k8*���:y,�y(�R}���������w�GY��c/��O��]�� ��¥Ej#�z�Mdk��5a˂S����Xw�^��5�l379�4D�T槤 N\%�I���:�u3��ާ~�+�,���JuY�
�}�z�B�r�&.!=ʭ��7�Ѵ�)H�`���@tr/�RG5M�L��3�a�٬m�m�kfTGBH��̵�6˔�	��  r�����.� ����5�X��g�    YZ