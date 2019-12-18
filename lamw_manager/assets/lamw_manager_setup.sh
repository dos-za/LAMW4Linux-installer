#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4199190074"
MD5="310f89096e8d0b8654034a9268c3349c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20296"
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
	echo Date of packaging: Tue Dec 17 21:32:59 -03 2019
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
�7zXZ  �ִF !   �X���O] �}��JF���.���_jg]77G1j.�FSx��׈��1L��柔<C�n0�0�J|u��&w���1쩃������u���F'�S���,3��^f�*����NA�Ԁ[�R?]����y*��sv3��K�V/\p��	ejXN�3����Z�?q�.�]�@0�p~{lZ���U�� ������t�+�~w;�d���|��Vѹ�
|�3z���"f�EWZȍ|��	S�p{�o���;���/���>K^4�[�����nu�T��Mԝ�sNZln~��35[��*Ѧ"���>�ݖ��szɛ�>y4�w��E��mTqn!ʠ}
�;�y2�����2>� �� xi����nr��Z��tqG��z��`5ye����ӓ�bJ�}Ju|<���C�ܿ��m65����
�2T��x�|�#(-eĴ�m.c������z����u�\��/�_D�����'�&77�2���s��l r�xKu8�����SL�}oQ�O>��� ӽ���p������J"��z��}/S�3[���p.��ӂ0֮yqs��`lN�JH�f�x�אoa��
�!��.5�$Ҝ��� J�o���hљ����-j��;�R�+��^��i��8N��3���k7�� 
�6�K?+e�]�IڮW��t%'����gB�V���甥�w�RU9�8+w�u<O��Εi�������� ��76kd"A�ZV�]�:���$V��w��ŷ�����\��.ء�.�W�x=�Z�cۗUt�A���e�@���|��M y��F�"�H>��ɧ����i	���+��x�(;��r��;1���gyQ`T�?�CJK1u7$��u�����oPE�3�VF�;��ܲ(�E"�[��s�e%)Lބ� �DY�E�o(��Y�Hˏ���G�B.�k����}tI�T�������'z� 2-u���s�N�ۗD����ߕp�{`��K+%�KO:￯�}(�cLY����:ۂJ��j{7&��J<WM��n��W�B�6&�գ���->եK���C���wj�H�~p-�f���f"�㏁^7�[�'���Xߠ{�L*
+0PŘ]T� �\?Y�O��_��_����KE7.L�)D�m���4�e�,�Pņ�`�n*afIA�ʰ�c@1v ����X�PZd)W�թtjDT��X��J'�f��s<���!9�w?�o�uD#Z��c`�QO�AǽB��8�6��1a>��ktp��˭7���]�\yl���xE���q�o�&����钳��Qh�2�n����۶��l��M�n�߸Yp޳�n�k�d�<:Z���F)u�*�ԟF�P�iț�J��2]g��w��f�*n༖��c��p@y�`��n���9�2�LJ���1�I��VGR�n�kcH%�a1O'���N0��
k��a�1	l-�y��To�2��y5�@��Qr�G�,o�4d}�+Ѝ�78V��f��S.D.�gZ�?���������29��M����v~.a�ʃxVZ�4\�@���M�()�\��"(.L���x���@̴�Y+	�H*��yutEh�����f�l,$e��@����4���i���RNȝ����;��D��H'�ʄ���V��H��*�m>/A��eCYD����`����xN�:�	�FN���vEɦ��e²�"�$�0���_a۠��X�T"��%��NI5oI�<{��.,���I�'h�t:q�ʀ�9�Oi�Z��T'������s*ˈ/��n4"��$�|��K���f"�4�E�� O����}8��55$Z���7Г<�)���2;�o����5'����z�r�9��ì])���P�����3&��CE~;{������	���ԃ��N?qs� [���~om%)s�	O;�cx"1:`辺=y,���#e�홆hpO}�Gd��`<Y�1�n��RD�h�_Su]qy�/�N�S�9��N���^�Ѵ ��fs��j�Q��֣�6��G�/ J(�B��3@@* �q��0����k�'&��㔟��R:���J.�k� �:�b��W�u��Y�ػPd�_]i�1Y%�2�ê-�� o]>{������?P����w�]�ba8���b�.�Hb�9-�9i��~�à�F�N��!���V���*�:����l 
T���F�R���E��Ȃ9�z����cQ�sW���.fC�7O3G�������
�q7�ф6����ͯxKb��3m�<k�:Ƣ4倆��A}*�Xs���S�R;�To7��I��9m��b��%m���^}�r0qR�(�}��qwx#��̐�{{��Y�����@� �M�U�7)v�z�=k@��s�Ά�Cp5�X��"����hm��u�����K������`���<"��A"��{WP��PB�RǢ}�Wf)�d�������|�O�&���"��a��>�K9��(
���i��xi�/˄��H�li(��B��!�Ȳ(�&��H�q��HF��&��U�IE9K�[��F���j�
 �t^�o!Ǟ�l�W��A��1��8oJs��#��T��|���[��`�6�4�����V}�ڪ�zq����8}і�iq�|[ȗwU�sJ�y���'ô\`
4�m��߾�P��u�Z3��v�c�N�
�\��/�Sf�(Ͷ�ށ]|�y{��3C��.��5�3y�]a�)�Ҟ�ۙT��sW���C��`ܗ9�!���@�z`ݳ��� G����Y���] �Z�H�������ۅ�h�HC^�3����黄��IfF�Ċ=ޭ��h_6̪���[��N�O�[@ԑFU�M��yX�ɒX�.$���-�9hB�K��.�-��zrj�Q��k���)�m��?�?V~�q��J�T<�CD~|�pJ��X��B0��䰶pԈ��~B	��H^�R bt���;�8���r�CP-���Y?U���M��N���+{������ͩb��ӆ~"��
�egaaTq�)�,��@0S���A#+�Ojz9��Ρ���N������TK*6LT^��OJ����P��ǸC�I�}�Q�!�z��0b��>,:pl��u�l-N�Y���-�tx%���s-
PhY)�)���c;W��	,��t���l�ݿ�TQC� ���9w�0qZ�����6\�H%�3:b�j��f��_TYZ�#j�q�;|z�7�@���]9���י��_� j W�5?�;��C� ���u����rN	P~�����<7�("�Xݳ�+l�ϣ�Բ_]'e�1@xW�'�Ӑ�D1�G�W��ӣ:�Uß������PCʬ>B����y�5�1ڭ�]��fI�OY=�L@Gp;���]�>��j~���n�S�;�p��!��͏~y�kՌ�Nl5��G^�;\Ζ��<��UB���0�"�7`�)�҃���r2!����ޛ��D�a��=�H���ˬb�DuX�C���PIl�rP}zv4lD�]�mM��ŷ�@"��7DYU7�o*�Te�-��,*���%�� ,�Eb[��s��e�r��ţfO��v8��3+���������a����u����,�/郈5�ګB�ᓜ�y�j덼����w�R�&4ڕ�d��5=ڵ�ۑ[�\���!o?��CF�� �ۈ+H����2���P���q�z䪌WKV�E�V�o>K�`X���^)Y�-�S8��n��Q�;�,��Wg�HGq�܌�*?�K�A{�%���"�D����ĵ?�E��O���\�QBM�c6�ʑ�[����Qf�]��p��|"E��?֠�J�x'~���&�j�J�A�����F�N��$5��!A!tI�q�1W�ű�p,A{D�+�^�Y��[����S&C��u��R��?:��D��և9\}��
���C�泔�� O�]%�^�����`�}9��[�H���3�vH���,���y�]� ��T~=�|�	2�Di�5�on���}�qe�j[�cY�` ~��h�*��V`@�T'���&LM�ι�HkX��v7����r�寅����I��� �/���������b��_Պ�!ϑ�ߒ�vݫ����,j�E^L�5$�����X���C���1�4�q��&W��������Ԁ����l:ۀИS��Z�����ǣVg�$Od�lJ����|������a���qC��p _��!Hjb5�-���~uQ�>X�ˇm��g�u���!�g���n?��Z@��*^E�;瑹�3oΐ��o�?Q�-8j �B��Ɖ���!g-��Z�ե�v��,$�0�O�ٔ��Š"�a�^�#��<����nM~���+��sc�'��'z��f�e�������U<�3GJ�� 7��W��޺6~;/�J�6�_�[�U�:Oڃ<�r������j>@:� h
^���F�7�?�6�jGL���tD�ڵ�e�Z���~ю�8�H��:;T�ʍ�"_� R�iu�h,.�4�$��X}۔���`������Χ��0��_��&z�np�ۃVl�/X�M�!�+-2k�}��55p��8;�6*?`$�?�-�C��H�pƦ	W�d��#��	L,&��0#�i����l��JK�	|�2��iZ��$'����|�f%���]9���N�5��aV$�S`�����e�؏�R��."Bú���&�O��+�|�p�n'#����� !{�t���;#1K�Y�e_���]�@��!�CI=mnaS���byT~È=/w�I����o�A�!�,�5�������#�0:��(7���Ը�ddWN�����t�T��{Ơ�����HY��`AD�t���Σkf�� ���ɧ�W�߯[��Я���F2T��2���'����j^3<s����"<�H�����R�䢕�жK�]��L�@��	 �QY
����F��w�g��	�%9�Bk@T�������/J�yU�b��D����Mը�W��y]� +&Y��̦u�q�Pt@�Y�:���Y���ߌ}̏��ncލ�-�?",.��-��Ͱ�>����@)�1n��W�o��02����RA��w�Y��i�坓t�I���}`�\�� ��0ݣ6�aG`{����":���B����2�x��Nն�_��5�1`K��8ދ���[�-�����$��kX�*Q#9��c?n����?vf�ń/c�Ba+7���h��g�R�K�ֆތ��g�K�&9���~����$]�e���1��{�R+JJN����W+I����T)�I`:�ݔ��t��ڌ�_t㍖��>���!t��5лǻr��f����H�{ ��v���ǫU���{��	�GgC�=�G���|����_ʑ�T�m�\�}#��)B�:'(y�[�?d%��Y�1�)�/��:����ҽ�A_-�9)��!��9u�&����(D$�|�����!�n]=\C���\�IJ�"�1A݋ўh��1�*wz٩UZ�t��{����pT��园�^���iK�&N����8L<�?e�����) Vm]�
d��|��;�R�ѥ�)�n�~�:�y�KFIIf	��u���i&]=��Z.�0��/�3�$w	�ъ�i)��=���M�H��(��T����� #;��C��ģQ)�y���H�~a`id����V|�JCn��
KzϜ������2㭱�-�$�0q��ߴW\��(9Q���sc���B� �+ѣh��x��U ��+ɶ��q:e�;@��-!/�aw����GB��Shz{�1a�pjB,��9B�s ��"�V����vW{�bA)�Y}1�g�jsfP��p[��kU�~�tah��Z�C=�ۮ-�t��|f�	$�k���������M6�_/�G0���]h�>v�����L����
��1���^8��i�I��MgSޙ���s�Cϝ}P��t�)s���&���l�e���UB��	Nc��v} 8- ��u�q���qE;���vēMf���b|�_d�}jW������cP/`x?�Eԑ5�_��1�/n$9cD�R�B�O6�)\Ű��C9��,[��r-If�
Ǳ����~�ᾤ�OFZE��"`f�c�Q�<l�|o5�i�Mc1�����aQ�P��c t��ws9=��$�^��C���k��5�2z���Pc#њ�I�c<䴾ԗOy�����������yu�&�`Mn
~�{�����~D�o�g0���ˉz/h�����V�6�u$��
���X� ��}*x�[0�q�o�֚�+����$��B�
 �&�Xb�k���NSb�xg͆��t��/a��B�9zk+�uK��*���.�� B���`�$�Y���V�e��1 ��uh4.����o�A^�6�]ڎbXn@�����z�Qš�WD�:�Q��j���p��g;qZu:sC�/��u�u�4Y#(�M�@%�L���"�M�5Dy�����6-ux�x�8DE(�r�kh��C��]!��RJ�/�-#����+��c]E�'L4�N�$�L����T�f�����-����nN�w����9�0W� �t���v{��B��|ㅍ]��c�x�;��5�zA(��A]s\�S�`8xM<����Ń/�fG]��*��'��)*�,=�!双p�*�d��{�sT�I�=��Ú�����ػ��kϝ	o��o�e�/��2���j\�½&�ͳLV���G����8�F��� S���T�V�?R��Gv��9	ά�~r��cW�BPG!Z�
