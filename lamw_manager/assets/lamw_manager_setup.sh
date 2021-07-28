#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3433863834"
MD5="ea38389ae91e7f73751331b3b03d2ba1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23356"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 27 22:37:26 -03 2021
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D�o_~��_�笁�s�1�5��ƻ���2U�bc�4��+��I�� �}�Bz�ݮ�}���l�5��e�N�z��!��,�c6 ȩ�5/_�&{�+P4ۖz9'<��ry����G]T���j�z�9�L7QNŁ��u�%i2�h���E�V9��Æ��MH
�iV��^6r��d�~n��%���<<B�(�`�*k���w�s{U�D^E�R�\�+H��kg$Z��>��+Ƹ�1�;v=���b3���U�LG���?�r������U����Ԍ/�S!�-�bF��GZJO�ϋ^�<�`~�.»?�o�Z�4Y�	+�)�ت9b�j"7���/h�"1YU�����0	���GX�\�Q�A�=}�\���T,5��� aiJ�YxSߥl�rg�^m�" Ov�P�����*�[��-k?��wnF�?T�Rc��ݭ��2`�� Cf'��r�ۆ|�z8�d��o���A�LC�e�®h����0��z������LsrLy��Yp�xR5j��/�1_��O��:�wgS��C��~+����P�ZCX�=�_5�>OK�ؐ�)5����gO��n�*����@JG��嶥x�=�����s���=�����6��h`{�^�!���&3�7װQ�t�ȅgǾ4�>��$[41���$��r�V;/��9O߾�k&d�,�dp�G\��j�܈Ĕ�d�Ne�H5�l͝d��b�@ע�F|���OW�����DFH� �6�u�ejM��C|�T��?⿷ƈ*fW!)@����	O��,����v��8�S��p���k�-ع*��D^��xQ�r�}��uM����`�%�� �-�Qa�6C������)�b��#�`���0���F�����R��F������3/X�֐�=�+����3�7��Z��7�?��@ o�㤶�d08s'�NG8�Dl���%�P^eRї#���!-�Xʡ��[)t�,�����th2�gߑM�l�Щ��&3����c�9�tq���Φw} },��Ƚ��2�K�("������7gh��g�6pzqH����#���av��s�T���V��3K�b�f@!P���}��y�J�ƻD5Iy���S�>��g�0��]�7�����?��"jV�j����I]���}��W�p���ǭO*5\+�BAB��@}��$��^n�@�\?_�h�0�6L���[=��Ny�Mo w쒻�SE.��3�kؒ��a8��������߼*T����5�Q�?����/����aV�1��AX����e��٢�N�����ϔ�p?8�?���y��٧$a���t��o{\��:���.�'�\�VVh�{�i�7R�!߇��"��c��JCr��>튯X�C���3�"$����@JL����&K2L,Q�݅H\9���������=�r��o^*�@��ՠ��h�Z��bx�UB�\�އ�ܴ�
*Z�:,���l>0hB�Fd�P6��sݕ�Er�b'?$��XN�Uu�T�!ٲ �e3��N+(�`�P	�B���E�(��i��t\��Y����O�7���H��	΢�c�ӬX��ר3j�XK�E����%6�\��N��Z� 8��"hɻ�"�ed�R@$�����.|\j�r�`�<=7T����YIr�J�W2�F�]�?����Du&��C����G~K��x���g�#��we���j�l�K�в2KGYMnF\mFa�#&���^>�ye���Xm�3Ic`;��t�����H7{6-�h8C�==�b`����P|Vj^�o\��
x�2m̂�`s���� ���5d�L�V}t�,�3g*f�s2�q�α4����� ,��+uK�&���ܚ���J�v�J�oǾ����N(^%~��J�kz.?G�Xr���c�<��j<��J}o�9���k��G�k�W�NOp��7h#�5���[ ��4)B�IVav��ք�J,v@���Wx ��W6�%�O#Q��=��j�\
�������f�nb(?�x1��s]`%���z����z�m9chD���BOv�zl���$,L[��J����s����d�6+��Ŷ�i�Do�^��KcuV��'W{o�CZM��D_+����jv��e���dT�u$�&{#��A��b�A�hKb�����CV��aA���^�p���]����v`p��ƈ���4�a���5|m�h>���6�gV���ާ &@����Ԧ�@�$���d����=W��T��܀� bM���+���Q��x�lF�K��������xA�·�������r}F�R")gS�
�]	f ���D�R��)N^=1�Љ`#��� +�`b�˸�z}��I]��-�3��I���7]�Т�7�`̓�fg	' ��t �(�㔉��8o���������Z�n�!GO�{��iL�S=H������n�>lT]������#-�?�u�Rf@y��������^�P=��y��L4����<JܠoA�}}F�~�ˑ �vG��6CF�R\� }?��=5s�F�?d��''��ܨlC)P۽�R�n�c�D(���ʫ�qM��ɏ�?+��U��f��:J���� ��ne�G.�'0��!���0�J^�-P���i������w��&����&\��ϯ=g��7���O⻟k�����u��<0�v����`��O��^g�6�W�=-{H�K�`ލ���?]u�Cw�**��R���L����3�S�xs��=SU�_�]�G�s"~0�\s,~|v�cv^�ټ9O����ԻW����Y�r�2��+<Qi�6
OE�k<�8#fH��x)l��;���K������F^\�z�tz���v^9sƐ`,_m(fX����%Ӯ���_LqK����wo��;Q�Q�Qw�:��n}�W0�~p)�=�0�7��14d���
'?ڇ{7��u黤�le���s�w|��i(v52]�|1E�όةj��f����t������L�')�HfŦPn�"}kd�5�i�'�V�P�SS3�<#��6-�U�q����t���6�>)̩#�H؍�#�@��R����7-�jSf�V�+4-S9G䆌Rx+5�eU��9�� ���h�S�w��V��b�2���<�=dۻ�Vc+���y3�f��.�[�IY�*�U6�Bs�iZ֨�$�G�m�spSw"����ۅKE�=D{8YK�{m�dud�s/�7�r��Y$�j�/�����*9��F+�B�	�`11к1���;p.���d�u�cJ�1�T�N�r��;��M*�u���r�C��+�-�m�=r���>U����u�"#샕��O�h���x��dۍDM��h���V��)�xyQި����f]��������A�ɱ���/<�����l��-�0~@�XE-ǂ��o�V}$ڭ�ۍ3i=���h�H��Ѳ5T�������Q9��p�T��2)�=�|���0�.��mL�v!���� j�խ�_Km�XO5(C���KI�+IMeJ�%�3A`s�Cˤsl����ߨ�ܚ���j\{|��:.}�Htf-;���J�d`1�cS66��MVO-����Q��]W����ux��Y����_׉���+���0���YfJ!gZz4]LRt���T���c�1�bt��F�����~H�=��}�b�
���|bE%�!ʞ
������ϡ���L�9�����;�͈A��n�7F:����6�3�@��1I����	��{�M.���ʹ�!����Ă��%=8@b`5(n�KC�)��8TUy��u��0C\�7���w��v�͉�����y������g#�(��*tE���z$[R�+�T^\�7�8�O��$�\j񌗃�����\7�=Wj��%���?{Dv�`�]�+M��}x���L?��D���}lw�ys'�|K6:BE�b��?]�ږp>�(|?�t���6�*p�ǘ
���k$�߶��E@_��`x�3g�?���IA���LH�a���;] ��g�9_�V�*Bn�3Bx�V��Ⱦ�����UΘF�C��6*
	�^0��6�p�6��jO�b���`� �B�@�	O�bE�E�:��l��v]y��-�=�ߧn9��,���ΨCf<���,(I�1���S��Jd褗�̲��V\���FŞ�3�Q�gpJ�!��i����$}�?�̑��tB�)zz	I$�y�g���o^�����v��c�/N�N��J2�=5�������i]��o
