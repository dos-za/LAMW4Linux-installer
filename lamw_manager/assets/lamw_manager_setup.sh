#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="31127450"
MD5="0c4f899b1a1221902e909a4467600bed"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24096"
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
	echo Date of packaging: Mon Oct 25 22:30:54 -03 2021
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
�7zXZ  �ִF !   �X����]�] �}��1Dd]����P�t�D��R�s��DW�#�q�Ŵ�	��bS������̞I���9�MF�	O�pna�:\M]r_��t�I햓�.''�ʅo�����G�m�t7��*�t@��4˓�J���T�vG���f�Q�?$�!xs?F6Y�`fq,u����}*�R{ �+:Y�e��a�h��'P��B�Xu���6(�H]�\N�]僨���f���̧���h8�e����D2S�<ر�r�*�'֎�^�sq��#e�PMko뭯�(H�ȉV�X�;�����7�U�N'���a�>���w:g`�	��yM�P��Ug��D�4��;ׇ�������'��\s�k���<  flx$��9�d2Z�ܱ�V��[�_9.<��/d�҃�����'C�������؊�V�_��l�3]�'<J�l�γ]�bX�;�K�]�q��ص�G$�9�Kr��w�u:NFo@�ښ}��@�fӣ�O�^w���a�����A1״��<JmE�(Ipf� ��>��o�ՔX˪���� 0T���Yz.h�\�B�GQ4�5���6��U�e�H=*'��},e��O�s[�9%3�����*��s
�ͬUb��`}?��&d��z���w�#�&x�/�M�єP�ܕ��_�oֹ�^�A�fQ�!!�4�'���7�V���=}���ηv���f���WiZ߿���"W�o��5^��T�~*�� �"�@CI$\[�j�����x�}tmuI��4�����V���8E�w�����gޏ�dym��J�5+�����qƯ,^D�vD�a������*^�����9�z����񗥸�zz��l��:�_`�?�5ǵ����&J+�r�x�f��yL�(�Qk��՛�1p��[-Y-x�J��F'��k&�Y�]:���X���ZR�%�5g������}�}`�� {b���?��9+,c|��#] k��9di�T,b�~Ր0��<��~c�$'��x�"���U�'�ZA��NS�L��Ȗ��+�zXML7bX��&ۯ{c���D�V��h`p˞)�̀|Eb8�Q¸�{�"N�\BH���["����4U o#�(�!f.�ϐ�.�Ïe���-D"�FTv&
C�8��������p�8 ��������n�4�Y�>f��_�J�����.d�\��< ���r����S�Rgc��j.�y���N�I�W�1zb))Z٩���Pҍ�s�f��7n@��[ ֳ�K	���t�..���x�2���i�*�}�M���X:s��3��B��S�_����Ei9�~f�w�O���'`mN����k��^�� iXE���%��<*~
>׃EP���E c���Γ���h�>�byI��2@����4���/Ҝ�m�8���;1�R�E����J�����lI.r�_�aY�\���S��D���,w����ܯ�xUI|ҳ��X����Gz5|�H� h0y7�T����]gH�`���=�-���9��.CVՏ�m���by��!�%�ΐ�E���C[0�-x"�{�?��W�gû�Y�BС���5��i��<��d��z�w�Q�3	��>��t��0cfL>6��=#��,ˍ����Ѹ�gWp�MA��(B$/q����c��2'y��wIQ~t;S�M �*e�p	���ǐ�d7����Ί��1����e���g֦�%�_��o���9ͤh��.�1��>W ��J}��+V8���ʷ0�q6 sS��f�*��P���k�W�E/���f(�m���Wɜ�� �"+$�6�Z� ��W^Z��(!�x��g^OS�,���ќ�f@P,f>�H$o���e��g�+9VN�����<��h&�v�ᨄ��*���y��ѫ>����/.�Ϡ�J���f;4-��]M���9_�R8<州T]�9������FD=�4��X}�O`
��Z���)p��&[��ǥ��U��x�(�L�L꽁������hB�@g�l���{ӑ�4�G�\�JK-���KEp�P� ���BQ���JS�����l����J`Hy/ל���|�:Â��~k=�n�o��N�	��+<���(�k���U����͐vk<�����W>6j�:˾cnUަ��5mP�
z����ioe��U��s�1M� �����1�̵s��i�(CmP��z��;1����pV?3�%aۼ1����<�]�~w����'������ϸ猉~w@~kr-�g�=�t��ٝJ9!�ɞ�=(.��1��z��,x4�S�����w���愫�K�6�b��	�� h���+�[�!��>����m�/v�>W��������ֽ#Ť ͓
��Yde�=�� e@���A~ٯ�g9�pfa�#�	����:%{�3-��Hp��� �Xv�g}�Nzt'���2*���&�٭M�,U-=��}#��# �aa�b.Ա�F���.�5T��E����@�Ԣ���=΂�!��S���/ȑɗ�.K��� ���j���2�1~��[��:�.OΉ�m^'�*�额T�۪*a+=K��Wؑ��zT�f�>������S@E<ђ���1|+|\E�6�+�F<�1�#�D�L~E�k�񍾨���&�XDSB��d��Y��lk:/4��7�;D�EyV��lzN#�׉�ŭ`g_����qB�HL������<�Eu�\��0�}���E2-�e(y�(�j��/A��0�73�U��J�"���m`�?ˋ�Gc+-3� ����V�{=�������W����Z�_����| �J0�ũ�	c�}�ҫ���ȍ��~��S�aW���9��d�ߎ<a^_�x�-�E��v��U�f6H�q���!);�p�#��#��U�E������j�ț�h&�#?f�d	��O7�L+�����r�*��@�e�Π��E����Q`D��ZPj���)8��T����%��!��.��}d�6����)=��1.&�D��N+��a��������.����̛D%o.��B��I��[5j�%�i��Ӆ�(S�I&l"�@d�!���Pα�4���*�Dq�H6E�*�����$#.Ɂ��f��/0�6�f�Ƽ#7��ܡ��W�9f��T�ˮ����)lpCB��y��B��=?+k��
F�����Q��AT��@�{�n�������%!�>�9�V,���LJ2q����羁I�	�|J����̂B �	�����ZS����A��I��V ,�W���ӣf�)ٶ0 f���q��]��ܞ�;$F:�5���'��>��I'̴��QO/�_#-��ѹs6�\�|��o�P9�P>�������p��oM*�Ič:pEk��9M��g���R.��baN��t"Y6���%Y�L�Kw�Jw
t�~�rD.X��8X�Bh�s�3��~*�3�ң��0��ȩ��lÎs�m��3ւ6&qD�k|~RJZ:��:���M���~�7�}No��M]�eg�C��q���od�`X��'�ٙ��9���ZtZ�b�Q�H~%��+H������hKb��cdc-^�f�B=�X�J������w,wB\�U���L�� _{U��r�4e}D=�,�_u�	hɚ�T7�i�|��=�~���:�I1����������q�|����"W�T���g�|<-!�[q�����p�l|�%�݌t��0tl	e�s=E�;w����|�N���p`[j.	&��i��Y��e�[�c�9�s����X�_�ǹ�N�OPF}��5?��*�.	8�����=�"�z�OZf��T�P����M�r�t��J�l��f����B�󋆝3����E��<�ਝ|���=9��}�3H�D{y
R���|��{�Q��E��6n���L6�^����T��~�����M���;�r���;!G{/�W��� i�}	]Ѓ�N܍�Ì�����0,������jwK���*N�&�`ʻ�k)@Ga3�����ۚ
�}������ֳc��X?l0*cz㎶k�U�;Z�x�T��>cX�iReFY٢:�|�K�O=V6�� �v_����c`n=�C��95�{U���O0բ+�"T��H�"Y��@��N��G�L `�D�H��s.�}�X�P�P�V��`l��$]C�{�l=IeQ����}Qy�;_[z';j��A�|t���W�]�$��q|؂��}2x��e����X��F����%���D��J�غ{��8\Z_�����v�MWn��l�f����`�gFex��/*� f^L*]̺���X�I���3�?�	g_�����Ma�b�:繅$uZSo��I>�^��Q�A�X(�n���2l��oW�]�����m�]���b�c��Z��15u.)�G��8��K!�� ��c *��eٗbW.R���_� 	~ݥ=�b˦ګo���P$ܟ�f�mȲ��C|�&��$��T\G:Cs�#:
)�>�!��}�);bxs��
���:}brp_A��/�¡ƈ�ȟ�W�!f��>���ŏA$�W�ח��3�Cɲ���M�����f��ԡGb��WQ�jNPT�(�-�@n��=k�4������%�����(/������� L�v 5����zG���,㚑㕀`Xܴ�߈�����������'��³=}G�5�}�6���o�X�"ywmII��_�S�\�\�a/�A��9_�h#7;��:X47d]T��qIP���BBU)M��0��G8ԧc`C��l&|<�ֽ�����M@\�5��\���ޖa����'Lu�.!V��!mn|T����Mp��g����Z�U#�@�Db�=o��^�2�V���B�Q�����a�`��b��f�KN�%�9{t���G;=[�R �,3��O7¶��&I�[T��ߜ��/�H�;�G�zۀ-�����4��U��~R��+���ޟjp���MZ��6�e�S7�<p��
ݐ��fݥX�W�0���L�� �B�v7�����,z϶s�LF�*��b���\_�r����f&Ú�w +,ʩd#� 5eФ��U��D�|��k�0�ӝ�3��Jxq�`k;Z`dx@ӟ�JS��)��醧��|�e��{�Z�S=˶��Ig�� �c�Z�S�`���U-M�s��eɼ�����M�?or�Ť��񲫴�hTs�P��ks]��H�=��k�_�*���(g�\�-�0�i�a[{�xDr-r�ɢu��R�����\�u�wm�O�R?�X���YR0'�C�Yv���ə����=cn��JAb~������߷A�YW`7W_��w�6�_��������z8d��X�W�k_0LL��f��\ �ۃ*�j'�">&��g��@n�y����yT�Y�B}�W�-�y���?Y��o6��d�Q���¡f#5��p�8A��*�-z����u�E���^�C��Z�V\�y	|�{�I�#��|ed���,VLP�I�RZs�Gi��%��~7��f8\&(�Ŧ�ʛ�D�	H]���'�Yeo���0���ņH,/۫�I7f�J�	�j��W9��R}�!pY@�����.���p���[��&ހ�Q��e�m@V
A�_:����9r|Ï���@�A���<��OFt�z�����q�`Ջ�">%���f0����I� �Pď�D��1jz��3�xy��P�m��lnag/�1�jg0DD������]r�F"�2𖂝@|9g'Hh�:V>��#c$���ȍo��5��F��x��4\��'f�)~�xA����g���u�|�0I���D�C���Yp��ͪ"8lby�,�� |A/��i+���/��$k^��?+�	���Qc`Mt���ư���%tN�J�6B (�mЎkޅ�F��хr<������Cn���0���D�#Hʩ�z��W1���[��3�.�H��i@��%-�>�Q<[]��η�+�	d8�\�Y:�#j�Jg'�G6-/�$�aS��@>��V��`����L�Z��b��zc٪��W�Z�#��ډn9��e
��`�Ke)\��DE���BZ���Mr��w+n`�Ҕ�X'��4� ���J�WzáG)� ���owQ8�l�,nw�2y�ǎ�,� >���*�eJNCR�}�خҀmMB��y�
'���f�s�s������
�r���Fᘦު6!~��;j ��4VDh�0	=	�%�B!9Эo�΍���CyrVॗ����D�{�c�����S��c��ђ�׆}��<��e� ����/��	E�eUZ�O�16	� N���<�.S�����V�xw_Ǖ�x�r�������P�T�C�*�� �Y�}4�`�*
�"�Ko�^��؞�Ыz}Yy�I&^)(h�p��-�*v�3������NS�%|7��8��A:��c����m�1�؀�u6"�We�{u��~�0�nZi��}zw�9������@-���i�>�D�2��_�f�<�c��Wk���^�%��X�N,+�?5�sӟ��7h�%4h�U�cP�	)�M�2n-
'�t�e��KZ�[�V����Q FL��ꪞÅN
���~�;Q���bhN�����_%Q�{+��Ҷ5�����r]���0���#�z� �=i����d=�1�a\h�5����tj���aܕ� §�n8|`7���6����,�i��`����8�ށ��E.<�L,���ts�A�y��*?�4�9�M�ص�µ�6~V'����%����
��y����~/�
!�Ϯ��f�m�F����Q@^���h*b�[|Pn���~��6U��+����%�zj�*#�xj��kl�A��\�Ҏ���Ȏ�]8�%E׭�yu?n|���M")�?�g��z/�GH���=��"@ �>���y5q����]�%}�-���낢R�A���nm�b�%�U�+�a����4#�1�p��Q��b��)7(��6�=��;)�Z!#x?�׋�u3�e�)S0g��U�]`*�H!�0I���"ְ��q+?TaD����l'֋&$x"5�`�dI����z����?�跀d��/p�s9>:���0�r�)����� ��ػ	��fn�*Z>���.�\���(�6�dd&$
D�?I!��P�Ƈj����6@��Aᾎ����W�(dr]�ъ=軲���.���M���Ђ���U�Y����)l9�^w)�-�P=���=�(�����<P�~�eb�p�s('�i��R�vݝ�T e �5a�g�^'Kcj�G���{����Y%��'D�7����>e�s*zNg�A2?�>���Vt�	����������E>SϬ@�����1���!o��D��7+x@:����y������8�PH�w�xQ,�|�u&X�Y
3�����P�նG�� �hl�g�Q���|b����<AOm�EE�wG�ǻ��ݰI�!��a����|�D�ҺX���E ��Nw�.6 �;��z�q�E�qp�R��
�+\���ޭJbuPV`}i_�F䳲��(��+k�L�oU'q�!�޴GazK'2W�J�	�����Z;$	8p��Wj���p�M+-�t##�Ө�R?89�h��1A�5���a7@�ȏ�a_��g�����\�|C�
KT�(���2[��*��+R�%�?�W^@-�W�7���U��D�e|�o�Lq�2�բ�~]R�!�����W#��j�"�jٞ�ay���"8^khޙ���@�լ?��}J�hz�j��]?�E�����zb�7��H-������{�]S��U�޺��
��hQ�{̰a>-��l��y��"y�c\��'=L��;����Bj�z�*/�H��_��j��Z�I�I������Ʃ��~7p�=�.����C*D�X'�K����;�N9���W�c�R�"���%��N�1�V��e{������i��V�ߟ�cPp<K(��w��e��5��	ߝ�9x��A���b��y*���!2\ᅶ�>�(��%hV�/j)�
	;#И�����eS����(���^���Y*����H��2�)�I���j�&
K���n+��T�����Eϗ�;��"�|�fp�&���5���GH9`��ق��7���C��);��	���x����H���z�����:t\�O�J�c�sc�s�x��_~�@��:lp�nЮ�G5�Yx�$Fx�-�_�Va|�d�4F���z̛S���ۙ��{�P�G�D� $�YIo�t�X�Zʜ*��6E}�z�#�E�={���a�?���)�9͞Lٴ� �W!�I +#*�9�*X���
j��~=�� D�D+�WRy�f&��T^�"�H�0=�~:�&�jgM��>��y�y�Z%��F�|�j���TrQv���N������`�#tIO��˞r�WЊ�͵OKã"�ϡ�2�GOe>T׹��ĳ�P?�lK��M��`�϶+���X��=���)��A�4�voh�r�q-w�v�6���$�Ҩ ��5㌸z$$�DG��ц�C�qc;7t�6�U��ct�?�e�~��Lٯ�p����؇�d#���T��f��n�A�''�Ǘ����7�g̛�H~KE�
A��y�,�N���@P¿�qg^K4BO=m"ᓷ��qr9�7?�w)��k-w,0=�������/l+�l�lT���6N����k��C��a���\[��-Y��<�Я�h���XeP���+b���]�͚��g�n�.Gq9Om[�
D4ࡩ��֪EJ����U��Y]��ap�������`3GE�b߶*�K=��	!ze���Y��vdrȀ��)��q'�?�##-�*��=��j`�k{��&����iK��� �G �)8�R����q�g슃7����<`:�j%ߚ�#����`��W<�9.(y|����.�� 	���
��r�b��oج��ޚ��v����1�K�����3���bl.����:P.y������Rjv�ٕ�����Z�փx@gna��������e��FZQAS�^7M��h/�-s�h'2)��n~9�u�\��������;�x�|�����-eJ�C�۴~�����i��u%p��6\U�6UռӘ�Hܧ1��75;%�dY h�M �/u�w��Z��V3/��]�=���j���Jٌ�C�]���&R,v��E�\�����jCKN�����zLH���3k�o�kCX�h4��켯Rf���?��_a���!{ �Dc�D�j,�$�bl���/s�k�7)8�A�O����BZ#N������?���.�����K0g�T)�53^W��az��u#���f?O���}Ӓg+w��~r���^D}S-���O�Rqw>�c�� ��uP������"���sJ&_Hz�+��i
�sh2�4��bJ��je�%����н�7��M��^Z��L!���&$��O�3���G���8Ҽ�"�n0��3�c@��2�R� ѥ�D���j�ɋ�U4�M�����]�[P:�p.��u=��i�������P�2�t�S�V���}z
� =#16��W�,\��8N�m�ݐ�	pu�).KG��3t�b8�����
UNgZ3�K��H:]h�����a�':�Y�w���X�),L�F��t��L��!�I�=z���9eMձ�ɅP8��Fz_-ކ�f�1�ǑI�j! �(~R�ˈ�����+�G��yFw+�V1����h��2��Z����4D�[߷<�^�t�M��a� 1���^�b]=�/�����}��2AW"|�.�M�'c10s�S7(�V�T��n]Y����S�2�]��}����Co�n��Kw#�^���N�\�@�@���Eay� Էr�Ƭ�-�85�I�K����?�5�`s��-���R=:�`oN�%^qwɪ=�Q�(�D��7�:�=�0,�
N)=9��A��q�y'�E�����z��:�|G=�p;�\0c9��w=`1�^��>K4����>z̰��ᢶ*���F菽�t$ n#����0��>w�!;�h�� E�+�:ޖ�Q�2���<i���=�\�:�W�T-�5ϩ?��G��A+�y�`eb8S]�dky<%��2�Q�n�#�暎�a�(1d��>����P~����`�`{��D��������s�iv��/K-�ܹ�F�u��"Qu����̯cI��|6�����3�!��:��NFy�G�/'U	��wZ(r�I�Wʧ���{ǩ��7݊��qC�09s)Nr�d<�x�X�1�7����}mǤ�ܳȦ<)�l�Op���B �CrzTeOX����.��^�nW����,	Ad�V6�#�fX��p޴������E����y�ӎ-��c��.��`���H������p����As�tVR6+d�G�Ј�=���V��.���XH�D���K(��PDW~����u@���6(�"���H�2|�<�1��wXu�W�g�J�3�(~.F�v�P�X���|Tsொ�!��$�ZmA�1��i0�6�yO��h:�j�Һ3�خG�O]����%�^qe���jkd"y�,�;���ǒɴ��;ꞡ���m�</֝����� ��`l��:�[V� j�����mD��S�Ɉ�5~o����J��_�Tz� �sGE�����'-�J�U�~0���za�v0����{Z�o�v����#�5+�s��y��>5���%��ي��uL�D�ı#nu�����ak�]	�C$.�(d��8dMhf��)̞�a���.�U>X���N럨4�����Y
�1����E%(�1��e�F:s(LLw&,�2�����O�� ��'	�`��/9�N�������ۙ���t@�XAL0���9���g��eܖ�d����t�h�ϾOeȖ�H��P�dS��W��#�����q�V8����.�nz|�2��ʹJ�H���GZ�6+t�FvR� 'f���X`k��-/
����EwC,�l�1G�۹�Na)��?�Il���jD�mc^x�-+�q�'��3���;%��Ҽؿ*�p-���7����$�(���v[��p�?��]�;F �p��4�����5�M�a^g#����0ڱ>{��&����Q���ه��XIbHp?W�./D�#ds��JǙE�������)�<�_&��wM���W�)��>���0�L	�������6^�9��n�AѢ����l�w�x3輙(��e_��5s�V1U��&�����J�ռ�c$hƀZ��Z|߄��"�����s@ؒ�Ԥ���ε�_i�)-5['�f¤���x�D�X��# Ek�&p{���ќ�=B&�aNn��?�o���+�����f1���z-��\�?a���!��~�;K�~�{D_m3EmF^�f�L?��x��GX�-F���iL ��b_W_�(�j����	k�V�2��߸g�:��*�D=��y��.�}��k��f��X{��ޯ3T��!U#�٫�6�t�v��瓟�V���ϭhbV[��8�.Y: /���X��K�E�c��!���j@6�O{@K��/^ð��HX�	#ä4�¥z������΄�����ޏ��lM��U����3::�z���VqU;�
dNBݍ�}u�L�X�:��8�V$���*P��3�Q>ҰJ����)q�pc��J@7�Ss R�[�)��M��\؊�������Y�n�y�J��-�i�k��_i �T�_u�.���Т�365�>"jПr�����I�h��RӁW�X�Y�!:��m	��
��_ֶ<i���h>��&�'8���[m�K�C�&0����SbC�01�,�����5�x����꜒���E�ܙ�{92�y�s�V|4}�/��c�9��1ާ� ֘9Ot�0���:�EI+��� ~)ң &j �׮���q���G���u�6s�P�.?ͷ~A
D�p<����0S8M�-XSiw�_����c����gg8��, t�I8��u�ZNK��L��d��G��&��5�w@�t-��t�	b�.Y�o��]�1��Cύ4�i�2B����T�P��?`�e�-.G�c�m�|M�gt�\�l�;뮃�	��4��0�r56SxU+��Py &UȪ�'#1$���T�fc �etQ/���"[?+��di����Y'��*	eC�{�08(�l��?]���Tq^>�O~���k���j�0%���n�}p���_ ]�V�:H'�Y�F�wp�l�MSy:p��E�b$�]���J�B��gS��y^#�7e���۱8YfC���b`Y�
h0'޹�`��K1�R*�-a��&4��BR����?Ă��[~u�:���ҡ�y%��Ľ����\����0�fD������՝�U��dLke���F�6�_�YR]��P"7�h�ZĦ�&|C"-�K�$��R&{�{��GU��A��H���z�w�������p4�u���$�2��3���Wf~�
wK��Ϛ.&�?��Q��DR����u�����視s����
�tӱ,
3p�m	
��
0�F��86�!��;�֒N���
����RN�S�M:d�� O
JSh�Ҽ���/6��նmw��ѷ\W���������9Zgq\:��ޑ��kϹ˒zZq��-�	n��7^t�{+s,ɡ�hA�]7�+�XE��a�<�sp�4뫲���MMֺ�*��P�*oP*�6GQ�[r*9��!'�Ʃ�	D�s�c�'�Q�I�/�OW ����_��qo@�{XW0�=�z��<]�Hc�1j��d�x5lpQ��o�	�#,�7p��Y��XTj�D�ڬ���J�aw�;��tqL�?@4A�@��>G`@�:����ݒOo 7�E5�[q��TIZd��\,?Wеq^���)���
Q�W�n}�0�[6ovRT?g5S�
Lx+'m!��%dK�Ȇ;Q��ff�D���^i����j~;�F`��rǔ]�Y�5�%���Ϯ�5U�#��}d0�2��F%��Ӟ��(�.�H��n�j���>Ұ���3R���r���-�D���˟g��,��:<�n�<������,���Q�~��٦}P���R�H��r΢�LD���o	�|J)4�2��F2&��5�k�<���ѳ��H��`���	~�i0�. � �km ���f@h�d��X/j
X�X�Nڏף��5D&�{r�6���p[)�]�}�x�y�!z����ou����&_5O�tN�tIגxk�R���*N:Smc�����u��a}p(�Ñ�AT|� ����<Fչ4y���1F�"�W�ē�l4��#X��T^�l;���sԮ�K���gC��:�ʙ�iU�%��]f��.v�>�z�0���,���!0[¸~�ף3b���%�WN��3���	¶�.j5�0lB���4j�5���|l6�
(�.Dטz��g%QI#=�>bޢ�4�)#NXi*�;I�����7�|2
n�"�("Do����j>�e�����cP
(e̽��	�͵� �{fÁ���rck�!�V�b���0�Y[�:�j�>T����\j]1WH��9
��o���k��K�9b�s~/��sq7�_�Edh�ˆZ�%1�U�`����f6%�j�9E���v<ݩ�?'v/�¦�f�z���^����߾p�<�@��L���IU�?�X���d��E�mδ=�����A�N�b������(%�@�}�%[ �F�5R�YMä��J�i�/8�E�g�U+��C�������!�I�Zܿ;�&�.�F�e�L�sB��>�w�����ޡ���=�J���?���Q����M-�K���ǹ���h%��5����ngM��>�(wM���D�l��g�hO�Y�93\q�.P�aH:Z] �g��W�|��'�g�-�w��0�zHDGS�� /H�#N��Vs�8�EĲ��p�+@4*� ��w�^��f�)���ϸ$5h�{�b����ߒQ5_Zz����>p��,/� Vm4��i�B,u�V�Ǫ"��ѐ�v���2si�_����tU���
���C���"|C�,�q��25��Ӗ�����s}|ڱy:��{ܒ6 F���4.A���9)Qf�Ϳ<����|M���b�V�".�jmۅlg�nҷ�B�V�O��zx��Vd�-���)4o�u���,��Y%7�	�5�5 ���=���'�;Ǘ��l���8	���4m'�s.k^��-�z�0���z�ֿ��}։I���O!A�}93�V�8a�*o�8X��ђ��&��3��$�
�[v��T����h��e[���^r��_' u�x�R'���ȕ83"�Xž�N�	?)@�'�!B��C~d]������ʛ��q]�f42AK�#�ښX��0d�P)��%@7�{͹4�fZϰ̳�n�2�$	1m6��vޓ'&l��]b`R��<j�|*�ʴ��\Q�y7�<����v�^o�S�k�d�܃��eĕM#��7B�����Nn?᰿~+�O�s�d�Ub��Z{�O�&_��x����޹�GX�|�2�K�L�?�ou�imEK��O&h��T�Y�������O/`���Ț'm��	\��E ��m;.�3���v�ʸ��FҞ��CT���c��/��9.^��:��iȣ��臅�~�5����n�V��P����(,�aG�_�Sݘ��A��|���j�='j�B�#�� ZQ���iC�N�Y^��&�kI�5l3]ʡ�*^���f�e�I:��Ty����Eʨ�ڤ�Wc��އ�����{]����7�R�U���1��L�MZ"
�J���ᮥ����5o�t:������`.� \UMe��ӧ	0l�
�^�9/��$B�9$qB�xJ)E���a�'�KkƖAtij]Mn��12+�[H����I~B�lcNU_��QO�"��̢�ڬ����y�>w�I(�p~ڡ~Bk+��,RMaGev0	�L��J�N�����A�a�P��-zE��o�zf8%Ox���\�n���
@��� <J��H�j`!8�����ЎY���dOm�#�"5^VAW#�1�8"���.�3*?4���2���1�_�Q����QQ�Aq1$M����$��9ܽ?^=�k��r���)	��ҫ�Z$���:Ct�Q8��
L{��}p�3������9u��ݝm����ڡ�Hw�5K�>[ħR͎E����-g��d)of�&�H�U�J�t��	�{�E��R��͕ 	~��	~_<��z���\)��<�P)����!�vX5Ү�͚qs�t3r�)�]�9�2����}�+7����VH	I(&4,�{��!�����������vW_3�����P�ńS�Ƚ�0�k�W�_�~�1��7�a��Nd�E��L���9�_�4gm����#LH�����Ͳ��d��$q�#c�c�e�Wt���}L�HS��8v.��Z����WS�*QM�G�za�lqu;ry@i{.rL�|������d&:�>�q�Ybά����{�(婨���Q�.ĭ���1dԶ����R�u���{�tߣ*� �a�i����+���| �Cޫ���8��4y��ܜ�z�ЋT�i������E�uZ��_�q�n	�>E�d#����Ŧ��wg�ԗ���LW� ��~�P�O��{!2���,����샷Q��#;�S���*��<K�s�.7��[b�������n�5�6����{�Q?=��d�8;�P����|}9��O�\C���x�UK����T�^�qZl��zNsn_ާ�F
�Z2b��&
y�Wf��x|�
���/�r�%��F�-$ʚ.��z|�0U �͘e�,���
#"8iz��{A�}�<��H�5è۳%2�8�7��9�2�s�����V����-}�ڜg�~�*�rG�i�9i��K|���Z�RS�D�;&:�v� ,�v���~O��A�lႰ{����N4���XШ����� ��Vب�ӆ����M�3�e�1��7���W�"�yRs4�;V�4����K�r���r@�5���|C^�Ɲ��:c�BP�'���C"|f:��Э���ߚZl?��b�qv���vM	q�*�N�u�d,d��,�������..��Ï`i��R3�`�E�Gc�0�y�t/P��ow�.�BE�	v�8���sEq&�w�=()�Nn�����UO�����5P�X���d�_��K�[���N���e�����HZv��� ���}ѱj���S�*M�=쯦�G�M�t&>z5��HDڌ��F&����nj�R$ �8>/�
�c��n�� �&�f$��Gtf��xϦH�_�'Dm�9���&�_��|ևcMn��7ݻ�:��u�a�ÜpV��=�6�n��_�6�i�b�V(7��Q�P�S�	D��`�B}�*Q]���L��>\���!��/ڢy �� ����H��h;i���2wA��kW�'�3�E�1uaF �<miG#X��ߋ�w�4���Vd!Yi��*ɧl	��6�/��
�1���^>����3��L�O�1�ZjH�߄����jŲ`�0�N8�^6�j�9��p�ȋ-�E����RQ��MR��P���f|�h�:�$��f��޾�/m�hL�w_T�UޫP{@���"͡51��7��j�cz��	�d.Gh5���R�؃�����H���t֪�;����2���/vW����b{� ��K0f��,�|Un��l0�����3��%�T�G��ό�� ɰ��2ڎ[ʪ�G���?p?���@q�H��C��O��մ�RAi�hY�+ܣ�XM��g�c��J�:����6@�ll�tmm4��|uA�u���q[�2��:7��ATQ�Vt�k�b_q�g�m���U�Q��`���V#�S!��7hQ�R��}��uq��	 �����a
O��"lۈ.��wU0<�F��W��"�h|�^d�&�d��J�FQ�Zb%>�V���Roܩ$#��[+��L�p��Mi���<w�Ρ�ʣ�+�a� ��
���S:.:h�X(	+U�
Q���`��u���<��G���qB#Q�0w/f�W]��snG��A��B�Һ.,�����e������ɮ�h�\	��۰�[�����+��~ע�\5���LL��TIeb	-� � �{q�����Z�.HEH��	{_�C��TE�ą�v�s������5]p��řVJG�r�d7ܦ�w��
3���K�6���J1�z�����<Y�x�胈:ŉ��j�{�w.�O@�k�]�8�ԫrAE�� ߓ���v3�������ŕ����5f�W��tS�U�6;	���g����k)T=��k2{b!���ՙ#�+y|�è!h�N�Y����c����
c��x@a��٣��'��P$ҿ-e�\�
|"�q���h�����/"g��P����[)���j�v%+�D.�GM�HV�׿�yfH`��sNAXQb�$��iMc���d�����H�%�Yg㈿5'M
�Щ6�:��B�G�\o�o1t�/v��:�u'���d}��b�?�gyI.���qkFv�ʴ�@4H^��&~�-�޴���m���ڑ�e�9]iu���` ��� �Ls78�V�$��+f�����462����f_c�]��m���[\rk5u��v�p��N�(
$�����jٿ�����yx��+�㹩�����4跒�gV�t�D�M=j$��/���:�#!���NE���N��z�� s�h��6���v����j�׭|���)����c`�j�
�H
U�*��g�j����@	��F���OV=�ߛ$?����J�iOp��K]�1l8|���Mm��������u���e�j��kr�t������4� ����1CT���`��V��;;�?ﺪ׼�,�9�Ь���T�k�r�m���]=H�B���z�Oh#��[t��jh��]�(b^ �1P|u��8@����]<�njЦ(�G����xL���
RӘ��0���kKs�6�Ρ��������ǌ�DAΟ����]��Ź�b_zr���1���V�����!%����l��n��N����g�q}���.�70���V����Wd؉��i�z)��.��O��O z(����`���(�Kz��n�ʜ�\���ju�b�
���\)f�#�U�:�Җ7J,G�S6�����	ja1.��u{dhj;��K��)�u�XNd�֋�@cn�S�����[�YTX�K@��%�C���LX@\z{gAƲ�:{�|��YMB���j�_�%�;	�w>�s+���-���W¶�i��>�3�²�~݃���f��31g_�:�d������t�ů�׻q���]��F�������2���ԢKˬ�C�n��ѽ?	�&�W'��I�z�J��}�]�>��x�kZ*!�]da�����DN�Z�
�xէ^��G�x��ؘ�q"��g��DQ�r�}��}	�,g�x�o�g�����O� �clcXX\ ��[h�LC>s��m�/�Sb�ބJ�鋃+@�7���#�9�o�6X��D/�����%|cJ������g��
��M��'9'�O�	rr+w.��nѱ|X���s����)��s�Y��A^��ؿ���śt���wr����#9�}J�<4r�)!gZ,��xՀrY��ZQp����	N�|�8CkQ�&y�,kI�z�Hh�����k�NQ�G�5[�X�gh/i��nr�(��?�G@%�G0�����B{��$�Ny���y��oy�U�V���x;�VS���.7�]�T�ǭy	�64C�ەj���
������%\�kG��aA��&�3Nd��\\���_�	�&����g!Ц���Q*0���Y�q�K�ل�t�?��u�'�Pc�fl��P;5�}������H�&�.t+��s�,�q���?��pK�C��Ӕ��iO�c��Wf�D,Fl8�RB����O�'/z��%�M�����1�O�s;��)�l�Y:*$m����V�g�q]۲��X�m�#@��]5��o�-Y�p<�\�la:��+�{ �,�P��Z��C��=m��^�bn���?RcW"5��pQ��[�܇oo��Ӷ��T��O�՜�LXY����?�c�8�vZ����׬eT-X��d�KD஋�D�c�Фn]Z��v±GA5L :����ܐ�3LII���;ѩ�O�Z��Ҍ?�z���/� �+��,K�=�P��(����`&rM�G��w�,>�}*��4��;菼��n�X�#˟[|��(\�d2/��{���Sٍ.����X)(ȗ�K���f���$�I�%|L�Xu�ˑ�bm!�.R�9U�4��.Mvk�I�C��h���L�r���x(���Y7�+�F-ͦ���̀)�m��J��{gM<����¹�*;n�҉���V�Љ��+��߅G��i�?��\�}�J�Q�63ߦ��l�u)�������fs���}a��슔��i�,����[���[�32��/�ҧ��A�R��Fi[Iߖ`�B�g�l�!H�a�
J�s�y+�tʚߵ߂F��r�D}ۋ;pZ^�KL��K0�����p�p�-'�Ьj�Z�G[xux�Y-5N�kk�X,�ݣ%sie�~�E-�Epx���i����/�v�QQ�a����%�}s)ٸ��J����t�\��t��X;	�qjO��; ��z���l�����7��
o�ݙ%��ܑ�	�P>��vgv,s����cL�[-�_�hԺ�k�mp�8���J�)�+ޫk�0A�1�K*z9��7R��br�k

