#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2788205823"
MD5="1a4fe56712cc025fe70d23233254a3b9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23628"
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
	echo Date of packaging: Thu Sep 30 22:49:57 -03 2021
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
�7zXZ  �ִF !   �X����\] �}��1Dd]����P�t�D�|�Q�tS�g���5YL,����@]��|ј��"�IF��
<"m e��?RR���wCk�s��x3������?l��и�?�D����!�ā��Ƚ�܈��5�S�ʴ���x��1���{�U�A�D�� �cr~->�8^����U�L�ٌ�����nN�]�<J����p�Xz|V�+c�Z���B���B�wM����gr�`x@���vj�mC�9>��+��A�;�yi�Ċ��D��#n�N�<���)����`�TO��>�2���/�i��� ��"��N�5�;��x	�2.�^�{?���j�.H�`XQ�Y�'�d�з��g�f� n]V��G�38�i]�P��b6E�nAJ�|���;�El��� e��kw{�YR���t�,t�x�N�z���y"��t�bjV��fkq��ũ�:��I;bӕ�!_���i����Q�+]n�&��^u�jS�@���W�.p��x�D�~`((~8�qq�w�U���oGE-�y�No� 6.����A���٪s�ț̡��"�*�-��}N��L�b���_
��߯q^�5w~�ew��|	�=m���HC�a�n��u�zpM��W��1`z�آr_TOG�V���]y*׿����c���SU��Ɔ���P���0�9��w���/�%���!))-�k\m�����9(��<�@/����$|�򥾗�	vE�aD4� ���I����q���\0Y5>`[�M}���"��"���(�������3<dokm��tt���5�|�m�k�L����RE��/����acV۽z����"��DzȆ ���^f�ґ������VqK����%�:~!�	�Ǳ[��Z�.�4�4���lK�~֖����z{����
\I�a��7e�G�r��Y 3���c�uF/�u���)���/w�<A�WZ���irBIu�~��^
Y,�-�G%���:��ϔ�]Q�*��5"<����(b>tO�.V��K�kj*�Zv���,r.D�`�jx�U���+=�Z@��ύ7.I�93��5~�7y��z�;~:���:s#�+km@-%RJ�
�̪ ���5En0(��xg����#��*/��&�b�cY%��_��j�Ũ�W�б;o��8u����_�4������t�9N�n��1و����+N3SA�:��.�X�x{�7�������P<��3��A�C��ҝ�+Pe�W"h�8�#8>�,&���pH=ZXB]�m�2z����+4�a��R#\yG������ �.�;*4~=qŇ1��d�[���E^Q�@����p.>��ۚ����ه�1���*��f�/�ߏ���1�;�ig�����mFc�_���	��y��wČ�*]z����q�D�л���."*��Á@��:�'�v�6�v�#�o��_U�̿�v�@Z	�5嫪�_!�D��a�ͮ%*��7��pV�zc2�Qp��-w �0�< ��@�<κ8ř1����u�S؇��%d����`#v��݅��D`'����l)Dl���3؋l��ҕ�������bwBq�~)�Jl�B�ܾ�&?y4��L{2�A�Tt)n�;&d}��X9�:y,����GWl"?W�3ux�g7'�ֳ3 ���A��@�^ۘ����0tğ��a�(�RKq6A��,{B��v8����������C���qǳ���о��*�W��7A����}�ޢ�����dc�&�i�Wx�Z#�����M�(Z�a��U�<s�;<���ak�ߑ^C��W�X��{e9��+հ-�i��0���G�mm:^�ؾce�a��Ѯ����؄�������gJA�,�*���f`<�!�@�	���%w�'�YN��'�Z���2��M��y�Fj���M�w>�G$U��M��ʾ���)�,�?av���6kb!P�����fy�bk���\���zx+�ߪv^T�ˣ���PZ�������V�%��bǅz�.\j�����{{͈��w'L×c��y�h;��B��B�^Z��g��sZGm���:\�� ��1�bH{�\��TY���k!�g���IwZ���M'�Jr�]6��'F[ri�����U�(�9z?S�ؿrF2����@�\<��|��ñ�p��[y,�>m�uv�6E��}_N7�K�:iC�C_Wm�����r�ט�
MV�F���=�/����|�o�i�!c	H����7��zB�5a�3�<N�ˢr�jg�q��)T��hs�얯8���N�D�*��"�`������Q3�T/ه������o$g��U�����i�y2�k6i����z����t~U���,m�e�i�$OY��}���lH�tf��0����)ޅ�G���`sV,qK��P���Ib�w��s�䏲��Y��XEX���~әڒ�Y�y�T�6:_�j�e���L8;+G6fE�.�<��7K-U�����]Vx�$N2m-s`R���@8qq Kɐ�˞�!߆��2���� *8�4�)F.��P�:��9r���O�t6�o��BmQLʄm���m�9M`@m̔a?�������zX!kk ��6��P0;W	k�����V��C;$6��#A\K��{������6*0��5����d�G�ʺ��此�lh.)YVE�Z�
��bt��{�p��A����jT�]\R2���:<���,i��?��S�Nasɱ|1L��A|�����a��7.9@_�˿;�$]���T����|�1�e����Ҳ�� ��|1��٦�}e�h�H�c����.s��`a�ɠ2R鐎��O�I�G�oDE��-9��u��1u�ɳHT��Y2$d.�)��,�P0E�����ޅ�[bjD��a���󔢙��X��O��fO�� (2^J�H���N�C��,I����e$Ks�`_:b�%F<����QL_��K��C���� l�Ă}o�#�� �M.��p�Y�7����'�R������},����&S�qXM�>��GL>@?���<�o�ph���KR*��"0Ԯ��$���N7i-v�zTs��%Շ�p��Z�F��b�%�Sd80Ԝ����6�U���=���b�Ze��4��ro��+w�Y'ݡO���1/�(��b��]$���I�r�oyBz��-Q���Q��FH,h ���A�n,T- ���kt���rLW%�Usk��iY�8^�~���=��yk�\��%.�ij-&mi�1b_J:�Q�M݉f��&x_�o�v����:)P�g�Io�WVc������<�3a�L�)	DzD�Q@+X��mX�T��R4��cs�����@1d)�ʳ���K��7äL��t���_�`�����a�t]�n@�W弦��G��H\*r\���
I��~���ʾM�͢Y��nR 0���%�Ybw�n	Ǟ��UW�
��h䐯�pY��"��d���N���n�kP�N7V
��T�SMY��Z`��,�
I!M�0vx��/���u��q<�ۍ'f���ш�!���QL����&�bn֔5����yjh���T/���0���pv��A�T�8�.�#�2��#]eU�>�AF &#N��:�l�,���	n*f�~Q��M_�
�J��Q[�F8���n{���.�7���O)�� ��6�=��3���J�>Mx��{��fI��H7"�Q��nV��@ci$ދ"R��-�m�O~�Iʸ�X��]#�kH���mx �F���\�փI嘏�.{�9�nUݹԳ�q������.��=P�
�uH�(0�n8M��-�K[MR��Y��y5�$�4��"�򡕻�����$�%⨝��۱Pfظt��y�ݬ'���Ԯ�[[!��`�����2R�_s��gz�8�J��{!;�o�/�W!Y�&�,�~3�c�h/�R�ܶ�{�E����>tj9> �����sd�W��w�㲪�#K�H"f��`��-9�8o($�OޣkES��E��C_D�X|:�8P�7`�i*���;�p���-C��mfp�٫��Px��c��㹑,&����+N9>�=��b��l����m�~*Ѩf8��ͭ��|)�M�v1Zf~������"����4S{���0~�LjI1ԍ���i?�^��3��TQ��;m���CڐM;�y��p��jy���n�������3��ӧ-��z[�,��)�xL���;��O@ރ�`��"1bAQ�p�N��Z�������d}��B Ǿ8ei��BI���V25SU�����0_�7�#@�O�È��I7
w�~l�<���~�Jtŉ�I5Wa���ЄY��*�����w�Q��H�kr'�n/���#��+F~>���R�$| �������J��	�'c:;WK����x�sh�
-����Wfoe.&^��2�\A$BpJK�C���#�+ufR�P�3�bo(�+|�LQu�	'ȸ�{9$'s�J�Q�ǧ�����.cZ�q���c�L��'�PC�%1�h�L�D�ݷ͇4�
}"�� �aT�E�""Ԟ��}�����t���6���x�ߕ*:2��˓_#��p<d�4H.lQ���Y)��æ���U�S�'+�,���NS8�)��h��Д���]ƃ��}�w��<���j�5���w��?��!��B?�����5�rT�Q������y�	_Pm.�t��E��C+[��ʵ�����)c$���g�tt8�)I�M�9��|Wٙ�=��¨�H��Z�����qL���ˌ��H�Y�z�`
[$H����rVn���0�w!q�\oA�H��k�����"=���e^F7'�(�Vw�+8�#�#��j�~n�����x�+8��Hx-�Ȫ�e�Hٴ�p�{7���W�zD�:��gԷX��iw
� &�Ѱ�R���Isj��y�ݮ��[�B�,.�Z�S.���S��D�37�x����!���脢���S�yG\�Kȱ좿�4��7}��=��]
s�BB�q!6�W�v<?rCWx�}r�]�r�!�%.�YE�7�1�������ۂ����sʠ�a�a�;��n�a�Ur"	�>u����t�$��i�9�	�2�:v[����OY��������َ��	��Y@g�c$�Q8hQ!��tE<7d������PB=�?;����r���l�m;1M�N�C�0GY�<r�����! ����/��D^P�"�(XI�0P���G�2��?�
%����b�:�-?�*��C|I*ռ� �*��v' ��ط"v�k\l #��K�?Bc���uX^�H߫� ��N��5ִ4����EDv��Rx����w�yb�k�]�1B���ӭM���u�TT�-���t�j`��҃T�y�}4 =�з����u�ҏ�%��a�r��"�@�ͤldQH�X����.L�lb��<N�dBS&F0�bvi%y�J"���YE�r��N���CM�5��)Rz�l�^�9C!Nʟ暺(pN� ��r����/���|��m���is������WMu�f<풨t>��a��N{����_����G7��3.�~_�3�%]�B�v",y�,8�����8Ng�3�-@����i��+"l���	��?|[l�CN��B?�"�Hk��0�9��o+s�ŢVj*�Ц�%C�z
p�LLn2�i�s��7XV�C�R��<�:?�0�T
���ߕ�Z��q��<�g^x���j�(��Ĵ���#i-O�k�M����D��u\S�^�0��/<�|,�'st��,8i�W �6G��JM�;Xˣ���K F��;���ք)+�A�{_o�߶�ʭ�M_è�K�ڲ\�;��oP�D4�n6�e�8S��z����V ({�|Q��@����:RZ-�-&�ԣ`ul�3J.���8��d{����p?�E���%u/�s���X�e~�s���D!��s~�`���H-'���� D�ZSؠZuඦ���E�3��n!�%~���G���#��8�����-����Ct^�<��B&b�_�o��kiC>%aj1�%�i�Ѣb�b`� ��%ey���4эN?������{�@?|E*��yZ�~BQT�;;���Q�v�j4��VyǱ��4s��T��DD?���7c>c������[MA�Q�a@�2����fD�t�aX�[�8th��(����V� �f]��ULs 2��|l)g����
��Aʕ�D�o+�`���r���2�Ul�s�d7n^ā�Ѓ����3����W~�h�X�(����e
�fQ�`����ו���f��4��j�r�r��R�������}���O������.d��
�� &J� 4ל��?
�p!�'��u{���b���ͨ��t֟�Stb��v�7��f@0t�"KK��H!"AvJW�?P�K�W��ǉ[nC�J�l�������e�e�@�$��l)�C!���r�2�D�}6��@��Ҏ�x LZC?�q��;"g��Do�ӃM�I�r�(b��t�X��
�JT���ힺ��,����}���5d�z��˲��0�&R��v蘢�2kJ�K�FZ|U��]�����K`?�APB�u�t&G��an�&�ڼ��4^�}R[ ƌg����x|����y�ۨ8�F±�hWQ?5�\�bW `�z���a�?�@��{|�;�)����ǢQ=�����<5�R'��V�e��a� uШ�:w�R�c�c�5��l"��A�J�*���-&�?o�� �{�=P�4F��23�"
�\�A�ۺ�ejD7�����	b����Ʈ`��<X[��+����Ԝ~���0`U�\�<��G}/��2����r�AA����攽k�-Eh�n)�/83�n�`om$	S�S_F\L�1�<ɍ�xj�]:�Uˡ��.�����[�o\�c�g$��WY�pߵ�,��Ew?y��|��D��b\����k���3�0�@R&���%*6=�1=�pi'ç��ꇠ)�iz͢�TIz����+�<�v�컑��&�Q�;N�]I��Gq=���$�f"��t��X��)o�p�``	k�i��v�ٱG��b�W:�J̉_qQH_!�.�����{-11�l1�ٺ��n><�_�^Ip�g�'dЧ�N��{���(��ǲr*)Ƚ�_�f�b���<g�KC�����xq�>CT���Y֧�W�7�ĝ��� t�c7��l_FFEV=\��7�^�Ȱ (SK
�2��C�`�Q&��Ol���u�ּ�-+���<r���r-2�bN��O����(�y(#���
䵣����9"#����
M��Lp`�o�,�*H{_
ױ�*SX4P�#H��|)кl2�ɁY7I�HxsĚ棐Mu����_M_���U�if���u��f�Ƶui���&����%��hh;We�6���z�l�o�-��ԭ=�����Ʈ���*qN�T�(�L�4'�,�9�
�9���Z�%�d� !d��w��k��=A���ʹbڣ$����is�Q���䝽�I�����kY6\���w���'�V<У�4���ļ �VB��D&2���k�Ć�Q]������$w����Ȩ��Z�p�4�ݥ�CY���e�ܞ�)u�FG��<�O$X*�� -Y�֘F�Y8�3H��$�)�M�:֐F4��e3T���w�gǴ%���uF��P'��A�t���\���
�5Qm@�d{@Q96K�Z�ٔ�އFǞI�w_�]�%jF/\�{	8��(4���}�j6ve�^�� \c�E�󾒳]<}�+���u¸�	oƝbf�y&J<a�rՃ�ۉ��8n�g�~C)ӹ�ٝi���,a���d�'�~��Ui�ʪ|�����Ax}N y)sV�M�9ɂ6	��	(�d�;�Y��]3�A �|���P�5��*�Z�/�)1Q��DI�\٩�-}s����c��1{Ԍ�LNL�?{���՗Է�F���
��K	��#���e�j#y���*œ��
=U���O�(��{�d��Θ��2Q\Z����SH�w�D����G�3����QW_��d)��@N�����e�@q��ǻ~d�:J�b�N	L�K�����Q�ݝ�?5�l�Ж1���,����	�����C���jĵ��@���?b��!��Za�3o�|V<��>t���N���7j�Ү��_�C�B���T���p����=�+�9�ca<����n�q��b��ñ�V�4���aKǞ��=��Yi�\֝-�*�Yu���!a>�.e��x0	A� c�q(~(�P�t:��>{���E|�f��e�������OP�Y��Z�����r7��]��V^n�E����(�#
yB�5�U/]�HY�ea͙�S�튈U�C�!�eL�������)N���i�NwïAR��(9⠴���z�e'�˨�k� �-�#�P.W��*�':�K���������'���� �H ;�k�U�Y�Y�%`���]�LP�h��
�U���_%���π���D��k�I�Қ�U�`	�?Sw�>��%��w�A��� �����_���*�
P
����#M=��3K��Ζ�V\-�^���g,��(���}K�>ۇ�X��ߑ%S#P)Z����,�\���A`h�u���@����w�29��z�&S��X��R�Q�C��56ۺc�j���
�S��䱱_�]����-�֢���D����+TW�S��A(�����ck��j���u���/�r�zˮ��s*��#K,���G�Ƥ���=F#@�@�_� �e9{���L�E�����W\2?�|2��8��m�i�n)�D�Ã�pՌS��W�Px�F����s=8����ܷ�'Gέ�:�Z��BA.[]���>lS�g8��7z8�~�h���+q��,�i-���۰{��;2	%���!���fu$pq_��G-��	�Ҭ�odx#�q:{���S�0W�5�1y��6���g]Ű�ti��I~Ū� ?�W)bff�72^ˮܛ��]�~���,�J��E�1�]w+O 0�C!��(�y��W����ծn�����:��:{��Ӝ�8�*�I�����]'�nʲ9@rs^�N�0��co�X�YRB����u� &�Nm�V{3��ȑ'7�R�O����(K�k�w�&s�+M�F�&�����g�8j�R���F{-/�n�bU��b�C�����Jm����"�����s٣��x�_@/��F��
ݘ�1ϊ��܀9��Fhw�*:�e���C���@���1CR�~[E���4JP��V���+�Y+� �'�M��%f�01w����;���D��9���q�_>��F���� ��ow��+[5"#���>-	-F�U��P��&�j!�K�u*�3�L(^���	�Z�����ɷ!��Lg��4����D�#ڥ����{��@�Γ�m���z�Ж}Jّ��:�A1v�|�"�r�*q㹜8�	��!�<��ƌ��yW=�6)E��@�a�XN���pTZ�-̡����+�9�wD��V� E�W9qbJ]4/��x��`hPB|��>i���'c2w2S)L��3�f+�@��RWVD��D�X�W1#f�@�p��^��jLo�/L*���p����
 �I(�O{���\�9�����qθ��h�TI;U�Xmz�� ��X�c<cVf&�a˽�ђ��,�ئ���1�ᠲ�������7
;�o�y��GX���dC��lҷ��<���B�S��m͙ª�Jmc��--�8����=�,�������:n����P	!
P��Y1V9���L�c5)�=����5aJ�eA���	\
g�����qjJ�,�v�p�OiC��vO�-4>"���?�OY}O��o�D%��
U���*�M_��D}�#0u�ʥ���~���}>���(!5�P���u	�R���������수�G��c�
,#���/���cwm*�C��<ڶX�s�Z?4\p4�VX0�P=�C�Q}���J�֦��@��*��X�P��{��/�,��kE��r>?�4�̎.*�+�^���:=Ѕt�Qd�5/lv�yb�X��1�J[�L�?pA��I��Â�0�Ά�:��g]��響��i�2>�W�Mz��;21r���$�Y�~�i0���i=	��6�Ճ��e-'���� ������R�.�*�� I�bzߔ���s4sKHP�+��9eI��
w�8FMe�%5�X���3���kR"P�x�8��c� WfE��/��r����Y�Y��[W}���~���a���6�8h��M I�Z���1����p���w<�)�L����7{����F�i�]�~�,qA{Rp��Ҍm�Ţ2^�J�X9)�Gg� �E[<��_�:�NV��'��Z��c����G�7�Wʼ�5��k���b&�@.+�mලy_�Axk�y����aޚ���lo[�En}�&5(�l�(�"��.<mSy��4���������SrK�~�K-:�ǼOG��j�R�2�u"���y��z��C��K����s��c�,��VY��/����T��*���i�b����F���S?*�FY"G������!`�8E�{KD�I���`D���B���N>[�ȣQűQy�8�:�x6`�2��8Ƣy��?o[�t�x<�75B� � �Ps��ko!��VҲ��QE�!�P���2V������%u�YDS�d@����Ղ�5WSI��o<��B"(�k�Q�����L��m�A��B��~��e	�ɪ��(9�p>�1~�e'����¢j���o�*@;R,���Akf5p�q�Na��F��#nkn	�ڒ���U*R�ʋ����MS�>a�=H���7���G���E�sU�Ɩ�$a���!��k\�i2)�>	�=�t����z�(<sL�
�9�	_?����;B2��}��D�C��]�%i`X��s�kH�e����)sv�� �_k��^4�$Z�~�w�Tn�Yh����w�Í�߱���#r��p!�oB���l��)���%�����CuS>���}�h�Nq�T	�A7:L-y��DR^5˽�=L�D�aˋb���()� �l��-�.�\q9N�e����_��	�,K����i%{�e��}a\\�BQ!q��Kb�ړ�A���>ZIKnsg���D�c�v�+0�Ec�FN=;wN
����E��۲g�p�3�TNo9�th�|�ۃ7�HV'�TBk���;�+/��s�gC!��Q���2n�Q�r���ן����\yw��x�f��Z�P���.*<`X-eQ�tk���C_&��^�8��>r��&h�ZD��'�S�3B�=) z"�F�����#�h���_�G;u�1��ƞ Jt�Á�xQ{R�fE��8��Eq2�!����`�52��i���Ā x]���X�h����𢨽2�D�|*RrRA�I��ݾ/ur���%�a3�+�Js \�!��+\� -�I�����S��@̈0�v
�����􅁙�6�T��}���F��d�@���Ŝf7�,��Mr{�䴧�e*�b�pP�)(&� z�5:Ƒ=/t2�K����5�1h[����@�NDdK����L����O3Y�X��X䥵1b�e�G��'�X�#g�=��H�0����:l�19)��fd����R�N�qiI�9^:0����hz��<�dN���	�(��O<Z}����A��z�Ƶ��8RvI[޻l�q�3t�C�]�@�,d*+Ud����������zV��*��!��Sk3��� 砭�D�shyT1JH���,��AS���zܧx͐��Q�j��h�Se K F1Ԛ��h@�Fxa�_�P�WrE|��8��[�7ىlK��d��>+t
Q�����q��b�_�n���ω�3��l⫱������O���b�`i��|�QC�Z�OBh�! Uqv���ޗ��(D,�����ɕ��sj�P�׵�%R)�\�8�2v)\�� �R7[��N�h
q���kd��޵.5�M�zD1��k yT� ��ݘ�)�0�'�#H:#�aJL��ͨ��SC
���y�|	�`�a'Τ��`4ܗ�Y[�'�ʱ���ʐ&�P�|�BJ�X�Ք�;*WN�p��2��<�R3��f׾���ьks6�I4|k�v�QX:�����jE�քo�U��ٽ`��7�@�d�2^g��5|�lw
"�0�}(��M7���H��
4�޶O��()�4��|	Z �+��6�i�UCz���BW?23@�x~�~���ʜT�,����zk�"S��:�?��(�M�������H�<�&*?�Jۛ��\T�"��P͒J��t5'�%N�l&�-`3+aayN&5�k��6je��#�N�2(�U��!k+	�m�خ+���󲄸�Ӵ�_�'=\].kr�;�q	2}]��ͯ����繯�Q���|�����&�X!��K8��d�I@�O�r,+�(�|�wd�w��������{�Ɯ�A����D̂�NUn�lm.�윻uZ�ꏏd��;$�}�V�^�NG��}-����U �
��t�~X���p�h 
�騞�l��l�,b/�h�y�^�d �%��8�T���Du�)PW ��~���Lˋ ���[�c��pv�Hs��0��.�%jm��Xn�o�a�S��ξ����W�wG�&�CK|�I��)�+��7+2��Ӎ�9ܫW�[�ߌ��o��iR&}[@*_�*��c�s��+��}�G�iwS�~O7Z�,	=���q���B�vZ�)zR�α��X�\ )��ya��ݔ�a�kO:�A�^�G$��v>��i0�@��F�s8C�a��d��Ϳ��R��,ՠ_����x���Eֹ~�Ԍ����^3)�U.,ԫ�����1Z����.Z���`�er>����P�uZ���J�	�������ǝp���5��1����gQXr.���,������H�� ��qR�Y�Ak�a
A"�_��F���0E��V���ގ��s�yM6p=~m����LX�+Em���Hϱ@q���L	ϣ�"K�1��Ȥ}i��DwAjm���L�\]����j�Pg�;���0�e2xi#4ꕉ��Lj�uSI��f��|a2/�4��9�jR�X���%�.=d��UBkH34mؽ	�߽�f~��}/��%�w��.�.�o�����ĝ!���'"�.]H�k�#^
%"�O'��*�=��6!)�+M%�x�1a:�>� �q0AႿM�����(T�-e�j_�/�bUG �&Q�����L���t�����nI��[�<Nxö=������%���uWF6Bv��!7\�a��מW|����eg̛Y0��`�2C�^���ܴ+ΙY�����!E�q�,^�}#b��aʈ��#�{���R���,��ڽʯ����q�bFn�&�Ž��=�@�{a�&�rK^D�?Ɍ(����T�z�[�K��F��0\/��`M#���7�Bs��R6��|)d-�^�;==J�����9��4^�oo
���9Xf:���Z˹(�V׷�>F��4�n���%ZB�B����]����O���n3�N����~|��o�ʕ8�^w��g��[~%P���ʏ�Ė�ˆ�P�E��Ɂt"Y�Rvnu�f�(��Yj_Pe3j�]�s	8.o<�B%�<k���m�<=v��Q�Q5e��dif��F�u�̴���9� )4o�q��R��;�&]�{U}p&>�{���+A�I��ԗA�ZS���K~�@%��5�1�W2�VNF���ِ@��z�D#�aJ�s��WxAe��I8��D8,�'`HY;�̔��5]!��M? p�����}W+,0S�D��Vc�Rb#0A{&�����S���ּ�~�s�q���10: �K����������%%a`,�4W-D�Ņ�v󭨗�
F� �{6��`��ZI�Tk�ϊ�U\���D��V�G�?�0.$CU�)���z�["��Z��F�JM9��_zbwѭꊔuQ��K~�1E�U���T��d��$.�,��	m�>Z�������=O�~�D�|B�)C��~#�*�i
�
�fmOr{�o���\F�c�L���-�v�j2x�P돪��Q�yh�@��!�<X��-������#��?��G�?F]{�G��
w������|C�_fǔF��dJ�� CƑr��LwW@n/K�@�[:���\�S�Nmj�����/,������5��d�lzU{���-%�ƒ�l|>��E�x�w�	 ��YE_C���s��'K��m�3��;��_��R '�>�i�<߉C'��@�c��HA/~�M4�+�5"��L�FJ���M3���n��o1M5�'�d��ظ<T�=��&�0UY�9��>�Vl�svK���p��~ю��S�(x���2��@��zt��ٍf28�fDU�S3#���o㥤�"��	���ͩ�~~�Yҧ�'vW����&���C+C��3�B�>��TZ}y���ߘ[������[���Xl}P�K7t��QşA���WM��m�0mĶ�]��d�$����,��:q#��\����<C���c��rI���"�w&ܷ�����K��?�B�wOr?�\�|�"��n�����g��R'��y��+�f��z;&�ID���������k�{'�� r��S�����6C}�'�	Y�AP&1��dݝ����,S�5ϐ.��<�%�[�?�u6��rzl�����9�${;?X�^�S���f�yyr�b�վ��ztw��1��L�G$(�.lNq�ƪ5�M.�]�F7`��F V{��O���i��m#)��gZ�?�`�$�S��`�m���ZR�w����xE����+7�SHA��=&�P�ӀΆ��.�c��}�`R��Ca�nKp}�m>)�HO�7s�����0Y��q�(��,�sS��.y�;g�δQb(|&�1��O�C��8s܅���7�X?v�q��wr2����bi)�U�y��?|'����.��5.��Oݟ0�C�{��/��%J7M�\߇8W7��J��R���^�wfϸ�:��54�r�R��T�#dȼ8d%�,+�:�� ¾�6��^6��4�w �,�$��"A�=aX����\��M�����#���@n/xH�\uX�u/�C���MCp��r6�ٹ��S{�[H�1���B ���+�-��*�����B�m�+���ݔ��C��1���aZ��_���o�R~�h��j�w���9B~�Ж��8�t����D��ʪ�����m�x	�".�o6��4�k+�
6�Y��ޤ�	�${�*�]Υ�v!q�LB�g��3��V�`�G���F�j���g[]E�`�Y95c���(s��%%��8�7�@�� ��7�I�x/eC.9���n�l��W)�z] \���7`&:>�F�@^8~r�8,*|�YØB���b[�fO��|��-c��p�4nf��ah���;�ɞN6�����)�Ox�����<��_�KOF�ejb�����)ς7)D��N��h8�5	��_&�`� ����<��7�vJ�����	+�wA�j�F�Ny�i��O�G������ר��Wc���ԉ�:��r�E(��t�hA0B!C6���f�1C_��3���-�h00ƌ�(R8�_�Vܾ��vp-H`���cm����h��t��)�Q �B����x������җWLu���iV.��,Ґ��@+/��r��l�>�~�.�+�C�4�)1h�Q�B��d�Afk��Lt��s��*��O�=�},��6�!>���ꂟP5 ƍ#SF�`��xYGT�|+��d�E�V�����⫀�
�T�k@�,��\c`Z�,�y	�Z�21��_�Y�L҃o�D6�5K��k�1�r�$�1�UC0J�?��6��3l����z�F]���M0�j	���풾����[��T ]�iqA��y"*�9�� 'P��L��w	5Ƈ<���V���h�0;���	s���f���N����J
��48@c�wP&��FP�\_rs%�H��Z�z�+~P9,�$���M�)��q�/����{;uT���Dx���$G�c����*~&w�D�M[����$A�%�j�e/�}�Ϡ���o�-Q�l��czN!���.!�	k�+�f��$��H|!�o�z?T������T�3� ��h�-L߽2����0��\�\K��B5f=�^ʍ�W�:��AI��t*����ďyBIl���ť=falY��� �$�?�j�#z�v����b~�9��E�||=�0M��2���7�	�����c� �p�&b�?Wl4WcƉxOi�,)����2L[A�l?���,Sew4Q�Iz҂�o���.��)�M����Ev>�T���f,(;*3��� �r����LX��N���s�"`�dG;\�yco[����)���K���ߗa�j�B[O�����G\�HC�}%Y	�
��Sݥ�g�����9��ykm�of�'I�_�S)�c_�e����/v7}�����Gw��kNX���z�}(F�5p�D���C�-:��j��]�&_lR@���bxУf�+��|�1�?+n���k�|���dv��D�P���ى��­e�l����XW��A}tB7���TJVJ���?!�	������I
��:�~F� ��p�\�ffP��V�i$g�I�hۍ�U�m�\�����|ѭ~L��?Z{����Q�ͱ��]Y	��Qީl j���>ATM7�c��@9܊'��W�`���
��22�=��'��e �����o�y�����e���\���T�'/�<�ݭ&�*L�����c:�]޳|M1L��~�gt���;�E3�W�I��27f��$�\��'��_7[l(n���OK����q�Ā	5 ������96���m��]�D\
l}�Q.��,��!����Q3O�u×i�f 0)�j}���n��%wthG���8yG/[�m�M�����H`�Α���O&��0#�p~�J�LN����U�
��}.ܭ8��C��D`y}[�8V�T5���B�)�c!��ہ�]l��-��Lx��>|��}�����
�m>(��!��m�w2�=���%�#�­�e�	7����[$�%!��$��2�ƒdC�,t�|����n�{�|[�1C}J�r��X'���ƹ2)��� �M&�9Zi��Y���̞��[s4�� �RBґ�t�)z#&�TN�u�-Q���T���Gv����u���/��$����m7:4cJ�dC�V����xP.3�ᆝ��&��T�k;m6ҙ=Št�|�l13�}������N?%���A����䐱E1��qJ�oS]�|��r1�����}, ��?�u�"�NR�&��W�nv����8��}.�J�-}���ZjW>]��{�7��^hm��.�Lc"�L�(�N"B���m��>Z��v�|T�a���H��˧M?�&ҡ}��pd�|@����xa��
�v{i�5��Q� �g'V�kC��'۾-J�%�k����^̕T�Ю-�Չpup�����<xYG�^dhV��db�j堉����@T�ޞXv�����8�U!�fV�,+ �r�Ԃ\H
UJ����E�����!���z&�/�4�?�O��A�V�7�FN�PP削%/�!�'�Ǭ I��g�ܼ���|��
�/��h�|K,�f֥�V;�Y���#���z���9�ݯ� �Òtj����̺(!�H���Ӽ휅H�R8n�I�x��T�����G"klq��y��3C�Te�n�[�A����7Q�I�N	���P��1���GG��K���<V8�)��V�$j	�,�X�'��v�\������'c�y�j�M8�W�s@��ưO�YTNb�a�s�qV��.#Q��V��}�Q���x��ŔL����[?�5o�h��nø��ZG���Z�H�z���^0�nkR�6
"�C%�ҿ�n=�B�3��y�k0��cH�����N>0,-�F�VOt�$<��0,��Ќŉ�U"cͿ�ꛀ�%d��L#E̴����d��.��0zE���ɘ�ȍ���#AF����}��9/N�B��SG-I�0������QA3��<���$���`	���]�eЇv�*qj�h��6�"�����B�	���6	ΰ��^D�V�UA����N��;�������~E��=��06��b��h ���XIS�5t�\�Q�s+yOr��z\6PG�Wk����0�j�?8Q6�}�\�D�������<h~��:�1u�Xy[!������8��p����ħ��@�i��B�R�9x�?r�M�FXCH�]ֹ�Z>��yb��e��<�������Й���V�P	P��r�ɐ�e������iA���D�W.Pn��%Ȱ�4]Z�M��C�2�'�CM��N�V+)�ك���L\�?^A����}�I�MF�d�)�ԅ~���s�%���c��yB��ʋ�{�(+�e[�9��o�|�\�*����V3N�\K��I�P���0
����w��;f��~C��qG��������'�����������4,�j���^5�bلo^�@�zn����@�S?;ɚ�6�`����N���� ��lߣ^)ϩJj������W�!]�?�/�J�夕,?��%��*���'�`F7��@���G?�~7�^�_�PՉО}���,@����UXx'4�e���5��m3U�Y%v�s�����`�l�)���� *9&ˌED����l�U���ie�;�>�jq�Kk@�RK��V�8��5"�~,in�Ϫ˛±j��eK�:�	�|�DN<'%��g��lCs��������j_��K;���޶�����r�a���ĄD���$�W�5������ױ������s�*@�l��6�"5.v�`�C8Fy�C�4��_�R�/Y���>���Z^�_i��5L@\��nW�ȼs�\�!��J0q�n��=�C�;��v��vfC~@Kz�n�q��=z)D�o��P9~з�T1Ȥ�ّAޝ���S}<��)��I}y�	�S�t��Ncs�˃�����	�7v��}Η��6��6��OEr���Ǉ��������~�Ê��2����NA[[F.yH7�����Y��؇`��ڬҢe�I��)���3?B�\��w�L�#�&������["��ʮs�㬋��~:��t��L����t��	7�����W�k��>���a����Ϋu�D�P\���r�$�a���`��󙁞{��f���e/�#~^�&X�v���﷞5����� ��J:!�c�%�jw��B�Q?e�8� �E6+\���dKs.�NJ_a���d2\꽱U*��Ɣ_DT�8@�B�E�D֙0�u>���	�^ì6ϯu�����a����;�R����LH݀8~ޫ��y�C���-i��ש˃�@b��)�j�>�~^V���Ia9�<+B\���t�2Z�J�s@�J8,��y�.�nz�oH糦鸼rB�����$*N���6g�]H��P��4��2�^�)��@-I
��D�
P!M ���bg^(v�U!�Tc��!�d�O��Xǁ�g��	6G#�Ң��W�KK1�]$W��� ��M��Yw�Xh�4^ ��G1e�H)�/�9<�1m < �>�v�)m������I ��l��[ثa���Y�l?��՗e���������us0i��;5��h<�������Ŷ���Ќ���i�c��-_gű\�n�o㵃a��j
�m�t�}.I{�R#7�dzY�Vx`�s\Rs�M뫘KgY �����hL�����ꥋC.�*4��f�)3�e�+��Z?a��݈�U�-��-�xE4/J��g2�`�hҔ�p���蝃�����h3�HJ��C�����r��d��lX�ys��~����>�.� y�����j�O�w��?�?��U�����&�kS�z��p�+D���P/	חHLY$_�Ɠ��p}���T�W��r0�˖y� ���U��X>����
g��i�������C;��{S��[�����u���.R��2��E���8�Ae�I�Bͨݦnz�{�y��Av@x��I�/h?9�e^�3�k��f����G�Od.�4 �����@��-�nd�a��������oT�ֶ:҉�:��I0ٻPu�wu�8-�ff���-+���N4zjW@H����r"�!.M(�2�tX�£�~��v�$���I�<�hG�}�Q�"v�ag��[�6ۛO����L+���JsE�L3�1�����+�,J7�x�۩��>+H��%E���}>�qv��W���Xp��q�@<�h^�	8�$��N�}a͢D.�{4�� �2�33��`���o�r����+&�µ-mg�]�$�j�F�?(l��8��� �>�3x����v��D��f'��CFR���w���?ǭP�%j=z
�{�@a�[x|-X �(�!��8S�2����R\�&GsS��/ltc�T�UN)��%��8��a@�T�����4�O[�Z���zʕ�5Y9���h��g��a�����j_�
�[�bj�O�Z��;��)����U�,�8��{^�����Sx[�^��Y_щ��s_W�X��O�Ny�$�Lb �p�#��'_��Sf�(��.Ӫ��hs߽��:1�-m�;'�rY{v�؍����!��zlb���(�OEc��?�)��n�cB9?J�wS}����:��K�:	2W	{cƗ�ݍ`E�q!��}Ȋ=�i=��a�0݇S�:Xn۫lA���XO�	e���e��(�q��	��Q�mLN�<}�)��:�J@�=�?�TN�t~���'=�G\��/�I�)n��(��mAĬiÔ^R�HQ��z��C���@��Ϟj�ъ���3��5~�M��Ɂ(��;�
�����deQ-�
pt�X����ohR��$2B�*S�� mV�z[H3����Ty��A�ι���gr� �,�'��7�����2c�28KPK����T�
#Ҧhklt]��m�H�.>��D5��ȫm9,ô�޿����1��;?��m��州#+\���ԣ���g�m�5)U�C�(���{h}�����e��|����W����v�m����S�����d��"̨9��UP�c��<�V�L;9f���#���W�S��S]u��fhQ�S�ϯ�I{\o�w2mz&3�nh��U �MO ��2gJ�c�oS��v@0s�TM�{�]����q�B�P2��h����c��:g���D����i0p��
��J-��94����g
����;����ͼ��|%�f�6�iX����Zv���C��{�qGOqX�r����z��T�hZ4d���h�5a��3U���^)����]��TAG�?S���DPfq��d+UDv���=�d�w,p�0��z�ě�x4�!��~d��lr�4LB�N�#���|���4��5!�x�Gg�]��!u�Q��a�����K�\��o��@���3�Ot[U>�!Q��h�C��v�$N�Y��� �LXӷJ��|�0ѫ�O���z-=����X{�O]�w��cKa�[�w�R����m�YZ�qI%�Z�h�x?����-�H�1��@��e+b.'8�Z����4J�A�.XG%��"X������!��3�r���Q����0�.�95=py���h
��gS��;���	�)}2��D>N""!l���I��v(�৕��I��)�e���'�u�_� �O~�(�N6�2 C��j��t.���xW�dbL�ND_�w�/�	�(2���>�*<�n�����Ĝ�m5�!��=}��w�ur��t�m�9�93|�~�/_�ﳄp0D��9;�NbQLq��~�[ _EM�â"�%�زt)�4�(�%0��qB#�BP�!���v}�>�:�[��V�!-��S��C��Tk5��׊��l�v.u��;���>�;�|TӖ�ڰ����7.�޷�%����Y�,��͚�`������U��&�n}����Ӗ�O�T��N��9Nu)�����n4l�e�Ed�oV���|B�V6��ٽ{ߚ��z �&X�hXsn�|o����T�"Pnů�X����c�+06b�r.�����!+c)���1��n��l*):vb>8��|�eJ�,��9)�@���~&I�"+�/˵!1i՝��[�k���ة���#�h��.M�9 B�<��#�O�Lo=�	-4�h=�ؼ+S��C?;�?��XW��:���tLY��?b��>���y�g��^�N����a]�J��p�x��|*�y��[��͈�bP���y��J�;�ʳ��C�v�c�cQ2��+�p�����qw ���`��FWO�0Ku�
V}�@��#!��2:�� �ۡ]����p�\��Ƙ��f<�
���>��|�D�BT0o�.���	����	�Kٟݏ�J�
%�[t�c�i]m�z��E̅ռ�wf�^��4 ���Ϝ̨�R_s}��[�=#��y�/����Ҝ*��
[nG�qA���#$'ԴXf#HR?��"����0�C�>�����u� c��`�"v}w�v �~�~�͞�5�N�%g�<n�����3c�~�����;_�8-�8vr�^�g��S���5JP� V�,��-�]����u|��Z�R!��忘��`<�d7Gt&4�e"2<v������޲�C�@�~Ԭ/0������	�1B���+�{���A��"�q���ԛ�M�����1�0p�ڶ����	XnX����S�)b5�r9�����AV�*����D7���/�V����GVR~ �_����^�;2��:qn��'΀qV�S�8�o/+��BZ}��dOVBuhYL�˩ _ȞR�:���`v]��`�|s�����΂ �@+9~og���g�����o��t'�Q�c E�ZRAi�*q����Zo�^i�!���O�."����Kz��1#�h�h�Ȏ��3I]���-e$4�SS6�'W�<Hi��pb�3�\z���#�A�'���i�7��84��[T�G��#E�ʭq��~3��*�����cw�Jg�Bᥞ)����oy� J�h��x�W  �$����� �����:���g�    YZ