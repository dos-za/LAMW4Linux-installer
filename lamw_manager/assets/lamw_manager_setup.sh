#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2626248635"
MD5="3486e6a54d9680f221543faf9d811961"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26580"
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
	echo Date of packaging: Sun Feb 13 02:15:34 -03 2022
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D�������C�g�'���38��k���Z�r�7f�8�I����	�����Bb ���.N�s�O�^�������j>�h_�%F�=^@��M��˘֎OK�Q�=O���!��E+���s;��g��٨�!�!��m������v!��"G)��iac\>ߑ�@�J�ͼ��AA7�vN'&ro�|s���q�GL�5����M.�s�?#nq'���q��us9Q��֜��n0&��e�(�>��H�$/[M؋�3��(wM'�&���]Y4A�7���9QyT_8����QQ��E͔@�"mmʉcqn9.|��(�y���\�ji^�7Hçu�,f��A"�~Wҏg��pOm�m��l����Z��K�cYWi�_�:.5
Q�<O٫��ݔ.��0�������pz�>dij��'����b=���+��W���\=�7UU}⁗Kr2�/C������`��c�S	Y�u� ����+�1M�ş���ȥ��7���T��7��6��sT�f%��@�����߹��>��o��X_�5z:VB�8<��a<��gV0((p��ź���H<��9�7sz�����.�F��D?ݎ��~;U5F�"p�{��;���5st)��AJ�C`yd���M׵Y}����Fk6�Ç8UN	�)�ǪG{�����R5���0ы�vi��t�dl�ĽJ-�Xxl=�� �x���m��.�7
��-;����j L}T�f��B/�'MuH>������n-#X=:�
I����Կ�2�2�ik��5]_+��y���ж��:}e�肈Q������}k9%i+�poyo������Y�N�v�gW�E_�anͪB�����F�(���a�K���d�򋝁��C�!�Q����9��<����e3�l&��Ö��s��wH�Vcb�b�9	�۞Y�zM����T����)X�������[�;�sKȔ�����c�BKń�5�4H����V��j�+`٥V�9P�
cg��U�����ɓ�z�+�u�+��K�Q�4�jz��S��n	���ݚ����p��&8��:�/���,Τ|�Vɘ����"Xv+4zMd.=�> �K���
�n���B�#���]	A�񀜆��++@dw�%�F6d��Z:?�����靆R"��	�{V� ���;8Dw���*3�z�����?���#�]sOW����o�7'ʣ-�7�?g�,����L����8��!Ub4=���l�I<$bg@9��3�ȒDM�/8348�|�h����k�r�d	��t�Юr��g�+H 8yQ|�ے"[�Qx����;Pn�vqfЋ�UW���c( ,S[�ziU�I�*��'�,'w���9�����#�����@s����;��D��������ضi�l��=�W��(5����3Lf�Y��S�9�3�拱��:��t���{B65|���^��Cp�͊� �0NC��+Y�O.Ӝ�\"/v���y�ki�:���YL~9�D	�99�|�D�t���=z���k�-��4]6�QmCq�.��Gp�d0�x�T*@�_*����S⨠r&�
�~�*:}{��G�z~��ay�wٱ�Ѵ���H;�8���rSh���M2)�E��8=��Z+Z'��*1��P0}���h�hZ�gA(-r��l����B��
[��W%}U�@͍M�7�ez�O}�'������#J�V��:�!�'�5؎W�"��͢L7��q��/8%
�u�l�Oz�$�9��9��M!����Z�&��8�e'i�,�k��;r�����,���7%��%\<�X��o�
��V���l1x[�v<�R��J7��)����ӯ	߫�%����H�Y�Z�G�d?O��^�W��j���9f��y޵�5�$K\��G��LY��Y=6���J��Y�O���~S�n��I�Ξ�H+D�5���_�{�Z(!�>6D�&9B�$��֩�hҝ������K����F�U��<���wueW���x�H�o�a�tb"R���sR�$Un���2m� Y��22N�^҇����s��N+x�
�D-��8B���@r�����(��f�YƑC�b,WX}�����Ϊ�8��-	歍��L|EbH�9�CO���mŮ��dD�d��,fh���K6"ID7��2�Aie�@q��#u��|6m��.�Z���5Y����`��e�dJX�b�O^.ʇ��ϰ?)w#���؈V?�4�)�p�|�j�=��W�F�ZDN�����?��XW`t�F;����ڑ9��80ѥy�+O�À<0�7h��N�l�3��,Yd�#�񓚔��e�N3 �5�yl�|���-@ǁ{���������V�ia�6���SV�ظ���3Kz�(�,��q���������E�n��N�/({fM�n���Ԝ��Wj
��5��W;�Z�:4F�r[@�|����=��%�FQ��t�)W5�W��ST���i� �>V㐑��:k1]Aus�M�T߰5��n{�F��D���(�/��r����*:>\,�Sʂ/]n\��/UbBN�B��c>�_�����o�r���T�o�C������o�$��h�3��d��e	i�^q~���B<��� ���ͱ�y�����DUG��ڠ�����s�>�<��dӓ�]�$c8₯���u���7@��� E���p����{�}C]�I��L_��ԭ=iՄe�k�0-ߦ-#��Zna�.�� ~X�K�ف�w�����}�}�j��O�u���1��`��=\x�ď�F�ֿ�pn�r{�ه@��ӫG��^UظY�ϳ�٦R�7��7�33F�?��V���ܮ���L�8=��,yǣK��+?�l�U�M-Cu�6ӆ��<�Za<�0��=gR��vN�8���&,nNt�&<𲾐
}�������ja�	��
aT�y�ܷ�+���s��>qT́RhH7S�r���0�	)�Se!"��G���h����}J�Ymi����t?�cw�b,",�s�q��}�<�oE	l�濅�5�y㶪�Q�����~�k�mI��MK�q��&��e��W�C�:5J�@$f�g���^��x�P��B�F������3�#�p������Z�^���xwXM�>�}����Q�E��s���UZ'��P�L�GM�3�+.��P<��j��)h��ǲ")�k �����T���0�Y���F�ʇ��*��=�Z�w���_�ֺP'�d1a-�����!"N/L�h��4�c/���=!$��$����߹�苴����Zd��տp|��x�����a||6Q�vowi����}�k�*i$��/Z�.w9Ȁ��"��RW���0����bN0���.�v�s���|C�^ф!�#��E�>ڇ�,��)�Ž�Vfʦ��s�u�v�IGսŰ�� n��V��^	�w�cu�o�9Iw�[�/ �U����c_˧ܐ�8YT^��ee �Y���'�zt(M+l�}g�m{!��(�'������G�����[��WF�Ht�h��&����4���W���N�T�2��'�(}Ā׻�_�c]�.s�w�:T��P@�����Q:�p�wѢ"#���^���Rܓ���Q� x˂���b�hq8d:_�?)�D<�n�=��E>>�pX��V��s񨫋uЕߥ���N�iA�x�M�@RTGDPΓ6�t�����rA�rC�K��G�����ָ;ۘ���h�!,#CV�x&�-��'c1K�D_ñ9>�t�<U�!��Ԁ�=�7q?>��m>���	$;L��Doc=Âu% �\D ��aPb�eAu9��g��̩�	�̰����n���R��7�7�̫%CB���jĸr����3�cԮ�I��1a��J�ɽ�9�8\h�Re�@�Il�cKh6����O<X��@-��6��63=lP��)��\�f��U�e�1�D$�C�ح�Ψo�5eS�H���ӀZZ��Pj��UO���Ƈ�&5��{8U�Ӥ����|�Aj�����l��0%����r�F��C��NBH���3���P0f�c,��3�k�tG��,�D�x;���=�J�h�N2�O+�2��/ٙ[hy$ބ|�H���'-�9"���5�c��$~���k�ї�H��
���1}a�.��PF�'Fd�<VޖMo�,Nq�m����!�N�L���O�}؜fQO|��m��.�@x���Koj���Xn�O�����P�$j�V��� ��_9����
��S�@B���w�}����W�ޝX���8��Z�l�%�5������z:!�z?J�N���.&�������j�������n[�{Y?!��5��ख़__�\rK*%�%):��j��Z ���3%�j�3��r� �:�"��\�F~�Y&K{���_.�:,�6Տ��0�.�*��;��VA��UX	NzP���\�����S����p: �pK���o�%ቶ_'J�\W���6�e zd�aA�'�)���<���jC���@K:D��e����q����۪��t�Ԑz��������2<:1G2�e/��cٷ�G����{>�h��od�
���*$
e��Z���.;FR�R�w�OW-w��m��8G��ɓT�}� X�	!q�����l�5X�9ԋ"+~��1�:�>����1m���ڪىΑ��|U����k��t;-KL��F*�6����Sɢ�S�q��d*�m�ZqF�'!�ZE籶�x t��1���'4)f䩵�}������2m/CQ4;f:yk�F��}m�� f_	T/�ҫg�Ƴ�3G3eȦ"j��gxd1	�r��dkc�#��8��`�Ĕ���<3�zV�.�C��x��~u����L�e�o�h;Z�T^���nZ��)
O/f;"љ���eId=��j��;�$̓хU���?�dpa[A#X�!�1���]E˗��aW�����vC+WKR7m�K���o
��b`iKUTn�o�n(����z^v����=6.�;~s��՗�}���V��.N��z.�ǺC߶�QZ���@h�ުI[��C젲�6�ȯ8{92�rM�����'&�|*$`�|j��g��2��,�C�� *������A�
�uI���
.cn���̑��R���72v�&Q�����&*�\����/b�>�SH��znMl�G/��x�v�ye6�ktI�џ����Le��s�u�?[ �q��l	BcY3;mb��yZ%"����p�,�����_�։~�P<,�˼�	�t��� �[�����u�2���1�Q����2���|諧����sU�.·�{;�N�� 4�����'�E�p���v��f�-�%���s�.��*�7m��s��!{�i���\�J�U����M0Դ,�R|�E�,җնL ��Qhoi�vh��* Ba'��i�1�c�9��,�s� JY�rP-���<&}��&�-8��h(U�:��-�J6Ae��Þ~H�:=�����U�>�)6@�v]j��o[ئ�韼L�K��T����2��R�G��L�9�hX��h.0����Щ(��}��On�4p:yNI��Z����<®�{ �R��b��,���!���P�.$�m�]wPX����鍡��#ń���CL�"��$� ~�=��UkdF�L����qU��E��D�d���N���ڮ��э��W�	}�6�nݸ(؂�O��r��P��Ӫ��?2|�q�hX�%a�oE:��z]X�����	��]_f�k�rK�i��iI�L)-��K�F�*�q�T�-6l�B���r����X>��`MyA��N?3Q��h���ֲ��6YX���q�L����͔��D�,\F��[�ˋ��r���Ë�Q'����^'y�ڤ%CuK�F�����L��joO�aS��*�ۃ��_"G	��	͇���̓"�D�w�A���d�	T�,ue65�yi�L�Vz��5~/׃)�&q���B�mz��Cl����g}�����0b*�՗��}�<)h!9aLO��i�j`��6uKy�H�_-�������_��n�[�M���a���R�e"�Q�$��c�85=
�5�C�H���[D�.�(����X�-N��i��/�؀�peT	_;�1��j��0p��d�x*z4��&K�FX�F�WY41�˄�0�N*���Ijk ��)�87 p]A9s6c7�?D�S{�Db$T���v��%��Rz]���'8�*�>�c>q��]�����}��� ;@v�&4,{��]������-D|����Pf%��gwef�)�� �l��jC���|U��,r
i��}�Y"{T���+�p)����wѴ�����0ŭ�hE�����{#΋��?Kdl��g'�G��Jb���D}Vn%��P�d�I���^LкBz�N�sͦ��ݗ8�8�8}��z5N�6��ӉqS�W
r�Ӡ'']��L�j5��ԴS����x�mݞd���f�$�ҋ���%�Ms�|yr��2��-�zS)ʎ���҉�����P��b:����δ~(�.ߒ/��׬66_�^2� P	GIS�R1R[�;1)�u��/��|���-�U ��F�����K�����øZv�xQZL�Q5�su�x��[�� �����b�$?�<|���)�j����5z����+����D�<�^��<Sٝ���w�V���.FP(����p꒟f������F#4��<mx��������(��d|�G;y�mb�Q��pȷjC1s��%f�fG1ߥ�8�����7/�t�A�BY��KP����u�����i��6���$j�+�R:� ���X���Ρ����湰��l��2g���#���q�3왾�lw��3cD��'����
s2��Q�M{�G��3�$Jp&�8ZʁfYyv��h/I�Φ�⸀��*~��B�ׂ*�y;Jvk`e��>���`���b������ˁt
!�_t��i���A���#�h:�Cc��RB[��*#�c�2Шk0�����]T�X��E��|�=��l�부>�R��M���'��З��~����ʤ?Th����
�(_<T�J�KL�c]�PG��~b���>�Q#H��� �-��N(��,�?�/�Auc���dA�8!����u
 ���Ȱ�0��܊=��ǧ�u?�i���&zF�O�H �I�����w�R��6	�C�Pq]ǵ�����?r:�G���n]����u�B�+�(���\)/6�u�,-�w�i;�&������X�'��̜�	��R�"���xp�C JZ��4X`��{B�G���|�b}TBN�&r�?L�Q�G� S��k��Z�m���r��YO��b��AetH/��ElUS<��=��(@�[���������۷k�􅖜T�m#�H�"�!�E����re��v�� ��=�l�E�Q^Ŝ�������l��:�r;B�i����ν�d�t�?�gbz %w؋��%�?9>N �d薽8JxbG���!�8���Ú�:P,,�{I�l#[T�?�yX8H0;e ���)Ā��9�
��xA�G��L��w�5$�ԫ
����'{�su*���n�/�d�aY��K���Ne��b�l;���o�Mq�a�Y��	�:7櫪z�e��GA�ȴp�I�u)Z�GRQ8EBC��dL�״�2<+�������|&�>^v�����ӱ������E��\_��Z/�f�_�+�_�]E+�w�Q�Eر�
�7<��Qg���fD^��&� bYp,t7z���1�FµQjo�ۃ�$�:G��+����ZJv �j�\R=�w����CL���f"��$�{�3_޹cɒ3R���<t��C�����oIw�j��9Xcv�JIN1�7<=t.k�R����Q�4Qrˌ��g|&�!װdA��14����y��g�?z'��s�iU��/Is���L�[�	pX�X�	ǹ#`���u8�pi�9�������N����&v`��l�
k�T���V>�ӫ��E�w�+μ�gO��@�u=�CvYކ_��\���^�����u�d��
HO?�f�a��(|	��pl�E^4����c':��i4]{ �g��g���g�	�|:8���}^��ŵ�ʌ�hk8�6�VM��������}R���$�e�l-��o���|�~�4�SI�C	��KD��گ"@˺c���,��.Bz�Ua�u�|S�m�U�M��ןYew'�)��ܰ�E��%G�2�������X�?n��k(��=�>��]�k�cIU���O�� �n����_׮��/[�.�^��QrWH��/CO���9n�#,V팙ҋ�E��J�Nthɩ��A�>�I:A�:Y���h��]Tr�jNn:J�'
?	T{��A@�%�ײ�nu��s5{���y���M��Gv���F�/4��U�\]��E�,�!s�&Jjs���ʂ�Q3��lKX��{����@���(���uMn�b$�I�jlB@֕��<r��'��)��K�+�X�Y�7�T�����4@��+-#.�=d� ϛ�ܚ�{$�oܖ!�8��P���"qΕe�Ms��7���i��^���D�7Zg ��َ�z16��n⤦T]�N�kД�u��������O<���*L�6#���l�$^\7(G��h�r4C+A���R$�]�$I�N�fb����qv6�9�� �Px԰4	d#���y�w��7�*~�9��h7h, �h����m�e�u�p�pf���/����H��:�T߰�h�8����/�S��v�aq��? ��z��>��{랐�UY��O���%�0E�~�{,{���[A��O�<`��֫=p�O�=R��PL�xz���� Ǜ�	)���_-.|RX,M�[ֆpy��5:�@t�MFZ. ���1���v��z���?߅���eƀ[���l�1�I&���*'��U����Q�D����Eފ���ʀ�_�.�GJ��P�%�L���W+�)�Se���y����$���/%��=���O�K-%@[�z�R�57��4��"
��*�g���z~�u�$�c�����CpP����YQJ��uX�=�zYz���@e��[�;�f+)���Q?�u��j�t��^�u�Πr>/�u.�>C��Krz�Z���(���MǏ;���/2β������gRs��3�@Q�Dj�n��J��'p��sZ`̕!)}�^��!���}����*�wW{��h� ��\-��?"��%{�%��e�K���7��5ƻ��~S�4��`Ь���91�U�F��X�03��fn�3��+�UZm��>k�D���%�5tC}� I[�2�s�<ʉ���*�<9(
��S�c����g=�#.`g����(��Gn�����]e�(Dl<v`�ݍ�'��hd9lJ{U0ʱ�dO���æL��9����eW�?b!p�<L�~'���ו*E`���v�y����0��#l���k��1;��ׯO,��4�[��(4�=]��/	���h0�V/6s�b�1��ߔǶ��*Z�'�{����>�e6�Mg&.dH���\��lf��e�P�c�ي��D��V �肘�z�#V���_+�ci:�L��W%���Ł��Rm9�@��|�E5���-z�yM���i��$Q]��2{jn���$��:�D ��Fo�]$2�k~]Y*�y�%�<�.i M��t�2�'���"���9l��h��{f�?�w�`/Zr����XT�x]������pR�ÏY`�]��ͯ�h����H0���f��P�vf����m�[׹D���w��M)���@�J&��>�z$g&��^l�ERu4�B��1	W�|u��	AU�tN����F�/����l���:5�J�=�f�XH�။(���te��N�L�p��e�?ZJ�ֵ�RR.�v/��Z<"s�pT0���_cUR�+��7BCЃ���L��'g�d����&����	A�X�Rw�����"?eLb�
���q�0�B yr��.���qU�k��r��VVH-	G��)���_�7��i�ð�?�)�j	41��?�M�G,�˹NT��d�Y�o��/Tcu�>����|�Ec���ȿ��Fo��2K�d��i����Zf*��#u(��k����z떪>pK}���$R�v�Z�.EBL�uH��c��R��4����a8T�e��9B
�Cۯ�1T�t��4�+_��H�Q<�����9��T�>,X�f���mN�Y(�
-G��w�z)P��8�lX<k[̲Aq��;٤N?P��͉���W��O	n�g'���I���5�o��2z�^�8#�0+�#o��j6ыa�;N�����`�.
#eUe����
B��A�ջ��dY���P��ǘ�'a⤞��O?�;'���O֣	�_�f�c��B��\�C ��ܣ���dm� �#��}Es1��P�2��:z�@��b0�\z|T|S��;��dnmٻG�Ě��Π����	�|�'�'(�Q�Xs�S;��4$�����e�����%�j����	� %ˑQ��nN�4�F��6 u�zaz�S����Iú/$P-��ץр#�?�q��y�h%����֓;���/p1j՟���1��'�r4U+E�������3�>m�+�-�#&U��p��Qߣ��J_�{|Z���6�4lT�YWw�����
�G�-3B^*e�ܝ�8t���"%)��Lv���9�Z��uS�Q�~BU�"?/��w+�@AaشXJZ���5�
+ƚ+�1�PY���+�4=���Qk"�2�eM�65�7.*��\C��t
�m�k	�b�p�g*\	r<�f�ЯΕȟ�v�l��`{E�*�F=6��y�Y�La1�I�_hG�'���4���1�����tX���Y��y���"%Bui%��eY���T4G��LM�F]�WD����H�A卫2^X�\p��F>_���PH8��5��)�g�-���:����E ����x����(n L��������u�AA�(��-�}�*9���v�!����ğ%W���m�I�� لu.���|�7F��X�o��m턙S�A��S�P��7��
.���K�ߍ�О��D=�B�RNz6������C�����(]���St�DQ<��e�N��?�t�')��Q�G�w�����o[��DO]�/)����NK�#ol����U�j���S�	@s��*ąJ��
�����$�R�)�YJ�w|]L�+�O=�����@q"-X�2�]����2T`�%A<���Iv�G2���W�x���YW�Ɉs��b��{�<���j�«�<���Qg�0Nh#��f|��L�g�ѵ��j�	�7'[�b�֕�5ݍ�م�ɓy�Ke罺�|��� -�i6k�:_�o��Kd�m�\�H/���Z�ЦL#�h.�.١���{-�"^N�$t��+��74:���#�L�l(CrTJ�|G=0	e�!n���":}:!:�sG��g���h�z*!	��E��I"�Z�E�z6U��MG����jH	�Z��]� �$b���r�:>g����*��[\���Ʉ�0�D�i�3�:E|
:{�D����N��Lp($��~�Sp�R0�q�p�6�W�!B�Ҡ�2�Q�+�8|�F4�&&g��d+Z�0�n)��7I���i���V]�%l�ޥ\���&Z�<T*�>�0K�9R&ƹ�X�[��SI^t;z�V���~x�R������`20b� ����%',�m�>���t�s4�98WG�Ҁ^m@��\�d��D��4%�u�wo�I��lw�1;�I�(cS�����n���ktW0w�Y�u皬��� B}PX��Z���aLWN�.X����^t�`�]'N3p"m&�����kߕb:��ۋ�6�A���ot;[/x�0H�w��Ch�ܪ"�=��7O�Ciwcl~��禪�$��I��-�����au�le���K��R��n�_��d)?%�X�g�P��Ħ!��>�#�\¾C����
��Q�����2;���?������B�o!t�ڑ�z��$k,�)W�3r	�\�b�����!�+��:ޅh3����1�$�vq ��>��,�cF��0 �S���<	l�?��V�a�[+I�;(�M�^@�'��E�����=:^�5�ds�#0����u���S��������-�Y�%D�"a�5�"0�+N"&�����?b�w��sw�� �Z�`M2�f��}��-�ٸd� �c*R�js�~��hf:����m� ��1hу״J	�����S��D��J1zM_�:".�|�y�0X��5���ޗLU�s
�iI�)f��ረ�t�4�nn�\���ȁ>'���uo�.5y�/��$���.ç�K%I�yn��Ī�O��&�W�F�f~�踱�qt/M��y{ֹ�t-@e�����6&�c:���{�p���Ǥ;Q����IX�[�{�N#A���b��3;��Y"'��K�#*��<7R��ϧxA?�ORbڋ�uG��t��g ɘ3>p<����-��g %W}mF5zu��)��A�g��z�	*u�PȔ��Y}�	a;����� Z'w��¨����a����24���"�Nêlϕy��G�ܙ���Œ�7���	�Շ�<tȞ�G��0��;����.���B~�B�x�,ā�� ��˙x��4A�)�� �퓫YCy�V.{S+��/{����Iih���޼��z��]]׋�ͯ	��
h�bO3��e�>�L�x�p*tF�YXKL2��Ţ�����-I ��<���v��pH�=�'�)@� ����[��n�(H[���t����>��}z�9�u(Q˽;�8({��w`�C��]�_L�PW0��k�e���8�&d�ē]�����J�aj���hv����7&�y�r"۹���X�*Vѵ��"Z�6��>"�9R�jwa����)�,"2)~^/�p��|V���n���댝.ݥ��񯆵Σ�$���t���]c~ӻhIsN���[��FV�@B.!d73������sݺ�u&W:�*�dt�ۺ��hn{��U	�H�W_I�&[V�/�r(s��堼��.�֮h-5�SqFy`��l^Z���υ67D�v̋9����/�|R�R�_*@/����Ό\I���3P{��#Q�<��[dW�Ʋͳ���ϩ���]�~L���@n?�Hg��TO�L�۩3��u�ڏv��Sf��� {��P ru��uC��5P~�<N��]��DW`�>�Y�D'��%����w��8�N���fE3k��<�ݼ����qt^j��5e���
�%O��/�f������~�M����Cl*%��\w��GJI���KB�-r���;����G�[.�;+�]� �U����٤�T�jQ�9&�"�U0m�?�w��iaG���a��5d=Z�н�A� �O��2�=�i(k��(\X�<*L�O�Tq�>�<6�t��֛]V�^t��ŉ*��G�{h�9N���'G�g�<�4�ׅ�hE���s��R�Rs ,����0&�-�ͣcak^Z`��H�������Ԩ�
���Eu�{C�M����" y�?�6��e��)v~�`��70�9�$F�|��;g������2YͿa!]^�4�#1��8��јi���y<��VjkD�v��n��1��Y�E�<��O�DTɘ��ƶ�,wC��4�'�P�5��n�iM�j��yG�h��h:/pm�D�eUh`e��]���`Қ�������|Mf+Y&2�N/����7:���4(4:�	�ڏ����<S���S����5uVso���^$bK��H�k�*M^�TgP	����$�y]�>U:NE{*L�YU�3����[�ZP
C������21r��Z龬�Q4Eb�aR��"m�\���[.j��c��	�,Li��)�d�M�Ѥ�R���]�?�]���� ��lq�ۤ)E�K����p��z�+����pFyu�8|̣D'����A�H�����K^���º��Fl�6Q��W��s��1�ʡ��r H�A~�$ /v�s&u�R'ݴ~tl��Ψ�;�MB�����=�f�o� ��b�T�(�,���6>�Dbv۩�ÏkV��a�z�V
�(��rc��WK5'�p�\�9��M~[� ~�-���T�n(����uq�`�/�B�ӌ���oe��)��%tt���*x.{ʦ0�j7 #�+�`^�ћ��b�"��^�Q��wz��Z���hn��a�Cȱ^����>u��XZ�."�5�/	�Q`���\�uHN6�fO�Q�cu{^�!��=h���Z�L�r��U\X��F�R��ʦu�� ���E%��@U�ީ�͈[�qJ��"�B��Pc��#�%$�g�$+āj_.�gj�]���"Ģ�W�|.�#��L�k�"�a"��'�nR���(�H�g�&`SÙ]_�"pL���5�	2�d=`���IK(:����]��oi��L�ؼ����v��w�os���{	�l�dFj�R(QxX��A�M������N7���x"�g3�`�H�
d��v�j,AO�#���Cn)�Ph?�`K�|�
�U�J���e�vǅ�	�#�x��=+��P�:4��j(5)jV(�󠢾�dWi�����7)YZ���أ_�4��	 -��L5�NQ<ppI�p�bhW��B���y�uAL���F]r����B�je���!:9z��{ǎ��"�.��@b�U���D�n>��CT:�'n���\�wv�p�E�NF<�OSJ�#���e����6��ȋ�rp�Õm�Rm�D��PU@TbD�X�?����|+z��̍:�����e4�W��&CIA"�u$�����>k��8F�M�M�G���i!��$�n�L�%�֫Bަ�/v�(F#��@�R�xEzy>������n�|�@Ð��y�}I��.g�T��h��ǽMw�BM%	�Y��v��%�,%M��[�������h�f�e$_�>��P�!A�����X�y��'�27��fZl��A;���+�����5#$fv�G�#�^J3ex��le"�_nމ5tc5X+��j�������#��ǡ��="�h8�l���L�����k�k��r��[��]��ULӵے(V�2^s)چ"�Қ5�E�����Z�$t$�ӼU�9����r���hgT�PcQ��P��*��H<�Y�H�Ih����`)���_O�]^���8�ޭ�	�y���O��3Rv�pT�����J��Ya:��(��&g��D����p\/���Fo��x�+OY>���dw����U�݉5*�_.a>�@ B7;n̜� (�sA�Q������ m.-8#QA"*+�����MH��q��ɧ�^5�o#86{JhW5&�Y *Z��Zj��"{x�pH76Mm{��<�z{M׃�|�5U�����h���WAi?��W��+t
1�g�2�AYK�O�d��4�������DL\��I��	c��Dmj�Ф?���f�)<�v`���O6I��7FyW�&��M�{�8�\w;"_dT�)�M�(��V�CDD(ћ����;�I4����0,\Mćb������GR�ϸ�A�ؒ�,��!fX�9���Lz�#��4� �|d�]:�XZ~^Y�B.����{Ds������{i�%�w�`v;�yC��n���)�{_=��E�<qY���C'��ƫ�����0UP�*�_�0�J�򇌜���Q���oi+�i�� *�ר �$t�J3��lh�d��vݪJd�_�8��ń�+�0Z��ȁv��Z�k��d܊n�=�VѸ}|[�����I�ؖŒm`�U�R��π�啅M�kD��Q�lĮ>����`KҬ��*i�]����R�.�d�C�u������c`���5Z'A�%1� ^;��kḭ�������H�E�]��n��ݖХ�cç��_�5t�E�bեjʱkQ_�T�KK����e�u�n|,x�.\��Y��ܚ��?�e�	���QS���uW�7+*�Q�{�Z}F6�m��f����%����?��m����R,�it��Ȕ�'Y��H��,[��������[dз]c�~��O��7L> �� ���t�WSM�>|cKp��
㢤�B�^�{M`�
<v
�׿�ˎD6�f�V�]�g7��п��?	<_���*�����Z��p������|nMJ?�5)|�-l��� ���-�g�~�7]�����~B���,\P���`�tOV1g�=5D�<̔��>ր�A{���G>q��-\�Y�&�Ph	��-]�u�S�J����)&݅�M�B�Q�0�iX*��o���)�i�?�����rX��?�U[f}I!(h��@����m�6H�����zTϠ��'ʍ�J*��!`K���������<�L	�uoXS�k�\qiG��#VyEBJ悏��W?�}MT��`�\��ŕ��Lc�=?P�د��r�VS�"x���ON�)%@�*W�Y�f	��`��j��k��E!��( �Y�(]�c5$�W��\���x��~�ʜ����u�C'_`˞R��?]��ȃHp)-�e����o�V���Q��������.k�Šr��Ls\��m��H��j�"E\������ �{1}�T�����O+�0 f��x�w���I$8%=2�e�'�r�H	�C�$�o�x^vB�0΍3�]����m" 7a���>y�J/N/dul�/��� �W��"��|^m���i����p�|a�p~���+L�`�;f�Vh~6Y
?ʬ�>;摗Z�"f6Ot��j��pM���e�����ٽ��r	#����Q�m�Ⱦ�j�w�@����9,��Cb���_�_��A�f�I���-D}K�5�*�}��C֑ GVfBX�Z��Nrr���VI��]��S6[�T�c��C���<=�fS�ܢ�G�<X}�����h��!��j.��?���)%kT�8+d?�9�Yn�`�ɏ '�!~HՊnջu�@����G"��t���e�̿�L)P����ϋ��蹦Y�34���x���8x�V8�ݳ�	kE�\�R���2��K�J���{0~�j�iT����p��^� ��U�L�,)�8�BH��^�]D������`�>�h�*�5G�YO�ţ�rH�ڳ홒�;I�����sA�XC١7�z��;�6�7��� �?�o��|����wx�Cǈt��`CN�"Z'kaGj�^����n��'�<���K��t ��dMڙ���R!�ٵT���I��͵�CLfS+��H�����������J�P��ܛ:�3e_3|�#݅��"9�]+e���,o�?&i�a��.=�BA�l��%l����\��ڋP�i��G�˞p�<k�U�E�xd�qFU�0�
�2祤]Jut�ǝ�pp��S��,���a�>�]�wo�����?��4�!H�~+ER��
�nC��J��0�M��+r̤�z.�ZpzR����|����P��OD����咴Cn,�[�3�l�@ IMMxb�!i/�z��"{6ym�v��?t��s�[=[n�ظ�T��Pk!����D��YY3�� �ӰU<Ǝ�qY����ۭ�sh���KEGY�ڍ�\��dS=9H%��I�1o�"��<���H�%�B���^��(��Өݍ�3���5xv�VŢ��
B�#��}�"�Ӆ�:�Ͻ�6��aa҃`o[�N�a�%��tb}��!oa&EJ���6�x"�9=6����.x��M�ݓv��U�:�����	4+�o���W���B��hhz�ř7yp���:,p�)��N+�7��E�O���0f�ģ��([\q2�OA~���|�L�l7��q�K;�1�%L @B���T��|۔�t򌴘��'U:k���p�A��}��ف����ryAp
*C|;=�* ��ݕ��*D�+�^h\�����n�c+�YRױ,۝$S)EP�r�H��6.\ 7� I���t�C���r��=��q0v��f�`��_��ߗ�#����I�+�|���P\�f̵H,������3�,fP�4Q����鯤�V����s���XKHv:9UO�] �����Fl�XC`����X{4m�����afKF[Jn��^3�/�i
]�T��OS�����W�
77����'f�����I�|o��9S���7�຅?���X�m-���Zc��U݊��:\:��!"?��J,k90?�;�����f7bο�T
]�%{�J�ȪC=��M�M��K
�a�(ɴ����;zĲOfß�R�0RyU�yOK�$��SK	��	4C@��6^�Ւ�loh\L�H�~;�ޟEi����Ia^�H�m����5����J�d�~&�r�Q���E�XH����*�E�qh$�BZ��
O����`F6��f�U������:�X6�#�$��l2���ZA�$�;��L��*e'��iEz��.%� �H����]�d ?�]��I�t�I*���gd�ҩIeM��e��m*��	�L�G�pP:/�+ �?�M�F����R�9@[J��obeI6�5�Z؉��� �{؈��Lv<0�5�6�1�)5=A�VB%�?��c���Q�T�)M|M�G�WSKv�3�I�C�S��8eY�ΐ0����g�5�m}+��խg~5�Kb3A��}<|E
JZ��*��u���k�tI�b:�a�`�fk�E�����?�XO���'1�F���st95�z=>�Œ�>��QMF	a&!Yu��:B֎�A�C\p�����2����s�G�Ͽ�{W�:�&��\>W�"+g�Nh8�mR�Ʀ�i��V�FU,�G6Pi A���_�z���Ne��b����=�jS<×�%j��	^��mڧ�
p���-��Z��.���%����Vx�Y�$��ЩkYg�y��������-��xH��څ���`+ <��=���IL���	��d���Q>&W�BY��n(�8r$L+�V~��h����b��N�<�bv�d7����$�ק�I~�UI�N;�'��%�]�y<ж4�����߳?�mW^��\fu�j��7��=�[�/��W'㹳���_�X�e(������Tf�[h�Qjr���X��nanަ��M,��:>!��,��������	�g�_����dk�}7xq~f̦�VSX�>�o�WM�|u�s��{��G䇫�k�2��g����ɫ�y�B��l��1��#���8��rs��F3tp	�_Yjto�ă��N
"��CwP[��:�1!����[#r��Vξ����<4�3��,�q���@�B�g�_�~���͘��p�>��FT>7�<w?��%��lo���t��J��k��g��en?��V�W�K��gtؠgx  �R	�e�o�����~5�Q�3��҅�̚u̳��(L,��Y%�3�5��T��R��k:#�Ӳ|��%zB���.̤���e��D�RCT,�_i�1w:�sV<�;B��x�=N�Z$IPL��"�Ǳ�8�Z-�T��u1�_���/�h�|vX/�Mv����1���5h9<Y�\<ZC��A�55�(��yӿvq�n������l�����=9�B:p~�*����������l@�v�ڥ��#�Yj�=*�����q��������{�^S��ƛRφߵ:3��@+�z,d�i�ĀWP������o��4Py!�L ���"��eh)��h"���ܖ�?X���ݼ1�|��Ҹ������~��z �����z����5ZMd���}	5�"���iƧ@�oB_��	���?�����D ��Ҩ��i�yw�S��S������׊ٻ����E�#����h��	E��	�/^�D����(�:]iM�1<�~?�%	Jq�I���̰����cc�'|����a����Y}$<MK{v%x�z
�sV�+��tQ��АX�+�5����Nx��u��ԙ�Zn�r�N���1[`,�zN�Kv*�ٺ���w���A�/����9m�"���]�� *m�yJ$$���ÑS�Ĳ��N�������M�`�j)M�\Pd�&�E��8U����۩������$px"��Ht�X'�{5߿}�+������|�{i��?[ٵ�~٤�`b���-���Jϳ����U��C3!�Dpgܩ����D�=%��x)'>��N����W�H�)f���{c��^�;����T��<�e��A�� \����𳰂`/A��m�$"+�t�r$��<��ftL���7Җ�}[��_�G�[�qq���HR,��R&��Ӻ"�H
���Pw4l�B���NG^����W��=O�~�C+p��Vw�Zƈ=*�E�����Nҍ�{�����tj�]A�=<�	`��Sy˵���!�F�m5�-���R�|�80���|u�B�����0�>핶�	&G����)"�R�:e_�o:MJx1�>?��Qߑ"L�?~���>�ql��k}�S���=��|�֡$0�y����Wa!���.���<�H~6Z"�w�F�g�ͩ�5��ڹ�݄� Wk����=x���B�WDVuh`
-XyY�
-!����Xw������Q��
G)��h�����ư��8K��,:�-�Bv�l���9�c6]4��*�LP��D�űLVh�fn[E�X�'��iV^D,?�A`�KM��A�/�-�i0�Z#�vV)��8:��N�Az���M��6(@du�"M�f�0��@��-)�}'��Q��s���._'�h�!R/�z-�qb��#���M���_	s4��K���տ����7��X�ux(Qꂸ/�u��-�uyq�1V;o�q3��	>�0�R�Nq��T �F����-o�$�{ַ���M�uO	}�e�l��eH� �:�=�X�"��gLa+Y��ߡ��;�X��=h�.&)I/����4�N}���Q������:R��̸�SNY[Ywp�S�=v���j9-�ſ(4�:��C�z��n'���Н8���Re��ۙ��[�ؤ#B�$l�c�!R4y~��)�,��K͞�^L1c����%�vr�����*ּ���@�$���+d�*�1�f(��8n��lf��n���=:�8���5w�x�8P	8	8���ڣ�q���%s����p�-ڛ�(b 7v�����G�4	����r�P;�>��oR:�>,}��x0W�j�&:��i��!������ܕ(/}�b�d�ɭ;�D�)�ۇ����1�*SAMVJ�Z�5/�؋Q�S�e���;��&�~	����Nw�9K$M̕?��ϊP�Nl9sD��������|-Cު���#S�Vid=9����3�ǉ��;�9v#�8U�v�^���{� ������"I�1 ؏�6*�I�>�S�6B�c	a�Qm ��W!����!�m��lTMc@�Ӊ�#YL��������E�����7,Q��O(���Zf�-D�ɔ3S�y��|MOȩ�~�'DeH�(A�+B���	��N(�½�6X�R�Y�r5�5�֎�o\��X�\դ��X 
~xT�Z?T�֔���v
����霽�FDW�U�#(�����X=�+Y��]�쑠y��Yx����U���D��x��w�x7�uK�O>M�`y�C�,\l_nX�,AP�Z���q5�����e{��P�>~���B��<��'1�6����C�ݗ�Y�n��=y8�$�c��-B���#u�K��C����3F�Z���#�U�Ȼ7]�{��'2���E;��ݭ��%\   փ�"�桼� �x�A�3p��'��Cu�T�O��Q�u8��n����5~���s��
U�����OM��uܝ/����Ť	OT�
fVa�������r�Us~14���Q���f:?@g����K��X)�_`�q�=���	�,jϬ�����@Jw��~6����-�!n�Qf0�=?S�j�F�u��o���-Q�d�����y�~S���*wN7a�7�?�ϢF���N��$Ʊ$��_��
���3X�Ds�D�@�.��A<�Cg0CM�	�T��n%j_����˳�l�.�V�*/<�v���cDv�x��ӷ/u!u�{�)�&=7,�x��M���}��K�cvng���r5��~6��k+4�k��0/c��
���r���]"���7���'��vM(�+>�I
�K�fǄ���S�� TxV��T	���v�&�>唫OL�Nl5�)O�2Po�m��t9O�yO�c��2�����[�j��"�<����<���ܔ�j��S�=k���̌O8�1��M��Ov���XYBp�z4 �?�1��fQ��j��i�@HF���9�	wO��b�F�N5���˺��T=@�$��c���� �	�#J���;(fo�%bޕR2��5��l�UA��"�p�u���f�? ��O�`�˝�m]�wP@P#&�ܝ 4����$7��	0���jUѨ���v'*�tj	C����jA�u"������Ll�c�S���(����%�x\u�;~	�B��fS�T�l��fƱ6;R>Z�_�j�)�p#kIa��\?�����y��\Õ��V�"����� ����U�����F ހ�#�hs ^X���+�`}�$Z���)�ھ�����ՙ�q{��Ӂ�#�.��O�{u���5��m��=��U�ܓ�H�~&B�x>O?\,&1���01���j*�؃��Wree���_Z`� ~�b��	��N[�)K@-�~XpϭIɺ����_n�tR�'Z���2�x
w�W%�����Fnt��φ�h6e��QgB�W�s�V�����Q��N({�Ya�MJ��l��n���[W��籝(,��6]�Uz�3ѱ�X0No�CF�X4�u4�Ю�y�^�A`5�i�4|C�SZxk?pt��4���������o��3��`�:c�.#�d��|54�Y[h�<l�U�YE��dX���ރ��(��e��<O{ ��b�'�3U��W`���a��g��$'�`�R��N��~��\9�7=�ƞeby|~�Z�����O">N�փ���7�ɊVb�h2���V�$�TП�Xr6��q0��!.h��h�C��x3ٮLq
����(�\9
1/�J���*=��\�G��Q݃����q�3�EI}4�~�Y���
2�)bcg�w��B�X1!��y�S��l������I��;��o�D�|����P�;�7�7=��F8����6:G�E��g� �: ���I� @{������g��zc����m2�PE��S��1��&���A���U�$����|�i	2��V	���꒛��{G �c�ؚ�V
��o�̮|��|Ϟ��\ַ�4���d����m��Xu�:�9�>AE~��M
�n�-}��|�|��KS����1�Eq`9�9���I��7���E"�.n��oo�il뼖G��H"�+1�B�#��j�_�fo�T���s��~d�WH��|Ip�oiU{�0��"$�����Xb�,Cط�����t������g;&�p�ï�>{��7��/,�=��e�_��/�����͎��j���F���K�i�m'�u,���3�l�D��ڢ�\��a���=bW������ţED�vM]�p2�n:݃v`���|x���5z?����WMyЫ�<w���]Ƀ�i������j�!21S�1��HV���RGW�����L�����K��X��j��]U������g@��|Nw+�|����x�;�-�"�Q	�<�"��HY^�R�*v_q���w�S��	���9�`�K;Qnۙ���a4�������ǇP%�f�Ys��
bD0�D��4�pN�]x��Mh��\�Bɟ',?ڧ���>�;���3ʗ�X5������!�64���#+���o��lV�^�̵�"3��b�=�M��� �<'Ѿ�ǰ 2�������
E�I7Ce�9�9��8 �5�'iL����=��Qo��Bl�k��1YO��}���]t�:S��t�s�T�|�a^��њ�A%� b���=J	�/�]l���qk�:��[C@X��`�L/��f	�Q�_К(�)Ÿ���=�O�����)���\W��S�������6o≊y��Y���4��q��Q</i�`�^rh�g�5�AӶ�"o�K�ĹRʯS���jݴŽC���<A�&��
�m��
^;�U�0=�
���j��d�7C�:2�����qR��-IكO�Q��v��&��i#�俤qVquJ6Z��͢�}��*���9���3����H����Ԝ��g���g�����勏.+��Ml�P�����p�"�i�5+iW�̗0j��T��j������������\�wO<�vBW$�`���������%ne��{�����A�16�������7U�p�Hn��;���PHp؂�*�;8u����C�%��8ݮ�H���5�P���M��������`yw*%����|c�˧	a�$���п8%R��i.u�9�f�%ӥj ��w����*��X�O_M�5Li�3���W�3r���81��K��`hJ�_ ��~���28s�KD�g/���JC�򄿂�vM�$��T�Y��]x8�`�b���pR��Cj���e���˸�}͠�GCO���86���=rJ&�f2kU�?
���
B�%ߔ���2;}�YY�ˎC��w1�NS{)4����+̑�ᔲ1e	�~�}fyr y��$�Э="̋ӟġx�F�,`�w��NWU����U�#H�M?�>�Oנ�����A�U�Aą���R���͏4e_�g��f,tg7�[��o��y�9i�Hv�v��!���ƃ�0M��L;e ��y���e?!i+�4�i��!߇�ֻۘ�2޾m��7)�v�em �T�_��V�$�j��P�
�i��W��11�l���C��)������qO��B�`q���Bn��-0E�����D��ӭ%�Љ��j!���x:�M��֞QU���S�J2�7��S�vR�\��B{��ifE��A~<)�.� L>�R���L�HZ����K|����|���I����>"�������ў�7�#�s���C5@y{o�A9��.�[���q�M"��t�D`����i�6�\�mamQ8s%��Z&g�Sn��U���|�\�A�M|���N�U�:��\��C�a7��@}G����@]G2�@7<մ�5�hƸ骿|�/VI��/�	K�롉 �����~,����pm� �u��	b ��	ް�pc",~>��(�o��Ν�I���q����¡.�s�ѓ�&� �ᘞ�_�n$��^w���tٽR�R�dKՕ�7��s�f�W"�ʧ��S
ZKX�QlQ��\�f�1���/��������b"��FDh���쯰��sCUm�A���i�n��`2�c4¨v7]��:�@8��H7�o5�n��+�K��_��J������!�HBh�=��Q^�H�H���O��|N��(�@]�<�����e��*�r˂O��9�O�GZdNm�z��&B��J���p-�U��a�}�M�j�������-���Bؐ��}���M��v�Eh��&\hܔĽ�b��EN9U�ɸ?�/�)B'iL�!(w�V_�E�rh���pI�2�� �&�>6�P���p�̅�[�&��[�T�h���x&c�}�u�<���`�����x*}%���t�8�lÆ7}_}�Λ��u�5ʓ�}�����Ť�G=���/u��?�q�d4��}�X�:y���F,��F�/w���_�`(�w{
�}��O�(���B�+�e�_	���b2��|�O4�(����8�I�3��O;�i�����N��Lv)sO�Z��f)ZV;m�_RE�̮Ɖb�t�V�a"R�LC^c�*tW�l���[��q�!M��ߵT��EI�N���� �_�ڒ��k+05x���%�����	@W��z�ȟ�� Z�    ʬ�G��� ���������g�    YZ