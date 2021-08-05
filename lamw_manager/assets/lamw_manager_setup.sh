#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2803807800"
MD5="a241eb02e02b975cc9b1579ee5ae4829"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23536"
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
	echo Date of packaging: Wed Aug  4 23:53:42 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D����[�}5){}���JI�AV�D"b�de�K�Bx10��O�>0Rҗ�����b��N��g�eF����yJ�,.�H�K@b�
��W,���6l��h�o ��\q)Dd�o���B ����E�3�ww�'�d4SA��p�S�����by�gO\�-�nC,����0"Uq�\8��5&���|�h�}���Z0����X0e�����/�Ia�-l6U*aP�0&9xt�u�g�A.��.u�'@�j��-����xz��X�T�jէt8ҽ�ׂ,��05��wA���z�����Kڙir���� z�
�"�l��f�Nwl�k�(*�Lυ^��_՗}����J�j�c����%4p�A�o�'���HR�W�-�M.�}r��K�J5ȅ3~$�)o�y/l�)k�������x�Bn�
�H2��K����-�6��s D�ˈT+����P`�]ʯһr�\�Yʶ���(��#:��=ֱ��QZ ��#��Sn:b��}oluC�v�-~�{Dr�X�ӛ͏�YU��a��Q*Gϰ6��.V�fc���*����8����-��ٜ��l���J�d@8�Q1f3̛��h�s�N;eP��b`��`�To=���nmC�)d@k�WG��ckG��}{:��DF�1_�����9���R5�fd��F��4o1)���r��/ُ���܇�c�-��C�?�'��_�$��=ʛ������pӵ�D�����ұ�Z�� M�p�6{]r���p�6`�C�)7G�M�4g?'|�k����Gs{Y�ә� e�n�ШE:w����5�k�s"�e�S���F,W�T��j�r����K[����+�G�%w��3G�7�?pc�X�s�jо����'� S��@%���;��qd���Kq�A�u��x��K��20�S[
��hC1�F���V�ڮ"������3�"��	w큩�O(U�F�Im<�gx�V��é�%g���¦�8u���6h	D�`W�g�|H�����7M��]9'[CRי�ЎީX�M������۩u���G`��h��(q�2�P����ɿ��3�S�F=��;<s���67ӭ��o;0��b�bSm�B��r�%`�5_���������G���[#!�i�0O����w�,��ۄL�+\H�0iO��p*�l�n��H��Pg��9�n>m�'@�����}���	-��Х�ߎ�5XO�@�@�O9�=�Z	�7� ��ȴǣ��8�����?t(�K��%ܐ���"K����7�r۰��}&���D3'
�]�7A��|g��?^	���l BI��54֡�����#x �cRn�H嚁���-����h��/�Lz�Դ5\��(������)��L��|�1+�-s\����'���Ճ++Y��l��n�u�x�1<�D�ǰ�ƌ�G�j�!@;v��B����jb}5'�څ~p�WП�$�0/�f�����< AX��<�.�J����ƕW,m��C��j�Ay��,����fC���a55�+�`�>�1xzG�:��ي��Ѯ�@h$F:�t���`��g��JԜ�x�\�NMj�6��s`����~mu��2!�sW�Z�\#�z�h~4�9R�Z)1�����bĸ�H߈�k���?�W�5��z�������M�@�!��P��n�J�F���l���
8�+���˼>�[QB��敝N�M�4��LM��)�l8�%�z�JХ���n���#�I�bq�z��E ����DKLX"$d~_�-���Jf#*�{b�L���	�^�|���pH�� ��,)h� d�^5��>I��t��$�mı��S�����"�\��T�ץ�ܴ�����:[��h�7��Z+1ടU�J��D#)cr9ےu4�a���G�����(;��dtΤ�>��:p
æЯ����q�Ϋ�Nµ(���V�2It�;��b@���M���w��j�P?��p��;y��#بbp=�XÃ�!��ɖ��{��.�L�P4�p�k�.f'W3Z�ҍ���������P���u b��a��\���T宯��!���E�~  $O��]��9{ъvL�r�5�<��s�V�J�K���yk�� �
�K���Q��k�=5l���cn����֨I�>FY� ��gōR��S=�ٙ����s�.�E/��*�|3,�@~�r�qk�p����y��I'n?N�&d|��Wy�  S[h��Ў�}<TN�d,oNEa��4.2�u%$�]�@r������!ų��^m^ClH/�k0w�hr��@��9.WԎ���|�f�#�I�<z�v!ǻ��c@�2q%J�:xa��<����^b�%S�������Ί�؋�D�o�JTk�Xs`{��f>��e�?����h,��o�@��ku�J^�6���)���5�Co1�W;O}h�����J���������[-���O?��}o�j4f��@i���~���cۇ�rj�%7��@է<��q��F���FPN�y�R��h4��r޿�&��y�W������+�;�7U�oؐJ]s��H� L�䒿wk,o8�%���u2�9-
�(
��gr�{��(�k��� o��Q0�+�W/���x���(�'����Rܠ
w.	t�/�9f*}��v9HaaM~BL�!�s��61�[�|!�M.~��F�<�֬�U�	�������q� �.ƔاL�iFE�ʔN�P���K�Ҕ�����Q:e]B�
l��7u��LRM1;:0t��废�~V8/��#��#S��p�O6�O�2FDU�o���l��)�0m���{P��=o�_Qw�R_Rը5�)�?�_P���;��iH��t��Ǧ��}TM��A��a6�/�ݶL>�K#��h7��kߪw�.��(��ت$���z:�5t�e1���w	/�u��x�!�Y�2}��55��|�$+��~X>��3�q��ڐ�&��R�dbNj&C��MY�@+�m	TѪg�.�;���ȬR9{�$�%h�&�����įW�d!^d�;��>a�Tzi���횰��EZ��2#ہ͏���5Mo��u����RMm���>).dg"5���\
��`����!e�d�q�ց�z_�9�-ᒣ؟p�hqz�͈Ic�*3aBZ�ء�X0�����n^�up��b�U�'	[�Ծ)3�8	����p'�tS���<���)����V����"`dX���v��Ȋv�eå�ָ�k<��>��ۏ)�|��.�s,�n5Yp.}ܸ�.��κw�\�a�l��<(�]�<nU	�D�w]11!`�vk�Y?��M���S��\Q�����(\�M����o?��/�Ш&�}<�.��3v+��р��ӓb����k}���n�-A��X��� ��6�;���Q�$�MA�����X˞���#Ձ7�v`�^M!����
����-Ғ ���K	r�&����g�[!�n[\m(������4i��=o���n[���{��6-D�ɋ���T������>K�g��� ���J�uKZC���D�+|��:�gD�7���v���/�+�y�iC�\����z�r� �}�8���'v��W3�-��m�#?���]u������ O�Ă��� ryΟY#ߥن�v���?�EV-}�W��@*N()1>���֐��`�ƽ6eSf�\;�1�c$��fc��Yga
�C4�Y�Xt�N�
�oi�<,��l���{@�(�$�ԷuiK��,��6�y�˘��ґ
ٙ1�c�6�*B��s�BF	�d%��G؅ХQ���~��3|�mļ<�<a����)������|�����Y�%�;����'���R��̑�i�h(��Τ1{t��������-�*C���_gu�4E�U��Y�b�A�Dy�C1��#�`]�YD7j�+��5��9nޣ���"���E�v�W���J�<A�ђ����g�_�0��𿞾(@�8L��9�w���z��|n���:���_�fK!���эO�ܪ9u�'�6^���q T}��QDԾl
T���"��\�E��kӯ:��[a����-��;�fi�U��f�.N�w�X��Ͷ?����ٗ�Z�ۊ�AV<0Y�V�\W�TR�9�R������A��$����ҧ@\��6	�&В�U�Уf����ǌ�K?��'@y��N?���mi,�#�iè������
��h>�kn/V-xk8:%�<�9F����dh���b�F��F!�Q��ѐK�$�d�����x�G9\E�^��ok���ͯ(C�������-K���,=�Ru-��~fċ��@UR�?8L�t�UHG�gO
�VD>� �e6z��n�F�d8�z#�;�B�_�C0���c��u�*���7�Y��`ִ/C�,���p�4�l���9:$}����"PڅRsd���ֶ1i�}ˬ ��|�%<�|�R�ک3��||ѷ�3:�5��%��msW�2q�kBq68���iܳs�)�8`\����@�iSG�~��iƖ��w�ɬAHcȣ��J���0�����SX�lZ��|�]M9�Z=h7tX����S��b��[��Et�x���h:i�T�°ׇ]� �ZFg�;.�z���nB��Q����$҃�	�e�E��kab�x�U�O|���T�5��ka�IeU���
���a��sB��g�Vkj�73���$Zx�l��L�tQ��M�g�1 �{wcDksEY�cd�)�K�BȢi��u�1�b�`��'�֑�����Jv����cd;���q�H
Vr���H:��^�&"�P��#�:.P�H�K�.�4c6�Q�h*9��!�R�ֺ��f`J���kЄ�6{Do���i֓pޥ�w�T_�i�K�zk��g<���~��-�`��o�Ml���n]��1هE5�`��Z��uV�Âh_hE�i���[��k0����~�M�Ƽ�Gz��_aj�О$6�>�Z�ޝEɞ |M���3JUr��T$��;C�q��P/L���zͮ�<-�>0�
{�a���f��&I�N�_�C����C4���2m.�t�B�ߵ�6�� l���k8{/+�Q~�m��U�qߺ��y��%�L�Xm� Re���d������ޙG%�+���vǌ�P�ߪ���2�y^�'K�����jl�t}A��zP�[j�������I��9�o�<jI�O`b N%ܞ���H�8k���t*㘔$u_f'<ǎ薺H�k-r�d�g�g���@̐U �l0!-�,u��-}So��^F� kN�#��e��_ ��\�?�ӹ#�F�e<P�Q�&e�'~d8c���$�-q6��55jm17���m�[ge)ß������3�s�r���W�t(Yw��3�t=��.t;�J��@ �0|����_���D������C�봶P�.��XL$ҘJO7��jp�t�T�2�6֫;|P����su�	֩������7ŉ��O/~��,�Ǯ�ؿ�	ȫ=h�F��蒦e��X��@mMg
nP��`��T!b�<'u������;��/��C�Մ�lNg�^ׯ�Q7B�20�vi	�R;yIsV��۵��m�U�kJ&�6���@��}��D�ʃ��s�KοF~Ҧ���o��U�ţރ���x$����@����⡉���3 ��������W���c��ӳ`3�����^W��3���՞fx� 4Y���V�N�������7R�>�9y�	�'�MĽ��%��Q�~"g՛�9��� �+��b�);۝��� �x˭��[JFI�n��&���{eXm�-�j�q�t�M�2�Hj>ɟB�s�Z��= NVPV���Rq�6E�3d�1�>)��`�o����@;w���t�����z�7����.hpǐ3�?����4*qk
�������"��ΠS"��(��\-����U�G!6�e�k��r�R�@�0��G�+���Zn�Q,V\4�&``��,x�K�)�?���u����49�i{�$��<��" c�qn�xoKr��᲎����G� ��5"��,sTrӽR��Kd��5nl��V� �혏������r���b�x��t�����6��8{DfK)�C>vK�B��P��Bxo$��`6��	 \��M���7L�8y��)����L.�["�峞���{#��w�\�ѧM�����I�.� �a$�?M/��DY-���q.�櫷�B�v���w_��Ձ��&�SuKO6��ۧ�DE@�Έ�2�ߢ)*�����8���%,,�=�)ރebu�c&d��+�bŁ�,g n� �w&��ҧ�I����[�\Jk����p�-3�;=PhNl|� ����:D�]r�մ>�F��⥈T1.TV䊴���ꄪT
�t�����n~q�ؤ�����z��UL'j�a�bl��f��3u�>L��O��LJML<�'��+_�0�(� 	z�3����2�2̇�3K�)�7IgUc[P��p��J�9֯���n� �42@��о�/h~6�VPy�rH�emǗ%q3!�g�����A9��o�nſ $�#}���E��A�SH�Ǟ=c���	$N�ʳ�ӛte;`敕+j�a�3�t#ѓߊ�V`U,�x*�W�_Ԧ����"�
��f�r_Ҫ�x��[���1{�MgDn��B�W�3?���6R��.M�,m���7�طy���uW�XA*�e���Y ��}����P���)w�PdN�6�.���J�#�4������U���['�Ǎ���u��>��Mial),{'���ko ă|3�-�����׵"�U�,H�3���r��6���`�\C���>�M�m��bJ�+�d)�yrl�{���[gPXZ���}�s*�^0ZLH�ـ�e6�؏��>�H�tLt�uU�R$��Uɥ��<�nZ0G���GH�II�-��$̘ &\�7����	D�ED���9�N��b�~�$�
�/�f�Y�Z���=)1���&��KP+/O�7��'TU�K݆��xCR�w%F���q[WTlH~�"�๒�*���=L��F#�k�8���R��D˕�.d��͢�J�HTYY&T����a=������м�[�U��U��
���H�p��6���/��]�S߄Q���I2
��ܝjeK�=���w{ߧ����4C�X'��B��)*j�`x@u��Uͥ�����,�+�/��!�lt�T����ݔ����o�۾��X��x(T���s��eF���{�&4J�ܷ��n��Y�U�
�8[�k���@��#�E�^t�ǙU�I�4o���$�j������~}r�����"X��u��Gs��D�[T����N������%�nâ�n�6�;����K}��j��s�k�^;����Rp�'�Yg��H^H���b�"�ř��� R�#0�����A�dDMV�N�$9�Q���.`��e�Zܬ���m�"�gt��*"�z /�s��5�w;�Y�a	|>e�����c��B�3 eƜ��:��&�m
V����G�\���]��|���1)_1�JRa�$��C���>���oR�?�Lp�va��S�'Bxx��j�y
���Cn�x�a_�B��cE_O��*��{3K%��Ļr|�BM�d�9�N�g�,���-���5�ĥR*N���3�C8\�8˝qH�6�z�d���h��J����1��<T�O����G�_��S�/�dp����/���J<�:��%�i�]�� �`�SVS1�	}4Jt{�b�ׄ|<���Ն��	�ت� q!E]���j��{�`°l9�r,���w���~t����p@'��[�*�ϥ�� �t�	w�	�`�R"XM���H�\IV}�Lht��'8-jm������C]-W緥I��Ew����:���!�O�$aa�� 4��v��Ƿ�L9�&�wz�����	�p��ʦR`@�sW+�u�:V�S����bL�a �йi�b���q`�N��ʷ� �����
`��gz�0�	vl�߷��Qw`����;�����*zN�D���k���?��>�����6w*�V#�-.��nc�+��3B�-�Ē�t�rc�H��r$ ��_�8�N�h�;�'�@� 8Z�|.i��������7�Oo0uaX ����2T���D���xÛ�$�Xiw�R�M��{5���lIz�����p�Gx����m�ړ�_��EP%�]�A?�*�>3��n�y+����&� �,�m��x
�q������V L�tc9�5�/B���U�,<=s�RsY��עA���)�7��v�����/r���d�]�1Ǔ�2�2��
��BW���N���iQYs��[��$�aR�A�,��~��X����P��v�� e�l�XjD��qj��=�p|�lg�ek2��4S3�#>9��̇S�U3�Q�,��]X<EGy����k��,!S�T<[�S�Ny�٣$nA�  ��9ޣ��6�5�x��s���/�X���xO4��CZّ*�8�����X��'Q����X>9M���`��s��]ZzF�I���L�rns;x����D�� �z�p�Hԩ�
H�%����C_0c�XdJ�"�� ���6�8�T���\o/.T��ߔ8(@���aFL9t���kgE�V��f�R�v��6���#)P�t�жC	U�c{�&XDүi��.��RV�^�p�#ol�lDm_ʭA��h���y[�9�cf�@�6nJ�	�m I_>��ͥ ��L��RM*jqMCي�^iH�?��"���WDiF�2R�g���	8XS�[V%�6V'��;���|��@uBι��2��h�j�?b���\��o�%Bq��x��=~ē�!2�A�BU����X��q�b������~�nNf$�_0�Ͱ����7̘s�e�-�?�a��ͪG�~�t��l���!'p����E[�1�D��>���׍�ż�b)�@�k8E�w�r�Q�O�������?��`G�	�6�^��U���bX�9�{��}Q۟DS�/������t�"���7R<��A�߀�����b���#k�"��Kpx�����|Q<��j]jN{��,����-y�k��&�Ǉ�������ԇ�\O��:"��|hA�ʒ�i�S�q��zUo����E19	Q�jEwn�I�g�j�L��7��=�y�V3Ղ�T�s�`�MU�t��3Ņ�OU䷷;9�c:����,Ο��������'�Vu��W�:,�ل�Ky�3���u�]���Eά_���w�p��Jtq�ӂa�ȑƿ{�+�p�U��f���z�su}
���Ò� ���Lt��oyޯ����%ݬ���,�6�i�j�y=�	�%�Lbu��QQ��5�f?�7hC��Q��	}�u�6���&���[�9vP�Rgɷ^� U�'
��"3c�7�V������'�t�/��#nY�ms����rᦦ�7sJ�}Kl�N(��򪁍����-������C}��8��Ux4�w�K�A�	Y��r���:����u��pS�������ݬ�J0*��T��l�L�*�@��j��[>B�"~��h4ѿ��EA���O��G�_����E�ʆS}��w(Z�E���_�+u�|�Ʒ�ؤT��0���x��[7�m��n���z�HEH=8�_�m3B���Ր�p�H��.f�4%=�naDx����t�I~L*�MV)���&x����1?�PP�(����S;��P>(�6�`/I�g�Ÿ�n}L�t�M/I|R���� ����?���y��V ���`����e@��3Ԣ`4B�#�[o�eX��I�L�H[��1�W���j���?`�C!3��~�����$�b�µ�+r�@�"j��"ֿ���-c�n��;(�0?q:��ց�k%��ɐ��n&���A��@Rީ��H#�V�jG�u���ԼH6��3�;:�Vu�pH̓����D1��>�t����"�^J�7q������9=�&��hj���P?~2�Df����ZU�;�4_�D�u����Z�j&�0H�S����+�-4w�.@D���6�O�k�&$(@Yk���D�l�h��"�4��#b6/���� ���X�kLlߋ��?�r>����D�I�d�BR��6VU<B�:d0M��S�B�O7���#�����#\�>��&"�C�qȽ�/���$��Ic�:��]B{J�i��>�b�  ��a�Hc�a��b���P��c�%{��AGD���X�O��Ҵ�-A�:����,\Ȱ7��"jdV��k���UJ�V�1��V����(�h�@s@��![u�Y���(')�.�db��Z�X��ۂ;j0�������*M����� A���:�v�=r,ig�a�F8�*��\W�$/�W�,���ο��t�oû�'ԣ1�p���XS�~	r�]�X��	4����[���t*)�h�`!4��uA��Ǜ�uc-��'��VI}z�-e֥���#
��2G<��\���M�L٣��\� ��OWc�
���̥��A$��lgQ�XЬ��f�F�&�]�j��x	{�}0���rر3����ţ��&��W�p�h�Ojv@ސ�?ǀ}t��-���ࠣ��>��Ɗ��x�p~�xJ��@����9���r4y�)F"gZ_�a�~G��c��Ɯ��i��E��A(.C��W��y�^�po]MFU*l�ic]��3��X���d��8�,ү�^���l�m�4��e�A�5�p�
��/���8CT:���Z�3:���Q<U�9� �E����(5���S�u�&�V��/���3�$�h�/:��[��*ou���:B~�`�fKSA�-�S�Q�[�\�:$ז��RIi��U]�b�k��K�R�53?��e�M�(͂U��Gx}q��&�_�[�Q�\?ʆ��y�ݛ��b;q�l�ߟEN�x�\:���4VF�a��#���#it�Ԟ�q8�DɡMXV���B��w �G�߳bJPtK�_b�Y����=�����g�1�f�>�Et�~���*���:7�ݏ ��N2t+#��l�' l��Ň3�	
o�q]>A��2bt�+)���5�\�ÆCcbө�Q�ǵ�e�a͌Ϝa�4����.F^�sG���N��I��z�l �p�ꮬ�.��m�p���n�@kװ1���4���P��X�eyԅ�MѰ }�JL#f�پu{���fY�Iռ��oC��U,CM�/K�a�y��@�y�qD��8� fJ��������̸����s��X��*$L漇E[q3���k�*�*"��8�`\���RbPbx(#;���sGe��(s�i�G��|$�~"���MrW���� c�"N�	��!Th(f�A�.F�hv6G�k?^�����cB�P�+w@�%�ɯhVݩ� �ɽ{�������A_l� �Saq4����<�6��:�8���ë��C�/=������/}�H�����d�od�]X�إ�yq?����#��%��ղhVm�o^	K"R���I�������B	t�m�j�˓-���v]҅�K~$��	~|�{��A�.F�)� �zf�@�����#^��8����cr]�Ќq�k���@M�a����@�DZIm'�
��+[�7����h}ª��j�a��eȾť���N���U��Ey��
>�Ra��c9�#x�9z�0�4����_����	���NO*dS��!X�K�M�*!B�w0���)ԋ'��9,�V��I\�D����sC�c3Y���"Fw@Օv��)��6g�ꖦaK�K*���[�%5~���F�D�GC��H�vb@=h=�(���ٟ(T�����6Q.>���3��a�"Z����°(56/�<��O0�Z�6x>�J֗�ˇl�� �e`|����X�JA��6d  ���ׄ^�j],e��zu=G�+�O���^O�k��ꠡW�,r���g;�U1DLu�l�.'�6"Е�!|<��o���n���Ӧ���ގ�|	�kt�eNѡ������D;��)��v���~�ˇ���G�}ګ8�9�e�A�iȒ;�3n0�z�@K�<���g�f�P7P�8(nWkR�1���)H�HǱ�^�}<b�$���(׋�<��2�Q�8���
��m��E�.ݰ2����R����l����']L�yA0r����7	�f�`�����J�*,#̀���]�\Ma�4N����-�a�S�����M�����y�|��h�rp�%�G��$|��
�ɬ_̗����X@7�#�A�;�Pa���4*ۈ���bi6-G���ȼ�Te��[�·�N�e���s��&D(�FY�n;�L����߇��7�v�+����<Ep<�9i�k��&�+5�?K��۰0G��I|�*3�bM��vj����+I͐�8N��q{�.Y��y�~����<.;pm� �ظ3�[x���a�@#���R�ؗ՜?s]��`���vp�f[Z?k^fӠ��u�7b��c����į�x#�1MFn���U��:����0v��O���a+���]tc/��c3,�gW�Q]f�d������5��o\�5�}ⒸbA(R����Ow�:�څ�j1"!啕�y�eƧ9�9|�c�D"^n�U��������-�����?�h�S�ȋ&L��f{+B��YoP�T��{ 
�}y)�!h\��P9P~ǀ������zk��t	@�4L�@�/Qyu)�c�Ujp��a�kϹ>87[׆��kN���������|M.q$HHW�1"Q3��Ѝ�F��rw�(+�E�U�B�8�{��d_�d��ig7X%�(����f��{��u��g�|��z޽�1����#z�~�����g���c"nPɛ.^��.� ��	�N�%O�R e�|c�{��O��e?�AC�S\��4)�s�)?80�5)?�A�>��E*��tQ���W�,�i�E>j�X�.�H*��v��d�p��U��ı��!vh*���	��Wr��|��L�N�J(2�"���^�t����3���Y'�\�RN��Y0d��[A7�}
5RK��� 4/ٯ}�@��䝤�G��-au���*����։��C���.)�By�!��.��{_H�����7c�B�w�P���R��Yy�kѨ��
R�;���#N���+a��TT��o��e-���I�*Ucc�JQQ7�H� g��$h�`�Q��H���4��Hඳ7p
�K��8�\�}J���d�u�����nt�8�1`�Cq uǝb?~j; �$
�f&�d�v�d���āJBZf�VQ���.���1��C��ٖ0g����f���l�,�}hs�]4���{t�ˋ�N��r�-J��T��x��	��_~�1�K1s]��ܝv������َ��a�X�D�Uh	�#ِ�`U��8�<ԡߛq"���)A�G,��vkoXi�糉��'Vԣ�5i����qa�,��^� �����)�U]B��f���=X�#=�ɞrO���k��Ķ}d��`J� �h�C�4g�@QA�蓥	�&۾�y`��1��
��k*2%����~�n;��<��_��%rJMs�ߗ4x�)����G�b�U�{A��}x���$A1v�Y��]Aȥ��2�ߪ�SƲ��쉥����6k� {-�ʊ�=?�1�|�LZn�M0f���@�J;&D�w�%��EpY��|Ј1��y�J���i�h�@U�*�v|��ZQ0(]ް�.��Yb��j�(c!�͠y�1��u$�6Jw6�y��Y4���|tE`+<ej'��p]��3 �;�#oa���Ai�a�z������7@R?�{�6/���g��ٔ��̖�mعj3��K`�������	�O\���g��{�V�=hwj+�6գU"C�s'T����q�}��%�I˒A�:���%>~(�0�[n����N�������+��u�e�w��RX\���T�>��%4[�Jzp�;�[�T��4e�Bȯf�Kg��!)8��@i��������,>Cf�qwD�nW��z]��p��L܇D�J5IT�Y��p��P�
�')e�hd���X*)�5VO��*���$��Y���ҧ�%�'v�#�pӧ�!ݪ�mSS
�&n�	���cpCb�����j�d������̈́m�����&����[ׅ�z=��l�l#<,�[߯�#^<��;�8��tؚ�Ä ��:��o��d|H��Y9� W �7-�i� ��}C/,���R��a�g�z��P��=�Ga��46�%m�����z�_k޼ik,^�1�5u�E�3���,�����Aq�"�5~q�����@�)90>k�,6V����څU���Zi�	�+�c ������&�G|����ؤ4?��B���E�9���d�M���o��
F&���$��X�ƺ������'@=vB�!-5�v��:�6�N���d-�go])����Qi�k�3��W�$�d0$��U����n����5��;�X5�4E!
�~��m��I{�� 6�Z+���dT[��)S���5g�/+�|wyKj[i��grd�:D��Ϡ"<�|a,K�$�UgO�9�d��$MM��[��An��O��&y�)Wk��$;��;ܵZ�1ޠޯU@i\��1�FtxU�ugp��F�-D𹶭A�#�@�c�Նf��q`�,z+:�A'��S����B�}����g����!�Ad(�>s��Ei�R�.=H�+���T��i��xk�*SJ�lu��Hı\�:ev|)*�0 w��5���v+�g�>	�b)zV
�[C�����g�%֚&\��3�/�!!�a��c	@o��/F���8+��:��[��M��0no�l�(����@��Z�ˆ(����=^�241;J$8��2y2��>�l����;�	�pY #Ƅ'O�������Q��%���=}!V�&Z�'n?͕oA�ɽ����b ��n�# ߷�.��c�kwz>����/2!c7}E]"]���I�������������Ό�Px���!d���"�$��_����,7#��e��Xw	ߥ��.����V�N�q�n��}s��Kg�*B�@��yW����zˣ�>`�F���G��̅E�z��!������F�$����H��kQ�����e���5�	��o=ÔX6�d3�<M<aD/<�?gt=�(C�Y���:k3��)9K�`�8q�ʯ�?50�����I��Izf��Dg�)v�C(��X�C0��oqT�WC�w ����o=Eލ��<��Z/**�����=ge���ι���z�`��ܴ��k4t03��&+L�M*A�Fr��	t�;��� ��OR8K@��t{��Z�7��4��!�E���B����������g~ut��N��5y�䝝�N�3p��2t��hl'ӋX����F���4�hu��e���{xń-�O�c���5u֗��%��R�y>�x��*�b<��g>"���j\���,��h����L�W$���tWoK���(�@���":�y�p[�����l�d�9��:��!�w7��e�V��JF�֝�2�b��E	T2�^��H����3n��jj�=м�?|���3dTvf�;���0����&� bX�4�a�c:��I�"]��c��Yȁ�p�ٍ��@����Y�B�j��m����ʒ��OFL]�J��.jZƽi8���4�2��z{K|)�����H�"J�7}��������RD���%�[���u�IQS�L(g�&ɛ6OohN� !��%�y8i��IXر0TVN܆s����~q�S������O4��fO��{q���u�{�M����q���?+R����;	I?�J?��MB�N"٩8�ξ�J�w�&�ݽO1�a���)=��Ji��V&Q\,�UcOU��Fu�I�����]�9��Q�6��j1��%����J�LP6��0#�����C���#�q�m�K0�����`8,��0ukKqX�J '�\��௦� ��x�*��V�ݬ��pX�[|0>o-���TH��9s<Ѣ���Yc���2�\H��*b�"��T�J���нz&3ӫ�bt1ӆ/C�.�O'v#��5����;-ߔ���H�.%�Ka�B1tRyVZ��Mʹ��K �����4i�VQG��_L�#Ƹv#Bh"Dc���D(b���<q�ߤA��8�e�h
�QH��Ȱ7����n���A�Do׌l�����t���M ���D�e�:
G�ֳqY�@�q��S�$#���fT���&��:6�U��:Y̌���So���P���zZØҠG���"��`����:��]ێ~���g��c�����4K��`�����Ɵ��q�Q��G���I�a��"W���\:�U�sΗQ��}�^��8�
jG��4oPq��%�?,�Ra��*��,h��a�e���K����6�@�&��I_����F��9�0��������.��]�C�׮�|�o��-�/����|��V��������3 A4���!�{����t3T��h_���*�I���S<ns9c"F��a5q�dd��� A�ͺ�����|�i��
D����j��n�1����`��K<�����MK�񖆢���aOξ�t<iT�tA��/� l�C�#W��R�g�*+��۾���3�/vӾ�"T�o�6S����%�:�no@v�����g�'Xl�O*cxlV�O�����զ�����NMEk:�H�~��f���h�f%T�.��P�y&��=�x�j���t���v�g��
H�(��|
�_��9;�̜��x	�P0��~Ɩ�0����b�>���=b
�������\O�@׎]��M��|G�1���Y|�-��#�
��Ry&ڮ���k�j�^f�m< ��n�?�w��1x�{�&�A'�=�6�|�yj�"�-��H��,�����#/	������~��)�uNz�
EiOf<l*̀N��p�g���ɥ�����T�jjZ}���o��T�H��ف_&�o����	LP�F����Hb(�]��3�k*����*�]�����V�@�*>�@�(�{���a)�M2��$	�B������I�nkh��c2؈���%c���u�ʚXZ�a^��	8��/N�0�OX}хo'w\K�j��u�%��l��.����H��M�Z�D�;�?���p�q��uE�c(�{(�EZ��+ț,�W��>#����!����?�!�����Q�@k��xk6����D�5�^B��i�%��e�Ww$�8�k��yi�9��6E��?�۩ذ@���\�c�\:�Ǡ��Ɍ���d��#>u�3>����Y-�|��RS�Xr�!i�g��C��@p	���\�ۊ��%�]\��S$D�͍���4���!m�XPp2�q�Z+GIl��2R�������MfG�>˚�ix,�-��:���E�˷��T6��g���ѧ�5f�޶�J�I3�Q�����3��
�J��j�5q[}+X��u-Y�$��܆�@ܿkjhG�r�8�������!���ul��d�lT��%����&O2@#ݜ�`G�t������P��gPB�`a��F�m1�o������@�3������l���J�
z�#���1�n'ʶ��j��Xb__}M�����M�$�ƥ�)�
��KB��ߠTQ.e� �0�߸
���B�?�f-�`�b|�L�5';�©WL���Ҳl�YiG�z�i҆o�4�1E��M}� G��7<b2�����<����]\�E����ψko�L��j����[���ɏ\����1%ĚC:#�g4�8C�w�B@̨� q@�CJ� 5���獐��1�2���I<�ur&�����"�A�V��P�v�[��釒mq��<:���$���ٚ�_k&��o���!
M�9e d��UP�Ч��P�~��h����C��S�b}��O���V�u�n��1ڇ��D7� 6AH��S~�c�FZ�����pvs���z���_x�t��Fj#DBR��'WF��f�������t��Έw�")8K	��|k�/��Uad�W���-xn�>*Bێ��2 �:y��Qz$O3^�Ϙ����e<*5���0Dp<�о��7��-?�^��}`�:���:�+��,����#�*^e0fP�$k�f̤2K�uk4��Tܝ�+�Ҫ�Q���y�wb	�U�ا��
��f��b���N3GX@�}9��y���	���+���"��D�G2��?=����k��L�]�;:�qz�g��b�U�@tk*�(:ȡ���Ma��i�����9��Cy�<�ׂ�[ ��˶�a�WZS�fↃ��n8(�j��������������D��V��x+��M���d/��]Lv�KG�z4����C�P[?��8^C���Yw��ٲTH��h$�u��-���~}����~2�*����ڙ��z�A���9A9:�T!��Z9�q7L`܉�����Z?�:�M������/�#�U��k|�r�ۊ��E�Ì3򢽱GD���wS$��f��;t�����,�ǥ	b�R�!��h$��*��������oY@�W[���m�")��]P��̪Kw�"���xh{Un޿�z��Tn�7�h�(�w����}�Cj��9S!��Yh�g��a��%J�LPdJ����|%�?n]�R���Fh�W��0S��Bb��FW�5�7;��b�~M�v���Ⱦ�����k6�t[y�
m~�һf��2�x�f7����ȋy_^��=��t~��!��HwF���=�"��3��5T�Z���+��3+����Ѓ��6I:��?�Mյ�J��(J��ahc'\:0�j�%![��Bw@������o����<i��ڠHR��M�>mbV4x�^��9����Xy�=��ӱ�U?��\WT��>���j�R���9 �Z��i����xJk��[��X����Ln$�jo�S/�77�Zzg��1Q�r��g��_r٠��͛n�qnQ�i�KI��6��n�}��ϲ����P��Aq�Fo3Y �(b#a�Q��)��G�r�`.?�[J�:3���N&�)�b�吘��>lr�/V�O.%噻�����[_3xԠV7�FXz�2M1�d�o�N׾Yk�U�BGG�"�{��M8������U���̿U-qL�S��_WQ>tBdM�����a���x�I�؉�	��/GK�晃c�AY+39m;��g<!?J�)��4o����
g��X�)J��k�R=���}�6@��9KRԚO�`�{t���,z��)"��c�#0ۢ���x�Sb�1�p�wi"tO{	� ALHu�e�1%���BK�^6�oBY"�~u�H�q�m0 jzU������y���UX3D�IG��/H����A#�8��g����o�!������Ә��F�������XJۀ��_|��4����(��Dy$�.�� A~+���5#�&�HP4�#������g\Pf�h7��<�c��C^��Yu��|9L\���DzNՂ���5<à;D��PA�/]�a���e�Έ�K�q�PO��~��;周J1�����ח��6���^7җ�2�bm� �r�w@?��p� S!jS�Tᩗ��/�H��#�O5��i^h�]_#��rg#F��4C��#8w�d��Ny�m����ȡ��⣸4�m�Y4O��fURu����<�Po�?�	b�P��42�4/����}4Y�M���>�TX�����skz�|^�V�p���M5J����A�Ƹ�n'�σ|�v4�;�?�;�M8�İ���:��Is1�f�˩zU�Yrݝ���X����Xvf'��e�6�r�*� v��A�+��d�>�(����
��t�n|ݰ�)�� =�}J�y��!��l��<�ߏ��
.��r-v�aj�7�A
`�W](�sg}Vu8�)�x'�"������uFo�.��SdB;��e��`o�`9u-�xii�&���v&��i���h�\&^�|qM��[-�mUݻ��+(�`
���u���@�5|�i����䎥���G{�x)W@�`#y�Cb�6�"���iS%�y\�vĮ�?�����`=��7�i(o�d;�1�����r��{,Ǒ",�]m��`9Q�&�(6�{JO�fjm��m�h�S14�E���pQ~�z�S8v>����h���>�>D�˄d�/⪞[]5?;���|�j���+�	�
�����Y�_%l�*�9R?\���*�rBk�a�X��fy�%n�0@�R�MJ�m�Ĺ.Ve�����Ab�b~/y
ۮ�9���X�F�L�YD\Ă^���jT6�saE?�����?�<�c
��*��J��@+��sv��)ے�*/�0�yA���c��|KL@y�� ��j��!�=���Ed?je�]���+�(:�?*�'�X�ai��eY�R���L"�/ЬOO�Ռe0핣Ƿ��G#��@�=mD
E��n�p|�ڭ��āh[����â��C�����y-����^��o�]�'��M��iX���k.�Ћ�I��R8� �텥��{�M�t�k�a����eq�����ҳ��"<�0͌$�v�-�����ɯ���3�};S� ?���x��=����Z��E	��VFt"����@��������J��iX�m��恁C/)a�������?Z�*��!$��9wUǼz$u�e�*�Lo��뎬	�C�8_Z23#��j6Rέ�ht��_�c!��e�4�F�[~~ٕG����o�ɐ��F��� !�ߓ1�J<fG�����f�|�Uܵ`�߆Ӽ�H��%��}Z|�!���oz�Ĵk	1卲~P7���p1:SV+@2���`�Q�OLF �,۴d[sz]v��$ETy4E�5��� F����Q¬eS�1��'&�ׄ�U��9{�ZOfCh�Dʵ��!8-��\f���s3��}�'���c���V�.���F��DWňr:���8n�1�m�͘�3
x=&��d��낀5?tc�.��,M��J�v(Fe�Y�����|&aQ'��_qV���+b�@#���.3���w���^Z�%.�����We^M͉���+q���T���}uh�ژs.�PS��J�#�HX �]�X�|	Y��"i�v6�WU��]�Jj�骿Mu �>��/(�Z��m���E�Bl�x���@����$H'NU+%H㏿���\Ce��Q���u�`�5?������3��1���� 4=�L/]���s^ ��av��!�<v#lJ[�RA|��~#2S���+���S�;�R��Y�ܐ9�*6��w"D?��n���$䲱��^Y��T�G��Q�}z"�_Ȼ|��`�GV�R���B��%
�v�tVy�[��^���"�R	��n����1���׺�p6�֒�g�巇 ���	��[.ɞ��D�N>�\^�Kxƿ'�`��jD�e���+Ě-�;k�
Y�$1監M"��rj��,Jy�m�m�u�dZ܆����+�Z�e�@Y0r��&X��D�o�P#Zx��z�=�%�=dbz��������y�{� ���
� 	 ��5�ǯCxG3;�j~d�!�K5,��ׇ�작7)0��JA@�^��_?�Jc�M8OqiEv�����xJ��A�l@ i7� �*�Z�fʵ����R��F��	�D����#[7ٚ��$�Z�����и�3��s4?���8�I��'$d���N�Jew�o=ҙHj�݈޿�_&FK�� �yc��/n���̂���&�(�9��W~�����q�?����R�N�L�P�[���e~~WlT�E<�p�ϫ�[&υ���6q ��E|�C讬�ޯ����Q	��l�M*k�	9�N���?� 9n�s2��!&g��b~�nU��_������!��{�C��3����w�c_D��0��&�1g�-��Y'�2�X-�����)U�*�K9 +����D!^)���sk��\��
7�S�GM���!���+�*���-����������D?y�l���v���OHz.#�}���ٕ�Zn�-;r�m��o���h���Q�e�����˂u�_��)R�r�ׅb�� ��DH�y�A#�]i_���~�z�O�*\���{ư?���!_�Ö�7}���Ɂ��R��$%kn#
3�.��nSU,�T�MgU��X�V��hC7�hh���ʋ�q���x$�a�y�Nu>ѓ�Qw�[o�5I)�3M!L^=�4z��7C��z+W�e��>_��lyJ�>���*��R��g�iR������j�����Ɲ	a7�##��s����ϴl�<�����t�o�"_YX홶������>���=`���G��	{:�3h�m(Q�~B!�K�N��fϚR�V����T�s
��ͻQ�I%���gUA�DŊ�_𸉜634��� ��Y��ܕQ���h��\�Ȫ��V�d���Ƨ�����r�>r�/�ѐg�����Q#�C�o�S��m_u'�i����Q�sK�3 �����s$�Oq獾����1�S���\�bDJ�CM1�~���t�I��	�Qh����C���U]{ü���1>�_�O�˹h:�^��j� ���ٯb��W-B?�!8*ջ������'O�!ꔑ^�T�4�Um!<͙R"�E����-#-�U ���&�-����2�צ�r����\w)��5P���iY�|�v��u��wr�J�U7XU������%s��!�f��w���!��o�S��?�ϑH3;����������m��;N�\ē�e���X�������VJ��&k���g`V��{��湋
O��Y��3����лE*j�0!)in��4?OCg��P�Cx�� hփ�ىĮ��%�*��<���Y(��
��IExb����ȓ���qNP��XsH5��BB������(_`/6QߺL"� ˰���r2  Z�:쫣� ̷������g�    YZ