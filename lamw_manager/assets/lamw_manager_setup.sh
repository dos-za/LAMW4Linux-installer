#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="513182236"
MD5="300b92d4e741b622cb3ca171b23c2f00"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23324"
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
	echo Date of packaging: Fri Aug  6 23:38:35 -03 2021
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D��2�~����(*��&NfZ�k���� �3�z	���˺?{�a��E�4�c0鼦��/�_] �L]`�#�]���4u��ʤ��Oiv������1�y�95�H�w�������	D�A���!����_���S���{��3$L,[eZ�]�]��`�ȅn[��d�}�����c)��6��ر�x�ɘ�W�&��b�oS4�V�)� ��R�z`�=���	d�G�*U�����y��ę�]:��[y�'Wf'F0o͕�X����p��)R��s���[l��StԻ�I�m
~a��&'�
���7��jM�P��L�����kNj�n��k�K�Z��7����K�5�G��5�^̽�������FU���x���l�zRj�Z�z"�¼w-���8p�	X��o
 �"��1 �\j��@�9d���}Z�S|s7q���;J6��^4��3�>v&��,�/L�������	�Ъ��1��Y�7�����6�:y!(�"���}�<h�:�2"�d�)v��biI:{ZĲ�;�hK7s�˨�E���`7���~�[W��m")�*���6�9Xߗ��)� ���-`<,*�����F�)W�e�u�N�D뚠�^��č��y��cW�EeQS��÷�$5�3<�>�Q���M�)�(�e��(�K�(Ͳ�8d��*�w�%�߻ii�m	^�;ϑwTFi�t��8RW���6���AIb0�6/�.��?��'7�{�S��d"�Ԡ;�P�������F�ɥ�<;�l@�3�i��~L37��_x�WO��A�k��-�������:"#L�F��7]OUs��5�����҅>;��' �ܾLM�cO�/�s�"告�n)����ץ�A�b����w�!��^P�RM��������q�D<���ɽ���Ю��D�C4�h{��0�x��/��n�D��'���t.!�㮜����8y�%O�k�(.|�감�9x�;M}U��'���cU���$Q��
N���\��5���W	��?x��i���m�������Kj�hj�g\T�f��L�����Z��T���o����dv��z���,[ddx���(��Q����e!��ҫ�����{b9�uM)�w�N$cD>�j2� �Tx����\z��_,�R��@f������1x���	0���ѷ���V񖒒!�������h�3ߨ�o��Mթ�O{;r/q�N�|��F]襓��SQ�N ��xC�����)��r���ճf	�8Ub�&��S��a$|����F�L��S� ������2\/��0��ɼ6M�\�L�3#8���f^�ع�__|ԏ����ǀ�:Z�p؟�p��t�@F�� ���
���]�i�x/FԠ�O=�A�K��^�1�g#خq���Y80Ѩ���c"�QX��;�w��'O��?E2L��@��HB�GO%q(�ɧ焂��h�"J�h��i^����E6��a��"�.���/��|�s�.s��cH癨cK����<3���tK�K;`!�r� 4��A�s�I٬٘�́�uL��Z'�|�Y��`�������~���F�g���g<A�����K�9��χ!�",V�2dU2zQP���*-qV�x(�A�9��1����$�W�!U�E���!�l
kDQ>O��C�
��l�ܻ�g�/tr2u��U%��LX���68�Ffr��� 4V�L�
{G*0#����"��%7�(K�����R�Y�c˥�I����浅"�p����HUp�7h=e.���B�Vw�{u�8k�R9��}���p��*蟄�r��kv{Az��� <)��GR�]WL�ͤ���oJv�L�أ��F������}ӑ��p�gݓ,�I�9���N�������3X9jmzB�/Ֆ�)C5�2��̌��>SyU����������H��� a�aE��i����ъj�0䕜6:�/S	G�7\���Mc�͝|��ҧ��������6�ς��~#�Ɛ/K�X��/#ZȞW(���� �䶘�Nơ I�陴U�0��Rd�=���g}ށU]��r��pж�8�!Pg�&�������NT�� H\����0�A;�h��aV��(�8�����i��*%�H��7Rb��U�ԨoPi�, ���r�M/�Z8��z#C|�Q��a�y�72iM���N��$e"���L�l�E���3���(}LJ��|)?^�q �W��m�Z����Ǒ����?}���h���u��d���GX%�؈�6��Awd�����k��Osm�Ƿ��H�E�(���_�~�e�7 �	yG�N�t��8p��[�*,�`uU_��R��G'K�RJJ��^�KVja���'Vf|�p��Hq&���-͕�����10O�P'��s}�ˬ��"-.
��R�����m�����*cD���>
�`ܰ-����aũHG����t,�X>����~9���h��ǆl3]V�f����Y�����p^�W��=��'ӕ
��G��ݡE�"$uQ@(��װwaW��&��>���~����pӄT�
^:�$u-L4
Ջ0�݈��uLd�ђ�2�'�.��Vē�_��ښj����A5�Ąs:��H!��am9@m%�S~ʢ̎����ǋ�p������c�s��p�g���A�&�KL�T�?���S�!�ְ
���g�:���Ԙ��g@���!Tf���Յ���}4�����h4�#�|b� m78L��y�5h��Y
ʛ�Z�#�����*��+�A��KF>Yˈ)-�N2�b7\�r���4Ĉ�	>g���m�s� 4�{r$m4�f��c��0
�T}e55to�-�#����\��كRUk�T�Q)ɿvX2C�b��7��Sᬖ��c�N)�P���t�?�a�X�t�!�*��E��>Q
�r� ���	�ey��*��zU^(o'�"��.��`���I������+���Õ$�ɻ5�%��Lr�-��C�FM9M�a^��Gps��sx9M�N�� oGB<r1�;��(&�=JȔ2�[���q�| ���V%p��?�A��v¬߸���
�������Y��Q�=��{��=X�K�|v
C���!$O���|�Ε3�\"w����^R=�V������J�ё�er�F�;yD�cz�lUJ�S١U�*"ud�XF�)>�ʿ�`�]�D���k�fo�)-�Q?چ�CO�0D=�d�c��:�QA��(����g_��1��k7���}���E6�U\:M�&�.M�A#�[�Y�
��Kc�!�xE�ˠaȌu������J������_��"�@C�̷�AO)�ӎ-���n9	�q��>�'q `PG�յ|������:��8ၐ�;�b�!�Y�EͰ�m���L#�Q��fH���L�l�ݭh+�p���gN~TLE�)�y|V���}g��z�0�Po�{��Iį�vg���cM���c�2��9�Gj�\m�J���t��a�s�;�e\*��܅A-�Bz��=I�\,1}���?8�8.�Y�p�k8�2����T��@�ֽS��2+�E�{�W�] R�*.i����ΖM�~��"��a��(H:[$"�����%������щ�L�Q�W�4_,,C3>�"\H6sd��֓�Yr�[��M��}��e�@��E��J�.7��SBd�W��t��w���W��н�I���z���a��-$�4����0>���9��|���!q�������OI`܂k���v',O�����#vɖ���D�g<LG��<2��!J�?4$�����$Ms"hNs��R���KN��u��K�����q�aU���-72�dD�U�\�"r�3gI�n�#�[���_�=���3�M�R��j�^��8B���(��d���2n�P�	P+I��L����4�����͡�������:]�b��O����]���(�ӕ+H�̃#�M<J`W��-D�0U8a�\ߔ(˓�"�ї�C���T�jݗ�7�&��a�N�4J`g*!��f5���T�����$5�Rĩi�@5���B��(������ӭ�`.��\�3	���O�����1��DCl*S��|�AN��{���7!�FtN��ޓI]�UB!8�[�4�'��l�����b���=eF��Y�����H1Q(���ݒ�*�-���:�Y�w��`g�#ԅ|�{����!�9���xV��T�E��aP8s�;e�?N�sˎ++3�l!])k�f9�'��"S�/�SM���ͭ,�����߸SD�N�aCMG�ܴ�Ή,��t�#�)?����m��_���?��4�'2�TY�O���eB?m��P�&3ׂ�]H��W|:hʯ��F�H�s���T~A!�<�'}� �˺a,�������N�.��
;��Ѓ���lw�{G�D;5	IV��f^�`�߿D�5���gd�x�:H^,�wDG��%�N`��g�6���FΙ����a���τ��O���UVv :�b�m�}ҧM_�==�މW8ыd��jE�5���SP�Fwރ�K��� �|lZg�@�� ��=��YY��YZ�`y�g1ț#�z�kF�l��g{XpD$�dۛ��<06��Pb����0�)A��n�A��ɔ��b��Ϧ���\�V'��9�nz�|uϵ�[)lR%�˲F�M�?d<|��G�9��SԀ�צ�*��Ѿ���hk��&-٫�b��b��f�͚��A>�
�'eu�����JK�\�.K0����_���������y?�;��k�02 ,�1?x�k�8��.�.H����r��t�m�k#CO��_� 'T-Ё�P���gO�Z��~A��:����ɲ��p�a`��S�i�2rwCJ+���������!�*�EJ�c([��T筜��P��<�`\��f��������P����2}F�牭I�b倗�*%�d(򿧗2n�z����}�}��A�~M�>h�K"r:+Z�L[�!��cs8@��Q�d��8A���+�1y�&
�6a���3��T�E�s�3�B���E���Jf�5~&	cW~[����Ή =j�?�0��r�9�z=oJ�X��&_�������A�@�m[c�w|8��0;�LQ&�0>nO�d�_�1'aVw�@��$�{���ܼ��"#��s�ҧ��ɓ�)�
�~�^������􃢈��0	���T���#`����ĸ﹬�����@�5�3װK�t�	�%��a!���]/��^Lj��Cq��n�p(-n�8���j�<,Z�+�ג��b���ڙ왱Z���<������F��96�J5{�(�ʥ�N��ټ�g�O�;������$�N��������Z�|���ϭE����mn,��(��i�@y=jA�)���|���[��vL{g<ΆH��A<hƤ��9�1�s���A�^�$l�O��){�Ü����:�^��A���0���徐�na�n�V:q��Bo�s<�e%9��y��c���P�O�94��o���-�a+6C�f$��}&˓XFH�vn�A!��ֵ5���q��h �ԑJ>VTI�67v�\@S߻�(���x���t�A�� x��{?ʻ`� V�y/����!{ �n]˚H_AF��I� ��I�s��t킻��J�[Y�!C�q?� j5Mx���+�j6T-�2:�2W't!��j�R����/&��4:�vh�j|!I]��H��_�\/������meobHC(��O�)��rrk�r��:�Ne*φ8�*��y.����g�ta��,X�z6B���f��įv#�F-�%�-	{^�b�L5�\���d�CI�y��_��Z��p��g;1��CU�RsB�VLf��e!�#�>#�g�B\���5�2'�1�S���j	1(����>*&�*��8���ŀ���cFX2Nhoj��Y��������#�kC0�#R���ݜN�N�ɥ�cKpb\g/��a�v42¶����h���*�J�q�h�P=����r�YR���}��R^axj��zM�wy����e1AF��&K��/!����)�$�����QҨ�7kK��ߝyΖ�-h�F�ٚ�r��"ޢ�B��x�?�i]��צi�|�ǣ�3�^����zJ��^��Xq�טn����	�K�o��nb�Y�!�I��,�t��)�,�Q�w�@�C9�wJ1�E��q��Yx�X��?�-��M��4��"�2��ש���(�,Tv<�������"T�n����y��b�}#�@�`�OѨB���z���7X���`+�U3$�c�A����uy��b[;	"��;-2��;��fk��/f���l�zIG��g��-��=d~AU��V��8��!� ��]�L�cA�<���t��9���8��
�S����~�_c{����ov��o�ID,��W�	.���H�c�iGVIH�a�oא,m�z9�o(��a�}h|ġv�O����MP����+~�ͅ���}�x.�A�C�)���k^�J���·��
w�_7���n�pXR������#8� �*�.g����aA��Yy_��.���^0V�X��,��ږ�n�<f�F۴�[��}�0A%}\��r�TG�KJG73&*5��m����,U������R)u�b�_�`B�*��l�� �Yɱ`P�$S�h\�	~�E*4�ț��l���(Lw3k��q�	�Gg�5����D�֪~��`�v� @֌S�.�9��̣	��/�i�s�^z0g}�#��g:�A����Y���Ux�h#��+41�}
E2h���5��5(�H�̈́T
G�/F��H[y X���|Yr�YW�A�Oq��u) O܎�w��Nl�#7p�{[��'X�n�T��%���&��D{H�5SH	�LN��aI�>�a��z��q�������b�����Gmb�-�,HR*N��)�-`� ��w����8{&cv&Hʿ���|��
@�����������RWþ�p��j<�؇�m��b��X@���c�a���'�?�J8g��������N޼���ub��%(���g��k��H&���C��=MC�ڗ���^L\�<gu�bZ�6F�?��Y�_�����D3�'��,]n.5�'rݷ
�X�#�f��B'''�ɋ���)�����������N�Rc�YY�?p`B(����]W9R�Z-���S"���꓄��=`š���͍����2U%�}���s��c�{h"cTzE�1ŷaG�Ԗ1鸖)���6�q{]�����@~�hZ��	���^��7c���Pw���[��>���,���ߓ���[��?@��9+}Ѽ(���Ґ��37�F�m�q��b�gEf0��j��;�J�|�C|�	��1��5w:�����,�����۫*�Il��*���y���~�ri%d*|?���&9[L�lC��g���)7�
�rONI&��#	)�g�̹4�5I'�B�V�X:EsWNN��g�*��p��W���I��,�+׬J
���1d�(�C)Up/��j7;���ǀ(��GLF�pam>Xl/�K�B�ΐa/gl��6ZK����-��s4Ѵk"v�v-���[�r��SS�\Z�/��W���#C�����|���'�֗���n�G�۳��;����ϻ���V��و����>�I�|T��͗�������~���=:�q��F	i�
ܨt�V�}`U�`G�j`c�CÏ�9�R�`Lu�l)ҙ>2'L�EwAڔ�K�ԯr�7��#h��2�6�h �X]��AHM�Ɛ�ۜ&�]`vK��Y�)v��wR����rG��+|��?�ށT�?A�9�R�TX�� r��!��x���k�f ǧ������wD�p/N�;�E��xyk��t���{����3�N�"��14{�Ǿ�Z���YE���c*t��]�CaӼ-!����*��v�D�����.^�=O/�8�"������������T���l�{LVt����-$�ɉ,�V��&�(� zr9W�Q�D'��f�`�]�ǒ�klDV�vP�$m����T�t�����)�&q��j�9�� $�<Ij��yY��F��GQ���2�?	���"��p�6�$�\r�pzF�k���ӥ���J�3�ղ+e�Ϟ~�N?mF�=={�����A��"<Jf6`���/pz{��VQ[�" ��H@p�JH���v,����G�o�"#s\FҚ�~��	)��3��d�<�@�����[B@ʰ��4�a9xG�iC(�!�B�l�AQ!,E���We����(2<]+��B�E}�^}��k��7��I�� +���*�B
%0 �t� Nt7���L?�R�թ%���%[��ӯ�3Q�gls ��̟�=t��-N��'(ά0��@u��(�		YvPr�-�Œ��dg�����������7$��u������*q$we�;/�|��7��|�@V:�@�|'�"�,z����0zm�j-����z�����<ʂ�d<���O��P�_k�M��H�!�E���^@w�@Х)�vl-��*�n}p~'+��$���tn�M� ,�"ö{L��Q`�P]
!����&����>�m[0�tB
�9�9�{
�����A�{DW���B�vQY��Vf�Q]�Dg��=�e��e5�ö�ԑ������8>	[͂"��dփ�K��o���Tމ�w��<tH)å���I4���,ݥ���-�$f�ʦM�����*t��N�u��p�.Ge"�p�&�xW��#��Sf_� ����X�<*$���f����(�3���N@�A�D�����"
L)#v�������c	O2���P��w:m�������5�M�� �[��	Ic�c�s��J:Btp�e��+��k�`�Ѐ��BK����^��b����Yf�W*E�{If�|�V(8��բ9�2+L��G�{d�i�r�[�J?�?N�g֤t�'�}�����Cې���ܡ���W��M#6w}U3e<���~ҳ��Z_*JJY*�Tc/-� b,j|h?��፡�[�u��6 �ZNuA�������I��П��7�p�f�OH�L��3elE��a��m(�g��S*�7�v��YB��8�f�<�ho�	�-���ͷ��LX;���!���^TO�猪��Jڶ�T�*�X��*r�nM���:�\kuqЋ�@w|`RBm :x�{H�d��Å4���r���48���Ơ�)p�y�ɈԜi�0��o���ku��|�� �O���J��|'驵h�pox�m�hiQ���I;���i2�*A�/Ւ֑�PX�z�����6��G���02w�0�(7c˪]�$1y��Ы��!���F�i!���\�g����#ݼ��|y���.��]^=�D��k�.c����_h�`w^��
��vdo�:��0����v�8 �?�d!5 G��cpݥP%��Tq(:��FY��>;�<�6�.s�nM�<�'��ݗ����i�?NY5�R��aL}R��k�;��f�Z�y$��i�k���+l��%l��:�5��@WT �$@RӖ��x�E.0#�h�S�%D	�=nmq+?���*��KT�!N�V���tg�����R�D�J���Lg	����k����7�|��\�[.]��sH@b.�%#5�M�L
�S������}	ކ�jh-�Ak����O�����M�2nL����Ǡ���W	E���n5�;��~��x�	J�&��4%;*oVC��tO�� *>y�Z*H�	�� jp�?6 pwo/�?[��y�������Z����
�vҵ�w^X�<DX(�I:W���|]�AV�J��B���-r�;R�
�U�E HQK!�4;7�a �@���R�N��q���y��%��pZ�^�;���֤�ZA�#Z��sޕP3$�Wt`�r[�/S����>��='��B���`�E_a�x-h>B3�:����R� �\��7���8~�u�<���y�xH}4i�p�"A��Q��TW�,���˻�k����:jd�tv��Ϩ3��ߕ�F��&=>��=°�w�An�O�e+	���.�����Ȅ($���C<��}��.������[��&�(W���K�քf	�����E���'�I���ܒќ�W��%�:����+$������F���c��1�F��S��eE6,ѼͱKR����K�l�"���ve;;�ZXSC����yYJ���3��J��Z"�мsMA�ܣH0k-�����T@��S���NT����n ���I�S��a.[��To��Ǐ�T�38�"ڀ�Y�0�����8�94�*�"ZD� Xs)6�F��J'x~{���B'b�c��֫�L����H�1d^n���2 Q3\sۄ���'��G�~�ZH#_H�#��?Q1�x��ȽqO�����"��KY_�#�e@��k�$�I0�� <�j ���� �B�R�Lf���(O�]WBt�f|Z-��{�aGH��]�p�������NҔz�u��%gϩ̗����88G��__�Q�hI�
IU��CF�ݑ	Gd�lI+�;@�~2v�/������ϥ��%<1�G��>��]�ؑ曏=O5 �D�3.S�՝����v��/� d	�������-~���o��a��{��Eb?4]��pMf�c|�`�U	�1.�J��6�	H���\����&X�?Q7b�	���2򜛟Zx��#�)�b�ni�u֑8��
�rIx]O�!����*��,~#�1�/(-�ɺ �=�v���� �f����e&�x�����d�a���k�]�0(ؙ&PXC����ڬ?	v2}��A�:�n0B�����/��t��r����z
3j��*I�DB|"�ԓ���H�Lx�З:(���R^�\M�gs�9jK��!�z��RE�����8¥E�=N�E���](�|VRj��y����[ ��0�&f��4 u��Me�45�X�����I�x#9c^���?���Af$�M����F�>.*�R2P��n ��y��F��듔�t4�I�Kߥ��Y�����׬t�;b_��+0EY�ʘ�������}(L��ڰS�SXgm�6-�	k@7�z�;$o�ؘY�Au�O���a���s)���� ����W���WMAA_c���E��N�o=N��yvHk�0�M�����:L7X_$�<[T������U�����m!`+>���'l�vo;3-���i\� u���<�c��~y�s�rL%�P��`]s�Xv<����3Έm�a3���ѯ�p��#֛�4tl���8v�"~�ً��i'vA3�V�P���G��d`aGS�JJ����R��"�頻+��meǕ�������z�5y��~^k��R�P��u5��F�8�n�zC����@t�hAkQ����нZB|�E�guN2�f�oI�1�^�^~��g�p���a,^=(z��G�w�� W�W���=��;�F��D������H�'Ѻ �y	�E��D�T���+�E�܉�4^aI ���M�ϮKs�O�lXQ�D��E��
�QdK�O"�R֓�y����|[�&�1��
��w�8F��NV�5��/h�(:%e%���I�����v���w��*�oS��U> ����k�'�Lw�`Àd�4�|w��0�_�\�Pg�j�3y1IT��ɾ���ڊH�~�J��1�:���e[i��&�H�fb{Ɓ���$5{�s?�����M��>�Q�(�T���L��o�3�y|��_`��;��5޴�y+B�1�0���;��QnF��J�=z��̍�fb���g�.�9�ձ^e$!2RG-�Pڒ�D�#p[�#�J��2#���F�Wv����>�&tiۜ�Q��cg�r}X�Y:N�	~���qc%�Rs�(���@��X�ӆZ���A9p3�/��C���p{a���P���"TA�ThG�,`��̆&�N��\f���-L��,�:~ƾ��L�"Ԃ`��札!1bK�+��v�d�r|��`�i{�Z�"�1
Z����I�!&*�^�rV����P`��~�kR���F1p�P��?W�ˍw#��_/a�I��l�ne�f#���|xzk���<��� QLa�{�s�f$����Ǎ-L�j�4��)G���lC��紱�Ρ��׋�Y�l��E�zG�u���*5��d}�F�Wv�����||��*P�8���}��|�w�R��i�l�9�S��z\/���$�̺v��V�&;��[�������=G��u�=�c��IyRm���jp/��j9��)Ƴ��OUxĭS]�!]�%��ErYE�"�����%k�:-�x���	Ul܉�;Fێ`��'��wRJ��5�ж�:65"�HM��������k�j��-\��<o�43�ÿ8���Z��E��q �jX��z�#}���i�V��J_�N|O�Qc���p���t�9`�6�(�u��o��?<��y*2�>��=9����n4CL�)�����-�O���_��&��:�
�����o���E
���(JVN��Z72�:~賿Ӆ>N~�_/7��(m���<����C�w2���ڗ��;���Mo��G�b� �_ס�kJ���6i�f���PzÉ�e�Tw�8�2�����L9"�-����d�I��n��yY�9���DSX��=���c��.'��x��Qw[i��	�{���K{w����%�"66���90�ޏ0ø��wAi����d�;��c5�Ø5}��A��[\�nV8��(! ��b�Խ{O�R�cmIl N�v���&쳧�**���g�ߛ�0]��;�>�9%-��`닦-F6��h��%Q�r�| ��� O���d��g~�m����HV�6��D��7��h�V��ˤ�O;?�e���n5KA]f�>]���-�Ǎ���O�=�b�A!>2���˿�0�3����;� W�#��KU�&c�_��"�t3�h��rB���Ω���9�K����)���$����ҥJMv;�A���h�����C��[4����F�����2U,����+��~�����.��9Vg��	��p�_u+��R�e7�կ��1���KD�n��/���g���׮��Ӣ*q�loPn=&�8h�v�����:N��/�_���g�d�l��iz��������U�����ƞ�U��;�`���rEUw�f�I�U@0 F�z������^_d�U]����l���j5���Z�*�I�;<�6/NHP�˚�hd�t�p�D�&\�mg����*�ՔdO�6����XD�7���G�aYz���u>B�H;�=8�`��1vs�ݱd��  ��a�i/�w��HF��׹b���>(�~a��;c��2�Ci�O��q�tb,(r�G���ZI �;�Ԅfi�;ڬ�x�:���P��_|W�>>4k�[6�t(`����g��S� ��106����ݏ>+pz��G.<&F	����ZA�������su�`�u��^s��ٛ�ܧӁ3�հ���������"H�hS�(����-����u<O�qZhj.W��#�a!�8�L��S����G��l��j��~
cRS&��eH����;����:�����h�Wx���V�������aWMlƵ�F�y����}�}D+�@WZ�����"��/QALT[��L��)�#�H��B���k�������}CģJ�3�Ż2����E�GAс���IF`{��LRA���6��'w�B��c+6����@��
���^A���j��XI�;a��"��+��S̀Բj��_�Jt�*�%μ��R�ou��q9q�"��g	Mn�)�T�;¢e�^�#1�N��^z����Ǽkq�a�����+��&�����`u�}L=�w�P��:w/�L ���3w��]M� �뒤kwc���X�#0o��tz��.������O�_��ZEa���e��H:���\C��Iu
�i�~������^IK��S�8N�3椃TE�w�B?�(���ig�0܌�`��!s��%�'z"� B�s�]�c�,��r�e��9��?� $�ޔ�3Vb�I�c������_�R�[VRui�i�׳L(�O��L�z?��`=^`�hf��q�~A����px��s�4D@N���
"]�I@�
]��Yf���S��pQ�qĀ��/���<��E=���V�̡�"g�V�~΁��7���л�!|�l���S ���Lj�\uwr�\��Ǆ�WF�>�6@s�?�h^��'�'Y��,�u���l�5�X_I�����b}�+X&}ڟ�X{�G��,R�!�g�(1��
X�.^��Vԓ_�4=§��]�Ty�:���إm�o�v���bf�S�î��1�	�?�iQ���3wGf����'�LP -~#�E��咯���I8E-OaA,1���`}%��I���P^���/�-�[����ڂ���lh�� m��V9�WLlӤ��T�r$6IIש�x��E�$n�Q���UBw��%��s�C
E���vy9����;龎��Eb�wHp@�YAN�6��a|�(C��Jg׵�e�Bï��fh��7�CG1Һ��x�]��d�㣇��{��4>z�_(��n�e���,�4,�9���e>�!3����-vm=)��\��f���Q��@m���]�>���L�hL9_)x��C,��FK��|���/��Fo�6��T��ž\�{�L(����f�=��7�lX$C	�v^!^$W�m3}�1���t��� ������w�K>'��˽�/H��.�5�<�O�(5	� �7�H�WxgV�6bL��I��)>A$�݅o�XW��,�]�4)�_�� ��A�b�.��"gS�����|*��l�+yo�����|@]|5��r��Mؗ���<s�B��o� �Ckt�'�<nO��� ���K'�(}�b7��^�N�Yp�7�.OH��]���o��ϝ�I�y{�F&�>2�zX�X�%uϭ�`�RӲs�u!K�[�?X��ETQiY��G -5�o��5�WbvK�#w�����Ҁ��n�6��R�-x�B���`���O�#�����J��r:���ÈE6)��������8��?��l �"�����w�z�_�|�)8'm�z��k�����齩��R�P��so��~��"h�0f�zu}�w���P�A����$�Q�5r��� x�bݱ�'T���j�|'����O���P�����R�RW�n��^���mw����S�[ Ub�$���6&�5*�}�C[@�y`�F��`S"'�A�À�����R��KЋ[=Q�)(!_��V��`3�dn�ë:��6���h�n^��n���ɻ3+��1�$����烊Fe$�2JͥI�/��V���R�B�$�e�4]���<f���Ӷ3��N�����?�u��n.�q�f�P�2S%��%Π�'|̤�����֪�F�ϱ��9p�n�eҥ��{Q�ۤt(��+e���xY���������E���|��aG@��ZZeb�����d��,�&M{�[���z�C.p	�����,Z]n�X}k�Nl�	(긔����������}���O&0I�_,�<i��&"���^*�!0��
M�.�+b@��sdۖF�����]O����zJձf�(�@�
C'��0au���87�U���`$��?���s��Y������V�՜�~���_�¯]�җ�G��53��"��GA�6ݵʂ ������`�Z�qv��x�CQצ�/i�Kl'��+�m��������M��D`�'��1��p�KI6ur�t��d���ʫ�t�h�٧rƃ9!��o�#�Ň*��U�����(�����R��!��ǵO�]��%o�vZ�"{�@2�ݽ�t�q.�
8���:ž6��w� Ҝ�����d�.���.���+�|��7G��;4�d
�(�T�u��g]H���3m�@+�G �HSx��.�Ei�Z��ĚX��>�Bl�'�k�wB��{8 ��;].����g�V�Tk^k����Ff�7���(�%=��4X�';� ��lŐ����� -��#8�����e�Ӛ~�B� e�L=:&96��P���!dbck�JS��X���@�c�O�#���<? �6��o���RNl�Œ��{(�������}���U��QT��04]�K��oؙ���A�tGC@=q.Џ(��!K���?��a���]���FxO��Uo�]0����h8���E�C �A͡���֬�^OD��u<^�)@��S�;�U�����B6�/p��E�.�n�)����@�hEYP(��M�@)�O�`�R������4��Ϛf*��Χ��$��1�U�p�\د|:�����|����ދ�WC���b�.�Jң�I�q��1���F�_�၍�#�������K?X�)o���q7w��!���GB�~´a)#>o1a�k^~�fKi��`lAµ�]��O$�)��5�Δ�{?P_n�R��qܴkv�U��=�����X��St��^P"���5�{#r�I�4�5P��	�\.��*K�"�e��{��>�=�.�`:��U�!*�o���/S7n��=L����BL}����h���]a������1.5_�5�+�)@`� ���<�-���[�j�Z��L��;��WI������ӭ&���E�\�x(�D�Y�K�������BI2�_����o��l$�]Y�w�q]��y�A$[ǉnB����6�����-�Im��q��S�. k%Jڹu�-6
���,�I�Qw8i���؈1����)�����h����+�2J3gη�'�K���eb1��7`�f!�){�{o�s$�^����!t8�Wx)�F�.)i �7VoZ���!��=n�'�����o��K4��@���}�@�^#8�l�d�L�	���W���c��_M�����ÇI�k�м�
�d��4e �Fƒ]c%�H�������&�l�7���3r��S���"�g+��~���8}�f^�i�{���ñu��^�?��qN�z��xD�E����t���{��u�\�O����φ�p���/S��yS�XM��u{��C#�N�I���`�<��;�</���r���1� A��1�t���B_��� 4j���k5ζ��^��@��8=�W�� ����e� ��Izf�����Y�o�JO��R��ǈQMD���h����_	ɇ��䊡_�ڊ���QΔ�;XJV)q�\���C�����Q��ە�� ���-\<�����;.�]�����.z��[��7��ť�L{	y��T*�fG�_�4��!��s!98�X�F��u�G���#��*?�Ѧ��˶W�=l�h�Ȱ�\@C���㻈ic�?0�=4�Øh�%���3W�n������ݭ[G�@P���5�"S�0�#�Ab��p�Kt�'�؃!|�)��i�.�N��k?�Z�"+�krs��SPKH�����C�f����$ߧ����;E/�雳��3L�}m.�WSNf���-���A����x�r�G����\��c��+������	cg�كY�|��:N�Wh�2��F��ױ~��h��*C��j��_�l��֑�����FL�ڱA�ܷ�4������)��e�{�c��Nz~�7 ���y��;�\��0�H��	���HKz�����%r�]�|a��t�͢�s�e�!�	�'�oɍ��]|�����<-`��)�[�Q�J��u2^�!ˏE�b'�v �p���l���Y"#���,�ov t)��m���R �e)�&��c+���oJa]vlJ�[�n��#`T�: :*=��Z~e����]o�p�P����k���=�F���!�ϑ���W����(�.Fɓ����0��O��C	�1VLc�j^�ل-Q�P.%O�vh� �l�3=85���sˮ�.���/F��B��ରc-�����>f�{��sq�C�*�~jy�H�1�D��!�Z|����3u����1�uM�~2K���A'Ń��{�Z��P����z�F9N��~t���8?_X�ە���=�,������}b�|s<`�B	��3��߸���(H�M��e��X�9���a3%�	{��CM�%�I5%5
��\����(O.���A�b�DM��]p�w9��v~����հ��|�;��ᣭ]�ΆCg��Z~UZ�`��.@��E)���hǸ��FU�%����C�A4sx�4<x~�����3o#��u؊�Ch���'/^�ϝL�,���9h��'\���W';���!�c�SЇ\��0�����SD:hN.�-.�'t�M>��S��C�Ԗ�&�]d��� y��v���J�VcJ���xk'U7M�����q�|0�b7�&��n�+��ĀZ=M����'��si:�[A�I��1�\fU�B��׸-���7���y�n�CK}�yH��Ϯ|d�c9�u�a��~��L�Ӊ���ڑ�	��5��D�{��{z����R��y��IP_S����bR���?47���HGz�(�j��a�������!�&�ѴG]����M����Xl�D��˃O���8�h>�W1я���B�[AnJ��^P]�ݠ�v��U������cx=�Aψ�"k#�<�Yn/i��h�~bl��������n6_�U��8���~a7K�D�?��j`(�"�K��p�t���$�����Cz�#*�.����J&<��d]�_��"�ד�t1�n�����]���t��!�݊ubO��J͜Q�cJi���7s��"M���A��x��=p%�˵�vx�v��tw�HȃB}��ZD�Ɛ<��uo���g�n�
G���o���?����ΨE�Y�����S�lK�k���k����N�y";�|���/�_K����G���r�5
�|+��|��_����Bg(�4F�����ֳ�>cV�z��یκ���r}�T�J)��rB�}��! ��N�J�ν�̾�re���-4B���x���p6j��/�".T����Lk���?o�0ٲ��?�wAg� �\?훿��B���F{״�=z�[���,���tG�D�\�*L[nl���M��X�M|�2�<��O�"�"���\2#�1�&�܌쇵�F5`-ɍ�FO��#�%p҃�<֚���;������jB�?T/�^)��xF��Y�͟��z�r�L'���ׇ��>w�j�qc�ǧ����=)D#����!>NxFu����UR?v�Uv7�Ŵ���8�㕂��zyG��0~����M�DN� �R��x=�zm�;�-%���l��M��k�KmX�-2��%������%[J%N.t�N�9;j�>���k&ѧ����ɡW�wj�2&#*~km)����2��S�e��Ʌ)���V����g��:�M����7mO��_����Y��--���&�=q	���_a
�@HO�"��Eq���t�� ���b�։@B����O�_<yK$�C����N�۝Q�er�oQHE+�1֬�� ��BIQ!�5�KK���Q���c�(߼�7��SF���� �]�FO(�� �kNi��_������}�q,+�#"���q�5�@�S�٩���B�	E�)�ܐ�t=�Щwf �����X��s�ꯩI�;��iT�<{��?����+���&%��J�_�q��Ο�R��43�V�(a��[bB�3IT�≯X�G��a�� ���u����9>김>��5[�\z�[r��DAY�Q�&tQ��	}�e�m�$���L�"��Ȯ��������K�v������t����J�}-��{��
:p3C� �r��d�����:��P"��V�H#����i�Ñ��M)�@�1�념��\7�d%����4����2�/Y�������~�����or���m�z��]��ӋC�L��jZ�!�Dݾ�I`m�1{"8��؂���<~!,��+�0F��_��k����������_Z�1ÚZ9AыL��H2�:�}0j^� jP���Sx��޾�^�E�LV�����a\dY9^��,�kL,�Rŀ���P�_�5���Z�΍�,��Rj����-�ſ���f}rAN�ȖLM,hO�
Y���4I���=o�!�'�P��O�^��G�I]�3#�)O�t6�;S��WJ��ꤴ������N6_$ F�+n��P��\ɤ���Ҳ:|�T]:��z7���4��Ά��e'�)�5�8�˰# �2��P��0�H ���P�/�@����4M�,	"�KM��(I�K �-,SʣE�'���ر`���v_�1���>k�ƻa�a�M|)vN7#���ҿ�^:�T��ܺ��B�Ņ�" :ǉK3�*Y��j�.-	�i����Ӛa��	����4�c��Ğ�5��;a��Q��&��yO#�&��K\Gm�'@�ݛ���6������6n	�nt7�`�׃f���2�ݝ���v�$��4׻9������OϮt9��rS���b����x�%I�S'*��7F�~�;u67�M�֟���qwű2�g�Y�OW�ӢX\�hZ���Z*$lU����T�i�)�?[�����/��<�vs��Vc�$(W+
��?|>����y�H�1��T�}�d�E<ʐ�Q{��ިiX��IFUF��הfV�&]"�q�V��;p	�tA%��g~�mu�6��$L>�r�>w���M.۲
�Q'93��|�Ǽ��z=c��nI�ӈ(��ZQ��!#%f��4s����OS���+�����υ���=#I4��ʃ3�@�A�Bx>+V�����Y�Ep7�2ې��x�:����J�h!*͆Z^��
��ճ8[f39w?�\mK�C���I�_�LD?����++\���s�X�5�]�#h�<	6a
�Ŕ��;�T�A�<����υ���׉�8��'�sG��\D��}�M�9����|�&\o�������<�X��w8rp�Z��M^U�3�)f�(>s/��b`�eP~����r��n8TJ�LF��y7x�|,��5*�	ٶ�]��l�|"
ۃ���h!$�x�ռш3pST�
e�o����h��	�[�o��VG��WnM�Q��wY��Ð�l:���73������&�m<+�4�_��Ϻ�(+�����%]����V�G�	�&����w]Bt����SV�ݕ<�p�c���:��-��ɞ��x���~���ƔMM�.{[�z3���MT�-�}����?���/r�x���I|�tˌC��,�#�Z��Z�>�G�|��u����Zڟ�4�Z�@�S	��Mb�s��|��x1� �
�[G�X��E�3���ww�Y��XE��j����H|6h�ۃC�N�s5�Qi��e���s��	���Ή����j�f�'�)nCv���:�Y|��@���緆7b����G�]_"�21�Z)�r��h
��`�4bg@�-��!uA6-k���g���lT�W�@�	�,󭣺HMF�����*��gԁZ傏yC����=�Zn�V�:�;��PNPd/��{aŚ�����=�;/������#�(����hF�P|%���7uSE1��4�7�
�(��R��h��7�-��0�Ě̌W��I�:�'U��?��;s�+y%06F��ݺ�u��6�}��dE|W��=���+|^![��j�Ⓗg��S���)45)�LJN��$���類��N=���e��X��p�!�s54�'�˝#0�ȥ|��q zY�@t^#�{��m��hj���j���FZ-6䏾��)m��o��!�'�x�E:�3=�6���[]JH�C۽��7�Ӻڤ.IF�i�Ǉ�i��zi�FB�FS��{}�骖�9���bR!4!�wm�Q'�`%�f]����.���if�9Y�{r�x��e�S ���&���|]���95�h����y�M����餛X�Cw�!�F�(������rh)�!���o�%81�K��L���3/�m��5��G�<I�<����U�V���tS.���8�T`22�og+M�=>����ur���d�0�c�s�����BZ�����T0H�`�$E��2�S��GT���E5U��)k��gX�)D*�o��[O �	����}�f�dLX�MLl�i��u�Sϕ�%Ï8;��}lP
w,�G��O��By]�OL6R]�";x�A���h1L	o���_���j�
���o����HO�k�zU�gP/��C�	1�]-���M������i�SP��rs:��B���[b��̬������Ů_�Kt͝�E?݆ێ��6o6
��9���_5���OR��۷���j����>\��%4�4V���G�	?�6�<��p4�O�l�	�w��u��~������ ���kHk �3Z��(+4�.�ai�v+g�^g�暓񭓤��M!���9���^XLU�s㟱�R�ڀ�{B6��-�_��5}�n����'��J-��=��#��]|���հԟ�:D_��Xm��Z���� ���m�o�`} M�q4�v���l��J��p���j�wՉ8��djdF+��CCT03q�c���u��WT��ϱ������Y��{�>�I�dWV��	����7��?b�"�S�m�Wg��ɪI����n��5�̯�;_�t�����Hr�D�EN�9ȉ���G��W?����(9�l���� ���4q�Q2tE���|�L+�*RU��SV�5���W�}֍���O�9��� ����%��v"S��%�H�7�|~�D2���tpH��!,��*�刨�����L�9$9�    K��圡d �������Ա�g�    YZ