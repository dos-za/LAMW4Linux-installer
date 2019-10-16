#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1510164188"
MD5="edd06c17194cf815ed2ae7f07d538751"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="18964"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 525 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 104 KB
	echo Compression: gzip
	echo Date of packaging: Wed Oct 16 20:18:31 -03 2019
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=104
	echo OLDSKIP=526
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
	offset=`head -n 525 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 525 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 525 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 104 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 104; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (104 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
� G��]�<�r�8�y��Mi�v�)Z�%���g[v4�-�$���T�Ɍ)RËl'����}���y���؞�$x��N�SSӪTL��������7�m����=�[}��-�Ϫ;{{՗/^�m�|�]�~�����=�~���.!�ݶ������U���R�ۯ��cֿZ���}����������V�믾����ֿ
�vS��b���}������64mm�{�Œ���b��6���LC7(S`7�"�x��9E6t�fݚ�XBݭb��	\���Ȥ���#g:��X�DD�}@�+;��b�Z��V�j/��?A	�F�9��M��ft����O�1���[��_`�>8B�� �q�����l�1-l���dBm�vI\'�M�zd츤�=��$�׻G��wUR��1�߄��+ԧ#_':���?12�����-�Љ��!E0��?��k�sf K�O��>-�<z�9���D
łaz�`s��7G�O4�4��Z���U,�tH_����6)
ϕ�a`���XQ�`�@�f,���'��0�|�V���C֬e��93m�TZ�%��Q1N5�Ne����s�m`�5���gށ�ys�2v)���H�*�;�"�����\jQ@<�l�	`����z�uM���,s�TI;:9��� ���UF�Ie��j�{������F��l�����V�Z*1���W���ZS�]:%��jsL���hw?�@�,dub�y���(�6)1v �!�3�b�2a�.���#��H�����L�2c����3t͉����(�à� D�%����o�gN���a�#��] ĝ�M4c5c��!�MTo�䳍�jy4&G����xBWbn�Iv%LgoP\o�vn���5R{z���؀]�h�r��BjDQ�a.Ŝ����+��Z��8�G����al5uZ ��7�,�]B�9S�h�݋�7$R�}l:7I$ŋʶ:�D`�,\�S��W����y�_o��_���RF���j�_��n�5�"z�:��0=υ��0�.������rz|��t���T&���EL��}�C��}��{$x08D0�];D�!]�(9�X���3��
m.�t�I�����@3�~q3�	s*�������;E)��u{B�#%��(_-�)i�ba�߀k�-%�nt���u�9�\���i�_�A[�;������h)�݋��C���^�� ��e��G�˓��BB��t'ͷ5\��B�MW�	Eq(J"�4�L�^��{���%�-tY:C��r�ϱ�D/$�Gs&(��8���x@�"��-F+�~���B�_�uQ�$�.�pO�!�Ee������\&ZG�s�"�d��Y�9�d��'
I�H��@��?2����s�|WYgd�.Ս5��%+�jG0:?�:�����>cu3�W��`/46'���EQ~$�ŲX>i�O'm����q��<�S\��Q���;t<���-��8T��hBe�ʟ2��n�����h|	=L�KcI ��J��Ļ�b�G��:��6���j�mлZ�O�B���@x�ʬ��ã�p)BJ>���o��?K�ު�}��=�Tj���Zpy�owg'��ۯn������M1����T���?���ӧ<����k��ԛ9�g-�b{!`J����VKL�z��o���C����Ι�!d暶?&��W�_{��Y���P������'Ӹ���P�����q��3ԝ��5e{^N���ά`x�+{����S���jn�S5���*<�
+�1xԝ���H\8���ҾC���`���50�rKD���#-��S2��,h����p�P��qr(#C �A@r�L��k�C!��D�J`q������V̩���&�G4���q��nmG���'Ǎ"l�"����/����Ux���>�'21�^T���>���v�?@��l�F�Y��?�4��{�ѦXÅPcH�M���9�@�p��c��|`-P�����K�9�5^̓	b�^(l�'ArQ�9WZ`���J��&��xt��ڸ���W	Īy�����)k�	��4���w��0J�D�1�o�65�d�$��}������63('QD�,א�$F1�AUs�������Ff�A�e��a�:8���òl�oG�El�П���X�r��N�uP�2�0�����gp�kt�F��f������z��-p/�m�1k��ʧ��q��km u�6h/,�_��������݋��[�C�!���UU���=���;i����&ja���Y�$	�8�ZY~S��?���I45k2i�8�VG*5ROĘ^�h��A�Pf�raS�=m�!� Y8;:����:��@�.l�G(�uZy�R��:� ��w(��d��v V�^���C�U��̝�@)�M�7��!��0�U�A���Mݺe!nn�ٱ�c[�$�����!�Rj?�y�*��Ѝ
O_��R���*y�3�B֐,r1�$&*�\�[[��A�H�n~{�t�^�Ŵ��M<�[���N\��UȊB�%�8hs��57)��w/z�^����`�đ�5 K�,���3C�ZIS̵tkR3�S�-���$��+��a]\��������&�*I+�z�4�=�y���ù�|�]L�c�i��E^s��ݺ&hX˙0�H�pm��cۖ3i�B����aM�<:x�A�8�*
��6�.�.(�<1�[��� :��+UP
��=vP(\���}�V0Q=�u��WTP��v�M�S?j�p"���S'Kϸ�=����z0�W�)x�M�M���:�xk�T����Xza�cT�|g ���ۭ^�)b���҉���*�4������\OK#+�"� ��E����kK�H�+��QE�|P��?[����o��:��n$q�m;�9�W=p޷��_���ȋO[^� 
`���KȈJt��M��E�<>�ƇW�&�1��ǃW�b���d>�}z�����/�NB+���?irc6��y���'��)���8,��{Π,>��.��ID�g3��	:^�M)��9ѥ�g�Ry,M<P��F_S�/����=T3�hD���3ݺ�j3��$�^��DkޯP��n|g�6�vw̋I�����|���SZ�J��Ը������T�s���*߿�lc�ko���QE^�Ƣy8�]��g��*	��4�<���7p\�PT����SwjںU� >��~Fk�xY�\��&�e��TP˙a��!�v����3��i����EjN�dr͏s
f��Y���4��3X-6,���ڝ���ٛ��� ,�zN��h~�icD�+�����"��[�a��d��1(tj��|�o�=(ë��a��)t�R*^�dr�&����:3���o�7���2��;��h������=w��R�Z� ���[�煪���Ѫ��vϵ��oj�C�E��c�g��A��8�K���q�k�|���H^;���V@7�n�Δ�X1ee� w8#S�g.�07�Z��Ć6,/R7��5����Te/�$0��3��P} �R ���xԭ\�S��z$[,N\!G��*wS�Q�F��Y��c���5PDMA�֏P�a�`<fLX���~�i��y����9�%��H���9s��.�@\.R����x>�S`6ȱ�AҊ֔ՖVɘ�얆�����s٣�Kv8������9��*	�bd�r�����^m3N��0�jX�����?7�>5���-��G�$KQ�;?�+[�[f� ��Ok�O��X����R��R�x��kv>4�������0�?
�I���?h��p�̡��&11Fz����n��ߓ�-R"-���A�7r\��$������	����Ls `Bps(���cS�Ȯ%�)YqNƣplyM��%���v��Z��}�H n�8��a�}:�C!0�+�\��@�z�s��0&�	R���[��6R��hϱ>��fazI/�#S�_��q-����(����W���O 6�zkn���o�_`Y���7��e.Wq=��^�=�/�1 ��
.�����v؂e ��Qc9&�V��'ͦ������߃t��㤍�GG3¦J&4�p��r&#�ݐr�PMY�P[N0J�E���arU~��ICkXX��$!�J�/�Ы&JiɎ��䔻���E�Ę1Q�d���$mƯ&���Bdq̭X�� �G`2FA���1��Ч����h��`������j�Cj��V�axt��	�([Gd�Zy��M���|�-��j��9	x,������ǵ.�3D���)�@Ht��0�cp���7����������+�=D5�FY��X0��n�#(�I!��Ҩ��0�G;gHdrk����j�qUV�^ÌA����^6��p/w0�P�A��_����CPU'�3��?f�T���W��"%�8����^�����"�� ����A��ŀ�P�q��f(��2�J}YӼi�j`�ՒUV�&���(��I�l���\W,D��Ю�a�W�5c#��%$�e�?³�H�=�i3`�y�o*ɶ�L���e�f<�ڝJ��]-#2+oBA��wf,�%{r�s�ku{ɱ_�7O@ybǙƩm
oɶr��1K)�ΐ��� =_�%�Ne�R��Z�/�9��B����eh��[�������j���HV�
ݪ�d� 2��c�ҕF�=d}ƒ�'�7aެ�[�^�5���D���h��1��
ˑ��ː<����t��aU-#��ǎ�5�8n��n�t�$p��%���d�鞒��5�d{�V���N֚}Y��W�3��:�;H���)�,T�Ks�0e�@	bd�pI���˝b�}"�bg)�룐�żK��i��Vi%,�����y
ޓ���<�p�ڵofSWL$��W��L.	�ė�� MR|�XB����d 27!�$T?\&#�/:Jq:ϡ���&GHǂ��E%�L��%�P�l�� �����e����s�S��T'�t�>�$��$�"��!ٻ�%H�T.��B
 �}�gZ����"�"�5J����B�h"�(OB����k]$�.b�B�F_�ŐiM�Y�<$B���K&���=y�<k^r��F�}j}s P9?_05�ڞD��Kq"��,�������.���W̙`��p`e��8�"����(oa1�Xtoa'��̗�����A�Q�{GYQ:�H��[hr� L�ݧ`G�m��U{��W��'�{�W�M��-��1rh1��JH���ImY;Ē[?�Ϝ�lG(�+�h�Aʚ����ߥV���J�@��٤����秽Ő�b�:�S�խq;.u�|�U�<{��$W���S9�Mm��o�2P���,�+����O����O�h��K��mz���}��F���|�{|9��������w��+|�o�}�|��{��Ke2]4ec�m������Vܾ+~���E��J���J��6�p�`,��j٤sǳz��zPLܹ���׸|����9W/�����/^2و�U�'\_������^p���r�r9�;�k�H�y�胻��H9|������`���?em�C"���|jsl
|~�g�>�9!��������P�����9��=5ɂ�(�M�C��⋵��a��3���h���6���-%��Þ���ζ�O�R2�O|q��3����f��4[���Y��<��Z��
s�m0O��Ͱ�C�����x�R��l��~�I8y�����]���Pޭw�����n�ˠ�Q rC��=��6�Ϸ6R�
5��������6�c������ �HE ��X���̘� 2�#za�!5���P���9��:yu~�ԥ��{. HK�>	�e��kuuuUu]���3T �+Ԥ��^#S��7_/���� =�+w�G��[kO�g�OU5���~��4��Wy���kTT`�O�` �����D��]U�+E��� ��_O����%�E�Z��.n��adO9��O_j�	a���|��ƪd�ɣ��e��wyE$h�H����ƍ��R�Ǘ&��w��Tnyn��� p��l��G/����Œ��{�Yg|D��(NM�/�$~��=����J��m�v�I���nO)hͯP��Mɋ@������2��>k�<k�i������o~�b�-�W��Y�At�1��!��E�#���Z�^Z��d8�JmE9P���=�#�8���S��U���emv%+l�ImV��~��VV�S��f7`Y^��g��^Z�$�%mW�6�(9hi��AA�X�> �D�K�N�p%A������[��'8N28a쾫���8�Ej�L?�f���d r�],�I��-�)� Pz��'v�-jv��揂��~;�	I������*�G.�V���Q8������K��������0�����`�o�oN���4��Z�e��{�,���f��oc��dc������#�2�� y���w@Af�Ȼ�iz�>��$���N��(�f���{�A� 	������1�φ�r�:��f��Y�o����J�,öK7L��Yc@Ϝ4a ��@['��~lxb�q�7��9�C���&��$u�U���X{�|r_��#qO �& Qj-\8ҽ��<X���iJ�Cm���]2��pI��p:�0-��觓�zKom�}}�s� f6���z���xI�IT�:eڐ��ҚP��v�F����e�P 1}�T�\I�(�j�xZ!��^t%�U�&H����O(��{�����Q�K��=A�^�ᙇ\_�F��/_]ub��u�����Q�O���ZY-B�o�� Ѱ�����h�j���S����6к��'��l�4���j���K�(J��E�pB�J��y��3�<�[��K������O^���	2}²��G�'��#?
8IGnT�����Ga&�8)���r|9-���D���Oz�{�GG����ퟰU�2T�*]�,q`�I�]@ˬ�p:S'�����<�T:v�dE��b��_���"�
�Ta"�qa��,tI���I����yiK����S�{5��h��,H�0x�7����T�(}#`iĩ�����=�B't?³Z�M)0s��~Ji8��t����Uk=տ���>����VmC?�3��m@�r�RE��_�H�bm����S�dȔ��BV�2�(Z��A#�?L���ed�yt�
���Y�'���s.�:w�_����}��oZ�À�8�HrQ�Tma(�qm���O�E�$��&u�ڐߤJC���~`�Ɇ
P�SW�l����Qo&G`��U)W��������L�d|��U��*��!Z�����JQ+�����>^	�3R�LF	��^-���߶2�^YhXX���r���)R�eEU�"�Ժ5�O��1��ķ����גL6-�JK�W��4��y����X�0L�p�]�z�`��%�bue8JQ�da��*)������i�Ar W�8t�(��)W} ����a*����|u�T�`#���i�'�[���"��o�X�/ILD�R|)�
��q;���ڭ���������}�T�_E�7#�3|����ZK��2��u�����t�^+!/�{�K��ESR�5�j�?��w}��q\z!��@��iԄ#�k�P�W����4	U����Zk�E������xVV^c���4�3���8�����a�s��)^�%�2��!F��齥����X��D�Ee��-WF��z<x����1�����uϛ����F�p��}� �)�FfA;ua��'�g��%�����aL�j �8l�o�_�T����+-*1\�����Vp��kԯU�Ѽ~/\G�3/����y�������Z��o,�?-��<�?#ԃ�	�RT_0�S�4a���*�ȡ�0m�#�%z_��	�I�!
0r�p����';��_�_u������NOZ��z�����t�PPR�sTc�����bw�
�����Q�Ѣ�lB "r�b���j�\1q�K5���E�d��(r�+8(�h��	&i��:5�Ȼΰ�.'���:�(<�u;�P�ãv���h �	����I�#W9�e�P]7�s��7�5^(�)[Mï2�q��2�CE�ǧuӫ�������L�2&��r3:���ǃr��J
��ve�1I�fE뮍AOoXzvY,Ñ.�7�����?{矽B���f� �~#cV'���f��BU��}�s��~��*�a&k�^t��{�O�nz�ߓb�����|{�Ҵ�l���o�7e� �tTW�: e��YH3|N3,�ww:4A΀�'FqE�`,n+��R���6�.�Z�inI#l��-�'M�{x�UjG��=��I �EI���M_��~p���ќ��%�KFT���;d6J^�Fu��4x�Z�°�Uj���bR�u��~
Ӓ�Mͪ���d�X�X\F��)8�5��p�lX`sgA�U ۋ�ݽ�Q���9��@k�!k�7�'b��󩻭;[���^r��0Yy�x�_8�r�c
�M6+@b��P�u>O���u�/�#䉂1=�\�Bf���tO'��<"���d�%^25�@�{�+J�wr*��Q�(���S-��8&^��*yG�'�H|����^��*jRé�!y����r-K����CgYރ_�[��+R:m�]y����#7��V2��c�ñ�����OX�o���.Zk�b�w_p�}�h=FgY+�L��A���l����&﹓�0#�W�W�ݣ��o�h���a �VQ��W��fe�c�QBVa��
��2����>��L�|G�h��� #�m(A�`4�'��K�8}3�u����CK��S�@���s���f{��_}x��^� OΣ�2#n�}[�oS�Z-{�U2�
 i^�l�R����d��"�k��@�մ�)js&}�"�Ϯ�G�'g��S5�FS8���tH��t��G���@)�a.ZiGZ��jȩ�*_l�tKI�W�)�3*9h�MLUP$�>�c�=���ټz���E��~�4�I'�P+k��=:�ɝ���<:�kc��O@o��i�SL� 	�oj���*4Q���
