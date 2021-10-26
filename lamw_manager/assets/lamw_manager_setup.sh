#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1797198962"
MD5="d0239848d06c560b40cd60a934ae0b55"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24168"
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
	echo Date of packaging: Tue Oct 26 00:01:39 -03 2021
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
�7zXZ  �ִF !   �X����^(] �}��1Dd]����P�t�D��S������!��� ���v\ۻ���E�cq��ׂ��)��B�k5L�{�,9*��)�ܛ8����(�,�� p�ݘl�OJ��j�p�
�%"�O!e��|��C,� ��h��چ�D���Z�3a����#{T�@�-F�S[�,�<<:�>�����9�KO�Յ�q�(ү���eC�th����R,pL�x9�r��(����Zo�Gepa�X��`�֠��z6����&&�+�u���j,|n��aE�!4l��5�l�D����.�vGa�U��·���!h&+�5���s��2�	�J�ʈ��1Td��ק�k������(w�TE~%�1& ���T���Q@�4옻���j��5p����C�B.���V�$�f-��Gc���Tno4f�1Zq&�[�|k�ݪ~\���)��|c
}�̙y���5ڍ� ����S�ǎ��,4 gp~�.��h�'4I�KӨ�7��M��r� ��=��/�+,�@���s&�#Cg�}�+ɼ�yZK�6 a����`>Rt���e�+��Ny��䦆�z�Tj]��*��S�h�}�5^g�#-�,��@8L%3�t^����F��t�e��CBJ)p�~�d>����y������k�F�
kid�	�hzS]/9���)�T�ɵnwZ����9����]�eT�	�"?ғ�Ő��z���gXj9Ҏ�� j�g��5��������)��`g�����`��ZA�1��z_.�	�x�٪^Yؔ�?���C��3��|
��s2��xlQ�=��}�T��2s�r"`��Ťq�0?/X
� Q,'ĺ!�>�
���>ȇ�{|l����V���E� &�����}�l�ʦ�t�auZB�� ��4�R�!r�U�Su�w �6��#I�{�ҰٹIhF���_�Y�Q[)j���Z�ny-�R��
�׿-{L��`��ɸJ���v2��)I&3�?[�_d|j������ʡ����r��n��}Vb���#�ɋ�Ӯ�ڛ\��:��Kh�F���"B���k���7}PÃ�j���@�z���@��U�Z~�;:�c*i�@��XM�׹�{���]i���"8��]1'y݃�"��X5��� hyg8'
��&&�h�JW�Mw��hR�����S䬐�TU.\]���~2����/���j���zH�t�+ �W�m�\��RX)1X��U�&$����.���bvNcªr�'Qf�|�$���Hy�0=- d�ApQ���q-O�j��ܷ��aei��*Q,�f�ĲV戄ٜ~�6����.�@W�E�T�j��E�"��rh�_��5����?�lA���m�T�?��%"��_�Pq6|T��t�LI^��Td�sD��>�fU��:�U�_�����>0\3P�����Ռ1�Cu�l$!qf�V��5�E0��d����א�Ȫ�]�f�����b)gp��r���˃N:��+f�&.���w	�Y�}����b��%��"�`�3s�>����
�g)�ޞ(w|�B &��i����eL���kɈ�0?�x�0�> ���:�լp�=X{�L����m>h�^�Rh���c �u@�����G~��+�U��0�mb.9k�1�2�����.L
��Dt��B^KW4I��[�O��#�Op$�Nj������g2\�$�,����#�3ϯ�z�N>&��PQY}�z��n���D�<Q$|��^��$Gqk; Q�\,��c�MGK���e�ӕ�=��Z�/}�y4>�����~�"��-�A�����5���w��7�n�͉t���J�6Ħ���<�@ή�nQ3Ѻ��U5j~�q��J��"��}w��t�A5���06�f\a�Zd���B��R����%�6A������ԇi��\��~b����W��yl>ʛVz�(�,µ}�QYτ���f�O:���ڈ�������I���Kd3C�e
HƾЍ����zP��{�(&���q�D>�em���K�ې�8���\�W��Y��Od��]�Ca
,;iX��$�W������C��dQx�oO	7���%#ZȀ��t�"#����AU-���#�+yZ���PF�Go�D��� ���ddҏ�����-x(���Zr�N�6�Tt@���$�.��i�Vr�-����(�nkLzL|}�{\�;
�
��+{�ڬ��KR�>�N]uM�ԯ��}`@��x�۱�/2n���=�r�&x��/�z~�[�2!�EL�D���H��J."ܡɖ�%fiJ���ja�T��/Շc��E�Dp�k��%W�����s{��8S��B+�_���*z菑:p�X&"mg��r{���	�p�2��Qg���	o�O����_;�6����>zJdiQ;YMxiPh!W�B	.�b�$���3�L)��D���(DWЃ�O�2��>?!Q�6���ޖ�(�,ֲD��E���?���ap>Dn��Ո�U�W�6��ƝhP�$�M�E$�m���Z������UIOtL2�V�e{S�=�^_6�2���5as��k�ɘy�"+�)��Ԑ���:�7@d)t���M���[N��4y$�ٻ5%����,B�c����͍edy�P��P���V.�hS��m�t�  �M�y�$T��^D�2e���YLN�be�mt����[�{�~�\:�J�f(�rf��Al�\B��I�"I�g�<�ߖ��u�%�M�d���J	��Tf}��_I�L���9Ze6*j�@#}i�B��u�Ff)��1�XVL�S�,Z�l��
�O�'��͊�� ���l���Q�1C�h�df����;��qh�]$K	��<m)-n�����!E�����h'i֜��b�iRO�]��E��ڭT:!��E� D�񦚂���+YƇWB)���킏o;y�dޕ����j�_�x97�Bk�xg���F$+���R�Eeu9�"lW�Z�Z���!q�ՙ�s{vq�F\
SͲj�8�A5}o��VD�}��n��TO��PZ1�"B�'<ĩ���#���E7��k3�9mڱ�A+��)Qʭ��ʩMY媤$>9�����Av��pCDRo�����r�l�	t�ɹJ�%�n*�b�yۆ��ڎw6�G	�y�ް.��*)?�#���	��3=���y:�o��X[�3G �IT[��^M�<�o��R���}��1���D��n�N��
	��b�-��V��T�F}��,T����w�}��T��q���ϽbX`��-�P<���FHѹ����Sa��z�ZJ�(���ܜ;
�Y[F��A�KV����¦"x�=CX�����OR���I�A�[���/6V~���	�_D���tr>��#7숬���G�(^y�v1w������
ۨʣɏ��׵�O4>��<,�ljSa4��D��@� )�ݩ傋��A�;׎��Գ� ���gS�ߜ)C��q����ۛѠ:t����:\%푋6���.��L�pi�5�/ʩ( nQ/wW.t�5̍�ԍ99�Ҩ�0�|�ƫ"�Wu$��?��)^����pK��6��,Ϡ����%'����)�	�'`XCK�J�<Z���АK�7m���I)��㼋ͷ��6XC����zɤlJ�I7C�k��x�V|'/��ߩQ��u(uq����Pn��0w7�b��h��/�b�y"�5���,�gʗ�$�jW��xa$EG"�X 5z���Ө.Qh���5��Z7�{���3j����:љ�==d�t��D�(z�X��:c����X;��<�e����"���Y��ȁb-��C�?o�d,�o����<�H65����
dNЌ_Z+;�B����j���H��?�h� wC98C�� �v�c��6	lLu�d��?��=��3r��n���ݔ)�9�	1p���s���e�^�`X}�}0���̗}VC��K�M�r�N����]�J�"I4V���t�.5�,��˭pM���\
���K�w�KT�>1��5�i����B�S�P�"iT�xl�F�M̚ʗ�e<�>��U�s#�HO�fE�^G����^T������r�a�F�ꐚ1��_���^)����T����4���1�〢�xDC�7��;$�.i�o�<�Tu� N�oV�R��V�x;K�=�7@��e[��-]գ� 6�ԣ���쳎�t����bȓ: ��0?[�ٹ��=�2���u����a�~_2�c��^ǽ���S7i�������Șr����J9�'��;�w�4�#T�"�	&�jCh*4WD
��p�-r�;̈��1M��3�b6X.�G� ��(=s^�ާ�:C̭5u)@u�w�>g��GXl�X�[	���4@ll�����+7�R\���Â.31I��G�!��q���t��hG<��
�Ͽ��6LrE�� ����Q4��ÿ2HuD<:!��P�3#7ʧqX���]5�f�M�)_Iֽ���Gs�@ܠ
�U@�Ϲ�ԓ>ـL ���\4��4��9!�<7���HY ��%������f�@
��N�ػ�-i��Jh�$�p�bJ�Ig�X�|�r.[j+�]4��|@�@�+���Þ�5�(15cؘ�F��v���m2�����NY7���3������jܽ��zU�����?'��}T�Q\�2�⸼���߽�Aљ��97�iAf=�낲��A���\�ew+tX�>�n0ep��~��p��h����`�D2�k��a;}q�
wC�����q8�Lχ���X��L�$B�޵�0��.�be�M���\��W������u�X�$QzQ��M�#��
�K�uIL��K��z�p:L�O�R�ҷ�eq�f5�� ���`��mkDg��{�v�I�/���{0G�DI�Ñ��EQes�����F�Pa$�&�r���;�L_e�� QVc*�)�{��i1�aY�����*�r֤�a5�@��	��q���a��'|j�ֻw�׾Wb���x���$�v��ʴXb�X�峕�2�x����nn�>���$��kT(�"#?�����x4EJ��j;05��D��-d�6�i�t���E�U�c�^���v�T�ћ����e��__�"�]�o,��G5�5Bc���M\�KP�Hcp/�|{�%c�++�"M-�f� IJw�]T:
�=F�J�ȯa0�,������r&ڈ��W1��b[[�m�@Zr��C���&ZO��uGN�u��M�-o�{M"K�=�J�cV0୴�K�*�� �yL}�(v�K��5���d�	=�mB���T�b�<�����Z� ����q��x���J��9z�sewq_����2Bį�hmT�:H���wމ�ԃ~3"�&b,�r��1�ؽ9Y��7���yhU�ho����EBY�r? Ā�D����� VKH�����Id�ǘ{�-��E��3�o�ϯ���-��!��5p��`���$��{��x׺��ĖZfZ����8��{1k%�L������?�ӷF���F�Km��]�A��p&����#M�r���@6ݘ�p"�����6䙥�'�KC^2a0�HM�'eo�_;�_�����{bf$%N��͕QK(��[y����K[�CVA+4�#2����Gד"���;���w[��5k�p�&7�x��)��v[~O�@[āp��e6s ���� �E�c���$-�rs#i6�ae��+��L�FQ^ᇒL����z�YJ���H�s��y�\ �"UZ/
��wު����On��{?Xo��;נ�Fy�)�:P�?��I*ZT��+),����!��_���$���hr*/!���^R��;:�����YB6�uwRwp�"�����ג#lz��'��w���y�S���g� �C�O�ae��0�O*�j;����a˦�-B���1Ñ��}�= �-�L�s�j6�����m<�9��!h��FA&db���)�j�.�K�d��i7�cʱB��.� ��܏��[ּ���*��Ǵ[�޲�."	VV�z�>��=4W&١Ł�FΔ��o'؜��]���c�]���7b���@Ni�$SJ����N�h�<t�����0B�����,	_�~+��;7���-��)P�����Abv瀖�t�Ҹ����{�����@�l�A�SIr���i�]u&�\�y�)�F��GXm� ��8��J:�E�ņ�U�����u��vO!�C]��Ԓ��5�GhHK8h�������]x�p�����["±�ӥ���_�㲏�f'�X�a�C����K*Zz�c�fN@����m�i��x�����͗`�ٴ�2�9q�yp���b�"h�7򨞤�-�3H")
��]ǘl�𯊃"���4�w�9˘�ON�4 J��I�Ձ�1�EDry���:A��Ѫ�oH*̔=�v��M��(���גt�� %zmTv���H�P3��<�D3���mtn�	<5[ ��#�: �'�o�#(1�7>u��fv�7
(���,4�[��cG$�ӏ*���O���Z����Pra۪*��T�>7��i�m�3��v<)[��9x~�~f����:�$+��:��>6D�py�=��o�� ͌Z�+m��	t�H���'�A�f�R̵�y�k�Ƚ(�a
�D��@��rXw��}0%0a���%�C�D]��~�ǻ�d�xq�Um4K���ضI�˒X�-!��'v3�r��ͭH[�������Ε�Sxo����w������3��S����Z�A LCB+�^�0aifY�d���؅�¾n���-8��:]j[�t�g�	omL�85C�6W���i�h���A;�=�BE�R��}q2������?�_A��j(���
�:Ekݔ�O����s+%��(��2�)�H;�^T'k��J�_�o�Qy9����,�`Fje����G��v�{�T&�#S!���X��w����ˈ׆�#3/S֓<q�!Ht����V����q<�uT�X�ǉ��ƽ��5\=��@�;��O���a�fo��;��ʩR����d���~"Pq���#���'Ǯ7Revk��n@�Y�Y9�޽�Hs�j)���<����'����@�hIu,y�� ��(��M�S�gB�;����>%�W�l&1��	fnC_;��>�+��{H��u�j� �0������x�R���Fw�X(D�����7��l+�c�7�7�F�T�S4�.�[I��z<�bH��
#�{������NvIa�@9J��Kw�]"d�<K9�kHiK"�i�?e������L�]�C��ā/�>h���&F����`��g\�4CJ��𽶮�!�kw��5�m���,�nu��8E4gsz!��)�Z�^g*OC���"�W�!�ߴ��l�Nj23\����^D6.��M����^$i�bX�V%MnG�r=?�� ������β���C�9)Q��W�C�)a�h."qG�Q���9Z�<�]��$5���6f�[�8��]�vA�������8�U�,p"{)��1iyt����'���'�NEs���]E��K���) (�oD�}v����e�SE3�OTP�q��e��R2Ͼu0��=K)ˍ�	9ז(� ��W��wc�L_��f7���J��,z��s0��KO���e5��q��a�V��N��2�J,�c8T���8�ec�ݘ�I��[���I�L��%�:'&[��M�"_�9�5�ET�����#ᗖ+H9x\+�N��K���1�ǃt���3@������`a򭕷��Vz��� ����2JI����oV�~GC��>4��a,Sx�H�xO�[F�P�H��t		�7������:Z�QJS����i1S�_C$M���/XeM���G &�* �/-H�Ӗ���d�9�R�$�<�M���5tS)A,#��d�����;��4Q�f�G�T�i�k�vy��my,��:���Ľ��S?j��e[˟Z�X"��C
�!Y�[�up�k?Z}4r�A�J��=� ���(�cdn#����k�U�ܶ��P=��;9��M��&_qM�G��,d�v�� 1-�J������@�t�1��Ƣ�u؊�����M���Տt��~� ��<P�V=��Qr���Y��4`s�&�����Gu,���ߨyx�]�Hx(ms��H{-��gs�J��q���C���XCrA"}rdr���Fu|���ĝr*�h�_��7 ̃Zc��Aľ�G&�����g�+�����e��ҝ2�'T���ް�t�M�ë} x�~]/��fP�H�\������[b�6�KGːs�ѕ&]"笶�+����*���m)#�d ͫ���	Hʇ(�R�����a
9Q���H�ǭ���tJZЂd]� S8Z}�E�э�M�E0c����]�s�;m�U�6ò���b�+w�-��3Sjn��������+�l��BU�Aj��f�[��6ͼ��<�؝m�^b��3�]���P���d�!{�%!���;�������(�O/��
D#��C��Z�`O⽩��t+� t^���x1�w����a���?��;p-�.Fڌo;C�׏k潵W�\D&׊���J�j�Ң&"�h�g��u�[LZR�{����ݥ:/8�+���~�<�y���c�|�I��Ё0��&�Y����A��$H��4�Ho�P�Ot��Ok?���[�}�T� ���{��$���PV�׷��d�x8� +�Ss@Gjo�A�<����$�QIv$)N�+$d!E�h��>:1���V�<�b��.���^�S�0� N˳q�9@W��K�ј�&%!�\�'�V M�/�.�΂�7� �T��w� �ȡ_EK4��J�t�+"�SL�6��pw�t.W(=��Йe/� e�k�:�^:y<b����L�&z��i<��<q��γ�S�u����<#������z�~�W6y�}����.�n�n����i�P��?���h�7Lxv�|�9��6�')�O&\K��G���4����� /�/J�����!���k�5�=�DǱ)� ���U+�f�e�̐��iQC"ש��&���u�u
�0&:�@-u���V���Һ��d�X�� "�[� ������W�zMOv�j�e��co �'�N��\��쥗��_��U���_A�~��ۨs����z��9l&f�K&y�'�E�6��)��'F�X�̚�n�F��-���z��$۪R��v�2���������H��d�8j�U��6�óS���nc���q�<���ʮS���*�R^��T�%���hD�Lb������iq̕ߍ�Ѝ�=�HW$��R�VX� MYX�9A�U15=a���t4�;�j����rGK����t�,b�0�i��R�H۞�%��Y�K=`���ǥ�lz'z�D�,o�=cbt�.!���tE��-�nf��T����>=����׬��G�#��4G� a-�������Y����ߠU
*����(\ĝ��-��<Y!�isY�8��eH"^���ĠW�Z��ji�e����w�jfH<��.��LMߑ�uqD����7>��._{�&�:)���$ޯN����"B��T }�<'�y�խ�(p�g'�vE��[���\�a-�P �ޙ�Rb�]ӯ�o�]�n�):��tL3����3�u�]T��]�|܃U�	@�Y�F1�?1���|�mMH���H��[��#Y�+�"2:���!��k��7�(�Ⲡf���}�ا��� O�m���㼈[�ܾwS�ْg�����T��}��2�0il�W�8�tw�Ԅ^�K�Ղ�XG �\��mK�Nv�|�Y�=rh���E��0��u�Jp�*+��sտ�m�{�=�ӰW�H9ī<���	����R#}cK=k�wLgc���&�E\��H1�k{h"�-d>���-!<WM���%�I�Mda�yg]N�U�d��[���6*����W��k�5��hSq�	'ڶI�OV�����ok=�'dݶ�)!��˚��C�b.�,��/���6��Bc����O{�0Y��QӷՐY[B�=��5��3�g���1gI~�)�*��B�Tl4����v�9�`�91X��h,��/݁�珰k݃F�r��� ����z=�]`�J̊��+���RrD�nNP��|u�E�k��&�Ԩ;�%�4�)����<}��ʢ����_�2;ǼӃG��a�,*S�7���n4�|f}����FK�|"1�D�zU,�̅@Ƌ�P���)���1��P�y}
���(��=lR�C�R$��7	^�\�%����?�'��3�q���T�y-�^x8�Z��ʩ�C��.��[�FJa�Y���˟��>�����Z���w�-I�߆��Q��BS#˦$Db���9= .yq��n�G�m#`�R�葁�}:n\�Q�eu_��!3-�B�;��`i��+�oV�/�n<j�je3�<I���3 Ƣ	zP��S)j�Tb����1)� ��$��\Q���u�5S%/Q<v�v�H��/B��w����OEH���3�Әd0��Z�[h��OF��"�8�%�s]!p0E�F,�ٶ��<!%M���-Ь˾װW�����~4���.O}��[ߥP	ؾ�o�u�TN(l�l����@��6;���e�&�lKPi�zZL�5[�:о�U|.)��� 4m���c�q뛽�E��t������X���n����;*&V�jU�� <����"x�V��1%��T(������f�c����'�R�C� #sՌ��z5��7D�!«�� 0���|!���{������[@��*uATRP�HԕDS��w���Q�l�����������'���m�_]B��W3/�Pw�������^Xc
�[�6$(�7 �,�{�n���"�H�"dL�\�
���a�Ȗ��馱z��/7}x�Ғ#���F���1�	���#�w�k<?��?[�`�&��e��`���F�[8�:z�+�Z������H����T�eX�Q%=	�ԉx���î�D�L@�N�t��&��9N'��#��FnO�y��ש�V����;�<~�fDȴ@0�k�)��n�x�H��X�"��x4��W��؋@�f/d�g�u#�&�
c�&iH>����,�5�����e�2�3͊�-�������ծC�f[e��-O�� �!�Ôa���ڌ�ى��}�L�|��5���n��[9�0'��/d�+<�Ў�
;�*%�����e-��((s��"�Q9e@����ʤ�I��t�����H1�s$6��^XQ���q��j�*�-�����od�k�K)�����T�mt݈��dFs�@;��5IA�K� �'�7L����nѾ�N�dҩ���J_����@w���OyȍW4W�Z�4��9��_��VOD���(t$��� �@�	�9��� "�gH�%��}��L}��'"��ݧTU	Ls��^pB�e��z�T���L����`"�q��k~&��_�P��p³���h,��?�FBD}���C'�M1��W+�gI�ր��0����f��3Q��KgIA�iHD��٘��3��������N�/V8�,��48o�LtVq､�4��
y�1��������=�'/�yG,���	R!�6>u�19Z0�n^z���a���*sr�_���aL<�-��TyO,)>�ڋ}d�/MxД�V��O���`�W8[����:�\�j� �҇���`@W�ܛ�]P�X0p"U=gP�t �Dy�/������ݰ�k�{�h��G]��G[T+�'�U��g΅}3u�ph�����b��K�-M��א��j��x9�����Yy^�L[�%`�p΁7�~z7�_���>%j$87��+������ظ@�����	<�S��@�&�<>��K"���0"�� �kR��n�.������6$ ��q%���3�
l	D6C�]�r�+� ��)��J��	*��(�F���_ən���������a���v$�*��.a�'M"�x�Oh`{o�F��Í<⼈Jm�y!v6�9A8��0V���[�����?˫��e��U�	��P�s�S�aҳ���BS�Ѻ:b`�'I�2s�x�u���z���Ò�N��;9����~
�1n��߁���.T���K
:�LX�c��#:���sv`,����YHp"V�����v�쐧49rvf���ݾb�H�|���������s�?*z�d�A��poe�D(hچ����Q7z2[/�Q�Y�Fo5�m�Ji
��'ԇ&��������w0G���I@U��!ݼ��Q'\�w$��hW����ɗc�����]jǆ�����۞�,�y*g��}۲����Nr>3������@��E!s+;��7��:¸��p��[0��}_1iE�ϐ���EA�54�������Y˪�	��E���BMV�3Mk(���$����P��vT��%):DC�6��5�Ia�;p�L]n�3U.�ct����G
��x�:�Ҏ��X�bI�?�l:�#��A��g12ᆲ-k���-�9[y��.h�0���ܡ�s�ޯ��8�󊎑����<�y�����!J%�N�w�8�:��=1ڒ9�/s�
+��wXQ�X����P)7�K��
�z�z6'�'Zt��?_S�����U�P혣�ٛ��/_C'���X$-Z�U6�b{\�k��S��v-X�>�Z�r�@`=�c�������m���� @U]wQ�pr�<��Y��hs^�bN�"�c)���+ 6�"���A��dk-�
.q.D��3�.��}�-61�U��W�XG/�����h曊G���h�cC�_5���D;��e� �)�^�b�o[���9�!��TUJ��h	p�v�Х[3~� H��ӄ^�\��d
Y�0˛���H��@��$7��?t"'�Jv��1m�l�A	(�)�b�e㊲�ai;U��x��ta�)q/���ˑ�'��ඥ]�\�q��{䝥�*�\�%�荏��!��V�µ��ݙ}tW�`?����tp���E�hɖ��ҐH�2�,b��m�����;�ʲA�@$�}�o��Xr�	qi6�S9���\��[�*X��E�J��j����M�t�E>/�3���7���v����y�p�g˕[A}���+`����A+�ܲ�u:������.���F��%aG��Đ�/[��
P�	����DQG����5��O4�k�m���3o�<������.١��'�&�������3�&"s���Ú�ȏ@�F;h�tS��2�h��s���׵����Eߧ���`G{]r�O�W�K��������U�鬖#�(4O�]�Jy�Ɗ��:�k@@9��w�}�f�g�fW7H�u��<˨�>�OCQ0g5����VE$A���\X;+�O��.��L��o�q�w��`��B�.��
>��,��LDR�EÔa'��ⱛ(M�T������a�h���7���N��K׋i�gk�$�
<�
t��9F�����xL�.��_��7�hԾ�GԨy�ϖ�9�? �ܬ�*�p�'mD�+�A�� |��ṷ̈̀F������
t�aZ�4����%x���:u�Λh��o^f�
��� ��t�4����j.K��%,��ZVY�8�x�6�d�+ �N�x 8tE!���Wzt*��"��x{���)97���2҆�m��C�����#�� ��qi����|�F���C�*���(YǏ���'�jVvq�[1-,�!��; ���Ѵ�����M�iې��
-ร4�j��}ո��C)����.�� ��z��U��RY�=оJ��Ҳ�+��LO��h�#���D��)&�ΐ\�̋��?i��z�����0Y�>:��]3ê����w�<�X����L��<�X.n�j%�S�׬I�q�`w�`%</u�&�l�G�4��k-����nT\a�[�~��M��k��|w2l��Χ)���QUqk$s�i_�#I�q�/�J������0e>�t��+��fTH43��b�2d�C�By�f7�d��Qx��J�޶��Х�ZnC��4m�@�c
#+%=�0{w��v�ճ㷠I4��OO.�M���!V������jA}�2F�Au�\o���·E��ϸ~�u�a�Xxݑoq�=��р����߇�uw�Y�v8Jlkw��|{P���h@����pB��Lk��r�����V�q�n�A#� 3���b�����ڇ�6�����P�2��r���D��
�<-WǑ�V����.o�O0T�)�b�ZΤ�o��䈟]okө���
�z|v��C���*���M�!�ܶO���*��A�&�������u,��M�@4�6�S��y�F�D�Ge�C�B���/a�l򚧋��#�j�~��o���N'�w�~�i+S�X�����[�q۬/�*���&$����}rP؉�'��!n2�N��:]��h]���|\���<�X q��:κha-iT��N��+��������䢠	}�;��%b�����gg��N��qMI�����)`3S�(�>��v�e����d�ƫZG�8�ޓB�qZ.8��\�fV�W��UE�o���V��ue>�nih�G�}�[Qn/��4%������G!r�i��*TP�S5d�Ij͠LRb��Uo��;�ŌA�C���k�L$MxL�X��K�B��2(�fW�M����lo�<�~qSdv��15��+�*#�%����+8�'�!�hT#z�6���c�3S%bo�U�j�?����.?u)���f%�d���P��c����w�͏[��Ј�T�2�f�C�qdґ"zТR���Tv6���j�����k6bm������,�m��y�l����mb���$:��&c?M#�m8oIIG�)4�P��f�Ͽ��Ը� �*�)�g������%l��9�p����L��HH�Kk�f�מ�w,lǋ$\���TO� �*�2��l�xXI�2��k����˕9���/찠��c[:tZ]S�RU	��0{���������<�����SB���]^85�f��#��@��:�I1ͨ4*A҆'��mV���݋����<0ۺ*K�b�3��Y~��mrC����P�'���3��GW��J⨚(��览�4�xÜغ9�5[�~�C�TL����h���K��t�����]Aw9Mvn��f�֜��U��k<��8�֌t5�Zu�b��=u7+Vm��EF'�(�rص��g'}�{�'�4u(�� �J�QD�ƥ�5�6�0��>�I�֩�؃�WR�S0Tu���6{�0�� �:�߻_�НZ�+��Ezi��XO�q��M`j���,+�ڇ[��(P��v.��.�8�������&� �?���&e��Jht�0O5�8�}H1)}�v<�����W�~� ��y\I&�*o�����[��\Tr)Ԥ���!�?E�S \�'�u��{*fsl#v�m��ۻ��������0�$����d>] �O���d���ȾN�/#<�O�������jg�&�h������!hE],�[���ML���eM�MY�Pբ�75,<Q/fl�U5a@3�zF�8C�H]}(l�(fےJO���Іڛ=[]��<^��4��hY�lС�z���F��;�)晹�]�F��L��#�f�p�v�yL�`C��:W	\����X�	��~���1�R쎋/�A���<�R�#V䆠��3�����OC��z<���/�P�ܐdhG5kfLp���,-\��X�I'�&����؏4U*����fBk����N�����K���r��u�= ��(�'�Um�'q��p\�iu$���d��*};�uB�@G������K����"�yATe�`y�b�k'zZa��+Qy�l���f`����2/7�I�_��4$tF���_ho)��D(�����/�#���ΊPZJ�G����
���r�*_��Yһ3M0�5`��\��]��Nw�%=N|U����_�Ф��ĸ�<k�a��{����qzL�r�_�K�ɞ��*�b�����"���bk�/����e}��E��%�(�.&�CQu�̔y7�[�=�Oh������a�r�v
�c����r���ZM� /��\�7?�����/
��z	�"A]|"I������<�J���l�N�X�!��_(��BFg�x!0b�F/��i�2�>�a}���$L�S�)�
�}����־�3;.]/�D� \��	J��1�J�<�\3�$O�Q(N(	�y��yU^�JS�Ϛ`t�������O��4�V�N่T�t{�:��a���U���!��f���>�+�2��X?0l��BZg�l�NVfL��3ד��@�>"�c-�W�"��#C9jR��� (��{4�*$���
e�[|fGw�8�h��4*�� S
���	�w����	��+}A�6^�x]���T��'א�wR)Y�+9JO��Ad�p�I(/�X%��;�Z��S"9���� �a��� �_����fyL97�B��J�g#��	3���$0��>����?������ً��`즽�{�wv�dN��jL�]���=��M�'�Z�v;�j�"��-3�������<��س=��޶��yM����?�I���Wi�B�����,WM/�=/�W��Ī�_Jc�~X��J�y|&)��Q-<���H?��!����m��d���]shG�~�G�>�̃���a�l;d��.(����M�]N,���r�)::�t���(o�w۷1�C�.i�&G�	�2���vr�����nd�_�>�医'��fN����p�5���P�V�%_f�c��(x�	A�]6X8��G0�|10�&9��E��Y\��/\��!����Qe I���ߥ�QSr�1���2�����o�%k�,�Uk؏���h2��t��;�O(7t��:�Oy5����r񠱇���W3_�� ��^����e(X��@�J@�����XT�j��5�[4��>sP�iO=�qMeF�R�b�����Sǅ����u���A}֎��Ɋ���و)����M����O	{�=R��4�X����Ȑ���t�MT�ëC��)�������*l�9&��>��c��T����˴����ϙ����!�q�4/Kq�y���B�!e�߀~bD7�H�:�ә��a@�R���I����pY�NW	#5�p��E��G�y�gT+�Jd�,­���$�#Sxi���Io�Y��������������.d���Iӹ�y�S(=�?���S��Yn��Tն�\�Sy���F�������n�Ta�^�|JƓR��]�H�W�<����]B�B��͡O-�[�~G1�Tm��]���Y|��������һ��w�>.B*ۯ6^��� Q��$~����#ip녢ڲb�vl�Ud*���x�|��p��B-8)W8�3c����) �բnG�����څ���`�rY_�x��������s��E��1�Z���Mu�j�qX��`>[�.��� ����<2�}e�R�?���p�pd_�ɾ:�k�=�d*�Ƥ�TW�3�g���\�YINuq�3�� ��b-���s��)�ھ�,z�m��//���w������/�0�V�Q�4�b�n}����I��.	XU��>����4m)=����h]��$�t����l��k#
�r!��L_��#s�Қ�0
�wu�gs�HA��g�:sz<���q=��~=����q�E������^^��ʋ6δ�KT�-�:}��0�b��6]|H�*��b�>���#@aM2����L���\�� ��U����m#�i)'�!f~�2ꑗ�-!�k�NAۗ�?]�o,�u���?���-"v�	U-��c�?_5z*�����(�644O���8d��׷N���`~�q/������n�U��1ڸÑ�?@y.5�B��h���'S�Y�|C�}�r{��}[�ʫ����c��"�сə�A+�]Sb�k����]�1�P�����ئ˪��n`ٚ.�q��K5|!(�<2��#��cy=�`ݘ�t�'`t�Yk������@_^����p�
��Z�����PG���)&�B�egS�ް�"�I@#v�}C��<�=�ZZ*�#L��5�"걆w��G��F��~f����[��ҝZu����3�����{4�ғ�_�{��l�j&LnÝG���f@�quř�4+=T(���\k�s$�¡���<���ꨊPЌ�:���	9T�Ќ��Pxd��་��������#{p�;3�����������}��g��W��n����p�b|���C�)&#��5bƔ��>�B�@�v���W���1����$���A@�!�T��i@8.}N���M�=����y�0�X�w@���蘰-,��1���� 
��p�K�%��o�F�U/r�zȢ�"����!*�.��z+fo����y��N���ȍڎ��<&W��P�����y�823�n���]γ� ��F�f{'��>q��q�{��,��{Ə��'��E���N����_���g��]0�=��
Q,e.@�@/]~K8�c����E��#�S�6���#�����|�M���}��ԑFy�i�^D-�;�~HON�Z��IJ���Z�֡�~�D�{�B�_�Y���){-<m����ZO���M��R�e�d�	\*�¸�e�$T'�-J#�Zj.�����"�bʧYQ��X�@0�/�@lK�Gp�An��
�7�E��ij�~9$Dy��� �<��0A�S����L��ױ���*E�sN��@�W�����2տ�u�U��͒A�	�#�r��כZ�n�Emm]y��ZN�4�<����u����8����/��*�tI)�9:�n�9��;��o��/3��Xr\Ɗ��! =J�d-�"J���Z�}�[��շ�Ԯ��@m����`�����38�;�1ƶ�=-���xtIjl�2�.*4j'�j�A�]�v5�?�L��n�!�=�U��[��� ���{W��ֻ�:�:�WKH�*ꚺi:5%p��a�q��Q0��
��U�[�?y����!a)ѫ�y}�Ju��RT���|o�ŝ,���͊�Vt�ׄҗ >y0y��m;��<���M�~��5��L.X����V�g����ob���Bg�Lڡ��Q~��tdy��H��Q�"�H����[)f����)�_��^x#�)��-���,�D��ۍ�,�7pmU��W�|�S=:������]�ZKN=؎�:P^��ݝ��O]B��W�L�/Uo^�s��J����q��"��(�>����M��i�\�bI*�Nq<z�i���(�
s�_���n�v���[�YN�H�|\Y3�j	dN�W�%�dZ�S���CM��_��s79Q�W����!N;-�>����<�#٫��0q���X�7�!ݘ�(�`���CLM����<m_����2��ģ�p�<O�D��__%�[!��c*�iK�v��ɿ��|�"w�.�4����cr�����p�-��7�&�h���e��lۨ��yRm]�EL��f�����8��i���~��a~��&9�ih�f��E�v�|��'�\Gb��2�b�.Q���������X'�	: �-��b.�+��Q��	ގ�lʶ�U��V2&��]%�q�Q�T`�4Ġ��m�r�|�e��izNg摌a;�G����@��ek���N/,�*���lk�+C���J����f1�b�@�:���n5�����[�*�7�d}�:�8O[]����-�a�.�N���'
`�15��^���r�HRhE��	�%��g~�I`�ݍ��ӵ�_>,Y�8�^a�!5������0����a��܋�B���m���Ա���.�B*��� �)L��{�A��ٚ�Q$���~�T�f;��c(zCfpm>%	�p��˒��Kd��)�:�Jc �c�)��1\�=h����f鞳��l�*��I>Jɋ��J��3#�<�S�U9YW��
Z�+`��E3�<O	�u���u�M�8%	�`��~�c/e��!K:�`H���#`�yi�h�hѸA:_݃h�Rڴ�fMI6"	X�DP: w�����T�~U���,?�f��_����2�	4O���ucs�L#A�,Ց����vy0��S�
2̠�������a��f��x���;��S���|P����Ac�Y����%=Ll��X����̶MN�擜�k����7EH>�l�G>���,c}s�:�v���l0Pя��P�g����
��j������00]�Z�.����&�S�f�\� N�ӆ.� �9�t%� �Z{N?6h��{�K���z��d�7L�wbW����!=����Hv��FP���P懕%�a�Y���faa��a�ʪy�@1*�(�QH{p�É���(5w��Π�����D�^���o�*ClC��#���j�H�<X�!��at5m�V�Q���[*�jNo�0˽����+��]��
]��e9��y��E�4ƶ~���Yν��� ��U����@+�Kz���o6G���0M�e[6{Ī��#}�27�3�0�܋�sk�|)Z���蛗�G��9"ua'\l�{Tq�̠P�p�E���~}�p4<F��m��p� �q�tm�~���U���JQ���#b�v�����@^�����J�W��s����"Dq��=rA��Ќ03�rm��Pj~�9c�k�͜�?�큀!ͨ+T��|���8�o����Be1;����1w{Z����?�����#��s��?�C �2\��ؑ�(�璪5��R� �Lt�%����wb1WQ[w�9�F����Ԭ8�=�N�q��6�ӏ��7T2R0���������s|R��N��v����{�_��2;/�h���`��)�� ���9�"/O;.9�S�ƍ|n�t�"�E�ڣ&���w��G�Ub����D���-
���f��X��n�'�'�-Ƶ+lb�x�W���4��:p�c03�y�lr�a]Ks�`Ŷw�<xI$��ʙ3gw�OCCc�I�4�h?@
��9)�\8�� ;��+���;j��h��%�v����^�y/['ǡ�X8�iݑU�/�Lj��m�6���cj�g3�5�3���T����B�����%㈣�+�f��<��;�������z�ɉRA� ḇ�Gz(��;��'����b�����Vd���G2��=�c	�,���1��E:@�;@�� ��"�~2�F����8f�msm��~��A#�`~�˄[Rʹ�:6)�����3��Ȉ?���z�H�$E=�F:�˘�(J�u
w�T
ጣ�b��IU��8t�6$}�#��L+Z��ԗ� ��F�����:c�E�?�֙�2������3[�$'z�����o���P����9��pt������Oq�S�¬�� h�k����4��X@)���j.����p{\���qYH����KV�=��������Q
�����`A�����5�6��S��A�}wcёpX���P����U�?����!OѬ�!Jތ�Ʉx'�u����|��bcZ#$%FT(��W�WF(�y(�o��=��	��a�P�)&jCa�0�-l��_2�ο�]i��C�!��+��u��Q�ǜbb{d$�lR3XLey�mpO��ή� U��=)=tU�_#��3z�{�!�T�ڈ� W�YL\�iUd��!~���A���"��Q�����rM��o���ͯ�����d�ۻ�-�j>���NZ�ل/oJ��!��]��z�e�.�OX�������v���kk��eD�;�'����g�F�V����%�&w� Ȱ�V�[�)�J����r9��f�ã�m�0h�4�h�=n�)���>�&;�J���֋�s�la^]S�⿺(�~�]w��v��Gd%�נ��ZH[K��Q6n�{ǝ���������8L��w�Y?4�z<��Q�'����q� �vlHYO�+�(�X��TA�v�<#�li��RD��6����1amRcP�~$jqh���n�No(�|���y��.�h�s���_sz���ѡ0�yx%'�җ�͎W�i��=��̼0�j�
���̊��t�>g��6bK��^j���⯯.�w�G;,X��J`�aL@����h:Q����.i4,W����v�kk4��P1�׭wE���V��f)��ٯ���ŗ����:I�y��K������	�T`�4T��fڥO?����M(|�Ti�m�VKu�N�]kԱ��.-��I�F��i�<���X���o���5�%c�����TCL��}�e8�Mf�.���h�:�t@`�q�'2�q����fˢEո���E���7�l����� ��M|��)�����d����p�L�!�k�-+��܃fG2_;��:q�1$�Xm-XT<��cQP�J��BgBwZ"Ү��C���o�z���1��(���ᬵ��h��I@�;֎W����8�n,�E�K 
53P5��iJZނ_�́����}���7��e�����A���z�2R�5^7�̣,��0��pcL��Ϛ������$Hs/v#_�hB~��Rאb'jZ���� ɡ�n��j��;�^ITo���o]޴�Y"���dIf��)	v�A���CZ���'cT�:qy����m��*��jt���H��Q\�+'*[z[J�!�X����f7�� ��f�{-�x�����X=1��'3�fM.�7>�;~,����V�gdR�}��� �e��N�D�#�=���K1�k�ZBU����h��(���?a@���`>�B��$(���lI�<52�(����P[i������j��8���C�x�|¡��~��h9(�%�������m�k���b���'^����o0ҍ������Mt\�k+�x��ҏ�(��g��� ����ḘaƜ!���_Θ�~�v� B���Ը|X����Q�#zq@� �O�"9���6���{d�
q.���T��ޒvS�{�q���0-���8Ms�#K�.M���ߣ������_F�1�_}! �#�&b���s�E��8���W��*̛�P���V�B�#�����\�Y�w�ws�S�7\��8p�ҕ�5<!��*o_x��<D2�#�H��0SD�x�qQ@7��Cj2�[?̖�1ɤ�@,?H�/�I#[^�ӮX@miO�M�8��Kfvl�x �V��%"sƂ��n�u�U���t���`X[�w�hq�����l�fE�p���=�~��͸2뙎�뿀���t��w9�.F}�a;��*I�sU��;x�A
�g�T� ke�1=��=�v]GH&�D,=�?x���Tf�H�|��7��Iڝ�I�!�Y		a�@ks�CK}c�|\,vH�2��%�Ob́fu9�.��}��-�H��Tduڷ,�3Gq��9W|����	���'�ۘ"#"L����b���]v��o9��=4���O��W�+��$ �l��b���
1�"�X��&���W$c]�D�,�OE�v.�;�ٶ����%a��_�B
�_E�`3���0 p�L�s`������-[ J5*E�G���1D6�ȁ�8����:gS7�v�]�Hg��ۯ�&�6i4#������cb�y7��|gf^�2R��z���Ut�*֣ށ��đU3HI2��\��|�   ���v˔�� ļ��bS���g�    YZ