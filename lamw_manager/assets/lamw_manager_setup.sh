#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2434408727"
MD5="4b9be8dd63f21505c772efd35d8f6979"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25672"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Wed Dec 29 01:20:59 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���d] �}��1Dd]����P�t�D�#�M�������mj��/��"N2��^�Z:��y�4���tpĎ�.�M�eZ3��&b1Q{�d��ь�����=]��x���bXb^�5/�N�uUe�+h	���: FQ�zvWx�����r�J�N����O�~��OT�EQ��&���S�B��j��1I�}[�]��x�ia��\`�!p��� =���;�y�����%p�I%ikm�pZE@��0A��O�d��1�<Vߙſ�{7���ɟ#��-x����G���^P�o�@Ja��4yt���%H2R7���y�Aƥ�8#hM]�^ō�K(k�u�p��j)��
�3>�`��i�J��4N9^@���!W4W���,�`��&x�/�P]�ӊ�-a�����v�d
{"��H`��-��m%�W��i�������6��|�-�I�?�6Q2C8������6J� .I��iL��sN�����w��o�sHj<k��ؠ��?�q��_�_�JK�!4p��eg������y�+�� �@>����6��c����ߨ	`���X���hV"��	4G{�1�B�
ո�L�љ��W���Ɫ�����\�av	Z�aue_a�>)m�dڠe�8;7�'�x?����'����qS��y��`@0탕�jy|��m=NgBPo^��8"w�^�c������F�o%W�����_�|焤y^�4��(�~�CAzn*v4�lf&B�N��ȫRc�v��MBhIqҗ��]gN�T���c�\�m�LN��T�6�h��ghM�?-|������:�	�K|X��K�1�sT�^e�s���� uF�^����shusTB~EƉyt�<�<��Ce�k�[A���"�R�x��;_�\w��}Y1�����.����k��7��Ę��ؙ"d���
���/Y��9.��U&ex�`|�G5�J�
���Lt�3�/.4���Ч��e��*�.p�/��&恦"<ި������^Ė�)���,��tfS&��U]*�6��^�=������A�,���T�׷9P��RR��i���#��m�vpRϻ_�Y ��v�L�*��� u�u0�שG\r��V� �|x���*[0?�n������G�ِ���s��1-	��%�o�S:�2��#������������!��j�4�@[���s�"�C=o�i.�SAT���cݾ��<q���#��e/�n�7a� ��H�������1=�0=xu���1BxN4-��|}x1u�n!��L�A��O�^�������?�̩����ܮߌx{f�
߹B(�������}BU�C��n�򦣺��L~*S]�4�7�dN�_Q�_���i5
n���/��g!H�+��ZXV�`�q�w�&?j��\���w��N_�J������[%�,q����]mRRw��İI�rf�^���Nz���hV���/u-}��:
}��?W��fh���g�#�.lo�i(a��ھ�x��Q�2�$&�uF����֡#}K�M��툆2mO�h��ɨU"Y�[�����u�?;�������s��S�=e�s���,6��E���Sy9yDF(�8�F����L,tp�g���&IKI�'�!J�ih�j�=�gUmYBg|F3��L����W*IcPU�����h wh�2��� �(��<�V������9}S��(�<�pcS�Tb�}�ـ��5�d\��{��{v��g��}�&o����>V�ʔ�ΘP���x�Ξ���y*H�ð �'�v�<>�_���}�p���In����,��s�Z�����)��d����o9�M��l�}"�	C@���ގ�_�P����_�%�h~8t"�M*_&X��9"��K��
��n�`�2Ҿ�i�"[p|n}a��$׆��T�_�y���הad�[�������/�n>�Q�e0��׻#:�o
Cy@�
c��QR�ϣ��EJ���aP�ƾ۹�F	�[�3͏��X) B��e��O�[:xdԣ3`�����y���k8Ij��q`�c�L(�:
5�;W7 �p�}��� 
�xlG(�eH�5L[���O�%�+XןגX�S�M��lo��� 0�e���4�e)��D�P�g��5�z
�+�^���'.��-t5ZS��/\���A|��3�Vd`���z%�0j�b����Q�E�X G2N���A�Ö�3H�\������0	V3���	�O��P�F���d>��0�3dZ78�䇍�]��=���䒳���&	Hl�뾔��G���3�?d�"���у��$�+�'�S�[��?�)�
�تX�C��t�Iq�8�����3���U�tyh��Ɨˬ^��޲IRHZ��l��<CĈ���GGƴ�3�����A��E�,R�(�Z�)�ц���%C����m�A@��YȅxR՝qi'R�V�@N����<M�\HCR@� ׬�,�p��!��Ʒ>�<A��1�@Y�t�v$�C3���^q�А>�̖��Lx�\Ϭv#PH��%5�9�Y��۷+|�؆yh�S�����@z��c�q����wr�!=]6�����r{�=�O^f��c�d?GZ��H�q�X*�i���5�-"�t��[)ь(�(r����V�����O�� ?`��I�Y�����Z]h9��s�*�=3f�+E�ݳR�V�}��Cot�#eü��/i�{S틫�	��>��}�t�ݠ�Y0�X�o�J�э�M�8N�*SB�=A����&���&N��B�Ds��>��S�����]���vhS��z	��������w6;���ő�E,#�jN��R�"�Y�D6�N9c�!Z��p^��w̒3�1�a�TBA�m���=��!Ҽ�<�7Nx�@"�� B����Vg���?�¯O/3`�~Ô��5B����ѿ��}�<�|΁`HݫdN�9�+;���d×N�'��.Ω+� -�����c7��m� <l�i�D_�m��f��)ś0I�;t<�}Ҡ�<'\�mO��=G�}��D�Y#k��昍����]��gR���9���/������q|j0��}(�~	�n$޻0��TD*�
{�2�`6GAM�Қ�N��f~8�|6.]�������M�_]���62!�@܊��v+[��x:�6d?r�~�Uuj0�����|Ms���݃����^�u����y3����n�[��m�������8P���׏�3V�V��L|���u���nRHУ-$�E>��?P�����K��{?���|ǉ�؆	��ڐ4^c���Q��j�V�UJ"�cǃU��X,�07~α��H����Y�F�h�ٮ�?�W������)�������H�8'�_UP0cۦ��R�,3N����`���Y�Gy�sh��H�G�W|��kڿ�e���(���،4U��c�t�3p]A2{���9�]R�in�:JjS�+��<2�i�r��=�'{h��%�\ï�*����up��C~�Bh��炳���`�V̍��Ɯ�k.�i�s���f����� 1΋wA2O��F�˧B;.�z"��v�a�ʡ�q�"am��N�E��&��Mge����y�gr���[�Ќ�"�U��e�$���=,�1����oG/HQ�<�H'�{~�3�0
2���VWZ���mN�7��,���$wYw7��>�_"�-M̿Hƹ��	���q4lk�?�ce6����r��	sw,��G��%�}@Q�ҍ^�
qDBG�Ouv-r��	X��tےE���N�t<V��j��7��Ѕz�`�� ��7�[R�r�q��v���,�������c�`�5b4�Or�e�a��. eoAJ�n���̖�<nC�����I\��8z�L��,�7!���(/Tа;��K�ژ_$۵B���0~�X���[|�֙z�A���d�
���,_W����x��|��v�; �Xc<�LT,d�ŕ@�	bf� �F��F����z8,܉&���
�ZH����F�f&:h��U��]��tm��f�%�`?~���v]ƆS�1�H��oFė�����hh#kP���L��"��I �ߢ�&�\�'���V���ݒ��_����B�<��&�QS`L�P���V�~Ia���K ��	��N�(�mxս�;QU��=�k�O��P�����ģ5�9x����N%�q����޹�؇�*�$�\���`����ѵR Ois_�ߣ>`������m�&m��&6��Ϭ��.�2�* ^�(b^@10��'9������s�E�'����_��������%��g`�ػ 8b��3f�Q�0�P|k�x:p+x�M�����%I4ue���"��b���S]������|a��#�U�6�3�r��yJt-|;���<���a4O�M��G�&�l�*̤�N9�ojȈ妙�Ad=�X��A���R��lYIO�5m�a3s5J$�V/�U��{x�B�B&[���r	H}D����gtR��{�f��ͩpQ�p�c
3X�e	�G'V�0��a��mτ�6�!�ܱY9g��k�B+b�:��\���n7��(������'ކ���*��� �8����▂�-Ԏ�8�2^T�y���`�]Ȣ��iG���)L�V9Yd�[=:���oeH���YW@��q�,�X�[5��ٌF(p���s����&���! ��C�x/[O6�1��64�C��-����[�P���� ���w)��-d�/�	�����g�0?7�1m�ĵ�_�h��˘�:caF���i���$y�Hhk�C&��Fo����:�랑R���c򽏚�k��BA�t�B�X���^��ی��$�6+�&�������� �A*����&�z�*�L�k�Y�J�a	S����L/���_����x���5�CrR7��ߐ�(l�&JX�]���
��y&=���L�y�$�D}�;dP�K^2�d�K��m�a(fڵ���3�
֋yK"��
C�
����_sF^���+f���C[i8r�g@_vk�'D �KlW�p�;ó�xI����Gۮ'\c^�2���A[� ~(r�p����C�u�`sF�������I�"~�cq�ݟ��
=��~!�G��S���M�v�ɗ�����.�F�=+�Aw=}TA��S��z���̀�"�2OJSw�՘pԞ$��l�,|ع��~^3�HY%���{K�
�$2m �I���.�����x�0�{=F�}�F7��N0L&q���)_�feˀ��~��A��>  �׫R��6�@d�lѾ�iJ�\��җ$��9mh?@P�+��ԙ� ��ޒ�T)�M�|���a����b���v��jAK�l��u��D�V�{s͘����v]\$�* |>��D-@�+��I�Cn�����KzË�
 {݆+�^)l<�$ &@.Ke_�{��T��8�_Ӽ���i��u�J�T�v�O�����W�&'����_����Y�?ې��B`f%���BѥZ�u��̲��C����͇�����u1�߾��^C��u�!pa�����͡آ�٥e�uS��R�����^����g����,*�E�W�KtX����H2�~��("�]T�?0�$C+�� ��+����N�(FX��.�e�A�v'n�31	��SL���C�7f������KCo�v���|�1�F�.q�^Z����%�6�9t��5�`4OCk��s)�Ã>9mc>���RY�Dy�jTS���E"��z���ה��[[���ZI��ī~pvj15 s�zlH��n�y'޻��NGѮ��2=�Q�}K0��M�,�����H�e��H�lq�(�`	����N�eV�3dV�g� ��P��8x�֤]�8�vj�r$~Mi �����>l}�t���Ww�Ωv�K.%t�7$w�yq[ᛦ�l4�Ł "�f ��|�������y��̬dn�����	@E/��m��N�d��3���T�'#qh��$��'؈�>�S��h�3����oU���k#��$	W��*�K�MJ�]��k�~7.K>�k�W�N�i�K2U�r�����?e���k�m����2H0�g�/��7s���	W��yU�yx�k�?h��n���r=F�S6ǿ�)�*y��Iڝ��)�F�/�w�*��;*n�Q��p��r�����j_L0
w��InC�?\z!�?[γǢ��0ߋX���N�!*�sʧ��2~�"� n�[m,h��������.ø5/D�ym]�7���1e�TRE>���Xh"�<1�xA�hKԚ6maE�� ��2���'���Uq�"��6�:J�o�k���R��D�<٢4s7d\��F�҂���b�K�������u��rb/(�X@️��S���v�CL�NQ���{�$�pg�&A!�[�b@S��C�EP�k����z��I���e��������/nwd��N=���}�ؚ�y�D���=';m��<��}��u:H����Hv4�tY9�� a�~�Y�{���n��L_��ƾ�ft���������DL5�쵀(k���"�qׅ<�4��mj�t��kyI���R Ga��n���gmC��� � �@sFU�>����ƣ��p';H���K?�@����a;��]�⯍�l�c��"�/���8;s��[�Z�l|6�
���$�����'=������!Aa^P�u �G�7��9�2����@#?����6�{��_N÷}Wx�����`�m�K+�p/c@�s�:�E{���Jh?i�U/Fm$G���_
�����JݠN�G���!=\9XW�'6"��T���'�p�S���ɸf��>r$�<����`��qz�_�O&�xpq >z���{�о��^�l[��>ӎ�$��"~��ӛx� ��>���w�D��+C�<���C�uk�����(�Ԫ!�{�����<�i��K|ر;�L���x�1YK����ƶ9ݺ�u�$���h�#�!����C��:��r-�s��,-�I� ���"�`����S�s���ı�����֑�Һ�F�,�)�/��m
��,~��NL��ɕtLN;H�o;�`�JR�W�J�ERޤo�f�~3 z�s؋ �d-���:xCG���0��ת
 �9T��|��2J�
�LC�B��(��2��D�l,�*x�N�Z�Xߢ�[i�3o5��2]��f��NUN���W��V�?�<�:H����T8���ݸv�͍h��n���2(8"`IosJ��t��!]�b���M���w�Q��qn��^_jf��V��rI��y�j/�2�LS�9ȏ&[�4�Mj#��˩_'X�ϓ�L�^�9D~Ƞ$e�}�eZ�~^IN���J����D��,8+���R��ń��3>�	{���{����U��!U�#��5��
��e�N�hF��
S��]8�{�މ�\���?s�:�I��9b&��߇p��K7u�0�Q���'�'�6�ML�d�®�D�a"A.t�L�.�\�q(��^��e�,◦��E9�I�WNR2ˎ#�W�O9F�8�L{�~`h&�u�us�T�^=����SL�g�y�0�!E(����"��ْq`ᅚY��Q"�-(F�(�9�{�9lb��b��}�-!�Μ���P�G�@�p��m�۳+
�.s^H�LO���Y�y�x�^�������f�������6p7�3t��� ��X%@eKX�;��7�N��M�q�{�d���_���B����7UmD2�K�g&��5fY�饔ʴO_�!@�q;�����C��L�X�	)��+���Ā�):u����T�K0c���	�lL�	�W~!�DK�?G=����bX��G��R̊"`�w..�c��R�!�b>�oɚ��g����.�e%
��G��M���'�ASU��?�'�3�a��x���(�Ǐ�I��
d�����)bML��6����N�K�J&�NhM���M���K�I�9� \ג���ڙ!�	Ǿ��Xޖ1�m�ZnE=���u8���������N�@m�8%�9���@�2-��ёY=N���I�w�ƹh�gW
��\k\[Ϳ&05�����z��`���ѣ������Ŏg�㵖��Vz�^ֹ}K�IB���}_KK���^���%��欟��J�Ӌoh^;�@}8�\�r�wvO%$'���o���n�gÕnJ����#W��_M���y3yN��AZ����7Y�V��������������>Ns7�	�M�m�:���v����[�{���Lc�ڡ?���]�K�(OY)u/Uv`�����Β�7��$/�'oM	��L{6I�Q�*o�����^�A����X�]c��DQ�Gp
��a��ʪsF��W��>~Br]�ǲ0�t�) L��
NﾍC�|�j�-�Gڧ����Aa ��Y�e�{�.4�Pd�����A�y�/|=�ԙ�@n���,yH��B�-
%�Ġ��ЄlM_k����.�
!J'h��wv�:�O�C<ԗ�iር���A�Ƶ�D���q�q���Mc8����4�E�?��6�r[<���Jf�a�Jb�L�=⒊Tw�U_����1��oF�9R+ؕ��� ���1����/)��x̨���!-]�H�
���q�h����"f[��y���T-�=�G�E�JZ�rg^�;n�=ta�zv�L��v��ja��+�W���Uc�A05���� y���T�a�HǔKC�e\��������V��qв9�%f��)}��i�&0D�0T��;s��+F�GTQ�a����tpnd�<Qp���>����.:7�����#>��F!��ȰyUm��)Ӷ+VK����|��x�>;�hU;(t��1��`f�w��>rQ�;��Z�(R]rJ�~iU���
.3d���<��/A�E=J3�D�0�S���ߒ��j1Ӎ�h�fO�����_��s{gY��q0Ơ��#/\�?��K��o�l��z�o�2��;�F|2"��X[t��>pT����������V�v�(��a٩��2I4zl�W�	�75v�����z�������ū�����b���G���/e�d��؏�m+l�_GC �4��V�ߊ��&)��7��)sF�p�x�I�u][08YwÒ~� �˙pDba��0��`T[�*���W<W!��BT�׎ͭ|ϻu��PW�G�����U@����9��;HDI�qKȎ��H�Vo��d����j�<�)|;H�"��f1a��o__&��ec��4�g�u�E��Z�a�Oم������ĩ�7�HK�$��=X����� �J|Ieù.�gԼ�F[*�3���-Y�+������M���)���gB��}��^k�ۣ��-�s���L�s1N�\��4�r��W���?��ʽ�_9;��&'�$�M�kn!��K��R�30��-iF�G�s�jC��mw<;�֠[t�0Հ|��axM�r����pn�n�ђ8x�Q��v�'欎����]�d\~� @W�N�@�pW���Z~�+v��\/*gƙ*������v��u����g~:S�T�홨ђ�8D�S����<T�:�8�{ �Y��.�<�}���Uُo�pIƴ�ӥ7�ل���PDeW|Vq�S<<e �,����!.vs=X|�qT�-���T�.\�~�2�eע ���:��S�l+:�u�x����v�?0ӫ��V�N�D��?!�I�jj��H�@^ҿnɜOrl��� ��n1gg�c��@��v��kj��瀞?��>�t<?�Gd���R�>:\�}�_9di�^.�Ct:�o笀Y��;�`K���Vf����d�����>N����M<|,�t=�.��ަ4�i��K�3R��#�W B��a+ b��t��%Dh𲧢��v��'��&�����*Y�����qF�-~��Hl量�:�9�3�[2MG�%C���k���~^��'�m&����M؆DQ�H8�C`y��1_Ŀ�L�Zu�m�D�A���@v��P)t*I7	w�#���Ǆ�-�)�)��y���'�&�������>�b��"rmF��!)<q�\�[ ��w�o�0�2�&�����d�C��%`�g���a&P��ܝ.��Z��m%��,<v�@��w���7��5����{��~����R\;���,�uY��p�J�r���o��F�]m���y��\MM�������(IL�1(C��d�������_�h�ŀzt�o��
Wr�zh<q��;�]��ق&>8����0�Q}#a��&):a~�K�|��e�|�z�R[�K��6aڲ\��C\�+i��}f�t�h	
�?���фr�����H��;��vWlE8�Ϡ^A���%Cyo��?������J@�젔��Y��v���P����/ǜvIg��4�,�Z햍'�4����57e+E	>b��[��xX)q�$����O�mp�B�����hHQ���i�H��[Ҋ�sfo$�1�rA�
r��\}��⒦�f 4�.�R�A��ٛ�L�`Ld1w^U�ꘜ��"�?�I�d�?��Y �ki��4 ���Y�7�"<)z݂$��C�
M# ��0:����P��j���M����5%�3�g�-���"L��X�Y��L��?�
��k���Th���u����`�ɸ�7a�u�#Xe����~T#,��#�t7�D��bN�q|���YӇ�?uq��6�o��l�5� /m}͞`B���L#uTg-���ա��7�S��TP���{{yX�-�3�:��՟tq�pGmg3�ӛ��
���_�U��� ���~_�T\�'Xe�7�����l�SKj����Ҍ��|����Fmpa��/�m�qY�lp��,��4#$��ʧS�aa?��]ѻ�k�����F@X=�L� \��ѫ�"=USiow
-��O0�0��q ��e~N�UzSz�B�Q}��!��P;H|C�����F{W��,}��VO�M�����N�c�+�HucE)k��h�w~���:���H@�H
L�j�4D�*�I1����@#�I.��f�ף��*J`^�*�/
�e���0��td���v�{d��e�b�Ń9G[L��hC�]�nY](��������!-\-��Y���B�^OT���$�kD�:�2{w����O~4���;�Fv�m��p�6ǭ#�\C�'�5�!r�s�s5�+�j�*{Lɹ��V?!��F6��~<�O�;Ⴗ�2�~�=!����M�9��c�:�Zom�_�g��1�Y	��YS��0KF��sD3d�����c���25c4��!�B�q�P�;xT�����YB�'1rƼ���J������.M\_�Jр_{����t��:��G�B�c�W�5�m�p���-0ӂ3r��N]qc;�[oR1�m�A�";N�C�-qUД�ى�ʼ�����* @u�O�J�Yyn���ב�SC���^�֖��:�@�Gdy��nN�s�ɧ���=UQ��ب/<=䴅lkkB ���?&k�t���͇ǽ��b��z��`C3�ܬr�p�d�@�J"7�i\�V�ۑCl�t|�搑=�B��㺳;�i�$�Pk� j��|�]����̶�%�ǥJ��({��Z�Α&�Q;s.����I����q�2�eVq��gt絰M�LV�K�S^I���_�u^3Q��F���٬Klg�)f��8�i��0���:��|�zv��A�~��Զ�������3Z��ݮP	�����>Ѝ�F����~�C�G� l���	Jb��	����4n�ƫa����}Z5�6P�N�^�n�R�n���AH�4b;3j�}Ż+��"Qe*Q�{��Xx��WĻ�E�h��<�i�v[���z*8]k����lO�k��$5/�o{���ڞv��-o����p���ie�.�n�Ȥ���,s�6�� ���!n�G$��މYt�2W��]G�ћ�ŋ4.�n8��w|���ʹ�A>�Z��Ʋ����u<Qh7����c����P㾺6�
�d�5<�]�|��[��70�<�}��w��ko�HÊ�|ge�R�'��1���g��RA�xJ��G?z����A�m"x�O�4��Q7�@Ux1����̎yj��|�_ч�o+�}fI{�&=w��
"]N_��h2��̠��ڏ�TCWF��>K~����?��*�	93�~=��a]��ˀ�B�|�������<;>x�JlU��^v~���|�J�0�k��p�{\�:
�M����7�H`�]|���,o��78俣��ƛ�ݣ@�.F�Ń3+Mۊ!4�q��u�@�*�n�0�̉͊�?�}?�c2�Qm����I��`��e�P�Q��@��L�&��y�S� ە��8:E���y�)3�1�T)Xl䮂����G0A��p�����^�`o�6Rfn�VO�F�ɘ��*v�һ���<e�EZ{B�'�IZ��"A��r$�����I]V:G��^Af}�7V�xz���ުZ%���Vн��8:�+t��>���G��$��m~Cω*�e܄��Y�h��XB�1��4�*��S�)4�F�5:��E �gL!�-�;��Zš��l��Uβ��i��8�$����%"�C4��z�bpٶ�!�;�<���ۦ�L�W&Ŗ��8DzHй\���{��!�ە苤k��z)C�*-��9��aȰ�%��y_֯<��X����N��n����F�Y���� �E[��Tc_���V��fR���e��K$����0 ���JV{j�W��a:r������efaоv�ʤ�I� @�Sޛx�$7ʢ�G�J���]�AJ��b����X��H��cԙ�"bZ�L���=8��mrO�9@N��64?�
b�h���*C��\i'e �[渄ZRD"5Ƙ�,�����M��Wlz��c
�b6*�"�ɩ=��^�/.٭��乷�ظ ϔ��4q��5��k��'6.�J�s�Hz�p�&~0@����2⌝Jכ���e���Z��ǜ0�:��̦�2+�:P�&p#�E�$tR�u��$��7����S��
��u�� ���Y������y�c5�W!z������6��[m&
Pa2�>f
�k��s��H���.�)�~i���=��8
��!�6�"�H�$�
�B	��²$ة���;�#W�����l�w&�Dv������2��^�oX)�E�x�4R|�j��08�Fȵ�\�� nV#3�f,�1�m#e'6u�ՈP����_39�uy�ܶ3��.�i�=�(F�lU���`?8G9����2�n�.LAܺZ��!�׏DD,��@�>ޝ���w�= ��㻍ax�k�M�h75n*�l�r��&m;�FƄ)	�m	�K���WE�t��d�t�-��M�`��xȏsw*r�-a�{M�S��e���H��Z�w����'jL:�i�'e֠7�39���%����(:&6�S@1	Ԩ������jF�O���}#jiϫ�:�Eފ7|d2�i��N�wk�U�.JJ1��ĝ��H��}i�����s��4��n��1X=
�Ea�4��;r�����5U%����vƑd��W�g~����-��V��/�v��r<�r��g�S�t{����R�q��� �����4U�-���Ý����c>i��|ԛr�����Ϙ?�
Z���p�T]�A���#C�Aq���17��Z���N/S����|�S;��0+���`EO�w�xc�^]O����_QaEF�6���\7��_�%��>M��Rĝňı��ن�	�b��Uv�����1֫yCc���������UX�6�o>�)�k�����k�4���sc�+*�NLY#�k�o�:M��G�Ndx �]������ĒW�A_琻AC�5�q1N�:q�����E��q+�%%c�6I�� s��E�|��M:�������d�!�M´���Dv�=-��>�Fw�'bwy��Yn�"
��l�=�T�Xp��rxg)
���*��q_����?�!P�mb]��z�Xg���RM�W�CnX�h�+������M�W*�b}{�ZV�FȄ�/C"[�0��v�a���
���K��_E]o���< 42�Om<�*�I8��kK��J��&�'ꌌ�u��W���q�&��h�	�{8J ���iTg6�;q�JG w���%&.=^�OI
�,o]�6"'⭀A�mvG�4�ex��䍞|l��'�A�.�D"6��%�3�7��;8W]"ط���y�I�<;�,^>��h�QO,��I���~|:Tے��l��
���f�Wq�[9�D�~�����.	���'�0[\�c��PJ:Ӳ�l�+���>�X?�4��U8_�
����W���ZX[M�tx��-���T��B`v`N���(��sC�� ���lD|�W��H�zR�]݁��_�R8Z�'QC�l�,g
wr)�ژ�4�O����`F*����Mp�|�2��0V�cf�I��/֋W�����;���4w��Mz�c��M�z����Bz��rX�H��ZS�+c�r���_{H����"��A�"�c`ϥ�Ga�7�5g�D �G����w�ߋȟ,wK��sf��P���Y䌨5�?1�lX	4��~?��G/lC��^�C��w�#���)x�@�&�h�I(Z e��Z��{��ez�E��	�e���Z�gSp-�5n��;�T�����*�D��ܪa�1n��~U~�<Ct8ߒw��Ϸ&�؞qA�ż��t���
�'�P�q�7̵i�s�����u�H�W�HB�ɹs"��@ڤ/�1c׵-�w���qB�9�0��}	����6����m��bNu}���a�X�p�� R&˩�1/s���#��7�
��ӷ�Zh3�m��x��C?q��}p=�[t���?hVౙCpl�ɋ�J�����3�[k	ɇ�O?�ͷ��W�H`*k#��u�R���[���z, ��+�ct��2�����(]��	3�]�6��-�3k4�$���<��\�-�vo�$6��'2�$�Ǘ:��;˖}O��\�m6At�^F^z� {�����CB.{y�	9�~�t��nC�0�w�7����6fz��K�Ī�*9*�$i��[@��5oQ���� ��/M�&9�)��C:}-�y+%��
��:8� �̖�M��Z�w��'�u	�?7H�u�b�g���Z�V���0N��+�9�֩�E�Q`jHp͉�VĆ3�c��p��UUX�9�&�Dcf�
��u2oDA.Q��#H34ڞ��nT
���ۈ;r���'Zж+������!ն����B~-{�O@.�O���g�U���ح���|��㙇�e���f~�i�|���RL�b-ֹ����3P�6�D:�LF�1�p#�>5��K��c�0x�� �H^]���L�_7Y�*5|��R@Z��и�o{@�ز��ڻֶ�����
�An�#��*bu�_��{���Ag-�P}�%�ĊŅf�s�� ��5��$WK����{�4_�i�q-��b��}�\Ⱥ�&֓9z���[^5"�Ԥ=���\necg�g�8���i׫d���!&�����9-�I[�|tY]* "���q�z��aӜUW��>�[�>R�*�nb��ӔEV�5 iTm�4~��Ku�'���VrbJ++��[~<��u�\"�f_��	�b�[i�3�x6PQ+�jM��v�yr����DУ���
G�u����,1�@A�<w�5�N:��D�EM
a��<����<%�������-V��3T�z�������şs��,�T�l^��N����
9� ��\5(9@��V�h���/���:`}��4F�K�-�8<'�(���xx;�����8F�&�&T"�4���M��6B��Se�g�C�|7_O|�:J`�k%3]{5}�0�C&I�~BH�J�� � �$�|jp���\i�|"��{��k�����D�Ɨ�u���U�O
� 4�%RdΜ� `	sgBGaE�"r+T�5⣂_�$�$��z����iW$�����9�h`�jf�x��̋�+��k�>�o��� C�X>�t��d����Y�_Lԥ���|�|��	�`�4:���B����(��x��@_��$4h�3�b�,/�k��c欺��n?M0���	�pa3�FSQ�m;@��p�ԕ?�%��d/�U�i���qu�������\�Ŵ	�����?\(����f	��!��#1��tD�4��=p�|yM�VNOE�\�T�_"��ћ8!7F7}u��3��}>��	��w1��R0�V�
<�|Ur�k����`�rF<��ƈ�೩�y��hYHЃB��1�Kp:������ƞs�3�X!H��m���CR1�gx*@�����e.��@N�G���-Qp9P`�Z�k�lm����R]�{Reɾ�D�ؑ��R	����b'W��>MG^�y�K�����9�A��n��VR�ٖT���rȻ�ZH}~0F�)���~ �ZU��ջn��$��«��/��,Aj�A9�R�%ljL�Yu3ߣ���6�ex��^P,qa�� ~u�a����sT��!��������N���қ\���*�X-���ʹ�O����!~�&�k���^iQ���=c×��r��Wن@�)���<:����o��p���.u���%��k��m��^�*����0O��@�L�E['n�ix8K��s�c���3�E=�9�4�ŀJ�fֺ�;�-��g�J������k��J�o�A��o���&v0�����f��B�7V����g(�t�dR^��VV��۟q�V��=3`?A���glx(H�Ѱ�|V�ʀ�9����;�����i�L���p���W��,���L=�XJ�+D"��{i�e�]�?R\�	��4v�����@M�L�Nx��֟�u0����Ǝ �}�o�6��&�08�xkJ�A�Mc!bE=�0sR�B���F�΂�{ч���4�4N�/��B9��&��91Z�-{P��O|KSˑ�"�~&Y�U�]�>�3�������<~�eI�9iܳgF6ݲ����\���	� eϗG�D����rKg�~�pj=Ê{�W'+`���)m�A�H�}��6���:$'��>R"���?i�����y�4���Y��l����u��L�U��|�.CN볭�����	���bj��5b�W���tA�A)��0�����~��B!�-j�"��f���:o#��hf��]vu�I��[e�A���۰LM�B�� �S�$�R��a�i)ج_�9Iqw�\UA]/@}o3�YC�ij|cp��^.9dɭL��LG�a���*1����ԫ/e���&B��q�^�7�`Dȉ?��L���٦aݜ}�9N�h�����R�MUj�N9+i<�alm�]�Y�^r������m۾+�S���Hu��H"�w�Y���*�VC�յ���&ރ��		1��do�(@���[o�J�I���j�OS��?��4v�1��X#|db����ٛ-��uR�����`zU�T�Q���Ѣ�0/�������fb{zv����7�`F��%Q��&#.Zڣ)���DGZA̞��Q��뚊�!�By�B��!��-9c�wbu&�����{Sn����h�-� Ej������ܦ�Q��y��Sg�g��d��%i6��u��I��z��y$���6��cH�H��0�(��g4o�������[sw�๬]��N��N��	%��h�?����q�\�<BnB�X�i�Bƴ�&�_�?���:����q���(��Z,�}���JԵ���V-V�Q)� E�g9���
YxQ��k���R�<'��Q�K=�p���B��f�8�ݡF@W+�!u+FN<}�*C��u*+!$�ϫ1��2�-+�
�X�`�5b��N�"��>{�%Q6ڀpz��L�pa	��M\p���C�XY�0�	0S�8�����N�	=���!��fYn���<�^6�
�� (R�w�ռqk���FxX�~ǔ&G����C�dI�6'�(1j�P�Aa�i�-P�CEu$<*�1YÀ#q	�����`��׀ǭE�$m��H���A�i�+�u4Eg��͚�̶~���,�{o�
� W4�70|�/��;a���m,�Z
L��XlZ�VKq�B9<^&{#�_,K����Uk�6K�O��cq����mo��_i�?G	QA���'	�$q&���g �}����s����T�+�BB94�1�Ƃ�(�����9J�X��9�]�w��<�Y�&���m�X�_�oƤ�_�j�f�;IJ�[��w��ڗ���ch;cs�v)�E�u\HAz.�������S	��C�K+o'KL�u!����0��{����0���,�Gi�Bf�֐wO����"w/b>��޳�Zcx��%�cf`�IY=����N+�UJK|`�����T���ש���R���1n���,�3z3��5@?6�q��}6?�&���q8�$ATiZ��D��<�X�*��멚�Ȃ�l@ZUE�ǖ�E�#�ͅշv�Î�l��P�L�V��D+ ���S/���g���V�ˇ?��~px:_������꣟�*m.����=�I�@ڑZB$�h*���r��[:b��Ϸ������Y�&p������ʤ��\!�͸,�O�BH���k��R�l8іߑ��� �q��5q2�X4I�����?2�I�Pt-Z���ӗ{A���b�V7�e�fK�87��}�� IċK+��:qq4��A)u��Ļ�B��*�}�jM�;�,W��~��'��\(+�U�S[.�0?���J�%� ��b�df��}8��E��=�Y��q�FC_k� E7��k�L��oA��
L�81}�Yb� �'M��d !���tZMOE�g4�HE��������K�[b�n��W��P����L���}c>�`�?�mh�u7�Q�a���g�>���XGpw�{�s��%�'�T��+�K� Yl��w�5Ez=��c�S��&u����#w�y3�����d�:�˺�JF"��9�ȥ��D�Ȼ��3��`A���.Z��~�ֆ�n2��hZ�2�ȭ�-�PHݼzZ�j�W��'�/��Jr�u�HƖ
�cs��)�QS��x!U�E�������F�wE��������I��M�C}�ߩ�!�-�?�w;��K��>}��˶$����˽L%�td�Aeo;+S�6��R�K�<�2����B�E5�����*�'����uZ���B\��u���|��%�:P��Ni�� �w$�ŗ|�<�a'��Λp�]�������6�ւ�s�����A�f+��M�;4��9�%�;p˪Þv���b6�\�U����R����eflI!�t�{���4:@>#���-0J2�;�6�,$S�2i�8*d0�G�$}�F{ !>�H��J\��ƴ���6J@�:n�������[<Oj�]����	C�~9��_��s�i��ũ��{�m[fvU�W��(�29�g��#p����8�h��lIv<����Qk̡�6bp��I��Z��i�Y�lF�%��o��%d���=@{>ں-5ʩɔ����fCe�R�Z��^B�8b�~�f���q#�)�h��K���K�����
��T��,Yߌn"��09�(10�	?/�j�Q�����[ �L�O��&cu^����d���T$�ms!��JPp���0�&if8�ꡭ���fi���P"ǯh_��-?,b#eg?��t-�Q!�^.�8엱���X���*���*�{����z���hB~�{��y�Q��G�̎S�+�ٚ�C���O��/�wf�{H��4����T̷G�%R����0�W�ZMBn�����BEC�]ذ"a��l���P� 7���o5�-K����`�N;��hJ�ʧ���6�H4�s9��،�yHs�h9ʄB4�� ��+f��L&;�����_��h<?{���cr���S���	V\��TX�E��[�#�/ݜ$�m��@�I���'���eXK'�4��m	���V�"�}y4�������o�m�U��_��Ю�FD�h�rf��t��W������ �J	]�c�·�9d�/1 �O�n�Ddu��x�Jo����Zv�Ѿ_�,lĆE�*M�P&4s�TL��B@����(1�J��kB>��4\.�6g.�-���.w���c�F]� �c���\Q۩��ۇ�,{:&=�.����L���_?^�Jb�^0�n�W��+�ZoG����4;1mt��XR�u���1$��� :Kϊ~�O=2pO�-hC�8E�V`hN�*�x�B��@<>L+gf��^W�}T a�y��mɝ֪)fO%�0R:��W�/�}������pf������"ev+���{���eM7*0�P�����@�z_��r�)�c��)X�h��r�Y���H��C#W��v��
&T<.RW�#s�6�9d����S� �;ێ	�ʚ�������P�[ 	L8Q*:��{O����&��m��y���2�sv��,e,d�y$��[NV	��v���=
c�ק���7�KQ���$�Azp���f4��X�ɡ��\�Ìdb��h�/�G�*A���_��� YVM�v�e��W{GL��y`�]&^E���T-��o&醷v�����0�U41ؑ�3���Y�����+@gzb-�6�EJ`�b�Oy>�{���7��7�;��"Vwx�"�d�^��۝�-ƿ�G6cK�
T=g<H����M�#�g��`�F���_h�\����N_��x]f�O�Ӹ�olm�ͧf�>M6c��BVA�H�w� �0N��:��C�ߏU�Lf+��o�x��ӥ��D�L
�>��T ��?�>콾{|�k��q8�\hרԟdi��S����[��G����vK��4����  x �>I���f���7���g����p���Ρ�O���7��[��4��; ��I��� �/��F�p�SO��8�5e���W���dp$���@}�I�>������Β��?�*}�=TUP�[�'�k�1����V�@J��T�8��PD�^����i׋�O�9��
��1�^LN/Q�$_���"�{�v���!�����yg��)G��?i�Su�I��S�B�,�4~-`�~n�)�"Fɳvx�ҍ�R~���P�K�N�M�u�q��W`��g��vˏ���=����um���!������uFNi1ܾO��\���-���y��6���kn���K�l��R�ߌ��z,��#��]f��`l���LtvN�4g����@"��+\�ʿ2�"�Y"���\��U��8�n����2es׬�;~���n⣉�3^���\��0ނB�D۶�ƹ2d�%pv��Y�6nD?���Q(ͱ[�S�7����ꣽ�=}݌��q�Zۄ&Ԝ<�����5QÏ��#��O*<����Ju�[��BŞ&���ِ��w,��f6����ㆨf����9��Xa�_��P�`4������3�6����HMJ�T/@��S)�@R��.VL`h��s����8��vȘ$�z�~Cm�r:�S��(||��w\T�q5�믦_�Y4,�����)�4��5��j�Y� ��>O�߬`�F6W�9��:�ȆV�Wc��7�;}l��T����w �D1��[�-�TLy+r��ޡGR^�7��x�������v��8N8��5�iO�I��c&k"��U�}$��.ٷ�@�8�X?9��ty��h+^5���`&8���]�����{���T����F'���3ÙՔ��"$����Òg�<Z�(�1�1с$)�8���0ˎb%�E̻@4sY���7��`Ļg�m���� �.��;h,]��8W�EK�Y���)��3ڂ]ܼ<�2�_�ô	a"����P�v9���DؾLoֲ�R?A�`R�zx�V�%�Pp+�ܸPr?-�e���vK_���G��q��Ȼ)�ք���x�qk4���&�4�'��ǹ�_��8��0#���OK����N���1�Gm���V��<7����'Y�p$�d΀�g���d��@��C�����N����s��&=]$rCs}��xbu��q6e�ٜ���z�]4�M~V��=�%����KANrp�l��SB��j�/��߷���o:I��,����<������	7�
�n�u5z�uŃc�)㍕�g�s^�����s[nҥn�-&������?���PE�+�H�ŝR�QDi��/�B+ޏv�����bm!��0�.��͍{�;?��}R�I��2cEUCy �u����gH�9�}�&�@s�-�����Q���p���z�l�R[K=sG�������Ҩ�Lp�&����f�V3<�o�i��(�����Q+��������-C�~��L�G�F6�?����q�A��L���W��F���.�;{��7g P,0���ڗ�Ѻ��o�7ˠv����� 8-w9����&WG:*Զ �HC�
��(���o+P���u�Q�Ȕ���ݜuI)�ǿ���*@���� ׉싄cp�ܨH��CO��Ȭӟpgԗ��	Pv�� eљ���1	'�x#*T.��Ɍa ٹ2����s$�����lN	�}�áF�mi3c���F3�yXJ�����.����V�lUc8��u�h�5�6�c��r�]�oPQT��ڽ0ؔ��������D�-/�=6��Йg	����D�k*���;���̵{�c�L�J-Yrܴ`��Z��u��1jrx�c��@'O4_�t�C]���b�F@��9���>�8��|�/S(����jb�g�[�$u�n��;����K'��^<�Rx���C"��P6k��ǁ�D5yS@P��9�M�U[C��{�����ۇK/q]*��%�[-�,�:�wր1k�����a��n�7��W#]ZK�h�2�A����*`�?VG;T�+%v�����GxD��6/�!�-Y����k�OA	��4;f���m��w�����u8w��A�Gち�1l��g�Ρ��x���Sdna����\[��A鲍����R�,x���u�B���%�ѱ��J۬��?��^b��1�MӼ�AȓK�l%�X'z4���G���ߖ�+�|�8��'��`����FnG	(4��gðQ�d��Rͬ���x1�>Yv���ݤ48b"�Ǜ�W��r$��J[$s��j�Y��E8��MX!��O΀}Y�]��L)�z!�xҢ�ai��?�F�n"}�k���-4�y���]����0��[�ءR���j`d�Mn3^��<��Q�;�M��Ey{$�i��>�۴��-����>1R�^�i��a�/�G)�8�����s+�]�Y�U>���Th_�sGvPn�Ͱ���Aj��߱S�RE�@k Q�o w�D��e���yuޥ�$�}�����}�+Lk���!�����5��̅	y��cȤ�n���Tq-<L.bخ�p2���H k���a��D\���U�rWp5r�{��6�O��o��K�lV�p���'���#��<���.��)	��18���c3������O��&$l(e_+� �q��s�U|�6C�������M���w��5Z���>�p�{v�������=�5m5�i�ݡH/��E�h4�ꬥ�Yg*��Q&���Q��d�'�e���#� �Y(iXr/��\� �\�lU�*5������>s��A����x��� &�X�@||#�H��	��c#���g��(�[I�Ra�T��V�Y����q�f�J�ͽ���ܙ���2C�ie�r��ވOT���?����L Γ�g�n9��m�yS����ɖ@���<�0�/ٜߨ�Ȋfܡ8UJ=�3�19C�6TXk�!�G%��Pi*��.��î�+ѧO͗�DI�k`L�`$M�B�ͥ��C��FC���.s��6�pه�nx �H%�+i�>���[z@��
8kY����c���KP�'���$�9��L9uT�o ��A��B��l{N���;���9T�W�u�k��:�m�W��(�v�����
�c�F�^�V����`�X��!�-T�ą�:�����[�s��ؒ���G�1�"1/}�g�і{���͛�򛷀����K_~��V�|�^�{�\#B|v)N�'Q�x������'����Bl�7�s�iY���Lb�������k 0I��p��z�R�Ţ��ǉ'�b�P�٪݉�%+��n��%��9���UBN̔�P��2��}���K;�	�����v����98h�$�a�݄�[8N�������7���m˳k/ݳUZ��P�OGi�d�U��i9���'����t�[�~�Vz��6����|�@��썀�?�����&��*�*1S	����E�,[�-��U�m`�#�*�yo-Ե&�y"�n�h\<���[{�p�`=w�WOh�^����0C� ��1@hV*k	��o�r����;����fVE��M�P�"5,0������(Xb�w���=V���)%�.�I@��;$�b(*���
̀� �k�Wef�=��y��
�	N�YQďKf�j��D��a���Ɲ�k�����Sʭ�/s0��a��r���퓰��D� �R@��Hs'𲦞E���'��r5�kpZ§vvʁ+83�'&G�W�7��*;d�,�&�um�����qc��� ��z_�b�!����QF�3��*�y��'U�Y�SqQ^T����T��{����?����3I�0A�W���k<��#�v���7[=1\�&{���J1�U��"75��G�������ezKhl��K��tl�8�J�:K����5Hu6j�Wu��ۻ!�g�1,/bZ~�ڝ�D�T�r��W��w`��/����<@��2�Γ6��g�( �u�c�E^��no���k���%5+�`�nvj�e�������lZ�3H7A�z����>Ԗ��pϠ�?U�|��|������KM����ɚ'<͍���yG:��u-w���Xq��q�x\���9������[EW�׍�t���z�D�3��_{�ѹ0\oB"�c|�پG;i�	�Kܣ�������'��`�δ&h�&�D����T�
p"�v#�"�������f4�Fnk2:����6�����M�WU;'��e��   <0��0 ����Jj����g�    YZ