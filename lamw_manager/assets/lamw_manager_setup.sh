#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="576815207"
MD5="61ed589e3c2881ed8cb66bfa7db7a9de"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23992"
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
	echo Date of packaging: Fri Dec 24 18:00:46 -03 2021
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
�7zXZ  �ִF !   �X����]v] �}��1Dd]����P�t�D�$�=��h��jN]��s�����e�G�ԕ:C\\z�mlM�W�p`EWJ�lߎ���/]]p����] N���d�х����Nc�]�&�����S������ \��;���hy������%���^w��r���P��<����__���~�)WQ�5!�*�:2U�W����r��4��W�#�2�`}�r]�(�V�,q�(M�+H�ǜ���?�<�z�M/qS�z�m��)J�t��׸w��֚�w��*$��O��¦�vC?���"���(c)|�1�����Jj�4Zљ��;=!�yf�D���pr�6*�*A��WB�?�Y)�}�<	姻����_(v�e��(�J�m�2\��M�q��_�;����}e�$h>fM]�1H��-`f�(J'PN]��3D��@�N��D��Uui�:c��gPJj����|k��g�Ҟ�����b0�N��6�B�e>�̚�<��^?�n�>����
ӏ�H����F�;0k��r�ѳ�Z��
X����l@�YQ�tG�C��8���+�_�%��-����$��l����	E�IBӯ�9:�1k�������ǨeOF��-Vێ���3�S9�kv7&��(�o���Ho"bb�t �>�.I^�w9:��?�3. 9���{Y<��1Rș�ff�F	�]�aRZ�:�T�U�Co����@B���L�'�o�l궞�z?�
�-f~�p���쇿�"q'J�1���֮�Q~��ʟ���.ҫ�r�+�_��
/o����6T�J��w��"'��"�5t>�RD 7�;��e�t=�mA�+�}�=V�z_
�o�<s�HS[�N�&4��zI��X�̱N?�U���2��Ҫa�z
l-�3E'|�� �ΓM}���Ļ���v�[���,�V|�m��yJ
�V���X������T��ah�"2S��5��X&���4�g�����<�����/̳���q.�N�	���Ƚz�+�ԝ*�`0�b_l}f?�S����`ݤ����t���kI�"���:�A~���Jv��N+��`�,"���a� �;��vY�f�9�t���+Y�kLoFNYU$��˙�j�DP���~�9��ztq1�և<�#mɜpsU;x���hPI��6@^n�t���G�!����ٱ<��eP*E��;Me�.1C`�,�;Pʻ��B��z~�+@_���aߡ^�:�q����j��On��?eL���>^�\I�g;�Cy��Ĭz���mݎW���>iE*���nS��AVpi�!�>Z鸝Ͽ"+5��Z���;�9]9���0��P��a�wf�:Sq�9@&Wn�j�.��MuC�>7�10�6l+wTT�%UY_��~m�a a%�P(\Ӄ1fY�҉Wn�!��A�����X��zR�5��Z�.J���.��L ��(Jv>�"�#
gK*�1nOj��e٬^�IJǏy�-ܲ�6��JckeI���l+;���M�p1�c�:+����T}�Pd���kB����=� ���F(�;�?��\���F�u��e1�4jA��1����1s^3�f��hh� c1/˽R��2���zl_j4V�U}�N�]��E@��4?��@���v�4�Ε<��O��7��a�Ԅ�ډ����Z��d����И !��b��ǽ��Y8�A�tUD�^����v�(-�R�������
7��w�zÛ3s���s~a�`�ž�y����
+��栗F�"�yW���9��B��9�N[�&U�4�f.X/�U���� �U������@����C���A����_���٨uV�Y����vx��E�O����V�J��y~h~�'��gmt�:�I��0������%���r`J�R�Rb�	L�۰��9d��m��]�|�{��2�x�Նu��諂0���M�鮯��TJ�l%��S��Ȃ�Zwʘ.��7\�mU��d��3�cs�fo�����[��0qKhq�(/ܪZ�)6�t�� �|x�1<�=�.�9W޹X���@��l�ن4H�tt	N��*%Bg�%o_;>���Ҷx{�����Cj�|�F�)���ryjt2H�ҡ��_<�0����i�����E�9�_D�&��Sʔ���\>Ϳ}�}{��E����Oc���z�r��@K�  �qi�+#Z���z����,� �#��4��I��<�/�%A�E9~�Z��/��T=>�{-�y j��Gr�d�r27Ⱦ�S:P�',��$[��1�+Q��K����� ���P�ΐ�Uw�>��.��:�Y�pߓW����.�-��c��܃6)����	 �,��ı��Y��M�A� ���Zk��fh�қ����	�@>&�ϔ_T��;'�	��U9�{�LLb���X��[�с�s�4�ocI�abG�1YtP�HscJI�8{���,ҬML�J����f�����E���wy�O? ��uH��R��m�� u�+a՘wJ��*z]�C����5�4�]�o���u,����-S�H��~V�<j]��9������$�
I����@���=��nt��0�:��̷�5����Rf�Y��7Ǻ���#FB��V��r��c����y��)�R����F��}>-'!�՞B���는��bgD��~��eĊ`����v.� �[��Y�u��!Aâ���O�~�P������5��e�8�񍈵(P��h�ֶt[�+/���]j��v	)Y����^7?4��R�lt!J~Y���ӰZ�d�.��>�x0�m�Px���i���Y�m�A�!~B�G1���7�&e��`�q-�:���	�p2���`#�(L�NCo�qy�����M�rLT��9�_1�أ�W-mӷ#�,8��o��Y`)��B (s�8�fb(|.%��p��0^�G��#9�;%�@���g��d�¾ ���S�|��h�F}�]��8�%/`ڍ�}3�Ιt��}�@=YR�uݸIi���K-xe�v)�. <���f��QT���Z�gvQS�u�;�X�nHMzT&>�������;�w�ߡ?x.L$����E����>�BAo���Z�5���-�����)�Жoc}��Bw���D��|�H��g��O8 Đ�il�h%��~N��M�:H��o�;�j��%��@�K)�DւW�<F���5Oՠ�*��ctx�;3�A�/����{�f���gP����|��4YC-���0p�q���E�{���V�ϐh���\����Ф��~Oa7�S�ZA.�N7�??ɫ:�W�v4��^�[yNx�t�^��mA_�a�G���")Dyx�^��[���[M3q�!���fB��!j��ItP�{4w��m� �v���=;�4��D�2��k�b�Q����	���҃��_p�d"Ϛ������:"<���`J|�@Q��,��m�Tf\̖�蟣 N�O�A�{0>^g&̢��F�$���xn;�.��f���|G���~gS&�g/��CO��.�ŷ��?ڱZ�S�D+&V��G��*a߂�[�w�g�M��fi�1Tܕ�l��WڬJ�)��ˣq�?x	(��jJ�@r�ɓ(�g�5�����YP�<�b��Q�w_q�\��c*͠�2寥&Pj+?������gS�+8i$ҢLE4uT��NS�Q3x�LaX	IXB�<P��)ե˾è��N�h���Rr`�66�0, ���*��Y��c�Y�I`|m�MS2&�#2�������44@^vi�����Moa�{��G����RA(��"����|�Y�(�k�ф=�Iħ	�� eo�1��N�K���Vl��Lѡ�5�4���=�
;®�7�M����e�=�!3+ǉ�_,۬D�PZ�'8��K�����^z���U^�B��_����O?�숨yXl	���\��l@�ˌtg�h�棏��=/V��A=�(�	�F�6���V����b����pܘV+�fdz�o[�ߙ�Јk�:,3�t�R�r��b��䃣u<�w���P�m�/gS3%I�E ͘f/kez�����,�C�˛<+����{�����m���@�^[�*Q���5�7�n��e����"���_�U�^�C��J4�)EmM���{�{P��� ��axo����L�}���A�-{1g;�0�ut�^�Ʀ����WO���3�^���.Y�^Ia���&�0g���ϭ~ ��+W{v�6�95�����<����F�=���+6	Xˈ��e?�4� �^�d��ܥUwi����T��m|C��ݠ'Hp�\���;{ԃ�Ē"L�b�g��)|�����沒�ie���)��ndzG���	�1"J�[�'�A�9�����������> 
�~�H�]�I�j9���rt������Blpy��'L��6�9[;:���r�"$�_T2�7���;����D�q��pU�)����1T����Re�͟@�P���Ĭ_5��o�Uè��@��m�%D�ߧ�UwLl�(s��
���CAA{�i�<{ �G�y��6 �yZV(V�/�}��D�$��=^�V���w8r��oFj�	XW���/V��*;1�.���DzzV�?�[)�~s����edJ	���|�+z�Z��tz7U����ha��� "�iܴ֛�&�Z_�����e� �H�d��q\��S�)�6:>����tǄ�+hΗ�,�hj�$�`zk�0�w�kC~�'��	���j���Lw�aך�d4J�]UE�xߢ(���_���c����T/� K.?\�Z6kյ��g�!,:�
�
�%�<�)yrbw�>�Z��ռu�O��t o�Q?Zr�֮2&�a�z6�ݰ�#��8ٿ݈n��%���UYn��cK��|�������c*6����A�7��-��ϕ�+t��/yw ۀ��|	�_�E?'ɛ�{��r6�����8Xj5�/s������r���cLl�B4XX[sn	� >��β�m{�쮲x�'�W��$���xs%$�S҆G~��6H�$���s�5|�)^����%��1�Ԇ�Z��(�d���2�>�m�\����y�!��s4܄p�2]�Bn���g��~_Z@�J5�u~�BÇ��,�f�,id���#?���V3U�9%Fq�,>ٍ�2��ђ��vY�O�]�Do%��!Jr WWEq�[帉��}���ޡ�"ڍ6�j2r�Ռ�����^��|7m/��4�T��/�Wߛ�7��'�WŘE�_������V*9���}��(��6	NH����lN��w��wZ��(թ�%��� ;k���X娌"��z�^���F͉s���R�ｆk �fV(��Hј��r����=g
�4r��ˈ�kc�t�b�>�h� �� we��	+<)`(�uC�"�lؾ�PQ�W��.q��a�Q���]�۾�z������F*�Z��Z>�;6����g��j��Dh�������O��a��T )�9*�ǌ�n_65�_ݚ�9
�~B�����,��\���k�!��r��*�
��&F�>8���^�[4W!����ܞ��<�}�"?�rC,M�5D�����ҵ�qW�A:<�.`����!�ݢ�A�Ӭ)
�t��*(��6NA�<f�n@��M��GƘCߠm0p�'0������)i�.ky�`J�۩��_^g�"�K�@�+5��q�����^?PV��t��+xI���wv���=9�j�J���ɚ#�^в^f��"~E)}?fn��jN�u��\��ò)�_����m&�V*v�¼���U��iݲ�nI'	r�>�¸;��]�D�8(�>7��*�y}�^6I>Ú[E-�vS�:�{Ag������%2N-aB�)�zðt�~�_ �k梣����jQ	ϕ3B�����D�^��x����,���~��32�"�L��G~
�e ��1���Y���M�Y\��g�Q��t��i5��N:a>�f�Y�I�:�����$�M���[�8�ǯ�w�
���?;F��
��:.�x��c�uO���BhJ�c�唛ATδ�������X!��
8\���aG��<��T�́b�A�<ԁ�P���z}�~X:f�bѾa����հ�go�b�׾�����!m��s�;_K0y5H�����^k����$S��,ʖ@����c�&×	oL@U�1�񙠻���yko����:�nJ���vKϋ'�a< >�@���6��t\�E�A�e�n�2�A�8syu��t��|��˟w_,�dߧ�z8,�=�`3��$��RfV���<κ|Z��vu%ztsp��/T_\˻��LR�R��l+��}�c�cJ�I���,9�d���-���nTi���jN���h��;C�ڔj�y&��玬�<r���1�1�_���x��B\.r��\�]�ux�We�6����Ҋ��{�7?�w٦�m�'���*m�K�����y�υ�N;JNǢ;&A�t���O�A�C��ʩFsFd��'m�'��^��E�=P�\U��2'�68dV�>"�#�^��K:�T�U͓�n�w����#���)>jѥ:/�����esQ�i�.w)���,���]��x��&,�,�����'5��}�Cϲ_֧/����z|�-�P�a�<{!�T�ׂR���im�z=��R�Ķ(�� "(��h���iZn��3b��lLmgF&�`� ��zGj?d�����z3Z��Ile�Ys�?��r{�(P3o���!ҿ�G�ƞ�i!��x1���.�Y�֟t�eE@�BU�!���l�c	$x����1j����O�?�_ݼ��EJ��	Z�R_qA�v���m�������S�w	�&��m^���yO~K�_^8��X\��Z_�z�i�$0m��]�~_v�_��>�)����=�E7��~ �e��tHH�]��v���)j�A���[p��m���_�B��Y�F��<�v;��D@���0���ȤQ=n7/�׭�_ᕂ�p��ܖ�m�6�Hِ�Ô����zw�D,���mW�a�9H�w̬D�>�A�ܢ���>��a�y��C	�<o�7�z�g�i'"��n�TY,��]����^� �n����YZoJ$l�v�T�|!n_^���N�f��P:��,���V�'�N���v���1Cv�0-O��d\\`����~���N���Hid1��\ה�����o9"�x�(�W��v ���뺴ۢ�@��ӵ�Z��T��q���&ɏі��6VĽ��|!H�E*�E2��L�P`�|;�;y�7*2�+2���і��d�C-�Ëg����=`����e3H���b�spq�\A4�%�\:�֪6�"J�-(F��mZ��ss  	YX\�K�:VŻH@�|?��h8Em*��j�a)�.�����s�c�λ�h4	r��[EJh"T������f&�*��d��I�Z�F��;��OK�IgYdߔ� brQ`���{r���Ϝ��(�mW���� Ca�i���"����|㫙���U��Dh�(~_D#F��"�F�I~,�/B���2��n��\[:�^�B��A�Z�	��
1h���Ah��J��?U�����G�>���g���iGMW��azp���}�&|/�C��[������[_��?��%��vB7SG�//�����@��SA��t�tt<_�h�������V�so�-a�s7q�M���6�ƛX������i�����En�����z�H۶���,�q-�|G�B�AIE�u@����ng�ځ���mI�cS�����V��U�_������r�&9t�Z�^cpi�a�C�����-�ҏ�Xm��_��u�xK�����6�z_Oa�@y}ڪC��Z������Eݙ�˦*�%K��=��	�79ؐ<G��Kkuɣ�J�%��u���I8�5r�,��Ga�!IT]�*z�{�4���񥌇0 ��4JL�g�|0�r���(�viM䑇�f�4��{Nݩ+�)�q��n!4�$�MG$0���6[��i��YB��O ��
��j{��Ժ��̵���xU�r�/��̕�w��Ν�?�%f�H� 
����`���ufN�*]s�vg]��\��R��-WL�N���M`%MBܝ���Ǘ�ֺJ�\��{�yz��@X�Jv�y���D��^uQ�f�ח�b����~��x�L��}>�E�����4��/}R�߷G>c,��z�'c��� Rta���
]E�L�F�[���B�߀�xJ10��:U�;կ}ci�D|��_r��s�� ��>�K�[2{�H����"
V�r�H�\5u4~����x����+�֋H;�R��]��u�i�ǈ�)uîv^���2��2�g���h9$�c������l�]�3A�1�I���P�F����;Z֝�������S���'W��1%�3/�g������6!���"�&�6�%�Ԇ�kz��OJǾu&���o�����;Ta!
xG�y7�H�8,�O?�0�L� ��UڈLpЂ."b���1 z1�=EU	6�7�W�UU��n�w�KЭ����t�eb�����`حw�1�chʛ�Sy
B���Έ���V��=���tNs����1��]6
^A��]��糽8�7�+|Z��i�5���'o'x<�[�ʍ��J5L]$<g�13�ǟ��{���zvA�2h��C���~�b���"���ʰ��`�@n?�����nB*���`z�T/�h����%e #6���?)��)�t�Gq���={A���_���v��[�7~}��S7LX�Ō!��h/��iZ�2��of�~3�1�"1XG1�t�u�%�����g|��P��A���FQN8n���31Q|�
jq߿�
��m�['�읤,^E�T�{lH��*���[�>1xܨFy�
m��A����Z��{�<k��&�`�*��Ljʸ��Lc�l<������k��"�3*��a�v�(�)��n�{[�%�; ^:��[���'�B�d�����r���eu����6��N�l�~���iGB���a�uY�2���$!>�d�'Z�	-��|$O�V�j���B�c�d��;�ϷV:��H��h���+���_���&�� yQ��\_�".�u�˯�~e��Q.K�'�p��	8��=/U��)zĘ	�*Ʌ��Q��o�D�&^���A�����)ۘ��R ��N�vjQ���jKkw0�l���Cr-m�H���dK{�1Q_]{�hK,h0��#��<]@��H.ɘĘ��b��������H�%�/�0/�rp%ɾ���^X�D�'�Jc�#����Y.��h�x�{�QݶB�1�G�����q
��Ʌ���|�OW��u2�.���pT+�hP\t���{j��+�:e�*s	1��f+���+H_\��������<����@�w�E�@]!�ƶC��UGx����xlԊ��;X��7����qR��g�B�$� ��u�r�v{@��4��j1^������2���������6����4fw��s�P(#����f���bG�*g�7�!���~1`e�����A�	G3pb��XaJjԣ�%��kph�pO������߅K9JZK҇[{���8Hx	��5��di\���YNDCL�e���=��H�r��:���Yإ'ܜô�U��;�o�5����ഥ
=D��NKb�G�	�r�;F�k5��^7 �<���&��?�� ܇6���"u��7�.$ݐ��&��'g!�jq��ڭ��v�Cz��q��у�?'Mz���B���D�f%��XJr���qs�����燪� �'����r��@ѭ$�����'�ec��	����#G�<Gr7�����:��b�6���G�����/����W4^�5�� "��I��|�s���u���NU�q�L������?��_g��`@҉�3t]�;���%�4����Υ��'�9i��^O����x�5��E��|sN�xj/L.�2���Ap���n�Un����9��'����g�+gc4Rj�f��B�,,��������C����NLf����dU�>�u��?~���_\J_ȔДth�ƵC��`�X{�B c����isj��؇ ݞ=#F;�)͍g;P��AƆ�9������D[�,0���K>�[�x�e�䒋Q��s�cOJj9��r�N���B�<8����>y �K����i�I ��+Dm;����w(�i b�'���q�̌�+���x��WYU74K����mT+�X���/8�Kw?G%�@d�b�&t#���
����[�'�|YC�<$ct�#�Z{��ʀ!!%늂G�6i,�z���+���Ü��Rޘ�DLl��bT�Q�V��������o!������w&$o�ԹH"ZH�1u�H'���$*���*�iW���
�)bPb��*�[u�������H�rV��nrzH��喹��+�k�?/l��8Q��oR�o�>!�Bi�L���$����>~��w��;
h(f{���߁��9ӄ�����O�Jg?�6{�G�R�g�k������`�h�Fc�W��9gQͯ���P�V$j ���e�������s2�W��&����ph�V!� uN{��H�=���Y��3��-�nR�7�Y���r�X-F��lN=�c[����&0�)RL�vӟjT�Tb]A�%�I���g�[|2L�Z^�LCt��l���	*���S����ݝ|4�A�w3:��3F8b][�Kh�6L�����R��|\�a~�^�5���<��v�PX��GE�AuEPr���2�Xw�J;�
禥x�����q5%f�����r����9�RO�m�#���0-�a/��b���s��)0^�6#52:����_���zQ#q��N��
X�T�8�T3�n�k�e�t2�W,5�HD�Jz񲍯�����bm:����ٜQb=o*.�3�Q	�������� �Ú_&��Ά�r �u]\<�P�\��kA��k�(�)�j#I<yy*ʮ�\��a�nPX�Z9+8UT".��~iw�֖�$�'��vh;f�)6ҁ�_>)1lR��h��Mv�~w�i�@�>��{b"~�����zl=¾�`uC(I�W�(�#����ٲs�o��>��.�ߖ��ţ��Y���|T0��WL�� �\O5��Tq�\U0C~Agј"��ݦȆ�O]�zsW�����%���ohfR�ȅ�4�5������'k
n�_,۲l'򷴝�D\\�ŏ�'�NӔ9�v>>�ϣ���#T�u���<'s F�/� � "�C@9Hp߮ ��pP���'3 ���)�@����~����H�{v��}��Π_x�C�>#��p�Ӯ�oO�'��7�̟���@,e�� ���^WPe�	ڑ���Ygo2E�JN��L0����QZ��\�g}���OgF�R~ؐAB�6��|#^
�pr��%4b�MB[?Ɉ���Ku���,()-H[Ǚ^���.��"��&o��̲�q�C!���l�M��1CG�?�k��������y��y�L������0@�S�j1�P�L�!D�����:�K��:�8z��Lx�g81@�?���$�>O��#b��
yL�5G�)yƱ���u?�`�nw �\�p��G��0W�^_��IZsh;"�U>��!�a3�� ]Z/��'j��0��C���S�/X_�i`ԗ��i�#:h�@��T
����<ΐ��7x}�?:ŗ�H��e�~H�i&�烡��}�=�]�y�<:���VH�4��B�S`z7��BY2
w�[z"k��`J��T�Ȅ��b#�|�����(�����<�o�2H����	�S�&�|���lP���s!Cv!�-�]��
�������{.��~��ug�<�dT�� ���6���O��D����	���^��'��%�Ym��.=5��CMQ-\�|���IoBp>���ζ��L��~�+�� �9OW(�`�l���7��֨���t�'T㷈O�U����e�;�F�w�&,�+���4��k�q�j����'�w��H0/��7�B�ZmW�K����F�%O>��[�x9i��lv�A�و��m���}b��)m����Ad���>n�q�+���0K���M��M �47E����������+f*�{h
��A�QL�kA�c�v�PT��"�ը�gT��QM�>��԰�ဌ�0��sp�ϵ#_�E'>�l$������C�����N��(��{�k��t���Q��m�0�ۉ]�qH峸ao�����0�2!�ٌKl��� ��[-&xܖ��i�`&k��5��R�a���8�C�aZ/�Iͣ�&��׺;4�@[��>�xd3x3K�`�l�9��˅B�U]o���S���1	�Q�(�4T�׋�d��$E�tx����>3����%����!���f�����S�6&�l�j�]qI**��Z�~��@Ho���,��9۱x݃�'�[��V�G5�5�XWz��yZ�M�q�����b�揢�x�F�G4n�ow����?�BJ���bz�Du6�X=��A¥�q�ZU�]�mLG>�� e��a���WF������/pJZ=\���8֗8>�hoh��k_A~\��~OU���A :p��p��KQ�
��΁_�UЯ�l*9��z�FR'H���dz���H������gL��t�>���@F!H���D-�Ë��%J�o��H_��L�w�SIubb7Y��%�L��
z0�5�4�qh坟���|��&+X���J2[�����O�*�
di-��U�r%S�a���s|������4D�s�@3��>AO��O�,dL?O�L�aş�ZpNJ�Y��jN�򲚷HFr�"���ċ�r��L�UsKu���(ק���1��V����.@$�����0���tS%���x+�������	P�&{#�L�z:ĵ׌�5L5�CI�d]�R���Y��mhE��-Qڢ� +��q�P���N�F�����"r✬+�1�C��U�t��xzb�z��d����3�v���\�B�t�J3��_��2���"��+F����Z�G��τ}z|p����W��f���5����9�`��uy+����yy�:Hv�aMyg\��~��py��i��|�b�������O7(�E�5=Ҍj�._7�z3��`�z(�B� �����BK�S<Ϛ�ȕ�MMl�r_u4��Cڳ��OQ�!)���O�3������m��28�F�����D�'�o2��\�D�w� Q8�ģ�~Vv�,E�-���j�˸|��&;�JmWu��$d8�6����`e4�c3�~�I1Δw��Z9�yhpN�S2k��x��6Q����[O=�ͼƼ�B�O��xn`��Y`���Q��ҡ�,��k.l��Y���V���mN6�eE1%G�H�7���(�4缏��*瞣FY�SԕU9������ѭn�x_zf�i
n7;^n;�ve�+^��ݝ�>��^�2HR�`��!q�:��L�}���+}�r��ndcr��bP
�*�+J^�T��4���;wF�F�Q0���?�ܠ+������hW��"V��:��h@X�)p�gV�Q�|�$v˓�}f�0ŦG�m��J
���3���W���kBޖ)Y����B���ky�.#&B��[0��(+0��E��R�i��b��ab-�,�t<�8�m��w�W5b)���I!uz���{�&��JQ�T�\�"�<��!�R���g2���Q ӻ�f��7BF��z�����*LC��HIw�Q.���>�b3�����B~?_Cpъ�h����T�ꂼOj�}R|x�e��x�	��z촦_y������m��U�<VX���hj-{�	/���R�5LXe�g�ʷٮ���W�**�!%���@PȦ�@�A�(J�!���|�c�fR�Q�ga���cr� � ݏ)��
	�,��SL��b5��9-�܈= c�\z�	�.v?r���#g2��J�lm.̴�Y!�ؑ3&NY><6���
�7�M����-M{�8�TCM�>8`��c��V7�j����'�A���$2;f�"D#s�2^|
�#�Y�!	"��`���r�%�:�$>���W�|��n }G{ք��3���RϮ�~�0v��a�2ܤ5�����B�?���k�r}o �<v��3v��T���Ue��wz�Ԩ+/X^\����K_��7�PF�SK\���ɶ�iDOsw��F��s�����"zm	?vX~�}�X�ՙ��u/��7s�\�����bo�
�M�Q	%�����ۘ@�,�+3�Q٠�c:NN�ԟ�)��]�-�뾭�~P��^�u[�_�.��k���J=2!o�~n^�Rf&Rj��s:E������7��㬣����)�z���wqD*��|�L�%Ȋ��
ݩ>}=������ >��M.�oAI�1(�$�h(�U��7���L2�d�i.%�1�Ƕ�{��3�T�/>a��J�T��3����'(CM�ĳ��\����~�@P�U�txg@)��z��y-l�U�K��jG�M�s�f�� 5j4ƀ#���촪z7&3��N���ը���}^뾐2����/�b�n�{>|��B1��?��l�4V�鲂ӽW��M�z��Z�l	?�XӤ�2�C�tzTm��b�|*B�F2R��&F*�bw��Tp��4�*���"�{����K�X�;8�w<�L%m�*y�F�[rd�op�	!����,V0K��Q�d�W�{ؿ/ƃ˜��RZ,���uЀ땎�Zk1���H��`;����nlQl���$Ǭy5�^u�-˦,�]XWڀ��C7�r1�=�*�!�T��X�T���3iLc1� ����0��UoY���;��ӛQb���6b�Q���6p�;,�,�M��1��6��I�BB~tXW��s�=2��C+!�\����:Cf�˩��fpq����&2Vg�?���?=8+/�A!=jc(
���3�	��L�B�%*Ն�C��[�co�,�A�p���Q��]��l/@�����9GXu�AA��o
���Z�TِA<̶F�*���Fս�=�ۃ�+М�
T5�	�sH����xf�Q �(O���\�CB��|��M�=-��@D��R �b��N�Ȱ	���Q�(D�+����vQ8"kS�xV�{���#�ޚf�d�^�U�Y����(�
*,�F/���0V��a�ߨ�}����.���'֠���'�F ��k��ҙ^%���SJ�f6�i���H�M�SY3�������4��|`���$����0�'Z"$�������q�Wq��Kk!��-s���kx����=E�����=� d�(�y��L'.΂}�D��^Q�� ��
�u���$�F?��2>�7K�I�2��6՜�k��{ܫ�����p�[��>�Tx�|�ge�n�Bh��[��>KG�6�����߱�u�Q��)�.��Ai�hg��X�P��ɳO���|-�`�B�x���Z�lm�C��W�-�a�W(�_3 ����huɩ�ES0�m��6���!+�'��	�ٗ� Az��7�_Ξ�����#l� 3���
��^�Q�"�b���O\(DN��9mG�3,yXe}��3_�X���np}͘p��2H��P�8�B8���g�_��Öt�U$ =��$�Jg���_"���=)��L⣊�����(�qg��9Pzp48�(�{j��;𙵚��U�N �������Q+���^y+��4_����)f0qdā���g�>pt=']�5\�f�EP��B� ιֺ���l�D���`
�"uJ�9��	�DzP��!���ʘ���`La�f�����z��@_�s��A4�va��1�H Lq,Hak&����(�Q♮%�Ѣ�	L� Ά4ݸh
����lxl�.�:԰��Mw�����}$r4$_?���.��Dg��`=Z�0pm0dV��b�m��!�Y���KZPUE\}M �R�����,gVF���n��r<-�-�EDk!γ���h?�ݓ	H���-�|�/�(g����[�2�Qt�����Ks���Y�[m�|+X�v�M����N��i��{"|�L��WU�Ю�V�0�Z7H��R�}��j�Ǥ̵�B�L�54��;K���l���r鋎~vp�Y�����2������?s?�� Xh]�;���o�Q��^�-`��^<eZ��U�\�F/OԀf��lL���s��C�DE�9m���jJN8'�i������
އ��=0*u�ޱ���U$�s�b2C�[;S�J�:�n�-�3�H|�Y?�]�ے�e+!��<ƛ5��UYU{@���)����q�${��J�h:DZVl/_ʎ#�3R�\F:�����_�"8�`:3�Z6�3���{΂����hKi��d	���%ˋ<��K'�b-#�����_ߖ^��Mb��"'�42t��^,��4�I	(�¿Zo�͟E�SFȹ�����H��z���\��`��<!��5]k?��
�V&�$S�-�|�.���ʏA�Du�E��e�4'D1�(L��J/���Gd�#{��;>'���^��R��\0�Q3��`ȔP
�䊿*z�e
����(������T`n��l8��p$\�K x!ݼTN�"���,��.�~���Fb`v#m
�`�U����ي�Xǲ�Gi�;������$I���vV�d�6ukMp���t�/���^�?�TP�4��ic�tF1}:���JH7Nh�XU�e�M��x�F�:K���D���+��Z���W|��j���ɲ�<��X�T����f�I+bV����������a`��j�D@����ZE؛oR�� R����I��n%3mt�Ii]]o_��|��n� AD�B���"ѩT�}���/]1(���mu�$
B��aQ��i%.	h ������"��%b�E�@Qj������<�JΟ0����.&�m��E-D���|���C͘N���N�d��s�+u�=w��+P��з���J�m��wgJ�ea����;a0���̑ױ�C�J0[�(�!�����Ѿ��k��X�ro̽C2��W:b�|@����z6��T�tW7�������g m��އ�hM@~Q�jg�Rs����>�5����T|��$�޹w�!������d(�X����e��a��V2Mptja6�e݇���݇N��-���u�Ttr���?��Pr���o:
��E�t���EKإ7�}�O�ć*�V��b9�1կA#V@a	d8�	���J��4:n uqNE���	���:0���������_6#����\���Ч�%󥲿�ޱ�٘Ml2���M���B��dOmw믌�)��BP���9����f"�w_K�h}�l*pϓ��[ĭ�4��v��8<�G8cbKZ��CDW�����O�nA@bo����O($Lv��/�԰�mشv�'�Q��+�q2�Z�K��ۤ��	��_���=�(a���-���o�$���2��ic഑|��t,<��>���G�w�U&Kb?�>��wԄ��</��r�%b�x�-4�dw��bu�+�4�{$$��:.��;��u�Ga�_��{w<��A~�[BT{�{�n"��@���la������#���h�(�߹,��M<��� 3hYqk'�r�C&xe^������w��3]���Yʞ��j����7�������ﻶٺ6���ʝE��F��ȂW�����{ �3a�u�������b���2v
e��lfg+SUD� Z�o�N9)�h�,<�dU��EP�<Q�HF��������/1��"s�k��<�k�U�Fz�]�mt���ّ���������I��
q)�ؤ@�����	���~��z�aa��vJ�K7�jef)xk�$�����)0Y�r�Գ3�L�������ԓ,���j���0�24�c��s2-��ȀE	yE�R[�Y����X�-��a4�7�����y)���f�����cgu�c��p
z)�FBG�����fPbb5K��D͈sZ0��<V���}AF�%�tS�	��Ъ����	sGqݍ(H�t����<9���X�;�/n�9"9�e���Zj��H&�Vr�)ql��@};�\4�f.�?�����:X��iϘ�*�{j��������h܂(��>���s���6
�L
���#g�PtJoi}�����H[��>4��8����[	~��<�$��)0'�"��p���А?x����B�')[>��iK6L|>�F�:��1f� ��'��^T�k�Wl��b6x���,Ɗ �N�0 Ah��{s�U�������yV�ѰF7z�fů:�O���y��O��
jaX�T
Y=u[n���;�>��ا˷��15�1���WvҾF�:�澎	_��� �QwJ� x	=L؟�"�w��8`"��F� 8�4��%�4.�P�Յ��![BB&PՇj�p�Qe��R�%'7��J��Zrr��" $&�!�Eҧ�����ԟ`�D�,���ݼs���)< ��sj���;�~ ɴA�噴�U�h;�< �ݭ�f<��i]��nOM}+�7>���b�uX�����=�3{�j���`olǱ�|�i�.����9�/k)�Ke�0 ���'o0�Bb)�����b(����V�~�>�G��xFZ/dp2�~W�\��܊~��#�].�LcCa��ڼ���ĉ6%4�ӐRGo���qh��z������L������ ^��F�D�A�g��O�	���\�3v]V_���7hr/毥�7�˼H����Qv��x�X�Wg*�^���22|��!<�Ve��>���FM���ba���iI�?���.RfD��@����X$�H���ڣԏ-�P��kRI5p����!��W	b��3���e�馄G�U
����5>ڡ�;�M�E��A����iLB�;=!1b�i8g�d]� �cY�o�p&�V����Z�悸�d��|s�r�T'�\]�n�� ��2���M3M�$�K�wuj��t4*���Z�JT7���`-���4au��� Hy0Ho85�|��H�QB��ˇ����(�Z��:H<�`9}\���z�6������Mos��u�~�L��o����2)(9�-m���%���8n����?�V��.^��}-4��l����y�T&!���8p�/=�nF�j!r�Ng�ozm�_�B������6�W�Q�8�!���e��ZA�����=a��{��-��4�$+>兣5`H��7��t�'���r�9���H�9�SX[�t\f���b�b(��[����z��I����Z(��)�߼�d"e�K*�����+���]��C=��B��A�29a�M0�Α�[�i��o��X�Á�׷ ��H@����4fE*����m��u�`k��҄&�$��lϵ�M1�f��t��[���B�B0]�c����*1k�]Յ�Ɠ\���$N(�OvG���J�N��[T-�%P��;�	gǟ2wW��tc��2d$�	W�������aV����������wb�NL��l���H����%��#z�(�1Eض]<�4��p�Qf����J�U��Sؤ֛�p�zƻ%;ʌ�N�N��Wڬ���7ɿ�Q]rO��I����}�4��� �C�U8k��@��7(4u��藶�iP`�	�����P�|��R�JWq���>�䝈�O��k`>O��3�u���Ή�/8���D��/B�>�\'�}��r�,��DT�FM�5�Vs�e�G��
:�� �6O�� (�]�$�g������e:�bH�l��&J����kmAQ"Ć���:'ĕ�Ч�싨Ͼh ���݃���>c��g��-��j�}R��;��kI�}B�����X��"�>)�G\��HCn����~WV�s'��7��7�TL��5��~�0U�kuJ;�D�آSV蕚���uR�@5q�E����{4��4�b��9����{&�^���Zg�����j��+�dІ��aEqm)��VHr�%����b�?�˶�0�;����q�������r{�%[�(�_Q�@HRh��I15�$bl��aI��F����kҵ		��=,0;�l�ӝR6���?���֧BI@����!�4��n�cL?׽p���9	ʈ��:]��3���:����&?&5fZ��Ӥ3_o��$�.�v26J�J�]��WZ��k��؜�R�S\4 R&�|��8�[>t���(��'��(*����U���{n��l� Sc��f����`M ��m�h��p�
bG�ڒ���U��M��!I���a����GT5�*6�8
=���� *�|C�*r��:�*���@�ӣ�U+�"����E�W[ ���Ƙ1��2Ѻ���j�\`�d7{$��Q�����.��[��Tx���F(mx��D�B{�"+�k���F�r'X�`�O�3V��Y�h]wR{�����n���V {k�˔\�����-���1h9�뢐О��]��0^ۖ{@	g*�&�n��H3\sccNn��u�,�"Ȇ�2�ܴ�5%�'V́�~ͪ���m��׌�Q7�U]��p�>��Qz<'d��g�3H�D�^�l�܊J�$`˿`s$��W���� 1L)R��5Ġ<�"D� (�b�6@���hP�������0S��#�`�o�ˤ�/+K�����]��Q�F!��j؇�F�����Q[F����qC���Z]ڄ�<�z���������IgH���G�{ti������7X] ��_]��T�(���f�\c��MG�Cヴw�D�i�ڔ�%��J ��ړ)f�@F���p4��L�T(��E��_���:횮�pC����`���ZT$���&��~�[�g}5�L��[-��|^�.��"�s�:�� Z��1�,6����V��  �<�4�$��%�a��m�HǉfgC�p�S��S2�J8���'#���K��!�G+�v&-�оWq���
?�g�H:qs�7��R_n#�~G�P?d1Jc�)��۷v�9���6T�#�3"ш����qv���՜����U���8Lo�� -� �qb�>��o�j�_��Kَ}ڕ�ͼ֜�F+�F�]�%�c�,�u�,�����0�����ړ�h�П�E>�r�07��_��M�?�� �d��_�L��˲S��[?�*�.%[��WwSUg 5vu]�Ztj
<y����M}cu��4	~L�qZK�ϚxA]���;[AA�t�%ĠXo�x�7է%��s�bV�KD֤�Y�U�2�c�)b� .��N�W��6�'����2 7#э����W� ��-7�^�y����d�g���Ơ<�&8v�tU����0%���؛��B�J����x������!f�<""WMӪ�\'i1L�����Ф^oX�+m~3&Y�b{2�X��;VWҵtN��F|���\�~�Ca���#�l�q��v+f5�;����4�//
����}d�hh!}�j�'u���6)W��d�|�\�Cx �N$�1�v�{.[��gA�ϣ��e��'�A^N�6��D��)��Qm����^��d��}��͏IS�#��q�z���ic5�F�*��O��{�!��4I�YśA�!t�y�U �_���Mh�iT�Of�P���O�Uz�O��4_�Gp^�(~��;��P�d$m�Q��'��$����
*h5-F#	��5�<�ѧ���h���~���q��JN�E�/Eud�[#��yr<&�]--&�x.3}����0�D�q�ϒ���ir�����/���/��|��a�G�E�:m���0���V��Zd1�JH��������L*��C�	�H�^$�D<��Q09��'�8'�r>盂��E�w�=�(��(>9�j��X�d��{�������4��p9
ַ,!fA���u聬�ӝM7��/4��W/@�RKg�����֒��r��cF�4�O��JT��`�\��f��+T���V�GD�M��

ב�&�i.�<y��Us��H&�,��܄p��$6��M����D����S�mq+;M�Vr�0�=����A�s	���<�Q�M��R���!oCε�IJYHty��4�Je&��h���m*U�s�:�͑�
���۟��&p1�T�Uh����9�TX	H���!����F���ظ3
�N롱@]nF'|n�u�0���d�%.����R��`'O
����E�o1ôSf��T��y��+�_��F�:�EO~��Q�Mh�~�k�E�*������L����2-?��m�7J�W6�z�L�����ۉ�. ��	�!i����y�9�PS�ij��6�h�6�jM�M��%��~�p���/非x�&nv�JJ'ݗx~���p�-\��~��xc��>�\y.��Sz\��O)=ʬw�}FŢ�Ԉ��~�[���R��]dx�6��s��B�m`�,��0����H�vRV��
~���|�۲l!�  J�Q;(���ɕ��7��E��0�)�������'J,�4�����<�XI�f���MF�D�������XX�*�R1�M��ȕ;Ϣ�=�ϕ3u��ӳ��D'?0끒��D��Nkͧ�Z�I.H�76�)��i�w�b��Y�C�6-[i�F`ᚁ���������5k���1�f-ԅ��0�ei��mC�:�ӼaAؕ�������uOK�H1��h���
Zr�I�����{�a�����q�drj?Q`�V�Y�*�f&����ހ2����0���㵂�/���rr�a����d��Sƚ���|�461UT�`�aԶ�P6��Z��??`ʼ}��L�]�By3�Mep���+���KfS��Z���1d��И}q�}����3�cOm�B�z)�N�����^A6�a�SHѼ��Qt�(��r�x�����Z���z�qR��5��z�e�Y�����x���]()^��q�):�_c[�RS(�<	����_K�'t� ��cO	v������4j�6��ͷ���KX�R�i��y���I�ޕ������nߢBWWU��FP����&>2���H>�;.c���� o[�OP&�H�둸�,1g=�q]o����/u����fkx�AF�J��̻�҉(+V��y7���7�+%KG:��Uq�F{��Tξg�%W&���/-�]�I��ޚ-�=�Z��+��m!��#�|g��p�E5���nt-�id>w,p��(�zp�.�u���,u#Z�^Z���|�'��o�@�n�6�Y��O�d��I�8�U^\����
��Y^�%ˢ��v��46�xbi�M�}F���W���y&uݹ*+�m�:�)?�x���< ���5O���`�K�[R��څ&��9�{Ztw��ڶ�eZ�|\V'닜�굪�    ��ܿ�x �����d����g�    YZ