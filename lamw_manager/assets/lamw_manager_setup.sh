#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2744242830"
MD5="51fa4e052b4663cd59fa012226f9bfa6"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22704"
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
	echo Date of packaging: Fri Jun 18 11:18:33 -03 2021
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
�7zXZ  �ִF !   �X���Xo] �}��1Dd]����P�t�D�r�ew�Ҷ����z7��.W��Q�I��ge��;�ȝ?,�d\qI	��t�v"�<�'�t5%%~��&�\AD����\�'��$|
Ģ~IGz?@͌v�����&߷��XՃr|������-��~qÄ2D;��`+�zGXK��DEY���H�1l^+�	�	��+��E9�.�ӛ�l;��|^Z����jK�P�^�t4Y��زX!�����W^0�W�-ƊZH����n��
��$u��{-�?4�b�k;����{�⏼��2��T���.�ω�=:7¶�XX�|�%��Ę�,Hx8�Ҧ�X�����݁Ɯ3�A0,�d�Iy�`\��j-�a��]�� �ꜲB/t㑹����-�VF�C�'ԕj�(�E4�U�'��?��2V�i�%>
�ɓ|��Uw�;d���~��n%�B.�`y�Y�mE{}������U�0}"�q��l����`���J����|BP_ �o?����Pz�u)e`��heEQ6���W�?�����<Y���2f>����C�9�`i�ó��������9�ch mAgS�L!vx#�󅝻�M]y���D�/�0�m���w�zlHK�P�_����h��.������a����T�:�b�<R�iػ.0tR����3�-����'�mHBgC�]9Ȫ#�ɣ�w�v���.b��@_�@|=2rOa��oY��9h���[D5|���"[_ZE�'����Lm�ޟ��Z>jD3�}��-Ǉ�r|��
\c9"=J}��;$�T�m�$F�r����)���bX�M׋�𳛃����]l��t��s�:9\�-�;�z��\<�*��{]��-�]�Xc�P�{d��%����`G2Do^�Խ�^Y;���0;bT�A��@PS��JL��:{�#��4A�A��;˕�ՠ��4~��&Es�!��|�<G%��Y�M	!{�0ʟ�5Fu>9ڎIB4:�w54[�_��-%U9��O����\[��\��f�v>p`�
*���w��&),�Z��@P`�ᗎ�IbRz|���bP'& \�er�rg��14�p,��
���3�F˟���S��il�Z}C|�R���qq��2�F6���j���2te66`���w7[���[,�ۂ_�y��g�N)����:���P�p�:�&�ix-�i�X}��
�wލ��9q�M�Z��oj�\A!���ӗ4��������v�0�q�4u�����:.�h�T17�X##8�ǟ��׆�a�e���ѫ?(���E����Z�Pէ���M��|*���M�f�HVQ�6���xLzs²ߞ��u���	N֊N��>��[���YW�î�@�rO�<s*�"&�'Sy��h�7�����po,�(��6U��h ���f��.�
����s"�x�:f.D�L�8})l�պ��prA�� �N�:�*�Υ�_ t	
+�G�/[F�����C���g��*&�K@l��������q����rp��?9`.�#J�	b@$ŵ���0�Bt7+�[|��xO.���]8Њt5fa^�	>��Y��4�ɳ;�������I�̩��9�@-c �_W�����^��'\�̲�_*�>vM���$^l��k����Y%�Km�]+���@�t���Sg��ܹ1�-�I�j˹�OH��ᔞ���놏^���\l5yP؂����@k�Qw��п����4�f6p.�m���g���r������u"� ��@���}h�y��ֶjBp�|&��@�ݷ"�;��`�����lt���)<5�G�?����TSRW�;�.0�c�~���.�����ï�ȡ�A����h��O���A��f����0�s�$h����|X��dy�,�К��]�/|��  q�o���SϺE@�=�d�x��J�=S����r�:�&(������Ku�61��Stq$�.�T�|�\�+L�'Ě�#������nKA}w�3�bT(cx��%r���9Xu�~x23�����l���|����}~;��)S�rSz�l�5PR�uX�E�<?����I�(�_�w�q�o�m?�]4�Qo�ۿ���%~��Y��}�g%��aY���;��}a�,J��w}�)"�P��w���Sa��$0�3=1)Q7yVW	�k�e��_旰�g�aa�(�l�ټ�6�Dm]=O��Z�RCR�'>��~gX���K��$�tT	�F���m�颢 $��5���R7��$!��x��f�^͇��9_��<�lπ��ؤQH�L��u�v1�T0�4�c�W��	�4�D������DDo���%����
e�p�0j�	f����,�k�oK	jZ�|� g�䵜3�S除��+��f��uP�I�Z����У����T?�"� M0'+#m��#��&J�!����QN]�u�$2���y|S���胼SJ�>�g�>�c�K2(����A:���lA���޻���w����@)����TX)$Ҿ�4H�lY�����8�������'��b������8!�<�\8T���qЈ�9gpoW*<#���CZ�y�`�ǽ�H���2�^	z=���)+�Б\ ����zV
�=��,ߚ�� ��l�Ղ�ǀ8Tळ�%���y��T��쵊������_��I*(�j3Mi����m�҄t�&�������-�|h�_nJvKB������܌e��Ybq�8�}q�����Px`��>|�:���X`]O">l |�j�f*#�0�d�G�	l=�(O{���j���ߵ�4��Mhn��S������w_���[�8!g�lgB�+%�o��t&�Ǐ[����7-�׌i}����v�O���Y�����Q1?_�G��_�;� ��;��Y�Lk����Ō"��|ˌT0����㧿��=�p��֫�.�U%rE!랸�c�$���J-�m��v�8f��1��z�[�𠱓\\P3�m��AU�����[��r�`8���0v�4Ê�<:��(�3��,tc��R�N��(=�bN�R(+�{E�dv��1�ĉ��U#�Į[�d�����U-�<ۓ'��o���E�9Â`�hP�N"Sv8-�ނ�E<����(�$��=K4;�sbɸ�cV�z#��"�C ]y��.��l ~�ޢ�����b-�9o5�
O�ΎQQT5�a�b�8�y)���llo�R����S/���} ���E����Ke��⿈8�~�h����mZ�87d�z�Ŋ��G6N�z�J����µn�vҲ(�TF����;w�h�%ܪG��h!v��=��m�m	�bH�gWE�9.�o��=���m//N� �*��Aω�L�OJ�/=�{E>,��?���əJ��p�U.���Rs�e�;�OL�3�>ENn���	L���و���K������	�����L�#�3���5$p-��?��M�X.����vO<��k*�R�G�@t(r�췻�V#l��"������ǯ��)�x����b� }@t�	<���A��a6��~����w�'��2	�Q?�+�13d�Y�%�ML9�J>1s%����#�x!۬]C"'�ć���Ӊ�:?m�Fr�3-?B��З0ȓl]3Y�U��M�d93f�I�`�����u�a>��(�o�V�H�V[ɐ�ڹ�,B��4�پ���KV0���ҧ9��,\��-�ߋf>�R���r@_��/�6��-P��j�����6��-�'�n���jt���@�����:\��e��#�f�q7;���&,�S���X�!J:�����q 0�$N%o<�~e�戉�� ��p�~�Om�x�3�p\��$�&��GLh�	\SX ��B�� @ED9��s�'���M$xA�uav�ac$4U]Y��c٦����^�\8��@�2�)kU���yPH#Z��'== m��i]Ğ����D��%���S���
�9�M]��0�w`�-�Eu�x�;�&Y���
�I�U��bY�&pc(?���'v,i0�y@�?M|���!%��8Z����)V�����.���V*>��?��1���'�T�S_��E��"a���YY���h�k�A� rQ�bAt�"��>��x/���A�`<����X�;�z]շ g��@��}�� t��
���ˏ�R��dǠ��E�l ��t�x��W�>d�W0��v�׭���U�ƍ_X�q���7R���jl�(��`ً������ny�7ʜyAD��Ǽ]rO�@�a赒	�j��E�hA:������U|�H���%��C���C�&Cg�������ģ1M~ꅪ���e"�0�1�Xk'�P<��f�&�|	��*����pk�����L9��������һ�u�o�>�))pSW��7Ή/�[���m������H���ἑ�>kD�Զ"�Ժ���^	Y7�&�mύ�_b������J��a��Jʰ�%�GE��(>4A%�+����5tΏ��$_ǂ`�V�p�F���Lb���k`�qp��3?>�fƃJ�S5W�C;6 �������9f�J<�6 ������%-C�-k�r!ń��ǛV������|grMq���4Gvo��L�t^�b�"����Ɛ����P�>X�,�D����/�R�-xQc���Jо�GK�CA�<y�I{�R�6�����̣(�K+m�d����G�c�B�������A-�GIL�!)>���N�ʮ?s��*�	H�7۔�5���ȱ��&J��5�_m;�j�y��e�-a��]
��W��nt�@(�V�2EO�S�*Ӷ�a����]�`���S�B;6Y��Ӳg��?�Gړ/ie��k��͆�c��P�nt��r��'p[��,����̑��@SŒGuU�b�m ���'$V��-��|h��9���Hq.��	q�b���!$i��T0�)vdD����ۘ,�&�	�}._i�M{�rs�q�vÜ��ʋZ�H��Z�_a-�e��ڟD�S}�Ԁo�bm����!j��S��n�e��:�D�O��,��TU� Ҋ�}��#Ssܼ_�h���_�����폒��a����s��}4(c[��� �D5���� ���$���&�>��Xpؽ%f#c<�i�����,��x���l�� HڄkܖY-w!��x���k�8N��s�C�Q*JL�������з��T0f_���,�?��X������z$��vfL
wZC==�l�>l�u��Mv���S�����ȗc�жH�QlO��ԹVwFt�II�"2m��?��m��-&���mV%�=OY溜�~2�|l�^�t��/͵O|��>MP�s�78�G�WrGK$�19���s7ꅭ޾i�3�:xw��}"F�;\�c�<�\`�>��`�4�|����	�����ߢ�_$�!H~���B�s����SAic%\J#t7����L�(�G��!E�#�BL��� �iKY��d����.�E�U�b��iS_.�lg~-V#3R�B5�LN���d�j���
6���+�5E�C�b9uFԊ�$!¶<�u�)�}�����P�i5���k}����~���r�w�k(C��9,���B�qxD�z\�d8>V��)�����ޥa�*��Bt5�{�"ªP�
�C|�o�]��&f#��Q	��3B&$8&n>&K�?t�%Y�Y��'�{�)�:��+�Q1F�e��{�3v�[�F(M�&v83r͡ywo��s��ٳT�
u�qKIk~�x9l\�3�S�8��M�_�e
�f�T��4,��7R�ʡ��Z�*�T��Oo�0����T�dM*��mcm���kn?8���o;fDAw�@�k3��Y��>^���S_A��Io�\��Hc��I-��F.��AF�JC�O�K���l��JWC/��N^���܉�:��к Y�!������ ;Q��h`%G��ث��l��鮵NO�\g�f���8�;I7�}E;��J�2�Ů���a�ljb��f�U0z��+x�Uq���ht�@%k�ÊT�J׊7�ډ#^��}�P?��U��e��D�NRL���g�h�;�o�	���o>T4�1 ��Z�嚁6@��Y̆.*��El��s��T��C�!�E,$������δ�I�:r�vv�r���0S���e�i�B,(�rmq��/\�(��W$�)(:rq�B��mF80p-�gK{Y�o����z|��w8����,W�d�@���c��`�s��� _]s�0V��k:M�?$�L����ak�%�Z����/xm m�yY���� 8%�&��_P�m��k8�uv-��dˀ��^^�Y.����D3⮆��.��;+�OIf��?P���Q7�7�&���DMAɹ��ui�y���w�S���9%���}��9&�w�K���*C��A�P2��a�p���ZO���5!�{�3�������c.SB)�¥��1�9ɿL!�����'���59	�_x� �Qݐ{�m�H���	�?���~�p�Ѩ�q>��S��q'�	*M��*$Q[��'~U9@!]�#�o��b���� E���8j����^qD�?#�p��S6-5E����5��En)y��R�Wg�p��2�ٝ�:g�JY��c�q��p=�o����YF5	6��e�&����uԭ�r��ن!�����U���LT���v7֢G|yv�l[�&V h��Y�!aQ5IiY3ܿ�M1XL������U��Ye�\c�����5p�BUn�0T63��z�����m@y��$�ț�����")�n�EE�'"I��|�r����)�8�g� �.��Kq�&�X�WS}O�p�P� �~`�$|{j���еEߥ��=S,ru���SX�Yΰ��@'���$��#~x�'��8U���4�'��dU�\��_k]��_o���+]J����b�J[�/ ���"7�V�j�g c,�:t�[�2��]L��nj�2����]Çx���n�߂<���_jO��qy�)�����i������/�U?;��Xc'�1A)/���1�X���9"J�G�[~V��mQ�� Y�B�t�[�2������v��D�Q_�|$��vL��s|���'��x�M� 4��X� ��mbu�?�k%�������	� ��8F}��`�2��j=���]͚>��V��1@������o$�<��G6hj�!����ͼlK�����C�A�p������$r7	��s2D�q' C]e-�l,$]�֑ݐnak�6�o��;����j�n����k0[/���h	��p@Ӕ�fF\-8�*��;�����e}vCBi�1t��?9T�̔/��}(�c�78Iױ)^��4'����)>f�+�u�Rh_I63A������z�d|�=�����m�n�O�Ɵ/(P��v�������lVe�]8��� @�K��鐅�����dȖ��)���!Ǟ�.3�� ��p������}�]�&����:��q�űѷ �`G�1�\�7���������V�[��ȳ��Z���{Z�W�,��/�'K/�I(��\	���s{▭��e�`ܸ��������";k��P�l��@OU(G`12����L���{ Z@R��n-A��������L�:�4 �ӽ�ծ'5��/0�ϖ�<&�ֿ'ɩv���x$�Qפ��A�(�n"yE����)�j��=Gwh���-
4@�f����%0�_x�����=���=��X���!Ƀ�N������<������\�K��ϣ�Aj҇�}�Y��5��B఻|��̏l��Sr[� �����=���M�.���>�A	��ܐ�:O��)Ů�6��[��B�]�����Tz��6o�����ّ%�T������&Ģ2t{�z:i�=�Ɂ��D
������O��������[��Dr�c�Qa(X��櫳G4j�@Q�n�]��3��x1�\�H��g �L������2jr?��=�7m\�yC�JC��"_/��+%
�/hc~AO�0/��P>��b厏4M���C(ja��a����]=����=O�+`�*P�r*pu�3!�t�>�ʙ��Q��N6���HǴ�&�m0ll�U���Qb���fw�(v6�����7B��]�8���o����m84b��ӕ=��M<Ok�eh���K,1W�Kں���4�o2�T%{D_�9�{�])�\K�����}�]/���{���/[�[Edt���}��HV�1�]�������N����"�,��R]&)�d�'��gp7+7RA�f2��Q;����ç�E��)�iw��fT�X�~OC;�}̰7�W��6����d�K3�\kn��&��|=�Zy.W�.|o��UY�,B���I�M����T>���݇�lLŚ��e8�zo>\��/b�����r%��) 7�	���S�gC�2�"�\���>�f�;��u��5�aґ"�bu�&��b�����t���j*���'����U�m_��NEH��[�~��2˶��E����N�����`OJD��F���b��d�<z�O���shC�99�~i���I\�שF�wl\�f���7vD�]������T�,�$������m|9|�3�/`�����fK�*�sf���ʹ/�A
��B:(�N?Z�~&D#,M��cE��P�q�t���\�C�3Y��,.�d���린�a�mF5�*����,�-$d����*b���|hPĞ�ՁO#��=��]���|rU
��i��U�?�K �{��~�2� ;"���bVZ�"�h�oŵ��ڜ���*4eo�a[IڱV�6�y������EثJw��}�>9Î@����8N,���k���0^�C[M���$�f"V	�����׶���]X��q��a�4�.��wN&wIל�Z���rɮ�QB>�y��-+�`���8�Hj�G�����2��:���[/"��&�Q`��h�6�&�w���A��c\W��G6j�\���Cu���y���ӕ�T�!�8nN�_[���TC�*s�&�	�+����epI�����:r�1��B��O�JB�0�)s6a����A�_�]w?�X��k8��b����EW���؂����jɷ�#9���,���!Τd����	����Y=9������^��-ѱ��P��]�#�����s�@O,¸fsv���x�#SEM{`�e.S�U�7P��4b��.3���Xxca�za�'g��n��ll?�n�-,��.��J>ϡ	d�؄��DϭHfeR�;�lG�J��z����o�[�F��c�X��РDIi�|�U��ETvS��Z�A�X����7����TB]�\���6Eώ�civ!�+=���7��ι���}k�TV~G��ܴM�9��`e�KO��T���=ХiN%��v�]�P���E���}:Q�@�
Ǔ�f�r�'❐߈/��'-���_H���綿��?T+����XO�f*_ ��S�(\9���Xǃ�TgdY#����@�B��q�r�tOX��w���<���M�t,bv-�ї)�ec��:	W�U]IC�l�Қ.Ե��}G�3q]� r��[)���?������dO�䞠<�#B&�eףV�����z����k��(7���Sہ�4W6���c��h���.&zD�<k
Q��(`�i'���?۷.e@�@>y?�ni���|W��[DL`��U��hsz$&�w:H?�6�"�M�����kbb��=O�}qx{v6]����H�*��`�v��}�[Í�e`�n��$��:��]���Z�P�� �g�,�πq��>�p��/i�O�o�n9��/l6 ?���f��a����s%{d{F�L��9��h6�BP�¥�؉j��K��(��t�*>�*H����0ϑ]|��幥#Iiw�WW7�'���|T��hD�E��M�,o�Y������j:X�9�,�H_� B[�>��5�(Z����9�R"#6���Nj�!BJ��_�e(٣i���>������U6���E1��pW����G�%�-�%VtK��F�2/�2���M�SL_�a�Kx����Eϙ� �f��M��U����X�5M\g)<�c[�n�\�U=U��;�ZC��DE�}x�c��g��޿��^��0�P�K~C�	$W�
�b�����Q5#'�߸������:���!K�:C9����s^s+^M�#�� )K�n�'�z�Ϭ�����裁��_��ff0?D�#(_�*�YB�R�����]U°�Ջ0�!+�##����+
�o7�O+��:���!�`-��B��Ƒ*Έ>X�of��1��*��%��A1]n`��vԫ��:K{T�s�3��:��F=?o��1Ѓ�7��_(T�5����%�\o�/	����[��:F"�fz��wP���U�\�<������sAr��8MZF'Z��<�\2bb �}n�4�*ר����U"<ѶX��:��z��s*��@Y�Cϝ����AJq�Pp8As��S��	c���W����o>N��H_I7��S�a�xp�P&/C4��ŵe�z�a�iNF��#!�65-�n_â\�x���������9������������%{��k�#n�����T��X]��͋��|��l ����f��u�t)`g�H��m	�ei�[0�髒�y��=ԕO�������	j�Wz0�!���g��]F�������Sk?d�Xrj2]J��tܨz����܉���X�?��2t,c�!يԦ��?�<;�k}ۀ0��?�3�e���?BJ2RJ�c	'��$Q�w��4�� ֠h��y9@ ���/٣�"�Pcq�O���	�;�:֡P�>OH����u2�T�t�3jѮ���{D��t�,�>HS ~|z��*��r�����ɒh^ۛi�P��~'�C�ßpI��� ܱx�6-,ǉ�3��~��4�pe���whV�W��^��V�#zF��s��&�V.a]R�V���u�G�"8���B$���f�>)��=��`t�wKw8�8�'�s�������=wMT����
�M꯮[�D�F��z��"�����ފ.}�g;���Ի������ͷ�����D�*!Z7�jp%o������k0��``�X����
�%aO���2�G	V|>~$QZ��a]�.Hb�7���[��,ׁ}I \�"�V�̗�Ը:â�A���}�v)|�.6<��h.��m
��}��a~ڹ�7`��bbf�b�ڑ�-Z�\�$4;�	�W�0�S���TjG3�ר�R籂�+ 0��I�1M�u�إ�dҌ��i�V���ؗ�e�RC��+��k�N�-U���4kd{��}/�B�J�)r��fƖ�6��]�+�u���4o�����#�|ۼ��X��镍�N��t�H��B[���+e��t5��Ɲ}x�w��D&��<r�+I�ښ�hȣ�$s�@�Yo�k�Ӥ� TI�aJ�Sw�e�6� �h�P��gz���f��l�KlF%��_q١;|e(�rfT?�G�9��
V�uN�q.Svo0'"�	���A�U���d�kY�\U�,��t]�'W�β�ԓ�Z�o����Q��F�꒔.z�k�S;|�U��G@Rt�Tr�t��	�+��f�t1��?�F��V�L�*���c�_x6D�f��Rn�%�T|��F����ܴ�������S_-��J�������۰�E&[�3(��s荱�!u�Am=��C��0R�h�����d�C�H�]�Q�� 7"1x�Xh�I/'N���+g�ې�t����sq�sDeu\�IH�hӐ4�Pv��>��p�'��e�m#�#�6�؏�=��v�gmކ�~<8!ބN�1��A���X4wA:q?�� <u��"��d���6�|Ƅ��5gqN�V��W@%-�6�3�����͐��;bv?ȌF���k���&ޣ�&Ԭ,�yG�Y�z�E�0�w��䯁�^)>L�Lf\Hҟ�
oF����F�2�U��qV�p��h�v���K�����n������j[vHJ�E��?�N�s.��,��ƣ0���/���g�y�K���P���Ǯϙ�d��u&&�z-}>�g�&C%��B�=��m��8Hi��ю��xFcZ#�,K�t7���v���ʪD$I���a�i�'g��T&����I���v�	3���9x0�4ϓu��֏[G�}�)�m��}$QتU��)���F	R��s�M���jht�L)�G�U���?�o�~Ǜ>�ő��{�?��������P��3 ��n�����
�ɰƮ� ko�d�����֗yAM�A���6[����A�Xo&�k������=M-���1��t��$�����ЦPfH`C�
�M:�����=���q��I�.��r��uO�S���N�@����?b�����P۱�O���4�1��q�H���ÖV�(O�T���
�r�+ix��gؤ��P9Ϥ$4���*bZ�I�8t{�τ��{_TJqv�4Y�%�խ�p ?@�TG��bw����� �A4(�tfS�o�4��� ��֔x�d�Kz�+׉�S���o�w�
�`�(�y!��|��{j%�)Ӂ/��>��#��W�?r����!��;�Hǔ�*�*�{�Iz��8}� �E�m�ƃ,��q��h�ʠ11`9�P�2�[Z3�I�� 7�	Ŧn�ḳ�f`*(-�����*g'q�|����@r�1u��&wq!�,=�1|9t�m�����&L$����D�/��/����:��;����5����]��¾�'��=>Cg,��W�%�Ӑ�?�k�l8ݙW��xc��x�{]]�X4x�G�I��u
��6���s}�i�$���R���F�	�cT$4���!��Y�dϐ�Qه���p8)i�]�����O�u@E/��Pg�pt͖�(a�#K�|�B���k�*�W�5kA
W���F���#����Ӣ]>X��ٕB=Ԋ��sYG��@ M��Dϋ-�2�}s�B. �*p'���\��JG*O*:��J%��V?�vBA�K��?�L�P^���yy�d�8��<���ޗ��DBSP�)"C`ǀX�g�E|:.�c2���F�(*�����d�&��MB���L��9�z?!��C�,�������B��/���0��L/�$�:��cR��]��	�c_��͑�<X}~b�P���@�G�`y�[����������8u�3�3u8��Z`���|Ԗ'L���4j0+�6�x���y)-P�f
I�^��vr(�MRªL_��K���p=	Η?n!�`�m���y�p����!�+��y9H ����Փ�O��1��[���sX�+�m$f?	��	���Urq�|=2�W@)�w�������|��Yh��i;#����OɡO��)ʠ�����@P�,Ld��+�	�<��&L2R9�5l���!��̬���X�RM��7���i�<m���.�JL'{&�������!5�٦�	�BP�61��wh�����x�1e�N�.��W�F����J=r.d��p�^�er�j�{##��_Zq[� H�FR("x��W���)�d� Y:�8+a>���b�\�8��>Q�T),!�B�<y����	N��p*cϥozf{߂�
Oe�'Sr��iu|��:��#�l+.C�؏|�Ul"�������3Ū�@�����i�D��Yn������ں��x�W3��~`�����K�dI7��$��$�I��|!=\|��ڼ!�٢�F���b2�M]듵��H7�8`$q�D�D v��7
�ǮT��~����uuޚ�$jRh��cH\��֐��qT�]q�|��r��d�o��C��v[��
�]e����@��l�U���e�H�]"�eߺ�bt(�0���L�V��G7@?xW�1p��)!���-F���7ۼY9�������|�6�7����l�J��:ت,���}� ӊa^x ?W4�e�v�����Se66�jD�j�O�"`\�=��Y��Xvߏ���g*{���� E��M��A��m�:��Q�)z�s;�)�?ܑG�i߂ql�q�-�9XEcB�C�\�:o:__��[���U���/����F'��� +�}8���3��7у)"�iG�h��1�N����Ѕʙ]	�C���"a�R�u����ؘ�e�c,�z��`�@��c>�]o���6�f.����d�����e�CtˮU��HXz��0�������'kBܿP��i�jNqz˜���$^v�^և��W��-U���iΪ[<
�rlxPLBa��j�7�_�v�������v")(6¶�o5"�]��rH���b�Z��b�#��^��\���;�x��QUU�	`{�F����ĩ�1��4���:�|��z^*9^����e�{�� Q��)`�+p�7��=�|=,����V3'��5��JL4�V\;�Z�U�Ῥ]�W��ױ_�T�	�����\N�{Wo����kN0^�k���d11�-���
��*��3F��k��t ��@<:�Gq��+4�Q���OV���1	������ w�@X��?�V�6�J�Bp�$����%�n���|�ɳ��ڏ�Q0��gcq�Cd�o3�6WʄN���O�4���մ_ �	_�α��[���L��8�0K*������y(�&�AA����p�]̷��!��*8x�.,#3M�X���@ЂoR�Ec�:����m��+�����fѱ�ί֢�R���?�h)O�n\�H�i�}SK�Zxl��;A
+�9ˢ�.ж�cmܛNGp�oC �/���XS����1xX�]�r�{��W3L!OY�v������O��
�t)��s�}���_KΏ��(����ٜ ��r9��ti�f�͆���&縮�-;d s�m�qE���h@�6�.�8\���nR�"1�Er a�a��֌Q�$���2Z�;�'#,:�g�0;b��qR�������Ԟ�cHt|}����*0�~�/vK���3��2�Nr�vѱ��1TR��>�R?��sW��D��vx��_A%|i�����t{C��[�RX�����ZL�G�8s����N8�M`S5#p�1�U�И�)!uA��'�eߤ]����JC��}a �e�Y��Y_ܑ�����h�R�����B��E�|��Dؘ�E��12�}�М�_�M��%OH�(>r��r#;��kWiL�`U�knrG�"V܀�eu/J&�1���P�^wh�ӊ��O��p�oOY��+��3jva���O�Ѵ����DC�XOi�,i�8���}�?�-��QS^*��goJW	Ε�4�;�F�1�+f홒�t�!WQ4]s�KuH�`�W�G�	A�Y�lr8�_���z�l�^X3W	Xy�s���C���m|��;��״�i7,��ݖ���zz�8��
疏[� 3y�=yC'����C(c���.0 U7M@������(�A9K�.%�m��� ێ��
-�L�H�]�ظ1Ocx�
��H���/d��g9l�Jn��Ĳ_�uw�y$�j��1���Jp�gk��M8�pB�T'ᘾR��,`������5�v0�kN�5�UT�B��$��Q(�<Tv���˴�r�x��zN!0�x������tQ�hSࢹ�!�j��P�ԯ���S	��>y<��ޢL����z��jl�k{ǟ=f�/Nf���խf-�>�,��u�,%��M�ڄ��P�V8����BM�Ҋ	ܪD��o1��ٷ J��_y��	�LG.c��P�?,��4W�R��
�aȒ���W7�س�i�C����Jfk�_Vk^P�#��o�$8Γ�hƓ=nĮy��w�A'���rY��Ľ@���>��Q�J��\lӥ�ϊ^���,�5i�Ԃ����u�e�?m�K�O����`$�J��?�vy6�{�'��@������e}So<�V�PQ�Y6 )��%��:�V/C2/���h��C*�E��B�ㇱO�q1�~��Hb�7y�)'�N���~.5J·�,���^ͦ�T��E���3s���N\������R��O�(����T8E�����h�� Zɘ�-}��\	����+�a��"��Nh7}u$�m�t ��Y�o4mu��.�=����c�"8�i���0��*CY�dzt��	��R_�S�i�qs�pƌ�&jd��Mq�ecE�D�"�48	�P�OHH,���[��t�34v�S�]"�`�Z�Ϊ�A!�(f�y���:��{���l-�<(W��B��{�	a�r�O����<eP�.Y�h�pY�to�殜W�����l?�󹪻�<H�#�`���ѪLLqV�Rע��c�޲�EA�\25��]�A��Ȳ	C��?�~S�iMȹ !�Vft�	�(�W���U;�=�ܰwpK���~�(��3nF��J���� H���I9T�A3�2�g��	��y^�	]�@?�
�Dd+�ӊ��H�GM��?e4�U���� R�Z���i�6���A'O,�oE�L�y�x�V�"��-ʐ��M�ٔ�p���D.�{c���\'�c��2'��]U�l���u����
�$o�,{FA~ɑ>��i}��NL��s��DC�f�j�q�SЇ�?Zq�ld�jЈ<ླྀ��0�]ߔ���
YG�V����]�b�7i��C���'?O�(��"����E��N��;j�p��t7��R���|e/����Yz����nS�T0{S��'U+�6�����s���T��? �ikj��܂���J��&�}���������4.�i���9箉9G#[=0N�ئ��Y���fН��?E����::�I�4�~�O��l������2X�6����u~x�`$�ͧ%�8����'��e`�?L��_d�d�i
������b��'��OObA��������&G���#��G�[+���J�ne�����������T8B�!�U�\��v�a���6 .��6��G��g��e��Hu��͒����u�It�o��I�� 2�	������;nwV5�����eC\��K�ʖ+�
���&'��ps���#}3����Z�[�����r�9ߵIL�#����x��Q�@ ?�PiC�i�4�t�D3y�1��)�;k�Óc�wm�^zp̤C��U����s�4�J��}b�)�{j0���6�k�&h0�a��Z��u��GP.�c˓wU_�C�z��mAm�o!��5N�}�o7�"M?!�j/�a�/n�>zˤ����}#���[��q��jķ*���m�KL!�}]�:j"{��n�ā̑�H��W�E�` �u}�jTM�4�Z�4mH�0���\���~�δXMX��RGBL���Ql���؞��e�=(;���׫�ȁ����ҟ?mo��4)��~�ƙ�{��9��C�v��;5;:ә�(R0:b���V&L���×�Аs�#_�B�фR��W�z6�O�zd���8J�:3*���F'���E\ޗIqx4�P�$i�5�ϱ\�=�-#�#��2��p�j֊e���S������u�꧑C���F�PmB�K#��3O���?�M�o	T�hܚ�?>f0����?�%�n� ���!��]85:�!�h��>�>:�+���%"����|��;N̈́���������G�iZN0�ꝢS'[��L�5 ���}�NrZ��9c���K��*@BvgWS��b�4f1v���d��zz-U";g�^�����+;�R@�8�w)$��~h��7� `t�
�"�����k�c:�6`��~��cs|�C|˴Ǭ��y�0�X@;m���k��UR����_���l��qΦ/�nK��f'����V��+>?0�@!��I?V���$�'�_�yOm_��S�e[^���f��Q���O���F؍ �5�A[B�+�����a&�ESmz��YK�?+cp��ࣺ���׺fͦ�T"�$��Ss�@H���M� c�>�F��n��h����|�]�o�E�_�\��7t���\G�������jT�cR�74>	�3���D��(wIL�2.M˺��}�Q���[\���/�D�	L#��q�	�y��VW��9���pf�#��aң�8V�lf� F����t-�6�w����k<˖ւ�7���r��Hֺ�υ��ŭ#Ò�&4�9�&�I��h��\nF���f���y�:�f�Y�������:�nđK}V�"#�<��rN 6�EP�!��+�V�v9�2��5f��_ǒ�y���v��,^����3\0|�(k�o̿h�cȌc��rm�`�K�_�bv�|1fD����c��)vÝ����A��{�ÅL���j�Ug/�.WVl`��2z�ʯ��$+��E��5�r��u�N���O�!H�z8��f���Μ�d�QB�x��d����e��+���|��`�T��C�:[��.7�����O���ϭ���Fgq״T
'd�fH~�$>�*���X��Mk����H�~��MD�7Mr���ʰ�Y�)�WK���:���*_�X�����G�h���D���W��M��z�ɹ�Zt%@l!����m�'��Α��tmX��/kXJS�d��[&v�-dl-nK�8�D�C�=��So_�������薽&A���b��P�����Zh+�Q�ԋ�/:KzE�)m��Frb.yK�'�yk�C$#�*���s_�?��X}|�6�{W�����ۿA�Q{�[*p����?���
���W_ViX%Ƭq����S4�Ư��
z���=ɞ׊9�]xI+��F��!��iRe��R�u� d��8	Z��V#h�^;��N"�+o��T�-���1�]�l���v�B�%�+��?(d�y͇��%і��z231�%�*�x���{2A����v@ҶA�B�Ђ�oG�[Jmb�)F�2������䰍Q=Z�Nc81�
z�&�<�C�� ���[^�xKu��n~L��g��Z�v����ߌ#6�mF},$�e����BX�ލ��[Z\�=:�hE���&�9R��A}���V��Xd���1e�*}2���0��Z�SA�9��'�3�J�����9�.�F6i`9a�(�`"	�/�7�����m#��,5v6�G�In���q�ք�S�����]!95�nN�m��.�9�8zO��ɋ+�����Od��v��!���q�Dj�k���'�;wܣ~EL����t�R�_=!	��җ+kE�[~j���9������*�n|Q�����@�������kOqf����+�^z��WJ���#�S���\��m��d�s��.~R�@�H�m��H�����MY;���.LM�
�Uf���d(��K����E����qc�\>e�q-S��5U"������T`e�g �s$e�#4N;�y�S�1qI����p�[׺<�o���o���#.�N�ADmVb�]�΁F�0؈�i=:Z�am��6�T��g��"nD�����z䓼��dD�~��Q������6}၎����H&�K�ЫKj�/E�?'>��:q��1-mt`��q�+?V���ԧ�w��a��C_?�_�<�p�r$N��W�üu��χ�����
��1�yFa�vR�9���w�Qd#Ԏl���@&�I�&��~"YڰJ����>9�+�& m�ɨVF�VwI D��=���� �Z_q���^Jb\�N��ї���ɀ�MPbY\M6�^�O^�3���w�>Tn�R���-��ڎ��!�삩#���~z�c���B)?g�\�M��� 

u�&qh�شU��1�+MYR[Q��R
�]z�����}y���[�\1 �^F�޿&��J�*4�����v���'3�z�֢<w������$!��'=?}���O^���2�4mF��[i�NT��������]s�d"`-Rⵒ�y��J+䃰3ܴ��c�Sq�{�5֘�+��RlC�?�9N�'f	��P�	\��fq�zף���	��`HI񦪶���0؍�~��a��NsWF��+ؿ�	-3e-��W��n����JB|p!�a����eHsj#���-���Ρ�sd5y^�ܙ̄M���(�x�ט�_��cqn���fu�6�;��]�B�"�{���J�<ӧ��� �.P�%�N�84ˡ!��B�����]�U��5(��B���c)�z�5g��_4 ��>vI�&�߻����{��k�ۆ�s Mr���vٓ�2���Q]�i�� CW��꼞�~*�Y�{�s��5�+��:2�ɯؕ�c��o#���<"��B�ֈ�`������?�\:&�9�]O݂��P�}��\��;~g����T�#�M7Uڳ_@g#9X�������P�h���t���υgU���u�{�hݮ����^'�Od*���m���Њ7v8>��e<�.�n�@�*���=<�04S���=����}r`���K<�N$d�&i���s�ֆ���u15�f�i�9c{�w��Ũմ�������d�G8�=�\潤�Jkql/I�*�c:��[c�ƛ�;I�:�`���%�<ם{	��t�TM�a�)]w+����;b}$��l]��h���W�K��,u�����ѯ� e~�%c1��7�w!�3Nbz�hą$<*��1��a��A��0��[@�c8I��5G.v}�+�@2�-a�~�q������u����G�Ғ���kH��Z���z�60( ���j�{߽��ǆ�xO<��<ߏn�B4���N)����3uf�+`׵b��f׼�d���7_�g������o����#��+�b�H������_3�V���NO�x�%�X��[�o`�ֶ:��8����.3SL���� �4fU0<�2�d�2�Ѧ6�a���nyEm��<�(�S�o� /#O2���b��Z�G�h{a�U�^�{r%z�ELV�=�xI��1����jU�S�_Jz\J�mgB�E~t ��2ZXPjk�s@A�� �1�_�	qg�{��k����`ҭa���kg�8v���9�Mk2�o�_j�&��@���b��b����D9<������E���Y��sn4F3K��(%g�\���G���Bړh����QY)���ps�>�܀�Z9mn�j�A�f����h��wuR�`)C��'�h�>����U����n�㝈��=p���Ic�m�;@�WNȑ�6����pg\�ӛ�଱R�z!�&��$�����[�Ť���K=? �Gy9�?�I-��s��E�O�ؐ��i���x�ok�(��'�r8�mhO�L;��^�o2��p��7LlC)�1쫳�V�Oj'����X�I?�&5ͩbc�cI�]vIK�98�F�f>V�����(̈́��:�'(XG1:���T��C�ߚ;�	'*Ľ���M�q��� �J�U�{�mez4g�|�)ZfB78,���aI��#Wt*'%Ϗ+Y+Ge�˟�'k�*C��c�����ڳ+�K�Xn�ѷP��Q,��s�W��'��Arw*A�R&��<W��R&�9�a��I�ɾC	�![��34o�X0T�u����ev2&'���)��LS]��&�����i:��&�I�R�����YA�Y�H����mRhH�l=U-��UCe��"Ҍ|ǚ#��h�����/�T�P-����F0x�����*SǰH.��ԃ`Rj��`�kn��D�]������Rf{�$0F<T̠Mĳv�L�"�0!J�D�;�ƾl�::�X�	l�7⌲`��ĭ����G��8ڰ���dPʜ궖����]���:�e*��<Z�e�3�X�W�}-z��<����^uX)ı=�k��#�W0s���T�!C?��?�5�����ݿ���b���ϙP7�"�SV����S�P��u����^�a���.L�A���q����_1��P�ץ�m'$y~YXp��p�$����Aс�C2�	G��]��xR�{52t�u�k��Y����.=�{���hj�OK�T�l�z2��HFwjeLqU�h�L�1τ��(�GgC�Us��Za��x��mՅF8��il�g
��oӛ B��)t�|(!0�ְ�1+�L��d6V���Y��6q���8�_�1��v�v�%>2[��-ʫ}���uK���K2F�=�{��+���-��:�J��b?= ��bԎ���IW-{���5�T��Y�T�!tj��b  `����n ����)�>��g�    YZ