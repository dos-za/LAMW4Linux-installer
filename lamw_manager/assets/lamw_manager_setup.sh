#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1809683372"
MD5="1259ba295273d3e7a70a9e676a1d8f88"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23580"
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
	echo Date of packaging: Fri Aug 20 11:49:22 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�o�~t�p����[�Y����7*	���G$�*��u�Sx�LJJ3ۆ�5��f�ȆiS����<��e�ci��2�Q�7mP�f��_@ٻ��ꏭ���ȴlA(�ϐ�x���o#�̳��1`��n\e�']h���E�2���$ň\��	���ϥ)�K0��3��׷���������Y�Q]��r�@�$��iuk]� ���`S/ɖG�}g��zo#ܫE�I3���m�ƱL�<P\Vc�\��;Pe��	����n�vM/<��7֋�ز�,�<Ă=�J�Bp�!ȡ��qf	NB��KS��W_>�-�"h��wPYa�h�<����[���6x�|M������������n�wA�R�
m��}��īe��<�4{8��>�U""ŋ�tg3��|��J]�0�7��[��G��Oe���P�Yy^!���GF��:<��߲"���1�����wy��q�>n��Jx2�UVG�_�a>7o�73����;��J�+��>�SSx�^���nmzPC_��uQ�}�$�6|���)��r��uଯ��~un�0L|4nv����&������x~ȫE���C޿L;��ǍB�m��8yJȸ�z}��F(	�Yx4�
�O�9~@�f8�ƏV�7�[��������#?|r��w�I{�UT�3�k'|�x{�ν9@v�6ac��qSd����j����`^� ��\_���ӍK�H�T�u{q���|e���E��fg�6�V�c���8�g��r*��cTmM�3�Za�nP��4>O	q�x���b��H�
�����1���̿1����P��W�O}��_Xڬl�G?U(�^�Z�D*SvJ �|mJ�����Mn�>�9�w�q�S�h�o�@S �܅���<��y�ߎCa�z>��J�����'R4���ʐF��BR�U�5j�
������:��a�X&��M���1����?�.-aêz��a�47�ij+葸���S8��l�5p	ؽ��v�R�bD�گ! �s-?��;��1ȿM���Qm�7�xS7\+	����+K5��RnJ�0Z�fJ�r������4wo6���;0$#�p[s7��� �=��g�w���f���b�@��[a ��V
z��RC��h�tB�McD�o�ln�u��ڏ/B���KZP?������������$4A�
���Rs� �v ��68��Q~��3q(���Uo��m������KHl�W���ECr�*N�EKc��q�z�0����|�Z=!�A鑂���8��m�"�����e�ڂ)��>�ן���<͌)�\�#?���'��.#,�y�;7���Jj+w�ūF"é;}�l��9�+�>6
*�ϙ�~>��E����8����e���wϥ �2q�Ϊ/= �H���6��i�Ci3T��UR}����_鵰}��f\�[�\L<���!M��~��A�j���;����e���>@�^�XSJ��J�/��L�n:J<M5�5[���@Xh��;���s�Щjsj���)J��6.�dv�ؙ�e��ٹ����*�ڶh�t�4�¢}s�l���5��Ű�i'�i��nと�@mЧ:4/��02�.���*g��?x����1��7�����k�"�7@��|�F	cG
3]%g�N��W<A�9�������ą�u�u��/:����	rq%�f�6��d>}Y�Rm�R`����\�i���=9R_[��@ܖqet�z�t�n+n3�/�^�_��`.	����D��Ɯ��=>���p
:�����ݹo�
A/R�v a�~#d�a���8��q�`@��F�#���DU��s[~�#��,D_"o&�ǜ���D"��.&��R*�u|V��u�p4�x�Ր��( xZ[d��U��SZR�ɯT�?Ya�V��q�_+��$yVڈ�	[����֯���O>��Ɋkp�l�(,.43�,4��U4�I�)�|`��!���?��P�7͝�9�d�t����Q��;��Ñ1�	;�7Š���-O�wp�!���p!H0>�Xٲ
*VeF��D0L��w�X!@+,[��`dxN�ue*�����J������Y��Y��h��Y�z	FS���j�*ў�����F�������{���|��h~�B�s`�+V#/�	�����t���~lo��ȍZ�qdz?
]�����R�*�X6���
]��3����&�O�J�Y��Ů��m�[<!�K�����`N�_\�InU3�A �0�_}���q����ĵ�R/�
<Ȼ�'��]�*=��-H�5y�l�a�$�(�T���>q
/)��a6c�:8�H`��M����5���{��3�b�B\&��,�Q���*�WV�>�d�ZK��9CI$3�m�
!$
�b!�&{�
�c�?����R=t���>8y@�2���@Ņ���M�!�:W�Ϡ �C��D�ڵ�,V4X���Y@~� M�+�(�M�+��l��]yl>��$���K�e��O�5x$J��T_�ء��
͆~�~�1ʋ/��4�3˖�WcT=�����4 ������H���B'��$?�4)O�z8C���ťl�g�a��ܠ����U6]��?��(GD��Dt 3Bn�6�X�-y�b���U�H)M�5�WկW&�ςo�Ǿ#�7�R�ړ�v��.���
�<��Z�Tl�� \h��`X>A>H�>����2�>ӯ'�o��5��e!C$�8�>,��z����f�|[��g%3"7�N�ҿ�J���A���*MiV��Z�����ʈY�`�"w")�/cu��t��6����mp���@`�4��e��W@��@g��Py�;2����H�o,��!��0a۽�ѪCQ��9z��N�������]��<�j�\�rz�RN0��6� �㫃���m1��Q/�4�;�z�����5���vUR�����������ᕛGvf�+n�*�9�B��g�Y��C/�z[���k'�>�m�
[I�Kj���t�۾��"���Y���������n�%>G���y��Q��3p2#el4-��]�Zß���X<݂ρ�W�� Ѻ�=~]Ta����x\�O ��/�-���E��Xb�G2��i~��=2
��8����uo�x|�9���M՛@�!i&��e���&E�&X%���'���r|�%m�	�����[���B�	����S����r������ד6���I~*e1��,nmg�p��A�Og2�YS���\MO��Zs��v�p�u�W)��'TP�K�o&k'��<hWT�>@�΢m#Z|?�ZlVU}��6^>l#:q���QEK�A��Y�@��oxF�Tf��3M���?}�r�[��Z�Ľ��TicHK�^�?5�U#�G�v����<�y`�K}l�<���.��r�Bh~���+MJ��5�/���N9��㰼w�u���O˔��Z�?����taR_`_�yO���,R39��|��#!���[ZŞ�H���*�l�C_�H����1�U��0�vb�%��U����*7�<�C��&-��f�~�)�!�k��	7��{^��z�F��k���TN	�H��:�d�:�Y��b���q�1�u�rى���ʯy��:AA��Ję����̰�����C���|�9"Q� Np7	G�B��o��r�����i�#k����z��~�Ri[��� O0�����\G|ۆ2��v.��C�a\E�����|����jØ���-�r4͇���6���%4W�g@����uT$��&��.�У�B�?��>o��֯��7�<6u���~�'UÉ%�X�3B��$�cO���h']L�Z��ْb��`4h��,QOp�kd�\�b�(᳍;�%	
�ډ���-΁�KjP�aA
��A�xv��M(��,�.�"tW}�bMz�F�-�W4���mC���@�y����{�39��;�N�/iݿ���OѴ~��ݮ ݌���a���C��P�g�h�l%��+��a�F�O$��%�>A���tʃк��%Z�BN�y��*��� .�g��HOh{Җ>�P:I4��S�LT�2�)<xG�kX~ 2��stF3�8E�9�T������*�ȩ�YYQ'�Z`a�S	iu
Ơ��^���U�"է+��BY#�hf�Ǘuϟ�~XS��ƿ���3{p���-+��ӎ��l�;��Rס�d:9�U�oK�K]�} �i��X7�;�CɫR���5��)�t�m��Cq�Sxƣ����ǹH��r�
�z����[�~� P�G�#Ny�	�2�Ѧ��hWk�X5CѐW������f�%u���L
�ht
����z�!e�)��~ �Q�>@Q;Y���/:�2��?��i�����w��K�eX#��([e�\���H�&z����XxP�
C����'Ȝ��G|5L`=e=:�޲�q���l��
p-o��aCJ{cȃ�R<ev8�7##=��n��fE�Ƥ��)wo��cL�57�p�ջ�f3��h��7<D6��Dm|��Ke��2��RWM~m��Y�I�vC�d�������֘��؟E H�d�L��p�z�l�V�<a�Bn��h�z�a�x��̤ђ�"�ϭ�2�_���W�Z�{���W^& ?9!����Y��D���e����f� �H2A�ʸ^ �r6�!m>̊ݶf�D#��΃ғ�.S���RنWm�h���Wa&��ӓ#����A��8a����oi��)�W���/ճ5�'�Ԁ
I��	T^bN�q����S(2�h	�
���S�Kn�+�L9! Y���A	�Hc��� {�k�d�W=ؔ���Va��u�=����ԆIq�btOA���|�{28g����w?�'zW�ѝT�[J��~�g�C���z�9%	j`��3�!��q5�!��C�q\JK�6����R������N��l�l�v�\k�_��N�T��)��ԛ��`y���uXӈecj )�GƆj��4������r9�cr���n�$�&Q�8��j��L��~�#�pa#�"E� ܂*�u�W�V&�~˴��F����W��n�q�'
�D!�絝��pB�t�m�>)�[HܼaP����w%&0������q�w�pIH�֞FnFd�sX����xx��i2S`����(�RL�|� �(ņ���;fʽ�7Й���3���i.Ђ6����v�K3o�s��5��o�vkፈ[� �;�f�-�D}[ �;�h�F�I�b���(�A���}��4#k���;//�DX�	�М\;ީw����,�	�<I��
����W%�9>�AA��ʈr�$��] �c�������3��O)�|�a� ������	u#����A���sȺP�g*�J�3d���A	��y����ʂ��?,?��H�_g�����ݰƿ�c��Ev_�j�d�+>�s�<��!p��l����{ɒ�AOmcn��/��V��X&�B��A�qZ`��Ղ�ma���B�����'譓$E���$�_���HB�)ew�x�vS���սVhR�:R�s������Ƭkm�o�@�D��v�pMPι�-��#3~��W��D���ӧw�,��{��S!&��/�᫟ײF�вK[�8��˽{|A����7��Ʈ;k���,V���yS�fV���<���k�r�TP�M��Ϧ�2ADȬh�zv��YO�C��`����ۅF�����ܡ����>}��s�M`IS�l �̋�:�["�pSA��<^.��I�����"�B9���yj�`���Γ_x�]�Qi* �Q��(�_+����2J�f�.�4U!�J�Pq�#���Η��VedV�	���D�"� ���}{�u�W��ѣ�ym�U�)U�ϧAb��^�7�:#[�=`À���
Ӌ�X��w�$�*}�xqo7eG��#;Zh�z���;r�ڏ��YͫJIԗ���� �!z����e3�F���g��ޗ3-��{�oF�X,����[@&����?�������
��Y��GJ��{fdѻ�S*�0O|��o8��Mʃ;�͜N�	��N�[���� �,ЃAc8���gsd��rF��Ln�¦��_k��H�֠���� ޠS�t6���$���i��w��\Ϥ7d�.A*�H�<W��Asv
�5V��?A;�Mih�����&O�tf�st*[׾��C�����J��_�������mB[d������ ��(�r��N�`�ũ�yB�O�� �����L;�%�,��䷱4gVΰ���m:�s�=OE^?(]���Т�����tNk�5E���xU9�5QI�n�avcg`��m�7(<9U��V���#��^�E+��}#~�N1��mE�1�D����c�{u�w�i�!��Π�G����ˣ�{3�FB{�3�2��q�C"3�P>�n��I�5��n�P��lw����mfa�N�-AJd(� I�^�X�;;������M+f����p2�M���ͪR{�$x��1i��m���|���f��@r �v:!(�y���E!bsH��N����/�˵z�G[���]�՗?6�2B>	�&E
w���c��_�N��>GI)�X�h,�7��0�Q�:¤�T��Ɉ3�,d3r�)��I� ��!Y��\P���?#.*p�ȮQ�a��h����/+�r�*�Z�y~�1�~Ǖ��<���s#��;/�������P֣@m@�CJ�]��U��%��x����I�C�yn�j�G�$m�kV��DOV���Ʀ\�����ί�x�X��w�*���l~Q#@kv$oN\���	LN���������q��U�g3�	��Q_*�0�P�g�5��mM|Tt4����g���k�$u����t~��(�̡~���̀F��A���`��j6�b��!����`U���%�n��%�!Oa�>XÖ4���c��Zt���:7:7/��P��yR#���+��M{,���A !��kD2�_K��V9����������>"ں)
�`X��J~b?4
Bm��vb��Qq��:����q�y$+����H0/y�J.:�X�x���b��i�Nu`�i�ѽ��	�3娫V��g��3���ѩ� 6�&a�-h�E�e�@u�:��Ib0���l�yRő�k���І�o�C�0"�T��Dz���Am�_of���Xt�[{�Q@��QlO`oo��*�5t�"�PQ.t��/>��^:�	�<>�v����ZB�%Qn�W+�jĐ�f= X���%'ԥ��	���ڎ��'V+���9GT�!z�܄��G����C��4ۗ����6SX9��t|v2�>V��;�0�_�%����@��������}�Q.�(��l��»<��2�!�-�-�Z�=_+I<����8ZH^��'_��MLj�n��\�؀�6���?*FA�N�3���w$�Ktb�B]^!�Q8�2uP����~���6��"wBd��8��B*� ��㮝j���F���w�h*�ՄA�� 9p!� !�[c��6d�m���a��~�2H�3KJ�ĵb��sx3�1��NQޝe�=l�W ���Fɏ��\�V3���ZSO6��T3ej����
z<5��?O0х]��=`A�x��?Rk��� �v+"����=�����l��hS+�����d����|]�l�x޾v�p[�d�q/zi�=���ˤW����J�}�ڜ��KX�h�Y��
¶�듊����8ֿ^}�}+�\:s����7��y�ȫ?���6��T��K����ʒ���&5��L�(���ʺࡴ�����VU������S�!*�K?Q��К�1 P$]h7��%<��E��w��DQ�]ћde;M	����$�AEJ��P���H[u��K	G�&BTU�ąB�a�������7���=���0%�W�R�4�s�ad�U� �~��wh6� �&�2x���vS�I�w�V��]/<���70��� cƘ�� �j�äLY�j�������M�ޫh����G��մc8t$Z����C���j����e�o gJ4@H�k��|?���Pn��ӹ�j��?K�.�Ԁl	.C;�x��喲ڜ<�@��M����O��3�OCGb��递�R� �H�q��<}�(�i�h>`*��xZg��B��i�F�J7�t���,UL'��ː 01�Q�m� �kA��@�Y�73�� ��c�OHH�'�;�]\�َ�;G&��q1�G5����/��1�'l���¦o^�?�?�Q�(4�E\��u ���Q�hY ��(L, �%��W\vk�~�#l�`����%L=�~��OeN����R�*����=�\��=!�r:�hI���5�t�l���Zĝ����I�425$T?�䛊q�{:�����}%ĺM��:��{�����j�)����/
߇�q���+�����c�d9/F�g��m���&�D;g(�<��h��Xd�.�]e�T�)�W��kvTN�G}#b�>�O4�Yu��jmKN�r7�m9�y-8�sPp�ߍ-7s�?>��?) �U������kZ���I�0�LB��f���@��Uh�Nj��-�zI˸)uoz�*�B�q�{ۨ"�Đ��^�Q.iL�%htg�i�e-�y�ҿ��"���oU���INO/m{̟:��`NQ�F_05k�r�\S ���E����h`*�Ԓqo�*�)ɥ��� �"E�������!������/_t�#7,�6�,�?��=���l�?u������.0zc#��0�3�M���~��M�n6�C&DU��d�����ݐ-Շ�$e��l��a���$w��Q�Zό3sIL�*�,<�8\Zor*hѦ,(jM�`����MY��!����v��
ݚ��.�W�XQp3�L�ۤ�O���,�ׄ�aw�Ӵp���2���4��FA
4��&��Æ���T���ߚZڰ&Wa���&����
o��.X��X���o8 &m���=;�7HO�͌u����f�>gp o<�Z 3��d��).)������l����F�!���Y����X乄1�=W�m���������ȁ���$�*�+H��Vn�9x�;!�P蕬�Y2k��O��i$��/��<�T��S�ϋ9u�;���3�;(ZQ�|$Z � 5��DJ�Ɨ����$v���9lN�[�k��>y�_����oEK�-��SS���Pͷٲx)����zL�T0���b���$����8���������q��+JAG<í�@�b�}�<јT���e6��Jv��Dj��CjXc3���b�p����<�Ijf����ϟ�
���?7U!���n�Э��p��v�&&����}6'}��z�j��u�nV�f�{�A_�F�C60FF�Zsu�_�����:vx�&wy�<�d��Ns1E-��Z�&p�h%Q��/9�ܯ^;�w��:���D~Y(P�#�54W�"w�uA����<���K{%8���h��J�.��B���;i:SL^�3�,�>��`9�p�Z8��e�Գ�Q�o�hY�L�{x�1(3�H���?�?$ǖ��.�̢��z� ���EI��߼��9f��vr��[.]Y}�o	j��qU����y.������I+r�QJ�����d$^��E���N��7<��=*�1L�ڊs�ce/�L���W�W>����x�*ޱ&���U8;yK^5�E��;˿v�����m�#䅞N3��Xj�ӧ��°ʘ�5��+qquDX���S���Nh4X���>8b j^���R�H��^0�j���@�'v����>�Ff���}#P��Z���bO<+�H~�5�
Z0`)�薟�;/�o�}��L��9���> �ӱ���¶&
W��o��B��b�բ�5��]�ΰR�E�o���X��=�y�0��v���Ȭ���)��m�u�W�7w��t"n��f�~����%$�/��_��X3Vg|f��(�
S�a� [��9�hB�3�g�G`5�ӥ�L��է|	�5���x.���+	�7(�d�0�S�M��C4���$��3AiT��%t��r��W�)��>yU�OD��߰��
�P*�9�YB�N1M�N�WXVϿ�kS
�(�o��u�d�G\�
�	��OK_�+�d�{O�fݟ�;xi�?a-`�'��j�����d���LG�_�;�A���׽#uF�_SvA���,	�TBW|B���372o�h��F%�0�=\Q%{�:2a��K}��	�v`g�.�v�����G��>�ԟ��!���>WzG��ψ5{�-�<J  �>kF�-�Xu�:p�K�CNH�D��8ҝ(����Y���;�uB2Q=�<����UŲ�Ж\dń�>e��ɧi��h7�jヒ%0u�����&�
1N ���@�aevKN�����8�`sX�����|�QRъ��%�8h��Q�!�� �9L���,���"��WZ��2쨲����_R�1�[
���0r\\�h��O&FqИL��4iO��q�!_V.^c8&��z��y�۟7Sm�N�.oD���0�e{�1�j*n
�K���,�X�Y$"'E}�5�`���*�r깗�za7@��^�~/LONIo/�Uo��H�E�~.��Bc�Li��v�4p^�P3�	a�ETԯ�� �^��JBۆ�X��8�Qh�қnmo"m;�IJ���%�:5d�b�d�Q��%��%P�){�ټ'�v�auf�4E��xv�c�0�2��00�6���3Q�41ܘ	�0���8��(��0�3�@[�|��G�^&�����w|L�����T��L�&Q�����N|Wf��Q�� �M��'"gIe�!�]B��(?��.\�5~@�-k"G���v��I�g�%LS��)J��+�����������𐴊��;u[Ma���^2��
���� $���R�0���\w͙����1)R���ͮ;�x���������e�&���w���çw�����'_`�@+�Cf���b!�\���@��S�Ƞ��,F�7�g���W�ts�x��{>0�]r?	LEA���M�/0�&\�<Q05L�A˛�fEv�ԩ�C�c�!� �Ӿ�/�2xk�+SN� �gb~���ւ�U���Z����%B���c��{��$�`H�T���bn�J3	\7?"����U�I��A Fl�݈F��gRu1�_s�x��|���aQ����!Fy[��2�ym��Ul��#�c��e�|I\�Gl]�v2���v�^�(\LW�& ���8�郉>]cP��8Ќ�}=9Y�$k�|�9�jqq�V{�@�ȃ���1�N�
p
��]���K.�8I�xX-L������;n�3(���h#査z��&2gØ �s-�҈z1^ѷ�O7���吖���b4��)�-�H�{�+��X�D��]� �#=t;��=,2��	n!zD������5G\�.z���F��ퟵ4�若 �\A�e�O1t�Α������T��Ys��P ٞ�O,��5ʹ��ad��b4�����t���Z���$��B5���N����[�0p�����=�������5�dZk��(D�;����+�9�˄[�U�>�r{��,��t�������v�؍�4=�:T�*�K�Q�R{�:�gJX�|�)�x{��0��ci��b�MjE�u�i��ˮQ��6����ڭ:b�S7@�>j���$o]qw�HT��v�J8h�o9zb�\�;��B"Lvr�����<�e��啣�U�Z}�ibk��3h��r�ɀ\����߯�h��[�1ˬh��D�yr��W�a�<��¶y�a90��ÔzƈN�0�W���"�hq�Mf��ڤ��N>��>��E�Z�e��` �0��~n���I��V�����yGABf$�A��,0�5جǶ�ɠ�Ϫ��t��"Ĭ��"<��^#��hfA���~ݨA\f�e_���k4K4ޡ�S��î�.ΗM�j���.0��u|}(9��̏96�!��M����S�ˑn��	K|��]yQA�C/2�p�/"�ol�i�
$���i\>Q��h���@�B�L� r��l��2�	8�&�$�Y6�=?�)�%��~.yqʫק�*���x���y$��O?D�T�
0j�ژ�u��K�Kc�NI��$���lW��rXU����ɠvQ0��Nֈ\�̳\�`MzhWVh.���1��-\a�����G�A�^WRMYbw8�����o/�
B���ΨG���@�_[�����x��S.��2�z���=��*�0e�z�4 �ä�ofe�(-j�0js�N��;�	a%�ōW��)d�%�Ԅ2���B֫�Zқ��i6�DQ�z�~AC_�M�з@����F������UL�_��OzIѪ~�W��2���*�0dZHԂv�:�@����P��]k�����cZ�<�Y ;
N��1�R��q�U(�<� ����f{1Q�d:<�86YlQ�f��7��Ly2;L�x��hr4%��M�ruZ�$�ċo�����^�����Q�k��d�C�U��H��
(n�o)��O�(��]L��E���G_3�j�+�C�-���;RܺL��EǊ�׸�c�i
O��oP!���L���x �`f��b8��/f��PZ	C�	�U�C��4w՝|o�R�l�����H-{��09�f��azD-���SW��h�
�$�ub�uq�4�mm����ǳl�p�ㇲ����������DѯG�$q�|��nm��{,�p�j�O���5���,%_�|��s�B�:kx�����|�S9��K�6���e|l���\������O����	HgPh� ���2��o�T��r_�s�(�sw��^+�������o��4�ZR�}0�M�=�������οC�L�X���2ܓhS�Z���}��|�+���h�Xr/�����W:�S�A��&�ul�������)��.�ﴊ#�x|z�\Xj��ܜ7��3��]sk�M�^}�u�����o���щJ��lѿm-��΢�w؈�Т�j�O�����gɔ�����D�8�l|��gַ���Zw�V��\=��,�Z~O@Y~e*���֏���s������$hY�˭a;8���eK����L�>�B���{OO#���ɛq
ˁR�Y�����[1�����l�͵�b/B��Z=������z�͛�a�����ZՍ���l�b�Q�] 7�5���Z�p��38vV|aF�uY���E��<� @"���Su��	�2��@��CE`�4֑,��@��DP���ݾ�h������̄������~�w��ё˻8RS�*O���1!F!��[� �Dhr���<�3�����J[/~}=Gh�(�޾jC�Z����`i�wu����k�dߝ�pr�v�܀Hr[�q�F��o�GT�6�x�O��=oF#j�z�?lw����n�1�27T�pߟ�Dd�0ʶz)�	^4 +x���}r�{������s8M��<�/���_6�7ӑ����<��m����
9U����y��Mf�vj�p(������uŃ/��{\����ho}?����j.�V\P��L^���D9�Y���J�^�FG��{(��,,N�6�y���z�
�r������y��廐EFF�x��94L]:�FW�|���f5�AMwk��7�M�§��ⷢ�_w3����۾=]�}e�?q:U����K}�%��N�!�u>KnHa*��<�LH-�M<�����31E���Ȱ�4��7�;��5�O9����x�".En5_To<g,_DY���õ���0�q-�t�}�	��CU�l.�b��qnw'ӡ
oWf�F�cKt�����z+����0�A�W{��O�����n�,0_�=�>;cO_́�tш�Sx��ff��E��1���Jh�CR��������G �$���/K����F���%P��!���G�O�ג� >��� ��ϫ����>z[K]]����b5̶��!�3DkXa9`�E��������O��N΄6�G�ҹ�ؕ���	
�9PG���]qS�?%��76�᳔O�3Z�99���I6��y��Ψz�3�c�#1;���H��X�|�_�mӦ��SI�k�JO���,Z�E�}@��tEW��6����zj7�$���WIV��A���ܨ��fo��N�!��F������/y����������:�$�>~6���QI�6aF/���/1E�|�Qq<�������˔��3e�,/��'+(,:/zՓ�����e��Gh�qI�͠W��L��>�G͋�̃o"1zI�*�v�@�|3������E)����k��kT�=x�'�(�Uh�CE�éF!ʺ r!�t�#J�K��ֻ������rY��,	�u��ΞUQ[�� �u:>G��]A/�Q�` �X�6�}bAA�n�4~��q���۲��䁯��N�S�޴I�ʅ�������V�_��WXz��w 4�;�S�bFZ�A�J�u��"�t��{����U �<[���&���c���y�>:򃭵qM�Af���޹�|� X��4Aװl�YB�[�9]B�(�~�l�("�"`�C�"���y�p�U��=7P��	U�r�����mmt#-d/@�ch��X��+jHk^���*�������X�-�f_vMz�j�֗�m���ჸR��s�ݭI,�z`��5�n���=�(y�esʜ�l]�0M8��D�{d��c�fcB���y�X�ŕ�P�$�)_��=χyA�T[M�*N0�w�l��%�a>��˓e�ϩr��.im���kwΪ�5�fws�� ~pڭ�+D��+�I��a	�W��Uɩ�h&E�N)DD�Nnoa��Q���+ �����װ�V�+��������Q��֐� Fδ���@e��b������I'���V�}8��J��:�H�W˯�߭�F�$檤�E!Ea�C+�~���#�Ҭ��Z�*U4��"����ꨝp�-�"\ҥ���.�c��p�J�Q�

��+��S��ea��>ѩ�<G�T@s�!�g���lF�,�M|�M���5Oٜ����e9�cQ�j+8�Cal9Q�$�����~Y�6f�H�=���		��g�O�9�C�Z_�>�߀�ࢎe�0�>&<D�^�_
�B���O��|�X�C�6~/:N�!F��I1���>9+Zh���t�O�8~�_���E��9�Mr9��ͮy�/����)��� `t[}QN�����e�a�ZM\��(U$�3R�y��L�ƪ���e�=W+YsIx���n�cܸ�|�Hh*-��W��!݃��QKB�815#�v1�m���&;�/��Xd��Q� ����1��\��{�/�ي�$1�W��l��]��-g6���4�f��?.���Pu���`5�M�\�NB�������Dq�rq
6h�\������+3HDD�����i\�&�Ǯ��J���}聗ް�����^�²���O^F�U���0���4����;_��?Q�7��kE��Mk�t���{vfw��+0mD��|�^ ��?r�[F�ӫ./J1�����J�̛�����?�j���5c���w͆zdeDE������_�����9i:����8$�~�1��Vg�~��r����W�d����.�:�eloҘYbwafk��;`^�9��Ҋ9��Y�d�jS��XP��P��V\��>o�[�s ���)�s �Β��/J��4�u[(F��?����B{O�����
Svp�`bmN� �~:�\�h�U��A�pKI�
�u}�6oL[n�2���H8��2V�p�Q���MQUb�NnL�-,�����H���wm�]�m��@��+Ԓ �%����\��Sݗ�r5G�э�2jf&dΣ�!��CMD5����۫㴊�D�eb�����9��nun��G���N&i�I�w˿Wr�J��~4w*��+�z��@����Y�t��[�lp�I���_�3�5�ɵ�2��ua|h� ��
4��� �;�Mĳ{�1���i�}w��)�_F��P�V�u#>N��;��6��j	��#N�$y��2cb%���{�&L4�`�Ʈ� �(X����Ք��Ϟc�����H����"�f`||�t�z��u�<��E�Q �v����q3���פ�c�����7��/}� =D�Y)U�wY,��5�)l� a�˖���beA*6j�����XOf�n��3ӻ�,��#4�K��d��81$81'	:��#�>F�1(��8���[��I
M�_m�C��O[��D�M��K�a�f�Zk���`q��~j�c@��G�D�e
5����TЯi�8Xp�S��S�RSr�}��ӻ��u��˺�w�(���Y�y.���>9��3��,0��B3Bzs�UTjR��eOJԛ�(`8[��݅g��3t�kA��}�/�^���
O�	��P(Jd���.���S��:��XX����{�*+���ƳԺ_��M�;9����.v�E����H92o\`D~�:��,V��ՕC̣Ưd*q2���Yҙ��Mn��ج.��g�]i��5����9\��f?]��f�.yG-%�g+ޘi�p1ًxP�O��;��`���	�`�GN[����Y�&����2�e���X�Ż+�ދ�� ף�.�̫?^�N3}bj�m�m
�l� ��jU��nFa���^�upj��7��G��E� ��R�V�:�(�ݸ�,���{�j��_��tG'��fA���F<�dT,�+[�ib !�kyЊ(�����|�.!����)f�"x%�]sϹ0��D�GUj��<��L`��ڸ�s3�r�y.�Ω�ߤ7����F��j)���"��d�7�~N/s���t�b.!�I��{�M^�!n�b�Q�Ww�{@қ�1Ni��Af��o�^E�i31;1�X�������u�|���0Ҏ��@�n/vS�WJi�#�&m��<S��2�~ٷ9��p��C�Z���fH�M�Xl���IlhaB��V�D��) ��wJ��c�(����rE��F�h�����T�q�Mσ�;��F�����	��/s�{������%?f����F98\�&�����A��w�ߊ� e�{�:���)�7��{����,�m%5�Ei'����`4
�-���5��9b���X����/}���%1.�l���k�!���m3G?��d��&�lE�3ȅ�sc��l��)	X5�eM$[�� �Jx�y����1�]0���{83t/)7:�BE�G����eF� F�E@��ӛ�^�C˂��T�WHK �:j�P���������,=��5��|��s��E�#�K��!�)ln胱d~��<�"��{v_�%�0�i>U��
d�6E>Ǔs��H<&�������aguQߍz�	Rq����$4�q)�Xs��Q�S{zS 5*ۙv�$a0V�f\O�V�v��w��h'K�K���5��pr���p~ʋ�vx�	���j����C�|sR�lc1������;og�\�[������b���D���7�V�̆r?-G�Q!w��[����2)G	�*&����]d�MYڨ�"�Z���c�Z�Sj&ݴfx//���}���f�<�%\��Y�7R9$rpg7ёx2����l#�T#����9��B�HI���-�v��=��KzC���4nu�L9�÷�CB�e���6�!����s16�%qU�;8�[](��I�Ms���/����AL/
�[�@�i�98�=���L�g��&�8�#RɡSNk���,ͥ�a��qe(�1R��)m��;�Jv�7t��Ŕ^���t5����ט�!7yi�Tsu��|����Ԭ��D�ll������ p�2�xG�PE��}�H���y �K%���''�n�v5���@K�'�Q�Z��"E�}FpW��|0���ӥp]?�m�;�9�\;�/.;c��*Kt	w�_��,��j
kc`�*܀i�.Õ�$��J���d�	~.����j ��Ɲ7{�/�QQ��r[��
s�?���](1�����k��	��*WǬ���Ҹqhu%ۅeʢʭ�+���\�MQ	,��(��}cƝ�d��m���=� N2O�Y11��w"})�p��c:KE�T�x���m��Y#k^=%��Q�yD�{�u�)t0H�Ď�S���:_���m�{1�xeb�yl�c�V���mx�*g+����ioZx����K���;��.}6`����z�lv36�ct%Vb��T�&q�'����6���K�-�K%˳ nI���R��tyk���5������ ��K�ҭ��`~��no/Vs1������Y$�35��µ��z��1��>*	�]5����	ДG�"���@���M��~�4ɲd��	}U�[�����x�#��`t�bDN�?V�d�vJѷ��h��	��e[G�3��9}9}1�3R��[ŷ�R�"��6}%�0&FXX�"�%s��"��#���@RdO(,�0�iK�}J6v�]���`�����}9nL�}{<�w��~^���Do�ӟu�TFG�Th���Y������;�x�p�&��=Vf{rh�������Ȩ����I!8��C9��k��)�$��m�o|��,�jz1Ls�i���z�|#��?����ek����[pj�oC�iJ*ڔR+p�s �Fx=6
�g�Xح	�萓�q�3;K��c�\��{�仅�W�_^���˓��&y�|�ڱ�]�̀^�l��?Dɯ���a����� $�p�zܪB���Yx¸x�id<z��7�ח�>����}Zĩ��,P�4c[#w�~6����hj\��R�eQW$��5)X�>�G5�PO&:U亓�$e'�q�QE�(����݌�����_�4��B�`A��CmAB�l��b�M���]]�g�j�ɒXD�<�c�y^���a�#ًH����K�N�{[�4����e����ζ��[~�OfZ���_��X�ap�Z�5�L>R����ۄ�ъJt:e�@�{UM%�SR_���^ӓ>8��."����{���[���z0R?�Ԗ�<��De{��w��2��t%��]ڊ���!�4�g<�}ĥN���!p�4O�񨪑�)���)9/��4���ѳNf1�eTo�����caX��/�;��/r�y��US�Xc�[9[�	����yq�0%ז���I���7A������������ t�L�>�������F5���k\�YZ�M|��A9p~T�SW�������փ����?�F�M�L��U�]��rj�O�'px#vX"�����?҆�e�5���ITh���j�8��\E��`��
��F�
Ɍ�|Hג��=��gikJK����v+꜋�&��)%�9,��^�4��92�8���F��.� �o0Z*̌{G�W�J�a�b�c�Y��?LNH���z.'�Hh�Ӂ.9#�|p�r���[�}p'���q�|�җ�7�,/:^�X���K[4�p~��4ki]���7��=��Mb���B�i�V(۾���O"�J @�߾�����45�<r	?��qK�*�ǹA��dZcQ���zPj@F`4�`��	��%
������nW6��S��D%�bt&A!��j��yJ7U�ctʼA�����6;�C$�T�`�{ Q�7c,9c�Q
�����r9����[��p28�o�΢�)�w���%b/ E���[a��g��T^]lv$�4 ϧִ3�`�N�"��	2�o=�x^wy��Yc&I�kG��nN��߻���.��Y[��I��v��A��q�"��;��6'��l��k�
d}59�[�L�h������zW�op3��K��1۔�QȓԮH��0����|z@�w^zA�}f0��Q̆� �Ze�~�������B�QA�z�:�P�E<��G3��nq�?�p�܊\,�� ��>�̈7`����7�-�%3�;l_�����E+�=�Eun���sbM�P�/��xb�1��������=n��9�eH"�L�@E�۽�կ��(��ƻ���I��k֋ر���=�Ex�?�;����7�|޾�z����AϘ�
��Z�=�� 3a��L��1sKʸB�"�]����)I��c�	d������Ri��Ł$�[���O�Ǝ&3W{��މ;��N���"��Y��v��n��Y�Q�IQ�hHy�Aܺ�c1�%W�=,�C�0V���z{L�x�pgG>��ڀ�!u1w�\|j?�?i�ĕ��`����RY 9��lf�O��1�8��(r$�{���z�9��L@����NY�PY���i��C}�C�J϶�W���*ƝA{$��{"Y�|�W}P�;�ɲ��3Rڜ�(�c��5�Qm����݃�Bu���i$q��"� �x=���]*A��]���D�cY�V�]x+�����F.���HQ�<�mSk�&Z�L`�$�O�H�L����Yѻ�N-f��R)D~
|8qi
��@�4^�����&~�_�����"ȵ��Vb�I14ID�,��'rϯ���&�"k�5�P[f��+f���r1��:�ϰ��4����
b���4��u����#0w�6� �i��D��l[Z��Y{��e럺��<xGR��?b�^���Y��gʓ��})$���DwX��,Ę}>�0铙�ז��@�9k���C\�:(��@җ���*���1 �p�N������?����a��.�
��Q��9���� ��[�13�\�wh�;�ѴP����^,���2~�R[U�j��/|c^�J��;����u��/��0XP�ť(�r��Vx�w�3
}O�K���'9�l'B�h��Mi8\u{��'�¹
ZK�vnJP09���*�$����)��D���P�ܖ�r�(	9l����V�P8�Sq�!ΡQ�]�,��!	����v[:�kA��n͸m@��|�ы����N}je�آr�(�R��8�W�t�+��z��Ms,A=� ���u
��gM1���t�iP<	���9]zXoư�21���5qfnOr�t�l�)����z:J*I?�8m_T�-�
�����P�:w�}�!�[R���COC��A鐚����oKWv��H��m��p�o�y���u��f�O㯫�#L����t��).�1{b�#�^ �q�^
����g@ҕڧ��*�3r�:eJ�����(WhtR`Q'�-�EN�7 �3'L��,>e�1R�>g�M�÷��O{×��k�̐ѱq�0��N{5�x:U{R�F�ě���9-g���u�;`����N����
s��;T��>�	h��mV��9�}\�����ۓѼ|=��sx�-]��k�0�$^] LH=tH��T�x&�H\��~��G��pv���d[��0e,i�bEAl�>�J%���� �|,��3&��d�@���곑u���kv�\93&d�������݀�tHgc7	)Y�^اץT¾m?��`�R�@�k� 3�V��:�<�|pW�w�P$�����Wn�����S�dĹ��韶l��A\�"�~�Ȁ&�W�]U\�XZ�H�FG�>,��4L�g�笴��{N?ꭁ_	�?��!����l0l=%��ox^1�wvyqgF�$�_���Yڗ)�Ff*��&�~��*�a;��&�V��ئA����ph����G�z�L'��Hn��ݡ��Xp����M����`#�_�#���[��0Vɓ��3�<�r�������/x��ʴ�:R��]k?�����[2k��u2�}�!�.菆sF���W>��b��8õ�=��0��)V��И�+���m��0���=��'!U-ð�Aj�}��u��n�Wg#_��=����W�H��*_��ם��@�ɮA�&.|�$k*�#�o�6��G ���l%�F��-�N���Q�//���>�3qͶjN�E�r-��k�Q�fq�0x��<�"S��bJv�B'�p�����C��J�Qg�`�:�p�A��c�t������u�7��� ���ZN�)�P6pU��y���L�_,J~Cj���ӣ�E��Kz� �)r��������	%�qB��כ���ᦳ֖rϱn*EFY~bɦ�($N��)��Ex���e�3y���Ͷ�}�۲�e���g>��ة ��O� R���)K��E�=�͞I]���
)���8��M�y���,2	p�Hl�S�����4�`$�qR�׻��Y�$мˈ?�(y`�6�⹨�K�1�q�3�3����j��o���'�cyb ���i��/	E���5�������79O<�פ\����@r�������3������Cf�'����x�|�e�Ũ"�T!�̅ҐV�T��h�%��������b�����':���1��Q.���Z!Q����M��=���r�xJ��E��0/�'���P�Qʪq-9j���4�Ø�I;�Q�%	���t�h�U�X��*3c���ƦV�Vє�E���I��
;	_�s�f#s��n��$]YT�[�2���eiP�^m4Gl�h���G�_�.՝n�;#*H�1ٓd�-���Y��y��*�xXQr"���h&��f��P�L�+]W�-�����lT�L�tζʌ	�o58���Yup���X�g�ޒ��w�?8�������vi;Eq�ov�*��� ��4+��DW��_��.Y�K����?UQ���k��y��f&R[�Jk����f���  a>2H+6X��/��7�ߚ_���*������ө�TŜ�3%��B&Uf�����uI��A���ߪ�1�G������*2�g�)�����Cپ��W�d��>�ۂ�;z~ڞ����ʚ9Źn� �e&�"�9M��7u�{�aQ��J\�V���_�75��
���2�ݝ,LI���f݇���&Շ���G�����ă@���kA������g���SK��@���1���    P���]� ������n���g�    YZ