w�"�*��E����SCΫ6I�#47f���y "=� ��q�.+�������s�[Dv�^��m�gd"�P�&.�Vӳ�i�R���cvO�^<~`���Jp|!ڋ_Yܡ��1����<� �u�V	��	Jz�-�����5���D�7Ms"'B��)�#[�{����(n��3���3�HZ1xu�F� �3�g�Łl:!$�6:�Ί�D<�l��y�q�{��=�&���euї�FZ��͕��s�
?h�}C�~�-e�Ձe[@)�0�C0��hL؎U�<6�SX��
�<ϔ��)�xD�㒫 �X�>��7�tŖ���e�#�-����:n�p�yd���@m�x�����U�݁��RK"gH�?K��yHY&a9��/ڿNG+�u��d�������?Ԋ�u4_S��
û;sj���z�!��z4�����RZ.0�ͬ��Ȗ�����ƯhF
���O9��?,t����9�a�QX��4�E��^毨n��tO��zX�@�{P��m�!3��"Y��m��w����3Hw�U��@� ����r6+�9��ҭq�Q�Z�2ً�W��n�yi�����D4��p>׃ޒ��^WP|����4Z0���y�]���X	vg_���?���B��! ���߼��Ғl���f�o���y����ӽL�%9-�f�S*�%�є��maW��Әb0��eH�щp��AK&n��-��1�B�.�6ӟ����
v�~�}K���N3 ��B;�+�]m����<����(�4G�|�W٤Vy&/B�Y-q��
 ��P��-�o�T���O�;t8D��-="���M�F��!<XVG2�MV.�s���1�,5w����<.��~+p���{jiwG���o���	�#�|�L˲,�!�D�7��i�J �]q��@BK�`�ز��2?�:�X�%H��S*[>rN̕WTl�CDkN�Q�%��#���Hw�ZU5��piK�"e)���:���z�K�a���#��_k<�A��d�����Y��`�i���Y0hn�"��
�|�	�A�V6��j�;_��]ٻ�u��g�Hf�ޏ���82���a�k��t��:������?dA�QO�?Č�FTn���	3q�$�9�T�&F�L��p|�B�+	b���2�\w�<� &Н�!B����G`�:� ���	��]�%
��Q�
'���6p��^x�߇F�N#^1�`u6�N�����Ovjus�WS@4�\ᄋ&6H���'0Lq�1�yz�J���Wt���G���I\"3ʨ}��թ��<?�d JΞ�y�a���b^̠�=-n9C�-Z��q�q�"sMqk)��6�<v�F�o��?�����~o-)&1ᘡ�p����c5ªF�W����12����4S6����GSO�Q�:�M� ���J�ՇYEźݴ+��I��K������`Pla�0���-G3�V$�6�ۭp6`�,2����a{褊���x�7�SU;��a��f$�ᇄ����E�!�ݛ9��N˛�R�n��m������Xz�Y�� q�h��?��-��c]��X_uh�6�$g�rj�&���ƞ�.��d8+�$}Z�X����g���J,���D�ѥ1�����[h�-��V:�pƾ��l��v+l����M1�%H��M-�s��;V�;�Vh� �B�>�:E�����ɓ�ڼֳ�(��g�@�G��Nܔ��_�;�Aw�(��ɨGj�i{�*��;'����o(̩���������j���	�Л9I]�t@�aL���hG�/�,�*�gI>b��_TA�U(�`�"BG�m |��)7�CE�5�HK�D�a�=������K��� ����˃����D�kh�7և
R�ax23�A��'ٹ88���-�%�)O��d�pi�A%��q���e*Q����0��3/۝R:��{�ZO�Mؓ6٭�vD(�]����+㫳��n�_����^(�/K�=(fx@��W%�oiBu�i)��-��@&@��P%�$'��'�of+�����z9'|2�E [=� �,�!����
�����r�+A�L�ʁ�w=�{�B6��3Қ$A�	�X�g�L[�	�PۚY3//���]��q%�C}X�f��$�N�M��P@T� OC��/oˇ��[	%5�F�X�Pd�mB��[V�5�Y;:������|{�7�S�\�ovyq|}�?���w�k~��CM�Q<�� �P��Q�4�n0�q^�}�#_�񁱭��9��R��2
ܗ��ǍJ�#i@6��gKbf��oB0��BxU3��%X2*��k�����"��]-zP �;���Q`*w�d!S4��=
��
���?FHf���&���j�X��f���W*rÑ)��VF�@ӛu�˖YڸS[E�����$�uR�Q�;����*_��6:��u7��7i��<�젍/��g�uC��[Qj|_RՏ[�$���`?�����*�պ_�Y�����w�k�Q�]Ф�تȔ�*'����Is��X�EB?l�8K�jz*�b�YJ2�Sf"���N-�0Ge%��� �Z�P.���j=�д
^y�U��?����2�͖���4�eQ�� 3�ȹ�܍�R|l���v%6/�q�U�5f���l(��Ƹ�� dϭ��ۙ� ��5hy]܍k���4��Z1���pB(����,�衄k�8��,�6Qf��Y1re���}����rܦY}}������db����l��Äk5�}�u�1I����5#$[*�o4��
~�h
,O�S<�KY"2mf,v|%�A���Y��7�4Of�7\���N~���1���"������r�����e��\�;^� ���E7�
��I�0eSHoW62AL]G��#��		�Q[{b�����n�R�������(`o����U�A�9i�y"����v=�XJ�m�Tg�?�+ē��nD�J�:3��Zi��3�~�fg�N{ۼ�#_���<��h �� ��\�y#���?�\��7�ȓ^l�T�g��Պ�#>���@��ғ���f3Ir�.K l��b1���?��^θ���B0]e#:�*t����� ��V�����&H�4W�?�z"����^��䕎��0�څ=DNNvB��{]�|�Qg���D~��+�U0�Ǹ�ʹ@v�Ҋg[�ǍdV�>Y�t�CZ*}60-D��S��6��@m):��- ��8�)<���YB���=<Y%Ű7Em�q��?�=�2|֎���b�em�嶇�	�Z L1?�xxD7�b��ݮ�>t�w��L�L.�������E�]�۩T��'rr�?�FID�!,5����k ZH@����D����:�k߼�������V����Z	�'C��Q���W�D�d��<�ʒ�sg�J�"i� ş�{"� 2�rG�)0��������g;���"k��\�@�C��p��O�.�Q��X���� �ܝwJx<U{zJ;���;Խ���\�
�^�3R��$1e�w�}U���5�B�h?T�A�=��qx��(s�kM�*V`�x	Z��d�b��J�$)}<�������ro��6mI�\���-����ϨD\�7�9+��U ��"f~�5.?��]z��&3�����T���[���μS-o�]���V~e#����5�A��F��5��p�`-�y6����{��y�t�+���r��3{��V)�-ʈ��z�ͤC�d` ����
@?���"-��	��\O#v�]%�W�V��F%�Z�|o�{�KA�y�Gq�W�}α�/���ټ:)�}�q�v��m��!���_W*��0�hH��vQ�}w�~Y�]�����,$�`��|ϡb�Ѕ�����C�Ÿ+��!R��BC=W�j6�Aʟ��*=/��0;�ÌC2�I?&�k��7E�cy13y^敕�O�����UyK;��f�AX�*6�p�6�{	+�0���n����ѽ� d�mԎ�� ���9,N�&c�, {P�!F4��l�Vna�G�Dl�V�%����^��}ݑO�Q	'�3��y�Yg�"����94��c�͂�2%��
�?�X3��?���.�e��P��g$�����U�u��"=ؿG:i�����4�f\DNJ��~u��O��vZ���L'iᆢ��a�k��̒g�&��UQ��}���A��	X<�{��MR����a8������Y$���H��i�(ge�f3$��F��5�6�0̻����he�_�
�9P�'����9g�.�1�0ڊ�0�N�5)�'���ȒAd(�gV�A��=�Vey}-qn{)Y%��e�u�E�z�1[��x����-'3i�x8#��oA0�Z��c���O���s�J�d>���z}���0�O�	����D�h���Ư����'��x���,0�������1�o�WP�QU����O����v1�BX
hct�.�$+�����8=:(�D��5�hA����y?�Z��P��.2qB�4
��i.�Z��^"��i���#���B��N�*�:C1�`�z��m5s��Wsb�h`� 3����m�ӌ��9"p�؆tu�$�6�*�4J�x��J۲��ۼ�w���vx�\.��2J默��	����O�dz�^�,vT��I���nB��k�b<Xk�(�,�U�<��:h����z���L�X]�G3��슗.9{�c��6�HU��Lm>X�%�I|���X��Mg2^����k��:���KI�4"�o�b��}ӻ���ہ��@љ���<Rn��nf�ݏ�(w3�wN X�?}B�KK{�&�j9���x�yד�.#0Y%��m�T��IY��HK��:S��і�����N�0��P�mm�)����j:|N u�VC�� w1i"k�l�L��K�l����!b"��:�B֎$�E��S��?m�C��4L@v}�D���C���x��@
6.��z�����"G]9D�'�:Aav84��j�v�/��g���B�T�Xh�IO\u�+=?ݲ�/N�
&��v�a��FJ��	p�5�����=��������GHg�Q�>]Y��hz04�Igq6�e3뗫^֪hsX ИN���c� ���i�������t{���է��r	V7��o�$���V3�ɀ�6rt���f��[����xx��i��Rf6��Zp�'@Zހ��`�ZyO�M���^�Nv�x�~Jݧ�}P~���p]��N?�����zjO�^�@����<��R���)O�w�����D{G�*yU��vi��	��!�xH�QȖ�W��_�����c�B��葚��
���g�>ؗ9sb��G`���(/DCM'������98���#����#hu�Zt�1���e�i6!RK"l�՜�	NN��%z���Q�|��?���9��>��|\nx�HI�yaк��	-"#��)�l���k�j�O�����I��֑���Q��_C�i���Ji=Ý�4�rf�2�٬of���@�E�fF��W}Z���n�Vi��QM�h�}�2ǃĨM2A�]6 �A�߻���1�kw{��\���p#��k2(����ώ�ΠQ)�v�RߧsF�N"��1x+'kd
Ӟ��S����R��R�8�^���B����"ƭb��U�.�����W�<�}�1�N�,��q{`_�`����G���7\� ����i&7΢�6ߪG�.���>���pᗣ�]��Ƴ#���>FD�v�1�	���\���"���
ѹg �ɾ�i�[�^�m4��	�!;�+>���`J@=����=j�%5�a���y;
~+z�`c�|�Z�/T$*;��
��g/�-��R�eBV�)Sȫ��j�*3�1�2E&�t��}��@��P7��d�c#���$(B��&���4F���h$x�5�Fڄ��J�K7��Z�ymM��&5m~֫���^QWp�_'�N��	*��p��X��������TRz>e+V�Td`\,�Wg����u�0�:iר��[��#�_�f�A��2�!Js�ڊ!)�1E�P ,	��5����q�%u����d���u{��3�<a��.�>���L��,�e�u�����Y�Z��b=�9c5&ͷ_i���_-vnì E')h�Y.L�2CrT)r3r�\�z��x�ZSo��<�Ta���s�����џ,NvR��!�lmd��D�_�Cx�G5�� o�k37��3�3�i��ov6#z��]���C�_��똢N�Z�Oh#�+*�8���:�m�bg����x�~&��d{w��� \���
uw�Z�m=M������1�H����D��q� !VA��d�E��MleU�Z$}�c����-��4�R����M�K9ظd �y�<��?SKk��2́�o"���=��3b;���3�i���%T�&6qS��̀���RL�C��~�%���QI�X�*��M#��E��#�t|9�B��#6Y��/7��lN�P�X�b.�Z�=��5Ь4_<�> �c�!��$�d~�6[�v��tA���ȅǔ�.�?�,2P��� W����[m4�-�#���߾�}i]Y�J�b<[�=.jB��9���yBI�d#�� �]������� �$1�t�溲��̮C�/�9V��u���R	CM�Wu� �3���g��K��V�2K`)�V���w"���uz+���"G�����*�M �J/�sL��%R��Z؁��ݷu:����>�T�|���8�0��ʙ����q<�*v_�Z�'����6�����=e9 dqp�?Pb�΢b� ��T�7L�����m�e�sc�?Ģ�x��.��8� QwW��d��̤Zw�Ա��sb��@��� =� G��1�1H��<���.�����M,���2:���U�������(q�+m���+�7���R]�ފ�@�p�:w�X35&��� 	�_���$��q������ڌ7_X�V�:ߟ�b��Y����f}	�EN����I�w6`BP��M�x�~�6Eq4<��$�EUǉU�	����iӂ���hw��Ͳ�g�K��E�����Ue��Y�#����^�L>1�󻢴�.��\J.������1&��!%ʧ�2�|�]x�j���$���iM�E����c�yӀ����!�W<������mTo����4z�����.ͮ��}�y�� |찉
�zk:�0S��M�ڱ��Mȃ��9;{t�B_e_󿿱��c�Ѻ ��?��K��.0X���������=ɘ�c)��i��92uZ�� ��D��_�XcJm������22���/!C���ΏZ��Ǯ��YD� .ٯ�ڽ�GX̐o���Q Aie�ԭ��T���uo��y�6֍U�/�%W#������Y���Zkf�8��*XO�
֑,KuК����<a����{N5t�#��P��LJ��[�6:|���I޴�]`�[�Aj����������J�Q���c@ĭ
�+t�G	8��}}�IF3������'=?�E�/K��S����tBS���1�
G�%K}��?D~6;j��QZH���޾>s�$A�k��ƹ�`���%Q!�II�.�.z��7�'��6�>�[|\SN�16r���6�9g֣Q���m�t���sԭo~�%�����,��G闇�^� 45]���=�nϺ�kF�{(�'Sh�K�l�7ߦ e��#��׼�_M�'�|q�]K`^[jd�/z� @E匚��Н�#���N�C"{���!�/�3��GMvڀ�m��]
�`�":+�B��|���r����VSڬ�Fȿ�
�:�����Yg�I\�f[��y����i�Eʘa��,Ӊ8�H5�qIk���/������]�����)�}q^ӦlW�YˀuG���9lR�t�z����Z~�4yeO7A��2�ԛi'�:W-am�@�r��m�E����0$�H8ǧ#�h
���r����[q��,o�<�<$=Fo)��������F�*('��ѠR ���L�U��|{Gp�TO�]�~]�8.�)$��ڭ���G/�	����D1S8EzS_ah��i��c
��Pw�E)6{n����`9b5�'��.�,e}5!"�"l��r]B��xι�-v!�	:MU��F{{Ew�m&�i��ޝ�"I^g��A�>�`�.dP�]u��k�6�n�BZ��i�a���ƴ��'�w�L����:f^����{0s@[-��y�������o�'_?��2����Sf<�W������1�Q�i��
�3K�GjM�=�'g7�Y�� �Ց��CJ׾����p�-��u�_��s�;�V<�뀉�}��>
`����N���폧n@[U�k�zG���jg:}F�S.W#Z�#�#�P�	d>y����ɼ�Yǘ��N�9Quⷆ��@	����;.�h=��Y���n��̺�cqW{�a�`�7/\���T�w�47�H�#p?�u���hͨ=��O�A�$���t�k,�R5UR� K���<�n�(vR��s����ʒ�<���ٱ�B^�u\�H�Y^�z���	G&�
����>v+KI���kUJ�Oe��-��6k�F���w��R�]}ßʅ�dH��r>aM��Y���=ju^�:�D�ԗ���&Ӵ���e�l��
����g& �p�>%���[�$��{e�I��t���Xaa{�wY���s��I��N�c�{�%������&3��&��泊������؟�F����#jf � Ogӡ~�D ��w��ݡ�5��`�|�`��GD�;�L������SE��ND�����򗢃��vS�E^8��)*����r�d�Ɉe���w�$[-}��d�5��(�4��`�)�j[SE�+&P[x9�Y*YK���M~׏&]�ذS��&�~�������xqؼ�����:WD�9�z˂SF���k/g(>\�Jh�&lM�P�����I�����)q�U�ۯ�ހ2�c}�.XR)�ZJX����LL����KM�����6���i��_�&||��<z|�D]1��;�A�w� o�Z.O�X���74޳fc��S��F�r<�(��>)���Y�w�����s�_ ��(���&.˪�ӡ9)�e� H@r݊FVA��K�����)"�j{��uuIh3�rBɓL�A��Y����ř!�^�}�=��W�%8�qD�n��;����'MY+w2�#��x[-�f�_z�7��=ō=.�j#fo���j��o�@��D��T�GA\��B�_� i�Dj����M��SV�[/��$N�<]�D�"��,Ӽ�)ᴛ�fKꈅ�`$/��?hD@��zᶴ�b/���>��(z���֧����/�������d�a�_ݔa2(-��\�z��I�c��5N�\��'�_S^���K�<ɸX���Q���(")��2��Ah* �o2P����h特����FiBo��>M���s����+�����uru�5��c����Y��`�ﺅ�aō��l�\l���~�Qʾ��c�emߺ��S7�1�ш�::����l4��z�1�khO��?���j6ol/��N<8c]Q-����>�3ɔ��}��ʗ7��wʷp@��N���<΢�m�:�.�`8�{-�e�S9D�mp�K$�3zth���c��x_1�����Hm���<�ˣ��� ҉V��˻�p�6�Jw�>�!L�g�G���X������*ގ��'4����;v���it�ҫ�9K�.����?kGm!1Yf�$h�kmbc����D�k���l�9��\_�ޘ���h��f.ϗ�T�����N�~35�U�-��f"/:��<�f����]�0��!E&Y�1ƈ�7˧��IT�TESv+�Z!M�f��n�����Y�a�Tݨl�-$�8i�{Z��䌤��]��o�:Y�,'����>�A�뼆��
ܔ��FK����Űِmd����`��j�G�����e2*S\��A{�&ܴ�p�/W;�=R�䪊NX��y�a�^�+���r���#��h����(��]�%sz�j�2�.�zD�6���JA����4�&S��${D�]�sv�*�eغ�L,��jl�]�Э���01�6�Sx\����C�`К�Ŀ2{) ue���<kOtV!	m_'�f�͇-�_���(�,a/�@���d���X��N��U�>^������K>�O*�|Y<��V��ʄ�(9�y������u8�1�4�x����i��H:mB��Y1<��
��6 "�Tg��T��w-N׽S��e�T�Û�IX�2
L��r�
�?�������F %C2Wr=���7�@fR �$����x�/4��"k�#����%YA%�VJ�$�h6)�+K���G�H	�������|�D������� ���u���	 J�������k�V��f\l~��׺����Ϭ�� �:�76N�N�u��YWT�Ac�Ǧ��"���x>]�5U�e�e�Gs+��=��O�3̒��ES5�]�jй^vb�ɉ�G�SH u�T��w�P��,\Y�
[�:b�}�ݳ�e�q�.(��O9�NJ��gh��z����BX�&%j��+Q��9��YW�="N�v��wcK�N��Rꧻ���F�kc=Q���_�i)�Zt)D!K��e&"?^���X������yђo�a�vs�v�5.�1���M��s-��lgM�WAK�Я�Ӕ�
WF���(�o�l"��d�!B}��њ�R?�MEO��oth�H�E��V��	�K0i|]h��L�'�N��C-W7&��tu�9-��Z{m��8�P�
�*B{c5(���7�oҡh���a���V�h��@�����0���L���#�Y��ig8ƛ�SH���o�j?Y�k����0�U�ckz����~_{'�Q��D�~�e�d�(;Y���ڍ���s�(�ah���w6˞����I|��	"Uě\��)؆~Fz�v��n�h}�h"��t#�����mV��l�p�3&��`>q��1$�KI���no�B��5t����y�`v%)�eU���T���ܫ$�zڔ�)��Q�%G}����L�S
�J�)V���"y�γPhnu$���$փ %(��Z���.2j���j�J�nI��u��,XnH��J_�]$Bgf$VGh
���Ԍ�}��e�jF<�����3�>oyVM#4�dfL"�]�IƸ�T+ٛI��_�Ù�^&\<�~P�(�L��x�j+��^��hnGn�F�V��k�B��;$��b�����nN����g�n���yħ�I���Ȓ5�[xl�G�2l��2z�f��a=�p_�����2>�f��.��wʛ�P�����������d��'�氂��ǟ{����~�ޜ�%�5�r�Š���ÿG���^�o[n��V������ �vj
�u>à�T��ܧ��.����j	�|�Z� KOt��������V5�x��0Z�`:5,���q���'qRj|6;�@Q�ˠ:A� �=]�ފ��S�Vz��l�5�:Z��P����-�g)�W$��3�̡�����iT�6@�ϱ�aV;��"����B�.lf���[r4��+S�=aWAC
y`��˺}1�])��7p��(ݼ�S�v�
����1�5|E�o~�X�WW��7�qs��y�L������?+��-�1�L}o9�Y^s�c��ՠet�9s(��βwP8�V��af��W���X��:��%��p�\'u���7��iL*S��w���z��9�'�,vޕ�D�m�wD�h尭��n	 ������A~F1��6P ����>�rm��$>�<B�C
�)�2�oG�8�U�fiHqLc�T ���";� v�0-zC0]}����}����w�����e$�-4�FT�0`�)/��֟g���FN9���.��QT��^X�YF�ey쭢�y��DzoS9��,��3l[�3Ҡ��=��� FP��`�)��F57�;;�X�S�:�>:��.0$��uS�P�2������ɍj�A�L�'�
��S1���E+�����S��}��q��ʭJ�89I�삹7_��|C�����}���LH���
�A�'���Q�5�CkuPNI�j����)v�2=���Y���ڸ_Q���m0g]{ʶ���9%O��a��,�#��)���X�'��p�ʬ����(W�Ε�S
��W�����B<T�zĎ`��M	���&�n��kF�0J�;O����Z^k�ĸ����@GQn>�ې4OB��q�y��X��z�4s���"Su��������:���ɱ�����RB
Tߜ����?A�������d*�뙤r��,]�5Ԏ�4����_Щ~a&-��k�̎nņ�K�Eo[��A�W������qdi�bִ�x!w��Ƒ�hV#=�x�+>�z���J.+�nT.���q[� ���頒8L�M�FQphƃ�J�prj�|�@��9��b)�`SV�@T�/����r-!R�d�9ھlR87����B|�R��jl�h5�w;��1!�~�Q���u�,�t03¸��M�A�r�$�#����kR�$��(����3H !kӋS�44i�v����D�ѡȗ�I՗��ٮ$ ?,��tC��FdP1,�S���N19A/bG ���H,22Ķ'y�ae��6r ^w���1��0�k�x�O���4؆Z�YF�A�6Q,fz�q"��=j���L�P_�6��G�9���G�x�@ڮ��_����9`�+X��s��g�5P֩�Hv��]�L�!��B��^6m�JV�� &A����U�BJ���*�����6�SHL)М�s�Ć�H;�^�d�9RJ�s
�����`�֏��?���_�%ޣ� ���a��p�M�7_��_ÂL��7~��ؘ�u���k��zٍ@`h�C%_��yF�Q8́��&��{��'�+��6��[��&\���s^��F����0���=ss��9�P���\Y���0���0��6T���iMBg&��?L�-G:��Q�~;dp��Q���s<�$S#z`�M3���g�'U,'7�18v9P�eI}X12�	\e�E@���.�јb�k똲$|\��/ܯi �oHd�WJm�
e|����g#1͎k{��6��[8�P"C��P�-��W�^���JWc�n�ڂ;�5�R��/��&�NE{�����(!6�n�PV��
��dJ�f㘪���F���v���\����2ƒ�&���j�`dC�ϰ���F�$!��x���d�o?h����=ʐ�n�m\��/�5wurm9j!�nj��-��i���;k�c��
d��U.����W�z�l*�5���w�⾊�wB^ ��׵?.Ս������[�ݠ\�a���7���ZH�=C�L��v�i�����E�Ό$���l}�?L�1|e+ӹJeu4��[�h��J��G ��6c�Q���#Ƀ�M��͖O�L�E���%��{���Y���ѷq
Y�6F�4����w0E�DH[�z?2ě$L�I��j'ZTf�Z���1�u���Yb)XB(�8]('oN��C�f��>�!�(ܦl�-���yB_��mYc�ѓ���c��S͘�W�[�j�q�Ima�;�9���(u�6��F��T��q�����}75�Ґ�NHG��T�'(���.sZ����zzC�������Rn���P����7����~l�~���W�5�xb�xa`�z�xY�Ƕ�	%g�	]��wk��L_��~��q��j`��[�щ�l�5o|��9-�aq�����c�ۭm� �-`��s��.Cϗ>%-�p}�ٵ�NY^�a��I�h����Es	��*�0�&�S�����F(��6��q[�o��`?l�S��%�|�@E��{M:ES�+�U%������X�{����o-������PϸC,��� �u�L"4ʜ�G��]���=���H������<�}�;8E�#�� ��Ap"#�~*��T�7 ��;�P*$́��wu�l9��$U�gp8� t���*����6xM��ZP��V^�`V�9l�
K3�o�U��Aj�+k�hm��;�SD�;+�����4�"-��}�Ĺ	���Jѱ�#P�`�3�Ʋ�m��Nj�U�e��]
���/�|x��\�Y��:Eo�����*�Y����|62?�[�v� ;��\�߾dwn�#��4��פ�d�^/��G��ʸX�<�U�e�լ���@)1+|zŅ�íP�M~��q������~g�I@����m3Y;W��B�qD�a�R��LΛ�P�O_'-j:��v�[�M��+>x�TiŮq��$�L`���D)hq.C8�M%��b�O�ƺUN�%r��_ו���BJ�h,	���}��6�c+ߵDS�Hv ��E��W)Vk�%F*ݟ�`7���3�����Q���������$-��Q���_�q5�6BE@���.�hU���P�-���m [�{����ռ�Q�y���G(�����h�c��� Kh�R|Վ�әAV)�i��{ǿ9֫���z��z���l�Ң�dIM8�������?TsV0+��f�$��(��V��/��)��؁���y����i�gP��`ԍO����? a�L[mU��?���vͨ�l�Il��z�zDe]������|3QL>A��TKISc0?;U�_ 㳲=�+�۟fg��z�[�0@��б &���%�.l���VI�r���P��k���#[�l/���p�g�V�j?��8����J��� �"�;�B������_?��W�*����j|n%���ڟ(����Ʒ"(^�����s��̟��!�9Kv�U��ϑ�״e�,��Wvdđ�=(�O��P�IV�nG��u$
�4ٴ���Wq捋YW��Cx��G>�'�86��\g��*}�c�;��:��k!�&L�?|��.bj�_i�}���6��3�h*O�,޻P"
��)VJ�_k�]�YNÿ^�j�DХ����DL�7$���2B�e��v�ӷ)��DA�(���$���0�_��@�[�0��l�{w}��gl�a��,{		�O$������UVTF�{pBx�.�����Y~N�,�Z��+F��ڷa�)�����>�O��eyںtV�MN�K��F�����Aћ�ie���>b(w~�E#8��9�i�C<V<��d��p[#\	*�������Vlޒ�V�*#b:�i�5�\��%�ɱ~F13Q��`�1�4	���\1��YJ���C��Y �u���8|&ДX퐘^%�4��6�Rha�H>$j�Azc�o^����V��t��m�\BU_6U�[�]��ě歮A?����a&�,N�aG�.�jt���<��S���	d��ߦ�����y�˕u��Cy	���?�dZ�K�qM���x(�绢}�}{�q5Nz
�^~D|�[g�)[z}o�)詸�v�a����XM�-�6��>�(Z(��}��g�3�8�A�K��ǧV��c~w鯓s �¢�'��n��Ȧ.ܠ�zIr!�L��h�l���׶���ɽ|����c��(i�)�o��WI�\���WI��`�� g�9���Z-�-� �M��CB���M�2E����mL�?�
k�U�;�a���$�>妌�qW��]Sb�+����ƿм]$��<aw����+�7&���"l2���-<a.����>2�P~=�}��M�a���`��o�v��Ȥ���KԟL!���g�Qa>˻,PU�lǦ-Bv��!�h�I�ݜ� xH����#�3څ��Z���|f;�|�D#�f��S{/:)���1�.$�m�G_�����M�h�>	v�n��-�>밨=�2� ��Lq!F�v{�a��[>C����U2з���O�#��M����L�i�7����w<�d���!�ͧ�a(_���8F��ٺ�a��k��%T���[F�
`uɻ�G�acyq���Ӳ�]���rgʛ���G�bܝ�B=x�R� �F�$ŋ��������[�p�P����ϋ�:��ѫ]���|�=���2ǘ"Z�e�G�>��[˫���U�x|��X����G8+�5�Ļw�1:�]��6~�9�с�,@���H���?޿<��x=������Y�2�W��rQ,v�'��m��>�y��5�	��E�^S�k�[�h�y#�WaTp,HR�@F.`����"x�}�����{D�\�t��۞��mD��&�:�yj ��8vc9
3-3�]>���*�6'�5�c����q���rxąZ0��\�P]�Wϖ��|F
�g�̚,�Ԧ��go��1`��F��|���&5�|۽�菟��Ū�Ixe��W� �V֥�z�k�aD|�P3?�i���5z�ÎH�={��9{�:n����#jɹ jD�z�@��Γ��,��5(��n��c��u8.)q�闰X�Dz���=��v>�Jj��z��g|V�R߀�BԻ��%������� ]�A��]6VN ��
���at���O�]��粓4MWG���1�@e�t�Z�㕾Mjq�$�W[=�"�J'z�Y���s��+�"OS�Wtqb��A�F���j��Y6׊u���>2��2x�/�F�W��XQ���w���Sٯ۱�@�����!���'�����I��/1�I}W4����D4���7����?|DY���abT��y��$*��s�B+������Ee�N�h^B@��jpW�����w�/6����?�׻̄�Y�޵N�eTލ��2I���T�� �{�OJ�8�.4c�4��P�gb�*|�z)��ur�f_�����A��q �uR�;QLǢA�������z|~;{�M/��nJ<N(��#��F��L��0����CK��^T5/��(�7ۋ���R�UZm���B���"~hb��8� {�m��`�H� ���?o�c^s�v�"Y�h>Lj������<@�ަU��>}Ĳ��t_UA�.�Fs��M��D6Ϣ	&���B���\L;�J��6��<2-�W�~o�2uxe�z%�
xkT˼xU��9j�0�������\L�AoT�}3��W�'(>��Y��f�w�,�f�ӛ�i�:�f 2/�C�8�d���9�^��/�.�� R��jV�y�U�K��7�8~W�8��iQ��= S(Wx�?�����a4����XuI�/x���2�d�؋�X�Xz�1�&���u�:c�]���
������bv9�­�	��*V4**�-��p�f(�n[�?��Aɿ|;4/PA�����5�e�4�z��*�'�ɔ��ui@�= ��{�V=T^=v�k��1��`O��(�]�✕�(�C`�W�6^���U���a�b��W[�����]豤47ƱԽ�fG�ؖ��[������60͙cUC�gFt���������K٢�'T'w� F�$��]�>����.#�Ԧ�o�D@�+��J�R�Bo����2b��v5���>cY^G�� U� ���4��ؽBQ�mK&r�B�]9D����'�2F2ʊ�ő�/W|���k���U���;L3���{��ԩ�#g�rJ��"�Ly�e�ђM������kwu��	�걂0v>?v�}_?�����B�cV�)���~�)��`tmz`�u��3�H�Ƃ���W~����	� IC���u-`�*���Ⱥ���إ;���
RA{ĜGm N��ڸ��BA�6ް��~1Ƣ�	�3�_�$��[5ųF{��~9p��43�]�0�<��]��-����h)y�|��=�K�Y^�| o��q�|Ee����
�1��HMX8�q�ѧ@%��hϵ�i\�N�of���mH�p_ҫ���Pc��L3����ɞ�`+�Ҝžv ��>l[��:?5���9����]Cd(֑��ʼ
K=��ƛ�坵 �A�V�+*��+�I�s�u�(����[���f�ٕ��j�}�����b��+0�h�U1^��!H�j�=�,�h������Y�t�����*"���P�8Ҭ�}z{ %���Y�}�ϣ5�����(�M�[ܷ��m�F�h|+���%p�u\�H�aR�Z%ҡ�a��?XĐ������ ҷw����+4~=8����ZS�6�a�e����P�5>���X�S+�޾,���5����C��L�gӀ��mrє���ǣ����Wܽ$@�jg<V�hkRV�9�^�aa3�	�j�82#��^�w�q6��5�W}u��,��8������T!]�|���#G��9<0V��"1l�.��hv16 �
�m�u,-"҅�x����!���I�J�U�HH���V���o���(˫ut��6�&ww0wbj< �0�k�i��������y�?�����0�Jyz�s>\|)I��1DW�֠m*T�I��o�>��k�.)f��?�����m�J�^��&�p������{��yj�D�w��Ls�2
��8u�x!�u�=V�^2xb����n׻T��BY�ەY���ֱ��������l��A�c��	`�$ =�u��Y'�E ƾ<�2M ����O���g�    YZ