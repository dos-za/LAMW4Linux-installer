#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3075945267"
MD5="af6bda62cf595ed96741e1ebcde8c33a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22968"
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
	echo Date of packaging: Wed Jun 23 00:37:20 -03 2021
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
�7zXZ  �ִF !   �X����Yu] �}��1Dd]����P�t�D�r�B�:��t%��b�1 �[)��8��
��+�l��(�i�L7�B�- ���)�!�rԀ���\����y���+T�a4�y�L���Y���R��
�-�<�5�n�lx�鼑M��ڥ�M4K��g����
�a��9~������G�m٠uyu��$ǻ(�c ����(0X����G��h# pA�\+~�R�|�f�	����Lb�:s�YM ��l���Y3����pt�	f�GL�� ��\��L���c��^r@9�V���G}^
��@���1�qG��a3��P./�8� "ƞ�j"�!�[~�Q3�#�[` �I����Y��׿�kCo�;CnQ���:;��bl*b�P+O�(�h%�D�-������Y���=H�K	�����3��>;��Jh!߷d7� U59�%�_B|�bG��2���D��@�~�^g���Ng(n��=蜊2�$��U�:T2"�[nl�]A͏�dD��Ѓu�-w~��?7j��˸}�\��)6��4;���ձ�2�*-��)��nh��G������������]cڣ>�I����9���&n,l�ا�Z��hY/�FΨ���	%���ӥ��2EA(��?5������epe
���Ɨ���Z��t|�Pқٌ��q(N�����jD�:�--�r�R�����.�����d?��fG&0�8�#:���
�bn�U}�U�8�v"�$��8v"�`�B���:��ȉ��U9�d?��*a�;5���^[�w=�E���ʵ���,�AX�{�"��v1/=K@n��9ȟt�f�N(P��Vn�4������z耊%f��;/���
�r�*Y��X%�����%v99��6�!Bz�1��g��� ��ց� ���t�M����9
�O���Q)<*ĳ��7��^Ex�D�8�H�	�I�9����kt�2?�u&�y�#?)�GsT�><��XJ���J�a� �Q�D;C8M�\@ǐ>��E|̳�z'�I�d�	�-	2���B�c^��L{���O�9������sۣ-(��)�J�A��lP�h�hE���DU��Q*�X�l��I�|���]�4����>h��n�R�#j�H.h�o�-�ǲL���sdbM:E������g	c�@����t��C	����e�RY�r��=�p_i�t=GQFP9$�8�RO���=�=�f=ېb�p���(�����N����%Rh˲+Pʆ���4���8}��Z�A��g�N��c=��&�?��i�x)x�A-5���Uy���z�k�G���cXn�#E,�r�A~����/� �Imn���m׽�I*ʝ��6�ykZѩ�6���n�!�g9���N�����s����<v���GuclF��$g�P|[�%q�Mk�b�g�+��l7Z��s�M���f��J�=C*
UAvAc����gr�m9����cw��k�o�w���&����,����z #4��v(?�Dʕ�T(74���v0dpУ�9�i�
�rh6�~��C;�~��0E�[=�{<���HE���'�-v����PeĂx&��STߥ�ýA#���ꯚ���/n��� �s:(<`��<��֒A��!�+�����&���-[�A��%��_������Iu���w2N)#��,I�/i�����M\xS"��/��+���޶����b�੉�h�2٪�;S������7�'b�CQ�=rb땨v�E�W;��%6s�u�����ÔS���,Y���"+@�~:�$�Y/K`zɵ�_�p��n�+�2�f @ӎ������t4�er���U�*����I�"�s�tܫ�at��Zk\ӃcJۤ�c�ڧ�Qe��N���˹K���B��"K(�]�m�a��l���Q�yZ�Uki^Ĺ�����Ov�}����T7�����y�Y��m�(ς<j �eE}�)(I?�,�>h�6 \�@Z��|1�� _݀�!Ilb�^�H�N��-I�|�=���oH~��MoH�om�<#��^W7�<��Jb'�Ҿ�_�����ǉ��_�=$��%���c{�K�L��Q�?�ij5�������F_�x�d*X��5,
%�K4�;h�H�vv*�`�8!�(���GР6�?��ubۆz�	�w���Q��5P�Ō,l�[�~M��<^��j���c��F~�C:"�1��N��L��J���LE9o��ߟs��_;�oc�,�\fѶF#c��+t�%C��\p" P�>v��7�� ���1�w��`!�,� �K��  �(A�ټ8����D���/�}���N���h��k�r׿+^�ȣR��U�r��+J�!�;-ϸ�BM�n��WI�m]����E���2?��5��%ŀ��ݍcLI�(�?���F#��hb��`N_UO��F�'��V�$�#����^��da�N�ī�E��D���M^+��xM��Nks6����8�(�v�l0��n����g鿂05�G�q���	6O��7K�����N\.����d�Pxh�T�?��&P4���Y5�1���(�$��5�?�n@:ՠf&2��Pp>E��d��^'�EGuj��w���=|9��ou���̇U�}���I���\�5�g�d��5�-��1�M�X�M(+�#/�RÔ�&-l����Zd����(�tB*V���J��,j�	 �	�_�[`M%�l�q���o��`���4Oݍ{K�/����N�>�~V������A~`Xfo��"S9������`iĜ긃,!�ߢ�*��]����*�+?L�̎�Y�hFW\�ֈ�\���q�\˥|-����+����zy�7�*���h����OUZH�#��̋�c��p��v,�Uk9��	d��)���!3�PC?l�ûF(,��pNeno�q���IA����'�d��6�����q0]|@�7���(�!ޯ�	�I;Rl���e4�YAĎS�nl��C���S�@�p+�'�!�!?�8��b��3��y7V���]���5|�nx#��	g����b@�M9�t�ǯ����x�m������Px 7�ӝ��$pb�C��S�T��/Dy��J�X+��NLCǽ�a幪��[
��,3 H=P:��pb};�fۼ׺Y!�z�Y��G{����﮵�U&�fw��[�ᎇ�rv��8��:�.�@_�y�8bkJ��B��}�V�L��Ɩ��^��GȞ���G��䛀�����h'��#q����:\�`
�-�Z��u��]�ó_�kn���$�|N,�+}Mh�(�Y6�`�cjrj<��Ά^�v:�vD��E�}�+Tu���T�Vթ�_���4y���@�..70��V��=ӚM���A� �!%��=�x���e���ejFИ�z|2��}���3��zu ���̓
�B	Y&p���|�C!w�[��H^ְ���TI&���t�fE6|��o�oMP�d�y/�H��3��-�^y'
I������.��,×��N�)1U���J��D���/ﺟ��e�9�̶FU���C��|�v76�?�9A��S�q}%�>h�<����`;/�`�CP���7����,��F잶��9)[`��lN
��{�ъ�V����O(���}f��/ż�d�������7 /�~i�p ``Sv�����կ�F!��$R��\I�c�{�e�%c��S��r��� �t,�Z��Eo�S�C�=rIG����ӿV�:$'\�]��O�(��`�U�h�w��ݐ�=�"c^ھd�������-��U�W�T�3����!�'�M�W����b�r" ����������v�����H�S�:,��:d�R80�R���W�uQ}5�<Ù�tm�%����嬜yb�sx�r��P1_ J/��t��n�g���B��>�$j�4w�=!&�����5��dz�t�x�&��Q���j�*�	zՕ,�G�f"����/̀Pm⽞U�����MD�~�0H��'������7��"&2���-G��G�m���l��C�):��^������+�.��>c��G9U*��Lƶe��v�l�^4o�3��������֭p�E��Ll�2I&�=�l���m/*��	�3τ���6]��k����2H)�3���e���ė�����/�WH���X�Bj=1�����H>�﶐4?ӕޘڿ��L�d4H��m��rb�V"�&$�<�����?5 ;S�� =e�����nJ�
���(yTVAۇ�2��]!�W�("��?!�=o�u�2��/������]�\�_l���L����=�������GX�5�C$�?�\��1��E�t�H
	~��J*y��5?b�Z�j��p��
�|�Q!�}���o�qW�o�L|�,n��q���陎�v�ϔ����;��v�~�3ڀv�Q�����a��/���܋)�r8��!HJ�ǳT�b�&�����-k���_�'��k����ށ<�$?�����{�\@ٷ] ��5oB7��*�$l�?:k�s�2E��A�V�l�h{2���=�X��P_ME���T{U�T�mp��X�?�s�B�-ah4í:�����U�Hr�9�"�u�(�mLc�ǙPx��}T&��ͫk瀽�/�r�fu�zӣ�jl\`]��1�N�Ä ͢j��|�g��k�/��n�e$����p�U������P��X�w��>������߮�_f*��mρ�/1|��.s�k^+;�lf�y��S̫=�K�����>�4
	�m��`[��qQ�0��jO������ho��ߐd:���ny��Gl.��)U��rw�z|�K������ibkr�5h�]��ܑ	�k�'�ě�PI�lH����v�!l�̔c�Gݚ5�|r�L_JI�I���u�wk۫�������u�F M7��<J)��V(�uĆ�ٗ0�Ah6�_�AR�!��^bQ'tE�h�c���\xa@�p, �'��k˂���2O=�*�#��Nxڑ)�[���H�Ƚ�O�/�n�ebM�o�ћp�̡(w�[�ک(P�s�<.;�L	�+t���r	6�H$/���]p�`�WɿX4O� ؤ�������>T��e#b��rP3��1�i�'�Sބ�-���hK*�\Ҳ�2�ӳ�Ր\�:�wB��4鼗��QX�6��ݎ��/-t��;��� ^`I�N᯺��P- ]�K]Ȅ�3�W��+���J�L�5V��?�ݶH��O�P���򛌿�ߛ�>TD��y>zs�;�xN|���<|�H���j��!x�J��FZ��P��X6��*�'��&�p&�ǁ��NL�'7S�f�z�LUĈh^��}z!�Y�c*z����h�C��z�Rx`�5�^��6�����0zY�$P"@4�_��'���������n1*C�)M�����y�!��K�~wh�m�U������.��c[]at�+��AxՅ�f��j��!��`����a*[�݃��MO]}R��	�Qv0��9w�N}�$zƙy⃺�sBF�9v��0p{��
��p�;�ޖ�<��qꊍ��@;(W���B���t̊�{�l��i���mt9���^Ҳ�G��k�ጜ"�����~�� #�%H>lrJ�Sb�5�*#�������4W�W�
kJ�X�ⴀp����nģ���Ħ�rz��3��.l�bGVb�rǜ�Zޤ�I�����e�h���[?�G�fӪ1�ʱ���Rzwws`�g��d��׃z�3z[�9٫*�w�������j���)H��N��Vw�1�y�`}/[��� !B�$Pj4�Q��eU�m�
޸ ��������C�\���9��%�_�/��(<�Gs�p|P^���AvQe�O���
>���
�Q��h�F�����Ew��A�8}L���M�`Wa��g{[W���Մ���F�@q�/	���2w�,(-yz6j�-}��� �㱉��+�1Y�-���k|�O�&a�0~�kU�n+$�BYښRzHaV��7�^�h��hUuzݚ咽73���Y�$� ��O�c�����Ѝ��Ô���<�[����wTH�z��1{���,BCV.�403i�G��\��֔�󖹞s�*��90����F��Z�U�mt�Bp;�:���40E�q�v�����R�'���L1���9$!E�m��М�g��t���4jO�[{qpZ��͎$F���D��Y���J�>&�/'Ϙ�;vp'5���䍶�����彞�QV�mj�j/'��T¨�LzYq��x���yTR�J�E$��CZvR��/��?�2Az���n.e����і�I�I�r9��܈	s�C3�W�Gme�?�:姸��I)9�ʝ��o��v*�>�|ě�d���Il/L�-f�6�]��$��Bbi\NF)|\�&��S��*�0��q4�g�E����/�&�$��A� ��y���G�⸅Q���I��ř���ٻA�3��:���F�ZT��.�¬�3��Tq���� �Yځ�I�I .;��wj�{�~dT�xD_�1�uC� �]�H7V����zg75�L���==��X�JC�S��踰a�C�����ҳ[P�� �f���؇*�G&��P��ٔ.I�BI���|Zj��[Ě���p�jv�(E�BG-��C+E.(EGI[��J�{*�|Z ��zy��0��=K,"~ak��(��}7��L� ����B��26>> �ն�خ�#7�B_�p!�y0m�k��a�
����aE�\$��&b#���Xgh�U�M�3���Ƨ�'�=���m���JoO��������)�oe��>���ލ|�םL!�\U��Jyyו�����G[�g���h�m$>4����Z�2���L��7hj(��>ʝż����;^�J׬�h�R�����P=���x��M`^�q�:cW�ov��ij�C�(|��Q��zd�))�FkF�%b��H*<�h�b|� ^�0�W<�@yZ>��',}���%v�07����/���W<!+�$ �Ȗ�2��I���G3� �����8�JE���ŭ(w�sY�5��zE��r�'{lr�?����X�j�jU?w�FO� �R�݋�c�p��l������P�n�֞;U�i.2$�L/�{���a��撆c�[����0{�=|ك�N���
���}��yd����#b�@e���ZLB������`9����pS�)��ݲ.�hBZƦ���6[	�f��r(Hhwf��(;~���P\��i��b��zD�,;O8q�����ͳ���t��!bE������D
/������������ ��NR�2��l�xߥ9�����jW~�� � ���z++e�lo]Q�|{�1�tk��P���q���\��|����s�3G�ǒ;	��o"A5G�/��^��uxGH�ε���1�:���Eu',ӄ(i�J���&/�BN��X4'
6�Ჿ�#F9��i*{9Eޅ���+Y�T�[�$�f*|�>0�ft!��{�]7�����m>��qqcDT�2����1���:>|�o�p�@��q�3S:��3!����p��w�XU�K6�Z�vo�����FQ�J�5i}v�^Z�N���&	�D���LX����~֍C:����
����e ��6��=�x�_a1-F���&�O��bdul;>u�#m��s�}#
���p�7�ƧǏ�PI~8���u�B���ar�b���M��Y]���3���a�{�i�=����k�Z����H�i�x4��V �..���J=��<5A.��e�T�b�x�UFxQ���U
iF���a���6����2�rM�vLw�F#!F��8PC�;ު�6�6���e����Q*�.�~�N3�f�0���wq�����2i�m�� �x���_OD�Y����O�W�u���ˁ]��BH�U0��
f��S�}��	u_�(P�[�r0]s`2��f�3ގEӋ*Nka���a�s���x��3H`�C��aV�2K��u���#'8��I�V�7�t�4��eN@{
E���|�4��c�3\�p�B���)7�ՠ2��f6[��h� ���ls�j��w���3���;4/�D��HX�4B���#T�'ڀ���sQ�W��-��G��*���̣�K�Z��89rr&�ЃrX��t0˟ry���%I5�����?�>��{�-��{ND) 
�]��qʸ7��0��r��:(�?@2+��O{�F�N�ܳZ�H�u�u��:����m�`Q[��D���c����G����߫���]��6ІjWN��r�@Q�����k�w{P��|ѫA������qB��5�O��~�P�Q:���7�H�yD�F��}sN�\SX@	���\:\��.�5+`��َ��C`5�Z�ߎo����0�w�w�#�`�S��:$J`5 �:�ҿ^��#(���\|�)ɜ�z�%�|�J�-�������n(c
ƣ?�j�3n�O��| �6H\����	���3�Ꞡ�j�WQ o�%F�$C��D�֦Jݻu��R�ciIOe�FY�ģib��G��-����5�m����C��ó,��
�v�i_`���e��[����`�1����\���k�3�A,�:���a���k��C��"j^�����7�i������֮�t�Po|�}��
��Z37[�"�=�K<|m�!�?M�k�)|��Lsִ��F���>]�F��?ob���K>�=�e4�����B��thyB�-�XT�s��Z�l3�~�W����<���M���V�:��0��x��Sy��t�>bu0n���߱aiR�L�GI	�^��Q��m-ޜ��9^`3=�Hc�A�#Ő-�2��+��̊����c���Z�"��2"�򽳞���������rw%e�s=n���!��h�Ϣw0�c�>�mL��ڀ�eDC���jE���7 o;�d���*�51|��h�m4��h;&�&i�Î�+�'|bY���� �t��������G�A�h�A63�YL��e�?;�d�ܫ��o�Kq��|m���������Ia��pH����@7ws��r寁,\NʄE��:�E�
�8�Em}Te2�ZDdܙ5�}�G���Q,�{�w��V��Us�A{\z~>/�s�t�H��֗ Ąv)U(s���L���N�=SQ#/~��Z-��Kȟ�O�囱.�U���8�V8�&_P�����C�ʋ9E:^���W��4��}W�)�8�}�M�V���rѦi�GA-�ZHǽ�^[Im�ƉG �|ա"iK^���D�Ⱦ����N��+G��#�/��Mz�N�A�-mcm+�f��o���l~��Rm�C��y�T��)��ؕ�� U��L�ﳦ�.�U����=;����@���pJ+�:=�P�B]��_}�!s�e�,OPdg�j8�K,�EMcK�A��ԗLf�#�Tr��sQ�!{!k;�X}����S?N z���C�1��`٪�ܯzG��F]�`�?[���M7ח�\#��э+~//�Q�x����g��l� �k4�ܛa��1�.��R|�:��ݬ	>#��&达����]��G-p�8%2���b����eC_�
�a���z�B�}bn��=grE��T�<o�ȠݏQl��.��\X��D����7"�� ��+�
��R����k��� ��P47�5(�aޚB ���&8��P�ɣ(���깄f;tC�=K�%V���e�Ԣm����+˱�N�67� ��t-�݄���@��v�m�I#qyP��~~#�|=+mCZ�0�e4?�rf���<is��l@����������:���~����w�� �#5%��l�	�����v:���`P�����h��Q����/����J��6�+��������F������X.Y UGx���]�Zq����[P��t4��Q��.�p�u���C��:D#�=�O=yl�O_ Li߽�I�x��+r�\�V@b<�׮N�B��v0�c)��gk.�;�2��G�?�-�������c9��:���9��Q<�*��I��l�gB̫/M�r�%����V'7��s���@��Ф�����S�� �Yh��3��������GQ �ӯ\&a��x�eBru֣W	�k�
q��?�%��[	�)�WhS3��n�D�:M�{��nuv�5k�B�N��$��wRO!B�f�oY���ޅ�L<��c|�C���6].�-g�����T����ܰ�*�6P�O*�~z 6�~a	CKи*\��hI���L�ڢ�GtN�q�~�Is�j[����o���7��5X��"94��D����`##g��"�}�N3#��($]4�L���WV��Z�k�D�n�q�b�U��WZ��������䅈nk�����s��H=�i�\�?��Bl8�b5�ڦ��zo
F��u��R���#�� 2I��ϟ�p�4'��GČ���Ŏ�3���������w�8o*�:��ȓwF�P�d���{���Q�i�A_��<1����=Ht� K��[%����v��G�K�ý�`��Y9*ǸW���\�{W��luՇ�4xխ��uQ>c�kj@B�Wؘ����r��W�5�W��W��3
'"�M�v�w��B���Q���GO��NՀ�sFl��9��*�j	@���r��
��^$�����o�0�E_A�f�)�w�f�M�?$���yt$6�$�nQ�lm�di~lM{�I��<¢�;��iEeg�������c��
�H=������#��'^DB��	��V�y-U�	
�u�>�:��
����_5�$��ڊ_��0��m:����~��[5n��\�Gc�8���N�x/ �{��+��!�v�;s�������hh�9�G���z�du̾�����q+8H��F����.��P��v��U�V�%V��U��4�rM�+c����>���Mb�����yz^�0hLqj� aU�� ?���Im�f��4=e�S�	�,Z+�2��������jv�_�cv}Q�S*Y��}<0�FbèJ�ʵ���4G�_�YY4���VN� G�Ȓ�}=3�S3�G��5��9�e����OM#�:�՗�NX?��+t�~*ᣑ�ǅ�t9X��Ş���h�ս'y��R�������i�WeՇO�yg ̭�W��K�ױ�i��lf�t����}5*���p�e�ο������v_�0F�
.��\ �*�dP���m�75�ߝ�\�trx��u���%��̎�4�qؐ�������/�K��yΎB������S(�v�l���PK�� �P�IGS�!��ǐ#����'V�09���o���ߝ	F��1Pp̜�k�hU@~��1y�����;�9R����� �����N���$7*�/���_�n'M���y-X7�)�`�[αL~P�d(�@| �������9�'we4�_\G�-�����r٥۸���� zj� X���+-����@IA6Ӷ��k�O�LjBu��8U�w����>�>?Y/�6;�|�=W�QGo��B�߅�!�镯�1d�t6d�%rE������dڦ��O�dko-\�@��_�b�e���S8p1�0zK�:$6�(e��%1�1��m�b\Z�k	(3�p����s��K��.�>p���VE�'ܳ[�؂�g'D)�I�c��b�o�b�x���%�G�Jȅ=�����Z�G��_��*2!���xS=�@�L&>�'�9�Cу�q@B��ܵs�.(��͔gѨI�[d.I�4�:�y�.l��_���s+��
�����-���ǢX��^���lf�@3�+���|�P�jQ�JH�12�.4���B�6�e���K��5��5i&?uf։�b�ǗU�	N����K�Tї�E����A�	|n��|*��O�m7n�dk34[�h�V+I��RX��Y�sH��|搠�g�_�����P������_�g�E��h�]�}�E"3��-��{���O�j��ƥ�{�(���CG�V)�M{��`_�48��'̡��D�wZ�O�0BC��TH
�Rg�cPD�~�� W����"��2D��t�o(�%�<<dP�"��"~O /��P�j�s\?�0��:xm?1�
|K���4*5�+�C�#2-�kÀ�ٞ�K�q�]㫸-�����!���6�{��Ъ�5/K�c�����.�&��wQ�U˽J�ږ0����[����`u8�����<H�s'�jY��d{��V��FTK`ÃH� !�lN4�꙳n�Bmm��d4�8G@:%�Xoi؀.���Pj{��],��A+�.��`4���c��� �g
�7d+�xS��/M���B%�B�$�(I�:,A���_�����Ҳ
����E�j7P�R$	�����%�T�;��5M��}�8׎ihN�̷�-j�����8%q=z1݄M���OX:���#�\��&��$
�P)d�f9�Kp�?�4����c��Hزҥ�j�@3&�MG1�X��$����g�����������HU�3TG���,�W��f�pFu3�n�Ma��1r�i���sD�����k�d�H���������>7똰U<��î����p+y�K�L(��I!?6��c���
�	;M�|���V^dY]��6pSB��GD_�� �G�hg�>R~"YV+��D�"c]rNK^������H� �	���([�;�|����{��(��&N�,���C���6 �Mζ�εV��zX�h��q hE�5&q��� Pf<���^��( �1o[��V�I���U[1q>�������:3j�@{��\��3@>Խ�G�~aQO�t���=HD<Z�k�Q�?!���k�E�%[�1��Ҁ@��S̟D4��4gn��u�d��B&���I�:�j���K�4K��5��a	`��R�o�:໭�am���5��y"����5"x8M39�*�ݟ��RY�r�O�0�3&����g�����I^30������;њ�P����#k�Z�Usx��ۥ�l���~A�O���	$��i�RW���3��Rʘ�n�qX�fV:ob�B:RaL�E��쇰.ƴb�  U� ������R�h��
+,�o��v ��``�
mUngN�	N�׶��CJ��u�P�bCJ-�L����Y�+%�l����d�����N�1�_enL��<J�y��C�*�G��^��ϊ>Z�^`���<f���BĎD^�r�kx툍�AR!�zd;=�"�M��.��x�c;!�l�mZ��qS��	���� ��k�{7���aai|M6�j3�f/�Ů�$I��!-K�ag��~���H��B��h6�| �\�cS�<�U�����&���`J�w6~�L�]��Ô�2+s֔wl83z�y���exg%��<-�;r����We-\ʦ��f{��s�P�Y�ǳo���~�E/p�[͌���ĺ57�?��z��`���
�&.�t�g������^E���.2=��S������&-�jo���݂x\���ݯ!S��N!�e�ϒ��*�ۡ��@V
C�q��g�i���4��o�3�?;=��ts��`��tË/���z��ʺ��k̓LM.'m��� ��o<��f1�5s��<f�Cj��Цu��玊"�7�6�N�u]�1�mS�,�N�!� ��%}+l�e����1�b��u>-����L� ��I�>�ɨ�ٳ���,o�kA��mP*�`�n0�Ť�-�#3��x�����{xk��W�"E S�}�����}̻CoY��Vl�u�c.���H�H	8�naĚ	���5��g|9��]�=�j�%��y���CɿJF�����7�r�̂�������ַh�}���[��+{�#�����4h��8�eK裶l�oQ'r��f��7��W���1�����φ�TQ�0rx��~�9ҙ���^��*�ӕ���	�+�y� TH�
����z3��=�kˣ_�����OVHؑ��#ꕪ�I�Lq��a��r�/�5"=@�_�m��㱷��˞�#b���&זUp��m��/��O12���BM����~�R�8K�]��=�^" l���f�u�A���{���591��D�R.N8E �7�F�tG>�r�`.���C�З��BAk���J����'�P��c�ÄH��Q�����{K��谸umq�+͂��@N�� ���$��g
�R/ە�BE`t��o�#C��/c�K�~cI�u�K�S/Ok% �-.VF^�*�%L�cO	��8�<5,��LH��~��ԣ��j�f�
������@v���������n����VFJ�tNoJ�������[u��t13�I࿵��Ǖ θ/��VB�����"�;����K�Ⱥ�/aK{�3�� ;���uo|�S/�-�0	#Q?~͗m�8�o|3b0KTK)zv�p��	�2�Vc�x�@�v?��2�X�Q�X����*ׅ���H�l
�4>�p�X�NI6��(t����J���᫻ێ<ʊ���DB}�4h+Bܛ�`	ٟ>�o�@4P�f�C�Z��DoB	��#RX9�a<p�����`��$z�c�h��%�]H&:���N��1n�̑ky6"����t~�ؖU
rR�2W4�l�����c��ϕ͏�����6^��l��T�Iݠ!ж�V���w���W�[��:��W��P�����"Yqֺ]�d/X�\�5Vf��5�������q������(���qh.t���&\s\Z���TP�?
.�@�[�����ස�[�r�� ��d��s�>�S�~]�o�_-Ex-����At�X|�J%}��BE�H�zw9E�'����?�Hj��Ǫ���\/:�.��Ӹ��Z���{w:��VZ��g�g~F����)W�h���jnÓ4`�1����#O�h�v�AqV=ر��*(�i.�9р�Uy����2�]nf6�U��c$���3��s����p��TD�f�3Qi�l	����`�"�Yն�G*깁�T�l��,��9��]=jPR��Eףͮwre*���k"^g��&����:�ϸ�������2SY��GLO�{(�m�����D���6E:=Ȁ�V�����gi\���j�7{IgʊE�+?�/�1��W�Iˑ��c��rIh�o�=�xǨBn@��Z�G�$�CV���Mc� ɮ�תּ��XU/�JS����j6@n����A)�7P�i+��E�p��S��@R$��^h�c������E�A�W�Ȅx�m#�6Sv�-��r:;�q��8��D;[,mj0`�i�D�&mB�I���B^qct��ʲ����Y*]��I~�Pq�:3�V�'h�5s��]Ǘ��6����ZōܼGP��(�x�(�,��^N��F�r@����ҡ����b��gf��Z��E`?Yo�-��`H��OEV�� "��4\իrܩXY�X R�b7���!�P��T�`��[�2�m�-)7���|��ѧ�r��9�{zً*�X��r�[��R�F�Ss�������T!�e�6�'�4���e|���Gl�:)�	��&��T*l���k��QB�h���`,��f*(tr�lڜ)�qzٸ㯊�T�|����f����g��͎��@B*H���r?�6d�
���ԣ� f� $3���"Γʰ}U�R���i�	M�FB��G(xj�>��g���ϽeD%��*�����YG�R-v�'���>a �%g������^�jm�K��Zb�R��X���H��ZA��_�Ԅ
�2|�H���V+�K����s�t��f����@���i�$�HQ���D�F̓����e)u:�/�t���0���˪���6�ޛ'�L��+N�)�1�7Y������ C����X���ڄ�l;	UO��Ϗ�u��R/���dd+h�	��hj�!���oO�}�^�x�x|�k�cyI��~T>��ֆRW��I}Rr2�}n䓢h�0�m���ȧ ?���.�-��^�2ym��"������8^�F����Ǿ�
[;�Y�M��
|N�"&/��*$%�9<���-�s^.�N�z��_�$�=�"ye�`v�Th7�Rz��l���WaSF��.Pd�t�Co�@�k^M�|�Uv΄������.1x��+��N��2щ&��.;a����C�����ê�2^���e��'"�K5���!��kj�
��crr���t�^o�c�����Tؘ�^�y������S����TljaA�1_ޕmLp�y �?��$!*�'8��#�\w|��E@�`��s%�7�)qU��&C4T�\Pk�� ��~��"^����#�)�L��R*�.�%R��H�]���v
�ck�sUa�ʑ���kҦm ��ȐI'��m>j�Z N��J����E3����p^��`W���l_�5��[=���Ӝ%>dt	�Y� �����ה���<�o�����2+�d ��!�Ĩ��F�`��s-�27qn�Q޸I0=ƚnl
��hŁ�����[2�.k
"
�"�#���:4�%e�ǟ��q�>Iۖ�	h ��Â�����$Q93�T�C��&�K$+Ҋ� 3��GЫ�'����-����9DUd;>��n�)�d��Sm"x��򬛧�X��8|F|Ì[�����u���{���U1�EG+�[��h*�c$�mZ�A�O�Q�JX��X��f@��`������|V10uN�\�s��eр[��R�'G�OQ��ٔ�1PQ��o!�xJ?Ӂ�їȰ�ؽ4��|��R�	�.��K����_��O��0�&G)K� �����OW0�Yˠ��R0Q�Y�������ķs�� F=��y���S��x)q���JxE/�L�o���e����Ҟx�`�B��xi�5\7o��d���_����;x��{���o�.a���?5�]H!3h���S���5�v*����k�3���폰�e��=���е�z�-S-:�?3�}ʠ�����D���X�b�"�<c��#��~��q����po�}��k'�����A�W��ьE��]�ҥ������N�%��c�"k\�W�T�{��$�B�G�<�I���	�)�5����6�w�P� O����Xg�茚(�+6�[�(�Ft��H�����0�� �����	?���69p�4;� [v<�7�?���k�j�D�R! ��Ih W
̫R���Vcg©sȐ���"%�Y͕{Ca(�݌���)���;x�\���ʬ�����a��K5,�V�N\�	 r)U���>B��&�:�����y�J2؞w*�����׺�Q�{@l��n����]m�x�m�"�`s�l����_�q��Rm���[��S%vޱ˾�B���-�Ab�E"��	��a�~��INқ���(��Y�D1�z�f���\��^���z���Fn��38��L��N���S��:T��������Q�3.�3�D`4W�TC��_)U�N��emJة�\���f�:��W�W|}v���+���Zo����N�P&$�)t�����D�A��Ze�u�T��n�J�1Ϊ��a@�����jr΄q��&u���1*�ƶ�t�t��ƻ���'�5��|�䇮�g���1|�r�տ�LGIj+8[���^\/JR��a��Ns=`�ƴ�C����+곍H�y�N�R���ڰ<>�u�'��ݏa4Kj�5��fN��M�#��T��]fdvX�d҃5w�x	�}���,E�{�^��ߪ�~��6��:�؟��I��"`��
��ί�{O�չ��P����Y_@��S��%_�5cg�-��P~&�����IS��Z�;yT��\;�-e�����ч�nz6�M{�.�z���%u��t-qC�v-��6���i3k����rZ�Z���3y��8w&�$�����a�����0k�P��N��cb���%��������� ��'Q� j�ũ�	����c:�N�s-� -5�l��t�[LDt��p�y�=�꥛�������e�N"2�ێ�45ܢyN���zd�+��H��S5)�����Y8�j~r����4�S��RzyZ�_:��1Ʃ%&eQ�c����~~4�l(@���^D�,>����ȕ��6��X��:�+�>=��7�I/��*��~��m�k~o@sƢ�i�m��QTW^�e ^�N���Bq��?���->H�>o��]�!N�fyb�����҅�&6�� �~4H���<����E�(؏*ߓ�/�$C*��()r���iē����%�-e�	Ae`�y_�S�s�|�.�e� ���!N{S�~�VÁ��iS"龤�Ď�L��}���������=�����TA��^��$i.%�+y�8LX܏�x��o�] ��L#85μt�Ao���1����m�`�ƃ)v汊;{:���U��V��ӌ��p�yIK��ߠ�fN���Y�HRkP�(��P���\Hw�%PZ��2w�h��Yc�؎�@�P=Ϻ-d�q.۝�(�<\з,u�/��-�"�I0�#��5�q�Llsv%O�%	eLe�� �@�O6�D"H\~>���#|j�:���y{�6ϮSܬ#�a��R֯�s�����{��(3�� lkg�k&;}�_�c�B����ϸ����s#Z��6�I$SZ0�D�P���!Hk5���`�]��/���p��۵��G�K��Ơ{i��8�����K�	�*c���8%��dTΉP��IB��%g�%
'����O����R������{�N5��V\�x"�~��(d?I�Ϙ�j��_���$x���&u�?)���Ғ�*�PA��}@E�6�5a�*:��+�Lԕ��9���<�HD�
��c�����q�-��g
���+��Gv*���vrަL�n�Y�T�go�j4}s��L6�N];��*B�hS��Mb0,H����=Q�ٿ�6���kʬ��`��P�
H&���xt^ �Z����j�^��N��̇z|�Q�®���q�5���|�h�Y��^�2��)�*qF�yQ��z���Vjp�����-c��~��s(#�XHM�pPJ�riEb_qL�ŷC`?(r�ȓ��� g:]�b�oǝ
��h�P_*��բC]���yO
>�>$'�!��o��������Ϫ,ˉQ�M��Dp�ˈ��Q�C
����'�G�_d`�7���+!�V�T�a��% �uSB�:lV{�/�6?�U�z�
�6�� ^w������X�3����5�gv��|A[�'5�~���m˞�"�W��A�VM���Or	Q�1�&2;�8	S�H0z'�o����ބ'��9,�nL1Qu'3�J��l�E4"#���|C6�p���Kj&�f�j��Ї�,S20��G�I��V��7��g[�5�t��P��4��$t�M��=Q[�ж]KǴ#�~F+���y
�|~�j|]�����2E;���઒�n��KWۉą�$F�v�υ������:����v���W	z<�Be����xt�A��Q�it�v�m�	Ґ�Ny@j�T�쇌��k�W&�%��tNe�+yD�X��&�M�ۧ:�k<��=$�N�"dgM��8M�	��PƜ|B�xq���\��鴰��#�<)7������q��K�Օb\�
r8K�m����t�6�#f���5h\��bQ�ٛ~���7/��6r.��m(jC��Ŭ�0)��S�zV�� <�hw�ɞ���{3��&��,��`�O�G�L�|7J���m�p0�g��L"���7A�L��q�W�Iu�GHq�Qr���>3�����$�̏����?�oTv?p]a��LmT�A������J��^{���+F/�	��+���L��(P�Q��k��V��`�Ŕ��V�+��u.�c��D�a���4:�o
{l�%@v�?z����%�c^�-ee����ivDQ�E I��4j��7S�~'�ݛ�<���͛E�/�$P,ko�G���`���L'��c#�/���~)nD�ub�r��4�7IG��NkҜ:�_�*��=_L3�-���=��ZK�%-�Y� t��T����g�eKdR|��_xz�ji�Z��D�-���+�����2�W+��-�G�ѝ.U�(��;�]����}��x��H6��&?��K�s��l�ruj��f"ǲ���Ż�H��(���������Y��<�W.h���Q�Hi�5eܴ.�[N��‟��D]����f��-D��d�]���*��"^^� �k�=��^�|1h�N�f�>����[a�V����h̉����lg}y؇02���&�xQ����1[F�>x[竈`�QW���6�*y-Xc�NKv�"�B"!ڨ�E���n_��Ϫ��,���=`�m;6�p�B�/�-���5�Uq0�&h�N�TR8��Ou�,���3S�]��י���t؍el'����T؏��{�{]yX /�v;\4��ņ��u�y��B�&�n�v*m�Qژ�{`U%�������vS�̘��;3�6����dލn*��	�Ǭ_��ޕ�`�6�e[�������~��3C�S����l9{�G���ð�"��L�p�yơ�ѴN6P��O�	II3�R�����X2��$D��sRA]N�x����ڔ�V?�;��:��n�}J_��DߋP�=g��s�e��G�(��8|�V�:������T`��E�+BE���Cy:�2����K���C\�120c]�|�8f��9^r!�|��HD�O_����}2B���	߆6�F�#��.�a��vާ��$-�	W��5�ê�XV�c֔ZټuF�Ŝ�����5^���(J��z�&�S�J�r�NBaa/M9��xDw�~�v�e].�B����0c *�[�:I/W,4��2ų�i:W�������Ǔ~�b
a6٢�a��Zh�Wu��!(?H)����{d;&k-���mqQ;��s2��]��Nx��Q�߷�����)}	M�$4�����>����y yId�uS����標�r�7h�m6��d��Mzf8���U +iY�>~��Y��6%n]N?$�Y�q�~(���|��|Ek�q,\Js!���K��W2X^ޙ�p�d���	�/�Ű˭��f/!�zKH
Qj�(M���'��\V?լ�ꢽ>Ϊ���]I!�N�8&�RB>,��~�!�ۧs"s��#G����I���@�<�E݂�D�7�����ު��������	��P~x����[i���������A\˥��.��k�5�i��6��:��e�~p3CRK�����N����#/����,c��F;ϩ<X���6�C�ӎ��q��LxMc2A��H�K$+)�	K�&~�?�(����H1Ǭ�kR��qW�<�z9Y[2�!K�)h6NQ��{��������).Ac-�g�g���|@3�~���x{�/xd",�QT���m̑�/��������.���Om�Jfw7_2kayd��|jf�r���+��B��&�XwI�`�^�,�+䧁�5ߵ��Rh�p�ͺ��#�G%���XXO�����E��1Q��}}<�P��K�8����e' �0{�q���$IJ�D,�_�0{&��C�� c�\��7��&�*7�?{��_R�b�B�h,G���3i�-�����6wZĘ�y;7����т�ъ�f���v����@^*�L�uP�|B6R�k��!�G���]�iI��	!�9N3���JQW:�NK/L�d���`�<� ��hR��� �������p����Ԕ�M͍s7�QdSa��ਫ਼8*�1P�S�ku_���E��8������	.�Ȑ#���dL�
��,Y	nƟyD��n�����?��q]���i}s�a���]��N-p~��},�t��$K}hop^A\�Mp���G�q�f�O�j�#���>q��M#ӈ3�n/�<��H
�}�@�f�+���<Z���§�O�Ҋbj8a4��ܧ�X����e�ed�n����B��l�	���ٌ�P�=l�Ev���Iqp��aW�W$��Y�49)�K���!�څ�W���CЫ� ��o���
g�8û5Q�ۆq N#	hM,-,�O�}9;k���(�ûb:(5�#2��A�H��.�Q`��51tzA�5����9�����C�Ӭ4�y�s�Ue
��P]���V�myԄ�ّ�2����j�{�n���t(�w�}tU%�u���Yn��8ô4�f�a`	���a�wi��L�%4E�$�Q��(����F�\� 	#�9�"A�`Z�#k�@������FEv��"����V���on˥?-8t$�X�f�Y���gv�5{df�o�Y�O�1��B>��'�=Ԑ���J>ͫ�?]��e&��lI6WO'���z��YN�W���<�v4X���(�?ɍ     ��5 �� �����]N��g�    YZ