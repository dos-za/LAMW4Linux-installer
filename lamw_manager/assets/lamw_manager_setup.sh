#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3144074595"
MD5="db5d3f4283b0c8b9acabb83fa8d6664c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23920"
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
	echo Date of packaging: Mon Dec 13 17:46:48 -03 2021
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
�7zXZ  �ִF !   �X����]-] �}��1Dd]����P�t�D�"ێ _?ё��_-��k�%-5�<�l^���Mo�\#{7k��B���S��z�+�R%s���L@P��fX��d��l�����)�{��ʚb3��/��"M<%~�HK�%�o��l��=�U��F���RL�{n��b�ŗ.�/b�Ԯ3����i
^�#��'��ē[���)�ũ)�>�.�U= %m'�B=��.R�k���SR%'²�tV�es����e}�~&�������>G}R�GWH�U��!����^pv��N[�[(���^l�e�Q���^⳶�\�='���-�U �r!aY����'�b݋dS��QG�v]�l����;_,X��~W����_-7ζz����[Y�=��0����x� d!,��DP{s]}+�Ӯ��w(�u�<n5��.��W�Lc�O�kz\��Յ�B�qǝvG�A��%Ï�#������!`:  \������Y��ӻYzX��# �J�7I�;�̰ܑ�4����t�U��R����sz6f�/���4zPe"�.�2s��R
����&5��lf�W�Hlk�����g��BT���˚Ǟ-�����L�,�݁%��/ �"���1���S�n���Z�X�P�0~xԱg�҇V%b;��k�l{��^���m�֯��y	�5��f�2��8 �-���Cq@�����U�-�	�(�W�ա��qg��|U��V�����ܻ1�Dwcv��U�-�ӌޤaѳ����X���Z����৭�I|�l\�YAGشA����%&�+[�Ĵ�W�9d�!��tG;@�t��"�-�0N�	1�	�����h��+.���n%�A�ϔ�`;��*�3��M�i��?���Vh��,�c��J��
F��P�����qH��c�"d��{4�I9�Yk��ʆ�(3GV��ZvaԠ��G���ӝYR"¡t5��AX��J���"cn�f�l���>�>��:ёH��[{�z=�9ʽ��O��L���gּ�`}=}��#DZ��C�r��`����@a�8cs���7�Ѐ��:8XѴ��u5a��M�{��v����ۻ�oP�:�S�~m���v�H��];�z_2�/FШ�N>8�޽^�J��/�r4�V-'��[�zț��C��?�x�v�&-yng۹��Dt'�"p�^9.�ӮD��-E�h�OG�m��޿G��y���)���Q���!����PoO3=������n�k[ڹ�<���p"���.�R�|��Z���_�s����P�й&Fl6�ݑ�
�IY|���qi�e�X��kJow�o	~�i�܁���MG8�er�J}�T�pmKhb/b'�p��8?�~�JY��7T*3�]�e/�pNlգ�N�! �ܳ����r��u���)�m.ZTr�/�V#�,q{�Q��	�zV�̱3(��"U�1��Tֳ�D���1��B�\�%ҁ2��C� ���ٳ+l�筧�c*e�~�q/��u�c�臙�~��۳�'��>�	�B}l(s����\��V�����]�eZN�:�.\��G�X+4r3�0ɾ�m���dZ}�� �U&��K╖�AL2����8��
t+�
��'_�41�6YC�)G}���߼�s@%y$�P�v�M�(��]���OWN�6x�m8���=T��0dLՓ��Z����"#vR�JT��RO 	� ��i�N�/4i{Z�u|7��\ŋh�_m�;�Z(��0�!�/H�ތr�k�8X-���X-b�^5��ˉ+�s�+p��t�2��⵳lDގvl@��L=�Y���P��F��~$�����-�Ɗ T���_^�w��~.��7G��ФE�*��0�y6G0<�����^�xTm�A8y�5�����m<�G�����XW� �j���K/J�N�:+���7T>����բ_���ݤ�bo����H�P��}��%�ل4�06K&��d�Џyfv�}=�7���s�t�	�Va��}W��o��j9{X���$l��Z-�ڔ$T��+}�ǎ��[���-5���D��9���]Ǵ� ����`�)����}h0$Z��g#��N����P�G��Rϲm�d��S���ږ����-��������Ku��L��@�h� A�/�atj��է�boEyF�CYP��WnJ�q�k��`��+~��n[���hr	~�^�//b���KZG�?�&5k��l�L��_|Q�]��AK;S7x���b��5��zjI������pו�A�/�6�9�i3ݕU�}�sލ��Q#�I��ά���Sd/Ŝ�+�`\�|��)%��l
2g�5�.I�������bg��sgL�%��<��u>�6u�ٚ `�R*/}p1Z=�sc'yk�'���t��n_y��3�z~;�0�
E�r9�b�N�v
�rӁ�%�IU]܃�KrG� ,%��\��=tY��cg��vл��]�Uh�	qm4I�֒�+��-�e~-b�<Iق�OG���2�̡����ϓ�$���%�=�`��}�fܬ��SxA����+��B|��a>�"Ϳ�v��s��%�S{�툎���Y"_��*D�S�V���d�M��<؊6���=;�����խ�U>Nh��Q���Xرl�!�c?0�Ư�H��`��ymW����*�_k͘�.���KV�VQ����j�J5�h���/��VH%�`A���*�d��:&�D�ұ���{da�����Em��f�;lno�����jծ�Eg��Uu�4����G��dM(�[��a�|u�M.���E�p,G�袦���<~(yyL;C�Wz�%��.;���n���*����ܽW��Bǆ\nBmS�� ���؂,0���`k��*��"w'�X3cj_ ��O~8�MVɌ������Y��8�m���$=X�M��Ʉ6��[hGh��ւ��E�l�\a��򺕞�8��Z��]#���rKSuX���ǲa-m[쵻�M�6�;�b�FV*�{�E'�?9C�W
��u��
�P��5f\!L��;�
�H>���~���w�s%	�j%5Ӳ�/�
���7�u|��Tu"k�f츄y�^h�	h�G�S�W
�W�E^��'F-"i�I��=��~�zY�5㳡s�ǒ$I���H��&�u�7�Vc�8W�5��49�����b�p��j<�ň����p��IeZl%��|�u���hyβ��t2b*�EX__�FW�@q92
�����q�d�%7#��P��B�*T��KK��^eoY "k&�=�A��n�#�V��&돡$4޺�O��̷�,m_C��k��
�T�Y�S�.ӥ�1��%��+slX"[�{G��.3fKg$�'�A�{̅��?�ld~(��V��J06fRl����C<�.']q�t�u�|�;�ք��*9b�c�UT�.,v�j_S�aT:->Qy*�Q�����"�B�3�K�., �
b�k�O�7¼i ��S���y4��|C�`|��ؿ��4F3�֬��)�������ݗ��(��z�z��A=L~�x60��Ɗ�j��y{rGZ#�i�j�̼�źYZ�� �|��!.�G,[2K��O��%@7R�l[��n0��e��M]']=Y߻��*U �����"\���\'�3�����q�RS�E�~�_�P�.y3� �sŻiS��GR������,?�o�,KX�>��C�>&	�b?�+?l(���O,��^��y(�3T�ؙ^�	�xXw~R�b�t�v]_)<CSOsb�$]}\T�+�lFe�W����~x�>RA�*���f�S'Rյւ@����3;��d:�.�n�,��\��r(��7fwr����Ů�Eg�Zd45��ұj����*�Q�h~�!�ܮ	��!}9�A�2�P�z���̖�6�u��;y�aE���E%�G^^%) 1AH�2�T��:O�FY�2��Pȋ�/1[՘��<$~�u�����P���[���$��F�jGJ���*��v��$�8�Z%C����|���s;kO\�P�m��aN�*j��Q�NGω��)�����x�륯H3���/�S6�S��E��6�m��2X�(M-6���dR������-�n���2�a�j�}�߿<I��@=^����s��K����	qi������*�h�խ��Q����P�(����vB��L��:x{�xLG��sTg�	�t��!�Q��#z�˩�0Ձ*��
�Y#+S@�$Z"#k�0t��;�Լmp��eݍ%+� ��ZJ��C>P�ؗL	��٢��>����p�
��&�X�M&����9!�|J���&@�7G�`%�#z6�$�ϣθ�e���eځZ��*�����2����3i�A�FZ&
����~w����X7�d��
L�o��";r���-��|���t5�M�)��Q��ķhL)��+L�a��s(yY`�+��l�ow�#i�0;�Uoܞ�Aڥ�z��
@Z����.!��,�[T��-�f��~> ̔���\�2P�������zƁ �xAY�@�b�A�	��{�aäMJ�n��a�9�N��!���ϑ��0D��L�k�������L�'[��(*Ȉ���M#�"�&�����2i�"��+!�kP�q�'�R�&��0�񜓈��C["��>����q~G���U�d+u�uA)��������I����[�fp�8�i���LM%��\�o>�x���5���}�~�����Sv�,�w���A�H��Ƚ�ݠԩK�q����&�d�+鎻bz��[ź��&��Bj��̲�� �p� J�Cg`� $�> �e��'[.�S�Q̺:mS!HXt�D4D��:j��g¢�	��D�$�o�g��s��B�� CtN�O��\}Ct��7~�(���[ug�*��ɽ�-��jH���}^t�Cj^Ȋ}<�����)6f1�b�Xd(C�G�]u���q����í��4KY
��n���k���Y��@��0�j1v�_�0$�L1c4X��V�4��>#�@"�\b������9��"Apب�=����ݶY�iq�{�b�� �kq�-�v,7Oe)+��W��C}�P�!7�ǟ�<�ް��I�@spP�բ(�,}U"�/��+F���K��؛���,�́�ql���_pA�Y���o����w-Ag�.�Th�ڰ�&Q�v�^��@Hj$+e����6y�6T�*� �!��l��sh;<�`�"iD f1" %?w��&���Z4 �:#RV��3b����d-�tY*�r�!rA9��3��2�5��~iASU���_���ۺ*�B�#���'�<�&C��6h�j�.� )w�&k��3�GZ�4�|.t˩7��S>�,�H�9�}}���lfNݖ�iͶ���OFP숭�_T
9ʋ�AO��[��d�'���b��#��N-_@.�(T��e��#^M��V�Ky|�+�ȃ���(��&�&��ja<J������R+ş�p{V�"����Faد%,-�1�k��q�}�v����P�0���1:�n��9�r �
�|�m^j��ZP�L9�ؖ���.��[�r9�1GF��oa�:�වq���8{G����^�8��^H7G0�}��!+�����|���ݙ�`l��V���SpA��%�*�*��)� GL���G���_9o&�g��E��9q��f��B��/�#z��`��T�Ӟ���s��� /����o����@�6Vu��lg���ъR�H�|O�>^�#��$��t25'Қ(�����9�p*0���<�˳�e�c�t�Fv��U'|�"۰��]٭5���ya�
� :�+�b|B�������|��%�G� �d��Y� ��|~�$��@*%�eXcTG�2A�.S�X�ca�H���gm?]�o�D�i��&hB�z�Sv�,���1q�9�_}Sς��a�䷐_��D:��F�� ��_������g�c����!8g����Cs�Zg�k�K��i3	m� ��F�R�eq��X&z��X\uҬ�ƻ��j1 +f�%=D���G(? r}&{��p�IjX������¿�����?�:�ӓ�4��������d�x� x0���}PV��BZג\h�Y���/Q��M4�a�j0LLq.��M����hi��ۈ���� O�yb	w�Z�V�7 �;v;�cۙK��<tZ_F�q��!^�+7O�\�.�����'C<\��0�8#�qj�G!��(�	�0��}��T��ܻ*��s��ҟ��Q"����O�N�*ߧm�@��BF�Ƭ�BQQn�P�t�s�����x�+��0Z]��Uѧ��G��7ÎK�>��x��
��}��2�z���gV%h���o��/�K���}kI�d�r؄��_kn&Ò鹐���D�[��\�<�>�ȑ��RK�鬐ь��jt,��d�Q'� ���gG�0�bZ�"b��o"��>����'7�R�˂�vI�ǝ0@j��LB2Kyg����-bqw]qkNZІ���b��"�Ě��O�$O ��ehn�9'�uy/�vK�*4�ݔp�<�ݳ�K������@�� l����>k��&�W��ӱf.h��9le�}M�M��3N��}��#���PG�B�=A�s�'Kl]�ʦ[��(���ZWdnU���a�fվwt�
������ä���R���:�6B*���Ѭ�۞����a��sCo�\:!����_��ŻD I1�'s��{:���Q��x�BG7��l�D��E�8 ��$��7]nfB0�F��9ЖA��kC��Ո�&�w�W��������~����Ya�eV3�E���!@~�U������������=+0B�H{�*����<!C	.z�ˊ���*�c@�#�v�LP�����	�ٱ��+gBd�c2.�����z�NP�MD\�}�[�Z��SFG���|r1֐��}�.� I�ߏ�T��kG~�12��*ƽy$�`p6����S��$),1��sz�N�t� ��ieR��5��)u�ǂ�qz�كH��7���d��rvM�~�{�Q00�۝&O��8��i���<$C����Ĭ�w�\f�o�j.7�:^�n8� ����؆O�Hd-�|��iȨ�m��yH�,�aO@��4Q͸���_��=�C��w�X4ߓt��hz��P`������*m���j7�
.�+�����Yk�s�o�t����CCR��)�����/��`��K��i�,�zs�����$V�/��#��ID�?�[���d6Ut 3zm\�w��R�mX����K�"_�W�����v�7�єO�
��D���)�Á˟����m�$�g�Y�/��k�t �+ߡ���>*�b�_�^E��
%�|��f�T�CX�U7��W���T��}o ����ؼϧH�2P��|�Q>��so��f@?F��6�w���~��]Ek��qA�e� ���i�6M�t���'!�s��S.<V�FNwf�\�:�A,�S��V��D�� ��d��ojg*��A0�:�����|B �K�$�Ik�\�}����)u����[�)u�y�y�?�K��\+˺fC�kddUu��LTk�|d<�P.�Xk�#� ��0�Ri����)p�~��ʃ�s�b�Mmo��('/���l%�y8B��,��{�L@��~�!@�Xo�1 C�0w哉�W��W���rԞ�t�n7G�g����3�+��v��քy�'h�m���@|;ώ�>�K�c�|�I��K7_s�e��?�ݙ�D�̡#��๘P�࣍���c=1'-[W���8"G)q��]d������"88ryD���K��=f���*;�Txl�&0��db��{����Ѿ_�f_楕��O�j��س�q������.x�۹3�k%��W�Qd�۠�6a,`՘!��/C�#��<5$	���OÓ`��R
'�e@�$�H�y9���<mh��*R �܄u���˸���P�G@���7��j��/���@$�����үR�mU�b?�$�^�DM��{r�f����'Z_��)�y�_ۦ��oeXkH~�����ǈ^/�W+Vl�;U����JAƈ�K��b�2����֘����ðj����sv�,g��_�ỿ2���3�bh�:�)�wAI��l-7�6g������q�e�j�,�*��FM���F���n�������X�Z��<M�E껋j��8��)���EN"_�!H/ӭ)�I�&¢F�e����?'�?���E����<a��|~\"C¯�����c��+)%ȩT��,�{��x�L�*�󜺅S��m�8e[��Um�P�m�o�d��.�~��86�/��p�y�iS�'��i����(o�f86H�,�u!�.f(��e۫'������~��/u\񾞡
#+�L��P���F������6H_��1nu�O��l��k3��j�A^�ڧo߃`f�!C1�b�R)�N�J��_\�ϰ-�	!����'b0��Ӝ�}�C`o�A�N�r�ߜA��x2�ѮpH�^�y{��&`yB�(QL��n�0���l��:FS&� Ѯ�����V��
���-�:�G<Xx7l���y�:�\�OX�[9�H�5ar,�� ���8ڗ�7Mu[X�[��1+$\�%��$dG��.�C�2�Hj�X���.�%��͏�OLA�r�t-��3!_���2���H�D��ɖ�4�� q��'p2��8j;�}�N�\�ܧoY�s�����xT�C��%�s�YӑF�h�~œ��~v�p>��FT�����+��XM9��ߦ��U��\�/�a_AM׎4�:v��:>�c��_�C���ˤ&�
� �ɸ5�M2�r/����m|�hV�~^���y�&"H�Q�Z���V(�?������*�ܭ��$&��[T�Fy�>�^��c5I�!�JVNm!����n�#b*���Ux��Y�Vl�9/^XL^tU�T&�K��vr(��6�As�J��M�7�Oqsi����LE�y�����^�wPyS���U�=���J�k�����-d�{$٨^
o����r2�s��:�9� ��p�g�|��V*D��?B��que�z��l�\�E���7�*?��t�����#��ģ�q���PTCo�����ld�[r2E �|5r��!������	� ��<�E3�h�~Ѧw���fU��^ʏ�qh�^����sEಇ�����NǓ�<�!�Ăq���wQ��sn}&�=W��,3Y�����7����s�����Ѧ_��NT�+uz$݇8���!"t���v/4L fSG.���{c��*pr9�bc�A��>V���l4�ɛ�x�C9W�)�G�y��^�4��,S�k޸�x�E錧���qb�	@n��"�@����3*ˏ�Fj������7o���_J�Wټ���_�4T-T���F[8�!��m`��KG_|5�٭�p��3z:i�/1�901A}杦tL/�@"�J�9!|DR����
,��U>�|E��\��O��Y���!����x��bc�6�'���.(HkCMl�����ܘ�u^�;`�?Y�~����ʟ�;Aa'Dr��������,e��)�6�V#���3{�5[�/�S���� ����.�z-�(���()2C4*�;�[��G�����<Q�[iǍ��u�飰((���[� ^�@���#�jE��k��m�.���`l$ܷH#Ō�n���\�-Sջ	)���+x��L,I/�$���J5rݎ_b��P:@���F�1PhM�䷌4x���7X���ݕ�A����ŗI�Tc��-G���G�x���ȯ�дͿ��f��+7fC��=([���.�=E�.HO.���<�����,"�6�������[�-��T	�[(c�K=�7��ތ(�&ȸ������pd:x9U~F�o`8hh֊�l�L�/�T��b�$�x�~�?.��^�Uèw%ʁ~ԅ��+��Y�|� 36�a���q/����>eC�~��{�â��
��v��;�XEN�M�]d��M�%,^��l�[��������~�s�3���)�J����=h�ɴ�7�j�3	'���P�y�ñ($�VY%����A�\�XpVW�=���Dfq�Ϗ33�$�n?���#B��Tw�>)��������l��_&)�9)jo���GF�
�E]/�[��a3��8��f���gE,��?��&/�6.�3��(DW���V����c�Z���J��ob�,���e�.ᰦ�-m <�׵ՙuu��5�o��+sϢ��v�7�>b&��|{|I�F��&H2.��-p:팠�rQ����"ӕ��Q�R ֏��`�R�~�|��aĘ�G��2WE%o�r\b:�G����U��Hm���0s�'˒ Ӂ<y�?MM���D��kU3M(+_�d����n�L��"H6q�K���{@���8�܎���೤���Lj����|Baa>W�=�{Lg�u���s�9�s NX����ҮZ�'A�\��(+��s��{���s^RF�Z�2X�v�������ȗ.�����P&����{z�d���Jb?����w��Y��!��g�R!�<;`{�ܙ��	���݃�2�Qjj��)v7d�3
Q!"7�֌�,F��U���l��t���5	`*��
�Q �d��Nt~P�B����l��<?ؐ��5b+Z����y�P ��1�����*��Bò��Ʌ�YU�K*�(�,=���fh�����!�Ki��ma���m�d6ԩ�o�Q�s������������TK�?Σ��֡s�	nGfb?��,[�N��|�o?�Z)�����G�Q�̫��Co	�Ld�3L�"?�҄�g���atO�g�&{�� c/�;b.\z9E�l9�P��x��ų]E��o��_|����n�SuLi�]�[���!\�3V�#����6����Q��.�/��=�A�;��{�'����Q�cǿX���4!ї�|H�x�3傜W
,��!�:�����L
gd�E��f(A�B�,l�8`��.ҁ����߮�!?q}�\5r�e��Q���+�vRLM�*>�)���$�h�{Aƿ�����ˢ���B\��x�nb��d7=E�ö@k���̑(�~P�df�Kc�`j�Q����R��R9`/W�uX�J,�e���[�6���Y}r��r���X�GW�U��)�Zuu�z*P�(`�#E��JD}L��u���#��Z��:F�&��F��E󂓊ü��x;�<D��Ǡ�ێ�dw����-�{{(<��¤�
���Y~�'���{*xWE*S�B-�X�cD��u�i_��lb��W��]��8��zF|Ey��!޺�ZɕM8c�Q�x���BHY�5,�A�8y��X6Fm2�^F���N�6ߔ<���X���։���üa`_���s��WRE��~�G^��Zcm�e�=E�J�Wv�����OĴE�o�F,'�9X�e��I!u�%Ɛÿ���9rc�gU{ſa_�Z�<��gP��i���i;� �����ц�fM �HeT�.�6�X��꾘�d�H�SB�݉�UD���V�F�CF�t�����kB����q���0F����uA=݀=����ڀ�<M���9O��ݥL�E���.fY>����>m�.F�N[K*c�0 8k�?�Kvù�C�#�����Ї�̇�o��>��A�m��� ��p�f��{f������ �mD�賷U��R�w�H�p(	��2Vv�A6��(�F=#�>�9S�!s����ߡ�!F��c�|m����_���M·Ay�mUTǏ��N��	@�{�X����
�N��	�MhЮ�VO���~�+F|��=�Cs��jD��"}>������v�q�L���S�&c��h��|'@v��{���&i���ǽ�����1b[�?t�
b���zI�9��{�7a�Zw��)4|�(F�L���d�.f6D��DI����ݣ��Ҵ.Rf�kG����6���]p� ��d�
�韜��o�j�Rwm�$��)���Q44��D]���Z�{{�0�fy{�G�~vCG��%ő��
 �;Y�G�L���ǧN���z�g�&
0��ی����a��3�ǤZ��L�|��3[G W�����B~�eI�5�k�l5�j�nC�нG�pE?AQ+ )�
�l�2�<{��<��<�E�4�e�P���N���f(��meklm(cn�^(���V�7'�I|�֍$"~s�p"{dk��q�Sg�,��֩O��4����0�Q��V&}�v���)�k.��۝�?@#l�I��Gֺ�p<���R��j!7�z&kDcq4a��B���]�pr@-�U��E�L�T���5�T��� q�fZ�� ����A� t60 h��x���8�x���:�X>s�A���m*��r�����{��o-g������)x��]��5"�[n�/ey�	�5�C$=ޫb�9i��1;��i6z����I�_)���$z��V@lJ�x����s�b4�x��{�멧��y���4��߆Y
���#�� �{����K�v�p	��.7g��'����M��Ɉ���������(��p7��' �t#�~g������J@�\�O��Q�H��HC� �W�3���y�t��^{?��x-Oc����ڢ�J�u�]�2^��P�y�`��5�	�#V��%4H�T�#�t�2R#�t����v�a��ш�ᚉ���7�?��%
�T�C�A��S�ݟ`«�XPDq�H��[,�%=n4�l0aL�V� ���#'��jfa��:B�I�\ij��	�Z	XquJf2���pH���ڣ��U�^���b�P���TK��"��H[�Sx%���\��l�>̟-��(c�TŔE�1�|��@L�#9���~�')�#�H�&wJ�x�&��R�W��b�sa�jg@�y�'佈�!t1v�����q$�y�od#]`g�B���Q]��0�����o��Rb�Z()m�*�1��h���.��F���vU�O�?b%U�#�J/ǩI�2jѧ������s�A��1=+\��S*P���E���[�8ֺ�!�.�ެlr!�]"���F�P\���VT/��)�������" f��\K����劙�"�s�f�8�ǿ@���A��M���&���%��O �`9E��ei5��Evm������s��u#g+�	�{Y�� ��	��V�ng�ŅF	-�L��f�Z׻Y�_G{�=��l\�GC�1f'ڢ��_KX���1/�D�rt�Q�fLT� ��%m{�vk�����3ǯ����K �B��I���h��f<�5R8R}�qa�s9P�P���dv?b�X��Z�{eS��lN�`w�M�z�:�߾'B搉�]|;�
l��F���j�v����n�/oy�]dp��0���2ɘ6�1��/�M#����M}I�����m݈�ą����H�C<UB��ظ.���9��9��	g�/�~� �0��7�-~����.���x���g��Sۆ�ln㼧ܡnZt�eL�tG#M9{�p���Q&���@����Mā���� ->��������v��g\Zj�����}�W[�&�J��v����aZS��#�Grί�f���I���>V,���};�"I�MAGX��np��s�|;a�&sN��y,�lTV��΁1Z��y���4&ՙ�ˡ�g]�
�B��{���?S��;U����N,��<�h@Yok��di�џ����9�^���=Dy���~��;��7P�^�I�.�A�z?�t�Q^m�S�P(�4��E�PX�m��vg�~�)���
g����v��������Hf6��T˥-�m���o���Fnb�G��j]���]s�JW���	~�*�u>O����Ͱ��	���$�����o��ާv�H���c��q��j��}m)-�+�z�㛝�ll����j��O�LV�̸\ϙI���R�����yRvQDw�|�gtb��ѴD�o�Z�>������JbEM�O��y�H cE��{�׎,@G1��^��j�e|�}X� ��Dl��������x�{�֠�����*�pk�>I��"ְv�v3���������G��@ 	@eZ��q�Ho/"����#�'��:Q1�%���XV���u��~ ʗ;t�U��mO2u�m=>��8�{-,���2�6�ޤ�PȖ�١9�>Sd���Vm���3q�# �4�w�h�<��0SF��?�tE]�cX�@j�Q[�L �	����ǌ�px�/t��ԇR{}){�}�c���*�PWL/���Qz���֯_`G��rBVG�eI����E#�h.�;� %^����e��7+��>n��8J�&/��U�\����)H��\�0��6Y5��ITL9��9�d3��M�Y+7v����S!�oZ�Jך�������la$��J�l�z�/q	C�)fq��g�Z̔�[6
��C>�%�hY#�o�a�3B�U������E���L,�ﺘ�ߔ@5��}s�L\n���='^)��QN�@��(�7����_�H+2���F2l�o	E��G%�����a|��*gii���D�(�����P�CPw��{D�(�U�/��349ʸ�(Y�Mzs���?��H[�u~�v�R�D�ة*P[#�y�KyȒ1��F;c�ٙI=�Yb��R�ϫ�<l#����j�m�ҖJKd}L�0)mϵ���I��N��� �FZd{w����u� >s�:݋m�<��D��a��i�΁G@w� �7=�����(�`7�]�Aj�:�e8��h۫$�-�K�d�bp=y���%���2��Z�Ѐ��Knly�6c#s����~a�=�6���y�»ye;N^a���^d�/53��'2��ְO�,'��;����06�0f��.$ A{w�?��ɢ�p�������5�tǪ�J��?�����
D�)HuȹSf��bZY�y؛��b���!������������`�1��l���X�_�u����+*�iG�-�!4Q��|{`9���R���E��p�p&��lm��U�Ss�`r�'s�b�A1�Q����5�ESm�*O�ڮģ�Muwl@�ǎ@T�H��>�?�R��d9�s���kB����8�+�J���#n��&Չ�S_�gT��"	{�" �o+eSQ�("�`��f��j�oz�E��v�|W�d���7�T{[����(����"?�QٯP� {*��� Z$X��:�ݩS`$�@����N�m�ȋM@�'��»�|D�T����l&����b�k�|�t�"�GF�b�ʑ��F��p�4vL���S�	�����c\�PHR@ mth��X����4��Z�p�ao֑m;V`⢤���j1�5��3˨?�s��x_�<�X��Hv`�?��O.�(h�݂R��.��Z��_u�v��^O���������A�s%mT#C� v�3���J$�o,N\���s��V����L��(��)Jh疨wr ˚K����To2�:G�b��� E�+o��.h�A'*�au���ʆ @����1����um�_vA��� GvSsW:�����@����4�3a�0"Tₛo+�%WX&�b�a�G�%�|�pR$���Gw������a���������#�`������h���f��$ddڸݪ��ؒ�>6uv�K {B��p���z��R;*���=�ǋi�Ѭ��ċ���vDD
G3X�D���ޘ9������"C��H�R�sNr�?���i0�o�>�+�$�*�Z}o%�ϒ���`*�Ǟ�r��3?�߼}��e���z`��rRa*(�-w�~�u#d��^aʰ$�kgh(�!U����u�!��W�^�?	��dܳ�yۛ��E��,]d	�P�}�&�ϸ�Zq�\�]-A.;M�RF ��@�8�|#<���������>V'9�B%{z ��� ,��j��D���%��m��mU���	ȫ��eY>/�D1DXk��KEű+��pH�+�[2N��M�])��F&��gTj@p�,�v�1��:�pjlڑP=��'W�j��������ȇ;��揸a�Z�_x�y1�<��V��Y��C:E�k�{%{��)��O R�Ƀ{C��^ѿ�7��7��H�B�ܤ��Gt�������pi�i���"t�4O��r�ED:E�����=0�soMPS.�A`�J�"ܠ<D����2q��ÄS�(��A�����2��<��;�ȴ��%�L�nG�V���O\��A��R&p�5X�>�"CN�&R�1�M��Y�#���u�i�[$��u$"�`���Д�0X<M^t��QHy�TZD���D6���e�d>B�ۥ��@���`x!_g3S������hqp���_dܐ�$��ZD�2y��Mjm/��eC��,Sm�Z�]��;�L�U}稬�#�WY�����+�r�hYI 8����ϧ��K�\!��H�W����ضK|��ܾ!�NIO*ı�L�Dz p�,~I�ۖp_��(�da�\!�l"�'�#}9`�=̉�o�/����h ݾ�����Ke�Κ].�1����PU!��Ui�Ś?�%��)��R�t������S�~P�5Y�p�bP	��E���P�`*-N`�
���u}�O��/�d
��c���U����K��aÝ�Q Gh��H����_�"*��sn�����k)�?#vZ�(�"�4�}�鵚�iGõ�&l���(2W�$����Z����~%^���9�:o�Bӭ�`�V�����Z�
�
��Lk�����eG�<D���� �k�0���(]�2��%P:}���9e70~��l�lP�'�u!R�Y�r���ށ���^'�(���ĝJo �U�U|�dpǢ���'c�4�#T�e��tvtbh�OwQ�\��z����Nh{�B�=$�=ӯN�<��  �:NQ�{���Xx���WY��4��u�6y��֙�vN?o#�w�MS�M����I�,�	X�I#A�F�x��,����gT�G����K?�s�k�ڎr@�]uJ.Z��T9I%@=�1~%�+��*�C!�_^�1���|��HR_M]b�U�	[6�V�/%�`�MӷL��Ur����y8Q�@��o��u�٩"ri���S�ܦ���Y<-�y��:��EوX���s"4G����7�(2*|w�	���s���<���h�tZ/&�1��<�%�;�M���r�h�\=̢��~2���diDH�����`����ф�T���,�#�o�W��$Xl�	߳6��g˕i�;'��ӂ�e����_1Tn0����Y�V��ה��c�|`��1��G�~@�Y����JE<�lF��������A�@_�v		ec(C�p�l�rX(�c��I�DK�%6���x��=��ǿ�'UKV���Z�}�s猸�ܬ�C�.�uI�Y�^^O�\�r���9t��r�[�6t���!���{����թ�9�aj���Fe�w&���'�2uK.n,�l�Dih��%І��/p�=pm3-�N�Y9T#�j^pbi�������"�Ϲ� aTҋoz��1n�������>���bk��Ӏ�2�A�ۈD�~�JnL�9�u��]�k��+�9�Z�~�$�&��]���|�P�Ҳ�:�F~]��`{��9�aJ����[�D璢z#�d��@}��&b@��2�y Ϣ<C��t�����{���j��4c��0�]ȁ֗�}��=\�F�X���Bc�����y��L$e�HH���߸e�D�~Lvw�۝�d�I�l���c�6�����q��@�=��(�3�u�1*ֺmtr��-QÞ��f�ȅ��>5al�tPY���u��+��eU��K��q���c�KXA�0�ߊ�����$�c�*���i�M`��c�Ț��!k��ᱍ�tUr̞������r��A&�*�c�?��_�p��7�v��;P�	KH��$�o�in�*g_��	��3����M��H65����:P�O������?��J�>�[K��ăe�(��v)���&u�����VN����)>	�)"��ݼo���4�]��'A�2<�ڍֽ�rC7|t6+ej��Y)����K.8��o�݌:Cc�p6ozy:�n��ݗ�b%������}�2_R?}e��]���|�\�4��᱂qCD`c=e��4"�/��g�,��n�I����w�j�]7_>��(o�,�2�"��x>'�A�
`��Iv�iVj��/,���1�1}�Dl�ے/TH��7�pZS����V��Y ���=��_���䴴F�!���Y�iR�w�n>���a�P���׀L�8��äXuE�l�ٔ���远[����i�^��/R���Pּ](�~4,�a���q�Pw�HkD�mQh�B�؅��Uyup��b��}�&�H�����6!"/3�D��7O���>63�4��(��6��m����L'�GjQ �^�� *;sܖ/�$�{w����3����[����Iѵ�v�ej�Z����!t�k����2#Py�9b�_[���<�z���� ��������ޚF3���s��c��)
����˝�-^U.f�%=�yb����%]�Kq�Y��,ʃ-��4�K���#îw�RO�|�c�jw�Äf�I�x�S����/�w�0�������x#cp] �[Z��#�
a5���\/� )�	F���6"C	��ͪ�z�V3�����
͖ �W:���D,P����T��踑努����̗�ڟ�|�!GGc#N/��G�O��Έ��P`4�c� 	��q/��L�h�8j?��*�$[n7��YA��l�|����⥮k¹��pK�r��������O^��k��[O���f��k������j}S�Rө�����"B����Z����}��	j���g������(y�cG&���I�8��nk��Ew��&�����,oXKe2�yOW���3`iͲ� @�p����Ϣ�&~�
{�9j�c�����Ϸ�fI@_��?�����#הr��c��)s�(j+�:�G���h�4z�Ú�Ζ�x��զ�Q�92��$�����+������4���j^2taxr&H��cD��f ���{��l*]��"B���mD*[xIsiJ�����;���&V�q��K&���g�	�L.bh�������}֬�1
�A����?vː�	8�p$�s������8|]��8�m�Fa�N&�0W��J;���
t4�Z~h�F��j��	#�gݞ�����Y��w���ah�;JP(}��F��n}2v��ka�)���[���I�i�O�V���Ŝ" �6����yUs��/������/�9�6�����p����\��2E6�����UW��`�N]��z	|��l���������%Bea=��v��Q��r�lʯM&��G�Y�2shC�$�u*rx����; �r'��b]_���6�st�Ҁ�{�([\~VX�~�V��{*��՗��$�G�,K̞6_d�0�N;��n����8����;xD�ݫҟ\��>e��%�3��-���X�5�p�t�ٸ%�B�:����qX�>H'W����#m���5W*������ s�U<���h�-Q�x�T�+Q��~��"$�Ρ�A.��<֌%;���������tU����J��dY�Ƈ�]V>�8'��~�auQ�����I����p�3>����_hi_=��IƑ��!(I���h�,������(=û>>�ƹ�\���]��"�!���A?���g���Ө�6v���`hY��օQ:v���1�-��`|�xH���f�h ����*c5���>SF�ܓ�l� ��4g8���L�=HS�A��gæ��A�o)�Ӛ,��S����j9~��R��a3��n�bY�j��ʦ� q���趘��B�𯅘%HJ߶M8	.�4f1z���֌G��� ̹2�o� "ާ�	��A��:t�}*�ܘױ�A�k�|t }ˠ��d��T`Y}u�J���:V,eB�ב�<5V�M9x���gv�@�{�17�^�6�d������^7�sV�-�.Dҝ�*�ž�:�Et����xO�h��c&@Sh:16D��$q���ď
��ڱڍ~ki���	)�.��d�P�t�R<�)hC��v���ڐ���[����½��Kv6��8�ϋ�#�EQ�q�� �+�4N�6֏���R3���h��]��8��&���F��R�6�3;ɡ�b��*�#�Fv�ö�'b�Q;���\{x�� j���*U�v�)f���!����Xc��q�)��Z/�a������|�zT�x\d���9���������hJ�V3$����vܯGi�vD,W_h������I�rI�Y�r�Q�^ͪP�Hޛ��ؒ�`�ou/S��Eݸ9&{uz��ꭠb�G֛�&���'@b���B!�����S͕r Y� | ���Ϩ��)�쫄+䷬`��C@��jX4*�f��]{�ŋw��P]�gT��&{[�� �;�9h�����cۇ[h�
��s�,�g,T.��w�ܤ�
f��t��а^��Ѯe\����SU߁R�t�pp���k� U�ޤI�]����x#�-�f���N��[aN'�8��s�axH���g�n6��'�.�n����'ƒjpϊ�.���c��h)c�fN2�'�XQZx�R-NA��Qg�_��U�r�D��4�a�+��4mIszڣ��㙇%�aĬFFG���ηa���o�4��y:r���ϝK.��d��.�J�@	�ȉ�̛�G���"��!�ͱM�gX��y@��:��O]&������A0�ѳ�&@�O��^D
.n�V��;����L,�����x���Ǽ���S�B~�;��\�M��^.�B�cP$��{� =�3��������3<�n~��	c=⢏ȡ̈́������(B%	v���������hǝ#��.�	*n�:�$���F[����¢5Ӆ�qB�H��>7rDOg�L�IA���B�@�Vv�,�����Km/�X��c�np�.��K?��C�Q�%=!9CV��>�D���XB�Y � �|������GT�Մa{�.u{��{�7a:E� ��S*��G,z��(;�������'��C-Xv���&V����h�Fp<98Kٱ�yh������<T�i��.�����jdO_�.�����?�>-��hf��)&�w���C��Ϯ��wj�E�,���I�t�^�p녑���N�O%�▋c7]!��N������������@�O`�T%��-��+�iĐ�yX�I�c��F�o�b:kŗ�6���jAe�K��^�]���{č��*1�-�.d�'�C�	�p5�yC]���"�ç_Y����p�(��)8k�8�XtQ��Gk���d` ����s��m��I��3���Y�׽&0c�e~����8Hu��P:\�^s��!�TY,;K���D��!_��&н�s�ɹ��\��U��g.l.�Cgv�=-����e�oyp`�9)B��Ѓ��j^��Y_ɱH ���l��Eԯ������m�`��o����͡9���`W���[ �
��9\���[!�l9H�܆竃��8>*_����6C��9 _����o�)�9��1G�U��N�?�%ľ�������usg������g�_E�1�ip�B6�F2��1�����n�l�u��P�JyRΟ ;�{s8-�r�}�;��qŭ>��h��hM)��Z�Nm���#օͼ ;��cAK����(otCa	5ú�x3Md��c8~���o�H�}���f��x&�y���Gˀ�x �P��ݟN���k��;�k�+�,UU�݃�n�$���s~�8���G�?��Jj��!+�U���P����_末��<m�U�-.�Q�o�\�(��87�Ϫ%�bhs�>(o�#��*A��I��_Q�~��@�>��ml�x���mw��Y���#�#f�Y���MVM�X�o�{]�.3
�� f�,r�h��ۚC
��nMv (��Q����P��"�+�������;$˭��0)`��A_͛��"e53���lOy��̪`�^���ՁkY���Qڷ}t����/���?��8����t�.���MT���i5��L�fLɎQY⭕@�##ab?Ea�Eb�G������}��1�?U��.,{W�8t�����iذ��G8&�Kl������QP�:t���jLLkP}�e����.f}d�G�'#��F��^���I~`�CWT��]F�rg^�����#Qk<fܱ�׸et'5Z��DX?WɓI+JY�!�πt���-3[�lcm�7v��3:�ˆ�#:��=����3�T�ޙ�*�u�� �������+��)��I��o݊��M4�;����h(��,��@NE�3�>�z
�����nV��"��&�H�z�ᨏ�V\�� T����a�&�^R<<c�[��FB,���/��ǫ���!A +]"�����IW��ƭ�f�7��u��Yy7��qⷒ�i���+8�ܠ�RM��r�Z�&D�hf���0;D<`r'ع�6U�Tr\�}ܩ��k���;��"�kU>�(����<>�\�qϧb�#RM�I%�X[��`��$�p���#5��ϸ���,�9|��� ����#\:�"8�������S/�`��'�%��az��k�m�!Q��U�ش�#���xP��n�'6b�IyJ-�6f�f)&�o"C�aAx)�\�D�
���7�=�������I�/�ԫ��7��u��v�Mfl�?�a. B��4�*���j�&��w��ɳq�[�s���r�=��c���h�5^Ǫ2;�8��.F�FBٷw�$�ݛ=���fn�`O�Z��H�Pǥ�
n�2W��wG��*��ݑ+6\Y��g���������M5���3��Y��#�%p���7�����JWe螺�������n�R�
�O�),����r�M8��jf��}�C��|������Ռ� ��Ha��+(q�i����M�	��}�r��?ћ�7���� )ˠ>�4|����&8�s{�* 3�R^����w�
�ޱ��o\��}��؁$����2���!�H��4��כu$�o������krV#��ט�ל�E���8f�Z���l=[�2���j#�z����M���c�E�*q0>]�ju��X�����;$D�t~PC+dNU�T�#���O�φUߍ�gQ7M�~Oz�o�jG7�*Fj;����N5sͱ��e�Q,f�l�1�*��dt�6�xD/�M��J��mp�1��Jʂ�����͂��x���Y     ͌LL%� ɺ���ң��g�    YZ