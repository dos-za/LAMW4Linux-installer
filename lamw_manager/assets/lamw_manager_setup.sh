#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2930544849"
MD5="1dc3e867e991b70c10f6a2eceb516561"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25596"
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
	echo Date of packaging: Wed Dec 29 00:05:32 -03 2021
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
�7zXZ  �ִF !   �X���c�] �}��1Dd]����P�t�D�#�d��N�q��,�{w��Q�w���Z�Q�D$������1�{ɛ&�4y���)���u1Y����dWWiϱU�XobSb�2����.4�΂��$$��6*��};Y|����L^�Gq�k��֢No~��V���������@�iY�\Z7?�h��˚뭘}����.�Q���O[�է��)����W�c��e���'�n-�^�C$Ϣ�ψ7�dR��-�
��FK�E�B��f��SɃ^���z:0Gϯ��f��9M�����PH�7�S9cW�j��ZMG
�/}��_5��:p�� ^��m�i��/+��,Sk�ˍն,z��hE���Q|�O�i�&Ց�yY��z�GҰC;�2�Ħ�����Zq��/��E��G���R���0��ُ�,c|=�}:Z�n)�<�EZ�Q���Se=']yB�o��ڙm��(������' 8��N���sr$o�x�C	;�{:�+�CP�㵎U�hމ�J������u]��E.u���� ��%�4)|?��<FI��J%��|�R*',����?3�����#��Lr���+,�;L�Y�S�Βu�3�>���z�,��^��q{.nhA �_CD�V�I�0Vg���Ml�8� ���L�"���
t.���:������ ��`D����ĸ��~�<�)$-��+����T�[߱`IJ��ڠ��2�����8�S,A	� U��Ah.�.�2MK޷bP9}�W��?:��qS����].F�o��dڲ�S��4l�,�I�!IbL)Q��'�S���&8����V��Z��I��o#%F��$����z�e�@K�&EOYdR�e�GY�3�V�����2P���倁':a'5[Z��װr��͛�J���v�������Q�����&��D���$\>��2>����Z�*���%$Hё�F�s�rHC�]�LMcd�o_ǶV���N�x�;β!r�t�L.��ӥ����k���h~@��(tD^C�G�\��%T ��8$�,���01+���+o(j-4��$��姇�"�%�]8L�{���SD����I��m�̣8��C���M��B�fոm�i�]�v�NԖ�-^9��d�q:��5�5��H���b<Ez��>1_����G:�VMQԄ�����#%{7�~������L�F@�ŇmK6��`Y��QW'��T�e"i�w369�VI�|� bFր����B��I�"���"N�ޢ=�C���Ҝ�Ó��N��+�p���j()�Ω�/�~��mTw׆!E�t��7YP��Y�MN�)Hsȷ����J\R��0�~����]΃M3�e���nY�����Kw
�Pr�i�����J㰨�n�P�Х�$'���������f���I�ҙ��&�$y�����v�R�}ѻZ����*ux }#2�0I��ʺP׍�F��bȀӥR����0?GW
<)
f��������Lq�
�hg�F�/C�*Z
WznA�Á��[�*P��Y�a�9�S���Y�d^��%�/��DMf�t�G��)e��y9�PL���p@B�
ű���pjnV(�>3�B�1Ć
C+�#wQ*�}U/�h�gq��3>SϪ/�#%��c�_:a�i�7�G�b&?M�*y�q#�U#�� ���Q�SS���}*�7��������𧐛�e�J̬�Mc��m!��T���NZ��C���F+uI����T�$D�GGy�$�]3���9t3hۛj���L	�]\���򪃎c}n=���P�t��0����0��4^(�M���\Ph�u��f���u��9R-�jl@��3�&:Ɔ��[��L��JۦD?v[����-�b-"%�pϳϨ�<(|�ܗ�FU�hH����V�*�M���6���N4P�ŧ�a�����VE��t�1%��p�ţa��;٪b�=W���dF-�/x�ה3֦StE�0+0�vg�B��t0o�P���/�R�d:*7��!�;�MVR&����%�.���=�h�v��*jU�AZ�h=��[든\SW�!Ӹ8��m�U�K@�$-�q�
Gq�Nǵb~���9���d>��]b����\�s�D)����
RJ/q^1�:����o���E�s��j�2L~�^`/VV�]N�ٹ�x�����0h+jscT�:�F^яV�G�f!P>� C0�d���]�qvS$qY�~���§u�>���C,�����F�s�r�'#��6y-%��y$A��NR��_���d��lV�G�8ލm��fn�����P��D�c�M�e�W٩[~�"n�a�s���!�0ޠ�[�c[��3��̸ [�9'�W�������HI�4�%��VEr}hD�,q_U�EM���,#2
1���@��)��7�>Kq�&)�f�+����e��fj=����Dpp���f�ҋ�@���B[��<k�gaң.��|�4��m�+f%F�C�΄��~y`sԮ'�e2��;>���b��E�]?2w��Y]����m5��Yp��@/HBC���P�G��O��b	D� `
����2��C��8'��rSx����
��2OB]ʟ㔀$t'�[>5���p��U"T ���E{�q0�]'���g?����.�J���+>yr��px��ɕ���ן���,�ݞ�*�.�<&~ũH��>�w��pU;�*�{�Z@]pD�П���o��gx�g�bdo�_g�6/;�%��Z�±�r���>޾w{�G����=g����Dj���|�xL�q��9 �v%�0QN�s�˶���=(�z��`q�PT��w�I�+5v��R�8^nqK����t�,�`;��#V�,�cs�t�q:��o� D���@�X� UT뗬Y���mC 3����|�&�F�!����D�?�n=d�+�b�
���f}��#��=d]9L�eʙ�J��hz����*�{��Wi��,7����읹6�J��y(*�Lj��}4�s3'C�KF��5��?���{,Fp��	��8�5�U33�GC����Ϗh ���U�Ę{'htT��~[8|v_w�� �l�5
��S �/��p�YP��n��E��}s�i�([���f[���f`��-�\N�%��l�J��ꟁ��k�P��^&gD�;w2t��
=kY�T�人����v��之���޷�jr������qϏ���?���zR��;�E#�y�u̟xQ�?~$���-��=�v�6����&���PҙWE@]�3�w���潔�c��@@m�,��ތ��ǂ\� ��y��EC�g�f�2�kM�eS	�3�d%�j�Zl��B�g���)l�vO�3;���|���}L�ݾŧ���������}��ؼ�E��V�ː:�^"wF�g��"ߐaccP�( R��ԀBBbfS?�X*��+6�y""�-E_�<�a�c��W֠�����)蕶;[��8e
א���{4[__���ٍ�͖Cζ�{>ny�Ң�e$ ���l�lOVf�2h��V���^o���U9ט��W��!-M6�t b|GJ��h��z�@���%>
ޙX����/E���5�
bY[�,�泜U5�m�&H��oASca�3�I.�i�<����}M�A����fkz͊��o3y��mm��z�x��c�8K�3�`� ���K)n�> 04�ڢ c�95u�NԪ�rp��񭞐�pY�
��T4�����s��T4��ع�`�-�E�!��A���� ���B�� ,avT�������)nk�<��֜[��_iSw�pKp���C�/���d��D���5Noρ�{[k�0u�دK��Cv<�.:�Q���-�bP��Ħ6pI�qlegu�Uw�[�r�K%�˄	:���f����q��vN�6lN������y��k����0��&}IG�@Q���E���򕫠5�6�`��)��U���r&j�vS���5���Bp���[��.Ë	@\�rtW�:����7����W��kqT���m\�Z�`=�3��L��[��0��P7ץT� 9U�Évs��UR�+���� ��rͿ� ��>s���i�b�ۮ�׳��R��mĵ�CRiZThfi�(�g�w���S��zt��nԤ1}�|��Ƀl��m`����M�J[��j���aʎ��Wc�"G�%�q���k�����܌�0�I��l�t��Ar ),�g\��z�����Q�2!!V�c!��F{dqo�c��?�Sr��Q�}�J���F��IJ���[�0ӝ��3��4�#�5��⁪k�O�A�
���r��63�ˤQ�sPi_�5��.}��Z�h1[�a�a��gAh0�Q�� "�
�ݛB`{:��J�n �) w�S�)h���Rn��]]��z�X�1w����nzx�!܆����CE��ٻﺛ�)`��z4`��"1�/\��EτQɏx(��>�JԄ\���a��@�N��q�͇IFEZ�HiF�Y$$A���^�	��=�:a������j3_z�s�Z�� ��3���<�j�P�N�큰Ӿ'/��+fji�\|LJ BL����~q��8 ��"�Vp�n���9�
N��@B5&.��[�<�H?SN�g���	mwM4��E����0)���<ө�5�*�~)��V�������.�OFK3�&�J��?{�����/�>�W?"�N�镭�n~���RM�g�-H!��z�-3(5W�1�=D�2���]s�w#(ubDY��z�l�����EȀ�����G@B�.4�y��9�R"��ȧ�gTh�]��]�(�b���?$�i��c#C�V���]� �	���7ܚ!�gȊb���>��G�t��e�e�|8 E"҂���jp��K������������Q�O:"y��ze��zN����3�h�r��I�`��e�+0��G�Oyk�x�y��xn:�N��J�;Rel�JN��ۜ���rK�\�OQ��ON����1�hT67���X��Q� O?A__4&�m�6��O��Mu�2ŗ�c����-�*��NH纱R��NR����o�g_j����'R�g&����9)�jn�S�;A��A%��^>�]��#��L=t���'�"�G���WmJ�*�Z%�gN{,,˛�ȱS���o��Do4?Y�6`�m���$���c��d5d�ݡ�fK׿Wj<5�q8ʬ�C�	f��T~ۆ�PE3ܗF*>�����6�¥� )�>a)߃�HQ5�Kx�bM�S�b�ؔ�G}�.���w�(�ā"k`!v.V�7�9�����V%�ŭ�s:���_����Cl�z(!F�9Z��1��P��/e�����=-`�88qL�_�/����ʇ��l�bjMt�?��L�t�h<�����c&//x iޠS��G���4��{A�N#�m�$�|�9�&;��4u]�˪�����@�A|ò}�Evϋ4�Z�$�3Np��W�����G���DU'�������uj��3>���W�#��7��Z́Ɣg��,RQ�
��7��p�S�����-���VZ��r ���J��8��`࿝��^�Au=ĭ���������n�U�P�:����P�su�[���z{�&�����Gb͘���7�����E���������"!qb��� �T T;\w�`����!k�LPӻp�U{)T��]�y_[�T4��by�P���R)	�&m�+	�Η�XafM���,���mV6`{yU-B�h�m��Q�t	N)b���$כ���?L� ��(�Qw��A/��|����4GbM�{�\Ȝm0E���5�R�k�q�bˢ���=9ʈ/�S��vX�RmOk���iЈ�HY�7BG��q�
f�,��\��4��p	�)�'��8G{g�K�{�f�S�������8���D2��ؑ+��<wI��f/����6h|�S(5/k�����v��x�nQ*6��Ž�%�-�@z.v��=4a���%����J�g��#p������� �ts[Y�r�;��m���EƼ�k�r�~TӍ6��]��ؤT�:��R�m���b3�'��N;=A`��b����(:��WWD@�n��b��)���4��'f�8:�K��N��J��P��#���/�R?��	O<F��hz����K������,y���N�kc5�����'/��MI�ְtZ
!�>�rY�}u�y�-�e@�:t~Q�'�X���;��z�(d~�ȥB�(Ce�VⓍ��MeԺ8�m~x����QG��L�>�m�ݫ�L*�����e����[x{�1�NN6;�w���d������<���c�y!X�D�6 ��� t_�De�� �yb������a�3�dMk�H�:��i����2�y�D�mQ��z��+G�p����`<u�nEܬ >9a���(�ϵyd�W�x����͹�٥�����9SИ���B��7���0 �;Q�`�zm�1U��֚�]�b��O�|�zϜ;�&��������{ۻ�������u�F��p�CT���[��B	����p��&+��]����!6�~���$U�)[�y�����f����c�J��$Sa&{*�)�x�G��)��F�)�nʅ�����qR��wUet��pX��j
��N���f��MD�r�o�,@�n�������f�#�eTd�f��0	�C�ɉ��F~����g5Ի�.�ٖ2RE��GiPNA�{��sK�����an!,��ޓs��<Zw�	���(=�B�r)lD.J�FgE	��Rߤ\$A&]L^�`��dEQΊ��1�g�fdn��L��t�C�(��Z�U������'�MTi2��d��c~����7�92��s��������T����=e�vXVd����.���3\�­P�j<�ۯ-~�+|�ՠ��x^h5�l{�|�/��Qe*�44V�ֆ�j�Q��;M�ԁ�bpP��^FI�9����8".J�~WS��}� �m��
��E->�P��X�����
m糿5�*�2�%Pz�c+L���`��C��X�X/#V��$u'|����Wz#k�d6�ĨG&�P�jTò6�$�!	�<	��JI�uX$b׸^l�f�h`<�� ��>�Z@�U���5uBR@��jI&2�u�Jc�o�Bȼ(��\l����I<�"s��f"J!��E�'�Q�_��	���q�Ļ��`��I���\V�xs)�e�ٟԷJ�S��=��$�8���&Fk�t~��4q$u��Oۺ2�$�s��V��!fI��/��u��Zk$3_�*�W�S���Pg,��Ƌ��ʝ�hy'P�{���:p`�g=�@ƶ�^{�Ɛ_��)���?���������H���Ga1.��6�,V��B��˲n��d^\5MDo���XXb5U>��6�7���@%]:,n���+��f�3�� �?�WmWLZ�!�K|���P�:�7�j��zgcAڢN�T+kJ�P!�^�Q��Hw1
'�/#��Ւ|�c]��f�*���ȯϝ{g_\�/"7�L���{���L���je$LUi��w����!!�T�,�)r>r����6%�铀���jqD�Ȋ1I^p�jP�5��D��o�F���/S0݋�T;�z	��_!Uu���>��io����óo�l��'�� �n��Ve���pC��⠂l�TH����Q����\��:�p��Ӊ��J.io7�V���x�AU�w6S��	��ߴ����;�d���~_Z8x��HکU���"Ϻ�Q�����^f��]�t S}d���Q��d, |���K?k�2|�-�׶~�g�ب&۴TmK5U�2�}�%y�����G�[�+g�����= ؾ�A���s���  ����XUr"3 tH��Ɩ�D�cd�Q���=��%:�6�r{�m��J����bC���	79p�5�\��Ȗ�����~�hf���v����nKd)��.�w��Wf:�.��aZ��*�2^�z~R6<�؃e�F�������K��C�1ܹJ��7d��^�&*���C��m��jїk���Ḽ�[��#��������*�Dł�.��qO3C�� t�X퉥��)c��]��/|��	�kzT\D���оCC]�Du�z%1B�ZE͍�HR�˛d�D⮷$r8F0MB����l:<k�R�4\ЎA��-M��Tv少�m�
�8j%%<�Y�'�E�f/���J�d0�aD�������u��Η�iF�s���Ӳ����M���������VV���/3rk��e�D�V��=��ݴ��8B������U��.�<}7�.�����j~�5FѸP�Z��l����Ohn,����#��/�s�t��(ˤ��]\0�o�at�(ҹR��w)�К�R^cS\���lj�	IO�5��y�n���]ŉ�I+wV�CyY.zsn�Z�Gل/Y�xj�io���jზ:��E����-��F��la+Tj��ǭjߝ RX�Nk��:�1+�v*�;h���	��8>E�U�{�ׇ�����4��r\Rq���Q�Y�t>�J����e�8�+"�)t����۽[$�p���㖺��F�Cq[p.x�9Er�U�� �B����S(�o׾��7O9K���mgmP�fBV�8C0d0<���w2M��0Zf�ͣ�u���wu�u-�\����%�`ͯ3�D��f���^q��c9��Um�����3�����b�Y��7:ڗ�"�}�8����ޚ;�SbL������yH��@i������^�h��l���Ù���LqGLT��n'Grj�>�]~���{Y(���O6&s�vZ�� ˝�{��U���o7��VyV��"J�!d�����y�ĵ�p����O��� `4�G���<� �iǵc��StY�eb�.{V��9�x�o}fʚՖZvx�ڦg���)L����|'�v�=Eʓz���b���fm�~V䬊I�*Ϣv2~���h�����]�x�O�F��'s��8��� 2�Q!�Z	�&(|@�<wN�� f^��:s��	��{�c�V]��:Yy�S�)9~�௤x�\'���]ů��H�r��Z�57��
��nL�FuY���Z�/RLq�)�wN���B1����E.zf��PF��us�@
l��?�Rx8`��*B��q�%��H��|)p��P���=�/Т��w����×��F�oX/������@|Q��4ԕCQ$Q^3N�]�ʶPZ�D�+k���׿n���su��
��4C���W�n(G���M�M}O�nR�^K�7T���q�y3a�ېTe�9a��<}�T��� ���p�ű5"M=�xi�@	�ݬv�iq�a8�p������m;�l�TK�E�_�>)��tD�.z�]oB��r$;_�����|��G?�$��R a�G3�2��%�1v2�Z:���>�qq-�em[�C��t�D�A��n�}����W(��U���_�4����^�w�~v�M�/s��l��Úaxgo�:��A<���:!�,��'*(���k$�*b����*dn��̼.��QԫJ����T���ط���1LyjBTe�\����S?���+%9�ZؚH���v����y��b�һ�m��s���c��K�Lzܨ��ʣh�*��=#ҁ���<� ���4Xh�i�����&�
jk�4���{��Q���5f�e��1�e��	���6��
���펹��l�a�΋v�UD�'YƢ�r����Mez�G1g��n2V�\�����nj1`ݐQQ��qUÛ�Ʀ�������V5H �/h�WQ�P�Uŝ�8���}�ތDX�Sp�CG���Z����m��e��9�,~r�:��{9�Whw�tra�Yt��)Iٗ%�s� =9��nS�oA(1]?�1;��S���-�= ��&�%!$��Ep��p�*�i��K�o�,��'[�w,�{���9|$žT�V�vl�6ly���F*�7�j���>��k�
d����WE���2��X�;�<������l}9������A�1��� T�c"UdE��d���p���7�p�g9
�D1����&����ު�@�>s�F��j�0,ʍ Cy��j}����Ӕ֑��g�d2ɯ��c�5�8�*�J��S����ȅ}w
,R��?��"6��ZK$����^.hӘ�N�@�)��n�
�(�o\_��O}2����`��Vc��<�<���4L-��Ɂj�M+ot�i$c�r�7~Y�T�+�e�$"����ΨŠh7�zus��#�M0��j	-7����J�yZ!)�z�׾�� '� �����TȰ�ˁe�*wH�8��U ĸ(Vɶ8�ο�1�q���p*��?�c5�=�7GF4i�tG;���%�v��OP��4�Y�U ��>v�k������}j�S�[<���f>��UwA[wV^����6]�<�4���I�M+�)�R��4������
h�/���|ɺ�����^\���l�~�Z�"�.O_�J��Z?u��Ⱦ�s���W�d��x�\.-������bmI�M���w���@K�❿���[�U?���q+x���5�κH�Ϯ;�����Y�&u>y����)#�	�Zw��q�����6�l��J������b~�rF�������,�z��b�p~P�˒T�F��4��0� ,�W�&k~b"	j�"�����E�ڵ2닮RQq	�:/� �:Lv��7�����;����wb!���ѣ'%h����R+��J���
��=�#�z��`u�Ț](�O׃���U��\5*�.o47y���\�w�X/%�y��{ґ)R{�b�
�,H�>�@��Ճ�R�b"r�(X��1�esضA�b35����� ��`�$%�-J�4B7��l_��|r�AÉ�fǤ9�q�u��m\O��y0E�I�4�a̅�ro&6jjU\���(�@�P\j��-�9�� b-��Z�-m�z�wP������;)I��}l�ز�!�6�"�%H��*d�#��[au@�x�U��7���4S�bֲ ���:b���[����XF/��+UZ�����E��r�W*��%j��(M"FdX;�%E��[{7�zo� ������,Pé�h������X~��n�
a������gǍ:��g7Ϭ}��It��Y��,��t	����8�j�y�g����B����2�|0d��S����厢ם���-@iK�b����D���������/eS�9��zCj��
{�XUhf[g���Y�A���\
���s����d�<���M�����iu�Tj[���C�ni�������+�O��	�	:� ~�x���]�C��/����$��o��g߱�w�u�-4� 
O';j���>��Ae��1��v�HN��n�f'����]�x�{�R�]݆U!��ζZ*�������^�������@L��e�3�	���rs��� C�ՠ#��k��.���擽tr�_��¶rK�ܘT����IB%qDP&�{~N��'���?c->�d�J@�SЋ2�6#��5��f�͢w�x�f���0�P{��,�+x��yut�>F]�d#xQ�5+�@8_��1��d26d�>���H9���	�c���_dgD�Y���4���n�,pS?"O���
3����^ۯʧ!@_���(�mqE^~$&�F�q_������/>Ʈ����b?�g3����%ǫ�"����/�_�|5��ѵM��@D1��U�鉭}�L]���~�~!��m-j����D7��f���Z y.�|I)$���ø�����nS״}|x�R|�Ye��z��Pc)RuH�����e[O���	 �I� ��x������Q.\D�@��&�Z/�ut2�b��J�E�X;�ý��u����pi�\�rb(�wF5���D��W_c�	d�j-+wY��^i8�n�?X��"$��/���j�N:����愳����W��-�A�|;���/X�C��ܺ��t�[#��+���̢�������q���������o�P��7���.�tSZY��	���2��k�����;p�7�������Q����J�R������^c�밶I�P�#�h ��2j�ؙ��� fΌ�:#�g��+`��9���l�7�8٫r^���抱0��	�ĳZ��������X�?���"� :k�F�.��癚�z�)�un
:��E��r��\wGo-���j�e�3<hF�1=�O�r
(.�����czu�C�q*�@O���ʈv�\�"#	�0G؂�h0����\��ie��\����kr���݀���0[b��,��_:��Lb�w�vƅ���yuɻ��V �Ǯb��O�[���>?U{���84~�5��V)��OMR>���6����T�����{4pV穾�/3��-���l��jS�Z��/�:��6�q6G�P܅X�G�j�l�`�57��'v݇����Ov=W�O�����b�iu
�Ys�
=��f��oN��'�� ��(�PV*c-�*ˡ�ecj/,��S:�rYU�9��XAd��J�Ta =�5�ǧ�t��U8��9pb(��ϒ���p�׹R��L�3,u�F�My��c�����lm��}@�`���F�A<����K-�ͩ�����8�Y���9����"�������ӱ���-��0�A�I��4�1>�3�9�n��1����Jޤ��C��!`M�a%�%�o�ǃRyą���x��}
*p�����K��%�;�!�~+y�q��8�l���<ӱ9]�j,�S"�� �	r������:�3]����O.d�*ֵ�i$������n&UI��0�� �+ V�����=�R=)<����ޗ�^K��|�/�(��~�����'�mɟץ��
򬡫p8�S���<�u��u.���h���=w��F��:�����u��e���PG|�-���M֦&��B�n7�'F�;�ѭ{��zFeI�]�Y�D>�9�j�d����^ϲǠZϳ�_ƀA߈:j~V�^�a%^ǘ�i"�7��C��AZ���qw�U�)fi���A����3j���Ss��<�v��碇\҅W0A�ԉL�?S[2���Ă�9.u�B��xF]�������e��k���/��� �H~��wu�̱]����ӗpE3�]|c��/�?~���A��kV�=���������_�!�cv~����|O$���l)���Ԍwy/\zۍnr�%У����`XN[�ꏢ�����o��wS�U<Aݫ�Y��M-�֨jr&��ܩ=L����K�e���u�/|7�t��������Zk��L"r'��1�_��u�3K2l���_�3ֽFM�g�4����#23�!:'ߧ	��=2�,��SP��#�a�^�}ir=Q^��]_��_�c��ɡR=����H7(Rr�klн�3B�����C�~5�!JA���L������:w���ڃ��R͒������M��o�$ �R�(��ZC�+�k��f���o ��Ut�>�H%b�7�BL6g�Gw������&F����l^i��fGk��5�UVVM��.j�ݑ�� ]�K7�`����{�>����[�����MЌ�t?���y^�V�G�?����aC"�Ǵ�Z?o�Xs0����"�%c�f��<�j�?�b�p ���W;<X����y�a5���\|���q>i���̄t�T������~�T���zZ�=��4Ѹ:�3N�p��}/�M1�6\�	�u�I��t��B��4���
�1m^�w�����yoUB2���&����>���c�\�Ƃ�{�r��J�C�/�Q@J���?[!�i���P���q#�u�`����lb����aK<��P�$�_�ՃR&^	��|՞A���3�گ�3�N<[�<"^[ �����U�Ԙ�W���&T˨��8�m�-� ӈ* �h��eAK�sC���������~>�{�)��~nd��N���=��3�UV,��OPt9��W�^"�[����L}6�-��f~f��ջ*�0��gI8_��#z���MЧ󙧤��w5������'��s[9���AD�ʗ�@nu���P!2����D}���
d\x81 ��DL��z�m ��ל�Ō	���
"Z��MW���Q.+��� ��+t���=:8�4�b����a����i'��u(�$�uD	�c�@G/^��oք<��"���*mؿ?ur:B�)�!�`E��gt9w���i��Ka�S{�q|#�~�oj�K�]1y��&�!�ZD�ʗ��	�!qA�F�Hvh�������cU6����Bzw�C_��e���vA�ԍ2ƿ%�Yrp܉i�sٱ��:FT�|��׈�czhJ=� �hD�Ɠ�w)6��רF=h]۱���I�#����3o�+a%�?#ٸ�sĻ�����אw-~ޛ/JwԸ�:_ �� r~>O�T�G�I������@r�A���Qð���;w�}���J�L̉:�m�Z~3
R�q�s���S��wB�Lf�̃�|U �$�s�/�^\c
�M0��o�/�]�C  ���p���E�}��b�#K�����HΈנ�l+��Z�"<ː~��"���b�v���N1����
������B[��K�(4J�%{CT�v�#N:Sg�&<Rh2N5��ح���S��^J��!\qm��N�q�Eqb	)<��<�c@��!|�Oۘ�/�]�ֻ��Rژpվy4���\% -�N�r��)�BP�S�H���8`e�U��4�ֲ-�-�m��!jA��L�����X:���Xe6�*����%=�cs� �{П��S�+�l��ծ�/,�(��A�Y��a�_`��ժ�e�i��sv��O	��� F�E�N��ER��������,��RL�, ��!m��Ǖ�����xd�t���lZ�łHW����h:��a�"!CL���v�JB8o���b���t��ʙ��LqO��2#����eO�/�.b�
!�&l@��t���J��K�4K��NR��R1�z@�RԷ#+>S!|��m?���H+��s�d ���ó/�A{���J�)�U�h�����Ȳv��B�oh_s���Y���[H�@T^�)TR�����\��q���P�,N�5�T�^XL��*����A�r��n�-���]@��`S�3t�X#r�c$��@��VC�eX;1�i��ҥ��.�|��Ã~ᑴq4�����G�����d�[��!%���rA�_'�ҁ/�Ê쯶�T�SLL��F�V���u7̧��闰E���O���fR��
�?���z�v������?άWy|0�q+�?\8s8�0�H,�����~�%�Rn�Ř_8z6�+����O���~ѣ�FSp�D�0�l8	�GȠl,�Z-�8k��V>�� }j�1�f�Q������i_������/fr�[a�	�J��S�9*F�A��Y�L������2�(���������7&6i��r�U�p0ZD5�8ec�˺]:ܭ� z���`���n]������Qo�`C��ml�����kV���qQ�xr+�.��'��SB��r�]�"#:�t:�ٍ�`�#�c��F&�7�V��Vޛ�6�Q�ܮ�xm~�7�3ڳ���l!P���:���n �m�R'�.��e�'@B�N4C?�Ie�������)��N��RZqW�s�m,o��@���{j�d��!��h5I�,n��9p�C}�JQj��R�9�߽��ʗg��$�����W�䰦��ꁡ)�n{(6���6�'q�(G�!��C#��E}��5˼��O_�At�M�Z�Y��%;�+�fWS����wd`�D�1�T�8~� ;��hG��l�y�N��.T�����f��3�W:�DkW��%|�֚�ܶ�/0�_dϞu��	ߢ��k��
���������tH�#�����	��s�6�L��^S�JZ���e�`��o��T�2�{�i��ǯ6���ZA���
��"���i	����g��o'48+۩h[��	Up]p��I�@��8���V�
G����d���E9��r/ug���	ZA���"���PN�X�˛���s^�g	X/ T�&���O�o�n����q�F��h�YR����1����c�C]��j����(E�����`H/��4�s��*n��Q��ja�j81X�):M��@v��1֪���J���+g	V��纤U���Ʀ���]��ُ�RƚI��Nߟ�}�f����t�fpy�lѻL[��~�&"�#�1�&�����%'���#	d�@��ǃ��q��CU�dj</�'u�B�]6a&�B뿠4:-J���#w�2K86y��!YjAt�s�@�gh��S��d�p�6�?�^zq�������k]�$�uVOw�]3��J;�-�M+}�s]��V���M���ɥ�K�!ͨ��?�6�[��\�R{6/��ǲr	�1��.$V1�:P�� ȭB�kG���5g�@�%���@�#�=�xG�资q���C��B��J$|RWn�Ǹ�U��κ��%6HdlH|\���.ϻ�������ov9T�|��Y��w'�dA@T8>qHe��Nɢ �r@��}0TY����M��Հ��"�$�s�ښC��J�2����C�p" ��3KI��kQ�s��'�eᐦ�2/�E�u��葬^�ǖe��k�R�t+M^0��40ÈTr��"z��@1����v������M��q.ذ���A&� )D�0a����]-y�r��p���Mj:�!-p��JS��??��ߙ���
�l�7V�J�L�r�:��#HG�]o'�2�&��.z�Q�_�!_b��Lb}�\L.�0_�oԱ�q��ULw1^Z�,#�m�@��f�S8�:g?X����P)�|&�K�������}5�b� Y/
��ao:{p1�Y8���<���0���i�L؟"{��w�5Q>�-e n�e��h����@P<v*
b5/5��p\/c4���[l�y�	���g�)j9iV�2t���,d���0qX�w�ع0��G���0�Ya�9����pY�V���HP���*���t�70�mܴ�blŏ��pvn�� \��j��o��`���@��U�r��r�믫o[y�V(����?�%or��_� %�JM�2�#A5�LZO3�N�s0Z3�������*���^E_Ӵh��?��f���㕯ђ�$:7�s4Q�x��XX[��ܥ��]*Lk�W��T`�j���EvcD��N�熶_\�-������R�y��	ӟ��u=�+�2Szp���dQW��� ԝe42���	p�9�c@e`�+=q��r�n��wS�������W����ζ�l{0S̟['˺�/���G���Z�_A �~�[� �|pѮ,�����������	V�=���Zo�0�[?;1�(��KL}:�Z�q'b
d�W7A����B=uc��Nؚ�M�)��V�w�C�cu+��� FO����~a.i�}eh���~���� ��0���1�Gئrhu�h��nw��u�1?��ǐdZ94SE��V���*��*�)�� |�� ���ko�=��IAc���L���8�~g|��o]�m��#y�4�� y�+;�Ǟ��1O���I�O�0E��8AF���9���f:%Pz��W�#< 32�9Q�Φ���as��|�_�a��G���7E��N1��E��e��;�m����i���Fc3˕ �
�h�%�ޛ p��t�8��4	��T'�M� /��@ې/g|���:�UG�&ҕ��T2u{!�����t~eh~1������ȯds��%��V~Ӛ֟�=ȨA��:�*��i��"[a��Wʟ�A�f�&����G6'0��8n�nE����Cl � ��(��c�	�:������;[���O��Б�4+�IPm��>F��<cH[�Q�b/3%�+��/�^.�'0R�q�f���x�R�+2���  ��rgC�x��� �b�sS[ �1|�1�l0��W��F������9��Li�yX��)�<wk�8�JT��SdD�&v�R%x�u~�>�I�
~����/��WKJ;V.�/[�G>���{��~�=�s8V'�n��a�9��X���)lw_��{z��L��g���ɫ^�z�NF���2�S�ޗ�ָ�J--!~q�f�,h��(JyI����Y��H�z�M�*w���۴��U����a�zJ���74R�E�#zc!����iz��fc����6`�T�f7yj��♏X����g�6;l�]�k����b�bC���4���gxl�t�뮫hw����s���9Lx���V���v�^7�4�4�:��r��
tr�0A:?�C��!�R����@Kh6����ie{w�ӀNxoo��������D�Q�D%B�^ѯI�tr���Ҹ&��%�_��A��"���*��t�m��0�q\��Q��k���l��E��_R��6Q+�I/�#��ߴ�MeA)Xl���e�{�,;=4)�B��x.f}OHv�T�	a���G�%/�<�N5��� ��G.2�����V9ĥ��+�ۆ�/#�>;Ot�:Z��Rl6~؅�b��V�`Z��Z&5
��h��%qn�����zH�dʑ�y�$���Y�߆�����9b�ny���b�Y]#�����V���ĀFy����kd�dC<ܶn��lŞ�����[@��W �>�9�3�:t}p���a����Y >?�(��ga��:���*�����,M���e� ԧt3-^���9�J��_"e\2�����'���qY�,$�U��ېVo{m��M��]i�%L�p�S�����a��ԟH�#��w�I3��m��jv��0?|N��~��i������4��ˡ����^ ��'4v��ex��50��nP��d8z�w!R%�|�ʈV$װ{�mp�^8޿܅�)zb��{�g��U�#;��;=>c���O�&)��Jk�� g���ㇿ����:�2�h�MEz������33Q��7�r�a�,*ߠ�gDũxK�u̝�E�Q,i��s �+nT�R����|Z��Y׶�G�=�3��I\c��fH�gu�~b��ReͳPC�D�[�o¦J�<,8~]�SF{�<�O,��m˥��/�g&&���g&��/��}ブ���7�Jk�l4��"@�]�6��׌#w4l1�*�W��w�X��sK/�����8d��b���,���R�r��������H�x153��F�LUY^�%s���)8�ah9!����1��������T�E��ՠ�M����G�n���&oa�Jfv�������B�p��aξ�r���L��o��%3�1���M��k�c��)ƺ_Y��g�����G���#�gj��_��GOH��^1������B��j�ȰK�qx�KW�-�nq:�A�������s�pv�����<g�%�;G{�6M+��9��x�M�P�̉}�GQ8��ꪊ%_�N���9�
����;S�n:<ʋ����j"I�٦m�� ^ ��0E>�����;,\�V
'I�~/�F�^<��0�؝B��3mR���ԋ��Z:�RY��҄H���(�9����Op��ƨ�}���#����)~3�mP�&4E���٠�Q7�A�Tʅ�w�}��o� VYV@���@}f���OH�0��:�x�F�<N���e5Y���8��z�0��٥?�Z�&�gk?`�%���h-2⟣��5q�_f�uC6��h�Pi�>��P��E$6)B��B�]9�OI�o%�?�}��}�b�V�Q��1oK���Z��9�����J5f���n���!=
e�S>M)�Wf��v
��.�A�_V*nP ���,d~O�����*��JV�X�4δ3nk���%��`h�%�YC�����}o�p���5*�˥b{/	r�#���<a���
5�~+Zf�H��r5�,��ϯ.�!�Q4�1��<<��1jh[!�y��s�U4�Yѻ�y�LUTi��I,5b���' {QVK\�b;����t�_���?m$��sB��Fר�;ߪ��і�^�-n~jK�I s�81����At?�L$� .6 ���z����8��l�s�G�Qd���]���� �@>*�t��OT=V�����3����⠤V0��ɲ��w�E����'?v�j͙
�]!mC�5��}RH-�������N]�Z����s	p6O"z
���0�N7� �ы�qD?�.���Mi�>F����hD�k!�z�	���u �
,=K����PX$L���jN�r~D��8�n��įdL�6���s����s�B����-��G���U���q��7��|��ě5!ycm����z�׾�7r0���H2�&���R�����Zb���t�p^U;q�����?��� �_s�=r2��|Fj}�7����\](�T<~�:���Mi�EM5u�y
`���cSm"[�3�`m
��S�h��%F( �pZ] _�
O�h& �'�V��V��.e�P���@6ij[�?��Z�[�<��#h�"��$���Z���g�=�2��r��H�W��4��'�rV荂:����u���j� `�"��z���c3��ax��[�$��*�*�5p�#�=��pԄ�a^��0�l�fh�����$Nw��/�eꡦQ ߥ@��ۥ��/��Z Ȳ�^np�M���<��:��5����ޝ��]�|1#�k=_�/H�#R�]nk�겺�q˙�`h�:�8!l5��{ϔ iS����J}�6�ykhJ$�=N�	�9�rߜ�
2�j�J+%�Cd���˖:RK���Y�ٰ�V-!0�?�ܲ-�) ��u���M���/2\���S��:Ɏ�n���,\���y���V�$pZ8�8�y~��]�q@�ާ�����F�@%JlX!㠔�A�pBoh��ؽ��k�� ��6�����˸�hDq=Q�={W����Qa��B75��!GDz�S�h�|G��)�\%[O +��/�����Y��:P�;�~�|�xو�s�<J^Q�"g�-��l��.Y�J�\q��-<$���"N>d+pCʳЀc�����O�YLI>�/�b���������w�+#�����?Ĝ�W�M@���i�-������ ���g�H�2	��\(�%hD�Z��Y��j|��%@�m$ik@y����'�ɧޥƧ�7�K�fIV��8
�ׯhqE��D���˴�K��"7d֭�Ϲ�ԋ�����-�*?Xأt����_��`����;��Q!�T�i����{b�5c�Vn���6`kb�Pa��L-3�`�7s�`W����ͬ�<B�	�,����ܿ�6��~|�X��Cuk��;d�=�"����ӻ�&�>����
�b+��+D�ˉ�&�f��'V/��.F�λl��c�f���.7�{����xX*֦�A����a���q2��SM�6����hk�t�ӿۀ�/&����u�t�`�1��Q)�nG�T��]�[�z�l,fBM4�x$��Ò�8`�Q4*vy�S���5J�~�����z�A�$/ï8��9��e������@����d���gp��ݻQ��.��J��Bq��n?Ӏ3p��@y���Y���.^�N^�bǉi����z�H��4��i��_��R�߉x8���:fƃ�.�}>k�4eI'��w�-PT���$��.��8����B@@�u��Ok�-x���HB�1y�"avD�ZA�QqvJi���Z���sS<�g\�W8�����:[A�/�e���H^<w?���"�eơ��ã؉m�0y��H�̍��Gb�k��(Gߓgiq�D�I�tOM��]f��6^�89xaȳIE}���r'��p�B��:��Úr���'u��{F�)��q�0p 
(�9��n����l[�m�k�^�����4!i[����1�J�x��y(`�{��g�q`�Xh+�W�!d~��Q"��lTw�F:O�>�͔sV5�v���̤�G��nc7jC��Juo�/��*Z��/5w�}��3%B��ĥK��8
�g1{�t�Es]�)*>�O��h<ұ8IΠk�Q���ϊz%��6e3���]0��H3�wDQ�'�x�� �w��]�y"�=���M�o6K�9���D!6
f�ӝ�YWT���#Ӊ�#{Eo�[�p_���֔c:%VM�@����aR�����˾i����9�z�*��V2
���=��R��kN�8ڪ���+����g~*?���Ñnp�Kw ke:�G�S���H۝�A�cfXd��[sH�V�rp�R�ƥ����/(xUn�y�u�>m�j�eD�����0�5E�Q��N�z/�j�ru/'�׵n�>
��~�t�)F�Y�\��q�
X���_��^�W��F�,ǌ�� g�|C􅢤�@@W��� ,�΂u�W:Ϸ�Ȯ��НU[�g�-��{����F���������9�al-��bҏ���C!���b�ƦUƁ@��a{H���uQf�{�,���_���9�F�p=l�a�X
��`	X\l�� �\����d�H��֐���Y��]�K��{_�]��gwd>�j?��_M���tS31�LEf�Í���V�i�G�6�	��,?4#^��o����;�/����k[[W�4�9��������"�}�Wv�C����,��!SU� ��a�⁓jgqfS�>-E�.�֝����.eyk�̷ ��,J����������h5 J�+�ꈗ=���qAj+�˒�s����L��.����24��O��bW@,lr7�"R��@�ak
DV%�f��j�[��N�4�t��C�".����_0(��[�5�y��ا��KB��!��=zn���D���僤����e�=��Q��>;B���>��lU~�c���3�c�n>���.�ݾ��1���� #I�F�D6���֢���E�����P��	�0���98����������7(�_�SR�4㿓��lhFJ�ѓ�@[i�
�Fį��[����o\�-ߞ���XP!���'fh1�ծ��y7hs���W�he�+x!��ܢ�M��I�NxP��\��>����!���[:�li���!3[(<`Y���l8^�P����Ӫ�Z�I���
nI��i�hy#K��-�5c�d]gt�󫅦�4�� @��w'p᫞��F�vm ��~�����MK�d���Zi�F���HWbL!L~���u�����=�w�U�VGq��N�+?����D�vѿ/�W�y"Y�
�����^��A6�H٨?�;?��V����5)r��/}�y���>��H�7��ݑ��"&�ǁ�s��<D��^QV1�rW�,��2bY7&
�a����Tb��e4� �z͒YR�W���v,�v
xe���a�V@Ǫ���'-�~��1�P��B������7֬n³�@ �����vPZ����*X��̙B]��0�p;��q���t&��fpP��Ɉ�"�C~�;��b�N��� >�
�<~�r��]�� ���FG���B�{(�d�!�y�wH�ƱϢ=.�X�;9��(�:C}%�k� �n:T����R��4�K�@f���Pgp�s�Th?;�AX����ٖh�+<nL���Z[O֬��������%ԨQH^��d����u�����eV��[{"E1H���#?~�g5���<�F�CW,�_�JJdr� BH���tr�9����eg�V���7�S\���uvE՘r��<?M�A�& �f�@�r;�I}k�*�%焱�\i��,FI�Q��*�f�#�}]%��0���~%i{��Lo��i�}��Sy��Y�y�+f�����?%��(��e��.�=�ߗ��$T��vos�^�yM�4��I��J o�/��dͧ�k`H�l�
;U� �2#�nٙ"JSQ��S\�}��#�X�?A+�����$�-��{���
.�^�e6�cF�Ѳ�(�*���ӓ+��5F�C�iI��+ڜj�LG��1�XV��`��@R.q�7L�#Cf�X1`����{`�Ru/q8Wd#�*D��5������3��b�6�� �^NCٵ��	�Ug�bŞ��I�u�]��7�?O gL��QH2	�8���%Ih��M��SV�~K7�K����M�n�d�q��Zj�"�.[�_2����C�� SkOL㝳�t�A���ɬ���݊�ҋbj���k ۾����Oʔ��T��7�|)�۳}������ܟ�T\N#���w��<q�Ձ�V���3��;��]�A}��l��̋��;��:�h��q9*}�65[����N��і�eU6�"����=_��1_:���VCmKu'���:^���&�	�e��w��LnпRe��Λ��+�$��Bm�8@h���;St`0���m��7�{��6m�-�2 Ya���5Z-�{���M,��R��ͧ�Z>?l���ZXe
DF�b���c.W۞C_*J}K�n�!���ٴ5:�
�+��*��%��Y��V�*�p�� ���H�ǌj_��w~p�u�ړU�Ʋ�T4	VŴA�Gŝ-�Uqp�.�8� ����K+�~����G����1�H���9�r�"��b�ƻT.H��fY$� I����f�i�9�:�
x�ً�b={*��;�#" X�I��|2
7�ֹZ���Hm�g'3��!��ǈm ��VG�;^�@��� �+/�8��<$]��� {JT�!�1#~� ,��(_lQ;�Ї;���s�.��ބ��Q�t��7I?x�f]�<�/jX�G���-���8�����k4�ju|e�R��z�m��u���Ҝ��s�s�.�SU_��#;|��N��C��N��`��z��N��mW�i�6�Y=��1m��Q�����c檔Aw}S��V<`S8���mb������&�g`������
GOP��q�̡h�}O"�E@�	,M6|ym��q��    �
�lg�FK ����G����g�    YZ