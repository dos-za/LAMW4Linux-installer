#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2576132398"
MD5="fbddfcd644680e975524b820e4347a63"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21192"
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
	echo Date of packaging: Thu May  6 21:54:15 -03 2021
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
�7zXZ  �ִF !   �X���R�] �}��1Dd]����P�t�D�l;������)O��(��M%<~L�k3������}�3����|��pl�I����Ђ#���q~9�;�X�8��ς]$��Rz�sn����y��ũ��uٚ�ɸ�ჾ_W����ͦa*�@ؒ��X��r�G�	Q��^v�K�H�o�F�C�_����R}D��]���!�S��f�B)DR�he�r/���7!dK��ɯ�ST�őMw�ċ�O���ڮ����N�1�/dY�0�qm�#G?���y�(0�Y#���Y+O3�������qoT�ó������k�)Θ�Y����d���~��.�:�
ƀ&č��ieO�~j/�	��t��O��j*�7�[�4X�n̸aR[�g'��QM�Y����l� W�Qd�Vw���R=~����6i;�YF|���vČ��Q��R�5�I<f�k����.dGү���G�n6���r��2/����ښ	���-\����Q&Gl���P���mjL�+�x�"s]��v��V��f����@wC��`�a�'#�'����88��v��A���=�S���ڹ��=k�x!�`��Њ\��1�A�E�o����ˇ+�U~�<}A�[���o铡�:��8q^܄�,W�tM��8<a@��m��UtV���0w;��r9�����̜(x����#n2H�������8@���!�oTKl_�4D�$	<�sڼ5�r?ƀ���^Z}ĝǼ��qW�e�T�!��:_)���
��f#�(p�n��y.�Ȏd��:ۛ_�K��GD�6��k�#��y��?��;_�^�jFohDQ�Ty�_tU�H�|Q,ks!��̩aU;�b' �'��O!N��%�����=�n���Y�hY �y��J���9EB^�8,K}�
tU�F���nw�+kk����,M�>1R�K�b=���Ml������T��E7��c��D!�x��z��?�������#$&d��N()�fU�O��ߝ�h��!?
���tr�G�zꞎf�Z�g��¶:ͭ[����"nR�!�L�y�)�Ֆ	���e�O�X���߰�^;-�#P���������nnC��\1��FC� �+�����tL�FaH��x�b��$?������"-����?��?W�S�;�j����L��������nt����x�\I�l�,j�[m�d�	N�����_�-3���<�h%��\�6?�	�VHܨ�Q�3{�#�\���z��R��6n;y��͐����#�ݝ\�T��?��1�_����>�
�0�ouUӿ�*�:}��lY']�4w�l��lf�By�����e�����VؐՀ:bG�
7~�D�Z���K��bw�-R��%�,�"b���d��(J�ڣ���Q��8����,	�Α��ANZ�h��sN�B�ɾ)gx����������%4o�Y��W�e����:�p_�������$������m�<����r������.�C���5Aw��r;��p�����?���d�R-sa `�@��@1��#���
��R��^G;o���!#C2Em�mx��寉��=I��1W7�:���,4'��S{�H�c���	
A��@5$����X�RW��7f<%�Ѽ���Ȱu����dϥ�;ȶE\�H��/-FO�-0�ŭ#Ǖ+ݖ�ξ��$$���f�`S+�	�����	�������hDe��Lk^�m��	�+��*�l�1�}y��&�a�o\��/����F�P�2��3�m���0�;mE��@�!�`�
~Ke�/��(�A�}j�^jO+���)-���2t#mp'saD�(6�yd�	ϐ>3$0^����F����&��q1#��(��ք�lة�IOS	��\�j�����@d佐 ( wj �!��f�7�q�����S���������gi���1s�
+��ہeHUE߽U�r�vV��4�>����t�T
>ץ$��vޱ,�0_k�;��t�������H>�����$T�W"�ŝ6�X���ܞǓ�C=s�tl yQ}�g�H�������ۺ�ǡ����6�&��$�[d/��^��ϱ�6#tD�����c'O>�{��g��D�@,��5# �M��I�͈���]Y8:����Y̨�$���E	�Y�qTVo�h��Q��,�%�&8ĉ:���)�y���\�}/��oJ(7eSAT`\�x��d�Z���J��q��/��,P�Dj�%h��&;�hT���޽ɥ���b_;�M��s���y�Q&����@�cAϻ�Hd�|IHi�����d��L%��lIH���5�-�=��[1YXeq���'�!y��),^�:ķQ9B]�!�'s7Vv i��D�f���]���u���[�އ#��c�o�\. a�#..�Ŧ+�/���̕��F�I^OAH�۴6*���D�I9��H�z�|�6�Zq{�ݪ5u��.q�e�WUƄ���gY��xw�}��*��k����
�e^z�l�P��
/��Su;�b���(ݥ��{3���P�v|X������GnE��I��Gݑ2�k�CN���'Q^��<�}GG�:	.ܘ�E��,���} ChF!k]��
��gW�\�5i	f��_�D�q'�����5}2Ks�i;����Pԫ-��(���c��������k��PFa)�Ʈ�A��F�U��Xp��:�״R0��mp�D� SY���l�#���+�vE�����{҉�W��躥������ x/E�58��Em��k���P]���u��h*~��w
�nkO5�j}>��;�l��i&�m^&|��?V�kZ��zWr����� ��dF�m��F�А�*J�%��  ��-���%
ͥ/+�9bt.�@���)�1e5@L�p@�ԯ�ܙT�����a7�-aZ=�1�s���V�I����ij�ޖ�}�n����@R�g�$!�z�QYǪ2GrH�p�M�<���a�[E�� �8R�Rf
2<��؋�jH
\�
�u��i0���)�G��|o5)�����vf#Q��1�TJ]�%�j�YF�_��7Y���w�b�jK�Z�F�qk��ж�[|$G-v�gO �L�mϐ2�M��v�#� �;����GxC�V���(���8-I�B�J�u�8\�+�R���f�|���KJ_��GJ����tPw]r�@6�ywXT���܁���԰'r$��V*\��>�F	[:,����ɋ:��?���W7�U������d�am�S344l�^m�o���&�C�(\�H�S���8Nb-����Fs�^�CIe���#�)�҃�+-��X����s��E�P^�OW�O�v��Wt�BP��:	 �Ѩ���	8X`K�!�wi��M�	�����R_������t�Uٙ��?& �y.٭�;Ք���x����3�-�����{�8cd�3%f�	h��|Ԫ�#���ɢ�?��T?��3����5I�W$�q�a�GR �����/A|�Ě/7�����Fk�?�63�c��n�M����"*5�����1:d!�yt)6d�	�b{]xi��/��`����Ш��BM$��(rD�������(��*hz`� #���Slm���L�߾��)�cN4C�����s���~|!��؏�T�3.��A�(�m�W�T�7R�P��F�Q��G�q����~��E�<�4q<�M$wmy��0>�ė�],��x�t�-`�H4s�LLzM��n\�g�n�r�K7�� ����ڨ#b]63��P42�K���K�Q���0��'?��ve~ؐ�hYF,���Z!�݊DcΌl&(:�H��8��LEk�q7��A*w�z���ꝁ{��>sW�AW�ۆ�3�E��y�e_%h�KS��%i�`w��#�|r��\�������uĦzC"x��g��[{������������'�V*�ݳ�����Cһr����B__�R(�3�h���`dtn�F�{TZl��LP��^c���l�¼U<a��3�/\��U��6`��a�7f8L��b�7�}�-��	�<�tɔo�U���)�S5�t�\Ƥ����>���1M$�\rr�Qʱ���}��=/_P/��#.�����N}�P�CQx�ݲ�<�ǜ��BNp{���/�ܲ�u�bP\#��`����rk���-D=#�1]?��2>�- ��:G�L�q��h�y�:������>�Oc�w������l7c��ơ]Hy(;jjM"K���-jZW���dԐ̈���o�1U���F.e��b#V*��Y�6%�T���
]O��#��!��J�"JI{�t�c��g2�ԇ�Q�����Wq�4��S�q7�s^dG�������-��l�p�Ql�>P$�my�i�
��ښ�',�������q}������=hj�((��|��2���xœ�}�r�$���_��k���ަ��)�S(*T?K��2���)̶��΃�$�3.3�<��ٻȗ�b������h%�I#$~۟����.4^�܉�ׯJ�!�,��Kq0�0���	��N�M��5\W	�b;���+�*{fi�z�]�.]^�נ�����`�0x)�=��Z��57C���~C������np����_ׇ��y��FE]��Ɣ��>�6����6$�\����Ql��S<�]��n�s�  ��J%�;K���5�{�VT���3�O�YQy��Dg%�apwb��|���v\������ګ#8����^zݩ��؆(�zg�ט� Nh�R�
�wͽŹ/����L[NVʛ'�Nd1֛��#|dT��om<>cTᩑ#��lJs��`'����.Q7�f��$;+~����n ���0������HJx$���^��K,,'L<Zd�5�K�ש�K0z��\n���pz�]Jd՚���
�M���'8F"+�N�$��������jq���U|2[<k�S	�SF���o7>b�'�ƭ�|���%{7u�#I���G�Sp� ܄ӧ�����{p��G��~o�S_%&�u�n����TU��0!�bE[�GRK络d���5On]���쇩��Z��^���I�P�h C�h�g�X�K%����Rj���
�di��3D(�#�����`&��ǁ���pr�iLqY1PM���_G����@,f�O�o��6xx�[�F��b�
�����Y��\��%2l��9��hZ���T ��S�D+j�C�ٻ�aS�t�D�R�4�&�3;�z����L�D-͠b��<�8>~-;�m�0Y0��1�:�KX-1ڶ��Լ63k*�	τ�g"\|����s1�M��G'[�e�Rg*]��%�k�5ڍ���q�������ީB�Dt�ɒI��9n�I7��P[RӐ�s1u�]�P�S4K|��C��&�#�x�D��j�Ȓ����ʽ��s)[N&�[���~��i�}.�����5F �6CM^c�ΐ�J�OOũ���j�%�H:E��s�� {HC�����
̅��n	h���bY��o�������*�0 �ug�B�8Jv�8"G�4�H>�9���z;M��G��n"��7�7������u��-�-���
�ڃ��G�i ��z��Ea�{
w�N�oO΍{hٗwO��!El�I��>�.��	�s�Ր�)�H��!7�����{Z��0��k2��`)
c@Đ4><^t,��'W�U\�0���@CzB�+0+��lbg�.{%;z ,X�4�47�7��Â8�\z����Ѥ�������QM�P,�x��!�����U_�SV�a'=#5�W��I��z^:�u+O�"O��?9�����fp}�4�o`�( Rl�%XT��T���[��IѸŅH�bB��^�5!�H�Xφ���v˲��� {����QA"cT�
5Q�5�RE�K�h�q4�\AK7R`�0��7��ه�|��;�gm��@{��2pih�؆zϥ~��� �i���z g�I���� �����0�{J�j�����鱄QߥT�e)��Bav�J�$�۳RK9Ԉ�'�F��˒w@%�p�u�����ڕ����iE��M��|��^�_fYݻ�]�1�?㶯qQ
�|E���bXTB�qGb|Q)�Q��з�}�7:�dX;48^����t:��T l�2�LΖnA�xnl��{�p ��x����r�	�tDҢ� ���� �{�Y���t�PB�nb��O*I�?e��,& O�꜡KL	!S���2�)��\�Zp�է���ȋ��Ap`r�|> ᷻W}���u�O�[�JՀ�zv���;�#��[J�H��T�ڌ����z�3Z��k��Ҩ�ҟ8�)Bp[s�F҃>ǣ�o����H�F !��=g�o�y��ۅ����p��Cs{R�?���*}{X�*YRu�T�=E��m+EX��W���M�#D��t-l)aX��ʂ�讕�F��ŏ������dx�����Eܪ_ŮMj���%�<BF�&�N�~Λ^&X�k�e�h#I֭�/�e2@��v������}dߛۻ����G�`M���(��*&	�/:�C�!{���0����Xo������MQ���D�7��H5������ZjΗ�#X�c��#X\�GЎ�o�_�,��"+[^���`�oB4��u��]�1�2n4
,��Ⱥ���D�����"%�w�^����\�S��Qd�=�N1�%T�?큛+y��"9��S\+�9�⠁�@o ]�K`���z -���k%h�+��]i���)�ӍY5M��s�N��0���IQ�01���Q�쭈j�H�8j�3:����>���٢l-�6 ���y��������"(�
�̉��Z���x�q��:g4q�C��=�%�H��y¹{0ŷu��x�]�&bx�~݆yj�@(*v��|O�:/u(��ʸ;L̚7psg�b{}Q/Ħ+�Ň�LN���'�d6��?ѕ�S�9b ohy����`@m���fpU������"�1�z�,��_�$��㸗����~hc�m�rT�MB߫8��b��:�ѧ�Ӓ��(�2��	�,�ƉPb�#������p��ݎ���L�P����>ܬ��vYq����0����6S�k����u�\��l7?/F�zt.�%/5"���N���{�%X�qv)�*�)�h�j�
#5N\��A�#����_�t����S�p���d�a�� wOc�~�	,G��ԯ�۝��cn�^$�k9�S�9�	�������'��9��]>������a<-g�I�� ���j+�`�!���kHU�������� Fn����B��l����DW@��cD�s��٩�Ϙ�����^��9�5R�ۤ��ɏ�O�4J��A��dx.ӥ�b6��h���Ĵn�S��j��?d�\m�^���H5{Q�1)b�I���߉�q\@z~�II"@Y��추j~����b'��G.r�5�o�3��1|>!ٮo�a�/��n+:�%ӆ��l�HXikT�����E�5����Z������5�����]{/ھ��Jn��p��F��R�`i��Ů'�z��x �ځ�?;!X�Y���&�i�Mf��1�W�9"�`H�XI�}��S��5�1jX��2�K�j�k����!���uY(�Zw.Q����h�b�<8M����]Ծuf5	}6��R���A\f��]���`C	����GYh��z�u��2��\퇘v�{��9�O�a�Y}��;O�L�F_l�FT(��J�ջS�~W	Ԟ�-δw �+��X����s��L�����V<]�k��}qTɿ9V_������Gd�@1@w�p�����m2Ȑzs�X��¸�%h�'���]ٙ#,y��eM^|L�/
D.=�M�EWL%�a9�*g�ft�E}�sw&6C�
N�@��EIi������\��j��\�ϑ����g_$8.j�)4�|�C��?��9|/�:�ݚ��CD�#k*��»�,[M��3;��iN21�Z�u �6β���>{��!����N�ySA�����ڒ�~��;��Dl��:`���f�V{��I�_�Ȉ����\�X�s5~�����;✳���A�s�����2>@	�}����E��<��RD{������hc�a�V�ګL_���♔:[��F��ʂ��G�N+9�e^�ޱ��7D��m�垔/e�ٕ��i�|�u��ʆ%� Ty�ShՐ�������q���.G6�C%�BT�C"��=u`�yL�ρ�5U��At��vB�Z��>١�)	�/��`���,J�^�@�O���R�c،�V�QQW3Z�oA�y"p�0������]f�8H.���m�3��c@�R���U�%G�q�$
 rQe�ږ�R=q���Y3~R|�OZ����ŝ�juA�^�F|i��_�����I�L�W:yj�d��¡����{���q2�!'��uxyh/Z��Zͼ:�Z�8ǥ������aq1�2Zt���g.���W�_��i���${v�l,Wkݬ��w@Ñ���UD�{$�뢻	2�$���om�C����H��%�X
�G�O�vEn�p}E�~�kG�dv��6/��d11�vM�U9U����~�7�|����/��	�FwR�7��2���!SIv�ue��S��h0�
���mQ��k9(��M;�
��y�Qrq�٦Y��n��%8q�/ 9NÈ��s�J�x۞3�N���`^I\'�A��3� ��ڲM�~��#��U!D�/����i&e}j�	l�&����/��)�݉���w?kG��Ɗ��S�x�O1����V*�c3�nJ�{�19�ߌ�{juI�0��)���)�C��?��d.��k�wr\J2<�>���%kB��ϙ���R��O���x�-7����إ�Z�/>�q��Yײ��%��5�2@vJ��}E8.�/��O^�|ݶ��b��T�`p�9�:on�1Û���D~iP��
g<Cb�c���>�����}��n�)�M�^0o�S�!��T���N�y$���|B�B9�I5���	纨9��/�(�Ғg��1�&��<��O,���������ؘ��$飙�.z0ED������}����=��nߢ�z4?�
)cO�p�|[�ɶ��dG�۳����F}�aX�z�f��u�ܩm��CƮ��1j�������S:]�F��#��d��Rڨ�^(B�1E�(A�F�3��T�N�@il��	R;Z9�������M�M�U�y'P4G�;Q�P��`668��6�ԗ�j����Z� ��9�_y�$fRc����H�~MZ�|���@G��ʍ�)?w�����"�?�e�!��2��/���lV��D�W�%�~�����'�`D���FT��<�~J�t���Ȕ<e�^p�t������l���M^���+��ʹ�"�\�<���w�J�>��.ۣ{�A0�Z��[�^��M��EV~���r��	Z���ɳ��IЁ_��E��g��I7Q�0U½�Q�*xB�PB߱�}a
*h��~�l���Z��_g<<���G���V+-��ݫ��޹�1��NH���;����!����U��g�$�)�YN�d���& ���Fv�9�� O�{�ˁ�V%�m#�Ԓ��"G��w~�::)��_�nw����Ǽ]U��%�nS��ֶ�C�����8��Ip��h���Ly��~W��ۋ�ڃɸ��y,�0}1^p������z��`���e6���|�Rd �j�� �o*^��صFan�dC��*�ET��L�h~_z0<NS$5|�	��L�I��e:^�	U��Hk�t��H"Wx�w4O K�k�j�eV���8Pm���zRB��y��i%���W��>�w����s����x�0��2������l��^�]R+Q�[w�ѵ���r�S�Tw	S{l^����`��	>����[Z"uZ� ��F0�6`Н��@�Տ��8���w����9�*���?=���I��[G!��6���XDmm�0F�[(�h�zAW���!EW������D�:>LFΊ
�{�mt?�O��t�9m�/�ƨS�fH�a�:Ǟ8�
�E�)?�{�h�.a'�� ms��|]���aIe�xclH�����N�<�.���͂x�|N�/���į$}�I/��j!s��N��G���1��S�H�k]���N���xȀ������:EW�d�Pf�C��L]�  .�b���$Ç쌢���9�o��y�e	C�Pϕ���<}Su��)��Y!�Q��/cyÙ���*��>�������zŔ��]F�%GZ�����^�qU�N` ƾ��2)�9�Z �~�����D]��$p���\R���k�A�$D��Iq)�] !E�3��oې�hkn�G�ɞ}wo����(�v�̩�<p'�9HqS
�ӷh6n���ˤ`������x?h���^+VX������Mm�Y21�N�F�7M�Q=o�xAY�ΑBu<�
H۬C�UGW�^�ނ�%����SS�焛[�@��(��Y���mݡ�%�|3m���I.qz�<��1Q�m�'�*cG��_M-�2�qQ�� oe�A�_�G���zL��A���=��LR�TTݟ��#T8�tn�s�O/7Ů{����F	m݄]�.�p(,��N�7�z�=���`�m>���F���HL���M�� ��&�h�&
WX�u���ߜ���,fi��b&���$��ܜ-�Bv�����(t������H�8���L�}��Κ�0����%=�&�m��9��2|��H����uy�Ft@��Ǳ��tY�6Ӎ9�!���u�;�_�������Z��ZVz�I�SZ�K$w]� _����x%�&I�?�����Ιu�A�#޵�ٿc�,��)R��������<xLb�x�l�d��g�u�6g��t;i��B+�]���+�9�p���mͭ4��WyB�,9�m��J�k�P]x6ls�?c�3[����]mo��ر8}Z]��I��kRǮ�!r=��Y�56T�D@���P!���e\��X��w��&��+/�
9��޻�ղ<D8;')\�D	
������/^/�Mr�5�
���V�.�gj����R"������4�s�_2�]���,��f��CNټ�P��=�և�th+�ʻPԀ��4��
 Q��?�����º�������P���;A��c��T�Z}�ĤQ����\j���tڞ�<3OXj�����o ���_�E�+ŀV�.y�^��u�{,��PrO��8�q�R79Z.��91`8�|5G�yXSa�Ѵ���-��>�Z�����XK�f��u��L0�ȕ].7��4=����}�N�S�%����W~Q6�w0#|3%=���x!�ڜ�8��D�o@�4�n�Q<��h���`��`��ew3�~G����Qfe,�C����7I�ڂ�D8L}5�>��f$�pc��)b3 �IE��M�q� �,�`R�g2'
d�(Ln��];n�^�%9���i�0jC�bhP�- �"���#kCB^$<���.���-?�H� n�3PY�%����Cbj��#�СtA���^�@u���+6�Z�n���2�X��Bk�Q'4i�|eO�B�(�b� �Ŗ�#�����Rj��]_����_�g^��-Yp�W~�G�-��2An�/타��8kGa��H�����}3��'NL9ؐy�ZX�@6D����s<�9�y*�l�J:�[$Sx��5̤�Z�>��!�k @�I�&�|���N^����xB�=��f�:����c��e,�2_�5 ����0����h�-��抅g؎��y�4��_����ǝ���g�s#���9��r���R�7f N֥�.P��+]>"ᾳ��l�ɌR/��'�7�O�9���ąY&w���,!���f1O�����~�|���f;W7�_�B͆=Dr�48�FŻ�z���e~���p�8H��ipS̴D0��[�w��p��=R����S��q	
���a2>�z��*�G�|��R4ZM���T��U��kǮ�9.�)\���n}��dY�ˆ�=��0����!��P�d�噡U�'B7�UN��]�)WiLˁ��k	�J�
��3�
LgB7ԡ�q�BLJ�^�#>l۶�'7K���:ӺY�����G*�	w/S|����/w�R�z}m��r�b�KYje�0�k+���x^��|R\5��C4)�:��/o��K6l��a̼ycq4���x=���y_�6�^�/"2���1����#oT��ǆ{��P�7�P��7�m�@��5�ا*����z�X�QRs���u�Ts)j���� ݥ��r|��i�������ߚ���˜zsA[�8:�a����z�d��t��ʤg�my/��� c�N׷�WD	Ɗ���t^�ξ��La��:s'I{�}#��ƣ&�X�g����f�#Z/��8/n>8�.Z̐���Gtܼ:)�e�����+�bk� yxv�8~�l��<���1����;�k*A1�@ltm[ s�>�A��כ����b��F�h� �!d|W��?�i��%�G��Jf�PW����1��] �n�2փ$W�7��ǤȜ��a�����C���F������V�ֶd_(?��:&�{��3C����e�m�u3�M�ʗ$��v|��v˛@��,,7����o����ț{��)��?^���uٮ`��Z�
�/�����d�kn��[ӣfk��%'}%��3h����~�$��ٞ֨�/�%��	�J��%"��_��"��g��M}�x��XΝO��wZ� ��2	��v;�
��Ţ�a�x�O�k�7���%�3L��Yܨ��Ӕ¥C���0�Yv-�_I�W.�Ϟ�FS��=�1�c��V�-k/y�@z�Yi�r6Y漨�ɺB83�#��X�m����j/�o$�i�+�
�<�&`�2��;Ő����X��]�<��X�ɠe��Yi����(Y��㭴��<�d�#Ӈ�-+�4 ٴYVPYs�F;��v�aP.�N�<E��G���ʭ߯�+C�$h!������N�2Z�\�?1�%Ec>���K����f��-�r�M�5�&�g�(���^c��~m&kkω*]�vM�q��9�
�΁c]#��bd�p�fU>;Lw����;~ZK��^��~mH��[�Zo,��<Ju��.����7��hQ�*��҉HsHE�o�jcٵ�f�7�>����/!.G��O��)P��Դ�}A�-���Q7/�/6G��4Ǯ�^�Y9i< ���q
�
0��x��X�];XG�k�fd8�#\"�Xb�P�^���2��B�%g�BPTtL/���O=@O)}e*G²G��\ҭ	.�~��I�̊��O�봰��<U���(U���ߐ`y�X
1�����E�K/��N�|ʝD�H�Ȕ��go��l��`�tܭ��E�6@y�	������x`K;�����$qH9�8������p$�|��?��z����}@��=�tP��}&>O�b⏥ b�57��]�� �s����J�1�*�G�W�|��p�C6f������Es��X?r�ѰQ|����Y�3���(� Ʀ����KH�� `;�ʇ�1TN��m����..|�,�3�"R׼�<�O��4���~r�{7<���K��/n��J�#�+�c�Hٛ�7D�?�4]�*�u��6�4L� �R�x�/.�ӝ�*{m^[�b�
�(a#!Mak`gq�3>�:Z�(��j`�ET�) ��ۏ[k?�A���H�C�� 3�A�t���&�k��(�Lf��e}B�[��A)���4�EV}{�y&�ޖr��9-L�,�Ec�#��ÝJ���pB��N1�~�?��,���%�t�pn������á���ݐ�q�<�1fF1�/I_��sx̔�����Er�L|k��b���Ԓ�/�=�pr�����.�@�k�偹b��!��1�������ȴ���8�.\V$�t��� W��IԞ�~�Da��[��C	�RQJ�l
�� �{�E\���˺�*��b>�p����G���^a.	L���7\�=��v�p��y�߳�wwQ�� q/�~���?���/�R�d@,�.�ڕUA�+<�� ���'.[k#2����!ZDO�����?0��U9ޯ�9�1�HW@��uX{"��h�V�P�?Q.u�`�c����fmx���h�t�]"Œ;Tm��O�ߚ'����e�r�,�$�`�-#�M7��Fl��x�� Bf��݁W�ye�&ꁙƲ Ə$�j��î��6i���,���=G56�l�Wjz�����!�Tk�i�/�M����e^Dr����w��@�
Bx��0W�m41��	Z4/=O�����cl�t��dJ�3%�z&v��4;s�BV;���hm1�����^��/T�O�8y�+"e[�x3֨�P�1Y����8h3�BY02���kc�n���d\F�uv4#�!B��]�Q��;�'I�����P2�=2�� +`�Q�:�j�k����tpz�& w?��p�vXqh��e���^� {��}��Pn0w9G�%��7אk��v���}�&����r��f�����<�x��5�"(+vɢQ�
����9;ə����'g�CF�Le���h%(�LCQ�ȉ&�@�G�]*q�޳:�Z*�4��7oZ.���
v*!J�ē0s{Z��XY3�����3Z`v8���VØ(��׼�;,�!�^A��V_a�'�I �+�M~�>�0;:�-��7�`����Ks	p�A�E�+�~��z1�k�y��L��k��*i�q��_���Fy( y�v@?��%u�UjR�9(� ���'Ʃ�>$9�o�ۣ/��2��ˮC���`8r��t#��O#�F/色���/�ѿUW��ށ$��KD����O6�zg���[t��_�k-�G����4@������������f��y����r5^LCF�[�����i�=�km_+�f̂>�4h�F��~�$�l7��7��h�K����D �sP m�	!�ƝA�'ZK�
���g8��j��E�p���z��?�X���،g=�1m2Ti��y\�B1��K^��V����N��X�Ǖ#3/�&BO��G�A~�Mc��>��s��z�J��j���r��5�b��h]�� U�6>�2��#���%�Cßm8Ԯ�5���rtk :�Z�G��ZM=����ƴ�5�k�r��!K�<�]ǁgiVܺO�*g�B �kr�<��z����+K�:�>�c��[O7fL��fdn��
D��h��p����z����f����Z����v���SV����y"�d\RG,�[��0���a�2QؿU��+o��p��� �{�PI�|��(tQ�a���zsr�� �m��V+��'�^;���S��wbH��㶾��%������]�P�@���ԕ?oI��y�	��k��օധ(*3���Z�H��V��Dl���:�.P%�B42.��X�d���rT������cu��W��v�1�y� 8�TE��Ŵ,�, ����{�b���x�-�~��x��U%��h5��+����h[%���ޕN���b��!��Ι�.��m]�HL���P҃��M|�g�p��V)x������p�5U&����?��y�E�γ�)��\Yy��+ܒ� l�h�!������g�)p>�Z�x��s�����6{��
2� 2y��غ�H�nJ��Qe����&5 D`�����Ì�"R�0��8 ]Ed1W[$Q	��Li�6x9�J�p���om/�z�V6W�g�v�P��s��g�$p���K��.�o��z���} ��<�;�>�f�\��q1�p3��6RtҌ(Ҟ�Ig�H�<Iќ�6H���v�B�2�2���UO89���{['چ��S'&�,�~~�}�/�������e���Cg'S�7����+8k�j�
�K�Zen|�۬I����=�Wy �E����0����i�4|��>�HU@��R\09.�κ�>ڒ�n��x�o���}����$}�F:}-���<� p;@�$&<��7e��������/M:��ٓ��vRt4�
�̋a2׵n�2ӑ��$��Ҝ�b����b��뢶 U�����(;�N�j��j����b��M\%�%���Z3�r�� r����ׇ�I��)0�P#��k�s�Ch��4���#���6�7�wA;���m��Q��e�]\�$JL� U�b9�`3�-��4�?�����P�P/4W��R���z���8J; 7_�%g��x{�c㣉$֙*�2�vf�e(�Jc�x\C?{�J���x��a.j��¶e<�����o�����Q�4W>I9���c�J��u�cf
�/�5�Ê:��m�I7�� p�[���\X�4Aۗ}�I��9�pq�l�:4��~���ٷf������̓ç�mmV��B���?�nD�*~ �<�Y��2�K�7j���xU���`��X��g��������S��r�O����siZ��^R�aًצ�!�wVn)���o!�
���x��.H�O����B4'>Qj؛jx��h�F Bg3�*��g�cc�M�"�%8>I�E�3̹eݦ_���+�}dH�1Tcj�Y&����O�n��C "}�ˡ�����_k~���A�d� �:�Aw��Ҹ�԰�5�s>tn~����Ќ��J�
�5�9V�I6�[L�){��"d�?���Y5$��?�}�R���Lu�Qß!�ë.��Kbu�zs��k༗'\ �ʿ�ȧ�A��۔,��� [Y�Vߨ!%E���?���gC�2�����G)����t�-��w�P�U6{��y��¤�,�Np�q5�U0��@��zd��|�������I�A�g�w�!x�H M~��) B�k�˓���4��'.����S���q��z���LΔ3��ݜ'��j���=|;61l��%_h��������R��1�|r��v�#���s1*.h���hǻx!vv���BL�᱈��4������^�K\���Q�����v���ĖF���*1�e�Q�|.
B^��vb��t_�q��4[�<���@=8�Li3.�!I�����r��?� a�;%N9�1b�9T�e��U�30�E�>����iΚ%f�4T�+�eЖT��V£ή��J	C�2u�ĭ�s��uY{V��ƛp��>;�,P��P]6,�Q{������=w���.�AA4�p�m� ��Qz�8ޥ����RD�J�1��j�LE��I���w_o_(���#���iA�H72�1��m�B։Y#�Dl�ӈ����uc����an����V����zK�L�����9�:A�|��$"!�z��ɦ�i�����r�I܇+�]���S��-鳰C���a�U�5򊐯����[!K�Ve��� �I1�9]����P�����ϼ)0���F2R�E	�~S�<������|�2��I3�!l{�@@�6��-��71l� ���4�X
س���`ގr�5�Kѷ.��}���F�.9������|_C�A����ׯgR�O��R�	[%m���	]������$J��Ua��<Q��r�?։�1u�Ha���#b'ӗ�Ram�:�ko{��������[2&���EFu���Em�����ޭqa_�qi`�Ë�{;%ƾ�(�⍍}��y��`σ�K?�7��<��{��<u�SVP;d�א&�)�8��[�dH�F��D�
k�l4B����*L�dp���)�P_am��n��1n.�R��_�������F��B_϶����c�D��\�[nS��~��|c�	�02�!��"FI��ql��o�y�8�6Ip�H��Y��rf��k�_1梿G�^�tw'�=�9��HAs��^����3�Ylƪr��x�:�	��ړp�V�iM���I�1�V3��{0�������L^c��JL�ɂ�?���x��/��˖7�7�`R)�I.,�vb���\�oS�$S�gq��扙4��~��!��q�y���b�^����6	�e�[��N�6.;��.�@e�UZ���M	�C��9��CG�ϗgɢ�7�ʩ�P��ƥ/�D�����0�S����m�h����^���;�l�S����X��l�=��8����A��mB��(>����O� t!{@ �����*�!(�D)Cs�ݞ�.�Ȣ�Fk��-ὀ�Ma�v�o"��r�����jx��r5�V;���Z�(j���[��1��Fo\�EZok��<��ϴ�����ĉif�g*���dP~�����U�J�����s
}[$�.�F�����8��R�f����t�=��)��]�F�B)�i4.����y����6u�hn�At��LJ,���H�*O�7B���3�}E�N�u<�� ��~p�\��K�j/�7���el��q��P���y�Z�&�MT�*���nGI�f9�{r��oV6pb��Pm�ȓ�kp�헂����G�^
��	���`)�%z�,O1�*gIi�H����[���3x&O̦�.˵���LƳK2EЮ4��f/��rs$l	�tk'�|��n�`+?������.(���&R��j�����FՓ�F�<r,�(��%��m4���}L8{�q�/e��B�ȿĲ�^��Hsp*�1-#�x#�0�"�<;�<�o�H����ةs#��ʥ_�xTe9�@�=�8�{w4`��@��QE�<��i[����G��䈵�0D痗!��٦�1T����� ��� ָ�\^4b��TW�~\��q4���&ԇ]��^�p_���Х�갔+2�J�d/���w,m|�JF|��@�u ���Š�tD�<|�1џ|������+؟݄0�ͬэ���ꏆ����>Os�<�� �H<W��H+N��D-��rVx`F��G�w�Upˆ��o��MQGu/�`���/(c{�d��;��zX�����������al�Vȃ A�Kкw��9bXF7�+f	Cb��	XQ_w���w�l�?W[,!�O�z�۴�Hiމ�4j.�V�6���H�0�KkC#Fw&#�IK����Y]���h�O����g-�b��ʭ̰	�gP�w��(�Z4�>�^��6�/.s��B!��9�:���#B�.W�[��[e�X"��"t	����/��y�l��l�,*��eU��1��ʫ��g��E�;g}ϋ�ʔ��g����� ��A��[�Ōк��Pz�F/�E�'gD���|2#I���fw-ߖ���
����k H>u�(�����DK�TS�lD�s�!R���vY�,���#������afz�lW�2�x! ���d��T�Ӕ��v���V�u��I��D� �D|:A�Us�??@b�� )z�}�s��^<�̙�~�N��YV:���]��LQޥ(�x��%'����&�6�z�R4a�t��M,ɣޖ��iԿ:��uq��5\�)�ڎj�R����Q�\2��S��lI�׉�
��|کx˖\SP�����R���}�xr��?l�{��g�%�3��1�^l��
��$�lA�:v�ƨ�G��a��b�����Ǐ&7d��JJd�����0�,Yj~b&�>pHR�w�&ʢ�q�����EN��:L���l���h�����ɰ4�!3���m�mv�mP�P�g7�G�?�G@Ӏ4 �.w�xɣ�F�AH2���/��y�B��U7���m� m&W6��B�8��t�B0|��b�@���JE�$�^��W_N!L7��T8�m�������G|�-���?��Z��U�я)65�V���.���w�(�+^w�l���"����+�a���f�~�%�(E�����]&`8周������)��Y�n�.�+�:C���S�˙�CeG����~|P<�N��]xC|�j�ֱN���e����i�<K���h�nKZp@Ѐp�Ư9r�����iK<�6|�y{&���w�!xk?XH6���N��8l�����J��&��q�'^��!���kJ�&���&9ȫKR�:b�es��u�IFQ
}�a2cҳ�[��CI2����;�6t{s�I���UcQB-��םPN�)��؂�$({Z"����$�3~|E���}̍�Q?�j�u���h��Q7y����K�=��R%v��xjG���0�6l�nx?��WZ�`��xt8����T���@z�W�ŗ��h&���������]U���<Q�<C�f�O��^��Q�3Z]�b�[��ۆ�L?pW����t�y֪��R#x�(�;ϐ�H�铅�w-��R8uo`���o_,*D�(��3�b艱�X��2�8��B��Lg��[]4�d�f='������sلM,�fz��	��+�uJ���^o0�K�]F��x����]?��C,m���'ʙߩ=y�01UރH?���p�R�Wh^+V�!�����}Q�QF���nI�B��A��������=��҇ߓ�YD��Fo�BF�r��:����]���52�؇�i�~8���jx�؊c���1�.������z�Ɵ�L"t� 8UI\el�4�8�gZ����&i�R��wO%rʄݔIi_U%(�ѕ.��$ e���4�+����y4)]Sc���V�	�/q�&��Q!GA̧;/� >u{��5����yp/���?Z��~�#���}�T{GyגOV�V��æ�)<��x��&l�yu��z6�4gL/�Qܾ'T5�ѭ<�3>����>�e%6#�-@c� ���3�� ������I]��g�    YZ