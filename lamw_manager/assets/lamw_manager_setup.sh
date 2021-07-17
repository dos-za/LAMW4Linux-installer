#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3305304692"
MD5="d4142e9ff416dde635016636092652bb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22608"
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
	echo Date of packaging: Sat Jul 17 17:01:36 -03 2021
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
�7zXZ  �ִF !   �X���X] �}��1Dd]����P�t�FЯRN��P��7�@ۓb\1��,�o�Ζ8�q�_�T.�1�v��ͳ���{�慎���x�Q�?O%��V7re]ٲ/|x
"�����jrW�i<��i:T���{��Qnқ�\F\�q���D�%�gk{�ՄΞ�K�����^C�`]�G�}
�Z�Â�w�����B9�c�jakؼ�:jEf�HM�Su�s���[V®���̆�w��;���G	t�b����:?\H�^�Am�9kZJbg�e�7����:����ؑl{;O�8��T>�-�܀a���e#�4�rP؎�d�/���R6�7�߁�d��%�	>-���y�iV��Hש(Jb��>ߐ��Nf�v��FZ�nQ�*�n3c*��"=�Qo�5���s����8�������f�%7
3	�N1����3�'\���=�=t7��R(]��5e�<L#A�~��s�9�c�{���h�����	AC����-E���8��a��!��S&�(��(�	;!<K�U[���<ӑO'u�sG��j�J`D�g�%��G��{k�F����8�w%T�E$�\r��M�X.h"Q&9Ύ�'QȻ�i���%��}[v��琦�~p6�r�iҬ»,lA}�D�=���냗ԕ��� l�5ߓ����D����[*��Q�{Һ��*�ПtJ�����`��H��警In����_�:��^�A(1��͠q�I���)K����}��87���EG�}��6���¸�n��]@�ph`r}���vd=m�z�Sؽw�!Й���ޣ�S�'A?���.��@��(7p*�"�4I�¯,�@K��M���f����	K�S;���Pe��bޝ;�G�4��AZ�,���_���8��Ry�ph)M�''���D�ԏn�t�%��L����R��;G���C���2�'(v���H�f3�hc��{3�iq�u�l�0�m�(����BEJ*�>7pV'�~�|��S����ERۡ��n��)�k��otz@9Ѻ@kX]����ˌ��:�,�'e��IB��M��jS��t�zc ��Ų�J%�
T^��/T�Pa��kՅ���#��\�3���ٿ{�(Tz|�lv�wQ0}�ñ�䕫t^�3�M�g~k*:�2���ys�"JD����	DJ���G؉�EA���	c�>�'y3�<X���,�y�%�����_}iձ��[�?���o��(������"K�M�������S���@��-���-�qj�a,7r�j��杗=�����%���^F���O�Ճ塽�}l�̊�Dv�y���4�lnr)��v#����t5D�8Њ���z���Em�T��C�$q�s�bJq+�֤�>n��v���T\�-P;k�?�L�xx��9�����8�����fZE����:ԙ �_��Y4"T�}
j���q�g�Ŵ*sR��3t����F/�5�a&����@0y�U�F��{�_�yy�h���ܶt�S����m����5��)P1�Es���;+˃\Ѳ1�R(�Qȓ��Z!�賍��^�:��H']Dgw�3(5�-�iqt}�u6k0��*je���ֺ���uB��I�Ղ�y�u��س�u��^��ǃz��j�3<X`(�@�۱�t�
�A�h@�=�P��,
a�~�6j�a�(���d��τ��5p�I[]d�O���Z>���n�#���:LhA����U~��g��s��P�f��#>o��T��8]�L��ܙ�C&�����`,kPXդf�Q�`��/�L�ds��7V�y�:²����5�6%��P=�1l��<pz���_�,�Y!U�0��tZy,�̅�_��zB|XZ��F$[xd�����Ð��Y�e��;t��[sS���vj^�`e�hQ�������
�U�����G��~�����Z
�����iL5Lm�@;���"�/٘J�T�N�
�yҒ�]̛����5*5�<��>��G���B+�����zo�"E`�@khw�(ߗ��;� �7��WG@L񻃾�mCyc��>69Q�<��\v��'e7'v����;Q<5��VQCcI�m ��k�S=�" �iͪʌ�~��H��Eߐ��3Q��q/dDdԾ��w���މ&����ҳ�Z�n$$&�Z
 ����΢��"3���pq��e{)����r�wI��Ģ�ER�Q����(��й����T�Z���t�Z,��M@y��߲�ɡt�l��:��Z>Z��|f��uX��x:��"��/_��H�����@5��P���E��{#��W!��{&l���~���%��aXf��=t׆�� ��Ϗ��n?��*,��c�B�r *�	��װ�ⱦj��*�=E�
Z���_���Π&td�#��y�W�3@a�3��O5\� y,�����=�h��%�l{�����ƞt�Fb_����d�.t�z�i9S�{m�:��-#M�ۮ�@N��{��O���n����)DӤ�Gy��h�%�x����/C�fk�C�k��$ ��!Mi<���l��P�K:S�����":�Q�{���Ỗ) "���`0��-m�82��Î�70��}K�A�
�Q�/�
����ѣ5�fk�Yg��K,���wK�(�h�IVS!(���Dj�58�,�=u-Xy��s���{c�#Ц��Wne���N����kPң`;�d�_�f��[O��+�E�ٔGIBt��e�Ӏ�(�ߛ�O�
z��R��6�Ӗ�Pf��G��l���-Ȭ��X��v8�
��[��^�M9!X����#ׂ*T�Џ�i��l�U&�x~WŰ�3<%����z [Xnc�=F��?ƻi�N��X��Ew�n,�SDPŵ���|L˖S��z@G�#.(7�kT"dև�:�@�_��X�r��4�-�ÛȎ���A>�魰`�7�0���>���Č���p�%�F����b�!x>��6�"o��iq�P�@��Pl� "��_po_������ ��=N��~n��s�j������F�̄��q��`.J:Mz_�O��뗛�wH���%"#���_J�`���L�˻NL$[�!]ucƐ+jm]>�2�S3�
)���D��$����<h���?f<1�n��-,
E��c�e�?.���'o>@s)�#��y�E�H��֏/d� h패�ɗ��ߌ��$��nC���a�u��~��<?;@:P��+ԝ"ߺt����J���>tb�ˣB��4F��y�H����A���_�A�� Cܘݸ}����ٲ<��jYRGb`%���?-�F���R�ז����$3���L4�hИ��R�h��[�j��b��b�7 >��垰�c��ܧ.7�D�>���g*�z�9,(�6oڮ����E�h��b~�1<���ܭ���N9*`��ʞ��xXnlԿ�����w�4�ȧd�%�A�&�ǰi]���Z_������M����W�ϖ�}T9��B�W�~�%���K^�
�롬=*��^{͑�?�j$�e��<��<�v|G�>��'����ѱ�S^��uJ��c���f��)a�4�t��>g���밺��O]��Fb��^Q�-Ү2E�&t<��Ty7[�=m��6ߩ�B�U�3���([]K���kU���t�FgWQ
�1g/�<�MӴ����p�D�a�w��	0�&��#/�|��h,Q[ދ�L�A{ƾ��R=�WW*�U�ڣl�q�`\����}�Ć��z'�����K�ךߙ�-��22j'n�,>�i�sJn5cV��}v�=�k��(����ܳh����`�Њ�?"_1��F�"T=ۭX'7n4��P��"�// >���W�?3(�fo��$�|*	ɕ:܃�6\$&=���풟bruY��	�i'@��0q��&d���>x4�N�^���Z�4�C����^"��]��;&ǧh�k1"2e#����Ex�f`w�z��@@������$5R����Nu�e����y@'����<�oiچPV�����,+���{�z�?���F���ҍ&�}���V߮r�3�}��2*�{�7��T�y`�_f8v����m�f�Jμ>��cA	8����&}�ﷹ	��.FN�lut��C���� Q90S�=MB���ѹ�UX��2J����<��$��-��q���x��eVR��}���<0*YJ��GWwJNC�"]��P���V��(7�'z����&�HK`�+L�1ʅ�l��;ȝ�ziw?�^���e4c��5^D�t7B셭�Aվi�;��C��g�����&�3 �{.���0���}��E�cvw������5j���h۔�~n��T �z9#�0�t��v��ߗY�˚E�M�f�n��I���ޡ �v(�_=�w8h@�'-�u��]�N�1>�����S+�s�����uG�s�%����,F�+[,e�5�3�&�T�e�����v�f�| �0�(�����ϣ��T�� Y ?I�o�yP� M��g$���+ʌ;
V�zc���'ۗ�r�W��4�gE����|�l��]��IFl#�����6π~��5Q\�ˣ}��k�E�3h*L2aq��N�1�X�,=h<�)K�
j\�?�-	�ؼ�[x�m���!�S�l��N{�j*�Y	���U���5��u�+<Gs��P����`�Zu [�$�+�M�-���d�;�;J���������)�6��<J�@�AR������tLS�,%'{�_K}j���ږ�t�,�W���������cr��d�$쀷Ǉk�$�j�W��hg���=��ΐ��j5��7����E��扥uXެWSM�|/�	c XZ~rZ"��O,���9�Y cV�J��l�󿻭�����Tΰ�< i�{�;;��T�������w�|jf��8��qg��X>{���B�F���B���{��{4n�f�M��g-7�=}?�o:�v��N��A�i8@q��-L1�?��5\��OGD�M�ך�Ȑ#W���=�IC��Ј�e[��k��G��e�k������{X�rB7��G�(�h�g_�乕�H\��i\|�z�BlIY����=y�84&˫����%f�jh'�ȥ�l�]��!wROU�̀]$0�g|}AC�8�E���R(���e���h��7�z^	��)��8���j�w��f>"�F�S2��鼉�Ӓ.�BX�7[)L�by���۸�(~a�5>&�d�1v��|P����:��O�_6���Ĭ��jD�z���-�)��X�P)�����=y�܅����5�T8��6��tas���cNn,�<$N�tE���x	:�.�wx�f��A]�i�n�C'���%7wtC�nĺ2����k�\r`DzJ�
YX���!jYD|�=�����t��"��2�'QDND�43������­�/zNc�Tɨ��9'���Ty�'�,E4��"�G��
c9����(����d+�	kk]�[ �T�i&��y�1�(��Uyڊ�y�i��8�Ș� �-a\O��#�∐���o�1�#˷e�NULEv�-����`k[��b�f�&h��	|�r�rQ����e8��)�PdYd�		)�s�T��z��Z����k�x�D�c�֡m3��U!��(��rӡw�C�fr-%}�'�ت�R����cܾ6%��Ҍ�DM�dmm�G=�li;����zS��'���RvsgG�r����|�H�6�㛑��o��K�4��y4����L#]M[�FV�X��lnpz[/�d��~��Ⱦ,��d��9*|.s�s7_�b����O�d�/�p�2�K�:��`t\sA�F\!�[�0�Á*t-W���z�r�{�U-;�.��X0�a.���C=��՜����lG�RcחS�3� �������"Y���X�H����a��2	�y�?�]�Me��h{�S,9Jxc��Pd��h(��ÃN�i�`�]��c�c���)��:
�(�x�d�O����4��)E-�W�53o/O�3�ؿ����x��`_�׽؈�@3Y���s�
���e~�Hqp�S�F�qq`���/Y�YMBE�\�|�G�6�tZ�gD*9�m)|��]�}�Q�nY������F�a�m��<%�;%�5]d�bACW?�?'�e���3�P��w�Ӭ:��O�Z[�mǮ=H_��d�b�Ҝ{̭>M$��V��c�sV7���x�(��M�F�ْʋ��ɢ�:vhuxҔ���4{ir��4�'7��L�_�� ���ZA|�1�6�%�/���e�uN`cm���j����P�=ڪD/M���m���X��4��N7�������E�P4ʟ0(�n��c&Z=�u��Z<#Jl83��vӯX����W4C"+3���l�,�o��� oc[���z`_K�^�?�c���D��S��;BCA� 4�[(o]my�9���h���!���>BaUP��,Z��q���� �9�f�h��/�Z�\���7!wL�s�����c-%g�Is�����G��tȿ㯽B�,J�� ��SRu,C�x��P��Q���$���l��3�w�6�D�^Xμ~owRP"�R�-G�z:ђ�9���-�nm2A���g-}^Q��;��pZ|�eS��2�he��ݟ�<s��N��*���@��t>��X����Fw�	?������:�&��g�*�YX���<1�`�˺^Zp
�w>�
��o&l��}\����b�*G��q���ȡ�h{��$�#`�'@a:?(5aY��:����ȜB
��:NANs�' ��0ݕ2w��
T���b�v|RƓݾ��x�"��n�R�=�i��^ø��"T��>Z��o�V�r(�������,�-@j���1�U����f8%�\'�'E_J#�?�U�3���ؼ��0�k!p�g3ro�N�>��ųYrޘ$5 �_[�1�OD����'�;���E(�9y�]�%��sMĭ�sy�� �ë5Cʉ�Iݤ�!��')��&��\|�m(�d�>���w,	�#��Sw���T!tqD�.s^XG:R�Mϻ��(�s�a��|�������oRc}��H0��$-�����C��o����Q�(0=��\;F��k�iP˼�b�WPS��ڇ�}��e,��Q�Ll� ���,!�<o�|�'b�����˻�������@�;(��,~������E}?����:8�hXU�m�G:���Y8jo��:��?���E��Y�}2��`��Zm1�[�J�1K̄1Q]E��K�U�Ee�S��y���y��lk|k��v���V�mR:����6��`�����90��w2�����Ԧv�0�o_~�E�'��7�͗Ie7}�0�د"����hSI��h2�ʝX��Gn9���\ �E\�b�ԑ���gH��W�ߎ�@�j�nްɷ�ijvȡR������n��~�}I:����ҹ�i�smUR�YL�Ƹ�(��:��V�������8�|���!oq�fOa�AG�ţ��%	������O���hHY��`Eb�S$�	yRh�=wCK���,��8���~��A�{�Z�.hcDBc+��X�$�jv��m@Њ|���h�S��(�䔚VS��5�/�M�P�h�߆�B]�\F�z��D�r��fH��MƐ���ٔ5{�+�!u�[�YD�RPG�(����dWY���sN�_GS�"��\rt��ot(H%��wR���XF�a�|����CFpeo�Zɥ�aI�9��,Ʋ��9l�����'�Z�=��%ճԙ�lbA�q4>�����V����,�E���:J�'np�vt�O:쁳�?��A�~YEϬ��1�Ͷ$ȶ���w>��1%k�T-T�S*
eG�:�����/E)����A�S �'z��8͘�(8p�c�9wgg��6 �G�[��m��?�HGTp�<�0�AU�%'�NO��ٷ���M"��/Cq���\�xFE��l'L��|g���g]��ر��~3��U�6�\H���7�y��c�I�YPa^�qjhۆ W]+�� 0S9d�:u%Ҩ�4c�r��T�ڬ8���wH�cE���BZ
��t7�r�s>g,����p���Fȕ��e�^CBn���5M��;��(�	K�� j�h���D��R�)ZrfP��R>��O�o�9H��c�]2��&29���z�*����	:;hc.�G5`*��%1̯�	����ߙ� r$��)�USeH�Z�$$����pB ��!�ޯ(#2�YV-�@w���Kz�CH$�C�e��T����P�u<$��"�g-?#n��Snx�T��Y����ڥ�LD��y��-�OªJZr�T*e~�e�h�FW+k�v�.b�&�H�h�y�R|�G�Ni�G���m1��q|W���!���fovӫ}/ �c�ԙ4Ճ����G]�`;	�A��9�5���cɅ�d9�SC��cM��,<Au�\�N���W��7�G^n�<"		vt������|/���o����'����~���5Qq)`X����^�r뿘M��Å��<lǇl
�9O�Z�e�ߕSM��H$��R�]�����y٥pS_D0&��ac~l,�����w����E��z�����C��� ���,7b�D�O!T�}۶�����شͣ�X8�fS�����	�>�w8z�@�EK,`a0����̷���[~�_g8�W8�Zި�M�a��,p�FH_)7��m<�Z
#��GY{ѯ>^a�MB�ͦv�/��Mķ�CY}�ڸn�����\�iE�a�<�Ę������E"�����rު	��9^��{R�{Q������'���~!�PFF�F7_���$4�G�S+wb	��G{�pr��F��J@��Z�'sh�s�\���%p#���$ȳƨo�T�J���hMcU�g�5��ԤQ��Gm���v���wj 3���~"��~�شu��Xy��tM�Ң��U����!��8�/e�A���X��>F]'ڐ���|��������i��{�%A�b��i�E1�/Ks(t�i3�z�]�ѭ��穼	���\�1H%p���~v�۪<��ݶ���o���}V>���?~i�5ȍ�}�,�����NZ��8E���\�р�mZ�{^�l��V�xʿ��Y�}�Q�0���[T��7��/w ��a�Bű���E���:��� .Ύ�_Z��k��~���ˠYDKfVz�R<Kcx��M�y+�:K���p���Hc�J���wZ�SA�ñ�9������vbq���Mp��r�����1���Xf��/�������eJFrQ�Z*�}���������
�/�k��6�WO��c5]����1�]���j21����Ж�:��bK-�:����RY��8l�W�s�XB̼��:���5FJ�ؑZ�^���y�s�+��Y�����!x�x22_n@\�?3��[�1�[/�i�o��c��e-4nߴ�%��ds�U$?���I��-6�B`[��]w��2z��;-�}!QI[p�b1_<r�w�\��R
Gݐs��xQ�({����d(��80����=��>�d��ux�s�G��W�Rg��&���|c�Ԟƴ	�BO��NC7�l�:��I��]���3A�4)%bP*x �������r��X�[�u���%���
E=�Q��� �(fl��;����hPI�
*�o�.��6��󲚂WFe.�gy
������ۄw�$��ό�AԎ�@�gI.�5����'���\_v��È�CW�~8�Ǒd7�]
�i�����q��>X,�����z����\�.��x�����'� ��b�N}ل� ��m�9���Xփ�����4:T�H�W\a�>F<�}�?�A�ap�U��G��2���K���_p!�Ko.P��R�$�w�k�u��8��51W`/E�U�<���x�NyC5��Ą�#�%q���A�p�v�t�i5�>'�^f�|����4�wE.@:��ܿ��p�w�dS��\�S3ͻd	/����	*�3�oI����|�m^66jv��.�,��W�#�4�8����Ç�9^;2�g��!<�K�@��D�v�WN�����7��k?����Ӫ�Mp���0��7�i/KA��1�ȭ�rx���W��tY�kVy�=Eu�����vj~��?`g�bQ$k�� �5�Y7W��9i�<�d)?�����$���������q��`�+K������eT�V��6����g�������b�$���4��RlJG��`#���H��b5�L�ھP~�#�(���ppܢ����=��[2N�$�-�jb�R�{��+لm��=J�M�>c�!´]��ϫ֭�3��fhm~�c��r��9%k�Lٚ�U�}�rO ��Mb��X���� �%R>�m�v��v�X�"���	�'j�W�u��D�����a�
��qJz�:3OKp��	3�Sj�?n�d�˅h���p vTV�[Ϫ@��Kؐ��~�MU��W�(�A����!������m���w�c�1um�c�[�5=��5iU^jK�mPlc؏�o���W/��v�>�T-�0V
�C� ���`��庋dT�8(n25F�vGVY+�_�m��y8L�%��|��|���8٠D��7�ɡq1D�Rw�GWS��_�!�ր]�h�{fjm���������)����#��8
qr��W[ƀ�A�.<u�Մa�p��j��ҏ��먐��Q��*oKM�	�R�8�:Hw	Er�|�=�z<w[����3����u��cwo�w���*xq�?(�h�c
$\T������c3pzu8&�X{yVl����ـ�LE��'r0��΀�JΆ�x؋ع��F�mi Ŷ�� AV�����{��^���K+O8(D7��'d����y@S��&j� �(���K�M��)tܚ��C�&�3Q��m�c�ĶO{�k����{7�SX�8i��>	��f�?��2e�`8b�/�I�������0���:��SH�:�� ��~o�d8}�����p�,R�%���jn�6�)��B�g�C�a��⍽y?�V��@�祠�;[\P-�����J�w$�����Ϲ�16�}0F�b0b�����~\2xx��8S��q�sŹ���!���]p��Z~4�G�"�qkܿ^w�9#�
�����Ŭ.�������ۥ)7�e�@	B��G����`�������l�ܙ_Jdx) Ⱥ��
ӏi��:��S�Z$�Ig߉��o+����lmFo�_X�ܾ_���ݬ���]x~Cl�#%��v�o� ;(9(8b�)zaH��"f�>��^u��乽��1��8��('�+��+��F�B��壠��1����21��J@L��H��V<�W�|{�ވ��@�H�ee!l�1E�s2@�k���!�6�w��Y:�T�r�Z~�q}�3��|"���t��|Kŵ����@+��=/0՜v]8����~<���]�}�͏���G�1>�\�C�0���`�P'�ʲ���Y3G��}O�~��I{�,\wx��6U�p��py�C���X�OI"�ek��<)Ź���R�+�&-�xi�M6�A�g��_]=!��.�Y{����3�����ȹ�}.�7����Ҥ������/�6>`�[��L�[ZI� ��.�G��٩����NV���/�9	�=���:�]�hj�A��\%N���5�$~CǅEl���z5��`��d5
�Fe�ܽd�]����5��:�q=Z��Mms�׹�{	��D�vH\�wn��杻��@߭Q���&O]��Xz�" |$��N�L�i� *��)l=���}�O9�
Az��m/@b��<�����Qܑa�os�я��ވ�Rz����YB�� �K��I��y<��oO���v���}\�J�;o״���j��Љ%#���b���	"mj��'xN��c�� ��J{���G!҆���5�qeeE�j]��";�յ��
ξǭ���d�n���/p��A��
���+1�b��W3���J�|�F�kq'�'�P�0��N�Ja�R'�����>!V9g�N\j7j�S+0>��b�Sd�Lq=���g�}���oy��ν�څho6k���5�	BħS �t�;�͜���#��;18)�"�VL�{�P5��KG~	���ë�#�D&�K
E妙�Ońh$�G;�fFa/e'I���"��̽S�?V�Ny~Ş�,B�����Ι�Հa�ڪW2�y��p�w�D�k�uv�Qޯ�=w��&�h*��-^>`3ƫe,Cſ�r{ a�R$�f��*G���i�7j|��hw�h�QF��� ��M�uP�VZyq�>K�&�K�n��G-9W�5v©Ms�K*Q�5<<��p.�frk����w��o�>9��!Aٮ�9�ø�I��j���>P�]�h��)���ɗ���Z
�y������`ש��=P
F�&��:eN��w������ �P3k�j� ps�&㸶�a��Q��{�?�0�R��w�%��h�S�ִ16��Ã]�S`$˦��Q5^�����;�2V�D&�䣣� ���;� !�� I}�e�dcM�����P�3t.Z����^(�BW9��$W�
�T:�K���� K��y��WcϾv��y8l骻b_� ��w�I��4�U�������:����M]j��g3p���jH)�r�2������t����ljv����T���4HL2�$���&	�3m����߲�ƿ�\n9f�q��8�w����a��fec܄W����tMI҄����զ�M��p6\��E_@�b�k�V~?z��"]�M|Re	��n/��eP�-�.��9����&�[c$� ;�a��m>���r'�"w��)��K8^��0�{j��`�G�S���;��4UH�%}�*IAU���P�=x��Ե�M7(I��܊��yu>AD�Z ��f���ܛH4O,�W-�u�e��3�r����&���@g���AKK?��O\��>r�Jk��?2���o�<��9���G$��i���yb\=(o���'�ė_�nX��&��G�I��`����gBr&�3�p�0��\��n��4K���t9h���-O��zc�`�&h�9΄�E��x�l	��	��v�cv8�ޙ3X�,��6
�a�F�$�٬ ��ڶ�F��O1���*�����t\_��H2,g�Q�e#��	�=s�i8%2��p��9�DЪU��
<DHf.&l]�S��I��z�}�,<NDs z�����G9'��m�{��J��?8���/�bf��%n}��]��都J�P�4#�_ttZ�MH����ܽ=�%Tq�ހj��5�ʈ{�"t1���$�/�i;T�����Q!��f�����b�
N*B"��`�����+]����r�:�Ȣ�w��)^�M�P�"���W�3�� ��t��S^�����i��j�hڹAz� kdMҥ'�\-/�uS�n4�����1W0���ٹlH���~��ղ��S��G�ıl�.��o�Srjp�@��4/c�I���02�8X�_���CR���\ ^�t�6���Dt��/�"�o+R�����Õ�B�ׁٕX�uj��������
���TԒ� ,�)2g� Z��p�:���DOq톋S��Vy�`�)Uy\�]ƎU$�';���=G&���~���$&���Y7=K�ϐ:�ŤsQ��ؙ>%Ϸ;o;b+f�Zr1�Gl%��|�jKo���+�騂q�N&+�JX�2ơH'@@6��<bx���<f�K�/9���.֦E��EOɸ����<V&�[,��䧃�Ԋ	��xU�ܑ��Q�����J^�Ta��>y��o�7���k�\�ōQ�Ъ��3�ۧ3@3j{(R?1{�������qK�l�Ӊb�::³��$��q�88�:�f�L�E�8��:�|���]{˿(�*Э��/�g��HO�ekx���" �F�=o�v�B��jQj@^����@�!d�_�}uuiˊw�+�����<��S[��̅����AS����͟�����X���c`�حz�Q�K���Y�:��;�K��t��8�QF�숽��f���b
�݇ڧF���}��=�{�a����8A�*Λy���_�6(�[h�w_K��~ ���Ӓ��[�(}��pY@�X��#v�s/7�ә��{W��*�e�����z{2���"��P�D�I�_�.�c% ��j��(�n�u�Yg�':+%�`�l�O���O����^ߜ�VM�y9Dmw�כg/�_�����N��`�C��y�T���y���j��C�U��\�h�-����_�S��x�A	Q�W4�n����� F=��ʨ��֯1$,��C��$�M��=p���~A�f2�@5�N�=/E�R�����D`^1%R�2w�v�_�#
Ǆ�A}��̛`�9�ɝ�G��������;8���,�ÊH6� ��JEq�� #O�%��wHEuv}Ĺp"��wJ��"�_�����eaX��V�~�1?��X��4ܠ��T��~96�ҋ�Vpfte�2L����II?�Ŵ�aeO� z/v�Epp���� .��)���L���t �	�ˊ\�������y0��&����w������f�!Doζٴ���ìY���':ZiC���D��Pnd���K�i�,ı�UPQ�B�GM��|���wQ�����ΚP�Bb�Ɍ���l�ؑ����v�������e2͖�����Ph�h� �\Lz�B��!�j�蔺�M��Υ)�`�B�~��T�� �|N��9��&T
��M�)O�z�J(|Or�����K�p?��A�r��*ͭ����F����ƾK�`4�G��D~�џ��Ɋ�$��@Z�"5+y1?s6�pE��ׂ'�ܬhk�~e �AqCY ����p����a&O�F�����0�E5�f!��7Ɛm뾡�V�r�E9����t�ִ�))9$Xm�7tg7����iR����z�ė����J���"��2���!�i����)�d�P��(E0	 J�瀯et�z��hw�Ӻ��3zu���_�w)P����Gܵas8�]R��rЧ�/(]�9�^��6��������
)ډ��*A�!eF�u]�)���Op���U�m˨�q��iO����I�R�!�t|u�(���N��M�{�T��eO=��b�0�[����P��b�8(3��@4�-T�r��l�����WnD��Ki�)����%��#ZH�l�:?&�;�6�?Yw��m���vJ�VG��8�B�.i�a���h��6��ud�g@-���ȫ>C�GG�X.K�wk���	c��$1������`Cy��3R�״�GX#	ׯ�_��%��4� ԛ[���e�%��j}��]�*��M�Z�3�L.?�Q��h���Ig�S`*��Y�i?�4��%�u��F+<���w^�& �ȁi
����{�.��˝��ˊ����Hq�,ogjLi�,�#���8ʦ�e��x���?�\l T0B�h]y�(�6�L	y��s�k u��h!�R�� 0]`�3H�U�q�q�� Ї�L�o%,�]A]��/p�(ڪ�8Bl��f]l(����r����iMJ���U�[ʀ�<k��^�A�Tj��Ayqb;���~�{Ƥ�0�`�P�f��X�G���*d�
��My�"��fӶ�(��+�!�u\�{��fO�]��+z�ƮHi�Y��D�i5gD�ӭC0��&kB"T5��dI�db
�T�ViZN���(iҍ~��Ym��r4�B�(($/��s^OOl՗L��N�s��z`������[��GqF�IL��JҮ��J&h�D'���/~pW�I�VS�N�X��(�3���SW, �#둬�eZqMf(��&t��*6�V!?��K�'���1|U��|_���-l�Na��rs�NȀ�7_[�[)�P�ہ�l�r#?�a�����_��Z�qN)p�����ďP�m�e�|���V�4b�eW�F	�/�/�j�x��e�4�4�J�Ib~�L�(/ҝ�i�྆�7@�{b /hݔ�S����~�44�\��&yާ�<D�2%�h���n�A�6�~�GV�+&����8����/��p*3e:��K�����3��K��z'3��^�7�y<;�WDx����-D���g��zp]T޷�ր�ݲ��TI6��	K�1���k|���Wc-Z���b��_u7���WwN���h^�%���N�aaH�U���PzS�C��3���1�l�͞�����0G�?֩/��V��<~2��RT*u�E^!�t��D]Z�⊌�8�5#D�)g��q���w2~��<�m�l4-�7IoQ(�I:1-H#SP�k<���H�9�&���ެ-�������L� �1�[��gM?��E}uz��(fn���~,l(_�d]R�)߶1�|�+�c��^2|i��;�m8@	#���������nr۞�\Yh���3��8������jrmp�ѿ��Q��xE&,�jׄ��Ͱ[B����Xp�����i��W-�!�3�7-b{�L$C��}����Z�a��]�}��?��yXY	Xnӹj8��-�˶�R��2��us@kT�Q@�V�%u�f0{I,�)@�Ni�q����ܸ� Eu����)����"O��`�����5�ةR��G#6�6�M�74?Bʃ�A�b.�~C�_l�"�M <��[�3����xP�1g�� ������<��if����*)f�ʐ.��?&" ���/�x}R<�$>�R��&�&.|m����T�5Ģ獤� ?.��sH�˷��"�j�iiQ����J����p&��H��;h�N�t��\Ꙫ��[%#],S�2Ob%���"6'�AF��| f��IIP»������3Bܫa�-�A�S1��&@��J�W���IݞB{��%z�?���s�+�+@�1-#0*9}g�K�I$�Z���L��W���FC���Y��Je��b��p{����E�1�I��5��qT|x���D��i:�ġ
{���Ŧ0PI]՟�Y�. Ú��u�/��2FDI��I�1*����_�s�)��	�iM�ǹT��x���e��gNr��
�2`���I'�_��-J���������<D���>�$`���s`P�|_+x����zW�t�a��&������i[?���h�Ui뵬���'��Fb��K��/��Bm��'L����)W��,k�l�mJ=p���??��)^ڽ(�M1E�j�{�H�����<ݬN%ڼj�Y�Y�*��.$8�Uh.��S��8�N\���-�^2t��*i�̅�eo�ƛ�IQ��\�����\t�4��*��e/'~W1s�33Du0�z����p����;���ӗ�w.�m�y�=��oT�V�/tm�z��t�w�b�Y[<�������O	�ȣ�Y�GU��c�]�u�«��7?�U�w�zkM$Jxa`�D.���&�$�l�:҉ͳJ���a�K�
͂�И\\�a�f}8o����q�Ė�@�L0nG�v,��4��~�/��BƁdȕsn���q�/=9�$
�nL"��,^=��QSEt}ӵky׾�6�v�����)3&9�7�w<�ml�)�G�T`u!E�>܋T�) ]Y��7��T�s��x��)ZS��S	B8�Ìd��PH���u8��헗�tɢ�#&%�ߕC�w��F�ֺ�a�N	ܷ���įx�͔-�~g�k��1�e�T��?C�����ك/�O�g�Z$���%�#g��x��XM%��7�tՀ-f@x�k�IU!,�-���Dp
.�#9+��ή�m���N��p9X=�j������8+G��\q��N�KO���)�N��]oW�k	_ �\�?Kq��p_���b����F��@G�f��>��z�&O������j�6���������׎f�\�i�v��n0�P��A��u�Ho�QGZ�~0�e��M��4��^�hP$:�͝�=�f���񑿮�ݲ$ٽ�G_����, ��r�?���$1ں�W��h���#{���&]3�_��!�js��h��8��2��ag5(I�z�ƌiхzG%�����&�68E��x�X�W�<!p���D��^�kn��2�EY �S�Ug!�<�#!�4h73��W�ٟ���{xC<&�����.u4��B�g��:��!���3L��('=�`����;!O �	j:z��(0�*���)fҲ��p7ψ����VEs��ׁդ�>��ד(es��˞�n=�@�x��1׮�Qs@��M�\,1���n����m�>���~X8%k&����8᳜bk)��]�O�[:��z�U�QZ8���Q5iUvBs�@Ly�}Tu�y�ߒ���Ղ\0�����w<F5P̫�MzD?���6�K@#��g��z�����||����@�-���t<���VI��p�ȸ��ֳ>�.��a�Rcb����?��Ƿ��R#65>$�n޾H?rK�jOQ:��{K��N���-i�h0b|s52�η��h��/�d<Q�=�H9�D�7�Ӥ$�6�|�4��G��3b"�q�M9d�L��v�n��|ꈁ��q2^�U��|������tm����*� �T�KH^�%Ʈ^<y4ŉ�C9}XNj�?�,Be���ӈ�5)��?��zB�{����3��J������cٌ^K��]"C�ɒV���K
����Q�с��kKx���W��l^n1Q�M���{���,	�/�7ڼA�7��5�l�N"i0n2xk*3��a�1���� �(25;��s̶��&�b�C`��´6�ٞz�k���`_s�%[y2P3�4.ŏm��l�On����>RN]���'��iҀͶ�#UX�7c6��<;�c8\��}�x���'����"���!��d���@�eD־�q���\��}8f _�M������q��[�N�3V8p��g6��?��^Ǖ�``�\[Y��p�D�%ʵ4o��b{;U�+�TJa2&�E��M3��l�a,��O9��h=r�w�����
�;o̮��KA%o��L7��_M�K\����85�b���us�`�xC8�6��7���4��v:Z�NXA�B���Ll�j��;b�cn�e���(���!��@Ϫ�xe�]_�r�C��I�N�#��}l*��Pĭx�3ZB)���*b�Q������hf���F��٪����k��U��X3���+^l=&��k��6`I��R�vZ�÷Of�eYޱY�����H����.�T8�!	H� �z�Wބ�H qBu�k��Z8��K\��o��˔)nF��\��[u	�r���#2���7��D���\�������@w��F/{R��┆�4ʂD�s��d�ޘ[� ��C2����r�vO��7�(�5M���5#JUK�H'DU���|a��H!���g�	N�P	T�K,��|��%˚[��J%�D����������&�;I�
W�1��T]�C���u����8گsR7W�4׬�!�r�J��SA#?If�����%o"�S �Y�B������Br��j��ְIH+Ҽ��I���h6��ܶ_�c��zXr��b�h�%G?~��!����y';m~<A
�����Ia&�u	T�HX�fx@�7�ժ�`%���s���L��P��������v3���-�հ�U1��=$�Ü��,L$,�,?���X�S�C�PM���o��k�>��{a#gZB�9�ɘ���6���מ�FTgB����e4�DF6j�l���5�ޭ?Sg5��i��IR����ܶ� ���D[��n ���f�SS������
�%��������h�"���m��J;���|��ĬER�a��1+�"G]�qa��ɾ��dӹ�%O��`���j6(��0��������*�-������2�f��+��[%�|+�:MN����:�4��s�1ҽx^�CBLȤ�� :�e#�Ox��"���H��1�k=� ����G��2��%r�{�BQA�C�u�j����k���hp�g�#��Y����|8�<!6�u�����q5%� �\���a�h�_�3gEz����#h��Ƹ���@����4����y����#�j���m����puT0P�ӭf�ԅs���H�)�10J#��9��-��Id�GE֣9����g�W3��„ςJ�{!8���S���+	ͽU�=uؑ>Y��]*V�F�gF�a[J�ɺ����Ȗ���\�}#����&|��������d1˳�bh����9�O���%��,�A��`Y"��Z�Ȩ��O�QqC=�J?�Y�W�]d�ӌ��^HV%��MQo^zd�/�!�p{o޷����.����03{D>�d�aG��o�ZZM3_7�,U���n�ՇEۡ��:��KK��?���,�@�~N_���=H˞+y秝���Aە\��u�D�Ud�zqo��ڀ2��R 05���-P���G��x"���Sw�qjp;j3G��=v�U���BQ�*/B�\��<���~��:y�a���#RW�`����1k��@gZ�����j��Xؔ-��m|��.����������Wz����6��v��|=��(,���R6�t�5P�D|m0�1H��m����(�J�$�b߸73Ǝ����8���r�d-Q���a�$N�?��Լ�{�/a>���Gz�b���>+���Vc��[Z;��5�yQ�T�$oO�o�Nq��К��M�>���N�]����]�#�z���j��
%!/ƻ�'2!��ܕ�"��f���3�ձ���/�Ȇ���E.t\2]d�u�׍�<���������� ��MIe7����w$��Of�D|�Is��k���Zl�,�M#�;Wz	���QF�;8��G���Mɛӏ2��������P���B����86?�Մ�z'�j�<�a��lm��pP1�r�0P���i,�K�3/����6OЩ{���	��	��v��g�����	�ői�u_c�6���7%��dEg�$�-y 逢R$k�̃��>�F�:��>��M���(y������Ys�S�%�w\�����������n]�63������g�����"���K�=yy�&��<�!�L�s�d�Z����=�9�ky�Q�;��<��z[���xe�K��V�3�����E��__�<��U(��*6��CI9��¾�@�4yEh�"��|L�u���%?���Bx��P����=}�-)ʋ�������r�grWZ���R��Z��8|�f�Ia2E�T������C2�k햏�J
� ��$�Fʬ;B.�lȥ4Y�G����Ab�p ?Y<�v��꟝UWV�������ɟ~�V����#�������~h@T8�N[����6�Xq���ݯ8(%�Zێ�ݔXssX����2q3�۵�$Zf���Nu��$�𭥷&���n��%doP�������7�,.,�-�枉E��ҷ��h�)�E�\��h�b��ٖ)�B-h�W�4����4
Ut�	�(/�X��J��j������b���q@�GM�nb>�u�Ҵ'`��
�a�1���Sr9oy��ΞY�ޗ0W{�ិdQM�&��p�n�?c�5�R�]5�[a��|�oVFBP���7D7�O̎5��q����ŀ�V>ҽTJ���ƺ6�然7��s�9H���;�U��[��)"u�cR�
�R�>�1�� ����p|�T�=�����I�q'��0�	V��3� ����ꤩt��ã���_����(�gU�<N
�}���{A��-y?P��*�i�Q�%��uYh� �;���׷ĵ�ވ�\1X�-���~�@/��h�n3��o�ĎzGѰ_n��y���y���bm1������H�WXP�<W�����%�4�PX[�@�2MQ�NH^Ύ����Y�����in^��6���ݵ���[�����������T��7���P�7AF����s������z��GO�X���E-f�ў�C&�^Ik���9Xߏ�-�|nΉ�?>),ꚣ�q�=�,.�m�H�0�>XOr���v����w �;d�@oX2K�w.�Ip��KXm���䥚�d���7����%�*��=!�� F�����    ߜp;��Q* �������I��g�    YZ