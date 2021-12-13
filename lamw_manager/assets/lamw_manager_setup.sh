#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1596505971"
MD5="382b040b37427f526ff35c898065d568"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23936"
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
	echo Date of packaging: Mon Dec 13 20:02:51 -03 2021
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
�7zXZ  �ִF !   �X����]@] �}��1Dd]����P�t�D�"�T�
2��_ꊊ~���U��F�=ڰ��޳��>Ģ�$�t>_��xz㧘�"N������A[�(��Y����3�Z����ܮ��}����z���s����oXW�ȏ���-��[ ��E~�� �S���L������;{��L������}����1�d�6S� �l;BCd�s��C'�"EZkc B�?(v��dr1�u�t��5Mj�Y��$}�26�E�G�w0*��/���@
�yP�/tX>	I�)����%�#y��T6����~We�Y�YV�<A�*dKk�#�v��kDd�`nTZ��&�5�=ی�P뤃�Y��T�J��iB�z��z~���%�a�6�lz�\od�Jʏ�F3��"��G7#)&]cc�cTy��;�;G�9DC%��R�:���^�i���]j9̈/�c�Qb���a��f��R�����	�y�,6�k�S^O�M� �1�_�kKgJ��K���<��P(A�`��-�7�QQ�u"��\��-t!x
+�w��3t��w;�� �\�k@�w�FěMy���j;T�U�9Ee� O�A��j� ��:]C4�����T�~C��Tw����	Qd���"�(��~�a��-}��
�}��}N���7OUpV�88 �8G�T�w|tH�3�a�����wK�s��9s�>��(x�
`���h�D�f0���Z*\����NX:�,ϋ�=�^�[᩶�VU��H�r�;Z�����i�R�M.`ZO\4�ܓ�8��P\���I�b�v����A�l�p�P�S>=k�R�N��)t7LRe�����W�����<�I��r|��C�u)��������yv$����`��&�r���)g������1��cd�K3F?�j�q[�7�6�kRN�T������	moS�\�ģ?eZ��3�����C(ej o�v'�h����HUɣ?J��rrn�k��s���n��N|
�a}r��������¾a�e��J&��M�D�V1�}��0"`L0*\}���٥px���b���U����5T�ғO_�N��mEm���b��x9�'�1�E�;d
>�\�eQ�gVS�&*_��C=�b�)B�A�Ŀ���0��*��1e$Ub���b��tA��}h<��������B�����Ӆ���{c��HGA��&2���뱰�h�*��a��8췽^ˇiPcu`I���e����-�9UW����.���_(�:<�>��Yt��#k�\<�7�j���L����V*S�(�#d��n����V�[�6�ä�G��Nɡ}I�Ȭ�x�:`�v �Z���G��F�ݵ�����)rA��:����cA5�	m�,��q�)��|� �1W4�Jn)u.�!�y���}�/��A�^��Sk�A	��.�n˄���]�j���I>}sT'���}����7� J���@S�g�_��A�x����f�w(����!8U9ar>"f�Z��!<��ė$YI��$-�i��K�5�A�,��X���P������y�t2U�/����-�z`ɯ\�t snx��ȇ�Ґ�}�O|Nt˶�zo(���Yk}y�v�CǋmH৭�1�o:�_��6��n���=!�wH����8��Z�vw>���c4�A�c�O�a3�G�"�C��pT	�qc<���Ø[=����6��g(�`����_l�[&�(ާ�������/8v@�K�5Ӽ���\8����r-�"�a�Xf�)|�W%d�8�ƾ�
���^}O�d�����+ɴQ�`xN6_�f�->���|��J�д�����h]F���_���'��~6�2w�[���*D�M�z e/�!���肋{ЖD��g:�+;��g��
{�d��{�^�+%e@S��/�'W/��N�Z�O:1�wgbτ��<6�.<w ��J�ơ���]צ�""���T[�VW�	�İ��qs��т@&J����h��E�$���La�r��ʗZq<>���G`p��63ʯ�.(b#��ߠ���@��؊4y0�N�t�6�����̓����󓆆J5���8�;x�q������f@�@�w�/�t� 3��z���r�?�q>Ϩ��{z퇂
�o[E��x���ʈ݂�F7���.��:�F�F�%�7ţ�_��J���_�Pq�p.F��m��L1}��R�Y�(���N|i��Z����h��TKmЩ�QUes�d�7����۰n�3��Fu��]�W#§LQa��z=k�bn5=�-��L苣��mG�7X��k,n$�_��o;VT$T	%�꤉t��0FG����n<�yc��\�'�a�/u�lq�Qe�r����j� �]�)�/�]!�סVWu�I �?�_n]3��~ >�R���?���x����-���cQM���,1��M��v�K�g�W�6��w$�*ō�A�*CV�m�����A*<2�ŧ=d).P��5�o�q���U.G�� <;Ϊ�@&e��\���D�xBB��;�ǲ9��T{����Z�J΋J��?��"����H.Ix���{��k�KR:��z�]T���aN�ަX��g��pj�
�_���+�"*��
���_��K��,��w�32��aI���d��R��g7g�Q���6�^)q5%�9�v�����6� z� ��NQA!�6��}M�m5�])��VZF�� �lܑ%)�'���ö���a�*�pEa9'�!���&d�������0���$4u�Ii�O�K?P6���]���[��Nm���N�B�RE�?�8wf���93?��,҄���4�˹�.�PȼT����1���O��ŭ����9�=�=��K ����Uv��`�D�.oP�����-_w��a\��*e��㖀8� j0�������y�����X�-�wá��:ܕ@�۷H���+𻤑E��Y%�3#�R��t�R��
�)N(B� �z��~\�m���j�Ys������RD��W��ou*�@i�PTQ���^Xn#u92��kl����1�>T��v.YpgqL<�}%���������*�3��0��7�G��o'�L�s&��7�U��z\�g,y�j�S�A����>IjE�]-�B��8��Z�և�X8����Y����כ΍A�YI��H��#բ������zn���ۆ�D�7衿u8(l勴���i�<��M�ՀšM��2����8�2b.q��o�� P��j�;K�U�֎^o>C���ם�� ~����a���ɛ�FTK<���_X�#c�?��|�����,Y���+�Q�T��8�S�~��2����e���IH���F��\��T��A�5��k%xj���Hj��j�(k�P����cK���(���}��%1� `'��v�2d�{�)�w�3���v
!��Hߣ��\��&]���0��%T2��/%Z�3߬��f�^��t#^�'��Lu?1��O�t�K
}T���`���Ř4aQ^���w��	sL>���J� ^��zq�lyZh_�s�F�d��Kr#z.�L�!+�U�rC4hԀ� 7t^��*����H(5�>_�KoR[r�j���f�XN�x����E^F���灰��X�l!Ί���o�+�b�g"CۖA�O�-�O��Ku�q��$��{'�T*��AH؉�����X�6�>�����h	s�z]*4H�p/վ�B�����e5�g��ᐣ�S#
As\�P|�Q �me�^y��s�JCދ~�-�&��:[��i	��X�
� m)�d�ZY�_����l\���D�H�1O�.�{|�E	�yL3�sP�M3	��x�O���c������L"w��<��P�G4
����w�G�����E-b9�<�'���4-�������{�~�x���[��t.%����Z��u���L^8U�Fi0/�q��)ъ��C�$�� ���J�������:0�����XK�o�&4-����))�q�je`Ҏ[.��D��/��S|��6K<����ʖ®����AE0��?z����Z���i���=���ﹻ��p]��H���u��4�7俨��a��Uۂ�f�2�#�L�6�����k�SA����MN�F���Ղ��EE�b��{����33�ɩ=��l��������wP���ۉF��8�y�%Rj�:0NgG}.���t�nP������(�=Eχb�i]0�dQ����U����M��.1;�Dѝ�a�i������!�_ƽ�c�Ml�?�m�^�|k�B�dx�Nȁ��r���f��9���f3��A�D^�ưֱ֘F�2�W�DO��d�8P		����G�s��o�����W,���b��6��C�oZ*�p"�#�J�Y�XR%/��Pg�Z�j��'�����C��:���f/�Gй�����6O(�o1�"�mX�͢�{�Rp67�=O�q	�;��zD��G�(�-:�jK���Or:Lߟ����ܑ8KۿƎ��N}�$�+
c"./�G�dA]V,���/�JEh߬���^�z`]o��Gc��Kͪ;^j�6�Bҹ�>��Y����I�~Sa+��9��W�Cyz�ڑ۵@`^ve��͎��ɤ(��԰���b��݈��JKv�Q �O�:��Z_w�S�[W�z��o�(1/&���ƨ�X�&�c���j=�R��d{�X�ٞ�b2R)0?�V���*��Y�HS[����"�amy~�U=�q����k��x������rPXC���OKs��C�NYN�ʷtw����<$�0��)i[5Mǯ�"y��4n��L�d]}��YV9+��:P)H�K!"�H��J�8����^��6��4�	�»W�8��l.�gL�R���Ĭbӛ֑��`�u(_���t���t%����ن�^��D*�ԗ��Ѭ�w�Ŝ�nt�ЎJS>h�}��������ؘ�P Z��u��v@���{e6���x`[��Ө�?�O���#A��0�xvm�]s��X�Z'&��p
M�;C4:�7|	G�=���{詓kg���l�F���6���e��T�ة+�B��Z1��Ju�w��Bs�i��ߚl�``:������s�];�fI&l����3~Q������Ʉ��4��ְQ`�Fa��G|Q���i*����gp;7���zü��&�0��w��V2=�V�T��U1�<[鷬�4�l����..�ǥ,O��:҉�+�bG�1������d��ٟ.��]��f��;�Kd:4��=_ޠ|�1ؾ���o�1D�SHF�5h٫B{/�}n����/;�:�\f�I[�G�Mea��"[r�Sbf�����`Фձ�.s�,E����$� B�[>����U��~�ظn,^�k���0==�\9p��e/��+���)��"� �La�))Ba-���c������S1��h(vu)�LG7pt�  ��&w�a}/vQK�s�S�n4	�=K�Ȅ!Hm����JL[o}�'Ѫa!�� �Vu8���C�dzļ/���(�?%�w���PZ�5��9}�4�����X`:���0�vN�z��c�E�:U�n
لUK������|a�[g�gD�[a�{}�QO~�"�DF���v���(J�����R���M��A'�w��N��]*��]^�u*.=a����O�'��a$� �t�����7<��/)�������r��쩩������i.\���b�d�:�&?/�/V�I�S����
�Tpe������]VZ뇽k�z�fx��Y��%Sλ��+���)\�Ԡ��Ž��H_1���"G�r�%B8�� ^X��D+�3ul;.�PG�r	����&��A���+9,4�%��Z��Y5�LV��F���(��p�eRn5�^1B�{�J#��ܵ.�*���u��I�<��Ni�|��]��mZR\�H��_�%x��&�f���hGӏ͊�4Ź#z{8֧�(p���t�M�#�:)>�H���g6+RՍ��z�-j :�)��H#��$Qp�~���c�_��0��#�_DL�L��@l�Eo>m|�U�J�KU�$��9-� ˸JVE���+��"�wp�e�_h��>�$���yn��W��������2f�G�l2:ѿ�'�cȀ\ޒ"ݦC4��@957R����l�+�GB�����HA�y���J߷Ɏ<����)߷�Y#���ľ�"ij����\Wg�FM�K�!7m����4q�	P���kD�P��A�#�e0}�� ����1�c��dC����sY��@�|��KU��(?t{ ���lw���W��������U~b�/��l�X8�mXڈkN�[�Ԟ�Zӣ�C�Y"*���
�{,���#y!׭>ë"U�ù��:v����Em'�"i|l�P9��D���8%����ٰ�M�FH�~C
 (g�9�|�%�T$�czD�*A�آTf6�fڞ�&��۫�wJdjB��z�;�9�]Z�]E��N����̘�9�LwH~���]�"���}Vrvi�4[����#��L��5y+�kSI&�=H�*�)�i��W-ܚ��#'v��<���,�b$��6�D��[�K���S�bq<7��=*�E�"����J��[����AЪ�q�ʹhV:���m�(M0Pν��<�\�	k[B4O(�\ݎf���Q�G;o0��u�P��O���?3F��q�,�7i��@��*T3�_`W�%H(�"Iì�U�����j.6z?�J��e+�@w�zǍ=�	3��W����__ ��]��TfUG��jT���Ԯ����qE��٠ }:/(�<]���qlm�`\.%A�]�j�	ld^����`�A�����Tm�"#�ܝ�#-�T��V��SC�t{�9�p�}�wPK�Zo��ӳ�6����"֝�K���W�a����|��%��8t	$��	:���$��	�Ig����̿U	I��L���b���O ���T����,P$��=��F�Ii�0��v�]�^oY��7�\a�n;W����`�S��"��X�y�����p�
�B��ۙ��Җwl�f�������Jl���N�V}�p~�(���~�댚�z�!� ΒL�\����*���E�xE`��$��pBa"��;����Ř��d��d6:�����|rvɤ�%:?C�sm+3tb��TQ���p�>��Ann%�Q�4�\.��QQ��N��x7o�!	� [p0C�J3JP��|��x���N4����R���<+��d�C�z�"\����?����4Z3B���VaoŐ�AP}r�m�L�_wt�CG��7���t��#��ǀ�"K��p��?�������Н����LI�VTɎ�w���M1�'}�;�j,�N1���{���7"�,��	n~ӛV���p-6ʬ���u�(���G3��3��B��R?�'� \��6��9�M�B���Q/�@�ċ��e��ڴ�J���g�;<�h'YF_@����PT�X�f�>rt�*�
�ʃ��q�cP�TsS	����ʻ:�+`ld���6�M%d?�ꌛaZS0�uX�8�f(yt�?/���%{��W2u�7��� �+�tݧ�7��ȵ�	:�y)�J�(8��[8̳��<�`��	.bA*=��l����Nf�0M���P�<�v=��'�E� �G���֛,2��I���6
��)����k��q�h�ɛ�-�W�����ݓ�E	�@N�9�Y�5ۜl��[���UF�!1��M�f{��W�.�<��F�����@�ڀ��sW�$n����w�E`��Qix���[�,tbA�$�Ն_�'�t�{�*��x$���{Ìj�K�4ˇ�׋�3?�y��/_Yخ�n��� �d��0�mx�B��Ef8����l؉��i˚�������:�M+�$���%�B����dB.{��b�S�PȀ�Kq�,Ʀ���f��5��Nr���5���6��5��k�W�A��'_ȁR��-9�F��O�ڦ9�S��^�g��F-5�����;
1��v���+�:��b��P��r�U�A��>*JF<Q����Q_ϙ�\�i����s<����b��cv�5�./Z�z�iM,_S'Wr�Z��ĉ�#bfp'��$�L��g ��~B��:j��<4���	bUd�QM�`	=�l����y��@�D�5(���^0��Y��P>_ֻZʞ��� &F�ޛ��$ɸ�i����4��g�:ƥ�3�(�J��B�ˀ-jh�עj�_h!�A�Pc�u? >卄�Px�c�k���u�q��m^�݁`i���;�$"��T�w)4v�:>�R
�>�"f݄#��p4�/�{��D�>�
1u�.&���M 𒆍*R�MSy�_�$#U��s��2O-��2�d�~�kT
�Y�-��39���9!�8��?��bm!J�� �QA�V�J������u�0��B1�&��i~꓊��XwZ<��⩟Is���H"�m��̸��~#��tbtE���m��(�	=F�N&=t5���}����S/ЕiZ~�����S��_@�,=�:rgx|����w�������a�z�h���p�4?2AQ;����3\<�H�7oH�9�zq�)�G
Os�Cҷ?�WY���h��
M�����ᴡĹ��K]��u�e6��A�=�D��2G�X���+J���	�鉨C�`0��\5ӽ�JZ�M���s����� ����.mL��W�Db��B��u��XEm's�yLj|b�Q�\S��V��Dyo��-AN?�·�~b�&�<�F;Xm.A��$�t_�h�ֶ
9�zx�_ޯ�������z%��R|��4��`OZ�)���l������������6�S�m��i�roN�F;!,\�4���: ~�M�	~�iq�OU*�dK,���ej@�Yt��)1<���E���6|v�-�{7�v`:�h.���W�R&fu߶d�����;�kt��؂����w6�z���w��\I�:���gs=��}���{Y�[���'�\)xv��?p��>�3�ԗJe-��Q����묚GC"8�B����a#qJ�IIWK�s`ǩ3t�R-�-�Kp/+�l��|[ �BN���d"8����Aԕ��6�*����֩�U�y�ZGi
M{j�h��/�	�P����`�'r�B�S�EJ{����v[K'i���Н"6I+�'Ļ�n����x#_�������ݳ1�V0<�Fx�܄;��&�a�wq�&x��*?���+������.��6i��I�4���=���|��_{�i�P��V�>;���u��T�$�5�mr�:-)MB"�:�)��4b}cp���Ʃ����iP�uWxQm��Ad5�.�~B�o/�I""6�kt�Ȭx�
|��K,%U*�՛z9R{޸�}��EZ��|"ۺ"vj�G���'�!v�v�5s���i�d��������:�+; �Y��OmI���b4��k�� ����Y��~�I]
�r90*Yh��yX�����̞�������&~�迆��5�!����5��&�FA�.�.�5�+����l��a���� ���9���p/iI'��L6vȮ?ԭ�Lm�1+�ܷ$x_���A$QQ/���4�2�x����!4g+?�C��3z:Y"��I������|��7�(�8�i=wx*��>+��z�R	�����F�����V��a�ȇ(�n��[�Ns�~k�!+�����Vq�s,@3UR��سX����3/N]�I�@�E�gܹ��Tҩꜟ���DĘ�)��῍�
Dl&���EO��G Nf���XbF8a�?S���<�赋�*�
��m+�,��`�<��[��/����z��|g~��/�5[&�vG�y�3��Z�73/�N,m7�Z�M��1����+S�L6�˥6�|�Fb���i�HK�oI�$��&U��Oc��4ڄ�X���֦tg˩����-��)}uOpL� ���J}|$�AR�u=.�)��@��*�J��T�C���@�2��]c����˧����r���Cm!���v�/�wJ!�^'��k�������g�+VǠ	��P?��YĹ���E�$���]��E��G:�F*ln��A�)S�ò��<�;`��w�1����#d&�������B=~�.�J�;�A�r.Lvt|^�����jPҀ�T�q���Vy{�NO.Y}q�$�><	��1��o�S'E@}��GaR��"mv�H��Uꏹ GE��0�$�H�b�>9>VuQ�d��p�:(b��� ԧ��i���]8��`����sJЃ��J��C����{'Z��Y�_A�}\M,v��4+{&*Čwl`�Ԫ�[�=2ű��(�[��^_�>3*\�,��5.0a[
 ���F#N��q���ߜD*�����꿏�EOCD���!��>�A�rUhJ%�>����T�-=��D�yf���%�;.B���l��_.oNJK��ĄL�p�Sx��_޾�b>o�@�Qh>g���M�K	����#c�V�F�� ��#++"zPC��T�/F!K��T���)8��|O�fk���wz�f��#w/�$X���"�/���,i7���R�%�%wv0�7���������#�>/�֡��B�q��E~j�yU��iⰍ s���O�?���d�8�,�"fT�o�[V�f[�&J�<�3�w��/��Ƞy3X(z�C9w=���<��c�䬻�݅N-���������)�9�����DI�Z=����O�LB�(U���-��,��OsrE����� 9���1�>stN�e�l=����0�Q�q��G$�rN���P.�oۈ���p�G����vR+�,�&�q�]Fȡ<5�gde
诐���w�����5D��q������_9b8��6q<����Ȉ���&�^I6��d2�e��)u��C�'(�&jLr��
��!lA)["�s1�BP����8�o�3<!X�owz��͐#7B�OtSN&�N�Q�Hf��s�q-]&+��=T�)�s���}iD^����?��^m���}��UTq
�.��:(n����b\=Ku��w�`������v4�=̕�7P��k����_<�$��5p,Gg�{\�8.��:;�)$RT���9lwdX@~n�z��:�κ�\
�N�U׺,� ���e�3�-��.b�jtTWı/g6�X�ܼi�)�F�O�QiY�X��p��ȜK�hO����1��2N;�XF�������c}Oo`��a6X6��b~ez�]���*n{+f�(K{�A@��+�%b'E�1������QP2�OX�k{n��p���<e�uqB��Z.O@��=�f5�~��\q^]�4^���� ����w�xx$�UZ`��wSY�ȇ�gm�P�HK�x8[ cɸ��<.������25��<���"x���c�jVR<�Oq�%Ub��D^ؔ9uq���齲�F@�׷|Cڸ��*b��!����Ԇ:�x����/�v^,ɑ��GmF6���Pi|����>�R�����~�#��ש��m������B��ұ�n��,x�K ڃ8o���oe�p"�p�F��p�~�h|W�hWW��KY��91a�@���М�1�uq��ÜCn\6��ZK_�a���5��tվ�]+v���K_�a�s4X���Ao� ^ťN;�g(
pO����k���e�=d�Dʛ r? �5��쎖�1a���_7�,��0�SwaMX pz��羣�Ư�ہ<�¬�<M�������|Q��#��xG����|��~���z_�\�~���,v{g@��z���.�bkʄr�a���П*���t���ĩ�h��z�&�}���c�
g�*���B(�܉�؍��U��Cm���Rm� YZJx?�KAp�~5�s�$]���B�f� ���,&���п���2�v�	��qb��A��I����p�R&$� !#>�N��0����z�L_�Y�&�RĨeU��E�Z:"rEY��j��1=ؽ�u�7�+�Ej�9��������4n�s��!�Wg�3�����IV�$����}��K
�\��M�7Y����(��'g�{��;�;�)OxZv����8D�=�x"�jZ���%Vڎ���hx�dc���� �K��#�R��h7�2��	4%�>�� t�Q�`���&�ue�Fe���+Z�Ee[X(�����>H�s��P�i'�r�*k𣫀���"Ѷ�+���g�`(U��_O�K�ޝNst��7��F��!]��B�c��۸Y7ɶ��l��R޻~���^��Q��/mo�b��A�nS�X;S�W���!�r@��i����'(?����o���Y�<�Ib��k�dC��X�'��@����f�p�H%AB:{�C��;V�z��;I�8G7�K�L	R�AL(g���9�~<�����Й�U��&�8�V�"=�N+�J��]L'�I#\m^��4�!�9�'�6�ᾘ�nk���fM�w�����h-���u��T��;�PZ�2��'ZoR�y�P�=ك�J�@���ɱ7��U�%]�\�v�|�?�g�F06~�.��1�h��g��rLYS��
[E�Ƞ[�5���bs��=��3���� �P��U�/x6���3�y�X^G{_>�c����sK���ۦ��*pe�������+��u��C](pM�Y�f�c|�ig�@;��A��ڸ�T'�;`����:����VN���b��Q�kV�4Ֆ3�`���M�,p�g�	�^�w�� �ϽX�"��R,���EW�*>ܙ���dC��dO��Ձp۟���v��� �L�/�m~�Vo�����y"��w��x����O*�H
��2�7�����R� ؚ����~"����{
�I������f��~_�}����c�Rٖe�p�6\�(��)٫+�6��7<�7����튳 �Odp�F�?���$�l��Ty�g�Q��{��p)z9��[��KtL`���H����6n��Tx��h~�(���__��<�[.4����u�&>�J�Z��6L�@!U�~Rm!4�)�1!�mo��MDeg��i]1iU�,z�85��\�ek�}�y�R_!�'Yr���1�H�^3Ow�<�nZ�e�|�Yw�̋���A#����\�4]��cIm]8`���e�]�]2����˅�UӦS7�0�?�*�y�t
}���.W��K	�I�nJn�2ܩeS|u���X����=�=�(S�x
$�F<�=y���k�����-&]i�h�{9�[�����䟗:��|'�ͯ*����:^^�_s�l�)@ ��u��<~ѫP���R��P]��+E^��<�u�hUe�w�M��!
��R������q��������fYC�M���t��M�0K��\h�FI�#�튝�uc���s'�Oe�%9͗1��.a���4~O���Qf`:��'���������>��'�#榸�ַc.���p�^͎p�a?\��ܗ4h�w��U���t-5�Y�������Ԍ�V�+&�r�_���{���nM��b���,��#�_"��`*Ui04��D?R���$��}���[ǉ�y�{s����IKU�)�����eӎ�ߟA7`�� R;���)��C*c'���5oo�g�'��W��."�p��E��w�2<z9Sȿ����MB:k-���e��w*r��2������-7B�K��}/������
u�]'��
X���U̢�V>��+ہz������uk�UܧhW��S+#�ΦF_~>��@�6ՏN<�ݣ+��
d�-z\�vW��yv͌��ӷE� f�������=�e�y"�&}Ļ@�Y[��|v�P�ϯ�� x�Q6'_��]A� �8���x���\�
�ou��Rh�af��XZ�π�����0���)��$�!D5޼:aGIԕe�H�}� �Y��i>���(�)�nYH2	�~�����l����{�i95Ӡe�n�0w,	з�>���2
{%�`�TN��8����g��\�(����Yl�����ZM��	8F�Q59J�괄������/�	��	�$p�-�����q�ڮ�.�/�%ǅ����hR�;0#](�9^���5��q ��!ô՟��46`K<�\�P'6L��0"uB/I�5�3A�����.�p� tңlX��r}nB�.I�0a]N�nq����A�G1�7��#��|k�2��fh1���D 8l������)�t��	:N�s��a�j�^�s��Yf��M��oK�џ����qi�Î�~��1�=�鎈Ao�i��a|ZE�N`���/ia����H��=� n�������A�����[����?�΄.�N�����ˡa}���]�E�ں�_����W0�B��~6nLwcSXh	�.t�)�q�7[J�J��M�B�������SJVG>�~��� 1�և�9Q��NaN����RC��h�?����${fi&�B����`��D�5���mΉb�"�|�ђ.�^t�k�Qw�"�Y��L�R; ^]�
�#�	�%�s�&�[u��R�n�R�1W����W���\F&ޢ̍e=;w�|L��'����u��3�Ӥ����� n�=���M2��^�aIۡ0�MgDJ��,)�,�91�J	���$?�٦��*�/���N�7��@<��5T��HJQ����2v���1L�K^ٚI����fH&��v<��{�������ռw]���� fǧ_D3d�óy�CXUM[Y��[�u1k��~�z���b��=����j����@��U48�i�y&�F�����'�n��T1J+�SM�TZ(�Ny����Z�艸P�2����J�/��uA�&��۫�`W�
��d�����z�x��_�n��'����|�\���LI;8β0>���ѫ���]��Խ}8�Wb��L�N�ĸ6�E���`w�7R���iS!���)'�\XL�Y�%�O�����oɱ�}�Aطn;�@��v%_�	&��Mo�{a����*�V!�T9�H3�ዶD#	�b>�;�Qx��-^��	�*�Q����6j��}��Y�`�K2x~��J�1s�J� 7tl`��j62���y�l�eFɹ]�S�R!��!�%��t62���]�xv醈����S5�	�4��_+e	�����cI2U�i�&���Ž$�4�E�;Qv�~с%T���c��i�Fy��2)q����=TڌCp�,��n_��Ei��>����*����O�:Y_s�r���.�y��a���?���6C�M��p}�o�.:l;S�
KlZC�̃{'n_���������0�;�{��E�@���J��D9Q���7����}�T+�@���������f\<�O�:-A&2��#�1d��VĒ`m�#�Ae���R>1�$V7�m\!Q�9 �:-�O.���?��H/��T*'�퍵&�.�t�O~ +6?Ű�I?Z$�������ި����#}���p�����l�5�f������,#vi��:�G��S�a$��[|k�P�=�;��g��*s��5���}L�P�a���A(S)�{��+�ŧ��Wd1�ӻ~������-��jK �{<��ae͐.y�!�S5p����2¹�@� �5B��ӗH�g�)�9�讧W�;!���sL"
P��/e�p��;���^3����+�)`WH��$x��.���Ƕ���N���&U�e��s�L�W�^�ˏ�l��f����z�h�#�k+F�<���pؓ� 'o8�?ȱ�N��0�(�0��Cy�C��aU��S�?J����5��k�t�i����fl�{m��P�3���Yq��D��c��!��1{�/[��^��"U��4���8���{�}Z̶S��}���-j��/��|r��'�1m���8�1�d1}H��k��4z8��8Z��	�,�׺�h���V��>y�x_�'' H�lϏV�؎���O���@����{Q�Y�8�a�vD@]����r���R0�Ƅә�S����up�J��]��F��k��<�_ȓ�m��?�Ƞ��7>��֗`R`2т�g�EO�<b �����~Pt��p6*%5���ľ��4<��$6 ��LǞtWpy3��IE�y0���U��z־Ę����p�w*X���&�����~�y���8^�����)�d�.��<���>�̖�ݪ���Iy�>��~ڽ�Ꮝq�_(vEt���o_��qP�d{�V�'�T��Z��UH:���S�f�myw�< ppu�v��AS��z��݁�mO8$�K��
�����I�	P*�<���){�p�n}0��]��uG��0F�9/���ɒsg��>ʴM���o�)GoN��R��nC�p��¥b*�+�ҟZMjY������x����g���Z����Z�u��=^(;.2E�	����v�+��s��C���(��mp0������
q��q�A������P�Lٛ��c"QO~Oa٦,MqQ�� Z�����'����<gLAp)�'����)���:dv����,Ë�@��V�cO�!���lߦ�Ӽ�`@H'�N�G��Jw� =�l�D@���}D�����uo�⫫��	j��\ʞ�S�IC�[��H�C�0�QY)�I��?���\?M��r]p�ĕƟ���a�a�WY�=�����������C�o�b?�뤌x}t!�a��a���,�/+�_":~��q9P�؎�V���#VUj�{�	��$7��6/����ݓ~����A��~��q/��HfM�r�Ű�#�:��}����u��J�l���"�d��<�Kd;�����;?�b��<%��2���!<b��r+�P-��8�;�.��od�!a����T(�DR���/����Ur.r�;}lB�v�l�ܸ�B��B�fT�y}�73�b���3�h%��S�9�j����CD�D�W��!�# I7�b�ɾ������"����2tMR��\�D4�{�>o��^h�}�>����QM}��I)�g>"k�a����ŒhC%̖X�(s��D�A��_�>�W�W�q��+��d&���!���8L�ۧ�|c�p�8T�.�Z�f
a���]��4՟ų:\)�<����6T�Z�����pŠ
��I��H����0FJ�-����U�jsA�t�����m{��#�	��`us2���5R�Gz��]��6~$s��YI$�s�I��n~���D����(�`x��1��/���F�S�r/��3�K�{0�� �B�}�@��f�k�rb��8�/s0��}�����_���-)['�@��b�)t�
%�������$A�.�MR��'LZRo�]�u~нP�?4��S�<��.���?�P�sG�*�|	�	r�+��i�ш��_��v(�ˌ&h���5��F��]�8�'����,��t{���b�7�lk�K�盹�c0������-|i�$��&gT&�[T�n��QV���?$�nʊ3�Y%f�,��Gdҝ+�d,�������B��b.)M�6^!mH���Qs���Ҧ�MR ���:� ,�omW�B��#i���7?�?�i�-��|���tAFU[��e�[y�9kx�y̚ۍ����b�vo���k�뛛(����z6��4��ci�2�y�Q��=[`�(��*�%�����Đ��?��	��d�a�4}��ӵN�t�
AE0ˍ�����S��%%;4�%���k�e���ߓG��J-�7���@ ��E��K��N��;q����Op�ks���^s(*X�}+��*�_4�����"�n�����h��{5'� ���9����W� Yܢ�U�a9Tؕl�.�3ߚ���μ%{����i�	�"y��8C�Fk}�1���ɂ��ǁEv��(5 ���Z	!3�L�Y����Th�Ħ*�3��͸��7��Q��B�Ș�c�?���O��>��A�)Q�/�|���<�]}��u�F'�˂�ƹ�tY�@�l���F!��Y����;t��K;P��%0��*Z\�tSID7n��zo��}�\�)�*����c^�3kҜFh2ņ���_���A$�b��\ϙ��w"(9��5��P�0���hj�EC>�w?�b�9�I��|�CJ�L{����rQ�����~���;�%G�)	O`y�P�U1 ��������N�6xql����I�J�#�����Ü���p�!�0L K;x�H̆q�6�����҆� �b��?�ps�`B�c,�y`���V��<�u�7��v�o���Ó�*_��%�r��:�W�]X���^^3��l�R����eM�r�Y��u�B6>j~��Y���_��+�������ToT�[��m�4���J����ң/_��D���� �t���;!�w�u�tR�+Q���lU��&k�r6�C� *l���Z�0J�=��6OhU_�]`��7�YW���+��/ Ą�%�aJ}b����J5�Q����[�]հD+/�w���H��2����<����֖�ݸj,� ���X��{� *
�љ+=�z"7n:nJH���yL�e�#��R2L�O{K�eS
��,���]r2��t�Y6q���j�)+7�/�SV7��^�����U��;u��l ����፽�"�}bymt�_$:S�L��VE�W{�����y^�J�5��Ǵ[hX�x��'萋b]�����l���M�S#�y�5H�*�r0��$�}hˮ���z�ϣX�GlsR�h�1۠G�z*��ǘ��N�;��',V�^�q����.W�i��>����^>��i���i���N��`>rK8ѯxg�l��
�G��i�8$���R���W*�(��<h�&�o��'4��)��5^�bc�l�����Z�L��f�p2�̦�`�F��yD$�V����>c胻�>�'O����`����U7������U;7�H��?�����X~�ډ0���n;���4//�=�V�ݲ�̹�_9Y��,9p��aa�9����;p����R~@�}}�����c���8`��M�M�)��0����,���Aj�����s��EՅ��A=p��L�����~&�:�ܩ���Z�%ܑM�s�ÝW��k����/��[�Ij��t�|�o�!$�8&�����M�{�5�B��h q�J���l�["�N��Lvp���o���JG$���Z���j0T�dفko��2 �y#	ln*"i���=���:�U��-g��9`f(�|��"N�@.@hA�-��b�n��Γ�iXQm�JT�:��t{I��]�C�X�}C����XX�_'��x
'���e)X�0�	��S��wuP����h ��<�{���9=�ɂ��syZ$!�+��I7<���� ��D�)O����4_!�MI�h���h�������U���)�8����%@�ث���`�ɞ����FCF2�����A�a�0�&������ �}I���3�q�7g���T��&�j�An�9bd`7w��V@�x�<� ^�1ǃ��n�s	Un���̂tJkR�BL�c�qe]�3���>���QcF�M3�T��3:�B�^N'T���r��u�L�Csi�R���:��9UE�BQ]t�3M�-�h/���i�DQ�T&!`����e�������q�np�R7��j�0��yh謜�����u�Wf��n�S����p`�܆(�|�\%'���:3up2�p5TO�fN��.h=(���k�5/�uWv��P�4�_sﮐL=y����QG�3�t��Tԡ�ϐ�������S!�)�y���5=X��L�p�	P2�;_a��Wg��ojD��^8�u������M���n�zZ��}+șC�Y�1�7(�*�?k��#i�IK��=���@��jn��r���yF��Rf\�{'�8�O���\�S�z�T���nM���?0t`]�$���#��Rr֦d-�ў�m��\��/5s.LoCk����b�+�
�vr�q@�d���3����f��h'� �9�9&�W[n�6p��d��HdC`Zy<�܄�\�a;l	�l�<��k8�S����܉��=ص��ϱj��f��U₟A���u��YMQz��*�r����Bӆ���?�w峴�/Q�;ϝ���mu�0�<)� ���Y�ͨ�s��"�}?WKX��/�P��F{����Γ�~W�px���\5$:����.�{���!�@��s�e���Rp��� �PrA+J������b��"`�rX��e(h��k��|�V�\c�r�J���	��8U<>~���<���vԬrt�*~4Bf�d'�z>��B��T���vW�����u�(RW�ܛ�0�+�� oB�(�T7���^#�����o��[i�s�(~�(�U�_4ǧ�6�G^w��K�*h��U*C���M��]-jf{�D�b4�w�$������g�%�l輐rUΗ�`��i�հ9�hZ�<m��E�k��Hڊ��N�]��.�}�ς�lЏ���\�^8s���{��2�橶�Z�V��~�����\Naa����(`(rͶ��x�{-�&g��ڬ=��Gl�� \C�/��Qh>]���"��d2pI���ۚ( �C�#2r�Y�e9Xƫ���\��o�t��J��hO��������S�3L2_ϴ��	�Y�@Qڪ�X7�ሮ w�<c��@�"Q}+:�����X�j����Jz�/��>�Y�A������+هZ�U�흞��A@��f�,`I��r����sG;�t�Z�WF���p\���77��Ĩ��I�$\�Xܖ�~N�$E��)�cj��wk���.��2�oj벐��0u{�"�9Sn�.�pt%أA>�s(����p,ϓ��,6h��;������ ��$f6P��	_7��ǰ*�f�;s��$���s�:]F� ,���/�+�^$�SYH����=��7����$��(�ϱ5CT0w��>���$'������y��zh�-����6�r�v[<� �5�����w���;�&)�����T*e�����H0�t�G��ϲۏ��Ҳ0�K2Û	?�< K`��b&QqP,��n�n�O��!_�&��Z�n)=+�OUa�_�L���L��^�ǖֶ;�G��IZ�������wx3e�ꬃ�7��l���@M2�
t�5-�,�����������b�>&-�V�!3�+�n�oVY�ݵ�d�W�yN!f`h�0�z�|VȬA�X�}���.�̚�����p/�%T�X�:C��s�OU@;��۴7�{��'���,��A.�h�?/��;����Y��d2��;��{@�� ��B��Mc?H���^m'���-�T�[�>&���L�ly��;Z`TAFr�MAk%S8nU��>�+q~��醡��G"l2M�
�k3c����|m!�~S�l�-�)�[��	"3҆ô���
�@�0�G�	��g���O,�:�2��ֺ����B+���i�G���Q8���$��?��L	s��e��nRcisr����ݵU���$��\�a�2���`�!��u H�E���/�S�������u!j�t�B�2��!��������4F��e�(N�5Bf*x���k�`��ݛ�F$�L�`V<6�r��!>6��˱i�P�#���./�!����a� ��r��l�{���5�ݒ�@J�gR<P�+\���-QOl���ۺ�;��V�I85�*Ou�R�{����.I�������1%b���D�7�d�ϼ�`�(2��&V�6/��)�qD�"����ܑ� �%«`x/�!�����9���l��'�������?��@|�ug����0��]M�p��AU�lq�g&�C�OWqc��I���̱dtB��R�£���S��ʁ�}��Y��� -G��ߛm�J��u��]����i��|S�xګ��OWO���lw�
jtp���b����[!���O�Q s�>������,���o���*�'���[��Q?0w:��M�d򽢯e'K��_��\@K�\慏���$���ǯɈ߷�����J��7^V��k�L~�q�hTrY��`�U*ԙ%P�O8@���y��y~}.8�R���K��8J��(�憛:��9գP��YSx���+i����ʱ8��h�aװ"~���V5�6dx
�:	����"�E|�)Z������]��Atk�s���u��}�6X٘���(�t�+�TRer >�h��f��I�@�����Fx��� F�4kb!^D���wߪ%=Ѱ�X�J����P��De_
�m��_t�^��ړ���46����9,��B�ޞui��-Ue�Q��;�ܦ�)�S.vD�������tġV��L7���^�!S!�z{�X���:You�ɍE��y�� ;�e�����t%e/�4h3�0jj�5�e��CZ+�=lB;ĺ�w'�Bj�2d̞�Qrm,9^�'���w궅6��dٍ������Z.��CD��K��^� lb� ���M>��M��:�R��:@�8�W
���Ku��U�S��p��Ms�tq�[�R�p^���=�*�G�a:�*\�~'�z�t[z��ߠ��3m�s�V'� !L�J@gzO�]�fQ<=ag�j=T���j���{��t~�,������(e�G�p9ޘ��U ���������PaL_��� v,K�l5�8�܊��;p&9��j�V!�(�oX}{��48xCT�h�WU�5n��_�vw=!���Zc/gJ�����#��U"!�o".U���)�	Ϣ�a44����-CW��Ɉ��*��>�	� zMܐ&?\\���/mi���^��2��n�T���J7��~���wEF�,`�1YVA$��n����=owů*mR������hj�H���x�Ht�2	��]D�,�6�����;�Kwq y�;���Aw�YZ/|�#���Ч����n��s�5���ڈ,^ک�q��V3@�뙀!@�Lw�!��0�(=L����e8=��?<97��ug �Uj-� �=5�;�K�������8Yk&(sع��E��|a�X��p�y���X�.+۽�Lu��L<B ���e�ַ(�O�^�*+��z��|�kض�%1�^C4�:����Z���'��jr���px��6�Β\�-�֜��X������\���U�4��K_����AA�y}|A�W֭�����X�p㴦�nH���<`qo�Y�B�+3 &�|���Ս�V98�Ǔݛ�<�ܱcJ ͜'�����+�䏉Z(��D���<f�k��B }L�H[��mه<d��խ��9�L�[C������0����Я��k�\��_hgV�=�7�[�
( d2���IL ܺ��4&���g�    YZ