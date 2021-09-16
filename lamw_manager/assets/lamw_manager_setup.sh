#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="856229328"
MD5="82cf47c74592a799acd0714a828588f4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23756"
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
	echo Date of packaging: Thu Sep 16 15:41:02 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D�@:�a+z��xr���0�=x.av������^b����JO跻�*���f�B���r�����n���P�{���A)9�[��(�k��������,bpZ���Z)FH17�ȱ������UJ�VU�NH�K,�Lh�?�3��+c̒��p ��s�:|�)eBf�D6Lg����������_W� �7���^;����,q�m0@ж?I��*C���_�*��1�ha�gc����#��m�󗐙sfI��ky���-X�>�8B���.!`]Z-���YoC�c��"���s~q�f��r��l���DR�9�Mhx�������Sd��'�I����,Q'����uqk����>�i�{�^�Jܗw��̆��D��UWj�cTc6��R0|�����HVG��������Xkn�Rأ���c��&��J��2�:���]��j�y�m-���W��E���ȅL*�k��]��	��NI��)��0˫�TF�?1�)�4J\���k E�X��d���^��U����u��x<	��z��N=��&�Y4|&�v�TB��U*���˹]��
v.�ڝ���������XF:�crOR�϶GzR�t�N��V�������,Vi�`*,�Xs�5O��ZJ
_�o}����aۦ[#:����ι�s6ШgU�#���U�|����V�0�@4�[�%c�*���GSw���E���ֱ��)�G�!�#SOfϐ���
��M�|�h�F�����ᶮ�*?9���a�O��MmJ\���ra��lfIU�����CmHL�~�!�?Ѵ^��^�-�m(
����Bb^2�%�5�;��G���	*�JyX��	���D~��DO)y���}g4&�	K�U�����؍���� j�&������|T��6^n����z!�b���W�]3�t�G�5��8�Za�<e�:%Ƈ|O"�{K�8�Yї���:`�=��q�獶
�^���`�f��x��B	h$F"Q%�N�Rhq������y�=K�ː!>u4��&��� ǣ�v%a{ƪ�ۻ@��D�*K�T&,%ܚVsu.LD�~9�!���-`�v@qU�v�X�s�ڞ��˜����R7��,�!���@��0�e����
+4�P�Zڥ�`���i�/�$�]XU}�ʛ
w}J��<�eY�
��|�Q4�=ت7� �-�f�������!�V���;��U5�㟖1 ^��DÂ���R��5�*�x��nuI���}���R7h��=�-��ʈD��϶�}�=������X�M�#�K�5�'�5@�`��r"%� ]É$q���X^p"�ؠ��h^�������e���/��P�_*�j�񏔱�2ҿ*����Z�.�wjT:Z��%��~,��F􌓆���dT���֮��*�	�}�B� ƾ��se��O=1�K�|?�J�����|"u�D槲v�	��ȧ�ت��t��G��nUF��&'�L0�D��2�L�%��hcX��v�x#rN��a�k��
��G�ĕ����q��9����:���4!����b+�ס��EЮ���hH� [���B����Eg6D�v䃘sC
{�E�Rh�4Q��/'�MK��n�����'�!��^�<~c��V��'�g� ��j _�0�I4��X˴ОKX��Bz�s�t�	��CW)c���p����<1g*�c�33җ���j���ba���So��:�)*&� ��?7�.����� ��ȡ;<llC;-���BQ �(8n}�;�!i5��j�#����U2�t:������)(�1�k��J_���sa<p�e���|�³^n��'��*��ݼ�N{��>S�`K�6������/y�0�.A��%C���G�����@��x�ς�Y�U�@�T�>�D���{���Y^<Bʫ����lݦInIV�Z�$����뒻g5���Pf�V��WU$�I�4�b�Id�y��D��Y&6��y�C[�(�Q�nnP���B��,p��1h�jp���t�z;����q*V�����g	Tus��o=�yv1�\�޻�?`Kp�N��n���D�S�`�{8K����[u�b~u���Z��o���Ǌ�,��Q�����ݣ�����(%����.k��!!����J9�ڒ�*���(Z	���©��cv�/�=aUK���hRޠ6�\w6E��F�.��N㟖?�q���Zެ�,�}t�ε#��B���/yb���'^^ckx9t�ɥ������*6V"Gt�Vz��V�j���1���mjG���1x>G�$���#\u�	�}�tw̶�H� ���q��$�^2	�0���|}�s0�|��9+�jѩ��xB)�y����~+�������^\9%6A�V�5�Q��"��/u��f�]26��g���x�f�&NZ:�0�����O
��V9ʜy*:�\ Ƚ�80��m�X�$�G�+O]�@�",�~�;TR������J�3�4�SiZ��F�Ԙ��4F�Ŏ<�v�����=F�:Y���x����(��P���l|�S��#+�-D��5S�������8="q�]"#%1�4!�b�ǹ���$k^;J|��3�`�@����k�W	A������;��bnik�W��7��Vx��P�5�7�[���ݕH�f��ǐofq�m߉����a�.�+e�s�~�r�n���:ʣ�{�28���WG���kN���wnN�̜w�� �2�W�����`�53����IX��r�>��}%��)9u�P��0���՚���R�,��jG�6�,��qAE��>e�569�v̝z(ۓB�˳n���}�� �#�\4t����37�ޠ��@n=�xb]+z	
MP~Л���fB/���[��5z�t��>H.M��ٻ0�q�1rN&0t��/���:7*jL�`o-����§��O�A&T���%u3/ϭC/����Y�P�4��r� 9E!3�wJ�����)"f�Xɷ"��#D��7؞y����:����Q�V&��� m�mv]iq�m�P��}��?W���yO.Wz'P�7G8�>6h�Fq��}��On#?��?��tTp���Qy�<S�
���Xo~/	V��!��
�ͬm�&/
��W;y��]X)��酎~��Z�~�M� �}J��#���Ҏ��Z��'��0�4�.�q����1=�'�5S�)�f���:�'���w*�*����+�4k-�!ϒ	o�scp���"����x��<�B�L�nei��v��ߴ�I
���d� �%΂�/��"��5��wK�-�p�z���ָE���R3I��&(��?�LKY��D���8�6�Aj����(g���H�ҝ�B`a���u�^rV����dK��|� ]����)��w�F�3���]��� W7�س�O���Y�7A���ц������t#���wdumx����.����7�R�
e}�Lڨq�$�q���g��NF�?�L'��T��r×=��� �pr]��3j�J�]f[I� Kھ��ڞcsYq;�ށ����˖0p�o��$�7�n�tF��z<�=�C Gq�����l7��#�j��~�(�Y��(Q����R3�M��5�X�Ag~������c��7�V���(�ˑ��u|��=k�����.K�U¡�x�C�M���GF�}�"ɘ��T�"$����;������`9{�[Ѳ.W�AG�4�FC�knA-o<���@�"
	��ȭ�&^�Z�w$sQ?�ٻ�ђ�=�x a���k�)�̆��J���݊R
