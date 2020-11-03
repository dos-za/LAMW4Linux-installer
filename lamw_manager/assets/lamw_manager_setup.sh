#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1113172043"
MD5="d07983740833c5eb6294a65424da12f9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20696"
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
	echo Date of packaging: Tue Nov  3 02:33:25 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��1Dd]����P�t�A�e����Z�,�[�6lIV�A߼sd�����q�p�?����x���m��h�.2����7!֭�>(Ι���B��qƽ��{�M'�.>h��.x��2��J�Yؗ�c
��IE�L�����V�V7*Ha�Tb+9G�v������g�X$a#E��?q-?ɐ^r`� ٨�Gt�҉r\.R����!�F��"t١|b�U�M�h��۔��*���Wmys��MnN:�VkW3�+���8���18I'� 0gNԖ|���[�%���� ��Ѷk�K+��S��Y��I������=!!m�i���µ5�:�t$�	7n�<�a���B�$�¦jDQ3�Tf o���i�H#��\9����{��ٹXvO��Ԟ��#��Z��Zem�F�h���,bø�k,��s���TX���W�{�z��~��	]F<0��5v�jt���S:�V͹MU!_���|9ѱ�T�����]����]p�4�-��7rV
�T�:f����\������P�W7�[����a�����Z�:MnC]�n���U;�rٖ����7�?c���26l|˖C�X��dT�^򧋣T5�v�Te�lj+�z'�C�� mxȯ/�^)z6I�o�/s7����a�u��8�EL�<�s�&�f�S�g�uChjw����ɂ��;jN��}�@�9��Yt�F�O-jW�;���	�@5��}�1��7���+~]�!�,e-�i�����L�N`���ʈ>:k��AP��0y����Q�x���"dVً�m�{�Q�Zt��Z��7��~X��թS�vi=醞���:l9�8�-�CWVxE�Y���N���M�*�Z��t�k�ĝbq�`��s7�^�Q���]��.Zq�g�4؛��Yd��Z����]������b�-����Q��b�
��5��</��~g?21���Z������8T�8���O��٦٣Eٛf�lz�
��}����'��c�<*��ީ`��"��22�<y��7�o6퇜B#�4<�×r���*�ū���Esw)��TXre�͐�F%[�k8�PA3�)�ʙ;٬��� ��L��ۤ4&�b�UO�K��c"�>B��
<n?�k��j�<iH��4F����9BV���n��"�����L.W��K�������:�ᴏ/�R�Ҷ���Q�uR���ر��H@1��g�����[��`N�:xW��!rO��R8Q�&���J����*�
:{�Q������~lh�!��$�+���h�5Ε�-�5_#�E1����=�6���!H栠$z�?�o�6<�[q�0VtZu&*g?��,�nT�k<].�Q[�\M�@�!&u�9�M�3G]OS�cuAo�y�S{W���m��/�D�m�UU�:6�'1*��J�P~㸊�-{��F�� 3_*O�ʛ�;*eI��OZJ�����b�c�QXs��������b��'�25�KT=�s̢�`L;��3zӘyc��J�3\�Ǎ�s�&�!#�4�˞����S��k�6 ~��ѫ�����q7+p_u��.bX����5�'�*���>���PK��Eq�Njؿ����6�a4S�=d��嗝�Di#߰Ya�vt��
c�?	��g](�}���jQ��񞰬�^�W� �N�WiN&:X��nX�j(���IQ�D�l
ٟ�;�f/��dF�5�k���AG�8y�O+�7Ĥ��N�&쟶0U�?0�g�e����*�l):U4P��t�1�t�]�e^u_3w�\�u���u��!�	�y�וҺ!�wR�`Z�C0�"ld@X���OW���\���V�⹴�jn�t^��_Ȭ��؁�cZF��������1�'S&vU	�N<&�e"q���x���)�N<:��-cx1ׂ���z���(�� BO@'L_��_�_�NU$�MԈ5J/I�p3���_r�Q�d��hv�B��nP�7�d�ϕH�	�w��C�kk��_`XO���dJ�����0�K)m4����N` ��E6�`�¹�9T~Q�U y����x�Ϸ>^�\�_�H�:�M���>�2[Rl�š'�>�=Ga�(=cZgT���D�S�:���%:��᱇��[�Q�-�g���YFV'[�V�_�6�Q��hl+��7z�b����s������/0,26�RO��#����-1�Y�5l=����ۼ�b���/:��7f�</s�~�m�Ґc<������`qP�P��h�%�,A�6o\�X*��=��>�O�阙�H<��uJ�)L��<���G�x8§֒G	�y��"E)X��3�'��x� c|\ϖ���yE*�q�疫��Z@A�K���Q��8�f�Wvk �����p$q�1��J���s0W>��n��Q�̵�2"Q^����u��ж{�ؓ|
�<| �2�}"K�! �G"L����`D\���RUo�M���ʗ�N@�������Zِ��2㦦����E���z)��MF6AK�(�<D�Xx��9���)O��Hv��/��v��5��ڳ7�Hg6��oh@U���b69ٽ���RN��nt�Ł̟�#�Z�>�]�=�dg!Tb�z5E��ܣ����H�\ք ��Y�|5�r�(�5����8#Ӈ���~�!6�%���j�	%3���{s3=U�$~�P�ʍ�I =��!�XW�C%�w��˹�g�r��k����h�h������3'4B��k�p�=����A�Jk�y�bqdk�	�z��0|]%�A���7d{F�O��3�;����k����y�h�^z
�����zfآ/<_�h�w�;���4G�;<B�FG�I�����'��G;�l�Ǐ2�`SϘ��o���zk�������&�� �ׄ����M��7���rֵ��RC�������!���(������{͹�MxzȰ^�����)�t=���\�+��u�C�i$������`3]�݆Gh��ɭC���kJE�?A����'��#r,��R���u��¨�EZ�ρ@��/��er�X����GD�2r;�	�G`D�Դ�hۈm������z�S����W��~u����mG�w��9<�jMH��	 /dT�� P������+�^(�kJ��
�_t��Q8p��	�ʠ�� H�~�n�sA�&c`�zte��5:�m��ͩ�g�6E���v��2��M��%5�7�:2�=g����B�\x��v��_���(;{�ݲb�x�i�81�w@P���+��R�+ܺ�=mI��#���V>N<��1���3�z������v	+ſ1KH*�����q*��(~'�e梉������c9�0�. ��0��Q�7�H�BL�wPnR��"0�^m�\�8�Jsf+�ڷw0�����+��/�s���9��+�� Tg���ߎ�56	sLH��I�?σ�t%}�Y��_�����1<�xܖ��t��0�!�#�jĸ��mw��:�D*{�l�#�Y兢����O.���?��i}�y'�A ������l!����&��u���l����jk�~x!����� ~���jK`�;`�f�W���J9=-[�GM�M�k1���--<vc5e���C���a l�?0�)�?����S�犡�К�f�U��Q���"浑�\Պ�x ��~��J���m��a��M�dE�muad��F���.�f������pb�T�هU��L��Y>�T\�Έ��1g��)�+�w���������:V�8�k��g{c�zGX
( N�zb�!8,-���%���$������ocg	�}��qg.ж��>-<'ާ7kœ&P�ߝ�-��%Q^m(��Q��8�!�k�O�,����hۃ�����ϋ��=�6
�	��+�%ԙ3pK���\�[��Xg�Wh�)kr�A�݊��ӷ˫/�ɣ�Q�i�N:Hhq�vk]0�o��k]k����Z\��n�B:Y����L����.��·̲Z&ҽrf�!|Vs�Y6�.������c+�1-�OT9s��4��k�%k�-�0B��xF%l��c���Ue��z1{��%���O�e�h�zQ���,,'����7gC�6g���
��i%��۱Z���-���z�fof}��]j]1
��mv��̺���"iM��߄�;�I�ӈj�:�;�cװn�C�3����Ыp4N��ŀ��\ZL�߱JOaÈ�r}��� �|̵Ro=p��wv��O��M��$�w�Ё{��l��n���(���]-p���F����L�A�Ƙ�:�hg��H�	�����ԯ�L:J�xޙ���;�y�����x�u���/�x�{�]�s�t��!(T�#�U�Ğ��3�/�������-��
)�32�S���C�5u��բߤ6�xy��� E���.�Nv8��7�)0�KĬ�\a��ԗֵq��̑Bmx�a+2����-��X����ev��)����Ǖڔ�T�����Ŧ=�"�ȐH�$2�sA"����6gtq�2��R��	ֱG�k$�����5�Q΄��������a��v�B�� �q.{K�뜵��t���[H�;rUr�@� ���n��/�cP�!�ɗ��R�^�{��p��L;����������hV�!c���]��/ �w��Ê�>9���H(oҪ���(J�ȸk��.�/�;���!�&j�~�ʌw�cX����Y��,�o<��%����N��<99lCD�>B9_�������jGՆ��V
�j�l&՛��� �U�L<u�C���qY�T�~>&�^ (����k:�;Fg@G��	f~����'Z�gw>[J�`��i���DST�5��`Cc��SY^�R^T*�D����k~�ScH��Sի�����.�k�d�SK�K��lv�
4�~�����>���@&�w�5�/��暲���.���`1���4�Xwȣ�؅8' �nbNx�Hgc��Ю�`�=Ǵ��^x$�Fő�8��w2��,X����~�j/�T�&�U0����b��F�J��	�92�\f�v�Ga}��K\����m�Y���+K!;}d9oM�t݂L���)�qB��,:A�`�k8���=CjqM*p�\=�!�Q�Pꐎ׻ȥ��F �=���绩@���m-գ�X��]��o`���`%�Y�<]���y]p��"��ԥ�0"3�R�p���w�Zi5�I�ﾂ��%ʠ��_˧�y�,��Zl)�̫��әp�j��s8�3�uK?��mǿ�fz��@\��C{��*�2Q�ò̥3Ө#"H�SYv�MHNnxƩL횳��O��n�+��~婨�[�zZ$O��Y��nY�\:�S�/�«iR�O�V%��H1M]���f ���4J��7�`7��@�t��i� ���/o��(�/罬�G�:��/�T�!$��"f�O�M�U��S��j����)�@��D<
�S�pq����]��\�bJu�����o;�RM"&��nwc5aV���o�bi�M!��~��uA[!�4��{~�?�@��*�<�l�	$#'|��%��q�+��^��꽀�I2�C�9��/�=Q��_2�B"2�i������9~aǒ�K�Pݟ�k,>���[X/�����D��M�x^O����}_�,����	��54���� b]F�:!�.�<Wf�/2������e=�!^�iC�i.Y�O�2�f� PU�Vg�+y�>���k��˩=�Oc$]���$ϫ_����;qt���M�$B`(��.%z7ٲ8l��{ �q�f�+���aKy���WO�u����1�m��qFz��F�ۜ�+�.ˑH'oZ�?e���=�Gt�u��(���p��[j���F�<��2H3��P�sl�����-�!ޥ�O��~Q���}��̌L�m*,�y�G�����edN�f)�k{�y�(����4�>\1Ls0O¼�������X�P�ňXP��IT����x<w�1u��0�֯;� *��|ks�4Q�>�6���A��'�o�`���d�چ�����d�-p{7'<�?B$�[U�Zp3|�u3��KL26n����,Zc|�{�3t����jhP�3G^'|j�3G�6�|K2_~�^CH
�NN��YPĲ���4�q��=Ҕ�O�PUT쇌�����hj ��\VI���E )�lu����]Wzf6��+3	1(�Y�Ѻc�4{�(7�����ڮ��?��g/{�',Ҳ*���D���`�駶4w�H�>�q�v����0u�+�wa���0ǫ�2.b��> ��j+t����Ԛ=w�}"MӬ���T��� �KM��rSUA8��f~&��a����ʙ8��/����[^���`��|c�{]s��6��c>\�}zi�v&0"���A!���C{��_�ś�$3*?|v˥��?�$�b9,ia��6N�]��3U��o]Vv$� ��=q��#=�te�/�7�| �'����!$(U`���a'���Z�`D"Y������L��J�A?����8�R�E�hC��}��	�`��� J�#MJ^�X��e�[9�`�D)��MȌ&0�8��kv�T�80��n>�$h�q���V��s�!J��%��OV����p<�m]�9�QL�d�e.�ɦh#�����%�g�,a|VGlQN��m_G���H�O�r^K�e�x�w8��||i��1���,{���ކ?N6�/���K�|��?m���BQG&�}��ؗ��Y�T 3o��%��7i������)pKK����}" �zU#68~І,(L���s͔K��}�rÖ�� R�
c�:bX��\Ul���γ�K5ldh0��|M�ez��8�$�Yn^Q���5Dg],�?��F��� q!��;m��xq���K���P�r���v��,���Q�~��Ķ]�E������ -���4>�x@I��z@k���~��R�-"�+	��%�㥞P�u�#Q��2%��R�ԫW[&g�{�����Ud�d��C
4�����^<�m@�̢�9��]���7�������t�M}z�~r�X�5��(�js�L#~��;����Ol�Q�0t?��UO3c��9.���(N����{�h���a�h����4�3�؇�'���0U
��]�EL&��������~[p�h�W��A۠u/*VK����q��2SEk�ܷ��G�?x�SS�[vnBH*0h�y����kv���^��yĐ��D�
u����3F5[�!3�˨$iQ'����3��7�_�R�N���Hij�QY4�}�4��4Z�r��.��V�y3���ڴ'ml���v��F�c���I�'Y���2p<}�qi#���Pk|�CI�Z8�4ݟho\-m�Ez��Ao�v_i*�@Ё��>��Ϲ�Cm 6��04|�4�J�H�T���s
S��0հd����D�������.�]	j\y�J��VN��I��b6���T6�p3/ ON�(��w9��0ZNTt�?P��B���R��+p���!7j��N#KH���Ғ���d�.��G��>*��}���ڹ��?�����^r�����MM斻�©�s&ҿ1ܛ��X�R���^��@��� WՍ�AQGX�T���˕G���(���I�Plgf�ٜ�5�;�}V�[�X�����w��p}��J#69DyErBE>"���dF����q-�gLq�<p���9����홡~ ̓1�i�}����!CcI)=��AM9�z^��k	'��ݱ��a�*y�k�I���=���� �#�G��'��{ZEc��m�%�/ːⱬT~���˩M�7TC��?����<��.����SY���ĵUI.���'g7U��H|��*�W����U����ֶv6��-���l��R�VM�3vCb�D���b<d�,��!��E�}|_X��Kz����S%r���N.����U�y� ̠i�I�q�wE�4�����)�Vjc
4ٶ� �ȿ�≑J /B�x+�H��3bKq,gO����ca��V���AX˨�Ł}�g7e+.�3�	��G��������#C8��7�n�{蓽N(�em����؏JM!�wQ{+m�������\�C�E��U� ��#�D���s0�Ƥ~w���)�1�܀���q��6�	���4�9��

tG,O-��:�u&�`D����hf=xm7��M�V�=v@M�*w�g#J������Tm�X���e��N�lBb=Z���S:�4����1�B�"F��s���wֶ�H#�,�ؼ�t[����B@�H�4���._f��׭�#Ѡ��4��e͗;���٥�km��N~�Y���G������l�6��r�D��rw��>c¸yj�j��pr�[���iu�t��������r0�P���o��v_y�s3�ـa��B�i��:�
����i8�Ldǈ�Ni����,kq���VmF��W'�k>�zE,�z��H���W$"� ph�KY��p�j�x��Ύ0i�4�'����Oh�\�a6��rsg����I����sbQ�N���o�B���uG�.�OER6����:�����/�mz��א���ɭ�z?�v���'d·���\�?kv�J�m�~�7���^ǅ��m?�v�Hc�7П�"�2��2b��B�D���g㉰M);��>)�_��P��n�������%���m�
��o��W���$�=�cт�lMD,��rpG	8U������	MUw��)+�]�@�Op��K�=o�.���vVЂ���{_��)�%l`^��8ғ��~=�_n?6�{��m�2�g�}H"T�,�+J��!5�8�����E!Hd��
�TL���*��]_ ��?���oc��lfB��;/����NN�ZB�mv�I����5�`	�!���|CK�0<���������H��!~V���Z;$"����\�u��%�5�a��ٷp��I�$�|*�\�����W�s]��8+�xR~]���������@���Xg��;�ti���-�h�O{�g�ي̋q�I�KV�VMH����l#�u�g��p4���	c�t���I��F��=�H �!vV#e`�V�f<W��^A�:�\��_ڝ�e���67�����J2[j�.�#�[<7m�m�䁈g�(�G�m*oM�X6��-d�=;�]z��f4�dW����Y���v��؂X�y*�7ڜz04�E��P���������X�*V	�,�)#��xܤ{�i!��e�g�j�+d��m�����	�8��\X9����g�.O=}���}��w� ��~�5e�60㕳��CE�ޅJ���r8���L��w��a�	�7$��g3�����
��0��֩��z�c��bG(��`��c�����$/Z�����K�;P�j\�;*���|	�����x�&`V��'iS>�brlz�R�K�im���� AEZB�r�B���\>��4���� j���[��E�^�G
n0�=Z����CD�j���_�}ִQ-6��	M-�G���Bc���������|��g��p���������\a>�"������c�;���aJG���|�	?|kO'�A;Ui���6��W氂�O���К:��>q���zGB�'R�����q����"�qgf�r�,%.�bK��(\�+��<c�������M�'q��N�YC�ң\@��0d�y�����Q��m�u=���,�e���/ϫr?c����?1YVq膭�$5�Q�C�1?�)�@��Է9�x ���X�6���y�^Ho���B�]��h��p�7*������_�㢨E��';dSЃy�]�n~��=ӓ�P���^T@���C����L�P���N|�Y߰�e}�z�Y9�]�[2ECy���^��0L�~%��~=:������|j�o�j�{P_W�}v2���#�����E_�6��z����ޙ�_O�79K����`�d�vطb���=V��"���� �"�+��Yl�#�Z!~�Qm;�<��]��K���>�0����
��=�A߻lsnݏ����6yu��r[4u��.6Y��4����~��5�PQAH�ew{��"�%\`;u:iZ�k�9�ʆ3�Z�A������w��}{kC@K�;n>;&�ݷNI,H��SEA,2(��Q��W������1�?�[Q��,Z�c/.�l���;!��<���]�嘏#�a����Z�v���~*�fP�Z�8�J��Dd�	J�GNޜ��4�����پ��_��QtY�z'��ԑf.���Nb��
^������
�����B8��A����Z�f�H62Q�+���t�M�'��4Ԥ�s�誧.��<�l��4w'�<yn���/���"�/_O�Yb�ݎ��f�A��#;_���0�i)�bmWW.�T��=�hj���W!_�[ttmx��I�cwP
ҍ���:���Ud���)7��bA����(��m�D��x�c��1Q���"=��&��Ħ���������L� m��4�ٹ���N�t��]5��F�����f6�U<�D��H�yFʕ��ߚU�^s��w���fj]�4��F�Gus2��~�aH+�/V.6[���Rl$E��p�x�KK��A|��B��i��@ZI��	�>sQ/���q��i9�L+á�2P���c�F�H����c��[ȡ�s�#)7*�x��з��ٖ�C���)��A�Ԗұ��8j�}��/��P���H�PM�'�M�f�L�u�ypw��	�?	b���Ά0�]���U�T�=^5�^�Є�$��"�9?�j���	�O�4���b�ir=�>�x]Can�'GA�!-�G䑚L��\q��Zv��P�������";��f��Ib|�z�F��=a�5#]ѶUp��_8q(�4l@䨎��5���;��f�2y�5C��� �����̃$��fOQ�����́��X���=P�3��P��t�ӿL����J�l���_מE�x{���>�bNO}gt�-0B1��٢e"Щ	��Ft�\3r�
C� �EBy���h� �Z`QX��#�>qs��l�x�Њ�Ky��6i���iF~c�W�K�bv�sNȏ^�m��������UK�ݰ����7��������f)gةBAj�¹�Q@:U�6	(����pH���Iy�I���V�#�L���?!xSdd����Ԏ�����\�	�����^��F�ӗ!������H(�?�:F({E�r��]�J=mi�����ݨ�AN=E(�>oV��D۲��&��2�ժ�+P���̼pJ�c���"{�A�]��WZ��c�&�#�k� �I�S� �a����Q��p�e�EYA;f�Z����j?�l��y�U��M���y|�y����x]X	 �3�f�n�o>@|�2����M��Bw����[�T*h#t�a�� �v��E�b��Û��hz��&k*)�oV_�tC�gNk�5���B5g��۵�6W�c]n�!þ���Y����Ԉ���"��>��_r��"�� ~�!"�zky!���s�yvޜ3����h��EjS@��M-7�eY�J�֯�A�U����5���@��ַ�E�He8�[�Y�(�����������OeK�ueǾd�jF?m�7�P:�-�'=$�u��]0���VDTX�6��v�x���`ش�6ԡ��-a�!d�	�^�F��6�$��V����_G--�(�UGO����XfT��7-�TyZN��1���'I��b��=;�� �z]Yҥ�%i-ڊڲ����]N�g�� ��/^!����K�Q���4�O\[��Ϫg�b��
'L�oO))��{%o�Љ��,d��� k��|a�KU�+����\P\���N@C��������kf��6󠠩�;�)ǎ�L��웬��v�A"��:�.�/�/v]Q+���V|�[wL��r���'n�������}_�]��U����ڇ��cÝ�=��Z��]��Z�&�d�o�!����熫oؔ��)�SK�X�bV��˓�u�����&�+@ǚ1��>�^���3�\�UI�Auh��V��~Ή��i��K�0#�M��j0#��� ��*�u��H�����)\x��߶��)bϓ�K@�
�>�lHH���^�I  `�������BO�� ����ߏᯞ/��ͷÔF���92GJYE;9�߻?EڑK�T�! �������L�.��y7�������f�J�S��ơ������&CE�-�!�����pR8
)�6,���ե!i�/:tJQ�Q�ڡ�0��_(����
�n/�� �a����wzl����峧��[g(�#L�O7OT�Ұ�1��m�&������"5�bx
�aӈ+:}�0[0�Λ<�/_.�����x�.���dɣ�m١��vϤn )����PuA_v�!RX ���Zc�����6qJ/N���r��P�n�3=�A<�2
J`�h�Q�Ă|>�̾�P"(A�G��'��gq�KO�,������4�`q�1�?B^�ȗJ@�hT< ����P�@x�a��OJ��4w+e��] [N�u��6�9A�_��QJ�u���,�t����d��[7%!)+{�(�6�<�(�{����$��*o!1�j]SK�oEY)��͖���O����U��q�r �Xt���[�[#���x4���ɡ������'* �D92긎��o�M���bk���Ё�9ьl^74�)��<bɿ�՗�0�~��*ڶV=<9{Y��O�І�T�:�ňj*W�cIv�&^�7�@�:������i��Fn����I�?�)#Lk�$c7��-ӟ�a�P�J����o�e�k�)��tK`r��e�dG�o��b�,u���eJ'㜶�����a�L�O2��_C!�{��;�]��;��5c�PF�IrW,f�N�Eܤzmph��]"�B���Z��F#�p�B��Z`: 
���հ#��`�؜�����t=�N�Cr��}���%㕭	0��#��o�g�8����!��M���<��f&��:�G���%m� 8\[�)Q~���(%,���j���J���޺|�|�G�S:mt׀��E�W�N�7b:6N��j�f��Ķ�& EM���(ߠD�;�A�����V�Z���H���n�d�U|^�n�ƒ� ) �~M	�R+���Q)5��\~��\<l��'�{`DQ����+w��>,��@�!Ȋ��勀�9��滧y[X�o&�G�0{�Ay�'5��/7W,���$ŷA������{P�i��Mo�ߢ��:ZWt�B3r�'u���C��ˢDm!6���Ӭ�Si=���{0�L�}Ǧ�����CJ�W�8������sϢgE��P�aj�.K���Im�BruxlX��ae+�����ٴ9��#�r^���~Ye_ЎF���lw���������sLp���-kC�<������
�d�L�f+�͠����=�)@78���^�I��=k��o7�52���R��t���OY�m��n>� xӅ��W����|G%����=E�F|�
Ѻ�B<�Gs���xGLl�y�mSױȳ������!G�o �R��������fv��J Hi*^�T��eZL>�2��@k
D<�I�B�e�҄:�I���t�y/ڼ�P��M���-�Uk��٤�%�6�l_��ϚȁY���B���
��[�f��ﺞ����N_��9)�Au_�ɦn�3�og�����I��i,q��k��1���p7(w���t���2��$P)�퇼��s��-b|���%(�M�����]�4�v�y�Pz�/�H�ގ� LTI�d�~4я��.�բ�_�f3�E���	��?ߙnx#��0S�8�n�X/	Y݀�B�쥭m��h���'K��EK��L&K�j2��=0JJ����'�Ӎ�����H��:��I��z͑�%0`����a��c�(=aU�������p�w��=����qF�z؊1V�T�c}�M* �w�IT�-�g}R�(���5�x4�އ�B4����[xv+T&a��ߛ�/�,�h5mP�u��M��R����U\2;`s&'fJ��8u �v���y�	�``=�|�eh��t�'&s�4�N�,�����lq��P�%��~i	�F��fؙ�'[{Qt{�&y�k-�F���ncM>��i�q���9�D�r����q�gw��̧8�������G�n��C�{p|+���������ވ2hÙ8� I?.��Ōʖ�tg�t�`VF�`oM�o�b�n�?L�B��{��� q�z�|xѸϳ��2��ç�$���P/�D�y=엏���n������GK��9s����z2�t�{��v��/����~�AU1�g�(-YY
�&ً�9ӽ�i)�fQM�FR��c�����]���·��ƺ �O4�����}��VN���c���d��k&��� ����Ym7kR�N\7�_z����F��Y�M�A�K�ƾ7�i���&�;W[� �oՠZ�)n�/��G���-�`6�]$L��-�%h�t�Ob����������.���?9̥> #�F�TE?��P�&pW�C�'Z,t�m��U"��;r��
&�E>��~!��B4.��9�~=��o�'?j0	����D� �W�_�����4Fߟ�}Գ"�N�4��ҳ���XS�'��;�4đ�Zk�(zV�R�J�V��iߺ8-�N�E
r����zcҳeu�����9'�Ӆc+���i����i��*�VD�t�A�v�tvn�&F����F�H�c瓘-H���%�K�u2��־�k�(~�k/֚�G��KblY�\K�Gd���K�9X�dK�(l�Zk��շl�R~��L���-�s{I����塚���FS��aG.�� ϚzR��µkN�׋^XkeΠp4Z�US	��+�!d�����nq]�H>���[P����f@���:ѹ�lP��i�n���@*�@�5��D5��l���6>��aɔ�vZ�@���^��S8���h�/���rx�����\uEKeX~�G��,L �Iq�s���8����c�{�3�GFPX:�� ����������+���X�=`�q����3��E�W�A �x8����{�㩛(���?V��o���!��j�졫��<#��j(I[U�w&�+J�$$���$�YV��G�!���e-��X.��q��c3�C�v��..Aۛʕ�9u��q�G�vd�4t�0fSZ��V�ZI�ڐ����C��ň��A٬r�@t������QdI蔫�J��E��!ۈ�eq��xe��4�2����;�#����W�&���Ѯ��k�1"��(/?ǣ8�zW:�}��\�Qb������e9f��eu�(-����6ù�?���=n~�%^�T�������ތ_q7�f	\��%!*B�x�c��4(H�*fQ��ح�e�zt!9c�f2[��S�#[�k��r�&�vfbk(��S�j-��7<B�L�!�M(�0���7{���o�/�]����
����|���?�8�z*0�	��YBX�rt6������q��坽��/S�p�o.�@B��vt���}�PwIu��Lٸ1b�R`#s<-p�<ɴ�5ֳ��'�I�Nc��Y�M�7GB�g��)�J:Q�6M3���GT�ju��?k+"��)t�׋���1v?�e(>�>l����"�~�c���ݺ�|\W�c�$�x��렿��S��@V�-s�a��!.}o���� ���PdH9�� e�x[fk��Mč�+F	����RH����/�J���K����%��d�[!��Q�\.?�M��o�	]u�_�n��Xcq!��t�/��o��;J���Q�4���l��{�>��{�2m*�e���}Fʓ�/��
��P��!p~�z����{�-��
�@]�h)s'����K����g�.:,|0��wmi����eO4��juo���VBߧX��Uy�ه����v�T�W��<�iJ��'��BYx�����AyUuN�7�f�1�+;{�S;�ʍ3���u/�[��)��� ��4bL>�8-�)-��8Q�TkP������"N#�Ƹ�&����ٰ���СS�v���x5�x'�楐����y�i
��Z9��v����R���r�Xȶ�F��8=�9� �0qK��;/?9J��m�_�^�" �k�7f2��?��B�3��/i�Zz-��E'ڊ�T��*��){�R��Z��:�6��`�h�֒-�@ ;-�l|'x��(��$X��@������Tof��0V����{Dy�����lo65�%�n����tʋ}����π ��Ӧ�+W��d!d�oXC�y���&K��qk���� ��`oM��^eo�f8[j@�jk�N�R�;���N�b{~}���ﲊ=�~:�$��&�*V8������[�k��#>��O�U>-�����ȩ�]�;��$���h<�4y��g��b����6���͈�Dky����1o����˨Sk�靦�Ӆ���<���G�o:{�֋`w.�o�b0���K�Ϭ�6�$���w=Ԇ�c;2��@<�4}��z� >��«��;��C켐'��v-S|Nq�Z.'�*���4�?L�����9уv�����b��NB��H�Cqz[6�?^�	Q%ɑ��H��'��sA�St���`!X){�!������Ie_�@e����;Yw��|'��R�~����I�y�Y];F:T��0��DJo�����`�XBy&���-t��[�/?��Tg��� ����	��3M/;Ҡ�����I�a���0�5���b/;u-�iǁ���x�)�2J�f$�a-�G~=GO���%������Rw�ӕ���"a��<�:�?G��,<�۔B�3��/�t��|�n�2�1f�ԍ'歷���J�����0#��d{�.�{Π���m(������S�Ԕٳ?�����"2	�?S��r��^�	�s׈|�&@��h���b�i
`��.pfZwW_�%8��s����������E�j^�KdM�	*�hrH/��6��<����2����z��N	��'m�����1�t��\���e��Gy�e2�hM'���>�T�H��@5,�$.y��;�:Afܦe!�&��Dl�����i�a$ce�AI/��ذ�;��l������ ih��`U��f����.59c����'n�Z���-bjʋ�d*}�)����N�N<���}<��Q�!��c�V��=3��.�|O#Ͽ����� �5GUL�h�2L5��c�:��IwU2��/N��?����:����`uv	��6� !/�R�H���������V�j�߯l�C��|4��a���,�97��j���ȶ�K��f���W�G�b�I�¾���CYE"��6zE��"����'T�ѝ��$���x)"�8Y�2�Ҍ�ⱊ_RK�+�e��"3�۵�nb�oʔD�">����;����t�{���K*H�T ������#�0��^�y���I)0�vf�Of�d.+ui!�>�4@��`���S���dv�:�=��IC�+!8)Xg�-U�&����",ű�Y��$T^͟�g�X1p��I�H��~ym�U(�	%�D"C}�@�1;����$��=��'����P2O?JXF���jQ��eO���m����*���r^�@,��E��R�8q2�b�^C�?k�}��|�%&!�)X�����~��dh�����z�
�՛sJ|c�4�"��X]1��T2o���%7�p�"�J/�8k|B牙�����- ��~:Q��?8���|v�w4�BD}�`%�ۣ����Y��ԁ�&9q�['����.��;�����z�!���^2k�GVW��_��g=G�>��m�q��΅�Й��qȥ����1�ѕD�Q�C��U��Y�D�f���k�i̠�&s_���H��	�@ax��H�CZ�`���;���B���6�*�;�(���z;�?��Ew�g]�L�V�n/O���B���d���p�M=��muq�l{�!C2��(���fQ �)�x�Ŀ`WzN�1�����oqJ]��&KPU	3
A*�R6G��RbI�a�)=��@O%�mQ3;�m�_!VRݟ�g뛪-��R���WQ-+���=$��A��(�WxQ�>R�'Ĺ��I"3��J��]����U�%�~�),.���g�>�x-�!߷v����iX|����|����w��J�D�2}k�E��=�rBO.��&S< �-�ሊ��u7�G96����W�뇶�Վ �����
�g�S�;4�}��N��#d�p)/��l���p���ʜ�B3\�������|p��}j��ȡ��*H����Y)����v�)m�0����΀;ms�P-T�C69���v�w�8w}��-`X/2�3t��$M��+Qۢc<K��e�5>���-���Mp�Dk؍�Y��[�ࣔ��.�	M���'������&��-dHr��T�H�R�c_��r���KA��Ic�]�2�lJ/d� �{�A��nU���r�M~���vֿ-wDH��X��C�a�}~��z�.uSBW��a��L/Sr4�,�9M�F2��+I���MɩC��`M�<�r���F/��}zK��|N���|�aA�~^��ͯ�De:ෟ�|b{�LG@Ɣѕ�M��+�7y��$�����N(��PA4���=�������;R�����P�Y�R��$�ħӁ*���c�A��]�(Y�i&�>0b��򦂲y,� ?��h�A�Q���,�:,��<A�ha#��!��3�S�&�:II���޲��8���������ߘi��쥖Կxe�bZV��#��`~�!A���)i$�2E�) �E�"M0i�F��ė7��:EI�s�Yג�wz�z�%Rs�S���h��`0w�>\n�/Y\�ִ#Z/7���3"5	�U�Rx����)�ha{�qɭ�I��ƪ���Ǟ��?=瀏�~ʉ���_��׃���:�e5��À�#x����[z���Զ`��u���P�˩E�_
fA;��Yˋ���I�'Lu5A�ٷ��� ���+�6�Sں˸�lP:���(9�Q�_<�[@o��4%�� ބd���f,��=^�/��r.�q~n���I���W����w�\~���7���1���1�r�K�~7G��`�Y��t����v���'���}���1uռCrp��e0�����Y|]*�Fb㊄�p��aȜ�W1�l�<N45��m���]�w%�uC���+�,�6��y��rρV{ aQ\Q����Ǌ�-���L�(�΃Ҳ\��2˨���W��� ��Ο��!.��en����6tq�����	�����j��E��4ξK��!�)!�1���@�s\B��T����ϬtL(N�3��g�����]�#l�T��	���LJc����������I! �����;n���)��k�)�<_5�]
E{d�W��94%2���x������a��p�������=�h���e�r���G�
15Ȏ$M&#;t��T���ˋ�x�Ղ3�7�QT[�1���Ȑ����z/Lˢم�ĺ�0�\�lo�`��G'�9��y���:�I����V��/�ˇ�h�T��ߋ�kf��X[���u���p*p#q��N	�L�4���G`���s��^'�yjO4���c�W5+r��=���Ãq-MY.��i�����T�Iyc���m����[\.nF����q6�Oً��y��;��0��j����~
c����k�Fk1�
��S�Φi�yy�O�(6M�
��9.����B�dm�ͣ����	6�!ȚC@afu���b�HD�6F�)��a�>��%^�ڢ�r'�~���g-�z�td��g(�H��m}�	�Փ�%7�A[e?���R��mۆ�5A���`�ҏ��$���(����� 8�����;� �1_���V�A�*��TV�UV{�j{�^���
�Zs���S'���:��`�����)HDtHQ�J���\�LA,'O�75�h��F��<
�R �!��"S�>�GG�����H�p� ���G��b&�a4#��˒�Ʊ����\�Ed.��mQ7a-�Rx ��|���ER��I8]��X6�1Mi����?c5H�aS�ଜ����s<�[`�=�l�:
+��F�����{o]��KnW�9�H�w��ǟ    	wi7
� �����iA��g�    YZ