#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3598596336"
MD5="f631c29f6475274f3014f5e5be038888"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24928"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov 15 05:49:20 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
�7zXZ  �ִF !   �X����a ] �}��1Dd]����P�t�F�P�a��A���P�Z��t��@:*bL�G���}&SX��P(�},��R}�	�N!e%(zA�%��B�3���!��iĐ�#�d������հ�ΰ̽�zd��/-Ry��{/]#h�.��߾�wN�%� )��}�#|s�l��n�M)��~���[�'N6��iO8(r����0V3�Y$c�A��tT�x��Qj]��*�5K�e�����s��0���S�`<Hڸ�AC�1��9��_���$��wY�s��.�����ib
��A����\��6+��{uM�nn��n��b�o�.�|��v��h:j�U���A�r�=��Z'��8یzN��~;8����<]�	�k�]��)
�L� ���  f�+�m�y(=�Ԁ谴���i�Vً-�Y��NDD`P7V�.�30��I��^�X�4�߻ C�)�:�N�ظeO�e
M�?}/I���0F��dl��kX-bB'v|���eg���x�&�*#EqͮMۇy��:J���H/k+8��P��˵�A�Ҏ8L��̀֥��� �
���kBpL���Q�j��u%2 pDn�f�`Ao9�Q��u@����s)��l�r��*���Y�v�mb�{�����Y/1�6'��Q��&�m��C$ܼ���Z�k�\���q�^��5�hq_�W�ň/VX�'R���'˥�{F��h�4���
Z>{���ϫ�7&$E��X(릞�斔r�[��#$�8΅��8��P�r����)��O!����[L|�>��!�C��;��X?�gN�!є�j{�<*XO����=�ܑ˿ۡ��X*�,�V���J�)d:)�I����y�:�X�of%�i@�������$�����Nn��4,���`#F�~�i�����A.���{��F���y�7yN��R�#e�'�R3�d��VS�"��{OÇTY��p�,�W9��h�Ѹ��LB��y������28���2�Ɛ�8{ڇ��� c� ��掮 ����.v����74)Ea_[��J�����9����/:a��Ɋ���q�X`��+�^5����$��-�����P���D|b:3�Ϡ�SL����|��M�J	b���8Mn��& �=���?�ri�j���	���钠3!n��U#	��)�����z�Ҟ=�fy�C|�{Ⱦ�4h�8��7��NN!�p��w�,��w�F8��H����}�kJ�f�#���`I�g��5�4K��S�Om�A�w�-��T�/�I��q-W�d��3���@�E��,����_�$q��1c����+
|�}�J_9�nʄ��)<S�)�	��}}����� ����~�간|y�E:���6���ΦT� � o0
sI9Lld�2��&�Bt8�E�� �����dm�1����c�n{�'H���X(Z��LZ�&pC�D�2_;�D�3l�C��5ҧ��J����������ښ��6��$,C���L2��us�����d��sq��؞s
@̉��-��\�ce�����uh1�@fGK޷R�p���qC�0��F��C��	+�㪥�/n��m\�Zt9��E�Nn�0� F��T��4����[�5����໖/�6�4��P�Z�����j�����ƅ�y���� 8#U����Jҹsʀ��+�$��G��-c�qT�1+�3Zyk�9V�������1 2��U���Z�Z��|RjDa F���R5�V������Tǃ�Ϸ���A�u^�T&�%��).ŝ��/=|��Gs 疊{�ȇCj���w=8f���2�AZ���3W�׳�ǜ��F����������%�X�D���j���3���@y�ZF�����l��,-�K��k�k%DR6Pdq��K����/74��J9��u���/�u�t��y�J�4�#�2���x�Ũ���| �L���w����׌�(�Q�����+g�bj,
����Y4��E;^h���vi��XNz����5�~�8p��rƨ�*U�d���a���FNlUҀ[���x�ؘ�Z=�	��|�6y��yГ�},i����=ε��	��p��%
��M����gM�+}�|�n��&��$
0ߪ�3��j ���o�Vf�	t���T{J0u,��ˇ}C�!�ߴ)���F��~�Og����3��'p7���)�wQq���i=��"L>:�������
m��p�+w��X��ٽg���
"�
�:3��*H1~�%B�����f,�Մ�-�`\�m�p�F�9e�o���j��.�d'��Ư��(5�-�i�HkC�)?{��GS2FWn½TG�{ÐyZ����ٯ�PD������ړ�1)�\_oV�t=�B����O�8���jA#����r���ǉ0%+UA\}s�E� Z;n�a�d~]+���a�L׋ZD4vI�a��~�Zk݌|��-����/Jb�q�������{4�^��L
���y|H[�wHe�>�R$�`�����FR���D2��R�P�R����-�"9`�hDBAY�,ې*��-Jm������q҂9��W:r���-�j�	d�L��m�KF�V7C�
%�I~��e�u#ǳ9�#4X��)o#��K���j��J.
Bt��8 1��{|�~�	т�Asy��9���-J���@�\]�cs^׏�N���u�9?�������L��j�<��K���6s��G�/�=������h��w�P�~"q$����E�rz�� �t�.�J���X����INu�����P��cſ�b�d��� �e=����.�e	y�0B2�������������Tv�^6���M"��?5~
&WK�{�8�9�5��苗���LseMg@�)�p}���`��ӇV#翭���\�LA~�׏�q@6����Y������"�G�*+D3LC��_$���=堷l��7m����\_�pp��6g�e��>�F�>�W�]���/���'�j�x8l4�*G�[v�7)�{J~�-�g�yk���Rp�qvk�="8.<����n�B�Ei(yz��^GU���d�q�p$��3���[fr���ݕ��cg��8�ُ��
'�&pFvA	'�I�xO~�K����m�G��h���tҸ�Y��_��Y��>i��P$��چ:m���y�#Q��Ј���5����ݽ�۵�����8ɪ��q�I�.�,�G�K���8��GJ2��'p-�k.�e����mCRx�Q������B���	U;}�~k�~�G�܋��f�#��Җ�H�� [\�zo��d.�9 �9���!_������jw[���p���Z�ڨ���O_�T�-���P`���qvѥ�� �����_��:b1��!2�Ñ���2Ɏ�v\�?E����O.DC�����F�D�$Ӌ,���\�_���f&Bw�vlBt��_S�4�����x�8Pɀ�����3�ݥԖM��<��M.*mz��E�7qY�<�f3~�zh�i�k:p�X�D\,$�6qER�_�]}<JГLOt�J��`N��|D��P�/**�a��/e�I��d"=+{����*/�N#('��RM"�Z٤�ew��%�-�����7��>��D�{�Hׄ�˨���j3JQ��H�ރգ�j��)���A�-�.GB�^��!�׬
l3ǾJI7���f�%��9V��*����V�%�6t���&���S^���}M4C�m+^	��Jhڢ�"O��3֣|^:~K�������@�~�CU��5�/d,୽!���i	>�|�#�-����ޖ�HV2�U+��.����dg̃I�<�t�jZ�Π�X�
Z�R_��l�S9��
����j��R��.� �"�AE�q ���m��A�(�x�!62�@j=X���to��wm=]�Y�=J��`�ɒ����)xO�HG�[�b�c&|�wP���7�� ��d����>�i��j�dpLr��1���^%Ue���m mGe���n���8�\�^���͛����ǭH���ji��j����qD�Sa�M'C����u\�qgE���z�p���_](b7�W�W��hAb�_������~��C���K��a_O��<X�������}�
�a	�CN����'�dӬ���V���^���g���$�P����S�1�!���MYr��q�MR7��N����,��>[�=(:��4����XT)���^v�Θ��J-(���׶�͵���}�R��)�4��J�TQ��1����04}i���U�E֤�#���X;��?c+��ӛbŞ�pj6�|���T�*��15�4~����4�1����z�(���>!�����?�£���3��ô)������$�\>I�S�V�2��!�u�������7dO QmҞA~��9�@��7@7T���-~��P9md�*�B�� �����U�j��5�H�����(�4��)��
��	�J�a�.c�:}�!wڃ��K�`[�BM��`��l���Y�ϡQ
��F'ε>N�L�f~���I9��jlzs�um O@%-��~���h�w����li����rɠ�:���M���Q����f¾@9بh��_�Bw���8��_�P0�<	�� �	ضv��uɒ8�;x�~�
���})Nok��\�R�f�J��Nܵ|Lw��#��(��+@+�[Yp�T��f�R���D�K��,���=�}%���k��?�͸]|,F���y���[���6�|ݽJ�j0E�܉(�R��&�|黪��-+�3_e�]�.�Z8X��U��l|�f�]B~�q��j��R�ɼOvCͿ��3W��U
8�T�L�M���g�F�7c�.�����Ҍ��THZ�q�g@�u� �w��r5�z��[eEG���6�׻�»��0�����Ӵ��2=Wiw	K|B�K�	�������!ה�K��/l>e�U�f��	��_C��d���U�,����|�,��"�ЬStd�b)_��+����[F���\UE��PZ���Ƞ���<��@�K�����M0�,��I �pS�<L�=!���Ok�V����F9�#�=Y��.��V��;I��>�[�8�sʭЊ4׃=Q�f�b�
��+u띨����,g9�lu��V�g7����1��|Z0J��C }V~Q��|�z)�Q)$��_>~x�&�ᑰ�>D��#;�{W��z�woR�� ���G	�1#+�q��+��=��;��g��[!�4=�e�>��'�"#*�G%�% �<X��T��䁌L�������=3�2���>2�|��̍��h�js�2�L�vy�Ws�C�)���#�t}��4n&�5��cgw[�-�d�Kq�z�&@E/�BbOWyh�`I��K������s�t���?l/���i�����D������ ��?X��:�ݪ �z��i���@�{ �-SY�{N+*�C��3��y�6Չ�+p��j_Me��ִ��>�=ũ��)j�QQ��y3��\'>��W'Xņ��|�q�L�캏E�)�1p��[�ƍEMҗ���R4%4+H�V�Ք��QX���n�EW&�m?]`hXv��`e��SiWns�;�1
/.\l5t�H�Yj���������qe&F�x���t�o��R��y㣤�CHD$��ȧ�;D��#��}�9�C��F�{Ǐ~J;�_��������W�a��OSK�����@ɬ֊E��R� ���@��ݍ<Z�,�2�^��c�R�P���(�I�\����<����ʺU�B�̙
Z���;�q����f�ӓ��������2�Hԙܚ��9�V�� ���ٱKFtIi��{d\��/���X-��u���ȧ.��[f[IQ:E2��+p$�O�I	t��P�I|��nS��5���k��vl4RC,�C�AĖ���*��;>o-��^�ŧˮ^�lT�y`l���l�Dʻ�������;�ו@I�Ӣ���m�k�_\���j��������X�>���I8��ش����X|�V��Sz6�T)�X���L_8�=��?�S��Cf�q��T�z1�y;1=�xr����p�����&,�5���ucF��i;���2E�L ��@Ƽ�@��kBw���/	ӝOh:H|��8��i�2���T���xY.tk����Z'0?��x�~����B��C�T���$wq��0��PĽN��BU�i���b��A[  ��\nTI���:)��y��->��|���<�Fi���x��gV=Ϊe��`->���O Q�KkC{����'Wf����I�m�A���9���˄���_`!(-YǐpX�-��V��3�V�y=���O��������a�Xk�"m-�TA�;�hK6|��ڒ��k�:�\&�*"��A��Zީk�4�`͌\��֒�'��v��Ύe�z:P��8D�b䯧s� Ba;)`�	�NHv��lt��ƭ�����Y�cq�v��o��6�M+}v��t1�D(ˎe���^^Km��&��s�|I�Mt7ؐN����}���Ph�_��3��U�.JX���z�w��E��.�]�
Irz�u�W�D�U!9��hTлֻ:��v,��q
��#b�OTj�	�|W��k/�ڼJ��ENRRƣ-xa���Ƙ=�w�R��8ys@5j2��$y��*mY1�T�H����1f�=�p��yN������"*���Tz ���`��x	B�	ٻ�L� ���.UP����=n̊8�z��'Gdg�u�����,��{\��O|U�[�~x`m�uXM�{v5E���~�j���|�	9������ι���!��°�!:������]�Ė?H�> ��`H��ۦ��`�Ra�1=�>���{~j���w�ӷ���	8m�����-�d�tPX�*#�J:�Hd��!��I�%iAg�[Y#���^q$|ChG�N�����~po�^�U�������4�︚���9�~)=,���<�*��F"5_���ffF��J���@�~��S,`[%��J�l<p�Q�↓]#iUNI����!c�i�@�bB�]���W��<ܵ����řrՙKW��if��5���k���Cm'ld{�!O�\�,�YL*����;r]�-�[{H�3wC��L�d���ƙ���f�_�V�P��B �3���;��R���8�*p�ط��2�R�%�I:I�|�T�wk����P��`�z\�&�݋��e:����y	�����Cg({5��Q��H�g�TO+��a%��Mima|��0�#6p�����<O�5 �Ku��^��-]�L��7�U::L�:<*��O�����ĳ�.,wjǠ�B�%��O�$�Q�� "�j��3a~�A�|�~_�����L��)��G/9���\S����s�/R�K%.K�t��J�]�r�p�b�'�W��\�|��'�H��eU������KGc�J?<j�n��Y��|�5gK֖�k���F�+�H���/������}�:��{ :�(iʀ���
u���&p��"` ���Cr��z�<S�\#V�	A;��dڞ��
V�xF�mg 6��=�{d����wˠ�S�Q��r?��h�����F�Aiq�Oy�j+��{���U��Rdk.�kU�v5A��D�F%�RUEO���
ق'��[�����^�������NV U0
U��q%C�]�!�NKÇ!�+�t����.��P�H����@]�j���S��f�ً�+��|�Y�7��sRn{��g�7�t�ȃ�s��QfX>�IB@۟������Bּ��mL~G���/tyuv&�;��0?t��.��G�i���޸W��4�?O<A�I�D$�m��p)�RȘc��02�'�*��nS&��N�e0#I�b���/J�Ɔ��{�u�d�|z��Z���+�lش�M�����u�9���i�t��Z��ğ�x�j�����E�&w^�~�I*��و���N����th��d��wדמ���-��ʋ�#�bc7(<m��2f��:׭2u�|X5�e2�򻋻�j�5 ���QD��׏�V�Λ�TWjpt��}�|��o�Gџ�E>J��9�� �RfՃ��[�zu5��!�A���,�<½r�Ӂ#����	C�'�2}��y₭ٮ!�������I���9�qc������̵k�7�(��n���Gɱ��Y�wq����������TLTg��� �݆�*���-E@�q�	 ���BN\�[�n���yrQ�%��x��ҟ���;}]:b%#�w�߹�?R�H�Z^Á�4!cjN��*���Hc|硗k�@AS \^���3	����.�f��;�ΐĪ�\r���+�WX���Xw��t���	�;M������+jM8����eR��t���e����ܢu�6���2�t�V�a����؊��XP���R��},�8�Cڔ@$'��~�!�����:9v�冀��7!
 *`4����΢��<,�|oY���襏��M�S��j���u�&p���i3���yrЇ<?�+Zz�)U�3�I��@��~ȹKn�����g�~���;>��@c��r��Ri�zE�nBXG�}���))��r��Fߎ�J'9������c]>��Ǳ���h�l�g�7�)q�}�C@|���҈����K�=�N��g�qO��I��G���B�j�1"܃:?ՠ} /�T;TE�,���z�/G�9�����%>��|~��b.-�qGU��x##?$<a�!?�nx$����D�"�~"RL"�D��H�vZ|E�^M���M��s;��p���V9�&9u����iC��dc���Wc�{	?�2������Ța����e�j$]�aB��Ll���u�����A��|�]l@?�=�.����|ސUa<�h�,lM���{1f���G>�zys�P�W���`�Af���T�P.��dkCܷ][�AI:?�	K5D���Rh=��<eЌu�G,῞�m��<R��(^~\��UT��m�AU؉z�S�\@�g]z��s�yz�����z�Ӭ{H�v{P�}�o�+<LF�I�	7�>G>Q=2�w��,)��tIE�s!G��CP�|�&��bO5�":7���I��Xd����!�r���7�Z9wO��͙vڲC�O�n���#�s��������\�ߨ�l�<��mTs������9h��.��g���O;��'� ��?�Ԟ�	��*߄�]+��"3V�]�����B[F�O8[Q�<I���N_�[��lEB�@�,���M�\I���W�R�Ls#wMJ��P�7�-^�br�,��Ÿu�+�L\>�?|���qD�4'�w�8d�K����/�j+�T�h���|�����{���#��F�>��&����t>;b����i���U�ͣ�CE�f���nf�A�1���c`�3�Ɗr�_.6��E9[O=ޫJ��-�d.���G]~�v��I�2?���W<*�����Pj�#�.�]{�����yB���A�>���ߐz\���?�h���Se$���'K������S~5��(�j�[:E,&�*�&�#��/J��2�-�����M�kd
�W�W\�󕊇ybq�Zr-���S��[C��!�e[�>?	���� �K�O���쨣�I�E�K�SK��C�P�S��,�=��_�0~�nD�p�XNzx
�|�a��d�7�RqhH��k�0;2�T���5�L#|�:���se�~�xWD���eH����XQs��LE�e�;��3�E�O��"�|B#�F={c�j�c�ԅt7�q`Ħ��ăXӺ�J��:Z�x��s���`�l��@�{&7R��=�������b���*�ۅ�F`�dr�Y͈Ŷ6��,9z�1v���������z؏���I���aǬ/Y0�ܔ���T�A K]a��V�r�����@C����,
eʣ��o������k�.9|�����\tCZ�`3q{l��
�3�79+g	���İ���2�F3O���M��/��
�0�/o�H�P����#��GI�N!�էٗ��?*B�G����]LqD���tt�Q4�d��T��F�ۻX�=�}�L��Ů�_	���R�ő�&I怲�v��P�b+���U��<�f$q�UT�F@��OE��Q*�O㐣�!)47�t�0���Za���Ԙ���Ϗ�%;3O��_�;�[�e��O���0&"⏣+����3��%E�>�B4G�-9]�A�O�3 �E�{��0�~���W:As�9تl�����qQ̷�ؚ=���T����xFR��R���/��Ӵg�Hyzq����1 b��X�3�[���G�xgȽ�G�}�N1�� z�n���1�� &2p[��"�^<�ݑ+I��Ƭ�s�ܽ�m��b��)i�{ҧ�tnB#V�8U��Rw*���%�xG�|�Z�佨X�+�BlJ�P�j���A!�?/� �$7�`q� #��}'�n%�{���6��E�o���*�i�5$��8-so�A��J�G�Ww�)�Q��/g-j�b����ފ�e�Rq���H��с�Hr�qB}'+!"�y�<@�\�W��E�����R�p|>XΌ�-���"�J�a<V�-�y���©�i��r���Ⱥ?�ey?D�׍<W�������{�Bkr��A��6��6���R���A� ��zPh�t�G�b��,�Ы=G����d\���>������T����W=�mf�<��GJ���U��;�Z�N?��%.�:��PG��.���/���̦�n�N��Zք:@E��g��6�qZ�X����?3&���l��j9�1����v$+d�%D��(��A+ܳ�\���[ۈq�;g�E>��D��o1��2{�wp(�\#���L���ʬr����`\�<?0��Y�P% ij����O��k����8���Ξ�>��n�U`��,P?���� �X� ˴��&��lU�<�w�&��ܲ��D��`��5)�� ���w����4�L�Eb������C5�Şg�e��/-�q�M�`��}�8��	`.�D���(�FU��Q��&�~*���!�x������[�b��܇�*HP
@��4�#�{�1�V%��D�<ӣhc�'���������x�2����V����=��٨f�_\β^��{?�9�N�Oy$N�E�3��A���}���}�0W���'�O{J}�$b���\�T��bmU�!Z�V�T%2� ��o��ĸ,���`�7kOT�T�i�:��
�2�jS�����`���-��T�S&�,�fl�\��Y(�����q�.���f�x�� k��r�Ã�o����,��`�e�M$���ƌ(��������.�"��S5�;��[���F�'>�D&;�$��Ʒ�{]��Y�}�7�42��Џ(R�,�N��
�D��б�0�'7ܼ��ݐ��,�[쥢�9�剌(�U�&۞�J�<�p��/�}�?�����B�V ��g㖾�@q�y��g[έi
6��6X@�񪥾��^.���A���K5�0nP�d$Ɠ���R��b�]ru���(|���I<���C���#�WVO}�|�n�^�j|Y+3�zBЫ�q�n��db]�Gy���g.U�ű��"��A9� ����RVu?��f_�5 ��@�Xx4�zJi��� Q��W0�n�7*���Q��V�@���X?�Rl(��B+2T	�(��W}���|`���>c](d�?�0��V�����)�b�	Y��Si�^1i:}QM�5��}���d��k��jra�O�����&��g"��R�(��9�O%�T���B�д�P���5V>�����~�������y~�Tޞ
e�Ȓ�-.TRF�H:����VW!�[>��9�
�.�vő}x��#32O9D94�4v@v��n����k:ē�˥d_N(~z�q0�4��;���ods��m�򿺰O�$�ꂚ[�K�cK��&U���<qn0�Zk	g�`��%��y��=N�<�T��!���g��C�@5_���b��=J�r��X��APU땑�PVw�#��="��6'�FO�~S�}�=��_������~��明���LGF������,t�c3��>�ӟ�ub'�bIڅM�Bc s.q߭(T����)�Q�')>�|����:6Ly�V����J���if�g�M�RH�.$�OȚ竐���h$K9F �Tv
�MLwIAQ�K��PS�8��kp�/S_�` Q��X���=��Oub��O{g�;�z� /I�7%�h<j]��.�� ����g`I��
�=�%7�w&4~���P�h��NT�<&5�1�IG	.�0�К/	E���V��i�U/"�q�g)���z�O�d����>Ix����louo��B=���;��2�!��YN5�7B�ԝ�_il���2ZYܢ;��s�0�+N�l�?�f���b;���çbl��� �@��Z�2&m����mʟ.^W#�R5q��6Z�i�e�xt�~�|ɍ����=:&`�,M��m��\���i�2c7�-%u"X�n�X�����p�2��/*�4�G��R�w_,��rS �����va�Ħ"R�<�T�A\ѭ�֠=J����D�y�_9���CZ����'G~�nwF>�0���=�ͯ\�������Q�n]�9X"�+�Ԩ\F��4�{=]s��_]���7O<��g��}������}"��_����A9�O�
gyMcR�*H35B/o���a�-��|�Y���7���ysK,�Ys�B�ī�[��К��������3)�}x��Sn(=<�!W�B�C�b} X��d�;}	蓔~B�9��J����s&�(��TV���]C�槊v6�C��3��񈰖ta����Gj���2�?�_?<��G��>hEN?���׮�{{�\�-�/��׬PڋlN���}/D�mb)����mF�Ķł�P�T{n�bx!��K��'��_�;������_��]�+�-N���ē�Uq.�0''�����6�S��U�y#�8e������w`�q��}�[����Y��?�md&aU��3Y#��lN0D��dL*y�����ǌCv<m9�|�Y���
��t ��2��B���Yj�L$�W��P^�h��͐[��Z�S�@�U�-0�?9�����@g�x�Cv���̨��<�'3DV�Ur,��"��)�����I:�s�7`$?O�j,bA 0��_�;|�`�"��g���2���uAY"_�sX��A�w�R�~O|�2~q��:��ej�����,>8�^V��qUe��҆mR�e���r�s�Tk�<�i�l)�3�!��A���*,�d>������&�*'�?��	����<�����f	��ݓ~Q���MYj3������ou�B�X0S���u�h�"O��=�� �V��2�a(bc�+l��F�z��.��w���=������@�Ri�l��-����6��^��p���5����/}�<2X��\y�%�'��m�������H�xex�1�}qm!����Aa�8��j6�]��+O�]Z �z�[,u�i�;�]S�7юʖyT:K�B�X�/�3��N�9��|O&B���P�_�6�cK��'��)����c0K2Y���s�^F�"��r�&� bz-H
%l:�Ij�?�2�:��>l	*B�ngU�E)`�/��L.�Gڡ�i��P��t=u]�ɦ��|*�&d��w���2��|��|
w��<	 �$��=��1�J\�H�b�<6*+��v�x�����Ϣ�<qܸ�Ms
�c�3�%2�Đ��}d����*�p�m0j�ȗ7z`~踥CQ���)e��椒�n�A����.��|f��A[/�������v�Zf�d!Lc'�E?��<�����I4�\��T�-E�}�r��r��r\�g�#Z���n+���0alX�����.�"?9����m�Nz�8�?^.�{3��Ӹ�&�7��@�����������i<UD���`�E"��-�t����V��MʎC��טom������	�N�b�c��X��f������u�z��!.K���#i,�\���8T\��A\k4�KkU�7+���VC�cK����j"�Lfe�}h[@x.��p�+�s�T�n���wY�ʓ1�g7���ܟi��A�a���n���w:'x=*��J|8D�ABE�C���16��w�Xԏ���Y���_˹g��O�����K����>��,��]��HOJ�}��1^\S;|ߧ>T����J��%W^Y���ģ�»:����2md��
,��Y�_0sk��*�9���(���v�F�tM��-�I��SXt�p,7�͇T�U_ŗ�x�I����!F1�q.�,��ݖ�b����*� -�����rb��]]���g�cs%O�#'�Ip6pA���ʎ8[��բ<H5���-�S%s�:�c�4d�l�nPf(���LNֲ��Ƒ�-)�)�&%]i�-������Ag{Wr���!�*)Go*�A=�-<�G�:aQ*8�}��N޳G�zJx��*w�7�=L_�� ��q	�o�[�u6��*�� �<&�Ӡ�	�K0',^�0-+��A�t��z̅"�?���*6� ��b�4r�n�x����|�!W,aVǱ�!bz2_Ù��ʯ�-�G�م��ɠ�uo4.k(B�1I�2G�A�qI�a-��ߋ�Q���pw�K��#'��id�J8͌���F؈���6oaG���͛�R<��rCKFX ��W#8�H/���#��xkcq~�����3��"<q��H���(�!OW�4��x��<��cP��-|�-׀KYE:��p�%���!��x �؂�3�`���֩n@��մ[,�����ïk�Iz���蕮��<�	��zk��,�i'��Ю��͏字�fXdZze�������ܙ���4zIY^Y��E�^�\����e=~$�4EI�z��|��E_1Cd���U�wkS64q�*�$�X��&^���:z�x� P��\P� ���@��� �퀑�@�/��v�w�i���;Y[�,��D/�=hٽ��h[F�7�#���p���]����X]�2���Tg24���r4�t_�#8��#�+(�h[dJ"�B����.	Sރq?c��SL��f��o�vkv;i���K�Ѯf��$�p�z��o��MU
�N��<�a�L6ӻsj�:H�U���&���3I}0�rdy�T>2r�/�'���LNU0F�O��̹�:�G�s_s�Ԛ����v�v��¯����n�&�A����[���Ջ&��}& �B�AJ�Hr^��7"0RL.h�x�r�<�T��v�)R�Oš��5�n���9,������{�t�֧|�k+��t��nFb��ڥ\u-��Hr�G=�(�a�������V�x&�̌�[�%�:��,��&�y�唅��-p_K=��Z�V�^@Z�P�g����k0��Ę�Ø�kLg���	C��V3��N��'S��m6o�zd#���vL(R�U�����@�]Qu�*�����>���{�:���M�:Ϧ�,�}�����#K+��Y�̮�>�.�8W�p�>/�p�q}��7��2���b��#��� g��Ո� g,d�)�*�ֱc�w��C;��
��wj:�\K
�~��K�2�,T���$� ���A]�sAa�Qn��z����8�����L�j%	�*ylkw�=�&e�WD(�'7cvu�6�w,®�[V����,Px�I��ש���YEV `�2ac?�\�U(���N#C7ֵ2�&-�����Q��v�9641���k71�"�V�����2�&fe�y2��jJ+Q>hޥ�l�7�2I��ϔU�Q;8�+qu `��Y�VL3�v�\c�$�fЌ��Gc�7���S}xRy�F<~}YF��*�G�5� 
�#[x�K�m�����Ը$��~��� ���`�@��b���0+����h���5�G�a��9�	�["ZJ]�?����u&���Ӥ^���~�W-P�$�#�B���@�Κ��Y����h�)��������V]�T�O���BpBЖ�i�5+7�`_��K���Lr��~���;�GS���ƭ]b�����O��~�̂����&cJ���=C���yrHb��5J�
��#��ڂ�V"�)4�&&`������h�u$��w�;x�j���s�c��J/1��6��M���vw�8@�S��>1�*ΒO(�����٨T����^�]	$E*�m�Tv{k$?R ���"x����<YXK��{+f�˖�N��;<d��d��37-�ԙX�IT�V�|�)�p���Kb 9�2�7G&~����'���P���;
����~i�}���P�I`ʟcC����i�qǦ���{��HS5��V��n��P�kA�X|�,�^��pݦ���ɓ��,�4���	WvQ4��$u�����҇p��f�uQ�A�ł�5�c�C�z�;B#��d��'�ab�[Uoq��MҸ9���'E���>o�A`x�\n�x�\�˾�L��ngT�x��2��Ԛ`���<���L��ϩ_;�h�h�U�U�;�9�b�/J�0�`�� �����H��Hc�-ޕ�� �	f�$�[���E�ZU�mQ�n/oA�㍝��}��ȺH��˺����7�����wE�Չ�;��$cGd��Ss��]]�b�6�NO�:��t�2�"�Z�)Pλ]�C�D�BTTy��5F�<��VOq���9mE��|_6$��~1��d�7����ڻB�ҘpW$nBB�D���4L�+e������Ƌߖ�z±"�-"�N�/2�s��"�g��[�G���f`j��	�Vfm�~QC��w\h���?QX��ڱ�����8g��E��GFa^��g��=q0:v�t�6	����l��i �ݑ��c +�$�y�A�{.l*͵o�(�8H����j�0,�(QE�s��\;�'����9��Z��3h�r}Vnd����h I����t(����IXG�ւ��%�Qyε��Ŭ^lcWY��Ri%�5�	��D�l��CHpe�n%`fv���s��o��
vG�I��CRNUl�*x��#`i��sP�$|�Zk@��ISＰʇ������^/�}�T%���3?��Np+�7�0�t���\v����u����m%S4S</%/��W��Q���_7ſ�����77�J�"�}�a�/�蓅G�Hv��U�ՁnM����X���ZdT�#�S��G��Ǥ�.�,ߴ�����-��aE��rfqLON��ɠ�P�,�����$H@�ȩB���K!�|����Ey��mC��#�O��e-��VD0��b$?e���}���B���7����PR�Y���Y1?��]�~c�&�3�r
ևuÞ~������a��<8J������}SF�t����R��="��G[�^I���>�Z	gy��*ཟ�Z���R$���!� �a~�-r �� �CA�E��0���ͷy�@(�yO�(%���G48���4)G��ԇ��DR3�4&��T��BA^v6������D��XA�b4��Ѿ��;���{˗mL0��C�Jg��Y￀q'̺�T$-/X)W�Ogݖ�L�P��p+^ \#Df�����L���ϭUN��a}���]P�3=����m|;1��'���$vF8j�M�w���gUw���t\t���Q��S���Wq�#�U6t*��F��n� b�q��{Ѯ-��m�Q�ۭj�3$ㆭ8­���+��z�
��ׅ�g)�ql�������(Çb
_EP�mF�s0�I�Ŏ��ZOYUO�[t���ಭ�s���d6��M�l���w7�*�S�F.2z�I&1�#���� }em��ِri:�:i��m�7����)$�p#L�]�0坄��'y���o������ZmF���	Qh���E������2`�V
��I% V#����n����Oݢᛑ�O��ST/��TǨ~Bth�&���3��A��16���-��ꌾ��@7]�O(�����������+6yWB2�x��@� �Q\�F���8�sX+�J���CI[�*Y)"��̿xU%���o�I���S��N�)����&�Y&��j3a�|�o�Ht ?Y�q��>�q��"٩���a}�����i^�f��E�{� �:�u���-�`�H�q�EA�����v*�ȸ[���=���V�^�&N	�@���a龧<�숂�������q�p]g>0۹�Ɵ�<d
LS�]	�G(.N�rC�y�4XW&�3�5>nX�2��C�'@'���2"2�q�d�>neA�s��.Ď]ڽ��<ML�J9�x�:V�8�d��x^��/K���TB���{���}�D�Y�t0�]Mc��.m�}���_�y��-��(j�g�qëܤ�}��~f�{�]² j/���!��ϙgֵBi�W���uZ��PK��>�ؼW�ʏk(�+��Vw���YD�1�"q-��)��ث�+�ɍ(���>�`���F���G�P��fv4n��:�>nTgz��>;�ls![q*��<�S4�r�E�|��~�l����_�� �ֺ<�#�An+�s��8K�i'�BoT�mj�v�f��ћb�辔�g��m�>�D�I_�Ę��|2?�^�T�k~���<uÛfY>Ȑ%J�T�x��I{�V��m��k����UG�%�. .�99��}��P��:�+R�y/>8����}sD�p�C�С��6�L�|�QM�Ʊ��m+|1N3�e�0��;��OO��e��-՜�Sig�m���LPOV�Y�Y���O���W���RE�1�#Έ��Q[���e������4�@gI�!�~�㟞�H�����c��5���q}q$��1�Bc�5V̓� {n��-9��JL�3q������Vu3��g �C�_o�5��m��%|p���D�E5>��X���EL�����KJ�0�	��u4�>��T��D��+W2�'�W��>C�aU��2�Tv��I��)�)�r�]vs0��V�h��F�ⱖF�jF0�����=�y�7��8���5�,ʱ5��&��nFzƥ?	Y	y�RX5��W�e�8���]"��@-�p��^�w{gh&���00���/[�*\�+vP�r�r�, �U1?�
J���������<���������O����T��Mk����v=8�0�Y	�h�5�+YU�̢�L}��*�ѐp�d�IȐ���"���F����$*y^V���|IA�gjԿL&_��tkgC�%A���y"�%�߀�XDd_�;�@���5Aȭg�9�evڻ�0��2㍌�U&�Z�0�O_��?�Ȝ�p�Ǧ�+�=�_}q;�T+B�Ut}�J�b��WBC���ѡ*ܯ��Z���K�'8�^�N�Y����ۮ�z��&�o @�y��|�3�s��M���EAh}x�{E��g�Io�?����W��:��e�D|�Ǽ�{��Sd�!�q�J�e�$���_� V���"X�>�zh�D`�:���$q�
���B[J��d��{Q��+#���.L:FV��,f������4 ;��Ꮉ��r���_Y��G����_��KvҼ�*f�X��j5�Lл����^ܛ�d(�}�ug�i�r\�4]ǣ�!̗�^xN�0��KU�97g[cOk>O�\�UU���*������-Jr�8)�ʍY��p�fl�ck<�L�z� 

� kB#��k�Ṗ�-9��H�aɾ>$h������l���[������ݫB���9ˬ��:�%c�ў&�F�cl�M�t��S�+������&-'?حb��|��ȫ����b �?3�v�=��T�N�%DLDw��y�����}3O���As�gdG/h��q
�rܺ�l�Ԩȴ8��I@��-u��Y���&�siy�o�K�B/�7F>EJ�3 *�G��vk/�z���@[ˊJ��`���G$��	)�Tw�ؙ�l�M�cU�_�ǝ�a$���6^���7C�r !���P�"TO6��$^�'1"ܚ�&��!�i�z�C�Ʈ����pvK%# ���T��]X�lkz*/������u �'�|@�BiYâ�w��Z���/�EI�[�������3F%֗�(�����3O�d7|c�F멣�ų=���|�x��$+�id�n�R��c�=����0�;�8�<�u��=0vKt�:�����o���1�8�3���A	"�m2jr��p[Hq���B�D�{4G�GZFU��6E���-��-���~1�+m�S�v���E�q�Z�2�Y>�/�,7�!�+69���B��C	��d���:��
����}�i�K�����w z��&w�8�=Ϲ���>�
gXg)��r� �(L&�*�����l��潑��S⾸$�+�95��SJI� �k�$��ē�N-�1����{4�
!�tC_���/@m!���ST>�	�H�e�QX�N��E����c��^(��{���.y�C�s>�A�g�dʦ齃�G��U��ـ�P���HD	��>�ta��@G}�w<���5��|���J�b��¾cNԖ�/ݕ��'��K�AL��}"	���l�B�����pR�1ᥗ�c���MZ����"c'_Gcv_Q�㺣+�&�An�ÿ���k�1'��-I��KK���s>5W$h���]��I�d�s(H����'F���F��3�R��r�.Z���r�x���X��I��(T�Sd��RvE��IA2��&��'4��p��YFS��U~)�{�8�~�pk�����o���!ሑ�℩�������v�����Y���qQ�� m����VT� ���=��;=� ��37�����v�Qk��=�wEX�A�7�����?���p��C�8)R� �鈉�Ո9n>}��M`�ͽ����(яF>��-e���<&4���8ZoY��1��_7�}��P�����CQ4j�1�ђ������C��]Dۛƥ���w2(�钸��C<����Vk����]b���-����K�ƹ����꭯�V'cǚ���5��N6��h~�Sm��_��h�
��OA�y�9=��`E����M�J�[>�`�X�U���!��z�~b��F'z>Q�YK���f�o7�cV��y���a!nD��zd��Z�:,
�?̲�'�1�֮A{�/b�� @5�J?�f�'�f�+Oa�7g�P0%2�p��q���?x]}"[�sr W?S��ω�ɫe0m(ɇ�}�S^9��\�����7���z���G�����F%B��`����!�����B��W��xïR��D��#�fx�&۴ �vڐ�SD��7�.<V��d�������ٺj��X�}��w�#��A�p�
�Pp��{��j;�f�^�8zV۱q��[�`*�PiM���0F���y�
��P�=0��u曕y{���|�ѣ��={��U�j�0�SF`.�E�vei<en�ZEye{c�ZG4A�#���may�Zx!~Ԟ�|:�D95.(��L|�_�i�R�ǿ;��!�4�0�|c>|��e �.� ���6h���(yeplѻM����i�BuX�����aL<���n���^�r���V�c�KX�X�$����܊����V){��(w�.�Y�ҙ ��h�&.g*�̟����Wٸ���[�����>iV�!������g�&���33�NwL$� ���6),>N+I5�	łֺp�����t>�h�\ؗH�� o��j�s��Uqc���P��s���⺴ꍕ#e�l[n�p$,t�kW#�k`��s�bM��:t�z8��2'�3�<�QWʄr�m8gFg��]a�%!v�n�o�0�xi"KŊ��b'�M1c\s��RejMG�]��I�a�,(*}�y9�:��9��ڭKd���pu[���q�H
�~t�?i��G��'�������?�J/�ݼ�~�����EƱ��X��՚*|Ē����p��p����p+�t��/J��u����u0q4���t�����t5���� (Si6R,6{wH��<�4К� 
���B��Au0X��3���b�'k��4NȗG���)��a������."�����Vrbcd�`Xئ�e����C/� �K�`�y�H�!�5	pM�����i����u�^�39��Co��J�e�lwHF�kMs1���TgD-�|��w������3[G��3Y�7�\%8�>[d�ތy�aH^y=����PN��A3��ݶ<{,�zt>YB)`�������{�dp���Cto��jMq:����<�r��`�Jw�����2,��91��9UN	���X˷ήc͕Ͱ�_�ow Ѣ�����f��W����-�� �U�I�F�ڍr1aP(!��s�[�X6USn�'�.��2=��Ĩ�i��+�L�<�p7�MGc-��y����)SI��M�*4�w	m���B6ɕE���M�GԽ�S��ԣ�]Q�ꢎ�=L���|c�W_�8�<�}ky����0�v��7P�f���{�a�^��F�$%d\�!Sܲش
���t�rk�@�T��> ?��@G�dݝ�]��y��3��JL�9�����R���<�$��iG�t����xƈ)�M�E:BA3�-Y���!�V�Mr]n֒W���QN�O�!����15K�{Hfx�z6?7,��n�vV;��O�W���*H����|��޺2YNBD�&�m�Ce�rsRV!���j�m3�8":�J�W���8	qf
#�V5�2���VfYIp����$�f&*$/�1y��g/��;�IP�Z�H$�4&�m���B������������!<�yE��ļ��,�b`�NCj�U��4��˘��N�g�o��T4�{�L"|�M[��~�t?�G�s�0���چ)�З�X��Ħ��t%G���(�b��c�����b�����Jux9��½����Õ)N6A88�t7�Nd� s*��	�ϊrGb^���aB�%��j}2~Ю�������D�}Y��T	�VY�:�m��}��C�l�y��H\�5jU51SFϢO��=<�je�s<C�z�����a#�ۯ0�{%���*�r��Y<�q�d)��ֱei�N����<8t6]Npl�ST��_�G*�JC��d��^�~㞵�o�A�qtq�=��̻TQ~�S �jx͗
�����^���أ�_B���o^��P?_m�mӌ���=�x0>�d�೪�RD���� ��Ԏ��Do��g�sF�BJOs��X��f�����Gä��b��T
���u[����A.�(A�_�0��vBt�\E����"��.=�8�{��jl�~>`�69ha��q~po�J"�]�ҍ��U�z����I|Z[��΋Vt�)���v@Et���rU�В0���f��,M6�'ڧ��@����E�c��m�-�����������*5�=�̸Jg���k]�YA��393].�d?�S��ߌ�H���~�[@ͅ_�^�Z��6�q��	���X؎=?�Y����Vq��/��(&ny�f>2��?�v�v�"Ҟ��!�+�ME�@�ɫ!��H��� ���nu S�(�뷃o<&La
Y5�a��^�U|�����2JyD�eP�}_�T�5R�}7)ń�}:�Z�Ǆr�8��%�D���$���1��y��w�ϳ��q�����e���V
�A����KHn0����2�-A8*-���9��SF;��lm��)%�(�E"r�:�bٲk܊��~���Bm���I?⚨�����>�.�����<m�ee�{?K���b��� 7Z��2&7�k�6�����^l�Q���V�葝�;%�����9A��~���9�k�^�
�Я�M��L ��C�����Q�S�h�]��I�/M�
�RN;1zk�T޼I����Et/�_�AO@(1q����w.�����p_a��g�}~S_�,e�K�s��V�G�>&�/�?���.^��X��E���8�2f�#�F�ޜϟ�pa�Q!��N���@�ꗤg�^W6�ߧLd�֫�;�$�t����3ߞ:��sCC|�3_k�nI�1t�lq��D�_�Xذ#
vVl�޺S%�@��e��)���r�[�𮫛wn%��Gi���m�'�Kt���ou>'�)`��i�9�`�9��W�%���V@R^Iۅ��_ [�T[T�`��3�M� �g���Ϡ�6�3��UK��N��I#PD��k;.������25�m�q�&Cb/�� XJ����[ /^�H�$9���}�{�8���yg�z�;?�(��~�8����VjN	������}�i�b�O��&+ϲ�XM)��(�BfO�]��˺Vh���Ish �}�0�7����mbf�FH7��IY�K. �#����}? ����`��1��g�    YZ