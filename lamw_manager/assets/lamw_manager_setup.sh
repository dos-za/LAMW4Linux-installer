#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3812588643"
MD5="6ba942cb55160f683da54aab6bc4e7a0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24024"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 24 18:06:42 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����]�] �}��1Dd]����P�t�D�$�=���v��4��c��еn���z��v���z�UJ|���s�h������/h�6eɸ[ˊiD.�� ��iK�9�Ux��N�@�q7���+���C1�L��}���o��\F��v�>�Lλ�x12��֦�KL�I���wCE�y�Q�8�nS����������x$�4��o�%�쑏[��kk�d�fQ�I;�y��}#خ����]��2��˘���:'�zَ��jkX=a��_�x�i�q2E����"|Ȉ�N�@jj݃@B���֡j�i���mF|�3Eh/����	E+�1/J�o9}���Z8o�V9@�{u>���(�ܫ��y�LC������Y�+}i�6���*��lb�H��ĝ�Xa�7ϥ��d,��7��*u7p���tY������<ݫ��F���	��b�J�ؚ|�����cPz?ץ�Hj|����9H��S�\</������sO֦�0��U��|q�rӔ6��{���5�4�]Z��x7����1�}�͙���-�&�6��6dX^��X�~�7��U��9-R��FK� ָ�j"���'���T7$[/���ă�x���J���-��=�&��K_�x�,����E����.`b��dߑC϶�&�"�h��0�y��f0�~R�37�W�d�hփ����@�����%L|x�N�jV�	�'k�m+�29W�?�I�琶�57���}��$��_N��z*�����c�����u���М<zb��(!����s�ң�~w?ȇh�}�69%|�#G�����U�P�q50�̸�4��1���<A���Y k��Ǖ�!ez�@��f�w-u�j]��B.�p.(6C@ȩ�>}���~�w�����[
D��e�s�n�|�^�7�ջn~7챂z}��)�K $T���ޙ��������6	�� h�ˑ�e<�wf4��ɚ-K~k�s}]��am���<���*�O&]c��z�Z�O�]*,�"s������A+��!H���������}ʁϿ_���.A�HCh�ɦ�2��sw�F�K}&$�l����n|��-���ۃ]���]�Z�^�x�i�}0��9��S��]���3���IZРB���n�����9i�a
�o�����npH���VUvPl�<�Iw�]���y�fFF�W��-�����{K2�ȗ��j�wM5��:����V�]9���cGtcu1� ��,�$��(d+�<x��;既�L�L�)����鈠v3=Sv w�3@ŕ�c��7�G��=�[u��>E�@�+Ũ�U��QP�{O�&����r�"8v�o�D��j|f/�錽Q���	���X����|9L�CHY�Z�9����}�Ѹ/�M��ϻ�VD�<z��*�*h���"�%M ���ح��|1>@����mr8��Tl\٠�,礱��5�jn���|�v��V
��d9�֨0�FkP�x�{\�?+;󉝭}i5�0�~P���o�� ����G7D��&Ŧ���3}��,�]p��C*+��s�>T!��Q��b?�G�����ʩ�QH�m����_�gg��N���;Aг=�wh�4-!#q��q�q�1���i�/�g���.`t����>�}�w8	3�& �83k?���-����1g<X�jW�d�#,�nX��Y��uP�� ���a��Hq�>PO\�c}�������}5ah6V"�ٞi����=��m���z|�	�ksJ/k���$�B�!���}�^Y�P5�)(M�v:�u�B]�,l?0�d��w`��xZܴL�%>��I.Y�'��N���Ŧ�45���E��9����j�ŶE
�׀���7pr�0�̔ч�R�.�@!��?AP_(CCS��Y�΂����eU!(���$e����q�w�Ix>
�+�N���_4�t%��S��Z�-��u^�P�j(.+c��-�m���6Q$*�U9�|���9b�- ��/��r�y`k�~�����b��)�*�E^��>�����=_Ipv���RƐ) \X�4%�	֯L���*�4�oC�{<p���~i����*�O?�����>�D���2T�H*��Z���O�e[`�nU��U��pu0��.�~Ps��%Æ��%8�r-��d�Pa�������M�R���ʾK���a�$�-�7Nۑq\��%�r��E���W<z����n=p������yć�w-v�O�'h�v�\��ZP�۪8�W��@X77����0��������+��i�5�f�nq�2�?p�T\��i�w�����8�q`�1��Ⱦ}M��%M����z��&�Z���^�:;ɬB��ӼmI�����-}�����p�O�(�)�6�n���X�y�B����w��O:�{��f.��	f����u1��X�5��q�c��/��i��֖.QP��|�.T��V���0��܍�Ϗ�k���׹�N��>�_S�j���D�Q'���H}��	;4gv�ۏR�/��)��_&��
\sU�D:�/��#7̼-c�{���թ������ؘ���/��X��Z@��xM�;�;4���4�/�w��J��$�`)h�6�G1���X@BFLe������t�b�8F�{� o`"3^�����i�'U9�@l��|$߯;����G�"�XQ��"��=}{t]�0s^A_� �2��
�ɩ��U)���ȶ�q��ƫ�~<"͉D�i�k�%\�� ��R���,��&8�R\�PM�Y�h�u	)bj2�NM�9���]�d��VoaT?}%̐��#?7$���AbQ��r� ��Z����\�� ���c��C���ڜh|UQQhZ!�->���>�7��k��xQ�]�9� �*^S�����~.��'��b���#�6�NNoM7OO��B���'��C�Bl�+�%y����pX�B���l��ֺ���|���0c.���l�6�[ư7�q,�R0�g�&�3v�,l��� BC����'��_�ס̐�".!
�z�F=���:��{ͩ��0�DS�tt]�ݫ��o�oV��8���㌩+��欏8\�F���l�.�	�Hכ� W��}�>vbkz=JO�`� ��o$\?��l��8���&x��.��7��'�� ���h5��BD>ݝ�K�-����"��*�j���w�Y�{��x7p���bԂ�4��!g�;.P$\��X�+��
�c�!���v0E]�
�!��k�/e�x �������$3~�#F6�!�#��'`k$�k8�U5K�xX1J*xHs�����d�'���Ska>Z�>�u4G��O��gI�����F��D�[�n q���WKz��L�,9Z��߼{�j�f=�jL1s(>��z)$��2z�@r��LWû��M; �];�K���'�u��j-�͛���ʺ�{����l��)�'};��X���K{F���� �Q��1@B4���j��iqR�I�As�fz,:�=	����S�	��������)}Qo�=~�I�p������5��0O�a��1r̘e��j���U�G�.�`��k��+9��O'a;)=�-Yf���3@M�4>Ǡb�ٚ7s3O��E��Z�4:�
������W=��X[r��.Z��i����㩺�w��9��n���_b�e����Ц��Z��´�m�o*�}� |SBMZ���$Kj�t��^���pŘ��7��cZ��3��\�{c�������Jt�8�|l2�	Q��2J,Qwd��O�MPV��� ��+�ls9Fmu��M�����ڡv����ܬ�[����Σ�>�)���0�,��(+���g]���ԭ�=�;`LbA�rz����7�O�ܴ��	�����O����\0���vn˶ ��^h8��?x(��]��J�������@-u�φ{e̞��a*�6�
f[�H	��_K���!(��${�Z���i\sܔ�?M� �j������]38�I�-GD��N�k��`��0���s��(�l>��"/L��y�:ܛ��)2�	@���c�r���,i�XA �~��� 4��V��~%��)����P�L���q4�kt���,_�x���{�\���Wf�C]U�E�C����dm
Z�Mv�=���>����_���¢i]�XH�Uؘ��W���Ʒ������`��W����c�CUV>�Ҭ����<s7Y�����S1�*�wCq���B�x%�&�lw�Ҭ����+ٖ�yN�s<�hB���m1�U}S�� �����X瓌�&��B �>П�����@�D&&�4��˨
���_'�T1N�r<���4��Xi�����Ɗ`��ň^g�C��ϓo�X����Iy�i����E1��W؄Z���.�������]�BB�]��}��K+�ꊓEd!ʰ[��",.hB���H�K��I�75�`���I�	���S� �Z�Tq`\l�1V픊�P���b�޴I@Y�	�{�ND�,)����1E}3T�GY��~V}���s3�����v��ȝ��B��q����+U
U�w�9�N�����C4��-����=�u���SZپ.�,�ć
�J��>�T� ����g;d��{n��yC�9�v��k��E��=U�� j��B�i��rb�6��t�_2��9W�D_?F���=�}�x$4��BdI$�e'l��c)�/(��3���>*ߓ��{Ŝ:�Ӑo��U�(�塛;�6:�<���tj�~�̒J�KtU\OK��.J���prp`3p�į���tWgx j���A8Eh�1���m�]�דY5s\���`;���l5�����e������qB��7��PPӹZ��5�C�䡽�3�,��]L�-Td���z�VI��|VW�feX�㙟��6TzL�\�<������p&������l@�B<�`��)?S�����o���� 3
�.#�g�Nt/ꔧ�Ù�^��(��_ۈ�BBO�Ss޼@�
q��	�d &OTC���?;�cp1���Bζ�~%�6MG���r��]���l�݀.<:Ȅٕ%��h� ;��{�;�HAIwD50�8oJ�>H`�H��SRы��Qɞ���Qj,�S�(XGk�lYV��U�:�t�O!ެ�jJǎ�����}��d�I	yk3~��7F@L���ƻW��#���c����&5�K�u�3�FN��P*��KfO�~eό�8�.������ƕ㛱��|�\����@<G�2r�y������ >�-��,ͬA�{/�\su��j.i�^�����&`�j��;���(�͚�h��{�U�B�/2�=�毈�ev(��{��&!Q�a{Gp$�q��OR�8>^�{ЗB��v���t&x���b�v�f�lx��/���;�k��`<a����B��2�Gqϥ�9����+�c\��``юM1 &g���0��h~����	/�\��k���놁]�X�˵����������m���x7��z_v^\Ї���>�4�7�Fo�	��b�.������Z���RͶUq�x��=dWc��k�i�k[I�f��a��y�ti��+R��9��.���U�Y�}�}�+�}�=�fd�r����$r���
�=�D����"a(���9����B[{A�[CkCP�OO�U&�ve+$�ujc��.h���Y�7�.�\�2� u�*��&j�!pS{�~��ǧ�XN���(��9��{���U�Ƞ&�VW� ɦ���r�qߗ ���������i���,;��d��c�ݸ�dV?=S~���)���-�x5���H��l�p�v ����_���R��yF�T<00,=�KH�G��W百J�>�['Φ�q��\ X�1��To�#��jm����Y���p�ٴ�u� ưL���;��5O*�1 �ir���r�6����tx�yJ(�gÿЬ*�ʂ`�]�E�9'=^��l�)m�XL,O黢F���R�[¿܈��u9�$k#�Z��`%7�A��٘2罓�����C��2��>�ޯ�M�m�K|,��0
P���3�,�[�8��+�=�]N%Q�*���2O���1���>��z��y~��Ԕ�?��r�_Ϩ���o�I�M�l��ZUzY5>� ����I�ӌ7�i2���t�p�M/*i���-�/�Q"f��{��|�]L{Kv����D��"�Ax��p�/��X�U�\��b=�ό�溄M�*=!������YmGƛG�r���kS:�k�̞�H���PS�&�ų�����*������tR���Y�*���50��Vp~t��\�aO'�;*;���]Gf'��,���`��ࢨ8����`$��.em� SV�v�^��I�iLU]Jќ�^a�>�;����+�4������/hZBEXRytx+O�kj6~�:O� ��:�f����S��i*z
�#7������5�逕%	�����������K%�|�9�ud�m�xL��Ne���د��Zo.Cx
��<��!��9��i�7��Q0���ѥ���3�\1�:��%�N_���A�޸�ao�z�QM�)��:J�:��i|Ԝ*r��y�@Tu�X�����g O_C�"8^ApD5}<��x���zI�b��gN�w�"�m\R��]��1ݜx�ce�����#�[���i6f�v�IK�L�Ч�,9��'��l��)��d_)�1|�����,q
܆��l�;�������v�bMp�k�[��ɟY��*�������0�c���@�����%��:�[
q�^@x�&����v�qM۸��38� �Iwkm�<�
�'N%��::@�"����L��$.Z��8b?���+���S2���j�\�����4�M})$�����
��(�V����C8�YW���������b � �� �G0~懧�����p�԰j[t��I��=%]f���`s�v3�����h������g��/՚{��L�iev$��$�hQ���u]~CZ#��ʇԁ7w�2���5��1*�OI�34C%�+88�u@p}�h���ב�gN��j/�7�n�{��Vd2�L�{owt��Rt��THp�}��$�+'$�# &�f��3-�C,��M�6�_��%@fMB�������#��h7��৐����=����x��֣*r-���61}�0������L=ܤ���u����9��04��j�e�c��^w3Bӭ��u�ہ87�z]���`5�J��f�݌�d^a�3s�
�!��V\�3��>ŀ&-�~_-G��s6�ტr�NX$سɨ�:��?�E���_��˸�P
�3{`��#0{Ѿ��g���tkٞ�!`�.�W�^�|:��u��)�����N����7��|x���S���U��,���Ao�#��r��m�ױ��(Iʀo��$i<r'y�y�g�(ߍ�S%�1���,���_�"e䱍��N��Q�<����E�oN���o���5��{��^�XX�$��3INR7M^
�ղqW
�󲆊1�ބ�m�J]�Z�Lk��v�f� ���J���_�Øk;�J��c����	�����4���i9,��I�p���=r\շ��cˆo����ʒ�}�O44���{ǚOj��cBlL� ��}>UNہ����Gr�$��UWP�zs3̹_rɸ�=�jN��˻�iIܕi.z��vGg�����hh̉��w#�RN�&m%jI�f^�9&:�L�u���|O��_7>�  S�w����q�$�v%u~��)�GG����m#Uv1,К�PfR^����/c5�_���g�+#��eA�Nh�f��`�(�W��=C]�ie��nZ1�=�'?�J#��#�gяq�o�=`��|�NM�K	֧�H�j�b�!��ϙ�/�#�*wP��i|h���q�R�D��mC�����R�3I�r��}h6*p1�8���P�y���������窱��*��^��<k��Ob�F�W�s傳g!��4�l]����<.R�r�=lS��UP���b/"����%���k��'R�=�����.�z�^٘v	Ad�L��>I�S�Z#�����.qV��P�p�p�c�0���a�X|A���vm�f?GT�6A�>j� ��H�X�����i��7��Ѯq����i-����3��Խ�Bj	�I�>�ͅ���L�Z�[� +>w�_���U ��W�)���4Oz�p��[�|L�%-.����G$/P��e����I� ����"��[���pq��|b�맶�2ڭ�翵���pXe<8K����b����T:�X1CV-�hѣ���H >�)��X����h�PBRP<�m{i	I3Ky����&.CJǳ����5g����J`�w���t�ˢ�G�`�Q���sD�1�c��_�!����s^�tK[X��S�T�!���}x��$���?A��zL��%(�ۄm"n!�69��[��&5m�^;��!B%c���L�v6e��J�l��7��J����qb-y���{as�%eJ�Ibt�wwaSu�%�&d�����LZz���]����KsL��l�X����G�*�K�ʸ$�`3N��kJ�� ��reXd�����t�f�LƟ�`���Z�.����&���U���l����(���M��M�a�N��0	�s��>z�![dIԭg�n���3����r�g0ڠ�)�S೶������H��or?���*q���Y�l �9]~'�;�\|Al��?���qh�C0�2+�)�1^)�y�����A߉�g#}��:�a	�m՛#�iB����nV�H�^֡����6lB��0爜�r(��?��BkA�S���E�R��=����
�z�$tE�B~�oDH�Z-i���Q��:,N.����Zɗ���4��im!8|�&L*:�3f1V��U�Ē(y�g��ڲyy�l�)u����	׊�9Y_��	<=>��p�����lkOJ�z�,��l^�9;�޵�"�'��_нUU��YZ@���܍�0%_i�T�,R�M�m3n��"�/�t����'��^�S3g1�v4�f�gֳ<W=���⿨\�3=zb�"vǑ�=��5�����^�}��#�Mc��֙H��!�$V5J���-L�EA�$�,2�����8���ϒ�I��H����2]��a"�CUj�}�V���+��n�@����BIk]�`l (ft�2�v;�O���8����f��#�<��K�i�� Yw�<�=ی5��2��U/:M�����Kc�X�X�o��!�4����@?�l�'�mA{vP�"I Q"��]��1�޹��c�+��]�3d�0S���9������9I(cn�詆H�?���Nl���)���6Q�GsS��#p�P��&��Sa��sq+/?t����K�>s�A��G��Hf9*a86����Pfi7/I�\��$P�cc|��L��a��z�'�&�w�=����W>/��=��}�Qys�ݵ���i9ц�kF�^���\dt"���"�qp���h�V���^�Mж$�w���8*K8��؝;y a�&��)�P�����ڝ$�4�!�������֛U�M�(A��]Ɂ���`BKj5\�w�׽��  &̽3�3gd�D|݊�uF���% =1��yx�t��,��o*[5R�6+~��W�=i��Yn/XS~���L�z�����,9Qgc�ڞ	M��D�}��0�(�|��X"���4�M��F�o4ц� 8a�o��7�G�~�m����z �F��|
@��[ѳ��<�E�_.���W����:S����:4���MbG�=y͗�/�NY�����6��-� �fn���H #>]2������M�{/��7���2:N�H����@?/;I)6u�7Rt6>	yaʒS�1�0K�*��R���9��*�!����r`�SPJ1*��8�[���R!+|�%U،%W|l�_�}Nq��s��_��d�03aa)�l�d,��ާeeJV�����BR&��w=H8��,uZ8vE�*��M~�|
Ň��Ħ9:��iK�:Ym�Q�p6��N�W��a��9��C�I@�Q�z$��o(�D����G��9���8�5��]vEVt)r6�?�ѡp�Nco�>�]S�Z�QP�f]��Mxd5�_�6�	���/��r�^����x��컽)�#Y����P�A~�n��x�W�	��-��"���r��D��>bg��?'Lf�B��~���	)[�ޫ��7b �eI�q ,����ts�ƛ	Ir��EԿ�y[��,���Y��1��O�"���
��¿`c�����4I����j��L�:���&dv9�u(r,:DkP�~L�\E4��oF���Y��Y���?�o������U2A�e!��~��2��4]8x��7J��@�Ǹ��͔����:9*s*��77�R�Mz�OZ��-θ
�냹��CӖ��=Z�� �x$�q��Bn�۶IC�>��)_�B�t��w��� ���%�g�/ �B��~�y�� �z��Դ\�\�����]�xbԊO�%�*�Oks--rA�[�,��a$��"qm��Op���iRY�n�/���L�5�@��1��7E��0�sp�}
�[qʔ:����*=Ȓ�fb��i�=x��ڞ��Q��  u��@:&Sm��Ԫ�Bb6�Og�,)���)t}u��n���o��}�#=��6�ҐD�]@�	��ѩv�����Y����MW�{�WHyv�#e��p?�c�pC�u*�2�-"N��Q��I��@vU��O���U�?�G>��8r����:���@�r~Vh�	� k�]A��bK"�2#,�2_���1%���ܱ�26;�(�9^��S$⚧�H08-1��#Lfkw���
�4�F1,���ӏ��Uy79��>�YA�B��fǚ�'����D S���y׏����!^��n�r�1�z��9��$�~`�ې�~nՈ<�+�(�S9�4�n�������sp�IcF=�J�^zLA���S�<���$}{�}	}+I�ec#�Tl���	�$l��I�HE�ؠ7��wf~���GU�'8��%�3d�����G�f4Ĭ�b�#f*D\ޱ(�9�{�X��['��6|�I���d���V/�G�"�i:������u;S�:��K뮰=BPB�xD��0Ԯl�YL�+���Y�rJg\��]��wڦ�GeO+18:Nn�U�g������F	Ns��z�T���o������TvK�_1$q�R�Ps�N���Q��eB%��?C�����š�h9��D���24!����ID�N1�l�������M���[�$���Jx��qPUc*O�n�z�2�E�h�XRlc��F����(��ߥz*w.�k�VU�L1�#�I�%�W\��
�����J����;�$�;�#��� O�|D`a�
���;R7P�[����<gx}Y�F1
�e��^����	��T�CIJ�)�R�Qw������Qm{�p�� M�BN����0��l��C����	������1�;�n�S����΂�$B�'\�xS+�=C.���x�n%����B�Yy�yj�*S �a;L�(��72&������m�1�4Y����@����\A�{�@f�8ރ��"t��X�xA,�`���:)�������߻R�~K#�}�qz��+���l��taK��|�A&���O%�7�Md�:|��K)fUֈU�G�/h��؏6(9xʨ��� ��/A�ĸ�n_��|O���R9�-?�_Æ\Ub�bDb��U|�9���]Ae-@&TIT:l�����z���Ҡ4*�V!��P�Ar~>dR�b���N��8,^��i~��T?�9�j���l����D�J�ҫݓP�H��*���0$��IP��>�GG�U�4 "�����ʵ ��|j��MM�ڄ����c
a(|�H��F�F��m�\"�J����J����`���P��	țV��1L ks�k�܌΅a�@,�A��f )�:7�����O4]?Nxp�	wpq���� ��es�L)Yp��;V��U�:(��}���*��BT��C`�	��@�*4fo_@�~��C����zj$]��d:/��o��K/�.?��b�����u���B��Y�IXiG�������+��>��#3,��uV��p߽7ݬ�0J�fef��n�ai��B�2rP�VT7�?Qg�Qf�j�%H�3��0�(1b�$�#w'H{�U|���D�W6�z�s�a���vn��k� q���;x��j7���F4��K��8�z��O�	?uk�i���~Y�������6ݲ��O��c�-8�JJl���*��~H�A��>򊑷+�R�[®Z@��2���� y<��8��9i�S1�9<���^iQU��;Ma�<t����?q��-���.a��+~�4R/�J����At"|k8�����7 0J>n3I;^c�u$]u< ����^�Pb�&��������t|ebX�JL'r*тz�6m	�>�Wb��;���rCB�vڞ�x��lX��&�n(��Z�.�_�Kn��Nt(��ܠ�u�V�Q��̀m̨Oo5⦫z����g �I�ͳߗ�$濒Wy�Z�QLg��'K���4e�N5��7�/�����1p��]�/A	
ʽ�W���'��,��f]Ss�P�c�F)��{�7����7򓆫�mnK��er[Y~���_CuR|m�������|v;�[=��'ƫ��<�
�}�K2��/|SW@���W!Z�/I8u7G� ǾVX�X��n\�$�L�@���!c�J�g�Sv�u�������",7�:�pv�G�A���<)��D��h9 �mhõ&-[$Y�_���O1%�F��n�9�׹`��of3.e�q0S=O�a8�R�����G.�v1PC��ݑyA횟p�({GM��a�'#�fRc��A� `�}���Z��z��5b��]E��5���%���jkbo���]�����XB��&ߴ��j���U./�T��d�m�W��zBA�2�u�t@J��-5E`g���2�Gy��E���Z�"'z-��U���Y)[�x����$���8g�;����j7��d��M����;���*���	�N�Cf6��7�JoN��8 ��@��:D�nM{�X�w�
V��1� >>^�����ࠗ�1/[�� ׏U���]Xw_"��Ǎ��HT����W���C�ŏ��!M* _8������B��c$�)����҇�����&i�ʫ��㽜������}i'���%�ws[�����3g��5#G{>��%����Q��V������=��1�G����z�y,��5�}k+ʖ�!.�m�yh��l�&n`�S4�v+�?`YE㮝�����F��	�1('�`�˭5d�M��dF	#Y�����=H��*͊�N��E���b8f=�nϙ�R���_��>Ѷu�+��Y�Dp�H���V��:+�]bw_�PMw"���E�Ěvii���QD"��F��R)BUJ#��k�_雛]!�Ħ�Ն���پ�>V�Z�-"��7W2p�`�uÄ��������f�ԔV>u�+�X�ٸ�Y�=s[× ���O�Ɉ����?E��z߇��MUw��Oո���3����!ۘ�dgw�P����I���v_�Iw*ds8��r�-����ڼ�p�������Jw[F�A�B���!��W(�>w�,]@L���ӵX�B�
��N챉��|���;s�3��uY�M��7�Y%�E�Q��x�j.�V��U%1ʑ��`�8�|��Uz	��d�k2��!�Fp�0����#@��K��?ʄZ�q����2�?�I~%R>�N�i���m	�J�Ӑ�P1�I5Z�$�vyGC~{�Y��?̘��s�}�7�#�Dд���h�z/0�m1��H`���D5d�=��
�w�j��d���tx*�ֵ�`n�!G��4?�)J��zV���
Ұ:�'B~��b��]���430N�^SK�_g�dl(qpPO$��T�[�V�y���^U ��
x}|m��u�H�.mJ���z��}�����=>���K��;҃�jO��+�)�T�3*<p"�(�pf�=U-�+�1v(2�Y���z#��1W��FF,�j�&����sJ��ɱ�"��s��������`�;hu�9QFY�ǜCF���T��Qv�[R�Ii�u۰"lZ2���������6cP8G����!�8��N�����V�*�_u�!*��s���5,by>�b߇�+~K�hpz�~���E )M|wi��(�ܫg~���\��⫔Ƒ�e3��x��!�CĻOu�. �M/�+�J㚯�=��Y�nM�S��e�{h�	ש�oA_WN7� �΂w����Xjd7)���	kgD(X�Z��QM��p�lŉ?��L��e�X�
�%�#|��Մ��}�fZ�o��'��L�Sΰ��p�1-,�rf$)�ɨ��6�р��l/耼�b���S���|�
i6ޑ]h¬v�F����0�mg2X��ɔU��=�⻩\5��ҕ:B'�+m��[����=��-��f���-�ƪ�ݜ��o�3���i���K7�� ���]9ᴲ|�08�#�Gy��#1�{_(p����1J���}߽���m�Dg�!2j�U�����V��ԑ���S���D���ۧ��/�Y����@
��Ŏ0�銰�GJ9.mR��P����n�+�0qr���@�i0ݤFG�ro�A���uf���ݨA{�rR
��W/T��:��z���%�7�8���Y�3��S����D$�R�S I�P#پ����n���RQJ}�oE^�:��*B�cH+{8����ڨ/�����5x��Иm�nE��(�r\貗�QMx)Y�
Z��Q����������UA��K��c�=߰��@K��_�k��'��ͮﬥ��8 hJ����Xx�`�O��l#�ߖh�
�-ⲱu���{�І���ϣdU�M�& �����8�p�vBE�
�k�l����Z|X~ v���qVzq�K�A�m��7�7Be&�Iyf�~i�,P+����A�b�� �g6��؜Ƅ@R���IR��ɊГ
��)qJ}�?���w�]�5^?��y�A��
.����뚚��E��w��`���(��o+��K=�kً�k	�eG�~��>�ɋO���;� �
�Xj'��s�-;�c��2�~ܑ�NK*e3N�;�Ⱥ��^�W̨w�n�pγ����F��ó�J:M�. �#م�V����|��fm�<���s]L�q�L(v������+�[�%;�3���[�W�i��)����{$sH��d�;]д�h��7	iD��޼����G�U�D�RWx���6a��6�p��C�<KE�!���>vg����9���ܿ7�q�$��)y����D�p���?g9��*K������+���I,�~q]�qA����X��?+O��V�����~4��ɪ<��>;|-��m�ohX���gOZ`7���b�t��.�`�� 6�a��n�B*�{���qS���n�j��nx_�A6)X�����U�ż=NK?^�(
�a�Xp^�e�q�#�Q��F�T뚙6�NəYD{�C�9	v�/�</��.���y�M�z}�F4���-���޲��\�I����"���:mnP��q�ں�kg���=ԓ�n�j9��kW�F�t2��鷍w��H����Hv��=c��v4]��P]06��F4��za3�A��S�����I��۠�X��������k�d��-�=���>�X͘�u���Z����#/�UwRƻJ9���c�G�PT+���8��ӇH��F7U8>H���'�^؟��p�`3�l��\lEK�n�gm���5�`5�̮��F�o���d�Y��$�E���R�]�e�m�=\�Lտ�hc�����ȯ=�\�OQhJ@�\S@a�������-�L�1-��.��>�����˳[`ښk�K?���[f�>����Қ�$��,Z��-ﲞ���d�+Fa���){8����Z��m�GŚ(D�&Mf�w���B ��r�ˊB���<f���֢vV���Gժ�[�J�]U$0�����N	�7 ��Ls���>�8��>��3�I2U��EO/��rZ���DM�dDZ�ಳG��1��ib�v�"|����kG�ÿ� ��BuA�-3�x��2N�ژ�^]b��ZŰ�e�	 8���2��꾉�X�v����h��Y�5�>.P�ܟ&,r��b�k��u�;��ЙM�VD�s����Ȗ���]h������h�P�e���Jx5��d�d��K��Ε�&Z��d�I��t���%yB����5�-O�}��`���8AI�.��خu��L,�L0�����W��1��҈����/�;�]33��`�g��nD�(E�xRc��h�4���V�KG��!%=�N��n��B�6_�ם�t�'�Υ���yo=���]�B�5���$y�>���><���͐æR��|w��x�y���.��c��]W�`;#�"6-u�7�Q�g��U:�����c:>a�'������_/����;���|8L�+֢+��Հ�O	.�J�f�vC�_��!��HM���V�`~����h�_m�ψw�e\j � l/f���7�H�L�b�c��w�ؙW��ZO:+�t�ˈ�=V����&�:�&N��������C����f�,��ዋ6>���d]�Er,�a� ��p.�Rb�c{c��L^���ﵣ5� Q������A��5��I�7��5�0��M!��R[R���B�LЄ�E{Yª��s, �0�Ӂ�}c$`�3�ǯ����x���YBf�GH���k6��PK#�|�.D,��B��FVO�^��D�B.�,\�!N�޲8ńn˵�=	/�>cv�W��}��k;=+˼�g��‒`]ho�O����s�n���:y�ަ���p��y4��ޠi���4K���>dВ���P$��Epn�a�eݟ����|�����éIrN���q��G��#�P$���Y����>�0�[M[|r?JL�M��MŸ�PB�Ώ�1����z-�!�$'X�n�3:������Zt����4��C����w\��.yb�ĮF4{h���ӓyO8ȣ����v���������]S�7�X�Θ�'Z�)PP>����KCGA�P,7)��۲��ф�~[��0�^�E� �x�S(��Q�9�Ὴ>����\�G�����nX[_��l�jK0$��\gk/$�nWE�`+vn~>8�ܻ91H_OER�4��X�y��F�r�~��_�O6
�������q��N�S�K�+9�]�'�+0ȏ[7���h\�r�T(�>T�-%A�(��z6N'靋\{�[��J@K�Dmb͋<�;�����Ow�|����2�۞^�=%�](���;u_}�I��$/x0�2Eu��C��ំ	O����"P��?n>ҹ7��Gd����0H�2l��C6��|�LW<*1f���*�d��>S���w�ȏ[����P@�Y�g_g�Z�hb��`�amG`������:���٤���Cd��o$�\�w��Be�>f�8����g��'C��Ɔ"5�Zve���K���wq�K�ˠۉ)���G$�N���� y����d_"�E���
B/�����tEx����� p$tS���Bw%8f��{�I��,b�}'�Jw�d�ſ�����ڛw�?�*&I���B����**�m��b"�7FB�;�	�ñ����������ׅ�`��	h�6�e�	�G�>�{��W\��N�㪰c�.�m��*!���Ϧ�}�H\�@�}�l�4 p暲��'Z�ن{#��Y?o�]�����F�*f�"t�}�����- �]����u��'�G	�~x6G�2�f����&GV�ϳ�*\#�G�%����G
Gx���_��>t�����IM��ď���@��S���s�s�X��pp���E�{Q��+���o�e���[$�Vy��������|V��ak�aL���N.���^�1x�_ C�h�����p����,�=d�P��o���`���F�@�6��BjY�92[�O?�Y��s�5��/v�,�"'��V�4	��%`��ܹ�gE@�ZK��#���O��V��|la�E��I`�\�ʔ�:8���oP�3�x��=4��m��H\��Q�� ���~]j�I�?ŕ��oU��Ur?�ծv���wڝy�k
+nB�(��˔�D5�A<-3%�c&�/t���AM��4X;n���XM2|Щ���sa؋��A�۩���^�c�~{iW�r�C��`���L�ѩ�I�zFnY���r<ƄUlv�xS'�up%� 9ug���ߠ��UN�a@A
8���K���[R���d��2BWtM��Q�^թ^�B���&eol�Z��U~��oT\�5�C�+�Х�w��i�s՗���-w�QP��D�(�������ۄ�Q��j����dߞ�W�T�K�+�9a���d��_j�}:�ቹ����,�UuO&U��k2�Ԭ��� 33(��ޮ�3�yݍ:r�����8:�L� �Y$Zr-�̾P_�J�)��6���^9�&}�e[N�_�,v� ����M2�8u�%5��iˁD*����-��{��>�s�°|�2��>�A�Wݨ!!r����n�	�6:"�����[�Nu�y�]x�\�:�����[�����x���/�����9�М�w�e����0�'�͝�y�l���﷼-��`��W/��&R�=M��$� (��I��90�4%/��u�g ܋LvW�b�,gbBU~�u*M��C̹�d��~��iЖ��$�Nt1c�v�Y�X��	��Z`��>�!��ei�����Pó
-V��e�� #��~����\�D��Qn�G(ٯm~����Na{�����F����R����z����� Q��ϐ���J�Cvq� �� u�禅wa��%�섏ݔ�k4d������YzV:����t ��u�LKy�D
�w�oM�Ȱ��Ũ��q*Q@���c�@�����` ��!,�w|z*I�)	L?�9B��6�8I�rY*E h�%j�^6����
���S�N��e�n��hg��]2#�<x�ƃMݕ�~�˹��Û_��?Άo!~r�$+�Q0{=��\ص�Z�z���ná����ߙjN�)'��J�>�d7n&�tŸ�>��}�]��Ā@��v�7�cE������5����ɝOʯ���Y�X���.�v�����5���WT���MG��Ch=�0o���]�A!�5-���9w ������2��אw��/�kSc�V�]̦M��*�~��AzË����P��0<��Q[���i'�!�*q�J���dx`��xK�r�	p`g'��[�l�#������5$r�^�6�`�s����K�e���3�"���t�; ���ހ���s��
v�7�6�����=:U����2�Y��π��1�4j<�_<��s�J$��]O׳6/�xQij���k=�)W��t@Qc�P���\�\>|�9�l��e�X�a@�;z�>~�w�.-��7��W@��D�}m �m�v$z�Z�6�lO�{��5	�5~����+���ٮS]�;Ө�۶-��*���hA��H�5 ��gS�����W� �����f*-�S8�Qo�(�'�����~�6���=��[bm'	��x��w[,���ǐ����O�q����n,��J<5�v�P7r{Г/��e ��7�+/	3��s����g�i4��<r]m�B�)ͽ!T�s�u$�������甭�{2}�������,p��{��4��5��j��-B�:_Z�/�x2�����]^��k/8Q��ë<��R���_ilM*��y 7�[��.�����R���c�($�g��#�㰔q8�Y5}�N��k\�/�D�������_r+�Zy���JR�+�*�st��V��oK�UZ,�$�ߧ�qY�>��t��8�F��I��۵�i�>w�A��ǚ���{ڗ������@9��~�D�,���[�z��e�۷6�ig��"̓9�\S�%syi�D?j�j�� 9<�W�a�lZ��{z�r�7��9L�%����t�F_K���N������ϺqH�C���N!ܰ�&Ap��g�k֧i)T1��?��Q�+%vm�=�X�M���<������=�R�"���7Q�5�+���Ėd���j�4
��t�h�X�E|-��b�_K�y= [�/%�>������u�8��#��)9�����'��[yd���9�&j������缸�k����3��ˮ�yY ������;G�d�ٱD� ���U��ڼc��l������m�RС���%��Ơ�1y�uX���K��P.��=���v������� [�>p�#9�%���?��q\������u��X��' IL۝�R��d��@�6%�@ ��1�y��=���(X5/��;߇�#	"������$�ڱ�w�!��[����iv���40�wy���:�ly����{�?f����~T0�������ڞ�Y�u��(%C@,�'���*������N�ByF�_�������c�Cً��^��&���E��n"��Ak����G/؍������t.�i4bQ
�̈́��7�ݭ-3M�c�B�+�)��%GF��֜���]��s@/�; )�3��6Z��k�G}_�Wq�v6I��[�'��U,R�p3�,�H.�|�ϔ�V��T�ÕV�����;�*V3j�!�7��G	���^Il���z�\1���閑��W,�$e3�);U����׸�
G�Am�p��XU����a��
�W�	���Xm*��������`S�m0ӛ]4^��Kĉ�l.w���e�������
���*So�	FE��w�nG$�a�C�]d=7~F���wƔ�r�zB��nm��|>�Bp��N[I��|@�A�$9:2G>��  Zc�o�1~�<��^r�۩z�����g-��mn�e���C��t��I�%��ƤTx���V�{��օ���<�g;\�a�ztXuw�A�a��!z���=���w���~'�u�U���}��C=�Xr��yN'���Q�D�i[>��Ͳ���j\��G��=#r"�J�R!� �����L�:)����]F���c��� v�<r�@a^}�7�-&�&���R}�<QT��v���U�Zxu��v�������!+��`��Q�uy! �=o�a�8�J��r�̥�ܡ�Ц���c8'5-���f��0%_m����[<�إ	�z:VP��tQ�Gִ�e�?�S���>ƍ:2#M.⺫�'�.����'��ڠ|��C$T�E��_t[*��+0��@y}��7�x�S"4IK�Pv�_�)6��j� u2<�ɇSi/.�x0C���,��[W�CY�_+���^	����Mcߎu�_�����y��-�B��<�L|���T��оp>���7Y}e�V"������������=��b��k��5�rꋡQ>1�f�E\��L����QS��/"�%��6�ڸ` �׽h�-�2Q�Ⱦ7��Q
S,'N�9rĜ��r�ö��>��S �9�����$9@�o�N��j��:�����䫡r�?t�.�(~���G�N3f�2i��5��s���W��>��K���1y���0��U z9N�9�Eޯ���#�A,���3��]�a��b�5�6oW圂V^�>
��nI�\/�j�o~/UH]c�)���a��Աq-���ϭZ8Λ��IT/c�����n`^���Q�s+<�1�$������dt�i�s�[!m�4)��6��\���O\e��ao�U�%[�Ϫ����X~�
��R>��m*�4Hj�?ׂ��7@x����?ʴ��r�}�oU+����@�>cp6#}�+����!�C�R�����E,�Z]A5�5, ի�r�cd�3	P'RM>Q�N����P�n<|2�řm��%�6P�$, EHt�@���š`C���t��j�iݺ2������y�$���AxD�h�aJz���?����V3�����C=�>l�Uґ����A�����W{��7�e�����6l��Xח���i�q�ѻ��=����,�x�~nW����/��~��?�!�3�nע�+9w��4|���èS�:O'l�����x�a�eL�T��7zg�3�q�G��:T�Y�A����?�,�S[�p��ݵk�K�$;Y
���j���<�"��t҆I��@��z&fZf_%���XB
�8��'�E��|S��f2�aZ��KBhU�G��D�SſKkx"��"Ί�|Z){C"wG|ʹR8��rԚ�:�d��/@�!�"й�F�g2�0k-�G�d]�&X�x��4~[�:]FW�8B������;�����sq�h4��;X!������=��x�2��bg~�Q���}Ͻq.	%��
/:���
�	�ň]��v�n"|r��T5?�E�M���I�[&�3�f>�{4�Q%���6U�Aj�����x���d/�ׇ�l��B���xa����%
i0[�M�.���}���I%TN$dR9XIt@�|u|﯅�l��F��KS��T��Es��Z2��9��q����;���2"�r�=*�v����x/g/�Z`�$hټ�eTh%�z���sfQ�Jf�v0e��Y� !VkRbfz�t��D\ݾ��-����4��� @��WX������ra4��{�?c<���e��L�0�n',H�s���$|��Pʧ�{CU����dɤW���IC2�
7�a )���=���C�W?��{t�	Yt�B�H�3���8 :��	Y��˘���R���!�{����??X@-���|"��Sv�4��c�d=t$c&d_d��4�'XFyK|g[s�L�8�y�Bkd�Y���s���$𽮾�!�M�)��R�c+n�LW���d��#F0���^q��F�Ch�ߥ��}R�ů	ڨ��46o��6�j:]�<��*�g�o<��<�V�!T6��d�~����$�q�!%�&k�Gͦm��X���������\�]�nI �{ ?*�g�D!�L\O�h����I�G���\�>5��=|�{K��M�*gd�w���8���m�7	꿖o#р�z��D ��v�2��G/�� ��sk���Z�6=�M`�}�[���ߗ��Ȧ�~��%�o�qU�Pܠ��j��25��,�,�W�,E�P�:7&�;���[^�v���l�����%�&_F!�͒�2f҈`�I,2cr���эJ-��z�����,�̎�V7���yw� ]�|�N/���{Jq]�pͅ//ҥ�
�~z4��<X�L�Qe"��A����'�II��t�r���j[��!��> �GZ�c��P�*K�c���f��������}��¢�L��jgx%Y�=i    ,{9w59 ���� �y��g�    YZ