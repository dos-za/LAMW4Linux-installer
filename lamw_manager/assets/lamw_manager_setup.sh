#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1254971985"
MD5="f858c9d77effe22fbcf5d2d8bf1c00ff"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24964"
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
	echo Date of packaging: Mon Nov 15 17:02:46 -03 2021
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
�7zXZ  �ִF !   �X����aC] �}��1Dd]����P�t�F�U�Yʴ�EjF}�|OA���J�)..IpA-��=����I4�RȐbˋ�*��� z���e ����q��֎���5�k
ᵰ"���mg�Q�v1�#�ڌ�� �~|�/������"��{H���lG\ߐ����xo'w6� Ȯ��!�ĉR�� c�~�'i�VtKR(������������aڇ��G��yӏ����;���L"���nlSE%�_�T��=]T���u��b��d�s����%�g*����R��|F����zR3=�q*��o2���]���]k��¬ܳ������
+�R����0\4��|}�f�"��Z#zj����f1J`aS���A�֢ݎ��~ &�o��6%r�����������#���H�>�F�m�:���U��F�4����t�f�H�
D�}�����=��\�9: 3�ο���jF�".�u��V(�o��3.P�)�LSS1��:,:]�~��U�0$f���tE�|�m�BB��`u��ƭѢJ�tobH��G~�FH�e���r=V���������wԡ�1i�� Ґ<���d~@Q�c�ش�ĉQڹN�5]Wٞ�Ł�}��w����&k]�n�=5�����[@�Q��7�L���r�P��vm���CX��K�?}0�#��}�� V��Ƙ��cփ*�oAO�^AWgr�M���;�&���pz�FZ5�GKv�6Y�Y��I� �k�=c_�L�6�Cc�8��{��&*���j�"���/�8���o�4WTs��
����dO!\�\�k�b$�y@��e0|��ɻ@������5u���&a��k4�8�/��}n�rS�]�<B`�%��R�q���"� �F1�����Y�R�s� ���8���ui��.էʙ��v�3߂в�$��L���([�Mx���9%H&�Ѯ%K=g�4�yq]��
��.��wu�c��訇|�̬��ݼJ�B�Գ�@��=��+c9qZ��P.
kM��)S��xwQ���-�&�����z�M�#����i�Sa��h� �t�M^-f�l�C,PdI@a�+Oً��'E�*P!~�,����z�����,����'���!�$�"��j�{n����J=��Ұ��Ta\��P}"^���I�k7 �_B�t�H�L<���Ny�!k��G
�u�?7��T��z�iyD��g��O;��3����҇����,L����P3!M�m_۠5��qn�iJ�"��^c�y�b$�aF�{	��On0�Xۊ�pY��%�H���7g�����u��kҕ�aT2�xb�Kf��;��&.���x4��tND�e��s�ۅ��T$��z��mc��6I(�@�8�$|}�x�]Bh�:��b�xC�2���6;:p�|ZF��P�Һ-���"�1_�?�G��\���?��W$��mzB]V��;���HK@ӠibDڅ�Aqg�xg%�O���q��f�:*����>k$P�&��idІ[�Ө�����ke��ܠ�/�M���4�@j&� � wW�z �{�:�[	q$��P�~��5�Dv�Yt�&{��LT3�����:�
a���F��BEG������%CӸ���Q��B�YS�bM�z��4��?���yE�[I���'�8Q�|{��s(�
qG�h��15��mѳ�j4U<$�^.50���G�z{��dc�{!�!���*P�|m����~fy�O�/�v����|Ñ�V��h$�s��,��ELk��|��� D8�B(>��Xg���ݴ��+P�r�#������"��.���J���9���Nbx�[G9�<$v@�j��iy���������S��c�h��j]6� 5�s�	��ǵ�e[ˁa�4��G�	��}?:ߗ3ԁN$0Z�Z,�~��/]5����9o��f�ѧ%���X3_��Rȑe/̊/��TKdX�%���7t��y�vT��&?��U���U�|-&)\_>���"��	v��ۢ��O�;|Bf\a�9ݛ(��u8�J,��h*���j��+oʜٸa��.�x�f�{g��?.��؜�#��� ����"���[��S�o��^�����6r�i��R�����Sb��<�
���zLCWZIj
�뷋���`[:� �	��u��^n�+�8Wp��DoZU���ˠ�9Y�u�2m@{ ��L%߅���s��%'��gk@�҆$��Z���D]���:6�}K,aL��zn^�G:��S7l
�^�_~|Y�~�ۮ&��P��⃓��rO��˓<�L�VWx����b�?���	�;���'Xzq�Rg�\��W��W��F�f�>;rMJBn�3;��`�P�FH�� Y��9+zk�f�|z �_҈?�n�`��́�o ��_�=1J���������+���I"S���~(-��30n���C��\�Y��P�&Ⱥ��Qʘ[/+�Քm��=6�f�ã�ZQ������S�jG�%���0Cw�&}W�*�%�힝��#�Q��e�f?��m��.�Ih���	������~�����$R�"�����-�ٲ�Z�� �V�*nA���H�y��ps�����ʧ�,�&e/�����U�@��eD^��""E�n<�P���r�^Bsw++��%�C�q��1��Ew���2�1��4�b�[v�/�[8ֵVr�]��32U)����Uʪٮ�l�n���>���I�5����"�X&D;o�|˨#������Ρ����_J������G��݃AX�~> #V�]ϭ��˒��P�����2����>F��:@Uz8<(�}���k�[N� ��(K �;�\#o08+�gg[M�/[�!^��:�ib����� �5��C��䊻l�����;���؜���d�ӕ�=�/��a0�4��g��R%��<(-��y�b��ju�U� q�֚�c<���)����2
)Fw;n$�)}5%	��Df\��m?V�U�\���UD�Ϝ�����k��E-H�dE`�#���R�B��dkd}鞟_�������iT? .MjU!�.������I^��	����F.�K��F�Q՟��c���I�z��j@�Y�kY˲ 7�,�N�>��/fY���!c�\���E\s	���Nf>P��ˊ�|o���1�ԕi|&Va�S�GI���.(,�k�Ԕ(6���y���^�l�E��JT����#b�����J@p����}t�mƑf�61L��4�dZu/�d���nˆ,	�8S���Ⱆ�cʲ���o�۫��`�[U�>+6Y�Od�5��p�}k���6���4d � |H�>�FT0�����)�=3�g��qO߀�+`�O�4̬g�{�~�~�����w�_8>�vI��+┽ۘ&�scϦ�E-a�^8��mh��7L+	D.�H��<��^鯄�г%!Zj���N�U�qb�����J����6)����T�9����}����akލ:ӧ"��4���zGP(_2)/����	q��O(<'�Qq��]
�͑�U���6֒ף|����s�2���Uũ��Q��ͦ���y)�S�Tb7=��7$" py?N���>F,�8P�D�y��fNU*!�[]�t���8��g%q�0�x�U�ȕ��b�&^�"u��0���o��qll+v�O���)y�^�қ;�V�tu�YS��v�����:U�F��E��m�Z᥽9V�L��� ϵ��{�[<��7�����2�YU��:?%���<��7�G������k�J�ǖ(e��;8��քX�aH���Yx�G�H'�f"��z�^�UK5�	0��� ��ζ��8D�&��Ǯ��D/�af�f���^�1~U�!9��aH
�R���s{�x��`H@��i��r��H��>_"��iLҊ��6��(�>O�x��[���9zXKb�����m|��8�5�GJ���p�ޒ
�ci��O$�G��c�B7��_6�tK��i�/��������0��{�I��K��f��x��!$K8�Y��bZ�����%��/�|k��s�>*j�� ���O5r���St�RE'hh,޷qz�ܶ� ��WК�p�sLlң��v�?
_��yb�+2BƑϡ����qz�����?9	�)��7ۢ�g`�У�N\E���;�C�X=j(5㕗��Y��S��)���<^������	�NY����(Uɤ�X(������. ݈�k�%��8���CU�O5eR1:���z�\����������>�W#c��]?�d4��d@� �5������h�xv1$�^3�-�� �f��b��S���� ��rk�����!r��ߢ<�1�t�r�3��=H�/\wSTj�M���"5"����Ͼ�'�9�L�"��v��A��`~�����	�����nӳ��.191��D�����ZYUw�qp�`z�hs�����ɤ{,�$��:�BC})/�3��%�fW����W��T�i^Xb` �\� ����HJՎ5q���t�
~|�XC�)��+x�c]o=���G��Sux{�>&X~�g�\��׹����8�����2ٹH��ȑP�*0[	�M�%�N���Y�{�~Xg��5\!z)�lȖ��:��J>T<���&�ݾr�y�Ιx6��h������Kܬ��l�����:�8�^$���0�B�lÌ;��X���H��@�d�Z�k��b�=�1��x@�g�iV]�S�����Ek�r˫z�2 �yS���ؿ��}����>F0f�X���,�ű�K��	~�VMpF/�s\KW��.�>��>}C��H��qZ��FJY_��RC��~�1gs���y���BzI�(��8w�y��A��S0�?~f L|�qձ)�r9T|s�����*���E�՗po��a*�j�_��U�w&�5�ڈV��Q�T���$>��˷9�*i\z
�6&C��Ϧv?-L�PԦ��ј4ө���N�����|��@>(ve�1�o�f��Ɛ-�-N�{w:/L�����N�m3��+�a��0�i��S��*\ ��覧�����yIӋ�}<���7s��Ul��OF�RE���Pl:3�Ck� �0�AV��`p �{Z���U��Nml?42�*�a�,�?*���h*4]N����5�f����;�~`��6���G�9�b�8�{�A�V�-�DQ���(�Rr/��U^�-7�F�#r��YW��Y�F����{��P�|$v����[a��l��!ڏa�.o3׿��͊�]��G��%*�,��@���-��u(5>9��,A�]���Md6� D��Ў,a�l��:�60�b�yT��L�1L��(	p<D�%��ꆓ^�>� ]��S���<�h|P6o���[x�ﶚ��~�*�VDsO��Ìm&N=^�j��n�p��`�L�u��D:=W��#� �4�5J����%x�Y`�G��|�\�?XN0�`���6��C=e�&L�|R��-���v�g�X�˄ڎ?J�Ĺ�r�/M�؁���,"0�APU�n!q��[��4��'_t�H�B����	�gցy�0�G�k�E_�l��i?�yy��د�2�pU?��˒*�	`�Y�}���A��0VW��� d��|��}7#���2�jPXg9zQ����<�zZ5k��4ӛa1͠�1?7���J8r'�����˲F�8�x`䰂�k?84 ���8��a&��0n'�w�;�?��r1�Na�U��@s
�<7�������[a�Ӑ�۫�o��*�e&�\~ڶ#�r�Nv���s'p�V��Kh	ƿ)�"@�5�s�X�Q#�#���v� ̰��wiHI�YWʾ�S>�Vf��."Kd�� �4�~�9x��bе^��������iW]��SG�`��۸����`�A�����>h��]ۖ�����2+��;��hHF�������G�y#��^��r���5�m�W�!8G�
jD@C��=U{��x>�霼F����l=x�q���w��Å��l�2H�h~&Q�K��� ��~;��V:�Y��W���u�����ј	�z�Jĳ�H8��s'��z�B��e��x������T�P�3 �cU
�;4��lP���	�m� ��_yMa��t���j��9��� X���E^U�M�P�m�hd�����vx�S�,��HFJ�W��`��Yѭs!����8�����??�J�dg3������~h	̇���T�}6�PG�>vϟ����ӘF����õ����D=g�4~��	O���iH�/7�1p�a�!Qd�X=jgk�E���+���5ï�(s��V42O��?4L؋��{��nUML�����.��`o9��D�����|��Ӽ��8^,f��]h?�� �)G_&�Oqq�����b$�-� �:n�F3�
н�v"�0m����|YQ=�8����"�s��\v#1��4����8�2�={=g;'�%Y]���m2-U�oc�6��r�P��+� ��������Y�x.H��Ob2��5�⬶�Ou��`Y��|gf��{b�������
�>2�A�Yq����1ei{`ԃ�Y'�ɆY�^0�%z]�9�P/�"�G�����C*�����Ԛ��x��\_�I����&(/�I��"?Ɖ= 1uI��Txv�޹��
|�/�pU�$���<�� ���H�FYV���^�g&��5;���4H�h��0{X�o����e�##��Ol��Q������s��V�������s���@/?���$@��<e���׃�?�Q@3�����2��E�l�ʍ���,��ȷ={��Ri4�w�W���{�|��g`���G#�O�r�v#�x�b��/�>�w�N���>y���uX�&���+����`�J�F�/�����q�sz/�������sQ��N(��i��X��sT�jji���=���L�x���X<�G��n�LX��E�,�|��`��ʟ�<Ģ�X�)��������4�]�9b��7����t(���+F�lD�s�\ݒqL�I���|2����3	�����Z�F��q�E�~S!��1�$���ID�J�$VYd:H�R����JA���H�ɯ��3����)�j�lX���I�t��U)6MXk9�����E����7*܂K]^'>��
0�,2PQ�c�T�DAۤT��_��c�jB�A���r���e�Ja��m�cҞ�����o���I��e���@�aV 8�V���>5\M�q})'А�CcS�k.:=k�$S�'�Vp��	�'��:���?�7ܡ�[쩑�N>�L����{�۶YǊ�����zP�K��d�k���J�
�p7Đ�*�7!�Oܷ�?�)�X+)B2p�FTE/I'u�M*�Ў�?�J��l��R��6��=�%�F�/փ;��a�ԥ��b2| ��׶r'u�z=	��&��'6E�ꓙ�c�ɹ� �Qw�
B�Bc���F�_f�D��&E�y�I�������b�-�ޑ��k�bivA��t�ڰ�j<5��Ȫh8�Ⳕq@�'������!x�%������#
���磱N��N?V̀T}�g��Pb*̿�k.�%��������:�ͺ<�!O-s��s�D�מe8�'�Om��3���ՠ�X��԰�p*J��H��]�5�ѯ6%���u�����u���^�1R*�皏�S�A�Z�O�}�Kf�~ޅ<��G���_rK�ݟ=�鿿���چ}���f�%���mo
ۜ��|b�4��������n�0���(�{8����� ��k�`¸)E�$w�0?�0����J��Xێ
n��{�ufΠݰv'	t�N���8,Q]�i__ �� ��gF�}��1��d�V��� ��K�B�\N��)�J{�m`*�y��]��q HuL��'@܂���FwR.$k��/��3|/`��r���&
�L��K��Q��-���<���;��rҪˇ�o2o�
j��6n6>�,�\��sw3 ��W_��� ��&������>��C��������wa�W�N*�)T��炓�1`h=5bˈ7�ޥ�|���/���=I�XO�q��?W���F+9�,��w�Ov��Ϩ�#s����}B��b{.tT�U;Z���K���	`O�"Og57vy�Bj>(�N(�S���X�C>qj.@s~5�Z�d4Q���=�1����%/���=A��Ȋ�Y�+O^����6}&��M&��	���ocY�=ҠF����J	�;,/�.[��Wf�{ι�J��Ad`��ܛ��_$5ځh��p���C���p�dj����&&�����<�G� �C�G��e8��¹k��z	� SC��	���N.+�S��G�W�J�4}w<[��civf�-�K��$� 8-ݦ����&�?�Y���ϯ*ៜK�A�7^��!�?�S�[S/�@Iڀ�m�u����� ��Z���_���8W��I�s 1Q�q�Cp����=`�(��ď��h�w�����E#��r�/���JLɎ(�@k���ti���0����kve! ���T�*C�mJF���;*�s�/u"<�ؼN���bxq]:Z����8`�$u�U�p�E���Yh����b��Ab$�s}���}BP��۞ǒ������B3���-ܵ�Yr�z��p{���`UF��� v |DC?OZ�]X���^��h¾�%s|6r�*h���($��/�x^9�9jM��<���"�2m��q�qM���=J[�пɪږl���C�Ӏ������ὲ���na%]i0X���C�Lc��;�Fv��F(a��R��m?��f���s+zO!*x��zd���=@�v_ �L{Rg)��E����FN;�u7�@q��{����k���o�+�h�X�	R.݄1�p��1$W\ͭ:�K���������̴�����4u��U<�L�.�xӋ����*)��V댲Wγ6E�xg2�����Ɠ�D�rUo��Cą���/�IH(�6���"��ȱ�K	���|�l_*�	\�o�G/�xnO �PS)ko��He�L���'(��G���&�P
1쩼1��H!�ƖV�b +�7(�h����8sx��(�t}�X�^���ڞ�ATRM��;��e��Z:�:d��Ӣ�#�5lt�Rk���/d����ݮ9;SwU�"7qx��2�=�,.������Oe�}<Z%]֜t���B���
��h�瞒���إ�=9�<�ۢ�y�/1�\�����ͽ}�+j�]"9a��1KX�4<�?���)����V�X�-Ƶ:�;	s�R�9M�9���u�u�`��:^C�� %��`���B*��}?����uv��T�Ma�#�$��4��-l�q�K�X���K�-�`�Q|T�yɛ��Ty�1�m����.�Cd�VNicТNݺǛ/�wߑ�).����)�Ē7:�.��Ĵ1��.=�5,�y�B,�'.�o�jw����W^m����V �� �{�U7a-Xw�!v��Os8�2�Y����K;�͓����c�@P㻐�7��5p1��n1��gk��;)D���ߚځ�W�=w��v\��׿��IB�@?	fΨ��L��w���Չ�Cx��`�U�����=M�vL��b�/�������Y^p������2���1��4y��& f�<s�z�xB�S{j9P�ȰM��M�/��t�=	s:S_�e�5?ۙ���.�;�Rdd\8'��	��1�=o-U�f^\h&���={��~c����u ��oc�c⥜ݵ��/�(���߻��_^.����oo�I��'�,/�A�F��δ�ј�N�mWp���j w�c#=�?̺�	�q��E?g�x��%# �a�ȣ!d)�'ג8V:6U�gv�J/=w���
?�Q���B0�؋���8�Ϲwt@���mC�C�"�Ƶ�t�pGV�e,k ���nU��C�xq_�>A9�Ά'i���T9���R����y.�\��bמ9Umy�����/!y��2�9��O/��s(�w�O;j�2�����
@'���.��U��ܺf����	�	(�}��KO�M��<�Y򬇮�4Q��QƓŅ�L� ��$��e9|��j�0�S�(�q��vZ!��$r�A8�A�����[Z��	���A��5O�T�f�:Y�y,�`�P'��9�x����Sǀ0���
���`G�Sv�x6p�I�K��x�庨�+�<7�5���3׭�"�m���
�nn(M"�/�����`�+nC�*[�6��(��,'U�&1�r��R�:�w�4��[�� m��)�x�8* �ω��0uNi ��!�owY� �/\X2�U��~x�)�j���X���S�l������?���y����4l�L�0��k{>F�p�4Fj���:UX�֯�O>H�eq[>������d�/�%�r��`#2z^���*������n�v��|9�8HQƱ��$�%Y#��XE+�1k��_m
��$�~�~�Ռv���d�\ϴc�+���PE;�(�|eY������ғ�W�U��l��6��v0���_h.(�p��/�V���	8$�Pp�Uy0�(������Py.>nq���<4������i�	�?���6G��{� Wa���6�s��0��.W�gdC���Q�9�<�?A^<{o�<��:�e_�lE{Ѧ�!�	�0P,���ǪTy�7nX��*�������G�@쇷>4F��{-i.��<�a[���6X��I��i�%ˈ��
���H-�m=l�r��kǠ���J�Qx�H
%C5dh}Q���ub�4�,8�� .t��>��Uv��s&
]�]�X�Tloڈp�K��נ�-�VLd��ILA	l�3�Z�%It�8>Q�M^@(�(��|�d�1�1������Ҟ9/��P����2 >���j�U1�r]����x�2VUI_z����ƍ/��G��1:~����J���z�����ϦT-��[�����\��e�S��_aw��>L��jw������W��7�K�j�^X��͠�j�z
V���	H�I��7<�E�)E
[0]�i�����5 묀aR+b"�#4?}:n��s9"��D�����Ǌ�pC���c�)���Iq���@%2�:s�o�ʌ�Q2@^�[Gﶅdl�fX��(ݜ��vF��L�E�~�)�U�`1���9�a��UI>T���$O�ު4*Tc�;�r�GvJy��'=SJ�g�UW���5D�8
^�៏S����l�M��m��{^,W��L��=`l�ه�?��WgK06ၓm'l]��!�޵�:dz��B��J�~����񣃞��g���7�X[U�<�ݍx�?�a�����mT+�M_SM��h�t�V�zQ��r^�5u�2z-̙UΠLQ��Q����q)~0]{�'�������b�k�~���S��A���H�I��r�^�S�2�Wk^����@,P�	�&��&����i�_+�s��
�L�Wݍm�'S��&"���dY:FE�iS
�5?��QF6/�o� t�����V<#:r�dUZ�9bh�-��s�\+��eC�����ǟNIH�pC{��(9�x����n$���/hPlMo�ǴE��+
�8ɔZr��za@|&�i���E0������5K0�D:E�F0w��|e�?��醅�Ds<5�c]���B�"r^m;]�BY��~���)�c�э^l�N�:&y���]�θ\_�S�y_�#�ZcK����Q?ʾ�w���j��s6޴���B;�79�:S�5)� ��X�u%J���/f����+E���82f	j�����N�a���>}�?���[a��T�!�-&�B {!�_뀶���<��V(?�`>�mP���g?�V>5}��g���8[�8��
�=N9��u ��>Y��*5���80C��n����n�3J]�E����K�Ϩgz�B(���hZb^&Ne��c���&�I��T�u���CS�ƹ'����u����Q<�!�!d&8���{���m����+Y4n^�e�3�r�D�h���B� 쑻�w��t�a
�
[���o�1�Q�I��ě5BF0�ϥ���G��4���H�z@�0Χ�2���}t\N3�&�m��6�d��������1*w�N{�JxFH���d��.%��s��0Q���ԏ���CJǱ?ܗ1�F�q2pQ�W��nX��N�
��gC��F	�?�g�5	@�!@Xݧg�rB�bR�p,��aQ��gbS[��G(]��gi���;� Q�Wd-D5�]llA����'#�Z��_+����l(19ߊ�:"��E�f�a��9
��%5�����n?�ѿ�o��GzlVaC!�&�oT-�-���ܢ!jPb���͏n�y�;7�Dw`�d�3�$3��*7a�ƭ�`%f4�k��0b��̜�>b���i�+�E����ˮxX��f;�	�? �/У��t�:C���`bڗxP��Vh�ʡ���v��8�ϱ<�Y��$��=�$���u�٠��V�o!"��,�� 0|�����%�>T�BU��Lohܵ\��>���L`6̒�j���d��^N"C�ۆjD��0%��hy$ �\l�d8�!}z��yRw���Y��F��a���p:!ϋ%\�l��+	.u�e:7�ˉei����O�݄�[6o\)�MXia|l?kd`�����>������� ����Ԝ�,� ����UǜP"?(�r�6`��1�ʻ�z8�j%Ha��f�}Ȗ[�5xj�B8?r�A�Yj_'A^f��ɭ��RQU+(��B��.�W�,KRʶ
��j�t�+�b�}L^�t�
}�3�8����
V:{�5��5 3����6�P��V�A�u�B"�Р����h"���~p7�l-���si��G�H���g���;�m�l��_�>�'W���n3��/������Ls�
T#RPni����z~��,�L�J��Sh��c4���-���d���Yv:s�i�U�g�=Z���>LX� ��
�/5q��']��/I���ք9�� 54�Y>}���鸓52J�}�H�R����.���xR�Gݼ�Po�53��⑟����}k�0�s<۝4���/��L��L��b#T�W���n�)����B�n��x:���*8��j��^3Q6y��XI	�Z*���z紎�z����\y6}"齑���(�(�HKl+h�y�3Yy�V�o�A4�����Gk7��!�Xp�R�v��Wo�^bv��P^�h���̝!��MA�w������^%�O߹ɡ�������Ok>�~l�ŭ�ǌ\>���7�ZP#(Px3�P�����,,�!0��F5�kX2>.� 1.��ؤ��{&��1W���o.��e���c��S7	b�r�`�@T[�x����ݞ��q0���jOmm���6���hXH������D����R2����_�A_&a���vDI�Yid�+di�_6��q�Q;]�04o�p|�v@K�O�=�]Z���eh�x��_s�q�& �#C/�Æ��%��of�ZV�����c�������*OVF����r�_�i�ہ����7}�����%���B���N��� ���������\8�P����%
n�#`�1�� Z�g��0	�_8h����_$i��Mm���7�ZĚ����v��a��R��`ү׎�������*���!s�a*�Ev��b@=e*�ޛ��^��jư��%����71pi�x5�(ܢ0=���/��t�H��^�]P]rdAH2�@����E��W�8F���j��G[b;�`���5[�DXB@���qw�.
*�Sy4Y���ýfqo�n��a��J�x����˭�_Xl�w\�;t'W�٪����>#7��n$ lpq�W�h�3q�)0i���έp�5p6�A2$�f�J~��)��N,�?�ľg��9:H��iBV�ª��P�J�����ql`�O i�G�$��>��m�zD��G�HYV�ދx�]�%XZ� �EU�(�K�[F~�CǘDb��~�����a�z_xrB��ʊ2���2�2_�!���ܑߗ��b��xWF��Ys&3�V�����`!�
��Q�ຑ刞l����}) {�Dv�������%jf��X��k�б�4ნD���A�>w����c<�%���>d����)d���-qP �}��	�L�,�R�H�����2�k�TC7�e^�-�(����;V�O_p�^���8�0}��$�a]���԰��2O,�Z��\���?���&�@�c�o9�Y���Ha�G��h�4���EH�󑒛�-'�Wgb,U*�5� � ��i�S�E ��Mj|6�?+���E�"�'W)'S�����6�.)Ӌ���(��Rǜ놠��+=�׺�t�~q�����Q$������eW;�E/|qK/j���țv�s^ͯxd ߤ�պiT8B�
^F�4����i��M�<�	���&���j��I�Yu���5���n�})h����9(�O�0�1�X��E������ؕ�"�#a��[�SxD-k+,��,�O�����¶oF�ﾁ�x�Y�PVfFy.
���V�lq.lP/B�{Qg�X-�Ҽ�����۔�W����7IMj����޹[���́2�[�P���.�4���8$g���b�'���	�����ڃ���E�_g��_�}4�п�ee%�q��6Ѧ�^6�'%pB<�jr��nj4�|���ĳ��M�S�rv�ffdL���G�#%�WD�"y/�]� _�[_=s�C�4i�	M+��}K����Og�/��1R���&��o�A�xR�s��e��{Q��M�~cէ�e*G�d5���������u�`syJ��{`�Z����%��$K�����j�@�WwswD�P�٢#���]t�y���޵}@�����,4�6\~f��RњT8CٜF�:ED��L�F�3�uEڥ��B��If\a9TuPU�l�9��]��?!/E�0�^<Fi���)F$�=��y�58ZYO��Z �i����V���\v�ypd�#���.�2�Q
���Q�7���G����|����_��}6���J�<�^b��#�����ë����G�N��Ѕ�P���/L�f�	fn�&��,r��b-�Ѝ9�_�>�2`�����LNM��2� ��вM��[�ج���Mp#9�m��ej��{q�?#YZϒT�յ�^�fq.�]gxbKgZ,��{B[��cf$2C��i����e'���0�s��O^��x���6(��6?�R]�����>V҂�)�_��2.�cObz\w?i���f!�R| �fk뒎�����-��-�oR�z�"���m��
O�ҳ\��;��`�
C�7X:�1giZ��L�)o^f�z���S?�@\?e8{�������s��^�|���h�b;|S&�t[��p!���=,M6[�
��@�b˴�v�<p�DC���4��z���1"Wq�7"eIYk��:��$8�g�yR�#Tq�G��˰�Nx����R�
��q�*�2cV�j�PE<���V�g� ��D��� ����t5��'4�D�ք?�o�S�)D��:��	����3-Ma=T1w�+�?Cx3T�ݿ^A�	m�C��0��R��.���yk�	���쟢n�a��y�.��Ϣ�)
���v�x�����!��9�09��S#R�A�|��&BS&ѷG�Y�/ش�<Z�Q���o�v���#�<�������z%�[�ΰ�]�_ʶz�ob�-q����!iid�Vؕ�g�(�B�q�̜�!�0��<�^�,hY֤���� �gw{�q:�aI���(?he���z��V�z,A%/����f�'�H@Ƞi�i�x���K��(9TG��*��i��qύ������<-Kf�[�vQ�I�r\�8���A��ŋ���p;��Y�~E��N��e�B� i�C!�g8�\��+��!+}�X����d�)�e_M�E� �PM٬�9�0Ž�n��D�m�8�fa��C�)�c$�f�u'2�O�0��E��0�Ƞњy��Hb��/�(�D�� !��8�HS�qWX���;e��=OG�nn�[CO�Ǝ�J u\_��S+a�AHr���ܟ��tm%�%��ևʿ\i�T�}0���I��I�%����_X����I	�f:�����m�Q'�i���*�υFm�M� �n$~�S��[��g�G�z����F����ϩ��v��l<3��z�m�/׾�|� �M)	�n��vic3w�
�9���:����v4Ƶ����n����K���c
�o�Ƌ�2�Wߗ�XaD5�z��3�O��Lv�l��W~�kȑ�]��q�w�=����7���g/��
������1C��IrA�hw�5G?��`Eɗ��&V��"�?c��71m���{bz��E���H^�r}������(v��geI�O���ޒ���5O�C��J=w���uy�I�JB-2����S���2c���4M���h��H�(�R�W���L�|3���aۤ��ͨY����Y&�΍֡;˯��q��9S�:�d�{�ǈdv쨶�j�{���zt�����'QbaU��G�O�H3�|z��+C�P\��u0=E�������]/d6	P��c�)���IG��k�����Ml���-��LĴ|:V]�U9�*��v�B�4���7�^� Hϸ�ŭ��Z/�o/{�A�1������z��2z�Ʋ�w֔j/�"e��.���N �՜��T�[�B��+��|��A}��ڏ�%��an�af�L]�8j��o:@�'g!(<�'�Dj��H�r睐�rV�䀓���e�+ڥ쩭��fKw4tf(���E���sR�P�8'O�h-p�N��l�z>:���ޙ,-�]�^(l���aZ�nL�P�Ǉ[�ܵ�kmÉ�2��vՂp�
6��k2�%�'Q;
��Nۂ�X$[!L������a�=�-.|�0l��+��<�s9�c�.5���G� hV�8O�����⚖��m�`舳�x�M��"[�{D�)��j ��"e�M�sz�,y��cw��@"��t�T���Mv�/��y��7�Fcln���v�$P�~b��Z�� E�X�������z�A�]�����SQ��K#^K~�Ii�UL����Kh���Mt�(����_����o��9UZ,�������u!�Ȯ���x�)Ǔ�x2�fo�h�Voq1p")�"x�ԝ�UQ���ӛ�r.2�cL!!9uQYY��ɇ��V={�ۉ�����QǱ��]���6\l�WÎ��4��Q�����߲}]���e�ՖU)-Kd��;�h:v��M~Uj��^9lM6���8ݤf���\��(؀Н����C9�$f�rK}��B��9r��u[] ���+�(y��̈́$6�9q�'A�U7c�@h����NX9���h$�^�0Z�j?%�V�����m�>6`�r��L����l_~�-4�Q��b��W#T����4��8���FF<1*F�~#m�lc��0]A���Y5��vCT�r��Y�'���~̧���,��Wn�=Nj�m�[R'�W�A�V����7�A;T���G��b�C ��z�*����Ή�f.�G^x��D�9�l��s ʀ�����cᕡ����	���z���:�]lD�9~=ϒ�w�]�
:��	\������,d� �NSe�V�LSؠ��]Y����[��c������?kS�k�h�*)q�9#��i]���mak"/|-�����]	�P�42��zF&� xX��W�@Ȳ��޻��N�F�[�*�P�SHlRG:�O쎵�=,2��8_���\��Jp�����7�!�ui��e�Q�#�nN�/�+�G!IG���t�=�!���/j��p���f@a�6�L�L(J��!�K�(��Зۛ�Z{���1g&a��{S�����<XT}r_��Q7E�zi�}۟wk��QWmK�L�M�� �<;�/6�,�U	�R&s�)�|N����ï)_��>��k���đ#���7���4�����+��h�
\���>�?���*l�S�TGmn�x�b Cϝƿ`�ielE�o�v�O�V%����0�gҵ�3�e��q�9����[[uL�)�o�V-E����9��&�?MClUt�9<�K���%)�S�dyF����s۲\����ϭ]s�4����Y�����\�w������q\DtS�4.X��{��Z�/Y��Q���D\��s�9���e����	k�X}�l��e$��Y�B�Ҙ��O���[�T#1�DZ��"g�{q���<cQ/$�J�+���,#T2^!��H����Թ(i�`�O�?I�&Id�Q�S��XN~��=�R��p������nl�:�"�%�\�����o�)OD���,��\���B%��T��6}�}FC���3����oE��҃�<)�j�W#tb`���[@���şbF�آ�qTn������ṽ�K�ST��y}/%��CN-3�Ǎ�:E8�2����Jd���o��/��׮��U�+���%E	}�/��%�d����q|��{�34�+�а2Jw��&��!0�O(�}�᳼����7Q]k�d�U�z��i���:s�]�NdϤ�䠆����q���O��D#L%ʞ���'�+C�Azy�oo"lZ�To�1�� �*��n�[c��B�Vf�6�h��@Z��2B\vN�d_Kn���*��lK�\6���b/��}��o/�f� z�p`Dތ�odf���Z���k{[��Ԍmk�����Y���w�xmg
j��-4t���A��ŀm(+�PbڞC��|�!mџ4ï[��~?gQv9�p�^��!Y}��+$�E���r�0"~��'oz*L���IE����kOo�w^��ğ�/K-����DW����b=�CP��"k&x�`ϙ��h�,�t�!%H+��
rL�1�4��
y٩���- *�Q�q�
��b4��)�K��a�� �����0'�u�U:#�Qo0�w闢c'��t��.��:W q���8��1N��Hڔ7J$s�ۢ�T�8ca�+�!��iB䦟�ܙ�x�ww<ӘX�D(�M��A�NA���+f�m����o�g�Y�n�6��.��N�Xӏ6볞��v����Ȭ�a�C�fב8��F(�� H����χJ���ݭ	�LNL_q��]4=�ﶛ�V)钅�(�1�2���-(G���G��O{�!���:Um*e�ֹ�N��9��̹4f�#G�
�X�Pp�����d�-�wb�_c,>D�=4e�<����<O% �֛������t$($��Ӓ���c��*
0��..�����wrXr��X��n
y�8T�LW\�[P�D����=��W��]r3$$��,�������?޾?V}L�������.�'0?Mf��ո���2�������TxN�殴 ���d��j���S�p�
��[/�5��VIy��4��� �L��#=�uw�s�O)�פ�O��NW��`KK�t�H�d��	IubλoO��PO$rЂ�M��;ʅ �����p���̽�q�t^p���h5XYtZ�0͠���2@m �D��f���7�����!���\W�u__���f��{�	�z�ظ^��\]�յ���`Ǩ�#_��6翂H�q9+$�ηn����>Q`�r��*N�ʔ�-��c}|n}��C��h�z��2Ț6Nׂd �� 4���y9:XU7�����>��Q`mX��;t-+�z@�~��G�+t��l�Ig(��em��X�zc�s}�h]��2w�D��n�Ijv���\V&�0���X�{@�G��N]1�3A�b�����8�=Z�m�z��M���� �b[��v�q{����K^��.
�C���S��}O�xz�m*pA@y}  ��2�̌$ �cB�n�㐠�u�ƈ�1�~ToJK��S;�Bk��*�����7� �����r��� �o��&zKz�	�Z�������m�u��ȱߗ*�b���]t`����ϳ���o+qϤ������7ު)P� �3��J/�0fu�Z��|��=�
>]��):�Gԃ��A�,�YQ���>�m�M#p� ��d���Jd���yK_9;��Գ���G�4��6��́�aH��v4���^�Pۼ)�BY�*�:ܿ���v�G�;���RLW�ڬ�b-���!e��L+�s�˿�\�+6�oFɳ�~�Q�'8}5mB*��"��F��s�[(P��j���F�o���)�>y��9`#{lVMp�j�a�G���� ��a��P��¯��Hsi ��Z����G!FP;�>��p��g
�s�a�x[��dM����
J�j����>S˶ ��y����e�HS�y�f�}��	�^S�Y�#NF{^�S�33���a�";�V�m²JH']��ԆI$�Bm�R 5*<<��qtΖ������41"�6���>]��+�3:�����"�����ְk���./p��ħ���u�_���W�9+��ρ�?�K�|c��+���	J�#Z7�5u��BwV{:"
�3���&n�i���"��C����X%��ƪ�8����}ة��q|��@�W�D���j|�%lSZM/�0]F��X��N�b(�|l�r����G��V1�����~yN�s���n�i�O�e�x������eߍf&RO��*���a?��2$��^���h�?ҥ{Z�KUJ?��I��l�y�q�E1e����׾޺��]��5tM۩��L��uI�!��ä�7�:RZf�nGX4�+A؃t�B�eR����UT���|V0_��c��M���a��o(�S%&��_F\%�Ze
_�2n��n�D�+Y�~��Y��� �H����1j,��U}���f�eQ	�sZ��0C"o3+K �c��L} 2���ܕ�o���L������'y�E�ujR��+^c�j�|k�{�����^��]˷� ���!���p�J�#5�Ot5��������,�jX9F>���?�5����3�c'���Gy�#TT�����F��p��F
O�x�|Z*8c�鵤�Zx���}�@kYp��XOhv�ʬ���T<�"��ڷ%�f�5?a����e�y՝E�� �_!锝ȥ���c�.Xa;$�8�ϸ�A���.�X�E�(K 2�c{n���{̏y�͢�=շL��da|-��?[q�Z��k)�v>:3T:R�7.�B�8|l�M=l���F���#╴P�?
���&�|�eFU����5AYl�g-P��i#/D�=�D;��2��?��#��y]G���Bd$�T>U&��EL������:u��4%�����&*\��kW!J`�o˫�v�g������� Q�����oy|Q��)Ƴ��Ӊ��[��:e���&��G�����]y��������K�%���^��LWy�P-P˜�R"�{�6��4��-p������=2$�/��f�#���9:1y���#�#C!�5�tF!�dJ"��+]CS��Տ:0���B+�r����,��F�<�~|=s����,OqȂ1�hD��E��b�l6O�wl�5s����f��6OŠT�S�u/���o���u<5r	�]�d�&`_8��b 1��g*d<�.����b�Õ���pj� ű"�d�זO�Ll����_c�I��'�@�4#�qxH*��;E|YV;�Z�+t��Z6\��j2Z;J�|��-�O�W4����W�>t��s~O%�Oٺ��N���υ��	���$s�����U�e�qٵOpK9��~:��Z��W����6n�����o���;ci-G�p�������e竰�eu���1��*�6P%�ʵ ���ėE�}�?4�����ᯚ{7Y,ce�+�`���#���7��Rsi`�nR�5g���S(��}a�����`1k�k�T�1��j�e\��A�;��mկq�&�k�
�*�9�)Y�6�����DnI�VV�
}+t�����ř��<�p�m]��ޅ���D�����-š d1��Z�=eRI�ی�@aH��X�
��Jo��~wK�P���oٕi�;��X��*qr���B ^��S)%�VO���P������8�6e��h�{��������~�B�
�� ���U ����àۺLk:��WȀ4�������##���}���wWu�ʱ��{��uĴq�ܼB�/�0�̧ ���]�V�f�'� ���(wO\j%v��|ͳ�U����H�\�7J1v� {���6>@�!X������O!���d��G�C\����I>N�:X��N�Cx���
�#"GW
���{!5��l�EW�?}ׯ�`�@�yl�0�~��|�#f�1d��3������$c -NQ����z/����"[��@����ܛ��a-Q,�_�}�U-d�UhXX�=v�� ȕ|g�i�p���n�{Z�چ7����������Փ٦���G�#��S� ��b�F��ȵ�G��0�{-�7�_'�-Ȫ0J�v�\�{�z�͹�J�����e�d��;��:ܸ0��W��g�1�LI��X��{[V�oߔkϵ���J��y�O�V�� xգgH�R �_w�8�z�)����V�v��s*��Z#����Gê� ��ڸ&���+A,	/�8����K�-�@MR�� t�C�5���bh�*e4�rz-`���XŢ�W�G�z�0E��;_dj�]Y#�ʪF(��iC���O��i ����~2]�!�%�Y�,8�G���
\2�*���M4yC �O�U��TP*x}�a�	�#��;L�}��V$����R3��	�+�o��:T�|�̸��"r#�a}�(P��x �V�g����S/aƠ�P�0��^�J){�;���Ͷ�!0�k����<e�8P��C2�F��[|�b|��+G�6ʉ!J{���\��}~� ����b���8��JӞ����q��t���f\U���Zc�18��j*�r�k�|����՟%\HL :nLЊ��t@~p�4f�~��V'�I��<ı���!a^�{^�'Q��@P�;n��� ��O������*1�rh��t�ң@p���A�XB���K��$��~x}�Nئ�sV7Tw0�d��3�6,���Gl{n��Z��P�fY�[��n����ãL�_��՗k�pe� ��+��`� �8�,VIď�CO�,R�.E�Ӟ4��F�A�(F���[�ڊ^+I%$>_$�����1ٸ�w�9� �M�S��������6-� �aC������$n(����L��Œ��p�i]N�����5-HО@�����|+eZ��v�ے���T�j��Ǖ���9Cn�0~z�FAHv	ej, ��w�+!̕{��`h��^���1b�Tr��������f��oA�z��K~����+ǀ-v��
���8?vV��u�̔P\پ@��ƍ^f!���ĩ9:*�����lf�ԧed>#��^-M��I�)j��t���$���A3�������,�@��e�K�9�K�8�_ �ܷգ�r���Ȅp��=Ԫ7p\-���qk�F5P�2Ɨ#z�-�qp4�x��@�4tW�/wc)���ͼ�W�u��.�Z�$z�a�e�/��Z �I�B�<�Bٛ����^@��t��9k��ְs"Q<����w���]�>��a��/L7D>�A*u�{D�x��W��|01~"��_�S噠Ǌ�&��UB��;H�QF��
^"���	<��ՏP��=��<��Z!
@�͈����
h��H�� ?�쩾�-,M�����sn�@ّF�%�������/������	R�d���ڊ��֒�z@j�D���Z2C�.���(=�ޔ/x?Bu@��.lˁAf������1��1LWZ���=���^���^��F�4{�ܥE��W�C� ӱr�W-E�O@!:l>�A�bD��n^�
�.��Z�Q�ϲ�`Gp���AM��ʞCEH�`������M��r��}#R}�E�2fP���(<�jLҺi��GCN��6$���_*�M�G#�*��	���_�b�),�2T/4�n\�����4[��l��TJ�**4C9�t�O:�8����x�z^jO R+��� �nJp����iN�+G��O�iP�e���0�-�+��O����G$���r��l�P���1a�p�}�
@l��P��ܸ ���m�Tr��M��)Kkw�Ow�l�UvJ\���k�J��Nf!QkS{梿��їӃ���f>¨-���a��@���>)�z��L��b�/-��>/��R�J<��LW�B  )�X�L��C ����������g�    YZ