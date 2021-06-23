#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1148424809"
MD5="33e433c6d2977a9968f93e69fe6e70bf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22992"
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
	echo Date of packaging: Tue Jun 22 22:35:10 -03 2021
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
�7zXZ  �ִF !   �X����Y�] �}��1Dd]����P�t�D�r�Cl�|�&eM���ב���9�q�j��΄Y�H<XanĢ�+�2�NHɈp4'[�Wp�ՃL��>]0�l���}��Qx���M��W���b��fЩ�
3��C
��n�Y
v�*n,<��w:�XY�"��Q�������{��1H�RG'yfd|6J��?ϥ�U���L�B���E�'�0�q0 j�Q�N�X�U|@&�����>3�x�V4P�1��+�(�W����a{�d�L���0)��K�y�9�+��9�S7����|�V|�>
|����ZN\w�Y��1ے�<�=���W���?����:H i才9��<���;x�A������m<Е�,�k*Ǧ�l"L:������:3��Z��#��?�� }���V�k���Z(u������>q8���˨�+�܀�i��PY;h����#ܮ�z:�DaL�߂͖�z��>����C��]#�l0��=<��S�V��a���������I�����bn[Dj��?��_�'���#�������H��Ja3��Ʀ�������eGD�!��l�j�='Ī�FFd���^����9,�P��m��a�k]Z�:�ze�~�xq�N�A4�T�xe  ���.^3���1;&X �
M��+�� 6�FҪ�A�Ғ�5UW���ׅ`�i�ZI�|�C�0������!U�]]�&�^�7ǅ.������D�暿/����G��FeUa��z?��_�3�'�m��9{{�Q�3�
�s���or���J�ϓ�S���Op�"P�q��� �f�9�k�����k͋y��K�2A{$�0��؀�UVi�y�@�5s�"�@��9�z���+f����� ʂ\�T��2��:N��%�WLh�D�>�1m�j��ի�� IF��%Xz¤L�G�mH4���+g]Fݫ���',",$�����9^.%�p�;[Lݵz#�:v���8d�x�v/��2�����	��c0���
���Kb�5bL�*ߴ��(ل�
XoI���5YoF#�uAp�dӰ~2	�ĺ.;�ނ�f)�:�U]�J���	^��Dg%	�TF&PL^ɓ�����A�Xgd�B��z�@,MZ������,o��\D،x�S��YRX<E� ig�`��+�_w�O熱0��������.�
��E�t8���M����ĬY�� �U������C>Q��I�U'�����/�L�:����&�H��*ǜ�Qm>`�"^jy����� t+�:�V$���e�M����/��6��͓#��:���Y��<�P�Oh\r���6�eF�P�E�n����ٹ�.7l��/���Yn(l�n�F��#!��7��� w+�_:
À�2QR���	3�����&QW}�e֏������w^^�S,�r%_ja,�wv�VVM͏X����E<J�8q+_8��JS��T����ϫ�,E��מU��@_����uK@lT��,֤�bt-eNf����~����"��z�I��I�� �r|t��z���y�m��9���Yj���v�;���qfA�!�s�H��l\ߛc9�6&�T&�%�4�DD��Ǡ9k�l�vEw����^��1�A�����}�K�1�Y�d��*[������q�a)�z%��c>�b,�Б}��8��b���{p���*� �J�՘�I#Q�uv�]X��*O�R�ۤ�n�Lw��d��?P8.�0��w]{z��N)��/�ӕ9���Sͫ��*/�+�W)�m�7%�0կ��@LM����3#�\�kX9{齖��ƙ�pu�1cPIY#xp$�
��	�����`��1뀬�ql� αt��12M���4�!�R������ѮI�3��~��v�����Lg�F�?��B2y�[���ﬞbZ���i@��Q�I�y�-Rr��������(��;�H��1�_A"S�[n���lա�r����8�J�{�i��&���R_������K��f�`��wWw�kd��|#=e ��0�����X^Qg{�Y�������~-�ӗM;h�X����I|�Y摽a�����qz�=[m�|}p��R�R�洃+�b%3�ް(OnC4@���[jPZ�z� ��w֘�X�`(.*����()�/���a�&zk'z��+!�=��UU ��ɤ�O�W�"��Nv�W�r�I��1�� ��)�[(=�曚�$hn����rp��!@�־~� r��e��D�m��X�` χ����4\��{����.���0�h�"W�������V-�GA�8P���L'q�><�}R�Cŏ�++�f��[���-��·�]K3vJ�pS�&Op�_���Ƕlo�Jjf�$���m�� ����y|AF:p�03%-a|�\�Z��ť�]O֕~�y��4RS��jQ�|b����:���-�w{k(��<O\�oo>��	ĵ�A��׭v�64��:%���*j��������2[;���V��;��X�Y�jѕ9�Ý����{�ɡ��[��3�\c�1�꽵1U,Z\�Sx��V8޻v�[�=�%�Ϙ[�(8H�m���ǐ�Z�ü��2�h>x�d���f�����NWOӟ��7o���	��K_�f"e!X���H xY,�l�h�=�I�=���P!Q #x�t�_x0�2���E�籢)yS�*_�,o8a6�*lJ�e�3Y�{�_�a9t����4H�KWÜ����|����ْ�3S�Ou�Z�w�֘�����tIhR)���촏)��W��Kd΄u����\������d~�;%��9_�M�ޱ�Ƙ�d��T_bULC�N������ur�)����}�X�(��QL��6���4:���0�I�c;��vL�6���Y��_ߊ��;al��}�0�����'%����e���S}P!b��r��QȈ~�� �NG`�2鞐֨|+`���t�B-�Ǩ��k�I�J5�h`-��C�����HCn�Ch>�
?��c�J@O 
���d�u,tE�|�Y�O��<w���,	M�oᝣrX������2]�[�i�%�y .�H�����
kI�����g�z�>��كzo~�wd�p�&��H���}��P�JiLK���U�L��S=?��M��f�e�W�۳ M�Άƨ�Byoo�J�����Iv1n[��w��A���R���A��,�a��҃;�!��(G��"�f�Ө�jb�[#�X�1lś�x�.�]�ʫ�=�j:k;C�����B�	�uǈ�����\����Vl+��ÀM�&fe�M,0��U��N��\dV-���|\�Y
;(>����y.�`'�N�w��X_�����L(����E���}
����9 �������-ba�)����U�zD��<�B��x��^E�dA[B����$�(g�HU!��9kbO�s0Y��:-��|!�z|��@}�}�L�J��]�;�jb~׷i�bٽ��Dâ\��5=vĞ�Ua�*p�^1�b#�ʸ#z��-���5��l����y�]g`�Enl��6�p�3hަɕ~!7n�thQVм��*-��O�-J�Dzri#��H��e�kqL��ԉ{OVϨg�k�d$���R1�>�#C�.Hjכ�@wq��j%���K"��a6����
��(��'i��}�/S�j��-�Bf�3�:]e��׀Йg���}N��c����uS)�9��W����5<�֠3�ٳ��a��lc�a�^ғ�}�lx�r��B�U���7����O���ʧ��[�u���1��4�Í�� �R@�M���M��a"U�I���`��|�q!�'����R�_t����MUAhK@[	���U���Se4�3+ú7� Fߛ���l��i2�2� �:\��DPL[V��L�K��Ø"���C�JQ�IڎNн\��>�ej����Ʋ?�Ow1��A��Dl�)v�3`��a�0B�1�ms�"��m:�� \�. ��v�^bqq�x!c�ߙ`8��"孒*G<o�5,���-s�O��//�[�� T�69K�
��\uZ4����E4�.l��@��~��$�|�% "��$���;�L�]�!^׻>����dA$�Y�]�ڔ٭����af|�Axi-5R���ƿ��u�,o��M��!%H��:H�����kZ�قg�O����B�}���-T���G��%�>�A��P� �۟����;��]�ݯ��9݉n*��5�|7�a�)% t!Ӿf[8��h�Qx�r�e�uxςY�U�ӏj��2�?�ݛ��8�)5/�	HB ��JIq��,�8��1ϵ����;۳�O������R^�2l4xe���\��Y��(p%����i����Gig<X�5>E�`d���8��!��D|Z�)�*^�;���4��]�+�٘���T���c�(K�ӎ�?��g��z�S��ꮮ�f��⑟��הlM 0׍M�>�0��R.�����Je��
>����p?IkT�R�%e��Z�!پ�b���0{z��.�B�YgݬL�!-;�����3M�=9`W�:�������K ������1�-��:�l��	bNn +{Ln=r!��Xt����>iI����Vy���{u[�9���1Zpv��R�j��D�3l72V�u�r�.sE�M��y�����79��;	�z]!s�^����Z`Å\��H���k�Scq�kZ,��s_�����"^/c{�Y�>�E ��������o_C�<0&UîYp�bH���kb�$�{6�i:�����c���x@m��/'C� m�h�tCўYߜ,d�%٫D8)���.)�-�6�E����F �-�����S}�i:�#T��(��8�z��e-�~XA_S�鍯Xa��6D�ť�p.fm�@�<N�QOl���ޕ�|4	�SH�^�a�}y6�pl�_�BK)�s��[n��8�ƝB�>+�F�
@2(X�<��z����Cl����q
FE�Zrsd�ĮT��5�c�p�y���t����Fȇc݈�$�P7 ���rPb<�u���
��t�$3t�OWu�-�@������v�E�sc�p�S>�T��D`!�y26d��»ѽ�>h�O�Lix۩i|7��|�+���h ��ue)�+Db�?"���gz�6�\�(sm�����>��-DN��oV����]��<���9v������UWH�Yj�x�POp����|���I�}dp���/�ʹGvWgT���tn-���P�V~�Ɵ���t��"^��4��ԫ�{\���.�j~�M�	N%�p�& [�������	吗$}��_{�t,(̽��BLw�<82��^�磵�C?~�l�������Pg�<�oJ;M��n�Ý4��$l[;B���8����YX�!�X �����ֽ���o�N��7�0�*�R��W���A6�mg�C%Y�� �����.��1����k�Z�3-/���F�����'~ �5��{q3Z��[�@�6��6�N{(��k��7E�M�X?����~��> ���K��y[ʉ�\x�E���,�pcE�R���@�yH��O�%�vH�y!��5�R��gb���4��u� Q�"��.��H�~��M��WۆoY��l��<�l��#`Z��U�'5�5Ö����G�@m���;�� ��8M*%R�cB�����rL��E��r@7$��6��Z��+H�Uu'&J)�T����K��(��F�f��%>�]��]�I����Ld�^*��]�7�Q��C_*��u�*�ɿ�����pNO<s��Ƶ��"H.��`;�Zˊ.F�v���5�| ��8J;�0����|�gЧz�r���O6: ��7�US����j\�i1GU���u5(*��������|��u��ϔ$�����[~��o>��$:���@_���������t'B�F��$J~�iW�&M�����3[��j���L�Ө�����䩪B����K��,�_��7���#�>1D&j��	f��g�1c5;}!r<BE%qrYIޚ��2dj<�E�2�g��~.$R��,�نߘ�Nb5)�w^�;s�F̐��	����%��bG[���D�N����7*v�m��s��{kj��P����Q5Ü�[.]�0,��E�s�D��(O���_�#*R�&_�D�a(ߎ~Vn�X4C*�P�G��;����,��Ӥ4�y��o>;Q�j�Kt�й���L����*��e��b�90���� � )��F���)l΅�g���c~�Y�BCCv������ؐ[���ͦ�uu'
p��k�� ���~��1 ������|εDQ2���)�K���I�g�>�k��!+�2��f�C<��_���i����|a��x�U�ǖx�B���'����!Xr��)�kQj��p��gC��Z��
;E��x�$��I��O�2�v8BW����2�+�^J�Pr��&��Fs�H�WGOP����Ѡ�[��ɼ��L8\������d<���I0{-��Z����b�ӝ-������x/F���l=e���٢���B�_�T����x��6���Җ�}�뮱���z�V�p�_3�����f����Wk\A�>�m�銛�r]
�'([M������f͍3�w�7�x�b����C����C�9�O�՞���p�R�s�͊Qor�Ѥ"S��}��X�*gD��4�^��K�.�{ߺ����Է��U�������7+0��%��9P�X'���&�4�w{�Q�E,���b�^�nMQUn�a#�U8"��w�����t׀��N�#�8)�ԟl� �=�r�R�>Daq$�"��t��R&,o��oA�`����*���)�~�|�����s�	����MѢ�'��ށ[���0S�ā���3l����襚&���}��{��2�2��v�����w�$G�X��-M�(��9��!2���Hq�d$��2S';���HuX�(-�͇0��U��q�S5�*`7��c[������f�E�sm}�7�Kur�Ņ&�6Z� �϶�E�KB�p{�.��uئ�դc~뭮�U���-���Ll�d��XR�������?���I�+h��5x���Ύ�G륜>b#Th�)���&�oU�l���]f�695��SyBޮ5 ��5�ijw����5�
ջj���º�$�֕x�rhn��v	������T�ޯ���2'�܍�O�L?������\^��'O~ۄ"�y:5�01�ـ� X����ú'򭓶q�Z�(����{��!m����z9�;�>j3�&3���-KƧ�@�;�_Gץ}�!{1%��J<;��׋=,.��$tȊFO��nl
_���2���eˡ`��A��#&�����{"Km�զty6��]¼f<�[��M��p��ɥo?N<�婪=˨�z[�7��Sa��ָ>��Se�����%]��Z:P�8r�}�_9����uZ��f�������Twq�|.����OB�£kAŬ��a��J�9�,u,��~D��N��X��ʖ(4͇*� J@��J< M3�� t�����?�+њm]�	�t�j��P��=b�4'��jbŤ�+)dT��7K�OlQ:!U����%�4��Gf�>F���r2%�H\��r��dF��ۊ�j>�EA����0NQ��]��wp*�Y��D�~.��O�o����n�w�y����Y�*ju���E<5��IC�Fn����/ve<r_>1�ki�	��� '��}�ءn��`��«B�pλ�dgi�r�����$�\��#�Cv[^I�(0��w��n��e����(-��|]>�=xA�5� 'B��;K�����{
u���:0'i�?�ymE�q�(h-�|.��۴��
�6���
sƨj�/f��<ˊ��;be[6ʃ����+�	����{"�9��� ~yJ����Z��rG��_js�̠P��f��b}Ce�+��������1�[�qq33�5R�5GUc��$��H�dZ��\����}��x�x�n����$�O�L+��bY�Ͱw�8d����#n��f#[�`�hW�}���`�Q��̻����X[�����f��K(,?���K���w�G�!8y}��4*��b���1��y������e�>'v�{x��yv��Q�y����c�<Q�&�~Dm�Wg���� QI=��d~�C���C��Fa�}���*a��|�@\�w�4>fY�����]V>��L-�QW�y
}֝�b�i���g��PJ��\	>:N�"� �����϶7 �q��.���?Y�ʢ��c��z)"��j���8����Ukk�v�Y�v�CHF�=�G�\�
NK'�[��/dUj~��ǵ����D��Ò\3K��m�X�����zx񳥤S����q�A�)f�^�0�>l��/�U�k��Do�\F%A�8�����ī4�g���+���6�7غO�gt�'�����ص�F�8�CE�M���-�8����^ۧ�ƞ�2�4���ӓY��K���)%����5�74GU�g��-��ÓNv�Q���#�	�����&$���D�g�	a�%{�����zE�o�!��b�g�-w����n*�@s����Rg�����]��Y��
|@��C�y~�T{T��G+�1x��[��]
�U�lK�H�RlW��xH���x�-8�g�8�������"�v�78�l��m�G�@��co����>�=�<!�z���f��)��FcE�R6����ƟU�Az<��1�*n!�P��ĒiP���{RF��NW���2g�5Z�_�?��ɺ`?��x���܏��~��Sa�n�+��q;��� �6��3���k��l�E>�30H�|�31�5e����[���rr����O�!���T���&��0�]%���u���15�N�ƽp�s�7�ǀTL}x�� Y�&u�a`���xZ��̠�m���
���Z !��� �S�S�ڴYN���n��aq/p_:���d�:Z����@�לQ�Vs�$�lK�ѳݪH}a7Hc�Qӆ�q!�d��o�C�\}��5w���(G8���>���)�㕟n�3S͐�oe�\M�nb�c��ƨ�"�+��ϳ"�i����q(���G�oXr���g�]֒�%n��
6�v��_�D�z�Hn�|��F	�5(!S���I�!�'k�A�B����X^R�/��8D�G�ǃ�.�2�N��2��oDSSڗ��sc>�k��L�|�OX��ha��.��Ƈ#!/�\��i�� 2����,h7?1�z+�n(�Yޥut�0���'�E��e>�]
g͐�j=
�jݔEN��?i�_W@]2o9J��k�|�Yo�V �1��gҮ��>��̾��)jyq���mb�cDhX� ��o�efv��IU�z�Y��Խ�.U�
���W��q#����er��,L��k),
Sg�K5<<t\�$��,�A��.���CH�w��m�a��v�"wA8�o�n��c�At�BD����"M��9V-/��M��o��ߦ+ w��e�%h�f����U��L�Ǩ�,�I�x_���Z�A��
�+�Ҥ�O)e�t��� �9K��^.�lv�ǒ���u'�*3�2�t5M�R��S�˥�̄V�O�G)Fʤ�%�	�Z��'[���j�˱SKI�{1{��(%� �F�~|����^�I�2�I�CV�aIH�0��U`��q�**��H��!?7/ғ��7���m�����\X�z�|3�ǙX����c�$'w�D3b�r<���/�OOF��L���z:;@E<���ٿ"R�)��Rߚ[���16�C�{ ��Ӝ�P�Mi��f�xz1�5��ՙ�?�� _�]S�VAJ�1FxD��2��h�pU2�d.f�8	�1�ߠei����z�c|�q��"�	�3������h;B�7QR�n��!^���)x�)$���7\G��ݕ��&�ׄ${>�Z`�4U��ji_�kم,�mi,����%_`��,�sP�%�X�,�}hg�]��~I����[e<YU`K�������`C�a�?�NOž���7_��l�
d���h��;p��	�G e��^E��j��
��H��3���.�p�Q������(dUǔ��i61�p��� �'\�|\L'[��s0�@*ّY�����Ol�(�+�����\E�A��vؔ�1?���:I_z{�B�!Y�� �9I�?��V����a�mF��%mfM�V��7n9�- A����H*�$�����Am�L^����x���~f��r�D�狼(�$!��(�[��������C�R�[-h?������ƃ��
F�	5�i�Si�0�E�;J<�Kz�h#��j�Y��9��Wk�ʶ���u��׍�f���	����@���7]��q�X�9�R��j���igU�����(�m�&Bi���"��s�,�7Q�D�XB:k�W�%��]3�ը����*8R(�L�e�t��d��
Z�(������_��ۊ4P��z�i�<"b��p}�yF ���/��N�y>�vK�9��Q+IQ�hh��b�F�2�f4 ��ĶV��(�����ɕ�L�g������-h���̩�z���E�ӽ�H��G�`�+�����V�xg�tLc�i�n�4ͳ�=e meA�߾��\�đ��ZI�I~�sP~��R4�IkG�qhȭ�
�l�7�cf'&H��q�]|���n)Y|��d�LM��08#*�7��a�!�+3܋#�H�@���f[��mlg��V��+]]�N��C�:R�_.'�ގcŠt��ƾ�O��7� y��) 1_u��;��ՀM.p,�j��fx����9����~p2�<�e8X�	���X
ҹ���Lt��lR�����x�Y�O��Ο���n`)~ƌ5���&C��1\*@c@��`���­�]mO,��X>����C]"6b&c�o�*�K�[��)(���p6#�M�̦�@
.���.&��o4_��ͼ>��jB{�"l�1�*ovG#i�'���#BU��o6���t�${�ЕT`�f����׉�%tkPn�S�9ʎ�k�aD��@�M;���!�
N�C�� �}ݬk��#.27��Me��h1����!Z �Ӑ�
����
��V��V�}���v _��Jf?� ������7a��gNޚd���+���*�������xD3��c������q]�o�I�������d��u��|��Y7CP�q�s}v�E�k����I[Ii&�fȓ�̧�}4�mzM���+
����F8]�Md���m�/��N�	��Y���d���QP��s��� Е~�|����t�cop�T%�>����@���ѕ�|�S�ORO/��� �R�چ���G�
~��qPz2���EYse`>#�2/kF�
�����V�!,��޽��PR��=|�I�ռ��*�:��v���@����8C�H�eM4F߆m�\ٜ*y�(����s5����T�_ǅ:�&^�Z��ʇ��O�B-oy��S���ƴK=֊d��i.��� <�s��>����<��C��P���)�=���ј~��jп2�������-��y/٪�:D�O��g4���3Ύ��]
*��i���oUq���D��2���	��5���ؓ)�J<�;F���eT����c��jЋ�Fu��;2��E�f�`HwhN��4e[����?Y����<����;	�;#9G���Ι��;�<�+o[�Z�~qޖ�����f"^ː$y���#�6~$�6�q������W����c%
W�mf��]f�-�V
n��Jw9���Y��*�C�P�a{���AxH�T������L���a��z�6 B�"kg)*0�+	R�z35B5E	s�{T4Q���~��IĄ�6��M*��z{7f�|��/VlAǓ��|r?�����ǘ��0$/�җcv�
|2�Y@�g�m��du���L#���"�oɑ��z5ݽ��Li�8��h�i6QŐo��7�
�b�o�|/K�i`Eh�&(��ߟ�ڴ��4��l�U�3�!4�������X}�0����D5d��G`�wM�z�B�-����b���8���9߯^4��Y� ����{��.D[��AT'&/�=(��1�B�d��"���`�,�Fݢ�9���:X��^\��Ĥ�>6[�+|�1Y��&SI%bdG��R(�����Y��ջ�ٻ<�qx�����P���U��#y6���?.��+�_�(wdPw/R!3![�G����m� j������@�:A�NѠ��L,�T{4��q�2S��
DÓ�%��o��Xk̬ ������j#Dl��s�k�s�M�8-�<b�S:�C�~\tUE����Ҝ6]W5��9
+��S�t�Sf���C$�k]V�Ė͚2�����R��LI�t�;[��N���j��\�-_Թ������>���j�5�1#����1���V��K-�\Plln�;k:�/+��h�=�;����r�X�8c���~'��V�������x �����>�;RdM�����X����M.4^��Sl<�8_	�����G�Ex�O A����:(e�¨�ϟc�� _1�-tl�`���2�����u!��CO�� "�^sxAv�`�:d��ֱjL6>_��s*��n�p��@u��d�1����I��}z�Ke;�}g�S$��I�E���u�pD��S�_�2��:~�m��	>bA7}-D��(�ȓ�_k�0Hh4�:u���Y�<ߌ]���C8��UI=ivzk.���"�~S2�WAo���%�N�wN�Dt Z��"����,�zБ�V����q��5�$�(��|Ã_������~�0�@����X/rJt��@+W��\l�|D�L[T}>��`ۡ^�a���%oVH�Xl&����f��<�w��W�)����x�śt9�AD�����,��D��u�����/' ��U��ܫ��u����e�س�@ADko���Į"; )	�
���Tn���Һc�%��7I�{�7YR^����-���w?����R��jtZ发�6���Q1�m��.�H�҅��n. ��K�y������?M]HE.k�8�g{Ţ�O�+x��.[�e�zo�c6�.GK�_�qcm��u����qW�����ʾ��P���?� |Ӈ��@��$�Y��27QrJ���%"��ٞj�;y�d��;�t�r��:�@:����OR����׻�F�fޅ��i�v��������\��uE_޼��T`�(��1��?��p	�Q;�A�IVzk��kc˕f��т8Tr���%����J&V�l�^�ϥ�;:Q~��˺#Y��o���v3����PNjg��9�:�{]�ϛUk���Mn{�R��6�����D���?��B�W�!��a�����E������b56xcd	��2����h'p�ˠ	êV\��1Cl�+�Ҿ�G���3���>�$�t�E�u/�j��+N�o.n��з"a�K�/��y�{=��Kr�7P�*F�&m5ߞ1�1�LX��]ڳ՜�R
�|��:Lv��Q#���H��I�g>�d��k1����K�<{h@-�k��Z��}�����z�\�t��Qf�*)�Z�^��jW�T�Ò�
6�S@$I *�'�B����)؛&G�,��4���'ˡ�����Wu�n#9�w�zSG�U�ޡ�k�4��]�9zf����W�X6�O�IS�>����yV5�}�&�"�p:� �q	U@o١����Dz1G)-��n���i!'�� ���<��eA��.�޽k���+Dl���w���vG�.+��z�:���a>��t��^zS��H���m����Y���:�i�$��0���z?Uѩ��J�7��C�Cq���৘{7��h�(�� &p'@���ץM~��Mmi�ČG�f(�F��遥�#s�!J4M~9])sv������e1)�0��AVN�ۄ�d��wpn	o,�Q�W�i�[�/�����o���ܖ�s�#��ۯ�sˏ���T�����)y�Vs' ��ZR�I��D������j��軴�&i��s��{�A%*ڄ/牁�3�)R_ޡF���քj�`�s�H+��n��"��;�d"e��l�=`���Rb�r�S����k�۽rZ"�A"�1ծJ�������r�'=N��5�D���/�^F-���g�z�-����~���`B����N��p�'���ߖ�R�{Ł��cƂ�ʛP�Ք*ϓWp�o��K%�l��˽�A�m�;���q������5���
����}mF�?-�v��v�@��y���|V����%C����D����h���B��k?TNk�v|ȏއ��Q� z_Xh�,��qxZ��=�_����(Ɵ�)����Y�k�V_Į�?����ﲐ	��9����o�BO@�]E�����Ԯб�gA�<�wf��"E�.8�e�`����P*&}t�l�F̚XF�W��лº�;�t�V�7��kV�q���jY̧I�m"Lfܚ�jr�[�ZW�)���� �e�g֗�8����w�MbJ߬V�%�f+�
�.g'�۱��g��E��ʸ&)&��mفF&�K���S�G�e�Z��O�w{2�0�r�����T��;��,}���vi�#~`�v��NJ[�5߶��ֱy�P�q?�HuD���cG,_���1ĢG�z@��|��Q����XM��ϝV����ź7�gK� ���#�</8���"��`��2��pW� �T�3����|d�_;+�j�dԵ^b���y!�,J|
�s)r��Gj�F��
�Ҋ�J�=�ټ
s8k��J8֯砖�}<��Y' ������La+�6+����a��R�?���S	��_�aJD˼B�4\~s85&&t�T�=�mJ� A7��8^�~�!��KN�	�$Ѫ��&�3
ҫ������G�q��o�7Trڜ�xG�1UN(������ ?X\�8�jR��q�3�8Χ��dk�Ez$�v\%�v�!J.�h�hS ��Cw;��ɾOQ�2N�K��������w�ݏ�TÎ�u������T0��[x�0�p6��#���*�B,/��:q���݆������
Z������KIr۪ʭԳ<qY��ގ���dJ�:B��3�,�a-�$�.�N:��U�`�Ad��OxhX&Ȑ����~2��<
��b�P��ˌ�'뾞Q�X]>���� ���Ϋ�][�?���9Ό a+#��'��M�Z1�UM��n�]�����yِ���uY>����p\?�%����C~h�6Σ�뺻�����O=,t[��k-��{/=���fh��Zu`�>��vĄ������vi��k�4��bG���;_;����
��j����Ɖ���:��G������y0���	X��yN��̣`���Q.�{g����ON���?��������F�vL^�"�G���	��{}�m��	�9��*��N�ᾁ�hPg�tt�t,�KMy�o�Y�}G�cxş��#΄�Y��ŉu�85��/���7{#�]�N�b�i��K�KY������>N���X���ń�
�D+�KV�1���=��R^�\|�����mX�T+}�gGs�r�Z�:"��;2����2��7j�5�׉@���.�l�I�"���]z��Z9y�"���P��I��8����H�����F�_"�ӥH�i[����m�X�82�L}�b�8�y��+�>h���k��(�n�p7�L~^V}��C�ϺӻѢǹ�E����FaPG�DM;�P|[鋗�fg�!��2�r��n�V$�?� �����]�8�˰�L����"H�V����w��Zٱ�_w^��u��t�u�Όr�d9�&����X4��a����`yXƵ_��bZ��_��t_��Q��'�[��Ը��D\��^����rdf�M�}��N��0����q��1,�ZOA��w�6�`R�����<��d�����"^9]�u�*���i~ M
�*1�ˏ�ʔpn#������W1���\�p� ��|�.��]�dPW3n��s�+vݍu�u'BO[����F��MM�W���0�.�� �w�%H�&G7� UzE�`:@��X��Ȕ!Z�1��C�"泩lk�!E[Sm�Z�������s��x��q�l�>��c���uhK~.Sv`aH���2X^�';݅�&(`����3%L��h�۪x�ٹ���|W��ggv�2��Ck���,d���}�x��g�t�x�%���
\�Pv�!zo�"�$��4�	��YZ���c��iHͶͶ�}����x�49���m�� ���'>�ùJϣTH�&�L�$��c,J��8|���)�JL��-����5`/���y�2���@L�?��hG�F�0.�ԅo�[L�Y��'H%ꆫo	c_������N?y�	N\��ϐF*ޤ,mďEP�B
��Vhq�vDq���l0h�S}v����OA�jI������d��]��.����)��:}��ł5��f���0L�ī��j4�hjw��?�S�$8f���@�&��b�k��:��G�M7[�_�z��I�歈�=?�8���ot�	�����6Bv�V;��/�i���\߸�~po���/Y��4U���=5�ɒ�#��9�~�'a��I�X���1��m�0�S��Op4Ho�()J��ք�6��]�Fep-`�]ԯ@��a��tL\R��'���*y<�I!�W���!���u����h�Q+ �޳C7��bIT�(%�Ǭ2��n)��MAջ![ζ�]ܘ-����:�{�1��m�ފP�qNɐ�EhI�.�8�J-J,'���O���O6z=�{���}W�yTxy�֫���?����
s�(4G:]2)���N��������0���gq��2v�7<hz��փ�H��9��5 H�(g�7��i!�R�C&==j����vT�~Ŕ�F:MF!|�_o��?֔��Kɧ�Wp��e J|�l�J|ѭ��N�s��x�˨ˉCHU��eq��g�F�؝4T����;z.  ��ko���[oB����M+D�SQ%~Z^�V��;�7.���=���#�Ew[�u��~P批�|������o�+�!�؟6I��v�@���.l�hP�Kd�c�P�ɋ��-?��J�����q�L��>��yF��%a�0�w�bқ���),e�[�~W�Ǿ�[��f7>|

J4ǎ��;t�jm�׮?�#��o�9CTs��d�#K�Gҵ�DW��?F��������VS��Ԛ�2��[kdMg���u?v�����3�&�9~nl�ӻ�$EM���Q���w3�R����t�@�v�y��]gKT�ۅ�F�h���_���L��R�9Ȭ�3�yE���`�I1��t� ��F�!�>lG�y��Fvp^^,����$����J�����O`C�~�Jn��&�{6�_S�ƾ ��fvŘte5�jw��/��Kg�ZK�у'��<�V�L1�&��WYpx+;/U�%��+Z!���Q��5醀���ޣ� �r�N��(�~:2Hi����}�k���E�U�F9�ɟ���Ԇ�Ǫ8 ��YIU:��iL@�E�UC�w��D��D|�Ԑ:���]��DA����[�cK�`��}�����o�T�E�U6��'򰳑\�]f#,���tȜ_A�����`��Clq����D��SЖ�����h�g��r�{���M�]$$��Q�^�t[:�c��Ѓ��N�؁ZU؆�P�)Wh��G��ݹ<�l
_��*��+�d�������؂�ni�n�,<����Pū:�nT�8)�͑���Wc*-$�v�����Wg�RR����9d��%%�)��E�U���=�|�=��$�x�������d�<#�W7����n(3$`����;����Y}{�SU�XR(����[�:�t�Z�";_Ay1s�E�n�M�M[gw�X,C/��&�|+9�L���7톳���4�� QZ�4t�L+��ho+���Ŝ�E�e{�g�5�F��s�W�m����H��-o\a��{d�2��hI2T1�����)�3ع��?��˳LG�u�?��Ȅ7�=l��t�5�L�d+�RU�ݭruISylS�i}�/Ki!��hn5p�IX�-���O�� �^S3u�g��B�V:����xY����^2&t�Ȏ�l�BI�jł�������'#��N���ƈJ�!��D&7-���@���]�C�h1t �r_>���Ap���%��N��S�ĵ�C��1<������
�8[��L*>�wpG�͋
_k�
q�'K�������3-%����==�P���L��&ў�FB���ۖW�*��l��Z���ŦRr�j�����p����F�!�LI�gk�S_��o*�@�����/�}{��$�/�2�)��I���f��/l���!��r5��$�a�����~����ȅ�� �M�!��>�X\z� �>}/��� ���ڇ�����z�<
��W%2��-D���;�kn�m�u���Φ�0��!u
M1A�e'0����x���ҝ���y(�h`g��+Oc(5��V5ɟyH�I���B�44�5cx����or��ڠ�:Q�D����sj=^���/Qr���{�$��b,[�h��PҰU�*��&���99�����_��p�4YZ}�ʄ��$�7�������W%
 vνW@���Լc?�w�o�����jTݓz�?����YI,�g��H���m�'P��)�}�{D4˲���%����ɃJ3�:U/�֏n�t�hݰ��=�:������ۖz��T�U�i�Y�i���̜�c�P�Â�f0���\�S�謕x�~
{����H��j���'�rqeW(�+��,�\�RحZ�ht%h�|�`�"�A�A��<�����3e_7t���>ڏ����km &r�P�RF��񴂅&;;��A'� Bn���2,�Ќ[�*үx�CTS���?h�a8�e��L��t��_;G]<Z�ݤ���� �3+�j��$Q�+/�K�r�(��>��(c�%�X��S���K�?c뷭3�Z�9���8x\�8�1pV���w$T>��|[��1�Dg7✝������S��1�2���n�"�j�2L0<�����ئ�S:�鍑�f�9���[т�	ip :"����*a`%��&�#�RR=*�� ��4o������-|����:!R���0�;Q�:���|�mG��A	� K�J�@�"�>�����bw[#�*��[d7j�k;ߠbܸ���	���G>p{|0�Y�S2Y�jf���-�� *��kr	���=���:=�ݷ9c�8^7�~:x_2I �����=�Ȩ�T�FU�٘��s����/S���{�q E܌!�f��X-�.��ұP��md�Kv:x�U�t}0) 67k�[��䑆�[\�B�jZ�����;�_��J�s���a��f����	2��l�a!�W�wxO��O����#���˪��i��}_#15������$�)}��s�����Ԩ
�&�$��S�;yх➌�P�"��4�[p�B��P8�m�!`ϸ�(��S��H7��7Xn��D���l���O:HY^1��)�=<��4o���QNOL����_-]ABA��k�}��c��"':q���a�6��<S�v_�0�	HU��%�� {5C���`9�b=��)�<�4-p5-�i-v��'��.W��I��菎���+��:����|�m7ٔ�Ie�� f��c�K��� Rr-����i`���1�L���mnov/}k��\��w��De�6��������9<a83:��&~7V6�w�b�*�f��j1�#ᇡ��l���{6©��Qp(5�����q��#�<��K)\Y�=]���g0c)7AЧ׉�l
�C����
�b�OrKh��mr]$@�P{g�=d��nc�N__��U�Z��
��&��N�\�}��>�#�|�r��G^k����
.
����r��u�15�l�[(7҄׬:�JK5"�^��*#}3Iy��+3.C�g���a$t�3z��2�����J��>���nP�o��R,�
�V�g��n]�N�$���*\���ly���fu${�UrWG�pe�����9�z����>_nbP�Y�K�g��Rl�	`��s�L#��Z]� ���AE!3D���7����1��5��������̓�^`Yq"`��h�4-�e���w�zhѴװ�e����=��v���>�Q.����8�\��<I����r	5�q����P>�M�^X��XO�}��������g�B �AQ-F�8M%�FBS�P<��f{\6����0���K�V�d�H�d8"��ڸ\AXv�K*i�(ݦ6xi̒��*
<a�)�7��g���04��y �E8� ��4t|�ʗ����+�G�I ��U��s/ ���AW�2��]S���b'[��7��V6��9�����h<��7�4�t���)�$�t?���l��)�� :�����<GR�m3����&J�l��7^����\g�N����$}�Ny�q5�k*s��O�1s}�Q�]UH���y+0۲�{\M
�+�ͣ�~�pu���w5�B���
&]<Z,�G�:QjͲFmg�;�}�E.F�k�kӲV1�)��Z��J8�X��$��x����|�C��]��j}���l�?u�%���(�u�V/���{�p�0UsKO0�ҸQ<�0��G5�+S:|����l��-����h�y ��"z[k#!�������eMaV2�:<L�`�S�
l+��١/�����*�a=sX8�=���T�P��!/�>���R5>��
������Q����B��fۢ�� ��m=�u��ZQ1t}�^��d�g���%��c�@�m=�N��l�B��S��ĝ�V�Q+�YJ����Xr�}����t2�X2��>\�1 ��{����ym��cU��G��m���d�!���x�Ðl����Dp����\���%��J�3�A����OcE�����K���
^�|�2Ck��Q���Cˏ�y#t�|"��;\N$`p��+�*2ʡ����A��.�b��G���Jn��?F�	�ͭX�%5p�9S�r���"��p�-�$�Y�_�#�sC���i�Qt{��{�2F�؋r5 c���x�ȲL!����$R+L�8#���]��G��]�B��q+'۵����f�>���e�m/Y�w@� ��������$���g�}�k�?���x3�C%v5Ɔ�u<	���Q�h�:�qd��Pd�>�xy8U�#���$�� T�&��d���:r~'K5�4H���PH���|u�^����z��Ơ�]p�o�$�,{��SMu�Js�i���L�S�Ahp)ӪV�:��".t��������L�(��Z�͝?E4ap���C��`��K��:O�E�ӏݻ�-�6���6G�{�C��Oc����H��"�K��'S�{^�P��,�뽱���`
 p�?Kh~9��8���0'1�(+��8��l��1kI�r�fQܙ6�7T�Ha�,�1rmfm�\+|��[-*}1:CՉ����w0m66���"�cJtϿ�ϵ5Qq];MX"/���[� ������+�nz��Ft�o�q�kGU(�Y�)���ë�&�3���� N�;r}^u��|����c�%{j�r^���ܟ��'�r`
E�d,Wq��ig�z�_�Jg�ߢPp~ۂ:�� ?)�d�Wd��P���{qC6%a�E��O,��| �È)-?K�c��ְ|$�N��+���RZT�U$�~�/��U���}Ock��}����Xjk�IR�JJ������55��,i�	w��7�����>ѝ0!��[��#r*Q����ћ�0��
ldTz�e�V���B�?����������aPS��TbB�@��[���׵@��x($��r΂f-~-Ea�D���jǫ
.qN��uiE�N5t�9����'5t|�C�m!K]�)�9p���*0�Fǔ��-�XuUxC4��AVn���G��}�-��4[��m�܀N	Ա��F��c?56�y�_��q���?�H+E�a:���s�=�����X�;�+K��#o����?���F�v$�3=*���Q?C7���Yp�}Ba+������r@��6F���4�ό��w��8cd�;t1\�Ε�?�9���U��C��Um7�{M_�V��˰�����q�����n�B'w�4��2Xq�	gޤ��5��
�I3ѽ�
,w���/? @�� � � �Wh礣&߳��S*Bw(���|y�w���^     �����
� ����7�6���g�    YZ