#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2115329168"
MD5="b6cf70828c966131bb860222303c4144"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23412"
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
	echo Date of packaging: Sat Jul 31 16:37:44 -03 2021
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
�7zXZ  �ִF !   �X����[3] �}��1Dd]����P�t�D�`�'��OD��
�_����:�O��A+(t���x������[�o *�� n�G-ڷ{&��5�R��hG{��<D,7�9u+5���c�x�4A��I$�z h�qf���7��V/�� to�b�e��tCb���>�z����|W���<%��:k6��H��<��tS~V&~T�������cO��w��]����ƿ�3|���{F���+�QxvM�=���M�W�1{۞�Y�;0VƇ��Dz����@��Wiद�jn�# �p��)�]G%�s|�Q�|�?��oT��{��)��K��wU����\�gA���7�QO��u���`�Lۗ8p���>��)�0E�Y�~�U���Hj⩑���c�/����G�ؑ��O񒧼��n�ꜵ<��	�gS�`��"&�)�6�����»'��_�"� �E���T*���v��Ď�����H�~�
OԢϭ)�O���s�خ�v�0,�43���>/,����sţ�B�k�����<+��>�;�?����#�˙L:�f$fO�n}_�8�1��f��%��fI����}ܖ�^8}�`v�O�,�w�q#���4	]֖��PDwc�c���z���[jX��	t=2q��ηQ�_��Qy�nQ8�Q��;����;�%xj�yd��0H��.
�,�2�����:��31h#Qr��G�9�8N�8ç��$>�X�y���(#N�Pnן~�	��d�!@�S�5��B�8�S.����c�
�-�1���S�#g�KJB���7����"�qo�$�
[t�`;ҫ❠����ti$[Ur���m�c����\��wP�
錺"=��t����p+�����LIJ�ooY��z:1�V������yJ���?�͈���S�R-�ZM@�(�/
��!���;���1[wD	���-q�:�j�y/���5�� �'�����Z퐄�1oB>Ԁ�$�4����k��`n8�:�n2�B��9�/˸��U�!�LPji�d�I$U��ʇ�X/�� ���=�]���MI�/e֤�O���136C;�h 60���z.B=�� w�)so���q"�R�V&涣�m��N�9��[]�nG�Z;�|�k�vɹI��L���5�����Fס�~@����e��,X��˜U^v5-�\��,��sQz;
H�>��+�a�n[��8}�:[�)�k)4+����h�"g�J�G�	@���i߭�陾���Ώ�Đf V�#��t!8X��Uڪr�����?p�����o�b�'H�Oݨ�҄K"C�*�M���iC���U!M8���"D�Յ��6a��Wl�R+Z~�m��� �ip���P	
G{��ɭ����r^�����+��j�� n�Fee'��s�ilM�@
�`���!U�{.H(^m	b��,c��A�ȅc��տ�l70H]�v颥: ��Eo��K��~�8�����h}%�Fg�2b�OY�`�c ���7Հ���N@�8��JS�d���~�cX��]@��v2|���A���YL.t�:JFH����7��2���:�Y���=6Jf'�uK���I�D!Z\�����UOR�0�� %����"�Ţn���!�N�K}:`����4���5�Ď1G���>�
�0���LΧ��.��\������T�4���[$BT��t>����u�=}t���Y�BUe7 [h��� ݁�O�d'��B�l?: `���r:"�dS6��NnB#%�P\[o��u��y�8�1f�0���Ikb�+C,�	��f��ĉ~⣮4����H��G��z� ���+F�Z&�,��=\���LHᩅ+��0��٠h҅r*���ݵ���e�SUܧ��(J�$0Q�%d&F�"-s��c��Y��=k
Zx���y*���Go)KFԳ��+	q=9=U^S75�޸������͛?��,��P�t�}���lv-�����Q�Wī@A�b�3�{�?hP�
Ic[IBf����7�#�R��vG�i�7�쀖���(^����cg�#��MU<��Da����H.p���chk�];,��{��&�@go��I��_�"��x/���jn�<j\T�X�bb�mu��9���#�JŔ_V�m*��B�~���������e����Ǎ�}�u-�P+�c�,�-4�b�� o��V
 Yu牬
�G�}�RR�>�3�G�Oaq[��(D�l�����B���X��PF�N�j��2b2��*q~i��M���V>�p�|��˪�S+� ן+�����
���s3�ؘ� ���C�O��w3
�.���	�j�n!�8��O6��lu�b��#4�{���n��|8Jq��M��gS~�{1�d&��������^�β������ݤ��F�#>��u�� Ʉ2Ꮍ�羪���������1u�|x�+�}\�ک��4��8���㌅d/҇�6F�G�>� n�"*Z�A��,���C(�֌��6��\�k)���Z��bz��c�1���1�'A���`I3Z�T�ZJ��=		�ɥ��d"��{D쇭��-��
`�{���v�HQ�0�$]������T���5�\�F�2Z0�$)"i&v��t���q΢j둋����s[��~���#4����-��P�b�[�`B>j"Z����?��v�a��n�ZtEY��%�ȰČ�ad�dOy\a��H&r��hV&��U��:�O�����W��^e�.�\���e�3�|����Z�.�u�8��,����`���e�=�4՘⨁8����}�??\a1��6Y޲�嘻�.O������sk��LKo%��i(�ΐ.��z #�(���|�ص�a�I�Kb�5��`�����<~H��[��U�>(l��!�\�rJT^,�6��1��s�[Q� =C]{t}�P"����#o�h@�ॊ�l�Ą���7r�S��g{�]����s�q^}�	O��G����D�����7�8X#�����]U��:E��\u�ER}�,j9�H�����+� ���|.1)ۺ1�L#\U2��	;E4G��yTM� ݽ������\]��.��P� ��v��10]�Qk��
���n���y��Eo��<��#YI���a$�
�H���ൺ*5u{g:��W]D9����Nb�l9�U$�����!�U�Α^g
� ��(��B�`�_^��_}�f�K�Ηsm��B���0��[2[�1XT>lw�`x��B��J-�e�L�#�M��"݌��N�תF�^�q%K+�Ԋ#����q�R`�gb�W)l��IȦx\�_�rC�3���o0�j�T8��ݛH����z��d�(|H�bZ���;#�l&h(Ov�=�2X�\����e���LQ�L���V1#Q" �ls뿪���ݓ��ܒ]����G���� -����X¿�W:�\y�P�V�
q�ky�eaC��0>8UWɓ-��x���6!�'nx4zoCj)f��Sw6\�MtހV�/��G �4=�`%���$��˞5��2meZ�����פ��<���0R�E����P���31���b_u0��#7���Ѕ2�@��� ��K���ܝc�L5��S��a�#?����Bl��LLw֠��=d���d�k}�=�b��'��[1BdR�6B.���Ǌ�L���g6۰�{֣1T�%���ex{(�JGC�l�ޠȊ���P�$��^r�-]ޛ�΍#��e�.�7��"uv蹡<O�	�\/
�ʻ�h0�O�����6�B+H��x<���T�h��E�I���[���sd��C?m����{�����+�j��G��;�ز���2�S�״@���ݙ �#7 ,���w�Vg� T�|O�����E���ku�x����~;��^��]��B����!Xd�3m67����t�r+s���0O
J��0 �&s^"���#��K"�ҙ�#c%. YGFoʗf��=C��Y3�`h��WR>������_fP�Zf̓|����M)�\�V=`�cs�<�;�k��C�9ޟ!�E�k���/+�qL$q��d
��PY���t}=�}����p�n��S�z�z��->�JC���8F�)��lV7a�=H�I�`*�9x�苔*v	!�@&E�.ºƈ^5q��U`F��:RΖ����ϒGj&瀻dm�^5H�G���Xv|�)��X�=N��.<�2���WF�XO͞p⩪��u%SǊޭ@0����=��d'9��R�Q�s�Z�}�|=�	�F���(�b�Iq돽�d'��R�w��$=�K���˪X�)���Z9lz�Շ���$r�Ώ� s~�e~�x� �p�W�B��-Y����e�"b��PЄ�n_t��g{��.��Բ��{ú���"֧9ylM��>U�HLhˆ��{:򖓞!FI��V��C5�F�^^��q����!����g&�fF��K��2�����Z@�D����j_�t]�_�j���YM��l�)#薎^X�g� �*D��@}b����r��j�.\a�u���gr}�������S��� 'u��|�O��֚�aav�w�%������? 5d��	0�O�+t�`��9 .��+ܗ/�J-?]�m���a>�nl�:��v��?D�P�Vs5��t0G�fuġ�O*��|�����6�%d�D�'6��[b�'p:�>�|P��v����.]����JdG�x�8�TVz� ���)�1�en|@���&���5�$JԶF2W�sĊ���A	$��B��g.u�o�#̴������ƐD���a>�Y�qHo*��uAz�Hj�}�����y�~$�&�skۋ�KϦ��ɮ. L������
�����-�CQj�ƽ<��C��CW]������3���rœ3���A��l�K-N�,��.ؾ�G�Kπ۹�"3f4 �I�#�C�
c�lڝ�S�k�.L ��f��e������9�~#�:�bοy�k�\�	Q��㞙�XY�$�iJ}�R5��MFj�/2��L�l$�X���r����v�� XQ[��O�J�ڱ8%D����f�V���
7�&
���\uU�4ߪDA�Aj�Q�j �0��![@�~V}�������e�����st:A�iE(}'��vrn���82&kޝ�6��}n4��lp�Ja50V4�٪N�Dn
)=�E�ގ©�O�f'n0�2�Đ��IU?�QbĔ�����$b�~�I�-.�T��op��>؎���w��0J�<��}�{!_-r`�y��l�]<W�O#h����z������̇�u��mG'H��/?^���=^��N\����ߴ�$�@9�#"��<&�[j�������Z�����'i�d���s�=o5� ����I�]R�P�	��1Afu\q�*�Y��A�Gu��#��B��n��v?��%-��"Z煐t�-ԁQ��y(��g�?� d��a���p���A|j'�:���3`�b"��������V�VO�C��ʚ�0G���|R���f�� w�iKןX�9Z�C:��t�Š�iP.�~����ڞ����_��~��э%�$L������=؃�97� �h=�]w0^���)�U�7Ƚ��&���?��Y�t���n`�5�~�}�Mҳgb����Oa\���� ϶���C�o�o,V܄�HnT��� x���1v�)؆�/`
�|����PG:Oa�c�Q z�K�"߫&��}�խ/Vd]�!q��@���������30
ǭ���� n��z	��?�Q-�ЫAH�	�p7�qRX��w��� ]�28���T\?)���`Y��=��'�����)]J�x��N6������p�=�C�X��A3?ɃUG��h�X�_�8`hHe�h����,0g��~�ll��k�w�Y���G��$����j�f��$@�����ͺ��B�? ��c�!ʅ�
���a:me~�UV����͉����tھ?U>H�Nn�h��rW�5/�(�a�f�A_�Msc�U_��F%(�u�A�_Y�tE���q������	&i���h��\]*�֘fm�{�1�|P�g�I`,�����O)�~���4	�c7Dȕc��Qߕ�_$R\x>��BL��ʪ��
������[��'���E��l�̾E�;^m`� ���&�}N*�'��9�
�V�$4�:���8�����]�
��M�'�~^K�;v�345<�7�Ĭѡ q���ϰ�+0;��1�`�\��GW�4�;�73�V�]�����ڵ��0�e-�g=���a�!�u�N�G��Ν��Uh����� �Q�l!����47���Ár�Z-Qb�H�����F� ��V=���N���7G��$x�l1�&�@�<�U����>	G�e�6��k1T
������a0$���]c���&gt ���hv9�οl�l$�
 ��6u�9���O|
}�r����Z�q��S���V���N�PF�7��܂����E���#^��A����[00�ʆX���G4����3�u�Nb�,w0��TQ�)��گ�@��C�#"�s�Ka݃{ pg�w�U[� H�Jm�����/'���殺�Z�=m�����0H�����Ϣ��=?�R�Z�
6�b��������l ��#ʱ|ދ���	-�m����u:������&z����6�n�v3F�,G�X�H�3>���B�?*��g()�-u#`(��_�0]C��n�י! �0y&��)�D��d�Z�b�I���z��	�](6��K����*SOy�57Z���)�#o4�R� ��x����;�Q����o��E�ۺ;��ʳQ�
WU`L�J���u�w-ڢ�J��B��?��9�s��1��S��ϔq���OzG�^��a��}Ih��&%V��^j9k��j��w���UT��1��@F�[�ڭ�t@�(�`�`���m�ovQ��☏K��w���-xI��%#Ҹ`���(a�DާڢGd�C�&r �S�H$���z,��Y>�}3{o�R�,#[������D.�M�w���P����W��:�X��&�\�����e=h ������%*ɃBML�y7T�(�( E!=0��doZ�������*��4-�GM��c;���̳IOH���9��+$P}D2�p.�����v"�3"qZ��`�\��C��2�T@��)fo�Z�s��oW��}�`G^����4�a�/϶�0HlnϘI��I�X�N�h��E����N��̦=3���3���i#���u��
Ukr��<
���ŰTG��ߏ�6$�a�N�}������:����݅�l%�RTd�(u��H������V���U2M���֭�_r$��?Jy\ELdU<�09b~�t|H�m�N5C˔�&���0�?��r��q�?����G{!?q�ؿЄ����*|��CDgaI�9@;ݘ�$  �~�>T�:�ӻ�y�H��\H���ɷt�}�`�'�V3Cm�) J�Q.��`^�w?�ʳ3��.���yF��F�zvcKX#Stի�YM1$��O��E?[U����l���r�^���n��傧JΣ쨖l�S7�!fз�G��&�_0cJ�h�Pg��(g1b��^���%Jk��K��VG��u��+Ι�N����C�DE$�_��b�1d��$v��Xs���v��E�b~=�/[�J�˦o�9��c�����̶ ��#�K�6�[�.a�(as������K\k��,���}�������M���~y8� XĪԄ*H���>>(�,'bB�R������u�/��T�[
�#.7tw�o��S�'so�]������5q�2�m�D� 68�%A�䢊އ/\�6�ȳuy3�w��=��p�ݥn��fG������ ��~5�Y���'Ǒ\�iܗ񻛆bK��h�զ��P�����G��.��>e�Z�8�݌�5bTɔ�Wi\v��Y��"d�����x�͐���۫�+4�L��Q#{e��W%c�m��C�g�f�݊�Rz���=IQ��B���{!�6�V���� ��t��A�G�]:	T03�b��"b�c'2g\�	�\�lk�ҹRS�|BS��}��)t�fq�!#�s>>����9˼]Ǐ#�0��. �Z�Ǹ-	8r�HP)�H���D�Nq!�I�;��a�}���v���� Ī�-�/^0wr2��L�V,0K�]��(��z�(a~6�.7y�'={�~�g�a�2{ӏo)N%:���� i�i~K��%� C�D{�t��ڂ�$��&&�ӈ?1�`MFh�Ǻ�쵣�����v��Gf�
�#�-�lج����#�*��oS�IhŹ6����h��30�@�(��SAy%�LЇ�H�SՌ�M�����F���<WPMkY 7�A:��T�K-�]Ǻ�Zb�~c�g.������ KFB���#3�ѫ���l���	ӽ>*��̩��b/������Yn����h�ä_���=?�Gs�p������]�ۈ�U����Y���p�m4l`uV�
'�<��~;\���ǳ�	��ݐr���[���m�� Bȷs�v�!��,�[!����o�GY��I�\����jc��Z&���fe�<�B�e��������)�O�)����2D8Z�E�9U������1�+���=�h]Hη�+��5�(���v�j�m��Z|H�q�;��O�I��� �Ԡ�H�6��{7��3�M|T�E�����e�Ov}C����ju������k_�_�=�i��9[0]tA^Ʈ����J���u��/�:�uTz�8������	�#�̠�����GPfOR�̴��u �#㿯���8̭�j�]�e�ޯ���cx�C��X�x)j�{e%����u�li8�W�|�6�s��۵H�X�ۀ�xc�A�S^����1�	[Ϭ�}���'��.�G�J�~�p ����"^�ޠ�}�L�&�]��|�W�.���Tq5�]�f+��<���L������������6��"�K7x����*)e+�)Y^B�p�E��xg�t)���K=�&�#��%�$�JE�5��8�����R�y�lv�ljA�-��s���^T��h�!���@AJ�\��Ӥ��p����j�vp���f4��O��q6���4��l0��U��d�4�,/��!��Nn&3�w�t�?���L���3�K�yF�۹�';�vT�|�/I����D��X�5�k3D��Y���լ1�+e���^ �DZS�O9x�]���=��S�BX�"E���~���+?߁�+^�l�����3�`�� �lb/�EMD���/�]9��/����I��<v>	B��<�j�F�n�a�qĕI0�2*��3��mn�׷(@L���[d�d^eѰB#4�S�q͢]ʶ�;EɧD�іNh��FE/�<���w=�
�{���jp.��[��};e��m��jh=` �o��m<�	%O�_ш��{a$+.�G����[���N�a���Z�PW�� '���0?d���~)'Ô�H0h���Ϯ=�'�DfzS�||K���ei����POa'�j��%�!�~=�i��(��1�P���l ��4% �\��,�:��Je������#���p,pJ#��=���S�#�B��D!Z�+d�p����U̮;���,>��>�����ڊ^��w"�+:zp�[,�։U�~�X!��?�=Yɼs��
ķ<yG�:4���F�o�Æ�@�¥�4�#_�{��ե~]���M���]��D����>q�;��@jy0�0�bI\��x��,b^�ܑ�Zm�ӎ����������ӱ���)���w����gW�A�Ϗ��.#�5�p�a�Zr��%P��C���>8l[�,!>����M!��Z�}^%8�jK;Y������ڼ6��Q�u����pA�{{(�[�.i�x�����]�y~�ܲ�1g��Y����W�;_3Y�7���--�|�$�K�N�T�e�4��x���@���Q}�����5�Gv�F�Ʒr��!�HkE�fѸ���o�$�A@�6�>y`��^� ?%m����@��YƗI�E�0;%�H>�(6��p�jlџ2*Cg�E��%J)�(�;pB�ۏC�� 5r
B.�Lo���g�~�㩫6�CopyƇW�Ʌ���՚�946��(8Bφ�j�ʉ���}0�n�'��	nu&�&ϓ�_�Orx~�B��`�ULB�ّ���G(>�%;�����֡>�yZ��Z�Z|ׂM���s&N7T��Ss��5�G�mJW=p���(�w
��f^+�q�� �I)ŉom��)��B0g��a8�GuW������}�~�XbL�E
�����
�=�CKjS���P���3�
G�l@��4+��$��X�CM#I�@=yp�m�HUjw�Y�Ă�)���7"���������qn�к�[iҮд����h����XM��B����4J�'O4g�Ћ���p3Z����bO&�w7�����H��_�"��1z��j�����) �]�'��j��(��ژ��y\���S�U�e�RG�ޒ���Vд�G�Y����b�pe^o?���2�?Pu�%]�\��5�a�	@�N��F.\^��&�OTs�0hk
۔k�;"�t��?�^ �\v���c
��'��:�|<`F��=/���Z���7�U�~�l��R�C�gّSZ#:���Q����q��S��z�+��y(�Դv@'�O��!�3]4�=��NN@U���_����#�D@׺K�w�u����6w��Դwf�9L�i��N�����1%����5B�����r�	_��ʧ�ȹ�2ˉ��O���#��������I��h=~m<ߟę���z>�gd��H.��L��0�$�A�m�+�3�R����]���d�"m��3���b�R�lg9F���`f���T|��֊����B-����y>�&���#��~m����m{�<���M(�>;l6����Y�y8FGRS*��f�Q��*{�TS�c��#�
h�A)���'g�E%�'�[�~�:O���^<z����CLZ��M�9�}0F�l-.�AX��=���z�6-���l�2RJ�
��=�y��*M��评'6p��V���4�П�u�_ڊ�XU=͚d��y�#��g���^����8΄)@>a�H91���K>��A�����^r%9��e����N8�9u��R�_bTm����'�T1��eZ�%i�����&@><{=���bŰX���� e�_#�쾫�{廂�J��������A�Ni�ު4O�W���S��ݐ?���0<8u�O��t��˾|0���+��@��rӗ���Y%�d*"9��`��.�J��͊�8e�C,�����&��(\
_&�(�|!N�6a@��;b�}��M:�]�Hܬ�E-���.�XLQ�����pƲl��_xLE��s���s�[���?*J�P����T��H��$�]Fh�2� ���"�P��Q^`������g�G����=$S:�aV���w��;)/=_�Y�,Hst-O��?�FœQƴd\�nŋ}u5�q�
��`� ~d���񯂯H E�r4�Tl�α�G�f2���īm0�9�GD�����f�Km^/}�Zw��&w�-�7q�?n�Zm�ȟ꺯�|�J&S�#�Y�!y!�<��5��Y�''��V��_J'��������Xc+�)4l�2����+�(��T~��0��;s�[�Bu�*��zU��c��y�c3����z�ٽQ�V���z�wD�7\�7%�ۆf;��'E�}�h9o�����%����;b|������V��q�X�+�T�{t�_*�XÚ�L`�������2�[c+��!k�^�f��8�=-9�1�PN(�z�2��Z[�\!ז�r:�7���������6/E�VNq���������UI����x�-�0&��u�D�{J����I$�Fлr�ȳ"���]���w-�&�G��L� ����2�L�!�
.FB2�M�P��BN~^d
���q�E����
��70mQA�,]L:
J��?[�л�^�⒴�Ӽ��F�=}R��u�,�Ӹ0��TjPGߢ��'�8V'_7�܍�{����"u��~��HϜ�]�j��,�$ű�=��x�y
Z�e8׊'�D%�)o���jDRq	�RH�^8���&�� "�Xj�Qf���N^�H�"{��SE�]EChJ������G�^�7���+3k�	���G�R��߼�vc͝��-�;�Fu��w�V�9�z��T�N�{#^�	���jI����p�U��=
5J	���C���ɪ�Ze��V�!b{nJŚԤcZ����(�p�Jf�)��8�$�t.)��lY�c�����~[��KOB��x�v"[� ��¬w��&?�2oH5��NDT�B��v��~-00�Sw��0�?��5�KG���5ո�����I����,��!)v��X�*��sDR����o�42�b�m"�9�bc����k�_M��H�H��?�aR���Υ�+)%d@����E���U�VX����A9�cP<����kѷ*�o�%@�`=4�������//����Z��zld5oUS�1�f�R�ܻˤg�FGMK.�up2t��,O�D�Sݻ�A-��Ba"1݀�	<����8�E��:�{"~'�Y����X�$ղt��ߤ#vZa5{�}��:;��F*��7]��Pݤݰ]�ړ�#,���3@T����DqP��Z��s�@��M^��M�>�V{���P�
��6�l��l�}�=Y[v�$�t5&������RV�*���2�T6!�U
JҎ&�ģ)v��A�(B�4��"��a���RzV�4~���᫼��\D<w�; %��-QR�=���ݷ%O��1�C4�բ�b�ɶ����`+5G~��hL)�0�~�7��-
=I:2Ara���Q�+�G^G��٥r����TON�$��H�ͬ�}��V�R������%�)U%�����֑ ^)��$�$v�<��^0�'�#|�'��ʘY�\R��\X����=?j��� j\UǢ)��ݎ��@�ϧN�E��p��:M��Bt��z�/��&m�_X��M��IV+�%)&o��K�r>��
�r��X�%�1�{J��L 㑓Y{�S�t쥼�VG��x���?Ȫj�z�z�ߟ8U�BsE/4�i�5E�y�a�&���>� U�`�D��G%� �O�c�e	;�}6���A+��ىQ�y��d�F�i�)YX�Y&"��L���G�B�S���]:{�$�|����i�qt`�q_��L��bA*�F%w�7+b�zy��,0Ѡ��R��>������K44fz�'V��@���R�S�B�
�A!���D4�辚
)����8V:��E�_��t@R|vH[/@f`���y�����.
0 �|R��&�bh ��5�q���Z�v�������^��Igjɮ�ރ���K��t���T1���1�E��|�T���	�T���Ði%�^G�����)[d埙$�����>ʂ��X�^�Ά�$:�
5��4L��{Kg���G����6���"�<V�P@$����)6
�>�c��4@�Hd�o�)�^t�U�
st�r�0]7j_��ں��ƴ��e��;#��O����d����(�Qɶ��.-m�?˿�o���$/�ݬ��B'�'���1����sVZ�<��'k���s���d`Xf�}��;	`#5�b}3�'���5�-�u|�=��B&�0H�Vzƾ9���lʺ����هv��P׫23��*�p��ByO�֚`�YB��S�/~;��K�8���R�g?z[ jͳ�����g����L���m`��CQc�Ӆu��#m	0�E��b�)�"���A(T��sdR���
���Ad�R�GIV��<��R�鈢 �@�>�	�����ɉ��C�z��id�������߁�|�����z��-mߞi>�c��f�����
�XR|g2���(�[�h�u��g��l>�WfA=Ԑ����cp508E��"h ld�=4;[�
<��C���T4�g%�?��4�� JqR�$<�z���+L�uZ�"'���P��h�i�ܿ��Q��	^h��fO���>�1:�7Ò�Cl���A�0�)��.��R�ҥ'e�YģJe�f{���"�3���u��z�-;�do]���2�<\��\ ��,�S��St��;�ա���;��j{^+g�pA�}�����IUu��m+V�� ����o�f�G�`)�"D^���圡ܺ����DSB��K9���I��)����u(��RΗ������!�jS��#a�M�l:��ÄK��O�Ćnz���y�,���4�Lz��^B<ޤ �!����@����:Ֆ**T;�i\3=�����8<��0�$N�@����R�����'B%[�L��vp3����łGm�� �t�1����t����K\b�AC>!�3�H�5��^K ��EA��,�_.��&�G��!>��
F=i�d��c��:e��>,�l�e��2�܎����M�G�$��'7���Ĭ��T�5������ �o%�}<��l�{匀�_D"��muS�r���T^8Q�+�e��f���3���L�Q��o�,��3�2y�k4�&�g��fYN/�7��+_~��:�)	צ2|�[����_���"K���+1�����j��`��nXK
r���Ñ\f�c�|U�ܒ��l�ez�����H���W@3��`�IKkd@8�!X0dxY{�h���3Kc��V��A����.�`Q�Q�wZc�a�pc�eg ��x H^C�1%7��~F22��x��ؘ3�P��C�i^]��gi�Y<���6��j�
�A��?��#����o�"�
�/cl &���?��n%2�������yg�ta�:�t��A<x�Z*d���5��'��y��rh�88��	$�z���si��B��FA�UA������X�wO>�ɤg6*e0�R���$F� ��pfh/�ޭsc)˺����q�@ʐ#��5@NH`o�Ϲ�s��S��r�8]=�$�_�����SS�ȱ, 0��V�]߂�6/s���!��ď���i>@��wm��O�9�7h!Q�Gb�6���5�c&o��Q��4�׎u��T�n��
Ŭ{}���;i����v���eŋ������2u���(+Siԯ��FԈ���B�0X]q�a2�u{K�(8l>H������Zf�O�Y���~�3Ex��D����!���\5+���]f�d�q�.��qS����	?Q�����h"��~�3��<6�t�:b�9L"m�'�tM	��H�����p��	mUy߮�w�S����ю��!x��9ef~�AP���c`�"��x�.
W��Zk�n��f��f�6�����h}�)c9����tK-f�ʌ �
�ܮ�g�"|Mڬ�U;��@�q��BE���$Y��kVC��}	��o9䬀����w�4�[*F<{�!��g��>_E����?��;}��u�/j�Cs�D���I��/�(7���!�gB��q�a���KΙc�n��q��z�
���{�f nr�ʤe��[Y1 ��B���ĕvz�0�N:Ū"����$�k|��]��Q�e���Ƒ���)EK�Fn	��Mz^W/i��|�?=n��ψ��s�a*�4$B�ȿ(���w�?�?��T��v㘜�8�MI��;��N����0�)4r[�cs�bd�Mr%>�%���G^��"K�Q��Ze'sVp����U�X3�	:�X�N�@z���x����?�5�rP8��Z��7�ޥG���\�l�@g�x\=���Y�իZI��1~�z�d��m��ҡAUVz��2�� ,�1�y-S��OK,oږ�ŉ��璉`#j-{��tF\6�eJ:UܒO��i�5�[��.c�8;��:� �RF���D-k�^�Փً�2�'@==>�����D�z�e�ajisG;�}�E��w��G0�i΅���/���&�5fZ)S�<_�$̎���`4��r�Z����}�� ,�� X#�~�N�<���9��5@dJ��}-��CG����|�� @��� PvTS5l"v�b�?QS2W�v��Q#߷+y�����qHW��,R�Ӆ
PD!��Ɵ:�d�;�"�1�¨<���N�%���I*/Z�D<��v�v&��HOe^n���Vkbp;���ŶBf:s�V�ev�k��hu�U��lZ���a�&Q��\b��9���:�V��U��>���W��x�Jy^M�w�d����<��HO%sEV��DG�φ{44��+m.<&OԎ5���uXRR|�1�[���d�I�Q��Z��BjIu[�2�1��R��*�M�c$��ٛыK�Dg0\2��*�NHF���E%�����o�ϑN�s�����ooi�@�[rл*��OYi�T��%�_�.B�+�H�ɚ�txX���R��ε\[Z@ሦ��t#�7�h1����~���qؚ[��B^3���s�ً)q�]g��l#]��gI����vE��$}iFjo0|y:�J���/��9/U�jK!�C�~����yQ��	�u��������-л���B���J��`�~��� m�9u��1:{}?'�V���wt�w��{���U�8�|-f��$lK�۹�q;C��N�v�����fwt�AG�~Y8�{/�(�Y ���	[8O��o���-��D�	��y�-(�l��#��~�o��5����2����d)^F&� ������_��
�:ݑ�q(!�"���{'�K�z�n�!�ɘ���D� ~<x����3dy�dD!�q��wi��vg�+Xfiݲ`�	4*��jR������.��>��˯�8a��թ�O��k�V��B*�\��m����ݭ#�U=&éK
x���G>�����y
� w����`�аg?�@�}��8aE��I���R�g}�53A#H�EE��zR>	�!:VRN���xI#�c�E�!��e�`�E�ȓ^ѓ+����9S]�@"��)I���Z�b�����r�X
	2��b��脷%�߹ؤc���'s�G�4��銀��V�a��L���zeZ�N߸��0�P!�܃��5�i�$�e���q��*�ps����d1���;&��wbK�uS�ac���+�45GPOn�TvEnY�?�>
