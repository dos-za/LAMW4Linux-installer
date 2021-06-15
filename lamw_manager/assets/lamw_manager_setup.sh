#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1992652908"
MD5="d524e0b4a83062d931e12c9f5967c16c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22292"
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
	echo Date of packaging: Mon Jun 14 22:22:25 -03 2021
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
�7zXZ  �ִF !   �X���V�] �}��1Dd]����P�t�D�re��.z0BT���G@�ީ�Q{yJ*����r�)0�j�l��䱔�ɞ��T9{�*z���+��#I'�\O�Gn|%���^�9����Z
*��CG/�P�5����y+��G%ڭ�������2fЌ5p'H�(
�]Mk�zDjM����{`TBe`L�W�S�<�~2zJ6��j==[�m�`첿eg
Xb��v�m\��Һa�T��ZQ �6L	l�)i���� �<�RuZ�����|Bŕ.vfw�2=�z]S��.i��,��Q�.>[�����H�/����%�QA[&��Jپ�A�Ram��	|� ���e�ʃEr������H���%�e��A���iP�2�,^L$@H(��7og��Qz���E�����M`�G'TR;�sUK��+�2K+b�� �� Qz;J
N����C��W�R���S'��.��dX���=(�+o� �Z3`؝T��2��P���]A͈!�*��t��䟴����*3����]3�HN8c_;��Bya���k�u�р`%4�	*,�f�X$d�D�k^��ph�xbL����}o�Y'�����n��9m�eFA�_W^Ki��Y!F����S|n�"�ҁ���"W�GCz ���JM	v��
�1y�F������E )Y��~����j�#�>����-;G�|_2�9°��n�^"�q�l���e%	g�,��F�E<7�k3�0�#� ��qg������o����yp�G�:�v�Na���s��E[����c25�����h$]��ȩ�J�_��Z�+������h�z��0a E�?�Hr�Q\%�,s��\�;4(���k{iti���q{#&���H���K�=<:����U��k�z <Dx���2���5+�wΚi���WB��E	��^Kh���`��<���P�� ɪ^����M�G���֓a ��-3Ț���4l�_��P*��Ѷ�Oh�`��o?_!������2UA�~��p�>f�ΪIEzZN�HW��5E���h��ĸ�l1�9����fuWU|�U0�{��0�ܗ?�M<$��!9mSk>\�S�XDa����K<�X�,�1�j��3�_��Wkߪ�
�@Y~ު>��u����ӯ?h�?%�d��r����F�M�����Is�x�C�n�yQv>�[�̜���	�b.d�٥��t��R9Q �f�,���T
Lk�NV�O��Q��Ľ��n���N�n�&��E��A�p�y����T<A�Q���d�:T'^�{��l� ��ܩ	��I.��ڗ4���s+sF���;�CU�����V?���"~c�&�@|7	�Ԑ�˻����ih���};�+�4^W�p{q�6�5���d0��m	nLv���������ǭ���FҠz"�($�y��]��rU�X���j�Z�XKs�h�1N�5��O9͢�?i�{m��g�~��N�;�v���"��'S39�l*zHy��5�K�!�+*)�;:W�I�x2�UY�-�6[���J�~
z�Y�p�J�c�:ɻ��N!�ݲ`>��$�{���8c(��-���X@ˉ@����T��&�n��YP%�"�Ɋ��-Þ�����|��:����Qܥ�L,����3�x������[ԍ���OM�_�p��/��ؼ�� ՉB�R�y�3��hgrH����s�gO���'(3��P���E�X@�L.��z·lD���#��%/-�lYfM�
�����3-�5<(C�մ����yK!��<�!t~�y&�]�;�3?:��E�c��0Ӡ6��>�SD��hgT�jq����{m'�DG�Cd��sn.S(�С@���s"�,:Q����ă�"!�Y1	w['WHeTm�T�ѭ�w:��^�.R� ����SkĢ�6w��o�>1r�����5"����$����*��!�����[	ibd�+�vA2|8�(��r$�5�2"b�TE�q����~=W���>�J����f� \�I�bg�+�؉��©l�Xo��c��U�9�|�L~a����'m��җ���vd���%���MG}5q�⑁mk/ݹX���RH�I�~�F��e�-X��zN�������_c.0	�_����R�)�]���#��3��������~PPH+���F.Q�^W�p~�/D��	5ݙ�?�gB���/`vm��}5w9u4$@���R�5�.���=*��Y�l����;�Q$ư~;E�X�8��|@�7��=�&���w�֡�� ��ٓ�%��Oe)��h�Y�D�����P��W/��DS�����/�nƄVzVчC}.)f��)2eGҼef!(��'�y�9�Rޟ}7I����U�Y!��חgX0�侓�����hI��������n=EySDYb����y�^y\��F��A�J�n��A�޻�h���URp�XyR"����z�B�m.�7AXԫ�X��%@_�����(KN�Uo; �P����iƫx[��L�Τ;��߀�K��W��s�kJ�W��*@x��v������Mpf>�3=.�`3/L�϶P���l��X�K�g������� ��<vd|���T�C9r"E>=Xb���	�RLUĉ��z9���>�qv=��WN�p���yƟ�̸,���~��қWj�R����YY�Z޶�R��ҿ@�ޔ���!y�Xɍ$�fl��A�T��"Au���[����I]P��C�
��RZ���g��9��9�4���Z�c3����]���qx��:��J��m���i�V�
�������(��Gqh�6���MF��}���;��m�ny9�.����[9�!n6��ǍX:x�7.C{ix[׵�L��*q�\�%�'R%#&lX�7 m4+�Q�>9�6$�#�"�U�����Lt�h���o��n�1`��[��V�� �M�������MD�l0	O�N�(g�	��^KY�%��a��Ţa%E����3O��I�H��L��m�5eG�Hޫ^�����qF�����>e���.�g�}���F($<C�<TŬ�����Jd�����G�X�兴禛>�H�+]Pd��al����Ov��ŵQ���Y$$�ac�fYc	����c��_�Ӫyܨ��`KKB�T�&�8o*�P!����;;�"��ͫ����};J�4\LX�]\%�]u�7����s ^ȯݵ,�,�L�$�E[�ʣ�P��IX�dm��T��dպ��2�����r�@�~h�Y�޶��s�9�{/EOf��,n�.r�Fw����9XG9Pa��ԅ���dZ����N�P�Y������ޓ5���<#�G�Û���1&��۶t%X�m�筋�N�E��2�����i��1:Њmp� ��D]Ë���Ģ7'i�C�]�u�&��VGݩP����;y��)�k;S�/�uW�n�,�K�ҏ&w�V��$���*;s,s��J����#z =�^FvIP(��#2�"�|nSM��ղ����s�hƾ���M�5;\�6��}�ʧ�VL�����wA(�����͗oP\��K+�b^|Vـo����\��]��}E���J+��?��4�>t����ZY�q��i�BP�M�[�������r�����V䀆�6_��~0�8����m5���	�x1��P�*��=H��v�y��L��c�v�#Y9:�&㒚DZ�̰C3X�c�}3�gZ7��4����\��Ç��I@��XLt��e����\�$r�D�~���Ï�������z@1���������x���/�<��׹;_����N~�Rc���P�x便0 W���FF�0հZ�hZ��4��%��K4��knK��yOf>c���Wgɶ%gc/z/5gCٙmumt��;gx�r5�H�Q��$�At�G��s+��D��KN�L9_9�w�I� n#gg�mQ�
��\�$q#�n�F�jޅ�,3�S��ʉגeb
���N���7c����g_�uaqf4�T�E��ݥ�0���V&�A��	@X����>��|/ܻ��혧�1�1 HCg��3,��л;��g�ڔ��~�.R	�ow<�&��Z;J��X����h�ش�J'��e��_�]��z��/���Z�Rj��b��^�عYn�L�9��ȮQ��)S��μ\ ~_λ-���2�
 ܎>qy�� �����P�?���+
I��_�)���r@���-�Qȟ��Q��@�����՚e���J�icB� �]X�LUX���GT���YX��xB�\�s%~ᔷ�<l�1�և~�atWi�U���]AGd#;+KDm^҈���::s*�<3q�]IŖ���r��&�T��̉C%{��rPU�~�<�>9s�$���!��Ռ��[��ks��������
�6S����'���i,���HaW�^'�Oҫ�l�b���<E#5�r$�U�J={�.�u�6�^�r?��P�k7���J���O���H�}����q���n$6�'�"k|���%�%FJ*�D'�� scbW�Oj	��{�쮿I��ͣ"?]V@�6�E>DvA�I�_W0a�1V��M�<�V�~����lqa8�E�u���<����]��\�-7�8S3 �-�4(4|��z��/r"�/ngݦ{�۰@l��0��]>f�
�4����X��=5������AyMI �hE���b�HKk+���^��~!J�R��r-A�Pu}�k�  ��F+��m1N+k���_4l�ic�Z�6���<6�ɦ���ZJ8�Ei<vw��������~Y��<X��)g��q��B��^\s6����LJW{��HOIe�d�C0�)�s�@E4EɋFC������7(J�0�s�}
����]��ԊTr���'�V/�=4��]>O�-�9!0E;��!�L1P8���6��<0E��%,@NMyܚğ������@���;1��ɷ���A��U.����B�!��鄐���������	/kQ���?E:�#! aA��2y��]-Vk���m+(L]�h1PXn|�Y����~b����5ؤk�z�S�MMc� � �9?zk̗����]lp��n�ѣ���[���=�K;�25'^�濚�����9�;�~=���P������F�����M�@)��:��C)���pK�����_aZ���I��%H;�
ia�X����į��!��J�G��R�W%���|��M�"n"@ꬬ9`�@�M��ML�Z���E:As)S��c�Vuv��j���L�ս!���O�����3B�d[����I��WHwg��8�ǻTT�rC�OVE���F�;gr$�;���ERn��N]Q�~l��N�0Ġ�?Z�C�J"��8q�״���g�����o(��x�x�qË�O�kk�	��b�3֘�1}[������O��	�^�<�*�"r��d�Z��o >��Z��x4-��⿄R���}��'�>�J�lL��B���櫺HI����CoJ=з��WL+ ��4�~�k'g����6+�]�Hv٭�۩�>?�"XCp>��@+��NcG�`՘h��6�����4�� �b���ɉQ�k��/q�n�+N��mu����R�	���y*�P�ۚ|R���HwQ��uf�����X�����<�7�V4����-sU�"44�����R���[������~*����3Q����"e|�EfR������o�$��M$X�#���^��9�:�$�yw^�hktv���#<	��I�玻����)w)C���$g��^���Y��z��*Wx#���)�W6��{�6�Q;����9������J������+�_�W�JX.U�]�n�����\[�&�6�Ҟ϶���e����<�*�%�W_&�֞�g=�m��LM�/��E��s�^�g��40�0�nk�r�!�Pb��;�
y���b��6��&�Ȯ�p�f�1�3�O�����U��6����>��7�L��)��V� -���^�;�7��+��I_<J�������o��$���6���n�ٰ�|�ٛ^����卬���+��~��\5��>ˌr��֍8���5-�ט���������G^>�P�4L
%m��0d�]�q#y�B���*yr���6����i����!a.\I��J�Hف�Wk^����<:�A���k~l�G8l]ȭE Uq�t�A�����ѤJF��-ʙ�<:خ���O�Я�M���oh�~���r��tX����fp�tSڪǒ7��D��>B@aɝ�ʩ�R�Z��.|��}i���R��H̡�IL��-l�I{+L�=4y0�sY�F���,��k~�>%aC��;�_U�⾤w���A�2�Uk\��@��@�/�o���k��ݛ^(8���əD~��7 ���ƻ|�:��*�|�4�F�t9/���$��O�*��x���F&��%��QɍѰ:�<I�ޡ�1�c?��#��y	�j�����9е��Y^(I���ݐ��S�o�����'��Q��<�m��ɉ�җ����U�(�1��j��� l�gg���]&xW�D�b�T�����
��8=h ��<��	샂�g�I��V�[G�g���i��b�۽�#\_��ޙ�W���sN>O��ܸB���5
�����z�'cZ���H����K�FU�&�b�Wd�9�H��sģ0�_m�� d6na�fx�w�<s��l�8��c��ؙ�턜�ƼF�m�QI��=	D�>|���7����5
H.)�zK��a���������G��wñK�6�}����BS�>8�����0`�J��A�~��R��yJ�M��?s�N=w�%[�u���<�`xzx��{X���:]�'�����5�된�{*x�Vi��l|��M�v�c�p�����ؼi^�L��$���s�r[�CZ�]����SJaPox�	g�G�5�)5;�Q9�fz �M�3V&; �s)��ik����N9�ex����R�¾δ�g?��6 �
�b�������Ǆ��Q�i�eu^�����a[k�w�����pE�n���������뺷��<�_&O,�xN��V��cf�t��(m�`aHnx���~qc����v[d\�v#���Č��@a�� ^^��:T;�n��v^����TH5�+�����CT�p�y�R�#�(��=��;c�a�A��!��$t"��;���;�W3 ,0Z]�>!^��eVF�J<�坊�[�m�����WPD_
G����vwPb�E������m��݁�CN����|@2	��2�[�|g�h}�U���;�:���2���.�PɁ���N��d�$ �P)�G}����#mf��;Q��O���b+�v���n^z&�o�k;�a�Y0�_! }QT�4��: �6����'��"2�)���z?����	��{�ë�z���vf�.4���]͂�F�i��0]����́�K��̮���92wm(�d �:og����D�5�ϱh��Ds�����Yo���S���?�~~,y�h8���&�_f�4=�b;�gT}h�C�4��@�b8j�r�%�S�E��ŀ��)��t��)�h��]���Uraz㸠
��]6
#�z!#��a`~7	t����#� AA�p�m^몜�V�\��M��W��#�I�`o:�u4���L�/SӉ#V�#�&HR�Ԇ{��3�a�&�+�ie���3�)�4<��U�W�K�9�S���Jed�.�M����e�:(�՘}��W���>j#���z��޸�B�7�������1�A%Aժ���@�p�cD���*3�htq���ID}J���]o;1.=)�tX9���3G*6lL}�}0��H� �!���C��?�h�릤�C��:6��|�8������!m�nfo�'�!�u��	�@ҫT�k��q^������R�;���?���v(qN��9�k�{>�{W���)/Eu��^*��=��\9�cU!�(��,�0�u��7�I�ڸ�@'����č���W�"��ͥ�6hq2�z�sb���yX5�hX(��>Å��L/kF`%�솄E��l�0L�쁹O4:t�"rڥ�I�uo���Z���4u馑�*�e;�k�sM>�u��Zb�~�X��#���\����Sn��Z��
f�)� �!>� �6*�-��uZ�ׁ�}W�2�E�T��~4��Z�#����~��U�S3� L<� �����%vk+�~�d�4��3� ���%Lz6��v_�'���(y�,�dt�D�
�-C�E��b>X�@0�\#D���)VR��X�f�#��H#��� ��\�ڈ��WF�A�Ꮆ�e��k�־�<�謻I�I���(��5�%��|ik����#�b_3Ͱ\ ~���< ^o(�4���S��	B4_c.�3t|<z �\�h�(���S�?Ř
����ӌ��>w�����9���$��ڤahm�w��~	ъ�4��	-������K�R��������\��2_�g����Q��J%u��%��X�v�)�,�˟��~� y.E6�����G��XѬ�T3��`�J“�S�n)B7���ج���W]��j0�����9��� EUC���ڹc����[���x��
��EGP�p����:�#�ͷl-����=�|�J6o;�c�%��)����}-�Cv1;�*ƻ5R\x��q��fו�ר9��.���(D!��FOy�s=F����}���t�3M4��ɟ�U�CݗfgL i�O��[���'��" ���F�o �-$��Lؽ��f������9!I��Օ:�QJ[f����z�<LJ^7��1��ɕ�'�1��d/�ެz� 5�[��88yW߶�N�q�U�K��&�9���g6a_P���� �j��w�6R����T݉Y��tҏ}����M6/����=��!�i�!��)�0uc��*� ��Ƞ��E�n~MJ�g�q�T�|,dH�l��`���PÖ�.�0a�^���2�q�O�V��ο���w��a�%�c0�Y�%^��p��nzN9m��O����e}�MS1wkg,l�z��9wƶ�X�'-P�A{!"��M���9���/-��e�6F|�93��sG�$t����+���˺�Ä�o'�`"|�Eتio;⹗.�J+�$͂�_:�d�7���
�Xq�P���������>w_W�����D��S��-�w j�V��ɢB
�&dt��`	��������)�íX�ᆬ~��n]ȱA����-8��swP�|(��
� A�-�sl�u�r��n�����.��l�
� ���;�Td������e� bo��I�:���翜.*�L�4V�v ׎�S�����(�$ÉI� ����F<��h)���M:���+#O�� �:���\�
��<S[o���_OhސL����p��#I���ʎɚt5"������|Bd�29y9;��j���4����ú�����IB�-4CG�ݤ"�&Fu����#��>�`Wmډ
��¬�:�����[�j���s`�OS�vO
��sS����,6EY�$�E�mIn�}g���DT�.]M�j��Ě�t�n�9�� �
)�6�_U�M1�������29���$��eZI0�,��o͇2|��f�}8�'��+S��:�Ha��+��E��^����
����%w �I��%΃em�7��JS%;�J�XAݦNt*��"�B^w��ٿ���q㡠�]�_�7w��DTT�!��!2�o�[�`_���[:
{���E���Ϛ%���4��}�0�1v�B��?Fv�H��{�㱈x��������d±՘��{,z.T�2� X`�l}.6���G�8t�J��
�h��%.�M�A e\˥���5xQ7���~E� �*�t�4͖�|ޞ��~+1��tu �K[�F9sX��_�Gv(r����R1��c��ɽW~���{�u�-!F�{r�&#�"6\Q�]�W,Avz�#E(��4��K��Z׵N�3�-��O�|� ���nJ�?,��=�y3�<�ee��}> �+r��!�M�/.���(iy���s<�9ۘ�j3&��ɔ�.�7��3{�e=���pݩn���${���#Ƭ���۶y�"�OFU�k�V���$�:�RˁA�L���]�#�յJ�Vc���I�ڒ\���DS�'%�e��97�Z�'1�ֶi٫LW����BA'�h��o�|��������Q�l"O����P���o�ƶ��\�T:27jZ�ْ$�]�z,��Ӟ��fX�b'./#I_�u�|z����[LK�%�7��Z�M�|%݅�����;k=�:)�̗6OI�W�7!�RLјa���ĂeT��Vؕ�	����H�"���U���PF���xs8�渷#�"��]l���z/=��ٮ�����%�ٗ8����lyGBaJ�Z}���j��C�v�3|v?�}��!~�/E�`�O>8o@�Q�pĀY�"j��&0�z0���;e;�{���C��.�^䳌p^��ʯJKFz$�ڿK�R�e������+=}%��L�!h�P�]댚
��W������S)��Y���VW{�=f�	v푞�dV+XЮ� ���nRZʌ���f"�T}r�[���|fJ��,c���zI�Z��Ư��Kwa �N���N���(zn�� ��<)��Zz�\��" <��R韈�ng�ez�W�O:��$w_��$׮Yu{oUOF�Vj�S+i͎�ZNg��t0��4�zP ���#u�:�֘��gqca?��ۿ=>�L0B�g��$�k&�ae�&,"rY��^5�c��R�mx+�K~��qT�}�W�(�|��Qh���h�`���I��ǌ:�Us�iO���
%x����t[E��T��&��X W���0|���d�s^����ł��kDJ�ъ���D~0�\��F���߂���=��K�H�Yk�j��fH��+.�\���"+��NDyWl�.��!������h_��:Y�Ҥ�#�K� U9�����ܫ٫����GRjيA���\�K��J�������)i���Cϒ�+�\���/A0��ކn��_l)��j�6Ӄ�`��x�����a�9��T�qQ;�R&QC�5����\D�F�$�9��$��̈́�u���˜�DJ�S�v��#���)`������K\��X��Dͣ��=a9v�c'�}��e�!�W����U~�0k�
|�k-� ��%��f�A^�r4
��a�<�v*4�[�4��\��z�����18�ZG.��ȷ��x6 `�h"Ԏ�Tf��:�G�r�a��d�?6��*��|X����a��R2�.�Po[^�e6hL �7|�w��Ŕ�/�M���؏ڎ�����]ɕ�1�n<|܋�$z�czL:���tb�?��hhX���'S}������Ap��"K� 4����D	�_db�M��o
��G��r����f�iQY|�HTG����x���������L$��n�߂��m�~���5zT�.�v�3 �@o�v��ѫ��0ם��Z�����T=��2~�s�B����D�ˇ���W��PL����k�3l����Aߗ����|v�s�)J����X��ݱ������U��U��ëe�U�D���Y�k�1GV��0��t F镽��#a�Xm��uV����>.}�<�˖l�ϧ�]{�k��>?��#����LU:o�0����&��f��>	��੎G�1��(��\�؜���
"��C:�btp��3!~�<���� �`|�Z��0�)�{�,ݏ}g����#��k5`���#��4b�O��,��_��g�>t�5�}��Kզ��'�l2]�%=sAQ����0�dj?�!r� ��� ��af������m�f`M��ep����&�P����xQ^�~	�;�8��S�ESX�����l�4���0T:xޟX�� ��|k9N�l�8���&X>
�u��^�X�X�,Q�a�W��Eߎ�r)�i�:�YcWx*�'���h�t�ݠxzŘ�s7]2����0޲�ʥ?m�0�d.��G����vؿ���"�<�_�[�կŎ�r�s�T��~�uI!���v"i��AΜ�V.zJo3`�0�����D�{{�o���H� r
'g��e�5W�c�!yL�O�̓u��e�)�.KkB$�@,Z�a��b�6���
���&Ht �UP(�ْ��S8E�ş��5���7���7�Q��p�u�u����� ��C��	=��}���0}|�� �p��j����.)�;��`v�F��) �X�|ط5?N����f�F��ٰ��	H���U������pQ��&/��u��.#/W�6�q>OW�r:r�m;����U���:_�[���l��a�"���?��&2L�P]�u�m��_�}�+��iY�?�݁�����m`�y��❟�u8�����E�@��NX<zR�J�*�E�u��c�{,Q�u${�J_�+��o��� �)f�;��|��0��4��;��9�z�-��[7k����MI](k�Tv�x�.E�h�*e�E�����t����s���Yi�ݢ�^s�b�iҳ��4�U��=��y ���{��v�:'D߈vM����I�*�.j��痉��
av��'Pgv�
�b�@��GՁ�z.�/:~E�0���S���k�o�d��^�]jyaY��G�����F�v���N�q�)���#q���{��������`D"4�N8�S2߅�6O:i���^��0�ܫ��T `Z�vL���l�'�8u��N,g�Ľ94W��8/&o��k�����%����%�؍�[��P����f���P6y�����>a�8�S_\��w�{.�4?R�a1���{Ѝ��R�_�y^hd=XO��MuM+��U6�&Z;��t!K�8K<�}����ΔIE��4�C�#�Y�8!��j'�^�ꬔ��#V�u�M�YX��w������QȺ�+:(�?4��Mb��iL49�;۔�}����d�&i��(tᚏ؛��[��KX���C�A��l_�}-���'��f6-*? 5] )\�0��&��$L@�x�=�����A�j���Æێ���TF�q��&2Թ�}۟mZno	�/�[�#7d.���/���Tn�Zʈ|#�1!����0�p�s6ø�l��h����r$I�����/q�nQ.��C�ࠑ9��+(Z�p���qlv��L�Y6�oD-�,�&b�����57�y��CZ
�x$�z;,� ��c����\kU8�F�;�Z�Y����z/K��9�YfS�yg��qG���t�B}b^ζ�H*�X;Iշ3���T�O��8��B9�pyMH��3�tT	�׫��Xآ�c)fD�3$ �b�����G:#
�C���qcz�x�c\��T>����6'��o��~:���]���C�CT�w
F4��H��3Ɓ��R��/$��n�o7O��
���	#��H��}dR�E�1#�s3��=�
��/x��9{ �\�<H�]gan�V�̊	l�¾9j�c)�v���i>ɁSd�O�&��v���9�IF��T��"PIJ�{�`B��+���cQX��Y�"Y%��e�z3^�>#��Tk�ԫ�.��,���*��s9F&��3	�b��t,��KawL���T�v�dvk���b�f�m�+9��eRo�Śt���zs�/���#�k�ס�~v�������#d�ٖz�,|n=������
�=����m�#��WEu??�Z�g�'o�����M�q�s�yiԃ�u��o�}��(nU���ybAߴ��m��`ܭQ��	,��-��T(����F�����73� �,��d�idb�k/O�ǂ�&�T���-���t�?B�7�l�bV�[�w�gʘ�4;tL�\ThL.��[��*���փ]3���C����Ŧ#�������v��#4��"6�訜Mߴ��-��+)
�Y������B7�ũGTu��Զ�*�s�"�I0�9�NI���aPA�xv���Rβ��eqy�H	�Ԇ�mP�y��3	Q`rRT��s���r�Ak5�v��p�H�A[��#�H{p��l8&u��6���@�XU>^9�d�gu�ēbV�M����|�HK�xD��4?I
U�䦠�	(��iN�G�� !��wU�\� �,/&�.��Z��Nw԰���{�ͫe�W�<>���}��v��J�$'V6�@2c�����b�a���8��`Y�]b��ƛj��[z��������N7�D�8��y��z�p��[\�Dd�C)��6/G*&�Xj�=�o��:R��}`>�L���zf{2�t�Dv�"��'�z��vP(	��#�U����)Oj�P2�q.�d����0��|m�Z�X|�����~��I'a�B�$�n���
����oA�Q��{h�N��мws�����84ܷ���'������1���4���<ږD����b;�`q�	��O�x�S��j��x�������m0cV;b��>�G7S��}��T� �}��~�0�&�˲�?u':�~V�Ǫ�`�z4� ��0��yj�vW�pDH�V�,�7}���pG^�sd��X6��O؛(L�0��h�g�l�_�:�o�;�NN�{���ß��R�̛�c+�([��)K3�������V��٠
#�?Eo�$@����؄2��QC�w~l �vWi��b��p�2��0؎�b�Qt1��6���$+������Pv3XS�m�NН�.zĈ��޹.�u��i��2�␍|M'/��Q���-^Tu�z���z�� �T�yf ƂWae���5LU]b��1�a���A)S1DP�@}q�&YI�&}��Ps4�6'��oG��C��ne״��jh��R����E�zC��ä�3��YP�!�Q�8��F��n�������C�V�=��h<���G>��s+u�$�j�ĉ�t@����������	�	�;rU^(`8n?��_ͬ���b�}�f�|�#�G�A�5�̳s�(�8$8�V쿟��*���B��#�� �</O�w�S�7F¹��?Qn݅�RJ+��sZ>�F��<��~��d&�i����������z�̐��VZ�8������IQ=�� C#�[�>�<O��k�t,A?�����m�� �������^j������}5#Oft�S����@0��O��J@6�'Ɖ)���U���>?v�B_��[^�v�p�йO��$vx��g�G骽W~�6���Z~Lx��]���0�p1��l�ĭX�����6f��.r����	��b�Y!��8�[o��v���n��W��B-�}��c���2=���*��#f��� Os=�(4�����exue]�����rM:�I�h��9�&T�fo�/o�����M���XS>�Q�uYv�oq��p)��ܪ�������ee�)����b�!=� b_�;�sy�^�a�^��bOY9k�������
�h��fw(�a�2vy�/�B ���T�YK5<�J])��3zY�ѡk�z�Nw����ї��HIDS�h�xk>��.�
�����̾e��xg� ��F��(�I����Ʌ8�VXGgT�ff��j�RN�3�ͥ��>P�ÍO~X���V�45%=��D����]�7\!Z��� 9��b�^*�:f���;�I	�1I��tB��߹H
�!Wz�/*mrx���J	G�R�(��߄�C���E�)M�#����{�Ve%g���ځ�@m���� ��ۉ�	�9CEk�
��5��s�ˇ�J��(t#�C��	-p[�q@T�����/d�Y��'s�O�-��ۇ��ݢ�zr_���R��6�I�>,`�Ю�B�u<I���F���E���� oLD����Q�m�CuV0�G"�����3�m廄������x-PD�T��n��?�sR�#:gQ�X�乺��jy[�K����n����a�7�#H�y��F�uj�l���{��Z�۝7\��������٫i �z�*Wϵ/iww��5�(H���Ӥ���FJMqh����T� �EŒ�q�\_h6��"a�9�L���09��O���0-ƐR�x��XO������� t�{�a޳S���B*��r��J]�0?ͫszWh�j��Ȟ>"�MFFV�Q�����@�B�f�fl�\��9\�[�n>@}�\�.p"]�\�Z��\f��o4�5��	�Qi_iK������g�U��~L��8L K�F�B׮���-e�U/T `�9�a�O��H�-W���Id�ƃ�`�u�!ϋ�f����N��bH^�p�,�P�
 z�+џ�ةM-��i�:Pd3"�1��#R軸�Rc C+i��]�댇6p׮���4�&=*�Yy��$�*L�LL`ZCT��X�h�v����N5#�P�.&f|YWc���(Oب�  <t�����M�����y�y��,�����NS�M�_��	����1w}o�ۋp��5�H!��n���CS�0����Cjof� �}����7sa���TO�$�x=[���K+�/h|�[�Q�jC��4ve�ح)k����B�TT�GG��1_�o�}�R��7hF�X�q*�<��F����N��P����E����	�0��c��ԝIx�|9�@��4�H�����T�Zθ�A����AZ���.-S�<w@��j�9Η(e��X����� X�O|��<T�x~b[,�(sЇ�(G�T??��3�Ӆ��^�Nl� �����E�*;�#u����"�e��a&1�!���:s�!���@,Cne`虥�;�Q�հ�yφ!���1�=�=]���4Hi���9z	�)ӵ���42���I�a�3LX �טּ��K�V��>-s葸�ɫ��e0�15uG�#�j��b���p+�cs�3Fތ�0�g:&��d�O����dW��+��gQ{`ϖ�o�N�jq��p���rST�o��wFZ�iWE�D�DR�ǥ�F3�6Ǘ2��6�k?Y����}l���Zu	7�r*�Dr<�vg������T������Of�
��!�m�~�>PB�)����Ϧ˴���RLigo�ԎM�
�w�z�1h��L"V���T4n�=מ���رu!&�j�hb?',�45m���7���<��j�[R��^�>
�م���7������+@�b���p?k������K:�WkVhrJ�w=���y�;N�;��.g�<E��&C2���@�����&D�^a��r���#{�����XO�3ʇSH]|X��~��:������51���7X4���T^�1.�Y�t�F�g���둛�A�iI� %x��yT���H�v�ߌJ�����M��2�?�b�8Ty��sL�mJ�i����-�%���Q��H!�z&D7͠8�wNT����n��RiAu�g�y�J�Zn���c�y���+�4��e���d���>�L�k�"��Րx�P����$j��'�#Tle��'<�<�')��<���p�a{���!�;�W% !X�Us�<�T��o}�y�g��qQj�~�o�v���ԥA|Y��컄Y���-h���H!��3�o�J��x�d5,i:D#�Q�^�eJlҼ����3%���z�m��X�7g�{9϶�J3{>Fh��e��L&�u
i��B� ~+��z`r]R��pB�ƬzIce���i����E��oGx�L�K}����R����a:�9%��G��Z���>��c���lxD^y���F�Ɛ��6��lYJ6�p�p�ؚ-}����xP�D^DW	�柾޻��ڇ�VR06ԯ�"	2|��m�D�ERH6�П��e��RP�d�� 9�ׂ�'�kZ�ѣ�,�Q|�O��ǃ3E\ԁ&��5~8�����i��a;Ubo��k-�Nۓn�p"ğ�*U".x��2�7���
�K������܌�+mR��E�ZP�- l��$�'�y,���7��� � B�ȺB���*�Mϸ�~
`���p!eY��a�0��Nԃ�軽�]�&-N�͈^����n9�����>����:��K�,���s�����2]ژ�ʮE�IP	z(�b��;,<J�Y�>�\i�l���B�H���!^z��%��x��#�NR���:b10z�U���ګ�	㑕y��/?s=�M�NlΈ��-�4y�c2�.'�a�1A�9:�e� ;�d�T�؜�����l/��>�Y<�>����[�TC: ��}�dI�S��Y0d��ٝ�J�:`����0��7�agy�C����e6Ԯ�����jI���d�X�Qʺ���򾑍��&nA?��&2e\����.j�b~�TX�j�]C����aJ��0�LTv8�����_�/�k��W	VH]����)*���c�84]�����_T��S��]���8�i4LN��^��>?��X(
����%�`�n�ª@;���<2���_"((7m���z�(.oM��ژ����Y%5�����{8��ߵ�Y*������O�4��&�A����r�����:�O�'ܝ���?�s�U(f�8�1�����v�b��A:��88'˹� Ͽ��+ћ�&c��]�zn� �z���'J|��wW�!o�A��'k��(ϛ������FA*�����?���_N��@�u=��i�=n���tXZœ�n�m�R����B�6wnL��S*'��	>�4�C������[�p�7T��m�e&	BhF6����ME���C4���
�c�uȆ�W��*��� �Z���X��O8�Y�RElt4A=;J1eұ<�=Sf���rB����f>+mE ���z/R"�������8m	3��;ǅ\V��'J�"ܶ�;����A v?���P&�����f��[#���2���+�����W�T+�g��d��Y��q���!A��n��(*����v�+��ˎd�����2�����F)�GW.K5��dՆ��(�SK���C2���mc���vd��̯����K5B�b;�F�������
�T�6����䳠�Pֵ����ԁfY���'����\��8
]<,���^U]�Z���-w�3R�HC�S���tj�pȷ����#"j�]�0w��X��߹[$!�@�H�J�xAP�Ƹ@vO+�׳�)��t�R���Y>�J�_��$YE2�jK�MF�և����7���(�s����XQ0��&��J"�C>[�r�����/~9��4Ң��J�if\�F[GkC��B�)S@|�eQ\���ɧ�gw`E��Nz���#"3��;`A�W�����WI$:����|������,�rIm�w�����p���"9��5�7$�O���?s@�����Ӥ�oB��bS(�B�5$��y}�^U�(����&^��v�_�:G��l}g>�00��l����U�E��'.���y���J�o�2Hh��������>��H��ݠ��o5�;y�N �l��Ό~�[B����mq�����$�9W�'�bJ��ݤ��Xz��Z"*���<@N_rt8�T�X�ly޾p@(f
�i��	�b��/-T�"K�&�fz�O�ABG��==��Rfry)����ZYR�9�����G������Do-�9@g<���¹�'L�����I�
��N��ţ�;���G�����I,�^����Kt@dbJj�N�/G�	ف���R@`pQԐ��"x�2������=��Y�`'P��'
T>f��;6��Ť��÷�(�]�wV��+w<�l�;V~h��&���B���v��B��:�ϱ��͐uPUFm�Am
p;*CB��� �2�<~����f�:��H|��H���J{�;�&���{�!�͖�_����c�Hd�u�=MV4@�s���6�ryʠ�z�r�ׄù��U�ؚj T�@'X��tťJrc�'u"�7:�ЃDɧ_�$�츊�� �XjЌ���_�9X��~Z���g�"i���L��7j�@��$��Į� [g/J���ޯ=�L�����)��#r��@$�ӹ�8yĐ�>	< }�x���a�ZnP�H�L�� ���T͖Y����;]{��.��	���{�.<�c� cZ��ZyNh�¸�A���V�m�7\��S�4���˃�� �j�ǌ���zZ^}qS�8n���[�.�u��	V�u��~i�o!��.>W���
L�C|qT��f9\g�N�B�K�z�K,=����S����bfջ�����i���B�8���\�)%�v��_�Yu��c�9�	�65
W&ͼ�8B��r?�����C��p��-Eh&�
}88^���n1A�d\7����/��	�%D�fI��џ���_A�'hCQ�Q,�Qdm04�Hr���e��T.9��;�%��{�>/mm�N�?�TM֣-��T������ȯs#�/`��Kq��$ԓ���l�2�,e�e y���变�|]��U�`���{֎��m!2p9�\II��<q���|��@�&X�Y��z�I���(��F���OGک�Pj`"�/C��#8��(#d)�<�oy�f��_27�*�L��Y] 3)">R(��=0p2=�z�}]�h�FD"`�	r��iv�T>�bv�`a���r����O{Y�j�!X0и�����{������xM�˛s�O�F��d}B�a��T������!�ZMe=6��&�T'J/��Vo�߽:��� bz��O�%����Da���F;f��t6����Mk_k�Y�;�}�&��(����3�QPn%ܩ�l�fn�/�wi��c��%��/'��<�V��:��W�������%����)���6���*��H!���|	G�1�n�Z�ȴ��Jz�(��G�-��l�]���G�4(�����.8!z�1�}��['F�1��8�f3C1�MٽA�����v2Pd�����z��s����h�()$%L��"-J��uo�,ұ�Nv�q���e��͟zU����>�3nL��ʘ���
^P���ݭg��M@]���;ĖP�ؿ(T>��v���>ű��֗���%���Z�΃]�Tg�B+�E#���ex�ݬW�p��AQ�ಥd^��(�����v=���g�-�az���� �6y`$'�i��l��wl�I��n$��,�z*K횳���M���w�<�}~�����ʩۜ����W��!�OU�?h�C͵��4�kc�~���6���ͺ��7a��x���ݬ��I���MV��ċ&n��E~�:�W�ʏ9����8�5��t�����ͩ�Ѡ�Ÿ�NT�ֱ��(t��Φ���HZ���T���Dl�����G{K�e��5�\�,nS�A�����4�m���v@�z�/~��\�� ��Z\@s/J:*�W����#�jn9!�C��u�S����=�̰Tݥom��h�/��:g��=�/�|G�n�b:b��P���A���2����o����g6��7U��N{5��kk�_�����뤓�~�F�HC��k���x֐%��B���Dt�����GZ��hn��b)��a�Li����
�3'�5�;�D�\ܞB9i�S���,�O?���A��PucԹ 1m�S�!X|�~ͪ6�HH�v��w�p�@�:���СU=X����p2�?�;��(��m   7�PŊ �������g�    YZ