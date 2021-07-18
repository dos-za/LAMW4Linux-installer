#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1623668604"
MD5="d8c90eac2cfc5c92649eb377e6b09b86"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22720"
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
	echo Date of packaging: Sun Jul 18 02:16:08 -03 2021
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
�7zXZ  �ִF !   �X���X~] �}��1Dd]����P�t�FЯRQم��`�;� Q�qo�Z{�6q�Bg%\����I�S����"$1;��6ϣ6bw�m'�l��c����[��K�s��嬀#*q�V>�����@��,�z�mjm2F@1�Ra"�3���q�����P�(~����J&?5�����*�;:8X�%7r�"��홎��j��H�z�W睏i��J�2d"�>��arJKa����RM��2����$e�J��&R����`tT'H"���ak���R�⺢�q��=)Ki%0X�?�H�o����� ��2Ă���5]Մ��I�[���>����s��Qn�;���-��>�����gg�d��
�^����w^�|d�1}c�o\Qi��V��W�x�_��(��8�E�SsVD�czCw�����L6�@�L�?�'B*��DAGL���Dy(Ra�q�-�D��s\�j_:��6�J���'֪*�v��/'�4GmZ3O��#L�	8���3�f������IϹ�L�ә#�X��S��cn��q�R� j� Гܙ��<���Bu�"Ү��ਉ���<�#?~��Iյ*c�R码��8.c��rz?\�4�5��bUu��ϒ� ^*��2�'�8{g����>����򍩎^ad�1�Q%�^��iA��U���m0��xYVF͈��A�3�w�qȱ�)�ӕކ�p�U[��a�  �Ψ�̒!Va!�)���� ^~�7�	��8N��O��,wu�HSB�����RW�Bk��X��G�bnɱ��s׽�����	H{8|�1���@�[9V��=�`��J�B����G�^-�Z����1;���%��U��pfv�aZ�'.�QI0M��UG=�R~ݯ��Qf�����?��|�!�ɂ��
t����[B
�$Fz���G�R�fӇ��v��B�y�-�)���s����5���kY%I�.=f���Nc���T�����dx��ԦqH�-&������{�p�V�H�A�5�6Xi��}�����Z{�s�}����i��_nL�z���ªG>��H;l��\I�>��L�A�3Mm��˥�)V]E����w�B�#)�%��	Å�\m)�2N�J�3sD��|Kw�~d_��� Q�g�����UIx^o���H����@�?F��Q��|+3������&�C���t����:�/bPp��C'�[o<f����Mx�z�n���Q/ԣ�0U��O+P	I�:P�W��B�j��;g� (��Xy�/�y���s{��ƪ�2c���Sk��Eu@�����o���O~�5�����53�@OK ]�6���W�z3�^�b����"���┴�d4e2���]�����+��Pu�<��C���`�1���qV=�~�1�؄v��7�<9d�V$U�O;���YEl��E�5��G�)l�2;=f^&u�	P_o?�K��?͕�%.\'r�Z�D0���y^����A�ءjU�W;�>Zf`�re�oC^�|�Qs���JxA�q1^��ߣ_��M! z��%�1�߀�1��a[!���1����<�ʙ �)˥2r�P�aY���?�Ee���z�!�\k2$S@V����hZ��+K�Ǥ2��n;)3�``�T��Z)��;7�h���{!���p��=��»��`�'쵓��1\�d��z�ݸ��#��M.qzl���o�;��0:��q��<�hZ(8�a�n�KrM���K1ֽ0u:ܹ��ҟFG��6��7�q��_76,��#F*ķ��@�]��b��/���hJ�=�@�XA]�,fyicІ!>v{(.s�b��Q=�e���zn��|�bZ�`|��E���cI�H�SAD�ߜ���j&�`�?��*p�����}��f��2Ow�4�d��C]�
�3���g5�8������	"X�(�s�Yb��fښv�]�%٘��w����7'�,��<����t��\��/��<�xx�����Px��K@�u�K��hWϥ>��\��|-�s����2���#&��Mٲ^�"��k�O=�t7�)T8�D�Y��N�G
����N��'�2:�d{�/|��Zo��㈍��_��4�W����>��PĊ�Fe��ݬ�#�u ���K���x��dL mb۴�T�(h�fH8|h���y\�i�M�� N�'�!���Ք�L��&�k{Np�#��<�N�N����g�8h�����	�ܥ&�]��+�ʱT�� ���'�R��T��@HD���	�޺D����;WRl�i�g�K�V^&�w8�_݆-�Hb��Ǔ���q�;�+5���cW���4Y��~;T�/�Zk�#Ny&e4�`���`�������}XQcitl���w��`�#>/rI�`�3����Σ��{��0��f?�U:��H�g�����ڤ�"�v�1�`g]"3b�5%{�RҰ��&�(�Z��C.m��?P7w*Zt\~k_ʃR�?#_��Ro�(p�P2�x! �a�-q��n���E�����5��h�U`u4|�5;=��pmz�N��r�w��
�N�ϪW?S!�p�F_�ab��x>'@�c`Gb���r$�Tj��
k��K|�M
[����ө*W����߉jx�D8v��o���u`�Y�&e"YGq�����̠���0��Cg$���	lI�'��~�8-~/8�#�x"Si�MXK�C.{����O���	D��R R�5���!�s�zї�*�Q�i^̀`��Dʳ���J�.*P��\c�6�7r��'��%���w��w�n�幁��
��,�EyC8���j��Ό�=��Q2:�	���f)�fy K;W�|��\�;�0q��[�.*�j�YJ�wC���VkkCo�ɕg��wA9�5�>a�.�c���@��ցu��Pq����N��h+��T2"#%�ځ +��5���i�5\���j�l�Ƀ���W���I;?^���͡��ZED�Í+?��,P�|W��5�*3�Y�����R��*�P0G6�Q�|*�B��C���B�sco*<Q�-
|�Jl�Pb4�M�̛
YE"�
��E�~t�~��Ƞ�ܢ����a���jsk�Li���$��u@�E'S��q.io���M�}Fحʥ�����,����gܛ~�J�ͥP��q�@�z��W7��_������N���I}�E섾� ��̈qO'�Ʀ��*� �Cw�ܕ�0)�>���b�.�y�5�b�()z�z:�� �<����%Wj�\��
ѫ0��L��p��1�X���![�b��jzנL�WO.�)R5U�&��?�q��cu�~�$�e�SM݂J2����	�9�P4yVj�:��j�t-�,R�����ys��t��SӇ�N�IT�QFY�>�� WO�( ��)�9�7���h�c�1ݹ��4���˶
WC A�U�T"�$�[����i��|����.�W��=�3����G_tk�W�a��ۭm�4�� ��[-?�&��U��g�H�a&$\�h�U�|�|1���)������&t��B\$%�Z)�K�E�U-��@&���m�x^��%��fo�Q�鄢�8��$��<�;�tQ0K;��������29lf����4?'��I��$��0�a�!(�;�]I��u]���0�x�j�ظ�ᱧ�@�:l>_W��X�H�؈��E˖�r�Q��9��eį^En�)M?����˞��P�o>�"[4�l��Ak��c���ۨ�����1�E��|�>YgQ$��%S�XSl��ӝg�s�/-</rR�6kzt�ߢn��,iݬ8a�ֿ�[^N)�"�^���95Z���v��kO���o3f���늿���@	gu@��8}�9<*T���'�
_ |�.n<��d�C�����:�b�<���a]�j�Ӛrx u���M"��ݞ�'�ǰ�R)>͙�� �	�TaV��ҿ��-ЀNES	��7�=N�L߁Q�y���,�ٸ�o���rh�(��r*�3�V)�ܭ|��4��/��d�C]e��� ו���e@,!/���ϳD� �Vꆵ�Y��T}���Z��H�~��� s_yVK&�U4Ӣ�w����Ց-��WҔ��MÉ����VWۏ�'�G�Y�u��}��?ϙ��h?f�m>��
���'�nc�\X]Q�i��L��v��oY�d��ۉ�W��v.�����[������:Tncڀ�#o�Uz����"2�[��cG`��2��0�����t�����_���|W�Lb �_��'�Z3i���~"Gʍ���������j;jd��JxH�z��=n�̪/K���Y��?t>_{��Z�o����pF�(�	9��􄙯����b�k�hr�7ތ�R�n�lM�Q|J�s�e�_��)<l�V<��&�^�+J+����}7��X��3�O��?D����N<�o�:��a��z�gmRR��yB���E�F��r�Ҧ��*p���V�2Nk-5}�\��V���1�-�
��8��z�0>�?B��&��$S�Ǥ�H���xМ��P��s�� �CC2�"��CRXD4�œu�-x��O�lg��Z�S�᝔�����攘�I]&�e�h��Wʓ�T�~۶M�ٙŢ&Td�.�"���9�I���/���&+O8�o�"{�%��!XM���Q�~�sf�p��I���q�i��"�������d39� �߱:LHћ�)�gf�nlkUup�wӏ���h%>Y�'�+\)�^b�$n��3�-
�Z6A�1�/���2�批v�d�o���D��W3:��T���\*�F
�q;e��X߹��?s�(q���#�a��W
�������,���-�~Oi�0��g��Rˌ!S@����^�;c�:�3E���v�����+ɻ:u�۵�=�j��R�)$��d�T�����ZИ��"�k�_K%|O\'wB\�n�2�Dr�=%���&����d�`�Jp)��{�-��R`�����W�T�*ҏM	,���Ark(�+c{��-u��a���ؿ�2*1�~��:��M�d3���3	0�װ]�l��E��m���?q���yͫ�(fε�V\^�?�qw�l��&ɇ��T�{�ǲmA̥��Z,Yf�m~Q���RDXA�H���,��D48�ǀ�Jy�l�������<�/��nCy �@�b�'D��u�f'���b���9��i���b�) W�~����r����}5���J�,o�ӌw�����FMJ/�� >c��!+��,?��1�1�ę4I6�-}"�Bm-]��9����˓����aw7J}7�re�J�Mqj��|G�əZ��7�7��#�r";wn5S��q	�t#�/�:d��_���Ft X�᧼�
+�er�3Y���I\�mOm��c"�~����Q�G@�U?i/L��S��1?F�tz��\_W�\dm5��#q��ԧ.Ѷ�2���C����u����_rv��hD�Os[%���R�+?�t����'�{N�M�ք�`���,=�#6g��p��Ef�<~lc�Bt����oR<�f��ti?��C.dM�%��%�����v��ݰ-�W�;�I��+X����d��r.@k,�O55zi���J!1�ʯ���k��ik�}�����n,���<���T>�	g�o�Ya�n]��y��ZϦ���BE_�>r�� ��(�-��y}y� }��*h��c6�	�+щ}M�=�����5D�ez����j���^�&dx���@]lQ�F��u��Џ��ʆFA8Hkd�os�^3��t�遖�W
�訧�[I�*,�%��7�xk��k5R��jt����)G�%���
���5���~o_V�������|!ץ�h��6[#Y�g��G�?9{���XGӱX�q��J�	��+�3C;�z�b�pR&nyQd�MiS�'Zz�v���Y���5����������(Ď?u��<6�m���7�&%�x��!?Gߴ�(Y�$"A��4�߶�|x�^����AZM�I�>�:�(�۲�ov=1g	�}������U(��8���^"�����{�����e��[s�,�ѕ|��p��siz������f5�d�eNf���Q��7�U����z� �м�Ut4��J�r�6"V~�^ՕDi�
3���e?�j��}���ǻ.��Y�u�E�Y�%��� ���q۶k::P���0�k9�W'P�a�"�;h_��1�թ��Fb�Py�N�"Y\y.A��!ƋZ�O���j�w�R$��_]P��c�6�oX���G�0o	��6G�mL�5��p��g��
ޏ3�9?�Z���f�vg$��5�iLٶ�.O30�$9�
��E�a���E��=�<Ī��A��3�.PIp��m�� �~�"T&+��(���$��&#�S�L�x�<��{�K��([G�Z��'��F��2�^Ը�����_W�q{�6�p�e;�݂�g)��,f�C ������t-�&�<Q��%}�����o���m�@ @-��[c$'�mQ���/8�5�EҠ1��]�]Vdk/��X���oT���ڤ����8��@�*�C�Y�`���th�.�/��!�i�������*_i z1;�i���*5n�v�4���2�	M�������l��B?P?��N��W��Y�j��0�g�C���6E,�Y���FZ�u�l�,\h���dJ���S6��|�uⴈ���ۖP��@7�~O�����]p�����>7K��9�,D%Դ��@��C�~+�^��K����s�-�O*��\��j	�n�`>H�Jg����lo�=�\�~�B��F=4i�Xw�v2�58z }�A�TGf����=CiiQ���B�J"�=o�%���pcd[�jT��g���'[LX�!��ez��EF�{w�Su=�(՝�h�/�z��g�մ���t�rsX�&��@P�&LG�l�+7ێ��|���9)�`8i�x:�k���@��V4��pq˲�pw4_݆��fh�!��l2d��nlxz�1R�)"Nq���R�,�� ���x+
B �Y��p�f�u^N���B��4r����]X�y>�B��]�a�%Z^w�=���x)�WUm���~���0�u�a(S�<�1زza�/���7X��ݮA-�t��҇X �zsM��?����zޫ�ǯ�o-,t��1h�����>rf5;勑�x{;N����5k1�a��n�Qim��H (�K�s��Gjc�IIci:�{���k.���9�=V�.qAa���҉�hTUq�1���=.���.�h����P�Ü�Eb�zv����(��^#���}(x0�Eݿ:h0�+T��-�8Z[��� ߆{c�f��P�2� ೓@�������+�s�+*���`�Hi.v&�m��@$��ח��k�F����m�h>'?BsL��3�w���h���ڶ�Q*ٹ9L�ɳY����Wa�P(l��TCp?YE��i�ŷ�lB-��%\Ë�����ƶ2�3���J��HP�*/Ӹ�D�/"O b'N��A�(8�f����S�ɐ��.�@.�Z�
Z%W�y_�}��C �^P��܊�,!�_1�YA���d�Y�bU �a_EZ-s㇕5��$��8�Vh4��)ӂz9m(�s2��H�0�W��Ò5�xp�� h��@�;=O���mNe[HU�� ľ�~3�{��	@Y�_�o[T���C1�E�I(�w��ԏ��{�	�f�8s�!l��dUJǺ���@�j��g�nD�Lh��ښCb�ڔ5;��ER��xEa:�N<�}�=���yt��nqho��ЁJ�9v�)�(1�q������1L�+pf&l��U�Ȅr|!�&u�T����SMB�Eqv��d��v5b?(�v�]���je�
�^�G�TC���|����!G]�)��w�H��n�.{돕Ipl~c����Ó��j�K�gp
�l��˅w�Nd ,t,7mU��\;��m�f�� L��f�5�bm��(�=���6�[ǼX��'-J*�W����S��E2��Z�	�
è�Q��?A!��b�PJ�#�ҏ�G�Lu��8�d[�MhZ���f��;�&�]��s�)�0ȂՔ4�"���:ђ��w/4��i �M�#|�y����^/�dH�$[��߄E�V��c{�މ97ש����r��H'�"ܕ.^:<^�/ࡲ���c&L�`�%h��WE��W XѢ�I��2B!�b�u>i�c{�KU����h^#�k"`yX�X#�Є}�/S�	�6ne��S	^�n�e�ѡ� �]���^���=!8���c�J.�<JvKS�/J��n5���~�t�4�ڌ�T� S����E������B�������*�_�m�L�bw��<�!��ͭ�ԛ$̹����P�bC5�:��t�mP�jZG}@��]�-�����_N�9��U&]�)	���r��U�Zص�	��ׅ���:꼣9[����:�W�D@]$�0�VJ��h��m�G�eTn��L�;�B�k��<���0$��(n���0䇇�"�"�I�T�L�D4������5��Ui�0��y���!�諸�t���3����EJ�:�RY(�Ĵ��#%�^J��8��DWXØͮ1��D�熝D�m�}�-˗Ä+�QzُX�N�dÕ����W��O����C^L����+�/Z�x5@QsuHH9D�LaVu�|7KPKc�<{V�Yq�:��F
��?9g�W�@� �0��ؑ/w�2-om�2d�Ճ<|{t��u9���|�}э��{��O.VI��1z����lR�y?B��dw+;��T�G/A���bV7�y��5�V�Kb��aCy���ۘ�A�?�N���bA��-���bb|��-��fȣA�ra�0a��Po�y&�.GS�P#�S2���`�t�m��}d��{ߥ��_Q���<��T��%|5�����q�0bSx%zw�����:��٧[.I羴�҄���p)c����ݰ	�5d�|��u&r0ވ�6u�x�U���kQ�a��_4�ou�Eo�H�&��eb�����EH�ʲ���t��]��q����W��  *9�\
z��*x��E`���X(�I�Ԝ��FB`������i�4ĜMB����ogbZ�����$66S�0�(m���$y�� u���^�<U����������v7+6�;��B����x幦+�NR�Ai� �P�8=����QYFA�H1sH�MM�1���y�e�8L�2j���D�Fg��4M��c�{���稵=O���iI��BY�6D��Wh'��}A�����!�B�K�I݀�'��k�dM���R�<��}�����!����|K��s���8Lr/�X�M�7M���6�>`�W���b�����q�IQ�
��o���}Tr����J@��i��8*��Y�]�t�|����`Q�}�gb}��o��9/0+0���X��MP7�RZ�n8�iz�v�����/ұ��!�J��V�+#'b&	�F�`���������K�b4�Z�Ԝ���Қ8�n#�����R<�}��WP�뇧s�F⬣;GN&�WM6���ϼ��Hf��
�SӘ� i���%�!�<�!��=�Ԇbǡ0�U�@I�!0������!?����(U� ����;H6��J�
U��b؛���U�p/a�;K��$Xb�����L�V5TX���`?����G]��I݇��W1I���*�[I���Q��d�{-vC���OƗ��LI���Ű06�P���.1r.�5(��@Ih��)(���a3�y�$��]����{�6 ��%�m+l��h2��ڗ�`�c��79�MU�Si�ԯ�6�yV�A"����%���^r�s�Y��*��v���Ku%��փ�%�|�l��h���GQV\GR^� �����q��S+^�VS� ���!�q���Kן��pI�!��ABg�T�*6�P(����Gfk�d�&��p������:�9����Df�x}d�i�u=�`��j�{d�x��r|�y&?Z�q��ø:��9
9�[��0k#�G��C�fpi�)��3�$�I��!q-�c��}$�i���Jf���l�R��M���z��ױ�P_��d�v��+��u|��gaC?|i((��-_�M0�21G�����G���sD����O��A{XZ��:���aRf<��2���/3��Gx�2�����QS�o�ől�cU	��hZp��y'��=�S�_[�+j�/�0ޮy��I�������s"�]���Bf��K�8�ߜ|̽�	�n�����nUj#�Lu%��Ǿ�g9YZqޜy"�GB0D�!�����]-��,��y�9!�C~tV����+i�^MuMl	egA����>
u��U�\f�=)�
TGy�����_�W��+��
~��� �\�R}��t��&�j��a0@�����nZ��7H!�D�?!+�,�P�,��&�+Q>R�(�<NN:��^�>���%Z���dv�j�ŝc�������`�h@Ĩ'��h^�yQ˵��w���v�`��Q6���d<��Mf5�\�����qC�;>z@�Y����z��� ���>��9w�(tl����<ٮ�2)&��	9i���O����y3�q��6��{:@�� Ȅi���C��$��wJ���W�W3 �Q���C5��	xr�\+�+A�Zf�T���������V�D����M�1US�A�
(��垗5G���ɾ�G�������z{��0K?��+oW� ��3"�_{����s=�'�����S��ɥWp����������e��"bgdټ�u�H�EE�W�g��}B�.�|mӈ�H`�a���&a�*���7�ajӝW��7u.߷�;SDKf� �Ш�fG1�R���F�05�ZP�,��'��U?V�K�{��eф��靶�]��Œ_4�6�}��]���ŧ p�Y�
ƙ⎆���Ԫ#Jb��n({��`�� &xq��f�Ͼ���3G�����]I���%�|Ԑ���QZѤ��v��CQ�&��4G̖��
`�m�)�}���CMG uU�C��\�*�݈�$��0��9%�e����ou���4�qE>7ȃ�������Ъ��D��}��z Ǜͤ����i,m���{K�s���k:��:۾1�3s'�g���֖`%��RfZ�S�(�Jo�LS|eg��E��/H�|;hJl�/Աe���i[��~��!S�Nj��YvHц��"s*��n����wb�DݵZ	o�V���.��}�'.�J�޲�X���X�ɭVߣ]Y#	{�\d,���i&@X����<]�5�V𳡑��b"�"�������P�
�qs�#��e8R*���y �_{�CqI��.0n���o����=So���#)2:y�Ҽ/@^��{x?�ő鱈�G�v����,�*�,k��;�P�o��	�I�sk||/�ک��Gc��[(�8y��ۦ��#���Un g|�,ԫ�}`\fAK�b�E���E��j�p����}��r��L@	L��b�x����VI�}�W��t[}��Z��E�e�'Bi+X�*�Sl����gwTMɕH=���+��W
G4v�qQ�ؕ2��ז�.$LoR�:I���6�?����oIЪ+���|�]O4X>)n�Aw�Hw�l�P����<ih��mM��_�*}��\v��	C�S��������9�]@L��H
,:�Kd���ě?��4�{��	Z�� �u�{���9�_]g���d"S�k�ш��=�5su��a���ۻ^�ӊ3�v&���fC�"��"�G\��y,mC(��7�� T��e�[����?��'��4} Y�&W�y�6��tP�������s ���ZX�;Ú�;�H��ZC{dR��()$u�p��J/��}�*ĖK���5N�[F�S%�m"����^O^�q:��#s��V"�Y�S��5ڂ��?wtG� +�K)o��>��]��vu	�� <Gu�X�P`A��w�̞ͻ0�2P��|$��Yݾ	|
J���[��l'LSN������l�n79��W�5�~k���P�̉����@��������a��%]q�F3�E�e9����g;� ^�n��X��-�ȅ��uDjٱ�X��7�Y���� b%�D�٭�c���vK�����LO>��c:vI�߭�כlA1#�W�#�=�����>��zN}��� �m����*Ďڇ�a��+�wѦk�����Tf�	�4�v}�Z+��i�k3���m����dF�@�����"�6�.a��TZ:��]�87�]��6��h�%��j�[ܫ�1#"��_�Ukԭ}~J�q��	�j��V��7Y�Goq�b,��=�����<����t�6��q��A�F�㟷��������RF6Hh�8��K[��%p6�?�4�B" t(�d�uq�fc�T7�1u��jCS��_�����^�������8��˭BdF��4^<ɗ|�}��6��%�׽��;*T���I/�]�zckw	7�i/xٛD��Kk����Aeݚ< ��IC� wGJ��Ϻ�޴|k������A��X���t�d�h�*�8\�C?d��2�������֨�ϻ\����i9[$�A�lJ�`E���ML������L������ϱ���<�ƈ�q�URT��,xh�q$��P7iZk����2��v�G�����ڿt>|	nT���$Vn"��42��(EnJ�����.�o�I�6yd��eH5�sk�y}\�˴�PA`	2��=x�ۼE1�V<��8��M6��P:f
Q7�aj�'���ٜ@~"{a�����:4�LS�p���	��Y�0>�m���_G8�:�pqw~���� E���K,�N���'�i��-/r�ǔ���ܖ���{������n�_�W
f�IQ������U���	��xl�8,n]��r���vj�c��wyR�͕�`?`T�'��8�?u<���� �(�a=LF:o��!��i�U*F>�:�!�tvW�b�P���걩���ǡWg_s)j�>Qtx��$��̘x�K�}�+��;��G�w�T��rʎ�H"dj)��oV�|������YZrQNh�#��U�w:��#$���n��m���!���n�w��Z�����Y����ܕ5�
�V�-^�����8H�"�r�����l<������8����SD��ƚ  e���L�^h � �S���>OpX�-�=,*�U91b�U��r�_gŦQ�mT�2m���E)}�O`\"X�~`O �s	�Ȱ�*�g��2e�� f{N�A;-{���p���s�ֈ�@(P�xG�b��Z��=�:���M�����Xd<�C��s���̈́����l����I��]�$VdxN�'0���XQ7X�J-.�Cb`�l���+Z6�2�,u=�:U��U�������j�+�G�G ɤo��"���޸�Oq�y@g;j֟�����ej�����k��u�B�5qi	�Kԟ1d7�et��#`�"i)_ȗf��+|R����}�f�w���5*,c �8�R0��Ԍ��$ĸ>�A�7��t¬����u/�==�lu�|"�r�w����O$�����c�H .��1YN�q��W�ft�zb%��wy�>��i?Q�k�W 6�/a6a��C	R��*Ja��4�֎E-��,�H/V��ޡ��$`ᦱ�0���
d�	�_y�?�
7 C�(���p9������sh�:�q�;򻊍H��}i3J�v�}&�/�B��,��erce<Ť}�f
�ff�9��L��}�{
>�f�U��e,���[HEI#���x7W�������Ƥ,�{i��Hmt�1
�bdTF���}�Us�ק�.pH���}�[(%"$�褱�<K?&.�+���I^�[�vt�̵SHnڔ+�,-��bNJ���g���=���6�bF2��y�P�w:<���8�KơQ���]#�p�/��IQإ��//��N�dw�Oh��q�,I2�0BD�y��T�I&
8��GA�����oIGoi�f��q�^o: �/��T+��������VN*QY���cڹv����k�8V5ќׇ�y�c������Dl�]zށi�g#����D�7���p�{hPY��4�����@���xV�;y�E�Dm9H�� �b~ʵ!v7���B�����땡�UD������q��_�ɬ�3�=�)U�'D2(I�p��vO�HS�V�,P������ �/�_��\؍�z�z�{�qF�2�8�Q�pd�e�)@p�9�M��a����i�0�;��b��:g�GE(1��4�QP�r�G9a��{`y׿6���O�2����1����a���p��}��KyXi�lք��c`V���+!5,�������(H�fA�Y�8Y1r5�j����j�R�$�J�-U��<�C�)rQ�<K�'��/���^��$Ҩv>�v�b�2My��m�ОC~�X��j9Yԩ�F���%���w�z��� �E�I��� �~k�:Uf|nx�����#ӱ����Ɗs7��Z�����LV)�0lzN���:�8t��ZeNT�E/j��������,U��sב�9Vΰ6�J��[)cOK�.u?�"z���b~%��#��s!�Vթ �B�����}S���!f>�~��o�a^���;�N{�>��))W`z���[��-��`u�^ܒ���'�/xki�AQ&D��+�C����Ě�d/9��=�W1-&��� ��^� -z�_�-v9�~��ĤA����^������"�\&�l��?���]��i�l��&4��ܕ����l��eW��s�����1ש�)���mֵ����9)�W���^��kW|�m�y����DNd^��KP��
��k��cˁ�:���D�@2-�eߦVw���lg��8tuRX�u{�T�_}�+F��L��eU�v/j�փp�>�ׅ2��!��%3���0]��\����mK**JT�:G���*��E��2���0T
G�/P8�Z�����u4E7�i�\E	?�u��t�4�;63l�٦��W�8ȦK��Ó�C8V�)6�kR�P.�ӱ���g�0Q� 7&Mp����c���[|��Ck�&o\�g�寠�7���%#��ۺ��cxs�9-"����C��hcn;z��=�x���Ma��\��gB>�B��;���f���_�>� 1,��r��ON��.")�m9,�Ya�{���K�;|}A���VW����1n�G��y\;����lxi�°�r��{	� �9'���4���YD�s8�]���L�B9+LRut��(.���ltM%�n�L21����Er��9�����6�f�W�s��˩���^X��1?���,x@�>�I<��>	6�����X���/��>��?�>XR��@�^�4Ɩ�&BϜ9$S�;/���
�7���'���Y�"���S,���9�-O,WD���;�Lٸ�	�$k2�������N!nF�����oj}�QkO�Ӄ�1eŬH��XN8�}%���hDY"6��ƲU-�@�j-R���I)H9 F��V�
�	��h��5�K�	?��ȭ1b���b���k�ߥ�U?'�`�V��:bG��jV�����r�^�|&m��+c�����R�F����[��\���ok|���g��߿Όu��^{�(LiNXd��B%�݀i2�����.ҏ��SQ9e��%I�����9_��ZC'�3ʹ�}�Q�K��ր؊~�Ͼ��AZ�Ɔm������@Rժ�����˴�_����=I��6|��ǫ�c�75�>���8��o�	Ռ�Ġe�=��,�*��[߳�\��2������"�qȘ�̸�u,Ϛp����A��jY������?��G���-��i�G$��[am�{���IQH;1R��P�ԍm�:��z�I����g�d���c/!�� �1axTkF�@�l(�x_\��j:�KH�@x����cV��}!WT]ٶ���7�X:�e�T�pPӿ+Z�	���J�%�$l*�t�v��ؾ���@�
�ؕ��w�P�r�L�0D��!��|G�k�;�����"���F��TLH����O�a���YsY���:��f:wt~� |�� �בu���i.����F�c*���@n�A8)�L�R�ap�̼��$ǎ�H�	6d�-'�J����ς��nY��.Q��}�N;h�T�I	�ȵ&����O#�Y��I�+��� NA�O��ke����hN �=y�0�+�T	�}}���Qo�x�mI�F}@�� �%�Q	��s_�_��A�B�C��D�4h3`*�'^Գ-Zi1>�\q��H�R���E�寋���Y���2����B֤� $5��~GZ��`���cd&V�f!B#��3���g1'����n�<�=y/��Nt#�3ɕ�h�x����:�r����N����9�Eq��a�Rh�-gC�X���Y;{�Z+a�:���(Z� Ͷ,\�u@R���Esq"P<l7[S&�7S��ay��=3��yQ�$����r�ٰ;=ͺV���#�׎�'#��(�ŀ�x�w��u(gM�Lò9@�eӜ�ˁǗ6����3A�,:�9� �f�7&_��+���������Z���[Y/�o*@	�mNڀ��6�9'Ct����~H�[�e7�j���O�*��!�M7>�}��fZoW",l��ɷ��f"Tt<�,�����	�T�qOK�uO�VW��n<N��"5Z�V�|���ƌ�P�AT�,x,߬���ȝ%�7qj�*>��siPI��ֳÞ��|vC���:�
n���F����ي�pp�ִa%��m��?��i�{q�
NO.{��N/�f�~���7ΠiP�V˾Eº�8�����XE-9[P�f��Y�	K.�}�L��=V�$�[�'��Lx�ja�T��3��Z8�T;�_�o�0-k�����殮a��N���L�.�m��Z��uk<� �(0̂L`�������E�ɛD�'c!�Q����N�y�Xϼ@���	���m�Ruߐ�YR�����zn
GcD�2�e��@#�zR>��%��tң���N��:,���w����;�͗�&�A�gM���	�Ȕ�.��-_6�M55-��	�L\
�"�e�1�
T3�L؂_���)͋����["�_-e�s��'BL�?m������:�"��c�x�y�(q=�0lPo���;!�3����l��K���V��c����er2˴�2�LVs��\�{D	��$s�z���DFiԠ��C0̈Z��0-u�6rze�8��yG��vJ�Z��@v�<7{ŵ���X���)��'lQ�`��R�K=��0ם݇&p䜴=�&������5`�6�]��٬ܺ?������"d=��+�"R~$�m��:+�D��q��YB@کS��ګH�:�J��#am�3P;bU$Cw
�}"ذ5L&�O�\x�?� ��	z�e�c�/�IՖ�[³��N�N���2�����,�;�/q��&�����կ?�&�G.��Y�Z�!G!�.�
������qJ��,Mp��Gt~W|�{w�>N�+2�Vb�7��5A���u1�`�}��( ��yB��"�5�^^���鿑@Z������V�%-o��Ǖ�^���G[��0ͩ��!���W#Xz[��5�r'�N7?�`,��_�$$T�A"��(~���J-��p#����`y�"�p�">[�w�VJ���9E#��� �S)�/��B�KK�?~)�C~��z��O���5NMR�V�}s�j�ߍ8�F�ߵC�/L"+��5 ��+\�2�a�4e7`]�T�ϵ��J�oc��P9P����0+Q��SBdy�d�J%G�K ��aX���f��OE��=��η��&�� �z���]+��P�̠���g��e)��������]�	u3�͏t	^�c�(��7�|l������b���5��K���o�������4jR�G�란$��$�!^a��Wj�8'31P��lŹ0h�`�[	W��2�8�����-��AZ��9�`��l�m��#h�bFR�Nz���QKz��a�>���1�*VZ+l����f[��>��Q��>2���M�@%W�zv7ehn0������o��̔qX,K��ࡎ�&z|Îf��6�8Q�Ĝ�fub\��E]lL
�m<nn���� �e�S]K�kg����]_׳�_�5�<OD!*�޷���tz-�a5�|�  ������RǍ�3m���^3P՝���Hl���-�f)ي�)qR��"Юok�l����G���d_K���d^�b���W��n��?	;�Ӥ7��>%���,7�C�twt`�' �0�P�M�'��L��-7��>�b����8��4C���7��h�ݍs�|��E��qs�i�	��ʑe��65P�uBh��/���ȸ�-֝�˷�m�)�M���&R������TV�@$m&�<�y}���f{����a��a�O��$�H:��� �'�<m��v�7�D�n fUU����$X�,H�7�M�M���B��y���+u�b*k&�نU��á��3I�7t<]���V/}�-�M���Y�����6�+$tM�\y�YL	��{g����Y��LR��a�
��B�G�x��~�y�gY�{�&�Z��Q.��=I3��A��
�0�9�^���S�,�A��Kq]���~Ѹ�"���� @)��;SS�"z7��`�]1��2����x|r�ev������ {�+�죥5��͞OwT~�m_��%�Ϭ���� ����i��b�5�_��e[y�](��o�w��P,d#7PQ���1'�o��Yu��ݒ���a8\A:g�sik&���*�Y0�%���}�C���Lm���� ��b3���Q�����-�z~*c8������T1�.T�?Z���(�";p��	�3D]u\�Y�l�ą���_6y���$�6"Ň��伉��4�L����ہ�T���	���=�ܼ�|jGӎ��i@֚*�G�{����3(1c�V������@š�ի�m>?��=�i˫�:9'���2M$huoA���v�&#�͊��h�r޼G�
|��8Sd��+	�,�&�k�3Je��}��t����jU�`�l]W78��W�Cw�#C3=y��@,j��G��5���E�qM�jX�����!���>E�c�㒊'��VQ��>ܔ3��5�r�Fn@8�
D��Y������v(WС9��H����G�w@E�X����"�<^`\�֗���7�:�}�|��&��Ѓ̥�EL�@Or�dr�<�4�F�CD�:F/L��"�3V�RST�E����qOD7����yf����+�F�E�~�����N%�K�4om�#~Ξ?Ȅ:�J�+C;�q$B��4	�� 1�!�(e�B��~!~p���!Y<�P��B�x��"�Ǵ�0S��`U�;r3�$�]^+�4WO����vL/ɽ�_�1#Ap���my�3����}����5җ��J��g:.��]�����E�-"��"�}j����c����~�C��%�A/[�R���yѶ*�!)�
�c9�zfh$���=��Tٕ&�F2/Qm�s� �ě8���m�^}��V0�=����d�=����r�v@�s7��,�(�Z`�
��Մy��x�wc�f���j�pJmϖ����]�#�h�
��Lp[������;ڑ?��?{��֫7�j�b�Z4�͞ ���W�_��m�ʣ�`S˒�%�9ԗ�f#ϼ.:�v�B��1�GS[?��+��"�l4B͗��������Z�I���yZ7h�ť3�0�6\��5��e�R�d��Y�;��X�F_7�
�L�.,'���k4Q�aCf�KErF
�B�;6���DP�,�~F����,b��G���E\}ѕ���}!�_RO��.�XI���N��!�"å����`3%8p�=t�� �F>=�x��W���~�W���yeDg����� ��./5����6J'�K�����q+�����/$�#s�^~��J�,�����o�B�-i�#��4cݘ*JRw�3kє����䢒�+��]F��L�[Yk6�F}@�;��^�O�;��Vo����Gc~�'N��!2a��B�&��["�xuz@��! i��{�=[h*)�Z3O�~�D�����P�*m��Hf]��D�m�a��R�T��9��2�egAL�o#��$�B}���I��$<�}Y�y�ǖ������P6�˸�Y@�R�T�]y�V X+��Uu�e�������,��9|6݅ۗL=��ڰv�^=H���n�5ފN8�~p�"?�N�[�|�p��o|�1#J�U!V�V��s��ާR�zS2y�Rݳr��8Ku�sl�a*�}�{��y+��,/���Bnx��89a1A97oC��Cܢgg�7�]H����-vcФ�r��ݣNgυ��S(q�f����ښ&�Ჾ�,����J��^E�lX��}��7:�/�P�f�^��2�X�������kP��ę�n.�ʊϝ�!n���u�]SyTu�{F�9R��ж�QɸO�ư���Z�R)GGk�C�e�=H������;��f�L?5:i(��Sϒ?�\��CI?�#�u's��(�W�Fnr��cEڰ���
�v	����
T�f�aYu����o=��T�x3��l��!�+m���������u���/0T�� �w�7j���2[V��'�d�J��CV�Gت*���.�p�B�l�>����")�r��Np+���_���,Đ�JB�{�*��t�A�Z��q^F���x.m7����<��Q��n��O�=��T�o�;ϹQ~�Ҫ��&Z���� ��mѥ�E��x& PH��xj��|�)������}t�(>j^�ı����Fƹ�0�sQ��fV�cE,[��gH�0�������a#2�d5���j�w+�=Y��W/(�A���:�ů�G�+D6E.)�@u&F�ř*�"�6'7Ɯ9�����CD`�ss�Q��*�e�8���׼-�^�4�v*�8!�&�,����߀ ����e�gsz�Kҫn�@���MP����ꙉ��g-�N�ԓ�� ��Wl�}�_����>5B{~�� �[M15�b���cm#��� \1�Bfy���V�׶���K&TQ��
�ŷ����@��k���hǕX<eO�m��r|0�X�P��t*�K��Aapu*��x�Ƞ���Y��6��n+���vM�~�zxD��@��8�ũG��>N�[�'��᝸gRoٖBM��ϑcʲ��{��g7�bV
l8Iut���l.��ے����II턼p�q����1�J �\}\���YgZ � ۭE�D�A|W�~�~�fޑ3� �xDD��:�UF8R�a��h9�]S�����B�b$�cd��:��az�sRG<2~�r�����J���i�V���w�?*OǘHj�-+����V8����9h��~��x�*�	�����T!��H�r�扟9uw�H`'�v�kÎ�a��2D�G�^���p��R���E)c�>�8����Ê�tg\�k�\�ֈ[7�Ϝ��-�a�M0ܝM
���-?=!
�{q�Aj;��9�	��*mdg�j�Kd�Z��&��M��_J�>C�r�"�B�x~	k�h�b�n��wԊHo���S�׫� ��lNja��s6�_�C���-0��҃.&@����X��(�в#��só�t�1�B��\H�2��Q�.�/e�4W�&���� �9�&�Eܽz�m����#|�d�N��t%1�T�$&�_L�
e؊.��)n���(#�#vJw���������5�C��a�"\�V'��9�+ 9�]�EZ���{ў�s�6������7m��g4T��T�Ȱ&t]�|pn���C��g�#3�� �k*�I�I���x�<lH�we>�E�G�R�����kӷr�d���"*d���2"�b\�����
�
O[T�}"��j���cN�ar�i��5��F�~ľ�c?O�c�k�Ԃ���p)&��c����n��4�N���L��:���@�ž0�;9^C��V>�(�����Ob��)*\�Ž���S}x8�vl�G=p��!���4�a���pD�{a��w+�/[_=}TK�����6��?    jX�й�� ����1�Y���g�    YZ