#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1558297302"
MD5="0b81472c6d82fb5c129148952124c0cf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26004"
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
	echo Date of packaging: Tue Jan 25 21:10:04 -03 2022
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
�7zXZ  �ִF !   �X���eT] �}��1Dd]����P�t�F�"y/j�g:�u��&B��Q���Û�8�2��������-~�1�^���wt�D�Λ�v?���L��o<s�S�P����U�V�0o;�
;!q>n�*1)�xMx	��T�F~�R]ҏvĶ\�i���_��Z]��+�LC��%p@��N��˄�� �*m�x*?������T�����9o����K�j�����0���N��1/L�rf���q��x�˝���s�}��;Oq����I��9�@˟)ө��rr���Q-ez\�Г��*3�^)x��>p��޳��;y�S1u2.h�����`�`TI%�,b��N�8��R������M���`"�w�c��G��u�ְ,�?;;���nn��6�Y��iQG�q����o����1ۻNμ�z� &A��Ώ2e�8��탼�c
���c�.3�}����áe��/JtB��2�����h�0㉆,i:q�R�*��p�����^}�~G1��<�	��F�7�Z�:D/5�e���qVEf��m�Z�S����uu�ԑڻ��8L�����G�	�Z�T�ۃ��##���I�Ň���&�b72�9t��B��B��Q��!�iA��h�Ő������$(�NY�+ǍLd���T݉�5�v�=��s�t8��3#�Yx��9mnYj�1Z���y�\TF�h�Bc}���б��	�E��F�z���U��?�p��	b_���_T(�9Pߖ���fii��!���&��r=�tb���m|n36�)�G1Y�#�th�8�SYq�Dp�YlX��)f]%P���C�QD۬��ãU�('����μɢ��\I� c�2���D��_�[Ł7)�����g�"m(�RNT�)Μ����ώ�;���c���3�0��T�>e��;RNw=+�K?����lx-�5�l���i���~g�Q��?����W^b��KuO��Ǒۼ�j˓��<C�4)Yz�/�o����w[�����	z�5��4�gkO���߲z�d����vu����n�U%�D!��4�G����m����V�[�綴����~�u��eӝue�J��_�ʣ,�����$�e�)�y㷗�pA֫	�MC%&�p����-H�#��[%�v��֨O��t��]���B�y��g� �����1������Cӣ{V��[q����q�A�����^�D/��6K.��*_$WqG���n.�l�wo�} �a�jR�KWP�Y�(@�&ga�C�=V���1��Pw��%EL�)�zS�b����W:u	�.1~�T@ۣ/�4�ڼ�kht���*(�zX�C'%�1�&)�͒IM�w�WMq6ϯ@��Ŷ̹�}�gqdA�	�#.�lO'Ǭ` ��ny¹Lz�ǚ�7�����V0�mC׿c_U9��ՠ��HJ��-9���ӡ� �>mlA�{jg[�m;�]W�٪Jǽ�K��(�=�X	M��L-
հ*��Jns�Eh,�����1����1�w���:`ܩ��g�vR`&���)[��eoq*�4���"���0�U~@�Vف�/=]���C���~����:E��ȷ���I4%��%e\�����}�� ���9����	���$%�԰\��fӂ�K�,voQ+��蟁�����$��'����D�}�o�mQ���D|���%hR/̕����16��)���ب��R�W�"c����><`YoZ���f_ '*G���u3%V<m�mڸ)e�g`Y�� ��ÓAD-W�)�,�񹰇@��$ �%+tH�o[�S�	�˂n��h�S�8s��l�(v��&=<��t�w��%�	Bu��c�H����^�h`���Z~��ʲ\��	�����ލ�*�_6zĉ�:{�yu_����vS��҈�^� ��E<I���xW^G�um�[s�����M���R}Ġ��l�je<�B��t"��f�Nu����׍��Iu��O��m��!~s��7����~�[^s�@h��������1d���ph~���Sc�ܪp]f��P[s��ʼd��6�/b�3�����ҩ���5�)�'Ah��_-�����.ΐŔ�*�t%���I�wxCr�B{c��o��bܩ
/琛�P�~D��.9�yHj�6�l�x�|^R�M������]`��f��\HM=l�f�=��cCWA���px�.y)zԋ��n���
�M�ܙZ-��������QZ�ɯ�(�����LWA���j�.�'���bL���2);���(ǆc�8��h!��J���ZI�����xe�(7
Mڳ-`��z/Ɯ��=���gX��L�}�L��(Z���y����7�s5������r>���= ՗�xEOP��9��y��}.CKB?3��Z�.�ǬO4-B;�jՆ��:��i5�P)�\�T�e�Ҳkd\�k9���J6w82ID1���3Ȑ�z�5�ΘEjRu.#����x�Ag�7!_���T�~7��\ [L��r��J����i���և�`�J���~�
���������^;�3�MC�:�%u����6�xS�[�����f������<w���W�z�̭r�w'U������e�ӵ}������y�=s� �3����m���e&��-�4�����ʭ��(>VA�����1����n���k����J��p^��>{B@���٪X��X_��?����0Q65Vh����C��o�����7�]~r�j�b�s-Q�r +XW���oq���Pi���j"����S�}��R�|�_�iQ���)��ѵ'5?'k��;̌�j�9k��	��D� &R��>�,b!��Uc��U��y��(��h��+��I͑��k�k�s�<�)�K{�����$�!��ǭ�>h'����%�u|�12^w�m	e�*��cc<kλC�<|$�)����=���C����*����G�G����{��7_����u�j
cɡ��D�iKu�|�t�/?�,��-��p��+�0�Z�B��{�R�r[L ��Jg4A�y��%��D���ƺQ{K3����+Š����T�F`�����!沉�V|;��p/�}m�N_�ry�&]��d�m���*c������|9* ���yx��ɚ�E�C�43G�e��#�vo�dZ�����dwz��
IA7�=K�w(J��<x߂�`��F%�"P�ߔ9����՗,������)�>�z{��ɝ��2���S`͇*b��5N*���]]���d��)�)�n6+L?r<SE9�D�8�8~��/%�}a6���1Z"~��!�}�a��w��'l�TuG�jV�ȪXXED��/�b	����~�[��f{�j|��.ۄo�}���>)^�����e��f�
��A���g�$� ���!3�8�)-6�z,i9X��MOm�F���SY.�l�r�v�O�E��U�0M=J瀂Lbc�1�,q�:̄0/z�������+��W6;�;�d� 6E��s(�y%�_���"7��r s��Q�t�
� w���H�
��ۀ/�^��Q�B�Tϣ���+X\�B���) Н�WUQ߉�)�A���ه�r
uzY�T|���{�f-��:y�/�N�3o%�I\�j�׎_s�1
��Q�|@����C��$L\}C�wM؁0�cM�r�,�է����(,Z��B>���G‐}5 �)�(I��Ǡȏ_��S]%@�U�l4޴m��	&ks�����iQ��r�C�ė+o�T�)�{��j��bk�����$&�7%@�O`���z'p� �>����"~����,}3����D��W�����GD���;�%����߇B�eK\�ugr��!�jT��'�'�՘f[��g�����O�71�m(��ˋ�E�"�)����R]�z�"%T�s�@�������&�D�1M�����u�x6y)E٦<?5��n9y+~�l�d�&�̨�;��K�g<�^y�A��Æ��74k�n���&	�a/�� �7*�b�+-&�)x��%d�[����[���RPC�t0o���]:$���u�����: I�)4�,��T��w94��S���?��/�{�_���`��O�O!�VB+,�y/��c�o"�=�rp�*�m�C�I�8�������R���|�¤��X'ؙ������XB��h+���K:x�.Gڱ	F�	:��߫��7f�^y?�O-�r�S��U����>�E���7��^�o��bY:T5�Ȱ� �)R��~XP��ef��({����^��u���&�QH!�Ns���!�4�"���©C^��08戰�^�͡��6��ۥ�Yִ�9�v1\�~��.1�&�*���]EQw��PR��u������
�'�(-)�[�����r/\ S;y�RQ�,X��)�>i�����EA��U��k{�]��h|�͔Eo��{��bn��Bs��N�UδxK?�7r�=��Q��o����F�"��^[M%l��x��%*���BS�2����}�_>ߌ�H��)MND:d�?��
;�=��M5�^6"uT6�5j�t ����"&�x(�Hb�	�G��Ȁ�������!�c�e�������j������e��{2�uJ�X��5,�磗Y<!���'��A�x�u��$wJ�nb�X��^l ?�l�������ħ*�=w���eQ�C�no�b��%�;
��bə+���7{;�KX�t`<����0�D�?a�|�vsBZ���l:�%���P"x�`�L����Yl&�|��i�a�ٟ���� �7	Ş�5���(����U��v�?(l�k>W��W���\��z�r��H������p�����2.�I�{���_m�h|�9��	�b��a�5=%#�}Vo�!���!�M��9�.w�C'l�� �/:��Bi++A�v���
29�&\�ʬM�����d��㖓��"�yGg����hJ:����.��~�%q^���:�@��V�A��%"rր�V�ˣ��n��y�+rD��������#��s��X�F��V��iוx'�h.Z{]w�0�� �Cg��
"�U��� f�ܩ����:n���߾R%��M׳��*ú���C������ȍ
ss�8�����f(9c���`B�u�7_Z�d�W�gq%*�7���0��GHFv��b�A��״�<��7,.ڰD�����<-�b��"�a���9�d�@W.u����Õ��B2��n�sf��}��)9+,����"���F�Q��9����S�Q���n��sH�+���K�.�U�ʛ�(�m"ۘS�����b/�Y�$��3]W�Y#_�!u�! �M>���UI�cE���,�����k��DK:)�j0��2�N7̲�<e!�{E�b�"�%ΐ�(�c�ػ
�l~8�� �&YPTd}%��T�!�K+��|�G�Sb��['z�=GZ�X����|�R����PV�d�rF�Ŧ�VX0
��������a��K.>gb�8����N�;B���U2"칙�'}���(���苈c}��T�/��d7�*]�OJً�=7gO�Z{y���D���R�;,&����I�|�f��&�r?迕�>�q���8N�|�L��?	����p�y~߲�:��n�$�W��O��ސ�`�b�,��X���ѹxQ��t��'H�G�+�`�
���<���l(��Z��YXu��( �,��ּ*� ݧ�玏�C���6��X,�F~�WI3��X�|��ȎwD���3���u�U��W�?�����g�p�?ɀ5��m6ۥL��rh<W5�H��e����!���6C{�Z��
�����=�a�BnÃ,���D�� ���j3�*����YM҅�Pr����x�K��y�+�!���U����=��A���Y��n���������R��Z�o@��A/�rG�N��޶��@@��>	/��*<�?���hJ��rnǡ�e� 8rG���ݚF�<����
��;/��q��A+J���O�v���^H�'?�C��i�Z���1�cB>��)M�����kL���o>��y��-��p���O��?@ŗ$~�Y�`bu��l��r0G����4V�|���y³�^\�d/-0Z%b���Z��l%ػ���9~���И�wiӂs���X��u��>�̠�h8��W�w�2��lހA�c�c�;���6�*�I��M=�YX�_���t/[wi��mHR�4�L-J�U��}�=Z�K�S��R���}�R�3m�� ���I+ @�����O>��%�L��*=1i(E{-iSB��r�cF* ,���F���+�x�n�������	V�8k�7�������ˋ=,���Q��������̥�����މ�3�W��oPK�֍scx"YXJҦ��UJ}1��e]�~����}ML�*R�O�ig~���^s�O�6%�C����� O^D�[H�N�fq���X����γf�0f!���k�6����@���˵��o猘}�+�W�w�H��qk���6�Uv��)C*$�t��i��C�O(V��'�'K�ԏ�d��C�7F�E��4	�`TAT 3��@�<��ɵ9[�t�E������@�Z�zp�X�������ľ$���&!�Կ�M�1F����1��z��:F�C��pE��*�� �"���#R���0�>xU�q�����e�"ݑ@X)�4V����~'�|`�6���I��3<��!�8���j��1]����m�����蒠��Ë�X����Dt�㛮t��4̳����:_�r�T��4y�W���wI��^?��e��B5�R#�ݦJZ���G���S�+�艔:��ڭO��fg]yD����q:rߺ�b�<�3^�OT���[{��-����1��T|��
> �Ɩv_*�q�����됟Ѫ�҈ed���cx�w˙A�6�n<�>1�֗]3$���:�����
c�kT�>a�M��J�� 5~�O]x/%��A1o�"gC0���������O�Oʓ��ҙg�(f.�Wk�o�,Y�6g�s!�-j3ܥԾ�� <�
�%���8��{�+f�l��"��VP��r���M�R(����FЈh9��p�u��kHy�� ��[���(�/��hH�g��5�E���N�TE%�kƗ9�4����l�F7@��L;o�zk��1��'��
�)�^Z���M��(&T$�Dg,�d��6w�Gk��������z	f駲}"g����v2�Sf�1��ryІ�r'��0���<�DNr�J���ӹ3~}���NZ=�l�\����|���&�WV�� �ZV\3���up�n%D�5O�)��;)��e�6n��>����,Aj9Z#0�}��M@�:X뎠�q"A���.����}n}��圼�0��#$w?�����7>�ekR�؊T�YG}���s^L��M�'������0#�ȡ�)v-�L�j���xX趑LÞ���|� g�K>��1�B���-��$2?us��>\�gUpp�S���J8�g�p� ���A�Hf�H��t�%ݢ��B�_\U����]]�V��J��w�!?���%_ȏV��HN�M;�6�k�kB��l߱Lq���FO�|�V��|���h,L�~w�QaU#L��G�4���jP��.����[q��ս3J�aTSF�Hb'%��v<B����^P	���>/>�~�}5��{R��Dq
��@��Y��6hZ�B��`�̟����7�D�����N�3�R��2| g�tm��\��K��]Z�����������|��ﮎ���1�
b��/As\F'�t���rKѮPq#_ �ir��#cm.9��5�ZԍG+�*�����`4��]@a��z���T���l�G���r�Y�&[��Xoq�x̖R��/J��q���$I;frryr4D��j&�T��c#����03��m���G�y�������i�����Q�ݛK���|�9�߻��o$v*��F���Ri�8k��d���k�%x7�OP��J�Z�%w�������6BK����G�&�-����Yf:�Ɠ]BW����W�r�_����@��CJJ�`4?��`~^�'�
T�	Rn�ȭ�C��Y6Z��{9��-��Y�C!Sџ���ĭ�[�F6wB��H`��!�?m�J���	��s=W��Q�j"�����'Q(��J��3��nw��2|#��:2����ܰ7��1#L��S4+�n��B]��~~�;��ۇJ�
lv�<��ܻݜ6��K~O�u�&Lk��:n'G���1m��-1~��\#�s`�n���e�1&�J��:;L�:E↷���C��5�gQ���~8��K�[s�0�]NT.P�A�_�R����A�y
ŘÐ�NrԲg���&��r+�V�Vt>�8�#�,�Cz^-�Y����*/Y���=�>:C-5UK*�^r�&�W�Z�P��]�t�
ƭ�X�4�	l�TQ�pk��A���� ^r�@ ��R*�˲���;�d	]��I����d[D)2��V�Z�r�g��+�9<h~�<�O
��9$��JiYɹ��յa?���8j1���l|��z���F�%���_Y�K�f���׈�^��-;K�{���}F��GW��pa���}��F�
7# ac�����K@x!�֥N���~xb4t_��I1��a����x��LŦWB��W�^&ϡ�ʻ�sУ�wN�	^��V����P����1`����p I��`	^]��!�Y�('�T$I�l$\�g�yw�y��"oX�A��틓f`mW5U\�Z7��'}�X��p�W��`����ĭ�g�/~Ñ~�]�<,�ʯtp6n�ڏ�mf�]����敺�)��w��	w�wn��X�ZO
G��(!��7����9I�!��TG�(?���*$�u�S��W�)g�t�౓��7��$�㠮%`W�_[n��Q K~�|}J�2���B'�%�B�Dxdܗ��X7�������*��Z�xAS	65�g��?=��"Ŷ��� �vh���4�˙�aF��~�K>b׺���M�q �F�}O�Ɨ��l�!������4J\�:�C�T��⼞�`5i+�(3�|����"�!��-�C,c.m�30��˕�*M=�L�0�6��N�/��R1>���B"����.h׶��^���,V������8�X�,�� ��)��e��jO2�F\��`��%U8��*7�-�Q����x%e��Qe]����?d��&�S����nS��/|\�+GF���F�UA�Z���*�����]�0�aȶ��!��=O\bb��k��GN褯���M��WOld���@�akCɖbtJ�b��m�5X�5�Y��B��0��	8����JhS�q��^�l)�f�XG{XG��I�A��2���[���2�?֏����7E76����l鮧��u�K�h����j�L��#5x˹1�pb��J��D�9v�Fݺ!(�u�JKg���c��ҭ�x蠞GZ�V��L��äd�S���HQ�Fd?�!ᆈ~�gZ=�0*<(TO>��������$��/��U��G߾+�/Q�Y�^.\|���p1���c���ͥy��:b&:�н�wrǒ�XpO����pV��͏e�Y���g���:�`�����Vꢸ�o��9A�?>a�U�aF4�!M���q��b�JW\z�{��|}�6��"U����`�T��&�(�H�O�)���:��ɪA\�~�Wm�zl�f\�M��t������u,L�ď��j
�݆Y����t_�U}5k_���]�p������$�{���;�ٓt�8k5�>���?���>���z�9��h7J\cTi�,6C���Rn�#%�u�T�!`D9�e��H���I*�����j�8���~�e��B*���n�hI	uOS���#I;ji�1��wd(�=̐E���I�2�۸即!����\����pU��\�z9�=
K���gȴ����h�p=����rB6^��ц�O8|�?�������wG;k1�XQ�8���k[��.�mp����iO|21���Ek��Xo!�W�U���
g�F/��z���f[�=�j4�@�H�@h~��$6eΐ�vU�젏x���xg��IN���k4.�5Hz��.�4(�4ŵ��;]���D��S����_������y3����!nck����<AF���_+u��c �1�VdČ%��+s!r��{""�ê�+�4pJbi�4Kv�SQ����1��=k]4����%j��nf�ɂ�%�ۉ����X��okg`�����ڭ��tm_S*��HV�>�n�҉�؞y�}�+ֳ��;�쳣�f�JP��Ёp�Q�ȁ�"R!P3�2���)��4�Dl_T�}�3L�)ڡ��z�������169&ø��'��Ǭ�mj���H�B�Þ8A�	��&E�g�ȴ�U��/�Vb��]�#�� ��^��4p�ڲd����+��ɏ ��r���t�,ʞzX���fDUOPX�quL��`Z��+��x_sL���e1��1W�J�bя^͋@a}#w��%�/{\[�5mO�͂�ݑ;�$=���\^5�0D\�`���������G�l  �S���	|�����L�t��x!-̹-��~C7�KH#�]����|Z+W�8 ?�j۔Du���KG�1�P��S���i��v�����9�-F �4�.]|xd��Ē\���pu��ם;G��@���`�nxP�P���g��7琫����������<w��}yNb{���4\դ�̀�� A5�u��X �hs�m�c�_I ��zꂆ�҃k�E���y��uw^T[�vt��]Vq��I�e�k��u�~d�`/�T�*C�������4�L>�ub̨�=������C>�%XX%m���.F�ʸ�O� wy ��G�w��̡ٱa��x�j0��,�zͦ�Y�Ȁ�yAf��[Ar�lM��*̀4;�\��a�L��N�7���Ģ"au�Ε������I�{�`Y&5�K�m������4�� z|}X:5���=NsS
�f�twh����q"��X��3�ӻ��o��}��T�(E`�9��<�êDS*������@����u=Ԑ��.E��N���c�=��Q��ެ�|&c�J��g��3U#�x|%����r�=�,FSi!�f��8��x�+E&����/<)�*�	���}a��(������*ٚ�'=�	��5Z�%|�Y�z��2���h6�W)AC� �j�@+"��R�iPV��y?����<bx�9�7��Wfv�5��5v�U�&�㖢,�`�/W 1�$�7�=�����6�}y�Ѩ�lf���9h��VJ�, ��w��E�AM�⯫����ƫ���ς5����mVꪩ�@�
��=��)����䢙P5�5�:��[G��$3Ys�޽�<�qZ�v��aRQ����6��}��=�5�H�,`p(^��G��!E,N7i9� iz�P��u�&!o��ȧ�AR��ö�-P�>�\�X%���oG��"9���#ѢL��
j�CI���O�]� � �LU�����u�+�m��/�	������<��ߟ��`��6�Euc�9���~�]p��v���Q�|\R�_��S܇��Is,%O��8QŘ��ZϿ�U�F�^b݃g2��T�#U����+������ж�K��p@����28?5X  ��cVp��rק�F�gf�"����N}83.����^�}�5��m0'����Ө�Oݡ�67����I��@ɍg9$���I�Ik�%9���rfZVtn�(V�UA\�g�\8g��g�o8cYFX�N ��l�,;l�>�l!��M�%��{�$�F���W<�8s�KT^3��+�ef��^���R��T�s���1�(�@����[�6��^e�����&��,�����&�	��{T��L!���eI�a��v^"�_�H�ao~�:����N�p���?e�R	zi�E�_�����7l2�Z��@���7.$.�M:���j�����&�+X|O5En�b�
��q�^�'w�ȳ�а�_�q��^a�r�Lі٪{b�֎R��X��K�}Y:�iCz�-���*��W
]��x�Z}H"념*�3m��qg/Xp�-�V���z3����0o{����KM*����fo%�P�h�q�-�������o��������g���ġzm��	4Pᩴ�T��@���S����x�ݚ�&p�֧��i��Q�b<�����a�1\��������G�=µ��P��ܼ��� �)[;b��B38ȔҕcH\���R�Ea�%9
��vVm��,��1�ѬQ߿ٛt��.�Ys�;$nw�9��-C0A�E������K�C
]��\���u6q���#���F��^��+�C��n����y7����m�0�z�v�����di"ꝶ^S�U�3)]��vG�dGZ3�t�ؓ.8�=�Ғ�8� @�+���UB��$H�� g�+�j��@��?$U�f�b4���a+�=�E&�[�k>H韣5���E�uI�AG��=L�Byzf�		$�VֿV�q�'�Qr��R����
o<gE�'���cYd/V5U��\�^7����x����������6-����Qi݌�I�{`�1��I31^\"�� �������5�XK�����u�"H��)nK"�ZBM��`͸r(�(^�Νo���[�̟�k%6wk�υㆻn�1\���D,�*���^%B�
���'	����Y玑njHɀk-��g'�X�q�����[k`D@�vg��Q}�I6�l���H����dP�6{�	��I}�(�}�0ϵ�q���B�yĈQ�S���3k	���B<�nW�в�6�K�|�.�K��nЀۺ �wʘ��V�c�ة:����S���Ʃ��j�cR�k�����������+�Ol�D
�MhX�q��� ��f6nzo���{���3�<u�M�r�L�%0.nt��VIZ�3r>��E[@Ɏ&\A:�$ᒲ&���hC�=�\�x��*�"!w�9���ɢ�Y�V,�WU�O+�}�������KN-���Sl�K�"`�����V�&GK"x0;�S˨=�؎�ߢ�����1%@Ҷ�b Yf��ٮvF�FO
�z��E��>D�m)�EQ�~Yg�w��x��GU���lUØ|`V�oY�G��w<d/ڼW!!7�n��3r�[gC��XSG2d�|�I(=-Ԝ�A�Ҡ�"��ͯ�i���ۘ���J�C�w��W5�!� I�ߎ��Y�M�� ����;qG��ԙey��g[���Wк�5�����i���ZS��uz7���6u��"���B��.օͪ��xt����Z~���F�H�i���� "�wy�dIYp��`�̢H�B��^2�򇢵��.B����+s\i[����v.�D5�(�ūw��;s1B�y�D���$��n�Z/ʨ7� ��kI�F��������=��H��'�pѬP�t}�{��]�cZ��KҺG��1ޜ@&��_P�����2t�ⱸf����B�7|�WNP��+D���+ދ�,���0��_.�(a�Jrh�=��,>��H��nA�f:@��(�0P�/�wu�q99�rmM�����I2ƑKO�����۠���4��Y����I{�%�
Y4K.9
]?�{R�T;�� 皮-����n�T͙~{X���z�n��_l1�3���%�µ	"Ľ�4�Wq�bK��e�9�Y�p�>���_YS��.D�,c�n�Ύ$yΫ6bg���4�����̭���g�3��� Cg�;Sˬld�6�W4[��T�s�0����*'�7:�p��I�sη�K$M�ft�݀BB� ��S.#�S:ǚ��}�l3N�ٲP =�\����I7\���xP���CPTI��Cs)�D��������\�~YMo����א	��JoKb��|�9D�F��;a���A5p(D���&k7��#�hjK�����B�+���N�ٯW/�sf�� �� �J��Q���9�a�K2}r��mC;��)˥��r�5L�8��)z�B��dr���*։�]��=���>�5����gc�hW��^QHR����9�n+�kJӌ�
��c�ˆ/�i�(Ri�B���+}���V������σ��!��c�%%J%�*�h�T��\󅝲���恈T�K�H��oO��L<3���J~@��WO�?��q,��3D�7�AikvK���(�5�<^uM���úf���ڝ9ߩ�3�d>L��)�_�c����ń���Ug2����q���g�·t�s��F�j�Ӥ�[ʧt��ֱ���6��U��T�u�*��؂m4��
��Z���`4'���u{#�"��g���	�(��g���G���ASA�/N�3?�����q(�������W�H�������������S����i- �q��Σ���5�=��r�U�7��Y�4X|k۶g���\,52�Ɓ���v���8R	$1����	��5�����3.�Y���oW��n�6�h0��#K?*耍iE>���{]W%h`���e����:��6&��W�M+N�����i5�=��6P�Ijw�6r�u�j2]+�����B�F���j�`�:��?�y�ݭ�|�8f9TCX���u�-I��-�]�w�q$�g��Cwl�r�J�!"��J$sG�-� ���L�֡��[clR��ɪ@��HĢ��o"�yT��3��g�u�*R�����(��A���'�o��� �پ�L@�֐7�����0n/�%]+�{6w tc �X��UV4Շ�a�韏�J���̞~��s���ĀRᔤ9C��$T�!���QD5O�{RƹH��x�]Y�T8aT����w�u*SY���Ю��2��_uϹ��;P��8`����Z%�<@`-t�t�%��TY�Iߍ/̙7s#̗NC�05� �Z���B��Q`K���6�e�a�@�'Z$���w������q�`M?Z,÷�W>�4��2gXwіb����2��'��y����1Ch;gGW%=7��2T^�d�f�̆Sʧ���b/�ug�/�E�Ͻ4�J#щ��ʷzq@��E+��|����B}�OI��7�'��I��ȑ� �W���E����`�&�f��nDް��x��8Q�j@5��Z��]���\�Ҙ&AD
������q�f^S��@�E\y)��@0��v�	�ǲNM�_�lf\.���tz{����A�	7@l
�����+k���~}� �+R�����$K�}��Z�h�h���!M�|�+D
��r�aP��Lb�����������I*�Oȁ+1��������Y�y�b�Pi�ť6شT�TR~�bBL�>a~���e�1D�6��j$����o���-'��V�E!/�H
/����7�B�4X�����d;�S~%|���B.�����VCW�lޏ��f ��Ż���NK�.t�߯D��;�_��AJ��/���ópB���՜|�(�[�C��j������(�' ��UMu``Wt!Fi�O&�xl���,6�(Oun����
3�8��˕�fK�?>��V�����F|�?�ӡ��PnL��)�⏘y� db��J=�_��G���L)1s�ܔuX�p�4�>p�u��:�4	^\�B��	����l�p�K\�:�㹐\�)yy�V�ԀYM�Sێ�"��I��Y�Z aQ��.� [��N V1W����)4�Կ����"�7!6���-�B���`Ӊ,��W�_
�R}MT�4� QX.�S�p��Sth`eͯ�|���[p�s�b����0�@Ƙb��'��D�6��Z�x�Ҏ�G������)@2�q�����E�ſ�	+c����=��Ct*�:@��i�$[b������;��5�F��sl�f�WiX�Y���G󫄊6ث�OI\s�^؊^4�]�|��07��R?v[4�����s�����1����t>�_�LF�:^������/PDTG�x���6�Bz-Z2��#�Io1l�;~�tLT���z&W��$#W��:�l�A�����ф+$�K�������7�l�����Z���}���������?�|#}�>���S���Ӛ��4�� ��8�q��R�3j�T���x�׷�9�m��2��#ge��p$�(�8i<�R����ң�r�H϶�X���X�����d�H�7��kz�u���O�bb��Y5�2����P�?��V%QsGT0N�ږb
-I�l�FK��裇0[�d�U,�Y�V�pAY��tQɺ������nW��У�B���| U�)�"]���cם;�ց���ܫ�s���`�O��l�9��HT?A�r�1e���Oc��)i�R�=
��) ��9�5�3���γ�F��}�i��n�u6�m`&���Qr�� ��r�͙�`\|n�������?y���ۤ�x�O���y�L��@��1�o��-�7e�D�{�H�Hk�I�Y�:�Zӹ&t�d�����%�N8}a@�O	c/��Q��F�ؓ��W!�Q�JF9M=���nF�=��b$�����֬(׷
�c��-�`�^�X����^�o�E4jN�%����.8K�&k�aӡE���{��A�A�l�[��HOH�ǩ`�)]X@���4A�x����%��S�eRV���a�|���Q���8݌~f���4�a��4�+ꃔ|�d�����OCF��8��^j�iqe��1������[YD�~e;U��b��Q�0htVg�.Y�8��͜��p��� �@�Z�
�v"�o�9������k�Y�,�A�@n ��9�^B<T@��!il�Cӆ����VIx؞���jǑ�ڡ ����<زhorZ\l��	�`l���;�
�U�CM�Q��>��M[d!���GaX� q�X��p7�\�4��� ����͋��[0�� 2�E�^���+2��{����
�3g�Y�y��!�5*�|��&�޺2���ޓ��Tu�(�z#d�Z��J��:S�r�箶�� #��S��o䤄CL�H3�M%T,����/:�p鏶�����L,��&o�9,��������*����� ��A�lm]H����*������c�^�Rg�]6�+=���9r(Ow�p�b����'�����LwKG֟:X:#)�!�1R�*C%$���äe���ȥ�#�E����0 4MM��U.u�d�����
��`+�J�dF~Vg����ޘ[4�%��]Q�J�J N��nfO�y��|��I�D�a�T}N�Ur���rX�5Y�'�����f����3������k���O__��He�(��F��M��L(�\�p�	������Me"T"��ulc���H�i��]T%��1�x�}o; ��b�rE�J�U��W�6,(�ogsD��m{g~��:�0hU�oڣ��)�!F���v^��*؅��$h�Q�e�;W�d¨Wrp�W��Ǘ,k�x�e5�Q̻^�1Ou�1��x���Rv\�V�sV~76?mp�Y�o�+$��e�q��"�{��8���J�f|��B�O��H.�EO1�Ĕ'ؙ��2�x�1R!���k��Je�����7��gݱ�|���S[��D��CIf-�^n���������tWP�i,ɴYæ¶��h��}�W���z����]��.~��vC�������d+�͹��^��d �m���x�;��V�e�g|"�gl왤q��Y�Ѯ�_ki�?�͡��Y�?�O�_�U:�<��-��(���U�K
p�~�����\��*��2������d�-��M|M�gR[�K"s=z缟�������uF��ֲ��YA'e��Nx'r�������� F	�,���湅z�,�+��,�Bd�MU}kg���5��/�7V���O�0����:TL��:/' ���-����<�n�>�m�f��% 8&5ⱡ��t�l6(?J]�&�s�ǖ�\All���Z	�4�s/\��T6�fK��b��6p
�k[|Jz��v���
 �[C���lHX�`[5�}3�����i�}ɡ��*�n�1]����3ck�I�Ս���"��dCt�=��ٹ��[�CK�d���1� �)3z��#1��~%��|L��y?uQ���z^�r�0��!<��/ܨ��q�m��E��,¯���g�"Sֻ����N�K7�?c%-� ��}B��	5n��&�tg�O�C+��;]HQ��� �ҥe���k�qd�Z�[<�A���^�g�o��^|�Iԅ�m?�	�*`O��5�&�����7
�8�>Z��m�⺩��Tٺ��u`����$�b^'T���r[�ݩ�ʵ��M�Z*;�Dy4<v�7�?A���ڝE��/a� �!0��P!��%���]�t|R�M=�^�-��1����BC-6/�c-���Ze�m�5; e����ì�j�@Q��"Bk{������Y�i��B��b[�Ȁ�6#�2m+�߄�/8��y�4/�v�E�	��P�>�/6N#��Ҋ >�Pr��1�X4,��=>c�i����5T��M(ҏ�jA���&�p�]����g�aޱ	B/re�=n��B��$���. ��}�Af���	)�/� �W���Cl�����N���&��Ү� m�H��p�_	0!Jv�ǯ�pMX�c3;?���ɆN�7G �:�о2�(�~�^T!杚{���xx�� �ތ����0�kËP��	����������w���Hڄ��h0�}&mB�U��W���?�Ys�����{l4��S�&�,�����ۀ���A����K���[��P�z�D~�b�lh  ���Nc5�f3(X"<A�ܓ����Z���{�Q����3�+FS�z�v\��ނb~�b��pP�,  eBdY�n��M*i�@U�����[���>�bJ�t��W�][�l���������,l�1��i�.��0��?'�S�!��B{���޷�(�e
Yg���������'l�J�X��N8l�U��
��{�ӬGۤ��g�%�Y�O�`!E%&�
F��2�'�:�p�[�F���§�zf�{��_�a�	�D���p�{U����$[3!LFa8�\�)���%}�`k���hBL��yՁ7ZQQqո�.{O�A?;A�Ix���A6�ˇ �����ڝ�An�GGy�!Yy#:����u/H��l��V�/0 -8�!����`��n@��}���]�fv9T��Jo�;���#�������{7��00��N��ޘk��J�Ie��ݼً.LZ��]���o���X�a�"<V���z���֧�}��I�E`tpb�c ����x�ʽ$	q���g�s�i[�@�1Qa��=�bK$eI2�:a�F�SX�4G�-@�jޕ���������uBғ�7>���`oi&T*�sleam�h�E6i�6g�1x�caތ\�<���\l��%!�8~��?���P�y����:�T�ֱ8h�8�:+��"��������R��[����؞���YU��\M�B4.���'��X��ۢ���T��/�Z�����E%3�BHxc�6sw�=q<�i)&Pgj�ID%�}�#�c_\ek����\S�kW�%��\��#
g����wd�ͯ��L���6�/^#�Yq���7_���X�i���s���sw�wo�;��:
��>�Q���H�i���.ߍ99n�?�4ܾ�%^���d���-X	W�;K��O���q�����݉����|%_U���?�~)e�C���	fm2�/�y��aƯ׊����0��5�j�F ���ș�C}��`�m{�޻���H�Ǜ!f�|� ]��g�6��1���*�P*�\0���'ާ�`�D3X�����V4��iK���x;��F��ǃ��/S@���i�$�J7� �4/��w��������~,��4���e��}�U�LG�����L��>��1?psBW�����zP2��(��Q)~ ��C#�'�-8K n0���[�etȺ���{1S�+�D]�鎶�p�K��O��-i+:���������s�����mb�5w�'���N�4d A�b?��s��h����ʝ<q H��q����D|q���t�w#��l�z෮a��_GY��V��\X�#����]\����F��+@cHң`�ˍɕژ��]��S���d%x=Fc׌�$fb�6�lZNg�~'�����C����Z�S��,K�2�z��aY���D�#�&��ά�5\ޞr� �3<P�V�����O���u��U�DbL�o��F ̈́p�	;�/g���`�������WR-W�����a�&�{e+�|mv9,�'P@�l�*D��(I�E��?yN��I75����_��\���zȨ.)^��A�/�t���x�����V-X�r���u38���[j贛�(��4��Q�ϡLX���]�{̺~�&;���y��*��qvE���M�^f`��?Ji�ʫ����&�ݡ�&?y|F����ϳQ	�}VשI�d���`_=�(t�Q�;���fQ��w��.�e*h�J��͑�U�#�;I���i%�[��G��I1�Ϋ#@U��K5j��k�(�H4�vO;n����m�U��Lۧ����I� ��1tC��#>(��3'+�:>� d�:��-�d����v�Ի�(��F��Ě����D���*���R��|B%ᒜ̉n����	�� �E��,�kg�z�-x��Ń�})��bXɂ��V#QC�Z^v�[߽�X�}�j�P~��A64�>�_u�[�� *���O�x��d=��]B���PA�n�=�܇��+9:3h����E]���m ���'�dI�Ɖ��	�lm�����.�u�D>�F�ld�P�ޚ��W������d�`�{���*Iu�j��D���-`�-�1����Qu�ܒ�,���z]򹛀���8.�:��;�f��dv|:�����n���1�:�q��3�E	��T�_��X�h��s=¤=.�p �B�0�Ƨ��=f�Կ��2�Ϡ/�����[��E�������Jf����a���&n��s$*@V4�:X%7�j�&='~^�(���Ip*$��^�t�$��%G�1���f��S�e�`��fP)k��L�]�<��K��Þ�^]uhy�š���=e�&�C�N]1�Ț�$^���� ���?��־�?C-��I����0��i�o)�Try)�f�5��%Y_�[H�����mՅ�E�Q�p"��͂����'_AYtW$���j7߅,}���~T�7��W(�M�2�n}���MC颣�5�;%���Mm��s&��ص�i����u�%��ƿ���2��ݭ:*���a*��w+�>�CD��q+Y17����g��P�1��*(�q���� �P���3��/���SB#]�a�,�5��<�f�8�Kn�OW�7�.�ՓP���#� ��%d {/�L>��)c��#�*�'��@��|�3�,j��Cw,G�mB�/Eas���"ӳWСs)�Sm���&��$뒘�z:� D���)�^�d���StU�Ô�Gߛ�0��o1�]��.֩?�S1��4�w�l��uL��)���X|иCŎj�ﴎ}�0���2 l*�%�'QT2��HSq����eMa�3T�L�Έ�o��?W?iL��e�2��~z��B����/����O�*������}��>GY�ޔ��B4������jAJ��q����QOLx�"����$����V��4�X;j��o�X7�sW��IӐga��1�[5�-���10����������/�T�s������!h@ˍ|1��b���*��ʗ/�{���)OZl��4�]�n�Rg���ё���M-��#n'1���m)�?���~QԽ,r;>�U�cS��	$I�&,\:�W�Juv%zR���hd��dI���u`B�T>��o��{I���=��p#�MÎD���@@�o)ML  ��jmY8��1�A"�Y虙����]��28fnTO�H��T����4>��w#�D�m}��#��A������S�zb�V!ӕ��fpU��c��[��+���s8Ӱ1��<�!qƁ�,��cl!�zl���U�Z$��k��1 �iܕ��BM=T����0�'��$;Ej����|�8	&�ֱ1�g�6�m����`�(���[�����O�����;@�ƨ+\r?oTU=GܷC��L���XVԘ��q�^�a.N��5C`��c�x�}C�d�&�M�������Ƀ8sX!���Ѣ��uWHDY�)2�-�1�1��ێ�s�X�����\וcx ���E���׃�#��ALAWȂ�=x��F�@�è�/��^h/�)$`�O�Pѓ�p������2}?��,��&`3���b({�sb��S�]��j�Hr�	ERZ�咬�h��C���B5���F��`4���!xj6��SSf����F70��9@���}!�b\O�y�a@�,�X�|G	�v҂��e���8������4)h�����`O�pj8�55�ع����#�a�D�[�{H�s���.��@8�>10T0P�D8�R��ː�gJ{R�P�������]~� ���N��x�ޚC�rt���c�
f}U�*S�];�K�t�$O2�U0pQ�/�����fJ�=�]�!�XL�0���@���bY0Xbx<��姵>��^Cv����qX�/�F�;k�+��U��*~�,G���lod�����y�C�|��1{�叓Ҋ��{Qb��3�{x�����C���K�(�K*���!���U�I���Sa�
Ճ��0���t�X��s����~�y���hC\��\�`+�$�K.j��@g�ڄ�\ѯ�Q����
͒H�hMV^-'�m����a +�K=v��y��p��޴�h��_+V�h�	���WS;gzY#���r�Q�Y�O�)1���+W����H�jB!�>ٹ��ЌC�Fp���n�u,jP���W�� ����z����r���]O�ӻ��kv�B<����3�>)�P+!������&�v���4YU��W[�d#���H�L۰� 6(�Q�.��%�9�<0x�+Y�V�o�Stę�"ɧ'����#\�`.t��G'hFÉ���Ba����4:����2v����نP[~�#&��P߶�i
�r`N�@A�6�}�B�"�T��$~�D@J��@۴�35wM���gN�.JM"�U�Z�֪OD*���5��q�T�^4�o��O[L�"�Kq�j�<��F�S@�@�c�`��Պ�����ﰅ[��(`Z���=��O!� ?�Lc�P�*�~�0�'�G�c�fO���S�9���x	:.��җ�?��ڇA�A��C�9s�z���c*]Ӑ����!twi�wh�k.!�����Cc^b�"�'p��)�� ����YJ�|��H�#��\"��N��˥�	h��§��Q5T�)��Cj� ���0�������J�H�� ��1]���}�W��e�a��i��� MDL�U+�h,�z:wW�(�c���2�Wz�m]t=�[xe3dj.��Rh\�w\�EP�`���;�!����6�V4�=>�z7��;��Ӕ� K�����*�U�~ma�ӋV���w��K��a�����{���?�u��0]>�)U�d��V�Ñ���.�ɦ�5;��|�����V��"��� e>|�{64�R�� �ԇ������~a�B1[y<\3�ǫN;X���J��w�'��:^MR�BU����x�)�x��rF�JLW�,ڷ���Npj�"0R�������1�P2�X���9�Z�ˢ����AXAORz�z��q�Ex���6'+Z�Њ���
LA��� ��r�I>��ߵ-:������#:���_�q�Pe��3�K�N��2J7#���� ��[�`{y�>�LA	󼚎LԤ��*+/h$f���6��2�l�E��͆��l3�Bku���C ��E�Q��P��d���
�}[�ߨ,���w6��+�8rnG��y��B\�G�JG7�n�Y�)�I�a�*�T<����U:�3/��$A�t3�u[	�m�1f�4��,��yV�d��p���u�	�m{�
�,5Y�Pz���b%�7ؼ0���U�!Fي �.z�'�}̭AVtć�@}{�`�9��4��T�f����h��_L�l�C��ɿ�o"H&�߿~�sO�~����H�ć�1��d�yE���J��@Hz&�ً�^���|���^}%�2"�P�kY�j1������%Q��'&�{��k�Ҭ!���xf��Џ����� �7yX����70Ss_uv4|F�3(��˸�ͷ�����W�:��
�$�zp>�5z���BWT	���4$�(n0�� �q4��7�ƚ�HQ�� 
A���d�zQ��.:�!	GUPYj52V����Э��.}�K�?ۊ�?�2�Z3�56=y�)s�����y�[�䨷d��_�����M��6*�U��M*h!A�9:}(�)rJ�@ ]��n�
��Ä������^b��xc��=7��B�)v�JZ'癲�jb8+3�	=ã�w���7�Ʒ���
Q!��>'���X>�?�)v.�{��� �wvC0�5�r-sWZ��j���S`�`[}�A,������Q�:Z �~=�RB(__�q���{��M�!B���tbA��ҫxG�8	�_�K<�(�ژ1C�MU�N_|�sh.·��\ �a�`������a�&���/pYMy�7_gV�\���ؔ�����|��rY�,#�_x#�\���$��]� ש�?�����'���x@d�$�&ޮ�y�+�Y⣀)�'>X⽌|%��L�,�U�R��K3�$��S�e�7�������R������Vʣ �A�Pƈ�k_��6�n�^��:J`<�
�Dv���Z�5���Tw
ܩ��`���ۄ�S���)�>��M�|e��!��
��Z��*b�+��Ľt2�!,b�e6K�Ƭ��-83Y ���>�,fje\�]��x�M kB��A����_/�B�_�َ�����tF�d�F�v����ОER�ʋC�;�u:��,�Gi�H����?9-Pn�h���!`.y�n��IDi�G������9~�e�74XW��|'�2�j��p�{F*�D�c�r�q�����+�f��;�h�ީ����F�SPt�f�)�݊�b�׮	�#���#$MC�FIy��Nd1?~�s�d�^��4>�}��2�iv������*s��F�S�Bu� U�xT�p�)�S���rD����0*�tT�J��Z��=}ަ��H�(��� ���,����܎�	穜���N ����T�� ����sCqS��g�    YZ