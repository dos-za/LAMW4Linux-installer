#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1849094051"
MD5="658dd468b8b31a2bed626e6be941065c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22472"
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
	echo Date of packaging: Thu Jul 29 14:23:13 -03 2021
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
�7zXZ  �ִF !   �X���W�] �}��1Dd]����P�t�D���E��O��0\�uX
��xy���XAQR�l�\�PHS�rFx�]��5�N�a�[���@z�<��tG*9�b4W=m����:䎡xyz��`�������|Ѡ=�7���"��eȹQ�MؘU)xʇ� ���J���N)j�ǵ�F�
�lj���}��즪�#�xv�A��kX��V/��aF����8dN.��Jذ�L��zC#��;qM�����ʯnN�S�kG���g&����-<��֎�����x�,;cw1v��"(n�����a���(�����#��,+�g}��=C��U�R��)��~R������B���3��f6�.<��UÔ\0��|��	� eq�sOo���ؤ8�$hWn3unOn�D�!85���X���r�u֎-��R�
�+O��1L$�E��Ctn��9���!��(�'GmuF�~�����m��T�A��d���0iX��16�t;`j=_�Y���J�[�Qf�n,��E��L��.=ʚ Zԣ���kǱk3,�߯�r{zb$ �#+a��!��6�c��Խ����8:�;��b�J����;s��O����P�0�����rXR���ށ��cl�fO`�ga�{x �Փ��a �<�A\�h�)}%{K���_a�����F�������v��G����:Uf?"��9��.���P����v3�1�Q�+���lͯ:�28��U����yh���(+�<�b2ܽ��$A������I����U�H��5��'T��ņ8��j�x�����:�H5�q��R�JP[�7�~������|W�%3��q��]L9��/q^P�J�9������F�4s
�vaZLC��ɛ�4w��z�"�7��+����	�|������P���hc���r�:�d6Ȣ���������ZtW�M��{�sC
�Vq�VrݩPxȁf��<�Q��zbE_N��W6Qq&8�<���E��)���`~l#�_D�L�@�ŮZƀmh	���-&e���M�cM�C�)P�c8�<�lr���ǱK�v��SYgP$��� 6s�/��8Ч�l��'.7
}k&�dw��2e�I��]'G�W�4�]m�J��B����9����)|����`6��ڐ���c7{*z '�z�����a���:��
ez4�%�0�j��]N�D��e������?�fIuvၘ�j�o���ř~^Q	A�I�{��/-���yP� p~I�Q}���XK�`F�۬q�Ve�)^���rQYH0�#��I����a�����N4����+��5f_��Ew�[ ����l?�2�J��� ��H �7��:�+6�Xc��I�!��Ë�T<Zq��0ŜQ�`�}�#*Ŵ��&��v�̚���C�Z��y�b�#&��+�L銫��K���h�йj�cs,m�-���ɭ�e	�xCon�w�q�
+�!R��)�~ �f�+�_%�������Q������]�k�0���� #�|)ߑ�ܫ���SBNW�dڻJ��r���$���9_/0\ɐ���?��F���tn���/��Sn5
¶�[�if�kL�2�+�U��Ҵֈ�ۘ_p�c��O'��ab���Cb��6eB[W�f[z����6e�9�U�6ŚZ��VD���LE�B����"P�Rѝn��.e��p��G�E�X���A�Z;�,S=Fգ�a�7��U$=��F�i�����Զ������޴ǐН���Y~�j�c�飹�� ���L�sQ� �H_!��{O���*�+0%hQN���p��:�!{
�gR�^�M�v�!w{r�]9Ly�M�c���;h�Od����Ka=B �z���L!lo%��|���
�+�Q��m�5s�`��Z����@eۦ?do$g�S|�yV<�͝&Y���'�`�>QS(zj���� ����<.��.�*K����N8����_Ϸ�s	%�@�߳���p6���V˨y���*j�:*���u���!�j��ĤBL�N�୮�Sf;�az��Cg��rl���Cj�q&�W �Ä/���;!�;��{��v݈Ѿ�"-�*g2���x��!����xdٚ�oZ�UI8�V� C�I
�o|
��nh�����p��Ey��RO)��
���؂�]��c��*Hu�PEQ"�~Q }�Έ��!m��LxYְL��P��2�/ZL��d
����9L�Z�����^�4/X$vs����2��U��Xm�,��ݺ󩒎�nõ�
�*�am�Ҿ:4~�k7sh�	�	��XA�S��r��٧��|#��%�m���!����ɹf��r�@��`�idF���6�ҽ��߾�w����S6�qZ����Tp���i6�x�u�����9K���Ai�%>wŧ�˥�_���땏��gLn%g��o\�j1vx��T�� �.1Z�k�����9���}���T�LV	����R��bfE��y��&�4�찿�QJW������'��͞�*KD��ZJo�D�%D�p�p	� �P�{�)�`��٢Нl�h��2��цI������5�c�v���2X(���)[�������f뤜YB9j��r���.��An��͡�N\�+�'�2cf��Wy�W+Jʅz��KY¤X�	Xf�j����"���/�j�+߷��{#�>�V�\�I0���
!G^8�GGƑ�Я���DLu�a]�P^�GW�6��nT������\1A�T����Er���ӛ� ���'т$~Ձ�����,bq�_j^XX����a���.g׷���n���/�9��R�_**�iA���U��.�5�$�r����e�3��-��E ������ծ
�i�`���%p�0[US��ϦT
���`��H05Ԁ�>2n�4}�}5�om+�h�uB��+^MC*u�U���H�^m��E>}��^�u������$�q,p3.��M���ʐőG����X's~^��)~bQ�؞P���V�}�V�eP�W��^�����߆䒂�ZF�s���y��u#�Ƭ��Sąz��$T�(;�������S�:����x:p0��~��t(�z�gY��ozm�Y�0��$m\�G`��W��+���J+Ec�d1��f��&���",�@<�k
ׁ8ѡ!�I �2�Av�1RR��z�ꊰ�����<��|D@��ӷ�d"�jZ+�,�:n�&��4F�5���A"��K[^��K��I�dV8�-�4]�2N-��9��W�Ȭ���t�$s���"�{�gɖm�w����=)Y���R6�0ěa��5�J��Ija�]yg�B¥��-�J05��&��Y5�(ڽ@{Sy���e��Xǰj^�����ۃ��]T���V{ԩ
�p2����ә�I'���	u�_cr ��t�vr��V�~�L�ӿ�O��g��;����2��'���@�ʢ��U�$�Ŷ����T[��^P�=_��BQ�5zăw�Y�����H+��F?�$�m�B�g�r�I.N/4�c@ʾ�60dI�:�>�Eu�s�Q�iX�E��y�2��4~�i�b���6�Q��u�������c�<e$ �����q�.�io�~P��%OL�k{�l/���^I�CH25�8�����	�a�u<6G#V -ЦRS�M���U�U���=�^�`�z�ʌ��F-f������qt����8Ž�����[ʛ��#F3P4R��!3��%�0��7)X���p����:A�cd���p�z2�S�FbU�1���:Ӡǂ��v ��lV牃r���� �<S�z�}�k$�CYH�tV�rlĘ�6�4����}}E�5pC�A҈��	�M�$��#�щ��±��aw�fn��Q���tmd��o�����E"�8�h�jWj*$K��q��t���o��#��|�:�����nIkR]�Ǹ�l̃<�͐���<3&~��_�j<�����a<Ǫ�j�����חd]�o~h%p���9�9��
��hd��Q�������BH�3|�!B�$���k�v�j������b�ã�\�G*�?�Hq�6_e�������ǥ�"ϞD���į�-�|��iop��@�z��2Xן�H>@q�Y��T��` ��;�E�L`K��oʫ���Q�
�ߣ!��+;/�~IϴmS����t#��� P�,ȡ?�ri�'���Y����������Gd��B�~��5Ǒ����k���8��֟���7��6�
�/�H�D�o�|N0��uF���:
�DZ�E�J2���4�$��G6F���y�P9���7���d�g;m)?P�C_�!Ǣx%��#���qn�n,��'���@KԎ�w9D�>��68{D�^8�ѓ�/����p�
�v� �)-��Z0R�I���,��([�VD��nsj�=����t "X� �f�d�l�6��Q$�e{���?1q��N}*z6���6JK}�O��� ���è�k9+��E����8����3���P&���t@��L��tyq�7� ~]0��t}�9W���P�ϔ��f�ҼG+5�ه:J�j��+TZv��>G�q�U>s���?�a'�'�R1ki�������ͧ�, L2�_8!:�?���]��q�Yb�/�G-�{�Jl����^hO��m�����;���!����� �:����I�/؏$��a���9���+U�+*�BU'����<���wE�(y�3�;���_�f�$��'���d�:g�R_y���� �
#��%�DL�����`<s����� ���sB��f�9 7qT��|$�NX�C�s��!�U��:�����W����;{+�0���)	b#ѱǽm����l?�bu�=�]��執{�:-;�e���q���a���1"���^��ڢ���vRԣ��vɶ�e�{�u@Ȁķ�� DF��n���tH4�<���XK�iJ�G�r�a�ЩЦ���cN�	?��;?o������w�~�oa�G��,��������_�dM����#�	ރIH`NЩDC�8��?`ܼ3���z'GQ��2Q�&cS]�gE0��Ȟq<^X��S�6�����t,������J��p\�е/ �%�U�Jع�H� 2�F�#�,����-�p9��aZ6\�z@�H}��+,��"oy��V��s�&�^Y�X�^�����g�K��˩�V~�O6��G��-�9�;�1����2՘iL��TO�lP���=�o-��?�^�|���?<s���GNC2c�U@��4�b�$1�-��ޓ�J
��6p�J�9�n���2ځ!���#�k�aG(�%'�`y����Е��uIC҉'���#N���.fo`4� ��A<!�������3�tE���&��~h� �mo�<۪�u�!cT�� �c`�ʧj��I���/��t�$3�ݘ���\�#�`�Sq�4m�ք�J=�n�/h���p��Ý�z��i?�Y� �;���Qr݅���F��F����{q+�2��+�17��3�mod�k)ҫ��0��_��WKF�S��N���N���"Bo���v�+��넻������P�R٩t?�V~r��9��I��A��I]_��H�	2�9~���2g|�vD+�wc�t@�I;I#�E�q���̟�,���"]��ܷ�g�����P-T�9��^��bĸ\и�<9Uq���	�	��1���{	M� L7��~�(1�̍�h*.A��net3w��>���j! c�c(�bC�����f�p~�-��!�7����b$����2Iýl;S��'0��W	���"\���pD���t�-�����E���mwM�
#�7�fOH���5m'Pg����=}Zc��Z�^�����6ЁK�[�05ݦ����0&��0��8���<�(�r_^ � �\ưk���K�pE��@�^[��FjB�� ��W(�D���4�FYkXMPbG�ӳTs���'ݲ'���޾���Z��J�-��"dx�"���$Dƙ"3��R�$>a�d����L�g>J]mm%Z�FH/�Kɪgjh�����2
;no|n~���턭6����.l ���s��4Q���>�խd�T|F�qZ�H� u�O�'�c��}_?�Eg��:_��:��B�DAv�z�Ak]���"Xe�2`����آ\?X2J=�f�[��k�W_��f����Jאk����U�k�"5�Ps�`�6u8���a�J{w��/,{�R�%�f*�A��p9�hfd�H�*5�ܩ�㪎<���=�	/t�*���#�w�H���m�^,V#q�Aۯ/`�3���VK�ۅ�WT7J��b^�dy��|����A��k`O��gS����Qk���n,@�B ��|0�dEC�A4�A��
ĺ�	Y	�5m�r]J�4������.��е�C�w:��1���Zr���&���)C�:�*,ydT\i+�(�f9�ќQ\;��>�/���޻z1�2�f� M�4�)��E�ji'G�p���u�H�'G����I��;\��>d��PM�	����~�L{�^�A#�!�_`Ys�[$�Mu;�E�y)�|�?�|���J��nGޔ�ꐎ	�I��2Ew,R~j��q��I����U����P�u�����8ZOɌ��kQ�==8�k�#}tZ�������w6��i�f�8#��ƍ�G�&/]�E)���cV�$b�g�(��|�3�|��8��8	7��j<�0�9V-�b���hlM��Q���K��Q���<�	�t�?v*R��h��~�$B�CP�S�k�^`?�C�$̆_��&�ZaO;��Cm\���*��8�&Q7,���n�pp6����y����7�ws���1s��+���4���9�lb�=����2o:4
��*�`�P�+�4�gY�4�����r�z{RF�Ohށ@���,\���ҶQ����f�.	��%|���O���E�������"���I>�5����s�C����~�^���5��O��Amr�5�s^�N'_�H��6��T�������&�����R��oB�İc$�W�rp��Z�94c����Q,��03&�Q��S��z��X�&nv�Fޣ���t���2됥I����e�]R�?���ͩYIA&.�V���/��2�Fq&	�-kRO�$�1vC5�Y�!�VEf�+a`�R�3�m�����GB��<<����n.�+����s�U)��P��V��VcgW���ؤ�YdR8��Doy�8�V�4�{;�/bѲE�M�<_σ��j� �F����i�K�!��,�)��X�o]n
D<R�n�%,����+� _�Xܻ��9��q�s�qt�0�ZzRF�I8�IR��Mk���6�E�#֗H^�OE<���h�Wz����s8|w�y�SaJU���1��Wjo/ds���L���/���MY�HL�>1Z#��+#���-E�`�v�BaP-
�jm�&�P��:.�@~����A�)�_]
���������3k�{+��Y|�"�$?ޏߟ��<|�ZH����vda ��V{[)b���32�r`��"�K��O<V��C�X����p�[#���� <��B��_�#p�sde�=�/ّ���*��|�!m�����-	��(��82�sޘ���B���oaj���6@? i�r�-�� 5�r��31��w��̾�g�̽�K��/rm�i%�^ t�f��x�%c��_T�/ --�l����{�Dp�����kx6���Vm�ҽ��Fl���eّ�#���l$�_�̷��:�yq�Y�.}��C�mH��*tCJ.�*_-CV�D�*+E���r��{��4;��ZF^�qH�qs/��NÜmI��Q|���m/
��Z�n&o��YMD���E���z��*�x���(؟��k�y�q��l�՛ׂW�g�e�ώ�fN0�|�(e�;*21Z�tD����y��7��h �9�0�����՟�t_��E�kMu�>��>��Jq!�^��!��A�!����Z.|:�9A�S~����〘4��[��� �s"g]G'�������\�o�(i�$oWR���Nb��Z���1P�}�0G�ec�1þHNڂ�<�]��D��3�d� a���wY|8)L��Yh�K�x�}�6��}_�\�K���FJ���Q&7	��R�N��V8h�Sn|^����)��X�UP�^t�tE;q/��[�z*�Ժ��>
�1�M�j����w��Je�o3˱��:�m���Jq���Ļ	#�lR�!���x:!���Y��NS�s�θ,ς2ֵw��DC��Md�7�|I���}p�Je�nqUr���sl�*z^Ɩ��"�L���j�'!�ʊD�����g�'�$]OV�XV�g��&wl��H�Y�̃t�c�#9@wZ����f|��q]���)L���M�K�Z2����8x-��	�*�x�*tI���l��rd�N&�Scj��7ݘO���{<]V'�p�t�kb�X�v�����j���s/V�v�7�����y�F1�]�%#��6M��_�O�!?�d-�٬�t��{5#*6K����_.����o�`����r�2��e9�#I�	~�)v1��
�+X�
��)����Z`.=ur'�i��m.R���ν��&��<�u��R�Yv�>?`"��ǾU b'ޘ�=KYn8��<�u)-!�~o��E�0G��9��QU�9>�s��4�|�!9�d��,,o��ć~p�^\R�v&���#8;���{F,�B(39�\n�����ie؇��?�X��,�N�|�.��,�Q2�_�����^�}%����\�H��8%*�LE�V�ʵ��/��1,F,Lc�f6����i�����^��w��!��퓂�I����!('��f�Nx2_4�D��-��S�*�1q)6B�w���	��� C���r���P=��K��}���-�(M�n���;�����B� B����2��2찗�t8�6��{{
M�ݐI%3|����~혥7h�<�3�NzP�0�x܋J	�vLWD*]^<(q�t�=��1=�F|EG���r5����O����>�Yf��]��ꝞoȒ�&uC�du�MXs��dǔ�P�7�w����G��)#�6ކc/��y\�d��Լ'hbl�^2�4��x�*���1�[�@�����t�T�{�4h3�9ނ�E:�wH���9�*!�&;�����?r{�o�[����W84���C�)�R�~n�";���Ɇ=pJ����`27�qw��`�\�l��+�Ⱥ9�-,�����h�4g$�"�Ѻe�D�ٿ*����gD'�`�^��������cM�B)g���r�`���F���B�K܎��4��r��0>���#6~ ���1�8�@��j���,�Җ�eSNk�^��L!?�M/G=��\=x�r������T�A4�#&f�Ef��O�d����jM�`3ɚ�l����	��i�E��ơZTk�9jʆ��T�7�U{RJs�n6���{��U���f���}��!�Ti~(뽱Ϊ�FV*�
����j�����r>:ݯ�[�L�b�U�V�4�J�źKeWѸ��T��Be*2t�QJ����x���܆�Ḙ'F�A��}��� �,ժ�宼
�;(5�u�P%����BŎZ�)��h�[���&M�r�[��G����`��d�����F�ţ��%��0\�q��-���G�����[���������&S��ܞ��IY�����^�2dh�	�΍d7b�Z:�n�(�H���0�E�v ����`�L�)ME�2#u�@��F0	OH�]����r[���wtM67�}��]k�Fn�W�ӄ�H�^�Y/� �>̶����~@>�P�Zo�����~֓�2����dbZëq�#�Y��������i�O�dm�G��w0pux�"���'�D�������-��$���Xui;�< i���4�"S�i�o���0gƘ�3_�:"��K_�a
ʥ^��4���wa�1E��$��'���O��}���|�y��i<��<�{#*x�7�!\��V���./C�o:�Q��M$��+��x�_��2#���fh#�*�K�'��|��H��ű��1�BL�\b�?�isД����s뙌��BM�<�4�I����f�� �t	7r�Ƀ�<|k��پ���&����G��թD�Z�a��w\�E"{_���8~4�K|e,A��5w����B�˴�<���[���7��=��% -m��1�(��+����]�8�濋�?��k�v�����ù������2]�rHl�i�E�9�k�������,�p؄=���>�'�ѻ�?��`���1��O�/?5�������zc0h�r�{�*���5�ԈQ������nlQlZ��1�U��*|�����q�	�t�����&���j3�qj�L�,A8�?Y���=4\���δ/7ޤYК#qV�ʅ>�}�K-�/D�\�-Q�?�4ѭR�YW��Ft+���*�O���[��[��	����{&��Z����A�tVrb�hETMZ�t&�G�~�C��xz<tJ�[���f_��.����P�x�����3Y��1]<a���I��f���5:�7�2���z�w� w���	m��s�c��J��ú#��\p�6	!�zS;^ WI�����,�?Z���-L�̓�NE^9d2^Wctv��Mow]����|����f;��$�� a%������`Q����z-;�~xFY�7]����&_�O��<h�U��8��q����]�m�Pa��m��b2t%�����L���~�ti
���~vM(�L��҃�d��\Ywe;잔!��ܾ�?Β�)���k5�0��L��|��3�̃Ѧ|7����'A)x��.��;��zB	����� ����ϹzT��ϲ�n�(s�l���u��;X��<9b+�.���&[_BY����\����Z��/LE�JE�xy: ���F쉤+@��`
=3�u��Ʒ0�MMD&I<�p�WWk�ť���#w�԰�g�n��Ԋl�Uj�'���y"_cY���Gq۟NJ�C�<��Ҧ'�H�ۨ^��W�Cg�_�L����%�E���s��y̤�6�"�P8�d��a�P�Ў�!�������p4��,�DJ��*.�l�s2O��yF��G/ߡ���!̹2Xf�Q_f#@j�I�m���J��xq�����3<��#��R�L�Q���**1�v�ۍ,�5D��I�C����f�_i�hϠU�d�Bm�xvkf���F��D ��QH<�t��|p�hD����֊neA��jx5pE�C�t�ҥ`yo��]�?�K_	H�lX�;���/��a���߸)���B��3�alO�X�9�$x�,���f�����R��<�����pm����3�}���p�ȩ�8'�I���$1�ry�w<xg�y�q`��н�����?p�mț,�`ӆ,fٲ�&v3��n|	�Cw�,�%�7w,/̍�o��m!24d0a�(� �W�&��My��S�ˈ�B��$A�!g�4z`��� ��-2�Bph�Y�y]�]���SY�@�w$I��@pm,���[���֐tL�d@w� �
��E�J���"S�Ŀ|�m+F��٣�9�w�Y7�<�F�\- � ����\_n�rk�_�.@�~>�D�H��&RQ�M]�~~����^IiW
s ���ĵ�;�)��Tp?׍�t��Z��z���B����Kn ��҆���[)���i����	CZ�.,8��g'�qh�Z7�A)g&��5G ��v�YU_��k��]H�����% D��g���u�+J��\T�+�r/z�S"����՛R.�ﯡW�Z	�%��_�ٸ`}A���+D�,{����Oi��]����{���u��$P8�Q���:(]�s�#s�qEk�	f?�=�H��H�A���Ȗ����z*�t�H�ה��'o'<��.��U��Jg3P�� �6��\�u-`͉A{	`K����M�����{x86�m��w8��d����S&�V��- /;�����y���6;�� ];�'ufhJ��c�u�v��
G����E�U�����K�9"�r�a#Bϴ��ё'�U�cP<-77ґRO�)|Y�m��]���h$��А�����|X����zUۃ膁�l[q�$sH Ϳ�]��8��x��ThOA�>'��W�$�0*r��ҕ����7/@���\1\���N�D�{2���	�f�9]	��O�ȴo��!ť�
�x��F����l�;���lc��rA(qawX�̋� T��Z���#�*_u����%-a1E^����6B1e�Ǽ���MWr+c�16 �@�[�:�_��F��� ��fs���hd6����rFjJ����ʗf������z�(�6�#�&;f�C�s��U�,�<�hM�����Y�WJ�?k;^nS�2���?��Ώ`sid�>��6vI�s��=ԟ��Ƨ�N�f˅��U�<(\�u���ϗs��E翖E���p���o��p으R��L!���,��fm�C�Ke&����nbV7C����h��2��Mo;t�%�drp'�Cy)��?\ZrS5���0�v�g�S
\<���x���۾q��n��bb����-�l'���of[ny�^����}6���*���͎�����)�x�@������1�����Q4U_�j���*i�荱U#$(#�u~D7@׸Xm��NT@t�f����̪xL@) �)�8w��K ۯ�2�
�&#�c!+>��[���t��3���f�1��	��^K2�`DM��a��r��`�˽�7m�2�����ˑ`���6��.7[ �(Rٖ���l��m��� N{3[�)�)�ʛ��H�GH��[�x=�[R����X&�l�e�I����Ӄ�'��X�)� �����-�A.�; |x����:���V���U�<�V]�i%N~⦑��m�g��$��n�bP�?;��94"�q8�}����q��l!���j��v�M$�.���o0O����)@R�M�e�kc�$(����3~�5Ɂ��ۍ���{��&w}َ�+0d�}{��2.�z8�������
yl7�7�ވK.��Z��vK�X����wt���χ�Ԧ�~sפyb� L�TX=M7X�C��=�h�m�?��wޅ� �	������x�P��LM��-�q�yR��|�ir^���܈�o!n�L�%��7/5S8��?d��2b/H��&��/��)���0����&�7���-ޗ�_]\���bu����[�+(���µ�֤�h�7��U��l�>���C��3:���<IB��C��q��x�j�6Z�5�֩B����5�Џ|j�l��N�y@�0Pj��օse��f0��w�]�e�S���(��ћ_أ���-���?΄�Zз~�>I��n��;=����4�U%[�����n������	 �=�-/
�:��V\���
W�[�Y���l�@�r��p��\��T �i�Zj�N9X�����Y=�>D�����6EȊ�ud��2zx��2�7�7x�K��em����>�[�m�緬x,6����[�Kx�d���@Q#�ȸ':�.�ӌ$m[+����i<G�ε�)���`}0���&|;o�B�T�	�ȑf�F��(J�������n�'��]����8�#(<�6
#����p�24�jT[w��\�̝FB����|u��DUZugUp2 ���]$c�WF<�����I����=~u*ΐ��[�A���i�t�e�!l�m�3����&��F"�~oboA��]��w8�/�W�˒N!��RO� �kV	�;B!�<H�!�]d���k
	�B�S <Ej��7��WvVj��CȪXp�:�h�I�b�c�яO�{3A{�؁�ܮo}^A�ev�E��r�Wcx*e�T�42���W�s�<���N�J�l��&8�-���Uh ��!�#�dL����
����- �r&z��Z�j��]�g��O�tM��[:Y�>Z�!s2`}���x�����!�1�Gu;�.B
�mxJD�4��+��r��0䣮hk������Qm?���H�g��d�!L�bR�i�g��`;�gX�4�hw��Zyj`�y���;�kIE�y "hgj��37@LT�Z{[\�q_���U?mH��^��ί�6�/'@��!Y!��b���o<t#1ܶ�M(��gIOt��A�î��ih���P��i7�7��D�"I���ˮ5��ii�Uw���7�( �A� '<f���|V�4�,D����S}����T*��\G/3�\U$@��Fź�����xj~c����9��+8=��z��{�+6�+'ٴ�3DedU�g*��:��)ܚt�!�8;*�B�`X���Y*���(�*I|�IDS�.D��JNŐ��y"ep%(�ъ���fV�1h��Ԯ�e�ۭ>�4U���W��y)�B�����H�/qBc� ֮���";XV2�Blg�R��UZ�ODl� B�,P&���;+���?$?G��N���1�_P��n]�Ro�þ��7wc��y�L/m8�����![�Y���3a� nzVC{�&|�(�WJ��J�@Pqs>C���c���엔���(\I!��u�%�b�cH��m��#�TI�Z� ����fe���C�+O��?�;����D�!�%�d�}R�#����<��D�vU�x(Y�W"�;?�v@w uK��j�kF�r@��МeE��G�5���Q߱1���;H��{�Po�wj�	I��c;ۓ�9�7xfs\�����juj���ab�M��'����Z�K��,W��x����!�
�?����d[�v�O��>�kVi�F��|�(�^�;�U�~��X,���y��,��p��g�H)�f�/�C|���ۏ
yP(C�����_��7a����+¸��d����w˓=|�1ɪ�DH�&&i.%�=W���i��$~G�3��kY�%�D�|,�mLw�C�bXlXe�������0�q�Z'�y�ܓ�z|�"����Ʃ=5d�z�l\�ף��'�}k$9G��~?�;���2.�Wi�ahm�v!��l��+c�g�QQ�>3c���4�B�]nޛ��_�a�	��p����W�Y���W����z17�{��Zv/��p����?+�<�jY�.�ӊj��1��dvŊ�XS�Ȧ0"�v>�G?^�-��^ka�M����f�3k�A�\��D��\w� H�G�jc�M}x����ϔb�mA_��偳7�*"�i���j�F�4��ܪ��3>�:���/�k�an����-J�.�g�WX�<�s)t���3�<�EW���:�^��t/��U9׊}�7�j2�Th7K;����Ьd}��p��B�' �t�%Qh]3�S�i�H���~�r#��CCk��j`f�t�֨}��;�H+o{j����l�ܼ���9�?��.��FtZ�jΆY$�%r[`�w
5FM�1�;C=�텗?�vd�՚�{�_���~�:ߟ���8@H���>��:����T���pr���纰��^�Ef=9�}N��h[nЭ�H�X^�ztM�����P�h��E��������p3�K����3���7���cqo��Gy�?�<��{1�{���¿��p�mm�vQ�А��h�p�C��P�I9��	����@��D'?3u�1o����r>�O�G�����G�
���V�:�aa7,�� C�GӞ*S�յ�IyL~�����կ�U��[�R��ֹ?���P�����Zi�u��L���P��suk�NW2��[O��7�O�Kg��%'=y�|A��-5NBL�
�a&J�.3�H]s3��\AX0+�I#>BPW��� IX�Av��ߕ&Y���U�^���9�ٱ�#��߸�9��Wy�@��־pgÃ���J')Y�US|� �Ȥg���R���(3��X�X�fN����}�$�Qώ��Ss�#s= "~r��Z��>h(�K�� u�)<<�"7��"��&!��x�e������!q�ީ���!6�4;3��hӳ�T#��'50W�=���)�2�RY���p}�>�� k���N`R]�f�=���aSJ>C�*�[r�QR�&X�J�
�sik��F3��� ��m� 更���G��l/��zD��>X��IO�W����X~F��g4���h��ExsW,�q�<�G�#�f.�hi!������F"�-^xG�GI	xv�ܿ��q��Dz��H�p7 VQ=��`�	<����>��DYv��.��Dm�5���NX�-eM�]�����4�]_G��oQ�o�$�/$zl��y��GΠ�=��:)�$��S�*�I�s�6��uJ���r3�X��h=��(#Bo�t�45H8]���
��O��6P������TVL*D����I�/q�$@�R�Ebch��b�G�E��]���&k`�؋���լ� |����{��	_z��VM��B�����D�Eꉸq��Љoe��YPC�RH���VV���!.*�oB��(i�b*j@�0���ܪ���Z������Z�jX���P��%�5r�o��rx������W���71]��!�A�=�xw�A�j���_�"�:8;)B��,���Q�tn+,��.��Ҝ_�^��&#���wޚ��Tr�9pEf�頪Be���l�X,C�-���n2��k:ЯE��ff�W�{��j�H�de�W�jl�g=6>-��"�ɪa�-���8��~���37���[���dI7@�wS��%��%Q�x$qf<���L��Бs%�7�[�)+}&ފ[�/֒��>8�TT�n^�������=�͙+ݾ��I����*�?j=l���7Nr�5�
Z.�\�|��_}V�^�)�<G����rs	�F̵T/��p�0��.P�H��%V�#�%�o��+��ʃR�*Ny�W�W
���
����u-���^���~*0� ��b(�DЌ?��Vp0Kk�U��1�D�q`��y��p9�dinï#�b�E��j`���1�TP�:���4��su�� �U�*
AY��?ȱ���A-�����ؙM����_��ȧ��<W�������� ׅu7�wi����o��n��%*��X��ؕ��VW��	��p)�Wߏ��n��������[�|{���v��B����x�Sr�u+��L��T���_�l@���^W����\�ד�Y�_��v�8�c�7cIA-Iso@�zv�6��^Ew�lW�R�盩�VEuc$̊��E2�`�ud4 �f�z��
8��T��w&��Y����q x� ��ښð��g.C���M�Bo`�t��A��,Q}���$4�8q���"ǞaM1n}8�� ٨��W��,�x
i��?��	���	 ���F��Ng-���	>+/��K/PE�[^���&�9";b^G�(�X�N��>a  ��[����s��%�#F�S��i=gq����νpG�!�M���l�%�ī
&��Zw`UA�㯻����rX)I��Y��o�^
=$=�X�1{H|�(�V;��^�F��53�Et��������-۱�f?�;�����EbX���Ma��6���5��λ��Gx��&y9�deS|��\/��տ)�S������ ����J�Bh�q��}Ż�7^}��?Pf���{�Z�	�̖��}��0�Π9m�npJ��"'Jk��>L�_&3U�T[^,N�0	]-�[�F�!�$�#84�
�no��u���D�2D=��?![��8
��@ul�nj#=m卍(�q2��0"I��˶5m�k F�b�K��OBA�Il��\�Rߪ�J:$�tFv{m�Elp���\u���A�Da:v_ڥ,�Dӹ�3,Q��ǹ���zc���d�8)�P"�j�����۷�t�w71+�<׽���9��WS҄â5�m��_����!��@+�V�(Հw0r�T6�%�x�#m�̣�����D =H�6c�;�u��7����E�'ҋ�K�#�i8k��H%B� S��*w�kNEa���61�8�6%�����ո�ęj6��+�ݑЬB�B͘��3)%>_�"�����E97�/}N�z�]��ɱU����ӏ��-�5��lR�����n��f]4n���Jh���sb�'N�edڹ�d������-��Ţ؀�в�b��kod��)�G��UIfX��Ì��'����	���1�*��o���Υ�1�j{��1h!1kW|�N�^���R��,����;��v�C�{c��%J�sc�5oRVw�9�b�s�� ���,�����e�Z�73g�E	|�U���t�w+�L>�HҤ[C'�D+O$ ��W�1������Y�l)J���%i�<OݟJ@[|u��U���� �/�]��B�<�fxg���WDLW�<�1���n	�m�ܓ�A��C 2#�/�rY�b����%�rt["�w�.x�D\�Xc(�*L���� �N�__m����i�GC:dٚ���d0�g��?8��_w��4�m���v�S�*�L�<m�V�e�Zz������L�L��9\=�����
��S|4:������:`��ê�-d���<+�Q�r�<���4�1�xy<
i
��U��H�����#������� ���B��:e�^z�Ⳛ?�<���|��7�f�=v�	�r��//P��ʭ�N+���y%A 3�p]�P8y�LWb �� P�e�6�w�A�6�a5��\��2���dɼQf!t���6��PDآ���`n!4�#���I0���Ɗ���eM� ̱�Vb��l�H%��l�8G����_��돓 �H���3c"l��[Ǣ!h~�Hƕmfx�`t�8�����f�O���Ҩ}�C��Wq=R�|z��Y'�?L���L���]`���ޟ�&n�Q���@MP�e���Bj�H�[.F(�;]�8�}���ȑ�{P��|a���F�s���)'�0&���<�_�:4͎F�J����`�5_YaC������e݁0�i�Nk4�yW�*x0��d��1�DuHĻ�!���*
�3�U(d��g�1�i�;�Ej��+�*�����gڞ�X���'���OϏiC�-�釛��x�n�#&��	H���C�k۱g�a�U�g�Ȳ)�šD�(�Q|1T7�-��u8�J��q�sm�{� �4,��jZc������*	h�8�",�}��A��PQAy*������~��p-�_���Oƕ^e�'����r��
��~�{{w>\��<�8�Z2��⹾���T $��D(�iJLcٝ]��10�#��U����A�Ŀ�QR���� 
-��ƃN&U��I��ǓK!�+Y� ��NQ�#\6�m��>��&L�kl}|�B��nFb�	j?����" M�ޤ�ȁ�".y���@L�� ߒ����?����?_|��Y���p�9�3+k)����A�b��0��;$?�q���!0ܸ́��];W80q���LP���fq�
{�{(#?��h8��� \"=J-����ݠ N���f�����~���L��dz2c?��Ǔ����Q/��h����k�{h�d�N�W�T�W��H=?�9ob�n������뀹f���0��܄ SqNӃht�Cˈ��:���bC�z鹽��O������(E���7�j��_���f��Fj�-S$�w�n�l��!֕5��?�;��Q>����W�l	25!`��xqG��1��#��7�	�"ײy�x_BA)�b��Gk� �x2�B�ޕ��4-/ɯ�zU*��p�&��`+�|��k��h������}��Z,j��_�KB��u��(����%
�nES2I&=<�Ǉ��|9�r�9��A�|�C,w 荴�hH�����;���䪁#�C�yԛi����U��4X5�.ƃЯ�B���(���±��Ti�G�b�j�iaC&*>>�w}��T<��n\hyU���h�֕�u��	��JߥETq��
.Q�@�=�A��C���X�J��[��!����f{�鉻}ŎN��(��92w���o56�ζ^0�d`�/A���I�%��?�.G���1��o�泡�(d�M����ɾ���)Z���e��e ܬ�[��(`�$�#L�ʩ��H<>��C�J	��)�i���E4��M7��a��K��S�e��x��-8N���%��\ϡ�]����Ɲ�]?����� �$k�O�{Ő�+ʀ3�����6��s`x��Np0���Cq�X!��=��`�q��#wȝ�����ϩQ-�0�"��v���/���Ƙ����iS!sm7%��q�O��kY
%(lR�1I&���e"�.(rx��*"e"�Ґ���z�2�#���$/����5����p�Rz���D��%<��H)ꦾ����P��"Z��z>�Z���=�Aj2��F�J`�_6�
�]$�<�4�����������x�%~7�Da���+5��/�;�ms�B ��>��M�k�Fq���"�&�%���
���Dݏ| �Ji�되!�|'mt�W�ѫ��̑��@��B���G�	��1LR��n4���L��K�-�[my�^Hl>�^g(����~M��Zn���ü"�; tH�aޠ�7]��v2�$d;��fF]��J:c��KpW=Pڥ�ʟx��@Gk2�i��+��B��F9��!8��x���� �`ա�7��k�C;���F�C����hL�7�9��m��ZHɁqw����ު��<����[G3vlk���O�򺲊c�d�����d���vI��,�[�)�_"�kwx��*E&��?����������Q�wa@R�H��)z$�D�`��yy���y��>��Wsw�?0�zo����f+���=���A��� �H�i`���$��T�2���V����*2�����xն_�a�v���������M��b�@�a�z1ry�O��t�?��@3�W�S]AŞk��Qr˿��`u@cn!֎�6D����կ�_�.Z⫽���y$|+M+�ˠI4�o<���r�Wq.�������sZ���	^!B~���4j�<�_3K���[��2��@�Ԣ��<���wh�{��ؤ=��.Њj|��G�\+���O&��O�}���;[1����%v��nkBw�_*��T �����jom�7f�g,��=QPm�b��.݃����㩋j������(nO�|� ;�%J������T��u�A��[�*h�z'$_G��,�� ��A���BC�\p�y{����	������Ɔ|��0���jVT2���Q�NĿZ4̪�����9��|�whՕH��/�z�7ԭ�T/�Q����[���-�D��4�_�W�
i��n�8:�;�'C�IS��5��כ�78 �/�	A1�!Xӝ^#� �|���HVI#=�1�Jo+��
��F[A��]|�����rn���w�!���z�kA2'�::EǍ�KFO�+���Y1��̚͡%rd-��ɦ+�Eɜ?��t�대�۬�wP4+%�Dq��0�
,x!s%v��t�A)���"/��4����ǘ�XL�[�$@s��0i�:�C���u��������$[�b�>��I���ҥ�PsSZap�a�zs�7�ZT�`H�~75wݡYu!o��>|]3o&��)U�����}��HyB��!xN9���rA(������Ů��v!�1�"b�����H�>�Ii?%Ŋ� ��X� -ZEײ��2�T��SØ�գ����x_�C<��K5�+��3�D%��VV՚� �yEns����q!rt�)D�w�Ռ�-�X.m,Gg���u�T�����V0�P(�u��c����d+�}C����)�NǄ6��T.k��s8�<ib�]Ʊ �=GL�e5w������;i�l��<�PX�H�ӮPj �	�oac�$�{�*g�m�  XA��2 ��������g�    YZ