<*1}?
v�|�ȉ�G�Ǚt�/�����%4������`�و���.�ɸ(��)��^t�O��)���ԐG,Ŕl4�QSw�J�����r����d٤+��ۂ��HN��6��Q?�FAk>�����)�K��_�)���]��|���=.4�ϑ�}��C&6��єb��CZxA�%��F��o�9DK��������0�5�����q�,ňH�z�w�?ڮ���$HX[&a��%��5v�V'���@&��0����T.-�R�A��&�ڕ�ؽ�<H�H�N�����,h��1�&���J�>!�Vʺ��Z����l��FN�oSw���H�����:��H�3�iv{�P&� �p�*�y%Hͭڜ�TX�Ԙ4@�ES2}�������o�k�'9��{�Fz� J����T�F���ŹE"ms,ZH!��ɑ���D9��;��D�Q�-<7�U�\��ĝ��2,?7�sk$�l�%����@���9t�6f��=��'�N�oJ�9��|�Ra��U5��9�������uZ������]
B�aO_�U��9ID}w��'q�V������������C��װ��!��^�G���yv�TV��5���5OG������'=�\T�G��"���1�4��1w}��_\��O0L혾�_��\��g���c����Mk&�q���#�@LheTph)I`8�����_�,y��9�O�!���+� d
�%܅d�*��P�Ă��`?�Tޏ\��|�U*�	�U^�J�Þ~�d<���
�.� ��X� \�4���ϒYn�#�uC� ��X�s�&-��=	�#�,������N��3�5�A��2y��2����OFy.rd�l��ų�Z%;i�O�(FMǩ=?����Te���@�xG>���EzZu����h��&���0����X���{u+`�M���l"����C��q}K�V�{A1*�`���TL�
��Q#V���b�%��O�if��L����g�ƨ��U�J"�ჳz].Z.c�M��Pl�njOE���y�*�����x�h-����������@�vb���O�c�*���p�Jb�\=1-mZ��cϛ5��,Z=�R�]bU�H�X�����/�N�o^ĞuL@�A���tݟ��qw^I����;pZY[���s��X>&�_�%Y��N�F�������twe�H�=�H'��u`!%Tq�_�)��<���²Ŵ�,B|�5XP5=����@��2UT��P�<$��gS�/+��; @Uԛ�h�B!����,:G��©j��VI^�(5Iszcs�� �>*}P�V*����zyAؘ�U��+w״�C#����|t^�A��)���1�>���)j8�-�Dut2��IՆ�����uh[�kz��a2���,�Nٺ�#�c��(���� )i��i�ŭ���LM@	��SJ���
+9Fq�uH���NP��!S'�P-^�AFC�^i�]Ut�p毈��~��	�mk�A�Z�D����)�G�{ƪC8�WaG�
F�'e$��q�Fw���u�&��$�h����0�Eݔ�
�x�T��_�e����ጼW���
}��h���ޝ���%�Dn|֚���ε�:/N9�L��.FQ�d!�kWN�^�vD�^��Ǡxk0ę]<@~;�ϟ��݊k�-g�6�(w�Vm��E��8�m5�t�a$�ǣ�9f�!~U����H(�;��2ˁ�cGLU��tI@9�������]U��$����c�a�@Ɠ�>�i*:5z�(>sr���όޏ���F���8xP� c�M��{�^ZZ�@g�J�J/�3�S�>v�y�݋3���1��!V#�b%WȲ��`Q�ň*�ʊ�LvV%���>�_�MԿX�S�]x���U�IŨ9�R�Ǐ/c�d^"�a;��e�Oe�8�s�G-7��^+�]�G���)Yem���яv��EŸ*�0Y����k��γM���\����D�&7ʥᤑ���@�7ܙ3��?��FM[a�����m����oȤ	���cX�E[������� ����y��n�g�R�7�1���	��Nc����sK���?��E*pZ�@��D �і��)E#��tm�WT�Kf���`\���J��>��̓୥�K�^/�#�}��S�Z��1�f=���Ch�j�#�z��E�	�Mn��7AA\�
#�����v�S���`�P]���Oo�Ϋ�H�U�0?��ë��u��J,����];c�{4��W���>�࿐:,�4�Kt3��������q�O�3`�M�r#�q�Ns̔]�:��� 9�=�q��s:oE|q����͑\l��,����%$]��g�6����#'�S��iWR�$��⸇�5�Ǥ�:�̴�B|�W�E�UF� !Q�CET"$F��ݸ���REb��1����v������֠'���/Hd�Sp�O1n	r7�.��#�?#�]6��$�Qw��6u������Oj�'��x���[P��i� �|�U��#�=��ڨ�dB}6I[I���;���2!~ �r�-�Ǎ6�%{�&sC=�V��*�5�x6���@@Zh]��įa�E�CL�0��)��.���g�i��~e�E��ZS=�=�AM�5�nA��Y���^����~G�Q(Dˬ(�a?��A`�]�hH����\�\��(=�D��{��)��S �����V%o�ɮbHw�W�%�թ���NyzL�/0S��5�t_��4!�v��9�%pP-��Э�	��l[��y�E\={?�l���PʂFg��Z����lb�\����U��xg'>�l���W"�E�H@�����qt� �9�G���KY���3�	�Hg�G���|P]���QF^r���;���{b0�F��c'yN�{�L��}�� v�J�t8-s�m̂���!�=��w��<2}�C0W�g!6�%]�I ����ǆ��GYQg�^���Z^�&H���Xo{�CGk��P���x�D>0��n�6��+VZ�I<��dĬ\[ ��D�X�%&:�����ۤ4��2�^��B���;P�T:_g`���,Bڎ���N��6��]g�6b� $�!�:��U���tw�K���G�q�E;T�oǧ��^����OQ�Ȫ�"��+u!^�1��|G@�ޠw&��KP-���p���x��P�( �R.q֙��@>ʝ���7�O�
�|�<!������} ��2|&Js�Y���<0L�m��訋�bQ'���_M4�L ^�e�7#�/��Xn�$��\����7v�)C�-!���nm,�vV�;�Hj�?MBx�;�3{(ߢ+.��`+-׷#����Y��i��ة%oʥ����"�����'��,y�1U���ñDO��z�Z]��蔲�O���ul�9�,��Єz|^�ƶ?X���Q�aʸ�.���zs�V)�Ȅ%d���5v\��?�����p��'����A"��~����(�E�
wTӝ<%���Ib��t����C���gSI��	2�]'�2[��H8���mal����&�Sb$��}?�/�j�M.��%���E>���+����ٶ�a3�[#�久�|9��Zj �n��U@^O
�R���\��|���Ĳ�r�	C1�Mp�����c*�>���D���G6�8�b�������[��#P)�U�/���M/���V����3 3��+�"�
wz�4��DD܆�_N�������"8�T�-��3�cFͰ�m':`@���_�t�Ϣ���d*1nF:�_��R�_*O��_� HE5��K�M7.ӢA�(3P���o2p�x�2û�؞>��fv�=��d9m�cH]�lQdJ��q�� �K!zus��������"M�z���y�[���ɣJ�
��m&���טn�G	z�K���g?��Ʉ��b�s�|%O���B*��tT];M��VR����:�$oF0�6�SYb��*�2_=輿w�YR���������5����#M 
	6p�*��	��:R�\0q���T�!��WZ�$�1�͆������4���Xg�T8���~aް�)�'��@�{q`·�ڊ��QdD4��&a�9��&_C���<o��
C��T���-�A�"�����~FTvt���^^\:B�ܾ�	IP�&��.*0���Ina�AԊ?[�ndc�(@^�������.c�᾵�xF֩Z��2��4tV�A/����~N>����jYXzc�x1����#<��)��
F�j_Z!�"6)L�U����0�v��C��Hp����jFwh����`}�]I �|,��8⾘&�Ej�?�R�����Jɨ���3���>9���GW��b�2;{LV��L&���&q�VkʟJ2��[f��=�����U��q6�)��w�?�����/��;�q��؍�Y3N,�����c�.��R�p��$�!EK��wrmВdò�^�x�"P��C6퇏���̀5��捤	C�u����@5-%�vk=_���J�h{�mJ��\� �o�c�t�RdrԻ�g�V�w��]+�K�R��Y{x�ױhR<fe�Ra��xo�y��o�է�l3}w���3z�ځ�����e�D��݂I�K�2$��%�6?�D	D�e�$
���HJ���g3||��v �ɬ;us�:6sD�$�:)q���3�V�/@H����`/����b9aݘSd�ٚ��A9n�; ���o����m�~¼�[��̖��á,�� |��]��R�>�p���"��(�����-��K��1����h���~�_���5��(��P�#�3�2�Fu�!�|U��LȠ�-ڨc��5`$���)�^	f���k��9��fG2���2�:Ԁ�y�?���{y���b��Z&�a/㞜@�M}�X��;!y�����CC��߃ѩV)O|Z�i�&l���"���Ws���C�afԛ�vr/+�-2�'��E5}�����5	�L�����o䒫��t2���jV*�i��O;����C�Q��>��������N���C����^�jv޵;�M��I5}�΁����*�Q�r�.��F��Vf)6J{B�����sx�8��,���ltf�n��b����:��`F6e�]��I��s��}\$p
B������	-
�L�2-���z��l��>��B��%&�N��]�4�������=������V�N�D�)��(�;��>,k�%�(P!��F���+�>^H�:x+�癔7Z�O����BQv
"��Y9�H��k��_��7�^�Jx^L:N��)d��%�\yH��>WZ4�k�!�"F��j	���>���Ȣ����85;�̓<j~�&�8T ��v�gf���im���36��1=�]<�wC����h��%.dA�J�r]���{�*�r9:�ykU�<L��yPF�Z�:�>��NP󳊇=����&i��]ɓ�U�Jr�g(G6���������^�e�������!D��(�����:w��m���Rޕ�2M�e�ǷN�!C��{�_�+qk�Im�B�T�ć���s��$8�=ȉÝ[�D��zoy��K�]��~�.NPX�Ւ�BӚo��00N��C
�ڃRF��BG���d}�H4��R��O�~ʏY��|��(F���Ɩډ15'����`%�~p�
��;�,�Ȁa@����/�w��v�>jtKXE��u׷�X�h�����O�r�p'�AL�N�akld��3��"dpǚ��GC�aWۣ�B#�#���ܚ2�4�l::R��ޓ]�̚��3�L����n�j�W���J5*��Ȫ|f<+{�z�v$�n����OO%��@1j�u�1���)�ɜ杞���+�b�Z�g�-�z�����!T�N}�p3R�֯�X�dV�D�d9�NM��d
Ѩą|O��X��=�`��[���	�p���/�h���	{�~b��w�~[d�i|cj-�}�_F��}+'l��b�5/V�ݧw�9�:|Ng�^��|�**��=������WS�Oߩ��A:t{�ڳ�F����}X��$]J���8���a|,jq���2�����r��T{-ܺf�M��)��Vo�[ဆ��8��y�/^�HS����A����������{���*c�d�H�?�1���c,ɜ�"	O�A��PFf����ŗ�� x]���+,{����X�ԣh�����O�Xؼ=�P�D`���o��R�҂������&����b�It��^*>�pl�"jΦ<Р����X��\��Q����*p~Ύ=���>:����C�<��	�JV�߸o�ᯤ,�r�|Wʷ^�yu�0�-�%Le����e�|L9ǊCO=Z�n���hx�E3�:S�c���+J�),�J�����9ۑeѕ��~���yQs��ԯT��IZCS;
�~��L���%Al�pYH�o����
����5PkO�߄�uTV��놩�A�+��Q;vb�PO�t������[��l-ڙJ���=��n�z�g����k�NPw�w���Zm�DJ$��\���J���s;H�^�X�i���Gh�0�;���%3�!���
1���P8}�+�ò��0��q6���Яk7/�+�e�%�}�����M�3ʋ�����2qn�`,���!������kZ�9$�k�BY�O�oje�O)?5 *6�N1;�ٟ�f�$�@VF} �5iy���>s��;ϧ����Byr�F�c�Z����ᗳE�z�{�R:r�sw��B8��)bk��um�m������
+��.Ӏ�-��pg�gA�B;�Z_l��n����8.Կ��	g�s:����W�U�_�����!�nrbx��L�^�Z��2Щ
�zb]�mU����1a ���-��#d�H�+����Ʃ�3<1)%h/�j�'���TÇ��Ƅ<@FB뙂�5 �=�v;����D����b<�|���
 O�{Ap����%0�bP��M��3������aʚ)��8��%́1L�K������j2�4ta0?�l��ׂ�O�N��#���H������h$C��&%`$Ja�kW��#\��<��)��#m2�7���4�leف�-]��?oA��<��KJK��4���c��VѻLT�x/T/3�ձ�H,�TÆ��U*ᙥ��2�	����0:�����
T#	�Ǎ{	�nv&�����M�ׯ*��˱�4��Å��.��Tg�� o��ܟd�8��0�j)>�E��8*�C���1[��ih��U��et �׀L}��L������SS#�2YlG)�&F ځ3ڑ&�.l����{>8��FJh2�	~���s���v�h�D\�d�w��Qʜ��|��tH�����Λ񞔷l����i�	��=�o+�~Ȗ9!ͫ/0y����
I]��@ ��L*L[G���0*&E�l�H�&�v���m�cY�Ə���:�K��e��NS��!�u nF"z��oU�j8s�
C0ﲌ���Ʈ\W��]6�u���B/Mɖ�q��/�[�M��3Q��K���d�z�� �*�U��_����jO$��
q�^I���s3�0�`���5
ҿ<��y�|�'����+aUF��;Ů�n)���=p�  x����+�0�1���#V;GYN�ût��D	��E%Mẙ��F����d���<�TGAd'��C�S��^�3���	j�bcA��Q��V�ˡMWL�X�zi�dd���g6���6�gMn�l�^�*Y��
�o�¬������T���?qAk��
�g:\�Q����n��a�~W��r�ނ�I�[������� �x�7c���̂p/�P�c8�L�f񱬪S �~��5ǂ��4)��YG��K�8�v�)�}��򝌀a�d���;��>���y�}�����GGo�C%D+�A -K)k�݊G��	j5�+�+b����W]��\�,?�e��}$6�Ƈ�_S+(Ή�� ���D�y�S�����Z�4>mM{e�-�&��[�p-�˿k�$o]�ua�.�d�\E�pkPm�)5
�~N��T#�(�3�kj1[��d��<j�7��
���Olz+�~����t�Ph.��윭���|P
�5L-�iN(K���C�C�څ�}���@;��#�k���)���j����l%11�ǒ2�#��޳ڣD�:�&�w��쪵� 8�c�pB�C�?��j��g>ƺ�R|�^��>��ER����7A��49ч�ح��������מ}��;d�+��w�K��Fs�x�:�'[��ET������:���H�9�R�,���x��u�/�<y�纜�K�jN�n��A}�Ĳ���{ѠD��ʏ��K�"���e"s%�3Z�)��L�o���l�7��tlJPe�6��I���ʖ/9��S%͇��u���-Ӎ�:M6닙M󕲔+2ڡc���i�U3��:�e���Ea܄�@��6�����K����N�:�a,o����M��L֭�v<��nW@l�^,Ɇ����/�~=3k�ݧw�O��#�2=��M�?����a� ��CA#]� �_����*��3�êC�jq����T.��C������i�2;KW�/o�Q*��;]��P�Q�@�-Ol=��z��o������?ܯ�2v�rQ*a�5"o͂n~���p�9^nk-�W�ЂC&/EK[��OΔl�2�(�nk�!Ί��@gwWiO���"9*��%�N���	�Ք8,�-��r����_M�"����a��b�\�d�yy�ʪB��l>����~�]'�$T�ò9V��T�A�&�Ų`���:bX���{�+_˲�������w����=C]7����o����q*jF��������]�NN�f���BIA���U3��e�̷'|l�H@�P��X�+GWD�*�w@N��U����TK8g��T�gX1�uק�0�M�C���@��FO��A��lU�� ��t=�,�hKͧT�L֑c�Adr�H%���j��R�d�2�4�8Ѝ�i�r�]��|j
[8��H�]Z��"�HJ<'$	���h��*�7Ұ��J:K_U6}�C!�Z͇��r[-���4GT�t)Q�w[;u|����W��g�F���˥����Y���vo���rx�f%��p������T ��df�8}M_z�IL=7|(F��/��[_�M߆��C�~XO����0:����_�4�eů�z���n����e#����U�(| ̊6DI�3����$�/�B.��� .�V��0��3iE䪵���s%T�����.rї|/Հ�g����,�l����D����=��T�oc��\w��IZ�n�����)�qȅ8x��a�����KgN>��$Нj&gy�<����Z���w)��Q��h�_�� �N��J���I�N���m�!#&x��j�|�(��Ca�j"�S0�O�@3sL�&��)n\�$>�8wg)R���=���@�&I��2���y�G)U�`q1�|نQ'�P���Uid��/��Q�0ya��q�=#z�`�T�i@�]�	�6�����P�XK;���H�����w	�rGW�h6>����
���:�;L�˜���{�Z�Ih�	#%��;�㦖%��ߝ<�rU��*f���X�s艑_1�P��d z�!Qg��e�<��$�PDy�xlNG�i�peM$3��yћ����p|�3�!���IP۠�Lg_��,r��~J���˕G���x���i� ņn��!0嶇 �%�ї��(+ɚq�{&~���d��-��ʒѡ�˝k����ь��T��!9�e��~u!,u�t�*U��9F��O�ϻu��9�?z�odf1�?T�sV!-+��B���??��қD�QK*y��mv�J�K���Ü�ǁ��7�(�Į��&� �g;��q�1�b֟Tr��S�������pv���5�E��¤ylq�_�Vq�a17W�2,����OSƇ�H��2�����p�WA�+��z�ؗ���f���Y�'PiZl���6���
��p�0�*��
_kX5��Z'�2����Ԗ9?OT�H0OnnʨI�?{bP��I-M|�]����|ң�{s�st}5��o���K ���X4��#F�F�Fh��j�t���Se����� ��į�ٍ)��ͷ�J�'A���9ACu�7x}.D"�eO
f�=`��J��R��e\��=�g	��`S��#)�b@��ʈ]D��� �i������\םEg���?ѦQ���F:��p��%�q��{Q��?3ۑ��J����Ηj�0(��@�/lb��óp��g��GT�gB��Y���N���v�V�/\ی(4�e��|��K��¶�Gn��ꝞD�+9T�E�Pu	4�J�!R޴i|�a�����-�0��+m��b�
���f�ꣀ&��;����a�V�Nx��;���7
��\��zK�2�/��DԈdߍ�S���}����B�,�q4|Ty�٢�\� ���ȉ���o����ĽkşU[Fet������iE�B!��4`
��ssJ�Q�Uh�0��+�m��nLj�W�1<���~1�4��)wŃ�� a㺎[d����zA�^�|\����w)�>b��מ$Ukc9����E2���S� �A�m�/�nS* :r�_Z/~WR6A���+š���(�/��������w(2K���@�����.{���`�P#�srJIKjD������Ӕ��}��H��h���I��?�}ឲtN���;�(���\�A]O����L]r��M�����27�>,a}q=@����Y�qC�v��D�\�C�#��kG1y7�� �6���(���d�qFxEl׸��w��٩%��'����\����uǣG=�~��*�גM�|����oV6
��\�L�P�E:N���]�Ϫ��1�P�@�\gA�Ȗ����f�NД"�Z�)U3W����%%"�.^R;q[�SA'&� ������j]����y�.0p/�A�n4j�W�u�~9OU�<t�4K���Ko����g��:20&eiJ���e�s���72��7�?[7�� �Z���f�c�J/�F
���ܡ��Z�G���U�`�W|����rRg�Y�.�3I��e�1r���s�g� i�}ѽ�)���2rx�Ǉ����*��a:`������pwr�u�φ;���l����D<R��]F��A y	G�t8�=gT��c]�QEp\��5gEƕ8�����Ƣ ����D8Y���5i+P��x������ev���"��?F��fk�Q:׵�T�O#����/��^f=�����	5:��Z/�����.�%����"��CN��8v�{��"�JwxW�J�6�*c*��/˜��
@�1�ǒ�24u5�9D>��"��|�!�?�l�T��e�Bc��4 w�i;ʉu� B�Pc��g�YQq��}��ݒ��9x4�8��+�h���fw�4�"y>���v��m�B̟���|�yr��t���)����r:Rݢ�;����]����	��*4�< ;����̈S:W l�]��x�WS�ԻDv_o��7��:Q^�V��ܛ�5��=�БK������ҋ���c�K8��`?�
���G��"spgoe���б�q�Y;6��in�ܤ((�2�,Un� P�Л�?�\��ch'�C��?u�J ��~���ME�F�z1��Z�]���Ábx���7RM��- �����cQР�p砌Z3��E�f��0N��N��.$i����g E+�2�a��"�������-��b0<-;�]I�n��6�G�;��M:�tWֻO?��(<��֝���G���I<ڦ�%rq�Ea�GH�EP�o5|�`��P��!��o��ٓ��l��B�G�HRݡ�c�6�x�Ŀc�~'�r��)SSU
D�f�8��>z��������D�Օ���[�]�j��N�]$H�n�q}���ᴸ�{7Ǚ��+��f����0�`�=݁�{�5n�[S���VT�`>O���M�:·�Ɖ�~���JMz�tN�{����eYcE��+��p��-X2�A$���] �@���SK#z��h�͋D��dщ�#;�o��HB��M*i�|�I����, z�E���}aK�4�1�W�m�����S��E!k-i���(�7$��܊ژ������"�����.�>[���s�`�M�3V���I��$s����a�oiC��nM:�A��,��WoVvJA�#S��@Jy'���ʑ�Fy�yz�C)h%��\~@�/`��ЪoO��ir
�#NBZ�c�
�\m,ZV� �3B�����~�x�茍n��`��6�9�#��y�ҟ�&���'����^`�ǤC`��D�P�R2Wl�:/pؿV����]���9�y� ;]5n��v����St�0K^M����,�!�'قĻ�����4ܑ9��v^��^�ʿY8�ۍ�����`�\�D�����Lw-�7v\�K�)�6M�����B:� ���wb�����ES�i�Q?E������rF��{�����ܦ�I��m�ލ��`MV=��>1��H�3C��?h#%��,�)*�~�x0t>���As����H#:�P�>rʙA��f��Z+K�C��ιS�uy�e����v���Ů\󝟇�����Sr6��K�A�YT�{�]-���_U�Ș��k��ԅ6
�����d&5��h%U��f�'G�i���7�A�*���iO~�M�H"��uEe/�)f��u��aS5p�9��nʠ�� ��k'0��Ĩ�+k�kWx|�fBS���0 �P 6��)�/��i�d���u$j�(B��j]8�I�ws(D�.��)q&�����%�O*k��i���h	�F=���Ԯ������I��On�2���׿��O�$�_��z�R��W��i�.:��YT��}��4�,���,S������Wޞw����s tH��G��ޅ�{{�D�5���a=�|$�X�]���P�N7P�v��+]��כ��q�	18�9�7��U	䭃�Z!��rE#�����^�~u�D�U5K,��gX2���v��pɕ�]V��3̗���8���'E�>7��SV��1�ʌ@��E��
���a���Sc3��A��q��O8}���	�	���d�9�,�nA��R��"V$FI�E�F��_[�����s�r|�mG)�]ܤU<��	cIUX��?@�8��F��VȮ� #_��c�ҝt�-B\+$�����n�d8_
ۈ}]�a��#/S��&52(��7�8�����m8w0�"o6R��-mÓU!�$�/]O����N�q���4�7w]�}A1�����DcT/�R�E��;�޵.ݚ~ws���+����j���{G�z[�fs\Q�9�@(��Y����􆅃|�V�'��7��}��Q#�����aZ%8�)�w �(�}��ơ"2�fD��C/)���P��W���ғ��Or��W�(("A�@Ca�y���g�BO�z]o���AE��Խ�A�][F1]m��zv��������_�sAgbTkBH���׿�5����LZ�7[��¨\���ڍC�'"Ne�����խ``1e�lX�C=��_k���v���i'��1Q/J:��8O�92�X)��k�{]W*�BP�`8��bm�y'���S��4�^����He�4��\���.��Ѳ�3�ֽ�W��Q�J�2�Q�[iO��/6�	%��"d#�H�j����e��z��w,�%�
=���%+�)/�6�Y�k.�l�*z���
�vydl�o��0�@|���]n�9�s��Ѧn�Lb�4����ވ&��o�5�ĚqCt��� �,��J�����<����]Sg䍫��I���ڡ���k���HĀ�娪����2�'b;��S�C�Ɠ8���'��TI�ƔGMa'���t7�R���5�Z�4rD^�j�S�+����,����^~it��TQ�L�*���v3���E����ʉ��ಚD7D����C:_#�ۘ�����J���)*X��=��`Z����U���4d�9�*�M�d3�_����XԒ��:c C��T���)􅁧Z������w��'�����2���))�CŒG�㨋�G$X�B�|�C����1A�Tw��qB`���\��V�+IrT����LV�q� _���&��M��G�T.��D���/:Α��O�t"�Q]��y��W,���D���y���K�>JT�l���TD �3D���)�����(��;�｢�t��ѓ���j�v��Ԫr("�����@g�_@�殟�Q�@�r|=p���w�C�j��SM��e]��M�Y:��F00��)څH�T\C�j����|D�|���\����D�O:bf��
<���*L���[��"Ua�_��?r}X�`���oh��>,rW-%A �+����Zϸ�iTsrUa�x}��8y�ԁ���k{��+�U��)�.��|~�Ѻ�[OlR�A�0+6����G�G|J켐_����Wo���lR
e����ׯ��-<$�P���$o'^�%*���U���ƉEŌH%�D��i�>�Jv$�+�AkU�L&�6($R���c�>Y4x}<�lϞ'��W�/9#����I�E�Ůq3��f�M�a:���q��3o��YO24���T�L��\Vٹ��R��ڎl���t����\����6�t��rv�Đ43 ��	J՟��K}�	��{�����'��,
s���~�K��=8��p�z�/�Б���T�'�N^z�n�I@ J<�wk���FM�(�(4$;'����Q�����_�����o~���0z���P7��2��UU��^��P��*��j��*�L���8I�f�X �Jչ9�u�ۂ7���p�����q�sY����MwU��w%5.]�q����&�* ���F�$sǪ�ź�{=,���0g~�{$Z��8l�F5�"밄��͙E}'D^=��Z@Su��S����	��(��|4��hcRqV��>:s��U�V��r哤���G�v�DJ`Kg%�]텫��g�gr���NU[�_�����RN��������[��O���S~�������H��]��g�f���Y� H��F3�~��X��,Y��!�P;���D�dj�Dr�������!}d�Y��
�U����oSy�����^́�����qd����ݬ�v�峇	����=���\=�$Qp�+
U���\Bc\�;_7~���e�F�Jљ5t�8�+���}�����%7�;"U ����-Q�< w���˟�3�����}I����°K���
V:��az�n�6"��:*���CxԸH�ZmR|٢<���e5F��ؕ�"��K䶺.�30�7��M��{��B�<s�2�d��Cƕ����&�)�ϞO/��q��[�+��МE&��L�J��l�7���⦕��I�,U��YO;Fп+�ގ~����}�����{���q@��״/Qݣ�`�e�~`�<�o����9���{�z�/�%�:/��,/$o����Ѯ1(v��x%�sJ�A�h�-�[�%�#������P̻-M�Ҧ�����fT]�l�%�z�S�4�1DM���C<TUmY�J�9��_���NK�3��3ڛ�Z�����~E��Rr5<B��,�~����j�>�Q�=��$�_�xS��oze��i�5_4Si��3jM�ybӪBu��O>����N(Cϊ��E������f�\����^=E>0��dYO��G��� �7���)x7�g&ŃHhߑ5��:�!�U��\z-~Q4#��)Ǝ��֋�/�u�qk5B�KfL|9E���A��gu̲�nk�GqZ<�zH&w�%���y$�zDT��GV��&�ߥ]��rl��5��R�52��@P���]e���%�����r���l,	Ns5ݸ�>|?����C��v�&�q�ūc����o���Ew�:���@�w]L2Ȝ�[vR�9������s�P��(¡�^�奡�g��b�1P���z-�Տ
�6�/L�_�HΓ�`��������=JöPGR&���~�I?��O=�h�&ܔ�G#Y���(�裸0X����L��kRX�f��$a(��ѮĎ�)�^�q�~�[���V����Ծ7b�OklC� S~�~�*mmz�O�\�k������S��o�@�U��HOڗ��N��8'x)B7(����c�yk.աt�C�jܻ����]�* ��{�C��$(C���^=��6��J��ilL�{DDs8o�������w�5$��p3Lcx�;".Gf��w!���-�T8Q9Q�_
;��?�U�%���w�Og�;�| �w�z��j����noyY�SCڊ˪9�	�����H���Tg3�(�cJD�ڽMs�����اD��@27�)ξ6*o�v���Zv�D�g���O��-����z�B����������_� ��Գ��_�f�	��w��!n̧�&8<�&����v� ]��u0�����n��P0szF��Gǹ����[���"pF�X��mȄr�wjx!uH��6�ކ�D4=�>tи�Ճ�������W���~����<{*�`��gyqk��Q����1��p8f��%y;��sִ�%Uʓ�(urI����(�?u�CDA���?0Ti&@�3 x&�Vu�N芔��"��h�a���jZ�/�ժ"y�|5�N�H�+�=J{���9��d��N�(��p��,
O�0+����RS��s+_؄α8J/4���?Z����D}LDM�le���
�AE �m����駃"M��~J�4����8=�I��H������j*�5�3���)Sc�԰N_{���2;��i���p���ɍ`���{�=�|���϶+b�Ɯ�0�6 ���US�h��i�r�
g��IV0���#݃�a	Մ?���CQ#��bK�<7�$bMⅧ+ʳz�3��Bdh��E:̚xf�7�I���*Ifo�ܘ��N$�˄��{�k��(5���/����M����_5�om�l��I2pE��[DnC�-ϛ�Q�;h��k(�fuո�?�̈�k��3\��D`.��}k����.�_�~�8ٽصFí%?���4Wu}���c�k���f�:�$�������2.��G���M]�t|�	d��b��oT\/��_���j����
+|t|�+�y5�~��m���U�t��g�	%�7*܋g}h<l���pf3�����]@0e��m�Sn|��ɦ�8S�<v\��(s���~а����|PYtx����-A��	�^X������~��!�H7�-��B�,r:+`9����atkO�������!F�	��O�B����~g��
���>)'0�;�5��ٌx�&��z]ٱU>$�Bf/�l�a�$�#3(��K�tvJ[�~�RtR�Zkw�E���]���)eM��	7#=jk��3Su�?�\ �q<��1��5KM�a�KjW����M���]�C��Mc2�Қ��Zoe�1�HJè�`Lrt�G�lr��1�\�w��39l���=��'�O�b5�6�祉?��!w����+ٞ�H�eM?�St�(�&��o!Bqqʽ��*Oh
�>:���g��kt]������(��Ӆ��^��Q#�.�(/���D
,W��x&��B�e���{���}��Y_uw��>8�������O%s��FW�]'���-�z���h�bh�Q^�I��+�` �Dy���n:Ʊ1���G�[�|�D��IMJĆ[T�Qw�9�O���������Bp<��M�QC���ㆿ�M"E2��#�գ�'T8[GձώI ]Qw�:�]'ɵ]��`�B1ˉh�M�nv[��=�׈�5��L���X��I��в`��H�@q�z�ւ��:��R(���~�l{�i�N�qަ���nY� }����ܐ`�F�g�y�mׇ�s�j����'�$=Տ-KP�`إ�vJI�S�%h"�?���ˏs���˥<�H�����gX3ہc�GPDEx�=m�\�{�����Q���dܒ��?����׬��Z��L��~�.�'GE�45%���K�1�XΌ(���>и�� ��Q�°`/�R,��a(���tі�_�Њ�Ь�.E�-7���l0�겧�<T�Q1����
\B	�:�"�ˡ�u�� �,� ԕ�^��1�0w����1�{秉켿]\(@���3�x���G(bF�A%��נA��֋���Qݜ��"^�_ŌnW�zJiW���g���p�5"�B�$��Riu�&{�P�ҹ1� 4��ɲ&��M�j���F�zA��զ�=kE�m��m5o�!{,���z�{B}�]?��ᘚ`�S2��t>�\�Y�yF*�=���~}u`ȭ���n�[f_��B��z�a_ȸ�W�;bIL�$�hY�Dn�i2p���;Y�h�C>�kᓼ0���ƒ.v�U5Z�,5���kG�e�� ��t�@F��w�o�ÿ��z���@��HA'̓jL�pvȆ���f�I؇��r��	�6�w���<Ddg�b���a�o����C�-�M��;���-!��x��# ���`R����2
�fh4B�?�	��v����O�7�+aSi��y#ݐU١	3<�����P�~�0p������Kv�R�dbE��õ�D*qX���I���]3��L����<uǬ%f9�����#��&Е�X�i1����9�y�D�� ��Cc����[u� V�z� ����O��S.��k��-���G煠�(#����$���	/��S �K<В����$vEP��)H��lq+�*�|1����㫇�����[���d��� =� *�iͱۯ)����Ơ�!)=$�@�-���U���������q��v��[��Y�����m'8����{�*��EX�=��J5\m�/2�cXI�$�1�;�ɑW�kU�9�L5a�9fԺ�f���D�k��l��{��8�O]8
��P���y�NT�����K)rb�4�;HV�w�����6K٭���)࣠�^4��#��=Ö`Oa� �R���]c��8һ��'Z˝�.������5��M|7��z�5d����!��~�������3 �lE
�����<����aﺇXO=�Q�FԈ��Ӵ�����f.[�=T&���k�]����霺������|1�ZO���Gb�1�n5�}u�[;����>o�z�ȖƱl��7t�	y�����6ɲ8�R�Rߓ�����< �>}���� �����^���PxϏD��ʑ�	'�(������F�,��pEg�����$@�H}�#�q.�S0y�+,�ϕM{���{����M.
����wP��+��  lMY�'�J ����3�'��g�    YZ