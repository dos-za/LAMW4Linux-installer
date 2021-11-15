#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="978864428"
MD5="1b9f4504cea0c0ebb2b6fc8e95ee548d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25000"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov 15 14:32:51 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
�7zXZ  �ִF !   �X����ah] �}��1Dd]����P�t�F�U��ױ� ����2k%�D[`gc�1���<��%9���!�f5��qg��2L�I6�C
i~h��@��w�
g��Q?�%}�8�Q�6:�l	�����HK�հH�WR&<t���y%=�o�K����g��㼊hTuP^��{�!9_L��
����bA����!Q��ˇ
vޙo��
y��j�bl?F^ة�y!�H����JΆa���N�=�h58���PZ1��TՉ'b�S���)J������l�C���>Ģ�"}��?s��tw7'a�)���9-/��)	�9�Rp	�9@��F�-�Q��M/���|o/$n�Pc�Q�)�a\��O���}�BOx��v��d<Q&�����z����B��\|@����4q��c'S� ���.)'�)@@x-D�@{��J�v��ډ+�Z�I�]s��T��;��7�X=�'���{�V��/°�W)Z[l��P�ݸ�+t�"�uw��H�ǩߗ���@�4˯��cd���i�j%�<ޥ���/�߷���K��H%P�b_�N�񅔧��j�����6��y%�E���^�i��tI����T6�p0��5h���� }Zz6��x�%�@��4;kL���6Ce�%����J��ţ��8�	yg��Rδ�"�Sh�����C�������|�Y�%��X���O�9���;��^���+6�P;�Ǔ"3�]����]�A �ټE���Z�N(��u��\{���PNa!mꗩusP-#4Q�JTiu�uHH�����h=��E5��X��������I�~<-Sa@i�8�m^}�i����}i��ӯ�a4g����jCnCX�k�{��>�V��� 1��P��^J~;��u'�mUް"�����^r�Gft.]<)��>��H�`>���/)�2)��O]�A�e׵�0��Zݼl��������Պ�ؼ��G�ɓ�:��%������=ik�郲�=�"�M�,֋�+���P5������>���E|�+�Tdr�ɑ����"k{*�L�gg�@?ԓX��	;;Hsx[+���I���>V�U���C��o;G�����v��Е�)�*��
�������z�K7u@O��M8:��p�?r奌s����S �'
<[vN��
vWmp�Te}����x������oG�6`��Z�[*��?�Aq���Č���1����v��:���mb�����=N�2��a���O���O��ve�R��Э��9������5�Igo��yE��2]m�홖����k�9,,GA�ܺ�/0(Er��Y��W�`V|�.�`a\72���7���ٳz?4��C(2�M���4?�A0S���ZI��nʿ���qΚl�����˒S�oLM�n��v���\�����x^�1�~��B�]'s6Z#*zL49��G�<��H�m8��港Yc<�lh���9�8ׯ  �K��Cz��SD���"�u ?�)Ɇxߕ�Ţ/b�E���K�-P���^�|�7��sX��9�VY{�(~�5Xl�I�գ�(&�0G^�q�w�I�v\J)��?��x;�yG��mSN*e�����GZ��I��U���1�F}�H�l_�J���0�Ҝ�ZO{��چY=��Ϻ�e�����L��G�G4�#j?;�3�hg�O_�$��B��� ���V'V�<8nւ��%�m&�^+�qY�%�}��L�@·�DGtY�����p�^1P���S5;͓$��1��["�ItT�财�q�*�Ü�K�����@�@�,;V�
Ą�)A)dq�)ɖ��1��W��3,$��>4m�;ۭ��4B�$⃑:��_C1��k8��p���>fwP-BH�L�%�e&�0���u����1�|�.S�rPMQ��FN8W��j�>���ɡ4�*~C�LX
 MP��z���_�lP(�а�$9�;Ñ��F�Ա�?j�tk<E#=z��(f���2du�w�ɚ�%fѦ� `�q�"Jmݭ3DU�aq:aR�)�e��ne���N�=~�����t{��6�bI�ϥ������Cf�J�ȴT2/=�~�N����oC��M�:�tw��RߤA�WO����d�t:P�v����+Ŋhc��k`��z�J�Y!�C]�f3�Z�U]�e~[����}#[RO��\Vu6��<G]`|Sw��X�i����|�Z���(,sf �-���S��zi�r�h����+���*ws�a��8 гN�9z��������>�<wI���q�D�'���'N�Z�*�L�z�B�R�vIS�B�ã�v���ܿ��@@=�)ĩZĎ<����2�L
!�d=^y�������5��iF�!o:y+�LO]�eP���V��ڱ �lS��.ռ|�'���j/�d�Sڞn�\ɇ7��4�,&���6�.�u=戭�axL�95�걈Ր׈g�C���8N�3Ο	
�,�I����A�ӥÔ�����ͦE[�pI������A�bqC����ڰ�k��'��D�J4���q;���E!��ܩd��\9P,Yxp�5�r7ҁ�KFp�e렅���v�n޺��O��������x�B��Q��'7�U���1�7��������v��V*n�WW0�8!�uzÆs[}����A7��i�e�G����.=N߲��F�����_�O,����"�J��VK��P�Ӝ��k%�|�#�B�'��䩵��p�u���!~�J�"T�u�gO�ǣ ���3v$�N
�|��=����s��T.�eW���U׿3�#[�,��o���_��9c��������A0���cc���6_�0�"8��$]�3�QP+��r��,X�X��B�wU"������ƫ�6J���<- V?���u���St��7�T��0U��|�:֟?gZZ\�:C#��M4<�}�p�4��ru�	�Π�i�|����D��%*�yQ�&H�א7uC�m��F6\4��c��O�p6?l/�yDz���jh#f�G7F�Y�:�m\������@����8%���P�jW��Me�#Id*�@S�I��	�{#	��|��OK�5����0�
�4tu�㴳�Th�j����{�H��~�x�a�r��	�1ӏ"�-��.�~g��Յ����u�ʜV�ch��̃6��eoЖ�CE8��5��������.�2W,i�]��a�9�h��N;���Qy��HK_����M����iy��ziG�O�Z1 ���8%M�v��Z�M�����ymݼ�m��d3F����r��b�xx��ͳt1J�b��%>��Y��d���]�"��7,��J!zn6�6U��vu�t��8�9�.��X9H�Өe~�!���PbR���Y����[SIZ�Si�q�0	�r๟�  D#n�b[�e��
g��{�>l��a�4��L���|RZ��Չ5̏M%5�gG�$>BK���/�સqX��]���S�h��p�߿ai	�I���ۛe��~i��Q.MH�!e��?���S��͸��C	���!W|�1�g���R̘7��O
��J�~�\Vj��|ˇ�5?�?^��zfr��%�C&�'ʘ��Z�VB����!��`Yz���{1���:)1aӽ,lD�h
5��S�h� ���W�+�l�806��#HA�쟇�� 7��F������܉�K>�Y�.h 6�c���רĂ�]�����I�X�,�idfΎ��LR褊���(`ZM��V��$M�r�γ �bT+��A�`�^�܁*�ЇEi��p�ȍ�
�i�5z):�X�:0bc��)�ZJ;�`�J��\Ԥ'���m2�)/{�6�@��(8 ��~��_���o�v̜z���I3�3J�c��c�]���-� ��VA�й��o��S���3NrF�8V�VW��"ޙQ;�A��v�t���S@b����F2!@��a��	�L�*�^^�i�z8�
�� ��P��;F�s	���{�S�����;4�~}��Y,"Շ;��L�O,Лº<ᧆE{�K��M�@��!��v���cA����!����vz^^�1pD�k&4�?���ܜ�5��dv�� �����yVR�e�=�ݭS�0	`�|^�y����� ��\��x���X�t�<#�u^y)ͣ��0Q����0����q0�q�7��H�%2���m�ئ��N��xN9� N�������q����/"���CȐH�'�Ws\�ĺ��u���<�?S?6A�As 1�>�i\h��Q�+�[�g�N)�l녈wĘ|�l�9�)����,�-���X9�0�k���C��.V�d�tRhimm���l2L@i_�ϲ��5�n��F5һ����?��٪�/����E��Z����PIC<�y@��:���ߒ:hS�f�K�٠�Z����LX+���?+�;f3�p�9]Ç���E�g��>2ͣ��]J��2��g�J�(����1���f�=Std��7�R铟�sj�����Q��[ֆ�I	�c�;��O�}��ZW�E_Vt�1��6(�֟\|��f���N�Cuq]�d?E�Bi��|���X�
�S`2@�\U���	�D]3�_@G"dA�t��D���r�(k K�!�^�9�Ť�)k����׆����Y��{�<���۴��W���Q��΂e�}��H���E�O�\8C�=�?I���_7��|7a�t<0���/�\��BR2�PYԡ��3T	�A���'��p�t1�o?�Fu��RX���I�V;�@x(�$k�
l�,^Λ?��L�륇���J}׫z5�wֳAFR+��z�ա��яY�V�հ��i��w��m�yy� �^�Ԩ6��!U.}�{}m�HTT=wj�F�U�&V�x�H�h�fb;�|)��p������o�$�Z�MT���i�Pm�4���y��Shv��Q�^=4^;�NTf��f<��˗c�A�j]p0�,e���ݮx�Ax�����u_w���#),o�"�Y%{��2�.��rB�T?`��E�A�ۉ��,p[��D�h���{���>�;�#7��碂1f��m�-:p<vO��9�\Ԟ�� 
������POlln���N���x:�ع�J��,C�O׵\�l�����5��x���Veog/���/
KU|�w�1Lu]d͗W�[�9LOHB6���p�7��e�Y�$Qy�2Ho��i��S��ŀ�������ߜh'R���
fA�>1H1��R�3��G�_ ��ü�5��)Y��~K�Y�۽3�9��S�p
�U_�E2�g6���K�-�3�%�;ܴP���͍V��.w���9Ep0�(��z5?`�].����'���씄UY�A�8����- �ӝ����!!j�GLm�����K���^2�������in��@�@�!rT��H�G�p���\J5r�0�؏��ܒ��vkn*,JY�$'5O%Bڿq��ϒ�#>/��?S�� �Uǵ;!�e�
�0ZA:�ǜt�9�Y����8u��0�n�b�p�˕��St�H+���4ź�x�c�C}�9�p�j��e�Q�]��f��4�y�sh�|d�I{�;N{߳��-Eϸ��EX�}��]l�rmm �+��#.y���_.da�]U��J7�x'��K�׋���svί��w�n���j�3�gl�؝L�������c's~�,}��#R�G��k(�4����yԽܗq�:��[(��i�A�=ڛ����g�����  n3��P�PV7�>\՝���ͩ��J�x�{�F˯$V�^���n���x���xƆ|6���S�9m9��x/a[���ci�{��
bz���_�ۘϣ����ԙ*Zn��km�?�YYg��Q��
_RBʉ�'�U�6+���
����`�l����c���կ�մ�L�������ͩ=A[|�L��/���
}9�&԰kvF�i���o�K�Ļqw�
H}>�tc��g :��OL-?�e��#�Q�R6�NR�)T�8H�Zw��g��Q1�������S�����[ń,т��!Ц�bW޷���೫ ��M�H�:�ʂ��g���~�Dr�V���� �G�zU���&\+�|�P��9�{�����A
j���%y�����?�!�!0��ڑ�Q�*�7~���Sտ�CoXZ�I�^J٭�lW
�M%�V�i
وh�;: f�)E����Ē���V�n�H��Ea����9-ȇ�׸G<�����T��>~��k� �g+�$`��I��S�FX&����6� B�H��ص�v��sh��O���N�N��^ԏMTv���8e��$��gU�A��NG87�
lƌ=�T︼W/�w�j��W�*˷lt�2�6a��:`��+nL#�Ʃ+�x��)����g��5[�G�X��Q~g�F\D�*GT���9ty��Z�u�U:��Ԗ��aUu���ҹ�H�O@(�V9O��~�-�x�gn2�tz�M�5/~,���y[1��WP?Z����Vΐ���Zn���b��blv�}t�B5H�9��"��[����Noꅬ$�",m�����)�}BR�&B���4aG���;̡~��ޢ�q��cuW[:���@CO�6>�+h�r��(/F΁"8�0���Y7bn�c�0T�f�&Oh��$t�����¦�U�\�BB_{W�}��\�+������"�	s&NL)"����D��雦��E��(j;9�慉�R���4B�Փ;�.͏͗s�
���LR�%"xF7�U��6���G�g������2w�<�E����r�h� @�3��ł���Ө.�H� ���KH;r��!	磣L�Q�'��&F�-}���ϙeU������_���o��x!ʀ^ ��xnYu�K\���Q�P�6����Y��Te�ן�2�C8O_V�oB@�}���+`�(�,�^��婤I����{����/X:��:YD�y��,�i�+�*�{�?������}����a����]���b�m\G��-p�	�n"�+�t�чG1*����v��4`Oß�@���CИ���ވ ��@I�ע����T����dТl��)�gt�0�	#"��M����
[�ۂT�!n#��V�4�iN<栝It��t�`�b���O�,$���s��d�F��Imt��@VI��E%Y�N!8��p9|�E�܈a��J{��E�)�Wލ�n�s"�_.��S�n'��PD�Dv��ěD������G�[�e���\TV����Q�?��JA�7ԉ��{��B�)�����.����=�ͷ�",˒\�_�$��U������Ԣ}e�B���<�tS_H6�*�Z��,���&���u\a�Py�@���m��Xw��r*��`ɲ�!|���V���-��d��H�qoK�cMn�ݽعl�Zr4�B� >����p48/�؄(�*)Q�J7N݃;D�=��Y�x�4����p�����@-�w�U f�,#PZ=E�.4�;`�+��N	S�*�T��V�xT��:Um�lz��ޚ�;��L1YC�>T��]7��W0���ʺ&S��]�O.mq��w��&���u|�ɸ����Z3�y�=���P���eN!���Uc�!U�q�L���
t3c�8�� <�^���V���1�����d�h~�Es+ו�j�?3��#2�(?�uf�gmri,�xqz�3���s��W£uj��&�p�,��+M�#>{� )1.����Dc,��<�4,�j��:V�kF~��z_g��{h��K�E��Y�d���'��~<���HF���,A��̲�/�6#r$[�O�A���X���4[,���Dy+��_�����r�^��d�T�ަ�&4y���[>e�o�ݱ�f�!|]���EU�C�o�������y��!��c�$&�]����\u"G(���W0;/w�.26����ȅ���ҟQl�* =^{w�&O����>�j�6���9��|jd���3�'���}�[(6y����	�9�bJ���'�2��$J���nD7%�?��S�k�Bc�Ƞ�]��@3q�i@v{��8�zUk�k{��=Om��d�����= VY����x���Rյ���)mґ@����-��wORb�wf�룃��7j
cē�_�u�W�s{g	��X�[��{s.�5�ה�Y;۹�M�!~������)U�	^�G��<����͍�g�Օ�8�����v8mK�UTkxS�0�VR�	�E�9|E�hN����dZB�I6�JE�^d/<~�ԟ�����i(}��� q�5�)��w�T�㳷�׆����0`l�~�m��l�1��ݖ��ŗ�Ӊ����rοi��]B���+q!��@��]q3=�(��`���� ;]��wg:Ҝ�I?��ZQ��/���^���w1�͇_�|��@XQ�������ږ�<c�nO��ҹ�o
�3d�&�P@ݮ���c�Vݯ��y��M��*���k�H'��Y �޾F>��������
�f��f��^+Rđ�$Z��>���9�Hg�7r�^+xYmŢ)ʱ���ۈJ� �
߳��uvJ/|�YZ$Z�̀�ˤ���4� *˰�3#�yF���� �����H���'ef����ߣ��{z�BN�^1�5ү�Y�,�j�ݒ�'��0��AHz�;�8M��]FH@U�th�0ɜ�_�y:e�B�K�7q��̕O!���C�Ǿe���S&K�k�^���򼻜��ϲJF����޳L]�G��i$\�V*Ng�Oc�C7fQ$����N�� ח4Yl>���@��ɬ	w�5�����N�����	ٳ�7�ӏ���X�����/=Kub�O���6����U6�:(���]�a�ZK�;V�U;�_ڏ��ſ��T3�}�j�)>�7����~F��0��lk>���k÷�W�l�յ\���k��qK�(��t|K���nn��MQ�Cs���=>ţ�o���_�g_��4$��@�ͣ^�
�����@���?��XD�2���DV��{W�H��v�-l�� �������:��p4���	y���5;Q���b��GOu:`|�ܮ�L�4 �[ye�JL��w)"B��C����Mw-�
l�V���*���㍊9+K\���42��~y��Æ|���Î�,o(��������L�=,�m�qe#��}���H��TC�p�n���?}ϐ*9z,�e������8#����P̩h�=��Â�崜nI,��>P����1� ]�b�{t�|x(�Z-�͓:2�ig�����nYh���-�e��L��_�cu���[J~��,ѼcB�V;L"y^=�	���i`�C�s,'L�1��ߡY�,�L2�2;U5�_�/���-�Ɏ8�i) _Y}бk�I�rX�֙d�wSz�~��ɍ�Pt�|p���!KÀD�*B��j�
4�qT@�m�QcɊ�Up��a:�`����%׆���z	�7P�� �ď�k/������	!�C�����to�Ѩ�sQ����t�`�+ <���?`��T�q������"�I�l�E�.]$d�79���%F~;�"{�{�����uL�r)e����x_�"k5 ��T1�P�k��آ�/֬79`ȥ����"� ����X@R�>�8V���"f�m���I��sW�6]I�Jf�ku2QOFl6+)��c��FY�Zw��"m��37m�R�-"�Sk��៩E�g�֫���2lGmLA�t����ed�g^� 0,2�n���O�����u2�͙�(�!ԍ{XYz��_/��UuL��~�J���=Do��{D�{]9?��5�_��ъT��x�~]���/��XK���%�sc�CD��"!��"v�O#x$j�N���7,
.&�=���&l}��(��I���p��|����F�Q[��ȡQ�C�(��k�B4������5�u[r�G�4���C���͆��;~���0��n%��5���mc�J�V��s)p����!��^W��'�Zf��m���|���8`|�Gy�;ZCs��i�f�V9(
QUR�>���Q"��|��8�s2�v��MثX,�^�4��#��Ӹ8�R.Zb�n��c�1����z�ֻ橕��X�N���"�e]f��T&@��L+T4���r^3��#YBS�H��cɺEgT�1��;� �Q���^^�/C��@��sT�BPˆ�[�� ��0�����M�P�����v���̜�ࣴV~�{�@r!�n&x,bK0���~ԉ��&��n��6e�0J�!�~��&��@zs�*�n6�	>#��w`����߇oR:�[Э;�4��'7���	8Jr�+c��S�����MJhP���$����h�+���,�]��߶!����GF�ux���(��h��3N��넄`,��A�"���6�p���a#_��0�]���Ύ_�;hJ]q5]C�&�.a��
�+|B��̛A�7��[R������ؑ='_)����|�|��iP�W����H�/�0���[������]���eqVބ���J�s@Լ"�;�/��t�{��Z�mAG�#|�C��@���Xվ�����>�*<e�Nl^�����;S�϶�7�E���%�v�����x�k������@c��`�����a� z��5t��a����b���ޗ �7����������[� ��'��T�i����	\,�_����BI��x�%|�o�FJ:8�ט7S��u÷iS{��� A�+J�,8����
���9 ��юM�2(ɦ�7{�^������2_�����ӛ��]X�K]"Ԩp�c3�x�n�o��w�
_m�,���a��]!k_��G�����u/US�U����E�7�30�0F�͜�}>=�O5��d�	�i^���h��~r�����T�� L`�z0�Az.�y
�o���%�;�
l^$���Hi3���H��u�P�z�Ο����OgB
#�e}��0.��-���=����Lk\�#Z^�ƹZ_�
ߋ�C9�}:���� ��Pv��_$�&d&G��.'�X7�l�d;���؜̨������.W���/��;�!/�>ԭ޵U�g&- ���)S���Qq��������t?o��R�?��z�'�:1H�K��{ψ�+�=i���>&ߥ$�Sf�����1/U��)AI�H�@"���BC��+����14�r7�&��J^-M�:�"/��> ��@ۃ<����~���p��sXu/��d?ׇnd�?
M�Y��/��j׵"����+n�,[M5+�i�[e���;$`��)�\�@dqw�I��t� ���t�}*�/GYZ(�=�~�Kn�{��
z�L[#�:L���<
���,��򵊂��U�4xIQ׬��B��v�ㇴ�F[���=�ȉ��@���r��uI勥ǂ�æ��&�k������6����DA~�����0g:�/j�8�:bΑE�F�+d���<z0�]�7���e�΄{��#I5�n3v���}'�-��Q��/�CRf�`��1�(#��y:����>����Ϝ�o���,�"�$��pN�ao�l�=����9�.$W�J�X�o�d
�3�ԙ^��押��,Ow�Db6Y�^��7X���B��Vz�I����*��+
��]�8�.\��?V�)D��3`�� 4�ڠ����F�z Y%a�(�����r�G��r�� O�x��z�,s/Ж�f3Um������v"��D�K3M�p2;����V��OP�c�=9��WԜ����Ώ��B���Z�Z�SX2����Ι�wA^n(����N���jGNIC����:'�z���)n.f��i���瘵����wh�s��W��y__R=lN4�GGg\�J ��B	�X>�6H�&� ��}�]�G4Py���~�5��@��G���m鼆汻��A���{��gh�E�2��M(�b�X�M�)n8�����Y�����eOɵf#��� sgD�)�&�R�%!�د�y��z:��e���!���ޫB^���`�$Ȣc���K}�1�����4�ݷ���͏���a �N�.?�L#�y̆f���th�H:0/�(ݨ:q�G�@R�}3���w_eWo����V$A�U����0��kh����Tmkb�TiqI�T��G[�=�0x�R�{>�D[|BG�����}��4P��8O�<�څk=f��FFA��k.Ҩ��72͔i����V���H0�U?�k���aJC��`7[�^��[����Q���4�'z8i�I%eYf��r@�*S�>�%EqP��C�M�B��P�����@�NcC�L�����7r��ge��2xρ�͖%�^L�|~��
,�����aAVn�H��w�%�@�Re�x���j����J-5����r6ђ%�&+�3��gR\��X?�Z��|ի��:G�W��c�C�!r ���&{�i*A2eW�pİ��˻�MǛ�
���#]��q��G��x-���ؖ��N���aJ��'�����2Q�]�pAM`-���@k����+Bva��T]�>�f�̑T�w�*ϼXʑ�w�v�'�/���P,���|Q�p�]��#��^�>�7:���I{�e���:��ɷ{�D_3����B����i��>$h�I�{�X��lƲ��G�Z��j������U������o�����㞼J<�f���dpvۭst2�;�f-��y�PJ�"	r�����Aԉ$��?[,B�`v������i�@^����^��Ƌ��iq��A��D3��߾��{�Q��E�t�\Wk�Êl��w1<db5�D�L֔x<�s����I껤9�
w�?8�3!�.ی3*b�?I�/�����b�s������n�p�����W��HxE�(Dx���WP�(�P7Fr�CJ��K�� �y�m��Ⱦѿ�e��^�̯���JB�/_��ij'�x44E�%�$�kr�kw���C�-��[q����t�8�ނ$�d0�&@��IH���u�M,�Z!Ö�)NH%XW�![H���j\*Xnt���䔋�1����d��t��f���@������Ұ�iB]P���O�nBD����di�)�<B<���ߥ�I��A������=֜��V�+(��1`R������6|�I�'�y�6�}upV����<�QEekL����r�5��m�0WG�j@b���;DNx�Z��&�_����?���F�C����٫x}���܌�%�z�^h�:�^9&^�2X7<��5�!Y��������uu���e�|�wz�w�
�n�s�_���[�̬��`�pY�	l�����g 6)0��c-?�����c�|uFkz����FX�u����nE�(�����c��;��2�E���f��6�91�;\fŢ�Y#��j���7Pzd��Yk�g���B�8�^Rp�=\�&��(,�"w^tj]��:_XN3�:���3����\^�U�l���Ȗ�5[��+zC��{a	S'`��mGy�-p~�rwp�2�{��؟nxAMk�A: Â��Y4_�G�y6Xf�BŃc�I3�˃l�SH��<U�nD�8�����ݧ�j�X	���ٿ>&��TI?�@�)O?M��īJЦ���,+�����bOa���=.�&�����ۈ-u�Zq�,�lih����l3�B ���//�y�c��ʍR���;��]���k����4�Q,��Xm���ɾZG�](�١�8���� ���-�����_�^B���Uȗ�Rf,�d8DC7��,Њ���a��w~)�Q�J��"7yT���;߼��8�WpU¦w�Pl,)�����Aq���:j��}pm�(�E?�C�PZ
��2,���c*�|�&��Q��CEI0W ��t=����s��:�	ĺ�	OA�����<csu�	b�[Ƣ�$���)��+�s����1&o:Sїk�!|�u�����P�{�#p.��G�MN�b(?"�-��������o٩�S@�&���
3Hb��}`Q9��գ���x��ݳ�������|�F�J馢8���oU���|ڴeל_��6����y�;��m�;i~��lTuj��M�Fb��J��_��jf�P2�)�������K���U�w�8��=�S�|��7Tl�|�E�C:�$'��"�y�:u��J�T2*�cח���"�d��]��>��sV�z�nwim��]�Y���G7����R�F|��{`ԭn�/4�+��.���.s��V`��M!_(�O��DF��[w]���~��6�~�ɉF�w�|�b�s!�8F ����a�U�?X��s�O�]G�g�?a�e��G���>G���Si���W���[�h)>HF1��4wS���(��O�p㼟9�E��x�gH�G��j?G�(��U΃��/xi��/�#r2���q�T�̨ݥЊ�:�A%څwe��ļ�N/��i��ED|�	�IA�k$`�n���Q-�A��x!q���X�hpi�e�̜5"�ZV�㭘}���_l��ʒǾ�c�NK\;�lP����vV���Bz�U��i�'�������y4%Aq;*[�M��P^G7t�W&m����[��@��>/�N(��kʗ���.f~��F�l$��8;��3/�I|&�����&{E���:�j�:,R�>F��UU��Iz#rF�ir�� ��|Ol�G֚*�?����=���H��ݗ��(�[%����hN4T_ܬd'��U�їz��_�`��/z]�²�������1���s  ��J+_������M�c=?b�z�)���0Qs9gC+4�F�gm��go�w{�T�}���.��/w"��]z��Â�p~��^�KL�������|��紳J�sȃQ^��0>#��$P[4
���y+���R���\_[w�ل��~MYS�ը]��f��d��iG*���@�z��p�a2�O�|Ї��*ng�t�m\4���yi=[Cd��h	�+>�Jc29��� ��@�SQ�Q>,8V!�dO��z@>R�H�~���� 	�V�O-��`�h�������j�|�ϔ��	��6��Ě�f$o�4)��j��b�`9��2����hY�� ��Ң�l�n�;�|�W&X�X�d�;�X��
͈�C�1��>��8R�v��k�����1�d�mU�=4A�Heo�������C��%�C��Bm	1K_Tt�{����E�w~`Q�#;�M�'m[�b�M�����6n��yy�f��4�k���x~������<8���y3� ��	�O�ɘ.c���p��a�m�|�p>����nςWa��n�?,j�����4a��wS���Ѡu2[�a<�`j@���kJ�	����z����ĖR��D��?Gk!i׃�0sfD��C�3t^���X��8�6�=��Q<��*Q�6�K�8�iwX������A�l��X����v��^K[�mƎ��l�.��et�Ol�b1%.Vf��wlV�o��!�zP����ky�&x��F�s:*��FC�u8� ,Z3荍|�ۗ6���J��V��O��h��1��M�"����9�N�d} �2I���'g	�jQ�ⷷ�䁅5꩘7��B�S��7�4,~�,�����e��[��	��c�^pn�|�~�>./'��,rZp��e"��_=�����)n��	\e�K�S�?7��Y;�e��q��8�+6Pf���!�s"�uPD�4"�#����h2����'\6^��A�4�*�MB�����[wa�3��?MoY�iҍ��(2��d��ǌ�SLI�o�.٭��d
�P�� �Ҹ��	haQ\� ���L�P�ô�u�K,��D`,	��.�(�pև���@�������hFE�gr�����09���Fے<-�f9+[���s��H#&��@t��o*v$L��	��܀����Ĺ�]V���@GTE�e0�n��ħ���M�6\�z������
%���0��/2���=ۊ�P[q���C@Vy� ������4I/�KT��DX�©6<[V�bb+�c�&���_r�FRZ(`4GT����Ƌ �8[�x�����@:�p�(^E7Yw��_!+�~���xeR6,��7�љ�0}���S���^O�H�.��H{��\o�~�ת�Ͱ����X�e
�`A�隗�qԱl��+�AH|�AN�IǇEm�>Y�>�I>��G���6��Eyү�����5�㢯;eo��P�V�f��C&�? s�q�䊑J5�[��H��P;����#Ohˤ)^���^ׂd}�b�:�`
�A�>���d��DK�����m�{�l�)ʄQ�G�ky|�]�fy~��Fj��u͇*Q�,C���݋8V�3ڏ�G/�`
��;�RN�˪�5�<B�ۈ8ΠK#� V �C:���H��;0dӱyd�5h~ȏFB��P��f������F����j���>2|bu�k��K!��͘����+�1���p��+?����A !�B�o�F6�LUG���(�Hl�ŽWML�#����ˢ16̧������=�q�`>׎�d�G��Ƞd��������z��y��A�or�&���`<مem��EA��N>�������q�T����j?�6Z��R��ޭ7�+$��C2���Ȕ�J�!�E��lсR�K�f�Ȟ�w�>{8�>���Yե	��ұ�2�j@.@��9�鸨�y�d�;��jk�q��h������z ��}��l��Ѡ��4tdZ�F�z3�|���L�_���H��kWo�'G<V�.<�-�Ae#s(3B�f��P���2 ,�͛���_��`�h����u����B�!(o ~K((��� \Gi�MVE�*�m	�H��Y�)��)�[pGV��a��������u(��E�� ce��cr�:���4�@�ʉ-'0����^ּ�"�B��ҹ��g�j��]��!~(XMHF:J���.��ާ���d�@%�$�|%���#�*��(c=e5����7-	�A�u|�Nn/d���?��6�B^�cH��{��u+QK ��v��ssRі�J�.G,ᱼ�-]d��3��2��;ʞM�N�Nd�� ��wb|\L��	��ʔN1K���~UN�S����(,"&�qG���A�'yZ{px\�>6܃!��9��ZQ�NP1pw_�/4Q��6D���J��WT�$}�����g��1�4w/�9*����v'ã}.�~NxU+�s�7<����a�%��T"����#�^�2��#n�ܲ�3d���"g�1R$C���E�̡N�^�8�hq2�4�sM��Bndb�FMf�PsL�ݲY��Y}gW�\�*K��̆5�����f�d��U���qjm�Q�X�<[��'%O�7�����f�a0o[(4�b4�m��d�ao)��֫�� ��l��}���l�����2��>����FV؛����WO/�g���XdA,>�1��	,���?�^���2YP�h��PEW�ky�=�8�%�4%�r�wU��O�ݑB��Aq���g��L"A��۾[��U_�`o�cg�ш��`wŸC2�[K��t�{�����q�S#��c����#!���B梯EZ�󇆚"�������T2�r�p�o�"0*R�A��a�w����/ ��֪?�Q*��dWRw�*rK��DC����H�u�M�[��T�R�daJ}������~�,j ����N�Uu����d��n�!+�'��HoV���VH�	��(��蠼$����P�S�i8٣I���<�N��a����x���_W�c�� �+��Wc��͎��l�$��⚦W ��@@��!t�B��X<e��_�.���"�X�<��|�ǯ�Jo]�)�6�ɩ%e�~K��V��H��ޣ���*6z�r˖6i���fwrc�7��OC��r���WL���,�'�O��>�>�MP��{u��n�l)�ǗDSB?oR�������'��i�$����k���r�7U�A�oP>��ܴ���*�Rk�e���k,����!�k�{��Vh�&�y��ʗ�*n��XmT�l��t�������yI�A�C1K�i��x��� ���X�4I6�/���>w��Ne8��|��0NX�]@6K/�mz6~$@f����}5��>�7u�#de+����4{��DY[�&&]�,�YM�$֘��īd������|T��)�ɜ�8�I��^��M'�%��lxB�΁Փ�X5��YO��v���|S��	�q�������/�/<�����+ۡJ�R�O�x3���6ة��h�s	+��y��	&{�hz5l�g�%��n"e:2a&p�f�]�>늦���F�ig|ƪ�S�Ж��z������^� q�8�N�rMȸ�KbI��78��Z!�:�!8�p\ϭ$��C9u�j4���@��������� ����(Bȏ�?���sV$h:���9�,q���p�#��}[x��G�Hp��W�LG|ƾ2R(�q�f��q��ɴ�Nk/��s��;IZ�8x+�5n2�񆕹��R�n�k��\��T����F㓃^��	������}$�'��U�
<݆JI�ȝ�� 1�}��ݎA�K�;�*D:��Hu��I+�1�.ِqsm^��v��bZ���f����Iv�lr�w)JZ���#�w3�ʈ�E�OTo/�>_(�}_yV���
��gu��DД��P��?������K5��P�}�j�>y��8��Ap`^k�u̷��� �3����ؘ�Kr�d� �n���. ߦ��퉀��͈�:9������8R�|��5��y��\�4�Ҭ��7N�ޥ�a�h@m]�w^�L5�xx�Ji���7B\������d�.�I=�Ua3�[�QC����F��U�x�'��g[d���X
����T�K���I���@�Q�c��� \7u��O��o2"{|r�m�6���1�����!���p��>�����YXJK��� rH�݁$AT���" ������c�Fcӣg��+uy�>[�z�jy��Z���j����P'�Zߵ�^fS�Ǚ6���� |�=8W�K'm:�bsq��D4�K�U&�;Sȗ���N�;�q��C�����! ��[���[�D�/��o;����?	V?2�j�ލ��u�����yJ�OwS[ϢTEdԤ_�?��bS�(��Ѫ��jl�Y���M�Fm>�W�n9���AmH㹼�qȜ��R���˸V�*��WL�j�J�7��0��=���`���y8��|���UF�W����=���0H�nP�[O��F͈H���ҳ�(��d-�?H����!9�w���-��ϖ� 558ں����*�gTR]�ڧ5��#�F\?c�aϯ�{溹�d�2oH�`� Ü�6&z���cÉ�:���)g%7bqR��`��v���N���5= H3z�|(Cu��J!�J%ۡ�Kx��4v��W9�|���%�,O)rj]"�2�r�qu��=0�!ˏ�4J8���H��F\�|�m)����
>�e�F�9���&pS��L���7����܁@�����l��r,��J��7����'=�g�'��s�׻~����u"Sj��Ӯ@�VoT�#�4��pS�><W�\"�RH�����G@r���5�X,�MQ2�h��I�*e��V #��Yh�)�Cs����?cU[ͫ�U��i���vB.��d���X�f�x���~%،T1�uZ2��Պ;Y�ʼ4[>�Ȗ���T��C��˭}5� ���/8gzDz�*LD��8������7�pu#�O�`zt2j��&A)�=�*f��_\yT/M�����bfca����L��Sï�W�P�m"�T3�ףt�+«>߷���J&�$��`2�Gi�b|���Fh�%����zX��  ?��T������^w���������q���ƸN_/��7�E$@�AS�(`���άV� 0d�P;��չ�WK}��d���Ξ����u}5IV޷8&���s�,敕�,���o�~;�ʦ��Y"K�>�0�e�Y5�&1aG�n���A��-�l�@� `����b�8�ьHw*��9��j�VR�>�*��(S���pȗS��\o�)ܯ?S&��^�L�I�z�U��)�[��O�l��J�IK��\�QDrk�s�P'�Lq�5��N��� ��o-Q~��qwj��t��xµt⋺u�����V�.��n�̋6�(����{��U��X���o�k��+dx��s����#%3ܭc�QM�<���R�V,��Z|˾=|�g�����(F-����H�P�p��2��\��q��n���)|ʄY/�4�0�� T*�>,�>����Ǯ�ՎԤyy�W�����H�u����^3��w*�Ҿ�y�z�<�¼�oKJ�苅8�[�C=����ï�aU#f����8��2a�]�,_�Td�~I`��/��qZ�����!z�V�	���4���Q�����>��6�c2�gN���Z�=.kn]�ub?'K&�g�
���Et��cwޖ��2�1��X��fsI>��	���`��z����,����9�>��Lز0���<3)q�'6"�z��V��3y�Tt��?DEtz%��d�ƩR�7e00�I��ʌ-�94�\��q���H��3(�8'Ώ�T�n�Q
��_�ާ��Bj�\Z�*�X+��8��~�5�AX0�!�XQHr�-P�Hl�Pڏ'ٍ��P��u_0����Fn�Ǝ� ���Fٸ��j�8�d�����SY8ʠF��KJ��Ee����H8�rg���E�|��m�Z=�qS(%��]�Re��#R)��-���'	ݾ��B�d�۔�"S��Oz�l�3Txq�du������N5@�T�Җ�W�O�Y���Ҁ^���J��眗�����I���<.��d��*�]��u�n���^�q�@�	0��p�Bc��l���3��p���DE��^���nL�}2H=Z>�Q�.58�|@zYiw��)�I�&����3��/��eb�'������r�������5� 04��p�,r!6��%� ��k1���VY�e^���휆<Z�������Y]{� 5*<��5Տ(�!��t�D�|���+���2�[]�.2BQ�O�_���DB��R�DW	���m��0n��t�/��2oy�j�-�7z������d�(g/�m�x&r;��+��cZ�8ʋG>��T~�#"WI�E�lC$\v�JX5.q@��	�*d�
��ȇv�E8���(�0wt,�N���T��ʒ��X�L�T�hB+��jdaz�R��k,�B�iL�A�y���;�|'�v�W<,Y^���D��%�S���x�#�V���9�v�Ou�u5�I[�<]�U��Qȇ�L�̢
��T����Օ4�\H���q��<a�`ફ�\�T�������LԟmJ��[Wk��I�ڵ0�Rzz��ND#��2S�۬s!���N� �a,�̻q���B�Uȥ�ꇕ��l1��4(So7*���c�v��Wv�����1$����W�2"�L�	t ���B�,��j�8��g[Y!���?�W������j�p���;�c���=����s�k�68<��6XW�9��̸J%�����i_?+lFO���(`�b0HC���r�'���ϻ�8=��I��j��f�F�Wb�����A�rQw� �ؐ<�E�%Y��E���"�R34Z)82AH%�[
�θ4��3σ��_����"Yl]��y�L�\�aV�7Z�'c� �6�����^�u�O��?z�ԫ�������*�Mss�TQ�q�cU$E8�uP]d�u&y�xqe���373���N��͊o�=�/�:���ws91�| r����o�
(9��)*x��>qb�`�rd	��Sd[��w�sl��S�����G`K., 'k��)Vt��
 ζ�od�P��4�Zl����5=��?䐌QK)`\�c�%/'PRR���)C7(D_-��+�:V��7F��/�;��d���{�{�*�gVG]Dֿ�(�_�C'��"�5��W^ QF��gX��/?=��k��8Y���^�?�.�=٬�L_`��		�yF*v��y��J��~mX�玶�;�
K�����:6Zq�A�]���<���a	L�{eg�i_��Yڂ6���X96�CDyc���F�=���X����+{0+����zwgְ��Qr�f��
$x���&-�)C�r��A��8A���¶.�F���O�� SW�)=��J�\yM��t��c'OQ6�(���{��<y�C4C�ɿ�j`Aݒ�1�i(/����wy���ql�M
6�t-��aqsn���e��Q4��AH�G� ��zt=�ܧ�D�O�*���@�����K�0�
?J3uδ�x%����m0��&Ra��#7GeX�	�왺R���U6D�u^_$���1�x��{w]���2�>?e�Qض��`��~�X'��h�.��NU��U�������{+f���G���Ip�X��W�c��|*ʢL�~]�"X�xRy��R����
�
�r~�Ձ�L�3���zDhe������;�d��t%{�Xa��"��L&.=K=��O]ݳ���^���>ͧ�|���h+
n����ge{��Q�'��pӈX��ң��U\�j��į~������綢��+@ҵjǱ�[i{W�˼h7�|{��#�ozóW�@00�+$Ik:_�`���J��&�N��"8��A��t��LbLP�S�g��Tz�BN?�ޢ�@T��������!��4��(4w]�s�b�NT<�5�5��Y����Fln���l�&8ERX��yr��tIĬ�*A�Ƶ�fp�J�/=�τ$m�sOc���������^�ƅg?���#�Z��ރQ��.q�P�;�	��7A!��ڪ���5`��仚��jD��DQ�QA��qｦ�n`2i����cҺ_�9�0cb�ǧq �Bב������ˡ9l��}Lb&�/H �YD�Eyg��p|j��2~��@+1
ե��k�L$Y#�.Ga*D[и��{�F��0n�N��i��E^78������IZ�����r�����D�;�L�;�౞�ֵ��ܞ���L�����l��Jb�O�*̌j��v.CU�$���~r�9�\LN׺@`��0�Ϋw�5�L���FX�_'r{����� W�I`�.�;¾�\Ac�M��Ƃ�^� �Nf�d�t�J���p,� 5࣢�W�������G"l$�3�/�vP@t�^����W���F ��D���f��ǖ��6�je]�O�ځ��j8���ѱ���.D��󘰉]��AW��K���)���Q	��� :��>%]�tk+x�ؕn'�2m���e#�1��({�ni'�$��J�8�_�bX�g3 �h����#3�Ym"�ӝ�q0'2yn���F�\5[}ƈ��Iˊ�U�g���y*�� b3�.<U+����S�L�\�0s(�7L*ҳw�k%����m��vtq�n�v���aD1�3����)���&kC龫~0K�m���QڂN�:nq�HUvP�9F�.���̳�T�ܝ7�k*�)Ք�ڝ���-�MѲߝ�2U)r+�����3��D��Di�e�ybṈ��6O�8SV�u����4f�Fx�H�����J~����}{�ip�g+�\Q��/#|�oSYP��-���\���b>��a�Ά�̚�or�֢G:�`��s�~[[~�c��D�$S��/�p��?U�}�7P��8̳��)D0���o�(d����<zt�~Q�?�H<� �Ⱥ{D2<�O�iZi�Y`C�� lɤ��<�~8/���	�
	p����s
0������S���� \�5DNX]8��ZK��%ԩ�/N���	��p�Q �q9o��-;:��>�	L�E)u�ª2��뛈rY��[A�[���w�1X�MPK�"D���:��@}��h��T2)�n���J���x�NPۖ��Q<
N�`��=I�^~�����_yC�(�>�sG����FQ躈�vgl��,@�h硔F��A��pQ�����@<�F��l���b�oO�״d�R,��=�gT�i��Q��`���\`�mRz:�֡��r�w˛�tCJf��|���i^�Vv����2�|f�}�tl��_B�ip� ��,R���3;�f4��8�`�5����w����_��5wHa-�nʒA���o��?�?��>J�$�E8����1���6�U���r�Ȯ�	A4�O_�ѵkE.{G/�|R��TH����N=���_�_*i����L���*_k9���-�5+1R��^d)�1�I�*�G*oaE\�Lb޳��9`N�;j�u\s{]��H����8AE��ی?/~�g�,�{�Ep?�=�eEW� T���`���8Ҳ�-�Ͼڭ�7��+o �@	���e�:s�6�-���1$��5f����{;��Sļ�3\_���J�1d`�̺�:,�.UyA����%C�D\ D��U ����.���g�    YZ