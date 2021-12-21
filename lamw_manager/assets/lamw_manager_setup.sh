#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4122994014"
MD5="dcd93ba75aeabe29329bd29979102d21"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23972"
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
	echo Date of packaging: Tue Dec 21 13:11:01 -03 2021
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
�7zXZ  �ִF !   �X����]d] �}��1Dd]����P�t�D�#����3k`愡��5&/�̼�C�7�l@��YȠ`�|�((#9�}I�
������c����>+�>v.Enq�m� ��ۡ��	��k��A85����w�0#�UO=�N��j�._�	�6_YWA�X99�|����.�R�K�)��lC��Џ'�`�϶l� ��+��Ò1��螚M;m��ɧԋ�$F]�̆7e_˟��D�B~D�۾K ͺ�M�5%Nfܹm�� '8`ʻ�Dwe�<a�W�"�"���P]��r�GV7���V	#%N�5hO�#	������Q�g����l�=���W(���+��KqMY!�8�vĠ���?-� [��Ó���T�Ԏ<�u��K񞦖h{3g��%)a�*����i�ǥ�ꖭ�I���(�t{~K�͡�-�Z/��!f�ɢ����`�{��Yyނu�,�����0�LuK&	�4۴.��8��	z8RU��-�@����A���ȅf ��a��l4l " �����M5�z����x�If�%4��e�!#���Lu����i#�cp��\ �jnR`$��a�2����� �D?��Y�R���b��%��S�����ގ��������4x��s8�y۴4��T���|�*�?���fӀ��A6=0�4���������^QK�=38��V<*x���%��[kUYt���
M���8���Z�
j��@rُN�1�i#��'�>�@��"g�.��T�h-�Mn��=3��J�!��^Π��q�(X�)N�<4�f��ݣѭ� 7��y����3)�j��8H6����F�Q����d���:����75f��Z8[u��C[F��2_��G��0Qs��ky��y9q���K�,���:2/ԡ)H�Y7a�ǚ��ިc[f����i�l,�ԵAH�db��lY҈�|���1?dU~FSK%�^_6_<��ƾ8V���'�*�e�Z
g<y�^_P�����Cbhb䖃Aq](�;����z�E ��n�H�sX��`�`�Ԕ�
��V�r㏀�A�:�l�+����k'G�5(�����y��̪:2�Vw�2��%�N�͢�3�2djp�/�q��#{�Z��i�ڂ�Vhw9&�ȃ��J9�lw���@���FMԤW8��xѬN�� ��*���+;o�;P&4��1m��S���<`m0(��Rwר0dڸG�)��4�c��q5�&�[��^��Cc6���P�t�s����z2~�8�AY���Ct"͉8�0�\\V��<�O�ó�
lf�sx�(xL�1�5G+�f`��!�
�� �����wk�0� �ܵ���i���V���$ٓ�މw����e�RPY��ӷ��elE����t��m��0����)����*B8��U��� ;�$.���R�C�g\�_(ߨiEI�;�!�p��]?x�K���.�d{	#`15� ��I�	�F}}-��
��5n���7\9`�ۨG����y�3Z^\W���?��:ӣ������s��]�S�5����9�;�b4�J �ٻ`ȱ�]O�.B�9�F�<3�:KΘk�X����ԯ�T�+��{�?��l�����]�{���=�~沔����! �(PW?��T]�����FH�{xa���E���u��'�[���C��7����j��m�	�-��mEMB1)Û�A(!]{�'��o�D���ʐ�i��O @���Z���j}W�&�@���p<�*�+1���_9WR��Ύd rz���H<����{x�?�p ����
�g6�-`>h7߾�".Ϧ�lQ�����G5���`Z ����~�7*a����������	�"�DfhAȜ�{��Zj���̯V���ps��in�RMҰO�Ym��g�B��/�d��Md�G�{q�~���l�	e!N����-���K�xAoN��rz�a��x�
���%Ǭ��c2��7���&8���1�ȝ�ᶊ�
��;19�Z(��rS�\C�B#7Q���ݴqoDܧլ<�Y��qJkN�X�	E��s����D\'��{�r�����e�p�#j�ي��NB�}�hU�3��L����h?��y���H�)YN����L�~�h{����o�^㶲=KN���<��z۫�Zۓ� 2 �5y�B�uV�����<�\���တ� �1���G�Jׯ!�  %"��4O��Z�:�r�!@Ό~���e8��<cmʯ(�g0I[� ����rW7R%��:�fZ��̋X\����A۫mK_Đ4C/�2��-�zC<�hr�M��Քc��IXX��	݁v�j��/��弊~C'r�ԍޗ�v�R�0�E�a=`%C}��X2�3�r�yQǹ`F��6��a����	�D�]�p���	~8����򊋯�g���'�j @��`fT�*����r����TX�*j ���W��8�9�nZ*��J~�d�m���
h ����l�0��7́"X�3YF�j�xU�u��C���]�vɍaF�޷٘�����cjV8������|��<x=�^�M69B�Wo�A3���E:7�`�#x�w<�� ��MRZ�B�w*V:P���M�rz���lch��S��O dS��,��9��&�(�0�W��0u�.�_3Io\�w���Rl��T�SD�����q��M�9�ZD����"����l�\e@�#�ŋ��9�X�+�h=g0����$�_k>�	���s��ڞ2��v���ҭ̕Z���5Mbzl)��.4ՃƵoX-��@$Ǯ�a���"��\.1x�a��9ʇ`o�#+wo�d�e��es����q��+���8ŷ�)�Y�|�n��͇��{�F�X-CH1R����{�	%`Eh��kֿ�C�"�]�V�s5@]�,p~�j��>Xi���6X�Jr��|���w� ��KX�Ϟ�>5D@EN��٩4��c�vŊu��(Q�``���K~��J���ٞ��-^$\d����Qj�?�rC5�f�@��Φ ꨰog��4�x�X|T���w p'7kݽ�o��41]��	@�-Dp�mX#^��������"�!j9�Z������$OA�a��ڋ۷wln��e��3����b�ʴ'�*����`�3ʹ<��b�TY���,%9�+�I�z�k�K�;�����I��K�Ǒ<]���O�;�S�W��n�3�u�@�����a�O�1�������Ĭ;#hx�8��(�I�T"f<�b�9�{���DJ�����ce?��.~���_�3�>iV�N&�`�n�s<*���~	(�� ���z+J�:7z����#?s�A��a^B	��Ś�U
}�K�j�J�C���8�(�"9Z��$%�A����ŉ}��Q��5�i�x%�ֶ�lC�����Y7f�OŶ:���j�-y�	��.E�w��ڎ��E���b�EU&w7�!|Fwev�,7�
�Ȋ��4y�{�������N�c�@��C��)V�T{�;�m�t���yX�]Be�3���C��A��߻��Jˊ[a�T�ܰʛթ�=��k��]_�r�VX�5��C
;���~25j��M�g)�!�P~bc�N�λ/�S.+ݷ��������A�>'��?�F�aid
wA Q�h��u�`m�M"[pwQ�fՓuR���2�:Pѷ�?`��?�+޷6<��Db�>�@���Y��d086y�\��y\u�>����K4�;,+b|�EN�A����JQ�
V����[���M��h�4�, l��v��v�(��G4�~2Y�O)ƣ�)u�ƨ��x9�>%���k�ݰE8��o�#�ТX3�.8����!b��L ���{jL��TƝF�9�G��������¼Q_(���[OXs:�$�4coY���
�c1͠^��-����:q�B�췥�)�&�c���F񶬁�+�Y��\�~OW���Z�P'�t�B��_&���!}�ߝ@)Qe5fM�u�Ơ�e�C˷7���p1�� �	9��W<h�>����i�I��e�7^`��jX��|�V�����0[��=�����1�
������eu8�d����f��?(�-�!����9�Y���e�e�m��>~�_	�/� ]3����:��QC�T��yք���kyp��e\�xH�;Gx��E�q�_�����υ;�m�x���M��Io�����Ph��R��C��m�T���߼8�-wL�7�~n	���y��|��/�@ ��(����Q�����w�o���Y��_����HoB���&��/���[=s�Y��޲
<�'W�~��r�j��� .���j�13�r�N����\�v.Ԩ��1ˑh<��M�mpx�W��(�$#�dPB�|8+j����n���,�u��Yi��8��O�m@�?�b����˜���j�^��ok��%�=�q��/.��d��Ά�p�ʠM-�I��+-:-M[�l�Կ��'��h��;:�v�
��~�"����-|;7�q.�aN��v?�:=r�T��ĪZ��3jD�;w����h�;WW��
�2�ύC2�rO���s�����C��d�VQ���bgMk䝴���(����@Kx����N�������.�"����ɻ�şș<�B��s�V��0�M&_��WzS�s
��q�;��L?v"�������eHE��[
"���DV0,qU��-�i0���:�NJ�(qo��)NU�Am���Wa!�'��/p�� qp���3���o\!�����;�jy���!k�Co�"&�N}IE�U��\Ŋ����`���4&��B���5Hq��6�%��VD�G�5�qv����_�&Wj"{��+�If���cv�>������o*Ȋ��g�����E\Έ6*���ďP-��=��q���m�*,�Errq��nͿW�7�����B���H�9���}�O�l�8l�O�����8���e$�u���it�����mN�u������9�ߩq��v6G����2I�;�?�_|7(�)O ��s����WL�6�Ͼ"Z�mS��I�����h��&Es�t�|TL�كR�����=<Q����>�nGx2~�����$�r4�c#Ֆ�Kž�o�9�|B����s��?3UI�������k\_ �(V�?�u?e�B^&�"�<���&�?���;�&��e�$����ۋ��ۙ.\�Xg��� 	�[��:N�ib�B����^iaZ,-���n=��ܲO�ɓ�p��5����ڠ�f�Ӏ_-�:>��0��iV�i�X	s�}�j�-�k��4�D�d�����p7�3i�|ZJ�~zWB�q��@5�+C-_��h����O^q�g=�V�cD��9��\$�R�I��)��U�K�5ӄ�0"��|ܘf�7�It+��������/��D��z�S�jW�O����u��Λ؋�G�đ��F�*Y�p�]W=�Z��f�X�Ļ硐PG�V��~&�y^���-�w�����@9��Q�-ڛ�^�x��B�Rn� �j~��� ���4&�^	j�Lƪ�M�%��E5���C-�;�Ǎ�N__��*9'�;p��%��\eP�۞���t]�����\
���%j��ɪ���8�u�<I,��5T�䅅���X�>�Gӷ{�>tW��_c�E�Y���ƮY����f2Ѵ�����K�4��C4��l���<c9�]7C�*'A[���K�*��"%�0`���T����r@s�7�MWP�n���-z~ҳ�LO2��G�k�Wvm����)K�&5������)��F>	1o�솝���7�L���*Ϭ�j�O�Ͽ?1L�HY�r �D���#}dh�k��PE��v�#���ןw��jB�� ���u�z�	>��R��!(�T1�#^C�ܾhVs��D�OjU��5Ks�2ټ����n\ �}4
q���IML�3���~Wuk��@`Y%W9�IK=�DVH�oC/,���躗�^u=r,+C��Y�X��p�
o�un"� ��@��𗣁���$e�Y>2�\��g�w���	�}G �&7Z-2�31��s�;ڑ$b$�2/�I�b�V�z
�Ҏo��S�k����$���q]�?(> oј�&wA�c$�^�G����;-H��c��u���G��,l��	�q�{Z�I��mÌԐbׄ�џ�7��"
t�a��az�nƞb�	��u�6I�ņo��&��NZ��(�u�}y���ψ��wnea���<�ju
�"�F�w�H%�E똔X����~ J�MxX9�^�6?�?j'�Lp-�L�L[=�d@������se���yM���{j�8g�1�B�8�Ƴ6ڃ��1$x�,Z.�kn۬2��W惒��s���5�3Sƀ_��9%j9�F:`��)�0�wo��%�90T�
W�tL04�ޔjP(ul&�k[�G��˄�ie_3����E~.�P�2j�9ȳE�	�F ��yɘ"P��E��x��r�-k�P�yd<����PdЄ����O�be�$R ����^{�*Ҫ��D��ߐ��&�o�i9��%�.������1+G�d΂G%���04��@�o*���<�#\{M*���3il�������,�#��
6
�b�>�����I�����(j��=�����d�@SXv@g����5�d�3�����������WI�;���b�n�z�Q�x"�خ]�`�'A�|��\�cg�JeCӜ
My����T�;	�&ww*uG�&�%ޗ/�o��mj���Wm�����\ﮫC�$�E#�n��r5��ؤ�-Y���ԛ�+�U����씄D~����\_�μ�oǘ�㝇|�|ꕚ��@gYq�%�!��f Q��̑ag�1�y[㹽k"�+�K5Ir���_����l(�a큕O�^��`���s\�J�t{Ѩ^2��{�i�.7�y9{`���H��Q��Fï�G�8 �`��9|��PYdæ�{P �\3l��o� K���C�~�������ˢ��R��A���I�M�Q=F$� �����j ��pޓ&��Un�8E���H{{�9K3YB�H0��wBd$���)aY7���r~�|�R������� K�����D*NF�9��a�g.�.<:�+v�};�^\<�#�O.��W�/o�:�� �TE�j�Qb��o��{�H��}��	��u6�(����I8�Ӭ��l�������?����_� ڞGH�����J���I>�Hr�+���b��>"j6�ֆ���y��(��S�*�+������&"�Hp���V���_S�1>d�Ou�A�U�8�z��+O��2xӯN@�:
k����C_�&���.�+�B"{��:|K����']7_�s��t
�76���*7O�R�C4���7wI&�a�*��S�(��m�0����]�w"�x��N���\Gƚ�R,�����i��Z}���Ã=r$.S�
���+A2��*��'B���/͇��4�x�^g�w��г��\��LG��F(<�x���Ɠ��s�J� ���&�/~��i@��#�Ӥ]MH5��	|�[��ѵ��Y:�v��lW��"�_ x`LF0�N�Z楗�u�N��Y�\Z�Iz)�a,^�}d��Eu�U�5O�Z@�_�D?��M<����X�۸jf^]��4�:�9@v��P$�Y�j+�������9��'BŅm^�*{ "@��	#�8�����,	K���(�,��Y|� IA���&�+,�J�|����p���.�U�hD�Y��Ca����kW;\�p�8�Iz}��rg������O��`�].PQ��T#߻TJ1T�l���fWH��pJ�Xb�	��X$jo�nE�B˕@���@�T�#��eh�'�'�>tY^
X�Yc��/�2���[��߷/�"+�6)�#�k�/,�}69��,ۗ�Ż6��G���[G> +�tt�F���HL��N��l��|a��l�nj<r�����D�_�L뻗��n��[aF5k��[[�2�y����>���05��zS]|�Y0f��Q��լe��p�)��w�>���!Dl�3rZ;|�ID�`~U�0�=�j�A7�,�sc��b�L���r-dn��\�؅��-1��&<�Tb1-5�U�]�ɝ�ѣk���9�۞���?dτ+�u�m��̠fFF�E"&#��<�m@S��y��W��ѐ�a|F������6G��X*�� ��E@巍��i��E�t;}�Q�}�[�8���F橠�e�g���ʕ�e���������jGεj��"�FԂ#�����Ln����'jq���`hꝏ�5�AlS�9T�j���ˏ�]�}�B8\�N@��i�3%US5m�@���z��"��LFy^�$�_x����8[C����sz�sO$���$��|�Q�<Ԋnw����ʵ��a_��Z͸\T���=DX�$СY_JCgT�J+���5g�9*T�q	$�h64d�j�#a��&��USM'O�X�5}�)߆�(�8�N��|�	�3}���E1,B2�^��a��	L�t]e�yq��qi�NF�,� S'zw<��Zb����FR#y�N�Xͪr�U���X����^-F�9�b4�L���H�/Y�$�4�nO^:��0$�h����ƪS6d��-�6l�ܞٟ{����H6����Ql����p���;�խ<} 
q#�
�x�jr@o�,4#��4�x٫�1[V\�J�A9t�4��!��X	�m�OL��.&�ӑ66�cMʺ��7*�x�Gje�,Rz{��
{.�r�T����տm��<ÿ�ڄ�� �*���s=peJ����f@�^�T%��>�d��d*Q��|+�UQW�$�l��R�2�2�5q����]�r�C��C:�0B��\(��楟m 9?������������H�s\Oc�m�S�Z��y>ʳ�(IOº!4<qzC�M��J#�����	�T�H���H0]��@V�*������_R�js��Q�����Q��7%y&><(�$e��>��j*6���I7Ϫx@ %uE�xz_��A�����[�z�:�NF����-��h��8|6�o������&&U�\)h�H7�k,-GB~0�Gݴ���؇��3a*W���(@y!��lO�B����J"9q�le7��d�ĳ��"]�#;uD���T݈B0�Tv{�"kJ±��QD����h���\RT�(�Xew0�Ҿ�q`��'t����q{<��>��C�$u3 ���tF�R񄭷&����=�%�o}������ʁ��h-��[ugea�[�M���-("��8�� ��O�m�d$���Ǯ�P ����M��6N6��B�z΍�,"�])���lh]v���O�]j��.�r'D�X��>�xaF�_G�8�N37G��*��BN<{��0�nND���JTr6�h~p�ſ���N���8�y��AW���+�8ˆ!�#�V4x��@:T��}�oD�@vm���Nm1��J�[��ǉ��>^$�qD�=@�r�6:��e����n-W�VB`��QL^��V�]q�P�9�1��":��2�9��?!�0������C�uP5EO��'����F侫�ܧ�^�Gȣ-ҙv1�e�x�^�Y�ƶ�%+�\�6�dQ��X�y˼�Cd%Ct�ᳬ2@"��S��~�(~ٽ�5�Ԭ<]�Up���m� BXOz_0c�$�.~%Qx�:�N�3 HЫ���"`��tF�vw��J�fe�cN�2u�+�c%X������N�~�X��U��ԻT�m�/WI`O�P�kh��"������E�:iq�x�h�(LA]�&b$Z����c��MGg1��	��[���g�;z�,.[����Lx��y�kg�3AL�Q%����$�D� ���g{G�1x�Tu�fl���y�k��J� ���F�#HCxV��/f߀|�;J�|u�7��ҐZT�f�\�j���*�g�1�ׄ�50��XK�[䐃����sY��D_����(�T�!�����qn�^�8�hC�r	ܶK΅����˯�r�aI4�F�Z\�#+���/�8(��&�u�Ʉ��m?�Xrc�Y�\��u%` /֌P:�K�<{p���T�S�Z����D<l���Cݓ�^[���KW����6��zkh�'�/������uV&���S��<{K4��M��C���d��*T	r9N)>����A��+�j��05q�[�Zf �g���2�nS�6���}�\�#�w=k;'=�:w�¤;!_���(b��R�iN�q�jp�p/j���Mg:��M��]�"ad�}:E?V��_V,QP`�xo�lAs�1�C���m�e�Ń-w٤Ӎ�w�P	6�O�b��0��O�a��e|_k;���u�Q.Ղb�0�Z�i�w�.VJ�γD���������ᦘ��x�|�g#g�I��^OiAI]ݡ�R�RM�N�P���.��L������+����o}=3~�A�)	av4�*�cU��W	����緿F�H$Ԣr�*��;�%AC���)���`E�8g��f�e���g �b_TIU�D�&�=��4_�[\3}��*!��j#[k�tcY��+�v���Lg�ٹ��2Q�Ѐ���~@�ٙ�UD���^�@^������_ T��u. �`�"G��G�Q-Ic���ȧ"+Nm����������<�e��*�';��ڍɓ����\~5)�L��F����ar]wPL3�^seX����X�Ȗ���t����v��]�o�χ�m�UF��p�2q�8��d���뿊֛�>`k/��{�������Կ L�h���Q8����	�ոZ�@�~z��Ѽ��i� ��?j�XETןCg�6���z�<��?�VC�_3��Kჸ\�t�9o������|(}����雌p�$�yФo`��v��t~Y��+�D�GZ*y#Re�B���&+3�d�h�Bk��������^�����8#�6�&az[�����Cj-k�CF *���������:ި8Q�&M�dԺ>�0Z��%�8GE]|�YZ��*R<g�F��u2N�^�åK0��V��{��c\yWn�st�L�E����e�t%_�9[��1qI�ւ`(U�9m,U�b����ǜ6$E�$�&�$�۵�;�O�d���x~�q٤�Ŗ�]�K�`B��he'��� �k�}Hp��@����'� E}�hs��f���S@
 RM����*�+;�{�Eߴ���x���џR-��yq��b�s��l ��E����H$z*���Td�� uɃ$wP�k���{�����������|��)ˀ�ָt����-r��Z�`c����⚇�\�f'�-�� 80�n�)#�+E(�F�	��6�cD����,\���J��-�H�V�H��[�Z�ee��#�phaRf`��za)�~�9���Vt��~3���.��*��Z
��E����IT�aVh2�y�S��I79��LV�i�	*��]��.h�d�*���PdO�~���U^���c������� H���^ �W��֭�7��~���J8⛲>�(�n�h��QV�/�ۜt���J�<��X����6
U운aR�l�T?-�ӵt��F���(�9������|5³�ʙ���D�-z�{!�U�ܑ�b�G�J�����x�ol����h�Y{{��"cPd���8sdGNHg=E�Hc���
> ��8'��Ċ���Y��W�)ㅰ��`G'W,��:�B:�s�nOH�]�����s�<2<�ܫ�@�-�����\Y�T�Fq`;�EM��]>	.W��[$�F�R�}CdaX0Gס\��]B�.�A�o��/�W��uT����6��$׏m����鱳I�`y�1�}#�3��~��@�������g	��3}tL2� ��O��e�(�����VE�:��S'~�+��Q�~�:5qN���"6�>F�y���N�̼�a�C`{.D�����G�T��q!4>�Q��Sj�)�\���l���#Jtk�~:�!�6�Ƶw���:gP|�-
۩Вs�a
���G�����sr�c�΢XL��eU&�ɫ�W���5���H���%�S��)߅����%� �ЂJt�Uq��e|�+J&95�Y�)�^Ͷ˞�0~I����@N�xP�
�Z�e��}&|w�w�O���� ������ ��6[*�dV�I��=��MBI��,30��%k�����rͭy'���V3f�V�P���f3�E��˭����0��D_a@�t��`qk�/fj��6Z���R$��Y���t�j�V����d7dn$
͉%�l1�����'��\�S�����B��8j��5�yX��[�7�v���TT����3ua.��T2�ڀ滻��;�m�q ��
j y94�foA��ߋg�J��0{���?A[g������jƳ��:�K��a�v#W�k��q
ʶ*�en;
�l���+�oyh��įv\�9�ZM�Ze&DUcJ�y�����v�I�m���{Pړk�
��Žƶ�g�W��S��q)Y�ӳAZ���g��Dڈq��AְjI]�q ���#e�oTq�e��@HUd��Ά
�I�X9{���;�Qwyb9O���A�|�c��GJ���Ap�A�,)�и� ���9a�/Ŀ��i�5�
TG�KJ���yJt�(v��2� 1	����M��#�Z^�R�[�͟BA��y�(�R�� ������j��w�4fQ�fպ�M�?�9�h�ж���a�׬����F�:v�F�*���!�Ngu"���Q���<Eh_@��!%���ltA��׉A����[��=��t�n���`�X��F����K�_t�S�_X������81�}}��K�JhL�� (B�=)�$���\� �7ܶRԝ����uZxn2�q5�������ium�^����ݣB鱃�4'�5�tԃ-o�R��?Bd+����Bkc��J<�FP��8#-����S��a���|���U	�JZ�,�1Ȥ��@ѰD�ן�Tl�d�`܈M��a����ʷ�����*Y$~�xz�+m�w�W󜸍pv�ė���ڰ��	@����R��D��\XӽY�,��)~VڽGʭ#���	U���LE|
FFU��Jh�� T�c�(��"����r�L�xh��:�*̉I��{���=����~X��9�ާ�`mF�ӧʎ�rU
(���;�75>��gaF���?C���X���Yu��H��=0���u�h^�\х��?[�U�����I���"�S��5�'�2�t�Beu|�)Cၷ8s�ߖ��
�~��p1vhmBS����ѹ��1�9�Ҕ�h�WK��Lt0���~U��0T����q��������|���8�7���������_|�>Ĳx>S�2�饯qm��z�6t�?�QB�j)D���51XL���7z��-�_" k#���JE�B��"#z��<��9Y�m:
��ͨ��#����Mk<~���$a�W��5�@�9G���u� 2J9��Ve�F�#��O���i�/9!I��;��\���Y������o�̔B�@RqA/�!s��MH�G"���_�YXg����c�9���F�J���"&.u���I��j��짥�s�79N�T���?PP�!
'��`�>�M�/�-�	�<�=ih��y=ˊk��BZ�l3������x�M	V��I�"�j�~��i������`)�Q�ަ`J_y�L��A$��Y�9ѥ�ͺ�*�f��#_�;����h��ְݮ���X��M��;!�p�fT�����E���ڙ�t��P��^�s��8Ď���W���XN�9 +E]�\#�*�1cIQ����B{��F�$
���z����b����(06��w_dy^+���	���	����a�^P4T>S�ׇ~a���ȓ�(�x?cA�B��!�{�bU�7��9Rf���UE�-n.�J`�a�g����gA�@�2a`�Uʺ��+��j�Aig���N�����93$m��ڋ�1y���r�9��xT��3�WOtY�4�t�q! �t(�"��$�FX�Q�"�B��hD���x�E4���W^�v�Qu�m�Շ&w�%~�6_����r٩�eC������b���?�'j�L��k�h�Mf��2�F��bX#PeI,�?lc����׉�d��8��fk��yn�0#��n�ǐ**{(�l����o�<�@B�V�+��ܯ�J��w�{'{.f��(�d�y�JldZ�+��(����ł�����T�D��F�|RM3�1�p� ��b�M2�?�����`m2��-y�C�2$��+��i,&+�M��b"s�H7tˑx劚�P�`�:9�C�\B���l�	g�?��[��s�輡�>
��������eY:_`�?���h;���&K^��҆+�����8��O �{j��9������-�Uí��]��92��v���Ѿ70S�pK,�y��᝛��x��t�*~�@DH>��*�%���y��daG���JU;�˘k�F�^�G*y:���S�7@e��5�,��NٰKO�e��:�o)`&�%�j{��%ۤ�=� a~j�>�Tvd�yg����n���rs	�4EXo��I�[~+�=k�FJV������a�]�	vm=�cDܠ���5ម�A����H)�к�)>F�
_bcx����S�ݸ��"�׺���
myB��'�7=L�?O�n�����X����g4���o,T.2� �X]I�.ljT�P6������GA�����Tu���\�.F��?xW���M�eP����U�	e$U�$�&ڒi�� daJ���0���e\��f�ԃg`�]Ί��	��ٰK� E*�;�^ ��^o�s}D��R�R���]���A�juq��R��zP��璨�TnD�9�,:��=O����[�d���Ha=H��.�`{��Z��;��Ń�]�H�B���H=C������q6�'�:O~a�:>�������Y_͐�#��֣
� ��=$>l�'��"\��(�!��jog���.�B� Lu���$���������_l��b��K죢�~& ��t���
�}4�v�1�P'�z��pz�z0�Tth�Mu�C��<aQ��,��kHʻ���$�������rA)�5�6M7�L����-�2��Xd.�F�~gF��M�&�u�?�7�(
�h��������R���PF+��L}�x����.��3\[������"diR,��U�Z�����E��gT��;��&���d�Ӛ�˝�a�!��N�S���HՕ�� �	H�0���?�BpA��W/"7����L}rWNb������;����5�� �`w�����0��ת�|ʟA��AR[kw�q�t��Vo߳� ���NM�p�~�JV4#��&/�r� ļ�"�(����
T&��Ǟ�>���Ӌ�ċ�OF� :����I��`V�����fAۋ�b�]�>6C~��-?%� o��>1B7�@c?_���M�� �	sU�A�t�7(_��k=u�����\�ZU65��[�6�)�(�2uT�!P�Vo3�h�Q�ԁ�.7�뻟��T5բ(4>�7h-�+���aa-�%;�7�b�H'�C����D�F"�w�.fdb�f��p̲�l'�%D���6��<��E(@�Z��� :�w"L\O�,4�)�_�ڐs�/��p�����di^ �.�P;c7I��yqn�,��d����ϼ�':�_���-��@�-��0���Q�ȇ_d�����Z\�ua�8�-�E�G�a��R ��$Z2]~?_ȡ�x?�w�T��O�Q�)�D:���O5����4)�Zb��ʶ_f^e�;Tm�ݓ��#����: Sڬ��yO�Y��}>�I(:�>1�w�dAM�Rd\��4�X:(�#���~c��+X���W�0���|����|��!W��"UTC3wq胙׈��G�A���ъ��|�/V������iv�Z�IE�� ��Tg.����/Q!>�3C� ���3�`V>QUu�^�-2/T4٪1#W�$)��:���r�":�s�=#�c���nD����$.�ڰ��B[�w��o�/�TC��Ŧc:'NX�ۏ`��!35�Ь
��\�FK�	���V��(G�\����n���II�I�B���b$��{ҿ�q	�O+ur�d��@���[�n�(R�#��ޛ��}Ƶ۽$�@U!�/F��Fk$$e;���b\@��$�!���$������5����[�IY��A�~��K�ؾ���-�JBj|������0r�U���V���E)=�*�$�i}{���3�{2P�f�N�n�f���n�p�R*t&��	kWz�fV��rng�-}M��ȇTQ��(8�;�Z9S��\�Z�1�&"O?� <L�3��ه�+4��g�r*��2�Ò�i�h,\Cm Bކ�+�8B�?���"�Pq���jDv��!�'i��q�#���ʊ��T�f>mwK�e�Ǉ��K�%]+���Nx�w��H�H�G�At�p��^�Q�Ϻ}D�;�8��1l��m��\3U�.��OK��m��P8[p�X�1��?~a�f��PQ���K�3װF�������Z�jx�R��3���c&x�e�beW[)-O�m��F�mq�߃� b�Ԣd�S���n�#߬�>�g�����O�ou�{���n�����c�M�3����F�ztI�D�4\(>���p���w���uPrҲ�>�V+��p�Զ{�&T�����}��b��,�,���ŧ��җ={��dѶ���l��E{����ԅM���D���������f7�#��z.4� �,&�s��GY��% �}kㅳy�g~Da��6���׃��m%��\l�}>Zh�20��wɋ�8�;X e��o�.���g�Ȼ��B=(�8����׹�^yӓ@JIQ��r{XZ��7��}_�J&��ƌ�?q�QXq�^���������ͧ�j������Z�	\Y�|El8��҈E��;@ܸ9�qs�=���@��4�)�-V���`�$j ��,S�]�KI�/M��5��>��t)=l���AI	�M| ���4}|���(d%3�	���=���w�{�m�iٓ'y��u�@�n�j��;�K�~FTXD�w�x+��b���w�o����rq|���ޅt���kf�h�Dhs�fX%Y���}:R,e�~b|��3��"�s	�xӖ��i���`�+R?'PĿ��A�I"�5�w9+��<
�Z���B��� �:[q��P^�q������C��a��lx�����?(B;UbGҕ�|6��tN�y��[�ְ��Ż,s�\"��9uClq���Q$�1u�����U��o�PME��J������A�)	L^y*=6>�-��F��*7�T�T��>&�rt}��Gȃu�B��H)jiJ��dE�d�g0O5%��?���L��k�$�|��r�h�f�|�fh�X����w@�n5�G��5I������zb����(g,�Qjt\�H����M���+�*��>Q�@sD��_��e��4��x�<�@�,0l�2�l�/6�d�����*���n�7�~KGq[�-e��^�@T�nd.ތa�/��Q�&�옏K{A�v�̂�����5�5�����U\��d�p�����0��=��wg��ۍb�j�8�U*TX��;<.u��}7*�K\�d�ԡq����9u�BsH�V��+�0.�ˊ����F����kz��ڢ�D
��V+(��PEe� ��ܩ���W���8e���?�Dd+g5�:��#.C��ۥ�_ހ5<i�(�)-J�����Uf�����R^���O��o�6C8�kg'c䅿�^E���)/��/-�{3e�������8�B���C�@�7�^��f�N`}������.���0��.w�YT���Z�Q���M��>a�:P��I#��\�r�$�� W7�=hpE-�#��݉������5��솋��ܯ�D�s'!;��[ᇟ�O ꁰ������2�Yv��A|��P��m�E�N�!@yM3e��
�\����d����tm�	±����+~�rR0���ǒuŖ���8��
�q�t%��0p{9i��G�k侞tT���0�́�Z����*��+�{�B����t9v�J��2�f�Aq��o���0�ۃ�C}�n�� �gC�
�5��`��:|�b��nH`�|:��.c�D�q����R�Thw��]���eY\o��cN��H�'�l%�7J�m5�/�wӗ,d�׸;x2Gy�O_�f����a���M�^r����'��$�Ð]ƘR�':���Z8����_K�|s��g"1w8hP�O=G�4�puy���,@z冝���n�o�2E��|�7��@�m����F~�E���"f�i�ߵIûY�:G�k��>�jT:đ��[?v��d&p���ˈ����Ef;�T6�02��u���:8�Z,�s�Ҳ�<�%��.�9s�3-,҂�3������]0Ouz����aR
'�.
���D?6�K�x/Q)~���Q�H{�:M��u���sŕ�HS�>m���%���?^�UX���z������<0�ߝQ(֮�J;|��O��?�vI�-^�zH�#���~�r�nqL�	�y�et���6�8�«���`�<�L���:6H�W׮��$��g���|E4����Y4S��9��e����LZҋJ���b�x�*��TY]hb>zc���R���DH� �T����Ŝa����Zɞ�j���9�`v�J,(${�{T���(�&9���� 'ҺF������B��ߓk]��}Cn)	�����(z�*���J&|`+�|�-�/�=�S�n���;��g��U�ĥV�ȱ-T�HV�9qMU���z��>��$����"�]�k*�~�q���G��N6?iE�x�ۍ2�1$#(qV�4=y��oj)6��?�<�Dr�}9�A��al��?�%^�T���	U�0�<�X�r�ת��c���D��5���R�B��r�Jf(���撖~�h�0/e˲3�8�&x|D.�3��8�N9ƪԤV�^˽��$���/��+�]Ǟ;O'���y��@�.��/,��Q�	��N�$6���7�u�Rnp��;���4���rP�&��ޗ��-�/�D}'퇉a߾$O�n�z輲�{��uu��TO�F~��HGS���,~�ؒ�)h�[r�p���]`NY�a �0�8�M��o�����幊5�,|�G�)s�=�mFۇc�ڃ�=Q�U��$7�1�;O��S�8������jD ��~-�/�e�"A��~�>$�G�"���9�[�bL��L�u����N�0��}E��[�YVO5X�I�چ{���۾�[	�M�mq�nk;��1��:�� �B��t�M]!��U��8X�&���O����4_�� O,WJF�}��X3o���'�@�0U�������N��DOd��|45����I0TG��s4|O4��M����rmò]�K_`�y�G� 7D vMJ�\�����P��}^�f-�-#H�T�>���%�����ffY��`�R�^3��p�E~ZN����^=)kX�$���]�4�uj:�UC��lhC�Cf�WCjW�ѫXk��F���Y\~��u�-G<��G^�ݗ��F����?����R�K�#%j݉��l4��j���e�s�:�Qb;�;���<����n� ��MvٚZ�4����aх��v�(����떳���*�|-�4� �x��$)�˦�t%i��_���Pp%'ѳZ`!�	fB�賿Y������&�S�D���5C�Y����6,ҏ�8��8�bw�/ep�u N�|j����U�� ׷�Y�i��g�G�n�**�W?\��(V�B��� gA.�Eg�\[/�����8��t[���I����V��Z�rx��:ߢ0u��L�T#ߕ��/`����A�
"ɻ��G(�,�kx����V������ϖei�[�s��G��P�Z��ca�;�2m����U��A�1jŵ�J<fVQk���	���5K^ ��|?",m���1���@�W�+���d\dZ��S�q%:��hm{|,9O�)b�͠���	q�
+�C�)�^�d�?&�>����mU����CYɾpM=\\��^W���j�j�|�Gw����L"����ȿt�\�v��5�AҤ�ő��H�^G�]h����� ��{5 ��R�k�/Zi��ЮB404���-� ��������4���Ģ�2���f]t��4;�$x�c�-�-n�0/r��"kV��1V�Z}Ge��v�z6�V������u��c��$n/˞I��7!l��\������}Ķ/�	d���'�hr�������y��i)������(����yWN����)�U�84B<"7TG���ۮRd#�U#���L��)Er��1W��*S��0��"�7Lݬ۠�7�:�'fI���c'��z�&��b�;�B���$R2��s�γ���Ye�)ըw�[4�(��^�������IH��ވ���ɧ�
D�Fb&L)жk��h���Ģ�#���y-��nՠ���ph��>@�P-�Y���n��E����-`S�9��hc�c[�	�N�mw���B&&;J�9iOZ�v��r��<�΁���ї��su#���#w^ϸ�)�zq4��@�e�m��/�5'N��K��Wqw�X-��kږ��/�eL���>�J�{|���}�8�J���7{д�|���I�a4b�=���>$T��;wJ�]�穅5�S�H� �^�9	��'6���u���9
�T�f�}���Y���q�p'��n��jm_j^�Δ��V�ބ��5^�i�CKOFGc�#�|�z�*����n�c�U����&a(�R��je��crs�x_�)_���\S�H�늿A��QF�: p�Z�|4�h�;3|�4b���g����c�S����
�[D��]��O�f�7��rQ�v�2���ЖM�ғJ�?H#�<xw�g|�$���߱�
�{�al��T׫I��0����łS�����IW��fD�z��P�sJ���Q�;�V.vV�0�����)��SS�� �3�¦��-IQ�.�i����`�� `<է�2��cN
E�sͧxd�ڲ�@�)�Hq'�MQPz
���M�vc�{i�k�~�1e���ȾY�;�� �k��pr��xްU��v��/��IT��!�`��rK�����N���T�՛����hmB;Q�|ȵ��e+;G*Q�rD�{3��w����>wadCra80]7?�=��=8C._�t��S~��5Y���ڶ3v~a�˵4j�?.���8��ui2�.'��z3���2wC-����i�#���_����g�jM�9Tg���`G��|�f��W�Y(��� ��θ���&'���k���I����֤w'��r��J�4�{����0����,/PdH�;��.�9WLC�m�*��G��;jLM'm# 2�O�:C�:��7��Őg���N��P��I��b���Wo})\RU`Oͥ�q��1��u���n��P����fQ�Y�cT��	g��m�q��xhnbA�h�6�O�f��³]����q'Zqh�������F�ƛ/����T ڻ᙭���}�/+t���E�p-'G5
��I��C��Z<ێJ<�l��2�j��r�:�e3Á�
�'������L%eB�^�vNɦp�A@ޟխ*s��9�swM-���(��2�?2.�D�(>��e��XofO�[?�6 '���A$ϼy����*����Fz���)	ȓ�7��?n7�~�{�:�"<ߓ2L�W��3_,Wb��kT�����hF�χ�tqH��[3�����Y�
U����D�->��3�|2�} !PVM7>,�v֬t2�-Eʔ9�d�"��J�+��2���
�F\�Rx��N�n�ND#z)/���G�k�n�$)���j�� � ~A2�������0��g���Դ�����3:�y/��ځڧ,j�z�c�p�а���1��LG_BD+�É�.A=*)C���������B
!��b�#�%ܺ���0�w�&�����~�[���ES�r�dB��'	g� !�@ޝJ˛�~��qJ���o�T���: i��`ǧh�kD:e鵕�s�:3��������t]a�?3ʡ��C��3q(Ѵڈ�<ܴ�_8 �*�'2���'.I3�YO��&i����	��u͠С�U�9�����[�dzDY��D�5.,�	 3�/�++����9k8J�KǀG/�`�nBQĸ7PH���x���*�9��ӡ^߯(�H���Gb�Z��{0kƄ�|�0��~�V���A ��9- U�g:@;{��n0Wr$U�����������5#�SO��A(w�Z���3����r.�<��T=@e�ķ0��B�z���m�Bi��뽷x6����wi&�K��ZO%ᅙ�v`�iE�8��cB�Mq1@�7����?>3Cߠ�m��w˿ܶ�n���Yp�������1D7 Ρw��(=���Pͬcn�8��,��gy�T#1�[��6�������-8�\ ]�V����u)�.��ȗ�*ߎ-9;C�}�k�4,ݷI�ٜ�y�K)dE&ά�n�#�I �kT��M˨*'I�����lZ-_�U���"�M�{�+��>s8�Uڋr��O V��/{s�6���0Y���9)3Z`Q�tՅOY�J����T>P���x/	D��;8@���A��=C��H�{����yø�Py���܋� �h��FK2˫�J?U	�(
�F�ژ_������!��ӿ؊��1KL�ѣQ?���ٟZ�}?�'KC&��fa�Ax&R�Λ�^+l�լ����=%W���0ѽ��h��D��uBo}Vx0x��b�|ց���`�{����~�I_>]t�\��G����w��Q7�J�u��Fu��q`ِ���3�g�Ձ� �
�&S��]�|��Zn��	�d�Y�b�������^�5���nP~�(���VDr�A���RVH�H�[L�b��r�O�D������B���u�Ԕc;����Zu���^��+�,��#!�oV��\o0�[lܣ����3��-Ù�	&4e�E0��k�Z�Q�]���U@�	@����(�?�qK�����.���2���8V��������x�N�[2�X�T@�&D�;��\��k�"�����A?_P&���ީA����V/~7H/�39졟�ev�fKH�ٙb���"nK� �cP�4��{�]��X��W��z��M�Be)!���
h+�x�!+�<9���@�~m��	���z~� �W&4*X�����#��K����:��ԩ�_4 k�d����)M�T��0��K;����jX�ݳ��v4N�FpQ�+�0~=@Z\粟5�o��P9�RPGc�B�곐��N�M���%A��Jr���9��Ԛ�r�Bh�YiMm�6�*��hM{�%�A&���*͋V�L  ��
`�� �����嶱�g�    YZ