#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="557838130"
MD5="aa7f3d5bae05c106700250d5cf75fcbc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23364"
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
	echo Date of packaging: Tue Jul 27 23:00:25 -03 2021
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
�7zXZ  �ִF !   �X����[] �}��1Dd]����P�t�D�o_�Ǉё�S�bu��/�\rNh�-~��ɒ�C�\\>�S��*�}~]Q�`�4���Kz�M���ڨ�A=����{�E.? ͭ�,ٗd%��\'�5��r��Q���ͣYe�;���bGV�(����Ӈ�t��݃+�AôxNkF�)*��~�����N8m�h7�io,o)�:�"�j���uzju�i�[�tLY��u�=���`��i@��Ѝ�_��!�Ep��s@���Z�l��}�ӵV���$��qEC�}�l�V��e_�,8���G��p�D��d�ۑ8��"T��y�h�ƞ�@=N��oq��7d�F�y��H��M4�4?K =�����X��2፛�t/O�t;&=͞5x"�;���ޥ�7����L��ךּ�w�����h�r�l<���D<�ë�ģ]o'����y�^%6)9<�uw����HS�����21�/�/yi/���+~�5��:�t��r�ۣ/�����]?��x$���k|���k��)��x�H3���z'�k���A�S]V��jl4_��sv��ᑐ� ."�X�:/����W��/�k1�Eɩs�5��9�}>>N#D'/�[��,-}$�W+�>^X�0��?G`S_�27�h~���[ �k��Jj����Zr�_��ʞQ�3�~9k_F̥��7_Xe�_b�=z"/O,�**P���Iv���Ҕ�.ToH{O�Q��|�׫����8l�QLG~�q"-�	r[N�:��!�*^Z�l��J.�B�3��U~ƍ��D��`:ۙ�����sb��� 9湸����M��v����Q	 ������
�$W��+4f�z�F��"R�S���0���\AR��lA���S��֛�Ŷ��������kmό���qLQ��d�)��>�O��vA^�y�-UY��k���j��z1�-�k=�3�=y&�@ͪ6Ņ�Cу�7ٽ�j?c������e�ZeZ���ۖ��d<� ���B�o�\#xw[ #|}��qB胭C��ߜSo�ʋ�@ x�4~���{�����٥���.���~��@��AK�ᮺ1�;)B�� ||Z���*|��`�^6ϺK��I��]��(4&ER0�s2�"�2�3]��i#�Pָ��e��� �^��{�	��@��[��0Lo�@E?c���G$"��uT��� p�f�����;=�_���d"�{01Rs�hC��o�˱ ����x7�./9Z<��ϟ�q�Tg�騽��^�WVvC.;��a���:z��ga�~P;w�B�nz�]�Z��A�l;�P6eU�8Y�<E���g�/' �p�ʢ$�5�"�@��i� V��<~�XT�`����ӣX?�����cK�Hu�����MU��6wZj����9�j0���?w&F��a� �S��94�xҪ��q��
y��/���A��C��ޏ�K�����Gc'�r�9>U̾����|�w@�����"��s߇#z.nA�O^�]���Bݕ[�X�5�p}�/��sn�C�e���@��n�����XhW��r�}���28����K0o�.�[�7��ظ(f����)��ê���f7n7��n�h�������.2�̞��w��rt�xg �냣lA8��ÿ���1��d"迒���/���f�͒�
�X3���-��o�����HdP�@�����������98ƶ=��)�=��kb�"3�1�$I<0�lt�]`�,����b�wz!c��?0�A��������e���r.�{�&�^E�$%��TP��<��#a��
0>۸� t{�>ز���1�xf:�>Xq��G�3�#<�>�|��'^Đ����k�m�P���
t+��0^Zc�KR0{�֯O2!�Y+UzZmQ�����4��}2TF��$�$�^�Vm�i��I2#gm'��!��˿��q����N �JPm�#*�(q�D17��BmT<Z��˝�;Qi�o�6��6ğ^�����C�<\s�� X�[�h+�X,��
Ƞ��,T���?&Hї���&p�^�z_�W�<�j|]C��tunsnT%N7���w�:��m����WV�5I�7<�Wd�m�>&� �uҁ�s�/AZP-���0���Qъ�`2�6���Ƈ����P���ԏ���W��P��%�� ��	��Wx�򍀀z���#L�Ӎr���X�3��;��bXj�f��]�����3i���&����xJ�<��SpcC�Y0�t9��]��P}:v��]��җ���w�_�i��g���<Sy�2�m�a�\t?���a�1��\�C����	���.Y�(W�\t���R��p�?z%#?�`nya󧋪6N�(�fc�3�}�� �f��;���=X?�S@�c���j��LP��p�  �l��C+n�r�V�����*gӮ�Ar`��M$+ǥOF~��}oHB*VcZ�N}�j�a\�� �� �f��ȴ���i�l\*� �F��z��8{P�(%�f�~�j��g���sZ�#�'Y�łRם��R��؜���2=�uPkP���G�D��9�`��カ1V:��x�F�=��Z�/�����������Kq��?5v�8�'�p]n5�jn��W�K%�T���|g���� (��g��F���u;�($�#\�sN��U�#�ԧk��&�0� �^�����_:p��`\û��;�eN�#4r��ӯ���^��nVZ@ʱ�l�a$�B܋������k�|��/$K���5�'�,O���k{2%�\�R7u+����g���{�����h�~��B����0��1�MO�������L6R��k�� �:{��7�t/lo!v{o�K���r]�����S	Q���CG�w�?�:r�Q��cCP����hj�0���
�z��=�!iM3�Ho]1�Z��Ќ`ї ���U ���|�.�!3��L7i�e�$�K���ےkd�Oy�]9��`Ѐ^�QT�z��:�4o\)�>0�2��;������,r f�gb��ܿ�;���d���륱V�k:��k��6�.�xU����EВ����m�	��S|�Ь&�?C�O*���y�<:�όC:��Z�j\z�@��9�τ�%��������8��m|1=ܓ;���jm��$b�Rs͒Jg?P>�d�i9､t�����A���k��Q�62	7�5��Ec�������Z������~W����)�:��÷#���X�2���)�s�?�
6�͛p[�����xA��-�n�:���.̡��tA���c!���r
W:�+UEl�X��6����a�Gʝ�A\3}l*O�z�n�x�M�P�qmB�9�RH�����͏����Hf�M��5	8�#R�%�U)π.hw�y�R�w�R"�z��	��%��AN`r��������{�	�t:�:�j��<��B�V  �&��R���6���C@�6���3�Ƕa�<-�K;�j�q0��|͚�x�X�	�#.�*���2�i֓��DF��k4ކlE>���r�^���W;��5��Z.��e�Ǻ�%�����hL�N%Q��V���9!n~���m�2Ѧ���|��v��y��9+��L��h��� �O_��Zxݹ뚒MF�red�(��?}��sn�y���������!0�ȕ�K��_n��k�]k*V9G�)�YU$&�q0m��p!!���˞Q3P�yW�E^�O+/��:�.��I�./�;C�+�q�t��K�u��ҡ0�1�(� sI�}�>�b�B[i�gߊB�ߐ9R�~p�扐	�o#�;�:�٥���Q��1�0qd�nY�51o3�W��kmpn��;~��3�Cs_=5�|�j�����}��Rb�����(�RPԤc�ٓ��! TSg�(q�-z��@���91L�4�,��W����?���f4�9���^��^�$���/ϋT����%�?��l~����
�*�ƭzb,�lPa��0ϣ���L趬$���U���(��T�vKI}���q��<�Z���I�ņ�c����L�E�X#?3*<�m�G�ie�^<������J����g3��ر����#����uZZt�R邧�^�� ��
VM��\�W���$�@ߺUt���+��i/H�5���MJD$�1�^�> e)��m!�v�xi��9%�ff��yOp�D뼪��9]���D�Lle����,tlD"d����S(�N*}��Ó��7	W���σb��j�!}w�ڎ
M��F��H�yF�0��g�	�͎i�&9'3��u��֓d�C�M+�]���h�6�����f�RVm���!�;��B#��]����p�?õ�b�P�����e-['��J�rm2��D�D���>=�&�~L�|+�A훧�-��Y�)�lX�2��1�_���c�e��.$�59�l'Ә=����n�I��*�g?M��B�q�qnc�|��TE?�v�D�jNd����xqؗ���,`sĒ�a��	G\荨:��-+��>���f���
��$��7�:�)>�}�4��1B��}W#��9���-�1��O�a+[U^���U�B�8V�^������T����,�����]^bO$�ܥV��iƀ1n\��Q| !��!�5��$%fm�0�T�ǉ�ٝ�-0��F	�SJ)��a�{��B�v��;��C���&�>PN�H��Z�I���������fG�p���l��hX�(�����I)R-��٣�;�O� �7��ս�����O�̅*���+ނx��dKsa4ȵx�o)j��)m���U���?�7+�]��r����t0�x��"0�H�o^���zh�OC�uK�)_������&p�L���u���5�]ғ�_��,@;E R��O�Єj��yq��\ӫ�4QA�H�N,s~��QJ�72�Hn�RV��
�᪸�T�PY�s�md����@ZfP���c/xD�"�)��p��@W_�e[�R�:? �f�;�J�̌�bn"Ɔ���J��3\���HCǤ�"T��#K[�m����c���)L�&�yM^8�He(a�!  ���k3�Hɔ=b϶��#;u￴E:���֖X�6���2���?�2��z%O��邸'�'���]��6�����Eb��Ľ@���� e�.��2��Y�Q��-��f�����,h�ӑ%BB���Mb�MJ6*	^R/p��]�e4��^o��������n���s�\�5/�3�O�ȡ|tO�7�ɗ�>R��3/��#�Yg��p��L����j�5zV�eF������଎sYoaFf-,���E��M���N��>�(�-:��?o���u�?���f{~hH�������D	bJ=:�$�ur��������Z��;�M�.x[J�~=``gIBd��u)�5o��>b��]:3��+؁�:��/�x����⎅����h������y<Ѽ�u��<i��#���_��C<����)^�uϞ�f/�p�P
�(����3_Q����M��� ��7T�'Ä"M�=�A���h������>����E��9�2�7�r��������T'E�ڡ�X8���>4r�z��3�K���]�&�[��Ҥ<�[�.OV[�3�3���D;c!��⁹���Ԧ��$��!+`4�u��J��QE/VAu�3e�Ԗ����m�$�[_N��X�����n=
�~#��h�������٭�Y��w�.���$h#��j�&��@4�t)�L�@gʨ�@N�%&�S.DY�"�\~.`����xU'!9n�ՙϨ��k��@�9~���
Wd�Yň]�6}c�҉Q{c/�Y����Ӡ�|��?�%"_`�Z�]"tѳ�aN ��)GAO����`��D���>�I��3Y���4���;����w�V��g0�7|�	���n*D���HXg%�w	F�^9�q�_�F����w�ͳ2i\Fq����6���7�uh�\*�Լ��:����/������Dc�e�G`-Y|nc)8��
��fz�>K�%��)_���S�Z<BKj3bA��w�RJx4��2-|j;G�럔-���[�}��a6BGGd9�<�&8�J�?��o��oV_�u7�&������+���o[�ʑ�0ӳ;��N�K$� �M ��ޛPϾ��P�Κ�_Y4�æS��^8 �KTm��������a��0}��J��r��|Dt` �=��@?��G�\���2z��z+��-�����@'aU�
C�xā=�[�^gN��@(��d������{H]Yk���4,�\��%8��r�3�j S(̪��>5����}�;*�HBTE��h�N[h~$�㧘T-+6����v�O�̳5F�8z��h�[T�c�A�Z��lKT�Ԣ�]�r�;'E��a�*/v��p
$���j�a��j��S���!��3vF/c��3nE���N���ߪ�M��Kd��e$��,�?�����ܗ4^�ETs�!rL�:A��^�	��8@���I��$&o�1|�p���� ��"N{��A��=�����bl1��!�(.�����VYA��[����f'u����G�+㡗�H�z��
��*F|�� �fz�����`Q��dpt\�7�K,�
�٘�>(���	�U��W��]�!����^jZJ�4�E&CP�?ҞHN�R�(rE���N��y�FLqa9����oqz&r��nz�,?�>'w]Hx.0Ɵ���I�qT�>��ȅ>0�+`����������
�%t�s�]�N�A�� 0�$����d�W�!����r�tx�ŪH�k�k��':i' =�7Ius����uX&�hᑓz+�PX-����(���[�P�7�3��H� ��E�5a��r<��tO�%�Y \����ק�MA҉BSW���R�'�P�����2h/^��|<�	%���4ooE��[�?)��nW`�o�Ǟ65r��K�X�%S_�vQs���D��w"R���Xv�\�"�0��X�T��SK�P�)G!
��Zԧ6!y֨ ����ܸ��G���_�aB�;,,��=�	Iy7	��X;eY�h�����ʢ��*�
r�^MW@_wP��VT��!���<I�$!��w�`�Z��&���Bɶ���b']��um��k(�-V��W�4�!"�C���%4$-�3�jƶ��:�#(�Y����l�`�1+�a�]�Ƙ��ԑ�'�c����$lu��1�P[KHE��l*��N�&M�Ӏ������,K�=��C�<���]O�M�n����$��S0F�H�l�2h嬮U�W�?lCaD�� �Iv}L9,
�i����vl��y��h���WL
���߲OL�/�%t�J�I�P�r�iLEGz�R� W�J�5=�%��.�!z2�'.ee���l����ͩ=�4(��.��>Y�m�V���/.$*s jҌp�Kh���x���Xu�}�уQ{�[.N8��'�����s�J85���81�Hj��U�����U����D�!?���<�ӓ�P���[n�� �w\d����3�ma+Q\j7`e[��^^k��|_�Bk�WY��cՕ���JJ��}	�yqH �N����J�߬i�Y��egi�A��gA��]Ѱ{�h,��c���&�<]��+�.��Q��
Qr�r������V�������ʧ�h`�˱�݆���B����x$���4�_����%��rq���R-J���QD�~�i��89���x�M�ǉ�)��833��K�b��q�Ma�@�B�
��K�!Q�����
�����*{z��9����\:�nI��Z�Aֿ���b�jn��x�K�'�7ٴ�� �@��:��L��w���@{����#��!�_����2C]�G����S�Qo������֝�Piq� �Q��b�W���,^�nr��̤�F��Fl.�W���@zH7t�������序(5�懜a�B���0�+�:���G�65NS,�*������%D|�,�NKsFЌ�K�.r1m�V����X h�Ņ�Oۓ���U��U#|����c�>�g{�(���/�R��+G�ҍ���L����Xװn���� �דӜ�3�a�|�v����#1�U��zkν$���ϳ�sh�:���SU��6�x����U*�<���� c*�����m�L=�!=����\CH\�'�M/��28�TD*o�i�Z�f�om����30�:1`�
?(F.
ɍ���	��?���U��?�I�|l�Ο^��,�ՙe2��S>c�>/��ܫ�>8�J[NҹA<W#�hi�X��6G�N?,�f���_ɘM��k��w(��/;��g� Z�>��𜱡<9��*�����.Fp�(|�*J��ο��#�k�p�H��R��6�ˠ�)��+���fN��HJ���C�9GKC�>�D#�^v�؇f͟;�+(�*�G��g��~���#H��$��(��>@�G���m������E)��6;���,����zD'"B@m��)U^����$W��+$�	�g�a:�0PX�r�ܝ{�������+�������E�r�� �y�sC��O?������PQ��C�)� �.��1Y�.�{��nr`��d�Jj�WZK�9i��Qhԇ��qli��jG+}O�����%nmI��CG(�p��V��(` A`I�v>$�	"��BW�9'[P��d*w�5�.��@�	�g.�I�����Ě�/R5^��>npJv����v�V���!i���o+�wr�>fI����vf^t�Q~?���Ӂy�^R��:~[?сC�7�n"G�B��'2�g�i�3���j�����[մ�v�V� L49�j���PM_�2�:Ko�*�dr��v�E������ �j}Gȑ{� s��n�g�u���͍���zP�υ�������@�&0�XDi�,��|y��(3_xљ��w�y`釀F���f�$,�Z�}�o��'���w� ͭ1-DJ�KK�N������r��'yb���-�^���Bo`�_��e�L�DͰ��&	�f%m�^)� bĝ~oBնp��Zc>�9tIb'�M,�i�}�1q�����Y�T+L���00G}��d]MR��$3F(m2���3~�xҹ�>�`���I��r
k[k����|14�ʡ4p��R�0����q��C|�W�2z�;�r�h����'��)("�8�T[,������L`O���\z�R�h_,���b���]i��Fc�0�NǅF�i\�!�>���e(:x�F�W��D���J���A� �[l��v�lkR�|�z4܍n�����:��m�Ƥ4Ex!}<X�4]��2@��G4vs�~g�PcnMT�k���5H8�&]�㧸<Mr]���)h�ֱ��1J�BR��/�����N�~���N?�d�.�1�����[���Rs�.�� ������<�U��B�l��!h$�IhxlZ=	��'���%7���A�?��D�d��t�`o���A<�?p-��R8��N�(
�|f�/~��E2t��$[)*�U��SũY��=Ԗ�_�j��G�.J�v?G(}ĸ�>�.M��o�����E~��{2z]��ʴ7���I�������i��8���)Ԯi�GCA����^��sv�O��9���Jc���7���{�N� �Q�$9��Ʀ���*w�����I!���	�����W�{G$c�-����L�/S�r{3���u�^ҕU��[�A5�!�)2�&6�KԜ^�lӚp����q��:�ym��X��LZ
臬�W����Su ���GE1%���~G� P��SYJ�0�
HZG](�w�]`4��@�P���Gd�����-9���U�f�V�"&���J���	(�
����'��P�̿7^�;��K�L}��k~v��֠n�1�Zp@>�K�k�vg�K��*�?+{��4� �K���GǄ=F��';��5�����V�;H�r��[!i��Q��n�1Na�fX�8L7
́��Y�I��wL	�o�u�2��kҧ�<�*C��0���l���(=�o�N�^�ˊ��ӿ?��&��<�u3B�n�<𔗆�s^O�
�ͮ�����1�e��]'�������]Q�4�T6!��)�.O��J$1z��a��d�X=��3���z[��em�����лz�6Kw��i Ĭ}�j+�6Gs@0�B�p�Ϡ�f2^XH��4΃����r6�%�%ڣ��"�P�����\�cj��읛O�+Vj��п}����������h[d�˄��.�����yA��[�	�A�A�
�f�����eW8<�7d?xC>T�d��޾����{�*���Zn�?�/�R��[��]J�����J��c?�F�i^��ɀ�e
������Ic!	/9+n�A�41^�hÔ��fԹ��k��x�x�=r�ﰈ��9��'�������BB0_�l�����3�L�f�0�w��� �3���_DCV��w_t�!Yt{���v��p��s+���/�+i�L2��C)�CF�#w�O�u�7�:k�s�K�d�(�s��ʹ�B�ݿ��yS�}A�m�@Q>�d��;�d��t���%u���@'�U�E9��3�H�a����z�VZ>�̀?JDѮ.Y���_;��">�!��%O�a��q�R��:c�I�H���CC���Mk�S�^~�x��L��wG8�M�����;�
Z���k�2�0Ι}v��͊j�i�c��ҵ4�I��9��юW��Y�c�5��J��T����v�$*��~:tͽ4j�b��J�$�3�:H�C���u���a01t�0�݌5�}#�};��#�sC�~��`��H։��2;Tok�t�X[�� �߲����X��[�[�%�����<_o��Equ�# �(��(�ǹ��a��j�-Ǔ2�H����:]�'����*���jD ^c��0Oi�V[ȟ`	?�!��v��+���(���+�������es������K���}�Dw��6?�(�~y�#��/%=J08j���NI��Y�RJJ���3V�ؐ�gc��C/����k�15�!^��<?9�N6{g�*��V�q1��*�>1!�P��^IL;��F�M��}(䈺�A�L��^Q>U�Z7~���l��K�`�-��<|��5�
�=������Q�P'��G5��$_�]�)�.�l����*�������l����7Rp�z�9P�1�v{-��~
~x牼�WQ_��g��y�C+����B�+�F����Ku>�
e���qM��r}U5tk2�,}H/� 痼op�h����O�3õ|��������-Q{O�����S@x��E"f"��5�L�|�$�$ʞ�NQx~�@�[r�U[c��~Z�F`�	Uw�b)�yK�]��j��>C�~��zzr���隝�k~�X�TgNGp�ORO8�"A���и5;�je����Yƚ��vD�Q%�r�5:
zt	��j7��n�7r�/r��B;�D���2��r����e�p|������o�/���ʗfut�T�u�F���RR�oa-��;^[ o#�g�?d��5\��G`����]K�z�-�������D�r����=�V�&�J;Ef�R!� �1���@����N%[�I䆅[ÄC`mo�u�Wv��f��p��>� ����R��1p�խ�Մ�)���e/���bI��4��z偡��!`GO�3Y7�����7�������JV��mi9®�Ay`/嚿:�5�C͛��?��}���o���ln����u\CIК�q�	7M0�<��IIx������+�·[&�Yl�m�+t�U�a��W�Wc�� t/� <�����@�'X�Tה�RBQ u��_fjt`'�y�p�5�~)Vݖ��}K����0B�'��l1��4����9�V��Ƽ���E��Iݓ�f�O�h`�%�N���^�<��x�킞]x4,r�}ZCl܊��=?AH����W/8&�\+F���vL�$��Hs �Ŋ?�+۵�k}8����ICj�O5�s��]���A��"���K���BNw�w	��Aӧ�0�LV� �YFd����Y3�^��VK�Ќ ��_��Ȅ��6�1�!/�։2��(J�] �1!�"��W�p4#�	)���� g��-��y�z_�DPRil�������S_lp��&����&��s��@�eg�dc}��S���������H8
�#AQt	��Ύ�nZ�͢����u��Q�D�\q�um�>~�R23���Y]D���H�D��#E�oe�7���ˮQjj>�"6�@��-�4�D���W������d'����d}���r�}���XRu`q�c���Ʃ׃!d�^,�<�w|UŠ�P�W�4�g�<P^�ku��D���0���|5��/�v�RNn����g�!�G�_@��4
W.*��δΐ�
l�Vv%%eB�H���缛r����epnb���� ��N|���6�}3�i���1H�M�86b��[��8]Gpji�![#x�x�̵D�l6��� �@��&5@� ϭR�3�J�r�~0$�	;0���b���y3/W��@��$�#�%���Z��HX�8FH������=�?T���E�f�|Ǜ��3+�s�����4��V��)Z,*�w�ӆ�e��d0Oʺ���1�,.å�y�	!co�e�����q'�[/��@�-4��>GH��M���å� 
Er��Z"ь\�1�����P��	���ޮ�a�1�@�� �v�0V���� ���8x%�� 3!#��}���#��0A{Si?pG �[Zl*N-0ۉ�1wi�> ��(wN��lma�t��B��*sX�N��"Ix��#��H�׮_�@��=N��e�����a�����R��B��IU6�u�yڍ�z�j_�T�-R��-�V@up)C�d!��L(�� 񖣝���DMk.|\�Z���S���˵�s��2<�R�<gCg��*�tG~k0ޕ.wUP��`�u	�<�v+�O�"�S�F��Jߣk?ͧO�ﶧA�W3.�
��\��m>uc���Y�װ��/��Fi��R���_r�($D�d�~�xamy�R7*|���<3�l�}%|����}�]���AMF��ұo/����E��dq�à^�Ҍ��/��ڐ/<JX<�#O��S(8ը	�wN�A��zz�*�c��G���F)�_�����!DC�|ci��dW��,�<�:�g��!E���<��-n�k6G�������
C�J��6o`3=-��ˤ�&F��m�3-\�՗i�����o
�B��-]B*ȱ�Z�o9>��h�8�F�HNK��j�!�
vw�8�$vR&�f�����A����Ӎ��J��D�2�y��������k�Ι=<'�Yv"�)1��4Y���\ZՎC�P7��,��G'֚8!VY���#ꊞ�mx"(����P�kJ�Ly�u7u��,��]?�m��g_!�4q�з�V�*Jhn�<\OCw��A�:���/�ot�P�����쫦4?7{����/�|�B��Y< N�#��|;�?S�Fv��<�k/y���	�ҥ��-�y5=R�_�������X��x��-�������L]�@�5
�?o)�πP'/%�=�:��u�ī�� ����A��^�
t4_L������o��w�yl|�ċ�|$�Yt�����rS�䉍f���=P��נ���x�ȧ1.�
Wi��! 2�Q��BJ>_5E{�r2���WZ�C�hʠ9���ѻ��]?�vKC���� `|�ju �ÔV�~
��M1��(���G#i{ٕ���n����T�8b��r*�W�B�d2Q�rMQRH1�5�<��ϵ$IJ�*��J�&�q�
�v4&�kB��d�Ʃk|S�߂rG��㶋���?!�';�t/�'�վo�/��F$~��A�^��D>��
��յ�*bNr۷�@W���k���������[Y�t�4�8z9|o����>Ɍ�h`���df���W"��G�yY���*j������|!�.�^�߰���RC=�#�6���?J5�pHi[�M��z�'��M���W*�m��u"^�^p���׊��9�N�"��'�8���1i5��	w���e�W8֝����SʗĤ0�U�&y���4��_ˁ-�x�i���4��ip��:�^Ԝ�SYY-N�S���cR	��ݕ�4O��:�ʟ��$gΰv�M��)rVBfÀ�b����R^�=lʁs�Mo�:�1'R5����oU b��� �d��:~^(H����D�w�K&F���r:}M��u�*8�����0M�u�2LnW�~���p㹯M$��3�a���ҦZI9Z�UQ�B�I��>�p߹궬{��|�^�YxnW1�F����h~0R�y~��ш�ix��x���X�&.�?�o�_x��W:?Rfđ.rtCb;5�%��d�]�f}T�N��e�m �C�'��)b�����<�;��w�"�O92���^6����g_��#���T�͐NU�-]
=M��Ai�_`�`��Y���v�<@����4�	�9�ig�-=k�my��`K��[� ���K[P��\��,܍���/ɰ�K���Ap��0�;<Y$c���Hq/�ά ��Z���YEs_	]˂t�y��Rbv�,�D����k=�Ÿ���e�CP$��>9,'�jtW쮈�Zn!�L+/7)b�| s���ڭ����o�/���LT�ϝ(Re��� ��'ӳ��=�>4��hG�2��㖛ǁ;#�o����+��8�l���덆W�Il�.
��8�'�L�3ͫ1Ԛ�y����T�y��ru���A��[���Oqt=��:��5���9�H�� �r�+uO �Gn^vnM����x7B��dƒ�~fs�v}Ud�� �z�<�J���L�O���|��x�6�8M~/`�Q�=�8�l����-)��0	��″m�o��H	S�Y����5NK��7?���`�U�[ݖ�S9ǃ�@b��J&(�K��"A��$!�]Яx���яu�R)�E,�Aa��j�bp�ib�K�[�9��X�M.QfA4Y��`P�	�0�]&"�3��%+��V�u]�	���9]�JIHW!�=a�6��P$T������wu6��p�Jdev�s��h
Q�AU��̝F���Z�a�����8�Sc z��G����gCh�@�o޶=s��@�j"��Gu��̵�F�>���:�ql�_��d��C#���z
wV�QUo�-Vy���	6�g�3�
�(��lkr���{yZ
��X?��d�ď�&V�7T���HpV!����?�)-�6[gP1i�����9k�f6�%MCw$נl*�Q���@u�)t�}u�$�����}i���s���n5l��Ͼ��V)r o��+F����K�d�,��o�I�]�+�0g�y�=G���o���������U8$^�[��PD�S���j��좠���Z?�_}�#����P]����~?�G�{�j-+1b����Sw�n���F�\ʣ�H:�� ���߄4�ݜ [(q�7|d�Z���<�`D!� �V��墢��Dk�M�t�ZjV@�F����	�����ed�&U��5�	N�5XϷ��݊]$,�s)�uK�c��l��(x����H���������2	K0�aGَu�}	X(��'��}�%鄗�1)Ұ�Q�~ڂU�E�}tvy}�<���/#qy����dR+�T�q��69&p�DC�_/~t�q�+N =<�FO��
-�	�'���c/�U�݁[7�1ݣ��"�U�OnfMdO&����i��nB3���#��s��=m5���H|��4;3S�)ǘ�=�~pM(J�ȫ^Aq�5{k�M�q��xPD5dT����~���s���$�U�ͫ2^�ԋ`�Dlgi�����f1�wy�֏�l�'sbfv�٘g7Cr\��ǻ�4���)c���1^�9rn^E�t�*�	r�-��s��;%d��㫡���RzP��JID�-K�q�X攈[R�����}�&W�a|�s��-�&*�@�_�|.~dP��`N_ޫ�Ţ����x�/Ʀ��M#A�Lz,{/�h��К��h;��>a��x���؃R��e��%���v��%���5����DVO%�+����h?�HR����G0|����f-����fy������r�A��G���I���-��
^.�	�ff�+�,B����1
�)���	�u��]H��w���I+�ԕ�8LZ��B$-vV{8�0$��+~M
�',�s3�b7�����pJ=��B�o�)D~�Cv�����"Vu?n�����l����+���Ȏs��R�Ո�U~��͠GF̬����  �=`������ȏD��)��^�aO�6iW�rO�܎���(��h��cB��J�8�Hc�|ߗ,@�C���D>l�c���"&�4���4���I��+��ѧ�*!���gփ[ E��q�N���y���GI	&N*yF3�T,�fW_T��W)�!4�^Z�1�s2�E\�K�����/���%��i�i�m���,WD�����[��*
Q��n��=$oq@@ 7�I�֏�������z�	�i�y������nm��rPu% <q�u����M��H�.�F�m�:Ub$|�&MS�#���@$sW�Wqa��M�e��Rš��(��ˁ�p�� ��/5v`;���lkcT(n���"�SK_�^_M��S5?����7z�?�׵x��;��J��u6�PZ�1��,-Hg3��#9�Eh"
����)v��������^�8��|xh���E@X�7s�ۛx���8H�ҁ�/��8���ʡ��wo��R�˝�>[Ѻ�V!��G�x��5!*/⬢ͬeS���jo/�3��z��F�Ue�KOz�O�ݼ�����
�:gEsH�0Qt;<i����7���`S��kFi��%�g�.��2�zf��t蠕�&�jéh�p�ۚ�uCFQ��Dٰ� quP-��ǧ������4�A�M�����L�����e3�PR%)�Yߗ����V��O����R%��U�ف;u�w����+dіQz�#?�n���0d1�Z�	�\�is%t�JFb�PPg�G�ǰ�����i1�ha���vTZ0�F/!��6BG/'�A�S�&hƍ���&�H�Hg��40�f�vP2s1\����B`?����r30�W�Z64���ɏa��ޝ[p^��{OA�A��`��n� ~t�7`l�c=�sE,�$,��::{��v���oi�i��KT�)*l`q��Y�?o���{��W2Z��:�*n��~�����A&#MP_�A�H�s�2�F�.��eOX�K��u(`5)���%R]��f¾��4 '/��d����V��S���0�>�ɮ��ds�p�GR%7=@�����	6Tm��}*��Gq̫��xjM1mj�%�5��Ǒ�6�m�ѩW�CyH"�X`vjĶ^i�J��f�f�c\�jޝ�IT�������x&�K�g{�ZB?�H��T<���;�҃L*6{�j=����B���[7�\��'���^X�c9T��ӳ�;-G�V��UZ�
��o�b�v�F �
��5V��F�e!�+�ǽ�7���S�z�s�y>��;��(�V,����(6��m���
p`�,(<�o�ˡS����JwJ�G�lka0'�Ql��|��.���a��5�[	>�N�����n�����'�T�rX��:��"�Rh܁�����1V����e���r�����1�_Ϸ��F1���d�A�f>%t���4nW������X�&a?����s4�e��#����%|����چ��н�Z{��h鞗�~=2s��K��δ��*�����.O'Ɯ��kyާ!|��8P����x�rU��4�Y��Uc�U���f֪ю�k�g�@�2�W֣c$�L6+pỔ�ٓ�^��fl^�I霧��\g�f��i���Ms�v%z�?�F^��ݦf6�<�������j���{l=x{����4�-Fʴ�U&�v�l���8�M��޳�6'�@p��������楑��\��g�+��G��pN���ҭ��ߔ�������~��H�G\�r7�9⢥Op���V�m��G��:D�u����9ս���/���(��}w��_6Y���)x�}�7ʵQ*#��(5�n"��)v������i���:������u� �\A��r����#cR�?��i�G}�ޅ�?�y�5wG\�2�2_��<�4��Y�nD�?���z�
�F�l��Ħ����MQ�W�(�X$�W��\��)�z�kU�ލ����q�RCo-����0V�|�HV'{b/,3/S*���`�>�J��|����xD����K�F`]Đ�/�,����49�W�t��d�׶ʟc� �@�w�F3b��ZAb�<�KA'J�%vtS: �%��_/V���v?��甕jd|���v����U�oõb6��鯤��)Z�C�ʶA��e����mp�*jH�g�l] ������do�0��c,$��(�zDh
�<��`WW��iN����4J�2�{e{-s�)�?�Z�P�s��S�.�����;NW޿H�'6�s�Ś�V@�7��5g2�U~bEl��~&����	%đ��I�en�X}��a^�E.���-��Z8*��W[WĲ�~#�jݮ�e��$ϵ�������D��6�$�R�|�ϙA틿w����⑶@�#�fբE*���?b�����
��
�>�O�$��sx��֖(��6�����Wr����	��-4w�����$�(��Οh�<�f�g&�>t����1�ar�q|�0b�*H���N�>�A�$����n5z�@�޷��+y�qe�d�� �t�x���)I�Z��T;R�	�?XX1,Bz� Z���1�s7��RTRO�M2���Dǅ?�'p��a�@f������MP���m�[���'����̀C?��6�㙘f��vq��Y�Y��.S�!5b����R�G�� q�?=��XЇ�MPc?j3��-���U���M���N�$	W�v|�q���̃��xLs`,Li谷��*���0H[�ab�S���h��e�K36�P!�k�}�,���0.�YԫQ��/�bĻ�Zl���k(���{I�������B��`��f_+�����=W1��%�i�;�Xr�h�=��
J�����G��S3�Q��:]-��wN:�J�8_
����ƹB�!;Af͡ �n�O6�:D$���h�'���S^h��?�s�>#���H���c���I���m�!H���WI����[1[���E�NN����~�{XQ"��ۖ���:��W�_(F�����tMV���j����)�c.B����]���`~�/�{D�.�1�)�$Zh<h�z���/<��dbs�"?I���ź<"t�����'[��g����DYa��J��Mz\�6��ݭ���~nյ�m�&@j��(H�Px�C�!�E6D�!�M������b��J��]�~*�>�V�]�	�E�B����*�`i#H<m�������Ur���2LfL�!�Ⱥ���O!�IH
NF^�*�i$���������}�;Ik� ɾ��U�z37I(tH���NZ�P��<��D��K�\vqߨ8����7h�2<L@g��,��'�\zV�R�&�Z!A/&j��`Jя0s��W�B�SaDX^0b�� �U�ӓ���t���̫DC[@�T��Gߨ$�*����ɔ&����|���R��v_�'�����CT}
�ۓ�����>��' Ou�[��M돋���q��`
���=�9��,Z���0D��s\_P�E��w���P+ ~��}�N %�/5����3��N�pj�U̵�f�=26�ۦ�ى�&뙓s�;E�6na�?��A���os>���p�_�ӈ�H�8P�o���A�uslr��j��<Wש/=�%~*YOB��8�U��%H�f�]3\��Ϩj �F�/��v�.������Ԭu����SU��w����M��^�D��k���㵥��f=
^S�.>ZK���{.5\`�IO�v���%W,�I��0��{���bNB��k�I![ɪ������D?�W�$LKv%�}�k���Z#Hlײ���������6���Z�K�:>M�{_�!����A�6J���^����
�ZG��:���A�p�!�@��W8i"��T�߱�T9l��K��&��NDo�e���i�ᛵ����ӵmsw����v�A���Zu�F���w�|,=�4Ɇ\!*�]�"�K��4l�8� ��H����
��'hc��h:;�����ӗ�E��B����A-&5������ �����#T(�{"̶�/�Z�v�LRL�l+��Ù{6�ݳ��_����d��p��|-�b�|�~�
��;��9f���F����
���<���6���n�K��2�ސ���o�M�P�ʒ,J�ڵ��8�܈{��ۉR��.Eϡo	NK	b��?�n���d�/��	^��:;��N�D4�SI%�88�dڇ��`�n���V(}�D�;M��&6$�l]���}\���;�N���e�Kܕ	�����ި.}֥P���đԛ�?G�V��]bip��0"c����Á�\���%7&�S��۪��vK�p���v���>��?�7�_���yo�>��$���~_������[&��S�$]0p%��Qd�{^m����$ �vO���uȰ�Q�Q�ӏs;�>��L��q���:�)q8(`f�����6�4�2��t>����5]Q�iX
_va�<��&�kUک}1�7u��OFj�-�hU�?�-rW�����|������7F �0����_EJsqM�ڛ�,a���*ո4?��I��LM}�g��ߟ$;�Y-_��k�e`7 "��;��;���eD��X�=~���3��!Nϕ�����e���|�6�v�UW{�O"V�]�Z�<�O'b���C�Ir�i����RXg��#��{�wac�Y}PgW��!�5�6s�}D����M�dH��!
`�4y\:��=���
��fլ�NV��Ø����̙�n?[r��9�����Q�|���ow5D���@[<�u��#]��^�\��G��1�3#���wm�K�4�W�����8E�6C�#�`�/�b͜� )P^R�w�W�G@������K��>B(���A0�#�Y�@��<RA%�7eړ�.��t��R�RQH�ӹ�K�ia��r��L�{� �7:�/r�e	9/���xV�%F�J�Xc5C�y��*�y�7~�R�r|�+�&1����+?�;6�0�W����y�?�z����%���*��M�]j�s�z 5�JN�N��BUHXq_�z�wz��-��@��&����i���_�9M�u���])B����,r���-(�Ah���밁����ԭ��"\�����r`M\����JG�Np��M����呶���i��`�1���Ssj�6j��@[�@$�|c�"��������EODu����rz���}�I��bQ���?[�nڼړ�rMhF`|�X��1<£���$�t�x�L֝�uQ ϭ��B���zOl���A��U�����P8��@�ɢ�C8i���Z����jIS�=�4P���A�E;~��;���G��:8����h'���1J��7įZQu'P2%G>w���
�R�{�]H:��"d�����?*�%Y��n�/�aDd/��� �� �OMA}�n�a5ׇ��� I49������l�pN����z�����ɴ�2�(L���aR	���h�O�i��\��8�Ro�e4o,���ppE�ư4{�K���������P�N�Ȫ�^�k~��^���}�V�l3�z���ݼ®4�[i)�!҈���0^gƫ6�6Eu��ꗇ��v։o�C���@�� A��OBק8{T1�G,?������c �\
x���?���@�> ��i���4��V��+��l����D��]��c�3�qz7Y��J��$��~����͐��?�r��`{3��3ݑxk O���B�M��jTr�Ϟ'��J��S����K�W9���d�}V��}�^·h�v8.���3��N9u�O�B3rY��xM��QDB�΢3��D��[��/����]�Vjm�w�[����+B�`\��zk��j��0Gh�Q����/YX~z
,�%7K��%�mC��i�)f���N^X��]C�so��J�mË����y�c"tT���Uׯho���Z��N�`#�(��4��	���/�閞��p1T�j��h
3|a̚�Kr�~D]Q
_"���;/ŐRH1���r��z e!x،*�:��0W��T�E	�x�(�q��C������7�3N���5g�ױg����5��m����\�kR��iƳŝ�����׀g[�ß��-m򦑟����b2�T��������������\�F+�
0�O�?DK��6�WnӶ�=�W�q���|���&���N_MG���8�k�q_�6������k1<��ޅ��Q������y���� }ma����Lo��i�5�,6[�=�<�Kt�ҹ�N� 	AJӅ0�� *^~l+
���уϨgl��mOt���fd��ⷡ�^�C���X� #���������i��;@7	W��ĲF��%�m�؝�z�o,���<��ܘh�{6��±؇W�.��wS��-��IO��%�6�W�0��(�3�@�`��c�;��� j����9�" �m&:E��} ������I��g�    YZ