�h���HJ��c�R�^%��Ba���ˇ;�I�
�
�B�v�+e:��&��h�L�P�����ʞs��vAб1o�ץ;�����,*7�L0`ɷ_
�k��Y����2���ν�D_�J9���K����(�ÙY�T��<}Z	؞���m�9���WO�$�!�����/^I��]�3�DپX�+ӭ�Ť@=�7��-�&�ρ���3aZn��f#5T��.�C�Q� A�Η�:�m�D��hX�J��(�iu��9��F8A�py�� �Ab
�k'���cNX��s��53'�8B�X=�bduD��)Z	qm�h] u�0���i���.�? @�2�����M�mH/�;ޯ(��2�%��; �ly �B(c�1Cp�H��`,32k[�˲����u-S"/M������#QdV8W�Nb����*���"�p���ع��1���u}������v��9��i��_��:ܹ�Х++(�� ��p�4�+"����x_���8-d���=U�^�C�[��C96En�F����9m���p/Sa_��|��5�TƷ�T��N^$E+�(���8	(?YO7�f�����a��bT�l��7k6Z__%�N}�Fш^�'?�Bu���}��j,2��� ���i�
xm]�X��%�Mq\;�=@����Q�Vp#S��f���#@� ������Qњ�CvU�a5�`��c_'����
�z��������~�bc?쵽@d�ԤGG"��(�a���1W�q���+�}`�_�͢	O��\��V����ޔ�ǧF�$�w)S� �'n�˨�~���E(�¼�G�7,`Y�1�Q��dN%�
��<wV�=����f�!h��yG�*)���H���!&N �$c�
�%hJQ�#r�|�AX�|��.�@���̖a�2��|+͌m#'������y����<_�o
����FTgN/N)7)m/.UG�L�U�[E�oM��Z�h�,��觻u�z�a�_�IY�3�7�c9h<��|1J�o�p�G^��4Kyi�i��]��ms�^ >�4ߚ��i�������0��+$R]q�`�\��L��|U�pV߂
�
��{8��|��:bl�p�N*)z����,unB�b�X���
��f�-Y��.w�����v���u'�M`Z�=qr�(����K_<T|Z�M��}��\J��|�DƞGs�K����:��c��i@���ԍ�n4�1'=Xј�ph�&�S���ܡ�!js��2\C�I~F5��/�y�&�i�l�S���$���S�xI[<7)����z" ���io�ڕV�����c���L9���&u������'�j��%f���S���	�����ٻ���2�h@�2�jS�DKL�؞�CJ�"\��tp	�~a�Ц԰d�xNp�n�!y�ɸHY�煀Ι��\���������q0ԡ:�*$pk���Q�~���C�¬r��F���/�X�t�9���"�6�Cw� H��Z�/<�h .�G%tVV����g�7��6R�����Q��M�4g!z�MG8����v�u@�	�s�.Y�v[��V�Z������ƌ��]Њ	slo�K��5�������ѭ0��?sw�R�q��kbt6�TL`l�i0���F5��ZX{������T�������G<^�V;��������BƾH�N��Y����vW�J����:��������L�Umj�{�	�K�P�%ݒq�0��9U:�eD�#)x��ў80�i�����Z�:Ӧ��H��'�Y���H��c��8��濇�};O���dVQ��iJ<K�6��X>l'�C�wI(}KӪ&��qm���^����[I�0�`CC`"m�M�adg����!�f��[�����j�/�Y�aW"�j�13?�3Cfh$��K�3v'Oz8I��!d�`�_B�UE��ϖF��f��>�S�
K����{Z��
l��5 ���7�J���<׏�(�~��B�FhU�?*�4iN�ȷ��Y�c��K �ؔrޔ�g�LE쪦�٦����g���9$c�� �j��c��Pw���"���f���V�E�� �ダ��̧����of��0�_E���%���0�� �$Y�h��c���Am�G���ː~��H� ?@\C�L��Ѵh�:��w'�vGP?��[��߲��z*?yu��貗r/s���,)�QN��hW�����h�U����9�7#��ϢV|��e�j���{�fo���"�^�K��/�)z���ϖ�'5Jiج �f���d�����LƇo��Ru�y3���m�}��>
PF �Y�sz[
V��O{���{��R�E��D�*z�{��)�w��2�D���wlG}<"{�+X���@4��aS�eՌ�e�x���u�{�&{�m&ڠȯ�m���e�
+
Vn��m��H�' �	�5P���f��PJ�:@*x�4R����[����n����ß�C���bşT`/�����\����C�dΠ�)G��F�0J��6 E����n1ٽڥ�Sy��4��.��"��{���0�FuVqك �a]��+�����2p�M�����>�:'���}��:s���%1D�H��#M|� �����N��5Sg�&�-����.����e�m����u�T�>v6~�ß��Bt'*RW�,�f���l}?%�q���tm;�E�˸�V	�O�v�R�w��AIc�;��=I F=t��#{��p������ޥ��������Tv�����w�"��β���J�9-�>}̊2���Ҭɥ`��T^���L������5��1�����Md7��h3���FinX�A~ي�ͤ�TB����Uz��Wu� sRm�������~7�������]gy�r����ehwPU [��������DَC�&H2p_�.iP�נ:))(�3h��l�	�dT�-ֱ����x]��@F,�!00~ō��L��%� ������8пTR �w �d���(��Q��x&�P�n�C�τ��"�4P����8�y�*��o�Y~%�;*tx���^�Z�䨤�`����>��W��t�i�s���}�Nh�^�סŶ�Q�8/��-�A0��317G�^Y�s{�f_���M����fݐ�A���ro[��	A�ŊJf]�3�H~�����8�
�JaV1O+份]���A�}�+ �E^r�b�F<"}B�����0si��sE穫��5���u�ƪ�(fQ�6[��ղ�(�ޣ1'�)a�.4�7{�\S�M~����92���
\�@��5	��|�H�X@�]>�3�^�=l�s�h��}��̜U�ֆ�B�>쌻������ ���~�Kr��	H'�H�,�g�|)��1+j���\t�q�SR�hB�Cꍒ�+��ԕ�����{I�D/�2����0o�����T�����w�P�+�^�q[�SS�= ����e�7:�x��:�j��9�n_��h_��4�%�%�KA��3z�IA���B�n'�_�����9Y輤�eLl�z�[H�g�~�@�������W�c����x]f����y��x�T�0��4�s���y�@���
q�,�lDl��ɖ��'��FwYJ�v�$�-�5%TfS��xS�M�׎EI�uB�' G��������-w�M�G<�!Po�~ QfrW]2�,Y�u�ـa)��Q8fDb.��$U��l�L�f�N[x��Y�"@"s����8�_��|dj�w�I3�7��'	�ؑ���!�"���������:K6����_��@G}�1c5�V
]�"��ZLk��D��Ϙx!������_��r?�UŎ�y?�t2��5|����Z�g#?K(�`o���nŘ�`����0]ʬN�'\�� %�
��������ƿ�	�+n�H�c\����������}t6��9)G�Z�΅�!�!��D���Ⱦʐ_�����j(��S��J�� rC-�<p(��~j�Ky�B T^��#�#�U�?�]�NC��MEg���M��-�z���kSeB��Y=�O���m��e�G���_&2B�}R���J-"+���&�/��)��k5<t�iF~v-��J�z��;5��D<�m�VWGMy��A�U �u
w��d��-�b
F?����ʠ�5��Z�D�+Vr/o��	��6m��SE��?�n6=�e/ŕ�7$��*�G�%��TR�^k�&o�����R�2$�7.<�ƌ�л���o��4J)<,���7����"_z�bWA����@?_*��2���iԄ�@ޭP�����ma	lOR0�J�_�v���/}�H-�2P��S.Q�
5%�?��#��\^qQ���
�+�"I̳�$�&�MN���Jhw��q�࿶:=5@?�"�m�X��د����FV��£�Y.�e���h՘xᣧB���4P/��J���
�m����+ܸw����BN��`��� �V�޼S:+�~�A�"Nvk�K���1|.E�~�[���Z�\{�24��m�B�?�fc1�E���k��O�]}��� "<��j&����j0c�O�;�Ѕ^JQ�D��_����
��&��Ȋ��nƨ����F�v�@8�Ϥ�ɶ�����QV͡=}\]j��a!FN��ܻH���y��?�B
�9Ő (lA�6��^��d�X��sV[��0���b�A*`)�a�֫�J:�i�J�;�����Q�`�i�"`��J^��
���[L��RE:[U��P�/Q*<O�'N�!cY��T1hn�ǉ�R`Q��.c�1��ΐ��ٿ��="����1�)�K����S���7n/T�Æ���x�J,9����\�>1��I��괴�Z��s�-��,v����������2��u1YUX!�=�� Y��)�x��k���;�**��x}��<�i��Yg@%0���(a����T�Tʜ�}�v��O�p�My�j��i���{��0T+�|�̛�|�>�dk�h��=���/�7J�9W��f�yݵ�bF.	/�L����_��s��kCS�}��-�Kf�#,��<"�L� 
\��8iK`��c�AgD	}y ��ϋ��'&���U�ŉ\���hd��Qű�\&�g���{���Sޜ24S;�w~���j�#��,�������<����P�\a�2k]���uo�Dm���r�����xB����QA1��{ZqZ�Zd4����=.��4*�}
��O�������_'H�Ȟ�n4��;7I��4�V���;f���Mh�F����5�]f+ʅ�(����Ӝ�|�r�G��(V�n�.�� �� ݳ%�ȉ$O�83�{\�&�7Z��^��w|�'������Y�K[O �����.r��kT���t)�XÐ�HK�%�q�{	�a1�����
&�@$�
5��Z�G-�z;��Xҡo��Mx�ɀc�u���^�)�!��I[���Ⱦݕ�dT�)�+�T1��ߞ��Z[w�UK�J��L�1S�̌|�
Ie}��T����[�?��0��Ԧr��G
�*˘'8r�>�w{1U��"4V�u�xĢ`��� ��O	8��?�5_�V�=N_�OI�R��3=�ݦ���md�D&�м�ۈ1�<�0Ԉ��I�>� �U�c&U�̜|jd/�%�%��"��9q�Ss��635�N�cS�ֆk��/��&�/�&�m���������5��z��e8�9��<紏.ù��{����q�Y	��P��;�������o�c�x�k��X��-O��Izq�*���f\�̫q��	0�v-�D[�S�|Q<>`RS�y�>4>�������[�ۍ���(�"̧MH�?D��硤nM5f��o>R�Ƿ꯾�D��lPQǾ�����*|��Ow���Y�;e2ɚ$ *>h�
Z�o�*h�D�p����\E���!	�kH_u�D�%m,��W=DI-���϶v/\�����|&�TTRЮK~�H�kn�{�{�f��;})c���Z�>�[�C
>�!�W}����36�Va���N�Y����z����S��2R��g�q;�Q�q7j�S"�9g#���M��t��� �A����(��}Vo���x����bd��:v
=�=V7Kc����"[�$�f�K5G�M���m��T|
��[���S7�� �'ܕ#OJ���m�Wq��h*!+���DZA��K��)#��,ջyD�[��/��j�kX�"+����i�@ev�>�~�?�������&�
��|i�V�ܣ� �e���M�K��ǽ�v�_�S)�pN������]^t��c5s^[zư2��]���(���~�De�d�H�~���q��F�y)`+U^�ޭZ7��փ^	������c��=�V��d2�@o+��U1w�<��z<��:z�X���������wa�0�M{�Dt]����h٧�48$X޺e��kL�$�|5~�K>�V�ߡK#��1 ~d�'����ǠlF�r�ŤO����myY4�sE�c�R��?G���TP���̥�t���ԢO�e���nӻ�[�(ɧtύ<�"���*�_5z9k?��Ȗ��ƻ�o���O�u:�Zw~�������_ߘ�(zAYěˬ���6qmU�Ɉ��v�F6��2�i��NP��!����-".�{6�U�m�1\��l ]��ⳑ�0cۥϤ
qY���:�<��Hs�4��G���'QN���3+?S<�P�K)� � �=5 ��ъ��),k���:"�����i���_d��A���Fj�iL�����诳A:K�ŽnR����Ћ}�Wp���8���� �^�ضů�كc�篤��Z&�pU��ٟ�g�\�
���,a��UE��_j���J�Ba:ppX�}C
D��*����	Ybs����.��ڭ�#�.F@\im�`��'ӂ�#;�=jĄ�a�A���N�x�!�k��œ�Coq��� `8��rN��.� R��*"ݢ��-�3-��h����ؤ��-~�u�B8�7#J2���c�D�y��P=Ү�0x�(\}Wu������)$#��qGnmǺT@�X,7���Z�J�c����20�}?IIT�+�	�8�W���{�p��-vşn�L ?�x���B�F@�<�L�{�x:�X߈�q�.�¨�K,��(��rH�P^�*q�ݗ����1;�*#`�B������˯U�}��N�{��F��g$ ��L@�@/�D�(RZ��O��;k�&�k���H��bd�L�U�i��|LkQ"�e�W b���`5��K��\4���)"\��?��2�>��1���{M?�x����,V�[��:�xx�?i�h�T}������'j�*��p1�I�$;��^�֑�L�{߰��M��c��s�W�x�~>Qv_����W���ʛ���x�IW��9z�E�vB3_�G������_�`��ɘ���V��so�T^$"�a���ysu-��LB��xxK�;��t��u��|h-�\��vU���0�U�3��Yg�2���-����]�J�^�^���0O�h��nu�&�r@�碿%}�W<_3}�cZT�c��v�f��҇�	9p��==�?����(���#k���)�FRM�ołR�"�Ah��_��ݔ�,�9�T���Y�E�����a��D�c���z�'��{iSEe�d�����
S)�'��<��a2_�&%凗��ƀ�P�3���P������^�v����ύ �:r���?���3�Va��U��!͜�GaEr��!��N_���H9y�!v�6ZsR��_�8��ls&
z@���k�k)�n�A��>���"�1�tJ"ѡ����L1�����9����gwvE�IrVfaZ�B��v1D3�	�^���
�/�[󡝆G�ŋ�[ʃ5Q���t�J�i���f��G�4�r����"���-�kz�&�*�S�A���\��2�fs�l)AU�rH�;u�`5����07�қ�Q,���>דǃ���"�����(�\���Q��B�jt�h8M_\lֺ�gE?�X�pg�ݞ��v�[���+�WS��M���˙@�*�]� ���+�uKLC�@@y��l bP�G�>��)�x+h�������]�364�*;��3�s*���P���u�Mr<.��顆}P�W���PA���UɄ�ϛS�pU|-��{���2TrD�� 
ߛ����iok�d�;�4@�υ�V�^ \(���:��Y���T�T����ưe�[A( ��%���]�}F�0�0P9�:�G��ʉ�*��r��1����G,�EÀa��O����%��ɶ���<;�:5:�Xf��'�eh?��x)��΀`cc:��\��F�������/'�$�K�Lw�Z���;4�g;��m��k /C ��d0ó�_�% b�/O�5�t�G�+]��B��}�36/��I!f���M������t�q��_4O	`����J��M��)!��՞�R0�zI�f	t4�uW�Nyb(Ձ������ �^ �kK���wP�9��s�����Xz��ы�0��e����@5�=¤��ј����"VҊ�Rxϼ�����9�+��T�
>w��!��P�L������+MD_��p����!I��u��4�W���A&&>e ��F5�?"[2֞�K������sd=�[�����w"}[\0�UytkP���bP�����`7�`+NM���0�n1�a��}�H�l��k���/�'l�H�N����9L��1r�j�{]n<=]�Z~�;g����
 �d�Y��b7�h��Ư�o�ܭ�-�)�%�s�$ �'3k���N��O�$J���H�i����/(�ګ��
���	�f����Oc[jƼ�O5]���hT v%����`���e���$vo���c���Sv�ԦفQ�CШlCC	��cJ�fM(tΒ��S�V�v�(AɅ������|�M/��4/��hTد�ބ�\0���U@��rcS��J�@&������ٹ��j�U�E@�_`��IV÷c��|��YCKI��K� ��S��A}NU�]�q6�4��!��:���J!�S�����U��S�8ҽ�4G�ǣ֛�y|��e��Ž*�Q�~���0Q���� ��U�U�w�،���*��{Ǽ�u�RkC�q��\�i�ޏ��4���]�i9�~+U�T�������K�y��w�u@�+����Ey�R9���KS�Lc����q���2�iO��@��e��T��{s��M7�0E�|/�+\/3h�47��:V:I~�z�5�����w9{?�6<Գ�h)A�^�b������h�T���.�8��UH?��s*��t�<�j����V�~`M��h�xͰ�� ���"�D��

���jH�zbw�(KY���E&�.�\�/}<Mej�-� �ZA�BA��tm�wk�J��.EU��HBNob϶Za]n-�c;��d�A����M5+���n�B;�S�V�i�H�f#���m�9�F����'#�^�����L�N*	�$�ן6�Yp��ŵ�5BO����{�!�����x�0��%�X�tl��O��%|����+���vc�*φ#�GV\����˒j�{�eV���Rz :��O��ܮ��\	�F'�� ���@�
�2eG?1�&S.G@�0O>�{�"�l/"�7~];6�M3y*M�5s��8H�ig���2�& ,�n��tA	ƒ0������g!h�oA��S���a�wXs�ߎ�$�Qj��Z������  �)�k�I�K��8y��H��KQ�A�XO�s��G�%����QI���W7M�|WLc"o^�Uf�����ٖ�aԑ�{�J����!o;t�=#��&�⻏��Ny�R�Ͷ(����!��2񸎗�+6C�;�1C�f6��C����Ô��Zwyr�/�-�^�N �N��c?x��]�#˚N� yn���~�m9��7Y�ϧx7���<�5��*�A�uOP��`=�� 	�dy�3��v�T�����Δ|<Y���D�����>�
�C����螊;�N�=�a^N<����!(�H��x@'9�|���y"���>�`��r�y���-F���gN��C]9�rZ�t���g��(�T�B^���盌��-b>V&�l˩<Ȓ�/$�a��X:{ҽ��-�/l�8��C2K�ΰL����
#<|�^�{���������D���/7��<�B�0��B�!� ��2c㜙T�{b���0�F2!��E%y��<1ͲT����|ߊ�s���+�GZ���f����U(�s���i��;�'������*��-u�x'F��@�����Fڽ�{����:5j218Dƶ r�6R�r|xP�儇4�b�t�b����jd(R*%��_\�������S��T�B���I8�큫�љX�n6��Q��wV�̌auq¿D�Q|-�x�ɒbax��m�4RfC,#-�D5�8˕�A�����n!�w��ZQԐ>���P���K���⏠]<���M:/P��q�����+5����8�O�h�C���k8$���k/z���X��SN������bS���Tl��4�����������+��n2k=�|_ę��e 1�{ӾAe������e_uD!�����vk.V��tk>6�-��x������u�#�I"�<�X��  ��>��
�����C�oV`�1C� |K�����x����5��M�2i�B7�r朵�+up	����o�A��2��i/�A����!�3Jc03����a������|�1?>g �����*�k���f�*)�
8W���Y�%`���&�&����^�0'�!�}�p��_wV�U.�l�P�l�OMy)��4+n�Q�B�|��)&u�~!�^��� [�LR��@�[M�`�UUH������f���26�4�N2�[
B��rŖe�V_���6�ZV�vK��p�p9��,�^���=K&tB��U������!����h#L^_�� �M@k��^ϰ�k����"�G}��o��n�$���?>���{��Nu*4�1���M����ͺ�TP�|�27M�ë(�Br��R0�i��PY_����k���w���v�M�Rn;��2h[I���� ���Y�"3�)���kK�	'ՠ��o� �/���
l��t��W�\>���^ϻ5\5L�J6����1[�!�~��+�)� �!M�e]	~<�.b�6�s�8z�	�#D��#Uz �Mk��1,zXؕ��ۄ��i���e5�Hxb�QNg=$?�$"��(`%�O���m�!w���o���|T�m��j��0��m�|��`��0���=���(Lm���H�.���L�-S!@D�l��TrF�[h�#�;��R�� ~4Ѐ��c�v�{�t�>3���R�E�JWXVC��r�{���ύ3>c-T�%Y*;���s(R���
���a|���*�~ /zrn�R4��s�ЙZ �0��W%B�Q��-@ڵ}��a��X9��Ϊ�Xy�J��ti�qX�.jޒR�O���Ͳ����1F�$ ��?y���[3K���.F��b%�I~���2.,C���k3�e�b�L�J��i�U��t�H�����l��u�yzn���$2laʣ7>�m�����5��|�r�P�Fdc
��g�Q��s"5�_�Z`��q�hA3f�X`����D�y?^�^Z���@B�{�2ٌ�	�E3�?������ŷ�VŔ�	�갟�A�+0m��<���W�j��=�T'�*?@O�s��T�U_;�YcJ����o��j�`���+،q��(.0��E	�Z��[�vU	 ����H��fdYb��BhnZPt6?�"&ݢw2!��t$�됓Z� ާ!ź�gA����[ԙ�#��P)Ԃ��ɻ,W��T-+����@���:֬���%�U�}
:bo&��5>�Xdtb��]��$0�B�$w�v��~7W@�t�v^x�B[����q�� �/�MS�'��8Ù�?��˸x�
.���L;�}��@�����2!!e���c¡+V~�|N�n�$���	,zaw�����>X�Ǟ5OF/M�П�3��߰�|�ba/�{����β�)��5�!B���#�7(�9��A�i
7;����)R#aB����]�/e�5� !�F�`.|\���{�����c)��mi�J�9�a�#Ȓ�I�,p�%�)��[v�ڡ+�� �/sl�՘��F�y�L����}�7��B�[5t��M������sq��c���8�P�&������{��rh�#�X�����oӐi���b�k��\W쫣�EZKt&���>!N�T��x�>�odW����(f�"l�x=ݷOr���%ǒ�gsH�X�:�c���2��J�M!5��X���nN^�7�EO���&��WCsO�4jNi�z��TWu�.����_�;��7���%��]k���m���� ��������m�[�ݒ�J5�(��$>�v�j����/�J���H��S,rrU���q�곶��xI�C���ث���p��wp^�]���!%է�(luO����f]��6������f���q�7�6�*�l??�5|l8b��h��K0{ ����v#��&�� ����E�Jv<@=mF�O��3�ԯ�җ=�`��mı�A@�h^��UX"G��"����f�
w�mU�P'x9|�AFz��]Q���g�,ղ�?��9��s�׭x��m�"�-����@��ڒ�PI��{�d��iN��*��Fqalj���	��S�n�oFy��\�o��@�d۞�����m�#��c�$��"mwFj�o��@��/��EB���#״}Φ4l;DX�(�	� �Bpx1�0�i���]5��K��B3��4��#<�WD�v栰��!.�34\�_�kD���3�k�OuY���c�Op̽��O��     �Dq\�� �������a��g�    YZ