���F8߫!>��x>�kXn��i_���I�ղ���HXn�kڑؑ��>��Q�I���r�϶������f��<�&�A;�{h���_qnˑ�zj2����%ېU+����6}	=����}�Xc�,KM���)�P�0Â�/^�0:��/����<1�2�����Ϸ}�P+� �7UtS< �Y֩�zh���S<+�G��K�ʄ����~L�O��,C�烜��G�;ȶU���l/#�.���S1�OJI�C]I%�NŽL�ǞB��Az%�f_s&�r�:8�%��J���B�T8�{���A�*����ξn*�x�\K�r�Y�H.fĥ�{K� �=Y>��,����AM��EB\a㡯��o���q���j���Gl;ݠg4��t��6����,� K�et�(۹�g�v�C�΃��G�UC�;��g}�,5��� Z!�jND�׌�n�Xx{?�F,�s�K��v�]Nv���΃��Ә��]F��b{�y�����{���Mr+��o����X �M?�}�ڨ�/udEo	���3#���ה=z�x"��m.t5�T1�W'1�u_��/]`~����!S�fAW?+2���#s.� Cs���cђ��[pO�KN���59�9k*s�΋�u,h���V��n5cθ�5��o ��97i�9�^a���3ۊ�u8d��&H6�6�^��s%�o��2C-\(��[B�a*g�vj��鸼OE� ը��规H���*ҫ�lJްT��o�yu�0��������j�7���Gm�	Y,K�N��G�"=�p�Ð0�� �gO��$&k�r��پ�/ t.���{�����5/���~��A�!�0Z�?Wi0(���h��]@��ˤE�T�ŋJr�6nU��uiK�&��.ۜ�$��m��<��?���~�{\��`�o+�-��B�����\��]�#���ε��D�ɺY�'�U�/ש(�@4��z�8Y���i d|g�:�骘k�S$*��B���!�����-��2��6��� ��gw�3@��@�_�~���ҫ�����NaU������u���S��L��o�q4߰�Z1�U��ʳ�]+T�F1�)��~����Xq{Iҝ���ē�m����h"��!J�K�Q�2l�ը�Q���谡�=�+��O���c�f"�sr�|�N��s�ؽA�&�<``�n+�v��� �A�Y�V�Nmt7���K�G���	#�|������M�H�=�)��q�S�[��lP Fa;#eoQR/����6���ꕐ�{+�<���]����F�Q��[�^F�tp3q;hvՎ=�:�NCΰ�=� o��I�xJmؠ�>#����}��ɛ�		�q��(�t� �({�ӄI[a�l���3lym�U�C�U�:"������UO.��Y��j��{�.c:��tg�@7�g፾�8�H�sGJT���'|���sHE�S��?����ŎB�P�>�`�Z���A�5�I�>�V��쪺�P�������s`�c�?�.ę=��"����ԬH��ˈ�����Uv!%�����k���镄�#�����Q���xMN�ď����3�x�|��-˸μ��C��i��CA��w��&o�����~����bE�m@������H�`�+W�k����>矌�`6����:����_J�2�G�Wv�NU�-׎̯���
t;�T���Dc:���r�U��o=�Ȯ�x��מh���(����p#`��u�'>������¹m��f�����|�K��\����(����t���&���4��s�Ͱ�!�b���k�Ѥ�� ���z��z�bX���Z;c��%�Fm��L��yD�]��ME�a��3Hf0z�"�JppR�_�]u]r��B��4;�����`o��!a~����܏��{�l!�@Dڑc�_�xd�喬O�h�>^O~�:\��ꎍ�OHS9�S��4����i��D�#�\�@3x�y�ˈ�P��b�ƻ?�f�"E\�,Ł�ळ�}//�KY]���Ɯ��Z�"a�����&M��g����G�����o����9�=ޠ3}n�w\�~��$�Z�#�zd���X�ݤ��[��a����n��B�_�j4l�u�t���)��7m�I۰�.Ժ�&N����Z�&rk=�Yo�t��h� ���1ޥC��{�]t�A���@�5��C��-������J����Z3�j3�x1t�Oܠxa�o��
yT�BC� �>�� սPZ1@
��"ȃ���g X��]��)�s��Gn�o
�U9���qZa=��s|eÍ����G���F3B �5	����r]q,�f�syWG��JF�[�9|�L�mGPjcޑ�nH�^�"��O�N��	���3�E�.P��<!i�����[pq��+���.����#$�7B��hl��<t+�e�Ȫ1������{b�C����<&�]%#)���T*!��q�&�3���P�<�&���Q�2E��8����[N���af��24d�`�f���v�{Z�r�M
�	��Yx�ە��نd#�Lz8�aa�N~*7,�z�N�u�zu�<y:(���1�����ģ�4������M�zg5��ZBʝ���7�+V���?Sm��4�3nn��pm����n��|�'HU��Ǣ��Y�U�I����Le�dI$�.����ޚ-9�	���(m}�PI�����E{������F�,E���y�T��P!����s�c��������iF�k�B�0Xm��Gu�{���밨'�}����}@�G�o�_�#g�I�5�s��yԠ���$0�����z��_�O5&���ܴ�C�P9cA^���֏�ڕNm>�7�� �R"]ʅ���9�W��}p�[^f�� �tq��}����b�4�?�D��5Pa�Ħ;�ʟ=U^��ѤBȝ��n�"��A>b�c����=�y�ZELG��7���y����>��?��!��_�8����	�Hy\w��l���N��e�|г΃>w�Kw��%��I��&�L@��B���'�̣�1��
$��~�f1�]Î�Q��l��\ ��fn"�,�������\?��l���r� j�t:�������5�:�S�Ǿ$I��0��;jB�a�$�0�<��� ���cgpHĜ��',��J�n�}�<ߑ�$YK=��4��?+ڹ2;��0,�����M�^�����,3�d/��z	�����[5H�H��8h����1
�-E^�8����l��kߪ�}��<����3�E�B�K�J*���+0���m��"���4@V�&�cL�8i�K�9���ˆrP�\@��8�?����3���I����u�V�uP��#ZX�2�_H����.���\��g�6c�#�TSKm_�;Mȍ�)F�4P� �mJ��'�4,��Բa�^rL���{��2�e�R�5��N��%T��=9�e�<r~m�!;n)���nR[i��P�A�|����j1���0}
<�a��W�	�F�p_�K����0\�H����h���O�v۹ž���gk`�{��r�s�,��	�7�e����H��1��	蔒Dt{���-�פ�yj M9����H�M�0��^�@�ԣ�̀�9y�u�0^l�Z*�,`H2c�,�C|sy,/�`b�����P
�_������̧s7"�NJƫ9��*����~l�qH�^.��-(E��H�^U�}� ��w7sbzO�;Wǒt`!����p�M̤�tIa���b��*����y�S�C*	%�O��������ue�M�u�%.��i@�)3q�J?B��h�焦��w%�����B����m"�Ma XZ�\g\��i�N��&:�P�F��f��+Ơ��J����۞ c�e�jE�b�޵nMl:������'�#��R��et�a����y��Z�lY�ﲬ�]\{�1�
������[*���>4���+[�uÉ���<W�K/e���]��%�ҙ�.� ��6��^l鿫��k���]�U�!���G��p��>1ncV��Ή�U��gWB@ �~�~�`d�6�^<�40�� �lл̗�
�ѣ�ٲv
����h1W#�Ȓ�߄ �D̕�*4�usOΤ�]}[�cKP	O�]�v#t�u��w�O.����>��0��IHӭ�-nS2!�'��b���x��O*⫝̸�w��W���A#Ϻ�b�vUj58�k
&���;a��*�.���>Z0N�w����	>_J���5ӱt��fm��M��:kn�-������ȃ/�ta�$����&��5��"�Y�x�RU�s�Lbk�p�
䟝� S�2[<���Gy�]T�[m��2�;��������ϰs�2�0x�һ5-�m�T�ѝ �K�{��~�VU�M�0/M��ҲGw��)��*�}(���ap�$�
�8�MOr�S�HBs�<8�1���>�l�Vs�1���ҡ�8-��n�]K�b���Y)���,�{<���K�!`�� ���y;b����<��[�D����7�XvRN�������)�VA/�j^�8q��MY��$�A������2�
�K�*F�q��G1�g�=]J���b5����f�ati��&���;����y�c Ac@�x��3���{��	�$���+<NC��bY=*��x/�Y�WN��P�&�a��c��a�E�"��h	izz�+�rT�y�E��"�+�޽��jH[��IѣM1��A�@Vߔ��D2R$\.�>ȉa�݆��P�8x�3�\��G��b���.���%��n>��-�r4�o���{4�w'��c�=�w��\���CM,h�݄��I��{�]����u�K/	8%�	���Ɋ*���rZ6=v�&�]�2W�A}C�p�	d<�~�ŉ��;am$�[�5=���E��H$7���kV��NVV�=��ܝ���k��]�b1?�A���8�2.27P���y31 ���1U^��O,�X������=ߞԑ�C�1o>rx��j�s:(S��"g\y@�Đ��I �|^�hp��V�=5�ha�x�}26���"�
"��r=p`�l;�]��J�M��AG!:��z�� �;{)y=������.	ݳbd�R��E�ߑ����x����|�J��ՅX��&,�����|j�5�f0��k"!^� �pn���K pi��5|�K�y(ٱ�8��޸:�ped'�Kg0�a�M��w��\,6wFYB!5�4bh����B!�,��^:g�;5鯰��9���v�·�"o:��Q���~iK�B���_W�����,���'M��K�����iȞ�Gq��"��8��-+{&�nE���NQS�������tWZ��� }�SUF�ItVť��|ah�D
_��Ȉ�.�����t���Z��q��яQ6�ag7K
�ƽ��h�#h�{8��6���p�+������D@ ��W0V�H��^R�� ��3Brd�W�kH�!��XU<�_�D���=�s��|��H���][���>gb�aD����ߒQ��CW4e������y��Y�~1>/����*�R�xǢ��U�"
Kr<T\N�4���v9  ����G-[ ϶�� �{���g�    YZ