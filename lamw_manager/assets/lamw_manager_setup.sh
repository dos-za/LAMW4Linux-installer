#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1367021318"
MD5="90b7f16d84cd1ea0ef6f74e37ec54dc1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22976"
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
	echo Date of packaging: Thu Jul 29 03:00:13 -03 2021
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
�7zXZ  �ִF !   �X���Y}] �}��1Dd]����P�t�D���3�+g�DZ���\;��Xd������k|�[N����y8J�h�a]R��?.&:�t��?IZ�~�n����gt	;�y�$�q�*��0[-�E������
�bi~��P�X}/��n�ﵦ�8v'���"�?=P�c�[VS��fQ����@+�z��ZK�o�@!\�Z;�+)n���F[�ħ�З�\wJ�z��O�@V�W;�?�L ��}���'���m5�z���T��֞3�B�0� ��f�/�a�����sv���U�Y@P�7ex��A+{*\43���I�=��W?��=���^�=��*��ZV�CHiy������������7������l�8۳�C`��s�ALt�:�IT�m���� A�Ez�����+ݔN��P��F��>R��TE���e%�� RY��#���W��5W�ڟ9�X��"qnԴD��ka��};�z��\�]���H��PS^ϫ�m0?o"�Z»uW��uHL_7���(��p�e���囩x�ucT���2�@?� P�1������z�R�2�������0_��Թ|
�2���-{��6�i�#Y�Js\I����c�{D�"������O��]/!�!�3�Q����MqJX�b;I�j]���D� �� ��ӹ�0v"��?'����᫭L.���I|�ScQ����+NB[�$�rG��ʋO�J�8��F�~��C[J�q@>�۟���C+n�]���O�6@���ꚠp����\�tdw���_6��P?���{�~���
�%�Kgc�w���[k��~�W�#�y�\���a��W�9,�G2 ���7�m���n�wn79q�u�e�p�}��A%����E\�{D��{nq�*Bk����O���q����a�\,M&h�'�C�=0�4�fX��K=&��E�3�������\wP�)S賡�C�^2�_
gEԺp6+ˁ���e �M}eFrꜿ�$�t7v��˲�7}�B���gA^ '����G#�E����z,@l��M� QnZ���1Wq^���S�2[����%Q�nA��x�$�2ҳ*_�MϝӭH�`8�&ۅ鋭Ë���1���X'�`�7����H�z��r�uC
�s��W�1�O�Mhno�,��םi�Ҝ�K/��_�fB*`/��*�Ϣ��>��<l/�[D�q@����d7������)�m��:T�scS�N�����x̵�Z�`���r�۰=瘖f�А*U8��7/�\�9���� Ȅ�����@:Ժ��a/d�"���-�x�W��jg����D3o�\�"*PI#f�ײN�ނs�H�*�|���˨�Џ�%_��6�d�o��@��70ݐR�q��~bT^@�}z&��rl� m�%��ƻ]��b'��-���m�Q����"�����K�c�0�~L�yp�I�q��$�G�"��?�x�����tg�<�\��L�U[��{&Q�9wV��|vi������ɴM@q����`������	�hLo��kP�OPQN�1U#�;�z�~^G��B?n�L�5��xKi��Sj������p ��z�ܜsAD�$yA#e������F��f��y���FL -���f(��E0����]+�������L�d#6g&/��@�&�!�Qf�~Dd���L�Up��� Z�������;"nrI�$b��݀��_�����q�?q�������W�ڠ:�;�⊟�i��pF
\w���/hU*B���a9���*n�Ә���U���赤�C���I;��LA�ߍ^`yӭ�4�14,�:Q1�L��$w�@nQ'�|�gf�ѥ3��2f/���(\�4��4K�� ���j�J��T/B��(�Ex�P@j!J�x ��&G�E���M�c��U��3�Hh6i�U�݊QH���">I47��nuʽ� �����W��1'�G�p��1Έ�v�D>�]�r􂀫&G;���`���y}K�xdwdc�on��O��F%���c?=�\�O�PéGc�H��z6.�`0Fe�]��
�P��83	�K&��͈�,�w��� V�r!d҅����}� ,������r�,ƫ���}��*Y��U�8��o��*�$���%F%�w����)���~l��yQJç�ڝQ�����n�gyi��w��;r�X.���k�M�2�����&��8�f-i�;�O\�H��,o�2��_��}��.ڽ0+���A�ּ]F���ey����d�U��Q�Һ܍-<&񀔗�%�xٲ�|]/b�/�ۗ5��p��"7���F��ɕLu� ���|�ı�1��'�Ĳ�����~1Kǲ��k�>
K,�\�#f�iS-�Q��y���ǟӔԙ^�P�Mů�y�{Ә�Y�#�5-�0v�@�|)7��s�F���I���n�4��V�X�06Q��&�D�3�⿎_�����h��}�W/�%����Rg�����>h��n��yH�_��L����$�����	F[҃?+/AQ�� �%>"/,�)@sL�$�I��,�'��90���]��SFz��Pl0��@U��0��w��H�-9O�n�|��h��A<q��P][B��qa�j"MX�}7���.4+]%"��.U�����(q�*@�9w���E0����?+��b;��+;pɟ�����@X)߃.������@��T��غ�ѿ��l"��Y:�-]��>������d���IX:E?k�Hm֤7&�P]G&r*�vd���k� `H������˵�,!ܨ7$ܘL
٫i+�?)�~��*)A;���Q���b.��Z��%�(���?�Q��8!n��>��D�@���ٷ��@b�Q�z"#��)��N�k2���\����?��|%����u����$B<���mr�K������O���7��v�ņ�:�|�R�Q���zU���4�2�{=��3���{���i�v`Z#h]�dZ�ߔ�R�"	�`ɧ2��5�7Ȓ"��Y1~��i RD ��ӈ�0*y��IRo�E�5s��MI�h�ҋ���"�S����L��4�q�t�����w�vm�c�Ð�F]=-{���/�����^��(1e�	���82^j٩�	�C#Pw������Eר2���d�䔈�ͨXE{A� �>��#�f#b��� ��G���H���� �:�U�D_R1Ӿ�z)f���.� ��eR�!��e0�Pe�$sr6b��~�NҴx���.W�sU������s�����WHY�����Nٙ���/�F�B�D�1h4���4��-�1�ձ��}�G�b��Qu`5��������g{Z18�Q�Pm�a�v��zs�U@p�̙�u���+mB���^�đ��Ծ̹�S%��v���|&�3�m�r���'hm�"��u��^8��!	��o3�������.�on�A����f���x��Ti�DE��6>�z�M�(�w�KT���ϣ�S�,$�R�qզ6��I���z#��>"����Ə՜e�R��$Il�1;���X�-���O|�3b4�!,��/H�b�˛ga�1����cp�~9Y+��D{H̽+:�*�rܨ*�{m�k]$K�T��0D}f�p9��`�y}��b���V����'"���8[�Ri9��ݼ)b�<@T7χ}OC?��1y��Y��=�/�:��8��		�~�4CP���P��s_P'F#�GƓc7a�e�)���.Z��g/*�y����O�$�К�i]�-��떉�0�G\;�	�05SM;j��y�]��r%�j+��oCh��/9��Ad����S����O��W[�QY��v�4v�]��C;dQ�u�Qm�=k��{i��x�>�o���r���9[���}ܧ\¸�����6�
w���T_��=�b�WLE����ˣ�����g)8?^��TƃI`��X�k���	+>�1��w^3���.�Sב���s{c�H�^O��wW�O������h�]6:��8���[a�JZJ��?���(�Z,n��[����c����6�RU�k����P]�쥜浓�\�u�)���*�9<��尔�O�i���BǄK+��}`��z�3�;��KyW�#�����ΰh�1�Q���>�Pa^v�Cr��,{�;(Du���ӣ�|y��Ö�	čGLb 5(�]�}���$����#O�3L[���T��y+#)��B�����ĀXή-*7|y�Am��jQ��l�@�^:k�m���/f89�'����Z%b��a������+��
2�\đ^�>��ʍ7��r��J�/��wI�Ԇ��XK��?ɝ��7�S3-�<t8IK��T�d1�{�Y��Շo�H�aYii��?a��&G���V�u��.B�lH�Ϳv� ���::��� �6K���.o�/�l�!�t��0g����4���BM��2�r�(7�V��E��P|��h��=85��"Ba㚔��*?7����s�n/$R��{�C���,�dPס\I�P_o�$�{M����U�`��
HF�J�N'p�)a���-X� ws�ڮ�uF.�0�vi��0)�ͣABih-�i|�Q���Mm^&�
O�Mp�=�x1!�)�:�#��p*,-���\]�3�%��<��85�����r{�L���� I0~I�3ć{޴��R>_�<���&�-Nf�X������B�2�"��@���5�,�[c�m�l�T�k��һ�}��~zGϦ��qkXvKx��Y]y=�K��H��s�:�N�-]�2 �O��z��)S�C�ƫ�Sp7��ؽ,�:o�g�����_{y�tS����0ϰ`Ɲ`�p� �L�n3�1.Q��^���� 5Gҟ���J�����s1A����i�2}i���W���!�Z� ��@����n���v����n�UF7�fޢ�R��A�&,	@�)��ʘ7��1�	�ep#W���l�D&�ָ�k5%9#�u���~ob�$�� �n�1�#ǉy.�9�zF�u�	R�x��6������F���Mpv�'m�ř�?�$?�ZHǀ��ג�/QH��ޤ���Q����C_�$e��L��5(!�@f�H�K�4��
t'��8��`��Xp�y9'^y�1��З�*�`�7�tPj�˷~�t���6.�&������Qz�6�8�B��2&7UN�&i��>'Ԍ'@��^�I�,;��b[�&�;T�a���R�8#/���'��^+�]8\m�B:c�|�l��z<v�j���T�������2����$�~'�﷚�mj$`zפ��G�*����f�Y��6�Mҗ�q�C��^�q�ղCƱYߵ��b#!MVD�q�����W�U��������=w�mѧ�����M:�Pg�@D�9zE��ǋ/�*'��}C��,��5 �[T/aEA\�'"M'p���
��sF���N;��b�f���#��I^���ܯ�*2!�T0�~EdQ׾��ƽ�	�6dI�#W`��Mz�h�,���~���`"<N��)����D2�Z���/����TZ�	>
�e��یק���C&>��{ݛ�f�m��j>`;,��#��/\�Q\�=u�H�3h����=)��X23�:�\�ɘk�y��`�i��O��S��Q 5(�Q_*CD�D���[�>8o�7Y�ŷC�8��j�(7�A��c�����8/�����Q7�C��n|>ѕ��pY�(�r7Mw����|�����ӳ�G����H��aswf�<Nz�,���~5E�0���36nN�� �quʼ�xl@���mL˞�Z�A�H��|��/�\�K��g��T�����zݟ�}��̎�<�O_�x�����55��m\%[���>s���z������i�8�4Z����
@�aW�-�K}K�Q"�+�-��N95���Ȗ��x�#�?��P{�+�Eqv�6����U�닮���Uu/��.�y�#

������ƾ����"~�����m�M�l�V�l��0-e������r�� b'wj�
2�h_�ߝIh,��`y�}�BmCĶ6LO�ٰ�_�Sk��#�� _!�е�	[����FC�=	�/W��,�.�J�B���ڄ�0kѐ:ᠹ�C��i��K�{Wm�̿�+)e#� ��!tv"� ��.�п|؊K��:q��՛�w �N�s,{���-6��&v��i���
��D�"����n�Qu�DPF��SLкm�X  ��;�8~%�Z����a�_�a}�qLdEQ<�f�`���>�L��ţ��`�c�;#9Z� �7�؋Ʊ���o}�"Ү�XྡྷvFX���*h�2�����f��R7�'�}���X��g39g��ڪ�!�4�����LL�M�-��~�;`��ۚS<*N�A���J�4���f>����(I@y��4�Y
{&q$pײ�n �����Z�Ypm�@�ɲJ�l�:�[C�;caB.����#ݤ��UTy2�~�ͮyc���oέ�$�?8�/�|�"X�З!�Z]��(F���^�b�ẝ�.r�J�2/�Eeݣ�C8c���s�����x�g�@�3��ۉhT8��4(����W���4����[���ʋ(;�E�X~�m��~K
̽	�$P��@բ���9�潂���N�Z��*�h/�3pL�6Ҝ�u}����X���J*��7�_7k����X��8�<"c%0v�6��(�Ѱ`̠���;���ҭHRL,"����/c�=�C�|�޸L�1��0HFÑ�Q
��z0UR ����dY{�o%���8N)�"��S�
vEV�� ~˷f9�����I��vJ�0�S�!����aʤm͐���~��Tr<��o���u ��Y�D�3t�R���7C?���\R��=å�z�ʧ�n�/OA���a�BCN�_&��q&��ό�\*<�(���RRh�Ɣcb	�Y�߸/D�>�u���p�q��L���Ge�F,�����n�B1f��|�z�Ҽ5������-^�/�뛘��o�zS "��Q�0���(��y���֠��Ԅ1�+I��DTh���v���r��2��_�^s맓+��8Θ:d4D6�mA�c?sߌ�^�D��v��ʐt�1�Q=�m��!�#�ױ[��� ��@�H�Ӽ{i�
gPo��) fp�N܊�&f(1MO�3��F�~�'Iq����4��&���o���do(�u��9�O)��TƶI�.���`�T�8$����&����w:F�H9��M`��2���5�'��&�@����v�Dt�v��sLQ,6����7�p�)Oi)������k�?]�'�ݲ�Z:�X��D����>鷶�7����ywH��[&)���maVe����z��*��ŖQ`�["�N5z�ǭPH-��Y��w#
�P:��U�wL��������\@l�s@�ᮾ���/��	j�ɲJ���i$�(�<���q�pj��Vj2�Y���ڽ�]A��\��{u��mb/T�	���~dy>����um�hh���4��*D�M��:���Čp8��́�0��T뗱!����1�{����"x��$9����>_BȲ�
���e#*잯��WG��+��k��Z�E>i諻~^DT�.���^��}*���u[u#��П��]�*��1� D�D��TX��nR��gU3(�p�,���F�����M�t�bu��<�$���Dy7p}���3�D���ȥnB���*n/�o4����zn�^�{�T%<�ƫ�R�梆��[D�8��@������3(�QjK�׸�m�S0�Q�I�#����3_c��ԓ��북��N�ն��J+�}7�т��{�8O�}���J�&xt«2��,P�|�I�������ˤj�!��1>�6s�s��],�� �J��[#ִ?F��J��@'��9X�F^u�*έ��&D��y����Hȫ���j}�^�+��2%���z�gb|��_D0Ipg��:Y'D� ���&�o�܁@�T���@NG�Pa�X�����Dj�W�Bl�d��ԣD������ ���+�Ø�8�N�,3IH��N���	dr�-��PX9�IO�e�q ����ZΥ�f��㆘��@�D��EY/Q�6a2����}IȮ���ڜ~(y�a��}��Q���ut⠧�6͈{n��{�}�:��)Cwkj3MR���@iW�Y$Ҋ]8E����z��mMM�f��F6xs�?k�hts�a�(�ha��})s�$���A�@zkPH˻�o%�_CF6��b��|�����V�K�������bQ������~i�A΃'^�+�ѽ<*��^֮Βˎ^u���2�喺�:'ߧu�q�.�x�&<]HF�?L�41l�%h,�<�C�V�Y���Sַ��\.�i��\�S�����/�#�8�������D�������В���.k��R$��y2��r�na�C��@��Qq�wB�y>DŔ^'���na������Nd��$������w X�1Ϲ<�J�,�;cr�BO#m<*|vU�;�C��eӇ	}5hq:�%z���Ӝ0�Mo��p����j��0����
W�f��q�~=�xn9��9��ߴ�%�gm�H����PߺG	,��d�D����lq��w�!�^�XU�Ë�����0f�j�+�}ֺµ�)��Sٵ
�U�GM(
	"�\�qhS�u�m�cp�C-�RW�*ʤ�
���?���C���Ӽ%Mh)"`��J���e��H, ?2#��S��~���ə͏��ǆ�l�캻��9V��Q�̧��$*�K�O���ڲN�{��60�a�w c�4Z��1]^��vx��2O(�^Sĺ�}?o
O�J���yq�/���t�1��
Qn7�AZ`��"۰6�����I����Z6`�?4wB�ۨO��;�+wā�yAd��Z���\�uTv���gzذ]`�Gs�47��mI�>����g{J3!bU��*�L��?)��N�Α$B崊�uu,��o�"wEV�O��d��� <D���,[^��_�c�������[��w�j/044/�n[[�{&�WR�zܢ��əPf1 "��7ps�U�-C�@�a�G�)r����5u��G6�)Y��"��cV^�+�="�w�M�D<*R�R��m9��T���3WA�?�<|+�����Z�~�t�sHB��U��b�J��p
����&C��UYJ���glN��]܋åF�|0m�C+�R]w���R�=�[^'I��0\ �9g����|up�\��8��]턓,4�->RSc7_TNXpX %�3�7b���aU����=��m�|=#�^�D�)����
2\������B�䄥�g3X��+c�т`΂;�}q��B3�D�E��H��SV��]I�6Jx���GG�m"l���Q�h�7�=Ǉ���Rt$U�K��SJ�����d���]-��
=����w�6�b,���cP-N��1"V&T���E$�ը��J���~�U�³�D���w��⎶N�8�(!P����M��T�^���$�*�%]��T�J8X�T�9<*�ā4:�ϗ@�be�y8��+nYyT�[	�k����f�W����(���a�W[,�ȦH� ���c;��}^Ө��Z�&ެFצD�����E{/C��[W�Fb����:FFF�{�Q�0X�5l�p��S)`È'^~g}�޶�r���Iܔ!�!�� īYk6a��n�6��	���J37bG.��]�
�:xy��5�i�� ��2���|w����ؔ�z;=�*�8����7UY�>�N\S\Ѭ�>��K�MQ�y���>B���3E�b�ڕ(�
f��ޥ\�ڵ�uX��4)#�ư�(�[�����ּ��ҍ,�#�L�$���	�& �y�
�c;E 0�z�t(OGp�������Ʋ� �L�1"��f��H��G�`�	��m{f&�����O���y��j��������h���֪�b�V�OF�k��ĝ��(LFut�0����H ԰㵋���#�nb���Vَ'8X�&s�ոUU���>�:\��R �<��3м���c���M�;�T1�b�@f�p����P�^;Ӻ�5?b�
�/��c�u�І.�x�!�?�Z�g�sOʒ���=dA�����ۄ_,�`��&����Bf��++P`U���D�ec]x3Ѝ;�S��V���J��G�u��ΐ�?�I��K)�Z��Fk\�u(5D*���v�/�V*A=*�|�#b�p��g��n� ���uxC�}�ǂr�9ӆ�Y�<S�fU�>����5�4��3Ԍ�s��
*�i���0�ҟ>[�үѕI��Ft/E�\�ٺ˔X��ôFI�\Ww��^�Fe齐�jW.���_�C����NE��l�'K�1!]F�6��zB3�
�I)z%���{"���O�jQ�%ݸXJ�K����'1��OYW�[J ڡ\^Q��QP{�3��I�gߓ���qr*�F�~����Ov�ϰ|3�aI����,
���#��9�zS�ƪ�ss�,ʹ�S����ȅ�F���d�������%B���P`&,��s�'	 "Ȍ�}d��8'($��$�xC��,�"ا�xwe�r��V�M;#�OVI�v(���� ��F�]��M��	��U���U]��vR��Dnp�,�T��.�����}��Vw Ю����h
��pX Q�4즁�QW��q������kތ\]P\��
�$��cׅ�%_Ң#���H��>���w��֖{�U���hN�d:k��*���|���x�-C�G�$��1�yp	L@M!��غ��-魮K��X�9}���tfM�7�?�]0ˣ*첷�?�\m[yJCҟ������_�%���gn�5�va�%���lA����q	����H�5�K�A2
�X�U�B�	����k�P��":ʓ�R͘���%C�<�#�MpW��������h�Z���ʃY;��ڨ���v�����������΁h4��dD�_.�_���v$&�w�՛�>M�n�P!U�AG'���4Y|ɉ3��Q#���@�gV��Jv�<-c�3�r��6AJ�bB����5�+o���)wbt�Y�g2��އ��;�C��X�uRXk��q��h���k�p�{�������������-�>	��_����U�k���M�*lr���v*�?9k�Dhb�+�n�|���p7���^�����i�v�|.����i\>�˓���W����
�ÃMu`:(IGDܦ�F�sh�&�?�+��5� �L"��3C[���K�;�g<J|��
O ��A��N� w��i(��kUO�>�c�?�~�c��jI�b����}P�fhp}k�5���#���ۀ��!��r��YӶ>3N��8�����e��4%�����?ߩ�*\���{9˂1�'���dNPMkN!taG��Kb��C$Bg��A�9�y����S�m�Ph�%Gj+�P� ʅ��=W=�Q_'X缺rڄb|�̂HF�{p0�`B�Ϲ���,�f�ʏPc#�KS�j���$�V<�O($f��!=���J���ؒ5��wZ���N�� -�onb���P;q��.�.�J*AT��$�=�H��C�����*0\ߪ���#l�l��n��Ҵ0���f��v��̓���57q����C,w���i��Ty3�]YH*\@�tP��w� :�@ L�'�I�"�j(4���Ӹ���V
�jS���tA#�P�q����4�AאJ\�+���$[�n�_G_���ۇd�D�k�����2Ƭ��41�;���"5���< y��;���/�Nµ�'��]�Vl��*lԃ�7�>$yg��g��@e[r��t���/��y�Rl�F�0gBF�0q}�>���m��)�ߌ��U�cO	���G�~zl8��/�t�/��]�}2`5���Z�XF<.~���6��z��u��G"��o���~a9|��m��>(pdLj�[P����l�z�Q��� �ڭF	�Ү%�=��6ą�  H�	C\`(%Cl���
`�I`{zdEt���9�vh>����XI�b��{e�͛�rM_���H���u���z�ٓq"6�����(���Q��
Å�Հnrc>��i�������}��$o^A�H1�$��Y4�����RO����_�5��#>"ʬ���Ը�HHY�buń���Zj��ȿ��l�<L��m�=�M��W�o���8��%-���j��*�nC�[�~)q=#ړӽx���A,�Z�KB����$I��Y/\����G�Y~չ8�V�o�J��U����e}ԓ_���4�A�oR�FZ�3PLB���fEc�|ѵR�>��"�D)��f�.�PH���2�����t�����Ѓ�].��k��t��;�bV_����?��f��J+]�|W��nQ�7&��y#���p��8�+Y����#�|u�ô���xAqQ�߮7���i8ӷ�t�eK,t<��P�����^�<�`�x�9�^&~Q��Ж 8��j���n8��æ�.
�q��T$=g��"r�:<�����`����Rn�P�`Ip	$|]rc�-��f���ނ�W`�=To�����T�,M�7����{���-(>�"�C��ԋG����|�-.I�3��8A���{Q����"M,�H�ݎ��|���M�!l���=oA�i=���}�: �>A��|Crd
:iX}*�8���3~�=/�_����r�1��YհS=���ǣYR���t�E$����l�V-�G.�B��d����r�n:�V.EHԿ<�)�)��ۆ^/���2/%eC��g?�gh)y��&�c�6�S/a������PH=R�Tv̌�'_��L� X	Gp��B8����KL��<OX���[�]���7#�-�u�
��/����.l�F�^��F(�d"t���cz��RI8ӌ�'���1g�̆��<�/J!�hHm��>xl� j� 3��5�	aRd�����}pA�,r�Q�Zw<6��n�R��I3��8���t)�̷0V	M�J59_�yMٳP�����>��f��L�<"tP�lI�ϒ��\MP<l���j	�t�%�Y�}�ZL ,f� Ȕ��������x���u����m4��d����ج4s��:����d��6-vkD܈����'~K4fDۚxnY�ܦBP�k��>s�2Y�=8�+��ZX2m͔s4	U���׊�?X/�ы��쎉�z=]Ӓ�2��KU�&Ɣ.0ϙ.!wC�s�����@����"���3��P��a�+�����RR��/�����zD��)/��o�A����,� �=��d��Lݽ��⹼���lL��G/d\�F%�t�C.��,,w��?\_j��C����b.,��J���q1V )ܘA�����p�u�Q&k���]�Q*D��t���G��ǭ������U	�۴����}l����J���]
4�T��nπ���HϥZ�C����u;��J�lgO��d�35l_l.5��=;ovn����\�|k�.�dЧ�2|c͢kD�$��f�ɷ�r�>��!c��صp�˃���A��%:�eC��r�_vR�ԁ���r�Wr�6�`��]܁��	�d���*%$
^�S;ɯ.7�L��AF�C2�)8��HX���������ɋE9ln��Y�%����oufءr��?5���!�ʼk�]��e>��G���ݜ�B^bC�v����^���x	*׮�.f?����BͶe���~�sϔ׆�?��ʡ�#F����t����+��%Z-�����Q
��K�3�����Vi��+x��v���{u*4nf�o�֏b8Є+���V����#��������kD�#j���3N�ViT�Y��ϊ��k<����V7��r|�؅�܇��)��}'�X�<Ue*�� m?3��WLG�7c�z�`3+s��Kǫ)=燴�"3��RC��$A���FI����K#H�W���^�8�>���ngoq�N�k����m��I<��+�q������q�cw0"&|Vঽ����i��e�77�{�z� ��Xn��2m@��3E���U�O��0P�n6iқt�7g����]�Ă5J�3S\ܳ�JL��?+8���d�%N,��W�+�N�§��K�_�i19%���RIa�C}
?��+b3,�u�%�RD�X�Ż�C����x]��P��@�~W-��ןy��k!�MZ|5-H����ĝ�p��F�n9��~�C>z�דgӺa}{a3���̈�
^�4g��X4 �~+�빱G"�t�O���:�n5�=s��W�x�ͣ˲+�&�:�_m^L��T<f4��p"��{���.��H��i��bD�̢�S�,d���G�A��8���I�p�q�1&���a�-k�2���C^���ߢsO"��5�VCG	���mc�6�zPz�%�Bù��Ѕ�Q�WY�Π��S6�zFΐ���(�0��Ze������3Y.�Jc��Ib�n��X���<a�fF�Ph��No��I�)z�|�Ȏ�LI<�z���w��袻�.ɫ���G�]�r��*�ŧ��kl���B���)Q��	�N��4ҳh��x�?�~�vϾf[�9��9��~+����a�uc�	�Ωĵ�V�Zu�v}㩶���Rj�-��VR����߃��t%s}��{CM��9F�%z����~���*��u���
��#
�ܵ��\����9��\D�����5w5��D�fy��2�]�5K]�F�{����'(_WY���csFlӫ�l]8ߴ��-��a���4����:�)�ti��lς98��a�8����=���(�`pY���nl�1�5u��t5�-�������eبy�"Aޑp���\Y���lkq�����&�og~Y���2g) �IșU�����l��Z��v�~���Λd)~z� �{���(��ZA/���Bڑ��BE���vk����@��g枉� ��g֑��ޤ��#5_��[g�ח��`$n)c�b3��,C�~M��hq3��6��t�ό��6hߴ����s��Ⱥ����=y"Ū�̤�� ٝ~Gx���&z�h[֍��8��G����ݫ�� ��+����@g�.�y?��6d&T�p$�]�Dʈ������}�W�3NWS�9G�,��M8�~E���4�~C/ב���H'��+�}z�͗�S�	0"Q7�/�7yj0C	n��$�L�fH�,^#�l�3�=�^u���cP��%b�>��$�9qo�צu�r}t��MѝIS�B���&��c���F��<�ղ����}��m�j�7�m��Fؽ����a.�(�&��k�	�7u���
�j����t��);7���4�	E'���v���T�X�R�A�[$��$�;]�s�s��� ��Z'Cn�t@Į�n�Na�M]��V�1�i�����A���4���H�96/�UǿTJ�����&��$�`kNߌPc���+�X��	�<�LX�@iuA,s%*��&�$) ��xyZ���+��E��Տ%��A��U�*)Yy.ȇ��HR/M��~� ;���2��k+_�@-c���.���I/(���-g�c�ߦ�"����hDX��P�w�*K&��Yc���&<p������p����K'�X�!�;1D��\B�f��*$��9yh0��<��(�x06���nհ����F(qA乊�\��Vt}m��� 8����((�W���˶j�`,�s4u@�����Kv�L�Iˏ1"͇E�,�=�bp�r;ą4Y��D�Q�9�������ƊQ5P�&�ӾX���L�W$�D(� ��qx�=�n���	*�GC��0I�
�(�����˔#ʆ���'O7Z�<�~OR�"m�(5SƾE�?a�=㢗^���q��`#di�2�?EL����vp�>�a'�>3N]."$A� r���pc������)ݬړG{9�uNZ73B�)�:�<�Hr��ۻ)`�����`��" �q���Z��a�X�Zɐ�����D�=��4��	*����oey�'\���u[��b�,�t��`?����[Uo��	���bۛV�b~-�J���s��!Z'iٟߩ 	d���e�i=F�[�">|��QMP��u�f�Q���Q��� ��옦��ì��XX�!��H���� %�������j��_�j���4
�o([�-��|�Tr�/X2.G$D3�)��{%��Vݏ�቎�$<�/��șb5)ZE�r&���ΣLEJ��F��ݵ��ѫ�F�W�˞��������ů�Я�4�9@������*�Gg ��y��э5�A|Y�%>���MK 4�!h��[?�?"l����m��n!�`�� ��q|V����S��j�ڼa,��gE1qYj������%Ej�z�D庛^釰[v��$�ɞ9���ט�ll�+�\�
+����B�Nv��BZ�0��#M�H4�E�����ە�G��W/�sE�A׏7�v������,�����6J�5�>2�AG�98�H��F˅B����B� r4��)��v���mk�瑊�t�<)�捸�mޣ�ѫ�
o�^�խT+(���G��/]���v�����r~��cz�x�m�`"�m��;S�[Ciy�K�(B��	ˏxOpe��e]�|�G��XQ����YZ�K�-j��?���<���O��˓_����>e�"L� �o��f�&�:�k��/^�n�����qE���R� ^�l�P��z��$�� u�a9"�}�e�r�ç��l�����X��Ë�f��������#�uS	UFCKd`���v`��V#ZU::��U��=L����HF���!a�U���FEFx2�/W������N�M�'Yͼ�m�w~6���{>�n�g؞&_:�⪭�*����
�Y,�ƪnh�kz�ބ�ꚪs�e��y� +�Mc|����:�J��2H.�4ߧ��~�,�TƋ��X�@�~������g���Vz�b׹��۝QvP*�SF���� �<�(Xq�$�놓����D5r��m�;�R4�r���:j����]?�{�!�����v��}��@%�1= �W���,B�������F#V�q�@��-�b'�ڛ J4���i��_��x�W_=1�|`X��
�Y��;��*�[_㦍�>�{?3Q9�FQc����V3�����s���g����tIu��X/�F_���u�\ʲM�K�W'UD��u�c����^n�Aˢ)�s+A�Mц;��ؤG5Q��hJ&�Q;46��`$�X*�Q4���*2��h�K����0���;*��j������%ei|p��'�qt�(F�]$6�?�Z�_۳ �Z����'~�V+��׾7�ߔ&FQ�.{�ؿ c��������-��sн��2���YY���F威�p������R�$�>�
�:
�i�����<���\�����6�!�OBY:`��cc��>�_J����M�����E2��[������w�U��@�W�2o4���w}�W��ej��rķ6̗�*<�y]��tsx�E!�D�M�mr�Ħ���2��\�$��3� @�}��4�e�:��%��@�yn�ғy�}�Ve-��Pi�6,Yl0W3��q���\Hwb��׼����7>5��Ά�K��LB�'���u�^�3%�d�S�rҷt\Hw��N+;��6?�0�T�d�4�Y8��\��N1���PՓ���1ml��e�����4$��ڽP�1@�ܟ9ַg�D�{��Q��	�7v
RV���9�lГ���Z�6�A@e�2���M�:�ⵅ��@m�Yw m�y��MY�!�BnM�F�AYJ�Ɔ}�2b~�"�߯�$A�%���&��	�>��71�S|[\m[�P��nOAS�4�UM�?�3@|=D��\��L`7v�*�VK	�"4�#.�^����V.Yb�
���m�$(�)&��1���5��)�] ��Y�c�ǌ�|�L�/5��p�����ʀ�;�% ���x&(�!u�oJ�����)lu�v`�M�$sF+�凉�ӧk�E�F��yU���[�^oi�@�� �`�Y<���%���YVF������)ߋd`�� !���K�����C�����i�p�}��ܜ������!
��sGA�`�<��)C�����U�̓��ʥ����ý��¿m�1��wv��>�!����,a��35_�0����,^_(-p�cD�4��
T@lK�3Q��N�g��6sgg�ie[��{��C�K��N����
���B��V���g	��K���&L`����m!X�4[�aqNS��<�#p�H27��>Uk9�r1¤8p�b
�s���z�d6�6�O�Ifg0q�N옱��}���Xd�v��.ws�dq�`����.������*\��/=5�ߪ��·"��,;�\J�"o::��#�ͯ�>{���+�u9�;�ra�{O�#ӓ�X�����IF>~��U�G2r��3ڂ��yc�!�tlBy"�~�u	@�t�F���6>�H�})��J�����g�g������ C�(���~���?�v�L�&Ӑ� `NC�8JS�3�M����"���UO{P�Q�;&�Lb��)�L�kP����?Tρ`+��M�e�wif�S�F��I�Z�'y�x�rW�O�]=2fPy�/.��Taл�C�l5�H��'��lM$�/�5.�O��[u�.(V����Q�_��ޅ���iI~���#��VZ�>�rMM2ڸ�31�hK
�w�����[_K/Y�t���[Y����I4+Y�n����3d�ϑźŵ��Ss����@�YN�U����45a>����]��G�@����$�����$`OJ�ئ������*�9�S����cߐ�'��+�ֳ�K�Ǉˆ##�j�`�'�)���`���T|���?
�p�T��~���@��8�m.�Tv�w�Ҳ:�����gU�ļ�V�l��p���]�S�籓���6󳂼��-.��I���~�W͆2`��Y�>�9$,c$`�=?h�1@E�D�a�oOQ�8u�a��Cn�5'cq�$�@�yA9��0m3y��M��/�m���Z;*g�03j�Ej�&���;ް5i��/ڱ��O�#�1�P�nsK�����xヸ���o*7q��8�ď��D�5��{���^[YR4
�Y����o9+I[����؍p�G�{!�ݥqFu�2�gx�׺�`�b��g�Ή,�UM0ƚ;��7�T� T<P��觽��?X��6�����x�O�������
'�E�����r."�z^�d��0e(�{!�@ׁ�,�}$5�N�3��]+{ì��M�	��}�t�*e<D��/�s1��e}{` )�?�^�+S�_?M�\妜C,=�M%ɠo��0}.��gk�JP@�j�~�r!�E�R���TO���݊,ޔ�mn�OQɄh�W��i��������Zc�^�������d�S2J�3�O��)�t&�����Db:����O\�](�+#{'���ZP'=���;�	�#�;X��<�մ>[t�\�~`��>�X��$��4�����~����Ґ�>��1��������9,6̞\�S��4�|���	��PףDQB3�׶%����rJL�Jٝ��u+���`+�wO6َW�N�;?��J��ڬ�^�7P�+"���|--� ѩϠ���?>��D�E�vʸ$�f��9M'��*܂�UDO=d��9���H
���� N�8:^���)��j1C�l}A��\��� �����[\:��gHK������a�a%��_e�#EG��x�8�B.��C*�4�[6�M��I��0���"N�5�� f�4�H�9�8���I$�Z�a�4D��7�	��'#�{m'�▹H/��N*kp՝�2Salčߎ��0�.�]S'�_E�a���tp����"k�I�t���,1�3�%����ш*>kY���;�Y�`Zk�rJa��i#�}I����o��<���g����r�ƍ[���D@5�XϱQη
���O�CB��m�)`��yԱ��2����}�O��95Z�P������}�!^��\�b(��}��4�1������E՞OPt�I�g,�]Q�C\3�r�F�u�y+����4b��
�>�Ֆ�OrM]�h,�-�f�U�K���Ϊ� ��U��Ll���l��ͤ�&�o�OtU
+�ջ�oi��Fjs��0���9k�ak�utQ�9�!��q�&b�%�j40�[��W����4��+�!J�M�>M���*�-�S[��8���,P= ��&�ߵV�� �᷎�,�5��'0����y�N�i�פ��J7���dS�o-߇k��Z:�F\m���|5T�Oi���%L=�lAODn�3������H�*-���VE~�q*�&������m4F���sD���pD\�e�~L�������o�Z	�wc�46�6���[a����맨�?tPV{�6�F(۽���e��\��>�BlY���w�&K���{%BJU
����
��ˈ��ͤ$k��%z8-������6���1�S\K�L	ȹ2�J��(����m��X�|����4��jz㴭܄��̈�r3BCn�m<�CG<?YRr_kFPs�	Gh$ʃ��ax�Sq�C�K(Z%w��5�� P�a�,�0��$���⼥Jz�C1�	�0��_�^+4�K��u=w���s�����mJ����շ���z�l��w�Ѡ5*��ΘPֻI�A�|'�lN�[φ��з���j��c|UM��;|�ZU�7�������[-]�`w��}A��M�i;ɀne�D����C%tn[|ϑ�v"g3�;t�xDY̓L�?�����W�/l��
�����r��8V��Pw��g�#+�&��"Y�Qw�.B�����2��|׊��:�Yy����1��ysxӧ#�3�}u�+��G�y�/-=�.����W�g�Wja؊�q��*�h���i�_{�{|�柺����z�B�%��ŷ[���K�QI]�7�b�	���� �c2_�;'��.��;ﮤ���:�n@���$P�/Çңj�*̏H�ff.vY�v��r�g)�p�Q��H����δ:�<����0��p�b�'�f�����e�܆���j�UP'��v���F��k�PYj_�u��8�%u�GN'X?J�Ko__>���M�+Ǻ��3d��t�Ɣi���2������Ɓ
��>�)���(<Yb����M����;z�&�ː,f���\�S/�H��<Ԥ��E?�*�oa���d@�@s>Vpg=�}�rT�g�(+>��2��4�M�I��0��g�7A{G�z��9E%k�N`w"�!��� ����xYĔ�pxOȧ�+^��<��x���q{���_B��o�|�J��s�l�3R��[����¤�ś��ۭ���n�gjϻ�Ai��Pɾ�b���L6aĚ>p��+p��l��N)݀�R�@�$��L�え�R,����'�� �]����T�v��h��װ�nl�t<X-켨�~ԇ�jX���Q�G-$cp8��qK�i;ȴ��Q��S9%���?���XH�����Vu�qe����[��R�;#@R�,�Q�3�! ll��� �W��ZPIQ�t����D`/YΈ�I�np�=�)�e�p���GsU�a� ���?�L9�h`%s�G��E��0;�xx��q&3�&Ұ	U�f 6��Ύ�О)v
+ �~�?�fD�"��﷛��@K�/�t$���d�y�"�W�bK��k���V����0Q0	����oǏ0ВN�y���,o�c޿�뿵U��l�Z@����b5D�둊�*�"�%����ޙ�$�KҠvK ��Q'�v7��X�و|Am�e�K56�����F	�)A+���L|�գ�Ĉ�r�z��5�|�Ӗd� �* ��bYs2����z�5��!�5��ĆQ�m��ɼ�U���]TPB�!?���!��\y-G)�1{'��J�R�9QQ�.�O
i��9�ZC�r 2ΥMe���{�v���ў GE\i1c��?�6�$�q�%���1���3�\�BG�+F��8�2�lo�h�U�_�:���;�Q(��O�-�ş��y�7��3��.o�8ДߒI��L��Yxۿ�V�����?����/V�I�E��K��l�N���L��s������qϣ����. z�:�����W�>�. a���[�x[u)L��z���@]rER���w�NEK�YS1�%�Elx>��Aƅz��c��*���c�r{�$�Ւ9�t��n���1�=/���Kɍ�Ʊ�	�e��R�����#�[�{���
��<1N"�_�f�^`����p�v���΃WZ?ќ���ypҠ�3O��`�.U�<�[j��e�z:��Y�:PUx�_:��A�e��0vTa�c�^琕{|�qy&���^#iۆ��2�p�~�e�U�D�}y�v]6��ݥ��)�h�7�[5�     E�iO�Y�q ������
��g�    YZ