#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3454078269"
MD5="0429db9c7c3421b851e89616a430edf0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22928"
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
	echo Date of packaging: Sun Jun 20 22:30:37 -03 2021
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
�7zXZ  �ִF !   �X����YP] �}��1Dd]����P�t�D�r��@D�ӗ���1���^��[���c�%�k*ZҨ������qOy�5�%Hy�Q	�A�Mb�:��?����e�8�O�˹o	�yb�3ƨ�Qr.�ݸX��0��y.m4�\9&TA��G�I���񢈋���}�7`M��{N.�N5���ܜq���hEj�嬗׾M�߉�����C䤹 ${�&��u��S/���͊	����y!eH1a�Ң����ǹ��8P�ƚf�Ď�{�;�"=�usy>h��,����Dˍ��>8������=��<���>}s��Wb]��*��Sd ��c�g#��Ѓ<]4����6�^@�[��"�`�	�7��ݲk�>3�}�u.
&2G|����1��:�'G]�'-q[����'e{3��0�r��Ad�^���^7���XY�/ĤY���ڥ[��$���Vd���eq^�^�k��\s�Z"25-����H�c�M(�x<ە�*5�
I.[e��K�_�Qۜ~$�h����-"e���0�t/�\g|�
�#m�j�M�FbJ�}�0̸��b�`��0��C�.�g��X֯m�W����SW/y!�f��A�<�a���35��鍊�#�������,�*�(.�AW��"��ej��۵�e��Gz�˿~����}\�h�ݔ"9h �d�����z��8�d�,v�W�3VE��݌Ե;@O���_����Q|EV�aa&��r��r�h�,��2^p201a�:{���{��y����˅�0�i�Wǫ�����iL�M���ޟ����(�?#�Cd'9��&c;��nEPՊ}�ok5!c{i��cv�-�0�u�u_M6G�&}J��}p�M&>?644���<�S��k=S�^wm���WG�q�==��w�q������%l��������|��8�X� DD�B6��e��ãVw����ɡW�Jk�mj�).$��Q�F�S�"�,��t�*�4�X360m�������"���� �{l�A��S"��� rf��M��t&,iK����<��_{���`K�����μ�*�`�]w_���:H�����lhx�L0R��P�TCb{��A-r��hYy`����i�	����X��>�݀���!��{���� ��.��!D��ߒu[/�<IB����r��ED:�^�ct[�ɒܸ3;���Yl�4.*\jN�d���O�F=��ɂ䵿z���y0�V�]4ѣ����R��Bu��q�dv���-DK�����EH�=��BHV��Г�����ld{�It�fu=�7�b�*���ݓ�fF��9!��Fy�Sox�ZaGݩծ�p�g���M/��!�	D�Fi�+
3[	���3�Uy���%�Pn�p���${SY�H�P�-�'3׳����ȓ����o��#�I�����s�3_�n�[B,��K��_�Y���Œ<��]�si|����QRWF�&��՟���1p��q���OT��fsbhx�A����?9x��4epT �7��J[!�����?�&x�'VR	�F�o�M� ���<��0�o!�T��Z�h��d����wTi�����e��b����]��Y���Ͷ%'$[? �r:a�ck�+[�0-K��{�����4O�*��aSr�r�t�_L*K���l׬/̡�
	�����m�ߵ��~���f��tw*^[�����|���`b_����/��3I���|$����i�7��Gr;�׷n���ƫj��r�M�`��ģ7��K�ú�˚L�!TJ����׶c���<��N�O����Y��_��	T{B�$y��x,ل�uA�:�L;L�w�+���1���Cq[��M]y����\'��B���&3������m�y�u�^���}!!�">
O��[����66�2_��s��X.5�2v�U�t[&8U$�d9(�����M��$�53):Z*k���N�ԇ:��oL�P�������1BJ�h���zw���4c��$��@��z������6|��2�a�S�#vDB~q Au���h=�A�:�H;E?�	r�V���/�a��0Q�n����ƹ�2LR�����֩-U�$M�=p���q堖Eu3��� ���T�ͮ�6À�=����ŉ�1L��Bd�Y`5F�-w��(��c��Ϡ:��[��y���E�!?r/��jC]w�at|�V�`�;}��8���pbCO�*�,=�?����w@��ٙ�Z�q� uLQU'6	�2��?���C�� �q�z�<�� :<�~��Ev�P�{�R�$&�W���"A�����w�[�d|�Q��ݧ�)�[�x��� ���~|���O�ҁ���A���^ �E��jU��(�������q�#������kC�9K����O`�S0`��)��E���D����з�.a�Ē������P�TcYWSpՑ\C��� "�b�j���~���C��vy �h�\�m�����埙3�����O"�@�� ӝ���v�\
���8V���8||Y�$�U	6�,9N�tT>�ߊz��w.��o�F��/~ڄ��͗^*Q=��#�A����׌����;����Q�`0���A���T�!,㛯T��s^��8+�Az���2��7����bz˃<>���f9n�h[.�@|���v�NӝW�D�S��=WI�����,p7�^ K���N7iB~�Ҵ���y�e1��I������,�k������}�n�R����/��-��u��.S���팖�/K��ٽ���Wė�\uj���	�TJȵ0�+�5޼R=�ڟ���v��wxk��РP|�N���������&w�ם!��g��Q����~�����+e�3���\%�r�ڛZ�$��J�YM��$Vxw�c��}����O�`��>^���!.�����7c��u\�)΄�ɗ�`���r����� �l�&'������^Y������Y��v�[�ɫ��2E���^�鬇7l�[�fY@��ʭP��j�����8��G6t���էwl��R�uiU��ۯ�(���1?�����1j��HI<_vw���dF��t�MY3YT�������Ж�����~�@k��.L�� �0�N_ȵ ��O���$v�7�/�<{x�����
`,o<C������w�L���t�XU��	�<U�X��z���kd vWy.",�&��qd��� !1/ά�L�w���B*}B�M�^*�B^!B�4�u{{ۊ�:�q:��$iT'~ϱ�]톜�<I��@�z��%�}Vw������Ǜ]��;"���my�'{ӹ/�Ř���a�����A�������?7��������Q}W�,/H��2d��ZCVF'sq�#�+N�8�Q2�^@��ˀ���gڰ�Y�/��9b��4��Ͻ�*��YY[�6R�Q�Wg��}��NF�į���w�%����!3=C[�r���p���Q�d�\�fH8�_�]�^y�A�g��	�5�j��&jCA�!�~�����ܔw�^��G�����p�Pz|sy|*�=.YoE�7r0R���jg�b^�Y[��PN��M���֧ �5�:�5��SŶ'���2��8��	��;  ���xT�����
\С{��u8���"o�kh�K'8}��ǧ��sE����xl��N��+줰@�M�O�0ѓ�8C/��0��L&�%�s���cJ���Yό<B�2����߈+'E=g#ti�����{�������.ފ�+�YJ��$���3�`�C1`�]�<g�+q���D��
�����\�Ќ]Sr�JE����Z��TO \|s�I}���'�!�X�N����-axb��Id�:�v��~��lX���_�r�wVޗ�8.Vp�����Y�%j�8^�S{
G$qE��S�r�Y�J�������Fq�hb�EQKK;�dQKZ��tu�>��%Q�/�F`��c0x.RK?1�ꏈpc�7�*��u�1�� �|H�8'���¦�m�_1د�LA�RS��Y3�����췾�f ̷��gx쬓/�F�G����c
m,D�XI��eĽ�.�J�?�s(Y�[�V��Yf�	g� AζR� �3N���5�߸g�xٺuuG�3��@�������t�px\҂y9I�}4�Ra]ɝ����+Y~'Q�v���^@#?Df���:��0�#��;h}-}�z�Y�x �jĝ�r�"X���8p"85%q��\i�2�"E��{TZ�9r邅ٛ�`����D�l0��G���@� Gm�Y�a{��Fa	O�&5�񭙒VV'���gVM�!�w��-/&�m������ߗ�-���P"�)��e����Q�ճҡ�9�ُ`�~���7�m!����ш���/��@��{?g̹�;5�^a�$� ��==1�5�����ߥ~����L�Ipj ���4���fͶ{�Y/+���8E�O���pG�~�z+>��S3�cZe�+A�Ӱ�-���-	.��%P��_]���k���]A0{�Ǔ:�JI���6 �z^	���b
��Q���d���:�������:��:?��jךX�>�����?���	�k�)�Iw�M����-�x�<!2����>���rC�1�_I�I��jCY�;�����8v��ޅ�%S�P���hgdSH������x�aw92%�|��w{(/r��/W^EaQ¨���O�!��-��.�YՃ*>����8��GlƊ��)/�<�G���d_
��q�h)���9cu�ZS�4�6.s��S7�u��OnSqrSmR��9���E�~�,�?9�Ze�l1�ߨ^Ŋ�e��;熛���ٲ�v�a$�?���U�T��	���%��㺼��v��}C̰�os�'#=�"ЎC�C*���4�:�T��7���������i�6^�kP�t0�����P��K����̧�p���,!�VD��@�6�'��-H��H���'0h��%��m1�.�;�-y) ��`�yz�P��d��`�m"�L)��h��⧲�� )_�z�{����������T��R��`���z��	mW��v?i�>���i�_�<�0Nϙn�ҽf��)ѩq��*�+=�/��墐�ƌ����!t��{�  c��qk@��CBn��vyl���b�m����]�M& 19-�ScÅ�	��.N� ��U�X��d�иϡJ%��5x�,p��Ac��F՞�qqa�S�.�Ƚ�3���MUA��:�\=�z��H�)+͞��L��<��d\*N��qܩ��]�$.������6c�~�(��4�\M���D�$���2�΢'��w�Q�y��T�گ�u��,���,c�O��#b��[������G>)��qeȩ$�z�_�q�����N�?%h�^�mLy�mƫ���Zx��iLn�Ҵ/�Ы!/�
�B�@dPU,W�&�6�qaO����b����7�O�5�Dy$��s�9ʀ����Y8�ʘ}¶����5*�A�̬��+���Q��4�8��*��N��N��^����Cl4�t�&�UX�) �MHЩ�)/�_i�g�U���,�y%Z���k�S�;Jn��2Y'w�����%_���L��66�H7)X�2(]��]�+��Zh��2��73��0��`��7Jg`�T�]ǔ�v������yڇ��0�Z,�)�wd}z���� ѫDB��wQ�����2�F�?A��^��ᇇvdU��Z�����+?����8�q���fI=�u����΁�(eŉY���(��?���'�R�(?�4h�C
^˔����x�#����a?�����Չ���sw��i<����Ի���b�jE!a�eg��{�z?X�~tbrL�T��Gͪ
q3�t:ؽ��r�����3������n~�m�v�.�ie׹y8E;����wXk����լG_|��?/�z�]�f��&i0�`��?�/lؠb��ϵA�A1��?Gq@OJ'�wYy��f��qt��ù`iXj݂����a�F-I�\���1k�}�����nT��=��^!��Fښ��Fc��/����'�>}w�� �.�TBx�x��|�9o@ͬ�Ŷ�ܝ���������x�J؂�U�x+n��tן���i~o��W�'~=4k���՗��w��'C-�a���$��᭶�����i �a�_�OX�!�n�&�0G�/�,_��rkU���`h��M hB)�XS:E��ܢ��eG��۽���X^�����Tr��R��	-(�-[p3[���q�0�y�g��iƭ��0G��h<C��f���}�2Y��Ǿ���7�6�*�a�z��*���id���~5��yR�ӑß���+���2�����7w�=�q�CtKyX�3;�ÿo��/+��ހ�Atc	6�7yjS���_g�|�~[zs��'3rɵz���>��Cy\4;��&��"STcрK����,��IGYl=�1s��h��/-9=N�y��ˡ���7���4 ��7��Ad�;1ރ�/G��Ū�V�jV�����Țߝr-�t�xr O��A|��q�^��g��SF>������QΙ�Cx�Z	+�ݽ��\T���ވ�G�q���9:U�8f����:�j	�A��Gc`���Z�)��8��p�~�j�.���wv>ЀL/���ׁ6Z�x!t��#M��r9��!^X�Qo:���oq��bq��������[/���
����{ �EW�e�n�G�R�*�
R�}�1��Q_����<���(;0�7��iғ yˇ-�s{PdO���rM�;[��;��s4ȥ��������w�?�g@(M.���~Bv,t�L��u��qY͉�f�e�]������JNUp���-�F�1��JXx���~;
���:EGý� o����V�?���\�)eY؋�a=Q���
�
QM����HĖ��,C�B��%���5��W����$KCpf��y�&��^���g�\B�mZ��A)�� }aѦ�V���Α1��?���%��^���2�"R��?���~�NҲQN�����B8DޜM&�eOx8-{�S_zϜ���DBd��$���4�I���x�/ą�Q\�@���W��%!��28;�T��Z�zpXaI#.~�_v�3���cD�0W|DV�% �N�l2�!���ڈ��ɋͳ��<�����\A�3&+s��^�ܦ&$S����gm�*�_����ڈs�A��v*� 4LxQ8YӺ�Z\c2©-V{8��l�V�b�JuS��d�|'+��J/�t�&7YÛF#I7�ES�~�+i[�~j�q�ξ�l\<��/��X�ҝM�\����f�6X��f�N:n� v>{R	1Υ�R���MjBVs	���b@tA
'��Ur�B��r/�'�s��rvF��8�z���U_dHѠWC&��NҀ$�?
���CW;��T���(����ǡ7/:[�%�I �#���NT"�U�աR~�c��o���%TP��q���A^�Ri�~�+g�&�U�kE��<#H3�T)�R#,��X���L�$N���0�j�S=��r�G�L�(y��A��_:��	i��f Ic��Ɍ�����=�h S�g���18D��0�.+mn}��v?_�
��J�$�ɖ�h3�I���^k%\�a��ٟ�Λ>�r�`kF��`����q��v��du݉����A�hh���{��D
�:��S��/R��C��.�,P�,v{��]��sUU�ˌ�_e��=R�u���\���0D�,�+��wg��0�cLas8R����^�H%q�%�By~OP�~02~�k��[�J6�������Ո��>�����`Pfdp���0��+��@��z����5�
$��.���<=���J�~stx���;LT��T��j1QS����]�FlCu�J�y7�B��X�v:�H�X���l!N�� �+����u=��RmϦ϶Y:UW��������A�Tَp�L���]{��O� ���gE}��[䤖l�;i��m5կ8�;'McG��Rד�f	:�����	ǆ�&� �ȭ������g��rے�0�|�jr�v�i�J�L8�Gc�9~>�zʮ����n���j��5�U��i�7c!�P��bg�l�I \�O�
:�͌����9�=��
�zurM7苤�6���hc������走��J-2N	r���0��������u<�3Zp8��)��Q�����F�<Xm�(�u�6ӊ�I>U�TKV�o@��x�(���=@��/�[�1C�҉���f�����p6�����Gm�T�vI2N�542��&�]O��-�j߫o������pI��BHa<����e�v�P��
4�o�rw>.�����K���X���<J�Q���l�3�c|���p dl@�qn�wT�q1Ω+?o2�=�"�������vƩ���2��r���aDBHv��P�,�u�k5�;1O�ƁOo�swy��<� � Ĺ�7ދr��q WN-!�K��?&��w'�	��?�2t� 5��VU��^aP��j���&�}mzTT��(��Yg[��記D����pf>�G
\	�:�3��lj��?a~ٮ5FСTtH�W6�0��ڧAnu�Gn*�z�[�c�1�m�����zS��ѱ��izoi����\+��E��y�t�v~���<+$$��X�H��u&Fb�p{�>�!���H[�c���?;��S!��<�;t�i+�soA>�/y-�%����Λ�V__�݃�d�����d���g��0�?�4�ʌDNu"ru ����t�BI�B6SG��8)�j�p�[Gn�z0�]�D	�f�PF�!�|s�M�T�_���ݗ0bs**7n��'3�hڬ��w<��m2�h��1d��yQ��hd���5�]Dnb.��z��y���Ӕ�#���]�������͵�
@a�mak�k#m��y�Rf0�(����۠�;˼�_c�evoL��0�"��v�v���E�δ~�:�����%~t�ڏ�P�8�:9�)
�����~�h�S�:V�ʭ�\��g�'�U1���Wt*�nJ�*��x��B�_�Դ)��_	i����R��8��/jwIFg*����6�Kb�w;Eg���Zm���L?�R���hq�{b��]�?����c�r�>����o� ǖ��%L�������iL���Ix�(�ƍ�d�Ac3����eu:tV?��E�)-Ӛ�rmy�2^(��K5�9���J�J)u_��\}#v�:7��Ú�bW(�(��b�1k�s���׼�J�co���Ts�D�M*����{eS�`�w����kyI7�آGs��H�C��s��ph�Ҙ�T;���� :�t�N��"G��	��+��3 K���6��e�z��_w:>�
���j�Uf�������XmK������uڤ�?��#qV�d3^2p�v4�!�n�s��,4�!,��)�Vr�[�b�GO�P�'4��j��%e�YtInӤ�"׿���:�H/�+��ύP�6m���'�EP���>�5��7y��=����f�-�d����#�z0h��	��)����W���ĝ~a�*�t�%�]�B4�����[��u�&]_\4��Q��G��][AM��st�Y<����'!"�zͺ�EZL4q�PRj�|�j�W�XDgݙo�aI�����þ�~I�/?����x
�jJh�ׇ��=t7o����C[O�7��;^�g�tG�l񌴺&��l������/<�X��c\�%'�X�CC��gm5r�d
�֖ȬlA���J+���N�V��鰣/I�̓�d�y�1mg�;)*�3h�v�s�E���D��}դ�2�����O��� �*|��uyu�OG�pδ�4�i
�%y���Nx:���ت���ÿUg����W�:ϭ�a��Kc��n@���+w�H���}�̔#?���[T��x�y�\�|�Y������=Sh`��������������
�>'����߱����ao�.�P5���aw/n�TbNԋ2�."ƴueMa���0��v
��)�~q��Rp$�!7���;�����!���Ѻ0fh��*�PEO���G?N���b\pْ�P�C>z����Ɇ������G3'��ޞ☯��
�9a*6֗y�		AB'3�]O��I�֌w��
F�K
�s��V`R=�M���JK�VB������$��U[\T�Q��[�Y(���&?��l L�kI�Ex�"�
��.�4;�Sp�X�{~o������$-��₼���2�����cdbg�3�����C���%P]��NB{�^/l�Jbd��Mm��5\nt�^0��ĕ������iYc�m�M*��/|�%,���<2��5�d�f��qc�j�]_����:?Gx]�K�p��u�ܑ��[>���q�-�so�]9Ko���*�,veo��K5
[�:�7K&�pg���[u��s7c�+z^��"��a���=�]�/���hc�L�v�;Ye�:�!����F���6�&"1U0�b���,=�pQf^�)��[Mor��I��C�� u�
XT
r���������xɈ)�I��b�]�:~�žv砳c?��d�O�>�eT���3v�<�П��ц$�g�z��iK#�5����D��Pk��1��urGS�VZeI�x�HoQd7f�I�.�����}��Y��A���?׶b˄�Ep�~4���0}& ]"���:O� �����L
(g�"�Sq�ʈ@̥� ��Y����S�>�&�e2��uȮ�	�bԟ즮N[8���f�Y�#�;�]HU�Ɏ�Pi}m9ѦH��og�����+�gMs�z&��u�^��.���$��
���L��0"��G���v�����4R8Q��k�|R��x�9�n���u��s髨��%q��� �̲S'�T�[Lw�s|�<�F�Ֆ+O�2���=��yP��Ĺ��0�6	h1r�H�����Q~Jk�Yh �o;ӣu�Flh(I�⦙v���)9�~Z'��^9r�a�)	ʉ0f_�n��)V@���*>��o	�M4`�^��\&B �����ƀxw��I�A+�x>���:�C�_�*���E����aM��۰��nB�Mt���Rt G�N��1F�l:)�\�|��R�y6��ʡ��~x7���%���2�~W
d��N�t^V�u�S3�g�~��4���V6���xpia;*w���/����@jރ���|�+����}x�c0a��ݕ�.��Ĺ�`�����Y�R����ŸW�Pݖ����r�Q�(<�1�BvBoUa�m��@��N�:��%)[|���/_����A܊�2�H�Ȍ!��RpI3!49��s(kQ��L���j��G�z�	�K:𭲔EŨ~LČL%Nްa�֧��đ�>�����)O4r_��X�f�-y1�U�H�<7�&��VA좲v:�Uo�v�NON
 J�^�V�0Z\��c�/ݴ:uy!7t'�|	$�D��}"� ����Ư��:W{��j�����ą������\�{�X���w����^;�<Tە���b�Gl���zs���8Y��Dl��`�g��LQk�A�|��,�%Z����u�h�k�<�{��r`x����g[�i�O���h����2"O���o�Ɋ�:�bN#��zOuK������Gn��@��2l�Y��Տh�t�-��lO� �}���%�ѐr{x�P\��ؠvBlįi�����;6F"��kkX�VF�Vu{@�:�8�
�.�+�s(���+Z8!�{�iz���'?�"�����͗�6�-����N��>�Y�����C��oi�t���2`���<wd�ҨK����z@�� XS���U0ǈ��V ?<&%B��#�Y�x��dV�9�ep��0�[l�Ɏ�	?p�ҫ^���ޑZ3~�X�u��Տ����E
�jB��C�I	C�����ɝ�*�/�Bl�
��]��P��픞n��]x>�,�c�)���d��z�(lL(#bsn6��� j8�ޣ�py�q�T�|�w�#��y-b�`�{f��o�.
�3m����yۊ��-�i"Zg:���I�z8>,��G��ē�l��$M�f��a(-��I�)}��-��rW�#��duZ[;�퉬k�'�Z�B9T0G2;���rqڡ������_���c�V�����6D�!��4WsZ}��:�D"��x?�pJ m8r1��&V���w=L�T%����
��[��-2R�d���D�s2	�V�79,��o��(Z)�RN�h|	�e`)���6����/������'�v+wn��L��g	k��O;�����O�ʅ��gPh#9Tw���C�?��5��UP�q�5�~=͵�j��|�	���q��7�&���m�G2\6�
L�Bw��x�U�;|4�7,zrC�՚�gׅ[����I�x�����`�O���Gz�)�J�W�¹��xР~�l�����2H5��Nd��X䎲z^�������t�ƹG��StYj�8,y����3uک�I�CGf6S�7�G㺕rz��=C�-M�ym"Lb��H���׶[�j�D�?LbQ��@��k�?���ɩ��a�f�;7y�p��1��� ���["�Ib%����L�F�QpŠ�8}2N�V�w]C�y8�Q1�1��=�-n�È�^]-DC�R7b+�*�A^�t}�*� _���C)����b�~ {˩�������Ƈk��������ļx��g����3*��r�����*��:�"� ��*����4z�vSПq�����r5��R_7U�d����$ʜU�aR� �nk�a��;.f�hW>����a����$�!3��U�x�!E9�����ݍ��qN�9� 9a��a:]@���D���sX�����|-�8S���C�$�x����\�����GMlբ�f�x$���8���.
)$���b�t��WG�X6�P��}�aUq�2g��"�cBhA�f�y�W�wz�	ibpW1��XR +�x�)�(�M4FU�W䠷�j�+!��p��M9ML�ڣ���9V'��[��CƟV�)4���5����8�}��[w{���a�ˠHJ���]���\\�k��o��k�0���������u�<��U�> �O�C�+��Pc^��C�VW��0A�kџ�$�B��'�����.V�M�v8��xVa��E�a��x�Nr��*_'���i?oK+��X�����H���o#N�'�Ä��x��՞��ZgX�S�'��C/�&�T��/�1�
����1�_�++�k+��O�1�HYc�pۗ�=7a~`���l~{��#�:Ŧ�̀L���k��8GI����c�C�������z��!q��`���_�+A�Nʪ��p�ЂN��B��d�!�j1��N>�U��lO2���k2�_f�w6���ԙ�-�[��|�(�b$f�K{)t�T�p%Kգ�Qz'�~$K���x�϶��|��]�QI� m+��q��OI͊���^e-���׃�M���lX��<��� (�n�������_�k����4�]���8�~ɱbp��\FM���e�������/V((��@���A��2���d#�ݛ���8$�A'��wvN����Z��&zl�
�̅Q�қ���D�>�����c��:��^�S=rwߩ�eUS�eF(W�E����⇮�}��"N Gy�8h���M1�z_�W�	Z7��6�Py w�I��kݒI���T��ԋ���$���sQ/�
������h�z��B{
�і�{�"���u�#�DWֻ�.�7�`�Y̺CBCM[��װ�33R�m�������N��k? 6]W������b*�5�� ��V� 7� �o��g�����Wz,ڤK��
~�l���}��AlA�X&�BI�Tt;�S��`4`�a�#�����A��o�~����X��ì�Dc��|9����_i�]��#|�
eY�n���>)�'����
��1/��U�'�H��M�9���_b�<Ҫ~Fr���<�-�N�(�v������i��@_�%`��K�i������T+�g�X��T�S�Z}=:�i-�������bp"-8���To�@�ϣ;�]�ބ@1<�i�k��ѹf�Nt�0b���SH7&	��w�*Οx�����i���(�u��C���c����	h�3��Uz}�Ƀ�O�N�A�b�?��	o �8R�ow���d���7S�$>��Qwfl�Uq������LS�i��<��2�R� �����af�=Q��u�C~0ހ<�s"2�~�>z۔��������i����i:���Sr�D�WץlV��w�	���}�T�jVp*=3�G�J�-�k0�"4}��`�F�A8u��n��Rzf��&_T��
b�ˇi��M���`P�F���PF��R��b�+��ũ�4=|���i7!��n�;_8$� ��x�w���#Ӝ�:&���7;<���6J#A�0��ߤh�p�8n����:�������b���{ͭYt)�:/Rы��� �T�N�[=���O���+��:B7��л��6)^�A�n�4���5y��>߷��<`�ʟ+x� �7S��0�h����|����.,�h�����f-��)�[ WQ�Fr�L�I!OLG���D��3v1���E��i�F퓲�|�(�}Xm��3|x#K��<#3)]�z�[�Q+_�]�#1(��
�q���.���=�J���K僯��'����&��bY�P�c�������J7��:ρP�B�'��a��5�4!((������7P�����K��>�$-��OŨ[-nSUi���_���嚠�>��4�⛪���;�47d���M�ϔA�2���w�	g�U�1>�O��b0�-<~X�N-�Z&��O��
�6�gFQQ�d�s�+,,�6�9p#`ϋ|
���D����i���'ΎHx�on��pS�Z,1Ig�.�Z}o\�Q�p�Ç<�z�%��s�y#o�P៙kL��YF��뾺�M� ,���#���rЀ��S��U�G�Y��U�)���agF���(�^D�ř�Z�n: �?j�?��q':��滤��X0&Q����(�����a�M�R���u�u�Z v]��<ٌoZV�]wQ��'�=�:�WQ��YF����]��XvR^�t�_?A�ˎ�ag�+%��KY�Eݤ�lw��;��/ +�����{��G����e�T7�����Tp
�줃&<���<O�]ն����� ���ʔ���	�w���q-_�QT�g���0S�g7��昆���ݔQIS���H9�0���y2��]��	�祰����'�b�U���ς��Eҽ���*����<o��IG)g�/u��XF
�,���r~�S�Ov4�|�3��ߋ ��+��fp_\vm���`�L0F�)��Y��t�kQ�v=�z�U���X��M�j�?����R�ҝy� }�6a�jS,}�ɔ6�sq�jx��s�w��3�Rb�\���6o��?h�Ja@���Txlnv��c�]�h �f�M	�%�^��i�/��[Y��.�<�}�i劦Z�_���ܨ�O��\s��������ϐ0{-��ߧ�,����5��i8����B��F�@�,yQ�[[�M��)kQ8��B�t9���ևT��A�1�k��IH=������ֽ�/\v�q�3�ɄD�*[�Ԕ�Bb~����B�+���t��pi�nقk;����L�cG�^:@gUH��S�Xz���FJ�P�V����H��ܶeЌAUN��ؚ���&�Yg��%qq_�%�:��YWݓ1���/�����bɧ�1���`6A����H̺NEa3�2�t��2N!��b43��� OL��"a5�.գS�FFc�P:+�t�cWP
���BB���E�c��� �zv� V�� e�����v�`HܱYG�jmc+��cBK=f�ظ�qO����#��v�k���4�#�*L�JO8�פ�T�v��l���G�^���Ȟ8�&�� ��7��B5��0f�!�@�G�eNj�/~�9�l�����v��~n�λ"�4�� ��1
Vۗ�{8\�F��=��3�v%Ƴ5s���1_uet2�ބ�V��v�ewj*U�c�Y�\����C(����U�����<7�I#ef^�Hu�*/�"i,g�v6�$�B���f���*|�ßZ�f<�!���,;��DPL���'^��C����&"���� >������~�ݭ'�G�{���l�ɓo�`�@�������](�}%�9^\/h���C��H)mz�|��ȹ�� ݤ�B �4�s�Y�+{v^�wF��K4��R����w��D��یi���&��Y�v��X��n�%��w�2r��"��!��8�-n�r���\&��86A	�o3cy���iJ��@�dL�,���.<y��M���É�Hm͐��"����OJ�� �����+3]��f9ۿw��u���m@4�<S�?b���XG���`q�:؁�(�*K�Q���<}�`MGntt4�\���8�DB�����h`0�X]ܳi�8�h�5�Xg���F�9��S��c]A�u8��i�.!wy>��p��+�T�\��{�A�SdS�����h!@�2��+ƺ���P�c9r-��U'��/l�H=g�a�ϠP��h���ӟ�00��je����l�L:���W��[ƽ�.s�NU�g3j��B�U����x�{ӂ�{�&R���h-۾��Z9����8�&~=vՂ̤lVǉq�Ώ��;5:j���׽�?c� {��U���ާ��2���h���$�Sy�h�4����2��i�]�L{�R-�s���2r��~�!� �@ /.�j6k�4��[��0��H��+�.˹��yL��G~���Z��Fj�İ��O����M��x�x���z���j2���#\lPJ,��/��D��/�QGڶ�y�;0<�MS�-�U���?�ޙ^���_ P9ם�E&��M��I;:5�MT�c'���p}[R+�֭�k��~�#Gz�V��7+��449m�$,YN?����\�����#;cF)��2�� >j�(THg�{�w7������3=��֫�v�<�J�_k�����D��}�CW��LyߝI}�0 a�ˠ4k��;�fQ�]�Ǫ���[�?i�ʁ��0��|{(qj���&1�WR�Ŭ�@���<�{9WEKȯ�Ь͋IWF��X��Bx�wTm�����AT�8nK�o7�&�w�.����� n��-O���Ȣ��%��E��m�S�E�]�PG������n����#�$|�ʨ'־�7������Z�=�6��F�E%ۓ��YjH�g�N��Ҝ��k�N�A����pH�����a�
��H��x�ŵ	�9Fw K`}x���0��N)�h]}k��q��0� ��D��6:�hF����k�ԭ)pF>?[�]z	&XP�z��je��l�׉��H ��i�������N �`�3��O�ֶ�Q��
�M9Z�0���L	L�$�c%j�v"�|+қݴɒs�����Ρ��n�{�VO��j/�^�x�Ώ'eޭ#�.���)E4Aȡ�1�er��$�<Z^��R�*y�	����E\�|?}��<::���b$��9s����Z�ڀՀ�{U2���I�O�JO�yԗ�I4�<�R�j�������@0ι2E����v���C�	Pӥ�eW�	!��mԧ�u)ױ�l����^��o�(j{��h<1/���g�/!��~���T�./�.$�	��#��aLs1Z�X�Q2
�%Ә&���8G��{�^]�w�-�(c�.\:���})1�(=��"L>i��~QE��Ǝ�Ne���/��S>�5�,l�r�Ī㱋j-w�9U�No4,�*��PQS���(&MN�x�J��n]�
ZA~L�(/��2���:o�b8y�a��W��Q�(�AW�q������*��M��<�>��_�N�.���}�_aĊ������g�^�����4�^�|�x;��:�)v���R����
��Fa耻ni�.����,H��Yk��YS�v�x ���_5�3q��_tO#��t��zM?=�6�O�ܥw| �E3<x��<�`��s�u�����w4ƕU�����W��A�xK�*��p�����ī�Ӥ�<-�Ur��+<N�LZ���+��&Y�X��7�ZOijM��&m	x�	,��"��3`oG���u��!��S�����k��+��(��D�yfޣ�y>������ϵ8��!�֔q�����]��ƾhNP��~'�:*�'j���|�Q�|�9�=�1��}N�,��~��\cA:������T�� �&K
_ a���,�ԉv��Q�Wѕ҈C!mI(�l8	:DN�@�@�۽Jf�J�=a��œ���A�\���C0��x�g�-��VjM�}ޏJF�=+�Ҁ���V�1\<L����+Fp���}ܒןğUԤgk�#�������N�|yK���ŉKO>�>�����J�w�L
Hh5�U�,v<p�=W�#֝��`+�����Ixa�%2�����~�mM�ud\�9O'G�Rkop/er��W?۔:"��HGqf��m�u��1����V�=Lz�����n滒jX�>��׶���q�u��!b�	Ϊ���t��ҭ� ��S��`y�g>���wG0�5;�Y[�V|���>��i`�@�v� �?r�Tv��(0(�ú�_ܴ��~j��Uʶ��䖒��֗�3auz�I�:u��-�2�8��Y0Wz����$�Gq!o�:�y0���?!�
�Qi��Yv!f8�Z�ђk)��sڬ��XX��RR�jp�%8/<�J ���Y�#������n�5�z}��eYx7�N>���?�4# ��F�s�d��4� B�/�_J���Y5�b*y�J�.�Y*�et�A�#��wA�[��q��*z�/�z���2�����6�1��@y�l�&�i�"|�}_��ٷ0��鏷@�bҏkC�5/�8�!�!.<���a-�& �q'����s������n�nhy��@��_�~��aE洛#-"U�)��j,`�T�7�vh��C]��X�tybt�jF�����~�}8�BV�jKo��\�zc4.9�_���ӵ�N�#���:*CUq�kB{���%�U۸C���?rJ-h��g���������q�`4�f����{����m��mN�XG����F#K���wg��V?�u���ɲ6�럴�`�z ��Yڮm�����6
8p���)l��&=�3}h�y���[�
�*u��m!��{��%ɴ$�
�j���d~���SJ�������M�\��=+��/�r�����m�'�K3�n�w�1�h��)*���*�x�|z�{�x�W_�e�1���i,nxQ��N��5�"�w��m�"*N?�s5���j�6Lb�np*EGZ03�+ �;@S%A�e��� ˏ�;iQp��Hba����9��`�T[G5/��%Q���]�)��k}����Q�_ܶ�9���f>�|��6��i���~��p�׹���d0�[���c�3�V�{�y�3�<�g4�B��M,�dis���З�A
Q�/��՝��	k��p�/L�e��GvC��,s����{�M'ۇw����O�d�����E�b�+,��Jp�1��7��\��x贀9Ky4�,"�"�'4>S:3�����Q������I��~"���:�ɺ�
rqB^ZC0�͋���c��}�+SE�ⴔ���ɨ� ��C�}D�-���6��=�K��Eǥ�w���.�';���E����X��ia�ر��#d��TH`b��sj�p�<���ן∾���/�v��[wm ���J��'XX����Z���W[$qӟ���e3�E�$I�bM������(X^y��evⳫM���!���
�ih"	�%���q��Z=X_��lcDl`�f�X���v�V���
��@^���'\�r|�I:nx!��
��ӆ�����S�7�u:1��R6	�w��t �3B�Jv?:���v$�]>�#)n�2�֕�^M&��o0O��+��s�$a~z9pn���{���5:��!:S!���\�)�'��Yb�x�n �����q<�V�^Њ��lF����k6�!"��W�SY`��1��qc�|�;�洯�[��y����<����>>2���"̎$��e�u�3g�}^j<��G��0S��z�<�/f�b��`t��J��	ь��>�
����+���e�������繣�3�=f��.a�qt�2�g_kF�?
�r$׀�Ѕ#�g[�;���$�ݖ�b?u0��k�b�4�G��F׿���'�!B��Tk���{��e<�JB(�XZ��Po+�s-s)@�Ġ�v�����	��_q���݉�L�	��S<K ��r�0��9�C>a�=�Z�j����()��}����b�����`̣x)�V��7؉Q\�;+l�T���w�y0Qs@���� ��6¾�e\G%s��_��T��լ��o���ԡ�f��mk�+���fk��ī+j�uR�|H6�&.��K�Hb7yKT
%����h4'=}�����4�`X��c0��.
��K{OM�}��I-*��Y�:��  �ǖM��g�y�!<��UȐ��Z�Hp��]��Gf�H��L�}l7wK���?��hE�e� ��}ͺ���ˎD�P��*�{Gc���c���:V�4�;���N��iw�,�9�Y�>�{��(`Nb8�O�O�����B/ѾE50���nʖ�n���=
���5<���(y�fV���?�4��<�{�u	5琉��1�3�ヶS��p�t�-6�ྏk���U�$ciҩ�Cr��}+i~1�K�
�F���"3���ۆ�+hH~�x5	�����y�XS�Z>n��O��誮F�Й���	���#��ȜuV�qF�֞];̸�RN�z)�&Y߼C�d���dM͆�m1rO��ŧ�Yr��r�|
bipͤ�}�����y$��v���|`�P�b��r�n�Ԕ���a�����h�w׀?�Ry�A8Ŷ*:�t��(q��xNyO;n�4��Ԭ��*������H�7���hI��g���h���g�` Ɂ�~v(.��dZf��� ���y�l���<m�n�����#�~�m:�ʼ�1hݗ���g����8o�8�6�(��2/���Q��u�9\4��;�ON`��t���߼�@a��x���w���a۵��°���*@خ3o{`��T���D?W�<���v���#Rҷp�)�Z�%�����φx&km1�Õ���K��C2>���M'�$F,e��_�~Z� 	2�	A�pG\��DH�{�@_���)��x�`j_���t�j`d8(��د�Y�8z�C��1R^4�D���]�*����e�L6����NQ�<%����X[�`a�dp\%�xI��!�R�����RmJ5{�D�o_��<��Ѩ��e9�.IW�b���pK�`ˢi�C(n�^�o:�3���i6)��Z;dVjX��d98�,$�ʐ�)���=����ߏ�q��f#����$2�3��:�8��٥��m��m-���#f層t����=�0�h9�J/�#P�`���cLA�z���^���&#:�.S����Z�Xx� �股�s��b��r��m�m���v�@Υ%.�X+![j�dU[QJ�t��cC��i�ʗ�^���K?���N�EA;�f��.�+	#$��RL�w&�D�Lϳ���ń�q2�S�p�'�����Op�Ջ��.B�w
ԗ�_ IyGA?L\�aMɛ��ȇ�u+�SK�h~�
����@��p����`�_0���_��
?�Y]���D,�&Ӎ/�hpf��Pxs�o*a�'��c�+"���)2f��~����Aq�g�������N� �SRYH���w�.r�,9���|Mr`�!�Z�����*��,��/���K�FL���N4�و��������Kg$����Ѭ U0=�2�;��,q��ϔܳMқ�ad3��8��3��B�Ң�SF�F��Q�k��u�T�,S�/���q�0D���������Z0����G�4K��t� ^�'�@��!i�yUPː9	�]!0��'�����������R`�/E##���_ �̲����u=�,x������:��޻(Ջ��b����2��3eJ��ϔ)��4��\��Z&�?�v���t�B��2C��=_�:�T[����	��	� �h�OGlY���B  �Ի���C� ���Xj�ı�g�    YZ