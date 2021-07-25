#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="824552912"
MD5="aa10b3ff7c5a9c4ed98bdda2c6e61efe"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22824"
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
	echo Date of packaging: Sun Jul 25 15:57:26 -03 2021
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
�7zXZ  �ִF !   �X���X�] �}��1Dd]����P�t�F��:��#�ߩ&Î[H��{�E�� I����TZ)éģ	��e�M<�A,}��+�!�̯�ީ�<�]d³D��k�s�44 XJq�)*�J�|�'�`���!���.1�qZ�w.Z�5����*[0�Oɡw�>eF�4�;!ꬔ @̼�&H564��E���> �-�!Aw��yp�Y�<� ��|/$bNǣ,��9q1� 0|����fL�y�dc�MA��{��jk9���h���ۓ�L�\yV��V����DM�z*�Z5� ����v��\�+�3R[��b-u�̭O\��b�ʭ��
�s�ZL�܏�$'NT\�n2��rȴ�޷�/�_�QŃ���un�a�~��D>�VXF�_����<��=B�bcw�ï,n�'�ze�<`J:HQ�ǆ��~9�9�$�e��}�.g;	�#��Y}8���3Lj<���g�,�m��]�0G���`�R��H]�fC5� fp
���ɀ{��k������`�?�X�1:�x �t��6�؊vw��S��&�XF?�Ăٔ:��gT77�IH��K_��i��w��9�W����_�Ux�QSQ:ہ����sy���#Ý�ii([�E�� �#�,�I�'�yU�6��T:��+������&���x�>�V�J4Y�ªB}�)I�Q (��!.m��nO;W-.��r��p��ۼ��ھ;�/���i�o�r:�&�ƹl����Re`���S��|��1�pbQ}���+fVi3 �tS����)�Xh���Q�uT�I"8�]�?Z'�Z�����<��d�Lti���e�GW�Nw�\��!h4\7dr���C>X�dK>�Z��r��y��KƎ+�����#�~��P��j�����݇J<�h�gW�	mT��tq�9?�˴�L�w�*�����
�I��=�"�*��z�N7��{�%�N��m�RPIZDT8HpU��������*f���S)ё���1�n6�e�-EK9"#������e��&>�.�
����tF��g��0��©�c�v,��Z�S���fܬ8K��O]��|���:�U��8�>k\��eK+�!3w얅B�t4����ʞ��E�����QV�d
&��V������N��|�1?�o�Rt���W�7N��ș��I{����VL��[��m6|��d�D@��a��`���ZN�S0�^���)�œ�����Y���xFt�׭KR�f��nVŠ��\�LM�>K�4>7E9�r	�ܸ87F�(�t�K5���D`^4,��S-��@����)v��3|Bz���h5O�G���yj�
�ɻ��t������;q��:��9���~��}�ٚ�dߖ������!tmy��Cm�wc�HF$nN�0�oI���+㐟Iu�%�"�Q��Y��G!"�\Ȇ$VR�@���0��*����m-zl7���f]�s��dƎG��]r;lV~�&�u�x�=%�_�E.8#I���|TO�_P܉�.׎��o�a4#�o��!�*ۏ-��NI\`4�J(ʅ2�Vv(ud��+�����j��/n���O�o����LP����mN��XO��o0uSo|]M^��m0�-�X����sK�{���Y��X	J{e�TNXF�d\�k����wC#�'*���C��yH"2���&�V�eK10r+-D�Z&������{.����h�kA�ս�jI|�����w��3����iO.Z��x��|�خ�����u`����`�|�]�u�M���R�&0W�tE�U�]/�W3Z��ޘ�4����mk=19,�L�D�/oki�N��[8� �_��o  ��c�}�5	*5�5�C��Co��xr���>Ij��_hS �+�G'Kg�2�0O;x4�'N�|�vx�Fq�n�+�
̄������5υWx$����A	H1�&�A�^,:��TZS�Y�.��{|�뙹(�+�m���`pbc)&�W�4��M��V��K�	P������0���X4�2�B8��9������V����f;�����w��+�S����6Z�H`�i�g�\%����/���7�
��A�͗r��k78"�hS�aH�Y;y�M�򱱿0����{��
/עsp�d�z�<��ӽi�N]$�e�	n��J�B��䧱Rh+V5�T�P�T-�D�A�J����b�^���c8�O<U��w��\���~e0i��~}��DP����IY�b���Z��(����	���Dc���,-a
�������xW��߼�ø�/�}r�mrQ;�డ^.Y�=�GJg�4i(�(��y
���#�Pr��R*�v�N�zG�E	.�ZX�%+���#;��d���
����%��D��:��1��=�79;��d��/�uA���Io|���!�O(�A��jyPȕŊu�tW�ջ�d���ŉء'�LHY�N���n[*h�Ma#�1��x�yR�JX*����{q���C|g��8qW�'Pl\:ٰ����{'�@����(W���z���.V�67�#�ɥ�������������`���
n�>�������.�YK5�<�/d*��ni疅��/目�K�h^��G��,�Ř&F^m�!����lûKax����~	�8K��(�ps�8��w2Z�RV�w�C7\kG4+O��a����2q	���:��ϔ ��)�g�tcdL�hQ.���POHL�L��-�6'�0�Wt�5��
��:�ة�g[QܘV�'*9�'�K������<�װ�|&�q��>W����sRd�&
���.�3q�>����6@G���g���l����b�o2>Y�9�u���G
s��J��L���� ��?p˿�`U���a�:��SW	�'���;ꗛuGDm�5 ����(�*���
��.���h��5=��-��3��<)��ѩ����sN�YfP_J�E��h~� zK_��q���O��g]�������8�Y�D����]~�o�+?����cmx'� ���	��%�#ST��ٽ6"��J�4af�PO�p�K��C�J��>�{��(��D�Z�i\�W���� K��=��6��T�)����ߋ�D��S�3σڤGOm_�ť^��� ��7��]uUC���@pa`Ӱ��K~ �P� V_C^���/(����me"��!ߨz��$�#D���chX�m�e����K=�Ղ5D��+7��gYa_��h4s�2���]f"97)Zڷ7J�`*��S^�4��"cө^��㐪ҫЖ�jvF�j!+P�n�V���D)��Czk^Ȝ�㥸�?��[�R�֏W�Y� ��l��@�b3�I���¶� N���z�Zà��?�|w���{M�*~[I�^�/��@ދAo��P3E;ӿ�V�B�̣?���z�d1i1�1z��%���'%? 7����c����K�f�ӷ�Iʞ���E(!�p�QF�ؗQ��~������h]�"�S��j�v_�¬i��زԀ��\���V #�5s��D��h�R�֓�)��a|e���P����ue���?�����4`2v� ��u�d��2$b^�B;2��\a�'���;0<�(���q��*ᾦH�X�xZ�E����Z��q�Xg�+����3�œ7�ZC_2�����(��bv1ny{:K^fKs�"=ok\db�_@�o������@�	_V�������s�m�s���Ɉ|y�e��T�$���O���p��F��C4Q	{꬞��� f�Px@3V����>�5*'��2q]�Zg�r�qe����테���c-&�t�R[q��6��� +��)j����E����F���%�r�FO\���.�g��*��?"����JN��P3Ma'GD
|�g>$� ؿo`n�׵�����JQ��V/�v#�n�ÿP�_�K8`�ܖ��a1ȩ�fw�<ݚ�mR�E�"r��,���R��<R�۾,+Ty)���ieS�h�$������A�EP�Ʊc�+6CIir 
gV򀾐�_
z����ڱ;Ժ�L�=o���͒�A�z��NE��V-��Ab�U;$�K��Om	Z?]��� ZJhb���;e��,�y/z��!����w��Ҍ�U�R*���7E�k����[�Rm��HfT
��Ju��5�u� ��X��EV.�i�ӫ�v[�B/��g�ɬ����v����*'}�$��HJ�-�� ������ت�ɑ���FC��,]��k:+����c-�K����J��;4<e9i�M�E���Pvn��t7f?��	����P`��3]C��o/O�
�3'b�!��♄XJ�He��!�ek�?�o:=-yA��f,Շ������M0���@�p�`�la�?���JI�8�����T�D�U��Ĭ�4/�mK3D��ܩwc�տ쭧,��No�|��ݞ�-�>���PR`.�o!��J����4�ƾ�qlQ	���q�3�x�[�:�|��q�v?_zZ�3�y\�%�؇L���ܣ���m��ig�S0lI��� Y7bV�F� �;�틜T��}�/�����H.�p,��ۨDf=7�l��a�͛����;B2/ʆ�.�v�x�(�ke|'��^��j=Gr{�R���$�
0L�pEQ�����\�� Q��a^b�/��Ƭ�����2f[���#P_Q�ՠΔ��_��d�K�T&�J"��]�l#*O<s1���r�]��t>3x���D#���Q���@�Fr@�=	y�:�,)��L?���?���ŉ�W�X���{�,B��˷T�-(.ǥ��X1��2�������i�o�*��U-��\	�^r�P��&e��Q�t�2�f�%��� ����&����e�C��>���b���Ѕ��3��+�|T�S��j>�̩���B�d�;��֟��΢۞y�	F���}�Bo�m!eC�PI݅�2�E��ՂG�!�[]s����x��B����G)�`^�\�m:T��8�ǕCǠ��jt�m~1sY����j�>�$,žj�-�]yH��.�#�S.,���Q^`�v�];7��)É�gm��1)��dw�DjM��E��W������ܖ���T�Y�q��^}������5�ziWfA�}�C��ݴ��m����~��I�~��g��/�S���p+������p�X����û���;��9+C�N���ʣ���XY����<V<���(V�LJUBF�;0��tW�g���\�����Q�m_��-ì:ѯ�gJ�1^.ͻ]���k���|�3��:7���\��36��Ӈ�8�C�`)I{�G���?`x�ɐ �H�M���F":u�G����KJ���	a���O>&���$(}@�B�R��4�x������^'W&���1C��a穮���~M,�Ӳv����!�l�ޣY��%-m���/���颯��ƭ�X�x�!��F��-�����i9 �����6��c��*��I�����������gh���(H��U	����\{��lظK�>g�Z��v����Dp߬a/0���+ޝ�z͵��Qv^Gob�y5p�B�Sx�GS�&��7��S����#n��(�e��%�T��UP�oTg:�/�[���F��،H��ɍ��M�h��eAY�Vt���?y���j��#�Sl����U���gV^U��l �(��xiĠM���٬�\���5�6���.5�r#R����t����x/A C\�:ǘ�pt���X[̈́�'Q���+Ȓ���ye����
KgyQ�0��4E����Rc1P}��B��¼sf�R�Rtc�j�dY8�Q���hV5�!�}�P���{�e&���ֻ��t\v��5{���ݱ!1�&1�~Ag#��� Ղ��E�/f(R/����6�֖��q�l�G폋�T���,���Z�}�i<9+e5-|3��LP�Tt�]'zE�[�)��n�#V��(d2hާx������R�W��=��j�Ĵ�<4�%��������4a�V��Y��IV����[a&r�a^2w �%.��(�r��Ȟ'�P6·�FR�s��_��f�9+puW�1��⥣�d��2Rk�����e�ι-�:o�J�r�=��N8��v�*�\Ѧ�^��X�%��Kr�Q�;)���)�2��wn����:���u��6�6�����V��K5�u�����2`D ��9��H�ߊud� �@(݆E��35gU����X<�n&�-�\n�F�:K��)5���"��a2���sL&�n���]��w�E��Sŉ��.Â\Z�������H=?�K������-J����S�xvZ��%k���/��J��?8����S�қ�Pj5��h,����θbCB�^c��ڊA�c��I�Eԫ���e��O����	$"Z�J���K] uw/V�襌ᠿaWX��Z4��[�2��K�p��)@�*H�`::!����ϝ�'�mT[%�.����j�7�R�5��x����>x��%�c��!�Z9�?��Q�.w#����gA\B�zT������u,+y���\V�y�m�
��D
�j��?O���"��	t���8X���?��u-�.g�h��"3D����fH�O����������%�z0}2���O{���&�2�7��G���1/��〹��Y���ď�=�?e��^�I������� <��xmp�1 9�^և]ͱ��Ш��J��8vv�������՛�� �Oes�A��G;�����������<��j�2:�w킼�X�@I>������6�� �Ӫ��N0w򁁜��oN�]*��_���%��V��爑���.B�	�����W��JiR����N���+�Od��6������-0@��x�9�fnngvR�ܫ�3���`hvcĒ޿�2��8�L�ۭ]A..i��S�����4�öUk���ˍy���Z�b6�pD��6�D����)Ky�?�,35 ʿ��Q� qfU@��$�$�<�<j��Qo ���k�@���!=%�f�����������)�SЂ���;1�Y��p��W�	�]q��^ʙZ��r��Ʌ
!�<��G	U���9 a�Sx����C�_��'����������Ϙ����8��kZ!��5��ڛ\�A�X��f�Ci)�Zg�����D�mA^(<�5-j���� �5�.{��!�õ��{'�\����S�A�Nel�L[Z�6�S�5��o'�-Ve��ǐ��=�}PAz0�>e4O��"�ie�	�0`�ں�6� �}�7WJ���d����Z0���,��M���}�[�tj�0Ei�-��M����� ��Z>�"�fV�W�&�_y���\��3g�:Fy���8��5���5�y�*ס�-̠Z���~(m���c^4x�r�j�lx��jc+KW��.����iS#���ԓcگ�R�g2�(��@�� e�KfB眐�\��r!mb���s?b� �X�8B���x��c�*���\�=�0�΂s���n�iࢿf�m��Q�,��o�AY��L:�~C=w��Nnѩ~ަ[3�/n�F���T7U���1X�byf��o�@H��HZ��AG�M��.�22������S�>���+l��CN��:o�X2�)���'�6�qpTxZ�*��	�۪�ᗨ�*�%��&�a$���L
=AK�M�^���A�*��l�y��_T'6���+��f�YE_�}�2�C���+�K��<�1]�lwr�<圏�Gr4��w������έ����~a���߬F��&�ք�:��'p�G��հ�Y�q�'�w��sV'�j7inҨ2m�6�Ǉ���F��")-�q;��9{r�S7<���'i\�J�霫��|�c�g;:�[	4	z�������g
��7�%H1�`�v;+)A̖x��?z���4��td���U<�L2	*Ѱ�[i�~��>�2�dA�\��d���
�+I��0x�#ă3���D��u�v'b)�� �#��/ĦM������
RQ�lʐOD�$�tk�2�Y���hŕq(���B�T�~�0��M#�i����n�L�qk)��+d<Lʅ��|�}:����)�]Yy���jt�	��Y�$�x��V'kB<D\����a;���k�79��]��=)۪����{#Ĵ1��Ȼ/X*���q�i�&f�!�t&�ߜy�:�B��",[=���X Hi���3]�P�x���M:���tAQ���Kpի�B!�dh����t��4��J���o߁c��}����Np�a�^t��Z�)�W�+3�i�K:��{:Ķ�X:0vO�t��.�?aAp����1���.�g���4�+�E�찫���1�m(	I��Q*Z ��D��#?5�r����l�)��ޢ��G8Vd���׿%�Ɉ�<�j��&͜	��MLGw��e�C����J�6�a3����w.m>�!mp�2Q��f��;d�o>���F�Ad���}>���ވ��;QLY;�{][��d��9�� {)���>(�C&_��?IҖ�,�K}��)?�{ŗ:һ�&���Vl��C�C�� �=�X�
� {��������@��#�T L���ca�̝�Qq�h�v��i�j�so4�VZ�U ��Џ����N��G>�-P�Z�ؓ<�6\Le��&q��?*��=��-�U�{���)j�µ\2� � ɿ�V ���n[���s���"�3<A������kI߸�(؇�PB�H�`�}/A�4��**�Ȣ���P�;���\��Klұћ�G�ҧ��D�C���ڞc�7뎦OJ�{���!s�.���;����󔀟F�"���?��Vw[^Н� ��1n��ᇮJ�~�{X���ۗ:`�XCN$�T�>ި����둒s��8<��j�d�wa��7 �l���,�>�ȸ%";�R��g:�G�zn6nn\�V���o�&��o{[�� Ӓ�hʫ���г���N��jf�z�y�������zi��;H	���#���&�_�/��	t|K`�!��E�,➙�	Rو�<T YY�s���iڼ+1"+�c[0!��j����50�n-�#˴����+��Ö<#)+1�P�]@ď0o'kc�ׂ��̔y�`��Tː�b�/�4�iߖSґ���^aXڎ%ԍLk������䢃�����Rr���jY�n�UQ~�ެ��B�NaB�k�H�V7�8Q�l�1��2Q!`��V��2�JeP��t�Z���S�G��`Ε�+J��+neĝ?)�H��_5S�6Z�s�q����&�����^����H�X�$&HD����՘E.��YQ�c�\쁠� k�I��p�bJ.\�<�6Z�'��HG&ԵMȊ��h���ѭ��5'|ڥD�0��ʄ�~!((+�м%%j(��s�<شYG��v3�UrdHL4��*��R�X���F�}�v���D���s�]�Zs֊�
#�0&�"����rL29��Q.<%���c��7>;_MΧ�e��bM�y���j}�
P@Օ�e����8�rUm�g~ew�|dv@Z����3�ys]��{
?��T�|���␷��֜�Q5d�F0��#{8|Y�o��%�+�����=�h�]y`��^�44�g��z��mek�_Q��]$�ix�@q�l��8�M�H�
Kc��7�J������=C�+hL���F�V�I^V�\"˵9�/�̲L�d�BY�Y��B�5�a�1O��ΏB��Pib�Ͼ�9�4Wg�"�68��\`�����Autl�Hc+�v���G�^:��íCXL��y%�ӤZs'��p:�v�@Ϳŷ3�(���Kv�8�j����ig�뾄q/y��h$ܺ)�n+nPc2�5Ć]�n���x�}��Vh{��F�ZZ%�� �ƨw��R�#O�lv��YQ�Q��8O��Ì!�:�<F��.�P	�b}�Z��K�7�%}uW4�vRExa���O���>�d�y��h's5.�^��`����/;��(��pmqEN�Շ�ӌ�J�_ӄ�MOW��'�[�<���<��s=_�0�B��>OO��Nn�@x���"L�0F}4Y�Z�����:��/<��haҳ]M7��mG�$�����e
��O���c#Ji8�KJ�RR��З��|	p<��-!v�
�ʮ�;�eR���@[~ކB{D$��*j���7I������BE��񵚓��4�|u+�5�����<L�e���?��]�o�lIwoj�#�3��|��$v�1�3 �7.c��*��2�*��j-�@��<���ٱ*ȃ@Yb�:��!Պ� �)^5�6��1B�����6�[��%Lw�h;+�fxGߚ=i��W�7��y��1�Ty�e��~��N��Q<�CE���=}Շ;��7�7aB�[�2�L0%h���|�E�2z�@�n�'W\)hVbW�݅��33m��� 1�U��ez�VȠ��j)�
P����nR�N�4� S� ��y9;�� �a	]���o�Jr¸�l}Z��S=��N7ԕ��R���|�s�����Ұ���|f�%Tˎ���~���̐3�g�f����x�f��-x�)����c��X{m�c���
���]Z:
AB����3�EʙIV��%�~��帪�e{A�����g��/:� ��ڒ��(��Q|�%+�/@�Q����Zxک�!�-�� #f��@GJkI ���m���G=�=.~�o�>����`e`�S���գ/"�<.�u�������2�g��Qpϛ����-��?���4K����������$��*��?P�-ա��1:oX=���S� �-ڙ��M�r+��I�V�c#���@2@s�Z,;/vl��+����N��xY�fS+ki~��U{(q>I��8O_���3�Gx���X����P%eN@��=����&H"�wZ�~�*�0=�?��2#�-i��|�J�0Y����M�j���j�.Ƴ��?����2�T&O��,�P�����	�EfGE׺���\,�{*p�.!��\�$��x�:�H�jl�W�Q��-���5��m���	4sCv��.��Ǝ��9o9��h��-�m1Y��E�3�5�8��wHl��豷$����������?��ϊؙ^i.`R�>�ޓ� ��������S���KP��(�L��B�|����K,�Ȩ�X��1��A���_1A.�-_����]��*�w�b�eJc��[���=߹%��d)�z7�2ߙ�!҂'B��m����hGp��D�ˋ�V���҄�N,$82oŁ��=o>�Vw������;
����W-�d�M�C�C
���Gq��-�d2�wF>����_����a�h����9����	�j	#*�ou!y0�KD2.�s�1��ώ#ע2i��(%���&.8VZ���]����e# .�փF�.����
y�ɖ�W���$?�X�ي+cu���xN���c` �����@sA�Igۻ{f���"O(r��Y�,v�C�=Ow�_���;�$�5�����5�����D��vc~��4[��asg��6O���g��m�o/��:��˘���>��ݨ�}���Û�W5_�尹+k$W
K�*9�qW>���5�|k��Ǝ��DS2[w䁡�� w�̓��p8 �G���OiIR���-�g����y|W���Q��7{V��jeeօJ%u��q]p���@dp͹q�;��q�����]T �+e|j�������DT���t��ȃ"�x#���I�k�X��!�)R��{�\�kc{0�G�u]|�
�;U:mmw���f�8�=��9��df+hA#9��9*�m��]ܽ��m\�PUj�vɂ��H�Ω����K�/�1?aQ5%a*B��<[¥`��0����>O��qL���0|9��G������kѐĠ��o��a�ѐ���?�_F���Y5X�
(�Eb�\� ��˟>[V���L�-�����l<�R�EF�����2,��P6l@�@�+�9�_��@	x�
�?G�+	9�yM6�cFr�W�&���jv��m*(���A��K����Xh��35�5^�f,��NwS$.�i4rq���`�E���5[j�O�(�XA ��-c�QC���)d�9�J�>������]:yD��a<yՓ^f��d�-8U�k�z6�	�IVYH���$D%`���H���t%�0�(]�0� ���]=��s�m�\ù�~:*�l���G�c�W�0}��/��y8C@�h�����sUGK��/`lK�Z��M�PQB�&X�̨<T�/M����G�&,p:fI$�=�ʡ�1�e!&��S(H!���g�d�V]�Y��l�����J�q�c�\�:��\{��&���j*	���5S��Ňo�Wl��e�����="ج�M�	�q�/gݠBuR��k!ک)@2�'��_7)��7�k�F!_Ii�%�,��Q�c�(���$h}���{�J�h����V�"�'�<��ͱ/	1D7O���e_V��x���^��z�p��{�����'&�Gf���cDO�FNH"�!,��Rb8,VhU�v�уa�nl�$A�׉N���[�M�������E��4�T�h:>�R���.�5�L
����'Y���S�t��iE�x���Y����9o�cb*)vA�:��QԥI�x�3C��O=%�����S�E0:'&I,J�8�fM�4�����N�(G�D�$�d��������n�B�|��L��cgok�����)��	��4���Q�W5���Q+۟N���qx:�0�uz؅�����	��pl�V$�1���2Y�e�v�p����J��Zo�+����.��kIT�Əg�_F�G�# �g �7h��q�;�3�\��!���%W�㩬��X$Φ�!��m��ʀ�$�\ҡE��r���l�\���o`��{�;=���w���!�o��B��F��y�3kRɰ�[�`���0��/L�`7u2Y0�0�*i2�*����њ�1T��9��=�c,�Q��f��������s� _Q��X�ޣ��m�p�i���,�>ͶEy��dp��y�h�|�$O����Mi|0h~���-�X\ȐH��9x�L��-��=�,��M-�^��O�\����U��h�����?�nf����k�T'�fTR��f�������@j��g8�)_ء-t�y5��;K������;�YrqO��s�����嵿�6�O5�0���%5|W@��!������k�6��X�&���2l�m�~����^2戌��w'B^ #��#.���]R�y�d�B˥�r��=�;}�ь�5�8�#ΦWӉ�Gu��v��W��X�9��7Xሓ�L2o)��f*�>z(�bd�����.N�Px�Y�~G��sT�'ЊU!g2�����V�6�9by���Q�z�h�Q����f���\���S�w�BR(�.Zn͖$	I���U�l&8�g�r�˔��G�쩎���$��3$P�0Ǥ�k�mL�I��P%�Kx��\�E���
#G�PV���4�?��^j�ځ�����B�5�6���Ծ��'�"e�"6�8�Pn�*Gtf�t_S���G=i�3�a;,}� s��-�]�����@$D�h*�4ш[�<#�,��M��V� ��ed����2R)>sD[y�hk��Ϻy�xX(y�����)��������7��lx��f���ɜ��Mg�asY�j�jf��"(i����Lto?�0	�u����X��sG��&��㝊����������$�/���!W�"]\U�-WY�����{湵D"Nr�y2�a4���ςQ��7��<'�L�J�g�@l���.���[_Ý?;���1,�Ab����F�S��_�H�9�����$F@�.���9��kjC6�B�6��_E�sz�~P��N����ƵE��^A���,�����L���&���t�e�}o�p
 JeҰ�ؼ>T;K[� ��J��*Z�D@�Xrb]����ӽeL�qo�S
�η���i���i�5������G�_��A|�=�0��[�[_�|�����0�&
�ҵ-i��Eg��׽���T������5��f/u+	��TT/�������r��_�X[��i���W$T�=uW�<?����x�}�9=�e Û�
,��[��J���!��-��F�b�~��!�n��E��ox�Ԑ��`��#��Q��1*�4�?d��ݬ{��壋�Pj��v[�h�M��f��LYۙW��K���+����u�M
������@$Ɇ�[]cI	 �J�2C4��Ep������ۍ�)�I��e�?���ų��}(P}��1r�����>��d+ȸ�i;PEò\�]�D�鏻�̂��FXq&RO�G�ԝ텨_���ͣA/�w R�+�\ v�V�R�J27Ӝ�o�)G���ڜ�^ӆV`?��7�2���{��{��B�Xw�nqe^�F]��ǻ��9������=�&��X����5���:�O�dg8I@��*su��/I��T1��0hſ4_7��r���+���	�X�2^s-�H��%�N�'8IMoʛ��Q��g�߃��ʗ*�v�Ƶ2���;|����B5�O�yc�q����f�F!զ�I8�\q��&�����Q��@ ����@6[�r(s`R�6�K��^0��V���n�������PU����(��;z�H��D��Gk��<N���n� Z�Vd�2Z��Y�,u��(kwK�#�q(�( �Й,�ɵ-cLp�l�P�}��
���Of�p��C����#5���<Wi�����[u��#W�(��/@=����Qm�~lq���K�ЗpxV���.Ҹ��E��ξ�|�Jj�`��"<*����O����bV��-�y�&�ѕN��x�L�+.?�K�]���U�|�6)m5�̉mV$��>Ai3J&�0�!;����ѭ!�W�맰�b@q�4B��=��~n�<��]������9���Y��찜D[��qP;)&E�T�e���:��Ñ�v��������_��('���9)�F��GW��x7[k�lkPl{+6�f�]�D�`^[s%:$%��}0JG�+��m�������O[�c
�ᳯD/h*��ODۍ:��7�[M��G��@e���w�Ӎ��4��`L�b��*��C�b`�S\<�2�HB�]���~��Qa~:h-jI�[�����3�9��1�2cZz��g�Md�/:���8%�n/��}q:G�{�U�K��ȶf���_�;�i����P��̀u�X��vw5ނfsa�U�\e"%#q�:��4j���͕<&2bn?j1߃��Z���2-h���Gt�	ͫ�8�µ�_��i�ɆK�VU�6�CP�Y�g�z��^@� cKi�yv��?\�������.��rX =��rm�W HWQFkGx0�b*0�*Kn���I�V���kӊj'e���>�5LF�_�h~��6]s�XԔ~.�x3v���ӎ@��S�:c&3�B���= �U����Iڗ��O������}���^�+��^$�U�y�ߤC뾖��$!8���l�lM��|��Ii+(k��ʂ$��m<{��tU�U_J��t��_�tѣ;0ƁT��ф�����1���I�ha���v�y���Tm�������m�_W� �E���� �'�`�:#p�
�
�e�#b����k�2�)L�I/)�V�i����Y��8-T��HvO�W-�E���o��G�a�Q#�y���eU�2H��;S�sB�-�Cb�$�����W�ie.#
Vכ���;~���MS�ة��י���~,�\T�+�%e����g�������~��v�-g��:�.��jW�}��c�_�E	�)ϘF��V��$n��J��[nPrƢ
�5���u;6�&G��Q�1C�aVǝ�L�j��ȱ��킠�� ײb�թF��W�S���I��|������]~d�ƶ*�	��q�|�ıߨCyp�b�n�#��k�p
�F��C��q��ͩY��;,v\1֛���A��=ӷ���.�~�j�4?G<q���'��]˄x#��yF�m?�(:;�-4�
�?���eH����U�ɋ�ͼ�] I�������?#�gv��|�'b�s����FiD�(��e ί^�+�--y)'=>�z���wsF���u�$�ʛ�����b�a>tJ������'` (��A�����~��)ZJ�fd,����=�h�u�zM|�f�3T	:z��7��`&G�`#��/ !���P��'%����}��EG�x�2�b8��7����g5�/������rG�n%8H��F�s��(�=��cr ���Q��Wr3�K
L���o�ꭕ�+e�xd�pd�k���E9��k+eZ��S�_�₃J�Xx~�j͹�$F�x=*y˴������=H6�i��{SÇ����{Z�Y:7�<��=�=i[U��)��*�	qM�0Qm�*v�9��?& ��ɋ%2P�m�t;�Ͳ<�cD��8�����8D䛳hD���l:ji��':�e9 ������:-�X��8��<,25W��D���~�:�~NY��d�U�ƻ?��]��'�0�Kݩ��]0������	��L�
O�!�ޠ��UXVgg��b��+�~-�a���f�q�2�f6���&�|����A\a�B4ɇx _�I��>��՜�k w��5��Xs���������P��c������$=�L��nZ]�	�`��a醶b�mZ �`� �x�n%7C,>D���9,p@�u�29Ԕ�Z� ���]]��&ͅZ������y�b���!�A��f"�c@u^c�RMҁ�aZgO$�6���D�2qq�z����VW@/[������7_��� 6��+�,���ovIC�5��ɲ#O3'j�0�cs�xo��	l����!A#�Lb%J[�H/�pR�Ȉ��l1&�Ko ��"�}M�7�x�������
�l�D��<���l�׋l,��S�m=Z��M�c���uU����3#��@:v��4`9��^��:�$����j��}� �C��V�-���y ���5ln����Z�0p�h�d7��B)NI��1k�9�EiP#ۦ[�G@��%E����w��3��.m:�_5�Rt2'Q@͆�c���_%�1�{��
�0ϱ�����/��|%�dh5�E�	�(1Wy���M,��w{���54Cl���@Q����&��q���#z��"PWȡ�&���#��u��W�d����H>�b�`uZ���l�8!�r�����g��I�s��A�W ��ձ�p�
�1yb��:_�����+���!� ��M=�#��>D/>��$q&!=rw���Ң��֒T��Oi�d�Xw�?�a�8h���?J�CN4��ɂ]��
�B�LQ�G�j�kQ�q���{��*`x �,R���e��.������j4c��|�oV��smi�{i���h���l�d %Guǡ��e?u+n�A@����Q�Օ�V�uݪ��(�x��'�v�~�z!���߶�:�j��`�u��=�a�6��1��t����*g ��������V���N�D�z��nX脲4��.Y�kc� ���`�.+n�F��Hz]����n\���*�����i�앂��ZY�ioKP�a�M�S�)g55*�ײq�zT�a�a#!-DڜY�-�~t�Ap��f��t�e�����	*J��#ys#�e�G������Y/�.5N�{���� �������ʙ	��N$�
�U-+`?.�3 gj2�4���;�(�p+U�L)&�;C�d2��n;A���b�%�L���'��#����q*�N�� ��Hv��i�-u�wQ�ZC��!��װ}�Q��`S�J��]W�Y�#p�z�;x��?� ��mPܢVÿ�{i���"I��2I��K-ĵ�U�z�n�rM�Vz��#��䏁��!�4��0��.���a��k�%gB��V�Ϭ6�/y�E�����{.�"R�y.'/�r��p{����Y����U��*���r�q1�:m1� eb���2���;�~$�܊mn��hxǞM�Uo�{<��E�Z��Z���_�l�����K�PX/VZ�R�
:����޹íw�H��J��U7IS3�E�3�Kt�gZ�<�+�O��7����Auк�MT����mk���@Ag��d���]i 	���D�͑���'��Փ%�*K�(g0��
s0EJ$m����}��)����D3�*���9���� Ϻ�{ƀ��y�X�+�G���/	�G�PtW�i �˕e7G���1���30P	E�r���)�D�Ե�EGEH�c��s��2T�����H_�=Kq�Ռ9/B���y��b{?SR�NT��Jo{�I��<�R��GByq-�*�?O��Db�7F:J��Q���\�r�v������|۪&~eO������|9�.�t��N$�6���Ɂ�K`Mj�T��K�Cmj�.f�I|���y\O1�=��l	z�5�=�[P��*p��R3O��i�d<������a�܃�H``"�aP�G^��'	Z�������#��T����ht��*!Lo����T�d�``��|f`1��F�1�<�����[{��Z'2�<1c-O����Vs��.�c������TyfE��������S
�]�|E(%��(��� ���[LH�u��o���/*�є{
R�c�����jiĚ�������أ]f����w�I�;��}���I�
�H���� �~��p��O`qyI��X��%`�K��K����_c�T~����bt��L|j�j��.Ӫ`(�>�e)�e��ah��#�a�rH`� ��!���lX�C�c]��)�5�\(��@;HԮ��`I5���L������  sLPu��k?�*G@Y��s�n�.������Z���M�\�f��� �HS�D$���*��4�z�#����˚�z�p2�>[�^������^5�Lϱ'Q-	P?���:@cD�7��d��d\4���%Ool/M��5�B���3����%LA@�����vg[��6�
����oC/�B᮲��+Y2�M-Oj��Q^n�J���=MN�K-�|։)��|!6 ����{?$�+�����5Y��v��$�"7�|ٗ��Z�b}a�C���,�I"��!
�_�ۑ�"�z��zY�x��3 R��Ǧ������0�&{i\k��ف�3�F檣�ˇ��K�opf�`�m�~�ӷ������z=Y�1���m:gڡ�Gs�o�놦����}���8���hS/lf�g�XC[��^ �{����i(ԏ�{�/g��N�^m����r\�'OS	�56T%���~��bM��~d��}Q|E�u��D_1j����WV��)]*�{���:���QH�ՙ���]^��ꫛ��Prbˣ������5M��̈́��8����YE<W���x��,/G b2��}�)���H�T����	�W�)j�.n�̘����+F��j+�j�Y�H�jK[O�r��ڸ���d)29b�`Cly]��R�a�xWd��Z�����ns�t�%���p �t��AxO���m�k?].z� �WT�C��xh�'!�;b鸚 k1��B0`�=��Z���:�pA���+�!E)����V��8a ��QS?'݂�p�27��{Ǻ�3,�T��ӊ����)��g��� Y��/ ����TFL
��N�Ľ�A��I5�;=��4�`�y�$�D�Ə+� �1�uF\!�(�P�!a�P̩�����7
=�D����(�@�n\�9h��>�i�$�|�O�x`�{^}�4x�u��>3�(���+��\{(d�V(�3s��">|�B�+�&�|�O`�v�������L�_��U!5=��4�T��^�(��o��R�HQ�[%`��H�-�Xb4�]}"JKK�P�C�����v�v��=k�7�:�рdT�)�"
�գ)q�2� ����7�iJ_S6�#.�/]��${KB����au=�U��N���IOKtUN��-^RlSk<�ř���y��c��/w[�����OlAn�[9��"�h��a�"��F�3�0]u�bF1h�뢄؞�Oi�8-�D�r�a����z)K�����S�ʈ�nQ�.$�w�_ahެP��\��=��z1�@/�{D�S�J��MC�b�諂�x��`op8sbw��x�Ƹ�U�o���v��'�nc�$]���kC%�w�~��[��O�_�p���73�Ǐxu�1D�S~���$&�#���ˏ��C�țG��ih�i,���R����F�*-�v/ۻѴ�#?	@�H���C���[�t�ѕ=���hk�[����E+w��[����^A'AgD�rM-b`n,�8�	�~��w���A���+�?��ȼ�U_��4���u����p٫�Ĩ�/A]cpE�	N
$�$u5��n��xL!$��e+h����T��4+閧cHG*A|��bix�F�<ۅ�>M%�q������!��`K{����V�(S�CS��jUOoUD�q�x��x��d[�I��IEq���4�'�51�jD��ꐪ��&��l�����#ty��c����ߙ�>Ҹ�R���V�?�N��X�a���!�گ4s�rw�!��6�}ի����,���~���춮���Ԭ��1�v&�P_.3.�p6�-a�lh��d�A�):9*99�F-����C��ɟ�چ� �	U� ��;��py2�Mᅎ<Ч`���ص��0K��e=;���My�{�r�
	(�F8�h���Ʃ�ϥ�X�Ob�O���m>~vjz7��Q6����-��б���D�L�m��B�� ҂Q!�xS6f;��J�0���;W����IӦ�t/�go�<�8H��A�:ko�HVF�ˤ��f�{ ̲+I�w��A�pwu;yуg�"}l7��y�޴X����J�AG]2����B����È&�۞Y�%��Ʋd�o��������HHbM�fg8$�����)e������%�l����>w07 ���.6�g����h^ϾC��F�%rdo?\�K��֥Vm"jlPBܗ��H(��clr�Y�g��0��h���7���G3+E�s�x	���)vlo|P������ݑ6��2 ��$����</�c�t�)+�� W����g��]�iծͫ�@��+���cK�������2���/�^�����gs���J-y�%q���vQ����01��MB�#;�It���bLg$�V��#L���	}���$c_"_|�|���冄��Iw޲�.���iS'��o�8�$N�����$�c�u-ڛ�Gp�ʙ����/��IZ��o}���K	�"z	��z��5��)�ծ�Gv'%)O{h��Y�_��M�����0,�+Di�^���7m���'�M-X,�����'\b܈� �h�puJP\������j^��p��FN�_<C�i�^����"R0=����ғ��L��B�\���#{�,>�a�;_�fG�ݖ�u;(��IZ뤈Iް>�zQ�M���UDf_�%|wկ�c�]5V0[s-0�Vn^z~��J��>^�[�r��ÞQ�]��Q�Q� ��L��D�9���W�� 3ɱj#�k�V=>�T]��Vn��$X/O�&�1��W��W�W5�U] N�g�oU�-�[t!8�U���O��
`��Qw?���J�\z��-> w�GJ;3fT����Nn��Xiл]�؎��S�	���}Hٻ4x�>@W����>=6��3��&}Ttزb��ԑ#U KԨ�d���*Dn^��H��`ئ�G��R����S 8��~�i�JF<�"��c�ŮN"3��lVs*���C��ѡ0R@�W�iʥ�J�Z�"�����p)�u��M�DY:���c����8%C�cߕ���v�  s��ns ��%���
�4�q4�E=)�|JTd�������>��kn�f�F�f��� �~ �{s������Z��f���vGu� t�����$��{�3�������^֭�t�_#|�J���޸fmfs�g�d��m=$�	��Q�3�~C�`Gݨ6�uIH�����'��gKY�"Yc�G�_Yi6D���t�8X��8�D���w9�����`�nI��YP�f�lhoY�V6G�W��������ϱ@��b���B�r��s#���G[J3_[Fg]���Q��q�2Y+���7��7�$��y4����/��T�u����ك$M��5�w��E�GW��6�2�5E�T�ҳ�t��R   �M��� ����|^��g�    YZ