�H3o��]{��K��kB���!U8�Q_�K�3��|kv�A�N��76�i1�?�
�)�0��؃���Y\eɤ��c, Է�M�̐6�J�\��2����|�F�{J�GEz���FWR�_���^M���ߛ��`N?Ý��*K�E�3
zV8M9�	�|A���^�>�o�=���L�z-�u�)��/�[>�lJ�(&�Υ��������$Pۋ��.Ok�7�S��g������T�����͸����\����Mģ0�z#��np�k0��egR��m��~#���N)t��m�b�`�a�Q�4��jI��e��ʋ�e��0�A��=�zq*�X�v�r���1rM������I���1e�eE��!@�~���]YP]���S���X�����O��V���D&��~#�Ś�{.;��n�䓡Ty�V��AoXS`�'Z�/���-��{�~%��b�71h�(�el�Yк�m�䵹�������zj-��Iso��M�L����=��濇6������w6U��Dw�7GJ�"�ҭ��1�Uk�͢�����	d��֜|�at�l����,*�Za{�W�Qr�����زR�� c���p��p�?�J��q��0���D4�C��j��6���T�jб	_?/��r��W
���J������q>�e6�dy�6�ϕx4�I��b�A/L��{�P�3.��l�
����J�K�hH;��Δ@�G`�(�jm4���o �"�"XW\��S��F�xl����|��zP�󩡭�Y�;��y�D�u��O,:�'�{���ζO�u+���n_����q�e�F�ɭ�	��Kb ��4�J���yY�0Q0�?�hV�~�}��s$ UP*<�A[K����o�%3��
j�O$�<ÚG�+ G������w9�3�W�QLYک��H����E~]�kc����+bZ�S�L�#a�]�e	�����N*翯��Ȍ6����5����VG����z�����b��Dqgu�vb"&���i�Rʉ4;���{_�^W�"5Rdŋ�0=���r���rO�_;����o<L�6��1_h��b��1+��q8m�#X:t�at�R||��z�$�ge����	q���U'��گ��I��v�g��
ɪ�S�&�f�z�	�j�P xR��S���x͚ ���6�c>��l�s����$[n��}�Rn���=PRJ��1�c�(o܁1I�C�f;%�q��[�O>�C-�s�� $�8K�Kk����_E*��A�/�M_��RE�d����s@˵�F�DW־�yk0�o���P����$���]��_l�N��sYc��3eE�5�W�ya)�E=/�����Jd�(0����LH��C�7 ��T�/�^�d��m|2�V�9Ō�[��v_��0��8�l���h	 �^���;)#C�u�Ur��6��v#�T���wlg'W�X����|�x�c����7�)���;��tKn���*M�%�f�v�l�錢��w	Ê_f"c�i�y��A��-��p������T���u͗�#����|M��ew�ר�O1��^��J~+��#v�� �L��P��l�P8#�ry�c���������:a����T���G�V7(�����ϥ���&`+EU������1�G�5K�^	�����:����3x�tZ9�����K)[K��P[肆@�ʔ��5
X������t݉=�2�تH��fj�__nOz�E�|l��'��.%ܬ��l�FJ��~�Q��c��_{�0J^j�����LMZ�Gd�G9��ä�)�/�z�]_������g���׃�s<hz�\�?.�� �s�u�;k�h�q�oR��iLZq� 娸#AD����N�x
0��C���(˵�Wb�w�՞^0N�B��cީ):VaSʱd�>������MS5 �[�{HEf�������2�@PLz2Q�_i� �Ck��.R&�X=�?�<����>�KD�-ʓP9/�ʡ�Q�2�M"֍F�BH���T�ʧb��(�Z��'B#NE���Q>,]��#��|��[qNM[G�0.�>�ڒ#nuq��QVj�gU��q����e$�UlR	�f2�W^e��)���]珺�(�VC�c�:�Z�5$[5��ٓ�j�7�͒f�AJ�����{��k��Bz8��z1��k�2k��$�qbk}�jzkę�|:�ZX|v�Y��0��+7�8AX����Ф�q�Dh�Y5X+m��>�8�P�d�8��mB��w1qB�r�Uq�5�6?����zd�~�r=�B
��<$���h�����ƕ�)ğ�����$w��i6�����`�eY� v%��e(z#/�Oi@�n��K�"ͬr$껆�|�|.�ۜ��~|�������Ot-H+�R���)�
x����N:㤪y7K>o�MlZ�hjN�΀��Gu�Č��~PS��Q���P>�#����}�����4)���g#`9���%���E�%�Zc��/�e�YR"ey�p��#��,���6sU�=V�W�5Q��\��c�!R�[�X��%�h|�0�4��
����D��K�N0�%L��m��a*%��r�{��w����fR�LF��9���U��K������u��*ϹS�*��������S0:�O,׎T���ǧ"ZX��D�%�c[�6G*e
``3 �t�����ˬ{$"\
������5�{��р<#��)QM#��,:�
�ҜdU� ����9�ko�b���C�:��:Cv��F�N��@����HKU<���mOD@��-< ,4�P�;������{�{Ԟ�H�bO|�cU����}��ӔiF!՞&��z(����?�*�R	?�)�p)(��`���T�G��^�I�%yR�iӐ�A9�P�T#��ӄys�N�6f�ϐ�(����Ő�I�:�L��!����TG1�"�TNܖ�2e�H�!9��s�AT*5J�6�ɛ{p���F��x�ٝq;u�{3�3ǓI�@ ��e�:����Zߗ�rq���7�!�����ü�����u+���]3v�V}rcª����
��%�8&)�H��O�.��.$B��pn9���p���uS�6X��;1�*/6D9V�:*ZRD �&{�>�����<��G����&����z�N'5� �='cF�mh֣P}���{=!2/�>���A�`�B;DE�b��싕W�\7�h�m�Y;%'�Ce�0�*4�Av*m=4����-�]z�n��ӳb��Q�d��.�����D�u���@�>M�� �Z�ƎW��Ͱ
�#N~ipa_�8
��7)֖����&/�ݝ<z�2���HI�Q4��Y�|�첶�i�-�,d=R���$[VyvĘi���f�fWz_𳒴�PաJ���Z�/N�V�#��Rg��R�Z$|UZ�m<��2�#�g�5˃�Q)�>��vz�{4 ����E����H��ȥ�M8錚r9�3�:>`ӣ!W��]��k���k�r��M0�Mu,U��.w�"�P�'��Qrn�C��c�{ �]����3W�T�c�۝�_gh?!k��H1OgC|��?��{�	8rĶ��x�d��j�W?�ΔaG1���ɶ�fн����y� :���{�m2��VCD�e$�0�wN1K�������-#��t�ѕ�	K�if�{�o�3��-;�-�iZ ��ԁm`8$�*j   $L�8� ����
: ױ�g�    YZ