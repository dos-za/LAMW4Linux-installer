#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="38061698"
MD5="e12c3786ddf0aa3e8ab27a7f52189088"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23332"
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
	echo Date of packaging: Wed Jul 28 04:24:38 -03 2021
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D��� h��3&r_BMR��RϚa��i
3����9��+e(�R�	�t!�`�y��#g|���x%;+���T渚�k�֌|�3>)���o�蝋cR���`�RB��Ez�{LՆVN��|��?�맥Qhx  �f����i���$e� M�1�,E�;^����vy,�g�
crs�Յo�a!��͙Pr�v�M�=�j�&�k-?r�Y��ͩ�F?����T&ut�'��'>��4�
�Ƭ7��hL+�5�/+TI���eɲ:����=\bR��	!Es�9���/��e��ë�@o�?%�;Fm*h)��tS���@l���G͎�@�8XI)$��)~�0i�<��3�*���ۅ4�!H��cr�fu���^6jh{���s����7���(1O��}����ˠsaQ���71��I���b�gZ5e�����irp^~سCKVH�y����Z�3����I�t�ک�8�����πJR���l7"_pM��U�َa����H�	M�v��g+Fuo�_5��<gA!��z�-3����ԅ�'�����A����!�HB�6��nNy��n�Y��:���0]���0i��O��@�c%�V@��;���#�+�����-�����*�d��2�ƺ��ޗ�t6��o�*t�'���"�Η��t��x�ut#[15ڒ}ufE�
~*:!!�vXH���bh��O��it�lqِZq���S]D ������pJ���3r�J64��9o�H�sYVn2M#x�B�"����&	6X��4p� �T�yu
$�e,�סd]�$G
���#���W��f]�ޓo��/��N6�<;�O�"Aq�&���:����r�b�j�G���ڂI$;��Rg]@2'����"�;��Qn+���˕��@8V�d��0R�\[�I�8Hc���6~��6���1W/Cj�~�u/��\�����)�f��wg)���s6�ư��u�B���.ky��A��zxr������j�B���w(���y�`~	p��z��jƊ(�����Ķ��(�BM�|�a|[)�����'.�|�����ge�ӯ�i��g|ь���
��R�r�o4�pԳ;J�i��l˚xɸ1����!_��r5;������C�e{�� �|�f0��ƪF�������۟[L~�	+d�~�ȑ���Cg�p1��s=�;!���~�px�X�2�����~[��R�A}$�k���kyǇ�b}s3���1�������j�Œ�!��J�f���z +�;��V�d����FŀKX�c�9�6e�G�A���D��Z&3�Qx�O~.'���zZyS������n:���L�ߤtp�1j�D��:kgMt֭�%;���1���|��tq�%ǜAOX (�.p��d��ں�Q��Q����L�NV>:����d(|��x�����V��0j/�f?�6��f���v��d�<�	z,�HQ=��Ew�?�o�@-昉Y��R���O�텺��Ö�ŰG�Sj�j}��մ��;�Kg��Ѕ ����$�Oy>� 6�d1p�>ϔ�?�qdew�YsPiGe��1�������X�Qc����Q�J�v���S��1����:9F�����#����$ī�&�Ē�n�@YI�-�0%�Z�,���s���&�BmÍT���W�V��d��AS��P�'�G�(�fD������8��i��v
� F@�`�Oo�\�Eߠڅ���>8!Rg4�C=�?�&H��~��L ��}�M�����������1��.�m��)��p�U�Ϙ�,�� �װ�p	��]kXѭ|�_�O^������6Xi���C��-Nr
�-����e�]��0(�"�4G7�L`�Y!x&�Y����7�
��x��]�	�c�����^�}PZf�X���[s*u�\4Ì�i!�,ԙc\;a�j}.��*�SS�-�9�ښ��S�gl)�y($$�i3�j��p�CN����c?��)�|B{��� ���*�G��xH��Z�p=B�:%O���u��ClU�z�"�A�iҦƀ�k:z@&�Bp����If�u��V�-�����܃ڂ�c=kDP��E=��UE�fk-���0�%����O��E���h��{%�� �._�zB��0T\�^�����f�60�;	�":(�����U؟���`J�����Q(��-�I@o�"d������W	��`I�k�L8�R�N�'j�0��� @�dpML�pŻ��r�c�"݇��y��+�G���LR��3�;(��a��8��]�%m����u4"��7[`u�,t�
���<M"5M�qq���3U敉̧���4����;|��ڇU��K̍��>1ܑ�o����N柪�����}�IT�e�,�&o6�m5+9Wp��BC����?�C����U�r��g1C��X�d�NwU�n��Cd�{8�P4J��܈��Oe����G�2�ĳsx�
FxV�eUá�đm�>4��6���eت�M3�����ݘ��2�5�#�c2v�d�항D�A��փ'�ı�E둱��G%>��P1��]�n�q��x�v�)��#͑\�˻�>xQ��XQ֯;j��ɖ
2�J�KF���S��e�*kƫo�.�����O��_�1S=T�x�T�ͨ��X40��D����g�̆ Gs��hI���X-J$�b��\�"��k�u�$�
��y�
;��� �B��X��p 6A��Ϗ*�m\��\L,���s����P1��ز��鶣? G��>]3�ho��6{� �;���`;rj�hq��p�n���S�9�E�t֊/����\��\�Ɨ,�6b)D\B�,Z���e�7Xv�0yƵF/�7FI+�n������%!4� ���\�c�NN�S���=��A��qp�y��㡯�0P�M��M���q=�S{l�ծ���������|�u��	��@Ҥ�ǳ �;��dY)zu��w���H4Wk�񇌞ܲ�=:@3s��r���7�!M vBO���d<�jE�4\�T���vo��6>X#�S5I�a`�=��!�����G�_��W�<[3
�IOIs[1pV�b����'ǩ�3Z���Lq�`���;\<���΅ݨ�8
��ŕ_�lL�r;/�;Y.}�3DXJ'�P�#�A����1���I`���^�n5�s�J�۶3�/p�=2�z���D���	�BF�9� ;���Q���?|/.��S���m,��)���J���+ܕ+&�q�f��3d%Sx�����	m��L�,i�2A�����^��Ūx��]���A��D�s8��f@��&�h���lC:��z�1�yCBh�����K?'"��C�j���P6(����(�L��c���YB�3E�VO�1}yS@����p�`��1��?e�j�����<$�{㕢=|\��7��U=�фe�8Yo��Z$�U ���Y��s�N�pG�"a*�؛��/F��j�gi�n�M
U��!	�A�nߧ-L%��o_�V6��s�(�Ο���^K� �$���a9�$���9H��7>�Ǧ�y짣\8�kR��Ҡ5'7�Pg���g�g�[���80�2�	�(rq/e�`(7۽�AŹ�ƌ��J�$�tQ9�n�bqb$�Oc�FR�!�h:���#׶[&��b���i�;��ҹ���LE-���$��>���T�>UK�K�\A��Z��O��y(-�_8a��0�HK�MI��b�<}�P�9>�G
�����;%5 �^x��9�ϰw���s3���I�ܷ��S�[�- i���]����C��}�L=c��g7IO�b��ay'��S������8a}$��g1J�Rx��-_�hi�XB��~K'H�GDQ�8ܙ��O{k��c���Fh���C>A�c&6E��z�'6ap(V��k=�ֳ�PS#�-.���9^�<Ǌ3���M�_C�]��Vʢ4W��#Zb�>S�Ǡ�⑙�x��T���ң�Jw�u�I<��C;�+h������D�hqDOi�b�Ș���aXv��+�1�����a���M�A�Ə������Z�c�"g��vi�������dQ�b�_��k�����?GT)!ٽ���l�k���.S����{pw��0�E`��������W�*0��6�+�͙�Ȅ �ρ��艕4#��*�
�m#���v�V�u�-���������PX|W͜�ѧ��dvCp�EKh�F���V2gl1����IB��I�H(i��ҿ��Z��J��
l�m�E�:&:[��,-u?����)u�$n�&
7�\�����ޮW�X��B���Ea��#�b����e�E�0��	� �0Op������`���w��%���?fCỗ��h�}��h�ꌇ�]~P>8��d�"#�p���2Ѷ鈴����I���̡<�����VMf�K�����0@�[[�qmáSS�2�"	�R��͔�����HE3֠R3�S�q
�+_wf��<�	�մ�x�.!껜����[��Y�G�}���ec�g�n���^r/���ǵ]��f�>ܴU�r��B�k�M��Pe��F?j�u���\�YM���x	�e�
L>�5J�K]pl���E���JW���m"V��=ю:)dӷm:��;G7vd<��Z*���� �$����य़����Qߥ���eǉCզs� ��c�;=�n&���gO�5�7*6D���!�/���߈���!�٥��l�/Q[z�,Զe4Ϙ���5Ex���ě��M������)wԳ��+e��ət�Tl���u:���WAwK����Ӡƾњ#u�+��o%�߇���`�f&����x��Ư�U�Ne`W �R߽�Z6&��d���ǿ���;(I�,f��1^@���i���|q����P˽�l�T�-o����eD�J���y-������8��1!�]B_���^TZ@�9�>l8Oj�jcv����&�H�։�,+�+�Z*`��=G8�e���(����u,$l��l?�E��h$З�+�M�4�l���9���Yh�[��T2a��Y�@Q���Ǐ16���[�lj}I���;MDP+�iJ+i�D��E0]!R���e�9��	6MPN|�d�\c�r ���s��]ڒ�٢ɾV3�����l�C��HR-a�C���_h�����5\Tʝ��7	H�*��а��n�����������^�@�jFa,Fì>�O�g�;[��y�҆�b�M �N��5��}q�ɘ�y��"[�fA,EYTK �jY���:�Wf�t�L+�m�����)�`���1���T�t�J��k�QTu
i!,�s<�Xp�e_1��Sg
�cz�.�hjTJD����k_� ���z���-���:yz����	�I4o��]@i�!��*Id~֬����N�>i��%�r�Y+OD�`��?Ttķ�c��GI�V�Y�:����_8��%V�_?Qg4¶,V�_��N�A+����.Ȭ+�$5����:�hb�м��i٢B¬*|LP�P]&�K��oG�ǥ �C���d ̏q��!�:��l��/a�����,]0㸐z=��3C�Q��<d�y��Á�>�=� �� /�I��p4D�Bi��VK�@��&=��4��"���I����%��cDG6����9�-�a��Z����2�����������}���E��� hL�� A?�{�����㹹JW%di�4o$L��g�|IG-��J�G��@M5�}��z�y�hng�h�ɦm2�j�]�Iק����8tw�zfIk�~��o#�'�<b�:�x�e��%�?�U����z���L�o����P�嬧���M���y-�Ϸ��*[�ih�X���eF����n����j!���G'ދ���$�]7-ü�o��D#��G��P�ga�_y���X/���I������U��F<'�d O�tn�,d䶑�I��p�;�Z*l`d�%��Qn�e [dQ���&L�l_��"��2{G��#�)�~��`�hьQ�)6�Q籏#)R�:-@]���x+^0��I�+����i��ْFm�yw�9�����˫ڎ�I�8����u�b�~X�*B�!u
���T�q7��NsrM��<�j��F�q	?��nA���w�v���Bx��g��to��u��P��^Y`���ݼ<t�e�VLR�B̔�=��7ddo��.������3}C:�=�W� ��*�[ف�� �AվG!�Ph��˨�A-���G��c�Û�n����l'!�de��y)�#��p9}�k�����g�/����_�:���o��lXT�:1+�����E�^@"Ð�%�{.�'r����%/s�Ա�e���xӾ�g�3Q���4r�c��Mc?�GbK����'V�@����uZsץ%�P͏ů�i�{^��â�r.�?�M�[�UΪY����p~�y�GZ�� �%z���Ds�r��y��U�áE��Y��<�}�-��#w��)~A�����b�3��J���:�o�����`X�a����p,�����ݝ>��V���qx<��t�.����o�K	�c��O�~Pa�S�EI���ߚ���9�J���E�`Ԥ|���O1r��?���ׂ�����B�`
]qp�e�"IQ3).:~�hw��'��:R�g�����%��F�w���L00s���k"BR��8�i�|��;��|�ù����憯�p�csuڠ�{�/��7]�C��h�S������	&�_���P/�z�/d,Sٟ�轂\�+��F�,SG������M�Q>/�衸�}q�{�N�]͛�[ދ-5�xX�>vP�#Y�e�"k�>Ļ̾.0��<Y����CQ����Q`�����o�WJ�Ɣ�%ȏt-b��^u��V��M9.w����Ӎ������|������� ^�1R,h��_���oDA�s�BؔjY������J���_x������(%-u���tD|�J��g3�:�KNI�`]+�jw���F;[$UQ�j 䝼������,�%��/7��#�?�+���o��K��@�=�.����Z��e�G�X��8��o�>q���qf�e�s`�hX���K�}[�~�}"B������V��*<7͉��!EDSr����3f��|��Y�N���"���R���b,ܚކ~V�E��572��x2��ch�>�8Ξ�xG-K��f�j<�f�!]�� h_�F ݖ�_}m����U�7:"L���PV�x`��g��I��<��J���N3��N@���}���zaj��9� ��ߙ�vw�ƜS� ��%kE���W�B3SX�h�>��0C4�!�w� Uv�\�.�4��,�$sN�Z��R�t�+R*�H�� ��;����oK�ϻ�1a�0��\�_�!U�_.O� ��8a?� �,r�����W��\Ъs�,Ʒ��|�r�@'�����Ί;E�l�}������NœD�h���O�5~6p�a�_?��vT#�.s��Ԧ�E�dkC�n�r|��T��׵G,������[w1nGD��A�.�ԕN(|��}�=����8òŅ��Ӂ����_ˡ2�J3{t�d#�Lz����Gbr�GڋBq���������v{_�y;�	����Mኯ��Њ��u����<��o�L�/ Ξ)6��>Ӏ%��1�ң���H�4R{u�tce�ǆ(Ƽ��7
�����̠���	?0�V�*L�t
����Ї����g'-��O�����e�6��*n���/�,��O�ZMCJX�����M4�:��i۔��E3:6��{��:�o�ѷ ��`�ȸ;�{����'�� }d�
V�W�=�e�Z����/pB��2���{:I�h� [�8e1E�W�Z�����+��ڼ���,���t����5o`��Ώn�93^�u7=\���N1_��Q�6�)�hm���?|3,�%:'`(����DEs�Fg��
��1�������xst>{�L:�J	G�Çpߋ�S/��,��ךxV/�GJL[�����׵=A�m�}!�-�-�'�}�#�<�ݣ���X�9zR��%WK��T��R�T"+��;L���{p�M"��$���X��0�@�c�6�oX�-�C����0+��ԬNsm:9��Sϡ�U�sS��_����a��̥��@h+�P|�ڦ�����nu���^�*?p�\w\L����O��g�65���8�����ч!CÅu_E�gf��3���F�z�"���i=-'Q�n�c6�y�Z^��a_�w�1ƕ�'7���]�Qs8�`�ZW���7����G�jPH������v�S@���� ��/�o�Q�����ꔿ_d��4���~�[>�zD��|��_)f
�u�L��ETN��l�'������z�����~XY��'[S.6�`=N{�;��H�~	��`��Hۙ��b��-�� >��6���y����:]�t��Vc��f��a�Y����W�N�
{K4z:M�=��p��WTl~1[F2��_��D���A���x��Xs�&>yUIo�h�e����i̐����eOLU��JH��V�3o���2�ݸS�Ub;�w��H~�֮
[˯���6%t�����,Z��s���wo��^��q�Bz܅'�褝,������Yhd8�{�S|��4�s�1/��|����ܧb���!�k�zH6c�eEp�E)�5��VsU���k��}��7$�dJA���¢g�ɬ��:�V�l��3:����\��Mʘ�@��T8�i� �Qi9�Q*̰����T2��k~�Uc|�F����l�X�
� �����5̶]*e����/�������<:%*���K���N�׳�����x݈`�}q�0��7��N�Z����-�&>�_�3c7)��W����|m�#���r�F�7�I�KGr�b@�i$���;ѕgت���E��U�C�%Udi�"�\?��Z���k�8$BI-��b��o�ܖ�٭#�[�'^[Ɍ'x*�Uo������6읾+'cǕ��P��`����N������-�A���:F�J4�}=kr����Ԏ��,̨w��I��;�PA��6{���$SR�{ ڛ)L(��n~��_}��z���
�*b�N4�@]bP�[%������z��~��G�����v�����6歸ʏ��ua��Z����~)���w�^^����)�G�*�S���K�!��)���A\N���  R��QY��9��R��K)��J�̵������%�O�-t�]��*D���f����jFĜ����܍��0G�j`0�M��%n�87n�o�#��y��)o��x)���1�iΪ�m���'��~�,��2*�L��:����!�����Jt+:����k�!��M����p4�q��+��E��K2lF�[
�~H�C]X}o��ǳ���?�1BJ�����";-/�Ӛ$h2��qD����s�cl%�5�#Z�L���s�h,�'��g]�����0����O��@��N9�*~��!�9`��@�<j~�^7�g���`��b���8
��GDaLl�� \_{j�h�Jd�)'X���Z�`Z����:b�u�M&ěb�)��}�~`�I��1ײD��!��o"��<��pŪ�7=����_���}�Rs{e��?�F)z?BF鄨�,6k���0��-�0�.�m��w�⾌������:�+�����#����6ۆcl������mA)I�5�o�"�m�( 8�I�=������T��?�K��Jv��Q��퀑:N������?�Y�8}�� ���d�0k1��V��(��u���0�b��k��,�ŗ�պY�!��_$�޳��#�ؚh;K cT�w&s\�ǋ1�$�g�v����<��ٵ���\��OCH�!
x����1�+6i�������(
�G.���������T�]�r��:-��<�[ =WƤ1�bL�`��e�|M�m���*��T��6O������hg��ESf��~��x�?����jU~���s���pGz�l "�w�9<{�ht���B8�5�v��V7�*1����i�g��'&8��,1}���zC*g�?<Д[����ߘ'˕�D#��������,$��
pC���G� �lz������5#p�|a�@w�>�������v�8��+�K�4�Q�`�@���6�|0i����iU�) `
�[d�V��]����X	��%)k�����^���L/_3H��ɕ�Ł��L#�WM-�0;�O-/RKM���7��5����V�u8�9s�\���������i��?rEAԦ��ۑkqV�r�(sI/=2�X�Lc���Ď���3]�_��>��U����[~�_2T����'���;Y�T��Eyٴ�ʡ�Nt*PP�"�_�!���މқ�Al�
�*-�n�LA@�@�֔�u;�S��C��;:եRP��H_��ҽ��JB�n�t`h���2���9/�����r�@*%���='��[4���o��y�~�Ȯv$2P�Vi�Z}p���3q>���ΜXRǁ��4��P2��[']���$��[
V~!)\��1�G��t��ډ�7��l�޾E�[��3�p�w�!�с��J$j�P�����Bn�6���1�~~UMƧ��0d}�j����<��� A�Q��H�s��򔈙�)��Z��&�����������޷G�я@�&���ʆ ��"t�`�*�iB�E��� s!��������b��¾�e5�G��v�>?7�c����&w��·��T���ߞ;a��:/ �"��W�ς�(�B�F��&X3�����?ͦ��`p�y��՚��$�x7,�p�\v2ai��:I��.RK�My�� T�O�{Km,�QtZ��Y��w����sc��	�]�kAb)�\��f>�[�'�L��V��*O������g�Ğw�7�_hPP��ľ���Y��c�"pDq�C2+�Y|�1��طZ�����f�Ģ�,;��T rI&�f#%�3��]_�u�4����a��%��f@Gi�f��������b$�M)���.^��1�c5��,�.���C��A�~��.On��+�,<�
S���6�@|a��.T0��D��s�_�.�Us��X�����8�4�%� ����*X8�z�=��6~�q�Ow֩�zu,�˼�i�j����m��S�C�0�������+���NNF������Ew	�8����t��O�Y:3[e'G��e<����1�wc�M:��6���f�2:��ꎃk�v,j��\�)b��\�5�1��U@M����Et�T.�vџ�B/�m�K�he���I�Ր��c��mqO`aK���8��p]o����8&��?y�����F	Y�L��4
8�'�Sb^����~�v{����3�@�ׄ�e�̞�Xr��`�[�l~�ϥ0��i7V�#�"�C]J۸W���&�1�
��Sqڑ.C<� _ם2���d��j��h��!-?"���u�)���BC4[��Ek-�N�L/m7��!��7�;Z����5<��A- ������2<C�!�g|Ʀ��a����T�&I6��n��;򠹨Q�/ ������Y�O7���_"_[�Ǣ�奏\�,g��'�z:B�O��"�6
9ʤF2�����t Gkr���܇��dg�4�۝�m�Ono��d�m>�\B�2HߖAW&K�w~��We�3���ӹ�$Ւ�ؚ��21,���盠��-2����
L����WD�.e�7�N�P<�ȧd�K򸈣�m\msG0��lc�(!]���� ?����F�J�:!ȿ�o���j�`{�gˬ��4���&:B���	$}�d�ؗ�T��P��e`aL��\�'��oH��R_"K�W��G��$�s�M��i&�`p]�`��j��Z����y���+�+�Yo�y����EQ�[��˭"$����"Ex̞�EB�x��;T�]��m�IWɝ���g/��
0<�4�\��մQ���l���[Z�g���"�?_C��$f�U�b%�fS��8�|�+8����	��ʝR����7���Es<���ʪ��BiR��x@�X��"��0�9��R��.��OK��!B��K%�"ItL����/-�1�\��۞#�bS��S�!�N��zT��u+������u�a�ɦ�xڥ��0i�(bt_D��E5i�Gu2�Oo7�Rw0Ϊ�[^�KH�^�
��\T�uV���>��L�-��u�1��]m�2�E3���f!_#��} �V�����9�NO��"ԹI��j8,��w��ByaB(fB#��$���P�q���49!ռ�Z)*�"�GsaZ���|���z#2���}:p\dne_:�S-�Qr� 7��K�_�����8=�X%Sӛ�c�=���2u\�X�9��h-��!q'_z�~�e��e9�����ޯ���8�թ��.�ʙ�~�mӭ>W;�'��ixWG��[��`���u (�wEG' 1 ��g�H<�d]\���8�}��PӶ�e8���@���O%��>��¦�ĕ���1M�Vl��EF"�>�X��443���:�9��������?@�$Ӭ��\�"#�X5_��,o�Rt,�F}��|�9q�g>J�^�W)={0�\�� P�O^����=׫��am�1l�dZ��7��Ԗ����|6k�0>��[�c�5Wd6 ����KԄ��d�E�/�h�)�AGy��,�����렢e]�҉(�����{����x�򺽶�Y_����^�٩`M�`����O�̮w˭�P��y���1/ƻF<��~���(���~�l%�E3**��w� T���~��郿�1��s%U�dy.|����莅���������x������ܸ��93rɏZ*�>8`�q1����T�7�Ǆ�o*�2h�#�_�5BMcV��P��)��tUJF�x��
Y哩'�I������dh���S�B#$�=�N�W>�)8f��=ф 37� D����(�VW^����}cu8�Ⲥ�k���<Z�g{�E�
�KòN!��E�WA�d(��R2ڊ?�F�w��QT���%*�'�S�=�w���]�^�z�����%�x�>U*kH���_��������,�Ʉ�����v�[�����΁�a~��B�~�K�1H�#/��4tb��!��X�Z8L��պ��
�h��H�b��Xj]k](dķ�ƮK���V��3������ER><*��{p�4�z�cS.�Hi�SO��(5�[����5`�5�T��ŊAC.r���.yEy��JĦ���m��-������^t�a�c�����K�W����͛͝0�⦇����^n��K�dmP*����H��xm��אT����8�p��t�v�\ ��Tj6:��|R�2�|�ƺY�B�@Ӻwl�i_����Io^�T��I�7�M������"�u\���zt}/���0�ඃKup  ��BMG����ߺ_��1F6��@�iD��H��#!c��6�Y��TV��b�^�ׇ�5r �jB��b~m��a[|�j����Y8mas{���:r׼VP�>���cTПRo��)����(7���n����K�UP',��}��Ό4I���#А��G��dL^V�9ֹ !nxS�������4���ǋ���7'`�XB���K�vr3�/.=W�d����N.6�}4nZGi��`�]�xbQ~H~�2i���g,	f�mXH�D��]�#��}�|`��`8��ަ"Qm�P
wI=�Z��;�K�?��JT�Eʌ& ����ZT�Y��J���y��SE\�
�_o�t�_�$��yXL�o`�@��M�ԎyA��(��B#���fS j:�L�e������� s��<22�ܟW�Y�L{�s�w��N�\_��n�s��_����8��R ߧ��s�W�wK�RO�P��5�#��%��:!N�!��N�ߛ�����y$@��;�`q�W6�e�Y��k�QQr�z�f?��*d��%�&rG�J��~3������\��D'��=�tY�h5�r!���.:����Q���x(��oxJD
���>*[�U\)T���.�Ӡs�.�C^�� ���k����+�K�tz�ظ����eq.k��D�`a�O�Lfa�K��&���i=�g� �fOn{�����}_�z/ؔ��&�_w�����(8ʧ5���׉�� �����ܖ�s��;�!�>E��4O��L)=$jӈ�q�n�9�u�`u�J$AW��i��0�� �
�^�H���Ӥ_l�4B]ܝ����g��H�auN��ș]���7u���i����A�dt�ٽJ�A��|�y�Rw`"�*�zK����L�����,!��{����2VZ5V�'�h�5�Vy8�Ӱ{z��X,Y��Xnz.6�Zݖz1��pZ�*/�Y��t�*{���WE�r�$��\�z1��J�w�[������x��1Z>r,׮sl|�$���sǹ�����hg�@�_Gۗ%;}��2�4"��6_<�j` ]� ���P(�cq��.��\�殪"�Иw�&�C �i
��ˉ5\xG�F����bS�X3�#��b���0i��m�non�� �&[�����o�iP��ʹ��I.�Dї͇����8épƧ�O��~��Sk��Cz�4�S��jkxY&��{�Ts�{����h֯5�q�cS1a�	M�R�D8L0�N��F�(��Tp>�����F���� �6n>N�l(�*�U�_�Us���/w�`<6]�������Y@�'����/ä���,	Sv�����S�c���a�7i,S�#ր?'�w>�-���(c�M�TS��L2Z7�x�ͪ)�P�W���os�.���ѐ��y�F2Л�:��D�b'��U�4���#i�7�
���T<jԘ+���E/	n�?���o��a=������ߞú�8�[�^7qrN�4=e�z��9�C��%�Ђ��Rt �[8��Y��9嵠AN *xȞe�|J̯����Ǝɬ�:��XoJ�nn7F���M��_ -G���(�I���3P���i���jBN`aڮ�3 $��8Sn�Y�����ߨ�=Q`���H�c��z&S���i{��Y���#�I�G��������p��8���ӡ��kH�3%hh���%�B!��G�cs��c4Q�" �z���)۴y��5����C��D Ϥ#]ǹ`	Aj7u�[����Tp����<Y�i:ھ���Q/��H������O� j��dBId羷YY�R��oab��	R�9�&3�V�i~�z�uk#���L
ٯd:]A`"��Uzar+�t�p�XabD�ہ��݇4-���z�} :!!o�1��+�[6idt��̓�d������ �;�?
�.t����(�w��.�@7Vi�����ۍ0�n�ؽi�����-Ԑ�ih�	��0~�2N	�����]T�$Ҧ�eA��-w c����ᰘ��p�B'n"�H���}�-[
����}���l/˖��[��;*�����b������5V@�j�m�A�;���FA2R�B;c4�����m��׾mA�cke��5��)7�S��?�JM�a�=E$)��Z�~�=E��������G�j"xj���d��̶�p�*��D�0j	 %��^�q�#~YS��T�����|]|M��n�_�
�'*�j�(�����LS���(W���i%�>�Q~��~̉`(���ZT9�9O({F�b��|�����Hfr��-�w��!8|O��5�&d(�=ˋ�h�$�i��7? �Y`�����U��-�:�Y�C�{�s,6��ޓ,z��@=���.�3<��hT|U���%��-Tjsc�wQۏVI?��P^��׆���*�υ�jiD>����FR?�	ѳ�H�q[��t�#��\�l&�.Tr�G�i{��?�yW4�CI)9�#�������3 ��t�d���'Os7�ԟ�`�=����j�^>ū��k���T�fɸ���� �I��Ѯ4!�\_�
hoe"rnܛ�X�񿒿!�s��<�A�է�CT�b��	�����ʭ��'���1<����^ ��>��O�íH@a��HN[��$�������*� ���/�ʤ^�h)�fu��b{�-���[5�3���QʱE��Z,��S~���E�Bp�Qm�y���!�H��a�Y9�&өh�T���s*�L06�j=.k^K��a��j��'�Guv��YX��VJ�L�G�O����,��_��+)�!*k�N���Ё�V��1��E��Ȉ:Ya���_>7��k/�aO�O�迖��ݖ�e�&w���s�ܞ���!m ����/-���Ik\/M���-��x�|u�z���,�^Q_�LUƣ�ݐF:y�Nm=�?�B����\�'6�/��r��v*W��eykذqZ;����ǡ+�*~�LY@�}vF ���b�>&�N��m*B�+�\������]!Nh���<���&[HbS��M��3�Hd���j(�A�-]#�_Z��j��b���Y��K��>�Q�n�rw�g�Z��I�<��2h�1����ܜ"����j���Wf=�k�p�y��AH�¬'Yż��tzE��^$��u@�m��mMt����7g����k�d�e-/�%[C@}'�Y>��L/K�eS0�b��x��� ��[��SL��jm�ة��2N�0��iRD���/k�?����)�> M�_�nM����J@��~
���$���Z��J�}���V����yjh}�Zwgu�V00v-Qi �۳����T=E���P[�Q/@F�1F E��^�����m�fl, $�@aB ���ֳG��) � ���=zDf�O�:�h�
|"��, �N�5��䨔:��@�s�\l[u�Z=��!ь ��8�,����@1�ǑV6�Փ��I�����ߝL���+�;i�{�zС/k��'�?Of���x��+]���0�)���YON�o)Ze�~ZwUl�}#�2O�Fڿ�H��#�l�˄@5�|��5S�2=�S�M�����c����F��dU�_����l'Qzi���(B��=$��YU�bps�b��^(��bVeѷ�e�b+�T��ߛ���#` |��1
�j$H}�va��|&c֛�r��g�Ox�u�x����#����[�Ͱ'rrf,�ZX!*�R��Ý*����|qК��[�-HX"��?��-o����^���ը� �v1yI�0㛶�����L�2�pL�r�����/��s1 �}���7~5��cQ�Q+��(�ku�f�L��>�ktk��0�o�5�F@F)�e,o�#�#���y�:)$�׋mŢCQ�l��5A琂&P]���8��²#޲,�/������ZgE+Z�I��7�� ��қdu���q)�ڿN��}��7��x#a@l9���G�=�'���5Qx�5^v@��9<�K�Ѓ����}s�^3����iv0}���^$d���ޝ1����&�/�*����u#�j�Hݒ*<���ʚ�4�ef�|ᓀ���������8Yc�-��)�lzi�Mq�x��RU���oRn��h�'����#]�߁,E�R=���.���AlP�@/�'DzT9.M1�p�6�����6��Ԥu!�B�ޘn�n�V�=�պ܎�M���9gͱn_�-
ʉ��Ĵ[��fh:��G)�A��Zm�a���Sx�1A?z=_K�Q�S�J�T*�W��c�-��P�y$�l���X�P�+�u��32 7��~�x:K�޿L|����a0�7��^À)��|��n��!����z��@]��U����J_0�u����R 7�Za�Q���7z	�~�bK��������4������19s)��L�qʇ�������OH7�:��{���ڡ�
�G�?�W �#�֌_*�yCA.aV�r��=�����R���8~3
/׀�yJz{�b����*5d��XsF�o��ip�sw�Iz����Y�\ߤLǈ갵?�Gh�?)*J�J�H���-\t-+��$����U�R�!���}��B�)[.�8���)���I��Z�A�]���(�[�\o�O��a�� W����h3��l�x�*��ɲtjKE�_(X)��f1���¥�a>6Oe�ѡ�? �0���Q+����d(��k[����8;�'52��e�`�A[�~,}ݱ��.1�J�Yԏ5��Q�Xs���r�Rh/\������k�&H��!a�GYwǊ�U-B��čTɈ@����C��Np�F�uoRzنv�P~=JL�a�qqB����75���z�ˀюX�ҙĤGiX���)���Jaf�����:��_��(�<w"9��	~r�U^Q�V��Ǘ0UW�0��ћ#�v1˷�i���M�	��{� _s Y}_7��er7�
Gq��#EW����+����D�r&Y�A�I0�0���ms�+)�{؄��]L��WU�)��>�@��Z���d��)�t摍H�_Nnc� 5�݁�<n����q��^MN����������������O�=�G�"�9#����	��KET[(ny� �(ח�I~&��p	2�Ɉ+Ճ�G�[�i{�0����wD	�1(M��,�o*���z�Į	rQ�[���p����<���	J8ȱi�i�ww��g`���f�Z�#C]Ժ��q��cV���������8�(Ez]�$-�o�Id��۵��hr�ٲ)�����f���;|�YyӰǐ�7Ej�����Z+�cj�<�ER�}1���aE\]9)�> nN��J�(pA��m�0EAE�J^��ѯ�� sBǘf�,�f�ewԽ���k��4�����m�OF�(���'c3�lD"�h�*<ܨ�ճ�=8���_���]�B�gM��'
���}���OU�Š��1���[���L�;������Zq7h|_�K *m��ɬ��n��Ժd\����r�إiUq*�P�s;s_�}K.-?����^"&��ʄ��9��ʈRj�]��{STц�|IR �9��I1<H=�o3挘�b��
d��R f;�̸��1
��v��}5R͉�GG��7@[��o�Ec��b�Pv�5�j�t�<��"��֜}o��ۚ�����Ht�z�[�4d!>�W@�df�cq�p~K}�km�p��y5�a�<���;�D+.H?Xz���cɏ)�i�َ��r��q/�a��y�����G��ǁ�k��LM&�9б��k�����%FK,�$U����]����6%b��x�D�����t8p6�p%:�ՙ������rk���:�*1<��;J~������z�*��<�L�^h�;���^!�UsH����}��R7܈�O���Ȳ^�o�h�	C��DZ��X,���4z_��@���4�o+��6_|���������̈́�Lf�e|W}~8=�m�.��9�ԏ�|�v�
��$�3��U�*���\j:ͧ��͒ۻ2��c��bW������[�r��0	=�
��Nc��^�����}�v�� ��Rx�=�T��u���)�NS'{�e�r{��Ǚ�>|O�L�s�#C~��'�}�ǒ;��N�K3>P�� U�-j%;8���!����Q������r�!��u��c�їX�ո�}#o��m�^)X]��=�קRo(�`G�.��7X�������Ҙ�k��g�ч��;/j�����	�k��2�gł�`�r-i8PU.���*��S?oxup�1e��2AD���/�.4��S)�@%0*���8�(�r��B�X,Ar��p!C]k�b;Z��esh�@\�EIs�\S^�lX�=qp�8^�91��]�[�
�O#�;\�*�8cۡ -�Q�-�<��,�X�������|�T&���O<�����>����4 �/#����k�g����Ί�g#��,�����}�Pɠ���c�p��+:�%�GQFR`M[Yl��DQ��a���
1�)"�������ۦ-��H9u�Բ���%�u?�O�����ެ-��������b+����9q���0T�Dk׼����j��Ziof�A~t�_�A2���8)6�p8ђ�a}�2����oԬEx�fR�	�ِ��V��eie5�ޣ<�֮ۄ�ڊ/���V��$�'��s\�PJ���4�;w_J��e,�
��Y4���5[`���ْX�`e�1	ګ픱�Pd�ۀ��!��� �I���o_,�ݮ�ַ<�[XS������z���s�?�|����.�NS�^X�O0݅��rN1�\��C��8�����y�ذo9�Ot
��ݐ����VUi��Z�yH˷�����B#tH�aJ��2�������e�Y��u�*�T����dŐSI�L����|���P8����/��{��?~=���Yڴ��4��)�����GN0�BI��������������H���3����eEd�����{ �/�#��7��Z�';�����Tr��"N��ޥ���QW�O*6�.w����JpQ���P�]��_2�9Y��u΋���2�� ��r�meP�SS��j �jǷ�5�TT߹�L��A���r�#�R��
� �E��qG��"F­b,O0~�nw���8����'
z'����[���O��Z�q$5���'{2�3wc�
�)���9�+E����֤���I�.�rgC;�m��na&R *�+->b�/H��R���mţ�-�(~����?zVp5��=���u���|����c3M��Jӊ�{�S�R	�QO������ҍ��B�"���-E�t�ƴ�_�m���WKh�xbS���{@�fҖe��W�_�xt�6�/��:��S/�z�$�Z�7 ǋ�%�a�m��	�o������� �*�#���@������l�R�����3B�r�#���I*N�m��(_S�H.d�1]hî�G�ΐ*��_��e�3���9(�A�([&h��Fg��~�W�N�;(�Ň�]�yo�z�zs��5�j$���5>'��Q
��˃�b�b
�&VZ�-��*�?2��˨�k��w{��[/<�s�p�Tf2�����?m�q�҆'��ǎF�M�	� T�'X�����h��^go��袘I�ĝ+��ֵw�՟�����bq�L�(��=����$��J��X�=U��X+[�¼.,����>�q���>��V���#��9�ff�cm����B�.zRۜJ���S�z��b-�V�`��i_g+��^���%�3=�j��r"��y�I�7�-՞���f����,���>r]��qS�R �k��np%�"��X~y�fuґ���s�"4��x@z��Jn̼�-ݺ��"��G0���>�peZ�^{EDq�۝#9���u]��.c��S^�獫ti*C�h��a�h�4��H��0K���ά�M��.�����J���N���-z�l$#��-�z��}_�b8A\��^wL�&��k�W:�N�4ؖ����#Z���ƴ���ɒw'�:!�^�����UJi��r>��츯�N��q#�����M��թ:�7q��3� ��'�|T��4ɉƽG.J{aa0u98����H(���u��c"�t��E�a%��_ǆ� �2 6kX\����:zS�]�]��`��x�K���2��ˏާNE~�7���%��Ղ��f:0C��h9�$inQ[�R�`��R9�S��jb���<\�gJز�����wP\cB/~7!�̕"%�%����o�H'l�4���y����K�K@B�r��lUg۪�����9���5��	�H��<��>��#�)�5vn�~��ς">�1�>#��9['�D�S�K0��&�ce���P.��)׫��=U����9�ŵ�%�٭U	�y�%U������x���H\���¦�_F���"�+�������Ƈ��7x^��~����g]���f!0��tkbD��=_�L���.�5���ީJ#��,>t��v&���B��>�@XӦ��E���[�{���������)��ďt�=�<.��x��"B�����b�Q.�������N;F�����/��Ik`}�k{�#j��x���k��M5�#���}�1���r�NH4��^X� GNQ�v#nq��\�Uz�����|�=n.��<ߟ�w���,5�wA��;NW��_���:ـ.�xTtT��?�����-bE}�͊�;Җ^�%�qZI�}3�tX�J��{�4o��f�Wm��H�k�6�P�G����L���(>a������}3�$�6��D��i�m�ɮT+�>X�:{����Ij��@(%O�l����XD�ge�?ŕ@���;p��G�"�&y�&3�Z�m����Io�(�B=h����dq8z��T�#��0�a{$�i��3L��&��%�U�6_��w����A9�6�T]�q����c�J�>�~�0>9��1k_��T����C�˱���H2N�T"�����XL|�I~�ug��i3�3�I��HP�g<�� ��s�5�C�I����r�^��B!�Dkm��^A!CE������\������`���G�>�2
�då�,�SE��(�}$��2�K+���݂_����[����y}GJA�����= �]����8��Cl����
�쪮�2�}���$��6��u4&5g%����Xꅛ��At�x���Ob���z  sC�e��a� �����uN��g�    YZ