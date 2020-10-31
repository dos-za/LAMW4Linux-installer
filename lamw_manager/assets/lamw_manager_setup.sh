#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4135602739"
MD5="048eade4221b351dc022a162486d0f68"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20308"
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
	echo Date of packaging: Sat Oct 31 14:08:11 -03 2020
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
�7zXZ  �ִF !   �X���O] �}��1Dd]����P�t�?�B�	5�C5.ŕE���.7H6$$�R���_#l���m���uy/>�Y6��ZVO�c>4"F]�{�_K��`.zM���8&͢�5<�oۼ�RJ��]�C���X��n5�I�p�-��������ަ�,�g�����ސ�a�4>��Nq�֨�ģ��>�'Ukz�`y�բ�7�}��Q�q9\$	���N�4��d¢X�[o�(�:���qd@�/��׉%��\mY� }���)zD�°y$+����(���\��*gl���.���T�ZC�2�L����_i���r/���Jr��+�{�p����%�wh>7�0i�j�J���N:�}PAf��y-�������&�tḷR	\�	+Ƈ@��(L���R�ՓZ��ͳ�dG��V�9oO��e��BN���~&��
�&�C�v@���2qr���f��öڍ��Wbݾ��2_��4�"�09�� r�ݦ�QB��G�9N�cF�������l*aq�}uUr<j��|�K�d��̍������o*4gp�<��G����K�����XT�T�Ɍ�e
J ���o# ^!�E�V��bM���_����;�HP~N��>"=���ZxS��M�H篱8N`����A�M����H�U��
\8��a;�� ���o8l� �D?v���w��W2��u��o䐻:��]G7(gv�?�B)�4�2��	���L�Wb�:�
d��وHZ�qv����)}S54�f�<!Y1p�uF�c�vs���s��^-C���ݴ�	����J�B���M�vb�Ǉ ~[
!��<�>o�o�%#CK���hd����D��|p���l��y8����v&�C׉�@?�
�z>$s"4���qG�om|
�-�f��� �c'�̌k%E�S��V����>+{;іݢ�r����r�y��7-��8ǿ�q��^6�v�>9V3K�r���1�����z>Ư�dk��kC�m�+��^�>V��e\Mi-w�H�[�¢��ӊr�0�/�8���U��߸���t��D>�=�_�o���1�t�׭�?�4F��� ��ס��OD]-ܯ9�5�niv��S3:�G��ꊴ%'�{��r�tM9��<��,B��-�.[Ѭ
�vNN��<�g�&̒�Z�����|+��m���+M!w"b4��I?��L�k#.û�Ќ*�,���S���%���|1l�g$y�ii4ίF�:l�>(��n��z��ŭ��_͓�duf��5 k�83�����'l��C�1��h'� !Y��C��}�K>��g7�/����_\Xj�#�˰a�	��dY8s8��{vɄ&���C�{&����)��?��Q[��*�6��\��Q!�j$���D��x�R�M�zw�]�M�$]��� {��o�J�37Ǟx���ZC�F'��[!�ڷP��+�ƍ�!-9����n�g����dH�X�>G�5��b��1�J��Z�D�S�TItʬe��c�gX�$��TO�T���
�%kEW��A�o '��
�p��>�1���'�Y�"��Y��b�>v;I1g9�l���z�߯��eZ��缵*ڋ�W�JH��a�4��-�PD��>M6��E��j��:���o���!g��J��K&�D8�)W������w_�-�z:7s91���T�=��S�K�El�4�|��*4o��e�>�'�U�ېhAZq{��j�+\�0Ht�ak�tZ) ضb>`qywD#���(���CG&�W�����������j\�@()��p2'�z�b�$��S�!���鸪��f,�1�̎f�/��P�����Q��ء��R��_f=E�eJ=��c��鎶
���f>����T��1��YϴӉ���zߞl��!Wq�[�:N!�^�t�oS���Q�.�O�2������w�k��-���}�q� �'�����j���yb8Tb��QDDf!��>6��
���5�Yi#��}ރ��4�Y��&�Sae��6_
(���_����	�(C��*��>#�Dwk�N&AK��ފ��ž�/x^�e>]��Te�(� =aaV]�>��� ��ک1��>o�PK]�Ll���B�&��Q��/�Ė2cp���J%t!�턋�4��-J\8�#����]ns	j�H���m�L.V�( �A(m��6����g\��iĝ�k-`�"\}4�Ĥ"�P�\�=�J���GԭY˝,Xl�hO>��>o�6A&<�<v��,d�+��)��5M�� ���L
�J�\���m�쭻8WRO=.=p�'��{�&"|��Erl<,[k��� ��&ι�X΅]�Bu�
�8Ҹ{,L�H�����v��Ҥ+���U�ؠ��S���h�r���1R9D��8t�֯R[�xr���`�ي��Ѓ�T$���E�޻�2���Y
ٰ#�0\&�SD*�k�Q�W �Ԩ��51�p�cP��}T8:j:���	�Yo��KE�P<�h��0Zq:�Ӄ���d������h;!�.0�[��$~�Q��]_clIN>@=
?`#��!���>��h�K�"Zޚ\^?�]]`�����o��p�9v!�%f�Ҋ������jk+��+�|��g D��B���e��?���O�G� �Z�y9!��s����1c�I�s	�ا@&2�^�\%@A���fYe��g���R:�8�����*�i��}5�'�ޕ����ޝ�bi4�k%!C��Ć�7���}"���P�nX��.��d�5�� �� �e�4`d��ѥ��E��h�e��:S�e�5R��"Əݤ���@�a%)K�a�8�Qx I�j�o�4۶g�w��+:,f��q�8ї~2���B�	~�́�6�����\(�|�frxT�7x�Q��=+�F(��6���K�����b��6ے �Rh��?�b?U�p�Q̙�Q���5��/#�]E�dJ��jCj�Bh�Sw���=C��e��Y�Ί�u��_}��[��Xx�K����`OsGWl+�/�d�����n��`���x�]�T1�7��8���Ɩ������Zi]Y.+hUBϟ8|��Շ�
P�ޢ�^!�,6�uo~�TV�4���|����I�"��x(6��Q��O����zKC�����+���5ZJK����7Yx��Ѡi:����G3��W�Y:�$4@��b�D�����������{�d�^�iq��������ou^����M�HPf�F+�����9�"+e�5%aYo�v�SC{-W�U�4ߚK��r�+���$/�θ�Ю~ݾ�q)hB���J��%�A�໹Q���|tgjw���dB���Ng��T�mc*�$Am��J]J�����K����t�;�+@S3W�����Z�M�Eˁ�s��!�f��)�-��ƈb\w���}p4�Wo����R����5'J'$a����H"���k�G�]F�
SĪYiܨ롲ϔӸ�j-G8Q�<@<ѧD�?n�3�"��;�N������":�Upi��D�}�w�����M,�D�QJ�w��kg+ݻ��8�9�5O9��ɰ�-��4˅��e�j����v�!a��©���l����@��m�������F�K�uv;�����7�&��G/���,L3�v�h�:�u�+S̔ϱ�?w
ݔ���W�?�/'�"i�I|T�LFM�MoO�R"$:��=�g���{m>b�kF'�yuɥ~��$��K���������F�4�u&?˯�߰gn�*�����sS�"g;Ĉ��9%�2�;�7�0��,�Ц@pmK���R�?�!sR�1Y���M�'��QۤT�{� ��E���r�u�m�A]I�
X��`=��9"Uq����i����ֳ2\v�,5ʂ���8J�hu��j����,[��g@�c�VN����\{��g�n*i���f�]���z}a<�l�����>��x�T���u)�R��]1��ylT�NE��T+)�m�;$�WM���9����nGU�5]�%�����Q���4�jS�*������C8��b�\�K��ީ-7@�}�]:��׸jk�����6��zK0)%�"���<U�6��dt����C�^$Ո���ۂg?+vt�r+"�����m�<�k �4xcK�_�}�r�n�b�i`X����({�a�~�U;�� O�q�
���ڻ,�ʻ�R��%���ų�r(0�_x,E��Wݓ]۪� o�;Uu�`# �_�)��c�!��\��t:�-������l�{Y����xB�Y��w�f��|��gǔ�MS��u&�'l6�>R����S��v3�n�f��tA/���E+r��#<U������ZK���&Lr����̔�@
۞f��\fX�,_�������P��"����q�P��{3���QE����j��i�h���Yȉ~``1 [9ܦ:��ϗY�~��������!7U�(.,�j�8�Tɘw�x=m����r�<�r?�ץF�J��2�5�$_���l&�؄|[+V��憚�]���(��~��wan���%�W��^�2{�_�8��5�?�,���[x&��z�𚷆��Ϯz�ʢL~�[ž�ZÕ�-!<ąP�f��\�(��RV�t�,�f�!D	�Ө����t�g���L�B2(��!!��yo^��7D�'9L]�7��*>�re��c}L����O5[F]���Q����g��|��H*��z)����@I1�Z"�5'�����b��E�j�)��aP�W7��g��nh�ڝ�{���������c����[�p�U�R�%�K���o'z�$-�kO6�{$����� ���U=7�����pY��+�d��������=��$�T� Z.��7�ޢ�7� �n�UI5����1���O�ʼs�R|a����3d%�1��R.%ėN�宺�rc��n���qm3O�6F���Xx=�!�`�Ǆ���T�e�7��RA�zZ����8�Sz��f�'�|��V���g+�����o|���\H�q8�ya����l�J㟝[8�*��%๭��#���>n�o���7a��z�s+��[�&� R��~��I��\V��ݘ��' �w�����	���7�$CllF��]s��n�����5n�G)r�g]���`���^;��d�t��;N�ŭ�g�\��Zm�R����-FO��x(�8�c���Mj�i��X��e���#ڑs݌����!f�.xG=�qx��ۢ*d-C�%�s�oN6�Q�$��NJ�����^�����p�]�v%i&���'�W;��Ǵ��~Ԏ�AjJB�	^�f���_u�:7d�XQ�-6�M8�K��p\���z+Y1N}AC����xQ��q�2>��Cic� PJ�6}$�h2�=YHZ�ROw�]��T;Z�Iv��W���'=��.E$��i��q)���)���� L�߽�4��6
���E���w�+"_�ߡD�^��/k�݀� �#0���+�)��Qk�D�Br��k&���	�
%L��{�?њ��%��*5[K�K:���={u��p�V8(Ĳ7!�{������^�7}g'�!<��|�+pg��1WV���mƝ�.r㴡k���5Z&���P-)�:U���\l��]�G N!`�n���[9�4�[$K���]8> %`��p1���T��).�f��Ύ�kv���HKI���SI��&G�g�-�!����蟶�1Z�)�d_�����d���9�Z�I#o���0�D�����j������o�S�o��Q��tW/��6�oB��U���] D-���� �W݀�i��RX�F��fJO������7�f���}��
.-�4I��ӭ,˶ ��0�sa�#Z��!�[VzAp�	�?k�u�ҙ0-S���t�GI;��W��˹,9���|ʬ������xG�Q�J`
�5R$��|}�pN(���x�l�*���t�1�)���0�y�>�^	H����G�>3ʀ���r�4��^*���~xX�b�򣐡]�\s��0}aP�Ԡ���Z�r;Agp���A���kHF�*����T��/�1G���Rw|(�4Ñ�\y��'�Wp�93��O�t��z�1(2*[M�ur9��rC!L�=Ս��^ ��{�k�і{�6Ж�"h�~�4��A��;T�eo��|_�&�P'VӉ�)�0Z�!l#�yj�׊N�,ݶɛ@�Z�Q#MS��ȭ�U�ݦ?�_���/�e
a�R�R��T��/3��>M��eA�]\�������Jǝ�~��1�����ワ�9���a�����mµ�`���j��Fh	x�U�o�G��Zm�V	�jS>m�0���4�U�ioB8ޟO�_�VU����G&��㸓T	������?��t�>F4�g���w����������/	���jWB��� )]��� �;�@��az�������<�M8��}R�gk������"��B�c�3AI"X�؃���n3�`�����b�G^1Ё\��7Z��2�b -��h�Z �X1Lژ謵,���A�����T��O:�MQa�#��͏���h��2�	Ϸ�Al98<i	+\=�O�C�5]ƿm�B�� �8P�}��a$|4N���XpKU���9\�hZ�*M��Sy��h�"�ѝ�%�5�3�þ������7n�94����qt���>�;���.-��һm��L��<���9�Nx���vۑ��4=ך�d3�d�>�'EzK(G�K=l(w��|�HL~���(���!�e�w��f����mȁ�CD��UAS
"�f'���.��C�w��{������5 �3�1�®yh�t���G��N��:òݤx�[��m���w{)Y�=�P��39#ŝ��(5����>TΕnC/ ��i�y��ϖ�i��׏*�kN����]�b5d,H�s���Н�+�YR� �`Srُ�R��V��e9����g!�W�ү	)!|OIآ�+��W��ê(�� �!��h�x�j�.~�P�R%g<����MZ��c}��J�C�8��G��c�E~i��CV���3�}��N�z�~�� I��RBSx��
	7��j�ЫbHg�%~ ��8�!\F��;IDH߼k����BKu����h��(&D��춺��b�BmX�d��@�B[[��-R�i8M"�Z�xԾ�3�'LoAVA
K�l��߹�1�#��O�x��
T,b�:<�!Ms�./�h9R��l}�]���5�O��v�^��JYwل�����QZ 
��kK2�6���p�v΁MSdcD�i!�����b�p���WAT�^G��5DO�����f.������ئ8�]�|ᄼߞ�3 #�Υf�o��x9�ܒ���z <b�_ܿ��l��֙YV�q�U�����N.�}.i�\o!Sg�K�`�I����"Y��h�$���!�L�r*�FV �;��J�f�x��x�o ��j*��*�2�pLm��#4z�avʆ0j�l1O'>�!����;��m0e�L�|% r�Ѯ*7{�-M�س�cH��DO5��PXȹ�Rv2i(|�͒\��+�}�I#S���o�s�+pm���|��Z]3�a�g
�B�?j�~�'c>�HxV4��X5�{^@�'�G94Ȱ���g����1�;\V)����_.��V��f�$����z�o1^z�pu�>ͺ��A6z�Y[�"` ����	#�~j��~R\��U��O��0Z�h�|�/�i��4��x|a*���Ё��Fd	�3�scC-�p��F�t�ۢ�iEv�N����^�3�ط8�������t.�Ŵ������ɵ'�☱d��&���J���� [�,%V������"�t���1�׬a$F�i�����z0Nfs�ܐ0�4�����	����'}��A�9����m�Vk&6�o"�q�� d��s@� ^)x!�;'\7�grL��:��2+y忬��>�㮔�N ����c�.)�d�}�r��� �ƃ���ayjl�A����N�����}ӻ5�ӻe��w�>��@�%�����w>E���e����-�B�� W� &����[��j����������XeUԯ�mD�iR'��"iR��Mb�W��"] ��v ���oCDhls��1�}�.�$=�g�D�+[��f�ʽ<;zNtt��pR��wr����g�N&��um~��%���?�AB��:ј3�݃C8X���ۿ�fzF�dj�� ��ڰ�$�*YoǕ�ً��C[�B�MO��qj�+��W�5q�着xA�<�뎶������W���_��שӖ��0I+��E�kY&M�k��OO@�!Kw�H���mk���<�X����۰U�M��3���� }��ޯ|��eOαFց)�Gĭ���\��*h)�`o��߇Ya����8��3�U�"=y��џm�58��xT_k�=��F����6�lP	`�*I���tr��=��M�[�tb�A�����#�� eݧ��T�8�e�9P���_&�@��ɱ�����>�����8��2�g[�n��:9��{�YR_xڮ���ي�A�_+�dR�����- ��fa���Kgɲ)�.�����C��rQ��]V���Z��	�ΪY8��Y�]�p��w��3j��W��3� �{��O����|"1�����v���]�����(���y̎��P����7������=}\���U��Ag��[EG�rH��,��F�X����$:?��;O�#���K�:��~���%!x�Z�^�O2�i8f��|T �G�[9�UǞ������`��e��9�m"��qF�i���%%!2�]�Qe=�T��Vt�����Ik:aR�3Re跚��*g
��i�&�p�s�KW�|K]4
�{��I���_쒵�<� ��c�րd�)-�ߝP?#�h��O[W`C>���oʋ~��-돠1]04cX4¼�g�[T�(��}F��x��u8�"�^�R�=X	{���^�˱��|V�S�o���V��g����Ӧb��J���h=!
�=��tfۑ�æ��&@ϝT�K�.��� ��eYvO���8Һ��������uƧ39�W�H�uD3�޳%'���r��5��h׫~�a�дͅ��{��!��k��a�gPƍS�(�L��)���.���s_;{��A�Lj�$�����̮��O���Ҹ�c���H�{Ah�Z�!�u���eXZ�8�W7n�լ�J��m�2�Yث��m~��e�j5�oqK��"�"��v>�͟NW�]��
�u�.Ni��g���	²x���2o�6� |d�QP�׳﵅Urh�tT��M݆�RL���p��:U���ڣ(���ښ����F	i���h��9�g��\�u=9���wG"��؋�n3����<�G�O�x䂱)�>x8���$;S�X��iv�cPKK����o_Y�s�fܶ!z��'5�2�;�e��.�Ɲ�erCx���~��Z��ے���!Q�9�Y=G�ƨl�Л���TN�vEWL9��ר �9��� ���-i�0�#�*�>}H$�N�5�B���W��6����� �&Ou9^z霥��)%�{ϣh,ѹ7u�R �K�Ӱ�b��mڐh���^i�h���=�?ovg�N��8"3�����%�8~��<�g�/Y�?5}0`����1w�t��,"�2# �E@�F"���L�ߎ��ƹ��(�O�m|l�~;%�Ԇw�A��I�d=ǘvŀe<��K��-0�<�H�dD���.�b�9�«��H�q�~ƨM��JSW��J1t�v�3�RH[�;lM�rm9�m�;�ͼjS�	GJF0�n���伕^c#A8�N�c�� n��#��(�{��oK>N� Z~�:����b���S�'�=��OTD� H5&�og���#�q��ts5GC� ��� �*��L�B2e�:�N��Cj"�Uq��j6�F�P_�׹f���gu��M�?�L�A�ndk��)�E\Ʒ��8���g1gpi��ݪ�7��e48O�'S�"�0r��-	��Wu\S���X�I��t�A�ґ�>�[��$,D����}�zb_��̞K�&�m{��9:w)�ئ$G�lKc�q�O��D�m����.6�#�u��rV�|LO����z؎-�U%���n+��sY��@��ZxǊT�lp?��p�:T=�e�&(S�Mcσ��'�mQ��T���=ov�s6[M����5F�=ך~M��Y.9�6F �Y6uN��.�����δf��a,jdy�l?�Z$��Įn=��:Z#���쟾k�.���K��i���fq�?\�ڴ@gZF{��{^ft�z��y��d�����/23�  q/p�6mi��j�:�]�9�ǀ<����\HBo�lk.W���|؊O�O}R�ų����#3|Ŝ�
���TN$�A������L*�7Eݧ�϶�F�c�C�;�S�
��6^cؠ��\E~Ax�mye_��� ����*-�-�j;0�x.����9���9p�[�X���6i-�W.�z���}�ӈ���\vW.�5%��\�wj��gX�	�)rUk�_"���{j�k�c�+8�P��y���7�c�tC�*mKHk��xLk0-�s~�S�Q��ch2�ɣ� ���bj|a�g̓�p��L�H��rVr���9�����k÷n�\�`l]�P{�.��4��?�=)���>�-���C�>��;�v�XF���f�r�zy��c�q�8��Fl��_-��G{�0uc�������}��
�r2D�ل��)��T�t���L^��1%��mkF�{dޖ`�����>|ty(��8�`3�=X�SMA.B������섺����%�?��(޽{�%�ST�VOIH���;�2�e�>%���)�㻫��c<�;�&�����)tm���#`FKنf!+a�CKO:�G�	�:̸�π_摄���-]�pZ��?�����Sq�}�S�u(8��O����m��ʃ*5�k_��7�t�&�Q�"N�mX��C����]���#��$I�be"�[ӡJ'���u8g�/N�+�����9�u�fW������u��.u�r��1^U�3�9��S�U�9���v�W���H�� K�ܻ�]K���R91|�#��{�?��y�PX|�[FpM��a�\�O�wyD�O:��K|u-f#�' �� ��0��w负��3:�k%#��/����
x�̿TX�5%�)����/�׫��<,���*fo���������x�:��o��:���rqq�����Hށ��=Z�<e�u�����*����?&i���*�!f�1�!��ɿO��Q^ވ\;���R~�I���{ctܯ?z-���tVV��B��I:E�b�����K��q�e1>p��j�Η�$;��=\��T%��)eA����p�C)J�?$��s�y	_� �z�^[�CH�p�F<@\~[gkv���86��c������K�V<Ĉ��1��P��m�Y&=���
�J�Z_.?� i~�e���^�h��\I 3���
����s�E�/D7j���^(B`C��lֺ*}�����s���V��&>�75�Mb�ރ��ˉW��Z����>���Ϻ�|	�(����8Do�:Hָ������A���e'tiV!�ˊ�Fj�K� B�C�\�%83t|��2jvjC#��z�mD'�"�k�Q�cH��!�+:���R��\c:Q�-��q��:�0�?@�Ś��p�-n�����)��[V񯻕;_�;����N�r��&�4�i�P�*^<mg��=R6D<Z�"�E���1�I�3��:��0����a�5ʿ1��XH��nB�(��җ����s]���8ݸ�%;3��@�(&���,Q�)/v��$ѵB
� /�9�o�{��Ϻvpu^,VV6���M6qUO�ل�5���"��V�sh�(������`��47�w�
S��n^�:�oKgd����8��W5|��S�u2Ħ�Q��Ӓ��4=�����[���a[�	Ę������7������DG��M�Ӫˍ�.9l+�O���k�c��q��x������Br	�&jO}[1�Hg5�o�L���� �q�o>�������:�ma�)+�L:���*�6J��Aqo��i�q2���	1����?��ե�;HS)��k����WЃB=��=��-v$�[��R�����gm&k}��CA,�.�{��x�u� �2�����45z��L�%܁Ҏ�5� L�K���&�b����ҥ)��*_.L��!�Kx���z����`Xs�|ɞ��f��4T3�0ފd��SA��Ԑ#$�I�4��Ѱ�I���Rt��l(r�V��˦��P����@~W�]����-���,9RE�Ui������(��o$���չܽ�V1o	�������ժ��P`M]��hq��WS׽��B�긔���!�����7|XZߗ����#,�]�y�X��w_'����̔X+ �ɓ��5	�Cwrְg�����"4�(���Pp������RS����h�1=!X�2��c!k
�;Y�=qb�63��t��6��^����eG���f4�I̽�/]�ʋ��7;g���X��X�xy��H�t[�chlyȄ�Ww��6F�8a�����I��M�:E�Z���J��=-kN_�l�������Gl���~����ow	�� o��F�?��1T*���r�}U������}Z+q�'�aH�}�9���(�Չ�T-Dqi��_'vw���K����a�{���Z����M�E�,!�Y��r��b�JC�.4r���u#��e�%�Q<��m�1c
X'Y��s�<��^����%E�?)xbF�����Jm��6]o���Wq�
�V��� 1ۺ~�2tl�3U�7��&x�L�K����S�r(4P(3R� ��U� 1�����6O�L��}�̶��;�#�]��v@���J���PVl���{�EO�=��3eZ��H�'��GU�տ��+W4���R��o=��SΛ^��*.���m��`(�P���-�?�L����-@���-��#�e�ɓ`��D�p�!B��O:j���C���+ ��0f�Zp	�i��	h�o��,�<�����Aڟ�dO�k�e$p":�\6�-������I����'���;�9��VO�CsA�z���p+�?��m��U����$O���k,�)�-����U
��$�_����˭��4��ִ�k:Ư)J�<\f��m�u�3�+�� ����Қ�b�B�Ϙ���U�/�6~��i/�Fᫌ������-W��$�[z"��uQP�v0(���(r��mf���t��QB���RZ��*�I�P-S����V��3q!�ͷ�m�+��U�IM��E�K3���M���|T�L����n�jin���9����1SOهn��ڹ��&��!5���e��G�t���Eb�J�~��p�A����ګ�x�k��UMaL��tʭ\~&�2���~V��E�&;d)
^��,��5-Q S��Z�Q����4�����R��hpNK)�#ٔzK���;�'&.P��|��Õo拻m�݄��A5�᠑�μ���2�K��^mEp�r�_�.�*�ԍ�i�J�z������\A�#����=����D�ޕ�ne�yh��j�CDu�^ϩ�>S���ݡ]$��=�G2�Y�!^��1�M�����ڧP�՞bju�z��+� �}$�(�W�~vx
����P��$��|�xHf~�7�髷nn��i��0ԙDm��"�+i�ᜠz}هc���Zn"4�+^���s��`�F+o܀�p��nC7^].6j[�����2�yT^Ձ��2|�^�0<�e�袉�>�q�5��l�*����S�c}w*E��x�����h���og����x�7�7��BS�0��[�I<js����s|lHV���W%�s��y�@���(%���$3HY��yBK�D�I1|�������i.]��� k7�͕ʣ6PsBeVm#p�?)C|f;��U���^��Q.=��V5W�;,K(}�He((h���QBb�̨z�B�ごl���ʾy,��õ�oS
鸳�{��g���-�*�v�MBF=��a�'cG%�	��r-�p}�H��a�1��<p��
<o�K���
���8P|�ɂ�+�b��0g?���F^.�$��(%X&f�e��z_*�-��3*���A����7�1��Cp����O7_oVŴ�/'�O��I�q�T�g��
6�E��m���S�4[�F=*yE[	@dA�b����M �ވ��pa~	��~;��-�Gg�5<���e����Ǻ�G(9&�{7�W����^s�/h0ݪI�~$���՗��Z�O�r�↭>�n�j����2��������M�,)/v����Mz���v��`��Ԛ�_Ɂ��/�[]���$
0�>%����C�8�Z�:m�@�4}�\�y���VP��"��|��G�]s�;�r"Vgux��=h|��UF��(|y�4=U����5��1�1��M�Zu����f�}q�T$�;��p�N���}�;B����Cq@MӋΈu=u� �!z��A0ˣUK�:2�J|:��G7�˗�K�)7�瞞���Mj�Z�?�r��~����J <��5����*ڜr�u��o�
�LY� �<7"�Q+����9e�<x7rI��u���X�v^�C������{���S�}���h��t�����L�����+���ٓU�-6&{��Jz�I���Ƿ� q�GmF����wX��ߵmΌ���&��,rs�\~5S�O��᳈���c-��Ȑ���}˯���'�[S�*���*Q˶
b�Y�Ո����2 `I�ݷ���6P��N'�P�T�����'r�
����p#}�l{������m�7��UV�:�~c����-\�i�r<TZ��5���W�:�7�	#���r5es�jx�{�ɀN�����%j�mo��s��.�C����R.�ZfCSg��Gs䁯5�����^9~|ǖ�)I4�?4���\��qT��1;F���q�z��[Y��jd�́WM$y����/����vB)�S*30��H=H�$I�9�H���Ī:֢�%p�=ç�7Ѳ���=�v�#W��\z+�I!�sȀ��טl��)B���lֈ�����	���w�_�O��?bRТd���ئ��˗؃�Rҡ��^(g2O�^sZ�,�_B.����0�Xn^�����K����s�,6���P'6o%��������VM7�2�Sk���g���!��ׁP���:`���]8;��i�Pp�H���H�����ú�PΤm�ɮsAf���3:�����˟�L�c�LSO9�
Z�����7��Be�%���r���v1J�l@h�W�`�;%�ȉ�5>gx���}'q>%OK���ogK3�ghj�$ 0fD8񡱒�P<3��1�q"��Y���>\���HZ∗�w4�x��>2�wWH} p�"�{�ߵ���!fF����T���������"��3���̅��%�>���3Ђ�����K�
-c�,���w3�WS�w�b��é|U���^sr����aFn�-�0C=��������"�����,����!�W�z1��]
|܉��ē�n���G,0t,��b?�
��p\i����y��"v����q!�`k*:)47�n�Q�򿄧��~΋��y'��Wň�]ۈNv���$��#p�%��0W�Yx`��Rk �WԈ���0���}ż?B����E�Y���a��Ú�D�׹a-E�/���<}�S�Q�v�bq��z�?��,�A��K�b�c~EF�IÚoGa�2��M�*�9QR͏� �e_�fցTeo��v����!;'RA`zeEGGV3Rbn�ݠ)�s�!������=ⷄ>yȶ�x�J���ŷ&&��ۍK3�q;��j|w3����Z:�@���τa��?��v��ZY�k:6���U��l[r�\���8�{ݒ}��4�t:�Yp�JƧ�!}�
��I�I:���4�Rd9gy_я���X��\Zr�p�ß��KФx7�a���`����g��Ю*�]|l���z����=���h����%`����k``���%�zz��S�'��>/���!$�Yw�I!Mn� O���!���Q V�CkWB�� ���K$�����N����Ȭ]B�;�����uZe�U+*���Da�,;�=`�bļ�P�./:�1�[�J�V&D�����/�;�#���
�V��0�g��q��r&/r�c����c�}�[#�ӆQq���h]�}��Ռ"����3e��JnxeM�a��v��m�kc{����tV]Od�o	2�qs'h�̌�6K����0�C�QǉMi��F�M6��	2h�;�J�?�B_�o\�q���Mdn�@o�K+o��z7��/��Y8�m���RZ�S1�?o0��w��4<�1�>�o[�"@RU߉�T��S�~��EkX�Y��̘�#稞�����f�\z�Йs
��wWOd��!��E����f<ݲDi���֑��i��>׫�k
9U��|�Z���$P�h��й�="d;xq��4�9P}�H�(f'zO[��L޲�f~�DDH}*4�,:��s͟���L���4��6F|���i�/=e�i�VC�w��kn���Ċ;��k#����'��J�)t������ȶ:�2�l�fܕD�?<�T"�Y�����,ܝcSPI|&��aO�/��wރR_>
\� ��0�:�kcCJ+��8�W�#g}+��gi�O�,vDX�u��jw���j��i�����T=Vl=�,�Oy��Aޡ�||�+^i�!J�������G���b�֎����l��Wy?�4��l�0x���a��o@
�K#��~�5\�3�I�)����۱4P�l��V%�P�A������M�p��+��������؇d)N_n(`�hNn�[�إUx3G��AqF�q����A�{S����kt9$�W�t��'�=N�) Ԍ�eo@hx�'��r��0��t���x�JAH���_���AMǣ�wm)0�9I@��Xl�J�\�^�l��B�?5�/�g���8,A0v�L�v�
����B���z�	��֕���P�bv�E����I�z�_&�a0
��hf�IU`���d���itCE��Z+���	Ӗ�"���è?�V�\M�en��Ш��iQ�\�v3�!�~���j�==ꃩ���]��		M� �Pq�5��F���1-�D0��/xŅ�`UN+v��(4�+"���;�L&M�<�aXu�`�_J���U�cvW����]s�O�_�[#<��G8~;��ǧ�F�z�ȻE{YN������EUn�@��5�R���(t��C�����_��D�q��ׅ�A@@9�M�H�y�4$6�>���QS[� M4�_I)��I|��B�S"��A�/l~֩R S�YS�I�{@ѵO����@���1��Z|ZrQ=B$����«��Mw/A�R�C�$X�j�7���z�D�!*���L�s:1����r����,��8s��GQO��y��OT�Xj(eU �����u.�1�i���7үa�l~�B��t�WJ������+�h��P;��MO��h'��a	��V��բ��d@����J���5�G�1�>� .�M�y'��n;����q5`y��H��6���u����j�/)kq�v�R!�_�s�0�Y��i�t ��U(w�Q��, Tޓ���y�
SrP��g5����!l7T�t�z�2�A	d$�{���Š��p���;]O
� �u���}!At|.qX}WJ�#Hy$��F�AGmwɏXC	˛��B��}�h�n�:_+�M1��S-�t)E#Ӓ��i�� ���"�nhsN0�7�>f�o�y�[��	��0:2���C��Y�'Ï#�g�+5j;f�9F>/\���Ϋ��Qp��D��1���W�lZ�*��k��<�(j���#����fk/q�v��
ǚ��dT���]��RM�b��S�j������&���`�sx�3���������ܘ��Kߔ��w��!�n�c00�Wļ�;6�o�1u�S`L�������ɹ���E�
y�D���@���}�Oؤ��9����d!3�\:��{$�`)���羹�:پ�[M�ז��35:^`�G��*`\���^3�+�wE���`,�
���y[K��v�D@�'`3(�|8҆b�1�*����o�8zl��S��p*�c谅3t�'��-\+��x���G���~�
�e��|���N��G�/s��[:3��l����AMҦ 9J$|�������_O�,�� �ѓKj�og0��nއ4��	�ѻT�ġYzù���S����ϯ�ݑdEgq�(B��cr�R�'Y�eO`x���P\'sv��7�,�+rЁ�w-ǞvE�n ��[�i�-%Vr'�5JC��C�K����L�e������u��fj��Sy7�Ò{�<�v&UTc����������6<@u�x��}�Xĩ֝�[8%������'rK�S�����˔�����@G���CO��k��?WAn��!a��1fC��$fS�Q���VX��r�`@n��g9�g�h�o�6�[0S����򩶓vŜ8��NA� ��=����x\HB~$�(�||䧣l�7�H�#�jA7���2;b�����Y�vWCJ:Y3k�lF9�F{8���P�qHAYڄ��8f�~�<���rӝ׾b}62V�Z�ԍ�E��ɔ�;�.�1�ɞ;X��զW|�%��p�����Qva�,���d�A��H���7%e�O��u�ҫ����s�����.˶i�᭰D�=�&?�����J>Eyb�,�HĠ��$~r����C��u�u��Pw�*�b���V@?�����M/f�&5�A��m7������ǫ�ǝ刐����\³S���������vח|M	�P����U�I\.T��l�X�,����������>S�-r٩��Nи-`�x�� ܮ;Eh[^pY�v~��r���F����=5��#�	#浳��K]�S��������'�6�[q��D>�ĝ��N'T��v�\���W�U��ݪ�7
�8��l40����Ei���_p�秘U���иE�2`` Dy���Y�p�*ͨǕ�u�a�^�9<ە+��{\{�9��!��Zg}�i��+��y��E���nيa:)us}9�S�=y C�q��5�
�������ٗ�E�~4�H���\�x+�(�蟳�v��Ɇ@��y%^��-`���b�RZ�ͭ�=RB�jӧ��[&��~|Z�/O��d���A����s���K��"+��)ZY�Vջ���*<@'4T��q�B<c��s3��lTQ��K�&�q�����p���G
����f.7H��˓��g����R�W	pNQTI?�a��Y�A���P1�OKH�41���0�?kT��`kʃzxvmۖ�V��õ+0�!�D(�2�_��ą�%�Ǜ��a� ������%�l�@��
�
��<5.f�W�A1��F����Z!��m��$����*)�����W�D� ��aeBV���C��^a>�+b�I�L�,�as��nU%^���r�k��4��>	��$`2q\rj ���"�_����aC������k���f��V(���`�i����1R�I�t��0&XtY֌Y[�f��������ur_i��;�"×{�h	�    ^�0n�l؇ ����X����g�    YZ