#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1889352688"
MD5="bc161dc1371ee608c97e8b768022a964"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23824"
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
	echo Date of packaging: Sun Sep 19 01:06:52 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D���:�y��"�L|�������p�ז8
�s�O�y��F/�������[��H4	rO����(^X���!~zR.�Gą�q;̀�p�}�\��|�/�3��;��֓�w�uzq�*��5��f��t)�o��C��f��ҎB�@M�S���+�!�e;@�1M����j^տ[��E4��A�`�,P12ptd��|�T)��^Ư҇�ni������Cn>�v����12q��!L�@|����=+�C�Z=��#5cv����ҺbT�x�v9�������ߌG(HY�-Qrb&҄�ڪ,�����c�ŏ�4���#�F	����p�%� s�f���Z�+�]���{��_X�cO"�T�b��.�R��fz�K�w�a�ל_[���1AO��]#���Ndy����wK�{���3�v�m���+)���������zL����.�">N*�xag#�ǝ�Rh-�c�&S��F2��4T�t�K�eV�i��a�bQ�$H���-㆑�4�=n��ǆ�n��
QL5�3v�g`���x��jb%�l�=>wǨ�!8���=���c�K!lXi6�3#�g����g[�u�V���׼4����Ս7�^�m����Mt�?kxR�s�Me+
��\INH���m:�*�E(BjQY7��Qi����%o��j?�?-{�z��~�4�WY�}Y���z쬤_V�zÆ=�Z`[�p'ۚ������x��j�4��J��s����s�>�mf�$��xf��C�#��.��ߥ�2<��?����������ќ��O���+�zS������ Ʈ�$j��	�Р�v~��x�q�F��n��Ъ�+}�O�	 fD�����J�l���1X*h�h*=��p ��\��j��:��>��@N���儭#�S�c�kwlmݛ�ˌ'o�yW~c>ר��	O)9amvA[V�����e�u��>�|ۜ 7�2�}����IN/]A*��3h$^�L�Y�)�/�� 4`
��ǆJɿ�S�eb*%!8X1D�S$��Id�,�����Sr�9!�7�E�A{F�֞4s��@X���=�����*%P�p�}$���w���d��Є��������8�]3����f����k��P�H��nf{*��Y�J����;o�8k���!�������gld����[~����6S[�
Lμ��$2�7&��JLSB�	��t�`"4�Ѹ��Vd�b5�*{��F��~	n��\��Wl��p�4<Ӣ�U��ec��W�̵C
�#jW)��Y��MLZ2�?J��E�1�	��EX����@�Yļo7�"vZXL9��8�"1^4�W�ܝ���S9�|L�ovЍ"�'�d�4y�&Ұ��U�eH����t�͘r���x�x�">���Y+���H���Τ?�U,`+�kqD���ePI*j���ۘ������D&�/b��/�� XmS�'��9�T�:W��ָ���*(��3C�L�� G�+��y��d�X��oOC�RB��[��4K��Bs�kM����N>ɋ[L{S��ĶS���Bk��S~��CT3+�ܚxР�Y�1�d�?+�f�ޢ~]����O���YK_oPZ��n��n�ͳ�c���OU������p�7��g�4�u�p�P��P�O��L"&{��VD��j&����ێ��>���+� �c���+MȢ���2l\J����
a�z�ψg�&O7�.e�˘�z�!�Y҂	X��NZ�:"�M�'"L�#�^�����C�A)Mg$�y���Kh����d��s�(.���q���!���1�w�0��=�'����{�d��/�:q�>�H�����l�\�a�|����������-Yu/}�e�$�S}$w�^{��bB�G.�q�9�,�Bl�x�]�Nt!�6Հ���q�Ŭ��M��%�WW�܄%f�#^�K) H(Q�t�����<oP�Fҧ�d���kY)�޶xժ�H���d9��6���מĶp;]3�a��8H!�x��_Lu����<:gZE(���gy���]e		�6����Կ>2��8ע���[j����ݩ�ۗt-x��~]@O��H2S[^���f2Qm�+e��D�u���[�As��&��B�=���p��tm$��f� "�e�-��BM���q�������m�L5��U��m{-�w?R��@�b�e5H"u�� �-?�FzF?���$�F)�4��A)�|�f��x4�|�%�ͻ#��%�|ٍ�i�~��l��®Q�hŤn|ΥCG��>�>!=+�b;r};9
�ܙ������x��3�Վ:�ټ��N���oqլ�_���0͚��"O��੠��T�	���HBK$��C.��8���b�pӸ�R9��ľ�����Ȫnzq#(ۄ����/o�����
������Y��a^����a����l�?�A��LmV|
:{���n���!Nm�D�[�	��3K�۹T��pT��蠘��@P~��\aG�tЀ+����P�#E�^F�	o]nE�%���˩���/~@S�%U|���˯L�E҇�1:l�z��n�����:w$ߧl���Y$�d��1u����hO���_�����GV�AP����x ����#MY�a S��H���Z�ߓ�
�}�#2/5�vr�9z@�Z�G�bO���Be��'Z���z�j_���,��b`/͇�%��gv�MMŏ&�-�j�+{T�E?�ن*����{u�<- �A��k��~����p$��(� �@	^�iTf1�_�9��� �K����	=]�p7�q�D����K�H��@
}�`[���I�6�U�3��;��@n�ّ��
�R%�K����܅��*��qW��;ЋOW�\,����1};������f�_�1(d3��I�4�ꨤ�k$^����r���Y����R���#~9�'�HJ�3���.qQ(�lR=�]C}�H�~�?|vB�t���Ǿ6YC^+S���S����$k� 0
�j�Ri7�������]kEe�������.1�C��8�;"�hg�ѹ�?��b�� ���c�r��+{��?8�K�(��]]��U�U�(�����u��EWW��e�c���I=x����n�:]���;0aP��l�팅��#[�";w��^���҃#:��� ��
6������R@f�� &ؒM$�+���W��O���f ��&���b���]y���a������L*�[���ˏ:30du4�C��-�pѶ�^�znظ��HJ����I��@J�@���F�1lW��}?&җ	�Mj	;����O ���^C[��Oϲ)�t���l�Ǯ�Ѷw�f��h/[�K�]G�D�لx\���b}[ﭗ^��
Ds@aL#�����#�?��T���%�o�;��3�Vei>����Y��a�Xhj��X��?��%�@P��{%�
���o�e2p�S-Q�'Q	2�(9y8�����mt=��uH�d>�q��y@�]��gP��	8��&��.|DM�G9�o�鴈������Lw#}^LJ0g#'�Hs%�2/�zw�Ң��wCT��Y��uW?��]�-����FW$mI�0�F�^���I ?� ߀@�R�b�G0{	=��}=%k����<�u��M�O�*X?z�¢1i������&ͪ<���#:���Ɉ�[я��:-���L;cI�O�!S�p\N^�����g.{�����$6r��3� �'.����̩طl:4n笶;�\>���FJ2�Zc�1�/�����wwGgv�i	���Q^�Awb�s�_,!=8m��U�4�f�b#��v��k����	�tǿr���]qӋ����&�sd�s�pQ���0�����f��T�������0��w�B�XڝB�2~�Xn��lcY�{$_YIc�䔿6��GK-I���ՃL��jڋ&��aC��Q&&�+2��D\aa���E�D��Y2��ռ��Ķ%��b����%T.��w
r��G�]�G�&7C���WP�����R�b���۞2�F
��&~;ˍk}=�lF���N�n�!5J�[�!�D�����)6��܈��Z���Z	�Ʃ��#S���?w�a��*�'s��D�չt����0�9L�F�PAUmE_��� �?:��yps�`�˾FG3f<���՞yU5����.V�X�Ҋ�kDDZ�,N]�h*bF�g��hY�xb���j����D|����>��X',���Epe'�U*Fm�>�|(+���i�z4��ơ�<Ƕʢ]i{�J��&���jc�L�g>�@�*�}��	"T�XIݒڪ�{v�[�*9+j����߼ަ�v���霊�P!�+f���C�x/���c�wz[}^�y�?(4A������S�%Q���m}1��\~�L�qo����I�>Ҝ�|��t��̒�b9v*�o�h�-�H/̄=A숁�K!�B�)1��I��>is?*�����c��TFۄ1
IaF���W��W���3�b����&5�b��#?��X����lZ����{��@��a���5
�? [/��c��m�(��d44tB��ߊD'|��4�&���r�읪ށ�/D�"z�m"��]%��^�G!�6��Q6��Z;'۶9�-�u����@3����u�;�̍�c��2�xA����+]鄍uo�A��_�x�ʲ:���E�lZ6Kz;��o��: ���?�A����{���L"��Q���Ѷ�/J�A����lWq =��m5
(U��`���F��b[٦��ޚG��.u���������57�Z�6�����QƄ��u��7�iϞK�ER�Dlh�e7�˥.d_7�����`�v?��&}P#U���vF՚�m*���)�op
ɘf�e�8�����Bʜ_߱-��0�G?A!��'K,�m�m����J�4�j��fa(q�E�����ܞ[�t��w9 ⵖ��<-��[Ϙ�UJ-!�Y_�U.��/��n��a�͓b�B�_BĪ2�z���|hC��`l�w�v�׀�x,�����o�<�q�g��]�J����`��J�+�o�b���נ�$\i�����Z[� ��Zk�vㆧ��l�4�3g>$>nf���g����J&CAn�ՄK��xHIRQ�|q��(�0��-���ddun�rdX�)�������\�ٔ�w����������O����[�{�*���ށ��Eo�%X��2U�G�jz�o>=:��4u�戨A�[I}��<P�L��gc�X1��M��<��6H����+{�_�n�A��B�Gy���A�!B�&���e�D�3�Y��E�2�uVw R��f�gd�!k�+������o2�1T�RR9�@��j2���S�ᡒ�=��� w�4[0���;k�a-����Z��`�/��o%)� f �kR˃vȊ2�����I���2��j&V7��)�qq��.i97H��a&!m�:�#6-m�C�s�os
P$�um���J�?���s]�ѣ�Z�xa�W�/�q�g%^昅C?<���p������\H�v��N~�M~��e�ݟ^��?��c�A�
y�ha�3^
lU��A���Y���6�X��F|f�	��Z2��ag�ol���&yg�X�x#�WA�Y��X��&7Ff��D(Ć�j^��/Ņ�%2�����n+/l 
Ɇ�o��x��.2k�������%���4��Τ�J�Lsȩ<eOF||��U������Rr�LPb�I�+��	T��Ы��m�%ǅ�+qɧ|IXw�LZ�`��@Y�NE':�d�,bPݼ_V��MUEd���J ���f�,��0\(��X���is�'Cj�c1S�s�����ۤ�3i-.�HS�W���	� )2d�,��AyXU���
4�'��I���M2I��Nϸ=�Z�d�'т<-��V�+���5>!
U�@���VX��@�ya�Ȳ��'4��N_���ǆ#�0��UPaRl�;��?�r��Q[�g�@{��ذ.�b�==���VT��g�3X�"�2�(Ds�_DU�������z�C�+��~���	Ӝ�r�P�f�~�Ãvы.w�����,xMD�Ǭ� �I�Jm�2L޷�ne����n?�#�Qs��ct�m!�e)\����t��%C&%Q�K�NF�ҳz��D�b�U�p�z��z�b����?������z��t������G���om��4�y�X ��ZgB��������r��J��S2Dh��68tYZvB��t_}��{7���[9^����,`��9��@kB�Q�x�1`�Y'76e�|�Pp@84��2CA�<,'v?�
��&*�`Le���x·?I�����OEz�6X�Ҙ���NuKTZہu�t`%�~�g��k�9	f�O������.��,��YKl@�j|��è.�2����^�`C�ZW�'x40��(* ��Q����NF�������W*���f[�r4[��~������<E^&t$�""�ܰ)#�:$�j��@��	Ⱦ�?VE��O��,1S�r�.�*���_0��1��� ���$�V39r񚙀��}K˃64|ֲB��G�~�i�nZ&�0h���tK��z���5�V)�ԫѣ�/�L<����e�zw`?b�M�Z����N3��̆��D���ZqVr>�!����-4�h��8��L�BL��]���1ʷ�Թ�M`�<�:�v����ǩmr�MF&TrO-	�"��QZͫ���y��U�;%�1=��1�b��~���y�������qh����k��=b�j{�\�;@��v��&��l��;$����A�\�ժ�496�o��p����|^q���(sA�GK��2e^%�YRhh����l"t�����կ14s��a���E�|�ÿ|���W|��T��qa�}pu�DQ<���M�җ��pьoށ"������Ļ�5��dR>��Z�v��$���,�_�bo�n�^T㙓۲�~fU0����}z�YƩ`CB����a���N�t[z�����$�)AQ	Giț��<W0J�y"�I���-�#x����1z��]ȁTF�\J�w�_ݽtу��7���ﭏT8�گ��W�ui(�>}�G�彫'*�掿�F|���q�N������w��Y���˥c<�C�#}Q��rb&���+�EE�kI3��e�
��5��z�J�}z�{��,ٵ��;��Gx%!��=+f�l�3܀d9��,86ޑ��a�G"� v���u=yW<Wcb����y�oP�֡]��W}A���/��6~�� ��-�hJl�Uv��ߑ�}+S���6#�k�3�Qr���t�0������p���;�R����p��і�|�A_SlC���r�Nm�%��U�%��M��9�#s�
���5��d���A�$5��i�Z��"zn����\j�w�VN��I]�^<����G���/ {��F�s�X�^�k�X𡘾�P5�MHu��'�"4�
�`���LW�9�O�T�G���U���t���؝ғ8�!P�����®0��''l �jm���{�Tp6��=�N���G̛�jrU���6�������術ޯRw�J�Cfꘉ�p���%ȕ�$�j"�?����&q�D���sq��b�x�����qP�=��U81�$���1�#zˣų�/D���tV��?)1����q�k:�^'b���+�g^�b_�wW}k9��mi^�y�Qǭ����m��@�ܣt�O�f Oe��X��I��4sT�!A�N�_�cFCPn�4�~��n�[8�U�Ｘk����I��o�݄�Z���FM�l����qi@�I����7��@C�v�/ �uPh��q6����I�.<�M����]k�JF���y�b��u���j��q����ƹ��+�2ı����l�\c\`ML�.�r`3�(��oNF\O@6|�jt�+�>�D\5-E���ʊ�����E�K�'_�+��P9+_�� P��P~��	���p-��E��! :�WpN�	W��ܪA2��詖�,@�-��u���z���w��[S��T�>����o6����`�2��v�@Z�jؔ��������,����I���3��q��L�0=4;B�P9���v$����z�8�xcl�9�fNF����d�rx�K�A"Ơ����j@�.�{��	�`�,8<[ߘK	s�����U��ߏAQ"ࢩ�����,�)��_-����E:��M�9���g	FX���6��u���||G+{A�q��Z#K�+�;����q-� ��ݰ���9��a�H�+o#�2��	Wm���b���������$�=�;*�h�*ؙ��N$~���SHBu����,H��K'��촗���
OW��2��y��hdhgFg�j�&/�~S]�$�uq���`����$��d��C�F��+�w4t�[�;��'�����]�L��,�9���c���"����1��T,��6vyY��t!k�l����C��vJ�t�Dfy6�Y�k��eO�u�n��7�<d.��w3�{�.@�zf�tgl����ܣ���;�5�~��l�Ϡ���~�D�g&?�2�_�e��!b[6x�*��ĺ�*Un���qT;�6��,D��FX�����G��p��K�����KW��Ѓ� XSv�|���6՗��R\L� �O.L?s�E03eւ\G���zf��J��������Ǐ4���Ǩ���D��'т�[U�u�$H�S,!Z0_d�xԛ�6I5��k�'bK7��X�mS�_�� k�̰���'��AA��{%��	,��.e���J�_O����rq��zM�=����`1�c�!�z�6G�*u/��r�����2m�Q����`س�zc`�v���AJ��DXʀEf��C)u	q ��<�(�`S$أ���v\TH�S�i-�^� )Ϛkd�2^���;!
l������?���ɠD�f9:=��&Dɯi�w�5�م�G0��4ᵛ˵��[X�rdn1�5�[����HD���!��)�ɬ:�"s}� �����O) ��w�����RD��v����_�{���4�qF�v�f^מv7��ٹ��C��z���`!~���V>�#b��@4	 ��Hg ��7q�xJ3���\A,k߬��V�� ݠ;�9�*�m�C�����EVZ} \�{����dp�� . ?��FJW�J�Ͱ.(?D�f;=��x�pr��������G%�3�*6�)�C9��ȭYJ�chO�cg�K�C�%۠Yg �����g����QvG�ΤAEBi��<aȷ~��FS�� ��b'Qۦ�#�L����	>�М�b��5~�q�Z���P�qע�=���.��
�3�溒��V���V:nkh���*�H�6�D��-���c���O_:�54�5l�"�����^շ�.D��"H�� `��W��5g�SN;�}ɺ���l	��zQ����@�ܘ�v�Q�>
��f`4$�q�-�97� �37/,��J�,p*f�j�PS��2�I��ݔ� ;Gho����a3�9.P$�NYd�	 � ����AUV�����o��oE��k�.!e�㾦D9eS:�)"1�<h����ˊ����P��d�@�`B|����G~z��P��{B�@n�)F��%Prz�۾�s�|T�0� �S�ͥ�� D`om�������h�иNHO�5���a�1�����w�����1N�+���'�������a/ffG��c�y%6�U�r��7۷z�u7;�Dv!D,q����sM>x��B^3h������N �`��t���T�_�+է�[w�ْ^ܤ�@��3P<�-Z�ȡ	iIa"H�X��"���)��x[�2oB�D �<�":{'@x<��6�(��vش���Ym��,o�:��DL�Q�u�q�zC���]�����$�NqV��������!%�JG��~��QgZ���qt�.
M�~^����&��k_L���Or�T����]f-E�6&� �]M��` �~�u��C��+��"�|K������M�4~XL/���F��X^��z,l��#�yl��&��>B\h��&��ͬ���c����[g?�fV�W��P�3)4Nz�,�dc�H��W�48G��<(s׉6�n���] %����(�=h-�;��Y�'�3�Y�>�eH��+�{�T�ER�/;
�A�����OQ��������|�7�D��)h���r(�f�`r!`�1�J�Ei��*��3��D��ϴn3&�]AdW'��*xA*�E�`(�>�෮s�h�O�sǰ��~b�ה��L.)=C���.3A���ބK�α�Nh��昩Ǆ���5ᨷ��D��_��OVN>�?�;��p={�<��_�D�~�) c�ƻN/�S��S���o�MԂ�Vp�$����!IS`D2M��a��qI��{/a�ǔ��5Q���ɖ�f�L^� ��>���͌FB̉n��������d�����D��խ��E�P2ٙC.,��ӿ�YH Čy���,Xt���\���0fȕ����к�eG�Q6��/�7W~�}�~�g�0����"���//lz���I�����X��"ߞ�����P�g��D��k����"��E��y����>�+{��Q�e\�#�%�A�M=�i|�[�ٺ��(���x�3"��o�
I36�a�cm1�/i�������,���2���=�j��\�x��S�S�	lfi����A?Y�Ȟs�[�0���?8���6&j��}�C�Od�<U�3#�XlZ�#$�����U�xZ�W�¦D�x	�o���(LH4إh&�Yd#��)�I��sӧ�A��&�ޟ��R��Ā*�"�H�$Xu���R�������90	{0���OL0�3r�c�6��>��qx[Ҙ�O q�%��"ݙ�yV�Ԁ����SÞ�ڊ��/bwk1cΜ���,�x�X_&�%eT�˛1�[��?�~}�ʱ׽r�H+���@�9�G]R�S+�B��	��&�GŹ��Ef�4�<0�����"}q�=�vA�Ҟ�c�0
&�1 �؛}b��������'�W� �!d���Kx������s����E�G�M�Ç!M(���w&�41(��c�U��H~=�e��'�i{��^��C��nEk5��)i�	zm��$3�O:����N!���s#����$�?��_�Qaq2b�x�H�@Չ�ԍ#Ȯ�X�MN��@�UɬH���1R���̭;��zA�ۧ�ƃA��]U)w.j��Ln����Q1��O`��B��C*�.��u{PE?�7ڞF�$�/����	)oھdZ�y�@��b}��+�����Љ��q*L���(e$�#Y7�?2y&&.%��S3�*Y�\x�;�S\��DS��:x�8 �7���4GT�%�?|@��|@��ņ�T�h;��̲n*m�m� j��s4d�q��S ����2@����w8 PM�B�`ys�'Z�,�"19�J�.{��t(�0Ѱ4wٿ?N��*XR���v���%M���A<�ݿsED��`��N�jX�KSQ{KFk(����F�ܨ�����:�ԛ<O��&唞����u"��e^S�W��PO�G1F�^����礱�~B���V2M�"\8�G*��4����F���s���X(af/�v�X� `\s4Cp��V���0z
|ޅT�����N����H�I60�+D�wV����]��(�؀�����CQjQ*��p�8#'�9�Zm������Z^�g$�3�3_9���(�4�'-�ر9������EQ!�Z������G;�R�3�Ys�`�K>�O��ե/�TB���i�mt�5X�OK�5�%����^��/"���_/�7�	�P��-��ihFQ���0��'g�ؙ��~oh\
�Xw�ԥ뷄 djiI��eV��'�_�x��&R��)�N�lߠ�u���f^!{�߉}5
{Q�Z�A���j�H9���PM�ʿ�h|�mf��E���wl��P�kZh��/��W� �������l���z}_n��2<u�0+�j��O�g6��B�&N�D/H}5h��.�_�ߢ,!�r*Y5{^���t�����ٽ�p\�f9����u���P�E�D�&����KN�OYw�I/����\0T��H�h�R�	QU�3-q��d����e��N6W�ԍ��g�_��]F35N�^U��q����au�d�O�����š᧒}�{�LN�8��<
���N�Od�s�y�p�Յ����l�NW�է�bc��h��r �k��\��(�Tq��moҪ'd����%�yj���C`߂C��Z{ŀh� �*G�����fue��d���(��1�2�Y�|��8j�]D��!rlW�k��˄��gN�e5�����i�O�(���ຣk;Յ
�_ӥ,�d"�]��/���Hp�QUT�ʧ�5ʃG����!D���j��a���RKj�1��Ƀ{A3�;�c���Q��T4q-+�׵�>?��x�*�K�u|��+�R����˅�6~���0�x��MSߪh�'�q�L�K�T�B��Ю	$m;qx�s7IF�RIӀe(�|�)��QN�c��5��uT��Y��o�_�Jâ�Hӕd���'ª���{Z�I"�,��!~����wY����C'$�u�;"wx�T����Lp6/ŐB O�Y0��N3s�e�>T� 0�֖�~Ĥ�gW�>x3��O� ��@��e-ia�3�	"�R���$,X���[چ��%Ʌ�j��o-ҦR|\���И�3@W�p���ؙ�SЅ2������wO��p�#O����ծ�pE��� ݊�:�IV7�JI��N��aj4����]�� %]��:�A/�C{_@D_������<g=�欎) �.�L��BbE���� �I*^5
9R�K�&)��Ư3o0�P�Ϸ�־_��������*�ZK>J~,#o�­j������tݭc#Q��u�>�k�^��g��j}�!�vAk���h��-�W�46�[a�0����>i�@�=��[BigW?ϒ��F!��fW�5	�d�j�q����T~B���V)���Bo�n�P�|pu���Ļ(r�d 5����ٗ�f̨���΅y�z�@ǵ��؞���w��Gy���r&v"2Zi�����190�LZ��d��`�C'���J<Vi�5�D���PNb$/�U�O��XCt������0�B�`�5w�Ru�X�t�	S��v!��󐧀T8f�0F�G�� E���N���qB����oa�A��D���I
���c��`��M��~�_�a� �d [(i��X�{��c��[��mC��2�+�L�4Uۻ	q���8�ՏQ�!���H+]a�#�F���4�a3�b��q֬ۦ�����]���0.'�ʔ5�l�Ƚ>�I��~�=#�w�����l�.S��s�O�0�
���*�^�Hsi� �q$bWmZi�����6��'Iۮ��DH$�����O	�Zd9K5��!N���{'W\�%�j�QZFiS0��q�x� �<�	���P�*�Cؘ�vc�Cl\��1� 7�	�;pe����!��a�K�&Q�m��z{��*��um���1��Ib��B�G��(ȧɑO�V= p~�߬orJ�:���n")�5ha %x�v��xРu�g��#�Eed4�X�L��t�̨@���L�h�_�ab;�L��=��p%����Z������/�ߚm�/Hȳ�����تT���u�И�������I�h~0�����1��z��։g����r�X#uiJ?�̓��ޏ�M(��<��.��m3���֒?`
���7>) x����c"��/��L��X*�w0��=-��OcfL���H�cd�u�[/���W!�=���odA)?���'�U�Z�t	@��黐����?��ʒ*1�L�t���Hj����+|T��XH����!���H)E8����R��z-�؞�H��[�ȬH�|U�g������G��4+f/��$K�+4��+y���8�r5@,�:2ho�q�?Wٸ4X� U@�S�i��Bi+�W�"xq��\�c�~¯�c����4�2��)�1d'fb��"7,̌&��DĴ��Y�oA�R�>8��T|^B~Տ�W>}�H�J��&v9C)k��ZXm�y��|¸@��͛���FL�ǇY�I�J�Kr�u�TJ~ ��G��jq���<�~��>�{�J�|�<M��7&4���D�W��4����\�ک�l?�ũ�6y$�x����A�.-CJ~�Ҵ=�*���M5�=^��+�<Z��F[��8���!�xNU\��F�G�Z�����~8��k��-,�%���3�ޘ�H<���G�o$H#��u����ri�B�n�`�@���� Z�e6���<����J�����#h$:��q]<%Hl�q���RK�i��+@��xr�J�A.�s��ם0�N��<�Տ�����y[�`�ic�c���:���r���;���z�x�ˉͱ9m�<�xI`��I�~��)�����Na���z�\���;4W&���a\M�von!�h�.nS@�׊�w\�}M7M���oQ�Z���׿�]^��ʚۿA��,��#�r�Ҹ1��6��ge.����D��=|hC,�.;��)�V������mu��[�t��u�<����������*�_}ؤi&�4Bzv�\�Z����X^Z��se\�:�U�rh��8�!�#^*o����֞��0r~P��ܥn,����� ��#�|��� �R����t
�q��A>��6~���S����
ޫn���1�Q�ww��%�6t���䬑���R�P;�[�O��\l`�,�P���i�EҠ��c�X�����6��$m�%�Mą)"u^k�O�ri���V��H�mz�w� AS!�\C�S���V��o�"��A�Sm��e����n�R���>�k06���0�����1w �Ҡc �y����q���ah�u��;P��%9
��4��R&u���U�xI8���<-��va�K�6���2��g��_�����#��>qTT,�p��7�M9�.l8���	gf�
B�!U�Mt�]U������NUBV���^Bv���Q�>�d[j���a0a�����Neb�q�	���#�D\X�Jyھ��IE�_i%�֏����M\��H��O�2j��⁺ݲ�;zR���c�J�Q:������/RY\ȝ���
�=�bt_s��,��	��/�A�a+u�#țHxhQ>�����Iݔ�-%��?tGԿ��D:���h�W��QL���.Z���ř�B\��(|��E��
���o��lh�ĖJ��_ry,�A6C��*�d͔q<��;:��[����R>"|�Uj3��/��t�"$��ĶU��s���T�a+�@���x�ʟ� uW0C� ?�����p���#�H �.��~Q�/[�=�WPT���4J=9S٪�R q&-���߽����B�:���Sxn���ձ����*���Ա������U�V�<����LN�
/��'f'O�a6dmZm8���B=��]�y2��i6dJj�����zdT�FT�[����E�m8���0Ɉ���=�2=�IMɩ����CZ�L��N$��v��f1f�Vq?����u��IJ�� 2py#��� ў�3й4J�h�H�i���T�����`��R��Q*^����d&�摠h��7M���C�����o>4c�(�^1��<��*X7W�I�`�M���j9xꀓ�2m�B�z�����Ǖ�!$y��N�F뽷 U�&4W�*��Ү�&P�hFkB�?�}o<r�/�hQ�$���hO���\��4���Ta��5���9����� ���6���]��t�&��0G"�1
a���6�v���O�N��uʆ��X�;9\�C��5+� �\*��g�z��]����mܢ�q��i� ���3�`L!~[�WR%�G3mY���+~23IhS"gI-�* ���/H�{g�/�N%j�n�⺪���qͻ[�+E�>F)���A�F�%t�!�'����-��Ue5"�{�=՟��#�Xw#�S|��3�u�`�B�O)L�/]��F�ƪ��cM��)>e����<e�kS���F`vEk�$��_,�Us��}�W&��148[�N�L�a�Hꌎ�S�.��0��Td.��Ps�zMM�Ѧ6���:$�4�@���[�C�X�@G��d"!�pH3���}"r��B[��7.;?S��g�޶�j
�ho�UYP�Z'M޴iL{�������K��� lI����؃>�F��a2����V�u���5��牛��5�PX����s1*^&�SU����amIwE�laC��<5ߜQ?�E����M&��o8�l��M�𩡔���E��؄�Q�'��j�M'�Qv��O*o�jc��K���#2��l��Ddu���8���}�[+ ��	S�����4��BK%RR\%�M�]���n4����][��kHn������a-F�a���f���h�ݪSD��I].�a�a�����5�[���i�`I-�s2=#cV;Eħ��y��ٞ�+�H�j8���^dd�%�#*����*��U��r0�m��`�PA�#�M�p+��$�d,(H������B����G�𜼅��K^�_6��`QmlC��T%㮾�b��،�5�B�O�E'�����)k<S���v�|��O�@���k����Z��0l"�_�G@T�O%O����@���]��g�k��	�V��i0a�7RND�+]�z�8.�~�nT��,��ª�30 80��^�����]��7�s�ۿR8MlZGG�n�n|<��,���8��hK-$(��"jpg�.�����T����Q�|�/7�ҝ�!�K���l�}� ��3Uj�C&C�P���q�N�ūs���L��I�?����y�<�R��S���_79�˩��3�x�Ա�
�4�R�F@���o�u�0�ƗZ��5���5s���M�l�R���s6�??�F�n_�\�f��a���k��9��0��X�t���})/�İH*HiJR!TJ����r&v=c�}>�Z�D�b��}���s����<K��D�G����D-�h�`�{���N���B٧���"{O'5�=X�/3|+�^�c`����t�y�f��9)>���LG�Z���K��ӿ�������|��7�{���R����5�p
�MtڜU!:@YR�?(��KϢ���؍=�~;� \R�!Y��� ��~+��hI[Z)�^d�A��[�?J�8��	)�-ZΰB���� nb��	#�,���c��W?l����~!O��b�[#3xL1��B���.U��G���ֵ8�.wn.�Iҝh��k[4Vՠ�m�8�����+hXpV��Cu�c���Z��M�f3TG*\�/��qˮ�Q�#�W�ձ(��;�r���~$�T�����ɖ���l���?��R٨���5l�]�l�8��n�&Q?S���<s���$	��Z>;�(ʆ!9��)�;dҊt�L�0���D2~�p�$&d�hE�o�������?�[p����>�)x��4�Z�#���̝�%�qf��3{�
�$ݏfJy�R�!���?9�HZ汅aCBnP|@�J�6�l$�<��G��z��.��Z$��U�i�Nw�`�x[��>�	�MP�u�� ���cV|
�*����#RR�cH:4��=cRD� =W�w��C�<)�o�T�I�n�F�
���5`j�/��j��[	�%LW.$��l�+(~���6�����3~�.�n@�8�[�F4���b��epg�8X�h�"
����A��� �?��"���E�y
�&��t�O��0��>�,��R�8�" {O�c�P�)-�v�R���J[@6��;�j�՟c* b�v�D��Sk���o�)dܖ]���ǠZcL��k���a^i73W
ط�~�_!�ڄ ×�N�)�6�a�XR��Y`S}��-���j���ڇ�����VMz�DN�th$0ZG>1i�j!Ê�ĝ7���zY�Z���,�40_��v_`5Cf��/��T�du��.�\��y��(�I����B٨b�`D�}����D����c�ˎ����Z�5��`�,}e���+t��m���	��4
��Br�p�?��6u��gLF��| �k~�	c":1X�_�l#Íe��F
*vg�����\Cxԙ�ͧ�D���LK�9�S�5�D0Bʗ2���̀|,�>���H&�@Mr�K�A�*����jk,���
���u���ؤ��;�=�&Ǜb^}���OS�ӅI� Ci����3�S��5��k��9/���
����bk�<�%SWg�s�D��X��9����s��_M<��(-\�;M�"�&>������JL�D׶<�t��f�ҧN7's4Uu��Uav4$�F�jInL��)C����l>�xΆ!?)8�g�T�Փ~FlL�]UV���6�Δ�)��(�^��a�T�V�����bQQ�	RkRzї��I����j:��q���1����>uw��,�]e�u�g���'���7f�X�c/U�_C�F#�h�t�f+�~`��M��[Ϸ�%�\�
u�")��/pB�
�־� �r��D�h��9�7Q;~�5�P3q�zgr5�P���og�-�ӽ [�)�O ֤]Ar�~eZ���Q�i�G�K�y�N����'j�@Y���T�}`d˔>��G��A4�Q���C_@dnދ���yu������=��}t$o�~\�m�8��ne����� ��<�0*o���"���I��h[��Ď"A�*���A�'���H[�f�<>LF��w���'2O��=u��`σW��RT{���B !X����ܼ�>d�a�&+�����"���)����*��bO����ն%�̪����E! g 4���bg_-�k�T�t���]��"���?�q�I�-�|����7�g4]�`&-��2ߚ��	4~���y�A*� �ዡy�`)���8_�������ig��?��%]zQނ
p��|�����L �X���{vfΩ6|KRNMV����5�<����	T���O}����e�Ni��հk 1��
=����S�&���0�����w�����X)��� ���j/�X�9��7}z=��%��f�}8��[[��3��f毧&'h��o~�;y$�~���gň7N���G����<������r��b}����"^�77����<f�r�]��G����o����a�w�9#-�B��.j���l(�o-$i�Z���݀3��[�'����&��	a���H��-O<7���/)�;�È2s����������~-G���[�����\ë�_��f��SO��wm� )Z�҄�G(�/|/��ϱ5�X���;�v�����̟6��i�W�l�2�渆�^��86�+�M`،O�b�.���J��=� ��i�8�����������+�Q����9����J1��7tAa�*?}�6��etL��[s���q��	�<��|ò�F��𥬓I�q?��K�X$�%b�6����	7�VX����H�����G�8B,� ��J��^�$ѻ)ۆ-����#{�㢈n��gwո�Hv��-�i��I9�^�ˋ����"�����m�Eӎ�$��wd,Z��2ũ@70��Lm��$Dȕr`�6��r��w�ʃ��)~c���w5��.��b��^>`�b@x�HN�����&p$n%4���԰�s�g(ﵒ�5J���X����y��f���U1��Y�9�.gisD+ .q�~�=�1
WcF+ mf�t5���`��<�y�,��1ppZ2n�V�2�#�8n�P�G?��z�a��`�2�rF)o��4]�y*I;��ÇM��G"U��fUk;ӯ������؂4��u�F�3r�~s�ԩ�&�9@�7-N�*�!�}���:/G#�:Ԟ�����{/�#�/�(I��։g��4L}�3Z���������x�;$c�4�Q*My!�����C�Ջ���_F���2A����V�K���	�F3�d�.�/%9sa�~�jl�������3�q���L�GJ>���_��B?�%�)-��ܩ|[��;?Kώ��md�ƍ=��8�� ���*�3��6��"��o�LE ��2{	U_����r�q��u��p�6�tGl�@����:"o�}l�Ii?{�&i҃�Cc���S�����M��tH��9�~}wt�t��דg$�p{�T°Fi��@�>���������)oP#�c "6��Ѣ��Նr(w�=���}��pJÕ����*F2@���s����c�v��M4��Q<����</��#�Hg���# ��j��'�U8#��]�& ��؃��G���)y�L�'z�G����l�wr�bA��n�lJ2���ا)�/�u�VsBe�aL�(��]ѥ܄R��"�U�D��j��6�`g[/hA��w`w��E醑�D�Y�~t�H�h�����������-M��<�lf����{� �!뎡�C��Gܲ?F$�/ˮ'��Jt�h�=h����dzn��b���8I�-O6c���?����]����Q�߉Wj�Z�f��*�ә��C�ZE�k �xޖ(e���"�E�g���F�`%�SV}���";��� �3�TPsC�6�{�+��Χ��� M@>֞z�L��f��=��*�Jq�.���-"^~��ew"7lb�YeQ?�	�nL+$��%?xk�?U��B��'�F��%ӹH��e7�=�FN���fZ�\]�J���̼���'O,�}���7���)��V*������;udJ���Pڏ�nGU˩�u��@_���㐥��s�>�-=G�-7�(��O�DŹ�"I��e&��ϐz]���<՚��Z��03�۲���TՀ��6�z�->1�O���agj"�$Ԁx̵8Lc�w�f�+Ŕ�� ��`�޷,��@H����~o3yGY�aKP�"N��֠�� �a�����.���_Ss�|S3.=q�̫��ߙPkϕ?I�M�����hN;�Go�j��lu>���AjʄG0��LpI��ia�7�{�	����94�@����t6��e��������e��%��	�nʘ��/2 ��"���� ?۩d����Oa�,�e?<���R 8��'��?F�_��x��"d*�]��Q��Jbk̅�w7����n�a*+��gd�M5ȫ*?X�:�
{����sǋ��{����r�-���L�/�d��I��(-�Ձ�2��	�#����*�\MX����Ѣ�_����@�g�w5!*���ǐ�&���[S]�l]M@}�qC���A���ZBE���oQ+���I"Û)"�L\��<�cH����zJ��J�[�_��\�o����:�On5��f���OG��B��7����F}����#�5�I~#J�r�d�����;�6�;�HB���G��B�OU��<����wL���@��f��71(�����J�^#Z�����1S�=�%3��lm�~_%a�;/
����5�}�w�ǁR]��.38+�rzqɪi⽃>[����*,A��*��qC�ւ\.��#|n��G^<EQ:>�	�t(u�ޗ��K*����gF0 �ڶ&2�tG����Lf�ڴ,l�c��m�R'v:Gh���P��"���c��>�J���ix���7�v��k�����b�4�t�D}a4f��?��eT̻���gՎX%ٰ\�\ }��:�����ZB�i��������͡�n��3Q^�X�/dm�����D6:ơ3��ߘO(��c�er��4���c�{�j�(ߍh�z�"��G���NU�;WO�U˭H����$�=�T��<���ǐ��Kk/�+�y��8��r�܂��2a��uf�w]F)v�D�PJ��2�k�������Y���S�i��8L&�S�}��y������[��*���j�_/	��k�m��-���
������ %bc�8V�\z��{I &/���g��s�"�Y���'�{0p����:��YK�T��;B;����%�����onH�P���@�L�����3J����b+5� �_H�;1�Ú�9t�V�9m��2�+!Z
�I�s�cѻp96�f]���X�Ƚ�A���}��MR�}V@e;1-�m����L?��C��4e �t+ga]$G��ʤ]���0��֎�m�a{�6��ͩQ�7�/w�ߝ��mܡ2X_�zM䑼 �7�����Q����N��E�]vH ܢ�C��O�V�쏘=mM�'y�	�~���E��&r����~_AsI���X���*��ó�ǎ��IF�F�'h��Q�Q�������Θ ʯPԀ��l&��O1c�?��+
�zt� ��p�򄏁���9�WP���b��3��V�D/0�Dz�J��*�o����Ý�����N�d qA"����lO"����k�9=+yp��^��Ӥ|��4хv(<�l_SnJ��Nl�J��2 ?6�v�6�h�W�m��DrsaF��+F�iT��?�Z׷Mh �?��1/�m%��R�n�d�#P"�A ,[I�J�óe3��|�%�DDbkj��9խ�Ĺ�^�3�������!@�'>�:_�a�j�y�i�?/vSxKD��lݯ���l��h����TԪb�W$��L���U��G��%��
x����YҾGh��
����&���PD��!��C�����l֭�Y�G����f�%����m���`:e֫��Q�!�����?	�)rB��n+=�p�`��<ʩ�zQvM
���)��/�G*�1B3��g��SVC�z{ $]!-l��~�V���IW]޸�N�,��$��"+�؊�5v�Y�J׳��!��:[�c�!__�n�Ƣњ��UJ�U_Θ�|V��L!�:{�̌7/�[�m#+@I�ֹl�we�p-�M�>*�W����������m�4G���k�%��rD���󍺪a��_�������)`ś��,!�.7�G���e�,�OBR򡤝y��~��E�3�ҡ�����Bj���#��@�̓y剚Y����[n�N�_s���k�=�4����d�����ر�|����wCw�;    �f rv� � ��������g�    YZ