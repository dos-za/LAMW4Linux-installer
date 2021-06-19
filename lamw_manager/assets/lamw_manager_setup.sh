#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3315917556"
MD5="0396c63261fc85f47297985398f06183"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22796"
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
	echo Date of packaging: Sat Jun 19 15:57:31 -03 2021
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
�7zXZ  �ִF !   �X���X�] �}��1Dd]����P�t�D�r����٠���)��1�&��rqţ�����,&��`���d�.�����SH�2R�l�Y��s��S�D=
i~��ni�
�C�H��c.1��@	u�H>�lY��x��-���Ɵ�JI��u�p|��[p�R¡���(Ҷ���.s�߼�� Nˠ�����Rݕg��oW�[�+Ě������0X�3� �>KE��cJ�&�)���ﬨͨ�,�)�����d�0s�"ͼj�.�=Q��JҸ���QK�{�Mk��쀦R�H9�����v|�?��.H���W���0�]�ZH�$��g�������Q����7��j��ׅ�.:4{����lĸ��tLi��b^#�l�O��|�#�B~��!�jsSFdoBt�}ZPc�g_��]*<�s>fRb�=�m���R��⠺��w���H�G���>�qq�DPԛ��j�
��v��O�o���W�{�J��=�x���uF���*;��8�e]��BU����z{��O;@��v�����ڛ���.�1ߏ���&nѱN��pГ�-=[���P�1�
v�Z�U@Cɦ�,���o���n0Z�>!�,z��g��
1�<kn�Q�Z���Cb�X�C<cBF_ҸbA؆RUϤ
�[����;��4��tAL4Ԛ�j矇η� �׮qY�\�-+E]�����OӁ��s�4t%�(�.ɡ'����D_/�d���D�1ԏ>z0�9�J�?�ӌ��`A�x�J�>�w
e�&�iGhS�KC֟!
��0�4���?���@s��V[����;��V�(&e�$�>(N2�=^�����xa[��_����WP܉�j�ݓ&1~yxF������k����|�J�r�*7A5�ǜ���<�p�'ZR����.�0��&�[�L��boؽ��_�����x�Q0z�ޙb���I
�����,j p�k��#�@Dz��V��B����!5�˶����e����㞣}�:��e�AH��~JE�pC^(1`��M����HG?|��B]���.>�!a�����mW�F*t�uRk�7M��Oj��|��t�s9����&�*R�[�Єw�>XR���N���bC䠐�� s��b<CNU�h����B&����|��k\�yҕ��&4���ẉ�f����;��>��%�VM֯q����<ܩΫ�w�>h���'�|�Fóڝ�f����yU˜�ް��y϶Ɇ�K�� x�x�tθ-ְ��m���=C	�����4�c@�*"��;ky���l4��O�K C�ܘ�bESj���j~��X��BJ����3X&�t�J�I�j D �4"!H^ҚP�����V_m8��_"�����j��������-���<�-�p���=���E�1�"��in��&W�6��E]��j�S��?�I-w�_wJ��+xy\K(��P�*ci�Á��~.٘��B����)	u:�
�ύ��wUe��z�-c3|��_*tc 	������:�U���iҿ�V�qz`��?Yg���P�B�g,�:�=1�iտ���k�ܟ��7Ba�e|y%3\�-sc�	t�d��OGs�o09}���Wz�����/S?֪���:��5�U0��[/��$�����s��í �4s�HB���L��X���-4��m�G���$��_qr����9�]��ܑ��[�'��2%�~	z��7BV.#�Ұ����/g�[Ĺ6x85�ͬ�%��d�r���ڢ\��qv�Gٖ�j�|�҇Nr����M����V7�O4]ҽ���ӂN$�[l��#�z�g�b�qYa��R�c겱i�g��VfF3K�PgnX{����M�ɿ}�~G$N�F�7�,����7�'����c@�r$��l��'���7mq�P>E�{z4��Z+}~�isc�h�X �
�;�����G�����R̈4PK,����
o�m/�4���d\�Vy��8�����p$������� ]�k=��JlgO��nj�����q��/5���\�O���Y�^���C�d��`B0��N�a	�B⏛:���\x  з���5�geJ��o�;��>��\oYG_\���J�B���[Gࠡf�.����1�K�M<gчl-����N�'��m�W���&�l�Q��֜'�>�y��8��%���DXtF��=��c���e-53R�u�)it]Eo���/u�"�����(��� Nu�m�;�e�U��?S�p˨�Qo3롧�9��m�{����� ;�����I�	QVܟh�Y�A��^��Q�u��ҷM��Or ����6js]�F��ȷ� �Cs}B QK���8Mg����F�����u�H�q�
�/�l��,�<��~vي���gο�`%_V.^4]�� v��Xd>/y�*��jb�X�X�v���(��V�
��F���#O1��d֣��w�WD�0-9%�B\f��c��^'9�5k+c��$�-q:O��������|Ojq� E�P̈́L�h��^JN���T��U5fk���M�̉bf�}�I�Mn��!\���`6Ip	$H�V��kC�����ހKT����*�i5�Dc�9i�֦zb,����@��&@��!
�dnM����O�<as!}[��� ����8kL5�E_�,��k����zz�����)_�l [�C3H�#be�[�\��(Q�R�,��m��������hu�Q����6�������o: ���ב�4^�!eXF�닸ɒ�;�#s��w$_P��C�(%v��t9�e�s�l�
όv�	�9H'�*�-��=�4��K�����z�J_T�$�]�'�B8&��@���"���L��q����e�qY����@h�%�~θ�78��A
�A}�T��fm%R���c�H.�^���6l�G�+��7�O��a�����||a^�%��6�{ ���������@���_�6���Q��D�zbx�u�f��W�洛&��7j��9d'oqMad���gA�LX |�ts^;��׊X���u�'�����,�N�&u��?�����݃�p\�W�t�A�T렫5ZwMz*���X��g��(�阀�����jbY��x���H���B���R�R���l������B�0{|�K8��/g���{!�۲7(^��9�y���b ��ށ��7{�.=�$�7���A�,V̇zP`L]�'D,�ˠ¯B!Uo@L���G$�6��������hAΝq�~�H��_��h���le�,�ot�|���������?����l��W�o��/��g1��Y���G�s��>�|�M�>	�y�hp�l����4jd0�)|�a5��QFoп�ý�g����P1�,�� _�iO��X���E��Np�E�ƛ�c�� Ǆ��H��3�/��	DO� ?~.�#R�'�����;�_א�;ߋ�]V�񧍖��V;!-V�%�$�k��OU8�o�QӦ�c�׍;�J̘A^��W��y��B,�|ӑ�肻<�*幵�5���������u�c����FE������dm36b�|�-�ϊ���˘N�W���@���7QGV�ߚ�D�	,A�W(��
�Xm��;�|ɒ������ >��_�JU��%�����˚�6V�dW�Z�cV�p��I����,����%&��_����}b�HO���:������Ew Gw����ve\J�&��{� ��9򁹟ϱ�Ԑd��؟ZjS���F�U����K��I�{�N����kN:�]���i��m��G��l���.��.�F]��E.<��8uo�Kqrw�֎���e|(r��+ɕFz�a�yeޛXn�p�7������}VQ����N���ܬ��� �����8`��k��8�z�2|��;��ylGUn6��p��S��0i��M�1!��_N)���㰨?�D�C3�߷F�(�-N��'ً�7$�t͒Mt���0����S�"k��n]�Y�ȍO3\R#Q^bEK|6Si�(�. IB'�!�$3����A�T�
L�S���NC��0��@Fdr&��r	=���4���s���$ї ,7�����'N@����F��!�
�g���O�k��U���:�m 7��*���J�+����7���	�1��;�X���Q������j��G�m��Lĸ_�X��XCb3����)�9�9��3��s�����b�؀*�Qd���{�ī�>)�r�c3]�Y޴V4�ѴY
��2��dg�*��>��r� Bu�u��z:�{d>g���b9 R�+0�6y���2�Ĩ[�|�
9J}S�#Ԩ�/���'��]2�U�d���F]���u�Lbk�!9�K/�lŭ@��4��	'�kߵ��ɸ��-�Pgy���+�7�@֌j�J����ݒС0�:�?�������^��r�jP'�*��2�@�����W�n��3*\���Su$ڇ��W��Te��ہRr4%3m֮�=�e2ޡ3/`�(9��Cs�:U��oݽ��Cw'�����0=��-5?u�c"���NB��� ���ꖇ��l�~�E�Y���U�}����o�XW߳G�c���:9K��:W�ܣ��v-؍^�q�I:�HN�4uO��K~mHa�1ϔ|B�P��2w�4�N&�K*E|�/ۜV�3OQ����:H����<�#������\1Bд(�9�������oiZ��'���b���B�PR�z�oƾ6=ǨQ�F��fv�?���r����ۀZ!*��˙�u_痡���㤑�N1�q%�Ӳ=O�~�m���_d�|�Y�"sx�S��sq�*`�j���?0eFcJA����|x�J68��v����lt���n7#�&�f�!y���S����M+�{"x��7ڒ��E��b�ZP�fͺxU����®��Y��61~OP��(����I����xq�ylJ �XN�^j�ͷ1�a3�`�gz���j����D��L仴]*��〩��J��t��"CL:`�=�����S]Q��w}56.�`���v�DeU�4x�Y���4I��P^}��JGb���s�����1�P��+�<�ި�,t��d2����e��B?��e��ϻJ7!�����ȧ���}c@Y̵�3���{ ��eRU���NF�7):�4�k�iڳ�ҫ����!��
G�G}J���H�� /C�����AE�~Q��wX�,}u�Y3�������OpO2Gj�q�s�s��9�J�8�x�x�,��� �՛�t[�K�X+�/���ɍ���l7� O���cŊI�y�OG���	ބm|�������
g�� ��\+���aR�&	���Y���X�xl�Q7�a�1���^e���.e���0�S���F{��{OZ�^!��"�'�e��?��l|j�W�x��H������Z9o�$]F�*������F�λn���B���?υ-�7�8<,����X�J�7j��-(,+j�K'A:g(ֱOb>r�"�J3�8�aA��1k��h��z�&9���S�6��0������-e��;�`�Q��B�	�Ů�{	7�#J�Mg�*z1Ryf����,��!�+Z���ヅ�q�a�����t����5�I���!F3¿s��r��6�]2���å���6c*CU/�F�\�X:��Ŏ>�WW�o)�8�Hwf ���2A8�GAW�&�G��k&#RcP�t�ט��Ak�;��^��#����t_hD%%S��'���&�~��%s�(�w�0��720K�X
�� !y�V�"`�m��$������'����6^�JoA=� ;9xko�)4Ж�@
��y�kXn�x���M�˥��$6�=D�7���d��=�cu�sO+s�m�'ڬ��o�����n)U���o��o��}�P��R�U(�Y��2J	\�뭚 �۴b8�S(�n�S'3����Ų��w(��U12�-�i��]M���� $U��2�� ~��0 ���1�#�B�t�f:!7?9�;18���7\� ����t- ������9���;/)��5_d�S	Κ�(U�g��՘M")h�'�Z>����;�`�\<tAz#,^Ġ��O|s��.�����,a#���0�?�7�\���Om��F�:�N1_�sJ�����5����J{���t���5�F�L�4Q0a���|��Z����C��y����Cx���]�F�����C�`���c�Re�c��/��A�lv�Y���|�h'���X+���|�/���?㗘ƞ7�l�������(�~�h_q72���@|�1��t	]�N�k˥);�F�O��]�0�T-�觺��a Q��F���!A7t'�l}țf��"v��s�5�FiT������n�;NKq��G+�`�:��*r̠M���0�A�*'�K`����E�Fa�:��j�^D��x��EN��B�o�;n����idZ�)7*���ȑ^�q�$#�es�Gv����OGz] ���9_�̆��w���UP7X+�_����L��$ǵbᙀ3g %�oE��K��p�%�!葀��m���Ud9�}���x����A����l����콂dw}���Ώ�|A����a+9*7���	c�e�ģ�����!����lcs}�o��ydk�O�zq��X(�[��n띕��"��3ս���K۪�k���p��z�$�= -9͘c(�Pm!7 �����<QWl �0���~��cc���~�v���ה�Լ��y��%��@��U�}��F� ���ˆ�+�G��ݡ�jݫ-�9��;l���^N��K*P��ձOI;�b�fܦ��K4;��hfu�$�=o�jJE���MA"�*�R�T������u�v��@��^�Kb`��򊄌��eB�\�d���x�,E�8\�-�U�`{���^����T%���D����}���8\<���Ej;<�$}�ӂ5�����_*�bC�������K2fu��㉥&�H��
����7��]<e���¢tW��j��g����M�m.��K�y.�ŧ(U6�;�_p��.�����u���˝6�bV�k�����%#��q�.�#�=��#�X��e����+5�/��Q��K�y��[^��lj~�#��. �Z�n�5��r�8h�h�A��h�'W<R?����,��{�����Q�����#-�L�TBj�	s]�<D�Ͳ^V�b��ǉleM�hX+�w,>SV�$Th
�O������P�"������w���G5����O�-��ҡ�i5&@7$�:㿑��'a��]����@d�t�1�"��a���rl{�k���ƪ_��W"z<#G-�о��o�������Z3�=�٧�p�����dI\�+��}�+�S~�~_�CO�5`��!���8����`P��ң�L(��Ƣ3�95ܨ��5�ϙ�rv_�#��Ӊ�Ug�p-N*7`[��`��Y��d����o�G�c]Uq�x�?)7��Z��q��bⳂӕmS��;��r8]��f���`9 �<�@�~�زnT�i�l��&��qp�B�l�Od{���B��#�����,����55�P2�Y��=_L����O�N��Ϊ;R�ǫ�*J:�3��G�����`�?܊>�`|Mf��������r[W���q	�qk�SX�yu(�S��w��f��6�x���|U�� .�m���U��N�5��6?+I���ʲ�vg�C��Û=!�����O��=ߠ�t`� �ᄗ��؍�bh6w0��!U�l��p�<�'�!���<T�k�[���ܥ	ޓ���[�� �c@�X��D3���چ6���;�N�6M$�eQcV�����7�<~�:bik��G'� 6-��#p��B��Η\3�Dn@|���t�)�F�,�Hs*��A���<�-:=�U7��&�\_X�jo��h�5��K�c�<�����+R�f����M����v��L2#��"�*a��%����V��(�x�N��ν �nAς��\��0�Ռ���JX��3u��Ŏ`]�J�j�ϰ�Jl�����\нbA���A?"T^C{����<N�_��l����M�8u����ȵoL2ׄxc��L�e�8���tn?u�y�O%�/���t�1��֮�������9l�������qnZ�|fΎF��2z.?w���U��읫��dW6�bu��C%2��N'fB�Lg㱳��Y�Ô�aq���t�Ozc��o<��e_�<+F����N��g������☋�ר��&k�kBWD(�w���3t5$j���b�4�ok��]��`v�����{3>ORfG�A��`d�F�>�U���L�#��WB`V^AL,`��̻�V�lO�ҏG�|�÷f[5��1q���H%@�&�gh�)t�E�F;�*�T�e:NŇ7���N�VG��_�R_ ��LA�j�_�h�	p|6�����ڦ�^�nWY���S }��[���F�;B�0�r�5��kU�����w�M��/�A$�lZ�r���M�	�';�񍬱:�T���Q��6���4�����W�����]_�.f��g��HP9
s�z�q7re˒�mO�-��F&���"���ѻe�_,t|��52R	O�2���;�UoRF��Z��b��oR��+�}���ea�q��l�a��n�gr�cj��i�7#�7fy�4� �0!Q{
�d9�����&���,�6�G�Ս�Õdv��H!6U!
Ћ�vh��>$P��Z���[�����lg��9���)�a��oP�9}�V���. bf������)�B<��(5(���2q�ϛ�M�����Va�;Î�>���L����0���4���e��{�&�m��T�N?\��f�=�&[���>
8����/o�97b�+��_�_��g�a	�)l�/`ƯU�\��]��}A���T\4�]���\3���A�����#�mO�D8Q-q4�ا��'�4䆤1�z����*�=X~��Q0-X+�x�f�m)����"�����J��Q��Yh�w��z`��zqjp��K��!sOT�d�5wh��3W�#���W�-����0�Ф˖g���q|h\�aߤ�I���eMa^�:���3G�pHK�a��Y?
��hOM��<�Y�ۏa�/*Hv�"خ�U?���i���˩����E��\�w��lsj<h���ST�) k Q>�+~`��w��ʓY������	�2�]����:����"�a��:�:�޸y�q�n����nt�7�; l>c��x}_B	_��l-���!܋R~t�b����*A��
�CWi�>���o�}H�~g�dg�;P��aj�d|7�G��pq)��j|���q5�%�7>'�Ր�ym��e�9�?��C�7�=5�.w�,l���n�������.(�LPش/k�L>��ž5Ŗ��A����L�_9w6��O�1���Z�D��ʞ|����?d���C�����$g�}�z�� �V�q|y�U6�=#/����#JerT�luNX7���!-+j����{˷����g9?r�*��d�[�h�n�6�q1�U��I�\S�+�N����=�$$���Jz6'��0iK�H<�P;_��q:Q�Qs�r�7�V�G(d��_"2-���#'�B��˪���]Lf���Z<��>���gh���(M��=1�fN��!�ظv�4ө����m弳�5������L��]U8����??�!�<�~�ϤD��HIQЌ�R�����O	0we0�c�4���[�wu��A�J�ۊ��27o��.���ژ[�J:j�+�{8`_��� T��B�O���_zH�/���XVng�@�P�8�,d�?�f�s6		�<{���T�(O�H�*���|�����no6`���~�2O,U���h��� };�� ?� ��5w
^��i>ԋ|�J�`�ƍ��"(f��dg��$����4$�\����kɵrm�-Q)<�`U�x��>���.�/;U�hYZ��$��Z�vr](Z틎@�z����pg 沚�p��?��'�t��@�.�&NoؙQ�����Ӏ��r�@;�r[�����J{W��LS�yj����5ozgߊ]�ⴅ.�dGG�Q��KV(
w�#i�QE�U]�8�3s�h͝jz莊*��u[wyJP��Ǡ��ے����𸗬��AՉ��aZ�M���l��˫��O����� �x���Hd3-`��%�D3xK�UO J�r�����G��[C3��{�6��	`��&�F� x�/�����2���&�o�`E߸�ڦOPmD�6?g4-��8p:��+�O�[� �4�UM~�"@���3�����&:�+���G��	Sn0d)3F�r���t�v IS�k���&����=��
�U�O��J'�o�����m�1���oKG�ra��掉���&'��vr1u�JQ	�ާ�:�"}:36xp`
�Eva�FU%YEqGbE��[Xv�3[@3-�N2�eR��*ʘ�k,��.iz��*�73�� ^D�J��Q!��818QR�uqb������$ܼD�4I|�x�9��Lr�S+�L+�U'�qO�l�
V��9� ���k��M�n�{\��=vн#��|k<�j��YX�S�V�E��UD%�n�2!����~.�匐�r�km�m��Oٛ{��{DE� ���R|�5[xu j�ZV�����f�X� k�����ې��i����h���,Z����_S^Z�]}�"���ӰJ;��[��X� �<���A���tˣ�a�������؁�u[�sH>>�c�2�+{ݖ��&�O�Ix��=v�iY/Ym�`΋yo���C8T�g��S }�׬��v���!��a��)�$��̤VSm��ϲ����f���N���tEW�ai�����]*7娗,����a�Z+1�{�,�����/ka3��`����f�%�a��ZE>�"�k��H�8*����ٸ�������O�<��Vݐ����z�Nv�D�`�k�(uEG����2}"U[F��ã����9��UH�G��cOj��2�,d�7'�H�;659�LHZdC�<�g� ���_�3jqh���
�Y�uv��O��n׵���x� �'ދ�(��j���i���$4�O����@��o�����9a4��({�'@��gz3��5i����	�m��I�~��窱y�;�|rx�%�T+�w��M� �=%!ȃ�	I�
+��X��n_�x�& �]�{�Wn)G���r%yX�r�=1�=����򟺚��!�7�����_���3y���.�
�9��)g��/,`�c��v�_ȩ��-%2�HݞO,�R��Jdw�D�h�=��	�1���Ɏ������2c�Cpxߺ���yǔ�	X>!M4f`��TB��ז�����ť�� ��� .��O436_������w�H�d������� ��`+��3?�))���/j��LT=�n�g�A�K#������nB�J�UN(e�Q&T�ﮚ�F�/�%���^��'jp?F�҈+"o5
	.��x`g�Z'�$*��	�p��B�
@���Yا_ou���RfP?��K����M9���`�UTҚ0H�2H�rr��Q��V�ڵ""K��|�Hz�OF79v�mEw�-
ۋ%R�E[�I���?�A�S+��b��8ӡ�'�$^t��t$��+[~�����jmr_�.�H^=ş�*�3wmU�b8�|w�q��&�I���@qo{eE���5�������Z	�:N�WqM�/������)���;�e���y4L^Zn�?�P��#}�ӏ��u�0�E%&/ؚ\$�Z��1���,��2�#psh�� �� T�-��e�E&�lp���W�|��b���a~�'@#��U{u�©S�
�}J㚮~��LBS�N�v�__���<P��1�
w�mcsS_NJ{�_�!p�a�i��Qմ�5��s�C�9筽�aҡӉԒ7 ��6���?2v�KP�8g�Dj�xՈ��ӽ
k�oj��Gc�	��(��a�Ft�&��~�Y%�'}�0�h��C^"�[���+>H>��5�GC�z�9ÿ.���Bl��3� �/�VN�i�^��KS>
s��W�M�s>�J' ?��Z���N��C@X�M!���o�IE.��ƌ3ހYFvũS�q�&Ǐ�t�;^r@LGe��\�+���x��qz-$�3��K�L�u���Ɏ��!�"�����iw�Y3�2��کq��^���؎P�B��8(��6��|,Q�����H:d���#w���}�6@����=w�PVe�g�c�6O]t)�}�+U���j�y�����3cyy����	�7��[Eh	��.X����>!A����W���t�߲=�f�x�T�G�$e��
�{����$���IaǙi�v�*(�-�B!�'ߞ������!�(��1έ����A�GgF)�]�n�Q�y�+S�_��D�~�mo����H�X-�KPCG�Z���#���#�NPX�b��#hD��.H�n��4׶?HBA�w�J ��J�>?��J�a�bq��z��~�f�6�(v�cE��tp�dX��u@��֟��L$n�U�	I��m��\,�1l3I�dZ�Y����?�R��}�T��:�ݷ.I��E�v�+�B<�7��]�ݾ����n�C��Kp���N�����J�}�^?����:��(Uwxƭl�쮔�	�efj�猿 Oj������M��ā��+WJ� TġXt�Z�ק�F�`����RhGݬ�.\a(�%3Q^���J��Pm�N�0���y��Z'2ܺ3��2Qub�N�|�	NE�(mF+�erb]� �=MSHֻ.��f札�߱1'^�,-�"Ic<���z~�6C	>H����z<7_��9���"ȡ��$k����v.۸!U��b5SP��"�R���T�O��-C�R��U0��"x2~���S�[���>����K�(�����@C�}>AA�H���؅__vȺA<b�|�r��K���䟯65.Cͼ��d�h�s�$seӮP�3F�/�e�R��0]kV����P���Y�����KC�d �>�Ïo��I�[��l�s���ؤ�1-�B���,���'恹	��佾�i�=;n��$�o�5:�ݢ�ϖCfy�,9�m"�{�����M�E��(�p��?j		kw�'6/�)1��5��3�d^���r"�V�Ѡ��`d�?/8�BZk1�<uf���qk��es`�~�]!�3
6��w^�uX�.���`2����o�]D�F�ṲJ��	 `��ء��_e�D'-���ف�?"�8&)l�����*;ί7�mW4�ä�4�z���!����I���#We��S)�.����ܝ������$Q3�\��H��E�i�(�l+T�����
��Цe��ͮ���;� J�w��vi6��gOgIr͈��?Gu�	q��wW
?����j������j|�ޠ����l�fx��Cwg>�Ϡ?���0p��jФrIy��z̻4�#��m0?�W�Ot:���o^�:���[kfc����1TZ@��S;��ٟ��њ��q����� ���;)�"��K����\C��M�ɿW�$m-��q��4ؗ�$ �O��$��8��57��Eu�j9�q��
L��:�ϋg2/���5a $�M9&�5V��W�s}5�]�{}�B_S�~�ƪ��0������|��.���]f�����JF�:�W��(;U�2T�h�g�y\*ﻳ�mK u��Q���Z����.L���Z4^okPWc�0(�(w�DH��L��#ڞ�`���̉I	�I�z�0�	�����:e�Q�V^�_�&�b�~�$f�瘊сY�N���QIû~+αH��
�lI(�<.<L�*0bG�"����A��t#;e����с`?{`��T��-ӻ����"�) �u��#�)o
V1*IG�%
�CX`��4�o��t֣���i��SRά���b���ӥ�M��)L� �I]�g���^�(��<�Y�Fc��~�߰�5��,����)Ɔ7��c��$���G	a���+��=�<��6�1��a�9�gf���㰘���;�>�[�6���Oz C�J̵k��h���͙�݀(g�y�I�q@ǵiV�OzQ��wt�䫕�6 In��Wtρ��X�j% �Z��h*���M�� ��:�E��:g=�<�W�G���7f�ݚ��!'�U�I��E7��:���h�}
<S�m����$n,e���|j��F�3�?̩�p�y�2�]�즚�}n?����J6�lI����&�����	�� ����
"�w���ϻgG>U7�%�2u��|*#��)�?�0-2�}/l␕�x���څQ9?��^�vc�W�(i�Zy!�\�Q����B�q��ÇU�6Ny���p�/W8������]6�E�
�>��ĭ�ԩ]Z�g�#d�p��b 2h�o{^Z��(�����!cu�� <GYy�htٵ�E��;.[:Zj����8��!�わ"ѷ�u�����T��k�v�2���T����C�L�稗k�U�����+��%��kZS}�Pkۋ�v\�^i�r`�{��s�ΐC���c�&�R��\�VOd�������5l�[��7�tJ�mc!��{����m#�n	G��|��r��w��e�^L�#�F�u��Q|���|�'T�7��|��%��Ft��8�,�o�=�
���r��e7v������1b8�D"���v�J�Y�F 8��K~Mw���#� �J��l�daZtt�}�{�o�o��.����v��[C&���]�z��1����d��.��sïu�#\���Lش�T���/��$���d��hA��滙K���������<6]^��*�eк�=�ׂoW=��d(@�{H'g� �]p9�Y���} o���V�F�ʯ�R��N`�i:K�*�E���?rX"�z8�L�r�Mʮ
�Om@�q�,�//47o֙�=gY����?�н��#�����?�&�7��wy���*��|�"2яRs���2]'mk�+<����u�\F��P��t]W덋�Z߁�)j��K�鿂��gi��a.f7��F�G�Ix{��=;kR/�b���JQėCbL@A�\JM�X@p6tt6�%?��ϲ#񖮈#y�@o����5Q�ۮA7��\S~�q�%�qBk�����_8i����`#�:�tO�.<H��'���H�랦��a3d��.�m�����fCy!�n�F�q��/�����ckw��E�@A@�	sJ���A� ��N��X���D�6��	l~]ՔsZҢ�0-tؠc�rA��^������]I8��*e�ܡ0�8��Q�G�hI���&+��ڦ��ŏ6Z�?&�ݎ<��N����LG}06�H����\m�Y:�L��#0��824��,�\Vp��Ud�3���)r-p�}�O;�+О� :�vʛP/�����DEȆ5|����5'5)v���u�^���3��1<s�r���}y�T}f�D�f��1�o�8���_6��B��oPr/�zi�g���nwR����U�������mES���6����Pm�+�{N�K���)|�m5�'$����zsf�,g�8TG��"�i�3���c���k����!�8E2x�#��C%pU��T��o'^yO��o��NQ-�3Q)�����m��3����W��d�e�)g��l9O�`��+����3���hO�?��8���v��æ
82��#Ma��� ��Z[��zȭ}^D"~�/��9W���4��p���LFiL��Մy��}���[�N�������t�,�k|�=��ɠ�~�i
� ��pm���F�/��v{��8�!4�c�k�8��g�����\[E�e��yM9���(�i��S��&дz��#��]ZDS�e	*̎�z�a��ъ�S(�0�G:���٩p��󍪕@�Xx7�}�Qj�r,�|�+6�h�� �gzaL���0u�ٛ�R���^���+�d����T��?J� X����r#c�=2c]�'e�7	)8�UpT�#<Z��b/��~E�c��ai��A�&���i�XG>�
�Z[�}����8k)���?A��N��{�x�5��H��O�i����O6�U��;��m^�%,[d'���H����y�����a�����������]@�)�{d~���Q[R$M���{�n5b	�ȩڨ8��2�tWU���鐥�t{�p�|;��|�<�=_��K���;�C��\�-��f�xE?�w~T�#�)�P����,
O*�W��n.a��i��g��p�k�ܫ�߂i��簺+FУ���3Z�zuR�忨�-6��R�bq�XW�/�V�U"����l�ɐW{ �d�)yb����^�oX����I]�X�EC��0Qհ��p�Nu�6�{�fV^�^��G���d��)�2[��3PPL뒧�:T'd��+���UW�	v(EQ��Rv�����:�����H�i�Y;$��6�:W�R=#��;NY�=h���ޘ|!��Nbq{���@�@���������3&�&6M�j�\,Y��
(g�K'�}���Ti�홰�*��*�o���B���Y��� (FOVMn�F����}��E�V�#�;�@�A��ц��=H׆�t}Z@á����gD8�ؼa�r�qc�C�����;�5 q�0�O��d"jv�༜�)�e�	_,mO�����
�ٮ����[j�t9��C��\����ME �+H0��ʘ�+�|u׊I�1 掩��=�w@�]�gjKylq%T=�.)������=��pO�hqv�QR�:]�YCF��K�M��Z6�`�l�)��#b"�ܡ؟[���:K8"���@nf/���G��t�w��S�t����[ђ�3�9z
E�>ߡ���ל�c��=�œm�6@C��r����,�)�=0��϶j9�i��� `@ЧM^���Hx@�هC��&�v�0��<L<��Ʒ:|�Q�q��?��)�n�v͆Az�]�`��E��Qd�bN��{��S�̖	� ��?B�l��� Uu�G;�m����+bi�;^�2u��W�H*i��F'�ѡn�i��%K_+����+ ����z[��C϶h�J��*QL�$5=x2��v�]���� 6�~��+F�=�fk4&��&��9��"%���aݣ��<�8�.1�?�&�aO������ü�Bw����m�2�)���~-�̲����/E�U�y���%!u���I��7�A��'�a"d4&t��#�y��X��^ſ}�s��T��{��~qJ5q)I�&�F�ʽ�2b�q��o
(&��Sr*8�P:��-~���������h��CI��|g-�+7v�/#O5���q
z2&z����kh���v+�KÈ�������k@;�T��X�E}�Ca�np�ڥ�f	�N�9��\cL���i\J��a��i�͕�L9KF;��we|q�âz��$�x7�)z�7�Rt��I�)�s*�
��`?{�0�6N6���{�8='��vS�^NޘQSV5��&��ξ3P�],��UEִf��v&
 � ��V���l#�1=���na2�ĵ�g�*���6.��H3�x�M?���y�Vo���Yk�fK۷9-k�5�y���{D
{v1C�
z�-��IV�eN�b�fJ��B�.���'R������Qh�P<B=`r�ˁ����s��jè��)�� GQ[��l�� �E���P���#T�,�v��*���4bZ�LUS�4��p��hQb�K�P�rI�S.~n����K�����g� 4[��
��]U�<}%�0��ѐ��(!H�l�|�=��H��W���x�0ʢ���R\J�x�&�����y2�E�%�L��-TA��郆�7d������)�A��D�L��e�'�x	h�(���+]<�-�X(��r��>S�=���)���:2(
����� � DnN%\ԺjKW �1��bK�hQP.�����'��\�Tls��2�#�Of`�Y�t&ŵ�Ѩd�"(�Y�:�Xa���
��c
�WHAܗ��u0���y�$ft�*C]�!�R�G#\K�^���Ь���R�9�
ہ�:7Ѭ���h�xg�e(Ȟ�z�l�FI�����~q1��1?,���W+�~�Zm��f
�
n;�����^��wj��_B'��^
u��QP0�w�?
g{�ꪮC��p��	Zp��Ԉ���H^���J�+�5��n Yc�������Ġ�ݨ7�<v&��-�����H�D��;�H@Z��c�j�	Ě��ԯx!����+7l�h�[�H1��g]��JP�n�C��Yڇ�ckl�����{��c��
���Α\���:i+�R����]�m{\��#c����D�c8�y-3{"��3��K2g��XHuO�S��j�G���7��b�����u���r�,s�[Q�:LF��fv���FDE�c��=^9�o��2/�}�S2���FN �o·1pέ�����%���C8� �Pd;��Z�$,o�����Vސ�`�f4�Es���J�\i4m�~����}m�69b����$�y����h�86� �K��*�":�q����ٮ�a�t䕪���El�X�/�u������ϻ�u�z=p��L4��%��J��x����S����	7�*|쉳�K�(�����l&�֝�����f�3nd�/2�?V��`��V���Қ�u��jBy�=��e���s����p�Ք�e#f�,�w~A�,����W��]�Y�A�G���n�B5���>|r; ͧ�wҺ�	(�g�O.�����r�Z/�Z-�"`� �<��7	���zz�vz���:Drm�����dL�8�	��b��ɞC�̒FIru8*x{5�!�-�������.[�Ϝ�}�<]a��-�ھ����mF�ȏ-��U׾b�!N����?�T,~����0�rl���r���[�2���_;		.�z
@H_��;���M�z,Q`Ҁ���;�!��!�ew��X>����䣛$qm	�bS��4���_�E�&Q؀أ��M��o�$�S@ݳ������Y��E
��&��~#����d�#_��ֶD��)�b�єI�>���]����j>B\*�EP/�ja���;�^��Y-�?t�=���}b���������EU�P��P70o�*]	�|�Fs=Ӱq��h&�k�u��:3��Y����0�����JSW����.�F���7���?�{d����W-y����X�4O&u��ӝ��s����L�ᵇ$�+~�z�4�r���+��]z�;����3�3��yR-������<��މ��͐�n��;n��
�����h�UO��P�`�x-�q�q�BG��o���J<U���s���֋��-�tP�	�̋��v��Z4FB�q��W�z��Ȫ{=H0\?�~(���L�����gO�~=�W�$��Y\by/��;��hƞ�(�����!1:�A�n�1��x������Q��&����,%�Ho��8-_Z~���h�����g|�!P���Ee��3ɝ+j�#��jC��J"v����@��Q��3?SM�P
�'�-����?n��)GQ�K�� ���2Gz��M�) �0������I���);[�B�/#�r״�oy�F���O[B�����ѬH�-�J��"�v�cD�U�T��\�&UC��4�Z1�"5a<eC>,�r�~Y MZ��h�E��z�c�"=,�h���q� �[}�_￦_�G϶�B�h�c�@�f�a�G^l����8�-�ry��d��S����&�cո�u�� �&sc�p56*%^N{:D�|V!WsP�Y�9J*m�XK\9�x�տ��L���)f[G_����x�V�)�@s�J-r ���{v�.BuN|�P���{S$4Տ�Fׅ�S�� �w��:��w�j	.���*���B�JU�("�z�a|��%O�Q_<�ŭijd�b��Z�����Hcw��]����| �B���
����emث��+ص�┛������x{�4����q��'��ב����3S�k���R�*"@�d��A�&$3���$�����$|��(b�߫��~H<=��-���3�2wR�g��! �bQs 7��k�,E[��{��ֆ����CgLR��;��J�KyF�r����B�W��C��P�"�"�2��̱l��"�D
�B�E����bB�KT|8C�"�D��a�jD�Ey��}�x�h�m|{���S�8^ZN �o�G%�NOI��-�^������+l�dbw����JZ��ee��8��R��ڐ�T�	?�п�*���K@�@p�_q͉fR/1N�_(`��e�>_l�	���\�j�X�Ǽ����<���3wH�Iy���f��l�{����>�(^�百�����KpT��#"��VB�B�H䐥������vZ>�o|5W�=�=��$��ĿH�7�A��X�q)3��|[�1^u�S_[�g4�'c* Q,�s������2sg��+Y��w$��gU�y���9�l��iBy[T�8���&%)/�?k�Htq��o_���S��1�g��O���s�H�/�Ә���8<�ns]sA�c|��9����_]4a�e(RVCQm��g����~��p��U&#� |�Y����ۺt�І�L�"7�|�M��8�ᕙ�Ux��o�>��,����'q rzVH(A���ԃ�Q�E���%+���֌pk��=��l�ʅ�g�������eL<�]FH�����fЗ��x����W�����*0y��?� 	|;�����Z�|*��vD�$���1͚В9�&��X:����ǣ+�dY��_%�u��j�v��4��7���1����ݎxy�q�I
��������G_� ���VK ?!W|b�R��{ ��2�=���l�|J����T���	��Q�	Z��ȭ���!��}��?���"��:�hq�y�xI�IM�LY����*��@m��i�SB�t�j��x"dG5&���H���z�5RnE���]�_���u�_"��΄SЊ"`�!�f�O@�����p�j��E6;�p��6��.���QT�	`Ffˢ���&jo��Ѵ��`1��'�+�A���Q[�IBVAY�N%��n?W5��^�C�A���_!L�u�L��)%ķ�dK�7��l�c�e�/9d�_e��)(�|��Nc-�p}� �\U�9~��vL���L��'ʒ�W���ݮj ��ܿq?�SͤƠ�&��ұ'��PȈK�@CN]�D$0'��H;��6����x������A�`��k9���0y�����'��Ϸ��J;��W��Z�T3I%��7m�B��6���Ι�{��&��H�%�v�5�gI���j
l[D�F	c6���5�����$*�yP��2� uԯq�r�ʕ)�ߊ���`$��>/���O�M���w�k&�f�W�٨]z��vm��]&���ߺp��v�+խnQ60� ���p=�=���(ij[�F��baO%����+�4��ݻ�l�ɆV���43��v��J��*s�r�o��r�q��hJ��:FݹpH���A����!���@T�8Xl°cY���,5���2\�Mk�F�B���*	U�u�a�;�|��2��!9e�>Q��ڴv�WO�	�4��U�X>��z)��4Y�U�ּ���OUW]NNw�X��Պb�e�G�w�Eû����a�̔4	�����$���`w�#x�R���@;ۿ�|Sݻd��Ėd��(b��:]/n���27lY���S��V�Zó�����7^�C]7�_��wo��%����_�m�m;�If5�2�z�ɘˤ1J�=���$�UX���"���a%U�	|6��i�w9���V�����k�s��O�dȀ=�Q
�aE�͙�'d;P�t���z�_l��3��_a4_*�cA�>��J��f��k&t�ɑ��6A��1����3Hx�^��	���c���1�F�J�~��� ��3�Oc2:f�C.z�T�D?k���H~�[\�A.�`c�Ĩ~c��Y�K�NTΩ��Y���DU�E  ������c� ����T����g�    YZ