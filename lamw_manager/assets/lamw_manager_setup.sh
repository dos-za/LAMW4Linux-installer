#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2289957929"
MD5="64fca68fa3ec874881a9e01c6b351314"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26504"
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
	echo Date of packaging: Fri Feb 11 06:33:26 -03 2022
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
�7zXZ  �ִF !   �X���gF] �}��1Dd]����P�t�D���a9��SD/�Y)�z1��m\����&܂�hq�ދ��\�0��:�
�+��)�2ΝEK��|oZ;Q]�b�p ��\����'��!�6.A�ʷ�*	*�_B%�����p{R�\�9�j�4 �NIy�$jʑ�t�Y邾�x�\&��5N�Tn?Vk���T*m?��zp���-�2s�M�>��9��j��|�1U�ZF^��hvz����5TH8M+Z�%xX}K�6i�_��l<��Kq�K�fǚ2��o������ͺ���K�Ox�vN��f7;�5�ٸ�\��@s:�'�{Z��2�#��s�Vɚ*RI�T�H�[��α��A{�T�G�Al^B�k{�6�^��2�Q�����*AL�p��a-�;�͖%J,����G��*��� �z
�c�$�{*>�5�*��s�n%�r�r��ۥB�@* �i�z��e@/������l�"^�µ(��5/�<�����v\����l��f& ��S?+k�� !ry��!�tfaW�{�f��H�/���%[���d3����8�dK��BJ��yOs��_Za���@*���s��?n����'3�)Zv��� L󒎍�H��~�/xb?��l��ٷ�R�	>@�^��a0����������
!Āvh"�mz ����P%Gb̶G��>���w7偓X�I�. �\6F�`g��p�$�P��33,Y��3qΈ\⑽a�� F�Kr%��:ف��7���co�}�����v��Ss��&�& �����C�w�p���j���3�Tg�lYCǢ�$�.U݄!�_��pa�Mٌ��I�F�:,d��@�o�&��j �D���>���UiK�f7�a�;�1�O95�U����<�}������d4��8�n�p'*�|��@����X_���砦�cx��^ �u��G^����yJ���]�J�57���L��j\��� ��NqǟH��k�����A����/Եi鬧X�� �3휁�a`�,Fe>Z�V?�Ux��8d@,����(fS�-v��*��t���rS=�T����g�A5U��G1"X��#$��w���c�%D���N�����d�U�a������F��.EN��<r��('�J)�L��<V����Ad�%�h:<Eϵ�š\��6Vx��0�b�[��\�d=�B�����k��l�
��0Ѧ:<$�Y�5���
a�g���0>�<o���^R(��|�����5�,(��Zaē��2_���)���))��:��N�+��s]��5�H�M���O�u�D�C���k#s�qf�����S'���׆�w����� mXD�iShT���Xx�Z�ϭ�1�Jc��fN�����j��_-r2�� {)�Yy�g�
�|6�}T*�R��8����w�ZUXdn��f��P�x�����˱m������e@�P�z��YD�yj�A�3���3�$��q�l?<N��������5���[U�cLL4�=�]�,>~�O���+l��/�6��ʝؙ�Ⱥ7�i��`�e��}��`�ؖ��S�:��O8�ޢr�Cq2���JB�{֐�_����'KB��6�M{J��F�m�ő�M_H��А��f�_:Ɲ4��n�Q<PF~EIAPp��/ M���"�̱6?ETYH �'�!����r����G�m�e�:ηQ��?��^�],��-�,����N���T�M;\�J	;)�i'Jo^���Y�c��i��B-��M.ЮK�I�羹FdP���!,r꼕��&}%4XF�K�W���e�S9�̾��ejͷ$0b�!'����@&Q�Vw��ō ���W�P�ͳ6k u��O��]���<l85�k
������Z0���
�?����F�O�����'[Rz��Dp��L�~��h�}�ׄ߆ʱ�ߴe/�F�D��X����O*�n=�[��A���q���6i�Z���ԩ��Y�����5{	��2��V�đ�W���f�wJ˒4�L<��:�0��a�	�C:Z�NC�z�4���8M]��P�ۼ4�/?3��l�����^�P�$�1�ꞔ��R���.q��P$�p �nvĜY}Q��mUE�6�#�VJЛ؇��/��'B{��{�zyp�&o7׀��k�(ۋ1�] "�TP?�U}W�?�Y}V/6���k%��i���<U�t3 ��JA�o>���e��lɫB����Ƕd�ߓ5�"�������U\�+,�wH�R�3e���`Y�A��Kp7s��,�4�j�h��� ��v��v�U;��b���M�ڗam1s%�u���o�֯SCY�0N��	��'��'�E��<��E����S�䒞
N���&���k�`ß�1C�r|4f�N��x��l�[�&CT �7��"�
皂�G�=B���U���R[��i�M���i\[? �kv�W�{�Ή�	 (`�ݔ�e�M8&%e���ւ�	۲�
j�a!�,��Z��"l�5HM�k*w�T��Ճ�_���1Ra�@�L�A�h}t��e�Zu��VL�m�@7�B�ك���DZ��"��DA�r�¤��ʨ��U"������~�<ݓ@�b�oT��|D��θq�ݪ_��|������tx�B�h7�i��R���e��?ƕ��z��Mp0ݚ�PޘoJ� �h���9�X����}w�!Ĵ���.t I+	�{����^�%��� ����~W���{9�SH�+�Jx���d{��YGY�]�_.�y�z�@(C�7�#Ca�$�3��J�9T���%J��	��� |Χ@$˔g�`!(����`N�� �	RK4?y{��j���@N�xG��<������7d�V+�?$F�TrO�<p�=j3�>���]N�y䬂l�(ԩ���٧���bƎq��HB���<�4%�S*)Ŭ*�G�և�����:���Ô��+�{Sghm�\�C��;E��pn���b���A+�}"м}�&�(m�a�6M��7����
|G�Ʃ޺]�23� R�!IIa�)����K`f@z
��Ep�u5����Ï�x"��\w��ޱ�}�@X"�o���\��K��C¯_�_�`�Y[���9�^x5>ޭ7��+ba��Ϊ��N�YW@�� ��?�T��^�>��E<���Uq!P-؅�U:�34TÙ	'�5'@�9�O�Mr�2+W;M��9�9�J�q���f��d�)��FW5�}_P:��=����^�g�s���z��x�@�1��ݼ5��~�1�ny�g�_��a������8|��a���)�4+�pŇUd�L
{g��>�gt��M'I�V	`V�����K�]`��
�発���a�`OA8��8��#���*����`�Pi�$����,�A��=�	��i �[X#'(ŋ3ۦ�}���N걐��c��#J�v�=6���%��[?�ۖC����c;�W���d�_`�M�^"w��_�%.��|ެKqE)֩��c��ڢ2.ױ\ZY>K��ע�[Z�L�w�pP�����(���k6�K�5���?1%�Ԙ�qv��Y���+�;��A�îIj��R�>��f���ݘקT#b��|<n��<�-�'����f.�0�$�,DJ���v%�27�Q�����b�ۑ�=�᲌��W��*� �)=�R�W�U��Zi�,��[����B���p���}��)و�q=5`�$v�Q���k��$~�o��Qy����+�'c���� �?%�P��riFڎ�8e�*b���_SA���||m/Ѻ�v�\$������_�0���6�����,�}���Fs�R�U�p�Ȃ �kYUU�W	���y�+�������1���o*��^p)���k���_́ny�����7CV��q@8�OAp2[�nT�
fG��;?�O�}� 
O����UNAj�������f��.%,3��2'խ��-8��B0��6�P�~�����B+�h���9PB�Q�m���g^Y<h�E&Q��7m�T�#�yC	A�h�m���g�F'ǁ��3��Y�_U]�2e��d&$.Ts:�v,�&h��nR.��Ι\5+�v�g����<	�hz�f)Yu�9�ƥ��w�S�e��/��>�DV���j¾������t_��\|#�ٙ����2L��?�<����;I�$�]����|����읨�s$��
�/���� vB��щHc,�8E�h�x_��#�,[Xr��۝ލ�������O�D�*q�rNM��Sd�����^�~�0o�[�SUq:�B��:���'>�v���N親�{�o�7��l����Z���)�b���:���L�@t���C.vZ�"�\M��P���"E�|c���}���j�+�rAҿ���	���-�m�����pض�dy����m�i�l��چi��p�zP�vyU�Y�f��p��h��!Z-���#w�Ҧ��
��(�֯~Z-Ұ�Ȏ��%@w �uu���uCJ�v�!� j�-�!���+Y}2��۠��Ngl4�%{�V	����Ye����,��'r,@���%L�DH�1��p*iB����L�����U센��*hu"����U�|��KŁ�7G���^��/.�D�f�c7�c��Y`l�J��㋷����5���T�?�K���
�B��_�#���-����e�)9� ��.�xq��xt�(�O�#��2�"���J4*���삨'��'ݵ{\hْ &��)�n&?Ż6  ��y���c�{i��/r6�E��V ����I��)��tߗo{��1)+�ڡ����b�Y�t���S�U��i��=�o�m7���H����OϿ��\n��Ȟ�%bO��а�+ڮO�D�9����{D#��
V�b�����v���}�G>c��H8�>�9�pF�)c��a���]�8uT�-�@OaӠŪ��?�*G�%5�L7m��1�y���VQa�P|*�����s��s D��8[�ûo#�O2C����o�ji��/���Řl��R�g�dk��`R�c3�g�S�J�;;�O���I�a�i���a����t#8y2iO���3�G��n�����[�q\H�ql逕'��w��������؊t��Ž�鄸`�B��y������4g�<φ:�0/W�@��$g�½��2zv�#[�-w��_���`_�������D�>KƖ:>��aC������� ��]a�>jTk�/���o�Yi@0��Z����q6}(?�W���Ek��jY�`���(�kuIo+�=��s@��8u�7���{�A��=�A:�P��CȰߔ�]X�G��;�QVK��<}d�7C�����n��9�Y���fV3�+����T>g��?Et�8�_Z�9d8���\&�h��������L*����x�	l�b{�H�P�R�Q�^�0@T��6����������b����n�_P(J��dq(P`�ڍ�,�p�x  �����jm����3�ի�-�}�V��I�\#k|A"=��:��Vyug���R'i�ד��1�ף�ÿ煴4���լ���k����������ȇ����#�a��Ch�#�#f��bA�	Q5=^l�����_�;e�%�'��#쉘x�Wup��R
��T���؛q��IG�`�B޻cw΂/O�l�*�(U��H ���"����K��!'�X��<�`.�n�RA"�g sl�\`�����s��'ۦ�v��3��%�4�q�����kAsH}��Y{�bl���������L�,3�${�.��9��ӣ�鿻�+t{+����X9�����Y8q>�H�_�6Y�;C�ћɣ@�^�k�;#A�H�͔�݆#Za~Nvĺ͟�����{A�dXE1�r�d�3P��{H&|���G��� c�6����:z���^�B�HH�I	~6�淗؛!���D[v�Pt�MKe������o�pV !�M@�GM�_'ݝ��odX.v.<�y�Υ�p~"G���P�.�,"c坓 ��������0��Ŭ"Z�ϲ��cv��.��*,>�U���k5U��h��1Rk��p���x�h\)v��<{��?�����#�7o7ȇ7�Z�/�I7EɧPEl�GM�&�M���ǥQz�s��x�0# j9Py��W͔�>�[s���Q�{T�l�T��m�D����P���A���X�}��^�����I�/|�7[ ��i�3?�Ww�5L:��u��BSf�lf��o���DJ����q/Dh�>?ĺ�qϵ���lhY��f��9�#�D��%㷙�i����,�q:�n� 2P��3��(j�$�Yc D�c����'V�[�;�2%M/7]����0�!�E�֭ѧ���Hq@Ia%�t5��˱����j���n����;�J:�j/HP%��W��k'X�1IY��f�3ǋR0
�&o�v�I��[M�A����1 2�ݥ`9x�B����
h���?WXH���&���bֺ��U,�`���%�����hd�W��>�P�'ӳ/HH<�Xc5p3lۉ�u��4���C^l�TB�
hzq�I["��T?��ke��r�i�'��P<�� ��)��y+�X^�ܧ�3��\�z(�i���Z����r��^�=*i)��z���9����7�����-*b�rVW�*\�]=l�l���n��C`%!9-hԐOB��5n�m��~��`l��y��w��Γ)ܣ�*�$.�5��t���m^6���7� ����ï���-�)E���4�	��BE&��}"�����I5�D���*��!}	ſ�Qo3��iTjD�v���NY3^	��.V1�e���/�B$ɫ�^VV8�)�kp���q�KO�̕���٤����E�M�_ꈽ�duل�tSyS��}O=I�a����[Q2�����95t��O����ʪM4����b՟��;O��a�*M�2PCT��!�w�	���b�������V B�^��֒*V�	�R�M���I��"@�)6�NV� ٯpN9��lrsK��0��(m�U5���7_|a/��wrl&�~��_�������y�{��{��4�/��e@��OKHd�KZ��~�����g�\�����ԥ���{����� ��8O�C2Ȥ	C�u�i��}9���vy(2�w�a�\#*��q.x#n����� �ז�"�(f/�9��UO���cT�<f�J>�:jQqC���"?@��$�,rc�8:yv�4\�����9(�D:v������S���a|�L�Z���I�W�Ltߗ���W+H�cj;nP����<MpO�%�7�3����t=h���L�]J�;;�TF&����K�����#��� �Tz���k�{���(G��6 ��)cE)���M���Q1~�A76[tɵ���GE0�u�����>���y\pn`7q/�7 2# t)R�p�7@|]�0]�q�Z���V�F�(=�僚���f�X����2&bJ�	�V�,:[�Ҍ lk���k&F
��vVu=s�it/�e��8,�
!A<����"�@Ї�=��x� �i�[2O�Oگ�}������(��k]�s��6�E�cؖ����z���7���@���,����Ԧ�N�a�#*��K]�r.W�S������xt�&��Pg$���,�^�l����PC�=#�MK޶���T���6#]���(J�3YeU\^��ϰ�5ϸ�71+-I�w$�6g�"���UvN��HG��@AӲ��f��d�����#>�#oW&R�,RwCûʽ�� pt��aI3wS,>��u�Qm�bEp7D#T�^�<\���\}�����}�Y�O�'���Ve��J&2��Fn4�@��^<Rɦ��G���m�w���)�}-��_����-{CV��Ƥ�_#N&�
52�R��:;M`��.�\cI�y��E�"� r��>Ci�5��I׏1R�'�������w.OK����0��6��%ˎ���y0����$�F��&؏%k��xߙm��e
j�ǹ���LE���	�U ��6N):M{��E��4�г��ИXC'p�f�����������jJN`+P�~�}c��֞�2K⽖��0�)�@��S�!v���?f�76v~9�n��m|��=%�Z���b���� )SE[,�ཁ�Z#B����R������{�qE��m�ʖ�v���qa#i`�=s���=���GF�s`��	�HN[s.�[	���<)����H����B�1��*ΐ,T{o�0DI�ǤWd��%6&����vF7��s!�5S(���b�� $g2���o� �F�g�㘸{o�$=`r��z	��&SF���7�!ﱒ�v
�	|��tx�$��_7v\�%�
�~��>vL�G�%���Jv��_��A���!�2�i�š��S�Pv��5H��U�-@�H�.Y��v'�i�=]����7R.�c��@n��\�����2g�!qOA ��)��cm�����Ч@��\H),,�dm38~�BDN�AE����PB��=�J��ѐ�y�"n����u��3�����m݇�X���őS��bЎ_W�d"?�8"��Ǖ<��Fc�����M�VT�ݸ�b�+%�]�H�drg�A�ۢ��1+��_����a���
�b�:Q~�r���n�R�D�ܒ�@��ba����x	B̖��a���sLF��$!�
{<���ZZjX��d��_���6����L�p_3'�Ė�!h��vߦf)N�Vr.Z�$?��`g�=-��Sn����� t�qr��'z@0�6���N]2���hY�x/��RV|�����	NQ�hlvX7�G��;�wf&�7a!
6m��:�)r�)��j*׿iߔ!�zv���Zŗ>��r�]g��$���D<V:�'1�3���Јw,�i�wOlN�`�1���N�h�U=�TF��mZ:�|�SO�"T������ݕ�?*����W�M�C�:>b����n����׆�P�`��ˡF��D����+���9�[��(�3�!E�Z[ֺKq�I��\�����$�v���ғ5�T�$-��Cup��K�u�Z��0���IعV�B��^�
�6k����/Nr�Z�
U[��L� ��o
_}?%�$B;f:=ь�����T�ͺ�&
P��@�r�* �#��P\S�h8��a�������AJk��,��z��G�Pq�X��3�~a�H�ٴ���|{�#��X��ꎜ-��定E�&�Yw�m��HY�N���(�%C��>D�'�M�G)��mlX���p%/��	�qr��N]��u�%�9CB�cn��˗��F����ԞɎ�;F�t�Mo����hy�_��.�i���Əq��\Ʊ�;����34кfs�8z��"R�$՘,8���KH=���Ьz��0k�;*?��!�����C�`�6ࠍ��_�xvi�'n�#�7��Z�c���������_P���j�tA����iZ=|^q����@�Q̕߁��Q�w���{�����QM�/�K���$O
�������$j�L�$��	�fPu:	���<��l�癞Ѳ�k"�2�q�vom�O��g��Zk)]$H6�X `m���z9�J�@����퀅��}-�Zϵ2s��髀����u����]�~(ΙOs�qީ�>'1�H�y�Y���� �*B><�?4�ޜ_���9۞��8��tIm��w/��+"�l�����o9�wY�t�.��C�f�����O�r�+Erb�gmz�v!'/�dY�fu��q�"�������\�(4�8>���ޛ61��؀�+�@G���&�K����~����RM��u�����n�~�F��g�-Ֆg�浦H�o{F�CG^���;�Ϻ��=K����h�~p��Q>u8A��{
j4Oy�ođI+-�5zG�	6��Va�8*��L���t��?G�����r�VJ���9z�K�s��Z2��+�x��`�cA/r<g�aɂ��b���'ib0��0�W�X�Z�7y7��N�LD0��?.uy�ǜ�Ēp��_�v����JGuF!��')������hӷ�,�bA��̥�N�~0��m�����N��d� �w�?�C^j.uE�
����@ʟԛYS�'#g�|?8�7KLKVĎ�:�=|<X����5�����v�
?�@R`0��\�IU9�*o;�~�Qk3R|�3\-Q�ԁ�U�����1g��<�_>�w��#J�ۛ�8H�L=��H�1딀}��~����^w�Uj����ýG��Y\��,�'	$I� ���F��J�9��o4�d�W��έ2PIz'��sO�_Z*u�hX���<7RW����#������,��t�[UJ������ﰻ�}La���;Q�U9G���b|r`*����߇�� *�z!�I�r8x��M�0+g#�)V�k}<��􍥴d��N��8��ȶhs��NF(<��ۅ����p��r=`����&F*�֎���u�i���ErP!����JHe�u�T!6q���>H��i�d��wV���-
2�l�L�m�@c�Ѿ��r�q�m�8�`�~Kez�C	à�!��kl��������zE�GU�7P�����h�S-�G�X����7OA���4����}7�d��?���懞G�H�&f0X�
�涭��Ekv�W	�>4L��@M�g�x�)TO��9'����/�7(W�h��fqԼ���V�뢶 ��r?�h���`�K�$����e�� ���Z��B(�CY�|����1s���;���2�bz�U칏v���v˛��fM��^��������6���t�c�P\�K&�$�oi��}�,�ê�z)1ib��9
��k�������d���	<���=�r4�=���o���|I/cH�0#��fCs�	�A��jT:�V0W0;�:[��ﴶP�\_F����: 6��(e�2KD�}"��(�	��īw�Eerob�5��b�E�>c%lt5y*�^��؋�#b�p6B�+�F|� +"+�4��Tt�	����v_�=Ŀ�zZ��k!9&fyݰ�% ��J� [�H�mN{KxNtW�C+��js/{��1@/r��N�]:
� &��fC}ṝ��8��}�!����������C��\����I��H(I�F�7�Zs�m���Uq�����S��6Yހb�	���G�5��z��MuZ�}�c�i��U;��bR�&u�ֹڙn��s���fɇU�4�ٸ�Ⱦ1��r���&Eq��c��bF��WR�r74��� � ��Udh�+�k��e��>�"4����t��m�=5��vf$U�/�.H���������ȏ�v/˚�gT�/L.^{�Ʋ���I�U �λ㣮K��\�%p8�(�X���k���1��/�~A=Y(��2ɴ�_�ܫ�z���Ϙf���y��T�)3R���fp.Ut�(����a1A��ګ�x� �"�ƣx�d2����9Ym<���ҡ����Z{��/P�y�N�q8���sL��lLS�E �������>�A�|���,��p$����*�tW�B0Qq�	~�88mG�l�^kE;��mǲ�!N3���U�af�����8�/�!�(����{2�P�6) m����1+�E�DTur}���ǐ��T�Ug@() |��+����W�D���Ě��Z��CM7�C"^d6��I�YU�:� �휷�b�����\>�Sȗ�m��ۻ��zҏ�� \�����	�݃��z��#9�:̈�E��(�]w])�ZAq����),��$�`h~NT{�����n8&�q��M����m���\Q���$�顸��<Q�~�٢dT��h$Zx�w��]��f��W��8�Z�t9ة��X�\�B���ź�+�C��� =���D~��%g-sG��7�J����`n�+�Ŷ�.��ϱ����{ް���u�r������@�$�dr�����vm�6/����2�c��t`{�!Pxd}`���񁶈hqb�!r�@����45�U^b��MM��*�ot�p6��ː����T���D�����X��	M[���ȘU�CF.���Hlܙ�$����Jom�z�)g.��U�k�9T�b��G�츬n�R����4��X�u��H o���2�o�)�g|�����#�����$�w��ICn�����^h��ϴ��MaN7��X��I� ��RШ?c��5��c�ﱨ'�\���<q&��� Ts@����=6)���w�E��t7W��v
����0��4K�Teن�&���6.8�^����ikW��"�@Q݊��)[h"�t@᢮}�~��U@n�h�0X��nžʹ�I� �*��vs�5���؜-��iq���v���	��Y����$Z�)*�c���G�~*��?0�P�j�b�m�$�ڌ0��2����6��na�������.��?_�r�ۚ���w_x/�
z0*�v��QP�w���G��P!\(����j)?���+5�G�����|{!X���y��?�z{�6Y�L�������N���vUd�6�W����o����OI���b'�m�o��J�A����I����"�,-�Kr;X �MKn�Ne���%4�L��Y!gٿ��Y��|˿�m��ע��OSj%K�Q�7z<����1r��.�ɘTr2��{���TS����6��%��ŚIAq�f��Y�8��$:�DWu���.)g �ë��2ǎ�j	-H�������2�$���h��g
ލa�gZ�BFQ���8	_Ԋl��1��Oe$�Յ�Xhbߟ�Ѥ���^����y�A#<6�'s��?���������\(}�2���SH!�)9�uF��w�Q�LOE�xgǕʮ�Z�^p�#�[��9Ի��b.�X>���XF��q��Ϯ<�w�7(E}0c�T�E"���^�;�$�1���8�\�A�:�_:�p�ōA��$��#v6������*L�ބg	���\C#�Xe��^��?'��I7�ƻ��X�ڞ&į����#Y�f�n���]d������O$��z��ͅ�!�1��10q\ÈAg�[{���xň��.~�L�����W֐��xs-�N���0b�3E',U�ڻ�Fe�ԘE3ʦ��h���*�Z���!�k�\&�����d�3Q�}bc�RJx����%��.K�u��1�o\&�N-��z��kc&qL���?O+��?�!̤��;/ב2~u%�㟷/�l�k��V��$��2��]n�T��~c���W%x`���zV.�lI��A�K�X-����ϕ0�ľgF�r���>�n���uj�t� ��p6�W�O@)M��z���Ȇ՛�:!S����6l	Osf��k'4��j���~��D��u�b�]~R۪g��㎳�@f�M�ڝ7c��C��A�	8łd��ܸڈ/%���էmDf�O�@�*��Vz�����&L	���gfz�TC�&dI���j��
D��	|خ�H��a�ή��I+8��	P����,�5�h{��B��FKi�^��9c�e���wϻg̠����d5���=0��f]i�%AU
��_��MD�u��ҳW'Q��������8��AdE74�`�*���󢮟]_z�xPD%�syT�SJ�)��Rx�� a �JF�تd$u}���FhGQ���++u���4Q��w��6��>d��i7�Xi/_��Q���� i�C3t=}������c��M��A��3��I+����z��@}	ƒT�O�^"�!e�ϯ�BckF���z=.>X��=�#I�k�[�r�t��Mi�ԩR>��O��f�5��Y�BX=�w����
<��l0�������$����]O��;�r１���+��
�$6�ԍ�#������q>mh�lW��~�p!y�A�~$���T"C+#�Gjy�2� ����ߋ,Cy	!���������].'2i(�R���M��T�ѫ��� i��uHbY�9�c���IbX���Hf�O�!#}��OѰ�x��"r�N`N�o��f&j;Ni�ڟ����Jm$�Qj��(���T��!���3i�K�}"퐻�#�7������k�z+��<t�����A��2��KF�l�8����W�֐�}+����\�KzDR�}W�tP�c�'�Ue��2�^��AD����I/�ץ�uY�����T�ʯ�%i.U>F|ӹ�z��XF��Ǌ��<#���c��. �w��,UGt�k�jUN�u/;G��"6#`��t��r?W��k��3�:侧�mn8䰧)6��Ҷ������I�A��]D�����S����s�ɹ?4+��[r�K)��K��g��;�������Ii�M+5)ޛ�V*����7��2\;�+��[ �}�2��ܻ�فpAW�/�X�U����g��M�QS*�f�1g�MJ�4�;�:�=&`m�tg�b:�3����(d����9�7��E����m�:�|��������M|n�7GO�a�;	���@�hN>�.H�!�*5Hם��N+��8����p�:[߃���6� ���Ķ��!VR�{dN�`��X���sL~&,�y��5��<#d���!H�UGp�	�y�db�|}��p��&Ah���x�jN�t�x-3�qC���*	�>-��1��ozj�Bl�48��r~�<,.�km��@��ZxLr��m�;y�����Y"OO�S�Z�+�沇-�/�>_�m@��p��%ZU��U�?Yr��#���~T����@���m���e,oG=�K8��	�"شCٰ��[o�ˏ�퍉��U��l� ��>D���yt"��-�����kP��W����� k8Ƅ�Ү�����ʓ��w�?q6y�g�a�־��2Pc����t� �Ū��,�͵ap�'��ȃ�;|u��z"��¯�����P�hRiRj�z0���d���3ܕ�b\�i?�s6�ƾM��c����u��R��M�4���M����GQ��CR��-qN5G0�����c/S��&��98G����+�e�9e"(8��C�c�/�yy�_�p��t��HT_n@�l��ᖆ�.<�<DU��-��7�1��؍YJ��Nrg�V[�k����<���oB����%pp�Έd���_��JOp�hLh�pSZ� D����H��"�.�1_�������A����z;Y5�[����7%-)�ա����e�Voh=k+vH�ܿ[�zy�%�|�2`����
Ĩ l��yR���[q�,��7F5!7�9��`���X�u�9��ͺY���M�V��R��_")�98���DdIRҙ%K��_�����e�]�3��S���F	����;�6����Y>�Z����,MG�V��	眢�bC4:m�<���3U*��������;j�� �Փۻ_Y��/��?q;�s�6�/lL���|��<��!<P�L;,��/1�}!�=_�(l@T"�!ӎ[�P��k�mR^�D�H�wF_Ӂ���W���O�q$�&�X50޼�&�C�`�_(�.y`-\��j}|�fl��W$l�,:mNO�k��Z�����	?L5���p�r����Yq ��LA�6`��R,��|aڞ�|�4iHWL�Y0��9�eJ%Ƣ��S�+9���Q���y||��*	D-��D���?%b��w��1aЃ��c�N��sЕ�?�,����%Qv�B ��1Z?	xG�ߛq�$UUN�㑍��X�LA7��t�k~���H}1��۪F5��4�z'��ag�B ?�+�����+�et��-���
Yp���*��3k/���I�J�Q�x���m�1�"�UL�s��W�o���x-E4:�c�Q�b4{��!z*�<?��N�G�l�z�Bp{f����R*�E�5��Kُ����}Z��a�J�_�浥�aզ��b�ЀQ����g',�Mh�Q1B��5�_|���������V�qL���'ni.�A ʿz@�I�9	���Gc�ڈ.��5�OJ;�#��A>;�A����f�L�%=�r`�65�r���i�@��d�N}��tr�$�����H��,�h���^�;���廐��,,�Q�hX��Ù*���l��u�~��Hvo�#(A�ŝ�rN�H!\w��#,v�1����/�XgZ*��%p�_�9�IR�=��>�M�4�67����{!e�������g1��=�,s%���o5��kY��p�|������%*(��yu�}�X�rku)X�t���N-�v�S�!h�M�veȄX�N2M�� �`��$�A(lm,�3��D��ɔ$�����@����f<����sm�w�c��l$� ����+��D��uX��:�@�|}��u��.�B��P���P�VY���soS�1	��,��
�/r�tX^C�`�2����+��+t��$�Dȗ�VS�G��x��[,�m��<m	�
26�$m"p�W���2�z�w����G�hT��k�7k��H��꥿~(%O������=��'I$���39|�8�kCM'ݬ�(_%<��A������U��\Zq�"�ӊ֗�[-Z�הav�$а ��?��=p��dQՅ����1x><
X���|i��W*�s��=��|��
�B��ÝR+����]���z�8���C@����y�,$G�lQ�q��Jd���	UR.,�!���u9.`舵[��-��7v�^3[��@�	�ʸ�, L�J��� ,r-*�mhnJ��DW��yⶩ.�M�+
��&�Ů  #8p�P���<�<B�\W��p'���Z�X�Ǝ�+{�!����)��l�nW�%���#�t~�E�)� !/Y hs�f���6(%�����>��Mw,8�6���9�ʦQ�1�S�	"0h���.$��?�KN^�^��-�����;�, ��f�9Ÿ}Ȟ �ީ� �d��:�󼒏K`8�S��/=���@��d�W�=�:�F�X�^��S�����ζ�`?<�� aȊ��yT��:mѧ�0����*���܋�z{+p����em�.ً�hV����U��b..������s��;3 fe�Qs�!Z51ѻ�D�['���Y��[�4�)\x�� �-�]w�fH3��8���s')�-���T��D/|_����=�3��l�淅F �����^�C��0x���wě,��=5�����s7�`l��C����I�=�n��i^�t�����b�@na�\u;&6f6Av�;C�u>��TB�l"��\�Q\9�����v;����|j۶@�דqG_'���8��Yc�-��bp��%+�*r ,=	�Ի���&e�pE�;!�XI]�� %0Gzl�_�	�=^���E���N+��B��U! `ۄ|�����'Rd�E(���5��"q�3�-�8DE���+����S���`�cG�H�� ����.��&E����v�l�ժD�)3/����]�VH�Xz���[�(��9+)/p}����R$�yOSuV��B����mday��5��K�&5�f����Ł�	���+��2J�Nz7�e���?7�Ҹ<�ֲ�4�%�d��E8g��vs:MK�҃�W���Y����$�}���R�,a��h2J"4�%b���3��!�?���I��b��$~4�ḕss��%�{Bwc�:�9�I����3�ͣ��P����_* ��ҹI�xe���=�5.��Ci��'Q�rvb����}���M�r.�o����͸�����8]��H� af��n��'�d���o��^�74�?/V��}#t��j����ʵ-��~�?[a�-А���HO�3�rW?��GE8�{nWX�ݹs�!q��9�k�eN��'%���q�R�Y�;�#��UIo[j�Nnහ�1��ߔD*p����ݞ��54XKW|���>̨�*@/s	�
�]&Ќ���z��U��W��.����?��,;������▔�Po��0�n!���Ѹ%Q�a'c0�z�"�dIY9TN�,8f%:$�E}t��II%��Sh�%��!�T��tC2��F�S��A�a��F�����q�#��5���0�>�v�ik��?��_���4O��1�i�S��oD�n.��Yq
�|I��A�e�!\����`X;�S�-鷶�ȇ��f�%N�m���n�U$c~�,���QuH�b�<��x��$�S}�����*?�;3�6%��g��g�_�#�&$&_�F�h�3����r?����	�/ԑ����wtI��N�ԩw̾�-�*<��������|�(e��
֥��v1r怩��Wa\��!���i�n��)����ܾ��:�3c�61'��i/�GAK�')y�il��l���cq��U��� ��B���r��O���"����hp����s0�>���c�l����ch����*�3�V-��%�M'dT�Q[�ˤyk��~QRܔ6�Ba�|1���,�8k�~���|�4%�u.ILҨ8?X���WL�ŘǀoC��*��dKO+�ir�9<����I*�p���B����b�җ��׶�A�POGczS�@����z[]*p��-��7IzF�z��c�_n-�mJ�f-�ѾX=�*�aPB^��rx^��'hMU�WpeZ�%�+�ì�Ip��DF+� /�7}�|ql�)�����kJ�����	�#��i[̴���i?�TY)\�.z���/Qc�D�a~>v&�c_�U��2qx�?J����k$ŞQ���TW���%��+V��gPe&F?�n���ϋ���6�A�ZTݞ�����9A&��z�3Ef�����Z�%�ng�Z�,���"��N27��2R�.;����$�P������- '������I֙�3�5��X(B������������ku���q,(Z���x�&s����6��p���� T�3����,n�vj�.nTA8X#��J*� 
�q��8}����W6#�f�ɐ+��d5�5�}C�z��'���IrwO�����p*�2�Z
c-u6N�c0_�{���ٛ�sg�Mz�}?>6�ψ�8�v�y��L�J4@�5l~�,�E�}g�v@�w����"�qz 9Z�X]|� �A���L��H�9b�f!:�8 k�T��,f�t��2�B�3~p_i��k+<�C���+�T�_�˲D��Nu���q�SN�k��~���M�����K�ٖΓ@V�Us�k����ǰ�%`�������\����r� �Ϙ�X��L�M�3o�-��~끒�!��+�4����v��s��C4Ɏe�1Ǡ�9$E��.���kӲ�wv.L�j=@iY�?��r�=��NZbsy�Wax]9�;��о&�I�6w��^�x�%c���oEFǁ��l44�{�(k9��^/~�r������8�in��tEf��p�(c���O�׫���!���_��K�lp��CO�a�g��[���ۆ����I�&8["HY��X���څX�e��2��?R��S��2��>Ց� �m*w�):�t�!� ��zs����Y���:��KC_O�t��um!�Ho�'���P�1H�2V!�P��@��_�\T�CmOZ�=�t��L�:��?�g�~V)x�T��Ps;Y�s��)�#�;
	4�'�n�Y�ùyB�*�m���LX.�0i��9��4�ŉs�2�̧���gp����G�#�-���f�7�cä�A��l�V���r�u֙5��F�i̽�p����C#>蒖nϣ	����T�ǧ�@f��PcR�)บ��_J zsΜo>m��Bp[�7i�*n ;��C�4�J1�R�D��pky~���-��u1WM�@���I�}����.�{]���
�[�̑R���8��Ъe���>��EL$bo��yǂ@o*�yw�G�
kL
�@����Ip��M��d����T�qT3v
v�$����8�5�������P��b�l���Ν���A�Qch�#�X��gۍ},��%	t���轥�6�l�VgtL걟;I�!6Xx��F����g!�}GG����i(��g�ʆx�Xu�N���	:7�ӡR���k$W�ٸs���s����P=n!�YE��q���	��	SX��Zկ���3�˘���"�7�Fב�J%�����Ge��ZQ�us��f��+�f@�n�	�i�s����O<n�0@�l�n}u@��,�J��m��ۗ���G���ʽ������S6����j����S�ιdr_V����b��:��Ɨ;	���qXՕ�Jqa5ڍ�����!��Q��4���Omev���.��H�;>\��M� Pr��kojTr�G, �Vq���~�b+ǩ�:h���1ĺ�)(?�*�߮i�1R���qpx��b���q�(�����B(�0���.�?��b0�������:^� ��	�<�$n�T�����˴��˧R������tT6W�

I��SF_�d���N[.ɣq�k�a�X��W�Xym�<�ȼ���	B�/f5'��&�3o6C���NܷE�����v�ݘ+���<�VFMދr�ڨ��+%���ɵ�c>��g��X@��V��_RUF��15@\uL�e�h���h�G���ʈ"kq^�c$J/�~�J�E;�sh�'��'c ��I�����x��I�rS���:)���S�%�.�p'l�ܖ�9�Ne�GB{"Ⱦԟ���������9Q��帹;	��c#�eS�%���qq�I�;�,A�����)���r �T%��c�;����O�m�"��7�N�ӤX&��왹�̦X��Z�M�O���"�t���ka�a]��V���,��v������F��S��N^�Y+f�m���>�K����(O�m{{�,����i<�V�l���л�m�܋@�`W&��C�c�<�팏�?,����)U��1Ԍ���Z�b��jN)����:������*@ h<���$���4��*����Ϋ�
��M:Ϧ;M�����K;��ހ��>��Ls��h�Y���{F���W��{>�0��H�O׬;׻�׎Q�~��x�Ɯ� ce���(�]�5k��-��5�.X�|IenX7����i��W��ƪ�ILW��C4T���z�S�݅>��5k��%1���9H?pSul �A3zQ�&�>0P_z/�y5�_O��jp�:=A7�S��An��B�[+s�?).���Š�()&��%�x���m�8��c�(eUt�H̄^�����Dx�u0�$Kc�W�d���iO�̍����L�yԜuǠ\��PwTv�VF��A�V����	�|��J]>g�4�2Ȝ�w�!����[�.w��'�Db*>*C�YS�����'���A��M\o�(4K����su�crJ&i����T�b(����S�fD�I7��!�������H�A/)1B\�XC��F͛%w��@R]�7/Xg ���w [�8�a��&T��L
��^�h�����^E�mŇ����I�FMM#N�N\���|����I��d����B_
�ƞݘ�9G$d�"\Z=~t^�d �i� ;�R��<��E������Np5��<���ԆI�����jTq�*��}��t�LN��0�6��N&M��T49��.h�hbB�ڏͷT�pIn�.���h�}A�EO}�'+�w�	�(�����e`�`~�!��~�����>V}C�� �7f��C[,@j����&�'��W�� �ldW��E0 g:���x�����K�hE/���Z;�z+�˃h�R*�Gm�h���a�U���sk��a�|O����fqC\�5T�G3���M��}p�{$b��ʄ��xx�Q���(��_��͉� 2�~�ì�I�f�{V�4����ӈF?|��&R��"���c����֑&�ѓQ �ܒ~#��+��_�E����nxL"q�u���<>3�s��$ωn�7a�x[�u�E<���4�
r�d���E��3��n�L��Y�Zk��W�)�X�!�9&!��_��F�_g�z��`��^K�A)0�ۗ5X�k�����zH��b4�	v�d�"q��`G�Q������c����B��E��
���U,VF1�+��	p�a�p����QY��nt�B� ��;�f�e����bv��zK@�{�%�^-�����q��7�3��ĵ�F=2�����C��j+��oɜu,���0�~�sw�g�%��Ow��[�*��3�� v�0+��CĤ����|�*�@Oai����d+R^�xYL�Yk>,g2��h|�B+�h�WD=ê�!�a-�H�MFX$T����4
3~T���.Ia�n��@�W���W� �vYj�;n�.D�X*�T^�S)��"<��=���nV�Ph�5����9#�흃�"��SRҁ�}_��Z��3��v��.���n�͜�2jƭ�Z9w�pl%[	����>�^^��j)���M���p����h]�N>F9*v�vn�/c'����X�	��.}߀�4dw�?���{E�a����~�B���>KINU�K;� ��d¿�B� ��Nk�>œvB��J¹�OH4:e���\XHM�qO����u9�e�ε��j�E��M��j'�0��4H�>ӠNKv��A����B���\Q� q��AWIv���'`0�OTF���Ϫ�F{h��i�B6n�pq�Ȑ\��b}r��l�\���Dˁ���Qz5����fmH�U$Q(����m��{B�įg�=�a�j�Ԉ���Ie���q);�l�g��ߞ��dZ�V#!y�"��Jv��=�4����9	��T�)���W�o�l<ex}���,�����q,d��I9�5���&z"���m8��E��W|~�3"w�U3�vW6��|ȸ~t�V���K�՚"�xj�{�EJR��-*��QQ/���QBEFj:�	�}�&39�4��N9�����.v\u��|7�t��P�+�줨f�h�L�8��� �kH�O2r��b��,�I��*Ch����C��Enf������Pw���H3�O��}B���<1A|?CF���B��y�����o���o�fsP24Q����J+��g�l�o,����E��l�T7 H���!�~E��gߴ�7�V*��.J��E��hXl���Z��R����`X+�?�IP����@L���S',?s�'70^A �q[;�w�>#!����_��g�A��r*����$:U?�c����o��2Q5�Gߞ��l�w\/����0��JhW�pw�H���8rl�.8������� X	�
��-���B���j�9&�=��d��C�-f[�2���R���,l�V�;�pYð���0C~:����M�^��huϣ􈼁w����sy�^�0��]t^A��G���t��sC����FV�pu%K�P'�;o���w��.)	��7��u�I9c�cZ�-A����&��Ɗ�Nr�5�O��2�����m�w�i'_�%�C�NWɘ�7c	Ӊ�<�ٖ����U��ݑ���.xx�U
S�ӱVf�F�ZHϥ �4�7��e^�˕qn�.��͇��-Q����(!R#��c�y�MV���5(��"Gqy��H��.jl�${9YRG}w@���Vu����I���eI�q^�>��!����$���t�܂]5\��j79c��,�v�[�q6:+R��ù��"���S�r햯��ʒ��ƌ��b0-{����;�0ԩ���sVX5lĥ�&_��"M4��h�J@3�c��a_�g�l���,��n�P{q_���<���7��o`�'��4��e�,[T?��f�+�z ��?���w�}�q?<�G�	l�Su����N���.�����Rz��$�p��;͚!�7�:�_�$G���D�bT���{D�/��K�d�9��%#ũ��!��q��Xק�!�=�$V���	��-�C������W��h��@䲻yK�5�ݮ�J�;���{��������;�Rp2h]D�@쟇�g?6�FQ���2�W>�h@��#�Oq��q>�-�A����&@�v�˔�K["�cJ
9J�7���C��{,��&v���޴�8$Ӱ��BNmp!�u���|1q 2-H�N_�J�;G?�R��)�����c��x�C#K�z)(���H踓����r�>BّN��8Z��bo��s}��D�+1�����z�h��!'.:��l�Xw>TCs~�zn�Ch�+���E�����f�o�
�o��R|��׋�3��]µ�c�Ɖ��g�����R?�p�8;�av��7-V�s��#����\7�[O�*YPk0���`I��6�S���q)@W	�}�#1�����
�8|�����O��0���V �����>e.�x��Z����]b���q�_���L�������M���H��1�D��nL?˩µp-C���.������ϵSx�Q�V�!7� �'��qq[�MO���-�%ǌ�7W�u2���Ӌ��������+������B���u����)��sO�0V�knG�&bd-d���G�R@�`�)K�_e��~�5|��ܔ������O|�w�P� X����T`���o&�*���[J9c��@3�]���L28�
� >w2�G��q1���q
P��˔�}��y��E)���ωg�WeD9ڡ�D��'>�'v�EϢ|Ҹ��zY�^D`�K`��>������tm(��C) -杖Q�/I֝�ԛ]��R��i/���Bg��K7�yt�8�J�������e*rDW���N틣��e�]O���=k	��L8K��6��9��@��W]%���^���g�#1����*�T���8�	0�6��q(�Fh��C*VQ���ē�AL��Θ�	IR�|�S�.���z�S�dDzA�<.g�"Ԣ�6Gn^;|��s��������.�h��Ĝ�(����\Z��9H���(�����h�n�W��HeWQO�(i�Th0�~ij參1W�^���WcL���*�ˌJp����t�S�y*�A�8��
�K�D�;�RH����!�aC�-��B����_`3O}���/�D5�����������9�V�'��'Կ�Ʃ���JdO�y��/�w��Hd�!Lq��U+WS�ʊ��5�� mj#ڰ�ЫJ�z�U4����	�f&���雦)wcq�Za	�Rޟ������q�������H،��%/ӧޑd�R!������Y�G�	�ml���,����7�9�#Yр�P!���&^q����S��0B���IR�\ڲNy�n:�;D\�kQ��_{�5Of��hd��o�|A�QJ�L&�<0��iص&L���~�w!O��;�=60Q�tz!��h-��-��YӲ�ܴ��	ss�0��X>L��~X��(߉�:�4uQ�Z w����N���7NWc��H�b�K1�:s#�F��~f`![���z]�9+�<�&S6H�y�z���[����Q�P�u�����'O*�x�Ҧ����۹=�Qu¶6�=���c��osŐF�_��8����(_Mԛ��e�)a��mZ�{��草)�a�f�zHط�4�VcP�x�'zX�U����K�b��J��)p�H�(���>�DC����2�0�rv��[�P�ܔ8�()�0�1��O����k� ��c�[���Ǽ+z� ��$�{*�'Yj��do�RQ��Tt��H�ר��z�oLМ��˸a���` �´��h��9u� �P�0~�[����V��6�UI���D�a^3�}�+M>i���^#r,����PUXq��{�B~�^w�Ith�te�D�@T
`�6��T����$g,�Z�����;���s�,T��l�֔�B
.r����    �d-�/�� ����#F���g�    YZ