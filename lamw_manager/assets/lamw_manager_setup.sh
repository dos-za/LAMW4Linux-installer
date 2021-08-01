#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2027396103"
MD5="0d29acdcf118dc431643bd480cf035c0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23400"
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
	echo Date of packaging: Sun Aug  1 03:28:35 -03 2021
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
�7zXZ  �ִF !   �X����[%] �}��1Dd]����P�t�D��fy�B0��%�ˠ�㋱
-y���z;��dO�i�C��1j8lZ ���k6_��@K!�=JP@F0�G�U�����Ȟ	&F����%�$�*�[u�beyr��aZv?G@�رN���4# n����^J?��5;�����K��:
3��=�H��
o�G�kw���t�$����FO��q����
�	�:����_	i+*��i�qpp�6='䓂K��;;+�
_����W�p��?7��<��L^�oq�KX�3�!)��$)ٻ݋�\1&�YöVS�;�!�v8E��n<���F���b}{��E�߿2����ۭLoŗbdŉ�!���0C�_f���˰8�������Ń��ɶ�DY-�`�-D!�T^S.�Ⱥ��鮾6L,���2ٺ��(��u!љS]����_n�O]9�U]����V�%�T2��ئ�LQ�6��<�FN��7(���T�.O�����8v�>G��(�svm��엠U���[GJ�5��-+=8��C��a�����z(bYS�@�s�1��I�^=j_Rf�V�%G�.��nt��L���aE@i�HI(�e��U��U\m��������Es��#�Q��b���qV�Pݓ�=�]7,T�6G����=����!t���ge��<A+$<� *)	%i���ܫ��/���eϦ�E�Nm���ӿ-���5��	#^����N	�r�Ʒ�U��³/5D��v�M3�p�@���X{�!�R(��b��;I�b� ɨU���g X���Y�?���Ȩ���Qyw��l�9La���\$-��p,�p'�w�+���!��4�E!���H����g�Y9,Ҍ�d��p�~}��y)�����y*�&<�L��(�6����c)��B6�/�I8!�ZԿG�3���uo1�M���W)FY���g��j����W�,�݆-�Ih��%4��-z��
�X�UhM��5��j�.m��,Dr�h�h ��U��ߵ��\2����8X{F<U�Іi6yl|�{�rC�����-Z�e��Ο�h}�Sd��|��PG!J?�qq���PѦyչN?���p�F�GO��in5�%�>¾�꼼��^G���V�T��9n6��&8�·�6�Ae�������]>���v��'=�Y�<&��dr�N��O�p����!4�`���>;� �R��c�kI3ЩN��g@���Ϻ����d�1߮�(߱=��� �!��<>�
��,�1o��kB�ν�����+y$��p�Gr�a�ɹ-�����Rm���+��ܞi�)��m;�α��pI�;��SD67M�2œ�u������~��	�2i��G�Fl{��F���(g�8�U��� ���W_�0x���\���$eVu��Z���J;&;�ˈa��|���Q��3M��/�f!{��W������^����ؘ���I���$_�������3�E �s�k����>�Q�� ���k�EW&ã��ʤ�'_� �]�4%��~�ɴ4�76��Hj0�$�M��{�<2��Ce�w�.P��a�!�t��o�l���fk)������.�&���Ag��ҡ�!�X:��y��:C�)�x���XG��.�n�v��:{*�U+W�=��֭PO��5	��!�L���6������l�C������+��m�*���DB��$�?�Y��6��.Z��ʅX2v��Hߣ@!�w
�U`=~��+J�����x�O�d��@kvW:��!㽌W�u�I	}'5ƫ�3*�p�q���6n���^=����`�JW��y�!r���
�^f���lv���U�P�����aĉ4��M9a7�=���R$�����#�����r��`\c�%���⯉������Γ^�i.�$Z�w������F��ON&:��Ho��l�mUon�g��OjM���IqOώ���<����\��#b�9[	�̦������ܵq�Ϳ��d�{��6������S	�Z��˸|�I?�K D���I?O�񯫬1�vT9GH�~Zue��ӢF��ڪ�L�r/V8�O��;P����t\��D a�NK�W2aF��Q��va)�CG}+DUQ���3����޳��;}[� #�L�l�̐����-(�KR(a1��?D��|	�N��]���%d��*��i�rV�!7"�I�ܱ�Ɍ�DP��'.��&'���/�.e/�Kn�Lc\�J�QkS��B�a͗����Fi��||�f�������]j�K#"�R�c0v��`�z�ƪS�M��6�0c���M��:�մ��E<�a���iZ� i��U���,�Jcn��B؏�`Q�Q׉�y,?Yk&J�k!��k�j��i�%H��j�>a4���J�}\�ٌ�ϭr�-A���0��sJ��&�(�K��-�a�t-NvO%��[������U����;h|�Q{�����!m�]^�x4c��B�����s!<K���>�@r� woG����O4*��L���Ȳ �V�7�.c�1b������6��4�F%1��o�3� �����2ՠM!�̯Q��`�;EV���L~�)q0�@e��?�+SV�/��Ɓ6��M8��<����iCM���Cf���;	T�1�_�Y��֣l�M<�
����qʺ=>Q�^���Ӕ�iq�����f��/
�O�T �l>��6�V��g���*cs���!����ٱr(5y�9���"�ŷu��om���%�+����u��%����ԓ�W/_]D�xE:�k� �q�|�f��z��VY���,��bY�Be��S4+�̪V;_T�g��D�nS�EH��|v�g�d�c/��݉�����T�T�N����xS?��:`��Xı��ά�'eV�Cm��^���%^�h�*�~F<��/j��")̎*c_\���z�p��z_��|�˯|d�V�1ɴ_G���P�|�+߬͢�x��L�4�i������CϹ�s�C���P����&� u�N*�'������z��UL��.��Z�	qu�^�\r����s@.K����{X�H�I-��@��Ga�����EZ�?)� s�F��đۉ� Q

$/�ܙ��8�&�w��(����8�"O�b�CD��C�<U�6.�)/�i����}&��rԪ��ڙZ�������S����6;)�g�t
��V��*�7�O�����EnkV��(��.��!9�yt��XQ'�b�T+Q�ܜ39 ��}��|N�n6v�6&�� ����������Ը^��,k�)f ?�X�:Z�Zem\��ث���̨,�W9�+F��F,0_����&VF�1f�2��9]��g�S����EӃ�c�������e_�pR�t���B��VGoXQ�1�'dp�N��$F!�l��0'�>����%
��\��	�����R���5Q4����<�*��|NDx%�x��;�;�<^�q+p��f]�=�����o�d<l��4����Xz�<�u���ホJ���3:[BZ���V��9y��v����nOqM-De�x��Qinu�b��k" ��!6jb~_C�9��BJ�o-&pO}�N�'���\�3Yd�숯x�uby�B.���b�"�+���j�|��(y�ro��u�]@���ձԿmd�N3��I�;q�)3����8���oeG'�OX�K^��r����ߘ��f�r3s�!�����L�� h����U8�
�*��R�w�n���4ٿS��ok�m����(Ϝƛ%���~��z���(l����F������lW9d,���`�e�>�z��iq�m�U�����"�v|���#cb@��Mw���5=�<�8�4��f\�LDp��izG�D�^���UQf��o��똸�D�	"�f��`����$�nM��k�q���&�˘���s����Dc^�0�5r�ti���G����	O`Q.�?}`�Xmj�yV��1.�����=迨<�s.����r#�\��.�	Ҋ�dZ�z�Nd��2&�5�"��u��()Y�*�/t�|���}�#'Y��ա��c�D��/>$�s�p6w�0���P@����g�t,\i|p�ւ��K�fÔ�j�c&6Sd�F�'f+�z��נ�˥P��7�H\"� ������5�n#n�1t~t���'Î�(^��7r���+�C�L�̫?#��O�
"�������t=�FQ��㎮��vр��K(�����!�˄+��]�������&
t��%v���P,T3���{n_�S|G�4d�k�o>8�?�������}Cb�(�l��$��Ufإ�C-�楪)��s|�a�-�͠���׮�YQ���LHu� n�іS�o^ɬ�i2���p�$O�b������+SFq����
��m�- 
<A�'�%f����*ʶ��\��,�Jr�W�oV�/���� ���~�P�W �5���o�HCbR�8��	e��
�fڳ�]��K);+��n����L�?j ���"#��\EҧN]v0��6D<-�m8_"��mh}�#��h�MM����3Ο�^��?�GIy�-�X�t�͵Լ�o�AA�ܲ��D�g�w�Yv��0�B��f� #	j��yx��%�29��G�tE:����yg.ރ#�3[%Vp��虺}�f�r�M��zA�������4�JR]��;z��<J���<�=�k�e�����bn?�?:zrG�̙[���x�0�Nw��w�}sƒ����{YV��!�շ�a�uϣl������w��n�������hKG�����#�J������(;�f�s�~��m�0_��J��Bիf�|�z!�Ω�S�������sԖ&�PN�E����w|�m�C+�=��6�)c�P�!-���Ϸ�r��'�q���Z�>�c���e]�h�"��-��aysN�|�H|�OT
�D ?����*�`���l��Iyc�Iӧ���g�ٵ����8>�J5�+Q�*[��zI5V,�ȯ+_�9:B������T�l��8�_��S��O0̀���"0R���7Y系�[6_�{8�=E�GVy�`��q(K��6�~������O�K�ѷ����l��C�Lo'ٳ�#� ��(ѡ������(��<�_��]��#P�6����I��Hͻ�$�N[2}ii�HJ�������!� PDUG�ʗ-����dv7���u���1��,��:�5�w�)�s�'m��$��/ɎR�n�����2'�Hm�,��6����V��I���̥�tv���Q������j�����B�6$48��sX�>g&�J�D�G:;�Og���&�S�وeq�!]+�I��x��ܝr���AO���(&�Yڗ�6y�'-O�s3$i2b����u���ęxr��%~ɣCT�[�mfJ��yw�77d�@9����I�W�7���W#Uz�W�r
ЖrЈ`X�x�x��NYX����엎9�Nѭv�tp�0����2^�oF'=�]d�e�,�'؊
<2�xN��r�����ɑ��%��ź'c�#���l�+���E�#�n��m�����6��|�\{E����4t�2�d�V���]P���H���Q�x���{w���	�,�ֱ�Qo��;�����7��M$��=ҹS���J�2��K��茳kS��up�#�e�{3]��8N�H�������+[�)�����Ax�I��2@�b�;ѝ���!Ԡ��$� �,i��b`�_��9���us񠁱y��j7G�*��7�8�H�jd���0$�Nي���f��ˮ�PW��,D%�[���:��R�&��T��qT+���yhxWP'�ȳ� hp3-�鑣E�c��K�6f�/:��4��RA�@+�jP� ��Çj�y"ѱT�뎙tm���5�2r�Y�bv>���\U載D��s�.W�R4�Y����Y���ri����	��TuA5c�0e:=�y�`)'j����;씶�a���ˉ�/T4��۶zI'��'��m�b� �݅^��I���gwm�0�Rl_<C	�ְ��Q��4��±�����X�ܴ���)fg�}��K��̣�'� �ƚ��зp��FoKI���}�#C,nճ3��r)�9�&���!��j�7��<�^�e�{ѫ�9*�;Ԛ�/um��(��"v.�rc���Z����B<<����y4��<T!��$�w�5e\ipu�f~���	��k�� 9�B����'��F"��Ub[
�ǹי\��5x�	�qE�Yz��y����C�`�c�\��V���d��}򻯹��y��Bė��Ja�R��[��3ڐ�R��t&Vf����sӟ�H6�wO"����x�-�lWTo�ӈ�Y�L08�,����z�[�z�G��u���\�B3JX�

B�tgw7�v�+~�Y{%�.�P�Qv����,���c��ax"�Dg����a�q9<��iM8 ��:�
��yb��^��ε؏�u��[l%�9���g���ηx��@.���ȸ�6�חJ��T�v�%z�s%q� P�-u&���5_xg��+�2�`E��i��JA��N��z.�*����A�2�5/��EK_�_���[o��'��i��r���f">A�q���G�U0m����)�ĭ���.�U )�XD{��
q�l�K���Y��� k�|~+�ö�pWIYM����'�-1���¿��t����,04�h�4Uq`$T�K�e���5�������2B�J�99��4"7�����jpb�ol�x���o�c7�O�"V׻t'��Rt�*��'�Ũ� �z�f���Q�iߪxux��Ϥ�p*Cv��-|����Z�u�:{����L�p' "Szw/���0�M�/�$y��	�i{�u�Z
�:�\��*�����g��?a�ή�o)ת�D���(��� �%��^�.�g�sP��rFD�w�~V.��	Om}<B��I�Κ��F;�<  ���j_��msm�!�'�L��6��t5�T6�����h�<;�w��\k�x'�����"��Е\j�Hx�k�D�x�ei�1!GNs2d��ǫ�V��q��İ��"��_��*�d�6�i��sDfC�M��49/���l�߭0T�e�l�s��c�_�:�C���K��)BizU!��U
m4�Y��Q�W8�DK���c�35�r
����f����e*����S� %�Uw�l�?����c��i��ka���Q���%Ϲ�����Lw2�$*�~B1��~ R��^����f40Mٻ`�Q%�=˒-���U���<ܯC���`�4��_�+l?��*z�a��q����ڽ{�~$��-u6��e#���߅B��M��4DK�,�p�:!�' s���fR�i�6w��m��<���y� �u+�w�+����:=����d�^�� ��ӗpʯ#��:�\�X�NL�f�6�����'y�02I����\J4�bn@�]�pwh#���a%X�B��7���B��k��f���ƎtZu�~/�DE,3�eM�'PL/��?<����Ķp�96 {���6�"��;�J����Q�~��׹�O�`����h¸�/ɺKG��E\0 շ��qT�ɴ��h*7m:{%���kS@K��nI.]�d�]�DH �^���oTt�k���5g�6I��9��vc����H/j�;k/�Tv���5V>a-  k*ɍ3�lxIm�J.hXt�����}���b����|��z���k{-v��y0k���?� !�f��hFM2v���t�q:o{o��`���'>#bq���C�"��V�wݺU:N�h�Dsg0sWsݪ�ψ6��$~/��D�=�:b/r��R����+��W��s�xy�PѺn� ��������2��6K���ލC��A�ܙ��c�F}�AP�^;�\~<� M����� �)�K)�1[��@;��k�CZ��ȱ8�Y����������PNz�S�y���'�������v��L�j�Jɽ�3��d��:�m�@-yK2�1)Ooc�D�=$�-�JI�
a�����["��+禡ن���Lr��$;)���)��I��|��h�V2��9�=:�'(�u��ɜq[���)��v���8A��l*A-3�9��$lhJ��ҩ�G ;�޴���f��Xԝd�p�y=�s��rX��;�G`�C��+��^Dx��E+ۿ�RK�֟�UU���K��;��$So:(K�*)���,�4O_�.��e�
+�⌎R�
Vd�X!˛�Y���w�"(n|>������e1�(�@��m~P(|m�h��'׻������6�|�-��O��Z/���(RĞ�FT��;�#��0-�������l\)Ju��%&��-&�G��r���oC��%�}������״tT���`��y4�Y��#���� O����~�!m+Îttv�z����3EᾎLś��E�5v#�]��䋯�p�5M���f�k��(Ϥ���Љ��W����I³��:g�6���-�GJ5 ��~��Z�`+x��w3�{��o���~�h�:�k���
Z���΢��6��ti���-��q�ƙe)���c3�Z�!E�c�����e2�S}�Y��:��fQLN���;FQ�]QY��]%m�",��!�n/9kpZ#�n�M�ȷ�2�m%&nŞ�]�k�]v��;��#i8�÷ � ��=?hA�C��o�c��1�M�\?��_'�2U�	aj��. �E�䌹�*�cep���β0�e4r��es��	0� Ɲ�<�c��Uy�������j�m&;�W4or�oB�2�E�q��Q1���9!�@4,�x��{I*�9�
�_�����;�+5�c弳��#W���gQ[882����m�.Ž%K���r:	�V��ҙQ �O5��"��i�U�ҊF�W��pНEݠ˚*��Aܗ�/
�ٜ҇_��*�~}��@:׏�Ǘ�<�fy�f�Fn��zZd|x�W� �q^/�vN�1|���J���>0a� %������X�y�a2Z�Ps :��6�Fc�ro"tR]�`��`����v~�����E��>���;#dٛ��yH�s�ך?�$����?]T\�D�㼐�����IbԞ�gG� �����v�{�!�`���4\���G�<f����c^�Ӌ����M�,�Ҵ��}~(|�m��k�g��<�]\R��T`�����\�$�J��w�NM�}ic�t�/�m��!���ٞ,�4�	_XSt�lR�l?�vB}��`�L�+M=dz":) �%'��x.���c�����1 �F�����!��>f5z[M�������O.O����{�GŘ�G!%�}����H:�/��w3�-a���#&�D)>t�u-�]Z�����$4x��=jtLf�R��Z�B��}�����#�$fn��'�)�SA����W ٤p��F	%2�U�E�Sfli��L1c%O�r��M�#��x���:��4}y�P������N�Z{��׶P�Q�(�r5"�5�Y���b��P�~���%���Q�B�n2D* k%ܟ���O�b�>�iJ��3^*6"3��Q�t���$p�RP|���t�7����!�����A�!}#�6b.c���� �V9Аc%��ms<��_1
�E|����y½#��hU�E�>;�1�ݣ�w ��z8adU�ޢ]_vk*��s�����\���'�ܦ�-��E�
�>J�?�	�贕�5�*�I��~T�x�:��>��~����?�c$����7J��~nH8	r�`J���qPZ��B�v�:Uؚ+���œϵO?t�ۆۏNIn�%��`�( k2Y�w� ��t���m�ڼ+��Z?�7P�r�W̙�-��.Wc�!��D���k�K��/��C�.W���$��(t��v5p��&�3��Z/�2*s����}(h�ح�R��b��"*���&�B�NmUԿq�eR�_�����\���.��"�6�-QfXTv�ڡ����	�ы�h���+�Q�{>���-YKk��f12����oz0ze��ZRS��_jZ���y}�lh������&��UѪ����?	�����
�9�c�ʴF/1@�P{!~hh�6�=T�a*����L[�%6��yU�=%��lD���OOp.�U/+��-�D�~�JwB�����@q���?k@�i�SU��s��u6�Pt�3�X�3��K�桟v7cK���7����ɔ �f�+�lA�������X�X�*|�9m�T�^�'¼A��inz6ci�ӯ�8]!��[h��6"�>�/ss�v3���_Uj��a�D��i1i;|f0G�mI������X�.TU�@& ���I�5)UTuڝ�43/��6��J�T~/�6��	�
�.F�Z+5ZI��'�ے�W/:3�e�V���!k�4G~��e�}�]gpgs;��Γ�e<��2�e��4*מ^ž��OuB_��U��V�d������M{N�]�q(�lC��^�p�6^�Et���yq����yZ���v僿��];�����*�Ñ$��TB 2O�Ռʤǥ�gv{i!U1�o�ͧB"$�(|M0}(��@�����n��<`�+�4@�@�|��b�����~1k�G���+i>�A,%^W�'կt+��4�6��G9W���Y�Rk��l�'�ï�f��s=kЦVJ9����$��k��C1��4aO�?HdPk��Ez�	]���p(]��]��$���n���ޜ�$j�HϵdC�᪰�,�?j��Kr?�{OOz'.�����^��,6]b0�y���7���1}�
Y�z��k,h�h@�����bm�[�B�a��D� ��O}F��`��<�~�"�okW�����nW����L��c_�~������uq����:�r�9����C��:X9Q�"�+R;���wRM�C�Bh��̻�鋟��١nʹ��P,X��n�9��[��I�@����=1��d�����:,�-0�ɋ�G�_�߽�'�䤡Q���7;��j��BU�d2�nk7q����1�	zI�:]��2�0�������A�~�E0��݀�*rh׶��C�Jb�*?k�F��'���i��)����Z�����[j�` M���:�*wF�f�e**���Bk>Y���J��Y�~�jif�Ԇ �mz���m���w6� ��+|ތyv$���|y��5w�D����0%D��/���]2�һ�v��Ud��RK�e_)��;ĺ��k9�lT+�>8�mYq](����I֨���(�R� ���V�f���*��_T�.�/t�ݵ\�i���P|n�pH�f�4�G���J?\�zr��?��Е.�%���y���ޯ �S+ ���e�+i	n󰨬��*@x��E���A��`��J�:��N	D>�x$;'-�\�4A���� �\9T��Q��>� ���fwR��O��K*�]F�>�
7+�R�"��"Qmwd� �ͤ�Wu�f��W~޴a�A�S����1W����jn���d�(��X����Lmm�@̿�z�!&9i��Ҵ��)��z��Ń������;�8=�j7�b'�I�_�m-�0����|��$
�úyB/J��L�g���C<a�If�).H�a�ԣ-d��x��9��)��Қ$$
�����@G��҅!/�/5����{���3�����Z)�R,�����m�K�:6��@ �Y��;[�c�s ���++��̞f!�Ċ��f��qz( �Az�����[�Q3�NTIo���ݸ�B��@(�b�--O9�G��P	7��޶{�����R�����_w^��D�P~�u��Ca����&��;A����H�v�ϊ��]f"�#�l����hf���s��+ƯYa�Β��͋�l��ݼ��í��my���Xrǅ!�%s�f و��2N��	�����蹄�kz�����+*=^���QGtr,�cK}�G\Y5,oq|��>M"C0�ip��t[�5D)�oN�	�R4ظ%D7�*ű�,p�]�hO������\��b.�����Pdq�]��q�$��߻pxF!���������G��YH`�3bL�F/�R�]�wH���)sX0��5
s�m���98恜t��S�e��^��ϻ�����ȓ�O�`w+l��V�p�d�N���7������=��.S=I"�LNZ�Xfi�9u.�~�V�M�[�EצQi���!��[��>�owkNG�#*��0��+H<
hؠ��x�I�ዪ�V�X�hu��lY���u,�=�����|��A���(��]���s��) =*�^��U�z���,@?u��㽾����i&j�LE�ѽA�M���-�Or���]Q{�VD�	%��PX,��v|C�w��I�/��B�Ο��-�Y�~���F�O�Jں��������>�u���YԄ ��hI�֏\�����<�6��<� m����.,͙����[/�uu�?�ne̺C�y��]�S�"" _���^0��	��4�̆9>'2����\��o!t����X�cG,�b��0k�_:aSt#p��1z��Vn]���`F��&��"I��P��r���8�����y���L��z%��'V��D�4w�K�b�||�ؚaҷm$i�:�Bl�è����ꆄJ��ph�Vz��9)%�^��*��A�A���ϟ�Pe����%u��m�#������l�W�u�1�U�QX]/Hl������!OJ>z,iN�kU���˸P��[�\l��i)��G��y�Du5�;����_�C�*�7��B� Zm��u���6!����&"�ư)��$s�D��"S^�;P�Ɓ��-���Ww`��1r�:�,��-��\�4�#O<n�!�ฐh�qR{��8�ȵmh���W\��.ƪ�9����_�Е<�SdQ�C�� �������!ʎ`���69����X�kZ���m�������,s}B�.m
�Ƃ�ɽ�8Lޕ�8�F�/"Շ�d�|��!������\��2�û�d~>U������e�J�#�ެ,�����y�8J@�ӿ�ƴ|��1������d|�����H㲭2I��0�����v��$��'>�j��r��k6#L%�6'��	_
Ն-aֽ�nO������������,�Fѓ�`�Z�3�QZ�K�����/s����,�e&A_�Z�Ŵ\���3����?S}ӜKxT]�i�V�`E��Y�V7U/��M���1ym�F�Ex�ϐ-�/���9�.@��	Ѱk��>��2���Fe�5�~%{��=#���'\�@,C����t?��T��OK78~��y�2��=+�`�c������2K77�$�]ֲz�G��y��Y� �w�����87n�u����B�b�p�U>�xՒ=58�)�V��4�l��z���oᚁ�q�^�k��'����5\`�}��<Rv�L��	�X�O�p�j/_�����;f*���F����g�x�����1a�$I3����_�u�c;�`�MOT(�'���U���Y�C,L��'����`R,��;�k?2X���RpIVoo�@���Fn�Гz8����U� �@>�*�iC���W*�7��y�a�
���`�����j���tr/}��V���7/r�.�iyٳ�L)&P��[�|�,�<8�W����H�5I
��6G�^�C�S(���X!N������j���ͫ�(!xr�dX~z��̏�%�*�����e��n�+�����V���&^�kkM�)�L2塈,�_5hc�)|����h�t�MV��+�'��-,1�IN��.<��<�B�fR]�����8̜�NYyf�t��
D�b�g^��%Ѐ����3F���Y�V෡�{�K#�'�����@��8լ�s�ћv�fga׋���|H�KDj�xc���`�H�W��D��p/��{���g�2��H�^0c�%\�"�����p4��Um[���A�����L����:�V#��RiQh�(���U��'��9��px��i�\�$cS�RD�دّr\���o��U��Z��(���365.]��$tz)��&Z�&[��Z�t�D�A?SZ��ɪA?K���G)R��V �q�]A�"1�z-�vL�Gf܌j�b<��c���[���cWi	:�9X(הgC�"���(v�J袧�`r��Yoz���"����؈IO�������F\W���|ߛ2Ѳa0���8���DP:߮5�����5Q}y]�����}�lG��fN$�$�U��F,!BR�A�z�[�.4y��g-B���V�O�@�A}ۺ�a��Y�]0'��4|�U
� �ry��������T��yS7�&���a��{�� ���W��O1+ڔ 3@L	#As�k$6e��%�/9vK���U���jۨ�Y�ڻD����fE����^R#Q�&�����qE�v�A ���ҩN�=Db�=�ZU�e��G�Na��ם�?U#�;����`���,������o!�G5�ӷQ�r5�bvtx.+#��!�T̸M���>t��o� <9��g۪�ٲ�e̼�鵃B���  h��:D���~�	}3�ߣv(��4F3+����7��o�(�k8(�c}*3p&ۢ�!�]�J`�*,�d�_�J>/"��&.&��(�v0-<Np�ZޝYm%�W�St����es�
�i�~��Ӣ1A1Т�1��`uJF�"]8<��=uV�	�ӆeCV���AbiY˺dV�v��X�"9��.��]$�S�x�3��C��x�"�ٺ۫�"ݽİl�݀i��쭶��,�.q��	px�l�
ξ��,4��!�z}��
y�4����!�Z�h��
��r�x�;ͱm��7�T9����?��ɇ��Û	J}O�ч��:�TV�d�W>91�}�ٯ���R���uG$�z��GkD�Ň�{�6֫�]c�i lD��?�����'��K<���Գ���y��)gF�����FF����e��ki�F�Ǌ9t��B9�H|�Q̪j�vdw�{K�x���^4K Tq?hXo�ʚ2�ϏC����~X� ��G+���)I(O�묿�GN�7�%v�p�Q��Rdd* 67�gy�=�Z'�"�at�uܴ�_��z��t�c��0u$`_X)QUC���N���"o����qy����F ߱��hV��M�����$�X�)�3���dB�W�ܐ���V �"tƟ���]�#*��5���*�)_�i����O�5�@N�z�}c��Px�M��b����� $�,.e��?	��Y�]Xa��{ΛI�.��MQi�@a��d#E����[��G�*�8���m+u���|a���q�2�(딻����W�:��|E�2h�aA ��\��	�f�8��'6��q߸hn0̼&�.�|^^YI���E�\��Y�&�by��f;$P=|ǐ��ŰM�e�;�7���c���g���ү&�s���M����(�����p��Z:� �uA�V��xn��L[7��w�x/!��'��W�S�[�����.���n^��¯�.�Zy�36�OD}�v�!cZB��cb�#R=��4�x�(|��(��-���/5���s�j;�<i�4�s6��΄>9�ƻVܩMB�(�	��FW�!��d�ܮ��?���?�`�re��Ums�|	S�&����pGȈ�@h�>6hQ�����5���^x�M�^��M芄��{����߾}�^-ֱ�a4����_�N��_4<�,���}|Ut��7��dz)�䅺���>p�I�{�''#mj�q
P�ʚ���[���78m��.��س{�$�E�[�7�Z�HǅE+��ރ>�u�4�ц��*���Pl���A;)>P^��������y��y���]G��ɫ�<���z�Zý������B�H�`�8 �E(SZ�A"χ�ǚ�1��G��i��z�ʾp9�v���\�Ava�,�ٹ��|g���Ll�n� x���El�7�AG3�g^c߷
J=�ӱ���7�/OrSx0W#��ܤ�3	6��q�"	���h���M�?�s�U ����g|rs^0��-U�QzϨ��1�U�a������e^3�θ��t��K]��H���9�Pq��#4�~f��<�7��Ň�4ȢN���Q�,��K�3��g���J��A��f�:H�N������VT�����- N��]<�ډ-��ժ8�\��;U1��EȅCwˮ�{G���@����|dwmNb�h���*��Vj���}��$��}�D���ۧ�����ug7������¸dE�M��4e���k��2A&:QrZޭ�覿2�D#��n*\��ǳ������Zg�`d�^;u�4S_�"=C#� �cPj p�>�`�ڳ�T���[�H'��)�XsH�m4�x��;h _r�R9���vRQa[�ƫ0y\;��E�:�z� +%�ԫ������l�P�pkw�yO�1$���?8��g�އ����IG��3ƣ��K6��f�AuR�3x�����V��);+ix���w���$W]?I�w<Ė�B!��q:�"P�B����?����F܎�j5�p�JN+,/�5T?��h6�M;�/���l��:~��*���g��u�W��s���Ev�)�˕�k��Ύ:�ĥ��h7 `{k'p�@3{�����~�'� `�¯�	�jPKyN��T����3b;�wa�ƶ^y��0�QUkD��m*�n���∑Cm���@����"�
���MH�ɥƕo*�����ZX���~�1<�ߛ��>�Z��r-o}{_w�ô�%�fZ[���A%6�\��a_Ή�GY��@Q���^�XR��G�4bt�93��p���q z�o�l�;�ϭ���3�5���e�a�.���`֏�O_@��ir�i���ʂ`!��B��YU�d����^��;+{��w�������U>�}v�}���~�Cb�~��e�c��_1.�C�M�u/ �pʫ4l#z.�]���l�%J�1�d2f	��e�����/�L����'C��3�9X�X��.�6�!���t�9��	���������摟}ƽ+ͮÑ�o�Ԕ���nq�sÇN46�#�����LNHx�'L [ؔL�o����,�?}x��,FW�"M?��rP���;�*��6�u����w��T��5�[o�p Un���v��0���V�.޲���P����)6_�h�^�*`�t�
��Llj|Y ��g���#�؍������t53J�+
y�(�R�ڎ&�*�Լ���U:0ّ�G&ض�1d�{��[���ED��2H��w�B/~�
Rj���ۤ��|�F�P(^�UL=��*����K�*�%5x�i����K�oV����c�&<�U�msb�r��S�1H')]0��u���-T�c�������Bj���X'-�_�T��F
����
s��fbiC�t�vM�ۨ�[!�b5�l�qņHw��3��V�2��:�,����LE��ϔ�̸��-�=���q�3� �{�:�t����n_�8���F;�>�"\;g��
B�C�j�g�;�h\*�_J��'�n3WM`mS�������5���4��8!YAC�l<�\����b��C��E��������䗋�{��2ʌ�)S�M�v���CR���r,�`���Ml���*E`�מ��7��q,Qg3�zE�>n,d6L�H��ԗ�.��<K�;S�o�����8'
��(˞
%���U�S�.[�Zk�2���^z�5����O6�v�"ĊP%Kί.P�������V�{�yU��hO)AĞ�~k�t�1��P���׵/�˩�h���q�Z�d税ؤ�mZ=��}��)���D%��w��LS�dW�2~k�^�mɴ���uC��lu�շe������.�*^�;��$ؚ{P��������(5��EX~������3�j K&��؃h�7	��u5{�CI���;�&#~����N0���s�ĝf�ά��,g�)�fJ�\�v(�Ӫ������%��=ǡK���"	B��COMd8gt���j���?''����:1u�����:�0̭A��X���X�/g���Kt����&Q�5�����~�k�;s��~pŶ�Z��F	��=5$s�@�������g3L܌�T� C�#�P�=R�7e��B{碬�%�# K2������e��;����l�W��)�Y��[���{s}�>���ly��&��o�5BjlV�s�"&�I��\�[-��Po*ҝ����$�K�5��S|�G@C�2�DN��޴|f�kZGƩ�W��Zb�E�
?L:lU�����>�UF��8"����0%�_�ˮ�ҟ��m �B�gj���趧[Z%���D�h�����k�Ĕ�����r\e�@3O�b��+�xr�����O�0�DC���� �9�x����k��0#U�"�{S&}���uvk��NK�E������xm5�\�F�~��`eG{����I狴[������4G6�gݦֆ���f?�l��5�B0���5ڝyKRw��I�e��;��M�1H�������ઇ�[�<4 O�ôNɊ�c69D�;�2�dB�
�BU�	q�lV���UM���Z�N��<쮲�����fM�Zh(�� �n��Q�?aќt;@��k�6���nH^�$��#_:k|�o�2�˨���,{4���2�%J�S]s�.R�4��9LJ�Y�>'�d�ɳv>�3[�}姺��K�3�B=.T��*e �{M�.�-]�DMu1=�_��m��/	��HN�r븯=��t���+��쟚v"ۊ����kx���w���{o���dWw������ji���4E<9t�����5���[�Ti'�]��R�`�L����ĺ>�4m}J���e�$�M	�Ȳ����AT���|�!S�m@*>�����`�����y��n�k�9�h�E1"5aE��)�g�I���]��գ��
Y��v�.q� {�wW0d`�P��=VU��ëO��#�����knsox���Z,����0�"��
�H6�	H��@H���:�G#n�RX�c��wg[M�&z�zP�N�xܚ����6�Ы(����;%u����N�X|�5���/[��e�2����~��Dd����+|NMW
�b$�T!g!@怵f�K���.���yv�
���
����O�4��c�NG(`d|k�yj��(�����Q�V�k%@�����aO������>�����E̪N����4�^@�)����(��R�\�QН?,ۯ@MaU�Ÿ}������� 0��5���}Dö��\�d"������\�^{��eCq���*q��[�a츂>��3v_�#�λ4t�!XQ��H��j;�8�����&N	�����J&T_�n5J�:����g��(���^�O��62�:���ݾ+v����G5AT*�\��Ff�M�F�!�=�� �w�u�&��4!�G��i`�)��FU���ٽ$͎l^�� ê~�ք���`�@"ϝ�8*y�y�����,������wmX�-�j)����D�y�w2����o�6R�#��!�sm"rM�O��dn�U�����m$��2۔�RR܃�u�rr`�@�M�l9(؛���A8�]�;�e����Y�e\9<r�X���kϭA"82I���}���'v}�Wҿ�x��y�������g���m�j� O���hGɅ�'�Ez+�M_�I;�S���٧�������a�\:B�S�K��ぇ��/8+E]�lid�m����W�H��z>�f@��Q�֥rƝ���� ��g/wv~o&�l��RI�]�������zb@f�Vͫ-~�P#4E/� �/��Ӂ��� Ui�dӆ�%}�L��{2�"ܥ�0_�X���B�e���Ky�Ĺ{�q�W�q37��N�R3OF�a�~�Ng~�+�n�%�tJg�T��O�-��_��,m��X��!��է;�]�8}7R܌2H�ɚ�*�k��0H��Z!J	A�+Vo�FB/a� �4�nć ��iKU���d�eM������~�M���|n��7���Cbb��ߙ2z����Q�7�X\:p�*�7��u2	�6d���8����ޚ�AL[y�3	�аD�q��2f�݉10����f�lV�qަZ��J�byg\\��Wh��}<�4Q{Mĩ������l֘-P_�l"%{z�ͷ��)$�D2Țr��a<ND( �#��}9FNb5/�`�)��l:E�9pZ��J�H�{��g*�*J�A���"��J��<�n�c����FjZ ���ƒk�kW�k�1��L���S���$�ڬ�|9Ae�jHKE6�5��zJO�G����F�&�{vi���ǅ�����s���~�ְ��F�=ݷÂL]���� �E`�,�*�  ��$��d���n���g�����z���|��Cwc0�z�A�	$G˫be.�zĞ�6��^S'�y,~�d<8<�D��XO%��L��m�ei���Ա�XWQ���g�ܲv�C���7�ZiK	U0#��qq�E�5Odk��%����)���nj
Y�k�h��_,#к`����A����5�s��0�g<H�of)��R�>z'U�\俖��X/�R����;Ng�|Z�PN�*<p_F�_3�̲j��Щ	vF)��j�u����(؏.�'�p)�&�;��$q��m�����$e�' Φ�M"�w�cI��
�ڶ2˷Zͺl�l9jv�>��}y�3��Rh��g��y#��C�T��	ESGNK'�옩2�Ű�
(�FD�:�>�C����@�AӒ8=�x"O����˓
'ZR�.����iA�����K�l�ۘ��m�rɱ�Z h�|�&E��!a⿫�;���x��:r�/6JD��7�,\)A�����騨t�1y	sZ��J'G0�S�)3�o���Z�\�$������Z�6}�y��ש�Uxe�/�9��	��v�3�J��c����UT��ºW��j^iS�=�,G�<�J��K|~�����ϱ꫊q�5�3��u��J���8�B>ϔSD}��G�'���{�pY�O@��}g8�CglcwB ��Ԩ��Q��!@�?U��J���p�H/H�P��w!���L�FqHw�$���&�
����G;Qę���-����1%빽/ý0�*��oɤ����3Ji-��!b��q�jR��m:-so��42f�0��~��-���+��v/�9>�^��������:z�H�S�ʘ�"on�d���i�)���x�
�����z�-3��I2���ѿ�f�ɬ{�c��ҿj���K�� 91 c�n���4O{�,����4?F�ۤ�-�뼘��+�_�;A�N��t��yw�?K�`9� �[�))*�DV�L��=q�/Ol��q�d���+{y2�r>L=I�� w�<�Q;�G�2&�F����$d�݆�勳�.��&eY��ު,9PEi?-�f3/� ��u�2ҦHK���W�Q'�ҏ���`��UJ��T���Fg�6� �$�T�g�!���"�7�6����Î����j hzL��=!��W"��`�{���`���Z۾�*N�RB�/YL��n��j���:z�a�u� �����W6�B��a��ז�ר+}!�]�� ��p/9K'$$p�
헕#����Zi���ǂ>����o�~�"X9�%=�X~3�Vd~yT[l֎�l��]7��KS��,n����%Ƽ�pU�v�YR&�r�5�D�1��n9T��	S�r#��6>�߳�����3)�7N��i�\	�.��u�gŠY���Ԧ^Ky�hh�\qCİs�/�%L����`x*��mG�I$6�M�ڃy����V��y�5��{��l�Ql]���x�zz�g�����{�_�q�j���#�:v�]9����F�Õ9g&����r=A�$*�y�~�6x�md���u(� ��^�=�����~7�c�9%���  ��b�3١y<?8b"�،@���O�wqݕـ�!ƶ�3�=a���R��9FlkW�TBW�޾JW6��/~?c,�����]�4�Y�8�IP�h ع	e��7B4Q�A��E��Ƕ�T��q����Ez����ȩGE�TxlT9{�L�����	?��|�U����|�W�߂q7�mk6�7���~��mܳ j�ғ^�S+�7�S�J^q�b�${�;��?/��.�:�]ٮ2�H�e{��_�^�*̘��\�௵L�>�5I��X��������VruDm�υ�=L3���=k/+���M�|�%��a���7[��ԯƙ����&�Q�qZ���Z�c�5�vn��y�k7|�@9,*��Q(AQ�'���.Bh�d?C�1��W�:z��/���[e�b��o<����.#�T��z��D�iv�X[�ډ���x��L�w�s,�W�r$���@m��Mq=�f��)��1�N8���H5�;m����/m�w���n�g)�M�(�`P���E��Be�{���au+�}=�Y���]:ˣ<�X㰈eL�!LܔՋ��2$bu�S�짨-`7���Ea�ȏ.1���穭H���й�Jd͇�16�m����}+p��^���t` *<&0�f8m���U��U�ׂ^��Q�[���:꼰�C�̏�l�"�H�N�����{`�����Lv�P+0o�*d�+��-�u��l ��l SA���U!p�xD
���"Bp7�j�dm��+g�A��XZ�s$,�e�wC��hqǀ    �o�_�3 ����p�q���g�    YZ