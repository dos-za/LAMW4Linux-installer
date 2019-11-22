#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4234013425"
MD5="e2b421de3a4f6181e9b30d2c336306fd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20329"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Fri Nov 22 10:12:28 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� ���]�<�v�8�y�M���tS�|�=�Ȳ��mi%9IO��C��Ę"9�K<�ٳ�����x%ʖӝ��N�`�@�P(�����/�ـ���~��v6���󤶵���������d��������<�
���f@��tݛ{���?���9��Lל������[�;s�������l|��/�)�mW�l���/�)+�s׾��-ӢdL-����f���c�#O�����+����Ȧ�7�#�Rʯ���VuK)}R��k;��F�gh�l�~�P�)%�,�*��� $ޘ��;���OꧯazT%�)�	48�$W���4 c/ *��:��.��SeS��pR�׾�6���c�{�3��35i��N����Y�_?91H4σ7�ݦ�����������j����A�=h�i����2x^�0T��B���y���1�퀎B/���;ls@{L����y}�W�ע���s�R*&����K *�:ns�����;��me9�+���+��y�o�ț�<WcSʷFA1v�0t'�-�h�әd;�=]�%J)��|=]y�x��"�l9���&lL�� �
�{W�=�,���l��p�sF��A;P��FfHt��I�E>�������/D���F�S]�3�� �n�bJ�bWSJ�:>��cN�֥W�0 ��̯� 
?�l�2*��ã�2���&���D-����t�Z��u�r�_�����H�g�bz�	<dă������P�te�yAT�|��Lh�ԩqzȗ-�p�e�PZT�J��h�j:[7r�:D��zjѱ9� �l�y�f	�Z���g�R�:_���Y;�c�6��C1#<_�!�ӿ��tD�{I[��I�7�� o����n�m�o���	��Jβͳ��Pƀ*pD���^�!�V��A@M+����UD���ίW�WK)��%J��2IH� S�9b%n�esSXJ��7���L�M)U����b��]��ܧR�41X5�|�D��(s"�o�?f0��Q�r�Y)�&�ɇ��HK�|�,�����;!=��CjU��������-��67��������o�������&E��lҾR�����h��ʯ(��G�����6�]Lׂ�|j)D�1:��>M���)�W��**@8��� ��mnn���v��M�����2�h��Q�I����i���7�h���ϻ�C2��GI0ҋ�̼�6/�E!�96����M2I�}2�,{lCN��㆔8����b~�Q���#�D�R���>�41ڢ�=�1,d0�ܹ��ʨ3&f0��xFƁ7
�����D�t�O�a�}]O�UmO�:E%��Y�;��+G�_���xD;5&0^E����"��P�L����~���:���~�}��_�������������5���WmَE�*�~���V���[�������g��k�����@.HynhB�C82�F|����; �Ҁ�$��v�/�QA�{z�GtR�w/v�5Rw������ؕ�EC:
M�Qp>��G,���Q�ƙ�I\�t�&��.?�g`��6��Js6���� ����sI)Y6cX�Qy�րm�"Zui���a�%���K����a���TU�`Z������W�������vb��59���~^}$e�HIɩedlU7�y<�ݓ,�P�X�]��q@!���ũz��t����ԡ�x�5�l�&�28i=t����G,�{�9TYk'`�C �8i��x2���<i�{MC�w�W�n��>3�%�D�^�F����ȥ핖�}�ӳ�d�?�@�m�F�JK�e. 1��l�넕L!��.���2,�Ch��$�]?o�3���%���pX��'�f� ̞?�ñG��D��Fr�x���_�q���_�����AR=.��2��|�T���_Iw%L�/Q]�o�`v���h�ܞ]��h2���F�Vr�TbU]<5)�<�Qm�T�͵�2�_��2�uӓ�ø�B�KK$���BY�ó#<<������g/Ij��8
��9�r Y�6�������*�m߿Ӟ��PǇ01�_Z���t��uv�f�}����&ĥ�<�tH�{�����;nf���{U}�N>��K�p�T.ozW�5b�.�AQG<�[hʓ�9���
���C�C:8��R��h.V /^,L �b��9650©3q�;5�	�N�*v�@J�])aU���£�8�����L��A��=n�,`��7T�B\@b�D%�^�/b)��{=����^�h��Ϋ-�$���6�Zoܙ��B�/7f W
e��*R�n#H��>�6������s`��2/�h�$!>�~������w��,:I�F+ނ`�^��L�E�A����2i�5Y}*�g��i��N%�j�p�V�`������B�W1�@��}��/�*���G�I��Z��  Id-�n=Mw��w�S�;�� �&��@P����hA8���o��^�Xa��-@���1G39P2)@!x�_Z�˥��I~`�p9��=4_n�Ds|m��DnǓMDY���9LC��������%7� �<�'Q��J�ސڤ;)G'���Qm\���nb9��� �67�0s�%�/Q������Ă���!'g��y������s$1�e��GB�ĮN�6+�E1阣sB��<l��O���R�x	p-z��$����0�����w�^e.�Kx����]��׌��	�4j��!��2���ߝ����\�wgw����p�w��_�tf�X�%�p->o,����]�|�e�С����Ao�b�.g��Z���&�X?|z��䞇?��pL�z��{����S�P#6T$�~�{k[��ky�4��U�����NۇMC���݅��n�Rw߉&�W}��7�:(����.��wjZ;Uy��hp�W>��p�'͇e��if��Ⱦ�PZR�~��\i[ѭJ~�>�Z��;L�*r.gW�J�,�D}3�ˋc��G��x��x�F,����ї|�`�
%�a�h �������Q˭#X/�C Un��"AєF��c^��7V�B�Y\��w��C[����J���P�u׺�}�AfL���J�0-i�5`L��9�ߖSeo��p���@
a�^L�v�g�(Fq�.�E._J�5�(�o
��FD�\;d�DqBõG�П}Ƙ t��.����Թ�늒U[焐��)�6�d; ɹփ��pb��v���)$!z������ �@=Ik��ӔZV'#���SPS�*<QB����Lk-QخCT�ZH��ƩB�JT�.���WC���=c��	<4�⾸�H���x�ZdZUtt�H�0H@Q[�������ZRQ�B��_9��O�!��p��=���5��ӽ@�'wϥ��	��G�a �Y������jE^�*=�KQ��V��\�x�̧��[q��t�I%��B�R���H�4d�r$�(��4Zj8�>��~ߋ���$9c��T;7!O~��!yQ��r �1���~.w��9���Pp�&�b�w�g�""� ���C+o~1J��E�`&������*8�Ko�E$9�<>���uE��W.ꎃ��'�m����׀5ĐH_��-�� .��*9�óh|�}%s(�ɦl!yie j+�L4(���W�����'Ѻ��ёg�6�1?�>h�Y�\����K7N���ޚ[�u($~�k�Ie'h�K�{���$��4�<Y�c�X��"�әH�FIK,�t+rs>�*`ۢ-^��ˆ?8�0���r�t�,Imr�i����\��&y<awD��p�/����v���S��h�W���	����
oǱ'ޤ%�E�'9?xtMoQ�(Q��7�@]�.��⪒�
�Kz(Y��O�Ԗ;����¨`��?o`�~r��+s�u����X3�����:�Y2�B̘�������s�!�th�or��Ôq�ר�5����ي��cL����~�}�ˠ�8�١t�+=�N�bKE�Θ��NK#��X@��N�����*v�ˣ�y���֓���o�6�A6����z�=����J�5Jw�F��^&��9H��E��^Ϙ�M��"wkb�.���{�PtfH�I��s�`ַ��������9��ڸ �{���J�V}
��X�;��g�<_!]#ٲ��1�nD0������B[vr�]���|�n�����&*�?��w1��.���<C =�����5H3&�,dhhf0�h���c�)��3���<�$�^m��h1ol�-�.B���_f���f��7dދ4Z=3g��6CM=�=��"|D�yMG�cK�>�i���n4��k<k.t�g��V��?\ƶ���/���D�n݆.ƃ� b/�l�
�|\�3�5cl�n����l�b64@F&<�5@e���x9� f;X���sy�q����yxmO���-��"��i�1�g�)l$'+�ס~����)^0�� ҫ��Q�g�Xnd� �9��BDB�
��v��y�I�F��%�+c1C�:bȡ�����ف��A�Io;��� �����<ljg��Kڼ)��}���1��L'�F���h����2�ڡ���N\�+YC�E�V��ͳ�A��<MjO�:�E�)df�kR4����m�`��h���E )  ��6�E@���_S��Չc�5Z�����L��$�-��3t�m�B`�RI�L���p�T�Ĥ�e�$�u����z=se��T���L�~��th̐l�#,o2;���/��q$��SG�:k��&�W�D�eaU�G�� l nQ2��x,��{�k�w����V��b�C�<����iV�H��Y.���bO��Y$1uZȔ���L�Yf<�n�~���ةUn۝�ٯ�'5w��u��3�T�A��O��z<3wG*p>4gF嶜#���#e���!%�ӝ��K
����Ң��~���^�_� ',�>}Jl���ן5������N�����wOT����lV^"Ow�6O�tKyk��@�\Ĺ�幔���/��y�dMT��ۮJ����G$5V����T'�&{�W ���:ʌ�`ə� ~dv�V�O�T���S��7Rg�a.�]���a�L��L%�~�K��BJ�TV��[ϐ�DX n����o0��a�81�yx��m��r=�q�'��F7Oί;�	�����W�N����F�$U5v����Չ���;�/l�v��5����GW;���B�\�k��\<�J�t���%ץ+s��xZ��;ca�߰^��C��X�S��C�8�YX��5��J��r�s�в���DM��/&Y3�2��KY�,��)�����c���F�_�K�SÀk�_��d��0���U��]�� ?e��jT�����V�Nħ�@�<<G����;!��45��i,��i��۸�=�U�W�M���(�cY�+[t��d��$3QO�l��ln7)Yq���=��/3g�k�m} h�MR��ɽWΉ��
@�P���V���`�]�2���p�ү�G\?E���胐^���d��E����E ��H�@54j�/h��kC��dqM�ಟ���[�����b�t��P���+�_�rW�I g18h-��<�()�V;ħ���|����++s��*������T
�M��`���C�ag@_��s0S�ɕ3������f�j�:Y\���j�=K���T΍
���߼%݌����X����r!Ѽ�XgN���w�҂����N�V�9k]�6�0M��~<+:�%S����s�b�gd�R��qx��o��3�f�\�̫�����y�n�c��1&C>p�YR�ŧ?�Z�Mo��A���	���A���"���I������Y�k:��x�\�F=|��-N�k��!����R�E�LB��:=8�Nr?�I�#�BW���|�c�F����N�G��s��L!�ɚq��� &�y}<���G�v/zi@ϡj�{l��w��H0�pL�LA�3�(~�nD�xD�?¿A�O� ��[��R>�HB=��Ӊ~��ǃ7�1�|��k�4�c�wڟ��~D�|F�靛?F%���^=lb2�A�#%Iqu�Ȟd�����EZ�^Oƣ̒1�2<��b"�p��Ç���f�������7�D���)�&J*�Al�sS�����4�ҫS��g�0L/6��t�3ן�\T�y��^7%��g�)�����e�I,Q���e,�����|^�B���˹ܘct�N('�5��7���a�*��ƍ�;��am��<�n��9�p��^�_�N��l����,"��N��+��x�FٹGd"C��
���>�Hg0��*.��D[0SN��H�A�7O%�5�e��&@՜i�ti�(���IG��bF��Jg2vY�o���Tt5YBE�k�(���t�K�):��Ry`	U�=/C��]�S�TS���N��(����9��{�������#����6�V^XS������N��\�X�a&��E�-276K�����Dc���;-i�W��Uvuo,6�0��#������,���3	+�ӬP�G����T�;8����wv�r3An���dr	rS�ʯ�����̍��2�%-~[W��s0�F���o����@�*0r�.`0ɽZ�2��u��Є���e�n��9�;�#��>��æ`�4�+�n�A��,����W;;�db��Q���Б���5IM�����E��7�s�O��YH&<�����n���� Yו�.����ğ�!�2&-� u$�[;2�R��Rݫ��@��h	.�����++,��Z���0�O7M�z��4��R�o�����m����f�M�S�?Iѐmߨr���$%�Yɉ��q��T<,%��7��C�C�(]Dq�يk��5g�,�y���}<�-<�oZ�EF�M�������]�]ٸum:�I�Fy)���1s_�L��bA�P�2�X�i���S���
�-7��^��:X2���%I\�=�� ��.�G�-�tUH��NZ���@���6N�"\\�q�z�� -f�tS$4�M\����w8�}�mWp�\9����7�8��J�����y����r����Jn���kw�\^fO�z����.��jV�������|��<��Ǖr��.�7��w8�ߺ�����47(Su>4��@M�j>*j�@:5���b�l�(ܨ��A����1[M�[[0��]�O�=򳥿w(�o���8Q0s�ʄkZ�)e�ǣ���HH�:��FC��
#Q��%�z%�{�Ǜ�B�1����5s�;+��1���/�{�`Q)�Ĩ��x�����|�^���C������[3pq�*6�����LSM~��6#�������e��v���}]&H��8�k���Q.�yX}����@}�1Id�g(��Q��&\$KflDYl��b���g�,-��$A�-�P�~�9�`�'��N��(�+����7�B' �t�ksSD�x-�GMr�M��1\6d�CU�F[����NKܒ�'�6k���A�q�@�]��|?c\&+w�pta
��/��zz���7�>zqV�-���m���W˘�' =/�l�.�$���៥�v�{\R���T'~�tא�����|���|&%��g�`jReK����� ~yِ� ����:��Ìb��jB�7?Xf`�׍=B��]�#�B_f��8:�� ����P��wд$�-�ؚq]'�B���euv&����z�a��/���Ti�&`Y���dȷV��ܚ&�/4��r%{U!#�q�8��}$VyB.�$��5��'U����a~��$K���w�[Y5���Y��(��tY0�%FA���k L�3hq��6���ɟ̯C��f�� �R�_�p~��p�Tg�/;��]��m:��n4��=��=��l�׋�u��4�_�4�V��ßM�خ�.����	�$��G�.�l79�����5�4�d1w����A��4EQ9��`�Ğz�/�6:DG�~��h j ��~8�/�2x��'�bD~�*��c�lʾ�=41"�i
{�<̊!�F#z�x���\��{�vZ2�E��ԧw^�Oٰ6O|я�� �x��?�\+��@h3<���>�!�f������k�]���&�zA5�#Po-Q�&�L�lB]�,���"NDS�+���A�P���(�qk����ֲ�g6���Z�� G���S�.	��儌�ȷ�5Q5��L�+#"����dI��􊢢�~��2�$�`V_�o�$E�'�����*4�l^�������PثbUu�ݕ/����]C�������r��k ��9&ցD�Ǟ��Vu��gb�V�[��h]h�<6'����bd�)�JR�Y[��jKf��X�F����k_��i��S����~8?�`0�98"��f�VYT���GŪ����^q��A:ܣ4��T�ýݣ�����C��g(uT�9���4h ��|Ag*�s���s�W 9B�J�Þ򬿛���rڃ6I\� U#�[�ca��/tJn��F��f�܌��Y!�sF�L�^�M,�)\�0zNЇ�Q�*���$$�=R\�O��$���@�&��@�:�fX��Y�IW,k���Կ������
��Vu]��-��i@���UI� �?�H�bM������2敇��=d&Qk�~	���h|��5=N#���lbL�D?�5��3y�}��!�����C��M}�q_�#�a@v��i+]9�͚�s'�Q˜d?�K��-�/���L?��5��N}�� �!�Bu���apV�B.��	Xk*j~/�?ݨ��l�P��9d#p&��ҡ�M�J
E��1~H2R�LA	��\oXf׆��g�՚м�X?��,t����ڼ(��$R��Ӽ6�-u��9�~3����:!�bZg����p�F׃Q0x���q<Q�n��3��
IKh��K,cQ�C*�	�;V�^B����t@y�p3
�@)�ɓ�%�	��OŒ鈠`_� �It]~�'��`~��uB����¿��D�P_��c��E;w:�X����}`����$]���֕��?�?]���֟l����������@��6�?��(_0�ӛd!ȗ��H�t��~�*�[�;��U�p B��t���!�J 0ِk�����p>!��-7�s���9�b"�9���y�n^(��������`��"[E#`�-r�Β�D����ɉ���=��K�A1��'!���ofF�V��7�p�M��<�p�dpP�R�G���B���
f�G�/�pPɃ��8��dp���cJ���>��������D,�C�GR���I��œ^�BWd[��9^2Y)[�$�S��EN�j�i�p#�dh���J���]������b�م���y8�L��4e�zr��V��v�i����G�Rsk��hD�!A��}zw���x�'���tA�Jr���q�)�\RW�E� N�?��IH8�_�����3�O<e�q|�yN����]%ay�'��>�?���@T�+B<Hm$��cM��C�RS��#�����Y��A�f�bY�@���-<�
�G�-��G"�0����γKV$EL�����r�x�黎h����رoއ�-:�By�Q���ך��Dމ�}|�F}�{G����ݿ�t4B��haf��Z�X$B�i�a��r�UZ�5ލ֭"0���c�<�U8��_��/�4�]���=>�5����V3��};�i�P�;����|#d�WX�}�`��B
~^��uxW|�}]vwA>6�:;$�ٞ�0�t��>'EH�����4���?7���ܼ����[U�b﨣��A�,������������i} c5ӝ��H���=�y�%�h�SH�h��,��G	��)�Ki0�/�����7,x�W�Bʲj*�g�!��]jN͛���hM����J �p�'��*��^�Q��v�_�9w���I��E�+�	ߧ0.O��RD�W���7����g������t�*�������7�N>���և��N�W8��~ DD�OA�~�� V'7na#��I�u��1`��i��w0Is6�z?�@)��x���z�����'�@�f�mdr�I��_ڭ炔^g�t0��0�y���;��lu�������=s�JB��Ȏ C8�M�7N[��CH�
|\b�]F�?�U���e��t�Cq�����eDzE�d[Q�!�B"L~2�L���=i5��Bip�5��kh^����m6���Y2]�$ �?(2"����KJU�j*�Qæ!hwڴ��TQ�N?�������&�.oʇ�|[���2��$e���^�6�i��{���oH�4
/�^�$7����,��$��O{^p��V��GU��������s|5� ȕ$w� O��%�7�¦���Ė�zҜ?KH��l��v	�&�v������h�®A���A4Rg癕��u��^e�V��m�i����5��[�v��%�%kT-�������2f2��l	Toy1.4'	��8��Q�fQ��c_֦#�@p��Ba�[*�n�:�̳�cm�(ޅL�T�g���=�ғov#�tF>gL�L�v������}fg�����j�T��-תЇe]x���/���j'Iy�bίP��FQ��~��E��$�S�;:�pN�];�[���V�u	�۾Y���q��%�s6T�h�;_U�/F;������4P�ڋ*G�W"E���Ȧ�҄�����
�ts��~��U��}������o�i��^9�v��Ԯ�&�{����u�+-!��Ý�|��M�����t̵)pF~6�m�E�q����58��)��^�Va�n��YժV�]
0E�*�W���o��[D�>���t�)��d�,F.���|>�j�q|>�?]�z�Ep�J��L��bh�̼�A�!�t@}��e�$��C�L�Ud�\��;n�|��b�/����~�����7�w�Vǚ60��	${�ڌAV>�V2���h+�`N��+KF����/�\g �7���s����ٓƘ3+JI�U81���.D;���]�m�J/��x[B���PD��*L�n�(�Tt�vk���i5�]'ш�g�g4�vP.{�й�'���U�Q�����%���f�h!+᪾/̻��y��6EgR�������׷��(��o�sn�_�+�-ť81����T#��B<�f��z���&a}RS+���i*_͝��<�"��ޝ���޻oJ.D�4ugA4�x��D9k�Ǥǐ��Ƅ9��B��Q���S$yK�[�׼Ń�$Û�*H��ņr��f%�E���� ��/92�`7�煵�XB�!h�~�qg�"ٮ���g���P��t�z���@3iÐ��dl(�致��<�k��F��`௨.S����ʯd,>����:̘��0�ǳg�D�}Q�1�.eg��j^&��qr�|�ެRש��Eފ�㳷=�%ѹmÖ3�ȫ̯{��TIB�CT<{�S8�҄�u�����K�K�/\d��L�H���TIo4�жLv.�Ƥ��	���X��n�G�#��w�����M�F�:�®a�� �*����$��}���H?��9ɡf���$�o�*�B� K���d�[��ڗ���pZ�,_�N�sx�`����ƤV��T�Y���>� e}$��?�K*�嵺9�7��[#��`?^����:��s>2�������O���o�n��2c��E��Kc�qB�����G��Z�:3�5���5��'+樒����S�1VyW�����t�S4��hޚ}����Wny��!O\,�H��^�8�w��,�T���A<%wL9	��,UC�aV� z,QMf���6;Œ]���#e�&ɷ��R�Q�c��J'�ڨ��mp�T\��-�X)� W��6Ҹ��B��e�9�sÙ��JV�lf���4=���E�� �VFa��Z�;f�6Oܵ����J%nz*A.7��ן��i�I�kv
,Vg
���f�fVe��'kO�k�'�+��I�uVB�A�mF�o�]I����uR��a˟�!�{��3丶��8�P��Y2�j�돦�;ky�y׽�7����Eǧ�h��*9&�/3yX��.��Ny��.����컝o�#���] �B��4���LTj�L����~���H�`](�����!>_����lnE
'���niG�,����r�[^(G@L��:�}��[�
S�c@�!{)�9�DO>C ��>�/zMo��_��pᇃ5�A4y�V�k���Y%�"Ā�vIex��*�I�2�A[C��0`�)��i���oP�-��d�^�f����V9Lٳ�'�����F���Lq�dt's�;b���ٲ�B��q�֘uwX������{D
c�̥�����"
�3�o�P������\0���G�H�����v����4<��Y�,vS��E�p�1f�.�kNx.�+y�@��Yh!�ޑK�ƂOK �ڌ�)�yB�K��'�T{��`HȪ�W�x$��=l�F��iD�hh�,�6nv
6&���"���*Ϊ�ml-#[ee�Y�.)�Xa]Y��q%��椤��v{wO��z�=��ih�{����7��9�ܐ�O��w����q���)LB�����L�`4�"�x��yR�9�Py�S���v���7M0�J���ḑϹ	�Dd`9�n��\��"���������!��#C)�"{�vi��+ѲB�G��}���XȨ�@���c���-=��;sfZ	�=�-���+���a���˭U�O	}���s$��r�^�7`aG�I����a��cO/@�OSP��S
���PŤ=9��;P�B����M�WDń"l$�)�JS�%� jH�,���,DA&�yF�bVtdQ�8�V(�$�y���97(5����K��;*Q^a3̜*�h:E`��t��7�������@��� ���@(Un��ɟ���rI6~�]��<is(�ff��}�u���,�P+y�cĈsU���.0�:eB�_���:��+]IM,��A�yP����\�_�_��L?f.mV�*�Ծ�ɺ���?�-��h�4����l�c�s��$�0`��)�<&D<�(+�1d �$��|w���]́@dM]0��@u�ʰd��W��\]�Y�u�ԥ���Όbge+�X�(�D�3ɘ9��x�%�9�>.�B�7��\H�{��R��T�|���g�ZV&���m&g	
���^O0�˙�4��;���7I�M�fp�^����5;,��&�c��o���7�~���#
���Ed����OA:�4���!+��h`қl{��$>���F�w쿽��e�A�wp9
��?\e̲d~h$��h�b�`h�:]��ռ�E�䂧���|�j�{�z�H-�19eK�{����{��r"�3���jp��Rɺ�*�Q�+Y֟j6�NC>s{q��dka��إ��m,�%��U�2wY�D)|���LaƉ��jĨ�fl�f��&o�pg��df|�[�G�Ğ`Gb�-0��״���=�'��2x|~m��c���9��%�.��&�%7G���R��I$�<�תo���Ŕ*�[5U�30Ĳ(X�WU�Y�Q�����v����Lc�po���Qw��Z;��� ]	`�R�1��Z�����pQ%qS�8��[�9%��b��ħ!��>�F�Op}��}m[TӶT�Ǵ|n^ji�<݆A42F����ȕ�\�X���;_ao+��A�4�%Tr�8�jOT��@#H� i(::Ԡ�T�	��}ȱ���9�T�r:g���c-1RO:���r��ۛ���ȹ���Y&a��?���Y��5�6��w��\'�Tԉ�/��ٓ'%����Q��ּ��v��|m��xo='�3��Fq�{���)x�{ ޜ�0|��E��$d��&�>�(�V��j��!iǣ�7��qArG�Ќ�,�O�Y}�}!ك�y��"O`�{s��n���"e�GT?���������I^Ɯ�)j&����Z�3F��"�GS�ї�ւ`!Z�4 �!8��2�&���D�	��Ylm��#�a�h4��A�}��X384�j2;�j,L7I2.������|�x�ڵr��/��rf��D�}s2I��m����?l�����S��'.����!���F��1 �;��c\�P�\zG!?��7� N��d��S���T]>	�on���Շ���vk�?�·��[��5�>���������W��#���%Wf&�Ƿ�E��mX	��~��	ld��`EV^{��0i1S���:���3��2La���/c�\�c)�1Lq%���3�#%�`Њ�-�YV�϶�����ϧ���)d�O�ݰ�`g�J{{��b� ���n��Q���Σ\�#�g�XM�l2��B�Su�w;_uw����;��Ζ���Y�_�P����Tq�4�s�m�A^<������l�N�n���29�ƗaB� ;�(
�` �U����S@)��k�J���!�}2y$a��D���1a؊�����;�><��{�}������C�wZ�w��u߶`������G7B}�h*x�a��k�Zo�e��ցƻ�jf��}-�Y���*![ߵr����g�޲��cN�@J�)KY�R�ʢR�Bita�~��c����(W&5�k�iu�9:8\����GF�,�9�l�G�ޛ���p���@�[o�=�xv&�&�U�[MOsـ���n�.6��MӖ�:נ:��Ģ�y�AR�s��=�7�M���ͬ}�$���_�A{�x3�f~VPk��	�	(���<�����Cu��P�9��T�7���'�N޲a9�t�ݝ�J5#�:��5�g��C-�z7|�aK��������(��	/h:L���m�+�,��8Q�q��6�b����۲�zw��=j�[���K#�m]&���\"|OZ���Qo���c���G[��y�3<�-Ο��o��ə������DjϬ��$���9A����[D50����kg-0b�a�)������vk{���"a�SO�`��I���Q�D�ҜJ��)�9=F-��'�w��9qc���� 6A��|j���}��l,u��z�sa�I/F��$�A
�������$8O��Q��pN�ހM]���s���yH>�xYKҖ�N���l�,v��_l��T�������u��]S�ӳ��ao�:�:��v{_�/��Lp�lj�w������K��-4==��_�L��Z�d����o}<��,L�dx�,��gۭ���m����e�j��Y���� iկ�>�uvA��5�Z��`�B'�~�6���CJ���������X��7�_�?�h4��_��8ĀkcE�4 n���[U�?�T��F�����y�#L�ң_��:��z���g&��v��w���]\;:��m�k��>�����
����s��{t�ځ	�����V��I�!>�p��Q�s�(�%D���Z?� A��|�V(���q��tzf��Q��_0G��f���$���`���r��WS%�q>�Nֳ'z�{���?GS�V���rb|w/���������t��v]g�>蟊s��p��/����2R�Zda�Р���B��@9���ԏw��!@��Q��Kb54y�%��H��� _4q��+�]�۞�h�طۻG[k��CW2���H��dlz�1�_�
¾z8�S��$�.ӽ|�X�C�F:������q��e>N����B�@�v�Y3���t֡�S�.z ����b����Ui��"�ӑ��C�	�����3n���;�ŏ�t�ml��3eE!t��ѫҩI\� U�&�������lFCmX���kA�Ԃ������6]�>�)���byj�LU�ỲF�t����gќQ���s���� ��`X��*/rS%_Q�xƼsߟ����A��H-�U��w���[��\M�^��Y��W�px]�7�֛�0ԕɆ�NFY[��,��M��?��+헊�[�ۅ_�	�OS����E$�u�ThVx;a���^O�[z����/��g�
�������N�o�Ps���jkl��*e�W����;���.52��������L�ap�6�j��7e�#���P=Pr; ��g��u���T�ݹ�I�fM�Ӊ��yM4O�sNI�wxLR�a<W��U'kt�K�s3�!�(*�-��jmt���{���� c��)�@̭��o%W���]�M�W�Od�2Y����I� 9�l�FݳV�*�Z{��X�A-s�t�2�tcky�Y�t�%a=��>�u��MK@d�|�UP+n�7P]�bK�G�Ԇ�OhU2/sT�2̹���j��X�p���ZyDѼ��k�t[�����w����J
�����R��Z�KiQ�^wQ4�Np�kF�(����������:�[�O4�yZ��|Ҽ������c�sc c����m�S	�r�1w�pt%��Ĕ,2��$�/��%����V��Y?�~�C~Ux���xIV���l�-��H�G�mh�GɣD�d�Ԗ���Z�ǻ�E��ǚJY�W�Z2�A'V�x��1I�L���ث?E�-�S�m�NU���ߦ�]�h�Hl����
��T�KK�&���SA�5�=�pQY��V}!�Fp�!��?��_T����g`��:�LAkMӭ��n?D��>g����l���U3�_D$�/0.�����J?NQK.�/�#Y��1n�a@e^�K[���[��V�(��� 1Tqش���2F�y2W|��e �3���p^s�ː{G6ᒰi�.#���^���#�C(��knq�r��q\P�s5�׶���E�U�0oԟ\B���-�9]����{�J$�[8�@`*8��o�7X�y����gEG�\�a�2�P�d���R�q!��^X.�fULS�찠P5��N�ȟ�{s9�
0#�Z�t� ��x$�A�Cñ5�>��<���R��s�`a�u�Ze*Tk�b0u�U&�U�f,j�~b�t�^��D�]0{��gG#�㉾^�c�'��@�X�� =��K����v^��p�V͜.ܡs�x�L��C�} b��\�!�j��AP��_�Y+LM$!~ؠ� ���y�O`OOȟ3	Lgْ�Y�p�	&�#v`�@��d�L!^�qM� )�Vf�O�dg�Y���iDߴ�4:{6���b�ɨ�"Y�2g����2�e��Fo�ܸ���6~��*�m]�E�М���X�
���J�ǣ�{adt}&�$�~*�����C����m^<��d�F�>Ņ� |��4UZ������������[�F��Jan�n��B]�7Rd;�r�/�/o��c�����x��/��I�oR�"����ľZ�җ�>I[���Ρ�Ƴ�q��.��b=)T�-L)hP5t�*�
�A���||Ni�ȕ롼ϖf+�'B���u���[\��k��6�;�����,��X����f.��L�I��'S<�)p��
~.�k��!�O���;16Ex
z���aڙ�8��� $t�t6б:����<��1����ȣ�ua=�
��(��BJ�b� �ۏ�e�k�̰�	���o7�$�O�{����8fv�2m�Ge�2v��~vLyO/���zs�$/QC���&q��R-��Z�
��骀��_K��i�j�\N���t`�w�Ԓ�ӂ�b��&��v�l��1�5r�"oD��5R�(�(t�⊡��F�6�A��Yv큗Ckr Q�n���
kBB����W��|E���5��T�Y3$	'� GC�A��~��i���c.����f�Ȁ��xr�
9%+��C�4���2J��h�k��&O�L
9
���wGPiXP<�CT,�bi[a��0z��O�_o��^���e����?���f�O����aoo�����Ƴ�����7m����Wכ���������;��/9�hq�'c�~���)�\�x�*�������7��F�jH�����ꝯŻ���g�	�褓8g�JY:��;�Ϯ�i�((�����׬6:9k�@?�gc��S\��i�.��eA���@J+˪Z�V'��oXP��g�-�q6�ޓi)5x���i�Re=��u��A4⠌�чPl=ƾ@�!��򦕏��7kԐ�2=ƴ�ڜʬiu�2��'��-	ǊJ�z9~	)�i�{I�%��+�X�ɡF�6u���r�6(6�J�
*�,yIe���dV�a��o3���P����I�>�Ͳ�D�E71�5�m�����矿�	~�JiX#y룚F|���=�\譴��I�`�du��1�Ú��8Ny�A%�;�WS �B0��.���)��a�~y/����-�`�µ��5P��\WVV]�)���|�0x��v���U0�hn�d�D�@@�ä���v�X�.v%�&���ωH1��h�}}������w���>���p���+��?���w�#�?�Z�և�;��Z]_/�m�o��?ލ��d��q ��"���DC{�06�N��D��Kq���]��C2��{��<pЛħa�X�Yz ���^��$��z�����eC�������r���ۨ����΀JӶ_�x_Y�w��N�����|y� �ζq���.z�S�x�¢�+fj�;��w\c)'��@�d�\�Y_6��/�8n�4���X��xOQ�.�����Z;%l�&�m)��,m)_H�(G4�tn#F?P����P�y�[<�(�N�=w%b"�l;o���D�@����Hݟ� X�CA���5�th�3vMJ�=��C8	-5IɗGm��9V��v��5���XŰ�B�{�3�8��(q��]�Ѧѣ7�P �j�b֏{�v���(��3{̜$��bim��/�5d_/���g�5���o�v�>��8��TG�[�x�t��\��e����m��Ѯ~��m�Rb����
D:n��XX���@N6F��C�o¨��@��U��!`�3��Y���pN|�@&)���ހ_�Gq<��$�~���0B��s�B�Xɰ��ދq����m�oa�oc�ٳ�����z����?��qt��7ͿMq�as�_
C�'�y�[r�R	.�Q�����=B5"<�Z'=�_��P�����5��� "��>z���ʡ1�}$}�ZY���/R�}�Yڍ�,�V��1>˝�����v�bkLk�
�&�M�k�f���u�=&�ܦ�3� %�ᷨ@U�2n��+�9!,��9.�A�x	��7Ӕ([gʍ�E J	Z㢈���f�8���(�ؖQr�aN3C�+$4��-�劕��o�w��Z	�
�l�R�3XH���Tg	����{vU���~��Ƴ�+���D������?�tVM�3ܲ��=�:̣2��c���.k��ܥ�Wm�hE73���n�閪�y�n.�U�wC��FN<gqr���D8d�ϴ�J�[<̑��V���������+����fu=���k&�&�Z8M^!8R���|C��a���,�K<�'@-��`�2@,���8��w}�8@���	�U<$IC���@�t�qmx��Ix�W�ɮ�:M�F��Դ��q:�O��4�F����߂a�R��ҫ��F��,�㳳������n���WN4�&W����j��Qs& ΰΆu2!��_)������"������|�\l�h_�֨���ݰ��U�?�?Ԟ��om�o�D��!��:价(m���(���Xd�I�#�"z����l}�à�;�A��$Hde��Iz�QY��6	�{_R=�"KQ��ܻ������x�>��Dv\��Ih -����R���!7uS'P(�;���L�ӑJ<�~����*3=6�z��T=�B
^ Rp�'P�81S�H}`��3"G��,K�5�������s���������?�V�� h 