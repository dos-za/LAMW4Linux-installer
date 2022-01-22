#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3727652176"
MD5="87a091a89b2c8761affc4597162df47d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25800"
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
	echo Date of packaging: Sat Jan 22 02:36:10 -03 2022
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
�7zXZ  �ִF !   �X���d�] �}��1Dd]����P�t�F�6�.L<)MD����/oέR��lj����+@����V�N�O��E���']25�E"�{�:F��m�t�I\O ��3=e�L�n��i%��A��^��-��ꏫ:ծ^��	ā�f��J�|/����p�v��z�M��Ϋ�*[�&��*&��]��=C��_�����N�o��/=!wL]���>��N%��(�ui��o�N���ŞJ�	��ղnە3j��%q�o˻[�%����~���+��p�_�Y�2��1$��`-g��?��f.��Bx?����]���)�����QͲˎ��}̱���3��/� UX��֤*�D���Ӳ$����'8@��I�~�w�x瀀Y�K�%���-0 *%ݩo<!�ɋ&�/���z��
��b������dl�k���𥴽�:�í�I�)�"Ԥ��˅�Ɠ���M�W�Q��#���8�R��6�d��A搦�l�)c���K���Dch���Ibr��a��a��� �0����U#�LC��e�h�{��v�i-�U���X�L%υ����D��醕\. b��s�"�K:�j�����c�]C9`�$��:�D}�,x;����.7��/>�M��ڻ�?��J�f&u��I�I%��G�`�\��k&t���w��۔!@�uP0��qϦ��#Ute�W+���:g�D�r_(x+cy!�� Cz�w��"�e>S�.��5�![V7Ʈ/�sepG�k�yM���	�Z����Ng7}}��;l��(�u:7L�!4�6�g����>�����E�Q�d��j ��ۛ�j�&(AK����4b�v)z���ٝ"����
��I;"��	�7:շO��6p�	�5|���$�9
t Un�p nU�8��I}����o�:K����'�,W�<N���V/W)�wٍ���˘X�f��RL���p��i�f���H)q/�[yå֞gi�P50d
pړD����wWN��ėI�5ئ�����`�'��e]��A��q�'G<
5�w�ÀSY;��b��#%<��#��Vr{�K��p�E֏ڍ2�?T�$>5k�j{���Z%��>���ێ����~æo�H�����6�9�׍�'[ym�Y�����pi&�9y)6p��ΆzYy�5TX�(�u�ѤI`�H�!Z�m,�@J9�ͦ�ڤ&�C�uC(nRR�����[�k���p��o9E�:++j���e��?I��Et>���r�'}:?f��NډB[��q�Y��
��a��G��8��'g���+'D����Ǜ�7�5%nK�"���=!���9h��S��bS���t�gy����J��)�5���M��ٰ��������#�A�����|ü�N�Ø��������k��v�*�
�7<��z����.p@&����=!>�OE�_�:�T� b��h�$�Y�+�HV&��G��D�P��OP4�x~��4�bU�S?Ɍ�v鄴��[��gM� ��J!�x����g\�����VI�G51����T��"��e�HR�ш�C&�5��6����k�:�?Z����L��n��b!�QG/�걌��F�hg���� ��/� �7-�2�m#'�HJ��U�����?mǈ��?�)�M���Y[�K�V,;�W�y6Ļ%��V�����5�zc;[��c�JB-j收2#d1/X�َ:��K\�|vc�UP��3#����=����S���ߑ$������� �]=3���o��@���9�'XH��SK�� ��B�/��r.��v��z�+>���������<Þ*��k�5��̇��4c������ۺK���+�wA
9ړK&��H�b���"�ԋH�n5�s�X`��^�<)�z8�Qk���@G��r�1���DQ9��^�C%sHh���ɥ��w�vy̌�[�}%�Ź?E��Fm�Y�u>S�a<�-I��׍�U	H/�]Ò�'�s�d�� 	�s˷eL�Dw"��F�O�گ���e�Ym'�����͓��������>{�u@_�7%vi���ד���?���2/��M,��%�d�lq�C�U��>9�P�,����Y�cp2�=c����#j"X(_���Z���}u\�Y�B |�hR�V!8~8CJ�"^��Doс��2A��ڜ���z/j�d�T��� k!Y7�U�T
h6_�W��v�!�j+E�����1 !�S�e�ڻ|6`qr��fv��P����6��6 ԉ����4SF��*�n��[i�>SѶJ��9p�M���<]��s�9x���Xw|�o�L4�e��>��6����R�jV�	d��"��H"���
<�'�X(���k\��������:R���o��c��>�h���D%`��4H�OJ���W��P��~%���H~����\T1���0����1k���a	�D����hXi�����^EЏ��/5y*�h�[o����ď'	����+E�1���Lc��P��ow�N��!�y1���>��y�N����_V��7U}g弬�������;&������>��Q���}FثW"���l�[ ���}8�o����^^٭e�b �z��oA]����o�<7������b=t�(3	Ĉ�uQ�������Ӷ4�}Bǿ�~�X���sC_U<�%�f
�i��U��.�KG����X�xsj�ԫ>�?(��U!�Nq�ikϑn+�An+|4��IGg�xݿXo��K�n�'����������	Hs��Sp��u�l#�3�Y^�C3�<�;x�M�}+s7������t���*i�S�{��w7?�4�8���֍�]:��y��Ȓ�p���h��go�_���ZJ��ٕ��G� ܟA5���>&�3�~�q��������>X�Wq�("��Ul�SQuІ4��"�_��)+lo s9��M�$��amc���T�}��Z�|r��k餡=�L�l>j5�F�Ė���hJ�)�?��8еc�c	_v���A��D�4%�d�񨠩z��(�#�V�y����i%8<2�Yl�#M�9g�7g�bp��`��b��K�f���("X���lIg'�{� J��~.��]��?^K4Zn� �z���$��+���v㏴�D�(�J`$�j����9�UM<�n�P�q���[mDS��_�1����K&0������A;5�a:5~2�9��cŚ��=ϡ��B:S~�s/dʻ��X��nZ��x(�G�=�
,S�`����\�u�"�q]��P��.ӿ[?�x�J�Y���g�6A�J���`\IR�h1�_���I:^:Q	yUɑ%@���Z��^��Z!��ea�h]�����r&���-��1���	 �������\�9<��r:Y�/�1r�z0hDë��H�'������(c��)h0�̠�|IO��T��\��$�}@�#.R ��Ư�lE&.KLe���A�v�F��� o�=����O^Q�n��v�vo��F6㜩~��m�m�^��0�Kf5�*&��/nP�Z&�K���yH��òP��ǉ����G��u�ht�:���~r�)�r;5�F�C$�m�#OB@���7�X�%yq��]�V,�j��̃[-�1�q���[���YԔ=�X;j���0.w#���~Cڀ[�"t��Kמ1i��zz���:z� rt��p�93�,!����'q+��.Pw�Qy5ذ�bj��:�;9�N�y� ��AVÕ�hR'�광� ����!�-�s:��c�͸�����Ѫ��w���Qq��\�p��a^�K[��	����<  ʫ���7x��utf�AA3�(��᛿Y�S�+�n]Vp�@���A���K}��g�ZܘV,�����@8G�+S��L��=�w��ϖ����D�t_
{�|f�<�����Gٝ@ :2� T�f�V8ƚ�^���醍��2��b[!^�-3������Uڭ�!��i\c�!:�cfr�N��jb����������k��V�,J9Ӄ��?`�E���bPn�=��d�m^�	O�����4�mp(a^_3moA���)X�Ar'��(�+R;t�~�����յ�x����唜w��	[6�Q��"��eLvQ1��2a��xQ���� M9 @M���D��w���c�o91N���ީ�i��R�dpn1����mW�Q�&nԙQ�c$�b�kd�d���4ǆ\�T���ă����Mf�Y.���>��`�o�l2���>�����=Q����J�w�tϹ���"]M����lz�T+ۦ����f�
s���?^6A&ΨT��(v�t�H-�z�SW� ui�1���� bL���tf��}�2>�J�[�Ƨ��i�k;^O���Fư�X�����=�N��f|�[kOg��r����(8�*�����!]U����w�KQ>(�����ZT�M����D#�Xl�{`σl�]���-�\�c�[]eU;"��+�'�q%gR�i�p����(�]�'؊�&�(Z'���s%>�Vw}��[S����E�I:��2����ے\<qL�0��gi����Y�k�\v����OW�~"e�y��/����gL_C~>YaB�3n����*�w����F�^��պ�$��&�E4"6�t�n�r���c����'G��N~��~\U/���}ZHֱ�n��p�/�<��h8]\��F����@8�a_�2�;��}�\~^ �ۗ�'�Kz���qx�vMNz���+���o��?C���T/��(�J����v������i7��q��u�lg�M�+�0	M�J�>�q��Ҡ%FC����1z���.��juQE�`���X��*gq�/�n�ry���xR�'�윭AXɧ��<:RW#�d��:��(BSD���Ť�km�<�@��8憐�J2�B�˕��}��>^�z�{$�H@�v�����z�t���,'D�o�n�<ܚ!�O�A�\�}������V��9���#d�\v�?Z�����H_m����M�n���@�k,[�m�� MJ�4�s�T_̡}�Y�{f���\d��㺏ACĺ���e�`K����k��L�����խ�Q�"�OI4��y�J�� kj�ך���@�$}���g´:86��ܸe .
FD���_��� g?�;�?��:a������]�����J.F��"�΋|K�aCd�<���η�8}p'��N��}{�Y��?2D@�ULT�/�uZb�'�@F��|1A�U��!c�ɢ�16H�t�";CNȔ�ۂ��k�X&���B�Rj.S�ɛǸ���N�Ý��o�9Z��=�]�����``Ҡ
��	_�l�=�ԕ��لwL��C�Yr�/ݏ��[9"�ڌo��Q;���,e��DJL�Y�JCٝ���Ч[S�����A�C� ������ro�*#�d���5�:F���4�0�����N�5e��H��`�O�\����~�pb�)�� �h*�"A5(t�� %�߅,��L���kP�D�G�[�G�L�Xl]��D�~��ͪW ��gK�ώ��[����x�k� {G"��$)z�0`����z��ׁG�}ó鈻6f�`(`����jy�+���v���\���c�F�yF��1%dV�� ���n��G�m�\�m�	?P%$ަ1�8Y���B��lL��_�6��š���c�;o%�DɁO��<��~<Q�|�yp9�Ca&e�Oh�;�u4A��k�kx�	MQ,%~��l���ſ8n2;�>��Xy,�?V��!j�7��/�,)�+4�^=�/�硫t8�>�K=Rg�G��U1�۔{�8�(:Q2�c�3k��[��5�3ɿ�n�`�&U�d�Ɨi�����K�=J6�K`и��R��q�<Tw7Dɸ��[L���B���Dx��t������n�j�V��}�a֍6)&�=l��_��a���V?��G0uT��o��0�Eͅߎ}�N�r#i{A�$��jP/�%vK��j��rlk@�r�]9�s����IB4�+�0wuohJ@��{9�;#���%A��97l���s��Vl8�����������Ӊ��?�*Ψ��L"+vtJ�W���bb�2t����OR:1hKO���> �5�<�T��F�y�s-޻�n�9�sy�պV�ٝٷ1����O�[�pB3����0#h  �M�&(��"HͳH�ҝ�ʰv+b��
��Ћ���%����+��u/��e�kz������h�&*,` |2�Z�?>O=>f�� d���2L{afI.�,X��O"	�
�x�!*��������} �>�lp�_����-Q���=�RC����������1Pd�{6�	�b�p_�De���^�0ңTw�l�1$��x�{-�C�ޑ�B� �<
5�J�7�G6�VBD���b��?���IK٭wzW<675��.fk�Z6����$Q/�E���Gs�]�I�Y��$5`s�㷥eT������H�U��<��PL���1/�k����=E,���->Gm�ڠts�?9n(�E�QN�C�Q��^��#����-�Pt�^���ljI�:��;����-�܋>6~@)m�7�X��E����o��CK��8D��{Iw�_�3�pV�[V�-pu��*я&j*���ղ:�
)Vt\��N����,�П���˷�@�WA�A<?�������|o�i$5��C?�M}�g�]���PEd����V�|���8^Ṯߡ�j8My�!r�n��9�k�>�c��G]�!�!�>ஹ�2�MI�������&�s#�<т�@�5u��;�8�;���2=�g7�#��m��NSn�K`�)�h�rf�����	��_�O�$;�������?9]R�ϕf/�R0q��x9Cьk~�#�$��G����n �8=�M*�A�����F|\-�rlb�p�ԧ?|��lx�]���n$[ǯ0)�5���q���o�9����Z~c�ͩ���Х�%���"X%�y�֙��9�S:N'j9鋊��>�x�h/��5�u�+H�3�'��]�&�)��Xn��ĐP��l-��^�o��Y�8c�������
¯{��R�4g���W�]kt���!�ݠ���G��;?��{.Nͳ�C6�?U���+�G�=�݆����^?-S�-��"ˍ�$�	�}��S����~"���T�7���7<��L��,�׿+��/��O=�(|���;����&��o��>\1ǐ�(�c�\����ً��?M��J��h��A���5[Ƒc��AW�0 5=U��7��+_�� ��q�m$�"�]ݡ�0n_����E�n���CV+Z��T���d�یU�S�'(�V�T�.<��Y��,:��N푧�������r-!�f=7�
��A5dUd���Y��6�y,`�h8��5'��Z�j��ڪ�~��]��[�r*�|�`xT�(����ٲ��֯�Vn�'i�)K���4����˅-�a��}���.E�	��A�}���{b-_s�I����ś6�<�
*��p����Ү=6&��J��rE�e�u�`[�1~)��f��/	�	ՎUv�F/4�O�r���~T��\�copy�/��/bcM&}��~�����G�d\�hB��T�s���j�ZCrmk�xn��n`���˸j7 4C�pj+�{�`Q֜�u��}Wr�韒t��ɓ���h���m
vj8a��%�i��Ѿ��*+�ʶ�D��m�2���������f`�(��x� ���2�;r��LDo�*���+�Q��]�!�w�ơ�*�_,`�r�QV�ΊLe��n�m6�\�4b�%�H%�a�XLx��X�n�s��t�N���S�]��>�^ZL�����sg7ܧ�h�K�{̹
��'�*{M�'���C!��I��|�B�
�s����U�VT�a��������cw��ɐ��T����N-�4b���v��["~v<��r��=�����a΄Y�]��,:���8S&�j�j���g&������4�ae�>S�	���ϯ�;и���)�/(��O���</���pL�U�=3����VJ��8k�.�[C1��� �"_��H*���B,���A�4����d�[|;h5N�B<rL�gz���MaBy�[��	e�֬H��9�J.�噯�����L!��tX��<�MZ6lhp�Ν/���= ?9��)�rk���j��/�y�z?�\qe�}��p��Ŵ��{��AJ�w��g����M�o�ܵj�ӠBa-�n�8�ni2�����t����8�Ǯ�/�*D��+5�*�-B�.X��_��,T����rqT��ҬM�P_��ƻG4�{� ����4״X���ss�����fR�
�u#X�o]e��u��,Ut-�d��$���6<�����w4�����j[$���n\�p�=�5lp����
��~G�{;�],5��g�$�6
J�����W�-������{i8X��I%3x��Csh��V�x���DY^�ű9;�R��Z�K=K 7	G!�#qۀ���s��z���U@�4>tq�yPj�Cp��2�Y�����;���-(���R�̗c�,a��ް{�zZr�SD Êb�������Q�^��G=�͹�a���ʞ�c38%f{.$]W�i��' ����-p�d>��=1�J�j�	�6a��s�\�w�Foṟ<	�]��݀q�{N����J���72�����#q��R�DNw+a@�0��$��۞5���=d=_��v}��J-�1�+[g�ld&Һ&��x�A����gY}y�3.�x�d���1�LA���`#�O���q)u����W2!C�����i��X�#����oײ�gXI��H��le)-���v%����a�nD��k#U�HA��L����������w��L�*M���a[ �$nRjJNVru����G�b��5S��4�@���������Ѿq���pE.�T|�T�B�TPV��:��ט"�h�H�-�x�?6V�NI$�
7�d�gTR��G�6���W'�J��2\؅9
zHdڇ���k���E�͟[�]AR{&v\Q�p�¿ge � .Eh��m���S2vW)���b�{�l���Y O�"zՌj�gވ�C���'��V7���.Np�߸��FU%�{�駝�]ID4t'�Q�$5T5��l:��3�6���G~+�Ԝ%�[���<����.w��'>KE
UWE����d"��m �4������@��26Ju�<���P�TC���z��Q7}l/f���C�lT��k ��]��gE���n��ފ&�VtS8`�5<��i�h��$�:�p�+��U��Yl����r��l��W���mE��XE�W:��:(QrR>�1Z�TGT6Q����B-;�W�0E ��ݡ!�;������Uj���+���Z�ՙz��A��d�����V���ssn!��9�U�ўBDL���8ݙ��_k�Nx�RF(˫�:���s��y�@�h8�#��bK��z�RS�H3yF!��%&i8Ƣ��I�%ynʝlB�}!����N���r\m�N�:�:�]�}���:n�����f;(V���!�	��I�o�E�|2 %��1�o�d
�5Y92c�o�33O�:��Y�� �R��Qu���.�KP����G3I��B50pm��,�ٯ_�"A�n/%E2՛?�ټDN�l��/�j���$p����A)̼� ��-+�����cmw˳���pq96�t<�}Cϧ	_2a6k������/眵��,	K�tgxU֧1L�����)]@"J�SR��%x�As(��VO�-����c"ҋ���W/�lO�kI%6���99���	c�5������(�izwR�ф���	��~��fz���l.�UwR��nB/u�
��Q��q���,�� �D�	A��GmCB?�:C.R�8�H6cx�����h���G�����p���������\v��7}��yF��Р��&��^0��\���`=$披U�7������<�$��3�{��5l���0�/{Gz�̲�I��<�n��3�6O5Rna�X=!aS��=
߳�р�pe�h$5sb�\߇s_I��16=���	!����H��A��[����^�HM� v��(���"� ƶ��y$Ǟy�t��f���e����E�W~��s �s�Iq C�R�;$<>%Ⱦ9�v<��A����Ȍ\����I�-3������%����<�Y��d�����MTz���xC����5�І�3��&�����Pr���sPU�`v�~��y��/3����J:�c�H�*Y�R����I�&i]O5��T=f^п�.y��sJ��0r���Rv��֮b���A7�־����P�:{M�5�_AMϥ
�:{rS'1��V�����~�o%eN-"��Na<JKB����䗫{7�*���-N�o�*��)�$<u7�"8��옍P�����J��q9j#XD�K�{@�
�,ʊ6�8��*�����p�áb���Ze�?@�X�]W�Zw�����F�+� ��|��e$�)�%Z�}��Lg�zM0F�C�.yB�^���Ϯ��gA�1�2s��+=|n��|��;սΌ��UToJ�s���s7e��J�,n���d�Q�dw���e����`�j��P��S�V�qP��Q��9y�ƥ�X�0~�q�+��ƗÈo?r>���^ �U�m��<NW�$Ǩ��BQ���]�'��O<*��)(B�����8�9�ɻb�ѵZ	�%�cg��B�"�jt��U�5MT�(B�y_l�k��=�zȧɇ�L�6��%����3��4�g�X�;XT$��'���ѡ"0�o�9�
z�V,��H���k�uB�
��z_o鎋�M�P%Rp�컄�N����0L_N�#$ T�@�ϒl�~Q`��M��9-��O���]�jb�1cװԯW��3v�']ӏBEwG�9�N%M��N�]C�h���spHfU����l�]>�;-��҇`vN�߽�����gRު8@����N�O7`6�-�ɸ��i*��5Vۖ	���!��A�ev%�&(�G%�j��k��ur�!!�'��̬'�\�L��=��o�.�p]A��R��x��& ��b���+�i�bl� ,�e�_�������'{���N�(����'b+KyE���~VK�8\d|4K<��̲�2wk�����/����tokXŒ| �K�ҏ�-͠$Fv�Z��`^q��Ms�~SqU5󝠕s-"�$
�N���t<3\����x��Ge8¾OB��#�.<�Ed�AÈ.;������n-��}@.2����	�׽>�!�+�X���c���F���F��xRH�5�cm<zK� L�қ����8�ie�E^F��X�R1����l��
�baVz$fa�5��OOb��L�Μ<g����<�O���n�c��}��^w�|@}f�bϯƢi���)�����$X(버m���Wp��5� N#��,��3	I'��8��~��T>�|r�m��j�u9�/A�w�B�I"�aa�U��H"�*��oH��uQ����T �	/���@�ʱ���}!�֣>Ҵ�|��5^ƓK�C%�������;��/#�G��_���!�K�ޫ�Z#GN�{Ʊg�|N[���CGn❣#ۡUY��x��Q���?|����ߜ#�����k<E��(��z璫���Dw��)�$*!u ��K�r���q��w@=ʣ�x�K��.��	���$��_q��S���z&���@�<Mb����nE��B�P���-�o~^Y<Ĩ�GS���!�0#d�6����j̯DG��@�1{����-�����%&���KDcaY��Iؕ�f��9���`Ҧ&��NC�:����V�/��:���p��쇇!��،�����?��R�QR*iYw����\��O���gb�r����<Fuҳ�K�|PJ\��A�+��?�8���Җ
b�Rv*��ĺƚ�oLx�����)ȼ�M�v�[n8�����b��w�g����?�n���Q�,e�X
Qb
����T�Xϐ��
�
�:C�,T��CU��TmFb��x&��m�U��gc���Q���K����TP� I��H���!��7���{g�}\��m��%g����b���bi�&��rU�=�M9�8O�+�ɬ��f�)9mN�5�VG�~�|�}<f'yܖJ�Mw��&E?�qї 2�gz�%�9B�o/���|^�f�}�&�j^~�:�(�n*��2�R��7�c'y�f|;>O�^���l^�x��J|�G�\� t�%vJ��.���G˃B(�J��Ag��i�w�+�;�&Э�f�QqHs� P��J�W�vgyi��0�kJ�����P�!�f���˫�����O2��kWp��������9��׵<��ѷ�x��A�WbM���k�L�alCЙ��A�xt�(��}&:��ʄ����ʗ��N���fJ�~�\��b���H<Ө��s�J��/s��I���f���q���@��W��Ū�%[���^T;ui�R	Fq��I�"U���筹;p.M�@��\�阩�ϴ�������W{�ek�Ԋ-c�QPv?�l��
�Q���>��딪�P{`�ی��ņ��JY]�UU>8�|�DMg�l������7M����8�*O9AWZ�P�޾!�W�q��H��H�Շ���6���O<�I�l�AcE�ʯ�����CSI����4���w1�R�J�D�#��7��}�s��P�F�6\N��+
�R��z����(u��v�)��+�n�1X���j���|�z��N��x��pe����������#p	�!�3��^x�^
�����iR�y>���~C�C����c�:�@�X�p,t��?�GZ�8�<bx����_L�şC��U���
M�]�3L�]n�@� �.��HK��*k��{�yXOM�P!`��>r�I	�"���W˟�G�ҹ.9i������d*گ�q��ټ��[~ l�ߔ������튭�7���ڝ���`NG3���I�K�"2]g��^����i�ݠ��k�.k�a��hM�%P�B�=��C��R��/0�����B��O�l�5>�����e%�MzW��+����p��Ό@.�PE bT{(~ �NB��	h���ߜ��.;�j�� &��$�\N�c ���m�ͳ0b99�9[#Y(�����qn֌0���R��Gs�Ģr�-g�*�oH�x=�ݿb{Wb,�*`��H6�8t�����O��`,j��:w/�� �Մ�Ϯo��&hݬ�K�D&��c��/X�Y3��fԤX�
�~��]'H��0Y��X'kR���l��:�A���x �1j�.7�$,��V�,ګU&�D�#�i/�Ӻl�O�,N>	S��S�v;���^GP��W�*�ν��Z~Dj{RO��|r��� c��m��K�ș�y*�S_��Kk�� �y��4W� �����?����"i���7<ָ��K��PL��ݷ��F�����T��0���̸�)@f>��Q6��>L ��M�	$�L߀zSC�!�h%�ZO5��}�n��.�H��/�c�G��*:dd^˵ȡ�]��-��+��Ҹ�݃$F\J�Y)�}.���h�`A㏥m^��4�n\4Z����:��Z-��=/�9���5����6��X�ꙙ(��m}��3�N=�	�ep���Pk�&/f"��$]fIL �8"��pA��=� _w�`<�-�Hvi��m�nl|�bEq���X�^�S:��H|��л�%l��3��t��X`��jGX�za-Q{�,�[��F��Ơ21Q�$z�f��cN��������Ҧ�G��#��IA���ϲ��l�����D�-~���=LIE �r$|@�"!6�Ֆ��Nl#"�]����f��j�WL�Qp��F�[�����4Vd��#���D����+#`���a��o�("��Ja|�h1)��+d�2���f�
��L_v�ZNq?7%_�x�0.�����ф�qj>o/c��cX�_p���ۿ�p�;� eǘD��-G7���������)p�q�HH��� Sޘi,����^�硵���\�`:�y� p�K�?P�͔�V:�� q�j���r���p�鎛f�5��^���JcF�P�d^�K�Rɋ� Ȉ=�L/�:�G����/���	F�iq;�be/�}�k�����h2�/��˛�Y�^M���Ыj��gD��f�N���F�ެֈZ�qp�bR+2@��2\hc���j��&��y�~Bs)�֐�C ��;�\�V�W_��`��R!ڋ�1��%y���rs���ߞ7�C�� Nu����8̒�_Vv�-Q�k�0V1ҷ��`Ru[��*^�T��H�4r!T#�1�v,;T<�390��lZn���#�j��͟�����g��S��Y)K@�-�9�c>{����^�ǒ�)�{�	��9�i�g��}�f4���s2���!��ۺc�b�P��nbAT�nڿ�"��O��� �S���Ww�!��tT�\N�	�(��ټ�o��C�pQS��Rο����a\6u�2�z��/5�A���<�2$!�,5u�����%����k�m����k�\�����]C�LX�O��A)}���!�<�;�,x�fb�?$\~\@(��Q��,��!�j���e�0'��y4���^�zH���Aː1y�!"�6���h�SAjmE����͖�MC!?�Z�Di�Ͼ���R��a�쏟�aW8�$#��邟�� U�`ݠN��{,c1��N4��UH	T�s'�0r�8:AWCp׹�|S*]�3�n%�;0	�"-�,�+Ɓ�]���Oz5���d�>p�\�3lc���i	�^n2��(Ae5Y�/���Y]�Q#�[�45E7c�7�M%���@����a�Q4���{.�0��7��"fu�
72�V���o�A�h&�,���B����`׿@��k��9w9�qB�9#'��{�
&učj�<����b/���S-��F�Zi�D�W�+M���s��	8�z�6����Iw0,��a�����s�#�L��ݸ�'�4ԧ��q�/��74(	�g�9����Pʋ1�	����G�IH�]$Յt�c]5[��O��^�����~�푨4DO\������FX���2m嬊�)�[�V�؝��F	�ۖN�����*�7< 1�䋼�O	H@>���\�����2�ERM���.�U����$8�,�Ok�6�|�,d�q�h8V��!z�l:#�!�ݍ�z�����f�DJ�6Q�3S�H^�ĳ�F��q��]
NЏ0��=}CS`�,p�d�!�����7Qt+teQ�腧.�?w�#�s��s��D�C�lC�,�OpA�2�} نQ�0�J\�ӯ�؇k��ט�WY�?�.>B��q�Z�A����5���6�!u;9���뮓���j)����rF�o�a�>�Q2��)x����ߦ��Y�EiEA��^�jq�vB�Z�4���/�q�� ^�N.�Pe��5�?9��#o����6�W��]灆��a�S���K<���������/����JC��:�9�Ҹy��~�+�x���v�G�T��ޏ�<���_	G<B�o��Y���7���پ(��p��M���efr;r0�.��������"�+(�:��[s�,�H�������y��%,mc.�ۡ}5�C�t�P�$6G��ݮ#�*�!)VQ"��6|���HO��,�����a<ZQ���s�=�R[��&��WE����gRH�mG�Â�$L�:�DI;�̚���!����>�5Yk�X��(�������z��n�4*���-AK�}�U�c�A5Ğ%���7aa�oCT"���:���x���8�<"��5��b�\�v@J��Djj�D*���@�T�-9j�� n]Y��c��br���ƥ:�D�J��b}���}�3=,.|�\�=�` ����?�����J	Ƭ1���1YE�Aɵ�k�hܗ5��/s�_�Ҳt���Le��eX1:�^<VdG7�й��C�y8�+�C��0�x�f#I���υ��o�O��]�
u�FI@2�j���XP��ܺva^5�֓�ߴf�ۿ5g(�P"�������'`d�d�=9����\���듯�ڐ��ծ�TV�+���S���vQJ�Oϯy7� ��I[X�<E�~��觑s*ێ	Pqoyx?�
>���ֻF�ě���)���W��? ��&ǲ*�o�C^�>�����3ą�賃1wˆ��`�3B�,B��J��>���RWX��������(����3B�J�0�dQ2�9޲� <�N����6-��z�ý
��좩$���;����,7(�=��sSg��!��\ZH̹|a���5�h�f�-ݦ�a!��ۼ��P1(��ȟr��P���'1�.�	X�����v��"�"MoMQ���)g����$��M'�g��Ӡ�z�E��`��Q+�g7�d�{5�k�J_<���~���'jm㊋���gĖ�n�pW���(�ߩ�Vld��*)�B\6�A|ms��T��Ŝ ⫈��J ����Z��J�Xi^���?��I_��)�NVUY��%�M�3�]_����d3Zߍ6׀��ۼL��8�{��]������{�ʺ�T*��5�Á�h<��?#z��<���Ѻkb��F�)�ѓ�k�~kxI2pS��d�8>c����R���!�vR����m������u���p���?j}��q�Jt����Z�hLܝ��%fSJ,�׷
�mnY�tb�s�g1�i�\��%��#��WgN�Gxg�4M�x��A�����CZ�d�����slf�J���%�=h�dw��$��&�����_���I7P���(�"o�&1��X�v��s��q2��t)"~
���-����)���C�y�G��ͻ�0�x5��hS�����@���@\f׫�4Ό�2�o�;�����#+(���(�{Nϟ>��:��ŕ�{�`��l+y�F�!�R7�zm|��NV@xR)t��w��RG�Ň�NJ,��ժˈ&�Q9ʂm/\o%��R��P��<84��j����~�&���D#�����ğA+�yvI�o���m�+�^b\XҪ���!�PMM&ba����*�凔�[��pL&���bF��+����31\D8ȯA1���p���a_����z�m�R"Ķ:w�U�%��*�Do�9��֟�6?M��-��Β��y�6l�Y�nHٞ�H��i�����蟺R�#��6F��,	"t����}�hX"KI]'aS(�>cp�����oO�De}3�Z2\�vN��*�&�lY
H/�T�V2ؒ��FI��1�ޏ��ǶK�/���x��9؁J]�RJ���D
g��}Ѫ�=5�*Ip<��$�o�пJ���'��[L�J,&������mOZT籚n(�-q�+~i0�}Q�$b�e|�Ԟ�X~4˞i�.�H�ǚ'�*��7`�OMC�n-�,kQh���m�n����ɸ�!x�c��㛔������ɉ�W��t�V�)/��/a܀)@m&gES��}ۦ>R�W��z�XT����?�m�,֡~�t�1YOt�1yZx$N���cWD�Y�bR�>)`
��U�g���&�����6c�1�596������}o:�0�,�Qx=Y�	��'�r��!�DЬN�L��x4)q42cE����?m�T��|���
��䎀�9d(������5O�~�Gm��G�q5�F����҇�U*%�K���Бц���W �h�@����(&��l"|`�d$�S�(t�Z�w:���+쬱�V��/t饏J�o�n��}F�I�����V@�s�N�G��
`1젋�>�~8�������8mw���,�j���1�Z��o%�b@@&���FyQ{�����v�הd�eu}$3O_`a�����<�p�X}pEi�%4>`&a��۟�Ԁ>�fN�k���o��0�͹��s���!8<IdMt��z��N��0����Im�+ԛ{���]�{�틙�[�Ѿ��DA!)Py�;]f�;&&��K�Y##��������ֆ74"�2>�i��+���Ъ��!jSi���ca��fe7�����tOÔ���m�.ӻ��G^I��N~9�M]��v�]}[2B�$�ǰ�62�ߙ�w}���mޠ��k\pь��
�`Dr�iY�?����@����>͗n�)�	VY���"B$��'2��Kjhofė{Du����Q����c�|��F{�ls��<�Jo$7�Mr�4}��h4�%z%�!:D�@l�_&I�J�n�%\�p� �U�]e$\`���܅�!}�'�>E3Q aT;��y�y+�[_a���:j�R�8y?�l|+Y��b��`D�OLgJ�b'��-�vF�|��7C1Zً"����`dt��Ai �į���@���3�Fs��^8 ���	�A�51'nou-Ͽ�0�W�Ig�L7	:Ip��Q/�WdDM���m=֔�c�S�wá).+�}�h�:grm��ܯ_�$��P��/�<��@��1eTO.rq�;�)#�.e)��������[r|5Jd(J~����J����z¤��Mdح���(ˢ|�R0�K[�
i��܂멬U`ɓ���%�����m�:hW�"$���oc���Τ����F��$�"��.�"�5�⓴����پ~�Ru	1
�%����Җӡ��q���܍0U/�5E��Qb/\�с�(�	�T�R�np@�����L�uW�"B�*�d�J'�7�Cک�S�������r)�INnAn6�.�ۂ�K9�YP�T���y�L ���Z�eX�+��:��Xssk�bԘ �u��劓 ���+��e�K�tmz�.(��~N?v��ԀA`
-��!c�V�	Eqś���JW��2?��Ȼz=��bWw��sL�'���Q*J�w�$�&���������(�^��3���UX�!���/�#�g��J�n�]�����8��.S�R����Uj��q�lxv�;R�f�����!]�Fou��Y)���M
מр
�q[�%�|�/�adC�Fk���Y��p�H6	����\(��W�^Џ�0�5V@�dZ�ny����#6�~ݕ+:|�]�Ń~�~}?��Z?qζj?g�1z���&�A�qҨ�^ (����U��}��q�>�8T��ꟺδщnh%\�a���;����{gW�Tb���ĻxD��(r�Tȱ��;��VĻ��6�@��=.���.��Ϳ�ؗT�g�N�Sg�#f$�ൔ��Ai<|��ʘ����K��]���_����2� ��+p��tb��KZ�Z�1�p� ^Nz΀�k@��a��}.�k�Dd���_#���d�\b����-)Fl@����I#:fT�H}R��k3�{�Ȓ�-@qgخX����t�F[Ki+�j�t'{̣��Paޤl�7�z�(F,߭d%C�~���WU��t�$�'�cZ@�tT���;r��M��x�%;����h���N��|kA3�d��N�;�"����aƌ�Mr������tɁ��<��x�CZ������Ϯ,����2��ic?��*��K�a�/�.8�d%D�7y���ݠk��~��u=Ì ��Ẹ8��i���Tn��;*JJ���Ӡj�s�y7�c�����{�S6G[Z!�o8�B	PYV��F�״��t���R��΄=���J�<�r��Z�X�?��R�SSJ�o�Uӭgn7��-Sn��{m�|��۶a�U�����h�6X%�VH[�E��aA�Ai>S��]u���H����.�R5h���6� }�x[dt��cMG��ا��oNv�kh�#��5�B�?
�����E�&3�SQ
I��Ӵ6NX��R<���ǹ��?�a�E��V���m�kh��;��H��v��t�R��n�9ǫ�7Ê�:6Z���h;���"��c'O��F���	������,B�'�k�Z��"�����/�`>Z�Ue.��G-^�:3=d�7?z)I�9�Ƿ���I�&"o5�-���v��
�!�3��v��6`�[�zH��e�`++o���6tx$�s/�a��z�����%lȽ�c�?�YP���ɦ+��W�Q��~� 5�'�q�?v��{�!`I�4w�Z�y���%ѬW%6�Xp��3�Ad$Z|�[.�.p&��ۚb����گ�1�O@��ډ�5���p��Dk��-|d��Nm�������?)4a�tPX�-�rI(���G�Ja@�͖0���Bs:�ᙍ Ӱh�H��<G�5��ݮ�J���g)n��GT�lZE��!���.�n���H�bߧQ���vEO?�	��1�gdM8�GZ��N������,��9�<҆��]@�uE���sa�U�<ЂR�� 7�ә������̀r-
��QR��[��~�������)�*������`v�i��ĵ`ʲ���3B�T�ͱ��l��̋jJ�d����st>��?t�P���������Qv/��� j��j�Y�ט_�������f��zn'C����[��1�c�L������͂��&Qj�Tę��nZO(����򢹦��J�Ē�~}�r�B_u�%��s�!�غ<ϞVN��ڷ�{rQٶ�k���s���p��6Y�#�h�@�T9��t�b�
��G��:�rg�y���i|�(�|���m���M�t��^��z�~i\�q}�2D4t�[�:Y��2ŭm<����BZ�S�<�6���p/I-���W�P ��V���r��&z�T!���Drz�[��_�/ެT�j�ĨA��ôA/�IB%5g�/��S	m�/����ĠMx`�r;���?��<�v���n�R��-S�1O�Z�����;�u�3¼�=���������Y7D߭(�S�=3��q9������]��r��fP��q�3FV�8��y�6�e�Ƀ��oU/�c�n_zJǠDI u�1�T�;6�/I(e�l���
��h�u�L>�����^��/�l���%��'�ޤM_�ꂝA��{ˇ���%žWV�"m��MJ��8p>|9L��#N�R��b5��z��y�����m*fv|�9�E�����[�����_n}W����;B�,�-D��%q�1P�nWhv�� �K��"�t�G�`�i��((`:U�i��U��Y��p2���jO*��������ب^�y�Q.Ɍ;�S�5u��֥ͱ����M�����'g�I�%�c]���gy��>]��(D9��@�m����oVǌ��uluS��β�)��;��#h����W�Qy����ذ��)����Lp��e���rx�b�K-�~q
�~�p�'Vdc/� j��K��O��G�*Ŵ�UUd���� =�ZBi*5G�ùe��z�BU/+ñ�pT]!�ʨ"��H�n�����5beT�lZ����K��K 
1��'�> x��D4�v�u1�췝����ld�c �;.r[�&�顒OCl(v��s��zJο�Cbӧ1l]Nb�+�Ww����hl��E�}:[z�|�ゅ���m�����}�����O(����L���K,<|S7q�\eB|�2ɳ��}k0��+��وn)��ݣZ�3�����r=TD�p�s�,;'_��h	�_G3��I��H���t2�Ҩ�{Y�1^Ҥ�O�"	��h2�0�v��I6��GR�>j�'�} j��������Z���u�I��.%�V9��4���lL?3�}����>郭�VIN���l�����I�Wݯ���Ru�ɰ>Fu?bcS�;�`vmd�n<�C��U;�oU��jK�{�F�Ԗ��m�o�|3��zZ�����Gej}|K.|��Z��*�dC�Z�5٩�[v/���0�H-�`7���d���h���[��Y7���Z����ѫp��LhTv�(z�m�ǹ�&�JSX�Z���K���8z��Ћd�6>� �Ё�IT����|%x�ṱA������1� 
��~N����"A��C��"�OW�kC�a�T���Q} ��h�d��T'� ��
2�� �P>N�*���{� ��ؕ:�b~[h�����r��x�&K�rT��V[1�~��n������.��d�[C�y��ik�9�˸��ڜJ]#��H6����� `�<,>4���nS!&2}��<R'���oj�q�EKLr�8@�L:�"�R*EÜc�3f푹C#E���1#�>c(u��ޥ��� ��n�f�:�Xfz��w���=0M$����*Iim�q�a��9PN��:Š�D������7�f��]3��w?>�p����������}g�>�U�|I���by���vo�1'B�ڼAӧv�c`���a7T']L�1=J!���#��ؖau�#��Mƹ9$-�n��С��x�b�D�f�z�T$>�n�긃d-H\��� Li�;�T�����(�>���M�$t�/��0���5m�ų Bk<��φ�,T����>/,��p~�-��2Ӽ'a@�'�Q4#v_:�{p�"�#6=3�\����� X�q�HO��n�s�)���m�=������XHnR�C��~,���X��҃
�+��.>�4$��?P�[���4%�;��_�qA�!�ׂ�y2U�PI����?��p��8�v�&��v�u�\�3ș��:�S�@vё������G���>Ej<��{�в�d9z\��[ ��baM8M@���I
B��f���>F��t���{a������ܸ��l����iz-��b
u�氉���	+XS|*c-#���Rtb��v��	����y�)طs�D-�	9���赬���<��q��iZw���`��Ϻ� Z�WV��W#G�4byk��S�¦fT+x<�$���`�5²mDJx�����~ 7�[N��0Q����c<~���u\�n՟��
�L�D�!�gU����[���O����f@)�H���8=�>�����x����'��x�W[s�B6(��L���T��ߌwm	ʆ��](eI1�o��$���4���Z�m�Q�7�����Jn-7ɳ�c��C�
$e�Z3��:t��)Vf��d`wE�.���-��j16eޏ鶉����<�Ĺp|&/���R���ڨ��$w�ccq�8<e�I� ��Ǯ�3oeKq�`:bb���_O��b�viաz�;�m%;�����M�q�����'p�-����x��jSdZ��2��$�v�[M���
�ω�J�nա����va2�N��p�/8ZB[��q��N�.����:��K��TT���j�H{�P��ƿ�D�t���Q�O�@Ws�P-���ݸ  ��t���������?�[��R�w��CP�8�).�)*L84�<v�Q�p��\f����2�&Cam:5���5{�*]U4y'Zؕ�u��-�' ���5�OK�&���YV7����\.M�VɁ����!>Z TVǛ��r$�*}<$��&~�xO�'tf�`��x���2@�r��vp�� ���З������Gѭ�e/��M���7~,&�y�L�
�2A�%sp��R����0��2��v?� ��?E�O�.~G�-�w1���>���T�V6��n4�j�nM���*c�1�^=|kB��C�f	�oH4�Y2+��l�]'�,`��v'U��_��s����-���)��͓h3ci�L��lOr#�I�?��]��(ۥ�OR[��I���Ŕ�d�r?D��1	
 ����195O5}��8��4�y�J�WU����H'mY5`tp%������d��r��͝˖ ���SB���l�-2*��1���z��2��Ԯ�	� ��ˀz���Y$01e���f671�QHZ#!o��7v��+��e5Z���i	|�� ��a�~�Zd�"3���%�����YKl4���)���\��@=qO)�4�/�����]�_���Ns��װ
�ހhmf�p�ݿa��eyOY��Ԋ�gI�)� ~��?�V��ˤ�e�۶_��z�B� �'
��sEi�+༖I�� ��������5�.���A十��e;�t{P���k�.��ۢX(3���E�I���F�}��mď|WFB��}��5ɯ�
"�J$l?'> y�Ԏ*֖G�+��?f�`]0z�k��{��ʉ���:*�J�
�{�&������dhO�q��l�5�-��	_�f:��M���-ɞd�n��e.��L�\r[�����S?��L5��.�f>�0�e�tUa�Ў3=oSo���},�&�$���ׁ�Rq���u�YGH�w.N�B~#��Ra�6�U��}�����T?� �g	�oUd��A�����|�gto�������C�Y�"��cМv��ss$o�-A��N��E��I��5\����5�u��@�!�a/�,q�gI��:TP�� ��@����j��щ�V�$�S��;ߢf"�onv�� U���j��z��D�D�s�$�k�����@������o�6�[�?�}�����
?�'�v �(F�.����c=ꇔt��xNH�x�仢"�c������d
O������b�OĜk��Gf����A�z�nc�Tfg��fj�;"��Tq�,}9LB (�!����QEA�X�ؠˍg\ُ�� (�Q� ��CZ|�c�2�����︼Q��]989b�cF�{����㭳&�oR	VK6����)PD��ۣ��|��6Id��:�P���"�n_�jE��j�Z�c��(����D*��&�����j|�*㜜�RԬr��>��kbS<b�����b�@�Kׂ��I!0��A�")5;���(t"ɲ��y�-N�m�x��KC<�����������s̿��f'��` �bN�d��G�֕���(�������T�+JɄ���	[���-������7]|�o^:s>j؄���&�����M�$�-{�χQ�%��lQ�T���{Zڠ�[�i>'E8յCq��*����K�*����l�pR��6�6�u��r�v�Ӑ�    ���O�� ����_��U��g�    YZ