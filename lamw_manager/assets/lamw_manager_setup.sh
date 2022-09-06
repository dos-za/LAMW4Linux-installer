#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4146427114"
MD5="a03a61692f210940f3594bf61cfcd395"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24344"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Sep  6 14:33:37 -03 2022
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 140; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
�7zXZ  �ִF !   �X����^�] �}��1Dd]����P�t�D��+��V�c���po318���8L�~�zƷ��}���_|8v���A�/��_�9XwD�Վ֎R�;���{e���G����ݯD�ف�B�zzh|Ն�U�KQ>KAn^h�:�(n{���%EHE�9�ل翤$��<=R�)_��+��$���ůTB�o�Z�j�*�~"�vb�q��옯C�M�,PE�� e�o}Dhv���y��sІ�q���ᷴ�ѳ���:���+up��5�<WB�rpbԖg!�?��s���e�����Y6#�:���������ɡ�Wȃ�f�8�C�p�]ᯎ�86��V��^3��4&{�+��4��y8��H/h~[3�2�N*s�R/�t7�|M�qg�S� :�3Q��Y��9�∡g�̻�����#�:�Kغ� >.�­_����Ȍ���"��hTН�'�L�%[�6-��1o�;�9��\\�ZՓ�.��;+�ӜRٯy��~̫�E�&P����\Ē���SK��k���b4a�ռA�6��� ]��[�}Ds��`
>,�\�Ԋ�����}&�V�G9���7�^#�0i�00�íӀ'�r�����b{���s����_��Y�P��L��#c��S�SP#Jl�@�Rs��
�=���8�
�~X։�$�?zMȧ)YOћV�f��yM���q3,Ճ7ĶY9���q3x��&��3�fFJX��b�<!��X[�W�s6+߾E����P��i�g}�迵��k�Vѻ�l��U20�,BE�������)_|ZP�H�>��`�>�+��G����%�n�Ab:c�JH+k�`��ο.�7|�]�~瑈��>�"^�=:� �:XP�'%�	�YP�"�ccSyp�꿌nH�'�Ѣ�K�`ͯſ>���dg�C&gd9�W������՚@S,��̝��`5j&�ڵǁNiz�ۓ���9}M�
��c����ʗ�h'���T���!R|��r4r9�q��]	?d�Tlo���ɔ�yV)�6��8�g�b��X�i�r1x�,JּJI�=��U�,TK�M�apP{êw]6F���w/��C����M�8Qv��87r�u���d8-��ϠaF�V"��S "1D����6�It>�����9���Vhz4�����&�����7r�
`,�L^+�o��eU�l���ײzϰ�O����gHר��K����u�z��|杦F'�P�yM_r�@��؅Mj�]�Q��B	�o���4{�H}�	sB.sx �D��Y?Ԉ�A��U�񀠊"FP�m���%}�mu�]�H.$3����S��i�9���\�D�4��ZL*���0.Yy�F*��2��v�p�\G����V�К�j�9��� �F�n�A�D���
����L� ��_��:T38�r�o�=��S�;d�����-���m�xZ�?��[�
����n-Cv)᳉�ѝ��TA���OލlQqR�Q~3ŬrON��ӳ��ʓ/�v�>'�Xk�e�����O׷a���s��e��K���{F+	N3m-
�ز��ŗÚ|�lA �N��oj���v����w.| �㢘�h���ɴq�a�zK{�us�+
H�ի�e+OD"�ha����w*x|pu��k�p��W���ɉ�^��5t��&[R�X�p<�V6���6Zg�� G�;�㐁^�|�`]Q�h��w��E��l\� ��X�����fʻ� �9�a�W{ȑ6���Z�#�T!�m[�^ގt�ヨD�i`�|{M6_eM�S���ff�4���V W���A�)�����H9	##=��+�!7�,���b�Rq{)��؆-���=H��@C�����*&�?�Z�._�,nu(�}�HR]r5�O`�o�'It��UN��ٵ���s��ҕ��1MNk�:MP����sʖHi�k�\����x�t�;�؊1t�V����#�?�����I�:�
#O$ܲ�9�.�d����A�!<沋��7�a頱��1�z��/�|ٞo�)~ҢF���Mh���P/����PP�Xwr����%3%+��pyD�� ~E���R[sNi���y�zi��9�x�P��ņXx��_/ ������"�k�8l�8�wFQ��]��Z���g�����Q���C�e�Zr�b�
<%�Q>A��g8陯bA�)*����v���� ��s��XR�ȍ�3ta�V��gj|&����r��Y}'%(��	�R���[\4[�Ԃ���P
�� �?��Y+\�R�	����Cu�g�
Yi������5�7��H��s�n�K�,�R�h��ݼ��5��	����ʷ��Ɉ�k��ʱ�<�;Gћ�sqp�Z�^�����>5i-c�#�VA��2/>�1��蜙���7᫧�BJQÙR�k��jX����ʨq�>��~������A�^�S��*iC,c�Z����)t�E3��?������5��$�N��T2���㰏$�'��q�+���Y�J�}C`��i1�;�	�s��i?!�JҴU�:"An���-N�|��0��b��ASo��4�u���ce�O�5�k�0�&k3*�:M�|x�(!�ĨIQ`?�=H���ck�5 �ݵ�9�\F���됳��P���1S��Ci��J����\'(�ɽ�lv���
��&�.W:5Y�T	�.��#Q��զ�
H '�ۃ�>�*��x�o��F6�CNk#%�n��N�x�hJ`1D�c���J3�F\8��+$�̡k#�Ā��h��a����n3cp�����/<s����1p#��(�V]#��5��x����06�8�5��iaM�y)b�ءV��h7���w�qo�7��̜w"gE�wf�l�Ks�"�z�N���w�Ĝ�n��ezjO��`�%��>�V��@�SyH�V·WX�K��T*�s���^�ۣ�5���O��z'� {�����&�H�9��6J2�f��OȚN�����E6�N������26A�{�dJ��^D4�§��؈��|�i�Y>Mj��![Vߠ�i��{[S�7FQ��Th�/nD�Ug�Ѡ?\���д�̋�m��e���A��Y����V����B��~�s#�Ͽ�*��Qs5!���Q��t�9�t-�M��-�FV��\����� Tg1�bʵ�横���2�����FsA��jT%y�T ��c�2�a4�s��uB^�I�S�0wR���e��(�B�_�^$N���� �- 9����D������������>���)��������n� �7�r��;�_��" ���E����gAʷqG|𾋻]��1�tkI?�4	DQNኁ^��V`.���MNy;Iy�Q�o={E�l������؁c���x�RE�,�%�8�'����W�VHgM�}�����K��M��z�4B[�vC�]�z�m4O]_$,���+E
��!W�'�+7D�]��=Ez�ӫ[�UH�MS�� a�
U�T��[�6�n���4
ݶq�"S�":����I�*��ݨ�`����34OH+DE�L8<٣U��@7c�P�Gg8c���K{,��pUZ��
��K܌�
�r�[,`]��,�;���{���0��� |��j��oʆv���\r��~�Q��|,���z&�A�tj��g+?O:[U8~��1ưa� ?��1�j�uYaĐ�����j1�m��5�٬�D;�[G����Eʘ@C/���8�og�R󦈷2ōG�׮Ls&��Ls>fu�M���d�x��+?�xfa����Z��k{g�"��J4X!�5�>0v����M�Gh������B�'���*�hF���gx/ҋ�5����᏶Uw���N�#`D9��� ʅD�D�$���R��@$�sK��l��#���jz$�E`%x�� �b|�W�R�N�v�^��r8
A�X���
��R�O��.{���;�g	���`��5-g�h�wX�v��{q)��a�2r��u�%GLil9�� ,8��&��	�
9�~W�l��8:R��_	�,_˦$�	'+|�as��w�P���a�\t��i����I��K�R��a�"ͽ��Yܔ�+�M�۩�xoK a�"H�ҧ�
SnMod��<��~!!�9�2.��?�b��u;�-�,NZ������?~��� Gԫ��8�U=f���r�a��� 8o��Ss�����g����1����K�Ͽ�b�KS�~ބC&=�+nB�?,vK2���� x՘�o�M}VJ ���0��b�9�ﯔx���G��G���]?����J��ݰ�����2xR�yGp�����7l�x(����٣�����5YE������+=jGX���L�F����[�i������ڬ���F��5�|-�.�,����E+�V�V�@֫n:Z7^d���_ǈ�:Y��� � �p����*RQ`�`2~Փ�Ik�Ԕ��A>������.l��`krJ� ���U�7J\��b��𑭩�����_�*G�`�\�)�v����~�M��y�g��l�@l���/ȉ]|V��v��AP��k:B�S��z��i��	�K�Y��Np����(�4��x��&ˀ�ck���{=��P��(���5Ջ�I�����YI�qKg��e"�5�':'3T'	<���t �����"g/���G�Tk���u��}r*���>t��c�]�j�V1�IG�\C1O�qBZHׯ�Q�OA�s�H�)B����y�SnI��u9��J�Z˕�ύa��4�|F�Bxط��f��	�CHגMd����,j]���5�s��,ў�p�G���Z:�� p'ͼ�j��=���&��k]��|>�?xR$��;J;�H�����$�h9��9۵!݂pSZ'D7��J�!Ѓ�@A;R�6��P.�G����%�qY*L�-srJ��Z"�\V��^��'��9�[-t�CՕ���>	T���A��~\+�# {����S�:F�*Xa7�
���[�O'ը+�^3J-{����8�����t�Uō�W�1���_i�l3���>��8�����m6�5���zx�M3�,?��1��O��jK�|�4VF�0���a4Yӷ���x��B����0�߫�h�G]��	�~�ÚC�\�h��^u�I�7��M�H��m���k=a0X�.���bHaҟ�"+E�>��zҖC�EPb^Ԓ�Z� �9zx�����bX�Y�3�z��.m�'���0@OC��?�"�C�WM�/QR�U Ϝ�!����R�r=\�6��L�t��;z�>�8Ib�����J�������|��D�����Ms��-������P/��s��D<���n��Q�'���&�2�w@꙼���y��o�{r��J����s�x�R�D7	��?U�UBŻ:4>�'/��0P�[�j�jC��V��=t*��ȏ���j#r�8�`�WO,
��hT蒲l�9^�R{o"��XB�W{�9Q�:�òfz�P8.L��ĺyo�M�`	�&��s�0e�T/7�(� g5�%n���v����8��Q���D�.���53Td��]Qӈ�E �Z�oh�U�B	���Rg�D�g�!��3�ٗ���x̟�k�O�/@̫�p��.&���Ŗg夕��C��6�;&!m)�ok5�ɢ��*��;���IyW����Wki>(km�3J�_���Q��������JcG���a��]6Q63.�3�Ok�>b���-c̹��h�/YD�#xe�+�%��5��_U�(1��B} [����^IHK׺���u�T�x_��A��5xι����n"V4�M�?KA�3E���[�'sX+�6�7zS��`����\=VrB���Qx�L؍��1��_,���V����\h�,��y^�3Q�����<W�g���0��&'G}h��2{u5�iI�4�m�Ky|��xl���z�\�}�(0!cAt�*���N)����+�G�&�Y�&yO`�e6˷2޻~���p������}��%���MCj��.Cq��/!�`IQ+=���D�������U�|�G���=MY�eR�]���_B�X��
Z�J��V�����Z�b�K�5�rU�g|Sܽ�.J
Ĉm�kP��*�ŧ�-b���~8=���o	ٷ�t��|��k[��iqډmR*c�������M���~�wP$o�!�T%�BFA�%F8	��7�m��C�0�H��#
���n�(F�]x�+CS�?��58.�DM��|�M҈�u"!�2%!��D�� �:`��8�ȑ��u��)�0GNq�p��'0c�� �;Waq#����Kp>�5�8��ߟ�D���E������P`i�F�#�z���j�+tAB�4ԇz�Ѩ��N ����E8i�h���l�͞�Y���b[�
/7/�s��b�`J- ��\�dB>��}f@3��ql���'C�	`+�%�9S8%@�������,�]���OV�j�z�C��f����p��e�ϟ�ޗ:�d�4�Π���ҡ�іP,^�#=���̰`Ao�Gx��S��(g��N�~��~�C�;f�Q���T��w��ŔZ)��eMB�`zBP��x�3�|��W�$���?��i�:8�#hd�Wծ9\@z��2�~����%NK���ċpAk�`S��7��J}���,��r�n������S��j[b��t{��]�%e��^\V������H[�$(ڻR}^���g�e��Y�ױw���v�"�Aӎ��ȭ7��Ö�7���C�Wg1{C}ά����
Uf`���g[��әZS�]5U�AT�5f�P�K@�8F�7�s��'��#������u��Syf_�N�y�mP��!���z�HoBMζ]q�=��uJ��(b��p#漸 
�+�m�7�ЉQ7D�>�r%�|C��-a۠Y6�x�C ��YI���Wr��ȁT�E�Jh��5����s�/$'��
��~L�+�9٢��>�[,n,K����K���d{�O3��u!V�TP��?�7�:��sY�ڂ.h��*�;C}��Tp���_��-8�d�P0B��o�U���r0n-�����&��D��^��}�6�V�z�`�!'&���>>�ytI[�`�B��\�g��1�>	E�WG�%;���]��k��0S�>�!���-rjC��U��q�dn���7��iz���'T���
IS�K�VTw��P��7��j	5U���ӻ�_�I��e�5�.���f8'pv;>΅�%��7������y�h�]\ft)cBz�	5��k�ǜx����>ޛѣ������f%�mF��%���F+Lk��:(�=Jx�ũo��,�=�`�BЦN83_h���4���Ѵ ��2Bkc���쨂y6�kf�!'�5L��AL,0�麊!�F�ܫ��m�?���0օ�f,�5�7�7�x����`_Ѥ�,Xe��Y��L�����=�-�^��׭�+��1�O����$�v��e�� ��I�;Q��fC(���e38��w����O�DN��Rk��J��D�e��t���3(}��l�c�Q�^�͔�a1��t+>^�ۭ9�btm4���,�h��8
Gb�ݎ:� ~֖v���x�/<�k�.�����T��5~p*�du���7���<�}z�^֍�t{��6����������}�
��' �+��(�r�(��<4%���˫0�V5�[����R#��qł�dHϕ.�f�v���v���s�&��A���t���OlP�%aN]"lH`�^E��!��W�����A�8�.���H.����8zm��=r|R���m��+�>�n��7�53{�Z�e��vΧ��J�3ۈ
ո�,D�a
,�a�TY��	erR2j@��C�����_�<����mĥ��m�Y��@��}'z�f�Zk���c�Z�r���B�Ŀ�*��8Ʋ�E.t�MT������O�ݭ�]��b'm%�A554����j��I���w'ug[�'x*_g"���M	�gӇ$�!��I��P�<����+\�E���2(lx�ɲ�O?᪰(k�;�㹅</���)�H���MC�di���r��?�����UW>O�.ⳤ����R#�ɸ
��^o��Yq�}�
��� �j�G��-��(��V�6�$)�5ؚ��*���� �T�A�1-�󍼣Ã�	��S��9��<���O!�V�wJ�+����
ti���z��� q.;ȓ:uVG�TMѫ`+
���/�^b'j������D�!ZP�5�T6P"�O��߀ u ���0P(h���-�lTxt�Ǻx(�T��b�=�P�MD{�͝�g���[a����K%�[;g��mW��%�(n8�w�y&���|�=:��E�:�ϽȹêiY�O��_�W�P{	N�ؗ�S���]�l�m���G�N��dzjNB������sD���{O�<ؗԶ��[�J�_��c29�S����ġ1���5�\�;5���p������;��UZyQ�u�!+BT����\�2��8�P�!�5QD�u
�6^�_�����~=5ʃG�=<�a_v�I�iw�8:�۠Ļ4C桱(^J!�I�g�^,,����� x.���-��wOqM����Wu�gntD3kP?!pI�D��ɽ�SC5����#}�S@����b>2m������n�:h�S)kWX�;��g2����P���[��Ǽ�>����L�ΰ˫8����iɡ���������b�&���V���ig�P�ܷ�}.�,B�5PN{�9��Be4�����	��4]*��zZ��䨤�+OޛlՀ��WV��us�0�r���q�5�@�=c����=�"l&(�:XHd���D��pga�݁�I�Qa��ḡP�3�+�m�n����W���v�V��gU�A�Z�Ο�[n��U�V�&Z�Q���S��]��
�J��6�|�q�>-<���t�����^ń}�U���W}]\d������EȆwJ��d6��[�j�������*��[6A)h,4ć	��6�YO�&�)�},�K���b�#�Gd=@�tuH��A�=4WExO����)ӄ/���2ȹK�՘D{�~\y�|�Δ!n�B@��X�D�IV�a���d���[ñ�/�#�N�iu�c��� k)=`��ɻ2����!���b;�L�8�B��V�����54��D��6&��$0�5 xɵI�����G�Ng��H�4����~`���y���f�MƩ��/oa��]T
��O��e �D(���<�zmX#9r GS�ǥ�|EZ=DQ�qe;DT���
-���r�&�}E�`�>@�H�9���%�D^n�*�+Rp. ~� �N9�C�+<f�dp¶�L�7�U�%T�-�#ܘx�g�	�䪊�K(�����t][f�:-<���LN+�J�_�Dl���a�?c�h��Xg�՞����儿L<f�c��CЭ��ώ(����r�$��˟��*�O�NK�ֈZ�58�ŗ03�o��jo���L�r�p��W��'�#�'���'�H@2V�3Gq�n���P����0����/���h�>d��g��啧Ig?��_��H�e��V}��ߎi�$�Y�B�;û~܈�r���7ΝT\h�M����YH���93r���#��A�2K�1�h��L��u�<�:�����Tw�KVCE֊s���{�,���Je�(���"A�no�d�d���ڇ	O i��	P��K��%��uh�$5��18;������������HF*�P�
Pgp���f'�a��#j����E��=�����z!�צ��T�
��Q$'�?�ep�� m�
0f%W�?�e's���h�hdy�Ү�e\�ӏ�JTK������og��횂�'B��K�e��җ�<���[���mu���h�Wd� |R�V�X�5�=/���8�ėY�����ԍ �ێw&�7�Ʊ��$���:Zif�NC�!���'!�-
V>�c
dF�B"��O}�فU���_)r]U�O�k��*�[�n�љ�l龟�V�����[�]h���¯��n��#Zt��+�Oc*NMz��A��l��0G��� �nK/�w{j3�1�jʌ����T���i��F���k�^��m�Z��/ԭ-��T�I�BX��=��2��n�$�8�_�G��F��M��2����[�VX&N����`#1��*��/~g�7P�b���5"yw��m*o�j=���b�C����ݲ���:��4ň�9]r��8~���E�|�J�?5��}O�{%��<E.ܩY�wZ�ի8����Q�z��n�r���� 9���C%X�D��U�O�PK�}�E���꩏���>�c��+2e�-,�����2)�����\�UCz��r���c�J'F����!�!�l��6ћ0���l܆���du��j$� �Q�u4��e\�z��!�0�����Ҹ���0 �g1�8�`�A�����]���wYCϵPd��1��j�4�5"�aa4R>�U׻s÷���k��~���Ew���%�܎���6iM����F�7�ao���Ktl�Eo�kO�5=�[;�[pVe���p1J�W�PH���Vh��}C쌎+b�����)�<R-}6q���"�����h1�ØS�P����D�X#5͑dv-�:�ᕶ�J�}x�׎�%L�۔G�ۘ4b쭴=C�(PoS^���21 K�>�IA�=D�o7�8�o��AU���O�bU�F��ǃ����o���~=U��e�h}�BBE؉�gV���K����ʍօ_,�����kk�&2��,	�xlL���n�����Ш~bX�v3u���W�զB�㭼B��d:����V��N�������4)�l��;N�LȳQ"{t��<�itP�<���A���9<����cZ��- k���UY������Ĕ'ǂ�����K$##x�d��+�ϑ���%�xG�ȩ��,�'��׬X��3����&��jh����G}�p�]�R����܅�הNj���(�[�z�u,|�ǹ� U�g@�vN��#6��zT��l�q���!�������h xDY印Ƽ�Ic�'s���Ds�4<�+��r{��"jB�8^�����skel�����Jz/��`tqD�zO�|q����m�N"�,�8\�[h <;��oϸR-$�C}�}���t������ͦ���E�N�(����g�6?��)>���	vǎ˸�}
�9���n�##2(�Ls������%?��nF�"���$��:˕:�����=��$8�T�oف���9]�B��a�ϕ&�RN����k������'��U�^�_���\��G�!���2]��U��mr���w���)@�a]�w�8�=k�4�A}6q����r��C����Z_�Ws|�]��A��$E6�8!ɟ��p=}6� N%��ϸ�Z�l��8�����ʗ#�[i��
��
��+�Jp�(�\�u�F���e1��ǡ@����ꩉU����q�l��p���3��k&���J�g��J�'�U���38x��a�9�TIV�n������qXvJ-:s��NC1l��\.-m�M��bf�_�?P�Q���3�l&"Ĵ¼A����<�RV*���Ӯy�B�E�=�3B:(����O1��P��j�ݙ1E;֣y�4Q�͜Gv~�c�`�oS��4N�3�l��o=�fX��O���Z��0�#��Q�������9��U�&�)���g\M�!�ԂOGɵ!���P��Pϊ�Kl�S)��ٳ��\�W�,��
�Ac���wQ<�����0��=)%-�ˢ/M��d48H�rP*��&N ��yD/N@�}�Ȣ�i��+�Q� �FZ�i����K^���Z��[�u����L<�$%�_c���~(���w���ps�<����m䋊*�Ж�Wv&ܵ1�HA���4�&�z���ֆ�}&R:���I�|�$S#q���֢_9����1-)Z�7�J�,�?i�^lwP6#�g���ݸ��s���<�{[��p�n�S�h���q�s�D�^}Tm���
|T�Ձ�=;s͚2W����qb�k�܅A	^Q���L��u�r�l��э��]�\�S��ޣ��q�s��q`VX��)hI��.U�CU�0�p���M��O�=�L�ށh��?\#E��^�%���;Я	��6=�A�F��]}��[���W��$�4�k��Lj;��d��˔������YS�I0jܧI�iub%:����Cqԯ�6=1��$���ya�E�|}��ʹO�A١�Ȧo-0�71k��譸�L]�õij�	�a��Ր8�v9�A���w��V��nІ���l�� \����uϞ
@¥�{܉�Q�AA��/���B�����R��l�����\���a�CD�Z�c���)������gԄl��e�-k0oLہ&L��E]�N��.֏"��֦Ib�~Y���oG\B[������q�w�S5�P�
�����I�ݐ�2򇍥
|><�h.��ݯ�k[�mn�������"�n1����\���P�1si��/��̅'׀�!��L�x���u6�.��2��=!o�M�=�Bԍ�hhj:��^�#�(���yrT��`-�Aslɷ�|ʗ�s/�q�x�+�`�K'���cOn����)�_F�H5����YX��+��4�8u�����h��~���Y�3RpZ4;��а�W4s��$bF�	9ϊ�����#����F6� %BBk%Q/~���� �M���ӝ��Ѿ��7B�6����}t��)�g���Ǖ��cK�ݓ+o޵ޖ)ƽٲ��(ףY$���;����|h���H�(,���4�Pb���X��
�~�f�w���\��χ���Uc#�e;�o��ﾓ�6VrQ��^���?��P5�A�u�^���[X,�y\�RD�"��O<��Έ�� �$j=UkM:�N�@�.��L����r~��}W`��]��6�=�͸0���L:խ�%�?ԩ�K"��!Pn�����=�3��M�F�:g*u���Rڵ�<;ʫ�o7���U�����cvtuz�h
b���,㺊hb�a���b�R���d4���=���O7u�Ƚ�4�p�.G�7��㵆6��c���W�E�� �ObW�td\��t0�L�
k��|40�K�m6�J��������2rU���:	<>Rl�	Տ����f_��X-f0��V�N�٪C�Q/���2�j)�{ܨ2�/�";L��܄�kuQH�D��ڗ�W��M�yԳ]+��$͢���0��]���2�1 ��icO!���;��Uj1��
�����s��d�[��7��������k�4Zh���w�(�U��tͶ�̐TE�T9qI�w�5$� <1i:yMI7�\�s�^���K�d�P��հ�+����L!m\���k�U����Bgɔ����G:����{=��OV�6^�ܕs�Od��7��hd�/�k.%��~�Lv�r�_�\�����@a�b���+j��#��#_����Ch>�0��$֧�B�^B5@��N���@m�M5�iT����ĺK�5%'m)�^��5�OF��k�ww+�4Jΰ�Lg�1�U���;�.���!^q�.��($�d��X�vx�}��D!VR�"�*�څ������~�g�5�Ha��Z��P=[[��Z��o]��mb��[��לK�Di&J�����s�W_��ڸH��)��é�ٺ0��1�����HH��[Z��!'�������F�1�{D�&dገlm�a�p ��&��#�>��tu�7�u�ם�?���<bw�'H<m��A	�U��vэ�
�vP�^�z\�E�ތe��5qO`��F�TpW����<�]Y���k�Z^A��+<�Y�i�O�%yE��kY;Bⓐ���Moʵ7����<�r��5{8i'>ōc	qj�@$���-E֐�y���g�k��r{7,��G��\�1e{T׀bY����b���#=`,����	������͜��l=M�WT�8*03�F�w�B�\�ԓ�a��ַ��h�C�$y���'���S ���C�.�[[
088��af#��!�U�R�؆B���_.�� �uL���33��-�{���`���L�������jj�dHR��|��X-��\� �u�e���@�s��[��� F���0'�v��QF�ȃ&x�To5�Xd��w}}��i+W�o8��>-��?p��B0��aR������U'�	෵��M��˭o�AaѸ�w�ǀ5&�ӣOU)YU8ڄ���E���(���C;rc�-����&C�:T��i�cو9?z�X}'���e�U��HW.b��s�������Ӫ�B�wp,0!��$(��}�|����b��[F�ĀE�s�������we:�3r���8qa&E�!�S$4����+���z��:��l�OU���4̐������~��'��C>g|4��:u�gB�����ϠSؾ�cq<f�V�y�z@Π�l�ЏV�T�|���P�����������k��'3z�_tr��I���J(�Gd3U[מ�sA�ꥳ���Cu���e��ZP��c_C���u
{M�*ݩ!����06���F����4do	��>�a<��`&��n� v�����D/��zЫe��9V:f��\,еǿ!bhj��j��T�\�,���&w��������н�>��*|�K�|� �)�#H$~�m�c&5�}��� ��f=�i�`��M���.�s�	A�� %��g�QKwpx��,�<���0��N<�:��j�l,�����
�w+?�9X�����|j����{�j��Æ�+:I&�]��Y&o��C�EƫP���+��$Ե���O��-�Pq�|�~�`����_�΋c�0�6���f�WQ`�2��s��1ܦ�UY�ũ��{��w�^���/YC(�� xa�����;��w�US3�����J��Ĥ7�V�Y^�w���y�mq �;$����� v�%Q�e���9�p�P�{7W�'��o��Wi�S��^!�!P���;�zƣw���܃�ዅ���
�"M���>�Ɇ��ˀ�$�Ko�_��9Q:�7�����6v��*9�)o��3�p�4�F�"&|G-)��%�=0{u)�p>*��D�LT:_��C|�ud{c��#yG���(���^�y�`���#7�p�sA�
��6Q��������dāaֶ�V����@��+�k/���ϵ�L�j�wz�����:Ai�u�f�<_���Tɤ�,凞Q[��L�;8�&MA�`�K?��k�R�� 
Rg�L��Z��_���s��@X��E�^�k�B�X4�� KA���>��=.�>���ϵ��=��� 1?�X\�~��B�� ����i���3S��'���H&4�Dg�\�4t�Z�����f_�$�
'��u����١�S����rh<��Z8OQ"��֟y���C��g��i��#��� El��M�,ͻ�K�N�X��;�B�8�ʤ��|�oߒh��瀅��i�(���]�tc��,�*���hYuZG�B�H3�z��K��a��ɶ.���Wo�f O�I�!	���t���i�S�}�?�sF�j��Ӆ���J	�
�s[��i\vs ���/��@险����T����Wܻenƺ����"j�SQ����o��q~|
v*!�+QT%������G��v��5�8��ų���y�� �y�Ա���ֽ�A���P�24zQv�9��}�&d�y@����nª	���D�5���� �$��y�FrH�*c߬r���'�y);=�B�#����8��`<��E��g�tl#�g���s��|�@?\����  �$f���xa�$"cW��j3�f��>����ڤ^8�8<�C�jrg���t62{��̲��*���΂z%3�� aU}b�=�kN����}��\�MP���\bAb�a��*���hA�5��Ɣ��� ��^�T+�k�wcvj�]�� Ώ�����n?\7W���l0������W�],�S�3tC�7����wQ��������������Уo�^�t�D�-�]��u;�_�'c��	���;@؜$�
�R�R�̢���Hm�߆���Q�V�m�G�-���g@��u	o�����Zy^R�q������*?�9�-��D�`-L���N�{��2
����H��y9���Ϯ��O���,�Ո�Ǘ�\}���=t�0��T�w&�
D��#������B�r��]
����g�Cʧ%�"��|�)�āg��%	 cwϧ��ͺ�� ���2'�z�z>Y��>�@�mYo s܁�iCА�}Qle����4{j�[6t�U��16ʈ�ц6�u�m{a�7n� �Z��+~G��O�H�n\�ì������O������GL]��NF�Ѝ���Pn)m�RxK�ͺ�eo!�z��aŰ��̡�I�D�����n�eC���%��5�o�e����|��ȸ�:x�TLp��]&r��p>�^�M��-^�C��x��{Q�k�
`�?����[}��t2�/��extj'�B��P��}f��������p��Bo�ʴ��\tVؿ3����9dO@�cX	qה���RX�nX�8b�������w3��<����憖d�j�nq�^�4�磣��Φ��Dv��B�?����EP�yjW��b8lϹ0�%���Q�H���-���I{��g"�~��K��Xu@IH���\�y.=}�g5���d�>\�$�n�x!DF�,J��5�6�C�뗥3���	9�*M�E�ؖn�1CG�
w ���~{J_����Z���$FЮ,u�cؕ��
�U��#����K�q�b
.扑i��q�I��1*��λޅ�Y��f]�`���]ߝ�v����࿽��Z4��@��^	@�� �W�J�wͅ���c��!���_ ���S4��Hj�x�]c�:q�ϡ�Z)�����=�U�����HGY�?Ջ^.M*ۺ	W����y)�@_zTR_���oN{�C�Ɔ7�)��qAS�f����T~$�Í|,��< l��b[h�u�-���*�;��}��>�D�����Æhn�x��:�Qk�$����H��*�Z=D����v���i^q�kś%��s�C	��f�IW�GQ	$@&${5��{B1��84�hb�����L)Ԥ�p/?���ഇ)�?��h�.�s�;���⭱���7>\q�fQ�:���57WWlI����@Ǯ78�7.�`���߬�����=h�J��k�������f[�����<�>Wί�;"	)�՛��3i����>��G�4܆
���Yם.M�����91��m�����5�{�Z@`�m6�y��O�EU�7^@�dUJ�z�֯W�1-tK��޽�G̓��3u"��!�6�[���@�4�_*�����H�'�Ϫ!�Я�DD��%oL��^��g	pgIZ�A���8�§�5���D�h՜�*��h�73�_�dp���KXqt�/J��GЦ�E����3��[A}��3[/��9.���������z�d�Fj���gHQ�e�gu;�@�kf3� ����z	�4e�l�]����g�i��C�S��`�֍�s�n��.
c��9o&yPN	"��T|��a�R��������ZBu*F1ay��iR������J���H9	�n&0b;!�k������ϼ�u�dZ�a�a�5���n����	���T�l��vh�fռ�Ѕv({!Fx5ͩ�t����&�	�iuk*Aq4��WR���,����1��>l�=��Y�E��p��������d�{Τ��@��n�}(�sp��)P��@�dk.�n��7�#���o�{�{Đ�)7��oYo��9;ZPݖ���ބ�Vk@��u�` k��ᑏoc<5D
�W+V�$�,����`�×%[?3 �:B�S����+��2��=���	�M@�-�#���Yږ��;��Av�,�1x�N��*o���}C�Z�H�z�M3��1�)L%p>���1�lѢj{D��"�oX;<`.7�Af�0�w��PL�����ah�]��K^H��W�k�/�m#��	p
�1���8K��8���W�rêP5	�$��V߈�b4���ew0�\塓�ݍ��*�#TۘT߂}[��"�e ��Qj��G������&p����m��'B��C��a�ٴ���z�k:�s���A,R�����|`��,\�Jk���F�ޯm�E��R�L0L�o��>�7ߣ��=��M^X*�qfN���g�	���@��N�Z���Nɭ��)���P�,� �Uz"��7�~�-TU��XIR�sf��:����:<6�';�P��r�(��o���Em��pv{������E�"!���g����R��iY;��C�܁��&�@�MXP�q),������u��`R~�7��c�h(0AY2kh��������>xlGFd��_4B���1[>��p�Z~�^%eg��R�@6rQD�����K�D}T"甠5�����-��\,T��?����9�15�I�!��f���H�1��� �j�R�DЗ�C-��)�&N��'k�.�`�wo�$$(��ˈ+
���:3P�Z�<��IyMB�vOqp��P���`���9(�#}����V)�LD)�'�4��댒��I����]�Y|�H�O��xw���~��U(�WR����&x`z�� �[�'����]��Wߡu�E��%��Y"�3o�Z����MAp~'��yH��'�q���[D"�Nu0�LA�h�T�>�Wl�>+��J��FG:��t�jQՠ
Ye���QKxm.���d���V$�>Y��N�Z��I0��<5@2+�3�#�R=L0P=un/*�`̂Ηo�x˯�z%�����?��'�Z]JgN�ܺ��'�9��D�81�'�{�U�|�B��H4Wynmtp����#����)a�X|�~�O�qPj�o��J"dL�Nh�և�`Ju7I���f�P�Ҷ$䃤��X�1���_G��ۀ?)Ib����r��+��9NLP�uؕ�E]]�I���0�x0���d�K^�]��P����]��
�z!��t緌l��?+����(40#" ��DK�?���L��ܼ;u86��i��dL��0шc�n��X�����:qڝM���Ҩi���e'F� ���ɒ��<l_�r��'����y�c�&�5���`Iv�UEX��wt�nyF���=��G|���;��?���B�������j�ߜ���~X'�[�h��O�o?^
2m+����9`��z���Gb9�j�C{�|	 ��ЮcIy�7���RP�/�� �6�X |B:.�s��� Z{%����J7�V�Ұ����i���H��g�<�Ww���h����~f�� ����uhk���	����7�����؃wM!z�G�o�t�VB��?��l�WH8�ʬZA7�d�f�p��b2��z��>��A���H��X�4�4YZ��"4��k���t���/����4s���0d���P�T�i�o�B�~-̏��6�S��6+��\������~���bQ�g �[q��Ye�����[�������gIe�|�e ��*�Xq�Q"x5b�E��E'�b�;�	cHy�HY�����~ZmS�:���=7Vh���[���}xɈG�T\���x��<[P^X�~la����e4��3,x�IUϏ���A�������=���xzoĜ� *�\�Y����Nd���ۇ+{$�SUM珐��gsP���9b���$�x�=�4�j�B5�"*�s��7����̈���i�c!��A�����y��/#W�/A��Wc���)�l�c�T���7G��)u��@4�eq0�Q��C��ɖG�yY���z�����=l����	B b��)�g��ځ�B���x�A�B��lA����*2���)�C����ͫ��̄�KMj*�n�v���Ϗ'�}�m$)�
�V�h/�sqa�6�s���b����!�G��5~@ߖ�@�Y	����8p��g����IV���!d��C���k���*j�0�����\|�)[�Q�_p��V0P����;���if}��1�vo�����i���MJ�Mx{�G�UA!��5~�c�k>skn-�������
����ө=M�,v[#4�+�_�epQ(qb��BǷ%��A|)f�q �4,���W���Ħ�_�e�U9板[]���ςFn�j���0����<)�@#��0j1����� ��X�Ҳ��1w��M�Y1���C�&��^�iw�ַ�����;fNТ�s���<i�)�L�0@c^-=Ʃ<��׶���H��4�=�$���
���1���9O�I#H�!D	]�r�ߑ�Z���:;P�ͨ\(���_���ɧ���C�w�c����u�� �u���{�3�T����fl��W���x���Mw�n�O�,�d�-��a���W�����ou��@����� /} �?2�ٺ�0����'���r�t^�Β�&�%�g'2�Q��[<�'P~Q~��O���ug�Z�w�܏�Ү�޻���(�B�����U$���gQ�Tу�iТE��c����Pi�٢��E�#'��*��T&���ؔY�6Y���v�]Bj��#�XL��l��_�%���ت��Ȭ��{�R`�	T��D�I���+��8y��D-��I%v���S���b~�f헕M|)���Ԑp���`�L���)Ƴ\,.L/a���y�3� �Mº%N�Zj��Rv��|����7ܵ�.qǹ��R�'d�}wc���f7��$(S��-U8ɰ���G��C�[7���g��Ͳ�<���=�|�����\�p���(aA��X�!k+E���@q?���|&>\�Zh����������%��9�b_w�_��X
�J=qA�<i�{o��q�[�lY�l�/A���8�;����-F�	�c���J�!!8�Uh�0��<uV/��G	��x ��c�!����������cԱ�:g���1�a({�I�!/S�y��7�Wm!�3g��2J�<��n��}�#�'�Ǻ��u$�7�?/�����6=���7��+�x!�p�`�S�p�g���̺���Gm����0�����>$�E���nRL4"D7 �f��	��U�d�=�]����4���G��5W��:��s��*�����v�	 ��4���?�����)'=H��
�<� 6ZCه�P�����b�Ŵa�Թ�/1,a��	��x��5��R������祠��%������������
(�l)|F�>B�_�;�G{\��ک�΢F�)�"T!S�_�t@�*�*(��.�QW�����q+	08뷓Wm ��,�(� ǵ6�%0���.�(Ⱥ����(�L�θ܊�i:�E�Q?��D����
��	ݾ�mC��߉���:��OO���s�"_�Ͽg���U�� k�,�g�?��0m����|���	t Mj�G���x
C�fv�v"X��Pތ��Xl	�êk"E��Jn�0�J9�����W��������=P&�
3IݢN0-��oWV#���\����Nqƪ`�A����t��oT�K��eԁ��#a�0�$H�V��+K-�u�)��KW��ݮ�\� �QE�_� 7k}������w��&��r�#L��[bÔ�q�#oG�c�?l�@{J�G�w[Z�R�g�Y�ӣv{���>@�ő�90<��_�Zg��3o��g�fi!��3N�*�����<M�K�(��߲|���E���� o�6/+���y�m2�Q^gP��[�D���[
)��0�e�� �3��,�`�;���B�����e����LQ7n.�o�Q'w'g���+�z��Т��?��a�=��rt=*+�S\n �s��ʢAp�(.���H���o1<�����z�7`g[{�6i�D�?�@�y=B����P�e�2�97�q[�����yY3$�6
���3�Djp�� "/��UF�|�#���IG���>�mr��i���3a_7On;2���[#U��a#�z���drV"l�%u���ݺH��1��e��ҍ�)�����H�>��5��L��4���I���uH݈A�.p���m⢠�/�����N��n��k0Ѣ֚�_�T|t�D$���V���VWg�|�����q$���kK�!� )Wq�Q5d�O+�Q�nM:��)B?��k���3z�W
�P��6Ņ�)7�������5\
�/�e����4�s�a�9�`��u��`�k~
\���� f��I5��BZt��[{|����d��+��j����uoiD�I��}�Ų�YZ_�mⱑ��i�į~)�&�
s� �h��R���N�Z'���0�z\�X���+�h2�2��T���IGơ'���}�ܿ2-rzR�W�V�o��%-rH��ij�հԟua�,�.π�|���?��J�Dx��ӄ����|s��t�ޏ��bώ����v �+Tfv [z(�(���4��G�0.�k�C� �9��VT|����$�F���$%�K�>6�l��nwPp�ȣ�ﶵ���n50�Z�|=3a��u�!aD$�)��D����b��!PҀ"��r��ZV2�!"JF�$Z��?�������o�ʾ@p��`^Y}nH�Q�_pQhN��,��𗋨�ZO�*��-�o�pK���>�s��� �M�4~|��b��2������{���oF����,q�%z��k����88�	��@��燄��ǟ;��b�0 �99[�Ƽ}�0�h�K�#E�Giό�+id���\�b̷�㶇
�.G�ʩ�a���eqT� ��A�� �A��4H[�K\�RRRr�`��U��c�����pǙ��*���\sG���&�����ʮ,ӻ��bo?��:�_��q����6���k�-����*� 0{a� wü��%����_�V[`���5����L;��S��;��7T�-�;*����C)�Cq��+$ ۏ#*ڷM��&�kL�Y0\��6�2Vs�����:�̥IL�����+��\"�[�t����K��)w)LzʋnZi�����Q�\�~]����3���/�ۆ�1%T�:>-c]3�Of�[(~׳�.HC��_%-n��T��$�Ze���g1��h�nnq4O�&��>�����30p� |{���^����P�9��@%{5��rմ}�&R�u}:���b\��3�-a��z���c|�DW�6�p���8�U��e�;o���p@b~�Օ�Q�����1�W�.V�S�f_�g�5�� �/��r��R@M��4f��i�m��1��M>t�4����ߒ�[��>�d5i���c��H+�Y�!�Ť�d�"�p�!����WCصo�w�όNh7s��7��|��~�s��Ynk(��ä)��FT:�h�!�n��7�E4��8�9S%�&!"�D�Α�X�b��V�M��s-�M|�\����,V�4�������u�7�,��R����Q��;��­�{łw����+Iq��H��$j��/�1���hT9/L�SZBm��  ,�s4뿿. ����}���g�    YZ