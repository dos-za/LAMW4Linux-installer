#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2429533479"
MD5="fcfba6319f75f8daeb5c1190ef7b8892"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25688"
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
	echo Date of packaging: Fri Dec 31 00:24:29 -03 2021
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
�7zXZ  �ִF !   �X���d] �}��1Dd]����P�t�D�#���x�)a�<)}�Q���/�eV��Y�N����~���Z�EDDr%O1��"�5T5������s$�K;C�{�\7B؜���(�~Gn1_[Ѕ�o@�D���ݜF���ڙf��e&x��Dym�@k8�u����.�v��LN���^������>|�wD�Hv��9�$�L�f���C0P��[�a����>�a��)-��} ]�bv����_���";,tΨYQ �?�h�E�^T>M�:�9Tc��ň85�LJ�1u��v���Q����� >6Ô��X'.ydQ�N��r�4/�ÅT]�r��������@��f"�FUMr
nxt�J��A��(��N�\��V���P��}韊�Zp4t9vS@|,/E��/D��L)8e<�~O+��״��'�2]����=�D��������ʵ������^}�j��o4�3p-*�Q�`��#5L���/��V�0��Y�`ߩ7u�������߅�$¨��F�:�E!'Rb��G.4+
�Q��8h�Y��eG5@�G{	N��̥.c'���S������k������V�퐭ؽ�������?=�i"��F����.O>���t�"�s���h�}���<v�>�|ؐ����ǐ�m�Ҟ��ƖO{*��l>�	�f�Q��<ŜԞ@��!n|�����&U��.,F���$vă��X.�~��t/�ʛPle�A'����~HU�%e�&(J��*�J�⚲�Kʋ"`��G��t�:	0H�	K�,�ѱ�k�0�K�t��M&�U��x��T�
��G�@.�z�LX���ךc4�#XU�b�����.�����8�x�L��
�������y�����{/�o�h��gYq��
,ŉp��_P���ka$���ef4�T�M��nK�;<h��Bq/j����;�=2U���lQyQ� �sm��\�q����!����?�պx|�> �	��آ�E��W�̪�,�ʺ�mt��c}��0�X��O�wl�qnsLJ=�<8��^R��>�"§XL�e�N��W�l�FNt�Gm�7V�4z@bt�ԍ繌��^���/sfF����x���i�K�u�sB� H�S��ֺ���o��I3��
�S���ň&}���A�"]?��:
�����F��:��iܤd��7B��#DFn�=Pte��uK{88����)��H�K X�x&���oY����j����{�Zl��ׂDn.�o�t���c6ښ~cY X&�� )Fȵ�Y�Q�l�Ϩ���gǖ� � S>�Я�W�H��T/�Ӌ2h�CnB�l<���,o 8��$�Źop4�7�+�x��z^+r8K��p��������un�G�95����(��]��E��j����eS��|�k���5(�ͻk�݅��Q���K�%o� y�+�$A
�Q���������H�*:�$鑋`L�O�	8�Y1O�	�
�a}#�e���`Mwz�w,���ҙ�Q�U+�n�[�\^M��rmZC	��ܠ��J�Y�sw>�0-=x�b��S�´�}5=��e߯��/�+��Ȼ�'�q&����3IK�>��?V�ʙ�h'?ru�`P�ɡ�!��|�arS{�{�&���נGŝKp�V���/�ĄL�}ɡ�g����L��h5�*�> [�OSxB��=I�z�:O&����B����y�7s������nz������mĦ�s�z?̖>��U�ߛqEt"��}:J����J��WYM�:M�1�s���S>�����
2>P��ןӊy�v�k>I��D�ʼ�*�`!����0�ݖGm�M41�D���x�j��4�S��U.R��R+{F���pV��]�mY��n�i=.���qkZD�������tp���s��L�=J�2�]��5�`D�<ة��(`��92�_��v�j;zyG�~.�����M�HR4���u�(������bC8�M� �6�W滇�*�n�B:�	�H�x�c�U��b�	���7�Co�Pp�#�0F���6"�3W�oQ1��VHNǃ�;+�Cb�B��Fnr�+���T�&!L����_��+%S1|�P���h(��Z2�Av�*R�F�������a�ݗ�w0�mmV�5�(g�Wn�w�*���o5�:�A��	C�׫f�`�m���L��R�Ў�iGg���d�+�!�A�dUM�0���q�\~/ѡS ��Y82���˟d�T� 0H�;��QA}�B��E��|�m��h�l�aa��xt!�Lq6��v�/�J�����fA��܆���f0��j�IH[����?%�:��1$�'g��ܐG��q�/$��֎�'�u�r8ۗ��AӸ�_�H�b�'"b�A�Lcs�_[���1j���o��j+��kV%P�		l}v��6�qa�z�!����?�rHS��x<���	��sh��H��È@�O�9�k=sI���laʭ_�I=��՚' �1׿�n�K0..ŷ�K�P����4����R[�C�����>�:u�8���hK�q�S ��Zղ��`ˍ�>r��d�/���M������m$l�4�J%}�r;O����\9"n���`x��ͪ9���r8����lcA]F���0�n��a �,����J�����96 O������Dl��n�6�N�怜0�JXO�U�?�1EY����C��ϋ�OC�P
Vq@��Vpo9ѐۚ��A̓B%Ĺ,���KP�3��d��:Ri ���6O"v7-'��������c?m�A4im�sA
t���i/|s�DT:d�P��G��l��	�{���W�.��l���E�P�N��U��.�3�m��g�~,j�ϥ�;-0��(�^X�< ^62��s��q�K	�7LR~�篔��(�vٱ��m��,���Q(�������T�%/�#�24�
s���RnFx0p<%�@�r�!�[�_j
D�iU�O݈%o N�eBz:o(=6!ag-4\|U5����yzC�}�Q��=O���T禘��J\nyW,��T_�����x狼�)�[ Q>:����'��衻�!fJ6�
��vl�ݶN-��T!�j�Ȟ�Ö�ڄ�-]�el�!ظ:���׼"sR�}�=��Ni�E��k3��'���!��%`���Z�Fp����I�8N�����������c�S��:BVAY"���p��]�Ԭ�����h�He�y"u[s�u��=c�ŠW�����SӴo_���� �<���2��D�H��;�n���A9��:�P<`�qiP;@��������~i�t�`�oH����?��!�ߣ�̖@�7ZClw�U7߳��G7=�F�z 0
[��������TK0g�I:]$�����fT���aq=�|S)B"�:4y�0��9~���ԟ�$Mُ�x�K�H�Ɏ��_W���Fk(>	�xu�m��aU�b$6u�*��k�a$�L�.o�X~PR��������LV�-��o|�ֿ@pq��xqت'q��-	�ʂ�J6�Ɠ�du0�f��`�;Rbdq���z��y���]}L�=0^�?I�$��"pW��`������Oa��}\À �s��ʸ�w�m���y�p6��o!�'�\_wv����?���C��6��D�f�1+�\-MC�+�����82y[�5�$�a�dT�-�\�?�!u�u�V����"Ỡ�ҙ(RR�>]�}��SU��;� ����@�͢d�I4$�N,�8zG ۄEx;�pT@Ԁ��(��\��\��W�c�4ׯ��"��C!Ԕ{�~�1Z9 ���8��hZ�#I���~�%�zqB�)?�ȓ;�����٢�Y�ڍ`��\Z���9(h y�x_��5F�Cp�lm�M&��w��`~���N@]ZC(U����U��6�or���f�f{5�YF.&-2�7!�Y�,k�y�q�ҕ/�@m���d�t�����6�I��$Ë�	���T�)7M�8�@m	�!��"+�<iHl~�%Y�#x.��㒼8�?.���v��羲z���r���d�go"��AC$���>�b.�DW�x<��V=�\��-�ٖ:������P�Q���7A�	%p��5�8���$�~nD��>�כ�ء��o�h�/0о4r��9u��b,��2-��x���E�KD��>K%囡�s��T&��I�2��t����.����I�P,�h�(u�QSʬ9�Z�a���2&b���\�Km���p��[❇,�޻��~����<nc�E�7md�����}�d)o��3�l�?���3�g��s�9��+3u�E�F{|��/Y��v��.��9�l-�[hF .�')zJ_���X�y���Z@_ZeS%+ɻ�0'(����|�!�䕦�+&��k���2�缔���h�5X=����kd�ES_���E>j�&.	 �#o�ذ�y�I��Y�3�o˪Xx�3R��CO�M�*��'��f�#�e]�[?h2��DKE����%���P09W7<C�C���2�4>T�o2���(I}���<�� �V���������rn�O��	�N�G�Ԑ㝪���CYX�*�yHsRp�����*�!�Y��=�������ѓM-�{@,I���E�==�9��EUt���3� %���L���j�g$�3���q���&~zoU�wN`3*����"d�M1�V�{��b�`U�v2�%�YY��n��]?)��FhKn{�ѧuMJ�^�F�d�{����*'�t�e���g��0?ԄYXL��k^)_wW���0b�����Z��|��"6%G7���\��� ؎�8�Gro:�p�N����k^H������D����҄����%����)�c���c�CA�!
�T�LS��J�v�ډ3)ه�����[\v�	�Cښ 3H鶱�ģ<m�9M7��s*��}쒴`i*&�ٜ�6�]9�\~$��w:��ȝ�`���3��rzm!қU���;�l
�J]�܊����������b�~**��y'1�͊�5�0䉼��E&�o4�d��,�^kz�H�s����"X�{�{�a�緪aS5@�B�)6?���f/���{Aa!����:.��l�
Rt�B�/���
�vE��q��,Z� ߗ}D�ze*���:�1�o�*_FqT^��WG*6�����V'd�L����2�q������%��8C�q�m#"���ϗ��/k��!��6�mJ�ydt��h��d��=�'���o=W��9o��!&*f�����e~�b\W�kwl�j.k��k���p@p�B��l��[�.��
������Js�_�>��K��lA��@��O�~�t�RV��>&#I�hh �z ��
�C&��O��԰ϣU��w������.�f�R�ՊV���c$��T�QK��:�2u��oA���Y*���",�z� �p:HU���Mp�H�s��p�ؾ����I,�u���Ol�SH�g�v���Gh�s$6�i�O�}��i^$t6��HQ�J-$u��	y�O��p%eB8����*y�˭_��������GD|&%*5%����у.u���*:���5ߎ�"�H?낛�#"����^8�o��@\����-�Ԫ�{b�'���U�(��
v���_�7f9kV'0��!^���~��å�y�~	��Y%+D��������U6i�������yi҆
ύ����q�Un��.���<ߡc��h_�&���\p��q�����R�R��+$�_�B��W�K�(��X/St��BҸ9w�=��8�ZY�󠝟���a<�6��0�+����zulB��x�ߞ �#��XG���Y���D�	�Um��/��7���u�ZɩD:�%/�8ݥ�	W�7����DƉU�-A{��JG��;�y�G�y�7�~v?/￡w�Y���o�fF�y�O�m�}�q\��p����t*ZLoF�2��Fȧ�PŻ�����!p�H��Z{K��� �=,�Ȇ�R��9�9�}��c�1��3D1-x���`'H��%��&*͏'��M!R���1�%@]H��F�9~��|ݫ���N&A��`3�&ta��4gdbvĥL'�3_����T=�~��W6���ӽA�W0���t�\�����jz���wp��$Ņk� n������Mg��j�7�����L��7�iµL,ٗ��9'��z*�<;�e�nZ,��'&��#i�r�Ui7��~M�ƛ��Ɔ��7� ��;[�zG�.�F@	�2�`�r����tSΩP�q�±:���0dW�i�^�OZqe��b}��t?�e�����NO1L��a}jAg��y�Ƙ��}��i�&$ݻ(������:Q�A��o��*(f�%���>}���9h���͢h��Mj��j-�N��n�4T�eK#��֛�Z�EJ�(Q��,���@�T���D������?���s�]1��rO������|���𛭽�ޮ�
nW��<KK;2LU�Eƿ"��܍���S���-�l��������w��(��m`�H	·X�զ@��4IK�Z����o�����kcV�I���V���	�܈�Q��L�Ѳ��8�BG�A_��Q�)�.S�������C���X��O�VU)�X�
<g��Q���|���_u<`���m�	�i_dH��`����yVhV��V���"$��WS�H�O&����T�ص&�S�?2U�5�]/����z<��\��yY#AcZ��N��-���ӃH��IC|�oq�T� K���ҿ�p�g[���4��Y�RGQj3�b��WT$�1��e[4���ĭ�]�6�h�z�F>Y	��
k�T������`y/�"6K��������.I�`>���+�^i�I���Xc.2�'*�YR�gS(�{��Np�(�wp��~@J7�;0)u��n��/~�oa�I�\��"6K!�ׇ9��	���u��Q��e�k�w�A��2E��!�Y�A�=[>�{a$7�=�x��6���ѱ3�\#&���o��tZ><:k�n����.�/�����[� βO���+ݸ�Y$�l�HU���L��=�����!�e�tz1ى_�Q��YjCE�*]J7����cwX>܎�|_��9+�I�����؅'i��H$⊿ˇ�7-�(2Ƣ�.d�>��g!4%s�� ��J�׻�%�8lZ� �pb#M_I��*Z�PIx�o/$�ڼ~�l�����N��C�X7~�!�˄����Z�%���0���d�^nAϲ��	#�dLQ��춓��;Z6.C���rmB�G������ǿ}w�|�Z���kr��v�Ek���w3�
O>�/'"<Y�)]�_d�8�C��q����4��^��i|�C`�����w��h�ӂ�t(�~�	S�h�D�2w':\�Z�}�_ڕ����=���UP��2!R�Xދ*�?)��Õ��t[_?8[���u���0[
������o�p~����P5� �Y�ݯ���� �=��8���g�8� ����L�J9s�،���(^�2��J|��'q�j/V)��[��`�Z�ە���2a���8��n�A}�x#�v�!���%t�6�_��"�0��7���	���܈����Eٶ8�@Z��~�䄁�đG�AXb#a�%�M��ks�6���-�n<r�������$�y�J������s������v�D_#Z#J0�%r,���hwxa�.g��cՃ�o!�	��p�����0��q
�ttT�y���WC�V�O&e�jX���*)%�AoL�ٝ'������Ӄ�_�R-��l�Z`�%�u�^�"RW�F4�8� Ey���9�02�Ϥ������VN�2�a�)���	� �ɜo��T>�-t���&�Y��K��}�u�آ���9�5��	LND	~9���(tX�)���m"���q_ʰQ^گr��ߜ�v _�}ž���P	�n�+�g}�ȢhZZ�dAA	@cuRF���}�W�)����k��A0vvTui��ǉ���xR�U�K~�&~T���<��u���W6r�04�9:���q�����ݲ9Xx����5�O��YϿFaOy
�#��TX*�i,j��dC�г��z�O/{�)]Y򋸫����Q�A�/��)����ZZqp���	�gnP�c}m����Ǳa�-,�861O� 행��Y�<�[�ʘ��0+��b��3����9�bZ��5H��RCz0�H��%�c��9�ױվa��s�!�,�ff��C`��8���]��ݶs4Bw��UFٹ��R��1���r3Hh'` u�&�(����fS:�@ޓF��CW�����K��YX:[���z�mr.������͒�P�e��!�[��v.Ү�o�(�&ƣ�t�&�H�bb��-{OKb�3�z�A�uB���W�GNn�8H"i7T�aWNg�Xx�oe}�cY��u���Ya��AW�'��t�fS�|��jݔzڅ L��B.���Eu*l�9ٓU��D�$
�a�Kcrh��؞3�s��RG�L����Ƀ՝!�RL;�{^������t�`�����S���&���%��p%�{�ޖ�:�#�A.ӈ�3tawڡ�Rz�v�F���+9T��"�6�m��{Tj`\[0�Lw��6n�W����
Uh0L3Cts���5F������#��~�3,U�m��w.H��a�eYŚV��lR(��u$������`�+�·�L��s�G�/����k8�����R4��U5C�s��S���^͗D���,z&��D?*�\K%K;w��81�)L��h��[ri?�h,�*���P�X��y��3�cň���[(˂C�۲������1]\���p,;$~b'��Q�e�<�F�u��ETy38]���xMA��g�7�sn��.������ �|zc��!>>�6���������+�<T
_�[3�5���B�f)�o()��hD��Xd����nM-y����ۃ� ;�و<��bC7���+]ʨ�$�ϮD����u�x��Z��/�<\�Iڶ(������x8������er�d�皌��75�@���/.ŋ[q� l��B�@������ok�.���;t��zڦ#Ree�}� ��6�l�imV��^���9b���p'��!��h��M�{
-�?�]�Q�<+��y�3F��+��VF��Pa�35��A�,=�%P'��ɠ��i���ٺ��"�y)�Z���jW`��� b�H�F�G�$'�I{�,kBlPc^?���� ��F��h�5g��Ż\�-O`��4�J,���]�t7�c�s�F9��KH��T���Ϥ��Qp���i����d=���'֜m�-]��>^̪��سs�apf��(E�s+R�HrP��%K(� q;g�s��%,�:���?�*K�ɏ�q2/��K ��[S�����1��uZl�8)�������9z�f�Q�.����4�Z(�.�Z��J_i�5%�h� �I.;�d<|L���z�jE-�@ b�fA��q��
C� `7e�m��߭��ە�`͌�9������lwԦ����{??P�������̀hj2}�23������$��,�u�l�f�䣈G�?>^�1@OЬV���畸.�-�[�FL)�_mÅ��W��F�1�ݙ�����s����ǁe8�T��ƀrC^�D��"6�m����
MNai#�Ҟ݀�̥���𙜦�|
� ����#C��8��Tø�@�y�.�V�*/�}����ѕҿ:��n�,Q�Qx�� I���;��r��[% E��;��6#�B�"pXI2����3v�u׽'0�\��X�xZ͑��A�	1RPh�4A����~8ŉU�+�)�]}`3���[�?+�	]*ef/κ�@����)�g� AX=V�5&��jz��:&���鼈�_8�{�t^e��M�.�1ې/�^��p��%�tV"��6�'�^����"�ØD;��s)
]��:^tG���aЯTl q9Z@:��٩n�AՕh���}gtCw�G�w^FJ�T�R��g�%�67%.��林?+rop:X@&Q�����L+{�6ԝ-D�������)�"" ��ɣMc}-���",]��!,�9��h�6�2���>XNe\�S�o{m����Nط�"���N�惙���W��w��z�K�F��������
���H��N�w�~.j�W'�6.n®&��..]t��X�L�p! v��_Z.Z|R	��8��@��q(1٩#��e� ��n�<׍T�t]��|Qb�j��d�UJ���.a) ;�{���]�^"�n�r*�������Z&�q�T��o�����4"a���m�F�2�!ZG�ڛ\0����̯�c��K��VM�TE�A��r`���rr��Fz�u�<���"M�~��{n������$�����6�~w����ؠG���v�-��,,�u��̷YbƼ��#�RL�=���f	�����1 �n�ihSa+��)Ő�	���'O1]�������LC�Ѷ��=��G�c0&Tv�ؒ��0k��;�9��U8���p����E�qyl�zh�s�F�1�Ѽg�I�+<?�ε<ٰ�-�t�^�nC�՗�m ���q�O��$�"¸��~^�]E6� ˦H)���ߒV=0 "��!�6�B;���@�`:N���c�0�ƞ�]�Yҳ�$��a�E)�����[ե5x�j�Z�őXN3A�
N����' ��L�	��'*�9�B|5��`kД1Q��#�̨XI�ז+<��^m!w�#W�w�?X�C�}�݌p'[uT�I>�׳����p2��q�:�&M�:�v�Gqt�<�M�����{Q��,(j
��I�h��gi��\@����9*�o���6:�L�+'6�G����P�y����( �K���@'�ѹ�ژ	@�O${,�{�O�:'�b_Rf�t�u���5>M���� ��]~ϴUxDB�U����ҍ�I�y/v��-n�N��&�c�%V�)y�~�n��&m�}�c��3C�p��eh����'�����Z^_H���b/� ���R��^vω������,E|!�	*?=@�f�B���Vz��uF��eҟgM5�L����xLs���a,q����������~�$�4�I��[�r[o;f)�)�2;X��e��;��w~��n�/��8���[�{�P�pt���J+�s��%ב�2d��sR�g��U�;n���&��ʏ�^©�x��C`b`��
bQ1>��5���s%�~n��<���0�K�q^u\�CWY,��(�h�C�U��=$��'7D��h�$hT����u�}Ԯt�e-p�4����2Ujx
��q2�/Op�|,Ě�x�IzV��Ȋɘ6 Ҝ�����
Q�xˆp#��}H҈�v�&���(���w�wo�ױ]��7P��)���t��X�L��n��C!��F?��1(�P&��C�Jv'��K4�uK	�W�Aܫowbz5]�BQ!Es}D�	ʽ#�ix(����mS�Wx@"p_ 6�\�F�\����:Eo|3~\�}C�}ƌ���{HO=���B�x��-�<�����ʗQ
�h���o%�\�$�fUk���~��1�
���,��S@%d���ϳ^���N�&�OΈĮ#3�<�H\pb(5�:��_GI��(*U�:�|�
l�WӃ���>�.YrT�<��I��u�4�_Z�ͨ�bV����Ty�Й^5��F�y�����	d�A�.NF�Γ!>ǜ)�Љ�w9\$���:\�SݸC܊Ng*�_3V�Q"��:��H��Q5�=�is�[I�a����TZ[*�~	�=;½@0kI⪸S��
��տWz�.[̉KQ�ї��F�SG���/���B��K���V4k��]��6KU����Ŏ�D��Ϫ�س�$O�sHn����J#Ƌg��?8���s�I�����
  p�r{T ��챶Jc�I��9�A�Zf�<��[���`���?�yE>�?�u2 ��/�������Wy\RDbR# /�EZX�£_�z�^�D�l��ߥIȔ��%��'�@mX+4�a��ϓ��xػ�=�nK�c1��x�n'�v�^0my��Fe�FC���/��!5�I;�B�ا����?$Q�����7���������_��X�0%ژz�l�͏��uȤ�*��\k�<�����=�;k�������f����mtU�걯�42�<Z����m�*WK�(��$'�ܬ�գ\�,谎��=%��M�:�Ւa�Xm����e}�:p0o���6}1)F�t������>���:-`�+E2���V �e���tU��Z-�7����K�UQnMu�J,��v�7iG�)���AeQn;}_U����U.k��z�z[��� ���}��ف���}h�""��{C��j�t�����b@�9H��rq#���ן��sej���Y��uJase���uL�킊ձx��_X`u����]<���N"����b�P
��$�v?��C�%�;��]��+��7�a�7�sP8tε1Hأ�-�5�8֪h�+�C�]�g�x��n�a3��ū��$����G�CB���kĄ��5����0,�����l��ܚf@u�Y35�i�d�C!���'�V�'p�cb�9$�����ee��_<Fd��/F^l�)`l�컳� e�����dZ	i�-P�{f�kF��o	�zB-ء�52�N�N���S���*~�=S�@�Gx3hȒQ�u"��@�]�<P ����awx_V507Q'�Ď^�nl�0-AW��~.t2�O�����\�Ѭ�ʭ�^���dC[���g�{}w���V*	���Q�%�C�ruD-�y�\�:�D�����
a���N�q���	mccg^�h�ԃ sa'9���������,����&����U\�
5��e�����+W
��z��~��Y�;��J��r��_��"wn��7�(c��p��JK�)�9[�~Q��{��A�'I�y�lz�k峑7��QmAÔ�7���~�ضL�t�R��|�,x6/X��719FӏR��f ��
�[�+�HQ��@[�!U�u���(k\8f�m�ָ��������s�i�L�Q����4Rd��K��/M�5.�p�4|͏��P"ʝϑu��oE�T�Q*GH�E oO�<�<���v�oE�q튬����:��/�#��;U
����qF�
$5���RE�� �y���LO��C������5�|,�Q�6M"��V����j�"�"�}�]}|AQ�r����xS�jL�ƒ`���`%d<}�����ݪ)Fj��o��̏�]�R����c�,B.��=)��Ѵ��ol��/�g�����H.�V���]R� �0��[�hԖI|l{�\4h8��()ʑ��T\�f�h�Tnm���-�+��`�����{��Vm���ׄ~���i]��oܾ$�4C�UacOPjw�u#=�ʦ�ئ��F?��e��@$��@�v��^�$JQ�)��#���|E�#�)�Ono���̅�&#rp�;)b�:7�,��$�����f1ys{�I�c,��>� ��D�R�:]�h��1��:X��oƵr<�?E����Bg��`]-��@�LMj���r8,�/��q�)x�Znb��s��mX�ف�8�;�F�@!�yS�8�5���k��&_�5V�E�9��@�=�
q��� :��ELN��𴚲(��-u��;�%=��P�ծ~\���Z�&ɏ$ ��*7�d���f��{����2�v�w:3I2�9�����5��%���Wq�7�x/�[I\������
�wGֳ�u�7[>�8�,'���D�_��{CGH���AH�3`g���?��3�����`�%^l>ω]a5YmVa5g����\���'�F#^ 5D�Z�g�AZk ��*���b�@�P+/j�/��;�8��4��ez-�����,��S�ӌ�\�䊰3�r��1e(cPb0��[����4�TeT�fA�@���D�F<�B�5�y!���23��F��^�X���§Nj��-}:6��j秒3C]���j
sZ��~K�t�((�R#�6m(wt>@0W�b���Z���fw;�9Tʧ**gh�d�y2\tj)����4;��ZE�
Zb�Ăt��4Ɯ"�ĦJ�=;�hRQ>���qzx\	<�x#��זxFV�|�մJJ�����Fn>����o��&4����ı�����o�=�z$��k_�	�f٫=;ԕs�0*[��E���߲��r���r������yG�6����#�e�{"�{��g $��f���p�]�Ay5�19��*�@�Ҍ<��tʃ��3U׼�@�4L�ø(��)}�j�)���SE�Ƅ�[b����o5�Z2��K�@�`�/R���Ϧ�;$m�����m	N����ׄ����TxFӒ�X�A|�!��qM��������_�H���I.\��_���7��-X�Lt.-DȰ`��R�#�Yih�W��
-F1X�\|�5����~���e�d�`θcY���J!�_~��ˬ����L�O�A-#�L<��i|L�o� @R+u���|���=<�qR���%�5�>{+����[�|C1E��~��M��|(���A���r��d=;'��&^����>����U��~q�w�m+P�r��m���:����X�����Z�t[��D�sudQ뮍���a�o嗻��>�M�B��� ]��1P�4S0��.��)WF����4)HX����^t��\Ȓ�g�X���"�#ۗ{a�e���2W2I��^e(kx��1��u}���~�C���ݓvz+��p���ѵ�-�4��8s-��2�}��DB{�3�rr�����>��Z��]���	S�ΓI��|��ISh�)5��=S���P'z*��
#���vLʲ���lC����]5]G~:.�%VCWv2�t�R%���?�2<�Ӥ�~��w�U�:�ah��L�Nu署�������"E��2��2g�<:��GŃ�N����f����I��/U��$�����$Sm�#��u�r]�l�>8w���t���3��Z*�@�����^h�Ua
ǫg���J.x�+�K����pj��J���Hm(�V8�!�-��Zj��ÈJ��D�,�.Q ��H?0?G+:�%���ػLˊ�k9�SJ-��Z�H��޶N�8(3�b�#���&׋�g�҅�L�*����~/P'����z	�����e
;�	!�7xh��}�޶���R�3�T*�兣�� (�'����Նlﮋ\�/���_��8s�r��@���~�D�dѤ�q�0���`}�[�r���R�r����""��Z�r/{�,��PBj R.����/�����ج]:�a/�^�ڛ�`|eF�~j&��d���4�o�Fn~��v��+��aҴeߓWtP�� ��|�(�R��<���)�&ê��E ���#B�G�������[��[Ԍa�F������ȼ�R�j�j���D��
`4����|ࠨEq��)	��ء@�C��l]5[B$e��A3�<�:*�$�v%��<-fp�(��`I��.o�t�����Ǵ�τXC_���M����p*�\���QD4���&>"J)Ҧ�_㦣5�k^���5��x'ǖ������ѳtsgW�V��S�6iյ�����,1��Ј����%�����F �T�=9~���)"��y/O��F�C�M��Lc�e�}���#L��v�ĺ�]uGe��a�����#��K�������+'ɓ\�X��KY�ȩ��j	�X��Y"H��poS���u7^C1����S�X��ù�y��d�P�T��I��t7|R�~������3:���	ʒ�~P�6�D�To�wç-o�m��Du�J�W�ք�ev�XI~��)ˣ����Lc�����r�>���\H��\�C���gX��A��^@3)� � 4�#�������_H��L���f	�'�N��{�j�S8�W*����Oq�Y(���H�ذST�	��y����8�/1�\�Zj��3����j�dj�V���0�z��a2��y
����������44mC�����$���`4��+mi���jK]��!����z�+-�����۷ ��[�vs���W�tRź�xޱ�-�V��O[3JŢG
�=�1�VjqQ��0*fߠuJ4CC�ٗ<΅�!�j���W��v��a�0r�����{ m�v��xe���I@�ic�g�5H�����r�� "���|���R&���s�sɞ	"�	�Up����u͜#<!�nE�KӐ>�Y�}T��n���6I~+��TW�ꇆ���!��V=�v�cVL*�j�E��^�W֏X�^)�_��{;E�e�Ꚁ����.���z��o�K/���2˚��K^��Ӛ`�!j��b
�\�]�|���tr'�H��l�JH�S��ݥ�W����ڍ��~��+�F�7&U���Ůs�����PԒyD瓃��و�Z3(�:[Z�sP@�~���+-�]J���i 6L7CS�����VL�8lΪ��vT˃w����(��'����v��Б�,��2Q�a��o33M;]�J��:��&8D��5[z��,~�=큖Ћ9��ݍI;#A�U�}��!�0d�P^����Qc������Mz��^�)��("W3�.n�	��Za�0d�ߟc&��'���1xA:nY��5&����=�ôW(^J>P����e��A���0$�~��i�R1����D���8Py�X��\?��
��}Fj����䍥��:u���FZ�ݳ�f|E'�8[�Lɗ7�y"Ɣ�n�?��.&R�f�H4�-�7A���i�qL�&�s9�����K>!��
n�1��~�]���dM�\��������b�_�u�j�8�1B��s��/b�=kB������^�C'#>��2�6�`� 8/B��=b���N�1R�U��.�ˏ�A�TԮ�pTh�'�����X�>'@�܃����mɬ�R.�Ng�*k���p�G�r�5|���Н#�ʵ����O#~mb<!���#�$z��[+���@Q��;	��L�X�V&ީD�Ԃ^w���Q��g�i�aUo$�Xಛ��$�9��o\0Gշ2��!�S���1d�5�w��-P:3 � &z��S��+7�W$�v�o�{�D�5B�oP"���˫m���fy�goKXS��s+��G�/V*�f��Ύ���~������<�P����T�ʧL�M���;�N�՘��zfS�5��<��4s7�ۊ^���ڵQ�qS���|D�>��H��;�1x�:�SM�t���94ڣi0U�,���0�D���x�D�p�����+��
��尘��K�",U���'�~��h�^�3�o�}�F�bx7k�#Eۏ�R�!�5��?�>��<�ι�na�д)g��%�g�.��$i�`������rET��EUuA\�ؼ�;7Z�B�n�D���T|��sbNGYs �B֣����C�r�\/�.���Jr%�[���M�-eiR����(8	V@Tc��
�)�6�tu*�h�Lt����8�� jb[$�K=M$R&4vAB�ƶ�7�ΜA�[�6o�F� �0Hd|�?a�t���@�l��s�U��{��A�pw�w���M�s�Z��ѵY*0F��w��uj�PFe���"ѹJ&�5��`چ����W��\�?#=s(��Q�B7΋� `@���0,�Pq��a؞]Li�tI]�n�a=2M=8/��U��@H}�3�Q��FSeu�i��V�[�����S(�V+G�tʐ5@��{iקAd��4�xׂ?�QK�|ej)�� ��XH�]�Q��x�-$=|�]��Jb�L1O�au�"��Q���?�p�����Eف�e��ƛ~���%�P�G,�D]Ly�Sl��P���y�����Z�|M��7��mV�m��x�Xz�������(ȑY��O���>5wO����l�^+�G�]m>sQg��zGeY�/ 3�9"\z�E�
l�we�xT���1Ť�W!�2�J�H��-�/�;����[@2�E;6K:�M��k��b�F8ʧ�$к�MQ�,������j�� >X����Sfך��Qi\`���Aq,No��F�P"�W��~�]�h��ޛF�.d�7`��GԹ4��*�PgY\v1"ۈ��z�Q?gQ��DVޔ�>{.LI"�����A��޺s�����}�Ra�'��h&���?�H
��x��XژRZ�.�5v6ENzY[��� �TwF���S��_йp@Բ\J��t�A+qY�ќ~�s�P[�whZ�ũC"	�!��� _o���W��GGP"������̉ �����K���8�+ I#���
$�!�
)?���tE���Iz��ٞu�C��nB)^[k�6Ht"2��FAGÓx1����7�����͇#���X
�Nk�� u���Z<~b��i,i��:^�.���P��~�� S��4��_/^%1d��LV��P��&0�qڧ�	؝���X�eՀ"�R�k�;�yl�;ڎ���g$�-�;�O��8���c�� ,;��2-�Ή�[�,w�|�	#N�/�/��>���j|��Iքi�T#IP4�Ip���b	c
*܁�e����BH�qw@}�0
t��_٧��N|-�t_��s����� *
�AJ,��?�ժ�R�:�q"��>aC�fUU]�μ��.h���B���xi������/�wJH��fx�z=ǿ;WGb��fB��C"~�e?�>ޔF�Jл�"�86���q�_�p�s�Od0XƬ��RWh?_p��@N��e�(8o�K�BI{s��R!�?�r�0��bs6ږ��f�8W����?G�������|>�M�,I�"$l)_y�	F�ʖ\�a+�`�#����ݻ��Q;b)y|�����/��3��h�WPq�h���`znG����.(���Q��reS&q®{KxJ(Y��j���y�nL?������}`�$�e�i�FF������,��D	��ߑ��Y�j�!�
F�{S�Nb~��!?z�͎	���zm����o�<����%l�r�z�$�+�z]3�����<�!k��3Dl���y��Dܢ���ց:�t�ښC2#��b�E]�������aG��6D��N�w���(}S�]Ǽ3���4�2�N��ŝ)�4%�KB����� х^�2��\|w;�E�vך����q���K^H���O�בm(̖(������+c�x�̿:j"ߎ�LKW#�;͟J:��J1�a�3��zV�y2�V��N(l�T[6��S!V�R��d�\-�T\�W�<��-�B+P3A�T�u�Z��l�Ƞ��X(�j��Q���׽�A�j/��\� �\H��i/����~�d�H�$�pê��k�NtR,W�`O�LĈfd�����ҿ��_�B�U�j�����5��	���������Q�FIѺ6ϑB��3�|�#(�#�8�V��iϸ0�[�h���%
~�+=���m�'� }AP��a��B(�\*�a�]�Q�5�r�g�I�
������S�H*�V�~�N~���q��j�"|�����F �ڢu&w���{\��c8 ���.����#Ã�n�p��$�0^	/�l��l7����)db5��$o�?;��mD��@�)%�? ~䱹��c��]�2fYD'�A��$  t�T�(W'�^K�e�;�g��9ߧ�/LzG�^4�P�*{q'R˘f#��K�"O+ |�r���\�)�5��~���n�D�d��]���~mʭ:�F��L�7�Ӊy�	��{c�،��+�G�x$��jvQ�+kϭ$Q�E���ڷ���b��#R
h�$�ܜ*]����'��w$�Ǫ��	����I��י�U�;%o&N|g���X[7���(I��G����VB7x}�C��z�)�IX@�4 ���;���DQ�F"������� 8�9���BI���N=��ѓG�Z˽Qߦ+dZ_l2���Ej�D�Ѐ��z�A�$@��F�SW�3:]�%��6�9��Lv��S`5*��e��������ƶ��O�+_E� d$�$Ujkq�(q?��wǽynbA�,���=���8Ga982v_q���e c�x;�_�N�������ؽ�a��̑GcO�-~D��v��w�<H�3{~h����S�Ԇ�'�3xn�-p�T�TnA�ѣS��e8�Y3w�U�y �?�N?�@T�J���L���ƹ���$�'E��g�v����"�V�^"2�?� ����ڻ(�x;�u"���z~���;<�Sj�3�0���q�_��эkǇ� ��E;�KFk��n�^�٪A�Lg˕/���AR�?�&�D\:,:�ϴ��I��`�ǿ����Ih�bFƳHy�p����Q��z�:;&�e:��W#���!�qm�ȓ�ل
*�8���7�
�Q�w���;�`?�1�*Y��m��H�G����j�1=7�1P���q**�^��D��_rb6a��"3��7���=�o�ӬWbfju��sR��Y|��v�s[�\��)т/x�|��l ��%���ig�j�9k8�b�Jc�V׫��v���~֭��;/���иֿ�)WF��{;���P����qg���V��[npw�4l�}N>��UH@h}�t ��6���M�z�Mx `����|D"0�ݞ�@!�k�ل,������1�pU�
��3Mۢ�ˆ^o7b�M��Z�V��]K��1N����Gו��뢰X�V��"RG���P(U"�q��A� 
��mxi���T�C���֠��~Aw����(�"t�^��Ĉ�����0�E�G��[3N��,T�ܚ��*����*\���o�FQR�A7�; @�֑��ͤ�����A��4�
ϴ1�_�WhX�g6y�M�:M����[��6N��![uS�w;�Y�v�?{����z���)�ew��3F�8k��&b+��>pkB���I���� �o�%�T�<d��VS�qƈ��7�-�*����u��+�@�];��=)L
ω:�����Ad[�f �*Q����p�e���x�/�6L�$t�ԓ~�>Ύ7�����\҆�F��bA�!`:���}��肶bq!G��Ābɬ��n�5 7�����t�!���
�k���q���N�s�������h�a���Ɋ'N������1*	�8#�ܑӕ���!բ%-3�IĽ����I�����5��
�1lqi[�_��F*HX��gr�-�!�i��I@/YM���N��'���6�[��!{��=�@=��D�w^�+���GCwᗕ٘�4�vRy���Y�0���Q��{&�W�U�%���l��Z�|��kz��~r�Z4Sg�aĦ=�;�-
�����u#�j�y���2|��i]� ���}����G;cyB�V.LA���6t�Ռ��������PoXMBè��g�0���ŒI=R�u�������E���/�m"��MHc�G�F"�+����Ҙy0�sb0qg��e�p�E;��i	���U�����,{��C�2|8������2׃�� +[3Q"��gS18g�ou� �.��֬���f�14h�c�W�y-�EiP�F^���:�ˣN?������ۢ�����:�`@k+����\�,�h����V
G�OE`OM���F:'��dˉ�|_���v�O��o3��!T{I���P���Wn�q�4��*�o&��/�UA�_d�&���]�f7	�]ן���������6��dA�x�&b�: @z7@�z i@P��I��U}߿��������!��_G2�ya������k�ρ�4LG�S�D�.���bǵU�r)G`8{ϡ����|��>W�*בDj��(/їɟg+���[7���n:5��<u��\m .�>��C�^��nB��|�Z%�WQ���?a���[����R`��O�H�"� ��O|�R$�()�~E��-$�%��� ")�i��7
,Ś����ذt̀�Ȉ�@2� x*����@���M��L(E1�g��b��c�<̥_��J�#�Q�_�������vß /t��Ζ��Z���-z���oU/'��3`�ǉ���-S��u��o�irL�ʦKwwXa7����pI76`�]��K�.'��lW����a'd�^6 �|M.�����S��Ah���?FL��P&�IV@���pP��]�m_A=����)OXH@�u1��"����><ϋ <&�劘�'	�G��*��5H�p�:��x�G`�`�����+0&�?}K���t]��8�6�A�J0[����0��%.��jk�\���1���?�v��W��w\p��Po�g�٠I�Ѥ	�M$y�g��l�^�@����K�~d&��w6��Ħ��^�	j� s���X_�o�i������+�kX�L>��1^�_@(
��V�T&_s>u)�x���LcKm盰����w�W,@�{��C2%�8��m}����|��>8����f_N�*��x�#~�6�R�b ��:�?v�x0�=�a���%7*�,�2�
�f�N�W"?Lk���P
��!
4v����"������7%{��_!	C��ZƉ��,�8{JM�0�L�襘ϧ���F_Y���k�(c�����80�8%�$c�DS��$�Z?UX_aDq@�ߡMjv����X��DB;�-G�DG�i�ß�Bѹ�_$xϵ,x'΋x�e���hI�TEH�ƫ�K9��P���b�쓷�V��7�Rî��U�J?դC�����%-�~Z�r��b:��t/k�^���O7Wt����g��hh�>��i�M�CQJ�Ҫ~� A����)Yp�Ԯ@���wR߻`|���Mᣛ�^ڭ��ɭ�j���a��͆���x�q�E� ��v������f�0�Muh���,�OW<F78�U�U�5g/����<\���Z:]��鵣y��A T�Lr��0�����ӫSH�7f��qn#�@��4��������������<��uO�Rz�C��XI���y�k۷�h)���c�gLX�Y��+�jk���`!�Gݗ}{=�%T�|�֟��y��pm9��fNan���$� �+����!�C�SZyfؗ1�S�E��"�m=��<)>cu���e����e8�����3�m-�y��$�T���7jK����c���v�{�;*�8����5E���(c��|g��	��ծ��s�į�`u!=��m�$tcd7TE�Ӄ�'���-o� �6<�u��5fY���׭%��Uf��ظ6)wo�gF����$�np��^��^�� F�Dbv�`����m�|@��\��e�t�ᜬ V@4��i��[����(jc �B�B��P�����q�}:���j�ae�x�_@���o8�bx&�I�a����Wh�&�bl��
�j�ߏ�x��؅�������h63o09N��R���팝�@HA�Az&�-��k�&V�úͿ����^��Nt��3/��:�L���l(o��i�O�E-�|�LV���JL�~MP��A������R��ޢz�y�#����c�=���믊22ҳ�yW�� gq_Oǎ�#��[�� �!��_<a�m������5��G@�0�-��쬇:�u�C�)~�G�~)��!X���FL�V!jeE���5�t�M�o���8vv'iU������1~�����S<A{(�q~8�r[ٹ�22��0���l���4C��͏n5L�([d��8���Q�2i@�� �N}�"�x��Z�M�� ��l�����v���b�G���]
3��k�[��L_������8}�S�yT`�T�x]|��gl�$��<f&P�m�t�2�d,���/�}�q��	R�A �7��-�w��V�2-$E6�*�9yW��Gp������&�=�m�{���6����*���C�Kw��f�.2A}�?Þ�`��i� X�jF�}q��J�]�S�W�=�P�p�4��I�2#0��w�)/ӧ��"cmEe��W|4'dC��Ox�p^��=�~\ZӪIk�Ú�dI�#�����l�N[�S�Q���QB��x��{�sm�P�ea�<�p-��]���3*�-;��I�u�9�dM��멶{�0��]���Ýs6�LEND)gm�%:6��Z���e��G=�O�#&AH/�	H��&�u����w����]с���(�Q��a�_A����V&9Y��Z��al�!Rw@T�$�;���M(!�1�����R}���,%]�Dv�NNP=�u��~j"�u֫�z[Ǘ"�6Q}�$3,S�`/��w9�e}�����I�Ej��*���5���D���A�cX�j?AI�[�%�2۶���.���?HK�\#/�Y��d�$�%�A	xy�C�9�J�OO=��Ք�����]Ƨ�C2>�q�I�gZ�!�??�X�x��&�YK��9I�K�$�|�v��\"��7����^�櫢��}/3������[�u|;��ؾb>�����Ĉ
�X^:��ܰG���{S�G���ȳ�P3��^Q}��1و.f�Y��.�'r�?zl��Pe�zG��	*T�X��l��
���5�!�T;̒z�$�{��5N�}v�����i���)*0D���ȭ(��4Gy��C���]���a�6Ĺ�����}Q_P)`<h��'��qÙ<&&�2^�c
oa��ٛu-�wou\�<�J��滮�J���$F��ry-opn�������9s�'����KF��N��1+��O�2�m�X.��#��0/5l���n5�f�x�Ρ06tI���yZ�@�e����$�h0ڎ�m)��Y�;��3�Sb�d8`��v�i9⧏���(pͿԼ�׻�q{2d6�)�;��qL���c'GU��`}�he��K�Ⲇ��l�tE˧�0h@e��o\�dέ�w G�JQ� ����iXx���g�    YZ