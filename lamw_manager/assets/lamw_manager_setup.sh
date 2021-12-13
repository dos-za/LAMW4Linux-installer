#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1998190382"
MD5="9ae7865bb916268f1b8b962f7cb821f4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25536"
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
	echo Date of packaging: Mon Dec 13 19:32:28 -03 2021
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
�7zXZ  �ִF !   �X���c�] �}��1Dd]����P�t�D�"ۏ��Q/���%���p\ϼ��$"s����2��z�%:��}�C�@������I��1�4������'P|����\�A�S7>�̮fs�.�C����?���V`��M�PL+'��z�|A6w�@Qغń��ƥ#y�s0EF��O��v���>
K#�hw�Aλ���{'D�hV?�&��z��֛#& 2�h9��I��'(�����d}.�;�㩼�`8���X[8�����E��b���K��������6C٩_!y�=�<�{{��J��@� F[�h�շ���R�����Om��Y�\��X=�;N��1P��'j��8�R!��[3�e.�m4Im���t�]�jp��+��zU�%��'�2Zh�[o��p�T=�M�fX8��<�5�p���.�7S�.�<����b�E\[7w�P��~�H`�%�9�,#�	,��*��	m��c���hi�;֊N<H̕}�>��*����=`த�I<��g6��b���h�4��Ș�����Y�2�\U��4{E}�9]΂��|�Xp����a��ۅ��|�-�;�ܫ/`�C�z��.��(���R/o}�o�_���:�AF3:��0/x`��7wr8�����1ެ�:J��0v�(�t���QcE����!ב��b��T�jA���Jw��'t���5����\��J��^�7�(�ѐ�u��P"�a]��]+(�20������6^�nV�m�A��rtvr���������=[���q��̷����w*/,�/���|�+-Ec>� ��q����=ĥ+!{��,�)Ȳ�R�"V7�U���X#q�ch�FS��LN����ï�Y��ڇg�^y��"'0�..�׉��̜�'�0�[Sߑ4���&����i$��kJ_�g�~Ar�sK//�&���w�v�llO,Q��D�4T�2�нEj٫h(,�()^��?"Yz����&Á�p:��EV`e��1&n�|�����!
SЍ�q�u]�ˡ͆(��gLK6
����K�i��R�h���FR�.׺��1�1���*$�н�G�'���Һ�X"����H����*�������a-�Q��6OՃ��D��xC������4�� ��)�?��e�8M�֕.{�D`=H���h��\�J'<�e���O�)e���P�c�ֺ-SJɆ���	�b4L�BO���x�p"bh�Q��� '�1�����1�vܢ��!����ƹќ�㐘�J�
B���9��Ө��6e����9�-�,	������ �����\��	�@�j4��0?�;AE��LI����?4�s��X�E;���f|�?����r��t)hI��r҂f���A6�QNV�%���r��L.�xn�Fc#rC�8)_	�@��Vm��ex�l*nң� ��v���B�w7\��$u8�c��k��P�F�bE2u��_��5�3���0��/�,.�.)���Y�{�����8��<Q�Gҩ��CqSL�R�Vɱ �*ȴKW����t�y]hUm�XT u�l��S�+2�.OV�B�,��ͩ���[�	n/3ʡ�92�ZO���L7���Ľ>�X�Ur&L�mJRuL�E�	 ���9�������:9ڸ���!$�pi�i��8aHRM!�-<�y,��s��Q�e�'�w@h���Ӎ�;��,����)m�L P�+�� ��aM�孻5r��=E�XgR�o3����t8X�y��kZx�f#7��u�RD����6�v���)�{3j���E	Ү�A�<�	�1l=h�3���4���;�\o�-��{�ǩ�5��4�.d�b���9^�E�4A޳m�]X��
4pə�ME�W1:+]3��g�
Y�h�족Ʌ��r�WB�G�㭩��^�}_t��-�/zd�ŭƦ�М$?B�C`՘A�*�@��U:>[M��P�w�Q#>إ�͍��>��,y��C�ь3�A4��8W�C���v;p݊�b�Θܠxu�_��b�I4
����@��uʡ�xre�� N���V�O�癯���B� � #��R�G�؇��-���Q={%bI�dW:QqN�
�2����hZ)�<��G�1��_�jl�t���%VuF4�u� x��ɣO��@�]4g{p2Ђ=�ކ��
�l��b���`�_��`O����؎v���V��y�e��'���]Q0��!8t�Ƶ����S�PՃ�;�x8T���w`���kⴍ_(U�j����C��,z@�!�l�3sk�'4-n�}U՜3�i�i�&��� +�peH1�M��=���&��]�x�0��}�@��l���?�WH�R���S�bߞ}��4�s�19��s +G�[00{h" >U�m�W�EK�� ؂´���d���v��s/6�i�l�Ke2>:�ŋ����#��@j���X��^��J��u���p�Z7G�:-�������r�Qs}�z]?�)�dCZ�YЁH��Z���)�LN0�y@kl�>6�k�ie(+H�,-���;��웋L�{իU5nD�����IR�*}��v��������{�r�M�e�N��F���E
T� ϑ�c�7Ã�$q��ip��f����^��y!r%�k���s�S2� 
�!��|UY~G7r+�}{ʏ��A��\�
��n r�8�K��q�<t�h@��cs~mB�������ʠ�z���.��ܵ~�v���H�4q��4��k5�2x��ԅ�m�v��W�Q,�ef���ĨkU�a�Ap�p����,���j��I~2̗�c��
Wme&,��M[�+'����h�]�#�������:��>9|�zZ�)ϼnPᕚ�#Y�����:��q��"�X��]X��d�,3�d�P;�us.(ᥲӸ����U����:�����ƈ��؞�T�Z�@/��WH�/�ih���D���!��N
_��&�&��U]���D7���U�C	 Y? �m�2��:��ui��S���%��M���";p�ퟣ��_3����k`�\=g���9�U��T�9>6¡4R+���<�O���kn(����h�~��Ò.
�b��]WHs)F�C�QO�x'+O�<���!6x}�W�5p^���
"�daRL�O����C[�}C^	Pq�8�����u4�;�����W��Xj��
���c�%�C�<&둷��0�`^�}��#"���C�G�����p����<d�Ʒ[/�L����!'�����R��cNY�3����T	9��锲k�hp���O�t~e`��S5C3�B2������縭p��׻������a\U;�j��V�K>�8<�~�wp�V��3&L��^�ݵ5���:ߨ��n�m��xܓ��磫h��j���V��L���o"%<�k�f�](O�ÂB�:�^+�5�����c,�g:�5��yGd�"�}�e��� u_����r��8BA"�a��� Piu��A�]�����軲�S�3�%�f~gŶK�/��Mй�@ˎc>�����[��g�ߩ�c��{]�N_�A�+�]ɰ�΀���ٯ�wڏpx�$؇��	�HE�����M0��{������"��;�,�8�����1���2��L�N��Y�)n� 7u,%e@I?륧���Ch��cжşmRas��(!�rď��$��b%Ž���$���i_L\{PD��ك�pD6Ef�]s.�$��{�j{η�|�������Qt���h�������i�ؤ�|g�)�4��!|�(����?��ڹ�`���P�,Ϋ�+��f������6�t*F�x����E��e�+TWs貘j��ME,������OWC
�5��y��J��s�Z��x��.�*ͪAYcI��>�k����ϝ]�J�4	�)��E�Bq<A�y�tG<�"^Xт�T�g�Z �Y�Mѐ:�8�5��S�9�Ɔ��lI�inksa�����c�EB� ��-�R��`��O��2hS �{lǇ�+����Lh�$��^��1��/kk?4H��`��~�	Ȥn�9N�Y�b�����9 Ю��w!D��c0�ǋV�z��9Υx��·v�V�{���6�Wp ,����en����xu���so����.�{�v�{��'e#k�=l�%���")�⃠M�2$�\�0l<�,+}haz
�D٦���=���$FwP���u^H6��I�T��ʤ<��x�%�zI#��
[-��]u��B��^�1!�n��� �����Gj����$s�n�8p2��,o�y@�x
v���F�[����1D���|ڥE�N�]k��r����-}��O���#&e�w��Cz)I�>�z��&�A��,��j(�^%j�Ϗ$Fڝ�(M��j�U?��IM���,���=��~$��]�J*�m��&�nAC
�q(��N�f.y�/�6�[�t���UW�Npߙ�P94�gjz�8#a�d`z؏f�	�M��A6�y��J,&��l�%D�exM��,9Ā �>���&1HB����i��Bk.&XJkZ.�TQ_�;��KMI�1�ʹ�G7�A�W��2�_�>��ڔ$�8���F�Q����۽9�՟�Mx��ɹ��r�4?{�ؙr�@��)�I_��T]���kV��Tb��� ���K��R����7�ުk�1i���%�����a��߻�x"��@z���5��*��suNWV�`&�yY-��h��Pq�����}o���,r~�ـ��ǎAQ�uJmٟ�_Y�8���$�����C�>U��~�$�}G��B���/��򤂅D�g�ۧ��X:(���W'�+���."���K���yJ�>[��6�Hh�Iz�k@��)Q�ڷ0)�4�܄�Ux�yu��?��T���֩��C���_c��K��<�#,UZ�ʕ!�C	b�ج���Sf�;[�z�p���8�F��)�B��r�PQF&���Z�lw��B�wR4\͎��i���QK*�y�/���f�S�a�U����f����)�\4Z���S�I5՞�R=��#���0�r�m��@���I�Mb��X�$C�Z�e�4�a�BB�I����k�ep����W��}�����E�j*>��(����q/�H�=�Ȇ3V�%$I�HH6� 
R�8g�	�T'S��j�05�P�U*<.�� ��~��Am�?���f~�)��Jm_��o��M�M,��IhӠO���6j$L�&������/�ҋȸI\�hɄ�t��&#z��Cϡ��l���x��9�w/���D1��м�`5��ժf*��YaB�!��H�m��j������Ø����DJR�tg!t0(��lc�?�dƞi�����01��FkU#��}/U��-MI�D��bI7��C��ӗ�yΎ�k�UW��@u��c���Y�nKsE�������1���:)�=����~��x�[^��<�8��7�C0��v�{^�� *�Dn�#�#!�22dU×�s�T�v�^s�ybIv�Dh]�D��ڒ�XmlZח�	Τ~ϴ�j,�rB�Up���b�kByH��L���n�w�2�o�e��C��#�9d��0��g��<�D/1�v�8PMu�?WI)�P�Z����O����-FD�yK�t��|,�S=_�Ax�:��!Ք��wpk7u�%���~0�/A�����F��w?�z%�@%�aA~��:ҁm�9%8�O�RM����7���""���֬O i�5��?y:�cC�9��s�#��n���Q�l�sP;�2N�i���T!\�U�F�MP~�ʍS/��W�r�coʌϪ��]}xJ>��kd�J1(t��,�I��I<S��b���$)��@����F��!���n^�� �m	5
�����bt�*�Fq�H�	�A��[5��>������px@"�ف������#�8���t�n��T��nt񇁏R�Hn��K�믬�*��U���E��8~��`s�.G�T߹k��2����a��aԯ�?L���9�"L�Ҁ��2AP���2���Gm�ٚ��x�O5�_��g&N,�!����/q	x��]X����|�k|T,��� �4��EO�h} mۭwXo�)v�lU�ݨm�7�` X@�D�qP����F�]��F�>Ь����47���r��ݛ�g_�1|�������v���c�W��?���Y�Ca��<�84n�H���.��RN;�&O�yoc�ೞ�9m̒䗈���(�)�a*=k}D�Vځ���lf�����9���)^�j�N��0���E��q5��pgD�fd��/�*�$"H�V�0�~�]׼Y�V�,wm�`�U&������zo.���Eu����8���߯�q0ǳ�!��Z� ��e8��{�22L��,�I��R�C�L���|-섐Q!������!ײF\G:FQ}�z�xn����^�@V�zh�c��p����Oj��Wa&U�����V��"֏9!0q(A���V	�;Չ���t팋gH�!��@�ǎ�'�ܾ������&����l�z��U�kv�7���wl�a	�Ù�\�u[Y��br&���� ��3�	T���e��w�|X��G��i݇꣦��Ս{��9�, ^r��莢���#�CB��<���(��V3R`q��A�t{u�"����f�nt���?�|���t�'H�rZ[VpVG�857��G��Q�*0rK�@�����!�!G�y%��oa��l+���ڙ"?�y	�ڋ�gQ��������'C��'�V�A��<>�s*�/�4���n���c��Sd�І�EF�kB��(mga�>D�%	��/2�1�7��~��L�FIʓx������Mz�9���F#�&�������T	׋${�jiO��:�e�����$��$e�C^zW�":x2c�0Is�tN�G@��W��_f���3�Z�K�vS�GQ����*}Fw��(��rh��Hʖ��0�*@�����b��&�S���f����@clp��k*l�)z]'B�ㄇ̳�qtk{�g�����q_3�L��.�~�'I�1|4�i_P��b�����s0��O�kCo���aR�`;ri)�6 #E���R���m������`���iI���s3��.Gɞϖ�ڝ=(<+������k��g*�����8���W%r�_� G\��|�ti4�.��e�����N����hht�� �Y�2���,� (@�֨*�����/�/1 9t�*3�4��t���dj�
�V���e�5�^T2�"�Jr@~�X�=mT�
�ɸ��,�vx�JY� R������#b�D�N�Q�f��z������5`,�6/!�����E���['�C�%��!������S:�+�w�f�Y�v�9p�m{mlY�H�D�KJ�!���.��1�ťQ���$�x�S�a�9��;�/�:��V.�6	����-f����T�5��]�
��J����R���f��l����C�,ߕ��(�<�]�c85ٗ2Tp��l���������:�^�������ME�q�x�J��A����ć��<�0��ˎ�a	���z���ڹiAW=�l���6_Z��ߺݺtRt�7���g|uI #
�J�*{͓A?�gzn)��B~2Y�ВR�_�Ç�IIG�9yd�«/t��p~���� H��P�mX�t���%�%�U~�Ǩ!���dX�ӟ������Ϟ�X�jI��ِ֦"�n�Sm��B�`&�:��F}�ݣ��]��Scɜf3���-8����L:C+4iDd���|�����^�����&T6#v����H��.F���_B0a�pcT��k�8s���Q�n錤o:���['�����YasLA2����HZ��nV�2��IZ�ga���v�����htk�)�C�����՜ *�g�R�BP1���`�'�I���)̜D�,b����!�u��9��}@�K�l0*(w2�8mhbN`�M���2��䩼�F IiǨA���dщr����)RW������	0w��]�����w=#� <#2`�|^�#6l�y��\*��㯜�hA/�^C�Q��{!�$o�=r�G��O@O]S)4�0�Ht|�ʯ���7�0�&��N�����).�>���IVYq��V@�&�����`�j�q�>�o�	�#�Ċce�����k ���3�#R?��a�Cy�j�/��<�u�&bR��қf�΀?p)<��̂vO|�E-/@(E5z�
L��g�9��zC���-���T���=&j�7È¨���	����aj�lֲj
��l���UM�f-~��[/D�H3S��۵�(���9�劤<����ߵ��;��zd
E���r.(0��CN�_����J��"	�o��~�8}զl$���2a���������h�p0��r����gN^��e���� ��L��
D�����H�����q���;�ڏ�[���.Xz�r�Z0nY�i��T�B�9����1v	���iYڀ������A��yƚ����
���m=�JĆ���X�>�y�4y* ?؟�Z�����*��m�6�LI69��X���B?�5�c2{d����B���G�K��ؗEg��E2��n���8�K�����>*��I�_I
͞rX=˼MIE� ��߆�Жa'"	���¸���s%�l�]���=��L��kBN���6)��DV�نՉ�4<�� �9$�6S3+�؍�)`38�b��to�.����h'�[��Ojݮ��D����hQP dH��CCJ:=G��h?"�15A�8��J���r�fy^�Lok����b�M�^/ǥ�I���0ߺ�*}*j���Z��,l�U�r��	���l�5�KQ�N����"��S���r�d\��ı�c0@�,��޼h%rO㧺�� ��t�H�M�6���x0����H�K.B��sa��>�������y?�( @5N(�N�M$���J�=�^�v�]�Hs5�{m���(ݳ~��`��ذ&��GD�|��/��y��F�i�"�:�د�������eF���u��E_�M8~�x82۶SN0rlԵ�Zm�����F�d~�X��p��e����2��������8��}z����(1����M@|J�'V�x:��9� ���
�J��G=K
����%T�u,,i�k���%&X�;�a����l��}
���l5"�	��?��o:�e����m(�)Aj&8�e[K\���u�Ƈ+�)1L�'�]< �j��N��T���F>��H�^�b�9��i�9{�� 'pf��~jɹ�Q�֍0��V�
i;=�Q����q����T%��CN���� qV�~����95��.>��C��]N�����+A���n��T>��_
���r���!j{��6�H-O$�͏�o%kA��,0�ݦ��ĻvP� j����=xz���`�q��Y��ۀ4�����RGh=��C���g�.'�[}��bA���:ڐD�d�lT4[3�u���d.�)���'��$2=U6�<��0���[_��mLH�����>-aE���ă�rK�o�%B]�����!�'��Ve�.�e�p�r�+C�O˽H�"���������	��\Y����?�N�;ʬ�Jt_"u��B?�?ti4k���9�4od��Oz�6 ���,vp]VǛ�z�q���8j�$�>x���Z�����}���� v7ZӃʜ��%�2��O�m�-r&�fq���i�K�H�/���"���|( 6���~ ձ`y�����[�"3^�eƱ�FC
i�}�͡b�kn�P\��L}��7~�&�䎕�j{\n|�l(D�t���������5ѿ,G6M(�z��&|�i�\�/�Pژ��c�q��<X�[|=��:	��[�t�M-��V�q�kN��R�o&�Z��<S�}3��7�����a��}��k-��1S+<I+{�f��?�_U:���,������a��V���mg ����4<k�)tp=�-��0����P�G�"�,�it<{.��xt���8�!N�{|��������[Q�^%}押�"��VI���Af��0������O;��{���$��*��Y&��e�n�E�sU��\tTd�$+l�8�~��^�9��כ;<bv��ތ�l�wV�9���cʟP�ÜN �[����$0���H�%��)�UV��H�	�&N�xL; D#ъ���� {���Ro?6~_f�"Uz^�i����ŗy�b����-�˜*<�HL���C_ޘ�`�0�@9N8M���e��>/;��K9p�艈ZV�8��j՝p.H�2�)OH������3\ȫ�|� �C�	a/Uz�i�9a�mT���T,��M��z9w��:W��aI��N>�gp��ܣH���cf0��,X���* ��ƥγ���?���P
�
��GP
��/�y��aW��*��N7�`���i@�s��Ri�`��g%����f�~�T��@�_Ac�R;�NV�	�V���"��g�ɕ��kی�?��m��o��u�7D���������% ���䍏ʆ��D���m�����A?�LwT(��m=���픍y��]�� �H���Ä8��H;%�-t��ޢ�����I��G���n���̲۬�qU�P��ӓx9K�.�"�ް�?6F���	�^��O䷂�����y5ֈ��љ�k��i��D�g)�]D�sg����ꭒ�(r=<���s�u�#��\([%���\�`z/�|�(!���]�	��qn�^�����S;fB� ��9B�Û0g;e2��h���cR�C6�
gG�nb�47Ҁ�ɬ��|Qm�1�'�\bA�ē���.�P@���>��\b|���RΜ�i�%���J��:%��������bg._9Vp����a��ݣZ�qJ���wl����8u$K����ov��sv�������>�P�XB��U�#$j�E����j,0�
�
�7���z!LZ �X7`R1X<@��Yv9<I/���{R���5���.�\I@�S������r�D�|PC��!Ӎ� 97a�0��e�w��]�k�������]sal^H���i�ƑvzS�չ"u`H��OTC�)qd�
��6�?��>����/y%�!@�^�觹�T3c�N�@����r!�ؑ2b����W� �����{w��A��"��h��:U�+p���k�)�4d�p��-������szIlG�A^=�h<�^��h�O65��!U��E�u񊥵z}��t��/�ƨ�d��tPs#����|r>���� �,w��5�@������ET�-�+h�3�W��.';�-�iD������_ԋ��\���L�]�:�M�7����i������qgDm3m�ˌ��٦8_r\��C}(.�z:u��};sZ�r��K����Q��)b(>-zf�Li��j�֜�'<T��P��z	C�D�\���lx�N�Js�b뿢���N�WkD0�T�+$¶����0�zj� N����M8�0-˶����م��<-7[�⥨�.HzY����� �B�x�.���Yڤ9�հ�Q��o��я�B�k	��+�"���I�������(��+E U�Ri����$B(���7 ͽ:E`<a��s2D���m'��X��e�J�]���U��_��
�`�]~Pc=I�Db�~T���1BW�jd���U�t�`0U���2�;��%���ЏFs�����T@��'���k��^�Q��V��*��#/X/���6\v��.��n�6�l���Me�2�;�G�m�ʿՌ;`'��z��l���?q��x?r����tå���j��2c8�鼄.�F��"�"Cb��\�-=6�=?r�h�	]:���&�X�P�f^ ��JP����g�d�;����(s=�Y�8��`�`��0��a6����uc���w�2�ؗ�����*Q.,oN���~�jI>�E�{�|�0����%V�r�jr���p�
�����LI�{�<��i=�����M�p�ɭ�C��pi�?��3īK;�7�Q����@DP��_9���^��H��E��db��~�4:{d[ ˽��*Z(]]x��i����D|Y)�x���7��S���j�0�/�k���v$/�'��6Z�)�!���C����+o������N�"�gJ�*ʈb����-��u5܋-qҏpND�0�.�u�#��r6Cj[F����G�[�}�,���f����廚���ϻ�3iO����ԺP�7��u�l����(帳��ʣ���,�!��$��%�u�
e��0ǘ<� ����0��C%Rt�m�8�we3�Y�b�zf9hl�=��Մ�N�BaF��W��g����Exc�w(б�hG�II�	�����]��h���/ҧ%�����	ﶆ�7�L����
������|K�-��H�f��K�	��Ń�/g^2|��l��a�C�g�VE��¸E��ǭ�2�7y8pr���=B��Ϊ�&�"��5�=�19M��n�ɇ���5�'�(�J��½���� }q�� 8�r7cJ�7��1ѳ��L�5�tQ[�y�;M9jQ��N*���g^-|jLL�=]�����Y�����b��Y�Q5����FY������ԇ+���#^#e�:iL`��ߊ+�S�FX��G�}}j�.�x�/%$���b׼�),%V4LJ|���.���>8���ǈ�T�pi-Ъ�j��Hh�xB'�Uk2�Y����o���H��͚��J9u^�,��4ʑXL�F��/:r�\���,�/�;΢��/��.� �5����P{�<���@Lf�l�p��{>��*�_d ��3D��A��V#�=�簽�ɠ�ݶT|�߂�΀�p�Ղ�k��~3��rI3yIY��n�<;�d::0A�<�?�p\+ܖL*T6�R�wKK��������\Y��0��XS����Z��%hD�PA{5�f1ԧ���$�\?WPxlp�*��k�.��P���V[�:��M��Đ"K�s�f+r#�e�����??H>N"�$8XL�d<ۋxإt��u�Ͼ��f!]�Α`��BK��m.�����n\|�bt.΋���|���}y=�[�`�X������	�gЗFXZq�N�V	CTi�78 &q��d|�_|��;b{؀�������� Ը�)92nUv�����[�jFs�k/,U|'��F��,?j�؃�����髯x�����a���T�=����N*B��$(����n%I�3�P�qKz-�Îo�sX�0퓕JZ9E\�]�N��pQ!���o���!������,���VX���S1;i�BFuo���?��S(U!^z�~�=�l��8�&k�����M��"}"�*��4<xtDOT���R^�U�FLE�%�֚��pi�uq�[Y�a=�j
(����"��=֝)��8+��,�n�h'������V�|�W��ӒȗO��Q��@TY���B�JίR�J�</~}8y�&e���{��X�s騔l�����IX��C����<�0-ŧ^����l��TϠ�b6�z�+��w#���%I�i����7M����~���o'tg��,��˳z$����'Y{�5����] ����_�mAz0�J.'�C��2 �ڇ���n5@�~���T��p���@@�z&�5K�>�=ku�0�f���i���)�zD�P��)CC�51��ŏo �p�C��I$�;&� n��3�NQ�A2�fi�K�73'�Pa8�偃A�7ki#U�n!A�����M~	dK��g4~�^6�x|aNE]}O�	�Q�k�R�ȗ�L�p�76���pގ��*�_�4�S5��E_|��_�Cũo�'�Q��iIr_�%P,�A��PX��Z@Ƣ���a�Vh�of�3�ܗ�:�ebԌR ��3r �¹����ogl�>Q!�uy�%w��B�`�����<��e�'��g���uf�6�t��a2\��i������"�qǳ��0�*��1��)$PL� ~X�^�������Qޢ#�a��،�l�a?C`K�ശa�
B?(�#-b���e�,��v����U>�s���y�$���<�t^�>Y����C�+8�J�EbD���b���8���AH\��s=(��V~5� �#/P�W>0�/_�i��)�e���C�~�ͮ`
���S�>�(~{��4�{��,z��,��n�����rVS�0ˮF���%7L�ֻ�=��k�rsj�U���BљU�>�\��d�Sg!&�W�,N�vI��x�Z�S_�U�:+��4�=R�	m}<�-�Ր�@�I�<�B��MB���ƏݫYܨ�Ƚ����巟�  ֒�Ҽ�FJ��!��wL�s���"�qE)_u���V��E.��t��ά��}����O�'�n�����$���c�۸�j�r9��q5��-��|��b_����tkG\#ɳ���a�;0�	atY-�t`�6�d0���%=Y��#sg`?���|����#���ZZ�1L��2N��|:y%��g$p
�_��% ��V�r�`���D��s b�i�Uٶo�V�-���a��4Ŋ�{��_h]2�s:��g8�'P�6t�e�3bάǘDC��$��j]�#�t\���0xPbX��]z�?���rG�O����ĵ���3<ڟ�LL�` ?��.�i�PMq�a3�!6e(�A����໓	*P2��M�=Z�W�\擧���v�<�d���jW{�zzd��H���L����������m�u"�@&���\�Q��Dl`����A�GF��)CJf:��w��=�IF��~��M-���7�_�5�'���Me�(x�7&LG�!S���V
DY��Ssq�E���&4YD�@�Es���D������S�hC�|��6q껝
F)���x���r���e��{ҩgz����|��t��ve@Qwu'vի��
�q���<�6�jD�:hF��2�0��o��R���!r��ؐ^���5�o�@����I�oM�t{�{�{�&t�_�w��vSՆm��|��UGPg�q�u�1��iN�':뉚g��D-6,BO�&��2g� '���E��m�K�����K<��D�	�Ge��v�%�I0a��?ď���\I�Ta���L��$~��'I1���e����\x�qnQP!;T� 8�m���7	��i�A?���e�v(��y�Hv����ij+�����ou]`)>4��Z8沉��9x\0�e�5�T��
� ��b���>G�e?�@J�GGr��W��AP����g�I�"Ѷ>@1�+�EW�M�Ρ��J���y�P%���nUkzVE�lR&�2�g����� �e|St�4>����<�W#h��Tʌ]���`.�C�u���;�/���<�n�ݡ(!k��K��x��㽢��M�	�>R^�(�Sq���}4�SuI�'&�����Y#���/�
X��?Ǟ��U?Bt�D�K�T�g��w{�xv~���Y�GQ����*#�l��uItdox�5K��������4�C��?Q#�<���*r�)��d)��h(�dMc�������U4�`5~o��៹��Eҁ ��r��?����2_8.(D�� �dz
i���FF�]Kh�H�?���6�=w���ND�y��^-�p��34h0_�z�(=rd������M�W��y�����Ǌ���Ǜ��.��
����/��#X3\]<7�-X�k�g����=���������)/2�o�4B4���^�m� >�F8-�-d�6W*/j��c9�د�wh��A_�&i�A�<\A���ݕ3��Fֹ�|��}���J��cړd�w���bZ~�]_#���8=@�N�p̮°Yd�c�J�@��FPS� �lX�-��¸"d��h�� 2�k�� �`I��]��V�MHO!�^�B|3JR0�F�պ��3׾�u6�5A����.R?�4�N�[b_����z����6VRVt��/:F�2���Ñ,��0pH7��l��YE�XY�	�aB���ud�"-�D�ך�v��n���B��Uά>�*�A�z�9���"�q�|�Tř�\,�6�g�ٹQ�y�?]}�E�Ic��_Ym=f���R�`fO�9�Ek���\��&�k�l�<��������e��Df:0�_2�_�G���#��l�k6kn{���8�SU�Td5�;�%��ݗ�^Vc�Z���oD����cU���M���G<;v�G�X.�>�CAO9h�>��m�[&��G�qp��\CQg��P $�`�8�N�c����X�Ae�h�d�����T�7g�羘T0��g��hgn�_�DDO�U�j����0?D�%~���æ}{�:q�PFVu�1\$d1",<��+�{E|���H_�S��t�H�D��_V�G��x�Ǉ���T?�P�V ���,.mZ1���o,
�L�܎/�x��ϸl;���jF;�q�d�2��ȯ[!�v�ޫǥ�2��@���A�yA�A���m�.�1M���
R,jb�"���U��Іb&�Kdoo����E��x$ɋ��5ƿ�b!�<��K�:����8��H[,r�ՓL�7�N��dօ�ʰ+ž6�["�X���[�y���b�(&��ѣ2?�~͹����lk���G��<��zYB��p_������ٿ�%�!gI�E���}J>D�/���{,�e׷��H�p������ǥ��I���!�
d+��q�)��I��WO�bn�Is��� �E��zq�ˎ]�{rh��	8����.� C��3�"������㍌�~������c��U�!�`�>�]��m�<ˮ�}2~ml_T	}a�J�#�$���0���ƃYP�
똠Sɰ'�p�?����Q�j�LC�����3��Lz������\�X�p_ޓ)E���L8{�1�����]D���%��W�t��ׄc������y�N�3h�����҄L�Ǟ �c�w�����$�YO�T�bnT�9�E������0~i�h$b�*v�� �	���8\y�<�_ �����R~r��Z�K����)*[��Pe54�Q%ٰ��E3�ݼ�Ѫl�Q�j�X�v>��	���LE��6�)ow��B-�+'����/�d움�t�&6���Kɮ�g[�,�PB�ʏ�/K�}쬮�Z���aS�k{t�������/��S��H"�6���O\��T$�>n���-&�~�-h6\���Q�zT��.=o���N$����
�F�R�A�Hf*N���q��a����F�$���9��u�bI@����E�;7��I���۩b���Gm.X[��"��~��{�U��$
8�=�an��K���+y�Z��8�RP3�`k�����t��ls9�4��S��s�a�/צi�j�`p�����8ծ�#!I?3�d��-ݐ9�ňFU��Y����+ȏ�va̴������w��U}<�k�~/׌%�3�O���ݏD��t/L��R�2]j$�,���唭dd��-&0#�I���0W��p��yb��A'V���,��"�3{k�K�]��h)���0Zҫ�q�c+�.��31(��&�OЭq�E���Yջ}/(��[�����}6���с���������m�Z�D���{�09��� ���◄`b�]K��X�SK#?gc��Xveh�8�!����%�k I��8Z����jx�EaF�4���c{��o ���o���B��ȉSZ��[�1r.�'��SQ�䗋�"K�U����=���� mV̕r��S^���u���F��匆�p9r������=�(��6�d
ګ��L�>Yv���;.Db	���GE|8����R8"�ꬹ3F���{M�7�ϛ�����1�ޝ��ң���z�9k4U� �/�y��>z�B���iq��Kc�=��Y�H�'���F�t��WN�v��1���>3��\�[���	��,���8��JF��\4���:��+r���3�Z��� �����g�e0���{����������jJ��NwVLv JJ�>�1;VrQ�J��	�S�X��.M���>���ض�Km󢘄�?+g�7���ߒ�����o�n.*�O���YuM�uV+�Z��7	05m-�?����Ua��ؽ�4e��(�_�]�4�+`y��p���V�D�����mj[#� ؂>���#m.wy����2�(1ذyW�(3u��B.28D{$�2�yBY/4BM�w
���*���|K���UFF�_$�{�+[Rp��i^t�0rC��!���너êOUio�3 �Cߏ�n���bPp#y��Ĺ�D4�1��-�~
j�Jo���<�Q��S�bGx4/���b����/��ctwg
w��R��I4"�)E(�ĦF��Y���ڛN�\t�!��k�?t]�TU:9��x��b��h ��/s�]��%P�X� ��Y����M�D��5N4Ń��Ӏ��&�Z��I��r�A��d��Lp�)cp+{f3/
@bĄK"�/所�iЗΫǮ�YUMQZ�����MXF��cn�wA��!���ݎs���UsY��+��S'.S���`tc&�p�>���p���̕	dgw��U�eX�,Db� �֡A"C��ڽM�s痦����6���mz�mLiд�Am4� _���C9,���`@#|��>���s�ã���`�5N��ڹkT�O-��A�yd6w��P��X���X�a�n;/���-��eO`|��;�������G�R�@�3�\#F,��R��G�b9�m%�O��&)�S�k~���s,!����?%*���#��6^���a�ᣳ�Y~)HM����k�Lт8�uO�<���֎���նJ�|�B��3}����ӑx�:�*�Ӌ�:�Qaeo\_Ry�ɥ��;�Λ����/`���ز�h�~�7�c������"�y��%��#��<bnd��]W�Z�5�G�,D�^l��8���],U#2�ǓMo&�,c�!i��+R81Z�9o<��<�U]���|���h띐re�����s�0~D��r��~iD�)}d�lT�h%i�5t�����D���bg���'}#W��|-H���i����>��DU�<�"�gc �d�gz���٪������#虞��1�������K�,X'{\\�;�OU�-��/_v8~(Yt�����Q���3ϥ.9=��}(F�&c6b�q���"���@r��K���1�zç2�}O[I�ș�&d#�P��e��G*�F�duh�9���q|�yیH�D���<��+©�-�{S�p�D��+΍�����!9���f"�D�����Z����t1;���B�^�|E8�Z+��@��rk�TG/
3W�%Z��Kd_G_epɳ,GD��D~ó�A��`����A�=G�����_���h��f�iz�?[[4�:�R�9$1�r�I��.=��X��%��&�\�Wò���S]����� QI�),x~�m���=~¤#�2�bC�L�ݎ�R�|@?�x4��97��!1���	S�Y�2ঽZ���5D��u� G� �TN\�/�	�wm�H~p=�hWʏ�H'�D��3�}�?ԯ�F؟A����F��0)�8K��q '�x3��mW_��#�&���X��4ú�'��{|-�lX�J#�I]]X���Q�j��V,���GM30f�)�>� �:���<��޽zp�H��CD��ID����w=�&N�����u����R(�YG.
�:����JK��MGs�U����T΍α���B�)u�P2�ޙGpk��( ��IR�Tq�	ѿ�i�ZC���� [8P�>����F�*��`�\@!=_�N��$2�7i��ʔ��q�ӊF��H�a�h7���Rq�U��]�����*��/��H{�_���E�1	�|�P3i���@.�պ[�eM���`g{8SK��z��
�������ZD ��?�`&��j�SJ����N��Ғ(�`2X�U��.3�{%����(��g�/ �`*��w4�N�cw�4���I�yI���i�0b�幬`����9=��R���T�f�z¹Iq(a�����:�g��,��Ҋ�2��ӋӖ���n�y����?7��d3���?�K,u��;�cJ��GA�K��� A���օ��~��X�L��gg�La�e��y`�P����g�e�ަw�����o��-WOSTo�ȉ�r��<���'L Y�w}k�,�7�	-�U��|CV�JF��	Ȥ�ta+8�e��*+GC;T�PNrq5������&�w��ӵF��%2Ȧy\�5oP��蠎�^#TX��
K$�����
W�DՙY��J�0t�x�D�,��]���d�\��Ԭ�c2�^�>
�9� G]�11?��'��|�$5����%t! �/J�����-�9��isj$NG�w�CI�h�0m��[�{3qfv_3����I�0�ѯ��d����j���>Y��n�^s���8�g-acC��a�Z�Vk���= B�sI�W-=�\��;�L��x/�g��J�ߟθ+͞�e)�L��800ѣʀ"�߭�}Sm\�g��VT2�Ц�S���(8�{X�jg�I�|���f��/�L,}�<��=��LL�w�8i��&��=t!�N9�Z56����F�V��|i�mҍ���>	���db����[�ĞK����VX���A1�Hށ��,��R���E��k �r�m�L�,5���A�?���ّw��I5�cy�ED�|��{��g��ӕ9�N�b�/��rw^}���q���@���f�k�ڀi:1�ҺW�E# ��T�Y`�/����N���@3��&� �N�'4 ��n����>R���KF=�"nJ�c����lK���L��(�S:'F�tH��3-.�o�D�̭���(��:w� �1>Y �wk׆���w�b�L��Gvw�g�|�/��@�s33@�����9��'6�#��Z�Ʋ��E�E�1�pT���N�3:��G�����D��Ì8��'#
�e:��u/���� �ߓ�i�'�>�hj��L�5�Jl
+� ���}�L��/��6�쳸i��e�?�k�Ƴu
�I��2�㥔ΞB����$<.�U�5�b��K4�r�'=�O.l�@�lzt5Q>@����H�f� ���]�������\7�f�ebg�����a�����1h�]�"�y.%6���X�měQx ��gCJe޵f{%|R���j�Ũx�-�Ec���&Oe�x�A��J$��,2;�f�aj��3�;M⛤�Qq���e�����v��B�91�[7X�̎ �rn�Q4H�Wݔg���&~�ZP,�@�%�ZcI�uL�w==��!���נ��"΋�d�.1�w�D܆�u�Y���� ��(>U�wV	�wJ������$�o�=�Y���K]�F
dk��3�T��W�j�����-�Y��t�L��8�U�E\�|s�9�1ߎ#r�4)ä�ed���Ω#�b~�}T��%�z��x���D��!��c�;��y���.-�w����}s߈�����"Ez1D��{5�,RDؘ���Q�k��J��Hcm�7�vu[�O���g�̞���Dv�'�mX�/,������ׁ�[�Χ0���13�U�\,���1�PUj^qb��e��#c,!�Ahd��vEH�=$����n����v�_�u�ts������󗰯ޙ����eBj�2�L:�_�[U�!���=�0����u�!���u)*L��j�s�������\N�w��FNzG�3�hZ�+g-Fz��:Ƭ��^��k����l:u�r�"r���V�)� o A��ͦ.3~��'�W���V�z�b��x�dZ�E1�YtX���-�l+=.�<k��~o�+�n�ț�!e�{�En	5[�4���Fk)kKavƗk�C�����Z@���@�8��`k��p̟�o���R�KƲ�
�Sn����&�X��Z��螋������E:�ޤ3n\�_���TTiI�����<[�ů�$��9�f��[P�Mp��~{�sZzvK*�בT;(ZU��֏*���&o$#���m	�U���I�p��w/2=��T��� Oy��z\�K�[\�&,�s�z�;�����%'��Y��rLQ�1����~sZ�+���sجl�6Ev�����ʆ*�q@�H\�8���_c�/ޠ��+y��;A�X�	uθ��<�B;���5ݪ߃Q*�d�����T����\���w�Y8"#�fғ�c��LZ۳�p&��1D!.ظ	+'L��ņ��/0��ᢱ<&ػivz�w,�ڍ��h5܉�j-�[n�"S�} hKk�1��v9i�ɣ͢x
�x��~�/�u�*6�|��W����+�S��
a?�����ʑ��V�!����R�Xh�xS�l}T�S�S�.��/,@����0����T��y��W�zg����m��|D���=��Fq�R��~�+'X#WXd���-.�:\�[-.��:ɔ�2������ ����I���9J�W���|���]�-��:����4���}���z������n��xhX�1[��L��4;�M��j��\�6�%�_���e�������v�H�{���v���_C����rc���{@S��B���8���t|����튒	���v��]͓�K �ԄTnvZQ��Ǿ��Sl}�;�<�9�Kg|��h&h�Ѹ�lr�o�����$����5C2�bT�~�s���Yw���\��\BK�)'��k�>I����j5�Ȑ�8�}�F��5�%V� ���[�=O�P���):7�J',]�d�/6vu(M��J\V'��&��� _o5���a�?��
�	E_-9���)c��N͘m�M�*4_菄��� �6�*֗p���8�����1�.+I���V�+��l�<�.Q�^�b5j
���O�"H$��z����}�e�/.�J�+�<*6Iæ罉���JPj��#X�p�a�q����x�3̄:�"N����F�(3��,������v��U�T�3��߃ob����!�I ��^Z4cXc.�?K*Č�q�#N�V������Rix���,/6���i��^�:P�w�����8��S,JҔ��n�9�0ݠcW��
s��:�r�\/��J�ssgP�0��ʨ
����v�	��c�go�8�[rн���`@"����{�\2�~k�]��1l�d����Ae*���c�-�|�OٵZ{�i��~�2L*,�H>U�:��7��P�k@0�w7��|m#pd%���kݶ�tiLi����~�|���n���p��]��.anp�_VydN�1�&-
7���"��35�*+�o�SG	�bQp��צ����i�b<8u(��焘R�m/�cFm����e��2�3++21׮�g��ɼ3�2pO"��-��c3E�<����6c.��n:�=8����0�,2��'i+�<ә6Hho�$t�Ěԛ�Ŧ_�}�E����K�ꁥ(�J5p��a��o&Ppq�q>H��)w��	�p�T�)J4�v0ؽ���B�3u�t��ٚ�t��8.D�b�[���������������IZ�ˤʵ+ɤ%yJ�J�j���%��W`1��֬q�oM��}����5��6z�{e�򣦝���0u_1₣��e�m��-��Nw#	�)�46��������j��R<F#&���Mi��h�1��6��"J�x���e�K
���;|ƜQٗ�'���S����X�6���w�2K�)��Q�R��qG�g��"5rUS}-1����w�Q9��aj��vR(|� ��Z2�|�&�h ���V	�B�	�'����m��O�L��)��q<}��,������v<�v���� %.Q2�1��,I��<����9����-Y���&�Mk@mt��(��mC��3�3�Z�7x���k��_,v��%Lf�8~���,q_Ή^��,�:YTG.��7����RBЅ�ه5�}d�t��x��eߦ����:���2'7p��,�%R�0<QQ�����U�����w�ؤ���M;�h��`Y7�j��\�j���+[B����e]�O�-���J>��2ذ�H������Lv�f�I�
'�Q5x��Iճx�{�?����9�J�'$��� S�9����-���hR"��%F0�S�bWغf�1:կ�5��.脴����q�R7�v�4�ʾԚd�po�g��d�=1{,xqa�E3������m��b$��lB��'�����V�ʝ~�:�:T���Y*'I#��_i���њ���(B�%E�h�O��K�,��s,�1F�`	��˟�Q�h�u�)��cة��Z0����K��wf��3X�Y��m�ÓS���U��1Xq�A���h['@��!@}SHj���D'�W�Iq��=�9a/SF�ҽ9�8��*`���p� Tdl
�M�zL΋��S�:�c�½�;��)9Gp���d����g��|��"3r-et[t�[�����%Q��w�S���]8ƾ�>>�s^��d ���~s�VKÐF�4��	Č�9�I���M��26�'M��C|��4N,刃��N�L��z4*"����=�8�'�|	D�G��%p܇^p��on)3T��,�~�-H�`������e�OM�}�?6{%�l�r����;*l9ctyq����ZYț��$�W�6֊ I�.[��������T���"(���Џ���]�`�]D��R�B� }w & �"]�����+���De���:x�w<�|��x���Y������8F���-��l�-�p8�r	G�$OQpo?u9@fJ3��,�mH���TP�O��>�ڒ�a����iaݕ`�q�2*�߶���<���o�O'` m��$��4N��/o쾦X���vL���.T	x˻7X����o���ݲ�.�eޚ�=��~�O�&(���[��z�[7��>oԁ�	ʠ�R�]�����l[�ަ��KMJ�!q�˖�}p�k�k� �"��cR�@ �����H�Ա�g�    YZ