$(�T�E3͚���,�qI*9�.�-\�>Ӟ���1�Ti�]z��/�A���nX�-�X i�
q�@c��d`��Z���Wǻ},��؀��k����ԙu�
��R_��(���1�y�n�o2���Q<��U'���
曃���gh�# 4������s���#'h����a��Ӹfl,	e]�J�vGx�Iڧ9��ý��ݣ~{�h�6:٭�xo��LYIYup��T�<><���b���A�ף��N�M{�H��Y8�B��m˭)*��R�T����V-�K�]�
<͙Jdp~�Dibz�k�7{��D��|��kQ��P.:�Sʮy��%>�G����i�ÛHwU8&�H�5+B~�V�B���_��8���wlȵ���u�X�%C�ߙ�����}����|�p�A��o��������������Ut��ZW@���mZ�Ȇ��H��m��MP�������ty'Sɉ\;�`FQ�>����S���Z�9�Fge���uKM���v'�F�`���G����-
�+#ۗ(JAN|>)�LŹIv�%��
�ٺ��L۱u#���"<v�^����;j4�"î��(��Ֆ�X�U6z���?W���l:�\#�����y�1���Bn��璊��Rk�(z�X���s�N年���I���i�-Pv9R�]$ݥ{��@0#�ز+	���xOqS�Y�T=U��9RJţ��:��r�<�������?��̉�����H���r���0�S9����/�FO�P�)�`��Bԇ��b�����Hw/�0
S��n{�0$uX��C;֯�?.�ES �KPp2A�o��
p��^�њ��.@��;	���i�b]6����=��zŨ�Jm��IJ�qa���p�Ǌ��FC�w���M���h�5��
�$$�B�Ng�|��$/[:���<�s�P���):t�dk��1�$�E�������-�,���e��v��W�-�C�(�Wad��B3�X�d�բ��`��Fb�'$���� ��#��+���;����:��0��ȅa�	�p=y�ټ�8�V��q��`�b6]��C�?��]�V���Ou:x�b*I���7_�z��&�����<QTF�+���X��5�&�J�^�L�_�|������l��E�������y,���ܛ�P{�?�������COH&A{�����F�*�Lǃ4�*�EizS�H�J��r�>D�>DFT�3;��C��$��=�s���>�?$t�
XǢ6_��=�I��Oƽ$�L�f�=�S%CŜ
��.�L9���s����ZZL�.��ސ�=�msL��	#IM�b8�?5NiÿZZ�Tձ0�'�#���G�2߆{O?]�nt�{?F��Z�g�J̪dh�������l���LM)~3�b`=?ԧc4���*�H5aҿ������@�G���m��J�|2г��a:�#�M�����fCK��1��f�_�����upeb}����A(/��0v��݌���Th#���D��A����3�V�˦~���D7�l���ޖ�	����a�J�fO�vkL�t��B+l��P6��������:V�S+�`����U��VYJ�@I�%�$~�T�d�$�ó[����L{A��I��q<���hH{%KX�I�����f4�z}����ªn�/���A?�x�z�K+*dl�r��K���"p�χ#��~�C_��C�W}���|�(S� �of�k/z�'�!�>�^^ě��Sl!2z�Ϯ|���Wn���S^вu��^���u����v�m �t�#�$+G0�ar��摵_������"p@� 3ƀ˽����Mc�U%\��S���*���b`��ʑ�]�Q�;.i�� ���F���v�	��LLUg��v�:�^�٠D��'xn�FK��ʙؒv��dA;���B�0�j@K���M!+��Vtf㻺Y��v��,8�l�K@3���3��!3
�;_�X.�o�uۯ����E#4@���\?
�qx(�Րhs�mz~��!a�R[�.N�m*�ݪ�>����A�������'������@�zq�,��}�@7)'̭gw��gF�s�'��d�h0L.�@N֐���?�Q��E��I�Zqφ�2�єuWS}���#�<ӡ�!�UP�tK����UU܆a�g�h2e#D���nj��{v�(\��q�����L�V� �ѣG�޽,��y�42��5���B�qo6��Jj��	ͧ�&U�8!��'s��О~^y(�Q�m�zKT1�Zm���< &ň��D���_����^��|@JM��'����㮟	�9ɜ{���(�:<��O���F�uU�M j#�(��&�1����ƃ:�j$^�����d$__��t�X�t����KJsc��f�P[o3I:�W&g��2�S�C��yD�+�%Be42�g�1�|�wg�ԬF���̬��{ūp�	F�'��1�\Y�M- r�,SF�ye1�����d��y�I�,ʻ7�;��9��T@�ZhRҭ����G~/&+�{�u�_�1 p4�$��5\��XcϖW)���R���	&"�;�5�g
dv@a�*1�{;��+E���en�3ת)�Zn��E7_k+�7�Mf@D) Jj
m��I�J&�9%��x�^��5>Ҋ[H��h���K�쵱�G����x��CtH����G�L�Cm�Ҥ�W��n�����x��Δ����>�"j�(����e{<l�/j�m˝Q!]{\s1$�q��G�B�tzZ�L����i�X^��΍S�45Mz�O�"h�Z*����lb�0�Seݬ�\~�����Q��撄��*tu��}����[�fE���..���2׃�&�?w 9v������#?V:��LŜW��Z�\o��\����h4� a�O%
��%���-}ͻ͌�i��:�#��qd��a葛�+�U�\��f��gY��RP��Iq�� ���	b� a� ��ۚs�ߠ�["����f���8W+�o�� �hO�#��䀨�	�ۻ Oq�Kq��
�~o\X4g]��*��S���f�Ռe�C�����E�{f��%΂rW:3�U~��Ix\�m��|�I�m
\�wꟇ�@X�9\�r����
yar�^9�{~%EL�5�"��R�R�����x�%�O�jWF㪘ܗ;����1_a2!���&<t{]�d���lb��f���yyB�$G��!��͈�E6��σ�
�.�[��-}��ݓtT�N�)��6om]G߫s�Me��}sQLD{h\ ���qp����^�N��:�dxC2-�:�OE�RQ3/JfG�s|��4�}�'S�~2v���V�F;H[-�HƑ�T��2�iW�u�ǉ�b|*�'�WQ�Npn����`N��vP���Fg�~mL���`���������lE�%<����e	�tG�[�����ikxRJi5�)T����e��X��:��*z���أ���	�&�E�z�40�GE�ՔHZ������;4\]U3/%\�6eg��P�8��lF�	N�L�E��Qv��0iŲ�"2��H��R�1��4 v���>'��X�+T˚W3!.D��u�U���~��c���.�,C!(D��eh#HǞ��}!�'� a�T��l&8����r����A�����c��Xb����wt���K
�Q_ V� ��ot��xx�*J�QrD�1�qi�ҟƴgBh�}P��I}��7比I�S߄��|!���tY��������0|�%��p��l�[������þ�~�m��7�qc 9�k;��O�w�|������Z�0�ꂵE���yZ���zc�̌嚃�TR��0�fA��[ft;�ZƚE�3��N2v����5��^�	�T�Φ��O��&j�AH�G��2���@�ΪT��3��;��
��WX^o0�⮰�i'��rfҠ$v�
��3�G%e�9۽J�ɞ��4��[�~~�V�me�|�N�e�x� r�Gײ�f��i�8P������w^$�����`:AB1"��q�*dj2����������0wV�V-	8-�0պE�$�S���t.�p�R�^<��o��!�`qr7W+�N.�R�8�Q�׾F0�*��}P�������@���"�<^�gVr����u(v�!�%Hp�1;�*W�e�(���Tԙ��F�Xc��S�8�BiuG�=lz�Xp�(�|�s�k�	ց�X!�nb�\�g������4͹��ϥF��&K=�|��G�� ���� �-�\+Qm�$<AY<�5SY=#f+j�7T+�r6��Vq�����PKC� ]��F{�����\���@FB2�%q[���M��f�PT�S(���p�"����p�-��ÒT�Q�l3���Z�)o7#�b�Sx�e��9ٓ/w��!�NIH���f�qE�=Q��C^x�@q��;��j��/>�
�k�8�*#�s�m{��<�p�Ix(��3N����E��^�,�e��b�a'*Jn�h(:>��f�[���z�Z�����\�\���y����t�����x�V�K$���1c�m���N��a��ȑ��pb���o[O7�GwՋ�~���;�Wk�n#}�;~|���|���������`����[mR�M�`�/�{����9_U�a�c'z��h�\Q��r"�rc�Z_z�5'�$_)��"�	�y�ɝLL_y�'�f�AhGf�l(��}���K��������:1n�(���vۻ;�v/v;��:�p��έ��c�*�_W|%�T��Ϋ�N��������\�f׌�y����R�Q� wi�t�B�֥���2c
ޡ��O���?D��ީu���Iqz	\l�0��Gqz%v�q���HXy�?��G�U�Q@���m��������r/��Q��n¨SRY���!��T�OP�lTQɦj�;?�=��Zs�)���}���I8��8��+Q��w:��W���Q����h�
~⒝��OgS�1=%��(-j�E�h�?v
����=1�-�֡]4d�8P��M��g�趥u�5Z���l;���xN���F��2ߑ�����̦��8����3_��\�0����P)=;SP^ɻ�)�񯣉�W�ψ~�L.6�,\#
�$Ovfی8�e����t��١q�3�t�D�z,�|��ɸ�7�z��m�Ec�; œ��ل�z����37j<��|� 9�j��䖙�~��q���o�/��M#Rl4Ր$�u�0���W�ll"��R��c��i��yHr9]�|�s�D�6P���i�&n����y!�-^��A��>g逕��,�G�S��	IꜶq�}N��bx�������0��|ћ�O�Dc���۴��q��ċ�h&�H�l&�El(e��Ϯ��'\ D���:׮Q<lX�L���zbb5tZ��tn�x�Ղ�h�@��A% ���zq8�h$݃^��������Iɖ���E���><���[h�r�ӿ� �u�s`߿tQ@/�v4�|�B�G���������B�14,_8�����,_�x
2(�뜃�v�O��L�6�^��S��/�4$��������p�"@#/�������(�N�B(q��-� �_j��gZ��h�_s��]�ː���w5��F�{��h@��y��Q����E��s�7ݾu������e*�;��=:����鶁ê}"��<i6��U.�;J�am36$���c�U�����^$�B�_�=N����s��D��{�"l�o?&q��{�{��Ż���	φ��4�H��s�ICUn�#<�{Y��OOU�=��K� Ư���ؑo:��H��1��N͠���B\���ѻW����DS�B&UL#9���O�R���MY>�o8�Np*�Ḏ�wecu4��B�~��g-��/���,��T">���F���ZG�bL��
6�3rt�l|5N��OX�n4M�	�H'I�Y*��(�H�sj�Nz�����$�;H+�М~�DI�i�ߴ���?��h4=��3�2���$?%��㱴�\��X���e��z��������;
�_�q�o���4��
�#@5*zO@9�;�K/�z�L��]�?J�7�0�&��hP��	�z�b�c"F)K�C�w��F���5��.��|�2����`aC�c9h-������x�[�INf�E�6���yW�4��n���wd��$������/:��^���d���̍�B��A0[k�6Z�3�,ɉ�1c����0�>��0�_�)^\i/Do+k���s���Mg��@�%��3�4aG�}lN����������X
�Ѣ�ʬN���ة����W͌�	'�]�SaM�(l�Ӂ�vf����M�|������#�T�G�� t~ۜD>���?Uj��]���̤w|�>�}���}%�l�fSdQŞ�)������-�LJ F����>��F���(�R�ͼ��
�8W3���O#o|����#0�(X�+�l�e8�����.kX�n��J0e�o��W�\c����Do�?ξ��7�Nhن�عw���#,v�.#�>�����i4�Y���}��ǣJ�?蓱�h�<�/�`i�q[��Tc4���_n������Qf���.����޽oƧ�����`��V��@�ў^��c����׺v�ր/���(2�߻�8��	�=�<w��X.�C~l�@�oI�VuMj�<�Nz��{����bH�K���8����s֌<kʟ?�o�g�7�����n\O�5��i�x-%d�e�K�E�1u%-B[q(�槕Y��No��K0�WL~,DYJ�&�����A�:<��H�y�Fh\�����oY�#��ք`�TB��u�m%��RY��P�j�`\�ʁ`���C�@I"��=d�,��U.��ivCLYD�Rڠ�y���2���R�+�J[*�a.󧜖,M�.�d�2JQfjʆ��)�%�ω�^�,x+�����l�gkj��9M�� $�J��u:F�M���P��'�Xjxf�]O}]�nTQ������|�Ǽ��e��2IAcp�� �\��<�v�T��g�t�`Z?�O~��z�2���ԗі,���ڥ�͖`+�H��v��7�Л����@K{��H{�3�"x�C!`�Wz��R��=��1��d�����.t*GTh�'�������'�@�{��Z�����N����X�Ŷ�scm)��������l&0��%�4���%���5�@WH�l��3�{���}/Pps�3�d�`�U��أ9^,#Z���`V���3�������	O�B�e$��e2U�<�J�j]��~�'d�	s���G�܏����h* ;C&r���c�?��o~p��N^B��+i���w2����gE\�B87P�#}u%pu��1�b֒a�2i¨��y�j�fݮ[2�*���W���!)�ǣ�F�5>���|��5=U=NM1�����;�5o9͊� �3��i���:xR��3m����=Z�-�Đ7v��3��L���w��N�^Ѓ~�o���0y��W�%g�����4�ȃ�\\�������__{����o<Z����+"3��������HcQuH/Ryv=GC�8�K�	�����3�91�8�V���@���Y���¡H�&������ʳa�b݄͒���
���*�1/9�g�x��nAL��#Q���VWÏ����dh3jv;�����\�9���r<kz��@#�sLT>�Q�
�gM����(���9M�I>�5d<��tLn~�)v��������1�Q�0<'��O;?<m���@�Yy��QaD�VZF�ZM��|��,4D/�l�uU���S��w��c{.�x�E�|dQ�Nr@���?��3�	
Y��_a<&�D�����X���p)�'X{7�[*�8bĳxK".UoI�p���M�'���7�&����t�S�^�f8�]!���&Z�!bȟ�i�]�Rͤ哟*p�р��H�@јz��T�JZZ�G(�kb��{��*���K[�9�7�s������u�[Gz��@r(���t�d��T�b�ޱ�A��^2�I$�tz!���8��C���Y���}2#p��YI*_w�􌋍ʳ�PQ�]L�4���A�Qo��O�3�ܔ�� WM' eϚ��$u��H<�-�8%��emC�#�	�}HG`�M ��@Ҵ�a���T�'p����l�/w�� �M^��=��fo�lw���b�oo g���4�LP(59)�/lՉ�V ��@I2_'[0��~��`���!By6�(�����M��H�5�e*�+���v�/�:/��S_eIxZ���(���B! &vGq����C� u�4�Yx�W�e���Y�Q����1�:�ny��3�ƪ������壦\��Ճ�
Ꙉ�n�֤�������-�����D�s��#]�8ba��Q�Mp6�h��t����	��_���)5X�}�J��LX�9	�1�ѬA{�˦ R'����ƚ\{� �i=��=MPJ�Ƞ�?�fo ��8kR.��c�v�$L&l��v���f��]�-z���ì���փ%�w+��N��4������K4��K]>Q���;�v���ᦎ_�θ��+tf��Z޹����}w+7ds���A��ޡ�J�*�}a\�n����q�(}���F/ڽ�\�+��J��9�{,3wX��w� Їov���\�h����j�?t-,Q[+{�����N��,02\9�kV傁;1�>���4ȩ��z�Χ�q��8���#4A9N�$ώ��f/+�B�V)�;�/�(x4�}<����$�P��؏v�<�̯�OΚQ8���0TM%��֬p�e�2�x��r�y�x� �&�E���@��r҂��x�U[���ps�j,nMq�GT< �M+}F���	�4����gQ������1!,qt,��@�Խf��%T$?�U0@��O��;F�n.g����Ú�.�]�^R[�E˵"o�W(�NW�^�a�����=���M_����C�����{������t
�_�����^�����"~�{��#x�~7�7^�H[��D$�X`d�)^$���)V$�ߨ�b:&Gi,��?Θf*��bD"J�n���$3X�<m�]-+=����j������>�a�9?�J�%º��w��\���6�]���I�C�����Ia4|�-E�XX�������D�_Q ��Q)��Z���l��/��K��ZG��������~�h	�O��j����cYDj�S1���>M�~DW��)�F��j����7�X���0N����~�!�#R1�Yv�fy��z�k�a0
���P�e���\�I�&GC	���p�ϟu���5��y;B���&S��^M��N3G���Ӱ�ߨR8e�s83)��zC��V�� {oBrV���!���ʷI�U"lR���F�1�
������z��o��õ%�����hК��y�TZd���I�5�S9
���>����,��
28F�V�K/7���,?����,?����,?����,?����,?���������_L� h 