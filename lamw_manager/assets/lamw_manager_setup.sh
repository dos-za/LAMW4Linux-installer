#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1726317309"
MD5="df919110b72f0898e61dc7f8fbac2273"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20812"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Wed Mar 11 13:59:39 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���Q] �}��JF���.���_j�����I�O��"Pu��Қ^�2Vr���8JȳU��y���ج���:cB9й�t��o�c�H�bЮ���LM���>RP�A�>u0,���7C}ʡ0=<&&ɾ�j/���w^,mDAu��+����W��y��i��׽_D��"M_!zxP$$d�w��b�![�D�s ? C�2o�S?\���(���_�Q=��Ϗ$��k) ]���=y����~*w I=���kޯ�؊l
K��������ޢz�����c"9��vS�>}��۱�.�c��;�����[��CE65���V�" j�����
�K����h����
��//
�ɰQ5�u �O������Ǆϼ�"���i2��~���=jw�e��mC[K���ki%}����cK���o����5��D�͔�Ϙٓ5P�P�Sơ+%��uM�����f��ԗ*)�����3�Bw'�����DI�hn�����A��Ds�����M0WR������Tȹ��,b	M��9�F�p	�
XO�Y!�_�*��Z���Y�fqZqI���L����g�\��ox�v�Üo:���1�(�x�j�و��@���R���ċ��/& 0p�;��ͯ,?M��y6���˨�G�\�MHt�(J�]<?>�yP:�WCg���tΊe�r����K�H�(���AR� ������琶�fX���eS��+&���y"�Q	�.�$�_���|`�,����GR���kÛbՃ'a�w�`7��G64�#齀e���>�3�~q�ܵ�`�8��Kgq���@�8<Gp��������d�<��l�����mhPS�VQm69����n��d̊F�����?e�2���'�N;���32��knv�kj�����,�0I�!�IMA�na
�/OA��8F?�`����
 3��&�#�:y c!�Գ+]�e�b����c�B�ԃ�(�	<V<c�j�Jy!;Ƚ���%�8з�<�jj��3��1��hlz��O|�7�M�x#u��C=�6hk���x���Y 
�L�����\�S"�*�p�D���Zb;χ>�E�0G`ų�,_��dS��ڪ��`(�.p [��c=T�]����Tw��ԏ����J4ق�>�AѴM��C����x	J�Y^���|@T�r�/�&�p�9$o�xך@����"vhK* ��WT�\��T �n�X��ccͺ.W�GQ��{&����y��^�	&[Uf���l�ן)���?\{��"f?�~.v E�C���x��Uĥvh?�'�����U�;�D�J���i����7jT��%���&��f���}B���g�QO�,��%U�ows���a8�3Ӻ�n��s�6��Z�I�JhP~�S������]����x�d�b�k�_�R�����F��m]��q��U�,ۓ���B�V��v�3Cs�+e,.c�)k4f�n򶩒�`Z�޽�D�^��-r����d��=�_�k�-R���<�m��q�g�'�ğ��E����zV;c��D�9v���x8�=��z"%h!$T*�b��r{��Q�� n�g����3�a����2��g��%���-8�����&t��_�.��s���t;f��SǦ�QqE�Ënh����
�@�_�%놧��f;n�}
Z�j�̬�~���iW����,ö@��ͧ�# lO~��҇��_�RWt0�6[����N�e��k�~>�ё��C���fW�W��fe�vը��������,�ƨ��`�hx����R$[;�M�q6x� �cUtfS��U�5��B+ � F�L:�ES�"J��$�iv������#+Mh�pL�B�I���=ZAd<6GC��N�{����'�Y�"��k0翷P*Gle�}:i�Ɔn�{�%����?*qQ���f�Ϊ�h�C�o͌Yʶ�=t�D\��j(K�u��;]ٲ��&�w�y%��š��1d�֦�Q�
�S��Ч��s��^�*��xjp����S"�Ђ���BC�T�k�ᯃl򆯩��!��*n�T��&T���v�Y�-3}����C�灟��b`Jv~jJ���!��/��ʂ�20�)��~pT��tR��MJ����1��\��/�� c׶a�.�R�< Ҏ�&~�Z9��K4�W��!�Ւ� ��t�{ì�'�*�G^�/��nө0��}_����[Xn�R���gK2��7z�"��4�N=�L�V#��^���Q/Df�����'�l�F����So�x%��)C��2��憯��ώΦ����u-Sى�S�(0n%`�H%�L�`��L������5�Z��u�$�2�,b��S�������lÔZ�|��_1T���4��?�i��mR(WK6�C��0i���X a���㔔..x>{7ʢhiO�D����Am<�0v�w֛�h�?���q��#|�%Pj	�����eÉ�~*��[�Ņ2������wa�t�`�C��r��i���]B{���>���d*<��E�~V?�������Q���3/*�7�e���O�z�s�|@�0�Ù�X�d߶f�d%RvR �/T�+' �7���jt(Ͳ�;�Q}��߻E����}5Й�����7�J�\~!�����K`H� 5��P+A�^�2C�"��:@�^$�	D=g�>���=C�9���63����u����ۥ����D-P����n�^w솣uQ���Q��ٝ�n-�s�
�%x��5ޛ�Q�;�B�Ӹ��n��+鿐��9�j�џ�]���;��X��1�)-0��X��}=;p����m�hOm�J=�}��4����I�$A��秝��?e{����cw����>�u�X���iJ$+��"V[��4��<)�a�2�^M��o�	�+���p��j�<��+ ݴK�_9Smɏ��jI�����g[(F�/L-""��
$QW��0�X�1��u��0���lsJ��$mɿ8"-l���K6�\��vMg��������b�� F��R���p�q;�f�$�g�����z`��Tm(��0���xe޶�t�=���Z&�:˚�(�}����,�x�� ���j"9H^��u���;Rx�W���{�(m6�(�xq�}msc�(a&�5�?������i��N/�y;Z�J�s�[E%Z1R%T=��qu/��%���Q��w��l�W���sQ:�䀛S,�?����9��{*)��J?J+Xo8ﰈB4P��8ӏ��ہ���r��b�j�ݖri�(�H�x	��.����Q犤4Ɓ+l^ȋ��%S�푫p����R�v �d�\���3tvI5���5�X�/�����9�cd����'NFQ5�u3p���n�޳2��-D6/��,P>�uA����(2G?�"��`X��sD��q���+ljb��3�ϵs�}��j@�\Nm=�ȡ�y��on�5=���C�Q�тP}���7����q>1ֈJ�c:( κ"P(,���~�l�epy�s�F����-,W(�\5��GX�AN�����<��q�ms{
���F,�7��g��Y�V">H��T�$)�n���?�~���?�KE�s$���A鷂�9�$W]�8��v���g��5��L�p�����.))h��ɜ�8Fl	�����1�-��X4)��y^���ګD�����&�������b�l{����WH�YAl����!Z��|��j��򰰀u�������G(��>������R�?��}�LD.�Zx�Px��>)�nO���˅ E�$rDXǹ2!��cܽ�����Ui7�Հ��;�C��')u��e������Z�4�W��ԉ/x�M��y�S��m�Y �HT[����C<
5��
7ґ��~;�F����?��ρ�2�ܲ@���<E��4�S0
Z�%
�vm��T-�jew1p��	�AY��1�Iڳ�&�MfImJ�Y|5�����U���e�Ј����[�'�[�Z�gg�����.�K":	7:�����Y�We0�Hde�Z!Rs�h�s^�9�Zk	�%I���i�%Խ� .��H��t�B7��W		^��I�]�����U@�$������B���Y:8D��37[�n7��C#�����k
Pk�Y�ʌ��<)� �lի�9-����R��3��K� 'W�ق�25�>�8�j�/k��M�©�'VF�x�*l�.hJ~ӆ�l��[�t��:ˎP$��[@�*2-�f��M�ě�XC��l˂�´b�."����i���C�NaIG��{����ڤ��0?	�pg��c�m�F�Ĩ�ٹ^��ш6��m��������F�]���ժ� �EW}��V���Є )f,Iv=�m�N��d��	b+F?��5 u��%��%kKs��g��>���U^}�"�i�16�����C �&��n&DTӴ�)e�s�%6`2Q~	�.3�����^%�q���x�߬��M@N�V�������U�7�H,�@��ZdMr��1>��;��l��4a��j�kP��XT��8N�q�Y�b%	*Az��:i���x�c@��$� t��޵�f���%f����[�s��5W<ڒ;��ú(<�2 �,���ho�,�;0y���9�,�+1t����t��,�����N#$���A�R�F��*&��ſ')ϒ�8@�j����&R�8c�F\)*���lD#6b}{g$	���aͰ����`�S����ՠ�޼�ɺ?���d9�����?��~�?sO螴���m|���l�(;��m'|�2W�j��u�5=�(��D��r��fa�W���캝9ʅB긊��t��?W_y��T�9}c�@�vk�J�6�������Ҝ>F,���y��u�����~�C󞱨�)��c\pu����}W�6�8-��ZqP{xi�`��`��I��$h�����Ղ^Uп��>�Q�X���E�"�x�8�g�z�ęC��J�����t���_�B\'(����DmPv�� μ�I���:��U��Q��� �Ɗ����%��'E��<<��r�����{�#"����ڷB��u5�"�S��d�e�Vˣ|��nP$�����D^y�"��[T	��$T��p���~�����׳h6�/@��t	Tg ��#�7	E�T,͊0���m�윰"��X6� P%�4���!�{u��4&Ϙ��_%l�ʉP6�d��O�L���q�";�:�rL燵�\QAAk���[�ż�>�����7�4������F�xWݟ�(4-,VK�����8z}����i�KJ� Dr$A�wzo��j;�K퉨a���j#\��BZ��TG"w�]Eչ	eaA��}�9s҅�Áyw�x�6�	2����k�h۵P�@��B&Q*�?��~�I�$�S��U��'���&5�������b��-�"M�iьp�Кij=��s�IvV�4Oh;��(���{�)"=���U$�C�,���R�Ԟa��X2o�����f2�{�7��0KP�����Êl4��B����c:�S G!��E�Wwqb=⢧(0⢭M�u��V5	;��xow�� ����b�&P�������X0���C�U���I�n�%2	 ����-�5�}$
�e�������9���Tg�����ۖ��Q�|F�G����������E�:��1�:LU٢oY'�n�HǕM�0+9���f�jX��b����N�������9��N,��q�-��86�-C�H3GK�$��ɿ�����?����v�6��%\^[�̛�*b�/Qg?kk�Å�Ri(`��f�r_��ϥ�O+��L�!>i���Vȱ��G�n0AI9G٭�%��츑EIWFj��@�O�����ծC!��Т'O�P�Aƺ�����6:�������C��0�\�a�<N��ֺi�,V
:Uk'�����qa�I����iʬ')�����˴(�=������T��Ď�� ���b�A���GM%ԕ}�ڹk�R�qsذL��I����gAn=2���������9m�|k��<|���}��P�S��z4t'k֕T��#A+l�A ���W�m�ŵ�&��:H�6�,"���?
�|�2X�9�Q9^7ڥ3�1��G�:m�|e�e��*�Ir����n]�$��kg'f���O��
|�t���dɎW�P��-3�KR�f���΃T}#��/�46�/�:�D��$
�E��
Δ��|7^�y`M��5����[+B�>��s�+ض�uU��}y�:c�,�Z ��8��Q�'��H��muOaʜ9��e9����{G������t�7H ,��H/�&�>TfB^J��
�q���	�w�~Y^��k�mIc��{�(�n�@�*6�UJ�.<65ƣ:zڊG!�#�K��8-���A塕��v������a��լ��R�s�1���h<ޘ&b�()��FI��b��}>r��l0밷;6��W�����9'?��<�D��2p������Z�.�0��)d4���Z(ब���;�s��R������e�אC���Z�w�\��ȴ�8��E�^��q���^�XTS=�f��w�h!��f�iE�(�����*��т��4��t�aA�P��J݌�0Ln#j�5�E&��^ĈN�-U�S)��ˢ���`�K�ND��7�9z�����k�A�{�e�r���RC0���I�%6�3�L���hN>�H�g<���k�-*�^�E'�w	Em��pU��ip�ps��I���
�.� ���,@Ѧ�������]�z���87[�����u[}Oٺr7�6|8�������uH�$IvL�mq7�{�����TW�Է�$T����r�Zd|  ���؋8���;v�"M	�.�y�(�e�F~Gbړ��_Z(os���>��!M����^B�����9��b>[��ғ��X{*�c*K�UC�h�76@t@�i�2��y��G6��t�6�iPO�cx����]���R�~_��,Ǿ�a��34aΥ/П$?kgC�.�R��r�r\,8GF0⇫�#�7S �J����g� <�w�^�د�_+G�x��wgs*�xl��b���?L�PU.�S��u�#���6�|}����ﯭ�AZfL���B��3oѯ�|��%*e\^;Ȯ#8T���d��"�Eԇsf�ob`,`������h��c߂���Od�$��s�϶��=X2�VҔU��g"n� �2���K*
�hA|6�W���	���#�e��b���  �.J;����$�8���H�}.D�c�a�Ⱥq�E�<��#�bj�-SJ�D���S�s�"a/�<�G��y<��T�>UH2J�� ������y��~ ����k���Ȱ���	��d_�8��$�,k���
s��iz�1z�	>��-RhCnBՐ�ѺFY��P٭�N�����6�3�딭����E&0��-w�4璉��<^���Z���&��������A~gm��>�vz���R�Et�Vg�#0+����ǚ%���y'�g���+��r�nPԲ�G�*��iX��G�����իZ�d����y'�p]��?������,�{��E�G�8~;s
�TM��Z<'�e.��hc�C�.��Ȁ��Һ47䯛ss�a���s�Ij}�c�P���?���\�6'ʹp� �����O|�u�1l�r#�9���E>dF�ZN��K]J�H+�:����4Jjk$k+e�CV�ɤy������p��!�ٱ'n~O9�X��r4����	6�3Ƅ*�u�W��Q�0�r����+%�Ig'B�6�,�\��_#�eK�<���4��R�P:�,�Sy��c��A�-𳏾j���i�R�/Ro�w��U���q�9��anaaXkC�^�i1:6T��H�֬Y������������?�W'��źPf�In�����?c55Ȑ�@�K��RO���v|v��v�N u�X�D�Zu-Y�q)�ẻ/��N�h��wl4g�s)�.i�j��Fjφ�@��[Ci]�^\>����}(��f������� �fo���3���* ��x�8����ؤ/�����巟�0�����YZ��<\bɅy��j=��峇�Ϯ��%���%}bN�A
^���0��V&��M�QBړ��US.ɬ�˟Ɵ�q���;b�mq�N+Zʉ�X������·H/ˀo��
d��7�D�3��e_�mt��X%���эG�Q����)��rE}�yR�51>�[S՜{��&Eݛҿ�~ay�
�6�L	���\U�x�^kbN����c�n�D���,�Z�S)�j�?�D>�+�����[c���゗P��6�2����q�9T��&���"]Зʎd��x����;?�Uݓ��-}_Q�5p`��,�M������,o�V:
��\� �g#�Y�j���i僬2�6�bj<�Ķ�7�0o�6��v��j��zk4�����UE�0���殥8`�Yd�w=��3ƃ��$����z�K�l��r-UA��V�!;R�À���r[[��{��hv�/R'Ô3���s���х
�s��0Z�}C�Y�z�V�1�J�z��y%�G���Ɂ(��c�RX�-1�M�o}��Ե�4��J
�����8�����l� �IVkX��c��0���OT
Rt���Z�f���3hv_X;�����&�s`�f��x�>�}0N�z�j4JԾɽd)�n�#�P2X�\��Љl�k/c�q�]=(�kSc�/x��I�c��o� !�d����YTx��mP��G��XAp%=G� 0 ���6�[/:��T-�bץ�t��c�I���{����'��'͕Vx'��8���H!��#	�@�/bO��A�ey��IĐl�Ѫ 
���DF9�J�г��{J�+EE�<w0CW�zE�sī�j�b���F-G䠅����g�!���iw����{Nv#m���������"��Ү�����v'_[U��nt,����C4T���0FE��>;	g�	�9?������Rh��ډ��0o�٤RW'��Wy�����@�K�4	�������`=@�-^Y���������������ʽtv"�V��\\h�;��M>j�΅��F[���֡��X�䍾)0�|��<q��`x^_>��Ec��qC̵�Z+F�܅��Mŷ>p�UF�aC�n��ZV����@R��ݣ�܎�L�� &Ϧ�j���	ww�tH��$|�2��g�処�gu�| j�(�:g&�Q�����޾����PQ*����MO�Y�$��o1ǅ���g�)����BlJ�4SY �����̨����s/�[��?0��Z?��<?zOW�_%/�@���b>�7�*��-D5t����N�E/�z�Cک��F� �u=6WT��-��Pk�JQ '�%�8����hWb��Q����
�w;ç��ݰ�S��S��������G����$�7����J�14�)�y#�o�C���y��)<<#���C+	�)Q�~`�:bX���^'���=O� NA��z����%���(�Ո����E㫮l��ҝ��ر��	'��uP:�0��j��L��e�v�i�#��X�a̼�N�� eeG�-WG�m]�D6Fb�r�D����L��ִ��P��
3ҞU�}$jC�08��e���r��=�"P�p���)o��~�V��b琏o� ���'��Rw��A�\`�!�b�&Zܼz2ժw]V�!��jX��N�������r��aRG�'�;n�(���u�+я�HQ�7\��:p�)�6�uFՂ���z1<[VS�{�"�H����R��]|e[��\m�O��"��k l�s�����|���W��DWF��\H�l����E�O�=�g&C�?����FM�Έ`��|s,��W��yA)L��B_P��gmה2�y3.��:�8rZn�F=]���R�& ��ng��.~�1���D�����_]~�Q(QI��Z���������ʡ�˵�Dp�	�Ab��ǩ8�ԧ��?�;׿.�T��Ǵɯ�<t��\���&JT�F�7~XQf6���D�>��3��P�:��Jv��Wu:<�fq�[�U���]���9�L��UC����n*rTS)*L�n��BUYF����{��#�kf�Ou����l�6�d�C���,�>vyV6TWݥ��8KQ��#�"B�+�k��N�]}Ȼ{BͶ}u�mT���[x�p�<�(^��|�W+]�&�W"Y0�1Q��u�M	�~�lD<c7L�����(ws�Q�����:#ư��pPP�����,pi&L�MV��#AM�^3��,}�5U���ʭ��0����
�����е�$�ʱz�ԹO�9g���i�> ֧��BA�F���~��nC2����;.��w�: N�g�K�6f�w.4��3��m����[7�"v��9n�k*l4�ҪwZ�� 
ӽ�5�@�5���l�~��E�}iD�[/�g�oT� �p V�s�G3��d������
.��8��;�����B4�wHa��Py8bC��5O�*j��c-����Ir�Ⱥ�W����+&��Z�T�dG���#Y %!��V�/�Qo��f������"4�=�W%����m��qJf.��/C���)��U�Q��3i�&��zqv� 5RI�I�^Bv�ݎi6z�t�
���.1����|�����iَr��8H�F{��2F�Pl�Z�6�X�및<:��7Pe�6[ߨ�Q�n��3<^����!�Q�n�4bVLp�:��C��V������U�g
�l���G���Q�k`���m!��	�������7_�w̤+,+޽�df�j�
�ri�$�D��v�kqGiy�/� 8L��Q�i�-�<E�>`y����`M���z��� 7�r��r$l��p�z�0-Bs�{��ʆ怬DA���@�FJ�gI�.މ��R�.��U(@�+�.s�/����ߊ���)�n4���t�3S��l:�,�N�O��9��3w��0i��a~�i�X��ql��	 o°+D���8uL0L��s����J��Ǧ4-� ��0ݫ�$4�V֦��?L-d	�Vf����BtsV��Ee�M�X�GZ�?ҭ��Cb�w���Y>�UT��bZK��9��|dȌ�x�,6
��i�S&��z�*���ڱA�*��U��WB�q�Q��
}�E�Ղ@@ar�׼$�w �(�C/�$cZYX�o�X^:S��\��H�j0ﳰJlK����?8Z�_��߶e�y������|��I�=�rv3D�X%m�����y:Lg���1Z�-��"�y�)ʲ�:�
T��h*d%k����"�妳����U�a��4R�EA���	��?ut�?IR�n���0�f��c)rEYa�H��`�� �`pK����?J���Y�t!у`�U"<"�nRs���.h_$��D.UO_�ْC��� ?N�O=bv��)ƅ|�B1� �ȁ�_	����8%"=��*�	�^�G���䮖*N`+��g�K�xa���/cq%��a'C{��"���"����={�œ5���)@���+o/�͖eQL�!Ȇ���ܱ�4�Ҋ��Y�� �^R�1g�ހ�5�U��Ck�_f��&J�aqj@F���eh��%����� Y�ej=f6Q�tl�f@�c�xկx�K}����2nc�Ƶ��[~���%l�vϿX_$]X���nh%6"������u�]
4��b�ٌ�?aWPƱ��u��~���V�g��� *4&6L�[��aVeQ\R�-�l̲jg�/�JK|x-�.���70ƈԎMh���<�����g}p�lF;���i�!�e�eq��,S��I��u�'"�5�6���V��{Y�:/�8��}�Ν}�SzUH�Hݖ�h�@�d�s��l��Cdx�����<a�-�p���{�n?�W�u ��������S����ν��o�ͥ�����?&����ι��@��p�%�+��)H����Qf�[�evI�9���i�1S��.��z$��ک��"�I�iH��`7�C�ь��R���@(��Б�^!��L"��Ŏ�v^ȡ�nD^J��qqGzY�|5���9(�#_c}Ǚ?4_�&���ŭ����x��D����.�����6E>MC��C
�ƌ5�?�=/���ʐcUs���[{AJ_=��������y�dYs���B�wQ`<֦��$"L�5w��[%p��Ϙ�`�d��Ď��1����޷�5�e��&�2���+l$H� �� ��BX'���<(��B���y����Yf��C��0���,�rv`�`��,U�57ȉ� N��w�>]���t�25��eI���v���*%�cMʘrż��w?�8L���(;��bi��|�83����3}��&A
p���&��O�Klp��o̧F�x@�~]�T�x�rqCm�o�������&��v/�=����ojE:.�c��x������0��8�1��������`�B&j���#��R�g�"sv|�}�d�";2��I��^�D�IIz��ej�бIk�9V���ؕ�pd6,�s�g���cw�`ܭ{ %j�ņmO(����tmײv+�G�k�e�y��m����P�L���tl�*NK�(��MZ�ED'��j����ycF���?ԺS2�c�`Y9�~�=dWZ�KXO����1«�C���sd��ؗѿ��M�k�(~�$*�U-�'=�SJƵ;�X�~1�7T�k�-
L%�&	ۅH�S�#&<������;c8�^%������ ���;�}�=�V6?^mk�l'�]�C^��w��[3}D��n����Ĵ�7����c�&��ט?%	lA��'] K���[]xGig�k��eS�(�з'���H�z�0�"M���qgAn�4�o�1�3G	HAy���p�����eJh��"�F'=���z_I�^�5�����$�F�`/�X�h
W�0���j�n{�����o¨	Vp4b2�`��+#f]O�5!�=�	߷�hv��v�b9֤��e�7K٩&0Q� �<�%B5��ϧ�W� �n��w��xNת�f��qmB�*�8�2�Ž��;�� )q���PmU�r>�z�����D�r4d�����Ly��ݙ��<�q���8�����}pN��bs��,������
u��X��^��a%Y���{�hS\����|`
�=g�Y�ũ��j�u}�4�����<�[I�ldA7���{����2vꭄ2}�.w��r ��&Ǖ��p�"�� �����w7�D3����P1R�>T0���_�nF3�6�a4�7|i`�u�+N*VPN�A��޶H$����㑟f{RÐ�w�ೈ_iu
*���U�t -(��C�,u8���	�'��N�FV五�sofͺm"V�f�6���!�$}=��`������������� �PI�9���6�(yx�{��J��c�V�y�#q���{|�B��8�h,�Bc�����2P#!柿��5�:d"�??T�}�8�Ҳ��;��Q��T�3p�Up���N%U_����L�	j���+�L}Z3�a,7ƔH�a?["�fFuԠp�EX��h�k�f�����a���t)���V�6�3���"��a��+P�G�y�F���׉�S�� �Fi�O���{x�X"��hX�ih��ꈓ����FH'��Α� 7s�}"/�,�;�7�~3�&(�.=C�c56R����녜�̀2�$2���-��Pg{Ƴ�&�'�셵�����6��+9T��v;�P5�ť�G��{����qЙʥ@���7���Y�+W�^]�_���!:�]�T�W}�YZƞ��?ON6�Ȱ�����
M�V���R��M�^��E�:�전�]��+���=��w��U���LPNg������[h%Δm'39����S���u�I���#���F���H�9���"�rCk������H/�;$/�����eFh�7���X�Yɀʱ�����7�Ϧ0H����	i1p��Jc�0y7�g�<�����fH�q��	�J$����������M>W��_L+���� �T�@L�-:��jT�٤�k��͢���\�T6��5�JyH;Yl�Xc~���Ԩ+�4����5/��� ;J��k�%�Έ:����ٕ����Z�v`�*�\~\�:}�e�u�k�|�n�gz�Ԙ�e��R�㴶b��L�$t	��-�y��⓰J��Z\"R&D�^;oA�j5�?+E��7-����c#Q�|U��iZ�Y[�{?���<���;��qO�Z�%b�v��N?��� [���u�ٱ5�1wso��c�w���)����A��"�K�"��s��ϴb:��!�"*�Tq_F#+�Iͅ�
��Pݎ���'�~͊�⤺��������Zj@�Ьɤ\f���~�EV��Cz���1_Y ��{}��l��E�p�,	���8v����Q��%V���n|�1z�	�قH�~�*^�$��!���{�B٪��X֤��U"�_LK��v��bY���wm^�n�:�O�m�u�(Ԛ����l��/Y8�uF.U��^r�5��$�1aUk��e�� ���%\|P�v�s4U.� �q���`�XO]��:��x���9��I�e0E���4)g]��j3XE_�=(ͨ\f�>�0_����V
r�w�����{�'c����M����h�{Sۊ�P#B�>��� 1��>���\7f�H��cH4	�#U�.�p��l��4���W�iQ��q���R�&����<����
�m�<
~)T�I��*�h���G0NEVN(��٥��>U�Ā*�!�� \(���w�6�葢N����i�E��D
���2�FՖK��P��H V$H嬟f�pT�z�F;���EF�z�^�P��v���2���"�&=�bb]��w��0�ق��h����^�!0��}��4�b����F��[�wh��F�
��B9ܩ�/5�G2����W��"^�T��)�S�o�C��
N��Co��گ�/UU�����ml�a�F-�^k�cJ�'t��8���:8����Y���s�xfb)H��舟�t#��Zïh�����ɠ'�ܻ�� ��"vW�� gɺp1�j�W
�L�EO���euŮ���Mj�k~��G[*l��1��!h��}���`:�L�:�}S�~(���Z�8�S�]C�\1�i��NZ���`a�X;��~�nn ���y���M�+��enG�z:^	�&�],����e:R��׷nd�ӷf�n��;��I��Z&�%f&Cږ����"Gh	;��A���p����Q[kk����F,�V�����n�K�{���.���Seb01���Mt�Fc=�AC�c�N�~*I�����q�ȷ�~'d܈����'2����m��[SXDyA[�7/��i�#���nL����� ��gq�H����@(y� �,�u��~���Bo+V�+K_���D�O4��U�X�u��TV��5u9sZ%A	��?��i3{�=�Ó��f���Ӻp�I@4Ȫ���?Z�?S���҅�T6ѿ3N����W�
n?�N��l�S�[�4 �63���SbPF8|����Z}���{ԆVCA,��F0�̦f���spiɏV�*M&N�Q&a@]'^�}!%�e�Ѫ4%/o�Y~�;�ү2Ó�[��SC&J�̑6�|�x�9�0V�I��(�b�If�Nh^3�����D���4��N"A���%�̅�`��	�������/��$�,S��UΈe�.�(�,�?���Z���R�O�"g��0}�;%�Ɗ�H�y���2�[�2�I�g�*"A�lڍR�	&�"uʊr	��M��+v��V�4.�?f��c��H��� /w!�/v�٫QwZPKs�\"N��酁�ҁ})���~b���wjNt6Ś�.Z~�E���Z�T�5q@����e��q�Z�iw��֚e)Tfբ.i�����~�K�ΰ�����CVS2a���������
��jϾ�Oa�#��'���d���Ck��,�s��]���L5�Z,�p!��?w�[�H������Q	NV/B� �a��_l8;`𹯫vb׿����ꍗ�[Hc��Z��̽�*&�˦���^9��D,�`\a����8!-S ��ڴzu�� �>uf�w�т
���v!_���-�xV4�,G���!�����^���$Ej��ڏ��Y~�T>��-�vw1$�W���Dn0C����E�#������9�1F�HUH���9'�6b+���4Ow��"�'���8���s3�S��D�����-
x��:��<B�o�s��.0�\��C��1�j�Zn,�&��M��zn���>\x�	*/�|mX)���z[VqY�ǎ�?A����o���Wo�q8�`�^��ǈĉ�w1�I��e�b�%L<J4���J���y-b.b8f
�P�1�w9�z��������1��P���/^y6yW���w�����3��i	!��d!k�Me)���3.J��P���"�ɺb6[]�!���DY$2y쮸���RV5�gz=�fD���pr�w������`�YN�]��3�,ȉ� n0O���j���݇�*O*�E�-2(-��j�ޘ��H�}N���w�$���$�GL�V���R��z�4C��8�Fa�ˁ%ӷ	6�� �WY�x^~ET�/��ޓ�~��|�ȍ�b����Ú�<�r��������T/�O.�����2��.��D&�� ���*�O4��3��<\�$�B4d�7Js�Qt笭��6R
?^n��<n`1��f�<�2Fe`�m,<7+8!Z)�O��,�6������1̼�b�^$�7�v��u�f�`N֔
*��`o�Q]�q� �k{��7�ܐx`�V�"��Z{�a��Z�6B�s���
�������7�L\;��½h�c���S�5���R$�[��x�g�� P��%a�y%���-���o�!R*9�Fn�Z���Pӓ!��H˖��kG6~�t���Z�ƍ0�{��z$eB���KH��U�rn��9��J�8��I��-r�-���;����	&�� zfB��x��^��W�H;�l�@X��7�(t�����-��>�AQ�T��² (Z�$��L@�V�oeY
�D���e���n�ٮ*��h���G�	���n|��j�Ls
#t�xj�	~UGA�+����j�7<r	�y�|fg���S���xc�d�	��`7�z��VX�U�m�E�'�ݕ!��©�� ��=�1�>t�eNH��-T��K`FrMyq��1�uJ��q��8̦��]ȏ�a��y~�O&x�	�o��b��p�T$�=Ҡ�Yo4�]8Lc��q�1����*b�Qۊd;c����$r��G��T���
:V����ӯQgDJRܳ/�E]~�^Sea�I$�G����a�s��t���6r�o�1���'"Z'�(��?C7���կ,��^�	;��cP�L#��=��t��9�qpwѯ*n�Pv$0�c]���J,a
[�����g��0�f���梆Go�;�&k�P�\���`q�?X;mhtv[9``���QV��U2�mmD�p����i��:���]3Z�^���5߬���I�!��D����t�M�H:� l>6��Q;'@�aȇ%������l#f�:e7bɌ���r3�ت�}R����`M���C�'�EĔ4im��BJ����ŧDK�46db�}G�5!�o?{,�1|�pH���>�$�G���v�;r��U�qV������I�L�B�?�v0���ə@>��|������򀔊��T)(�5��)����U�T��krؒ�����>z�����C�w�V���Ն�#��m����np�;���;�R:w��p��=Z���.=��b� ��0���,��c��:�c�`�����JU���1�$�W6ޢ��Q6��Pv�|d?Sa�K^?N�Mg�OJ\�JV�k�-������e�!f�4N��m3�_} ��T������%�e�k��� ;�m�)wN��H59�o��-u6��Is^V����al�*	�����0BL5�7C��(�X_�tg�h��e�;��\ր���3Q�5l����o��%�_�^S�~u��\�.��X냉��Ѧ�mxQ��~���ǔ�^�j\h:�րFb��w8�� �M�R[7�i߬7��ՊxxY�7��6���g��(�5R����ct�"+�I3l�
b#����4�Q;��Ї�SuUEb����	��q� ��n��'�[�^Dut&���ѬM�R���CH���s��t�z{C�1Ζ����Z�(��Z!#U{��oD"�}�6rm5�s����o�vѕ�p�����t$rC��I���	Y�C�c�Zo�5$ANgk��ӂ9v�*4���}�$�/j�N]Q��u�a�/�~8��`c��xzz�0�z�����V�Te��n�b~�Ϝ���4oS.Yt�����*�e\\!㱜?}�4m0��Hu������2��8��Jt��NN��b��mq, �W�	ET#����&d����|r5c@�~a*:_���BV��@�#��OD�*�5���x�#��Z9�gB)�p�٪x����%��e&������t&�$�@����$U�oz��5��S�*���Ը����\��.�:��.,��Cd���CDE<��L^���bjĸ����ȑ�7;�N�� ,�3^/����Q���|z>4��v�B�>�?J��c�[PV�uG(���Nw8Bi�є��/��Ę�	��X:�b�ԗM��^	�ϯ"���4w�{a8�`-i;�J��{����a�]�a��D��X�k%��\l��J�E�W��a�d����Ե�~ ��i,e�x|��Jlp�4�$87�y&�G�Q�����C���Dt��3�.�dn�g%�[�/#��f�oۗY� ��)�|�L��4Ot#�"���k�v4���W~YAi�jl��9L�B4{ ��¤)�3��s��N�2��W��<�US¸{�rk�2	�����H���*���#w���΃&Y�
Q�#�X�b��*cQZ@
ȠG,^]�7��b�����v]� P�t�����tM~�n̱rzĄ�،�1���=��@�Wse|/��lvA��	�F�V0Sػ�k�u�]5��iv~�JC�SQ%��XG$N
%�����|���z���� ���_�Չ�u�$c�rK=��b	(�B0�'7@]�[���[5HT�C-�>��V��"_+��_��N�$�o��|?8�o
�\u�9�F�k��٭ޤ��[�﮿����]�ě���e�%/k����#B��qm�T3ߔ�h��r���$��a�r?���uӕ-��r�G�hL�#WBin��%�6z9�Ć�"�?�����K��=��5��逗{<�}�52n�5��Q[+�0T�nN.����p��5 �{r���3�OO�������`f�mT��m�9��#gR���ֽ7�Q	�d�08M.$�)�C��_�n�d��y��DQ���Z �/�*Qg�>���i�ʐ5UԌ���<�uZ,��G}��B���.s���j�7�1}֜�����2���V��ç6$�E@��O�� 	n�����n�S�����-�8p���_�*2��݉�l����(<�Gr�p8CS�A��qO����x���'�#�.�3L�ڹ1���5#	����Bz^�o�7�<MЏ\�e�+�g"�B�XXM͛����a�i�ϣ�yT�*=�"�:�S"-�����@���H���Y���1���b� �T��y�2�t��U�˗���n��8	R�;��s"�������,$�L���@��a�M=�:�����-�}:����A1_&Ԟ~v�1;2C��k��Y��d�t�i:�j�/)Q<�+A�QVb�cH��dcBn�t;>���:� ݒ�]{a}B�X�	���@N���*@��mw����7?�dio
�\���u7}��Xu��q�Ǿ��k��v�;�O`�L��h�O#iȶB,��+Ȝ�{R=�P�r�A������V�`�r3l��y�|a�#��`E!aDS��ؖ[q\<z+�fZ�ϙ��ε�嫽tu��*�/eX�5����7�J��h�q��ImK�T�G��E��D�6q91�>�jb�2�<PE�d��#�CK-.��9�.�Zf��U��%�#����+���WS��I�j��%I��eYH=�)S<Ѿ&����n��|:L�"�X�c����[4�-9��&�.��q�@�v�r����^ll{z���w�`�� �s�r	[�F�F*[�auˑ'f1�)�@�߯���v)~���!F�_�h�#)�>�� �Za_?S�$ ������"��g�    YZ