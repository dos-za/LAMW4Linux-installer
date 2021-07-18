#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1364632743"
MD5="c89fb047e414becd04d427cb7cfef494"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22604"
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
	echo Date of packaging: Sun Jul 18 03:00:51 -03 2021
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
�7zXZ  �ִF !   �X���X	] �}��1Dd]����P�t�FЯS�uc�q���Eי�'��9�$�Wq�$P�����9]ׯ���H�~������k�U����dZ��۬����@μ��������̕m�H�����e�6���r�Rs�ڬ"��<Q'*�w֊t�_ÛPm>Q�'k���m� 7d:�͜�n
+Km�_F曣3zz�
A�qC��}s�Fʧq�Z:��U1]�q����3}���T%7�j{%�p����Lx�>80O9��]�cߔO;�]xī3%r�9��&�I�"��6Nw���1f���e�o%߂9���j"��[��[�O#1d/�j2� �w�V��R��Rj�z�O�j�Y���ǯx�i�3�R���w�(�(�U�%�"'�RN�\�p��D��,�n���<�H^���@hք�-c�"������h�Kg��-T�X����Fa_	@�;�����y�N�\������h��u��G�K�)��D��?ln	R���D�����!R)C�V+\ ӸT���V3�U�''R�f�!𸊔$�	����:��`׾dmi�!�s
���}Ó��-K�ҝ[���:e	�#/H�Ҕ�ʻ�je���۟GBnI�������Ham�N;}�r̨�rg�L�ȵQq�9�%jtC��H�M��خ�V�ش�
����s�=<�q��@���p[3�W	��YoՖ�h,�M/Hba�{/�㱭��sD��B@#��UP�v?�|���N4����hy�F�밝͏O��L���J��91S��&��^՚�ZC׉����&$ϑnLr�g-�/��jU����S�����J��`?.:WG���~���@� @��N�	�}��=������K];쑷��Dp�\�M��S;G{�7��H�H���J^�;��ܣx=s	+�?)�W ��x;����ď�g%0;�S�_�r[]oC���s$�JFQ���bܳ7TEc�C�9�ڽ�*S��7��lsԪh����d)��`;�e���u2��R.�N�@4�@��P��-a?���|�<5`��|V?�+J�$_��<n=���<u�h:4$d���$�~�Fp<�������+Ҙ)>>'>P��F���R6�;Q�-��d���ࡺ�eo����W�&�\^����H�3�aA%Q�� �s���ц����քc�N6��J�GB$1���ke�J%z�B`�v��ɩ�`��B���~��F:�m3F}zI#�F��U���%!�!h<�i'R| ��Ւ��=�H��S�:�*��
��7^��AO/�N�~\,Jl�����L���d��)��3r�i���%�)�Y倨�k�O-D˞��?7{&�f\��ߪ*a��^��tg���m(���a�U/�r��PY�K��� �i�-?���G߫�]��RR��V����rp�ݙ41�8Ȯ�#b�j�)�O��.�?���3R׈x�W$.ЩW̝^���w�,�8H��cp0�Rk�yLvk:�Vvk��9�j��K� 63bM�t�դ���Z��t��{'�P���i���M/<v����X?a��i6��mA!i���LsӨ��n���$�򷌇��P�V�@N������AfO��&ۭ&W���[�	�8�AnE�6C��:8�ͪ�(���4dŁ�[���e����1>s7,�M$��HRSx�a1.`���y�P�8��,Y{/�Jn�|�P������D�>�2@*(�Y��d�J��)�~����#�q�h���"22rq,�H�����m8�p���f���"���I�W�ȗ"�x�k9��x�ǃ�̋�pU�d`�Y�`���tӠ�(c���j%�3uX+V\�����m9�2������Ǌ�^�P]�P[ή4��(��#�
Ukhq�|�V����2QA��V>�1Ycx���^�n0�̣����(��&�	����������.;T3�=���{��%㕞��m���lI����
Q���J�;ʅ~��`�1���B��aݕ�2� Z:F�v��O�O��y
��D>R��1�mj8T.z�6PNǤ�����@�����#1'&��kI��'�����'}JT]���`��Ĩ~���`�L"z	��!�R��<e=e��9�9v+Z�-�����p-g܌�]��l8���>	y�-��,���b������蜺��[`$������I%��`|�?Y���L�@m�Ŏ^-���/P[[P}�׌�����8�-� H�M�5����:��Ҫ�.P�Ը����%�g���Ui7�(��o�Z��Zd΅e6����N�KQ<�ç*�!wu�c�Լ�K��Ƀ��
S,�[� �G��˸v�5�ß:�Ğwm���b�k�j��GŪ��rdwJ�{�]'ap>��U�����oWNb
Y��lDr�9Z	�324�ߨ����N@Wҵ�S����[�a:�y8�I�&,d} �w7"7�ݦ^e�[0�"���zC�]`����ED������~���K�lqN|P1����i���N�Gi��//z_9ȮE�w��6
I�����*b`Zr9�L�AIO�X$���(�k���\md�y�=���������H,�T�� �������C��������,8�c�:�q-^F~��k;}U��!�d��c��ې��fw��|<,���k�5;�/7/���?��m�����s����/���U"�b��6-�ȉ9f@��ť��m�]�9�t�C��8���Rwtl,�u��exĤ|��!�ʯ\�n�-�]����X�\�{t��Gyp<V�|qGi�"��bj{�Z��o� �wGi�����Q��
Q�D:Q���Y��U�D76/�NI�%���2+#�5۲��GOK����������V� ,%G��X�ءe�ܭ&��F}�f���5^�FN����8��j���`���jާ�a�烥���|OD8��L&�y\X�v����*��$����}\��.��V�x�����R�����nv��&��B�������X�Y����Z���c��p8�e�g�*�6��һ�yRhku�Q�$#K�Z{�����8˝��ˍjTc��Ƨϲ9�~Ī�P�|C;R��>n�Zp�Պ�����-/�+��E���=�#�t
B �^wUމm�]�*ˆ��k���V^����\�
9��`�ˏ��K�U�����	"�x�1�3�����@�nG^���﫿���kO�=�Y'��Y�j�[��Q�GbVW|Ψb$/ݜNH���*B�@��%2&�n����	A�/e��%�����᙭Ƥ*B\�2�m�."�q6�=�ީ9w��e���M�-�c sj�:74�;HU�wOt�o��ʫƏ�zN�0�Ջx|g�j2��0N	N"������1��9�uv�\4�������c�A�0j0���AȺeod7 Պ�#�����ǁ���̟�G�xX����{�SP2����:m���!��	�hx�=���`���׌�C�G�Pl	=�������6uQ�f]H�CP]�:���EN�|����B?Ts�v�쎰���[���F��`���qf"�1��G\��Z|�7O�r�d�tyo��q�м�DlF5��e`�e��y��S��fSd�]+��+1t�t�a�D������V��3`�p�4#j�e�Ѥ��{a]�!z�O� T˰t>oY��J�謘MØw����c����[��`ߏ�?��.�}�d�x��#�m�Q�L���=C�MrG�h�k�6�TmvdԪ�,6��5�7q'�3/}�l��^P��N��eL�.(>�(�Ĺ���^+J��D%�l�1�;w���?G��"�o�0]K�h��t�����C��2D� >vk�c�Ql�t�b'��أ��� ��A����7���q��ݕ���j��sd����8 ,8�
�E�h�Z��V	{��(R��B�k	�&����a�W�UL�����eH�}J?g*���$D��=�`9}�b!c�ᖺU�|�o	�=n@�Q.((�9�uy�ue����;B�_44w�}��ٚ�WW\�~#�������{��x.~��L��������t�ly�|�˧�K��")�t���	W�8JZ}��*>(��4e�:��I�HyX�~���iIj�2܇S���=�7�JQS����%��OyW4��q~9Q0ed�w�%�r�O����w��t-x�g&*�,��w�j�	1�Ҍ��sk�<��u'˺�ne�S�wf^���G�v>�%�>"�S"���j�Dl�Zn�JƟE�2:Y8��%���	ژ�N�V)��孛EX�Ȭa?���he=C��0|a�إy��j_�(G�GA?�i���'��/y�wk�m�L4���jxx��> H�`nr�׾L} W��gyG�_u{��W�G�U�ڬ���3��#RR�1����Hʲ���Ǭ�&�$���mW����R�Q�}Zع4[?*�����lr;�ͫ#pUW0��:���"7I��db�Ya���Px3���K\�q�Q9�}��J��|!G��QL�K�kc<���$�s�u 3X[�T��t��
{�_5�a�o�Ά�C���вn��f[r�lçU�Ǻ���a����[$�+�>�Y����|�*qfF:������?�(�B#Ή���0 �?�h߷��m��	�T!4] � )�&#�oF�!׃���J��_
�{�g�N�_����񨦢�nԥ\�~�t�>���9�Ï�էo����!���yp�;̬ܡ���+i���'��W��$�Kd9 �g9�=��fe�4&M���Frwa}�0ɺP&�<��������U:�����i{�u��$�� P*��C���ݰ0��&���|*R!icQ���}��O��D�7����N��D>j���k�����A[2򍇌IZ%�#��6B�NMy�?��֬�ӶQ��mW&|��l"��c�[b�"�ǚH��CH��&.�§���R��4i>�W�����m�3״i5�Q�!HL�i�mpJL�߂`�{�]�@H�#�(p�8><��g��� �ܣ�@�6�i�D^�H����P��f(w������'#�U�/d0W�Q@�+�C�A�T��\oo���҉�j���TD���1q�#�5��\G�" �-jm��S\0��č��n��6^A���D�r�^M�;�C!��A�
�"`����7S�����7�B.u�Ĵk�m�n7�BI�~N��D���7�b��0��_��8����OȂu��*ة/��>r3���QtrIFo�5����p;�*�On�*����o��YU�H#��}Wv�T��s���	Ȟ�M�3��Ж_C��P�W��*q����r�P��7iq��Sڷ��虚�8~"��H�5uZ�N���	�0��p.�$��Ւ���z������&��s�f����H��VV.������m@"�"sޮY�t��l��=nIwA�i�E����,�����_pPSo6��\���){L�FV��ta��U2Mo���U3�DW�,&�bV�@dH��2tW�*X)횠���jz%c*0��O�6ц(j��ȧ�E������\���������
��}�\�o�Pc%m�k�V�h+����<DOf�PG��٬���<E%��/XgT]h�ޝ���<�B��n��ݧ7�ve����B�Պf�zd�⸴�A���0
Ɲ�"�����M_a�6�Ɗ�4���9P���퀀���q/t��;�����>6�h\/N�]>K�r�1�OMy$l����^�:��g��X05l6�̃nˮO�l�WNZWL��Z>2p�D����r����@7��	�ɨ�''h������/b!�͆��Ϗ�\��Z(7Z�cLƧ�c��뚯�IA���39B�f���(��<q	8N:��Xj,?U�薪�һ��� �J�˅���Z���y����)E�,?���(	y2��2b�ON[�(����r�ۛ2�C�	����|��c�1���H���_�%�IרU��E�c=���qͥ��T$�ӈ(R�aJS�y�<4��=>9����9߽ڥV���F�_���֬�m4�;��cTah�F�kA��>����?�*t} w�)"����Z�hO��v�j(^B\B}b4S��)���&�ВR�!g%������h� �P��Ά��섆�����9G-w�}(����^�)�t���Ј�ֻ�.&��UZ���}[�{�g�����]��O�9��4	s	��*��pM?g3�ߦ���f��3	�w�����(bn���t�1��%M��XX�^�^"%��/���=�����2������=e��=e��ڗ��4/l�@��æ�f�oL[�j��`NI�M��f���"�Ҟ�_�~8��ը���P���C�"ޅ*~�0T�h��ﷺ3%L�dʶ��X�>*�Q
�d�g<U;v���.����ne]M�f�4B�[�l�!�OڰH���T3�JǃRuƮ����'Su�z�a���Q4u�"}}_'��s�F+��!�s��p��镤͆�����|�1�ԡ���F&� Q�=-9�@w��uvV�x�f��٬Fo�����v���"�9.��]K��@\o��S��d���"�_Y�c�h'j����蒚<�05 �jT!�V��.4��f�pL�ʻ'�d����J�N{ٵ�x�������5.�� � >8��Ժ99���&)�^���s�pUp]Ɍ<�=�����^�G�}0,>����/�&��IRд����PS8��]��nȽ��&�tl��ހ�b�`�;�,�7�J��C���e�}M0K&�R��H_��VI�]���4��[����7�� rV)�xu����v��prؾ'��0��� �آʜ�X�P�2���Wc�%�<G᠉ײk���Z��׼]���\�ql�ܿ��z(��uD�<Z,�~���!�]�02k��ã*���G�B�t��t���۲�X:6pj�u�e�ɾ��>�$E��P�1T�|�Khy��Y ����)�J��lҭى�
�l8��^�M�PM"��}�7���a��]7���Q-��qҿO�{��^��gÕ@��{����@ᐎg��Pg/e4����0�B���q�o�X�/>�X��5�[4����H�w�B���"Z��K��U ,p��]���,$=�,2q+֘�=�D��=2[�*Kd��hT]\��ׁ�F	Z�ث��&&�b!`�p�(�hW6	J���ĸ2,�����ۜ��k��M*�-�%8�� P;�֐�L �mJ1r�s78�@>�LM�Խ��R]�F�j�~�k�B'Ҵ�avѣ�ԓ8�O��㓏��i���N�WlD�=8��	^CbviWw���^�M�Y���|@��}��D 2�l�f����;Rr�6�#�^����.`Ò1�����|9�6�r�S��ϱ�L����zU.*�����ܕ�F�m�ƗUۦ�篐��۸v���r�۠����ϭ�:��*�ʘ�
�қ��������p�~�|�~e�텵gL�ط���%�e@�T�X�5(�+P�1��򞞪}��v�x��/�,"07�Fm��ʓ�KfcA��S��#S�{s�G���5k��$CS�H¿�3��rSV,Kޠ��M�m��
q�
���*^�\��9x�u�Lꒄ��C���/�v���6�/�
��3'�\�J����(S�#T�@�+4��Hm��N�e,�cJ�9E�������i��Dr��ӵ}he�N�Y��j.�L��ӌ�e6�Ҁ+�kF�@0eg��{^Ϫ_L�'Wђ���ǅR�}\a����Qø�2C�V?['B��Ø�D��=�-A�"���Y,E�(ʯ7���� ���5�q��+gq;&9�����.�Dso���������n�pL��e<�>��������*ϟ0�c�ܻ.D����Ƈ����,:D���4��0�;4jWN�<V��X����knیo��<A�Q��uM�����gtFq�o��B[��A��.����1{l@�C�a�`� 1�����fx��,2��s�=��"o��ۮF{5cȍ+]萱)-T6�p��J��ҩ����!�(>�nI&{�7s���'���� ��S�S2,���� ���`!�����֣�W\���8�do�tO�P�I|^f�U�s�4�d.V���4��}{I|���Χl2�?Iwp�]F���4���ɂ�ߡ�����j�(AP�vwx~�X*��v��mV�ZT�'������_$}�~�)m�߁!dzOv��?���3������{|ZZ�ٸ-/X�wD��U��[ǲb�)�fr�&Gҩ��V@ϳ�i��s}��+��I��N����l7pc�U����)�0�G�O?Q�wf�X�Đ}�Ej����DJ��K�o�V����{N8�w�sX�^�<���\�I�w�'��+H�.��������5��l~!$��n> v*�����͹B�|Y�Ѵr_�u~̔�3ƈ)����X�ctG�������T�=k�maO���"0��J%��{R`wPP����|��6��V�� ��,���Qp{����td����g���b�H�J����|ЌZ�9Vr�Yv
��39�,����x5�^�����D�!	�H��, }	紓 ���%LD!���y���m��Ȩ�~rǿ�I0:���b�Cf7j�5�?ݽ.���ٛ�8�Lϩ'lW-�ɒ��	�f���4�?O�C��3$���V~U�#���@��&��XE���)����OtY���S-�����3�xm���J1������L������d����C�s ��i��^9��a�z3�:^�����W_a�銠�i�F��I T3���]B[16@��澵<E�,�\��רBԾ��T��`���-�Q f�&��*�Y2I��:�/iݛC�.�X���X2U�c69we@�X��_[|�9{�/A��"`�7>��!R:�2=+e����4��i��"me�� gZ������j�oؗy��D�[k1���N����vĉ,wM��E�����4��_=��u3�yʜC$.��s�%^�6�`:�-��eõK�PG�=�0�4P)�r�~j �Ҹ���"N��c�r��d�g�����7��X-j�:�8��#�d�Z
׺ �N�Չ�ə��ϠW2� "Lb�uaBk1�8��i+���/�`�#�hO��'WbY�.ђ_�gm(�V<����1�C��Q$֨��aM�#'��˂�l��0g/ȉ|]����$�ۧ��"7�Ю_z�>^ҋOא	��� �j��TW(i�:o
<ȶ
��E��2�u��"#�BeI��k�8���:�6.�L%c_~�/�xZ2��1� LP!�M�)Wq��\XRN�yZ3푌�����S��R�>�R�p�	a�E���sâ,P[d�_O������u*���ƾ��"��Ӡj�^Y�rz�/������rX)ď��&x��W�����,xe�-���Ӂ5�W9�n�C�ٳwt���$�i�N�����i��tయ�)��t�m�ё�$s|�������v&�E�2����&���³����#wƊ��k�q��?$�]�
6"�(��KXp:_.~�'�/ӄs����	�4,\GL��U��XZ\6he6i����k熢L�ӌ��蛤]J�{�ַ��i#'0h�sV7^��o]������V̼ō0O�d�tBT�~�pw7q��*v����t�l���ˉN��#�d�v�{�z�T�¯w��ȩ����k��	��c�V�i�|Կ��G�T� ���W�A���J�P��'��^�&2�D�>��v�C��;37�=�ݩ�Ҍ}�fh9���i4��]㍙���n��&�M�0(qN,�h����	��Â��4���+o�/�y�L����c_�)��N*3��;1��op�����W`��<2m����b��H)��vi��p�j�Oï.���AD���gh�f`C+�0ɽ`�\~���ĥꤱ�ħ �Ӎ�-0S��$���S���2��:'%lb��S,_"��G WY������C��SI%�X��7<�4��l>������68r�����ԃ��o%*���2Y�>�� �Vg�u'�����⌌��9xCi5�9�WVVz�5��&[��zcMvFC\����Tj��
^�-���c�gd�X~5��~�@F�R��8�ѩB��<s �jYG}���e�S��
��Q��t{���=&�fN��o�L �'��U�\"��)|5�z|����OJ@ih܊�$lb�(�ߒ2��n�ei��!d�,J��
��V��?\�p��	Hۀf����u!j5% ���g��S�K"���Tb�dI"�6s�J�x?�`�����g�t���#�!�~B:�u�Bq
]I��Y�Y�1NpT���<��X��4�ߤ�C��p�q�Q1����U>+��=s���x8��JI(�g-�������g?bqО�1H��]5���;[���2��9ɂ�fP���`�ևj�f���?�C�D�V��{��c��Jt~1V&ǀ@}qˬ=}���S�T6k��s|M� HmS�r%?���/Vc��zv�:ۉB�(�NN�
%}����A�Q����Vi�,g`���
�d���� �\v&��ʄK����qi�FC����F�n&��єɝ�x���|j-_nM7�os������#�Of��A�n����U$� �
���'Y���qڔ�"*U^���i+�7 Ϥ�5A�>N�"E�P��(�_���=Av��	�w�@��������g�v��Bn�9��s2�������o,m�m��ɰ}�82� i��O��A�O!��;IK��(&cp�5m�&��w���)��֡��y���]�W�y�w
*� ��p&���*���_V\t���K�-?�$�P�㘉�&ט;��f,���氱$F���0I�X&B�
��n�}�1�J��˪��{j����㸕�T�J�Z���A�q��7A�Y�P�Ou5�bQ3`&��7��MI��p��O�`�'�2L���3�:8���%�.19���h���s?|k�?�F�	���)e�vk�M�&�(^'/��� e<D�&�.���S��3��F�_tU��M�Q����E�v����������ƒ�`�s�Ј�mu�4��J)AvkIʋ@�/Wu��7�&��͸�8�^���QBH�ˀ�% g��i��e�c�eP��H���C�(�����A�oH3)�Q*���'�z��C781��*�R~��h��R��)>:�8�I�R������+�DN�z<嬎z�tj~�0��S�6;��cs�&��W�c�O��9\z��WϩJX��)r���҉�bZ|R���z6����#	f�͙l�l�)|.EƮ����ޚa(H������D"?�k�k	������sXC7�g�P�]�4�i��D����jÍ�<�2�`_��䟙5�����Č�4��%X�:a�WHf5�ۘ�mD[2� �ӷ֯�����q���smt5�Ң��M&����ӆ�?=���םQ�(�+���;z� `�Qn�;V�q�ۑ�b.�'��
��\�:	�4p��Q|aG���Y�h�M���ɍ�%�2a���9�L��L�qԴu>Yr�kA�h,z���]��"/K�3�i&�?*P�pݦ�#s|]Z�M���A�������*C ��;�h��(�Q��	=Z��!��ji�,�U�FftX�MWL���0
g�����&�n�xG��"z|��2�9�:���o���(��i��[�QVW=�M>��"f| �{���?6@�G��T�z{Y�	�Þ�+g����7�P�dv;�"0Q�R�<k�p��~`�C��p�hrKR��4����/�����%�r|PMd��@G��[��E)^p�ʍ��S���yd�ا�6�_:+�>�3��{m��QTC�B��X��>��k53{p����o���#t����8Dۇ�`tp/-�H��5=n�U�6o@����s�)؁F�� 2: ��3ڱ�Q����R�
D�֜����~cgAm���;���C��GRgt��uL:@JS������Pɿ@��\_R�@WHs��G�be��0ݪ�6�w�ٝ�y���}���'c���ז8�f����@�-CB;iI���O�����謙|Y�	r��_��'*���>��6�!k�z�-�n��)b�#��uď�7_v��O���+v����lz��� ��r�p�U�4�݌��S�;m����Kv�w5��ѻ&������WOYtxyk�\75孀�EB�l��ڟi ��7L����"��߫�+��`P���as/�6'��"��'(_5���Fc������b�v>6D����^#v 7�['�W�A�����ڛH�/�Z?��6���H�OT��'��(�Q��*�9�*s3l��Ň8��)v(�*���¬5|�/��2Tr5}���:5�x�s�%�]�E�f��?�V�?��şd7=0���.�+c�$��% �]}�5����[�#���31!ŋ�0�	vΆ.Bw7���Od�ugkSN&,�a�G̯�lh�sRqI��I
��{\����J���`��(QH��%9�Z�Yj(fE����N�d{��.�2;�@(��BKm�������[Qx%5�Қ�F�`.�uT�b=�	�����A� ?z��rȾ%sY+	�����r�_���x�]�?f�Ak?XV���e�%g̭����-J��������q��q������p����$e��o��L�[��X��u]�G�v i���s�^�ƕEs^>[!u+���dQx���+�m���h������v}�^}��Ӵ�Z��r��.�4�Y�=D�Y��ˍ"���1����Qt�{��1�]��)�*R�!B�x���|�A5m�線Ua�3Eӿ�������>�KtE_�$%Z�y�ݪ"u����R�ȲR�-�L˴Bnm�~Qj�#"	�	hLQZEO*��:��My�2�T�7��筐��H��?�*E�ѽ%�y��"���(�S�Y��|�U-�=&�W{�ƥ�h����/�*f�["�.o	"@�GE;mB�ʎ%L����V�t��SL�0�
�&Ϥ���Q��f���&���'I-�������j#"t����ޏv`��*����7���p�c���w��#VhO�B�4���߃De�J�Ś�E��l1���GLCǀ9T{���F��E	*��)�R��q	�Zv���5�N{J�%��9}�g]>��@��N&C﫶�u6�92�w��Z1.w7<���jƿ���g�sRTd��5hGk��Q-y��H�Y!=�:q�c(6E�7�ّ �~m+I�qGP���� �����[�]�j���l���ٽm��8*u��MJ�D�gd��]��V3�5����v�}AjS`�1�$�=�̳�����{W�#���u���X�����/������S���
��h'P�+�iBj?����Ѵ۸+_,/29M�25�c�#V���}|Է��<����b�Z�i��-��B˃H(�_�"��bc{��4��4��pc��H�Ig�DI�a#y���,���9T�<��XI����4+�^����+%q�ؐZ�g�c�Zd��n��T�]��D�m�C���m�j-�"3%��P��S����2'������1b:����{(ΘIʞ�q_��Gy,���:�] ���c3|m��x�S�҉���b�H~f��%�2�2^Yg|�`	���X���,�QQ������"%;�k���n:ı@#[��ʷcm�Q+��U_�#lL�/��'Ϯ��4�1��UÍ]&Jz�:Eq�����^���P�
kFu3��J�d�d��������T��@I�E˖��+���J���J�1|�h�W��ѹ��;a�@�%,E��x��GT�8��5��:U&�]:�#;���טxD0/�V>-2���pW��́�]s����x�Z��
8,���"(� �5t����&�������h����scR�.���4���	2���� hy�vPy�� �(q
M����Ł,���7����_�$�֭ym�]Ye��]�� �{z1b�͇mrg��v��NKͥd���1��z\z�O
<�
v��W��:�Ixٔ�/aZI���g!_~����w�e4un� p٧ʊ�ħ�6DK�!	�n��E�����;�����LYPB5D������u.�uK��]X��l6����r!�2�R��>�:<?�է����UV�С#Kk������c&FF�\���4��$�p���z�E���7�in'��bsbݍ;h�-�s�M�I��&�U���ۘ�g�/��֨���
p�3���B8L���>a��C�7�Q��Y�Iِ��%F��ئ)�i���rG�	TSe?�>� y/�1��T��l���r��]Wr��c؊�ƞ�q�5�:�	^�t��;`�+�2��\��}"�\��M�8��v�KI�k��IՁ������=��@�.���Ef骺�)CW�@�B�HR#h�7ǎK�a�Ċvo�RuJN	�8yZ��P��e�F8�CJ�ѵ����A�]�O�DƉF�IX�n6Z�L���5����2j�b�:�'�R{�$��V��u����&�s� yH���8���7� <�����T�����%�	K0��_�O2���>�� ���K�ҭ���	G�70�侮G��uc+�`X6�B�#q�����~l
x���b}̇��k��Μ&��n�S��>̀�#�p
:v�A����%�8Ӟ���^6�'8�Q���@ڐgQ�/VO Oފ.�q|e��Z�Dhrg��4����jw��' �&z[6s|�Q\��$q�4�͝%�%+37ǻ}����b*U�[_8I��A�g��[%�uO]ڂ����w{;�BQ��|̪�/���ϻV�r�ڣvӎ�xs" /s�{-Q3���z�i������o:��'��>�$�b
�[e_�����fF�2n�C��S���'�)G/C�AkvĹz�!��r1U�\,�A���g�`_R��@�V�EF�/�~�O�)H3���r�wZ!��V�z2�x��L��O��L�ژ25�C*�$n>�a�Mb�����~a��Y�Ŗ9�տ�۠E� (D�W�1��g��מg"?z���~��ߡ�G��:��Z)_��f��1�`�O��zn��U�u���Dbg��!��{���r��G���¦>)��,�=LR��(j�)�Ϊ�e�׷tj�:`������&Q�a0�@y���)�!-�|ޓe�D��	{F�}P��������fZ�a��LP,C�� �L�h���TZG� �-qoY�EOv	ߥɵ��^�gd5(�+k2��T�3����z# ����FlW�w3�쪀(s#f~�ĀBw=�~�<���7@�D��n����O�"�7�ұ���L���uLR~��
" yF2��R�""��ɈpV�W�+v�p���)+9	Ƥ�:;owr�IF�u�-o���,�֨�����H+F">��Pz_�g��>�`')��Z)	��)/�^��#�|������%^�( �R
:��-*l���$��_4=L��DXs�Ƚv{Vm�tŜA:������ƥ�mNʑ*���:��C�F�[���9u=���^4�L���2�O��G|ᡯd,��{�w�b���J5�;(�W�r#���Ŝ�Q����P^�4;�AS�rR��MǬ�̡x�v��1���ʱ��n�4����,����eL8�5-�z�;�t�<��rm)�[S��J���+�\�
���\��ݓ-�#lEf}΅�la�Ů�X�� N(�g�L�w��\���F��U��۪FA�{X1	}��$/'�'���W�򲣞��R�WcK� \�ƺSf%.���JvHv{�U�N�|!C��h�Kz+�R��e�yW\�+��l�զ��£�_H�;��ݵ�5A��#;�
 �?p�f{���) �F��r5�˞W���v�էMYm瓙��>Į�ye�q7�9�0V'G�Jk�����F��~��(����͇׈Z��&&��-�n,����"q�EQ���Hń���_k��jc7mX"�m��y�X&ou�7��{ˆ:�?������w����r������%������c�]����T�p'�\��U�z�v�A�5�G��@y��3���#�b���~�b�����<�S�P��aj��L�;��u�ZVœ��8��E��C#��A��z��/A0�{/���3��)�Y��g:,J:�߈�:|�B3M<3�����k!���0^��RX�t
 )���ù�����,1�g(�$iH6��ă!�5��H�IU�UQ'�-@��0'�b;�$i�� ��⋗�zdܳ:6��C]e��3,ֵ2��=��+ꨜ5io5����<I/���JXj-�&2��@�Q{���7���a?ih���q�g����$i;N��exȥ-��)�4<
W�iG��2�.ρ�#:���yy/ϭ�c*9�����#~ӵ�s	�m�CQ;�ڸ|E%x	͡�wbˁ�ﲉ[N"S	��5}����-yS�̗��z�N��6��8�	+�1�5��qaB�z �+|;���uv�̯L?�5�Gv���H�*CpRJ]��\���*�&YyG����lPӚ�e�L0c�ײ�=PM�i�M�5'1X��Ǒ:"�?8>�D�b�R��ϳB�,q̺+\�j1� �us��E|֫�߁�i��ոU�"e��Y�P��(a�bx%�y~�͸^���숎�;-h�wk_���v�5�F��̳��)�~�wCl"%%Լ�hg¥|j"��u��WE�`���X4�A�!�&��L�#$l��[��2�E�q�������@tz������Ťͤ
��������pJPbY�	��3�k����m�+�s���i �'�+V^��B��x/���ɸ:�+�߯qƙH�>���T�+��'��Я_����[�|��O��K󳟧L��q�$.].EK���w��a���sD�|��N��f��
/�$Ƒ~�O/≁g�9]Q?$������!ޢ�qWL�W"�����`�C(ߩd����֦���̎5�mX[0m=�c|Ҧ�q �&?�j�����$�2o=�?�V*?F�.31�%����<�9�v�(�T�hǲ�A6��Թ�)6�	����$�����/�З$$,���M)fʠ�w��q	O�ՌoNv5����>�z�� ��0"wL��~�,L�X��59{*{9���1�_b��2�r_j^�K�ڸ�����еꦀ}V[�����J6����.U�.��$c�r��K�ƿ���GG}��	1J�����WC=X`�=�N���[�$�G�!Y�{��A\�����o��<@ݑ�Sr����".h�>�,�B&I��}��d�!@k���n����YPX�	�=�kӕ$���=��wnz1!��j�\�=�oH����:����}�����T�
��4
�����3��~:�e,�p�^������7�y��D����8M9�\b��q+�F�������-/y�?��;��/N+�F�x�p@�4A]V&�ժs�)xÉv��H�'|�R���i8�k"��.���)<)��S>������穤�^YF�o�O�C��`Y�F�� �;��_jM�r
z��پ�h#�au�&}�]Z�,�gaM���H�e�b!M�u8ZE9��ծV�O�J�����2��w!�����_ی����w%��)�(��q%5Y�B#��Ymh�igwW�X@�X𓊚��1u�Jx��\P�������ًRRn&~�=P�&V^�M>K�)�f�
��_"�G�n1fP���>?�|������-�E����/�>Ģ��B��cz�^L�-D^���l^TL@���1��^w7bԿR��,1�(x�Zl4��ǙZ�`��#F=��&��t��Tz���9����~[��t�����Bo��ˏ p5���qb����7�>�>{Ts��=���Y09��ԫv^V@7�4��Hȅ��Y�ٓ�*J;����A��;��"��*QQ���8�7(�bǆQ�l5 ���.qOsA�����rСwڏ�p�����^Bt��v�b��-���wț��̾kš`h�^Z� -	(Z����0!��m��*�n�ԑCU����e��[��Z�ηi��$4�*�F��X��ϣ L�z!Mi��H�b� ��Ɩk�8u�@�V�oE���_�:��&Y�j�iD�	^ŷ=��S�OD$���n��EO�SqtF[�=Q���v�J\|�*�R*�%�b��$R�
�j?��_e�Ê�+fA�� ����Or�UU�82��3�5�k�W{��u	��0[���i�%��!�&�W1��û.&�)Ӎ�a��w2�qe��M�ȚV�=jҒ����wga��I埁Ǫ��K����џM�]�QZQ����<���q`�H���mh��>G�)X��{��;�ehU3is��u��ɤ�g�m���Cc���I��e�syU�����x*J�����N�u"�P4�"��zc6�HLB����w٭U�t� ׳�?���0�q6AVA��Q��e
P�r�d6<��C�Z�?�q�@�pK�&"+H��h����I�G"YxEtbc�Ҍg�ά�,����<�^�/'�<�3�5��.��>RDhh����fȽ�|�,a$JQx����b$-%'[Q.�KB]W�+oh�����GF��$����6(����ߚJ�{��@�A%P�ݏT��ηI��{��&�'I`*��q�A���@G{�c�K��F*�ښ���p�l�e��"X+Wխz��q[�N%?��axM�G���(�~9�)�;]�ꌭ�'ʏ~���,g�h����X�ճ�!��Ǜo�R
���k(0���a�NY��{��͗�S��{�e-��MY���³�\F@r��C�3g��VFپ�^�fc	^1�ŋ�tG;O�ca�_�/s�!�rñ����������]��A��zt�k���!�/�Ƈ�!�k+ʑ�!8ʵ��ܭ�i�i#����^�<~bB5��Ͽ6U�P�Z�]�a$Z��%�G>>�h��E,QD�H"�u6wY�'���	W�f2��R�b���J6�s�D�!&#�'k"&�����4^��>�K�,����?�Ɉ}d�1d�[�zZ!�5{���m#!O��r��~Y��y�jx}��������N� c��J��Z0cҾ��a騣�K�p�H�;�E�/�΀��|��[�ᇎO������yp���T['������t����P�?W�_Ԋ�0$nev6";9�JV|<�J��vpD�����?ps��0�����2��n��0_*�J�M9	h��#��!}g��g(����泐�.~�6���&Ym���Hn8ܘ�Sm�Us9[��{ϸ���axY�/G��
�C��i�݁93+�Ju��Pn$%P<Ħ$@�=�GyK�(��l�t稟�EVe���x���gK�-�y����%V�XH���`O�S����t����#��{��p�����~7�*g����C�����V8tY�S[�?�~�W�U��}�C��lq=m�qH�:J���#�wI����h-��@�p�� �a�@��G`�;5��!��M��ΣXO�!
(��P-Gݽ��0��9F�:;>_B@��v��`D� �K6U^�V�����G���[�]$O?�q�.H�U�}*6�~��d��������yraX�$�il�����r�^Of0�p��P�T{��Ŷ������&+@�z"R�'KEt� ���z��|5��;���r�L���S�t��%�$���oN|����U1\PL�U4������0�BTq���ErU]�����Vċ��'�j;���t+g�<P����*Y�x�1�#ۂ	��p��y����%�h��m�TS1F�<[���q?,��u�OV)���+�P=�0;�Ɩ�����3�f��>1Db��0���,���ep�E��8���"�����t�*؛~��Y�;I���i�ϓ���-�ޅ|�p��*r����$�lg�Qp��H1Wm^K����qy�J_��bQ�CJ�^,A{�Ȋ�89� �V��EC,���[U������Z��Ib��ښ��8?�4�`aG��! %��|�����ˤ�����s" H�����*��|LL%s�\�\7��u3Q���5N�fJf��������<��'�f��=vTȬ?�c$ݚ�qw��E| K�<F E?�]�Osl��E�H�f-VCmJ�9��SMW����pU㞞r�W"��5Le݃���pz���U�c߳d�Y��]��pږ�
���M�j��0�R՟[�+4?���O��pm� �����\I[ٽ�V-���� PR>* MZ��C&��a]�ט:���K������|:J��.���ǆ"��L��{�HE���w1/J�Y秥gZ,M��Yi��Q�<h��²
��SMx����i�gT=�f�S�z&�cY�g��j�b!7*�3�PQ�V1��Aړ�e���](�#pr&|0(�*�b´Tku�~�.�F�~p�o`���f�����?ǃ���:��gA�*�6I���,'�l-���Rᄬ�ES�w� 7e�d�35~��#e����uN�3�s6�Wַ+�C�T�'�N�:qh�Wu�{'�X���A@�1[��[��>O��Ab*ElQ�̫��F[��F����{ʴa;8X�/e[�gGY�EG�Ůq����/�0�w�ښ1�4��N�`���.袜�l!dx���~���r6a��>c+ZI�$,�
7k+��]��P�џ�h�HH�ڇ,���� PPΙi��p:;(��y7,z��g_A\1S��|�,��,g� ?P�BG��/�(t0�� ة� �b�q
�r���G^0R�=�#�2� ��Q�M�w0"~v$�y��T��}|GX��U�|F���{��4YͣbZ��
�ڬ=��O�z{i;����t[�2��!h����B�8�n;��3{�t�\,i�9���#n�ё&�|捥�>�T�j�u88г
)�Ǵ�C中7�ma�F=;/�s�/�u���l�?� �RGw�~x'��<�X��y��ָD"��,����j�p՝��"�֟5������ڜػl��;$�ИkL[�ϙ	sFz\J=(��� r1]�o�&1�����F�	�x
�P����ӎ=���"��U����	��$�G�:}�VFSHy�����ݘ��Z$��֫���@��>�.͗֝8j���7��ڒ<3��B�n"�:�3+��ٯ&Ĩhc�5F�<�Uڷ�#�����E3t`��2�@`�x���R�I8��K�������RwA�QHd��]�K8kɭdm���YU�=���`!H`�d��U�1�8
�+&B.)��Zw�Jwv��W��〠+�s�QaEbҔ>������n�@��?+�>�_&� ��o G6}�����9�q/�UF��N?�Z񜭘a�^�����Ы�f����z���!��Q��Z�|d,���\Xh�+[��2��E��Eأ��Y������?�gg�������RCآ���/�8���ꡟ�a8^w�K���G@gW~b�@Ǡ�&\���Jxb�(��qp7>� IJ��B7ȕ�Ue��� �{�0�����G�F-�%Y��YF%�����&����J�D�ۮ
�K ȅc��8W�Y�k}�Q�dwH�Q3�v�Y�:m��A}W�bE���-#SŦ���"'�!9;���߂��L��
flԍE�/��Nb�Z��CJ�,�Q+�*b��]x�`�����J�`f��(d�<�@�ή+���L�{+b] Z ����f~���ř�����j֡t�el=��B�����x� ����=xZC�u��3.u��9���I�`�P6�o���,����wd.������J�i�gŲ��� ��h��:�VY
�RR���EÄ{wh]�/l�?���8�U-�iGcs�b4�~�����o�A���@[ݜ�]���v�1���;��1��6��@y՚�&ݖ9i��Dջ����,     �`D���� �����d>��g�    YZ