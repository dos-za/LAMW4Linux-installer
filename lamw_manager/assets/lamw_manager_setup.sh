#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3055651537"
MD5="d9bba2b17d62b860208f556c332bbc7a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24736"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov 15 00:15:32 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
�7zXZ  �ִF !   �X����``] �}��1Dd]����P�t�F�Up:jd���U#���mε�/�R��^���6Mt�
 ���R���:w��s���
��#P��,�m��i��u�2�1�#��=݅�y=R��m�9�?l[��B��=T���9�������|��Ht��f�/Iԅ54O_�L���l�V�W7~�&I�4�Fo�J%|�i��� Q��+����*��E\�[O�0T峺���')�pqD*��`c
�=�Q*�6(���/�7�:9D:�ga�xsS�3��O���MJ��X�v�Q����}[�5��hc�07�t0��V^�� %��9Y����Q�c����k�"��N�n�Bf���{m�)�1N'rR����V ߣ͞��aq���B7�0�^ΕU�e*�m�2����8��O^��Y������Ȉ�4���� �~:7H��LR�}�h����%���m��)<�.�awI#�G���.�0��5��q�+����&�{�ì��)��ɭ�p2*$����J�G�M9�_��@T���_1�.z�^�I�~��x��O��Oi
�W�|v�Nںᄑ�O�hzxJ/[Ab,�Q�Hv��ļ�"_����e��;���&�ˡ�RɩI::�r����B��x����CH�]�k�W�d�"u�ٶNZ6�C�%���z\�g�RŞ���D�fD�%I��
��1�xy���}��Y��A�j>��+�?_W(7��h���S�_(�L��tK�88o���rQ����CKGN^���Bmc֩�'����ѶZXX�A��m�47�����%=^����\�!E9Xj-�I\?�tx��`�_�cǣ����P��3J�������.�K"��^�R�QsC�s��gF�=�qGQ�DV�7HQ�|� �*Ί�*�xH�ӛa2]��elr��I��×P���o�B�|K��+A2@���V�Cx4��?8(�wW,l�|�gg���cIϕ3\\����<��n+�:H�M��_���F4w���ǀ�	�Oa�����o���	"�p������U�J6/j�J5*Lb��Z��z������R_��ʧӌ@$�CРL�I�g(9��H囯4Ơ�v�.;�w͹�O��?|�`c�>,SA��N���.џ�������?%KҜ���W�(�t�M�(�x�?�^���j��#�̋:[��L��~A�޶"�lٟS_��)�#�W˔���8��?ӛ�	EAnx��&!V��Z���g�
j��Q�9�ŭ�d"r��G9������ƅ�zRw��-W��x`�~~������FV#{l�3X�-F��z������O{�bp����;|�Nx�,ݤ�tA���it��%.$��_U��W#e[іf��;�
�� ~�_�s5��͂�X�/B��%^FH��[�v�/YJ���n<Ũ�*�X�Nz���0aD��ٍ�<�FL؛줓
2srW�3�ed�Ay��A�JH��\�哗��7��Y.�]L5rg k���W�&[�*A���N1���f]����x�jac��
%�t�^��o�%Y��|�j�U�Mr�c~q�8���!i���;�p]�����@e��;�f���+aj����H��؂�q�f��֧�a��6���n�0G��R2L��c��!+��ϓ����-�:���(.A��K��v#d8Y��8jۘ��t�ҙe+����Mv����ܖ$�qU)T�Ề��Ψ�����/�E^��!�d�)v�BЖ��g�d��&)c>D�_p�c�O�h���~V�^�]����&�⾎��g�ŮTd�q80
��|���V�9Z�8��_��j?M'�ά�9��}~���G�C��K-�s/��eEG���R0k~$^ϋ��|��;�^�h�u�����X]��tOw�6+��Qc ��O�(�j���-�8�ҒStd����O��x�0�v,��TLG��C ڤ"c�`I񌽛+��Q��Y��7PA4�EB렁W$'�n�/��ɡ��U��x�0I� <������s�5t���h@��\�j�x˾)�8/���`9W�n9�Ϊ���ӷVa�y�|�v���ևo�8�E9������՝zCqU����@��'�[$y�ೊ����C�m'�����B�e
��zQ���Y�1"�&eχq�J
�Dj��<"+�l�,����BԼp���'E������z��km��L�&�i���������;i��'�֛�B0%���tlqТ�)�E�Nx�L�!�0�r�8���V���2��4�}�qQ\�Lh�5�[RD<6�lGw���$	���Yë�|��Zk͎k��tTnzB�ѷ���r1����v�߆�j����d!f�`��GGH�c�`0fvD1�O�`\ne�0 �b�%@kK�Ɵ{pW�-�8�b|�L\�����4�>�|�o�!��
6�0h�J�ȼ�-wq���iC�6���b�Ši��P���Rs��a�e.����?�2�U�R����_j�!{�7����)��|����?H1��8�(*u'$��S1�e�htZ�J���Z�1qoۦ�G���PJ�[I��wv��P'{����`��c���E��+���#2Bp+��D: ��pJnX�p9�ϨV&v.g �@W���)�Bv!��OU���P?��1,�|ḣ��|�p��Ѫ=]�A�nܫ�����'��"��m��$P�������9l2Z�|=Y��LeM���w�i�|�Jς����l�����c�T�z�A"�5��OZH-���",��T"e�l�i�����C�S�3k������aٱ�ﻗ�倰8dr��_�t��L�� H�0���@
e�}�b��>`+��t˯P����h(Յ)Ib�I�d&�����՘]��L,NCEND�p�lN��YDv=�%���d����2[<���W<LГx3�O���ۅ̊C��׾HZ��#pU
 VI�<�&��x�$yd��@a����;/��~f�T %��A��� h��*�Jڷ�:{j�����<���3�"p�X6}�$����|�-6��n)�TV�;L�~]T�����g=s�ǒ�Q����V�!�nT��vZv�u�"gTȁL�^ mĢ��H�%�!�]F�v��M'�_.�d�+��b(�& ܔ����l[�E��)��:S@ۙ\�VW@i(k��eH:*�VlT�KH�%�z�S����%G����`�[��o�5�M��x�<���i��쁃o�j���΋�\DI  CW	͆������W ʊ�SK2 �=�]������'��>7��-�vY�j@�W�NJ��l,k��Y�Q�2%m��ug�S�f_���$V�G�g��$���tOMKD�.]����,�Ia�D�]��ް��S:�'Z�Cx��3l�D�j qQ_����UD`;%'������8�W2(�\�����|3�("P�/s����`���OA��7�������Ħ<�L'�c�j+�����֊ٖ�&E�ώ^�f��U��h�����J�h�]�z�!e@�*���o�r�����Թ>*�r�o8B��,|.���������C���|+�3�+�0��R �[ �$��|�GyM�=*<���&�p; F\K`��J���l��ϧ/!�E���l�`���l���V�55�����j�m�(B>�Okp��%���î��v��f����3ڀ��uz����g���q�?���٩�L/qP�P��ɢu��[���,TO}#Ʌ<����K�i��w�p�b�[\W�Ƿ�n�̰���3l5nfpK��xD�W���� ��ܭ��Q�K��yzn�%
,jէ��-�VJ�k�`l�U��W{��Ԫ�&�ZnRY��5?�W&n�dƯ/l��t�W�����$��lѠ���MŞ;� �r.% F6Cn�[;_��7�8��\
�?p#����	�i�z[{z�"%hY�t1�Yfzl�\7۱A���O�n�������W��! }p�������	2���B��h�j���3+J&*��h��3��j�Uii$?�z�޺�m_Ӹ�����]8��Π�t��<��zهei�kg�_Y��NV�X0[8�\_�	�uAȠ%t��I�\�В���X��>���"&�@)�՘^d*�1n�7�BX	0�ŻY�Ye��R?��]C����k;�6i@^Q}v�B�8���/~1y��B���Aw�nJ��ӹV޲�<a�"1��In�S�ϒ�n�[*����� �������e[���E_۽S��I�k�}~��zo@`L� =��N��}F����$*��\�%�_-Z=�x����1�b���s��8��и��^�{�6K�a��v��* ����m|酟���b<�`�������x̏r8�R5t�?��۬"��p%kN�E����A!nċ������e`e_��b��:�Cwux�i���p���y�΍��z��q��\�N���GU���+e���^�]�o�Qg8�A	Tm���UB:ۥ@��gA�	��S���tf��^�B�'��/��x�lo���I�� ���"p�C�}����,�s$��|"�D���mA��^�%�՜۶dD��op o7E��0Q��~�Z��o|h���j��v.F)��>k$S�,�ǧ� ���N��)Zü��_���np��M��5�Ҙ��A���h.�jp=��s�3�׆A�sߥ��Ω�|�g59�vE�9�]O���VqΨ��S0nZ����&���t)�>�r��m��=���2fX��nnH�G�E�A�O��t
�lW3��6�/�O��[jb7;f4��[�>T��>���{'����!e �]��Q��pj7 ]8��PRX?�(�7w�X�WL%���.�d�ޠD�*�!﹐�	q�`���2���$�.�UP	��R�c����ȱ9��9�t�P��P��s+AjLkl����6���M�?,
,����Eϐ�R�'�`F+[�jZX���A�y��}���c�mO�yj��\I��#���ܜ�������^�pax����(�؀Z��V�XB9]4E���}C�<�ǹ�L�m`R�*lT���� B[NԜ�7�IT;������ �{�+�Ve 6��&TXVֺ�db�PCv�]�^�ҟL4t��Ҡ�/Z�c��Ѳ�����^��1[7��H�pA$�H���{1�ZY�v�^y�nd��C<A
��4UGJ&���<#͒�C�D��H�8ླྀH��j��11[z.�&��3�W�ɧ�:S(����c�r���s���`*�%�$;� �<-l�A�4��g�R�('p�%��l�|�����l��˦EU�0��G�^p�P�}sy�H)>��o�W{��C�k��.�pd}�,{-]obu �{����'@��یFJ�|�i�|�4����� |7`��;�y��c��~U�!Ȩ�q�ITF��#�GD(�h���1J�S�x
�E+�����_l�MͶi�@����K6'Y�7��	�:h�U��k�rb�p��״1c%d��rK)- ���
��-�y���B׿�
�G�.~N�?����:��TYhJgG�QK�=�P�7?�:��������c��\�b��H#"7[':������oZz�zE���ؒha�p���Za=n��<��`O�k�=\�4X�-H����q|��� L��%��cƆ�h�9��:����qÂ�p�.8�Xf%�I(�[�E�bCË�ꯣG�*�vܣ���>�6���+�&��X��i�����(T�e���B
	���FZ�0�*�'�-�B\|­�fp�\����u������k�/��]Ţ����"��c�F�!�lڛ��+ ���,2��,��&%��Ȑfw ��)t��Mp�:�y���B���j�V�e~u�D�fEJW0��sT7)�>����T������f"I@c�}����2l���~�	kf4t��p�����Zw��]�i�S��Ս��8��ǣ�ա��/�us&�O�GS�rj:�8m踋�o����ޕ�����x0~�I"��/�]��	����Gr)D�xƱ�"���QIC߈�+l^�)
���q3�!mY����7&��tfO▕<�{}0�w&�@9���5�U!��J�@�?��=F��pI�!��I���,&����9��M�lȮ%ݔ{ퟝ���J�������UKCpe+$�K��5.���(��wJገ�e	�U�ڰ��P�Q0S3{��F�Q��&�W���p�_&,��A�^��]X��Σ�y�}j�70���}@���^(��~Չ��&���*�#hoZA�Ժu�-�8�51bbH���)�ަ�ˤb��6�	��]�G�N�~Q��8f&zǎ����~���Bi!5X0�i//͆�7j�
��j�P��L���%�G�[�)?�G�T�׳�������T�oa1��	��B�
loz�w'Qq�RҢ��������+�|��
#2�n�����7
�,.�k���#B�&;.#e�d�_�`(B_�`�?�;����i���'I&m���k��iEI6�9�����@엷�8��F/g<k�-�"4������Z�b L�ӫz+Y�;�-lB��U����R��鐮�J5?�n�8��F�R�e�W*ͺq�Hoxӌt/|��9�im)Q����#G�D��t)*�t{~vF-�s�����gT�b���4:���)����0�5l�K?�_���bF^_��������sGd�f�h֥T���V��b��]��]2D9cƒ_�=�I�ѷR�}`���z2aB>9�)�!c�y襱M�f �/FBf��m[(i`F�
��*"�?���C�'���*w�_�NdQ&���>�./��@����ݝ�i<^���&�.�G&�娢c�wC��z0��q-Z;����Siy�짫g�|��S�Ή[TGEǍc;;�'_E[��,2&�%�] X\R7��2E����4`٦Y�D��F�iS�Ι:v�tb̾0Ǟ�!�4����M��d�Ts�$4��,M/���q�'�����ĭ��w|E3R��� �rwf#�t����u�ƲB@g�&&�R�Y0P�0�gp3-�8���ȄNKa�}�8�萌�1X����^�W	*E2�l	?���(H{�S���R�&s��ణQ��4gMΓS�",Qչ�K��4{�� 7�u�[��K=U!৛�B���P�2e��+�iH �^�{�- �^QU�1�,��6Ȁ��y���J�|�������d���/�K�LZ}�d@e�W��U�a�d���
V���d{!{��a��&�
5CCL� ~�u�Z�;x��q����/1$��e���HG�g��ŀ�ן4I�Ȋ"� ���F�宨�"��K�@x�uVWcY~	�#y����9����"��.�L�������m
8"��#cA���3�:������J�	���$��̐��A�����T�9�1@�{�p��'�w(H^aíB"�(�2g�:�rP�{���/�k���{m���Êu%�o�ĄX�:1�goc�:W�D�$8r.�d_̛�;��(�)���m���aܙ�tP�@�U�f�Xv�qrmX~�����v�F-�پ֎���ˊnc�s,�S)����N��B��B�+v���fE�`?%5�Ҁ��y��f::FW{e���+Tڂ�)�.��趝o�~]A���*[^��.��~\Z7鶪{�cAe!B��#��id�XJ;(,���р���[�k�{>�_^�g���K���[j�0N� ���y���'H��%|Q��CȽ��*���sD���kr̒�]��A#�1y��؆M�eMdq�Y����^1�5
�yJםȃ*���멣��'��zj�]��y�g��4�����?�+�+ۘ*ʬ^nxDa��
oCuUQ<��h;��T���W�N�]�>��K��UȂ6�νy[���5�QOd�;���TF�0w>�Z[R�.���y��Y�ޢ�RL:x"��5���ʕʓ=�bg�W���I�h3�fy�m�2�f�OS!y5�/�E��gq������ɝZ"�~�XJ�Svy�]��l�cV{��~iu�
����5��T�[���Y�_�w^è�:3�_���[�_����S���a�|�vW�q��<���t���;%�f}`�2�}�I]�J���&p m	q����ܸ�## �*��ʢSD�v4���������*�x/��-z0��Yv����H��1�����,Z���Oh�Z�������xw��Rog�L�mS��/�D8`����o��-�h��,!��4�W�t�8t���2�T?�;�ˁ7F��ee�PY)��>}�Xמ��#3 �o�gbJ��~���ک�D0!p�l���I���*
Tm���Q����
܋�n����i<M@�8�ڴ�����`W�NS2�z^I4��K2��͑˔�YfJj���u}����zf���,D;dw�oѹ��ǲ��Ή9Ģ�Zk��)q&�ET��̞�xT���e�,�t�?�;�x�7������Z�����E�q9g�9����Awr�h�Y�P����\Ti��.��˷+Z�5^Z|�������XX����Ժ����q��Hbec�wJ�.7�	����l�A��sd�	�ӛ���Wam'+ZKQw�,�����B���D��!Ry.oi���;�[/�f�ʁ*`��lzVv���I ����D��Alf�Wđ�3��i282���=	?
H�it=<ŗ�����d�_����z��b�:�O�Mc1�����Z>C�7�Q��z��"���f�����*S�j��	r����>��7�if�L>F�T�y'L�&�ܬȍ� �{�$w�����?��A�Y�U�����; I7���:P70��VR�����`���*���c_
�����Fy��W4y���F CYK����*AS��o����`�]�gT��/t��W�2r� �M����!U����.Cș�:�q$������`F�4
,�}cꈍ&LG�����g��(�
����$�)!ͩl��x^֓���s )���3��w���	;d��0T�']� ǎ��H벏e�9"/���6�YhF��݀�Q1��1��\����UTCv߮B��CgZb	ZAp��k�l��+�j�?])QZ�,�b��"-�v�0��7F�y�K	
e��������ˣlG��M�D�#�H̿=�|Iw��8��� �����ەӊ��_�5��㥵�H[�'5��]tfX������T��g�#e`�)C�e�+D��_	�L4�u��؋TWދ���w�I/2�j�pդ�>�mBr�F:����M�\j�)��h��bo�*��ʮ��iN�K����?O����%��
k��]�@̌��D���թ*��u�����(mk҅��Bf�&��ŏY�� �����l�@M(G���>$�w�;��1���Y2�*`���xk�.a�(�O�9��
� �jȶ�n$��A�d����=.�<.����&۾��,�/2�&ߤ�K�6����}"�ĵFT�	���:|�b����&���٨˛���qΔ�R�,�G��H �L��
1�N"8ĩC6ʰ�?ޘ�
�,�X���vű�����5봋� ������[�5�Έ)���n+U\>�Q��vJqt��j�LHn*�г[���R,S@{+(�rt@�R6G'����|�Ŝ���!y*F�pYx����U�HD��� �c�)�K��1D(4v��}f����Q��`u��Kpr�b̙�ƭ>}�}Л�z��_�ܚ�(�|��e���ײ�bF�Gdۓ�A� �ǡ�ř�e������8f��0���e
\��lPhz]�S���@��N�6-�@�@G�C����	y��VE]@x�݂�e�,W�B�X$��²�6��`��#��e�}:�������Puzsa����֫�K<�x�W �c1�$���V&CA����c
W_o�e�wt>>�G}�3�N��U�ani��{&W�uм��T�����b�7]�hu
�݀Ք�~��W�� /�V\t�T9G�a%�y*�3�P�ϲ����Ө��^�S:SA��g,��<������WO��M�`�t�I�6����9���ED0��D�U��*���U���P9�wv�:�2kS�� �vSvܓ���_�^��Ph����%e�����>Rt�&E�=��f�G��6T��t���	��� /��B(�dG�0�������<Gf1�!��1���U_���O����VY�A˶V298�B�H���|O$�#��K�_�wps��ԡ|��ܝ���|ES]{��1:�#��8�A��;�ȩռ�J�5��M���LLp��t,�S;�Z8+(��ir��-t�?��Ш9j�2mu�Z`����B��ms����"
:��T>i�r�ˤ�.��E��tG /�Ф�X��aV޾�e�	�!����a��8av�O�<`��"��:�����G����G�\-�G�L����WR�j:�\@��-"��U\�va���ς�o�m� c'�AgNG��s� ��i��9f��8��v�>vG�}�j ܆�b����ɂ���w�ā�U�S� K��1{�
���҆�Z��m����4a�U~�ન@�{<��� �#0"
8{y�C�S�-:>��*?�����P��d��.F;�����{.A�����͌�`@	��:���!k��f�CK�߆q���`����f#�Q�F�Y��iO���$a{]k͆���@U��������̪0f���-qd#h�o����j��8\M���f�I���LB��
�|mGI�H�V������ �νޥS�ď8�������9B��P����J�=6I���PP�<�֕O�� H\�� �T��R=��y�F�P�m�+��Os�m����!i�a����X�=��Y���J����F�yDqV�nZK����N�TO��8j/��,�2�#����E!/���J�gA=�b�U��я*�<��F�r~P'Y)P]U�����!$�ϲ1M��n{ӂ�)ٰ��V�>i}��e]�x%4Yo&��0�8�W ^N������B$�Y������3{.�������Xv�-�a I�Ig�BB-�q�v=����+ #�+�3"
���b���]��FS��?��j9ư4�:� +��(xQ����7�%�\\�l·3�1�t-聧~[��ڂ	�n	h���`Y���L�H�:�Y߀֭�U'�9T�Fk/�U&�����0O��p���螒�DN��՛�2�]�Տ��v�	�#O��Pw^�~���}+�~"�����[;�X��p�x�"��
zQ���g0D�ߒ8���� ,^8�8��P_i��m����Yܚ�{9^��/B,���7*K�gf�>5��D��D~G�����R\��.���;�<B�W� ^H�B*0`��  ��I�H��}+�s�$?�%#{��6��g�-c�Ơ³b7p
�1	ȋޏ�^|����<2.��,�/����&Kz� �2�?�)���zꊭM��� s���>���nO*�̩/m�l�~��3������qM���&�BA�]V�D:�q����_6��z��Q*$���I�0����JX-ڧ0�4�F�w:Ǽ�m�ȃܭXQG��ʕ�ڶ*�L�����,�P<N�]v�eOS+Z\�W���7@��@��v3�R���2>�`m�� z�ԥ��0�A��\'.;�D�`��ޢ�*M�)��W�)J�wC��濇U�N�?�)��w�1�e]��%|ZHw�_�q@����rF��x��W���p�A�h5��XŜ2]3���Z��ҫ�����]e�)����i�fؚ�Q�����x�}J����u�Gv�Y�G��4��?L|�f��7ܰfe��>�YXp���!/��1	̿�	1o%���RR��=��A����m"�^�	�kQ�2O�U�?W4vT��Q�5��W��&#s���oW9�#Ꮭ11��vhanp��aک�H[\ˆ�b�o$�#�ڝ���?w�|
5ƼO`�Zm	��#m�����kn×F���X�M�j�+����j�7�s�K@��Y��FǦ�-����/f��K{IB��&� �jQ��
{��xc������_$a��W�R���r��Z���`q���S�G�~.4A�g�`���R���7�� q����ba�����s�Ÿ|kj:� E�����a��qpb��I4K�UQɤa\a?f�P.Z�(N�^ ���kCy�ٳ��|���8�����:L�È��x�
���=~2����;/w����v����F�h�.�\���Z��.j�p���;z��H�պ�NS_: � ���Y�#�9i�Bە6	,.%H�g���̞�Ƴ���ϴ��НY`�a��V)��/&��]w�_�-�� q� <T�z�H�X�M���+�^������*��?o����4t���dr�w�˝���A~Q�9�'hm_X����)5��8�MKQ+1�l�A:{\�楩8�+]���p��KEeg��SH���iC+c2I�8�`nb��p��i��D�zD�S~l���
-��fl������"���i���� �n���{vq�K��dp���/d�Z�|� /�|џ�O0������s�
�:͆��\O�h�{�\F��3��ya�ln?((���f���.��¨�b�)��0�������>׷Fu���6�)A���g�9��H*�Jτ�N-d�(�UTz����pַ��?�Ual�M7�t�8�QV=���Ő�vL.��>�-g�T.y7��Ec�z�^$2�uP`O�]�S/ť~�b9�A���\�$ ��lL�t����k>3��=���k�-\!|}m�)x�m��=έ���A����6��|2�LQK�Lٷ��oQȫ�F�X������ދ�*S�^�3K�ëH���-�^k�C�L�R�M�:&�ɥ�ES1ξ�sW���3�WGjY�v0���@�.�8_>�!�z��{���NZ�=�g��Z�"ѵ�����L2t3dcj^���V�E�v��C� P�
�`�����	�ꂿyAe���L��OW�O��%��}�x:��n"�ǸWv���>�c����>�v~L�P���F<���2_���?��r��s�o�Y]J�=ܰ���Y�M\L���&eļ�q�&KA����pXΝy�~8�!�>�-%�{��i��7���̰�V̷�\A����͔O�ơ�)1a���b˾=B����g�0�כn:|��B��1�\��h��.D�Na�?�;�QbJ�	��'9��B�k<���@p�f�*�H~��MA��\چP5fT���8���z��QH&!H��g�r�q����c��,:>w6���<�q$w�v<��>u({��f�/�/�7+?șO��Ok�#�'�(�[zל��K����d�^�e/��.&�{����J�'�z︪����:K��eT	|��C���XB�7��I�����x�pk��?�(x��-�3�lC�-�7����qEy�J,�ۏ��6�Wr������kA����[MN/��T���)V!(�T�p������ƣ�ؓBY�ӊ��z�ߜ$4 �������c�2m�cU��I#��qrI���v�]|V�p�6g�<qG<.#���s��S%�?隧Z�aߠ�9�@����H)��w�M�H؟�S${��92�E����K(;ik}������ Ge�%�>�L�G�V�����L��(�	\����!=�B�����yf�ݭ�ݜ��pbt��rk_��Ö�?ec?Y�ge"7��7��рނ[~���Z����;���U�t��kn,!�
��w��RCh�h�Z�h�q�S�����1����m�=43���� ���f�<!�f.�'#O�r/��^S�N�,PY��}��J�/�sxZ~�9�U`����8�����!�X'�e��8o��D���"��
����[�j�a��F��ci��L��o+ULƋ��!/��^�p�3{�w��g�4�h�E��ІP�XP�ѱ�������A�m�i�p0�h�"�/@�?5k�w��@H+6�W�HIf�W����\,W
!����ۈ~�ɵz8���n��đ�Sz]}(Nwe�һ!>�ZhV.8p���c�Z{/�w��_�9g�t Zj����<��1���PW
�sɹݞ�m8�|�X�IB���)��uC�<"��w16�F�+^��M��V���i@��j���X������,3�h-,Ѽr�����{�ER��N\yE��Rn���^��h`�/+��6���a�R��.�r���'�>�  ��QpF��	��L��T!z�E��j���l�U6RSK��_��Ҏ�7�O4�<#�0Z���>l�Q��S���A�(%���lS�%��T[����b-7Gk���@m���J+@�A��B)�~m�rȊB���)Y�m�P�|p�|�M?��ݬH��Zgp�k{�ۇ��.?�i�}��Uk |!6���K&tn��Ǚ����7�m�	ly*v̩���=�N2��2��Rq]��9&?� ������_�x����u0��)����N`��hA���LAx��pV�k���h��c"}[�n�����fz�o.>{�5��1OYV��sGS�U�B�%��T��p��,�+����v¥{ͩwjFM=�Z^�lY��'&
S�ջQ�m;`�`s��QK�d<�WO��A+��uv��ŖGAf����+3�ȍ�&�L��+��]|z*N`n��������6�o��Χ�Bg���t�OӥI݀ۤ�y�;kK��q;���i�d�?jܛvg�`R̥K����'����^&�DR��)V^0B�",�;��fZ&�t�Q���J�KQ	���ᲃ�	q5����K3�$���y����nej��Bk|E_����5ʷ�.��4��f� K�!7]��t��0�o�S_�>;��=���7�t@�$�Jj%�K�"�6�V�}�%�jF��ȓ'�7���[���h�SB��:�u�T��趦Ud�B�tq
�vc�� �򵸒���W��(ָV{$ũ�Y��J�2ӫ����$�#�{j	��l#�ZQGGi�8K.W7.��j�A�=Jiz�ܲMv����Ӻ�� r�K�-.��u\�@�˃%�Y��&����"y]��G0ڐ:궒6��.��نP)����YԦÎz>8����4^tc��葔�]�X���-e"z�=���PpO�0+����D�GX��j��F:,�"��R�������cS�Q=�!��."�B�!	1v��Q�����H�U��# ��[�11�d���@��3v�SS�'�[>y]u\�'�?��m7�������Uq���	6ךVj��=j6�䐊�Q�mr[?�d��"��Nd�m)oq6!���Aߍ-?�I5=0��f:��B)�P/!):�$��E�t1�(p��&�n���W��zu��hc���ʛX�*;=�؁a[pv��O�����jB)�U��_Z��
e<� ��@��aˊl�V�`����D�d򤏇�.tY�5Z$�������g6�{9���P�tB<��$��\z����Ƣ��d�-{Q���d�r�v�A�O?3m�b_%�y��b��u��ʌ�i�&���s��ځ����]e�� �������ŗn�ݬ棭���U����˚|JB�M	x�6�:z�BU����B�I�@�O�w�O$C�(U��	%�e�ս��3r�p�ȿȟr����V�xS�bZJzA��e�-1��)�����y�ozV���*��������߱���f3��D;��uR3�]j�n��r�}�
K�P
v��R_F� �Ef9��דKm͑��l��S�dϗ�QY{0&l���6"�� �L�6�;��94��$4,��Y��=�|2��dfo)�� m�Gw3�Ih�}���lRH�-X'�BVcS��y�0�FZ�* p��D�do���t�[+&�Q���X�o~�rZe�	[8T++}O~�݌�X�{D�G""�n��vz����\�7~B��c��)U�y���w�snԨ�z�N���kW���q�uX��QJ�p��G�>l㭬�D�UU�rЙsGHm6���7nqvc2֒W���#�
Ϣ��B��rV��U�t�2�[5:����h�!�_��͏��A?Nz�ބf ���8q�M����c!4p�n��P�S�Zu.���p]~ݗԊ��NzW�h���ϋ��L�r���%��0X'B]���M>�%3b���$�W9�ED�޾���hzb�4vyv�o��x3R
8�4����%��۰�9m���辤���nצ�
�4���/�����s��I'T���@�{�
;@k~� ��JP0n�Oޚ��]Z��$�Ҕ�"C�����%=�G=�zH���6~v�:�Cb�1�ʽ�l��@-���Y\.D�������'����|0ށP�7Ο�z��^���	=Q��n��w9�0�y���A���K@f�.*�B�	
�O��y�=:OfFBa��U�$�f��	��cAɓ��p���b�|�I[��Pl�#���P���� �zI�z؞����"���o�1�9��q��~<���Ľ�@�s.���k���Ha����L��"'���m1���z@?K�����:)�DP-|�0�_ �Yd T���\%���5tQ}�\�Mu9w���e�5WAzZ��A�D�]�����@J�=�(�o�뽾�E�����{v%�E�]`��{�n�֟��J?��7�`�,]��p��aw��yu�Ń��f5����6�}%D �T_K3�y�y/��+���^}�;%�J߆(;�Zߵ�IL�\5�?"RP�L�L;Gd��U�XY/Da��Y8jE2�����{ 0�h#�柦hq��ĒA�bBNzz��IjzH�U^�����c�*q����-ĞVA8���k'ָ�Rr^ ��$+9��CO���\�3��y|�`W�J��"u���GL���M��,�f��s���QJ�����E���R-��)mL6��U ��n�����P�1Iq������p1#'u�:[f�妋Wo���6H&{(������������I9�-s����}�Sf�᪩���&�ъ=�3]`����A7υh���!�̡��e��F����!֚�nw�h�1�_���=dRC������~�l��!k���Ș�:^�;�-��vn��p.g��0���u����<�)�7�����Uґ��3.��M��hCԒ��rr^�<+B��
n��]:�A=�A|�'��ך+qt"�6w]JJ4#���EͧF���2�F�ʡ��A��[蘶���Fwa�Ʀl'��]�M\�L����G���Ժ~z����!���Y�m��@^�Q:5��x�P� �X��	�j�u~Gt�w��7^=.K�\����,;���ǣ��'=�#M%���}~<�#Y4�7����!��mLK8)K�'!(���6L��;j�@�M��D(sm}�HTzr	Y.���3����N�<rZ\W�j���
��pb�x�+\=�ˉ���\P�^#qy�w���l1�ɞΕ4_��5���G�5X� �v$��1�Q� f���J�bd�9�(�#�du��V�a������~��B��o��Nbp4����#JP�'��}���d���1��i{s,E�G�AB�{�q4ˋ�]�sp�	�Hϖ���9�іAُ;6��^zK���a���I�`��< ��y�{ �iDo5�f�D�rk|btT��`��U:{��%;�V��x�*uH��K�Q�M�P�Wjp�n�R�`YUݭ��ܡK^GSpV�w��c��Z�����³c��'AMn�<-��s�o�j��n���lw����-�����>�پ����q9��F}�ɇ��z=-q����%��tKT��j��;�n���!���2筥��܈$F���B�����<{]p�yN����x?�(�wE���
ݛ���K��f�����5�����e�m�n�s�x�T��ʮʴ<	���9 T|�&0-�&��:h��ٰ�ٍg( �[�<� �0���,f{�s���k����6�K��%y��t�]��2��c�>��]�.��*���Aئ{Y���F>Ҧ6R�0n?�bǈ�!�zaH�#T�*�L҂/&H��T�yb^J�ECN���&sܥs�ǯ)�h���J�?cdPLs6th��Jt�&���aCo��}D�;q�o.`�<`��r:�頥g� N?�k�@�"h(�E��lfN5�s_+���K3	�W7g�:`$|�}��9ь2QO`�.YǛ��ė�~�๊�Ƌ�;A]hB���8<�߫N�i1޾b�.�}+9A����i�����|�*��ݥ<��Q�#�z�� /�W���x6�C�f�W���cћZ���m�}��d�R`%O�
�c��9Ӽ��B�8���O���A�)I��KE����E8��+)�D�����]C>�����v�u��&T>�
Jzl]}9ҝEv0�-�A����:6�\��+�M����y'��@)�x�xB��.� ���vF��Z:x5W�@�8T}���i��d��z��p`Ӝ��-�h!�Cۿ����ai�W$�Ak��s���@�2�W�@'v<�У�w܌˙���R-�t�l4��9wXrM�̮=O��k,����xO���h2�B&�cJ��&^���vQ��[U�΅����9��<��$����*��OIqe:b�'���oU�ڂ��;xű��x��ݰ}b�_	����ܣW�H��2��Y��,n)�HE�%��;�&t:�9QjW�Nf�� �σ��	�l��q �ek���l�4��H���b/[��j��v����"���)��;�� Ѳ�2b|��qy�	P��QY�Xi��eϟ}�_2ˎ��;fyE��v��_{v�9�"�h��Z�1�N�QqžLP�!�<֫���9Fn
�d�W�9 R`}MbJh�tر�F;B��/�*jF~W2-��γ&�r��n���$��(.�yY��
7@��(�Z���+���ޢ�kLxW|v�+@���f�G��SK��i�	��3�iݿU8NF:h�i熶h�87�V� P���[��"�|6>�~*����ᚹ��i������<R�+���>�0g���3�c���YH�חh�J+�Z|J#�~>v�v[H��]h=Vrp�@��&�)��1 ��E+o	F�o�'��q��)��ӊQR�������MMyf����@�HV뛽3�6cܱoA�ʖs�תLL}7<kt˫~Hv0)o�����j�U�7:����P4g�\����+vg�
4N]��d�֊߅R��]BQ裫D���C�į kJ�*Z�a�*��)O|븡|�Gț�I�Ŏ`ZصЉ{�d!�h����JCV��,0E}i��D�s�!(�0NQ��ARjd�G[2��],�I~Sw3��T� �M/5��S[I�x��{�į������!�,�je�����"x�p+��LP��*z[���!� k,|�yp��ș6ҹ"��/���+�X���R��@d)�$v�m8�G�6�=,B�=^6N7ݩ�UwYc���t��C~�!Wlv����^����ɩe�)�BE�`�͌��>Q��4�I��)�1�,�nO=f�	�xr�.��=wx�LN?�@-����V�����������%�k�M��A���A�Lk�jD(/?��n�\i�B8�*,��r�C~?5��s 	�I㘎���Y���(����o0 I�wmG���}نZ�ȫ\�v@�L�9�] ���Zl��	(��:��d��2i�ڌ�pAxAD+�i�����p6__W׻��+N��<鵵o����#���]"���5�s��0�U�d��,�t�CLA����3��ϐ�okױ�I�X3g�GUx�n]~T��-'4���Tx�CEB��d,�4�|��+WUי�A�hL|�ݯ�xN�㼓 3>b�:��:��g�2 �r��
<�N�j��7 /�D�2�#6>]%���V���.LM�� \yv��Q�[�zj�K�W�"�@�"�ԏ��4�X�<8�8ظ���)��+�0�]�=�,��JAܮ�	�$:f=n_���`�"v�jy�����iW0���-�0vR� ,�n�Ɣ���?���!&x��;[�v �r��/,��A>5���v�����QB/ ��s�Ff�}��R�ۘ�z�|2I�3�c1�=�LnXD�`�@�Ќ���k0cX����ٛS
�>W^��2u+�1�t+�Oɿ�����1���b�v0wy3�uٕ����6W�BÇL|��<����lw����������;��m�d��}���S0�,�m�����Gj�U�j���M��Y,@�����G�E���A[�ي~5>{I�U0b}< ��mO~�:F������.j�_��%zג_�R}�j�^"�� :������-��n[���S9�鴌�r_c�k}1���;l(f۞a�n�ܾoܦ��L���U[�z���s��F�b��%��������{�cF����5��S�X��`kƗ��L�;d����y��L>IV�]�]�8��e]���ْ���n?v��hE���s?����p$2�oo}�P����E�3��ۛe3c�kF;QnT�N������}����T��3^M~�"ԇm(�+�D�A�����WZ�J.j�ɫV>
�>[uا�*$Z�Y�UaN�?�ـ8�<7�"��������C��PX�w������2p����ߥ�7�A��_[�E9bޕN�m��f@*�6[���������Oc楧U�9�bڱW�*;��<�Pf�!cO��b�Ojl|����T|�;�$���x,iAZ�i ��4���LC��Z.���4�p�F��Z�A�r��:��t�h��\����9�u���K*�U�U��L�x�}�Q�x�g�?\=�a,�Y�����T�ឬ;6�Sk�J�{ �`t#���F�D�(��Pnﰙi��V�B�>����I�c��%fO��]����x��D!�]`��X|Am�w�ص��  ��:��{�B` �V&,U�aȖyپg�oHp��}�x�p�S��۟�64Q�	k�Wf3�B�0k�U��m�]땹E�Bzڑ�
:��j�b�8�����=�k�0ͼ�8�LHb����i�u��;���*�.f{8l5���-<����V�9�b��gf�\�h�9��k�j-�C-v_�����n�O;H<������ztx�-x����să��0�����ٹhҘ<����ɚ��b��
y��}�\Y�|�f�����]d�|t�F���! �����qfg9,(�;!&��5PQ::����<�Bu�� �Q{�R�i����Ɠ�s�"07��oN�o��;a�%�L)��^#v[,�����S�Gu��v��-٠�vd��I��>�r�V�
�����Q��[a�J��+��� ��IfD�R0��1o��.�������:��r$4Z��-� ��Y� ����-9�ٗ�i�-�~�ս#���+aޞ������F�����8�H���m�qJ��P>w'F�*�/�W<to����,t1���ٕha���[�<�M�+0��OʸQo�2���d��h����l��d��<ﯣ:J���I�����x�eܼ3P���{�o�2��ms��c���ү�liLp�e��w�9#7WsϺ�S�ZG�(�����I>q{��x��7�����
y'���ݍ�EJ���H�����Ѹr�8I!�$|��V.��T	��������8��o�h�I�\������ ������+��mw�٣�q߉O]GY�2'��k�s�	���5�
��eqŶG �N'�sm���k�o�5���L�<��T"(��F� =G��(�t�����T2�
�AO��p�r�'lb�h���t�*��s�J�� �����3���B��t$I��K�W��� f>�ǚt�md2�)�AFŝP%� }d��
15 �|�-�D�Ɨ�Ӈ]MJ7���p�4b"�=�K<�#�I�v��./���{�a�B=S����JV�����<��`�Z�s�H�:�L�<�aM�
�ISZN��l�uƜ����0zF��N�xv�F�2=a!r�$�H�F�nU��@��m`'O�\V�{A��&���w�Ìn�>����_�O3�%�E��a��%ztC�1����]���i{�_���4�����j}�溡iU��v����D"��en�v���t�B�?�:pb��L7Q�Q�:+*bm���o�և����vT(\k�5�)�2��6�"��d�t�`���r�|>Z[/���4���
[�qy�=-�D�)R�da*p��GG�!p��{������(�%|&2o��'>��֒��&���	����;�5A����'c�*�z8D���Xdض	�Y��<T�^7[%�Sش���i���p�k>h�]*G�P��f�C��'ưY��\9���× J'��zA�W5E�:Q��4,�5�K/�;��P��3��s�aݎ����:M���7��V��	|'&�W�`��2�uQأ�@��?�Z|�4�J�ڱo[�I��M|�E�b����^��GJ�N�Z9P��	���ە<�x%�-IL@j,I���3��vSíg��j��^w�;櫁 Aj2���!��Јc@�����m��;s?t��٧1�3qx�\Q���j&�|urf5_��n�����U��r�a(ޓ�<0��_L�c�����^#��8��i���'�w�_���;�K��¥�<#!ͯ�J��(�*Ξ���|����8k�'�S~$8����l2�Wc0�J�(,2���>��5�@�٭$q�G�u�ABz��u�O[C��^���G�0J������</�z��`����:QI�gcf�T����}gػ������$�8߼� �R�?� !�)�y$%6�T�j:ۖKBQ?�q��"�-7#P��oy��a�02�a�{Be{��4��7��Œ[h�
0��d�_�����U�z[�{ؒ���betօ��q�AI�s	�n�}#��b2�X���z����ǥ����L��$�����z�4��s����JÞ��Ӌ-c�G�
H��&w�j|���uJ�t�#���������H��0��/F]ɂ�']�"���ǃ�idI�n�31�R��ǒ�~%&)�C����.z�hyf��D�����F*}K�>�2�����b�!�3�Q�5G�^�{�M�}(�8�S�c�B�t���ӈx �G?.e�,�\�\��5�\m(Y��n$�3@��SDC(\P�C�z����q͑m>�B��.��{Ϊ�GP�����[_PpC�Pu��o;Ef[XNҟCj���'��}�Q��+��},��:�4�(Q���R���a�j8�I����W�d
R��E';�z� J�g��N��Ho~��%��IBA�s����}2�d)�O�6ҁ\A�����?3Q�kvB��f����֮��Y�8ū%��;<t�U�3'h{.�O/W��]�%��e���/:/f��S�e=Y-�L��H̛,39�z^ߥ��_���l�E Lv.�g$� ڈ�ј��w���[�~{��~NSa�Pc�\���z�8Sr΋��Ɍ�_0��Q��TA�a/$� �(|�w�1�}"ӹf�*�P�q���;dG��=W.�s��t
[�,J�+�Q�d-DI�W>��M����f|�����Y���.Ѹ������:��������J,*٢Z���"ʷ�6L�w����\���Ӥ�U���w��D6N�<�6C�@Y�?<9��(����@��#�UX�6�S�6 cg��ٔ�{Ո2�K����C�{}���젊�7v�Z_��2)d8�%���h�6�sxΐ�k��v$�]4��F4m��384�
ζu��36}na�!��ݼ�5~��O�Ұ_�I� ��Q���K�_
,w<e4GS�0tD5����F}��������M����L������y��x�\Q��ɬ���)�j�QK'u��T���C�@X?��e�B��c���ݠe>l0j[���J������)�N��ˮ��7�AԒ�./`��3��!mX%Ы�������N2�
h!c�CN���s��  �[�#u ����l�D��g�    YZ