#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2579404097"
MD5="dfa83108bc22d71d6f154e1171f80828"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22668"
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
	echo Date of packaging: Mon Jul 26 23:00:01 -03 2021
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
�7zXZ  �ִF !   �X���XI] �}��1Dd]����P�t�F��F�K0͋{1�+H���&��'�N�[���S���t�G�l����P��$�a ��v�2M>;��Ԥs��̪�RTWJ��@cJ-@���W"@��w����` �!���gWwgK�р���rf��5Պ�X�](����-v\�q�.X��9����]#��&ڈE��H�H�x/@��@gT���o6ڭ>,�T�lFr0���B�"&S�/�cD��:S��5W�ݾv��Ϯ��z���b��ʵ$e�%{�}�({+(��4�i'Y.�x�rץ�Ih1-5�@��%n�ȉL�<H�bG����C�T��,���D��1SFP���Ĉ	,�q��K�JiIu�2���S�� !�����)�-�z[�5_.̩�����3o�ޚ>�!@W/��Z^�G���:F��Q���|l���\�/�u� ��(����b�/�*D�)N��SuZר5�1be<����F��������)s��:��''�l��oI��u/b���H��^�c�����!M��п��#2t`$��i�A��"W��t�L�CFC��a���*��ꀅ�R�n6�v.�QW�i2����k�y1���qn+�I0r��J�S2иt(�+4ñ	�]��#H�����7��inX
�*q8�4��8�a.�������1?�Fl���=�h�\+>��=�~�������t��x\^��c��(��5��'����)�:�X,��\��w��|��3���yZ8F�Z��,wFJ�Zφ���S�T���c�YV�*�J{3��I�U�'/d) l�Z��E���D$$�_�#Ub�(1j��a�������U\x���I�YX��2nv`_)���:L7�u����0	�����Z���.0�5�<����!���!Ϫ 7!�At8�y�u�%��e�h����Q������d�$�Τ{X56�Y�V�g�`A��4u�NF���VMv� l~9Yud9M��02(��z��i �_�{��;��Q���v�hІ��\xd�~Rp{?�M^&�?'XS Z|q�����8�@{y�	�<�Q�*<�MǛ�.6������7`yn�����X~Rm���x_9X'��MC^T%R�[�W�)��W�^j&]�!:x�Qw�XJP����k�4��3-?��Kr��7��J��Q�哒�<	J3Uh�k� ��:�',�Z4�2w���d�f��w�H�\���<��������H�#�ۣ<��\��S�|E(eL�w5@�T�b01��Pb�y�hٗ�z)��Q���F̲���8���G��[�2T�ep̌�.ż��3P����x��W�eN.����(��jZhw'BK��@�]E��`\g	0��,냞��p��X��wt�rG%_Y2��%�ܡ�>za9� ʘ����廴(^d�ի@RK[MVY#<�����jJ�ߗ$�IQ��d�,�ݟ��t;�7t�g(���!nM��I�sz�y��[YU⟴�&$�����8��R-RW�L�HC
W�{���]aZ�=Z��_SF��
���#�Y&���Ied��FXɼ��)gtmL�K�W@c/'%4$5/Npv���b� �~��b.�����[�6X���2TCGrD$@N(���[>�I������i�/>/���a)�aW�h����1�qv�à�䨄����]�[�fV�ƭ�1߻L}�}���/���vJ��� ��u�0i�����f�A%�5��d�
d��	��}�s�>o[sM�Y�7�^H����H���p��y�/2��G)�Fl��n�" Z�E�
��m���E}q�k��V�����m���*c{��s�nc�����!!,�=�+3�7KE�x�{����&&�f������?��Kr'跿8������w�ϕ�lDFs�{���;�����U��f���Œ�3�c�L!�n2��]��<�u����$�W�V+��A�>�렎i���×������\̥������0z���c��"�M�5i�ߨ��Ϲ���P��L�����n=����8�#�f	�8X�^{�>o=pY�Ѿm��~Ї#i�[�w.ڣ�-Z7��Y�{�Z��_*����XY�{>�N���{����@A����Quɨ���x��Q#Ǳ��Z�B��rRb�M�-��{���L�,���I�w� �{?�_*h�����s�b!����>Q���.W�����B�C)rU3���Eּ�9VG]�	W&K}2�*�y����`��x`6Ld*�#}��v�G��2mpw��Wt=��8�c�6`����#A��a�zy?��yN�\�K���p��kp�Mߞ�b���`f!�́*�@'
�^j��X�1r^�c����`�EUk�����r�*8����+yG��`�hߩ<[0���f���b�L!�D�9d�	�W����o��0}J���{o�\ɶ��{t��a{Z��JB=�Fo~a���)Y�V �[��4do6B�σ�SbaO�|`�	>+^}c�[���W"`�f�U�.G1�-�b�H���C����iU�����\�H@�䡬w�!�K��ҹ���ɠ�g%�MAS��$��O�p��F<�"v�}s�M��?,ç��%�͸�r�s��@�y�Us�z�H�@���A����@+Ib��e��0'y	�J��@nv@Q�Ԛn��'�v�*�����B!Mf��Aw�~v�dh ��.{�`���t�����_D�F��Rq��n� �j�+Dv!�U#�1z�&`}�K�^O'G]��r�X0�`��&Fe��C6���z|E�� ��7�$<�L�Ӣ׻Bp���@z���*}u�p�a�X�� o&A�;�F��5u�$�%+�8c��OU���q��N�#� �f��hm��Y
b8MR����QP�N��8�|ˡ2o�j}X��(z����/�B4Ix<�[cP�R���D������Rڍ"5SXi�3(6)b��K�~n<-�e{�i�G��3Y�^w9w��m%hkf�D�©��'�L0�.��wn$ox�(rw ?��i?�+ ]�9���k���V���������{k_㐀$��LGSkT�Կ��.�
�@�����5�,�Ex&`ś;�Ma(5u~�#t��c.d��2t��w�`D��zh!G�w�jDDs��X�c3T)�h����.جbW y��Wδ�c�z.��Z=�"%����D�8Y�S��&� ��m����Ly���dF����vq[��tSr�J�j:�(�����]�\X z��gC�����?E� �bF��xi3[+qp��JR��l�����W�����})  �y�3({������.:����6�����ɱ���x�W��^�T��?1�,�
6^�^��ڡzG?Ot���U7�`�Q���f �+Ӱ�'�Q�B�VE<<�aơ������b���'�$
{�, ���J�?���t(�m��l=�E���e���=~3�D�gz�?��*�Z����!�F@���G/�������6��a���A�]H/�,N�]Dӄ�he���⭉>h��C�j�o?b�&L,��þ�mUF��H�Bf`Y��@���)O5��ƴ���	w�FB�v�e���wi>'l�{�g9�<������JD��k�J�0���/N���%�
m¶g�w`��<C���30������w�(�� C�aˠC���p�@�͉��5�!S��õ+�a�Rt�o�%R���:��6Rx������T�7���:&�ug>��N e��E�泑Lȿ����i�PZ�����kv��cZ�hX��@��Sq��lO0�/�L秞��@���uX�p f۶�-�z���H8z�#W����?x�.����l"q7�|�t�DR��ӕXc��5J��4V��a������o�]���JM}:d���X��|��+���w���H��f�B�觜��9+J�%6����y2�k��ё�t�*r9��06��N��u�p�Y�=�AUxЗ�Uz�0��j;�,�Z�f/}�����I�<�I�л�R{?%�!s=#���lf��
h�$i�ؘL޿h��\n�8�J���Yf���U�H�:n[����P'0�m��-�ĝϓBCU�lH�c�+�`m�����˕�.*E�ӳ�;)��Zӧ�b-�T�д���v�>ˑ~^)@�.��aqA2��lQ73\���t���|�� /6&_��Z%�����%Ek3���˝��|�eU��&7��褕��^�_o�L�D+��6���F Rl�>�̀� o��N�P��M��>e!~����,dn�z��4�Y�7/ZqpMɩ���"w!A6�1�IKr���Vͷ�k{k��뮨g�(U��$�f��I C�YG���[�ODlϞ}J�0+���mK����!��4Jd��7��ˏ�M^�<'�lխ��qE�����H葇Ipv�7B=�������� F�`���\�+�n� ���u�3�p�o�r��Ln?A�2��Zr�$f�-b�G��Y.�C�:��Z�F��K�q6�s�`XW���p0�⏉.�CwC� �Ћ���7~ca�^>]',f�$5����f����	Є)i�7w��n��]�IO&�b�����׮ !�dfp|R��Q���d$t��wY{�s��j�-���@^o��!����߶���\�� U =A�m%X;yku��IH��2G�.Wa��'"���ػ��<{�TQ���r4���.U�ժ�Y�;������C��@|��K�������S(�S�"�$Oī� �{^�l �����n�jˤ���@3&��<�2�3��cظ��7]���| ��H��S�
�[�qH��,���xK->������P�[Oګ��� �n�4`�&h������x��5%t��s���c��9�y�_�8���f���Cf�f��5�A�>�C�Ĵ4�I���<O z�(%l��2c�7�W5��4�$_1�e�a�Ti�����<q��(T�i�f���]��ϵvs�W8�_�*0��r�7#�(	�d�{>�R��B�ǹ"G,P���
�-�}w;�Q(�ր�C���IX�ɮ|tUoF�T����g�m�%4!��Co݃>�:ν	*�,8S��є���c}���Z��i���G6
�E�Xf��� g�Mώ�VU ��S�������p1HBb�~=��sf��l��e������թ������(G8�}ԩ8q�'bW�EN����EF�@�?�ar��)꯰K`,�ڿ�'��}�֋�����['��֥r .�B�C��EM�~���Z��J��G�Wn�+���2���K𱴽_�it� ����C���^Z���W֔P�W��՛.8�eW�x���kL�zR��:i�V�m
���ȟ{h�!��#�h�dʵ�H��1q����Uv�fbl&��b~�f�3����}��^'J�J�mR�Nw@��{$��l٫�-��p:�L�&�'%��z�Qb-��3_�vlܴ���gV��d~W���g��=����Oo�+�%�MB���3�ne,2�:rq+���T�H_� ������=���g���V
l�i���G9�����U�&/z�K&����j�b+�3Q���c-�<8g�������.H  �=��-ԘL�@�Z���N.���ri��y�}��d�7 �=SP�.-!�2�L��5�����s����|Q�C�������P��|"��Q���z4����+��0g>�����77�4��G-��u+��w�i ��_$�x�.��"M�d�-�8'���lwRb� 
���i�^��O��S#Z����:ETͿ���˾��䬲�9R\]i�ͧ5����V1䢵���i����^5�Nn���h�
�P��W�Q0�T�I�<�3���v��8���IGY�L��ð�k�覉�}�����͚�SQ;lz��,�D�[hp*3fR���; "����N�`9;YM S�I��"}#'G����8cqL7��K�@��ٞ��]��<�'8� �Gu٫(��w)����0^��`�tf��z��m����l^��{Ѹ�M�#�dШ�c7E�ݶ#��*����nݻ�W޽f�2��s�(+��1~M>W�v��s�4{���	!�O�aP���
�M9�cF$�Z��oV?}��lg�� m|��:�6�b����"܃�k�1���&0>oE��n��>�m�Kj�.*�3'�}����Y
�{t������^^�E+��h���"b�� �Lיh�����=�SZ�/�A8�7��C��v��g+ץ�1Ř}����m ��X�Gs S<ng|�c���WA��Y�~[X�i�Aƥ�p���EI��B�9t+�F�$�>~�f�m��m>�~�43s�M�a�{*A}��G���K���x�"8
Ji��L��V9]^0ZG9�1��
I����⍈��ˉ��W^���o�ZJܑ��q㉼v���I٠pBR풁�:��yݷ.�jX�6�B�,l��l)B�8f��6����Ge�{�7Qћ>�&�f�*��=�aR�0?;:v�V�x�&��1n||t�t����b���^����,�k��=�A�D�.�Oj��'�A���=�t��F4(�ĕ��Wc�}���~�':��h=2}>���f�0×�D�Ꞙ�Ɠ�P�dE��DE� �%d�.s���M�U3Ǻ>�Z�<���`/[Ї �F��&�,�m1�U��WAҷ�;�����)�����?��bG��ƀ�N�r���SM����t�H_�~0B�P�p"<��]��C��ϳ��"�]u�' ����Ї�%Jl�p��ة?#��_=�m�O�^��������𸲳�`�0��$�~}D¬�����s��>>���d�����8$ۚf]�l�	�E�qr��*^����[�!�e9D�H[�l��>�o��{gA��_gtS
���a%1kP -�N0+���]b���+s��r�85����.<����֮x���Npm��Z���$�f=��ǶNGz\���<��C=j�G*H�&
ǆZt�SI��Mp��q�9����.�֖�>�c=��+��X��
/��2k'��P�;j��T�=Xz��+���w�|�N�g�Nᕢ���
yo�IJ;<�������ȼ˩����`��:�
�=�J^�*���+�	a�����/�}�PB(d%����j�a�� �H˥6]i��Vq-�v�΍���/�� ��aP/���� ���Ð����I���:vt*��1i�B�F>_.{M�ٽ�Q��!+�B�~����C}��J+����oK~wZ�&<��m���*}�
����4��<⨹����R�Um�Q0��A�ʒ�yi��I/g�oG+�eo�
3�5��~��ߐ�$�����/��Mډ�3�Y}�F�cT�mo1\�y
E��}�|t,�0��Z F,Jf�aw��7^�4�WNZ�Je���ڰ�U��5x3�ڍ>�}$t�u�"�1dM��y�T=T|��j�I�
��Z��>�n^nٯ�`u�&=Pb�'�e����pF��f�fdf�0��z�~�4�!�LK�
�����0|g�����٥�O��O��RVGI��hK�C�r	)��iM<?4P���i&M"��?��a�,0����#���	�����]�"�I�FOp(ܜt:=��������Ie�q��,��4�uQ����x�v�cf��DT��B|[��w�n�\�,��HWD�V�l��\�-�F�,��(�+���+ָ�h����~���Q�ҏ�e���)��i�s�Ӳ
��&Ĝ<� �o2��$��p -���cV��'��*�o>FD~���Tm=(=du`��@�((��%��)=����.��Nj�\�C(\N���ell�3+���Cߕ� ���TzV�2�A���X0��������9
�>N,���쏐�y`1�����q^,��{�ci�e[�w!r��nsQ�t����V�^��V<ά}qʖ�˄}�U���.�R��	7��	��Υ&�*�~�02N�|Pf��U͟Ap �vR���ؐ��R��G�I��s���p�>�9
��/�Ⱥ���T�nt5�N �=��璗�t��d9s
���Ҷ�����?6������FQ���8��FFt8a��I/�_ �����I&*W"W?��V�7��U����}�$�K�K���@?���!7y���`��V8Y'�r��M�xWY�|�x�c��osD�4k�)��O�D���&���D(��ݸ��
 ǹ~V*�UF�\f;�ښ�SLlmY�ˎV0���Y{pf����3&��p?3}��ZRE}����(GFO�o����+,�(�:}�:@�C���
xГ�Ɠ�zQM�0�>��+|}t���9����r�ۏ��t��_�̩Aǎ}��)!����Vo�j�ҜM�l�k5�!�T�-��^��A�q�UԺ������R�P�f�q���gz��VRft�:���m������l��a[	�?O��c���U���區#u{lS	9&зw*%�����W�[U9@�X��a{�{��n�����{G!4y��͂-�S��l� !���}XO�3����8���J���_8W$+�A̅�W�&��&Gv8S�1�����:n�?0oξ�Am� �!�8����r��T|�)C9��D6T���p�%K�9�9!�*D�}2���U��_�mi]��3�G��q�+�
���׽�<�H��܊⮾s�?Q�ܑ늪l����К�*otT����͞���|��`�W�>���0�S����1{[�e�i��M��� �5����!�KY_!]Q�4̖�'ڰ9Ӛ=�|�c��T�Q��<�w��&C�%�X�r�͸]�ʀ(�N�n<�pY�#¾M}���䧯N�'�0׻31�`�7�H�<�D钕=�ub[��g��& ��_���'t&oYtl������|������c�o>�����a5c�Gˁ6���I��Er�fF}�4�Z��JJy�}��k��x
��O�ʛ�8ƣ`�Y�s����x�8e(��ٚp'j[ӎՔ햡�6���CdQX`��J��`[��]����5� ��yd�|�F�2��&��?��L���r��V)�����-P�$0��7�tu�Ih�������-�D��.7Cj�L����*������)��(�S���.��?�Ri)P]ι����*3
F�Gr����TU ����t��k���3�}���8���p�Ge�U�4ŦkŢ�C�����H��d��p�Xr��Y���l<�\2�~�\0U�IǗ�*�� ���BߧC�^E��;�k��?�������jt��b3�#��>���P�hFK[t�e����,o!R���ql��[0��\�o�%�P�&#��8�Ō��8P��-/-p��J�W|�h���%3��şa�<��E�NbĘ���ݮ�I'3��������4*�/X���T���.�"��Z D�S���O,N^S�-�W9s��������{�I��ܯ�]:��D_��"��,���4�Q��]�Tm��9p��<����ԙd;�[��tIP8y�N��N���c_:jU��}��ku��[L�'��b�K�b�" 26��l��R][P#|t��:��q���cq��x,�}*9Q.q�@�3�n���]*���ğ�aE�|a��<�X�E/���ܐ�,C�-R�ʾd��!�0���x>֝�q�>Ag�xԐae%�	��){���K'�P`�r�vs�ǽ�Ũ��7�b"�7�-V�y5P�j������`�7�N�3�.>�����5�������R&N�Bϟ�b���v�����l��&�!����E�a"!��9�5~u7t�	�'x��{��!�]��u>:�%:[$Wk��!�*\��2�l浀xn6��'�c���T&���+�76�ԙ#݆H�]�D���%y�e��O���ǻ��f�f����5z����:$Tټ��,EGÌ�8H~������/C��S�1I�����$�\[>OaUa�~W���%n���\�Z�����ms�4e'�%
�0��}ΩQ����О_sXeo0W훿ҾMN����o$����y����p:�^p�d.C����+d�KɹN��<ҿ�ix�Ļ���<Eآ��2U	RPF��� �_��b�	�΍�<>Ds9Z|"=��d�bAYш�(��c�#�"lY��M\��O���xu��@�}�A�Qٶ�zY�� .��=�$���U�|�F�a}�����\�Oj�;�PAs��M ��{����p�^��FV.\��-h��s�<�&K�2"R�t���rb���	F����Pm���ldu�x��}>*4u8�X�Ήu��포7y>�^��f�δ&U���K��bW��B�Gg���n�Ա�+��:iJ�EH�Qf����L�HD	v�!����5��F����W���DO��5����}���<ޖ���8�!L��='��f#�H�[���׮�	vqF�Z����\-9�kg����pz�YF�e��w���S(�:�S�u('y�U�W�F0��_ܪ�S�)�$�J�$]��G�mM�p��U��Q���G���܇�!K���E��/��2��<�V��~=���8�q~��W�0g֥�Ѽ�|�<��o�	��Z:�f��g�蝣��qB]�-Jxh�K�E�N��6��,nEƍb��1���$6�p�&�y���^L��LM��Z�|���$�x!��wfKK��Z�6I���ϾSL��Ogz�f� �Y��a��
��&��|�#���c�?g��k�X�ŃB]>B��}�/�VW��]X*4G��`1���<!��I)a j�m�@�r�L%���bF8X���僻-"x�lv�>�uF�cV��+Y/"Y�J<�~���.D�e����
F��Zr��H$�i[����R^�i$#&ht���W���T*5��@�]/[d'�X�Ɂ��*��?��Uk�[ɳ��,�������?�sZ��D�4���K�șK������z�OGp1�I`�5�vL��K�K ��~t�����=���$_���:�IvR��w�{��E��������䢥������&��ݍ��.���\�3�'���_&)T��U�Jp�)�(K�r�f�X�9W������c���&K0+r���QIy�E���t_L����֪5���p��l��B�D&��M�"�~5E{�`1UQ��m cQT����z��QG#c��չ��ǰ�tS�) ��rxH+���1��\�vt�GNe���H������o�E���=ޡ�9)o��R߉r��v���Y	��FR��bM�����Et	��Xf�n�$�9=����xͫ�'��u=�������-7��e�-�����!o�_	J��q-_��s/&̽���]���"��l���D��G&i��.�P9���|>6���������>�Ka�	X=n�lS��������v�w)�Khbt�
R�
Ⱦ�/7�B��P�O�e�\d���Y�c�%lceUfg��t��4���g��fB8CY��j�5t�D���I�բN�$<_�o���#��+�1qT���q/�>C�>M�N����K!�@WҪ2~+��F�%]�Xh���r�R��g޺��Nk^p.Q�IwX�{�W�"����7LJ�����@�a�j��:����s��f�������5
��H>Df�;���*��p�J��_@}��ٔ	��>/zWDu5��y��m��9=J�L�!2�"�r�>Ь��gxhb�e�e�6�%�G{ ��=�-"f4+6P���u�}ov E/�^�_Ծ9�O+{��S'8�W\�Ҧ�~Ȯ=U��,�W��ZJ!(�2���M��ѻ��BP�YDq5!'S솱�O��aN+��"(L9��\J/�Vw0E6����Q����L�M��6U���F�"�l�z��p�gx���j�{S�*��e)���-�H�lF�Ng�t��Rn�W��p X����@pnxqy�HU������"��2���)�.���`�kr���Bs�5��c4ւ��D����dM��O�Y��җs���pQmn}
i���_�I��
�3��+��ӆԻ!���oJ$�K?�� Ϥ�H4���5����<h=�x��	V��XY���WfH�9�6���_}k�l����ī�)SvY��ՙ��8�a�������V=,�e�~T(���/�b%��Zf�麂f��R�ԂL�C�^tn�/F�X'��o�� ��UH�;3�����ɣc����L��
�	e��o�=�}����5l��ۛ�E�^�ە��,��Ǡt���J	��e�1޼dv��炼�#s{p��s}:C�-����'�An1V"q�ǩ���m)�]D^u�=5�^'���ZR ..��G��+�l:DPm��oE��Y��Ӕ�t��[�L��x��_��^�{p���\8��r�ܨ%U��D���܅����Y�g��ǄLV�����R̭N	@�y͖�V9������'�+�w���-K�c3�Oa���{/����x����)JO�J�[���BWޅE~20CƓJ&��g�o������4_wM����Z�wI#�E�
t0x�&/��2+7�]&� �A�r�4Q�q	yb=����� 5Q�9�4��0v~�ق�=�m0����M�Pr/�m���SIOtVjH_����ً_�V��W��Y1Q��+8����[UjUi��F�H[J�[�ҁ�8�y@����l 6�c��p����ѥ������n��:�C��QW�>u�Z�R.�>�Α!iP�su���ӸuI���U����e�A�E�9Jܯob�Xz�F4�!S�g�l��mVD�;�z�zek)��EdǓ�i�aU�������7�گR�,��p,x
�cZe泫�9[�J�z(��ߋ �_��1��0��2�uף�U�!�3R3� ޒώ�tEQ<t�x!���R4G�.tU�V�&��~�#�[*�+:��\��%�}#�ā*���eNF}
{RB���Pψ����LoI��}c;3j$���[*H{R���#��m"z��M����k3�R��v=��,�s+-[�-��������1�b9r�dl���Y���	�t�	җ��8��W��)CM�H�r�5{�r�#�� �T-tm]��EFD��wh�>c�7�#p�wKܐ9p�(D��f)L{���g�ӹ��,("�|Le㧴 f������'�ݐ��S7�s����w���;�-t2<a����|�r�tũ�ןZ���B�ȝ�17�!x��,�&Fx�{��\�j4�Y(���������H�n�S�� 6E�9���ԍ�2}R� a7V���M�w��Qӂ&����|��\�.�A]ܶrA@��]��b����q���"��6��W��}4`U��[��$G7g>N����
�nW���Ęa$��a}IM6�D�j�L������)�h��E�GK�O��^�He�7�L\8V(��ȿR�厽u��W�YC�V���ǳ	��f0��:�]������^�<���݊�.G�Fy�N��C�S�-^��X1B��Y�����u�#��ņ<Z� �J'.U�����ͥ��#��8vR�{����݃�fE[�ϝ���P�+��h�hC��͜m��oh���0�d��u'C_8@��=��4�n�U��Nc�Ƥf��O��͚Y��*�w]�4go�"�� ��w��?4\;��E���]�]?�m2s�h�5=�s`k�n ����csL,����hˁe�*~d�,�3��cQ3��!�Z.��8���wr�a3#ԏ��3vwш�6u�4����ss���ڏ�caWazeJ8�A"���1� �J��B)c����M�ҵk�i�2���������7VNx��+[�d�p�C}�y��#܉�qK}�9o4$yd�B�ΥH˔�vk����5^�i|���Q$�CO?� &�S��P�[0lᮈ0ǶZ���	t�/�PTL��!4a|�8V���09<)YФc�jN8=����1�{�+4)_�ƪ]�ݽ寧6�J @2E��q��j�U�e?2�����	b��"jEp��g-GT���Ma�W����:�󞀱�<üق�^wW�(B�0�2?�"ZB�@b������mP�r}R.&�Κ��Z�T��|e�&�Z��S�y��il�!hž=�*�ٹ�D��r:���f,G�6�@�;�F@C��r���R4��&+`w����+�+���|H�,啨�U��-=>��&��r�0���D�6�����1�vX�	c@x��ףp,�b������sT�}}���Hh���>�5�s��]۫�m��/�6��eMg�Y���H��|�[.$M��L�{��=���,��Yå��(�*���+�btP��J\�\��ѝ�����I7L�E&Q�A����}��??g�.��D�:�bU���N@蕅@d�AD���x�r�KÞ*��f}�3�}$��.���4�&#��?�7պoP������X$�ʪ���(ѿ��aL�/��B�,Üb��VZ� �nr*,�8�?~�ۇF��b$.����D�q�o��"7zɎ)����F�h]:�R	����ڼ�׮��E�_�J�>hD�`F�M�p��U*VK�Z4�,��F���7cV�G��ҵ�Z��=b%�hqh�v��~�}�;Im2~W���W�6�IϏ��_����X;۾��=��|!۵�F�s-�f�|S4}������в <ԯ�P+���bq����jO��ä]��8t�h>�<�"�Ģ?_�GL�錃ɳ���7��d+�M�y�=���H;񠖈R�ź����څ:�����ɝ,ӄ�BKc3?5����8���B�[�wu/5D%�B�
s=�V [� ̩5�Y�����X�o�;	WU�-=#7���ǧM�j�،I}�qg��MP����L��,����9�w�(������;������a��R�O`MW��i�p�}H�I[�������5�'�nL�i�����I�����M?����u��v�HR��<�r`��+�����1�n��]U��~�d����s�V�;�8���}6�_C�i&�[;�tO�W�I���tLG��u�
�F5�|��Dѫ��Bl�V���3�T�h��4��=s8� �dl�>��8�W1�Trㅔd��W�[*,)Ć�L��.11+����-�a��rכ�w����� <;Ç���9ƗW�j��x1V[�,Uǰ�Z] �\��#X�MT?]W������ ���kcJ�Jq4ׯsؚ�� ĥqQ=})�8���y�y3U��A��z;LÑb	Fm�^�vȭњp#&�����߳��u�XCQ��[_�G8�4�x�����/�5�33U1b��Ś~6rGXzd����z �" ��-�U6�7�X��u����l^R�Q��C�?
��orheQ��ֱ~51�S����������r������,}ޒ2awD�{����}��gU�l0,��D����m��z`��b���ŧ޻�U]�<*�=P�9�~��	�Z���K<��6�̳�&�t�o6 A(7I�t����X��ی;F0�=�;X�J~�h.��cR��vm�=gU,9��d��|����y1��Vg	[�ۺ�Yk۠��8
��0�W������K��*f��U$
_�ױP�{�ˌs��k��r1�U`�#�x/H��KL�z��	5�Q(�gL_�y����qf*\9K�ؕ^G�+]�/��&���ah��Y���3}�_����z�zn� ����r�5	�[�{��'X��J_!B	�L�i;!��澠���`�:�+�WU�"���{ZV�^Er�f9��S}_I��Aǭ�ۏ 입�y5�Q��M8�p��x~ౌa[4x6@���9�w��y�t�*Ǝh[LD���&ǐ�RCm8i�Tȣ`�y�?f�AFx�1;>r}�KLl��Z�!��P�g��߅x �l����	H*f��=k�i)糯Pn��ԁo��Ji�ň��p�j.�@F��12�W2/p��-u틔�n���=�]����XzG5� @-��r���+qn$$ALufj0\�ku���|�=��ưtJ�g)��'zN��{��F�%�.y�Lx�D�cA�E/K �����N"в�Y!ò�m6�
B���fU�a�#{�P?Ɋy�1�!:ы���]��y�ǿ����2�͛ݨ�M�I��jJL��'����h�Z���q� �x�<���a�A�SZ���v��� mOn���/�ݛ��M!|�鏙��@إ|��h��i�;p�_ �q�ܰz���"ӭ���~l�x�9�\�[X�*2���/m5����'zs(p7وy]l/is�>uL%J��Ơ�k�hO��P�@P�#@Ԡ�����?o.��U��I�"���U���R.�R�<@N囀�?e�^P����A�y8��R����x��"z�7�>��&v[n��y�M�vı���;0:��I�@�*4Mɒ����@^�/�|��!���YNW�\�u錥����:����p�F��.S�hPŬ��������y|��~�z�Y!�TJS(�Mۧ6h��4�qdK���o��x�����l�I�ebmR����=i���`c(E��F�+���c?24�����E�.
t�{�,���>ө��ú�0��	CTa2�_ l�^.|}&q�.���1��l�/Ka�gR�ۯ��p1-5+e�7��;�<"�D��kbX�Mc�xN�yg���r�K��b����v�O5-�'k������$�S��wg��JK�����6�B3��]dɦy��՚(A���%5�Pb����`�A{�V��V�yi���a�����:pA���'qo38/��s���@(��z���D���S�6\�SHY��`�����-�|���� BU$3���=�J�gbWe°P�]W(�->VʶGH���G=-`���T��fJ�_$���$4�$p�t�5�,4����-h��cS��%_bV�aD5�����XCy�f+��-*������ea��6�C:��O���`*D�J�a	�g˂��l�?�3�M��j/Ŕ��&��Ē���&{����@�do(�@��b��S��~����e��{l�ռw'� v���BO`�y[�*Y��>��)�w_�����0�\�Y5n��X,s��>w.�&QJ:x�/�9���҃QR��և9Z��d��[���A��i�������,����}���*��p��Oy6Q��J�4-2�V;T%q7Hk�3���Wk����P��N{KGь�V�ż���q��؈��`��Ѯ���)��e�7��.��q�!�J���`���
���.�R���P;0/l��˻�-�芛x�yn��|���1+�᝕�L2���t����$�G{�r�<"��d�t��^�_k]g_t'�r�Xl�����+��`�n������*9D<8���ѹ��g\�R����\.�DBʌW���XO�̮,�@*~!}S�<K8� *g�U��s'�d�����ii�Zsw���
n |��,����x@�� +]���qv-k��'�{{zyH���J�:���ދw�gA{��_}S�y|�!A��Jd�0����h1y2M�h�+u�g[�_"|�{^�9	u^�k\EdvGT��2����?����U������'��4��\jbEq��/�r����
��_^�2^��v'x���&�$ű��^D��|�gu��l5:�Y�����,%�s��e�)O�@��o�ZN:����vIc�.��ɑـ��FS;yP	Pt�T;�?�-B�j`�]��-����pq�GJ�U�>l�'"�C��x� L�����L�h�Y�*A�~��Bb��Yp��&�D��%Ϲ��%���b0��ԝ�l-���5��T5�=lBR��GQτ�7d�p?]�A�[ ��t@@��b�j��%��bj��'���飊����}*(F{m#Ȣ��g!����i�l��~<o�^�c<�����4�)o���]u3�T����!��m�AI�fX�5�B��w��@XOVr��|����B���!?C`/�4i�&~�rA>&���A��}vux�s'��i�xo+��hs+�T���+�xH�+��Ԇ��y���vc�iN��)+�(�-�$2qw���Nn��ٚ�󊯑辄ab4V���h�/�:���Q��b���֡�?�@]Zy\�#X�~6f��+?�D��"��~+p�S��e������͙A?u�*I��wA�ߖ�\d�B�').���hoF�H�Z����t��$�Iҝ��� C��<t�ʘ�"�����Z��j#���пL$��t%���pW�>�Y���ph����\,��C���E�so��0�wm�}�7��;p?A�0�
2�b�@�k�8ղk�*�0�Jce�ryG��Cj�c��[���h�º���E���P��v��j|�i0�g�qs��|���c^lK����DUG?��+�:��۱��ЖI�'G��T����;+`�h�(Ҁ��@-t�@�ʹ�2Q$<E=�0��VЋ
 ��)��k�G���\�&�-C��.�û
o��c��rJ�0vju�Y�Z:������ud����7s��N q�
ދ���%���q8�R�
�k85TC+-F�H��������y��ee�o��dJ��NA�H˞��� �S��+�YMIЇ�v�l�Gf�%�S��;�D�6t<_M!��}.�V����eyi�0�3q��R�{J�S�-6ޒ�M��f���o�TB�aCܧռ�;��ư�řę2������e}��]�֚�y�E[�ߤZ�c� ==�-����Ȗ�]H՛�$(�)C�EkN��p���+�"�Y949�j%�=��)���9=��o��[A��5F�u�]k�Vj��7y:.�D@�ũ�l�L"�o/ @����cZ�V�a��s5������E� òS�w�2	��*@\�1��M�ת�#o�����e(�8�aĭUю9fT�m(#~�=��Yid	�in���3�������՘��.IZ�Y7s���}����&�2�B����֓�'R�_{�.�K��: ]z`�fՓV�U=����d��]U��(�����֍9:"��ň(,���M?#I�ĵ���)�{����y]�s����xo9�0��]k�ǂ������+�L�%�e�mB"�ò�:��s�fyzҵ~f�pN�Y~�8=?�3�|]�2���L����Z�o-���'�GED�-�E����d��`۰.Ym�ƙ^X���O<�ǜ�7]k4�>�`�Dw;�rh��ʘz�����g>�4�0Al<���y6���H��y���$q���Q��/��-3���c��$�ԕs�U_���ؿ����k�7�[?� wԸ/��Q�%��y�z��n�_���>���Rc���-�ΌA�X)x�zN�ޔ�/;ԧ�uR ��OhF盯�H�If�Co-���K��^J�(���B�%i/g��{$<�<����=1��k�e���+��Xڨ���_��W���U~��0~�o������R�u���؆g�|6�A�K��4Őn��zY�A��ܸ�t^m���P�S(�������Vj]�;]�fHaI����CĘ�jw�W���^���`#E�`d�|9gw-g��׼�	{�ԛ��d_ܼ^%U�je�{��{�!�{Ŵ%7Bж_�]�;���������f�O�䖐=�o��;ݩ�R� wϲ� B���0xv���wk���H�c�~V�K"��|��:�)<���4�� �>Y�?ơ!�9�>�I��2��+��qh��wF����E����`�Z��بjL5y���G�E�	�B��u��E�|���k�d�16�<��g9�,;G�-t��q�G��)���;��f�h5�)M�����]�f�����(�gU�JK1O�4��'�]��Ħ��ٯ��A���n��1B�Uu	�d�~(1��c�y��3�����m|c>�Ix�8q���nT�{>����1��e_F�`�b3��'��I
KV���۬�m>��'��E>���T܎�&��wv���:M�.�K�y���˓�_��6��C����pAx�r-S�6�Y<#{�q2�n�$�P"H��K��R|��Ω$���~��R����=^G��y���du��N��yaS��� q:\��Z[��]��;*=�1j'tM���o�(s[����.���mñ\������r�3B�p�;��+���%�9����f�b�o<1s!uV��a==Y���R�椔�2�ѻ^0\%�-̙��n�B��4�XԘrf�@�$($��"}a%u��66��4�dᢤ<;��J��r���)��p���T�>�e�J��2cJq8"٦�㸈��g��[����FuV�ꞈ�G��w���E�1��l�4��0��.@e�	G�����Ȥ�\o�>խ+{K�Lh�i/a����)��^Q�$�_)X; �����q���Sm��G�tG?��v��\�E�1�����Q"�/��k ڤ����l�g�lwy�۱��O�,�o8!�\��z�{��)W�1	qd�^|���"�z/��I��'.*\�l��(S�T�S���8D��&l��_:�8ua�#Fȥ]B+Qtu�C
4L�<w�$P'�W?R��Աf>dv]a:w1�3�x��p&N�J�gY��?�
��LV":5�4�/R%�:�D����c����vg������A2�̹�=f�n�hO����{��!1|������V�*�N(I�1���-ǿ%��r�_���1���Tc��J�h�a4[$�oY�x�G���2���d��v�B$�No��s���yO:��!��w��G�e���a�b�
GD`P�4�#R�{�JmI��r���+8��PCt�X{�7�H���0�ӖjZx��z�Ua���h$��(k����+|.4߉@�N_�TC��fO���=:\b��L�S���:3�FX�YI���S,��!���5\qP�K�B��x��])]�)'��>�Ȉ@�_/4(��z�O2�j��xh��Fn��$��(�%����z�T#︴N3�g�@�a!�1��	ݚ2�"DL>�i��V 3
8j-!���N�V��!�����`���l�Ѕ��[d�ЪU1ne<]4��Ow�F�M���+6d/��e�S	�$�{�Ƽ�k�P�~6@�{����)��ݸ.�.����c�bx���*(��E�V&�K�i�P���ȯ`����H�*�8���Y���s����A����#5�-CceA�op�ھN�
8�Eo��D;��H�.��cP�[f��!�i�/uO�P��E
�R���/EY/H���	��?y���o"���&	��(�4ج\�^*�����BRe��\.YR.D۬�`!M�mڹ�]�'�ru;񭢹��V��hll�O=T�V?��
Bɚr6q��%k�	J��>�F ����r
�u�	Q:O=r�E(�����E��u�`���3[>�(�W�?����FYKn�e�\��&N�	H�K!��!@A
L�?�'-�o�\��0��+�o�=�n��Rr�p����aMdjb��"�����H`0N�فv8�45{�'u<�7�0ġ��1Z���_LE�s˗�Չ����P�7�@N�1+T�fbm%L��*O�!�ʤ�����'�B�n�b����:����y�S�d�b�A��B%_�
1{'�*g��	_K�#�������z��ɒ,���X�M�l~�2����Ҿ�q�Ѱ��%jpI���Z�̚-�b������WG}�T�yo�i�mʗ�JMo�ҧ�=��6
�Sp__k%�N8yl쳓e����N��J�0K� ����Y+��*S����.vw��B�4�^�t!O?�ʎRYב�9�ܵD�J�����`o�>.�)�I�L@-X����r�H�v�5�':��&�k��4��:��֎��d՗t�i��
���T0fx��)[��@�k�i#��Zgt½�����DU6Jk珘�����SW��B�Ɏ������I�\{�lYbt������,�:c
 �T�B}N��z}    �'���؃� ����nM1��g�    YZ