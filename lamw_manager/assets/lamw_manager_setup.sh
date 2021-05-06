#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="616436439"
MD5="2066b3759315627feb25c5e644a79fee"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21192"
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
	echo Date of packaging: Thu May  6 20:32:13 -03 2021
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
�7zXZ  �ִF !   �X���R�] �}��1Dd]����P�t�D�mJ%�3������=��w0�l�/a����<%.�_^@�����n��Zen�6�DO�^��'��Ad�+hI��kq~��	-�n�h�Y)���� g�^:�Pv��<��so�h�W�R)@q��OtI ϧ!��7�=̱g&�n�t��m�7�(Zj}Ȏ�/_��]��Lf=�d���J��߸FH����VD��/H����(D��OaR��Z�K�s��~5.?w1��8ml�q�/� R�O�/�TVv���U��B�ֺ�Dܡ��s[�*o�v�c�/�t�ށ���=� �ͻk�cO��
�*�t�2׷��/�ä�I=��k�_9�nS��].^�#����R��4����X�y�t���B���&���n��\m�^2�$��ߎC�*�?/J��K��ë~�7���N��˭yh&�?�:7 T��|��U����G
fDD\_O$m9ʔ ��,�!o� ����j!Ab4�G�f�q�Q�3㩒����S��r����5�J�G��'䳏�s7?��Ʉ��(��F��E�L祢NŘ8?�o��7��������aWH�G�8$���b�S#�$���R����y���HdH�+��=��,m�o���c��x2��ܩ
�Ƨf�=�iUt!Z�.w��9�\�~:��RU�A���~�_&�踴߲��	�rGY8lW�#N$h��*ѡ�p��|ثȵ��]�wgU�MW���a��P�2>�����%� r�<0�g���Rs�I$!}FJՕ��T��f�(jH��	�d��=&�*VybL����4ߤ�%0�6�����&��3��O�:�?+:<����ԉ���R>�gР,#�[g���r�)|e<�T��.`�[����[�@�cL�q]~�S����c�n�D[(��|����9x�S�R��b��qRJ�U@[�z�=�g�'��"�Vxcp��ajp9��\/bR���x.��z�	ض��+��h).xU�����h&P;
l��q� �!8����)t���>X�����^q>�Y=�8��Pϕj��׍���Ɔ{���6���.B�|�Z������8H���E���z�����J��0�ð���s�o��bAh���f��ۏ[�Y���Ut��l��}H� ��_�Z�G`�*m���>(�m��pL1ܞ�����*�O௓��d��E�dgR}�-ϒ��5�-�3���C���ѐ�;�Qևli=�K��`��?E���H>�\�S*^�V���������"�L��P�f�g��X��1>绶	{n��󞽀�<�5K,�E0ܸ\6����oW���G�Vµ�X�f��-���D��5p�s�i�נ4�k��ѮJ��C�t���j�GJ��lv����;+�>���.��Ƶ�:CU\��;q��L�d,�k���	�Z��[/b�3��WA��5o� ��zXu��`�V R�g�hp�^��Ϫ����"'�A�}z�ʊ��_3g�`��02&���?{S�IWݻp�!��z�k#Xm�|\�Vy�
�4���e~ZV�PwA���N�F�-�#���Y�1���������$���"U%E��ţ����V�/!�w3��4�]\\�Lv�P�f��-%O&�5D����u�� lX�^a|l�-=�庛��߷k�J�]Yui��P�L�(�d�[4�ǳF� I�<n�ʩ���\8���G��Z��c������_q�q�F�5���`!̾��-�l��&�à�Vɟ[�ρ���>��]�oPy��g%��t�[l;����c���a�-�)�Bl藚�l��iK~9y)R5TA�5�f]6O���.c�(�""3��nMt�-�6�\��Y�|ZC4�&�.�5j�Y��L`i�"5���/��2�÷d~#@.���"$*�'���X;�+�E���َ�0��3��c��W�P�,�&QB�JS����L� X�Ɨ��뚗8;�hQ&m�Rx�5G�N�M�6�ĺ���6���e�<�ܑ>�y��&���r��v�)ϔHQ- �`���ԓ��aB | &q�u�a~��ʁ㛫]S`�{��W�>�����:m��-�UV$,��	 ��c��?	�����7	0_��m����l^�(�P �p$Mn\f�{c吟VH4����}V@$W���D�<yƗ,�d$�:���G�:��y~�S{�M�X���Ip~��4���[Z�p��gR,-����T��f�*
���:����y�t��� �v)1�Y}Ӫ��\�����R׬�X���Zvb��+��l�?38�q!�KC����#���G���$���)�ƪ��X��]1	 S���W��.}
4����;���ǌ�y��k|��� �̩�����(P,_¿�Pv)���z.�53�UT�м�[8aӯ �8ϔ7���?�v��i�u�>�c>����}��*��+5��)iK9W�ڮh���B��6�u��HTa�F&��7�8� ^<sg|�/���d�QQ!�����&]�ჽei��4��ƨo�ZxR�5��!%���|xhHcs:��7nGRl&���"(�Ӆ�����o.����2�R0����)���{t�������B���C_,�y=F<�B#��'�:�9��j��i�Yɠ�5C���9l�T�5��}�������5*�|Ƽ�ʐC\ ����d^V$܍�hDs�'3=�\���6j5�P9��g����{��O2X�3��T~�F�Ɲ��b��ùlT�uj��w����v�\J�ǲ�����'3��K��?���S9	lgf�㢰�b�#��:!��Y�99X ZNqބN^�̯����m8g�3Kʘ�a�|� ��G����TOd�0�Γ����{�:S����(������8�ˉ�'�%���rTy7�:J��q&��qc���?:چM�*���=d�҇ͪ����nl����`�j��84����c*c��l3��ܺ�A�Zy���8����u��RBa���Ԇ)%����@�m7�$��7�3���m��d�8���-�y炄7�Y���f�y��/��9�VkQ��G/�(��§���a��E~�I�2W�
Đ�eN�P����_|��m_�m�s�ܻ��~�����Zi�aGI�H|f܍�^��s9�ΝW��1���M!^I�}��V��Rb۳���1�^V�������GrzW�5��S[�䞂)�QM���a�k��rfGW�c��^M7��Oe4�
4�֑��)tƅ�x8_�__�ޝV�I#A~�:����p�.�{�;�dL��6���}5��i �"F���PXm�o�vT;���}m�pL���y�H�f��塩��C�+g�#F�� �/�!���f;d�(k�G-|K|���y�b��������u�Z*Ȱ:F��Ϥ����N�����"È�1:كC�cj`�W⫳�NzČ E��>N�����B8�=c���R�ߦӬ��B�ȁJ�w.C�F:ēNs,A͎�p8ȼ��]+̓ |��Rz����;d��3-z0��8�X�O��l��L�a��L�籘m���U㿻��R,xry޴=���O9:&�Uh���P�!�e��c���L��b�L� W|"Q��	Iw�
�D^�W#�����NX��}ڔa���O��3gة�N��gG�K�
k�d���T��j�(�3!W��/�1I�)?�3'�[9$�f벛'-�"G�HdP��n�*ѡ1%A�������LSjn�ծ�U����5�]��h�t�3��� Id�Iw�sv�qc�3��v���'xS����;������X��ɢ�ѥ���������lܜnzФ�8�k�x��9�q�G�k������4r؝��7��Z�z�@Fa&"&E̡�ǲ�gTҚB�& ��$��:�w;�0&oC6�AT:G��CX�t;hq�y&Q}�o��v�a��J���m��%�.V��"��J[��Κ��fi��9��.r�Ӧ��=�et���Bv��DaE������ �v6����ʢX�;ر�=c�Pf�����������Q-���s���?��l3�h������O�E��f�=H���[�XOue�@<o;5�dcY�?6ˑ�zn��ݓ����2g�b�wO�S�S���jL�~F��|�2Q̓>������<b�s��������"���2Q���E�`��f�@-iD��������.MʬN�W��L���.ȯ�`5G!�*�宁��e�M��KK6t:iY�t�0�h'����^_�L�C��(����n��,w�I7*�!�W���sX%�na�#I嗻��x���6�=�I�+�_��Hw���]��n&Z�]�1�b�KR�ʓ�b<�����ޏ��M|�+ ^k�r���+�Q@C]�q�tp0b��]����������&S��A���a3�vs �dϯs&�XHK��oMmjQ�C���]�̉�4^㼞9�8hIaq՟k��q|��i���r4| H"����9!
`ʣ���Fh����M���+�՜�p�-M8
���I����*n@����r�_[��$/�	�r�#�u���f�k��O��+�s�:hhV����`�n,�
�Gsqi��^�,��}���]R�j�F��Z�H���O��#,��� z!Ȏ�z\�0�0� �s9bJ���"}Yt@��B�&��:�V�q}yA(W
��:n(����]���`ּm����|֧n�'�8ǒ-�˸FJ�괚+�hzl-_j�M�7���(O=\xm-ꐯ��� ���y�8�I=�b���Do2�qd�B�Sf��Pr[����ʂ`'�Y.%��ʼ@q��ՒѐW���ɂ���q���ř���YX��K�X�qBj0�z���Z3�B���2dqq��!����z[�.�d�^���&-Z0a+�h},�sZ^@r�af�J�{���i�`����u��p����7u������y~�L����WU#e.�˯��<�I-X�Y{����&�I���S���*���k����0���Õޝ��s�8�����\K|��
>�f�X�p[닳U���Y�.66�r~�pɟ�n�ग'Y�j����f�����T��Hβ�\#��H͇��h\z<�X+VM�S�Zw �V-����,���d�-<<;�ۙ3}4�Ǝ�cW�da�mt�JF�b$�#��Z�<!B���0���pA"?t�!�!O������~L">�֘-��A���m
}�97B�`���!�:gI<��Q@E*\0�8��:
��F�m�
5&r_n򑵀�)M�B�r�5 �.T̌�!�b����엻�9�T��c��zm[E������z�{��wa�_�8�[��U�.N8r���G��O�纁���!XR�3>RyA��W���C�)���%��b��W{�̥��B��e�攵f��t��>>��:�:!T�U�%�U��ܩ��I?#"[���!7sErϮ�&�5�m)H@�͝���3��g��.�a'�@ ��MϾ�y������ ���ms�����$�}�D̌�릐v�Y=��zX>k�#/�5�&AI�ߵ����ܾ�5a�1:?�!&���΢�cu|�k�U=��B�f:(��i��j�C��8�
RC4/�K+'B
��;�/��ۏ$�7ڄ�|��>�n�����N�X��@H!$(ُ���zQ��[�	���g�����ҕZ��h�/r���� �R��8o�K�Y��SƏ.9�:�;�jL	���}"�b�Ċ֌ TL���8o�?�S����o�6Ç���oR�`=�.���g1@e`�{�������R�?�6�)ZR,��\�uϧ��U��q�Y�Թj#fṖ8l_}v���f��̑��f���`􀲽���R��g���0�1��,w�V:�%���Ph�P7tU,+���ȗ�#ҋ�E?F7놻�q�/���oE�Y���!��_�rq��m=cP��-yx�{����Z�S���i%�A�ݘ��@H�&��R@��kX�-���Y$�㮝/�2u���b�B ���; C��Gt�m�]�ouT�S������H,Vc���sBԄ}��S�E~6ǀ�D��K�'*�PRh-bE�@�m�S�k}+f�c:?��/A.R�9$�2:&�m��l���FA���f�H�	��T��36*tKl���@�	r�a��&�	[P?|��@Z@��U����_�[c��K[ו��W)[la9�_��3D��
`�r+�of�M��"J|����Y8��{f�d"��]��������	� �ig�v�a�w�l����PP�gv�
�I�]fx���B�d��5%�OʧrDG)�^7���j=?}뵬!;�g�:�y:��3l.�c�`{@*1e�E�)�#���F�ǹ�G��(�z��k�1���Wyx;A��e�J�5;��? �͡B扤����B[oI5�H
�3���
=0���������M�5�Ff��
pu�9s��&8�{��ӭ�`L��1�}~���v�.'1�W7?$ U����a�!�z\fZ�C�2r�ݖ����*��0p&���
m��fS�P�w赨F��ZJ��`��pT��b�8)�� �q�e�Ӑ�if���bNC{��������l��%�������>V�R��D$�o<6P����	��e�k0�mi?c�����9��z�>���c]�}ʡ�#Ϣ¢H�'� ���|)gb%���3��n�V�S?����K�:Q��&�F��z���t`Ky;��Yix[�fq��*}eܮ�o�+����u��uRC�U�.�(�y~�-ȷ���Xo滨m�޴Q:n���\S�Y��t�OPW�i�"h�#�gnwHܼ1� ��uc
�F��!νA�*�L��û\2���x��7t�wjG�q�j�zKl��[�t��(��<_����������b�c�����|�4dE3�q>`�>� D����?���y���y���3�yp*0�lZ��$��y怞.���'g'�y�,��I{����ѭ�\ f�1�r�Z��ZO�`+��!��=I��-FQ;�������:ڿ�6�a�;���	
�!ߣx�z�Qi�`��]�pv�ge܍H��x��hC���*�	[��A�H�S�\�D�#�M��.��:����`�MDm���s��y��\�V�vsn8�bY.yI$_ߟ����� se�v7�D���9���p�^1yJ(lK�^q;�l�@�)��rL%%�"!c�n��"R�${��3�����P߯�������@�'hQ����,뺁T�!����q��54A!�Ie�3���y���8����,�j�b\ �XŰ,�S�]B��ӫ�Y���~�������e͇V�z���ڦw����־b�dm��BM5�k�-m����)z�����@
G<���#� �8k�Y�����1�.(rݜq���աHݖ�X�J+0�n:�����m�Hd��)�z�1��"kw4]Oy�C���}B$�<��<]�s��H,;%鵬��й�I\3%|�Z��EG��G��N����T�4��װ	���f'M�\\��p,K�0�^����u��p���Y~�(�[�8$�N;K
:<=�;jhY	i}���:����ܘd�H��S1�*���8�-�ˡƂ���\��v�If��g���:Ѵ���M���<��?x^��������lԋ�����N��a����}��Ƚ�����Kl��Ep��5{�N\�qs�B53'�0����gy�GϤ�W�+�h��S���Q�:�Xd�n����e��poF[N�8���O~[�� |��yX-����!�X�9�{����2<��X�`<4�.�)g-���%(*��m,��#�ӎ�'���?�h~��lqgj�J*~�j�I��R݈L���%�=��ߝq~u��LP������K�I�!ۮP���1h�S�9�/���鐞�-�*����O���E�Ffv.�ִ��I�z�7�d��N�pA�6�?6�!��(�P8o�>��<Pi�����#Cz�����a����,c�T{KYtu����*6�fn4'�o8�Xc�ge2Κ��S@��r��x+��Υ�AB���b��$��պ�?�^$$���è���]o�&u��s֮w���E�ZiMFv���,&�D��s��p��-�q��]�&-����͑�`�6�=�����\�� [3QӨ�4!i���h��n�@Q�i�-4ӤT]ZV��wgБ�B���5#K`��M6��D%�;��ո-^��9���s�L3�u�0�qX|���P?,-3x�n��D�w*�A^<�����ޚ`���W��c��ml�l����8G:á No���G�;(���Ց7/�o��
�X��	3
I�!o���kue}�kq��������Ɂݟ�eUx�)�?O:�RG�
��4?��,c��ԙ�w�� �����#��䏽�s�$��;St�$B�g�O.���M�����,�D�hM�V3+R�7z�^�����TBR��l/͚�>��(�)��m��rV�P�!7(��򱃕�ڎ��{#u����Icw��3|���ۏg�����8��hc���+ ���Z�( ����'"��vɪ�#�by#�.��$�_��JO&Oy��R�:/��5�.��/!'��Sq�W�[��i���}�����ژ����&3	�!:{5
R��[�FѰ��S
ʲ�K���y���-b��l�����O�:ʾ |+�W4�͊0Uim<�y%�<���7��u��N{�xku���C_����Š��GB��u ��"y�8�����-_gz���7���X!�W,ƚl�Kn�$	��*F^�:��N�G�PQ�`�Ez�^w��[~	s��/�u�t
�,��[�B�Dd���]�!8��9%�os�~�b�n"i���pLI�7,��@�ƨT��i�-T�)���P忳�,ŎŤ0O�vƐ�l���<T�4CC�<���1��.�0m*�yv���B�e�iu[O(Y�,�	z��O�/�ؒ�x�ǔ�mT��h�c��"������ߑ,����zY�:�ZUT�6��Q�3���rE_�(��):�[U�G�$ �i��5��^z��h|/g,��wK�3QXo��8�/�����+MGտ�����l��dT�0�Yԗ�7n��F�7��%ц~&�X�t��������Kwڡtא��3���C�U�`x�똚+#��Q���l�R)jI�z>�J���R�V��Y�$-�hs�:.x�����Ѯ;`Ǌ9~'���Sxο.�T�x�7t��/��b�q3�l�^��=g2y�t�%S^�b��[��A�����E"E`Z7��<�Y�a��i�p��y"����DAt3K>c�S���X٦'�..���������j�D2\@����˴�y2q@0En]�CP"�[)ë�����rw[��>����!>1���k>I�R����*�
�qӯa2^�O����) �8�F���
V�Bv��p�6٦Q�^�C]�� �ռ/�5�����βAD��]�̕�pM���	f�&S����(X����L��B���5��{��)	�M�m[ ���(Z2iBdauЯO ������t�ذȟ�*�7�-e�q��FRR�K�ycn�3 4���~�c~s�����Q�udY=ڥx/����f�"�K�X����r���B
A�?�̛�����M��b�=�Iq��D�7�ዟ0�vC�&���)��^􀐚��.�	���a�������_&�UfmR0|,�3��DLx�b�9>�lG�O�|��{�����}��.ʊ8Bn��^�x��%����d�s�7�~�K�}��q3m���1����!}#A���p�LL4<�uT0�).K�*���B���f�3��Pq�歾��O�U#g�3��J�Q~��ĸ�����mjG�UX�B�+��E�r(#lQ�u�[p8��L�&?�n�lF9�:3s�E��y|�J
5�ַ�q�B<=��X�Np�Ǆ�X�B����y�apĿ�����M���E��N�!,��,!�r)Ia�p�H_��C}��g�M�����{4�C2�ҳ��os�9-Zp�����Z_��ܡ��.�jV���4�Uz�#�ސ�+�~z~��W�!�׀���'S���W�<�H��հ	��3P�x0��kC|4�N���^�UZf+v{/�/�(�%�sA�¶����Y�Y��A��u{�wO���!�c�esFY4�����@�Ҿ�F��<I^���uSIᕷ��߀��~ج�m��7���q�R9�GH�
�֦���dΩ�31�Kҍu�I���թ��2�Й+Վހ*��>����/���Z�J�8�R���F�M���	1�N`į*ޚi�D!��&o�<֗���W�o���5�.��'�d'�HJ��J�l7��q�4�CB�G��Ƃ0�-�:`64�T��95Z�dW3w��<�2��ds���k�S*X"��^�͐́�-��а�7��0K\W��{��S3/�]g�(�����a?b����X�Q�N��Z�D��O`*�E��<���~�2ߏ�������ˤ���M}P��Pk!�o������1�y�m#��qݦ���b9���..W'���XIL�^`��/]�7�@ZH M�C-��i���a����F�e%X{��C\tWCz��E����]쒒E-��(P�&�d2�Fa�a�Ne�7�ާ������h�<�"CbBq/aR�*����RF���EJ��Ǌ2D>���D�ϒ�0\��Ϫ���Du��>��ǐ�Д`���qP>�V:����.��Y�'��>˙ǲA��Q! ���ިg�*4��;�a�F�	�K�hE$�E���R�|�HnżQFb(�76;�h.��HJ���;*�ב[�u�7"��X�K�(	r�c8��a��K��ډ/�ղ�9�Qr~tw]DŒ������l6����۪��n�P�6������M�2�ហm0���g�x\w��Q�0p�җC�pr�iՌ�n�p�ڌ9��cZ��~��Bs�x�Rpu3��]���M����;f� 4U5�!7�'���q0[��Pr����x_���ϧ�T�(a )r#�NҐ�$.�t�=A	��7�XP�
���?�L�2�N݃o�T�w��>��>k'��=N�T^8��QU��!a8n�0'��0_�d��G>�
V��`����8�n|&r�I@��$bwj˭�#:"툘f��� K���m"��hB1��D�r�X�H��n'�w�>:�UlvI89�Ë�M �*٨d�rK���ۯ%�k��Y99�����L�;��o��w5�(�V{�
�����#~�Pя䭝�ާ� SϚM~�2�2Bt��_�A�����۔YV�y����%�� :A%�n4�{�|��'�6�pN�(Vx`�8���)xz�#��� ��2n��[ ruʿ��V��Pj�>2��1�A����I�΋>�` с���hBk�!M�L���.�TB^Qb�5
$�Xm����TIn�2��ٞ�E���%��"L5$
n��aj:Y�eKgu��\%Y[��'J6�?xN��3��t�������8�_O�x�gV�ͬ/~/D�j�������er MLe@{��\�$~Wg*�G4����$�27�$	k3���� ^��>�p@Z����p懈�̛U�ҭt~'�6��I�^�ڄ�h���-�8Fl��)��i�G�i�k�n]`��c又n�S��7���B��� n�r;��J�{���#q��Y��7>����ở����j���U�J.�bY|��X!LKͻ��'���HʪX��i2�����	,0��9e	�E�e�l��s^X�Y�̩��"�v����ȋs�V�_y��=��N�it�q�d����&�-�ɱ�:�^�zf�L�߲����I�%GlSE\}��2٫؝��k2���WX�m�Xy���}����V�gY���6|�����I���wa���rKl�}�,�~�֟Un��3���\�n�u����b�c��[�pz\�N-<����*��"��[����j�����l ������[�����o����z<߅ �{���艟9Ygx�A�舐\�o��jX�["c�S_X�� Eb>nN}�|D|��@��_#w�'��˳6z�v-��9}�� �fKA�4�|�w|hD�a��x>����SH��\\���J�X���;�}��r��@�x�yԑ�pQ�Z��%&
�ȗ�Y���nT�f�����������ㆢ��pw�L�٘��Z���npW�O����}n��un��I�v5������z�"�k�<]u"�2(� e��9)�%����^CrcZ��7CU���<���p��c��m(*D�ϼ�����m����|�%�s��v�ř���n�}n�7��b���~��&�����dj����
�v��wYL�ʨS�.e�ҙ�?{�R쁺�WU���^-Y;�&� ��)+���:����V����e��J���m��¨�rٳ�E�k��(�����.���M\ù�3�X�Kêw��} �k�_(�j	��+/T���{�x��ڮx�C���C��(J�w^������5�e�b����a����h���$&?���ə�χM^�{���Y�U��*�ĵ0�0`�a~H��FGĭ�q��0}Z�W�T�ĸW"&�r}��r���Z�8g�}�S�ii���'�4Qfmc������8�#7�T���W��bX���[T�OV���T�S�_&��y�?b�0	��1#� �<�Y純j�+25�ۉF�B{�c�?�^�K�n�'������Ji�?7���C!o�p�R����́����������mك/2nb�5�|7�v��~�g�n]�(H���|���f��lވ��	tebAyO?Vj2T��2�:�cX�B��lć���8�+��+��!n�	i)`��pʚՎT\�\�tH��+��k�t �Tė�OݵF=��К�Dg��-�=�*��N��/f~ӱ��3X$b��l��@_���54��Gs�\ǜ�f @8��2�B���w���A��ɳk��3KWsN�ď%h�憒�GI�^�ѝwbt�W�"k!�f;�z��a���H�=�ܟ;�Hn���?-�����3�V|�%t5��R	ޒ�����!W�0{�X���?��-H/�"~�&�vZ�!��=B�P>���T���)�>�s
6#T�V&�p��{֍}Z���.a~�n!�	�@�{l_�&��ZHv�%@WK��[�~!���o ��%g,�nU
U\�-B�]X��(J�B��}P���̡��1�<H�� k�q�ڈ�Y��B�Gٺ9�b&�	�OGt�y!Y�l�[.�����	_O�e�%�C^�D���#.��)��H����������Yp�~u�S�%�]F��$G��#�u�x�$Q�p=S6pX��6�?J�@_F��D�z ��5l��Y�Z�V�����r����Sܸ�ѷ�N��%-�˶�@�B�[+��T�r	S{^�S�X`>�M�FT5W�uJ$��t-�
�¿M�Դ[CS�?����̓�p:��`Ǥ{������W�B.݊��M�Ңp��R��O�]��< ��x�<�7����-L=tr�O��Cv4!�@��z8��Z'�KG�$;�H4�2S�h�c�ܚX��U2�'��oxwT#��9&@�t �&b�T$��TJ��:U���*�����_�>)�� ��D��,}��7#��mr��ǰ
��%��)Ok)��`Q��e^��Y�2N�f�CY���dO���"2��x?��8���#��M��� E?fn��
�LUQ�T�9�=O�&�4w���V� ,�������>�{�>|���nz�k�oO�4pt�U���نf�b�dHX�eV+|�38��堒��/�s�5��Ujv���j�9h�{�^ �|KjV��(�B��d����s�T=�@�����oO�����:��!���b� _OF��n}�o��R�4����P�U���P{ߨ��;��'�^u��n����xj�}#��H�@� �\� h�Ҹ�\�~�2~��`�'���AXڵDŠ>A�1��ͻlc���6��;npH}�29�{��R��e��*N��Z��m�n,���V��;�IV�����T�E���tK�s����o��b���y:�����Ӥ�����qq�}��V��˒�d_w/EU����,B�캑�?"O>f�> ~��R�!�X���rF��6r#7A��WC���
�9#3^���q�Ax@4���_�C�h�\L{��K�C���6�������q��χ�;Ϲ�ke�	N-�ޓ3޿Q0��j5 ld�0�U��nnE���\��!C��sǘ=���Dy�/�/X�M2d"5�]5�1���0�D����M���M1��"f���m_?Awj���m{�����]�#*��8?����<x��a��l�~����m�<�Bm뽈ٻ���p�٤,<�20\V7��E\��Kk�H�ڇ��H�c͑B}6�w���.Y~wv��$,�Z���P#Pm�=}���]Q��w�!�!u�%u�k��|��X��x73}�+��?���ϔ\��Ec5�����+y-fӕ�@�8.�����fVw��4�0,�����#�XN���xX���x�!�^k�f^M��� R#�[����3 u�Z|0�*�3w����!Vi����RB$����&��'��%�������c�jti��/�x�Ld2����k���6'��f�0��_��M�}?��Og�������[��ͱ�PG���)��Y"5��!��+��@iT)m&`��`Bh���,���yQh��	�LG��w�������e��@�}<	8ק�ܥƠ�����P��ﻧ����:-5Q�"��0Z�?��	*�#V�6��ԏY(u0�E��P������e���O���j�����0~����z(�'�@��f ��T��9��n������"k���u�����f����{����A��/����'����O����gUZ4m1�Ϩ*W�j�?�H&X����6�@��h?�n�X�ɶ� ^<�h�^0.j�����kQ�����h��΃<`���r�tMS�oQT$��c���{������|
�Z�LJ���A}�XO��5/0�7�JGi���c�,��ܬ����T�c�io���JG7��X�"q&�KJ����� �U�D�}��)�@��1҃0���);���>m��.	���k��_]����F�βH�ҽ"����/��:��B$ gЗɍ!��O+#�̿؞7֖>#;}V��z� U4�����A�(3�N��5�i���Q�>����ۚ�G8e����H	�S���R&��Ch��M5z{_���\�X�is�����F�<��i	��^��w���!����@�k�@bpz_Bq�1oh�T�w�lG����K߇a��tP"�L����rs~ {{W	-���C��a��c�KL���AU��z�l�{2�S����u��0�͟�|dXߍ��(Ν�9#lP��Jz��c�N=��驰�^/��9�91���b�ǅ�Tm`�`��>�6���Q��*�����=H|~ZY��jGJ@��^��l�q���L�����~�����W�mz�F���n��.�	����K������cC�ƒ���c�wB�.hU%����e#9So)�8�8=ja�7�;>�i����}�M87��^ըX�=�)�Σb� �F<И�2s.%�>�7��a<43-~�����]
c�}&����FjrܙeI�U�8�J��띉�v�i���3�-�M�/��c�N����)��	��.�(��o'bN���E{'��a)��U���2��G/	�:䡙����C��tw6'�!w�0yĜ���6��c[�u��� ]i�p[����̰���av���#�o 6��Q�Ɏ�}�����~�v4�mN)�/0�����[���
��������ag�lH}�(s�~��`��ХHe?�e.ε�S��'T 6�t�/�'�b)�h��o��Ns&�S���U�p3_�Jc�L;J�P���ɤf�}�	�d�bl��fDv��"/%���
�PV��N�*�G\���A�m�\�x�
>���zG�mp{����s��v�'JhSFB������D����<�K�g��䧲}�؃r��=�W����:Lޯ��Ѓ�e��&ۿ\�Z>8�]���_�i�$�Z���w��U��"����3�`	�>	e3 �m���ŗ$S�c#~'Vmǭ��"��L?�f߶��r��n�j��RIB���ኚ�,����*�SZnb��B����:L�Gᐢ���$�}���ָ�ד܍S��m�KGBQ����v]�.�^Cps��u��	G���Dj�0y�ylK4�l|��;�B��sX��%f����2�\[	E�)e� ��`�YoJ��Х�R�{�-\�y�R��,k�Y����������ͥ�M1ϯ� rQMD3�Vj��<�V6�D� �.M֏*�{GU�΀��ǧ|����;��[U����p	|x_�J��0&�<����Mp[�N �{�n��.���	^�3���ۼ��=�"T�v�e�}��`3�����D��ؿ�:?���k�kv��_��S��*m`��B>�Ho�䊹��(w[���_�^����x�ROP��� �-GH���zA$:�������骪6�oNG%P�C�{Ǎ���>�M�������g�q�5�mbC*UP'���)p4�8P����/yw�S�1��5~�/�F��~j�{�NM�50�+�)�N���:$ԭ�f�d����z�d�n�L?�� /)u�}�4m��c)܁�5���^��i"��q%�!��v0X����5(�׏��h
����P�X�g�M`Bu����*_�G��U_�S��z���� LR������fX��dG�:�%���1���b~v�V/�����sؿ?)�`"3_|�>�j�j�?�9�6�=���T�d_����ũE|�ۥ�x�/�s�6ޫ�7`fZ��<_�����/���ky9'~�^V��dj�a�`^�)����TaE}_g���xѵ/pj�h"�ϨB+=I�?%��ܕԕ�T�!�1�h��#�<ԭw���ހ>���җ#����m����q6�� ����-�%�a-�GD���>ȴ���";ڔўf�j���d$�j��=����Ƭ��'{d���8B֫�o��h*��³ 垍�]p֚lRe���]�:�>Y7�TN�s�6�_�wh�|?s��r�% ��A*�*�T^g pw��W�lVu��Qg\�Xa�e:�-8�����2�P2��Z�^1|N�} (�A�ۣ�v����=1�qlG�g��竰r� �`�����'9��Cf{�Z&�w��M�M�5�78�����` Q�W8�~º40S�B�����mL9c�a�X�2g��;���X�=P�t�!��Qؕ�c��}+fUZ2}�!�brƘ�����n-���g��n^�i����QDw�╺C��@I���k�w(���A���&��&�I�1�a��K��"�`rsxk��0�Mg�`��G�lz�y�o��jYl����`��F����Q/O���t��?$}|s>�ҭl�r�Rch�BE;a�$r�,��к���������<��ˋ�,�s�$s�+e�뱬�ߣ�p���٣��@SR��3�<�ؤCr(U�yo~����^|��M(� !B�T�#+�7��.�_�1�Y:��W�mcV�W��-Y�$����ݎ��]����M ���|.cH��	]� �Y�e��#pM-�=��@.�.���R�%J��3Q��͖��xL-tc>&EftZj�[��� D�`���2*8����8vf�k�u�@�	6>Tg7��P��Aq�ˤg{ӗ�h#�A\�߄-q�����&˱���p�����B�+3�2=���o���f���_ȫ:�ʒrH�8��!�D���j-Z�J�d<Z�3��W�5��	rۆ"C���*6`z���nw�<�pU�H[Wn�!|N�y����b�܂�tG%�/��DVnQ��(���G�X��r[%LHp��W���$c�I|������	sUJ����t�0"�g�f����.YJ�8}�Y����pz^���8Q�)T&�Y�����2nJ�����ۣ���E����@��}���f���&��SD׏�#��C](�a	����$RdKp����2���{�^�.�OD���s2����J��e��z �5'y�`�{�~%�҆�#,,Ø��ٯ�DY��,���f┈�$#,)�)�&&����^N>ږR���.*��yԠ�
C~�xT��u\�s����bK3��K�B���A[ҤQ���@r�'�J=���d�nѕHPa6�G���&\���.on��?L#���s��Y���Ck� ���V{� ����Gɻ:ژ��~��[�gx����R������d!ft����qM"��]�"����i�֛/#c*�/���LH]�<�����8vY{-�ˍJ��a�Y~��0u*R��<nd
�ϚuA�$�s�o���cFռ*�$�S�g���:�	�غ':�l^!vpC�a�CY2. �ބ��	���Y�z/�y�,�y��+�,�l�2RLC0�S�{�84ְ�^~
��Z��"L�߬*����-E��)g����5�9���Eۭ]�7����O�U�yO�z .���k�����L�#���
�R�=jO[�{���q&Jmfs��ׂ|��`Γ�����m��["0X��A#W��^+-�&�2�p�ʽn
	����Ԓ͞��j3�W�C���U�aچ!
8��vΎkt!��F�qڼa=��I Oԟk�Y�BWB����wg��1׏��ae�S^ވL`/��'�2���za���O����D8wM應�+�<F�w�����ܯQ^�B{W���S�2/8��&f���wϖ i����Y>@x�j�/9"&��OP�����ޫ�жښ�W%��u��-�SU�h��2�Q�倩�����N�����j��r����cr������,��9zk~�2tK�{D0</�U�}�vt���U�4��#�"`�3b
����D`�H%j(��_�����"ՠ@�.�p���ظ3tN�����\�"�Ax�<�@�dP`s|��7�+���d�K�����b+_ڬ � �NM�n^�/��"FƤ�=�3Y�N9�i�7 ��tJ	 �Y� _������ OhY;�����w�;�nT2J��dyd�٢*�P 
"�G��O6����Y��x�Ƅ��\e��Rk����O�-�o~E����7�����<�n:����>�<ހB���O̳E{���[��v�O�ր�{�t����Ǡ�~_�3T����T�t�m�lA����u�՜�l�����?�'�7^����>��?Y��e�WYP$�w-�I�A��DQ������آ���g�<~^U�gI]���e��l&䧳 ��������$�j��b�7K�=����_ 7�ޅ?�������rey��^��0����k�0P�Ǡ�0��~S����
��n�U1���S���&��������QٔR$��L�&�Q���<H�%�d�l��rq=7��Hɣr@9�*������-R�b��j�`�΄L�)�'GdKz��S�0��}�����^k�'�ZDZ�i*�.Hb��!s1���/@�o4����?�����p����k�9m��u�D�	�lAwo�$4�l�(5Bj��n�W.�q��z�%
���V�������V���SE8w�p(��K��Bͼ�dyߩ���I�l�L�AU)n��p}�{��
��P�� ��E��p7� ��ϰ��V�\��lX#?Oݽ}o1`W[ė->)��%c/���%��.f{m�mGK]����S��
�)����̀Ϻ5��:�GS�����:.���t�U=�Q���%��I� �,.�Խc��~6��r_��L���$�l���N33�R�4@ݡ����R<'�R�Ҩ!�0	�ʴi8GP����!MX.�jx�*�Dwۅ�.��G�	M+O=����tu<c�%�v��� ���ؚ4|J������_�<G}���<��d1�,��jvS�ɚ�G|zӶ�O��aq���Hu��[�TZ�'���Bv�L�h���ݧ�cX�����P&�Y���q�G�p߸@�Ҩ�8�;���հ�X�;4$��As��д��~��q^TUh
Y>%_�B�s�����+�e���z`���lͅR!%bկ��T��� �.;�HoYO;�>i�bzx�'�D���$y���ѶQ_�<6��D���+* �Qb���ƣs�c���/[D�b����X�H0�Vc���{*�U�5�g^a��1�ǆ�7��	�Y�j@��3�ݗ���iVt��k�e6�k�g�%��TiT��a؟��ءZ��q��\�mrl1lOg���kx��vi���!ӣ���Cv=q9��݋Q-��hb�9j���Qi��>X��{΅��m��+��}�N*�$�G.!���K�!k@=��M!EHEs�]�a���5e�o�X��dX:7D��-\���C/gT���˵���i^�]z���I�3�_���ܭ�OcO����*�iV}�
���P2:ѐ��    T�.Iܒ�u �����L���g�    YZ