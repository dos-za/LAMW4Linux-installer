#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3127375848"
MD5="a9074805c53c3d430defb8826a77621b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23964"
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
	echo Date of packaging: Tue Dec 14 00:09:07 -03 2021
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
�7zXZ  �ִF !   �X����][] �}��1Dd]����P�t�D�!$�E��pH�,G�Ϣg�q�L"4����$3Z!h=��15�uI��!uJ2X=�J(}#��wxA��a�m�4���R�t�iMH�w�|˰"7Z����]s�N��ҳ�?	w��V�}�f�	XkOΠG��裧L>�&hrꁒ��{c�jn��}�Ƚxލ#�f�k��lŬ#J��𔳫���Nؖ����-��*�ʲ�l��I�z.�����ԻDw��R�Ac��;�Ff��h2l�ۦ�f���b�S�1�u�F��9�\�e�fw��8���}K��=��bؙ�[�\},1��5+K��>�Sya}�X���t���{��B��Z�#�����-P&+E����3�jE���b�/8� �H��eD�L\'��=$
HQBrS�M-m���C2:�k!����L�..o`0���������ɟ��|:�}WZ�Aq�Ẁ9
���%�᝖��:� �A���u�j$�_8sL���.�)���H�D��*J��<�� U��n2��%X:-s�h���@8�7A���Ku�(�ݒ)�vi�&7 "C�4�����L�������\a����$~�/9�Ћ����&���O����j��Eگ0C�/���G_wF}��q��Z�ZZ�i��#}��Xd@+ڧ�s�G�v"�������>�b��FV��Ht�
�g���	M
����I�W��R֙ʏ!����;�{B�&�D�"# �X�R�N8��u��z���,��wh�1B���A�֎������4�s���z?�򌋗J�?2�}h�w���oY�M
)9-LS���S�4}�̂� ��Ow5�$k�/˒.����ym�iT	����Y�,g�i��l��X!G�h�֓�RZ��%ORN�p[�~��>���
>l��6k�r�`��7ΰꜛy�������bP�;�o��������=A���'§G�i�i��YU��g�Q�n�o��ӥ{cپ�Hǧ$�榯*z.���f(����VC�{\`����H*�aڹ���+k�	�݆�h.�x"C������R����;<�Z?��A��2P�pgu�Q�(���|g�r�M����&�/����ﻡH;c���(9_�a��t9���j ��Vf`	�дTZc�I�e�cFK�PPԊ(	�CM��䊪}{��,�������~�PX�t��������k� �V�3��)��l>n3��39v�jZ�d!��u!��~L���ng�d��8�s�DB�9���>�����|�v�����٪�.�u����x=�!�|�<�M�v�K/�Z{�=�&�v�_X�_9®=P��+Vچ��i���O��y�%qZ���Y�����,�} �cc�9w�~m�U&�4�_y
�	�̒���q)�#�M��$�h4kĉb�D��VN����m�;L��$��uC�E�ۿ{�	G	��׼����]�ǆK>1�$8@��
ȹ��a�OT�K2����-����?^�9��,��]�^y���� 1�gI4�$!;���W�f�e��4Z"��� {�˲~G��o�\��v�+���1U�	�e1o�ٱk�u�:�X�#�v��OԴ��d�����q"F���0y�돜ƅK8��gk���,��b��]��<]���^�F�Җb/c�WF�����_"�4�*��܁��v�ԭ(�8-�^rx��媴��Q��k��e���5�f'��z�$4��X	���8w ���Ռ�4�7E�S��4e_���Q���A��<�&'9�6��F�
?e�u- ���6��9_xS��H=҆���Õ�!Z��t�%����!g�d�p��,�B��ݥ��D���6��0ؕ#�th��p�S�R�i�^��ԥ�F�W�	�{������W,Ҷ^i��:騚4uȸĄ�%i��gwRn�;m�巔�K�:�7�S@��Т�8�R�[�Ƣ�jB�R�\��C�������J��ʃ*�>��I_���Lｸ����i���^eB!��^M�8�346A)��&�C�;�X,+	F<��0���Q7����G��}q�%��N�I�����P[�_�~:Ppmu��'���Ɲ�3������T��������K�C�X�
"@6�EA.�����~܌�z�RM�����1)4G0"N��˵�\�V O�E3�o5�E�s�R:[YC��Q�L��C6L�83	���E͛�jp�}�8#���0�'�2�r�P���xP���G�+�p��*�X�~�4q-�q~VG�R!*����h�����zm
h��K���6*<3ΚH�J�\��sS%H��T�HW�X���aȠ$��G��z�b:�J��0���c<���)�4�����+R؟�4 "=�K�3��ɂ��tN�MD�U�T��	p[�V�=���Vfӓ����jt;����`#iwGX���&��Θ��c^�\x(�ï�{N�������ֵ$k��%�!�?�I�<s��Zdj�	����`K�y���xm��F�~��д����P�ED���{8�
˖3$FA�~P^��6[*	?w���\[�LC������rk�ϭ�E3�#�\�����2��@�]��Δ��13�b���.S���Hg�����ω��̺�NDJ�駶�F�G�Rw�]� =/Y�9qzQ�=�|jh�==M3�o_є�M��xDlA��~:�\i5jH٧'i�����_by��ڊh���f���C�'t����[�� �a�׏cE���C�ov��f̀Ӻ��IԌ�����`�B2	��=��
�Y���wW��{wVr�L��T6�<b|��f��V���7:���6�L���n��m��5��F�d��ӈ��j���A��6���أS�D���-��Q�\�
_������C�e�Nb!����0c�~�`���u�¦�e�J��]��^r��M�)� ������^<y�w��)�/=�C�1/��1g�)V!~d�>��:l�L{��ˆ~���'���/�7�=�Q�O�u,�L �~"��0�(����]���W���:|ń������@Y%��M�	?%�)yG`�x�	p�Di�p��w��<0q"Z擪��!����;Orr�㿜N�(��c�;nH����W�]��lI�K6:Ϻ�����Lc��	���A��r�"�I{���b9D��Xr��ݭ�s<a�:0�OёJ�'���SA8|@�)�@Z 3�*������z�!AF
�ٲ�R�6ֈ�3n�«|�A�R�0�sk괟_��.����\�:�T�L��ey���F�w����}Ϥ�~<��y��0�6v�]!8תֺ�����1j����?�Ć�-�v��z��cD6Y��Ž��E����XG�o��P�MVp�CR �t�#���muu|O%�ڈ��@r������X�݊�oM�)}9�4�t{T����ϋės���eS���DC�5��{'�X�E3G��]��)��\%h0|�Y�J����/j]���H��l�?�G*l�G���>nҠ�O�WǼ���˄&ԃ��*z��Q�v	x}�sb�\dA�gD0���3����v���J�!�����]!%w�:����3�G�<�ӽm{��-@!	5�ᚄΫ{i�W��7 �@G2Ű��^,Ø+u�P��+ڏ���\v��u�uP��%����9T���u�۠z�[����D$h��ت/YE�p����l�r{׉{(��O���gm�˕k����1�#5N��N�x�=��3�r]rN��Z>���'�H� �],.~n��H�w8Pl�+�Cߏ�;7�D�W4e�	����'f8-�O@�V�x�V��"�Rܺv���S�1Fߜ -�����ڇ~�'\p_޽��o�OR�?!i��x-�f�a�6z)���[ 5�4�YU=�c����t��6��u�ŸO��� ��r�,�}�\�_oO�P���td��oD8$�#\Hr�Gm���ō�?���A�:s��7a����7��S&ô�!��e���)2�n�J�`�@��Pie��RZ��?�0�3�U���;�w�\�FI�`��$���>Jx�����LVj��p�)i�e�����h?��3(x	��+%�Ȅ�@IUW��(]�$�k��.R��Z	󍅓��O4'i�A>�`�6�}�Jn3ә�w�� 6U:�t�{��F��.U]q*�-aH�w4�Wދ�CT�#C�q�F�������6F�b�
ӂS��=%���X����G�e�R��8�Owf�;s�H�d�Bd�'�f�` ��T������%i�Գ����\
�Xl�?B�.+��+��Y��w��R]�[S/��t�ȯ����dԻ�riC�0�̬�ġ��)
����8𝺻�[r�]4�o����m�U5߱�g�-��+Wʲc�!��N%��Q�ò6J?�t}5��oH'r>.�"�|��}� �"C�B�%1��}d�CRC��k��� �] ���Y3���㧩r����������,̔4��j��!���W��*x�R~���-�^2�C���W#26FV��n��DE�-����D���(ތI�|ķ#� ]�.�Wk'����3?!����<���
ڣw�{��Ԍ6��ښ�ڴz�t����]7�1���]Ȓ�+`���C��^&���]a~J���{�_A:�*���� <����3��m��6�#��H��a�@��5m�"ƛ.+E�������ܴ6�l	�i�����ztR��l�v�3���l	B��k^ N�铿LY�8�h
����/wP�wdu38�b�A����4+8w���(lJ,� ��N5�_2�t�K�̷�����)�]��NP��)~9+PH��Dd+���\�`��̅~/7��p�ͳ֩��x7	����<���Xc^���	}���!ى	��'�,I=��A����\LU�G�C���&J�N���7d[��E{�%�}� �j��w���$ �
Z�O�% �2���[�ID�Ň�b�x�ЊZY�:&����A�꒣{�.y*�?�#�ӭxq���1m��K�iܢ͢O���>yk��vގ�����_��=�����3^e����.�щ�:O�J�@ӥ�78\�c�u�9gZ�Q��j/�A�-R>��aXT�9�!�;Qu�K��A����`��E_b�8�:^�R+�Ƅ1�����W�V���K�l<��e2���|����][���YCp<�xx�)�h�0>�\���� ��qR�ާ�=�:�&T�D:�<�-T��߳?�O�P�dq�:	��R���먟��1���
�Ġ�6hBhs��\����uA�/�����)n��݉���=3#���V��LXI� ��xU����bJ�t�U+�;��Nu��n�����t��-��S�nfR�g��Vrݻ�MQѻ�w�E�҅��DB�d�l�0��"bP�<�ꈙ��*G�J�EyK�]�"r�(�5C�R�;��r]��lccM;�؏���0�T�%�e	�b�f���_6�~'M��M�h��	<�n��U��=9���|�јeVP��c�eM5Й6�׫ط(�vE�.V˴�B����#xz�t~��G%:��J4��3�5��M �u�����[b;?��H0��.�K�����C��em!���n�Q4�7�D�IO��'��ܽ�T���t�P�xgR��W�§p�I�J�ߞ��(�1a�����v@a��A[��1��dr�hI�ڪYƖ6se�&�D��n����vx�X�>�(NU���8������x� ���'��8!�x��}�����.���%��k_��7໱�Q/f*�h��In�ynjM_��B>A������g)dUh�9�"7"�wN����+J70�%��uݗa�; �>��#8�̵o���W)y��k�g����Zi�9�+�f'�
 9������K �:LЋ����:F�ʕ�=޴�����E�\_��� �m�M�}�|S (�?�6Uf���
UQf3�:[�g &}\\e���e�7��_��������~2{�_/���3�p�#A�
���$�#t,�#oie���%��.�u��e,i���[[ bF�B�(��
�`G�7X��6n�FI�!tْG��1�DM����7
�*��ز�3����>�Kᬏ�Ј�X�0>�Fg�I��������T�� 5�=󔴪&X��q��1^̀��?,�ܨS3������|�bO@U�=�u�ا�`[�P���ʅ���C�s����NZ=�O�3�ߟT�*ת��b33����I�p��9ҍ�9&�c�5�:G�qy�����]T�b����c�I��y�� �F�Ƴ���H��_#�(�8ԘO��_x�,�BX��?���f�ׁ��?Ij{�:cm4�����@���k��D#ښ�
&�*�J��ަ�=d�[�X�販tS1�P�na%�-o$B�����A��'�ل��~HL!d%��� A � R�ɖ�ϲ��Dž�a7E#�Bu|��2�[�ʅ쨄��K`�Y��_	�=D�P7��-��9sX��_-�<�N�rg
-��p$�o~Z��i��v�����>��z_{��Cߟ�Ƣ��9�����V�sg�X4f����i0����)O��;L��?�E׏ ZH�m��i3��x��B�b~�͝ใ�h�VFHq���h:�Z�BM�Xߋb��^׭r��5LqHZ�7��VF��'�1�K��U�;&&�|��/��w:f�Ӟ\6�DsύhK���D?������$vC�&8��X^�uGw�Ya2��x��W��#��B�Y�$VKؒ�3����Jp�~���@��&��,���tM͇�X�E��tkwWS8r��n�~]|�4C�Z\Y��R�,�wm�ET9wp�]�Ƨzd��E����~XV��4��BY*��%���0N�f�?�~0�@��Q_I��,�(<����!��~
,N�oh҃+d3��;J�4�Z�p�H������ΉÝ�C'�`�֖�u��?�'�֚K^��}�h?�|��=ú�ud�b�Ђ|,[l7X����d׾k�ti�&.�\Y([�}g��:��݌�t�Q�ގ~�d�ܖ<�Q�C��zKo���=���L�8�2rHKE�TD���\`{�r$�iq�2o�B��'O�E��q�G�8��R����O�>���Č��m���\6pa!:hӮ����U#�m7�P2���7�I�[�`�����AA�%�/�[�bٶ�@!�ޢ�;I���[��d�!�^���m<K߰,�ý�����`�ԳV����f�}ZΔ����˒�8�z���Y�Lb7��
���L��r�=_��J\�@�9뺴��]��!"��ҠԎ���"�y��8�����7@��u �+o��%�fI|��@9�"Ɍ�Y�lİ��%�
A�#��Ql1�����d&�`�	:�O'��ae�f_�	�EEt�i�*䛔V�>4Q��v ��gh��y�F�l�� ��#R>�\Ɵ�8!�x�D�d��Xlmr���b�N3tD���R�R��B��ǁpy��E"��vy���a6���p���v;hp�B�Q�gjF���Mc_P��caa�P���ɘ�x�C3bA�o�Š�p��Wɧ��>�oI^�3����S�����a��=nu�57P"Cp����_���xҚ`��;6�/%��Z|1�^y@D�ua<B ����Ef�1�0w2��p�b��^������ �����`��R;�n�9��@��΃�������p�*:���r�s6e�C`��Y�ý��\�6qHIup4�+M�;��n�&��3Zx�K�j&�~-�Pv-�n� 5�R0��.|(BwF]6�蘆o�h-��Ν0:�|>H12=$���p�r�1,>�������狻��]���Mz�d�Թ��\z�$��`Q X�Y�P��\���A�96��$�-c@�s��`�kLD@���Y�VY%yKj��n焹�!c�Ow����`p_�I~��g��Z�P�	�#�۪.����i�	��5d�+}�{(����n�g���M��D͐�|"׵��8�c[��iy��1�*��:8D3l�&m 9,�	��<��
P�	˫�=[ �»�#ݗ��"�]�3�����*)`l���|$�H2	�Yԛq��^Fڷsd�VM�~	<4}����+Z��0�=H[�����n��j�ٷ���7�[n��sW��a!�mr��U�*y�8�)_���M?�MCc�������pp�
zޯ�{N�<�oۜ���19�O��]�o�`�����'���*ڙ��R�*|�F�<}�L��f��9j�5���Gi4i�͏�
re�賘Ы���Q[�{l��_(���E4f��$~����,�}�RM����H7,�|<7�3�g &q���6�5�V��}����b-���^=oR��!w��6��(ViY�^B�%�d5��D_d�iz�\�g]��r4��϶(kj��Dz���J�0+��������(�-q�<��1_��"�H���������So����/���kȒ&��G����R9Mq����k!��oX���X�o��s�(E���;���d�wBK���!����;��8�/&����sX6C(��kTA�����s٥�F�ԅ�	m8x���b���^@�ѕ�=���0�.@(Ÿ����>�sZX��@����7D�7֋U�H;,]Z����j�^�Y�R�=��������x�����JނO������Ѹ���\��$�V�P���Ve�>?r�(8���'Qs��U&�����tp�vf�	�=��e��x�"��׭$�e#��"%��P��o>�k�3:4�y�цG�m�ll��G%0`�lw��7͝�,YR��o�Fm��]>#�-��QK�ܠ9b�Hc���ɧ����DfŠTep��il-�>�!��)1�_/��e�˟�-�/I�K`hl�h�@cJ�zH��[�ݑ�܎_�D���Ô����_��{������X���<r��Wl��隌�&ujJژ&&K"������w�V��:�"xw��� �W&0gߊBAz%���x�[��i���BH����05.��--���
�yJ���4�w�+�(�iQ�n6�R��'lMa4hq�,$��o��1�Z�p�u�ݪ��`�}��Lo����7���p$Z�_�W�#��em���4��ޜ��'�y�
�>�K�B�XW���	 _����ˁ�W����/���q�E���bk�����Hj� �d;��.+��G�*�ҳ�d��($ʛ>�׺��'����3J7R����<��h�G+Y(��Fa���hG��Q��`���`�ih��JN�{db8�ɼ�-�ϣ�S����\���`�7U4V��t�k���U���NG�N��`��}|(1U����l���1X�,Mn��Y�V1�8Q�4aiι�� B�0Կ2+�����������Rmv14B� ����M�AtďO�@�Mu)v�\GW$��b�b8qw"���MQ���%�B,�b'�2��.���q��20gƅ��_�$(Un�H��%L4�u84�IZ�5��8��q��!��c��̋�?����t���pʩ�����r ����0+%������e�DȌ�yk�ۧݳ�%Gu��� ��TS���j2����q����M̎-闤������K�c<��y�9�2�R_�^�6CQ!77+���s�I%|R��KȻFJ2�i�m�,�|�䵲�1x�ĵ>x\F�3@%�F���<R6*���*�5�^�(�������d{�L��c��?t6��9��؝f0S��b���F�MV��`O�
��=�����>Ac1���ڦ7���
����~�����Tdvgߌ��S����E��MØd�)w��,��,����^� +���ń�����M����
g$�b�dH��93�#�9��`���
�z�ۉ�/���P����Q{e�w�H�s��`�<> '6\c}[r��=�V`�ͻ�$9k΅�=*cgmC5��̖��0�z���S��Cw��%d�( Ԧ�o���J��e=މ�p��đ�qj[w��wҮMX�0��<�G�H!G ;t�n�rԞ�c��������5	{ iN�\�#˓��f�;�ޏ�Ȇ�*z���	�`�����u�=VKp�:p���n��O�ۮ�x{��Xow���|R1v�����J��۱u{z~���uʖ���D�#O9s�������A�u�̔�,>C��S��W@�.�)�j���m|A9�@t�
26k��ʎm��og�{�����S�;�������3��k����	b�s�����_�lL�fu���3�C-q�+}���%3�Ԅ�{�M��#���,C�L��h���I�_o��X�4����v��g����S妸�$��p�	c�8k�P���x��t��g��o���hIy4�mb��-���D񶉕l�c��\���9sW$� �k�tC�&���A��1� ��`֗��
����y(�(�fyA�f��Md	�.b_QQyr{a@uҀf�]o�k?�dK�ԭ�~ÿ�XX͝�W�@p��k��#���L�����j�äl �7��5|-��g��]>o�ʽ��(�����,=�q=m�PCQ3�8��������O��A�M�7j���C�8<tz��z��YM���laK� �[����%�ᛚ4bF�������̥8��bC���>��Iz��F�Z�˾��v!Q7#i\{`�k�Kdf��*wB&'5�0/	 F(���n@h]O0N!SY(g�_��&����T^X�اQv
��5�g�#N��x�T�53�oǁr�(9�c��D�{����D[ґ������k��u���n%C�cz�����I�v����w��\��W/��>��E��߄B��̃�p�l�{~={����ɋ�m�p/��'^��9�1��Eߝ3��Gg]�穫��o����WEɪ9*��g�P�ES�a�Ή��'[���+�"�zY$�_F�� ��?�**��ჾŚ�m���	���]��3%<Д�Z��>����db��~�ь�+(�]�C��qY�����w�ǧ��,�[f퇍!��o��)NfRy5��
�&f��äByߎ�P]��\��3�Z�z���_L���LMaP�I�cj�0b�N�å��P�"���� ��y��r5�=����f�㯻bn�������6��'*�(��|/s܄6�wԺ{�'����;N*qwe��0��އp��!�P�?	�+��΢�V~�8�d�Q��.T�Tk�}Dg� ����t7}0��N˻E����C3d"d��4/49[�'�si���6��yu��H�
eWP�8�$D;��JpL��%5�0�+%� t������VBO\���*_ײ��^�8;�N~��a�3P���mzlƩ4�Jz�P`B�k���Bl�>����9�� �	z�%oP�^V����ju�����/d/�,K� }g��N��'κ8g�U��s.���<4�݆��گ|�,;��f��eo�dӃTg�
nuVմ2:�X�-t�:�o�ͬ�h0Β���`�㹪��Bm*+�73?h�%��=n�@i�&�fr�7,��oq���%���'���B�Q�,�wr��a&���o�q��=�!�)pK8�[�s��ͼ���0i�ϓ��I�UZ~%��$�H��7+E�z�d_�u]�u��m�t�#�m�]~�w�2 6�;�އ��p|(�-���I����4�cI� q�9�jc�,����^hc�4U�(p��:��h��I��v��?[?o�?4�P�������1n�bF���.)D�<����:	iשWת&<P(�����n�QyL[������mE\��	D� ��q��j�C�~w���Ȕ�Hc#��Ѵ|��u$�+A���R�X2\G�����L	.ȅ�'ZDg�]��g�C�I|9�C����م[.CB{}�]����mg�lI�UB������D*R&qc�� f�P��?p��U���f�k�.Cxa����w���֘UufYrǞ��>�f��w'�bR�Y�2�zxI�I�� f�ulK��ִ�
S]]�@�/ӌK^w�jR�z��R������䆪TS�1����B��H�N��ގ�'���R�b��!e���$��캬v��bsP�BZm�1(����a��6�G;�˞��;�19��W9+6�*5���!��+��2�ti uH�K�L��'��Ô�r,{�n�tu��a��e��
c��ؐy���k=މ;5 ��T�?mi�#r�l�f�����j<bh
�4���H3�-�z��<�(��J���8��x�#S8�Y�-p��U'��bi�4�B�L��E��{��av�܊!��d�|�� 0��L���{���A�a��z)Ծ(ĝ�
�F+�ӷɭ�N�!�q�M>m��fo���4�����떎8ye�p�(hUP˺�W��i__��k������;�$�� Gh,(@��)�1\J�F>�>A�� .t肘�m�F�0���{1����k��䏱����ǧ�}���y/�m�r{A\�Ň�:
�����ૣ�֞@�f�k��c�!Is�؎�����T;Y����hC�P�����v��>i~U�?Y�]o���@�\�&�ŭ�035F��?��s��Ǫ։β%�z5�,#��N�^�"�N���Q�Ӏ���P��iSLc!�*��{g�:�P
�BKȇ�.rY�>���9�@���h��m3�$G���c�_e?ߖ�%�4k�=����p��v��Z���M��\#i['ɩ$�A��s��1�s���N|X�i�r�u���Y/x������NB�v7罼�|��6�<��G�"�ܶ|Y׊��
�SCLԪ��9.߻�M̦8׃���~��,��#���</#�
�K�����t'ޟ�➸N��mN!���"�d&)�y��,�5F�����@��5�b%3�D�s0� ���\QT!��'b��ʺ�%t
�'i	X|�}L�~�[߸� ��08/-i�*��1���e^t��.�2g��z�(�������wL8rg����)XUm�/�\��=�s
4�~��Y�3���95�)�2k9�K�ʎ4E/�줘	�q��֣��RΒMw.a�9R2~�^C�V�I���������@��W�[F������\�b�&^ڧ�Zh��螭���P�'���|�]�Iu KX"c�&����F��#��	�@���T�p�ؽ�����f=ڮ��"1"�ɡ��3o�Ԓ�=�H�U]e�ހ礳P�����1����(:}�S����z�셖'*�cD�wHͼ<�I�5'N��Oh��s���f�p��u&4�|k�#5��o6XNv�,�5�'S�o�NE�����|��&�:�;n/�]�s�ۊb���,��k��P`�s9Ν����2jw�w'a�jں�O��ʗ�Qx�Hh`61���y����m���Բ�f{�=3�+/��[ ( ����k��"�o��d�qzDW�AE�EL	D&��.xQ|y�~�
5#�o<9�^%��z�=��-�z`u���"];�+��0�����rWK���_��Uԉ,Zg�Li�2��]\dC��
�-�q&>�OXW�#ܯ���F?Q��F+t壺�jg~N1�˟�VB3���l�h�7-�	���I�h��6��6�U�v��se#�G1I(�Bq�*6�؟�twC��z��T���aP�u�_�p����ѣ�F��A<���=@Y�ok��$�-܏2߻�m��}�-��]qqX�fzj�V)�ڰAK��W������4ޡ���7?l+2^���xL��c-�A9wS��q���H�PI�� ��8%R�����@LiXP+SbW�ݠ���C�Ĺ���r0Z�tN9/Z�3;�E�Fs������C�=�:5����uj�ެ��{�5���>���g��Y�S��.(�� �pO�}��1�OLb��;�3�^�jJ�C'(���>��.Տ�?�
5O�ű�O��G��m�4Tʤ�����MaQ�ƭ���1�I��~?�'}H��`�;i1AX��sI���O>��&�8���:B��2���x��!,bf̰+*�d�������Ρ8J�E2��r>����M;aY�޵R����?x���:��She�]/;�X\E�,��Bc����Z�*g!��c"�J�D����������]sŗ�yH��7�H
�`������,��J�)S(�e΄�:��5��e�2��pX�O�"�/�Yt�>h��]��j��������\���ᤃ�O���8���)��HC���KlI{<))�I����9�$E��q��w�ΆI%"+݁ٴ�Wۆ�CL(8�ͨm8Je:O���xU�	ʺXZ�pKưu��l��o)���#c�+��i��e�M:ݬ1�`��>I���O~
ƻ�g�/n5D�7�ʏ�{��ٮ���T�#b(���RnZ��Sj�GY�
�[N��T/���c�oaM(�V}�̴)"������]��#
�C�#��iǐ�Z`�qN��җ%�Fmdk�ZH,ky�Z_��|��\��%3�|Jڦ��8M�����8>���L�7�x	��{�K���d�o�O�y�a�S㈈R;bH�)W�&�9�稖����{���[�����6��*]�z	�Yl�p�JɫoGy�]�Vw2����z�p�n)��Ϸ�A@�X`�^T�=b��!��-}�B�,��&s���?�z����[�o ĩ��0:��*v9˰� �h1yX�X�����
}��`��T	��Ɠ�l��U�nGЄ��
�p��h�-��C|-Q�F�~@]��n	\F��vպ�e�G�P-��)6U���	Ze�%�o32��*��v`Q��N�Ч�lT8M�Oy��Tۏj�x�.P5ɀ�����o)�|q���E��t�q�Mi�����f�@���Z�L?���<�!�/���$9J��#ɐ9>E���gC&Mr��fkd��nY��C��|�F\p����cR�/�(�\��z�o6���uJ��^�M=��y��
�n�H�d�m��g3威e��BV�\ �p�����t�b�|�4$���`W`̧ܖ���gKLӄ�l�����\!]�~R�M�y�z�_���#������� pq�����q�`��aGɊ��|��k�h)�+���?up�TJ~�����9���e��f� 7�
�����'>B�]�n ��҆rXT	o��O9~�v�֕��l��1M��FY*�G��%�~�|+5��9�Șw�+��^)����1݈D���M�� .a��R��͊�0|�� C��q,� |p���f� �=a��S̊t)F�ƞqQKFv@{8?����0UX����������C�ʎm{���0�a+�S[	q�w��S��o/��/�qE]
��^��ﬅ�vs�0J����K?����=�bS��Vj���ˋܔ��L��1��Kr:��G���|��?|�+v]�^'5�k����&��zp~�9���Ȅn����Vxʚ���C����]� ֋�wLȬ�ٌF6ښK?��.s���{QK�Y���H�;���u�;i�A��ޗ��k���C�)&�Y@�G��Cʉ��F��"�N�)��ڛ"������*k�/�|&��v`��}2��;���q6�k�R�M5��|"�#�g�lŝ�UGwJ�fNl0R�r�+��A�0��/��cl|��4�0�!���S"H�UL����gRV�r9��]G�O�t3RK,c-	��#�k%��:�-{e�ECYv���ȥ��^,��O�2N�Qt�FP�b^�7��ֻ,�zie�����_G��	��Z�4f�m&�᣺;jM��������5,���ς��_��8ewE� -m��$V�ozw�!���&����a����N�;�*��(@m�^&�#{0s�8z��f��5j��ט���E`P�JEb-D����a�����Ow�֥�W:z��^�t���}�Q�Ԇq�.2�k�+��`���hQF�C��߯��`&V�Q�b	@���F��	�\\L�����I�T×q�a�������+fO��M��L���7(Rh�h�e���?�������o�|��!ڳ��D-�i���_�J�[���n�'ٳ?J�B�I|[����AP<6{�[X�$g�t;}�d�M�djK�\�����K�3��f-I�)R�Dy�b�\iɮ��ݫ [m���V��%��k;y��6�j<�-�v���z��WKsy?�����?�3������d�E�	v�ǅ������}SK��n��E�e�M���X�E�"��y�]>��(D#�W7X��XL����P��JD����Er<<`w���!�����_s�0��6����0�=i�����AV�#e�F�큎�~Be��x\3˙Gh��0�b�T1E��!;����h�y�g����`�)oa�����{��&>����⯪��%jI�u8����YY�s�k��=�/�~iХ3G��4��ϑM�"eU�3���Nl����r�n�֩/S/.�E�em��t^�A֎���A~���ta΅���4��7��kPL=2��20��/� $�絑J������d�ُ���ݢU��t�6Bs��#l����G������xd:%у5�)Vş�N8j-� cp���h�0c$�j�Y����9�l��d�{���;�"	��WI�+�C/0J)����yPۍ&h����}�����6L�^8^
��l5�f#I�.��St�6�Zp�W��*
����'5��Ҷ��k:�Z!T�}���^�0���D�ޏ��&M���ȸ�zSV�x+�ܑ.�M�Pϼ+���?7���ռ�1��ɧ]|2�V��>�a��g�"E��Ln�MB_����b���(�j.Z���k��2�	Or��'�4��+"a]���'	$��~�K�i-�9�?�Q<��Ҭ
��"Uy���&���@��	�v`d4��>�p����τ=Q\�108�,��5Z�{�N��s�!�i����UA�1z����>���}'wn�@��j�/4�]�D|��SA��[Åx����V�nv��6�m�͘����JuTk�H�̔��#[Uf��͏�t�aG%�H㑂���Hwl��{��ϒ�O��Z�����6�C�7�Fen�u�>�^���'���Л�)����'�ͼ�\l5t=���)*��n!��������F&��( �-���@���]�n����~���Gr�'0���(g @��G�q`S�)�̭�g��8��/_t�}u����X��]<��b�0���!N!�jPؒ\�@��Xz���8?w��[G}H�!�N��~�Z/�ћp�� ��=[(T�r�La�I�tI������X�o��Q�kJ�cISa�V5��r����L��ͶF%�p�u��'��ܰ.�0�+Q�7B��� ��&�}�.rƙ�ㄓ���	�ɲG��{�T��V�1O����<�Z�Iiq�����dz�s�n@�t��A)8/��,��r���-�' ���:�b>�<�yQO�m�L��XN��ge�r�����(A<k[	�e��	M�eT��e�:[��Å��������<Wj�[�X5_�炋�>�t3��H�ێ�J��ĳ��`�N�S�
 ��u�ڨ2��I� �����4�9�r���B��@T��M!�8�v�=9c��f���Fk�)62�9rP_��{*����zč�ꮠ�Ā������.!x7ww���O�2Os��4���`���)�}�c���Ϩ�y��E����{�����[7�},dzO�22�e=�����a �?gx;�W�p��T�0�� �u5 /Ca'w�=�Ik�1}����+)|�)�~�SN��T
��h��7s��\�>�0��g供�a&��re��x�38%k];(�.n�`�uR8#"�k5��$��Y�gҭ�'R:r�y/x{p��Ft�1fR�Qo ��L�{�}�����!� ���$w�j3%�qf�(_a��yb!K[T��Z�6d3�����;�b�]�3}Z��D�K��j�M^�bA�
������r�o����M1�(�A�h�G�˗�6\jc߉����Y��s�
R8�� +�s\�s^IU(�]Kn�՛�}ٗ�����Ҹ�����D�i�ڎuܾ{�� �?��y,.Xm�����r��cu�UV
,�Ci/'�+�!b�v�Rs&�R8��Wp�������Ĉ�Ġd�h��#���(��3�S�`Eې']���fl�@�jq"���(\�"B'�E=e��ŵ������P�Op��+ߊ���Zo�
%�{��tp�A��̤3$5�~|H$P�U��^���O�!�(M5�-H�M�B�u:_��S�N�I2��GR����\�²��3�@q7��nS�`+�Y�6�����)w�:C(j���s��|����-��X~��M�
&��S��yu+�w0*Z����#�A�P�DЄuzATo4���L��UG�4[M'��9|b`r�� Ϛ;h�}B����]��'�G>2����:�[����|�r�	E��1F�딋����=�Ύx�����](	�R�+��lB$	�H_���)�_�()1U�|ZGW�B^���::B ��@o�x��t�pH5��j̩!ʇz�Y(�Td�  �C��?+n5��0�.Ѩ���b �Y�#XS6�-9М��Vʚ��,_;�jPNR
�$7l���d�����FAmx�x�+�Ŏ2�w����qQ!���
����g��$�/[`�Ԉ�z$D��N�|�5#\8e[q�W,��l�̾���*�>'���}B�)\S�;. L(C�S6���
~ɠlK-� �g�{�.���2f�È0��G��u��Z�<�L��T��C��<o��8XT��UK�M�������w��u�D?i'��� �os���=���3���)�L_�ħ�y�t6ptv������:��S,�y>b����"�l��Q������y|3�y�V��礕��Z'����E,?�]ă��CD�Պ�k>��E���l'�1T퓠�px���7�.�o�c��R��W���D�0^�+�'�\`�N��	�U�b]��:}�ZhP����w�-�9��6��-"�."� `X�&��a@;�«a��t҄��Z�T&������k:$P&���?�������o�!e[9�ʴD���7c�u��"����\8�5���gꉿUeʿ�$J���Q�*�l��u)ܣ|�^.�y�fƓ�L��b2o	���������e��/����Q�
�~qx�nY��J����)�L� y�!����o��4}�9:����0�w�='C�e^�jjB�}�K����#�PgL��ɴX{��s�A���h��$�J|z��7kK�����7V n��71�з,�2�a�b�lQW��k�!�Α�m���9�P��3�6���ǌ��7 ���z��{�t g�"u�]=xq��&0ܽrV`˼�4-�x�6�`��-�+!5SOe᤿?H�M���*�mq����W�rzC@6-�^��};4Nuk��#�K}-a֓�SwʩG���/��)�Ʌ����S� �9qW0�H���
G��h��Մ�c��:��[��nD�	�nZe:\��i14&����p�g���T����ɔ}�@<��_m�Gq*��O2�6 �<߯V�0����K�KVQ�کT�ٕ� z�½c�(w��� G�@�jH�S	v,R5���v�#N��"��u+��O>����E�h�OȾL�h.���R��\�m�ԭ�q�؊���3����$�O��g���c� ���i�o�74��~�vV�Bɨ�3�aX�����0c�==z�Z2�J����0�x�������II�
2.����%�Q��OA��̢O*��x�7�ɪ'�L�ͦ�@K������(M�9���t��bEhe�(ho��C�#��}��	���c���_��k�,w��|��n�46Ǯ;�z�z�R����ǁRH'\��r�|�!��P�TU�M��������:�z�����X��N�9{F���zQ����u]B��c>��"V�Jn*�mx��M��xK��������C�Ք�'�>Y#�����nA?�A��1�+nZYH\o����-T̗.� ��H���e��z�����'��Brrq ��7?:�V�v,5O$���IO+�{��C���YGBS�D��̐��IژyTU1$�����e�%���H:-�� ��T��5��h�<L����b�~i�!&����TF�ut�
6�=Y��S��4��m�����!�k�!0)R�6���H����s�	�y����p#����y��������7Y���؆��ƈ�Q��u�0uB _�{.R��b�NFӝ�T��o�z�,,x:#}�d0u��4hN��-B�9Y2�����'z�E�Rը�w��y����c��:tUGoGh�kQWL�q\N�� S��pQ�<E�A�����:!l\�J��SH��?�&�WbB���x\?Q�yZZ��'�5�ōHR�=�ܺp�S��~���p�����pl��s���jوhh]��I�g�l��X!�`D58i�G�u���z�<�x�j�e]^!l=ŀ�1�I �����xg�x
��3q:��Ɛ�%*=r*�IA@��!�k �.V��6n蚒l����1��|��L�$��1�OQ��j>'J7�Υ��B���U��'�g?��ܠdX,¼=/��Q��Z� ��%�ց�-SҋG{� �A��$�L~��R�~. ���g*���i�Q�Ko4N'�T� ����o���t�V�R���Fpēa�0X�Jn�8h���'ݧC.hI�鏛��YC�5d�{s)Q=���*����J��l�s4͞�s�t͞~YE��o׽m������������sc���4B˰cf�<�a�ʲ�շ8$�z7����V:�}w�Z/{�S;E�����V�bD�#Va���\�+ס����9���cqs��O�M�m_Y�l�x��es�q&s�)s�'�o�ǵ2_H���[:`$O'!�˰iz�矴c/�4A��hp2���6���.�W\c�	�d�����R^���A�1�`�D�b�s����V,�8��
�栈I�o����9Q1�.`�]��c�h-p���Z��n��������u�.;#�i��%,��e��<����
Dg�������9�P��,��ܪp]�g��L��R[��H�~��lsjci	�L�^"�p/]��N��v�@��=k\r����2y���A9q�qޛ��A���E�#<�2�9�=��i|¡Fqkń�倈IR*���Ժ8_���aV���sn��)������H�k�x���(�W�6�8�z�C]���3�J��%E�(l�g1�e�Lr���2�5$&9<ܟ���?�ѐ,�4���lb��,n(l85�/ :9M����o-p��K�,��f�o���V�sB*���?fDd�k��eqX��â�����9ԛSh��'5/�B��AVS@���d��c��h��Z�ȓ`
ǐ�Q�=��Z![�&H �$�����S��yuM�"� P'X�-������y�J|�/��ͬsߛ���L�WT%M�w�+�`��F��̔e��5tps}DJ]2MN�n���@t(bW��
�W�-=�*m�1V���h�$#��d׫�WX|^��H�9�IWq
R�]j�À���m�2�~eNU)�iEO��`���I��V��/Mqb�R��y�G�dL8�lg&2�/�/�[��Y�d�nz�>��^cW�դpA�F�2���ٱ�re83�H)�͆�=�P�Ep��ň���Uh�;���N��ml�;ė�X_��Y��j��(D�8��۷��(Z4`�w�l���ZZ�qE���H�2�?��͉�fA'~�A�=b	�G�.`J�-���=��"en�ޚ�jx��h�m;�U9���q�lDyKJPY���s v�+U�k9������.ȅ@�Vv葵��_� b�n�pl��,_�>�ꩀ�粢�uc�H���.=��X�-��T0ܘ�!�>�i6Ʀ���*����q�4�C9AE�@uwJ��MQ:+)W���ͤ>��� �7$҈��|�w�Bn~yg�0(GW�0fn)A:��a�erF;Y)�U �e�]m��q�v*�3Ǜ�H��Qf�n�4酤�r��"ǌfAY�E7FTe�dFx���� mV,�L����%I�,*�a�v��7�x����J%�N����(O�B�ޜ���P̫�f)m,��^=<�21�Q4� �3tqQ8�S9Մ����N���1�bp����uD'���*?�2���D�����@�p�q�mme�����"n�j<���[�[�8Xlt邽/���)^0-�[�(7�}:�d�Zk`p/�Q/�B�e߸f��E���J��SS$�=b<�|�p������U�㕪�Ӟg��*K$�����m�ߧEp���`���f(ę&1��Mc�+N*�����a��29M�M��Rj�}5��l#審���56Z�k��8rbYR�9�*����`s����\���[�W��X��F�i��L�7 ��E(Hq�Q���x�s?\jꣻL|$���h�GG]����ؼGI|d�L��pЁ�����	0�r�>@[�d⏾j�����R��:�CL~�8s��T�����}�R�ߎuZT����A=���L-vWF��5�����~����2�����s��5@����'�����(��I����}6P��d+3��*�]jV���z<����Ɨ�-��0�ˇ���ӽ4�)H(��n��$��曠xQjھ�)��[����֤�
��4��X۷����~�����D|��\<h�A� ��[?h#�P�Eܩ�ͤ�����;��P��п�y�i�|F0��xX�#��38�.҅R�&��0$c��ԯ��&��A���Z�bf;��Pa 'r�/rDF�}d_'Âz�S}�k\�G�3`ܸV^z<�l�����$���xlo_��z<o��,�-Ǫ��$CƵ���z
�zgy�m�����Ӆ�����$�}��=���+9�%��&B�^�\7������Y���z5|�tx��"{:2�hbKݮ;�H-F0y��f�IQ��a6���X�6�;�O�o��	P
�7ADe����",�QKg��A���T�O{���':��M��!ʛg�io��4���PZ7��.+�Fq��c^���wC;|�P�E�6��>�Sޘ;G#[��r�G�)E�5ʖ��jl�<~�-V����U��שdԉ#M ���مF�ۓ���r����Dw����6�B�W�0��mh`���[m^|��!ݿC��u;��<(��8Z��q�   �b`~R�) �����Ӣ���g�    YZ