#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3568328774"
MD5="b9022e8fab06a2d75cc1908f4ab66273"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19774"
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
	echo Date of packaging: Wed Nov 20 15:27:44 -03 2019
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
� ���]�<�v�8�y�M�O�tS��鶇=���c[ZINғ��P"$1�mR����˞}�������xe;�Nf/у%�B�Pw�����g>O����to;�4����=���߅����Γd��W��,�}B��\�wW���O]�t�bb뎾��?e�w����g��x@�����T�S���Nu���ʗ�T��c���LC7(�S���E�����wsɣ�e��B�-��rC��2��ԙQ�rm/�.����ٮ?�?��mq@�jcO��n�-��|�j��D�J�LLF<��;'��\������+����x	`�Ʌ�{������c�)��d��R�*������γ�#m;~l�F�\{,������p�;�����ɂ�"x�?�hr�~6�L/:�;�t���3�������8mn�,�g��sMF�JP �h�� X�Q����,p��"�a�}*�s�(�o����Z+�E&�q��RN>��-F7@Զ7u\瞿����7D���f�r�K�H5s�o�̵m�Qؒ�P�-�7���M�2	������E٣�k"Ub^���y���u��+d��� ��������sk��C!�,4\bS{
�#q�3F�A;P Ufz@T�ԅ��Y��â��/D5�JuBˊ����|���x7a1�u�kHA��k�Ƨu�� ��O�94�2��Ϯ�Zmvx�tA�P7�������L�H۸�ծ�KU����,&�k��CF\�a̘	���	�MV��wD��g�)҂�@�Z'm�lA���H#Մʺ֒�D���ن���9 �o�#����
�$ i�;�;�d��%JY{�(UV�k�8���LІf f��s3�sz����uV�����i��y�<?�{chK�ϧOp��r���^.L�O����zi�^�ˇ>Ս�ïbW:3tBZ\?���4�R�.��T����A�&b3��榰�l+o���u�I(�����c��C�
�S���	�	t�/C�+s"�o�?�0����r�Y�dM ,����[Q�l,y��9�/�΂� �Q.�/����n��vv���'�.|�����{�6)d4g��J��=�|<@[�-���T�$����a��Ew_ɧ�b@��������b~5����/��;�����nA�w��������U2~��n�C����Is�È�7��v{Gg�N�L��Q�tCb�W��@�E�0�0��Q��#�³�@&	��Ol�0�&�$�0>nJ�岠�/�����3�e�bAx���Б��!Q�OE�6�e�&���&�;W[?��Zs����gd�6P tt+B� :�����j<�n���)*Hi� �ռU�*���rd���;�G�K=f�U���3؜�,����[��0�����(R��G��7��5�?/9���7{���_s�gXxU��iԯ��W����(�����o��[������M������ $�\'�!�!D#�i�@��u����C�b:��9<Y=%*i6�����
i:���Wr�Rՠ�:�(���%�K��,J�tC'�K-��F�r�����ʤ�X��S^���֝+R�0Y0��ڵڣ�l2ҺC�-,3,�'p�t^R},�MC'I㧺� ��%>'���`b�\��c�	/�	DO����GR�Ϥ��FJƓ�v};��lx<�%jr���S��b:�_���/�I����`�O-
�'O&ۓm9�	�L�{�&����&�!�U˜�@Ù��G1�@NZ}6_Q;ǝ樣ɷN��3���Z��{���2#��b����{뒠����x�?�O@�,e�k�JJ�U. 1��l�넑L!��.���R,�Ch��$�]?w�=���%��8��ɂOB� �焙���?,s��+�l?7���M�E,�(��ů�t9���%���^��Ϙ*Z�������.��0;Ks�Dn��*J�VT#�k�A2ш,����c.rT�4�(�KU��&U�o�XAVJ+$�,�\Z��s<� W�h�ó�$1�c�%�8PV)v������M��j�km߿U��PG&�_z��`s��wz�z���Ȗ:Đ�<��Nf0�^���G7ܐ��xS���S_|�KV�M��]�/��@D2X�" �*�cJX�֔'95�� ��5��p/{l�\�@^�H� ń�3lja4��mq�ԝMO��*v��@f,�T�
��5FO)p,��q��g�1�����ƚ��H�ˤ?J�E�CZ��h$ [@�|�$Jk��;x�D&����n﵆;S\���F�J!M��DE*�́�8�φ���hF��0D�U�Aȇ��D��${�y��}���N���G�� X�������H��]��t-�쿒U���ix�<���p�&GRdAחX"�rr�Y+�~� tpʇ��|#T%9P�fN=�"����6��r�T|�cwJv'�9�[��_"�ya~�]�2�n������E�j��T�T
P�dƗV�O�R�ӶI�c�p9��=4�v�Est���m"���&��l���$��3�F��{\��[i�o	���GH)joe�2�G��ͣI��6�y��{�I$G��Y�����`n�X�3Ԡ�Ǿ)�&���s��|x^3#$�/�IDa5{##&6îA��J�E1�s}A	��MǠ���H��ڵ�M������5�⼘�_��ǯ�0q�)�0���ae���{�;O��{������?���X�St�����I. +�yS��߳8��sfN-�k{!��.���16�Qq�+��_鎰������=3�[3B<�t�9y8:{6�m4�h����#i���k�xI��o��O/;�����;�;�����G�����. ���yH����Q*�!ާ�C\���5���y�����+H|^8	��͊n��w�b1E���+�%a�ǿg+-��:c�o3�Ua��ä�����y��@���PO���R����*��/�����W�g�ʦ�Ga$��&�:NX�k�����;]�9����)����(@O���8=;�qD�E���D�]�6����i�1�U��~���R���XōP c̘�1�6�:syC��.�\ׂ$ =�����Ϫ�S�Ut�l(J�+��J7�o
�Y	����0������O�>��1~`=�j��ʅ�[����
BH��TAw�铸J�DŸ��5�Y��QiF��l��&�+=�:PO��j-ۃ�n#-x���Zh%(%l��6�2��z���(c6!�r$�r��1�L&r�.�����Ӛ��5 =c�;�]4��v��?�xV��utk�L\�Ġ��L�Nǂ�V�a\��&�{P;6���D�!p���
���5��,�9G��7�3�G��!�<�AF���ʵ���s��t�|o3;���I1���G�+ҩղO2��B6�>�&�M-�Z��e��%��������߷��f�IΘ�4��&��S�!/�Y;:�B�2����.P<G>�
n]�Q�{��N� ���m~D�#U�!X��z��P�M�����Y�37$��P���1L=�$Q��_8�oZ�~����u]�TC,}��;�UA�aT|��'�x�}%�(��N�B��|"�sd&����Nf��O������%�LK�� �5 ��0?辑M���.dq�.��I�-$z���k�.��/���/�?;��y�$��ΏuV'3����Yb���'7�1U	��m�=�i����p_�l�n�%�n�s����q�1קjSv<O�D��t�/����ֆL��S��f���F����.���q챻�Fn1C-�|r�hQ�0J��7�@]�.�G�b��
I�>9�*k�g	rϙ�hdaT0�>(���\��9��F}����N
�;	uYgɌs1c���g��9��Ң9��q���	� �V+4��O��3�3��9&8�~�x�B�5q��v��0��;��j��x(�tfc��;�(���l0���-B$����C>�=¯�8�8�{��&#�Frgߎ��+�A�%U^�t�I_�2�׊A��蝱H��0�0���E�<���÷�-B(:S	$�L�:�0��������9��ڨ��{���J�u��X�[��U
�<_!]#鲰�aS'$��as���N�-��W��2>D�=�J.�'�Ju�E��}�]r>����%��kA�1yfCCc�� �x��X�ܓb۴��b�����͍�Ffݠ�<p=�����M[4���N���nS-�9���E��j��r_�}"4S�][����+<k.u����V�>\Ʈ�ԛ�/���D�nՄ.ƃe?d��l��|ܘ����6�A�DӕG�f�cZ #�j�2�r=��u��Cd�s�숣�ã���\ �[�5�ޫ���3Vd�	l$'+���z���q��)Z0�}ҫ��P�g:Xnd� �9���RDB�J��v��I-�J���+c0M��bȡ�Oi���Pp�0Ϥ7���\�V^�;�),eE;�寒�K��_G�!��n�T����kE\U��U�Vi�����9��3EXtj%�jr�9=��Ɲ���T�SX�YBfF~�$e��+�i�O��Mc��4���t�3S>�'��,�����&u�ZeW,����Eh�gj	۠�*إ�6[	������hb�Ru�:�\�P���O�AQ*�g�_:V�	��dhĐt�'X�xv���^>'�P��&��w���,�Y8�sD�e`U�G�sl n�R��,���=��1ɻXM���k^b=�!��!���|�լ���,�R�� �ܓ�a�IL�V	2��^_�q0˴G���+[�N�v�tN�����6ώ�7
�q��a*��A擟��hf�d�|��Z�#�Ϳ��!U����)%.��Y���~@w��gIQ.�~��^�_�',�>zDL���ן5������E��X��wWT����tV^"Ov�:O�	tg��t�%�0=8?�rU�u(�9�_[�6��MT����d��Sz1�Hj�Ə�W�NlL��@*��t�iw���3�I�� ��ȟp�(��S��7��(�=��\��3�ðL��L-��L�����t ���跑�=�a��&���\a�!R�в"6��,I�|a�F4�v�:��99 x�:n^6�D't�v<�_�9��r.�TU�ˬf���]���)��ک��\�>��jG<T^+��dS)ē��>��m�C7yÅ�Z��s�M+~g,L������"���uP>0�9=��Ù��5�KX#g\	�A�l.�4"6bܟ��e�u�2�L��p�R6"KkrRe=��0�������hs*p���'��FA cn��Zg�4>����3� QT�ڣ@7-�4�᷈�Tc(��sZ>���<� K={�!9��B�J��`�.����'�EL������o�n�F�ݯ�_7�#��$EJ��d:[��D���qf�,�ْ;��t�������2��ü&��@�h�Rd����L,�( �[�P�U�s�,�>�\N�ZT
zQb��#�F�����gm��,���;\�S�fs+���Z����{T���Ў^�+�$��/��"�()�R��΂>Y�T��WV��hO�� ������7�6�p���7#����΀��k9�`�Z�/l�+gʕ�YY]ͨT�Ct=��2'��t{��S���%t4�yK�˵����k��\�y9�"ΜZS�
����+6�����N3���m~a%�r<0Vt�*J��5s=����=���%������ߐ�g��*�,8��Wa����.�h�d_cL|�Ƴ�h��~��v���_�	���bF��܃<���e�U'�s�ދ���_ӱ����F4��WX����`EY��?�`��-
��S�ߨ��t��Y������o�f|M�hr05���U'鍸��{�we�8�Ÿ�:����#�:��$��j�;l��;FZ�N��?%��LAX#�þ�U:x<و�3�n���}����H��'b�z9��/����?���j���ƽpL���@~�Q�_j�#��������(��A�hP�H�\.�o2�dlpX��-d/�'�̒2�*<�z}b"zƂ���5׶��p �����'���-�6QRIb���*l��f����^��T>#�Pz�%hO�3���d梚�����)�Є?/L�Lҗ</5Ob�J�G.c���_ug�B�u^�����SuB9��qp�(��/��ySa��nU�+��)u+�����>S�%����p/�&jN�"�)�f+!�F��o��(=��TdH��YA�p1�g�N�0W�%֚hf�(������d���=��la ���3ms�.��TZ�p�!�Y��R�lA�.+���B���&�Hq��uНNr�8E��uZ*�-�����e���+}b�j
���?�:�!�x�87��qvrd�a�Z@�����kj�����i�V�K0̄>���Ej��f�|>�؛�}w�%��J¶�J����&��>�$�Â����%��p&"a�s�
�����ك�ygu����.]n&��ݛlB&Afa�_��ұPU�����X&���o��7}�܊��wqh_�B��&�W�Sf�`���������̰�Ϭ6�C~�q$r�G�~��w��Fq�M8(���1����z���� b;��$��m�|��D�]�
�nUH<�{콐��љ����� ���R�r��|����.z�(�-B�D���}�y�zϕQ>k�%�b�D8eU\�+���!��*/�Z\3���t���3p�<Z�c�_�� 'O6¾M�(�WT�]�O�\h�0i���w�|�.N�y9h��8�.�>����K��$r^����Th��Iӽq�R��Yξ�<o�I�V�c)�j��*��|�-7E��؂����5����sͻ��^�����q���z7�YW�=��<�/�j��<w���d��[���gr�՞��4�͞r�*~gOA]f�լF;�3���z����ӯ������o���M�s���=�in�E�H�ה{��ն��52sd�p�P[̻A,�.�##�ݴ�5���s��u���#?Y�I���1+���T|N��Q��R��x<j����pb5S4@�{�� ��+ �b��t:���Xj����h'�b���`I��p��
�9�F���l� �w�Q�Zo�Ҝ�T�]�U�M��0��\��N�ǔ$������_S�j;�,�o��[�{�{Z��l�K�V�W�3/(4�/؈����1���$��dI�((���ϗ�o�<B��e�aݶ������7�K
���N�ת"�u�]�CU�^r�S�dk�~mm����E�IN���7�������H�-���e��a���[�5�L��⌸@�Q"�+V=�d�S'^�B���Q��V�zu͇�@wԃ����<�~��)y�����e���{s@@N	��������D��ȩ_C�j��j�pUiUͯ���Ϥ�j�x6�&U�D��k�
��5��rl�+�� 4L)��"j]���E<�g:�#z�U;r���e�ƈ�#��P���+�ø���	l�֌�:�A�d5�-k�3Y螧�艿�񪿴*��R�>��ex䫒!_�0_�+M_h��
��BJ`�5p�*�H����wI.EC9gO���˅���I���<����F�2�Hjų�18P���`�J��O�Ai� ��&?��"`��م�?�_����,�A��8��p~��p����Mw��9�%���?7�k����?��^���kպ�����@����k���| v9�P�dp>8_��X�����C���><}P�M3H�0>��H��h(*_��#8�$�����}��D�;����Y��ѥ��_1$�l��� O��]4:!Z
{v	���FCz�x��ˀ��z��c������	��㏰r����/z�01`���>�]�^CdՐ+�xx>~$Т[< �
w�:6�4����M��&Z"o_8��Cػ%���h:�Q,��O/W���� #�_s����ֲ�g6��r#��<R#��Ʉ�)p�cLsB�r���Zt�{u&5"��q�ڄ�d[IK����%����R_$�Y	|U���)3� ����Dc��%L1��͕�J%����Aegsu�K�+6FFgA�F����|�\Yu����0Ѱ#Z<�tm�冧U	��
&��טѺ��G�Z���j�Ӫ�A���;	Wfi��+-�X�7u�b)Q�T~ޮ�m��Wm�FAf_���"� ����t�`ܛ�Z�P�+��֪zR<V�N1��Al_�>��=>n�t������Te�P6ꨴs��;X��(�v�SÙ
i�e�U��Ц���4�=�&�9�ܸ�A�8H�H�V�XX�����?�Qo��wnFJɬ��9#uzSQ�L,�)\�0"GЃ�Q�J����HH:w$��]#lEH�]�*MJ���<tkL���ޓ.�XV�\�ҿ���>��
�}����ʖO�4�	k�o���Ó�/e	����@�S`�J9╇��=d&Qk�~���h|d��=N#�$���Ę8�~��>�=��F��X!a;AO���cI�3Ɔ�3��T/U�W�7�K��9�~.��:[��oR��L?�p)�տ��rYA�z}�ZFY;�جL�\�����o�Q:�U�]��3��w�8,ȴ�\JG�C+�ԥ�>\c��d����f]�ٰLo[_�h[m�ya�~n�)Y�fcM-�YQT%rI�֥�y�|W0�x;�p��n&8�otB0Ŵ��=��Cy�S�n�Xo�*9f�F� �v�G� Z%i	m~}�n+JpH��5A8�ԡ�0��t6�P�8�ڀ$�A����Έ�ѣ(E�tH���/JH�8��.���a�[0���*�_5�]�/��h�������ΝLz!�i:�W�}a��t&��������ןd���{��}��;��-]��(_0��+��
�-	�?�R��_H�WÁ5{�1z솄d'��dCnlc$�JQC������n���s�}N�u���\���<W����x�!��A�'���§g�*-r��s�D�������=��(�A[����Dc�63�c+݌ڛI���g�d�?�k2� ��Y�#W�V.��s�ʣ��R8�d�rDx\2\�y�!��^G���A�@)����D,�C]�R���I���I/m�+���`�/�j���W#9�.�E�QB4�0��3*�Kd�7w��o�疋if*S�N��=	&ӄ!���/]�n�ݦ	�����Oڤ���:ш4CS���zs���d�'�|�tA[Jr���q�)YR��E� N�?ùIH�������3��x���x?u8]8m�J�%�}�4WDy�7~!*}Q��
i'"�� �5��A+M�2v�Ɠ
�p�>�|�Q�9dS0,�.�`��*0<��Q�D�a��W�[�g�,l}ELyK��2�x�黎�����ر�ޅ��h�0�`��������DΉ���X�V-��Wתk˖Sx�j̵Z;��C��-\g��4�r�A�gQ0D�`����\a��ق�
c�Y����c3}����s��Ug̷A��Ŧ!WU�)�^�{$�	�[��^���)j#�6����q[q��NX<R�i hq�Დj?J&���LSz����,1Ac�� �y�:g�JBM�J{�li�T5��9?܄ ̦,5.�1�SFo�a8!d��gQ?�\?��@���O}���Q����a�02�����ˀ�)0>O`\�U��������w�͇ޥ�:Up��0��e�Q�w�:{2���k�^	�./p4�@�$�D��y����H�̸�	o�\�ÜW���_�FbJ`��$ɸ�u[BLT*�i|�i���CX��)�����˕&	'>j=�:������ςd��|!^�EX{oix�3W�8�M���Slh>�Hʹ%I:��`�%J�UD��JQf�E��^Ex�K��>���[-]Et��QdI�%�R�6a��a{2�qٓ��P��iS ����u����f?��&ӥK7�bʱ�G����TŲ�b\�o�q�K�#L%��q��;!����-����Ϣt��~��!����hl�Ll�Ht�`
���C���֭gTvo�F��l!ƪ���#&NnM8�*����2B̀��,�T�[�uxW�Se%��~��`)�ș�?�\����@60��E=0�Tq@��
3��R����5�(�x�?���P�	�背��n�&�H�g?�5<F]�{#D���x��G�!�5s3�nݷXv=�!X��I.L'�V��q٢Hy���|��ߤ��h��rr���躍�2�1V�i���Ц��Ƌ���
f�<:�o����u�y������~��2��v:��N��a�s�}�M��VZB I8�/a��-�����ty�)pF�n�Ѓ��$t=��_G	z�]�Va�h��YժR�:�� ΡW��K�;z��C8[�s �B:)s�!Y:����2��Ī��ht��P��Ȑ�('S���'3�u�'�>P&2��;I0~�!+N.Ӻ⎛�_9W2]L�E�\��ϕ���������j[��3���@�1Ȋ�jz D"�5SDn�u�_Z2`�&��"p�5��Lv�����:wgOcά���7��T壺T���ޝ��΅}�������p%Ĉ
]���0�ө�B�����M?j�ۭZ�B2�f��z�6�����:w!c��dq;�J9�t�s0� ���4-d\�W
YGA?�?ߦ����L�w"�ڨHW���������_gF����o	��bs0�!f	P���6�%s�}����Nכ��JMQ����4��|4w��L
�n��m�����@�*8�y�1f2Q�⑘@1rPИ0�^.P�����<�;��%��
�5\0���V���,�0?�R�5�0�]�#8���3v�s^,$@a����w/��F��~�	H
E�CG���폆�H��d5eCA(�m]Bey�Xc5O�}Up���G�o�
&���/�n�#j��(
O�>�����W��8�U�2)���cœ�v��I��2�N9tw�v'�Yl'��oE_��
��g���E�=��gW^ߊ�@��0F�A�{ �f�5F<��q4B�h��H�F�4�C�x�%*@��敮�*��+�-�w=F2ֈ`ѫ��J8�� �6�Ż�T��� ����%�ǓJ��].ϟ*��:	�ꇟ��������N�5�J�������֗��������8���M�Bf�9����U�/4N`mB&���.���#�V�A�!V�K4����d�U�V�=t����*�����^����[�O2�3���-@�5伄��Ǥ��i��9ҳ��Cl�`A�h_�-':y���'�J�լ��dv�xְS,�%�/Oذ2
{���h�;��s�+���v��V �hyy*V�M�mp�1�Hm�q���kaE%dm�9�3Ù�Y
V�tf�j���킑�D�{/�VF�%��=1S����Pexz%U:��w���O���
郎0;+�13E�MS))��������j���w%�6�^�ʪ�*Hd���&�ͤ#�q���Nʰ24�Ҿ��1;C�k{,1�ˬ�N[��R��h���g)�s���؏M[�EǧHh��*9&s�bla����Ys���\=��7;�-�x#�˟�]���ן�UL\Z�0��h�~���X�H$(��%��\�J0��<A̭H��P�MۣEڑo�v0��������+��p��t��zK�a"~U�1��=��
��3ΫЪ�S���ɶ�|��i�I�+~��~D�GZ����/�U@.B(i�^�Z[Ȫb�����Ĵ$�@����k�M�֜=�%��BN�7�����j��	}�異?�i����±0��5����[,w��F�~o���f�n�2�U^�����K��\J���l�*"g103q�Nl����*�-� ��Wiu2����]/5�e�p.�g���<�Ȝ.��58MT��9#��3nT�>�\�7��y�(��]|�J��-�a3ަ��	�3³��R�1#�!�:_#l�.���T��J�m��۸�)��A�3��?Lg��v���l��S������ �K��pD1����l����=������w��%��i3��U�� ����b�o���.��U���g0��%v��&3��a��:�q2�I8�C�JY2�M����4�@

���1�>e���{���%��#-z6���-e��?bC�3����k3�**G����@�f�~���h�NFBE�E5���1t�li���ي(��`^g�%����:�0�ubz�\����z8:�A�8.�7���bv���(�&	��wī#��hۣ��9
UL:���<<�&MD�wh��*J&A{ MY�e�W�hH,I�@�`�t�֒6����e �eE�X޾\����X� f���!��f��P˚�/-f
�Dq���R�\��Rv~�E�Ď�D�F���GB�L���9�T��\��/|ˣ��A��v�A�g8��ṵ�U���H9="N���ѐCr�G0C�dB�����*(Vzx��AB�|5�_{�ˠ����
I��C�ib���I�ۖ�[���#�B�c�w�>&0���fkY��0$A��y��O�d�/FS0�eY®�!��;띵�ZƇ9mꂹE	��V�eZxu��ld�r��l�S�.�(~&|F,3����H c͢c�$c�B�#�����3�
�ޔ��r9���I����A���k�Y��/>1���y$T(�\gz=���*gB��P
��t&<�$񷄚�[��2��`TF�쎁��R^Zz�"2��V�� wH�@����Ua 髴��r2:酗��F�T쿽��}��T|p5c��MZ�̗�,�4�v$/�w=O0�D���m�U��E�䂧p5^w�j�{�z���39eK�{����G��2"�3���jp�/!fE��u�+����V6�,�l�Ff���nY���67Y�7��X���Y�ri�,�R:xKI��*h��f��0�'7yۼ8�Dtl 3����>�9�;��l�q���xI�)�5�2[��̏M�n uS�Q�xإg�D���@5PfT"	P�ŧY�m,��H2�6k��zN�f�*�p�G�+]Oh�0��4��v_�w�_�M���NХ �� ���Xn�9ӿ�	�uP�0��c��)�S��,���,��X�k�h{1���~O[�-���l3�ۗZX(O�A��9�?r3!�1�|��Η���{�� d�s� ��:Υ�%h9��(@'
n��(4�2B�{r��Y_ U���Ym�{XK4�LF�RK9cw��M^�V���r{�,ït����+O2�5�6�{���*A&�R�~��OO?.�����OkO��?�����(�S׉���}�Q\�f*��bJ��ȇ盆kE�2�Fl^
٫gq�G�Z�>U��
AmHڣa�;��QA��PaU��t����
�ҊaE$�q^��x�ū��ã���_)R�D�>�=8�i�@__�w:p`��IC�M�R����0#���]��J�#��6$��"S_RF�RT<T	?B]?�fST�{P�A	xp"c�-�8c���U���\��y��)�q���E,���sTn��Z�y)�G�3c�'�B��q������w�������������]�!�ӑ� �s'�v�K<U�<�|��TȫQ�����685����|�P�Zo�Ջ������Z�w����K8�����7��7�o�v�e�z�\���b�:MJ�a%���ɞ&��>g�YMx쥺��d0��L�KJ�x�L�
ʰ%z�/��iq�����\0�y'�B[H����]@k��J��*��m���K(��
�'�h���>_�à�}RKGۻ;�w/w[o�[<�<u��Y=��oz\���g��������}����=j7�0ޛF@n~���1^��SG��4ϼ|��{��X����d�N�r���:9�����w�a��AV�(���Rz�׀�^��C*�t�P���������'յ�w�νx�}���0���)Q�*(��^�n��>:�A�f��_7^��P)x$����Syk<u��6��,{�/%�����C-n�{��<$�������z?�a*}�]�,W�ek������p��><�- 8�����ڝ���`{�Ԁ�[�7�y�9�ܦ�8�rX��i�P�:�m=�f8�i��%�T��X�S?H�{NϿ'�z�n�#����o����A�֪7�j�k�}Ɖ�KjRK�����������`�x��� u�\p��E~���A32:����a����T��8� ��@���+�T6�5ȴ���]�p��EѨ�NxI{�!c���AI��'j2�����
�֪q�-��7'���־�޽'Ԃ1^��zb���%���ÀQ��n�syg�\��˞�oq��<�+���p�5��~�=���ݲ��k��j�c����1h�7Κc�<
�ø��R���{G��=�ʋ�UN5��&&1RF)�IKs*�Φ<(������ 왋��mLv����D5j�*rK�M�2pI�RW]��_�V��rX=��p$0���&�M��ĸ֝�����q������3�Y�ML�%CM��N���,v5P��g�LC��*e��5۾���jrt�nw����sk�_&\����[��A�_�H��&Z���/�@�FoX��o_�x�»e�j���i�%h�^�~�D�wαF�0��r׍q��_A}���We#Z��
�k�6�Dϗ^�2�����>J��������X>�'$U���g4��
�V�ܵ}��P�������U���4?�U�?g}1��ts�Q������ݾ����3ր�Q����/�G��d�=��Q���}|b���QQ�o�N랊؞.�M�pX����z�^��uv1y+��"�8�p6=7v�(5�/�#�z���$��������]��J½�?�����殺�M�d� `���ufb�w1�V�z�3��t���g>蝉�������깢��RR�X��L�^Ç�B���5�>s���|��^G�
�ٗ�*h�Ga�����:o�ⶑ�g?W���K����.��ۻ��z0х��\�x$n�e
26��͛� �/N�|w:�>K5#?�����:ؑ�l����8�H3�$@N��T
�4�]nZ�̏4`zi�؞����T��ĵ6�
�q4j�B����_�>�8�~�����	c`+"*�\���?B�3�kB:5)�� �"Y���	�:�6tw6��P�+����*� }��+*刮�L�O�����5h�*F�f@#t:�������,�3
��
�a����g� #b�T��L�l]Dn���}��g��c#���ԯߜ�le�j����\M�X�c�Z���ZW��VL6lx:L��f4�2�p\��_�)^^k�[޲����*�h3�|��5�XG�x��W�Dh]x:a��:��)����_�.v�1��ǵ��&!���Ps����j�S� 1EA����g�;���.�R\���#8��BL�apU6����7e�^�*�PP��ʮ�}r��I�m�yԾu��}�&�	�n�&���9'��/xTR�^<���Ͳ�5����ǩ�������<�\� �:��a�J������<�#����E>�l}�zU��p�i:�J��� ��o�=�a9�f�Y�eP��U��ɤn4��r�i�������^�����% 2q���)7��_�%��ljC�F��ǘ��_&�>�V����?-��/k�Y_������7���������� �귳bc�D��\����;E8���ѐ���)Yd|� �P����;'{tÉ�ڬ���{vUx���8���we�l	�E2 *�hXIІ{d�<Jȏ�@mI;+��=�_4/ɖ��z��%��S�������� 7Q�s4nڨ���=s�(ۿ�<=� ���3��EiM觤 ]Z*��I���6��U.Di��Z���Y�6x�Я�|CQz�Jϟ��Ϙi0k��M�H���B4{��qʌ��6L�_63�y07z�Z�
;�t����~c`d��X�������T�6c��E�\)?\�Bk�FS�a�&�)-Ë�g@]���ϱ:����a{C�e*
�ƛ¦���
��F^ƍ��#�}(5��oq��b ��^H�P�j�m���f�ͲB0�O>���a���W�>����'J����]:ʗ{�A�$�^jX�����$�yG�LHa�%��P�dM�"�R�d!���pX.�fUL��찞P5��NB��{1�̯�AH-PR���zM<��r {�1������+���}m�D�9��0=i�R�5?1D���E[�5n?3a���e�f�.�==M�ǣ�D_��ȑ�N��'Q��.����&���zA/��ixXgb��.�(��`�T<j���!��>��0���B>K���SqH��� Ck���^@ ��cr��ӿ��^���%�e�PG��M;�; ���l��f�;#��#�;�f�!��wE�b���T�*ċ�nժ��V��)�nU�����ջ0����K�I?F׍�s9����m�ǽW�/=�-�K�}P5Nd���؎g:�늆��/�D���K�����<u a���������3/R��i�hυ����fg(�0oF+��%��D����n�H�f��s����;�**�:��-?i|��_��y��7�n��U,f��C����ݜ��<<���9n8�g(֓�SNP��&����^�ZA܏����	M���n@����{`�����/������~�E�z�VPJ�G�p��	*�.�%���e
ܬ4�L�B��rC�7D�I6f 7�N�M��hw�q��'0�a�4H1�^�O�t���;��Ea����z�Q�9��A}�>n��S��FA��7�Af������T�� ��=�TN�23����W���m�c;����L{q�=Iy����N�2���j���\-�B���tU��ɮ��Ŵp5u.�j��r�����xq��A�1���b|�y�a:�ȶ�����7#{ ��QrE���qŕ�?k#t�>��,����`[9���f�Eut��!�pQ�KKt�"$w�E��U�ڬY��v�����5B��!��0�@��ˠk%��2Z��W��&/CN�J��-�)�����:%�s���Zf�-�B��Z�e��!T���s��.�ցn�]�_���7�&��Z���d������&���|���-��G����'�����ߴ������^���³���/���>j��h׏c�z���)�L�x�*�������:�$I�j@�ʋ����oś���g["�ꤓQ�6���w��w۞]���3PP0���/Y�tz~�#�<8ğm��9��Nq%r�a��&�}�O���(�>�Z�VNYR�?a��z�����Ƒ�zNƫ���N���h�*�e����ޏ���Q?z����G��\4�CT�x��fE�P�͘6U�S��ePF���"�rp��䯗ᗐ�v�W�Xr�˰R�%�jdZyS�8�, �l�e3�d����V�����Lfu�-007�p���\���#�,��~dڌ�X7��f�P������G������>�i���l����a��JKdj��?vMV�red9�yʉ��GTB>�:�7�>B.�kA��R'���+�� ໣)�T���\{(�[l:�B����Li�V棆�ö�˦'F��~0E��8�&*j&%��@�G"Ap�k4�4��E�A �|F����ۃ#/k�ң�Q���F8)���}������?����?Z�T�/�������8'�5������}Iy��@��G�����*bp7)���1��yL�w�3ɔ��y�d���Aw2:�G�����������<�ģ�ŋ7�����5��O�����~�b/�z�.j@*M�~�M�<����`]���ɻ�5x�$�m�%]��K�&�7�EW��L�zJ�+��RNⓁ�'�,(�ʬ�kX��5h7��?�c��p<	g(Eq������6l�}8���c���-�s�#���1�P����P���[<�(�O4���y���7S�Q�� ^���Pݦ' X��BU�!j�i�~g요{���Zj��/��(Ss�p.�%�=k3�8
D��w g�!p��P���;ߣu�Goݡ@f�j�j֏{�v)��(��>9{̜e����m�_>����Y>(͑�x�����v�>�E���TG�[�y�t�I�"��S�5�o>$���g��]�L����U�)G�
�k�=\cazh?�9�	�� �:��6 l�/�:��f!�e���D��H~�do���8�]@�K�v�[�ƛ!W�x�_i�Ÿ;��ݵԷ������iF�k4��������ï�g�x���wV��P�?�ϓ�ג+�Jp��"S�Ç���!���u�7��8�����3Ԍ�F�����R<�/(��\���-j!d��^L�H5L�jfi��'ҜZ�fT�x-wN�e���U�1�H
(� 7ԯ囕�.C�i���ܥ�3� %����@U�2n��+�9!,����� Y��l�i
��3	eF�"���q��qHu�ECS�Xhl�(��0��������R��r�j�ȷԻ7]��[l6M�f��,$em�J���x�N�=�*Z[l?Vz�Y���f�H�R���R:�&ʌ)�X��rm�Qg��RY�dv���+��{�����|sE��tKU�<]7���*黡PY#'���?9H��Dhe�Ϥ�J�;<̑�kO�����������Lh�Q�î���aL�jQR�����/%�-Q��7��n�<�G���
��1P�$5X�����z6�]_i݇4q�Bt+$ih��UH�L����.ϝ@�<��\��^K���V7����38�͸v����o���_�e��U�y-xA������$�j����Oԏ&׬���j�Ψ9gXg�:�����/���K�AFa~���w�{&�M<�YkT�Hp؊Pc�*ןz�+�*�v�H���uwmr�[�6B*���S��w��	�vd}QD�C���Gx�p=��.����r;I�1�����&A|��M"�GQDc)��M̽;YN�-=���!C�ȎK�7	�E��@jU/�^06�f�n�� t��F�+��R���/00�Ze��F]�C��TH�@
�{jG���,uJ���E���r����������s�����?��������/����D� h 