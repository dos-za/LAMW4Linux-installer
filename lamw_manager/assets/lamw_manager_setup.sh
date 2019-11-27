#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1621004791"
MD5="26103e3ff7dfccf68fa1fcea47bcfa4a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21128"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov 26 22:13:04 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� ���]�<�v�8�y�M���tS�-N���YY��/�Jr��$G�!�1ErR�����9�00���*���l'����Z�
�B���?��5��x���_<_���ϓ����/6�����}}mc�����W�D,4B�X��^�w_���O]w���pf��������z^�����'d�q������>�]}d�s��}�OU�����̶L��	�h`:~���G�1�<m83[h��T�^0�C�c��cJ��̏�K��BD��C���M��#v�����\�X[�Z(�"���U�v�،�foBB�{��Ǎ��0=���9�	48�$����4 / *��:��.��Sg��W�B�|h�o�k�c�w�7��35i��O{��i�8>6H4���^�P���~k�=j�i5��Z��Vo8�[oڃ��	������r��@�!�08��R=�@��q��E��6T�'�-�`�j���z�����ŝs�J9�8�w]Q[[�q�{�6g'��eb+�Y\�.!\a � �@�5co6�\��S�5
��C��y�;�mQ�@Ӏ��ۡ���Q*	��p��y���s'�+d	f�AvaU�0a�/`�����س��Ȍ�F�9
8c4h�>�Jel�D��X�^䓿�i@}1,�-��Lt��u7r���ڟ�7YKvSY�u�"��s8��i]z���p���u@���ZFmvx|��n�	-j-Q�)*'(�f=k�:W��/]O�귤
�3`1	=�2��`�l�VO(o���＃ *d>MQ�4�uj���e2�A�3M�,�a-�M�+5���y���v=��Č�pU�F�üS���O-Q�ڳT�d���i�]ϱA��P��v���/����~��=n�j���M�l��k�-�M>�>�UR�Y�"{�0�e�G�K��z���ԴR�N\E��	!hq��b��XJQG�H.QR��IB"�����)��Ma%�V�;3m7�T�'NV����</,�O��ib,�j,��>�:5Q�<D��*�`2;� �+�R�M ,����[Q�6�<y�,�����;%}��Cj�ë����[[K󿍍���������k|^z�h�"Fs6iG������hS��ʯ(��G�����6�]Lׂ�|j)D�1:��>I�K��� ~A�ߓ��oll�k}�Q��3��j�^���}�"�Q[�1hc��+ivNڇg��>]�$�Edf^s����Ga���dϦ�$�>�y�=�!'�`��q#J���|Y`1��̀��NV�!�_"W��C��h�mQǞ�2
�L�\g�eԙ3�FH<#����@�tbd�c:�!�a�]O��mO�:E%��Y�;��+G�_���xD{n&L`��2��3G<ӡ��:y����{��uM�[�8�{��_���ÿY�}}����5���WmَE�:;���?l�ւ��x������Y�_�76�������3�\�0��Єԇpd�����w@�ԥ;H !��_ģ�F�d�����5_noi��Z�g[_ɱ+U��t���|��X���8�3-���6	�M,��?�=�͹My�Ҝ�l,x)<@:�6��\Q*�7�=�Y8� ��Ӵl3ѺK�U,3,�p�z^X}���"7���u� �L,]z9�8��	/����aǶ]������I�9VRr�326�k��<����j�ID��n}P�� �q�^0�&�����u( n׆k��	���{�nc��P���c�p ��J`̓�y '�>�L�({��V��2�;'~���۝S#^���k�H5�:�������%mݹ$����$Y���C�4E���º���HAi�ʋ�a��S�?��@���K�������?�4
3���y��hF�������?{��+On� 7��Ll�E�h���/�t9Hj�%�^�^��Ϙ*^�+鮄��ե��f����#�g�*��m5����� �DU�N�19�-��as=l��/��J�g��y�d\T!ߥB~z�,��	��������#����b��HV����6נ�`�E���B۷�g�9��QL��v7>2�:n����윴�`�s�SX@:$��W����-7�%3��彪�>֧��%�K�t�T.oz[��6b�.��Q=%�[hʓ�9���
���C�C�8�T��h.V /^,L �b��e���4��8�=7�)���*v��@J�]�`m���£�8������L�ݳ��;l,`�;0T�B\@b�X%�~�/"*��u�}���Ջњ�W�W�*I���k���3��*_n� ��(nIU���I�ıs�k�G%/r`��Vl4~����~���������,;O�F.ހ`�^vnL�EZA�;� �2i�5Y}j7���I��V%�j�p�V�d�%���Ǧ�R�W1�@���v5�,��$��ؿ$��W@^����j�@:�l�:HT�˺����[���CV���n?@L>���������Qw�@-��� y*��$��c�f��db��r/3��M�T.U?m���{��#9�sA�|�A4Ƿ��M�!�DT��[؄��4����ϕ-�@��B�=��T����&]u98n:h4���N{�Q�΃�S�$d�͖��Djx��j���?�����3BR�rޖ�V��#	���Y6�T�Ťk�/�)w�u�8;�7Jm�(I�mעW��K�����x���O^k.�L8�Xe�����kFL�a�lpeX������b�������������~5ә�`��������D�X�Q�{.�G�]�zsu�x�����������b�o�6�9�A4�W�L~גΩ�������:���3'���%�����bv���� �O����~&^zQK=��2�"0-L�5�J��1�e�QN�%H����q%y�J~���#��k��4��B�̢s�MB��v�	Y����Z'��Fl�~O�A�ƶ^Q��[h��U�t����N:�-C]��ކ��^�k��M���]!��Q*���q"?K��Ŕ�y��h0�k�H^���q1�r�X�4��D��CN���?��c���䮨�*��\�3�|��h+G}3<7�,5/�U��T�.�E��<��πlQ5NWC��!h��iR��X;�5B�� A��Z4�)J��)�鍕���o�#�ݤ�������*��Z��!���ch�:�,^�m� c�1���:�xCܸ_�z��0�;z9Q[�u?�h�B]t�*C\�TV��(�5�g.���	b��rJÕO�?��1A謈]�k��߫�����Hb[H��YxC�Hr�#,B�¸n�.�]��\��ə$Do���D+/<劻Qg�3��܃Y�zvDA�&�X�����ax�
O?��[��I�k!q�WS�T�Jԩ�����Zݰ,�.��n���&D,�-�a�rcP�y�� �bf��T�>c%����.�ݩ���-�Dn��v����%�{��^�N$�H���!���(�����Vk2T�9]J�.Ka�|������WWH1�O�V��1�i��'�b?�t�h$n2k9�{p��L-5(+�����w��F�I��e4��&�ՅxQ���k��&��1���S<Ǟ�
��	����� 8��0�1�W\�R�D`i>�I�"3�=�
�i��/5��#�ǰ2���Jf�ҥA�q�HO�z�s_��C"}�B VVr��1�n��Duj(�S�.4"J<v��b�1�,K.��� �vb��������F﬏/y���1N
)K�H��q欙4M����z^��eI/'RT��{yT�9/���?F�+t��8!I�z����%�)O���ڮ�S�*1������w߭��O�^2���V�x�$�;�O����w{�e����F�Kd�.���ӱ7m�F�e�����!Gn�\�Z@�;xSb� &�*����z(.��LO҃��V~z��݉��{��r-�A;��m�O.�������}���!nepq=������.ČI�i���;���Cs�������ͨ�ħ�l���1���g����9�gPM�t_:#�x�|�&mj�Ca#����FQ,&��Y����;DI;�eSC��S{�_�Ё�k� ����ܻ� Vj�b],ajzW�3h�:�C�)n|S�BP� �"�νC�Dg&\d����;w�le}�+��s�s?/RgĿg99{)���@��Žs�˷`�yl �1ɖ��䌺���C���wmŒ��D7}�I�{H�����
r�G�7���A�rN����c��XX�򥜇N,��)��3���>�J�.-���m�����y����������"wQO�5�-QSSo��]������8w�Z(r7M	����&2*�'&�>�O��ʢ^��el9)A�1��<L��m�b<�
"6������h0�]�1&&h�h������-fC$e�cC���l���p!�8��������+�>�)�_�4��"�O`;9Y!�
�+M�!��O����aM���>��J� +������""Uڈ卋|�س(L��b�G�l��Q[��u �J�GpX��;�y&��lهL�zg�v���Na)sں
)��}���1���L'�F���h�n��o��ھ��I�N\��J#��mOZ�g���u�$��:�y�9���+R6����}��~�4�t�y:H��ƶ)�����E�SǯO]oF��R����5�L��4�-��3r���B`�R�L� ����3���&�-S'a���E����I�(Ζ������#!@��ٜ�����ރqo�뗐������O�<Q�N�	�o$*	�(˚<D�`с%Sڮ�Bqb/E�c���P�w���(�ԟ�O�`rmQ-�#{�y)@Y@T���0�$��Y°��L"Wf<ͮ�~��t��j7�n���~������`]h�̂��|� {�mu57?wP�����̀D1G�����
=��c:��C0�=��9KG��
�<9H�"���&������$M%6�v��'� X
�)Y]%Url~��'J` ��S	H6w.����/d�٪K `Zr�+'�xK��Bg��Q&�����hRrJ/��Y	c�eҁ�:՘�� ����3��"JR�ƏB�Њ}���_0�K9$uƱ�)��B�E�~�`�=�E�D�.byiW�X���}C>C������^cX"���qb6�.��a	�446�D:��8 x�:n��dw�c-��윀��:��I�j<�V�GV'��w�wՉ�EW\�VV>���Uʘ���3��TxW�{x<�.�r\+4p���������;|Wyi�]�ֱ�z�2��jy��4'j	kT�琻�.	��e#����\'_$L2o⅐���YvGV�,&�Upu��_W��?D�aN㳅���^Ä[��,�������Is^��NrJ��$EJ��d�G�d��t;�T�ݥ:<)2%g�dr��d���_�i�>���ه�Ǯ?�q�@&��T��v�<���k  _\�K8�����N��,����'*uw�U���JՏQ�2ί��7~B����ym�ö)�~E���v%� ��eK������(�{2��k��/��t�<�D� ��V�K4�)���!Y�D����F�(W�m�=�&��џQ't�=!I�r7�Y �b(���t��W�X	���U/��5-f����+sv�/JT���o�Z��T_p����w+��pXy��c��r��L��_�'WΔ*�Ӳ��Q�L�|cQeFZ���,��20��%t�4�yK�˵����j��\�Y9�!Μ�r��nI��7l�:�fTզB7�ttLX�U���OD��<����W-2��T���z�.�	���{�5�=ȖH�H�#�d���*��|"KnL3���.Z���φ���?TD�!]#���j�-:�.�%���1b	��`����I'������]^��&C����h����r�~��z����� ��~���Q(��'�q�gu��̏�:^~C�6�k�FS+_u�n�U?p	��l'��`�\U�c�����(�h_w������ﱏ��ˢc�`�}�9�2�|{�WYi�C�l#"��Wԯ�W�t��T~
e5�g巟I�o��d���⇽7�!�\7��6�C�;�N��q	E����:w8���*�6�`G}b
�Q���:�&���ŀ���k!y����2KJ���"������hM<��sS/q�~f°IL�5�F1����9�҃-A{*MFV����y�}0j�wYK<�տ؆ ��4����r.�fF�����m��KtQ�t^#Q�S�W}Wt$�lT��4
P�W��b���/ݥ��Gaz���ȴB>gMz%�T��*i/u�c�Hw�TGW�/��6�pv��Y��öO���H���)a����|F��%�i���6��ڍT�o�6��̑F��6�uד3P)6������Br�5+y5|-mJU*��r�Q������1Ѿ�~��Z�IS�gH�f
��%�<����O�Ը�X '�y��	7���8i� =��v�i�e6S�������)����/-�����U�a"I �|5������Є��x�^���}|l�;��^����c��y�O]��s�����,Y�}�#�
���(��'K7J���d�ek3,?�#����ӗ�����wW~��9�"��w=�u�9�I�x77�J_^da:�e~�#e�7�Wsn���~4L�m�=���� �QX�L��ʌ�dn���i�8��Rx��Ĵ�ir/s��T�b�x�ht4��L�|���ӽ�w�┞�s���_�^<�).=��8���V��ӆ��ؕ�[ʧZ�}��}!�&P����y�����ծ��[�%��[��q�{'�#�ב��(�sd�YG��h���øe����D���|��˳|�}��W�
y_�?J�eаI5G�u��#m�>V�:�l��N��� ��!�~]5MR��*v?O1��؃{��� Fs� 3S�)�˛v��,۫�O�hg�G'g��v�(�ܫ�^w�:H^�?�+V~kf�n��S~��ljl�C�s���D����ܯ�l1�5h���>j��H�g�h@^#�e%��������쀗���iN��Ul�Q�j��1 �lU�ՆY�}^������%���{�}s

�R���Sy6I%j�����:!]��>?�>�KZ�ں6��[��DQ�z]}��l�K �+�ǫ˙�ȗ PT̲��(��$�Q��d�C���v<��K�|����2��t`�o�)�ucα��q?�ẗdp�DY�_U��\��:�ҩ_[[�"*�םY�IJ�K�o�*;2�KY!����O���6C�Pnc�,3M��3�b�6F��7�����*k�ppm���/����GͯW�|8t�.,2M���m���W�˗<������u4�h�D�'	�����>ז�ձ���_{����Ԥq�R��_!�+_�%U�D�A�uYEkV��e��Fz��&�bZ�ei$�F��W�s��z�øx>�b�i`�]�#K����YU`�d؃��Z^Q��-��K`�0�g\�	Jw� a�Y��ɂ</���|�V��UA�,�����|U3�k�+�����]�zq�5!-`�-p���XX�)��p�1��Ta#����I������g�S�'��9��`�a�̙x�����5� QZ���_�b�T��ɟ�n#��f��~)�7~�_�"�GQ��9�5�����\���"���m��u���V���o�7+�׀a4�Yl�Gb�ÀD�Q�C�(��F�����9�������4�d5_��+��?z��/��>�C��W�&��#t�TQ���=��m�����[���~�}��į���z��u�6�o�w���~|���d�Tf��������m�I�6���=��l��iV6o�����|�B�ɯ]l��~��-��ҧ����8�_u����^�X3�g�V.G��3��ު���R��=�B붃^g�ģ���R7��a�2���ɩ���b@Μ*Z�`�;x}OnwV8�<�k��#a4�G�7(��t�#NQMlSv˦�Z8]�1�ud�n��R?�E7���/�y���Kp;�_�z��<�>h*#y]�c�I��n2��t`wV�MT��=�'����Q�2��"���G��˵�C��6
7��w�4�I��7t=�xp��N!Q$hV�2�#ߎ��������9��$�J�Z�'N?�q�G����U"��@W��(I�CP��J�[6-a	�մ�R^i���s������Wl!�nC�-T(}�'({4WV]��7"�TT�n-El�т�S��%ZWZ�_k��ZM|^5��e
<��El�8r�R��Cy��=���A���_�*��i�F��C.L�p~Aosp�G| �l�������U;)�	ks'�I[de�:��;=��io��l�K�#C�h����.�m7��.�%;S%�Ӵ�f9��q�Sas����3�I�&��}F���Tq"�ya�B-tJ���N�)�߹iIf����ӫ�RfbQK�Yp-�0A�	*�+aR�*� �bh�a��q���!E΄RiR
��kS������t{º������g0̨�)oL8��u�T�h*�MXˇK%u��~)k %�5"�[VʘWf
�F�L��z�6��d��=N#���o*1q��I?ɂ��Ky��}��>��������Mc� ����$�|%�K�@,<�MÄ��ըeN��+�����ӺD�+���
����\V� �׾Bդl��iZ�\.�rHkj�~/�?ܫ��l�	P�KOd�����Q!k����@���[a�IF*�)(a�ջ�ez��FF�3	M��3GN�Bw�5��fEQ��%�Z���u�CQ�h��hpG~��Dp��`�i�[z����͹֠Ur�:��"�����������8�l"��!�(�+�!o��l2��a؋���2��U���1>ٯ�K�UF�9�bds�E�0�War>؅���j��,�����3�B]��)�	��ɸb�vt\��±1;�@x�r�
�󰛐�±˳�^�*��*s���T`�B����+ߊ�NzE��\I#��v1����1Ԑ�E���#q:���1z�;έ��o�ݤ/(�|d��&c4�I�N�"����Q�	�$N�Z��G�-	��>�p֯���E�V4r� �0��x�J��$��uj-7i�)ñe���I����%v+�?�����:
߼GֹDD$�),`��'/���R8��	*�b�,��C,��dHT�bϴE,�*�a�!��?�\g��%lU}ˆ
E�$Paj���A��}�$��l��jb%s�Tn�9�u|S��	�h��aw5��S2T.���~�����W�8��ÎD���$;q�AŶ�?i���+8��"���<ʏq�dc9�\^�ȋ�9�g�6~bϹ�%���0O7�@ҟ0*1?���U��H�x���s��y���������lq����~���O]�|�����F�z�B�˂t���,�0?�J��K�Q�ʰO��sH�|�Jv��q��Cd���n�F3���8�[M�ѽ�����V)��Y'�\]�]E��G@��B�5	%F�g�����RA�dNo
}Hڡ�0	�7�D�\�ʟ�IP�lg�r�k�f�XʓP�ݟA�#ב�
,�!��]��[ZU��֬�����͕�	��@�Ay@4Kh���ȃ_&��,@f�,�9r(��t9�M�%$���������xA�\+�f_�C)͞�E�3�1�eqlR �L"���Uo�ά�L�T����@Ѱ5Ɠ�%l�N����i������ӳ��i}2)aD�!�_O_�ߝ��o��zK�4�`X�(��@�#Y��1��_�}H������a�&���#�G�nu|rixRE�j���
�j�
�b�\��e
���u@G N�B�4C�S:�U�jJU&�2Ч`�O]m#�*�͚����	����M�Vڸ%+Z�*L�K�2�x��������8�oއ������`k�q����y�f�$�Ϳ��OwO�O����q��jÌ��ȼ,r�zc7È:p�YX���F���;�fh�!�lJ�:�5�K[���(&9��8y�c)jh�o��V]��!fP�pww�}v���.�L�z<�(v(���Վ���O;�	�Y���O_�$��j��v_T��t8i��L�.��3��Rz��l�W�F�f��ʺ)���'b��f�)��G:j3$�+��,���-E#�@=cAS������А��ԓ*Zۤ����C^�m�_ �^MJ�BE`���YA��rd��S�?��M]�v���	�S�_����;����a��/�]b@�5o��v���(��>-��X��"^|��{O�CD߳�~����I _���@�$�D�"V��oA��&�8��09T�&7������۽q�������3�T���U���*�aS���i��:	�:�}!H�~Lzc)^�?�J������6�^{��o.�pUk!Ɍ)����J��{�.�P�D�P��`�KS�Y��f57�Ӑ9����(FKk7���,1��V j�G�r����q<�2#����B�;�]���
��?m��>]~9M�k�H�
�ƶs	�=*���e]�aS�eH͆I��)+��O��	���I&�ǲ��������e���R�e:W�o�p�!e��:'LQ�f��|,4˳�e�L3s��!�:�=g� n�Hሤ/����Y���$�s�l�=jL!oK^��m�i*u��G݌Ҽ�Y2�s�<O�.薭
�"|� �?��Q&Y�m5;{�������_3��^I��Kf���:g�	�4��"(�f�C�d�����F����-u>"��w��JB������S5��N؍���GqB^u�����ںu}m��U0�G��u�|� ��v�6����ҀTf� �&�JF��l�����,nl�9��ZE3Ş��xU�%������GĆ��7����P�d�`o<�U*��Z5q���:P���ԏvAZ��aC�ak=�>�~�{�~s�cT�#���6�4���4������Jv�d{S�nH�Z�ĺ��l�Z���m%pT\Z6i����I>ħ���E�~�8޳h�.�
B��h7$�t�51�4%�.(��;����D�٦ժ��P"�W\VNv�w�[��*�ӣ1�P+��mM����@f	�S����NGGA���MPU+*�Δ~�~�]�?��SK}��fJ���ꍯl.H��u���(����ޏ���Fx=��
3�������kSh땚��xu�aLS�h�T5�d
,l��l��Dv�]�^Bp��� �a�d��Z�1�j$SO���C1ϔ�grO�ȇ2z�{�7}oQ��=Dbx�V��2�W�������WA8d_Ѓa�,Y:aQ��Y�fЋA4#�p��q�0+���[r��Y��/Gb�h�s����qFT�
b�`zK����|4�h8��pDX���˟�{ì&�y�=��s���3F�!'�?.*'�42/�f��9�feR��NR���5�.��'և�.`�oƧ��ʾ>�\�d��wU��(�p��m���_'t��lȄQ7YS+��]k��Z�V��f��Hm1�f��Jcs�I¾��^h$%�/�	
�Jf^*LY!|a���:P�y9{��ne�������k�$��"�T�xw�+�ȸ�1vǿ��(��j���D�4���h[2�{o���$+?���'RD�U]'g'��>^_��bjt��3맰�����69�[V0�!�bf��iDk�R�lP�|.�ޘnA�Q�}�A�`أ�A�k����p4�ǫ���I�;�rC�1xL�~��VbM����:�r3)w����3�b��q�� c�\v�1�m5׈�n�M�+�Bm�)Non�'Jߛ���{�䐆�c���9����<mL��J�W�����<������d9���}�Z]��w{���z��׍@�;�]M�Go���>�ls���\0U|EzƬ6���,�2����JtZ�T�J�����p���H��Q@�sR���u�xZmT���DZ-��|���U_��*HP
���'�w˻J[���UOg�@��_���/G�&wR1��x�΍߆fK�î�OS޴� ח�T$1�H$���r����WJ�����n���7QE��>��x7E!V|O}����"�ن~S�YLo�����D�'�4�W]��VAq�H��"�BR�I����	��h�����,K��i9q�>5�������X����	���n����c_3�.0��z�ty7�
���l|�S�nW���0g�5�}�vO��l; ɿ������_�>�ۗ���a�Lj���?m��q�@rN|��w�R�A������ҊY��чp�����f�ڄ���H3�%�ă�C�`YHh�9�Ճ�$7sy׋�m�(��Ex��8]�� �K���I��#�Kl���my� ���iZ	��j[�c�㷥^�9��?9�Y2:����D3%C*
�6�"b��UT�'%��э[e	�#C�1�s�S�M��螶D�n�8���[H��T-���e��.�=	�A4�6#3�XR����S��e,��\����/U���N/5ݓ6xb�g\�-�@ІG�ޯ���.v��:�n�cE�4a���@�Q��\(K� #�Ü�#C�NFx�ٿ	=0f��̴�d���eɘ��Y1��
j���݁��W���WQ9)���|��TLY���v�4�ǱP1�Ĩ&"^]fYǹ��ü��Y��9f�O��_�m��)�Ϫ��:Fh���׶�+}��*�_�C9ߋ��Q���0&xvA��Jn6���'�\��ΰ����u���UQ2
y˗_�=����VA1L���tx��)�*_�PƲ��/o���6p�lV �K.!��f�fM���35r4���f� U��u�	���"Maǿ!�#IQ̽"sA/�%�,��-�i�3cҠX;?�R��^.�f�?6X�C ��B_o!������}�P��$Ș}B�@�j��ϰ]��13�4"��o�_�P���6�V��A�"}����{�Ȇ���`s
)`���E�A� L���X�O�n$��&�{lI�QH���z{���q�J�:gnQ�植aIX!ݭ-��ܱ1�|�k7�����j�e+��
�a�*;���˅N�N��+�_9���^��p�C�8�RK�~V�ggu���&�rF��ܒ����3��	M�()L�ә�B���jNgP
���Ci�;	�+M����kz���@N�w�:��w��!����0�Fv{��8>��1\4q��+iȚZ������ʷ4��f�0=�]Q�;1K��c�-���X��Y�2�ʅP�Njf/t�����{��%A�>,Y������A�e�δӛ����(��
vnP^{X��2�R��w^�����g[%�em/��b�.؜��ߥ��,���[J�M���
kF�Uo�S}avO���djZ��j�F'{��K�v>���~G3ג�}�k�$�ė�&���uR�q��أg���u/��y��wj֧͟m�`xz䲛��)�i�������m�}2u=��3�l*�qp���fﴽ���h�����$�g>\�-5V�8Y�2��W���qxS7�3j\�FBQ�/BX��/�p}����aFV2�R%G����k-���[?���v�ݐl��G�%#/��v:6���lD"Yf#��uw�?a�%,�2A�vQ��DPF0�4v�`h��anN�-˱gͮ����w�¼��vb�dKU锍,��y��s��m����Ir'�72,anq�!���V%�$ԧ��/���ӧ�o�}#�gm�����+�[Q���ō�}�Q��.��uV=l.7�����M�:�b�'��ՋQ�g�Z��T��
�Wʲ�A�WtԠ`��P��L]i��YYZEЙ �mx-�־�������P$x�**|����d��#}}��IRƜ�)*�!�+@�!���78��y��[	�a�~����
�Y���Gה��W�d�O��Ϣ����'Î���i\��S�/d�ep\�Tdv�&�`7*��$\(*oEI��|��;���^�Q�LY����!��Q��?���r���],����_��u��������>'�s'�v�k�rA:K�NȷTDP$4�U�������������J(�[uNC�ys��(?6V��������t�-z��`�_������H髞V?49LVQ{��t ���5��,��S5���iIY���v�)�l��U����{����<X�:�q���y�3��,����n��w���m�=h5��F ^~�31^��S1��ɼ�aw�����0sL��6g;5
6O������8�	G䡺��'�z0ӣQ�Nɿ��[����hS����v���T��?��m���V�ŋ��> v��ΧT:4A�\��=9&9�i�WDXU���?�Hz���SyYg<u�^5��,:��<�|��;�g�����尳l�p��Q*��~Yִ�#AkA���Xr��;=:�y��{�B٨���*�b<:>5ZgA��d�>���$�N.�c�Ӥ��z���s@���mZ ^�E�� �����k ���;Iec}}����[����>S���v��d<�����3��ڢ��c��Y6��g�g���o�}3k��iE�P��zV�W뾗qәJӖI��_�jޘ�	<�y�7L�B�k�ʤn���r�9&[�̀sY�
QwН�ie��mL�����aj��nM3��ܜ	���m��mVU�[s{��"s���lP?�{$L�\eV��:���N�ڑ�U���Y���Y?�GSHi"�k�U4~?������C�S�H�(�[\	�
(/8UM���eD�FT�ӵ�vvU�)���1��� �Ã�D�b����p�i��d�h�r'�&9�x�v��6R�Ţ�
�dtB��i*�A��������Nw��n9�񮊌��*���1�_rh��Q���c?����e~����H�˭3?,��ӭ+�ciϭ��&~����)�0��`���������ҏ'E8�I�_�$WА:[��
��¹����3}�a�k�!f��)�����LL�;��ާR��o�S�AO&��SB�5E��)5�.&�3F�zJ;]Ƌ��ys��'��G&��s����g��M_����p;g�v^��?��_xυ��grc����2]�����~����l*����*�`�&���>U���Q��#�£�ljm\%�lsaĳQCo�syeI�wH�	A m�Ҩy{������z�0��/0Ū�$=�X"&��_��z�E�r.y�m[�0����jo���)},S�%��Ƌx��n�ś�3%?�������3I��.5N�}�c�x���>�_?|�N��'�o�������W2��靍��m�5W�
�t�-8#�U*�c�>�D�n�2�k�٘4JRo_������ˡ|�O�XT�7�@ ����٭0\�k�FE�d8�5�m��&˟i*~p���bp�(C�Я�U/;=����������?��O�p�hy�'mK����GE1�1�9��*�z>8�=�+l-���z���A޻���J����0�x1�4v�h7�/�#Wq=}�q����`��xs��SQ5�q՛���o���Rڦ�Dh���Ȣ|/H�0�	e`h��`��:2��t/���h�P�X�\�󴌔ù�K^�><R�aÿ�d�d/�>�&d1��/��g���?��y�6LnK�qWɼt�������'{��R�a-U�n�ښ�����<�;�Q��o_*#�x��ET٨��6��"�՟jIP&.Pe+�:;F6��B3OZ�-�e߯��W�ݜ�ESj��g/�M[Ig(����Ͳ�4���&�)7�F�y���h:SlE��Q0��
���GX��Q���V��=1����ⷆ�}�YJ�e�� ��o���g��,�Xξڇ��^�Vޅ��!w�ݨn��p�^nN�����d�Ҧg*�v<��CDd�04au���Y�����^�FZ��X������6�/���ۢ3y�����4�z���2R��?�5h#έi��Y�ս����B� �e��y��v0>n��m�p>��_�Yzw�c@؂�O�w=]|��~�1f^qi�3�ڬ�n�+�4�]oZ�ԏBƧk5t��*��(L�����|��٦�La��:N&)�Ƙ�:���>�:������X�<I�ڴ���T�b�p��>! ���� ��=9f luvk�4h:��5��`�5�5j��������R2T8J��*�LT��i݀N�tL�͕٭�i4�[�
�a�����L22G<W63s%���y��so����Q��H-����ó�׻'�ɚh�S3ג9��`�X�֟U�2�k��Ҿ�c�C��]���׷t�[�;����O�"��OD$�J�Dh|x:f܎!=.
O������]�]b*E�C'�[3;MB���J��N�ݪg�=δ������o}�����Fca�����a�uo0���gƦ����q&c�*�*��|�%o^�}�O��x,Z���S�ή
�?{˭
�ܕͲ%��ɀ��񠒠5��<y�P��
���wR	�x�;o^:���OV���Q����Z�=����K12�/Ѱi��J�����}�����~pu�L�� HhQZ�)���Juz��s���9�9QZ��V�!�F��=�g��~?ӿ��<}N�X:Hm�w��R7�8��4���m��hu����l!6p�_6�:"b�`�j�*�ҁWTF��[�,"�DnZoc�ԇ����������RƘ{6j��!X�� &QZb�by�8�꽌yu������/�S�nMlJ�]��<��ͽ��l�n���!l���:�ߩ�F���
<�:��\^��YT�fY�+�'�`���ib��>׆���gDņ
j�<�jՀö�m}����Jr����=v�D6�Hb��ȧ��;.���	˯�l�iQ����k	5����$Z�E/T�pG�R�!�,hWR��S *qy�c�(�2~� B����ʳn�DK;�0�5�!��5O1��CpZ��'�p����e���ϙ]OO#��(�����'wx;��qC�:� ����������'�	H���lwj���u�Xk>U�6�'�����3[�PE*Ίe��K\�����[� ��uv�?"��Q0#��P��54�2���9��ѣ4 3챯�ih�,
O��YT.��AY�*q"�;�B��?pE�dc�F�]ث6U�9u�g�p=�.o������ʆ��BrK�t�T�S��t%�㹏|�0H��oI�}7��{o�QA�O��,��72b#)@��Mz!��Ri��Nߞ�a+�;�vP��a��,�:��Vu���I���
�!緾��w�MT���JZ���,#]�NI��o0���;��b��n�\�0'0t�H���e�������<���*�ѫ�n0�E���g�&�\�V䍱4tX5Pf��k�cso~G_!/ݶ���𷿩_��J����*�2�\�e"V�YR�L�T��L��(rV�XQn��(?ˆ+��؉�+�S�N0��x�vW%��`D*��I�t ������BHB�уp=�dD�:���0P(��J�bO�܀�K��Ff��a���f�I��H�b*�y#��]p][���LA���S��K���޿H�����OC�LTr�T�p��f�b�v�`�d�R�bZ��:�S�f׷PF��"��� ��l3ۦxe�N��]�X3!�+�Fd3/,�:�J�vB�G���Bw�o��O�;s^�ˁ{np��5�%V����m/-�Os-�E��Ujڴ)2
���I����G��@�Ax�B�AJX4e@��o<	�^����T�C�4��3
��x!毊���дN
Ɇ��XK�{h4�(
,�!+��bq[!�C�at�߃��Z�Ɲ��E똁�����O����?������5���W�a���:�k������?]���:�6�A���^_yKx[�2�r�F��e�е���d�B�o�A�#��힥��WI�/:��{�
��2�G�ejY�z<����+��e-xUѼ��	��D$ %�v��M6�}".&cFBx���wp��RyY�_Q%�^��������H�X��_��}��٪�^����W�;�E4�4h�[R��YQ�O�_�^�*S����р ��4��A�U~�5�bJ�Rjɏ��KH}�A��d�-�"�۶.J+���75�zf� O�)]ѯ�G|V $��KJ�@�$�ds�&��+��
�����65���`)m3�����3��}���6@�>Ibl&~���M�]�?->w��a,��x��9�Y�_w��I�5�}m����Z�/俯3��>��CtcCe��1W=���^ͪ���J�_��P���h��O�����o�����g�j���8c<LYZ{�Gǭ��g��b�(x������|St~y���C7�l�o�!�p�+�3�Ki2Y7��]�^�U�Vu��+��埰j�z�JG�cCi='�^�
�ng���d��Y�=��J��E�n��}�}���	�"W�Q&�Z�>�Fo,�bJNô�]9�Y�7j�> oH��CRC%}�����	)�PbI}/CJ!�trh�iO��3 K�m�ͼ����"cj�'��f2k�0m������\(��SΪ^�o�I��Ȕt�`|��fs���O�ۏ2�OB5II���5�4��l��(T�Si�M]�ڮ��Ю�c�-ٚ��8K�����P�H�B0���"�{3St����7�x2� Ѫ�Un=����
6�s]!�Zmq��[+�Q��a��c�S#�U/����(m&^�=LJW�}Y���eoAl��}��9�g���G'^�m�K�q��/��qM-��-$�����N/ ^�hc߇S�͡������������}���'l�oQ�%1��&��<ɉ5cF�,��儦�;�u ��S��`q
��UN�g�[�R�V*��dE�+�"8�$��.�+��zq�EM!K+�ɏ��=�
L�x��%,-�&�ph"!q���`O^րhL�wqN�z�}���hp��Qca�rg����/k8*ӵ�l*�l�S������,h����}�(�j�=��!�w�g������*(�a����c-�����������'�=`ז�S*.b�2��a0&8���+AxUϻ&�<(v�NؿGO��!
 ]2��~��Ck��&(#�.���!LQ�ԕ�#,��c����K�{$X�|����g��Cc��C���3�����V�zԪ!�N2��"��NL���L�vB�ƊL�#�ݛ&U3�ή��j7�oDK ��͛���$�����GJ>������yw�` )�VL%];��\@�#]$�E�o��@Ce����;��)l��%��:5{I^�w5��N��_+���ċ".��K���N�M*�۞\�R��=��_B)յ"�ܰ��P)t\�{j>;g�.&��L�����T� TY��0��8�yZ�P0���T˔Z�Ѳ3"i"RPT�-��x�EZU�w1�:
*�l�> ��t`����w~D�ƈ�{@��jŪ�>��j��B"+�3q�d��b�~����yM����Am�|&�5��T}��'0��U�d�7Cc�*�_���SQ�D�zGߝ%��Dgs�]�L�O�L]��"�p����<r����Ap˩�	s��[Sc��;k�ˆ��݌iP��d���e�F���}L��{��߳���d$A˷����01v��V-D�������CK�����ϳ�������W�<~���"n���"�J}�
��W�������Jx��"S��Ǟ��1^#�7\��
���6��}=3�Y���}�?Vϳ+�Dc+zI�mZcE�nz��)}#���WSk�w>���W�Fs��Z���̾S�~�7���Y�q�.�W����q�m���<��w�����r�� /cgs\��	aݘ����d��k�����}jAN�U��@�/�@g��|Q�T8o7�E%�x��L���XF)����j�[��w]�����R 3H�Q	K��5p�)�Z�~���-��6 6E�~Е�l�)��E�1%���Y��4*��,Z&E=�����ʢ�ͭh��D�����t���l�F\V��*�-rƤ�����c $Ft��L*�����?kϳ��O�������i���î���pD��QR���C\K�ғ���]?y>^ƽ^|�*������c���a���|��8B�KR
+��X!IC#�B�5۰6<���E/��v���흃]`{��Z��Qz�L��xu"(�6u����o��n�a�Nnꌚ2Q�UJ�2�	��$�^:w�bT!���O;߽���l5ꕔ��
)tQ#�s�C�E��`V��Z<f�b�ݺ�,�r��%��?����*��TO���L2PD�[�.	�a���ht�&Hde��Ir	��J��=�7���D�RE��{o��X[z��"ȁK�7	�E��@jU/�n04�f�m�� %����F�iI#^�c��FO�F]�C۫*� � ��j��Es�#K��rJjբ��B����}���,>����,>����,>����,>����,>����,>����,>����,>����,>�����?���l% � 