#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1266634930"
MD5="4120c24c5a79112bf22d82437d9c371b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23744"
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
	echo Date of packaging: Thu Aug  5 14:23:29 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D����5��Ob��sBDL8���QCTr���=w� 9/ic�r��V�T��&�� m/��5H�vf���0d}���H�C���0wn+�4�6�Vjc���/��Y�Κ�DR��e2�r��wg����:�l�� �r���l*.,�lKOg�s�gdV��m��V}����h��2�c#��0Ӫ�g볘���������>�k��	�ϔ�K����D�Q�n��
���n���ʔ���M��r[>�9m�MS���uw+5�qE~&��aS<����1	Y�;�4!j���).��8Nw�k��Խ�5�U����XgF���>2 �]���ҋF�k�0@�b	e2�g��Ib���n,�,�jRU�\J�pYU�����*ߙ�Zo�`$��7�Ǉ�oM�����������o�C̡[_K�Ji�:�s^��P���ДD�^��h1Y:s ���=ۧV����?VvK�a��@FB���A$^�0���w7R����eg,��VU��Y{Ū��#��˿�]i���yq&Ĩ|<�����Ѭn���b(W�$G�L�H���"�p~�J�����]���OgM�W]��3Aa���*����qc�?�j�.@�W�z���QT��Kp���q~F��������[9�Hb��]�5f1���J�y��ГX�HE��[�I��V��C�-�P�j��9���WA���J5����5�9U�j�u�2ߑ�کg�0������V�/���:R<��0 ��j��u�0�:����=A\���+1G*����7!Kꎄ�����>�^p4�%�77����q�#�4��l��Q�m�����x�L�:��U���
�(��6S��fV�`ݤe͉V�uG8��!�r�T���-�52���]�	8�'7����O��z���NDVj�-�
!o���Ó�x�#3��"e;�cө�m��7��L���������P��z�
W{���j�1l��r��#�_�U�n0�L��:>|IS��FCʭ�:�j��2�H_��Y��HT������F�B��<󡺜���`f�ٶ���ʷϡ�Dbdf*�3-F���+�]?�>b�^GKA�b���V��z����r}aކ�E��e�Q`�Z�C"Kؓ�ˤ�{�nh�BW@ɒ�'S��4�֧*x�3QT�/k�]-h�͡���)v��JE�ȡ�eγ�|ޝ�.� -M������ݕ�d:g����s���'�!��鄚-V�H�z"QNx�4����6{�s��[M�CH]��urz��y�J�G�R3	`���OG��U��fO��f���E]ջ56����2�<3#��� b�_��G���7Z���@e��K�c[倁��8��!!��zpě:�GQznr�$6�T�V�v�7CR�R���#"GX��ǹmbN���dG����W�z���)�Q4�h�'Z�02Z6��T��L�({;]Eޔ�2�{u��.PeLx�9#d��;�q�vCJ�=p�ƦT8�q��yc���{:#Fj�ٛB��<'|eԵ�M:�Z�@�:����9��|΢�s%���aQ�)��e���=��?���<�<ss�~e*��r���9a. /��HTk�q;�שP�$���r�2�/R3�!�|��#�Ad��կY���������oA!B������|��s�_�^_D,>Na$� :����L{fQq�Y��X,fӌ[niOM��x�З)���R�s�)
C���&�vF�t��γg�ڪ���ޝ��?S�B����� �ŷQ%����"�����b�=��x�%s���躸�]�u?�`��n��LF�(�	E{<a��r>)A�6�@Ig���COS����M��	ܜR8��սr6.E!�G�₿��;Sb�|E��8t��K��)GrX&�8V�m��-Ѣ9�TP3R�.�V�VD�C/��г�b_���N���=?�a��'�̘3�A&�q���V� F8
��x���HN��'� L�-��I �#��\}�%��@|�E�;L<r��d|�mI�oʢ叻4�|lk��:���ks۪�r�~�1��7����� ��
��=B�C�X���l��){�֎W~�RT���'���#��HεT�T|D��N��z�ac��?iс��U�@��ͷ�T��K�T���BzI,^n�g}��lw����b>V�ޢ��mDy�e���,H7%�؆��O���86Ѿ8Hd�,�TwNтKF_i�ֽr�QV�7��fz��5�����"���zڻ^5@8f@*�qhZ���?uku�F�z\���w�@� `I٬��4�ޚ�a�Kj��j>B�g� ڴ���������Q�l��=`���+.���m��M	�d����[|/E��a8���%��W�Y�3�-H�Q������u�|T"d�˼�Yxi��pU*����B��̭VbY$��m\Z��y�MS@7৛�Ͽ�8�VF�0�-�O��D���3w��ߒ��=�� jz��dt���T�Δ��Q �~�� ��J;;I���$�ob ������ܟ7�<3
y��ց}6Q�_�1Lm�c��+�>�D���DUe?�^!E�w�n�n�K�0��[�b�r�^U�%����B�!��̺�nU��Zsw#eA"G�����h6\�����o�0�n��\M�,��ND�g�u2���>T�Jj����,}n��	Pg�R�0$AWΠ�%Lا/MO��^�>�˄�ne=��w��w��t�I����GF²�-��� �b��"f!�#N�;^̶�����
�bKBC18�0<�;�b�[h\��*�$��(��o�խ�g-m��z&Qen�u���_�\�j��6
,>ZY�'��Qc`�pT9;c'2P(7����o)�V�e/̍b(g���E�T�������3�����\�M�>Iw���!H�����u�Q��(e�i���]�-�<ϋg%10Y�D�y9��aD�véOG7��O�Ь�J�	
&�b�NL<�A`�	���DjwM�,� ,�8�'��N���:��&�ל�͍�-����<��U+ӊ��\j��z��5Dz@5��rkʓ�D�ꮑ͘�7�F�m�Qwq�Ǩ<���}���G�PL��g#
 ����%��J�6dcr$�`���
F�����ic�vٿmi��iAM�W����5��N�5��	���fQ����IY�)T�u�Q�zC���=d�ch�'G.fe�/֨z���h�	5kAyq'&��1WBFIK��*X0C<���q�l��b"-��J�{�?^���e�f^�k�� Yk`.�!K.��1/�����;+�-�˹?�~�3�YF�O
�!~+ha��\��P�樵q���������v1(n?�f��@y�
�WYW�
��$U����Z�J9��3ݝ:���'�h� ���\���PV��oV�9е^�k�2�ƒ��.�I���{A$:�Ϸ+Kb�����F͕�#��3�i��n�fQ��]r���Gd�������|h�2����M]a�������Fi�b|����i�a�.�~]K6�!��� �%{�d�-�� �s��@'Y�مI�8��-���ؚ����/��3/	j/���Fo�v����!d�o�f�~L���)k@�`a��"a�|��wk�%zaf
]�@憥F��"�K4A7:�
\=�6���[�*ћڏ#l���Q�B��m�;NWR,>V�35^3�,_p��g�� �k8S��W�RA����J6�Zʴ6��>�JbI��g��n��(�0�u�Ε�2��̾
vܚ���ش�M�_,	e?M]Ĭ��K-G/��&Y��t�[��S��4>w�e��t;lN ���O�?Y�mz��mM_O)�
ҙ�	|%d�+�ѧ�f��[�TOx�>���ޮ�gڈ�z�-�X�N{,��z��o�/��(�)�DR����S�|;�%��$��ߑ��KD�g�96w�V�(#��b�$���g���&����E��ɀ^74����p�4�rs���U<����U���
���8�ڮBJ���r�]��su2����X��[o�U�R{#�c��z�T��L�_��W�����=��3�I�x<���T����6>5�&g-�=��h(����llj�i����,�F� �/����{�5Ԓ��ݎcs8q5y��x�9�c�<�	�1R���*����j��Sݹ�����_�:�i���#��	g��[� �	���4�N$��A�e���jgՃƅ��hwv����0���R�ԇ�R����:�V�ů,^l$�F �v�NV`m@��=�%D�;�eO�<hCc����p�kn-N��0z���*���`��!X��Y��ǝs�-���!oۀ��>�['�v��ΏͰ̎Uw�$������F1a�-�h�W��@�ml'�p\�p��n���;��hFY�����`����$Z�ǲ�	ڝ	}�7Sϊ�]��N��F>�d���9�ȓ�'��3��oc�΁5���t[l�x�l��^��Î!�v|�����亶Ƃ�V
�W�M��9(�m,���Ѧ�n�Zr�#�*8�0Y���A����P�	���T�g�?�"�0| ���}�%��	����%@+�����8K�WHm�6�a��, W��4#���E��e�R*t�H�s��`�ߧ"��R�b���ղ��������$���Č#~�ܨjT�8hX����>�U����W�	N��]�#�ր�<�Oc���&pk>ʞ�XK�R�J��&��G����p�k�W4�}3Z���i���8z�d�8�7 d;�a���B�Zg��he�sT
u�-?z�H�O`n�c�e3�"q ��q�\�����
�����(A��ǰ�M�P'l8�oY��qq��J9!pg���G<�z��d�<�[M�O���5:˽t���o����;`r���$��%��B�H�
������<mNg"�ҧrr����9+�]pzQq5�*;6�� �q��]�S��<w��G�R=M��w[�6���1LƟ����W�5n�[9"X�X�qR{S���[��19S�������T&��U�4�z��#��ωr*�B�(``�d���Xc���q��"��y˳��%}��VLG�7ݚ�4���\ޥ!�p���d���D�<	����� �ǲ�Y���O��n��q��B΄��F���s|%�z�}�#�;r�_��d�i*���_�K *7�(�Pu;�w�� 3�'閑v\�r'�8��*��Pv9QMs�w��̕��xEo�t�(v�S��ˌ��Rg�qg��혃��o���(�W��Z�NL��f�sγ�L�Dv�(��|)k��Ti-����4��r7X/�)��'8�����4.�7�%��|���W���?f�LÀ�H�[����@�G�#`Er����<Z]�#��+BJhx�0��r��dAw��!�)���^�]�O��[�A�r����4QHZ�R���9��Jm�Zm!�R3�xXbe����ѳ�NVT��Z�z���{�f���?H�9�I���[g�G0*u,�]��S��\A&B���`�e�N+<�u	) |G�d��d�K;n#2�G��򣊖Vt����̪�C���W1'��E�ֽ���|���:�g �bB� �7�ZL�+CRul��T �$m|��Z)��:~f		�az��,2�9G8�I,\' �;z�y�*�&"�}Q<<]�L?�>J�:�mG�!�wyt�Q��0>����X.�
��G�vM5��a0T/��*�J�\.��I������2���$�F�XN1��^\�c_35b
��ݮ�����wLY�rJ�kr�ળx�f32�ӯg�s~O&6��J���@�CJ�'�|4�~˯��n�x���0�@���*�� :�@7�<��?�B�m+
�����T'FL�n�6~�J�P2��tL]Q�>�?qA�\ �6��j�M�j�2z�z;S�����8I,^-�%�WӅGYӟ+'�f�ß���U���������-	+N;!/I�b�!E�Z~X=���}���/j/�7 s�Y�GQ��g��c$�k>�}�">\�%4�5��bs_�v����{��޹0�a�N1���+�a�A	�#$NI����p�?�X�w�ǉ}7��}����`BHѽ�=@�Tv'$�@)㮭��O�m�q�7)9��e�����ƺ����r#��%��S.�1�P�����x4�	�%,��<gӮ�w)���ۍK�R����*�<�ox�e�[�0����I5��"��I�2{����ϑ�a��ZFl�&���
­��S'�����K���$?�Lq�:�#.�P������!��`#��Z�lu�[��Nm��a�nAa��6SWs��Idp^\�C�Hl(�Uc�=����慌_S�w���?z�������q��'Z��E7>�tt{j3�h�6�����B�j�:ބ޻�(h;0c������E��t��4e�erfҰ6y����d\�ÄJ�Ԟ`��YE�QծUV΅om����}��"��|N��
x��=	��6�2κ���έu\��H�_AN���	G
	�Df�x�&h��f�([��ɆE�p1��C��-G��-�ARY;��>0�!�U{14(�[Cڦ�g�/5�;jOJ��nB�6��d����2u^�'=���|���w�,����g�,)�"�0KL}�
�O��[צ�v�~u[��Q�7^��#��6�����y�P��e�a��i��lҿ>��ND{��P+r 	g�At��h�e�ہ��9�60?��2��Ɖ C�y<o��c�G&�-x���[0f`�e,H�ĸ�ص�I`f�2�'�c��o���u%�[as%���Nn���Z�=��$��h�#���a���*h	�׹�0�MgB�s�<�]ɞ��ew����^��ͧ�^�T5�P�(Ħ��xB��q�gy?I`�#�Ǣ�|<�,Kb���E��k�n*W��H/4h�^������҉/���õC����-����v�u���Z�C}���c�|{ҩj<Ǔ�/���2"��6�����|^α. ��N)�G�rR���滻�к� A��+����Q�FY�q�̵U��urB>�9��	��vJv=��x/V��lu�,��u�e��~�S�~Jx!��,>���`v1��D'�����T��d��r=���u5���frB�U��,����^��~Y��m�� (v">R�s�i��B���ܛ��d6#��	��@��%��|sbY�\
���%�*j�v	��:{�,�$�
³Wn"���ǧ%�!���	�Ek��$��u~J������H�~� ��F��io�E����'3���ש���M(d��-�()�F�ޔK3g6�]�I�F���I�K��"�.��6��!1Ԍ}�U5�I׾�H� 2*jE|���P�P���)in|C*$�:*W�@���M*�	CZ��G	d��z:�V�9L�4��l��=w�5F�A�c_n�-�_zK.����֪x��w���8Y�+[����86u7�_��;J�}�@��L�1=���#�X�C�8"�$=c*��3έj���H��q����jۆE����I�[]xW
ǈd�3�dV���Z�L�^QTd�r��Qz �?oH�|E�~�5G���ǒ ��%Uk��¡ ]��l��!'D6(4{����������Q���5ǘ�����U�w�"��%�]7OH���e�A,�����i��l�����V�):���[s��W���O{�sP΂�ha�N���Q��� ��b.�;<��6��=y����g��4R��4I�`t�]Ձ#6%>ف��L�����J	�<�2�Avץ�W?L�#��֣��ME����7dҺC�oBf�ӈ"���C�t��\{6	݅:᛿v�h�����,R�}f%��Z�-\�YC�&dd��V ���*������%�{d`o֕e�͊%|m�W���5b�����H�J]�sc�ۼ�?�"5Q�M>�%�-}8��7�N(���?}?�����C<[��LX"� ��3��|����Y�	�+r�/����:N9�D�& ���	�D\'���x���p����q˷m�+�OX�0ڎ�Q�o����F�f�a�58A�	, �0��c�#E@��B�u��'=P�s����fkϳĊ\�/��e�E��O/]>�*̙O��k�|ڋ�`��kYvݴpw�ˌFB7��9�Ǩ� 3��;��T��}Jd�ҕ"��X�c��Bm�W�J��zY9Ϗ{@߲5�Ʀ�H˥�3�!p����T�.���s6'L����Q��I~�vL*��G�W_1�Q�qV�z�^��p�+�r7z
4.���E&��x�}Ie&m���g�����V�a:�� ����Pc�j��l�F�x���c���
c��:���^�侮8�$�1z%�-_���3i{<$��B静�O���T�>{j��%�Xh�h����>�������05�:��l�5*�z���v�#~K���Ǜb����x��7��%CU�6P f����8�Y5��:�6�3V���*"�ϒ�W�G��_�_Ұpl�q�5�pM��c�L�J.��X�5��_��[�]����J!��%���A���$9w�z�_�w-���;�l/�3���/q��R߃��3rm�R��J�P�1�dw���b�Y�g5vrZ��5�v�q�,j��k䩉��$H�<G�,����vһ	+��k��v��i0��3V_�!,��%�@;2���[�Bud-�Ʈ�e1'����\��q�"�6���֣�T��b^Fe����'	��Nwg�Z��b+F�� ��L�r9�V�|��1.�rW5��ih���8J�?[@/� �(��n'F�=ܽ����M!/�}�с^�d�T�]q���\�G,�5p�L�fJj�Q�־�J��'��J������b�w�|��#.��E&�Ѫ��yf2�	��lB:��D*{s�^���y8w~Ϗx,��6Đ���Eg�{y����SΠB����9rrS�.�1�$@M<Cm(��F�X��'���5^���ѐ,�ł�/g�R|+\Yr:R���IGvߢC�H��o�c����SP�٩��8PH)�����v�#>�a�R��R�^W�I�FE&�^�8��31�O ��k�z`>gl�-��0T������J�w�i�	
�%?��PC9�TJe�Xw�:���[]�u��Z;�ٯ6�7h}ǟ���"�1���0oi����A1#J�0޹j��w���)���'��A�2��2����Jn�YY��^����?~8,��P_�U�2�4j�:X7Zq4j�
�X�_SPů��� �4T�?��U�T��^�86�OP�^'�+�" ���iP�2���C1�p��)��Lԋh��|bk
d{�;6rcU�PDu{�����/`aϷ���Z;�3\)�e���"�vp���	��l`��39�s����{;��9'x������C�՝�0Y������p=.�Д���P-�2��}��
�m�Y��ϬrcT~�����"�g�Z6dP^�b#�y���fE��.3�T�]�̣68/Ip��W�g��ײEͰ>
ؚ���c(_�`��/���9��P��0Գ�|q�=�w��Ә�x]3y;�)��aqu
�b,{�9̣ۤԵw�ƿ5�i���*�2�.�Z��vE&���Z��	y��sJ�߰B�D��XZ��8^*�C��zsg�tǎ��׃��xm�혥��Nį
�ęۙ���D얳�� ���.M�

�,�ej�QA��8#������k����W�4"�W�r#eŪ���W�޳e(-0>/Uv��>�w,$�7����?��� �� �~�V����O:�7|][���ZӬZǼ��X){MNÒF֊�9s��4R��C&v�I��0���=8q��ء'��R���un�	HN����<cq�,�+o"�;�g�]}ET'B�����99j9lo>Y��m!P�Y��5zv�"�l����9�=��n^�%A�?}�#���.���4C>N;����;g��Y�џ�0��d�|�h�{E@:�2X�L3 ������W_r���F_��6Ä�3�7��L��Ԟ�{���%8��6��}iTD��'���㴓� �������"PΛA_�0������Wv��S�[���oi��΄�,& f�jrӸeD��3�ۦaY�c[Co��rt�v�3����S�}z�Y���&��>�3�I�?���+�x�a#������}�Q,yV8�3��ȍQ��R���٤Iq�vރC��1B��60<��(��N�B�S<O�"G��AN�i,|�)ZT��Su�0�(�/��sβ4 8�����v�,[E��1�
�3�b�$K%�Sy���]hX]�{J�F�'28^�vN�AnJ �a���_�Iv�b�Q�Ȋ��!��ɏ��2w�x��̦��Č�Yy`2&��>�=p�\�D!�E�3:���a(8����%�t{�����O�{���,�8J ��:����fU��to�E�Z��}��%h"�,2"^fcRݶ?�cn��^m�}#J[*�~���C�dqQď��Q[���`<�ul��\�p%���;Xӄ\�Ђ�`O���7]�#+�z$����*���8���N�68�0՞.��*�}ɤ�&	�E�'�S�6e0�z$����
>����6p�̣��@�Ϟ�#�Yk�wt�,� Q��˻(NQ�.� ���@�9���6r鯢k	�k/���Xg�ߛb1ɞ���vs�b5C3�\ˀ���	!����4FxSO�Я/k��U�����r�*�@C��w� ��#Kt���]�t�í`:�P3]��	⯡󴷈�n����츝^�?�z9���vh�64q��>�����0�hg�4�Q����$�Y�10��GИ񚤖�=�g�=��d3J4B�F�����NT�m�!���<%\{�`����|��'-V�3嶔7���;��7��<����	iU�N���Mq�e�ɖK��Jy�;5��h�E�si�k�J�wϭ����iM���R�,�@h���hӸ��`o[+;"��J��ݚ�i�#����!xAut��p��T�'�c��N��8F h��k�B�(ٽ �����cC����YQQ�|��ń��AW[H*�kE`�p��ȂV���_O���in���:S�G�)�W =�F��x��rsdٕ�壐섩s�)δ�a�G �J�&U /��oO﷨��:�8Nu��K�)̵�!�qA��0ay���G�$:�I>Z�xץ�����?y�A�R��ާ�՘^Uݍ�u��'�����fQJ�O�K�Ц���)��nw���u��c+��rg�~?*$Ð�)��h|�mUri���:^3�▘�����,�0����C�e��`��J�?}�Na,�J���(�µ����@^�K�<J��X�]߮�ҜQ���4t&%��o2$ �J	�>$�����PK��=?�C��@�t��Pr*
<�ٷ���ִ@���<�~�m$�1.�.�G	ԙ���lRO�5W%�\JO7�r�(�֏\���Ĺ���u[��i �;dH$�8X��|,�?M6�n�Q�W�;��L������H�?3��.��w�����G\FO�� �wb��q���t1A����ҍS�[%�o�0õ��!��zz� �]Ok-�fmm����R�ϑ~o�pI��y��A�j��v��R�g@Ik�]kL�љM<N~߬O��醶�|�1�/���sGW$Cj��gT�G��L�L��[:�-0��^�
}�8��?{�r��f=�ȃ�}c��t>�xL		uU�l{?�n��]Ԕ���y%�"(�=�sSd��Ea��r^f�e����_X���q�h��f�1��p������$�̤���,��Y���[��8��y���D�;J��7zA�<j������k��ړٴ�z��c�����ϒ�@�ˍ8�� �V�aDs�ka�!F�Z��1��)��f�J�?�	��Ge��6w߅�*=�m��B�ҾM=BR�[�P�n2	��i�7}Q}M0�����n�n�ؕ�G2�����p� ����tOJau�:��9cc�[�,_�,�Æ��å~~��Z܍��Jf7p��w�ŋ��v`�6�`(4]�Z��}O�g+�_�6��O08�Պ�n��|p�"E$���vP *0�F>��$� �v4�& >�
!ow�Ԇ�l�ِ���q�)=6�xƈ��'�N��0�'k7���_𙈕��˟��GtoW�_�4�wKo=����3v��6*�ǆ<c��mƟ,j���S�*	�$��m�Fxv�n���1A�#�<��;��Ǣ�qv��tU[����Gt����*���<����W36. �m�����\g�=�l��6遤MS
�sk5���,G�ڟov��j���#��z�dO���B�˱$�|�[�*��H�k�D���Ex_~P��NUY�&oUer�2�=���$����@jd��1wc
��*�u�K�Mk,H^�4� mt��G��ʺ�L��	���e��g�rR��5[K�2?� ��h�[�&���].��7j���C����wbt{�}i{4�(G��I�Ε)RTg�}t����Sy��FZ%���颢�,�])y"K~�nP"C���i��G/��ic�����=��r�\N�Y�an|ʫ��wFK���
�j4'���a�F:�nؒ��U�N�-�f8[�Bn6�!�Y�;P]C�Ve3Y��mϗ* Ku|?���[�i�C�Wza���j�I�Ru֘�Vذ���a���`�{\�����#Wm]�,��u�����XΕb{&v�
��6�9'�o�ҹ�ԥ�����JA�^�a)��ޡ��mo��[a��������W��i��㗭\쇎�ۛ�6�F	�HWWq�`�ֈw\J�jÉ���a���`�'R/I��63�E^L�ˁV?w�`���'�-g��Z�Mǋ_F�0r=�F��輁���(��':��MIQ�(��W+-��3�;�/X����ֻWi����DC㭏�o���9S����9��6�1��IRt`�_6��><�<��j,4bsGa���	�Q����<K���5$ا�������
�l:��� ʣ�I ��k$6P��}�#�٣����ǡm�:F�ĸeӄ/��W�ڌEA`��&��	{��AdLG�ҁA?۠��N�P������l���Y[��QX1�����>����C~1����u��aif�-�p��)!���5��LS�,����9ICIo1Pn��owi����7ݷ � <��;x��g���R(X,��B,�����E��mPf�P�X�*_�L��9�#�Xi~6$���e1V�s9��Z
�=�Dk�����͑��
Y
w�Όə$��B�� E��r��:�塚��:�p%���w�&���)�G\��|���㥾��f�D\�R�@"�"�������
��9Uf���w�p!��	7h;M;�-�GB��O}��XKB��.����w\��ĸ�>��'��dB�;䷹o�p��,h�9�+�p"ZNV,*���4J�T���8uT��~c���d��� ��V���s�?mL���:կ�Sn�9ȦI�O@z���@K�g���:��u�*a���Ў�ri%�fͫ3�;�sP,b1��I��>�I�)�؞�,ceN�" v�O�$	�A��5w��.��1D1��}Vu�ȅ�mxS03�B�dj���� T��ˆ��:M�`��������}i.�ֿ&ρ)W:��%f�)T�x����ξu+n�o,�5v�>a��J`�=�p�q�Dϓ�� W;cm�:�
	�gĩ�{�5��;�[ ��A�u��DȖy{Y�qj���h��Hv�����ehS��%��n��'�)������鸵��v�G�U�P����w�M�c̈
���W@qe&��:$Z�]���@.6��4D���Rh�y~+�������DH����^&Td���=�Be��&1|]홨�K�
�8������_��=�7���{�@�N�ҋ3��*1�j^@J4B���xF��E�(Եz���,��̶м��R��m��L�������h+�܊��� �_��TMy�4�ru�M�z�h�4;r��C��J�8�ǟk�����7k&�>��Ȯ�l�+/�����~Z���x/AV�8 ff�Cs6 �'��R���]�`DN9֛i+�m��oc��6m�m��}��~�9_|�
��'>���#X�mP���.{6��hv������Ɩf�������^��v�M�%LB[m�>t%d�`���e	�Z\X����"�I�ɸA���F�}9��1��5�ॺ݂�*��b�+�R=-���Fij��Sn��e�������������R��1I�p!�C��Y�j�UN�E���iԋPwE8�9�D�[qN�֘��V:J�&����?���rpH%p�Ǭ@�E�j�/
��Y��i�h�"��}'�L1w)i���0�#�6�]#Fdeg:��\�ެ�E���C	�B�e돳�-�ަB��,K�x�dFn�;X�T���*r�L]�zG�){�g����Q�Չ$�.����B.��W�I�1�喁�]��]I7\�8}	�i5"�f?�?�^�W=�m���c�b���]p�vxgN��E�y�d1ޢ?T�+�9(ϱj%r��[�<jq^��G4sD�c�����,���zV7��~p,�d?b�q�	����܇(�����K�[��D��Ȗ�s3�c��%
*4&���P���V�	'�\�P�������1��?�kB��{�]GF ���|����9՝7��tʽb�-u��7�p_f��E����x�]��+��
YH�V�.�V4*#��ϺU��K"\w�D �,YJ"�)���ltK���ߏΥ/�sՙ��q	SrT�4�݈F���y$I+�̮��[�~��p�z~��-�5G���A��Ԛ�;�3:��,-��ݢ	>���o�ӍP�� ��a���̍����?��&:�.j���z/|0���Y�lR�q�NhΙ`Mm��t侼������8Ψ6���	Q)�۳e}�qmXo�em�L-S�r�"G�Rwn����n��b�}��АM�M��XQ��`'�Wf��n	���sʹ��yOX6�q���$俬0<���y7y������ m�!<�n�?�k����ڟ����^ԧXZU�'D����5U'6ο�2)�s|UvjI�o^�f�����R��H�(-p5^����A	��6��?������E�_�y�}z���!vS�t���ɾ	
\5����O��n[;�GS��d�Ƌ�D�\���c&S$9�����?���e�t$�wJ�['j�_'@�� �1����%v�Ҵ-!{#�&*#ml�z\�+*}p�Q*�~�K��z�ۃ�6��������P�u�][���\KA�RP�5��)ȇ�ƅb��r&A��\D�k
8�-���W��&���-+\�{
gІ����Z��H�ܱ�Z��)��t��$ފ< m�ř�l�-�ơ�VK�F=�o\���%�\���E�nL{,�ሤ����ٹ%�� ���w����ۀ��If�:�E��Ð���μ��'���5k�z��b�&�j/ 2�s���|+ΊYߞB����^��=9X�#����!r�����CT}���z�w�(���Q7ǱS��Ք�Ց�Q�rW�^]�֒��.t\F	�,���*�uVC0\��ae�*��_k�(�DՃc�l�{�g�K�{ܻs�,�;�>��Ս�4�W[��b��Jf��� i�C��{�k�*K�|�E���$�Ҟr ���3�쒆Dޡ��n7LqO+~�d�Я�	��w�ǧ7ʀš��$V��n���~�B��_�0��q���̥���b)Ђ���{H�G9��ʑ�w���1�SO�<Zc��6`5�z��F��xT�7O<����F�����Ě �g�Kk�6�p�K0[��L��t�����^��10���b����,���*���������>Jg�\�1�t�+/X3�_Em5�x�ƺ��W�
w��W
vwg�y��fʮ�ļ?Lr����pM��CW��4��h�m���xBH)�ne�Kh�A�����O�3+��]1<+��`����i��i����Q�����|�VJ�x  �-+�S�U�<����d*�C :�F|Eܼ!m�z^�YQH��:!� �lvSaԎ��$< �p�)����4�gmx�1�l�1��S�R����|��SdZ�%fq�3��	�q�)[X;����׷�%"�I�|ٽ?��ASp�����������H~gÚ~g�f�ݺ5� ��Yt��~P�ȏ�bpp������Կ��H���C�ѸV��i3đ���{	%#>f/�n{L@E�N�7�aӑ�y�Z�('��-�{��`ocE��6ޛ�s�E�gA+m�]����o�^<���g���<�|��d�ww3}6���ƀTI��������b��^£��a ��-șt�/P�yv*kQ�ɿ���O�{��o�h?�@W���H$�]Ӛ�kcj��Rƌ�� q.k�m���[(��n̽3�8��wð|�����2@�j�A���zrH�ě|�����P�?��޽����k�L��t�I���g6M��y�Ԏ�h6�lQ==2S��q�kh���`��@ttt���P�r�*�S��}��s��̾=	�����@`t��a���k2=;�W���1H��&֩�ͳ�s)�ꚠO;\�����o�B��1=��!��(A�!�D�����(Hg�^�gE�*�e�^���dC��)_��K$4���ݘ6l��/�P�b]@luI�m��P����7�	up?�j�����Rʎ�A�bw�⇷�b%�S��/՝�6*G1M�$�%��VP�Â��[�������M�����瑅����}�o���e6>�{A
>�����3��1r�����(l!R�E6R�=��y��_;��d�Nn0`qfĬ%X�Xd�`�"Q�C�����W�2�0v�Y��� -`>�I����6�d�k���zw��xT&�[b��|�N�v'G��)'�G
_]�6���w����^@ِ� �� �B	���'F|9��dr>���K�� *@w�E��V�mQ�	�(���Gnq{ߺ��J�w[�u�ϧ,D-5?�(�+��Jؽ�'�t�(�EV7o�Dt����������b�~�t��6����<��xB��D���Ċ�%�����3�.�We��_�ȶ�H�]>�%��;%�
�^�E~��U�=�۠���*o䠽�Z��j��&�*�=6DQY��+��hՋY8�<�G^Y�H��9�^=�gO��^t������2g/�)���|���.'�� 2o�#����J_�s�)U���yR�Iw����eR7ʯ�s�YP��� �|�`��nd�VR������8V[I��j��o��Pu�m�T;8�/�g+�앻3͖�H'��&���	��4u*՞R�&��C.n �i�P��a��r��_	���Ջ�R�
+,���fԹB�����g��yPo?3w�S�5�Q
]��D����U�<M7���L�s;�u�� ��p���U��~�Wa_�$�z��b��\��2\�d.��+�z�#4�޲�.�}�cET2��P���~���X�|���K!P!Sȭ��h�p��9֚�+[A�o��	������c�����K��	�V�ݚޅ\d�+LGr��@R�'�>I�f��~�fW�mN�aL�]�jR6�*Du�nx���rg5��W ¿y=@7�+hw-�oYk�_tX|Bݷ|;-��?�Znu����(o\�0�C��E��S�O0�v�	N1���j�R+�.P��k����5)j�~�g�z�O�%l�x���bw%�a�;��9�]S��S�Yҏp����~_�>��̍h`���b+)�Ϳ�����t�d%�T�s�7�X$�H�MJ)x����4kԍ���p��9�P��c*��ke�Bz��1$������Gݼ��We�c��%b�e\?�*��GAl��|ڈD{����TD`�+�>��9~T^��n
t=Dq�INyۊ��?'����* g3T1R���i"�e���Ԕ9y�/᳋�Y�[R�|�H���.�RUJzw��O+G�n��#�:h�?���],�������y�q�un����+�����$���xD��S���L(�!ɉ]O�"���j��Ɏ[x�A��E��<K��)�Xܶ�ҷ��ȃl�>�ix�$���b1�a��p�̈[=h�8��ѐ�7��{�@��-����}��l�$M�>�F��j给��]�us[I.g�N�	Tj��J�]���aw,x��@l���	���)19b[��z�?�S���OY`�r�xA)AnV�d��YS�%A���ybԝٸ�_B�ynG^T�v�P/O���o�ja�|��eP4��in�[�-R����C��*HN����i��6�yN.'(J�q�B�-��0q;�R�$��$��;�⋟����|�pO�T�1,��.^L x�s�g��<D@}�B���e��.ă��M$r�- 
dT��k�b	�\)�V�?' ���(���\�sh�˶Ĩ Vj�q&�5���E�9\A�� 3�
��V{~�9i�U/��q8����2�9�%X��a3궺��w��˝
�Q��5��/�q��S�4Q#_겍��4�?�P�s��@2wb�B�0ړxFv´<8b�k��vl��؍�X�[^�K��A.xX����3�A�w``&�SQ"'qʮ�/��ZK$oe�B�G⥃�r*\�26�C���w2p�E%$��x$��^َYL���ؘ9��L�9e��uԘ`+���#��k�� �U����/�H�MT~.Ȱ�� ?�#m��&���_c
����+ګ�6v��+�������9M�Mhl�$7词�R���R)�x��:C!G����� ��
��N�x\U���]N�]eW�	 ����)�H��P�nN�?��=r�����<bE�V��υ������pvܰ6~,v�̕������e+5/���Kq�����n��a���2�_��g@6 K�`[�w���Gӕ<�\��ݺ���J�3�U���5s��7ʋbAu�s7�7��v�I����k:�'�I�!�L��_n_�D<��yI��]��*3�.A�qg-HNT�T�EK��L� �!�%�P���!���
�Ƴ��!Ӑ��3bU`&_yz�MF]N�=� �7qK�!��[�& ��3�4�c�����J*��Z¹��Ï����MMB��a��c�E|Ud�e�T-T��y��O�\?
���z��o�9�'����T���Ύ1(,N-����3a֋{��ł�����4t�p��0A�	�Ԑ���![��ݸ��1��"�O���C;]+*8���c�l<'�_�^.�~}�~��l�r�զ4"� �&�\AZʶ���ù}q��F	��O���]��|U�/�%�my�]�0Ļ^Y�r�7W�^��� hUYj��Օ�r�x�+Ix��$dlr�)�co]�����1t���z����\�N���dDފ`:�v٭A����QwgXߨ$5*���ޱ�C��ҞQA�7Ƨd��-��N"3���������P�ϲ����ˈu���x�5Β�>u!S�*R��@+z���(�e��)C��0�^9�Rd��Δ����Uo?�6/�����
��y{�:J�Uwh�ݢ��lQ����={��фi�Yn͏��C�;W-,&B����RQ�V5m#o�G-w�jβ�Os(�92��*�9���אv������(o�>~"��a�N2�a�jY������ ����Pٷ�I�0����a ��O���y�<�y��|y���ß�H��D����dnu1��ĵ?g�5���]3 b�b���"6��^Z>ͣ��Ε�i����B���9b�y���7���t6B`�Z8���N�:��(.�t�2E4]NsB�P�-nf7RG��9~�e�vH�k'|�١�x�	$�hW���hv���.��ZUl��Y;P�	�'�n;����N�?��b��Y���}���X����gM�Âr��a�5�2��e�'�)l���U	N�+��W���%j��VQت�Q4���U��e�p�va������/�Ǿ�~��9�VfOB<��A�����i��U����1��W�o���~F��\�l�w#��*�[�Nk!(W�R�q���^g��c�n)��K����5{���0�T��2尒}Y͸�G`���ZhY~�H�*����<�R�( %0FF����̨%��6�ȻsnXX���ag~�pP�}M[�	\A�O�`RyD�����h�/Q�.X�@XF�D��b�*+W��Q]�R?`~H2�M�{�����R�F��Yc^*Zѵ?p��GNl�P�QE����f?��Z�>Wy��(�ʏ=�S1<uX�1�A.p=�[%V��
�s>�x���r߭$����������L�.G$���@j�S4��X��E�t��9����I�{�ZI��޷R�O�k!�[����ڮ�c+��v/&#��F7�Y*�;S^�7y��t��h�ҥH���g>`�:@J��ԩI`c:蒦��ֻ�րt�:���P�#�$C3,�h�3��w�Q��$:�'���t��
���!���F�T�C��'�/=�9Ԅ�	���0{Z.kp��e�ExW��숀�N��c��n�h̻�����q�K��Z^@�n��0x�=����N�Ax�7�6�zΘ��ZV��Z$�>��J�f:px�r�B�^J�]Qek�>L�����ywZr�z�����g_(%:�i�O��n��b��OϿ�Ý������0�Wp���|��3d�>�Ӓ�m�>)B�ZMX�ѫcI�r1�X�(�:�ٙ���IQ~za���(&d�B!�_�Q��q)5y��-7 ��qF�f�@�� \�!���-	�'�+��b	�z�EaV�[Ҏ'w� �hu�\䙠 Y�^ԜVW{�莟�#*z<�Z����X�|$Rk�K�x��y��M�I*��Ï�A�	,k'���B�{��q@)[��"���������Q%�D��� ܧ��G��OM^F�sg�
8�t���y!XSh�C�����������O2QGƮ�)��'N6敫V��h⛒��.R�a�mqc
Rq��>�[D}K����b71�3L<��󡢅�����T�ʷ���&osg�F�Uj�}}+'�Y��
%���F0f�gk/um��V��#��s+�.#�'�(��ōf�jߨ@i!�����_�;��)�(&	x�e�*�-�!��)`B.|�;��e�SЌg�	n�@�\�P[�N�E�nmN=�<`��A:,O�$^�W��4����>��y�
p�V"�Ḓ�ϫ镖ڌo[�����l_Ѩ�d�#v�;t�����+U.���w1�~�ѵ�O�����LKY���xtReC��&��m������ w
��§���_�eK�W�H�0Vs�2���}��}$zo��/7C�(5�E�}��`��Q͠���$�#��NRAB����(�)I��aU��Dl�o��Np;l\�WMN�e�y��cQf�� ���l��KZ$��Jq7���}C7�V��5��K����d�ͪ�@D�<Oyhv-�$K��Q:"!��K�ӄ]��*
��#���Z��i���ԅ����>���sP�uѢ_nl�����X��\J�2��-a9��[nџ1���������3�h]Q�aو�#Q�t����t��,f��L���8��7���g�����ʼ�m�Cً��~K.k���^H_�c]G�#�?3��|Tt�8�9M�|�Hl�X)�놤��DCF��,ѝ�e'������"�l��.�?7�KrD��jHFNq���!!u�J�|DR.N��aqGܢ�.�t�X�Lw�B�G��3̞�f�>�^8�C�ݕ!\�X��Iq�1� Q���&�QA��)Z������K�;�7�P�o6e��=�\�w*UC���`c����)��}�Ȋ�Y�wA�����L��}����*�ɱ$�3�����Y��,�	�z7+�?�ɎgD�����;�ݚoA�eM0-�k�d��)��;U���M�G�q�M:O�1�b�X@:G_�����ǵo���W<+pқ����)H�z�髪�1�A*�e�HP�[ara��a�N��^�}{
�x�'*�ͳJ�[�9�C�:+�v�'4v!*��Ce�b���%�Z��̓�=쇼Ȕ�䏢Ƞ����G1�'7�r���u�w�3�Μ��9�D�c���q���G�& �4�߸K�A��F{$
u���4!(��(��U��?o���xڜ���=	�d�����B�MWY�X���e�A̪�ľ���rP�����ˮa�Lh�.n�,A˒G�9BHO�s�'Wr��/1	Ѵ)�on�董�>o��RY���Cd�X�u�CCs3�o�I�>YV���_���a6 ��09��ߥ��1-�!c �Z����yu2���P��A+�P}M�Neu����ހ�����/���5p7�f�lꯓ5�=&�R=I��_N����U�M���5��w�2"nC��ҙ yNȲF9p��B��9>����#��z|��&�W@L�V��P��%p���s�JR{��6Lt��ՓB���%f�ͣ�VD�'�\���,��%5�F�U�q�������� +m^��]U���Y�����-Y	͘S>����v��S�"�I�3�|��ɱ�GK�yq��̖��Z34��|�.樎��ì7�o��9~h�U��Y�h�G���U����s ��J�(8��"�6Ɍɮ� b�������"/��(��Jw7N�[rΖ��(ӷ�<��7�NR
�|�:a��S��_a����P��S]w#��>b��$W��c�����(I��+�;��#@��x��V����Yr$�6�v�sZe�Eln	�H�42mP�������BM���lK;d�D7<1.K�xb>�]���)��p�Dr� �����wX��q�M�ai'^eZ��Y��Q�}9#駂���Z{n�C��[�V?����'�<���K	Q$�O��`d���1n���W6���1���
F�1��>�j��o0$"��Y��[͜��W"���\� ��BTj��N �����V1���g�    YZ