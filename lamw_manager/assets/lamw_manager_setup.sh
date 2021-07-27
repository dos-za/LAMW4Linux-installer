#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="47504618"
MD5="3bb5036f0cd865ec1e40b564887e8949"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23224"
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
	echo Date of packaging: Tue Jul 27 16:21:43 -03 2021
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
�7zXZ  �ִF !   �X����Zv] �}��1Dd]����P�t�D��~5�:Ӧɱ���bK�DD��5�qr�KP��q�б>�غ
�K*��`��fa��z���u��9xO���U>�Ǒ��h#��a�d�U0��M國7ܷ �s����z=`Ħ�"/"_������P{zd�S�!U�Wg!�o��DQ�F�7?��6� ��!. q��v�ā2�\��O��6���48]�]�J=�vmb\�y0;��L���CT�\�{o=�"�yp�������G��4%�"&��<�\ؒ�l7�E�
����(�v@i�VgD�e�@��,MB�[`�r'�hn��q�R^m��pW���%���|1Q�!92������Q�W1��6�M����@r:t�D��,��<�33a��g4ۿ��thh�<f�@�LQ!���A���d�6�D�I�$/���_M�c*��/<� �����3�}�/V���^�,n�k�{�+��?�2�;�M����$>���Y�~��j�qhR�ja����	j:�M��Oa"�]��0�J�`�(�0~�&=��%�'/�9dYq�~"�VH��q
JX�A�J�nȩ���D����}�Y-��\W��[�/[v*�D�	�r�7WA�'q�f�0��m�x���]ϝC�8`8����|J2�=��5�:��7�x�u�|[ ��}H�y5!0	eI_�Q�F#�*"�*�ͪ?f\籅�?qc�EvX)���YW��OPQQ�h�23�!| w��2�t�2u�e4��1ǽ�q`�!C� ��ЅA�2��Q��VE�$w �4��^�TEk��w2yM�j�iDh��T�����q�	\h�*�2.m�j�Dj�s��&	�U���O�c�Je���Y�zx%%O�6<��-�������0������N��\�BV�C}�x�z�R6��� ���5\ث�#FBw~�}���Т/g$�ʟ>:���a��������`=��]�8GS?rl4$w�W|1�3�%)y&"Z\E��,&���'�=�tN�q��"hc+�-�Ja���N��f�e� �hҏx�{�����V�o��"��c�����$Up-Ʈ���+a�p:$?Jg��k7��B��6s����I�Mc�oDƵmr�z��h����X����[����e���M_!��\�|#��od�mÚ�t�Q�l��s��-��� �Bq[�]����� �W'����� ���?��Z
M��!��rs���^�������ƕ�����%��y�=��C��a{�d���{�;�Z���`��K�M� ����kF�uj+���	o��X8�Hq*�6��i��ҕ@{{`��*M�E��`g��b>���a�@-��-X钛1dH]7t:����	Ry��-�p]��zyiQ��μ�����w��n�T�H��M��@��|��֕W�k�\R�%�z78��5$:9%�cL�lE�s�L;0J�ު�m������XB�>��Km���kU�������U��w��:���HF$���-�"�qEC��u[�`1+U���9�2�t¹'���2��E!�p"O-N�H5�[7�p���bz��n�b�(�U�}e����a|��%�4�q�]��PdJ�v3z�nb���=ˇ�[	fV��89|<�G�;�L�VhV#,��&s.�`�q�5�#L�[+��a����BT���W�Ĭ{�m@��#�޿S�у� e9:vއMP��Q��v���~Y0��)�SN��;�H~O XuW��]�ý)�t��\���n���h�0O߮�\��	_�𒏜���%	8��c����`��U��"-���o�K:Zܭ��$j��')�U)��1����8��ξT���3	��&#ɣ�����9���Y�K��'n��v/`�t��ۗ����7F1�1�R����B�jQ �LU`�sP�D�9瑓�[
?+�a���A�����<4����V1�������[�����ny��KnN��=�/�|b�?�u��Y�BF��=�S��.�D�ʥ�bHf��מ`b.L[s��:�-WZ#Q�0O�͵�s��=���=q���B� ��\j�k{�B���E~I���<4����O��o��	�f��K���Ef<�Ի_���lʅ��#KU�B5�g�2pS�o�u%Bd;�4� ���^E)���r7�G�C�Q���6x��u}Ka��GK�:�O�Y��rH�9��C֪\��uݤAZ�tԒ}��S���vUl��_#)E�y�v�iʵ>	�������,CGGF��6N�������C�o/����A���_Ub����~�ƶ����ȇ��w���5�w M�Q��z�g ��ua��[�F�<��S�hg+�$�6�K�/0�6��Kc����[ٰ~�� R��c�{9K�$Vv�'<%i3�9���Ԗj �Ǚ��m�=]�o�����-IOQ�4bi��A��9�g:�$'cm�h  *,����g��+�'�9J �}���T�I��x�[u$��a
��%'��?B�w	��:����Wp��C��s�@�P���[�f��h�1�o�b�a�:{��ax,�/�^�<�z�b��ǂ$�
���1b'ک!m�?�B�8=o��+kd��(� �]��TZ!��zJ�i�q���V}Y��xܐ鰸�wo6q�+),Ӹn��U�Zcx�L���'4xk+p0&��6�w
�ħuø�½ ����d������n�P:h!�@�zD����Bň��=�;~��^kB�AI*�1s!��F�&�|�=N�Ʒ���t?g���~�}�������ш�@��)uz:>�S�a���E��HH�}U�a��P�b�R-�Ґ��	nB,����e�T��'%�Z^̷gSK�b�o!z�ۚ:�rb:��/�Ҹ���m�+�Z��c�F����G��5.�a�i\��b�C���|��6��6�L��'���o����HC�8�?�Mo����֚ʂ�'�l%��ir/����.k��FH�n�ƒ@����vo{���z�]!{7����Z6t��a8<Z�g���̯5ӓ��¶�P�ݱ���r���91��q�6���L���Y��g�4��@7�ƣ�^�����f���D^W���
���a�nel܆�G|��;RJ�:u���?�%������i�Pn�C�=�ݏ�c��J3���!�S�+��<Zz���= ��1��-g��!�}Ա�%��K���2�8�2zI��m��,��˘J?�N$,�o��r_D����Dє�΃��ǩJ���'d̳�a��Nеv?,�Cmd[^���ޭ@�j�<���U������O�v�prCN?'PT�&�d8	x8K�b�������d���w�U\sS�,��y6w�U�n��\(@���i$����Js)���Z�p�g!��<�|%;En�d=�Q�GYj�?��
����E��џ
8���'����e�tϑ�ю^bռ�u_]�qϫs��Z+@���4�rP��y���<�?AU�iq����7c2�g蒲W���YB.R�[Ӓ� l���TIg�t�h�|��9�Fl�ܚ��9i0�e�̣�q���()��iƖ1�x�ݿ!װ<�2��4��LqH���r.����RYL�Ms��w_t ������O*O�8~v���vg\x30q��Es4m���D}�߯�"f�ec�jM��0f���iw&�DP$�������)1��H�fz�;��2������Ѓ��>�O?S� z�ηV3i���4h"�C 3��A.sR�a~nS��B�7K{I�$�����Y_���̪�m������G� "UZ��e� O�%BϺգ�4I���$�x��Yy�	?�c��||��8-d�ɋf�K��ی!Q.��s�Q.����V.����W�/0h�W��m˦ �ݣ��v,�0����5ʉ�N��\Gp�� �#�6L�:� x��7ƨ<��*�=�2 z�30��<�}_�ţ����P;=����� Ծ3��� ~Q�/��A�7��d!yj�~Fq�q�[���Dӏ�vCK3k9t⫔���[`����6���b�7,_h�:��P�Bi�t^�hk���W)��队L ���J�nӿ�{NɎ��_j�AzS5���6�Q�u���|zN[���ڑd'���Z��τ�7�j�Yp:)����f-3o]�`M�����X�D!���O�DI4O�P�я̘� �
h�������R����t�(��L�L��Y�mZ�T�a�d�����#�e���k0�+Umd�BsQ�`�
&Y�zI%l����D����7�!rҦ]B	�};�/ J�Ea}+q��Zȱ�ZW�L.4��87+8��+�=e�+����Z�5�>������iϴ\<(i��D��O��Di��M��Ynz�I�eBgb��C��qZ�٣@~�T\�:���P����l�q�8S������~�Y�8 b����w�1����YH��n>ġ��@�s<�ͻ�"چ?��09�V꥜�p���W �[��o��2!O��>Ա��<�q�A�����t�����葹�k�y?���s�2[e����c�Q��-$��fD��L�#��_J,���9�qdV��7��A�i�����w��K���Cg�["ߕ�K���6�i��㤇���;�T�<d�=�����P��D�o�`7gD�`%eW�>�ȠS&��`������rGI�x�����»pG  �KO�WD<Ta�>F�E�⻥�8c������`TF�޺IN���&,A��Q1Eθ	~�wo���V5P��GV���ӟjjm*�R]���"O���Ff�u��\*�^u�B�`j����_��dɖ\�ȝ.M�Y6 �<X�04�n&�p!Т�x���*R�Y����
��i�d70�Q����!�0��q�S�w����_@d�*����}��y�<k��gAS�FX_	M�ؿ�U�=�%m^NcW�e�qt��F��k�����I��4�s@��Q0���lZ���.���"F �Z�j:d^`n�ZS�UV��̵�̏&R��[�����S���o���9��5��OG��,�,'�`�[^-�j�,1��?v��dׅ�r^A�ļ��x�.u4.�d�r��ړ����� �P�kڕ؞������DVi�!�3ɒ�[�s�\z�� ���}k�}}�����2V�<����㸞=+��'�?+q���'��ub/z�uV���~�$�
C��B[�'3��K��$�W�O��sP�ҾlA-	�\��u�I�qL���Y��|�JEx��P�[W@�w�Ֆ7}}ˌ�@Y;УC�>�U���==<S�,AgR, �y(i<��������&$�j"Dw�T*���� }�)�V���{/y�W�8�7(P:[�7�p�!i#+�ٔ6���&`%�M�"�[}Y\&�0�;���m:�(�q7D��P� ��F&�M����t("O�#���پv�ż?�+�� va�~4ƺa�Z�dڗ��'�� -��E�h��*�cBC�������7��y!T��d�M�2'#=~�����ê���RK��2}h|�8����G$�H$R@
P�`\V_�àN!��JƉ4]e��L� ��6���M(�;���o6'�	��Ē�B��Z�kd���������	���DY��̚t����vǂRڇE
l&���M��x&"wװ�N���}��`�J*c�{�m�
��U�m,��'�6p R0� *��b'���sDL���?*2����I����~SQ}�7�c�����=hMO��*���Np�	��21�娦#��0���W�t�-7/v�Up���%]�)_�e�
���ɬ�P/A9�w��1�w����>������P�-�8K�3�Ѵ�|��L+,Ȋ6��gZ�H���t;0��%kl`K�tX����%^��"���-���Y�܈�n���6[��ːS�Jr�9;l2���?qn�l+�I�f&Os�&�kV�NR�����=�a(^���kE�L �ģ�2�0O�	^��y�]Q�zE��h�����Ƙ�	���Ho�N-�p$��������Mq�g^�c��v(��(*[	�̈�]�\ۈןI�¶sx�䳪������9Ҝ�!�j���:<���i4ۦw>��w_7)�v/{�ų�u'U����>O�4nl�`A@b�ۖ'�(n��kg$�X�ϸ(����_.gF%�0$<5kn� 0�[��0�S%E5�HN#����P�~o�+`�N$�K�q(2�b��fF�ť;`�>Q�;I���@�tʷR(�si�M})g���0ò�3_"��y�@�#��`��{E��Y�� �-�D]И$��]@��	�F+U�sfB�}��j�G�q����SMo�X�T�ݎ��`�5c�AU⚎��G�_�ƿAH�ؒ��t��2���7=%��L�
���5���#�ON���*���1��5τ��֋Q�-���ƶ>��aݮ�vDj�{>0��{��y�0!�-��� ��^�h�+6�~<ث-A9�.�q5��#�c�浑�e�cJh�#��Z9� O�/�~܌M�T��1L����ޤ`F	 �M"�ڀx@� ���������W,|�l*`�un��VX�赜���	q��PZ��;7��5���v����ݠ�ǯ��F`���i�]�Z�>�:�Q��$�q�fC(�`oa�*�	�!��������8�^NPDB�~�0t�b��(Lx/�:���ï	�����N��{���n�����Sra_�1Ӿ��{S��e����v	I�D��|�쟐�i��~�o����{����Yw'b�܉b�ǚ�4&���Ď(k\:=.+���
��/+��wh+���K�cX�3-I&��
v}.|/y,�R��dU'�nx޹�AɼL����_�g�`����Z=���N;���^zL�~Y��0�g�?�4��v��pU1#.�6>g2�y�j�0���s�����Ƣ��Ɂϑ9�yo�J �>�g� ���$�?���o���ЬO�9���jQ<xd���\���HE}Z�N�~I^�,j7��Qy�;��R�j���3%��Tj�Ŕ�A�w��|E�CٴӮ�<x��L�wԑ�2��o\I���2�̓��Y������'��u��َ�	Z�꼑D���S�Z!���5j8?���/���v�C�����M��g��km�z��{$i^UG]S�=W��n�@0V�c�������)�t��x���e��M\��z�E�ٽq̅^	�U�P�$F���ǀJW��^u^p���\��Wi�ȏA�6\�> �%Ǜ���0bY����qBB�2�DWgwO-��|a�\��t�%�W �z�D�6����ݏ��e@x'v�Pi�9��w(Jʨ�F�B^����x�U{b��Q������}�N��3Ab��0F4*wC��D�U����b�5�ʫG0��c�@Z�[�UB�Z�����9ɞA�H^������\����1�ks�����l\�bk�b������c	��P�|������=/UG�%�|�*b[���[�F��R�A�����BD�L���h�G@c<ŶW�gl��m��A��m��@H�$�����q�ӰB\�X�9 ����֢A��.^/��C����`��a܌郧�
�؀ĤS�_�Qӊ�ͣ��װ [~�*�(�>e��Z�����vB��f k�(T wW�U���j��X��zR��v�f��"�s�d`�(�l�/��7�þ�оH�զ�ZJ�G[9F��cB+\����jΡ	�wWIZé��Bq�y��sS�b���k���t���z#yۃq8d�NHy�p|��`�i��8��?ޯ�����Iw��6a��j���^h2�N�V/q<ֳ������%Ja�~��4���|`���_N�="sj9��fH��8ES$���|+QA
�4~�>��՚�;�[3�K�OL���u��N����	+�l�Y��C�+v�7T����6Ɉ,\�94�ǿxA	!6r̽���EmG@fn��{�#2�^��Z���v����_;��]���C|{Zu��Uˤ���s��5�=ȩW�v�I/OK׳�#�s#CJ�0�����k8���b׌k�R�}����u�I	�U)���澠��k�	˰=��5�ٛ���!8b���P�Bz�e�X�z]@��Sg�����O��u����O]�Ev���y���c�I�U(;dp�9*~��MM��� '}���� �5ݺRΪ�^�g��J0�o�EA��
E�?���<�A-:�>�U+��n��@�J�J�nJ{z�u��!�&_��k�loq�F���Il���4v����ĭlxV��H@V���&�p�����i�&��l}M�Xl<N+ ��!K�Ӵӱ}w�E��+Ɲ���0��>��I"U�_�S��`>��6�`���E�T�"� +3d���ȩ��T�7�М�v&ufI:��^7:GK���\濃&g�4�#��M���	��/�3m�3�`�!���s�H����y�Ld�)(C���˜Uft:��^sm|�ܴٔ�$M�@�
}?��ᥱZ��L��<��s�Բ�$-~�@���DA���GJzu~����+N���o�F���n���IH6�(&^��sŚ����#2��h��N�����L��S��u� &��������q��b�(/AC����"����4�����)}_�A��QP�r�������1�헿����aZ�־w��D�Y�l��k� �q����R�_@��\���m���%��1�eE4�e>���g��X(qr��ΧE�t҉�+7���z@I�_���#^��c�$�tB�ܾ��P�	��n9�^ ��f?OC��kR�	!��m*�W��A�����4��3�P���Qn�I��>��������V=����h�1�ɘVc�|����U��ƪ���J��J��t�1᳜�Y����.�gPpM�}N��P�nd	q���M<���4Cr:�T"���b0꼡%OMk�PK��#������N=^P�d6��3���.s'�=��4�3��>�ܦ������e���E@�|�)��5?P|��E�`Q��6��K�!vMxS@� ���U W�ZX%��ώ����ˑ�ǿ���h���bևs?���Ƨ�K�r�u��M�����p� p�mR��z�[}"gl��fV����=~��jċ����(�����<#\���DlE��4E޾r?�D�>v��o�� dj|�$�˃'�a��Mh.x:0�X��"x�mx��x�1��صe{fgX/��묪�u/�])1.�ಒB���G"Ҫ?}RQ��ٔՀ9�HYA���Y�3@��v&A5��W��3��M7ȟ"�}���;�žt�t*�Vv_�Z��?�s��3gǴ/��O�h��m=��H��Y!�"%]$eų��� �&�kb'ډw'Y@*�bo&�ko���T�I��l`��ɖ%̧V:�A-�U ����Q��w����A�P���C��]�_��������9��O�G��R�X��%(�w�e^��`��8�ä���wX�O���+�a�r��j�� �&��]dΆ�iAVr��4�R/�pb��qI�2�)��]\6�ue��㼟{(̓��_p@3�����
�Q�/�����m+��>5�A�%w��*���`���	�s�/�� ߔ�T�0�Z}��i����F��a��}S�^�#APO�K΀��}��A����ٛ�
kD3�{��|}��v�ce��Ž��y�޶���f�tAX�;Y=��:�5�B�6����F�M,�>x PK�^���t��'y^US��7&r�Ras�u`*��c/̂�5�fiv�g��W%�p!�m��$H����P:Ȧ����9��1���!�W��8r9�%���!:�0�u���I����&��	v�8� �;�S�FM�0����&�簅4�0�]�|���[��җ���*�?�G{/��/H`��N(�O(-�*�R�8��z���ML\S
�*++Gi�DvD��w]牗Y���v�H�u&�c����\�ET�!� C����`F�	$��p(�W�].R6�E�T�勻h�L!z�^l��Uc����Η|�]�cm���"���F��S�I�Y0oߎ��a��x�H�9�^����h��5ǭb��F_y���M�PJ��DD:^Xo~�WA�,[�(�"`���.�𼠑�6K�h�(� ���`}���S�݂�Pwt?��O����
=�gC]je目�Z}r�����j��Z@�n����@98�C�}ǤX�¬j�L|�)C�H���E%�ޞ�Wg����{$�(��nҀ�R�������s�l��B��S� 4���H3��Z��O�j�K{.BO���(Aa�T��%1��ن�~�)��9�����ĝ��W{�O6����.�)�p�c=k�E*�t�-��K�gpH��i���_�<h��g�;s��v���J�S���y���2m��XR��Й��c��$��%NN$�0�^ݙ��0t	����R���mJj��a��M$ӫ>;2�^�Lx��O�D/�Z�Q�Nx�˸���#�F�_^�
�M$�'4��l��M�Vv�F~�Gi�upJ��V�W�j	����g���f�D�{�|�L=��)�֩������f���v���D����A{ƙ��H��X��<'z#Q̋pj���G#��+f^>�L�~�u%U�2m��@���5��ᔜ(דּF�*;�(/ �Z�i�Wllg�zf�\t@0�u���&�HzM|���-�6Ko�����'%Bh"x$GUi}�G?��<��yIC��JI��=d�i<�_��8:��a�X����+�} �\���9���3q�����a
�0[�ѹ$����6IP����*L���t��`#7����&ԉ|�����PKy8�
M���?�7s�YY����_�a�/e�;5��ggfte`qk?H����ݙL
���}�7���şjA�{?Eτ:Mt�2�Uٵ��E#kO�5+$URD�\�w�,�rL�;�x#�~'��F�Eu��x�>���L��z�ӡs3@}���؊:���������$��F�Z�
mۇ�}�5L�	�\&$d$�)��m%r|���wTs'c�,B��ZA��9���>���f,U�X�@=�.P�辌����W��m���ƴI��~��u�5ʳ��P!R0��N�Ľ�ξ~qznc9�<�Rdۢ%�JUTh�K�q��2"_���][�8fq�2��r����^ß��M0�	#�
c�i!9,���q���̓��DF�l������K�+�6�'{o��^�l^��4b�@T�,�bK Y����J�k���$Ŧq�&����i!��ݱ���ǉ�Z:���eB�þ�C����'[���1����\��
4*��I�(S��1ޮG���Kr��c'���l4|���0ky�Յ��S�ƥ�#�
������ῇ�||��!	���O�A��'dh@�tI��A`YIM�N:�H}S�v�^/w�O���� Eb���o�]"ěA�;���4-����O	�Ry���A������y��!S���F?��G�\0�x�:h7ϖ��ɐ�v���p�Ft1{W8���'���
\Y�b�0(|���4h_��%h�K�!$&�gѦ�1r�_�2�I����8.��^P�o������z:I������:Ga�A
��d���;b2���]��0$8��.�$�y��cMZ��2h/�O���	���D�/�=~�q�4��t�&�8��hZ��������4������o�c�D�kXf��&;��z5�� ����]�1.Ҧx�&�h�0�a1y^�X��ogx�~%�@�	ɁB�d��8�PF�Ѱ�F�$Y��NNNC�����H�	�c"-(&�>�͹�k; in��mg���bC�P�%����{/v�]IPc�'�2��dM�w �ƭ����T"v�N�����3}�`k((�����ޝ��. �)e�ˈ��|tҥ��*��������wC�?QbURB�7�7E.b�$v�w���sg �v�e�/BF�w�{�b ����>۟�l��lD��8Y��t��Ā�
wP �m��Y���hgf����Z�!��@�"cހ���ޅ�s��T�i9{�˿��`;ж���� 8P5O
�"Gs��F�0*�++9�U���7��>W��sğl�������m=R��[hTN=�VB�(M�7e�j0������%��7=�s�"��7�8j�!�4�B��?��s��c�b,~d��,/?isd]�B�o��G?u�a��^U�T���]ǭ��!�����ð:����%�<\"�$d��e7Y}�σA�T����]J��pؐ��l'R�+���c�"�Qy���J�0���in`�,���ۓy%����V�5�TsUH�j��'t�SڹP�9��y{ݳm
�柣����K�֙��ey�A��G��뽼�bS���=�!� A�&?z�û%�5*��������ٺl�����\�Y'�f��R^%X@徍�,�d��68�]���5�	��{�j�,G˺ �����zp��[�r���ښ���w�^�Z;�o��17o�ۥ�rAE�q�O�H�N7~{��-�0����:8���T�fħ2���"/B"#2��|��TV�c�o��Uj����>`�����N����R�*ω|0��+��6s���Q���b��(��Z�^���ң�X�"�t8c�`a3�˳��t�ਥ�(�� ���5�C%��?D��,����ˮ�g�\[��y:H�&B�q.x >�&���3	��n���u��F���@�'�kl8��=��B����nE!m�ӑ����-����ܫ�{i�4�^��d���6lvŠz�D ��M31&��!f1��Xf�1�CD��b�am��(ծYG�1�џ�[(!���G�=��r�H|��3���&�0|t���­�Wt��i>�{���ݍզk߱�X��L|�X�ctЍU������z�Ngvx<�W�$a��jIuO�w(&Z��Ml��:�IT��;|k�s��#v�Љ��#8�ؐ���`�f����(�D��L�ї� 7�#��$�)�V)ٷJS���Xl����~1+�n;�Cg�տ,���l�x�o�*�Qiπ,�-
W�9s��b�_u�#�&N��D��R;ᓤ/��I~�|7��E��{n���+���Az�q�cUK-�:V��d��o�0Q@�n#�.Q����T��$�
���J[K嫐v�
�i�Z����6�V��O+�j�gf�R%F=c���IB]Asխ��<Ķ�������P�Ƹ�QkT�\[x��1��V�-�yJǝ�u� �T�eӴJ��-MHJTTj����4�I�5zކ%Q��62۞��2cg����g��-	�Ɗ�=��q�p���w��  �.+�j����~� P�eS��؊�?��#�ln��{AF�T_wؒ�K4��J��d��g�\�O]�J�+󹪕��<��jB��*�'�1J��b��d{w�� ����bن�896�ă���߇��)I�r��,A��EA�2����Q��Nd�7t���'*Q�u�[WC@V���ַ�����3QW}��,�]��l�9M?#n�D�`k�/�3s���c2V�1��sD�ˍx�\&�è��p��J6��(������jn��9�����/ `��d<#���>d�����b^�������B��L��}�Q�$�˘W��.�������B����g�N�x���|M3&2T\��ϕ�j�G��J���~���!ˑ���������y̕���#���ޓ�w����_�J�`"7�� �g�R��!�aǾc/#J���1���U��4
i���\��-E�,lߓ1���5)�vhia3{����6���@,�F�D�}��%�T�=�l{�Q��uY:��=��eN��?cD;���k��;��JD�.!�^_�)�M�I��C�nxϺ���-��
gn������O\�<�E&�ʳ��{�ܧԑs�J�`bZ�j>�UY������/���Q�r���'"�[�\�s0(\�+Rm�H'@ Xi�UތF6$��f�<�g1����z'��fk4\<�p���K�i��,;E�/L�!a�f�<8%�Y�&�S|�)ݜlT�R���(3�a�nEj#�eB����Z��s�����J�1ٮ�q&���jIe[�.�o�S��(E:�g{��%���0��g�hhAO3Q��έ|�G-��H~���G�lMF?�wL �����m�b�Ô��N���&�9#jZ /��?�mo���@sɯD�n�

3���� (�n��(x"{�[��l�w��$e�:J2����]�( +Y?^�]��F@7�(e]*Ӡ�^;�B�:�ɪ*��妭�sd��� �fi�y7��nA����H�U�o�)^/�iJ�k�>�u�g奜��l`m���z�(���m��S0գZ*���$�L��=We���b��-���+$���97ݓ�2+�gy�)�!ZƊ��r��={I��?�a+p��	�sXV�;q�o����̇�J`r�yE�4�q�ЊA�����_>�o ���۔�
� �}RT�&�ʶvI�k�ӵ���_���p,6,L��c�[4�6�B@�x�z�����Ɣ��?�[�����`�"��r�t�r�s����c�g'^�W�m!��+D�|~��a���� ��ov����jQ�Xn�ʊ-i��3�X�R7�g��~�YP�=v���>��>�5p���t�������@F/�����Xs����v(O�'�0ݜ�Wk�1�[�hJ$�h�FE�6Iܽ+��)�Q�ᢌ�v"�r����6ާk,I\}��N�(�ܨ;��:���4q	. x-�<W�,D[�n��i�5�ע݈�#GK���\�7�;�8�����b<��iJmW��_�˟�D���ْ&�����D+�fP?��]�3e��{e5�9�]&�Z�N"t�+G�hlSa�����m�@���]��{�b?�%<Z��z�հE�i�#i�r���	s�4�)�0�I�m+r]W��&"�9��B���eC�E�v�����v�?Ū��#��5y=��1).�q oF��W;J��^��U��)p\� �S�,�D��w�?"����=sQ��sh��%`d��C�5d0�a>ֱ=����� j�u�[!?�-��L.T�����n�����x��#���C�_~Ma
��E����	*�a^�slwb2o����ܙ?���fXa
��`m���i�X�D,���0�Q��I>�f~�F,��w�r�aX��}����c�s �4�tf����4�:�~��eSW�W�������+Ŗ����1�仧��R�V�E�;kI�-�\
Ğ��u��B�Q]�s�cDٍ��t�B�v��OQ��=�r}�{�m˰I��@����$���-�wj<ɺ�3�?b�R{;��/�묹K1��XL�_P�h˞D�f�8Z�s!�y~0�L�u�x�o�������r曆��KL�Fsx5X�Z�����ۢ�'��>ז�겫B�D�������z�͢X�Ϊ�i����k�7(���}�"��������L�+0�L�L�uV�l���,�`E�	��[��38�(YB�|pd��kV�tj��r����1d���E�:
�!�I�#.0:Sa��h��yT�9���3}3	@�R�=�NtS��[��y�_p�����o�K�����j��^<O�K`]�P=-t�r�s��n��@�����D�w���C?3�-���%ө͏?	�b��aL�x"u�;n��"J���W�R��%e�׶,�(��Z�u����~T�;���Tg��fS1��e��^)��h��5��	⁁"dx�O��Y�u<���U,Զ���Tfw�m��ǆ
����<��2���]�v����n:���ڄ)�S�u�f2-敨~��H8-[]�/E���c�vt��z��(��/�t`y��Gt�&�-#�����)i��o|K���S���w9Z;��Xr�aj��Ʃ���	 Aܺ��c��1Z�,�˿ ����SWֲ�:���"@�x���t�C�1�7��;��H�5��6^�0m����H���9�6_UL��_�[mrR����ĥF;t	���4���V�����"�<�<�H��	
��>3ÔAQ�9�局;������,�u~�᩺�4�͡�T�R}s��a���Ї5\��X1�*`08p峉�U�*�vkF�&A>g<O~;=�UT�p�p��dKHT��L&Sꡖ����̫>}f�
�\�� ���e+ieט����Ul?u����&�v�t�����w;�o�~�^�Y%VU t�&BNXoF��{�B�u����N�le�-�}Ix��H�������J�gzMx�Nʆ�`G�B�/����9�~ !��v��>�\Obj+1"��#&�����U  ;)�-F��"4p8�o��h�քf#��xα����)\Y���q�������G�N�&9���������]���xw�	4���,�Ƙ��*!��@�����D����\�u��͍4_��T��4k�pq�6��i�*��9D��,��.��5���?΋-{f
�8i����Jz��V���a$~v'�r< �D���gw��f���I:�H������csl�w��gX�D� ���SP}Zx���k(L���;�̺fP(�����Q�z�;�9� M���!�Hk7�2��.R�n��$���X*o7@���R��*��L��@٦Σ�V��/-��'?	�0��ĳ�uE��X�7��Ġ�R�b9����tB�}�N!v��3n�M~�ې���A�E�kEd� �|���x]m�X	K��f��y!��`ɷ��j4c���ָZG���N�P����d�%8�hB\f�͕{|��� 2� A��5^�-#����l�8��W��a�E�ۮ/��A�y���X�~��`�ӝǣG(��l�JiP{�L}4Y;��O�+JlL�˷ї�U�_�B�B�&��=���Ҁ@�r^å���H���ޡ�i�^3M?�"��l��ř`5��ԋ;��9U����r�-u-�e�-X���%Ltj�r�S-�2m�*�ԝmV�����p?�*'o���]�GM��QR:���bP��`��I�� 6h'�ʠk�Hcc�j��=T��(}�+d�=�b�L�	"�	�����6�A��ņ�������@�T��>��$�`��ћ��lP��k�W])�����bH��+�#��j�S�{�F��l�E�$~�._F��F�Ȼ�����.�_� ��l��{z�}��-z�cS�}��ʳ�=u M2m�~�8�$G�o��D�~z�4����uz��t #�*y���M���y;�;��{���i��o;�K�A��;@1TK���U6�'k����GD��5vT�?|���:���:\�a���Xͽ����	�	*|��@� �X��+qP5��w�M4#���#
X
�nJ%�F�n_;f�؅��[xժ����#o�Y���ⶡ����?a��;�d����/4�a���z�����f��j��6��G�w�uz��7��dW-�5�؍kMVz��a�����˲ЅZRtqD��8���db��zD�*��\JZ��]/h�}��m�PY"��~~ ����x;<o�O9I����`�/��U�G#��?ɱa�.lm6�,�d��UE�������<�a�pw���{�+�$�^�l����\���],�_,m8Ȗ6����.ЎıY�G���]���ߟ @��D0>���ձ�N\/��������P�g�*~^�i�,�z�FsGn�Y�4�JȪo�}`��}@�����g�<�7�fJ���l���R�f�@�?aզ1h��bf/ᢛ-���S��b�Ɵ�+��|�	�K��S�+��S��jl�^G���!��Zߝrp�N�C겉ת-:oՍ�G(���6���vy���\������9�6����8G�z//B�Ӈ�K�km�o��M��u�)��Oi
����`&d�*޹�@���R`�9A�5�;�Xs-���Xz+7�I��}U�L-�<m�MJ �b���4���K�L��.�� s�9MQo�c !`�H�q,� �j��M�9���տ8�ֽ��h(���3�-�<l�d���&ڍ�R:H#;0�y���V�Ge�h�l3��E�n�b���#�H0#�%��3)"�����?�{��O��_�5a{Df��l�i.U�%����*��PS~���"'�oz{�Vn� �+��,U�v�ZG�"X��,���C���*�󢈑��@0c�-6{a���VU�����oX�>^b�24*!�/�>:�#`�C�����ڃ�M�\�����ڲ,@��Vg�3�:W�!(w/�S���0�w`�xkOZ�=qC��X�N�s"wQ��>�Ʝ�\o����`Kj#�QP}}\h�mH��M��3!#�-d�9LƄ�����{��I�4y�����/ќ�n��m �Z�IWз |�	�f~����N����)�*���^�p���������V9t�+h��v<�CG��\���O=���Q��vG��'��AT-�:���LC&�kQRm��D��@�=��|�h�}q���7I���;u��7���֚��#}�323h��9��h��4hY�+³d穵'�X�K"L��_B ��L���M���RW�u�]�޲1#��x�1?������M�SQ�U�a�<I��4�@fCB�`[�m:��}��7��+��}�.�I�s���2}n�w�v<��Y/�R{�J��w��w��+j\`��ۈ����<	�E���fr�^�l�?hr�f���ݥ�S夕��WX�"c���'.�*.d���Hj�Sp0�DZG���.�O��*e����D{:���9O4�f��d\��
.4��S��^.�K)U��������Pٶ)+�f*D�\e҅g�&����|�ky��_q�-gc꠴��S���1�3P��p���>A�t���
����f7�գ���Xyb�
o����������L�L����E�^�Edtaz�r�����d�$N˂��VҐ����+@����|���~�}�Q�̘�#���æ$�u���+�Kb�yU�$[�SW�j'����HW�{���]	C߂�=�:/"��\�GjBe�t�e���	�:Q�R{�{���䙖����g����P���Vh�)�K3%Q�@R�Lt�|
{5�R�s�>��:p!���K�p�|8���x��'3��W���h�
�͠�
�sqJuZ{K0�%��ڌw"v� c��2�,ˇC;�J��6��k��a2[�����b�ã-̭��cd�k�[��RVQ7f�=��x��9�ʮ�Ą���܉0+�
I�N/VY���|�T*(B*Z?�Rao��2�wN͙�������ɷ������l�5:��h��Z�t�m�ʐ�5��eg|���vr�9J�s,2�8�\��p�Q?Q������(GK=�X+,Ie���j��<������h�q��?
�6٧���^j�EkF���ZX�7p^��$L���#.Θ|����yĲ�����������_�o%��~{4�܅	P�67�oHJ����Rݣ�=>�K����po��Cʒn����7�E�47?g�%󪆿5�$�h�[N"�����^�ūҎA� �!|�k�y��[o��	��-1�����ۓz�m�_U�ǅ���t��6b^RxIգ���kҦ�96�O�&���F��Y�6�X:�92n����bw�����b>��"�yC��p�a��,�(��7�K��V�yA��Įf���Ɖ9X�	��
zK��Ǝ��������-82�$��c�p�Q��"ğ@=� �m��3>�C�5�x����~��l��=���P���T�W��4w�=1���	r��][���La��;��|牷�EZ��Œ|{� [Ju��M�%��� pD�^U�Ds��!�w�U��rR�Cך����aJ�U^��uS7�$��Y�sf�����{��C�m�Y��I��ne�/Jh�h/=M �D&���:E)�<P�c�g	8ڕ��9��9eCSf��a9M�e�ë�����y�Wd}�'c�eN�M.�ww[�e���C&)��j�XR�Mm�lV��!�G��z����U��d�i�V�j5=����@��̶��^9�����ڟ_�̓	s;_�6�Io~��R .���Ԟ{5F�/��A�/�ܺU?�o�����aY�{���>6�Ua���J��ɥ�i���ڟZ�c��(�|�m�X�Ԫɨ��`ە~X�{Q�&vW%���Mu���|�Ę���U����yI�eP
В�U��2��g7Pg�ӆ/zҙ��]�6zX��6��7˓�v�;a��;��Ș�g�|����P��sc�*@�,�E���j�B��`*]�\;��t�}��8���t:s�c�
�����ے1nfZb��i	�� ��
u`-l�F0�;�J���������=c�ZHf�%�OۉTW�9�7BU"j���в�	x0W�X�ۄ/w��wj�T�)�?1E�f�(�����7�o�Nʽ����C�s��}�c��-��"0	ɫ�lSf�E/2�*pB�*��@|v�ó�UXZ����m*���t�b[��j��9��īF��Qcݐ� ;��o}^.շ��C�e3�W7�(,���\��n������Rdo"��]ga-@9|D�x�Zp2#ǧ9a�u8,1�U`UJk��q���j����p�k�����.x�c�%g�pkZtE�B$J�VW��q�޵�+u�JU�-�̓L+���f�A0w��|����o�������1@yzn^�OLZr\F����(��05Yy7?�+�����T�����sίܲ��Jx��cb��MM7�-)��SU�#x6�D��M��*�(�.�S���0��w���e~-�nw�l ���'�֞v� Ϩq��_V��Y���bk�� ��0�ToX��=�ƭKNo�s�.sr�mv>JK�vq�"�}�nG,72�k��ͦ!�����Vݚ\�{ɂ�Y��:x��5�׊k���C�J�P]oZ�
0*vJ�"��<��	0qe�ǊF|hV'2Tf�Nf%�TU�&_*4s����G{ ϭ�Њ��2�Zwi�lQK~Fg_��M��٢�c�p Hozd���:2�YC{�̻@"�.�lŔb&��.G���#��zDd��w����>�H�H�����8��d��wLv����N_�>`h�u�������B;_P!=��$a���-�� �U��0-�}:�nX�ZKp4���K��I��q+�PP�����$Sg����(è��m3�uNx[� �[BCN]<���G������ꢬ d�
M0�*�ߑν�m�M�i?���C��ى�9T�˳Z���Oǘ0��\Y��ra�s��,ry�K�/ �ǸK
W�c�T^r���Lp��OzD��]�V���Xe5��S3%�]�k�`�j}7�|]ԧ�Tw|,(�4�o%�>{ǰY����PS��8,J���<�+h�',1�W������5������HV���8�b4d��!�����E������6����M3�o��]ѽVr+ce.��(�����!b1���X&�~�
f���!�Xb����i�{��P�C��F�"D@�A2�t<L��Юt�����T���TLp��$��xd���w��bg)t��y0/�S�pLRɘX卋������jCt�g��.�hP��S�q���[�D�ȋ��{CQG.���2���'���A�Y�&�/P�;&�}o.��<$`}Y#|��zE͕{5Q~9�jӼ@b"�����9�\����l9ő��dW1Uk�� ��u�E&+��@��P��D&o*��٤��Jϭq=�ƌD2U���꺏Q��N{)�ܟ,v��.?�ߪr&b܋��0b�d�9b���q��}���u�F�'S��p�M�_�-s��E���gϥ\3�H�";���������w ��b���W�I�Y���nu��(�.�����e�Q�>��%1���{���j�����h(^�ȖQ�2��(��2E���(� �� IF���\�e��*O�>������ͤZ��_|���O����;����)V�}�Z��WF��d��'Qg-ΔP`�,���% �#1c��U&*�~��P��/��\I����G'u����d"�P^��#�Ls2�8���FF��G.�Ӽ���L�E�X��p]ڞ-_�[UB ��$q�dx���P��e3%��Q�2=B�K����V|D�5�B`�p���'E�dO��I�r=�{>=NC�]���$�<œ�h�α���6�K�������3{�3��<>�\�C�x��x��Zz�6�(��fu[�Vf��Kxa+p��c��N1���n�������2��	<!�ku�+m%iCD\���4�h5aN)Wu[� 5u-n�2��=���K��Zl����@p�L%y�I7��$��u�U�?Ͷ&�O����m�@X�d������r^0;F��,�s\f�a�����ԩk�S�8���#��2��ٝ�ad��c,��#O׽߲: ��W���6h38 y�K�9�Q���^�R�K;����?��S�'d��:%rh>��!;d    ԥ��C�aN �������G��g�    YZ