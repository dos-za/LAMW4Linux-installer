#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="328369752"
MD5="6d75bb8b9301423e076050092454ecfc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20312"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec 17 21:24:19 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���O] �}��JF���.���_jg]77Fܜ��`�tBU��x
ߌ.�8�q!����p�i�=���7��򂭸YWPs�>'�����V�o�R :��s9br�T� ����dz[؆�p�����|1�@%��/TY�Mg�Hn��V�`���ϖ�����T��I�G7Y�;� �*�}�C���lBmYmV�\n�A ;�`��	*�}M�4��{+]�� ���VJ"� ��w�%t���*XJ+u�y�-"������f��2,���/㴗�\%����q��.�yg|��cx�|W�z�7���U4�z�N��۬��#������عo�3^@o�)u��;�^��i���a�oU&��jG�e��qN!P<�hX����%S����Q^��m_q�/�q�D8�gn�߁���06J7�XƧ���M�l,�@C�J~�*�n���3��К:<��j�A5�C��֩%͏���J���{�=��>��ِ�����,Z���f�w2<����־�����]�8�I[	�s��[4�9�+�}�ցy��ԐQ��c9/ೲh-�Q��P4?�cK~���~�V-�ܵ;ʫ&�����Ԭ�7���-�V�k�x6~?q��7!n_d����Ȏ��H�"�h�$��|i�����3_��#�}�r����C!ݎ�ϯ��dz�c,6ۙ
-a9��[�8���<�g�Lf�
v^%�ڒWAeu�yo!���A�b���p;�V(��!=P���.�;kN`_-�w:Ǡ�/=�>L�H��0���)᩿�CM�<�U^͌]�HC��؅k۱ �T��d�9!�U޳Z�郏ͨ�4��Gd�;+���g����\���J�_�����t�;��7E�$�x �J�{ޮ����m�Czgx��k����/͟�1��W�[3�t���q\�t�A���3����n��X��N�PU.Tͻ���߬�N��$��=p�����/淕	����ssQ�׺�I!��D���
��;��Zʛc�3w�Q��B�Y�Um��)�/b5fy�Z��P�pT�&16�Q���dU���!�&���9rB����c��,��:��7'�����J{�g��vB���	�R�e�!E��߰�AP+#GM��@E\89��5�^-���A�{A�$�ſ����*�@�P��$�=�NZ�AEfNZ���ˋ������q?�nmDI5-Q$�d��N�uȂ�;4��{��8(=�էˆ������:�U�҉ڈT-w�����ɨ�JOʶ�X�t��V,��;i�r]$~d�\�d�`�|a3�@Xl��wM�q&*��h�!j������)�Q@�5�B�.ʐ?�R��m�(2j�}Ϯ��?i�HJ�~�?�.K� ���F��>��ꨰ\���%m,�fՈz !eb���hU����ל�%�֣8������J4(K�^d�/������CqS#��|��0�������٨b��ݯ�;�H� 8K$C�ߢG���P�sB�,�Ų�����Ɔ������jQ̬��(B�!�!�2[W��@~�H��1���Z�b��YϘ%�6�����5��L��d�*XSG&wE�� �����!�ߺ`qQ\N(�&T�]��u��t"�Uj����a��\e�E���a���c�-t��:i�N���B3�z)h�4�$1�jh�5��e�`�pf���iSMV���[��?`2��J�|�F ����r�246�=Cօ���w�;��`X`@�/oG�9y�pV��jɨ�6pS.�������j�wMk�h&&�� 5�qyBWq�4�K�32�ͬݑ���9bp$ȹ�k���;G4O�_��#��f0�7���k��k��0N\/���G_#L�;�i�+Lbd�3��۰il�Y���i�T��F�#}K�X[�������(�t�l��a�".�<�P��$����ط�H�Wm�%@f� 4��hA�p�Qߗ����\�^���i���@���W�#�sni|Z۫�.��+��o�F����g-� +G��G�1��H����ᙚoD�����9�'� ��*#�T�+Ma�@�X50�?�0+j�@G��=�FHyS�w�!d#�uH�96�3�R��^�#�@RC�{no���#����A�WT�tX�[,�w� ���M���CP]5��x����d���l�E֫�h��^
������%T	����8}��۾��/��bc#.0�a �/�o��M7�_�[[�*���#͵���QK��De�uNȏn��E���c�N��)�PZ�w���۹5f��5=_�����&����M���ڸT���[8��
��"�T��4Oj���µ
���)E^��������]>r���7^��
��I�9�b��! ��x'�WRF.�0�W��2ݥY��r&�*����z؎y��h�V��=UA�H"�`9�Bm������齕'X�����a��M#���)Ӡřmh-���tS����X���\�;�2�ʹ3T���:^(��M 󗼕����`.�
�;��W��GT�+�i�y�uz��s�VH�[=��$Ok����[����Q+(�fʰ��eK�ݙ"2 3�����nU=����(�3���-��*1��.�pۘj���+�c����G�9yd���g:W����&Ll~H9��xl���n,H6��	�9�����.W�6}���RU0#�=��6GT] Q�:k}%�@5?v��[�w�����6=y�����r�srF�DX/���o+#����ibm��b��A�,7#�bڮ;xHb)�a�X2ƃ��S��>Z�����x b�C	/ͯ2M��6
���ϹܗoR��>�_T8��qN�@�/�)G���We�ABڐ�'�ܘy/�.�m�kI>O1|=��G���e�ǲ-�"�*l�Z����c��T��[$g!�ݗT
Q[����V�ۋ̧�W������Nsz��zv(��Ƨ��FD3��(�~D���>ֽ>6�~��M�9��:=g���V��������P�N�x�u���"M��_v2�q�L���]Π��Av&wb���^"��Z�̍IB�ɨ/�,���t���T�x�M�~����R
�t�=lښ�u�?�ۜ�E!گ�_�ܑ�Ff-Ȥ,�&����js[� >�Fn6�\���iV�s��z<p�[�ZibcK����Js=^܎T��J4�n4�t�U�Ճ	$��!I�ga�lEq�����8~�j�	������i�.���$G]Y��C�ybǇ>*����!*w��
�L�%�bxqc9�C�P�%��P�s/z���#Y�]������3�Y�W*�9�^#�%{��.��o�*� 3_QO۞;��'����a'�6w�������,����0�?\�ͣ�њ�Z�T�/eR���G:�r3�@j,���i��S�e��;5�6��i�nF�pj4O����)�a��A���؃���ѷղ�����Ǯ�Бѓ��.�|}���[��S��q�޶��@ZGU��G[���@uـ����	�v����0�������>��4(GQ$��[�z����(��r�1��rn>tW�uhs���K������*�#����ԦY0�q���?H3o���`�u���Vʖ��d��Ȭ�Le�jZ�������}�u�>��W������ ���8�uPdHgIԞxZ�jRA��N�zħ��$��:�^<����}<�'i���K�sI�2ݹ�=z���O���#7
2g͈�K�F�Bl�ț�j��j��5�� � �G�0���uW�{�����\u o?x_����x�����J�E-٧�m�A���W�.Јhm��G�!�k��jȣ��_�+��X]��w�(2��E�-4LS�����iJ�ź5j��%�������̋�C��w��@�;�ʕ�������Ӗ^U��rѩ�@��ST�n��/0V���x�]B�]���PN�<��?W�Ԝ}���*X�ռ@,����9^"EU�]�:���vրn4��|�w��Y�'�A@K���滧����vP���9Y&�36{�r�uYS��9g��׎;�A���"�LA҅�͸O�9����VO�ø� s4S�ꪡ�K�|X�#W�`;�$2W��ƥ �/���ߦ��)Y��4y����,d���
rGX� B2/r�z��r(�g���%�H���1�&mn�:��C����+ӥT�Va�3�;Ğ�B]E����^���];�j���-.;D��p����_g>w%Nxq�S��ئ�������y̓�Ac���� �y�q9s�j%��*8,7P��`�ۂ�fTB�ކ��J��ʆ�OÞ���+������?����I�L�6�w^&��o
�� ���[ɾ-^�D��j�JN���pDވα���s�gwV- �(�h�=W��Ԝ�~T�AVI��6-��ܒ`�������|��HE�b�1�)4IG�̚۱:�B3(b:u<}��8z]Ӊ��@/p�4�M����
i�}	����?���;-^n��ʟ`ѽ��)�3���U�D�.���̏UY�^Mv�j���aVR�����0x郥�u�D��
�3p�\�r�ٔ�q��%�) ,��ʯϤ6d� >aҪO߫�����6r��$ ݚ��A��g
%������U.�6�2)����I��?^�^|��Hu*���'��Cl~�ö�}�1��'Yz����A�l��q���R+wQ��?��,��|w�-E�[%�C����/�B��C��@B}�; w����_�N�܏}e{v�><��Jh�d��@����}���RvO�ӺHy�Y3�eg�ɘ(�	������K+��;��h�!vO���uV��T�
�U�p�:Ko�?���E�Y�8�i��>q_�3�ި�l6�'cf�:��
���i"��i4��	0m4��Pr>�p�������N�DԾ�=���4�s��ޣ"�qb�G�42�B��������ya�rG����̈́�O��gS�Vh#X�-fz��ԓHL�Xo/�.f��uK��o)g�d��)��s��z��;+�;-�y̛���ʂ�� �(�8�jkڑ����"}}��7.E�,o}�s�^�s叇�t9B���� ��A<vTWdzy�f`g��3 D��n����eZ]٧	?�Gm
��Y�MZ�>�v	�.{�d#Ic�'n� �\bl��� ��PW�ƞ�y�į����(���/�S؉"���5����
�������GE���Rw	��%�Q��4�5-nZrb���KR����f�!&U���8~����s��W�p��C(�lQZ�U�_Ժ�<T�[Rhܓt����h�c֞G#����g�h^r�S����G���}��[�].U�A73ϙ�w�C��B��N�Y�}�.�%��Nz@һ�
G!� |N)��*��0/g����_�ģ��)	O�bm��-�V��ʡ�wjxX�V��(����6��雑$�����9a.8�l�4UΛ�mM{'��ܘ���O���Y
��t�����[�>GVJ�S�_�
�<H���t�	?�ьux��vPܗ[�05��è}xN��/��n0N6�g+��
�E���2�6+Z���=�&~c���sK%_�G����K�Iw�ྠ۲���!�/��NbF6�M��3KJb~��8"ZH��v��ۂ�f���F�7�j�^s�UȱH�i���!���-μ< gku/��g���=92{���!8|)�ӳ����xx��G[�Q��V<����q��.�i_Q1�{��
��aDxQ=��]���L�8КT�5N�x��t��]#ϰ|���7����v�6�t�a�P+���`���lQ��^>�>�����׿�ZD�=�UՃlj�FM��������u�s�ρ�A��X������&6��z4O
7�dn
�4��t�D���7�'8�z��*�f?�l��Vn0���9��#G��=�y_����T�y;1)���?��jw���hJ\XS=P�[r��uMd�k��n�b��}�\�(F���� ��g��M}葺[����^ׯ{x�K�!Wr����'U�9�LKصB)8��/�u���dlMW��ǹ���ʖ{8��S�d��-��x��;�H�[$�o��u��u�	����4%e�ӹ�re�F�Ʀ�8�� A�
j}��m�7�c�g����0f=��~Ǐ��1B���X����-�+t����M��uμ���� ���L?k����:���bV�D=���V���v�(��T���靦�YUo�+�; Z��˃:���A+\N���*s�D��K��̓��ŉ�)=�%Vx��Z{c��l�7�U����tI��g�^�<+�����pެ�e.��Жdd�c&n�N������.*�k�Y..Z�	��U���w�\�j�[]�h���Ϛ��TH2�����������3�f�,�N�fS]m�T�O��6���B�ہvy9O�^��'��dro�VloZ����9n�d��8��4$���� B�%��� PX=�A��0;І<$ֈQߪH���yn3��s�4�7-p�����b&V�f��aڛ����b��E͑xlJ���ak��46`OR�������Z����?XW[����A3G�*�owB�����8����qV��g�1��B�ԋ�%�$�K>_7����Kx��؄p�&�
L#d"�]N>>�A���j��3��UF�e���*s���ϭ������h��^���\��d���w��mo�8�����V&{j!?=�)��n�m�I/�V��~e _r�*7�=����0�3���s_��H�Ww���̸�i�Z�	��j)^����v�J*+<4�OW	�p�dݨ(%21�g���_~��2��`��ɛG%5l
�e�qo ��Sf>[�������X��/�GGV?��6W2߶��(X����vO΄5=���o�_$��������*}_\I��V���m�L(V剴b/������|k�����69]fΡc�&�J��×�_�Q�FS ���E?�V�.zk4(Yr�o�Y��BI�p;�! e#/+%1�4�����As�#�&��'��[�4ˌ�g�<N��(a2P�%w�~���9���&*��78���[��ɮ7�D?�^cmˑ�xqlP;�g1Cܣ�����D�r�S?�zW�t9C�D��C|^$ב�Y��n������ѷ���h��k�A%h�dP����?"��z'�����!�m���=7������|��A�aqU����ވ�N�t�>#6(�we�R|�BH}b�OӤƭ���������Yr���'p�s�n��P���e�f�i���Io�R~.�H��ټ<�`�CC�R���r�V�әyGy���s���CjJ;�f�J��a$�b�;n�0lf��a�ӳ���k|����DQ��of���C+ �rі.H�6�2���-_ſGfZ�Z�=Ӧ�>�[^�����[,��\�aJ��`��8W|ƾ���=n���s}eY'��vxo�-��H�P}�#$�kv�lQ���mF�ն�Z�:JX�[�T���d����fo�D�9^�56Y���Q����	�',u�	�M�p�g��
�9�z�jh��`��Ę_6�T���YB�zL/x{�gJ�\HJ�rM�"&B6���
a���?�gh?A�ί���J��3B��ɍ�K9��̳�i3�C-��
�Ł���T�'��\�[�9
���<y/Ғ�b0	n[���}"
���}�ݐ� 8\&~	�`�6�W¤��PCe�Ǻ�G���^��'+�H8i4���c�G�W7/FUAivX�	}#�*M��ǇQ�c+s@�b1б,���m(�׬�*-����i*O�|��N)�J�x��p�&�%�}az��@F:ǬrS���z�5X1��#���2�-���l�>�t��1�ɸ���o7~�� ��V��rW�h�hn�U��Z���E��>�{I9�������r%Y�j�[Sa\��\0���C�����pMH"T1.#������~vg�����mU��0����ݑ}Gu|�u	*X����uv����`ACe���O~������9(W�p�B��q�;"��z�M�H�~��j���] z����S��MZ�.�61�a`�=���'�T���u�X:��Fӽt�(�4&�@+�َ<�ֿ��$�L�B�'[�|=������$�녝�G�~6lN�_e'V��D(:�p^�|���%ƪ�As(�+��OH#b>c5�=9�l����8��;���s��A�a��+E�:Ĥ~�}��>��@;T����"��4��0���A��^�<�A���$os<� ����Vn5N�>~�����{�gi�<�6&���o���=h�b����q��
,�S�n�a#�'��<qn��I�3����B�k�_��h��jS�ݟJ��.{�!8a5rC�{���NVk�0\�K���Q��R�FH]�<�ѡ'�
�:;����9��w~���� 0�����U.�hZXz��D<{I������x�a�dϑu������:���K�;�����Ej�(��a��u�}�I���
Q�s�g��8#ȁoVhH}p�~��,&)l��+�<�5y�	.��0��
�t���*�~i�umr�X$I�Y\�����*d�&(�KQ�F_ϱ�.-x�>��{�I�N]��*䶯]Ćh&�bs:�[�'����Y�4�%L�����k�?�7,!�����UM�S(���R@.ѥ+[Է�k�\�<� ��`�Z���p���$.����f���R�F~zuh�=����hM�K��֢�:������}�7���#��R����tH��W��%��
7����1�Q戮�$S|�^��xlc�A/��$ZPߍ~>�Z���0��XB,§�Źv������~��_��VX�X^E��t��*�eru��`dp��d�q?n<�pt����Jv.V�"� �7jVN �NE���D7�p����r�8 ����]}�����(�X��ʽ��W���'$�3�̹�ɥ����Hƒ�*؆���X��G��(d��Ln�+��o|\(JAd���t�&	:�A��Z��x�|��k�>����bRŃ^�5|�F�ߝӵ�p�N(:=W��(�Q��Y�ك��˲Nw�&UB��k��s4��x��I_��	<�� G]�7V�=���.̹h�0��\����--��/�� .��M=�ģ�OD��@um��%w�S7�j%��R�ta��leo�G�1ԓ4��G����yN�����l�g��*V�0m�)m��+���æu�^=C���Z�݇� t�rM5^q���(ީͳ��¡�w�:�'�[2r�8j,S���=23�c�+u�����h�g�8�(�2ptR�41'ly"����t4�����8�鞙U��i#/��`1��;A��:8�	Z
���\�J'���ϱ+%aG;�e`U1X}��Syt��M�2^kXD���Bc�	��/ݻє��zCJw�>sT&~��Ѕ��1n:�|�bi��. ��w�����P?εT�6e�F�r����ȓ��K�-!�}%�F�$����́D�^�}��:F�|Bh��}Z��az�Ӌ�>t2%�&�Ϗ2�P��(�V�~�Z?���m���XhT*V�����3���Mb���*{d5|l�0D����ox܄~,�A�*�Zb��|.�D��X��B�4��"�e�H��������V�������#�ZM�^�>j˭&5��hg�uLO��W���+ۉ��"��q�j�u9��?+���r�ܶ�t����}5be���X��t�L����--SwN�IOG��#D)�)ml���be�ݚ�E���'6�45�v��W.�9��w-�1�9�$���n�'�b��t�s��>ޤ�n�Ӂ���P�{׽㉾��	�`{����1��q�e���bNy����a��iM%<DF�Io	L�si�j�߅�oh∭C6qz�f�C�3f~q|&�w�:ҧ��n96y�R�[�F�����r�F�e6���Lᶭ�;.T��`�H!V7��R!�i7~��%k����u��l0��8�Aw��&��D4u�0��wפD�_M~�+k^m�Y�ǐ���z��=�bpjQIOs���_�mY�H�5b���5�s�(Iq1C�5�r�[�AK7�㏪綵g����k��`��B�M5@�u͍��|��9i!0©����c��B*~�M6����5��O�LL~�EZ�聟��,kc� ?���|/��e�Ӹ�N�YN����~c&����¢րf�һ�#����IQ5�p�-�����?�e���I�D�
Ε�w���GI
�����̾��w��o1 j��@7 �Mu�iT(��cA~��qF��DR�K.�=�Yp���rR�2,�t����Z9�:Ԛ�'��r��±��4��dP�~ ıJz���
U�	$o�n�gU�E� wв	���]]��<j�L��[v�In(e誔�2���c��.�B�]:�G�@>��v��`�8:��vL|���&��'�f��}��{: &k�
��`���N0oP����q���ۃl��|hџ��8����8�Ɋ_���p��
�:;��>I�$�i͜�-�3���N����N��Ќ�f_��Fuz��}�:�ua(0<2Mgh1T�L���)��]�%��ۄx.q��|���.��$F�9��E�ƕ��O<J�,�I񞛻�v�� ��s�M,�(���2�>D3vJ���b,�T�
)�^��	<�^�r�8��Xq|�v�y����m�9��D7��6�+�F=-�6=���6�*�G�`b���,�6��5��ٮ����˰�d��Y,Eg���N;���,�>�ACQh��(�ˬl���ڬ3����3�>��{���L��UKkN���L=A��'��Q,,5���$����8>G��c4���8`��c�2%��TF���	[���78?�yz)<���l����U��I����� ��j�:x�R�C��|#X8�Et�G�n�����L��R�ͯ�#WL�:�����}$��I�?�� ���=�n�(4�ث8���7zN��=j���<e^#jJ�j�C >QӐ�c���m�
� ��<��59W��xd&����X��Ԝ�@�P�b������L��0��������M��������VO9�pK(A�)�M�
��V&��J��;�lz@�m��M��{��t���D�g��x����tG�F�r�l���61P�����a^&`�D{@^.��V1�Z�|�5�n�[h��1dRX<���@��	*�5����i2Ǹ���Zmx��~ABJ�H]Ui̳�l}�"�-QGI�.ߔ���;��G����8�h�E�o�qU�%���唘�*�l��|�8�txa�>�OQ x}�f��ĥd��B\#u�^��ߑॶW&�Md��L:� ���U�[��,��HRV��Y.Q�A}��y�l>��&��Z5e��{�G����υ��ryS��a��|��ju�ՐT�� ���5�ҿ6#�f]�>��<�7�[MD�bc�+D��+�J$e9���ik \��)m��|P��F�@��;s�}���� �H��2$a�5o�ᤶ~��-ݽM^@�GV2,�	������N�m��s�F����@H0G ��X{�@ I�Ӄ�^�9��0����y�ٌ��!�7 �����I��b?\#�,�cH$�:Ȳ�MS��^s�="�6���* ����� �'�*W��-L��p�?�U9��g8?_lxF�?��Ll��rֵ����n��c
�}���d��{_b\��b��C4\����9��㧄F�ٮѧ���h"��(1��ˬ�;�GW\�����
�Cw{��|"v|/诫�,@�_�@�Xf#s#��C����^��j�9A%���-�|����w�ՠ	����ӧ����h(E����C��Z����{��%
��M-aȃ@PB�{6��zN�R�I0�u4/x%G���S�lM��wЙT�Ը%�ڗ�s(��H�m�~�����7Q����tb�c�B�L��#{t���Pe�4q<�R�l��|uz�h�ߕ��d
/�C��Z�,u���,,�5ܯʌ��H�H^���!m���%`	��/۞w=!TЄ
E���y�\�Z����������G)��Ҷp���~�1	I3�4[���5[=��=�T�Ɓ�[r���
ֶ���I��8Ɨ�������J '���:t��85��EU���RQS	P��"��{(z��>�yS�Vʾ�^�L����{B�6�W���fV�+������=����ne�]�FG���1���ׇJ�C���"�=v9h2�(GKT.i�����k���f����r��`3r ���sAiN���nj�lS �+�
HӘ�-�,1������>H!�-�a�������C`n� �@��6'p��� v��;�Y�����|Q�� :ݨ}�rڤԜ��%8��&�����9��=l�M�EnT�����{io|�2�D׏� �ӳ+"w�����H]▪�ÍV�z���F���*�Y"F'�1"�(��|u�tw�XL�%)6Q"x��H�3�D�&h�� ?M�A0x�bQ�R"�E� �����!����r�|��j뒖��$=8i�J�X��IPe� �z���i�$NA�>Hw5Z�cnH}֌D�kV�1J������g��qzi4�
UV�+�3S!��	�;)�bk�L��׸b�z�mJi��W�����#��vԐؙ���pֽ�M�E'���1���	�Ӯ?4�$���&+�Wl��I�����iI�i������"����e줓	 �"bvɻK _G����%>O����g �	��V ;r-E{���ͼ!��}� �?A!R+�Ϸ�c�;ST�a>�8�=�2}�#N�e��,�s��'o��>1���22���W��_��W1��o�iW�+nl���v��&|�N1B<.��8=7�`�a��cRz��d��|N�`�ƕ\v5����Ѷ�|M#��u�g��sn4�.b�;zvD���o�y،P��;��sO�{�"Kzty�_�Ff���`��`���v�y;�K C���E���	ט�����d@�^^O�p~�캝�Ű�ٹ�a�[�<_��!�Rj�	=zk��S@���bI��mk[)R�9��C��C��s#:'��BAz���a�D��^-�Z��.�$ؤ��{�V�����d-_ۻ���fBOԪ7�M;�����^yP��N����߾-Z@s����ȧ�frV�m]Q�(#��1��T���#KK��
{`���:�e}�6�	s�Ij �
�G
�5-���N��'�9�X�U�u7����i���0Ο���=���z ��^P6F���{���W���G��}�~.,28�/�#����ﶘ�F��U��U
��e�w�P�TWU�1��axY֊�OȈ(�D��m�G��*�d[A𚻯���<+�߷��7�����.k诜1�苹R����Ie��W�<!���_`9���V��Iw�gP�D�6�o� ����BI�X}X���x�a��jb��22���b��x�[H1,�?�B��_͓�q� �k�� 3�!D d�BT]W����;�]ޙ݀�b�)�8�%�)9�L�qi�C����i�8s��ǥp"II:X;^��P>i��&m�z r-����D��e�� g���ԙz[�OdP�)���D�˘�)�^ň��3)�7�?��y�����T�5�x؞i.����PѢG���F���!T��
8��a�v��J+d��͚��oz�q:����ɡ D%]����6CE	������5BA�j.���AO��8HE��'�ǥ�d��e�:v��=|"�wu�^�;�-��j�)B?���+�߃�p
<h���LyK\h���!���БX��ml�^h�
Ne�u�爁�C��@ {d|�<���Hv�pU诱��+V�!}�,"�`s�!�XO�J�5i\b��d�U��xcM�ϐl���&t���ͯ^{�'\պC�L�vd�T
����G�k,/�#D�����������;�S�e�R��j�?G�~A�Fć�܈��_?�&�/瓳���Q%�:��`�����l)���b�)K;����	4�֠��3��y���wm���*��.,[��	e%UM�+*q��""y;��� 6X�ͭ�Ztג��c���2w�o*�t�^T=�]s�����������'e�%�C���.�ht�	�P�0���2�g�L�\���Q&��ԨC�?>g�6� p_EBY�j��z����<$RY��s�c!�s���0W���pm�'R�5�F���A5�Zֆl��8���4�\�-�^�3Mƃe�w�*c߻�6򆄕Ò'�[���%)�����7�7�ƤM�t�m��6�d����B��(Q*:���'���}^o��'���C)���Yz��x+{�>��������]��si+��������P�����f�����b����m���]�ٙy��mwQ��X>�:�xC-[p�P�URT�o����s��m��i���=ʋ��9�7���$u��0�Mݶ^��l���`�r2�ߥi3���&�"��UT��q�1�٦�SR�>���;��<�/��sqcbA��+���R����8%[8w�̪"C��2�a���5�`�H��D�,3࿳:#D��N���(
R�@*��3��E��E��ߐ?�@c�	ژ���[k#�Ȥ�Ƙ|����5�p�A![OM����b�_8��E�k����6���j֣���vt���cI�����oɇ�x�i]��
���C�t���y�a�C���C���h��pjk
N~x��Q S�E���B LYf��`��^�?�������*�*�h����U��p�0��Vm~q��i0�pF~�m��~�~��ֲ�T�ZHY<Q�yl�b+%�4�ULl�oY;�?��&�����-Hu!��X��e�!0o��{T���"���*��2��[�xw#Z6��d��I���i}��Z9RT���G����(+����&*V������J����sBJ��&�x�^xs��7�3=��]0d�,"(b�tdoA���X;���*�v�[�|�Zˡ/᜝A%"��+�ٙ2����� ��(&fɘw�%�0�N>��,{+%k��5Bw��Q)�:��B�!r|�Z�e��jͮ!�*z�S	dx?�q[���P�@��/��y"ݛ�p��~:lpހ�(:����X�&�B��6hN�C�䕨�4v�4�1�O���}}�U�e�g�o�*�U�|�h�Ͽ���\��%+����f�A?J�A)��V1b��P�Oq�Ȳ��ћ4��6����P��&�Vpj�����VX`��$T���i�|��[B�b�7~G)W�Ǭ��a�P��]��h?mS�I/z��.��8�m.�U��̃�R�$<�lD�������A�s:��8{���30����,������� ̖��0�5�'��ۥ�꣺�\����)�[I�ojߦ�J!H��U���l{�gZ�˒��ܗۂ4,$$f��ۄ#Ƽ���`�d:`�K	�$u��e�C䩗g6��� O"�m��B��h��� ���}M͓p����a�DD^�yR��zw�9-=0y(#�O��[�-$C��@���HP�=w3YO�F6]�bi�k�d��s��
a�}�&��f�c���(�����Rȿ��s�e^�ভ����j`���ŗ�戟ƣ�{�j9���+'���Py'�kU��Z2	�(����gD����:�"�����.�풇^W4b�o��Pz~.2$c�j}�əyc�9���f-��^�0cS�O'�}ƚ2b*~�\3(i�.�p̆\�~e��ר����Gk
��#��q�+M@YV����6���@F<��r�G<w$�4~�:8KT1�ȉ3!l~�m��]t���w�g����i׈�g8IcS�`]�8�x�t�F����<�%���k�,�6M���Sލ���d�b�o�K���e@H�!�i�*��3���Eؾ�V�x�/ۏ�d�?j����cײ�y�Ϥ��+�n}�ms)��<�!.i�.��Q��T�j���C�t�Q�,�����qQ�m�����X�ƃ��(���)�ea}c��٦J��IZ�Uέ����sF&�����dd�Pdz	 �����K�����>M�����?oB����AM��\���,�7�/��VN�#�9�����W
3$���IӉ?";�U�	�R)U�>[u�a�(� xj��#�R <�\�(�j���!-q��p�n�8K��h	WdE�p���U6}J"��(�Z|���L���w���_��(!�D�O�c tz.���T�TPG�PlY�9����D�֨5��޹�l[U+�o��f���r�O�G�A� ���+>F��K��1G���7i�;�:�#�)T���+)�;�|��|�<��ߩ7�47�e3�eR7�6+zѼ�6`��F�����m�ee���kB�*��D]^6�D�Rf�h|��p�	���-]�?�%����_g��LuҪi��w�	��6~�֤MW����Q�-��DN��k��T���h!]��Bj<
��ly L����<c�%���z�dg8��W�H�lIV�p3��w&�u�����y��!������Pĸ\��q�U���SϨǁ^��oM�z��Mi��L�e'U�������������z��!���c�԰��6�ڵ��e

�|�{�2S/���W�G�%:����,[��\ �in�9煒�B�<w��h�g
�hC<[�?W���M����{�k����__��c���:bo,d���]�H�rα�7r�Pτ��bOپ���"I��c^|���� �S%��׀���|ؿ4�k)c0������{��b����c��vX��%�<������B���Oa���5i�\]�#̓��H�@��ڭGM���#28>�Sb1�N��9�b��t��A-5^QQ��*p�0�&�`1Ry�f��ū-a2��x�;��E�^6o�c)ksF#t
��!:+Y��)���m�v+�'Nׄh5�t�-H�"W���(l.SR'D*y�;Ճ�;�eJ�1c�Q/T˽�&:��NR��<M����^ah���(:��&9�y!s�},j�]uУ78�֚Oy�Vxr��CK����x\]N�S,U
l�b�e��B]���R�O3�'�&X�A]R�0�|qb|�����7y���n@c���ӟnr\r���,�s�|r��s��nq�d����"���YX��>�P�rp�nRIA�5e�P!D1Ъb"�TC���og?�en2~�ɼ<�`�غ�.����Bd����X���n���ER��灈���ۓAo'����6���
���=�,���
��\�q\Ư=1\�#n�\��/���l�ߒ�2(U��$c�{��l�D�\�>,R��ah^�@�I�<����dh�+����Le�|rv`
�dX�ء����4���<\̏�K���D�aAS$t9)ʅ �No�tQ�'+����҆�1��Ƙ��Z����6Ȧ�x��ؠ�_+ʳ�"�(5~^���:�_�i�����El�����A���6����G\VK�;$����B !�=%��	�b�֜����%��S���r<�F�|	��N�>?�_"q���aM}�.��v���0��E�(�@���l}�a�Z�3�D3�<E��`�=��M�RMݣc[7�Y�z��j~��l4L�5�����!�������D����\�D�v�9B3�xKvC�)>�P�d�"��zV�����p� �.�ɈA�]
\R�IQu��Ǎ���9x�ՊD������4�|�#/mX]uH=S͵��W�oJ��8�3�|`�G�-�ϖ�S�iW�肚�u;��q��]t\����-R���X��,�PtBQU�bf��S,|B����\e}���U��A�0�I	8�wb+l�}��Q����[�ɍef��Q�Q�M0R�����6��@��t`dx:�W1;�C�����$<-h�����Յ*�Hq~aڝ�� "wOǌ�e�HH�P�R�g���@J����t��;L�䣻1�<��ݿ�E�1y(�z�JHns6.e)+��G�p����  <�un2c̃r�w�x�*��s�[^���5-������A���&�%���`R"&N�x��@̓���=�lwG�v����fQ:�n�>�t�G#+��G�q]u�G�H Rʏ��Uo��2;8.�f>"8'�+��u�mxtjn��?㾨�6  <�2�H�MxgR������+<�=������FǼO�yIj⏼�[�[=��-���T�d�qV�s?�����/��K]'~p:���Ӄ0W��>� ��%IMe˝���_k���Q��.0���$���M�ι�r�	o���:�F5�Ï�뗹�g#ӠDBr�
�y �a:���b=�,����0=��<�;��E#U��C�oAC�Hs*\�:�oL��8���N?��5��>u`i+(�d�f��Ji/�`��؉�[�=)��)����v���BnZ�::�&�������c����b+�e� ����
=��P��(���~���>�De�N.���7t��R?8��;��� U�w��O�8.�Y����5#܍�j��E6&���0�ڣ>ܑm�V [$�GV=9la9u՞�80�B�W2� }������Q�&I4���y��)Q�U ӽ��a�(��`�1�+�ƀ���y��5�;lK�1�C=��c-����5+PN�� zQx�B�6jw��7�/	M�bN��˻��������h-:�K�m��Nh�O��F���T�̃`�u/i�j1�^�}Ir�F�Sf����4q�`�uS�.ƀ��E�����y�� ƧZ��E<�̅�L3J"�Is`ps�0k�|l��
��{�@;����S��6=?<A	�f�Yf`�$�y���JY$$2������S������$�/e�У��;��K�q���fyg}��9��ߣ&W;�+J
<K����Y�"��-J��Y���|ߎ����5�Q|l�I��V�<b�D��;� hhY��g�Wu��Bi���@�ؒ> �qO�r���U4I���Z�bT���
Fw�{-4���MS��p�;���K�f.$?��x=&|��^�5��Bܻ�~�DL�&�lظ��{�@�^L� σ�=|-uD��e~>��$>bq��ю�9��X����x $Ί¬�Q|��A��`�JZ�9v`j�x%�iz�| �ï6�ں�C� Jt{��E�^'��;�G>I4��k̴ ��u�����mɃ?��-w�A�>�H�[!�Z?��+I�kM�vpw��	C��uX˾��h`|?�+��� +q�5ŷmG�s ��7��n�ts-oQ� ����\bD_M�����4���×x�E�5:Jy�8�_rX?!�7>�#�r�6���xj�[�M{�������͞5r �x�!�u���" �g�Pq��v���J�aG��+��,d����Aj�k��05��2DU��`�X2M���j<�x��K!�y��I�}"$oh��,	`�!u�}p��H��`�6������+��,ﶳX�fR��!^���N�:)��p�<R��Q#�,M�� �.�Ji�$�v��t���=T���~Um��a�^��w|>�D��嬱��]��]�|����Q���I�X%����V��w��E��f��U~�ʲ9�G_F�5�����B�*c	�;�5��\��5����e��͋�nE>x�qf�z#��Y��    ��..�^g� ����뚌��g�    YZ